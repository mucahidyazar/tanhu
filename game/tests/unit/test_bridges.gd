extends TestCase
## Anlatıcının iki köprüsü (Yol Haritası bridge-one, bridge-two; story.md §6, act0-text.md «Köprüler», K36, K67, K93):
##   - Çizelge çözülür: iki segment dosyası da sorunsuz, overlay, kendi dünyası yok, sahnesi bridge.tscn.
##   - Satırlar sırada: Köprü 1 N1–N5, Köprü 2 N6–N7; satır araları 0,6–1 sn; süre satırların gerçek süresinden gelir.
##   - Çekimler hikâyenin sırasında; her efekt, ortam ve müzik katmanı gerçekten vardır.
##   - Video süresi çizelgeyi karşılar: |video − (segment + 1,0)| ≤ 0,25 sn (dosya yoksa atlanır ve yazılır).
##   - Dosya yoksa da çalışır: kara ekran, satırlar, altyazı ve olaylar akar, konsola hata yazılmaz (hata yazan sınama düşer).
##   - Video varsa sinema saatini izler; altyazı koyu bantta iki satıra sığar, bitince eski yerine döner; bitişte perde karadır.
##   - İleri sarma sessizdir; atlama ortam döngülerini susturur.
## Görüntünün son onayı kullanıcınındır; pencerede kare denetimi ana oturumdadır.

const SEGMENTS := {"bridge_1": "res://data/cine/bridge_1.json", "bridge_2": "res://data/cine/bridge_2.json"}
const LINES := {
	"bridge_1": ["act0.narr.1", "act0.narr.2", "act0.narr.3", "act0.narr.4", "act0.narr.5"],
	"bridge_2": ["act0.narr.6", "act0.narr.7"],
}
const SHOTS := {
	"bridge_1": ["fox_hare", "bow", "wedding", "wall", "horizon", "heir", "migration", "dailin", "cradle"],
	"bridge_2": ["road", "gate", "ankle", "counted", "bell"],
}
const GAP_MIN := 0.6
const GAP_MAX := 1.0
## Satırların dışındaki pay: başta perde, sonda perde ve kara (sn).
const MARGIN_MAX := 4.0
const SCENE := "res://scenes/cine/bridge.tscn"
const FIXTURE := "res://tests/fixtures/t_silent.ogv"
const MISSING := "res://assets/cine/video/yok_boyle_bir_video.ogv"
const DURATION_TOLERANCE := 0.25
const MUSIC_BANK := "prologue_myth"

var _trash: Array[Node] = []


func before_each() -> void:
	Engine.time_scale = 1.0
	CineVideo.enabled = true
	PrologueBridge.video_override = FIXTURE


func after_each() -> void:
	CineVideo.enabled = true
	PrologueBridge.video_override = ""
	for node in _trash:
		if is_instance_valid(node):
			if node is CineHost:
				(node as CineHost).stop()
			node.queue_free()
	_trash.clear()
	Engine.time_scale = 1.0
	get_viewport().disable_3d = false


# --- Çizelge --------------------------------------------------------------------------------------------

func test_segments_resolve_cleanly() -> void:
	for id: String in SEGMENTS:
		var timeline := CineTimeline.from_path(SEGMENTS[id])
		assert_eq(timeline.validate(), PackedStringArray(), "%s sorunsuz çözülür" % id)
		assert_eq(timeline.id, id)
		var seg := timeline.segment(id)
		assert_false(seg.is_empty(), "%s segmenti var" % id)
		assert_eq(seg["view"], CineTimeline.VIEW_OVERLAY, "%s kendi görünümünde" % id)
		assert_eq(seg["world"], CineTimeline.WORLD_NONE, "%s dünya istemez" % id)
		assert_eq(seg["scene"], SCENE)
		assert_false(timeline.events_of("release_camp").is_empty(), "%s tek başına oynarken kampı bırakır" % id)


func test_lines_play_in_order_with_short_gaps() -> void:
	for id: String in SEGMENTS:
		var timeline := CineTimeline.from_path(SEGMENTS[id])
		var want: Array = LINES[id]
		assert_eq(Array(timeline.line_ids()), want, "%s satırları sırada" % id)
		var events := timeline.line_events()
		for i in range(1, events.size()):
			var gap := float(events[i]["t"]) - float(events[i - 1]["end"])
			assert_between(gap, GAP_MIN, GAP_MAX, "%s: %s öncesi boşluk %.2f sn" % [id, events[i]["line"], gap])


