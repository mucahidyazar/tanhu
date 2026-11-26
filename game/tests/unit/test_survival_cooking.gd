extends TestCase
## Pişirme ve bozulma (Yol Haritası fire-hunting; survival.md §3, economy.md §2.10, §5.2, §5.5; weather.md §8.5): istasyon ateşin
## evresinden (şiş ve kazan Küçük–Büyük, kor yalnız Kor; kazan taş halkası ve küçük kazan ya da Eski Ocak), süre evre ve havayla,
## Tam Vuruş (★3, ★1, Yanık; Kor güvenli; Büyük'te şiş hızlı yanar), kazan ★2 (Ocak Bilgisi ★3), girdi Heybe'den alınır ve iş yarıda
## kalınca geri döner, çıktı Heybe'ye girer, ateş başında hemen yenince yıldız geçer, ilk tarif +20 XP, Ocağa Pay; çiğ et ikinci şafakta
## bozulur, pişmişi bozulmaz.


func _setup(items: Dictionary, stones := false, fuel := 300.0) -> Dictionary:
	var inv := Inventory.new()
	for id: String in items:
		inv.add(id, int(items[id]))
	# Saatsiz Survival yerel sayaçla yürür (step'in dt'si gerçek saniyedir).
	var s := Survival.new({"inventory": inv})
	var f := s.fires.add(Vector2.ZERO, s.zone, stones, fuel, 0.0)
	return {"inv": inv, "s": s, "fire": f}


func test_stations_follow_the_stage_and_the_cauldron_needs_stones_and_pot() -> void:
	var f := FireState.new()
	f.light(Vector2.ZERO, "z", false, 300.0, 0.0)
	assert_eq(Cooking.stations_for(f, false), PackedStringArray(["spit"]), "Taşsız ateşte şiş")
	assert_eq(Cooking.stations_for(f, true), PackedStringArray(["spit"]), "Kazan taş halkası ister")
	f.stones = true
	assert_eq(Cooking.stations_for(f, true), PackedStringArray(["spit", "cauldron"]), "Taş halkası ve küçük kazan")
	f.old = true
	assert_eq(Cooking.stations_for(f, false), PackedStringArray(["spit", "cauldron"]), "Eski Ocak'ta kazan hazır")
	f.fuel = 30.0
	f.advance(0.001, 0.0)
	assert_eq(Cooking.stations_for(f, true), PackedStringArray(["ember"]), "Kor evresinde yalnız kor")
	assert_false(f.douse(1.0), "Kor söndürülmez, küle yatırılır")
	f.advance(100.0, 1.0)
	assert_eq(Cooking.stations_for(f, true), PackedStringArray([]), "Çukurda pişmez")
	assert_false(Cooking.is_fire_station("rack"), "Kurutma Sırığı ateşin değil")
	assert_true(Cooking.start_known().has("spit_meat") and Cooking.start_known().has("ember_fish") and Cooking.start_known().has("meal"),
		"Başta: Şiş Et, Korda Balık, Aş")
	assert_false(Cooking.start_known().has("stew"), "Yahni'yi Hereka öğretir")


