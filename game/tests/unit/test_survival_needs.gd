extends TestCase
## Tokluk, Yara ve Düşüş (Yol Haritası hunger-wounds; economy.md §5.1–§5.3, progression.md §3, §8.5, survival.md §2.7, time.md §10.5):
## Needs prototipin needs.js'iyle altın değerlerde aynı (tests/fixtures/needs.json, birikimli benzetim 1e-6); açlık öldürmez, oyunu
## durdurmaz ve Düşüş açmaz; yara sınırı zorluğundur, Can 0 yara yazar, sınır dolunca Umay Eşiği'nin planı (erzak bedeli, Kut ve Muska,
## uyanış yarası, ilk Düşüş kartı); ateş başı dinlenme ve uyku yarayı kapatır.

const ProtoFixture := preload("res://tests/support/proto_fixture.gd")


func after_each() -> void:
	Needs.reset_cache()


# --- Prototipin altın değerleri --------------------------------------------------------------------------

func test_needs_matches_the_prototype_fixture() -> void:
	var fx := ProtoFixture.load_fixture("needs")
	assert_false(fx.is_empty(), "tests/fixtures/needs.json var (node tools/proto_fixtures/survival.mjs)")
	if fx.is_empty():
		return
	var items: Dictionary = fx.get("items", {})
	var n := ProtoFixture.run_cases(self, fx, {
		"bandOf": func(a: Array) -> Variant: return Needs.band_of(float(a[0])),
		"foodK": func(a: Array) -> Variant: return Needs.food_k(a[0] if a[0] != null else "normal"),
		"rate": func(a: Array) -> Variant:
			var mods: Variant = a[2]
			var needs := Needs.new({"diff": str(a[0]), "mod": _mod_of(mods)})
			return needs.rate(_opts(a[1])),
		"script": func(a: Array) -> Variant: return _run_script(a[0], a[1], items),
	})
	assert_eq(n, ProtoFixture.count_cases(fx, "bandOf") + ProtoFixture.count_cases(fx, "foodK") + ProtoFixture.count_cases(fx, "rate")
		+ ProtoFixture.count_cases(fx, "script"), "Bütün durumlar koştu")
	assert_true(n >= 60, "Durum sayısı: %d" % n)
	var c: Dictionary = fx["constants"]
	for key: String in ["max", "start", "sated", "hungry", "rest", "sleep"]:
		assert_almost(Needs.value(key), float(c["FULLNESS"][key]), 1e-9, "needs.json %s prototipin FULLNESS'iyle aynı" % key)
	assert_almost(Needs.value("per_hour"), float(c["FULLNESS"]["perHour"]), 1e-9)
	assert_almost(Needs.value("last_night"), float(c["FULLNESS"]["lastNight"]), 1e-9)
	for band: String in ["sated", "hungry", "spent"]:
		var proto_band: Dictionary = c["BAND_EFFECTS"][band]
		var ours := Needs.band_effects(band)
		for k: String in proto_band:
			assert_almost(float(ours.get(k, -1.0)), float(proto_band[k]), 1e-9, "%s bandının %s'i" % [band, k])


func _mod_of(mods: Variant) -> Callable:
	if not mods is Dictionary:
		return Callable()
	return func(key: String, def: Variant) -> Variant: return (mods as Dictionary).get(key, def)


func _opts(o: Variant) -> Dictionary:
	var out := {}
	if o is Dictionary:
		for k: String in o:
			out[{"lastNight": "last_night"}.get(k, k)] = o[k]
	return out


func _run_script(ctor: Dictionary, ops: Array, items: Dictionary) -> Array:
	var opts := {"items": items, "diff": str(ctor.get("diff", "normal")), "enabled": bool(ctor.get("enabled", true))}
	if ctor.has("fullness"):
		opts["fullness"] = float(ctor["fullness"])
	if ctor.get("mods") is Dictionary:
		opts["mod"] = _mod_of(ctor["mods"])
	if ctor.has("lastNight") and ctor["lastNight"] != null:
		var last := bool(ctor["lastNight"])
		opts["last_night"] = func() -> bool: return last
	var n := Needs.new(opts)
	var bands: Array = []
	n.band_changed.connect(func(b: String) -> void: bands.append(["need:band", b]))
	var out: Array = [{"op": ["new"], "ret": null, "fullness": n.fullness, "band": n.band()}]
	for op: Array in ops:
		var ret: Variant = null
		match str(op[0]):
			"update":
				ret = n.update(float(op[1]), _opts(op[2] if op.size() > 2 else {}))
			"eat":
				ret = n.eat(str(op[1]), int(op[2]))
			"add":
				ret = n.add(float(op[1]))
			"fromJSON":
				n.from_dict(op[1])
			"toJSON":
				ret = n.to_dict()
			"enabled":
				n.enabled = bool(op[1])
		out.append({"op": op, "ret": ret, "fullness": n.fullness, "band": n.band(), "bands": bands.duplicate()})
		bands.clear()
	return out


# --- Tokluk'un kuralları (belgenin sayıları) ------------------------------------------------------------------------

