extends TestCase
## Kampın iki atı (tools/blender/quadruped_rig.py, tarif quadruped_horse.json; 2026-11-07): iskelet (bacak başına dört, beş kuyruk, üç yele kemiği), beş döngülü klip
## (idle, graze, walk, trot, gallop), boy (burundan kuyruğa 2,3 m), yön, eyerin yeri, kliplerin adım boyu ve faz tablosu. Dosyalar henüz yoksa testler atlar.
## Toynağın zemin ölçümü tools/blender/quadruped_measure.gd'dedir; burada yalnız kaba bir bekçi vardır. Ham dosyalar (assets/_meshy_raw/horse_*) korunur.

const IDS := ["horse_brown", "horse_white"]
const CLIPS := ["idle", "graze", "walk", "trot", "gallop"]
const LEGS := ["FrontL", "FrontR", "HindL", "HindR"]
const PARTS := ["Upper", "Lower", "Cannon", "Hoof"]


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


func test_skeleton_has_legs_tail_and_mane() -> void:
	for id in IDS:
		if _skip(_path(id, "glb")):
			continue
		var scene := _load(_path(id, "glb"))
		var skeleton := _find(scene, "Skeleton3D") as Skeleton3D
		assert_not_null(skeleton, "%s: Skeleton3D" % id)
		assert_between(skeleton.get_bone_count(), 30, 40, "%s: binek ≈30 deforme kemik (fauna.md §10)" % id)
		for bone in ["Hips", "Spine", "Chest", "Neck1", "Neck3", "Head", "EarL", "EarR", "Tail1", "Tail5", "Mane1", "Mane3"]:
			assert_true(skeleton.find_bone(bone) >= 0, "%s: %s kemiği" % [id, bone])
		for leg in LEGS:
			for part in PARTS:
				assert_true(skeleton.find_bone(_bone(leg, part)) >= 0, "%s: %s kemiği" % [id, _bone(leg, part)])
		scene.queue_free()


func test_clips_exist_and_loop() -> void:
	for id in IDS:
		if _skip(_path(id, "glb")):
			continue
		var scene := _load(_path(id, "glb"))
		var player := _find(scene, "AnimationPlayer") as AnimationPlayer
		assert_not_null(player, "%s: AnimationPlayer" % id)
		for clip in CLIPS:
			assert_true(player.has_animation(clip), "%s: %s klibi" % [id, clip])
			var anim := player.get_animation(clip)
			assert_eq(anim.loop_mode, Animation.LOOP_LINEAR, "%s: %s döngülü" % [id, clip])
			assert_true(anim.get_track_count() >= 30, "%s: %s kemik izleri" % [id, clip])
		scene.queue_free()


func test_size_direction_and_saddle() -> void:
	for id in IDS:
		if _skip(_path(id, "glb")) or _skip(_path(id, "json")):
			continue
		var scene := _load(_path(id, "glb"))
		var skeleton := _find(scene, "Skeleton3D") as Skeleton3D
		var mesh := _find(scene, "MeshInstance3D") as MeshInstance3D
		var box := mesh.mesh.get_aabb()
		assert_almost(box.position.y, 0.0, 0.003, "%s: toynaklar y = 0'da" % id)
		assert_almost(box.size.z, Horse.MODEL_LENGTH, 0.01, "%s: burundan kuyruğa 2,3 m (eski boyu)" % id)
		assert_between(box.size.y, 1.6, 1.9, "%s: kulak ucu" % id)
		var rest := func(bone: String) -> Vector3: return skeleton.get_bone_global_rest(skeleton.find_bone(bone)).origin
		assert_true(rest.call("Head").z > 0.6, "%s: baş +Z'de" % id)
		assert_true(rest.call("Tail1").z < -0.5, "%s: kuyruk -Z'de" % id)
		assert_true(rest.call("Tail5").y < 0.5, "%s: kuyruk kılın boyunca aşağı iner" % id)
		assert_true(rest.call("FrontUpperL").x > 0.0 and rest.call("FrontUpperR").x < 0.0, "%s: +X hayvanın solu" % id)
		var texture := (mesh.get_active_material(0) as BaseMaterial3D).albedo_texture
		assert_true(texture.get_width() <= 1024, "%s: doku mount sınıfında (8K oyuna taşınmaz)" % id)
		var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_path(id, "json")))
		assert_between(float(meta["saddle_y"]), 1.2, 1.45, "%s: eyerin oturma yüzü" % id)
		assert_between(float(meta["saddle_z"]), -0.2, 0.15, "%s: eyer gövdenin ortasında" % id)
		assert_eq(str(meta["saddle_bone"]), "Spine")
		assert_eq(meta["tail_bones"].size(), 5, "%s: beş kuyruk kemiği" % id)
		assert_eq(meta["mane_bones"].size(), 3, "%s: üç yele kemiği" % id)
		scene.queue_free()


