extends TestCase
## Kamp ateşi (Yol Haritası fire-hunting; survival.md §2, K35, K45; weather.md §8.5; time.md §10.2): yakıt ve evreler (720 sn taşsız
## 4 sa 48 dk, taşlı 7 sa 12 dk), Y ile yakıt (tezek, dal, odun; doluyken malzeme gitmez, yalnız sığan kısım sayılır), hava (yağmur
## ×1,5, taşsız ateş fırtınada 40 sn'de söner, taş halkası korur), çukur (24 oyun saati, 30 m erteleme, uzun atlama, zon başına 6),
## yeniden yakma (1 odun ya da 2 tezek, kavsız), Küle Yatır (yalnız Kor; ertesi doğuş + 1 sa), söndürme, Ocağa Pay (×0,9, günde bir),
## yer seçimi, kayıt gidiş dönüşü.

const NOW := 1171.0 * 1440.0 + 886.18


func _fx(fire_k: float, ring: float, out_s: float, type := "clear") -> Dictionary:
	return {"type": type, "fire_k": fire_k, "fire_ring": ring, "fire_out_s": out_s}


## Ateşi söndene dek yürütür (yakıt saniyesi adımlarıyla). Döner: yanma süresi (yakıt saniyesi).
func _burn_out(f: FireState, fx: Variant = null, step := 1.0, day := -1) -> float:
	var t := 0.0
	var now := NOW
	while f.is_lit() and t < 100000.0:
		now += step / FireState.minute_s()
		f.advance(step, now, fx, day)
		t += step
	return t


func test_full_fire_burns_four_hours_forty_eight_and_stones_seven_twelve() -> void:
	var f := FireState.new()
	f.light(Vector2.ZERO, "testmap", false, FireState.fuel_max(), NOW)
	assert_almost(FireState.fuel_max(), 720.0, 1e-9, "En çok 720 sn")
	assert_almost(f.burn_left(), 720.0, 1e-9)
	assert_almost(f.burn_left() / FireState.minute_s() / 60.0, 4.8, 1e-9, "Taşsız 4 sa 48 dk")
	var s := FireState.new()
	s.light(Vector2.ZERO, "testmap", true, FireState.fuel_max(), NOW)
	assert_almost(s.burn_left() / FireState.minute_s() / 60.0, 7.2, 1e-9, "Taş halkasıyla 7 sa 12 dk")
	var ev := s.advance(1080.0 + 5.0, NOW + 434.0, null)
	assert_true(s.is_pit(), "Yakıtı biten ateş çukur olur")
	assert_eq(str(ev["reason"]), "fuel")
	assert_almost(float(ev["at"]), NOW + 434.0 - 5.0 / 2.5, 1e-9, "Sönüş anı adımın içinden hesaplanır")
	assert_almost(_burn_out(f, null, 0.5), 720.0, 0.5, "Adım adım da 720 sn")


func test_stages_by_fuel_and_fuel_seconds() -> void:
	assert_eq(FireState.stage_of(0.0), &"embers")
	assert_eq(FireState.stage_of(59.9), &"embers", "<60 Kor")
	assert_eq(FireState.stage_of(60.0), &"small")
	assert_eq(FireState.stage_of(239.9), &"small")
	assert_eq(FireState.stage_of(240.0), &"steady")
	assert_eq(FireState.stage_of(480.0), &"steady")
	assert_eq(FireState.stage_of(480.1), &"blaze", ">480 Büyük")
	assert_almost(float(FireState.stage_row_of(&"small")["light_m"]), 6.0, 1e-9, "Küçük 6 m")
	assert_almost(float(FireState.stage_row_of(&"steady")["light_m"]), 10.0, 1e-9, "Orta 10 m")
	assert_almost(float(FireState.stage_row_of(&"blaze")["light_m"]), 14.0, 1e-9, "Büyük 14 m")
	assert_almost(FireState.fuel_seconds("dung"), 180.0, 1e-9, "Tezek 180 sn (1 sa 12 dk)")
	assert_almost(FireState.fuel_seconds("branch"), 60.0, 1e-9, "Dal 60 sn (24 dk)")
	assert_almost(FireState.fuel_seconds("wood"), 240.0, 1e-9, "Odun 240 sn (1 sa 36 dk)")
	var ids: Array = FireState.fuels().map(func(r: Dictionary) -> String: return str(r["id"]))
	assert_eq(ids, ["dung", "branch", "wood"], "Sıra Yük verimine göre: tezek, dal, odun")
	var f := FireState.new()
	var seen: Array = []
	f.stage_changed.connect(func(s: StringName) -> void: seen.append(s))
	f.light(Vector2.ZERO, "z", false, 500.0, NOW)
	assert_eq(f.stage(), &"blaze")
	f.advance(30.0, NOW + 12.0)
	assert_eq(f.stage(), &"steady", "470 sn: Orta")
	assert_almost(f.light_m(), 10.0, 1e-9)
	f.advance(415.0, NOW + 200.0)
	assert_eq(f.stage(), &"embers", "55 sn: Kor")
	assert_eq(seen, [&"blaze", &"steady", &"embers"], "Evre değişimleri sırayla yayılır")


