class_name FlockHome
extends FlockStep
## «Çobanlık» 9: eve dönüş (tür «flock_home»). Saat görünür biçimde güneşin batı tepesine değdiği ana akar (ışık altın, gölgeler uzun),
## Yançi «Güneş tepeye değdi, dönelim!» der. Sürü yolu geri ağıla sürülür (koyun ağılın yolunu bilir; Luhun önde, Yançi kanatta); yolun
## ortasında Luhun «Ay doğmadan ağılda olalım. Kurt saatidir.» der, uzakta bir kurt uluyabilir (K3: kurt yalnız sesiyle). Doğuda dolunay
## yükselir. Ağılın kapısında Lan Hatun bekler; koyunlar kapıdan girerken sayılır (amaç satırında sayı); son koyun kapıdan geçince Lan
## Hatun «Kırk çıktı, kırk döndü.» der, hepsi içeri yerleşince kapı kapanır. Ak taş heybedeyse E ile gösterilir: «Ak taş… Sende kalsın. Ak taş yolu bilir.»; taş Mete'de kalır.
## Gün biter (aynı akşam Ak Kemik). Veri: home_at (hh:mm), home_lapse_s, path, lines {call, dusk, count, stone}, dusk_at (yolun oranı),
## mother (lan_hatun), mother_at, item.

var _path := PackedVector2Array()
var _cum := PackedFloat32Array()
var _length := 1.0
var _dusk_said := false
var _all_in := false
var _stone_shown := false
var _ending := false
var _count := 0
var _wolf := false
var _counted := false


func start() -> void:
	phase = "call"
	var lapse_s := float(step.get("home_lapse_s", 5.0))
	clock_to(step.get("home_at", "17:45"), lapse_s)
	at(clock + lapse_s * 0.85, func() -> void:
		var wait := say(str((step.get("lines", {}) as Dictionary).get("call", "home_call")))
		at(clock + maxf(wait * 0.6, 0.5), _begin_drive))
	var mom := mover(str(step.get("mother", "lan_hatun")))
	if mom:
		mom.go([point(step.get("mother_at", [27.6, 22.0]))], pace(1.3))
	var a := atmos()
	if a:
		a.music_layers({"kopuz": -6.0, "kaval": -1.0}, 4.0)


func _begin_drive() -> void:
	phase = "drive"
	_path = path2(step.get("path", []))
	_cum = PackedFloat32Array([0.0])
	for i in range(1, _path.size()):
		_cum.append(_cum[i - 1] + _path[i].distance_to(_path[i - 1]))
	_length = maxf(_cum[_cum.size() - 1], 1.0)
	var h := herd()
	if h:
		var s := site()
		if s:
			s.set_gate_open(true)
		h.drive_along(_path, 6.0)
		h.home_to_pen()
		h.set_leader(actor("luhun_child"))
		h.penned.connect(_on_penned)
		h.all_in.connect(_on_all_in)
	_update_objective()


func _on_penned(_index: int, tally: int) -> void:
	_count = tally
	_update_objective()
	var h := herd()
	if h and tally >= h.sim.visible_count():
		_say_count()


## Son koyun kapıdan geçti: Lan Hatun sayıyı söyler (içeri yerleşmeleri beklenmez).
func _say_count() -> void:
	if _counted:
		return
	_counted = true
	phase = "count"
	var h := herd()
	if h:
		h.set_leader(null)
		clear_drivers()
	var mom := mover(str(step.get("mother", "lan_hatun")))
	if mom:
		mom.face(player().global_position)
	var wait := say(str((step.get("lines", {}) as Dictionary).get("count", "home_count")))
	at(clock + maxf(wait, 1.0) + 0.3, func() -> void:
		phase = "stone"
		if not _has_stone():
			_finish())
	_update_objective()


func _on_all_in(_total: int) -> void:
	if _all_in:
		return
	_all_in = true
	_say_count()
	var h := herd()
	var s := site()
	if h:
		h.settle_in_pen()
	# Kapı binekler de girince kapanır.
	at(clock + 5.5, func() -> void:
		if s:
			s.set_gate_open(false))


func _has_stone() -> bool:
	var item := str(step.get("item", "white_stone"))
	return scene.inventory != null and scene.inventory.has(item) or bool(state().get("stone", false))


func interaction() -> Dictionary:
	if phase != "stone" or _stone_shown:
		return {}
	var mom := mover(str(step.get("mother", "lan_hatun")))
	if mom == null or not near(mom.position(), float(step.get("mother_reach", 2.6))):
		return {}
	return {"key": "E", "label": "Ak taşı göster", "run": _show_stone}


