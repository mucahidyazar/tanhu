extends TestCase
## Türetilen değerler (Derive; progression.md §2.3, §2.4, §17.1): stat değer tablosu, kabul satırları (yük, çan, yara, yay, binek,
## Kül Borcu, Korku) ve prototipin altın değerleri (tests/fixtures/derive.json, 1e-9).

const ProtoFixture := preload("res://tests/support/proto_fixture.gd")


static func _stats(stat: String, value: float) -> Dictionary:
	var out := {"grip": 3.0, "wind": 3.0, "foot": 3.0, "eye": 3.0, "word": 3.0}
	out[stat] = value
	return out


func test_stat_table_section_2_4() -> void:
	# progression.md §2.4 (kabul tablosu, iki ondalık): puan 3–12.
	var rows := {
		3: [21, 1.00, 0, 100, 1.00, 17.0, 0.0, 2.20, 4.40, 7.60, 15.0, 15, 18, 1.00, 1.00, 1.00, 1.00],
		4: [24, 1.06, 2, 106, 1.04, 16.7, -0.2, 2.24, 4.45, 7.71, 14.5, 18, 19, 0.95, 1.02, 1.06, 0.97],
		5: [27, 1.12, 4, 112, 1.08, 16.3, -0.4, 2.29, 4.51, 7.83, 14.0, 21, 20, 0.90, 1.04, 1.12, 0.94],
		6: [30, 1.18, 6, 118, 1.12, 16.0, -0.6, 2.33, 4.56, 7.94, 13.5, 24, 21, 0.85, 1.06, 1.18, 0.91],
		7: [33, 1.24, 8, 124, 1.16, 15.6, -0.8, 2.38, 4.61, 8.06, 13.0, 27, 22, 0.80, 1.08, 1.24, 0.88],
		8: [36, 1.30, 10, 130, 1.20, 15.3, -1.0, 2.42, 4.66, 8.17, 12.5, 30, 23, 0.75, 1.10, 1.30, 0.85],
		9: [39, 1.36, 12, 136, 1.24, 15.0, -1.2, 2.46, 4.72, 8.28, 12.0, 33, 24, 0.70, 1.12, 1.36, 0.82],
		10: [42, 1.42, 14, 142, 1.28, 14.6, -1.4, 2.51, 4.77, 8.40, 11.5, 36, 25, 0.65, 1.14, 1.42, 0.79],
		11: [45, 1.48, 16, 148, 1.32, 14.3, -1.6, 2.55, 4.82, 8.51, 11.0, 39, 26, 0.60, 1.16, 1.48, 0.76],
		12: [48, 1.54, 18, 154, 1.36, 13.9, -1.8, 2.60, 4.88, 8.63, 10.5, 42, 27, 0.55, 1.18, 1.54, 0.73],
	}
	for pts: int in rows:
		var r: Array = rows[pts]
		var g := Derive.derive({"stats": _stats("grip", pts)})
		var w := Derive.derive({"stats": _stats("wind", pts)})
		var f := Derive.derive({"stats": _stats("foot", pts), "bell": {"on": false}})
		var e := Derive.derive({"stats": _stats("eye", pts)})
		var v := Derive.derive({"stats": _stats("word", pts)})
		assert_almost(g["loadMax"], r[0], 1e-9, "Yük, Bilek %d" % pts)
		assert_almost(g["meleeMul"], r[1], 0.005, "Vuruş ×, Bilek %d" % pts)
		assert_almost(g["hpMax"] - 100.0, r[2], 1e-9, "Can +, Bilek %d" % pts)
		assert_almost(w["staMax"], r[3], 1e-9, "Stamina, Soluk %d" % pts)
		assert_almost(w["staRegenK"], r[4], 0.005, "Dolum ×, Soluk %d" % pts)
		assert_almost(w["runDrain"], r[5], 0.051, "Koşu gideri, Soluk %d" % pts)
		assert_almost(f["noiseR"]["walk"] - 4.0, r[6], 1e-9, "Gürültü m, Ayak %d" % pts)
		assert_almost(f["crouch"], r[7], 0.005, "Çömelik, Ayak %d" % pts)
		assert_almost(f["walk"], r[8], 0.005, "Yürü, Ayak %d" % pts)
		assert_almost(f["run"], r[9], 0.005, "Koş, Ayak %d" % pts)
		assert_almost(f["dodgeCost"], r[10], 1e-9, "Savuş, Ayak %d" % pts)
		assert_almost(e["sense"], r[11], 1e-9, "Sezgi m, Göz %d" % pts)
		assert_almost(e["slingRange"], r[12], 1e-9, "Sapan m, Göz %d" % pts)
		assert_almost(e["spreadK"], r[13], 1e-9, "Yayılma ×, Göz %d" % pts)
		assert_almost(e["eyeK"], r[14], 1e-9, "Yay menzil ve hasar ×, Göz %d" % pts)
		assert_almost(v["trustGainK"], r[15], 0.005, "Güven ×, Söz %d" % pts)
		assert_almost(v["loyaltyK"], r[15], 0.005, "loyalty ×, Söz %d" % pts)
		assert_almost(v["barterK"], r[16], 0.005, "Takas ×, Söz %d" % pts)


