extends TestCase
## Oyunun saati ve takvimi (GameClock, GameCalendar; K20, K67; time.md §0–§2, §6, §12; godot.md §3.5): saf sınamalar.
##   - Oran: 2,5 sn = 1 oyun dk, 1 gün 3.600 sn; kare başına en çok 0,25 sn; hız ayarı yok (rate yalnız Yol Akışı k).
##   - Durma nedenleri sayılır (dialogue, cine, pause...): biri açıkken saat akmaz.
##   - Saat başı ve gece yarısı olayları; atlama yalnız ileri, uzun atlamada sınır olayı yok.
##   - Görünür akış (lapse): verilen sürede hedefe sabit hızla varır, durma onu da durdurur, bitince skipped (lapse).
##   - Tek takvim: day_n'den tarih (doğum −7.785, Çocukluk −5.600, Yola Çıkış −41, Gün I 1.041, Serbest Gez 1.171) ve mevsim.

const CHILDHOOD_DAY := -5600
const START := 520.0
const END := 660.0


# --- Oran -----------------------------------------------------------------------------------------------------

func test_rate_is_two_and_a_half_seconds_a_minute() -> void:
	assert_almost(GameClock.SEC_PER_MIN, 2.5, 1e-9)
	assert_almost(GameClock.MIN_PER_SEC, 0.4, 1e-9)
	assert_almost(GameClock.DAY_MIN * GameClock.SEC_PER_MIN, 3600.0, 1e-9, "1 oyun günü 60 gerçek dk")
	var clock := GameClock.new(CHILDHOOD_DAY, START)
	assert_eq(clock.text(), "08:40", "Çocukluk 08:40'ta açılır")
	_run(clock, 2.5)
	assert_almost(clock.minute, START + 1.0, 1e-6, "2,5 sn = 1 oyun dk")
	_run(clock, 60.0)
	assert_almost(clock.minute, START + 25.0, 1e-6, "60 sn = 24 oyun dk")
	# ≈6 dk'lık sahne en çok 2 sa 24 dk eder (story.md §5): 350 sn akan saat 08:40'ı 11:00'e getirir.
	var scene := GameClock.new(CHILDHOOD_DAY, START)
	_run(scene, 350.0)
	assert_eq(scene.text(), "11:00", "350 sn akan saat 11:00")
	assert_eq(scene.day_n, CHILDHOOD_DAY, "Gün değişmez")


func test_frame_is_clamped_and_rate_is_only_travel_k() -> void:
	var clock := GameClock.new(0, 600.0)
	assert_almost(clock.step(1.0), GameClock.MAX_FRAME_S * GameClock.MIN_PER_SEC, 1e-9, "Takılan kare saati sıçratmaz (≤0,25 sn)")
	assert_almost(clock.step(-1.0), 0.0, 1e-9, "Geri adım yok")
	clock.rate = 4.0
	assert_almost(clock.step(0.25), 0.4, 1e-9, "Yol Akışı k = 4")
	clock.rate = 1.0
	assert_almost(clock.step(0.1), 0.04, 1e-9)


# --- Durma ------------------------------------------------------------------------------------------------------

func test_pause_reasons_are_counted() -> void:
	var clock := GameClock.new(CHILDHOOD_DAY, START)
	clock.pause(&"dialogue", true)
	assert_true(clock.is_paused(), "Bloklayan söz saati durdurur")
	_run(clock, 30.0)
	assert_almost(clock.minute, START, 1e-9, "Söz sırasında saat akmaz")
	clock.pause(&"cine", true)
	clock.pause(&"dialogue", false)
	assert_true(clock.is_paused(), "Sinema hâlâ durduruyor")
	assert_eq(clock.paused_reasons(), PackedStringArray(["cine"]))
	_run(clock, 10.0)
	assert_almost(clock.minute, START, 1e-9)
	clock.pause(&"cine", false)
	clock.pause(&"pause", true)
	_run(clock, 10.0)
	assert_almost(clock.minute, START, 1e-9, "Duraklatma kitabı saati durdurur")
	clock.pause(&"pause", false)
	assert_false(clock.is_paused())
	_run(clock, 5.0)
	assert_almost(clock.minute, START + 2.0, 1e-6, "Sonra yine akar")


# --- Olaylar ve atlama -----------------------------------------------------------------------------------------

