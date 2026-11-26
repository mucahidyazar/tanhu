extends TestCase
## Eşya kataloğu ve Yük kuralları (data/economy/items.json, containers.json; ItemCatalog, CarryLoad): satırların biçimi, ekonomi
## modeliyle (docs/design/d2/econ-model.json) birebirlik, tasarımın Yük tablosu (economy/inventory-load), Çocukluk'un avı, etiket ve
## İnce İş eşlemesi, hız ve sınır formülleri.

const MODEL_PATH := "../docs/design/d2/econ-model.json"
const MODEL_FIELDS := ["tier", "w10", "per", "stack", "worth", "act", "ration", "fuel", "source"]


func before_each() -> void:
	ItemCatalog.reset_cache()
	ItemContainer.reset_rules()


func _model() -> Dictionary:
	var path := ProjectSettings.globalize_path("res://").path_join(MODEL_PATH).simplify_path()
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return (parsed as Dictionary).get("items", {}) if parsed is Dictionary else {}


func test_rows_are_well_formed() -> void:
	var ids := ItemCatalog.ids()
	assert_true(ids.size() >= 220, "Katalog bütün eşyayı taşır (%d)" % ids.size())
	var slots: Array = ItemCatalog.slots() + ItemCatalog.mount_slots()
	assert_eq(ItemCatalog.slots(), ["head", "neck", "body", "cape", "hands", "belt", "feet", "blade", "bow", "quiver"], "Kuşam yuvaları progression.md §6.1")
	for item_id in ids:
		var r := ItemCatalog.row(item_id)
		var nm: Dictionary = r.get("name", {})
		assert_true(not str(nm.get("tr", "")).is_empty() and not str(nm.get("en", "")).is_empty(), "%s adı iki dilde" % item_id)
		assert_true(ItemCatalog.TIERS.has(str(r.get("tier", ""))), "%s kademe" % item_id)
		assert_true(r.get("w10") is float and float(r["w10"]) == floorf(float(r["w10"])) and float(r["w10"]) >= 0.0, "%s w10 tamsayı" % item_id)
		assert_true(int(r.get("stack", 0)) >= 1, "%s yığın" % item_id)
		assert_true(ItemCatalog.per(item_id) >= 1, "%s per" % item_id)
		assert_true(r.get("tags") is Array, "%s etiketler" % item_id)
		if r.has("slot"):
			assert_true(slots.has(str(r["slot"])), "%s yuvası tanımlı" % item_id)
		if r.has("icon"):
			assert_not_null(HudKit.tex(str(r["icon"])), "%s simgesi atlasta" % item_id)
		for part: Variant in ItemCatalog.bundle_of(item_id):
			assert_true(ItemCatalog.has(str(part)), "%s bohçasındaki %s" % [item_id, part])
		var y: Variant = r.get("yield", {})
		for part: Variant in (y if y is Dictionary else {}):
			assert_true(ItemCatalog.has(str(part)), "%s verimindeki %s" % [item_id, part])
		for tag: Variant in ItemCatalog.tags(item_id):
			assert_ne(ItemCatalog.label("tags", str(tag)), str(tag), "%s etiketinin adı: %s" % [item_id, tag])
	for tab in ItemCatalog.TABS:
		assert_ne(ItemCatalog.label("tabs", tab), tab, "Sekme adı: %s" % tab)
	for s: Variant in slots:
		assert_ne(ItemCatalog.label("slots", str(s)), str(s), "Yuva adı: %s" % s)
	for kit_name: String in ["child", "act1_start"]:
		var k := ItemCatalog.kit(kit_name)
		assert_false(k.is_empty(), "Başlangıç donanımı: %s" % kit_name)
		for slot: Variant in k.get("equip", {}):
			assert_eq(ItemCatalog.slot_of(str(k["equip"][slot])), str(slot), "%s: %s yuvasında" % [kit_name, k["equip"][slot]])
		for item_id: Variant in k.get("pack", {}):
			assert_true(ItemCatalog.has(str(item_id)), "%s: %s" % [kit_name, item_id])


func test_economy_model_rows_are_copied_exactly() -> void:
	var model := _model()
	if model.is_empty():
		push_warning("[test] ekonomi modeli okunamadı (%s): karşılaştırma atlandı" % MODEL_PATH)
		return
	assert_true(model.size() >= 135, "Modelin satırları")
	for item_id: Variant in model:
		var m: Dictionary = model[item_id]
		var r := ItemCatalog.row(str(item_id))
		assert_false(r.is_empty(), "%s katalogda" % item_id)
		if r.is_empty():
			continue
		assert_eq([str(r["name"]["tr"]), str(r["name"]["en"])], [str(m["tr"]), str(m["en"])], "%s adı modelinki" % item_id)
		for f: String in MODEL_FIELDS:
			if m.has(f):
				assert_eq(r.get(f), m[f], "%s.%s modelinki" % [item_id, f])
			else:
				assert_true(not r.has(f) or r[f] == null or (f == "per" and int(r[f]) == 1), "%s.%s modelde yok" % [item_id, f])
		var a: Array = (r["tags"] as Array).duplicate()
		var b: Array = (m["tags"] as Array).duplicate()
		a.sort()
		b.sort()
		assert_eq(a, b, "%s etiketleri" % item_id)
		assert_eq(r.get("bundle"), m.get("bundle"), "%s bohçası" % item_id)