func test_acceptance_rows() -> void:
	# Kabul 2: L1 stat 3 → loadMax 21, hpMax 100, staMax 100, yürü 4,4, koş 7,6, çömelik 2,2, sapan 18, sezgi 15.
	var d := Derive.derive({})
	assert_eq([d["loadMax"], d["hpMax"], d["staMax"], d["walk"], d["run"], d["crouch"], d["slingRange"], d["sense"]], [21.0, 100.0, 100.0, 4.4, 7.6, 2.2, 18.0, 15.0])
	# Kabul 4: Bilek 4'te yük 12/24 → loadMul 0,85; carry_pack sonrası 16/32 için 1,00; dolu 0,70.
	var grip4 := _stats("grip", 4.0)
	assert_almost(Derive.derive({"stats": grip4, "load": 12.0})["loadMul"], 0.85, 1e-12)
	var pack := {"load": 8, "slowFrom": {"set": 0.5}}
	assert_almost(Derive.derive({"stats": grip4, "load": 16.0, "mods": pack})["loadMul"], 1.0, 1e-12)
	assert_almost(Derive.derive({"stats": grip4, "load": 32.0, "mods": pack})["loadMul"], 0.7, 1e-12)
	# Kabul 5: çan, Ayak 3 ve 7 → yürü 14; 13,2; keçe tıkaç, Ayak 7: 4,8; çan yok koş, Ayak 7: 8,2.
	assert_almost(Derive.derive({"bell": {"on": true}})["noiseR"]["walk"], 14.0, 1e-12)
	assert_almost(Derive.derive({"stats": _stats("foot", 7.0), "bell": {"on": true}})["noiseR"]["walk"], 13.2, 1e-12)
	assert_almost(Derive.derive({"stats": _stats("foot", 7.0), "bell": {"on": true, "plug": true}})["noiseR"]["walk"], 4.8, 1e-12)
	assert_almost(Derive.derive({"stats": _stats("foot", 7.0), "bell": {"on": false}})["noiseR"]["run"], 8.2, 1e-12)
	# Kabul 6: snow_step, çömelik → gürültü 1,2.
	assert_almost(Derive.derive({"bell": {"on": true}, "mods": {"noiseCrouch": {"set": 1.2}}})["noiseR"]["crouch"], 1.2, 1e-12)
	# Kabul 7: Soluk 3, 2 yara → staMax 84; koşu ×0,94.
	var hurt := Derive.derive({"wounds": 2})
	assert_eq(hurt["staMax"], 84.0)
	assert_almost(hurt["run"] / 7.6, 0.94, 1e-12)
	# Kabul 14: pullF, heavy_bow (pull 7) Bilek 5 → 0,76; çekiş ×1,4.
	var heavy := {"id": "heavy_bow", "dmg": 38, "pull": 7, "draw": 1.0, "spread": 3.5, "range": 48}
	var bow := Derive.derive({"stats": _stats("grip", 5.0), "bow": heavy})
	assert_almost(bow["pullF"], 0.76, 1e-12)
	assert_almost(bow["drawT"], 1.4, 1e-12)
	# Kabul 16: Korku 4 → Güven kazancı ×0,9 (nöbetçi 0,5 sn).
	assert_almost(Derive.derive({"axes": {"korku": 4}})["trustGainK"], 0.9, 1e-12)
	assert_eq(Derive.dread_effects(4.0)["guardPause"], 0.5)
	# Kabul 25: L1, debt_erlik=ash, hearths_out 4 → hpMax 91; none ise 100.
	assert_eq(Derive.derive({"flags": {"debt_erlik": "ash"}, "axes": {"hearths_out": 4}})["hpMax"], 91.0)
	assert_eq(Derive.derive({"flags": {"debt_erlik": "none"}, "axes": {"hearths_out": 4}})["hpMax"], 100.0)
	# Kabul 26: Soluk 5, dururken, Patika, Tokluk ≥25 → staRegen 16,2.
	assert_almost(Derive.derive({"stats": _stats("wind", 5.0), "env": {"ground": "path"}, "fullness": 25.0})["staRegen"]["still"], 16.2, 1e-12)
	# Kabul 27: Bağ 40, Tipi dışı, eyerli → horseDrain 0,234; horseRegen 0,18; turnRate tepe hızda 2,8.
	var horse := Derive.derive({"bond": 40.0, "mount": {"base": 10.5, "saddled": true}})
	assert_almost(horse["horseDrain"], 0.234, 1e-12)
	assert_almost(horse["horseRegen"], 0.18, 1e-12)
	assert_almost(Derive.turn_rate_at(horse, float(horse["gallop"])), 2.8, 1e-12)
	# Yara sınırının bir altında Son Diş hızı (Normal 3: 2 yara).
	assert_true(Derive.derive({"wounds": 2, "mods": {"speed": 1.15}})["lastTooth"])
	assert_false(Derive.derive({"wounds": 1, "mods": {"speed": 1.15}})["lastTooth"])


