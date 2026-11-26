extends TestCase
## Kışlak (act-1-p2; Yol Haritası terrain-chunks, winter-camp-terrain, navigation, grass-streaming; act1.md §4, §5, §15; godot.md §4.2–§4.7):
## tarif (data/maps/kislak/map.json: sınırlar, iğne, iklim, katmanlar, yerleşim kayıtları K51 şemasıyla, 24 ocak, 9 nöbet ateşi, 3 ped,
## 14 bölge), yükseklik (act1.md §4'ün denetim noktaları pişmiş yüzde), yollar (roads.json: act1.md'nin uzunlukları; en kesitte düz, eğimi
## sınırlı), pişmiş parçalar (imza güncel; 154 GPU parçası, üç düzey, ortak ızgara; 154 navmesh karosu) ve dünyanın kurulumu (hatasız,
## parçalar görünürlük aralığıyla, kar malzemesi, kenar, nöbet ateşleri saatle, Kızıl Kazık hattı, akan çimen, yol bulma ve değen karonun
## eşzamansız yeniden pişmesi). Dünya bir kez kurulur; son test bırakır.

const SCENE := "res://scenes/maps/kislak.tscn"
## act1.md §4'ün yükseklikleri: [ad, x, z, beklenen, pay] (tools/paint_height.gd'nin denetim listesi).
const HEIGHTS := [
	["Ulu Ocak", 0.0, 0.0, 0.0, 0.3], ["Adak Ağılı", -80.0, 190.0, 42.0, 3.0], ["Geyik Taşları", -100.0, 135.0, 34.0, 3.0],
	["Yar kenarı", 8.0, -93.0, -5.0, 1.5], ["Yar dibi", -20.0, -110.0, -14.0, 2.0], ["Buz Kolu", 140.0, -155.0, -18.0, 0.6],
	["Büyük Kurgan", 478.0, -318.0, 6.0, 2.0], ["Yukarı Ağıllar", 440.0, -475.0, 22.0, 2.0], ["Kemik Boğazı", 550.0, -640.0, 48.0, 3.0],
	["Şafak Sırtı", 600.0, -725.0, 60.0, 4.0], ["Çukur", 92.0, 165.0, -6.0, 1.5], ["Demir Diş", -310.0, -100.0, 8.0, 2.0],
	["Demir Diş duvarı", -350.0, -175.0, 40.0, 6.0], ["Ayna Göl", -290.0, -500.0, -8.0, 0.5],
]
## act1.md «Yol ağı»nın uzunlukları (m; ±2).
const ROAD_LENGTHS := {"road_winter": 857.0, "road_east": 619.0, "road_sled": 533.0, "road_west": 376.0, "road_column": 489.0,
	"road_hollow": 103.0, "path_goat": 184.0, "path_lake": 518.0, "path_ledges": 692.0}

var _world: MapWorld
var _build_errors := PackedStringArray()


