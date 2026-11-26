extends TestCase
## Takvim (GameCalendar; K20, K33, K42, K55, K56, K67; time.md §2, §11, §17 «calendar»; godot.md §3.5): saf sınamalar.
##   - Tek takvim: day_n'den MÖ yılı, ay ve gün; mevsim; perde başları.
##   - Ay: yaş ve aydınlık (Gün IV 18:00 dolunay), ay ayı, Dailin ve Lung-çeng günleri (K56), Kış Toplantısı, akın penceresi (K55).
##   - Tarih kartı ve sayım biçimi (time.md §11): «8 Haziran MÖ 209 · 1.229. gün».
##   - Prototipin calendar.js fikstürü (tests/fixtures/time_core.json): yıl, doy, mevsim, ay yaşı, aydınlık, ay ayı 1e-9 içinde.

const FIXTURE := "res://tests/fixtures/time_core.json"
const EPS := 1e-9


func test_day_n_names_the_days() -> void:
	assert_eq(GameCalendar.day_n_of(11, 4, 209), 1171, "11 Nisan MÖ 209 = 1.171 (Serbest Gez, Ev)")
	assert_eq(GameCalendar.format_tr(-7785), "27 Eylül MÖ 234", "Doğum")
	assert_eq(GameCalendar.format_en(-7785), "27 September 234 BC")
	assert_eq(GameCalendar.format_tr(1041), "2 Aralık MÖ 210", "Gün I")
	assert_eq(GameCalendar.year_bc(1041), 210)
	assert_eq(GameCalendar.doy(1041), 335)
	assert_eq(GameCalendar.season(1041), &"winter")
	assert_eq(GameCalendar.format_tr(1172), "12 Nisan MÖ 209", "Serbest Gez'in ilk Tan kartı (time.md §11)")
	assert_eq(GameCalendar.format_en(1172), "12 April 209 BC")
	assert_eq(GameCalendar.format(1172, "en"), "12 April 209 BC")
	assert_eq(GameCalendar.format(1172, "tr"), "12 Nisan MÖ 209")
	var acts := {1: 1041, 2: 1222, 3: 1679, 4: 2682, 5: 4314, 6: 5237}
	for act: int in acts:
		assert_eq(GameCalendar.act_start(act), acts[act], "%d. perdenin başı" % act)
	assert_eq(GameCalendar.act_start(2), 1222, "II. Perde 1 Haziran MÖ 209")
	assert_eq(GameCalendar.format_tr(GameCalendar.act_start(2)), "1 Haziran MÖ 209")
	assert_eq(GameCalendar.act_start(6), 5237)
	assert_eq(GameCalendar.format_tr(GameCalendar.act_start(5)), "20 Kasım MÖ 201")
	assert_eq(GameCalendar.act_start(9), 0, "Bilinmeyen perde 0")


func test_date_card_with_the_count() -> void:
	# time.md §11: II–VI'da her Tan'da «8 Haziran MÖ 209 · 1.229. gün» / «8 June 209 BC · Day 1,229»; Serbest Gez'de yalnız tarih.
	var day := GameCalendar.day_n_of(8, 6, 209)
	assert_eq(day, 1229)
	assert_eq(GameCalendar.format_count(day, "tr"), "8 Haziran MÖ 209 · 1.229. gün")
	assert_eq(GameCalendar.format_count(day, "en"), "8 June 209 BC · Day 1,229")
	assert_eq(GameCalendar.format_count(14097, "tr"), "9 Eylül MÖ 174 · 14.097. gün", "Son Dailin")
	assert_eq(GameCalendar.group_digits(41, "."), "41")
	assert_eq(GameCalendar.group_digits(-7785, "."), "-7.785")
	assert_eq(GameCalendar.format_season_year(1709, "tr"), "Güz, MÖ 208", "Tarih kapısı geçildiyse yıl ve mevsim (time.md §6.3)")
	assert_eq(GameCalendar.format_season_year(1709, "en"), "Autumn, 208 BC")


func test_seasons_turn_on_their_days() -> void:
	# time.md §2: kış 16 Kasım – 15 Mart, bahar 16 Mart – 14 Mayıs, yaz 15 Mayıs – 22 Ağustos, güz 23 Ağustos – 15 Kasım.
	assert_eq(GameCalendar.season(GameCalendar.day_n_of(15, 3, 209)), &"winter")
	assert_eq(GameCalendar.season(GameCalendar.day_n_of(16, 3, 209)), &"spring")
	assert_eq(GameCalendar.season(GameCalendar.day_n_of(14, 5, 209)), &"spring")
	assert_eq(GameCalendar.season(GameCalendar.day_n_of(15, 5, 209)), &"summer", "15 Mayıs yaz")
	assert_eq(GameCalendar.season(GameCalendar.day_n_of(22, 8, 209)), &"summer")
	assert_eq(GameCalendar.season(GameCalendar.day_n_of(23, 8, 209)), &"autumn", "23 Ağustos güz")
	assert_eq(GameCalendar.season(GameCalendar.day_n_of(15, 11, 209)), &"autumn")
	assert_eq(GameCalendar.season(GameCalendar.day_n_of(16, 11, 209)), &"winter", "16 Kasım kış")
	# Serbest Gez'in açılışından (11 Nisan) yaza 34, güze 134, kışa 219 oyun günü (= gerçek saat; time.md §5.5).
	assert_eq(GameCalendar.next_season_day(1171, &"summer") - 1171, 34)
	assert_eq(GameCalendar.next_season_day(1171, &"autumn") - 1171, 134)
	assert_eq(GameCalendar.next_season_day(1171, &"winter") - 1171, 219)
	assert_eq(GameCalendar.season_name(&"autumn", "tr"), "Güz")
	assert_eq(GameCalendar.season_name(&"winter", "en"), "Winter")


