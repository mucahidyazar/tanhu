extends TestCase
## Sinemanın video oynatıcısı ve mit sinemasının video kipi (K93; story.md §3 satır 1–6 ve 8, godot.md §3.6). Gerçek dosyalar
## motion-studio'dan gelir, ana oturum kopyalar; burada küçük bir fixture oynar (tests/fixtures/t_silent.ogv: sessiz Theora,
## 640 × 360, 10 sn; gri düzey kare numarasını verir: piksel.r × 299). Başsız koşuda konum ve sinyaller çalışır, doku boştur.
##   - CineVideo: sinema saatini izler; sapma 0,12 sn'yi aşınca sarar, iki sarma arası en az 0,5 sn; küçük sapmayı hız alır, sarma
##     yeni sarma doğurmaz; takılmadan sonra saat ve video birliktedir; hız CineHost.speed'dendir; saat durunca duraklar; sonunda son
##     karede kalır; dosya yoksa ya da bozuksa sessizce kapalıdır; 16:9'u korur, artan yer banttır.
##   - Katman sırası: 3B ve keçe (0) < boyalı süzgeç (1) < video (2) < perde (5) < altyazı (6).
##   - Altyazı: video oynarken alttaki 124 px'lik koyu bantta iki satır sığar, video bitince eski yerine döner.
##   - Mit sahnesi: video varsa keçe kurulmaz, 3B çizilmez; çekim ve olaylar sürer; ileri sarma; son 1,5 sn'de overlay söner, video
##     akar; köz sabit yerdedir ve 7a'nın ilk karesi gerçek közü oraya oturtur. Dosya yoksa ya da enabled kapalıysa keçe yedeği.
##   - Doğumun son 10 sn'si: video varsa keçe pano kurulmaz, görüntü 0,4–1,9 sn'de belirir, video saati izler.
##   - Gerçek dosya varsa süresi: |myth.ogv − (mit segmenti gerçek süresi + 1,0)| ≤ 0,25; yoksa atlanır ve yazılır.
## Görüntünün son onayı kullanıcınındır (Karar Bekleyenler); pencerede kare denetimi ana oturumdadır.

const TempDir := preload("res://tests/support/temp_dir.gd")
const FIXTURE := "res://tests/fixtures/t_silent.ogv"
const FIXTURE_SECONDS := 10.0
const MYTH_SCENE := "res://scenes/cine/prologue_myth.tscn"
const BIRTH_SCENE := "res://scenes/cine/prologue_birth.tscn"
const MYTH_SEGMENT := "res://data/cine/prologue_myth.json"
const BIRTH_SEGMENT := "res://data/cine/prologue_birth.json"
const PROLOGUE := "res://data/cine/prologue.json"
const MISSING := "res://assets/cine/video/yok_boyle_bir_video.ogv"
## Videonun segmentten uzunluğu ve süre sınamasının payı (K93).
const VIDEO_TAIL := 1.0
const DURATION_TOLERANCE := 0.25
const CHILDHOOD_SECONDS := 10.0
const READY_TIMEOUT := 90.0

var _trash: Array[Node] = []
var _dirs: PackedStringArray = []


func before_each() -> void:
	Engine.time_scale = 1.0
	CineVideo.enabled = true
	PrologueMyth.video_path = FIXTURE
	PrologueBirth.video_path = FIXTURE


func after_each() -> void:
	CineVideo.enabled = true
	PrologueMyth.video_path = PrologueMyth.VIDEO_PATH
	PrologueBirth.video_path = PrologueBirth.VIDEO_PATH
	for node in _trash:
		if is_instance_valid(node):
			if node is CineHost:
				(node as CineHost).stop()
			if node is PrologueBirth:
				(node as PrologueBirth).restore()
			node.queue_free()
	_trash.clear()
	for dir in _dirs:
		TempDir.wipe(dir)
	_dirs.clear()
	CineActor.clear_cache()
	Engine.time_scale = 1.0
	get_viewport().disable_3d = false


# --- CineVideo: saat -----------------------------------------------------------------------------------

func test_seek_rule_is_pure() -> void:
	assert_false(CineVideo.should_seek(1.0, 1.1, 10.0), "0,1 sn sapma düzeltilmez")
	assert_false(CineVideo.should_seek(0.0, CineVideo.MAX_DRIFT, 10.0), "Sınırın kendisi düzeltilmez")
	assert_true(CineVideo.should_seek(1.0, 1.13, 10.0), "0,13 sn ileride: sarılır")
	assert_true(CineVideo.should_seek(1.13, 1.0, 10.0), "0,13 sn geride: sarılır")
	assert_false(CineVideo.should_seek(1.0, 3.0, CineVideo.SEEK_GAP - 0.01), "Son sarmadan 0,5 sn geçmeden sarılmaz")
	assert_true(CineVideo.should_seek(1.0, 3.0, CineVideo.SEEK_GAP), "0,5 sn geçince sarılır")
	assert_false(CineVideo.should_seek(1.0, 1.3, 10.0, 4.0), "Hızlı oynatmada bir karelik adım sapma sayılmaz")
	assert_true(CineVideo.should_seek(1.0, 1.6, 10.0, 4.0), "Hızlı oynatmada da büyük sapma düzeltilir")
	assert_almost(CineVideo.MAX_DRIFT, 0.12, 0.0001)
	assert_almost(CineVideo.SEEK_GAP, 0.5, 0.0001)


func test_follow_starts_and_tracks_the_clock() -> void:
	var video := _video()
	assert_almost(video.length(), FIXTURE_SECONDS, 0.05, "Fixture 10 sn")
	assert_false(video.is_playing(), "open oynatmaz")
	var t := await _drive(video, 0.0, 1.0)
	assert_true(video.is_playing(), "İlk follow başlatır")
	assert_true(video.playhead() > 0.5, "Video akar (%.2f)" % video.playhead())
	assert_true(absf(video.playhead() - t) <= CineVideo.MAX_DRIFT + 0.05, "Saatin yanında: konum %.3f, saat %.3f" % [video.playhead(), t])
	assert_true(video.seek_count <= 1, "Saatin yanındayken sarılmaz (yüklü makinede en çok bir kez; %d)" % video.seek_count)


