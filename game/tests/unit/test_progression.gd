extends TestCase
## İlerleme (Progression; progression.md §1, §2, §4, §13; act1.md §11; Yol Haritası levels-skills): seviye 20 ve perde tavanı (I. Perde
## 1–5), köken statlara işler (K104: Zırhlı Atlılar Arasında Bilek +1, Otağda Yetişen Söz +1, Yılkı Beyi Ayak +1 ve Bağ +10; eski
## kimlikler yenisine göçer), her beceriyi bir insan
## öğretir (usta istemeyen üç beceri dışında), insan öldürmek XP vermez; beceri tablosu (data/progression/skills.json) belgenin
## tablolarıyla aynıdır; kayıt bloğu gidiş dönüşü ve doğrulaması; prototipin altın değerleri (tests/fixtures/progress.json).

const ProtoFixture := preload("res://tests/support/proto_fixture.gd")
const DOC := "../docs/design/progression.md"
const MASTERLESS := ["lead_count", "two_tongues", "tumen_call"]
## progression.md §1.1: birikimli XP eşikleri (L1–L20).
const CURVE := [0, 250, 800, 1700, 3000, 4600, 6600, 9000, 11800, 15000, 18600, 22600, 27000, 31800, 37000, 42600, 48600, 55000, 61800, 69000]


func before_each() -> void:
	Progression.reset_cache()


func _new(origin: String = "origin_riders") -> Progression:
	var p := Progression.new()
	p.reset_player(origin)
	return p


func test_curve_and_act_caps() -> void:
	var p := _new()
	assert_eq(p.xp_curve.map(func(v: Variant) -> int: return int(v)), CURVE, "§1.1 eğrisi")
	assert_eq(p.level_caps.map(func(v: Variant) -> int: return int(v)), [5, 8, 11, 14, 17, 20], "Perde tavanları I 5 … VI 20")
	assert_eq(p.act_cap(), 5, "I. Perde 1–5")
	# Kabul 3: 250 / 2.865 / 4.575 → L2 / L4 / L5; 4.575'te L6 yok.
	p.add_xp(250)
	assert_eq(p.level, 2)
	p.add_xp(2865 - 250)
	assert_eq(p.level, 4, "Ana yol ve işler L4'te biter (2.865)")
	p.add_xp(4575 - 2865)
	assert_eq(p.level, 5, "Tam oyuncu L5")
	# Kabul 20: I. Perde'de 5.000 XP Sv 5'te durur; act_change(2) Sv 6 verir.
	p.add_xp(425)
	assert_eq([p.level, p.xp], [5, 5000], "Perde tavanı seviye atlamayı durdurur, XP'yi silmez")
	assert_eq([p.stat_points, p.skill_points], [4, 4], "Her seviye +1 stat, +1 beceri")
	assert_true(p.act_change(2))
	assert_eq(p.level, 6, "II. Perde'de biriken XP seviye verir")
	assert_eq(p.respec_tokens, 2, "II'den her perde başında 2 Ozan'a Anlattır hakkı")
	assert_false(p.act_change(2), "Aynı perdeye geçilmez")
	# Kabul 28: I'den 4.575 ile II, II'de 7.175 → 11.750, Sv 8'de durur; act_change(3) sonrası ilk 50 XP Sv 9 verir.
	var q := _new()
	q.add_xp(4575)
	q.act_change(2)
	q.add_xp(7175)
	assert_eq([q.xp, q.level], [11750, 8])
	q.act_change(3)
	assert_eq(q.level, 8)
	q.add_xp(50)
	assert_eq(q.level, 9)
	# Aşkın XP: L20'den sonra her 1.800 XP +1 beceri puanı, en çok 3.
	var r := _new()
	r.act_change(6)
	r.add_xp(69000)
	assert_eq(r.level, 20)
	var before := r.skill_points
	r.add_xp(1800 * 5)
	assert_eq(r.overflow_points, 3, "Aşkın puan en çok 3")
	assert_eq(r.skill_points - before, 3)


