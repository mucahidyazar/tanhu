extends TestCase
## Hava planlayıcısı (WeatherRng, WeatherData, WeatherPlanner; weather.md §4, §5, §15 W1–W5; godot.md §8.2): prototipin altın değer
## fikstürüyle (tests/fixtures/weather_core.json, tools/proto_fixtures/weather.mjs) bit bit.
##   - Tohum: hash32, strHash ve mulberry32 prototiple tam eşit (32 bitlik maske).
##   - Gün içi eğriler, hedef paylar ve tür vektörleri (veri dönüşümü) 1e-12.
##   - Plan dizileri: tür, kaynak, cephe ve hücre tam eşit; sınırlar 1e-9 (fikstürün ağırlığıyla).
##   - Karışım, varış lütfu, kilit yığını, satır ve dışlama değişimi, kayıt: prototiple aynı.
##   - Kısa benzetim payları ve günde bölüm sayısı 1e-9.
##   - Kurallar (W3, W4): süre aralığı, sis 10:00'da biter, dolu yalnız fırtına içinde, tipi kardan, dışlanan tür hiç çıkmaz, kurudan
##     ıslağa hazırlık; gömülü ağırlıklar prototipin ayarıyla 1e-9 (göreli).

const FIXTURE := "res://tests/fixtures/weather_core.json"

static var _fx: Dictionary = {}


func before_each() -> void:
	if _fx.is_empty():
		_fx = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))


func _weights(climate: String, season: String, exclude: Array) -> Dictionary:
	return (_fx["weights"] as Dictionary).get(WeatherData.weight_key(climate, season, PackedStringArray(exclude)), {})


func _planner(c: Dictionary) -> WeatherPlanner:
	var ex: Array = c.get("exclude", [])
	return WeatherPlanner.new({"climate": c["climate"], "season": c["season"], "exclude": ex, "seed": int(c["seed"]), "zone": c["zone"],
		"weights": _weights(c["climate"], c["season"], ex)})


static func _num(v: Variant) -> float:
	if v is String:
		return INF if v == "inf" else -INF if v == "-inf" else NAN
	return float(v) if v != null else INF


# --- Tohum ------------------------------------------------------------------------------------------------------------

func test_rng_matches_prototype_bit_for_bit() -> void:
	var rng: Dictionary = _fx["rng"]
	for zone: String in rng["str_hash"]:
		assert_eq(WeatherRng.str_hash(zone), int(rng["str_hash"][zone]), "strHash(%s)" % zone)
	for row: Array in rng["hash32"]:
		assert_eq(WeatherRng.hash32(int(row[0]), int(row[1]), int(row[2]), int(row[3])), int(row[4]), "hash32%s" % str(row.slice(0, 4)))
	for m: Dictionary in rng["mulberry"]:
		var r := WeatherRng.new(int(m["seed"]))
		for v: Variant in m["values"]:
			# Değer k / 2³² tamdır; Godot'nun JSON okuyucusu son basamakta şaşabildiği için k karşılaştırılır.
			assert_eq(int(r.next() * WeatherRng.TWO32), int(roundf(float(v) * WeatherRng.TWO32)), "mulberry32(%d)" % int(m["seed"]))
	assert_eq(WeatherRng.js_round(2.5), 3.0)
	assert_eq(WeatherRng.js_round(-2.5), -2.0, "JS Math.round: yarım +∞'a")
	assert_eq(WeatherRng.imul(0xFFFFFFFF, 0xFFFFFFFF), 1, "imul taşmaz")


# --- Veri -------------------------------------------------------------------------------------------------------------

func test_type_order_and_vectors_match_prototype() -> void:
	assert_eq(WeatherData.ids(), PackedStringArray(_fx["type_ids"]), "Tür sırası prototipin TYPE_IDS'i")
	assert_eq(WeatherData.count(), 18, "17 tür ve Kara Boran")
	var params: Dictionary = _fx["params"]
	for key: String in params:
		var parts := key.split(":")
		var p := WeatherData.params_of(WeatherData.index_of(parts[0]), parts.size() > 1)
		var want: Dictionary = params[key]
		var js_keys := ["cloud", "cover", "coverSky", "shadowK", "cloudSpeedK", "dark", "sunK", "hemiK", "expK", "fogNearK", "fogFarK",
			"fogMix", "sat", "con", "rain", "snow", "hail", "dust", "points", "splashes", "wind", "gust", "vis", "mask", "wetGround",
			"wetFelt", "snowRate", "storm", "fogFarAbs"]
		for i in js_keys.size():
			var w := _num(want[js_keys[i]])
			if is_inf(w):
				assert_true(is_inf(p[i]), "%s.%s sınırsız" % [key, js_keys[i]])
			else:
				assert_almost(p[i], w, 1e-12, "%s.%s" % [key, js_keys[i]])
		for c in 3:
			assert_almost(p[WeatherData.P_TONE_R + c], float(want["tone"][c]), 1e-12, "%s ton" % key)
		if want["fogTint"] != null:
			for c in 3:
				assert_almost(p[WeatherData.P_TINT_R + c], float(want["fogTint"][c]), 1e-12, "%s sis rengi" % key)
		assert_eq(p[WeatherData.P_HAS_TINT] > 0.5, want["fogTint"] != null, "%s sis rengi var mı" % key)