func test_moon_phase_follows_one_formula() -> void:
	# Gün IV 18:00 dolunay (≥0,999); Gün I gecesi %91; 11 Nisan 209 14:46,2'de %36 ve küçülen (time.md §2, K67).
	assert_true(GameCalendar.moon_illum(GameClock.abs_of(1044, 1080.0)) >= 0.999, "Gün IV 18:00 dolunay")
	assert_almost(GameCalendar.moon_age(GameClock.abs_of(1044, 1080.0)), GameCalendar.SYNODIC / 2.0, 1e-9, "Dolunayın yaşı")
	assert_almost(GameCalendar.moon_illum(GameClock.abs_of(1041, 1320.0)), 0.91, 0.01, "Gün I gecesi %91")
	var roam := GameClock.abs_of(1171, Daylight.MENU_MINUTE)
	assert_almost(GameCalendar.moon_illum(roam), 0.36, 0.01, "Serbest Gez'in açılışında ay %36")
	assert_false(GameCalendar.moon_waxing(roam), "Küçülen ay")
	assert_true(GameCalendar.moon_waxing(GameClock.abs_of(1040, 0.0)), "Dolunaydan önce büyür")
	# Son Gece %99, Gün VI gecesi %95 (22:00).
	assert_almost(GameCalendar.moon_illum(GameClock.abs_of(1045, 1320.0)), 0.99, 0.01, "Son Gece")
	assert_almost(GameCalendar.moon_illum(GameClock.abs_of(1046, 1320.0)), 0.95, 0.01, "Gün VI gecesi")


func test_meeting_days_fall_on_the_moon() -> void:
	# K56: Dailin 8. ayın dolunayı, Lung-çeng 5. ayın dolunayı, Kış Toplantısı 1. ayın yeni ayı (time.md §17).
	var dailin := {234: -7785, 228: -5600, 208: 1694, 203: 3525, 174: 14097}
	for y: int in dailin:
		assert_eq(GameCalendar.dailin_day(y), dailin[y], "Dailin MÖ %d" % y)
	assert_eq(GameCalendar.format_tr(GameCalendar.dailin_day(208)), "16 Eylül MÖ 208")
	assert_eq(GameCalendar.format_tr(GameCalendar.dailin_day(234)), "27 Eylül MÖ 234", "Doğum Dailin'e düşer")
	var longcheng := {205: 2698, 203: 3436, 198: 5238, 176: 13270}
	for y: int in longcheng:
		assert_eq(GameCalendar.longcheng_day(y), longcheng[y], "Lung-çeng MÖ %d" % y)
	assert_eq(GameCalendar.format_tr(GameCalendar.longcheng_day(205)), "17 Haziran MÖ 205")
	assert_eq(GameCalendar.winter_meet_day(208), 1472, "Kış Toplantısı 6 Şubat 208")
	assert_eq(GameCalendar.format_tr(1472), "6 Şubat MÖ 208")
	# Toplantı günü o ayın içindedir: Dailin'in ay ayı 8, Lung-çeng'inki 5.
	assert_eq(GameCalendar.lunar_month(GameClock.abs_of(1694, 720.0)), 8, "16 Eylül 208 8. ayda")
	assert_eq(GameCalendar.lunar_month(GameClock.abs_of(2698, 720.0)), 5, "17 Haziran 205 5. ayda")
	assert_eq(GameCalendar.lunar_month(GameClock.abs_of(1472, 1439.0)), 1, "Kış Toplantısı 1. ayın başı")


func test_raid_window_only_on_the_full_moon_days() -> void:
	# K55: moon_illum(day_n + 0,5) ≥ 0,97; oynanan pencereler 1.693–1.695, 2.697–2.699, 3.435–3.437, 4.321–4.323.
	for window: Vector2i in [Vector2i(1693, 1695), Vector2i(2697, 2699), Vector2i(3435, 3437), Vector2i(4321, 4323)]:
		assert_false(GameCalendar.raid_window(window.x - 1), "%d akın yok" % (window.x - 1))
		for d in range(window.x, window.y + 1):
			assert_true(GameCalendar.raid_window(d), "%d akın penceresi" % d)
		assert_false(GameCalendar.raid_window(window.y + 1), "%d akın yok" % (window.y + 1))
	# Ayda ≈3 gün: bir yılın 365 gününde 33–40 gün.
	var count := 0
	for d in range(1171, 1171 + 365):
		if GameCalendar.raid_window(d):
			count += 1
	assert_between(count, 33, 40, "Ayda ≈3 akın günü")


func test_fixture_matches_the_prototype_calendar() -> void:
	if not FileAccess.file_exists(FIXTURE):
		fail("Fikstür yok: %s (node tools/proto_fixtures/time.mjs)" % FIXTURE)
		return
	var fx: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	var cal: Dictionary = fx["calendar"]
	for row: Array in cal["days"]:
		var d := int(row[0])
		assert_eq(GameCalendar.year_bc(d), int(row[1]), "yearOf(%d)" % d)
		assert_eq(GameCalendar.doy(d), int(row[2]), "doyOf(%d)" % d)
		assert_eq(str(GameCalendar.season(d)), str(row[3]), "seasonOf(%d)" % d)
	for row: Array in cal["moon"]:
		var a := float(row[0])
		assert_almost(GameCalendar.moon_age(a), float(row[1]), EPS, "moonAgeAt(%s)" % a)
		assert_almost(GameCalendar.moon_illum(a), float(row[2]), EPS, "moonIllumAt(%s)" % a)
		assert_eq(GameCalendar.lunar_month(a), int(row[3]), "lunarMonthAt(%s)" % a)
