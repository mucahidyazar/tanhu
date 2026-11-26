extends Node
## Oyunun ayarları (autoload "GameSettings"): ses seviyeleri (ana ses, müzik, seslendirme, efektler, ortam),
## görüntü (pencere / tam ekran, çözünürlük, dikey eşitleme, boyalı görünüm), arayüz ölçeği (menüler, kitaplar ve HUD tek ayardan;
## K104), kamera ve ipuçları, Önsöz'ün oynanması (K36: ilk yeni oyunda ya da her yeni oyunda), dil.
##
## Kamera: dönüş hızı, fare hassasiyeti, takip, görüş açısı, eğim payı, oyunda eğim, ters yatay ve dikey, tekerlekle harita ([game];
## godot.md §5.6). Tuş ataması [input] bölümündedir: değiştirilen eylemlerin olay listesi (InputSetup.bindings), açılışta apply_input().
##
## user://settings.cfg dosyasında saklanır; oyun açılırken okunur ve uygulanır. Ayarlar sayfası
## değeri değiştirince apply() / apply_display() çağırır, sayfa kapanınca save_settings() yazar.
## Sahnedeki düğümlere bağlı ayarları (takip kamerası, boyalı efekt, ipuçları) ana akış uygular:
## "changed" sinyalini dinler ve apply_to_camera() / painterly / show_hints değerlerini kullanır.
##
## Geliştirme ve test çalıştırmaları (komut satırında "--" sonrası bir argüman varsa, başsız çalışıyorsa
## ya da ana döngü bir betikse: godot -s betik.gd; bkz. is_dev_run) oyuncunun ayarlarını değiştirmez:
## dosyaya yazmaz, pencereyi kendisi boyutlandırmaz, eski klasörden taşımaz.
## --settings-file=/mutlak/yol.cfg verilirse o dosya okunur ve yazılır (ekran görüntüsü denemeleri).
##
## user:// sabit bir klasördür (project.godot: use_custom_user_dir). Oyuncunun gerçek açılışında, ayar
## dosyası okunmadan önce eski app_userdata/Tanhu klasöründeki kayıtlar ve ayar bir kez kopyalanır
## (UserDirMigration, K30); autoload'lar ana sahneden önce kurulduğu için kayıtlar da menüden önce yerindedir.

signal changed

const PATH := "user://settings.cfg"
## "Ekranı kapla": pencere ekranın kullanılabilir alanını kaplar (büyütülmüş pencere; varsayılan).
const FILL := Vector2i.ZERO
## Sunulan pencere boyutları (gerçek piksel) ve yaygın adları.
const RESOLUTIONS: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160)]
const RESOLUTION_NAMES := {Vector2i(1280, 720): "HD", Vector2i(1600, 900): "HD+", Vector2i(1920, 1080): "Full HD", Vector2i(2560, 1440): "2K · QHD", Vector2i(3840, 2160): "4K · UHD"}
## Kamera takibinin yumuşaklığı → FollowCamera.follow_sharpness. «off» (Kapalı): kamera oyuncuyu Normal yumuşaklıkla izler ama atta atın arkasına
## kendiliğinden dönmez (FollowCamera.ride_follow; godot.md §5.7, act1.md §4: «Kamera takibi» açıksa yaw ata 1,1 sn'de döner).
const FOLLOW_MODES := {"off": 5.5, "soft": 3.5, "normal": 5.5, "tight": 9.0}
## Takip kamerasının dikey görüş açısı (derece) → FollowCamera.fov. "normal" kameranın kendi varsayılanıdır. Üçü de K98'in 30–40°'lik
## ailesindedir: Dar 32°, Normal 36°, Geniş 40° (k98-recalc; K39'un Geniş 42°'si ailenin dışındaydı).
const FOV_MODES := {"narrow": FollowCamera.DEFAULT_FOV - 4.0, "normal": FollowCamera.DEFAULT_FOV, "wide": FollowCamera.DEFAULT_FOV + 4.0}
## Ayarın eğim payının aralığı (derece; Ayarlar › Oyun › «Eğim payı» → FollowCamera.pitch_bias): varsayılan kare (38° + pay) K98'in
## 35–50°'lik ailesinde kalır (k98-recalc; K39'un −8..+20°'si 38°'lik tabanda 30–58° verirdi). Bant (15–60°) oyuncunun oturum eğimidir.
const PITCH_BIAS_MIN := -3.0
const PITCH_BIAS_MAX := 12.0
## Arayüz ölçeğinin aralığı ve adımı (Ayarlar › Görüntü › «Arayüz ölçeği», kaydırıcı; K104): %50–%150, beşer beşer. Menüler, kitaplar ve
## oyun içi HUD (GameplayHud) bu tek ayardan ölçeklenir; HUD arayüzün HudKit.HUD_SCALE (0,8) katında çizilir: ayar %100'de HUD, eski
## ayrı «HUD ölçeği»nin %80'indeki boyundadır.
const UI_SCALE_MIN := 0.5
const UI_SCALE_MAX := 1.5
const UI_SCALE_STEP := 0.05
const LANGUAGES: Array[String] = ["tr"]

