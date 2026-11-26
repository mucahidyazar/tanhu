class_name HudBag
extends RefCounted
## Envanter (I) ile gerçek envanterin arası (görünüm modeli): Inventory'yi (scripts/sim/economy/inventory.gd) tutar, ekrana satır verir
## (ad, simge, yazı, sayı, yuva, işler), ekranın işlerini (Kuşan, Çıkar, Taşı, Bırak) envantere ve dünyaya yapar. Çocuğun oyuncak yayı
## hep yanındadır, yay yuvasında kuşanılıdır; vurup E ile aldığı av (tarla kuşu, kum faresi, keklik, karga, tarbagan) bütün olarak
## heybeye girer (PlayerController.target_collected → on_collected; SmallGame.collect: {kind, yield}); sığmayan önce yakındaki atın
## terkisine, sonra ayağının dibine yer yığını olur (GroundPile). Yakında (15 m) Yük'ü olan bir binek varsa onun terkisi aktarma
## panelinin kabıdır (transfer_target). Kayıtta durmaz: Çocukluk'ta kayıt yoktur, Serbest Gez sahne başına yeniden başlar; kayıt v2
## gelince Session envanteri verir (set_inventory) ve bloğu Inventory.to_dict yazar.
##   bag.reset(true)                      # çocuk: oyuncak yay kuşanılı, sınır 6 Yük
##   player.target_collected.connect(bag.on_collected)
##   bag.entries()                        # [{id, name, icon, text, count, slot, actions, ...}] kuşanılanlar, heybe, araçlar
##   bag.equipped()                       # {"bow": {...}}
##   bag.grid("all")                      # kuşanılı olmayanlar, yığın yığın (sekme: all, back, food, craft, tools, keepsakes)

signal changed
## Alınamayan eşyanın uyarısı (oyuncunun dilinde: «Yük dolu», «Heybede yer yok»).
signal refused(text: String)

## Kuşam yuvaları (progression.md §6.1), kişinin iki yanında: solda baştan ayağa, sağda sırt ve silah.
const EQUIP_LEFT: Array[String] = ["head", "neck", "body", "hands", "feet"]
const EQUIP_RIGHT: Array[String] = ["cape", "bow", "quiver", "belt", "blade"]
## Bedenin sınırı (Yük): çocuk 6 (tek kütük, ×0,8), yetişkin Bilek 3'te 21.
const LIMIT_CHILD := 6
const LIMIT_ADULT := 21
## Heybenin sekmeleri (economy.md §4.2; «Hepsi» ekranın).
const TABS: Array[String] = ["all", "back", "food", "craft", "tools", "keepsakes"]
## Kampın iki atının adı (K3): terkinin başlığı.
const MOUNT_NAMES := {"HorseBrown": "Doru", "HorseWhite": "Akbulut"}
## Bırakılan yığının oyuncunun önündeki ve sağındaki uzaklığı (m): gövdenin arkasında kalmasın, E'nin eriminde olsun (1,15 m).
const DROP_AHEAD := 0.6
const DROP_SIDE := 0.4

var inventory: Inventory
## Oyuncu (PlayerController; GameplayHud.bind verir): yere bırakma ve yakındaki binek için. Yoksa bırakılamaz, aktarılamaz.
var player: Node3D
## Akçe değil Kabuk (K48): kese açıksa kesedeki kabuk.
var coins: int:
	get:
		return inventory.cowries() if inventory else 0
## Taşınan sınır (Yük).
var limit: float:
	get:
		return inventory.capacity() if inventory else 0.0

## Yer yığınının dünyadaki düğümü: yığın kimliği → GroundPile.
var _pile_nodes: Dictionary = {}


func _init() -> void:
	set_inventory(Inventory.new())


## Envanteri bağlar (Session gelince onunkini verir; oturum kapanınca yenisi). Önceki envanterin yer yığınlarının düğümleri dünyadan
## kalkar (yığınlar o envanterindir; yeni envanterinkiler spawn_piles ile konur).
func set_inventory(inv: Inventory) -> void:
	if inventory:
		for pair: Array in _links():
			if (pair[0] as Signal).is_connected(pair[1]):
				(pair[0] as Signal).disconnect(pair[1])
	for node: Variant in _pile_nodes.values():
		if is_instance_valid(node):
			(node as Node).queue_free()
	_pile_nodes.clear()
	inventory = inv
	for pair: Array in _links():
		(pair[0] as Signal).connect(pair[1])
	changed.emit()


