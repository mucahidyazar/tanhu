extends TestCase
## Kayıt sistemi testleri: SaveSystem (yuvalar, en son kayıt, eksik / bozuk dosya, küçük resim,
## yazılamayan klasör), SaveData (kaydın içeriği, okunması, biçimleri) ve Journey (kaydetme ve kayıttan
## geri yükleme: karakter, yer, yön, süre, işaretler). Hepsi geçici bir klasörde çalışır; oyuncunun
## kayıtlarına dokunulmaz.
## Kayıt klasörü (K30): user:// use_custom_user_dir ile sabittir ve adı eski klasörlerden ayrıdır;
## UserDirMigration eski app_userdata/Tanhu klasöründen yalnız bu oyunun kayıtlarını, küçük resimlerini ve
## settings.cfg'sini bir kez kopyalar, eski klasörü ve Tanhu 2D / Tanhu 2 / Tanhu Ref'i değiştirmez, ikinci
## açılışta yeniden taşımaz. Taşıma testleri geçici klasörde kurulan SAHTE klasörlerle çalışır.

const TempDir := preload("res://tests/support/temp_dir.gd")
const SettingsScript := preload("res://scripts/settings/game_settings.gd")
## Eski klasörün yanındaki öteki oyunların klasörleri: taşıma bunlara hiç dokunmamalı (K30).
const OTHER_GAME_DIRS: Array[String] = ["Tanhu 2D", "Tanhu 2", "Tanhu Ref"]
## Sahte eski klasörden kopyalanması beklenenler: kaydı olan yuvaların kaydı ve resmi, bu oyunun ayarı.
const EXPECTED_COPIES: Array[String] = ["settings.cfg", "tanhu3_save_0.json", "tanhu3_save_3.json", "tanhu3_thumb_0.png"]
## Tanhu 2D'nin ve Tanhu 2'nin settings.cfg'sinden birer parça: ikisinde de [game] bölümü yok.
const TANHU_2D_SETTINGS := {"general": {"ui_locale": "tr", "difficulty": "story"}, "audio": {"music": 0.8}, "display": {"fullscreen": true, "window_px": "2560x1440"}}
const TANHU_2_SETTINGS := {"general": {"ui_locale": "tr"}, "graphics": {"fov": 59.0}, "camera": {"sensitivity": 1.0, "invert_y": false}}

var dir := ""
var saves: SaveSystem
## Taşıma testlerinin sahte veri klasörü (macOS'ta ~/Library/Application Support'un yerine); boşsa kurulmadı.
var data_root := ""


func before_each() -> void:
	dir = TempDir.fresh("kayit")
	saves = SaveSystem.new(dir)


func after_each() -> void:
	TempDir.wipe(dir)
	if data_root != "":
		_wipe_tree(data_root)
		data_root = ""


func _profile() -> CharacterProfile:
	var p := CharacterProfile.new()
	p.set_value(&"skin", 3)
	p.set_value(&"hair_color", 5)
	p.set_value(&"eye_color", 2)
	return p


func _record(save_no: int = 1, unix: float = 1000.0, at: String = "2026-10-26T06:53:12") -> Dictionary:
	return SaveData.build(_profile(), Vector3(3.5, 0.25, -7.0), 1.25, {"ates_basi": true}, 754.0, save_no, "ocak", at, unix)


func _write_raw(slot: int, text: String) -> void:
	var f := FileAccess.open(saves.slot_path(slot), FileAccess.WRITE)
	f.store_string(text)
	f.close()


# --- Yuvalar ---------------------------------------------------------------------------------

