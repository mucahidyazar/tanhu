extends TestCase
## Daylight (scripts/sim/time/daylight.gd): prototipin daylight.js'inden birebir taşınan güneş ve ay hesabı.
##
## Altın değerler prototipin kendisinden alındı (2026-11-05, node ile src/game/daylight.js; dosya bu testin
## yorumlarındaki komutla yeniden üretilir). Doğumun ışığı (story.md §4, godot.md §3.6): 27 Eylül MÖ 234 (doy 269),
## Ordos 39°K; içeride 05:50, dışarıda 06:03; dolunay batıda ufukta.
##   node -e "import('…/src/game/daylight.js').then(d => console.log(d.sunAt(39, d.solarDec(269), 363)))"

## Kayan nokta payı: prototipin (V8) ve Godot'nun trigonometri işlevleri son bitlerde ayrışabilir.
const EPS := 1e-9
## Vector3 32 bitliktir (Godot'nun varsayılan derlemesi): yön karşılaştırmaları bu payla yapılır.
const VEC_EPS := 1e-6
## Ordos (childhood_ordos) enlemi ve doğumun günü (time.md §2: dayN −7.785 → doy 269).
const ORDOS_LAT := 39.0
const BIRTH_DOY := 269.0
## Doğumun iki dakikası (yerel güneş saati).
const INSIDE_MINUTE := 350.0
const OUTSIDE_MINUTE := 363.0
## time.md §2'nin ay yaşı formülüyle 27 Eylül MÖ 234 (dayN −7.785) 05:50 ve 06:03 (data/cine/birth_light.json).
const AGE_INSIDE := 14.903868
const AGE_OUTSIDE := 14.912896


# --- Sapma ------------------------------------------------------------------------------------

func test_solar_dec_matches_the_prototype() -> void:
	# Kampın iğnesi (11 Nisan, doy 100) ve doğumun günü (27 Eylül, doy 269); iki uç da sınanır.
	assert_almost(Daylight.solar_dec(100.0), 7.435, 0.001, "doy 100 (kamp iğnesi) +7,435°")
	assert_almost(Daylight.solar_dec(BIRTH_DOY), -2.12, 0.02, "doy 269 (doğum) −2,12°")
	assert_almost(Daylight.solar_dec(100.0), 7.43496380452865, EPS, "prototipin değeri (doy 100)")
	assert_almost(Daylight.solar_dec(BIRTH_DOY), -2.11549773912759, EPS, "prototipin değeri (doy 269)")
	assert_almost(Daylight.solar_dec(0.0), -23.0935593023621, EPS, "1 Ocak")
	assert_almost(Daylight.solar_dec(172.0), 23.4391317616853, EPS, "yaz gündönümü yakını")


# --- Güneş ------------------------------------------------------------------------------------

func test_birth_dawn_sun_is_east_on_the_horizon() -> void:
	# 06:03 dışarıda: güneş doğuda, geometrik yükseklik ≈ −0,7° (kırılmayla ufukta).
	var sun := Daylight.sun_at(ORDOS_LAT, Daylight.solar_dec(BIRTH_DOY), OUTSIDE_MINUTE)
	assert_between(float(sun["el"]), -1.5, 0.5, "06:03 güneş yüksekliği")
	assert_between(float(sun["az"]), 88.0, 96.0, "06:03 güneş azimutu (doğu)")
	_assert_sample(sun, [0.999232831555, -0.0130651474360, 0.0369195106275, -0.748599105234, 92.1159936742], "06:03")
	var apparent := Daylight.apparent_dir(sun)
	assert_between(rad_to_deg(asin(apparent.y)), -0.4, 0.3, "Kırılmayla görünen güneş ufukta (geometrik −0,75°)")


func test_birth_inside_sun_is_in_civil_twilight() -> void:
	# 05:50 içeride: güneş ufkun 3,3° altında (sivil alaca 05:36'da başlar).
	var sun := Daylight.sun_at(ORDOS_LAT, Daylight.solar_dec(BIRTH_DOY), INSIDE_MINUTE)
	assert_between(float(sun["el"]), -4.0, -2.5, "05:50 güneş yüksekliği")
	_assert_sample(sun, [0.998367315861, -0.0571062676121, 0.00125571470487, -3.27372910518, 90.0720647739], "05:50")