func test_cook_seconds_by_stage_weather_and_water() -> void:
	var spit := Cooking.recipe("spit_meat")
	assert_almost(Cooking.seconds_for(spit, FireState.stage_row_of(&"small"), "clear", false), 14.4, 1e-9, "Küçük ×1,2")
	assert_almost(Cooking.seconds_for(spit, FireState.stage_row_of(&"steady"), "clear", false), 12.0, 1e-9, "Orta ×1")
	assert_almost(Cooking.seconds_for(spit, FireState.stage_row_of(&"blaze"), "clear", false), 9.6, 1e-9, "Büyük ×0,8")
	assert_almost(Cooking.seconds_for(spit, FireState.stage_row_of(&"steady"), "wind", false), 10.8, 1e-9, "Rüzgârda şiş ×0,9")
	assert_almost(Cooking.seconds_for(spit, FireState.stage_row_of(&"steady"), "rain", false), 14.4, 1e-9, "Yağmurda ×1,2")
	assert_almost(Cooking.seconds_for(spit, FireState.stage_row_of(&"steady"), "blizzard", false), -1.0, 1e-9, "Tipide şiş yok")
	var fish := Cooking.recipe("ember_fish")
	assert_almost(Cooking.seconds_for(fish, FireState.stage_row_of(&"embers"), "rain", false), 12.0, 1e-9, "Yağmurda kor ×1,5")
	assert_almost(Cooking.seconds_for(fish, FireState.stage_row_of(&"embers"), "downpour", false), -1.0, 1e-9, "Sağanakta kor yok")
	var meal := Cooking.recipe("meal")
	assert_almost(Cooking.seconds_for(meal, FireState.stage_row_of(&"steady"), "clear", true), 15.0, 1e-9, "Aş 15 sn")
	assert_almost(Cooking.seconds_for(meal, FireState.stage_row_of(&"steady"), "clear", false), 20.0, 1e-9, "Tulum yoksa kar erit: +5 sn")
	assert_eq(Cooking.quality_drop("dust_storm"), 1, "Toz fırtınasında kalite −1")


func test_perfect_strike_late_and_burnt() -> void:
	assert_eq(Cooking.judge(11.0, 12.0), Cooking.Q_EARLY, "Erken basış: henüz pişmedi")
	assert_eq(Cooking.judge(12.2, 12.0), 3, "Doğru an ★3")
	assert_eq(Cooking.judge(13.5, 12.0), 1, "Geç ★1")
	assert_eq(Cooking.judge(15.0, 12.0), Cooking.Q_BURNT, "Çok geç Yanık")
	assert_eq(Cooking.judge(15.0, 12.0, 1.0, true), 1, "Kor'da kalite güvenli")
	assert_eq(Cooking.judge(14.6, 12.0), 1)
	assert_eq(Cooking.judge(14.6, 12.0, 1.3), Cooking.Q_BURNT, "Büyük evrede şiş %30 hızlı yanar")
	var j := Cooking.Job.make("spit_meat", {"meat": 1}, 12.0, true, false, 1.0)
	assert_eq(j.tick(11.0), Cooking.Q_PENDING)
	assert_false(j.ring_open())
	assert_eq(j.tick(0.9), Cooking.Q_PENDING)
	assert_true(j.ring_open(), "Halka kapanıyor")
	assert_eq(j.press(), 3)
	assert_eq(j.out, "spit_meat")
	var late := Cooking.Job.make("spit_meat", {"meat": 1}, 12.0, true, false, 1.0)
	assert_eq(late.tick(Cooking.burn_at(12.0) + 0.01), Cooking.Q_BURNT, "Basılmazsa yanar")
	assert_eq(late.out, "burnt")
	var pot := Cooking.Job.make("meal", {"millet": 2}, 15.0, false, false, 1.0)
	assert_eq(pot.press(), Cooking.Q_PENDING, "Kazan zamanlama istemez")
	assert_eq(pot.tick(15.0), 2, "Kazan ★2")
	var crafted := Cooking.Job.make("meal", {"millet": 2}, 15.0, false, false, 1.0)
	crafted.bonus = 1
	assert_eq(crafted.tick(16.0), 3, "Ocak Bilgisi ★3")
	var dusty := Cooking.Job.make("spit_meat", {}, 12.0, true, false, 1.0)
	dusty.drop = 1
	dusty.tick(12.0)
	assert_eq(dusty.press(), 2, "Toz ★3'ü ★2'ye düşürür")


