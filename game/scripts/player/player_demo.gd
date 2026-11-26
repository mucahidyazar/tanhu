extends Node3D
## Oyuncu denetleyicisi ve takip kamerası için deneme sahnesi (scenes/player/player_demo.tscn).
##
## Dünyayı yükler, karakteri ana oyundaki gibi kamp ateşinin önüne koyar ve kamerayı arkasına yerleştirir.
## Ekranın altında kısa bir tuş rehberi görünür; Esc oyunu duraklatır / sürdürür.
##
## Geliştirme (ekran görüntüsü):
##   tools/capture.sh <çıktı.png> 240 --scene=res://scenes/player/player_demo.tscn [--pose=x,y,z,yaw,pitch] [--hide-ui]
##   --pose: karakter (x, z) noktasına konur; kamera yaw (derece) açısından bakar; pitch > 0 ise
##   bakış açısı olarak, y > 0 ise kamera uzaklığı olarak kullanılır.
##   --walk: karakter ekranda yukarı doğru yürür (--walk=run ise koşar).
## Kayıt sırasında klavye/fare girişi yok sayılır; böylece görüntüler her seferinde aynı çıkar.
## İstekler doğrudan komut satırından okunur: DevCapture'ın ertelenmiş sinyalleri, pencere boyutu
## değişirken (--window) bu sahne daha hazır olmadan yayılabiliyor ve poz kayboluyordu.

const CaptureTool := preload("res://scripts/dev/capture.gd")

## Karakterin başlangıç yeri, kamp ateşine göre (ana oyundaki gibi: ateşin önü, kameraya doğru;
## bkz. scripts/main.gd) ve baktığı yön (derece; 180 = ateşe, -Z yönüne bakar).
@export var spawn_offset := Vector3(0.8, 0.0, 4.0)
@export var spawn_yaw_deg := 180.0

@onready var player: PlayerController = $Player
@onready var follow_camera: FollowCamera = $FollowCamera

var _ui: CanvasLayer
var _paused_label: Label
var _paused := false


func _ready() -> void:
	InputSetup.ensure_actions()
	player.refresh_obstacles()
	player.spawn_at(spawn_point(), deg_to_rad(spawn_yaw_deg))
	follow_camera.snap_to_target()
	player.pause_requested.connect(_set_paused.bind(true))
	_build_ui()
	var capture := get_node_or_null(^"/root/DevCapture")
	if capture and not capture.is_queued_for_deletion():
		_enter_capture_mode(CaptureTool.parse_args(OS.get_cmdline_user_args()))


## Karakterin başladığı nokta: kamp ateşinin önü (ateş yoksa dünyanın merkezi) + spawn_offset.
func spawn_point() -> Vector3:
	var fire := get_node_or_null(^"World/Camp/Campfire") as Node3D
	var base := fire.global_position if fire else Vector3.ZERO
	return Vector3(base.x, 0.0, base.z) + spawn_offset


## Ekran görüntüsü kaydı: gerçek girişi kapatır; poz, arayüz ve yürüme isteklerini uygular.
## args: CaptureTool.parse_args() sonucu.
func _enter_capture_mode(args: Dictionary) -> void:
	player.set_active(false)
	follow_camera.input_enabled = false
	var pose := parse_pose(str(args.get("pose", "")))
	if not pose.is_empty():
		_on_pose_requested(Vector3(pose[0], pose[1], pose[2]), pose[3], pose[4])
	if args.has("hide-ui"):
		_ui.visible = false
	if args.has("walk"):
		player.auto_move = Vector2(0.0, 1.0)
		player.auto_sprint = str(args["walk"]) == "run"


## "x,y,z,yaw,pitch" biçimindeki poz metnini beş sayıya çevirir (saf fonksiyon); geçersizse boş dizi.
static func parse_pose(text: String) -> PackedFloat32Array:
	var parts := text.split(",")
	var values := PackedFloat32Array()
	if parts.size() < 5:
		return values
	for i in 5:
		var part := parts[i].strip_edges()
		if not part.is_valid_float():
			return PackedFloat32Array()
		values.append(part.to_float())
	return values


func _unhandled_input(event: InputEvent) -> void:
	if _paused and event.is_action_pressed(&"pause"):
		_set_paused(false)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"toggle_fullscreen"):
		var mode := DisplayServer.window_get_mode()
		var full := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)


func _set_paused(paused: bool) -> void:
	_paused = paused
	player.set_active(not paused)
	follow_camera.set_active(not paused)
	_paused_label.visible = paused


## Ekran görüntüsü aracı: karakteri ve kamerayı istenen yere koyar.
func _on_pose_requested(pos: Vector3, yaw_deg: float, pitch_deg: float) -> void:
	player.spawn_at(Vector3(pos.x, 0.0, pos.z), deg_to_rad(yaw_deg + 180.0))
	follow_camera.set_yaw(deg_to_rad(yaw_deg), true)
	if pitch_deg > 0.0:
		follow_camera.pitch_deg = pitch_deg
	if pos.y > 0.0:
		follow_camera.distance = pos.y
		follow_camera.zoom_by(pos.y - follow_camera.get_target_distance())
	follow_camera.snap_to_target()


## Alt kenarda yumuşak, yarı saydam bir tuş rehberi.
func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.name = "UI"
	add_child(_ui)
	var hint := Label.new()
	hint.name = "Hint"
	hint.text = "WASD / Oklar: Yürü   ·   Shift: Koş   ·   Q / E: Kamerayı döndür   ·   Sağ tık + sürükle: Döndür   ·   Tekerlek: Yakınlaştır   ·   Esc: Duraklat"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override(&"font_size", 17)
	hint.add_theme_color_override(&"font_color", Color(0.97, 0.94, 0.86, 0.92))
	hint.add_theme_color_override(&"font_shadow_color", Color(0.05, 0.06, 0.12, 0.7))
	hint.add_theme_constant_override(&"shadow_offset_y", 2)
	var panel := PanelContainer.new()
	panel.name = "HintPanel"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.08, 0.15, 0.42)
	style.set_corner_radius_all(14)
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override(&"panel", style)
	panel.add_child(hint)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE, 24)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_ui.add_child(panel)
	_paused_label = Label.new()
	_paused_label.name = "Paused"
	_paused_label.text = "Duraklatıldı  —  sürdürmek için Esc"
	_paused_label.add_theme_font_size_override(&"font_size", 34)
	_paused_label.add_theme_color_override(&"font_color", Color(0.98, 0.95, 0.88))
	_paused_label.add_theme_color_override(&"font_shadow_color", Color(0.05, 0.06, 0.12, 0.8))
	_paused_label.add_theme_constant_override(&"shadow_offset_y", 3)
	_paused_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_paused_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_paused_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	_paused_label.visible = false
	_ui.add_child(_paused_label)
