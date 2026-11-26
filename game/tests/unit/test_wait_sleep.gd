extends TestCase
## Bekle, Uyu, Dinlen ve Çalış tekeri (Yol Haritası wait-sleep; K20, K45; time.md §6.2, §7.1–§7.4, §11; survival.md §2.7):
##   - Satırlar (WaitPlan): Bekle «Bir saat», «Üç saat» ve sıradaki dört evrenin başı; Uyu yalnız Akşam ve Gece'de, «Tanla uyan» sivil
##     şafakta, «Güneşle uyan» doğuştan 30 dk sonra; Çalış dört satır (Çocukta «Bir saat yardım et»), Tokluk <25 kapalı; ≤12 sa sınırı,
##     «Tan ağarana dek» ve uyku ≤15; bekleyişi geçen satır soluk ve nedenli; binilen at yürürken «Atı durdur.».
##   - Adı konmuş atlamalar takvimi aynı yönde yürütür: atlama yalnız ileri, geri yazım yok sayılır; hikâyede takvim günü saatle ilerler;
##     24 saatten uzun atlama tek skipped (long, sınır olayı yok).
##   - Ana sahnede Serbest Gez: T tekeri açar (saat «modal» ile durur), «Bir saat» 1,8 sn'lik görünür akışla saati bir saat yürütür,
##     Stamina dolar, ≥1 sa bekleme oto kayıt «wait» yazar; döşekte E «Uyu», akşamda «Tanla uyan» karartma altında sivil şafağa atlar,
##     Can dolar, oto kayıt «sleep», uyanışta bildirim; ateş başında basılı E 3 sn Dinlen tekerini açar. Teker HUD'un dilindedir.

const TempDir := preload("res://tests/support/temp_dir.gd")
const MAIN_SCENE := "res://scenes/main.tscn"

var _dir := ""
var _nodes: Array[Node] = []


func before_each() -> void:
	MenuStyle.muted = true
	InputSetup.ensure_actions()
	_dir = TempDir.fresh("bekle")


func after_each() -> void:
	get_tree().paused = false
	Input.action_release(&"accept")
	for n in _nodes:
		if is_instance_valid(n):
			n.queue_free()
	_nodes.clear()
	TempDir.wipe(_dir)


## Kampın saati (11 Nisan MÖ 209; minute verilirse o dakika).
func _camp_clock(minute: float = Daylight.MENU_MINUTE) -> GameClock:
	var c := GameClock.new(GameClock.ROAM_DAY, minute)
	c.set_place(Daylight.CAMP_LAT, Daylight.CAMP_DEC_OFFSET)
	return c


func _ids(rows: Array[Dictionary]) -> Array:
	return rows.map(func(r: Dictionary) -> String: return str(r["id"]))


# --- Satırlar -------------------------------------------------------------------------------------------------------

func test_wait_rows_are_one_three_hours_and_the_next_four_phases() -> void:
	var c := _camp_clock()
	assert_eq(c.phase(), &"golden", "14:46 ikindi")
	var rows := WaitPlan.rows(&"wait", c, {"lang": "tr"})
	assert_eq(rows.size(), 6, "Altı satır (1–6)")
	assert_eq(_ids(rows), ["h1", "h3", "to_dusk", "to_night", "to_dawn", "to_morning"], "Bir saat, üç saat, sonra sıradaki evreler")
	assert_eq(rows.map(func(r: Dictionary) -> String: return str(r["label"])),
		["Bir saat", "Üç saat", "Akşama dek", "Geceye dek", "Tan ağarana dek", "Sabaha dek"], "time.md §11'in yazıları")
	assert_almost(float(rows[0]["minutes"]), 60.0, 1e-9)
	assert_eq(str(rows[0]["at_text"]), "→ 15:46", "Her satır hedef saati yazar")
	assert_eq(rows[1]["reason"], &"wait")
	for i in range(2, rows.size() - 1):
		assert_true(float(rows[i + 1]["target"]) > float(rows[i]["target"]), "Evreler zaman sırasıyla")
	assert_almost(float(rows[2]["target"]), c.next(&"dusk"), 1e-9, "Akşamın başı")
	assert_true(bool(rows[0]["lapse"]) and bool(rows[1]["lapse"]), "≤3 sa görünür akış")
	assert_false(bool(rows[4]["lapse"]), "Uzun bekleme karartma")
	var dawn: Dictionary = rows[4]
	assert_true(float(dawn["minutes"]) > WaitPlan.MAX_WAIT_MIN and float(dawn["minutes"]) <= WaitPlan.MAX_LONG_MIN, "Tan'a 12–15 sa")
	assert_true(bool(dawn["enabled"]), "«Tan ağarana dek» 15 saate dek açık")
	var morning: Dictionary = rows[5]
	assert_false(bool(morning["enabled"]), "Sabaha 15 saatten uzun: soluk")
	assert_eq(str(morning["why"]), "En çok on iki saat beklenir.")
	var en := WaitPlan.rows(&"wait", c, {"lang": "en"})
	assert_eq(str(en[4]["label"]), "Until first light")
	var rest := WaitPlan.rows(&"rest", c)
	assert_eq(_ids(rest), _ids(rows), "Dinlen Bekle'nin satırlarıyla")
	assert_eq(rest[0]["reason"], &"rest", "Atlamanın nedeni rest (Tokluk ×0,5)")