func test_spec_reads_the_winter_camp() -> void:
	MapSpec.forget_cache()
	var spec := MapSpec.find(MapSpec.KISLAK)
	assert_not_null(spec, "data/maps/kislak/map.json okunur")
	if spec == null:
		return
	assert_eq(spec.kind, MapSpec.KIND_INTERIOR)
	assert_eq(spec.scene, SCENE)
	assert_eq(spec.rect(), Rect2(-450.0, -760.0, 1400.0, 1050.0), "x −450..950, z −760..290")
	assert_eq(spec.pin, Vector2(99.4, 38.9), "Atlas iğnesi Hexi")
	assert_eq(spec.climate, "hexi", "İklim hexi (weather.md §4.2)")
	assert_true(spec.raw.get("layers") is Dictionary, "«layers» sözlüğü (öteki ajanların katmanları)")
	assert_true(spec.raw.has("audio"), "«audio» anahtarı")
	assert_true(spec.structures.size() <= 160, "Yapı kaydı ≤160 (%d)" % spec.structures.size())
	var kinds := {}
	for s in spec.structures:
		kinds[str(s["kind"])] = int(kinds.get(str(s["kind"]), 0)) + 1
		assert_true(spec.rect().has_point(s["at"]), "%s haritanın içinde" % s["id"])
	assert_eq(int(kinds.get("hearth", 0)), 24, "24 ocak (act1.md §4)")
	assert_eq(int(kinds.get("watch_fire", 0)), 9, "9 nöbet ateşi")
	assert_eq(int(kinds.get("yurt_pad", 0)), 3, "Üç Yeni Yurt pedi")
	assert_eq(int(kinds.get("great_hearth", 0)), 1, "Ulu Ocak")
	var named := 0
	for s in spec.structures:
		if str(s["kind"]) == "hearth" and bool(s.get("named", false)):
			named += 1
		if str(s["kind"]) == "yurt":
			for key in ["size", "style", "layout", "rot"]:
				assert_true(s.has(key), "%s K51 kaydı: %s" % [s["id"], key])
	assert_eq(named, 11, "Adlı 11 ocak")
	var wf3 := spec.structure("wf3")
	assert_eq(wf3["at"], Vector2(-12.0, -34.0), "wf3 Amaga'nın yurdunun önü")
	var hostage := spec.structure("hostage_yurt")
	assert_almost(float(hostage["facing"]), 180.0 - rad_to_deg(2.36), 0.01, "Rehine Yurdu'nun kapısı kuzeydoğuya")
	var unnamed := spec.structure("yurt_u01")
	var door := TerrainPaint.compass_dir(float(unnamed["facing"]))
	var to_hearth := (-(unnamed["at"] as Vector2)).normalized()
	assert_true(door.dot(to_hearth) > 0.999, "Adsız yurdun kapısı Ulu Ocak'a bakar")
	assert_eq(spec.spawn("start")["at"], Vector2(-43.0, 53.0), "Başlangıç Rehine Yurdu'nun kapısı")
	assert_eq(spec.regions.size(), 14, "14 bölge (act1.md §4)")
	assert_eq(str(spec.region_at(Vector2(0.0, 0.0)).get("id", "")), "winter_camp")
	assert_eq(str(spec.region_at(Vector2(140.0, -155.0)).get("id", "")), "ice_branch", "Buz Geçidi ırmakta")
	assert_eq(str(spec.region_at(Vector2(-300.0, -170.0)).get("id", "")), "iron_tooth")
	assert_eq(str(spec.region_at(Vector2(600.0, -725.0)).get("id", "")), "bone_throat", "Şafak Sırtı Boğaz'ın bölgesinde")
	assert_eq(int(spec.raw.get("red_stakes", {}).get("rank", -1)), 0, "Kızıl Kazık rütbe 0 alanının çizgisi")
	var light := FileAccess.get_file_as_string(spec.light)
	assert_true(light.contains("\"lat\": 38.9") and light.contains("\"day_n\": 1041"), "Işık Hexi 38,9°K, Gün I")


func test_heights_match_act1() -> void:
	var spec := MapSpec.find(MapSpec.KISLAK)
	var ground := MapBake.fetch(spec.id, "ground", MapBaker.signature(spec))
	assert_not_null(ground, "Pişmiş zemin güncel (tools/paint_height.gd, tools/bake_map.gd --map=kislak)")
	if ground == null:
		return
	var shape := MapBaker.shape_of(ground)
	assert_eq(Vector2i(shape.width, shape.depth), Vector2i(1401, 1051), "1 m, 1.401 × 1.051 örnek")
	for row: Array in HEIGHTS:
		var h := shape.height_at(float(row[1]), float(row[2]))
		assert_true(absf(h - float(row[3])) <= float(row[4]), "%s %.1f m (beklenen %.1f ±%.1f)" % [row[0], h, row[3], row[4]])
	# Yapıların, ocakların ve yolların altı düz.
	for id in ["great_tent", "hostage_yurt", "stores", "yurt_u05"]:
		var at: Vector2 = spec.structure(id)["at"]
		var c := shape.height_at(at.x, at.y)
		for k in 8:
			var a := TAU * float(k) / 8.0
			var q := at + Vector2(cos(a), sin(a)) * 4.0
			assert_almost(shape.height_at(q.x, q.y), c, 0.12, "%s'in altı düz" % id)
	for key in ["mask", "cover", "normal"]:
		assert_not_null(ground.data.get(key), "Zeminin %s görüntüsü" % key)
	var mask: Image = ground.data["mask"]
	assert_eq(Vector2i(mask.get_width(), mask.get_height()), Vector2i(701, 526), "Maske 2 m")
	for path in ["height_file", "mask_file", "cover_file"]:
		assert_true(FileAccess.file_exists(str(spec.ground[path])), "%s yazıldı" % spec.ground[path])


