extends TestCase
## Kaya alanı (RockField) testleri.
##
## Saf kurallar: kahraman kayanın Meshy modeli (büyük kaya / ikili yassı taş), Meshy kayasının taban
## yarıçapı (MeshyProp ile aynı ölçü), serpiştirilmiş kayanın zemine oturması, eğimde en alçak zemin,
## vadi kayalarına işlenen taş ve yosun renkleri.
## Dünya testleri (world.tscn): kahraman kayalar 4. referanstaki yerlerinde (tools/menu_camera_fit.json →
## kaya_R*) Meshy modeliyle kurulur, engel daireleri model kurulmadan önce ve sonra aynıdır, çayırda Meshy
## kayasının hafif sürümü serpiştirilir; modeller kapatılınca prosedürel kayalarla hatasız kurulur.

const WORLD_SCENE := "res://scenes/world/world.tscn"
const CAMERA_FIT := "res://tools/menu_camera_fit.json"
## 4. referanstan ölçülen kaya genişlikleri (metre; menu_camera_fit.json'daki noktalarda).
const REFERENCE_SIZES := {"kaya_R1": 3.2, "kaya_R3": 3.2, "kaya_R7": 2.8, "kaya_R8": 3.8, "kaya_R9": 3.1, "kaya_R10": 4.4, "kaya_R11": 2.1}

var _world: World


# --- Saf kurallar ---------------------------------------------------------------------

func test_hero_model_uses_the_flat_pair_for_small_rocks() -> void:
	assert_eq(RockField.hero_model(0.8), RockField.BOULDER_PAIR, "Küçük kaya ikili yassı taş")
	assert_eq(RockField.hero_model(RockField.PAIR_MAX_SIZE), RockField.BOULDER_PAIR, "Sınırdaki kaya da ikili taş")
	assert_eq(RockField.hero_model(1.6), RockField.BOULDER, "Büyük kaya yuvarlak Meshy kayası")


func test_meshy_footprint_matches_meshy_prop() -> void:
	# boulder_a'nın kutusu gibi: 1,9 × 0,98 × 1,88 birim.
	var box := AABB(Vector3(-0.95, -0.49, -0.94), Vector3(1.9, 0.98, 1.88))
	var s := MeshyProp.fit_scale(box, 2.4, MeshyProp.SizeAxis.LONGEST)
	assert_almost(s, 2.4 / 1.9, 0.0001, "En büyük kenar 2,4 m olmalı")
	assert_almost(RockField.meshy_footprint(box, 2.4), (1.9 + 1.88) * 0.25 * s, 0.0001, "MeshyProp.get_footprint_radius ile aynı")


func test_fallback_basis_fits_the_longest_edge_to_the_rock_size() -> void:
	# Prosedürel yedek kaya (MeshKit.rock ~2–3 birim) da Meshy kayası gibi en büyük kenarıyla boyuna ölçeklenir.
	var box := AABB(Vector3(-1.2, -0.06, -1.0), Vector3(2.4, 1.6, 2.0))
	var basis := RockField.fallback_basis(box, Vector4(3.0, -2.0, 1.8, 90.0))
	var scale := basis.get_scale()
	assert_almost(maxf(scale.x * box.size.x, maxf(scale.y * box.size.y, scale.z * box.size.z)), 1.8, 0.001, "En büyük kenar kayanın boyu olmalı")
	assert_almost(scale.y / scale.x, 1.0, 0.001, "Oran korunmalı")
	assert_vec_almost(basis * Vector3.RIGHT, Vector3(0.0, 0.0, -0.75), 0.001, "Yön derece cinsinden uygulanmalı")


func test_scatter_transform_sits_the_rock_on_the_ground() -> void:
	var box := AABB(Vector3(-0.95, -0.49, -0.94), Vector3(1.9, 0.98, 1.88))
	var shape := _FlatShape.new()
	var xform := RockField.scatter_transform(shape, Vector2(3.0, -2.0), 0.5, 1.2, 0.8, box)
	var bottom := xform * Vector3(box.get_center().x, box.position.y, box.get_center().z)
	assert_vec_almost(bottom, Vector3(3.0, -0.5 * 0.08, -2.0), 0.001, "Taban ortası kayanın yerinde, biraz gömülü")
	var width := xform.basis.x.length() * box.size.x
	assert_almost(width, 0.5 * box.size.x / 1.9, 0.001, "En büyük yatay kenar boyuta eşit")
	assert_almost(xform.basis.y.length() / xform.basis.x.length(), 0.8, 0.001, "Yükseklik basıklık oranında")


func test_footprint_ground_is_the_lowest_point_under_the_rock() -> void:
	var shape := _SlopeShape.new()
	assert_almost(RockField.footprint_ground(shape, Vector2(2.0, 0.0), 1.0), -3.0, 0.001, "Yokuş aşağı uçtaki zemin")
	assert_almost(RockField.footprint_ground(_FlatShape.new(), Vector2(2.0, 0.0), 1.0), 0.0, 0.001, "Düz zemin")


