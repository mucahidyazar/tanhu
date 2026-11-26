extends TestCase
## Yapı kaydından dünya (building-catalog, staged-building; StructureKit, StructureCatalog, StructureSet, YurtField; K51 şeması; act1.md §4
## «Kışlak yerleşimi»; structures.md §3.6, §4, §13.5, §13.6; godot.md §4.6): kayıt normalize edilir (rot, facing, adsız yurdun kapısı
## ocağa), katalogun her türü kurulur ve ≤6k üçgen, ≤2 çizimdir, iz dünya koordinatındadır; Kışlak'ın kayıtları ≤160, açık yurt ≤3,
## canlı yapı ≤48; uzaklık kademesi en yakın 4 yurdu ≤40 m'de tam kurar, gerisi YurtField'in örneğidir (millet başına 2 çizim).

const KISLAK := "kislak"


func before_each() -> void:
	MapSpec.forget_cache()


func test_normalize_reads_k51_and_old_fields() -> void:
	var r := StructureKit.normalize({"kind": "yurt", "id": "a", "at": [10.0, 5.0], "facing": 90.0})
	assert_almost(float(r["rot"]), PI - deg_to_rad(90.0), 1e-6, "Pusula facing'i rot olur (yaw = π − facing)")
	var u := StructureKit.normalize({"kind": "hearth", "id": "u", "at": [30.0, -40.0]}, {"center": [0.0, 0.0]})
	var door := Vector2(sin(float(u["rot"])), cos(float(u["rot"])))
	assert_true(door.dot(Vector2(-30.0, 40.0).normalized()) > 0.999, "Adsız yurdun kapısı ocağa bakar (rot = atan2(−x, −z))")
	assert_eq(str(u["preset"]), "closed", "Adsız yurt kapalı")
	var o := StructureKit.normalize({"kind": "otag", "id": "o", "at": [0, 0], "rot": 0.0})
	assert_eq(str(o["size"]), "l", "Otağ büyük boy")
	assert_eq(str(o["layout"]), "otag", "Otağ Divan Düzeni")
	assert_eq(str(StructureKit.kind_of({"kind": "landmark", "type": "pen", "id": "offering_pen"})), "offering_pen")
	assert_eq(str(StructureKit.kind_of({"kind": "landmark", "type": "gate", "id": "hollow_gate"})), "hollow_gate")
	assert_eq(str(StructureKit.kind_of({"kind": "landmark", "type": "gate", "id": "offering_pen_gate"})), "", "Ağılın kapısı ağılındır")
	assert_eq(str(StructureKit.kind_of({"kind": "shed", "id": "kantu_shed"})), "kantu_shed")
	assert_false(StructureKit.handles({"kind": "watch_fire", "id": "wf1", "at": [0, 0]}), "Nöbet ateşi MapWorld'ündür")
	assert_false(StructureKit.handles({"kind": "yurt", "id": "old", "at": [0, 0], "radius": 3.3, "facing": 180.0}), "Eski Meshy yurdu MapWorld'ündür")
	assert_true(StructureKit.handles({"kind": "yurt", "id": "new", "at": [0, 0], "size": "m"}), "K51 yurdu kitindir")
	assert_false(StructureKit.handles({"kind": "lookout", "id": "lookout_bluff", "at": [8, -92]}), "İşaret yapı değildir")


func test_catalog_kinds_build_within_budget() -> void:
	for kind in ["stable", "tower", "kantu_shed", "felt_yard", "tent_qiang", "great_hearth", "count_stone", "work_board", "kitchen",
			"woodpile", "latrine", "watch_fire", "yurt_pad", "hollow_gate", "offering_pen", "gate", "lantern", "black_cloth"]:
		var mesh := StructureCatalog.mesh(kind)
		var tris := StagedMesh.triangles_of(mesh)
		assert_true(tris > 0 and tris <= 6000, "%s ≤6k üçgen: %d" % [kind, tris])
		assert_true(mesh.get_surface_count() <= 2, "%s ≤2 çizim" % kind)
		var node := StructureKit.build({"kind": kind, "id": kind, "at": [0.0, 0.0], "rot": 0.0})
		assert_not_null(node, "%s kurulur" % kind)
		if node:
			add_child(node)
			await wait_frames(1)
			assert_true(node is StagedStructure, "%s aşamalı yapıdır" % kind)
			node.queue_free()
	assert_eq(StructureCatalog.stages_of("stable"), 4, "Ahır 5 aşama (0–4)")
	assert_eq(StructureCatalog.stages_of("tower"), 3, "Kule 4 aşama (0–3)")
	assert_eq(StructureCatalog.stages_of("tent_qiang"), 2, "Çadır 3 aşama")
	await wait_frames(1)