func test_gaits_follow_the_walking_table() -> void:
	for id in IDS:
		if _skip(_path(id, "json")):
			continue
		var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(_path(id, "json")))
		var clips: Dictionary = meta["clips"]
		var walk: Dictionary = clips["walk"]
		var trot: Dictionary = clips["trot"]
		var gallop: Dictionary = clips["gallop"]
		assert_true(float(walk["speed_mps"]) < float(trot["speed_mps"]) and float(trot["speed_mps"]) < float(gallop["speed_mps"]), "%s: adım < tırıs < dörtnal" % id)
		for row: Dictionary in [walk, trot, gallop]:
			assert_almost(float(row["length_s"]), float(row["stride_m"]) / float(row["speed_mps"]), 0.001, "%s: f = v / L" % id)
		# Yürüyüşlerin vuruş sırası (fauna.md §10): adım dört vuruş, tırıs çapraz çift, dörtnal arka-arka-ön-ön.
		assert_eq(walk["phases"], {"HindL": 0.0, "FrontL": 0.25, "HindR": 0.5, "FrontR": 0.75})
		assert_almost(float(trot["phases"]["HindL"]), float(trot["phases"]["FrontR"]), 0.0001, "%s: tırısta çapraz çift" % id)
		var p: Dictionary = gallop["phases"]
		assert_true(float(p["HindL"]) < float(p["HindR"]) and float(p["HindR"]) < float(p["FrontL"]) and float(p["FrontL"]) < float(p["FrontR"]), "%s: dörtnalın vuruş sırası" % id)
		assert_true(float(gallop["duty"]) < 0.3, "%s: dörtnalda havada kalış var" % id)
		# Satırın adım boyları kliplerinki.
		var stride: Dictionary = Mount.row_of("horse")["stride"]
		for clip in ["walk", "trot", "gallop"]:
			assert_almost(float(stride[clip]), float(clips[clip]["stride_m"]), 0.001, "%s: %s adım boyu" % [id, clip])


func test_hooves_stay_above_ground() -> void:
	for id in IDS:
		if _skip(_path(id, "glb")):
			continue
		var scene := _load(_path(id, "glb"))
		var skeleton := _find(scene, "Skeleton3D") as Skeleton3D
		var player := _find(scene, "AnimationPlayer") as AnimationPlayer
		for clip in ["walk", "trot", "gallop"]:
			player.play(clip)
			var length := player.get_animation(clip).length
			var lowest := INF
			for k in 24:
				player.seek(length * k / 24.0, true)
				for leg in LEGS:
					lowest = minf(lowest, skeleton.get_bone_global_pose(skeleton.find_bone(_bone(leg, "Hoof"))).origin.y)
			# Bilek (fetlock) dinlenmede ≈15 cm'de; basışta çok az iner, altına inerse toynak yere girer.
			assert_true(lowest > 0.1, "%s: %s bilekleri yerin üstünde (%.3f)" % [id, clip, lowest])
		scene.queue_free()