func test_sun_matches_the_prototype_elsewhere() -> void:
	# Kampın ikindi güneşi (11 Nisan 14:46,2, iğneli sapma) ve güney yarıküre: formül her yerde aynı.
	_assert_sample(Daylight.sun_at(47.35, 7.4223, 886.18),
			[-0.657651024567, 0.597843283059, 0.458343254326, 36.7155898283, 235.125819854], "kamp 14:46,2")
	_assert_sample(Daylight.sun_at(-30.0, 10.0, 600.0),
			[0.492403876506, 0.651781725926, -0.576817999157, 40.6760714576, 40.4859119929], "güney yarıküre")


func test_sun_direction_is_a_unit_vector_on_the_compass() -> void:
	var dec := Daylight.solar_dec(BIRTH_DOY)
	for minute in [0.0, 300.0, 363.0, 720.0, 1100.0, 1439.0]:
		var sun := Daylight.sun_at(ORDOS_LAT, dec, minute)
		var dir := Daylight.dir_of(sun)
		assert_almost(dir.length(), 1.0, VEC_EPS, "Birim yön (%s dk)" % minute)
		assert_vec_almost(Daylight.toward(float(sun["az"]), float(sun["el"])), dir, VEC_EPS, "Azimut ve yükseklik yönle aynı (%s dk)" % minute)
		assert_vec_almost(dir, World.direction_from_angles(float(sun["az"]), float(sun["el"])), 1e-6, "Kamp dünyasının açı kuralıyla aynı yön (%s dk)" % minute)
	var noon := Daylight.sun_at(ORDOS_LAT, dec, Daylight.NOON)
	assert_almost(float(noon["az"]), 180.0, 1e-6, "Öğle güneşi güneyde")
	assert_almost(float(noon["el"]), 90.0 - ORDOS_LAT + dec, 1e-6, "Öğle yüksekliği 90 − enlem + sapma")


# --- Ay ---------------------------------------------------------------------------------------

func test_full_moon_sets_in_the_west_at_dawn() -> void:
	# «batıda dolunay ufukta» (story.md §4). Plan yaş ≈14,9'la 0…+2° yazmıştı; modelde yaş 14,9 +2,02°,
	# takvimin yaşı (14,913, birth_light.json) +2,15° verir: ufuk sınırı 2,5°'tir (bkz. dosyanın başı ve notlar).
	var dec := Daylight.solar_dec(BIRTH_DOY)
	for age in [14.9, AGE_OUTSIDE]:
		var moon := Daylight.moon_at(ORDOS_LAT, dec, OUTSIDE_MINUTE, age)
		assert_between(float(moon["az"]), 260.0, 280.0, "06:03 ay batıda (yaş %s)" % age)
		assert_between(float(moon["el"]), 0.0, 2.5, "06:03 ay ufukta (yaş %s)" % age)
		assert_almost(float(moon["illum"]), 1.0, 0.001, "Dolunay (yaş %s)" % age)
	_assert_sample(Daylight.moon_at(ORDOS_LAT, dec, OUTSIDE_MINUTE, AGE_OUTSIDE),
			[-0.999151514594, 0.0374423247625, -0.0171558503434, 2.14578875679, 270.983695888], "ay 06:03")
	_assert_sample(Daylight.moon_at(ORDOS_LAT, dec, INSIDE_MINUTE, AGE_INSIDE),
			[-0.996648967710, 0.0799542973593, 0.0172668901879, 4.58593875234, 269.007452975], "ay 05:50")


