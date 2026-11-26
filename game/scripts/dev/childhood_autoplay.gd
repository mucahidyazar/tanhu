extends Node
## Geliştirme: Çocukluk «Koyun Sırtında»yı tuşsuz baştan sona oynar (main.gd --state=newgame --autoplay; pencerede kayıt, kare denetimi).
## Sahnenin adımını (ChildhoodScene.current_step_id, current_phase) okur ve oyuncunun yapacağını yapar: girişi kameraya göre yazar
## (PlayerController.auto_move, auto_sprint), E'ye basar (interact), nişan alıp bırakır (archer().aim_override, begin_aim, release_aim).
##   wake   yurdun önünden yol boyunca ağılın kapısına yürür (ilk harekette kalkar)
##   ride   ağılda kalan koyunların arkasına yürüyüp onları çıkarır, yaşlı koyuna biner, kapıdan çıkar, yarış yolundan taşa sürer (koyun
##          otlamaya durunca dürter), taşta iner
##   hunt   koyundan iner; yerdeki kuşu alır, yoksa en yakın kuşa 6–9 m'ye yaklaşıp nişan alır ve bırakır (mouse: önce bir fare)
##   count  sayım hattına koşar, söz sırasında durur
## E21 (K110): kayıtlı adım türleri (ChildhoodSteps; «Çobanlık», «Ak Kemik», «Ebenin Çetelesi») kendi autoplay(bot, delta)'larıyla oynar; bot yüzü:
## follow(noktalar, anahtar, koş, erim) -> vardı mı, halt(), hold(açık) (E basılı), interact(). Gün bitince günün süresi yazılır
## («gün day1_flock bitti: N sn»); --autoplay-quit Çocukluk'un sonunda (sıradaki gün yoksa), --autoplay-quit=day ilk günün sonunda kapatır.
## Takılırsa (1,4 sn'de 0,3 m'den az yol) bir an yana kayar.
## Hız ölçüsü (E20; PaceLimit.Probe): sahnenin kişileri (Lan Hatun, Luhun koyunuyla, Yançi, sayıcı, Teoman ve beyler atlarıyla) kare kare
## izlenir, kalabalığın en yüksek hızı kartlardan okunur; bitişte her kişinin en yüksek hızı ve oyuncunun koşusu (sınır) günlüğe yazılır.
## --autoplay-shots=klasör sayımın hız karelerini JPEG yazar (pencerede; SHOTS: çocuklar hatta koşar, kalabalık yürüyerek gelir, atlılar
## tırısla gelir, bakış, atlılar gider).
## --autoplay-quit sahne bitince oyunu kapatır (süre ölçümü). İnsan kipi (--autoplay=human): ilk kez oynayan dikkatli bir oyuncunun hızı (gerçek oyuncu süresinin tahmini; sayılar HUMAN_*): uyanışta
## ipucunu okur, kamerayı bir tur döndürür; yolun ilk yarısını yürür, sonra koşar; koyuna binmeden durur, koyun otlamaya durunca geç
## dürter; avda kuşa koşarak değil yürüyerek yaklaşır, uzaktan (7–10,5 m) uzun gerer ve hedefin çevresine (0,5 m) nişan alır: ıskalar
## gerçek okun dağılımıyla olur; düşeni almadan bir an durur.