func test_follow_can_start_anywhere() -> void:
	var video := _video()
	video.follow(6.0)
	assert_true(video.is_playing())
	assert_almost(video.playhead(), 6.0, 0.05, "--cine-at: ilk follow oraya konumlanır")
	assert_eq(video.seek_count, 1)
	var past := _video()
	past.follow(99.0)
	assert_true(past.playhead() >= FIXTURE_SECONDS - 0.2, "Saat videonun sonunu geçmişse son kareye konumlanır (%.2f)" % past.playhead())


func test_drift_seeks_at_most_every_half_second() -> void:
	var video := _video()
	video.follow(0.0, 100.0)
	assert_eq(video.seek_count, 0, "Baştan başlarken sarılmaz")
	video.follow(3.0, 100.1)
	assert_eq(video.seek_count, 1, "Sapma: sarılır")
	assert_almost(video.playhead(), 3.0, 0.05)
	video.follow(5.0, 100.4)
	assert_eq(video.seek_count, 1, "0,3 sn sonra yeniden sarılmaz")
	assert_almost(video.playhead(), 3.0, 0.05, "Konum yerinde")
	video.follow(5.1, 100.6)
	assert_eq(video.seek_count, 2, "0,5 sn geçince yeniden sarılır")
	assert_almost(video.playhead(), 5.1, 0.05)
	video.follow(5.15, 101.5)
	assert_eq(video.seek_count, 2, "Sapma sınırın altındaysa süre geçse de sarılmaz")


func test_hitch_keeps_the_clock_and_the_video_together() -> void:
	var video := _video()
	var t := await _drive(video, 0.0, 0.3)
	# Takılma: motor süreç adımını kırpar, sinema saati (CineHost: delta, MAX_STEP tavanıyla) ve video aynı adımla akar.
	for i in 3:
		OS.delay_msec(600)
		await get_tree().process_frame
		t += minf(get_process_delta_time(), CineRunner.MAX_STEP)
		video.follow(t)
	t = await _drive(video, t, 0.3)
	assert_true(absf(video.playhead() - t) <= CineVideo.MAX_DRIFT, "Takılmadan sonra saatin yanında: konum %.3f, saat %.3f" % [video.playhead(), t])
	assert_true(video.seek_count <= 1, "Takılma sarma doğurmaz (yüklü makinede en çok bir kez; %d)" % video.seek_count)


func test_recovers_when_the_clock_runs_away() -> void:
	# Saat videodan koparsa (kare tavanının üstünde sıçrayan saat: en kötü durum) sapma sarılarak düzeltilir.
	var video := _video()
	var t := await _drive(video, 0.0, 0.3)
	var before := video.seek_count
	for i in 4:
		OS.delay_msec(300)
		await get_tree().process_frame
		t += CineRunner.MAX_STEP
		video.follow(t)
	assert_true(video.seek_count > before, "Sapma sarılır (%d)" % video.seek_count)
	t = await _drive(video, t, 0.7)
	assert_true(absf(video.playhead() - t) <= CineVideo.MAX_DRIFT, "Toparlandı: konum %.3f, saat %.3f" % [video.playhead(), t])


func test_small_drift_is_taken_by_speed_not_by_seeking() -> void:
	assert_almost(CineVideo.trim_for(0.0, 1.0), 1.0, 0.0001, "Sapma yok: normal hız")
	assert_almost(CineVideo.trim_for(0.03, 1.0), 1.0, 0.0001, "Başlama sınırının altında normal kalır")
	assert_almost(CineVideo.trim_for(0.05, 1.0), CineVideo.TRIM_FAST, 0.0001, "Video geride: hızlanır")
	assert_almost(CineVideo.trim_for(-0.05, 1.0), CineVideo.TRIM_SLOW, 0.0001, "Video önde: yavaşlar")
	assert_almost(CineVideo.trim_for(0.03, CineVideo.TRIM_FAST), CineVideo.TRIM_FAST, 0.0001, "Sınırlar arasında çarpan değişmez")
	assert_almost(CineVideo.trim_for(0.01, CineVideo.TRIM_FAST), 1.0, 0.0001, "Kapanınca normale döner")
	assert_almost(CineVideo.trim_for(0.1, 1.0, 4.0), 1.0, 0.0001, "Hızlı oynatmada sınır da büyür")
	var video := _video()
	var t := await _drive(video, 0.0, 0.2)
	# Saat 0,09 sn ileri atlar: sınırın altında, sarılmaz; video hızlanıp yetişir.
	var seeks := video.seek_count
	t += 0.09
	video.follow(t)
	assert_almost(video.player().speed_scale, CineVideo.TRIM_FAST, 0.0001, "Geride kalan video hızlanır")
	t = await _drive(video, t, 0.5)
	assert_eq(video.seek_count, seeks, "Küçük sapmada sarılmaz")
	assert_true(absf(video.playhead() - t) <= CineVideo.TRIM_START, "Yetişti: konum %.3f, saat %.3f" % [video.playhead(), t])
	assert_almost(video.player().speed_scale, 1.0, 0.0001, "Yetişince normal hız")


func test_a_seek_does_not_breed_another_seek() -> void:
	# 1080p'de sarma kareyi takar (ölçüm: en çok ≈350 ms), video ardından ≈0,15 sn geride kalır: sınırın üstündedir. Hız kapatmazsa
	# 0,5 sn sonra yeniden sarılırdı; bu da yeniden takılırdı.
	var video := _video()
	var t := await _drive(video, 0.0, 0.2)
	t += 3.0
	video.follow(t)
	var seeks := video.seek_count
	assert_true(seeks >= 1, "Sapma: sarılır")
	OS.delay_msec(300)
	await get_tree().process_frame
	t += minf(get_process_delta_time(), CineRunner.MAX_STEP)
	video.follow(t)
	t = await _drive(video, t, 1.0)
	assert_eq(video.seek_count, seeks, "Sarmanın bıraktığı sapma sarılmaz, hız alır")
	assert_true(absf(video.playhead() - t) <= CineVideo.TRIM_START, "Yetişti: konum %.3f, saat %.3f" % [video.playhead(), t])


