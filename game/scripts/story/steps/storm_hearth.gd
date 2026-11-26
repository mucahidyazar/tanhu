extends PrologueStep
## «Tipi»nin kara yurdu (E21, K110; story.md §3): Künay'ın yurdunda ocak tipide sönmüştür (kara yurt). Çocuk közü ocağa koyar (E), tezek ve
## çalı ekler (E, E); ateş tutar, ışık evre evre yurdu doldurur (ocağın ışığı közde 0,25, tezekte 0,7, çalıda 1,6'dan 2,4'e). Yurdun içi
## çatısız diorama, yukarıdan (StagedYurt'un odası; K98). Saruk Künay'ın başında diz çöker, Künay döşekte; ateş tutunca Saruk «Işık döndü…» der.
##   {"kind": "storm_hearth", "yurt": "kunay", "hearth": "kunay_hearth", "lit_line": "act0.storm.lit"}

const PHASES: Array[String] = ["embers", "dung", "brush", "catch"]
const LABELS := {
	"embers": {"tr": "Közü ocağa koy", "en": "Lay the embers in the hearth"},
	"dung": {"tr": "Tezek koy", "en": "Add dung cakes"},
	"brush": {"tr": "Çalı koy", "en": "Add brushwood"},
}
const OBJECTIVES := {
	"embers": {"tr": "Közü ocağa koy", "en": "Put the embers in the hearth"},
	"dung": {"tr": "Ocağa tezek koy", "en": "Feed the hearth dung cakes"},
	"brush": {"tr": "Ocağa çalı koy", "en": "Feed the hearth brushwood"},
}
## Ocağın ışığı evre evre (enerji) ve tutuşmanın süresi (sn).
const LIGHT := {"embers": 0.25, "dung": 0.7, "brush": 1.6, "catch": 2.4}
const CATCH_S := 2.2
const REACH := 1.9
const WORK_CLIP := "crouch_pick_place_f"
const WORK_S := 1.1
## Yurdun içi sayılan yarıçap (m; duvar ≈3,3 m).
const INSIDE_R := 2.9

var _hearth := Vector3.INF
var _i := 0
var _busy := false
var _fuel: Array[Node3D] = []


func start() -> void:
	_hearth = point(step.get("hearth", "kunay_hearth"))
	phase = PHASES[0]
	places().set_yurt_hearth(str(step.get("yurt", "kunay")), false)
	# Yakıt ocağın yanında: tezek sepeti ve çalı demeti.
	for kind in ["dung", "brush"]:
		var f := PrologueProps.fuel(kind)
		var off := Vector3(0.7, 0.0, 0.35) if kind == "dung" else Vector3(-0.65, 0.0, 0.45)
		f.position = _hearth + off
		days.root().add_child(f)
		_fuel.append(f)
	if days.sound:
		days.sound.bed("amb_yurt_storm_inside", true, -3.0, 2.5, point(str(step.get("yurt", "kunay")) + "_yurt"), 9.0)
	_apply_light(0.0)


func interaction() -> Dictionary:
	if _busy or _i >= 3 or not near(_hearth, REACH):
		return {}
	return {"key": "E", "label": text(LABELS[phase]), "run": _do}


func target(_from: Vector3) -> Vector3:
	return _hearth if _i < 3 else Vector3.INF


func tick(_delta: float) -> void:
	pass


func autoplay(bot: Node, _delta: float) -> void:
	if _i >= 3 or _busy:
		bot.call(&"halt")
		return
	if near(_hearth, REACH * 0.7):
		bot.call(&"halt")
		bot.call(&"press_e")
	else:
		bot.call(&"go_to", route_point(player().global_position), false)


## Ocağa giden yolun sıradaki noktası: dışarıdaysa önce kapının önü, sonra kapının içi (duvardan geçilmez), içerideyse ocak.
func route_point(from: Vector3) -> Vector3:
	var y_id := str(step.get("yurt", "kunay"))
	var c := point(y_id + "_yurt")
	var door := point(y_id + "_door")
	var inside := point(y_id + "_in")
	if c == Vector3.INF or door == Vector3.INF or inside == Vector3.INF or flat(from, c) <= INSIDE_R:
		return _hearth
	return door if flat(from, door) > 1.0 and flat(from, inside) > flat(door, inside) else inside


