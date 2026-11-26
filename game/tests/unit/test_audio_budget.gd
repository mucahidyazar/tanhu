extends TestCase
## Ses içe aktarma kuralı ve dünya başına ses bütçesi (K59; godot.md §3.3 ve §7.2, audio.md §4 «Bellek»).
##
## Godot sesi bellekte sıkıştırılmış tutar: WAV, QOA olarak durur; Ogg ve MP3 dosya olarak tutulur,
## çalarken çözülür. Bu yüzden bir sesin bellekteki payı içe aktarılan dosyasının boyudur (`.import`
## dosyasının `dest_files`'ı). Havuzlar dünya başınadır: müzik 16 MiB, efekt ve ortam 8 MiB,
## seslendirme 2 MiB; ayrı toplam tavanı yoktur, toplam havuzların toplamıdır (26 MiB). Destan Kitabı'nın tanıtım
## sesleri (`res://audio/vo/ency/`) kitap aynı anda tek tanıtım yüklediği için dünyada bir kez, en büyüğüyle sayılır.
## Ortam döngüleri (`res://audio/ambience/`) 22,05 kHz mono QOA içe aktarılır ve döngüleri yeni
## örnekleme hızında da bütün dosyayı kapsar. QOA kayıplıdır; ortam için kabul edildi (K59).

const MIB := 1024 * 1024
## Havuz tavanları, bayt (K59).
const POOL_CAPS := {
	&"music": 16 * MIB,
	&"sfx": 8 * MIB,
	&"voice": 2 * MIB,
}
## Havuzların hata iletisindeki adı.
const POOL_NAMES := {
	&"music": "müzik",
	&"sfx": "efekt ve ortam",
	&"voice": "seslendirme",
}
## Dünya başına toplam: havuzların toplamı.
const WORLD_CAP := 26 * MIB
## Ortam döngülerinin klasörü (alt klasörleri dahil) ve en yüksek örnekleme hızı (Hz).
const AMBIENCE_DIR := "res://audio/ambience/"
const AMBIENCE_MAX_RATE := 22050
## Ses dosyalarının uzantıları ve içe aktarıcıları (`.import` dosyasının `[remap]` bölümündeki `importer`).
const SOUND_EXTENSIONS: Array[String] = ["wav", "ogg", "mp3"]
const SOUND_IMPORTERS: Array[String] = ["wav", "mp3", "oggvorbisstr"]
## `compress/mode`: 0 PCM, 1 IMA ADPCM, 2 Quite OK Audio (QOA).
const COMPRESS_QOA := 2
## `edit/loop_mode`: 0 WAV'dan oku, 1 kapalı, 2 ileri, 3 git-gel, 4 geri (AudioStreamWAV.LoopMode + 1).
const IMPORT_LOOP_FORWARD := 2
## Mono QOA'da 5.120 örneklik çerçeve 2.072 bayttır (8 başlık + 16 LMS durumu + 256 dilim × 8):
## 22,05 kHz'de saniyede ≈8,7 KiB (audio.md «≈9 KB/sn»).
const QOA_MONO_BYTES_PER_SAMPLE := 2072.0 / 5120.0
## İçe aktarılan dosyanın kaynak üstbilgisi ve yarım kalan son çerçeve için pay (bayt).
const IMPORT_OVERHEAD := 4096
## Destan Kitabı'nın tanıtım sesleri (K86, godot.md §3.8): kitap aynı anda tek tanıtım yükler, bu yüzden klasör
## dünyanın listesinde tek dosya, en büyüğüyle sayılır.
const BOOK_INTRO_DIR := "res://audio/vo/ency/"
## Oyunun kodu ve sahneleri: buralarda adı geçen her ses bütçede sayılmalı.
const CODE_DIRS: Array[String] = ["res://scripts", "res://scenes"]
const CODE_EXTENSIONS: Array[String] = ["gd", "tscn", "tres"]

## Kaynak WAV'ların süresi (saniye; yol → süre). Kaynağı çözmek pahalı, her dosya bir kez çözülür.
var _source_lengths := {}


# --- Ortam döngüleri -----------------------------------------------------------------

