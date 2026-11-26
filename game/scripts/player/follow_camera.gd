class_name FollowCamera
extends Node3D
## Uzak ve yüksek açılı takip kamerası (K98): oyun içi her çekim Diablo gibi tepeden bakar, yakın plan yoktur.
##
## - Karakteri 38° aşağıdan, 36° dikey görüşle izler: ufuk görünmez, kişi kare yüksekliğinin ≈%8–12'sidir. Varsayılan uzaklık 28 m,
##   çocukta 22 m (CHILD_DISTANCE; çocuk ≈60–80 piksel). Fare tekerleği, iz dörtgeni ya da - / = ile 14–40 m arasında yakınlaşır/uzaklaşır:
##   uzaklaştıkça açı biraz dikleşir, yakınlaşınca asla yatıklaşmaz (omuz üstü kadraj yok). Nişan almak da kamerayı yaklaştırmaz.
##   Menü kamerasıyla aynı kadrajda olmak zorunda değildir: set_active geçişi ikisinin arasında kayar.
## - Eğim bandı (K39, godot.md §5.1): eğim = uzaklığın eğimi + ayarın eğim payı (pitch_bias; GameSettings.camera_pitch_bias) + oturum payı,
##   PITCH_MIN–PITCH_MAX (15–60°) arasında; sınırın son 4°'sinde eğim hızı ×0,3'e düşer. Oturum payını orta tuşla dikey sürükleme
##   (0,15°/px), Alt + tekerlek (2°/çentik), iz dörtgeninde Alt ile kaydırma ve ; / ' (40°/sn) değiştirir; «Oyunda eğim» kapalıysa
##   (tilt_enabled) bu girdiler yok sayılır, ayarın payı kalır. Bant oyuncunun elidir: oyunun kurduğu her kare (varsayılan, ön ayar,
##   ayarın payı −3..+12°) K98'in 35–50° ailesindedir (k98-recalc).
## - Dönüş: Q / E ve , / . basılıyken, sağ tıkla ve orta tuşla yatay sürükleme, Shift + tekerlek, yatay kaydırma kamerayı karakterin
##   çevresinde yumuşakça döndürür. Orta tuşla sürükleme 12 pikselde baskın eksene kilitlenir (yatay döndürür, dikey eğer); sürüklemesiz
##   orta tık kuzeye hizalar. Oyuncu E'yi başka işe kullanıyorsa (hold_turn_right) ya da sağ tuş nişansa (right_drag kapalı, çocuk
##   denetleyicisi; godot.md §5.3) o giriş kamerayı döndürmez; çocukta da orta tuş döndürür ve eğer, sağ tuş eğime dokunmaz.
## - `/` (camera_reset) kısa basışta açıyı kuzeye, oturum eğimini 0'a, uzaklığı başlangıç uzaklığına (28 m, çocukta 22 m) 0,5 sn'de
##   döndürür (godot.md §5.2); ayarın eğim payı kalır. Açı, oturum eğimi ve tekerlek payı oturumluktur: kamera kapanınca (menüye dönüş)
##   sıfırlanır, Serbest Gez her oturumda kuzeye bakarak açılır (K27).
## - Ön ayarlar (CameraPreset; godot.md §5.7, K98 kadrajıyla act1.md §4): yürüyüş varsayılandır; atta Sürüş kendiliğinden devreye girer
##   (auto_presets); Çömelme, Oda, Bakış ve Tengri apply_preset() ile gelir. Geçiş 1,1 sn'de karışır.
## - Ses dinleyicisi (K39, godot.md §5.5, audio.md §1): takip kamerası ekrandayken AudioListener3D oyuncunun 1,5 m üstündedir, yönü
##   kameranın yatay açısıdır; yakınlaştırma oyuncunun yanındaki sesi değiştirmez. Menü, sinema ve oluşturucuda (takip kapalı ya da başka
##   kamera ekranda) dinleyici kameradır; geçişte dinleyici de kameranın geçişiyle birlikte kayar.
## - Takip hafif gecikmelidir; bakılan nokta ayakların biraz üstündedir; kamera araziye gömülmez.
## - set_active(true) çağrılınca o anki kameradan (ör. menü kamerası) yumuşak bir geçişle yerine oturur.
## - Hızla çok hafif genişler: hedefin hızı (get_speed(); at dörtnalı) SPEED_WIDEN_FROM'u aşınca görüş açısı SPEED_WIDEN_FULL'a dek en çok
##   SPEED_WIDEN_DEG açılır, yumuşakça (K98: eğim değişmez, kadraj uzak ve yüksek kalır; yürüyüş ve koşuda hiç değişmez).
## - Sürüşte açı izlemesi (2026-11-08, Yol Haritası riding; godot.md §5.7, act1.md §4 ve §10, K39): «Kamera takibi» açıksa (ride_follow; ayar
##   «Kapalı» değil) atta kamera atın arkasına RIDE_FOLLOW_LAG (1,1) sn'lik gecikmeyle döner: oyuncunun seçtiği açının en çok ±75°'si
##   (RIDE_FOLLOW_DEG); at kameraya 135°'den çok dönükse izlemez (at kameraya gelir). Elle döndürünce o an görünen açı oyuncunun açısı olur, izleme
##   RIDE_FOLLOW_WAIT (2) sn bekler; inince ya da izleme kapanınca görünen açı kalır (K27). Pay seçilen açının üstüne eklenir (get_yaw görünen açıdır).
## Konum hesabı saf fonksiyonlardır (compute_transform, pitch_for_distance, compose_pitch, lift_above_ground, ground_reach)
## ve tests/unit/test_follow_camera.gd ile sınanır.
##
## Açı kuralı: yaw = 0 iken kamera hedefin +Z tarafında durur ve -Z yönüne (kuzeye) bakar (menü kamerası gibi).
##
## Örtme: OCCLUDER_GROUP grubundaki düğümlere her kare set_camera_occlusion(kamera, hedef) çağrılır;
## uzun nesneler (kaya kümeleri, ağaçlar) bu görüş hattında noktalı saydamlaşarak karakteri gizlemez.

