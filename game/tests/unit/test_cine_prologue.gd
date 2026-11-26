extends TestCase
## Önsöz'ün bütünü «Kopuz Söyler» (Yol Haritası opening-cinematic, prologue-p4; K68; story.md §3–§4, godot.md §3.6
## ve §8.4): data/cine/prologue.json kamp, mit ve doğum segmentlerini CineHost'ta sırayla oynatır.
##   - Çizelge: toplam 4 dk 19 sn ± 15 sn (dizinin target'ı) tahmini sürelerle, oyunun okuduğu seconds'la ve
##     dosyaların gerçek süresiyle (dosyası olan satırda dosyanın süresi, olmayanda tahmin); tahminle segment sınırları
##     0:38,9 / 3:22,2 / 4:08,7 / 4:18,7 (±0,1; şarkı çekim 3104); şarkı kamera durunca 0:06,0'da; şarkıdan sonra 3 + 2 + 1 sn;
##     konuşmacılar (şarkı ve mit 3–25 ozan, doğum 12 anlatıcı, Hereka'nın sözü Hereka); aynı sahnedeki iki satır arası ≥1,5 sn; tek kara
##     sessizlik (doğumda 2,5 sn), tek koro (tengri), iki alçak sessizlik; childhood_ordos mit sineması başlarken istenir,
##     doğumun çakışmasından önce örneklenir; kamp kara ekranda bırakılır; satırlar gerçek süreleriyle uzayınca sonraki işaretler
##     aynı payla kayar.
##   - Akış (gerçek ana sahne ve AudioManager; Engine.time_scale ve sinema hızıyla hızlı): Yeni Oyun → Önsöz sonuna dek
##     (childhood_ordos geçişten önce hazırdır: doğum dünyasını beklemez) → oluşturucu (prologue_seen yazılır) → vazgeç
##     → menü; ikinci Yeni Oyun varsayılanla atlar, «Her yeni oyunda» açıkken yeniden oynar ve her banka ilk
##     oynatmadaki düzeyinden başlar; basılı Esc kampta, mitte ve doğumda ayrı ayrı atlar. Her dönüşte menü karesinin
##     başsız karşılığı Önsöz öncesinin anlık görüntüsüyle aynıdır: kamp dünyası, gök ve su tekdüzenleri, sis, menü
##     kamerası, ateş başı (CampNpcs) ve ses (çalan müzik ve ortam, katmanlar, yolların düzeyi). Pencereli karşılaştırma
##     (tests/refs/menu.png) araçladır: docs/testler.md «Menü karesi».
## Görüntünün ve sesin son onayı kullanıcınındır (göz ve kulak; Karar Bekleyenler).
## Keçe yolu sınanır (K93): CineVideo.enabled kapalıdır, gerçek video dosyası geldiğinde de bu sınamalar keçeyi kurar; video kipi test_cine_video.gd'de.

const TempDir := preload("res://tests/support/temp_dir.gd")
const PROLOGUE := "res://data/cine/prologue.json"
const CAMP_SEGMENT := "res://data/cine/prologue_camp.json"
const MYTH_SEGMENT := "res://data/cine/prologue_myth.json"
const BIRTH_SEGMENT := "res://data/cine/prologue_birth.json"
const ORDOS := "res://scenes/maps/childhood_ordos.tscn"
const MAIN_SCENE := "res://scenes/main.tscn"
const MAIN_SCRIPT := "res://scripts/main.gd"
const SONG := "act0.bard.song"
const SEGMENTS: Array[String] = ["camp", "myth", "birth"]
## Segmentlerin sahnesi, dünyası ve görünümü (godot.md §3.6 tablosu).
const SEGMENT_SETUP := {
	"camp": [CAMP_SEGMENT, "res://scenes/cine/prologue_camp.tscn", "camp", "main"],
	"myth": [MYTH_SEGMENT, "res://scenes/cine/prologue_myth.tscn", "none", "overlay"],
	"birth": [BIRTH_SEGMENT, "res://scenes/cine/prologue_birth.tscn", ORDOS, "main"],
}
## Önsöz'ün satırları sırayla ve konuşmacıları (story.md §3 «Satırlar»): şarkı (1–2) ve mit (3–25) ozanın, doğum (12) anlatıcının.
const LINES: Array[String] = ["act0.bard.song", "act0.myth.3", "act0.myth.4", "act0.myth.5", "act0.myth.6",
	"act0.myth.7", "act0.myth.8", "act0.myth.9", "act0.myth.10", "act0.myth.11", "act0.myth.12", "act0.myth.13", "act0.myth.14",
	"act0.myth.15", "act0.myth.16", "act0.myth.17", "act0.myth.18", "act0.myth.19", "act0.myth.20", "act0.myth.21", "act0.myth.22",
	"act0.myth.23", "act0.myth.24", "act0.myth.25", "act0.birth.12", "act0.birth.hereka"]
const SONG_VERSES: Array[String] = ["act0.bard.1", "act0.bard.2"]
## Hedef (story.md §3): 4 dk 19 sn ± 15 sn; tahminle 4:18,7 (şarkı çekim 3104, 26,853 sn; mit E13 ile yeniden yazıldı, ≈2:43).
const TARGET := 259.0
const TARGET_TOLERANCE := 15.0
const ESTIMATED_TOTAL := 258.7
const MARK_TOLERANCE := 0.1
## Tahmini sürelerle sınırlar (mutlak sn): kamp → mit → doğum → Çocukluk'a geçiş → son.
const BOUNDS := {"myth": 38.9, "birth": 202.2, "birth:panel_8": 248.7, "birth_end": 258.7}
## Köz çakışması: doğum mitin son 1,5 sn'sinde kurulur (3:20,7).
const CROSSFADE := 1.5
const BIRTH_ENTER := 200.7
## Satırlar arasında kopuzun cevabı için en az (story.md §3 «Söz»).
const LINE_GAP := 1.5
## Akış: Engine.time_scale (bekçinin saati de bu oranla akar) × sinemanın hızı. Doğumdan önceki pencere (pano 6 →
## doğumun çakışması) gerçek oynatmadan sıkı sınanır: sinema orada SLOW_SPEED × TIME_SCALE = gerçeğin 4 katı akar.
const TIME_SCALE := 2.0
const CINE_SPEED := 30.0
const SLOW_SPEED := 2.0
## Menüye dönünce seslerin ve perdelerin oturması (ölçekli sn; en uzun geçiş menü müziğinin 2 sn'si).
const SETTLE := 2.4
## Ses durumu karşılaştırılan yollar (efektler tek seferliktir, durum değildir).
const STATE_BUSES: Array[String] = ["Music", "Ambience", "Voice"]
const AMP_BUSES: Array[String] = ["Music", "Ambience", "SFX"]