func _links() -> Array:
	return [[inventory.changed, _on_changed], [inventory.refused, _on_refused], [inventory.pile_changed, _on_pile_changed],
		[inventory.pile_removed, _on_pile_removed]]


func _on_changed() -> void:
	changed.emit()


func _on_refused(item_id: String, _n: int, reason: String) -> void:
	var msg := message(reason)
	if not msg.is_empty() and reason != "unknown":
		refused.emit(msg)


## containers.json messages (oyuncunun dilinde).
static func message(key: String) -> String:
	var m: Variant = (ItemContainer.rules().get("messages", {}) as Dictionary).get(key)
	return ItemCatalog._pick(m, lang(), "") if m != null else ""


static func lang() -> String:
	return SubtitleBar.ui_lang()


## Envanteri boşaltır; child ise oyuncak yay yay yuvasında ve sınır çocuğunkidir. Dünyanın yer yığınları da kalkar.
func reset(child: bool) -> void:
	inventory.reset_body(Inventory.BODY_CHILD if child else Inventory.BODY_ADULT)


## Ekler (toplama ve avın yolu: heybe, sonra yakındaki atın terkisi). Dönüş: eklenen.
func add(item_id: String, n: int = 1) -> int:
	if item_id.is_empty() or n <= 0:
		return 0
	return int(inventory.receive(item_id, n, "hud", {"mount": transfer_key()})["added"])


func count(item_id: String) -> int:
	return inventory.count(item_id)


## Taşınan Yük.
func load_amount() -> float:
	return inventory.load_amount()


## Yerden alınan hedef (PlayerController.target_collected): av bütün olarak heybeye (sığmayan terkiye, sonra ayağının dibine);
## yer yığını sığdığı kadar geri.
func on_collected(_target: Node, result: Variant) -> void:
	if not result is Dictionary:
		return
	var r := result as Dictionary
	if str(r.get("kind", "")) == GroundPile.KIND:
		var pile: Variant = r.get("pile")
		if pile is ItemContainer:
			inventory.take_pile(pile)
		return
	var kind := str(r.get("kind", ""))
	if kind.is_empty() or not ItemCatalog.has(kind):
		return
	var opts := {"mount": transfer_key()}
	if can_drop():
		opts["spill_at"] = drop_point()
	inventory.receive(kind, 1, "hunt", opts)


# --- Satırlar ------------------------------------------------------------------------------------------------------------

## Bir satır: id, count, name, icon (atlas; "" kodla çizilir), text (çekmece), meta (sekme, Yük, yığın), slot (kuşanılıysa yuvası),
## equip_slot (eşyanın yuvası), tab, actions (use, move, drop), use_label (Kuşan, Çıkar ya da Kullan).
func entry(item_id: String, n: int, worn_slot := "", can_move: Variant = null) -> Dictionary:
	var lg := lang()
	var equip_slot := ItemCatalog.slot_of(item_id)
	var actions: Array = []
	var use_label := "Kullan"
	var locked := inventory.is_locked(item_id)
	if not worn_slot.is_empty():
		if not locked:
			actions.append("use")
		use_label = "Çıkar"
	elif not equip_slot.is_empty() and ItemCatalog.slots().has(equip_slot):
		actions.append("use")
		use_label = "Kuşan"
	var movable: bool = can_move if can_move is bool else not transfer_target().is_empty()
	if worn_slot.is_empty() and movable and not ItemCatalog.is_tool_item(item_id):
		actions.append("move")
	if can_drop() and not ItemCatalog.is_keepsake(item_id) and not locked:
		actions.append("drop")
	return {"id": item_id, "count": n, "name": ItemCatalog.name_of(item_id, lg), "icon": ItemCatalog.icon_of(item_id),
		"text": describe(item_id, lg), "meta": meta_line(item_id, n, lg), "slot": worn_slot, "equip_slot": equip_slot,
		"tab": ItemCatalog.tab_of(item_id), "actions": actions, "use_label": use_label}