func test_curves_and_targets_match_prototype() -> void:
	for name: String in _fx["curves"]:
		var want: Array = _fx["curves"][name]
		var got := WeatherData.curve(name)
		assert_eq(got.size(), 24)
		for h in 24:
			assert_almost(got[h], float(want[h]), 1e-12, "eğri %s[%d]" % [name, h])
	var targets: Dictionary = _fx["targets"]
	assert_true(targets.size() >= 41, "41 satır (38 ve kampın üç K67 satırı) ve dışlamalı satırlar")
	for key: String in targets:
		var parts := key.split(":")
		var ex := PackedStringArray(parts[2].split(",", false))
		var got := WeatherData.target_shares(parts[0], parts[1], ex)
		var want: Dictionary = targets[key]
		assert_eq(got.keys(), want.keys(), "%s türleri ve sırası" % key)
		for id: String in want:
			assert_almost(float(got.get(id, -1.0)), float(want[id]), 1e-12, "%s %s" % [key, id])


func test_embedded_weights_match_prototype_calibration() -> void:
	var table := WeatherData.weights_table()
	assert_false(table.is_empty(), "data/weather/weights.json var (tools/weather_calibrate.gd)")
	var weights: Dictionary = _fx["weights"]
	var emb: Dictionary = table.get("weights", {})
	for key: String in weights:
		assert_true(emb.has(key), "gömülü ağırlık %s" % key)
		var got: Dictionary = emb.get(key, {})
		var want: Dictionary = weights[key]
		assert_eq(got.keys(), want.keys(), "%s türleri" % key)
		for id: String in want:
			var w := float(want[id])
			assert_true(absf(float(got.get(id, 0.0)) - w) <= 1e-9 * absf(w), "%s %s: %s ≠ %s" % [key, id, str(got.get(id)), str(w)])


# --- Plan -------------------------------------------------------------------------------------------------------------

## Bölümleri saat saat ilerleyerek toplar (atılanlar dahil; fikstürün chain'i).
static func _chain(p: WeatherPlanner, from: float, to: float) -> Array[WeatherSegment]:
	var out: Array[WeatherSegment] = []
	var last := -INF
	var h := from
	while h <= to:
		p.advance(h)
		for s in p.plan:
			if s.t0 > last and s.t0 <= h + 12.0:
				out.append(s)
				last = s.t0
		h += 0.5
	return out


func _same_segment(got: WeatherSegment, want: Dictionary, label: String) -> bool:
	var ok := String(got.type_id()) == str(want["type"]) and got.src_name() == str(want["src"])
	ok = ok and absf(got.t0 - float(want["t0"])) <= 1e-9 and absf(got.t1 - float(want["t1"])) <= 1e-9
	ok = ok and got.seed == int(want["seed"]) and got.g == int(want["g"])
	var fr: Variant = want["front"]
	if fr == null:
		ok = ok and got.front_kind == WeatherSegment.FRONT_NONE
	else:
		var other := str(fr.get("to", fr.get("from", "")))
		ok = ok and got.front_kind == (WeatherSegment.FRONT_BUILD if fr["kind"] == "build" else WeatherSegment.FRONT_CLEAR)
		ok = ok and String(WeatherData.id_of(got.front_type)) == other
	var cell: Variant = want["cell"]
	ok = ok and got.has_cell == (cell != null)
	if cell != null:
		ok = ok and absf(got.cell0 - float(cell[0])) <= 1e-9 and absf(got.cell1 - float(cell[1])) <= 1e-9
	if not ok:
		fail("%s: %s ≠ %s" % [label, JSON.stringify(got.to_dict()), JSON.stringify(want)])
	return ok


