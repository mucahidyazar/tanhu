extends TestCase
## Önsöz'ün mit sinemasının çizelgesi ve sesi (Yol Haritası myth-panels ve myth-audio; story.md §3 satır 1–6,
## audio.md §3 «Yeni Oyun ve Önsöz», godot.md §3.6, K35, K68, K93): data/cine/prologue_myth.json.
##   - Tahmini satır süreleriyle segment 0:38,9–3:22,2'dir (kampın segmenti yerine konur); story.md §3'ün işaretleri yerindedir.
##   - 3–25. satırlar ozanındır (David), sırayladır; hiçbiri ses zinciri (fx) taşımaz: «Erlik.» sözünü sessizlik taşır.
##   - Bütün satırlar arasında ≥1,5 sn vardır (tahmini ve gerçek sürelerle).
##   - Satır bitince answer katmanı sözün altındaki katmanın 6 dB üstüne çıkar ve ≥1,5 sn kalır; swap'ta alttaki katman o sürede susar,
##     sonra döner. Kopuz 3, 10, 11, 17, 18, 20, 23 ve 25'ten sonra cevap vermez.
##   - Müzik durumları: myth, «Erlik.»ten sonra erlik, ağaçta myth, gök panosunda tengri (koro bir kez), pano 5'te erlik, kıvılcımla myth.
##   - 3. satır karadadır; perde ondan sonra açılır. Kıvılcımdan önce 1,5 sn alçak sessizlik, fire_catch; «Erlik.»le rüzgâr kesilir;
##     17'den sonra sekiz çentik «Sekiz.»ten önce biter, 23'ten sonra sekiz çentik; pano 1'de uzak kaz ve su; pano geçişlerinde felt_flap;
##     pano 6'da nefes, doğum yurdunda dron −6 dB.
##   - Satır uzayınca sonraki pano geçişleri aynı payla kayar.
##   - Segment CineHost'ta sahnesiyle baştan sona oynar (sahte ses hedefiyle, hızlandırılmış), hata yazmaz, iz bırakmaz.
## Keçe yolu sınanır (K93): CineVideo.enabled kapalıdır, gerçek video dosyası geldiğinde de bu sınamalar keçeyi kurar; video kipi test_cine_video.gd'de.

const SEGMENT := "res://data/cine/prologue_myth.json"
const BANK := "prologue_myth"
## Kampın segmenti (story.md §3 satır 0a–0d): Yeni Oyun'dan mit sinemasına 38,9 sn.
const CAMP_LENGTH := 38.9
const TOLERANCE := 0.1
const FIRST_LINE := 3
const LAST_LINE := 25
## Sonrasında kopuzun cevap vermediği satırlar: karadaki ilk söz, adın önü ve kendisi, sabahın iki satırı (17'den sonra çentikler),
## alçak sessizliğin önü, «bizi saymaya başladı» (ardından çentikler) ve son söz.
const NO_ANSWER: Array[String] = ["act0.myth.3", "act0.myth.10", "act0.myth.11", "act0.myth.17", "act0.myth.18", "act0.myth.20", "act0.myth.23", "act0.myth.25"]
## Cevaptan sonra alttaki katmanın dönmediği satırlar: 13 gök panosuna geçer, 24 doğum yurdunda tel susar. 21'in kopuzu döner.
const NO_RETURN: Array[String] = ["act0.myth.13", "act0.myth.24"]
## Tek sözcüklük satırlar: tahminle saniyesi.
const NOTCHES_PER_COUNT := 8

var _trash: Array[Node] = []


func before_each() -> void:
	Engine.time_scale = 1.0
	CineVideo.enabled = false


func after_each() -> void:
	for node in _trash:
		if is_instance_valid(node):
			if node is CineHost:
				(node as CineHost).stop()
			node.queue_free()
	_trash.clear()
	CineVideo.enabled = true
	Engine.time_scale = 1.0
	get_viewport().disable_3d = false


# --- Zaman çizelgesi ---------------------------------------------------------------------------------

