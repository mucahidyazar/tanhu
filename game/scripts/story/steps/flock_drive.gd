class_name FlockDrive
extends FlockStep
## «Çobanlık» 3: sürüyü göle sürmek (tür «flock_drive»; HerdSim DRIVEN). Koyun sürücüden kaçar ve yolu izleyerek ileri gider, sürünün ortasına
## toplanır, öndekini izler: Luhun önde yürür («Ardımdan gelin»), Yançi sol kanattadır (o da sürücüdür, sol yanı tutar), oyuncu arkadan
## sürer (yaşlı koyunun sırtında da). Yolda olaylar (events, sürünün yoldaki ilerleyişine göre): yürürken konuşma (Sarı Irmak'ın eski
## yatağı), sapma (sağdakiler dağılır: «Sağdakiler dağılıyor!»; biri kaçar: «Biri kaçıyor! Önüne geç!»): oyuncu sapanların önüne geçince
## döner; uzun süre dönmezse Yançi önlerine koşar (ceza yok). Turnalar güneye geçer (kamera bir an göğe bakar, uzak kare), ufukta Dailin'in
## dumanları görünür. Ilgınların ardında göl görününce (lake_view) Yançi «Göl! Kuzular suyun kokusunu aldı.» der, koyunlar suya koşar; adım biter.
## Sürü uzun süre ilerlemezse çocuklar arkadan sürer (oyun takılmaz).
## Veri: path (işaretler), goal_radius, leader, lead_ahead, flank, flank_offset [yan, geri], events [{at, say | stray+count+line | cranes+line+
## then | dailin+line}], lake_line, stray_help_s, stall_s.

var _events_done := {}
var _progress := 0.0
var _best := 0.0
var _stall := 0.0
var _stray_t := -1.0
var _arrived := false
var _path := PackedVector2Array()
var _length := 1.0
var _cum := PackedFloat32Array()
var _helping := false


func start() -> void:
	phase = "drive"
	_path = path2(step.get("path", []))
	_cum = PackedFloat32Array([0.0])
	for i in range(1, _path.size()):
		_cum.append(_cum[i - 1] + _path[i].distance_to(_path[i - 1]))
	_length = maxf(_cum[_cum.size() - 1], 1.0)
	var h := herd()
	if h:
		h.drive_along(_path, float(step.get("goal_radius", 12.0)))
		var lead := actor(str(step.get("leader", "luhun_child")))
		h.set_leader(lead)
		h.arrived.connect(_on_arrived)
	set_drivers([str(step.get("flank", "yanchi_child"))])
	var a := atmos()
	if a:
		a.music_layers({"kopuz": -1.0, "kaval": -9.0}, 3.0)


func tick(delta: float) -> void:
	tick_followers(delta)
	tick_look(delta)
	var h := herd()
	if h == null:
		return
	set_drivers([str(step.get("flank", "yanchi_child"))])
	var c := h.flock_center()
	_progress = progress_of(Vector2(c.x, c.z))
	_move_kids(c)
	# Takılma: sürü ilerlemiyorsa (ve sapan yoksa) çocuklar arkadan sürer.
	if _progress > _best + 0.004:
		_best = _progress
		_stall = 0.0
	else:
		_stall += delta
	_helping = _stall > float(step.get("stall_s", 18.0)) and flat(player().global_position, c) > 22.0
	for e: Variant in step.get("events", []):
		var ev: Dictionary = e
		var key := str(ev.get("at", 0.0))
		if _events_done.has(key) or _progress < float(ev.get("at", 0.0)):
			continue
		_events_done[key] = true
		_fire(ev)
	if h.sim.stray_count() > 0:
		if _stray_t < 0.0:
			_stray_t = 0.0
		_stray_t += delta
	else:
		_stray_t = -1.0
	_update_objective(h)
	if not _arrived and _progress >= 0.985:
		_on_arrived()


## Sürünün yoldaki ilerleyişi (0..1): ortanın yola izdüşümü.
func progress_of(p: Vector2) -> float:
	var best := INF
	var along := 0.0
	for i in _path.size() - 1:
		var a := _path[i]
		var b := _path[i + 1]
		var t := OrdosGround._segment_t(p, a, b)
		var d := p.distance_squared_to(a.lerp(b, t))
		if d < best:
			best = d
			along = _cum[i] + a.distance_to(b) * t
	return clampf(along / _length, 0.0, 1.0)


func _point_at(progress: float) -> Vector3:
	var along := clampf(progress, 0.0, 1.0) * _length
	for i in _path.size() - 1:
		if along <= _cum[i + 1] or i == _path.size() - 2:
			var seg := maxf(_cum[i + 1] - _cum[i], 0.001)
			var q := _path[i].lerp(_path[i + 1], clampf((along - _cum[i]) / seg, 0.0, 1.0))
			return Vector3(q.x, scene._ground_y(q.x, q.y), q.y)
	return Vector3.INF