func test_round_trip_keeps_profile_place_facing_time_and_flags() -> void:
	assert_true(saves.write(2, _record()), "Kayıt yazılmalı")
	assert_true(saves.has_save(2))
	var info := saves.slot_info(2)
	assert_false(info.is_empty(), "Yazılan kayıt okunmalı")
	var data := SaveData.parse(info)
	assert_true((data["profile"] as CharacterProfile).equals(_profile()), "Karakter aynen geri gelmeli")
	assert_vec_almost(data["position"], Vector3(3.5, 0.25, -7.0), 0.0001, "Oyuncunun yeri geri gelmeli")
	assert_true(bool(data["has_position"]))
	assert_almost(float(data["yaw"]), 1.25, 0.0001, "Baktığı yön geri gelmeli")
	assert_almost(float(data["play_time"]), 754.0, 0.001, "Oynanan süre geri gelmeli")
	assert_eq(data["flags"], {"ates_basi": true}, "İşaretler geri gelmeli")
	assert_eq(str(data["place"]), "ocak")
	assert_eq(int(data["save_no"]), 1)
	assert_eq(str(data["saved_at"]), "2026-10-26T06:53:12")
	assert_false(FileAccess.file_exists(saves.slot_path(2) + ".tmp"), "Geçici dosya kalmamalı")


func test_slots_are_independent_and_numbered() -> void:
	assert_false(saves.has_any_save(), "Boş klasörde kayıt yok")
	assert_eq(saves.next_save_no(), 1)
	saves.write(1, _record(1))
	saves.write(5, _record(4))
	assert_true(saves.has_any_save())
	assert_true(saves.has_save(1) and saves.has_save(5))
	assert_false(saves.has_save(2), "Yazılmayan yuva boş kalmalı")
	assert_eq(saves.next_save_no(), 5, "Sıradaki kayıt numarası en büyüğün bir fazlası")
	assert_false(saves.write(SaveSystem.SLOTS + 1, _record()), "Olmayan yuvaya yazılmamalı")
	assert_false(saves.write(-1, _record()))
	assert_eq(saves.slot_info(99), {})
	saves.remove(5)
	assert_false(saves.has_save(5), "Silinen yuva boşalmalı")
	assert_true(saves.has_save(1))


func test_latest_slot_is_the_newest_save() -> void:
	assert_eq(saves.latest_slot(), -1, "Kayıt yoksa -1")
	saves.write(1, _record(1, 1000.0))
	saves.write(3, _record(2, 3000.0))
	saves.write(SaveSystem.AUTO_SLOT, _record(0, 2000.0))
	assert_eq(saves.latest_slot(), 3, "En yeni kayıt (Unix zamanı en büyük) seçilmeli")
	saves.write(SaveSystem.AUTO_SLOT, _record(0, 4000.0))
	assert_eq(saves.latest_slot(), SaveSystem.AUTO_SLOT, "Otomatik kayıt da en yeni olabilir")
	# Aynı saniyede yazılanlar tarih yazısıyla ayrılır.
	saves.write(4, _record(3, 4000.0, "2026-10-26T09:00:00"))
	assert_eq(saves.latest_slot(), 4)


func test_missing_and_corrupt_files_count_as_empty() -> void:
	assert_eq(saves.slot_info(1), {}, "Eksik dosya boş yuva")
	_write_raw(1, "{ bu json değil")
	assert_eq(saves.slot_info(1), {}, "Bozuk dosya boş yuva sayılmalı")
	assert_false(saves.has_save(1))
	_write_raw(2, JSON.stringify({"foo": 1}))
	assert_eq(saves.slot_info(2), {}, "Tanhu kaydı olmayan dosya boş sayılmalı")
	var other := _record()
	other["game"] = "tanhu"
	_write_raw(3, JSON.stringify(other))
	assert_eq(saves.slot_info(3), {}, "Başka oyunun kaydı okunmamalı")
	assert_false(saves.has_any_save())
	assert_eq(saves.latest_slot(), -1, "Bozuk kayıtlar en son kayıt sayılmamalı")
	saves.write(4, _record())
	assert_eq(saves.latest_slot(), 4)
	# Bozuk yuvanın üstüne yeniden yazılabilir.
	assert_true(saves.write(1, _record()))
	assert_true(saves.has_save(1))