func test_ambience_loops_import_as_22khz_mono_qoa() -> void:
	var loops := _ambience_loops()
	assert_false(loops.is_empty(), "%s altında içe aktarılmış ortam döngüsü bulunamadı" % AMBIENCE_DIR)
	for path in loops:
		var params := _import_params(path)
		assert_eq(params.get("force/mono"), true, "%s: force/mono açık olmalı" % path)
		assert_eq(params.get("force/max_rate"), true, "%s: force/max_rate açık olmalı" % path)
		assert_between(float(params.get("force/max_rate_hz", 0)), 1.0, AMBIENCE_MAX_RATE,
				"%s: force/max_rate_hz en çok 22.050 olmalı" % path)
		assert_eq(params.get("compress/mode"), COMPRESS_QOA, "%s: QOA ile sıkıştırılmalı (compress/mode = 2)" % path)
		# Ayar kadar sonuç da: içe aktarılan dosya bu ayarla üretilmiş olmalı.
		var wav := _load_imported(path)
		if wav == null:
			continue
		assert_false(wav.stereo, "%s mono içe aktarılmalı" % path)
		assert_between(float(wav.mix_rate), 1.0, AMBIENCE_MAX_RATE, "%s en çok 22,05 kHz olmalı" % path)
		assert_eq(wav.format, AudioStreamWAV.FORMAT_QOA, "%s QOA olmalı" % path)


func test_ambience_loops_take_the_ruled_size() -> void:
	# Kuralın kazancı dosya boyunda görünür: gece çayırı stereo 44,1 kHz'de 1,07 MB'tı, 22,05 kHz
	# mono QOA'da ≈0,27 MB'tır (saniyede ≈8,7 KiB).
	for path in _ambience_loops():
		var seconds := _source_seconds(path)
		var limit := ceili(seconds * AMBIENCE_MAX_RATE * QOA_MONO_BYTES_PER_SAMPLE) + IMPORT_OVERHEAD
		var bytes := _imported_bytes(path)
		assert_between(float(bytes), 1.0, float(limit), "%s: içe aktarılan %.2f MB; %.1f sn 22,05 kHz mono QOA ile en çok %.2f MB"
				% [path, bytes / 1e6, seconds, limit / 1e6])


func test_ambience_loops_loop_the_whole_file_at_the_new_rate() -> void:
	# Döngü içe aktarmada açılır: ileri, baş 0, son -1 (dosyanın sonu). Godot 4.7 açık döngü
	# noktalarını örnekleme hızı düştükten sonra, yeni hızın karesiyle okur: kaynağın 44,1 kHz kare
	# sayısı yazılırsa döngü yanlış yerde biter; -1 her hızda dosyanın sonudur. Çalarken
	# AudioUtil.enable_loop aynı döngüyü yeniden kurar; içe aktarılan hâl onsuz da döner.
	for path in _ambience_loops():
		assert_eq(_import_params(path).get("edit/loop_mode"), IMPORT_LOOP_FORWARD,
				"%s: döngü içe aktarmada ileri açılmalı (edit/loop_mode = 2)" % path)
		var wav := _load_imported(path)
		if wav == null:
			continue
		var frames := roundi(wav.get_length() * wav.mix_rate)
		assert_eq(wav.loop_mode, AudioStreamWAV.LOOP_FORWARD, "%s döngüde çalmalı" % path)
		assert_eq(wav.loop_begin, 0, "%s: döngü dosyanın başından başlamalı" % path)
		# -1, Godot'da son kareyi dışarıda bırakır (frames - 1); bir kare (45 µs) duyulmaz.
		assert_between(float(wav.loop_end), float(frames - 1), float(frames),
				"%s: döngü yeni hızda dosyanın sonunda bitmeli (%d kare)" % [path, frames])
		# Hız düşünce süre değişmez: ses kaymaz, perde ve döngünün uzunluğu aynı kalır.
		assert_almost(wav.get_length(), _source_seconds(path), 2.0 / AMBIENCE_MAX_RATE,
				"%s: içe aktarma sesin süresini değiştirmemeli" % path)


# --- Dünya başına bütçe ----------------------------------------------------------------

func test_world_audio_fits_the_pools() -> void:
	var worlds := _world_sounds()
	for world: StringName in worlds:
		var sounds: PackedStringArray = worlds[world]
		assert_false(sounds.is_empty(), "%s dünyasında hiç ses bulunamadı" % world)
		var totals := {}
		var sizes := {}
		for pool: StringName in POOL_CAPS:
			totals[pool] = 0
			sizes[pool] = []
		for path in sounds:
			var bytes := _imported_bytes(path)
			if bytes <= 0:
				fail("%s: içe aktarılan dosyası yok ya da boş (.import'un dest_files'ı)" % path)
				continue
			var pool := _pool_of(path)
			totals[pool] += bytes
			sizes[pool].append([bytes, path])
		var total := 0
		for pool: StringName in POOL_CAPS:
			total += totals[pool]
			assert_true(totals[pool] <= POOL_CAPS[pool], "%s dünyasında %s havuzu %.2f MiB, tavan %d MiB; en büyükleri: %s"
					% [world, POOL_NAMES[pool], totals[pool] / float(MIB), POOL_CAPS[pool] / MIB, _largest(sizes[pool])])
		assert_true(total <= WORLD_CAP, "%s dünyasında ses %.2f MiB, tavan %d MiB" % [world, total / float(MIB), WORLD_CAP / MIB])


