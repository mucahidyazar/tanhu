extends TestCase
## «Ebenin Çetelesi»nin envanter yolu (TallyErrand; K110, story.md §5): kurut torbası heybeye girer, Hereka'ya verilince düşer; yedi çentikli
## çetele heybeye girer, sayım gününde sayıcıya verilince düşer. İki eşya görevliktir (Görevlik sekmesi, bırakılmaz); çetelenin simgesi
## kodla çizilir (yedi çentik), torbanınki bağlı ağızlı torbadır. Sayım günü: sayıcının «Hereka'nın çentikleri. Yedi.»si yalnız çetele
## heybedeyken gelir; bugünkü adımların sırası ve sözleri değişmez.

const SCENE := "res://data/story/childhood/scene.json"
const LINES := "../docs/design/d3/e21-lines.json"


func before_each() -> void:
	ItemCatalog.reset_cache()


func _child() -> Inventory:
	var inv := Inventory.new()
	inv.reset_body(Inventory.BODY_CHILD)
	return inv


func test_curd_goes_in_and_out_then_the_stick_goes_in_and_out() -> void:
	var inv := _child()
	assert_eq(inv.equipped("bow"), "toy_bow", "Çocuğun oyuncak yayı yerinde")
	assert_false(TallyErrand.has_curd(inv))
	assert_true(TallyErrand.give_curd(inv), "Lan Hatun kurut torbasını verir")
	assert_eq(inv.count(TallyErrand.CURD), 1)
	assert_true(TallyErrand.give_curd(inv))
	assert_eq(inv.count(TallyErrand.CURD), 1, "İkinci kez verilmez")
	assert_true(TallyErrand.hand_curd(inv), "Hereka'ya verilir")
	assert_false(TallyErrand.has_curd(inv), "Heybeden düşer")
	assert_false(TallyErrand.hand_curd(inv), "Olmayan verilmez (ceza yok)")
	assert_false(TallyErrand.has_stick(inv))
	assert_true(TallyErrand.take_stick(inv), "Çetele heybeye girer")
	assert_true(TallyErrand.take_stick(inv))
	assert_eq(inv.count(TallyErrand.STICK), 1, "Bir çetele")
	assert_true(TallyErrand.has_stick(inv), "Sayım gününe dek heybede")
	assert_true(TallyErrand.give_stick(inv), "Sayıcıya verilir")
	assert_false(TallyErrand.has_stick(inv), "Heybeden düşer")
	assert_eq(inv.equipped("bow"), "toy_bow", "Yay yerinde kalır")


func test_both_items_are_keepsakes_and_cannot_be_dropped() -> void:
	for id: String in [TallyErrand.CURD, TallyErrand.STICK]:
		assert_true(ItemCatalog.has(id), "%s katalogda" % id)
		assert_eq(ItemCatalog.tab_of(id), "keepsakes", "%s Görevlik sekmesinde" % id)
		assert_true(ItemCatalog.is_keepsake(id), "%s görevlik" % id)
		var nm: Dictionary = ItemCatalog.row(id).get("name", {})
		assert_false(str(nm.get("tr", "")).is_empty() or str(nm.get("en", "")).is_empty(), "%s adı iki dilde" % id)
	assert_eq(TallyErrand.notches(), 7, "Yedi çentik")
	var bag := HudBag.new()
	bag.reset(true)
	bag.add(TallyErrand.STICK, 1)
	var entry := bag.entry(TallyErrand.STICK, 1)
	assert_false((entry["actions"] as Array).has("drop"), "Çetele bırakılmaz")
	assert_eq(HudItemIcon.glyph_of(TallyErrand.STICK), "tally", "Çetelenin simgesi çentikli çubuk")
	assert_eq(HudItemIcon.glyph_of(TallyErrand.CURD), "pouch", "Torbanın simgesi bağlı ağızlı torba")