func test_parse_falls_back_to_safe_defaults() -> void:
	var bad := {"version": 1, "profile": {"skin": 999}, "position": ["a", 1, 2], "yaw": "sağa", "play_time": -50, "flags": "x"}
	var data := SaveData.parse(bad)
	assert_false(bool(data["has_position"]), "Bozuk yer kullanılmamalı")
	assert_eq(data["position"], Vector3.ZERO)
	assert_almost(float(data["yaw"]), 0.0)
	assert_almost(float(data["play_time"]), 0.0, 0.0001, "Eksi süre sıfıra düşmeli")
	assert_eq(data["flags"], {})
	assert_true((data["profile"] as CharacterProfile).skin < CharacterOptions.count(&"skin"), "Taşan değer seçeneklere sarılmalı")
	var nan_pos := SaveData.parse({"version": 1, "profile": {}, "position": [NAN, 0.0, 1.0]})
	assert_false(bool(nan_pos["has_position"]), "NaN yer kullanılmamalı")
	assert_false(Journey.record_has_position({"version": 1, "profile": {}}))
	assert_false(SaveData.is_record([1, 2]))
	assert_false(SaveData.is_record({"profile": {}}), "Sürümsüz kayıt okunmamalı")


func test_thumbnail_is_written_cropped_and_loaded() -> void:
	var frame := Image.create(420, 180, false, Image.FORMAT_RGB8)   # 21:9
	frame.fill(Color(0.2, 0.4, 0.6))
	assert_true(saves.write(1, _record(), frame))
	assert_true(FileAccess.file_exists(saves.thumb_path(1)), "Küçük resim yazılmalı")
	var tex := saves.load_thumb(1)
	assert_not_null(tex, "Küçük resim okunmalı")
	if tex:
		assert_eq(Vector2i(tex.get_size()), SaveSystem.THUMB_SIZE, "Küçük resim 320×180 olmalı")
	var small := SaveSystem.make_thumbnail(frame)
	assert_eq(small.get_size(), SaveSystem.THUMB_SIZE)
	assert_null(SaveSystem.make_thumbnail(null))
	# Resimsiz yeniden yazılınca eski resim kalmamalı (başka bir anın resmi görünmesin).
	assert_true(saves.write(1, _record()))
	assert_false(FileAccess.file_exists(saves.thumb_path(1)))
	assert_null(saves.load_thumb(1))


func test_read_only_save_system_never_writes() -> void:
	var ro := SaveSystem.new(dir, false)
	assert_false(ro.write(1, _record()), "Yazılamayan kayıt sistemi yazmamalı")
	assert_false(FileAccess.file_exists(ro.slot_path(1)))
	saves.write(2, _record())
	assert_true(ro.has_save(2), "Yazılamayan kayıt sistemi yine de okumalı")
	ro.remove(2)
	assert_true(saves.has_save(2), "Yazılamayan kayıt sistemi silmemeli")


func test_formats() -> void:
	assert_eq(SaveData.format_play_time(3725.0), "1 sa 02 dk")
	assert_eq(SaveData.format_play_time(0.0), "0 sa 00 dk")
	assert_eq(SaveData.format_duration(20.0), "1 dk", "Kısa süre en az 1 dk yazılır")
	assert_eq(SaveData.format_duration(3900.0), "1 sa 5 dk")
	assert_eq(SaveData.format_date("2026-10-26T06:53:12"), "26.10.2026  06:53")
	assert_eq(SaveData.format_date("kısa"), "kısa")
	var info := _record(3)
	assert_eq(SaveData.slot_title(info, 2), "Ocak başı #3")
	assert_eq(SaveData.slot_title(info, SaveSystem.AUTO_SLOT), "Otomatik kayıt · Ocak başı")
	assert_eq(SaveData.place_line(info), "Gece Kampı · Ocak başı")
	assert_eq(SaveData.meta_line(info), "0 sa 12 dk  ·  26.10.2026  06:53")


# --- Yolculuk ----------------------------------------------------------------------------------