func test_speed_comes_from_the_host_rate() -> void:
	var video := _video()
	video.speed = 4.0
	assert_almost(video.player().speed_scale, 4.0, 0.001, "VideoStreamPlayer.speed_scale")
	var t := await _drive(video, 0.0, 0.5, 4.0)
	assert_true(video.playhead() > 1.0, "Video dört kat hızlı akar (%.2f)" % video.playhead())
	assert_true(absf(video.playhead() - t) <= CineVideo.MAX_DRIFT * 4.0 + 0.1, "Saatin yanında: konum %.3f, saat %.3f" % [video.playhead(), t])
	assert_true(video.seek_count <= 1, "Hızlıyken de sürekli sarılmaz (%d)" % video.seek_count)
	video.speed = 0.0
	assert_true(video.speed > 0.0, "Hız 0 olmaz: motor bölerdi")


func test_clock_stop_pauses_the_video() -> void:
	var video := _video()
	video.follow(2.0, 100.0)
	assert_false(video.is_paused(), "Saat akarken duraklamaz")
	video.follow(2.0, 100.1)
	assert_true(video.is_paused(), "Saat durunca (dünya bekleniyor) video duraklar")
	var seeks := video.seek_count
	await wait_frames(5)
	assert_almost(video.playhead(), 2.0, 0.02, "Duraklamışken ilerlemez")
	video.follow(2.0, 101.0)
	assert_eq(video.seek_count, seeks, "Saat dururken sarılmaz")
	video.follow(2.02, 101.1)
	assert_false(video.is_paused(), "Saat yürüyünce sürer")


func test_end_holds_the_last_frame() -> void:
	var video := _video()
	var ends := watch_signal(video.player().finished)
	var t := FIXTURE_SECONDS - 0.25
	video.follow(t)
	var seeks := video.seek_count
	var deadline := Time.get_ticks_msec() + 5000
	while video.is_playing() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
		t += get_process_delta_time()
		video.follow(t)
	assert_false(video.is_playing(), "Video biter")
	assert_true(ends.fired, "finished gelir")
	assert_eq(video.seek_count, seeks, "Sona yaklaşırken sarılmaz")
	# Çakışmada saat sürer: geri sarılmaz, baştan başlamaz (motor bitince konumu 0 yazar, doku son karede kalır).
	for i in 10:
		t += 0.05
		video.follow(t)
		await get_tree().process_frame
	assert_false(video.is_playing(), "Son karede kalır")
	assert_eq(video.seek_count, seeks, "Bitince sarılmaz")
	assert_eq(ends.count, 1, "Bir kez biter")
	assert_not_null(video.player().get_video_texture(), "Doku yerinde")
	# Saat geriye gelirse (--cine-at ile geri sarma) yeniden başlar.
	video.follow(2.0)
	assert_true(video.is_playing(), "Geri gelen saat videoyu yeniden başlatır")
	assert_almost(video.playhead(), 2.0, 0.05)


func test_stop_lets_follow_start_again() -> void:
	var video := _video()
	video.follow(3.0, 100.0)
	video.stop()
	assert_false(video.is_playing(), "stop durdurur")
	assert_true(video.is_open(), "Dosya açık kalır")
	video.follow(4.0, 100.1)
	assert_true(video.is_playing(), "Sonraki follow başlatır")
	assert_almost(video.playhead(), 4.0, 0.05)
	video.close()
	assert_false(video.is_open(), "close dosyayı bırakır")
	video.follow(5.0)
	assert_false(video.is_playing(), "Kapalıyken follow bir şey yapmaz")


# --- CineVideo: dosya ----------------------------------------------------------------------------------

func test_missing_or_broken_file_stays_closed_silently() -> void:
	# Konsola hata yazan sınama düşer: bu sınamanın geçmesi motorun hata yazmadığını da söyler.
	var dir := TempDir.fresh("cine_video")
	_dirs.append(dir)
	var good := FileAccess.get_file_as_bytes(FIXTURE)
	var noise := PackedByteArray()
	noise.resize(8192)
	var vorbis := FileAccess.get_file_as_bytes("res://assets/_free/sound/crane_call_1/Grus_grus.ogg")
	var cases := {"bos.ogv": PackedByteArray(), "cop.ogv": noise, "kisa.ogv": good.slice(0, 400), "ogg_ses.ogv": vorbis.slice(0, 8192)}
	var paths := [MISSING, "", "res://icon.png"]
	for file_name: String in cases:
		var path := dir.path_join(file_name)
		var out := FileAccess.open(path, FileAccess.WRITE)
		out.store_buffer(cases[file_name])
		out.close()
		paths.append(path)
	for path: String in paths:
		assert_false(CineVideo.usable(path), "«%s» oynatılamaz" % path)
		var video := CineVideo.new()
		add_child(video)
		_trash.append(video)
		assert_false(video.open(path), "«%s» açılmaz" % path)
		assert_false(video.is_open())
		video.follow(1.0)
		assert_false(video.is_playing(), "«%s»: follow bir şey yapmaz" % path)


func test_enabled_switch_turns_the_video_off() -> void:
	assert_true(CineVideo.usable(FIXTURE), "Açıkken fixture oynatılır")
	CineVideo.enabled = false
	assert_false(CineVideo.usable(FIXTURE), "enabled kapalıyken kullanılmaz")
	var video := CineVideo.new()
	add_child(video)
	_trash.append(video)
	assert_false(video.open(FIXTURE), "enabled kapalıyken açılmaz")
	assert_true(CineVideo.is_theora(FIXTURE), "Dosya yine Theora")


# --- CineVideo: en-boy --------------------------------------------------------------------------------

func test_fit_rect_keeps_16_9_and_bars_the_rest() -> void:
	assert_eq(CineVideo.fit_rect(Vector2(1920, 1080)), Rect2(0, 0, 1920, 1080), "16:9: bant yok")
	assert_eq(CineVideo.fit_rect(Vector2(1920, 1200)), Rect2(0, 60, 1920, 1080), "16:10: üstte ve altta bant")
	assert_eq(CineVideo.fit_rect(Vector2(2520, 1080)), Rect2(300, 0, 1920, 1080), "21:9: yanlarda bant")
	assert_eq(CineVideo.fit_rect(Vector2(1440, 1080)), Rect2(0, 135, 1440, 810), "4:3")
	assert_eq(CineVideo.fit_rect(Vector2(1366, 768)), Rect2(0, 0, 1366, 768), "Neredeyse 16:9: 1 piksellik çizgi kalmaz")
	assert_eq(CineVideo.fit_rect(Vector2.ZERO), Rect2(), "Boş pencere")
	var ember := Vector2(0.5, 640.0 / 1080.0)
	assert_eq(CineVideo.screen_point(ember, Vector2(1920, 1080)), ember, "16:9'da videodaki yer ekrandaki yerdir")
	assert_almost(CineVideo.screen_point(ember, Vector2(1920, 1200)).y, 700.0 / 1200.0, 0.0001, "Bant hesaba katılır")
	assert_almost(CineVideo.screen_point(Vector2(0.0, 0.5), Vector2(2520, 1080)).x, 300.0 / 2520.0, 0.0001, "Yan bant")