func test_cook_flow_takes_inputs_and_puts_the_dish_in_the_pack() -> void:
	var w := _setup({"meat": 1, "meat_small": 2})
	var s: Survival = w["s"]
	var inv: Inventory = w["inv"]
	var f: FireState = w["fire"]
	var p := Progression.new()
	s.progression = p
	var opts := s.cook_options(f)
	var ids: Array = opts.map(func(o: Dictionary) -> String: return str(o["id"]))
	assert_true(ids.has("spit_meat") and ids.has("meal") and ids.has("ember_fish"), "Bilinen ateş tarifleri: %s" % [ids])
	assert_false(ids.has("dried_meat"), "Sırık tarifi çemberde yok")
	for o: Dictionary in opts:
		match str(o["id"]):
			"spit_meat":
				assert_true(bool(o["ok"]), "Şiş Et pişebilir")
			"meal":
				assert_eq(str(o["reason"]), "no_pot", "Taşsız ateşte kazan yok («taş halkası ve küçük kazan gerek»)")
			"ember_fish":
				assert_eq(str(o["reason"]), "no_station", "Orta evrede kor yok")
	var r := s.start_cook("spit_meat", f)
	assert_true(bool(r["ok"]), str(r["text"]))
	assert_eq(inv.count("meat"), 0, "Girdi alındı (önce 1 et)")
	assert_eq(inv.count("meat_small"), 2)
	var job: Cooking.Job = s.job
	assert_almost(job.T, 12.0, 1e-9, "Orta evre 12 sn")
	s.step(1.0)
	assert_eq(s.cook_press(), Cooking.Q_EARLY)
	assert_not_null(s.job, "Erken basış işi bitirmez")
	for i in 11:
		s.step(1.0)
	assert_eq(s.cook_press(), 3, "Doğru an")
	assert_null(s.job)
	assert_eq(inv.count("spit_meat"), 1, "Şiş Et Heybe'de")
	assert_eq(p.xp, 20, "İlk tarif +20 XP")
	assert_false(s.fresh.is_empty(), "Ateş başında hemen yenebilir")
	var gained := s.eat_fresh()
	assert_almost(gained, 39.0, 1e-9, "★3: 30 × 1,3")
	assert_eq(inv.count("spit_meat"), 0)
	assert_eq(s.buffs.size(), 1, "Bilek +1 süreli etkisi")
	assert_almost(float(s.buffs[0]["left"]), 180.0 * 1.3, 1e-9, "Süre kaliteyle ×1,3")
	assert_almost(float(s.buff_block().get("grip", 0.0)), 1.0, 1e-9)
	r = s.start_cook("spit_meat", f)
	assert_true(bool(r["ok"]), "Et yoksa iki küçük et")
	assert_eq(inv.count("meat_small"), 0)
	s.step(Cooking.burn_at(12.0) + 1.0)
	assert_null(s.job)
	assert_eq(inv.count("burnt"), 1, "Basılmayan şiş yanar")
	assert_eq(p.xp, 20, "Aynı tarif ikinci kez XP vermez")


func test_walking_away_returns_the_ingredients() -> void:
	var w := _setup({"meat": 1})
	var s: Survival = w["s"]
	var inv: Inventory = w["inv"]
	s.start_cook("spit_meat", w["fire"])
	assert_eq(inv.count("meat"), 0)
	assert_true(s.cancel_cook(), "Yürüyünce iş bırakılır")
	assert_eq(inv.count("meat"), 1, "Malzeme gitmez")
	var w2 := _setup({"meat": 1})
	var s2: Survival = w2["s"]
	s2.start_cook("spit_meat", w2["fire"])
	(w2["fire"] as FireState).douse(0.0)
	s2.step(0.5)
	assert_null(s2.job, "Ateş sönünce iş bırakılır")
	assert_eq((w2["inv"] as Inventory).count("meat"), 1)


func test_cauldron_meal_at_an_old_hearth_and_hearths_share() -> void:
	var w := _setup({"millet": 2}, true)
	var s: Survival = w["s"]
	var f: FireState = w["fire"]
	f.old = true
	var r := s.start_cook("meal", f, true)
	assert_true(bool(r["ok"]), str(r["text"]))
	assert_true(s.job.share, "Ocağa Pay")
	assert_eq(f.share_day, s.day(), "Ateşin bugünkü payı verildi")
	assert_almost(s.job.T, 20.0, 1e-9, "Orta evre 15 sn + tulumsuz 5 sn")
	s.step(20.5)
	assert_null(s.job)
	assert_eq(int(s.fresh["quality"]), 2, "Kazan ★2")
	assert_almost(s.eat_fresh(), 32.0, 1e-9, "Ocağa Pay: 35 × 0,9 → 32")
	assert_almost(f.burn_rate(null, s.day()), (2.0 / 3.0) * 0.9, 1e-9, "Ateşin o günkü tüketimi ×0,9")
	(w["inv"] as Inventory).add("millet", 2)
	s.start_cook("meal", f, true)
	assert_false(s.job.share, "Ateş başına günde bir")


