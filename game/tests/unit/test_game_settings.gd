extends TestCase
## Ayarlar testleri: GameSettings'in kaydedilip yeniden okunması (settings.cfg), bozuk / eksik dosya,
## değerlerin sınırlanması, ses seviyelerinin veri yollarına uygulanması (Seslendirme → Voice; audio.md §1),
## Önsöz'ün ilk yeni oyunda ya da her yeni oyunda oynaması (K36; prologue_seen testte yazılmaz), kamera ayarlarının takip
## kamerasına yalnızca açık özellikleri üzerinden uygulanması, tek arayüz ölçeği (K104: %50–%150, eski ui_scale ve hud_scale'in
## göçü); ve Ayarlar sayfasının
## (SettingsPanel, Tanhu 1'in dört bölümü) gerçekten değer değiştirip kapanınca kaydetmesi.
## Her test kendi GameSettings örneğini geçici bir dosyayla kullanır: oyuncunun ayarlarına dokunulmaz.
## Kayıt klasörünün taşınması (K30): testlerde autoload eski klasörden taşımaz, betikle kurulan ana döngü
## (godot -s, "--" argümansız da) geliştirme sayılır (is_dev_run); GameSettings'in yazdığı
## settings.cfg taşımada bu oyunun sayılır, Tanhu 2D ve Tanhu 2'ninki sayılmaz (taşımanın kendisi
## test_save_system.gd'dedir).

const SettingsScript := preload("res://scripts/settings/game_settings.gd")
const TempDir := preload("res://tests/support/temp_dir.gd")
const BUSES: Array[StringName] = [&"Master", &"Music", &"SFX", &"Ambience", &"Voice"]

var dir := ""
var settings: Node
var _bus_volumes := {}


func before_each() -> void:
	MenuStyle.muted = true
	dir = TempDir.fresh("ayarlar")
	settings = _new_settings()
	for bus in BUSES:
		var idx := AudioServer.get_bus_index(bus)
		if idx != -1:
			_bus_volumes[bus] = [AudioServer.get_bus_volume_db(idx), AudioServer.is_bus_mute(idx)]


func after_each() -> void:
	if is_instance_valid(settings):
		settings.free()
	for bus in _bus_volumes:
		var idx := AudioServer.get_bus_index(bus)
		AudioServer.set_bus_volume_db(idx, _bus_volumes[bus][0])
		AudioServer.set_bus_mute(idx, _bus_volumes[bus][1])
	TempDir.wipe(dir)


## Sahneye eklenmemiş (yani _ready'si çalışmayan) bir ayar örneği; dosyası geçici klasörde.
func _new_settings() -> Node:
	var s: Node = SettingsScript.new()
	s.path = dir.path_join("settings.cfg")
	s.persist = true
	s.apply_window = false
	return s


func test_defaults() -> void:
	assert_almost(settings.master_volume, 1.0)
	assert_almost(settings.music_volume, 1.0)
	assert_almost(settings.voice_volume, 1.0, 0.0001, "Seslendirme varsayılanı 1 (audio.md §1)")
	assert_false(settings.prologue_seen, "Önsöz henüz oynamadı")
	assert_true(settings.prologue_always, "Önsöz varsayılan: her yeni oyunda (K100)")
	assert_true(settings.should_play_prologue(), "ilk yeni oyunda Önsöz oynar")
	assert_false(settings.fullscreen, "Varsayılan pencere")
	assert_eq(settings.resolution, SettingsScript.FILL, "Varsayılan pencere ekranı kaplar (büyütülmüş)")
	assert_true(settings.vsync and settings.painterly and settings.show_hints)
	assert_almost(settings.ui_scale, 1.0)
	assert_false("hud_scale" in settings, "HUD ölçeği ayrı ayar değil (K104)")
	assert_eq(settings.camera_follow, "normal")
	assert_eq(settings.language, "tr", "Tanhu yalnızca Türkçedir")


func test_save_and_load_round_trip() -> void:
	settings.master_volume = 0.4
	settings.music_volume = 0.25
	settings.voice_volume = 0.45
	settings.sfx_volume = 0.6
	settings.ambience_volume = 0.0
	settings.prologue_seen = true
	settings.prologue_always = true
	settings.fullscreen = true
	settings.resolution = Vector2i(2560, 1440)
	settings.vsync = false
	settings.painterly = false
	settings.ui_scale = 1.35
	settings.camera_speed = 0.8
	settings.mouse_sensitivity = 0.2
	settings.camera_follow = "tight"
	settings.camera_fov = "wide"
	settings.show_hints = false
	assert_true(settings.save_settings(), "Ayarlar yazılmalı")
	assert_true(FileAccess.file_exists(settings.path), "settings.cfg oluşmalı")
	var other := _new_settings()
	assert_true(other.load_settings(), "Yazılan dosya okunmalı")
	assert_almost(other.master_volume, 0.4)
	assert_almost(other.music_volume, 0.25)
	assert_almost(other.voice_volume, 0.45, 0.0001, "Seslendirme [audio] voice olarak yazılır")
	assert_true(other.prologue_seen, "[game] prologue_seen")
	assert_true(other.prologue_always, "[game] prologue_always")
	assert_almost(other.sfx_volume, 0.6)
	assert_almost(other.ambience_volume, 0.0)
	assert_true(other.fullscreen)
	assert_eq(other.resolution, Vector2i(2560, 1440))
	assert_false(other.vsync)
	assert_false(other.painterly)
	assert_almost(other.ui_scale, 1.35, 0.0001, "Kaydırıcının %135'i kalıcı")
	var cfg := ConfigFile.new()
	cfg.load(settings.path)
	assert_false(cfg.has_section_key("display", "hud_scale"), "hud_scale yazılmaz (K104)")
	assert_almost(other.camera_speed, 0.8)
	assert_almost(other.mouse_sensitivity, 0.2)
	assert_eq(other.camera_follow, "tight")
	assert_eq(other.camera_fov, "wide")
	assert_false(other.show_hints)
	other.free()