func test_xp_ratio_for_the_hud() -> void:
	var p := _new()
	assert_almost(p.xp_ratio(), 0.0, 1e-12)
	p.add_xp(125)
	assert_almost(p.xp_ratio(), 0.5, 1e-12, "L1'de 125 / 250")
	p.add_xp(125 + 275)
	assert_eq(p.level, 2)
	assert_almost(p.xp_ratio(), 0.5, 1e-12, "L2'de (525 − 250) / 550")
	assert_eq([p.xp_floor(), p.xp_next()], [250, 800])
	# HUD'un Vitals'ı ilerlemeye bağlanınca seviye ve çubuk ondan okunur.
	var v := Vitals.new()
	v.bind_progression(p)
	assert_eq(v.level, 2)
	assert_almost(v.xp_ratio(), p.xp_ratio(), 1e-12)
	var w := watch_signal(v.changed)
	v.add_xp(275)
	assert_eq([p.xp, v.xp, v.level], [800, 800, 3], "Vitals'a yazılan XP ilerlemeye gider, seviyeyi o atlatır")
	assert_true(w.fired)
	v.reset()
	assert_eq(v.level, 3, "Yeni beden seviyeyi ilerlemeden okur")
	v.bind_progression(null)
	v.reset()
	assert_eq(v.level, 1, "Bağ çözülünce yer tutucu eğri")


func test_origins_shape_the_stats() -> void:
	# Kabul 1: origin_herds (eski origin_stable) → statlar 3, 3, 4, 3, 3; Bağ 10; carry_pack öğrenilemez, neden usta.
	var p := _new("origin_herds")
	assert_eq(p.stats, {"grip": 3, "wind": 3, "foot": 4, "eye": 3, "word": 3})
	assert_eq(p.origin_bond(), 10.0, "Yılkı Beyi Bağ +10")
	assert_false(p.can_learn("carry_pack"))
	assert_eq(p.learn_block("carry_pack"), "master", "Her beceriyi bir usta öğretir")
	var load := _new("origin_riders")
	assert_eq(load.stats["grip"], 4, "Zırhlı Atlılar Arasında Bilek +1")
	assert_eq(load.origin_bond(), 0.0)
	var listener := _new("origin_tent")
	assert_eq(listener.stats["word"], 4, "Otağda Yetişen Söz +1")
	for o: Progression in [p, load, listener]:
		var total := 0
		for id: String in o.stats:
			total += int(o.stats[id])
		assert_eq(total + o.stat_points, 16, "Toplam stat 5 × 3 + köken 1 (%s)" % o.origin)
	# Kökeni yazılmamış ya da bilinmeyen kayıtta köken puanı beklemede durur.
	for missing: String in ["", "origin_nope"]:
		var n := _new(missing)
		assert_eq(n.origin, "")
		assert_eq(n.stat_points, 1, "Köken puanı beklemede (%s)" % missing)
		assert_eq(n.stats, {"grip": 3, "wind": 3, "foot": 3, "eye": 3, "word": 3})
	# Oluşturucunun kökeni (CharacterProfile.origin) aynı kimliktir: her köken tablodadır.
	for o: Dictionary in CharacterOptions.origins():
		assert_true(Progression.origin_table().has(o["id"]), "Oluşturucunun kökeni %s ilerlemede var" % o["id"])
	# Köken statları türetilen değerlere işler (Derive): Bilek 4 → Yük 24, vuruş ×1,06, Can 102.
	var d := load.derived()
	assert_eq(d["loadMax"], 24.0)
	assert_almost(d["meleeMul"], 1.06, 1e-12)
	assert_eq(d["hpMax"], 102.0)
	assert_almost(listener.derived()["trustGainK"], 1.06, 1e-12, "Söz 4: Güven +%6")
	assert_almost(p.derived()["walk"], 4.4 * 1.012, 1e-12, "Ayak 4: yürüyüş +%1,2")


## K104: K104'ten önceki kaydın köken kimliği (yeni yolculukta da, kayıt bloğunda da) yenisine göçer; etkisi aynıdır.
func test_old_origin_ids_migrate() -> void:
	var pairs := {"origin_load": "origin_riders", "origin_listener": "origin_tent", "origin_stable": "origin_herds"}
	for old: String in pairs:
		assert_eq(Progression.current_origin(old), pairs[old])
		var fresh := _new(old)
		assert_eq(fresh.origin, pairs[old], "Yeni yolculukta %s → %s" % [old, pairs[old]])
		assert_eq(fresh.stat_points, 0, "Köken puanı dağıtılmış (%s)" % old)
		var saved := Progression.new()
		saved.from_dict({"origin": old, "xp": 300, "stats": fresh.stats.duplicate()}, 1)
		assert_eq(saved.origin, pairs[old], "Kayıt bloğunda %s → %s" % [old, pairs[old]])
		assert_eq(saved.to_dict()["origin"], pairs[old], "Yeniden yazılan blokta yeni kimlik")
	assert_eq(_new("origin_stable").origin_bond(), 10.0, "Eski Ahır Yamağı kaydı Bağ +10'unu korur")
	assert_eq(Progression.current_origin("origin_herds"), "origin_herds", "Yeni kimlik olduğu gibi")
	assert_eq(Progression.current_origin("origin_nope"), "origin_nope")
	# Sınamanın kendi tablosundaki kimlik göçmez (prototipin fikstürü eski kimliklerle koşar).
	var own := Progression.new({"origins": {"origin_load": {"stats": {"grip": 1}, "bond": 0.0}}})
	own.reset_player("origin_load")
	assert_eq(own.origin, "origin_load")


