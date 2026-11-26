class_name FlockLake
extends FlockStep
## «Çobanlık» 4: gölde yüzmek (tür «flock_lake»). Sürü kıyıda içer, sonra otlar; Luhun meydan okur: «Kim yüzer? Son giren kurbağa!», çocuklar
## suya koşar (Luhun yüzer, Yançi belden suda), gülüşürler. Oyuncu sığda yavaş yürür, belden derinde yüzer (ChildSwim); suya ilk girişte
## Yançi «Su buz gibi!», bir süre sonra Luhun «Ayağıma balık değdi!» der. En derin bölgeye girince akıntı geri iter, Yançi seslenir: «Orası
## derin, geri gel!» (bir kez). Oyuncu swim_s saniye yüzünce adım biter (ak taşın meydan okuması). Veri: dare_line, cold_line, fish_line,
## deep_line, kids {kişi: işaret}, swim_s, fish_after.

var _swim_t := 0.0
var _cold_said := false
var _fish_said := false
var _deep_said := false
var _laugh_left := 3.0
var _linked := false


func start() -> void:
	phase = "dare"
	var wait := say(str(step.get("dare_line", "swim_dare")))
	at(clock + maxf(wait * 0.5, 0.5), _kids_in)
	_link()
	var a := atmos()
	if a:
		a.music_layers({"kopuz": -4.0, "kaval": -2.0}, 3.0)


func _kids_in() -> void:
	phase = "swim"
	for id: String in (step.get("kids", {}) as Dictionary):
		var m := mover(id)
		if m:
			m.go([point(step["kids"][id])], pace(2.6))
	sfx("sfx_kids_laugh", point("lake_shallow"), -6.0)


func _link() -> void:
	var sw := player().swim
	if sw and not _linked:
		_linked = true
		sw.pushed_back.connect(_on_pushed)


func _on_pushed() -> void:
	if _deep_said:
		return
	_deep_said = true
	say(str(step.get("deep_line", "swim_deep")))


func tick(delta: float) -> void:
	tick_followers(delta)
	for id: String in (step.get("kids", {}) as Dictionary):
		tick_swimmer(id)
	_link()
	var sw := player().swim
	if sw == null:
		return
	if sw.in_water() and not _cold_said and sw.band >= ChildSwim.Band.WADE:
		_cold_said = true
		say(str(step.get("cold_line", "water_cold")))
	if sw.is_swimming():
		_swim_t += delta
		if not _fish_said and _swim_t >= float(step.get("fish_after", 3.5)):
			_fish_said = true
			say(str(step.get("fish_line", "fish")))
			E21Shots.shot(scene, "flock_lake", 0.6)
	_laugh_left -= delta
	if _laugh_left <= 0.0 and phase == "swim":
		_laugh_left = randf_range(7.0, 13.0)
		var m := mover("luhun_child")
		if m:
			sfx("sfx_kids_laugh", m.position(), -8.0)
	if _swim_t >= float(step.get("swim_s", 7.0)) and _fish_said:
		done()


func target(_from: Vector3) -> Vector3:
	var sw := player().swim
	return Vector3.INF if sw and sw.is_swimming() else point("lake_swim")


func cleanup() -> void:
	var sw := player().swim if is_instance_valid(player()) else null
	if sw and sw.pushed_back.is_connected(_on_pushed):
		sw.pushed_back.disconnect(_on_pushed)


func preset() -> void:
	for id: String in (step.get("kids", {}) as Dictionary):
		var m := mover(id)
		if m:
			m.place(point(step["kids"][id]), PI * 0.5)
	player().spawn_at(point("lake_swim") + Vector3(-1.0, 0.0, 1.5), PI * 0.5)


func autoplay(bot: Node, _delta: float) -> void:
	if phase == "dare":
		bot.call(&"halt")
		return
	var sw := player().swim
	if sw and sw.is_swimming():
		# Biraz yüzer: gölün içinde ileri geri.
		var a := point("lake_swim")
		var b := point("lake_wade")
		var to: Vector3 = a if int(_swim_t / 3.0) % 2 == 0 else b + Vector3(2.0, 0.0, -2.0)
		bot.call(&"follow", [to], "swim_%d" % int(_swim_t / 3.0), false, 0.8)
		return
	# Kıyıya koşar, suda yürür (sığda koşu yoktur).
	bot.call(&"follow", ["lake_beach", "lake_shallow", "lake_swim"], "into_lake", true, 0.8)


func line_keys() -> Array:
	return [str(step.get("dare_line", "swim_dare")), str(step.get("cold_line", "water_cold")), str(step.get("fish_line", "fish")), str(step.get("deep_line", "swim_deep"))]
