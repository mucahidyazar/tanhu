extends TestCase
## Islaklık, kar örtüsü ve Kar Kabuğu (WetState, SnowPack; weather.md §5.9, §15 W8, W26; d2/weather-model.json v2): prototipin altın
## değerleriyle (tests/fixtures/weather_core.json) ve kural sınamalarıyla.
##   - W8: yağmurda zemin 0,6'ya 1,15 ±0,05 sa'te; analitik atlama ile adımlı tümleme farkı ≤1e-3; prototiple 1e-12.
##   - Kampta kar tutmaz (bahar, yaz, güz): serpinti zemini ve keçeyi ıslatır, örtü bırakmaz.
##   - Kar örtüsü saat saat gerçek planla (3 kış, iki iklim) prototiple aynı; kabuk yalnız kural sırasıyla oluşur.
##   - W26: WeatherPlanner ve SnowPack sabit tohumla (2048377054) 150 kış: steppe_south derin kar payı 0,135 ±0,03 (Yol Haritası) ve
##     0,16 ±0,03 (weather.md §15, modelin değeri), kabuk 0,63 ±0,3 ve 0,62 ±0,3 / kış; gobi kabuk ≤0,05 / kış; hexi I. Perde satırında
##     kabuk 0. Sayılar prototipin gerçek çekirdeğiyle de aynıdır (1e-12) ve d2/weather-model.json'la tutar.

const FIXTURE := "res://tests/fixtures/weather_core.json"

static var _fx: Dictionary = {}
## W26'nın sonuçları dosyada bir kez koşulur (her biri birkaç saniye).
static var _w26: Dictionary = {}


func before_each() -> void:
	if _fx.is_empty():
		_fx = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))


static func _params(id: String) -> PackedFloat64Array:
	return WeatherData.params_of(WeatherData.index_of(id))


# --- Islaklık ---------------------------------------------------------------------------------------------------------

func test_wet_state_matches_prototype() -> void:
	for c: Dictionary in _fx["wet"]:
		var w := WetState.new(bool(c["accumulate"]))
		for st: Array in c["steps"]:
			var acc := -1 if c["id"] == "accumulate" else 0
			w.step(float(st[1]), _params(st[0]), bool(st[2]), c["id"] == "camp", acc)
			var label := "%s %s %.2f sa" % [c["id"], st[0], float(st[1])]
			assert_almost(w.ground, float(st[3]), 1e-12, label + " zemin")
			assert_almost(w.felt, float(st[4]), 1e-12, label + " keçe")
			assert_almost(w.mud, float(st[5]), 1e-12, label + " çamur")
			assert_almost(w.puddle(), float(st[6]), 1e-12, label + " birikinti")
			assert_almost(w.snow, float(st[7]), 1e-12, label + " taze kar")


func test_w8_rain_wets_ground_to_point_six_in_one_point_fifteen_hours() -> void:
	var w := WetState.new()
	var t := 0.0
	while w.ground < 0.6 and t < 3.0:
		w.step(0.01, _params("rain"))
		t += 0.01
	assert_between(t, 1.10, 1.20, "Yağmurda zemin 0,6'ya 1,15 ±0,05 sa'te (k 0,8)")
	# Analitik atlama ile adımlı tümleme aynı (≤1e-3).
	var a := WetState.new()
	var b := WetState.new()
	a.skip(2.5, _params("downpour"))
	for i in 250:
		b.step(0.01, _params("downpour"))
	assert_almost(a.ground, b.ground, 1e-3)
	assert_almost(a.mud, b.mud, 1e-3, "Çamur zemini gecikmeli izler")
	# Gece kuruma ×0,12/0,35.
	var day := WetState.new()
	var night := WetState.new()
	day.ground = 1.0
	night.ground = 1.0
	day.skip(1.0, _params("clear"), false)
	night.skip(1.0, _params("clear"), true)
	assert_almost(day.ground, exp(-0.35), 1e-12, "Gündüz −0,35 sa⁻¹")
	assert_almost(night.ground, exp(-0.12), 1e-12, "Gece −0,12 sa⁻¹")


func test_camp_snow_does_not_settle_outside_winter() -> void:
	var w := WetState.new(false)
	w.step(2.0, _params("snow"))
	assert_almost(w.snow, 0.0, 1e-12, "Kampta kar tutmaz: taze kar yok")
	assert_true(w.ground > 0.3 and w.felt > 0.4, "Serpinti zemini (+0,2) ve keçeyi (+0,3) ıslatır")
	var winter := WetState.new(true)
	winter.step(2.0, _params("snow"))
	assert_true(winter.snow > 0.6, "Kışın kar tutar")
	assert_almost(winter.ground, 0.0, 1e-12, "Kar zemini ıslatmaz")