func test_stat_cap_and_points() -> void:
	var p := _new("origin_riders")
	assert_false(p.spend_stat("grip"), "Puan yoksa stat artmaz")
	p.add_xp(4575)
	for i in 3:
		assert_true(p.spend_stat("grip"))
	assert_eq(p.stats["grip"], 7, "I. Perde'nin tek stat tavanı 7")
	assert_false(p.spend_stat("grip"), "Tavanda stat artmaz; puan bekler")
	assert_eq(p.stat_points, 1)
	assert_false(p.spend_stat("luck"), "Altıncı stat yok")
	assert_true(p.spend_stat("word"))
	p.act_change(2)
	p.add_xp(6000)
	assert_true(p.spend_stat("grip"), "II'de tavan 8")
	assert_eq(p.stats["grip"], 8)


func test_killing_people_gives_no_xp() -> void:
	var p := _new()
	for src: String in ["kill_human", "kill", "loot", "gather", "minor_stop", "companion_quest"]:
		assert_eq(p.award(src, {"base": 500}), 0, "%s XP vermez" % src)
	assert_eq(p.xp, 0)
	assert_eq(p.award("main", {"base": 110}), 110, "Ana görev, I. Perde ×1")
	assert_eq(p.award("job", {"day": 1}), 25)
	assert_eq(p.award("job", {"day": 1}), 25)
	assert_eq(p.award("job", {"day": 1}), 25)
	assert_eq(p.award("job", {"day": 1}), 0, "Günde 3 iş sayılır")
	assert_eq(p.award("job", {"day": 2}), 25, "Ertesi gün yeniden")
	assert_eq(p.award("job_first", {"key": "job_herd"}), 15, "Türün ilki +15")
	assert_eq(p.award("job_first", {"key": "job_herd"}), 0, "Türün ilki bir kez")
	assert_eq(p.award("hunt", {"key": "hare"}), 40, "Tür başına ilk av")
	assert_eq(p.award("hunt", {"key": "hare"}), 0, "Aynı türün ikinci avı XP vermez")
	assert_eq(p.award("atlas_node", {"key": "kislak"}), 0, "atlas_node II'den")
	expect_errors(["bilinmeyen XP kaynağı", "tabanı görev verisinden gelmeli"])
	assert_eq(p.award("murder", {"base": 10}), 0, "Bilinmeyen kaynak XP vermez")
	assert_eq(p.award("main"), 0, "Ana görevin tabanı görev verisindedir")


func test_xp_scale_by_act() -> void:
	# Kabul 29: Keşif, II: 2 iç harita, 12 XP'li durak → 286 (2 × 35 + 12 × 18).
	var p := _new()
	p.act_change(2)
	var total := 0
	for map_id: String in ["whistle_field", "tanhu_ordu"]:
		total += p.award("atlas_node", {"key": map_id})
	for i in 12:
		total += p.award("lookout" if i < 5 else "waystation", {"key": "stop_%d" % i})
	assert_eq(total, 286)
	# Kabul 31: sahnesiz konak (waypost) XP vermez.
	assert_eq(p.award("atlas_node", {"key": "tanhu_camp", "kind": "waypost"}), 0)
	# Kabul 32: II'de beşinci türün ilk avı XP vermez.
	for kind: String in ["goat", "dzeren", "kulan", "bustard"]:
		assert_eq(p.award("hunt", {"key": kind}), 70, "%s: 40 × 1,75" % kind)
	assert_eq(p.award("hunt", {"key": "goose"}), 0, "Perde başına en çok 4 tür")
	# Kabul 30: VI'da 14 ana görev, ortalama taban 177 → 12.390.
	var q := _new()
	q.act_change(6)
	var main := 0
	for i in 14:
		main += q.award("main", {"base": 177})
	assert_eq(main, 12390)
	# job tabanının perdelere göre değeri: 25, 44, 65, 88, 110, 125.
	var jobs: Array = []
	for a in range(1, 7):
		jobs.append(q.scale_xp(25.0, a))
	assert_eq(jobs, [25, 44, 65, 88, 110, 125])


