extends TestCase
## Binicilik (Yol Haritası riding; progression.md §2.3, §6.4, §13.2; economy.md §4.7; fauna.md §2.1; act1.md §8.8, §10): Mount'un koşulu (Bağ,
## eyer, gem, terki), at staminası ve mahmuz; satırların kalıtımı (I. Perde'nin binekleri); MountStable (Bağ kaynakları ve günlük sınırları, köken
## payı, at eşyası, dinlenme) ve kayıt v2'nin «mounts» bloğu. Saftır: düğüm kurmaz.

const DT := 1.0 / 60.0


func before_each() -> void:
	Mount.reset_cache()


# --- Mount: koşul -------------------------------------------------------------------------------------------------

func test_bond_load_and_bit_shape_the_ride() -> void:
	var horse := Mount.new("horse")
	assert_almost(horse.gallop_speed(), 10.5, 1e-9, "Bağsız dörtnal satırın base'i")
	horse.set_condition({"bond": 40.0})
	assert_almost(horse.gallop_speed(), 10.5 + 0.045 * 40.0, 1e-9, "Dörtnal = base + 0,045 × Bağ (progression.md §2.3)")
	horse.set_condition({"bond": 140.0})
	assert_almost(horse.bond(), 100.0, 1e-9, "Bağ 0–100")
	# Terki: l ≤ 0,5 ×1; dolu ×0,85; dörtte üçün üstünde dörtnal yok (economy.md §4.7).
	horse.set_condition({"load_k": CarryLoad.mount_speed_k(1.0), "can_gallop": CarryLoad.can_gallop(1.0)})
	assert_almost(horse.walk_speed(), 1.6 * 0.85, 1e-9, "Dolu terkide adım ×0,85")
	assert_almost(horse.trot_speed(), 4.0 * 0.85, 1e-9)
	assert_false(horse.can_gallop_now(), "Dörtte üçün üstünde dörtnal yok")
	horse.start_ride()
	var speed := 0.0
	for i in int(3.0 / DT):
		speed = horse.step(DT, true, true, i == 0)
	assert_almost(speed, horse.trot_speed(), 1e-9, "Shift basılı kalsa da tırısta kalır")
	assert_eq(horse.gait_name(), "trot")
	# Kemik Gem dönüşü ×1,04 keskinleştirir (fauna.md §2.1, K65).
	var plain := Mount.new("horse")
	var bitted := Mount.new("horse")
	bitted.set_condition({"turn_mul": ItemCatalog.gear_of("bridle_bone").get("turnMul", 1.0)})
	assert_almost(bitted.turn_at(0.0) / plain.turn_at(0.0), 1.04, 1e-9, "Kemik Gem ×1,04")
	assert_almost(bitted.turn_at(plain.gallop_speed()) / plain.turn_at(plain.gallop_speed()), 1.04, 1e-9)


func test_stamina_drain_and_regen_match_derive() -> void:
	# progression.md §17.1 #27: Bağ 40, Tipi dışı, eyerli → horseDrain 0,234, horseRegen 0,18.
	var horse := Mount.new("horse")
	horse.set_condition({"bond": 40.0, "saddled": true})
	assert_almost(horse.drain_rate(), 0.234, 1e-9, "horseDrain (0,27 − 0,09k)")
	assert_almost(horse.regen_rate(), 0.18, 1e-9, "horseRegen (0,14 + 0,10k)")
	var derived := Derive.derive({"bond": 40.0, "mount": {"base": 10.5, "saddled": true, "load": 0.0, "cap": 50.0}})
	assert_almost(horse.drain_rate(), float(derived["horseDrain"]), 1e-9, "Derive ile aynı")
	assert_almost(horse.regen_rate(), float(derived["horseRegen"]), 1e-9)
	assert_almost(horse.gallop_speed(), float(derived["gallop"]), 1e-9, "Dörtnal Derive ile aynı")
	# Eyersiz: stamina %30 hızlı biter (act1.md §8.8).
	horse.set_condition({"bond": 40.0, "saddled": false})
	assert_almost(horse.drain_rate(), 0.234 * 1.3, 1e-9, "Çıplak binme ×1,3")
	# Satırın dayanıklılığı (fauna.md: at staminası çarpanı) gideri böler: Yakve 0,8 daha çabuk yorulur.
	var yakwe := Mount.new("yakwe")
	assert_almost(yakwe.drain_rate(), Derive.DRAIN_BASE / 0.8, 1e-9)