func test_missing_and_corrupt_files_keep_values() -> void:
	settings.music_volume = 0.33
	assert_false(settings.load_settings(), "Dosya yoksa false")
	assert_almost(settings.music_volume, 0.33, 0.0001, "Dosya yoksa değerler değişmemeli")
	var f := FileAccess.open(settings.path, FileAccess.WRITE)
	f.store_string("[audio\nmusic=")
	f.close()
	expect_errors(["ConfigFile parse error"])   # bozuk dosyayı motor konsola yazar; beklenen hata
	assert_false(settings.load_settings(), "Bozuk dosya okunmamalı")
	assert_almost(settings.music_volume, 0.33, 0.0001)


func test_loaded_values_are_clamped_and_validated() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", 7.5)
	cfg.set_value("audio", "sfx", -2.0)
	cfg.set_value("audio", "master", "yüksek")
	cfg.set_value("audio", "voice", 3.0)
	cfg.set_value("game", "prologue_every", "evet")
	cfg.set_value("display", "ui_scale", 0.86)
	cfg.set_value("display", "window_px", "1234x567")
	cfg.set_value("game", "camera_follow", "uçan")
	cfg.set_value("general", "language", "en")
	cfg.save(settings.path)
	assert_true(settings.load_settings())
	assert_almost(settings.music_volume, 1.0, 0.0001, "Ses en fazla 1")
	assert_almost(settings.sfx_volume, 0.0, 0.0001, "Ses en az 0")
	assert_almost(settings.master_volume, 1.0, 0.0001, "Sayı olmayan değer yok sayılmalı")
	assert_almost(settings.voice_volume, 1.0, 0.0001, "Seslendirme en fazla 1")
	assert_true(settings.prologue_always, "açık / kapalı değerde yazı yok sayılır, varsayılan kalır")
	assert_almost(settings.ui_scale, 0.85, 0.0001, "Arayüz ölçeği beşer yüzdelik adıma yuvarlanmalı")
	assert_eq(settings.resolution, SettingsScript.FILL, "Listede olmayan boyut kabul edilmemeli")
	assert_eq(settings.camera_follow, "normal")
	assert_eq(settings.language, "tr", "Başka dil seçilemez")


func test_persist_off_never_writes() -> void:
	settings.persist = false
	assert_false(settings.save_settings())
	assert_false(FileAccess.file_exists(settings.path), "Geliştirme / test çalıştırması ayar yazmamalı")


## K100 (K36'nın yerine): Önsöz varsayılan olarak her yeni oyunda oynar; oyuncu «İlk yeni oyunda» seçerse görülen Önsöz atlanır.
## İlk oynatma prologue_seen yazar; geliştirme ve test koşuları (persist kapalı) oyuncunun dosyasına yazmaz.
func test_prologue_plays_once_unless_always_and_tests_do_not_write_it() -> void:
	settings.persist = false
	assert_true(settings.should_play_prologue())
	assert_false(settings.mark_prologue_seen(), "testte prologue_seen dosyaya yazılmaz")
	assert_false(FileAccess.file_exists(settings.path), "ayar dosyası oluşmamalı")
	assert_true(settings.prologue_seen, "bellekte işaretlenir")
	assert_true(settings.should_play_prologue(), "varsayılan: görülse de her yeni oyunda oynar (K100)")
	settings.prologue_always = false
	assert_false(settings.should_play_prologue(), "«İlk yeni oyunda» seçiliyse ikinci yeni oyunda atlanır")
	settings.prologue_always = true
	assert_true(settings.should_play_prologue(), "«Her yeni oyunda» seçiliyse oynar")
	settings.reset_to_defaults()
	assert_true(settings.prologue_always, "varsayılana dönüş «Her yeni oyunda» (K100)")
	assert_true(settings.prologue_seen, "varsayılana dönüş Önsöz'ü yeniden oynatmaz (durumdur, tercih değil)")
	var player := _new_settings()
	assert_true(player.mark_prologue_seen(), "oyuncunun açılışında (persist açık) ilk oynatma yazılır")
	var other := _new_settings()
	other.load_settings()
	assert_true(other.prologue_seen)
	player.free()
	other.free()
	var auto := UIKit.settings_node()
	if auto:
		assert_false(bool(auto.persist), "autoload testte yazmaz: Önsöz işareti de oyuncunun ayarına gitmez")


func test_apply_sets_bus_volumes_and_mutes_zero() -> void:
	settings.master_volume = 0.5
	settings.music_volume = 0.25
	settings.sfx_volume = 1.0
	settings.ambience_volume = 0.0
	settings.voice_volume = 0.5
	var changed := watch_signal(settings.changed)
	settings.apply()
	assert_eq(changed.count, 1, "apply() changed yaymalı (sahne ayarları için)")
	var master := AudioServer.get_bus_index(&"Master")
	assert_almost(AudioServer.get_bus_volume_db(master), linear_to_db(0.5), 0.01, "Ana ses veri yoluna uygulanmalı")
	var music := AudioServer.get_bus_index(&"Music")
	if music != -1:
		assert_almost(AudioServer.get_bus_volume_db(music), linear_to_db(0.25), 0.01, "Müzik veri yoluna uygulanmalı")
	var amb := AudioServer.get_bus_index(&"Ambience")
	if amb != -1:
		assert_true(AudioServer.is_bus_mute(amb), "Sıfır ses veri yolunu susturmalı")
	var voice := AudioServer.get_bus_index(&"Voice")
	assert_true(voice != -1, "Voice veri yolu olmalı")
	if voice != -1:
		assert_almost(AudioServer.get_bus_volume_db(voice), linear_to_db(0.5), 0.01, "Seslendirme Voice yoluna uygulanmalı")
		assert_false(AudioServer.is_bus_mute(voice))
		settings.voice_volume = 0.0
		settings.apply()
		assert_true(AudioServer.is_bus_mute(voice), "Seslendirme 0 Voice yolunu susturur")


