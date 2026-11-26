extends TestCase
## Emek yasası (Labour; K21, K50, K80, K83; structures.md §2.4, d2/labour-model.json v3): inşaat eğrisi T(n) kullanıcının sayılarını
## tutar (Hane Yurdu 60 / 45 / 33,75 dk), karışık ekipte n ağırlık toplamıdır, el ve katsayı tavanı, söküm ve onarım aynı eğriden;
## tezgâhta eff kalır; taşıma, çarpanlar ve günlük emek prototipin fikstürüyle (tests/fixtures/labour.json) birebir aynıdır. Beklenen
## inşaat değerleri belgedendir: değişen kural (T(n)) fikstüre girmez (K29).

const ProtoFixture := preload("res://tests/support/proto_fixture.gd")
const MODEL := "../docs/design/d2/labour-model.json"

## Hane Yurdu 1–8 el, gerçek dk (structures.md §2.4 «Yurdun ekip çizelgesi»; K50).
const HANE := [60.0, 45.0, 33.75, 25.3, 19.0, 14.2, 10.7, 8.0]
## Belgedeki tabloların yuvarlaması: bir ondalık 0,05, iki ondalık 0,005.
const ROUND_1 := 0.051
const ROUND_2 := 0.0051

var _model_cache := {}


func before_each() -> void:
	Labour.reset_cache()


## d2/labour-model.json v3 (proje klasörünün yanındaki docs).
func _model() -> Dictionary:
	if _model_cache.is_empty():
		var path := ProjectSettings.globalize_path("res://").path_join(MODEL).simplify_path()
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		assert_true(parsed is Dictionary, "d2/labour-model.json okunamadı: %s" % path)
		_model_cache = parsed if parsed is Dictionary else {}
	return _model_cache


static func _hands(n: int, role: String = "hand") -> Array:
	var out: Array = []
	for i in n:
		out.append({"id": "%s%d" % [role, i], "role": role})
	return out


func _real(game_min: float) -> float:
	return Labour.real_minutes(game_min)


func test_curve_holds_the_users_numbers() -> void:
	# K50: «1 kişi 60 dakikada, 2 kişi 45, 3 kişi 33,75: her kişi %25 hızlandırır».
	assert_almost(Labour.build_minutes("yurt", 1.0), 60.0, 1e-9, "Tek el Hane Yurdu 60 gerçek dk (1.440 İD)")
	assert_almost(Labour.build_minutes("yurt", 2.0), 45.0, 1e-9, "İki el 45 dk")
	assert_almost(Labour.build_minutes("yurt", 3.0), 33.75, 1e-9, "Üç el 33,75 dk")
	for n in range(1, 9):
		assert_almost(Labour.build_minutes("yurt", n), HANE[n - 1], ROUND_1, "Hane Yurdu %d el" % n)
		assert_almost(Labour.t_of(60.0, n), 60.0 * pow(0.75, n - 1), 1e-9, "T(n) = taban × 0,75^(n − 1), n = %d" % n)
		if n > 1:
			assert_almost(Labour.build_minutes("yurt", n) / Labour.build_minutes("yurt", n - 1), 0.75, 1e-12, "Her yeni el süreyi %25 kısaltır")
	assert_almost(Labour.k_build(9.0), Labour.k_build(8.0), 1e-12, "Katsayı 8 ağırlıkta durur")
	assert_almost(Labour.t_of(60.0, 12.0), Labour.t_of(60.0, 8.0), 1e-12, "12 el 8 el kadar sürer")
	assert_almost(Labour.k_build(0.75), 0.75, 1e-12, "Tek başına çırak 0,75 hızla (doğrusal)")
	assert_almost(Labour.k_build(0.5), 0.5, 1e-12, "Tek başına yaşlı 0,5 hızla")
	assert_eq(Labour.k_build(0.0), 0.0, "Ekip yoksa katsayı 0")
	assert_eq(Labour.t_of(60.0, 0.0), INF, "Ekipsiz yapı bitmez")