var _trash: Array[Node] = []
var _dirs: PackedStringArray = []
var _muted := false
## Akış sınamalarında önceden yüklenip tutulan sahneler (bkz. _new_main).
var _warm: Array[Resource] = []
static var _lengths: Dictionary = {}


func before_each() -> void:
	Engine.time_scale = 1.0
	CineVideo.enabled = false
	_muted = MenuStyle.muted
	MenuStyle.muted = true
	InputSetup.ensure_actions()


func after_each() -> void:
	_press_escape(false)
	for action in CineHost.SKIP_ACTIONS:
		if InputMap.has_action(action):
			Input.action_release(action)
	Engine.time_scale = 1.0
	for node in _trash:
		if is_instance_valid(node):
			node.queue_free()
	_trash.clear()
	for dir in _dirs:
		TempDir.wipe(dir)
	_dirs.clear()
	_warm.clear()
	MenuStyle.muted = _muted
	CineVideo.enabled = true
	get_viewport().disable_3d = false


# --- Dizi ----------------------------------------------------------------------------------------

func test_sequence_chains_camp_myth_and_birth() -> void:
	var tl := CineTimeline.from_path(PROLOGUE)
	assert_eq(tl.validate(), PackedStringArray(), "Dizide sorun olmamalı")
	assert_eq(tl.id, "prologue")
	var ids: Array[String] = []
	for seg in tl.segments:
		ids.append(str(seg["id"]))
	assert_eq(ids, SEGMENTS, "Kamp ve şarkı → mit → doğum (K68, kullanıcının E4.2 sırası)")
	for seg_id: String in SEGMENT_SETUP:
		var want: Array = SEGMENT_SETUP[seg_id]
		var seg := tl.segment(seg_id)
		assert_eq(str(seg.get("file", "")), want[0], "%s segmentinin dosyası" % seg_id)
		assert_eq(str(seg.get("scene", "")), want[1], "%s segmentinin sahnesi" % seg_id)
		assert_eq(str(seg.get("world", "")), want[2], "%s segmentinin dünyası" % seg_id)
		assert_eq(str(seg.get("view", "")), want[3], "%s segmentinin görünümü" % seg_id)
	assert_almost(float(tl.segment("birth").get("crossfade_in", 0.0)), CROSSFADE, 0.0001, "Mitin közünden gerçek köze 1,5 sn")
	assert_eq(tl.end_target, "childhood", "Önsöz bitince Çocukluk açılır (K99)")
	assert_false(tl.keep_world, "Dizi bitince childhood_ordos bırakılır: Çocukluk dünyayı kendi kurar")
	assert_almost(float(tl.target.get("total", 0.0)), TARGET, 0.0001, "Hedef 4 dk 19 sn")
	assert_almost(float(tl.target.get("tolerance", 0.0)), TARGET_TOLERANCE, 0.0001, "± 15 sn")
	var main_script := load(MAIN_SCRIPT) as GDScript
	assert_eq(main_script.get_script_constant_map().get("PROLOGUE_PATH"), PROLOGUE, "Yeni Oyun bu diziyi oynatır")


func test_total_is_4_19_within_15_seconds() -> void:
	var est := CineTimeline.from_path(PROLOGUE, _est())
	var game := CineTimeline.from_path(PROLOGUE)
	var heard := CineTimeline.from_path(PROLOGUE, _heard())
	assert_almost(est.total(), ESTIMATED_TOTAL, MARK_TOLERANCE, "Tahminle 4:18,7 (story.md §3)")
	var rows := [["tahmini", est], ["oyunun seconds", game], ["dosyaların", heard]]
	for row: Array in rows:
		var tl: CineTimeline = row[1]
		assert_eq(tl.validate(), PackedStringArray(), "%s sürelerle çizelge sorunsuz" % row[0])
		var total := tl.total()
		assert_between(total, TARGET - TARGET_TOLERANCE, TARGET + TARGET_TOLERANCE,
			"%s sürelerle toplam %s: 4:19 ± 15 sn" % [row[0], _clock(total)])
	# Dosyası olan satırda oyunun okuduğu seconds dosyanın süresidir; dosyasız satır tahminle akar.
	var with_file := 0
	for line_id: String in LINES:
		if VoLines.audio_path(line_id).is_empty():
			assert_almost(_file_length(line_id), VoLines.est(line_id), 0.0001, "%s: dosyasız satır tahminle akar" % line_id)
			continue
		with_file += 1
		assert_almost(VoLines.seconds(line_id), _file_length(line_id), VoLines.SECONDS_TOLERANCE,
			"%s: seconds dosyanın süresi" % line_id)
	assert_almost(game.total(), heard.total(), VoLines.SECONDS_TOLERANCE * LINES.size(), "Oyunun toplamı duyulanınki")
	print("    Önsöz: tahminle %s, seconds ile %s, dosyalarla %s (%d / %d satırın dosyası var)" % [
		_clock(est.total()), _clock(game.total()), _clock(heard.total()), with_file, LINES.size()])


func test_segment_bounds_with_estimates() -> void:
	var tl := CineTimeline.from_path(PROLOGUE, _est())
	assert_almost(float(tl.segment("camp")["start"]), 0.0, 0.0001, "Yeni Oyun'a basış 0:00,0")
	for mark: String in BOUNDS:
		assert_almost(tl.time_of(mark), float(BOUNDS[mark]), MARK_TOLERANCE, "%s %s'te" % [mark, _clock(float(BOUNDS[mark]))])
	assert_almost(float(tl.segment("camp")["end"]), float(tl.segment("myth")["start"]), 0.0001, "Mit kampın bittiği an başlar")
	assert_almost(float(tl.segment("myth")["end"]), float(tl.segment("birth")["start"]), 0.0001, "Doğum mitin bittiği an başlar")
	assert_almost(tl.total(), float(tl.segment("birth")["end"]), 0.0001, "Dizi doğumla (Çocukluk'a geçişle) biter")
	assert_almost(float(tl.segment("birth")["enter"]), BIRTH_ENTER, MARK_TOLERANCE, "Doğum 3:20,7'de kurulur (çakışmanın başı)")
	assert_almost(tl.time_of("birth_end") - tl.time_of("birth:panel_8"), 10.0, 0.0001, "Son 10 sn Çocukluk'a geçiş")
	var ember := tl.find("ember", "myth")
	assert_almost(float(ember.get("t", -1.0)), float(tl.segment("birth")["enter"]), 0.0001,
		"Mitin közü doğumun kurulduğu an parlar")