## Luhun önde (yolda, sürünün lead_ahead önünde; sürü geride kalırsa bekler), Yançi sol kanatta (sapan varsa ve oyuncu yardım etmezse
## sapanın dışına koşar; sürü takıldıysa arkaya geçer).
func _move_kids(c: Vector3) -> void:
	var h := herd()
	var lead_id := str(step.get("leader", "luhun_child"))
	var ahead := float(step.get("lead_ahead", 12.0)) / _length
	var lead_goal := _point_at(minf(_progress + ahead, 1.0))
	var m := mover(lead_id)
	if m and lead_goal != Vector3.INF:
		if flat(m.position(), c) > 26.0 and flat(m.position(), lead_goal) < flat(c, lead_goal):
			m.stop(c)
		else:
			escort(lead_id, lead_goal, 3.1)
	var flank_id := str(step.get("flank", "yanchi_child"))
	var fwd := h.sim.path_tangent(Vector2(c.x, c.z))
	var left := Vector2(fwd.y, -fwd.x)
	var off: Array = step.get("flank_offset", [9.0, 4.0])
	var goal := c + Vector3(left.x, 0.0, left.y) * float(off[0]) - Vector3(fwd.x, 0.0, fwd.y) * float(off[1])
	if _stray_t > float(step.get("stray_help_s", 30.0)):
		var strays := h.stray_positions()
		if not strays.is_empty():
			var s := strays[0]
			var away := Vector3(s.x - c.x, 0.0, s.z - c.z).normalized()
			goal = s + away * 3.0
	elif _helping:
		goal = c - Vector3(fwd.x, 0.0, fwd.y) * (h.sim.flock_spread() + 3.0)
	escort(flank_id, Vector3(goal.x, scene._ground_y(goal.x, goal.z), goal.z), 3.3)


func _fire(ev: Dictionary) -> void:
	if ev.has("say"):
		say(str(ev["say"]))
		# İnceleme karesi (--e21-shots; pencerede): sürü yolda.
		if str(ev["say"]) == "walk_3":
			E21Shots.shot(scene, "flock_path", 1.5)
	if ev.has("stray"):
		var h := herd()
		if h and not h.stray(float(ev["stray"]), int(ev.get("count", 3)), float(ev.get("dist", 26.0))).is_empty():
			say(str(ev.get("line", "")))
			_stray_t = 0.0
	if bool(ev.get("cranes", false)):
		var r := reaches()
		if r:
			r.fly_cranes(float(ev.get("seconds", 46.0)))
		var line_wait := say(str(ev.get("line", "")))
		if ev.has("then"):
			say(str(ev["then"]))
		at(clock + maxf(line_wait - 0.8, 0.6), func() -> void:
			var rr := reaches()
			if rr and rr.cranes_flying():
				look_at_sky(rr.cranes_position(), float(ev.get("look_s", 6.0))))
	if bool(ev.get("dailin", false)):
		say(str(ev.get("line", "")))
		var rr := reaches()
		if rr:
			var smoke := rr.nearest_smoke(player().global_position)
			if smoke != Vector3.INF:
				look_at_sky(smoke, float(ev.get("look_s", 6.0)))


func _on_arrived() -> void:
	if _arrived:
		return
	_arrived = true
	phase = "lake"
	end_look()
	var wait := say(str(step.get("lake_line", "lake")))
	water_the_flock()
	at(clock + maxf(wait, 1.0), done)


func _update_objective(h: HerdField) -> void:
	var strays := h.sim.stray_count()
	if strays > 0:
		set_hint(step.get("stray_hint"))
	else:
		set_hint(step.get("hint"))


func target(from: Vector3) -> Vector3:
	var h := herd()
	if h == null:
		return Vector3.INF
	var strays := h.stray_positions()
	if not strays.is_empty():
		return strays[0]
	var c := h.flock_center()
	if flat(from, c) > 24.0:
		return c
	return point("lake_view")


func cleanup() -> void:
	end_look()
	var h := herd()
	if h and h.arrived.is_connected(_on_arrived):
		h.arrived.disconnect(_on_arrived)


func preset() -> void:
	var h := herd()
	if h == null:
		return
	var at_point := point("lake_drink")
	h.sim.place_on_meadow(Vector2(point("lake_graze").x, point("lake_graze").z), 12.0)
	h.snap()
	player().spawn_at(point("lake_beach") + Vector3(-3.0, 0.0, 2.0), PI * 0.5)
	for id: String in ["luhun_child", "yanchi_child"]:
		var m := mover(id)
		if m:
			m.place(point("lake_beach") + Vector3(-1.5 if id == "luhun_child" else 1.5, 0.0, -2.0), PI * 0.5)
	for id: String in FOLLOW_OFFSETS:
		var s := scene.sheep.get(id) as Rideable
		if s:
			s.place(at_point + Vector3(-6.0, 0.0, 6.0 + (2.0 if id == "old_sheep" else -2.0)), PI * 0.5)


func autoplay(bot: Node, _delta: float) -> void:
	if phase != "drive":
		bot.call(&"halt")
		return
	bot_drive(bot, true)


func line_keys() -> Array:
	var out: Array = [str(step.get("lake_line", "lake"))]
	for e: Variant in step.get("events", []):
		for k in ["say", "line", "then"]:
			if (e as Dictionary).has(k):
				out.append(str(e[k]))
	return out