func test_segment_spans_0_38_9_to_3_22_2_with_estimates() -> void:
	var seq := _sequence(_est())
	assert_eq(seq.validate(), PackedStringArray(), "Çizelge sorunsuz çözülmeli")
	var seg := seq.segment("myth")
	assert_almost(float(seg["start"]), CAMP_LENGTH, TOLERANCE, "Mit sineması 0:38,9'da başlar")
	assert_almost(float(seg["end"]), CAMP_LENGTH + 163.3, TOLERANCE, "ve 3:22,2'de biter")
	assert_str_contains_view(str(seg["view"]))
	assert_eq(str(seg["world"]), "none")
	# story.md §3'ün işaretleri (segmentin başından).
	var marks := {"act0.myth.3": 0.5, "open": 2.9, "act0.myth.4": 4.4, "panel_2": 19.3, "act0.myth.6": 19.9, "panel_3": 29.0,
		"act0.myth.7": 29.4, "act0.myth.8": 39.5, "act0.myth.9": 51.3, "act0.myth.11": 62.8, "wind_cut": 62.8, "act0.myth.12": 67.0,
		"panel_4": 81.4, "act0.myth.14": 82.4, "panel_5": 95.1, "act0.myth.16": 95.7, "act0.myth.17": 105.1, "act0.myth.18": 109.2,
		"act0.myth.19": 112.8, "act0.myth.20": 121.1, "fire_catch": 125.8, "act0.myth.21": 126.3, "panel_6": 133.9, "act0.myth.22": 135.3,
		"act0.myth.23": 140.2, "act0.myth.24": 147.7, "act0.myth.25": 155.0, "ember": 161.8}
	for mark: String in marks:
		assert_almost(seq.time_of("myth:" + mark) - CAMP_LENGTH, float(marks[mark]), TOLERANCE, "%s story.md §3'teki saniyede" % mark)
	assert_almost(seq.time_of("myth:panel_1"), CAMP_LENGTH, TOLERANCE, "İlk çekim segmentin başında (perdenin altında)")
	var open: Dictionary = seq.find("open", "myth")
	assert_eq(open.get("type"), "fade")
	assert_almost(float(open["to"]), 0.0, 0.001, "Karadan açılır")
	assert_almost(float(open["dur"]), 2.0, 0.001, "2 sn'de")
	assert_true(float(open["t"]) >= seq.time_of("myth:act0.myth.3_end") - 0.0001, "3. satır karada biter, perde sonra açılır")


func test_lines_3_to_25_are_the_bards() -> void:
	var timeline := CineTimeline.from_path(SEGMENT)
	var ids: Array[String] = []
	for ev in timeline.line_events():
		ids.append(str(ev["line"]))
		var line_id := str(ev["line"])
		assert_eq(str(ev["type"]), "line", "%s okunan satır" % line_id)
		assert_eq(VoLines.speaker(line_id), "bard", "%s ozanın (K35)" % line_id)
		assert_eq(VoLines.tier(line_id), "A", "%s ana söz (A dilimi)" % line_id)
		assert_eq(str(ev.get("fx", "")), "", "%s: ozanın sesine zincir uygulanmaz" % line_id)
		assert_eq(VoLines.fx(line_id), "", "%s: veride de zincir yok" % line_id)
		assert_false(ev.has("pan"), "%s: ozanın sözü ortada (2B)" % line_id)
	assert_eq(ids, _lines(), "3–25. satırlar sırayla")


func test_all_lines_are_1_5_seconds_apart() -> void:
	for pair: Array in [["tahmini", _est()], ["gerçek", Callable()]]:
		var timeline := CineTimeline.from_path(SEGMENT, pair[1])
		var lines := timeline.line_events()
		for i in range(1, lines.size()):
			var prev: Dictionary = lines[i - 1]
			var cur: Dictionary = lines[i]
			var gap := float(cur["t"]) - float(prev["end"])
			assert_true(gap >= 1.5 - 0.0001, "%s: %s ile %s arası %.2f sn (≥1,5)" % [pair[0], prev["line"], cur["line"], gap])


