extends TestCase
## Şantiyenin emeği (SiteState, SiteRules; K21, K50, K52, K83; structures.md §2.4, §2.5, §11.6, §14, §17 kabul 4, 19, 21, 22, 24, 26):
## camp3'ün dört durumu ve «Gece dinlenilsin» belgenin saatlerini ±15 gerçek sn (±6 oyun dk) tutar; aile kuralı 23:00'te aşama ≥4'e bakar;
## Kışlak Yeni Yurdu'nun takvimi (Ambar yalnız eksiği gönderir, tündük Gün III 08:30'da altı elle, ocak Gün IV 17:00'de Atşo'yla) ±1 dk;
## olay güdümlü ilerleme kare kare ilerlemeyle aynıdır; hasar LIFO düşer, aşama 0 yıkılmaz; kayıt gidip gelir; yağmur keçe adımını ×0,7 yapar.

## Serbest Gez'in günü (11 Nisan MÖ 209) ve ustaların inişi (14:54).
const DAY := 1171
const START := 894.0
## Belgenin saatleri (gün dakikası; ertesi gün +1440): structures.md §11.6 «İlk gün» ve tablo.
const UNAIDED := {"y_site": 946.0, "y_bosaga": 995.0, "y_kerege": 1083.0, "y_bag": 1113.0, "y_tunduk": 1236.0, "y_uuk": 1420.0,
	"y_liner": 1488.0, "y_tuurduk": 1566.0, "y_uzuk": 1654.0, "y_kolan": 1723.0, "y_esik": 1735.0, "y_sirdak": 1784.0}
## Saat toleransı: ±15 gerçek sn = ±6 oyun dk; dakikaya yuvarlanmış saatler için ±1 dk.
const TOL_S := 15.0
const TOL_MIN := 1.01


func before_each() -> void:
	Labour.reset_cache()
	SiteState.reset_cache()


func _abs(day_min: float) -> float:
	return float(DAY) * 1440.0 + day_min


func _run(opts: Dictionary, until_min: float = 2200.0) -> SiteState:
	var site := SiteRules.camp3(_abs(START), opts)
	site.advance(_abs(until_min))
	return site


## Emeğin bitişinden gerçek saniye (14:54'ten).
func _real_s(site: SiteState) -> float:
	return (site.finished_at - _abs(START)) * 2.5


func test_camp3_unaided_matches_the_document() -> void:
	var site := _run({})
	assert_true(site.is_done(), "Yardımsız camp3 biter")
	for sid: String in UNAIDED:
		assert_almost(site.log.get(sid, -1.0) - _abs(0.0), float(UNAIDED[sid]), TOL_MIN, "Yardımsız %s" % sid)
	assert_eq(SiteRules.family_saw_smoke(site), false, "23:00'te aşama 4'ün altında: aile yatar")
	assert_almost(_real_s(site), 2235.0, TOL_S, "İlk duman 05:48 (2.235 gerçek sn; K83)")
	assert_almost(site.finished_at - _abs(1440.0), 348.0, TOL_MIN, "İlk duman 05:48")
	assert_eq(str(site.opts.get("ember_by", "")), "mother", "Ocak Ana'nın sabah közüyle yanar")
	# Ocak hemen yansaydı (köz yok, kapı yok): emek 05:56'da biterdi (2.256 sn).
	var raw := _run({"family": false})
	assert_almost((raw.finished_at - _abs(START)) * 2.5, 2256.0, TOL_S, "Emek biter 05:56 (2.256 sn)")
	assert_almost(raw.finished_at - _abs(1440.0), 356.0, TOL_MIN)


func test_camp3_errands_only() -> void:
	var site := _run({"child": {"water": 2, "logs": 4, "ember": 1}})
	assert_almost(site.log["y_tunduk"] - _abs(0.0), 1233.0, TOL_MIN, "Tündük 20:33")
	assert_almost(site.log["y_uuk"] - _abs(0.0), 1409.0, TOL_MIN, "Uuk 23:29")
	assert_eq(SiteRules.family_saw_smoke(site), false, "Aile yatar")
	assert_almost(_real_s(site), 2207.0, TOL_S, "İlk duman 05:37 (2.207 sn)")


func test_camp3_join_only() -> void:
	var site := _run({"child": {"joined": true}})
	assert_almost(site.log["y_tunduk"] - _abs(0.0), 1192.0, TOL_MIN, "Tündük 19:52")
	assert_almost(site.log["y_uuk"] - _abs(0.0), 1352.0, TOL_MIN, "Uuk 22:32")
	assert_eq(SiteRules.family_saw_smoke(site), true, "23:00'te aşama ≥4: aile ilk dumana dek bekler")
	assert_almost(_real_s(site), 1969.0, TOL_S, "İlk duman 04:02 gece (1.969 sn)")