func test_node_fills_its_view_and_bars_are_black() -> void:
	for size: Vector2i in [Vector2i(320, 180), Vector2i(400, 300), Vector2i(630, 180)]:
		var box := _box(size)
		var video := CineVideo.new()
		box.add_child(video)
		await wait_frames(1)
		assert_eq(video.size, Vector2(size), "%s: görünümün tamamı" % size)
		var rect := CineVideo.fit_rect(Vector2(size))
		var player := video.player()
		assert_eq(Rect2(player.position, player.size), rect, "%s: oynatıcının dikdörtgeni" % size)
		assert_true(player.expand, "Oynatıcı dikdörtgeni doldurur")
		var bars := video.get_node(^"Bars") as ColorRect
		assert_eq(bars.color, CineVideo.BAR_COLOR, "Bant videonun koyu bandının rengi: dikiş görünmez")
		assert_true(bars.color.v < 0.1, "Siyaha yakın")
		assert_eq(bars.size, Vector2(size), "%s: bant bütün görünümde, oynatıcının altında" % size)
		assert_true(bars.get_index() < player.get_index(), "Bant altta çizilir")


# --- Katman ve altyazı ----------------------------------------------------------------------------------

func test_layers_keep_the_video_between_the_filter_and_the_curtain() -> void:
	assert_eq(CineVideo.LAYER, 2, "Video katman 2'de")
	assert_true(CineHost.VIEW_LAYER < PainterlyOverlay.LAYER, "Keçe ve 3B süzgeçten geçer")
	assert_true(PainterlyOverlay.LAYER < CineVideo.LAYER, "Video süzgeçten geçmez")
	assert_true(CineVideo.LAYER < CineHost.FADE_LAYER, "Video perdenin altında")
	assert_true(CineHost.FADE_LAYER < SubtitleBar.LAYER, "Altyazı perdenin üstünde")
	var main := FileAccess.get_file_as_string("res://scenes/main.tscn")
	assert_true(main.contains("[node name=\"UI\" type=\"CanvasLayer\" parent=\".\"]\nlayer = %d" % CineHost.FADE_LAYER), "Ana sahnenin perdesi (UI/Fade) o katmanda")


func test_subtitle_moves_into_the_dark_band_and_back() -> void:
	var bar := SubtitleBar.new()
	add_child(bar)
	_trash.append(bar)
	await wait_frames(1)
	var box: Control = bar.get_node(^"Box")
	assert_almost(bar.bottom_margin(), SubtitleBar.BOTTOM_MARGIN, 0.001, "Eski yerinde başlar")
	assert_almost(box.offset_bottom, -SubtitleBar.BOTTOM_MARGIN, 0.001)
	var k := UIKit.ui_k()
	bar.video_band = true
	# Pay videonun alt kenarındandır: pencere 16:9 değilse (başsız kökün tuvali de öyle) videonun altındaki pencere bandı kadar kalkar.
	var lift := SubtitleBar.video_band_lift(box.get_viewport_rect().size) / k
	assert_almost(bar.bottom_margin(), 16.0, 0.001, "Alt pay ≈16 px")
	assert_almost(box.offset_bottom, -(16.0 + lift), 0.001)
	assert_almost(box.offset_top, -(16.0 + SubtitleBar.HEIGHT + lift), 0.001)
	assert_almost(box.scale.x, k, 0.0001, "UIKit.ui_k ölçeğiyle")
	assert_almost(box.pivot_offset.y, 16.0 + SubtitleBar.HEIGHT + lift, 0.001, "Çapa alt kenarda kalır")
	# İki satır bandın içinde: videonun koyu bandı 124 px (1080 satırda), üstü açık renkli parşömen.
	var label: Label = box.get_node(^"Text")
	var height := float(label.get_line_height())
	assert_true(height > 30.0, "Alegreya 36'nın satır yüksekliği okunur (%.1f)" % height)
	assert_true(16.0 + height * 2.0 <= SubtitleBar.VIDEO_BAND, "İki satır koyu banda sığar: 16 + 2 × %.1f ≤ 124" % height)
	# Mit satırlarının altyazısı, iki dilde de, en çok iki satıra kırılır.
	for line_id: String in CineTimeline.from_path(MYTH_SEGMENT).line_ids():
		for lang: String in ["tr", "en"]:
			var text := VoLines.subtitle(line_id, lang)
			assert_false(text.is_empty(), "%s %s altyazısı" % [line_id, lang])
			bar.set_windows([{"id": line_id, "t0": 0.0, "t1": 1.0, "text": text}])
			bar.show_at(0.5)
			await wait_frames(1)
			assert_true(label.get_line_count() <= SubtitleBar.MAX_LINES, "%s %s: %d satır" % [line_id, lang, label.get_line_count()])
	bar.video_band = false
	assert_almost(bar.bottom_margin(), SubtitleBar.BOTTOM_MARGIN, 0.001, "Video bitince eski yerine")
	assert_almost(box.offset_bottom, -SubtitleBar.BOTTOM_MARGIN, 0.001)
	assert_almost(box.offset_top, -(SubtitleBar.BOTTOM_MARGIN + SubtitleBar.HEIGHT), 0.001)
	assert_almost(box.pivot_offset.y, SubtitleBar.BOTTOM_MARGIN + SubtitleBar.HEIGHT, 0.001)


# --- Mit sahnesi ----------------------------------------------------------------------------------------

