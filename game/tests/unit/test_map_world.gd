extends TestCase
## Deneme iç haritası (Yol Haritası world-swap; godot.md §4.2–§4.7, §8.4 «test_map_world.gd: arazi, kapılar, navmesh karoları»):
## tarif (MapSpec, data/maps/testmap/map.json), yükseklik yüzü (HeightmapShape: çift doğrusal), pişmiş parçaların güncelliği (imza; taze
## üretimle aynı), dünyanın kurulumu (MapWorld): 100 m'lik parçalar üç düzeyle ve görünürlük aralığıyla, dikiş, dış halka, ot, navmesh
## karoları ve aralarından geçen yol, kapılar, yapılar zeminde, atlar binilir, engeller yalnız bu dünyanın; bırakınca bir şey kalmaz.
## Dünya bir kez kurulur, dosyadaki sahne testleri paylaşır; son test (test_world_frees_cleanly) bırakır.

const SCENE := "res://scenes/maps/testmap.tscn"

var _world: MapWorld
var _build_errors := PackedStringArray()


# --- Tarif ve yüz (saf) ----------------------------------------------------------------------------

func test_spec_reads_the_map() -> void:
	MapSpec.forget_cache()
	var spec := MapSpec.find(MapSpec.TESTMAP)
	assert_not_null(spec, "data/maps/testmap/map.json okunur")
	if spec == null:
		return
	assert_eq(spec.id, "testmap")
	assert_eq(spec.kind, MapSpec.KIND_INTERIOR)
	assert_false(spec.is_camp())
	assert_eq(spec.scene, SCENE)
	assert_eq(spec.size, Vector2(400.0, 300.0))
	assert_eq(spec.rect(), Rect2(-200.0, -150.0, 400.0, 300.0), "(0, 0) ortada")
	assert_eq(spec.title_text("tr"), "Deneme Ovası")
	assert_eq(PackedStringArray(spec.bakes), PackedStringArray(["ground", "chunks", "grass", "nav"]))
	for id in ["start", "east_gate", "west_gate"]:
		assert_false(spec.spawn(id).is_empty(), "Belirme noktası: %s" % id)
	assert_eq(spec.gates.size(), 2, "İki kapı")
	for g in spec.gates:
		assert_eq(str(g["to"]), MapSpec.CAMP, "Kapı kampa açılır")
		assert_true(spec.rect().has_point(g["at"]), "Kapı haritanın içinde")
		assert_true((g["at"] as Vector2).distance_to(spec.play_center) < spec.play_radius, "Kapı yürünür alanda")
		assert_eq(spec.gate_at(g["at"]), g, "gate_at kapıyı bulur")
		assert_false(spec.spawn(str(g["arrive"])).is_empty(), "Kapının varış noktası var")
		assert_true(spec.gate_at(spec.spawn(str(g["arrive"]))["at"]).is_empty(), "Varış noktası kapının alanının dışında")
	assert_true(spec.gate_at(Vector2.ZERO).is_empty())
	assert_true(spec.camera_bounds.encloses(Rect2(spec.play_center - Vector2.ONE * spec.play_radius, Vector2.ONE * spec.play_radius * 2.0)),
		"Kamera kutusu yürünür alanı kapsar")
	assert_eq(str(spec.region_at(Vector2(0.0, -10.0)).get("id", "")), "konak", "Bölge")
	var kinds := {}
	for s in spec.structures:
		kinds[str(s["kind"])] = int(kinds.get(str(s["kind"]), 0)) + 1
	assert_eq(int(kinds.get("yurt", 0)), 3, "Üç yurt")
	assert_eq(int(kinds.get("horse", 0)), 2, "İki at")
	var paths := spec.load_paths()
	assert_true(paths.has(SCENE) and paths.has(MapBake.path_for("testmap", "chunks")), "Yüklenecekler: sahne ve pişmiş parçalar")
	for p in paths:
		assert_true(ResourceLoader.exists(p), "Var: %s" % p)
	var camp := MapSpec.find(MapSpec.CAMP)
	assert_true(camp != null and camp.is_camp() and camp.scene == "res://scenes/world/world.tscn", "Kampın tarifi")
	assert_true(camp.load_paths().size() > 30, "Kampın önyükleme listesi (tools/bake_map.gd)")