func test_camera_settings_use_the_follow_camera_public_properties() -> void:
	var cam := FollowCamera.new()
	settings.camera_speed = 1.0
	settings.mouse_sensitivity = 0.0
	settings.camera_follow = "soft"
	settings.camera_fov = "narrow"
	settings.apply_to_camera(cam)
	assert_almost(cam.rotate_speed_deg, SettingsScript.rotate_speed_for(1.0))
	assert_almost(cam.mouse_sensitivity, SettingsScript.mouse_sensitivity_for(0.0))
	assert_almost(cam.follow_sharpness, float(SettingsScript.FOLLOW_MODES["soft"]))
	assert_almost(cam.fov, float(SettingsScript.FOV_MODES["narrow"]))
	settings.camera_speed = 0.5
	settings.mouse_sensitivity = 0.5
	settings.camera_follow = "normal"
	settings.camera_fov = "normal"
	settings.apply_to_camera(cam)
	assert_almost(cam.rotate_speed_deg, 110.0, 0.01, "Varsayılan dönüş hızı kameranın kendi değeri olmalı")
	assert_almost(cam.mouse_sensitivity, 0.3, 0.001, "Varsayılan fare hassasiyeti kameranın kendi değeri olmalı")
	assert_almost(cam.follow_sharpness, 5.5, 0.001)
	assert_almost(cam.fov, FollowCamera.DEFAULT_FOV, 0.001, "Normal görüş açısı kameranın varsayılanı olmalı")
	var plain := Node.new()
	settings.apply_to_camera(plain)   # bu özellikleri olmayan bir düğüm: çökmemeli
	plain.free()
	cam.free()


func test_window_resize_refreshes_the_ui_scale_only_when_it_changes() -> void:
	# En-boy oranı aynı kalan büyüme (1080p pencere → 1440p tam ekran) Control'lere resized göndermez:
	# ölçek GameSettings'in pencere dinleyicisiyle yenilenir.
	add_child(settings)
	assert_true(get_tree().root.size_changed.is_connected(settings._on_window_resized), "Pencere boyu dinlenmeli")
	var watcher := watch_signal(settings.changed)
	settings._on_window_resized()
	assert_eq(watcher.count, 0, "Ölçek değişmediyse changed yayılmamalı")
	settings.ui_scale = 0.8
	settings._on_window_resized()
	assert_eq(watcher.count, 1, "Ölçek değişince changed yayılmalı (menüler yeniden ölçeklenir)")
	settings._on_window_resized()
	assert_eq(watcher.count, 1, "Aynı ölçek için yeniden yayılmamalı")


func test_ui_scale_and_resolution_factor() -> void:
	assert_almost(SettingsScript.res_ui_factor(SettingsScript.FILL), 1.0)
	assert_almost(SettingsScript.res_ui_factor(Vector2i(1280, 720)), 1.0, 0.0001, "1080'in altında arayüz tam kalır")
	assert_almost(SettingsScript.res_ui_factor(Vector2i(2560, 1440)), 0.75)
	assert_almost(SettingsScript.res_ui_factor(Vector2i(3840, 2160)), 0.5)
	assert_almost(SettingsScript.res_ui_factor(Vector2i(3024, 1964)), 1080.0 / 1964.0, 0.0001, "Retina tam ekranda da küçülmeli")
	assert_almost(SettingsScript.res_ui_factor(Vector2i(5120, 2880)), 0.4, 0.0001, "Çok yüksek ekranda en az 0,4")
	# Çarpan seçilen çözünürlükten değil pencerenin gerçek boyundan gelir (tam ekranda macOS ekranın kendi
	# çözünürlüğünü kullanır); başsız testte pencere 1920×1080 sayılır.
	settings.ui_scale = 1.4
	settings.resolution = Vector2i(2560, 1440)
	assert_eq(settings.window_pixels(), Vector2i(1920, 1080))
	assert_almost(settings.ui_k(), 1.4 * SettingsScript.res_ui_factor(settings.window_pixels()))
	assert_eq(SettingsScript.parse_resolution("1920x1080", Vector2i(1, 1)), Vector2i(1920, 1080))
	assert_eq(SettingsScript.parse_resolution("0x0", Vector2i(1, 1)), SettingsScript.FILL)
	assert_eq(SettingsScript.parse_resolution("abc", Vector2i(1, 1)), Vector2i(1, 1))
	# K104: %50–%150, beşer beşer; aralığın dışı uca iner.
	for pair: Array in [[0.7, 0.7], [0.86, 0.85], [1.234, 1.25], [0.3, 0.5], [2.0, 1.5], [1.5, 1.5], [0.5, 0.5]]:
		assert_almost(SettingsScript.snap_ui_scale(pair[0]), pair[1], 0.000001, "snap(%s)" % pair[0])
	assert_eq(str(SettingsScript.snap_ui_scale(0.86)), "0.85", "Değer temiz yazılır")
	assert_almost(SettingsScript.snap_ui_scale(NAN), 1.0, 0.0001, "Sayı değilse %100")
	assert_almost(SettingsScript.UI_SCALE_MIN, 0.5)
	assert_almost(SettingsScript.UI_SCALE_MAX, 1.5)
	assert_almost(SettingsScript.UI_SCALE_STEP, 0.05)
	var list: Array = settings.resolutions()
	assert_eq(list[0]["size"], SettingsScript.FILL, "İlk seçenek 'Ekranı kapla'")
	assert_eq(list.size(), SettingsScript.RESOLUTIONS.size() + 1)


