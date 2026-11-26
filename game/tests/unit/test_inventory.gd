extends TestCase
## Inventory'nin Godot'ya özgü yüzü (prototiple aynı kurallar test_inventory_proto.gd'de): çocuğun bedeni ve tek kütüğü, toplamanın
## yolu (Heybe → terki → yer yığını), «Yük dolu» ve «Heybede yer yok», bırakma ve yerden alma, kese, kuşağın Yük'ü, hızlı düğmeler,
## başlangıç donanımı ve kayıt bloğunun gidiş dönüşü.


func before_each() -> void:
	ItemCatalog.reset_cache()
	ItemContainer.reset_rules()


func test_child_carries_one_log_and_the_toy_bow() -> void:
	var inv := Inventory.new()
	inv.reset_body(Inventory.BODY_CHILD)
	assert_eq(inv.equipped("bow"), "toy_bow", "Oyuncak yay hep yanında, yay yuvasında")
	assert_almost(inv.capacity(), 6.0, 1e-9, "Çocuğun sınırı 6 Yük")
	assert_almost(inv.load_amount(), 0.0, 1e-9, "Kuşanılan yay sınırdan düşmez")
	assert_almost(inv.worn_load(), 0.3, 1e-9, "Yayın kendi Yük'ü 0,3")
	assert_eq(int(inv.add("wood_pine", 2)["added"]), 1, "Çocuk tek kütük taşır")
	assert_almost(inv.speed_k(), 0.8, 1e-9, "Kütükle hızı ×0,8")
	assert_false(inv.can_jump(), "Kütükle zıplamaz")
	assert_true(inv.can_run(), "Koşabilir (doluluk 0,67)")
	inv.reset_body(Inventory.BODY_ADULT)
	assert_eq(inv.equipped("bow"), "", "Yetişkin boş başlar")
	assert_almost(inv.capacity(), 21.0, 1e-9, "Yetişkin Bilek 3: 21")
	assert_true(inv.pack.is_empty())


func test_receive_overflows_to_the_saddlebags_then_the_ground() -> void:
	var inv := Inventory.new()
	var refused := watch_signal(inv.refused)
	var piles := watch_signal(inv.pile_changed)
	inv.near_mount = "horse@Doru"
	var r := inv.receive("stone", 6, "gather")
	assert_eq(int(r["added"]), 6)
	assert_eq(int(r["to"]["pack"]), 4, "Önce heybe: 4 taş (20 Yük)")
	assert_eq(int(r["to"]["saddlebags.horse@Doru"]), 2, "Sığmayan yakındaki atın terkisine")
	assert_almost(inv.saddlebags("horse@Doru").cap(), 50.0, 1e-9, "Terki binek Yük'ü (kampın atı 50)")
	inv.near_mount = ""
	var r2 := inv.receive("stone", 2, "gather", {"spill_at": Vector3(3, 0, 4)})
	assert_eq(int(r2["to"]["pile.1"]), 2, "At yokken kalan yere yığılır")
	assert_eq(piles.count, 1, "Yığın açıldı")
	assert_eq(inv.piles().size(), 1)
	assert_eq(refused.count, 0, "Yere yığılan reddedilmiş sayılmaz")
	var r3 := inv.receive("stone", 1)
	assert_eq(int(r3["rest"]), 1, "Ne at ne yer: kalır")
	assert_eq(refused.count, 1)
	assert_eq(refused.last_args, ["stone", 1, "pack_full"], "«Yük dolu»")
	assert_eq(inv.receive("sheep", 1)["rest"], 1, "Sürü eşya değildir")


func test_slots_full_is_its_own_refusal() -> void:
	var inv := Inventory.new()
	inv.cap_source = func() -> float: return 500.0
	inv.add("felt", 10 * 24)
	assert_eq(inv.slots_used(), 24, "Erzak ve Zanaat'ın 24 ortak yuvası dolu")
	assert_eq(inv.refuse_reason("reed"), "slots_full", "«Heybede yer yok»")
	assert_eq(inv.refuse_reason("stone"), "", "Sırt yükü yuva istemez")
	assert_eq(inv.refuse_reason("nope"), "unknown")