func _show_stone() -> void:
	if _stone_shown:
		return
	_stone_shown = true
	var mom := mover(str(step.get("mother", "lan_hatun")))
	if mom:
		mom.face(player().global_position)
	var wait := say(str((step.get("lines", {}) as Dictionary).get("stone", "lan_stone")))
	at(clock + maxf(wait, 1.0) + 0.6, _finish)


func _finish() -> void:
	if _ending:
		return
	_ending = true
	done()


func tick(delta: float) -> void:
	tick_followers(delta)
	if phase != "drive":
		return
	set_drivers(["yanchi_child"])
	var h := herd()
	if h == null:
		return
	var c := h.flock_center()
	var progress := _progress(Vector2(c.x, c.z))
	# Luhun önde, Yançi sol kanatta (sürünün gerisine yakın).
	var lead := _point_at(minf(progress + 14.0 / _length, 1.0))
	if lead != Vector3.INF:
		escort("luhun_child", lead, 3.2)
	var fwd := h.sim.path_tangent(Vector2(c.x, c.z))
	var left := Vector2(fwd.y, -fwd.x)
	var flank := c + Vector3(left.x, 0.0, left.y) * 8.0 - Vector3(fwd.x, 0.0, fwd.y) * 5.0
	escort("yanchi_child", Vector3(flank.x, scene._ground_y(flank.x, flank.z), flank.z), 3.3)
	if not _dusk_said and progress >= float(step.get("dusk_at", 0.45)):
		_dusk_said = true
		say(str((step.get("lines", {}) as Dictionary).get("dusk", "dusk")))
		E21Shots.shot(scene, "flock_home", 1.0)
	if not _wolf and progress >= float(step.get("dusk_at", 0.45)) + 0.12:
		_wolf = true
		sfx("sfx_wolf_far", player().global_position + Vector3(-120.0, 0.0, -160.0), -10.0)


func _progress(p: Vector2) -> float:
	var best := INF
	var along := 0.0
	for i in _path.size() - 1:
		var t := OrdosGround._segment_t(p, _path[i], _path[i + 1])
		var d := p.distance_squared_to(_path[i].lerp(_path[i + 1], t))
		if d < best:
			best = d
			along = _cum[i] + _path[i].distance_to(_path[i + 1]) * t
	return clampf(along / _length, 0.0, 1.0)


func _point_at(progress: float) -> Vector3:
	var along := clampf(progress, 0.0, 1.0) * _length
	for i in _path.size() - 1:
		if along <= _cum[i + 1] or i == _path.size() - 2:
			var seg := maxf(_cum[i + 1] - _cum[i], 0.001)
			var q := _path[i].lerp(_path[i + 1], clampf((along - _cum[i]) / seg, 0.0, 1.0))
			return Vector3(q.x, scene._ground_y(q.x, q.y), q.y)
	return Vector3.INF


func _update_objective() -> void:
	if scene == null or scene.hud == null:
		return
	if phase in ["drive", "count"]:
		var total := herd().sim.visible_count() if herd() else 40
		scene.hud.set_objective("%s (%d/%d)" % [text(step.get("objective")), _count, total])
	elif phase == "stone":
		set_objective(step.get("stone_objective"))


func target(from: Vector3) -> Vector3:
	match phase:
		"drive":
			var h := herd()
			if h:
				var c := h.flock_center()
				return c if flat(from, c) > 22.0 else point("pen_gate")
		"stone":
			var mom := mover(str(step.get("mother", "lan_hatun")))
			return mom.position() if mom else Vector3.INF
	return Vector3.INF


func cleanup() -> void:
	var h := herd()
	if h:
		if h.penned.is_connected(_on_penned):
			h.penned.disconnect(_on_penned)
		if h.all_in.is_connected(_on_all_in):
			h.all_in.disconnect(_on_all_in)
		if not _all_in and h.phase() == HerdSim.Phase.DRIVEN:
			h.set_leader(null)
	clear_drivers()


func preset() -> void:
	var s := site()
	if s:
		s.reset_herd()
	player().spawn_at(point("pen_gate") + Vector3(3.0, 0.0, 0.0), -PI * 0.5)


func autoplay(bot: Node, _delta: float) -> void:
	match phase:
		"drive":
			bot_drive(bot, true)
		"stone":
			var mom := mover(str(step.get("mother", "lan_hatun")))
			if mom and bool(bot.call(&"follow", [mom.position()], "mom", false, 1.6)):
				var d := interaction()
				if not d.is_empty():
					(d["run"] as Callable).call()
		_:
			bot.call(&"halt")


func line_keys() -> Array:
	return (step.get("lines", {}) as Dictionary).values()
