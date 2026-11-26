extends TestCase
## PathNetwork testleri: parça uzaklığı, işaretli kenar uzaklığı, eğri yumuşatma ve bölme,
## parça bütçesi, hızlı (ızgaralı) sorgu; ayrıca dünya yerleşimi: patikalar engellerin içinden
## geçmez, kaya kümeleri menü kamerasından kampın önünü kapatmaz (K98), patikalarda çimen çıkmaz.

const WORLD_SCENE := "res://scenes/world/world.tscn"

var _world: World


# --- Saf geometri -----------------------------------------------------------------

func test_distance_to_segment() -> void:
	var a := Vector2(0.0, 0.0)
	var b := Vector2(10.0, 0.0)
	assert_almost(PathNetwork.distance_to_segment(Vector2(5.0, 3.0), a, b), 3.0, 0.0001, "Ortadan dik uzaklık")
	assert_almost(PathNetwork.distance_to_segment(Vector2(13.0, 4.0), a, b), 5.0, 0.0001, "Uçtan sonra uca uzaklık")
	assert_almost(PathNetwork.distance_to_segment(Vector2(-3.0, 0.0), a, b), 3.0, 0.0001, "Baştan önce başa uzaklık")
	assert_almost(PathNetwork.distance_to_segment(Vector2(2.0, 1.0), a, a), Vector2(2.0, 1.0).length(), 0.0001, "Sıfır uzunluklu parça")


func test_signed_distance_is_negative_inside_zero_on_edge_positive_outside() -> void:
	var segments: Array[Vector4] = [Vector4(0.0, 0.0, 10.0, 0.0)]
	var halves := PackedFloat32Array([1.0])
	assert_almost(PathNetwork.signed_distance(Vector2(5.0, 0.0), segments, halves), -1.0, 0.0001, "Ortada -yarı genişlik")
	assert_almost(PathNetwork.signed_distance(Vector2(5.0, 1.0), segments, halves), 0.0, 0.0001, "Kenarda 0")
	assert_almost(PathNetwork.signed_distance(Vector2(5.0, -3.0), segments, halves), 2.0, 0.0001, "Dışarıda artı")
	assert_almost(PathNetwork.signed_distance(Vector2(12.0, 0.0), segments, halves), 1.0, 0.0001, "Yuvarlak uç")
	var empty: Array[Vector4] = []
	assert_eq(PathNetwork.signed_distance(Vector2.ZERO, empty, PackedFloat32Array()), INF, "Patika yoksa INF")


func test_signed_distance_takes_the_nearest_of_many_segments() -> void:
	var segments: Array[Vector4] = [Vector4(0.0, 0.0, 10.0, 0.0), Vector4(0.0, 5.0, 10.0, 5.0)]
	var halves := PackedFloat32Array([0.5, 1.5])
	assert_almost(PathNetwork.signed_distance(Vector2(5.0, 2.0), segments, halves), 1.5, 0.0001, "Geniş patikanın kenarı daha yakın")
	assert_almost(PathNetwork.signed_distance(Vector2(5.0, 0.2), segments, halves), -0.3, 0.0001)


func test_smooth_polyline_keeps_endpoints_and_passes_through_corners() -> void:
	var points := PackedVector2Array([Vector2(0.0, 0.0), Vector2(4.0, 2.0), Vector2(8.0, 0.0), Vector2(12.0, 3.0)])
	var curve := PathNetwork.smooth_polyline(points, 8)
	assert_eq(curve[0], points[0], "Başlangıç korunmalı")
	assert_eq(curve[curve.size() - 1], points[points.size() - 1], "Bitiş korunmalı")
	assert_eq(curve.size(), (points.size() - 1) * 8 + 1)
	for p in points:
		var nearest := INF
		for c in curve:
			nearest = minf(nearest, c.distance_to(p))
		assert_true(nearest < 0.001, "Eğri köşe noktalarından geçmeli: %s" % p)