func test_heightmap_shape_reads_bilinear() -> void:
	# 3 × 2 örnek, 2 m aralık, ilk örnek (10, 20)'de.
	var shape := HeightmapShape.new(PackedFloat32Array([0.0, 1.0, 2.0, 4.0, 5.0, 6.0]), 3, 2, Vector2(10.0, 20.0), 2.0)
	assert_almost(shape.height_at(10.0, 20.0), 0.0, 1e-6, "Köşe örneği")
	assert_almost(shape.height_at(14.0, 22.0), 6.0, 1e-6, "Son örnek")
	assert_almost(shape.height_at(11.0, 20.0), 0.5, 1e-6, "x boyunca doğrusal")
	assert_almost(shape.height_at(10.0, 21.0), 2.0, 1e-6, "z boyunca doğrusal")
	assert_almost(shape.height_at(13.0, 21.0), 3.5, 1e-6, "Çift doğrusal")
	assert_almost(shape.height_at(-50.0, -50.0), 0.0, 1e-6, "Dışarısı en yakın kenar örneği")
	assert_almost(shape.height_at(99.0, 99.0), 6.0, 1e-6)
	assert_true(shape.normal_at(12.0, 21.0, 1.0).dot(Vector3.UP) > 0.0, "Normal yukarı bakar")
	assert_true(shape.normal_at(12.0, 21.0, 1.0).x < 0.0, "Yüz +x'e yükselir: normal -x'e yatar")
	assert_eq(shape.rect(), Rect2(10.0, 20.0, 4.0, 2.0))
	var img := HeightmapShape.to_image(shape.data, 3, 2)
	var back := HeightmapShape.from_image(img, Vector2(10.0, 20.0), 2.0)
	assert_almost(back.height_at(13.0, 21.0), 3.5, 1e-6, "Görüntüden aynı yüz")
	assert_false(shape.is_underwater(12.0, 21.0))


func test_grid_lines_cover_both_ends() -> void:
	assert_eq(MapBaker.grid_lines(0.0, 100.0, 16.0), PackedFloat32Array([0.0, 16.0, 32.0, 48.0, 64.0, 80.0, 96.0, 100.0]), "16 m: son aralık kısa")
	assert_eq(MapBaker.grid_lines(-200.0, -100.0, 4.0).size(), 26)
	assert_eq(MapBaker.grid_lines(0.0, 100.0, 1.0).size(), 101)