func test_spur_is_a_second_press_in_the_gallop_and_costs_stamina() -> void:
	var horse := Mount.new("horse")
	horse.start_ride()
	assert_true(horse.has_spur(), "Kampın atı mahmuzlanır")
	var speed := 0.0
	for i in int(1.5 / DT):
		speed = horse.step(DT, true, true, i == 0)
	assert_eq(horse.gait_name(), "gallop")
	assert_false(horse.is_spurring(), "Basılı tutmak mahmuz değildir")
	assert_almost(horse.stamina, 1.0, 1e-9, "Dörtnal staminayı harcamaz")
	# Bırak: dürtmenin aralığında dörtnal sürer.
	speed = horse.step(DT, true, false, false)
	assert_almost(speed, horse.gallop_speed(), 1e-9, "Bırakılan tuş spur_tap_s boyunca dörtnalı tutar")
	speed = horse.step(DT, true, true, true)
	assert_true(horse.is_spurring(), "Aralıkta yeniden basmak mahmuzdur")
	assert_almost(speed, horse.gallop_speed() + 3.0, 1e-9, "Mahmuz +3 m/sn (act1.md §10)")
	var drain := horse.drain_rate()
	var before := horse.stamina
	horse.step(1.0, true, true, false)
	assert_almost(before - horse.stamina, drain, 1e-6, "Mahmuzda stamina gider")
	# Bitene dek mahmuz: soluk kesilir, mahmuz biter, dörtnal sürer.
	var t := 0.0
	while horse.is_spurring() and t < 10.0:
		horse.step(DT, true, true, false)
		t += DT
	assert_true(horse.is_winded(), "Stamina bitince soluk kesilir")
	assert_almost(horse.stamina, 0.0, 1e-9)
	assert_almost(horse.step(DT, true, true, false), horse.gallop_speed(), 1e-6, "Mahmuzsuz dörtnal sürer (stamina dolar)")
	assert_false(horse.can_spur(), "Soluk kesikken mahmuz yok")
	horse.step(DT, true, false, false)
	horse.step(DT, true, true, true)
	assert_false(horse.is_spurring(), "Yeniden basmak da mahmuzlamaz")
	# spur_min'e dolunca soluk geri gelir.
	var need := horse.value("spur_min") / horse.regen_rate()
	horse.step(need + 0.05, false, false, false)
	assert_false(horse.is_winded(), "spur_min'de soluk geri gelir")
	# Aralık geçince bırakılan tuş adıma döner, yeniden basış önce tırıstır.
	for i in int(1.5 / DT):
		horse.step(DT, true, true, i == 0)
	horse.step(DT, true, false, false)
	for i in int((horse.value("spur_tap_s") + 0.05) / DT):
		speed = horse.step(DT, true, false, false)
	assert_almost(speed, horse.walk_speed(), 1e-9, "Aralık geçince adım")
	assert_almost(horse.step(DT, true, true, true), horse.trot_speed(), 1e-9, "Yeni basış önce tırıs")
	# Yakve mahmuzsuzdur (progression.md §6.4 «Mahmuz yok»).
	assert_false(Mount.new("yakwe").has_spur())


func test_act_one_mounts_inherit_the_horse_row() -> void:
	for id in ["yakwe", "offering_stallion", "spare_horse"]:
		assert_true(Mount.ids().has(id), "%s satırı var" % id)
		var m := Mount.new(id)
		assert_eq(m.seat(), Mount.new("horse").seat(), "%s atın eyerini ve kliplerini paylaşır (like)" % id)
		assert_true(m.walks_on_input(), "%s girişte adım" % id)
	var stallion := Mount.new("offering_stallion")
	assert_almost(stallion.base_speed(), 12.0, 1e-9, "Adak Aygırı base 12 (progression.md §6.4)")
	assert_almost(stallion.trot_speed(), 6.4, 1e-9)
	assert_almost(CarryLoad.mount_cap("offering_stallion"), 50.0, 1e-9, "Terki 50")
	assert_almost(CarryLoad.mount_cap("yakwe"), 40.0, 1e-9)
	assert_almost(CarryLoad.mount_cap("spare_horse"), 30.0, 1e-9)
	assert_null(Mount.row_of("offering_stallion").get("gear", {}).get("saddle"), "Adak Aygırı eyersiz gelir (act1.md §8.8)")
	assert_eq(Mount.row_of("horse")["gear"]["saddle"], "saddle_felt", "Kampın atının eyeri modelinde: Keçe Eyer")
	assert_false(Mount.row_of("horse").has("stirrup"), "Üzengi yok (K58)")
	var edges := Vector2(stallion.value("walk_top"), stallion.value("gallop_from"))
	assert_true(edges.x > 1.6 and edges.x < 6.4 and edges.y > 6.4 and edges.y < 12.0, "Klip eşikleri satırın yürüyüşleri arasında")