func test_resample_gives_equal_spacing() -> void:
	var line := PackedVector2Array([Vector2(0.0, 0.0), Vector2(3.0, 0.0), Vector2(10.0, 0.0)])
	var points := PathNetwork.resample(line, 5)
	assert_eq(points.size(), 6, "count + 1 nokta")
	for i in points.size():
		assert_almost(points[i].x, 2.0 * i, 0.0001, "Eşit aralık")
	assert_almost(PathNetwork.polyline_length(points), 10.0, 0.0001, "Uzunluk korunmalı")


func test_allocate_segments_respects_budget_and_minimum() -> void:
	var counts := PathNetwork.allocate_segments(PackedFloat32Array([100.0, 1.0, 1.0]), 10)
	var total := 0
	for c in counts:
		assert_true(c >= 2, "Her patikaya en az 2 parça")
		total += c
	assert_eq(total, 10, "Bütçe tam kullanılmalı")
	assert_eq(PathNetwork.allocate_segments(PackedFloat32Array([10.0, 10.0]), 8), PackedInt32Array([4, 4]), "Eşit uzunluk eşit pay")
	var tight := PathNetwork.allocate_segments(PackedFloat32Array([5.0, 5.0, 5.0, 5.0, 5.0]), 6)
	total = 0
	for c in tight:
		total += c
	assert_true(total <= 10, "En az 2'lik taban dışında bütçe aşılmamalı")


func test_default_network_fits_the_shader_and_tapers_free_ends() -> void:
	var net := PathNetwork.new()
	var segments := net.get_segments()
	var halves := net.get_half_widths()
	assert_true(segments.size() > 20, "Varsayılan ağ boş olmamalı")
	assert_true(segments.size() <= PathNetwork.MAX_SEGMENTS, "Shader dizisine sığmalı")
	assert_eq(halves.size(), segments.size())
	for w in halves:
		assert_between(w, 0.2, 0.8, "Yarı genişlik makul olmalı (patikalar 1.0–1.6 m)")
	# Her patikanın son parçası (serbest uç) ilk parçasından dar olmalı.
	var first := 0
	for path_index in net.paths.size():
		var count := _segment_count_of(net, path_index)
		assert_true(halves[first + count - 1] < halves[first] - 0.05, "Patika %d ucunda daralmalı" % path_index)
		first += count
	net.free()


func test_clamped_distance_matches_exact_distance_near_paths() -> void:
	var net := PathNetwork.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var mismatches := 0
	for i in 3000:
		var p := Vector2(rng.randf_range(-30.0, 30.0), rng.randf_range(-15.0, 38.0))
		var exact := net.distance_to_paths(p)
		var fast := net.distance_to_paths_clamped(p, 1.0)
		var expected := minf(exact, 1.0)
		if absf(fast - expected) > 0.0001:
			mismatches += 1
	assert_eq(mismatches, 0, "Hızlı sorgu, yakın noktalarda tam sorguyla aynı olmalı")
	net.free()


