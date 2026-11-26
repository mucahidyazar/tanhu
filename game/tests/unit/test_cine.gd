extends TestCase
## Sinema çalıştırıcısı (Yol Haritası cine-runner, prologue-p1; godot.md §3.3, §3.6, §8.4):
##   - CineTimeline: çapa çözümü (sayı, _end, ±ofset, adlı olay, satır ve çekim adı, "end", segment zinciri),
##     satır uzayınca sonraki olayların aynı payla kayması, validate'in eksik çapa ve döngü raporu.
##   - CineRunner: aynı anın olay sırası, adımın 0,25 sn kırpması, ileri sarmada sesin çalmaması.
##   - CineHost: atlama (0,5 sn kararma, finished(true), restore), 0,6 sn'den kısa Esc'in atlamaması,
##     altyazı pencereleri (sözcük zamanı ve seconds yedeği), deneme çizelgesinin baştan sona oynaması,
##     sahnesiz segmentin kara perde ve altyazıyla akması, release_camp / restore_camp, ön yüklemenin her kare
##     sorulması, şarkıya saat kilidi, overlay görünümü, dünyası hazır olmayan segmentin beklemesi.
## Ses sahte bir hedefe gider (FakeAudio: çağrıları sırayla kaydeder). Önsöz'ün bütünü test_cine_prologue.gd'dedir.

const TEST_TIMELINE := "res://data/cine/test_timeline.json"
## Dünya yolu gereken sınamalarda var olan küçük bir sahne (örneklenmez; sınama kendi dünyasını verir).
const SOME_SCENE := "res://scenes/ui/painterly_overlay.tscn"
const PRELOAD_SCENE := "res://scenes/dev/cine_preview.tscn"

var _hosts: Array[CineHost] = []
var _trash: Array[Node] = []


func before_each() -> void:
	FakeScene.journal.clear()
	Engine.time_scale = 1.0
	InputSetup.ensure_actions()


func after_each() -> void:
	_release_escape()
	for host in _hosts:
		if is_instance_valid(host):
			host.stop()
			host.queue_free()
	_hosts.clear()
	for node in _trash:
		if is_instance_valid(node):
			node.queue_free()
	_trash.clear()
	Engine.time_scale = 1.0
	get_viewport().disable_3d = false


# --- CineTimeline ----------------------------------------------------------------------------------

func test_parse_time() -> void:
	assert_eq(CineTimeline.parse_time(6.0), {"at": 6.0})
	assert_eq(CineTimeline.parse_time(2), {"at": 2.0}, "Tam sayı da saniyedir")
	assert_eq(CineTimeline.parse_time("2.5"), {"at": 2.5}, "Sayı dizgesi saniyedir")
	assert_eq(CineTimeline.parse_time("act0.myth.3_end+8.3"), {"anchor": "act0.myth.3", "end": true, "offset": 8.3})
	assert_eq(CineTimeline.parse_time("pullback+6"), {"anchor": "pullback", "end": false, "offset": 6.0})
	assert_eq(CineTimeline.parse_time("7b+1.0"), {"anchor": "7b", "end": false, "offset": 1.0}, "Rakamla başlayan çekim adı")
	assert_eq(CineTimeline.parse_time("camp_end-1.0"), {"anchor": "camp", "end": true, "offset": -1.0})
	assert_eq(CineTimeline.parse_time("myth:panel_6"), {"anchor": "myth:panel_6", "end": false, "offset": 0.0})
	assert_eq(CineTimeline.parse_time("song_end + 0.6"), {"anchor": "song", "end": true, "offset": 0.6}, "Boşluk okunur")
	for bad: Variant in [-1.0, "-3", "x+", "", null, [1], "a-b-c", "a+b"]:
		assert_true(CineTimeline.parse_time(bad).is_empty(), "Bozuk zaman reddedilmeli: %s" % [bad])