func test_myth_builds_no_felt_when_the_video_plays() -> void:
	var scene := _myth_in(_box())
	scene.setup({})
	assert_not_null(scene.video, "Video kipi")
	assert_true(scene.video.is_open(), "Dosya açık")
	assert_null(scene.strip, "Keçe şerit kurulmaz")
	assert_true(scene.panel_nodes().is_empty(), "Pano yok")
	assert_null(scene.ember_node, "Keçe köz yok")
	for path: NodePath in PrologueMyth.FELT_NODES:
		assert_null(scene.get_node_or_null(path), "%s kalkar" % path)
	assert_eq(scene.find_children("*", "MeshInstance3D", true, false).size(), 0, "3B ağ yok")
	assert_eq(scene.get_node(^"GooseHonk").get_meta(&"free_asset", ""), PrologueMyth.GOOSE_FREE_ASSET, "Kazın sesi çizelgede kalır, kaydı işaretli")
	scene.restore()
	assert_false(scene.video.is_playing(), "restore durdurur")


func test_myth_events_stay_in_video_mode() -> void:
	var scene := _myth_in(_box())
	scene.setup({})
	scene.on_shot("panel_3", {"t": 0.0})
	assert_eq(scene.current_shot, "panel_3", "Çekim izlenir")
	scene.on_shot("wide", {})
	assert_eq(scene.current_shot, "panel_3", "Bilinmeyen çekim yok sayılır")
	scene.on_event({"type": "ember"})
	assert_true(scene.ember_started, "Köz olayı boşa düşmez")
	scene.on_event({"type": "cue", "sfx": "felt_flap", "db": -12.0})
	assert_eq(scene.sounds.size(), 1, "Efektler çalar")
	scene.restore()
	assert_true(scene.sounds.is_empty())


func test_ember_position_is_the_videos_in_any_window() -> void:
	var wide := _myth_in(_box(Vector2i(320, 180)))
	wide.setup({})
	assert_eq(wide.ember_screen_position(), PrologueMyth.MYTH_EMBER_SCREEN, "16:9: videodaki yer")
	assert_almost(PrologueMyth.MYTH_EMBER_SCREEN.x, 0.5, 0.0001, "motion-studio EMBER_X 960 / 1920")
	assert_almost(PrologueMyth.MYTH_EMBER_SCREEN.y, 640.0 / 1080.0, 0.0001, "motion-studio EMBER_Y 640 / 1080")
	var square := _myth_in(_box(Vector2i(400, 300)))
	square.setup({})
	var at := square.ember_screen_position()
	assert_almost(at.x, 0.5, 0.0001)
	assert_almost(at.y, (37.5 + 640.0 / 1080.0 * 225.0) / 300.0, 0.0001, "4:3: bant hesaba katılır")


func test_myth_falls_back_to_felt_without_the_file_or_the_switch() -> void:
	for mode: String in ["kapalı", "dosya yok"]:
		if mode == "kapalı":
			CineVideo.enabled = false
		else:
			CineVideo.enabled = true
			PrologueMyth.video_path = MISSING
		var scene := _myth_in(_box())
		scene.setup({})
		assert_null(scene.video, "%s: video yok" % mode)
		assert_eq(scene.panel_nodes().size(), 6, "%s: altı keçe pano" % mode)
		assert_not_null(scene.ember_node, "%s: keçe köz" % mode)
		scene.on_shot("panel_2", {"t": 0.0})
		assert_eq(String(scene.player.assigned_animation), "panel_2", "%s: canlandırma oynar" % mode)
		scene.restore()


func test_host_keeps_the_felt_overlay_under_the_filter() -> void:
	CineVideo.enabled = false
	var host := _host()
	host.play(_short_myth())
	await _wait_until(func() -> bool: return host.scene_node("myth") != null, 10.0)
	var scene := host.scene_node("myth") as PrologueMyth
	assert_not_null(scene, "Sahne kuruldu")
	assert_null(scene.video, "Keçe yedeği")
	var viewport := host.overlay_viewport("myth")
	assert_eq((viewport.get_parent().get_parent() as CanvasLayer).layer, CineHost.VIEW_LAYER, "Keçe katman 0'da: süzgeçten geçer")
	assert_false(viewport.disable_3d, "Keçe 3B'dir")
	assert_false(host.subtitles.video_band, "Altyazı eski yerinde")
	host.stop()


func test_video_overlay_runs_over_the_filter_and_fades_at_the_end() -> void:
	var host := _host()
	host.speed = 2.0
	var watcher := watch_signal(host.finished)
	host.play(_short_myth())
	await _wait_until(func() -> bool: return host.scene_node("myth") != null, 10.0)
	var scene := host.scene_node("myth") as PrologueMyth
	assert_not_null(scene, "Sahne kuruldu")
	if scene == null:
		return
	var viewport := host.overlay_viewport("myth")
	var view := viewport.get_parent() as Control
	var layer := view.get_parent() as CanvasLayer
	assert_eq(layer.layer, CineVideo.LAYER, "Video katman 2'de: süzgecin üstünde, perdenin altında")
	assert_true(viewport.disable_3d, "SubViewport'un 3B'si çizilmez")
	assert_true(get_viewport().disable_3d, "Opak videonun altında ana 3B çizilmez (önceden çizilen dünya yok)")
	assert_true(host.subtitles.video_band, "Altyazı koyu bantta")
	assert_eq(scene.video.get_parent(), scene, "Video overlay'in SubViewport'unda")
	assert_eq(scene.video.get_viewport(), viewport)
	var video := scene.video
	# Saati izler.
	await _wait_until(func() -> bool: return host.time() >= 3.0, 15.0)
	assert_almost(video.speed, 2.0, 0.001, "Hız CineHost.speed'den")
	assert_true(absf(video.playhead() - host.time()) <= CineVideo.MAX_DRIFT * 2.0 + 0.1, "Konum %.3f, saat %.3f" % [video.playhead(), host.time()])
	assert_eq(scene.current_shot, "panel_2", "Çekim olayları sürer")
	# Son 1,5 sn: doğumun crossfade_in'i overlay'i söndürür, video akar.
	assert_almost(view.modulate.a, 1.0, 0.001, "Çakışmadan önce opak")
	await _wait_until(func() -> bool: return host.time() >= 7.3, 15.0)
	assert_true(view.modulate.a < 0.9 and view.modulate.a > 0.0, "Çakışmada söner (%.2f)" % view.modulate.a)
	assert_true(video.is_playing(), "Çakışmada video bitmez")
	assert_true(absf(video.playhead() - host.time()) <= CineVideo.MAX_DRIFT * 2.0 + 0.1, "Çakışmada da saatin yanında")
	assert_false(get_viewport().disable_3d, "Çakışmada altta 3B çizilir")
	assert_true(scene.ember_started, "Köz olayı geldi")
	await _wait_until(func() -> bool: return watcher.fired, 15.0)
	assert_eq(watcher.last_args, [false], "Dizi sonuna dek oynar")
	assert_null(host.overlay_viewport("myth"), "Overlay kalktı")
	assert_false(host.subtitles.video_band, "Video bitince altyazı eski yerine döner")
	assert_almost(host.subtitles.bottom_margin(), SubtitleBar.BOTTOM_MARGIN, 0.001)
	assert_false(get_viewport().disable_3d, "Ana 3B açık")


