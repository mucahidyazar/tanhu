extends TestCase
## Kampın bütçe kesintileri (godot.md §7.5, K3; Yol Haritası budget-probe, foundation-p3): menü kadrajında
## görünmeyen kesintilerin kuralları.
##
## Saf kurallar: arazi parçaları ızgaranın her dörtgenini bir kez kapsar ve aynı köşeleri kullanır; seyrek merkez
## diski dikişsizdir; dağ halkasının dilimleri halkanın tamamıdır; uzak vadi ladininde gövde yoktur; kaya
## kümelerinin taşlarında LOD zinciri vardır.
## Dünya kuralları (world.tscn): arazi, dağlar, çimen ve küçük kayalar gölge düşürmez; kahraman kayaların ve
## kampa yakın çamların gölgesini sadeleştirilmiş kopya düşürür, kahraman kayaların dokulu ağında LOD zinciri
## vardır; uzak çam orta düzeye geçer ama menü gözünden bütün çamlar tam düzeydedir (menü karesi değişmez); vadi
## kayaları karelere bölünür, uzaktakiler seyrek ağlıdır.

const WORLD_SCENE := "res://scenes/world/world.tscn"
## Sınama ızgarası: küçük ama merkez diski ve iki bant çıkacak kadar halkalı.
const GRID_SEGMENTS := 48
const GRID_RINGS := 100
const GRID_CENTER := 60

var _world: World


# --- Arazi (saf) ----------------------------------------------------------------------------------

func test_terrain_chunk_plan_covers_every_quad_once() -> void:
	var plan := Terrain.chunk_plan(GRID_SEGMENTS, GRID_RINGS, GRID_CENTER, Terrain.BAND_RINGS, 5)
	var seen := {}
	var overlaps := 0
	for part in plan:
		assert_true(part.y > part.x and part.w > 0, "Parça boş olmamalı: %s" % part)
		for i in range(part.x, part.y):
			for s in part.w:
				var key := Vector2i(i, (part.z + s) % GRID_SEGMENTS)
				if seen.has(key):
					overlaps += 1
				seen[key] = true
	assert_eq(overlaps, 0, "İki parça aynı dörtgeni kapsamamalı")
	assert_eq(seen.size(), (GRID_RINGS - 1 - GRID_CENTER) * GRID_SEGMENTS, "Dış halkaların her dörtgeni bir parçada olmalı")