func test_journey_saves_and_restores_itself() -> void:
	var j := Journey.new(saves, _profile())
	j.play_time = 300.0
	j.set_flag(JourneyFlags.FIRESIDE)
	j.visit(Vector3(13.0, 0.0, -9.0), 2.0)   # ahırın önü
	assert_true(j.has_flag(JourneyFlags.STABLE), "Ahırın önüne varınca işaret konmalı")
	assert_eq(j.place_id(), "ahir")
	assert_true(j.save_manual(1))
	assert_true(j.save_manual(2))
	assert_eq(int(saves.slot_info(2).get("save_no", 0)), 2, "Kayıt numaraları artmalı")
	assert_false(j.save_manual(0), "Oyuncu otomatik kayıt yuvasına elle yazamaz")
	assert_true(j.save_auto())
	assert_eq(SaveData.slot_title(saves.slot_info(0), 0), "Otomatik kayıt · Ahırın önü")
	var other := Journey.new(saves)
	assert_true(other.apply_record(saves.slot_info(1)), "Kayıttan yolculuk kurulmalı")
	assert_true(other.profile.equals(_profile()))
	assert_vec_almost(other.position, Vector3(13.0, 0.0, -9.0), 0.001)
	assert_almost(other.yaw, 2.0, 0.001)
	assert_almost(other.play_time, 300.0, 0.001)
	assert_true(other.has_flag(JourneyFlags.FIRESIDE) and other.has_flag(JourneyFlags.STABLE))
	assert_false(other.apply_record({}), "Boş kayıt yolculuğu değiştirmemeli")
	assert_true(other.has_flag(JourneyFlags.FIRESIDE), "Başarısız yükleme işaretleri silmemeli")


func test_journey_flags_fire_once_and_reset() -> void:
	var j := Journey.new(saves)
	var watcher := watch_signal(j.flag_set)
	assert_true(j.set_flag("ates_basi"), "İlk kez konan işaret true döner")
	assert_false(j.set_flag("ates_basi"), "Tekrar konunca false döner")
	assert_eq(watcher.count, 1, "flag_set bir kez yayılmalı")
	j.play_time = 10.0
	j.reset()
	assert_false(j.has_flag("ates_basi"), "Yeni yolculukta işaretler sıfırlanır")
	assert_almost(j.play_time, 0.0)


func test_journey_uses_pending_thumbnail() -> void:
	var j := Journey.new(saves)
	var frame := Image.create(64, 36, false, Image.FORMAT_RGB8)
	frame.fill(Color.ORANGE)
	j.pending_thumb = frame
	assert_true(j.save_manual(3))
	assert_not_null(saves.load_thumb(3), "Duraklatma anının karesi küçük resim olmalı")


# --- Kayıt klasörü ve eski klasörden tek seferlik taşıma (K30) -------------------------------------

func test_user_dir_is_fixed_and_apart_from_old_folders() -> void:
	assert_true(bool(ProjectSettings.get_setting("application/config/use_custom_user_dir", false)),
		"user:// proje adından bağımsız sabitlenmeli (use_custom_user_dir)")
	var dir_name := _user_dir_name()
	assert_ne(dir_name, "", "Özel klasörün adı boş olmamalı (boşsa proje adı kullanılır)")
	var taken: Array[String] = [UserDirMigration.LEGACY_APP_NAME, str(ProjectSettings.get_setting("application/config/name", ""))]
	taken.append_array(OTHER_GAME_DIRS)
	for old in taken:
		assert_ne(dir_name.to_lower(), old.to_lower(), "Özel klasörün adı eski klasörlerden ve proje adından ayrı olmalı: %s" % old)
	var user_dir := OS.get_user_data_dir()
	assert_eq(user_dir.get_file(), dir_name, "user:// özel klasör olmalı")
	assert_eq(user_dir.get_base_dir(), OS.get_data_dir(), "Özel klasör sistemin veri klasöründe durmalı")
	assert_false(user_dir.to_lower().contains("app_userdata"), "Yeni klasör Godot'nun app_userdata'sının dışında olmalı")
	assert_ne(user_dir.to_lower(), UserDirMigration.legacy_dir(OS.get_data_dir(), OS.get_name()).to_lower(),
		"Yeni klasör eski klasörden ayrı olmalı")