func test_footprints_are_in_world_space() -> void:
	var y := StructureKit.footprint({"kind": "yurt", "id": "a", "at": [10.0, 20.0], "rot": 1.0, "size": "l"})
	var c: Vector3 = (y["circles"] as Array)[0]
	assert_almost(c.x, 10.0, 1e-6)
	assert_almost(c.y, 20.0, 1e-6)
	assert_almost(c.z, 3.3 * 1.4 + 0.25, 1e-6, "Otağ'ın izi")
	var t := StructureKit.footprint({"kind": "tower", "id": "t", "at": [5.0, 5.0], "rot": PI * 0.5})
	assert_eq((t["circles"] as Array).size(), 4, "Kulenin dört ayağı")
	for v: Vector3 in t["circles"]:
		assert_almost(Vector2(v.x - 5.0, v.y - 5.0).length(), sqrt(2.0) * 1.2, 1e-4, "Ayak dönüşle yerinde")
	var pen := StructureKit.footprint({"kind": "landmark", "type": "pen", "id": "offering_pen", "at": [-80.0, 190.0]})
	var length := 0.0
	for b: Array in pen["boxes"]:
		length += (b[1] as Vector2).y * 2.0
	assert_almost(length, 2.0 * (44.0 + 30.0) - 3.2, 0.01, "Adak Ağılı 44 × 30 m, kapı 3,2 m")