func test_wet_state_save_round_trip() -> void:
	var w := WetState.new()
	w.step(1.3, _params("rain"))
	w.bow = 0.42
	var r := WetState.new().from_array(JSON.parse_string(JSON.stringify(w.to_array())))
	assert_almost(r.ground, w.ground, 0.0006)
	assert_almost(r.bow, 0.42, 1e-9)
	assert_almost(r.puddle(), w.puddle(), 0.003, "Birikinti üç basamaklı zeminden")


# --- Kar örtüsü ve kabuk ----------------------------------------------------------------------------------------------

func test_snowpack_follows_real_plan_like_prototype() -> void:
	for c: Dictionary in _fx["packs"]:
		var climate := str(c["climate"])
		var seed := int(c["seed"])
		var p := WeatherPlanner.new({"climate": climate, "season": "winter", "seed": seed, "zone": climate})
		var pack := SnowPack.new()
		var frac := PackedFloat64Array()
		frac.resize(WeatherData.count())
		var o := SnowPack.Opts.new()
		o.lat = float(c["lat"])
		o.seed = seed
		o.zone_hash = WeatherRng.str_hash(climate)
		p.start(0.0)
		var days: Array = c["days"]
		var di := 0
		var bad := 0
		for d in 360:
			if d % 120 == 0:
				pack.reset()
			o.dec = Daylight.solar_dec(float((319 + (d % 120)) % 365))
			for k in 24:
				var h := float(d * 24 + k)
				p.advance(h)
				SnowPack.type_hours(p.plan, h, h + 1.0, frac)
				pack.hour(h, frac, o)
				if k == 5:
					var want: Array = days[di]
					di += 1
					if absf(pack.snowpack - float(want[1])) > 1e-9 or pack.deep != bool(want[2]) or pack.crust != int(want[3]) or pack.formed != int(want[4]):
						bad += 1
						if bad <= 3:
							fail("%s gün %d: örtü %.6f derin %s kabuk %d (%d) ≠ %s" % [climate, d, pack.snowpack, pack.deep, pack.crust, pack.formed, str(want)])
		assert_eq(bad, 0, "%s: 360 günün hepsi prototiple aynı" % climate)


## Bir günün saatlerini tür dizisinden kurar (06:00'dan başlayan gün).
func _feed(pack: SnowPack, h0: int, types: Array, o: SnowPack.Opts) -> void:
	var frac := PackedFloat64Array()
	frac.resize(WeatherData.count())
	for i in types.size():
		frac.fill(0.0)
		frac[WeatherData.index_of(str(types[i]))] = 1.0
		pack.hour(float(h0 + i), frac, o)


static func _rep(type: String, n: int) -> Array:
	var a: Array = []
	for i in n:
		a.append(type)
	return a


static func _day(type: String, n: int, night: String) -> Array:
	return _rep(type, n) + _rep("overcast", 14 - n) + _rep(night, 10)