func test_k_table_and_per_hand_match_the_model() -> void:
	var build: Dictionary = (_model().get("law", {}) as Dictionary).get("build", {})
	var table: Array = build.get("k_table", [])
	assert_eq(table.size(), 15, "k_table'ın 15 satırı")
	for row: Array in table:
		assert_almost(Labour.k_build(float(row[0])), float(row[1]), 5e-5, "k(%s)" % row[0])
		assert_almost(Labour.build_minutes("yurt", float(row[0])), 60.0 / float(row[1]), 0.01, "Hane Yurdu %s ağırlıkla" % row[0])
	var per_hand: Dictionary = (_model().get("crew", {}) as Dictionary).get("perHand", {})
	for n: String in per_hand:
		assert_almost(Labour.per_hand(float(n)), float(per_hand[n]), 0.005, "%s elin el başına verimi" % n)
	assert_almost(Labour.per_hand(12.0), 0.62, 0.005, "Otağ'da 12 el 0,62")
	assert_almost(Labour.site_day(3.0), 42.7, 0.05, "3 ellik şantiye günde 42,7 İS işler")
	assert_almost(Labour.site_day(8.0), 179.8, 0.05, "8 ellik şantiye günde 179,8 İS işler")
	# K80'in örneği: dört ayrı yurtta tek başına dört el saatte 4 yurt, aynı dört el tek yurtta 2,4, sekiz el tek yurtta 7,5 yurt kurar.
	assert_almost(4.0 * 60.0 / Labour.build_minutes("yurt", 1.0), 4.0, 1e-9)
	assert_almost(60.0 / Labour.build_minutes("yurt", 4.0), 2.4, 0.03)
	assert_almost(60.0 / Labour.build_minutes("yurt", 8.0), 7.5, 0.01)


func test_sizes_crew_cap_and_coefficient_cap() -> void:
	var sizes: Dictionary = _model().get("sizes", {})
	for size: String in ["s", "m", "l"]:
		var row: Dictionary = sizes[size]
		var kind := str(row["kind"]) if row["kind"] is String else str((row["kind"] as Array)[0])
		assert_almost(Labour.structure_work(kind), float(row["one"]), 1e-6, "%s: tek el emeği" % kind)
		assert_eq(Labour.crew_max(kind), float(row["crewMax"]), "%s: el tavanı" % kind)
		assert_almost(Labour.build_minutes(kind, 1.0), float(row["baseRealMin"]), 1e-9, "%s: taban" % kind)
		var real: Dictionary = row["realMin"]
		for n: String in real:
			assert_almost(Labour.build_minutes(kind, float(n)), float(real[n]), ROUND_2, "%s %s el" % [kind, n])
	# Küçük Yurt en çok 6 el alır: sekiz el çağrılsa da altısı çalışır (5,7 dk); Otağ 12 el alır ama katsayı 8'de durur (20,0 dk).
	assert_almost(Labour.crew_minutes("yurt_small", _hands(8), {"night": "day"}), Labour.crew_minutes("yurt_small", _hands(6), {"night": "day"}), 1e-9, "Küçük Yurt'ta 7. ve 8. el sayılmaz")
	assert_almost(_real(Labour.crew_minutes("yurt_small", _hands(8), {"night": "day"})), 5.7, ROUND_1, "Küçük Yurt 6 elle 5,7 dk")
	assert_almost(_real(Labour.crew_minutes("otag", _hands(12), {"night": "day"})), 20.0, 0.05, "Otağ 12 elle 20,0 dk")
	assert_almost(_real(Labour.crew_minutes("otag", _hands(12), {"night": "day"})), _real(Labour.crew_minutes("otag", _hands(8), {"night": "day"})), 1e-9, "Otağ'ın 9.–12. elleri taşır, katsayıya girmez")
	assert_almost(_real(Labour.crew_minutes("yurt", _hands(9), {"night": "day"})), 8.0, ROUND_1, "Hane Yurdu'nda dokuzuncu el sayılmaz")
	var crew := Labour.crew_on({"max": Labour.crew_max("otag")}, _hands(12))
	assert_eq(crew["heads"], 12.0, "Otağ 12 baş alır")
	assert_eq(crew["W"], 12.0)