func test_song_starts_when_the_camera_stops() -> void:
	for pair: Array in [["tahmini", _est()], ["gerçek", Callable()]]:
		var tl := CineTimeline.from_path(PROLOGUE, pair[1])
		var pullback := tl.find("pullback", "camp")
		assert_eq(str(pullback.get("type", "")), "shot", "Geri çekilme menü kadrajından")
		assert_almost(float(pullback.get("t", -1.0)), 0.0, 0.0001, "Yeni Oyun'la başlar")
		assert_almost(float(pullback.get("duration", 0.0)), MenuCamera.PULLBACK_TIME, 0.0001, "6 sn")
		assert_almost(tl.time_of("camp:hold"), 6.0, 0.0001, "%s: kamera 0:06,0'da durur" % pair[0])
		var lines := tl.line_events()
		assert_false(lines.is_empty())
		if lines.is_empty():
			continue
		assert_eq(str(lines[0]["line"]), SONG, "Önsöz'ün ilk sesi şarkı")
		assert_almost(float(lines[0]["t"]), tl.time_of("camp:hold"), 0.0001, "%s: şarkı kamera durunca başlar" % pair[0])
		assert_almost(float(lines[0]["t"]), 6.0, 0.0001, "0:06,0")


func test_after_the_song_three_two_one_then_the_myth() -> void:
	for pair: Array in [["tahmini", _est()], ["gerçek", Callable()]]:
		var tl := CineTimeline.from_path(PROLOGUE, pair[1])
		var song_end := tl.time_of("camp:%s_end" % SONG)
		var silence := tl.find("silence", "camp")
		var out := tl.find("out", "camp")
		var black := tl.find("black", "camp")
		assert_eq(str(silence.get("type", "")), "low_silence")
		assert_true(bool(silence.get("on", false)), "Alçak sessizlik açılır")
		assert_almost(float(silence["t"]), song_end + 0.05, 0.0001, "%s: şarkı bitince" % pair[0])
		assert_almost(float(out["t"]) - float(silence["t"]), 3.0, 0.0001, "%s: 3 sn alçak sessizlik" % pair[0])
		assert_eq(str(out.get("type", "")), "fade")
		assert_almost(float(out.get("to", 0.0)), 1.0, 0.0001, "Ekran kararır")
		assert_almost(float(out["end"]) - float(out["t"]), 2.0, 0.0001, "%s: 2 sn kararma" % pair[0])
		assert_almost(float(black["t"]), float(out["end"]), 0.0001)
		assert_almost(tl.time_of("myth") - float(black["t"]), 1.0, 0.0001, "%s: 1 sn kara, sonra mit" % pair[0])
		var opening := tl.find("open", "myth")
		assert_almost(float(opening.get("t", -1.0)), tl.time_of("myth:act0.myth.3_end") + 0.2, 0.0001, "Perde ozanın ilk sözünden sonra açılır: 3. satır karadadır")
		assert_almost(float(opening.get("to", 1.0)), 0.0, 0.0001)
		# Kamp kara ekranda bırakılır: kararma bitti, mit henüz açılmadı.
		var releases := tl.events_of("release_camp")
		assert_eq(releases.size(), 1, "Kamp bir kez bırakılır")
		if releases.size() == 1:
			var at := float(releases[0]["t"])
			assert_almost(at, tl.time_of("camp_end") - 1.0, 0.0001, "camp_end − 1,0")
			assert_true(at >= float(out["end"]) - 0.0001 and at < tl.time_of("myth"), "%s: kamp kara ekranda bırakılır (%.2f)" % [pair[0], at])
		assert_true(tl.events_of("restore_camp").is_empty(), "Kamp dizinin sonunda konakça geri gelir")


func test_speakers_bard_narrator_and_hereka() -> void:
	var tl := CineTimeline.from_path(PROLOGUE)
	assert_eq(Array(tl.line_ids()), Array(LINES), "Önsöz'ün satırları sırayla: şarkı, mit 3–25, doğum 12, Hereka")
	assert_eq(str(VoLines.line(SONG).get("kind", "")), "song")
	assert_eq(VoLines.speaker(SONG), "bard", "Şarkıyı ozan söyler")
	var verses: Array[String] = []
	for sub: Dictionary in VoLines.sub_lines(SONG):
		verses.append(str(sub["id"]))
		assert_eq(VoLines.speaker(str(sub["id"])), "bard", "%s ozanın" % sub["id"])
	assert_eq(verses, SONG_VERSES, "1–2 şarkının dizeleri")
	for line_id: String in LINES:
		var want := "bard"
		if line_id == "act0.birth.hereka":
			want = "hereka"
		elif line_id == "act0.birth.12":
			want = "narrator"
		assert_eq(VoLines.speaker(line_id), want, "%s: %s" % [line_id, want])
	var hereka := tl.find("act0.birth.hereka", "birth")
	assert_eq(str(hereka.get("segment", "")), "birth", "Hereka doğumda konuşan tek kişi")


func test_lines_in_the_same_scene_are_1_5_seconds_apart() -> void:
	for pair: Array in [["tahmini", _est()], ["gerçek", Callable()], ["dosyaların", _heard()]]:
		var tl := CineTimeline.from_path(PROLOGUE, pair[1])
		var lines := tl.line_events()
		for i in range(1, lines.size()):
			var prev: Dictionary = lines[i - 1]
			var cur: Dictionary = lines[i]
			var gap := float(cur["t"]) - float(prev["end"])
			var same := str(prev["segment"]) == str(cur["segment"])
			assert_true(gap >= LINE_GAP - 0.0001, "%s: %s → %s arası %.2f sn (%s; ≥1,5)" % [pair[0], prev["line"], cur["line"], gap,
				"aynı sahne" if same else "sahne geçişi"])