func test_old_folder_is_godots_default_on_each_platform() -> void:
	assert_eq(UserDirMigration.legacy_dir("/Users/a/Library/Application Support", "macOS"),
		"/Users/a/Library/Application Support/Godot/app_userdata/Tanhu")
	assert_eq(UserDirMigration.legacy_dir("C:/Users/a/AppData/Roaming", "Windows"), "C:/Users/a/AppData/Roaming/Godot/app_userdata/Tanhu")
	assert_eq(UserDirMigration.legacy_dir("/home/a/.local/share", "Linux"), "/home/a/.local/share/godot/app_userdata/Tanhu",
		"Linux'ta Godot'nun klasörü küçük harflidir")


func test_migration_copies_only_this_games_saves_and_settings() -> void:
	var dirs := _fake_data_dir()
	var legacy := dirs[0]
	var user_dir := dirs[1]
	var before := _snapshot(data_root.path_join("Godot"))
	assert_false(UserDirMigration.is_done(user_dir), "İlk açılışta taşıma yapılmamış olmalı")
	var copied := UserDirMigration.migrate(legacy, user_dir)
	assert_eq(_sorted(copied), _sorted(EXPECTED_COPIES), "Yalnız bu oyunun kayıtları, küçük resmi ve ayarı kopyalanmalı")
	assert_eq(_files(user_dir), _sorted(EXPECTED_COPIES + [UserDirMigration.MARKER_FILE]),
		"Yeni klasörde başka dosya olmamalı (sahipsiz resim, yarım dosya, yuva dışı kayıt yok)")
	assert_eq(DirAccess.get_directories_at(user_dir).size(), 0, "Günlük ve önbellek klasörleri alınmamalı")
	for f in EXPECTED_COPIES:
		assert_eq(FileAccess.get_md5(user_dir.path_join(f)), FileAccess.get_md5(legacy.path_join(f)), "Kopya birebir aynı olmalı: %s" % f)
	assert_true(UserDirMigration.is_done(user_dir), "Taşıma bitince işaret dosyası yazılmalı")
	assert_eq(_snapshot(data_root.path_join("Godot")), before, "Eski klasör, Tanhu 2D, Tanhu 2 ve Tanhu Ref değişmemeli")
	var marker := ConfigFile.new()
	assert_eq(marker.load(user_dir.path_join(UserDirMigration.MARKER_FILE)), OK, "İşaret dosyası okunmalı")
	assert_eq(str(marker.get_value("migration", "from", "")), legacy, "İşaret nereden kopyalandığını yazmalı")
	# Oyun kopyaları yeni klasörde okur: kayıtlar, küçük resim ve ayar.
	var moved := SaveSystem.new(user_dir)
	assert_true(moved.has_save(0) and moved.has_save(3), "Kopyalanan kayıtlar okunmalı")
	assert_eq(moved.latest_slot(), 0, "En son kayıt yine otomatik kayıt olmalı")
	assert_not_null(moved.load_thumb(0), "Kopyalanan küçük resim okunmalı")
	var s: Node = SettingsScript.new()
	s.path = user_dir.path_join(UserDirMigration.SETTINGS_FILE)
	assert_true(s.load_settings(), "Kopyalanan ayar okunmalı")
	assert_almost(s.camera_speed, 0.8, 0.0001)
	assert_eq(s.camera_follow, "tight")
	s.free()