func test_plans_match_prototype() -> void:
	for c: Dictionary in _fx["plans"]:
		var p := _planner(c)
		p.start(float(c["from"]))
		var got := _chain(p, float(c["from"]), float(c["from"]) + float(c["hours"]))
		var want: Array = c["plan"]
		var label := "%s:%s seed %d" % [c["climate"], c["season"], int(c["seed"])]
		assert_eq(got.size(), want.size(), "%s bölüm sayısı" % label)
		for i in mini(got.size(), want.size()):
			if not _same_segment(got[i], want[i], "%s #%d" % [label, i]):
				break


func test_mix_locks_arrival_rows_and_save_match_prototype() -> void:
	for c: Dictionary in _fx["mix"]:
		var p := _planner(c)
		match str(c["id"]):
			"blend":
				p.start(float(c["from"]))
				for sample: Array in c["samples"]:
					var h := float(sample[0])
					_check_mix(p.advance(h).at(h), sample[1], "karışım %.4f" % h)
			"arrival":
				p.start(float(c["from"]))
				p.arrive(float(c["arrive"][0]), float(c["arrive"][1]))
				for sample: Array in c["samples"]:
					var h := float(sample[0])
					_check_mix(p.advance(h).at(h), sample[1], "varış %.4f" % h)
			"locks":
				_check_locks(p, c["events"])
			"rows":
				p.start(float(c["from"]))
				p.advance(28110.0)
				_check_briefs(p, c["before"], "satır öncesi")
				p.set_exclude(PackedStringArray(), 28110.0)
				_check_briefs(p, c["afterExclude"], "dışlama kalkınca şimdiki grup kalır, sonrası yeni ağırlıkla")
				p.set_row("orkhon", "camp_summer", 28111.0)
				_check_briefs(p, c["afterRow"], "mevsim değişince şimdiki grup kalır")
			"save":
				var q := _planner(c)
				var saved: Dictionary = (c["saved"] as Dictionary).duplicate(true)
				saved["at"] = float(c["at"])
				q.from_dict(saved)
				var got := _chain(q, float(c["at"]), 300.0)
				var want: Array = c["cont"]
				assert_eq(got.size(), want.size(), "kayıttan devam: bölüm sayısı")
				for i in mini(got.size(), want.size()):
					if not _same_segment(got[i], want[i], "kayıttan devam #%d" % i):
						break
				# Godot'nun kendi kaydı da aynı devamı verir.
				p.start(float(c["from"]))
				p.advance(float(c["at"]))
				var mine := p.to_dict()
				mine["at"] = float(c["at"])
				var r := _planner(c)
				r.from_dict(JSON.parse_string(JSON.stringify(mine)))
				var again := _chain(r, float(c["at"]), 300.0)
				assert_eq(again.size(), want.size(), "Godot kaydı: bölüm sayısı")
				for i in mini(again.size(), want.size()):
					if not _same_segment(again[i], want[i], "Godot kaydı #%d" % i):
						break


func _check_mix(m: WeatherPlanner.Mix, want: Dictionary, label: String) -> void:
	var ok := String(m.a.type_id()) == str(want["a"]) and String(m.b.type_id()) == str(want["b"])
	ok = ok and absf(m.k - float(want["k"])) <= 1e-9 and absf(m.seg.t0 - _num(want["seg_t0"])) <= 1e-9
	ok = ok and (m.lock.id if m.lock else null) == want["lock"]
	if not ok:
		fail("%s: a %s b %s k %.6f t0 %s kilit %s ≠ %s" % [label, m.a.type_id(), m.b.type_id(), m.k, str(m.seg.t0), m.lock.id if m.lock else "-", JSON.stringify(want)])


## Planın «tür|t0|t1|src» dizgeleri prototipinkiyle (sayılar 1e-9).
func _check_briefs(p: WeatherPlanner, want: Array, label: String) -> void:
	if p.plan.size() != want.size():
		fail("%s: %d bölüm ≠ %d" % [label, p.plan.size(), want.size()])
		return
	for i in want.size():
		var parts := str(want[i]).split("|")
		var s := p.plan[i]
		var ok := String(s.type_id()) == parts[0] and s.src_name() == parts[3]
		ok = ok and _close(s.t0, _parse_js(parts[1])) and _close(s.t1, _parse_js(parts[2]))
		if not ok:
			fail("%s #%d: %s ≠ %s" % [label, i, s.brief(), want[i]])
			return


static func _parse_js(text: String) -> float:
	if text == "Infinity":
		return INF
	if text == "-Infinity":
		return -INF
	return text.to_float()