func test_mixed_crews_use_the_weight_sum() -> void:
	# K50: karışık ekipte n ağırlık toplamıdır (usta ve el 1, çırak 0,75, Çocuk 0,5); Çocuk eşikte (y_esik) ve ocakta (y_ocak) sayılmaz.
	var mixed: Dictionary = (_model().get("crew", {}) as Dictionary).get("mixedRealMin", {})
	var day := {"night": "day"}
	var usta := {"id": "usta", "role": "usta"}
	var child := {"id": "child", "role": "child"}
	var oktar := {"id": "oktar", "role": "usta", "crafts": ["cr_carpenter"]}
	var erka := {"id": "erka", "role": "usta", "crafts": ["cr_felter"]}
	var dengiz := {"id": "dengiz", "role": "apprentice"}
	var camp3 := [oktar, erka, dengiz]
	var mete := {"id": "mete", "role": "mete"}
	var cases := [
		["master+child", [usta, child], {}, {}, 52.19],
		["master+apprentice", [usta, dengiz], {}, {}, 48.36],
		["camp3", camp3, {}, {}, 36.27],
		["camp3+child_ember", camp3 + [child], {}, {"ember": true}, 31.2],
		["kislak_nanay+2", [{"id": "nanay", "role": "usta"}] + _hands(2), {}, {}, 33.75],
		["mete_quick_raise", [mete], {"mods": {"buildTime": 0.7}}, {}, 42.0],
		["mete+first_ten_8", [mete] + _hands(7), {}, {}, 8.01],
		["mete+first_ten_8_quick_raise", [mete] + _hands(7), {"mods": {"buildTime": 0.7}}, {}, 5.61],
		["laden_household_3", _hands(3), {}, {}, 33.75],
		["raw_yurt_1", [oktar], {}, {"raw": true}, 130.0],
		["raw_yurt_3", [oktar] + _hands(2), {}, {"raw": true}, 73.13],
		["raw_yurt_8", [oktar] + _hands(7), {}, {"raw": true}, 17.35],
	]
	for c: Array in cases:
		var env: Dictionary = day.duplicate()
		env.merge(c[2], true)
		var got := _real(Labour.crew_minutes("yurt", c[1], env, c[3]))
		# Belgedeki değer bir ya da iki ondalıkla yuvarlanmıştır (31,2; 52,19).
		var tol := ROUND_2 if absf(float(c[4]) * 10.0 - roundf(float(c[4]) * 10.0)) > 1e-9 else ROUND_1
		assert_almost(got, float(c[4]), tol, "%s (structures.md §2.4)" % c[0])
		assert_almost(got, float(mixed[c[0]]), tol, "%s (labour-model.json v3 crew.mixedRealMin)" % c[0])
	# camp3 870 oyun dk, Çocuk ve közle 749 oyun dk (structures.md §2.4 «Karışık ekipler»).
	assert_almost(Labour.crew_minutes("yurt", camp3, day), 870.0, 0.5, "camp3 870 oyun dk")
	assert_almost(Labour.crew_minutes("yurt", camp3 + [child], day, {"ember": true}), 749.0, 0.5, "camp3 + Çocuk, köz yığında 749 oyun dk")
	var esik := Labour.crew_on({"max": 8, "child": false}, camp3 + [child])
	assert_almost(esik["W"], 2.75, 1e-12, "Eşikte Çocuk sayılmaz")
	assert_almost(Labour.crew_on({"max": 8}, camp3 + [child])["W"], 3.25, 1e-12, "Fiili yapan Çocuk yarım eldir")
	# Çocuk tek başına ekip kuramaz (önder kuralı); tek başına çırak 0,75 hızla çalışır ve usta sayılmaz (×0,7): 60 / 0,525 dk.
	assert_eq(Labour.crew_minutes("yurt", [child], day), INF, "Tek başına Çocuk yurt kuramaz")
	assert_almost(Labour.crew_on({"max": 8}, [dengiz])["W"], 0.75, 1e-12)
	assert_almost(_real(Labour.crew_minutes("yurt", [dengiz], day)), 60.0 / (0.75 * 0.7), 1e-9, "Tek başına çırak: k 0,75, usta yok ×0,7")


func test_raw_work_needs_its_master_and_adds_to_the_steps() -> void:
	var raw: Dictionary = (_model().get("law", {}) as Dictionary).get("rawWork", {})
	assert_almost(Labour.structure_work("yurt", {"raw": true}) - Labour.structure_work("yurt"), float(raw["yurtTotal"]), 1e-9, "Hane Yurdu ham 1.680 İD")
	assert_almost(Labour.structure_work("yurt", {"raw": true}), 3120.0, 1e-9, "Ham Hane Yurdu tek işçiyle 3.120 İD")
	# Ham kerege dülger ister: usta tarifinin ustasız yolu yoktur, adım «master» bekler.
	var kerege: Dictionary = Labour.steps_of("yurt")[2]
	assert_eq(kerege["id"], "y_kerege")
	var crew := Labour.crew_on({"max": 8, "rawRole": kerege.get("rawRole")}, _hands(3))
	var info := {}
	assert_eq(Labour.build_rate(kerege, crew, {"raw": true}, info), 0.0, "Dülgersiz ham kerege işlemez")
	assert_eq(info["reason"], "master")
	assert_eq(Labour.crew_minutes("yurt", _hands(8), {"night": "day"}, {"raw": true}), INF, "Ham yurt dülgersiz bitmez")
	assert_true(Labour.build_rate(kerege, crew, {"raw": false}) > 0.0, "Parça biçimli kerege dülger istemez")
	# Yalnız işaretli adım ham sayılır.
	assert_almost(Labour.structure_work("yurt", {"raw": {"y_uuk": true}}), 1440.0 + 480.0, 1e-9)