func test_bakes_are_fresh_and_equal_a_fresh_bake() -> void:
	var spec := MapSpec.find(MapSpec.TESTMAP)
	var sig := MapBaker.signature(spec)
	var stored := {}
	for kind in MapWorld.BAKE_KINDS:
		var bake := MapBake.fetch(spec.id, kind, sig)
		assert_not_null(bake, "Pişmiş %s güncel (imza tutar; tutmazsa tools/bake_map.gd --map=testmap)" % kind)
		if bake:
			stored[kind] = bake
	if stored.size() != MapWorld.BAKE_KINDS.size():
		return
	# Üretim kodu değişip araç koşulmadıysa düşer: taze üretim pişmişle aynı olmalı.
	var fresh := {}
	for bake in MapBaker.bake(spec):
		fresh[bake.kind] = bake
	var g0: MapBake = stored["ground"]
	var g1: MapBake = fresh["ground"]
	assert_eq((g0.data["height"] as Image).get_data(), (g1.data["height"] as Image).get_data(), "Yükseklik aynı")
	assert_eq((g0.data["mask"] as Image).get_data(), (g1.data["mask"] as Image).get_data(), "Maske aynı")
	var c0: MapBake = stored["chunks"]
	var c1: MapBake = fresh["chunks"]
	assert_eq(c0.meshes.size(), c1.meshes.size(), "Parça ağı sayısı aynı")
	var same := true
	for i in mini(c0.meshes.size(), c1.meshes.size()):
		if c0.meshes[i].surface_get_arrays(0)[Mesh.ARRAY_VERTEX] != c1.meshes[i].surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			same = false
	assert_true(same, "Parça ağlarının köşeleri aynı")
	var e0: Array = (stored["grass"] as MapBake).data["entries"]
	var e1: Array = (fresh["grass"] as MapBake).data["entries"]
	assert_eq(e0.size(), e1.size(), "Otun parça sayısı aynı")
	var grass_same := e0.size() == e1.size()
	for i in mini(e0.size(), e1.size()):
		if e0[i][0] != e1[i][0] or e0[i][1] != e1[i][1]:
			grass_same = false
	assert_true(grass_same, "Otun örnekleri aynı")
	var t0: Array = (stored["nav"] as MapBake).data["tiles"]
	var t1: Array = (fresh["nav"] as MapBake).data["tiles"]
	assert_eq(t0.size(), t1.size())
	for i in mini(t0.size(), t1.size()):
		assert_eq((t0[i]["mesh"] as NavigationMesh).get_polygon_count(), (t1[i]["mesh"] as NavigationMesh).get_polygon_count(), "Karo %d aynı" % i)


# --- Dünya ------------------------------------------------------------------------------------------

func test_world_builds_from_bakes_without_errors() -> void:
	var world := await _get_world()
	if world == null:
		return
	assert_true(_build_errors.is_empty(), "Kurulurken hata yazılmadı: %s" % [_build_errors])
	assert_true(world.is_ready(), "Hazır")
	assert_true(world.used_bake, "Pişmiş parçalarla kuruldu")
	assert_true(world.get_terrain_shape() is HeightmapShape, "Yüz HeightmapShape")
	var counts := world.part_counts()
	assert_eq(int(counts["chunks"]), 12, "4 × 3 arazi parçası (100 m)")
	assert_eq(int(counts["nav_tiles"]), 12, "Her parçaya bir navmesh karosu")
	assert_true(int(counts["grass"]) > 20, "Ot parçaları")
	assert_eq(int(counts["places"]), world.spec.structures.size(), "Her yapı kaydı kuruldu")
	assert_eq(int(counts["gates"]), 2, "İki kapı")
	assert_true(float(world.build_stats["ready_ms"]) < 3000.0, "Kurulum çabuk (%.0f ms)" % float(world.build_stats["ready_ms"]))
	assert_not_null(world.get_sky_rig(), "SkyRig")
	assert_true(world.get_sky_rig().current_sample().has("light_energy"), "Açılış ışığı yazıldı")