func test_exact_full_moon_is_opposite_the_sun() -> void:
	# Dolunay anında ay güneşin tam karşısındadır (sapma ters, saat açısı 180° geride): şafakta biri doğarken
	# öteki batar. Bu, 06:03'te ayın neden batıda ve ufukta olduğunu söyler.
	var dec := Daylight.solar_dec(BIRTH_DOY)
	for minute in [INSIDE_MINUTE, OUTSIDE_MINUTE, 900.0]:
		var sun := Daylight.dir_of(Daylight.sun_at(ORDOS_LAT, dec, minute))
		var moon := Daylight.moon_at(ORDOS_LAT, dec, minute, Daylight.SYNODIC * 0.5)
		assert_vec_almost(Daylight.dir_of(moon), -sun, VEC_EPS, "Ay güneşin karşısında (%s dk)" % minute)
		assert_almost(float(moon["illum"]), 1.0, 1e-12, "Tam dolunay")


func test_moon_matches_the_prototype_in_a_crescent() -> void:
	_assert_sample(Daylight.moon_at(47.35, 7.4223, 1200.0, 5.5),
			[-0.797101187305, 0.444821499226, 0.408366907355, 26.4119189049, 242.873255070], "hilal")
	assert_almost(float(Daylight.moon_at(47.35, 7.4223, 1200.0, 5.5)["illum"]), 0.305029101283, 1e-9, "Hilalin aydınlığı")
	assert_almost(float(Daylight.moon_at(47.35, 7.4223, 1200.0, 0.0)["illum"]), 0.0, 1e-12, "Yeni ay karanlık")


func test_birth_moon_age_follows_the_calendar_formula() -> void:
	# time.md §2: moonAge = (dayN + dakika/1440 − 1044,75 + 14,765) mod 29,530588 (GameCalendar.moon_age act-1-p1'de
	# gelir; burada formülün kendisiyle birth_light.json'un yaşları sınanır).
	assert_almost(_moon_age(-7785, INSIDE_MINUTE), AGE_INSIDE, 1e-6, "05:50'nin ay yaşı")
	assert_almost(_moon_age(-7785, OUTSIDE_MINUTE), AGE_OUTSIDE, 1e-6, "06:03'ün ay yaşı")
	# «8. ayın dolunayı o gece» (story.md §4): şafakta dolunaydan yalnız birkaç saat geçmiştir.
	var hours_after_full := (_moon_age(-7785, OUTSIDE_MINUTE) - Daylight.SYNODIC * 0.5) * 24.0
	assert_between(hours_after_full, 2.0, 5.0, "Dolunay gece yarısından sonra, şafaktan birkaç saat önce")


# --- Işık ve kırılma ----------------------------------------------------------------------------

func test_light_dir_never_comes_from_below() -> void:
	# Işığın yönü güneşin azimutundadır ama 15°'nin altına inmez (godot.md §4.9: gölgeyi ≥15° güneş düşürür).
	var sun := Daylight.sun_at(ORDOS_LAT, Daylight.solar_dec(BIRTH_DOY), OUTSIDE_MINUTE)
	var light := Daylight.light_dir(sun)
	assert_almost(rad_to_deg(asin(light.y)), Daylight.SHADOW_EL, 1e-4, "Ufuktaki güneşin ışığı 15°'den gelir")
	assert_almost(rad_to_deg(atan2(light.x, -light.z)), float(sun["az"]), 1e-4, "Işık güneşin azimutundan gelir")
	var high := Daylight.sun_at(ORDOS_LAT, Daylight.solar_dec(BIRTH_DOY), Daylight.NOON)
	assert_vec_almost(Daylight.light_dir(high), Daylight.dir_of(high), VEC_EPS, "Yüksek güneşte ışık güneşin kendisidir")


func test_refraction_lifts_the_horizon() -> void:
	assert_between(Daylight.refraction(0.0), 0.45, 0.6, "Ufukta kırılma ≈0,5°")
	assert_between(Daylight.refraction(-0.75), 0.5, 0.7, "06:03'ün güneşi ≈0,6° yukarıda görünür")
	assert_true(Daylight.refraction(30.0) < 0.05, "Yüksekte kırılma çok küçük")
	assert_true(Daylight.refraction(10.0) < Daylight.refraction(0.0), "Kırılma yükseldikçe azalır")
	for el in [-1.5, -0.75, 0.0, 5.0, 45.0, 90.0]:
		assert_true(is_finite(Daylight.refraction(el)) and Daylight.refraction(el) >= 0.0, "Kırılma sonlu ve artı (%s°)" % el)


