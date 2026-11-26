class_name Inventory
extends RefCounted
## Oyuncunun heybesi ve kişisel kapları (saf; economy.md §4, progression.md §6–§7, godot.md §3 «Envanter ve ekonomi»): Heybe
## (Yük sınırı, Erzak ve Zanaat'ın 24 ortak yuvası), Araç, kuşam yuvaları ve sadak, kese (II'den), Yük ve hız, terkiler, kızak,
## sandık, araba, Menzil ambarları, Zula, yer yığınları, el koyma (Hüküm), şafakta bozulma ve kayıt bloğu. Prototipin
## game/inventory.js'inin Godot'su: olaylar sinyaldir, şafağı ve bayrağı sahibi (Session) bildirir.
##   var inv := Inventory.new()                     # yetişkin, Bilek 3: 21 Yük
##   inv.add("wood_pine", 3, "gather")              # {added, rest}: yalnız Heybe; sığmayan döner
##   inv.receive("stone", 6, "gather", {"spill_at": at})   # Heybe → yakındaki atın terkisi → yer yığını (ganimet ve toplama)
##   inv.equip("bow", "toy_bow"); inv.unequip("bow")
##   inv.load_amount(), inv.capacity(), inv.speed_k(), inv.can_run(), inv.can_jump()
##   inv.move(inv.pack, inv.saddlebags("horse@Doru"), "lark", 2)   # aktarma; Sırtı Boşalt: inv.unload_back(to)
##   inv.to_dict() / inv.from_dict(d)               # kayıt v2'nin «inventory» bloğu
## Giyilen ve kuşanılan eşyanın Yük'ü vardır ama heybenin sınırından düşmez: sınır taşınan yüktür (economy.md §10.2'nin sefer
## hesapları Bilek 3'te 21 Yük'ü boş sayar). Kuşamdan çıkan eşya heybeye girer, orada Yük tutar.

signal changed
## Taşınan Yük ya da sınır değişti (yalnız değer değişince).
signal load_changed(load_amount: float, cap: float)
signal item_added(item_id: String, n: int, src: String)
signal item_removed(item_id: String, n: int)
signal item_moved(from_id: String, to_id: String, item_id: String, n: int)
signal item_spoiled(container_id: String, item_id: String, n: int)
signal equip_changed(slot: String, item_id: String, prev: String)
## Alınamayan: reason "pack_full" (Yük dolu), "slots_full" (Heybede yer yok), "unknown".
signal refused(item_id: String, n: int, reason: String)
## Yer yığını açıldı ya da büyüdü (pile: ItemContainer; at: dünya noktası) ve boşalıp kalktı.
signal pile_changed(pile: ItemContainer, at: Vector3)
signal pile_removed(pile: ItemContainer)

## Kayıt bloğunun sürümü.
const SAVE_V := 1
const BODY_ADULT := "adult"
const BODY_CHILD := "child"

## Beden: "adult" (formül) ya da "child" (sabit sınır, containers.json bodies).
var body := BODY_ADULT
## Bilek (stat; Yahni süresince +1) ve Sırt Yükü becerisi (carry_pack: +8 Yük, yarım yüke dek yavaşlama yok).
var grip := 3.0
var carry_pack := false
## Sınırı derive() verirse (loadMax, Yük): () -> float. Verilmezse formül ya da bedenin sınırı.
var cap_source: Callable
## Kızak sürükleniyor: kızağın Yük'ü ve sınırı heybeye katılır, hız ayrıca ×0,9.
var sled_on := false
## Kese açık mı (II'den, K48)? Açıkken başlıkta «Kese {n}» yazar.
var purse_on := false
## Kış dünyasında balık donuktur (spec.perish.fish false).
var perish_fish := true
## Son şafağın günü (dayN); ilk gerçek şafakta bilinmeyen sayaç eşlenir.
var day := 0
## Yakındaki (15 m) ya da binilen bineğin terki anahtarı ("" yok): taşma oraya gider.
var near_mount := ""
## Sadaktaki ok: {id: n}. Çan: {on, plug, fate} (yuva değildir).
var arrows: Dictionary = {}
var bell := {"on": true, "plug": false, "fate": null}
## El konan: {sack: ItemContainer, tools: [], equip: {yuva: id}, arrows: {}} ya da boş.
var seized: Dictionary = {}

var pack: ItemContainer
var purse: ItemContainer
var chest: ItemContainer
var cart: ItemContainer
var sled: ItemContainer
var cache := CacheSet.new()

var _tools: Array[String] = []
var _slots: Dictionary = {}
var _stash: Dictionary = {}
var _bags: Dictionary = {}
var _piles: Array = []
## Bedenin kilitli eşyası (kits.<beden>.locked: çocuğun oyuncak yayı): çıkarılmaz, bırakılmaz, el konmaz.
var _locked: Array = []
var _pile_at: Dictionary = {}
var _pile_serial := 0
var _resolver: Callable
var _day_known := false
var _sent_load := NAN
var _sent_cap := NAN


func _init(p_body := BODY_ADULT, p_day := 0) -> void:
	body = p_body
	pack = ItemContainer.make("pack", {"owner": "player"})
	# Heybenin sınırı her okumada sahibinden gelir; zayıf başvuru: kap sahibini tutmaz (RefCounted döngüsü sızardı).
	var owner_ref: WeakRef = weakref(self)
	pack.set_cap_source(func() -> int:
		var o: Inventory = owner_ref.get_ref()
		return o.pack_cap10() if o else 0)
	pack.slots = int(CarryLoad.rules().get("pack_slots", 24))
	purse = ItemContainer.make("purse", {"owner": "player"})
	chest = ItemContainer.make("chest", {"owner": "player"})
	cart = ItemContainer.make("cart", {"owner": "player"})
	sled = ItemContainer.make("sled", {"owner": "player"})
	for slot: Variant in ItemCatalog.slots():
		_slots[str(slot)] = ""
	day = p_day
	cache.day = p_day
	_day_known = p_day != 0


# --- Yük ve hız (economy.md §4.1) -----------------------------------------------------------------------------------

## Heybenin sınırı, onda bir: derive() verirse o, çocukta bedenin sınırı, yetişkinde 12 + 3 × Bilek + Sırt Yükü + kuşak.
func pack_cap10() -> int:
	var cap := -1.0
	if cap_source.is_valid():
		cap = float(cap_source.call())
	else:
		cap = CarryLoad.body_cap(body)
		if cap < 0.0:
			cap = CarryLoad.cap_of(grip, carry_pack, gear_load())
	return maxi(0, roundi(cap * 10.0))


