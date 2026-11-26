extends TestCase
## Oturum (Session; godot.md §3.1, §3.4; Yol Haritası session-core): sistem sırası, saat başı adımı, yoldaşların 11b adımı, sinyaller,
## saatin durma nedenleri, oto kayıt kuralları, saat bloğu, koşul bağlamı ve etkiler. Saf sınamalar oturumu ağaçsız ya da kendi
## düğümünde kurar (auto_tick kapalı, tick elle); son sınama gerçek ana sahnede Serbest Gez → duraklatma → Ana Menü → Devam Et akışında
## oturumun kurulduğunu, saatin durduğunu, kaydın saat bloğunu taşıdığını ve menüde oturumun silindiğini sınar.
##   - Sıra: 1 clock, 2 calendar, 3 weather, 4 needs, 5 sites, 6 settlement (yalnız saat başında), 7 schedule, 8 fauna, 9 stealth,
##     10 combat, 11 quests (sonra sıradaki etkiler), 11b party, 12 audio.
##   - Durma nedenleri dialogue, cine, modal, map, pause: her biri saati durdurur; iki sahip aynı nedeni tutabilir; ağacın duraklatılması
##     «pause»u, sinema konağı «cine»yi tutar.
##   - Oto kayıt: bilinmeyen neden hata; zorunlular engele bakmaz; region ve caravan ≥60 sn arayla; wait ve work ≥1 oyun saatinde;
##     saatin atlaması ve hikâye kipinde Tan kendiliğinden ister; sinema ve engel öteki nedenleri düşürür.

const TempDir := preload("res://tests/support/temp_dir.gd")
const MAIN_SCENE := "res://scenes/main.tscn"

var _dir := ""
var _nodes: Array[Node] = []


func before_each() -> void:
	_dir = TempDir.fresh("oturum")


func after_each() -> void:
	get_tree().paused = false
	for n in _nodes:
		if is_instance_valid(n):
			n.queue_free()
	_nodes.clear()
	TempDir.wipe(_dir)


func _session(mode: StringName = Session.MODE_ROAM, journey: Journey = null) -> Session:
	var s := Session.new()
	s.auto_tick = false
	assert_eq(s.setup(journey if journey else Journey.new(SaveSystem.new(_dir)), mode), "", "Oturum kurulmalı")
	return s


# --- Sıra ------------------------------------------------------------------------------------------------------