func test_hour_and_midnight_events() -> void:
	var clock := GameClock.new(5, 23.0 * 60.0 + 59.0)
	var hours: Array = []
	var days: Array = []
	clock.hour_passed.connect(func(info: Dictionary) -> void: hours.append(info))
	clock.day_changed.connect(func(info: Dictionary) -> void: days.append(info))
	_run(clock, 5.0)
	assert_eq(clock.day_n, 6, "Takvim günü gece yarısı artar")
	assert_almost(clock.minute, 1.0, 1e-6)
	assert_eq(hours.size(), 1, "Saat başı bir kez")
	assert_eq(int(hours[0]["hour"]), 0)
	assert_eq(int(hours[0]["day_n"]), 6)
	assert_false(bool(hours[0]["skipping"]))
	assert_eq(days.size(), 1)
	# Negatif günde de (Çocukluk) saat başı doğru sayılır.
	var child := GameClock.new(CHILDHOOD_DAY, 539.0)
	var seen: Array = []
	child.hour_passed.connect(func(info: Dictionary) -> void: seen.append(int(info["hour"])))
	_run(child, 2.6)
	assert_eq(seen, [9], "09:00")


func test_skip_goes_only_forward() -> void:
	var clock := GameClock.new(CHILDHOOD_DAY, START)
	var infos: Array = []
	var hours: Array = []
	clock.skipped.connect(func(info: Dictionary) -> void: infos.append(info))
	clock.hour_passed.connect(func(info: Dictionary) -> void: hours.append(info))
	var info := clock.skip(140.0, &"wait")
	assert_eq(clock.text(), "11:00")
	assert_almost(float(info["minutes"]), 140.0, 1e-9)
	assert_false(bool(info["long"]))
	assert_eq(hours.size(), 3, "09:00, 10:00 ve 11:00 (varılan saat başı)")
	assert_eq(int(hours[2]["hour"]), 11)
	assert_true(bool(hours[0]["skipping"]), "Atlamada skipping")
	assert_eq(infos.size(), 1)
	assert_true(clock.skip(-5.0).is_empty(), "Geri atlama yok")
	assert_true(clock.skip_to(CHILDHOOD_DAY, START).is_empty(), "Geçmişe skip_to yok sayılır")
	assert_eq(clock.text(), "11:00", "Saat geri gitmez")
	# Köprü 1 gibi uzun atlama: sınır olayı yok, tek skipped (long).
	hours.clear()
	var long := clock.skip_to(-41, 390.0, &"cine")
	assert_true(bool(long["long"]), "Uzun atlama")
	assert_eq(hours.size(), 0, "Uzun atlamada saat başı olayı yayılmaz")
	assert_eq(clock.day_n, -41)
	assert_eq(clock.text(), "06:30")
	assert_eq(int(long["days"]), 5559)


# --- Görünür akış ------------------------------------------------------------------------------------------------

func test_lapse_reaches_the_target_at_constant_speed() -> void:
	var clock := GameClock.new(CHILDHOOD_DAY, 600.0)
	var infos: Array = []
	clock.skipped.connect(func(info: Dictionary) -> void: infos.append(info))
	assert_false(clock.begin_lapse(GameClock.abs_of(CHILDHOOD_DAY, 590.0), 3.0), "Geçmişe akış yok")
	assert_true(clock.begin_lapse(GameClock.abs_of(CHILDHOOD_DAY, END), 4.0, &"beat"))
	assert_true(clock.is_lapsing())
	_run(clock, 1.0)
	assert_almost(clock.minute, 615.0, 0.01, "Sabit hız: 4 sn'de 60 dk, 1 sn'de 15 dk")
	clock.pause(&"pause", true)
	_run(clock, 2.0)
	assert_almost(clock.minute, 615.0, 0.01, "Duraklatma akışı da durdurur")
	clock.pause(&"pause", false)
	_run(clock, 3.0)
	assert_almost(clock.minute, END, 1e-6, "Hedefe tam varır")
	assert_false(clock.is_lapsing())
	assert_eq(infos.size(), 1)
	assert_true(bool(infos[0]["lapse"]))
	assert_eq(infos[0]["reason"], &"beat")
	assert_almost(float(infos[0]["minutes"]), 60.0, 1e-6)
	_run(clock, 2.5)
	assert_almost(clock.minute, END + 1.0, 1e-6, "Akıştan sonra olağan oran")
	# Sıfır sürede akış hemen atlar.
	var now := GameClock.new(0, 100.0)
	assert_true(now.begin_lapse(GameClock.abs_of(0, 130.0), 0.0))
	assert_almost(now.minute, 130.0, 1e-9)
	assert_false(now.is_lapsing())


