extends TestCase
## Havanın yüzü (WeatherFx, WeatherStorm, WeatherSigns; weather.md §3.4, §7, §8, §15 W4, W7, W9, W10): prototipin altın değerleriyle.
##   - Karışım: vektör, ton, sis rengi, tersiyle görüş, mutlak sis uzağı 1e-12.
##   - fx: rüzgâr, görüş, iz, ateş, araba, kabuk, ay, pinFx; §8.1'in sayıları.
##   - Fırtına hücresi: şimşek dizisi (an, yer, uzaklık, vuruş sayısı) prototiple 1e-9; fırtına başına ≤1 yakın düşüş.
##   - Yıldırım hedefi: uzun ve yalnız olana; Çocuk 25 m içinde hedef olmaz; vurulan yapı 1 gün bekler; Hikâye'de oyuncu hedef olmaz.
##   - Gök gürültüsü: d / 343 sn, bant ≤600 m, ≤3 km, ≤10 km.
##   - İşaretler ve gök okuma prototiple aynı; sev ≥3 her bölüm Normal'de ≥1 sa önce üç kanaldan (biri ses) okunur (W4).

const FIXTURE := "res://tests/fixtures/weather_core.json"
const JS_KEYS := ["cloud", "cover", "coverSky", "shadowK", "cloudSpeedK", "dark", "sunK", "hemiK", "expK", "fogNearK", "fogFarK",
	"fogMix", "sat", "con", "rain", "snow", "hail", "dust", "points", "splashes", "wind", "gust", "vis", "mask", "wetGround",
	"wetFelt", "snowRate", "storm", "fogFarAbs"]

static var _fx: Dictionary = {}


func before_each() -> void:
	if _fx.is_empty():
		_fx = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))


static func _num(v: Variant) -> float:
	if v is String:
		return INF if v == "inf" else -INF if v == "-inf" else NAN
	return float(v) if v != null else INF


static func _p(id: String) -> PackedFloat64Array:
	return WeatherData.params_of(WeatherData.index_of(id))


func _close(a: float, b: float, eps: float, label: String) -> void:
	if is_inf(b) or is_inf(a):
		assert_eq(a, b, label)
	else:
		assert_almost(a, b, eps, label)


func test_blend_matches_prototype() -> void:
	for c: Dictionary in _fx["blends"]:
		var out := PackedFloat64Array()
		WeatherFx.blend(_p(c["a"]), _p(c["b"]), float(c["k"]), out)
		var want: Dictionary = c["out"]
		var label := "%s→%s %.2f" % [c["a"], c["b"], float(c["k"])]
		for i in JS_KEYS.size():
			_close(out[i], _num(want[JS_KEYS[i]]), 1e-12, "%s %s" % [label, JS_KEYS[i]])
		for ch in 3:
			assert_almost(out[WeatherData.P_TONE_R + ch], float(want["tone"][ch]), 1e-12, label + " ton")
			assert_almost(out[WeatherData.P_TINT_R + ch], float(want["fogTint"][ch]), 1e-12, label + " sis rengi")
		assert_eq(out[WeatherData.P_HAS_TINT] > 0.5, bool(want["hasTint"]), label + " sis rengi var")