func test_shader_parameters_fill_and_clamp_the_shader_arrays() -> void:
	var segments: Array[Vector4] = [Vector4(0.0, 0.0, 4.0, 0.0), Vector4(4.0, 0.0, 4.0, 3.0)]
	var params := PathNetwork.shader_parameters(segments, PackedFloat32Array([0.6, 0.5]))
	assert_eq(int(params["path_segment_count"]), 2)
	assert_eq((params["path_segments"] as Array).size(), PathNetwork.MAX_SEGMENTS, "Dizi shader boyutuna tamamlanmalı")
	assert_eq((params["path_half_widths"] as PackedFloat32Array).size(), PathNetwork.MAX_SEGMENTS)
	assert_eq((params["path_group_bounds"] as Array).size(), PathNetwork.MAX_GROUPS)
	var bounds: Vector4 = params["path_bounds"]
	assert_true(bounds.x <= -0.6 and bounds.y <= -0.6 and bounds.z >= 4.5 and bounds.w >= 3.5, "Ağın kutusu kenar payıyla tüm parçaları içermeli: %s" % bounds)
	# Bütçeyi aşan (ör. editörde çok sayıda patika eklenmiş) ağ: fazlası kırpılır, shader dizisi taşmaz.
	var many: Array[Vector4] = []
	var halves := PackedFloat32Array()
	for i in PathNetwork.MAX_SEGMENTS + 10:
		many.append(Vector4(float(i), 0.0, float(i) + 0.5, 0.0))
		halves.append(0.5)
	var clamped := PathNetwork.shader_parameters(many, halves)
	assert_eq(int(clamped["path_segment_count"]), PathNetwork.MAX_SEGMENTS, "Parça sayısı shader sınırını aşmamalı")
	assert_eq((clamped["path_segments"] as Array).size(), PathNetwork.MAX_SEGMENTS)
	assert_eq((clamped["path_half_widths"] as PackedFloat32Array).size(), PathNetwork.MAX_SEGMENTS)
	var empty: Array[Vector4] = []
	var none := PathNetwork.shader_parameters(empty, PackedFloat32Array())
	assert_eq(int(none["path_segment_count"]), 0)
	var empty_bounds: Vector4 = none["path_bounds"]
	assert_true(empty_bounds.x > empty_bounds.z, "Patika yoksa kutu boş olmalı (her piksel atlanır)")


func test_group_bounds_contain_their_segments() -> void:
	var net := PathNetwork.new()
	var segments := net.get_segments()
	var halves := net.get_half_widths()
	var groups := PathNetwork.group_bounds(segments, halves, PathNetwork.GROUP_SIZE, 0.5)
	assert_true(groups.size() <= PathNetwork.MAX_GROUPS)
	for i in segments.size():
		var g := groups[i / PathNetwork.GROUP_SIZE]
		var s := segments[i]
		for p in [Vector2(s.x, s.y), Vector2(s.z, s.w)]:
			assert_true(p.x - halves[i] >= g.x and p.y - halves[i] >= g.y and p.x + halves[i] <= g.z and p.y + halves[i] <= g.w,
				"Parça %d grubunun kutusunda olmalı" % i)
	net.free()


# --- Dünya yerleşimi (paylaşılan dünya örneği) ---------------------------------------

func test_paths_do_not_cross_obstacles_or_rugs() -> void:
	var world := await _get_world()
	var net := _network(world)
	if net == null:
		return
	var circles := world.collect_obstacles()
	assert_false(circles.is_empty())
	for c in circles:
		var d := net.distance_to_paths(Vector2(c.x, c.y))
		assert_true(d >= c.z - 0.05, "Patika bir engelin içinden geçiyor: %s (kenar uzaklığı %.2f)" % [c, d])
	for rug in world.get_tree().get_nodes_in_group(Rug.GROUND_COVER_GROUP):
		for c in rug.get_cover_circles():
			assert_true(net.distance_to_paths(Vector2(c.x, c.y)) >= c.z * 0.8, "Patika halının üstünden geçmemeli: %s" % c)


func test_rock_formations_are_registered_obstacles() -> void:
	var world := await _get_world()
	var rocks := world.get_node_or_null(^"RockField") as RockField
	assert_not_null(rocks)
	if rocks == null:
		return
	assert_true(rocks.is_in_group(World.OBSTACLE_GROUP), "Kaya alanı engel grubunda olmalı")
	var circles := world.collect_obstacles()
	assert_true(rocks.formations.size() >= 2 and rocks.formations.size() <= 4, "2–4 kaya kümesi olmalı")
	for i in rocks.formations.size():
		for stone in RockField.formation_layout(rocks.formations[i], rocks.formation_seed + i * 101):
			assert_true(circles.has(RockField.stone_circle(stone)), "Küme %d taşı engel listesinde olmalı" % i)