# --- MountStable ---------------------------------------------------------------------------------------------------

func test_stable_entry_gear_and_origin_bond() -> void:
	var stable := MountStable.new()
	var e := stable.entry("horse@doru", "horse", MountStable.origin_bond("origin_stable"))
	assert_almost(float(e["bond"]), 10.0, 1e-9, "Ahır Yamağı Bağ +10 (origins.json)")
	assert_almost(MountStable.origin_bond("origin_load"), 0.0, 1e-9)
	assert_eq(stable.gear_of("horse@doru", "saddle"), "saddle_felt")
	assert_eq(stable.gear_of("horse@doru", "bridle"), "bridle_bone", "Kemik Gem")
	var fx := stable.gear_effects("horse@doru")
	assert_true(bool(fx["saddled"]))
	assert_almost(float(fx["turn_mul"]), 1.04, 1e-9)
	assert_eq(stable.equip("horse@doru", "bridle", "saddle_felt"), "!", "Eyer gem yuvasına girmez")
	assert_eq(stable.equip("horse@doru", "bridle", "bridle_bronze"), "bridle_bone", "Eski gem döner")
	assert_almost(float(stable.gear_effects("horse@doru")["turn_mul"]), 1.08, 1e-9)
	assert_eq(stable.unequip("horse@doru", "saddle"), "saddle_felt")
	assert_false(bool(stable.gear_effects("horse@doru")["saddled"]), "Eyersiz: çıplak binme")
	var c := stable.condition("horse@doru", {"speed_k": 0.85, "can_gallop": false}, {"horseDrain": 0.8})
	assert_eq(c["saddled"], false)
	assert_almost(float(c["load_k"]), 0.85, 1e-9)
	assert_eq(c["can_gallop"], false)
	assert_almost(float(c["drain_mul"]), 0.8, 1e-9, "Soluk Paylaşımı (shared_breath ×0,8)")
	var m := Mount.new("horse")
	m.set_condition(c)
	assert_almost(m.drain_rate(), (0.27 - 0.09 * 0.1) * 0.8 * 1.3, 1e-9)
	# Yular binme süresini kısaltır, toynak sargısı buzda kaydırmaz, çul staminayı uzatır.
	stable.equip("horse@doru", "bridle", "halter")
	stable.equip("horse@doru", "hoof", "hoof_wraps")
	stable.equip("horse@doru", "blanket", "blanket_felt")
	fx = stable.gear_effects("horse@doru")
	assert_almost(float(fx["mount_time"]), -1.0, 1e-9)
	assert_true(bool(fx["ice_grip"]))
	assert_almost(float(fx["stamina_mul"]), 1.05, 1e-9)


func test_bond_sources_and_their_limits() -> void:
	var stable := MountStable.new()
	stable.entry("offering_stallion", "offering_stallion")
	for i in 3:
		assert_almost(float(stable.add_bond("offering_stallion", "fodder", 1042)["gained"]), 5.0, 1e-9, "Yem Bağı +5")
	var capped := stable.add_bond("offering_stallion", "fodder", 1042)
	assert_eq(capped["reason"], "day_cap", "Günde en çok 3")
	assert_almost(float(stable.add_bond("offering_stallion", "fodder", 1043)["gained"]), 5.0, 1e-9, "Ertesi gün yine")
	assert_almost(float(stable.add_bond("offering_stallion", "groom", 1043)["gained"]), 2.0, 1e-9, "Tımar +2")
	assert_eq(stable.add_bond("offering_stallion", "groom", 1043)["reason"], "day_cap", "Tımar günde 1")
	assert_almost(float(stable.set_name("offering_stallion", "Küldoru")["gained"]), 10.0, 1e-9, "Ad +10")
	assert_eq(stable.name_of("offering_stallion"), "Küldoru")
	assert_eq(stable.set_name("offering_stallion", "Tanyeli")["reason"], "once", "Ad bir kez Bağ verir")
	assert_almost(float(stable.add_bond("offering_stallion", "oath", 1043)["gained"]), 10.0, 1e-9, "Ant +10 (act1.md §8.8)")
	assert_almost(stable.bond("offering_stallion"), 42.0, 1e-9, "3×5 + 5 + 2 + 10 + 10")
	assert_eq(stable.add_bond("offering_stallion", "unknown", 1043)["reason"], "unknown")
	stable.bond_gain_k = 1.25
	assert_almost(float(stable.add_bond("offering_stallion", "effect", 1043, 4.0)["gained"]), 5.0, 1e-9, "Beceri çarpanı (downwind ×1,25)")
	stable.add_bond("offering_stallion", "effect", 1043, 500.0)
	assert_almost(stable.bond("offering_stallion"), 100.0, 1e-9, "Bağ 100'de durur")
	assert_true(stable.bond("offering_stallion") >= MountStable.BOND_THUNDER, "≥70 gök gürültüsüne aldırmaz")