func test_unknown_or_missing_recipe_is_refused() -> void:
	var w := _setup({"meat": 1})
	var s: Survival = w["s"]
	assert_false(bool(s.start_cook("stew", w["fire"])["ok"]), "Yahni bilinmiyor")
	s.known["stew"] = true
	(w["fire"] as FireState).stones = true
	(w["inv"] as Inventory).add("pot", 1)
	var r := s.start_cook("stew", w["fire"])
	assert_false(bool(r["ok"]))
	assert_true(str(r["text"]).begins_with("Eksik:"), str(r["text"]))
	assert_true(str(r["text"]).contains("Ot"), "Eksik ot yazılır: %s" % r["text"])


func test_eating_special_foods_heals_and_buffs_are_capped_at_two() -> void:
	var inv := Inventory.new()
	inv.add("herb_tea", 1)
	inv.add("bone_broth", 1)
	inv.add("stew", 1)
	inv.add("spit_meat", 1)
	inv.add("ember_fish", 1)
	var s := Survival.new({"inventory": inv, "difficulty": "story"})
	s.wounds.add(3)
	var sta := watch_signal(s.stamina_gained)
	var hp := watch_signal(s.hp_gained)
	s.eat("herb_tea")
	assert_eq(s.wounds.count, 2, "Bozkır Çayı Yara −1")
	assert_eq(sta.count, 1, "Stamina +30")
	assert_almost(float(sta.last_args[0]), 30.0, 1e-9)
	s.eat("bone_broth")
	assert_eq(s.wounds.count, 1, "Kemik Suyu Yara −1")
	assert_almost(float(hp.last_args[0]), 30.0, 1e-9, "Can +30")
	s.eat("stew")
	s.eat("spit_meat")
	s.eat("ember_fish")
	assert_eq(s.buffs.size(), 2, "En çok 2 süreli etki")
	assert_eq(str(s.buffs[0]["item"]), "spit_meat", "Yenisi en eskisini siler (Yahni gitti)")
	assert_almost(float(s.buff_block()["eye"]), 1.0, 1e-9, "Korda Balık Göz +1")
	s.step(130.0)
	s.step(130.0)
	assert_eq(s.buffs.size(), 0, "Süre bitince etki kalkar")


func test_raw_meat_spoils_on_the_second_dawn_cooked_does_not() -> void:
	var inv := Inventory.new()
	var clock := GameClock.new(1171, 600.0)
	clock.set_place(Daylight.CAMP_LAT, Daylight.CAMP_DEC_OFFSET)
	var s := Survival.new({"inventory": inv, "clock": clock})
	s.on_dawn({})
	inv.add("meat", 2)
	inv.add("spit_meat", 1)
	clock.skip(clock.next(&"dawn") - clock.abs_minute() + 1.0, &"wait")
	s.on_dawn({})
	assert_eq(inv.count("meat"), 2, "İlk şafakta çiğ et durur")
	clock.skip(clock.next(&"dawn") - clock.abs_minute() + 1.0, &"wait")
	s.on_dawn({})
	assert_eq(inv.count("meat"), 0, "İkinci şafakta bozulur")
	assert_eq(inv.count("spoiled"), 2, "Bozuk Et")
	assert_eq(inv.count("spit_meat"), 1, "Pişmiş bozulmaz")
	s.on_dawn({})
	assert_eq(inv.count("spoiled"), 2, "Aynı şafak iki kez işlenmez")