func test_rock_formations_fade_out_of_the_line_of_sight() -> void:
	var world := await _get_world()
	var rocks := world.get_node_or_null(^"RockField") as RockField
	if rocks == null:
		fail("RockField yok")
		return
	assert_true(rocks.is_in_group(FollowCamera.OCCLUDER_GROUP), "Kaya kümeleri kamera örtme grubunda olmalı")
	var stone := rocks.get_node_or_null(^"Formation0/Stone0") as MeshInstance3D
	assert_not_null(stone, "Küme taşları kurulmuş olmalı")
	if stone == null:
		return
	var mat := stone.material_override as ShaderMaterial
	rocks.set_camera_occlusion(Vector3(1.0, 8.0, 2.0), Vector3(0.0, 0.7, -3.0))
	assert_eq(mat.get_shader_parameter("occlusion_from"), Vector3(1.0, 8.0, 2.0))
	assert_eq(mat.get_shader_parameter("occlusion_to"), Vector3(0.0, 0.7, -3.0))
	assert_true(float(mat.get_shader_parameter("occlusion_radius")) > 0.5, "Örtme tüpü açık olmalı")


func test_rock_formations_do_not_block_the_menu_view_of_the_camp() -> void:
	# Ana sahnedeki (scenes/main.tscn) gerçek menü kamerası. K98 (2026-11-07): kamera kampa uzak ve yüksekten bakar (ateşe 26,4 m, 38°),
	# kaya kümeleri karede görünebilir (çevre kareyi taşır) ama kampın önünü kapatmaz: kameradan ateşe, ateş başına, iki yurda ve ahıra
	# uzanan görüş çizgileri hiçbir kümenin taşına girmez. (4. referansın alçak kadrajında kümeler karenin dışındaydı.)
	var menu := _main_menu_camera()
	if menu.is_empty():
		fail("scenes/main.tscn içinde Camera3D bulunamadı")
		return
	var world := await _get_world()
	var rocks := world.get_node_or_null(^"RockField") as RockField
	if rocks == null:
		fail("RockField yok")
		return
	var shape := world.get_terrain_shape()
	var eye: Vector3 = (menu["transform"] as Transform3D).origin
	var targets: Array[Vector3] = [Vector3(0.0, 0.6, 0.0), Vector3(-1.6, 0.8, 0.6), Vector3(1.7, 0.8, -0.6),
		Vector3(-6.18, 1.5, -4.31), Vector3(6.64, 1.5, -7.26), Vector3(13.76, 1.5, -14.65)]
	var unit := AABB(Vector3(-0.5, 0.0, -0.5), Vector3.ONE)
	for i in rocks.formations.size():
		for stone in RockField.formation_layout(rocks.formations[i], rocks.formation_seed + i * 101):
			var inverse := RockField.stone_transform(stone, shape).affine_inverse()
			for target in targets:
				var ground := shape.height_at(target.x, target.z)
				var to := target + Vector3(0.0, ground, 0.0)
				var hit: Variant = unit.intersects_segment(inverse * eye, inverse * to)
				assert_true(hit == null, "Küme %d menü kamerasından %s'ı kapatıyor" % [i, to])


func test_default_camera_sees_the_player_along_every_path() -> void:
	# Oyun kamerası varsayılan açıda (yaw 0, FollowCamera.DEFAULT_*) karakterin güneyinde durur. Patikanın her
	# noktasında kameradan karakterin göğsüne uzanan görüş hattı kamp çamlarının dallarına ancak kamera örtmesinin
	# tam saydam çekirdeği kadar girebilir (Forest.OCCLUSION_CORE): o dallar noktalı saydamlaşır, karakter görünür.
	# Çam dalları koni gibi düşünülür (MeshKit.conifer: alt kat ~2.8, tepe ~0.2 birim yarıçap, ~10 birim boy).
	var world := await _get_world()
	var net := _network(world)
	var forest := world.get_node_or_null(^"Forest") as Forest
	if net == null or forest == null:
		fail("PathNetwork ya da Forest yok")
		return
	var shape := world.get_terrain_shape()
	var segments := net.get_segments()
	for s in segments:
		for t in [0.0, 0.5]:
			var p := Vector2(s.x, s.y).lerp(Vector2(s.z, s.w), t)
			var focus := Vector3(p.x, shape.height_at(p.x, p.y) + 0.7, p.y)
			var eye := FollowCamera.compute_transform(focus, 0.0, FollowCamera.DEFAULT_PITCH_DEG, FollowCamera.DEFAULT_DISTANCE).origin
			for tree in forest.camp_trees:
				var clearance := _sight_clearance(eye, focus, tree, shape)
				assert_true(clearance > -Forest.OCCLUSION_CORE, "Patika noktası %s: kamera ile karakter arasında çam %s (%.2f m)" % [p, tree, clearance])