func test_sleep_opens_only_in_the_evening_and_night() -> void:
	var day := _camp_clock()
	var rows := WaitPlan.rows(&"sleep", day)
	assert_eq(_ids(rows).slice(0, 2), ["sleep_dawn", "sleep_sun"], "Tanla uyan, Güneşle uyan")
	assert_false(bool(rows[0]["enabled"]), "İkindide uyunmaz")
	assert_eq(str(rows[0]["why"]), "Uyku vakti değil.")
	assert_true(bool(rows[2]["enabled"]), "Döşekte beklemek açık (Bir saat)")
	var night := _camp_clock(21.0 * 60.0)
	assert_true(WaitPlan.SLEEP_PHASES.has(night.phase()), "21:00 gece ya da akşam")
	var srows := WaitPlan.rows(&"sleep", night)
	assert_true(bool(srows[0]["enabled"]) and bool(srows[1]["enabled"]), "Gece uyunur")
	assert_true(bool(srows[0]["sleep"]), "Uyku atlaması")
	assert_almost(float(srows[0]["target"]), night.next("civil_dawn"), 1e-9, "Tanla uyan: sivil şafak")
	assert_almost(float(srows[1]["target"]), night.next("sunrise") + 30.0, 1e-6, "Güneşle uyan: doğuş + 30 dk")
	assert_false(bool(srows[0]["lapse"]), "Uyku karartma altında")


func test_work_rows_child_row_and_hunger_gate() -> void:
	var c := _camp_clock(9.0 * 60.0)
	var rows := WaitPlan.rows(&"work", c, {"site_eta": 200.0})
	assert_eq(_ids(rows), ["work_h1", "work_h3", "work_evening", "work_done"])
	assert_eq(str(rows[3]["label"]), "Bitene dek çalış")
	assert_almost(float(rows[3]["minutes"]), 200.0, 1e-9, "Bitene dek: şantiyenin kalan süresi")
	assert_eq(rows[0]["reason"], &"work")
	var none := WaitPlan.rows(&"work", c)
	assert_false(bool(none[3]["enabled"]), "Şantiyesiz «Bitene dek» kapalı")
	var child := WaitPlan.rows(&"work", c, {"child": true})
	assert_eq(_ids(child), ["work_child"], "Çocuk: yalnız yardım")
	assert_eq(str(child[0]["label"]), "Bir saat yardım et")
	var hungry := WaitPlan.rows(&"work", c, {"fullness": 20.0, "site_eta": 60.0})
	for r: Dictionary in hungry:
		assert_false(bool(r["enabled"]), "Tokluk <25: çalışılmaz")
		assert_eq(str(r["why"]), "Önce bir şey ye.")
	var fed := WaitPlan.rows(&"work", c, {"fullness": 25.0, "site_eta": 60.0})
	assert_true(bool(fed[0]["enabled"]), "Tokluk 25: açık")


func test_deny_and_holds_fade_rows() -> void:
	var c := _camp_clock()
	var rows := WaitPlan.rows(&"wait", c, {"deny": WaitPlan.text("deny.moving")})
	for r: Dictionary in rows:
		assert_false(bool(r["enabled"]), "Bağlamın yasağı bütün satırları kapatır")
		assert_eq(str(r["why"]), "Atı durdur.")
	assert_true(c.hold(&"dawn_line", c.abs_minute() + 120.0, GameClock.NO_DAY, Callable(), "Sayım"), "Bekleyiş kurulur")
	var held := WaitPlan.rows(&"wait", c)
	assert_true(bool(held[0]["enabled"]), "Bekleyişten önceki satır açık")
	assert_false(bool(held[1]["enabled"]), "Bekleyişi geçen satır soluk")
	assert_eq(str(held[1]["why"]), "Şafak seni bekliyor: Sayım")