func test_design_load_table() -> void:
	# economy/inventory-load «Yük» tablosu ve progression.md §6.2 (giyilenin Yük'ü).
	var table := {"wood_pine": 40, "wood_juniper": 40, "wood_willow": 30, "wood_saxaul": 50, "stone": 50, "ore_iron": 40, "waterskin": 30,
		"clay": 30, "yurt_kit": 590, "yurt_kit_s": 380, "tent_kit": 160, "iron_bar": 20, "bronze_bar": 20, "fodder": 20, "barley_sack": 20,
		"grain_sack": 20, "hide": 15, "fur_big": 15, "felt": 10, "hay": 10, "leather": 10, "wool": 5, "rope": 5, "reed": 5, "meat": 5,
		"meal": 1, "dried_meat": 1, "qurt": 1, "cauldron": 80, "hostage_coat": 10, "hide_lamellar": 40, "bronze_scale": 80, "iron_lamellar": 100,
		"toy_bow": 3}
	for item_id: String in table:
		assert_eq(ItemCatalog.stack_load10(item_id, 1), int(table[item_id]), "%s Yük'ü" % item_id)
	assert_eq(ItemCatalog.stack_load10("otag_kit", 1), 1092, "Otağ Yükü ≈109")
	assert_eq(ItemCatalog.stack_load10("arrow_bone", 10), 5, "On ok 0,5")
	assert_eq(ItemCatalog.stack_load10("cowrie", 100), 1, "Yüz kabuk 0,1")
	assert_eq(ItemCatalog.stack_load10("cowrie", 101), 2, "Yüz bir kabuk yukarı yuvarlanır")
	assert_eq(ItemCatalog.name_of("hostage_coat"), "Kışlak Kaftanı", "Rehine kılığı Kışlak oldu (progression.md §6.2)")
	assert_eq(ItemCatalog.name_of("cape_hostage", "en"), "Winter Camp Cape")
	assert_false(ItemCatalog.has("white_felt"), "Ak Keçe pelerini kalktı (malzeme felt_white ayrı)")
	assert_true(ItemCatalog.has("felt_white"))
	assert_eq(ItemCatalog.slot_of("bridle_bone"), "bridle", "Kemik Gem I. Perde'nin gemi (K65)")
	assert_eq(ItemCatalog.slot_of("dyed_cape"), "cape", "Boyalı Pelerin sırt yuvasında (K58)")


func test_childhood_game_rows_follow_the_fauna_yield() -> void:
	var kinds_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/fauna/kinds.json"))
	var kinds: Dictionary = (kinds_raw as Dictionary).get("kinds", {}) if kinds_raw is Dictionary else {}
	for kind: String in ["lark", "gerbil", "partridge", "crow", "marmot"]:
		var r := ItemCatalog.row(kind)
		assert_false(r.is_empty(), "Çocukluk'un avı katalogda: %s" % kind)
		if r.is_empty() or not kinds.has(kind):
			continue
		assert_eq(str(r.get("game", "")), kind, "%s faunanın türü" % kind)
		assert_eq(r.get("yield"), kinds[kind].get("yield"), "%s verimi kinds.json'unki" % kind)
		assert_eq(ItemCatalog.name_of(kind), str(kinds[kind]["name"]["tr"]), "%s adı faunanınki" % kind)
		var sum := 0
		for part: Variant in r["yield"]:
			sum += ItemCatalog.stack_load10(str(part), int(r["yield"][part]))
		assert_eq(ItemCatalog.w10(kind), sum, "%s Yük'ü veriminin toplamı" % kind)
		assert_eq(ItemCatalog.tab_of(kind), "food", "%s Erzak'ta" % kind)
		assert_eq(ItemCatalog.perish_of(kind), "meat", "%s çiğ et gibi bozulur" % kind)
	assert_eq(ItemCatalog.icon_of("lark"), "icon_lark")
	assert_eq(ItemCatalog.icon_of("gerbil"), "icon_mouse")
	assert_eq(ItemCatalog.slot_of("toy_bow"), "bow", "Oyuncak yay yay yuvasında")


