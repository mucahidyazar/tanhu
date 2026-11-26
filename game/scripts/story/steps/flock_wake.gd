class_name FlockWake
extends FlockStep
## «Çobanlık» 1: uyanış (20 Eylül MÖ 228, 07:20; tür «flock_wake»). Çocuk Lan Hatun'un yurdunda yatağında uyanır (yurt diorama, K98: yukarıdan),
## Lan Hatun kapının iç yanında: «Kalk. Bugün sürüyü Kamışlı Göl'e üçünüz götüreceksiniz. Luhun yolu bilir.» İlk harekette çocuk kalkar
## (Wake_Up_and_Look_Up), yurttan çıkar; kapıda Lan Hatun «Güneş tepeye inmeden dönün.» der; ağılın yanında Yançi yayı sorar («Gölde ördek
## olur.»). Hedef ağılın kapısıdır; varınca biter. Veri: bed, rise_s (kalkışın süresi), target, radius, back_near (Lan Hatun'un ikinci sözü
## kapıdan bu kadar uzakta), bow_near (Yançi'nin sözü ağıla bu kadar yakında).

const WAKE_CLIP := "wake_up_look_up"

var _lying := false
var _rise_left := 0.0
var _back_said := false
var _bow_said := false


func start() -> void:
	phase = "bed"
	var p := player()
	var bed := point(step.get("bed", "lan_bed"))
	if bed != Vector3.INF and bool(step.get("in_bed", true)):
		p.spawn_at(bed, 0.0)
		p.carry(true)
		p.global_position = bed
		p.get_avatar().rotation.y = deg_to_rad(float(step.get("bed_yaw_deg", 0.0)))
		p.get_avatar().play_job("sleep_normally")
		_lying = true
		var w := world()
		if w and w.has_method(&"set_yurt_diorama"):
			w.call(&"set_yurt_diorama", "lan_yurt", true)


func tick(delta: float) -> void:
	var p := player()
	match phase:
		"bed":
			# İlk harekette (ya da E'de) kalkar.
			var moved := InputSetup.move_vector().length_squared() > 0.01 or p.auto_move.length_squared() > 0.01
			if moved and clock > 0.6:
				phase = "rise"
				_rise_left = float(step.get("rise_s", 1.6))
				p.get_avatar().play_job(WAKE_CLIP)
		"rise":
			_rise_left -= delta
			if _rise_left <= 0.0:
				_stand()
		"walk":
			var door := point("lan_door")
			if not _back_said and door != Vector3.INF and near(door, float(step.get("back_near", 2.5))):
				_back_said = true
				say(str(step.get("back_line", "back")))
			var w := world()
			if w and w.has_method(&"set_yurt_diorama") and w.call(&"is_yurt_diorama", "lan_yurt") and flat(p.global_position, Vector3.ZERO) > 3.4:
				w.call(&"set_yurt_diorama", "lan_yurt", false)
			var gate := point(step.get("target", "pen_gate"))
			if not _bow_said and near(gate, float(step.get("bow_near", 14.0))):
				_bow_said = true
				say(str(step.get("bow_line", "bow")))
			if near(gate, float(step.get("radius", 3.2))):
				done()


func _stand() -> void:
	var p := player()
	_lying = false
	p.carry(false)
	p.get_avatar().set_locomotion(0.0)
	p.spawn_at(p.global_position, p.get_avatar().rotation.y)
	p.set_active(true)
	phase = "walk"
	if scene.game_hud and step.has("show_controls"):
		scene.game_hud.show_hints()


func interaction() -> Dictionary:
	if phase == "bed" and clock > 0.6:
		return {"key": "E", "label": "Kalk", "run": func() -> void:
			phase = "rise"
			_rise_left = float(step.get("rise_s", 1.6))
			player().get_avatar().play_job(WAKE_CLIP)}
	return {}


func target(_from: Vector3) -> Vector3:
	return point(step.get("target", "pen_gate")) if phase == "walk" else Vector3.INF


func cleanup() -> void:
	if _lying or phase == "rise":
		_stand()
	var w := world()
	if w and w.has_method(&"set_yurt_diorama"):
		w.call(&"set_yurt_diorama", "lan_yurt", false)


func preset() -> void:
	var gate := point(step.get("target", "pen_gate"))
	if gate != Vector3.INF:
		player().spawn_at(gate + Vector3(-1.5, 0.0, -1.0), PI * 0.5)


func autoplay(bot: Node, _delta: float) -> void:
	match phase:
		"bed":
			bot.call(&"halt")
			if clock > 2.5:
				var d := interaction()
				if not d.is_empty():
					(d["run"] as Callable).call()
		"rise":
			bot.call(&"halt")
		"walk":
			bot.call(&"follow", ["lan_yurt_in", "lan_door", [8.0, 14.0], [23.0, 15.0], step.get("target", "pen_gate")], "wake_walk", true, 0.8)


func line_keys() -> Array:
	return [str(step.get("back_line", "back")), str(step.get("bow_line", "bow"))]