func test_every_sound_named_in_code_is_counted() -> void:
	# Bütçe içe aktarılmış sesleri sayar. Kodun adını verdiği ses içe aktarılmamışsa (yanlış yol,
	# `.gdignore`'lu klasör) oyunda sessizce çalmaz ve bütçenin dışında kalır.
	var counted := {}
	for sounds: PackedStringArray in _world_sounds().values():
		for path in sounds:
			counted[path] = true
	var named := _sounds_named_in_code()
	assert_false(named.is_empty(), "Oyunun betiklerinde ve sahnelerinde hiç ses yolu bulunamadı")
	for path in named:
		assert_true(counted.has(path), "%s kodda geçiyor ama hiçbir dünyanın ses listesinde yok (dosya yok ya da içe aktarılmamış)" % path)


func test_book_intros_count_once_with_the_largest() -> void:
	# Kitap aynı anda tek tanıtım yükler (EncyclopediaPage): klasördeki onlarca dosya dünyanın listesine bir kez,
	# en büyüğüyle girer; geri kalanı listede yoktur.
	var intros := PackedStringArray()
	for path in _project_sounds():
		if path.begins_with(BOOK_INTRO_DIR):
			intros.append(path)
	var counted := PackedStringArray()
	for path in (_world_sounds()[&"camp"] as PackedStringArray):
		if path.begins_with(BOOK_INTRO_DIR):
			counted.append(path)
	if intros.is_empty():
		assert_eq(counted.size(), 0)
		return
	assert_eq(counted.size(), 1, "Tanıtım sesleri tek dosya sayılmalı (%d dosya var)" % intros.size())
	var largest := 0
	for path in intros:
		largest = maxi(largest, _imported_bytes(path))
	assert_eq(_imported_bytes(counted[0]), largest, "Sayılan tanıtım en büyüğü olmalı: %s" % counted[0])
	var lone := _book_counts_once(PackedStringArray(["res://audio/vo/prologue/a.mp3"]))
	assert_eq(lone, PackedStringArray(["res://audio/vo/prologue/a.mp3"]), "Tanıtım yokken liste değişmez")


func test_pool_rules() -> void:
	assert_eq(_pool_of("res://audio/music/menu_theme.mp3"), &"music")
	assert_eq(_pool_of("res://audio/gen/camp_drone.ogg"), &"music", "Araçla basılan müzik (tools/bake_music.gd)")
	assert_eq(_pool_of("res://audio/vo/prologue/act0.myth.3.mp3"), &"voice")
	assert_eq(_pool_of("res://audio/vo/ency/erlik.mp3"), &"voice", "Destan Kitabı'nın tanıtım sesi")
	assert_eq(_pool_of("res://audio/ambience/night_meadow_loop.wav"), &"sfx")
	assert_eq(_pool_of("res://audio/sfx/horse_snort.wav"), &"sfx")
	assert_eq(_pool_of("res://assets/ui/sfx/page_turn.ogg"), &"sfx", "Arayüz sesi Ogg da olsa efekttir")


# --- Yardımcılar -------------------------------------------------------------------------

## Dünyaların ses listesi (dünya → içe aktarılmış ses yolları). Bugün tek dünya kamptır (menü,
## Serbest Gez, Ev; godot.md §4.1) ve projedeki her ses orada yüklenebilir: kampın listesi projedeki
## bütün seslerdir, yani üst sınırdır. İç haritalar gelince her dünya kendi listesini `MapSpec`'in
## ses profilinden getirir (§4.2); bu işlev o zaman profilleri okur. Destan Kitabı her dünyada açılır ve aynı
## anda tek tanıtım yükler: tanıtım sesleri listeye bir kez, en büyüğüyle girer.
static func _world_sounds() -> Dictionary:
	var sounds := _book_counts_once(_project_sounds())
	var camp := PackedStringArray()
	var bridges := PackedStringArray()
	var childhood := PackedStringArray()
	var depart := PackedStringArray()
	var days := {}
	for key: StringName in DAY_VOICE_PREFIXES:
		days[key] = PackedStringArray()
	for path in sounds:
		var day := _day_of(path)
		if day != &"":
			var list: PackedStringArray = days[day]
			list.append(path)
			days[day] = list
		elif path.begins_with(BRIDGE_PREFIX):
			bridges.append(path)
		elif path.begins_with(CHILDHOOD_PREFIX) or _is_e21_childhood_sound(path):
			childhood.append(path)
		elif path.begins_with(DEPART_PREFIX):
			depart.append(path)
		else:
			camp.append(path)
	# Köprüler (N1–N7) kendi sinemasıdır: CineHost dizinin satırlarını ister, bitince bırakır; Önsöz'le aynı anda yüklü olmazlar.
	# Çocukluk'un ve Yola Çıkış'ın sözleri (E20/7) kendi küçük dünyalarındadır (childhood_ordos, depart_yurt): kamp o sırada bırakılmıştır.
	# E21 (K110): Önsöz'ün ve Çocukluk'un yeni günleri sözlerini gün gün yükler (her gün kendi sahne dosyasıdır), seslendirme havuzu gün başınadır.
	var out := {&"camp": camp, &"bridges": bridges, &"childhood": childhood, &"depart": depart}
	for key: StringName in days:
		out[key] = days[key]
	return out