func test_hhmm_and_save_round_trip() -> void:
	assert_almost(GameClock.parse_hhmm("08:40"), 520.0, 1e-9)
	assert_almost(GameClock.parse_hhmm("11:00"), 660.0, 1e-9)
	assert_almost(GameClock.parse_hhmm(523.5), 523.5, 1e-9, "Sayı olduğu gibi")
	assert_almost(GameClock.parse_hhmm("on bir"), -1.0, 1e-9)
	assert_eq(GameClock.hhmm(659.99), "10:59", "Dakika aşağı yuvarlanır")
	assert_eq(GameClock.hhmm(1440.0), "00:00")
	var clock := GameClock.new(CHILDHOOD_DAY, 600.25)
	var back := GameClock.from_dict(clock.to_dict())
	assert_eq(back.day_n, CHILDHOOD_DAY)
	assert_almost(back.minute, 600.25, 1e-9)


# --- Takvim ------------------------------------------------------------------------------------------------------

func test_one_calendar_names_the_days() -> void:
	var want := {
		-7785: ["27 Eylül MÖ 234", "27 September 234 BC"],
		-5600: ["22 Eylül MÖ 228", "22 September 228 BC"],
		-41: ["15 Aralık MÖ 213", "15 December 213 BC"],
		1: ["26 Ocak MÖ 212", "26 January 212 BC"],
		1041: ["2 Aralık MÖ 210", "2 December 210 BC"],
		1171: ["11 Nisan MÖ 209", "11 April 209 BC"],
	}
	for d: int in want:
		assert_eq(GameCalendar.format_tr(d), want[d][0], "%d" % d)
		assert_eq(GameCalendar.format_en(d), want[d][1], "%d EN" % d)
	assert_eq(GameCalendar.doy(-7785), 269, "Doğum doy 269")
	assert_eq(GameCalendar.doy(CHILDHOOD_DAY), 264, "Çocukluk doy 264")
	assert_eq(GameCalendar.year_bc(CHILDHOOD_DAY), 228)
	for d: int in [-7785, -5600, -41, 1, 1041, 1171, 3525, 14097]:
		var md := GameCalendar.month_day(GameCalendar.doy(d))
		assert_eq(GameCalendar.day_n_of(md.y, md.x, GameCalendar.year_bc(d)), d, "Gidiş dönüş %d" % d)
	assert_eq(GameCalendar.season(CHILDHOOD_DAY), &"autumn", "22 Eylül güz")
	assert_eq(GameCalendar.season(1041), &"winter", "2 Aralık kış")
	assert_eq(GameCalendar.season(1171), &"spring", "11 Nisan bahar")
	assert_eq(GameCalendar.season(GameCalendar.day_n_of(1, 7, 209)), &"summer")
	# Çocukluk'un ışık dosyası ve sahnesi aynı günü okur (tek takvim).
	var light: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OrdosWorld.CHILDHOOD_LIGHT))
	assert_eq(int(light["doy"]), GameCalendar.doy(CHILDHOOD_DAY), "Işığın günü takvimden")
	var scene := ChildhoodScene.load_data()
	assert_eq(int(scene["day_n"]), CHILDHOOD_DAY)
	assert_true(str((scene["date"] as Dictionary)["tr"]).begins_with(GameCalendar.format_tr(CHILDHOOD_DAY)), "Tarih kartı takvimden")
	assert_true(str((scene["date"] as Dictionary)["en"]).begins_with(GameCalendar.format_en(CHILDHOOD_DAY)))


# --- Evreler, şafak ve akşam (act-1-p1 clock-calendar) -------------------------------------------------------------

const ROAM_DAY := 1171
const FIXTURE := "res://tests/fixtures/time_core.json"


## Ana kampın saati (K67): enlem 47,35°, sapma tarihten ve −0,0127° payla.
static func _camp(day: int = ROAM_DAY, minute: float = Daylight.MENU_MINUTE) -> GameClock:
	var clock := GameClock.new(day, minute)
	clock.set_place(Daylight.CAMP_LAT, Daylight.CAMP_DEC_OFFSET)
	return clock