func preset() -> void:
	places().set_yurt_hearth(str(step.get("yurt", "kunay")), true)


func cleanup() -> void:
	days.player_work("")
	walk_mods({"speed_k": 0.95, "can_run": true, "can_jump": false})
	for f in _fuel:
		if is_instance_valid(f):
			f.queue_free()
	_fuel.clear()


func line_keys() -> Array:
	return [step.get("lit_line", "")]


func _do() -> void:
	if _busy:
		return
	_busy = true
	walk_mods(HOLD_MODS)
	days.player_work(WORK_CLIP)
	var which := phase
	at(clock + WORK_S * 0.6, func() -> void: _apply(which))
	at(clock + WORK_S, func() -> void:
		days.player_work("")
		walk_mods({"speed_k": 0.95, "can_run": true, "can_jump": false})
		_busy = false
		_i += 1
		if _i < 3:
			phase = PHASES[_i]
			set_objective(OBJECTIVES[phase])
		else:
			_catch())


func _apply(which: String) -> void:
	match which:
		"embers":
			places().set_yurt_hearth(str(step.get("yurt", "kunay")), true)
			_apply_light(LIGHT["embers"])
			sfx("sfx_fire_rekindle", _hearth + Vector3.UP * 0.3, -14.0, 0.8)
		"dung":
			if _fuel.size() > 0 and is_instance_valid(_fuel[0]):
				_fuel[0].scale = Vector3(1.0, 0.6, 1.0)
			_apply_light(LIGHT["dung"])
		"brush":
			if _fuel.size() > 1 and is_instance_valid(_fuel[1]):
				_fuel[1].visible = false
			_apply_light(LIGHT["brush"])


func _catch() -> void:
	phase = "catch"
	set_objective({"tr": "", "en": ""})
	sfx("sfx_fire_rekindle", _hearth + Vector3.UP * 0.5, -2.0)
	var y := places().yurt(str(step.get("yurt", "kunay")))
	var light := y.light if y else null
	if light:
		var t := days.create_tween()
		t.tween_property(light, "light_energy", LIGHT["catch"], CATCH_S).set_trans(Tween.TRANS_SINE)
		t.parallel().tween_property(light, "omni_range", 4.6, CATCH_S)
	# Açık kapıdan sıcak ışık kara düşer (e21-atmosphere.md «Tipi»).
	var door := point(str(step.get("yurt", "kunay")) + "_door")
	if door != Vector3.INF:
		var spill := OmniLight3D.new()
		spill.name = "DoorSpill"
		spill.light_color = Color(1.0, 0.58, 0.26)
		spill.light_energy = 0.0
		spill.omni_range = 4.2
		spill.shadow_enabled = false
		spill.position = door + Vector3(0.0, 0.9, 0.0)
		days.root().add_child(spill)
		var t3 := days.create_tween()
		t3.tween_property(spill, "light_energy", 0.9, CATCH_S)
	var saruk := person("saruk")
	if saruk:
		saruk.face_point(player().global_position)
	at(clock + CATCH_S * 0.6, func() -> void:
		var t2 := say(str(step.get("lit_line", "")))
		at(clock + maxf(t2, 0.5), done))


func _apply_light(energy: float) -> void:
	var y := places().yurt(str(step.get("yurt", "kunay")))
	if y == null:
		return
	if y.light:
		y.light.light_energy = energy
		y.light.visible = energy > 0.0
	if y.hearth:
		for c in y.hearth.get_children():
			if String(c.name).begins_with("Flame"):
				(c as Node3D).scale = Vector3.ONE * clampf(energy / 1.6, 0.05, 1.0)
				(c as Node3D).visible = energy >= 0.6