func test_dismantle_is_a_third_of_the_curve() -> void:
	var tables: Dictionary = (_model().get("crew", {}) as Dictionary).get("dismantleRealMin", {})
	for kind: String in ["yurt_small", "yurt", "otag", "tent"]:
		var t: Dictionary = tables[kind]
		for n: String in t:
			var got := _real(Labour.crew_minutes(kind, _hands(int(n)), {"night": "day"}, {"kind": "dismantle"}))
			assert_almost(got, float(t[n]), ROUND_2, "%s sökümü %s el" % [kind, n])
	assert_almost(_real(Labour.crew_minutes("yurt", _hands(1), {"night": "day"}, {"kind": "dismantle"})), 21.0, 1e-9, "Tek el söküm 0,35 × 60 dk")
	assert_almost(_real(Labour.crew_minutes("yurt", _hands(4), {"night": "day"}, {"kind": "dismantle"})), 8.86, ROUND_2, "Dört elle Hane Yurdu sökümü 8,9 dk")
	assert_almost(Labour.structure_work("tent", {"kind": "dismantle"}), 75.6, 1e-9, "Çadır sökümü 216 × 0,35 ≈ 76 İD")
	assert_almost(Labour.structure_work("tent_night", {"kind": "dismantle"}), 15.12, 1e-9, "Gecelik Çadır sabah Topla 15,1 İD")
	# Gecelik Çadır (K46): tek başına 108 gerçek sn, iki elle 81 sn.
	assert_almost(Labour.crew_minutes("tent_night", _hands(1), {"night": "day"}) * Labour.real_s_per_min(), 108.0, 1e-9)
	assert_almost(Labour.crew_minutes("tent_night", _hands(2), {"night": "day"}) * Labour.real_s_per_min(), 81.0, 1e-9)


func test_repair_uses_the_same_curve() -> void:
	# Gün V yaması (labour-model.json scenarios.kislak_new_yurt.dayVPatch): (129 + 146) × 0,8 × 1,25 = 275 İD, üç elle 154,7 oyun dk.
	var steps := Labour.steps_of("yurt")
	var felt: Dictionary = steps[7]
	var pull: Dictionary = steps[8]
	assert_eq([felt["id"], pull["id"]], ["y_tuurduk", "y_uzuk"])
	var work := Labour.repair_work(felt, "raise", {"burnt": true}) + Labour.repair_work(pull, "raise", {"burnt": true})
	var patch: Dictionary = (_model()["scenarios"]["kislak_new_yurt"] as Dictionary)["dayVPatch"]
	assert_almost(work, float(patch["work"]), 1e-9, "Gün V yaması 275 İD")
	var crew := Labour.crew_on({"max": 8}, [{"id": "nanay", "role": "usta"}] + _hands(2))
	var minutes := work / Labour.build_rate(felt, crew, {"kind": "repair", "night": "day"})
	assert_almost(minutes, float(patch["gameMin"]), 0.05, "Gün V yaması üç elle 154,7 oyun dk")
	# Birim canına göre: birimin emeği payı × birim canı / adım canı; yama canın eksiği kadar, yırtık 4 İD, yeniden koşan adım ×0,8.
	var unit := {"work": 146.0, "hp": 50.0}
	assert_almost(Labour.repair_work(unit, "raise", {"unit_hp": 10.0}), 146.0 * 10.0 / 50.0 * 0.8, 1e-9)
	assert_almost(Labour.repair_work(unit, "patch", {"unit_hp": 10.0, "hp": 4.0}), 146.0 * 10.0 / 50.0 * 0.6 * 0.6, 1e-9)
	assert_almost(Labour.repair_work(unit, "patch", {"unit_hp": 10.0, "hp": 4.0, "burnt": true}), 146.0 * 10.0 / 50.0 * 0.6 * 0.6 * 1.25, 1e-9)
	assert_eq(Labour.repair_work(unit, "stitch"), 4.0)
	assert_almost(Labour.repair_work({"work": 20.0}, "rerun"), 16.0, 1e-9)
	# Onarımda usta kuralı yoktur; Mete'nin repair becerisi oranı ×2 yapar (repairTime ×0,5).
	var hands := Labour.crew_on({"max": 8}, _hands(2), "wood")
	assert_false(hands["usta"], "Yalnız eller ağaç zanaatında usta değildir")
	var wood := {"id": "st_walls", "work": 510.0}
	assert_almost(Labour.build_rate(wood, hands, {"kind": "repair"}), Labour.k_build(2.0), 1e-12, "Onarımda ustasız ×0,7 yok")
	var with_mete := Labour.crew_on({"max": 8}, [{"id": "mete", "role": "mete"}, {"id": "h", "role": "hand"}])
	assert_almost(Labour.build_rate(felt, with_mete, {"kind": "repair", "mods": {"repairTime": 0.5}}), 2.0 * Labour.k_build(2.0), 1e-12, "repair: Mete'nin onarımı yarı sürede")