func test_steps_are_the_designed_order() -> void:
	assert_eq(Session.STEPS, [&"clock", &"calendar", &"weather", &"needs", &"sites", &"settlement", &"schedule", &"fauna", &"stealth",
		&"combat", &"quests", &"party", &"audio"] as Array[StringName], "godot.md §3.1'in sırası")
	var labels := PackedStringArray()
	for step in Session.STEPS:
		labels.append(str(Session.STEP_LABELS[step]))
	assert_eq(labels, PackedStringArray(["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "11b", "12"]), "Yoldaşlar 11b")
	assert_eq(Session.HOURLY, [&"settlement"] as Array[StringName], "Yerleşim yalnız saat başında")
	assert_eq(Session.PAUSE_REASONS, [&"dialogue", &"cine", &"modal", &"map", &"pause"] as Array[StringName])


func test_tick_runs_members_in_step_order() -> void:
	var s := _session()
	var log: Array = []
	var shuffled: Array = Session.STEPS.duplicate()
	shuffled.reverse()
	for step: StringName in shuffled:
		if step == &"clock":
			continue
		if step == &"settlement":
			assert_true(s.add_system(step, _Hourly.new(log, String(step))))
		else:
			assert_true(s.add_system(step, func(_dt: float) -> void: log.append(String(step)), StringName("probe_%s" % step)))
	var clock_seen := []
	s.add_system(&"calendar", func(_dt: float) -> void: clock_seen.append(s.clock.minute), &"calendar_reads_clock")
	var before := s.clock.minute
	s.tick(0.25)
	var expected := []
	for step: StringName in Session.STEPS:
		if step != &"clock" and step != &"settlement":
			expected.append(String(step))
	assert_eq(log, expected, "Üyeler adımların sırasıyla (eklenme sırası önemsiz); yerleşim saat başı yoksa çalışmaz")
	assert_true(clock_seen[0] > before, "Saat adım 1'de, takvimden önce ilerler")
	assert_eq(s.members(&"calendar"), [&"probe_calendar", &"calendar_reads_clock"] as Array[StringName], "Adımın içinde eklenme sırası")
	s.free()


func test_settlement_steps_only_on_the_hour() -> void:
	var s := _session()
	var log: Array = []
	var hourly := _Hourly.new(log, "settlement")
	s.add_system(&"settlement", hourly, &"settlement")
	s.tick(0.25)
	assert_eq(hourly.hours.size(), 0, "Saat başı yoksa yerleşim adım atmaz")
	# 14:46,2'den saat başına 13,8 dk; 34 sn sonra 15:00 geçilir.
	for i in 140:
		s.tick(0.25)
	assert_eq(hourly.hours.size(), 1, "15:00'te bir kez: %s" % JSON.stringify(hourly.hours))
	assert_eq(int(hourly.hours[0]["hour"]), 15)
	assert_false(bool(hourly.hours[0]["skipping"]))
	s.clock.skip(150.0, &"wait")
	assert_eq(hourly.hours.size(), 1, "Atlamanın saatleri bir sonraki karede işlenir")
	s.tick(0.0)
	assert_eq(hourly.hours.size(), 3, "16:00 ve 17:00 sırayla, atlama olarak")
	assert_true(bool(hourly.hours[2]["skipping"]))
	s.tick(0.25)
	assert_eq(hourly.hours.size(), 3, "Bir saat başı bir kez işlenir")
	s.free()


func test_party_follows_quests_and_queued_effects() -> void:
	var s := _session()
	var log: Array = []
	var quests := func(_dt: float) -> void:
		log.append("quests")
		s.queue_effects([["flag", "quest_effect"]], "mq_test")
	s.add_system(&"quests", quests, &"quests")
	s.add_system(&"party", func(_dt: float) -> void: log.append("party:%s" % s.journey.has_flag("quest_effect")), &"party")
	s.add_system(&"audio", func(_dt: float) -> void: log.append("audio"), &"audio")
	s.add_system(&"combat", func(_dt: float) -> void: log.append("combat:%s" % s.journey.has_flag("quest_effect")), &"combat")
	s.tick(0.1)
	assert_eq(log, ["combat:false", "quests", "party:true", "audio"], "Etkiler adım 11'de, yoldaşlardan (11b) önce")
	s.free()


func test_members_are_validated_and_removable() -> void:
	var s := _session()
	expect_errors(["bilinmeyen adım", "adımının üyesinde step yok", "kimliği zaten var"])
	assert_false(s.add_system(&"teleport", func(_dt: float) -> void: pass), "Bilinmeyen adım")
	assert_false(s.add_system(&"needs", RefCounted.new()), "step'i olmayan nesne")
	assert_true(s.add_system(&"needs", func(_dt: float) -> void: pass, &"needs_a"))
	assert_false(s.add_system(&"fauna", func(_dt: float) -> void: pass, &"needs_a"), "Aynı kimlik")
	var obj := _Stepper.new()
	assert_true(s.add_system(&"fauna", obj, &"fauna_director"))
	assert_true(is_same(s.get_system(&"fauna_director"), obj))
	s.tick(0.5)
	assert_almost(obj.total, 0.5, 1e-9, "Nesnenin step(dt)'si")
	assert_true(s.remove_system(&"fauna_director"))
	assert_null(s.get_system(&"fauna_director"))
	s.tick(0.5)
	assert_almost(obj.total, 0.5, 1e-9, "Kaldırılan üye çalışmaz")
	var node := _StepNode.new()
	s.add_system(&"schedule", node, &"schedule_node")
	node.free()
	s.tick(0.1)
	s.tick(0.1)
	assert_null(s.get_system(&"schedule_node"), "Silinen nesne hatasız ayıklanır")
	s.free()


# --- Saat ve durma nedenleri ----------------------------------------------------------------------------------

func test_roam_and_story_default_clocks() -> void:
	var s := _session(Session.MODE_ROAM)
	assert_eq(s.clock.day_n, 1171, "Serbest Gez: 11 Nisan MÖ 209")
	assert_eq(s.clock.text(), "14:46")
	assert_true(s.clock.has_place(), "Ana kampın yeri: evreler")
	assert_eq(s.journey.map, "camp")
	assert_eq(String(s.clock.phase()), "golden", "İkindi")
	s.free()
	var j := Journey.new(SaveSystem.new(_dir))
	j.reset()
	j.set_flag(NewGameFlow.DAY_FLAG, 1041)
	var story := _session(Session.MODE_STORY, j)
	assert_eq(story.clock.day_n, 1041, "Hikâye: takvim günü (Gün I)")
	assert_eq(j.mode, "story")
	story.free()


func test_each_pause_reason_stops_the_clock() -> void:
	var s := _session()
	var changes: Array = []
	s.pause_changed.connect(func(r: StringName, on: bool) -> void: changes.append([String(r), on]))
	for reason in Session.PAUSE_REASONS:
		var before := s.clock.abs_minute()
		s.set_pause(reason, true)
		s.tick(0.25)
		assert_almost(s.clock.abs_minute(), before, 1e-12, "%s saati durdurur" % reason)
		assert_true(s.is_paused_by(reason))
		s.set_pause(reason, false)
		s.tick(0.25)
		assert_true(s.clock.abs_minute() > before, "%s kalkınca saat akar" % reason)
	assert_eq(changes.size(), 10, "Her nedenin açılışı ve kapanışı bir kez")
	s.set_pause(&"modal", true, &"level_screen")
	s.set_pause(&"modal", true, &"road_card")
	s.set_pause(&"modal", true, &"road_card")
	s.set_pause(&"modal", false, &"level_screen")
	assert_true(s.is_paused_by(&"modal"), "İkinci sahip hâlâ tutuyor")
	assert_true(s.clock.is_paused_by(&"modal"), "Saatin kendisi de durur")
	assert_eq(s.pause_owners(&"modal"), PackedStringArray(["road_card"]))
	s.set_pause(&"dialogue", true)
	assert_eq(s.pause_reasons(), PackedStringArray(["dialogue", "modal"]), "Sıralı")
	s.set_pause(&"modal", false, &"road_card")
	s.set_pause(&"dialogue", false)
	assert_false(s.clock.is_paused())
	s.free()


func test_tree_pause_and_cine_hold_the_clock() -> void:
	var s := _session()
	add_child(s)
	_nodes.append(s)
	await wait_frames(1)
	get_tree().paused = true
	assert_true(s.is_paused_by(&"pause"), "Duraklatma kitabı ağacı durdurur: «pause»")
	assert_true(s.clock.is_paused_by(&"pause"))
	get_tree().paused = false
	assert_false(s.is_paused_by(&"pause"))
	var host := _FakeCine.new()
	s.bind_cine(host)
	host.clock_hold_changed.emit(true)
	assert_true(s.is_paused_by(&"cine"), "Sinema saati durdurur")
	assert_true(s.autosave_blocked(), "Sinemada oto kayıt yazılmaz")
	host.clock_hold_changed.emit(false)
	assert_false(s.is_paused_by(&"cine"))
	var playing := _FakeCine.new()
	playing.playing = true
	s.bind_cine(playing)
	assert_true(s.is_paused_by(&"cine"), "Bağlanırken süren sinema saati durdurur")
	host.clock_hold_changed.emit(false)
	assert_true(s.is_paused_by(&"cine"), "Eski konak artık dinlenmez")
	playing.clock_hold_changed.emit(false)


func test_clock_events_are_forwarded() -> void:
	var s := _session()
	var hours := watch_signal(s.hour_passed)
	var days := watch_signal(s.day_changed)
	var skips := watch_signal(s.skipped)
	var dawns := watch_signal(s.dawn)
	var phases := watch_signal(s.phase_changed)
	s.clock.skip(s.clock.next(&"dawn") - s.clock.abs_minute() + 1.0, &"wait")
	assert_true(hours.count >= 14, "Saat başları aktarılır (%d)" % hours.count)
	assert_eq(days.count, 1, "Gece yarısı")
	assert_eq(skips.count, 1, "Atlama bitti")
	assert_eq(dawns.count, 1, "Tan")
	assert_true(phases.count >= 3, "Evreler")
	var replaced := watch_signal(s.clock_replaced)
	var other := GameClock.new(5, 10.0)
	s.set_pause(&"map", true)
	s.set_clock(other)
	assert_eq(replaced.count, 1)
	assert_true(other.is_paused_by(&"map"), "Açık durma nedeni yeni saate de yazılır")
	other.skip(60.0, &"dev")
	assert_eq(skips.count, 2, "Yeni saatin olayları bağlanır")
	s.free()


# --- Oto kayıt ------------------------------------------------------------------------------------------------

func test_autosave_rules() -> void:
	var s := _session()
	var asked: Array = []
	s.autosave_requested.connect(func(r: StringName) -> void: asked.append(String(r)))
	expect_errors(["bilinmeyen oto kayıt nedeni"])
	assert_false(s.request_autosave(&"lunch"))
	for r in Session.AUTOSAVE_REASONS:
		assert_true(r in [&"dawn", &"sleep", &"wait", &"work", &"quest_done", &"level_spend", &"region", &"act", &"world", &"fire",
			&"rest", &"depart", &"alight", &"pagehide", &"to_menu", &"tier", &"caravan", &"court_path"], "d2/core.md §6.2: %s" % r)
	assert_true(s.request_autosave(&"region"))
	assert_false(s.request_autosave(&"region"), "region ≥60 sn arayla")
	assert_false(s.request_autosave(&"caravan"), "caravan da")
	assert_true(s.request_autosave(&"quest_done"), "Öteki nedenler araya bakmaz")
	s.tick(61.0)
	assert_true(s.request_autosave(&"caravan"), "60 sn sonra")
	assert_false(s.request_autosave(&"wait", {"minutes": 30.0}), "wait ≥1 oyun saati")
	assert_true(s.request_autosave(&"wait", {"minutes": 60.0}))
	assert_false(s.request_autosave(&"work", {"minutes": 59.0}))
	s.block_autosave(&"boss_phase", true)
	assert_false(s.request_autosave(&"fire"), "Boss fazında zorunlu olmayan neden düşer")
	for r in Session.AUTOSAVE_FORCED:
		assert_true(s.request_autosave(r), "Zorunlu neden engele bakmaz: %s" % r)
	assert_true(s.request_autosave(&"fire", {"force": true}))
	s.block_autosave(&"boss_phase", false)
	asked.clear()
	s.clock.skip(90.0, &"wait")
	s.clock.skip(30.0, &"wait")
	s.clock.skip(120.0, &"work")
	s.clock.skip(30.0, &"rest")
	s.clock.skip(240.0, &"wait", true)
	s.clock.skip(240.0, &"cine")
	assert_eq(asked, ["wait", "work", "rest", "sleep"], "Saatin atlaması kendiliğinden ister (kısa bekleme ve sinema istemez)")
	s.free()


func test_dawn_autosaves_only_in_story_mode() -> void:
	for mode in [Session.MODE_ROAM, Session.MODE_STORY]:
		var j := Journey.new(SaveSystem.new(_dir))
		var s := _session(mode, j)
		if not s.clock.has_place():
			s.clock.set_place(Daylight.CAMP_LAT, Daylight.CAMP_DEC_OFFSET)
		var asked: Array = []
		s.autosave_requested.connect(func(r: StringName) -> void: asked.append(String(r)))
		s.clock.skip(s.clock.next(&"dawn") - s.clock.abs_minute() - 0.05, &"dev")
		asked.clear()
		s.tick(0.25)
		assert_eq(asked, ["dawn"] if mode == Session.MODE_STORY else [], "%s kipinde Tan" % mode)
		s.free()


# --- Kayıt ------------------------------------------------------------------------------------------------------

func test_clock_block_is_saved_and_loaded() -> void:
	var saves := SaveSystem.new(_dir)
	var j := Journey.new(saves)
	var s := _session(Session.MODE_ROAM, j)
	assert_true(is_same(j.live_blocks, s.blocks), "Oturumun blokları yolculuğa bağlanır")
	s.clock.skip(200.0, &"wait")
	var at := s.clock.abs_minute()
	assert_true(j.save_manual(1))
	var clock_block: Dictionary = saves.slot_info(1)["blocks"]["clock"]
	assert_eq(int(clock_block["v"]), 1)
	assert_eq(int(clock_block["day_n"]), s.clock.day_n)
	s.free()
	assert_null(j.live_blocks, "Silinen oturum yolculuktan ayrılır")
	assert_almost(GameClock.abs_of(int(j.blocks["clock"]["day_n"]), float(j.blocks["clock"]["minute"])), at, 1e-6, "Son hâli yolculukta kalır")
	var again := _session(Session.MODE_ROAM, j)
	assert_almost(again.clock.abs_minute(), at, 1e-6, "Aynı yolculukta yeni oturum saati sürdürür")
	again.free()
	var loaded := Journey.new(saves)
	assert_true(loaded.apply_record(saves.slot_info(1)))
	var b := _session(&"", loaded)
	assert_almost(b.clock.abs_minute(), at, 1e-6, "Kayıttan yüklenen oturum saati okur")
	assert_true(b.clock.has_place(), "Yükleme saatin yerini korur")
	b.free()


func test_failed_setup_leaves_the_journey_alone() -> void:
	var bad := Journey.new(SaveSystem.new(_dir))
	bad.blocks = {"clock": {"v": 99, "day_n": 1, "minute": 0.0}}
	var f := Session.new()
	var err := f.setup(bad, Session.MODE_ROAM)
	assert_true(err.contains("v99"), "Okunamayan blok kurulumu düşürür: %s" % err)
	assert_true(f.failed())
	assert_null(bad.live_blocks, "Bozuk kurulum yolculuğa bağlanmaz")
	f.free()
	assert_eq(int(bad.blocks["clock"]["v"]), 99, "Yolculuğun kaydı değişmez")


# --- Koşul, etki, tohum ---------------------------------------------------------------------------------------

func test_cond_context_reads_clock_journey_and_sources() -> void:
	var j := Journey.new(SaveSystem.new(_dir))
	j.set_flag("child_spared", true)
	j.act = 1
	var s := _session(Session.MODE_ROAM, j)
	assert_true(s.holds("hour>=14 && hour<15 && minute>886"), "Saat: 14:46,2")
	assert_true(s.holds("day_n==1171 && mode==roam && act==1"))
	assert_true(s.holds("phase:golden && !phase:night"), "Evre saatten")
	assert_false(s.holds("dark"))
	assert_true(s.holds("child_spared && !missing"), "Kalan adlar yolculuğun işaretleri")
	s.add_cond_source("trust", func(_p: String) -> Variant: return 27)
	s.add_cond_source("quest:", func(p: String) -> Variant: return p == "quest:mq_count.done")
	s.add_cond_source("ties.", func(p: String) -> Variant: return 3 if p == "ties.farnak" else 0)
	assert_true(s.holds("trust>=25 && quest:mq_count.done && !quest:mq_ration.done && ties.farnak==3"), "Kaydedilen kaynaklar")
	s.free()


func test_effects_run_through_session_services() -> void:
	var s := _session()
	var events: Array = []
	s.event.connect(func(n: StringName, p: Variant) -> void: events.append([String(n), p]))
	var before := s.clock.abs_minute()
	var errors := s.apply_effects([["flag", "met_eskam"], ["emit", "bell", 2], ["clock", "advance", 30], ["push", "seen", "x"],
		["if", "met_eskam", [["flag", "then"]]]], "mq_test")
	assert_eq(errors, PackedStringArray())
	assert_true(s.journey.has_flag("met_eskam") and s.journey.has_flag("then"))
	assert_eq(events, [["bell", 2]], "emit oturumun event sinyalidir")
	assert_almost(s.clock.abs_minute() - before, 30.0, 1e-6, "clock op'u oturumun saatini atlatır")
	assert_eq(s.journey.flags["seen"], ["x"])
	var ui := _Ui.new()
	s.add_service("ui", ui)
	s.apply_effects([["toast", "SAVE_WRITTEN"]])
	assert_eq(ui.toasts, ["SAVE_WRITTEN"], "Eklenen hizmet")
	s.free()


func test_rng_streams_follow_the_journey_seed() -> void:
	var a := Journey.new(SaveSystem.new(_dir))
	a.journey_seed = 42
	var b := Journey.new(SaveSystem.new(_dir))
	b.journey_seed = 42
	var sa := _session(Session.MODE_ROAM, a)
	var sb := _session(Session.MODE_ROAM, b)
	assert_eq(sa.rng_for("weather").randi(), sb.rng_for("weather").randi(), "Aynı yolculuk, aynı akış: aynı dizi")
	assert_ne(sa.rng_for("weather").randi(), sa.rng_for("raids").randi(), "Başka akış başka dizi")
	sa.free()
	sb.free()


# --- Ana sahne -------------------------------------------------------------------------------------------------

func test_main_free_roam_owns_a_session() -> void:
	MenuStyle.muted = true
	var main = load(MAIN_SCENE).instantiate()
	main.quit_handler = func() -> void: pass
	main.saves = SaveSystem.new(_dir)
	main.prologue_path = ""
	add_child(main)
	_nodes.append(main)
	await wait_frames(3)
	assert_null(main.session, "Menüde oturum yok")
	main.menu.free_roam_requested.emit()
	await _wait_until(func() -> bool: return main.state == main.State.PLAYING, 8.0)
	var s: Session = main.session
	assert_not_null(s, "Serbest Gez oturum kurar")
	if s == null:
		return
	assert_true(s.get_parent() == main, "Oturum Main'in çocuğudur")
	assert_eq(s.mode, Session.MODE_ROAM)
	assert_eq(s.clock.day_n, 1171, "Kayıtsız Serbest Gez 11 Nisan MÖ 209'da")
	assert_true(is_same(main._roam_time.clock, s.clock), "Serbest Gez'in ışığı oturumun saatini okur")
	var t0: float = s.clock.abs_minute()
	await wait_frames(10)
	assert_true(s.clock.abs_minute() > t0, "Oynarken saat akar")
	main.player.pause_requested.emit()
	await _wait_until(func() -> bool: return main.pause_menu.is_open(), 4.0)
	await wait_frames(2)
	assert_true(s.is_paused_by(&"pause"), "Duraklatma kitabı saati durdurur")
	var t1: float = s.clock.abs_minute()
	await wait_frames(5)
	assert_almost(s.clock.abs_minute(), t1, 1e-12, "Duraklatmada saat akmaz")
	(main.pause_menu.get_menu() as GameMenu)._on_general("main")
	await _wait_until(func() -> bool: return main.state == main.State.MENU, 8.0)
	assert_null(main.session, "Menüye dönüşte oturum silinir")
	var auto: Dictionary = main.saves.slot_info(SaveSystem.AUTO_SLOT)
	assert_eq(int(auto.get("version", 0)), 2, "Oto kayıt v2")
	assert_eq(str(auto.get("reason", "")), "to_menu")
	var block: Dictionary = (auto.get("blocks", {}) as Dictionary).get("clock", {})
	assert_eq(int(block.get("day_n", 0)), 1171, "Kayıtta saat bloğu")
	var saved := GameClock.abs_of(int(block.get("day_n", 0)), float(block.get("minute", 0.0)))
	main.menu.continue_requested.emit()
	await _wait_until(func() -> bool: return main.state == main.State.PLAYING, 8.0)
	assert_not_null(main.session, "Devam Et oturumu yeniden kurar")
	if main.session:
		assert_true(absf(main.session.clock.abs_minute() - saved) < 1.0, "Saat kayıttan gelir")
	main.queue_free()
	var audio := get_node_or_null(^"/root/AudioManager")
	if audio:
		for p in audio.get_children():
			if p is AudioStreamPlayer:
				(p as AudioStreamPlayer).stop()
				(p as AudioStreamPlayer).stream = null
	await get_tree().create_timer(0.25).timeout


func _wait_until(cond: Callable, seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while not cond.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame


class _Hourly:
	extends RefCounted

	var log: Array
	var label := ""
	var hours: Array = []

	func _init(p_log: Array, p_label: String) -> void:
		log = p_log
		label = p_label

	func on_hour(info: Dictionary) -> void:
		hours.append(info)
		log.append(label)


class _Stepper:
	extends RefCounted

	var total := 0.0

	func step(dt: float) -> void:
		total += dt


class _StepNode:
	extends Node

	func step(_dt: float) -> void:
		pass


class _FakeCine:
	extends RefCounted

	signal clock_hold_changed(on: bool)
	var playing := false

	func is_playing() -> bool:
		return playing


class _Ui:
	extends RefCounted

	var toasts: Array = []

	func toast(key: String) -> void:
		toasts.append(key)