func test_answer_layer_rises_6_db_after_the_lines() -> void:
	var timeline := CineTimeline.from_path(SEGMENT)
	var bank := MusicBank.load_def(BANK)
	var layers := timeline.events_of("layer")
	for line_ev in timeline.line_events():
		var line_id := str(line_ev["line"])
		var end := float(line_ev["end"])
		if NO_ANSWER.has(line_id):
			assert_true(_layer_event(layers, "answer", end).is_empty(), "%s: kopuz bu satırdan sonra cevap vermez" % line_id)
			continue
		var state := _state_at(timeline, end)
		var clip := MusicBank.clip(bank, StringName(state))
		var rule: Dictionary = clip.get("answer", {})
		assert_false(rule.is_empty(), "%s: %s klibinin cevap kuralı" % [line_id, state])
		var under_db := _layer_db(clip, str(rule.get("under", "")))
		var answer_db := _layer_db(clip, str(rule.get("layer", "")))
		var up := _layer_event(layers, str(rule["layer"]), end)
		assert_false(up.is_empty(), "%s: satır bitince answer katmanı çıkar" % line_id)
		if up.is_empty():
			continue
		assert_almost(float(up["db"]), under_db + 6.0, 0.001, "%s: cevap sözün altındaki %s'un 6 dB üstünde" % [line_id, rule["under"]])
		var down := _next_layer_event(layers, str(rule["layer"]), end + 0.001)
		assert_false(down.is_empty(), "%s: cevap söner" % line_id)
		if not down.is_empty():
			assert_true(float(down["t"]) - end >= 1.2 - 0.0001, "%s: cevap en az 1,2 sn durur, 0,8 sn'de söner (K61: ≥1,5)" % line_id)
			assert_true(float(down["t"]) - end + float(down["dur"]) >= 1.5, "%s: cevap ≥1,5 sn duyulur" % line_id)
			assert_almost(float(down["db"]), answer_db, 0.001, "%s: cevap bankadaki düzeyine döner" % line_id)
		if bool(rule.get("swap", false)):
			var hush := _layer_event(layers, str(rule["under"]), end)
			assert_false(hush.is_empty(), "%s: cevap çalarken alttaki %s susar (aynı anda en çok üç tel)" % [line_id, rule["under"]])
			var back := _next_layer_event(layers, str(rule["under"]), end + 0.001)
			if NO_RETURN.has(line_id):
				if line_id == "act0.myth.24":
					assert_true(back.is_empty(), "Doğum yurdunda tel susar: son cevaptan sonra kopuz dönmez")
			else:
				assert_false(back.is_empty(), "%s: cevaptan sonra %s döner" % [line_id, rule["under"]])
				if not back.is_empty():
					assert_almost(float(back["db"]), under_db, 0.001)
					assert_true(float(back["t"]) >= float(down["t"]) - 0.0001, "%s: alttaki katman cevap bitince döner" % line_id)


func test_music_states_follow_the_story() -> void:
	var seq := _sequence(_est())
	var states: Array[String] = []
	var times: Array[float] = []
	for ev in seq.events_of("music"):
		states.append(str(ev["state"]))
		times.append(float(ev["t"]))
		assert_eq(str(ev.get("bank", "")), BANK, "Mit sinemasının bankası")
	assert_eq(states, ["myth", "erlik", "myth", "tengri", "erlik", "myth"] as Array[String], "myth → erlik → myth → tengri → erlik → myth")
	assert_almost(times[0], seq.time_of("myth:open"), 0.0001, "myth perde açılırken")
	assert_almost(times[1], seq.time_of("myth:act0.myth.11_end"), 0.0001, "erlik «Erlik.» sözünden sonra: söz önce söylenir")
	assert_almost(times[2], seq.time_of("myth:act0.myth.12"), 0.0001, "ağaçta myth döner")
	assert_almost(times[3], seq.time_of("myth:panel_4"), 0.0001, "gök panosunda tengri")
	assert_almost(times[4], seq.time_of("myth:panel_5"), 0.0001, "pano 5'te erlik")
	assert_almost(times[5], seq.time_of("myth:fire_catch"), 0.0001, "kıvılcımla myth")
	var bank := MusicBank.load_def(BANK)
	for state: String in ["myth", "erlik", "tengri"]:
		assert_true(MusicBank.clip_index(bank, StringName(state)) != -1, "%s bankada" % state)
		assert_eq(DuckTable.kind_of(StringName(state)), DuckTable.NARRATIVE, "%s anlatı ve sinema kısması (−3 / −3)" % state)
	assert_eq(MusicBank.problems(bank), PackedStringArray(), "Banka geçerli")