func test_act1_skill_budget() -> void:
	var data := Progression.skill_data()
	var skills: Array = data["skills"]
	assert_eq(skills.size(), 93, "Yedi dal, 93 beceri")
	var per_act := {}
	for s: Dictionary in skills:
		per_act[int(s["act"])] = int(per_act.get(int(s["act"]), 0)) + 1
	assert_eq(per_act, {1: 20, 2: 29, 3: 18, 4: 14, 5: 11, 6: 1}, "Perde başına açılan beceri (§1.4, §17.2)")
	var act1 := skills.filter(func(s: Dictionary) -> bool: return int(s["act"]) == 1)
	var free := act1.filter(func(s: Dictionary) -> bool: return s["free"]).map(func(s: Dictionary) -> String: return s["id"])
	free.sort()
	assert_eq(free, ["hand_signs", "riding"], "I. Perde'de iki beceri bedava")
	assert_eq(act1.size() - free.size(), 18, "18 öğrenilebilir")
	assert_eq(skills.size() - act1.size(), 73, "73 kilitli ve ipuçlu")
	# 6 puan: 4 seviyeden (L2–L5), 2 görevden (mq_herd_school, mq_feast).
	var quests: Array = (Progression.data()["skills"] as Dictionary)["questPoints"]["1"]
	assert_eq(quests, ["mq_herd_school", "mq_feast"])
	var p := _new()
	p.add_xp(4575)
	for q: String in quests:
		p.grant_point(q)
	assert_eq(p.skill_points, 6, "I. Perde'nin 6 beceri puanı")
	assert_false(p.grant_point("mq_feast"), "Görev puanı iki kez verilmez")
	# Seviye 20, I. Perde bandı 1–5.
	assert_eq(int((Progression.data()["levels"] as Dictionary)["max"]), 20)
	assert_eq((Progression.data()["levels"] as Dictionary)["actBands"][0], [1.0, 5.0])


func test_every_skill_is_taught_by_a_person() -> void:
	var data := Progression.skill_data()
	assert_eq(data["masterless"], MASTERLESS, "Usta istemeyen üç beceri (§4.3)")
	var roles := (data["masters"] as Dictionary).keys()
	for s: Dictionary in data["skills"]:
		var teach: Dictionary = s["teach"]
		var who: Variant = teach.get("who")
		var whos: Array = who if who is Array else ([who] if who != null else [])
		if str(s["id"]) in MASTERLESS:
			assert_true(whos.is_empty(), "%s usta istemez" % s["id"])
			continue
		assert_false(whos.is_empty(), "%s'i bir insan öğretir" % s["id"])
		assert_true(teach.has("when"), "%s: ustanın koşulu var" % s["id"])
		if int(s["act"]) == 1:
			for w: Variant in whos:
				assert_false(str(w) in roles, "%s: I. Perde'de adlı kişi öğretir, rol değil (%s)" % [s["id"], w])
	# Usta koşulu tutmadıkça puan yetmez (acceptance 1); ustasız beceri koşul tutunca hazırdır.
	var p := _new()
	p.add_xp(4575)
	assert_eq(p.learn_block("carry_pack"), "master")
	p.set_flag("tally_ardoksha", true)
	assert_null(p.learn_block("carry_pack"), "Ardokşa çetelesini böldü: öğrenilir")
	assert_true(p.learn("carry_pack"))
	assert_eq(p.mod("load", 0), 8.0, "Sırt Yükü: Yük +8")
	assert_eq(p.mod("slowFrom", 0), 0.5)
	assert_eq(p.derived()["loadMax"], 21.0 + 3.0 + 8.0, "Bilek 4 ve Sırt Yükü: 32")