func test_rock_formations_keep_clear_of_camp_tree_trunks() -> void:
	var world := await _get_world()
	var rocks := world.get_node_or_null(^"RockField") as RockField
	var forest := world.get_node_or_null(^"Forest") as Forest
	if rocks == null or forest == null:
		fail("RockField ya da Forest yok")
		return
	for i in rocks.formations.size():
		for stone in RockField.formation_layout(rocks.formations[i], rocks.formation_seed + i * 101):
			var c := RockField.stone_circle(stone)
			for tree in forest.camp_trees:
				var gap := Vector2(c.x, c.y).distance_to(Vector2(tree.x, tree.y)) - c.z
				assert_true(gap > 1.0, "Küme %d taşı bir çam gövdesine çok yakın: %s (%.2f m)" % [i, tree, gap])


func test_rock_formations_keep_clear_of_paths_and_camp() -> void:
	var world := await _get_world()
	var net := _network(world)
	var rocks := world.get_node_or_null(^"RockField") as RockField
	if net == null or rocks == null:
		return
	var camp: Array[Vector3] = []
	for node in world.get_tree().get_nodes_in_group(World.OBSTACLE_GROUP):
		if node != rocks and node.has_method("get_obstacle_circles"):
			camp.append_array(node.get_obstacle_circles())
	for i in rocks.formations.size():
		for stone in RockField.formation_layout(rocks.formations[i], rocks.formation_seed + i * 101):
			var c := RockField.stone_circle(stone)
			var p := Vector2(c.x, c.y)
			assert_true(net.distance_to_paths(p) > c.z + 0.3, "Küme %d taşı patikaya taşıyor: %s" % [i, c])
			assert_true(p.length() > 12.0, "Kümeler kampın dışında olmalı: %s" % p)
			for o in camp:
				assert_true(p.distance_to(Vector2(o.x, o.y)) > c.z + o.z, "Küme %d kamp nesnesiyle çakışıyor: %s" % [i, o])


func test_terrain_material_receives_the_paths() -> void:
	var world := await _get_world()
	var net := _network(world)
	var terrain := world.get_node_or_null(^"Terrain") as Terrain
	if net == null or terrain == null or terrain.material == null:
		fail("Arazi malzemesi yok")
		return
	assert_eq(int(terrain.material.get_shader_parameter("path_segment_count")), net.get_segments().size(), "Parça sayısı shader'a gitmeli")
	var segs: Array = terrain.material.get_shader_parameter("path_segments")
	assert_eq(segs.size(), PathNetwork.MAX_SEGMENTS, "Dizi shader boyutuna tamamlanmalı")
	assert_eq(segs[0], net.get_segments()[0])
	var bounds: Vector4 = terrain.material.get_shader_parameter("path_bounds")
	assert_true(bounds.x < bounds.z and bounds.y < bounds.w, "Ağın kutusu geçerli olmalı")