func test_choir_once_in_the_sky_panel() -> void:
	var seq := _sequence(_est())
	var bank := MusicBank.load_def(BANK)
	var cues: Array[float] = []
	for ev in seq.events_of("music"):
		for layer: Variant in MusicBank.layers(MusicBank.clip(bank, StringName(str(ev["state"])))):
			if layer is Dictionary and MusicBank.is_choir(layer):
				cues.append(float(ev["t"]))
				break
	assert_eq(cues.size(), 1, "Sinemanın tek korosu (#53, K59)")
	if cues.size() == 1:
		assert_almost(cues[0], seq.time_of("myth:panel_4"), 0.001, "Koro gök panosunda")


func test_low_silence_before_the_spark_and_fire_catch() -> void:
	var seq := _sequence(_est())
	var silences := seq.events_of("low_silence")
	var hush := seq.find("hush", "myth")
	var fire := seq.find("fire_catch", "myth")
	assert_eq(str(fire.get("type")), "sfx", "fire_catch efekti")
	assert_almost(float(fire["t"]) - CAMP_LENGTH, 125.8, TOLERANCE, "kıvılcım 2:05,8'de (segmentin başından)")
	assert_true(bool(hush.get("on", false)), "Alçak sessizlik açılır")
	var full := float(hush["t"]) + float(hush.get("fade", 0.0))
	assert_true(float(hush["t"]) >= seq.time_of("myth:act0.myth.20_end") - 0.0001, "«Gök onları kendi başlarına bıraktı.»dan sonra")
	assert_true(float(fire["t"]) - full >= 1.5 - 0.0001, "Kıvılcımdan önce 1,5 sn alçak sessizlik")
	var off_at := -1.0
	for ev in silences:
		if not bool(ev.get("on", true)) and float(ev["t"]) > float(hush["t"]):
			off_at = float(ev["t"])
			break
	assert_almost(off_at, float(fire["t"]), 0.001, "Kıvılcımla kopuz döner")
	# Sessizlikte söz, efekt ve cevap yok.
	for ev in seq.events:
		var t := float(ev["t"])
		if t > float(hush["t"]) + 0.001 and t < float(fire["t"]) - 0.001:
			assert_true(str(ev["type"]).begins_with("_") or str(ev["type"]) == "layer" and t <= full,
					"Alçak sessizlikte olay yok: %s@%.2f" % [ev["type"], t])