func test_multipliers_and_stop_reasons() -> void:
	var step := {"id": "st_walls", "work": 510.0}
	var hands := Labour.crew_on({"max": 6}, _hands(3), "wood")
	var info := {}
	var no_master := Labour.build_rate(step, hands, {"night": "day"}, info)
	assert_almost(no_master, Labour.k_build(3.0) * 0.7, 1e-12, "Ağaç yapıda usta yoksa oran ×0,7 («Usta yok: iş yavaş»)")
	assert_null(info["reason"])
	var carpenter := Labour.crew_on({"max": 6}, [{"id": "o", "role": "usta", "crafts": ["cr_carpenter"]}] + _hands(2), "wood")
	assert_almost(Labour.build_rate(step, carpenter, {"night": "day"}), Labour.k_build(3.0), 1e-12, "Dülgerle tam oran")
	assert_almost(Labour.build_rate(step, carpenter, {"night": "dim"}, info), Labour.k_build(3.0) * 0.7, 1e-12, "Ay ışığında ×0,7")
	assert_eq(info["reason"], "dark")
	assert_almost(Labour.build_rate(step, carpenter, {"night": "dark", "food": 20.0, "speed": 2.0}), Labour.k_build(3.0) * 0.4 * 0.85 * 2.0, 1e-12, "Karanlık, aç ekip, iki kat hız")
	assert_almost(Labour.build_rate(step, carpenter, {"food": 10.0, "fed": 1.0}), Labour.k_build(3.0), 1e-12, "Kışlak'ta K_tok 1'e iğneli")
	var felt := {"id": "y_tuurduk", "work": 129.0, "felt": true}
	var home := Labour.crew_on({"max": 8}, _hands(3))
	assert_almost(Labour.build_rate(felt, home, {"weather": "rain"}), Labour.k_build(3.0) * 0.7, 1e-12, "Yağmurda keçe adımı ×0,7")
	assert_eq(Labour.build_rate(felt, home, {"weather": "downpour"}, info), 0.0, "Sağanakta keçe adımı bekler")
	assert_eq([info["reason"], info["hold"], info["why"]], ["weather", "felt", "felt_rain"])
	assert_eq(Labour.build_rate(step, home, {"weather": "kara_boran"}, info), 0.0, "Kara Boran'da herkes sığınır")
	assert_eq([info["reason"], info["hold"]], ["storm", "all"])
	assert_eq(Labour.build_rate(step, home, {"hold": "fire"}, info), 0.0, "Dış neden emeği durdurur")
	assert_eq(info["reason"], "fire")
	assert_eq(Labour.build_rate({"id": "y_esik"}, home, {"gates": ["y_esik"]}, info), 0.0, "Senaryo kapısındaki adım bekler")
	assert_eq(info["reason"], "story")
	var child_only := Labour.crew_on({"max": 8}, [{"id": "c", "role": "child"}])
	assert_eq(Labour.build_rate(step, child_only, {}, info), 0.0, "Önder yoksa iş ilerlemez")
	assert_eq(info["reason"], "crew")
	assert_true(Labour.build_rate(step, child_only, {"kind": "stitch"}) > 0.0, "Yırtığı Çocuk da diker")
	# Tezgâh K21 eğrisiyle kalır: üç ellik tezgâh eff(3) = 2,71, inşaattaki 1,78 değil.
	assert_almost(Labour.station_rate(3.0), 2.71, 0.005)
	assert_almost(Labour.station_rate(3.0, "dark", 0.85, 1.0), Labour.eff(3.0) * 0.4 * 0.85, 1e-12)


func test_station_curve_table() -> void:
	# structures.md §2.4: eff(W) satırı (tezgâh eğrisi).
	var table := {0.5: 0.50, 0.75: 0.75, 1.0: 1.0, 1.5: 1.46, 1.75: 1.68, 2.0: 1.90, 2.5: 2.32, 2.75: 2.52, 3.0: 2.71, 3.25: 2.90, 4.0: 3.44, 5.0: 4.10, 6.0: 4.69, 7.0: 5.22, 8.0: 5.70}
	for w: float in table:
		assert_almost(Labour.eff(w), table[w], ROUND_2, "eff(%s)" % w)


func test_haul_table_rounds_to_the_document() -> void:
	# structures.md §2.4 «Taşıma» tablosu: İD, en yakın tamsayıya; son sütun araba 50 m.
	var rows := [
		[58.0, [47, 84, 158, 233], 18],
		[89.0, [78, 140, 264, 388], 36],
		[159.0, [125, 224, 423, 621], 54],
		[146.0, [125, 224, 423, 621], 54],
	]
	var dists := [25.0, 50.0, 100.0, 150.0]
	for row: Array in rows:
		for i in dists.size():
			assert_eq(roundi(Labour.haul_work(row[0], dists[i], "adult")), row[1][i], "%s Yük, %s m" % [row[0], dists[i]])
		assert_eq(roundi(Labour.haul_work(row[0], 50.0, "cart")), row[2], "%s Yük arabayla 50 m" % row[0])
	assert_eq(Labour.haul_trips(58.0, "adult"), 3.0, "Küçük Yurt 3 sefer")
	assert_eq(Labour.haul_trips(159.0, "adult"), 8.0, "Otağ 8 sefer")
	assert_eq(Labour.haul_cap({"cap": 20.0 + 8.0}), 28.0, "carry_pack: yük tavanı +8")