func test_autoload_does_not_touch_player_files_in_tests() -> void:
	var auto := UIKit.settings_node()
	assert_not_null(auto, "GameSettings autoload'u olmalı")
	if auto:
		assert_false(bool(auto.persist), "Başsız (test) çalıştırmada ayarlar dosyaya yazılmamalı")
		assert_false(bool(auto.apply_window), "Başsız çalıştırmada pencereye dokunulmamalı")
		assert_false(bool(auto.migrate_user_dir), "Başsız çalıştırmada eski klasörden kayıt ve ayar taşınmamalı")


## Hangi çalıştırma oyuncunun açılışıdır? Yalnız pencereli, "--" argümansız ve sahneyle açılan (betik ana döngüsü
## olmayan) çalıştırma: oyuncunun ayarına yazar, pencereyi boyutlandırır ve eski klasörden taşır.
func test_dev_run_detection() -> void:
	var none := PackedStringArray()
	assert_false(SettingsScript.is_dev_run(false, none, false), "Pencereli, argümansız, sahneyle açılış oyuncunundur")
	assert_true(SettingsScript.is_dev_run(true, none, false), "Başsız çalıştırma geliştirmedir")
	assert_true(SettingsScript.is_dev_run(false, PackedStringArray(["--capture=/tmp/menu.png"]), false),
		"'--' sonrası argümanlı çalıştırma (capture.sh) geliştirmedir")
	assert_true(SettingsScript.is_dev_run(false, none, true),
		"Pencereli ama betikle kurulan ana döngü (godot -s deneme.gd, '--' argümansız) geliştirmedir: taşıma çalışmamalı")
	# Bu koşu da betikle kurulan ana döngüdür (godot -s res://tests/run_tests.gd): autoload bunu böyle görür.
	assert_not_null(get_tree().get_script(), "-s ile kurulan SceneTree'nin betiği olmalı")


func test_own_settings_file_is_recognised_for_the_user_dir_migration() -> void:
	assert_false(UserDirMigration.is_own_settings(settings.path), "Dosya yoksa bu oyunun ayarı sayılmaz")
	assert_true(settings.save_settings())
	assert_true(UserDirMigration.is_own_settings(settings.path), "GameSettings'in yazdığı settings.cfg taşımada bu oyunun sayılmalı")
	# Tanhu 2D ve Tanhu 2'nin settings.cfg'si ([game] bölümü yok) bu oyunun sayılmamalı.
	var others: Array[Dictionary] = [
		{"general": {"ui_locale": "tr", "difficulty": "story"}, "display": {"fullscreen": true}},
		{"graphics": {"fov": 59.0}, "camera": {"sensitivity": 1.0}},
	]
	for other in others:
		var cfg := ConfigFile.new()
		for section: String in other:
			var keys: Dictionary = other[section]
			for key: String in keys:
				cfg.set_value(section, key, keys[key])
		assert_eq(cfg.save(settings.path), OK)
		assert_false(UserDirMigration.is_own_settings(settings.path), "Başka oyunun ayarı taşınmamalı: %s" % [other.keys()])


# --- Ayarlar sayfası ---------------------------------------------------------------------------

func _panel() -> SettingsPanel:
	var p := SettingsPanel.new()
	p.settings = settings
	p.size = Vector2(1920, 900)
	add_child(p)
	return p


func test_settings_page_has_tanhu1_sections_and_turkish_only_language() -> void:
	var p := _panel()
	await wait_frames(2)
	assert_eq(SettingsPanel.SECTIONS.map(func(s: Array) -> String: return str(s[0])), ["Oyun", "Dil", "Görüntü", "Ses"])
	p.show_section(1)
	assert_eq(p.get_section(), 1)
	var lang: Dictionary = p.get_control("language")
	assert_eq(lang.keys(), ["tr"], "Dil satırında yalnızca Türkçe olmalı")
	assert_true((lang["tr"] as Button).button_pressed)
	for key in ["camera_speed", "mouse_sensitivity", "camera_follow", "camera_fov", "show_hints", "prologue_always",
			"painterly", "ui_scale", "master_volume", "music_volume", "voice_volume", "sfx_volume", "ambience_volume"]:
		assert_not_null(p.get_control(key), "Ayar satırı eksik: %s" % key)
	assert_null(p.get_control("hud_scale"), "HUD ölçeği satırı yok: arayüz ölçeği tek ayar (K104)")
	# Ses bölümünün sırası (audio.md §1): Ana ses, Müzik, Seslendirme, Efektler, Ortam.
	var order := ["master_volume", "music_volume", "voice_volume", "sfx_volume", "ambience_volume"]
	var ys: Array[int] = []
	for key: String in order:
		ys.append((p.get_control(key) as Control).get_parent().get_index())
	for i in range(1, ys.size()):
		assert_true(ys[i] > ys[i - 1], "%s, %s'ın altında" % [order[i], order[i - 1]])
	var voice_row := (p.get_control("voice_volume") as Control).get_parent()
	assert_eq((voice_row.get_child(0) as Label).text, "Seslendirme")
	var prologue: Dictionary = p.get_control("prologue_always")
	assert_eq(prologue.keys(), [true, false], "Önsöz: Her yeni oyunda / İlk yeni oyunda (K100)")
	assert_eq((prologue[false] as Button).text, "İlk yeni oyunda")
	assert_eq((prologue[true] as Button).text, "Her yeni oyunda")
	assert_true((prologue[true] as Button).button_pressed, "varsayılan her yeni oyunda (K100)")
	if not OS.has_feature("web") and not OS.has_feature("mobile"):
		for key in ["fullscreen", "resolution", "vsync"]:
			assert_not_null(p.get_control(key), "Görüntü satırı eksik: %s" % key)
	p.queue_free()