## Kamera ile karakter arasında kalınca saydamlaşabilen nesnelerin grubu.
const OCCLUDER_GROUP := &"camera_occluders"
## Varsayılan kadraj (K98; docs/media/review/kadraj_referans.webp): aşağı bakış açısı ve dikey görüş açısı (derece), uzaklık (metre).
const DEFAULT_PITCH_DEG := 38.0
const DEFAULT_FOV := 36.0
const DEFAULT_DISTANCE := 28.0
## Çocukluk'un başlangıç uzaklığı (küçük Mete, Serbest Gez'in Çocuğu): çocuk ≈60–80 piksel görünür (1080p).
const CHILD_DISTANCE := 22.0
## Hızla genişleme: bu hızdan (m/sn) başlar, bu hızda tamdır, en çok bu kadar derece; yumuşaklığı.
const SPEED_WIDEN_FROM := 5.0
const SPEED_WIDEN_FULL := 10.5
const SPEED_WIDEN_DEG := 2.5
const SPEED_WIDEN_SHARPNESS := 1.8
## Eğim bandı (K39; derece): bileşik eğim bu iki değer arasında kalır. Ufku isteyen sahne çekimi (Bakış 15°, Tengri 13°) kendi eğimindedir.
const PITCH_MIN := 15.0
const PITCH_MAX := 60.0
## Sınırın son PITCH_SOFT_ZONE derecesinde eğim hızı PITCH_SOFT_RATE katına düşer: kamera sınıra çarpmaz, yavaşlar.
const PITCH_SOFT_ZONE := 4.0
const PITCH_SOFT_RATE := 0.3
## Eğim girdileri: orta tuşla dikey sürükleme (derece/piksel), Alt + tekerlek (derece/çentik), ; ve ' basılıyken (derece/sn).
const PITCH_DRAG_DEG := 0.15
const PITCH_WHEEL_DEG := 2.0
const PITCH_KEY_SPEED := 40.0
## Orta tuşla sürükleme bu kadar pikselde baskın eksene kilitlenir; daha azında bırakılırsa tıktır (kuzeye hizalar).
const DRAG_LOCK_PX := 12.0
## Shift + tekerlek ve yatay kaydırma: çentik başına dönüş (derece).
const YAW_WHEEL_DEG := 8.0
## - ve = basılıyken uzaklığın değişim hızı (m/sn).
const KEY_ZOOM_SPEED := 12.0
## `/`: açı, oturum eğimi ve uzaklık bu sürede (saniye) varsayılana döner.
const RESET_SECONDS := 0.5
## Sürüşte açı izlemesi: seçilen açıdan en çok bu kadar (derece), bu gecikmeyle (sn; üstel), at kameraya bundan çok dönükse izlemez (derece),
## elle döndürmeden sonra bu kadar bekler (sn).
const RIDE_FOLLOW_DEG := 75.0
const RIDE_FOLLOW_LAG := 1.1
const RIDE_FOLLOW_CUTOFF_DEG := 135.0
const RIDE_FOLLOW_WAIT := 2.0
## Ses dinleyicisi oyuncunun ayağının bu kadar üstündedir (metre).
const LISTENER_HEIGHT := 1.5

## İzlenecek düğüm (genellikle PlayerController).
@export var target: Node3D
## Sürülecek kamera. Boşsa ilk Camera3D çocuğu kullanılır; o da yoksa yenisi oluşturulur.
@export var camera: Camera3D
@export_group("Kadraj")
## Varsayılan uzaklıktaki aşağı bakış açısı (derece).
@export_range(10.0, 85.0) var pitch_deg := DEFAULT_PITCH_DEG
## Başlangıç uzaklığı (metre; açı burada pitch_deg'dir) ve yakınlaştırma sınırları.
@export var distance := DEFAULT_DISTANCE
@export var min_distance := 14.0
@export var max_distance := 40.0
## En uzakta açı bu kadar dikleşir (derece). Yakınlaşınca açı düşmez: kamera omuz üstüne inmez.
@export var zoom_tilt_deg := 6.0
## Dikey görüş açısı (derece).
@export_range(10.0, 90.0) var fov := DEFAULT_FOV
## Bakılan noktanın ayakların ne kadar üstünde olduğu (metre).
@export var look_height := 0.7
## Kameranın zeminden en az yüksekliği (metre).
@export var ground_clearance := 1.2
## Başlangıç yatay açısı (derece; 0 = -Z yönüne bakar).
@export var start_yaw_deg := 0.0
@export_group("Hareket")
## Takip keskinliği: büyüdükçe kamera karakteri daha az gecikmeyle izler.
@export var follow_sharpness := 5.5
## Q / E ile dönüş hızı (derece/saniye) ve dönüşün yumuşaklığı.
@export var rotate_speed_deg := 110.0
@export var rotate_sharpness := 9.0
## Sağ ya da orta tuşla sürüklerken piksel başına dönüş (derece).
@export var mouse_sensitivity := 0.3
## Tekerleğin her tıkında uzaklık değişimi (metre) ve yakınlaşmanın yumuşaklığı.
@export var zoom_step := 1.8
@export var zoom_sharpness := 8.0
## Oturum eğiminin yumuşaklığı.
@export var pitch_sharpness := 12.0
## İz dörtgeninde (trackpad) iki parmak kaydırmanın yakınlaştırma çarpanı ve yatay kaydırmanın dönüşü, Alt ile eğimi (derece/birim).
@export var pan_zoom_scale := 0.6
## Dokunmatik yüzey jestinin ikinci kopyası (Godot 4.7.2 jesti iki kez verir; GestureDedupe).
var _gestures := GestureDedupe.new()
@export var pan_yaw_deg := 2.0
@export var pan_pitch_deg := 1.0
## set_active(true) ile önceki kameradan geçiş süresi (saniye; 0 = anında).
@export var activation_blend := 1.6
## Açılışta etkin mi? Etkinse kamera hemen karakterin arkasına oturur.
@export var start_active := true
## Kapalıysa kamera izlemeyi sürdürür ama Q/E, fare, tekerlek ve tuş girişlerini yok sayar.
@export var input_enabled := true