## Taşınan sınır (Yük): heybe, kızak sürüklenirken +12.
func capacity() -> float:
	return (pack_cap10() + (sled.cap10() if sled_on else 0)) / 10.0


## Taşınan Yük: heybe, kese ve sürüklenen kızak (giyilen ve kuşanılan sınırdan düşmez).
func load_amount() -> float:
	return (pack.load10() + purse.load10() + (sled.load10() if sled_on else 0)) / 10.0


func load_frac() -> float:
	return CarryLoad.frac(load_amount(), capacity())


## Yavaşlamanın başladığı doluluk: Sırt Yükü ile 0,5.
func slow_from() -> float:
	return float(CarryLoad.rules().get("carry_pack_slow_from", 0.5)) if carry_pack else 0.0


func speed_k() -> float:
	return CarryLoad.speed_k(load_frac(), slow_from(), sled_on)


func can_run() -> bool:
	return CarryLoad.can_run(load_frac())


func can_jump() -> bool:
	return CarryLoad.can_jump(load_frac())


## Oyuncu denetleyicisinin okuyacağı hareket çarpanları: hız, koşu, zıplama, koşunun takat gideri, sırt yığınının kademesi.
func move_mods() -> Dictionary:
	var l := load_frac()
	return {"speed_k": speed_k(), "can_run": CarryLoad.can_run(l), "can_jump": CarryLoad.can_jump(l), "run_cost_k": CarryLoad.run_cost_k(l),
		"back_stage": CarryLoad.back_stage(l)}


# --- Eşya ------------------------------------------------------------------------------------------------------------

## Ekler: {added, rest}. Araç Araç sekmesine (tekil, Yük tutmaz), kabuk keseye (açıksa), gerisi Heybe'ye. allow_over sınırı geçer
## (kuşamdan dönen eşya, el koymanın iadesi). Bilinmeyen kimlik bir uyarıyla reddedilir.
func add(item_id: String, n := 1, src := "", allow_over := false) -> Dictionary:
	if not ItemCatalog.has(item_id):
		push_warning("[envanter] bilinmeyen eşya: %s" % item_id)
		refused.emit(item_id, maxi(0, n), "unknown")
		return {"added": 0, "rest": maxi(0, n)}
	if n <= 0:
		return {"added": 0, "rest": 0}
	if ItemCatalog.is_tool_item(item_id):
		if _tools.has(item_id):
			return {"added": 0, "rest": 0}
		_tools.append(item_id)
		item_added.emit(item_id, 1, src)
		_changed()
		return {"added": 1, "rest": 0}
	var box := purse if purse_on and purse.accepts(item_id) else pack
	var r := box.add(item_id, n, day, allow_over)
	if int(r["added"]) > 0:
		item_added.emit(item_id, int(r["added"]), src)
		_changed()
	return r


## Toplama, av ve ganimetin yolu (economy.md §4.6 madde 9, §4.7): önce Heybe, sığmazsa yakındaki ya da binilen atın terkisi
## (near_mount ya da opts.mount), sonra yer yığını (opts.spill_at: Vector3 verilirse). Dönüş: {added, rest, to: {kap: adet}}.
## Kalan varsa refused yayılır («Yük dolu» ya da «Heybede yer yok»).
func receive(item_id: String, n := 1, src := "", opts := {}) -> Dictionary:
	var to := {}
	var r := add(item_id, n, src)
	var added := int(r["added"])
	var rest := int(r["rest"])
	if added > 0:
		var first := "tools" if ItemCatalog.is_tool_item(item_id) else (purse.id if purse_on and purse.accepts(item_id) else pack.id)
		to[first] = added
	var mount := str(opts.get("mount", near_mount))
	if rest > 0 and not mount.is_empty() and ItemCatalog.has(item_id):
		var bag := saddlebags(mount)
		if bag:
			var b := bag.add(item_id, rest, day)
			if int(b["added"]) > 0:
				to[bag.id] = int(b["added"])
				item_added.emit(item_id, int(b["added"]), src)
				rest = int(b["rest"])
				added += int(b["added"])
	if rest > 0 and opts.get("spill_at") is Vector3 and ItemCatalog.has(item_id):
		var pile := _pile_for(opts["spill_at"])
		pile.add(item_id, rest, day, true)
		to[pile.id] = rest
		item_added.emit(item_id, rest, src)
		pile_changed.emit(pile, _pile_at.get(pile.id, opts["spill_at"]))
		added += rest
		rest = 0
	if rest > 0:
		refused.emit(item_id, rest, refuse_reason(item_id))
	return {"added": added, "rest": rest, "to": to}


## Heybe bu eşyadan neden almıyor: "slots_full" (yuva bitti), "pack_full" (Yük), "unknown" ya da "".
func refuse_reason(item_id: String) -> String:
	if not ItemCatalog.has(item_id):
		return "unknown"
	if pack.can_take(item_id, 1) > 0:
		return ""
	if ItemCatalog.uses_slot(item_id) and pack.slots_free() <= 0 and pack.amount(item_id) % ItemCatalog.stack(item_id) == 0:
		return "slots_full"
	return "pack_full"


## Heybenin alabileceği en çok adet (araç 0 ya da 1).
func can_take(item_id: String, n := 1) -> int:
	if ItemCatalog.is_tool_item(item_id):
		return 0 if _tools.has(item_id) else mini(1, n)
	if purse_on and purse.accepts(item_id):
		return n
	return pack.can_take(item_id, n)


## Çıkarır: gerçekten çıkan [{id, n}]; etiket kabul eder. Önce Heybe ve kese, sonra araçlar, sonra kuşanılan.
func remove(ref: String, n := 1) -> Array:
	if n <= 0:
		return []
	var out := pack.remove(ref, n)
	var left := n - _sum(out)
	if left > 0 and purse_on:
		var got := purse.remove(ref, left)
		out.append_array(got)
		left -= _sum(got)
	for t: String in _tools.duplicate():
		if left <= 0:
			break
		if not ItemCatalog.matches(t, ref):
			continue
		_tools.erase(t)
		out.append({"id": t, "n": 1})
		left -= 1
	for slot: String in _slots:
		if left <= 0:
			break
		var e := str(_slots[slot])
		if e.is_empty() or not ItemCatalog.matches(e, ref):
			continue
		_slots[slot] = ""
		if slot == "quiver":
			_trim_arrows()
		equip_changed.emit(slot, "", e)
		out.append({"id": e, "n": 1})
		left -= 1
	for it: Dictionary in out:
		item_removed.emit(str(it["id"]), int(it["n"]))
	if not out.is_empty():
		_changed()
	return out