static func _close(a: float, b: float) -> bool:
	if is_inf(a) or is_inf(b):
		return a == b
	return absf(a - b) <= 1e-9


func _check_locks(p: WeatherPlanner, events: Array) -> void:
	for ev: Array in events:
		var h := float(ev[0])
		var what := str(ev[1])
		match what:
			"start":
				p.start(h)
			"lock":
				p.now = h
				p.lock("a1_last_night", {"type": "snow", "params": {"snow": 0.35}, "keys": [{"k": 0, "params": {"fog_far_abs": 1400, "cloud": 0.3, "wind": 1.5}},
					{"k": 0.66, "params": {"wind": 1.5}}, {"k": 1, "params": {"fog_far_abs": 140, "cloud": 0.9, "wind": 6}}], "blend": 6, "at": h})
			"progress":
				p.progress("a1_last_night", 0.5)
			"kara_boran":
				p.now = 1003.0
				p.lock("a1_kara_boran", {"type": "kara_boran", "blend": 6, "at": 1003.0})
			"release_top":
				p.release("a1_kara_boran", 8.0, 1004.0)
			"release_all":
				p.release("a1_last_night", 6.0, 1005.0)
		_check_mix(p.advance(h).at(h), ev[2], "kilit «%s» %.3f" % [what, h])
		_check_briefs(p, ev[3], "kilit «%s»: plan" % what)


# --- Benzetim ---------------------------------------------------------------------------------------------------------

func test_short_simulation_matches_prototype() -> void:
	for c: Dictionary in _fx["sims"]:
		var ex := PackedStringArray(c["exclude"])
		var r := WeatherPlanner.simulate(c["climate"], c["season"], ex, _weights(c["climate"], c["season"], c["exclude"]), int(c["days"]), int(c["seed"]))
		var label := "%s:%s" % [c["climate"], c["season"]]
		assert_almost(float(r["per_day"]), float(c["per_day"]), 1e-12, "%s günde bölüm" % label)
		var want: Dictionary = c["share"]
		assert_eq((r["share"] as Dictionary).size(), want.size(), "%s tür sayısı" % label)
		for id: String in want:
			assert_almost(float((r["share"] as Dictionary).get(id, -1.0)), float(want[id]), 1e-9, "%s pay %s" % [label, id])


# --- Kurallar (W3, W4) ------------------------------------------------------------------------------------------------

func test_rules_durations_fog_hail_blizzard_exclude_and_fronts() -> void:
	var cases := [["orkhon", "camp_spring", []], ["orkhon", "summer", []], ["hexi", "winter", ["heavy_snow", "blizzard"]],
		["steppe_south", "winter", []], ["gobi", "spring", []], ["kerulen", "winter", []]]
	for c: Array in cases:
		var p := WeatherPlanner.new({"climate": c[0], "season": c[1], "exclude": c[2], "seed": 4711, "zone": "rules"})
		p.start(48.0)
		var segs := _chain(p, 48.0, 48.0 + 40.0 * 24.0)
		var label := "%s:%s" % [c[0], c[1]]
		assert_true(segs.size() > 80, "%s: 40 günde %d bölüm" % [label, segs.size()])
		for i in segs.size():
			var s := segs[i]
			var id := String(s.type_id())
			var before: WeatherSegment = segs[i - 1] if i > 0 else null
			if (c[2] as Array).has(id):
				fail("%s: dışlanan %s çıktı" % [label, id])
			if id == "kara_boran":
				fail("%s: Kara Boran yalnız kilitle gelir" % label)
			if id == "hail" and not (s.has_cell and before and String(before.type_id()) == "thunderstorm"):
				fail("%s: dolu yalnız fırtınanın içinde" % label)
			if id == "fog":
				var h0 := WeatherPlanner.hod(s.t0)
				assert_true(h0 >= 21.0 or h0 < 10.0, "%s: sis 21:00–09:59'da başlar (%.2f)" % [label, h0])
				var end_h := WeatherPlanner.hod(s.t1)
				assert_true(s.t1 - s.t0 <= 13.0 and (end_h <= 10.0 + 1e-9 or end_h >= 21.0), "%s: sis 10:00'da biter" % label)
			if id == "blizzard" and before:
				assert_true(String(before.type_id()) in ["snow", "heavy_snow"], "%s: tipi kardan sonra (%s)" % [label, before.type_id()])
			if s.src == WeatherSegment.SRC_SIM and not s.has_cell and id != "fog":
				var d := p.dur_of(s.type)
				var len := s.t1 - s.t0
				assert_true(len >= d[0] - 0.05 - 1e-9 and len <= d[1] + 0.05 + 1e-9, "%s: %s süresi %.2f ∉ [%.2f, %.2f]" % [label, id, len, d[0], d[1]])
			# W4: kurudan ıslağa ya da fırtınaya her geçiş hazırlıklıdır (önündeki bölüm hazırlık ya da aynı hücrenin parçası).
			if before and WeatherData.group[s.type] in [WeatherData.GROUP_WET, WeatherData.GROUP_STORM] and s.src == WeatherSegment.SRC_SIM \
					and WeatherData.group[before.type] == WeatherData.GROUP_DRY and before.src != WeatherSegment.SRC_BUILD and not before.has_cell:
				fail("%s: %s kurudan hazırlıksız geldi (%s)" % [label, id, before.type_id()])