func test_bow_ids_and_fine_work() -> void:
	var rows := {"hun_bow": {"dmg": 26, "pull": 5, "draw": 0.8, "spread": 3.5, "range": 40}}
	var plain := Derive.derive({"stats": _stats("grip", 5.0), "bow": "hun_bow", "bows": rows})
	var fine := Derive.derive({"stats": _stats("grip", 5.0), "bow": "hun_bow+", "bows": rows})
	assert_eq(plain["bow"], "hun_bow")
	assert_eq(fine["bow"], "hun_bow", "İnce İş kimliği taban yayı okur")
	assert_almost(fine["arrowK"], plain["arrowK"] * 1.1, 1e-12, "İnce İş ×1,1")
	assert_null(Derive.derive({"bow": "no_such_bow", "bows": rows})["drawT"], "Bilinmeyen yay yok sayılır")
	# Kimlik verilip tablo verilmezse Weapons tablosu okunur (oyuncak yay, pull 0: Bilek okumaz).
	var toy := Derive.derive({"bow": "toy_bow"})
	assert_eq(toy["bow"], "toy_bow")
	assert_eq(toy["pullF"], 1.0)
	assert_almost(toy["range"], float(Weapons.bow("toy_bow")["range"]), 1e-12)


func test_prototype_fixture() -> void:
	var fx := ProtoFixture.load_fixture("derive")
	assert_false(fx.is_empty(), "tests/fixtures/derive.json yok: node tools/proto_fixtures.mjs --only=progression")
	if fx.is_empty():
		return
	var handlers := {
		"derive": func(input: Dictionary) -> Variant: return Derive.derive(input),
		"mountLoadK": func(a: Array) -> Variant: return Derive.mount_load_k(a[0]),
		"stepWet": func(a: Array) -> Variant: return Derive.step_wet(a[0]),
		"turnRateAt": func(a: Array) -> Variant: return Derive.turn_rate_at(a[0], float(a[1])),
	}
	var n := ProtoFixture.run_cases(self, fx, handlers)
	assert_eq(n, (fx["cases"] as Array).size(), "Her durum koşuldu")
	assert_true(n >= 200, "En az 200 durum (%d)" % n)
	assert_eq(fx["constants"]["difficultyNormal"], Derive.NORMAL, "Zorluk verilmezse Normal satırı")
	# Prototipin Normal satırı oyunun zorluk tablosuyla aynı (data/character/difficulty.json).
	var normal: Dictionary = {}
	for row: Dictionary in CharacterOptions.data("difficulty").get("levels", []):
		if row["id"] == "normal":
			normal = row
	for key: String in ["staRegen", "woundLimit", "wetBowK"]:
		assert_eq(float(normal[key]), float(Derive.NORMAL[key]), "Normal.%s" % key)