func test_wind_water_geese_flaps_notches_breath_and_the_shadow() -> void:
	var seq := _sequence(_est())
	var cut := seq.find("wind_cut", "myth")
	assert_eq(str(cut.get("bed", "")), "wind_steppe")
	assert_almost(float(cut["db"]), -80.0, 0.001)
	assert_almost(float(cut["t"]), seq.time_of("myth:act0.myth.11"), 0.0001, "«Erlik.» sözüyle rüzgâr kesilir")
	var shots := seq.events_of("shot")
	var cues := seq.events_of("cue")
	var geese: Array[float] = []
	var flaps: Array[float] = []
	var breaths: Array[float] = []
	var notches: Array[float] = []
	for ev in cues:
		match str(ev.get("sfx", "")):
			"goose_honk":
				geese.append(float(ev["t"]))
			"felt_flap":
				flaps.append(float(ev["t"]))
			"breath":
				breaths.append(float(ev["t"]))
			"notch":
				notches.append(float(ev["t"]))
	assert_true(geese.size() >= 4, "Pano 1'de uzak kaz kısa ve sık (%d)" % geese.size())
	for t in geese:
		assert_eq(_panel_of(shots, t), 1, "Kaz pano 1'de")
	assert_eq(flaps.size(), 5, "Pano geçişlerinde felt_flap")
	for i in flaps.size():
		assert_almost(flaps[i], float(shots[i + 1]["t"]), 0.001, "felt_flap panel_%d geçişinde" % (i + 2))
	assert_true(breaths.size() >= 2, "Pano 6'da nefes")
	for t in breaths:
		assert_eq(_panel_of(shots, t), 6, "Nefes doğum yurdunda")
	assert_eq(notches.size(), NOTCHES_PER_COUNT * 2, "İki kez sekiz çentik")
	if notches.size() == NOTCHES_PER_COUNT * 2:
		var morning_end := seq.time_of("myth:act0.myth.17_end")
		var eight := seq.time_of("myth:act0.myth.18")
		for i in NOTCHES_PER_COUNT:
			assert_true(notches[i] > morning_end and notches[i] < eight, "%d. çentik sabahın sözü ile «Sekiz.» arasında" % (i + 1))
			assert_true(notches[i + NOTCHES_PER_COUNT] >= seq.time_of("myth:act0.myth.23_end"), "Ozan «sayar» dedikten sonra da sekiz çentik")
	var water := false
	for ev in seq.events_of("bed"):
		if str(ev["bed"]) == "water_reed" and float(ev["db"]) > -80.0 and _panel_of(shots, float(ev["t"])) == 1:
			water = true
	assert_true(water, "Pano 1'de su")
	var shadow := seq.find("shadow", "myth")
	var bank := MusicBank.load_def(BANK)
	assert_almost(float(shadow["db"]), _layer_db(MusicBank.clip(bank, &"myth"), "drone") - 6.0, 0.001, "Doğum yurdunda dron −6 dB")
	assert_eq(_panel_of(shots, float(shadow["t"])), 6)
	var ember := seq.find("ember", "myth")
	assert_almost(float(ember["t"]), float(seq.segment("myth")["end"]) - 1.5, 0.001, "Son 1,5 sn köz")


func test_longer_lines_shift_the_panel_transitions() -> void:
	var base := CineTimeline.from_path(SEGMENT, _est())
	var longer := CineTimeline.from_path(SEGMENT, func(id: String) -> float:
		return VoLines.est(id) + (1.5 if id == "act0.myth.6" else 0.0))
	assert_almost(longer.time_of("myth:panel_2") - base.time_of("myth:panel_2"), 0.0, 0.0001, "Satırdan önceki pano kaymaz")
	for mark in ["panel_3", "panel_4", "panel_5", "panel_6", "fire_catch", "ember", "act0.myth.25"]:
		assert_almost(longer.time_of("myth:" + mark) - base.time_of("myth:" + mark), 1.5, 0.0001, "%s 6. satırla 1,5 sn kayar" % mark)
	assert_almost(longer.total() - base.total(), 1.5, 0.0001, "Segment de aynı payla uzar")
	# Gerçek dosyalarla: her pano kendinden önceki satırların farkı kadar kayar.
	var real := CineTimeline.from_path(SEGMENT)
	var shift := 0.0
	var line := FIRST_LINE
	var last_before := {"panel_2": 5, "panel_3": 6, "panel_4": 13, "panel_5": 15, "panel_6": 21}
	for panel: String in last_before:
		while line <= int(last_before[panel]):
			var line_id := "act0.myth.%d" % line
			shift += VoLines.seconds(line_id) - VoLines.est(line_id)
			line += 1
		assert_almost(real.time_of("myth:" + panel) - base.time_of("myth:" + panel), shift, 0.0001, "%s gerçek sürelerle kayar" % panel)


# --- Oynatma ---------------------------------------------------------------------------------------

