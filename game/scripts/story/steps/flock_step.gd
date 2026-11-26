class_name FlockStep
extends ChildhoodStep
## «Çobanlık»ın adımlarının ortak yüzü (E21, K110; story.md §5 «İki yeni gün»; data/story/childhood_days/day1_flock.json): sürü (HerdField'in
## sürülen evresi), iki binek koyunun sürüyü izlemesi ve yaşlı koyunun çanı, kanattaki ve öndeki çocuklar, kameranın bakışı (turnalar,
## Dailin'in dumanları, bulutlar: uzak kare, K98), görünür akış, sözün sırası. Günün paylaşılan durumu sahnenin meta'sındadır (state()):
## kayıp kuzunun dizini, ak taş, sayılar.

## Binek koyunların sürüdeki yeri (sürünün ortasına göre, m) ve çanın aralığı (sn; yürürken).
const FOLLOW_OFFSETS := {"old_sheep": Vector2(-3.2, 2.4), "fast_sheep": Vector2(2.6, -3.0)}
const BELL_EVERY := Vector2(1.3, 2.2)
## Sürücülerin ürkme yarıçapı (m): yaya çocuk, koyun sırtında, kanattaki çocuk.
const DRIVER_FOOT := 9.0
const DRIVER_RIDING := 8.0
const DRIVER_KID := 5.0
## Kameranın bakışı: eğimin payı (derece; K98'in bandının alt ucu 15°) ve süresi.
const LOOK_BIAS := -20.0

var _bell_left := 0.0
var _look_left := 0.0
var _look_saved_yaw := NAN
var _follow_speed := {}


## Günün paylaşılan durumu (sahnenin meta'sı).
func state() -> Dictionary:
	if scene == null:
		return {}
	if not scene.has_meta(&"flock_state"):
		scene.set_meta(&"flock_state", {"lamb": -1, "stone": false, "carrying": false})
	return scene.get_meta(&"flock_state")


func herd() -> HerdField:
	return site().herd if site() else null


func lake() -> ChildhoodLake:
	return site().lake if site() else null


func reaches() -> ChildhoodReaches:
	return site().reaches if site() else null


## Noktalar dizisi düzlemde (işaret ya da [x, z]).
func path2(list: Variant) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in points(list):
		out.append(Vector2((p as Vector3).x, (p as Vector3).z))
	return out


## Sürücüler: oyuncu (koyun sırtında da), istenirse kanattaki çocuklar.
func set_drivers(kids: Array = []) -> void:
	var h := herd()
	if h == null:
		return
	var nodes: Array[Node3D] = [player()]
	var radii := PackedFloat32Array([DRIVER_RIDING if player().is_riding() else DRIVER_FOOT])
	for id: String in kids:
		var a := actor(id)
		if a:
			nodes.append(a)
			radii.append(DRIVER_KID)
	h.set_drivers(nodes, radii)


func clear_drivers() -> void:
	var h := herd()
	if h:
		h.set_drivers([] as Array[Node3D], PackedFloat32Array())
		h.set_leader(null)


## Binek koyunlar sürüyü izler (binilmeyen; oyuncunun bindiği kendi yürür): sürünün ortasından kendi payına yürür, yaşlı koyun yürürken çanı çalar.
func tick_followers(delta: float) -> void:
	var h := herd()
	if h == null:
		return
	var c := h.flock_center()
	var fwd := h.sim.path_tangent(Vector2(c.x, c.z))
	var side := Vector2(-fwd.y, fwd.x)
	if h.sim.phase == HerdSim.Phase.LEAVING:
		# Sürü ağıldan çıkarken binekler kapıyı tıkamasın: sürünün çoğu çıkınca, toplanma yerine (sürünün sonunda) çıkarlar.
		if h.sim.released_total() < int(h.sim.count * 0.85):
			for id: String in FOLLOW_OFFSETS:
				var still := scene.sheep.get(id) as Rideable
				if still and is_instance_valid(still) and not still.ridden:
					still.drive(0.0, delta)
			return
		var gather := h.sim._active_center
		c = Vector3(gather.x, c.y, gather.y)
		fwd = Vector2.RIGHT
		side = Vector2(0.0, 1.0)
	var homing := h.sim.pen_home
	var penned_all := h.sim.phase == HerdSim.Phase.PEN
	for id: String in FOLLOW_OFFSETS:
		var s := scene.sheep.get(id) as Rideable
		if s == null or not is_instance_valid(s):
			continue
		var moving := false
		if s.ridden:
			moving = player().is_riding() and player().riding_node() == s and player().get_speed() > 0.3
		else:
			var off: Vector2 = FOLLOW_OFFSETS[id]
			var goal := Vector2(c.x, c.z) + fwd * off.y + side * off.x
			var at := Vector2(s.global_position.x, s.global_position.z)
			if homing:
				# Ağıla dönüşte binekler kapının yanında bekler (kapıyı tıkamaz), sürü girince kendi yerine.
				var outer := h.sim.pen_center + h.sim.gate_dir * (h.sim.pen_radius + 3.0)
				var gate_side := Vector2(-h.sim.gate_dir.y, h.sim.gate_dir.x) * (4.5 if id == "old_sheep" else -4.5)
				goal = outer + gate_side
			elif penned_all:
				var home := point(id)
				goal = Vector2(home.x, home.z) if home != Vector3.INF else h.sim.pen_center
			# Ağılın içindeki ya da dışındaki binek kapıdan geçer (çitten geçmez).
			var sim := h.sim
			var inside_now := at.distance_to(sim.pen_center) < sim.pen_radius
			var inside_goal := goal.distance_to(sim.pen_center) < sim.pen_radius
			if inside_now != inside_goal:
				var door_in := sim.pen_center + sim.gate_dir * (sim.pen_radius - 1.6)
				var door_out := sim.pen_center + sim.gate_dir * (sim.pen_radius + 1.6)
				if not sim.gate_open:
					goal = at
				elif inside_now:
					goal = door_out if at.distance_to(door_in) < 1.2 else door_in
				else:
					goal = door_in if at.distance_to(door_out) < 1.2 else door_out
			var to := goal - at
			var d := to.length()
			var want := clampf(d * 0.6, 0.0, 3.0)
			var v := float(_follow_speed.get(id, 0.0))
			v = move_toward(v, want if d > 1.2 else 0.0, 2.5 * delta)
			_follow_speed[id] = v
			if v > 0.05 and d > 0.05:
				var step := to.normalized() * minf(v * delta, d)
				var next := at + step
				s.place(Vector3(next.x, 0.0, next.y) + Vector3.UP * scene._ground_y(next.x, next.y), atan2(to.x, to.y))
				moving = true
			s.drive(v, delta)
		if id == "old_sheep" and moving:
			_bell_left -= delta
			if _bell_left <= 0.0:
				_bell_left = randf_range(BELL_EVERY.x, BELL_EVERY.y)
				sfx("sfx_sheep_bell", s.global_position, -6.0)