func test_fx_matches_prototype() -> void:
	for c: Dictionary in _fx["fxs"]:
		var w := WetState.new()
		w.ground = float(c["wet"][0])
		w.felt = float(c["wet"][1])
		w.mud = float(c["wet"][2])
		w.bow = float(c["wet"][3])
		w.snow = float(c["wet"][4])
		var p := PackedFloat64Array()
		WeatherFx.blend(_p(c["a"]), _p(c["b"]), float(c["k"]), p)
		var o := WeatherFx.Opts.new()
		o.a = WeatherData.index_of(str(c["a"]))
		o.b = WeatherData.index_of(str(c["b"]))
		o.k = float(c["k"])
		var opts: Dictionary = c["opts"]
		o.gust = float(opts.get("gust", 0.0))
		o.night = bool(opts.get("night", false))
		o.moon_up = bool(opts.get("moonUp", false))
		o.snow_ground = bool(opts.get("snowGround", false))
		o.accumulate = bool(opts.get("accumulate", true))
		o.snow_felt = float(opts.get("snowFelt", 0.5))
		o.strike_risk = float(opts.get("strikeRisk", 0.0))
		o.hail = opts.get("hail", {})
		if opts.has("pin"):
			var pin: Dictionary = opts["pin"]
			o.pin = {"mask": pin["mask"], "track_k": pin["trackK"], "douse": pin["douse"]}
		var fx := WeatherFx.new().write(p, w, o)
		var want: Dictionary = c["fx"]
		var label := "%s→%s" % [c["a"], c["b"]]
		assert_eq(String(fx.type), str(want["type"]), label + " tür")
		assert_eq(fx.sev, int(want["sev"]), label + " sev")
		var pairs := {"wind": fx.wind, "gust": fx.gust, "cloud": fx.cloud, "vis": fx.vis, "mask": fx.mask, "hearK": fx.hear_k,
			"trackK": fx.track_k, "scentK": fx.scent_k, "fireK": fx.fire_k, "fireOutS": fx.fire_out_s, "fireRing": fx.fire_ring,
			"douse": fx.douse, "dryK": fx.dry_k, "wetGround": fx.wet_ground, "wetFelt": fx.wet_felt, "mud": fx.mud, "puddle": fx.puddle,
			"snowFresh": fx.snow_fresh, "cartK": fx.cart_k, "roughK": fx.rough_k, "fatigueK": fx.fatigue_k, "coneK": fx.cone_k,
			"snowFelt": fx.snow_felt, "strikeRisk": fx.strike_risk}
		for key: String in pairs:
			_close(float(pairs[key]), _num(want[key]), 1e-12, "%s %s" % [label, key])
		assert_eq(fx.cart_lock, bool(want["cartLock"]), label + " araba kilidi")
		assert_eq(fx.gale_damage, bool(want["galeDamage"]), label + " fırtına hasarı")
		assert_eq(fx.moon_seen, bool(want["moonSeen"]), label + " ay görünür")
		assert_eq(fx.blizzard, bool(want["blizzard"]), label + " tipi")
		assert_eq(is_nan(fx.track_abs), want["trackAbs"] == null, label + " mutlak iz")
		if want["trackAbs"] != null:
			assert_almost(fx.track_abs, float(want["trackAbs"]), 1e-12)
		assert_eq(fx.hail.is_empty(), want["hail"] == null, label + " dolu")


func test_effect_table_rows() -> void:
	# §8.1: Kara Boran rüzgârı 8 (bora 15), iz 15 sn, taşsız ateş 40 sn; tipi görüş 40 m; sağanak görüş 70 m; fırtına 16 m/sn.
	var kb := WeatherData.index_of(&"kara_boran")
	assert_almost(_p("kara_boran")[WeatherData.P_WIND], 8.0, 1e-12)
	assert_almost(_p("kara_boran")[WeatherData.P_GUST], 15.0, 1e-12)
	assert_almost(WeatherData.fx_of(kb)[WeatherData.F_TRACK_ABS], 15.0, 1e-12, "Kara Boran izi 15 sn")
	assert_almost(WeatherData.fx_of(kb)[WeatherData.F_FIRE_OUT_S], 40.0, 1e-12, "Taşsız ateş 40 sn'de söner")
	assert_almost(WeatherFx.fog_far_of(1400.0, _p("blizzard")), 140.0, 1e-12, "Tipi sisi 140 m (act1 §10)")
	assert_almost(WeatherFx.fog_far_of(1400.0, _p("rain")), 490.0, 1e-9, "Yağmurda 1400 m'lik taban 490 m")
	assert_almost(_p("downpour")[WeatherData.P_VIS], 70.0, 1e-12)
	assert_almost(_p("gale")[WeatherData.P_WIND], 16.0, 1e-12)
	assert_true(is_inf(_p("clear")[WeatherData.P_VIS]), "Açıkta görüş sınırsız")
	# Her türün gök örtüsü (§3.4 cloud sütunu).
	var cloud := {"clear": 0.0, "cloud": 0.35, "overcast": 0.9, "fog": 0.7, "drizzle": 0.9, "rain": 0.9, "downpour": 1.0, "thunderstorm": 1.0,
		"dry_storm": 0.6, "hail": 1.0, "wind": 0.1, "gale": 0.3, "sleet": 0.9, "snow": 0.85, "heavy_snow": 1.0, "blizzard": 1.0,
		"kara_boran": 1.0, "dust_storm": 0.8}
	for id: String in cloud:
		assert_almost(_p(id)[WeatherData.P_CLOUD], float(cloud[id]), 1e-12, "%s örtüsü" % id)
	assert_almost(WeatherFx.wind_k(3.0), 1.0, 1e-12)
	assert_almost(WeatherFx.wind_k(16.0), 2.309, 0.001, "Fırtınada çim bükümü ×2,3 (W18)")
	assert_almost(WeatherFx.fog_factor(60.0, 10.0), 0.6667, 0.001, "Siste 10 m'deki oyuncu ×0,67 (§8.2)")
	assert_almost(WeatherFx.fog_factor(140.0, 10.0), 1.0, 1e-12, "Görüş ≥100 m'de sis gizlemez")