# --- Prototipin fikstürü (tests/fixtures/time_core.json; tools/proto_fixtures/time.mjs) -------------------------------

func test_fixture_sun_moon_and_day_info_match_the_prototype() -> void:
	var fx := _fixture()
	if fx.is_empty():
		return
	var dl: Dictionary = fx["daylight"]
	for row: Array in dl["solar_dec"]:
		assert_almost(Daylight.solar_dec(float(row[0])), float(row[1]), EPS, "solar_dec(%s)" % row[0])
	var bad := 0
	for row: Array in dl["sun"]:
		bad += _sample_misses(Daylight.sun_at(float(row[0]), float(row[1]), float(row[2])), row[3], ["x", "y", "z", "el", "az"])
	assert_eq(bad, 0, "sun_at %d örnekte prototiple aynı (1e-9)" % (dl["sun"] as Array).size())
	bad = 0
	for row: Array in dl["moon"]:
		bad += _sample_misses(Daylight.moon_at(float(row[0]), float(row[1]), float(row[2]), float(row[3])), row[4], ["x", "y", "z", "el", "az", "illum"])
	assert_eq(bad, 0, "moon_at %d örnekte prototiple aynı" % (dl["moon"] as Array).size())
	for row: Array in dl["day_info"]:
		var info := Daylight.day_info(float(row[0]), float(row[1]))
		var want: Dictionary = row[2]
		for key: String in want:
			if key == "phases":
				for i in 6:
					assert_eq(str(info["phases"][i][0]), str(want["phases"][i][0]), "%s°: evre sırası" % row[0])
					assert_almost(float(info["phases"][i][1]), float(want["phases"][i][1]), EPS, "%s° %s başı" % [row[0], want["phases"][i][0]])
					assert_almost(float(info["phases"][i][2]), float(want["phases"][i][2]), EPS, "%s° %s sonu" % [row[0], want["phases"][i][0]])
			else:
				assert_almost(float(info[key]), float(want[key]), EPS, "%s° δ %.3f: %s" % [row[0], float(row[1]), key])


func test_fixture_phases_keys_light_source_and_levels_match_the_prototype() -> void:
	var fx := _fixture()
	if fx.is_empty():
		return
	var dl: Dictionary = fx["daylight"]
	var infos := {}
	var phase_bad := 0
	for row: Array in dl["phase_at"]:
		var info := _info(infos, float(row[0]), float(row[1]))
		if str(Daylight.phase_at(info, float(row[2]))) != str(row[3]):
			phase_bad += 1
	assert_eq(phase_bad, 0, "phase_at prototiple aynı")
	for row: Array in dl["sky_keys"]:
		var keys := Daylight.sky_keys(_info(infos, float(row[0]), float(row[1])), _num(row[2]), _num(row[3]))
		var want: Array = row[4]
		assert_eq(keys.size(), want.size(), "sky_keys uzunluğu (%s°)" % row[0])
		for i in mini(keys.size(), want.size()):
			assert_almost(keys[i], float(want[i]), EPS, "sky_keys[%d] (%s°)" % [i, row[0]])
	var s_bad := 0
	var keys_of := {}
	for row: Array in dl["sky_at"]:
		var id := "%s|%s|%s|%s" % [row[0], row[1], row[2], row[3]]
		if not keys_of.has(id):
			keys_of[id] = Daylight.sky_keys(_info(infos, float(row[0]), float(row[1])), _num(row[2]), _num(row[3]))
		if absf(Daylight.sky_at(keys_of[id], float(row[4])) - float(row[5])) > EPS:
			s_bad += 1
	assert_eq(s_bad, 0, "sky_at %d örnekte prototiple aynı" % (dl["sky_at"] as Array).size())
	var src_bad := 0
	for row: Array in dl["light_source"]:
		var lat := float(row[0])
		var dec := float(row[1])
		var m := float(row[2])
		var src := Daylight.light_source(_info(infos, lat, dec), m, Daylight.sun_at(lat, dec, m), Daylight.moon_at(lat, dec, m, float(row[3])))
		src_bad += _sample_misses(src, row[4], ["x", "y", "z", "k"])
	assert_eq(src_bad, 0, "light_source %d örnekte prototiple aynı" % (dl["light_source"] as Array).size())
	for row: Array in dl["light_level"]:
		assert_almost(Daylight.light_level(float(row[0]), float(row[1]), float(row[2]), float(row[3])), float(row[4]), EPS,
			"light_level(%s, %s, %s, %s)" % [row[0], row[1], row[2], row[3]])
	for row: Array in dl["night_class"]:
		assert_eq(str(Daylight.night_class(float(row[0]), bool(row[1]))), str(row[2]), "night_class(%s, %s)" % [row[0], row[1]])