func test_settings_page_changes_values_and_saves_on_close() -> void:
	var p := _panel()
	await wait_frames(2)
	var painterly: Dictionary = p.get_control("painterly")
	(painterly[false] as Button).button_pressed = true
	assert_false(settings.painterly, "Kapalı'ya basmak boyalı görünümü kapatmalı")
	var follow: Dictionary = p.get_control("camera_follow")
	(follow["tight"] as Button).button_pressed = true
	assert_eq(settings.camera_follow, "tight")
	var scale := p.get_control("ui_scale") as HSlider
	scale.value = 0.8
	assert_almost(settings.ui_scale, 0.8, 0.0001, "Kaydırıcı arayüz ölçeğini değiştirmeli")
	(p.get_control("music_volume") as HSlider).value = 0.35
	assert_almost(settings.music_volume, 0.35, 0.001, "Kaydırıcı müziği değiştirmeli")
	(p.get_control("voice_volume") as HSlider).value = 0.6
	assert_almost(settings.voice_volume, 0.6, 0.001, "Seslendirme kaydırıcısı Voice'u değiştirmeli")
	var voice_bus := AudioServer.get_bus_index(&"Voice")
	assert_almost(AudioServer.get_bus_volume_db(voice_bus), linear_to_db(0.6), 0.05, "Voice yoluna hemen uygulanmalı")
	var prologue: Dictionary = p.get_control("prologue_always")
	(prologue[true] as Button).button_pressed = true
	assert_true(settings.prologue_always, "«Her yeni oyunda» Önsöz'ü her yeni oyunda oynatır")
	var music := AudioServer.get_bus_index(&"Music")
	if music != -1:
		assert_almost(AudioServer.get_bus_volume_db(music), linear_to_db(0.35), 0.05, "Değişiklik hemen uygulanmalı")
	assert_false(FileAccess.file_exists(settings.path), "Sayfa açıkken henüz yazılmaz")
	remove_child(p)
	p.free()
	assert_true(FileAccess.file_exists(settings.path), "Sayfa kapanınca ayarlar kaydedilmeli")
	var other := _new_settings()
	other.load_settings()
	assert_false(other.painterly)
	assert_eq(other.camera_follow, "tight")
	assert_almost(other.music_volume, 0.35, 0.001)
	assert_almost(other.voice_volume, 0.6, 0.001)
	assert_true(other.prologue_always)
	other.free()


func test_settings_page_z_and_c_switch_sections() -> void:
	var p := _panel()
	await wait_frames(2)
	p.show_section(0)
	var c := InputEventKey.new()
	c.physical_keycode = KEY_C
	c.pressed = true
	Input.parse_input_event(c)
	await wait_frames(2)
	assert_eq(p.get_section(), 1, "C bir sonraki bölüme geçmeli")
	var z := InputEventKey.new()
	z.physical_keycode = KEY_Z
	z.pressed = true
	Input.parse_input_event(z)
	await wait_frames(2)
	Input.parse_input_event(z)
	await wait_frames(2)
	assert_eq(p.get_section(), 3, "Z geri, baştan sona sarar")
	p.queue_free()


func test_resolution_note_texts() -> void:
	assert_true(SettingsPanel.resolution_note(true, SettingsScript.FILL, Vector2i(3456, 2234)).contains("3456 × 2234"))
	assert_true(SettingsPanel.resolution_note(false, SettingsScript.FILL, Vector2i.ZERO).contains("kaplar"))
	assert_true(SettingsPanel.resolution_note(false, Vector2i(1920, 1080), Vector2i.ZERO).contains("gerçek pikselle"))
	assert_true(SettingsPanel.same_value(0.9, snappedf(0.9, 0.1)))
	assert_false(SettingsPanel.same_value(true, 1))


## Sinemanın yazısı resmin parçasıdır: menüler gibi yüksek çözünürlükte küçülmez, yalnız oyuncunun ölçeği uygulanır.
func test_film_scale_ignores_window_pixels() -> void:
	var settings := SettingsScript.new()
	settings.ui_scale = 0.9
	assert_almost(settings.film_k(), 0.9, 0.0001, "Sinema yazısı oyuncunun ölçeğini izler")
	settings.free()