func test_camp3_join_and_errands() -> void:
	var site := _run({"child": {"joined": true, "water": 2, "logs": 4, "ember": 1}})
	assert_almost(site.log["y_tunduk"] - _abs(0.0), 1188.5, TOL_MIN, "Tündük 19:48")
	assert_almost(site.log["y_uuk"] - _abs(0.0), 1342.5, TOL_MIN, "Uuk 22:22")
	assert_eq(SiteRules.family_saw_smoke(site), true)
	assert_almost(_real_s(site), 1924.0, TOL_S, "İlk duman 03:43 gece (1.924 sn)")


func test_camp3_rest_at_night() -> void:
	var site := _run({"rest": true}, 3200.0)
	assert_almost(site.log["y_tunduk"] - _abs(0.0), 1236.0, TOL_MIN, "Tündük 20:36")
	assert_almost(site.log["y_uuk"] - _abs(1440.0), 460.0, TOL_MIN, "Uuk ertesi 07:40")
	assert_almost(site.finished_at - _abs(1440.0), 857.0, TOL_MIN, "Ertesi 14:17 (köz 08:00'de söndü)")
	assert_almost(_real_s(site) / 60.0, 58.5, 0.15, "58,5 gerçek dk")


func test_child_is_not_counted_on_the_door_felt_and_hearth() -> void:
	var site := SiteRules.camp3(_abs(START), {"child": {"joined": true}, "family": false})
	for st: Dictionary in site.steps:
		var counts := site.child_counts(st)
		var sid := str(st["id"])
		assert_eq(counts, sid != "y_esik" and sid != "y_ocak", "Çocuk %s" % sid)
	site.child["active"] = false
	assert_false(site.child_counts(site.steps[0]), "Fiili bırakınca katkı durur")


func test_event_driven_equals_frame_steps() -> void:
	var a := SiteRules.camp3(_abs(START), {"child": {"joined": true}})
	var b := SiteRules.camp3(_abs(START), {"child": {"joined": true}})
	a.advance(_abs(START + 600.0))
	var t := _abs(START)
	for i in 600:
		t += 1.0
		b.advance(t)
	assert_eq(a.step, b.step, "Aynı adım")
	assert_almost(a.wm, b.wm, 1e-6, "600 dk tek adım = 600 × 1 dk (±1e−6 İD)")
	var c := SiteRules.camp3(_abs(START), {})
	var tt := _abs(START)
	while tt < _abs(2200.0):
		tt += 0.4
		c.advance(tt)
	assert_almost(c.finished_at, _run({}).finished_at, 1e-6, "Kare kare (0,4 dk) aynı bitiş")


func test_eta_does_not_touch_the_site() -> void:
	var site := SiteRules.camp3(_abs(START), {})
	site.advance(_abs(1200.0))
	var before := site.to_dict()
	var eta := site.eta()
	assert_true(is_finite(eta), "Kestirim biter")
	assert_eq(site.to_dict(), before, "Kestirim durumu değiştirmez")
	assert_false(site.opts.has("family_wait"), "Aile denetimi gerçek şantiyede henüz yapılmadı")
	site.advance(_abs(2200.0))
	assert_almost(site.finished_at, eta, 1e-6, "Kestirim gerçek bitişle aynı")


func test_kislak_new_yurt_schedule() -> void:
	var day1 := 1041.0 * 1440.0
	var site := SiteRules.kislak_new_yurt(day1, day1 + 840.0)
	site.advance(day1 + 4.0 * 1440.0)
	assert_true(site.is_done(), "Yeni Yurt Gün IV'te biter")
	var stage_at := {}
	for i in site.steps.size():
		stage_at[site.stage_of(i)] = site.log[str((site.steps[i] as Dictionary)["id"])]
	# Aşamanın son adımının bittiği an (structures.md §14 «Yalnız ekip ve Ambar gönderimi»; y_ocak duman ayrı).
	var last_of := func(s: int, skip_ocak: bool) -> float:
		var t := 0.0
		for i in site.steps.size():
			var sid := str((site.steps[i] as Dictionary)["id"])
			if site.stage_of(i) == s and not (skip_ocak and sid == "y_ocak"):
				t = maxf(t, float(site.log[sid]))
		return t
	var expect := [[0, 1, 886.0], [1, 2, 601.0], [2, 2, 889.0], [3, 3, 551.0], [4, 3, 943.0], [5, 3, 1007.0], [6, 4, 717.0], [7, 4, 901.0]]
	for e: Array in expect:
		var t: float = last_of.call(int(e[0]), true)
		assert_almost(t - (day1 + float(int(e[1]) - 1) * 1440.0), float(e[2]), TOL_MIN, "Aşama %d" % e[0])
	assert_almost(site.log["y_ocak"] - (day1 + 3.0 * 1440.0), 1026.0, TOL_MIN, "Toy'da ilk duman Gün IV 17:06")
	assert_almost(site.log["y_tunduk"] - (day1 + 2.0 * 1440.0), 551.0, TOL_MIN, "Tündük Gün III 09:11 (altı el, 40,6 oyun dk)")