# --- time.md §17 daylight ---------------------------------------------------------------------------

func test_day_lengths_match_the_design_table() -> void:
	# time.md §3: Hexi Gün I doğuş 07:11, batış 16:49, sivil 06:42 / 17:18; kamp 11 Nisan 05:22 / 18:38; Orhun 15 Temmuz 04:12 / 19:48;
	# Ordos 27 Eylül 234 doğuş 06:03, sivil 05:36; kamp 16 Kasım doğuş 07:23, batış 16:37 (±1 dk).
	var hexi := Daylight.day_info(38.9, Daylight.solar_dec(335.0))
	_near(hexi["sunrise"], "07:11", "Hexi Gün I doğuş")
	_near(hexi["sunset"], "16:49", "Hexi Gün I batış")
	_near(hexi["civil_dawn"], "06:42", "Hexi sivil şafak")
	_near(hexi["civil_dusk"], "17:18", "Hexi sivil alaca")
	var camp := Daylight.day_info(Daylight.CAMP_LAT, Daylight.camp_dec(100.0))
	_near(camp["sunrise"], "05:22", "Kamp 11 Nisan doğuş")
	_near(camp["sunset"], "18:38", "Kamp 11 Nisan batış")
	var orhun := Daylight.day_info(47.35, Daylight.solar_dec(195.0))
	_near(orhun["sunrise"], "04:12", "Orhun 15 Temmuz doğuş")
	_near(orhun["sunset"], "19:48", "Orhun 15 Temmuz batış")
	var birth := Daylight.day_info(ORDOS_LAT, Daylight.solar_dec(BIRTH_DOY))
	_near(birth["sunrise"], "06:03", "Ordos doğum doğuş")
	_near(birth["civil_dawn"], "05:36", "Ordos doğum sivil şafak")
	var winter := Daylight.day_info(Daylight.CAMP_LAT, Daylight.camp_dec(319.0))
	_near(winter["sunrise"], "07:23", "Kamp 16 Kasım doğuş")
	_near(winter["sunset"], "16:37", "Kamp 16 Kasım batış")
	# Ana kampın evreleri (time.md §4): Tan 04:21, Sabah 05:52, Öğle 10:30, İkindi 13:30, Akşam 17:38, Gece 19:39.
	var want := {&"dawn": "04:21", &"morning": "05:52", &"noon": "10:30", &"golden": "13:30", &"dusk": "17:38", &"night": "19:39"}
	for phase: StringName in want:
		_near(Daylight.phase_start(camp, phase), want[phase], "Kamp %s başı" % phase)


