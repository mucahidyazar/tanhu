class_name UserDirMigration
extends RefCounted
## Kayıt ve ayar klasörünün eski yerinden tek seferlik kopyalanması (K30).
##
## user:// eskiden Godot'nun varsayılanıydı ve proje adından gelirdi: <veri>/Godot/app_userdata/Tanhu
## (macOS'ta ~/Library/Application Support/Godot/app_userdata/Tanhu). Proje adı bir daha değişince oyun
## eski kaydı ve ayarı bulamasın diye project.godot klasörü sabitler: application/config/use_custom_user_dir
## ve custom_user_dir_name (macOS'ta ~/Library/Application Support/Tanhu Bozkir Destani). Adı eski
## klasörlerden ve proje adından ayrıdır; ~/Library/Application Support/Tanhu başka bir projenindir.
##
## Oyuncunun ilk açılışında eski klasörden yalnız bu oyunun dosyaları KOPYALANIR: kaydı olan yuvaların
## tanhu3_save_N.json'u ve tanhu3_thumb_N.png'si, bu oyunun anahtarlarını taşıyan settings.cfg. Eski klasör
## yalnız okunur, dosyalar orada da kalır; günlükler, gölgelendirici önbelleği ve başka dosyalar alınmaz.
## Yanındaki Tanhu 2D, Tanhu 2 ve Tanhu Ref klasörlerine hiç bakılmaz. Taşıma bitince yeni klasöre işaret
## dosyası (MARKER_FILE) yazılır: ikinci açılışta yeniden taşınmaz.
##
## GameSettings yalnız oyuncunun gerçek açılışında, settings.cfg'yi okumadan önce run_for_player()'ı çağırır;
## geliştirme ve test koşuları taşımaz. Testler sahte klasörlerle migrate(eski, yeni) çağırır.

## Eski klasörün adı: use_custom_user_dir açılmadan önce Godot klasörü proje adından (config/name) kuruyordu.
const LEGACY_APP_NAME := "Tanhu"
## Taşıma bitince yeni klasöre yazılır (nereden, hangi dosyalar, ne zaman); durdukça taşıma bir daha yapılmaz.
const MARKER_FILE := "legacy_migration.cfg"
const SETTINGS_FILE := "settings.cfg"
## settings.cfg'nin bu oyunun olduğunu gösteren anahtarlar (bölüm → anahtarlar). Tanhu 2D ve Tanhu 2'nin
## settings.cfg'sinde [game] bölümü yoktur. Eski sürümlerin yazdığı dosyayı tanır: GameSettings'in bugünkü
## anahtarlarından bağımsız tutulur.
const SETTINGS_KEYS := {"game": ["camera_speed", "camera_follow"]}


## Oyuncunun gerçek açılışı (GameSettings çağırır): eski klasörden user:// klasörüne bir kez kopyalar.
## Kopyalanan dosyaların adlarını döndürür (taşıma daha önce yapıldıysa ya da alınacak dosya yoksa boş).
static func run_for_player() -> PackedStringArray:
	var copied := migrate(legacy_dir(OS.get_data_dir(), OS.get_name()), OS.get_user_data_dir())
	if not copied.is_empty():
		print("Eski kayıt klasöründen kopyalandı: %s" % ", ".join(copied))
	return copied


## Godot'nun varsayılan klasörü (use_custom_user_dir kapalıyken): <veri>/Godot/app_userdata/Tanhu.
## data_dir OS.get_data_dir()'dir (macOS'ta ~/Library/Application Support, Windows'ta %APPDATA%, Linux'ta
## ~/.local/share); Linux ve BSD'de Godot'nun klasörü küçük harflidir.
static func legacy_dir(data_dir: String, os_name: String) -> String:
	var godot_dir := "godot" if os_name in ["Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD"] else "Godot"
	return data_dir.path_join(godot_dir).path_join("app_userdata").path_join(LEGACY_APP_NAME)


## Bu klasörde taşıma yapıldı mı (işaret dosyası var mı)?
static func is_done(user_dir: String) -> bool:
	return FileAccess.file_exists(_absolute(user_dir).path_join(MARKER_FILE))


