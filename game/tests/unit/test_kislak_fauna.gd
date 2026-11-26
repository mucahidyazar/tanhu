extends TestCase
## Kışlak'ın dört ayaklıları (E19; tools/blender/quadruped_rig.py ve tools/blender/quadruped_<tür>.json): deve (yol denemesi) ile köpek,
## maral, kurt, ceylan ve sığır. İskelet, beş klip, boy ve yön, doku sınıfı, üçgen sınırı, yürüyüş tablosu (fauna.md §10), basan ayağın
## yerin üstünde kalması ve uzak sürü ağı. Dosyalar henüz yoksa testler atlar. Toynağın zemin ve kayma ölçüsü
## tools/blender/quadruped_measure.gd'dedir (kabul: gömülme ve kayma ≤ 2 cm); burada kaba bir bekçi vardır.

const IDS := ["camel", "dog", "deer", "wolf", "gazelle", "cattle"]
const CLIPS := ["idle", "graze", "walk", "trot", "gallop"]
const LEGS := ["FrontL", "FrontR", "HindL", "HindR"]
const PARTS := ["Upper", "Lower", "Cannon", "Hoof"]
## Tür başına beklenen: omuz (meta shoulder_m; devede hörgüç tepesi) aralığı, tırısın ve dörtnalın biçimi (fauna.md §10 yürüyüş tablosu).
const SPEC := {
	"camel": {"shoulder": [2.2, 2.4], "trot": "pace", "gallop": "transverse"},
	"dog": {"shoulder": [0.62, 0.74], "trot": "diagonal", "gallop": "rotary"},
	"deer": {"shoulder": [1.3, 1.5], "trot": "diagonal", "gallop": "rotary"},
	"wolf": {"shoulder": [0.78, 0.92], "trot": "diagonal", "gallop": "rotary"},
	"gazelle": {"shoulder": [0.68, 0.8], "trot": "diagonal", "gallop": "rotary"},
	"cattle": {"shoulder": [1.25, 1.45], "trot": "diagonal", "gallop": "transverse"},
}
## Binilen ve büyük hayvanın LOD0 sınırı (godot.md §6.4) ve uzak ağın T1 sınırı.
const MAX_TRIANGLES := 20000
const FAR_MAX_TRIANGLES := 1800


func _path(id: String, ext: String) -> String:
	return "res://assets/animals/%s/%s.%s" % [id, id, ext]


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


func _meta(id: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(_path(id, "json")))


func _triangles(mesh: Mesh) -> int:
	var total := 0
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		total += indices.size() / 3 if not indices.is_empty() else vertices.size() / 3
	return total


func test_skeleton_has_body_head_tail_and_legs() -> void:
	for id: String in IDS:
		if _skip(_path(id, "glb")):
			continue
		var scene := _load(_path(id, "glb"))
		var skeleton := _find(scene, "Skeleton3D") as Skeleton3D
		assert_not_null(skeleton, "%s: Skeleton3D olmalı" % id)
		if skeleton == null:
			scene.queue_free()
			continue
		# K65: binek ≈30 deforme kemik (kök sayılmaz); öteki T0 aynı plandan.
		assert_between(skeleton.get_bone_count(), 29, 32, "%s: ≈30 kemik" % id)
		for bone in ["Root", "Hips", "Spine", "Chest", "Belly", "Neck1", "Neck2", "Neck3", "Head", "EarL", "EarR", "Tail1"]:
			assert_true(skeleton.find_bone(bone) >= 0, "%s: %s kemiği" % [id, bone])
		for leg in LEGS:
			for part in PARTS:
				assert_true(skeleton.find_bone(_bone(leg, part)) >= 0, "%s: %s kemiği" % [id, _bone(leg, part)])
		scene.queue_free()