func test_meadow_keeps_paths_clear_and_thins_grass_at_the_edges() -> void:
	# Not: Başsız (headless) çalışmada MultiMesh örnek konumları okunamaz; bu yüzden çayırın
	# yerleştirme kuralı (grass_density / grass_height) doğrudan sorgulanır.
	var world := await _get_world()
	var net := _network(world)
	var meadow := world.get_node_or_null(^"Meadow") as Meadow
	if net == null or meadow == null:
		fail("Meadow yok")
		return
	var blockers := Meadow.collect_blockers(world.get_tree())
	var segments := net.get_segments()
	var halves := net.get_half_widths()
	var on_path := 0
	for i in segments.size():
		var s := segments[i]
		var a := Vector2(s.x, s.y)
		var b := Vector2(s.z, s.w)
		var side := (b - a).normalized().orthogonal()
		for t in [0.0, 0.5]:
			var c := a.lerp(b, t)
			for p in [c, c + side * (halves[i] - 0.05), c - side * (halves[i] - 0.05)]:
				if meadow.grass_density(p, blockers) > 0.0:
					on_path += 1
	assert_eq(on_path, 0, "Patikanın üstünde çimen/çiçek çıkmamalı")
	# Kenarın hemen dışında çimen seyrek ve kısa, biraz uzakta tam yoğun.
	assert_almost(Meadow.path_weight(-0.3, 0.55), 0.0, 0.0001)
	assert_between(Meadow.path_weight(0.15, 0.55), 0.3, 0.6)
	assert_almost(Meadow.path_weight(0.8, 0.55), 1.0, 0.0001)
	# Kenara yakın çimen kısalır: aynı noktayı patika etkisi kapalıyken ölçüp karşılaştır.
	var k := segments.size() / 2
	var s0 := segments[k]
	var mid := Vector2(s0.x, s0.y).lerp(Vector2(s0.z, s0.w), 0.5)
	var out := (Vector2(s0.z, s0.w) - Vector2(s0.x, s0.y)).normalized().orthogonal()
	var near := mid + out * (halves[k] + 0.1)
	var edge_distance := net.distance_to_paths(near)
	var with_path := meadow.grass_height(near)
	var saved: PathNetwork = meadow._paths
	meadow._paths = null
	var without_path := meadow.grass_height(near)
	meadow._paths = saved
	var expected := lerpf(0.7, 1.0, smoothstep(0.0, meadow.path_fade, edge_distance))
	assert_almost(with_path / without_path, expected, 0.001, "Kenardaki çimen patika etkisiyle kısalmalı")
	assert_true(with_path < without_path, "Kenardaki çimen daha kısa olmalı")


func test_pebbles_line_the_path_edges() -> void:
	var net := PathNetwork.new()
	var shape := TerrainShape.new()
	var buckets := net.pebble_transforms(shape)
	var count := 0
	var edge := 0
	for bucket in buckets:
		for xform in bucket:
			var o: Vector3 = (xform as Transform3D).origin
			var d := net.distance_to_paths(Vector2(o.x, o.z))
			assert_true(d < 0.2, "Çakıl patikadan uzak düşmüş: %s" % o)
			assert_almost(o.y, shape.height_at(o.x, o.z), 0.25, "Çakıl zemine oturmalı")
			if d > -0.3:
				edge += 1
			count += 1
	var expected := _network_length(net) * net.pebbles_per_meter
	assert_true(count > expected * 0.75, "Patika kenarlarına metre başına yeterli çakıl serpilmeli (%d / ~%.0f)" % [count, expected])
	assert_true(edge > count * 0.6, "Çakılların çoğu kenarda olmalı")
	assert_eq(net.pebble_transforms(shape)[0].size(), buckets[0].size(), "Yerleşim belirlenimci olmalı")
	net.free()


func test_world_network_builds_pebble_meshes() -> void:
	var world := await _get_world()
	var net := _network(world)
	if net == null:
		return
	var instances := 0
	for child in net.get_children():
		if child is MultiMeshInstance3D:
			instances += (child as MultiMeshInstance3D).multimesh.instance_count
	assert_true(instances > _network_length(net) * net.pebbles_per_meter * 0.75, "Dünyadaki patika ağı çakılları kurmalı (%d)" % instances)