## K104: eski dosyanın arayüz ölçeği aynen geçer, eski HUD ölçeği okunmaz ve bir sonraki kayıtta düşer (HUD tek ayarda arayüzün 0,8'i).
## Eski varsayılanlar (%100 + HUD %100) yeni varsayılana, kullanıcının %100 + HUD %80'i aynı görünüşe düşer; HUD'u büyük seçen eski dosya
## menüleri büyütmez (%100 + HUD %130 → %100).
func test_old_ui_and_hud_scales_migrate() -> void:
	for row: Array in [[1.0, 1.0, 1.0], [1.0, 0.8, 1.0], [0.9, 1.3, 0.9], [0.8, 0.8, 0.8], [1.0, 1.3, 1.0]]:
		var cfg := ConfigFile.new()
		cfg.set_value("display", "ui_scale", row[0])
		cfg.set_value("display", "hud_scale", row[1])
		cfg.save(settings.path)
		var old := _new_settings()
		assert_true(old.load_settings())
		assert_almost(old.ui_scale, row[2], 0.0001, "ui %s + hud %s → %s" % row)
		assert_almost(old.ui_scale * HudKit.HUD_SCALE * SettingsScript.res_ui_factor(old.window_pixels()), old.ui_k() * HudKit.hud_scale(),
			0.0001, "HUD arayüzün 0,8'i")
		assert_true(old.save_settings())
		var after := ConfigFile.new()
		after.load(settings.path)
		assert_false(after.has_section_key("display", "hud_scale"), "Eski anahtar kayıtta düşer")
		assert_almost(float(after.get_value("display", "ui_scale")), row[2], 0.0001)
		old.free()
	# Kullanıcının eşlemesi (E20): eski %100 + HUD %80 ile yeni %100 aynı HUD'u çizer.
	assert_almost(1.0 * HudKit.HUD_SCALE, 1.0 * 0.8, 0.0001)
	# Bozuk değer yok sayılır, aralığın dışı uca iner.
	for bad: Array in [["büyük", 1.0], [3.0, 1.5], [0.1, 0.5]]:
		var cfg := ConfigFile.new()
		cfg.set_value("display", "ui_scale", bad[0])
		cfg.save(settings.path)
		var s := _new_settings()
		s.load_settings()
		assert_almost(s.ui_scale, bad[1], 0.0001, "ui_scale = %s" % [bad[0]])
		s.free()


## «Arayüz ölçeği» satırı (K104): kitabın dilinde kaydırıcı %50–%150, beşer beşer; yanında yüzde. Klavye (← →) adım adım değiştirir ve
## hemen uygular; fareyle sürüklerken yazı izler, ölçek bırakınca uygulanır (sayfa kaydırıcının altından kaymasın).
func test_ui_scale_slider_steps_and_applies() -> void:
	var p := _panel()
	await wait_frames(2)
	p.show_section(2)
	var slider := p.get_control("ui_scale") as HSlider
	assert_true(slider is SettingsPanel.BookSlider, "Kitabın dilinde kaydırıcı")
	assert_almost(slider.min_value, 0.5)
	assert_almost(slider.max_value, 1.5)
	assert_almost(slider.step, 0.05)
	assert_almost(slider.value, 1.0)
	var label := slider.get_parent().get_child(slider.get_index() + 1) as Label
	assert_eq(label.text, "%100", "Değerin yanında yüzde")
	assert_eq((slider.get_parent().get_child(0) as Label).text, "Arayüz ölçeği")
	assert_eq(SettingsPanel.percent_text(0.85), "%85")
	# Klavye: → bir adım.
	slider.grab_focus()
	var right := InputEventKey.new()
	right.keycode = KEY_RIGHT
	right.physical_keycode = KEY_RIGHT
	right.pressed = true
	Input.parse_input_event(right)
	await wait_frames(2)
	var right_up := right.duplicate() as InputEventKey
	right_up.pressed = false
	Input.parse_input_event(right_up)
	assert_almost(settings.ui_scale, 1.05, 0.0001, "→ beşer yüzde büyütür, hemen uygulanır")
	assert_eq(label.text, "%105")
	assert_true(slider.has_focus(), "Kaydırıcı odakta kalır")
	# Oyun kolu: yön tuşu solu bir adım geri (ui_left).
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_DPAD_LEFT
	pad.pressed = true
	Input.parse_input_event(pad)
	await wait_frames(2)
	var pad_up := pad.duplicate() as InputEventJoypadButton
	pad_up.pressed = false
	Input.parse_input_event(pad_up)
	assert_almost(settings.ui_scale, 1.0, 0.0001, "Oyun kolunun yön tuşu da adım adım değiştirir")
	assert_eq(label.text, "%100")
	# Fareyle sürükleme: yazı izler, ayar bırakınca değişir.
	var watcher := watch_signal(settings.changed)
	slider.drag_started.emit()
	slider.value = 1.3
	assert_eq(label.text, "%130", "Sürüklerken yazı izler")
	assert_almost(settings.ui_scale, 1.0, 0.0001, "Sürüklerken ölçek değişmez")
	assert_eq(watcher.count, 0)
	slider.drag_ended.emit(true)
	assert_almost(settings.ui_scale, 1.3, 0.0001, "Bırakınca uygulanır")
	assert_eq(watcher.count, 1, "Bir kez uygulanır")
	slider.value = 1.5
	assert_almost(settings.ui_scale, 1.5, 0.0001, "Sürüklemeden değişen değer (tekerlek) hemen uygulanır")
	p.queue_free()


## Büyük arayüz ölçeğinde kitabın sayfa alanına sığmayan sayfa sığacak kadar küçülür (UIKit.center_in_parent, fit_scale); sığan 1'de kalır.
func test_pages_fit_their_area_at_large_ui_scales() -> void:
	assert_eq(UIKit.fit_scale(Vector2(100, 50), Vector2(200, 200)), 2.0)
	assert_almost(UIKit.fit_scale(Vector2(1408, 788), Vector2(1280, 532)), 532.0 / 788.0, 0.0001)
	assert_eq(UIKit.fit_scale(Vector2.ZERO, Vector2(10, 10)), INF, "Boyu belli olmayan içerik sınır koymaz")
	var holder := Control.new()
	holder.size = Vector2(1920, 900)
	add_child(holder)
	var p := SettingsPanel.new()
	p.settings = settings
	p.size = holder.size
	holder.add_child(p)
	await wait_frames(3)
	var frame := p.get("_panel") as Control
	assert_almost(frame.scale.x, 1.0, 0.0001, "Sığan sayfa 1'de")
	p.size = Vector2(1280, 532)
	await wait_frames(2)
	assert_true(frame.scale.x < 1.0, "Sığmayan sayfa küçülür")
	var room := Vector2(1280, 532) - Vector2.ONE * UIKit.FIT_MARGIN * 2.0
	assert_true(frame.get_rect().size.y * frame.scale.y <= room.y + 0.5 and frame.get_rect().size.x * frame.scale.x <= room.x + 0.5,
		"Alana kenar payıyla sığar")
	holder.queue_free()