## Satır bir E21 gününün sözüyse o günün adı, değilse boş.
static func _day_of(path: String) -> StringName:
	for key: StringName in DAY_VOICE_PREFIXES:
		for prefix: String in DAY_VOICE_PREFIXES[key]:
			if path.begins_with(VOICE_DIR + prefix):
				return key
	return &""


## E21'in Çocukluk'ta (childhood_ordos) çalan sesi mi; audio/*/e21'in kalanı Önsöz'ün günlerinindir (kamp).
static func _is_e21_childhood_sound(path: String) -> bool:
	if not path.contains("/e21/"):
		return false
	var file := path.get_file()
	for prefix: String in E21_CHILDHOOD_SOUNDS:
		if file.begins_with(prefix):
			return true
	return false


const VOICE_DIR := "res://audio/vo/prologue/"
## E21 (K110): günlerin sözleri (önek, `act0-text.md`).
const DAY_VOICE_PREFIXES := {
	&"prologue_day1": ["act0.milk.", "act0.storm."],
	&"prologue_day2": ["act0.lambs.", "act0.feast.", "act0.wrestle."],
	&"prologue_day3": ["act0.hearth."],
	&"childhood_day1": ["act0.flock.", "act0.bone."],
	&"childhood_day2": ["act0.tally."],
}
## E21'in Çocukluk'ta çalan ortam ve efektleri (`docs/design/d3/e21-atmosphere.md`).
const E21_CHILDHOOD_SOUNDS: Array[String] = ["amb_ordos_", "amb_reed_lake", "amb_moon_night", "amb_dailin_far", "amb_ebe_camp",
	"amb_child_swim", "sfx_sheep_bell_", "sfx_wade_", "sfx_dive_up", "sfx_kids_laugh_", "sfx_mud_pull", "sfx_fox_bark", "sfx_bone_land",
	"sfx_post_slap", "sfx_child_pant", "sfx_dogs_guard_", "sfx_dog_settle"]