## Çekmecenin yazısı: satırın yazısı, yoksa alanlardan (kademe ve etiketler; giyimde yuvası).
static func describe(item_id: String, lg := "tr") -> String:
	var t := ItemCatalog.text_of(item_id, lg)
	if not t.is_empty():
		return t
	var parts := PackedStringArray()
	var slot := ItemCatalog.slot_of(item_id)
	if not slot.is_empty():
		parts.append(("%s yuvasına kuşanılır" if lg == "tr" else "Worn in the %s slot") % ItemCatalog.label("slots", slot, lg).to_lower())
	else:
		parts.append(ItemCatalog.label("tiers", ItemCatalog.tier(item_id), lg))
	var tags := PackedStringArray()
	for tag: Variant in ItemCatalog.tags(item_id):
		if str(tag) != "gear" and str(tag) != "game":
			tags.append(ItemCatalog.label("tags", str(tag), lg).to_lower())
	if not tags.is_empty():
		parts.append(", ".join(tags))
	var food: Variant = ItemCatalog.row(item_id).get("food")
	if food is Dictionary and float((food as Dictionary).get("fullness", 0)) > 0.0:
		parts.append(("Tokluk +%d" if lg == "tr" else "Fullness +%d") % int((food as Dictionary)["fullness"]))
	var gear_load := float(ItemCatalog.gear_of(item_id).get("load", 0.0))
	if gear_load > 0.0:
		parts.append(("Yük sınırı +%d" if lg == "tr" else "Load limit +%d") % int(gear_load))
	if ItemCatalog.is_tool_item(item_id):
		parts.append("Yük tutmaz, aşınmaz" if lg == "tr" else "Weighs nothing, never wears out")
	if not ItemCatalog.perish_of(item_id).is_empty():
		parts.append("çiğ: ikinci şafakta bozulur" if lg == "tr" else "raw: spoils at the second dawn")
	return " · ".join(parts) + "."


## Ölçü satırı: «Erzak · 0,4 Yük · yığın 10» (sayı Türkçede virgüllü).
static func meta_line(item_id: String, n: int, lg := "tr") -> String:
	var parts := PackedStringArray([ItemCatalog.label("tabs", ItemCatalog.tab_of(item_id), lg)])
	if ItemCatalog.is_tool_item(item_id):
		parts.append("Yük 0" if lg == "tr" else "Load 0")
	else:
		parts.append(("%s Yük" if lg == "tr" else "%s load") % yuk_text(ItemCatalog.stack_load10(item_id, n) / 10.0, lg))
		if ItemCatalog.stack(item_id) > 1:
			parts.append(("yığın %d" if lg == "tr" else "stack %d") % ItemCatalog.stack(item_id))
	return " · ".join(parts)


## Yük'ün yazısı: tamsa tamsayı, değilse bir ondalık; Türkçede virgül («0,6»).
static func yuk_text(v: float, lg := "tr") -> String:
	var s := str(int(round(v))) if is_equal_approx(v, round(v)) else "%.1f" % v
	return s.replace(".", ",") if lg == "tr" else s


## Bütün satırlar: kuşanılanlar (yuva sırasıyla), heybe (eklenme sırasıyla), kese, araçlar.
func entries() -> Array:
	var out: Array = []
	var movable := not transfer_target().is_empty()
	for slot: String in EQUIP_LEFT + EQUIP_RIGHT:
		var e := inventory.equipped(slot)
		if not e.is_empty():
			out.append(entry(e, 1, slot, movable))
	for it: Dictionary in inventory.pack.list():
		out.append(entry(str(it["id"]), int(it["n"]), "", movable))
	for t: String in inventory.tools():
		out.append(entry(t, 1, "", movable))
	return out


## Kuşanılı eşyalar: yuva → satır.
func equipped() -> Dictionary:
	var out := {}
	for slot: String in EQUIP_LEFT + EQUIP_RIGHT:
		var e := inventory.equipped(slot)
		if not e.is_empty():
			out[slot] = entry(e, 1, slot, false)
	return out