## Ayar dosyasının yolu.
var path := PATH
## Değişiklikler diske yazılsın mı?
var persist := true
## Açılışta görüntü ayarları pencereye uygulansın mı?
var apply_window := true
## Açılışta eski klasördeki kayıtlar ve ayar yeni klasöre bir kez kopyalansın mı (UserDirMigration)?
var migrate_user_dir := true

var master_volume := 1.0
var music_volume := 1.0
## Seslendirme: Voice veri yolu (anlatıcı, ozanın şarkısı, söz; audio.md §1, godot.md §3.3).
var voice_volume := 1.0
var sfx_volume := 1.0
var ambience_volume := 1.0
var fullscreen := false
var resolution := FILL
var vsync := true
var painterly := true
## Oyuncunun arayüz ölçeği (UI_SCALE_MIN..MAX, UI_SCALE_STEP adımla; K104): menüler ui_k() ile, HUD ui_k() × HudKit.HUD_SCALE ile çizilir.
var ui_scale := 1.0
## Kameranın Q / E ile dönüş hızı (0..1 → 60..160 derece/sn).
var camera_speed := 0.5
## Sağ tıkla sürüklerken fare hassasiyeti (0..1 → 0,1..0,5 derece/piksel).
var mouse_sensitivity := 0.5
var camera_follow := "normal"
var camera_fov := "normal"
## Kameranın eğim payı (derece, PITCH_BIAS_MIN..MAX, birer derece): oyuncunun seçtiği varsayılan kare; `/` onu silmez (godot.md §5.6).
var camera_pitch_bias := 0.0
## Oyunda eğim: kapalıysa orta tuşla dikey sürükleme, Alt + tekerlek ve ; / ' eğmez (FollowCamera.tilt_enabled).
var camera_tilt := true
## Ters yatay ve ters dikey: fareyle sürüklemenin yönü (FollowCamera.invert_x / invert_y).
var camera_invert_x := false
var camera_invert_y := false
## Tekerlekle harita (K40): en uzak kadrajda tekerlek haritayı açar. Harita geçişi II. Perde'nin harita fazındadır; ayar şimdiden saklanır.
var camera_wheel_map := true
## Oyuncunun tuş ataması ([input] bölümü; InputSetup.bindings() biçiminde): {eylem: [olay sözlüğü, ...]}; yalnız değiştirilen eylemler.
## Açılışta apply_input() tuş haritasına yazar; Tuşlar sayfası değiştirince buraya yazar ve kaydeder.
var input_bindings: Dictionary = {}
## Serbest gezinti başlarken tuş ipuçları gösterilsin mi?
var show_hints := true
## Önsöz'ün içerik sürümü: büyük değişince artar, «görüldü» işareti eskir ve oyuncu yenisini bir kez daha görür (2: K96'nın yeni miti;
## 3: K110'un Göl Obası'nda oynanan üç günü, E21).
const PROLOGUE_VERSION := 3
## Önsöz bir kez oynadı mı (K36: ikinci oyunda varsayılan atlanır)? Kayıtta değil, ayarda durur; ilk oynatmada
## mark_prologue_seen() yazar. Geliştirme ve test koşuları dosyaya yazmaz (persist kapalı).
var prologue_seen := false
## Önsöz her yeni oyunda oynasın mı? Ayarlar'ın Oyun bölümündeki «Önsöz» satırı: açık «Her yeni oyunda» (varsayılan, K100: kullanıcı
## Yeni Oyun'da sinemayı görmek istedi), kapalı «İlk yeni oyunda». Atlamak her zaman basılı Esc'tir.
var prologue_always := true
## Çocukluk'un içerik sürümü: büyük değişince artar, «bitirdi» işareti eskir (oyuncu yeni Çocukluk'u bir kez daha görür, «geç» sunulmaz).
const CHILDHOOD_VERSION := 1
## Oyuncu Çocukluk'u bir kez sonuna dek oynadı mı (K100'ün dili: «Çocukluğu geç: Esc basılı tut» o zaman sunulur)? Kayıtta değil, ayarda
## durur; ilk bitişte mark_childhood_done() yazar. Geliştirme ve test koşuları dosyaya yazmaz (persist kapalı).
var childhood_done := false
var language := "tr"

