extends Node
## Geliştirme aracı: komut satırından sahnenin ekran görüntüsünü alır ve oyunu kapatır.
##
## Kullanım (Godot komutunda "--" sonrasına yazılır):
##   --capture=/tam/yol/goruntu.png   Görüntünün kaydedileceği yer (zorunlu)
##   --frames=150                     Kaç kare bekleneceği (varsayılan 150)
##   --pose=x,y,z,yaw,pitch           Kamerayı bu konuma/açıya koy (derece)
##   --fov=32.5                       Kameranın görüş açısını değiştir (derece)
##   --window=3200x1800               Pencereyi bu piksel boyutuna getir (ör. 16:9 karşılaştırma için)
##   --hide-ui                        Menüyü gizle
##   --freeze-time[=12]               Kararlı kare (godot.md §8.5): gölgelendiricilerin zamanı (world_time genel
##                                    tekdüzeni) bu saniyede donar (değer verilmezse 10 sn). Menü kamerası salınmaz ve
##                                    fareye bakmaz, parçacık sistemleri görüntüden 30 kare önce sabit tohumlu yeni
##                                    kopyalarıyla değişir, pencere girdi almaz (fare bir butonu ısıtmaz).
##                                    tools/capture.sh bununla Godot'ya --fixed-fps 60 da verir (her
##                                    kare 1/60 sn: canlandırma, ateş ışığı ve geçişler kare sayısına bağlanır) ve
##                                    oyuncunun kayıt ve ayar dosyaları yerine boş bir geçici klasör açar. Aynı
##                                    argümanlarla iki koşu aynı kareyi verir; tools/image_diff.py karşılaştırır.
## Örnek:
##   Godot --path . -- --capture=/tmp/menu.png --frames=180
##
## Kendi akışını yöneten sahne (ör. scenes/dev/budget_probe.tscn) görüntüyü hold_capture() ile bekletir ve işi
## bitince release_capture() çağırır: kare sayacı dolmuş olsa bile görüntü o zaman alınır, sonra oyun kapanır.

signal pose_requested(position: Vector3, yaw_deg: float, pitch_deg: float)
signal hide_ui_requested
signal fov_requested(fov_deg: float)

## Gölgelendiricilerin okuduğu genel tekdüzen (project.godot [shader_globals]; shaders/include/world_time.gdshaderinc).
## Eksi değer "zaman akıyor" demektir: gölgelendirici motorun TIME'ını kullanır.
const WORLD_TIME := &"world_time"
## --freeze-time değersiz (ya da okunamayan bir değerle) verilirse zamanın donduğu an (saniye).
const DEFAULT_FREEZE_TIME := 10.0
## Kararlı karede parçacık sistemlerinin ortak tohumu.
const FREEZE_SEED := 1
## Kararlı kare için motorun sabit kare hızı (tools/capture.sh Godot'ya --fixed-fps ile verir).
const FREEZE_FPS := 60
## Kararlı karede her parçacık sistemi görüntüden bu kadar kare önce yepyeni bir kopyasıyla değiştirilir (sabit tohum,
## ön benzetimle tam dolu). Erken başlayan sistemin çizim sunucusundaki durumu (adım payı, döngü sayacı) yeniden
## başlatmayla da gizlemekle de sıfırlanmaz ve ne zaman başladığı gerçek zamanda süren gölgelendirici derlemesine
## bağlıdır (denendi: kor ve ateş böcekleri koşudan koşuya %0,02–0,05 değişti); yeni kopya her koşuda aynı karede,
## aynı durumdan başlar.
const PARTICLE_RESTART_FRAMES := 30

var _path := ""
var _frames := 150
## Dondurulan an (saniye); eksi = zaman akıyor.
var _freeze := -1.0
## Görüntüyü bekleten istek sayısı (hold_capture / release_capture).
var _holds := 0


## "--anahtar=değer" biçimindeki argümanları sözlüğe çevirir (test edilebilir saf fonksiyon).
static func parse_args(args: PackedStringArray) -> Dictionary:
	var result := {}
	for arg in args:
		if not arg.begins_with("--"):
			continue
		var body := arg.substr(2)
		var eq := body.find("=")
		if eq == -1:
			result[body] = true
		else:
			result[body.substr(0, eq)] = body.substr(eq + 1)
	return result


## --freeze-time'ın değeri (saf fonksiyon): argüman yoksa -1 (zaman akar). Değersiz ya da sayı olmayan değer
## DEFAULT_FREEZE_TIME'dır; ondalık virgül de okunur ("12,5"); eksi değer 0'a çekilir (world_time'ın eksisi
## "akan zaman" demektir, dondurma isteği kaybolmasın).
static func freeze_time_from(args: Dictionary) -> float:
	if not args.has("freeze-time"):
		return -1.0
	var text := str(args["freeze-time"]).strip_edges().replace(",", ".")
	if not text.is_valid_float():
		return DEFAULT_FREEZE_TIME
	return maxf(text.to_float(), 0.0)


func _ready() -> void:
	var args := parse_args(OS.get_cmdline_user_args())
	if not args.has("capture"):
		queue_free()
		return
	_path = str(args["capture"])
	_frames = int(args.get("frames", 150))
	if args.has("window"):
		var size := str(args["window"]).split("x")
		if size.size() == 2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(Vector2i(int(size[0]), int(size[1])))
	_freeze = freeze_time_from(args)
	if _freeze >= 0.0:
		_freeze_world()
	_emit_requests_later(args)
	_capture_after_delay()