func test_state_machine_on_the_real_table() -> void:
	var p := _new()
	# Bedava beceri ustası tutunca kendiliğinden öğrenilir (riding: Farnak, mq_first_tally; hand_signs: Mene, mq_herd_school).
	assert_eq(p.skill_state("riding"), "teachable")
	p.set_flag("riding", true)
	assert_eq(p.skill_state("riding"), "learned")
	assert_eq(p.learned["riding"]["src"], "free")
	assert_eq(p.skill_points, 0, "Bedava beceri puan harcamaz")
	assert_true(p.mod("mount", false), "Binicilik: mount")
	# Kabul 19: I. Perde'de lead_drill gizli; whistling_arrow ve II. Perde sonrası locked değil teachable.
	assert_eq(p.skill_state("lead_drill"), "hidden")
	p.set_flag("whistling_arrow", true)
	assert_eq(p.skill_state("lead_drill"), "locked", "I. Perde'de II'nin becerisi kilitli")
	p.act_change(2)
	assert_eq(p.skill_state("lead_drill"), "teachable")
	# Kabul 34: II'de mq2_strung_bow yokken quick_nock kilitli: «Önce kendi yayın olmalı.»
	assert_eq(p.skill_state("quick_nock"), "locked")
	assert_eq((p.skill_row("quick_nock")["hint"] as Dictionary)["tr"], "Önce kendi yayın olmalı.")
	p.set_flag("item:fallen_bow", 1)
	assert_eq(p.skill_state("quick_nock"), "locked", "Düşen yay Mete'nin kendi yayı değildir (K43)")
	p.set_flag("quest:mq2_strung_bow.done", true)
	assert_eq(p.skill_state("quick_nock"), "teachable", "Kendi yayı dönünce usta beklenir")
	# Ustasız ve bedava lead_count act1_done ile hazırdır; bedava beceri de seviyesini bekler (Sv 6), gelince kendiliğinden öğrenilir.
	p.set_flag("act1_done", true)
	assert_eq(p.skill_state("lead_count"), "ready")
	assert_eq(p.learn_block("lead_count"), "level")
	assert_eq(p.skill_state("two_tongues"), "ready", "İki Dil usta istemez, puan bekler")
	p.add_xp(4600)
	assert_eq(p.level, 6)
	assert_eq(p.skill_state("lead_count"), "learned", "Sv 6'da Sayım kendiliğinden gelir")
	assert_eq(p.learned["lead_count"]["src"], "free")


func test_sentenced_loses_unmet_masters() -> void:
	# Kabul 18: sentenced, slip'in koşulu yok → lost_master; ready olan carry_pack etkilenmez.
	var p := _new()
	p.set_flag("tally_ardoksha", true)
	assert_eq(p.skill_state("carry_pack"), "ready")
	p.set_flag("sentenced", true)
	assert_eq(p.skill_state("slip"), "lost_master")
	assert_eq(p.skill_state("carry_pack"), "ready", "Koşulu tutmuş beceri hazır kalır")
	p.set_flag("quest:sq_wager.done", true)
	assert_eq(p.skill_state("slip"), "lost_master", "Usta yitti: koşul sonradan tutsa da")
	assert_eq(p.learn_block("slip"), "lost_master")
	assert_eq(p.skill_state("tracking"), "locked", "II'nin becerisi yitmez")
	p.act_change(2)
	assert_false(p.lost_master.has("slip"), "II. Perde'de başkası öğretir: lost_master temizlenir")


func test_save_block_roundtrip_and_validation() -> void:
	var p := _new("origin_herds")
	p.set_flag("tally_ardoksha", true)
	p.set_flag("riding", true)
	p.add_xp(3000)
	p.spend_stat("wind")
	p.learn("carry_pack")
	p.grant_point("mq_herd_school")
	p.set_bar(0, "carry_pack")
	p.award("hunt", {"key": "hare"})
	var block := p.to_dict()
	assert_eq(int(block["v"]), Progression.BLOCK_VERSION)
	var text := JSON.stringify(block)
	var q := Progression.new()
	q.from_dict(JSON.parse_string(text), 1)
	assert_eq(JSON.stringify(q.to_dict()), text, "Kayıt yaz, oku: aynı blok")
	# Kabul 23: aynı Derived.
	assert_eq(JSON.stringify(q.derived()), JSON.stringify(p.derived()))
	assert_eq(q.award("hunt", {"key": "hare"}), 0, "Bir kez sayılan XP kayıttan sonra da sayılmaz")
	# Kabul 22: bilinmeyen beceri silinir, puanı geri gelir.
	var bad: Dictionary = JSON.parse_string(text)
	(bad["skills"] as Dictionary)["no_such_skill"] = {"at": 2, "src": "point"}
	bad["skillPoints"] = 0
	var r := Progression.new()
	r.from_dict(bad, 1)
	assert_false(r.learned.has("no_such_skill"))
	assert_eq(r.skill_points, p.skill_points, "Harcanan puan (Sv − 1) + görev puanı + aşkın − öğrenilen ile doğrulanır")
	# Kırpma: seviye perde tavanına ve XP'ye; stat tavana; stat toplamı tutmazsa fark statPoints'e.
	var odd: Dictionary = JSON.parse_string(text)
	odd["level"] = 12
	odd["xp"] = 5000
	odd["stats"] = {"grip": 12, "wind": 3, "foot": 4, "eye": "x"}
	odd["statPoints"] = 40
	var s := Progression.new()
	s.from_dict(odd, 1)
	assert_eq(s.level, 5, "I. Perde'de 5.000 XP Sv 5")
	assert_eq(s.stats, {"grip": 7, "wind": 3, "foot": 4, "eye": 3, "word": 3})
	assert_eq(s.stat_points, 16 + 4 - 20, "15 + 1 + (Sv − 1) − Σstat")
	# Bozuk alanlar varsayılana düşer.
	var empty := Progression.new()
	empty.from_dict({"xp": "çok", "skills": [], "bar": "x", "origin": 5}, 1)
	assert_eq([empty.level, empty.xp, empty.origin, empty.stat_points], [1, 0, "", 1])