## Son "changed" yayılırken arayüzün ölçeği (bkz. _on_window_resized).
var _last_ui_k := -1.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	var headless := DisplayServer.get_name() == "headless"
	var dev := is_dev_run(headless, args, get_tree().get_script() != null)
	var custom := _arg_value(args, "settings-file")
	if custom != "":
		path = custom
	persist = custom != "" or not dev
	apply_window = not dev
	migrate_user_dir = not dev
	if migrate_user_dir:
		# Oyuncunun gerçek açılışı: eski klasördeki kayıtlar ve ayar, ayar okunmadan önce bir kez kopyalanır.
		UserDirMigration.run_for_player()
	if custom != "" or not headless:
		if load_settings():
			apply_input()
	apply()
	if apply_window:
		# Pencere kipi kök düğüm çocuklarını eklerken değiştirilmez: macOS'ta tam ekrana geçiş o anda pencereyi yeniden
		# düzenler, Godot "üst düğüm meşgul" hatası verir ve açılış donabilir. Kurulum bitince (bir sonraki adımda) uygulanır.
		apply_display.call_deferred()
	get_tree().root.size_changed.connect(_on_window_resized)


# --- Kalıcılık -------------------------------------------------------------------

## Ayarları dosyadan okur; dosya yoksa ya da bozuksa değerler olduğu gibi kalır (false döner).
func load_settings() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return false
	master_volume = _unit(cfg.get_value("audio", "master", master_volume), master_volume)
	music_volume = _unit(cfg.get_value("audio", "music", music_volume), music_volume)
	voice_volume = _unit(cfg.get_value("audio", "voice", voice_volume), voice_volume)
	sfx_volume = _unit(cfg.get_value("audio", "sfx", sfx_volume), sfx_volume)
	ambience_volume = _unit(cfg.get_value("audio", "ambience", ambience_volume), ambience_volume)
	fullscreen = bool(cfg.get_value("display", "fullscreen", fullscreen))
	resolution = parse_resolution(str(cfg.get_value("display", "window_px", "")), resolution)
	vsync = bool(cfg.get_value("display", "vsync", vsync))
	painterly = bool(cfg.get_value("display", "painterly", painterly))
	# Arayüz ölçeği (K104): eski dosyanın «ui_scale»i (%80, %90, %100) aynen geçer, menüler ve kitaplar oyuncunun seçtiği boyda kalır.
	# Eski «hud_scale» okunmaz, bir sonraki kayıtta dosyadan düşer: tek ayarda HUD arayüzün 0,8 katıdır (eski %100 + HUD %80 yeni
	# %100'dür; eski varsayılanlar, %100 + %100, yeni varsayılana düşer). Eski HUD boyunu korumak arayüz ölçeğini HUD'a göre kaydırmak
	# olurdu (%100 + %130 → %162: menüler oyuncunun seçmediği boya büyürdü); HUD'u ayrı büyütmek isteyen kaydırıcıyı yükseltir.
	var ui_v: Variant = cfg.get_value("display", "ui_scale", ui_scale)
	ui_scale = snap_ui_scale(float(ui_v)) if (ui_v is float or ui_v is int) else ui_scale
	camera_speed = _unit(cfg.get_value("game", "camera_speed", camera_speed), camera_speed)
	mouse_sensitivity = _unit(cfg.get_value("game", "mouse_sensitivity", mouse_sensitivity), mouse_sensitivity)
	camera_follow = _pick(str(cfg.get_value("game", "camera_follow", camera_follow)), FOLLOW_MODES.keys(), "normal")
	camera_fov = _pick(str(cfg.get_value("game", "camera_fov", camera_fov)), FOV_MODES.keys(), "normal")
	var bias_v: Variant = cfg.get_value("game", "camera_pitch_bias", camera_pitch_bias)
	camera_pitch_bias = snap_pitch_bias(float(bias_v)) if (bias_v is float or bias_v is int) else camera_pitch_bias
	camera_tilt = _flag(cfg.get_value("game", "camera_tilt", camera_tilt), camera_tilt)
	camera_invert_x = _flag(cfg.get_value("game", "camera_invert_x", camera_invert_x), camera_invert_x)
	camera_invert_y = _flag(cfg.get_value("game", "camera_invert_y", camera_invert_y), camera_invert_y)
	camera_wheel_map = _flag(cfg.get_value("game", "camera_wheel_map", camera_wheel_map), camera_wheel_map)
	# Tuş ataması: bilinmeyen eylem ya da bozuk satır sessizce atlanır (InputSetup.sanitize_bindings).
	var bindings := {}
	if cfg.has_section("input"):
		for key in cfg.get_section_keys("input"):
			bindings[key] = cfg.get_value("input", key)
	input_bindings = InputSetup.sanitize_bindings(bindings)
	show_hints = bool(cfg.get_value("game", "show_hints", show_hints))
	# Sürüm yazmayan eski dosya 1 sayılır: yeni Önsöz bir kez daha oynar.
	prologue_seen = _flag(cfg.get_value("game", "prologue_seen", prologue_seen), prologue_seen) and int(cfg.get_value("game", "prologue_version", 1)) >= PROLOGUE_VERSION
	# K100: Önsöz varsayılan olarak her yeni oyunda oynar. Eski dosyaların «prologue_always»ı o günkü varsayılanı (kapalı) taşır,
	# oyuncunun seçimi değildir: okunmaz. Seçim yeni anahtarda («prologue_every») durur.
	prologue_always = _flag(cfg.get_value("game", "prologue_every", prologue_always), prologue_always)
	childhood_done = _flag(cfg.get_value("game", "childhood_done", childhood_done), childhood_done) and int(cfg.get_value("game", "childhood_version", 1)) >= CHILDHOOD_VERSION
	language = _pick(str(cfg.get_value("general", "language", language)), LANGUAGES, "tr")
	return true