## Hedefe varılmış sayılan uzaklık (m), atış uzaklığı aralığı (m) ve germe süresi (sn).
const REACH := 0.6
const SHOOT_RANGE := Vector2(5.8, 8.5)
const DRAW_SECONDS := 0.65
const AFTER_SHOT := 1.1
## İnsan kipinin ölçüleri: uyanışta etrafa bakma (sn) ve kameranın dönüşü (rad/sn), yürüyerek gidilen yol (m), binmeden önce duraklama,
## dürtme aralığı, atış uzaklığı (m), germe (sn), nişan hatası (m), atıştan sonra bekleme ve almadan önce duraklama (sn), koşarak yaklaşılan
## en yakın uzaklık (m).
const HUMAN_LOOK := 7.0
const HUMAN_TURN := 1.1
const HUMAN_WALK_M := 18.0
const HUMAN_MOUNT_PAUSE := 1.6
const HUMAN_PROD_EVERY := 2.2
const HUMAN_SHOOT_RANGE := Vector2(7.0, 10.5)
const HUMAN_DRAW := Vector2(1.0, 1.7)
const HUMAN_AIM_ERROR := 0.5
const HUMAN_AFTER_SHOT := 1.8
const HUMAN_PICK_PAUSE := 0.9
const HUMAN_RUN_UNTIL := 16.0
## Sayımın hız kareleri (--autoplay-shots): [ad, evre, evrenin başından sn]; atlıların gelişi lider Mete'ye 16 m'den yakınken (odak kaymış).
const SHOTS := [
	["hiz_1_cocuklar_hatta_kosar", "arrive", 3.0],
	["hiz_2_kalabalik_yuruyerek_gelir", "wait", 6.0],
	["hiz_3_atlilar_tirisla_gelir", "", 0.0],
	["hiz_4_bakis", "gaze", 2.0],
	["hiz_5_atlilar_gider", "leave", 1.3],
]
## Dürtme aralığı (sn) ve takılma ölçüsü.
const PROD_EVERY := 0.9
const STUCK_SECONDS := 1.4
const STUCK_DISTANCE := 0.3
const SIDESTEP_SECONDS := 0.7

var scene: ChildhoodScene
var player: PlayerController
var camera: FollowCamera
## Önce bir fare de vursun mu («İki kuş, bir fare.» satırı için)?
var shoot_mouse := false

var _route: Array = []
var _route_step := ""
var _prod_t := 0.0
var _shot_state := ""
var _shot_t := 0.0
var _stuck_t := 0.0
var _stuck_from := Vector3.INF
var _side_t := 0.0
var _side_dir := Vector2.ZERO
var _mounting := false
var _last_phase := ""
## İnsan kipi ve onun bekleyişi (sn), uyanışta etrafa bakış yapıldı mı, yürünen yol (m), bu atışın germesi (sn).
var human := false
var _wait_left := 0.0
var _looked := false
var _walked := 0.0
var _draw_s := DRAW_SECONDS
var _last_pos := Vector3.INF
var _rng := RandomNumberGenerator.new()
## Kişilerin hız ölçüsü.
var probe := PaceLimit.Probe.new()
var _shots_dir := ""
var _shot_taken := {}
var _phase_t := 0.0
var _started_ms := 0
var _delta := 0.016
var _flock_t := 0.0


func setup(p_scene: ChildhoodScene, p_player: PlayerController, p_camera: FollowCamera, p_mouse: bool = false) -> void:
	scene = p_scene
	player = p_player
	camera = p_camera
	shoot_mouse = p_mouse
	# Günlük: adımın ve sözün sahne saatindeki anı ve motorun karesi (--write-movie kaydında kare = süre × fps; kare seçmek için).
	scene.step_started.connect(func(id: String) -> void: _log("adım %s" % id))
	scene.said.connect(func(id: String) -> void: _log("söz %s" % id))
	scene.finished.connect(func(result: Dictionary) -> void: _log("bitti %s" % result))
	scene.finished.connect(func(_r: Dictionary) -> void: _log("hız %s" % speed_report()))
	_started_ms = Time.get_ticks_msec()
	scene.finished.connect(func(_r: Dictionary) -> void:
		_log("gün %s bitti: %.1f sn (sahnenin saati %.1f sn)" % [scene.day_id if not scene.day_id.is_empty() else "count", (Time.get_ticks_msec() - _started_ms) / 1000.0, scene.clock]))
	var args := (load("res://scripts/dev/capture.gd") as GDScript).call(&"parse_args", OS.get_cmdline_user_args()) as Dictionary
	human = str(args.get("autoplay", "")) == "human"
	# --autoplay-quit: Çocukluk bitince (sıradaki gün yoksa) oyun kapanır; =day: ilk gün bitince (süre ölçümü).
	if args.has("autoplay-quit"):
		var per_day := str(args["autoplay-quit"]) == "day"
		scene.finished.connect(func(r: Dictionary) -> void:
			if per_day or not r.has("next_day"):
				get_tree().create_timer(0.5).timeout.connect(get_tree().quit))
	if args.has("autoplay-shots") and str(args["autoplay-shots"]) != "true":
		_shots_dir = str(args["autoplay-shots"])
		DirAccess.make_dir_recursive_absolute(_shots_dir)
	_rng.seed = 228
	if human:
		_log("insan kipi")


