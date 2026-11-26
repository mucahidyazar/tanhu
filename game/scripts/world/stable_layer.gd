class_name StableLayer
extends Node3D
## Ahırın işleri: Bağ'ın oyundaki tetikleri (Yol Haritası mount-bond-actions; progression.md §6.4, fauna.md §2.1 «Bağ», act1.md §8.8, §16
## «Antlar»). map.json «layers» → data/maps/<id>/stable.json («script» bu dosya); MapLayers kurar. Kurallar ve sınırlar MountStable'dadır
## (yem +5 günde 3, tımar +2 günde 1, ad +10 bir kez, ant +10 bir kez); bu katman onları oyuncunun eylemine bağlar.
##
## Ahır bir alandır (stables: {at, radius}); atlar haritanın kayıtlarından (ref: MapWorld.horse) ya da katmanın kurduğu atlardır (Kışlak'ın
## ahırı: Yakve ve 8 at; RideableHorse, binilir). Atın başında (yüzünün önü, ≤1,5 m) ve atın alanın içindeyken:
##   E        Yem Ver (heybede Yem Bağı; yoksa 2 ot varsa Yem Bağı yap, 2 sn: ahırın tarifi rc_fodder)
##   E basılı Tımar (4 sn)
##   F        Ad Koy (adı konmamış ve adı sabit olmayan at; öneri listesi ya da yazı) · Ant İç (antı olan at: act1.md §8.8 oath_stallion) ·
##            Yular Tak / Yuları Çıkar (bridle yuvası; yular binişte atı tutmanın süresini kaldırır, MountStable.take_seconds)
## Atın yanında E yine biner (oyuncunun binişi). İpucu HUD'un şeridindedir (atın adı ve Bağ'ı yazar). Bağ kaydı oyuncunun MountStable'ıdır
## (kayıt v2 «mounts»); atın ilk kaydında köken payı ve ahırın eşyası (gear: ahırdaki at eyersiz ve yularsız durur) yazılır.

const PROCESS_PRIORITY := 6
const HEAD_REACH := 1.5
const HEAD_FORWARD := 1.25
const GROOM_S := 4.0
const E_TAP_S := 0.3
const FODDER_RECIPE := "rc_fodder"
## Ahırın atlarının görünürlük aralığı (m; kadraj ≈±30 m, sis ötesi çizilmez).
const HORSE_RANGE := 90.0
const OATH_TEXT := {
	"oath_stallion": {"tr": "«Bir gün senden vazgeçmem istenirse, önce sana bakacağım.»",
		"en": "«If I am ever asked to give you up, I will look at you first.»"},
}

var world: Node3D
var def: Dictionary = {}
var lang := "tr"
var main: Node
var player: PlayerController
var hud: GameplayHud
var camera: FollowCamera
var session: Session

## Ahırlar: [{id, at: Vector2, radius, name}]; atlar: mount_key → {node: Rideable, row, stable, key}.
var stables: Array = []
var horses: Dictionary = {}
## Sınamanın heybesi ve günü (boşsa oturumunki).
var inventory_override: Inventory
var day_override := -1

var _attached := false
var _built := false
var _e: Dictionary = {}
var _work: Dictionary = {}
var _dialog_layer: CanvasLayer
var _sent: Array = []
var _base_pairs: Array = []
var _emitting := false
var _mine_shown := false
var _kit_given := false


func setup(p_world: Node3D, p_def: Dictionary) -> void:
	world = p_world
	def = p_def


func _ready() -> void:
	process_priority = PROCESS_PRIORITY
	for s: Variant in def.get("stables", []):
		if s is Dictionary:
			stables.append({"id": str(s.get("id", "stable")), "at": RoadGraph.vec2(s.get("at", [0.0, 0.0])), "radius": float(s.get("radius", 12.0)),
				"name": s.get("name", {}), "horses": s.get("horses", []), "record": str(s.get("record", ""))})
	_build_horses.call_deferred()


func _exit_tree() -> void:
	_detach()


