extends TestCase
## Koyun varlığı (tools/blender/quadruped_rig.py): iskelet, dört klip, boy, yön, uzak sürü ağı ve binek ölçüleri. Dosyalar henüz yoksa testler atlar.
## Toynağın zemin ölçümü tools/blender/quadruped_measure.gd'dedir; burada yalnız kaba bir bekçi vardır.

const DIR := "res://assets/animals/sheep/"
const FULL := DIR + "sheep.glb"
const FAR := DIR + "sheep_far.glb"
const META := DIR + "sheep.json"
const CLIPS := ["idle", "walk", "run", "graze"]
const LEGS := ["FrontL", "FrontR", "HindL", "HindR"]
const PARTS := ["Upper", "Lower", "Cannon", "Hoof"]


func _skip(path: String) -> bool:
	if ResourceLoader.exists(path) or FileAccess.file_exists(path):
		return false
	print("    atlandı: %s yok" % path)
	return true


func _load(path: String) -> Node:
	var scene := (load(path) as PackedScene).instantiate()
	add_child(scene)
	return scene


func _find(node: Node, type_name: String) -> Node:
	if node.is_class(type_name):
		return node
	for child in node.get_children():
		var hit := _find(child, type_name)
		if hit:
			return hit
	return null


func _bone(leg: String, part: String) -> String:
	return leg.substr(0, leg.length() - 1) + part + leg.substr(leg.length() - 1)


func test_full_model_has_skeleton_and_bones() -> void:
	if _skip(FULL):
		return
	var scene := _load(FULL)
	var skeleton := _find(scene, "Skeleton3D") as Skeleton3D
	assert_not_null(skeleton, "Skeleton3D olmalı")
	assert_between(skeleton.get_bone_count(), 20, 31, "≈20-30 deforme kemik")
	for bone in ["Hips", "Spine", "Chest", "Neck1", "Head", "Tail1", "EarL", "EarR"]:
		assert_true(skeleton.find_bone(bone) >= 0, "%s kemiği" % bone)
	for leg in LEGS:
		for part in PARTS:
			assert_true(skeleton.find_bone(_bone(leg, part)) >= 0, "%s kemiği" % _bone(leg, part))
	scene.queue_free()


func test_clips_exist_and_loop() -> void:
	if _skip(FULL):
		return
	var scene := _load(FULL)
	var player := _find(scene, "AnimationPlayer") as AnimationPlayer
	assert_not_null(player, "AnimationPlayer olmalı")
	for clip in CLIPS:
		assert_true(player.has_animation(clip), "%s klibi" % clip)
		var anim := player.get_animation(clip)
		assert_eq(anim.loop_mode, Animation.LOOP_LINEAR, "%s döngülü" % clip)
		assert_true(anim.get_track_count() >= 20, "%s kemik izleri" % clip)
		assert_true(anim.length > 0.2, "%s boyu" % clip)
	scene.queue_free()


func test_size_direction_and_ground() -> void:
	if _skip(FULL):
		return
	var scene := _load(FULL)
	var skeleton := _find(scene, "Skeleton3D") as Skeleton3D
	var mesh := _find(scene, "MeshInstance3D") as MeshInstance3D
	var box := mesh.mesh.get_aabb()
	assert_almost(box.position.y, 0.0, 0.002, "Ayaklar y = 0'da")
	assert_between(box.size.z, 1.15, 1.35, "Burundan kuyruğa ≈1,25 m")
	assert_between(box.size.y, 0.85, 1.05, "Başın tepesi")
	# +Z ileri: baş önde, kuyruk arkada, sağ-sol ayaklar kendi yanında.
	var rest := func(bone: String) -> Vector3: return skeleton.get_bone_global_rest(skeleton.find_bone(bone)).origin
	assert_true(rest.call("Head").z > 0.2, "Baş +Z'de")
	assert_true(rest.call("Tail1").z < -0.2, "Kuyruk -Z'de")
	assert_true(rest.call("FrontUpperL").x > 0.0 and rest.call("FrontUpperR").x < 0.0, "+X hayvanın solu")
	var texture := (mesh.get_active_material(0) as BaseMaterial3D).albedo_texture
	assert_true(texture.get_width() <= 1024, "Doku mount sınıfında (8K oyuna taşınmaz)")
	scene.queue_free()