func test_clips_exist_and_loop() -> void:
	for id: String in IDS:
		if _skip(_path(id, "glb")):
			continue
		var scene := _load(_path(id, "glb"))
		var player := _find(scene, "AnimationPlayer") as AnimationPlayer
		assert_not_null(player, "%s: AnimationPlayer olmalı" % id)
		if player == null:
			scene.queue_free()
			continue
		for clip: String in CLIPS:
			assert_true(player.has_animation(clip), "%s: %s klibi" % [id, clip])
			if not player.has_animation(clip):
				continue
			var anim := player.get_animation(clip)
			assert_eq(anim.loop_mode, Animation.LOOP_LINEAR, "%s: %s döngülü" % [id, clip])
			assert_true(anim.get_track_count() >= 20, "%s: %s kemik izleri" % [id, clip])
			assert_true(anim.length > 0.15, "%s: %s boyu" % [id, clip])
		scene.queue_free()


func test_size_direction_texture_and_triangles() -> void:
	for id: String in IDS:
		if _skip(_path(id, "glb")) or _skip(_path(id, "json")):
			continue
		var meta := _meta(id)
		var scene := _load(_path(id, "glb"))
		var skeleton := _find(scene, "Skeleton3D") as Skeleton3D
		var mesh := _find(scene, "MeshInstance3D") as MeshInstance3D
		var box := mesh.mesh.get_aabb()
		assert_almost(box.position.y, 0.0, 0.003, "%s: ayaklar y = 0'da" % id)
		assert_almost(box.size.z, float(meta["length_m"]), 0.01, "%s: burundan kuyruğa boy meta ile aynı" % id)
		var spec: Dictionary = SPEC[id]
		assert_between(float(meta["shoulder_m"]), float(spec["shoulder"][0]), float(spec["shoulder"][1]), "%s: omuz (fauna.md §10)" % id)
		var rest := func(bone: String) -> Vector3: return skeleton.get_bone_global_rest(skeleton.find_bone(bone)).origin
		assert_true((rest.call("Head") as Vector3).z > (rest.call("Chest") as Vector3).z, "%s: baş +Z'de" % id)
		assert_true((rest.call("Tail1") as Vector3).z < (rest.call("Hips") as Vector3).z + 0.05, "%s: kuyruk -Z'de" % id)
		assert_true((rest.call("FrontUpperL") as Vector3).x > 0.0 and (rest.call("FrontUpperR") as Vector3).x < 0.0, "%s: +X hayvanın solu" % id)
		var head_dir: Array = meta["head_dir"]
		assert_true(float(head_dir[2]) > 0.6, "%s: baş ileri bakar (ham ağın dönük başı burguyla düzeldi)" % id)
		var texture := (mesh.get_active_material(0) as BaseMaterial3D).albedo_texture
		assert_true(texture.get_width() <= 1024, "%s: doku mount sınıfında (8K oyuna taşınmaz)" % id)
		assert_true(_triangles(mesh.mesh) <= MAX_TRIANGLES, "%s: LOD0 ≤20k üçgen" % id)
		scene.queue_free()