func _log(text: String) -> void:
	var at := scene.clock_text() if is_instance_valid(scene) else "--:--"
	print("[autoplay] kare %d · sahne %6.1f sn · saat %s · %s" % [Engine.get_process_frames(), scene.clock if is_instance_valid(scene) else -1.0, at, text])


func _process(delta: float) -> void:
	if not is_instance_valid(scene) or not is_instance_valid(player) or not scene.is_running():
		_halt()
		return
	_measure()
	# Günlük: adımın evresi değişince (kare seçmek için: sayımın bakışı, atlıların geçişi).
	var phase := scene.current_phase()
	if phase != _last_phase:
		_last_phase = phase
		_phase_t = 0.0
		_log("evre %s" % phase)
	_phase_t += delta
	_shoot(phase)
	if not player.is_active():
		_halt()
		return
	if _last_pos != Vector3.INF:
		_walked += Vector2(player.global_position.x - _last_pos.x, player.global_position.z - _last_pos.z).length()
	_last_pos = player.global_position
	if _wait_left > 0.0:
		_wait_left -= delta
		_halt()
		return
	_delta = delta
	# E21: kayıtlı tür kendi oynanışını bilir.
	var handler := scene.step_handler()
	if handler:
		handler.autoplay(self, delta)
		_flock_log(delta)
		return
	var step := scene.current_step_id()
	match step:
		"wake":
			if human and not _looked:
				_look_around(delta)
				return
			_follow([[8.0, 14.0], [23.0, 15.0], "pen_gate"], step, delta, not human or _walked >= HUMAN_WALK_M)
		"ride":
			_ride(delta)
		"hunt":
			_hunt(delta)
		"count":
			if _follow(["children_at_line"], step, delta, true):
				_halt()


# --- Adımlar ------------------------------------------------------------------------------------------

## İnsan kipi: uyanışta ipucunu okur, kamerayı bir yana bir öbür yana döndürür (Q/E).
func _look_around(delta: float) -> void:
	_halt()
	_shot_t += delta
	var dir := 1.0 if _shot_t < HUMAN_LOOK * 0.5 else -1.0
	if _shot_t > HUMAN_LOOK * 0.2 and camera:
		camera.add_yaw(dir * HUMAN_TURN * delta)
	if _shot_t >= HUMAN_LOOK:
		_shot_t = 0.0
		_looked = true


func _ride(delta: float) -> void:
	var old := scene.sheep.get("old_sheep") as RideableSheep
	if scene.current_phase() == "dismount":
		# Taşta iner («bin, sür, in»).
		_halt()
		if player.is_riding() and player.get_stance() == PlayerController.Stance.RIDING:
			player.interact()
		return
	if not player.is_riding() and scene.current_phase() == "herd":
		_herd(delta)
		return
	if not player.is_riding():
		if player.get_stance() != PlayerController.Stance.FOOT:
			_halt()
			return
		if old == null:
			return
		if _follow(["pen_gate", "pen_inside", old.global_position], "ride_mount", delta, false, 1.0):
			_halt()
			if human and not _mounting:
				_mounting = true
				_wait_left = HUMAN_MOUNT_PAUSE
				return
			if player.mount_in_reach() == old:
				player.interact()
		return
	var route: Array = ["pen_inside", "pen_gate", "race_start"]
	var layout: Variant = scene.world.get(&"layout")
	if layout is Dictionary:
		for p: Variant in ((((layout as Dictionary).get("childhood", {}) as Dictionary).get("race", {}) as Dictionary).get("path", []) as Array).slice(1):
			route.append(p)
	route.append("race_stone")
	_follow(route, "ride_race", delta, false, 1.4)
	# Dürtme: koşu tuşuna aralıklarla yeniden basılır (otlayan koyun yeni basışla yürür).
	_prod_t += delta
	player.auto_sprint = fmod(_prod_t, HUMAN_PROD_EVERY if human else PROD_EVERY) < 0.12