func test_terrain_chunks_reuse_the_grid_vertices() -> void:
	var shape := TerrainShape.new(1207)
	var grid := Terrain.build_grid(shape, GRID_SEGMENTS, GRID_RINGS, 0.6, 3600.0)
	var vertices: PackedVector3Array = grid[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = grid[Mesh.ARRAY_NORMAL]
	var total := Terrain.build_center(grid, GRID_SEGMENTS, GRID_CENTER).surface_get_array_index_len(0) / 3
	var mismatched := 0
	for part in Terrain.chunk_plan(GRID_SEGMENTS, GRID_RINGS, GRID_CENTER, Terrain.BAND_RINGS, 5):
		var arrays := Terrain.build_chunk(grid, GRID_SEGMENTS, part.x, part.y, part.z, part.w).surface_get_arrays(0)
		var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		total += (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
		var width := part.w + 1
		for k in v.size():
			var idx := (part.x + k / width) * GRID_SEGMENTS + (part.z + k % width) % GRID_SEGMENTS
			# Konum aynen saklanır; normal motorda 16 bitlik oktahedral biçimde saklandığı için payla karşılaştırılır.
			if v[k] != vertices[idx] or n[k].dot(normals[idx]) < 0.9999:
				mismatched += 1
	assert_eq(mismatched, 0, "Parçaların köşeleri ızgaranın aynı köşeleri olmalı (dikiş yok)")
	var full := Terrain.build_mesh(shape, GRID_SEGMENTS, GRID_RINGS, 0.6, 3600.0)
	assert_eq(total, full.surface_get_array_index_len(0) / 3, "Merkez diski ve parçalar tam ızgaranın üçgenleri kadar olmalı")


func test_terrain_coarse_center_is_watertight_and_meets_the_bands() -> void:
	var shape := TerrainShape.new(1207)
	var grid := Terrain.build_grid(shape, GRID_SEGMENTS, GRID_RINGS, 0.6, 3600.0)
	var full := _surface_stats(Terrain.build_center(grid, GRID_SEGMENTS, GRID_CENTER, 1))
	var coarse_mesh := Terrain.build_center(grid, GRID_SEGMENTS, GRID_CENTER, Terrain.CENTER_STEP)
	var coarse := _surface_stats(coarse_mesh)
	assert_true(coarse["triangles"] < full["triangles"] * 0.4, "Seyrek disk tam diskin üçgenlerinin %%40'ından az olmalı (%d / %d)" % [coarse["triangles"], full["triangles"]])
	assert_eq(coarse["down"], 0, "Aşağı bakan üçgen olmamalı")
	assert_almost(coarse["area"], full["area"], full["area"] * 0.0001, "Yatay alan aynı olmalı (boşluk ya da üst üste binme yok)")
	assert_eq(coarse["boundary"], GRID_SEGMENTS, "Yalnız son halka sınır olmalı (sık halkanın bütün bölütleri)")
	assert_eq(coarse["bad"], 0, "Her iç kenar iki üçgende olmalı")
	# Son halka dış bantların ilk halkasıyla aynı köşelerdir.
	var vertices: PackedVector3Array = grid[Mesh.ARRAY_VERTEX]
	var ring := {}
	for j in GRID_SEGMENTS:
		ring[vertices[GRID_CENTER * GRID_SEGMENTS + j]] = true
	var found := 0
	for v in coarse_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array:
		if ring.has(v):
			found += 1
	assert_eq(found, GRID_SEGMENTS, "Seyrek diskin son halkası bantların ilk halkasıyla aynı olmalı")


# --- Dağlar (saf) --------------------------------------------------------------------------------

func test_mountain_sectors_add_up_to_the_ring() -> void:
	var segments := 30
	var rings := 6
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	for i in rings:
		for j in segments:
			var a := TAU * float(j) / float(segments)
			vertices.append(Vector3(sin(a), float(i), -cos(a)) * (10.0 + i))
			normals.append(Vector3.UP)
	var grid := []
	grid.resize(Mesh.ARRAY_MAX)
	grid[Mesh.ARRAY_VERTEX] = vertices
	grid[Mesh.ARRAY_NORMAL] = normals
	var total := 0
	var seg := 0
	var used := {}
	while seg < segments:
		var count := mini(7, segments - seg)
		var arrays := Mountains.build_sector(grid, segments, rings, seg, count).surface_get_arrays(0)
		total += (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
		for v in arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array:
			used[v] = true
		seg += count
	assert_eq(total, (rings - 1) * segments * 2, "Dilimler halkanın bütün üçgenleri olmalı")
	var ring := {}
	for v in vertices:
		ring[v] = true
	var foreign := 0
	for v in used:
		if not ring.has(v):
			foreign += 1
	assert_eq(foreign, 0, "Dilimler yalnız halkanın köşelerini kullanmalı (dikiş yok)")
	assert_eq(used.size(), vertices.size(), "Halkanın her köşesi bir dilimde olmalı")


# --- Ağaç ve kaya ağları (saf) -------------------------------------------------------------------

func test_far_spruce_has_no_trunk_and_the_same_tiers() -> void:
	var with_trunk := TreeKit.spruce(14, 3, 4).surface_get_arrays(0)
	var without := TreeKit.spruce(14, 3, 4, false).surface_get_arrays(0)
	var colors: PackedColorArray = without[Mesh.ARRAY_COLOR]
	var trunk := 0
	for c in colors:
		if c.a == 0.0:
			trunk += 1
	assert_eq(trunk, 0, "Gövdesiz ladinde gövde köşesi (COLOR.a = 0) olmamalı")
	var tiers := PackedVector3Array()
	var all_colors: PackedColorArray = with_trunk[Mesh.ARRAY_COLOR]
	var all_vertices: PackedVector3Array = with_trunk[Mesh.ARRAY_VERTEX]
	for i in all_vertices.size():
		if all_colors[i].a > 0.0:
			tiers.append(all_vertices[i])
	assert_true(tiers == (without[Mesh.ARRAY_VERTEX] as PackedVector3Array), "Dal katları gövdeli ladininkiyle aynı olmalı")
	var removed := (with_trunk[Mesh.ARRAY_INDEX] as PackedInt32Array).size() - (without[Mesh.ARRAY_INDEX] as PackedInt32Array).size()
	assert_eq(removed / 3, 10, "Gövde 10 üçgendir")


func test_lod_chain_keeps_the_full_mesh_and_adds_levels() -> void:
	var stone := RockField.boulder_mesh(500, 2, 4)
	var chained := RockField.with_lod_chain(stone)
	assert_eq(chained.surface_get_array_index_len(0), stone.surface_get_array_index_len(0), "En yakın düzey tam ağ olmalı")
	var lods: Array = RenderingServer.mesh_get_surface(chained.get_rid(), 0).get("lods", [])
	assert_true(lods.size() >= 1, "Taşın LOD zinciri olmalı")


# --- Dünya ----------------------------------------------------------------------------------------

func test_world_terrain_is_split_into_pieces_that_cast_no_shadow() -> void:
	var world := await _get_world()
	var terrain := world.get_node_or_null(^"Terrain") as Terrain
	if terrain == null:
		fail("Terrain yok")
		return
	var parts := terrain.get_parts()
	var plan := Terrain.chunk_plan(terrain.angular_segments, terrain.rings, Terrain.CENTER_RINGS, Terrain.BAND_RINGS, Terrain.SECTORS)
	assert_eq(parts.size(), plan.size() + 1, "Merkez diski ve her bant dilimi ayrı parça olmalı")
	var casting := 0
	for mi in parts:
		if mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			casting += 1
		assert_eq(mi.material_override, terrain.material, "Bütün parçalar arazi malzemesini paylaşmalı: %s" % mi.name)
	assert_eq(casting, 0, "Arazi gölge düşürmemeli (ay ışığında kendi gölgesi görünmez)")
	assert_eq(parts[0].name, &"TerrainMesh", "İlk parça merkez diski (TerrainMesh) olmalı")


func test_world_mountains_are_sectors_without_shadow() -> void:
	var world := await _get_world()
	var mountains := world.get_node_or_null(^"Mountains") as Mountains
	if mountains == null:
		fail("Mountains yok")
		return
	var sectors := mountains.get_sectors()
	assert_eq(sectors.size(), Mountains.SECTORS, "Dağ halkası dilimlere bölünmeli")
	var total := 0
	for mi in sectors:
		total += _triangles(mi.mesh)
		assert_eq(mi.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Dağlar gölge düşürmez: %s" % mi.name)
	assert_eq(total, (mountains.rings - 1) * mountains.angular_segments * 2, "Dilimler halkanın bütün üçgenleri olmalı")


func test_world_grass_flowers_and_small_rocks_cast_no_shadows() -> void:
	var world := await _get_world()
	var meadow := world.get_node_or_null(^"Meadow")
	var rocks := world.get_node_or_null(^"RockField")
	if meadow == null or rocks == null:
		fail("Meadow ya da RockField yok")
		return
	var checked := 0
	for node in meadow.get_children():
		if node is MultiMeshInstance3D and (String(node.name).begins_with("Grass") or String(node.name).begins_with("Flowers")):
			checked += 1
			assert_eq((node as MultiMeshInstance3D).cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Çimen ve çiçek gölge atmaz: %s" % node.name)
	assert_true(checked > 10, "Çayırda çimen kareleri olmalı (%d)" % checked)
	var small := 0
	for node in rocks.find_children("Rocks*", "MultiMeshInstance3D", false, false):
		small += 1
		assert_eq((node as MultiMeshInstance3D).cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Küçük kayalar gölge atmaz: %s" % node.name)
	assert_true(small > 0, "Çayırda küçük kaya olmalı")


func test_world_hero_rock_shadows_come_from_a_lighter_copy() -> void:
	var world := await _get_world()
	var rocks := world.get_node_or_null(^"RockField") as RockField
	if rocks == null:
		fail("RockField yok")
		return
	var proxies := 0
	for i in rocks.hero_rocks.size():
		var prop := rocks.get_node_or_null(NodePath("HeroRock%d" % i)) as MeshyProp
		if prop == null or not prop.has_model():
			continue
		var shadow := prop.get_node_or_null(^"Shadow") as MeshInstance3D
		assert_not_null(shadow, "HeroRock%d gölge kopyası olmalı" % i)
		if shadow == null:
			continue
		proxies += 1
		assert_false(prop.cast_shadows, "HeroRock%d dokulu modeli gölge düşürmemeli" % i)
		assert_eq(shadow.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY, "HeroRock%d kopyası yalnız gölge olmalı" % i)
		var model_tris := 0
		for mi in prop.find_children("*", "MeshInstance3D", true, false):
			if mi != shadow:
				var model_mesh := (mi as MeshInstance3D).mesh
				model_tris += _triangles(model_mesh)
				assert_eq((mi as MeshInstance3D).cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "HeroRock%d modeli gölge düşürmemeli" % i)
				# Dokulu ağın LOD zinciri (UV ve malzeme aynı; motor bir pikselin altında sade düzeye geçer).
				var lods: Array = RenderingServer.mesh_get_surface(model_mesh.get_rid(), 0).get("lods", [])
				assert_true(lods.size() >= 1, "HeroRock%d dokulu ağında LOD zinciri olmalı" % i)
				assert_not_null((mi as MeshInstance3D).get_surface_override_material(0), "HeroRock%d malzemesi korunmalı" % i)
		var proxy_tris := _triangles(shadow.mesh)
		assert_true(proxy_tris < model_tris * 0.7, "HeroRock%d kopyası daha az üçgenli olmalı (%d / %d)" % [i, proxy_tris, model_tris])
		# Kopya modelin yerindedir: kutuları örtüşür.
		var model_box := prop.global_transform * prop.get_model_aabb()
		var shadow_box := shadow.global_transform * shadow.get_aabb()
		var size := maxf(model_box.size.x, maxf(model_box.size.y, model_box.size.z))
		assert_vec_almost(shadow_box.get_center(), model_box.get_center(), size * 0.03, "HeroRock%d kopyası modelin yerinde olmalı" % i)
		assert_vec_almost(shadow_box.size, model_box.size, size * 0.05, "HeroRock%d kopyası modelin boyunda olmalı" % i)
	if MeshyProp.exists(TreeKit.FOLDER, RockField.BOULDER):
		assert_true(proxies > 10, "Kahraman kayaların gölge kopyası olmalı (%d)" % proxies)


func test_world_near_pines_cast_shadow_through_a_lighter_copy() -> void:
	var world := await _get_world()
	var forest := world.get_node_or_null(^"Forest") as Forest
	if forest == null:
		fail("Forest yok")
		return
	if not MeshyProp.exists(TreeKit.FOLDER, forest.young_model):
		return
	# Çamlar menü gözündeki düzeyleriyle (tam ağ) sınanır: kamera varsa _process uzak çamı uzak düzeye geçirmiş olabilir.
	forest.update_far_levels(Forest.MENU_EYE)
	var planted := forest.get_planted_trees()
	var near := 0
	for i in planted.size():
		var pine := forest.get_node_or_null(NodePath("Pines/Pine%d" % i)) as MeshInstance3D
		if pine == null:
			fail("Pine%d yok" % i)
			continue
		assert_eq(pine.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Pine%d kendisi gölge düşürmemeli" % i)
		var shadow := pine.get_node_or_null(^"Shadow") as MeshInstance3D
		var is_near := Vector2(planted[i].x, planted[i].y).length() < forest.shadow_radius
		if not is_near:
			assert_null(shadow, "Pine%d kamptan uzak: gölge kopyası olmamalı" % i)
			continue
		near += 1
		assert_not_null(shadow, "Pine%d kampa yakın: gölge kopyası olmalı" % i)
		if shadow:
			assert_eq(shadow.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY, "Pine%d kopyası yalnız gölge olmalı" % i)
			assert_eq(shadow.material_override, pine.material_override, "Pine%d kopyası aynı malzemeyle sallanmalı" % i)
			assert_true(_triangles(shadow.mesh) * 3 < _triangles(pine.mesh), "Pine%d kopyası çamın üçgenlerinin üçte birinden az olmalı" % i)
	assert_true(near > 0 and near < planted.size(), "Yalnız kampa yakın çamların gölgesi olmalı (%d / %d)" % [near, planted.size()])


func test_world_far_pines_use_a_lighter_level_but_not_from_the_menu() -> void:
	var world := await _get_world()
	var forest := world.get_node_or_null(^"Forest") as Forest
	if forest == null:
		fail("Forest yok")
		return
	if not MeshyProp.exists(TreeKit.FOLDER, forest.young_model):
		return
	forest.update_far_levels(Forest.MENU_EYE)
	var pines := forest.get_node(^"Pines").get_children()
	var full := {}
	var nearest_switch := INF
	for node in pines:
		var pine := node as MeshInstance3D
		full[pine] = pine.mesh
		var center := (pine.global_transform * pine.mesh.get_aabb()).get_center()
		nearest_switch = minf(nearest_switch, Forest.FAR_DISTANCE - Forest.FAR_MARGIN - center.distance_to(Forest.MENU_EYE))
	# Menü kadrajı değişmez: menü gözünden bütün çamlar tam düzeyde kalır (en uzak çam ~58,5 m).
	assert_true(nearest_switch > 1.0, "Menü gözünden en uzak çam uzak düzeye geçiş sınırına 1 m'den yakın olmamalı (pay %.2f m)" % nearest_switch)
	forest.update_far_levels(Forest.MENU_EYE)
	assert_eq(forest.get_far_pine_count(), 0, "Menü gözünden hiçbir çam uzak düzeyde olmamalı")
	# Çok uzaktan bütün çamlar uzak düzeye geçer, yakına gelince tam düzeye döner.
	forest.update_far_levels(Vector3(0.0, 20.0, 600.0))
	assert_eq(forest.get_far_pine_count(), pines.size(), "Uzaktan bütün çamlar uzak düzeyde olmalı")
	var lighter := 0
	for node in pines:
		var pine := node as MeshInstance3D
		if _triangles(pine.mesh) * 3 < _triangles(full[pine] as Mesh) * 2 and _triangles(pine.mesh) * 3 > _triangles(full[pine] as Mesh):
			lighter += 1
	assert_eq(lighter, pines.size(), "Uzak düzey tam ağın yarısı kadar üçgenli olmalı")
	forest.update_far_levels(Forest.MENU_EYE)
	var restored := 0
	for node in pines:
		if (node as MeshInstance3D).mesh == full[node]:
			restored += 1
	assert_eq(restored, pines.size(), "Yakına gelince bütün çamlar tam ağa dönmeli")
	# Sınırda titremez: payın içinde düzey değişmez.
	var one := pines[0] as MeshInstance3D
	var c := (one.global_transform * one.mesh.get_aabb()).get_center()
	var dir := Vector3(0.0, 0.0, 1.0)
	forest.update_far_levels(c + dir * (Forest.FAR_DISTANCE + Forest.FAR_MARGIN * 0.5))
	assert_eq(one.mesh, full[one], "Payın içinde (dışa doğru) çam tam düzeyde kalmalı")
	forest.update_far_levels(c + dir * (Forest.FAR_DISTANCE + Forest.FAR_MARGIN * 1.5))
	assert_ne(one.mesh, full[one], "Payın dışında çam uzak düzeye geçmeli")
	forest.update_far_levels(c + dir * (Forest.FAR_DISTANCE - Forest.FAR_MARGIN * 0.5))
	assert_ne(one.mesh, full[one], "Payın içinde (içe doğru) çam uzak düzeyde kalmalı")
	forest.update_far_levels(Forest.MENU_EYE)


func test_valley_rock_tier_switches_at_the_far_distance() -> void:
	var d := RockField.FAR_ROCK_DISTANCE
	assert_eq(RockField.valley_rock_tier(Vector2(0.0, -(d - 1.0))), 0, "Sınırın berisinde tam kaya")
	assert_eq(RockField.valley_rock_tier(Vector2(0.0, -(d + 1.0))), 3, "Sınırın ötesinde seyrek kaya")
	assert_eq(RockField.valley_rock_tier(Vector2(d * 0.8, -d * 0.8)), 3, "Uzaklık yönden bağımsız")
	assert_eq(MeshKit.rock(301, RockField.FAR_ROCK_SUBDIVISIONS, 0.35).surface_get_array_index_len(0) / 3, 80, "Seyrek kaya 80 üçgen")


func test_world_valley_rocks_are_chunked_and_far_ones_are_lighter() -> void:
	var world := await _get_world()
	var rocks := world.get_node_or_null(^"RockField") as RockField
	if rocks == null:
		fail("RockField yok")
		return
	# Kareler ad ile tanınır: ValleyRocks<çeşit>_<kare x>_<kare z> (Near: Meshy kayası). Başsız koşuda MultiMesh örnek
	# dönüşümleri okunamaz; kural adlar ve ağlarla sınanır.
	var chunks := rocks.find_children("ValleyRocks*", "MultiMeshInstance3D", false, false)
	assert_true(chunks.size() > 6, "Vadi kayaları karelere bölünmeli (%d)" % chunks.size())
	var keys := {}
	var tiers := {0: 0, 3: 0}
	var wrong := 0
	for node in chunks:
		var name := String(node.name)
		var near := name.begins_with("ValleyRocksNear")
		var fields := name.trim_prefix("ValleyRocksNear" if near else "ValleyRocks").split("_")
		assert_eq(fields.size(), 3, "%s: çeşit ve kare adında olmalı" % name)
		if fields.size() != 3:
			continue
		var cx := int(fields[1])
		var cz := int(fields[2])
		keys[Vector2i(cx, cz)] = true
		if near:
			continue
		var variant := int(fields[0])
		var tris := _triangles((node as MultiMeshInstance3D).multimesh.mesh)
		var tier := 3 if variant >= 3 else 0
		tiers[tier] += 1
		if (tier == 3) != (tris <= 100):
			wrong += 1
		# Seyrek çeşit yalnız sınırın ötesine uzanan karelerde, tam çeşit yalnız sınırın berisine uzanan karelerde olabilir.
		var square := Rect2(Vector2(cx, cz) * RockField.VALLEY_CHUNK, Vector2.ONE * RockField.VALLEY_CHUNK)
		var nearest := Vector2(clampf(0.0, square.position.x, square.end.x), clampf(0.0, square.position.y, square.end.y)).length()
		var farthest := 0.0
		for corner in [square.position, square.end, Vector2(square.position.x, square.end.y), Vector2(square.end.x, square.position.y)]:
			farthest = maxf(farthest, (corner as Vector2).length())
		if (tier == 3 and farthest <= RockField.FAR_ROCK_DISTANCE) or (tier == 0 and nearest >= RockField.FAR_ROCK_DISTANCE):
			wrong += 1
	assert_eq(wrong, 0, "Çeşit, ağ ve kare uyuşmalı (sınırın ötesi seyrek, berisi tam)")
	assert_true(tiers[3] > 0 and tiers[0] > 0, "Hem tam hem seyrek uzak kaya karesi olmalı (%s)" % tiers)
	assert_true(keys.size() > 4, "Kayalar birden çok kareye dağılmalı (%d)" % keys.size())


func test_world_formation_stones_have_lod_chains() -> void:
	var world := await _get_world()
	var stone := world.get_node_or_null(^"RockField/Formation0/Stone0") as MeshInstance3D
	assert_not_null(stone, "Küme taşı kurulmalı")
	if stone == null:
		return
	var lods: Array = RenderingServer.mesh_get_surface(stone.mesh.get_rid(), 0).get("lods", [])
	assert_true(lods.size() >= 1, "Küme taşının LOD zinciri olmalı")


## Son dünya testi: paylaşılan dünyayı serbest bırakır.
func test_world_is_freed_cleanly() -> void:
	if _world == null:
		return
	var world := _world
	_world = null
	world.queue_free()
	await get_tree().create_timer(0.2).timeout
	await wait_frames(2)
	assert_false(is_instance_valid(world), "Dünya silinmeli")


# --- Yardımcılar ---------------------------------------------------------------------------------

func _get_world() -> World:
	if _world == null:
		var packed := load(WORLD_SCENE) as PackedScene
		_world = packed.instantiate() as World
		add_child(_world)
		# Forest, RockField ve Meadow kurulumu bir sonraki kareye ertelenir.
		await wait_frames(3)
	return _world


## Ağdaki üçgen sayısı (ArrayMesh'te dizi kopyalanmadan; öteki ağlarda yüzlerden).
static func _triangles(mesh: Mesh) -> int:
	if mesh is ArrayMesh:
		var total := 0
		for s in mesh.get_surface_count():
			total += (mesh as ArrayMesh).surface_get_array_index_len(s) / 3
		return total
	return mesh.get_faces().size() / 3 if mesh else 0


## Yüzeyin özeti: üçgen sayısı, aşağı bakan üçgen, yatay (xz) alan, sınır kenarı ve ikiden fazla üçgende geçen kenar.
static func _surface_stats(mesh: ArrayMesh) -> Dictionary:
	var arrays := mesh.surface_get_arrays(0)
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var down := 0
	var area := 0.0
	var edges := {}
	for t in range(0, idx.size(), 3):
		var p0 := v[idx[t]]
		var n := (v[idx[t + 2]] - p0).cross(v[idx[t + 1]] - p0)
		if n.y <= 0.0:
			down += 1
		area += absf(n.y) * 0.5
		for e in 3:
			var a := idx[t + e]
			var b := idx[t + (e + 1) % 3]
			var key := Vector2i(mini(a, b), maxi(a, b))
			edges[key] = int(edges.get(key, 0)) + 1
	var boundary := 0
	var bad := 0
	for key: Vector2i in edges:
		if edges[key] == 1:
			boundary += 1
		elif edges[key] != 2:
			bad += 1
	return {"triangles": idx.size() / 3, "down": down, "area": area, "boundary": boundary, "bad": bad}