func test_anchor_resolution_and_segment_chain() -> void:
	var timeline := CineTimeline.from_dict({"id": "seq", "segments": [
		{"id": "a", "length": "after+3", "events": [
			{"id": "m", "t": 0, "type": "music", "state": "x"},
			{"t": 1.0, "type": "line", "line": "l1"},
			{"id": "after", "t": "l1_end+0.5", "type": "shot", "name": "wide"},
			{"id": "beat", "t": "wide+2", "type": "event"},
			{"id": "early", "t": "m+0.25", "type": "event"},
			{"id": "last", "t": "end-1", "type": "fade", "to": 1.0, "dur": 1.0}]},
		{"id": "b", "events": [
			{"t": 0.5, "type": "line", "line": "l2"}]}],
		"events": [
			{"t": "b-1.0", "type": "release_camp"},
			{"id": "x", "t": "a:wide+1", "type": "event"},
			{"t": "a:l1_end", "type": "event", "id": "y"}]}, _seconds({"l1": 4.0, "l2": 2.5}))
	assert_eq(timeline.validate(), PackedStringArray(), "Çizelge sorunsuz çözülmeli")
	assert_almost(timeline.time_of("a:m"), 0.0)
	assert_almost(timeline.time_of("a:l1_end"), 5.0, 0.0001, "_end: satırın bitişi (1 + 4)")
	assert_almost(timeline.time_of("a:after"), 5.5, 0.0001, "±ofset")
	assert_almost(timeline.time_of("a:wide"), 5.5, 0.0001, "Çekimin adı da çapadır")
	assert_almost(timeline.time_of("a:beat"), 7.5, 0.0001, "Adlı olaya bağlı olay")
	assert_almost(timeline.time_of("a:early"), 0.25)
	assert_almost(float(timeline.segment("a")["length"]), 8.5, 0.0001, "length bir çapaya bağlı")
	assert_almost(timeline.time_of("a:last"), 7.5, 0.0001, "end-1: segmentin sonundan 1 sn önce")
	assert_almost(timeline.time_of("b"), 8.5, 0.0001, "Segmentin başı öncekinin sonudur")
	assert_almost(timeline.time_of("b:l2"), 9.0)
	assert_almost(timeline.time_of("b_end"), 11.5, 0.0001, "length yazılmayan segment en geç bitişte biter")
	assert_almost(timeline.total(), 11.5)
	assert_almost(timeline.time_of("l2_end"), 11.5, 0.0001, "Segment adı yazılmazsa segmentlerde aranır")
	assert_almost(float(timeline.find("x")["t"]), 6.5, 0.0001, "Dizinin olayı segment çapasına bağlanır")
	assert_almost(float(timeline.find("y")["t"]), 5.0)
	assert_almost(float(timeline.events_of("release_camp")[0]["t"]), 7.5)
	assert_true(is_nan(timeline.time_of("nowhere")), "Bilinmeyen çapa NAN")
	# Olaylar zamana göre sıralı; her segment kurulma ve kapanma iç olayı taşır.
	var last := -1.0
	for ev in timeline.events:
		assert_true(float(ev["t"]) >= last, "Olaylar zaman sırasıyla")
		last = float(ev["t"])
	assert_eq(timeline.events_of(CineTimeline.ENTER).size(), 2)
	assert_eq(timeline.events_of(CineTimeline.EXIT).size(), 2)
	assert_eq(timeline.line_ids(), PackedStringArray(["l1", "l2"]))
	var line: Dictionary = timeline.find("l1")
	assert_almost(float(line["end"]), 5.0, 0.0001, "Satırın bitişi süresinden")
	assert_eq(str(line["segment"]), "a")


func test_longer_line_shifts_later_events_by_the_same_amount() -> void:
	var def := {"id": "seq", "segments": [
		{"id": "a", "length": "out_end", "events": [
			{"id": "pre", "t": 0.5, "type": "event"},
			{"id": "fixed", "t": 2.0, "type": "event"},
			{"t": 1.0, "type": "line", "line": "l1"},
			{"id": "shot", "t": "l1_end+0.5", "type": "shot", "name": "wide"},
			{"t": "l1_end+1.0", "type": "line", "line": "l2"},
			{"id": "out", "t": "l2_end+0.2", "type": "fade", "to": 1.0, "dur": 1.0}]},
		{"id": "b", "events": [{"id": "next", "t": 0.4, "type": "event"}], "length": 2.0}]}
	var short := CineTimeline.from_dict(def, _seconds({"l1": 4.0, "l2": 3.0}))
	var long := CineTimeline.from_dict(def, _seconds({"l1": 5.5, "l2": 3.0}))
	assert_eq(short.validate(), PackedStringArray())
	for ref in ["a:pre", "a:fixed", "a:l1"]:
		assert_almost(long.time_of(ref), short.time_of(ref), 0.0001, "%s satırdan önce: kaymamalı" % ref)
	for ref in ["a:l1_end", "a:shot", "a:l2", "a:l2_end", "a:out", "a:out_end", "b", "b:next", "b_end"]:
		assert_almost(long.time_of(ref) - short.time_of(ref), 1.5, 0.0001, "%s satıra bağlı: 1,5 sn kaymalı" % ref)
	assert_almost(long.total() - short.total(), 1.5, 0.0001, "Toplam da aynı payla uzamalı")


func test_validate_reports_missing_anchor_cycle_and_bad_rows() -> void:
	var timeline := CineTimeline.from_dict({"id": "bad", "events": [
		{"id": "a", "t": "b+1", "type": "event"},
		{"id": "b", "t": "a+1", "type": "event"},
		{"t": "nowhere_end+2", "type": "event"},
		{"t": "x+", "type": "event"},
		{"t": 1.0, "type": "line", "line": "no.such.line"},
		{"t": 2.0, "type": "fade"},
		{"id": "a", "t": 3.0, "type": "event"},
		{"type": "event"}]})
	var text := "\n".join(timeline.validate())
	for fragment in ["zaman döngüsü", "bilinmeyen çapa «nowhere»", "bozuk zaman", "no.such.line", "to alanı yok", "kimlik iki kez: a", "t yok"]:
		assert_true(text.contains(fragment), "Sorun raporlanmalı: «%s»\n%s" % [fragment, text])
	var sequence := CineTimeline.from_dict({"id": "seq", "segments": [{"id": "s", "events": [], "length": 2.0}],
		"events": [{"t": "s:missing", "type": "event"}, {"t": 5.0, "type": "event"}]})
	var seq_text := "\n".join(sequence.validate())
	assert_true(seq_text.contains("bilinmeyen çapa «s:missing»"), seq_text)
	assert_true(seq_text.contains("çizelgenin sonundan"), "Sonun ötesindeki olay raporlanmalı: %s" % seq_text)
	assert_eq(CineTimeline.from_path(TEST_TIMELINE).validate(), PackedStringArray(), "Deneme çizelgesi sorunsuz olmalı")
	assert_false(CineTimeline.from_path("res://data/cine/yok.json").ok(), "Olmayan dosya kurulmaz")


# --- CineRunner ------------------------------------------------------------------------------------