func test_length_comes_from_the_real_lines() -> void:
	for id: String in SEGMENTS:
		var timeline := CineTimeline.from_path(SEGMENTS[id])
		var spoken := 0.0
		for line_id: String in LINES[id]:
			assert_true(FileAccess.file_exists(VoLines.audio_path(line_id)), "%s kaydı var (yeniden okuma yok)" % line_id)
			spoken += VoLines.seconds(line_id)
		var gaps := timeline.line_events().size() - 1
		assert_between(timeline.total(), spoken + gaps * GAP_MIN, spoken + gaps * GAP_MAX + MARGIN_MAX,
			"%s toplam %.2f sn, söz %.2f sn" % [id, timeline.total(), spoken])
		var lines := timeline.line_events()
		for i in lines.size():
			assert_almost(float(lines[i]["duration"]), VoLines.seconds(str(lines[i]["line"])), 0.001, "Süre satırın gerçek süresi")


func test_shots_keep_the_story_order() -> void:
	for id: String in SEGMENTS:
		var timeline := CineTimeline.from_path(SEGMENTS[id])
		var names: Array = []
		var last := -1.0
		for ev in timeline.events_of("shot"):
			names.append(ev["name"])
			assert_true(float(ev["t"]) > last or float(ev["t"]) == 0.0, "%s: %s önceki çekimden sonra" % [id, ev["name"]])
			last = float(ev["t"])
		assert_eq(names, SHOTS[id], "%s çekimleri" % id)


func test_every_sound_of_the_timeline_exists() -> void:
	var def := MusicBank.load_def(MUSIC_BANK)
	for id: String in SEGMENTS:
		var timeline := CineTimeline.from_path(SEGMENTS[id])
		var clip := ""
		for ev in timeline.events_of("music"):
			assert_eq(ev.get("bank"), MUSIC_BANK, "Altta dron ve seyrek kopuz")
			clip = str(ev.get("state"))
			assert_ne(MusicBank.clip_index(def, StringName(clip)), -1, "%s klibi var" % clip)
		for ev in timeline.events_of("layer"):
			assert_ne(MusicBank.layer_index(def, StringName(clip), StringName(str(ev["layer"]))), -1, "%s katmanı var" % ev["layer"])
		for ev in timeline.events_of("cue"):
			assert_true(_sound_exists("sfx", str(ev["sfx"])), "%s: %s efekti var" % [id, ev["sfx"]])
		for ev in timeline.events_of("bed"):
			assert_true(_sound_exists("ambience", str(ev["bed"])), "%s: %s ortamı var" % [id, ev["bed"]])


func test_curtain_opens_at_the_start_and_is_black_at_the_end() -> void:
	for id: String in SEGMENTS:
		var timeline := CineTimeline.from_path(SEGMENTS[id])
		var fades := timeline.events_of("fade")
		assert_eq(fades.size(), 3, "%s: kara, açılış, kapanış" % id)
		assert_almost(float(fades[0]["to"]), 1.0, 0.001, "Karadan başlar")
		assert_almost(float(fades[1]["to"]), 0.0, 0.001, "Perde açılır")
		var close: Dictionary = fades[2]
		assert_almost(float(close["to"]), 1.0, 0.001, "Perde kapanır")
		assert_true(float(close["end"]) <= timeline.total(), "%s bittiğinde ekran kara" % id)
		var lines := timeline.line_events()
		assert_true(float(close["t"]) >= float(lines[lines.size() - 1]["end"]), "Son satır kararmadan biter")


# --- Gerçek video ----------------------------------------------------------------------------------------

func test_real_videos_cover_the_timeline() -> void:
	# Satır yeniden okunursa video yeniden işlenir (K93): süre farkını bu sınama yakalar.
	PrologueBridge.video_override = ""
	for id: String in SEGMENTS:
		var path := PrologueBridge.video_path_for(id)
		if not FileAccess.file_exists(path):
			print("    %s yok: süre sınaması atlandı" % path)
			continue
		var want := CineTimeline.from_path(SEGMENTS[id]).total() + PrologueBridge.VIDEO_TAIL
		var video := CineVideo.new()
		add_child(video)
		_trash.append(video)
		assert_true(video.open(path), "%s açılmalı (Ogg Theora)" % path)
		assert_true(absf(video.length() - want) <= DURATION_TOLERANCE,
			"%s çizelgeyle uyuşmuyor: %.2f sn, beklenen %.2f sn; motion-studio'da yeniden işle" % [path, video.length(), want])
		print("    %s: %.2f sn (beklenen %.2f)" % [path, video.length(), want])


# --- Dosyasız ---------------------------------------------------------------------------------------------