func _ground_y(p: Vector2) -> float:
	var g: Variant = world.call(&"get_terrain_shape") if world and world.has_method(&"get_terrain_shape") else null
	return float((g as Object).call(&"height_at", p.x, p.y)) if g else 0.0


## Ahırın atları: haritanın atı (ref) ya da burada kurulan at (id, mount, model, at, facing).
func _build_horses() -> void:
	if _built:
		return
	_built = true
	for st: Dictionary in stables:
		# Bölmeler yapı katmanının ahırındandır (StructureKit.stable_stalls: arka duvardan 1,7 m, önü kapıya); yeri verilmeyen at sıradaki bölmeye.
		var stalls := _stalls_of(st)
		for h: Variant in st["horses"]:
			if not h is Dictionary:
				continue
			var row := (h as Dictionary).duplicate(true)
			if not row.has("ref") and not row.has("at") and not stalls.is_empty():
				var stall: Dictionary = stalls.pop_front()
				row["at"] = [(stall["at"] as Vector2).x, (stall["at"] as Vector2).y]
				row["facing"] = float(stall["facing"])
			var node: Rideable = null
			if row.has("ref") and world and world.has_method(&"horse"):
				node = world.call(&"horse", str(row["ref"]))
			elif row.has("at"):
				node = _make_horse(row)
			if node == null or not is_instance_valid(node):
				continue
			horses[node.mount_key()] = {"node": node, "row": row, "stable": str(st["id"]), "key": node.mount_key()}


## Ahırın bölmeleri (dünya): stables[].record haritanın yapı kaydının kimliğiyse (map.json structures) yapı katmanının bölmeleri; yoksa boş.
func _stalls_of(st: Dictionary) -> Array:
	var rec_id := str(st.get("record", ""))
	var spec: Variant = world.get("spec") if world else null
	if rec_id.is_empty() or not spec is MapSpec:
		return []
	for rec: Dictionary in (spec as MapSpec).structures:
		if str(rec.get("id", "")) == rec_id:
			return StructureKit.stable_stalls(rec)
	return []


func _make_horse(row: Dictionary) -> RideableHorse:
	var horse := RideableHorse.new()
	horse.name = str(row.get("node", str(row.get("id", "Horse")).to_pascal_case()))
	horse.mount_id = str(row.get("mount", "horse"))
	var path := "res://assets/animals/%s/%s.glb" % [str(row.get("model", "horse_brown")), str(row.get("model", "horse_brown"))]
	horse.model_path = path if ResourceLoader.exists(path) else ""
	horse.effects_enabled = bool(row.get("effects", true))
	add_child(horse)
	var at := RoadGraph.vec2(row["at"])
	horse.place(Vector3(at.x, _ground_y(at), at.y), DepartWorld.yaw_of(float(row.get("facing", 0.0))))
	# Bütçe (K63): ahırın çatısı altındaki atlar gölge vermez (shadow: true açar), uzaktan çizilmez (range m).
	for mi: MeshInstance3D in horse.find_children("*", "MeshInstance3D", true, false):
		if not bool(row.get("shadow", false)):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = float(row.get("range", HORSE_RANGE))
	return horse


# --- Bağlanma ----------------------------------------------------------------------------------------------------------

func _find_main() -> Node:
	var n: Node = get_parent()
	while n:
		if "player" in n and "gameplay_hud" in n:
			return n
		n = n.get_parent()
	var tree := get_tree()
	var scene := tree.current_scene if tree else null
	if scene and "player" in scene and "gameplay_hud" in scene:
		return scene
	return null


func _live() -> bool:
	if main == null or not is_instance_valid(main):
		main = _find_main()
	if main == null:
		return false
	var p: Variant = main.get("player")
	var h: Variant = main.get("gameplay_hud")
	if not p is PlayerController or not h is GameplayHud or (p as PlayerController).is_child():
		return false
	var host: Variant = main.get("world_host")
	if host is WorldHost and (host as WorldHost).map_world != world:
		return false
	return (h as GameplayHud).is_shown()