func test_same_time_events_fire_in_written_order() -> void:
	var runner := CineRunner.new()
	assert_true(runner.load({"id": "s", "events": [
		{"id": "a", "t": 1.0, "type": "event"},
		{"id": "first", "t": 2.0, "type": "event"},
		{"id": "second", "t": "a+1", "type": "event"},
		{"id": "third", "t": 2, "type": "event"},
		{"id": "zero", "t": 0, "type": "event"}]}))
	var names: Array[String] = []
	runner.fired.connect(func(ev: Dictionary, _seeking: bool) -> void:
		if not str(ev["type"]).begins_with("_"):
			names.append(str(ev["id"])))
	var watcher := watch_signal(runner.finished)
	for i in 20:
		runner.step(0.25)
	assert_eq(names, ["zero", "a", "first", "second", "third"] as Array[String], "Aynı andakiler yazıldıkları sırayla")
	assert_true(watcher.fired and runner.done, "Sona varınca finished")
	assert_eq(watcher.last_args, [false])


func test_step_is_clamped_to_a_quarter_second() -> void:
	var runner := CineRunner.new()
	runner.load({"id": "s", "events": [{"t": 3.0, "type": "event"}], "length": 10.0})
	runner.step(1.0)
	assert_almost(runner.time, 0.25, 0.000001, "Uzun kare 0,25 sn sayılmalı")
	runner.step(0.1)
	assert_almost(runner.time, 0.35)
	runner.step(-1.0)
	assert_almost(runner.time, 0.35, 0.000001, "Eksi adım saati geri almaz")
	runner.hold()
	runner.step(0.2)
	assert_almost(runner.time, 0.35, 0.000001, "Tutulan saat ilerlemez")
	runner.resume()
	runner.skip()
	assert_true(runner.done and runner.skipped)
	assert_almost(runner.time, 10.0)


func test_seek_builds_state_without_playing_sound() -> void:
	var fake := FakeAudio.new()
	var audio := CineAudio.new(fake)
	var runner := CineRunner.new()
	runner.load({"id": "s", "length": 20.0, "events": [
		{"t": 0, "type": "music", "bank": "camp", "state": "camp_bard", "fade": 2.0},
		{"t": 1.0, "type": "song", "line": "act0.bard.song", "dur": 4.0},
		{"t": 2.0, "type": "layer", "layer": "drone", "db": -6.0, "dur": 3.0},
		{"t": 2.5, "type": "sfx", "id": "fire_catch"},
		{"t": "act0.bard.song_end+0.5", "type": "line", "line": "act0.myth.3"}]})
	var seen: Array = []
	runner.fired.connect(func(ev: Dictionary, seeking: bool) -> void:
		audio.handle(ev, seeking)
		seen.append([str(ev["type"]), seeking]))
	runner.seek(5.0)
	assert_eq(fake.names(), PackedStringArray(["set_music_bank", "set_layer_db"]), "İleri sarmada yalnız durum kurulmalı")
	assert_eq(fake.calls[0], ["set_music_bank", "camp", "camp_bard", 0.0], "Müzik durumu geçişsiz kurulmalı")
	assert_eq(fake.calls[1], ["set_layer_db", "drone", -6.0, 0.0])
	assert_true(seen.has(["song", true]), "Şarkı olayı seeking ile yayılmalı")
	assert_almost(runner.time, 5.0)
	while not runner.done:
		runner.step(0.25)
	assert_eq(fake.names(), PackedStringArray(["set_music_bank", "set_layer_db", "play_line"]), "Sarmadan sonra satır çalmalı")
	assert_eq(fake.calls[2][1], "act0.myth.3")


func test_voice_is_requested_preroll_before_the_line_starts() -> void:
	# Ana söz AudioManager'da kısmadan 0,15 sn sonra başlar (K78): ses isteği o kadar önce gider, satırın t'si
	# sesin başladığı an kalır (altyazı ve saat kilidi ona göre).
	var timeline := CineTimeline.from_dict({"id": "v", "length": 12.0, "events": [
		{"t": 2.0, "type": "line", "line": "act0.myth.3"},
		{"t": 0.05, "type": "song", "line": "act0.bard.song", "dur": 1.0},
		{"t": 6.0, "type": "line", "line": "free.line", "dur": 1.0}]})
	var cues := timeline.events_of(CineTimeline.VOICE)
	assert_eq(cues.size(), 3, "Her satıra bir ses isteği")
	var at := {}
	for cue in cues:
		at[cue["line"]] = float(cue["t"])
		assert_true(cue["cue"] is Dictionary and cue["cue"]["line"] == cue["line"], "İstek satırın olayını taşır")
	assert_almost(at["act0.myth.3"], 2.0 - CineAudio.PREROLL, 0.0001, "A dilimi satırın sesi 0,15 sn önce istenir")
	assert_almost(at["act0.bard.song"], 0.0, 0.0001, "İstek eksiye düşmez")
	assert_almost(at["free.line"], 6.0, 0.0001, "Ana söz olmayan satır beklemeden")
	assert_almost(timeline.time_of("act0.myth.3"), 2.0, 0.0001, "Satırın zamanı sesin başladığı an")
	var fake := FakeAudio.new()
	var host := _new_host(fake)
	var watcher := watch_signal(host.finished)
	host.speed = 4.0
	var heard := {}
	host.play({"id": "v", "world": "none", "length": 3.0, "events": [{"t": 2.0, "type": "line", "line": "act0.myth.3"}]})
	host.runner.fired.connect(func(ev: Dictionary, _seeking: bool) -> void:
		if ev["type"] == "line" and not heard.has("event"):
			heard["event"] = host.time()
			heard["calls"] = fake.count("play_line"))
	await _wait_until(func() -> bool: return watcher.fired, 5.0)
	assert_eq(fake.count("play_line"), 1, "Satır bir kez çalınmalı")
	assert_eq(int(heard.get("calls", -1)), 1, "Ses isteği satırın anından önce gitmeli")