## Ağılda kalan koyunun arkasına yürür (kapının karşı yanından): koyun kaçar, kapıya gider.
func _herd(delta: float) -> void:
	var site := scene.site
	if site == null or site.herd == null:
		return
	var gate := scene.point("pen_gate")
	var best := Vector3.INF
	for p in site.herd.held_positions():
		if best == Vector3.INF or _flat(p, player.global_position) < _flat(best, player.global_position):
			best = p
	if best == Vector3.INF:
		_halt()
		return
	var away := Vector3(best.x - gate.x, 0.0, best.z - gate.z).normalized()
	_follow(["pen_inside", best + away * 1.6], "herd_%d_%d" % [roundi(best.x * 2.0), roundi(best.z * 2.0)], delta, false, 0.8)


func _hunt(delta: float) -> void:
	if player.is_riding():
		_halt()
		player.interact()
		return
	if player.get_stance() != PlayerController.Stance.FOOT:
		_halt()
		return
	match _shot_state:
		"draw":
			_halt()
			_shot_t += delta
			if _shot_t >= _draw_s:
				player.release_aim()
				_shot_state = "after"
				_shot_t = 0.0
			return
		"after":
			_halt()
			_shot_t += delta
			if _shot_t >= (HUMAN_AFTER_SHOT if human else AFTER_SHOT):
				_shot_state = ""
			return
	var fallen := _fallen_mine()
	if fallen:
		if player.pickup_in_reach():
			_halt()
			if human and _shot_state != "pick":
				_shot_state = "pick"
				_wait_left = HUMAN_PICK_PAUSE
				return
			_shot_state = ""
			player.interact()
			return
		_follow([fallen.global_position], "pick_%d" % fallen.get_instance_id(), delta, false, 0.7)
		return
	# Önce farenin yanından geçer (Luhun'un «Yavrusu var.»ı); fareyi yalnız mouse kipinde vurur.
	if not shoot_mouse and not scene.said_lines.has("luhun_mouse"):
		var mouse := _nearest("gerbil")
		if mouse and _flat(player.global_position, mouse.global_position) > 5.5:
			_follow([mouse.global_position], "mouse_%d" % mouse.get_instance_id(), delta, true, 5.5)
			return
	var kind := "gerbil" if shoot_mouse and int(scene.catch.get("gerbil", 0)) == 0 else "lark"
	var target := _nearest(kind)
	if target == null and kind == "gerbil":
		target = _nearest("lark")
	if target == null:
		_follow(["meadow"], "meadow", delta, false)
		return
	var d := _flat(player.global_position, target.global_position)
	var shoot := HUMAN_SHOOT_RANGE if human else SHOOT_RANGE
	if d > shoot.y:
		_follow([target.global_position], "approach_%d" % target.get_instance_id(), delta, not human or d > HUMAN_RUN_UNTIL, shoot.y - 0.5)
		return
	if d < shoot.x:
		var away := Vector2(player.global_position.x - target.global_position.x, player.global_position.z - target.global_position.z).normalized()
		_steer_dir(away, false)
		return
	_halt()
	if human:
		# Hedefin çevresine nişan (fare imleci kuşun tam üstünde durmaz), daha uzun germe.
		var off := Vector2.from_angle(_rng.randf() * TAU) * _rng.randf() * HUMAN_AIM_ERROR
		player.archer().aim_override = ArrowField.target_center(target) + Vector3(off.x, 0.0, off.y)
		_draw_s = _rng.randf_range(HUMAN_DRAW.x, HUMAN_DRAW.y)
	else:
		player.archer().aim_override = target
		_draw_s = DRAW_SECONDS
	if player.begin_aim():
		_shot_state = "draw"
		_shot_t = 0.0