func _attach() -> void:
	player = main.get("player")
	hud = main.get("gameplay_hud")
	camera = main.get("follow_camera") as FollowCamera
	var s: Variant = main.get("session")
	session = s if s is Session and is_instance_valid(s) else null
	lang = SubtitleBar.ui_lang()
	if not player.prompt_changed.is_connected(_on_player_prompt):
		player.prompt_changed.connect(_on_player_prompt)
	_base_pairs = player.prompt_pairs() if player.is_active() else []
	for key: String in horses:
		_ensure_entry(key)
	_give_kit()
	_attached = true


func _detach() -> void:
	if not _attached:
		return
	_attached = false
	_close_dialog()
	if is_instance_valid(hud):
		hud.show_hold("", 0.0)
	if is_instance_valid(player) and player.prompt_changed.is_connected(_on_player_prompt):
		player.prompt_changed.disconnect(_on_player_prompt)
		player.prompt_changed.emit(player.prompt_pairs() if player.is_active() else [])


## Deneme takımı (def.kit) yalnız yeni yolculukta (Session.fresh «inventory»).
func _give_kit() -> void:
	if _kit_given:
		return
	_kit_given = true
	var kit: Dictionary = def.get("kit", {})
	if kit.is_empty() or (session and not session.fresh("inventory")):
		return
	var inv := _inv()
	if inv == null:
		return
	# Takım ahırın ilk atının terkisine konur (yoksa Heybe'ye): Heybe'nin hafif deneme takımı (survival.json «kit»: koşu ve zıplama açık)
	# bozulmasın; Heybe'ye Envanter'in Terki sekmesinden alınır.
	var bag: ItemContainer = null
	for key: String in horses:
		bag = inv.saddlebags(key)
		if bag:
			break
	for id: String in kit:
		if not ItemCatalog.has(id):
			continue
		if bag and not ItemCatalog.is_tool_item(id) and int(bag.add(id, int(kit[id]), inv.day, true)["added"]) > 0:
			continue
		inv.add(id, int(kit[id]), "kit", true)


func stable() -> MountStable:
	if player.mount_stable == null:
		player.mount_stable = MountStable.new()
	return player.mount_stable


## Atın kaydı: ilk kezse köken payıyla (oyuncunun kökeni) ve ahırın eşyasıyla (gear) kurulur.
func _ensure_entry(key: String) -> Dictionary:
	var h: Dictionary = horses.get(key, {})
	if h.is_empty():
		return {}
	var ms := stable()
	var fresh := not ms.has(key)
	var profile := player.get_avatar().get_profile() if player.get_avatar() else null
	var e := ms.entry(key, (h["node"] as Rideable).mount_kind(), MountStable.origin_bond(profile.origin_id()) if profile and not player.is_child() else 0.0)
	var row: Dictionary = h["row"]
	if fresh and row.get("gear") is Dictionary:
		ms.set_gear(key, row["gear"])
	return e


func _inv() -> Inventory:
	if inventory_override:
		return inventory_override
	if session and session.inventory:
		return session.inventory
	if is_instance_valid(hud) and hud.bag and hud.bag.inventory:
		return hud.bag.inventory
	return null


func _day() -> int:
	if day_override >= 0:
		return day_override
	return session.clock.day_n if session and session.clock else 0


# --- Odak ---------------------------------------------------------------------------------------------------------------

## Atın ahırda mı (alanın içinde)?
func in_stable(key: String) -> bool:
	var h: Dictionary = horses.get(key, {})
	if h.is_empty() or not is_instance_valid(h["node"]):
		return false
	var node: Rideable = h["node"]
	if not node.visible or node.ridden:
		return false
	for st: Dictionary in stables:
		if str(st["id"]) == str(h["stable"]):
			return Vector2(node.global_position.x, node.global_position.z).distance_to(st["at"]) <= float(st["radius"])
	return false


## Atın başının yeri (x, z): yüzünün önü.
static func head_point(node: Node3D) -> Vector2:
	var yaw := node.global_rotation.y
	return Vector2(node.global_position.x, node.global_position.z) + Vector2(sin(yaw), cos(yaw)) * HEAD_FORWARD