# --- CineHost --------------------------------------------------------------------------------------

func test_skip_fades_restores_and_finishes() -> void:
	var fake := FakeAudio.new()
	var host := _new_host(fake)
	var watcher := watch_signal(host.finished)
	var holds := watch_signal(host.clock_hold_changed)
	host.play({"id": "s", "world": "none", "scene": FakeScene, "length": 40.0, "events": [
		{"t": 0.05, "type": "shot", "name": "one"},
		{"t": 30.0, "type": "event", "id": "late"}]})
	assert_true(host.is_playing())
	assert_eq(holds.last_args, [true], "Sinema başlarken saat durmalı")
	await _wait_until(func() -> bool: return FakeScene.journal.has("shot:one"), 3.0)
	assert_eq(FakeScene.journal.slice(0, 2), ["setup", "shot:one"] as Array[String])
	var started := Time.get_ticks_msec()
	host.skip()
	assert_true(host.is_skipping())
	await _wait_until(func() -> bool: return watcher.fired, 3.0)
	var took := (Time.get_ticks_msec() - started) / 1000.0
	assert_eq(watcher.last_args, [true], "Atlanınca finished(true)")
	assert_between(took, 0.4, 2.0, "Atlama 0,5 sn kararmayla bitmeli")
	assert_almost(host.fade_alpha(), 1.0, 0.001, "Atlamanın sonunda perde kara")
	assert_eq(FakeScene.journal.count("restore"), 1, "Sahnenin restore()'u bir kez çağrılmalı")
	assert_false(FakeScene.journal.has("event:late"), "Atlanan olay yayılmamalı")
	assert_true(fake.names().has("stop_line"), "Atlamada ses durmalı")
	assert_false(host.is_playing())
	assert_eq(holds.last_args, [false], "Bitince saat bırakılmalı")
	assert_eq(host.subtitles.current_text(), "")


func test_stop_during_the_skip_fade_finishes_once() -> void:
	var host := _new_host(FakeAudio.new())
	var watcher := watch_signal(host.finished)
	host.play({"id": "s", "world": "none", "scene": FakeScene, "length": 20.0, "events": []})
	await wait_frames(2)
	host.skip()
	host.stop()
	assert_eq(watcher.count, 1, "stop atlamayı hemen bitirmeli")
	await get_tree().create_timer(CineHost.SKIP_FADE + 0.3).timeout
	assert_eq(watcher.count, 1, "finished bir kez yayılmalı")
	assert_eq(FakeScene.journal.count("restore"), 1, "restore bir kez çağrılmalı")


func test_short_escape_does_not_skip_held_escape_does() -> void:
	var host := _new_host(FakeAudio.new())
	var watcher := watch_signal(host.finished)
	host.play({"id": "s", "world": "none", "length": 60.0, "events": []})
	await wait_frames(2)
	_press_escape(true)
	await get_tree().create_timer(0.3).timeout
	assert_true(host.skip_progress() > 0.2, "Basılı tutarken halka dolmalı: %f" % host.skip_progress())
	_press_escape(false)
	await wait_frames(3)
	assert_true(host.is_playing() and not host.is_skipping(), "0,6 sn'den kısa basış atlamamalı")
	assert_eq(host.skip_progress(), 0.0, "Bırakınca halka sıfırlanmalı")
	var pressed_at := Time.get_ticks_msec()
	_press_escape(true)
	await _wait_until(func() -> bool: return host.is_skipping(), 3.0)
	var held := (Time.get_ticks_msec() - pressed_at) / 1000.0
	assert_true(host.is_skipping(), "Basılı Esc atlamalı")
	assert_between(held, 0.4, 3.0, "Atlama ancak basılı tutunca (0,6 sn)")
	_press_escape(false)
	await _wait_until(func() -> bool: return watcher.fired, 3.0)
	assert_eq(watcher.last_args, [true])


