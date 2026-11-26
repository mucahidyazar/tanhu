@tool
class_name CreatorTurntable
extends SubViewportContainer
## Karakter oluşturucudaki canlı 3B önizleme ("döner kaide").
##
## - İçindeki SubViewport'un kendi 3B dünyası vardır (own_world_3d) ve arka planı saydamdır;
##   karakter, arkadaki boyalı zeminin üzerinde durur.
## - Farenin sol tuşuyla (dokunmatik ekranda parmakla) sürüklemek karakteri döndürür; dönüş
##   hedef açıyı yumuşak bir gecikmeyle izler. Çift tıklama açılıştaki 3/4 açıya döndürür.
## - Fare tekerleği (ya da dokunmatik yüzeyde iki parmakla kaydırma / sıkıştırma) kamerayı "tam boy"
##   ile "yakın plan" arasında yumuşakça kaydırır; göz rengi gibi küçük ayrıntılar böyle görülür.
## - Kadraj gösterilen karakterin gerçek boyuna (CharacterAvatar.get_model_height) ve kafa yüksekliğine
##   göre kurulur: tam boyda karakter baştan ayağa görünür, yakın planda yüz ortalanır. Vücut tipi
##   değişince (ör. 1.82 m Mete → 1.68 m kadın kahraman) kadraj yeni boya göre yeniden hesaplanır.
## - Retina gibi yüksek yoğunluklu ekranlarda görüntü bulanık olmasın diye iç görüntü fiziksel
##   piksel çözünürlüğünde çizilir ve kap aynı oranda küçültülür (bkz. _fit_to_parent).
##   Bu yüzden bu düğüm sıradan bir Control'ün (Container olmayan) çocuğu olmalıdır.
## - Model değişince karakter küçük bir "zıplama" ile yeniden belirir; oyuncu modelleri arka planda
##   önceden yüklenir ki saç modeli değiştirirken takılma olmasın.
## - Görüntüye referanstaki "soluk film" renk ayarı (ColorGrade.creator()) uygulanır: koyu kumaşlar
##   saf siyah değil sıcak bir gri, beyazlar fildişi olur; karakter yumuşak, boyalı görünür.
## - Ekran gizliyken iç görüntü çizilmez (SubViewportContainer bunu kendisi yapar) ve karakterin
##   animasyonu da işlenmez; böylece oyun sırasında gizli duran oluşturucu boşuna iş yapmaz.

## Kamera tam boy / yakın plan arasında geçti (true = yakın plan).
signal view_changed(close_up: bool)

## Sürüklemede ekran pikseli başına dönüş (radyan).
const DRAG_SENSITIVITY := 0.0105
## Dönüşün ve yakınlaşmanın hedefe yaklaşma hızı (büyüdükçe daha çabuk).
const FOLLOW_RATE := 9.0
const ZOOM_RATE := 6.0
## İç görüntünün en fazla kaç kat yüksek çözünürlükte çizileceği.
const MAX_RENDER_SCALE := 2.0
## İki parmakla kaydırmada yakınlığı değiştirmek için gereken en küçük dikey hareket.
const PAN_ZOOM_THRESHOLD := 0.05
## Renk ayarı LUT'unun kenar uzunluğu. Ayar yumuşak (neredeyse doğrusal) olduğu için 16³ yeterlidir
## ve bir kerelik üretimi yalnızca birkaç milisaniye sürer.
const GRADE_LUT_SIZE := 16

## Oyuncu modelleri arka planda önceden yüklensin mi? (Testler kapatır.)
static var preload_enabled := true