func test_adding_fuel_counts_only_what_fits_and_full_fire_refuses() -> void:
	var f := FireState.new()
	f.light(Vector2.ZERO, "z", false, 600.0, NOW)
	var r := f.add_fuel(180.0)
	assert_almost(float(r["added"]), 120.0, 1e-9, "Yalnız sığan kısım sayılır (600 → 720)")
	assert_true(f.is_full())
	r = f.add_fuel(60.0)
	assert_true(bool(r["full"]), "Doluyken eklenmez («Ateş dolu.»)")
	assert_almost(float(r["added"]), 0.0, 1e-9)
	var inv := Inventory.new()
	inv.add("dung", 2)
	var s := Survival.new({"inventory": inv})
	var msgs: Array = []
	s.message.connect(func(t: String, _k: String) -> void: msgs.append(t))
	var g := s.fires.add(Vector2.ZERO, s.zone, false, 720.0, 0.0)
	var res := s.feed(g)
	assert_false(bool(res["ok"]))
	assert_eq(str(res["text"]), "Ateş dolu.", "Doluyken Y «Ateş dolu.» yazar")
	assert_eq(inv.count("dung"), 2, "Malzeme gitmez")
	g.fuel = 400.0
	res = s.feed(g)
	assert_true(bool(res["ok"]))
	assert_eq(inv.count("dung"), 1, "Bir tezek gitti")
	assert_almost(g.fuel, 580.0, 1e-9, "+180 sn")
	assert_eq(str(res["text"]), "Tezek eklendi.")
	res = s.feed(g)
	assert_almost(g.fuel, 720.0, 1e-9, "Fazlası sayılmaz")
	assert_eq(inv.count("dung"), 0, "Yakıt harcanır")
	g.fuel = 100.0
	res = s.feed(g)
	assert_false(bool(res["ok"]), "Yakıt yoksa eklenmez")


func test_fuel_slice_order_and_cycle() -> void:
	var inv := Inventory.new()
	inv.add("branch", 3)
	inv.add("wood_pine", 1)
	var s := Survival.new({"inventory": inv})
	var f := s.fires.add(Vector2.ZERO, s.zone, false, 100.0, 0.0)
	assert_eq(s.fuel_order(), PackedStringArray(["dung", "branch", "wood"]))
	assert_eq(str(s.feed(f)["fuel"]), "branch", "Tezek yoksa dal")
	assert_eq(s.cycle_fuel(), "branch", "Dilim tezek → dal")
	assert_eq(s.cycle_fuel(), "wood")
	assert_eq(str(s.feed(f)["fuel"]), "wood", "Dilim odunsa önce odun")
	assert_eq(inv.count("tag:wood"), 0)
	assert_eq(s.cycle_fuel(), "dung", "Odun → tezek")