func test_segment_plays_through_the_host_with_its_scene() -> void:
	var fake := FakeAudio.new()
	var host := CineHost.new()
	host.audio = CineAudio.new(fake)
	add_child(host)
	_trash.append(host)
	host.speed = 40.0
	var fired: Array[String] = []
	var scene_seen := {}
	host.segment_started.connect(func(seg_id: String) -> void:
		var node := host.scene_node(seg_id)
		scene_seen["is_myth"] = node is PrologueMyth
		scene_seen["ref"] = weakref(node)
		scene_seen["viewport"] = host.overlay_viewport(seg_id) is SubViewport)
	var watcher := watch_signal(host.finished)
	host.play(SEGMENT)
	host.runner.fired.connect(func(ev: Dictionary, _seeking: bool) -> void:
		if not str(ev["type"]).begins_with("_"):
			fired.append(str(ev["type"])))
	await _wait_until(func() -> bool: return watcher.fired, 20.0)
	assert_eq(watcher.last_args, [false], "Segment sonuna dek oynamalı")
	assert_true(bool(scene_seen.get("is_myth", false)), "Segmentin sahnesi prologue_myth.tscn")
	assert_true(bool(scene_seen.get("viewport", false)), "Kendi dünyası olan SubViewport'ta (overlay)")
	# Müzik: bankanın durumları sırayla.
	var states: Array[String] = []
	for call: Array in fake.calls:
		if call[0] == "set_music_bank":
			assert_eq(call[1], BANK)
			states.append(str(call[2]))
	assert_eq(states, ["myth", "erlik", "myth", "tengri", "erlik", "myth"] as Array[String])
	# Satırlar: ozanın 23 satırı; ses zinciri yok.
	var lines: Array[String] = []
	for call: Array in fake.calls:
		if call[0] == "play_line":
			lines.append(str(call[1]))
			assert_eq(str((call[2] as Dictionary).get("fx", "")), "", "%s fx" % call[1])
	assert_eq(lines, _lines(), "3–25. satırlar çalar")
	# Efektler: kıvılcım konaktan, kaz, keçe ve nefes sahneden.
	var sfx := {}
	for call: Array in fake.calls:
		if call[0] == "play_sfx":
			sfx[call[1]] = int(sfx.get(call[1], 0)) + 1
	assert_eq(int(sfx.get("fire_catch", 0)), 1, "fire_catch bir kez")
	assert_true(int(sfx.get("goose_honk", 0)) >= 4, "Uzak kaz")
	assert_eq(int(sfx.get("felt_flap", 0)), 5, "Pano geçişleri")
	assert_true(int(sfx.get("breath", 0)) >= 2, "Nefes")
	assert_eq(int(sfx.get("notch", 0)), NOTCHES_PER_COUNT * 2, "İki kez sekiz çentik")
	var beds := {}
	for call: Array in fake.calls:
		if call[0] == "set_ambience_layer":
			beds[call[1]] = call[2]
	assert_true(beds.has("wind_steppe") and beds.has("water_reed"), "Rüzgâr ve su döngüleri: %s" % [beds])
	assert_eq(fake.count("low_silence"), 3, "Açılışta kalkar, kıvılcımdan önce iner, kıvılcımla kalkar")
	assert_true(fake.count("set_layer_db") >= 30, "Cevap katmanı ve gölge (%d)" % fake.count("set_layer_db"))
	assert_true(fired.has("ember"), "Son 1,5 sn'de köz olayı sahneye gider")
	assert_true(fake.names().has("release_lines"), "Bitince satırlar bırakılır")
	# İz yok: overlay ve sahne gitti, ana 3B açık.
	assert_null(host.overlay_viewport("myth"), "Overlay kalktı")
	assert_false(get_viewport().disable_3d, "Ana 3B yeniden çizilir")
	await wait_frames(1)
	var ref: WeakRef = scene_seen.get("ref")
	assert_true(ref != null and ref.get_ref() == null, "Sahne silindi")