## Oyuncunun başında durduğu ahır atı ("" yok): yerde, yaya.
func horse_at_head() -> String:
	if not is_instance_valid(player) or not player.is_active() or player.get_stance() != PlayerController.Stance.FOOT or player.carried:
		return ""
	var at := Vector2(player.global_position.x, player.global_position.z)
	var best := ""
	var best_d := HEAD_REACH
	for key: String in horses:
		if not in_stable(key):
			continue
		var d := at.distance_to(StableLayer.head_point(horses[key]["node"]))
		if d <= best_d:
			best = key
			best_d = d
	return best


## Atın görünen adı: konan ad, sabit ad (row.name) ya da «Adsız at».
func horse_name(key: String) -> String:
	var n := stable().name_of(key) if is_instance_valid(player) else ""
	if not n.is_empty():
		return n
	var fixed: Variant = (horses.get(key, {}).get("row", {}) as Dictionary).get("name")
	if fixed is Dictionary:
		return str((fixed as Dictionary).get(lang, (fixed as Dictionary).get("tr", "")))
	if fixed is String:
		return str(fixed)
	return "Adsız at" if lang != "en" else "Unnamed horse"


func can_name(key: String) -> bool:
	var row: Dictionary = horses.get(key, {}).get("row", {})
	return row.get("name") == null and stable().name_of(key).is_empty()


func oath_of(key: String) -> String:
	return str((horses.get(key, {}).get("row", {}) as Dictionary).get("oath", ""))


func can_swear(key: String) -> bool:
	var oath := oath_of(key)
	return not oath.is_empty() and not bool(stable().care_of(key, _day()).get("oath", false))


## F'nin işi: ad, ant, yular (sırayla ilk uyan). Döner: {kind, label} ya da boş.
func f_job(key: String) -> Dictionary:
	if key.is_empty():
		return {}
	if can_name(key):
		return {"kind": "name", "label": "Ad Koy" if lang != "en" else "Name"}
	if can_swear(key):
		return {"kind": "oath", "label": "Ant İç" if lang != "en" else "Swear"}
	var bridle := stable().gear_of(key, "bridle")
	if bridle == "halter":
		return {"kind": "halter_off", "label": "Yuları Çıkar" if lang != "en" else "Remove Halter"}
	var inv := _inv()
	if bridle.is_empty() and inv and inv.has("halter", 1):
		return {"kind": "halter_on", "label": "Yular Tak" if lang != "en" else "Put on Halter"}
	return {}


## E'nin dokunuşu: Yem Ver ya da Yem Bağı yap. Döner: {kind, label, ok} ya da boş.
func e_job(key: String) -> Dictionary:
	if key.is_empty():
		return {}
	var inv := _inv()
	var care := stable().care_of(key, _day())
	var full := int(care["fed"]) >= int(care["fed_max"])
	if inv and inv.has("fodder", 1):
		return {"kind": "feed", "label": ("Yem Ver" if lang != "en" else "Feed") + " %d/%d" % [int(care["fed"]), int(care["fed_max"])], "ok": not full}
	if inv and inv.has("tag:forage", 2):
		return {"kind": "craft", "label": "Yem Bağı yap" if lang != "en" else "Make Fodder", "ok": true}
	return {"kind": "feed", "label": "Yem Bağı yok" if lang != "en" else "No fodder", "ok": false}


# --- Kare ---------------------------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if not _attached:
		if _live():
			_attach()
		return
	if not is_instance_valid(player) or not is_instance_valid(hud):
		_detach()
		return
	var host: Variant = main.get("world_host") if is_instance_valid(main) else null
	if host is WorldHost and (host as WorldHost).map_world != world:
		_detach()
		return
	_step_hold(delta)
	_push_prompt()
	if camera and (not horse_at_head().is_empty() or not _work.is_empty() or not _e.is_empty()):
		camera.hold_turn_right = true