func test_day_capacity_table() -> void:
	var cap: Dictionary = ((_model().get("law", {}) as Dictionary).get("dayCapacity", {}))
	var days := {"winter": 14, "spring": 104, "summer": 195, "autumn": 287}
	for season: String in days:
		var dec := -23.44 * cos(2.0 * PI * (days[season] + 10) / 365.0)
		var info := {"lat": 43.5, "dec": dec, "window": Labour.rest_window("own_seat", season)}
		var k := Labour.day_capacity("produce", info)
		assert_almost(k, float(cap["outdoorTanhuOrdu"][season]), 0.06, "Açık hava üretimi, %s" % season)
		assert_almost((2.75 - 0.65) * k + 0.65 * Labour.day_capacity("herd"), float(cap["household"][season]), 0.6, "Hane, %s" % season)
		assert_almost(Labour.day_capacity("build", info, false, "rest"), k, 1e-12, "«Gece dinlenilsin» penceredir")
	assert_eq(Labour.day_capacity("build", {}, true), 24.0, "Şantiye, gece emri, ışıklı 24 İS")
	assert_eq(Labour.day_capacity("produce", {"window": Labour.rest_window("camp")}, true), 16.0, "Işıklı atölye 16 İS")
	assert_almost(Labour.day_capacity("produce", {"lat": 47.35, "dec": 7.4223, "window": Labour.rest_window("camp")}), float(cap["pinned"]["camp"]), 0.06, "Ana kamp 14,3")


func test_data_matches_labour_model_v3() -> void:
	var m := _model()
	assert_eq(int(m.get("version", 0)), 3, "Model v3")
	var data := Labour.data()
	assert_eq(int(data.get("version", 0)), 3, "labour.json v3")
	var law: Dictionary = data["law"]
	var ml: Dictionary = m["law"]
	for key: String in ["dayGameMin", "realSecPerGameMin", "effBase", "siteHeadMax", "roles", "roleUsta", "noUstaK", "leadMinWeight", "rotation", "dismantle"]:
		assert_eq(law[key], ml[key], "law.%s" % key)
	for key: String in ["base", "coefMax", "k_table", "appliesTo", "notAppliesTo"]:
		assert_eq(law["build"][key], ml["build"][key], "law.build.%s" % key)
	for key: String in ["classes", "dayLevel", "dimLevel", "fireLightPad", "torchDarkHours", "torchFreeSpecs", "restWindow"]:
		assert_eq(law["night"][key], ml["night"][key], "law.night.%s" % key)
	for key: String in ["ok", "low", "hungry", "lowBelow", "hungryBelow", "pinned"]:
		assert_eq(law["fed"][key], ml["fed"][key], "law.fed.%s" % key)
	for key: String in ["raise", "patch", "burnt", "skill", "rerun", "tearStitch"]:
		assert_eq(law["repair"][key], ml["repair"][key], "law.repair.%s" % key)
	for key: String in ["vLoaded", "vEmpty", "handleS", "cap", "selfHaulR", "cart"]:
		assert_eq(law["haul"][key], ml["haul"][key], "law.haul.%s" % key)
	for key: String in ["outdoorTanhuOrdu", "workshopLit", "build", "herding", "household", "pinned"]:
		assert_eq(law["dayCapacity"][key], ml["dayCapacity"][key], "law.dayCapacity.%s" % key)
	assert_eq(law["skills"]["quick_raise"]["crewK"], ml["skills"]["quick_raise"]["crewK"])
	assert_eq(law["skills"]["repair"], ml["skills"]["repair"])
	assert_eq(law["skills"]["carry_pack"], ml["skills"]["carry_pack"])
	var weather: Dictionary = (m["weather"] as Dictionary).duplicate()
	weather.erase("_note")
	assert_eq(data["weather"], weather, "Hava tepkisi tablosu modelinki")
	assert_eq(data["childHelp"]["verbs"], m["childHelp"]["verbs"], "Çocuğun altı fiili (K52)")
	assert_eq(data["childHelp"]["excludedSteps"], m["crew"]["childExcludedSteps"])
	# Yapılar: adım payları ve el tavanları modelinki; her türün tek el emeği (one) adımlarının toplamıdır.
	var s := Labour.structures()
	for kind: String in m["defs"]:
		var md: Dictionary = m["defs"][kind]
		var dd: Dictionary = s["defs"][kind]
		if md.has("steps"):
			assert_eq((dd["steps"] as Array).size(), (md["steps"] as Array).size(), "%s adım sayısı" % kind)
			for i in (md["steps"] as Array).size():
				for key: String in ["id", "stage", "work", "slots", "felt", "tall", "lattice", "child", "workIfEmber", "rawWork", "rawRole"]:
					assert_eq((dd["steps"][i] as Dictionary).get(key), (md["steps"][i] as Dictionary).get(key), "%s.%s.%s" % [kind, md["steps"][i]["id"], key])
		if md.get("crewMax") is float:
			assert_eq(dd["crewMax"], md["crewMax"], "%s el tavanı" % kind)
		if md.get("one") is float and not md.has("per"):
			assert_almost(Labour.structure_work(kind), float(md["one"]), 1e-6, "%s: one adımların toplamı" % kind)
	for kind: String in m["settlement"]:
		if kind.begins_with("_"):
			continue
		var mr: Dictionary = m["settlement"][kind]
		var dr: Dictionary = s["settlement"][kind]
		for key: String in ["craft", "one", "work", "same", "drop", "add", "stepSlots", "coefMax", "size"]:
			assert_eq(dr.get(key), mr.get(key), "settlement.%s.%s" % [kind, key])
		var derived := Labour.steps_of(kind)
		var numeric_work: bool = mr.get("work") is Array or (mr.has("same") and not mr.has("workPerM"))
		if numeric_work and not mr.get("per10m", false) and not mr.get("per20m", false) and not mr.get("perPlot", false):
			assert_almost(Labour.structure_work(kind), float(mr["one"]), 0.51, "%s: one türetilen adımların toplamı" % kind)
		if mr.get("work") is Array:
			assert_eq(derived.size(), (mr["work"] as Array).size() + (1 if mr.has("add") else 0), "%s adım sayısı" % kind)
	for size: String in ["s", "m", "l"]:
		for key: String in ["one", "crewMax", "baseRealMin", "realMin", "dismantleRealMin", "workK", "kit", "kitLoad", "siteLoad"]:
			assert_eq(s["sizes"][size].get(key), m["sizes"][size].get(key), "sizes.%s.%s" % [size, key])