func test_subtitle_windows_from_word_timing_and_seconds() -> void:
	var subs := VoLines.sub_lines("act0.bard.song")
	assert_eq(subs.size(), 2, "Şarkının iki dizesi")
	var song := SubtitleBar.line_windows("act0.bard.song", 6.0, VoLines.seconds("act0.bard.song"), "tr")
	assert_eq(song.size(), 2, "Şarkının iki dizesi kendi penceresinde")
	for i in song.size():
		assert_almost(float(song[i]["t0"]), 6.0 + float(subs[i]["t0"]), 0.0001, "Dize ilk sözcüğüyle başlar")
		assert_almost(float(song[i]["t1"]), 6.0 + float(subs[i]["t1"]) + SubtitleBar.TAIL, 0.0001, "Son sözcükten 0,4 sn sonra biter")
		assert_eq(song[i]["text"], subs[i]["tr"])
	var english := SubtitleBar.line_windows("act0.bard.song", 6.0, 27.0, "en")
	assert_eq(english[0]["text"], subs[0]["en"], "İngilizce arayüzde EN")
	# Sözcük zamanı olmayan satır: başından seconds boyunca.
	var narr := SubtitleBar.line_windows("act0.narr.1", 40.0, 6.5, "tr", [])
	assert_eq(narr.size(), 1)
	assert_almost(float(narr[0]["t0"]), 40.0)
	assert_almost(float(narr[0]["t1"]), 46.5, 0.0001, "seconds yedeği")
	assert_eq(narr[0]["text"], VoLines.subtitle("act0.narr.1", "tr"))
	# Sözcük zamanı olan satır: ilk sözcükten son sözcüğe +0,4.
	var words := [{"w": "First", "t0": 0.3, "t1": 0.7}, {"w": "water.", "t0": 0.8, "t1": 1.9}]
	var timed := SubtitleBar.line_windows("act0.myth.3", 10.0, 7.1, "tr", words)
	assert_almost(float(timed[0]["t0"]), 10.3)
	assert_almost(float(timed[0]["t1"]), 10.0 + 1.9 + SubtitleBar.TAIL)
	assert_eq(SubtitleBar.words_window(words), Vector2(0.3, 1.9))
	assert_eq(SubtitleBar.words_window([]), Vector2.ZERO)
	# Verideki her okuma satırı aynı kurala uyar: zaman dosyası varsa sözcüklerden, yoksa seconds'tan.
	for id in VoLines.ids("act0."):
		if str(VoLines.line(id).get("kind", "")) != "line":
			continue
		var real := SubtitleBar.line_windows(id, 100.0, VoLines.seconds(id), "tr")
		var span := SubtitleBar.words_window(VoLines.words(id))
		var want := Vector2(100.0 + span.x, 100.0 + span.y + SubtitleBar.TAIL) if span.y > span.x else Vector2(100.0, 100.0 + VoLines.seconds(id))
		assert_eq(real.size(), 1, id)
		if real.size() == 1:
			assert_true(Vector2(float(real[0]["t0"]), float(real[0]["t1"])).is_equal_approx(want), "%s penceresi %s, beklenen %s" % [id, real[0], want])
	# Çubuk: saatin penceresindeki metin, çakışmada son başlayan.
	var bar := SubtitleBar.new()
	add_child(bar)
	_trash.append(bar)
	var all: Array = song.duplicate()
	all.append_array(narr)
	bar.set_windows(all)
	bar.show_at(6.0 + float(subs[0]["t0"]) + 0.1)
	assert_eq(bar.current_text(), subs[0]["tr"])
	bar.show_at(6.0 + float(subs[0]["t1"]) + 0.3)
	assert_eq(bar.current_text(), subs[0]["tr"], "Dize son sözcükten 0,4 sn sonrasına dek kalır")
	bar.show_at(6.0 + float(subs[0]["t1"]) + 0.5)
	assert_eq(bar.current_text(), "", "Dizeler arasında altyazı yok")
	bar.show_at(41.0)
	assert_eq(bar.current_text(), narr[0]["text"])
	assert_eq(bar.layer, 6, "Altyazı katman 6'da")


func test_test_timeline_plays_from_start_to_end() -> void:
	var fake := FakeAudio.new()
	var host := _new_host(fake)
	# Bir karede en çok 0,25 × 12 = 3 sn akar: en kısa altyazı penceresi (≈5 sn) atlanmaz.
	host.speed = 12.0
	var camp := Node3D.new()
	add_child(camp)
	_trash.append(camp)
	host.world = camp
	var seen: Array[String] = []
	host.subtitles.changed.connect(func(text: String) -> void:
		if not text.is_empty() and not seen.has(text):
			seen.append(text))
	var watcher := watch_signal(host.finished)
	var timeline := CineTimeline.from_path(TEST_TIMELINE)
	host.play(TEST_TIMELINE)
	await _wait_until(func() -> bool: return watcher.fired, 15.0)
	assert_eq(watcher.last_args, [false], "Deneme çizelgesi sonuna dek oynamalı")
	var order := PackedStringArray()
	for name in fake.names():
		if name in ["set_music_bank", "play_song", "play_line"]:
			order.append(name)
	assert_eq(order, PackedStringArray(["set_music_bank", "play_song", "play_line"]), "Müzik işareti → şarkı → satır")
	assert_eq(fake.find("play_song")[1], "act0.bard.song")
	assert_eq(fake.find("play_line")[1], "act0.narr.1")
	assert_eq(fake.find("set_music_bank").slice(1), ["camp", "camp_bard", 2.0])
	assert_eq(fake.find("request_lines")[1], PackedStringArray(["act0.bard.song", "act0.narr.1"]), "Satırlar sinema açılırken istenmeli")
	assert_true(fake.names().has("release_lines"), "Bitince satırlar bırakılmalı")
	var subs := VoLines.sub_lines("act0.bard.song")
	assert_eq(seen, [subs[0]["tr"], subs[1]["tr"], VoLines.subtitle("act0.narr.1", "tr")] as Array[String],
		"Şarkının iki dizesi ve satırın altyazısı sırayla")
	assert_almost(host.time(), timeline.total(), 0.001)
	assert_almost(timeline.total(), 1.0 + VoLines.seconds("act0.bard.song") + 0.6 + VoLines.seconds("act0.narr.1") + 0.4 + 1.0, 0.001)
	assert_almost(host.fade_alpha(), 1.0, 0.001, "Çizelge kararmayla biter")
	assert_eq(fake.count("play_song"), 1)


