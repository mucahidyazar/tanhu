extends Node
## Geliştirme: Önsöz'ün günlerini tuşsuz oynar (main.gd --state=newgame --stage=prologue --autoplay; pencerede kayıt, kare denetimi, sınama).
## Koşucunun süren adımını (PrologueDays.current_step) sorar ve adımın autoplay(bot, delta)'sını çağırır; adım botun yüzünü kullanır:
##   go_to(p, run)        oyuncuyu p'ye yürütür (girişi kameraya göre yazar: PlayerController.auto_move; takılırsa bir an yana kayar)
##   follow(points, run)  noktaları sırayla izler
##   halt()               durur
##   press_e()            E (PlayerController.interact; 0,35 sn'de bir)
##   hold_e(sn)           E basılı (Input «accept»)
##   nudge()              küçük bir giriş (yatakta uyanışta kalkış)
##   set_speed_limit(v)   en yüksek hız (m/sn; −1 sınırsız): geçitte yavaş basış
##   lean(x)              güreşin eğilişi ([-1, 1]; Ö2'nin adımı lean_value'yu okur)
## Perde geçişinde ve söz sırasında (adım beklerken) bot durur. --autoplay-quit Önsöz bitince oyunu kapatır (süre ölçümü);
## --autoplay-speed=K oyunu K kat hızlı oynatır (Engine.time_scale; başsız sınama koşusu).

const STUCK_SECONDS := 1.4
const STUCK_DISTANCE := 0.3
const SIDESTEP_SECONDS := 0.7
const REACH := 0.6
const PRESS_EVERY := 0.35

var days: PrologueDays
var player: PlayerController
var camera: FollowCamera
var lean_value := 0.0
## Dışarıdan sürüklenme (rüzgâr; adım yazar): bot ona karşı dümen kırar.
var drift := Vector3.ZERO
var steps_seen := PackedStringArray()

var _speed_limit := -1.0
var _press_cool := 0.0
var _hold_left := 0.0
var _nudge_left := 0.0
var _route: Array = []
var _stuck_t := 0.0
var _stuck_from := Vector3.INF
var _side_t := 0.0
var _side_dir := Vector2.ZERO
var _started_ms := 0
var _log_left := 0.0


func setup(p_days: PrologueDays, p_player: PlayerController, p_camera: FollowCamera) -> void:
	days = p_days
	player = p_player
	camera = p_camera
	_started_ms = Time.get_ticks_msec()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--autoplay-speed="):
			var k := arg.substr(17).replace(",", ".")
			if k.is_valid_float():
				Engine.time_scale = clampf(float(k), 0.1, 8.0)
	if is_instance_valid(days):
		days.step_started.connect(func(id: String) -> void:
			steps_seen.append("%s:%s" % [days.scene_id(), id])
			print("[önsöz bot] %.1f sn · %s · %s" % [(Time.get_ticks_msec() - _started_ms) / 1000.0, days.scene_id(), id]))
		days.finished.connect(_on_finished)


func _process(delta: float) -> void:
	if not is_instance_valid(days) or not days.is_running() or not is_instance_valid(player):
		halt()
		return
	_press_cool -= delta
	if _hold_left > 0.0:
		_hold_left -= delta
		if _hold_left <= 0.0:
			Input.action_release(&"accept")
	if _nudge_left > 0.0:
		_nudge_left -= delta
		player.auto_move = Vector2(0.0, 0.3)
		if _nudge_left <= 0.0:
			player.auto_move = Vector2.ZERO
		return
	if days.is_busy():
		halt()
		return
	drift = Vector3.ZERO
	var step := days.current_step()
	if step == null or step.is_done():
		halt()
		return
	step.autoplay(self, delta)
	_log_left -= delta
	if _log_left <= 0.0 and OS.get_cmdline_user_args().has("--autoplay-log"):
		_log_left = 5.0
		var t := step.target(player.global_position)
		print("[önsöz bot] yer %s · hedef %s · hız %.2f · sürüklenme %s" % [str(player.global_position.snapped(Vector3.ONE * 0.1)), str(t.snapped(Vector3.ONE * 0.1)) if t != Vector3.INF else "-", player.get_speed(), str(player.external_drift.snapped(Vector3.ONE * 0.01))])


func go_to(p: Vector3, run: bool = false) -> void:
	if p == Vector3.INF:
		halt()
		return
	var at := player.global_position
	if Vector2(p.x - at.x, p.z - at.z).length() <= REACH:
		halt()
		return
	if _side_t > 0.0:
		_side_t -= get_process_delta_time()
		_steer(_side_dir, run)
		return
	var dir := Vector2(p.x - at.x, p.z - at.z).normalized()
	_steer(dir, run)
	_stuck_t += get_process_delta_time()
	if _stuck_t >= STUCK_SECONDS:
		if _stuck_from != Vector3.INF and Vector2(at.x - _stuck_from.x, at.z - _stuck_from.z).length() < STUCK_DISTANCE:
			_side_dir = Vector2(-dir.y, dir.x) * (1.0 if randf() < 0.5 else -1.0)
			_side_t = SIDESTEP_SECONDS
		_stuck_t = 0.0
		_stuck_from = at


func follow(points: Array, run: bool = false) -> void:
	while _route.size() > 1 and _flat(player.global_position, _route[0]) <= 1.0:
		_route.remove_at(0)
	if points != _route and (_route.is_empty() or points.back() != _route.back()):
		_route = points.duplicate()
	if _route.is_empty():
		halt()
		return
	go_to(_route[0], run)


func halt() -> void:
	if is_instance_valid(player):
		player.auto_move = Vector2.ZERO
		player.auto_sprint = false


func press_e() -> void:
	if _press_cool > 0.0 or not is_instance_valid(player):
		return
	_press_cool = PRESS_EVERY
	player.interact()


func hold_e(seconds: float) -> void:
	if _hold_left > 0.0:
		return
	Input.action_press(&"accept")
	_hold_left = seconds
	player.interact()


func nudge() -> void:
	if _nudge_left <= 0.0:
		_nudge_left = 0.25


func set_speed_limit(v: float) -> void:
	_speed_limit = v


func lean(x: float) -> void:
	lean_value = clampf(x, -1.0, 1.0)


func _steer(dir: Vector2, run: bool) -> void:
	var cy := player.camera_yaw()
	var forward := Vector2(-sin(cy), -cos(cy))
	var right := Vector2(cos(cy), -sin(cy))
	var k := 1.0
	if _speed_limit > 0.0 and player.walk_speed > 0.0:
		k = clampf(_speed_limit / player.walk_speed, 0.1, 1.0)
		run = false
	# Rüzgâra karşı: istenen hızdan sürüklenme çıkarılır (yürüyüşün yönü rüzgâra doğru döner).
	if drift.length_squared() > 0.0001 and player.walk_speed > 0.0:
		var want := dir * player.walk_speed * k - Vector2(drift.x, drift.z)
		dir = want.normalized()
	player.auto_move = (Vector2(dir.dot(right), dir.dot(forward)) * k).limit_length(1.0)
	player.auto_sprint = run


func _on_finished(result: Dictionary) -> void:
	halt()
	print("[önsöz bot] bitti: %s · %.1f sn · adımlar %d" % [str(result.get("ending", "")), (Time.get_ticks_msec() - _started_ms) / 1000.0, steps_seen.size()])
	if OS.get_cmdline_user_args().has("--autoplay-quit"):
		get_tree().quit()


func _exit_tree() -> void:
	halt()
	if _hold_left > 0.0:
		Input.action_release(&"accept")


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