func test_settlement_steps_follow_their_base() -> void:
	var yurt := Labour.steps_of("yurt")
	var small := Labour.steps_of("yurt_small")
	assert_eq(small.size(), yurt.size(), "Küçük Yurt yurdun adımlarıyla")
	assert_eq(small[0]["id"], "y_site")
	assert_almost(float(small[2]["work"]), 58.4, 1e-9, "Payı kendi work dizisinden")
	assert_eq(small[1]["slots"], 4, "stepSlots kimlikle ezer (bosağa 4)")
	assert_true(small[2].get("lattice", false), "Bayraklar yurdunki")
	var armoury := Labour.steps_of("armoury")
	assert_false(armoury.any(func(st: Dictionary) -> bool: return st["id"] == "y_ocak"), "Silahlık'ta ocak düşer")
	assert_eq(armoury.back()["id"], "y_raf", "Raf sona eklenir")
	assert_almost(Labour.structure_work("armoury"), 1728.0, 1e-9)
	var shop := Labour.steps_of("wood_shop")
	assert_eq(shop[2]["slots"], 4, "stepSlots dizinle ezer")
	assert_eq(shop[0]["id"], "sh_footing", "Ağaç Atölyesi ambarın adımlarıyla")
	var yard := Labour.steps_of("felt_yard")
	assert_eq(yard.map(func(st: Dictionary) -> String: return st["id"]), ["s0", "s1", "s2", "s3"], "Tabansız satırın adımları s0, s1, …")
	assert_eq(Labour.steps_of("no_such_kind"), [], "Bilinmeyen tür boş")
	assert_eq(Labour.crew_minutes("no_such_kind", _hands(3)), INF)


