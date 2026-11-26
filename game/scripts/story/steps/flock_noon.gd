class_name FlockNoon
extends FlockStep
## «Çobanlık» 6: öğle dinlencesi (tür «flock_noon»). Çocuklar sudan çıkar, kıyının otlu yamacında sırtüstü uzanır (Lie_Down_Hands_Spread).
## Oyuncu yanlarına varıp E ile uzanınca (ya da yanlarında bir an durunca oturur) kamera göğe bakar (uzak kare, K98: eğimin alt ucu), müzik
## susar (yalnız sazlık, çekirge ve rüzgâr), bulutlar konuşulur: «Şu bulut at gibi.» «Tanhu'nun atı. Ak.» «Babamın.» «Sayımda görürsün onu.»
## «Sayıcı bizi de sayacak mı?» «Herkesi sayar. Saymazsa yoksun.» Söz sürerken saat görünür biçimde ikindiye akar (güneş batıya döner,
## gölgeler uzar). Bu sırada en küçük kuzu sürüden ayrılıp sazlığa gider (benzetimden çıkar; ikindi sayımında eksik çıkar). Söz bitince
## çocuklar kalkar. Veri: rest (işaret), spots {kişi: [dx, dz]}, lines (sırayla), lapse_to (hh:mm), sit_after (sn), clip.

const LIE_CLIP := "lie_hands_spread"
const SIT_CLIP := "sit"

var _lying := false
var _talk_i := -1
var _talk_left := 0.0
var _still := 0.0
var _rested := false


func start() -> void:
	phase = "go"
	var rest := point(step.get("rest", "noon_rest"))
	for id: String in (step.get("spots", {}) as Dictionary):
		var off: Array = step["spots"][id]
		clear_swimmer(id)
		var m := mover(id)
		if m:
			m.go([rest + Vector3(float(off[0]), 0.0, float(off[1]))], pace(2.0))


func tick(delta: float) -> void:
	tick_followers(delta)
	tick_look(delta)
	var rest := point(step.get("rest", "noon_rest"))
	# Çocuklar varınca uzanır.
	for id: String in (step.get("spots", {}) as Dictionary):
		var m := mover(id)
		if m and m.arrived() and not scene._held.has(id):
			m.face(rest + Vector3(0.0, 0.0, -6.0))
			pose(id, str(step.get("clip", LIE_CLIP)))
	match phase:
		"go":
			if near(rest, float(step.get("radius", 3.6))):
				if player().get_speed() < 0.1:
					_still += delta
				else:
					_still = 0.0
				if _still >= float(step.get("sit_after", 2.0)):
					_lie_down(SIT_CLIP)
		"talk":
			_talk_left -= delta
			if _talk_left <= 0.0:
				_next_line()
		"up":
			pass


func interaction() -> Dictionary:
	if phase != "go" or not near(point(step.get("rest", "noon_rest")), float(step.get("radius", 3.6))):
		return {}
	return {"key": "E", "label": "Uzan", "run": _lie_down.bind(LIE_CLIP)}


func _lie_down(clip: String) -> void:
	if phase != "go":
		return
	phase = "talk"
	var p := player()
	p.set_active(false)
	p.carry(true)
	var rest := point(step.get("rest", "noon_rest"))
	p.global_position = rest + Vector3(0.0, 0.0, 0.6)
	p.get_avatar().rotation.y = PI
	p.get_avatar().play_job(clip)
	_lying = true
	var a := atmos()
	if a:
		a.music_quiet(true, 3.0)
	look_at_sky(rest + Vector3(-40.0, 0.0, -60.0), 999.0)
	var seconds := _talk_seconds()
	clock_to(step.get("lapse_to", "15:40"), seconds)
	# Kuzu bu sırada sazlığa gider (kamera göğe bakarken).
	var h := herd()
	if h and int(state().get("lamb", -1)) < 0:
		var lamb := h.sim.smallest()
		state()["lamb"] = lamb
		h.take_out(lamb)
	_talk_i = -1
	_talk_left = 1.6


func _talk_seconds() -> float:
	var total := 1.6
	for key: Variant in step.get("lines", []):
		total += scene.line_seconds(str(key)) + 0.5
	return total


func _next_line() -> void:
	var lines: Array = step.get("lines", [])
	_talk_i += 1
	if _talk_i >= lines.size():
		_get_up()
		return
	_talk_left = say(str(lines[_talk_i])) + 0.5
	if _talk_i == 2:
		E21Shots.shot(scene, "flock_noon", 0.8)


func _get_up() -> void:
	phase = "up"
	end_look()
	var a := atmos()
	if a:
		a.music_quiet(false, 3.0)
		a.music_layers({"kopuz": -80.0, "kaval": -6.0}, 3.0)
	for id: String in (step.get("spots", {}) as Dictionary):
		unpose(id)
	var p := player()
	if _lying:
		_lying = false
		p.carry(false)
		p.get_avatar().set_locomotion(0.0)
		p.spawn_at(p.global_position, p.get_avatar().rotation.y)
		p.set_active(true)
	at(clock + 1.2, done)


func target(_from: Vector3) -> Vector3:
	return point(step.get("rest", "noon_rest")) if phase == "go" else Vector3.INF


func cleanup() -> void:
	if _lying:
		_get_up()
	end_look()
	for id: String in (step.get("spots", {}) as Dictionary):
		unpose(id)


func preset() -> void:
	var h := herd()
	if h and int(state().get("lamb", -1)) < 0:
		var lamb := h.sim.smallest()
		state()["lamb"] = lamb
		h.take_out(lamb)
	player().spawn_at(point(step.get("rest", "noon_rest")) + Vector3(0.0, 0.0, 1.0), PI)


func autoplay(bot: Node, _delta: float) -> void:
	if phase != "go":
		bot.call(&"halt")
		return
	if bool(bot.call(&"follow", ["stone_shore", "lake_beach", step.get("rest", "noon_rest")], "noon", true, 1.2)):
		var d := interaction()
		if not d.is_empty():
			(d["run"] as Callable).call()


func line_keys() -> Array:
	return step.get("lines", [])