func test_storm_events_match_prototype() -> void:
	for c: Dictionary in _fx["storms"]:
		var out: Array[WeatherStorm.Event] = []
		WeatherStorm.storm_events(float(c["t0"]), float(c["t1"]), int(c["seed"]), WeatherRng.str_hash(str(c["zone"])), float(c["flowX"]),
			float(c["flowZ"]), float(c["near"]), float(c["rate"]), out)
		var want: Array = c["events"]
		var label := "fırtına %s %.2f" % [c["zone"], float(c["t0"])]
		assert_eq(out.size(), want.size(), label + " şimşek sayısı")
		var near := 0
		for i in mini(out.size(), want.size()):
			var e := out[i]
			var w: Dictionary = want[i]
			var ok := absf(e.t - float(w["t"])) <= 1e-9 and e.ground == bool(w["ground"]) and absf(e.x - float(w["x"])) <= 1e-6
			ok = ok and absf(e.z - float(w["z"])) <= 1e-6 and absf(e.d - float(w["d"])) <= 1e-6 and e.strokes == int(w["strokes"])
			ok = ok and e.near == bool(w["near"]) and absf(e.u - float(w["u"])) <= 1e-12 and absf(e.v - float(w["v"])) <= 1e-12
			if not ok:
				fail("%s #%d: t %.6f yer %s (%.2f, %.2f) d %.2f vuruş %d ≠ %s" % [label, i, e.t, e.ground, e.x, e.z, e.d, e.strokes, JSON.stringify(w)])
				break
			if e.ground and (e.near or e.d <= WeatherStorm.NEAR_M):
				near += 1
		assert_true(near <= 1, "%s: fırtına başına ≤1 yakın düşüş (%d)" % [label, near])


func test_storm_cell_statistics() -> void:
	# §8.7: ≈15 şimşek, ≈4,6 yıldırım; fırtınaların ≈%33'ünde biri ≤600 m'de (2000 fırtına, ortalama 263 sn).
	var out: Array[WeatherStorm.Event] = []
	var flashes := 0
	var strikes := 0
	var close := 0
	for i in 2000:
		var dur_h := 263.0 / WeatherPlanner.S_PER_H
		WeatherStorm.storm_events(float(i) * 7.25, float(i) * 7.25 + dur_h, 4242, 7, 0.871, 0.49, 0.0, 1.0, out)
		var any := false
		for e in out:
			flashes += 1
			if e.ground:
				strikes += 1
				if e.d <= 600.0:
					any = true
		if any:
			close += 1
	assert_between(flashes / 2000.0, 12.0, 18.0, "Fırtına başına ≈15 şimşek")
	assert_between(strikes / 2000.0, 3.5, 5.8, "Fırtına başına ≈4,6 yıldırım")
	assert_between(close / 2000.0, 0.25, 0.42, "Fırtınaların ≈%33'ünde ≤600 m'de yıldırım")