func test_one_day_is_sixty_real_minutes_and_keeps_the_minute() -> void:
	# time.md §17 world-clock: 3.600 sn → gün +1, dakika aynı (1e−9; Kahan düzeltmesi).
	var clock := _camp()
	for i in 216000:
		clock.step(1.0 / 60.0)
	assert_eq(clock.day_n, ROAM_DAY + 1, "Bir oyun günü 60 gerçek dakika")
	assert_almost(clock.minute, Daylight.MENU_MINUTE, 1e-9, "Dakika aynı kalır")
	# 15 fps'de de (kırpılmamış duvar süresi, kare başına ≤0,25 sn) gün 60 dakikadır.
	var slow := _camp()
	for i in 54000:
		slow.step(1.0 / 15.0)
	assert_eq(slow.day_n, ROAM_DAY + 1)
	assert_almost(slow.minute, Daylight.MENU_MINUTE, 1e-9, "15 fps'de de gün 60 dk")


func test_phases_dawn_and_dusk_follow_the_sun() -> void:
	var clock := _camp()
	assert_eq(clock.phase(), &"golden", "14:46,2 İkindi")
	assert_eq(clock.slice(), &"evening")
	var phases: Array = []
	var dawns: Array = []
	var dusks: Array = []
	clock.phase_changed.connect(func(i: Dictionary) -> void: phases.append(i))
	clock.dawn.connect(func(i: Dictionary) -> void: dawns.append(i))
	clock.dusk.connect(func(i: Dictionary) -> void: dusks.append(i))
	# 14:46 → ertesi gün 06:00: Akşam 17:38, Gece 19:39, Tan 04:21, Sabah 05:52.
	clock.skip(GameClock.abs_of(ROAM_DAY + 1, 360.0) - clock.abs_minute(), &"sleep", true)
	var names: Array = phases.map(func(i: Dictionary) -> String: return str(i["phase"]))
	assert_eq(names, ["dusk", "night", "dawn", "morning"], "Evreler sırayla")
	assert_eq(dusks.size(), 1, "Bir akşam (Gece başı)")
	assert_eq(dawns.size(), 1, "Bir şafak (Tan başı)")
	if dawns.size() == 1:
		assert_eq(int(dawns[0]["day_n"]), ROAM_DAY + 1, "Şafak ertesi gün")
		var dawn_m := float(dawns[0]["abs"]) - GameClock.abs_of(ROAM_DAY + 1, 0.0)
		assert_almost(dawn_m, float(Daylight.day_info(Daylight.CAMP_LAT, Daylight.camp_dec(101.0))["dawn_at"]), 1e-9, "12 Nisan'ın Tan'ı")
		assert_almost(dawn_m, GameClock.parse_hhmm("04:21"), 3.0, "Tan 04:21 dolayı (11 Nisan 04:21, ertesi gün iki dakika erken)")
		assert_true(bool(dawns[0]["skipping"]), "Atlamada skipping")
	assert_eq(str(phases[0]["prev"]), "golden")
	assert_eq(str(phases[0]["slice"]), "evening")
	assert_eq(clock.phase(), &"morning")
	assert_true(clock.dark() == false and clock.below_horizon() == false, "06:00 güneş doğmuş")
	# Yer yoksa evre yoktur (Çocukluk'un sahnesi): yalnız saat başı.
	var plain := GameClock.new(CHILDHOOD_DAY, START)
	assert_eq(plain.phase(), &"")
	var seen: Array = []
	plain.phase_changed.connect(func(i: Dictionary) -> void: seen.append(i))
	plain.skip(600.0)
	assert_eq(seen.size(), 0, "Yer yoksa evre olayı yok")