func my_pairs() -> Array:
	if not _attached or _dialog_layer != null:
		return []
	if not _work.is_empty():
		return []
	var key := horse_at_head()
	if key.is_empty():
		return []
	var care := stable().care_of(key, _day())
	var info := "%s · Bağ %d" % [horse_name(key), int(round(stable().bond(key)))] if lang != "en" else "%s · Bond %d" % [horse_name(key), int(round(stable().bond(key)))]
	var e := e_job(key)
	var out: Array = [["E", "%s · %s" % [str(e.get("label", "")), info]]]
	out.append(["E basılı", ("Tımar" if lang != "en" else "Groom") + (" ✓" if bool(care["groomed"]) else "")])
	var f := f_job(key)
	if not f.is_empty():
		out.append(["F", str(f["label"])])
	return out


func _on_player_prompt(pairs: Array) -> void:
	if _emitting:
		return
	if _mine_shown and pairs == _sent:
		return
	_base_pairs = pairs.duplicate()
	if _mine_shown:
		_sent = []


func _push_prompt() -> void:
	var mine := my_pairs()
	if mine.is_empty():
		if _mine_shown:
			_mine_shown = false
			_sent = []
			_emit_pairs(_base_pairs)
		return
	var merged: Array = mine.duplicate()
	for p: Array in _base_pairs:
		var dup := false
		for q: Array in mine:
			if str(q[0]).begins_with(str(p[0])) or str(p[0]).begins_with(str(q[0])):
				dup = true
		if not dup:
			merged.append(p)
	if merged == _sent:
		return
	_sent = merged
	_mine_shown = true
	_emit_pairs(merged)


func _emit_pairs(pairs: Array) -> void:
	_emitting = true
	player.prompt_changed.emit(pairs)
	_emitting = false


# --- Girdi --------------------------------------------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not _attached or _dialog_layer != null or not is_instance_valid(player):
		return
	if hud and hud.is_screen_open():
		return
	if event is InputEventKey and (event as InputEventKey).echo:
		return
	if event.is_action_pressed(&"accept"):
		var key := horse_at_head()
		if key.is_empty():
			return
		_e = {"key": key, "t": 0.0}
		get_viewport().set_input_as_handled()
	elif event.is_action_released(&"accept"):
		if not _e.is_empty():
			var key := str(_e["key"])
			var t := float(_e["t"])
			_e = {}
			hud.show_hold("", 0.0)
			if t < E_TAP_S:
				tap(key)
			get_viewport().set_input_as_handled()
		elif str(_work.get("kind", "")) == "craft":
			pass
	elif event.is_action_pressed(&"sling"):
		var key := horse_at_head()
		if key.is_empty():
			return
		press_f(key)
		get_viewport().set_input_as_handled()


func _step_hold(delta: float) -> void:
	var held := InputMap.has_action(&"accept") and Input.is_action_pressed(&"accept")
	if not _e.is_empty():
		if not held:
			var key := str(_e["key"])
			var t := float(_e["t"])
			_e = {}
			hud.show_hold("", 0.0)
			if t < E_TAP_S:
				tap(key)
		else:
			_e["t"] = float(_e["t"]) + delta
			var t := float(_e["t"])
			if t >= E_TAP_S:
				hud.show_hold("Tımar" if lang != "en" else "Groom", (t - E_TAP_S) / GROOM_S)
				if horse_at_head() != str(_e["key"]):
					_e = {}
					hud.show_hold("", 0.0)
				elif t - E_TAP_S >= GROOM_S:
					var key := str(_e["key"])
					_e = {}
					hud.show_hold("", 0.0)
					groom(key)
	if not _work.is_empty():
		_work["t"] = float(_work["t"]) + delta
		hud.show_hold(str(_work["label"]), float(_work["t"]) / float(_work["T"]))
		if player.global_position.distance_to(_work["from"]) > 0.35:
			_work = {}
			hud.show_hold("", 0.0)
		elif float(_work["t"]) >= float(_work["T"]):
			var w := _work
			_work = {}
			hud.show_hold("", 0.0)
			if str(w["kind"]) == "craft":
				craft_fodder()


# --- Bağ'ın işleri --------------------------------------------------------------------------------------------------------

