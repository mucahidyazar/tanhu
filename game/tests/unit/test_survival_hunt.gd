extends TestCase
## Av verimi (Yol Haritası fire-hunting; survival.md §4.6, §4.7, fauna.md §1, economy.md §3.6): türün verimi kinds.json'dadır (taban
## fauna.md §1; tarbaganın güz eki yield_season), tek okta düşen avda +1 deri, Avcı becerisi ilk kaleme +1; yetişkin yüzer ve eşya
## verim verim Heybe'ye girer (sığmayan yakındaki atın terkisine, sonra leşin yerine yer yığını), büyük av bıçak ister, küçük av istemez;
## bütün av (Çocukluk'un tarla kuşu, tarbaganı) düzülünce aynı verimi verir; tür başına ilk av +40 XP (bir kez).


func test_yields_follow_fauna_md_and_the_autumn_fat() -> void:
	assert_eq(Hunt.yield_of("crow"), {"feather": 1}, "fauna.md §1: karga 1 tüy")
	assert_eq(Hunt.yield_of("partridge"), {"meat_small": 1, "feather": 1}, "Keklik 1 küçük et, 1 tüy")
	assert_eq(Hunt.yield_of("lark"), {"meat_small": 1})
	assert_eq(Hunt.yield_of("gerbil"), {"meat_small": 1})
	assert_eq(Hunt.yield_of("marmot", {"season": &"spring"}), {"meat": 1, "fat": 1, "hide_small": 1}, "Tarbaganın tabanı")
	assert_eq(Hunt.yield_of("marmot", {"season": &"autumn"}), {"meat": 1, "fat": 2, "hide_small": 1}, "Güzde +1 iç yağı")
	assert_eq(Hunt.yield_of("marmot", {"clean": true}), {"meat": 1, "fat": 1, "hide_small": 2}, "Tek okta düşen avda +1 deri (küçük post)")
	assert_eq(Hunt.yield_of("crow", {"clean": true}), {"feather": 1}, "Derisi olmayan avda deri eki yok")
	assert_eq(Hunt.yield_of("marmot", {"hunter": 1}), {"meat": 2, "fat": 1, "hide_small": 1}, "Avcı becerisi ilk kaleme +1")
	assert_eq(Hunt.yield_of("lark", {"kopuz": true}), {"meat_small": 2}, "Kopuz Gecesi +1 verim")
	assert_eq(Hunt.yield_of("nope"), {}, "Bilinmeyen tür")
	var sheep: Dictionary = Hunt.yield_of("sheep")
	assert_eq(int(sheep.get("meat", 0)), 6, "Koyunun kesim verimi de kinds.json'dan")


func test_knife_rule() -> void:
	var inv := Inventory.new()
	assert_true(Hunt.is_small("lark"), "Kuş küçük avdır")
	assert_true(Hunt.is_small("gerbil"), "Canı 8 ve altı küçüktür")
	assert_false(Hunt.is_small("marmot"), "Tarbagan (can 10) bıçak ister")
	assert_false(Hunt.is_small("sheep"))
	assert_eq(Hunt.skin_block("lark", inv), "", "Küçük av bıçaksız yüzülür")
	assert_eq(Hunt.skin_block("marmot", inv), "need_knife")
	inv.add("knife_iron", 1)
	assert_eq(Hunt.skin_block("marmot", inv), "", "Heybe'deki bıçak")
	inv.remove("knife_iron", 1)
	inv.add("knife_iron", 1)
	inv.equip("blade", "knife_iron")
	assert_eq(Hunt.skin_block("marmot", inv), "", "Kuşanılan bıçak")
	assert_almost(Hunt.skin_seconds(), 2.0, 1e-9, "Yüz: E basılı 2 sn")
	assert_almost(Hunt.skin_seconds(0.5), 1.0, 1e-9, "Avcı becerisi yarı sürede")