func test_w26_crust_forms_only_in_rule_order() -> void:
	var o := SnowPack.Opts.new()
	o.fixed_el = 0.0
	# Sulu kar yolu: 06:00'da derin kar, gündüz ≥1 sa sulu kar, 20:00–06:00 açık → şafakta kabuk.
	var p := SnowPack.new().reset(0.9)
	_feed(p, 0, _rep("overcast", 6), o)
	assert_true(p.deep, "06:00'da derin kar okunur")
	_feed(p, 6, _rep("sleet", 2) + _rep("overcast", 12) + _rep("clear", 10), o)
	assert_true(p.crust >= 5 and p.crust <= 10, "Kabuk 5–10 gün (%d)" % p.crust)
	assert_eq(p.formed, 1)
	# Kapalı gece kabuk vermez.
	var q := SnowPack.new().reset(0.9)
	_feed(q, 0, _rep("overcast", 6), o)
	_feed(q, 6, _rep("sleet", 2) + _rep("overcast", 22), o)
	assert_eq(q.crust, 0, "Kapalı gece kabuk vermez")
	# Sıra ters: önce açık gece, sonra sulu kar → yok.
	var r := SnowPack.new().reset(0.9)
	_feed(r, 0, _rep("clear", 6), o)
	_feed(r, 6, _rep("overcast", 14) + _rep("clear", 4) + _rep("overcast", 6), o)
	_feed(r, 30, _rep("sleet", 2) + _rep("overcast", 22), o)
	assert_eq(r.crust, 0, "Sulu kar ertesi gecenin açıklığını bekler")
	# Derin kar yoksa yok.
	var s := SnowPack.new().reset(0.4)
	_feed(s, 0, _rep("overcast", 6), o)
	_feed(s, 6, _day("sleet", 2, "clear"), o)
	assert_eq(s.crust, 0, "Derin kar yoksa kabuk yok")
	# Yoğun kar ve açık öğle yolu tohumludur (%12): bir tohumda oluşur, gece kapalıysa hiçbir tohumda oluşmaz.
	var formed := 0
	var cloudy := 0
	for seed in range(1, 201):
		for night: String in ["clear", "overcast"]:
			var g := SnowPack.new().reset(0.95)
			var go := SnowPack.Opts.new()
			go.fixed_el = 0.0
			go.seed = seed
			go.zone_hash = 3
			_feed(g, 0, _rep("heavy_snow", 6), go)
			_feed(g, 6, _rep("heavy_snow", 3) + ["overcast"] + _rep("clear", 5) + _rep("overcast", 5) + _rep(night, 10), go)
			if g.crust > 0:
				if night == "clear":
					formed += 1
				else:
					cloudy += 1
	assert_true(formed > 8 and formed < 50, "Açık öğle yolu %d/200" % formed)
	assert_eq(cloudy, 0, "Kapalı gecede hiçbir tohumda yok")
	# Kabuk sürerken yenisi oluşmaz; örtü 0,3 altına inince biter; bahar bitirir.
	var t := SnowPack.new().reset(0.9)
	_feed(t, 0, _rep("overcast", 6), o)
	_feed(t, 6, _day("sleet", 2, "clear"), o)
	assert_true(t.crust > 0)
	var n := t.crust
	_feed(t, 30, _day("sleet", 2, "clear"), o)
	assert_eq(t.formed, 1, "Kabuk sürerken yenisi oluşmaz")
	assert_eq(t.crust, n - 1, "Her şafak bir gün düşer")
	t.snowpack = 0.31
	var sunny := SnowPack.Opts.new()
	sunny.fixed_el = 30.0
	_feed(t, 54, _rep("clear", 30), sunny)
	assert_eq(t.crust, 0, "Örtü 0,3'ün altına inince biter")
	var u := SnowPack.new().reset(0.9)
	u.crust = 6
	var spring := SnowPack.Opts.new()
	spring.fixed_el = 0.0
	spring.season = &"spring"
	_feed(u, 0, ["overcast"], spring)
	assert_eq(u.crust, 0, "Bahar bitirir")


func test_snowpack_gain_loss_and_save() -> void:
	var o := SnowPack.Opts.new()
	o.fixed_el = 0.0
	var p := SnowPack.new()
	_feed(p, 0, _rep("snow", 10), o)
	assert_almost(p.snowpack, 0.35, 1e-9, "Kar saatte 0,035")
	_feed(p, 10, _rep("heavy_snow", 2), o)
	assert_almost(p.snowpack, 0.53, 1e-9, "Yoğun kar saatte 0,09")
	_feed(p, 12, _rep("clear", 5), o)
	assert_almost(p.snowpack, 0.51, 1e-9, "Yağışsız saat −0,004 (güneş yok)")
	var hot := SnowPack.Opts.new()
	hot.fixed_el = 20.0
	_feed(p, 17, ["clear"], hot)
	assert_almost(p.snowpack, 0.476, 1e-9, "Güneş >15° açıkta ek −0,03")
	var r := SnowPack.new().from_dict(JSON.parse_string(JSON.stringify(p.to_dict())))
	assert_almost(r.snowpack, 0.476, 1e-9)
	assert_eq(r.crust, 0)


# --- W26 ---------------------------------------------------------------------------------------------------------------

func _stats(id: String) -> Dictionary:
	if not _w26.has(id):
		var want: Dictionary = _fx["winter"][id]
		var t0 := Time.get_ticks_msec()
		_w26[id] = SnowPack.winter_stats(str(want["climate"]), {"exclude": want["exclude"]})
		_w26[id]["ms"] = Time.get_ticks_msec() - t0
	return _w26[id]