## E dokunuşu: Yem Ver ya da Yem Bağı yap.
func tap(key: String) -> void:
	var job := e_job(key)
	match str(job.get("kind", "")):
		"feed":
			feed(key)
		"craft":
			var recipe := _fodder_recipe()
			_work = {"kind": "craft", "t": 0.0, "T": float(recipe.get("hold", 2.0)), "label": str(job["label"]), "from": player.global_position}


## Yem Ver: heybeden bir Yem Bağı, Bağ +5 (günde en çok 3; sınırdaysa yem gitmez). Döner: add_bond'un sonucu.
func feed(key: String) -> Dictionary:
	var inv := _inv()
	if inv == null or not inv.has("fodder", 1):
		_toast("Heybede Yem Bağı yok." if lang != "en" else "No fodder in the pack.", "warn")
		return {"gained": 0.0, "reason": "no_fodder"}
	_ensure_entry(key)
	var care := stable().care_of(key, _day())
	if int(care["fed"]) >= int(care["fed_max"]):
		_toast(("%s bugün doydu." if lang != "en" else "%s has eaten enough today.") % horse_name(key), "warn")
		return {"gained": 0.0, "reason": "day_cap"}
	inv.remove("fodder", 1)
	var res := stable().add_bond(key, "fodder", _day())
	_toast_gain(key, res)
	_play_horse(key)
	return res


## Tımar: Bağ +2 (günde 1).
func groom(key: String) -> Dictionary:
	_ensure_entry(key)
	var res := stable().add_bond(key, "groom", _day())
	if str(res.get("reason", "")) == "day_cap":
		_toast(("%s bugün tımar edildi." if lang != "en" else "%s was groomed today.") % horse_name(key), "warn")
		return res
	_toast_gain(key, res)
	_play_horse(key)
	return res


## Ad koyar (Bağ +10, bir kez).
func name_horse(key: String, horse_name_text: String) -> Dictionary:
	var n := HorseNamePanel.clean(horse_name_text)
	if n.is_empty() or not can_name(key):
		return {"gained": 0.0, "reason": "once"}
	_ensure_entry(key)
	var res := stable().set_name(key, n)
	_toast_gain(key, res)
	return res


## Ant (Bağ +10, bir kez; act1.md §16 «Antlar»): bayrak yazılır (oath_stallion).
func swear(key: String) -> Dictionary:
	if not can_swear(key):
		return {"gained": 0.0, "reason": "once"}
	_ensure_entry(key)
	var res := stable().add_bond(key, "oath", _day())
	var j: Variant = main.get("journey") if main and is_instance_valid(main) else null
	if j is Journey:
		(j as Journey).set_flag(oath_of(key), true)
	_toast_gain(key, res)
	return res


## Yuları takar ya da çıkarır (bridle yuvası; eski eşya heybeye döner). Döner: yuvadaki yeni eşya.
func toggle_halter(key: String) -> String:
	var inv := _inv()
	var ms := stable()
	_ensure_entry(key)
	if ms.gear_of(key, "bridle") == "halter":
		ms.unequip(key, "bridle")
		if inv:
			inv.receive("halter", 1, "stable")
		_toast("Yular çıkarıldı." if lang != "en" else "Halter removed.")
		return ""
	if inv == null or not inv.has("halter", 1):
		return ms.gear_of(key, "bridle")
	inv.remove("halter", 1)
	var old := ms.equip(key, "bridle", "halter")
	if not old.is_empty() and old != "!" and inv:
		inv.receive(old, 1, "stable")
	_toast(("Yular takıldı: %s" if lang != "en" else "Halter on: %s") % horse_name(key))
	return ms.gear_of(key, "bridle")


## Yem Bağı yapar (ahırın tarifi: 2 ot → 1 Yem Bağı).
func craft_fodder() -> bool:
	var inv := _inv()
	var recipe := _fodder_recipe()
	var need: Dictionary = recipe.get("in", {"tag:forage": 2})
	if inv == null:
		return false
	for ref: String in need:
		if not inv.has(ref, int(need[ref])):
			return false
	for ref: String in need:
		inv.remove(ref, int(need[ref]))
	var out: Dictionary = recipe.get("out", {"fodder": 1})
	for id: String in out:
		inv.receive(id, int(out[id]), "craft")
	_toast(("Yem Bağı yapıldı." if lang != "en" else "Fodder bundle made."))
	return true