func test_mods_fold_in_learning_order() -> void:
	var rows := [
		{"id": "a", "kind": "passive", "mods": {"load": 8, "slowFrom": {"set": 0.5}, "draw": {"mul": 0.85}, "form": ["line"], "flag": true}},
		{"id": "b", "kind": "passive", "mods": {"load": 2, "slowFrom": {"set": 0.4}, "draw": {"mul": 0.9}, "form": ["crescent", "line"]}},
		{"id": "c", "kind": "active", "mods": {"dmg": {"mul": 1.3}}},
	]
	var p := Progression.new({"skills": rows})
	p.from_dict({"stats": {}, "skills": {"a": {"at": 1, "src": "point"}, "b": {"at": 1, "src": "point"}, "c": {"at": 1, "src": "point"}}}, 1)
	var m := p.mods()
	assert_eq(m["load"], 10.0, "Sayı toplanır")
	assert_eq(m["slowFrom"], 0.4, "{set} ezer, sonra öğrenilen kazanır")
	assert_almost(m["draw"], 0.85 * 0.9, 1e-12, "{mul} çarpılır")
	assert_eq(m["form"], ["line", "crescent"], "Dizi birleşir")
	assert_eq(m["flag"], true, "Mantık ezer")
	assert_false(m.has("dmg"), "Etkin becerinin mods'u katlanmaz")
	assert_almost(p.mod("draw", 1.0), 0.85 * 0.9, 1e-12)
	assert_eq(p.mod("missing", 5.0), 5.0)


func test_prototype_fixture() -> void:
	var fx := ProtoFixture.load_fixture("progress")
	assert_false(fx.is_empty(), "tests/fixtures/progress.json yok: node tools/proto_fixtures.mjs --only=progression")
	if fx.is_empty():
		return
	var rows: Array = fx["skills"]
	var handlers := {
		"scaleXp": func(a: Array) -> Variant: return Progression.new({"skills": rows}).scale_xp(float(a[0]), int(a[1])),
		"dreadEffects": func(a: Array) -> Variant: return Derive.dread_effects(float(a[0])),
		"script": func(c: Dictionary) -> Variant: return _run_script(rows, c, (fx["constants"] as Dictionary)["origins"]),
	}
	var n := ProtoFixture.run_cases(self, fx, handlers)
	assert_eq(n, (fx["cases"] as Array).size(), "Her durum koşuldu")
	# Prototipin tabloları veri dosyalarıyla aynı.
	var c: Dictionary = fx["constants"]
	var p := Progression.new()
	assert_eq(c["xpCurve"], p.xp_curve.map(func(v: Variant) -> float: return float(v)))
	assert_eq(c["levelCaps"], p.level_caps.map(func(v: Variant) -> float: return float(v)))
	assert_eq(c["statCaps"], p.stat_caps.map(func(v: Variant) -> float: return float(v)))
	assert_eq(c["xpScale"], p.xp_scale)
	assert_eq(c["STAT_IDS"], p.stat_ids)
	# Prototipin kökenleri K104'ten öncekilerdir (origin_load …): eski kimlik bugünkü kökene göçer, etkisi aynıdır.
	for id: String in c["origins"]:
		var ours := Progression.current_origin(id)
		assert_true(Progression.origin_table().has(ours), "prototipin kökeni %s → %s" % [id, ours])
		if not Progression.origin_table().has(ours):
			continue
		assert_eq(c["origins"][id]["stats"], Progression.origin_table()[ours]["stats"], "köken %s → %s" % [id, ours])
		assert_eq(float(c["origins"][id]["bond"]), float(Progression.origin_table()[ours]["bond"]), "köken %s → %s Bağ" % [id, ours])