func test_one_black_silence_one_choir_two_low_silences() -> void:
	var tl := CineTimeline.from_path(PROLOGUE, _est())
	var blacks := tl.events_of("black_silence")
	assert_eq(blacks.size(), 1, "Önsöz'ün tek kara sessizliği")
	if blacks.size() == 1:
		assert_eq(str(blacks[0]["segment"]), "birth", "Doğumda (7c)")
		assert_almost(float(blacks[0].get("dur", 0.0)), 2.5, 0.0001, "2,5 sn")
		assert_almost(float(blacks[0]["t"]), 227.6, MARK_TOLERANCE, "3:47,6'da")
		assert_almost(float(blacks[0]["t"]), tl.time_of("birth:7c"), 0.0001)
	var choirs: Array[Dictionary] = []
	for ev in tl.events_of("music"):
		var clip := MusicBank.clip(MusicBank.load_def(str(ev.get("bank", ""))), StringName(str(ev.get("state", ""))))
		assert_false(clip.is_empty(), "%s/%s bankada" % [ev.get("bank", ""), ev.get("state", "")])
		for layer: Variant in MusicBank.layers(clip):
			if layer is Dictionary and MusicBank.is_choir(layer):
				choirs.append(ev)
				break
	assert_eq(choirs.size(), 1, "Sinemanın tek korosu (#53, K59)")
	if choirs.size() == 1:
		assert_eq(str(choirs[0]["state"]), "tengri", "Koro tengri'de")
		assert_almost(float(choirs[0]["t"]), tl.time_of("myth:panel_4"), 0.0001, "Gök panosunda")
	var lows: Array[Dictionary] = []
	for ev in tl.events_of("low_silence"):
		if bool(ev.get("on", true)):
			lows.append(ev)
	assert_eq(lows.size(), 2, "İki alçak sessizlik: şarkıdan sonra ve kıvılcımdan önce")
	if lows.size() == 2:
		assert_eq([str(lows[0]["segment"]), str(lows[1]["segment"])], ["camp", "myth"])
		assert_almost(_lifted_at(tl, lows[0]), tl.time_of("myth:open"), 0.0001, "Kampınkinin içinde ozanın ilk sözü söylenir: perde açılırken kalkar")
		assert_almost(_lifted_at(tl, lows[1]), tl.time_of("myth:fire_catch"), 0.0001, "Mitinki kıvılcımla kalkar")
		assert_almost(tl.time_of("myth:fire_catch") - float(lows[1]["end"]) - float(lows[1].get("fade", 0.0)), 1.5, 0.0001,
			"Kıvılcımdan önce 1,5 sn")


func test_childhood_ordos_is_requested_with_the_myth_and_placed_before_the_crossfade() -> void:
	for pair: Array in [["tahmini", _est()], ["gerçek", Callable()]]:
		var tl := CineTimeline.from_path(PROLOGUE, pair[1])
		var preloads := tl.events_of("preload")
		var spawns := tl.events_of("instantiate")
		assert_eq(preloads.size(), 1, "childhood_ordos bir kez istenir")
		assert_eq(spawns.size(), 1, "ve bir kez örneklenir")
		if preloads.size() != 1 or spawns.size() != 1:
			continue
		assert_eq(str(preloads[0].get("path", "")), ORDOS)
		assert_eq(str(spawns[0].get("path", "")), ORDOS)
		assert_almost(float(preloads[0]["t"]), tl.time_of("myth"), 0.0001, "%s: mit sineması başlarken istenir" % pair[0])
		assert_almost(float(spawns[0]["t"]), tl.time_of("myth:panel_6"), 0.0001, "%s: pano 6'nın başında örneklenir" % pair[0])
		var enter := float(tl.segment("birth")["enter"])
		assert_true(float(spawns[0]["t"]) < enter - 10.0, "%s: örnekleme doğumun çakışmasından (%s) önce: %s" % [
			pair[0], _clock(enter), _clock(float(spawns[0]["t"]))])
		if pair[0] == "tahmini":
			assert_true(float(spawns[0]["t"]) < BIRTH_ENTER, "Tahminle örnekleme 3:20,7'den önce")


func test_real_seconds_shift_every_later_mark() -> void:
	var est := CineTimeline.from_path(PROLOGUE, _est())
	var real := CineTimeline.from_path(PROLOGUE)
	var song := VoLines.seconds(SONG) - VoLines.est(SONG)
	var myth := 0.0
	var before_six := 0.0
	for n in range(3, 26):
		var line_id := "act0.myth.%d" % n
		myth += VoLines.seconds(line_id) - VoLines.est(line_id)
		if n <= 21:
			before_six += VoLines.seconds(line_id) - VoLines.est(line_id)
	var birth := VoLines.seconds("act0.birth.12") - VoLines.est("act0.birth.12")
	var shifts := {"camp:hold": 0.0, "camp:song": 0.0, "camp:out": song, "myth": song, "myth:panel_6": song + before_six,
		"birth": song + myth, "birth:7b": song + myth,
		"birth:7c": song + myth + birth, "birth:panel_8": song + myth + birth, "birth_end": song + myth + birth}
	for mark: String in shifts:
		assert_almost(real.time_of(mark) - est.time_of(mark), float(shifts[mark]), 0.0001,
			"%s satırların gerçek süresiyle %.2f sn kayar" % [mark, shifts[mark]])
	assert_almost(real.total() - est.total(), song + myth + birth, 0.0001, "Toplam aynı payla")
	print("    Gerçek süreler: şarkı %+.2f, mit %+.2f, doğum %+.2f sn → toplam %s" % [song, myth, birth, _clock(real.total())])


# --- Akış (ana sahne) ------------------------------------------------------------------------------