## settings.cfg bu oyunun mu? Okunabilmeli ve SETTINGS_KEYS'in hepsini taşımalı.
static func is_own_settings(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return false
	for section: String in SETTINGS_KEYS:
		for key: String in SETTINGS_KEYS[section]:
			if not cfg.has_section_key(section, key):
				return false
	return true


## Eski klasörden kopyalanacak dosyaların adları, yuva yuva: eski klasörde kaydı olan, yeni klasörde kaydı
## olmayan her yuvanın kaydı ve (varsa) küçük resmi; yeni klasörde ayar yoksa ve eskisi bu oyununsa
## settings.cfg. Yeni klasördeki dosya ezilmez: yuvada başka (oyuncunun daha yeni) bir kayıt varsa eski resim
## de alınmaz; birebir aynı kayıt varsa yarıda kalmış bir önceki taşımanın kopyasıdır, eksik resmi tamamlanır.
## Sahipsiz küçük resim, yarım kalmış geçici dosya, günlük, önbellek ve başka hiçbir dosya alınmaz.
static func files_to_copy(legacy: String, user_dir: String) -> PackedStringArray:
	var from := _absolute(legacy)
	var to := _absolute(user_dir)
	var out := PackedStringArray()
	if not DirAccess.dir_exists_absolute(from):
		return out
	for slot in range(SaveSystem.AUTO_SLOT, SaveSystem.SLOTS + 1):
		var save_file := SaveSystem.FILE_PATTERN % slot
		var save_from := from.path_join(save_file)
		var save_to := to.path_join(save_file)
		if not FileAccess.file_exists(save_from):
			continue
		if not FileAccess.file_exists(save_to):
			out.append(save_file)
		elif FileAccess.get_md5(save_to) != FileAccess.get_md5(save_from):
			continue
		var thumb_file := SaveSystem.THUMB_PATTERN % slot
		if FileAccess.file_exists(from.path_join(thumb_file)) and not FileAccess.file_exists(to.path_join(thumb_file)):
			out.append(thumb_file)
	if not FileAccess.file_exists(to.path_join(SETTINGS_FILE)) and is_own_settings(from.path_join(SETTINGS_FILE)):
		out.append(SETTINGS_FILE)
	return out


## Eski klasörden yeni klasöre bir kez kopyalar; kopyalanan dosyaların adlarını döndürür.
## Taşıma daha önce yapıldıysa (işaret dosyası) ya da iki klasör aynıysa hiçbir şey yapmaz. Eski klasör yalnız
## okunur. Her dosya önce geçici adla yazılıp yerine konur: yarıda kesilen kopya yarım kayıt bırakmaz.
## Hepsi kopyalanınca (eski klasör yoksa da) işaret dosyası yazılır; bir dosya kopyalanamazsa yazılmaz,
## sonraki açılış eksikleri yeniden dener (kopyalanmış olanlar yeni klasörde olduğu için atlanır).
static func migrate(legacy: String, user_dir: String) -> PackedStringArray:
	var from := _absolute(legacy)
	var to := _absolute(user_dir)
	var copied := PackedStringArray()
	if _same_dir(from, to) or is_done(to):
		return copied
	if not DirAccess.dir_exists_absolute(to) and DirAccess.make_dir_recursive_absolute(to) != OK:
		return copied
	var complete := true
	for file_name in files_to_copy(from, to):
		if _copy(from.path_join(file_name), to.path_join(file_name)):
			copied.append(file_name)
		else:
			complete = false
	if complete:
		_write_marker(to, from, copied)
	return copied


# --- İç işler ------------------------------------------------------------------------------

static func _copy(from_path: String, to_path: String) -> bool:
	var tmp := to_path + ".tmp"
	if DirAccess.copy_absolute(from_path, tmp) == OK and DirAccess.rename_absolute(tmp, to_path) == OK:
		return true
	if FileAccess.file_exists(tmp):
		DirAccess.remove_absolute(tmp)
	return false


static func _write_marker(user_dir: String, legacy: String, copied: PackedStringArray) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("migration", "from", legacy)
	cfg.set_value("migration", "copied", copied)
	cfg.set_value("migration", "at", Time.get_datetime_string_from_system())
	cfg.save(user_dir.path_join(MARKER_FILE))


## Aynı klasör mü? macOS ve Windows'ta büyük-küçük harf ayrımı yoktur; ayrımlı Linux'ta da emin tarafta kalır.
static func _same_dir(a: String, b: String) -> bool:
	return a.simplify_path().trim_suffix("/").to_lower() == b.simplify_path().trim_suffix("/").to_lower()


static func _absolute(path: String) -> String:
	return ProjectSettings.globalize_path(path) if path.begins_with("user://") else path