## Zemin yüksekliği kaynağı: height_at(x, z) taşıyan nesne (kameranın araziye gömülmemesi için; TerrainShape, OrdosGround; testlerde atanabilir).
var terrain_shape: RefCounted
## E tuşunun o an başka bir işi var: kamera camera_right ile dönmez (oyuncu her kare yazar).
var hold_turn_right := false
## Sağ tuşla sürükleme kamerayı döndürsün mü (çocuk denetleyicisinde sağ tuş nişandır)?
var right_drag := true
## Takip dönüşümünün son süzgeci: (dönüşüm, odak) → dönüşüm (iç harita kameranın sınırı; OrdosWorld.clamp_camera_transform). Boşsa yok.
var transform_filter: Callable
## Ayarın eğim payı (derece; GameSettings.camera_pitch_bias, −3..+12): oyuncunun seçtiği varsayılan kare, `/` onu silmez.
var pitch_bias := 0.0
## Oyunda eğim (GameSettings.camera_tilt): kapalıysa eğim girdileri yok sayılır.
var tilt_enabled := true
## Ters yatay ve ters dikey (GameSettings.camera_invert_x / _y): fareyle sürüklemenin yönü.
var invert_x := false
var invert_y := false
## Ön ayar binişe göre kendiliğinden seçilsin mi (atta Sürüş)?
var auto_presets := true
## Sürüşte açı izlemesi (GameSettings.camera_follow «Kapalı» değilse açık).
var ride_follow := true

var _active := false
var _yaw := 0.0
var _target_yaw := 0.0
## Sürüşte açı izlemesinin payı (radyan; seçilen açının üstüne) ve elle döndürmeden sonra kalan bekleme (sn).
var _follow_yaw := 0.0
var _follow_wait := 0.0
var _distance := DEFAULT_DISTANCE
var _target_distance := DEFAULT_DISTANCE
var _session_pitch := 0.0
var _target_session_pitch := 0.0
var _focus := Vector3.ZERO
## Sürüklemeler: sağ tuş (yalnız dönüş) ve orta tuş (eksen kilitli dönüş ya da eğim; _middle_axis 0 kilitsiz, 1 yatay, 2 dikey).
var _right_dragging := false
var _middle_dragging := false
var _middle_sum := Vector2.ZERO
var _middle_axis := 0
## Etkinleşme geçişi: 0 → 1 (1 = geçiş yok).
var _blend := 1.0
var _blend_from := Transform3D.IDENTITY
var _blend_from_fov := DEFAULT_FOV
## Hızla genişlemenin şimdiki payı (derece).
var _widen := 0.0
## Varsayılana dönüş (`/`): 0 → 1 (1 = dönüş yok) ve başladığı değerler.
var _reset_t := 1.0
var _reset_from := Vector3.ZERO
## Ön ayar: etkin olan (null = yürüyüş), elle mi verildi, geçişin payı (0 → 1), geçişin süresi ve başladığı değerler.
var _preset: CameraPreset
var _preset_manual := false
var _pw := 1.0
var _preset_seconds := 1.1
var _preset_from := {}
## Ön ayarın uzaklık kiplerinin hatırladıkları: "at_least" öncesi ve koyduğu uzaklık, "fixed" öncesi uzaklık.
var _restore_distance := -1.0
var _at_least_set := -1.0
var _held_distance := -1.0
## Payı bekleten ön ayardan önceki açı (çıkınca geri gelir).
var _held_yaw := 0.0
## Ses dinleyicisi; bırakılırken (takip kapanınca) kameraya kayışın payı ve başladığı yer.
var _listener: AudioListener3D
var _listener_release := 1.0
var _listener_from := Transform3D.IDENTITY


func _ready() -> void:
	InputSetup.ensure_actions()
	# Oyuncu hareketi işlendikten sonra güncellensin (kamera aynı karede geride kalmasın).
	process_priority = 10
	_ensure_camera()
	_yaw = wrapf(deg_to_rad(start_yaw_deg), -PI, PI)
	_target_yaw = _yaw
	_distance = clampf(distance, min_distance, max_distance)
	_target_distance = _distance
	if terrain_shape == null:
		var world := PlayerController.find_world(self)
		terrain_shape = world.get_terrain_shape() if world else null
	if start_active:
		set_active(true)
		snap_to_target()


