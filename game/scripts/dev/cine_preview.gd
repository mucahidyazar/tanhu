extends Node3D
## Sinema önizlemesi: bir dizi ya da segment dosyasını ana sahne (main.tscn) olmadan oynatır (CineHost).
##   Godot --path . res://scenes/dev/cine_preview.tscn -- --cine=res://data/cine/test_timeline.json
##   ek argümanlar: --cine-at=SN (sessizce ileri sarar), --cine-speed=K, --no-world (kamp dünyası kurulmaz),
##   --quit (bitince kapanır)
## "camp" dünyası isteyen segment için kamp dünyası (world.tscn) kurulur; kamera main.tscn'in menü kadrajındaki
## MenuCamera'dır. Sol üstte dizinin adı, saati ve segmenti yazar. Bitince R yeniden oynatır, Q kapatır;
## oynarken basılı Esc atlar. Geliştirme çalıştırmasıdır: kayıt ve ayar yazılmaz (GameSettings.is_dev_run).

const WORLD_SCENE := "res://scenes/world/world.tscn"

## Oynatılacak dizi ya da segment.
@export_file("*.json") var cine_path := "res://data/cine/test_timeline.json"
## Başlangıçta ileri sarılacak saniye ve sinemanın hızı.
@export var cine_at := 0.0
@export var speed := 1.0
## "camp" segmenti için kamp dünyası kurulsun mu (kurulmazsa segment dünyasız akar)?
@export var use_world := true
@export var autoplay := true
@export var quit_when_done := false

@onready var host: CineHost = $CineHost
@onready var camera: Camera3D = $MenuCamera
@onready var fade: ColorRect = $UI/Fade

var world: Node3D
## Kaç kez oynatıldı ve son oynatma atlandı mı?
var plays := 0
var last_skipped := false

var _status: Label


func _ready() -> void:
	_apply_args(OS.get_cmdline_user_args())
	host.main_node = self
	host.menu_camera = camera
	host.fade_rect = fade
	host.finished.connect(_on_finished)
	_status = UIKit.label("", 22, "Alegreya", 500, UIKit.TEXT_DIM)
	_status.name = "Status"
	_status.position = Vector2(24, 18)
	$UI.add_child(_status)
	if autoplay:
		play.call_deferred()


func _process(_delta: float) -> void:
	if _status == null:
		return
	var timeline := host.timeline()
	if timeline == null:
		_status.text = cine_path
		return
	var seg := timeline.segment_at(host.time())
	_status.text = "%s  %.1f / %.1f sn  %s%s" % [timeline.id, host.time(), timeline.total(), seg.get("id", ""),
		"" if host.is_playing() else "  (bitti: R yeniden, Q çık)"]


## Diziyi baştan (ya da cine_at'ten) oynatır. Döner: konağın finished sinyali.
func play() -> Signal:
	if host.is_playing():
		host.stop()
	if use_world and world == null and _needs_camp():
		world = (load(WORLD_SCENE) as PackedScene).instantiate() as Node3D
		add_child(world)
		move_child(world, 0)
	host.world = world
	host.speed = speed
	fade.color.a = 0.0
	plays += 1
	return host.play(cine_path, cine_at)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or host.is_playing():
		return
	match key.physical_keycode:
		KEY_R:
			play()
		KEY_Q, KEY_ESCAPE:
			get_tree().quit()


func _on_finished(skipped: bool) -> void:
	last_skipped = skipped
	print("[cine] %s bitti%s (%.2f sn)" % [cine_path, " (atlandı)" if skipped else "", host.time()])
	if quit_when_done:
		get_tree().quit()


func _needs_camp() -> bool:
	for seg in CineTimeline.from_path(cine_path).segments:
		if seg["world"] == CineTimeline.WORLD_CAMP:
			return true
	return false


func _apply_args(args: PackedStringArray) -> void:
	for arg in args:
		var value := arg.get_slice("=", 1).replace(",", ".") if arg.contains("=") else ""
		if arg.begins_with("--cine="):
			cine_path = arg.substr(7)
		elif arg.begins_with("--cine-at=") and value.is_valid_float():
			cine_at = maxf(value.to_float(), 0.0)
		elif arg.begins_with("--cine-speed=") and value.is_valid_float():
			speed = maxf(value.to_float(), 0.05)
		elif arg == "--no-world":
			use_world = false
		elif arg == "--quit":
			quit_when_done = true