# --- Yürüyüş -------------------------------------------------------------------------------------------

## Yol noktalarını sırayla izler (işaret kimliği, [x, z] ya da Vector3). key değişince yol baştan kurulur. Varınca true.
func _follow(points: Array, key: String, delta: float, run: bool, reach: float = REACH) -> bool:
	if key != _route_step:
		_route_step = key
		_route = scene.points(points)
		_stuck_t = 0.0
		_stuck_from = player.global_position
	while _route.size() > 1 and _flat(player.global_position, _route[0]) <= maxf(reach, 1.0):
		_route.remove_at(0)
	if _route.is_empty():
		_halt()
		return true
	var to: Vector3 = _route[0]
	if _route.size() == 1 and _flat(player.global_position, to) <= reach:
		_halt()
		return true
	if _side_t > 0.0:
		_side_t -= delta
		_steer_dir(_side_dir, run)
		return false
	var dir := Vector2(to.x - player.global_position.x, to.z - player.global_position.z).normalized()
	_steer_dir(dir, run)
	_stuck_t += delta
	if _stuck_t >= STUCK_SECONDS:
		if _flat(player.global_position, _stuck_from) < STUCK_DISTANCE:
			_side_dir = Vector2(-dir.y, dir.x) * (1.0 if randf() < 0.5 else -1.0)
			_side_t = SIDESTEP_SECONDS
		_stuck_t = 0.0
		_stuck_from = player.global_position
	return false


## Dünya yönünü (x, z) kameraya göre girişe çevirir: W ekranda yukarı (PlayerController.camera_relative_direction'ın tersi).
func _steer_dir(dir: Vector2, run: bool) -> void:
	var cy := player.camera_yaw()
	var forward := Vector2(-sin(cy), -cos(cy))
	var right := Vector2(cos(cy), -sin(cy))
	player.auto_move = Vector2(dir.dot(right), dir.dot(forward)).limit_length(1.0)
	if not player.is_riding():
		player.auto_sprint = run


func _halt() -> void:
	if is_instance_valid(player):
		player.auto_move = Vector2.ZERO
		player.auto_sprint = false


# --- E21: kayıtlı türlerin botu (ChildhoodStep.autoplay) ---------------------------------------------------------

## Yol noktalarını izler (işaret, [x, z] ya da Vector3); varınca true. key değişince yol baştan kurulur.
func follow(points: Array, key: String, run: bool = false, reach: float = REACH) -> bool:
	return _follow(points, key, _delta, run, reach)


func halt() -> void:
	_halt()


## Noktaya doğrudan koşar (yol önbelleği yok: hedef her kare değişir; sürünün arkası gibi). Varınca true.
func chase(point: Vector3, run: bool = true, reach: float = 0.8) -> bool:
	_route_step = ""
	if _flat(player.global_position, point) <= reach:
		_halt()
		return true
	_steer_dir(Vector2(point.x - player.global_position.x, point.z - player.global_position.z).normalized(), run)
	return false


## E'yi basılı tutar ya da bırakır (ChildhoodStep.is_holding).
func hold(on: bool) -> void:
	if is_instance_valid(scene):
		scene.auto_hold = on


func interact() -> bool:
	return player.interact() if is_instance_valid(player) else false


# --- Av ------------------------------------------------------------------------------------------------

## Oyuncunun alabileceği yerdeki av (Yançi'ninki grupta değildir).
func _fallen_mine() -> Node3D:
	var best: Node3D = null
	var best_d := INF
	for node in get_tree().get_nodes_in_group(SmallGame.FALLEN_GROUP):
		if node is SmallGame and (node as SmallGame).is_down():
			var d := _flat(player.global_position, (node as Node3D).global_position)
			if d < best_d:
				best_d = d
				best = node
	return best


func _nearest(kind: String) -> SmallGame:
	if scene.site == null or scene.site.game == null:
		return null
	var best: SmallGame = null
	var best_d := INF
	for a: SmallGame in scene.site.game.of_kind(kind):
		if not a.is_hittable() or a.state > SmallGame.State.WALK or a == scene.get("_yanchi_bird"):
			continue
		var d := _flat(player.global_position, a.global_position)
		if d < best_d:
			best_d = d
			best = a
	return best