## Kişiyi sürünün yanında yürütür (kanat ya da ön): hedefe varmadıysa yürür, sürü uzaksa bekler.
func escort(id: String, goal: Vector3, speed: float) -> void:
	var m := mover(id)
	if m == null or goal == Vector3.INF:
		return
	if flat(m.position(), goal) > 1.5:
		m.go([goal], pace(speed))
	elif not m.is_moving():
		var h := herd()
		if h:
			m.face(h.flock_center())


## Kameranın bakışı (uzak kare): eğim alçalır (ufuk ve gök görünür), yön noktaya döner; seconds sonra geri.
func look_at_sky(target: Vector3, seconds: float) -> void:
	var cam := scene.camera
	if cam == null:
		return
	_look_left = seconds
	_look_saved_yaw = cam.get_yaw()
	var to := target - player().global_position
	if Vector2(to.x, to.z).length() > 1.0:
		cam.set_yaw(atan2(-to.x, -to.z))
	var t := scene.create_tween()
	t.tween_property(cam, ^"pitch_bias", LOOK_BIAS, 1.6).set_trans(Tween.TRANS_SINE)


func tick_look(delta: float) -> void:
	if _look_left <= 0.0:
		return
	_look_left -= delta
	if _look_left <= 0.0:
		end_look()


func end_look() -> void:
	_look_left = 0.0
	var cam := scene.camera if scene else null
	if cam and is_instance_valid(cam):
		var t := scene.create_tween()
		t.tween_property(cam, ^"pitch_bias", 0.0, 1.4).set_trans(Tween.TRANS_SINE)


## Sürü göle varınca: suya koşar, içer, kıyının otlağına yayılır.
func water_the_flock() -> void:
	var h := herd()
	if h == null:
		return
	var line := path2(step.get("water_line", ["lake_drink"]))
	h.water(line, Vector2(point("lake_graze").x, point("lake_graze").z), float(step.get("graze_radius", 13.0)))


## Gölde kişinin yüzme pozu ve suyun üstündeki yüksekliği (Luhun, Yançi): derinse yüzer, değilse yürür.
func tick_swimmer(id: String) -> void:
	var a := actor(id)
	var w := world()
	if a == null or a.avatar == null or w == null or not w.has_method(&"water_at"):
		return
	var at := a.global_position
	var water: Dictionary = w.call(&"water_at", at.x, at.z)
	var depth := float(water.get("depth", 0.0)) if not is_nan(float(water.get("level", NAN))) else 0.0
	var pose := SwimPose.attach(a.avatar)
	var swimming := depth >= ChildSwim.WAIST
	if pose:
		pose.amount = move_toward(pose.amount, 1.0 if swimming else 0.0, 0.05)
		pose.speed = 0.7
		pose.phase_offset = 1.3 if id == "luhun_child" else 2.6
	a.avatar.position.y = maxf(depth - ChildSwim.FLOAT_DEPTH - 0.5 * a.avatar.model_scale, 0.0) if swimming else 0.0
	if depth > 0.05 and randf() < 0.02 and lake():
		lake().ring(Vector3(at.x, float(water["level"]), at.z), 0.9, 0.6)


func clear_swimmer(id: String) -> void:
	var a := actor(id)
	if a and a.avatar:
		a.avatar.position.y = 0.0
		var pose := SwimPose.attach(a.avatar)
		if pose:
			pose.amount = 0.0


## Bot: sürünün arkasına (yolun gerisine) geçer; sapan varsa onun dışına koşar.
func bot_drive(bot: Node, run: bool = true) -> void:
	var h := herd()
	if h == null:
		bot.call(&"halt")
		return
	var strays := h.stray_positions()
	var c := h.flock_center()
	if not strays.is_empty():
		var s := strays[0]
		var away := Vector3(s.x - c.x, 0.0, s.z - c.z).normalized()
		bot.call(&"chase", s + away * 3.5, true, 1.0)
		return
	# Çocuk en gerideki koyunun arkasına koşar (koyun ondan ileri kaçar, sürü bütün olarak yürür).
	var fwd := h.sim.path_tangent(Vector2(c.x, c.z))
	var rear := h.sim.rear_sheep(fwd) - fwd * 2.4
	# Yolun koridoruna yarı yarıya çekilir: yolun kayasız şeridinde kalır, sürünün ardından iter.
	var on_path := h.sim.closest_on_path(rear)
	if on_path.is_finite():
		rear = rear.lerp(on_path, 0.5)
	var behind := Vector3(rear.x, c.y, rear.y)
	bot.call(&"chase", behind, run, 0.6)