func test_prototype_fixture() -> void:
	var fx := ProtoFixture.load_fixture("labour")
	assert_false(fx.is_empty(), "tests/fixtures/labour.json yok: node tools/proto_fixtures.mjs --only=labour")
	if fx.is_empty():
		return
	var handlers := {
		"eff": func(a: Array) -> Variant: return Labour.eff(float(ProtoFixture.decode_number(a[0]))),
		"weightOf": func(a: Array) -> Variant: return Labour.weight_of(a[0]),
		"isMaster": func(a: Array) -> Variant: return Labour.is_master(a[0], a[1]),
		"crewOn": func(a: Array) -> Variant: return Labour.crew_on(a[0], a[1], a[2]),
		"nightK": func(a: Array) -> Variant: return Labour.night_k(a[0]),
		"fedK": func(a: Array) -> Variant: return Labour.fed_k(ProtoFixture.decode_number(a[0]), a[1]),
		"weatherK": func(a: Array) -> Variant: return Labour.weather_k(a[0], a[1]),
		"haulCap": func(a: Array) -> Variant: return Labour.haul_cap(a[0]),
		"haulTrip": func(a: Array) -> Variant: return Labour.haul_trip(a[0], a[1]),
		"haulTrips": func(a: Array) -> Variant: return Labour.haul_trips(a[0], a[1]),
		"haulWork": func(a: Array) -> Variant: return Labour.haul_work(a[0], a[1], a[2]),
		"dayCapacity": _day_capacity_case,
		"restWindow": func(a: Array) -> Variant: return Labour.rest_window(a[0], a[1]),
	}
	var n := ProtoFixture.run_cases(self, fx, handlers)
	assert_eq(n, (fx["cases"] as Array).size(), "Her durum koşuldu")
	assert_true(n >= 400, "Fikstürde en az 400 durum (%d)" % n)
	# Taşınan tablolar: prototipin sabitleri data/structures/labour.json'unkiyle aynı (değişmeyen kurallar).
	var c: Dictionary = fx["constants"]
	var law := Labour.law()
	assert_eq(c["DAY"], law["dayGameMin"])
	assert_eq(c["REAL_S_PER_MIN"], law["realSecPerGameMin"])
	assert_eq(c["B"], law["effBase"])
	assert_eq(c["SITE_MAX"], law["siteHeadMax"])
	assert_eq(c["NO_USTA"], law["noUstaK"])
	assert_eq(c["LEAD_W"], law["leadMinWeight"])
	var roles: Dictionary = (law["roles"] as Dictionary).duplicate()
	assert_eq(c["MASTER_W_MAX"], roles["namedMasterMax"])
	roles.erase("namedMasterMax")
	assert_eq(c["ROLE_W"], roles)
	assert_eq(c["ROLE_USTA"], law["roleUsta"])
	assert_eq(c["CRAFT_OF"], law["craftOf"])
	for key: String in ["lit", "day", "dim", "dark"]:
		assert_eq(c["NIGHT"][key], law["night"]["classes"][key], "NIGHT.%s" % key)
	for key: String in ["dayLevel", "dimLevel", "torchDarkHours", "fireLightPad"]:
		assert_eq(c["NIGHT"][key], law["night"][key], "NIGHT.%s" % key)
	for key: String in ["ok", "low", "hungry", "lowBelow", "hungryBelow"]:
		assert_eq(c["FED"][key], law["fed"][key], "FED.%s" % key)
	for key: String in ["raise", "patch", "burnt", "rerun", "tearStitch"]:
		assert_eq(c["REPAIR"][key], law["repair"][key], "REPAIR.%s" % key)
	assert_eq(c["DISMANTLE"], law["dismantle"])
	assert_eq(c["HAUL"]["cap"], law["haul"]["cap"])
	assert_eq(c["HAUL"]["cart"], law["haul"]["cart"])
	assert_eq(c["HAUL"]["selfR"], law["haul"]["selfHaulR"])
	assert_almost(float(c["QUICK_RAISE"]), 1.0 / 0.7, 1e-12, "quick_raise ×1/0,7")
	assert_eq(c["CAP"], {"build": law["dayCapacity"]["build"], "herd": law["dayCapacity"]["herding"], "workshopLit": law["dayCapacity"]["workshopLit"]})
	for place: String in c["WINDOW"]:
		var win: Array = c["WINDOW"][place]
		var ours: Array = law["night"]["restWindow"][place]
		assert_eq([Labour.day_minute(ours[0]), Labour.day_minute(ours[1])], [float(win[0]), float(win[1])], "WINDOW.%s" % place)
	var weather: Dictionary = Labour.data()["weather"].duplicate()
	assert_almost(float(c["RESUME_MIN"]), float(weather["resumeAfterGameHours"]) * 60.0, 1e-12)
	weather.erase("resumeAfterGameHours")
	assert_eq(c["WEATHER"], weather, "Hava tepkisi tablosu prototipinkiyle aynı")


## dayCapacity durumu: girdideki classAt [[başı, sonu, sınıf], …] tablosu Callable'a çevrilir.
func _day_capacity_case(a: Array) -> Variant:
	var info: Dictionary = {}
	if a.size() > 1 and a[1] is Dictionary:
		info = (a[1] as Dictionary).duplicate()
		if info.get("classAt") is Array:
			var table: Array = info["classAt"]
			info.erase("classAt")
			info["class_at"] = func(minute: float) -> String:
				for row: Array in table:
					if minute >= float(row[0]) and minute < float(row[1]):
						return str(row[2])
				return "day"
	var lit: bool = a[2] if a.size() > 2 and a[2] is bool else false
	var order: String = a[3] if a.size() > 3 and a[3] is String else "work"
	return Labour.day_capacity(a[0], info, lit, order)


func test_fixture_leaves_out_the_changed_rule() -> void:
	var fx := ProtoFixture.load_fixture("labour")
	for c: Dictionary in fx.get("cases", []):
		assert_false(str(c["fn"]) in ["stepRate", "simulate", "etaMinutes", "remaining", "deriveSteps", "repairWork"], "%s: değişen kural (T(n), K50) fikstüre girmez" % c["id"])