## «Görüldü» Önsöz'ün sürümüne bağlıdır: sürüm yazmayan eski dosya yeni Önsöz'ü bir kez daha oynatır, yenisini gören atlar.
func test_prologue_seen_expires_with_the_content_version() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "prologue_seen", true)
	cfg.save(dir.path_join("settings.cfg"))
	var old := _new_settings()
	old.load_settings()
	assert_false(old.prologue_seen, "Sürümsüz eski dosya: yeni Önsöz oynar")
	assert_true(old.should_play_prologue())
	# «İlk yeni oyunda» seçen oyuncu: «görüldü» işareti sürüme bağlıdır (K100'den beri varsayılan her yeni oyunda oynar).
	old.prologue_always = false
	assert_true(old.mark_prologue_seen(), "Oyuncunun açılışında yazılır")
	var fresh := _new_settings()
	fresh.load_settings()
	assert_true(fresh.prologue_seen, "Bu sürümü gören atlar")
	assert_false(fresh.should_play_prologue(), "«İlk yeni oyunda» seçiliyse görülen Önsöz atlanır")
	old.free()
	fresh.free()


## K100: eski dosyanın «prologue_always = false»ı o günün varsayılanıdır, seçim değildir: Önsöz yine her yeni oyunda oynar. Yeni anahtardaki
## «İlk yeni oyunda» seçimi korunur.
func test_old_prologue_key_does_not_turn_the_prologue_off() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("game", "prologue_seen", true)
	cfg.set_value("game", "prologue_version", 2)
	cfg.set_value("game", "prologue_always", false)
	cfg.save(dir.path_join("settings.cfg"))
	var old := _new_settings()
	old.load_settings()
	assert_true(old.prologue_always, "Eski anahtar okunmaz")
	assert_true(old.should_play_prologue(), "Görülmüş olsa da oynar")
	old.prologue_always = false
	old.save_settings()
	var picked := _new_settings()
	picked.load_settings()
	assert_false(picked.prologue_always, "Oyuncunun seçimi yeni anahtarda kalır")
	old.free()
	picked.free()



## «Çocukluğu geç» (K100'ün dili): Çocukluk'u bir kez bitiren oyuncu ayarda işaretlenir; işaret Çocukluk'un içerik sürümüne bağlıdır,
## sıfırlama (reset_to_defaults) onu silmez, testte (persist kapalı) dosyaya yazılmaz.
func test_childhood_done_is_remembered_with_its_version() -> void:
	assert_false(settings.childhood_done, "Varsayılan: Çocukluk bitmedi, geç sunulmaz")
	assert_true(settings.mark_childhood_done(), "Oyuncunun açılışında yazılır")
	var again := _new_settings()
	again.load_settings()
	assert_true(again.childhood_done, "[game] childhood_done")
	again.reset_to_defaults()
	assert_true(again.childhood_done, "Varsayılana dönmek oynanmış Çocukluk'u silmez")
	var cfg := ConfigFile.new()
	cfg.set_value("game", "childhood_done", true)
	cfg.set_value("game", "childhood_version", SettingsScript.CHILDHOOD_VERSION - 1)
	cfg.save(dir.path_join("settings.cfg"))
	var old := _new_settings()
	old.load_settings()
	assert_false(old.childhood_done, "Eski sürümün işareti eskir: yeni Çocukluk bir kez daha oynar")
	var dev := _new_settings()
	dev.persist = false
	assert_false(dev.mark_childhood_done(), "Testte dosyaya yazılmaz")
	assert_true(dev.childhood_done, "Bellekte işaretlenir")
	again.free()
	old.free()
	dev.free()


# --- Kamera ve tuş ataması (camera-pitch, key-rebinding; godot.md §5.6) -------------------------------------------

## Yeni kamera ayarları kaydedilir, okunur ve sınırlanır; görüş seçenekleri K98'in 30–40°'lik ailesindedir (Geniş 40°).
func test_camera_band_settings_round_trip_and_stay_in_the_k98_family() -> void:
	for mode: String in SettingsScript.FOV_MODES:
		assert_between(float(SettingsScript.FOV_MODES[mode]), 30.0, 40.0, "Görüş %s K98'in ailesinde" % mode)
	assert_almost(float(SettingsScript.FOV_MODES["wide"]), 40.0, 0.0001, "Geniş 40° (K39'un 42°'si ailenin dışındaydı)")
	assert_almost(settings.camera_pitch_bias, 0.0)
	assert_true(settings.camera_tilt and settings.camera_wheel_map)
	assert_false(settings.camera_invert_x or settings.camera_invert_y)
	settings.camera_pitch_bias = 7.0
	settings.camera_tilt = false
	settings.camera_invert_y = true
	settings.camera_wheel_map = false
	assert_true(settings.save_settings())
	var other := _new_settings()
	assert_true(other.load_settings())
	assert_almost(other.camera_pitch_bias, 7.0)
	assert_false(other.camera_tilt)
	assert_true(other.camera_invert_y)
	assert_false(other.camera_invert_x)
	assert_false(other.camera_wheel_map)
	var cfg := ConfigFile.new()
	cfg.set_value("game", "camera_pitch_bias", 25.0)
	cfg.set_value("game", "camera_tilt", "evet")
	cfg.save(settings.path)
	assert_true(other.load_settings())
	assert_almost(other.camera_pitch_bias, SettingsScript.PITCH_BIAS_MAX, 0.0001, "Pay aralıkta kalır")
	assert_false(other.camera_tilt, "Yazı değer yok sayılır, önceki kalır")
	assert_almost(SettingsScript.snap_pitch_bias(-9.6), SettingsScript.PITCH_BIAS_MIN, 0.0001)
	assert_almost(SettingsScript.snap_pitch_bias(4.4), 4.0, 0.0001, "Tam derece")
	other.reset_to_defaults()
	assert_almost(other.camera_pitch_bias, 0.0)
	assert_true(other.camera_tilt)
	other.free()