func test_migration_runs_only_once() -> void:
	var dirs := _fake_data_dir()
	var legacy := dirs[0]
	var user_dir := dirs[1]
	assert_eq(UserDirMigration.migrate(legacy, user_dir).size(), EXPECTED_COPIES.size(), "İlk açılış kopyalamalı")
	# Oyuncu yeni klasörde otomatik kaydı siler; eski klasöre (eski bir sürümle oynanınca) yeni bir kayıt düşer.
	DirAccess.remove_absolute(user_dir.path_join("tanhu3_save_0.json"))
	_write_file(legacy.path_join("tanhu3_save_5.json"), JSON.stringify(_record(5, 5000.0)))
	var before := _snapshot(user_dir)
	assert_eq(UserDirMigration.migrate(legacy, user_dir).size(), 0, "İkinci açılışta yeniden taşınmamalı")
	assert_eq(_snapshot(user_dir), before, "İkinci açılış yeni klasöre dokunmamalı")
	assert_false(FileAccess.file_exists(user_dir.path_join("tanhu3_save_0.json")), "Silinen kayıt geri gelmemeli")
	assert_false(FileAccess.file_exists(user_dir.path_join("tanhu3_save_5.json")), "Eski klasöre sonradan düşen kayıt alınmamalı")


func test_migration_keeps_newer_files_and_skips_other_games_settings() -> void:
	var dirs := _fake_data_dir()
	var legacy := dirs[0]
	var user_dir := dirs[1]
	# Eski klasördeki settings.cfg başka bir oyunun (Tanhu 2D'nin biçimi): bu oyunun anahtarları yok.
	_write_cfg(legacy.path_join("settings.cfg"), TANHU_2D_SETTINGS)
	# Yeni klasörün 0. yuvasında daha yeni (resimsiz) bir kayıt var.
	DirAccess.make_dir_recursive_absolute(user_dir)
	var newer := JSON.stringify(_record(0, 9000.0))
	_write_file(user_dir.path_join("tanhu3_save_0.json"), newer)
	var copied := UserDirMigration.migrate(legacy, user_dir)
	assert_eq(_sorted(copied), _sorted(["tanhu3_save_3.json"]), "Yalnız yeni klasörde olmayan kayıt kopyalanmalı")
	assert_eq(FileAccess.get_file_as_string(user_dir.path_join("tanhu3_save_0.json")), newer, "Yeni klasördeki kayıt ezilmemeli")
	assert_false(FileAccess.file_exists(user_dir.path_join("tanhu3_thumb_0.png")), "Eski kaydın resmi yeni kayda eklenmemeli")
	assert_false(FileAccess.file_exists(user_dir.path_join("settings.cfg")), "Başka oyunun settings.cfg'si alınmamalı")
	assert_true(UserDirMigration.is_done(user_dir))
	# Tanhu 2'nin biçimi de bu oyunun ayarı sayılmaz.
	_write_cfg(legacy.path_join("settings.cfg"), TANHU_2_SETTINGS)
	assert_false(UserDirMigration.is_own_settings(legacy.path_join("settings.cfg")))


func test_migration_completes_an_interrupted_copy() -> void:
	var dirs := _fake_data_dir()
	var legacy := dirs[0]
	var user_dir := dirs[1]
	# Önceki açılış 0. yuvanın kaydını kopyalamış, resmini kopyalayamadan kesilmiş: işaret yazılmamış.
	DirAccess.make_dir_recursive_absolute(user_dir)
	assert_eq(DirAccess.copy_absolute(legacy.path_join("tanhu3_save_0.json"), user_dir.path_join("tanhu3_save_0.json")), OK)
	var copied := UserDirMigration.migrate(legacy, user_dir)
	assert_eq(_sorted(copied), _sorted(["settings.cfg", "tanhu3_save_3.json", "tanhu3_thumb_0.png"]),
		"Eksikler tamamlanmalı; kopyalanmış kayıt yeniden yazılmamalı, resmi eklenmeli")
	assert_eq(_files(user_dir), _sorted(EXPECTED_COPIES + [UserDirMigration.MARKER_FILE]))
	assert_true(UserDirMigration.is_done(user_dir), "Tamamlanınca işaret yazılmalı")