## Listedeki tanıtım seslerini (BOOK_INTRO_DIR) en büyüklerine indirir; öteki sesler aynen kalır.
static func _book_counts_once(sounds: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()
	var largest := ""
	var largest_bytes := -1
	for path in sounds:
		if not path.begins_with(BOOK_INTRO_DIR):
			out.append(path)
			continue
		var bytes := _imported_bytes(path)
		if bytes > largest_bytes:
			largest = path
			largest_bytes = bytes
	if not largest.is_empty():
		out.append(largest)
		out.sort()
	return out


## Köprü satırlarının dosyaları (K36; act0-text.md «Köprüler»).
const BRIDGE_PREFIX := "res://audio/vo/prologue/act0.narr."
## Oynanan sahnelerin sözleri (E20/7; SceneVoice): Çocukluk ve Yola Çıkış.
const CHILDHOOD_PREFIX := "res://audio/vo/prologue/act0.child."
const DEPART_PREFIX := "res://audio/vo/prologue/act0.depart."


## Sesin havuzu: seslendirme `audio/vo/`; müzik `audio/music/` ve araçla basılan `audio/gen/`
## (godot.md §3.3); gerisi (ortam, efekt, arayüz) efekt ve ortam havuzundadır.
static func _pool_of(path: String) -> StringName:
	if path.begins_with("res://audio/vo/"):
		return &"voice"
	if path.begins_with("res://audio/music/") or path.begins_with("res://audio/gen/"):
		return &"music"
	return &"sfx"


## Projedeki içe aktarılmış bütün sesler (`.import`'unda bir ses içe aktarıcısı olan ses dosyaları).
## Gizli klasörler (.godot), `.gdignore`'lu klasörler ve testler sayılmaz.
static func _project_sounds() -> PackedStringArray:
	var found := PackedStringArray()
	for file in _files_under(["res://"], SOUND_EXTENSIONS):
		var cfg := _import_cfg(file)
		if cfg and SOUND_IMPORTERS.has(str(cfg.get_value("remap", "importer", ""))):
			found.append(file)
	found.sort()
	return found


## Ortam döngüleri: ortam klasörünün altındaki içe aktarılmış WAV'lar.
static func _ambience_loops() -> PackedStringArray:
	var loops := PackedStringArray()
	for path in _project_sounds():
		if path.begins_with(AMBIENCE_DIR) and path.get_extension() == "wav":
			loops.append(path)
	return loops


## Oyunun betiklerinde ve sahnelerinde tırnak içinde geçen ses yolları.
static func _sounds_named_in_code() -> PackedStringArray:
	var pattern := RegEx.create_from_string("\"(res://[^\"]+\\.(?:%s))\"" % "|".join(PackedStringArray(SOUND_EXTENSIONS)))
	var named := PackedStringArray()
	for file in _files_under(CODE_DIRS, CODE_EXTENSIONS):
		for found in pattern.search_all(FileAccess.get_file_as_string(file)):
			var path := found.get_string(1)
			if not named.has(path):
				named.append(path)
	named.sort()
	return named


## Klasörlerin altındaki (alt klasörler dahil) verilen uzantılı dosyalar. Gizli klasörler,
## `.gdignore`'lu klasörler ve testler atlanır.
static func _files_under(roots: Array[String], extensions: Array[String]) -> PackedStringArray:
	var files := PackedStringArray()
	var stack: Array[String] = roots.duplicate()
	while not stack.is_empty():
		var dir: String = stack.pop_back()
		if FileAccess.file_exists(dir.path_join(".gdignore")):
			continue
		for sub in DirAccess.get_directories_at(dir):
			var sub_path := dir.path_join(sub)
			if not sub.begins_with(".") and sub_path != "res://tests":
				stack.append(sub_path)
		for file in DirAccess.get_files_at(dir):
			if extensions.has(file.get_extension()):
				files.append(dir.path_join(file))
	return files


## Sesin `.import` dosyası (yoksa null).
static func _import_cfg(path: String) -> ConfigFile:
	var cfg := ConfigFile.new()
	return cfg if cfg.load(path + ".import") == OK else null


## `.import` dosyasının `[params]` bölümü (dosya yoksa boş).
static func _import_params(path: String) -> Dictionary:
	var params := {}
	var cfg := _import_cfg(path)
	if cfg and cfg.has_section("params"):
		for key in cfg.get_section_keys("params"):
			params[key] = cfg.get_value("params", key)
	return params


## İçe aktarılan dosyaların (`dest_files`) toplam boyu, bayt. `.import` ya da dosya yoksa -1.
static func _imported_bytes(path: String) -> int:
	var cfg := _import_cfg(path)
	if cfg == null:
		return -1
	var dest: Array = cfg.get_value("deps", "dest_files", [])
	if dest.is_empty():
		return -1
	var total := 0
	for file: String in dest:
		if not FileAccess.file_exists(file):
			return -1
		total += FileAccess.open(file, FileAccess.READ).get_length()
	return total


## En büyük beş dosya, «ad boy» biçiminde ([[bayt, yol], ...] listesinden).
static func _largest(entries: Array) -> String:
	var sorted := entries.duplicate()
	sorted.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var parts := PackedStringArray()
	for entry: Array in sorted.slice(0, 5):
		parts.append("%s %.2f MiB" % [String(entry[1]).get_file(), entry[0] / float(MIB)])
	return ", ".join(parts)


## İçe aktarılan sesi önbelleği atlayarak yükler: AudioUtil.enable_loop ortak kaynağın döngüsünü
## çalışırken değiştirir; önbellekteki kopya içe aktarılan hâli göstermeyebilir.
func _load_imported(path: String) -> AudioStreamWAV:
	var wav := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as AudioStreamWAV
	assert_not_null(wav, "%s WAV olarak yüklenemedi" % path)
	return wav


## Kaynak WAV'ın süresi (saniye): dosya içe aktarıcının seçenekleri olmadan, kendi hızında çözülür.
func _source_seconds(path: String) -> float:
	if not _source_lengths.has(path):
		var source := AudioStreamWAV.load_from_file(path)
		assert_not_null(source, "%s kaynağı okunamadı" % path)
		_source_lengths[path] = source.get_length() if source else 0.0
	return _source_lengths[path]