func test_rest_heal_rule_and_wake_text() -> void:
	assert_eq(WaitPlan.rest_wounds_healed(60.0, 80.0), 0, "2 saatten kısa dinlenme yara kapatmaz")
	assert_eq(WaitPlan.rest_wounds_healed(120.0, 80.0), 1, "≥2 sa, Tokluk ≥25: bir yara")
	assert_eq(WaitPlan.rest_wounds_healed(720.0, 80.0), 2, "6 oyun saatinde bir")
	assert_eq(WaitPlan.rest_wounds_healed(240.0, 10.0), 0, "Tokluk <25 kapatmaz")
	var c := GameClock.new(1043, 400.0)
	c.set_place(38.6, 0.0)
	assert_eq(WaitPlan.woke_text(c, true, 3), "Gün III, %s" % WaitPlan.text("phase_lc.%s" % c.phase()), "Hikâyede «Gün III, …»")
	var roam := _camp_clock(6.5 * 60.0)
	assert_eq(WaitPlan.woke_text(roam, false, 0), "11 Nisan MÖ 209, %s" % WaitPlan.text("phase_lc.%s" % roam.phase()), "Serbest Gez'de tarih")
	assert_eq(WaitPlan.roman(6), "VI")
	assert_eq(HudWaitWheel.duration_text(232.0), "3 sa 52 dk")
	assert_eq(HudWaitWheel.duration_text(60.0, "en"), "1 h")


# --- Atlamalar ------------------------------------------------------------------------------------------------------

func test_named_skips_only_move_forward_and_long_skip_is_one_signal() -> void:
	var c := _camp_clock()
	var hours: Array = []
	var skips: Array = []
	c.hour_passed.connect(func(info: Dictionary) -> void: hours.append(info))
	c.skipped.connect(func(info: Dictionary) -> void: skips.append(info))
	var start := c.abs_minute()
	var info := c.skip(180.0, &"wait")
	assert_almost(c.abs_minute(), start + 180.0, 1e-9, "Üç saat ileri")
	assert_eq(skips.size(), 1, "Tek skipped")
	assert_eq(hours.size(), 3, "Atlanan saat başları sırayla")
	assert_true(hours.all(func(h: Dictionary) -> bool: return bool(h["skipping"])), "skipping yüküyle")
	assert_false(bool(info["long"]))
	var back := c.set_to(start, &"dev")
	assert_eq(back, {}, "Geri yazım yok sayılır")
	assert_almost(c.abs_minute(), start + 180.0, 1e-9, "Saat geri gitmez")
	hours.clear()
	skips.clear()
	var long := c.skip(GameClock.DAY_MIN * 2.0 + 30.0, &"wait")
	assert_eq(hours.size(), 0, "24 saatten uzun atlamada sınır olayı yok")
	assert_eq(skips.size(), 1, "Tek skipped")
	assert_true(bool(long["long"]), "long: true")
	assert_eq(int(long["dawns"]), 2, "Atlanan şafak sayısı")
	# Hikâyede takvim günü aynı yönde (Session).
	var j := Journey.new(SaveSystem.new(_dir))
	j.reset()
	j.set_flag(NewGameFlow.DAY_FLAG, 1041)
	var s := Session.new()
	s.auto_tick = false
	assert_eq(s.setup(j, Session.MODE_STORY), "")
	var forwarded: Array = []
	s.skipped.connect(func(i: Dictionary) -> void: forwarded.append(i))
	s.clock.skip(GameClock.DAY_MIN * 3.0, &"sleep", true)
	assert_eq(forwarded.size(), 1, "Oturum tek skipped'i aktarır")
	assert_eq(int(j.get_flag(NewGameFlow.DAY_FLAG)), 1044, "Takvim günü saatle ileri")
	s.free()


# --- Tekerin yüzü ---------------------------------------------------------------------------------------------------