## Açılıştaki dönüş: hafif 3/4 açı (derece). Pozitif değer karakteri ekranın sağına çevirir.
@export var start_yaw_degrees := 18.0
@export_group("Kamera")
## Kadraj karakterin gerçek boyuna göre kurulur (Mete 1.82 m, kadın kahraman 1.68 m; ayaklar orijinde).
## Tam boy: karakter ekran yüksekliğinin full_fill kadarını kaplar; orta noktası ekranda full_center
## yüksekliğinde durur (0 = üst kenar, 1 = alt kenar; 0.5'ten büyükse karakter başlık şeridinden uzaklaşır).
@export_range(0.4, 0.95) var full_fill := 0.8
@export_range(0.3, 0.7) var full_center := 0.535
## Kameranın karaktere hafif yukarıdan bakış açısı (derece).
@export_range(-10.0, 30.0) var full_elevation_degrees := 5.0
## Yakın plan (baş ve omuzlar): 1.75 m boylu bir karakterde ekran yüksekliğine sığan dikey alan (metre;
## boyla orantılı ölçeklenir) ve yüzün ekrandaki yüksekliği.
@export var close_view_height := 0.7
@export_range(0.3, 0.7) var close_center := 0.46
@export_range(-10.0, 30.0) var close_elevation_degrees := 3.0

@onready var _viewport: SubViewport = $Viewport
@onready var _world_environment: WorldEnvironment = $Viewport/WorldEnvironment
@onready var _camera: Camera3D = $Viewport/Camera
@onready var _pivot: Node3D = $Viewport/Pivot
@onready var _avatar: CharacterAvatar = $Viewport/Pivot/Avatar

## Şu anki ve hedeflenen dönüş açısı (radyan).
var yaw := 0.0
var target_yaw := 0.0
## Şu anki ve hedeflenen yakınlık: 0 = tam boy, 1 = yakın plan.
var zoom := 0.0
var target_zoom := 0.0
var _dragging := false
## Dokunmatik yüzey jestinin ikinci kopyası (GestureDedupe).
var _gestures := GestureDedupe.new()
var _render_scale := 1.0
var _pending_loads: PackedStringArray = []
var _loaded_models: Array[Resource] = []
var _pop_tween: Tween
## Gösterilen modele göre kurulan kadrajlar: [tam boy konum, tam boy hedef, yakın konum, yakın hedef].
var _frames: Array[Vector3] = [Vector3(0.0, 0.92, 2.95), Vector3(0.0, 0.64, 0.0), Vector3(0.0, 1.0, 1.9), Vector3(0.0, 0.88, 0.0)]


func _ready() -> void:
	stretch = true
	# SubViewportContainer tıklanınca normalde klavye odağını alır; o zaman her tuş önce ona (ve iç
	# görüntüye) gider. Önizlemenin klavyeyle işi yoktur: tuşları CharacterCreator işler.
	focus_mode = Control.FOCUS_NONE
	yaw = deg_to_rad(start_yaw_degrees)
	target_yaw = yaw
	_pivot.rotation.y = yaw
	if Engine.is_editor_hint():
		return
	_update_frames()
	_apply_camera()
	_apply_color_grade()
	_update_preview_processing()
	_avatar.model_changed.connect(_on_model_changed)
	var parent := get_parent() as Control
	if parent:
		parent.resized.connect(_fit_to_parent)
	get_viewport().size_changed.connect(_fit_to_parent)
	_fit_to_parent()
	if preload_enabled:
		preload_player_models()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		_update_preview_processing()