func test_hits_fall_lifo_and_stage_zero_stands() -> void:
	var site := SiteRules.camp3(_abs(START), {"family": false})
	site.advance(_abs(2200.0))
	assert_eq(site.stage, 7)
	assert_almost(site.hp_total(), 420.0, 1e-6, "Hane Yurdu 420 can")
	var w := watch_signal(site.stage_changed)
	assert_eq(site.hit(20.0), 0, "Kolan havuzu 30: düşmez")
	assert_almost(site.damage, 20.0 / 30.0, 1e-6)
	assert_eq(site.hit(40.0), 1, "Artan 30 keçeye geçer: 7 → 6")
	assert_eq(site.stage, 6)
	assert_almost(float(site.hp[6]), 90.0, 1e-6, "Keçe 120 − 30")
	assert_true(w.count >= 1)
	site.hit(10000.0)
	assert_eq(site.stage, 0, "Aşama 0 yıkılmaz")
	assert_false(site.is_done(), "Düşen adımlar yeniden kurulur")
	assert_eq(site.current_id(), "y_bosaga")
	assert_almost(site.work_of(site.step), 81.0 * 0.8, 1e-6, "Onarım payın 0,8'i")


func test_sizes_scale_work_and_hp() -> void:
	for row: Array in [["s", 576.0, 216.0], ["m", 1440.0, 420.0], ["l", 3600.0, 843.0]]:
		var site := SiteState.create("yurt", str(row[0]), {"raw": false})
		assert_almost(site.total_work(), float(row[1]), 1e-6, "Boy %s emeği" % row[0])
		assert_almost(site.hp_max(), float(row[2]), 1e-6, "Boy %s canı" % row[0])
		assert_eq(site.steps.size(), 13, "13 adım")


func test_rain_slows_felt_steps() -> void:
	var dry := SiteRules.camp3(_abs(START), {"family": false})
	var wet := SiteRules.camp3(_abs(START), {"family": false, "weather": "rain"})
	var felt := {}
	var plain := {}
	for i in dry.steps.size():
		var st: Dictionary = dry.steps[i]
		if bool(st.get("felt", false)):
			felt[str(st["id"])] = true
		else:
			plain[str(st["id"])] = true
	dry.step = 7
	wet.step = 7
	assert_eq(dry.current_id(), "y_tuurduk")
	var r_dry := dry.rate_at(_abs(1000.0))
	var r_wet := wet.rate_at(_abs(1000.0))
	assert_almost(r_wet / r_dry, 0.7, 1e-6, "Yağmurda keçe adımı ×0,7")
	dry.step = 2
	wet.step = 2
	assert_almost(wet.rate_at(_abs(1000.0)) / dry.rate_at(_abs(1000.0)), 0.85, 1e-6, "Genel iş ×0,85")
	wet.env["weather"] = "downpour"
	wet.step = 7
	assert_eq(wet.rate_at(_abs(1000.0)), 0.0, "Sağanakta keçe bekler")
	assert_eq(str(wet.wait_reason), "weather")
	assert_true(felt.size() >= 4 and plain.size() >= 8)


func test_save_round_trip() -> void:
	var site := SiteRules.camp3(_abs(START), {"child": {"joined": true, "logs": 2}})
	site.advance(_abs(1300.0))
	site.hit(5.0)
	site.add_tear(3)
	var d := site.to_dict()
	var back := SiteRules.camp3(_abs(START), {"family": false})
	assert_true(back.from_dict(d))
	assert_eq(back.stage, site.stage)
	assert_eq(back.step, site.step)
	assert_almost(back.wm, site.wm, 0.05, "Adım içi oran")
	assert_eq(back.tears, 3)
	assert_eq(int(back.child["logs"]), 2)
	assert_almost(back.hp_total(), site.hp_total(), 0.51, "Can 0,5 nicemle")
	assert_true(JSON.stringify(d).length() < 2048, "≤2 KB")
	assert_false(SiteState.new().from_dict({}), "Boş kayıt okunmaz")