func test_new_game_plays_the_whole_prologue_then_the_creator() -> void:
	var settings := PrologueSettings.new()
	_trash.append(settings)
	var main: Node = await _new_main(settings)
	var host: CineHost = main.cine
	var before := _menu_state(main)
	var holds := watch_signal(host.clock_hold_changed)
	var ends := watch_signal(host.finished)
	main.journey.play_time = 77.0
	main.cine_speed = CINE_SPEED
	Engine.time_scale = TIME_SCALE
	# Sinema bittiği anda (yeni yolculuk Önsöz'den sonraki aşamada başlamadan) yolculuğun süresi.
	var played_at_end: Array[float] = [-1.0]
	host.finished.connect(func(_skipped: bool) -> void: played_at_end[0] = main.journey.play_time, CONNECT_ONE_SHOT)
	main.menu.start_requested.emit()
	assert_eq(main.state, main.State.CINE, "Yeni Oyun Önsöz'ü oynatır")
	assert_eq(host.timeline().source, PROLOGUE, "Yeni Oyun'un dizisi prologue.json")
	assert_eq(holds.last_args, [true], "Sinemada saat durur")
	var log := CineLog.new(host, main, ORDOS)
	log.slow_window = true
	log.slow_speed = SLOW_SPEED
	await _wait_until(func() -> bool: return main.state == main.State.CREATOR, 120.0)
	log.detach()
	assert_eq(main.state, main.State.CREATOR, "Önsöz bitince oluşturucu açılır")
	assert_eq(ends.last_args, [false], "Önsöz sonuna dek oynar")
	var tl := host.timeline()
	assert_almost(host.time(), tl.total(), 0.001, "Sinema saati dizinin sonunda")
	assert_eq(log.started, SEGMENTS, "Segmentler sırayla açılır")
	assert_eq(holds.last_args, [false], "Önsöz bitince saat bırakılır")
	assert_eq(played_at_end[0], 77.0, "Sinemada yolculuğun süresi işlemez")
	assert_true(main.journey.play_time < 1.0, "Yeni yolculuk Önsöz'den sonra sıfırdan başlar")
	assert_true(settings.prologue_seen, "İlk oynatmada prologue_seen yazılır")
	assert_eq(settings.saves, 1)
	# Dünyalar: kamp kara ekranda bırakılır, childhood_ordos mit başında istenir, pano 6'da örneklenir, geçişte beklenmez.
	var release: Dictionary = log.marks.get("release_camp", {})
	assert_almost(float(release.get("t", -1.0)), tl.time_of("camp_end") - 1.0, 0.001, "Kamp kara ekranda bırakılır")
	assert_true(bool(release.get("released", false)), "release_camp kampı bırakır")
	var asked: Dictionary = log.marks.get("preload", {})
	assert_almost(float(asked.get("t", -1.0)), tl.time_of("myth"), 0.001, "childhood_ordos mit başında istenir")
	assert_true(int(asked.get("state", -1)) in [ResourceLoader.THREAD_LOAD_IN_PROGRESS, ResourceLoader.THREAD_LOAD_LOADED],
		"Arka planda yükleniyor (%d)" % int(asked.get("state", -1)))
	var placed: Dictionary = log.marks.get("instantiate", {})
	assert_almost(float(placed.get("t", -1.0)), tl.time_of("myth:panel_6"), 0.001, "Örnekleme pano 6'da istenir")
	var enter := float(tl.segment("birth")["enter"])
	var added := float((log.marks.get("ordos_added", {}) as Dictionary).get("t", INF))
	assert_true(added < enter, "childhood_ordos doğumun çakışmasından önce sahnede (%s < %s)" % [_clock(added), _clock(enter)])
	var opened: Dictionary = log.marks.get("enter:birth", {})
	assert_false(opened.is_empty(), "Doğum segmenti kuruldu")
	assert_false(bool(opened.get("held", true)), "Geçişte yükleme yok: doğum dünyasını beklemeden açılır")
	assert_almost(float((log.marks.get("start:birth", {}) as Dictionary).get("t", -1.0)), enter, 0.001, "Doğum 3:20,7'de (çakışmanın başı)")
	assert_true(bool((log.marks.get("start:birth", {}) as Dictionary).get("released", false)), "Doğumda kamp bırakılmış")
	assert_true(host.instantiate_ms.has(ORDOS), "Örnekleme süresi kaydedilir")
	print("    childhood_ordos: istek %s, örnekleme %s (%.1f ms), sahnede %s, doğum %s" % [_clock(float(asked.get("t", 0.0))),
		_clock(float(placed.get("t", 0.0))), float(host.instantiate_ms.get(ORDOS, -1.0)), _clock(added), _clock(enter)])
	_assert_fresh_levels(log, "İlk oynatma")
	# Bitince: dünya bırakılır, kamp geri gelir, sinemanın izi kalmaz.
	await wait_frames(2)
	_assert_cine_cleared(main, "Önsöz bitince")
	assert_true(main.creator.visible)
	assert_almost(main.fade.color.a, 0.0, 0.01, "Oluşturucu kara perdeden açılır, perde kalkar")
	# Vazgeç → menü: menü karesi Önsöz öncesiyle aynı.
	main.creator.cancelled.emit()
	await _wait_until(func() -> bool: return main.state == main.State.MENU, 10.0)
	assert_eq(main.state, main.State.MENU, "Vazgeç menüye döner")
	await _settle()
	_assert_same(before, _menu_state(main), "Önsöz sonuna dek oynadıktan sonra")
	# İkinci Yeni Oyun: görülen Önsöz varsayılanla atlanır.
	var plays := holds.count
	main.menu.start_requested.emit()
	await _wait_until(func() -> bool: return main.state == main.State.CREATOR, 10.0)
	assert_eq(main.state, main.State.CREATOR, "İkinci Yeni Oyun doğrudan oluşturucuyu açar")
	assert_eq(holds.count, plays, "Görülen Önsöz yeniden oynamaz")
	assert_false(host.is_playing())
	main.creator.cancelled.emit()
	await _wait_until(func() -> bool: return main.state == main.State.MENU, 10.0)
	# «Her yeni oyunda»: yeniden oynar; her banka ilk oynatmadaki düzeyinden başlar (önceki oynatmanın katmanları taşınmaz).
	settings.prologue_always = true
	main.cine_speed = CINE_SPEED
	main.menu.start_requested.emit()
	assert_eq(main.state, main.State.CINE, "«Her yeni oyunda» açıkken Önsöz yeniden oynar")
	var replay := CineLog.new(host, main, ORDOS)
	var birth_start := float(host.timeline().segment("birth")["start"])
	await _wait_until(func() -> bool: return host.time() >= birth_start + 1.0 or not host.is_playing(), 60.0)
	replay.detach()
	assert_eq(replay.started, SEGMENTS, "Yeniden oynatmada da kamp → mit → doğum")
	_assert_fresh_levels(replay, "Yeniden oynatma")
	assert_eq(replay.bank_starts.size(), 3, "Üç banka baştan başlar: camp, prologue_myth, ordos")
	# Doğumda basılı Esc → oluşturucu → onay: yeni yolculuğa Önsöz'ün işareti yazılır.
	host.speed = 1.0
	_press_escape(true)
	await _wait_until(func() -> bool: return host.is_skipping() or not host.is_playing(), 5.0)
	_press_escape(false)
	await _wait_until(func() -> bool: return main.state == main.State.CREATOR, 10.0)
	assert_eq(main.state, main.State.CREATOR)
	assert_eq(ends.last_args, [true], "Esc atlar")
	assert_eq(settings.saves, 1, "Görülen Önsöz yeniden yazılmaz")
	main.creator.accepted.emit(CharacterProfile.new())
	await _wait_until(func() -> bool: return main.state == main.State.MENU, 10.0)
	assert_eq(main.state, main.State.MENU, "Onaydan sonra (akışta başka aşama yok) açılış ekranı: kampa inilmez (K99)")
	assert_true(main.journey.has_flag(CineHost.PROLOGUE_FLAG), "Yeni yolculukta onsoz işareti (mitler ve «Doğum» açılır)")
	await _free_main(main)


