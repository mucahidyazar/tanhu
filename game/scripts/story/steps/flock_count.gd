class_name FlockCount
extends FlockStep
## «Çobanlık» 7: ikindi sayımı (tür «flock_count»). Yançi «Sayalım. İki taşın arasından geçirin.» der ve taşların yanında durur; oyuncu sürüyü
## otlaktan iki sayım taşının arasından geçirir (HerdSim.count_through; yol kapıdan geçer, koridor daralır: koyunlar tek tek sıraya girer).
## Geçen her koyun sayılır, sayı amaç satırında görünür. 38'de Yançi «Otuz sekiz.», 39'da «Otuz dokuz.» der; biri eksiktir (öğlede sazlığa
## giden kuzu): Luhun «Bir eksik!» Adım biter. Sürü yolun sonuna (count_after) varınca durur, otlar; taşların dışından geçen ya da geride
## kalan birkaç koyunu Yançi orada sayar (tally_grace saniye sonra, tally_every aralıkla: sayım hep biter). Veri: path, gate_a, gate_b,
## slack (taşların iki yanındaki pay, m), corridor, counter (Yançi), counter_at, tally_grace, tally_every, give_up_s, lines {start, 38, 39,
## missing}.

var _said := {}
var _base_corridor := 14.0
var _count := 0
var _ending := false
var _arrived_at := -1.0
var _tally_left := 0.0
var _started := 0.0


func start() -> void:
	phase = "drive"
	var lines: Dictionary = step.get("lines", {})
	say(str(lines.get("start", "count_gate")))
	var h := herd()
	if h:
		var a := point(step.get("gate_a", "count_stone_a"))
		var b := point(step.get("gate_b", "count_stone_b"))
		var dir := Vector2(b.x - a.x, b.z - a.z).normalized()
		var slack := float(step.get("slack", 2.2))
		h.sim.drive_along(path2(step.get("path", [])), 5.0)
		h.count_through(Vector2(a.x, a.z) - dir * slack, Vector2(b.x, b.z) + dir * slack)
		_base_corridor = h.sim.corridor
		h.sim.corridor = float(step.get("corridor", 3.0))
		h.gate_counted.connect(_on_counted)
		h.arrived.connect(_on_arrived)
	_started = clock
	var counter := mover(str(step.get("counter", "yanchi_child")))
	if counter:
		counter.go([point(step.get("counter_at", [318.0, 20.2]))], pace(2.6))
	var luhun := mover("luhun_child")
	if luhun:
		luhun.go([point("lake_graze") + Vector3(8.0, 0.0, 6.0)], pace(2.4))
	set_drivers(["luhun_child"])
	_update_objective()


## Sürü yolun sonunda: sürücüler bırakır, sürü otlar; geride kalanlar biraz sonra sayılır.
func _on_arrived() -> void:
	if _arrived_at < 0.0:
		_arrived_at = clock


func _on_counted(_index: int, tally: int) -> void:
	_count = tally
	_update_objective()
	var counter := mover(str(step.get("counter", "yanchi_child")))
	if counter:
		var h := herd()
		if h:
			counter.face(h.flock_center())
	var lines: Dictionary = step.get("lines", {})
	for n in [38, 39]:
		if tally == n and not _said.has(n):
			_said[n] = true
			say(str(lines.get(str(n), "count_%d" % n)))
	var h2 := herd()
	if h2 and tally >= h2.sim.visible_count() and not _ending:
		_ending = true
		var wait := say(str(lines.get("missing", "missing")))
		at(clock + maxf(wait, 1.0) + 0.3, done)


func _update_objective() -> void:
	if scene and scene.hud:
		scene.hud.set_objective("%s (%d)" % [text(step.get("objective")), _count])


func tick(delta: float) -> void:
	tick_followers(delta)
	var h := herd()
	if h and _arrived_at < 0.0 and clock - _started > float(step.get("give_up_s", 100.0)):
		_arrived_at = clock
	if _arrived_at >= 0.0 and clock - _arrived_at >= float(step.get("tally_grace", 4.0)):
		if phase == "drive":
			phase = "tally"
			clear_drivers()
		_tally_left -= delta
		if _tally_left <= 0.0 and h and not _ending and h.sim.gate_left() > 0:
			_tally_left = float(step.get("tally_every", 0.5))
			h.count_gate_one()
		return
	set_drivers(["luhun_child"])
	var luhun := mover("luhun_child")
	if luhun and h:
		# Luhun sürünün arkasının öbür yanında: kapıya iter.
		var c := h.flock_center()
		var fwd := h.sim.path_tangent(Vector2(c.x, c.z))
		var side := Vector2(fwd.y, -fwd.x)
		var goal := c - Vector3(fwd.x, 0.0, fwd.y) * (h.sim.flock_spread() * 0.6 + 2.0) + Vector3(side.x, 0.0, side.y) * 5.0
		escort("luhun_child", Vector3(goal.x, scene._ground_y(goal.x, goal.z), goal.z), 2.8)


func target(from: Vector3) -> Vector3:
	var h := herd()
	if h == null:
		return Vector3.INF
	var c := h.flock_center()
	return c if flat(from, c) > 18.0 else point(step.get("gate_a", "count_stone_a")).lerp(point(step.get("gate_b", "count_stone_b")), 0.5)


func cleanup() -> void:
	var h := herd()
	if h:
		if h.gate_counted.is_connected(_on_counted):
			h.gate_counted.disconnect(_on_counted)
		if h.arrived.is_connected(_on_arrived):
			h.arrived.disconnect(_on_arrived)
		h.sim.clear_gate()
		h.sim.corridor = _base_corridor


func preset() -> void:
	var h := herd()
	if h:
		h.place_on_meadow(Vector2(point("count_after").x, point("count_after").z), 9.0)
		var lamb := int(state().get("lamb", -1))
		if lamb < 0:
			lamb = h.sim.smallest()
			state()["lamb"] = lamb
		h.take_out(lamb)
	player().spawn_at(point("count_gate") + Vector3(4.0, 0.0, 0.0), -PI * 0.5)


func autoplay(bot: Node, _delta: float) -> void:
	if phase != "drive" or _ending:
		bot.call(&"halt")
		return
	bot_drive(bot, true)


func line_keys() -> Array:
	return (step.get("lines", {}) as Dictionary).values()