## Heybe, kese, araçlar ve kuşanılanlardaki toplam.
func count(ref: String) -> int:
	var n := pack.count(ref) + (purse.count(ref) if purse_on else 0)
	for t: String in _tools:
		if ItemCatalog.matches(t, ref):
			n += 1
	for slot: String in _slots:
		if not str(_slots[slot]).is_empty() and ItemCatalog.matches(str(_slots[slot]), ref):
			n += 1
	return n


func has(ref: String, n := 1) -> bool:
	return count(ref) >= n


func has_tool(item_id: String) -> bool:
	return _tools.has(item_id)


func tools() -> Array[String]:
	return _tools.duplicate()


## Sekme: "back", "food", "craft", "tools", "keepsakes" → [{id, n}] (economy.md §4.2).
func tab(tab_name: String) -> Array:
	if tab_name == "tools":
		var out: Array = []
		for t: String in _tools:
			out.append({"id": t, "n": 1})
		return out
	if not ItemCatalog.TABS.has(tab_name):
		return []
	return pack.list().filter(func(it: Dictionary) -> bool: return ItemCatalog.tab_of(str(it["id"])) == tab_name)


## Erzak ve Zanaat'ın kullandığı ortak yuva ve sınırı.
func slots_used() -> int:
	return pack.slots_used()


func slots_max() -> int:
	return pack.slots


## Kesedeki kabuk.
func cowries() -> int:
	return purse.amount("cowrie")


# --- Kuşam ve sadak (progression.md §6.1–§6.2, §7.3) -----------------------------------------------------------------

## Kuşanır: yuva denetlenir; eşya heybedeyse ondan alınır; yuvadaki eski eşya heybeye döner (sınırı geçebilir, kaybolmaz).
func equip(slot: String, item_id: String) -> bool:
	if not _slots.has(slot) or ItemCatalog.slot_of(item_id) != slot:
		return false
	var prev := str(_slots[slot])
	if prev == item_id:
		return true
	if pack.amount(item_id) > 0:
		pack.remove(item_id, 1)
	_slots[slot] = item_id
	if not prev.is_empty():
		pack.add(prev, 1, day, true)
	if slot == "quiver":
		_trim_arrows()
	equip_changed.emit(slot, item_id, prev)
	_changed()
	return true


## Kuşamdan çıkarır (heybeye döner; sınırı geçebilir). Kilitli eşya çıkmaz. Dönüş: çıkan kimlik ya da "".
func unequip(slot: String) -> String:
	var e := str(_slots.get(slot, ""))
	if e.is_empty() or is_locked(e):
		return ""
	_slots[slot] = ""
	pack.add(e, 1, day, true)
	if slot == "quiver":
		_trim_arrows()
	equip_changed.emit(slot, "", e)
	_changed()
	return e


func equipped(slot: String) -> String:
	return str(_slots.get(slot, ""))


## Bedenin kilitli eşyası mı (kits.<beden>.locked)?
func is_locked(item_id: String) -> bool:
	return _locked.has(ItemCatalog.base_id(item_id))


## Yuva → kimlik (boş yuva "").
func equipment() -> Dictionary:
	return _slots.duplicate()


## Kuşanılanların toplam Yük'ü (sınırdan düşmez; arayüz gösterir).
func worn_load() -> float:
	var sum := 0
	for slot: String in _slots:
		sum += ItemCatalog.stack_load10(str(_slots[slot]), 1) if not str(_slots[slot]).is_empty() else 0
	return sum / 10.0


## Kuşamın Yük'e kattığı (kuşak: Kese Kuşak +4, Ordos Kuşağı +6, Alet Kuşağı +3).
func gear_load() -> float:
	var sum := 0.0
	for slot: String in _slots:
		var e := str(_slots[slot])
		if not e.is_empty():
			sum += float(ItemCatalog.gear_of(e).get("load", 0.0))
	return sum


## derive()'ın «gear» girdisi (progression.md §2.3): adı Mul ile biten ve snowSpeed çarpılır, öteki sayılar toplanır, mantık birleşir;
## statBonus stat başına, dr tür başına toplanıp −25..+60'a kırpılır; İnce İş DR'yi ve sadağı ×1,1 yapar. check(when) koşullu etkiyi açar.
func gear_block(check := Callable()) -> Dictionary:
	return Inventory.gear_block_of(_slots, check)


static func gear_block_of(slots_map: Dictionary, check := Callable()) -> Dictionary:
	var out := {"statBonus": {"grip": 0, "wind": 0, "foot": 0, "eye": 0, "word": 0}, "dr": {"slash": 0.0, "pierce": 0.0, "blunt": 0.0, "fire": 0.0},
		"hp": 0.0, "load": 0.0, "noise": 0.0, "parryT": 0.0, "morale": 0.0, "moraleR": 0.0, "firstLook": 0.0, "stagger": 0.0, "quiverCap": 0,
		"visMul": 1.0, "visSnowMul": 1.0, "runMul": 1.0, "snowSpeed": 1.0, "trackMul": 1.0, "animalMul": 1.0, "drawMul": 1.0, "spreadMul": 1.0,
		"strikeMul": 1.0, "eatMul": 1.0, "turnMul": 1.0, "saddleDrawMul": 1.0, "wetBowMul": 1.0, "slots": {}}
	for slot: Variant in slots_map:
		var e := str(slots_map[slot]) if slots_map[slot] != null else ""
		(out["slots"] as Dictionary)[str(slot)] = e
		out[str(slot)] = e
		if e.is_empty():
			continue
		var g := ItemCatalog.gear_of(e)
		var fine := ItemCatalog.is_fine(e)
		_fold(out, g, fine)
		var cond: Variant = g.get("cond")
		if cond is Dictionary and check.is_valid() and bool(check.call(str((cond as Dictionary).get("when", "")))):
			_fold(out, cond, fine)
	var dr: Dictionary = out["dr"]
	for t: Variant in dr:
		dr[t] = clampf(roundf(float(dr[t]) * 100.0) / 100.0, -25.0, 60.0)
	return out


const _FINE_K := 1.1


static func _fold(out: Dictionary, src: Dictionary, fine: bool) -> void:
	for key: Variant in src:
		var k := str(key)
		var v: Variant = src[key]
		if k == "when" or k == "cond":
			continue
		if k == "statBonus" and v is Dictionary:
			for stat: Variant in v:
				out["statBonus"][stat] = int(out["statBonus"].get(stat, 0)) + int(v[stat])
		elif k == "dr" and v is Dictionary:
			for t: Variant in v:
				out["dr"][t] = float(out["dr"].get(t, 0.0)) + float(v[t]) * (_FINE_K if fine else 1.0)
		elif k == "quiverCap":
			out["quiverCap"] = int(out["quiverCap"]) + int(floor(float(v) * (_FINE_K if fine else 1.0) + 1e-9))
		elif v is bool:
			out[k] = bool(out.get(k, false)) or bool(v)
		elif v is int or v is float:
			if k.ends_with("Mul") or k == "snowSpeed":
				out[k] = float(out.get(k, 1.0)) * float(v)
			else:
				out[k] = float(out.get(k, 0.0)) + float(v)