func test_rest_refills_the_horses_not_ridden() -> void:
	var stable := MountStable.new()
	stable.entry("horse@doru", "horse")
	stable.entry("horse@akbulut", "horse")
	stable.set_stamina("horse@doru", 0.2)
	stable.set_stamina("horse@akbulut", 0.2)
	stable.rest(1.0, "horse@doru")
	assert_almost(stable.stamina("horse@doru"), 0.2, 1e-9, "Binilen dinlenmez (Mount yönetir)")
	assert_almost(stable.stamina("horse@akbulut"), 0.2 + Mount.rest_regen(0.0), 1e-9, "Öteki dinlenir")
	stable.rest(60.0)
	assert_almost(stable.stamina("horse@akbulut"), 1.0, 1e-9, "Dolunca 1'de kalır")


func test_mounts_block_round_trips_through_save_v2() -> void:
	var stable := MountStable.new()
	stable.entry("horse@doru", "horse", 10.0)
	stable.add_bond("horse@doru", "fodder", 1042)
	stable.set_stamina("horse@doru", 0.4)
	stable.set_name("horse@doru", "Doru")
	stable.equip("horse@doru", "blanket", "blanket_felt")
	stable.active = "horse@doru"
	var reg := SaveBlocks.new()
	stable.register_block(reg)
	assert_true(reg.has_block("mounts"), "Kayıt v2'de «mounts» bloğu")
	var blocks := reg.collect()
	assert_eq(int(blocks["mounts"]["v"]), MountStable.SAVE_V)
	assert_eq(MountStable.validate_save_block(blocks["mounts"]), "")
	var text := JSON.stringify(blocks)
	var back := MountStable.new()
	var reg2 := SaveBlocks.new()
	back.register_block(reg2)
	assert_eq(reg2.apply(JSON.parse_string(text)), "", "Blok okunur")
	assert_almost(back.bond("horse@doru"), 25.0, 1e-9, "Bağ: köken 10 + Yem 5 + ad 10")
	assert_almost(back.stamina("horse@doru"), 0.4, 1e-9)
	assert_eq(back.name_of("horse@doru"), "Doru")
	assert_eq(back.gear_of("horse@doru", "blanket"), "blanket_felt")
	assert_eq(back.gear_of("horse@doru", "saddle"), "saddle_felt")
	assert_eq(back.active, "horse@doru")
	assert_eq(back.add_bond("horse@doru", "name")["reason"], "once", "Bir keze sayılan kaynak kayıtta kalır")
	assert_eq(back.add_bond("horse@doru", "fodder", 1042)["gained"], 5.0, "Günün yemi kayıtta sayılır (1/3)")
	# Bozuk blok okunmaz; bilinmeyen eşya ve yuvası tutmayan eşya düşer.
	assert_ne(MountStable.validate_save_block({"list": {"x": {"bond": "çok"}}}), "")
	assert_ne(MountStable.validate_save_block({"list": [], "active": 3}), "")
	var odd := MountStable.new()
	assert_true(odd.from_dict({"v": 1, "list": {"horse@x": {"kind": "horse", "bond": 300.0, "sta": -1.0, "gear": {"saddle": "bridle_bone", "bridle": "yok_boyle"}}}}))
	assert_almost(odd.bond("horse@x"), 100.0, 1e-9)
	assert_almost(odd.stamina("horse@x"), 0.0, 1e-9)
	assert_eq(odd.gear_of("horse@x", "saddle"), "", "Yuvası tutmayan eşya düşer")
	assert_eq(odd.gear_of("horse@x", "bridle"), "", "Bilinmeyen eşya düşer")
	# Yeni yolculukta blok yoksa binek yok.
	var fresh := MountStable.new()
	fresh.entry("horse@doru", "horse")
	var reg3 := SaveBlocks.new()
	fresh.register_block(reg3)
	assert_eq(reg3.apply({}), "")
	assert_false(fresh.has("horse@doru"), "Blok yoksa sıfırlanır")