func test_segment_without_scene_flows_on_black_with_subtitles() -> void:
	var host := _new_host(FakeAudio.new())
	host.speed = 6.0
	var watcher := watch_signal(host.finished)
	host.play({"id": "dark", "world": "none", "events": [
		{"t": 0, "type": "fade", "to": 1.0, "dur": 0},
		{"t": 0.2, "type": "line", "line": "act0.myth.4"}]})
	await _wait_until(func() -> bool: return not host.subtitles.current_text().is_empty(), 3.0)
	assert_eq(host.subtitles.current_text(), VoLines.subtitle("act0.myth.4", "tr"), "Dosyasız satır altyazıyla akar")
	assert_almost(host.fade_alpha(), 1.0, 0.001, "Kara perde")
	assert_true(host.subtitles.layer > CineHost.FADE_LAYER, "Altyazı perdenin üstünde")
	assert_null(host.scene_node("dark"), "Sahnesiz segment")
	await _wait_until(func() -> bool: return watcher.fired, 5.0)
	assert_eq(watcher.last_args, [false])


func test_release_and_restore_camp_bring_back_the_old_state() -> void:
	var camp := Node3D.new()
	camp.name = "CampWorld"
	var fire := Node3D.new()
	camp.add_child(fire)
	var crackle := AudioStreamPlayer3D.new()
	crackle.stream = _tone()
	fire.add_child(crackle)
	var snort := AudioStreamPlayer3D.new()
	snort.stream = _tone()
	camp.add_child(snort)
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	env.environment = environment
	camp.add_child(env)
	add_child(camp)
	_trash.append(camp)
	crackle.play()
	# 3B ses kaynağı çalmaya bir sonraki fizik karesinde başlar.
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_true(crackle.playing, "Ateş çıtırtısı çalıyor olmalı")
	var fake := FakeAudio.new()
	var host := _new_host(fake)
	host.world = camp
	host.release_camp()
	assert_true(host.is_camp_released())
	assert_true(fake.calls.has(["suspend_meadow", true]), "Kampın gece çayırı da susmalı (AudioManager'dadır)")
	assert_false(camp.visible, "Kamp gizlenmeli")
	assert_eq(camp.process_mode, Node.PROCESS_MODE_DISABLED, "Kampın süreci durmalı")
	assert_true(crackle.stream_paused, "Ateş çıtırtısı susmalı")
	assert_null(env.environment, "Kampın ortamı yeni dünyaya bırakılmalı")
	host.release_camp()
	host.restore_camp()
	assert_eq(fake.calls.count(["suspend_meadow", true]), 1, "İkinci bırakma yinelenmez")
	assert_true(fake.calls.has(["suspend_meadow", false]), "Kamp geri gelince çayır da gelmeli")
	assert_false(host.is_camp_released())
	assert_true(camp.visible)
	assert_eq(camp.process_mode, Node.PROCESS_MODE_INHERIT)
	assert_false(crackle.stream_paused, "Ses kaynağı eski hâline dönmeli")
	assert_true(crackle.playing, "Çalan kaynak çalmayı sürdürmeli")
	assert_false(snort.playing, "Çalmayan kaynak çalmaya başlamamalı")
	assert_eq(env.environment, environment, "Ortam geri gelmeli")
	# Dizi bitince bırakılan kamp kendiliğinden geri gelir.
	var watcher := watch_signal(host.finished)
	host.play({"id": "s", "world": "none", "length": 0.3, "events": [{"t": 0.1, "type": "release_camp"}]})
	await _wait_until(func() -> bool: return watcher.fired, 3.0)
	assert_true(camp.visible and not host.is_camp_released(), "Bitişte kamp geri gelmeli")
	crackle.stop()
	crackle.stream = null
	snort.stream = null


func test_preload_status_is_polled_every_frame() -> void:
	var host := _new_host(FakeAudio.new())
	host.play({"id": "s", "world": "none", "length": 60.0, "events": []})
	var asked := {"n": 0}
	host.load_status_func = func(path: String) -> int:
		asked["n"] = int(asked["n"]) + 1
		if int(asked["n"]) <= 4:
			return ResourceLoader.THREAD_LOAD_IN_PROGRESS
		return ResourceLoader.load_threaded_get_status(path)
	host.preload_world(PRELOAD_SCENE)
	assert_true(host.is_loading())
	assert_eq(host.load_state(PRELOAD_SCENE), ResourceLoader.THREAD_LOAD_IN_PROGRESS)
	var counts: Array[int] = []
	for i in 4:
		await wait_frames(1)
		counts.append(host.load_polls)
	for i in range(1, counts.size()):
		assert_eq(counts[i] - counts[i - 1], 1, "Bekleyen yükleme her kare bir kez sorulmalı: %s" % [counts])
	await _wait_until(func() -> bool: return not host.is_loading(), 10.0)
	assert_false(host.is_loading())
	assert_eq(host.load_state(PRELOAD_SCENE), ResourceLoader.THREAD_LOAD_LOADED, "Yüklenen dünya sinema boyunca tutulur")
	assert_eq(host.load_polls, int(asked["n"]))
	host.stop()
	assert_eq(host.load_state(PRELOAD_SCENE), ResourceLoader.THREAD_LOAD_INVALID_RESOURCE, "Bitince bırakılır")


func test_clock_locks_to_song_position() -> void:
	var fake := FakeAudio.new()
	var host := _new_host(fake)
	host.play({"id": "s", "world": "none", "length": 30.0, "events": [
		{"t": 0.0, "type": "song", "line": "act0.bard.song"},
		{"id": "later", "t": 2.0, "type": "event"}]})
	await wait_frames(2)
	assert_eq(fake.count("play_song"), 1)
	fake.position = 3.0
	await wait_frames(2)
	assert_almost(host.time(), 3.0, 0.1, "Saat şarkının çalış konumuna kilitlenmeli")
	assert_true(host.lock_corrections > 0)
	host.speed = 2.0
	fake.position = 10.0
	await wait_frames(2)
	assert_true(host.time() < 9.0, "Hızlandırılmış sinema kilitlenmemeli")