func test_fullness_follows_the_clock_and_difficulty() -> void:
	var n := Needs.new({"diff": "normal"})
	assert_almost(n.fullness, 60.0, 1e-9, "Başlangıç 60")
	n.update(60.0)
	assert_almost(n.fullness, 55.0, 1e-9, "Uyanık −5 / oyun saati")
	n.update(240.0, {"rest": true})
	assert_almost(n.fullness, 45.0, 1e-9, "Ateş başında dinlenme ×0,5")
	n.update(480.0, {"sleep": true})
	assert_almost(n.fullness, 35.0, 1e-9, "Uyku ×0,25 (8 sa −10)")
	var day := Needs.new({"diff": "normal", "fullness": 100.0})
	day.update(16.0 * 60.0)
	day.update(8.0 * 60.0, {"sleep": true})
	assert_almost(day.fullness, 10.0, 1e-9, "Kışlak günü: 16 sa uyanık + 8 sa uyku −90")
	assert_almost(Needs.new({"diff": "story"}).rate(), 5.0 / 60.0 * 0.7, 1e-12, "Hikâye ×0,7")
	assert_almost(Needs.new({"diff": "hard"}).rate(), 5.0 / 60.0 * 1.15, 1e-12, "Zor ×1,15")
	var roam := Needs.new({"enabled": false})
	roam.update(600.0)
	assert_almost(roam.fullness, 60.0, 1e-9, "Serbest Gez'de Tokluk yoktur")


func test_bands_and_their_effects() -> void:
	var n := Needs.new({"fullness": 80.0})
	assert_eq(n.band(), "sated")
	assert_almost(float(n.effects()["staRegen"]), 1.15, 1e-9, "Tok: dolum ×1,15")
	var w := watch_signal(n.band_changed)
	n.update(60.0 * 2.0)
	assert_eq(n.band(), "ok")
	n.update(60.0 * 9.0)
	assert_eq(n.band(), "ok", "25 henüz Aç değil")
	n.update(30.0)
	assert_eq(n.band(), "hungry", "<25 Aç")
	assert_almost(float(n.effects()["staRegen"]), 0.6, 1e-9, "Aç: dolum ×0,6")
	assert_almost(float(n.effects()["run"]), 0.95, 1e-9, "Aç: koşu ×0,95")
	n.update(600.0)
	assert_eq(n.band(), "spent", "0 Bitkin")
	assert_almost(float(n.effects()["hpRegen"]), 0.5, 1e-9, "Bitkin: Can dolumu ×0,5")
	assert_almost(float(n.effects()["runCost"]), 1.25, 1e-9, "Bitkin: koşu gideri ×1,25")
	assert_eq(w.count, 3, "Her bant geçişi bir kez yayılır")
	assert_almost(n.fullness, 0.0, 1e-9, "Açlık sıfırda durur, öldürmez")
	assert_eq(Needs.band_name("hungry"), "Aç")
	assert_eq(Needs.band_name("spent", "en"), "Spent")
	assert_eq(Needs.band_name("ok"), "", "Orta bandın adı yok")


func test_eating_quality_share_and_hearth_craft() -> void:
	var n := Needs.new({"fullness": 0.0})
	assert_almost(n.eat("spit_meat", 3), 39.0, 1e-9, "Şiş Et ★3: 30 × 1,3")
	assert_almost(n.eat("spit_meat", 1), 23.0, 1e-9, "★1: 30 × 0,75 = 22,5 → 23 (yarım yukarı)")
	assert_almost(n.eat("meal", 2, true), 32.0, 1e-9, "Ocağa Pay: 35 × 0,9 = 31,5 → 32")
	var crafted := Needs.new({"fullness": 0.0, "mod": func(k: String, d: Variant) -> Variant: return 1.5 if k == "mealFull" else d})
	assert_almost(crafted.eat("meal", 2), 53.0, 1e-9, "Ocak Bilgisi: Aş +53 (economy.md §5.2)")
	assert_almost(n.eat("stone", 2), 0.0, 1e-9, "Yiyecek olmayan Tokluk vermez")
	assert_almost(Needs.fullness_of("burnt"), 5.0, 1e-9, "Yanık +5")


# --- Yara ve Düşüş ------------------------------------------------------------------------------------------------

func test_wound_limit_follows_difficulty_and_hp_zero_writes_a_wound() -> void:
	assert_eq(Wounds.new("story").limit(), 5)
	assert_eq(Wounds.new("normal").limit(), 3)
	assert_eq(Wounds.new("hard").limit(), 2)
	var w := Wounds.new("normal")
	var fell := watch_signal(w.fell)
	assert_false(w.hit_zero(), "Can 0: Yara +1, Düşüş yok")
	assert_eq(w.count, 1)
	assert_almost(Wounds.hp_after_zero(), 0.5, 1e-9, "Can %50'ye döner")
	assert_false(w.add(1))
	assert_true(w.hit_zero(), "Üçüncü yara Normal'de Düşüş")
	assert_eq(fell.count, 1)
	var plan: Dictionary = fell.last_args[0]
	assert_almost(float(plan["skip_min"]), 120.0, 1e-9, "Uyanış +2 oyun saati")
	assert_eq(int(plan["cost"]), 1, "Normal'de 1 erzak")
	assert_eq(int(plan["wake_wounds"]), 1, "Normal'de 1 yarayla uyanılır")
	assert_true(bool(plan["first"]), "İlk Düşüş")
	assert_eq(Catalog.pick(plan["card"], "tr"), "Umay.", "İlk Düşüş kartı tek söz")
	var after := w.fall()
	assert_eq(w.count, 1)
	assert_eq(w.falls, 1)
	assert_false(bool(w.fall_plan()["first"]), "İkinci Düşüş kart yazmaz")
	assert_eq(int(after["cost"]), 1)