func test_gaits_follow_the_walking_table() -> void:
	for id: String in IDS:
		if _skip(_path(id, "json")):
			continue
		var clips: Dictionary = _meta(id)["clips"]
		var walk: Dictionary = clips["walk"]
		var trot: Dictionary = clips["trot"]
		var gallop: Dictionary = clips["gallop"]
		assert_true(float(walk["speed_mps"]) < float(trot["speed_mps"]) and float(trot["speed_mps"]) < float(gallop["speed_mps"]), "%s: adım < tırıs < dörtnal" % id)
		for row: Dictionary in [walk, trot, gallop]:
			assert_almost(float(row["length_s"]), float(row["stride_m"]) / float(row["speed_mps"]), 0.001, "%s: f = v / L" % id)
		# Yürüme dört vuruş: sol arka, sol ön, sağ arka, sağ ön (fauna.md §10).
		assert_eq(walk["phases"], {"HindL": 0.0, "FrontL": 0.25, "HindR": 0.5, "FrontR": 0.75}, "%s: adımın vuruş sırası" % id)
		var t: Dictionary = trot["phases"]
		if str(SPEC[id]["trot"]) == "pace":
			assert_almost(float(t["HindL"]), float(t["FrontL"]), 0.0001, "%s: yan yürüyüş, aynı yan birlikte" % id)
			assert_almost(float(t["HindR"]), float(t["FrontR"]), 0.0001, "%s: yan yürüyüş, aynı yan birlikte" % id)
		else:
			assert_almost(float(t["HindL"]), float(t["FrontR"]), 0.0001, "%s: tırısta çapraz çift" % id)
			assert_almost(float(t["HindR"]), float(t["FrontL"]), 0.0001, "%s: tırısta çapraz çift" % id)
		var p: Dictionary = gallop["phases"]
		assert_true(float(p["HindL"]) < float(p["HindR"]), "%s: dörtnalda arka bacaklar önce" % id)
		if str(SPEC[id]["gallop"]) == "transverse":
			assert_true(float(p["HindR"]) < float(p["FrontL"]) and float(p["FrontL"]) < float(p["FrontR"]), "%s: çapraz dörtnalın vuruş sırası" % id)
		else:
			assert_true(float(p["HindR"]) < float(p["FrontR"]) and float(p["FrontR"]) < float(p["FrontL"]), "%s: dönen dörtnalın vuruş sırası" % id)
		assert_true(float(gallop["duty"]) < 0.3, "%s: dörtnalda havada kalış var" % id)


func test_feet_stay_above_ground() -> void:
	for id: String in IDS:
		if _skip(_path(id, "glb")):
			continue
		var scene := _load(_path(id, "glb"))
		var skeleton := _find(scene, "Skeleton3D") as Skeleton3D
		var player := _find(scene, "AnimationPlayer") as AnimationPlayer
		for clip in ["idle", "walk", "trot", "gallop"]:
			player.play(clip)
			var length := player.get_animation(clip).length
			for leg: String in LEGS:
				var hoof := skeleton.find_bone(_bone(leg, "Hoof"))
				var rest_y := skeleton.get_bone_global_rest(hoof).origin.y
				var lowest := INF
				for k in 24:
					player.seek(length * k / 24.0, true)
					lowest = minf(lowest, skeleton.get_bone_global_pose(hoof).origin.y)
				# Topuk (bilek) dinlenmedeki yüksekliğinin altına inmez: basan ayak yere girmez.
				assert_true(lowest > rest_y * 0.8, "%s: %s %s bileği yerin üstünde (%.3f, dinlenme %.3f)" % [id, clip, leg, lowest, rest_y])
		scene.queue_free()


func test_far_mesh_for_multimesh() -> void:
	for id: String in IDS:
		if _skip(_path(id, "glb")):
			continue
		var far_path := "res://assets/animals/%s/%s_far.glb" % [id, id]
		if _skip(far_path):
			continue
		var scene := _load(far_path)
		assert_null(_find(scene, "Skeleton3D"), "%s: uzak ağ iskeletsiz" % id)
		var far_mesh := _find(scene, "MeshInstance3D") as MeshInstance3D
		assert_eq(far_mesh.mesh.get_surface_count(), 1, "%s: tek yüzey (tek MultiMesh çizimi)" % id)
		assert_between(_triangles(far_mesh.mesh), 600, FAR_MAX_TRIANGLES, "%s: uzak ağ T1 sınırında" % id)
		var full := _load(_path(id, "glb"))
		var full_mesh := _find(full, "MeshInstance3D") as MeshInstance3D
		assert_vec_almost(far_mesh.mesh.get_aabb().size, full_mesh.mesh.get_aabb().size, 0.01, "%s: aynı boy" % id)
		var near_texture := (full_mesh.get_active_material(0) as BaseMaterial3D).albedo_texture
		var far_texture := (far_mesh.get_active_material(0) as BaseMaterial3D).albedo_texture
		assert_eq(far_texture.resource_path, near_texture.resource_path, "%s: aynı doku dosyası" % id)
		full.queue_free()
		scene.queue_free()