func test_skip_events_match_the_prototype_clock() -> void:
	# Prototipin WorldClock'u K67 gün bilgisiyle (fikstür): saat başı, şafak, akşam ve evre aynı sırayla, aynı anda.
	if not FileAccess.file_exists(FIXTURE):
		fail("Fikstür yok: %s (node tools/proto_fixtures/time.mjs)" % FIXTURE)
		return
	var fx: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	var cases: Dictionary = fx["clock"]
	for id: String in ["skip_720", "skip_2880", "frames_dusk", "skip_dawn"]:
		var c: Dictionary = cases[id]
		var clock := _camp(int(c["from"][0]), float(c["from"][1]))
		var log: Array = []
		clock.hour_passed.connect(func(i: Dictionary) -> void: log.append(["hour", i["day_n"], i["abs"], i["hour"], i["skipping"]]))
		clock.dawn.connect(func(i: Dictionary) -> void: log.append(["dawn", i["day_n"], i["abs"], null, i["skipping"]]))
		clock.dusk.connect(func(i: Dictionary) -> void: log.append(["dusk", i["day_n"], i["abs"], null, i["skipping"]]))
		clock.phase_changed.connect(func(i: Dictionary) -> void: log.append(["phase", i["day_n"], null, str(i["phase"]), i["skipping"]]))
		clock.skipped.connect(func(i: Dictionary) -> void: log.append(["skip", i["dawns"], i["minutes"], i["long"], i["days"]]))
		match id:
			"skip_720":
				clock.skip(720.0, &"wait")
			"skip_2880":
				clock.skip(2880.0, &"dev")
			"skip_dawn":
				clock.skip(180.0, &"sleep", true)
			"frames_dusk":
				for i in int(c["frames"]):
					clock.step(float(c["dt"]))
		var want: Array = c["log"]
		assert_eq(log.size(), want.size(), "%s: olay sayısı (%s)" % [id, log])
		for i in mini(log.size(), want.size()):
			var a: Array = log[i]
			var b: Array = want[i]
			assert_eq(str(a[0]), str(b[0]), "%s[%d]: olay" % [id, i])
			if str(a[0]) == "skip":
				assert_eq(int(a[1]), int(b[1]), "%s: şafak sayısı" % id)
				assert_almost(float(a[2]), float(b[2]), 1e-6, "%s: dakika" % id)
				assert_eq(bool(a[3]), bool(b[3]), "%s: uzun" % id)
				assert_eq(int(a[4]), int(b[4]), "%s: gün" % id)
				continue
			assert_eq(int(a[1]), int(b[1]), "%s[%d]: gün" % [id, i])
			if b[2] != null:
				assert_almost(float(a[2]), float(b[2]), 1e-6, "%s[%d]: an" % [id, i])
			if b[3] is String:
				assert_eq(str(a[3]), str(b[3]), "%s[%d]: değer" % [id, i])
			elif b[3] != null:
				assert_eq(int(a[3]), int(b[3]), "%s[%d]: saat" % [id, i])
			assert_eq(bool(a[4]), bool(b[4]), "%s[%d]: skipping" % [id, i])
		assert_eq(clock.day_n, int(c["day"]), "%s: gün" % id)
		assert_almost(clock.minute, float(c["minute"]), 1e-6, "%s: dakika" % id)
		assert_eq(str(clock.phase()), str(c["phase"]), "%s: evre" % id)
	# Hedefler (next): evre başları, «hh:mm» ve çapalar.
	var targets: Dictionary = (cases["next"] as Dictionary)["targets"]
	var clock := _camp()
	for t: String in targets:
		assert_almost(clock.next(t), float(targets[t]), 1e-6, "next(%s)" % t)
	assert_almost(clock.next("civil_dawn-30"), clock.next("civilDawn-30"), 1e-9, "Yılan yazımı da okunur")
	assert_true(is_nan(clock.next("yarın")), "Bilinmeyen hedef NAN")


func test_long_skip_has_no_boundary_events() -> void:
	# time.md §17: skip(2880) sınır olayı yaymaz, tek skipped {long, days 2, dawns 2}; skip(720) 12 saat başı, bir şafak.
	var clock := _camp(ROAM_DAY, 1260.0)
	var hours := watch_signal(clock.hour_passed)
	var dawns := watch_signal(clock.dawn)
	var info := clock.skip(720.0, &"wait")
	assert_eq(hours.count, 12, "12 saat başı")
	assert_eq(dawns.count, 1, "Bir şafak")
	assert_eq(int(info["dawns"]), 1)
	var long := clock.skip(2880.0, &"dev")
	assert_eq(hours.count, 12, "Uzun atlamada saat başı yok")
	assert_eq(dawns.count, 1, "Uzun atlamada şafak olayı yok")
	assert_true(bool(long["long"]))
	assert_eq(int(long["days"]), 2)
	assert_eq(int(long["dawns"]), 2, "İki şafak sayılır")
	assert_eq(clock.phase(), Daylight.phase_at(clock.info(), clock.minute), "Evre uzun atlamadan sonra yeniden okunur")
	assert_true(clock.set_to(clock.abs_minute() - 30.0).is_empty(), "set_to geri gitmez")
	assert_true(clock.set_to(clock.abs_minute() + 30.0).size() > 0, "set_to ileri gider")