func test_roads_have_act1_lengths_level_sections_and_grades() -> void:
	var spec := MapSpec.find(MapSpec.KISLAK)
	var roads := TerrainPaint.load_roads(spec)
	assert_false(roads.is_empty(), "roads.json")
	var by_id := {}
	for r: Dictionary in roads.get("roads", []):
		by_id[str(r["id"])] = r
	for id: String in ROAD_LENGTHS:
		assert_true(by_id.has(id), "Yol: %s" % id)
		if by_id.has(id):
			assert_almost(float(by_id[id]["length"]), float(ROAD_LENGTHS[id]), 2.0, "%s uzunluğu" % id)
	assert_eq((roads.get("edges", []) as Array).size(), 23, "travel.md §4.1'in 23 kenarı")
	for id in ["n_hearth", "n_ramp", "n_ford", "n_throat", "n_pier"]:
		assert_true((roads["nodes"] as Dictionary).has(id), "Düğüm %s" % id)
	assert_false(bool(by_id["path_goat"]["cart"]), "Keçi Yolu arabaya kapalı")
	var ground := MapBake.fetch(spec.id, "ground", MapBaker.signature(spec))
	if ground == null:
		return
	var shape := MapBaker.shape_of(ground)
	var winter: Dictionary = by_id["road_winter"]
	var pts := PackedVector2Array()
	for p: Variant in winter["points"]:
		pts.append(MapSpec.vec2(p))
	var line := TerrainPaint.resample(pts, 2.0)
	var steepest := 0.0
	var tilted := 0
	# Uçlardaki 4 m (yolun ağzı araziye karışır) sayılmaz.
	for i in range(3, line.size() - 2):
		var a := line[i - 1]
		var b := line[i]
		var dh := absf(shape.height_at(b.x, b.y) - shape.height_at(a.x, a.y))
		steepest = maxf(steepest, rad_to_deg(atan(dh / a.distance_to(b))))
		var dir := (b - a).normalized()
		var side := Vector2(-dir.y, dir.x) * 1.4
		if absf(shape.height_at(b.x + side.x, b.y + side.y) - shape.height_at(b.x - side.x, b.y - side.y)) > 0.25:
			tilted += 1
	assert_true(steepest <= 10.5, "Kış Yolu en dik %.1f° (sınır 8° ve yumuşatma payı)" % steepest)
	assert_true(tilted <= line.size() / 20, "Kış Yolu en kesitte düz (%d / %d örnek yatık)" % [tilted, line.size()])
	var ramp_top := shape.height_at(40.0, -92.0)
	var ramp_bottom := shape.height_at(96.0, -128.0)
	assert_true(ramp_top > -6.5 and ramp_bottom < -12.0, "Yar Rampası iner (%.1f → %.1f)" % [ramp_top, ramp_bottom])