func test_migration_without_old_folder_marks_done_once() -> void:
	data_root = TempDir.fresh("tasima")
	_wipe_tree(data_root, false)
	var legacy := UserDirMigration.legacy_dir(data_root, "macOS")
	var user_dir := data_root.path_join(_user_dir_name())
	assert_eq(UserDirMigration.files_to_copy(legacy, user_dir).size(), 0)
	assert_eq(UserDirMigration.migrate(legacy, user_dir).size(), 0, "Eski klasör yoksa kopyalanacak bir şey yok")
	assert_true(UserDirMigration.is_done(user_dir), "Eski klasöre bir kez bakılır, işaret yazılır")
	assert_eq(_files(user_dir), _sorted([UserDirMigration.MARKER_FILE]), "Yeni klasöre yalnız işaret yazılmalı")
	assert_false(DirAccess.dir_exists_absolute(data_root.path_join("Godot")), "Eski klasör oluşturulmamalı")


func test_migration_never_writes_into_the_old_folder() -> void:
	var dirs := _fake_data_dir()
	var legacy := dirs[0]
	var before := _snapshot(data_root.path_join("Godot"))
	# use_custom_user_dir kapansa user:// eski klasörün kendisi olurdu: taşıma oraya işaret bile yazmamalı.
	for same: String in [legacy, legacy + "/", legacy.to_upper()]:
		assert_eq(UserDirMigration.migrate(legacy, same).size(), 0, "Klasör kendi üstüne kopyalanmamalı: %s" % same)
	assert_false(UserDirMigration.is_done(legacy), "Eski klasöre işaret yazılmamalı")
	assert_eq(_snapshot(data_root.path_join("Godot")), before, "Eski klasör değişmemeli")


# --- Taşıma testlerinin yardımcıları ------------------------------------------------------------------

## project.godot'daki özel klasör adı.
static func _user_dir_name() -> String:
	return str(ProjectSettings.get_setting("application/config/custom_user_dir_name", "")).strip_edges()


## Sahte veri klasörü kurar ve [eski klasör, yeni klasör] döndürür. Eski klasör Godot'nun varsayılanıdır
## (<kök>/Godot/app_userdata/Tanhu): bu oyunun iki kaydı (0 ve 3; 0'ın küçük resmi var), sahipsiz bir küçük
## resim (7), yarım kalmış geçici kayıt, yuva aralığının dışında bir kayıt, bu oyunun settings.cfg'si, günlük
## ve gölgelendirici önbelleği. Yanında Tanhu 2D, Tanhu 2 ve Tanhu Ref kendi kayıt ve ayarlarıyla durur.
## Yeni klasör (<kök>/<custom_user_dir_name>) henüz yoktur.
func _fake_data_dir() -> Array[String]:
	data_root = TempDir.fresh("tasima")
	_wipe_tree(data_root, false)
	var legacy := UserDirMigration.legacy_dir(data_root, "macOS")
	DirAccess.make_dir_recursive_absolute(legacy.path_join("logs"))
	DirAccess.make_dir_recursive_absolute(legacy.path_join("shader_cache/Forward"))
	_write_file(legacy.path_join("tanhu3_save_0.json"), JSON.stringify(_record(0, 2000.0), "\t"))
	_write_png(legacy.path_join("tanhu3_thumb_0.png"), Color.ORANGE)
	_write_file(legacy.path_join("tanhu3_save_3.json"), JSON.stringify(_record(2, 1000.0), "\t"))
	_write_png(legacy.path_join("tanhu3_thumb_7.png"), Color.RED)
	_write_file(legacy.path_join("tanhu3_save_1.json.tmp"), "{ yarım kalmış")
	_write_file(legacy.path_join("tanhu3_save_11.json"), JSON.stringify(_record(9)))
	_write_own_settings(legacy.path_join("settings.cfg"))
	_write_file(legacy.path_join("logs/godot.log"), "Godot Engine v4.7.2")
	_write_file(legacy.path_join("shader_cache/Forward/cache.bin"), "önbellek")
	var games := legacy.get_base_dir()
	for other in OTHER_GAME_DIRS:
		DirAccess.make_dir_recursive_absolute(games.path_join(other))
	_write_cfg(games.path_join("Tanhu 2D/settings.cfg"), TANHU_2D_SETTINGS)
	_write_file(games.path_join("Tanhu 2D/tanhu_save_0.json"), JSON.stringify({"perde": 2}))
	_write_png(games.path_join("Tanhu 2D/tanhu_thumb_0.png"), Color.BLUE)
	_write_cfg(games.path_join("Tanhu 2/settings.cfg"), TANHU_2_SETTINGS)
	_write_file(games.path_join("Tanhu 2/tanhu2_save_0.json"), JSON.stringify({"game": "tanhu2"}))
	_write_file(games.path_join("Tanhu Ref/tanhu_save_1.json"), JSON.stringify({"ref": true}))
	var out: Array[String] = [legacy, data_root.path_join(_user_dir_name())]
	return out