func quiver_cap() -> int:
	var q := equipped("quiver")
	if q.is_empty():
		return 0
	return int(floor(float(ItemCatalog.gear_of(q).get("quiverCap", 0)) * (_FINE_K if ItemCatalog.is_fine(q) else 1.0) + 1e-9))


func arrow_count() -> int:
	var n := 0
	for k: Variant in arrows:
		n += int(arrows[k])
	return n


## Heybedeki okları sadağa doldurur: taşınan [{id, n}].
func fill_quiver(ref := "tag:arrow") -> Array:
	var room := quiver_cap() - arrow_count()
	var moved: Array = []
	for it: Dictionary in pack.list():
		if room <= 0:
			break
		var a := str(it["id"])
		if not ItemCatalog.has_tag(a, "arrow") or not ItemCatalog.matches(a, ref):
			continue
		for got: Dictionary in pack.remove(a, room):
			arrows[got["id"]] = int(arrows.get(got["id"], 0)) + int(got["n"])
			room -= int(got["n"])
			moved.append(got)
	if not moved.is_empty():
		_changed()
	return moved


## Atış: sadaktan bir ok düşer.
func spend_arrow(arrow_id: String) -> bool:
	if int(arrows.get(arrow_id, 0)) <= 0:
		return false
	arrows[arrow_id] = int(arrows[arrow_id]) - 1
	if int(arrows[arrow_id]) == 0:
		arrows.erase(arrow_id)
	return true


func _trim_arrows() -> void:
	var over := arrow_count() - quiver_cap()
	for a: Variant in arrows.keys():
		if over <= 0:
			break
		var k := mini(over, int(arrows[a]))
		arrows[a] = int(arrows[a]) - k
		if int(arrows[a]) == 0:
			arrows.erase(a)
		pack.add(str(a), k, day, true)
		over -= k


# --- Kaplar -----------------------------------------------------------------------------------------------------------

## Menzil Ambarı (40 Yük), bağlı durak başına.
func stash(way: String) -> ItemContainer:
	if way.is_empty():
		return null
	if not _stash.has(way):
		var c := ItemContainer.make("stash", {"id": "stash.%s" % way, "owner": "player"})
		c.day = day
		_stash[way] = c
	return _stash[way]


func stash_ids() -> PackedStringArray:
	return PackedStringArray(_stash.keys())


## Terki: bineğin kendi kabı, sınırı binek Yük'ü (key "horse" ya da "horse@Doru": @'ten önce Mount satırı; cap verilirse o).
## Yük'ü 0 olan binekte (koyun) terki yoktur: null.
func saddlebags(key: String, cap := -1.0) -> ItemContainer:
	if key.is_empty():
		return null
	if not _bags.has(key):
		var load_cap := cap if cap >= 0.0 else CarryLoad.mount_cap(key.get_slice("@", 0))
		if load_cap <= 0.0:
			return null
		var c := ItemContainer.make("saddlebags", {"id": "saddlebags.%s" % key, "cap": load_cap, "owner": "player"})
		c.day = day
		_bags[key] = c
	return _bags[key]


func mount_ids() -> PackedStringArray:
	return PackedStringArray(_bags.keys())


## Terkinin hız çarpanı ve dörtnalı (binicilik okur; economy.md §4.7).
func mount_mods(key: String) -> Dictionary:
	var bag: ItemContainer = _bags.get(key)
	var l := CarryLoad.frac(bag.load_amount(), bag.cap()) if bag else 0.0
	return {"speed_k": CarryLoad.mount_speed_k(l), "can_gallop": CarryLoad.can_gallop(l), "load": bag.load_amount() if bag else 0.0,
		"cap": bag.cap() if bag else 0.0}


## Kaydı başka blokta olan kaplar (şantiye, yerleşimin ambarı, StorePool): fn(kind, id) -> ItemContainer ya da null.
func set_resolver(fn: Callable) -> void:
	_resolver = fn


func site(site_id: String) -> Variant:
	return _resolve("site", site_id)


func store(store_id: String) -> Variant:
	return _resolve("store", store_id)


func _resolve(kind: String, ref_id: String) -> Variant:
	return _resolver.call(kind, ref_id) if _resolver.is_valid() else null


## Kimlikten kap: "pack", "purse", "chest", "cart", "sled", "seized", "stash.<durak>", "saddlebags.<binek>", "cache.<direk>",
## "pile.<n>", "site.<id>", "store.<id>"; gerisi çözücüye "store" olarak.
func container(ref: String) -> Variant:
	match ref:
		"pack":
			return pack
		"purse":
			return purse
		"chest":
			return chest
		"cart":
			return cart
		"sled":
			return sled
		"seized":
			return seized.get("sack")
	var head := ref.get_slice(".", 0)
	var tail := ref.substr(head.length() + 1) if ref.contains(".") else ""
	match head:
		"stash":
			return stash(tail)
		"saddlebags":
			return _bags.get(tail)
		"cache":
			return cache.at(tail)
		"pile":
			for p: ItemContainer in _piles:
				if p.id == ref:
					return p
			return null
		"site", "store":
			return _resolve(head, tail)
	return _resolve("store", ref)


## Kaplar arası aktarma (item_moved); şantiye yığınına bohça açılarak girer (economy.md §4.6 madde 7). {moved, rest, items}.
func move(from: ItemContainer, to: ItemContainer, ref: String, n := 1, allow_over := false, filter := Callable()) -> Dictionary:
	var r := ItemContainer.transfer(from, to, ref, n, allow_over, filter, to != null and to.kind == "site")
	_after_move(from, to, r["items"])
	return r


## Toplu aktarma (hızlı düğmeler): list verilmezse kabın bütün içeriği (filter süzer). {moved: [{id, n}], rest: [{id, n}]}.
func move_all(from: ItemContainer, to: ItemContainer, list: Variant = null, filter := Callable(), allow_over := false) -> Dictionary:
	var r := ItemContainer.transfer_all(from, to, list, filter, allow_over, to != null and to.kind == "site")
	_after_move(from, to, r["moved"])
	return r