func test_overlay_segment_draws_its_own_world_below_the_painterly_filter() -> void:
	var host := _new_host(FakeAudio.new())
	get_viewport().disable_3d = false
	host.play({"id": "felt", "view": "overlay", "scene": FakeScene, "length": 30.0, "events": [
		{"t": 0.05, "type": "shot", "name": "panel_1"}]})
	await _wait_until(func() -> bool: return FakeScene.journal.has("shot:panel_1"), 3.0)
	var viewport := host.overlay_viewport("felt")
	assert_not_null(viewport, "Overlay segmenti SubViewport'ta")
	if viewport:
		assert_true(viewport.own_world_3d, "Kendi 3B dünyası")
		assert_eq(host.scene_node("felt").get_viewport(), viewport, "Sahne SubViewport'un içinde")
		var layer := viewport.get_parent().get_parent() as CanvasLayer
		assert_eq(layer.layer, CineHost.VIEW_LAYER)
		assert_true(layer.layer < PainterlyOverlay.LAYER, "Boyalı süzgecin altında")
	assert_true(get_viewport().disable_3d, "Opak overlay sürerken ana 3B çizilmemeli")
	host.crossfade(0.0)
	assert_false(get_viewport().disable_3d, "Overlay sönerken ana 3B açılmalı")
	host.stop()
	assert_false(get_viewport().disable_3d)
	assert_null(host.overlay_viewport("felt"))


func test_world_segment_waits_until_its_world_is_ready() -> void:
	var host := _new_host(FakeAudio.new())
	host.speed = 4.0
	var world := FakeWorld.new()
	host.show_world(world, SOME_SCENE)
	var watcher := watch_signal(host.finished)
	host.play({"id": "seq", "segments": [
		{"id": "one", "world": "none", "length": 1.0, "events": []},
		{"id": "two", "world": SOME_SCENE, "scene": FakeScene, "length": 1.0, "events": [{"t": 0.0, "type": "event", "id": "go"}]}]})
	await _wait_until(func() -> bool: return host.time() >= 0.999, 3.0)
	await wait_frames(5)
	assert_almost(host.time(), 1.0, 0.001, "Dünya hazır değilken saat segmentin başında beklemeli")
	assert_false(FakeScene.journal.has("event:go"))
	world.ready_flag = true
	await _wait_until(func() -> bool: return watcher.fired, 3.0)
	assert_eq(watcher.last_args, [false])
	assert_true(FakeScene.journal.has("event:go"), "Hazır olunca segment oynamalı")
	assert_eq(FakeScene.journal.count("restore"), 1)
	assert_true(not is_instance_valid(world) or world.is_queued_for_deletion(), "Dizi bitince örneklenen dünya bırakılmalı")


func test_card_and_fade_follow_cine_time_after_seek() -> void:
	var host := _new_host(FakeAudio.new())
	host.play({"id": "c", "world": "none", "length": 10.0, "events": [
		{"t": 0.0, "type": "fade", "to": 1.0, "dur": 2.0},
		{"t": 0.5, "type": "card", "text": {"tr": "27 Eylül MÖ 234 · Ordos", "en": "27 September 234 BC · Ordos"}, "dur": 4.0}]}, 1.0)
	assert_almost(host.fade_alpha(), 0.5, 0.05, "İleri sarılan kararma yarıdan sürmeli")
	assert_eq(host.card_text(), "27 Eylül MÖ 234 · Ordos", "Kart Türkçe arayüzde TR")
	await _wait_until(func() -> bool: return host.fade_alpha() > 0.99, 3.0)
	assert_almost(host.fade_alpha(), 1.0, 0.01)


func test_cine_audio_passes_silently_without_methods() -> void:
	var empty := CineAudio.new(RefCounted.new())
	empty.handle({"type": "song", "line": "act0.bard.song"})
	empty.handle({"type": "music", "bank": "camp", "state": "camp_bard"})
	empty.stop_all()
	assert_eq(empty.song_position("act0.bard.song"), -1.0)
	var none := CineAudio.new(null)
	none.handle({"type": "line", "line": "act0.myth.3"})
	none.request_lines(PackedStringArray(["act0.myth.3"]))
	assert_null(none.call_target(&"play_line", ["x"]))
	var short := ShortAudio.new()
	CineAudio.new(short).handle({"type": "line", "line": "act0.myth.3", "pan": 0.1})
	assert_eq(short.lines, ["act0.myth.3"], "Fazla argüman hedefin yöntemine göre kırpılmalı")
	var fake := FakeAudio.new()
	var audio := CineAudio.new(fake)
	audio.handle({"type": "music", "state": "myth"})
	audio.handle({"type": "low_silence", "on": true, "fade": 3.0})
	audio.stop_all(0.5)
	assert_eq(fake.calls, [["set_music_state", "myth"], ["low_silence", true, 3.0], ["stop_line", 0.5], ["low_silence", false, 0.5]])