func test_terrain_chunks_have_three_lods_and_seams() -> void:
	var world := await _get_world()
	if world == null:
		return
	var chunk := world.get_node_or_null(^"Terrain/Chunk_1_1") as Node3D
	assert_not_null(chunk, "Parça")
	if chunk == null:
		return
	var lods: Array[MeshInstance3D] = []
	for i in 3:
		lods.append(chunk.get_node(NodePath("Lod%d" % i)) as MeshInstance3D)
	assert_almost(lods[0].visibility_range_begin, 0.0, 0.001)
	assert_almost(lods[0].visibility_range_end, 150.0, 0.001, "1 m'lik düzey 150 m'ye dek")
	assert_almost(lods[1].visibility_range_begin, 150.0, 0.001)
	assert_almost(lods[1].visibility_range_end, 520.0, 0.001, "4 m'lik düzey 520 m'ye dek")
	assert_almost(lods[2].visibility_range_begin, 520.0, 0.001)
	assert_almost(lods[2].visibility_range_end, 0.0, 0.001, "16 m'lik düzey ötesi")
	for mi in lods:
		assert_eq(mi.visibility_range_fade_mode, GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED, "Geçiş kipi kapalı (godot.md §4.6)")
		assert_eq(mi.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Arazi gölge düşürmez")
	var tris: Array[int] = []
	for mi in lods:
		tris.append(mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size() / 3)
	assert_true(tris[0] > tris[1] and tris[1] > tris[2], "Düzeyler seyrekleşir: %s" % [tris])
	# Köşeler yüzün üstünde; komşu parçanın kenarı aynı yükseklikte (dikiş yok).
	var verts: PackedVector3Array = lods[0].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var off := 0
	for k in range(0, 101 * 101, 997):
		var v := verts[k]
		if absf(v.y - world.ground.height_at(v.x, v.z)) > 0.001:
			off += 1
	assert_eq(off, 0, "1 m'lik düzeyin köşeleri yükseklikte")
	var right := world.get_node_or_null(^"Terrain/Chunk_2_1/Lod2") as MeshInstance3D
	var mine: PackedVector3Array = lods[2].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var theirs: PackedVector3Array = right.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] if right else PackedVector3Array()
	var edge_x := 0.0
	var matched := 0
	for v in mine:
		if absf(v.x - edge_x) < 0.001:
			for w in theirs:
				if absf(w.x - edge_x) < 0.001 and absf(w.z - v.z) < 0.001 and absf(w.y - v.y) < 0.0001:
					matched += 1
					break
	assert_true(matched >= 7, "Komşu parçaların kenarı aynı köşelerde (%d)" % matched)
	var ring := world.get_node_or_null(^"Terrain/Ring") as Node3D
	assert_true(ring != null and ring.get_child_count() == 12, "Dış halka: üç düzey × dört şerit")
	var far := 0.0
	for mi: MeshInstance3D in ring.get_children():
		far = maxf(far, mi.get_aabb().end.x)
	assert_true(far > 3000.0, "Dış halka 3 km'nin ötesine uzanır (K27)")


func test_navmesh_tiles_connect_gate_to_gate() -> void:
	var world := await _get_world()
	if world == null:
		return
	for tile: NavigationRegion3D in world.get_node(^"Navigation").get_children():
		assert_true(tile.navigation_mesh != null and tile.navigation_mesh.get_polygon_count() > 50, "%s yürünür" % tile.name)
	for i in 4:
		await get_tree().physics_frame
	var map := world.get_world_3d().navigation_map
	var from := world.marker("west_gate")
	var to := world.marker("east_gate")
	var path := NavigationServer3D.map_get_path(map, from, to, true)
	assert_true(path.size() > 2, "Batı Kapısı'ndan Doğu Kapısı'na yol var")
	if path.size() > 0:
		assert_true(Vector2(path[path.size() - 1].x - to.x, path[path.size() - 1].z - to.z).length() < 1.0, "Yol kapıya varır (karolar birbirine bağlı)")
	var yurt := world.marker("yurt_north")
	var around := NavigationServer3D.map_get_closest_point(map, yurt)
	assert_true(Vector2(around.x - yurt.x, around.z - yurt.z).length() > 3.0, "Yurdun içi yürünmez (engel)")