## Hızlı düğmeler (economy.md §4.6 madde 2): Sırtı Boşalt (tag:bulk), Malzemeyi Bırak (Zanaat), Yiyeceği Bırak (Erzak), Hepsini Al,
## Eksikleri Al (need: [{id, n}]: seçili tarifin ya da şantiyenin girdisi; heybede olan düşülür).
func unload_back(to: ItemContainer) -> Dictionary:
	return move_all(pack, to, null, func(item_id: String) -> bool: return ItemCatalog.has_tag(item_id, "bulk"))


func store_materials(to: ItemContainer) -> Dictionary:
	return move_all(pack, to, null, func(item_id: String) -> bool: return ItemCatalog.tab_of(item_id) == "craft")


func store_food(to: ItemContainer) -> Dictionary:
	return move_all(pack, to, null, func(item_id: String) -> bool: return ItemCatalog.tab_of(item_id) == "food")


func take_all(from: ItemContainer) -> Dictionary:
	return move_all(from, pack)


func take_missing(from: ItemContainer, need: Array) -> Dictionary:
	var list: Array = []
	for row: Dictionary in need:
		var lack := int(row.get("n", 0)) - pack.count(str(row.get("id", "")))
		if lack > 0:
			list.append({"id": str(row["id"]), "n": lack})
	return move_all(from, pack, list)


## Heybeden bir kaba ve kaptan Heybe'ye.
func deliver_to(c: ItemContainer, ref: String, n := 1) -> Dictionary:
	return move(pack, c, ref, n)


func take_from(c: ItemContainer, ref: String, n := 1) -> Dictionary:
	return move(c, pack, ref, n)


# --- Yer yığını (economy.md §4.5: sınırsız; dünyada en çok 24) ---------------------------------------------------------

## Bırakır: heybeden (kuşanılıysa önce çıkarılır) yere. Görevlik eşya (Hatıra) atılmaz. Dönüş: yığın ya da null.
## at: dünya noktası; 1,5 m içinde yığın varsa ona katılır; 24 yığın doluysa en yakınına.
func drop(item_id: String, n: int, at: Vector3) -> ItemContainer:
	if n <= 0 or not ItemCatalog.has(item_id) or ItemCatalog.is_keepsake(item_id) or is_locked(item_id):
		return null
	var slot := ""
	for s: String in _slots:
		if _slots[s] == item_id:
			slot = s
	if pack.amount(item_id) <= 0 and not slot.is_empty():
		unequip(slot)
	if ItemCatalog.is_tool_item(item_id) and _tools.has(item_id):
		var tpile := _pile_for(at)
		_tools.erase(item_id)
		tpile.add(item_id, 1, day, true)
		item_moved.emit("tools", tpile.id, item_id, 1)
		pile_changed.emit(tpile, _pile_at[tpile.id])
		_changed()
		return tpile
	var have := pack.amount(item_id)
	if have <= 0:
		return null
	var pile := _pile_for(at)
	var r := ItemContainer.transfer(pack, pile, item_id, mini(n, have), true)
	_after_move(pack, pile, r["items"])
	pile_changed.emit(pile, _pile_at[pile.id])
	return pile


## Yığından alır (yerdeki yığını E ile almak): sığdığı kadar heybeye, kalan yerde kalır; boşalan yığın kalkar. {moved, rest}.
func take_pile(pile: ItemContainer) -> Dictionary:
	if pile == null or not _piles.has(pile):
		return {"moved": [], "rest": []}
	var tools_moved: Array = []
	for it: Dictionary in pile.list():
		var item_id := str(it["id"])
		if ItemCatalog.is_tool_item(item_id) and not _tools.has(item_id):
			pile.remove(item_id, 1)
			_tools.append(item_id)
			tools_moved.append({"id": item_id, "n": 1})
	var r := move_all(pile, pack)
	(r["moved"] as Array).append_array(tools_moved)
	if not tools_moved.is_empty():
		_changed()
	if pile.is_empty():
		_piles.erase(pile)
		_pile_at.erase(pile.id)
		pile_removed.emit(pile)
	else:
		pile_changed.emit(pile, _pile_at[pile.id])
	return r


func piles() -> Array:
	return _piles.duplicate()


func pile_position(pile: ItemContainer) -> Vector3:
	return _pile_at.get(pile.id, Vector3.ZERO) if pile else Vector3.ZERO


## Yer yığınlarını unutur (dünya değişti: yığınlar dünyanındır).
func clear_piles() -> void:
	for p: ItemContainer in _piles.duplicate():
		pile_removed.emit(p)
	_piles.clear()
	_pile_at.clear()


func _pile_for(at: Vector3) -> ItemContainer:
	var best: ItemContainer = null
	var best_d := INF
	for p: ItemContainer in _piles:
		var d := (_pile_at[p.id] as Vector3).distance_to(at)
		if d < best_d:
			best = p
			best_d = d
	var limit := int(CarryLoad.rules().get("ground_piles_max", 24))
	if best and (best_d <= 1.5 or _piles.size() >= limit):
		return best
	_pile_serial += 1
	var pile := ItemContainer.make("ground_pile", {"id": "pile.%d" % _pile_serial, "owner": "world"})
	pile.day = day
	_piles.append(pile)
	_pile_at[pile.id] = at
	return pile


# --- El koyma (sentenced; progression.md §6.1; act1.md §8.4; economy.md §4.4) -------------------------------------------

## Heybe, araçlar, sandık, araba, kızak, Menzil ambarları, terkiler ve giyilmeyen yuvalar tek çuvala gider. Kalır: gövde, sırt, el,
## çizme; levha; çizmedeki bıçak; görevlik eşya (Çığırtkan, Çentik Çubuğu, çetele yarımları); Zula ve kese. Dönüş: çuvalın özeti.
func seize() -> Dictionary:
	var prev := seized
	var sack: ItemContainer = prev.get("sack") if not prev.is_empty() else ItemContainer.make("seized", {"owner": "stores"})
	if prev.is_empty():
		sack.day = day
	var keep := func(item_id: String) -> bool: return _kept_at_seizure(item_id)
	var sources: Array = [pack, chest, cart, sled]
	sources.append_array(_stash.values())
	sources.append_array(_bags.values())
	for c: ItemContainer in sources:
		var r := ItemContainer.transfer_all(c, sack, null, func(item_id: String) -> bool: return not keep.call(item_id), true)
		for it: Dictionary in r["moved"]:
			item_moved.emit(c.id, sack.id, str(it["id"]), int(it["n"]))
	var tools_out: Array = (prev.get("tools", []) as Array).duplicate()
	for t: String in _tools.duplicate():
		if keep.call(t):
			continue
		_tools.erase(t)
		tools_out.append(t)
	var equip_out: Dictionary = (prev.get("equip", {}) as Dictionary).duplicate()
	var keep_slots: Array = _seize_keep().get("slots", [])
	for slot: String in _slots:
		var e := str(_slots[slot])
		if e.is_empty() or keep_slots.has(slot) or keep.call(e):
			continue
		if equip_out.has(slot):
			sack.add(e, 1, day, true)
		else:
			equip_out[slot] = e
		_slots[slot] = ""
		equip_changed.emit(slot, "", e)
	var arrows_out: Dictionary = (prev.get("arrows", {}) as Dictionary).duplicate()
	if equipped("quiver").is_empty():
		for a: Variant in arrows:
			arrows_out[a] = int(arrows_out.get(a, 0)) + int(arrows[a])
		arrows = {}
	seized = {"sack": sack, "tools": tools_out, "equip": equip_out, "arrows": arrows_out}
	_changed()
	return {"items": sack.list(), "tools": tools_out.duplicate(), "equip": equip_out.duplicate()}