func test_painted_rock_has_moss_on_top_and_stone_on_the_sides() -> void:
	var mesh := RockField.painted_rock(MeshKit.rock(301, 2, 0.35), 41)
	var arrays := mesh.surface_get_arrays(0)
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	assert_eq(colors.size(), normals.size(), "Her köşenin rengi olmalı")
	var top := Vector3.ZERO
	var side := Vector3.ZERO
	var top_n := 0
	var side_n := 0
	for i in colors.size():
		var c := Vector3(colors[i].r, colors[i].g, colors[i].b)
		if normals[i].y > 0.85:
			top += c
			top_n += 1
		elif absf(normals[i].y) < 0.2:
			side += c
			side_n += 1
		assert_eq(colors[i].a, 0.0, "Kayalar sallanmaz (alfa 0)")
	top /= maxf(float(top_n), 1.0)
	side /= maxf(float(side_n), 1.0)
	# Yosun sarı-yeşil (mavisi az), taş gri-bej: tepedeki köşelerin mavi/yeşil oranı yanlardakinden düşük.
	assert_true(top.z / top.y < side.z / side.y, "Tepe yosunlu olmalı (tepe %s, yan %s)" % [top, side])


# --- Dünya ------------------------------------------------------------------------------

func test_hero_rocks_sit_at_the_reference_positions() -> void:
	var fit := JSON.parse_string(FileAccess.get_file_as_string(CAMERA_FIT)) as Dictionary
	assert_not_null(fit, "tools/menu_camera_fit.json okunamadı")
	if fit == null:
		return
	var layout: Dictionary = fit["layout"]
	var field := RockField.new()
	var found := 0
	for key: String in layout:
		if not key.begins_with("kaya_R"):
			continue
		var p := Vector2(layout[key][0], layout[key][1])
		var best := INF
		for r in field.hero_rocks:
			best = minf(best, p.distance_to(Vector2(r.x, r.y)))
		assert_true(best < 0.5, "%s için bir kahraman kaya olmalı (en yakın %.2f m)" % [key, best])
		found += 1
	field.free()
	assert_eq(found, 12, "Referansta 12 kaya noktası var")


func test_hero_rock_sizes_stay_in_range() -> void:
	# Boyutlar 4. referanstan ölçülür (kayanın kadrajdaki genişliği / o noktada metrenin piksel boyu): ön plandaki
	# R1 ve R3 ~3,2 m, kampın arkasındaki çayırdaki R8 ~3,8 m, R10 ~4,4 m'dir (önceki tasarım en fazla 2,6 m idi).
	var field := RockField.new()
	for r in field.hero_rocks:
		assert_between(r.z, 0.8, 4.8, "Kahraman kaya boyu: %s" % r)
	field.free()


func test_back_meadow_boulders_are_as_big_as_in_the_reference() -> void:
	# Referansta kampın arkasındaki kayalar iri granit kubbelerdir; küçük kalırlarsa çayır boş görünür.
	var fit := JSON.parse_string(FileAccess.get_file_as_string(CAMERA_FIT)) as Dictionary
	if fit == null:
		fail("tools/menu_camera_fit.json okunamadı")
		return
	var layout: Dictionary = fit["layout"]
	var field := RockField.new()
	for key: String in REFERENCE_SIZES:
		var p := Vector2(layout[key][0], layout[key][1])
		var size := 0.0
		for r in field.hero_rocks:
			if p.distance_to(Vector2(r.x, r.y)) < 0.5:
				size = r.z
		var expected: float = REFERENCE_SIZES[key]
		assert_almost(size, expected, expected * 0.15, "%s referanstaki boyunda olmalı" % key)
	field.free()


func test_world_hero_rocks_use_the_meshy_boulders() -> void:
	var world := await _get_world()
	var rocks := world.get_node_or_null(^"RockField") as RockField
	assert_not_null(rocks)
	if rocks == null:
		return
	for i in rocks.hero_rocks.size():
		var r := rocks.hero_rocks[i]
		var node := rocks.get_node_or_null(NodePath("HeroRock%d" % i))
		assert_not_null(node, "HeroRock%d kurulmalı" % i)
		if node == null:
			continue
		if MeshyProp.exists(TreeKit.FOLDER, RockField.hero_model(r.z)):
			var prop := node as MeshyProp
			assert_true(prop != null and prop.has_model(), "HeroRock%d bir Meshy kayası olmalı" % i)
			if prop and prop.has_model():
				var box := prop.get_model_aabb()
				assert_almost(maxf(box.size.x, maxf(box.size.y, box.size.z)), r.z, 0.01, "HeroRock%d boyu" % i)
				# Taban yarıçapı engel dairesiyle aynı ölçüdür (kurulumdan önce de doğru).
				assert_almost(rocks.hero_radius(i), prop.get_footprint_radius(), 0.001, "HeroRock%d taban yarıçapı" % i)
				var ground := world.get_terrain_shape().height_at(r.x, r.y)
				assert_true(prop.global_position.y <= ground + 0.001, "HeroRock%d zemine oturmalı" % i)