func test_strike_pick_matches_prototype_and_fair_rules() -> void:
	var cands: Array = _fx["strikes"]["cands"]
	for c: Dictionary in _fx["strikes"]["cases"]:
		var rules: Dictionary = (c["rules"] as Dictionary).duplicate(true)
		var t := WeatherStorm.strike_pick(cands, float(c["point"][0]), float(c["point"][1]), rules)
		var got: Variant = t.get("id") if not t.is_empty() else null
		assert_eq(got, c["target"], "hedef %s %s" % [str(c["point"]), JSON.stringify(c["rules"])])
	# Kurulmakta olan yapı aday değildir; Çocuk 25 m içinde hedef olmaz.
	var site := [{"id": "site", "kind": "structure", "x": 0.0, "z": 0.0, "h": 8.6, "building": true}]
	assert_true(WeatherStorm.strike_pick(site, 0.0, 0.0).is_empty(), "Kurulan yapıya inmez")
	var tree := [{"id": "t", "kind": "tree", "x": 5.0, "z": 0.0, "h": 12.0}]
	assert_true(WeatherStorm.strike_pick(tree, 5.0, 0.0, {"child": {"x": 0.0, "z": 0.0}}).is_empty(), "Çocuğun 25 m'sinde hedef yok")
	# Oyuncu açıkta atlıyken noktaya 17 m'den yakınsa vurulur.
	var pl := {"x": 0.0, "z": 0.0, "mounted": true, "open": true}
	assert_eq(WeatherStorm.strike_pick([], 16.0, 0.0, {"player": pl}).get("kind"), "player", "Açıkta atlı 16 m")
	assert_true(WeatherStorm.strike_pick([], 18.0, 0.0, {"player": pl}).is_empty(), "18 m'de vurulmaz")
	assert_true(WeatherStorm.strike_pick([], 5.0, 0.0, {"player": pl, "difficulty": "story"}).is_empty(), "Hikâye'de oyuncu hedef olmaz")
	# Vuruşun etkisi: Can en çok %35, taban 1; ıslak keçe tutuşmaz, kuru fırtınada kuru keçe tutuşur.
	assert_almost(WeatherStorm.strike_hp(100.0, 100.0), 65.0, 1e-12)
	assert_almost(WeatherStorm.strike_hp(10.0, 100.0), 1.0, 1e-12, "Can 1'in altına inmez")
	assert_false(bool(WeatherStorm.strike_effect({"kind": "structure"}, 0.6, true).get("ignite")), "Islak keçe tutuşmaz")
	assert_true(bool(WeatherStorm.strike_effect({"kind": "structure"}, 0.1, true).get("ignite")), "Kuru fırtınada kuru keçe tutuşur")
	assert_false(bool(WeatherStorm.strike_effect({"kind": "structure"}, 0.1, false).get("ignite")), "Yağmurlu fırtınada tutuşmaz")
	# Serbest Gez'in yakın düşüşü kameranın baktığı yönde 30–70 m.
	var pt := WeatherStorm.near_point(0.0, 0.0, 0.0, -1.0, 0.5, 0.5)
	assert_almost(pt[0], 0.0, 1e-9)
	assert_almost(pt[1], -50.0, 1e-9, "Kadrajın ortasında 50 m ileride")


func test_thunder_delay_and_bands() -> void:
	assert_almost(WeatherStorm.thunder_delay(100.0), 0.2915, 0.001, "100 m 0,3 sn")
	assert_almost(WeatherStorm.thunder_delay(3000.0), 8.746, 0.001, "3 km 8,7 sn")
	assert_almost(WeatherStorm.thunder_delay(10000.0), 29.15, 0.01, "10 km 29 sn")
	assert_eq(WeatherStorm.thunder_band(600.0), "thunder_crack")
	assert_eq(WeatherStorm.thunder_band(601.0), "thunder")
	assert_eq(WeatherStorm.thunder_band(3000.0), "thunder")
	assert_eq(WeatherStorm.thunder_band(9000.0), "thunder_far")
	assert_eq(WeatherStorm.thunder_band(10001.0), "", "10 km ötesi duyulmaz")