func test_drop_and_take_back_a_ground_pile() -> void:
	var inv := Inventory.new()
	inv.add("lark", 2)
	inv.add("notch_stick", 1)
	inv.add("axe_bronze")
	inv.equip("bow", "toy_bow")
	var removed := watch_signal(inv.pile_removed)
	var pile := inv.drop("lark", 5, Vector3(1, 0, 1))
	assert_not_null(pile, "Bırakılan yere iner")
	assert_eq(pile.count("lark"), 2, "Elde olan kadar")
	assert_eq(inv.pack.count("lark"), 0)
	assert_null(inv.drop("notch_stick", 1, Vector3.ZERO), "Hatıra atılmaz")
	assert_eq(inv.drop("toy_bow", 1, Vector3(1.2, 0, 1)), pile, "Kuşanılı eşya önce çıkar; 1,5 m içindeki yığına katılır")
	assert_eq(inv.equipped("bow"), "")
	assert_eq(inv.drop("axe_bronze", 1, Vector3(1, 0, 1.1)), pile, "Araç da bırakılır")
	assert_false(inv.has_tool("axe_bronze"))
	var far := inv.drop("notch_stick", 1, Vector3(9, 0, 9))
	assert_null(far)
	var r := inv.take_pile(pile)
	assert_eq(inv.pack.count("lark"), 2, "Yerden alınan heybeye")
	assert_true(inv.has_tool("axe_bronze"), "Araç araç sekmesine")
	assert_eq(inv.pack.count("toy_bow"), 1, "Yay heybede (kuşanmak ayrı iş)")
	assert_eq(removed.count, 1, "Boşalan yığın kalkar")
	assert_true(inv.piles().is_empty())
	assert_false((r["moved"] as Array).is_empty())


func test_purse_and_belt_change_the_load() -> void:
	var inv := Inventory.new()
	inv.add("cowrie", 24)
	assert_eq(inv.pack.count("cowrie"), 24, "Kese kapalıyken kabuk heybede")
	inv.remove("cowrie", 24)
	inv.purse_on = true
	inv.add("cowrie", 150)
	assert_eq(inv.cowries(), 150, "Kese açıkken kabuk keseye")
	assert_eq(inv.pack.count("cowrie"), 0)
	assert_eq(inv.slots_used(), 0, "Kese yuva tutmaz")
	assert_almost(inv.load_amount(), 0.2, 1e-9, "150 kabuk 0,2 Yük (yukarı yuvarlanır), heybe yüküne girer")
	var caps := watch_signal(inv.load_changed)
	inv.add("pouch_belt", 1)
	inv.equip("belt", "pouch_belt")
	assert_almost(inv.capacity(), 25.0, 1e-9, "Kese Kuşak +4")
	assert_true(caps.count >= 1, "Sınır değişince load_changed")
	var before := caps.count
	inv.count("cowrie")
	assert_eq(caps.count, before, "Okumak yaymaz")


func test_quick_buttons() -> void:
	var inv := Inventory.new()
	inv.add("stone", 2)
	inv.add("rope", 3)
	inv.add("meal", 4)
	inv.add("lark", 1)
	var bag := inv.saddlebags("horse")
	var back := inv.unload_back(bag)
	assert_eq(back["moved"], [{"id": "stone", "n": 2}], "Sırtı Boşalt: tag:bulk")
	var craft := inv.store_materials(bag)
	assert_eq(craft["moved"], [{"id": "rope", "n": 3}], "Malzemeyi Bırak: Zanaat")
	var food := inv.store_food(bag)
	assert_eq(food["moved"], [{"id": "meal", "n": 4}, {"id": "lark", "n": 1}], "Yiyeceği Bırak: Erzak (av dahil)")
	assert_true(inv.pack.is_empty())
	var missing := inv.take_missing(bag, [{"id": "rope", "n": 2}, {"id": "stone", "n": 5}])
	assert_eq(missing["moved"], [{"id": "rope", "n": 2}, {"id": "stone", "n": 2}], "Eksikleri Al: istenenin eksiği kadar")
	assert_eq(missing["rest"], [{"id": "stone", "n": 3}], "Kapta olmayan kalır")
	var all := inv.take_all(bag)
	assert_eq(all["moved"], [{"id": "rope", "n": 1}, {"id": "meal", "n": 4}, {"id": "lark", "n": 1}], "Hepsini Al")
	assert_true(bag.is_empty())
	assert_null(inv.saddlebags("sheep"), "Koyunun terkisi yok")


