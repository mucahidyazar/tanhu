extends TestCase
## Kampın pişmiş parçaları (Yol Haritası world-swap; tools/bake_map.gd, MapBake): arazi, çayır ve orman data/maps/camp/baked/*.res'ten
## kurulur; pişmiş kurulum taze üretimle aynıdır (menü karesi değişmez): aynı düğümler aynı adlarla, aynı ağlar, aynı MultiMesh örnekleri,
## aynı gövde engelleri ve dikilen çamlar. Üretim kodu ya da kampın düzeni değişip araç koşulmadıysa düşer: o zaman
##   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s res://tools/bake_map.gd -- --map=camp
## İmza saf yardımcıları (sıra, nesne süzgeci) ve MultiMesh'in ham dizisinin düzeni de burada sınanır.

const CAMP_SCENE := "res://scenes/world/world.tscn"


func after_each() -> void:
	MapBake.enabled = true
	MapBake.capture = false


func test_signature_is_stable_and_ignores_objects() -> void:
	var a := MapBake.signature_of([1, 2.5, "x", Vector3(1, 2, 3), [Vector4(1, 2, 3, 4)]])
	assert_eq(a, MapBake.signature_of([1, 2.5, "x", Vector3(1, 2, 3), [Vector4(1, 2, 3, 4)]]), "Aynı girdi aynı imza")
	assert_ne(a, MapBake.signature_of([1, 2.5000001, "x", Vector3(1, 2, 3), [Vector4(1, 2, 3, 4)]]), "Kayan sayı bit bit girer")
	assert_eq(a.length(), 32, "MD5")
	var consts := MapBake.script_constants(Forest)
	var names: Array = consts.map(func(pair: Array) -> String: return pair[0])
	var sorted := names.duplicate()
	sorted.sort()
	assert_eq(names, sorted, "Değişmezler adla sıralı (StringName sırası koşudan koşuya değişir)")
	assert_false(names.has("FOLIAGE_SHADER"), "Gölgelendirici (nesne) imzaya girmez")
	var forest := Forest.new()
	var inputs := MapBake.script_inputs(forest)
	assert_false(inputs.any(func(pair: Array) -> bool: return pair[0] == "rebuild_button"), "Araç düğmesi (çağrılabilir) girmez")
	assert_true(inputs.any(func(pair: Array) -> bool: return pair[0] == "camp_trees"), "Dışa açık ayar girer")
	forest.free()


func test_instance_buffer_matches_the_multimesh_layout() -> void:
	var t := Transform3D(Basis(Vector3.UP, 0.3).scaled(Vector3(1.5, 2.0, 1.5)), Vector3(1.0, 2.0, 3.0))
	var buf := MapBake.instance_buffer([t], [Color(0.1, 0.2, 0.3, 0.4)])
	assert_eq(buf.size(), 16, "12 dönüşüm + 4 özel veri")
	assert_almost(buf[3], 1.0, 1e-6, "origin.x satırın sonunda")
	assert_almost(buf[7], 2.0, 1e-6)
	assert_almost(buf[11], 3.0, 1e-6)
	assert_almost(buf[0], t.basis.x.x, 1e-6, "basis.x.x")
	assert_almost(buf[1], t.basis.y.x, 1e-6, "basis.y.x")
	assert_almost(buf[12], 0.1, 1e-6, "özel veri r")
	var back := MapBake.buffer_transform(buf, 0, true)
	assert_true(back.is_equal_approx(t), "Ham diziden aynı dönüşüm")
	var mm := MapBake.multimesh_from(null, buf, true)
	assert_eq(mm.instance_count, 1)
	assert_true(mm.use_custom_data)
	assert_eq(MapBake.instance_buffer([t]).size(), 12, "Özel verisiz 12")


func test_camp_bakes_exist() -> void:
	for kind in ["terrain", "meadow", "forest"]:
		var bake := MapBake.fetch("camp", kind)
		assert_not_null(bake, "data/maps/camp/baked/%s.res" % kind)
		if bake:
			assert_eq(bake.kind, kind)
			assert_eq(bake.map_id, "camp")
			assert_eq(bake.version, MapBake.VERSION)
	var spec := MapSpec.find(MapSpec.CAMP)
	var paths := spec.load_paths()
	assert_true(paths.has(CAMP_SCENE), "Kampın sahnesi önyüklenir")
	assert_true(paths.has("res://assets/structures/yurt/yurt.glb"), "Kurulumun modelleri önyükleme listesinde (preload.json)")
	assert_false(paths.has("res://assets/nature/pine_b/pine_b.glb"), "Pişmiş ormanda çam modeli yüklenmez")