func test_count_day_says_the_stick_line_only_with_the_stick_and_keeps_its_order() -> void:
	var d := ChildhoodScene.load_data(SCENE)
	var lines: Dictionary = d.get("lines", {})
	assert_true(lines.has("count_stick"), "Sayım gününün yeni sözü")
	assert_eq(str(d.get("vo_prefix", "")) + "count_stick", "act0.child.count_stick", "Söz kimliği")
	assert_eq(str(lines["count_stick"]["speaker"]), "counter", "Sayıcı söyler")
	# Metin e21-lines.json'dakidir.
	var path := ProjectSettings.globalize_path("res://").path_join(LINES).simplify_path()
	if FileAccess.file_exists(path):
		var src: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		var found := false
		for l: Dictionary in src.get("lines", []):
			if str(l.get("id", "")) == "act0.child.count_stick":
				found = true
				assert_eq(str(lines["count_stick"]["tr"]), str(l["tr"]), "TR metin kaynağınki")
				assert_eq(str(lines["count_stick"]["en"]), str(l["en"]), "EN metin kaynağınki")
		assert_true(found, "Kaynakta var")
	var count: Dictionary = {}
	for s: Dictionary in d.get("steps", []):
		if str(s.get("kind", "")) == "count":
			count = s
	var ex: Array = count.get("exchange", [])
	# Bugünkü sıra değişmez: «Bir çocuk.» yine altıncı girdidir; çetelenin sözü onun «before»ıdır, koşulu çetelenin heybede olmasıdır.
	assert_eq(str(ex[5].get("line", "")), "count_child")
	var before: Dictionary = ex[5].get("before", {})
	assert_eq(str(before.get("line", "")), "count_stick", "«Bir çocuk.»tan önce")
	assert_eq(str(before.get("if", "")), "has_stick", "Yalnız çetele heybedeyken")
	assert_eq(str(before.get("item", "")), TallyErrand.STICK)
	assert_true(bool(before.get("take", false)), "Çetele heybeden düşer")
	var order := PackedStringArray()
	for e: Dictionary in ex:
		order.append(str(e.get("line", "-")))
	assert_eq(order, PackedStringArray(["look_down", "-", "-", "my_bird", "-", "count_child", "mete_catch", "count_answer"]), "Sözlerin sırası bugünkü gibi")
	assert_eq(ChildhoodScene.validate(d), PackedStringArray(), "Veri sorunsuz")


func test_day_lines_match_the_e21_source() -> void:
	# Sözlerin metni docs/design/d3/e21-lines.json'dakidir (kimlik act0.bone.* ve act0.tally.*; elle değiştirilmez).
	var path := ProjectSettings.globalize_path("res://").path_join(LINES).simplify_path()
	if not FileAccess.file_exists(path):
		push_warning("[test] e21-lines.json okunamadı: karşılaştırma atlandı")
		return
	var src: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var by_id := {}
	for l: Dictionary in src.get("lines", []):
		by_id[str(l["id"])] = l
	for day: String in ["res://data/story/childhood_days/day1_bone.json", "res://data/story/childhood_days/day2_tally.json"]:
		var d := ChildhoodScene.load_data(day)
		var prefix := str(d.get("vo_prefix", ""))
		var lines: Dictionary = d.get("lines", {})
		var count := 0
		for id: String in by_id:
			if not id.begins_with(prefix):
				continue
			count += 1
			var key := id.substr(prefix.length())
			assert_true(lines.has(key), "%s: %s günün dosyasında" % [day.get_file(), id])
			if not lines.has(key):
				continue
			for f: String in ["speaker", "tr", "en"]:
				assert_eq(str(lines[key][f]), str(by_id[id][f]), "%s.%s kaynağınki" % [id, f])
			var sp := str(by_id[id]["speaker"])
			assert_true((d.get("speakers", {}) as Dictionary).has(sp), "%s: konuşan %s" % [day.get_file(), sp])
		assert_eq(count, lines.size(), "%s: kaynakta olmayan söz yok" % day.get_file())