## Fikstürün senaryosu: aynı işlemler Progression'da; her işlemden sonra {op, r, s}. Köken tablosu prototipinkidir (eski kimlikler,
## K104'ten önce): durumların origin alanı prototipin yazdığıdır; tabloların eşliği test_prototype_fixture'da göçle sınanır.
func _run_script(rows: Array, c: Dictionary, origins: Dictionary) -> Array:
	var p := Progression.new({"skills": rows, "origins": origins})
	p.reset_player(str(c["origin"]) if c["origin"] is String else "")
	var out: Array = []
	for op: Array in c["ops"]:
		var name := str(op[0])
		var a: Variant = op[1] if op.size() > 1 else null
		var b: Variant = op[2] if op.size() > 2 else null
		var r: Variant = null
		match name:
			"addXp":
				r = p.add_xp(float(a))
			"actChange":
				r = p.act_change(int(a))
			"spendStat":
				r = p.spend_stat(str(a))
			"learn":
				r = p.learn(str(a))
			"teach":
				r = p.teach(str(a))
			"grantPoint":
				r = p.grant_point(str(a))
			"setBar":
				r = p.set_bar(int(a), b)
			"checkTeach":
				p.check_teach()
			"flag":
				p.flags[str(a)] = b
				p.on_flag_set(str(a), b)
			"restore":
				p.from_dict(a, int(b))
			"states":
				var states := {}
				for row: Dictionary in rows:
					states[row["id"]] = p.skill_state(str(row["id"]))
				r = states
			"block":
				r = p.learn_block(str(a))
			"mods":
				r = p.mods().duplicate(true)
			"mod":
				r = p.mod(str(a), b)
			_:
				fail("bilinmeyen işlem %s" % name)
		var s := p.to_dict()
		s.erase("v")
		s.erase("xpOnce")
		s.erase("xpCounts")
		s["act"] = p.act
		s["originBond"] = p.origin_bond()
		out.append({"op": op, "r": r, "s": s})
	return out


func test_skill_table_matches_the_document() -> void:
	var path := ProjectSettings.globalize_path("res://").path_join(DOC).simplify_path()
	var lines := FileAccess.get_file_as_string(path).split("\n")
	assert_true(lines.size() > 100, "progression.md okunamadı: %s" % path)
	var trees := {"4.5": "labour", "4.6": "shadow", "4.7": "saddle", "4.8": "bow", "4.9": "blade"}
	var roman := {"I": 1, "II": 2, "III": 3, "IV": 4, "V": 5, "VI": 6}
	var kinds := {"P": "passive", "E": "active", "A": "toggle"}
	var quote := RegEx.create_from_string("«([^»]*)»")
	var rows := Progression.rows_by_id(Progression.skill_data()["skills"])
	var tree := ""
	var inside := false
	var seen := 0
	for line: String in lines:
		if line.begins_with("### 4."):
			var sec := line.substr(4).split(" ")[0]
			inside = sec in ["4.5", "4.6", "4.7", "4.8", "4.9", "4.10"]
			tree = trees.get(sec, tree)
			continue
		if line.begins_with("## "):
			inside = false
		if not inside:
			continue
		if line.begins_with("Söz: «"):
			tree = "word"
		if line.begins_with("Buyruk: «"):
			tree = "command"
		if not line.begins_with("| `"):
			continue
		var cells := line.strip_edges().trim_prefix("|").trim_suffix("|").split(" | ")
		if cells.size() != 12:
			continue
		var id := cells[0].strip_edges().trim_prefix("`").trim_suffix("`")
		seen += 1
		assert_true(rows.has(id), "Belgenin becerisi %s veride yok" % id)
		if not rows.has(id):
			continue
		var row: Dictionary = rows[id]
		var name := cells[1].split(" / ", true, 1)
		assert_eq(row["tree"], tree, "%s dalı" % id)
		assert_eq(int(row["tier"]), int(cells[3]), "%s T" % id)
		assert_eq(int(row["level"]), int(cells[5]), "%s Sv" % id)
		assert_eq(int(row["act"]), int(roman[cells[6].strip_edges()]), "%s P" % id)
		assert_eq(row["kind"], kinds[cells[7].strip_edges()], "%s Tür" % id)
		assert_eq([row["name"]["tr"], row["name"]["en"]], [name[0].strip_edges(), name[1].strip_edges()], "%s adı" % id)
		var desc := quote.search_all(cells[2])
		assert_eq([row["desc"]["tr"], row["desc"]["en"]], [desc[0].get_string(1), desc[1].get_string(1)], "%s açıklaması" % id)
		if cells[9].is_valid_int():
			assert_eq(int(row["cooldown"]), int(cells[9]), "%s CD" % id)
		if cells[10].is_valid_int():
			assert_eq(int(row["stamina"]), int(cells[10]), "%s St" % id)
		var act1 := cells[11]
		assert_eq(row["free"], act1.begins_with("Bedava") or cells[8].contains("bedava"), "%s bedava mı" % id)
		assert_eq(row.get("hideName", false), act1.contains("gizli ad"), "%s gizli ad" % id)
		if act1.contains("«"):
			var hint := quote.search_all(act1)
			assert_eq([row["hint"]["tr"], row["hint"]["en"]], [hint[0].get_string(1), hint[1].get_string(1)], "%s ipucu" % id)
	assert_eq(seen, 93, "Belgenin tablolarında 93 beceri")