func test_front_kind_and_signs_match_prototype() -> void:
	for c: Dictionary in _fx["fronts"]:
		var seg := WeatherSegment.make(WeatherData.index_of(str(c["seg"]["type"])), 0.0, 1.0,
			WeatherSegment.SRC_NAMES.find(str(c["seg"]["src"])))
		var before := WeatherSegment.make(WeatherData.index_of(str(c["before"]["type"])), -1.0, 0.0, WeatherSegment.SRC_SIM)
		var want: Variant = c["kind"]
		assert_eq(WeatherSigns.front_kind(seg, before), "" if want == null else str(want), "cephe %s → %s" % [c["before"]["type"], c["seg"]["type"]])
	var p := WeatherPlanner.new({"climate": "orkhon", "season": "summer", "seed": 12345, "zone": "longcheng"})
	p.start(100.0)
	var st := WeatherSigns.State.new()
	var want_list: Array = _fx["signs"]
	var wi := 0
	var h := 100.0
	var bad := 0
	while h < 172.0:
		p.advance(h)
		for diff_k: float in [1.0, 1.5]:
			WeatherSigns.signs_for(p.plan, h, diff_k, false, -INF, p.prev, "", 0.0, st)
			if st.n > 0 or st.clearing:
				if wi >= want_list.size():
					bad += 1
					continue
				var w: Dictionary = want_list[wi]
				wi += 1
				var ok := absf(float(w["h"]) - h) < 1e-9 and absf(float(w["diffK"]) - diff_k) < 1e-9 and st.n == (w["list"] as Array).size()
				ok = ok and st.hud == ("" if w["hud"] == null else str(w["hud"])) and st.clearing == bool(w["clearing"])
				for i in mini(st.n, (w["list"] as Array).size()):
					var e: Array = w["list"][i]
					ok = ok and st.list[i].id == str(e[0]) and st.list[i].ch == str(e[1]) and st.list[i].type == str(e[2]) and absf(st.list[i].in_h - float(e[3])) < 1e-9
				if not ok:
					bad += 1
					if bad <= 3:
						fail("işaret %.2f ×%.1f: %d kanal, hud %s ≠ %s" % [h, diff_k, st.n, st.hud, JSON.stringify(w)])
		h += 0.25
	assert_eq(wi, want_list.size(), "işaret satırı sayısı")
	assert_eq(bad, 0, "İşaretler prototiple aynı")
	var q := WeatherPlanner.new({"climate": "orkhon", "season": "summer", "seed": 12345, "zone": "longcheng"})
	q.start(100.0)
	for w: Dictionary in _fx["sky"]:
		q.advance(float(w["h"]))
		var r := WeatherSigns.sky_read(q.plan, float(w["h"]), 6.0)
		assert_eq(r["kind"], w["kind"], "gök okuma %.1f" % float(w["h"]))
		assert_eq(r["type"], "" if w["type"] == null else str(w["type"]))


func test_w4_heavy_weather_is_read_an_hour_ahead_on_three_channels() -> void:
	# Kamp yazında 40 gün: sev ≥3 her ıslak ya da fırtına cephesi varmadan ≥1 sa önce zemin ya da ışık, ses ve HUD kanalı açar.
	var p := WeatherPlanner.new({"climate": "orkhon", "season": "camp_summer", "seed": 2026, "zone": "tanhu_camp"})
	p.start(24.0)
	var st := WeatherSigns.State.new()
	var checked := 0
	var seen := {}
	var h := 24.0
	while h < 24.0 + 40.0 * 24.0:
		p.advance(h)
		WeatherSigns.signs_for(p.plan, h, 1.0, false, -INF, p.prev, "", 0.0, st)
		var channels := {}
		for i in st.n:
			var e := st.list[i]
			if WeatherData.sev[WeatherData.index_of(e.type)] >= 3 and e.in_h >= 0.99 and e.in_h <= 1.0:
				channels[e.ch] = true
				seen[e.t0] = true
		if not channels.is_empty():
			checked += 1
			assert_true(channels.has("sound"), "Ses kanalı zorunlu (%.2f)" % h)
			assert_true(channels.has("hud"), "HUD kanalı (%.2f)" % h)
			assert_true(channels.has("ground") or channels.has("light"), "Zemin ya da ışık kanalı (%.2f)" % h)
		h += 0.01
	assert_true(seen.size() >= 3, "40 günde ≥3 ağır cephe işaretlendi (%d)" % seen.size())