## Ambar'dan geri alınan çuval (mq_errands): hepsi heybeye (sınırı geçebilir), araçlar ve yuvalar yerine. Çuval yoksa {}.
func restore_seized() -> Dictionary:
	if seized.is_empty():
		return {}
	var sack: ItemContainer = seized["sack"]
	var r := ItemContainer.transfer_all(sack, pack, null, Callable(), true)
	for it: Dictionary in r["moved"]:
		item_moved.emit(sack.id, pack.id, str(it["id"]), int(it["n"]))
	for t: Variant in seized["tools"]:
		if not _tools.has(str(t)):
			_tools.append(str(t))
	for slot: Variant in seized["equip"]:
		var e := str(seized["equip"][slot])
		if not str(_slots.get(slot, "")).is_empty():
			pack.add(e, 1, day, true)
		else:
			_slots[str(slot)] = e
			equip_changed.emit(str(slot), e, "")
	for a: Variant in seized["arrows"]:
		arrows[a] = int(arrows.get(a, 0)) + int(seized["arrows"][a])
	_trim_arrows()
	var out := {"items": r["moved"], "tools": (seized["tools"] as Array).duplicate(), "equip": (seized["equip"] as Dictionary).duplicate()}
	seized = {}
	_changed()
	return out


func _seize_keep() -> Dictionary:
	var k: Variant = ItemContainer.rules().get("seize_keep", {})
	return k if k is Dictionary else {}


func _kept_at_seizure(item_id: String) -> bool:
	var keep := _seize_keep()
	if (keep.get("items", []) as Array).has(ItemCatalog.base_id(item_id)):
		return true
	for t: Variant in keep.get("tags", []):
		if ItemCatalog.has_tag(item_id, str(t)):
			return true
	return false


## Sahibinin bayrağı (FlagStore): sentenced yazılınca el koyma.
func on_flag(key: String, value: Variant, prev: Variant = null) -> void:
	if key == "sentenced" and bool(value) and not bool(prev):
		seize()


# --- Şafak ve bozulma (economy.md §2.10; time.md §7.4) ---------------------------------------------------------------

## Şafak (sahibi her şafakta çağırır). İlk gerçek şafakta bilinmeyen sayaç ona kaydırılır: eldeki çiğ yiyecek dünün sayılır. Dönüş:
## bozulan [{container, id, n}]; her biri item_spoiled.
func on_dawn(p_day: int) -> Array:
	if not _day_known:
		_rebase(p_day - 1)
		_day_known = true
	return _advance(p_day)


## Uzun atlama (≥24 sa): şafaklar tek tek değil, bir kez ve şafak sayısı kadar ileri.
func on_long_skip(dawns: int) -> Array:
	return _advance(day + dawns) if dawns > 0 else []


## Kesin gün: sayaç ve bütün gün parçaları ona kaydırılır.
func set_day(p_day: int) -> void:
	_rebase(p_day)
	_day_known = true


## Dünya kuralı: kış dünyasında balık donuktur (spec.perish.fish false).
func set_world(spec: Dictionary) -> void:
	var p: Variant = spec.get("perish", {})
	perish_fish = not (p is Dictionary and (p as Dictionary).get("fish", true) == false)


func _containers() -> Array:
	var list: Array = [pack, purse, chest, cart, sled]
	list.append_array(_stash.values())
	list.append_array(_bags.values())
	list.append_array(_piles)
	if not seized.is_empty():
		list.append(seized["sack"])
	return list


func _rebase(p_day: int) -> void:
	var delta := p_day - day
	if delta == 0:
		return
	for c: ItemContainer in _containers():
		c.shift_days(delta)
	cache.shift_days(delta)
	day = p_day


func _advance(p_day: int) -> Array:
	if p_day <= day:
		return []
	day = p_day
	var out: Array = []
	for c: ItemContainer in _containers():
		for s: Dictionary in c.on_dawn(p_day, perish_fish):
			out.append({"container": c.id, "id": s["id"], "n": s["n"]})
	for s: Dictionary in cache.on_dawn(p_day, perish_fish):
		out.append({"container": "cache.%s" % s["rb"], "id": s["id"], "n": s["n"]})
	for s: Dictionary in out:
		item_spoiled.emit(str(s["container"]), str(s["id"]), int(s["n"]))
	if not out.is_empty():
		_changed()
	return out


# --- Başlangıç ve beden ------------------------------------------------------------------------------------------------

## Bütün kişisel kapları boşaltır (beden ve gün kalır).
func clear_all() -> void:
	for c: ItemContainer in [pack, purse, chest, cart, sled]:
		c.clear()
	_tools.clear()
	for slot: String in _slots:
		_slots[slot] = ""
	_stash.clear()
	_bags.clear()
	clear_piles()
	cache.clear()
	seized = {}
	arrows = {}
	bell = {"on": true, "plug": false, "fate": null}
	sled_on = false
	_changed()


## Başlangıç donanımı (items.json kits): kuşanılanlar yuvaya, gerisi heybeye (sınırı geçebilir).
func apply_kit(kit_name: String) -> void:
	var k := ItemCatalog.kit(kit_name)
	var eq: Variant = k.get("equip", {})
	for slot: Variant in (eq if eq is Dictionary else {}):
		equip(str(slot), str(eq[slot]))
	var pk: Variant = k.get("pack", {})
	for item_id: Variant in (pk if pk is Dictionary else {}):
		add(str(item_id), int(pk[item_id]), "kit", true)


## Yeni beden ya da sahne: boş envanter, bedenin sınırı; çocuk oyuncak yayıyla (kits.child; yay kilitli).
func reset_body(p_body: String) -> void:
	body = p_body
	clear_all()
	_locked = []
	if body == BODY_CHILD:
		apply_kit("child")
		var lk: Variant = ItemCatalog.kit("child").get("locked", [])
		_locked = (lk as Array).duplicate() if lk is Array else []
	_changed()