func test_tags_fine_work_and_names() -> void:
	assert_true(ItemCatalog.matches("wood_larch", "tag:wood"))
	assert_false(ItemCatalog.matches("sprig_juniper", "tag:wood"), "Ad öneki kuralı yok")
	assert_true(ItemCatalog.matches("hun_bow+", "hun_bow"), "İnce İş düz kimliğe uyar")
	assert_false(ItemCatalog.matches("hun_bow", "hun_bow+"))
	assert_true(ItemCatalog.row("felt+").is_empty(), "Malzemede İnce İş yok")
	assert_eq(ItemCatalog.name_of("hun_bow+"), "Hun Yayı · İnce İş")
	assert_eq(ItemCatalog.name_of("hun_bow+", "en"), "Hun Bow · Fine Work")
	assert_almost(ItemCatalog.worth_of("hide"), 8.0)
	assert_almost(ItemCatalog.worth_of("hun_bow"), -1.0, 0.0001, "Teçhizatın Kıymeti yok")
	assert_eq(ItemCatalog.name_of("nope"), "nope", "Bilinmeyen kimlik kendi adıyla")
	assert_eq(ItemCatalog.tab_of("shrieker"), "keepsakes", "Çığırtkan görevlik")
	assert_true(ItemCatalog.is_keepsake("notch_stick"))
	assert_true(ItemCatalog.is_tool_item("axe_bronze"))
	assert_false(ItemCatalog.uses_slot("axe_bronze"), "Araç yuva tutmaz")
	assert_eq(ItemCatalog.label("tabs", "food", "en"), "Provisions")
	assert_eq(ItemContainer.kind_name("saddlebags"), "Terki")


func test_carry_rules_follow_the_design_table() -> void:
	# economy/inventory-load «Hız cezası» tablosu.
	for row: Array in [[0.0, 1.0, 1.0], [0.25, 0.925, 1.0], [0.5, 0.85, 1.0], [0.75, 0.775, 0.85], [1.0, 0.7, 0.7]]:
		assert_almost(CarryLoad.speed_k(row[0]), row[1], 1e-9, "Doluluk %s hız" % row[0])
		assert_almost(CarryLoad.speed_k(row[0], 0.5), row[2], 1e-9, "Doluluk %s Sırt Yükü ile" % row[0])
	assert_almost(CarryLoad.speed_k(1.4), 0.7, 1e-9, "Sınırı aşan yük 0,7'nin altına düşürmez")
	assert_true(CarryLoad.can_run(0.75) and not CarryLoad.can_run(0.76), "Dörtte üçü geçince koşu yok")
	assert_true(CarryLoad.can_jump(0.5) and not CarryLoad.can_jump(0.51), "Yarıyı geçince zıplama yok")
	assert_almost(CarryLoad.run_cost_k(1.0), 2.0, 1e-9, "Tam yükte koşunun gideri ×2")
	assert_eq([CarryLoad.back_stage(0.05), CarryLoad.back_stage(0.1), CarryLoad.back_stage(0.4), CarryLoad.back_stage(0.75), CarryLoad.back_stage(1.0)],
		[0, 1, 2, 4, 5], "Sırt yığını beş kademe")
	assert_almost(CarryLoad.cap_of(3, false, 0.0), 21.0, 1e-9, "Bilek 3: 21 Yük")
	assert_almost(CarryLoad.cap_of(4, false, 0.0), 24.0, 1e-9, "Zırhlı Atlılar Arasında kökeni (Bilek 4): 24")
	assert_almost(CarryLoad.cap_of(7, true, 0.0), 41.0, 1e-9, "I. Perde'nin tavanı 41")
	assert_almost(CarryLoad.cap_of(3, false, 4.0), 25.0, 1e-9, "Kese Kuşak +4")
	assert_almost(CarryLoad.mount_speed_k(0.5), 1.0, 1e-9, "Terkinin yarısına dek ×1")
	assert_almost(CarryLoad.mount_speed_k(1.0), 0.85, 1e-9, "Dolu terkide ×0,85")
	assert_false(CarryLoad.can_gallop(0.8), "Dörtte üçü geçince dörtnal yok")
	assert_almost(CarryLoad.mount_cap("horse"), 50.0, 1e-9, "Kampın atı: mounts.json load")
	assert_almost(CarryLoad.mount_cap("sheep"), 0.0, 1e-9, "Koyunun terkisi yok")
	assert_almost(CarryLoad.mount_cap("yakwe"), 40.0, 1e-9, "Yakve 40 (mounts.json'da satırı yokken yedek tablo)")
	assert_almost(CarryLoad.cart_cap("pack_camel"), 60.0, 1e-9, "Deve yük atının iki katı (K65)")
	# Çocuk tek kütük taşır, hızı ×0,8: 4 Yük'lük kütük 6'nın üçte ikisi.
	assert_almost(CarryLoad.body_cap("child"), 6.0, 1e-9)
	assert_almost(CarryLoad.speed_k(4.0 / CarryLoad.body_cap("child")), 0.8, 1e-9, "Çocuk kütükle ×0,8")