func test_video_overlay_predraws_the_world_then_stops_drawing_it() -> void:
	var host := _host()
	host.play(_short_myth())
	await _wait_until(func() -> bool: return host.scene_node("myth") != null, 10.0)
	assert_true(get_viewport().disable_3d, "Dünya yokken ana 3B çizilmez")
	host.show_world(Node3D.new(), "dünya")
	assert_false(get_viewport().disable_3d, "Dünya opak videonun altında önceden çizilir: gölgelendiriciler derlenir")
	await wait_frames(CineHost.VIDEO_PREDRAW_FRAMES + 2)
	assert_true(get_viewport().disable_3d, "Sonra opak videonun altında boşa çizilmez")
	host.crossfade(0.5)
	assert_false(get_viewport().disable_3d, "Sönme başlayınca altta 3B çizilir")
	host.stop()
	assert_false(get_viewport().disable_3d, "Sinema bitince ana 3B açık")


func test_felt_overlay_keeps_drawing_the_world() -> void:
	CineVideo.enabled = false
	var host := _host()
	host.play(_short_myth())
	await _wait_until(func() -> bool: return host.scene_node("myth") != null, 10.0)
	host.show_world(Node3D.new(), "dünya")
	await wait_frames(CineHost.VIDEO_PREDRAW_FRAMES + 2)
	assert_false(get_viewport().disable_3d, "Keçe yedeğinde önceden çizilen dünya çizilmeyi sürdürür (bugünkü davranış)")
	host.stop()


func test_restore_stops_following_before_the_scene_is_freed() -> void:
	# Sahne restore'dan sonra karenin sonunda silinir: o karede follow videoyu yeniden başlatıp sarsaydı 1080p'de kare takılırdı.
	var host := _host()
	host.play(_short_myth(), 3.0)
	await wait_frames(3)
	var scene := host.scene_node("myth") as PrologueMyth
	assert_true(scene.video.is_playing(), "Video oynuyor")
	var seeks := scene.video.seek_count
	scene.restore()
	await wait_frames(2)
	assert_false(scene.video.is_playing(), "restore'dan sonra yeniden başlamaz")
	assert_eq(scene.video.seek_count, seeks, "restore'dan sonra sarılmaz")
	host.stop()


func test_seek_lands_on_the_clock_without_sound() -> void:
	var fake := FakeAudio.new()
	var host := _host(fake)
	host.play(_short_myth(), 5.0)
	var scene := host.scene_node("myth") as PrologueMyth
	assert_not_null(scene, "İleri sarmada sahne kurulur")
	assert_eq(scene.current_shot, "panel_2", "İleri sarmada çekim kurulur")
	assert_true(scene.sounds.is_empty(), "İleri sarmada efekt çalmaz")
	assert_eq(fake.count("play_sfx"), 0)
	await wait_frames(3)
	assert_true(absf(scene.video.playhead() - host.time()) <= 0.2, "Video saate sarılır: konum %.3f, saat %.3f" % [scene.video.playhead(), host.time()])
	host.stop()


func test_skip_does_not_jump_the_video_to_the_end() -> void:
	InputSetup.ensure_actions()
	var host := _host()
	host.play(_short_myth(), 2.0)
	await wait_frames(3)
	var scene := host.scene_node("myth") as PrologueMyth
	var at := scene.video.playhead()
	host.skip()
	await wait_frames(3)
	assert_true(host.is_skipping() or not host.is_playing())
	if is_instance_valid(scene) and scene.video:
		assert_true(scene.video.playhead() < at + 1.0, "Atlamada saat sona sıçrar, video perde inerken sarılmaz (%.2f)" % scene.video.playhead())


func test_real_segment_plays_in_video_mode_with_every_event() -> void:
	# Fixture 10 sn, mit 2 dakikadan uzun: video bitince son karede kalır, segment sürer; sesler ve olaylar çizelgeden.
	var fake := FakeAudio.new()
	var host := _host(fake)
	host.speed = 40.0
	var watcher := watch_signal(host.finished)
	var seen := {}
	host.segment_started.connect(func(seg_id: String) -> void:
		var node := host.scene_node(seg_id) as PrologueMyth
		seen["video"] = node.video != null
		seen["ref"] = node)
	host.play(MYTH_SEGMENT)
	await _wait_until(func() -> bool: return watcher.fired, 20.0)
	assert_eq(watcher.last_args, [false], "Segment sonuna dek oynar")
	assert_true(bool(seen.get("video", false)), "Video kipi")
	var lines: Array[String] = []
	var flaps := 0
	for call: Array in fake.calls:
		if call[0] == "play_line":
			lines.append(str(call[1]))
		elif call[0] == "play_sfx" and call[1] == "felt_flap":
			flaps += 1
	assert_eq(lines.size(), 23, "3–25. satırlar çalar: %s" % [lines])
	assert_eq(flaps, 5, "Pano geçişlerinin efekti çizelgede kalır")
	assert_true(fake.count("set_layer_db") >= 30, "Cevap katmanı ve gölge")
	assert_false(host.subtitles.video_band, "Bitince altyazı eski yerinde")


# --- Doğumun son 10 sn'si -----------------------------------------------------------------------------