## Görüntüyü bekletir: kendi akışını yöneten sahne (ör. bütçe ölçümü) işini bitirene dek görüntü alınmaz.
func hold_capture() -> void:
	_holds += 1


## hold_capture()'ı bırakır. Son istek bırakılınca görüntü alınır (kare sayacı dolmuşsa hemen) ve oyun kapanır.
func release_capture() -> void:
	_holds = maxi(_holds - 1, 0)


## Görüntü bekletiliyor mu?
func is_capture_held() -> bool:
	return _holds > 0


## Kararlı karenin başlangıcı: zaman donar, parçacıklar sabit tohuma bağlanır, pencere girdi almaz.
## Ana sahne bu autoload'dan sonra kurulur: parçacıklar sahneye girerken (node_added) yakalanır.
func _freeze_world() -> void:
	RenderingServer.global_shader_parameter_set(WORLD_TIME, _freeze)
	get_viewport().gui_disable_input = true
	get_tree().node_added.connect(_on_node_added)
	print("[capture] dondurulmuş zaman: world_time=%.2f sn" % _freeze)


func _on_node_added(node: Node) -> void:
	_fix_particles(node)


## Parçacık sistemini sabit tohuma bağlar (Godot 4.4+: use_fixed_seed). Sistemin kendi sabit adımı (fixed_fps,
## ör. 30) kapatılır: her kare motorun sabit adımıyla (--fixed-fps 60) ilerler, adımdan artan pay kalmaz.
static func _fix_particles(node: Node) -> void:
	if node is GPUParticles3D:
		var p3 := node as GPUParticles3D
		p3.use_fixed_seed = true
		p3.seed = FREEZE_SEED
		p3.fixed_fps = 0
	elif node is GPUParticles2D:
		var p2 := node as GPUParticles2D
		p2.use_fixed_seed = true
		p2.seed = FREEZE_SEED
		p2.fixed_fps = 0


## Sahnedeki her parçacık sistemini aynı yerde, aynı adla yepyeni bir kopyasıyla değiştirir (bkz.
## PARTICLE_RESTART_FRAMES); kopya sahneye girerken node_added onu sabit tohuma bağlar.
func _restart_particles() -> void:
	var systems: Array[Node] = []
	systems.append_array(get_tree().root.find_children("*", "GPUParticles3D", true, false))
	systems.append_array(get_tree().root.find_children("*", "GPUParticles2D", true, false))
	for node in systems:
		var parent := node.get_parent()
		if parent == null:
			continue
		var fresh := node.duplicate()
		var index := node.get_index()
		var node_name := node.name
		parent.remove_child(node)
		node.queue_free()
		fresh.name = node_name
		parent.add_child(fresh)
		parent.move_child(fresh, index)


## Kamera/arayüz isteklerini sahne hazır olduktan sonra (2 kare sonra) yayar: ana sahne bu sinyallere
## kendi _ready'sinde bağlanır; autoload'ın _ready'si ondan önce çalıştığı için hemen yayılan sinyal kaçabilir.
func _emit_requests_later(args: Dictionary) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if _freeze >= 0.0:
		_still_menu_cameras()
	if args.has("pose"):
		var p := str(args["pose"]).split(",")
		if p.size() >= 5:
			pose_requested.emit(Vector3(float(p[0]), float(p[1]), float(p[2])), float(p[3]), float(p[4]))
	if args.has("fov"):
		fov_requested.emit(float(args["fov"]))
	if args.has("hide-ui"):
		hide_ui_requested.emit()


## Kararlı karede menü kamerası salınmaz ve fareye bakmaz: kadraj tam menu_transform'dur (farenin yerine bağlı kalmaz).
## Kare adımı da yazılır: tools/capture.sh --freeze-time ile 1/60 sn olmalıdır.
func _still_menu_cameras() -> void:
	for node in get_tree().root.find_children("*", "MenuCamera", true, false):
		var camera := node as MenuCamera
		camera.drift_amount = 0.0
		camera.parallax_degrees = 0.0
	var step := get_process_delta_time()
	if absf(step - 1.0 / FREEZE_FPS) > 0.0001:
		print("[capture] UYARI: kare adımı sabit değil (%.4f sn); kararlı kare için Godot'ya --fixed-fps %d verin (tools/capture.sh --freeze-time ile verir)" % [step, FREEZE_FPS])


func _capture_after_delay() -> void:
	var restart_at := maxi(_frames - PARTICLE_RESTART_FRAMES, 0)
	for i in _frames:
		if _freeze >= 0.0 and i == restart_at:
			_restart_particles()
		await get_tree().process_frame
	# Bekleten sahne varsa o bırakana dek beklenir; istek çizimden hemen önce gelmiş olabilir: çizimden sonra yeniden bakılır.
	while true:
		while _holds > 0:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		if _holds == 0:
			break
	var image := get_viewport().get_texture().get_image()
	var err := image.save_png(_path)
	print("[capture] ", _path, " ", image.get_size(), " hata=", err, " fps=", Engine.get_frames_per_second())
	get_tree().quit()