func test_menu_minute_is_the_prototype_menu_sun_with_the_camp_offset() -> void:
	# K67: sapma tarihten (solar_dec(100) = 7,4350°) ve −0,0127° payla; 14:46,2'nin güneşi menü vektörüne yakın. time.md §17 1e−5 der;
	# 886,18 iki ondalığa yuvarlanmış dakikadır ve 1,43e−5 verir (prototipin sınaması da 2e−5 ile bakar); tam dakika 886,1756'da 1e−6.
	assert_almost(Daylight.solar_dec(100.0), 7.43, 0.01, "solar_dec(100) 7,43°")
	var sun := Daylight.sun_at(Daylight.CAMP_LAT, Daylight.camp_dec(Daylight.CAMP_DOY), Daylight.MENU_MINUTE)
	var dir := Daylight.dir_of(sun)
	assert_vec_almost(dir, Daylight.MENU_SUN.normalized(), 2e-5, "Serbest Gez'in açılış güneşi menü vektörü (Ev'in ikindi ışığı)")
	var exact := Daylight.dir_of(Daylight.sun_at(Daylight.CAMP_LAT, Daylight.camp_dec(Daylight.CAMP_DOY), 886.1756))
	assert_vec_almost(exact, Daylight.MENU_SUN.normalized(), 1e-6, "Tam dakika 886,1756'da 1e−6")
	assert_almost(float(sun["el"]), 36.716, 0.001, "Yükseklik 36,716°")
	assert_almost(float(sun["az"]), 235.125, 0.001, "Azimut 235,125° (güneybatı)")
	# s 4,3: ikindi→akşam 0,3 (time.md §5.2) 1e−9 içinde.
	var info := Daylight.day_info(Daylight.CAMP_LAT, Daylight.camp_dec(Daylight.CAMP_DOY))
	var keys := Daylight.sky_keys(info, Daylight.CAMP_GOLDEN, Daylight.MENU_MINUTE)
	assert_almost(Daylight.sky_at(keys, Daylight.MENU_MINUTE), 4.3, 1e-9, "Menü dakikasında s 4,3")
	var fx := _fixture()
	if not fx.is_empty():
		var camp: Dictionary = fx["daylight"]["camp"]
		assert_almost(Daylight.camp_dec(Daylight.CAMP_DOY), float(camp["dec"]), EPS, "Kampın sapması fikstürle aynı")
		assert_eq(_sample_misses(sun, camp["menu_sun"], ["x", "y", "z", "el", "az"]), 0, "Açılış güneşi fikstürle aynı")


func test_phases_and_keys_are_ordered_all_year_and_sum_to_a_day() -> void:
	# 38°, 43,5°, 47,35° için 365 günün hepsinde evre sınırları ve anahtarlar sıralı, evre toplamı 1.440.
	for lat in [38.0, 43.5, 47.35]:
		var disorder := 0
		var sums := 0
		for doy in 365:
			var info := Daylight.day_info(lat, Daylight.solar_dec(float(doy)))
			var phases: Array = info["phases"]
			var total := 0.0
			for i in 6:
				var a := float(phases[i][1])
				var b := float(phases[i][2])
				total += fposmod(b - a, 1440.0)
				if i < 5 and not (a < b and b == float(phases[i + 1][1])):
					disorder += 1
			if absf(total - 1440.0) > 1e-6:
				sums += 1
			var keys := Daylight.sky_keys(info, NAN, NAN)
			for k in range(1, keys.size() / 2):
				if keys[k * 2] < keys[(k - 1) * 2]:
					disorder += 1
		assert_eq(disorder, 0, "%s°: sınırlar ve anahtarlar bütün yıl sıralı" % lat)
		assert_eq(sums, 0, "%s°: altı evre bir günü doldurur" % lat)


func test_light_source_dips_in_the_twilight_windows() -> void:
	# time.md §17 sky-keys: akşam ve sabah penceresinde k en düşük ≈0,07; güneş 15°'de kLow 1.
	assert_almost(Daylight.k_low(15.0), 1.0, 1e-12, "Güneş 15°'de doğrudan ışık tam")
	assert_almost(Daylight.k_low(0.0), Daylight.K_DUSK, 1e-12, "Ufukta 0,35")
	var info := Daylight.day_info(Daylight.CAMP_LAT, Daylight.camp_dec(100.0))
	var dec := float(info["dec"])
	var lowest := 9.0
	var dusk_low := 9.0
	for i in 1440 * 4:
		var m := float(i) * 0.25
		var age := GameCalendar.moon_age(GameClock.abs_of(1171, m))
		var src := Daylight.light_source(info, m, Daylight.sun_at(47.35, dec, m), Daylight.moon_at(47.35, dec, m, age))
		lowest = minf(lowest, float(src["k"]))
		if m >= float(info["sunset"]) and m < float(info["civil_dusk"]) + 45.0:
			dusk_low = minf(dusk_low, float(src["k"]))
	assert_between(dusk_low, 0.05, 0.1, "Akşam penceresinin çukuru ≈0,07")
	assert_between(lowest, 0.05, 0.1, "Günün en düşük k'sı pencerelerde")