func test_hooves_stay_above_ground_in_walk() -> void:
	if _skip(FULL):
		return
	var scene := _load(FULL)
	var skeleton := _find(scene, "Skeleton3D") as Skeleton3D
	var player := _find(scene, "AnimationPlayer") as AnimationPlayer
	player.play("walk")
	var length := player.get_animation("walk").length
	for k in 24:
		player.seek(length * k / 24.0, true)
		for leg in LEGS:
			var hoof := skeleton.find_bone(_bone(leg, "Hoof"))
			# Bilek dinlenmede ≈7 cm'de; altına inerse toynak yere girer.
			assert_true(skeleton.get_bone_global_pose(hoof).origin.y > 0.055, "%s bileği yerin üstünde (kare %d)" % [leg, k])
	scene.queue_free()


func test_far_mesh_for_multimesh() -> void:
	if _skip(FAR):
		return
	var scene := _load(FAR)
	assert_null(_find(scene, "Skeleton3D"), "Uzak ağ iskeletsiz")
	var mesh_node := _find(scene, "MeshInstance3D") as MeshInstance3D
	assert_not_null(mesh_node)
	var mesh := mesh_node.mesh
	assert_eq(mesh.get_surface_count(), 1, "Tek yüzey: tek MultiMesh çizimi")
	var arrays := mesh.surface_get_arrays(0)
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var triangles := indices.size() / 3 if not indices.is_empty() else vertices.size() / 3
	assert_between(triangles, 800, 1500, "Uzak ağ üçgeni")
	assert_almost(mesh.get_aabb().position.y, 0.0, 0.002, "Ayaklar y = 0'da")
	if not _skip(FULL):
		var full := _load(FULL)
		var full_mesh := _find(full, "MeshInstance3D") as MeshInstance3D
		var a := mesh.get_aabb()
		var b := full_mesh.mesh.get_aabb()
		assert_vec_almost(a.size, b.size, 0.01, "Aynı boy")
		var near_texture := (full_mesh.get_active_material(0) as BaseMaterial3D).albedo_texture
		var far_texture := (mesh_node.get_active_material(0) as BaseMaterial3D).albedo_texture
		assert_eq(far_texture.resource_path, near_texture.resource_path, "Aynı doku dosyası")
		full.queue_free()
	scene.queue_free()


func test_meta_has_saddle_and_clip_speeds() -> void:
	if _skip(META):
		return
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(META))
	for key in ["saddle_y", "saddle_z", "length_m", "shoulder_m"]:
		assert_true(meta.has(key), "%s yazılı" % key)
	assert_between(float(meta["shoulder_m"]), 0.7, 0.8, "Omuz ≈0,75 m")
	assert_between(float(meta["length_m"]), 1.15, 1.35, "Boy ≈1,25 m")
	assert_between(float(meta["saddle_y"]), 0.6, 0.85, "Sırt yüksekliği")
	assert_between(float(meta["saddle_z"]), -0.2, 0.25, "Sırt noktası gövdede")
	var head: Array = meta["head_dir"]
	assert_true(float(head[2]) > 0.8, "Baş +Z'ye bakar")
	var kinds: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/fauna/kinds.json"))["kinds"]
	var sheep: Dictionary = kinds["sheep"]
	# Klipler fauna.md §10'un yürüyüş tablosuna bağlı: f = v / L.
	assert_almost(float(meta["clips"]["walk"]["stride_m"]), float(sheep["stride"]["walk"]), 0.001, "Yürüme adım boyu")
	assert_almost(float(meta["clips"]["run"]["stride_m"]), float(sheep["stride"]["trot"]), 0.001, "Tırıs adım boyu")