func test_w26_steppe_south_deep_snow_and_crust() -> void:
	var s := _stats("steppe_south")
	assert_eq(int(s["winters"]), 150)
	assert_eq(int(s["days"]), 150 * 120)
	var deep := float(s["deep_snow_share"])
	var crust := float(s["crust_per_winter"])
	print("    W26 steppe_south: derin kar %.4f, kabuk/kış %.3f, kabuklu gün %.4f (%d ms)" % [deep, crust, float(s["crust_day_share"]), int(s["ms"])])
	assert_true(absf(deep - 0.135) <= 0.03, "Yol Haritası kabulü: derin kar 0,135 ±0,03 (%.4f)" % deep)
	assert_true(absf(crust - 0.63) <= 0.3, "Yol Haritası kabulü: kabuk 0,63 ±0,3 / kış (%.3f)" % crust)
	assert_true(absf(deep - 0.16) <= 0.03, "weather.md §15: modelin değerine ortalanmış 0,16 ±0,03 (%.4f)" % deep)
	assert_true(absf(crust - 0.62) <= 0.3, "weather.md §15: 0,62 ±0,3 / kış (%.3f)" % crust)
	var want: Dictionary = _fx["winter"]["steppe_south"]
	assert_almost(deep, float(want["deepSnowShare"]), 1e-12, "Prototipin gerçek çekirdeğiyle aynı")
	assert_almost(crust, float(want["crustPerWinter"]), 1e-12)
	assert_almost(float(s["crust_day_share"]), float(want["crustDayShare"]), 1e-12)


func test_w26_gobi_crust_and_hexi_act1_zero() -> void:
	var gobi := _stats("gobi")
	print("    W26 gobi: derin kar %.4f, kabuk/kış %.3f (%d ms)" % [float(gobi["deep_snow_share"]), float(gobi["crust_per_winter"]), int(gobi["ms"])])
	assert_true(float(gobi["crust_per_winter"]) <= 0.05, "gobi kabuk ≤0,05 / kış (%.3f)" % float(gobi["crust_per_winter"]))
	assert_almost(float(gobi["crust_per_winter"]), float(_fx["winter"]["gobi"]["crustPerWinter"]), 1e-12)
	var act1 := _stats("hexi_act1")
	print("    W26 hexi I. Perde: derin kar %.4f, kabuk/kış %.3f (%d ms)" % [float(act1["deep_snow_share"]), float(act1["crust_per_winter"]), int(act1["ms"])])
	assert_eq(float(act1["crust_per_winter"]), 0.0, "I. Perde Kışlak satırında kabuk 0")
	assert_eq(float(act1["crust_day_share"]), 0.0)
	assert_almost(float(act1["deep_snow_share"]), float(_fx["winter"]["hexi_act1"]["deepSnowShare"]), 1e-12)


func test_w26_matches_weather_model_file() -> void:
	# d2/weather-model.json v2 prototipin üretecidir (üç basamak): Godot'un koşusu ona yuvarlanınca eşittir.
	var path := ProjectSettings.globalize_path("res://").path_join("../docs/design/d2/weather-model.json").simplify_path()
	if not FileAccess.file_exists(path):
		push_warning("weather-model.json yok: %s" % path)
		return
	var model: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var by: Dictionary = model["byClimate"]
	var steppe := _stats("steppe_south")
	assert_almost(snappedf(float(steppe["deep_snow_share"]), 0.001), float(by["steppe_south"]["winter"]["deepSnowShare"]), 1e-9, "steppe_south derin kar modelle")
	assert_almost(snappedf(float(steppe["crust_per_winter"]), 0.01), float(by["steppe_south"]["winter"]["crustPerWinter"]), 1e-9, "steppe_south kabuk modelle")
	var act1 := _stats("hexi_act1")
	assert_eq(float(by["hexi"]["act1"]["crustPerWinter"]), float(act1["crust_per_winter"]), "hexi I. Perde kabuk modelle")
	var orkhon := _stats("orkhon")
	print("    W26 orkhon (kampın kışı): derin kar %.4f, kabuk/kış %.3f (%d ms)" % [float(orkhon["deep_snow_share"]), float(orkhon["crust_per_winter"]), int(orkhon["ms"])])
	assert_almost(snappedf(float(orkhon["deep_snow_share"]), 0.001), float(by["orkhon"]["winter"]["deepSnowShare"]), 1e-9, "Kampın kışı ≈%6,7 derin kar (§5.9)")