func test_world_rock_obstacles_cover_heroes_and_formations() -> void:
	var world := await _get_world()
	var rocks := world.get_node_or_null(^"RockField") as RockField
	if rocks == null:
		fail("RockField yok")
		return
	var circles := rocks.get_obstacle_circles()
	var stones := 0
	for i in rocks.formations.size():
		stones += RockField.formation_layout(rocks.formations[i], rocks.formation_seed + i * 101).size()
	assert_eq(circles.size(), rocks.hero_rocks.size() + stones, "Her kahraman kaya ve küme taşı bir engel")
	for i in rocks.hero_rocks.size():
		var r := rocks.hero_rocks[i]
		assert_vec_almost(circles[i], Vector3(r.x, r.y, rocks.hero_radius(i) * RockField.HERO_OBSTACLE_SCALE), 0.0001, "HeroRock%d engeli" % i)
		assert_true(circles[i].z > r.z * 0.25, "Engel kayayı örtecek kadar büyük olmalı")


func test_world_meadow_rocks_are_baked_meshy_boulders() -> void:
	var world := await _get_world()
	var rocks := world.get_node_or_null(^"RockField") as RockField
	if rocks == null:
		fail("RockField yok")
		return
	var small := 0
	for node in rocks.find_children("Rocks*", "MultiMeshInstance3D", false, false):
		var mmi := node as MultiMeshInstance3D
		small += mmi.multimesh.instance_count
		if MeshyProp.exists(TreeKit.FOLDER, RockField.BOULDER):
			var arrays := mmi.multimesh.mesh.surface_get_arrays(0)
			assert_true(arrays[Mesh.ARRAY_COLOR] != null, "Meshy dokusu köşe rengine işlenmiş olmalı")
			var tris := (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
			assert_true(tris <= RockField.SMALL_ROCK_TRIANGLES * 3, "Serpiştirilmiş kaya hafif olmalı (%d üçgen)" % tris)
			var mat := mmi.material_override as ShaderMaterial
			assert_true(mat != null and bool(mat.get_shader_parameter("use_vertex_albedo")), "Köşe rengi kipiyle çizilmeli")
	assert_true(small > 20, "Çayıra kaya serpiştirilmeli (%d)" % small)
	var valley := 0
	for node in rocks.find_children("ValleyRocks*", "MultiMeshInstance3D", false, false):
		assert_true(((node as MultiMeshInstance3D).material_override as ShaderMaterial).get_shader_parameter("use_vertex_albedo"), "Vadi kayaları da köşe rengiyle çizilmeli")
		valley += (node as MultiMeshInstance3D).multimesh.instance_count
		assert_eq((node as MultiMeshInstance3D).cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Vadi kayaları gölge düşürmez")
	assert_true(valley > 300, "Vadiye kaya serpiştirilmeli (%d)" % valley)


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


func test_rock_field_falls_back_to_procedural_rocks_without_models() -> void:
	MeshyProp.models_enabled = false
	var collector := _ErrorLog.new()
	OS.add_logger(collector)
	var field := RockField.new()
	field.valley_rocks = 30
	add_child(field)
	await wait_frames(2)
	var circles := field.get_obstacle_circles()
	OS.remove_logger(collector)
	MeshyProp.models_enabled = true
	for i in field.hero_rocks.size():
		var node := field.get_node_or_null(NodePath("HeroRock%d" % i))
		assert_true(node is MeshInstance3D, "Model yokken HeroRock%d prosedürel kaya olmalı" % i)
		assert_true(circles[i].z > 0.0, "Prosedürel kaya da engel olmalı")
		var mi := node as MeshInstance3D
		if mi and mi.mesh:
			# Yedek kaya da Meshy kayası kadar (en büyük kenarı boyut kadar) olmalı; engel dairesi de buna uyar.
			var size := mi.mesh.get_aabb().size * mi.transform.basis.get_scale()
			var r := field.hero_rocks[i]
			assert_almost(maxf(size.x, maxf(size.y, size.z)), r.z, 0.01, "HeroRock%d yedek kaya boyu" % i)
			assert_between(circles[i].z, r.z * 0.2, r.z * 0.6, "HeroRock%d yedek kaya engeli" % i)
	assert_eq(collector.take(), PackedStringArray(), "Model yokken hata yazılmamalı")
	field.queue_free()
	await wait_frames(1)


# --- Yardımcılar ---------------------------------------------------------------------

func _get_world() -> World:
	if _world == null:
		var packed := load(WORLD_SCENE) as PackedScene
		_world = packed.instantiate() as World
		add_child(_world)
		# RockField, Forest ve Meadow kurulumu bir sonraki kareye ertelenir.
		await wait_frames(3)
	return _world


class _FlatShape extends TerrainShape:
	func height_at(_x: float, _z: float) -> float:
		return 0.0


## x boyunca 1 m'de 1 m alçalan yamaç.
class _SlopeShape extends TerrainShape:
	func height_at(x: float, _z: float) -> float:
		return -x


class _ErrorLog extends Logger:
	var _mutex := Mutex.new()
	var _messages := PackedStringArray()

	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		_mutex.lock()
		_messages.append(rationale if not rationale.is_empty() else code)
		_mutex.unlock()

	func take() -> PackedStringArray:
		_mutex.lock()
		var result := _messages
		_mutex.unlock()
		return result
