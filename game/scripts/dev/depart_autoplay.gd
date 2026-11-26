extends Node
## Geliştirme: Yola Çıkış'ı tuşsuz baştan sona oynar (main.gd --state=newgame --autoplay; pencerede kayıt, kare denetimi). Sahnenin adımını
## (DepartScene.current_step_id, current_phase) okur ve oyuncunun yapacağını yapar: girişi kameraya göre yazar (PlayerController.auto_move),
## E'ye basar (DepartScene.interact, PlayerController.interact).
##   yurt   beşiğin önüne yürür, yayı asar
##   yard   kapının ekseninden çıkar, avludan Eskam'ın yanına yürür; söz ve kapı bakışında durur
##   horse  atın sol yanına yürür, Lan Hatun'un sözü başlayınca bir an bekler, E ile biner; atı batı yolunda tırısla (Shift basılı) kampın son
##          yurtlarını ve çiti geçip eşiğe sürer (E20); eşikte sahne girdiyi alır, kamera arkada kalan kampa döner
## Takılırsa (1,4 sn'de 0,3 m'den az yol) bir an yana kayar.
## Hız ölçüsü (E20; PaceLimit.Probe): sahnenin kişileri kare kare izlenir; bitişte her kişinin en yüksek hızı, oyuncunun koşusu (sınır) ve
## sürüşün süresi ve yolu günlüğe yazılır.
## --autoplay-shots=klasör sürüşün karelerini JPEG yazar (pencerede; SHOTS: yol, kampın dış yurtları, eşik, arkada kalan kamp, kararma);
## --autoplay-quit sahne bitince oyunu kapatır.

## Sürüşün kareleri (--autoplay-shots): [ad, evre, evrenin başından sn, en az sürüş yolu (m)].
const SHOTS := [
	["yola_cikis_surus_1_yol", "ride", 3.0, 0.0],
	["yola_cikis_surus_2_dis_yurtlar", "ride", 0.0, 52.0],
	["yola_cikis_surus_3_esik", "look_back", 0.4, 0.0],
	["yola_cikis_surus_4_arkada_kalan_kamp", "look_back", 4.2, 0.0],
	["yola_cikis_surus_5_kararma", "fade", 1.7, 0.0],
]
## Hedefe varılmış sayılan uzaklık (m) ve binmeden önce Lan Hatun'u dinleme (sn).
const REACH := 0.45
const LISTEN_BEFORE_MOUNT := 1.6
const STUCK_SECONDS := 1.4
const STUCK_DISTANCE := 0.3
const SIDESTEP_SECONDS := 0.6

var scene: DepartScene
var player: PlayerController
var camera: FollowCamera

var _route: Array = []
var _route_key := ""
var _stuck_t := 0.0
var _stuck_from := Vector3.INF
var _side_t := 0.0
var _side_dir := Vector2.ZERO
var _listen := 0.0
var _steering := false
var _shots_dir := ""
var _shot_taken := {}
var _phase_name := ""
var _phase_t := 0.0
## Kişilerin hız ölçüsü.
var probe := PaceLimit.Probe.new()


func setup(p_scene: DepartScene, p_player: PlayerController, p_camera: FollowCamera) -> void:
	scene = p_scene
	player = p_player
	camera = p_camera
	# Günlük: adımın ve sözün sahne saatindeki anı ve motorun karesi (--write-movie kaydında kare = süre × fps).
	scene.step_started.connect(func(id: String) -> void: _log("adım %s" % id))
	scene.said.connect(func(id: String) -> void: _log("söz %s" % id))
	scene.finished.connect(func(result: Dictionary) -> void: _log("bitti %s" % result))
	scene.finished.connect(func(_r: Dictionary) -> void:
		_log("hız %s" % probe.report(PaceLimit.run_cap(player)))
		_log("sürüş %.1f sn · %.1f m (binişten eşiğe)" % [scene.ride_seconds, scene.ride_distance]))
	var args := (load("res://scripts/dev/capture.gd") as GDScript).call(&"parse_args", OS.get_cmdline_user_args()) as Dictionary
	if args.has("autoplay-shots") and str(args["autoplay-shots"]) != "true":
		_shots_dir = str(args["autoplay-shots"])
		DirAccess.make_dir_recursive_absolute(_shots_dir)
	if args.has("autoplay-quit"):
		scene.finished.connect(func(_r: Dictionary) -> void: get_tree().create_timer(0.5).timeout.connect(get_tree().quit))


func _log(text: String) -> void:
	print("[autoplay] kare %d · yola çıkış %6.1f sn · %s" % [Engine.get_process_frames(), scene.clock if is_instance_valid(scene) else -1.0, text])