## Izgaradaki (kuşanılı olmayan) eşyalar, yığın yığın (bir hücre bir yığın: 25 et → 10, 10, 5); tab süzer.
func grid(tab := "all") -> Array:
	var out: Array = []
	var movable := not transfer_target().is_empty()
	var rows: Array = inventory.pack.list()
	for t: String in inventory.tools():
		rows.append({"id": t, "n": 1})
	for it: Dictionary in rows:
		var item_id := str(it["id"])
		if tab != "all" and ItemCatalog.tab_of(item_id) != tab:
			continue
		var left := int(it["n"])
		var st := ItemCatalog.stack(item_id)
		while left > 0:
			var k := mini(left, st)
			out.append(entry(item_id, k, "", movable))
			left -= k
	return out


## Sekmedeki yığın sayısı (sekme düğmesinin sayısı).
func tab_count(tab: String) -> int:
	return grid(tab).size()


# --- İşler ----------------------------------------------------------------------------------------------------------------

## Kullan: kuşanılıysa çıkarır, kuşanılabiliyorsa kuşanır. Dönüş: yapıldı mı.
func use(e: Dictionary) -> bool:
	var item_id := str(e.get("id", ""))
	if not str(e.get("slot", "")).is_empty():
		return not inventory.unequip(str(e["slot"])).is_empty()
	var slot := ItemCatalog.slot_of(item_id)
	if slot.is_empty() or not ItemCatalog.slots().has(slot):
		return false
	return inventory.equip(slot, item_id)


## Taşı: satırın yığını aktarma kabına (terki). Dönüş: {moved, text} (text oyuncunun dilinde sonuç ya da uyarı).
func move_to_target(e: Dictionary) -> Dictionary:
	var t := transfer_target()
	if t.is_empty():
		return {"moved": 0, "text": ""}
	var r := inventory.move(inventory.pack, t["container"], str(e.get("id", "")), int(e.get("count", 1)))
	var moved := int(r["moved"])
	if moved <= 0:
		var c: ItemContainer = t["container"]
		return {"moved": 0, "text": message("refuses") if not c.accepts(str(e.get("id", ""))) else message("saddlebags_full")}
	return {"moved": moved, "text": "%s × %d → %s" % [ItemCatalog.name_of(str(e["id"]), lang()), moved, str(t["title"]).capitalize()]}


## Bırak: satırın yığını oyuncunun önüne yer yığını olur. Dönüş: bırakıldı mı.
func drop(e: Dictionary) -> bool:
	if not can_drop():
		return false
	var item_id := str(e.get("id", ""))
	var pile := inventory.drop(item_id, int(e.get("count", 1)), drop_point())
	return pile != null


## Yükü Bırak (economy.md §4.2: G basılı 0,6 sn): Sırt sekmesi (tag:bulk: odun, taş, cevher, tulum, kil) oyuncunun önünde tek yer yığını
## olur. Dönüş: bırakılan [{id, n}] (sırtta bir şey yoksa ya da bırakılamıyorsa boş).
func drop_back() -> Array:
	var out: Array = []
	if not can_drop():
		return out
	var at := drop_point()
	for it: Dictionary in inventory.tab("back"):
		var item_id := str(it["id"])
		var n := int(it["n"])
		if n > 0 and inventory.drop(item_id, n, at) != null:
			out.append({"id": item_id, "n": n})
	return out


## Boşalan yer yığınlarını kaldırır (aktarma panelinde boşaltılan yığın; Inventory.take_pile boş yığını siler).
func prune_piles() -> void:
	for p: ItemContainer in inventory.piles():
		if p.is_empty():
			inventory.take_pile(p)


## Oyuncunun erimindeki yer yığını (yatay; yoksa null): {pile, node}.
func pile_near(xz: Vector2, reach: float) -> Dictionary:
	var best: Dictionary = {}
	var best_d := reach
	for p: ItemContainer in inventory.piles():
		if p.is_empty():
			continue
		var at := inventory.pile_position(p)
		var d := xz.distance_to(Vector2(at.x, at.z))
		if d <= best_d:
			best = {"pile": p, "at": at}
			best_d = d
	return best