func test_stable_roof_is_cut_for_whoever_is_inside() -> void:
	# K98 diyoraması: ahırın içindeki oyuncu ve bölmelerdeki atlar yukarıdan görünür (StructureRoom; yurdun kesiti gibi): odak içeri girince
	# cut 0,35 sn'de 1, çıkınca 0; kesitliyken kit gölge vermez, ikizi verir. Ahırın malzemesi kesitin ölçüleriyle ayrı anahtardır.
	var holder := Node3D.new()
	add_child(holder)
	var s := StructureKit.build({"kind": "stable", "id": "stable", "at": [-72.0, 34.0], "rot": 1.57}) as StagedStructure
	holder.add_child(s)
	var room := s.get_node_or_null(^"Room") as StructureRoom
	assert_not_null(room, "Ahırın odası")
	assert_eq(s.material_key, "catalog_stable", "Kesitin ölçüleri ahırın malzemesinde")
	assert_true(float(s.material_params["cut_radius"]) > StructureCatalog.STABLE_HALF.length(), "Kesit bütün ahırı kaplar")
	var focus := Node3D.new()
	holder.add_child(focus)
	room.room_focus = focus
	# Bölmenin önü (atın başı): içeride.
	var stall: Dictionary = StructureKit.stable_stalls({"kind": "stable", "id": "stable", "at": [-72.0, 34.0], "rot": 1.57})[2]
	focus.global_position = Vector3((stall["at"] as Vector2).x, 0.0, (stall["at"] as Vector2).y)
	for i in 30:
		room._process(1.0 / 60.0)
	assert_true(room.inside, "Atın başındaki oyuncu odada")
	assert_almost(s.cut, 1.0, 0.001, "Çatı kalktı")
	assert_eq(s.mesh_instance.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Kesitliyken kit gölge vermez")
	focus.global_position = Vector3(-50.0, 0.0, 34.0)
	for i in 30:
		room._process(1.0 / 60.0)
	assert_false(room.inside, "Dışarıda")
	assert_almost(s.cut, 0.0, 0.001, "Çatı geri geldi")
	holder.queue_free()


func test_fence_blocks_except_at_the_gate() -> void:
	# Ağılın çiti (Mene'nin Ağılı 20 × 14 m; Adak Ağılı 44 × 30 m) oyuncunun ve kişilerin engelidir: kesimler yapının izinde kutu, kapının iki
	# direği kapının yerinde (kayıt ortasında değil); kapının aralığı açıktır. Navmesh aynı izi kayıttan okur.
	var holder := Node3D.new()
	add_child(holder)
	var rec := {"kind": "landmark", "id": "menes_fold", "type": "pen", "at": [90.0, -240.0], "size": [20.0, 14.0]}
	var s := StructureKit.build(rec) as StagedStructure
	holder.add_child(s)
	var boxes := s.get_obstacle_boxes()
	assert_eq(boxes.size(), 5, "Çitin beş kesimi (kuzeyde kapının iki yanı)")
	var area := StructureKit.pen_area(rec)
	var gate: Vector2 = area["gate"]
	assert_eq(gate, Vector2(90.0, -247.0), "Kapı kuzey kenarın ortasında")
	var blocked := func(p: Vector2) -> bool:
		for b: ObstacleBox in boxes:
			if b.push_out(p, 0.3) != p:
				return true
		return false
	assert_true(blocked.call(Vector2(84.0, -247.0)), "Kuzey çit kapının yanında engel")
	assert_true(blocked.call(Vector2(100.0, -240.0)), "Doğu çit engel")
	assert_true(blocked.call(Vector2(90.0, -233.0)), "Güney çit engel")
	assert_false(blocked.call(gate), "Kapının aralığı açık")
	assert_false(blocked.call(Vector2(90.0, -240.0)), "Ağılın içi açık")
	for c: Vector3 in s.get_obstacle_circles():
		assert_true(Vector2(c.x, c.y).distance_to(gate) < 2.0, "Kapının direği kapının yerinde (%.1f, %.1f)" % [c.x, c.y])
	var fp := StructureKit.footprint(rec)
	for c: Vector3 in fp["circles"]:
		assert_true(Vector2(c.x, c.y).distance_to(gate) < 2.0, "Navmesh'in izinde de direk kapıda")
	assert_eq((fp["boxes"] as Array).size(), 5, "Navmesh'in izinde çitin kesimleri")
	holder.queue_free()


func test_kislak_records_and_limits() -> void:
	var spec := MapSpec.find(KISLAK)
	if spec == null:
		# A'nın haritası yoksa (geliştirme sırası) sınama atlanır.
		return
	assert_true(spec.structures.size() <= StructureKit.RECORDS_MAX, "Kayıt ≤160: %d" % spec.structures.size())
	var ctx := {"style": "yuezhi", "center": [0.0, 0.0], "painted": true}
	var open := 0
	var yurts := 0
	var handled := 0
	for rec: Dictionary in spec.structures:
		if not StructureKit.handles(rec):
			continue
		handled += 1
		var r := StructureKit.normalize(rec, ctx)
		if StructureKit.is_yurt(str(r["kind"])):
			yurts += 1
			assert_eq(str(r["style"]), "yuezhi", "Kışlak'ın milleti Yüeçi: %s" % r["id"])
			assert_eq(str(r["size"]), "m", "Kışlak'ın yurtları Hane boyu: %s" % r["id"])
			if bool(r["open"]):
				open += 1
			if str(r["id"]).begins_with("yurt_u"):
				var at: Vector2 = r["at"]
				var door := Vector2(sin(float(r["rot"])), cos(float(r["rot"])))
				assert_true(door.dot((-at).normalized()) > 0.99, "%s kapısı Ulu Ocak'a bakar" % r["id"])
				assert_eq(str(r["preset"]), "closed")
	assert_true(open <= StructureKit.OPEN_MAX, "Açık yurt ≤3: %d" % open)
	assert_true(yurts >= 20, "Kışlak'ın yurtları: %d" % yurts)
	assert_true(handled >= 30, "Kitin kurduğu kayıt: %d" % handled)


func test_structure_set_levels_and_live_limit() -> void:
	var spec := MapSpec.find(KISLAK)
	if spec == null:
		return
	var root := Node3D.new()
	add_child(root)
	var set_node := StructureSet.new()
	set_node.snow = 0.85
	root.add_child(set_node)
	var ctx := {"style": "yuezhi", "center": [0.0, 0.0], "painted": true, "set": set_node, "snow": 0.85, "spec": spec}
	var t0 := Time.get_ticks_usec()
	for rec: Dictionary in spec.structures:
		if StructureKit.handles(rec):
			var n := StructureKit.build(rec, ctx)
			if n:
				root.add_child(n)
	var build_ms := (Time.get_ticks_usec() - t0) / 1000.0
	await wait_frames(2)
	set_node.update_levels(Vector3(0.0, 0.0, -30.0))
	await wait_frames(2)
	var near := 0
	for s in set_node.slots:
		if s.is_near():
			near += 1
			assert_true(Vector2(s.global_position.x, s.global_position.z + 30.0).length() <= StructureSet.NEAR_M + StructureSet.HYSTERESIS,
				"Yakın yurt ≤40 m: %s" % s.record["id"])
	assert_true(near >= 1 and near <= StructureSet.NEAR_MAX, "En yakın ≤4 yurt tam: %d" % near)
	assert_eq(set_node.level_of("great_tent"), YurtField.NEAR, "Amaga'nın Yurdu (0, −45) odağa 15 m: tam")
	assert_eq(set_node.level_of("yurt_u13"), YurtField.CLOSED, "Uzaktaki (14, 82) kapalı örnek")
	assert_true(set_node.live_count() <= StructureKit.LIVE_MAX, "Canlı yapı ≤48: %d" % set_node.live_count())
	assert_true(set_node.field.draw_count() <= 4, "YurtField millet başına iki çizim: %d" % set_node.field.draw_count())
	assert_true(set_node.get_obstacle_circles().size() >= 15, "Uzak yurtlar da engeldir")
	print("[structure_kit] Kışlak: %d kayıt, %d yuva, canlı %d, kurulum %.0f ms" % [set_node.records, set_node.slots.size(), set_node.live_count(), build_ms])
	assert_true(build_ms < 1500.0, "Kayıtların düğümü çabuk kurulur (%.0f ms)" % build_ms)
	root.queue_free()
	await wait_frames(1)


func test_site_binds_to_a_yurt() -> void:
	var site := SiteRules.camp3(1171.0 * 1440.0 + 894.0, {"family": false})
	var y := StagedYurt.new()
	y.configure({"size": "m", "style": "hun", "layout": "otaci", "preset": "hero", "open": true})
	add_child(y)
	await wait_frames(1)
	y.bind_site(site)
	await wait_frames(1)
	assert_eq(y.stage, -1, "Başlamadan aşama yok")
	site.advance(1171.0 * 1440.0 + 1240.0)
	await wait_frames(1)
	assert_eq(y.stage, site.stage, "Görünüm şantiyeyi okur")
	assert_almost(y.stage_t, site.stage_t, 1e-6)
	assert_true(y.stage >= 3, "Tündük kalktı (20:36)")
	y.queue_free()
	await wait_frames(1)