func test_wheel_face_lays_out_six_slots_and_takes_keys() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_nodes.append(layer)
	var ui := HudWaitWheel.new()
	layer.add_child(ui)
	await wait_frames(1)
	var c := _camp_clock()
	var rows := WaitPlan.rows(&"wait", c)
	ui.open(rows, &"wait", c, "Bekle", "11 Nisan MÖ 209 · 14:46 · İkindi")
	await wait_frames(2)
	assert_true(ui.is_open())
	var centers: Array = []
	for i in rows.size():
		var p := HudWaitWheel.slot_center(i, rows.size())
		for q: Vector2 in centers:
			assert_true(p.distance_to(q) > HudWaitWheel.SLOT_SIZE.x, "Altıgenler üst üste binmez")
		centers.append(p)
		var screen := ui.size * 0.5 + p * ui.scale_k()
		assert_eq(ui.row_at(screen), i, "Altıgenin üstü satırını verir (%d)" % i)
		assert_true(Rect2(Vector2.ZERO, ui.size).has_point(screen), "Ekranın içinde")
	assert_almost(HudWaitWheel.slot_angle(0, 6), -60.0, 1e-9, "Birinci satır sağ üstte (saatin 1'i)")
	assert_almost(HudWaitWheel.dial_angle(720.0), PI * 1.5, 1e-9, "Öğle kadranın tepesinde")
	var picked: Array = []
	ui.chosen.connect(func(i: int) -> void: picked.append(i))
	var cancelled: Array = []
	ui.cancelled.connect(func() -> void: cancelled.append(true))
	_key(ui, KEY_2)
	assert_eq(picked, [1], "2 tuşu ikinci satırı seçer")
	_key(ui, KEY_6)
	assert_eq(picked, [1], "Soluk satır seçilmez (Sabaha dek)")
	var esc := InputEventAction.new()
	esc.action = &"pause"
	esc.pressed = true
	ui._input(esc)
	assert_eq(cancelled, [true], "Esc kapatır")


func test_world_spots_put_the_bed_at_the_yurt_door() -> void:
	var spec := MapSpec.find(MapSpec.TESTMAP)
	assert_not_null(spec)
	var spots := WorldSpots.build(MapSpec.TESTMAP, spec, null)
	var bed: Dictionary = spots.list("beds")[0]
	# Kuzey yurdu (0, −22), kapısı güneye (180°), yarıçap 3,6: döşek kapının 0,75 m önünde.
	assert_vec_almost(Vector3(bed["at"].x, 0.0, bed["at"].y), Vector3(0.0, 0.0, -22.0 + 3.6 + 0.75), 1e-4, "Döşek yurdun kapısının önünde")
	assert_false(spots.nearest("beds", Vector2(0.0, -16.5)).is_empty(), "Erimde (1,6 m)")
	assert_true(spots.nearest("beds", Vector2(0.0, -14.0)).is_empty(), "Erimin dışında")
	var barrel: Dictionary = spots.list("containers")[0]
	assert_eq(str(barrel["store"]), "chest", "Fıçı Mete'nin sandığıdır")
	assert_false(bool(spots.list("fires")[0].get("e", true)), "Deneme haritasının ateşinde E ateşin katmanınındır")
	assert_eq(WorldSpots.build("yok", null, null).list("beds"), [], "Bilinmeyen dünyada yer yok")


func _key(ui: HudWaitWheel, key: Key) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = key
	e.keycode = key
	e.pressed = true
	ui._input(e)


# --- Ana sahne ------------------------------------------------------------------------------------------------------