## Ayarları dosyaya yazar (persist kapalıysa yazmaz ve false döner).
func save_settings() -> bool:
	if not persist:
		return false
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "voice", voice_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("audio", "ambience", ambience_volume)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("display", "window_px", "%dx%d" % [resolution.x, resolution.y])
	cfg.set_value("display", "vsync", vsync)
	cfg.set_value("display", "painterly", painterly)
	cfg.set_value("display", "ui_scale", ui_scale)
	cfg.set_value("game", "camera_speed", camera_speed)
	cfg.set_value("game", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("game", "camera_follow", camera_follow)
	cfg.set_value("game", "camera_fov", camera_fov)
	cfg.set_value("game", "camera_pitch_bias", camera_pitch_bias)
	cfg.set_value("game", "camera_tilt", camera_tilt)
	cfg.set_value("game", "camera_invert_x", camera_invert_x)
	cfg.set_value("game", "camera_invert_y", camera_invert_y)
	cfg.set_value("game", "camera_wheel_map", camera_wheel_map)
	for action in input_bindings:
		cfg.set_value("input", str(action), input_bindings[action])
	cfg.set_value("game", "show_hints", show_hints)
	cfg.set_value("game", "prologue_seen", prologue_seen)
	cfg.set_value("game", "prologue_version", PROLOGUE_VERSION)
	cfg.set_value("game", "prologue_every", prologue_always)
	cfg.set_value("game", "childhood_done", childhood_done)
	cfg.set_value("game", "childhood_version", CHILDHOOD_VERSION)
	cfg.set_value("general", "language", language)
	return cfg.save(path) == OK


## Bütün değerleri varsayılana döndürür (dosyaya dokunmaz).
func reset_to_defaults() -> void:
	master_volume = 1.0
	music_volume = 1.0
	voice_volume = 1.0
	sfx_volume = 1.0
	ambience_volume = 1.0
	fullscreen = false
	resolution = FILL
	vsync = true
	painterly = true
	ui_scale = 1.0
	camera_speed = 0.5
	mouse_sensitivity = 0.5
	camera_follow = "normal"
	camera_fov = "normal"
	camera_pitch_bias = 0.0
	camera_tilt = true
	camera_invert_x = false
	camera_invert_y = false
	camera_wheel_map = true
	input_bindings = {}
	show_hints = true
	prologue_always = true
	language = "tr"


# --- Önsöz (K36) ------------------------------------------------------------------

## Yeni Oyun'da Önsöz oynasın mı? İlk yeni oyunda evet; sonra yalnız «Her yeni oyunda» seçiliyse.
func should_play_prologue() -> bool:
	return prologue_always or not prologue_seen


## Önsöz'ün oynadığını yazar (ilk oynatmada çağrılır). Yalnız persist açıkken diske gider: geliştirme ve test
## koşuları oyuncunun ayarına yazmaz. Diske yazıldıysa true.
func mark_prologue_seen() -> bool:
	prologue_seen = true
	return save_settings()


## Çocukluk'un bittiğini yazar (ilk bitişte çağrılır; sonraki Yeni Oyun'larda «Çocukluğu geç» sunulur). Yalnız persist açıkken diske gider.
func mark_childhood_done() -> bool:
	childhood_done = true
	return save_settings()


# --- Uygulama -----------------------------------------------------------------------

## Ses seviyelerini veri yollarına uygular ve "changed" yayar (sahne ayarları için).
func apply() -> void:
	_set_bus(&"Master", master_volume)
	_set_bus(&"Music", music_volume)
	_set_bus(&"Voice", voice_volume)
	_set_bus(&"SFX", sfx_volume)
	_set_bus(&"Ambience", ambience_volume)
	_emit_changed()


## Pencere / tam ekran, pencere boyutu ve dikey eşitleme. Başsız, web ve mobilde bir şey yapmaz.
func apply_display() -> void:
	if not _has_window():
		return
	var mode := DisplayServer.window_get_mode()
	var is_full := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	if fullscreen:
		if not is_full:
			# Tam (exclusive) ekran: macOS'ta Dock ve menü çubuğu kenarlarda gizli kalır.
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		return
	if resolution == FILL:
		if mode != DisplayServer.WINDOW_MODE_MAXIMIZED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
		return
	if mode != DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_resize_after_transition()
	_size_window()


## F11: tam ekran ↔ pencere (seçim kaydedilir).
func toggle_fullscreen() -> void:
	fullscreen = not fullscreen
	apply_display()
	save_settings()
	_emit_changed()


func _unhandled_input(event: InputEvent) -> void:
	if InputMap.has_action(&"toggle_fullscreen") and event.is_action_pressed(&"toggle_fullscreen"):
		toggle_fullscreen()
		get_viewport().set_input_as_handled()


## Pencerenin piksel boyu değişince (tam ekrana geçiş bitince, pencere büyütülünce) arayüzün ölçeği de değişir.
## En-boy oranı aynı kalırsa (1080p pencereden 1440p tam ekrana) Control'lerin resized sinyali gelmez; menüler
## kendini yeniden ölçeklesin diye "changed" yeniden yayılır (ölçek gerçekten değiştiyse).
func _on_window_resized() -> void:
	if not is_equal_approx(ui_k(), _last_ui_k):
		_emit_changed()


func _emit_changed() -> void:
	_last_ui_k = ui_k()
	changed.emit()


# --- Sahne ayarları (ana akış kullanır) -----------------------------------------------

## Kamera ayarlarını bir takip kamerasına (FollowCamera) yalnızca açık özellikleri üzerinden uygular.
func apply_to_camera(camera: Node) -> void:
	if camera == null:
		return
	var values := {
		&"rotate_speed_deg": rotate_speed_for(camera_speed),
		&"mouse_sensitivity": mouse_sensitivity_for(mouse_sensitivity),
		&"follow_sharpness": float(FOLLOW_MODES.get(camera_follow, 5.5)),
		&"ride_follow": camera_follow != "off",
		&"fov": float(FOV_MODES.get(camera_fov, FollowCamera.DEFAULT_FOV)),
		&"pitch_bias": snap_pitch_bias(camera_pitch_bias),
		&"tilt_enabled": camera_tilt,
		&"invert_x": camera_invert_x,
		&"invert_y": camera_invert_y,
	}
	for key in values:
		if key in camera:
			camera.set(key, values[key])


## Oyuncunun tuş atamasını (input_bindings) tuş haritasına yazar (açılışta); geçersiz satırlar atlanır, temizlenmiş hâli geri yazılır.
## Atamada olmayan eylemlere dokunulmaz (bütün atamayı silmek InputSetup.reset_bindings()'tir).
func apply_input() -> void:
	input_bindings = InputSetup.apply_bindings(input_bindings)


## Arayüzün çizildiği ölçek: oyuncunun ölçeği × pencerenin piksel yüksekliğinin payı (bkz. res_ui_factor).
func ui_k() -> float:
	return ui_scale * res_ui_factor(window_pixels())


## Sinemanın üstündeki yazının ölçeği (altyazı, tarih kartı, atlama halkası): yazı resmin parçasıdır, pencereyle birlikte büyür.
## Yüksek çözünürlükte menüler gibi küçülmez (res_ui_factor), yalnız oyuncunun ölçeği uygulanır: Retina'da yarı boyda kalıyordu.
func film_k() -> float:
	return ui_scale


## Oyunun çizildiği pencerenin gerçek piksel boyutu (tam ekranda ekranın kendisi; pencere yoksa 1920×1080).
## Seçilen çözünürlük değil bu sayılır: macOS tam ekranda ekranın kendi çözünürlüğünü kullanır.
func window_pixels() -> Vector2i:
	if not _has_window():
		return Vector2i(1920, 1080)
	return DisplayServer.window_get_size()


## Sunulan boyutlar ve her birinin bu ekrana pencere olarak sığıp sığmadığı ("Ekranı kapla" ilk sırada).
func resolutions() -> Array:
	var out: Array = [{"size": FILL, "fits": true, "name": "Ekranı kapla"}]
	for r: Vector2i in RESOLUTIONS:
		out.append({"size": r, "fits": _fits(r), "name": RESOLUTION_NAMES.get(r, "")})
	return out


## Ekranın kendi çözünürlüğü (tam ekran bunu kullanır).
func screen_pixels() -> Vector2i:
	if not _has_window():
		return Vector2i(1920, 1080)
	return DisplayServer.screen_get_size()


# --- Saf yardımcılar (birim testli) -----------------------------------------------------

## Arayüz 1080 satıra göre çizilir ve pencereyle birlikte büyür (canvas_items). Ekran daha yüksekse (2K, 4K,
## Retina) menüler ve logo piksel boyunu korusun, ekranın daha azını kaplasın diye bu pay kadar küçültülür:
## 1440 satırda dörtte üç, 2160'ta yarı; 1080 ve altında 1 (en az 0,4).
static func res_ui_factor(res: Vector2i) -> float:
	if res.y <= 0:
		return 1.0
	return clampf(1080.0 / float(res.y), 0.4, 1.0)


## Eğim payını sunulan aralığa (PITCH_BIAS_MIN..MAX) ve tam dereceye çeker.
static func snap_pitch_bias(v: float) -> float:
	return clampf(roundf(v), PITCH_BIAS_MIN, PITCH_BIAS_MAX)


static func rotate_speed_for(v: float) -> float:
	return lerpf(60.0, 160.0, clampf(v, 0.0, 1.0))


static func mouse_sensitivity_for(v: float) -> float:
	return lerpf(0.1, 0.5, clampf(v, 0.0, 1.0))


## Arayüz ölçeğini sunulan aralığa (%50–%150) ve beşer yüzdelik adıma çeker (0,86 → 0,85; 2 → 1,5); sayı değilse (NaN) %100.
## Adım tam sayıyla bölünür ki değer temiz yazılsın (0,85; 17 × 0,05 = 0,8500000000000001 değil).
static func snap_ui_scale(v: float) -> float:
	if is_nan(v):
		return 1.0
	var per_unit := roundf(1.0 / UI_SCALE_STEP)
	return clampf(roundf(v * per_unit) / per_unit, UI_SCALE_MIN, UI_SCALE_MAX)


## "1920x1080" → Vector2i; "0x0" → FILL; bozuksa fallback.
static func parse_resolution(text: String, fallback: Vector2i) -> Vector2i:
	var parts := text.split("x")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return fallback
	var r := Vector2i(int(parts[0]), int(parts[1]))
	if r == FILL:
		return FILL
	return r if r in RESOLUTIONS else fallback


## Ses seviyesi (0..1) → desibel; 0 sessizdir.
static func volume_db(linear: float) -> float:
	return linear_to_db(maxf(linear, 0.0001))


## Geliştirme ya da test çalıştırması mı? Başsız çalışma, "--" sonrası bir argüman (ekran görüntüsü, ölçüm) ya da
## betikle kurulan ana döngü (godot -s betik.gd: test koşucusu, ölçüm ve deneme betikleri; SceneTree'ye betik
## bağlıdır, "--" argümanı olmasa da) geliştirme sayılır. Oyuncunun açılışında (editörden F5 dahil) üçü de yoktur.
## 2026-11-05: "--" argümansız, pencereli bir -s deneme betiği oyuncu açılışı sayıldı ve taşımayı oyuncunun
## klasöründe çalıştırdı; betik ana döngüsü bu yüzden ayrıca sayılır.
static func is_dev_run(headless: bool, user_args: PackedStringArray, script_main_loop: bool) -> bool:
	return headless or not user_args.is_empty() or script_main_loop


# --- İç işler ------------------------------------------------------------------------------

func _set_bus(bus_name: StringName, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, volume_db(linear))
	AudioServer.set_bus_mute(idx, linear <= 0.001)


func _has_window() -> bool:
	return DisplayServer.get_name() != "headless" and not OS.has_feature("web") and not OS.has_feature("mobile")


func _window_px() -> Vector2i:
	var usable := DisplayServer.screen_get_usable_rect()
	return Vector2i(mini(resolution.x, usable.size.x), mini(resolution.y, usable.size.y))


func _size_window() -> void:
	var usable := DisplayServer.screen_get_usable_rect()
	var px := _window_px()
	DisplayServer.window_set_size(px)
	DisplayServer.window_set_position(usable.position + (usable.size - px) / 2)


## macOS'ta tam ekrandan çıkış animasyonludur; o sırada verilen boyut kaybolur, pencere ekran kadar
## büyük döner. Animasyon bitince boyut yeniden verilir.
func _resize_after_transition() -> void:
	for wait in [0.8, 1.6]:
		await get_tree().create_timer(wait, true, false, true).timeout
		if fullscreen or resolution == FILL:
			return
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED and DisplayServer.window_get_size() != _window_px():
			_size_window()


func _fits(r: Vector2i) -> bool:
	if not _has_window():
		return true
	var room := DisplayServer.screen_get_size() if fullscreen else DisplayServer.screen_get_usable_rect().size
	return r.x <= room.x and r.y <= room.y


static func _unit(v: Variant, fallback: float) -> float:
	return clampf(float(v), 0.0, 1.0) if (v is float or v is int) else fallback


## Açık / kapalı değer: yalnız bool okunur, başka tür (yazı, sayı) yok sayılır.
static func _flag(v: Variant, fallback: bool) -> bool:
	return v if v is bool else fallback


static func _pick(v: String, allowed: Array, fallback: String) -> String:
	return v if v in allowed else fallback


static func _arg_value(args: PackedStringArray, key: String) -> String:
	for a in args:
		if a.begins_with("--" + key + "="):
			return a.substr(key.length() + 3)
	return ""