## Son test: paylaşılan dünyayı serbest bırakır. Ses sunucusu durdurulan sesleri (ateş çıtırtısı)
## kendi iş parçacığında kısa süre sonra bırakır; beklemeden çıkılırsa test süreci kapanırken
## "sızıntı" uyarısı yazılır (bkz. test_world_scene.gd).
func test_world_is_freed_cleanly() -> void:
	if _world == null:
		return
	var world := _world
	_world = null
	world.queue_free()
	await get_tree().create_timer(0.2).timeout
	await wait_frames(2)
	assert_false(is_instance_valid(world), "Dünya silinmeli")


# --- Yardımcılar ------------------------------------------------------------------

func _get_world() -> World:
	if _world == null:
		var packed := load(WORLD_SCENE) as PackedScene
		_world = packed.instantiate() as World
		add_child(_world)
		# Meadow ve RockField kurulumu bir sonraki kareye ertelenir.
		await wait_frames(3)
	return _world


func _network(world: World) -> PathNetwork:
	var net := world.get_node_or_null(^"PathNetwork") as PathNetwork
	assert_not_null(net, "Dünyada PathNetwork düğümü olmalı")
	return net


## Ağdaki tüm yumuşatılmış parçaların toplam uzunluğu (metre).
static func _network_length(net: PathNetwork) -> float:
	var total := 0.0
	for s in net.get_segments():
		total += Vector2(s.x, s.y).distance_to(Vector2(s.z, s.w))
	return total


## Bir patikanın yumuşatılmış parça sayısı (build_segments ile aynı paylaştırma).
func _segment_count_of(net: PathNetwork, path_index: int) -> int:
	var lengths := PackedFloat32Array()
	for path in net.paths:
		lengths.append(PathNetwork.polyline_length(PathNetwork.smooth_polyline(path)))
	return PathNetwork.allocate_segments(lengths, PathNetwork.MAX_SEGMENTS)[path_index]


## Ana sahnedeki ilk Camera3D'nin kaydedilmiş dönüşümü ve görüş açısı ({} = bulunamadı).
## Sahne örneklenmez; yalnızca kayıtlı özellikler okunur (dünya ve arayüz kurulmaz).
static func _main_menu_camera() -> Dictionary:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		return {}
	var state := packed.get_state()
	for i in state.get_node_count():
		if state.get_node_type(i) != &"Camera3D":
			continue
		var result := {"transform": Transform3D.IDENTITY, "fov": 75.0}
		for k in state.get_node_property_count(i):
			var property := state.get_node_property_name(i, k)
			if property == &"transform" or property == &"fov":
				result[String(property)] = state.get_node_property_value(i, k)
		return result
	return {}


## Görüş hattının (eye → focus) bir çamın dal konisine en yakın yatay payı (metre; eksi = dallara giriyor).
## tree: Vector4(x, z, ölçek, tohum) (Forest.camp_trees).
static func _sight_clearance(eye: Vector3, focus: Vector3, tree: Vector4, shape: TerrainShape) -> float:
	var ground := shape.height_at(tree.x, tree.y)
	var best := INF
	for k in 25:
		var q := eye.lerp(focus, float(k) / 24.0)
		var h := (q.y - ground) / tree.z
		if h < 0.8 or h > 10.5:
			continue
		var radius := lerpf(2.8, 0.2, clampf((h - 1.0) / 9.0, 0.0, 1.0)) * tree.z
		best = minf(best, Vector2(q.x, q.z).distance_to(Vector2(tree.x, tree.y)) - radius)
	return best


## Birim taş meshinin kutusunun köşeleri ve tepe noktası (yerel; taban y=0, tepe y=1).
static func _box_corners() -> Array[Vector3]:
	var result: Array[Vector3] = [Vector3(0.0, 1.0, 0.0)]
	for x in [-0.5, 0.5]:
		for y in [0.0, 1.0]:
			for z in [-0.5, 0.5]:
				result.append(Vector3(x, y, z))
	return result