func test_held_escape_skips_in_the_camp_the_myth_and_the_birth() -> void:
	var settings := PrologueSettings.new()
	settings.prologue_always = true
	_trash.append(settings)
	var main: Node = await _new_main(settings)
	var host: CineHost = main.cine
	var before := _menu_state(main)
	var ends := watch_signal(host.finished)
	for seg_id: String in SEGMENTS:
		var finishes := ends.count
		main.cine_speed = CINE_SPEED
		Engine.time_scale = TIME_SCALE
		main.menu.start_requested.emit()
		assert_eq(main.state, main.State.CINE, "%s: Yeni Oyun Önsöz'ü oynatır («Her yeni oyunda»)" % seg_id)
		var log := CineLog.new(host, main, ORDOS)
		var start := float(host.timeline().segment(seg_id).get("start", 0.0))
		await _wait_until(func() -> bool: return host.time() >= start + 1.0 or not host.is_playing(), 60.0)
		host.speed = 1.0
		assert_true(host.is_playing(), "%s: sinema sürüyor" % seg_id)
		assert_eq(str(host.timeline().segment_at(host.time()).get("id", "")), seg_id, "Esc %s segmentinde basılır" % seg_id)
		_assert_playing_state(main, seg_id)
		var pressed_at := Time.get_ticks_msec()
		_press_escape(true)
		await _wait_until(func() -> bool: return host.is_skipping() or not host.is_playing(), 5.0)
		var held := (Time.get_ticks_msec() - pressed_at) / 1000.0 * Engine.time_scale
		var skipping := host.is_skipping()
		_press_escape(false)
		assert_true(skipping, "%s: basılı Esc atlar" % seg_id)
		assert_between(held, CineHost.SKIP_HOLD - 0.1, 3.0, "%s: Esc ≈0,6 sn basılı tutulunca atlar (%.2f sn)" % [seg_id, held])
		await _wait_until(func() -> bool: return main.state == main.State.CREATOR, 10.0)
		log.detach()
		assert_eq(main.state, main.State.CREATOR, "%s: atlanan Önsöz'den oluşturucu açılır" % seg_id)
		assert_eq(ends.count, finishes + 1, "%s: dizi bir kez biter" % seg_id)
		assert_eq(ends.last_args, [true], "%s: finished(true)" % seg_id)
		_assert_fresh_levels(log, "Esc %s" % seg_id)
		await wait_frames(2)
		_assert_cine_cleared(main, "Esc %s" % seg_id)
		await _wait_until(func() -> bool: return not host.is_loading(), 10.0)
		assert_eq(host.load_state(ORDOS), ResourceLoader.THREAD_LOAD_INVALID_RESOURCE, "%s: bekleyen yükleme bırakılır" % seg_id)
		assert_almost(main.fade.color.a, 0.0, 0.01, "%s: perde kalkar" % seg_id)
		main.creator.cancelled.emit()
		await _wait_until(func() -> bool: return main.state == main.State.MENU, 10.0)
		assert_eq(main.state, main.State.MENU, "%s: vazgeç menüye döner" % seg_id)
		await _settle()
		_assert_same(before, _menu_state(main), "Esc %s segmentinde" % seg_id)
	assert_true(settings.prologue_seen)
	await _free_main(main)


# --- Yardımcılar: süreler ve saat ------------------------------------------------------------------

func _est() -> Callable:
	return func(id: String) -> float: return VoLines.est(id)


## Duyulan süre: dosyası olan satırda dosyanın süresi, olmayanda tahmin.
func _heard() -> Callable:
	return func(id: String) -> float: return _file_length(id)


static func _file_length(line_id: String) -> float:
	if _lengths.has(line_id):
		return _lengths[line_id]
	var value := VoLines.est(line_id)
	var path := VoLines.audio_path(line_id)
	if not path.is_empty():
		var stream := load(path) as AudioStream
		if stream and stream.get_length() > 0.0:
			value = stream.get_length()
	_lengths[line_id] = value
	return value


## Alçak sessizliğin kalktığı an: aynı dizide ondan sonraki ilk «on: false».
static func _lifted_at(tl: CineTimeline, low: Dictionary) -> float:
	for ev in tl.events_of("low_silence"):
		if float(ev["t"]) > float(low["t"]) and not bool(ev.get("on", true)):
			return float(ev["t"])
	return NAN


## 226.9 → "3:46,9".
static func _clock(t: float) -> String:
	if is_nan(t) or is_inf(t):
		return str(t)
	var minutes := int(floor(t / 60.0))
	return ("%d:%04.1f" % [minutes, t - minutes * 60.0]).replace(".", ",")


# --- Yardımcılar: ana sahne ------------------------------------------------------------------------

## Ana sahne (kayıtlar geçici klasörde, ayar sahte): açılış ekranında, giriş bitmiş.
func _new_main(settings: Node) -> Node:
	# Segment sahneleri ve childhood_ordos önceden yüklenir ve sınama boyunca tutulur: Godot 4.7.2'de ağır bir sahneyi
	# ilk kez arka planda yükleyen istek (load_threaded_request) yükleme belirteçlerini bırakmıyor, çıkışta «ObjectDB
	# instances were leaked» yazılıyor (Önsöz başına ≈18 nesne; oyunda zararsız, docs/testler.md «Dikkat edilecek
	# tuzaklar»). CineHost yine aynı istekleri yapar; kaynaklar önbellekte olduğu için hemen gelir. Dünyanın örneklenmesi,
	# kurulması ve doğumdan önce hazır olması (geçişte beklenmemesi) olduğu gibi sınanır.
	for seg_id: String in SEGMENT_SETUP:
		_warm.append(load(str((SEGMENT_SETUP[seg_id] as Array)[1])))
	_warm.append(load(ORDOS))
	var dir := TempDir.fresh("onsoz_akis")
	_dirs.append(dir)
	var main: Node = load(MAIN_SCENE).instantiate()
	main.quit_handler = func() -> void: pass
	main.saves = SaveSystem.new(dir)
	main.prologue_path = PROLOGUE
	# Önsöz'ün oynanan günleri (E21) bu dosyada değil: test_prologue_days.gd.
	main.prologue_days_path = ""
	# Yeni Oyun'un akışından yalnız Önsöz ve oluşturucu (K99; Çocukluk ve köprüler test_new_game_flow.gd'de).
	main.new_game_only = PackedStringArray(["prologue", "creator"])
	add_child(main)
	_trash.append(main)
	await wait_frames(3)
	main.menu.finish_intro()
	main.settings = settings
	main.remember_prologue = true
	await wait_frames(2)
	return main


func _free_main(main: Node) -> void:
	Engine.time_scale = 1.0
	main.get_viewport().disable_3d = false
	main.queue_free()
	_trash.erase(main)
	var audio := _audio()
	if audio:
		audio.stop_all()
		audio.reset_buses()
	await get_tree().create_timer(0.25).timeout


func _audio() -> Node:
	return get_node_or_null(^"/root/AudioManager")