func test_weather_multiplies_and_storm_puts_out_a_stoneless_fire() -> void:
	var rain := _fx(1.5, 1.25, 0.0, "rain")
	assert_almost(FireState.weather_k(false, rain), 1.5, 1e-9, "Yağmurda taşsız ×1,5")
	assert_almost(FireState.weather_k(true, rain), 1.25, 1e-9, "Taşlı ×1,25")
	var f := FireState.new()
	f.light(Vector2.ZERO, "z", false, 720.0, NOW)
	assert_almost(f.burn_left(rain), 480.0, 1e-9, "720 / 1,5")
	var gale := _fx(1.0, 1.5, 40.0, "gale")
	var g := FireState.new()
	g.light(Vector2.ZERO, "z", false, 720.0, NOW)
	assert_almost(_burn_out(g, gale, 0.25), 40.0, 0.26, "Fırtınada taşsız ateş 40 sn'de söner")
	assert_true(g.is_pit())
	var st := FireState.new()
	st.light(Vector2.ZERO, "z", true, 720.0, NOW)
	st.advance(60.0, NOW + 24.0, gale)
	assert_true(st.is_lit(), "Taş halkası fırtınada korur")
	assert_almost(st.fuel, 720.0 - 60.0 * (2.0 / 3.0) * 1.5, 1e-6, "Taşlı ×1,5")
	var calm := FireState.new()
	calm.light(Vector2.ZERO, "z", false, 720.0, NOW)
	calm.advance(30.0, NOW + 12.0, gale)
	calm.advance(30.0, NOW + 24.0, null)
	calm.advance(30.0, NOW + 36.0, gale)
	assert_true(calm.is_lit(), "Hava dinince açıkta kalış sıfırlanır")
	assert_eq(str(Survival.new().weather_type()), "clear")


func test_pit_waits_twenty_four_hours_and_the_nearby_player_holds_it() -> void:
	var set := FireSet.new()
	var f := set.add(Vector2(10.0, 0.0), "z", false, 60.0, NOW)
	f.advance(60.0, NOW + 24.0)
	assert_true(f.is_pit())
	assert_almost(f.pit_expires_at(), NOW + 24.0 + 1440.0, 1e-9, "Sönüşten 24 oyun saati")
	assert_true(set.prune(NOW + 1000.0).is_empty(), "24 saat dolmadan kalkmaz")
	assert_true(set.prune(NOW + 1500.0, Vector2(30.0, 0.0), "z").is_empty(), "Oyuncu 30 m içindeyse ertelenir")
	assert_eq(set.prune(NOW + 1500.0, Vector2(41.0, 0.0), "z").size(), 1, "Uzaklaşınca kalkar")
	assert_eq(set.fires.size(), 0)
	var a := set.add(Vector2.ZERO, "z", false, 10.0, NOW)
	a.advance(10.0, NOW + 4.0)
	var old := set.add(Vector2(20.0, 0.0), "z", true, 10.0, NOW, true, "old_hearth")
	old.advance(30.0, NOW + 12.0)
	assert_eq(set.on_long_skip().size(), 1, "24 saatten uzun atlama bütün çukurları kaldırır")
	assert_eq(set.fires, [old], "Eski Ocak kalır")
	assert_eq(old.pit_expires_at(), INF, "Eski Ocak'ın çukuru kalıcıdır")


func test_zone_holds_six_and_the_oldest_pit_goes_first() -> void:
	var set := FireSet.new()
	var made: Array[FireState] = []
	for i in 6:
		made.append(set.add(Vector2(i * 10.0, 0.0), "z", false, 720.0, NOW + i))
	set.add(Vector2(500.0, 0.0), "other", false, 720.0, NOW)
	set.add(Vector2(-50.0, 0.0), "z", true, 720.0, NOW, true, "old_1")
	made[3].advance(720.0, NOW + 300.0)
	made[4].advance(720.0, NOW + 300.0)
	var seventh := set.add(Vector2(70.0, 0.0), "z", false, 720.0, NOW + 10.0)
	assert_eq(set.count("z"), 6, "Zonda en çok 6 (Eski Ocak sayılmaz)")
	assert_false(set.fires.has(made[3]), "En eski çukur gider")
	assert_true(set.fires.has(made[4]) and set.fires.has(made[0]), "Ötekiler kalır")
	set.add(Vector2(80.0, 0.0), "z", false, 720.0, NOW + 11.0)
	assert_false(set.fires.has(made[4]), "Sonra kalan çukur")
	set.add(Vector2(90.0, 0.0), "z", false, 720.0, NOW + 12.0)
	assert_false(set.fires.has(made[0]), "Çukur yoksa en eski ateş")
	assert_true(set.fires.has(seventh))
	assert_not_null(set.by_id("old_1"), "Eski Ocak silinmez")
	assert_eq(set.count("other"), 1, "Öteki zon sayılmaz")