func test_free_roam_wait_sleep_and_rest() -> void:
	var main = load(MAIN_SCENE).instantiate()
	main.quit_handler = func() -> void: pass
	main.saves = SaveSystem.new(_dir)
	main.prologue_path = ""
	add_child(main)
	_nodes.append(main)
	await wait_frames(3)
	main.menu.free_roam_requested.emit()
	await _wait_until(func() -> bool: return main.state == main.State.PLAYING, 10.0)
	var s: Session = main.session
	var wheel: WaitWheel = main.wait_wheel
	assert_not_null(s)
	if s == null:
		await _end(main)
		return
	main.player.spawn_at(Vector3(4.0, 0.0, 10.0), PI)
	await wait_frames(2)
	assert_eq(wheel.context_mode(), &"wait", "Açıkta Bekle")
	# T: teker açılır, saat durur.
	var t := InputEventAction.new()
	t.action = &"wait"
	t.pressed = true
	Input.parse_input_event(t)
	await wait_frames(2)
	assert_true(wheel.is_open(), "T Bekle tekerini açar")
	assert_true(s.is_paused_by(&"modal"), "Teker açıkken saat durur")
	assert_false(main.player.is_active(), "Oyuncu durur")
	var before: float = s.clock.abs_minute()
	await wait_frames(5)
	assert_almost(s.clock.abs_minute(), before, 1e-9, "Saat akmaz")
	main.gameplay_hud.vitals.stamina = 10.0
	assert_true(wheel.choose(0), "«Bir saat»")
	await _wait_until(func() -> bool: return not wheel.is_running(), 8.0)
	assert_false(wheel.is_running())
	var after: float = s.clock.abs_minute()
	assert_true(after - before >= 59.9 and after - before < 61.5, "Bir saat ileri (%.2f dk)" % (after - before))
	assert_true(bool(wheel.last_info().get("lapse", false)), "Görünür akış (≤3 sa)")
	assert_eq(wheel.last_info().get("reason"), &"wait")
	assert_false(s.is_paused_by(&"modal"), "Saat yeniden akar")
	assert_true(main.player.is_active(), "Oyuncu yeniden yürür")
	assert_almost(main.gameplay_hud.vitals.stamina, main.gameplay_hud.vitals.stamina_max, 1e-6, "Bekleme Stamina'yı doldurur")
	assert_eq(str(main.saves.slot_info(SaveSystem.AUTO_SLOT).get("reason", "")), "wait", "≥1 sa bekleme oto kayıt yazar")
	# Ateş başı: basılı E 3 sn Dinlen.
	main.player.spawn_at(Vector3(2.2, 0.0, 2.0), PI)
	await wait_frames(2)
	assert_eq(wheel.context_mode(), &"rest", "Ateş başında T Dinlen")
	var fire_e: Dictionary = main._interaction()
	assert_eq(str(fire_e.get("label", "")), "Basılı: Dinlen", "Ateş başında E basılı Dinlen")
	Input.action_press(&"accept")
	assert_true(main.player.interact(), "E basılınca tutuş başlar")
	await get_tree().create_timer(1.0).timeout
	assert_false(wheel.is_open(), "3 sn dolmadan açılmaz")
	assert_true(main.gameplay_hud.hold_progress() > 0.2, "Tutuşun halkası dolar")
	await _wait_until(func() -> bool: return wheel.is_open(), 4.0)
	Input.action_release(&"accept")
	assert_true(wheel.is_open(), "3 sn basılı E: teker açılır")
	assert_eq(wheel.mode(), &"rest", "Ateş başı kipi")
	wheel.close()
	await wait_frames(2)
	# Döşek: Yurt A'nın kapısı (aile döşeği); akşam olunca «Tanla uyan».
	var spots := main._world_spots() as WorldSpots
	var bed := spots.list("beds")[0] as Dictionary
	var bed_at: Vector2 = bed["at"]
	main.player.spawn_at(Vector3(bed_at.x, 0.0, bed_at.y), 0.0)
	await wait_frames(2)
	assert_eq(wheel.context_mode(), &"sleep", "Döşekte T Uyu")
	assert_eq(str(main._interaction().get("label", "")), "Uyu", "Döşekte E «Uyu»")
	s.clock.set_to(GameClock.abs_of(s.clock.day_n, 21.0 * 60.0), &"dev")
	assert_true(main.player.interact(), "E: uyku tekeri")
	await wait_frames(2)
	assert_true(wheel.is_open())
	assert_eq(wheel.mode(), &"sleep")
	assert_true(bool(wheel.rows()[0].get("enabled", false)), "Gece uyunur")
	var target := float(wheel.rows()[0]["target"])
	main.gameplay_hud.vitals.hp = 40.0
	assert_true(wheel.choose(0), "Tanla uyan")
	await _wait_until(func() -> bool: return not wheel.is_running(), 10.0)
	assert_almost(s.clock.abs_minute(), target, 0.5, "Sivil şafakta uyanılır")
	assert_true(bool(wheel.last_info().get("sleep", false)), "Uyku atlaması")
	assert_false(bool(wheel.last_info().get("lapse", true)), "Karartma altında tek atlama")
	assert_almost(main.gameplay_hud.vitals.hp, main.gameplay_hud.vitals.hp_max, 1e-6, "Uyku Can'ı doldurur")
	assert_eq(str(main.saves.slot_info(SaveSystem.AUTO_SLOT).get("reason", "")), "sleep", "Uyku oto kayıt yazar")
	assert_almost(main.fade.color.a, 0.0, 0.01, "Perde açıldı")
	await _end(main)


# --- Yardımcılar ----------------------------------------------------------------------------------------------------

func _end(main: Node) -> void:
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