## Menüye dönünce geçişlerin bitmesi (menü müziği 2 sn'de gelir, banka söner, ortam katmanları kapanır).
func _settle() -> void:
	await get_tree().create_timer(SETTLE).timeout


## Atlamadan hemen önce sinemanın o segmentteki hâli.
func _assert_playing_state(main: Node, seg_id: String) -> void:
	var host: CineHost = main.cine
	match seg_id:
		"camp":
			assert_true(host.scene_node("camp") is PrologueCamp, "Kamp sahnesi kurulu")
			assert_false(host.is_camp_released(), "Kampta kamp dünyası yerinde")
			assert_true(main.menu_camera.current, "Ekrandaki kamera menü kamerası")
		"myth":
			assert_true(host.scene_node("myth") is PrologueMyth, "Mit sahnesi kurulu")
			assert_not_null(host.overlay_viewport("myth"), "Keçe panolar kendi dünyasında (overlay)")
			assert_true(host.is_camp_released(), "Mitte kamp bırakılmış")
			assert_false(main.world.visible, "Kamp gizli")
			assert_eq(main.world.process_mode, Node.PROCESS_MODE_DISABLED, "Kampın süreci durmuş")
			assert_true(host.load_state(ORDOS) in [ResourceLoader.THREAD_LOAD_IN_PROGRESS, ResourceLoader.THREAD_LOAD_LOADED],
				"childhood_ordos arka planda yükleniyor")
		"birth":
			var scene := host.scene_node("birth") as PrologueBirth
			assert_not_null(scene, "Doğum sahnesi kurulu")
			assert_true(host.world_node(ORDOS) is OrdosWorld, "Doğum childhood_ordos dünyasında")
			assert_true(host.is_camp_released(), "Doğumda kamp bırakılmış")
			assert_null(host.overlay_viewport("myth"), "Mitin katmanı kalktı")
			if scene:
				assert_true(scene.camera.current, "Doğumun kamerası etkin")


## Sinemanın izi kalmadı: dünya bırakıldı, kamp yerinde, katman ve sahne yok, saat bırakıldı.
func _assert_cine_cleared(main: Node, label: String) -> void:
	var host: CineHost = main.cine
	assert_false(host.is_playing(), "%s: sinema bitti" % label)
	assert_false(host.is_camp_released(), "%s: kamp geri geldi" % label)
	assert_true(main.world.visible, "%s: kamp görünür" % label)
	assert_eq(main.world.process_mode, Node.PROCESS_MODE_INHERIT, "%s: kampın süreci sürer" % label)
	assert_null(host.world_node(ORDOS), "%s: childhood_ordos bırakıldı" % label)
	for child in main.get_children():
		assert_ne(child.scene_file_path, ORDOS, "%s: childhood_ordos sahneden kalktı" % label)
	for seg_id: String in SEGMENTS:
		assert_null(host.scene_node(seg_id), "%s: %s sahnesi silindi" % [label, seg_id])
	assert_null(host.overlay_viewport("myth"), "%s: mitin katmanı kalktı" % label)
	assert_eq(host.subtitles.current_text(), "", "%s: altyazı yok" % label)
	assert_eq(host.card_text(), "", "%s: kart yok" % label)
	assert_true(main.menu_camera.current, "%s: menü kamerası etkin" % label)


## Menü karesinin başsız karşılığı: kamp dünyası, gök ve su tekdüzenleri, sis, menü kamerası, ateş başı, ses.
func _menu_state(main: Node) -> Dictionary:
	var world: Node3D = main.world
	var camera: MenuCamera = main.menu_camera
	var state := {}
	state["state"] = main.state
	state["menu:visible"] = main.menu.visible
	state["player:visible"] = main.player.visible
	state["world:visible"] = world.visible
	state["world:process_mode"] = world.process_mode
	var env_node := world.get_node(^"WorldEnvironment") as WorldEnvironment
	state["world:environment"] = env_node.environment
	if env_node.environment:
		for prop: Dictionary in env_node.environment.get_property_list():
			var prop_name := str(prop["name"])
			if (int(prop["usage"]) & PROPERTY_USAGE_STORAGE) and (prop_name.begins_with("fog_") or prop_name.begins_with("volumetric_fog")):
				state["fog:" + prop_name] = env_node.environment.get(prop_name)
	for pair: Array in [["sky", PrologueCamp.sky_material(world)], ["water", PrologueCamp.water_material(world)]]:
		var mat: ShaderMaterial = pair[1]
		if mat == null or mat.shader == null:
			state[str(pair[0])] = null
			continue
		for uniform: Dictionary in mat.shader.get_shader_uniform_list():
			state["%s:%s" % [pair[0], uniform["name"]]] = mat.get_shader_parameter(str(uniform["name"]))
	for type in ["AudioStreamPlayer", "AudioStreamPlayer2D", "AudioStreamPlayer3D"]:
		for player in world.find_children("*", type, true, false):
			state["paused:%s" % world.get_path_to(player)] = bool(player.get(&"stream_paused"))
	state["camera:current"] = camera.current
	state["camera:transform"] = camera.global_transform
	state["camera:fov"] = camera.fov
	state["camera:keep_aspect"] = camera.keep_aspect
	state["camera:drifting"] = camera.drifting
	state["camera:drift_base"] = camera.has_drift_base
	state["camera:flying"] = camera.is_flying()
	var npcs := world.get_node(^"Camp/CampNpcs") as CampNpcs
	state["npcs:hidden_model"] = npcs.hidden_model
	for avatar in npcs.get_avatars():
		var key := "npc:%s" % avatar.name
		state[key + ":visible"] = avatar.visible
		state[key + ":transform"] = avatar.transform
		state[key + ":face_point"] = avatar.face_point
		var skeleton := avatar.get_skeleton()
		var modifiers := PackedStringArray()
		if skeleton:
			for child in skeleton.get_children():
				modifiers.append(str(child.name))
		state[key + ":skeleton"] = modifiers
	state["npcs:kopuz"] = npcs.get_kopuz().transform if npcs.get_kopuz() else null
	var audio := _audio()
	if audio:
		state["audio:bank"] = audio.current_music_bank()
		state["audio:state"] = audio.current_music_state()
		state["audio:low_silence"] = audio.is_low_silence()
		state["audio:line"] = audio.current_line()
		state["audio:speaking"] = audio.is_speaking()
		for bus: String in AMP_BUSES:
			state["audio:amp:" + bus] = audio.amp_db(StringName(bus))
		for id: String in _ambience_ids():
			state["audio:layer:" + id] = audio.ambience_layer_db(StringName(id))
		var playing := {}
		for child in audio.get_children():
			var player := child as AudioStreamPlayer
			if player == null or not player.playing or not STATE_BUSES.has(str(player.bus)):
				continue
			var list: Array = playing.get(str(player.bus), [])
			list.append(player.stream.resource_path if player.stream and not player.stream.resource_path.is_empty()
				else (player.stream.get_class() if player.stream else ""))
			list.sort()
			playing[str(player.bus)] = list
		for bus: String in STATE_BUSES:
			state["audio:playing:" + bus] = playing.get(bus, [])
	return state