# --- Kayıt (godot.md §3.4 kayıt v2, blok «inventory») -------------------------------------------------------------------

## Blok: {v, body, day, pack, purse, tools, equip, arrows, bell, chest, cart, sled, sled_on, stash, saddlebags, cache, seized, piles}.
## Kaplar ItemContainer.to_dict biçimindedir (gün parçaları dahil). Yer yığınının yeri [x, y, z].
func to_dict() -> Dictionary:
	var stash_out := {}
	for k: Variant in _stash:
		stash_out[k] = (_stash[k] as ItemContainer).to_dict()
	var bags_out := {}
	for k: Variant in _bags:
		bags_out[k] = {"cap": (_bags[k] as ItemContainer).cap(), "box": (_bags[k] as ItemContainer).to_dict()}
	var piles_out: Array = []
	for p: ItemContainer in _piles:
		var at: Vector3 = _pile_at[p.id]
		piles_out.append({"at": [at.x, at.y, at.z], "box": p.to_dict()})
	var seized_out: Variant = null
	if not seized.is_empty():
		seized_out = {"box": (seized["sack"] as ItemContainer).to_dict(), "tools": (seized["tools"] as Array).duplicate(),
			"equip": (seized["equip"] as Dictionary).duplicate(), "arrows": (seized["arrows"] as Dictionary).duplicate()}
	return {
		"v": SAVE_V, "body": body, "day": day, "day_known": _day_known, "grip": grip, "carry_pack": carry_pack, "purse_on": purse_on, "locked": _locked.duplicate(),
		"pack": pack.to_dict(), "purse": purse.to_dict(), "tools": Array(_tools), "equip": _slots.duplicate(), "arrows": arrows.duplicate(),
		"bell": bell.duplicate(), "chest": chest.to_dict(), "cart": cart.to_dict(), "sled": sled.to_dict(), "sled_on": sled_on,
		"stash": stash_out, "saddlebags": bags_out, "cache": cache.to_dict(), "seized": seized_out, "piles": piles_out,
	}


## Bloğu okur; eksik ya da bozuk alan boş açılır (bilinmeyen eşya bir uyarıyla düşer, yanlış yuvadaki eşya kuşanılmaz). Bozuk blok
## (sözlük değil) false döndürür ve envantere dokunmaz: sahibi kaydı «boş yuva» sayar (godot.md §3.4).
func from_dict(d: Variant) -> bool:
	if not d is Dictionary:
		return false
	var o := d as Dictionary
	clear_all()
	body = str(o.get("body", body))
	day = int(o.get("day", day)) if _num(o.get("day")) else day
	_day_known = bool(o.get("day_known", day != 0))
	grip = float(o.get("grip", grip)) if _num(o.get("grip")) else grip
	carry_pack = bool(o.get("carry_pack", false))
	purse_on = bool(o.get("purse_on", false))
	_locked = []
	for k: Variant in (o.get("locked", []) if o.get("locked") is Array else []):
		if ItemCatalog.has(str(k)):
			_locked.append(str(k))
	pack.from_dict(o.get("pack", {}), day)
	purse.from_dict(o.get("purse", {}), day)
	for t: Variant in (o.get("tools", []) if o.get("tools") is Array else []):
		if ItemCatalog.is_tool_item(str(t)) and not _tools.has(str(t)):
			_tools.append(str(t))
	var eq: Variant = o.get("equip", {})
	for slot: String in _slots:
		var e := str((eq as Dictionary).get(slot, "")) if eq is Dictionary and (eq as Dictionary).get(slot) != null else ""
		_slots[slot] = e if not e.is_empty() and ItemCatalog.slot_of(e) == slot else ""
	arrows = {}
	var ar: Variant = o.get("arrows", {})
	for a: Variant in (ar if ar is Dictionary else {}):
		if ItemCatalog.has_tag(str(a), "arrow") and _num(ar[a]) and int(ar[a]) >= 1:
			arrows[str(a)] = int(ar[a])
	var b: Variant = o.get("bell", {})
	if b is Dictionary:
		bell = {"on": (b as Dictionary).get("on", true) != false, "plug": (b as Dictionary).get("plug", false) == true, "fate": (b as Dictionary).get("fate")}
	chest.from_dict(o.get("chest", {}), day)
	cart.from_dict(o.get("cart", {}), day)
	sled.from_dict(o.get("sled", {}), day)
	sled_on = bool(o.get("sled_on", false))
	var st: Variant = o.get("stash", {})
	for k: Variant in (st if st is Dictionary else {}):
		var c := stash(str(k))
		if c:
			c.from_dict(st[k], day)
	var bg: Variant = o.get("saddlebags", {})
	for k: Variant in (bg if bg is Dictionary else {}):
		var entry: Variant = bg[k]
		if not entry is Dictionary:
			continue
		var cap := float((entry as Dictionary).get("cap", -1.0)) if _num((entry as Dictionary).get("cap")) else -1.0
		var c := saddlebags(str(k), cap)
		if c:
			c.from_dict((entry as Dictionary).get("box", {}), day)
	cache.from_dict(o.get("cache", []), day)
	var sz: Variant = o.get("seized")
	if sz is Dictionary:
		var sack := ItemContainer.make("seized", {"owner": "stores"})
		sack.from_dict((sz as Dictionary).get("box", {}), day)
		var tools_in: Array = []
		for t: Variant in ((sz as Dictionary).get("tools", []) if (sz as Dictionary).get("tools") is Array else []):
			if ItemCatalog.is_tool_item(str(t)):
				tools_in.append(str(t))
		var equip_in := {}
		var se: Variant = (sz as Dictionary).get("equip", {})
		for slot: Variant in (se if se is Dictionary else {}):
			if _slots.has(str(slot)) and ItemCatalog.slot_of(str(se[slot])) == str(slot):
				equip_in[str(slot)] = str(se[slot])
		var arrows_in := {}
		var sa: Variant = (sz as Dictionary).get("arrows", {})
		for a: Variant in (sa if sa is Dictionary else {}):
			if ItemCatalog.has_tag(str(a), "arrow") and _num(sa[a]) and int(sa[a]) >= 1:
				arrows_in[str(a)] = int(sa[a])
		seized = {"sack": sack, "tools": tools_in, "equip": equip_in, "arrows": arrows_in}
	var pl: Variant = o.get("piles", [])
	for entry: Variant in (pl if pl is Array else []):
		if not entry is Dictionary:
			continue
		var at_raw: Variant = (entry as Dictionary).get("at", [])
		var at := Vector3.ZERO
		if at_raw is Array and (at_raw as Array).size() == 3:
			at = Vector3(float(at_raw[0]), float(at_raw[1]), float(at_raw[2]))
		_pile_serial += 1
		var pile := ItemContainer.make("ground_pile", {"id": "pile.%d" % _pile_serial, "owner": "world"})
		pile.from_dict((entry as Dictionary).get("box", {}), day)
		if pile.is_empty():
			continue
		_piles.append(pile)
		_pile_at[pile.id] = at
	_changed()
	return true