func test_plays_on_black_with_subtitles_without_the_file() -> void:
	for mode: String in ["dosya yok", "kapalı"]:
		if mode == "kapalı":
			CineVideo.enabled = false
			PrologueBridge.video_override = FIXTURE
		else:
			PrologueBridge.video_override = MISSING
		for id: String in SEGMENTS:
			var fake := FakeAudio.new()
			var host := _host(fake)
			host.speed = 30.0
			var watcher := watch_signal(host.finished)
			host.play(SEGMENTS[id])
			await _wait_until(func() -> bool: return host.scene_node(id) != null, 5.0)
			var scene := host.scene_node(id) as PrologueBridge
			assert_not_null(scene, "%s %s: sahne kuruldu" % [id, mode])
			if scene == null:
				continue
			assert_null(scene.video, "%s %s: video yok" % [id, mode])
			assert_not_null(scene.blank(), "Kara zemin")
			assert_eq(scene.blank().color, Color.BLACK)
			assert_eq(scene.blank().get_viewport(), host.overlay_viewport(id), "Kara zemin overlay'de")
			assert_true(host.subtitles.video_band, "Altyazı alttaki bantta")
			assert_eq(host.subtitles.windows().size(), (LINES[id] as Array).size(), "Her satırın altyazısı")
			await _wait_until(func() -> bool: return watcher.fired, 20.0)
			assert_eq(watcher.last_args, [false], "%s %s: sonuna dek oynar" % [id, mode])
			var played: Array = []
			for call: Array in fake.calls:
				if call[0] == "play_line":
					played.append(call[1])
			assert_eq(played, LINES[id], "%s %s: satırlar sırayla" % [id, mode])
			assert_true(host.fade_alpha() > 0.99, "Bitişte perde kara")
			assert_false(host.subtitles.video_band, "Altyazı eski yerine döner")
			assert_false(get_viewport().disable_3d, "Ana 3B açık")


func test_broken_file_is_ignored_silently() -> void:
	PrologueBridge.video_override = "res://icon.png"
	var host := _host(FakeAudio.new())
	host.play(SEGMENTS["bridge_2"])
	await _wait_until(func() -> bool: return host.scene_node("bridge_2") != null, 5.0)
	var scene := host.scene_node("bridge_2") as PrologueBridge
	assert_not_null(scene)
	assert_null(scene.video, "Theora olmayan dosya açılmaz")
	host.stop()


# --- Video kipi -------------------------------------------------------------------------------------------

func test_video_follows_the_clock_above_the_filter() -> void:
	var fake := FakeAudio.new()
	var host := _host(fake)
	host.speed = 2.0
	host.play(SEGMENTS["bridge_1"])
	await _wait_until(func() -> bool: return host.scene_node("bridge_1") != null, 5.0)
	var scene := host.scene_node("bridge_1") as PrologueBridge
	assert_not_null(scene, "Sahne kuruldu")
	if scene == null:
		return
	assert_not_null(scene.video, "Video kipi")
	var viewport := host.overlay_viewport("bridge_1")
	var layer := viewport.get_parent().get_parent() as CanvasLayer
	assert_eq(layer.layer, CineVideo.LAYER, "Süzgecin üstünde, perdenin altında")
	assert_true(viewport.disable_3d, "SubViewport'un 3B'si çizilmez")
	assert_true(get_viewport().disable_3d, "Ana 3B çizilmez")
	assert_eq(scene.video.get_viewport(), viewport, "Video overlay'de")
	await _wait_until(func() -> bool: return host.time() >= 3.0, 10.0)
	assert_almost(scene.video.speed, 2.0, 0.001, "Hız CineHost.speed'den")
	assert_true(absf(scene.video.playhead() - host.time()) <= CineVideo.MAX_DRIFT * 2.0 + 0.1, "Konum %.3f, saat %.3f" % [scene.video.playhead(), host.time()])
	assert_eq(scene.current_shot, "fox_hare", "İlk çekim")
	await _wait_until(func() -> bool: return host.time() >= 5.0, 10.0)
	assert_eq(scene.current_shot, "bow", "Çekim olayları sürer")
	host.stop()


