class_name EncyclopediaModelView
extends SubViewportContainer
## Destan Kitabı'nın ansiklopedi sayfasında kişinin döndürülebilir 3B modeli (godot.md §3.8, K85): kaydın model alanındaki
## model (assets/characters/<id>/<id>.glb; kendi modeli olan her kişi, yoksa üçüncü yuva T-pozdur). Oluşturucunun döner
## kaidesinin (creator_turntable.gd) kalıbı: kendi 3B dünyası olan (own_world_3d), arka planı saydam bir SubViewport; içinde ışık, kamera ve
## CharacterAvatar. Yalnız üçüncü küçük resim (3B) seçilince kurulur; model arka planda yüklenir
## (load_threaded_request; başsız koşuda doğrudan), o sırada «3B model yükleniyor…» yazar. Kendiliğinden yavaşça döner, fareyle
## sürüklenince döner; çıkarken bekleyen yüklemeyi teslim alıp bırakır.

## Model yüklendi ve sahnede.
signal model_ready(model_id: String)

## Kendiliğinden dönüş (radyan / sn) ve sürüklemenin piksel başına dönüşü.
const SPIN_RATE := 0.35
const DRAG_SENSITIVITY := 0.0105
## Kameranın görüş açısı ve kadrajı (CreatorTurntable.full_frame ile): boyun %82'si ekrana sığar.
const FOV := 30.0
const FILL := 0.82
const CENTER := 0.52
const ELEVATION := 6.0
const LOADING_TEXT := "3B model yükleniyor…"
const MISSING_TEXT := "3B model bulunamadı."

var model_id := ""

var _viewport: SubViewport
var _camera: Camera3D
var _pivot: Node3D
var _avatar: CharacterAvatar
var _label: Label
var _path := ""
var _pending := false
var _dragging := false
var _spin := true


func _init(p_model_id: String = "") -> void:
	model_id = p_model_id


func _ready() -> void:
	stretch = true
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_STOP
	_viewport = SubViewport.new()
	_viewport.name = "Viewport"
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	add_child(_viewport)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.93, 0.88, 0.8)
	e.ambient_light_energy = 0.55
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	_viewport.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-38.0, 28.0, 0.0)
	key.light_energy = 1.25
	key.light_color = Color(1.0, 0.95, 0.86)
	_viewport.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-12.0, -150.0, 0.0)
	fill.light_energy = 0.45
	fill.light_color = Color(0.75, 0.85, 1.0)
	_viewport.add_child(fill)
	_camera = Camera3D.new()
	_camera.fov = FOV
	_camera.current = true
	_viewport.add_child(_camera)
	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	_pivot.rotation.y = deg_to_rad(18.0)
	_viewport.add_child(_pivot)
	_frame(1.75)
	_label = Label.new()
	_label.text = LOADING_TEXT
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_override("font", UIKit.font("Alegreya-Italic"))
	_label.add_theme_font_size_override("font_size", 22)
	_label.add_theme_color_override("font_color", Color(UIKit.INK, 0.7))
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(_label)
	add_child(_label)
	_request()


## Modelin dosya yolu (yoksa boş).
static func model_path(id: String) -> String:
	if id.is_empty():
		return ""
	var path := CharacterOptions.model_path(id)
	return path if ResourceLoader.exists(path) else ""


## Model yüklendi mi?
func is_ready() -> bool:
	return _avatar != null


## Sahnedeki karakter (yüklenmediyse null).
func get_avatar() -> CharacterAvatar:
	return _avatar


## Gösterilen yazı («yükleniyor», «bulunamadı» ya da boş).
func get_status_text() -> String:
	return _label.text if _label and _label.visible else ""


func _request() -> void:
	_path = model_path(model_id)
	if _path.is_empty():
		_label.text = MISSING_TEXT
		return
	if not EncyclopediaPage.threaded_loads:
		# Başsız koşu: model hemen yüklenir (sahte çizici dokuları iş parçacığından güvenle kuramaz).
		_build_avatar()
		return
	var status := ResourceLoader.load_threaded_get_status(_path)
	if status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		if ResourceLoader.load_threaded_request(_path, "PackedScene") != OK:
			_label.text = MISSING_TEXT
			return
	_pending = true


func _process(delta: float) -> void:
	if _pending:
		var status := ResourceLoader.load_threaded_get_status(_path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			_pending = false
			_build_avatar()
		elif status != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_pending = false
			_label.text = MISSING_TEXT
	if _avatar and _spin and not _dragging:
		_pivot.rotation.y += SPIN_RATE * delta


## Model hazır: karakter kurulur (CharacterAvatar.load_scene arka plan yüklemesinin sonucunu alır).
func _build_avatar() -> void:
	_avatar = CharacterAvatar.new()
	_avatar.name = "Avatar"
	_avatar.model_override = model_id
	_avatar.start_pose = &"idle"
	_pivot.add_child(_avatar)
	_frame(_avatar.get_model_height())
	_label.visible = false
	model_ready.emit(model_id)


## Kamerayı karakterin boyuna göre kurar: tam boy, hafif yukarıdan.
func _frame(height: float) -> void:
	var f := CreatorTurntable.full_frame(height, FOV, FILL, CENTER, ELEVATION)
	_camera.look_at_from_position(f[0], f[1], Vector3.UP)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_dragging = (event as InputEventMouseButton).pressed
		if not _dragging:
			_spin = false
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		_pivot.rotation.y += (event as InputEventMouseMotion).relative.x * DRAG_SENSITIVITY
		accept_event()


## Bekleyen arka plan yüklemesi teslim alınır; alınmazsa yükleme kaydı ve model bellekte kalır.
func _exit_tree() -> void:
	if _pending and not _path.is_empty():
		if ResourceLoader.load_threaded_get_status(_path) != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			ResourceLoader.load_threaded_get(_path)
	_pending = false