func test_birth_panel_8_plays_the_video_instead_of_felt() -> void:
	var scene := await _birth()
	assert_null(scene.panel, "Keçe pano kurulmaz")
	assert_null(scene.panel_camera, "Pano kamerası da")
	assert_not_null(scene.video, "Video kipi")
	assert_true(scene.video.is_open())
	assert_eq(scene.panel_layer.layer, CineVideo.LAYER, "Süzgecin üstünde, perdenin altında")
	assert_false(scene.panel_layer.visible, "panel_8'den önce gizli")
	assert_eq(scene.panel_layer.get_node(^"View"), scene.video, "Canlandırmanın izi videoyu söndürüp açar")
	assert_null(scene.panel_layer.get_node_or_null(^"View/Viewport"), "SubViewport yok")
	scene.on_shot("panel_8", {"t": 0.0})
	assert_true(scene.panel_layer.visible, "panel_8'de görünür")
	var view := scene.video as Control
	var bow: Vector3 = scene.spots["BowHung"]["pos"]
	scene.player.seek(0.2, true)
	assert_almost(view.modulate.a, 0.0, 0.01, "0,4 sn'ye dek görünmez")
	var far := scene.camera.global_position.distance_to(bow)
	scene.player.seek(1.15, true)
	assert_between(view.modulate.a, 0.2, 0.8, "0,4–1,9 sn'de belirir")
	scene.player.seek(1.9, true)
	assert_almost(view.modulate.a, 1.0, 0.01, "1,9'da tam")
	assert_almost(scene.camera.global_position.distance_to(bow), far, 0.001, "Kamera yaya yaklaşmaz (K98): uzak karede durur")
	scene.restore()
	assert_false(scene.panel_layer.visible, "restore gizler")
	assert_false(scene.video.is_playing(), "restore durdurur")


func test_birth_falls_back_to_felt() -> void:
	PrologueBirth.video_path = MISSING
	var scene := await _birth()
	assert_null(scene.video, "Dosya yok: video yok")
	assert_true(scene.panel is FeltPanel, "Keçe pano 8")
	assert_eq(scene.panel_layer.layer, CineHost.VIEW_LAYER, "Keçe boyalı süzgecin altında")
	assert_not_null(scene.panel_layer.get_node_or_null(^"View/Viewport/Stage/Panel8"), "Eski düğüm yolu")


func test_birth_video_follows_the_host_and_stops_with_the_scene() -> void:
	var host := _host(FakeAudio.new())
	host.speed = 3.0
	var timeline := CineTimeline.from_path(BIRTH_SEGMENT)
	var at := timeline.time_of("birth:panel_8") + 1.0
	var watcher := watch_signal(host.finished)
	host.play(BIRTH_SEGMENT, at)
	await _wait_until(func() -> bool: return host.scene_node("birth") != null and host.time() >= at + 0.6, READY_TIMEOUT)
	var scene := host.scene_node("birth") as PrologueBirth
	assert_not_null(scene, "Doğum sahnesi kurulu")
	if scene == null:
		return
	assert_not_null(scene.video, "Video kipi")
	assert_true(scene.panel_layer.visible, "panel_8'de görünür")
	assert_true(host.subtitles.video_band, "Altyazı koyu bantta")
	assert_false(get_viewport().disable_3d, "Video belirirken altta 3B çizilir")
	assert_almost(scene.video.speed, 3.0, 0.001, "Hız CineHost.speed'den")
	var expected := host.time() - timeline.time_of("birth:panel_8")
	assert_true(absf(scene.video.playhead() - expected) <= CineVideo.MAX_DRIFT * 3.0 + 0.2, "Konum %.3f, saat %.3f" % [scene.video.playhead(), expected])
	var p8 := timeline.time_of("birth:panel_8")
	await _wait_until(func() -> bool: return host.time() >= p8 + PrologueBirth.PANEL_OPAQUE_AT + 0.2, 10.0)
	assert_true(get_viewport().disable_3d, "Video opak olunca altındaki 3B çizilmez")
	var curtain := timeline.find("curtain", "birth")
	assert_almost(float(curtain.get("t", 0.0)), timeline.total() - 0.5, 0.001, "Son 0,5 sn perde kararır: görüntü perdenin altında gider")
	await _wait_until(func() -> bool: return host.time() >= timeline.total() - 0.05 or watcher.fired, 10.0)
	assert_true(host.fade_alpha() > 0.8, "Segment kapanırken perde kara (%.2f)" % host.fade_alpha())
	await _wait_until(func() -> bool: return watcher.fired, 20.0)
	assert_eq(watcher.last_args, [false], "Sonuna dek oynar")
	assert_false(host.subtitles.video_band, "Bitince altyazı eski yerine döner")
	assert_false(get_viewport().disable_3d, "Bitince ana 3B açık")


func test_opening_frame_puts_the_real_ember_where_the_video_has_it() -> void:
	# Pure: hedef, kameranın dikey görüş açısıyla, istenen yükseklikte görünür.
	var box := _box(Vector2i(320, 180))
	var camera := Camera3D.new()
	camera.fov = 50.0
	box.add_child(camera)
	var from := Vector3(1.0, 1.2, 2.0)
	var target := Vector3(0.2, 0.1, -1.0)
	camera.look_at_from_position(from, PrologueBirth.look_for_screen_y(from, target, 50.0, 0.6))
	var at := camera.unproject_position(target)
	assert_almost(at.x, 160.0, 0.5, "Yatayda ortada")
	assert_almost(at.y, 0.6 * 180.0, 0.5, "Yukarıdan %60'ta")
	# Mit videosu oynuyorsa 7a'nın ilk karesi: gerçek köz videodakiyle aynı yerde.
	var video_scene := await _birth(_box(Vector2i(320, 180)))
	var ember_video: Vector3 = video_scene.spots["ember"] + Vector3(0.0, 0.04, 0.0)
	var on_video := video_scene.camera.unproject_position(ember_video)
	assert_almost(on_video.x / 320.0, PrologueMyth.MYTH_EMBER_SCREEN.x, 0.01, "Köz yatayda videodaki yerde")
	assert_almost(on_video.y / 180.0, PrologueMyth.MYTH_EMBER_SCREEN.y, 0.01, "Köz dikeyde videodaki yerde")
	# Keçe yedeğinde köz ekranın ortasındadır (bugünkü çekim).
	CineVideo.enabled = false
	var felt_scene := await _birth(_box(Vector2i(320, 180)))
	var ember_felt: Vector3 = felt_scene.spots["ember"] + Vector3(0.0, 0.04, 0.0)
	var on_felt := felt_scene.camera.unproject_position(ember_felt)
	assert_almost(on_felt.y / 180.0, 0.5, 0.01, "Keçe yedeğinde köz ortada")