func test_seek_sets_the_state_without_sound() -> void:
	var fake := FakeAudio.new()
	var host := _host(fake)
	host.play(SEGMENTS["bridge_1"], 20.0)
	var scene := host.scene_node("bridge_1") as PrologueBridge
	assert_not_null(scene, "İleri sarmada sahne kurulur")
	assert_eq(scene.current_shot, "horizon", "20. saniye")
	assert_true(scene.sounds.is_empty(), "İleri sarmada efekt çalmaz")
	assert_eq(fake.count("play_sfx"), 0)
	assert_eq(fake.count("play_line"), 0)
	assert_true(fake.count("set_ambience_layer") > 0, "Ortam kurulur")
	assert_almost(host.fade_alpha(), 0.0, 0.001, "Perde açık")
	await wait_frames(3)
	assert_true(absf(scene.video.playhead() - host.time()) <= 0.2 or host.time() > scene.video.length(), "Video saate sarılır")
	host.stop()


func test_skip_silences_the_beds_and_finishes() -> void:
	var fake := FakeAudio.new()
	var host := _host(fake)
	var watcher := watch_signal(host.finished)
	host.play(SEGMENTS["bridge_2"], 2.0)
	await wait_frames(3)
	var scene := host.scene_node("bridge_2") as PrologueBridge
	assert_true(scene.video.is_playing(), "Video oynuyor")
	host.skip()
	await _wait_until(func() -> bool: return watcher.fired, 5.0)
	assert_eq(watcher.last_args, [true], "Atlandı")
	var silenced := false
	for call: Array in fake.calls:
		if call[0] == "set_ambience_layer" and call[1] == "wind_steppe" and float(call[2]) <= -80.0:
			silenced = true
	assert_true(silenced, "Rüzgâr menüye taşmaz")
	assert_false(host.subtitles.video_band, "Altyazı eski yerine döner")


# --- Altyazı ----------------------------------------------------------------------------------------------

func test_subtitles_fit_two_lines_in_the_dark_band() -> void:
	var bar := SubtitleBar.new()
	add_child(bar)
	_trash.append(bar)
	await wait_frames(1)
	bar.video_band = true
	var label: Label = bar.get_node(^"Box/Text")
	assert_true(SubtitleBar.VIDEO_MARGIN + float(label.get_line_height()) * SubtitleBar.MAX_LINES <= SubtitleBar.VIDEO_BAND, "İki satır koyu banda sığar")
	for id: String in LINES:
		for line_id: String in LINES[id]:
			for lang: String in ["tr", "en"]:
				var text := VoLines.subtitle(line_id, lang)
				assert_false(text.is_empty(), "%s %s altyazısı" % [line_id, lang])
				bar.set_windows([{"id": line_id, "t0": 0.0, "t1": 1.0, "text": text}])
				bar.show_at(0.5)
				await wait_frames(1)
				assert_true(label.get_line_count() <= SubtitleBar.MAX_LINES, "%s %s: %d satır" % [line_id, lang, label.get_line_count()])


# --- Çan -------------------------------------------------------------------------------------------------

func test_bell_rings_and_dies_away() -> void:
	var recipe := CineTimeline.read_json("res://data/audio/bake/bell_step.json")
	assert_eq(recipe.get("instrument"), "bell", "Tarif kodla basılır")
	var sr := int(recipe["rate"])
	var a := SynthBell.render(recipe, SynthDsp.make_rng(int(recipe["seed"])))
	var b := SynthBell.render(recipe, SynthDsp.make_rng(int(recipe["seed"])))
	assert_eq(a.size(), int(float(recipe["seconds"]) * sr), "Süre tariften")
	assert_eq(a, b, "Aynı tohum aynı sesi basar")
	assert_almost(SynthDsp.peak(a), SynthBell.LEVEL, 0.001, "Tepe düzeyi")
	var head := SynthDsp.rms(a, 0, int(0.1 * sr))
	var tail := SynthDsp.rms(a, a.size() - int(0.2 * sr), a.size())
	assert_true(head > 0.05, "Vuruş duyulur (%.3f)" % head)
	assert_true(SynthDsp.gain_to_db(head / maxf(tail, 0.000001)) > 18.0, "Çan söner: baş %.4f, son %.5f" % [head, tail])


# --- Yardımcılar ---------------------------------------------------------------------------------------

static func _sound_exists(kind: String, id: String) -> bool:
	var dirs := ["res://audio/sfx/gen", "res://audio/sfx"] if kind == "sfx" else ["res://audio/ambience/gen", "res://audio/ambience"]
	for dir: String in dirs:
		if ResourceLoader.exists(dir.path_join(id + ".wav")):
			return true
	return false


func _host(audio: Object = null) -> CineHost:
	var host := CineHost.new()
	host.audio = CineAudio.new(audio if audio else FakeAudio.new())
	add_child(host)
	_trash.append(host)
	return host


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

	func count(name: String) -> int:
		var n := 0
		for call: Array in calls:
			if call[0] == name:
				n += 1
		return n