## Bu oyunun settings.cfg'si: GameSettings'in kendisi yazar (eski sürümün yazdığı gibi).
func _write_own_settings(path: String) -> void:
	var s: Node = SettingsScript.new()
	s.path = path
	s.persist = true
	s.apply_window = false
	s.camera_speed = 0.8
	s.camera_follow = "tight"
	assert_true(s.save_settings(), "Sahte ayar dosyası yazılmalı")
	s.free()


func _write_file(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		fail("Sahte dosya yazılamadı: %s" % path)
		return
	f.store_string(text)
	f.close()


static func _write_png(path: String, color: Color) -> void:
	var img := Image.create(32, 18, false, Image.FORMAT_RGB8)
	img.fill(color)
	img.save_png(path)


## Bölüm → {anahtar: değer} sözlüğünden bir settings.cfg.
static func _write_cfg(path: String, values: Dictionary) -> void:
	var cfg := ConfigFile.new()
	for section: String in values:
		var keys: Dictionary = values[section]
		for key: String in keys:
			cfg.set_value(section, key, keys[key])
	cfg.save(path)


## Klasör ağacının özeti: göreli yol → içeriğin md5'i ve değişme zamanı ("/" ile biten: alt klasör).
static func _snapshot(top: String) -> Dictionary:
	var out := {}
	_snapshot_into(top, "", out)
	return out


static func _snapshot_into(top: String, rel: String, out: Dictionary) -> void:
	var d := DirAccess.open(top.path_join(rel))
	if d == null:
		return
	d.include_hidden = true
	for sub in d.get_directories():
		out[rel.path_join(sub) + "/"] = true
		_snapshot_into(top, rel.path_join(sub), out)
	for f in d.get_files():
		var path := top.path_join(rel.path_join(f))
		out[rel.path_join(f)] = "%s|%d" % [FileAccess.get_md5(path), FileAccess.get_modified_time(path)]


## Klasördeki dosyaların (alt klasörler hariç) sıralı adları.
static func _files(path: String) -> Array[String]:
	var out: Array[String] = []
	var d := DirAccess.open(path)
	if d == null:
		return out
	d.include_hidden = true
	for f in d.get_files():
		out.append(f)
	out.sort()
	return out


## Ad listesi (Array ya da PackedStringArray), sıralı.
static func _sorted(names: Variant) -> Array[String]:
	var out: Array[String] = []
	for n in names:
		out.append(str(n))
	out.sort()
	return out


## Geçici klasörü alt klasörleriyle siler; remove_top ise klasörün kendisini de. Yalnız testlerin geçici
## klasöründe (tanhu3_tests) çalışır: oyuncunun klasörüne asla dokunmaz.
static func _wipe_tree(path: String, remove_top: bool = true) -> void:
	if not path.contains("tanhu3_tests"):
		return
	var d := DirAccess.open(path)
	if d == null:
		return
	d.include_hidden = true
	for sub in d.get_directories():
		_wipe_tree(path.path_join(sub))
	for f in d.get_files():
		DirAccess.remove_absolute(path.path_join(f))
	if remove_top:
		DirAccess.remove_absolute(path)