func test_camera_band_settings_reach_the_follow_camera() -> void:
	var cam := FollowCamera.new()
	settings.camera_pitch_bias = 5.0
	settings.camera_tilt = false
	settings.camera_invert_x = true
	settings.apply_to_camera(cam)
	assert_almost(cam.pitch_bias, 5.0)
	assert_false(cam.tilt_enabled)
	assert_true(cam.invert_x)
	assert_false(cam.invert_y)
	cam.free()


## Tuş ataması [input] bölümüne yazılır ve açılışta uygulanır; bozuk satır sessizce atlanır, oyuncunun öteki ayarları bozulmaz.
func test_key_bindings_are_saved_in_the_input_section() -> void:
	InputSetup.ensure_actions()
	InputSetup.reset_bindings()
	InputSetup.rebind(&"jump", InputSetup.key_event(KEY_K))
	settings.input_bindings = InputSetup.bindings()
	assert_true(settings.save_settings())
	InputSetup.reset_bindings()
	var cfg := ConfigFile.new()
	assert_eq(cfg.load(settings.path), OK)
	assert_true(cfg.has_section_key("input", "jump"), "[input] jump")
	cfg.set_value("input", "fly", [{"type": "key", "physical": KEY_F}])
	cfg.set_value("input", "map", "bozuk")
	cfg.set_value("audio", "music", 0.4)
	cfg.save(settings.path)
	var other := _new_settings()
	assert_true(other.load_settings())
	var jump := [{"type": "key", "physical": KEY_K}, {"type": "joy_button", "index": JOY_BUTTON_A}]
	assert_eq(other.input_bindings, {"jump": jump}, "Bilinmeyen eylem ve bozuk satır atlanır; eylemin bütün olayları (kolda A) yazılır")
	assert_almost(other.music_volume, 0.4, 0.0001, "Öteki ayarlar okunur")
	other.apply_input()
	var k := InputSetup.key_event(KEY_K)
	k.pressed = true
	assert_true(InputMap.event_is_action(k, &"jump"), "Açılışta atama uygulanır")
	InputSetup.reset_bindings()
	other.reset_to_defaults()
	assert_eq(other.input_bindings, {}, "Varsayılana dönüş atamayı da siler")
	other.free()


func test_settings_page_has_the_camera_band_rows() -> void:
	var p := _panel()
	await wait_frames(2)
	var bias := p.get_control("camera_pitch_bias") as HSlider
	assert_not_null(bias, "Eğim payı satırı")
	assert_almost(bias.min_value, SettingsScript.PITCH_BIAS_MIN)
	assert_almost(bias.max_value, SettingsScript.PITCH_BIAS_MAX)
	assert_almost(bias.step, 1.0)
	bias.value = 6.0
	assert_almost(settings.camera_pitch_bias, 6.0, 0.0001, "Kaydırıcı payı değiştirir")
	assert_eq((bias.get_parent().get_child(bias.get_index() + 1) as Label).text, "+6°")
	var tilt: Dictionary = p.get_control("camera_tilt")
	(tilt[false] as Button).button_pressed = true
	assert_false(settings.camera_tilt, "Oyunda eğim kapanır")
	var invert: Dictionary = p.get_control("camera_invert")
	assert_eq(invert.keys(), ["none", "x", "y", "xy"])
	(invert["y"] as Button).button_pressed = true
	assert_true(settings.camera_invert_y and not settings.camera_invert_x, "Ters dikey")
	(invert["xy"] as Button).button_pressed = true
	assert_true(settings.camera_invert_x and settings.camera_invert_y, "İkisi")
	assert_eq(SettingsPanel.degrees_text(-3.0), "−3°")
	assert_eq(SettingsPanel.degrees_text(0.0), "0°")
	# Oyun bölümü kamera satırlarıyla sayfadan uzundur: kaydırılır, odaktaki satır görünür kalır.
	var page := (p.get_control("camera_speed") as Control).get_parent().get_parent() as VBoxContainer
	var scroll := page.get_parent() as ScrollContainer
	assert_not_null(scroll, "Bölüm kaydırılır")
	assert_true(scroll.follow_focus)
	assert_almost(scroll.size.y, SettingsPanel.PAGE_H, 0.5, "Sayfanın yüksekliği değişmez (kitabın çerçevesi)")
	p.show_section(0)
	await wait_frames(1)
	var last: Dictionary = p.get_control("prologue_always")
	(last[true] as Button).grab_focus()
	await wait_frames(3)
	assert_true(scroll.scroll_vertical > 0, "Son satıra inince sayfa kayar")
	p.queue_free()