func test_determinism_and_fixed_anchor() -> void:
	var opts := {"climate": "orkhon", "season": "summer", "seed": 12345, "zone": "longcheng"}
	var a := _chain(WeatherPlanner.new(opts).start(100.0), 100.0, 100.0 + 30.0 * 24.0)
	var b := _chain(WeatherPlanner.new(opts).start(100.0), 100.0, 100.0 + 30.0 * 24.0)
	assert_true(a.size() > 150, "30 günde %d bölüm" % a.size())
	var same := a.size() == b.size()
	for i in mini(a.size(), b.size()):
		same = same and a[i].brief() == b[i].brief()
	assert_true(same, "Aynı tohum, dünya ve saat aynı plan")
	# Sabit çapa: aynı gün içinde iki başlangıç aynı zinciri verir (24 sa içinde dönüş aynı plan, §5.7).
	var p1 := WeatherPlanner.new(opts).start(245.0)
	var p2 := WeatherPlanner.new(opts).start(251.5)
	p1.advance(251.5)
	assert_eq(p1.plan[0].brief(), p2.plan[0].brief(), "Sabit çapadan aynı zincir")
	var other := opts.duplicate()
	other["seed"] = 54321
	var c := _chain(WeatherPlanner.new(other).start(100.0), 100.0, 100.0 + 30.0 * 24.0)
	var differs := c.size() != a.size()
	for i in mini(a.size(), c.size()):
		differs = differs or a[i].brief() != c[i].brief()
	assert_true(differs, "Başka tohum başka hava")


func test_lock_holds_and_resumes_from_lock_type() -> void:
	var p := WeatherPlanner.new({"climate": "hexi", "season": "winter", "exclude": ["heavy_snow", "blizzard"], "seed": 9, "zone": "hexi_winter"})
	p.start(500.0)
	p.lock("a1_kara_boran", {"type": "kara_boran", "until": 503.0, "at": 500.5})
	var m := p.advance(501.0).at(501.0)
	assert_eq(String(m.b.type_id()), "kara_boran", "Kilit türü yazar")
	assert_eq(m.lock.id, "a1_kara_boran")
	assert_almost(m.k, 1.0, 1e-9, "6 sn'lik karışım biter")
	p.advance(503.0)
	assert_false(p.has_lock("a1_kara_boran"), "until'de kilit kalkar")
	assert_eq(String(p.prev.type_id()), "kara_boran", "Karışımın eski ucu kilidin türü (kilit kalkınca kilidin türünden devam, §5.4)")
	assert_almost(p.plan[0].t0, 503.0, 1e-9, "Plan kilidin bittiği saatten sürer")
	assert_true(p.plan[p.plan.size() - 1].t1 >= 503.0 + WeatherPlanner.HORIZON_H, "Plan yine 12 sa ileride")
	assert_almost(p.plan[0].blend_s, 6.0, 1e-9, "Kilidin bırakma karışımı")
	# Kardan bırakılan kilit çözülmeyle (kapalı) sürer.
	var q := WeatherPlanner.new({"climate": "hexi", "season": "winter", "exclude": ["heavy_snow", "blizzard"], "seed": 9, "zone": "hexi_winter"})
	q.start(500.0)
	q.lock("a1_sentence", {"type": "snow", "until": 502.0, "at": 500.5})
	q.advance(502.0)
	assert_eq(q.plan[0].src, WeatherSegment.SRC_CLEAR, "Kardan sonra çözülme bölümü")
	assert_true(String(q.plan[0].type_id()) in ["overcast", "cloud"], "Çözülme kapalı (ya da sağanaklı satırda bulut)")