func test_relight_pit_with_one_log_or_two_dung_and_a_lighter() -> void:
	var inv := Inventory.new()
	var s := Survival.new({"inventory": inv})
	var f := s.fires.add(Vector2.ZERO, s.zone, false, 10.0, 0.0)
	f.advance(10.0, 4.0)
	assert_true(f.is_pit())
	inv.add("dung", 2)
	var r := s.feed(f)
	assert_false(bool(r["ok"]), "Yakıcı gerek")
	assert_eq(str(r["text"]), "Çakmak taşı, köz ya da meşale gerek.")
	inv.add("firestriker", 1)
	inv.remove("dung", 1)
	r = s.relight(f)
	assert_eq(str(r["text"]), "Çukur için odun ya da iki tezek gerek.", "Tek tezek yetmez")
	inv.add("dung", 1)
	r = s.feed(f)
	assert_true(bool(r["ok"]), "İki tezek, kav istemez")
	assert_true(f.is_lit())
	assert_almost(f.fuel, 360.0, 1e-9, "2 × 180 sn")
	assert_eq(inv.count("dung"), 0)
	assert_true(inv.has_tool("firestriker"), "Çakmak taşı gitmez")
	f.douse(10.0)
	inv.add("wood_pine", 1)
	s.fuel_choice = "branch"
	assert_true(bool(s.feed(f)["ok"]), "Dal dilimindeyken tezek yoksa odun")
	assert_almost(f.fuel, 240.0, 1e-9, "1 odun 240 sn")


func test_bank_only_embers_until_sunrise_plus_one_hour_then_wake() -> void:
	var clock := GameClock.new(1171, 1200.0)
	clock.set_place(Daylight.CAMP_LAT, Daylight.CAMP_DEC_OFFSET)
	var inv := Inventory.new()
	inv.add("dung", 1)
	var s := Survival.new({"inventory": inv, "clock": clock})
	var f := s.fires.add(Vector2.ZERO, s.zone, false, 200.0, clock.abs_minute())
	assert_false(bool(s.bank(f)["ok"]), "Küçük ateş küle yatırılmaz")
	assert_eq(Survival.f_job(f), "douse")
	f.fuel = 50.0
	f.advance(0.001, clock.abs_minute())
	assert_eq(f.stage(), &"embers")
	assert_eq(Survival.f_job(f), "bank")
	var r := s.bank(f)
	assert_true(bool(r["ok"]))
	assert_true(f.is_banked())
	assert_almost(f.light_m(), 0.0, 1e-9, "Küllenmiş közün ışığı yok")
	var sunrise := clock.next(&"sunrise")
	assert_almost(f.bank_until, sunrise + 60.0, 1e-6, "Köz ertesi doğuştan 1 oyun saati sonrasına dek yaşar")
	var fuel := f.fuel
	f.advance(500.0, clock.abs_minute() + 200.0)
	assert_almost(f.fuel, fuel, 1e-9, "Yakıt sayacı durur")
	assert_true(f.is_banked())
	assert_true(bool(s.feed(f)["ok"]), "Y közü uyandırır")
	assert_true(f.is_lit())
	assert_eq(inv.count("dung"), 0, "1 yakıt")
	assert_almost(f.fuel, fuel + 180.0, 1e-9)
	var g := FireState.new()
	g.light(Vector2.ZERO, "z", false, 30.0, 0.0)
	g.bank(1000.0, 10.0)
	var ev := g.advance(1.0, 1000.5)
	assert_true(g.is_pit(), "Ömrü dolan köz olağan çukurdur")
	assert_eq(str(ev["reason"]), "bank_end")
	assert_almost(g.pit_expires_at(), 1000.0 + 1440.0, 1e-9, "Çukurun 24 saati közün ölümünden sayılır")


func test_douse_needs_water_and_leaves_a_pit() -> void:
	var inv := Inventory.new()
	var s := Survival.new({"inventory": inv})
	var f := s.fires.add(Vector2.ZERO, s.zone, false, 400.0, 0.0)
	assert_false(bool(s.douse(f)["ok"]), "Su ya da kar gerek")
	assert_true(bool(s.douse(f, true)["ok"]), "Yerde karla söner")
	assert_true(f.is_pit())
	var g := s.fires.add(Vector2(10.0, 0.0), s.zone, false, 400.0, 0.0)
	inv.add("waterskin", 1)
	assert_true(bool(s.douse(g)["ok"]))
	assert_eq(inv.count("waterskin"), 0, "Tulum boşalır")
	assert_eq(inv.count("skin_bag"), 1, "Boş Tulum kalır")