func test_fall_cost_by_difficulty_kut_and_amulet() -> void:
	assert_eq(int(Wounds.new("story").fall_plan()["cost"]), 0, "Hikâye'de bedel yok")
	assert_eq(int(Wounds.new("story").fall_plan()["wake_wounds"]), 0, "Hikâye'de 0 yarayla uyanılır")
	assert_eq(int(Wounds.new("hard").fall_plan()["cost"]), 2, "Zor'da 2 erzak")
	assert_eq(int(Wounds.new("normal").fall_plan({"kut": 5})["cost"]), 0, "Kut ≥5 erzak almaz")
	assert_eq(int(Wounds.new("normal").fall_plan({"kut": 4})["cost"]), 1)
	assert_eq(int(Wounds.new("hard").fall_plan({"amulet": true})["cost"]), 0, "Geyik Muskası erzak almaz")


func test_rest_and_sleep_close_wounds() -> void:
	var w := Wounds.new("story")
	w.add(4)
	assert_eq(w.rest(119.0, 60.0, 1000.0), 0, "2 saatten kısa dinlenme kapatmaz")
	assert_eq(w.rest(180.0, 24.0, 1200.0), 0, "Tokluk <25 kapatmaz")
	assert_eq(w.rest(180.0, 25.0, 1400.0), 1, "≥2 saat, Tokluk ≥25: Yara −1")
	assert_eq(w.rest(180.0, 60.0, 1600.0), 0, "6 oyun saatinde bir: 200 dk sonra yeni kapanış yok")
	assert_eq(w.count, 3)
	assert_eq(w.rest(720.0, 60.0, 1400.0 + 1100.0), 2, "12 saatlik dinlenmede iki kapanış (6 saat arayla)")
	assert_eq(w.count, 1)
	w.add(2)
	assert_eq(w.sleep(239.0), 0, "4 saatten kısa uyku kapatmaz")
	assert_eq(w.sleep(480.0, true), 0, "Uyku Zarı'nın kestiği uyku kapatmaz")
	assert_eq(w.sleep(240.0), 3, "≥4 oyun saati uyku hepsini kapatır")
	assert_eq(w.count, 0)
	var fx := Wounds.effects_of(2)
	assert_almost(float(fx["sta"]), -16.0, 1e-9, "Açık yara başına stamina −8")
	assert_almost(float(fx["run"]), 0.94, 1e-9, "koşu −%3")
	assert_almost(float(fx["hp_regen"]), 0.5, 1e-9, "Can dolumu −%25")


func test_hunger_never_opens_the_threshold() -> void:
	var s := Survival.new({"difficulty": "normal"})
	var fell := watch_signal(s.fell)
	s.needs.update(10000.0)
	assert_eq(s.needs.band(), "spent")
	for i in 600:
		s.step(1.0)
	assert_eq(fell.count, 0, "Açlık Umay Eşiği açmaz")
	assert_eq(s.wounds.count, 0, "Açlık yara yazmaz")


func test_apply_fall_takes_the_cheapest_food_and_moves_the_clock() -> void:
	var inv := Inventory.new()
	inv.add("meal", 2)
	inv.add("millet", 3)
	inv.add("meat", 1)
	var clock := GameClock.new(1171, 600.0)
	var s := Survival.new({"difficulty": "normal", "inventory": inv, "clock": clock})
	var fell := watch_signal(s.fell)
	s.on_hp_zero()
	s.on_hp_zero()
	s.on_hp_zero()
	assert_eq(fell.count, 1, "Üç yarada Düşüş")
	var before := clock.abs_minute()
	var plan := s.apply_fall()
	assert_almost(clock.abs_minute() - before, 120.0, 1e-6, "Saat +2 oyun saati")
	assert_eq(s.wounds.count, 1, "1 yarayla uyanış")
	assert_eq((plan["lost"] as Array).size(), 1, "1 erzak eksik")
	assert_eq(str(plan["lost"][0]["id"]), "millet", "En az Kıymetli yiyecek gider (Darı 2)")
	assert_eq(inv.count("millet"), 2)
	assert_eq(inv.count("meal"), 2, "Aş kalır")
	var kut := Survival.new({"difficulty": "normal", "inventory": inv, "clock": clock})
	kut.kut_source = func() -> int: return 6
	kut.wounds.add(3)
	assert_eq((kut.apply_fall()["lost"] as Array).size(), 0, "Kut ≥5 erzak almaz")