func test_structures_sit_on_the_ground_and_horses_are_mountable() -> void:
	var world := await _get_world()
	if world == null:
		return
	for rec: Dictionary in world.spec.structures:
		var node := world.places.get(str(rec["id"])) as Node3D
		assert_not_null(node, "Kuruldu: %s" % rec["id"])
		if node:
			var p := node.global_position
			assert_almost(p.y, world.ground.height_at(p.x, p.z), 0.05, "%s zeminde" % rec["id"])
	assert_eq(world.horses.size(), 2, "İki at")
	for h in world.horses:
		assert_true(h.is_in_group(Rideable.GROUP), "%s binilir" % h.name)
		assert_eq(h.mount_kind(), "horse")
		assert_true(h.uses_model(), "%s modeliyle" % h.name)
	var obstacles := world.collect_obstacles()
	assert_true(obstacles.size() >= 10, "Yurt, ocak, eşya, kaya ve çam engeldir")
	var yurt := world.places["yurt_north"] as Yurt
	assert_true(obstacles.any(func(c: Vector3) -> bool: return Vector2(c.x - yurt.global_position.x, c.y - yurt.global_position.z).length() < 0.5),
		"Yurdun dairesi")
	# Engeller yalnız bu dünyanın: ağaçta başka bir dünyanın engeli olsa da toplanmaz.
	var stranger := CampProp.new()
	stranger.position = Vector3(5000.0, 0.0, 5000.0)
	add_child(stranger)
	await wait_frames(1)
	assert_false(world.collect_obstacles().any(func(c: Vector3) -> bool: return c.x > 4000.0), "Başka dünyanın engeli sayılmaz")
	stranger.free()
	var area := world.play_area()
	assert_eq(area["center"], world.spec.play_center)
	assert_almost(float(area["radius"]), world.spec.play_radius, 0.001)
	var spawn := world.spawn("start")
	var start_at: Vector2 = world.spec.spawn("start")["at"]
	assert_almost((spawn["at"] as Vector3).y, world.ground.height_at(start_at.x, start_at.y), 0.001, "Belirme zeminde")
	assert_almost(float(spawn["yaw"]), PI, 0.001, "Kuzeye bakar (pusula 0)")
	assert_eq(world.marker("nope"), Vector3.INF)
	var cam := world.clamp_camera_transform(Transform3D(Basis.IDENTITY, Vector3(900.0, 30.0, 0.0)), Vector3(180.0, 1.0, 4.0))
	assert_true(world.camera_bounds().grow(0.01).has_point(Vector2(cam.origin.x, cam.origin.z)), "Kamera kutuda")
	var gate := world.gate_at(world.marker("east_gate") + Vector3(12.0, 0.0, 0.0))
	assert_eq(str(gate.get("id", "")), "east_gate", "Doğu Kapısı'nın alanı")
	var gate_node := world.get_node_or_null(^"Gates/EastGate") as Marker3D
	assert_true(gate_node != null and str(gate_node.get_meta(&"to")) == MapSpec.CAMP, "Kapının düğümü")
	var hud := world.hud_map_spec()
	assert_eq(str(hud["key"]), "testmap")
	assert_eq((hud["places"] as Array).size(), world.spec.regions.size(), "HUD haritasında bölgeler")


func test_world_frees_cleanly() -> void:
	var world := await _get_world()
	if world == null:
		return
	var log := TestErrorLog.new()
	OS.add_logger(log)
	world.get_parent().remove_child(world)
	world.free()
	_world = null
	WorldHost.clear_static_caches()
	# Ocağın ses oynatıcısını ses sunucusu kendi iş parçacığında bırakır (testler.md «Ses çalan düğümler»): çıkışta sızıntı yazılmasın.
	await get_tree().create_timer(0.3).timeout
	OS.remove_logger(log)
	assert_eq(log.take().size(), 0, "Bırakırken hata yazılmadı")
	assert_eq(WorldHost.static_cache_size(), 0, "Statik önbellekler boş")
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)), 0, "Öksüz düğüm yok")


# --- Yardımcılar -------------------------------------------------------------------------------------

func _get_world() -> MapWorld:
	if is_instance_valid(_world):
		return _world
	var log := TestErrorLog.new()
	OS.add_logger(log)
	var scene := load(SCENE) as PackedScene
	_world = scene.instantiate() as MapWorld
	add_child(_world)
	var deadline := Time.get_ticks_msec() + 20000
	while not _world.is_ready() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	OS.remove_logger(log)
	_build_errors.append_array(log.take())
	if not _world.is_ready():
		fail("Deneme haritası 20 sn'de kurulmadı")
		return null
	return _world