## Dünyaya bırakılabilir mi (oyuncu sahnede)?
func can_drop() -> bool:
	return player != null and is_instance_valid(player) and player.is_inside_tree()


## Oyuncunun önü (yer yığınının yeri).
func drop_point() -> Vector3:
	var p := player.global_position
	var yaw: float = player.call(&"get_facing_yaw") if player.has_method(&"get_facing_yaw") else player.global_rotation.y
	var ahead := Vector3(sin(yaw), 0.0, cos(yaw))
	return p + ahead * DROP_AHEAD + Vector3(-ahead.z, 0.0, ahead.x) * DROP_SIDE


# --- Aktarma kabı --------------------------------------------------------------------------------------------------------

## Aktarma kabı: binilen ya da 15 m içindeki, Yük'ü olan binek (koyunun terkisi yoktur): {container, title, key, node}; yoksa {}.
func transfer_target() -> Dictionary:
	var ride := _near_mount()
	if ride == null:
		return {}
	var key := _mount_key(ride)
	var bag := inventory.saddlebags(key)
	if bag == null:
		return {}
	var nm := str(MOUNT_NAMES.get(_owner_name(ride), ""))
	var title := ("TERKİ · %s" % nm.to_upper()) if not nm.is_empty() else "TERKİ"
	if lang() == "en":
		title = ("SADDLEBAGS · %s" % nm.to_upper()) if not nm.is_empty() else "SADDLEBAGS"
	return {"container": bag, "title": title, "key": key, "node": ride}


## Terkinin anahtarı ("" yakında binek yoksa): taşma oraya gider.
func transfer_key() -> String:
	var ride := _near_mount()
	return _mount_key(ride) if ride else ""


func _near_mount() -> Rideable:
	if not can_drop():
		return null
	if player.has_method(&"riding_node"):
		var riding: Variant = player.call(&"riding_node")
		if riding is Rideable and CarryLoad.mount_cap((riding as Rideable).mount_kind()) > 0.0:
			return riding
	var reach := float(CarryLoad.rules().get("near_mount_m", 15.0))
	var best: Rideable = null
	var best_d := reach
	for node in player.get_tree().get_nodes_in_group(Rideable.GROUP):
		var ride := node as Rideable
		if ride == null or not ride.is_inside_tree() or CarryLoad.mount_cap(ride.mount_kind()) <= 0.0:
			continue
		var d := ride.global_position.distance_to(player.global_position)
		if d <= best_d:
			best = ride
			best_d = d
	return best


static func _owner_name(ride: Rideable) -> String:
	return str(ride.get_parent().name) if ride.name == "Ride" and ride.get_parent() else str(ride.name)


static func _mount_key(ride: Rideable) -> String:
	return "%s@%s" % [ride.mount_kind(), _owner_name(ride)]


# --- Yer yığınları ---------------------------------------------------------------------------------------------------------

func _on_pile_changed(pile: ItemContainer, at: Vector3) -> void:
	var old: Variant = _pile_nodes.get(pile.id)
	if is_instance_valid(old):
		(old as GroundPile).refresh()
		return
	if not can_drop() or player.get_parent() == null:
		return
	var node := GroundPile.new()
	node.name = "GroundPile_%s" % pile.id.get_slice(".", 1)
	node.pile = pile
	player.get_parent().add_child(node)
	node.global_position = at
	_pile_nodes[pile.id] = node


func _on_pile_removed(pile: ItemContainer) -> void:
	var old: Variant = _pile_nodes.get(pile.id)
	_pile_nodes.erase(pile.id)
	if is_instance_valid(old):
		(old as Node).queue_free()


## Kayıttan dönen yer yığınlarının düğümlerini kurar (Inventory.from_dict'ten sonra; dünya kurulup oyuncu yerleşince).
func spawn_piles() -> void:
	for p: ItemContainer in inventory.piles():
		_on_pile_changed(p, inventory.pile_position(p))


## Dünyadaki yığın düğümleri (sınama).
func pile_nodes() -> Array:
	return _pile_nodes.values().filter(func(n: Variant) -> bool: return is_instance_valid(n))