func test_baked_camp_equals_a_fresh_build() -> void:
	# Taze üretim: pişmiş parça kullanılmaz, ham diziler saklanır.
	MapBake.enabled = false
	MapBake.capture = true
	var fresh := await _build_camp()
	MapBake.capture = false
	MapBake.enabled = true
	var fresh_terrain: Terrain = fresh.get_node(^"Terrain")
	var fresh_meadow: Meadow = fresh.get_node(^"Meadow")
	var fresh_forest: Forest = fresh.get_node(^"Forest")
	assert_false(fresh_terrain.used_bake or fresh_meadow.used_bake or fresh_forest.used_bake, "Taze üretim")
	var t_new := fresh_terrain.bake_payload()
	var m_new := fresh_meadow.bake_payload()
	var f_new := fresh_forest.bake_payload()
	var fresh_names := _generated_names(fresh)
	var fresh_trunks := fresh_forest.get_obstacle_circles()
	var fresh_planted := fresh_forest.get_planted_trees()
	remove_child(fresh)
	fresh.free()
	WorldHost.clear_static_caches()
	await wait_frames(1)
	# Pişmiş parçaların imzası taze kurulumun girdileriyle aynı: oyunda kullanılır.
	for pair: Array in [["terrain", t_new], ["meadow", m_new], ["forest", f_new]]:
		var stored := MapBake.fetch("camp", pair[0])
		assert_not_null(stored)
		if stored == null:
			return
		assert_eq(stored.signature, (pair[1] as MapBake).signature, "%s'in imzası tutar (tutmazsa tools/bake_map.gd --map=camp)" % pair[0])
	var baked := await _build_camp()
	for part in ["Terrain", "Meadow", "Forest"]:
		assert_true(bool(baked.get_node(part).get(&"used_bake")), "%s pişmiş haliyle kuruldu" % part)
	var baked_names := _generated_names(baked)
	assert_eq(baked_names.size(), fresh_names.size(), "Aynı sayıda düğüm")
	assert_true(baked_names == fresh_names, "Aynı düğümler aynı adlarla aynı sırada")
	var forest: Forest = baked.get_node(^"Forest")
	assert_eq(forest.get_obstacle_circles(), fresh_trunks, "Aynı gövde engelleri")
	assert_eq(forest.get_planted_trees(), fresh_planted, "Aynı dikilen çamlar")
	# Arazinin ağları: köşeler, normaller ve renkler aynı.
	var stored_t := MapBake.fetch("camp", "terrain")
	assert_eq(stored_t.meshes.size(), t_new.meshes.size(), "Arazi parçalarının sayısı")
	var mesh_diff := 0
	for i in mini(stored_t.meshes.size(), t_new.meshes.size()):
		var a := stored_t.meshes[i].surface_get_arrays(0)
		var b := t_new.meshes[i].surface_get_arrays(0)
		for k in [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_COLOR, Mesh.ARRAY_INDEX]:
			if a[k] != b[k]:
				mesh_diff += 1
	assert_eq(mesh_diff, 0, "Arazinin ağları taze üretimle aynı")
	# Çayırın ve vadinin örnekleri bit bit aynı.
	var stored_m := MapBake.fetch("camp", "meadow")
	for key in ["grass", "flowers"]:
		assert_eq(_entries_key(stored_m.data[key]), _entries_key(m_new.data[key]), "Çayırın %s kareleri aynı" % key)
		assert_true(_entries_equal(stored_m.data[key], m_new.data[key]), "Çayırın %s örnekleri aynı" % key)
	var stored_f := MapBake.fetch("camp", "forest")
	assert_true(_entries_equal(stored_f.data["valley"], f_new.data["valley"]), "Vadinin örnekleri aynı")
	assert_eq(stored_f.data["valley_trunks"], f_new.data["valley_trunks"])
	assert_eq(stored_f.meshes.size(), f_new.meshes.size(), "Ormanın ağ sayısı")
	var forest_diff := 0
	for i in mini(stored_f.meshes.size(), f_new.meshes.size()):
		if stored_f.meshes[i].surface_get_arrays(0)[Mesh.ARRAY_VERTEX] != f_new.meshes[i].surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			forest_diff += 1
	assert_eq(forest_diff, 0, "Ladinler ve çamın LOD zinciri aynı")
	remove_child(baked)
	baked.free()
	WorldHost.clear_static_caches()
	await get_tree().create_timer(0.3).timeout


# --- Yardımcılar -------------------------------------------------------------------------------------

func _build_camp() -> World:
	var world := (load(CAMP_SCENE) as PackedScene).instantiate() as World
	add_child(world)
	var deadline := Time.get_ticks_msec() + 30000
	await wait_frames(1)
	while not world.is_built() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	return world


## Arazinin, çayırın ve ormanın ürettiği düğümlerin adları (sırayla; motorun kendiliğinden verdiği "@" adları sayaçtandır, girmez).
static func _generated_names(world: World) -> PackedStringArray:
	var out := PackedStringArray()
	for part in ["Terrain/Chunks", "Meadow", "Forest", "Forest/Pines"]:
		var node := world.get_node_or_null(NodePath(part))
		if node:
			for child in node.get_children():
				if not str(child.name).begins_with("@"):
					out.append("%s/%s" % [part, child.name])
	return out


static func _entries_key(entries: Array) -> Array:
	return entries.map(func(e: Array) -> Vector3i: return e[0])


static func _entries_equal(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for i in a.size():
		if a[i][0] != b[i][0] or a[i][1] != b[i][1]:
			return false
	return true