func _fodder_recipe() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/economy/recipes.json")) if FileAccess.file_exists("res://data/economy/recipes.json") else null
	var rows: Variant = (parsed as Dictionary).get("recipes", {}) if parsed is Dictionary else {}
	return (rows as Dictionary).get(FODDER_RECIPE, {}) if rows is Dictionary else {}


## F: ad, ant ya da yular.
func press_f(key: String) -> void:
	var job := f_job(key)
	match str(job.get("kind", "")):
		"name":
			_open_name(key)
		"oath":
			_ask_oath(key)
		"halter_on", "halter_off":
			toggle_halter(key)


func _open_name(key: String) -> void:
	_close_dialog()
	_dialog_layer = CanvasLayer.new()
	_dialog_layer.name = "HorseNameLayer"
	_dialog_layer.layer = 45
	add_child(_dialog_layer)
	var panel := HorseNamePanel.new()
	panel.setup(name_suggestions(key), lang, horse_name(key))
	panel.named.connect(func(n: String) -> void:
		_close_dialog()
		name_horse(key, n))
	panel.cancelled.connect(_close_dialog)
	_dialog_layer.add_child(panel)
	player.set_active(false)


## Ad önerileri (arayüzün dilinde): atın satırının «names»i, yoksa katmanınki. Satır [{tr, en}, ...] çift dillidir (veri kuralı:
## satır içi dizge iki dilli); düz dizge de okunur.
func name_suggestions(key: String) -> Array:
	var row: Dictionary = (horses.get(key, {}) as Dictionary).get("row", {})
	var list: Variant = row.get("names", def.get("names", []))
	var out: Array = []
	if list is Array:
		for n: Variant in list:
			if n is Dictionary:
				var text := str((n as Dictionary).get(lang, (n as Dictionary).get("tr", ""))).strip_edges()
				if not text.is_empty():
					out.append(text)
			elif n is String and not (n as String).strip_edges().is_empty():
				out.append((n as String).strip_edges())
	return out


func _ask_oath(key: String) -> void:
	_close_dialog()
	_dialog_layer = CanvasLayer.new()
	_dialog_layer.name = "OathLayer"
	_dialog_layer.layer = 45
	add_child(_dialog_layer)
	player.set_active(false)
	var text: Dictionary = OATH_TEXT.get(oath_of(key), {})
	var yes := await ConfirmDialog.ask(_dialog_layer, ("Ant iç: %s" if lang != "en" else "Swear: %s") % str(text.get(lang, text.get("tr", ""))))
	_close_dialog()
	if yes:
		swear(key)


func _close_dialog() -> void:
	if is_instance_valid(_dialog_layer):
		_dialog_layer.queue_free()
	_dialog_layer = null
	if _attached and is_instance_valid(player) and not player.carried:
		player.set_active(true)


func _toast_gain(key: String, res: Dictionary) -> void:
	var gained := float(res.get("gained", 0.0))
	if gained <= 0.0 and str(res.get("reason", "")) != "full":
		return
	_toast(("%s · Bağ %d (+%d)" if lang != "en" else "%s · Bond %d (+%d)") % [horse_name(key), int(round(float(res.get("bond", 0.0)))), int(round(gained))])


func _toast(text: String, kind := "info") -> void:
	if is_instance_valid(hud) and hud.toast and is_instance_valid(hud.toast):
		hud.toast.show_text(text, kind)


## Atın kısa tepkisi: başını indirip otlar gibi (binilmeyen atın kendi beklemesi; ses varsa horlama).
func _play_horse(key: String) -> void:
	var node: Variant = horses.get(key, {}).get("node")
	if node is RideableHorse and is_instance_valid(node):
		(node as RideableHorse).set(&"_want_graze", true)