func test_hearths_share_lowers_the_days_burn_once_per_fire() -> void:
	var f := FireState.new()
	f.light(Vector2.ZERO, "z", false, 720.0, 0.0)
	assert_true(f.give_share(5))
	assert_false(f.give_share(5), "Ateş başına günde bir")
	assert_almost(f.burn_rate(null, 5), 0.9, 1e-9, "O günkü tüketim ×0,9")
	assert_almost(f.burn_rate(null, 6), 1.0, 1e-9, "Ertesi gün olağan")
	assert_true(f.can_share(6))


func test_place_rules() -> void:
	var set := FireSet.new()
	var flat := func(_x: float, _z: float) -> Vector3: return Vector3.UP
	var steep := func(_x: float, _z: float) -> Vector3: return Vector3(0.5, 0.8, 0.0)
	var dry := func(_x: float, _z: float) -> bool: return false
	var wet := func(_x: float, _z: float) -> bool: return true
	assert_eq(set.can_place(Vector2.ZERO, {"normal": flat, "water": dry}), "")
	assert_eq(set.can_place(Vector2.ZERO, {"normal": steep}), "slope", "normal.y < 0,9")
	assert_eq(set.can_place(Vector2.ZERO, {"normal": flat, "water": wet}), "water", "Su ve buz değil")
	assert_eq(set.can_place(Vector2.ZERO, {"indoor": true}), "near_structure", "Yapı içi değil")
	assert_eq(set.can_place(Vector2(9.0, 0.0), {"structures": [Vector3(0.0, 0.0, 3.5)]}), "near_structure", "Yapıya ≥6 m (kenarından)")
	assert_eq(set.can_place(Vector2(9.6, 0.0), {"structures": [Vector3(0.0, 0.0, 3.5)]}), "")
	assert_eq(set.can_place(Vector2(1.2, 0.0), {"obstacles": [Vector3(0.0, 0.0, 1.5)]}), "near_structure", "Eşyanın üstüne kurulmaz")
	assert_eq(set.can_place(Vector2(1.6, 0.0), {"obstacles": [Vector3(0.0, 0.0, 1.5)]}), "", "Eşya yapı sayılmaz: 6 m gerekmez")
	set.add(Vector2(20.0, 0.0), "z", false, 720.0, NOW)
	assert_eq(set.can_place(Vector2(25.0, 0.0), {"zone": "z"}), "near_fire", "Başka ateşe ≥6 m")
	assert_eq(set.can_place(Vector2(26.5, 0.0), {"zone": "z"}), "")
	assert_eq(set.can_place(Vector2(1.0, 0.0), {"olds": [Vector2(5.0, 0.0)]}), "near_fire", "Eski Ocak da ateş sayılır")
	assert_eq(FireState.text("slope"), "Burası düz değil.")
	assert_eq(FireState.text("full", "en"), "The fire is full.")