func test_skin_delivers_item_by_item_and_spills_to_the_ground() -> void:
	var inv := Inventory.new()
	inv.add("knife_iron", 1)
	var p := Progression.new()
	var s := Survival.new({"inventory": inv, "progression": p})
	var got := watch_signal(s.hunted)
	var r := s.skin("marmot", Vector3(4.0, 0.0, 2.0))
	assert_true(bool(r["ok"]))
	assert_eq(inv.count("meat"), 1, "Et Heybe'de")
	assert_eq(inv.count("fat"), 1, "İç yağı Heybe'de (bahar)")
	assert_eq(inv.count("hide_small"), 1, "Küçük post Heybe'de")
	assert_eq(inv.count("marmot"), 0, "Yetişkin bütün hayvanı değil verimi alır")
	assert_eq(p.xp, 40, "Türün ilk avı +40 XP")
	assert_true(bool(r["first"]))
	assert_eq(got.count, 1)
	s.skin("marmot", Vector3(4.0, 0.0, 2.0))
	assert_eq(p.xp, 40, "Aynı tür ikinci kez XP vermez")
	assert_eq(inv.count("meat"), 2)
	var full := Inventory.new()
	full.add("knife_iron", 1)
	full.add("wood_pine", 5)
	full.add("dung", 2)
	assert_almost(full.load_amount(), full.capacity(), 1e-9, "Heybe tam dolu (21 Yük)")
	var fs := Survival.new({"inventory": full})
	var at := Vector3(10.0, 0.0, -3.0)
	r = fs.skin("marmot", at)
	assert_eq(full.count("meat"), 0, "Heybe dolu: Heybe'ye girmez")
	assert_eq(full.piles().size(), 1, "Leşin yerine yer yığını")
	assert_eq(full.pile_position(full.piles()[0]), at)
	assert_eq((full.piles()[0] as ItemContainer).count("meat"), 1)
	assert_eq((full.piles()[0] as ItemContainer).count("fat"), 1)
	var no_knife := Survival.new({"inventory": Inventory.new()})
	assert_false(bool(no_knife.skin("marmot", at)["ok"]), "Bıçaksız tarbagan yüzülmez")
	assert_true(bool(no_knife.skin("partridge", at)["ok"]), "Keklik bıçaksız")
	assert_eq(no_knife.inv().count("feather"), 1)


func test_skin_uses_the_season_from_the_clock() -> void:
	var inv := Inventory.new()
	inv.add("knife_iron", 1)
	var autumn := GameCalendar.day_n_of(22, 9, 228)
	var s := Survival.new({"inventory": inv, "clock": GameClock.new(autumn, 600.0)})
	assert_eq(s.season(), &"autumn", "22 Eylül güzdür (oyunun takvimi)")
	s.skin("marmot")
	assert_eq(inv.count("fat"), 2, "Güzde tarbagan 2 iç yağı")


func test_dress_turns_a_whole_carcass_into_its_yield() -> void:
	var inv := Inventory.new()
	inv.add("lark", 2)
	inv.add("partridge", 1)
	var r := Hunt.dress(inv, "lark")
	assert_eq(r["added"], {"meat_small": 1})
	assert_eq(inv.count("lark"), 1)
	Hunt.dress(inv, "partridge")
	assert_eq(inv.count("feather"), 1)
	assert_eq(Hunt.dress(inv, "meat"), {}, "Av olmayan düzülmez")
	assert_eq(Hunt.dress(inv, "crow"), {}, "Heybede yoksa düzülmez")
	for kind: String in ["lark", "gerbil", "partridge", "crow", "marmot"]:
		var row_yield := {}
		for k: String in ItemCatalog.row(kind).get("yield", {}):
			row_yield[k] = int(ItemCatalog.row(kind)["yield"][k])
		assert_eq(row_yield, Hunt.yield_of(kind), "%s bütün avın verimi türün tabanı" % kind)
	var s := Survival.new({"inventory": inv, "clock": GameClock.new(GameCalendar.day_n_of(22, 9, 228), 600.0)})
	inv.add("marmot", 1)
	s.dress("marmot")
	assert_eq(inv.count("fat"), 2, "Güzde düzülen tarbagan 2 iç yağı")
	assert_eq(Hunt.items_text({"meat": 1, "fat": 2}), "Et ×1, İç Yağı ×2")