## Önsöz'ün açtığı ortam döngüleri (ambience olaylarının id'si, sahnelerin bed'i).
func _ambience_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	for ev in CineTimeline.from_path(PROLOGUE, _est()).events:
		var id := ""
		if str(ev["type"]) == "ambience":
			id = str(ev.get("id", ""))
		elif str(ev["type"]) == "bed":
			id = str(ev.get("bed", ""))
		if not id.is_empty() and not ids.has(id):
			ids.append(id)
	return ids


func _assert_same(before: Dictionary, after: Dictionary, label: String) -> void:
	for key: String in before:
		var a: Variant = before[key]
		var b: Variant = after.get(key)
		if key == "camera:transform":
			# Menüde kamera salınır (0,06 m) ve fareye 1,2° bakar: iki kare de menu_transform çevresinde.
			var at: Transform3D = b
			var was: Transform3D = a
			assert_true(at.origin.distance_to(was.origin) < 0.14, "%s: menü kamerası kadrajında (%s ≠ %s)" % [label, at.origin, was.origin])
			assert_true(rad_to_deg(at.basis.get_rotation_quaternion().angle_to(was.basis.get_rotation_quaternion())) < 2.5,
				"%s: menü kamerasının yönü" % label)
			continue
		if a is Transform3D:
			assert_true((a as Transform3D).is_equal_approx(b), "%s: %s eski hâline dönmeli (%s ≠ %s)" % [label, key, b, a])
		elif a is float:
			assert_almost(float(b), float(a), 0.0001, "%s: %s eski hâline dönmeli" % [label, key])
		else:
			assert_eq(b, a, "%s: %s eski hâline dönmeli" % [label, key])


## Baştan başlayan her bankanın çalan klibi bankanın (ve perde renginin) düzeyinden başlar.
func _assert_fresh_levels(log: CineLog, label: String) -> void:
	assert_false(log.bank_starts.is_empty(), "%s: müzik bankası başladı" % label)
	for entry: Dictionary in log.bank_starts:
		var def := MusicBank.load_def(str(entry["bank"]))
		var clip := MusicBank.clip(def, StringName(str(entry["state"])))
		var levels: Dictionary = entry["levels"]
		for layer: Variant in MusicBank.layers(clip):
			if not layer is Dictionary:
				continue
			var layer_name := str(layer.get("name", ""))
			var want := MusicBank.layer_volume(layer, entry["color"])
			assert_almost(float(levels.get(layer_name, NAN)), want, 0.01, "%s: %s/%s katmanı bankanın düzeyinden başlar" % [
				label, entry["state"], layer_name])


func _press_escape(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.physical_keycode = KEY_ESCAPE
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _wait_until(condition: Callable, timeout: float) -> void:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame


## Sinemanın oynatma günlüğü: açılan segmentler, dünya olayları, bankaların baştan başladığı anlar. slow_window açıkken
## pano 6'nın örneklemesinden doğumun kurulmasına dek sinema SLOW_SPEED'le akar (geçişte yükleme olmadığının sıkı sınaması).
class CineLog:
	extends RefCounted

	var host: CineHost
	var main: Node
	var world_path := ""
	var slow_window := false
	var slow_speed := 1.0
	var started: Array[String] = []
	## Ad → {t, ...}: release_camp, preload, instantiate, ordos_added, enter:<segment>, start:<segment>.
	var marks := {}
	## Baştan başlayan bankalar: {bank, state, t, levels (katman → dB), color}.
	var bank_starts: Array[Dictionary] = []

	var _bank := ""
	var _fast := 1.0

	func _init(p_host: CineHost, p_main: Node, p_world: String) -> void:
		host = p_host
		main = p_main
		world_path = p_world
		_fast = host.speed
		host.segment_started.connect(_on_segment)
		host.runner.fired.connect(_on_fired)
		main.child_entered_tree.connect(_on_child)

	func detach() -> void:
		if host.segment_started.is_connected(_on_segment):
			host.segment_started.disconnect(_on_segment)
		if host.runner.fired.is_connected(_on_fired):
			host.runner.fired.disconnect(_on_fired)
		if is_instance_valid(main) and main.child_entered_tree.is_connected(_on_child):
			main.child_entered_tree.disconnect(_on_child)

	func _on_segment(seg_id: String) -> void:
		started.append(seg_id)
		marks["start:" + seg_id] = {"t": host.time(), "released": host.is_camp_released(),
			"world": host.world_node(world_path) != null}
		if seg_id == "birth" and slow_window:
			host.speed = _fast

	func _on_fired(ev: Dictionary, _seeking: bool) -> void:
		var type := str(ev["type"])
		match type:
			"release_camp", "preload", "instantiate":
				marks[type] = {"t": host.time(), "path": str(ev.get("path", "")), "state": host.load_state(world_path),
					"released": host.is_camp_released()}
				if type == "instantiate" and slow_window:
					host.speed = slow_speed
			CineTimeline.ENTER:
				marks["enter:" + str(ev["segment"])] = {"t": host.time(), "held": host.runner.held}
			"music":
				var bank := str(ev.get("bank", ""))
				if bank.is_empty() or bank == _bank:
					return
				_bank = bank
				var audio := main.get_node_or_null(^"/root/AudioManager")
				if audio == null:
					return
				var state := StringName(str(ev.get("state", "")))
				var levels := {}
				for layer_name in MusicBank.layer_names(MusicBank.load_def(bank), state):
					levels[layer_name] = audio.layer_db(StringName(layer_name), state)
				bank_starts.append({"bank": bank, "state": String(state), "t": host.time(), "levels": levels,
					"color": audio.music_color()})

	func _on_child(node: Node) -> void:
		if node.scene_file_path == world_path and not marks.has("ordos_added"):
			marks["ordos_added"] = {"t": host.time()}


## Önsöz ayarlarını taşıyan sahte ayar düğümü (GameSettings.prologue_seen / prologue_always); kaydı sayar, dosyaya yazmaz.
class PrologueSettings:
	extends Node

	var prologue_seen := false
	var prologue_always := false
	var saves := 0

	func save_settings() -> bool:
		saves += 1
		return true