func test_build_plan_needs_fuel_tinder_lighter_and_respects_weather() -> void:
	var inv := Inventory.new()
	var s := Survival.new({"inventory": inv})
	assert_eq(str(s.build_plan(Vector2.ZERO)["reason"]), "fuel", "Yakıt yok")
	inv.add("dung", 4)
	assert_eq(str(s.build_plan(Vector2.ZERO)["reason"]), "tinder", "Kav yok")
	inv.add("reed", 1)
	assert_eq(str(s.build_plan(Vector2.ZERO)["reason"]), "lighter", "Yakıcı yok")
	inv.add("firestriker", 1)
	var plan := s.build_plan(Vector2.ZERO)
	assert_true(bool(plan["ok"]))
	assert_eq(str(plan["fuel"]), "dung")
	assert_eq(int(plan["fuel_n"]), 4, "4 tezek = 720 sn")
	assert_almost(float(plan["seconds"]), 5.0, 1e-9, "Dizme 2 + yakma 3 sn")
	s.fx_source = func() -> Variant: return {"type": "rain", "fire_k": 1.5, "fire_ring": 1.25, "fire_out_s": 0.0}
	assert_eq(str(s.build_plan(Vector2.ZERO)["reason"]), "tinder", "Yağmurda kuru saz ıslanır")
	inv.add("resin", 1)
	plan = s.build_plan(Vector2.ZERO)
	assert_true(bool(plan["ok"]), "Reçine kuru kavdır")
	assert_almost(float(plan["seconds"]), 7.0, 1e-9, "Yağmurda yakma 5 sn")
	s.fx_source = func() -> Variant: return {"type": "gale", "fire_k": 1.0, "fire_ring": 1.5, "fire_out_s": 40.0}
	assert_eq(str(s.build_plan(Vector2.ZERO)["text"]), "Bu rüzgârda taşsız ateş tutmaz.")
	s.fx_source = func() -> Variant: return {"type": "hail"}
	assert_eq(str(s.build_plan(Vector2.ZERO)["text"]), "Dolu altında ateş yakılmaz.")
	s.fx_source = Callable()
	var f := s.build(Vector2(3.0, 4.0), s.build_plan(Vector2(3.0, 4.0)))
	assert_not_null(f)
	assert_true(f.is_lit() and is_equal_approx(f.fuel, 720.0), "Yeni ateş dolu yanar")
	assert_eq(inv.count("dung"), 0, "4 tezek gitti")
	assert_eq(inv.count("tag:tinder"), 1, "Bir kav gitti")
	assert_true(inv.has_tool("firestriker"))
	inv.add("branch", 12)
	inv.add("reed", 1)
	var bag := inv.saddlebags("horse@Doru", 60.0)
	bag.add("stone", 6, 0)
	plan = s.build_plan(Vector2(30.0, 0.0), {"saddlebags": bag})
	assert_eq(str(plan["fuel"]), "branch", "12 dal")
	assert_true(bool(plan["stones"]), "6 taş varsa halka kurulur")
	assert_almost(float(plan["seconds"]), 7.0, 1e-9, "Taş halkası +2 sn")
	var g := s.build(Vector2(30.0, 0.0), plan)
	assert_true(g.stones)
	assert_eq(bag.count("stone"), 0, "Taşlar (terkiden) halkaya gider: 30 Yük sırta sığmaz")


func test_free_materials_for_the_child() -> void:
	var s := Survival.new({"free_materials": true, "mode": "roam"})
	var plan := s.build_plan(Vector2.ZERO)
	assert_true(bool(plan["ok"]), "Çocukta malzeme sayılmaz")
	var f := s.build(Vector2.ZERO, plan)
	f.fuel = 100.0
	assert_true(bool(s.feed(f)["ok"]))
	assert_false(s.needs.enabled, "Serbest Gez'de Tokluk yok")


func test_save_round_trip() -> void:
	var s := Survival.new({"difficulty": "hard"})
	var f := s.fires.add(Vector2(3.0, 4.0), s.zone, true, 300.0, 1000.0)
	f.give_share(2)
	var p := s.fires.add(Vector2(20.0, 4.0), s.zone, false, 10.0, 1001.0)
	p.advance(10.0, 1005.0)
	var b := s.fires.add(Vector2(40.0, 4.0), s.zone, false, 30.0, 1002.0)
	b.bank(3000.0, 1010.0)
	s.needs.fullness = 42.25
	s.wounds.add(1)
	s.known["stew"] = true
	s.made["meal"] = true
	s.hunted_kinds["marmot"] = 2
	var d := s.to_dict()
	assert_eq(Survival.validate_save_block(d), "")
	var text := JSON.stringify(d)
	var back := Survival.new({"difficulty": "hard"})
	assert_true(back.from_dict(JSON.parse_string(text)))
	assert_eq(back.fires.fires.size(), 3)
	var f2 := back.fires.by_id(f.id)
	assert_true(f2.is_lit() and f2.stones and is_equal_approx(f2.fuel, 300.0) and f2.share_day == 2)
	assert_eq(f2.stage(), &"steady")
	assert_true(back.fires.by_id(p.id).is_pit())
	assert_almost(back.fires.by_id(p.id).out_at, p.out_at, 1e-9)
	assert_true(back.fires.by_id(b.id).is_banked())
	assert_almost(back.fires.by_id(b.id).bank_until, 3000.0, 1e-9)
	assert_almost(back.needs.fullness, 42.25, 1e-9)
	assert_eq(back.wounds.count, 1)
	assert_true(back.known.has("stew") and back.known.has("spit_meat"), "Öğrenilen ve baştaki tarifler")
	assert_eq(int(back.hunted_kinds["marmot"]), 2)
	for key: String in ["recipes", "fires", "tents", "sleep", "snares"]:
		assert_true(d.has(key), "survival.md §7.10 alanı: %s" % key)
	var row: Dictionary = d["fires"][0]
	for key: String in ["zone", "x", "z", "fuel", "stones", "state", "out_at"]:
		assert_true(row.has(key), "survival.md §2.8 ateş alanı: %s" % key)
	assert_ne(Survival.validate_save_block({"fires": [{"state": "nope"}]}), "", "Bozuk ateş satırı")
	assert_ne(Survival.validate_save_block({"fires": 3}), "")
	assert_false(back.from_dict("bozuk"), "Bozuk blok okunmaz")
	assert_true(JSON.stringify(d).length() < 4096, "Blok küçük (%d bayt)" % JSON.stringify(d).length())