func test_preview_scene_plays_a_file_without_main() -> void:
	var preview: Node = load("res://scenes/dev/cine_preview.tscn").instantiate()
	preview.set(&"autoplay", false)
	preview.set(&"use_world", false)
	preview.set(&"speed", 40.0)
	preview.set(&"cine_path", TEST_TIMELINE)
	add_child(preview)
	_trash.append(preview)
	var host: CineHost = preview.get(&"host")
	host.audio = CineAudio.new(FakeAudio.new())
	var watcher := watch_signal(host.finished)
	preview.call(&"play")
	assert_true(host.is_playing())
	await _wait_until(func() -> bool: return watcher.fired, 10.0)
	assert_eq(watcher.last_args, [false], "Önizleme ana sahne olmadan sonuna dek oynamalı")
	assert_eq(int(preview.get(&"plays")), 1)


# --- Yardımcılar -----------------------------------------------------------------------------------

func _new_host(fake: FakeAudio) -> CineHost:
	var host := CineHost.new()
	host.audio = CineAudio.new(fake)
	add_child(host)
	_hosts.append(host)
	return host


static func _seconds(table: Dictionary) -> Callable:
	return func(line_id: String) -> float: return float(table.get(line_id, 0.0))


func _press_escape(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.physical_keycode = KEY_ESCAPE
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _release_escape() -> void:
	for action in CineHost.SKIP_ACTIONS:
		if InputMap.has_action(action):
			Input.action_release(action)


func _wait_until(condition: Callable, timeout: float) -> void:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame


## Yarım saniyelik sessiz döngü (ses kaynağının çalıyor görünmesi için).
static func _tone() -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var data := PackedByteArray()
	data.resize(22050)
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = 11025
	return wav


## AudioManager'ın sözleşmesini taklit eder; çağrıları sırayla kaydeder.
class FakeAudio:
	extends RefCounted

	var calls: Array = []
	## song_position'ın döndürdüğü konum (-1: çalmıyor).
	var position := -1.0

	func set_music_bank(bank: String, state: String, fade: float) -> void:
		calls.append(["set_music_bank", bank, state, fade])

	func set_music_state(state: String) -> void:
		calls.append(["set_music_state", state])

	func set_layer_db(layer: String, db: float, sec: float) -> void:
		calls.append(["set_layer_db", layer, db, sec])

	func set_ambience_layer(id: String, db: float, sec: float) -> void:
		calls.append(["set_ambience_layer", id, db, sec])

	func low_silence(on: bool, sec: float) -> void:
		calls.append(["low_silence", on, sec])

	func suspend_meadow(on: bool) -> void:
		calls.append(["suspend_meadow", on])

	func black_silence(sec: float) -> void:
		calls.append(["black_silence", sec])

	func play_song(id: String) -> void:
		calls.append(["play_song", id])

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

	func play_music(track: StringName, fade: float = 3.0) -> void:
		calls.append(["play_music", track, fade])

	func song_position(_id: String = "") -> float:
		return position

	func names() -> PackedStringArray:
		var out := PackedStringArray()
		for call: Array in calls:
			out.append(call[0])
		return out

	func count(name: String) -> int:
		return Array(names()).count(name)

	func find(name: String) -> Array:
		for call: Array in calls:
			if call[0] == name:
				return call
		return []


## Yalnız tek argümanlı play_line'ı olan hedef (argüman kırpma sınaması).
class ShortAudio:
	extends RefCounted

	var lines: Array = []

	func play_line(id: String) -> void:
		lines.append(id)


## Olayları paylaşılan günlüğe yazan sahne (konak onu kurup sildiği için günlük sınıftadır).
class FakeScene:
	extends CineScene

	static var journal: Array[String] = []

	func setup(p_ctx: Dictionary) -> void:
		super.setup(p_ctx)
		journal.append("setup")

	func on_shot(shot_name: String, _ev: Dictionary) -> void:
		journal.append("shot:%s%s" % [shot_name, ":seek" if seeking else ""])

	func on_event(ev: Dictionary) -> void:
		journal.append("%s:%s%s" % [ev["type"], ev["id"], ":seek" if seeking else ""])

	func restore() -> void:
		journal.append("restore")


## Hazır olması beklenen dünya.
class FakeWorld:
	extends Node3D

	var ready_flag := false

	func is_ready() -> bool:
		return ready_flag


## İki satıra düşen altyazı dengeli bölünür, noktalamadan kesilir; sığan yazıya ve elle kesilmiş satıra dokunulmaz.
func test_subtitle_lines_break_at_sense() -> void:
	var font := ThemeDB.fallback_font
	var text := "Şafakta Tanhu çadırından çıktı, doğan güne eğildi; batıda dolunay daha batmamıştı."
	var full := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 36).x
	assert_eq(SubtitleBar.balanced(text, font, 36, full * 0.9),
			"Şafakta Tanhu çadırından çıktı, doğan güne eğildi;\nbatıda dolunay daha batmamıştı.", "Noktalamadan kesilir")
	assert_eq(SubtitleBar.balanced(text, font, 36, full + 1.0), text, "Sığan yazı tek satır kalır")
	assert_eq(SubtitleBar.balanced("Bir\niki", font, 36, 1.0), "Bir\niki", "Elle kesilmiş satıra dokunulmaz")
	var plain := "bir iki üç dört beş altı yedi sekiz dokuz on"
	var plain_w := font.get_string_size(plain, HORIZONTAL_ALIGNMENT_LEFT, -1, 36).x
	var lines := SubtitleBar.balanced(plain, font, 36, plain_w * 0.7).split("\n")
	assert_eq(lines.size(), 2, "İki satıra bölünür")
	var gap := absf(font.get_string_size(lines[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 36).x - font.get_string_size(lines[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 36).x)
	assert_true(gap < plain_w * 0.25, "İki satır yakın boyda: fark %.0f" % gap)