func _process(delta: float) -> void:
	if not is_instance_valid(scene) or not is_instance_valid(player) or not scene.is_running():
		_halt()
		return
	_measure()
	_shoot(delta)
	if not player.is_active():
		# Girdi sahnenin elinde (asış, söz, kapı bakışı, eşikten sonra): kendi sürüşü bir kez bırakılır; sahnenin auto_move'u ezilmez
		# (eşikte at sahnenin girdisiyle yürür).
		if _steering:
			_halt()
		return
	if player.is_riding():
		# Sürüş: batı yolunda tırısla eşiğe (atın dörtnalı bu sahnede kapalı: Shift tırıstır).
		if scene.current_step_id() == "horse" and scene.current_phase() in ["mounted", "ride"]:
			_follow(["road_gate", "road_end", "road_far"], "ride", delta, 1.2)
			player.auto_sprint = true
		else:
			_halt()
		return
	match scene.current_step_id():
		"yurt":
			if scene.can_hang() and _flat(player.global_position, scene.point("hang_spot")) <= 0.5:
				_halt()
				scene.interact()
			elif _follow(["hang_spot"], "yurt", delta, 0.4):
				_halt()
				scene.interact()
		"yard":
			_follow(["door_in", "door_out", "eskam_talk"], "yard", delta)
		"horse":
			var horse := scene.world.horse
			if horse and player.mount_in_reach() == horse:
				_halt()
				if scene.said_lines.has("lan_days"):
					_listen += delta
					# Dizginin sözleri (E20/7: Lan Hatun, Mete'nin cevabı, Lan Hatun'un son sözü) bitince biner; en az LISTEN_BEFORE_MOUNT.
					if _listen >= LISTEN_BEFORE_MOUNT and (scene.voice == null or scene.voice.is_free()):
						player.interact()
				return
			_follow(["mount_approach"], "horse", delta)


## Yol noktalarını sırayla izler (işaret kimliği, [x, z] ya da Vector3). key değişince yol baştan kurulur. Varınca true.
func _follow(points: Array, key: String, delta: float, reach: float = REACH) -> bool:
	if key != _route_key:
		_route_key = key
		_route = []
		for p: Variant in points:
			var at: Vector3 = p if p is Vector3 else scene.point(p)
			if at != Vector3.INF:
				_route.append(at)
		_stuck_t = 0.0
		_stuck_from = player.global_position
	while _route.size() > 1 and _flat(player.global_position, _route[0]) <= maxf(reach, 0.6):
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
		_steer(_side_dir)
		return false
	var dir := Vector2(to.x - player.global_position.x, to.z - player.global_position.z).normalized()
	_steer(dir)
	_stuck_t += delta
	if _stuck_t >= STUCK_SECONDS:
		if _flat(player.global_position, _stuck_from) < STUCK_DISTANCE:
			_side_dir = Vector2(-dir.y, dir.x) * (1.0 if randf() < 0.5 else -1.0)
			_side_t = SIDESTEP_SECONDS
		_stuck_t = 0.0
		_stuck_from = player.global_position
	return false


## Dünya yönünü (x, z) kameraya göre girişe çevirir: W ekranda yukarı.
func _steer(dir: Vector2) -> void:
	var cy := player.camera_yaw()
	var forward := Vector2(-sin(cy), -cos(cy))
	var right := Vector2(cos(cy), -sin(cy))
	player.auto_move = Vector2(dir.dot(right), dir.dot(forward)).limit_length(1.0)
	player.auto_sprint = false
	_steering = true


func _halt() -> void:
	_steering = false
	if is_instance_valid(player):
		player.auto_move = Vector2.ZERO
		player.auto_sprint = false


## Sürüşün kareleri: evre değişince saat sıfırlanır, koşulu tutan kare bir kez yazılır.
func _shoot(delta: float) -> void:
	var phase := scene.current_phase()
	if phase != _phase_name:
		_phase_name = phase
		_phase_t = 0.0
		_log("evre %s" % phase)
	_phase_t += delta
	if _shots_dir.is_empty():
		return
	for shot: Array in SHOTS:
		var id := str(shot[0])
		if _shot_taken.has(id) or phase != str(shot[1]) or _phase_t < float(shot[2]) or scene.ride_distance < float(shot[3]):
			continue
		_shot_taken[id] = true
		var path := _shots_dir.path_join(id + ".jpg")
		var err := get_viewport().get_texture().get_image().save_jpg(path, 0.88)
		_log("kare %s (%s)" % [path, error_string(err)])


## Sahnenin kişileri (görünenler) hız ölçüsüne: yer ve sahnenin saati.
func _measure() -> void:
	for id: String in scene.actors:
		var a: CineActor = scene.actors[id]
		if is_instance_valid(a) and a.is_visible_in_tree():
			probe.sample(id, a.global_position, scene.clock)
		else:
			probe.forget(id)


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