func _process(delta: float) -> void:
	if not _active or not is_instance_valid(target) or camera == null:
		_update_listener(delta)
		return
	if input_enabled:
		var turn := _strength(&"camera_left") - (0.0 if hold_turn_right else _strength(&"camera_right"))
		if turn != 0.0:
			add_yaw(deg_to_rad(rotate_speed_deg) * turn * delta)
		if tilt_enabled:
			var tilt := _strength(&"camera_pitch_up") - _strength(&"camera_pitch_down")
			if tilt != 0.0:
				add_pitch(PITCH_KEY_SPEED * tilt * delta)
		var zoom := _strength(&"camera_zoom_out") - _strength(&"camera_zoom_in")
		if zoom != 0.0:
			zoom_by(KEY_ZOOM_SPEED * zoom * delta)
	update_camera(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not _active or not input_enabled:
		return
	if InputMap.has_action(&"camera_reset") and event.is_action_pressed(&"camera_reset", false, true):
		reset_view()
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		var amount := mb.factor if mb.factor > 0.0 else 1.0
		match mb.button_index:
			MOUSE_BUTTON_RIGHT:
				_right_dragging = mb.pressed and right_drag
			MOUSE_BUTTON_MIDDLE:
				if mb.pressed:
					_middle_dragging = true
					_middle_sum = Vector2.ZERO
					_middle_axis = 0
				else:
					# Sürüklemesiz orta tık kuzeye hizalar (K27).
					if _middle_dragging and _middle_axis == 0 and _middle_sum.length() < DRAG_LOCK_PX:
						align_north()
					_middle_dragging = false
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
				if mb.pressed:
					var dir := -1.0 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0
					if mb.alt_pressed:
						# Alt + tekerlek: yukarı kamerayı ufka doğru alçaltır, aşağı yükseltir.
						if tilt_enabled:
							add_pitch(PITCH_WHEEL_DEG * dir * amount)
					elif mb.shift_pressed:
						add_yaw(deg_to_rad(YAW_WHEEL_DEG) * -dir * amount)
					else:
						zoom_by(zoom_step * dir * amount)
			MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT:
				if mb.pressed:
					add_yaw(deg_to_rad(YAW_WHEEL_DEG) * (1.0 if mb.button_index == MOUSE_BUTTON_WHEEL_LEFT else -1.0) * amount)
	elif event is InputEventMouseMotion and (_right_dragging or _middle_dragging):
		var motion := event as InputEventMouseMotion
		# Bırakma olayı kaçtıysa (ör. tuş pencerenin dışında bırakıldı) sürükleme burada biter.
		if (motion.button_mask & MOUSE_BUTTON_MASK_MIDDLE) == 0:
			_middle_dragging = false
		if (motion.button_mask & MOUSE_BUTTON_MASK_RIGHT) == 0:
			_right_dragging = false
		if _middle_dragging:
			_middle_motion(motion.relative)
		elif _right_dragging:
			_turn_by_drag(motion.relative.x)
	elif event is InputEventPanGesture:
		var pan := event as InputEventPanGesture
		if _gestures.repeated(pan):
			return
		if pan.alt_pressed:
			if tilt_enabled:
				add_pitch(pan.delta.y * pan_pitch_deg)
		elif pan.shift_pressed or absf(pan.delta.x) > absf(pan.delta.y):
			add_yaw(deg_to_rad(-pan.delta.x * pan_yaw_deg))
		else:
			zoom_by(pan.delta.y * pan_zoom_scale)
	elif event is InputEventMagnifyGesture:
		var factor := (event as InputEventMagnifyGesture).factor
		if factor > 0.0 and not _gestures.repeated(event as InputEventGesture):
			zoom_by(_target_distance / factor - _target_distance)


## Kamerayı açar/kapatır. Kapalıyken kameraya dokunmaz ve girişleri yok sayar. Kapanınca oturum (açı, oturum eğimi, tekerlek payı,
## elle verilen ön ayar) sıfırlanır: menüye dönüşte varsayılan kare bekler (K27).
## Açılırken o an ekrandaki kameradan activation_blend saniyelik yumuşak bir geçiş yapar.
func set_active(active: bool) -> void:
	_right_dragging = false
	_middle_dragging = false
	if active == _active:
		return
	_active = active
	if not active:
		_reset_session()
		return
	_ensure_camera()
	_update_auto_preset(true)
	var from: Camera3D = camera
	if is_inside_tree() and get_viewport().get_camera_3d():
		from = get_viewport().get_camera_3d()
	if from and from.is_inside_tree():
		_blend_from = from.global_transform
		# Menü kamerası dar ekranda (ör. 16:10 MacBook) yatay açıyı korur (KEEP_WIDTH); geçiş dikey
		# açılar arasında yapılmazsa ilk karede görüntü bir anda uzaklaşır.
		_blend_from_fov = vertical_fov(from.fov, from.keep_aspect, _viewport_aspect())
	# fov her zaman dikey açıdır: ekran oranı değişse de kadraj (karakterin boyu) aynı kalır.
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_blend = 0.0 if activation_blend > 0.0 else 1.0
	if is_instance_valid(target):
		_focus = _target_point()
	if camera.is_inside_tree():
		camera.make_current()


func is_active() -> bool:
	return _active


## Geçişi ve gecikmeyi atlayıp kamerayı hemen hedefin arkasına koyar.
func snap_to_target() -> void:
	_update_auto_preset(true)
	_yaw = _target_yaw
	_distance = _target_distance
	_session_pitch = _target_session_pitch
	_reset_t = 1.0
	_pw = 1.0
	_blend = 1.0
	if not is_instance_valid(target) or camera == null:
		return
	_follow_yaw = _ride_follow_goal()
	_focus = _target_point()
	if camera.is_inside_tree():
		camera.global_transform = get_follow_transform()
		camera.fov = _fov_now()
		_notify_occluders()
		_update_listener(0.0)


## Kameranın yatay açısı (radyan): seçilen açı ve sürüşteki izleme payı. Oyuncu hareketi bu açıya göre hesaplanır (W = ekranda yukarı).
## Etkinleşme geçişi sürerken ekranda gerçekten görünen açı döner.
func get_yaw() -> float:
	if _active and _blend < 1.0 and camera and camera.is_inside_tree():
		return PlayerController.yaw_from_basis(camera.global_basis)
	return _view_yaw()


## Kamerayı belirli bir açıya çevirir (instant = true ise yumuşatmadan). Sürüşteki izleme payı açıya katılır, izleme RIDE_FOLLOW_WAIT bekler.
func set_yaw(yaw: float, instant: bool = false) -> void:
	_cancel_reset()
	_manual_turn()
	_target_yaw = wrapf(yaw, -PI, PI)
	if instant:
		_yaw = _target_yaw


## Hedef açıya ekleme yapar (radyan; artı = görüş sola döner). Elle döndürmedir: izleme payı açıya katılır, izleme bekler.
func add_yaw(radians: float) -> void:
	_cancel_reset()
	_manual_turn()
	_target_yaw = wrapf(_target_yaw + radians, -PI, PI)


## Sürüşteki izleme payı (radyan; sınama okur).
func get_follow_yaw() -> float:
	return _follow_yaw


## İzleme payının hedefi (saf): atın yönü heading (radyan; 0 = +Z), seçilen açı base. Kamera atın arkasındadır (heading + π); seçilen açıdan farkı
## ±RIDE_FOLLOW_DEG'e kırpılır, RIDE_FOLLOW_CUTOFF_DEG'den büyükse 0 (at kameraya geliyor).
static func ride_follow_offset(heading: float, base: float) -> float:
	var a := wrapf(heading + PI - base, -PI, PI)
	if absf(a) > deg_to_rad(RIDE_FOLLOW_CUTOFF_DEG):
		return 0.0
	return clampf(a, -deg_to_rad(RIDE_FOLLOW_DEG), deg_to_rad(RIDE_FOLLOW_DEG))


## Kamerayı kuzeye hizalar (sürüklemesiz orta tık; K27): yalnız açı, en kısa yönden.
func align_north() -> void:
	set_yaw(0.0)


## Uzaklığı değiştirir (artı = uzaklaş), sınırlar içinde kalır. Uzaklığı sabitleyen sahne çekiminde bekleyen uzaklığa yazılır.
func zoom_by(amount: float) -> void:
	_cancel_reset()
	if _preset and _preset.distance_mode == "fixed":
		_held_distance = clampf(_held_distance + amount, min_distance, max_distance)
		return
	_target_distance = clampf(_target_distance + amount, min_distance, max_distance)


## Oturum eğimine ekler (derece; artı = kamera yükselir, kare dikleşir). Bileşik eğim bandın içinde kalır; sınırın son 4°'sinde hız
## ×0,3'tür. Payı bekleten ön ayarda (oda, sahne çekimi) yok sayılır.
func add_pitch(degrees: float) -> void:
	if _preset and _preset.holds_bias:
		return
	_cancel_reset()
	var base := _pitch_without_session(_target_distance)
	var step := soft_pitch_step(base + _target_session_pitch, degrees)
	_target_session_pitch = clampf(_target_session_pitch + step, PITCH_MIN - base, PITCH_MAX - base)


## Oturum eğimi (derece; şu anki ve hedeflenen).
func get_session_pitch() -> float:
	return _session_pitch


func get_target_session_pitch() -> float:
	return _target_session_pitch


## `/` (camera_reset): açı kuzeye, oturum eğimi 0'a, uzaklık başlangıç uzaklığına (28 m, çocukta 22 m; ön ayarınkine) RESET_SECONDS'ta
## döner (godot.md §5.2). Ayarın eğim payı kalır. Dönüş sürerken gelen girdi dönüşü bırakır, oyuncunun eli kazanır.
func reset_view() -> void:
	if _preset and _preset.distance_mode == "fixed":
		return
	_manual_turn()
	_reset_from = Vector3(_yaw, _session_pitch, _distance)
	_target_yaw = 0.0
	_target_session_pitch = 0.0
	_target_distance = _reset_distance()
	_reset_t = 0.0 if RESET_SECONDS > 0.0 else 1.0


## Varsayılana dönüş sürüyor mu?
func is_resetting() -> bool:
	return _reset_t < 1.0


## Başlangıç uzaklığını değiştirir ve kamerayı oraya koyar (kişi değişince; sınırlar içinde kalır). Açı bu uzaklıkta pitch_deg'dir.
func set_start_distance(p_distance: float) -> void:
	distance = clampf(p_distance, min_distance, max_distance)
	_target_distance = clampf(_start_distance(), min_distance, max_distance)
	_distance = _target_distance


## Hedeflenen (yumuşatma sonrası varılacak) uzaklık.
func get_target_distance() -> float:
	return _target_distance


## Şu anki uzaklıktaki bakış açısı (derece): uzaklığın eğimi + ayarın payı + oturum payı, bandın içinde; ön ayarla.
func current_pitch() -> float:
	var p := _preset_params()
	var bias := (pitch_bias + _session_pitch) * (1.0 - float(p["hold"]))
	var curve := pitch_for_distance(_distance, float(p["pitch"]), float(p["start"]), min_distance, max_distance, zoom_tilt_deg)
	var base := lerpf(curve, float(p["pitch"]), float(p["fixed"]))
	return compose_pitch(base, bias, minf(PITCH_MIN, float(p["pitch"])), maxf(PITCH_MAX, float(p["pitch"])))


## Ön ayarı devreye alır (null ya da walk: yürüyüş); geçiş ön ayarın blend süresinde karışır, instant ise hemen oturur. Elle verilen ön ayar
## kendiliğinden seçimi (Sürüş) bekletir; clear_preset() bırakır.
func apply_preset(preset: CameraPreset, instant := false) -> void:
	_preset_manual = preset != null and preset.id != &"walk"
	_set_preset(preset, instant)


## Elle verilen ön ayarı bırakır: kendiliğinden seçim (yürüyüş ya da atta Sürüş) döner.
func clear_preset(instant := false) -> void:
	_preset_manual = false
	_set_preset(null, instant)
	_update_auto_preset(instant)


## Etkin ön ayarın kimliği (walk, ride, crouch, room, lookout, tengri).
func get_preset_id() -> StringName:
	return _preset.id if _preset else &"walk"


## Ses dinleyicisi (takip kamerası ekrandayken oyuncunun 1,5 m üstünde; yoksa null).
func get_listener() -> AudioListener3D:
	return _listener


## Kameranın şu anki odak/açı/uzaklıkla olması gereken dönüşümü (zemine gömülmez).
## Menü kamerasının kendi geçiş animasyonu için de kullanılabilir.
func get_follow_transform() -> Transform3D:
	var focus := _focus + _lead_offset(float(_preset_params()["lead"]))
	var xform := compute_transform(focus, _view_yaw(), current_pitch(), _distance)
	if terrain_shape:
		var ground: float = terrain_shape.call(&"height_at", xform.origin.x, xform.origin.z)
		xform = lift_above_ground(xform, focus, ground, ground_clearance)
	if transform_filter.is_valid():
		xform = transform_filter.call(xform, focus)
	return xform


## Bir karelik güncelleme: açı, eğim, uzaklık ve odak yumuşakça hedeflerine yaklaşır.
## (_process çağırır; testler doğrudan çağırabilir.)
func update_camera(delta: float) -> void:
	if not is_instance_valid(target) or camera == null:
		return
	_update_auto_preset(false)
	if _pw < 1.0:
		_pw = minf(_pw + delta / maxf(_preset_seconds, 0.001), 1.0)
	# Uzaklık ya da ayarın payı değişince oturum payı bandı aşmaz (sınırda ölü bölge kalmaz); payı bekleten ön ayarda dokunulmaz.
	if _preset == null or not _preset.holds_bias:
		var base := _pitch_without_session(_target_distance)
		_target_session_pitch = clampf(_target_session_pitch, PITCH_MIN - base, PITCH_MAX - base)
	if _reset_t < 1.0:
		_reset_t = minf(_reset_t + delta / RESET_SECONDS, 1.0)
		var w := smoothstep(0.0, 1.0, _reset_t)
		_yaw = wrapf(_reset_from.x + angle_difference(_reset_from.x, _target_yaw) * w, -PI, PI)
		_session_pitch = lerpf(_reset_from.y, _target_session_pitch, w)
		_distance = lerpf(_reset_from.z, _target_distance, w)
	else:
		_yaw = lerp_angle(_yaw, _target_yaw, smoothing(rotate_sharpness, delta))
		var zs := zoom_sharpness if _pw >= 1.0 else minf(zoom_sharpness, 3.0 / maxf(_preset_seconds, 0.05))
		_distance = lerpf(_distance, _target_distance, smoothing(zs, delta))
		_session_pitch = lerpf(_session_pitch, _target_session_pitch, smoothing(pitch_sharpness, delta))
	_update_ride_follow(delta)
	_focus = _focus.lerp(_target_point(), smoothing(follow_sharpness, delta))
	var xform := get_follow_transform()
	var speed := float(target.call(&"get_speed")) if target.has_method(&"get_speed") else 0.0
	_widen = lerpf(_widen, speed_widen(speed), smoothing(SPEED_WIDEN_SHARPNESS, delta))
	if _blend < 1.0:
		_blend = minf(_blend + delta / maxf(activation_blend, 0.001), 1.0)
		var w := smoothstep(0.0, 1.0, _blend)
		camera.global_transform = _blend_from.interpolate_with(xform, w)
		camera.fov = lerpf(_blend_from_fov, _fov_now() + _widen, w)
	else:
		camera.global_transform = xform
		camera.fov = _fov_now() + _widen
	_notify_occluders()
	_update_listener(delta)


## Hızla genişlemenin şimdiki payı (derece; sınama okur).
func get_widen() -> float:
	return _widen


# --- Saf yardımcılar (birim testli) ---------------------------------------------

## Hedefin arkasında ve yukarısında, ona bakan kamera dönüşümü.
## yaw: yatay açı (radyan; 0 = kamera +Z tarafında, -Z'ye bakar). pitch_deg: aşağı bakış açısı.
static func compute_transform(target_pos: Vector3, yaw: float, p_pitch_deg: float, p_distance: float) -> Transform3D:
	var pitch := deg_to_rad(p_pitch_deg)
	var offset := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * p_distance
	return Transform3D(Basis.from_euler(Vector3(-pitch, yaw, 0.0)), target_pos + offset)


## Uzaklığa göre bakış açısı: başlangıç uzaklığından yakında base_pitch (yatıklaşmaz, K98), ötesinde en uzağa doğru base + tilt.
static func pitch_for_distance(d: float, base_pitch: float, default_d: float, _min_d: float, max_d: float, tilt: float) -> float:
	return base_pitch + tilt * clampf((d - default_d) / maxf(max_d - default_d, 0.001), 0.0, 1.0)


## Bileşik eğim (K39): taban (uzaklığın ya da ön ayarın eğimi) + paylar, bandın içinde.
static func compose_pitch(base: float, bias: float, lo := PITCH_MIN, hi := PITCH_MAX) -> float:
	return clampf(base + bias, lo, hi)


## Eğim adımı: sınırın son PITCH_SOFT_ZONE derecesinde sınıra doğru giden adım PITCH_SOFT_RATE katına iner (saf).
static func soft_pitch_step(pitch: float, step: float) -> float:
	if step > 0.0 and pitch > PITCH_MAX - PITCH_SOFT_ZONE:
		return step * PITCH_SOFT_RATE
	if step < 0.0 and pitch < PITCH_MIN + PITCH_SOFT_ZONE:
		return step * PITCH_SOFT_RATE
	return step


## Kamera zeminin clearance metre üstünde değilse yükseltir ve yeniden odağa çevirir.
static func lift_above_ground(xform: Transform3D, focus: Vector3, ground_height: float, clearance: float) -> Transform3D:
	var floor_y := ground_height + clearance
	if xform.origin.y >= floor_y:
		return xform
	var origin := Vector3(xform.origin.x, floor_y, xform.origin.z)
	var look := focus - origin
	if look.length_squared() < 0.000001:
		return Transform3D(xform.basis, origin)
	return Transform3D(Basis.looking_at(look, Vector3.UP), origin)


## Hızda görüş açısının genişlemesi (derece; saf): SPEED_WIDEN_FROM'un altında 0, SPEED_WIDEN_FULL'da SPEED_WIDEN_DEG, arası yumuşak.
static func speed_widen(speed: float) -> float:
	return SPEED_WIDEN_DEG * smoothstep(SPEED_WIDEN_FROM, SPEED_WIDEN_FULL, speed)


## Kare süresinden bağımsız üstel yumuşatma katsayısı (0..1).
static func smoothing(sharpness: float, delta: float) -> float:
	return 1.0 - exp(-maxf(sharpness, 0.0) * maxf(delta, 0.0))


## Bir kameranın fov değerinin dikey karşılığı (derece). keep: Camera3D.keep_aspect;
## KEEP_WIDTH kipindeki kameralarda fov yatay açıdır. aspect: ekranın en/boy oranı.
static func vertical_fov(fov_deg: float, keep: int, aspect: float) -> float:
	if keep == Camera3D.KEEP_HEIGHT or aspect <= 0.0:
		return fov_deg
	return rad_to_deg(2.0 * atan(tan(deg_to_rad(fov_deg) * 0.5) / aspect))


## Düz zeminde kadrajın oyuncunun ayağına göre uzandığı yer (saf; act1.md §4'ün sayıları, metre): north üst kenarın önde, south alt
## kenarın arkada uzaklığı, side kahraman hizasında yarı genişlik. lead: bakılan noktanın ileri payı (eksi = kameraya doğru).
static func ground_reach(p_pitch_deg: float, p_distance: float, fov_deg: float, aspect := 16.0 / 9.0, p_look_height := 0.7, lead := 0.0) -> Dictionary:
	var p := deg_to_rad(p_pitch_deg)
	var half := deg_to_rad(fov_deg) * 0.5
	var h := p_look_height + p_distance * sin(p)
	var back := p_distance * cos(p) - lead
	var north := h / tan(p - half) - back if p > half else INF
	var south := back - h / tan(p + half)
	var depth := back * cos(p) + h * sin(p)
	return {"north": north, "south": south, "side": depth * tan(half) * aspect}


## Dinleyicinin yeri (saf): ayağın LISTENER_HEIGHT üstü, yönü kameranın yatay açısı (yaw = 0'da -Z'ye bakar).
static func listener_transform(feet: Vector3, yaw: float) -> Transform3D:
	return Transform3D(Basis.from_euler(Vector3(0.0, yaw, 0.0)), feet + Vector3.UP * LISTENER_HEIGHT)


# --- İç işler -----------------------------------------------------------------

## Örten nesnelere görüş hattını bildirir (kameradan karakterin göğsüne).
func _notify_occluders() -> void:
	if not is_inside_tree():
		return
	var from := camera.global_position
	var to := _target_point()
	for node in get_tree().get_nodes_in_group(OCCLUDER_GROUP):
		if node.has_method(&"set_camera_occlusion"):
			node.set_camera_occlusion(from, to)


## Ekranın en/boy oranı (sahne dışındayken 16:9 varsayılır).
func _viewport_aspect() -> float:
	if not is_inside_tree():
		return 16.0 / 9.0
	var size := get_viewport().get_visible_rect().size
	return size.x / size.y if size.y > 0.0 else 16.0 / 9.0


## Bakılan nokta: ayakların look_height üstü (zeminin altına asla inmez).
func _target_point() -> Vector3:
	var p := _target_feet()
	p.y += look_height
	if terrain_shape:
		p.y = maxf(p.y, float(terrain_shape.call(&"height_at", p.x, p.z)) + 0.1)
	return p


func _target_feet() -> Vector3:
	return target.global_position if target.is_inside_tree() else target.position


func _ensure_camera() -> void:
	if camera:
		return
	for child in get_children():
		if child is Camera3D:
			camera = child
			return
	camera = Camera3D.new()
	camera.name = "Camera"
	camera.near = 0.05
	camera.far = 6000.0
	camera.fov = fov
	add_child(camera)


func _strength(action: StringName) -> float:
	return Input.get_action_strength(action) if InputMap.has_action(action) else 0.0


## Sağ ya da orta tuşla yatay sürükleme: fareyi sağa sürüklemek görüşü sağa çevirir (ters yatayda sola).
func _turn_by_drag(dx: float) -> void:
	add_yaw(-deg_to_rad(dx * mouse_sensitivity) * (-1.0 if invert_x else 1.0))


## Orta tuşla sürükleme: DRAG_LOCK_PX'e dek birikir, sonra baskın eksene kilitlenir (biriken de uygulanır); yatay döndürür, dikey eğer
## (fareyi yukarı itmek kamerayı ufka doğru alçaltır, ters dikeyde yükseltir).
func _middle_motion(rel: Vector2) -> void:
	if _middle_axis == 0:
		_middle_sum += rel
		if _middle_sum.length() < DRAG_LOCK_PX:
			return
		_middle_axis = 1 if absf(_middle_sum.x) >= absf(_middle_sum.y) else 2
		rel = _middle_sum
	if _middle_axis == 1:
		_turn_by_drag(rel.x)
	elif tilt_enabled:
		add_pitch(rel.y * PITCH_DRAG_DEG * (-1.0 if invert_y else 1.0))


func _cancel_reset() -> void:
	_reset_t = 1.0


## Oturumu sıfırlar (kamera kapanınca): açı kuzeye, oturum eğimi 0, uzaklık başlangıca, elle verilen ön ayar bırakılır.
func _reset_session() -> void:
	_preset_manual = false
	_set_preset(null, true)
	_target_yaw = wrapf(deg_to_rad(start_yaw_deg), -PI, PI)
	_yaw = _target_yaw
	_follow_yaw = 0.0
	_follow_wait = 0.0
	_target_session_pitch = 0.0
	_session_pitch = 0.0
	_target_distance = clampf(_start_distance(), min_distance, max_distance)
	_distance = _target_distance
	_reset_t = 1.0
	_listener_release = 0.0
	if _listener and _listener.is_inside_tree():
		_listener_from = _listener.global_transform


## Oturum payı dışındaki eğim (bant sınırlaması yok): varılacak ön ayarın tabanı + ayarın payı (geçişin karışımı değil).
func _pitch_without_session(d: float) -> float:
	var p := _params_of(_preset)
	var curve := pitch_for_distance(d, float(p["pitch"]), float(p["start"]), min_distance, max_distance, zoom_tilt_deg)
	return lerpf(curve, float(p["pitch"]), float(p["fixed"])) + pitch_bias * (1.0 - float(p["hold"]))


func _fov_now() -> float:
	return float(_preset_params()["fov"])


## Bakılan noktanın ileri payı: kameranın yerdeki ileri yönü (yaw = 0'da -Z) boyunca.
func _lead_offset(lead: float) -> Vector3:
	var yaw := _view_yaw()
	return Vector3(-sin(yaw), 0.0, -cos(yaw)) * lead


## Görünen açı: seçilen açı ve sürüşteki izleme payı.
func _view_yaw() -> float:
	return wrapf(_yaw + _follow_yaw, -PI, PI)


## İzleme payının şimdiki hedefi: atta, izleme açıkken ve beklemiyorken atın arkası (ride_follow_offset), değilse 0.
func _ride_follow_goal() -> float:
	if not ride_follow or _follow_wait > 0.0 or not _riding_horse() or not target.has_method(&"get_facing_yaw"):
		return 0.0
	return ride_follow_offset(float(target.call(&"get_facing_yaw")), _target_yaw)


## İzleme payı: hedefine RIDE_FOLLOW_LAG sn'lik üstel gecikmeyle yaklaşır. Atta değilken ya da izleme kapalıyken görünen açı seçilen açıya katılır
## (inince kamera geri dönmez).
func _update_ride_follow(delta: float) -> void:
	if _follow_wait > 0.0:
		_follow_wait = maxf(_follow_wait - delta, 0.0)
	if not ride_follow or not _riding_horse():
		_absorb_follow()
		return
	var goal := _ride_follow_goal()
	_follow_yaw += (goal - _follow_yaw) * (1.0 - exp(-maxf(delta, 0.0) / RIDE_FOLLOW_LAG))


## Elle döndürme: görünen açı seçilen açı olur, izleme RIDE_FOLLOW_WAIT bekler.
func _manual_turn() -> void:
	_absorb_follow()
	if _riding_horse():
		_follow_wait = RIDE_FOLLOW_WAIT


## İzleme payını seçilen açıya katar (görünen açı değişmez).
func _absorb_follow() -> void:
	if _follow_yaw == 0.0:
		return
	_target_yaw = wrapf(_target_yaw + _follow_yaw, -PI, PI)
	_yaw = wrapf(_yaw + _follow_yaw, -PI, PI)
	if _reset_t < 1.0:
		_reset_from.x = wrapf(_reset_from.x + _follow_yaw, -PI, PI)
	_follow_yaw = 0.0


## Bir ön ayarın kadraj değerleri: eğim, pitch_for_distance'ın başlangıç uzaklığı, ileri pay, payı bekletmesi, sabit eğim payı, görüş.
func _params_of(preset: CameraPreset) -> Dictionary:
	if preset == null:
		return {"pitch": pitch_deg, "start": distance, "lead": 0.0, "hold": 0.0, "fixed": 0.0, "fov": fov}
	var fixed := preset.distance_mode == "keep" or preset.distance_mode == "fixed"
	return {
		"pitch": preset.pitch_deg if preset.distance_mode != "at_least" else pitch_deg,
		"start": _start_distance_for(preset),
		"lead": preset.lead,
		"hold": 1.0 if preset.holds_bias else 0.0,
		"fixed": 1.0 if fixed else 0.0,
		"fov": preset.fov if preset.fov > 0.0 else fov,
	}


## Şu anki kadraj değerleri: geçiş sürerken önceki ön ayardan yenisine karışır.
func _preset_params() -> Dictionary:
	var now := _params_of(_preset)
	if _pw >= 1.0 or _preset_from.is_empty():
		return now
	var w := smoothstep(0.0, 1.0, _pw)
	var out := {}
	for key in now:
		out[key] = lerpf(float(_preset_from.get(key, now[key])), float(now[key]), w)
	return out


## Ön ayarın başlangıç uzaklığı ("start" ön ayarın kendisi, "offset" yürüyüşün başlangıcı + ön ayarın payı; ötekilerde yürüyüşün başlangıcı).
func _start_distance_for(preset: CameraPreset) -> float:
	if preset != null and preset.id != &"walk":
		match preset.distance_mode:
			"start":
				return preset.distance
			"offset":
				return distance + preset.distance
	return distance


func _start_distance() -> float:
	return _start_distance_for(_preset)


## `/`'nin döndürdüğü uzaklık: başlangıç uzaklığı; çömelmede en az onun uzaklığı.
func _reset_distance() -> float:
	var d := _start_distance()
	if _preset and _preset.distance_mode == "at_least":
		d = maxf(d, _preset.distance)
	return clampf(d, min_distance, max_distance)


## Ön ayarı değiştirir: önceki ön ayarın uzaklığı geri alınır, yenisininki kurulur; değerler geçiş boyunca karışır.
func _set_preset(preset: CameraPreset, instant: bool) -> void:
	if preset != null and preset.id == &"walk":
		preset = null
	if preset == _preset or (preset != null and _preset != null and preset.id == _preset.id):
		if instant:
			_pw = 1.0
		return
	var from := _preset_params()
	var old_start := _start_distance()
	var old := _preset
	# Önceki ön ayarın uzaklık kipini geri al.
	if old:
		match old.distance_mode:
			"at_least":
				if _restore_distance >= 0.0 and is_equal_approx(_target_distance, _at_least_set):
					_target_distance = _restore_distance
			"fixed":
				if _held_distance >= 0.0:
					_target_distance = _held_distance
	_preset = preset
	# Açı: payı bekleten ön ayara girerken oyuncunun açısı saklanır (oda kuzeye döner; K27), çıkınca geri gelir.
	var held_before := old != null and old.holds_bias
	var holds_now := preset != null and preset.holds_bias
	if holds_now and not held_before:
		_held_yaw = _target_yaw
	if holds_now and preset.faces_north:
		_target_yaw = 0.0
	elif held_before and not holds_now:
		_target_yaw = _held_yaw
	# Yenisinin uzaklık kipi: başlangıç uzaklığı değişince oyuncunun tekerlek payı korunur.
	var mode := preset.distance_mode if preset else "start"
	match mode:
		"start", "offset":
			var start_before := old_start if (old == null or old.distance_mode in ["start", "offset"]) else distance
			_target_distance = clampf(_target_distance + (_start_distance() - start_before), min_distance, max_distance)
		"at_least":
			_restore_distance = _target_distance
			_target_distance = clampf(maxf(_target_distance, preset.distance), min_distance, max_distance)
			_at_least_set = _target_distance
		"fixed":
			_held_distance = _target_distance
			_target_distance = preset.distance
	_preset_seconds = preset.blend if preset else (old.blend if old else 1.1)
	if instant:
		_pw = 1.0
		_preset_from = {}
		_distance = _target_distance
	else:
		_pw = 0.0
		_preset_from = from


## Kendiliğinden ön ayar: hedef ata biniyorsa Sürüş, değilse yürüyüş (elle verilen ön ayar beklerken dokunulmaz).
func _update_auto_preset(instant: bool) -> void:
	if not auto_presets or _preset_manual:
		return
	var want_id := &"ride" if _riding_horse() else &"walk"
	if want_id != get_preset_id():
		_set_preset(CameraPreset.ride() if want_id == &"ride" else null, instant)


func _riding_horse() -> bool:
	if not is_instance_valid(target) or not target.has_method(&"is_riding") or not bool(target.call(&"is_riding")):
		return false
	return target.has_method(&"mount_kind") and str(target.call(&"mount_kind")) == "horse"


## Dinleyici: takip kamerası ekrandayken oyuncunun 1,5 m üstünde (geçişte kameradan oyuncuya kayar); takip kapanınca ya da başka kamera
## ekrana gelince activation_blend sürede ekrandaki kameraya kayar ve bırakılır (kamera dinler).
func _update_listener(delta: float) -> void:
	if not is_inside_tree():
		return
	var cam := get_viewport().get_camera_3d()
	var on_player := _active and is_instance_valid(target) and camera != null and camera.is_inside_tree() and cam == camera
	if on_player:
		if _listener == null:
			_listener = AudioListener3D.new()
			_listener.name = "Listener"
			add_child(_listener)
		var goal := listener_transform(_target_feet(), _view_yaw())
		if _blend < 1.0:
			goal = camera.global_transform.interpolate_with(goal, smoothstep(0.0, 1.0, _blend))
		_listener.global_transform = goal
		_listener_release = 0.0
		_listener_from = goal
		if not _listener.is_current():
			_listener.make_current()
		return
	if _listener == null or not _listener.is_current():
		return
	if _listener_release <= 0.0:
		_listener_from = _listener.global_transform
	_listener_release += delta / maxf(activation_blend, 0.001)
	if cam == null or activation_blend <= 0.0 or _listener_release >= 1.0:
		_listener.clear_current()
		_listener_release = 1.0
		return
	_listener.global_transform = _listener_from.interpolate_with(cam.global_transform, smoothstep(0.0, 1.0, _listener_release))