# --- Gerçek dosyalar ------------------------------------------------------------------------------------

func test_real_videos_match_the_line_durations() -> void:
	# Satır yeniden okunursa video yeniden işlenir (K93): süre farkını bu sınama yakalar.
	var timeline := CineTimeline.from_path(PROLOGUE)
	assert_eq(timeline.validate(), PackedStringArray())
	var myth_length := float(timeline.segment("myth")["length"])
	var birth_tail := float(timeline.segment("birth")["end"]) - timeline.time_of("birth:panel_8")
	assert_almost(birth_tail, CHILDHOOD_SECONDS, 0.001, "Geçiş 10 sn")
	_check_real_video(PrologueMyth.VIDEO_PATH, myth_length + VIDEO_TAIL, "mit videosu satır süreleriyle uyuşmuyor; motion-studio'da yeniden işle")
	_check_real_video(PrologueBirth.VIDEO_PATH, CHILDHOOD_SECONDS + VIDEO_TAIL, "Çocukluk videosu 10 + 1 sn değil; motion-studio'da yeniden işle")


func _check_real_video(path: String, want: float, message: String) -> void:
	if not FileAccess.file_exists(path):
		print("    %s yok: süre sınaması atlandı" % path)
		return
	var video := CineVideo.new()
	add_child(video)
	_trash.append(video)
	assert_true(video.open(path), "%s açılmalı (Ogg Theora)" % path)
	assert_true(absf(video.length() - want) <= DURATION_TOLERANCE, "%s (%s: %.2f sn, beklenen %.2f sn)" % [message, path, video.length(), want])
	print("    %s: %.2f sn (beklenen %.2f)" % [path, video.length(), want])


# --- Yardımcılar ---------------------------------------------------------------------------------------

func _video(path: String = FIXTURE) -> CineVideo:
	var video := CineVideo.new()
	add_child(video)
	_trash.append(video)
	assert_true(video.open(path), "%s açılmalı" % path)
	return video


## Videoyu sinema saatiyle sürer (CineHost'un saati: kare süresi, MAX_STEP tavanıyla, hız çarpanıyla). Döner: son saat.
func _drive(video: CineVideo, start: float, seconds: float, rate: float = 1.0) -> float:
	var t := start
	var left := seconds
	while left > 0.0:
		video.follow(t)
		await get_tree().process_frame
		var delta := minf(get_process_delta_time(), CineRunner.MAX_STEP)
		t += delta * rate
		left -= delta
	video.follow(t)
	return t


## Kendi dünyası olan SubViewport (CineHost'un overlay'i gibi; çizilmez).
func _box(size: Vector2i = Vector2i(320, 180)) -> SubViewport:
	var box := SubViewport.new()
	box.own_world_3d = true
	box.size = size
	box.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(box)
	_trash.append(box)
	return box


func _myth_in(box: SubViewport) -> PrologueMyth:
	var scene := (load(MYTH_SCENE) as PackedScene).instantiate() as PrologueMyth
	box.add_child(scene)
	return scene


## Doğum sahnesi (konaksız, dünyasız): bütün kişiler kurulur.
func _birth(box: SubViewport = null) -> PrologueBirth:
	var scene := (load(BIRTH_SCENE) as PackedScene).instantiate() as PrologueBirth
	if box:
		box.add_child(scene)
	else:
		add_child(scene)
		_trash.append(scene)
	scene.setup({})
	scene.build_all()
	await wait_frames(1)
	return scene


func _host(audio: Object = null) -> CineHost:
	var host := CineHost.new()
	host.audio = CineAudio.new(audio if audio else FakeAudio.new())
	add_child(host)
	_trash.append(host)
	return host


## Kısa dizi: 8 sn mit (fixture 10 sn: video segmentten uzundur), ardından 1,5 sn'lik çakışmayla kurulan ana görünüm segmenti.
func _short_myth() -> Dictionary:
	return {"id": "kisa", "segments": [
		{"id": "myth", "scene": MYTH_SCENE, "world": "none", "view": "overlay", "length": 8.0, "events": [
			{"t": 0, "type": "shot", "name": "panel_1"},
			{"t": 2, "type": "shot", "name": "panel_2"},
			{"id": "ember", "t": "end-1.5", "type": "ember", "dur": 1.5}]},
		{"id": "after", "world": "none", "view": "main", "crossfade_in": 1.5, "length": 1.0, "events": []}]}


func _wait_until(condition: Callable, timeout: float) -> void:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame


## AudioManager'ın sözleşmesini taklit eder; çağrıları sırayla kaydeder.
class FakeAudio:
	extends RefCounted

	var calls: Array = []

	func set_music_bank(bank: String, state: String, fade: float) -> void:
		calls.append(["set_music_bank", bank, state, fade])

	func set_layer_db(layer: String, db: float, sec: float) -> void:
		calls.append(["set_layer_db", layer, db, sec])

	func set_ambience_layer(id: String, db: float, sec: float) -> void:
		calls.append(["set_ambience_layer", id, db, sec])

	func low_silence(on: bool, sec: float) -> void:
		calls.append(["low_silence", on, sec])

	func black_silence(sec: float) -> void:
		calls.append(["black_silence", sec])

	func play_line(id: String, opts: Dictionary = {}) -> float:
		calls.append(["play_line", id, opts])
		return VoLines.seconds(id)

	func stop_line(fade: float = 0.3) -> void:
		calls.append(["stop_line", fade])

	func play_sfx(id: String, opts: Dictionary = {}) -> void:
		calls.append(["play_sfx", id, opts])

	func request_lines(ids: PackedStringArray) -> void:
		calls.append(["request_lines", ids])

	func release_lines(ids: PackedStringArray) -> void:
		calls.append(["release_lines", ids])

	func song_position(_id: String = "") -> float:
		return -1.0

	func count(name: String) -> int:
		var n := 0
		for call: Array in calls:
			if call[0] == name:
				n += 1
		return n