# --- Hız ölçüsü ----------------------------------------------------------------------------------------------

## Sahnenin görünen kişileri hız ölçüsüne: yürüyenin yeri, binenin bineğinin yeri (StoryMover.position) ve sahnenin saati.
func _measure() -> void:
	var all := {}
	for id: String in scene.movers:
		all[id] = scene.movers[id]
	for e: Dictionary in scene.escort:
		all[str(e["id"])] = e["mover"]
	for id: String in all:
		var m: StoryMover = all[id]
		var shown := m != null and m.actor != null and m.actor.is_visible_in_tree()
		if shown:
			probe.sample(id, m.position(), scene.clock)
		else:
			probe.forget(id)


## Sayımın hız kareleri: koşulu tutan kare bir kez yazılır.
func _shoot(phase: String) -> void:
	if _shots_dir.is_empty() or scene.current_step_id() != "count":
		return
	for shot: Array in SHOTS:
		var id := str(shot[0])
		if _shot_taken.has(id):
			continue
		var ready := phase == str(shot[1]) and _phase_t >= float(shot[2])
		if str(shot[1]).is_empty():
			var column := scene.column
			ready = column != null and column.running and not column.at_pass() and column.leader() != null \
				and _flat(column.leader().position(), player.global_position) < 16.0
		if not ready:
			continue
		_shot_taken[id] = true
		var path := _shots_dir.path_join(id + ".jpg")
		var err := get_viewport().get_texture().get_image().save_jpg(path, 0.88)
		_log("kare %s (%s)" % [path, error_string(err)])


## Günlük satırı: kişi başına en yüksek hız, kalabalığınki ve sınır (oyuncunun koşusu).
func speed_report() -> String:
	var crowd: CrowdCards = scene.site.crowd if scene.site else null
	if crowd:
		probe.peaks["kalabalik"] = crowd.peak_speed
	return probe.report(PaceLimit.run_cap(player))


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## Sürünün günlüğü (5 sn'de bir; sürülürken): sürünün ortası, dağınıklığı, sürücülerin sayısı, sürünün baskısı, oyuncunun uzaklığı.
func _flock_log(delta: float) -> void:
	_flock_t += delta
	if _flock_t < 5.0:
		return
	_flock_t = 0.0
	var h: HerdField = scene.site.herd if scene.site else null
	if h and h.sim.phase == HerdSim.Phase.LEAVING:
		var inside := 0
		var stuck := []
		for i in h.sim.count:
			if h.sim.pos[i].distance_to(h.sim.pen_center) < h.sim.pen_radius:
				inside += 1
				if stuck.size() < 4:
					stuck.append("%d:(%.1f,%.1f) m%d r%d" % [i, h.sim.pos[i].x, h.sim.pos[i].y, h.sim.mode[i], h.sim.route_i[i]])
		_log("sürü çıkıyor: çıkan %d, içeride %d %s; kapı %s" % [h.sim.released_total(), inside, stuck, h.sim.gate_open])
		return
	if h == null or h.sim.phase != HerdSim.Phase.DRIVEN:
		return
	var c := h.flock_center()
	var tally := ""
	if h.sim.gate_a.is_finite():
		tally = " · kapı %d (%.1f,%.1f)-(%.1f,%.1f)" % [h.sim.gate_tally, h.sim.gate_a.x, h.sim.gate_a.y, h.sim.gate_b.x, h.sim.gate_b.y]
	if h.sim.pen_home:
		tally += " · ağıl %d" % h.sim.pen_tally
	_log("sürü orta (%.0f, %.0f) dağınık %.1f sürücü %d baskı %.2f oyuncu %.1f m%s" % [c.x, c.z, h.sim.flock_spread(), h.sim.drivers.size(),
		h.sim._flock_push, Vector2(player.global_position.x - c.x, player.global_position.z - c.z).length(), tally])