func test_holds_stop_the_clock_until_released() -> void:
	# time.md §6.3: dawn_line Tan başında durur; until koşulu tutunca ya da release ile salınır; atlama bekleyişi geçmez.
	var clock := _camp(1041, 1200.0)
	clock.set_place(38.9, 0.0)
	var done := [false]
	assert_false(clock.hold(&"nap", "05:00"), "Yalnız üç bekleyiş")
	assert_true(clock.hold(&"dawn_line", &"dawn", GameClock.NO_DAY, func() -> bool: return done[0], "mq_herd_school"))
	var changes := watch_signal(clock.hold_changed)
	var dawn_at := clock.next(&"dawn")
	var info := clock.skip(900.0, &"sleep", true)
	assert_almost(clock.abs_minute(), dawn_at, 1e-6, "Atlama bekleyişte durur")
	assert_almost(float(info["to"]), dawn_at, 1e-6)
	assert_true(clock.is_held(), "Saat tutuluyor")
	assert_eq(changes.count, 1, "Bekleyiş tuttu")
	_run(clock, 10.0)
	assert_almost(clock.abs_minute(), dawn_at, 1e-9, "Tutulan saat akmaz")
	assert_true(clock.skip(60.0).is_empty(), "Bekleyişte atlama yok")
	done[0] = true
	assert_false(clock.is_held(), "Koşul tutunca salınır")
	_run(clock, 2.5)
	assert_almost(clock.abs_minute(), dawn_at + 1.0, 1e-6, "Sonra akar")
	# release ile salınır; kayıt bekleyişi taşır.
	assert_true(clock.hold(&"ice_story", "05:45"))
	var back := GameClock.from_dict(clock.to_dict())
	assert_eq(back.holds().size(), 1, "Bekleyiş kayıtta")
	assert_eq(str(back.holds()[0]["id"]), "ice_story")
	assert_true(clock.release(&"ice_story"))
	assert_false(clock.has_hold(&"ice_story"))
	# Vakit çağrısı bekletmez.
	var calls := watch_signal(clock.summoned)
	clock.summon(&"b_herd")
	assert_eq(calls.count, 1)
	assert_false(clock.is_held())


func test_saved_clock_round_trips_and_old_roam_day_migrates() -> void:
	# Kayıt: {v, day_n, minute, holds}; prototipin «dayN»'i okunur; eski Serbest Gez kaydı {day: 3, minute: 600} → 1.174 (time.md §13).
	var clock := _camp(ROAM_DAY, 886.18)
	var d := clock.to_dict()
	assert_eq(int(d["v"]), 1)
	assert_eq(int(d["day_n"]), ROAM_DAY)
	assert_almost(float(d["minute"]), 886.18, 1e-12)
	var back := GameClock.from_dict(JSON.parse_string(JSON.stringify(d)))
	assert_eq(back.day_n, ROAM_DAY, "JSON gidiş dönüş")
	assert_almost(back.minute, 886.18, 1e-9)
	var proto := GameClock.from_dict({"v": 1, "dayN": 1042, "minute": 742.5, "holds": []})
	assert_eq(proto.day_n, 1042, "Prototipin yazımı")
	var old := GameClock.from_dict({"day": 3, "minute": 600})
	assert_eq(old.day_n, 1174, "Eski Serbest Gez günü göçer: 1.171 + 3")
	assert_almost(old.minute, 600.0, 1e-9)
	assert_false(GameClock.new().load_dict({"minute": 5}), "Günsüz blok okunmaz")


# --- Yardımcı ------------------------------------------------------------------------------------------------------

## Saati seconds gerçek saniye kadar 1/60'lık karelerle sürer.
func _run(clock: GameClock, seconds: float) -> void:
	var left := seconds
	while left > 0.0000001:
		var dt := minf(left, 1.0 / 60.0)
		clock.step(dt)
		left -= dt