## Düz durum (sınama ve geliştirme paneli).
func snapshot() -> Dictionary:
	var bags := {}
	for k: Variant in _bags:
		bags[k] = (_bags[k] as ItemContainer).list()
	var stashes := {}
	for k: Variant in _stash:
		stashes[k] = (_stash[k] as ItemContainer).list()
	return {"day": day, "load": load_amount(), "cap": capacity(), "speed_k": speed_k(), "pack": pack.list(), "purse": purse.list(),
		"tools": Array(_tools), "equip": _slots.duplicate(), "arrows": arrows.duplicate(), "bell": bell.duplicate(), "chest": chest.list(),
		"cart": cart.list(), "sled": sled.list(), "stash": stashes, "saddlebags": bags, "cache": cache.snapshot(),
		"seized": {} if seized.is_empty() else {"items": (seized["sack"] as ItemContainer).list(), "tools": (seized["tools"] as Array).duplicate(),
			"equip": (seized["equip"] as Dictionary).duplicate()}}


# --- İç ------------------------------------------------------------------------------------------------------------------

func _after_move(from: ItemContainer, to: ItemContainer, items: Array) -> void:
	for it: Dictionary in items:
		item_moved.emit(from.id if from else "", to.id if to else "", str(it["id"]), int(it["n"]))
	if not items.is_empty():
		_changed()


## changed her değişimde; load_changed yalnız değer değişince.
func _changed() -> void:
	changed.emit()
	var l := load_amount()
	var c := capacity()
	if is_equal_approx(l, _sent_load) and is_equal_approx(c, _sent_cap):
		return
	_sent_load = l
	_sent_cap = c
	load_changed.emit(l, c)


static func _sum(list: Array) -> int:
	var s := 0
	for it: Dictionary in list:
		s += int(it["n"])
	return s


static func _num(v: Variant) -> bool:
	return v is int or v is float


## Zula: onarılmış direk başına bir kap (6 Yük, 4 yığın; gizli: nöbet ve Hüküm bulmaz), en çok altı. Kap yüzü yuvaların toplamıdır.
class CacheSet:
	extends RefCounted

	var max_spots := 6
	var day := 0
	var _spots: Dictionary = {}

	func _init() -> void:
		max_spots = int(ItemContainer.rules().get("cache_spots", 6))

	func size() -> int:
		return _spots.size()

	## Toplam sınır (Yük).
	func cap() -> float:
		return float(max_spots) * float(ItemContainer.kind_row("cache").get("cap", 6))

	func at(rb: String) -> ItemContainer:
		return _spots.get(rb)

	## Yuva yoksa açar; altı dolduysa null.
	func open(rb: String) -> ItemContainer:
		if _spots.has(rb):
			return _spots[rb]
		if rb.is_empty() or _spots.size() >= max_spots:
			return null
		var c := ItemContainer.make("cache", {"id": "cache.%s" % rb, "owner": "player"})
		c.day = day
		_spots[rb] = c
		return c

	func spots() -> PackedStringArray:
		return PackedStringArray(_spots.keys())

	func list() -> Array:
		var sum := {}
		for c: ItemContainer in _spots.values():
			for it: Dictionary in c.list():
				sum[it["id"]] = int(sum.get(it["id"], 0)) + int(it["n"])
		var out: Array = []
		for k: Variant in sum:
			out.append({"id": k, "n": sum[k]})
		return out

	func count(ref: String) -> int:
		var n := 0
		for c: ItemContainer in _spots.values():
			n += c.count(ref)
		return n

	func load_amount() -> float:
		var s := 0
		for c: ItemContainer in _spots.values():
			s += c.load10()
		return s / 10.0

	## rb verilirse o yuvaya (yoksa açar), verilmezse açık yuvalara sırayla.
	func add(item_id: String, n: int, rb := "", p_day := ItemContainer.NO_DAY) -> Dictionary:
		if not rb.is_empty():
			var c := open(rb)
			return c.add(item_id, n, p_day) if c else {"added": 0, "rest": n}
		var added := 0
		var rest := n
		for c: ItemContainer in _spots.values():
			if rest <= 0:
				break
			var r := c.add(item_id, rest, p_day)
			added += int(r["added"])
			rest = int(r["rest"])
		return {"added": added, "rest": rest}

	func remove(ref: String, n := 1, rb := "") -> Array:
		if not rb.is_empty():
			return (_spots[rb] as ItemContainer).remove(ref, n) if _spots.has(rb) else []
		var out: Array = []
		var left := n
		for c: ItemContainer in _spots.values():
			if left <= 0:
				break
			var got := c.remove(ref, left)
			out.append_array(got)
			left -= Inventory._sum(got)
		return out

	func on_dawn(p_day: int, perish_fish := true) -> Array:
		day = p_day
		var out: Array = []
		for rb: Variant in _spots:
			for s: Dictionary in (_spots[rb] as ItemContainer).on_dawn(p_day, perish_fish):
				out.append({"rb": rb, "id": s["id"], "n": s["n"]})
		return out

	func shift_days(delta: int) -> void:
		if delta == 0:
			return
		day += delta
		for c: ItemContainer in _spots.values():
			c.shift_days(delta)

	func clear() -> void:
		_spots.clear()

	## [{rb, box}]: yuvaların içeriği ve gün parçaları.
	func to_dict() -> Array:
		var out: Array = []
		for rb: Variant in _spots:
			out.append({"rb": rb, "box": (_spots[rb] as ItemContainer).to_dict()})
		return out

	func from_dict(list: Variant, p_day := ItemContainer.NO_DAY) -> void:
		clear()
		if p_day != ItemContainer.NO_DAY:
			day = p_day
		for entry: Variant in (list if list is Array else []):
			if not entry is Dictionary or not (entry as Dictionary).get("rb") is String:
				continue
			var c := open(str(entry["rb"]))
			if c == null:
				break
			c.from_dict((entry as Dictionary).get("box", {}), day)

	func snapshot() -> Array:
		var out: Array = []
		for rb: Variant in _spots:
			out.append({"rb": rb, "items": (_spots[rb] as ItemContainer).list()})
		return out
