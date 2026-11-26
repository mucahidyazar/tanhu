extends TestCase
## Ateşin ve hayatta kalmanın görünüşü (Yol Haritası fire-hunting, hunger-wounds): FireView evreye göre alev, ışık (Kor 1,6, Küçük 6, Orta 10,
## Büyük 14 m; gölgesiz), kıvılcım, duman ve çıtırtı taşır; küllenmiş közde ışık ve duman yok, çukurda kül halkası; yer halkası 6 m içinde
## yakıtı gösterir; oyuncu ateşin içinden geçmez. HudNeeds (Vitals'ın dili) Tokluk'u ve yara baklavalarını gösterir; tarif çemberi
## (CookWheel) bilinen tarifleri, Yakıt ve Ocağa Pay dilimlerini taşır. MapLayers deneme haritasının «layers» satırını okur.

var _nodes: Array[Node] = []


func after_each() -> void:
	for n in _nodes:
		if is_instance_valid(n):
			n.free()
	_nodes.clear()


func _view(fuel: float, stones := false, state := FireState.LIT) -> FireView:
	var f := FireState.new()
	f.id = "t"
	f.light(Vector2.ZERO, "z", stones, fuel, 0.0)
	if state == FireState.PIT:
		f.advance(10000.0, 1.0)
	elif state == FireState.BANKED:
		f.bank(1000.0, 1.0)
	var v := FireView.new()
	v.fire = f
	add_child(v)
	_nodes.append(v)
	v.bind(f)
	return v


func test_view_follows_stage_and_state() -> void:
	var blaze := _view(700.0)
	var look := blaze.look()
	assert_eq(str(look["stage"]), "blaze")
	assert_true(bool(look["light"]), "Işık")
	assert_almost(float(look["light_range"]), 14.0, 1e-6, "Büyük 14 m")
	assert_eq(int(look["flames"]), 5, "Beş alev katmanı")
	assert_true(bool(look["smoke"]) and bool(look["sparks"]), "Duman ve kıvılcım")
	var steady := _view(300.0)
	assert_almost(float(steady.look()["light_range"]), 10.0, 1e-6, "Orta 10 m")
	var small := _view(100.0)
	assert_almost(float(small.look()["light_range"]), 6.0, 1e-6, "Küçük 6 m")
	assert_eq(int(small.look()["flames"]), 3, "Küçük alev")
	var embers := _view(30.0)
	assert_eq(int(embers.look()["flames"]), 0, "Kor alevsiz")
	assert_almost(float(embers.look()["light_range"]), 1.6, 1e-6, "Kor çok az ışık")
	assert_false(bool(embers.look()["sound"]), "Kor sessiz")
	var banked := _view(30.0, false, FireState.BANKED)
	assert_false(bool(banked.look()["light"]), "Küllenmiş közde ışık yok")
	assert_false(bool(banked.look()["smoke"]), "Duman yok")
	var pit := _view(10.0, true, FireState.PIT)
	assert_false(bool(pit.look()["light"]) or bool(pit.look()["smoke"]), "Çukur: ışık ve duman yok")
	assert_true(bool(pit.look()["stones"]), "Taş halkası kalır")
	for v: FireView in [blaze, steady, small, embers, banked, pit]:
		for c in v.get_children():
			if c is OmniLight3D:
				assert_false((c as OmniLight3D).shadow_enabled, "Oyuncu ateşinin ışığı gölgesiz (K63)")