func test_seek_into_the_sky_panel_builds_state_without_sound() -> void:
	var fake := FakeAudio.new()
	var host := CineHost.new()
	host.audio = CineAudio.new(fake)
	add_child(host)
	_trash.append(host)
	var timeline := CineTimeline.from_path(SEGMENT)
	host.play(SEGMENT, timeline.time_of("myth:panel_4") + 3.0)
	var scene := host.scene_node("myth") as PrologueMyth
	assert_not_null(scene)
	assert_eq(String(scene.player.assigned_animation), "panel_4", "İleri sarmada gök panosu kurulur")
	assert_true(scene.sounds.is_empty(), "İleri sarmada efekt çalmaz")
	assert_eq(fake.count("play_line"), 0, "İleri sarmada satır çalmaz")
	assert_eq(fake.count("play_sfx"), 0)
	var last_state := ""
	for call: Array in fake.calls:
		if call[0] == "set_music_bank":
			last_state = str(call[2])
			assert_almost(float(call[3]), 0.0, 0.001, "Müzik durumu geçişsiz kurulur")
	assert_eq(last_state, "tengri", "Gök panosunda tengri")
	var beds := 0
	for call: Array in fake.calls:
		if call[0] == "set_ambience_layer":
			beds += 1
			assert_almost(float(call[3]), 0.0, 0.001, "Ortam döngüsü geçişsiz kurulur")
	assert_true(beds >= 3, "Ortamın durumu ileri sarmada da kurulur")
	host.stop()


# --- Yardımcılar ---------------------------------------------------------------------------------

func _sequence(seconds: Callable) -> CineTimeline:
	return CineTimeline.from_dict({"id": "prologue", "segments": [
		{"id": "camp", "world": "none", "length": CAMP_LENGTH, "events": []},
		{"file": SEGMENT}]}, seconds)


func _est() -> Callable:
	return func(id: String) -> float: return VoLines.est(id)


func _lines() -> Array[String]:
	var out: Array[String] = []
	for n in range(FIRST_LINE, LAST_LINE + 1):
		out.append("act0.myth.%d" % n)
	return out


func assert_str_contains_view(view: String) -> void:
	assert_eq(view, "overlay", "Görüntü kendi dünyasında (CineHost overlay)")


## t anının panosu (1–6; çekimlerin sırası).
static func _panel_of(shots: Array[Dictionary], t: float) -> int:
	var panel := 0
	for i in shots.size():
		if float(shots[i]["t"]) <= t + 0.0001:
			panel = i + 1
	return panel


## t anında çalan müzik durumu (son music olayı).
static func _state_at(timeline: CineTimeline, t: float) -> String:
	var state := ""
	for ev in timeline.events_of("music"):
		if float(ev["t"]) <= t + 0.0001:
			state = str(ev["state"])
	return state


static func _layer_db(clip: Dictionary, layer_name: String) -> float:
	for layer: Variant in MusicBank.layers(clip):
		if layer is Dictionary and str(layer.get("name", "")) == layer_name:
			return float(layer.get("db", 0.0))
	return NAN


static func _layer_event(layers: Array[Dictionary], layer_name: String, t: float) -> Dictionary:
	for ev in layers:
		if str(ev["layer"]) == layer_name and absf(float(ev["t"]) - t) < 0.0005:
			return ev
	return {}


static func _next_layer_event(layers: Array[Dictionary], layer_name: String, after: float) -> Dictionary:
	for ev in layers:
		if str(ev["layer"]) == layer_name and float(ev["t"]) > after:
			return ev
	return {}


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

	func set_music_state(state: String) -> void:
		calls.append(["set_music_state", state])

	func set_layer_db(layer: String, db: float, sec: float) -> void:
		calls.append(["set_layer_db", layer, db, sec])

	func set_ambience_layer(id: String, db: float, sec: float) -> void:
		calls.append(["set_ambience_layer", id, db, sec])

	func low_silence(on: bool, sec: float) -> void:
		calls.append(["low_silence", on, sec])

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

	func song_position(_id: String = "") -> float:
		return -1.0

	func names() -> PackedStringArray:
		var out := PackedStringArray()
		for call: Array in calls:
			out.append(call[0])
		return out

	func count(name: String) -> int:
		return Array(names()).count(name)