## Ekran, modeller arka planda yüklenirken kapatılırsa bekleyen yüklemeler yine de teslim alınır.
## Alınmazsa her birinin yükleme kaydı ve modelin kendisi oyun kapanana kadar bellekte kalır.
## Yükleme hâlâ sürüyorsa bu çağrı bitmesini bekler (yalnızca ekran açılır açılmaz kapatılırsa).
func _exit_tree() -> void:
	for path in _pending_loads:
		# Önizlemedeki karakter sonucu çoktan almış olabilir (bkz. CharacterAvatar.load_scene).
		if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_loaded_models.append(ResourceLoader.load_threaded_get(path))
	_pending_loads.clear()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	yaw = CreatorTurntable.follow(yaw, target_yaw, FOLLOW_RATE, delta)
	_pivot.rotation.y = yaw
	if not is_equal_approx(zoom, target_zoom):
		zoom = CreatorTurntable.follow(zoom, target_zoom, ZOOM_RATE, delta)
		if absf(zoom - target_zoom) < 0.001:
			zoom = target_zoom
		_apply_camera()
	_poll_model_loads()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion and _dragging:
		# Dokunmatik ekranda parmak hareketi hem InputEventScreenDrag hem de ondan türetilmiş bir fare
		# hareketi üretir; türetilmiş olan da sayılsaydı karakter iki kat hızlı dönerdi.
		if event.device != InputEvent.DEVICE_ID_EMULATION:
			rotate_by_drag(event.relative.x)
		accept_event()
	elif event is InputEventScreenDrag:
		rotate_by_drag(event.relative.x)
		accept_event()
	elif event is InputEventMagnifyGesture:
		if _gestures.repeated(event as InputEventGesture):
			accept_event()
			return
		var factor: float = event.factor
		if factor > 1.02:
			set_close_up(true)
		elif factor < 0.98:
			set_close_up(false)
		accept_event()
	elif event is InputEventPanGesture:
		# macOS dokunmatik yüzeyinde iki parmakla kaydırma tekerlek olayı değil, bu olayı üretir.
		if _gestures.repeated(event as InputEventGesture):
			accept_event()
			return
		var direction := CreatorTurntable.zoom_direction_for_pan((event as InputEventPanGesture).delta)
		if direction != 0:
			set_close_up(direction > 0)
		accept_event()


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	match event.button_index:
		MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
			mouse_default_cursor_shape = Control.CURSOR_DRAG if _dragging else Control.CURSOR_ARROW
			if event.pressed and event.double_click:
				reset_rotation()
		MOUSE_BUTTON_WHEEL_UP:
			if event.pressed:
				set_close_up(true)
		MOUSE_BUTTON_WHEEL_DOWN:
			if event.pressed:
				set_close_up(false)
		_:
			return
	accept_event()


## Yatay sürükleme miktarını (bu düğümün yerel pikseli) dönüşe çevirir.
func rotate_by_drag(dx: float) -> void:
	target_yaw = CreatorTurntable.drag_yaw(target_yaw, dx, _render_scale)


## Karakteri açılıştaki 3/4 açıya döndürür.
func reset_rotation(instant: bool = false) -> void:
	target_yaw = deg_to_rad(start_yaw_degrees)
	if instant:
		yaw = target_yaw
		_pivot.rotation.y = yaw


## Kamerayı yakın plana (true) ya da tam boya (false) kaydırır; değişirse view_changed yayar.
func set_close_up(value: bool, instant: bool = false) -> void:
	var target := 1.0 if value else 0.0
	if instant:
		zoom = target
		_apply_camera()
	if is_equal_approx(target, target_zoom):
		return
	target_zoom = target
	view_changed.emit(value)


## Yakın plan seçili mi?
func is_close_up() -> bool:
	return target_zoom > 0.5


## Önizlemedeki karakter.
func get_avatar() -> CharacterAvatar:
	return _avatar


## İç görüntünün ekran ölçeğine göre çözünürlük çarpanı (1 = normal, 2 = Retina).
func get_render_scale() -> float:
	return _render_scale


## Arka planda yüklenmeyi bekleyen model var mı?
func is_preloading() -> bool:
	return not _pending_loads.is_empty()


## Tüm oyuncu modellerini (vücut tipi x saç modeli) arka planda yüklemeye başlar.
func preload_player_models() -> void:
	for path in CreatorTurntable.player_model_paths():
		if not ResourceLoader.exists(path) or ResourceLoader.has_cached(path) or _pending_loads.has(path):
			continue
		if ResourceLoader.load_threaded_request(path) == OK:
			_pending_loads.append(path)


# --- Saf yardımcılar (test edilebilir) -------------------------------------------

## Sürüklemeden sonraki hedef açı. dx yerel pikseldir; render_scale ile ekran pikseline çevrilir.
static func drag_yaw(current_target: float, dx: float, render_scale: float = 1.0) -> float:
	return current_target + dx * DRAG_SENSITIVITY / maxf(render_scale, 0.001)