func test_light_level_reference_points() -> void:
	# time.md §12.3: öğle 1; batış 0,60; sivil alaca 0,35; açık dolunay ≥30° 0,35; yarım ay 30°'de 0,20; kapalı gecede dolunay 0,08; aysız 0,05.
	assert_almost(Daylight.light_level(50.0, -10.0, 0.0), 1.0, 1e-3, "Öğle")
	assert_almost(Daylight.light_level(-0.833, -10.0, 0.0), 0.6, 1e-3, "Batış")
	assert_almost(Daylight.light_level(-6.0, -10.0, 0.0), 0.35, 1e-3, "Sivil alaca")
	assert_almost(Daylight.light_level(-20.0, 30.0, 1.0), 0.35, 1e-3, "Açık dolunay ≥30°")
	assert_almost(Daylight.light_level(-20.0, 30.0, 0.5), 0.2, 1e-3, "Yarım ay 30°")
	assert_almost(Daylight.light_level(-20.0, 45.0, 1.0, 0.9), 0.08, 1e-3, "Kapalı gecede dolunay")
	assert_almost(Daylight.light_level(-20.0, -5.0, 0.0), 0.05, 1e-3, "Aysız gece")
	assert_eq(Daylight.night_class(1.0), &"day")
	assert_eq(Daylight.night_class(0.3), &"dim")
	assert_eq(Daylight.night_class(0.2), &"dark")
	assert_eq(Daylight.night_class(0.05, true), &"lit", "Işık havuzu her zaman lit")


# --- Yardımcılar ------------------------------------------------------------------------------

const FIXTURE := "res://tests/fixtures/time_core.json"


func _fixture() -> Dictionary:
	if not FileAccess.file_exists(FIXTURE):
		fail("Fikstür yok: %s (node tools/proto_fixtures/time.mjs)" % FIXTURE)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	return parsed if parsed is Dictionary else {}


func _info(cache: Dictionary, lat: float, dec: float) -> Dictionary:
	var id := "%s|%s" % [lat, dec]
	if not cache.has(id):
		cache[id] = Daylight.day_info(lat, dec)
	return cache[id]


static func _num(v: Variant) -> float:
	return float(v) if v is float or v is int else NAN


## Örneğin anahtarlarından prototipin değerinden 1e-9'dan çok ayrılanların sayısı.
static func _sample_misses(sample: Dictionary, want: Dictionary, keys: Array) -> int:
	var n := 0
	for key: String in keys:
		if want.get(key) == null or absf(float(sample[key]) - float(want[key])) > EPS:
			n += 1
	return n


func _near(minute: float, hhmm: String, label: String) -> void:
	assert_almost(minute, GameClock.parse_hhmm(hhmm), 1.0, "%s %s (±1 dk): %s" % [label, hhmm, GameClock.hhmm(minute)])


## Örneği prototipin değerleriyle karşılaştırır: [x, y, z, el, az].
func _assert_sample(sample: Dictionary, expected: Array, label: String) -> void:
	var keys := ["x", "y", "z", "el", "az"]
	for i in keys.size():
		assert_almost(float(sample[keys[i]]), float(expected[i]), EPS * 100.0, "%s: %s prototiple aynı olmalı" % [label, keys[i]])


## time.md §2'nin ay yaşı (gün).
static func _moon_age(day_n: int, minute: float) -> float:
	return fposmod(float(day_n) + minute / 1440.0 - 1044.75 + 14.765, Daylight.SYNODIC)