func test_bakes_are_fresh_and_chunks_share_grids() -> void:
	var spec := MapSpec.find(MapSpec.KISLAK)
	var sig := MapBaker.signature(spec)
	for kind in MapBaker.kinds_of(spec):
		assert_not_null(MapBake.fetch(spec.id, kind, sig), "Pişmiş %s güncel (tools/bake_map.gd --map=kislak)" % kind)
	var chunks := MapBake.fetch(spec.id, "chunks", sig)
	if chunks == null:
		return
	assert_true(bool(chunks.data.get("gpu", false)), "Parçalar GPU'da yükselir")
	var list: Array = chunks.data["chunks"]
	assert_eq(list.size(), 154, "14 × 11 parça (100 m)")
	var grids := {}
	for c: Dictionary in list:
		assert_eq((c["lods"] as Array).size(), 3, "Üç düzey")
		for id: int in c["lods"]:
			grids[id] = true
	assert_true(grids.size() <= 6, "Ortak ızgara: tam ve kenar parça × üç düzey (%d ağ)" % grids.size())
	var first: Dictionary = list[0]
	var mesh: ArrayMesh = chunks.meshes[int((first["lods"] as Array)[0])]
	var arrays := mesh.surface_get_arrays(0)
	assert_eq((arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3 >= 100 * 100 * 2, true, "1 m'lik düzey 20 bin üçgen")
	var skirt := 0
	for uv: Vector2 in arrays[Mesh.ARRAY_TEX_UV2]:
		if uv.y > 0.0:
			skirt += 1
	assert_true(skirt >= 400, "Dikişte etek (UV2.y derinlik): %d köşe" % skirt)
	var ground := MapBake.fetch(spec.id, "ground", sig)
	var shape := MapBaker.shape_of(ground)
	var r: Rect2 = first["rect"]
	var aabb: AABB = first["aabb"]
	var span := MapBaker.height_span(shape, r)
	assert_true(aabb.position.y <= span.x and aabb.end.y >= span.y, "Kırpma kutusu parçanın yüksekliklerini kapsar")
	assert_eq(chunks.data["lod_ranges"], [150.0, 520.0], "Görünürlük aralığı 150 ve 520 m")
	var nav := MapBake.fetch(spec.id, "nav", sig)
	assert_eq((nav.data["tiles"] as Array).size(), 154, "Her parçaya bir navmesh karosu")


func test_world_builds_without_errors() -> void:
	var world := await _get_world()
	if world == null:
		return
	assert_true(_build_errors.is_empty(), "Kurulurken hata yazılmadı: %s" % [_build_errors])
	assert_true(world.used_bake, "Pişmiş parçalarla kuruldu")
	var counts := world.part_counts()
	assert_eq(int(counts["chunks"]), 154)
	assert_eq(int(counts["nav_tiles"]), 154)
	# Kurulumun en uzun karesi (yapı kitinin ve katmanların ilk kurulumu dahil); asıl ölçüt WorldHost'un ≤6 sn'sidir (test_kislak_swap.gd).
	assert_true(float(world.build_stats["max_frame_ms"]) < 3000.0, "Kurulumun en uzun karesi (%.0f ms)" % float(world.build_stats["max_frame_ms"]))
	var lod0 := world.get_node(^"Terrain/Chunk_4_7/Lod0") as MeshInstance3D
	var lod2 := world.get_node(^"Terrain/Chunk_4_7/Lod2") as MeshInstance3D
	assert_true(lod0.custom_aabb.size.y > 0.0, "GPU parçasının kırpma kutusu")
	assert_almost(lod0.visibility_range_end, 150.0, 0.001)
	assert_almost(lod2.visibility_range_begin, 520.0, 0.001)
	assert_eq(lod0.visibility_range_fade_mode, GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED)
	var mat := lod0.material_override as ShaderMaterial
	assert_true(mat != null and mat.shader == MapWorld.SNOW_SHADER and mat.get_shader_parameter(&"displace") != false, "Kar malzemesi, GPU yüksekliği")
	assert_not_null(mat.get_shader_parameter(&"height_tex"), "Yükseklik dokusu")
	var ring := world.get_node(^"Terrain/Ring/Ring0") as MeshInstance3D
	assert_false(bool((ring.material_override as ShaderMaterial).get_shader_parameter(&"displace")), "Dış halka kendi köşesini taşır")
	assert_eq(lod0.get_meta(&"free_asset"), MapWorld.FREE_SNOW, "Ücretsiz dokuların işareti (K89)")
	var edge := world.get_node_or_null(^"Edge") as MapEdge
	assert_true(edge != null and edge.get_obstacle_boxes().size() == 4, "Haritanın kenarı dört kutu (MapEdge)")
	assert_true(world.collect_boxes().size() >= 4, "Kenarın kutuları engel toplamasında")
	# Yurdu MapWorld ya da yapı kiti (StructureKit, B) kurar: düğüm kaydın yerinde ve zeminde.
	var yurt := world.places.get("great_tent") as Node3D
	assert_not_null(yurt, "Amaga'nın Yurdu kuruldu")
	if yurt:
		assert_almost(yurt.global_position.y, world.ground.height_at(0.0, -45.0), 0.05, "Yurt zeminde")
		if yurt is Yurt:
			assert_almost((yurt as Yurt).radius, 3.4, 0.001, "Hane boyu")
	var lights := 0
	for l in world.find_children("*", "Light3D", true, false):
		if not (l is DirectionalLight3D):
			lights += 1
	assert_true(lights <= 32, "Gölgesiz ışık ≤32 (%d; yalnız açık yurtlar ve ocaklar)" % lights)
	assert_eq(world.watch_fires.points.size(), 9, "Dokuz nöbet ateşi")
	assert_true(world.red_stakes.points.size() > 150, "Kızıl Kazık hattı (%d kazık)" % world.red_stakes.points.size())
	assert_true(world.red_stakes.inside(Vector2(0.0, 0.0)) and not world.red_stakes.inside(Vector2(140.0, -155.0)), "Rütbe 0 alanı: Ulu Ocak içeride, Geçit dışarıda")
	assert_true(world.red_stakes.inside(Vector2(92.0, 165.0)), "Esir Çukuru rütbe 0")
	for wf in world.watch_fires.points:
		assert_true(world.red_stakes.inside(Vector2(wf.x, wf.z)), "Nöbet ateşi rütbe 0 alanında")
	var hud := world.hud_map_spec()
	assert_true((hud.get("box", Rect2()) as Rect2).has_area(), "HUD haritasının yürünür dikdörtgeni")


func test_fires_and_light_follow_the_clock() -> void:
	var world := await _get_world()
	if world == null:
		return
	var clock := GameClock.new(1041, 12.0 * 60.0)
	clock.set_place(38.9)
	assert_true(world.bind_clock(clock), "Işık saate bağlandı (MapSky)")
	var sky := world.get_node(^"MapSky") as MapSky
	assert_eq(sky.last_fed, Vector2(1041.0, 720.0), "İlk örnek yazıldı")
	var noon := world.get_sky_rig().clock_sample()
	assert_true(float(noon.get("light_k", 0.0)) > 0.9, "Öğlede güneş")
	world.watch_fires.refresh()
	assert_almost(world.watch_fires.lit, 0.0, 1e-6, "Öğlede ateşler sönük")
	clock.minute = 17.0 * 60.0
	world.watch_fires.refresh()
	assert_almost(world.watch_fires.lit, 1.0, 1e-6, "17:00'de yanık")
	var mat := world.get_node(^"Terrain/Chunk_4_7/Lod0").material_override as ShaderMaterial
	assert_eq(int(mat.get_shader_parameter(&"fire_count")), 9, "Zemin parıltısı dokuz ateşte")
	world.watch_fires.set_fuel(1.0)
	var fires: PackedVector4Array = mat.get_shader_parameter(&"fires")
	assert_almost(fires[0].z, 12.0, 1e-4, "≥%100 Yakacak 12 m")
	world.watch_fires.set_fuel(0.6)
	sky.feed()
	var dusk := world.get_sky_rig().clock_sample()
	assert_true(float(dusk.get("s", 0.0)) > 4.5, "17:00 akşam durağına yakın (s %.2f)" % float(dusk.get("s", 0.0)))


func test_grass_streams_around_the_focus() -> void:
	var world := await _get_world()
	if world == null:
		return
	var grass := world.grass_field
	assert_not_null(grass, "Akan çimen (grass.stream)")
	if grass == null:
		return
	grass.follow = Callable()
	grass.focus = Vector3(-40.0, 0.0, 40.0)
	grass.update()
	grass.flush()
	for i in 4:
		grass.update()
		grass.flush()
	var near := grass.live.size()
	assert_true(near >= 12, "Odağın çevresinde parçalar (%d)" % near)
	assert_true(grass.instance_count() > 0, "Kuru tutam var (ezik yerin ve yolun kıyısında)")
	assert_true(int(grass.stats["writes"]) > 0, "MultiMesh.buffer tek atamayla yazıldı")
	var keys_before: Array = grass.live.keys()
	grass.focus = Vector3(400.0, 0.0, -300.0)
	for i in 6:
		grass.update()
		grass.flush()
	for k: Vector2i in keys_before:
		assert_false(grass.live.has(k), "Uzaklaşan parça bırakıldı")
	assert_true(int(grass.stats["released"]) >= keys_before.size(), "Parçalar havuza döndü")
	assert_true(int(grass.stats["reused"]) > 0, "Havuzdan yeniden kullanıldı")
	# Aynı tohum aynı parça.
	var a := grass.build_chunk(Vector2i(2, 2))
	var b := grass.build_chunk(Vector2i(2, 2))
	assert_eq(a, b, "Parça tohumdan: aynı anahtar aynı örnekler")


func test_navmesh_paths_and_async_rebake() -> void:
	var world := await _get_world()
	if world == null:
		return
	var nav := MapNav.of(world)
	assert_not_null(nav, "MapNav")
	if nav == null:
		return
	var ready_by := Time.get_ticks_msec() + 15000
	while not nav.is_ready() and Time.get_ticks_msec() < ready_by:
		await get_tree().physics_frame
	assert_true(nav.is_ready(), "Harita eşlendi")
	var from := world.marker("start")
	var to := world.on_ground(Vector2(0.0, -37.0))
	var path := nav.path(from, to)
	# Bölgelerin eşlemesi eşzamansızdır: yol gelene dek (en çok 10 sn) beklenir.
	while path.size() < 2 and Time.get_ticks_msec() < ready_by:
		await get_tree().physics_frame
		path = nav.path(from, to)
	assert_true(path.size() >= 2, "Rehine Yurdu'ndan Amaga'nın kapısına yol")
	if path.size() >= 2:
		assert_true(Vector2(path[path.size() - 1].x - to.x, path[path.size() - 1].z - to.z).length() < 1.5, "Yol kapıya varır")
	var ford := world.on_ground(Vector2(140.0, -150.0))
	assert_true(nav.reachable(world.on_ground(Vector2(40.0, -85.0)), ford, 3.0), "Yar Rampası'ndan Buz Geçidi'ne inilir")
	var walk := nav.walk_path(from, Vector3(5000.0, 0.0, 5000.0))
	assert_true(walk.size() >= 2, "Oyuncunun yolu hep var (düz çizgi yedeği)")
	var inside := world.on_ground(Vector2(0.0, -45.0))
	var around := nav.closest(inside)
	assert_true(Vector2(around.x - inside.x, around.z - inside.z).length() > 2.5, "Yurdun içi yürünmez")
	var tiles := nav.tiles_touching(Rect2(-5.0, 15.0, 10.0, 10.0))
	assert_true(tiles.size() >= 1, "Değen karo")
	var watched := watch_signal(nav.tile_rebaked)
	var before := (nav.regions[tiles[0]] as NavigationRegion3D).navigation_mesh
	nav.add_obstacle("test_post", Vector3(0.0, 20.0, 3.0))
	var deadline := Time.get_ticks_msec() + 20000
	while nav.is_busy() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	assert_false(nav.is_busy(), "Yeniden pişirme bitti")
	assert_true(watched.count >= tiles.size(), "Değen karolar eşzamansız yeniden pişti (%d)" % watched.count)
	assert_ne((nav.regions[tiles[0]] as NavigationRegion3D).navigation_mesh, before, "Karo yeni ağla")
	var post := world.on_ground(Vector2(0.0, 20.0))
	var near := nav.closest(post)
	var sync_by := Time.get_ticks_msec() + 5000
	while Vector2(near.x - post.x, near.z - post.z).length() <= 2.5 and Time.get_ticks_msec() < sync_by:
		await get_tree().physics_frame
		near = nav.closest(post)
	assert_true(Vector2(near.x - post.x, near.z - post.z).length() > 2.5, "Eklenen engelin içi yürünmez")
	nav.remove_obstacle("test_post")
	deadline = Time.get_ticks_msec() + 20000
	while nav.is_busy() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame


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
	# Haritanın kendi parçaları sınanır: öteki ajanların katmanları (map.json «layers»; kendi sınamaları var) bu kopyada kurulmaz.
	var spec := MapSpec.from_dict(MapSpec.find(MapSpec.KISLAK).raw.duplicate(true))
	spec.layers = {}
	_world.spec = spec
	add_child(_world)
	var deadline := Time.get_ticks_msec() + 30000
	while not _world.is_ready() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	OS.remove_logger(log)
	_build_errors.append_array(log.take())
	if not _world.is_ready():
		fail("Kışlak 30 sn'de kurulmadı")
		return null
	return _world