func test_view_rebuilds_when_the_fire_changes_and_shows_the_ring() -> void:
	var v := _view(300.0)
	assert_eq(v.look_key(), "lit|steady|")
	v.fire.advance(100.0, 40.0)
	await wait_frames(2)
	assert_eq(str(v.look()["stage"]), "small", "Evre değişince yeniden kurulur")
	v.fire.douse(50.0)
	await wait_frames(2)
	assert_false(bool(v.look()["light"]), "Söndürülen ateş çukur")
	var w := _view(360.0)
	w.show_ring = true
	var ring := w.get_node_or_null(^"Ring") as MeshInstance3D
	assert_true(ring != null and ring.visible, "6 m içinde yer halkası")
	await wait_frames(1)
	assert_almost(float((ring.material_override as ShaderMaterial).get_shader_parameter(&"fill")), 0.5, 0.01, "Halka kalan yakıtı gösterir (360 / 720)")
	w.show_ring = false
	assert_false(ring.visible)
	assert_eq(w.get_obstacle_circles().size(), 1, "Oyuncu ateşin içinden geçmez")
	assert_almost(w.get_obstacle_circles()[0].z, 0.55, 1e-6, "Taşsız ateş 0,55 m")
	var p := _view(10.0, false, FireState.PIT)
	assert_eq(p.get_obstacle_circles().size(), 0, "Taşsız kül çukurunun üstünden geçilir")


func test_hud_needs_shows_fullness_and_wounds() -> void:
	var s := Survival.new({"difficulty": "hard"})
	var hn := HudNeeds.new()
	hn.survival = s
	add_child(hn)
	_nodes.append(hn)
	assert_true(hn.active())
	assert_eq(hn.bar_text(), "60")
	assert_eq(hn.diamonds(), [0, 2], "Zor'da iki baklava")
	s.wounds.add(1)
	s.needs.fullness = 12.4
	assert_eq(hn.bar_text(), "12")
	assert_eq(hn.diamonds(), [1, 2])
	await wait_frames(2)
	var roam := HudNeeds.new()
	roam.survival = Survival.new({"mode": "roam"})
	add_child(roam)
	_nodes.append(roam)
	assert_false(roam.active(), "Serbest Gez'de Tokluk ve yara gösterilmez")
	assert_eq(roam.bar_text(), "")


func test_cook_wheel_lists_recipes_fuel_and_share() -> void:
	var inv := Inventory.new()
	inv.add("meat", 1)
	var s := Survival.new({"inventory": inv})
	var f := s.fires.add(Vector2.ZERO, s.zone, true, 300.0, 0.0)
	f.old = true
	var w := CookWheel.new()
	w.setup(s, f)
	add_child(w)
	_nodes.append(w)
	var kinds: Array = w.slots().map(func(o: Dictionary) -> String: return str(o["kind"]))
	assert_eq(kinds.count("fuel"), 1, "Yakıt dilimi")
	assert_eq(kinds.count("share"), 1, "Ocağa Pay dilimi")
	var ids: Array = w.slots().map(func(o: Dictionary) -> String: return str(o["id"]))
	var spit: int = ids.find("spit_meat")
	var meal: int = ids.find("meal")
	assert_true(spit >= 0 and bool(w.slots()[spit]["ok"]), "Şiş Et pişebilir")
	assert_true(meal >= 0 and not bool(w.slots()[meal]["ok"]), "Aş: darı yok")
	var fuel_i: int = kinds.find("fuel")
	assert_true(w.pick(fuel_i))
	assert_eq(s.fuel_choice, "branch", "Yakıt dilimi sıradakine döner")
	var share_i: int = kinds.find("share")
	assert_true(w.pick(share_i))
	assert_true(w.share, "Ocağa Pay açık")
	var chosen := watch_signal(w.chosen)
	assert_false(w.pick(meal), "Pişemeyen tarif seçilmez")
	assert_true(w.pick(spit))
	assert_eq(chosen.count, 1)
	assert_eq(chosen.last_args, ["spit_meat", true], "Tarif ve Ocağa Pay")
	# Yerleşimin ocağında Yakıt dilimi yok (halk besler); tarifler ve Ocağa Pay var.
	var h := s.fires.add_hearth(Vector2(30.0, 0.0), s.zone, "hearth_test")
	var hw := CookWheel.new()
	hw.setup(s, h)
	add_child(hw)
	_nodes.append(hw)
	var hkinds: Array = hw.slots().map(func(o: Dictionary) -> String: return str(o["kind"]))
	assert_eq(hkinds.count("fuel"), 0, "Ocakta Yakıt dilimi yok")
	assert_eq(hkinds.count("share"), 1, "Ocağa Pay var")
	assert_true(hkinds.count("recipe") > 0, "Tarifler var")