## İki parmakla kaydırmanın yakınlaştırma yönü: 1 = yakın plan (yukarı kaydırma; tekerleği yukarı
## çevirmek gibi), -1 = tam boy, 0 = çok küçük ya da çoğunlukla yatay hareket (yok sayılır).
static func zoom_direction_for_pan(delta: Vector2) -> int:
	if absf(delta.y) < PAN_ZOOM_THRESHOLD or absf(delta.y) < absf(delta.x):
		return 0
	return 1 if delta.y < 0.0 else -1


## current değerini target'a üstel yumuşatmayla yaklaştırır (kare hızından bağımsız).
static func follow(current: float, target: float, rate: float, delta: float) -> float:
	return lerpf(current, target, 1.0 - exp(-rate * delta))


## Yakınlığa (0..1) göre kamera konumu ve bakılan nokta: [konum, hedef]. Geçiş yumuşak başlar ve biter.
static func camera_frame(t: float, from_position: Vector3, from_target: Vector3, to_position: Vector3, to_target: Vector3) -> Array[Vector3]:
	var e := smoothstep(0.0, 1.0, clampf(t, 0.0, 1.0))
	var frame: Array[Vector3] = [from_position.lerp(to_position, e), from_target.lerp(to_target, e)]
	return frame


## Tam boy kadraj: boyu height olan karakter (ayakları orijinde) ekran yüksekliğinin fill kadarını kaplar;
## karakterin orta noktası ekranda center yüksekliğinde görünür (0 = üst, 1 = alt). Kamera karşıdan
## (+Z), elevation_deg kadar yukarıdan bakar. Döner: [kamera konumu, bakılan nokta].
static func full_frame(height: float, fov_deg: float, fill: float, center: float, elevation_deg: float) -> Array[Vector3]:
	var visible := maxf(height, 0.1) / clampf(fill, 0.1, 1.0)
	var target := Vector3(0.0, height * 0.5 + (center - 0.5) * visible, 0.0)
	return _frame_from(target, visible, fov_deg, elevation_deg)


## Yakın plan kadraj: kafa ekleminin (head_y) biraz üstündeki yüz, ekranda center yüksekliğinde; ekrana
## view_height (1.75 m'lik karaktere göre, boyla ölçeklenir) kadar dikey alan sığar. Döner: [konum, hedef].
static func close_frame(height: float, head_y: float, fov_deg: float, view_height: float, center: float, elevation_deg: float) -> Array[Vector3]:
	var visible := view_height * clampf(height / 1.75, 0.5, 1.3)
	var face := head_y + maxf(height - head_y, 0.0) * 0.35
	var target := Vector3(0.0, face + (center - 0.5) * visible, 0.0)
	return _frame_from(target, visible, fov_deg, elevation_deg)


## Hedefe bakan ve ekranda visible metre dikey alan gösteren kamera konumu.
static func _frame_from(target: Vector3, visible: float, fov_deg: float, elevation_deg: float) -> Array[Vector3]:
	var distance := visible * 0.5 / tan(deg_to_rad(clampf(fov_deg, 5.0, 120.0)) * 0.5)
	var e := deg_to_rad(elevation_deg)
	var frame: Array[Vector3] = [target + Vector3(0.0, sin(e), cos(e)) * distance, target]
	return frame


## Oyuncunun seçebileceği tüm modellerin GLB yolları (tekrarsız).
static func player_model_paths() -> PackedStringArray:
	var paths := PackedStringArray()
	for body_type in CharacterOptions.BODY_TYPES.size():
		for i in CharacterOptions.count(&"hairstyle", body_type):
			var path := CharacterOptions.model_path(CharacterOptions.model_for(body_type, i))
			if not paths.has(path):
				paths.append(path)
	return paths