func test_act_one_kit() -> void:
	var inv := Inventory.new()
	inv.apply_kit("act1_start")
	assert_eq(inv.equipped("body"), "hostage_coat", "Kışlak Kaftanı giyili")
	assert_eq(inv.equipped("cape"), "cape_hostage", "Kışlak Pelerini giyili")
	assert_eq(inv.pack.count("notch_stick"), 1, "Çentik Çubuğu heybede")
	assert_eq(inv.tab("keepsakes"), [{"id": "notch_stick", "n": 1}])
	assert_almost(inv.load_amount(), 0.0, 1e-9, "Giyilen ve görevlik eşya sınırdan düşmez")


func test_save_block_round_trip() -> void:
	var inv := Inventory.new(Inventory.BODY_ADULT, 1043)
	inv.apply_kit("act1_start")
	inv.add("meat", 2)
	inv.on_dawn(1044)
	inv.add("meat", 1)
	inv.add("wood_pine", 3)
	inv.add("hun_bow+", 1)
	inv.add("axe_iron")
	inv.equip("feet", "felt_boots")
	inv.equip("quiver", "gorytos")
	inv.add("arrow_bronze", 30)
	inv.fill_quiver()
	inv.bell["plug"] = true
	inv.chest.add("felt", 4)
	inv.stash("way_camp").add("fish", 2, 1044)
	inv.cache.add("dried_meat", 6, "RB07")
	inv.saddlebags("offering_stallion").add("felt", 4)
	inv.saddlebags("horse@Doru").add("lark", 2)
	inv.drop("wood_pine", 1, Vector3(5, 0.5, -2))
	inv.purse_on = true
	inv.add("cowrie", 24)
	var before := inv.snapshot()
	var block := inv.to_dict()
	var text := JSON.stringify(block)
	assert_true(text.length() < 6 * 1024, "Blok küçük (%d bayt)" % text.length())
	var back := Inventory.new()
	assert_true(back.from_dict(JSON.parse_string(text)), "JSON'dan döner")
	assert_eq(JSON.stringify(back.snapshot()), JSON.stringify(before), "Bütün kaplar, kuşam, sadak ve çan aynı")
	assert_eq(back.pack.days_of("meat"), [[1043, 2], [1044, 1]], "Gün parçaları")
	assert_eq(back.piles().size(), 1, "Yer yığını")
	assert_vec_almost(back.pile_position(back.piles()[0]), Vector3(5, 0.5, -2), 0.0001)
	assert_almost(back.saddlebags("horse@Doru").cap(), 50.0, 1e-9, "Terkinin sınırı kayıttan")
	assert_eq(JSON.stringify(back.to_dict()), text, "Dönen blok aynı biçimde yeniden yazılır")
	back.on_dawn(1045)
	assert_eq(back.pack.count("spoiled"), 2, "Gün sayacı bilinir: sonraki şafak eşlenmeden bozar")
	assert_false(Inventory.new().from_dict("bozuk"), "Bozuk blok reddedilir (sahibi boş yuva sayar)")
	var odd := Inventory.new()
	assert_true(odd.from_dict({"v": 1, "pack": {"items": {"bogus": 3, "rope": 2}}, "equip": {"feet": "rope", "bow": "toy_bow"}}))
	assert_eq(odd.pack.list(), [{"id": "rope", "n": 2}], "Bilinmeyen eşya düşer")
	assert_eq(odd.equipped("feet"), "", "Yanlış yuvadaki eşya kuşanılmaz")
	assert_eq(odd.equipped("bow"), "toy_bow")


func test_mount_mods_and_signals() -> void:
	var inv := Inventory.new()
	var bag := inv.saddlebags("horse")
	bag.add("stone", 10)
	var m := inv.mount_mods("horse")
	assert_almost(float(m["speed_k"]), 0.85, 1e-9, "Dolu terkide ×0,85")
	assert_false(bool(m["can_gallop"]), "Dolu terkide dörtnal yok")
	var added := watch_signal(inv.item_added)
	var moved := watch_signal(inv.item_moved)
	inv.add("lark", 1, "hunt")
	assert_eq(added.last_args, ["lark", 1, "hunt"])
	inv.move(inv.pack, bag, "lark", 1)
	assert_eq(moved.count, 0, "Dolu terki almaz")
	bag.remove("stone", 1)
	inv.move(inv.pack, bag, "lark", 1)
	assert_eq(moved.last_args, ["pack", "saddlebags.horse", "lark", 1], "Aktarma yayılır")
	var mods := inv.move_mods()
	assert_true(mods.has("speed_k") and mods.has("back_stage"), "Denetleyicinin okuyacağı çarpanlar")