func test_map_layers_read_the_testmap_line() -> void:
	MapSpec.forget_cache()
	var spec := MapSpec.find(MapSpec.TESTMAP)
	assert_eq(str(spec.layers.get("survival", "")), "res://data/maps/testmap/survival.json", "map.json'ın «layers» satırında ateş ve av katmanı")
	var def := MapLayers.read(str(spec.layers["survival"]))
	assert_eq(str(def.get("script", "")), "res://scripts/survival/survival_layer.gd")
	assert_eq(str(def.get("zone", "")), "testmap")
	var sig_before := MapBaker.signature(spec)
	var copy := MapSpec.from_dict(JSON.parse_string(FileAccess.get_file_as_string(MapSpec.path_for(MapSpec.TESTMAP))))
	copy.layers = {}
	assert_eq(MapBaker.signature(copy), sig_before, "Katman pişmiş parçaların imzasına girmez")
	var holder := Node3D.new()
	add_child(holder)
	_nodes.append(holder)
	var built := MapLayers.build(holder, {"nope": "res://data/maps/testmap/yok.json"})
	assert_eq(built.size(), 0, "Okunamayan katman atlanır")
	expect_errors(PackedStringArray())


func test_kit_fits_the_pack_and_places_are_valid() -> void:
	var def := MapLayers.read("res://data/maps/testmap/survival.json")
	var inv := Inventory.new()
	for id: String in def["kit"]:
		assert_true(ItemCatalog.has(id), "Takımın eşyası: %s" % id)
		inv.add(id, int(def["kit"][id]))
	for id: String in def["kit"]:
		assert_eq(inv.count(id), int(def["kit"][id]), "%s Heybe'ye sığdı" % id)
	# Yük hıza bağlıdır (CarryLoad): takım sınırın yarısının altında kalır, Mete koşar ve zıplar.
	assert_true(inv.load_amount() <= inv.capacity() * 0.5, "Takım hafif: %.1f / %.1f Yük" % [inv.load_amount(), inv.capacity()])
	assert_true(inv.can_run() and inv.can_jump(), "Takımla koşu ve zıplama açık")
	var s := Survival.new({"inventory": inv})
	assert_true(s.has_build_materials(), "Takımla ateş kurulur")
	# Yedek yakıt ve erzak Doru'nun terkisinde: haritada at kaydı var, terki sınırına sığar.
	var sb: Dictionary = def["saddlebags"]
	var spec := MapSpec.find(MapSpec.TESTMAP)
	var horse_ids: Array = spec.structures.filter(func(r: Dictionary) -> bool: return str(r["kind"]) == "horse").map(
		func(r: Dictionary) -> String: return str(r["id"]))
	assert_true(horse_ids.has(str(sb["mount"])), "Terkinin atı haritada: %s" % sb["mount"])
	var bag := inv.saddlebags("horse@%s" % str(sb["mount"]).to_pascal_case())
	assert_not_null(bag, "Atın terkisi var")
	for id: String in sb["items"]:
		assert_true(ItemCatalog.has(id), "Terkinin eşyası: %s" % id)
		bag.add(id, int(sb["items"][id]))
		assert_eq(bag.count(id), int(sb["items"][id]), "%s terkiye sığdı" % id)
	assert_true(bag.load_amount() <= CarryLoad.mount_cap("horse"), "Terki sınırı (%.1f)" % bag.load_amount())
	var yurts: Array = []
	for rec: Dictionary in spec.structures:
		if str(rec["kind"]) == "yurt":
			yurts.append(Vector3(rec["at"].x, rec["at"].y, float(rec["radius"])))
	for h: Dictionary in def["old_hearths"]:
		var at := MapSpec.vec2(h["at"])
		assert_eq(s.fires.can_place(at, {"structures": yurts}), "", "Eski Ocak yurtlardan uzak: %s" % [at])
		assert_true(spec.rect().has_point(at) and at.distance_to(spec.play_center) < spec.play_radius, "Eski Ocak yürünür alanda")