## Pencerenin fiziksel boyutu ile mantıksal (ölçeklenmiş) boyutu arasındaki oran, [1, MAX] aralığında.
static func render_scale_for(window_size: Vector2, visible_size: Vector2) -> float:
	if visible_size.x <= 0.0 or visible_size.y <= 0.0 or window_size.x <= 0.0 or window_size.y <= 0.0:
		return 1.0
	var ratio := minf(window_size.x / visible_size.x, window_size.y / visible_size.y)
	return clampf(ratio, 1.0, MAX_RENDER_SCALE)


# --- İç işler ----------------------------------------------------------------------

## Önizleme ortamına referanstaki "soluk film" renk ayarını uygular (bkz. ColorGrade.creator()).
func _apply_color_grade() -> void:
	var environment := _world_environment.environment if _world_environment else null
	if environment == null:
		return
	var grade := ColorGrade.creator()
	grade.size = GRADE_LUT_SIZE
	grade.apply_to(environment)


## Ekran gizliyken iç görüntünün düğümleri (karakter, animasyon oynatıcısı) işlenmez; görünür
## olunca kaldıkları yerden devam ederler.
func _update_preview_processing() -> void:
	if _viewport == null or Engine.is_editor_hint():
		return
	_viewport.process_mode = Node.PROCESS_MODE_INHERIT if is_visible_in_tree() else Node.PROCESS_MODE_DISABLED


## Kamerayı şu anki yakınlığa göre yerleştirir.
func _apply_camera() -> void:
	var frame := CreatorTurntable.camera_frame(zoom, _frames[0], _frames[1], _frames[2], _frames[3])
	_camera.look_at_from_position(frame[0], frame[1], Vector3.UP)


## Kadrajları gösterilen karakterin boyuna ve kafa yüksekliğine göre yeniden kurar.
func _update_frames() -> void:
	if _avatar == null or _camera == null:
		return
	var height := _avatar.get_model_height()
	var full := CreatorTurntable.full_frame(height, _camera.fov, full_fill, full_center, full_elevation_degrees)
	var close := CreatorTurntable.close_frame(height, _avatar.get_head_height(), _camera.fov, close_view_height,
		close_center, close_elevation_degrees)
	_frames = [full[0], full[1], close[0], close[1]]


## Gösterilen karakterin kadrajları: [tam boy konum, tam boy hedef, yakın konum, yakın hedef] (testler için).
func get_frames() -> Array[Vector3]:
	return _frames


## Kabı ebeveyninin alanına yerleştirir: boyut = alan x ölçek, görünüm ölçeği = 1 / ölçek.
## Böylece SubViewport fiziksel piksel çözünürlüğünde çizer ama ekranda aynı yeri kaplar.
func _fit_to_parent() -> void:
	var parent := get_parent() as Control
	if parent == null:
		return
	var window := get_window()
	_render_scale = 1.0
	if window:
		_render_scale = CreatorTurntable.render_scale_for(Vector2(window.size), get_viewport().get_visible_rect().size)
	scale = Vector2.ONE / _render_scale
	position = Vector2.ZERO
	size = parent.size * _render_scale


func _on_model_changed(_id: String) -> void:
	# Yeni Meshy modeli bağ pozunda (T-poz) gelir; bekleme animasyonunu yeniden başlat.
	if _avatar.has_meshy_model():
		_avatar.play_pose(&"idle")
	# Modeller farklı boylarda (ör. 1.82 m ile 1.68 m): kadrajı yeni boya göre kur.
	_update_frames()
	_apply_camera()
	if _pop_tween:
		_pop_tween.kill()
	_pivot.scale = Vector3.ONE * 0.93
	_pop_tween = create_tween()
	_pop_tween.tween_property(_pivot, ^"scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _poll_model_loads() -> void:
	for i in range(_pending_loads.size() - 1, -1, -1):
		var path := _pending_loads[i]
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			continue
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			# Referansı tutmak modeli önbellekte canlı tutar; CharacterAvatar load() ile anında alır.
			_loaded_models.append(ResourceLoader.load_threaded_get(path))
		_pending_loads.remove_at(i)