func test_skills_data_integrity() -> void:
	var data := Progression.skill_data()
	var rows := Progression.rows_by_id(data["skills"])
	assert_eq(rows.size(), (data["skills"] as Array).size(), "Kimlikler tekil")
	var counts := {}
	var readers := {}
	for module: String in data["readers"]:
		for key: String in data["readers"][module]:
			readers[key] = true
	var tiers: Array = (Progression.data()["skills"] as Dictionary)["tierLevels"]
	for id: String in rows:
		var s: Dictionary = rows[id]
		counts[s["tree"]] = int(counts.get(s["tree"], 0)) + 1
		for key: String in ["name", "desc", "hint"]:
			assert_false(str(s[key].get("tr", "")).is_empty() or str(s[key].get("en", "")).is_empty(), "%s.%s TR ve EN" % [id, key])
		assert_true(int(s["level"]) >= int(tiers[int(s["tier"]) - 1]), "%s: seviye tier tabanının altında değil" % id)
		for key: String in s["mods"]:
			assert_true(readers.has(key), "%s.mods.%s'in okuyucusu var (§4.11)" % [id, key])
		for need: String in s["requires"]:
			if rows.has(need):
				var pre: Dictionary = rows[need]
				assert_true(int(pre["act"]) <= int(s["act"]), "%s önkoşulu %s önceki perdede" % [id, need])
			else:
				assert_eq(Cond.error_of(need), "", "%s önkoşulu «%s» koşul dilinde" % [id, need])
				for atom: String in Cond.atoms(need):
					if atom.begins_with("skill:"):
						assert_true(rows.has(atom.substr(6)), "%s: %s var" % [id, atom])
		var when: Variant = (s["teach"] as Dictionary).get("when")
		if when is String:
			assert_eq(Cond.error_of(when), "", "%s usta koşulu «%s» koşul dilinde" % [id, when])
		if s.has("limit"):
			assert_true(str(s["limit"]["per"]) in ["region", "day"], "%s kullanım sınırı" % id)
	assert_eq(counts, {"labour": 11, "shadow": 13, "saddle": 13, "bow": 12, "blade": 13, "word": 14, "command": 17}, "Dal başına beceri (§4.5–§4.10)")
	var free := rows.keys().filter(func(id: String) -> bool: return rows[id]["free"])
	free.sort()
	assert_eq(free, ["hand_signs", "lead_count", "riding"], "Bedava üç beceri (§4.1)")
	for id: String in ["over_shoulder", "pointing_arrow", "volley", "tulpar_run"]:
		assert_true(rows.has(id), "K32'nin yeni adı %s" % id)
	for old: String in ["parting_shot", "singing_arrow", "arrow_rain", "thousand_li"]:
		assert_false(rows.has(old), "Eski ad %s kalktı (K32)" % old)
	assert_true(rows["volley"]["mods"].has("volleyR") and rows["tulpar_run"]["mods"].has("tulparT"), "Yeni anahtarlar volleyR ve tulparT")
	assert_true(rows["knee_steer"]["mods"].get("rideGather", false), "knee_steer: rideGather (K46)")
	for tree: Dictionary in data["trees"]:
		assert_false(str(tree["name"]["tr"]).is_empty() or str(tree["name"]["en"]).is_empty())
		assert_true((data["masters"] as Dictionary).has(tree["master"]), "%s dalının ustası" % tree["id"])