## Yerleşimin ocağı (deneme haritasının ortasındaki ateş): yanar ve yakıtı durur; beslenmez, söndürülmez, küle yatırılmaz; F'nin işi yoktur;
## zonun sayısına girmez, silinmez; kayda girmez ama kayıt okunurken yerinde kalır; taş halkalı ve kazanı hazırdır (Eski Ocak gibi);
## yanına 6 m'den yakın ateş kurulmaz.
func test_hearth_stays_lit_and_is_not_fed_doused_or_saved() -> void:
	var inv := Inventory.new()
	inv.add("dung", 4)
	inv.add("waterskin", 1)
	inv.add("millet", 2)
	var s := Survival.new({"inventory": inv, "zone": "testmap"})
	var h := s.fires.add_hearth(Vector2(0.0, -4.0), "testmap", "hearth_campfire")
	assert_true(h.is_lit() and h.hearth and h.old and h.stones, "Ocak yanar, taş halkalı")
	assert_eq(h.stage(), &"steady", "Orta evre")
	assert_eq(s.fires.add_hearth(Vector2(0.0, -4.0), "testmap", "hearth_campfire"), h, "Aynı ocak ikinci kez eklenmez")
	assert_true(h.advance(100000.0, NOW + 40000.0).is_empty() and h.is_lit(), "Yakıtı azalmaz, sönmez")
	assert_almost(h.fuel, 360.0, 1e-9)
	assert_almost(float(h.add_fuel(180.0)["added"]), 0.0, 1e-9, "Yakıt eklenmez")
	assert_false(h.douse(NOW) or h.bank(NOW + 600.0, NOW), "Söndürülmez, küle yatırılmaz")
	assert_eq(Survival.f_job(h), "", "F'nin işi yok")
	var fed := s.feed(h)
	assert_false(bool(fed["ok"]), "Y: halk besler")
	assert_eq(str(fed["text"]), FireState.text("hearth", "tr"))
	assert_eq(inv.count("dung"), 4, "Tezek gitmedi")
	assert_false(bool(s.douse(h)["ok"]), "Söndürülmez")
	assert_eq(inv.count("waterskin"), 1, "Tulum dolu kaldı")
	assert_eq(s.fires.count("testmap"), 0, "Zonun sayısına girmez")
	for i in 7:
		s.fires.add(Vector2(20.0 + 10.0 * i, 0.0), "testmap", false, 300.0, NOW + i)
	assert_not_null(s.fires.by_id("hearth_campfire"), "Zon dolunca silinmez")
	assert_eq(s.fires.can_place(Vector2(0.0, 0.5), {"zone": "testmap"}), "near_fire", "Ocağa 6 m'den yakın ateş kurulmaz")
	var stations: Array = s.cook_options(h).map(func(o: Dictionary) -> String: return "%s:%s" % [o["station"], o["reason"]])
	assert_true(stations.has("cauldron:") or stations.has("cauldron:missing"), "Kazan hazır: %s" % [stations])
	var d := s.to_dict()
	for row: Dictionary in d["fires"]:
		assert_true(str(row["id"]) != "hearth_campfire", "Ocak kayda girmez")
	assert_true(s.from_dict(JSON.parse_string(JSON.stringify(d))))
	assert_not_null(s.fires.by_id("hearth_campfire"), "Kayıt okunurken ocak yerinde kalır")
	assert_eq(s.fires.fires.filter(func(f: FireState) -> bool: return f.hearth).size(), 1, "Tek ocak")
