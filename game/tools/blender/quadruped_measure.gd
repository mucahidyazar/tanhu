extends SceneTree
## Dört ayaklı varlığın Godot'daki ölçümü (başsız): GLB'yi içe aktarılmış haliyle yükler, Skeleton3D ve AnimationPlayer'ı, klip adlarını ve döngüyü denetler,
## her klipte toynak köşelerini kemik pozlarından deriyle hesaplar: gömülme (en alt köşe y < 0) ve basan toynağın kayması. Yürüyen klipte basan toynak
## modele göre klip hızıyla geri gider (yerinde döngü), oyunda hayvan aynı hızla ilerler: kayma = |z + v·t| ve |x| değişimi.
##
##   Godot --headless --path . -s res://tools/blender/quadruped_measure.gd -- --id=sheep [--rate=120] [--full]
## --full bütün köşelerin en alt yerini de arar (yavaş): yere giren yün, kuyruk, burun. Çıkış kodu: kabul sınırı aşılırsa 1.

const SINK_LIMIT := 0.02
const SLIP_LIMIT := 0.02
const SEAM_LIMIT := 0.001
const LEGS := ["FrontL", "FrontR", "HindL", "HindR"]

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var id := "sheep"
	var rate := 120.0
	var full := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--id="):
			id = arg.substr(5)
		elif arg.begins_with("--rate="):
			rate = float(arg.substr(7))
		elif arg == "--full":
			full = true
	var dir := "res://assets/animals/%s/" % id
	var packed := load(dir + id + ".glb") as PackedScene
	if packed == null:
		printerr("GLB yüklenemedi: ", dir + id + ".glb")
		quit(1)
		return
	var meta: Dictionary = {}
	if FileAccess.file_exists(dir + id + ".json"):
		meta = JSON.parse_string(FileAccess.get_file_as_string(dir + id + ".json"))
	var scene := packed.instantiate()
	root.add_child(scene)
	var skeleton := _find(scene, "Skeleton3D") as Skeleton3D
	var player := _find(scene, "AnimationPlayer") as AnimationPlayer
	var mesh_node := _find(scene, "MeshInstance3D") as MeshInstance3D
	print("Skeleton3D: %s, %d kemik; AnimationPlayer: %s; klipler: %s" % [skeleton != null, skeleton.get_bone_count() if skeleton else 0, player != null, player.get_animation_list() if player else []])
	if skeleton == null or player == null or mesh_node == null:
		quit(1)
		return
	var arrays := mesh_node.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var per_vertex := bones.size() / vertices.size()
	var box := mesh_node.mesh.get_aabb()
	print("Ağ: %d köşe, %d üçgen, köşe başına %d etki; dinlenme kutusu %s" % [vertices.size(), indices.size() / 3, per_vertex, box])
	var skin := mesh_node.skin
	var bind_bone := PackedInt32Array()
	bind_bone.resize(skin.get_bind_count())
	for i in skin.get_bind_count():
		bind_bone[i] = skeleton.find_bone(skin.get_bind_name(i))
	# Toynak köşeleri ve uç köşesi.
	var feet := {}
	for leg in LEGS:
		var hoof_name: String = leg.substr(0, leg.length() - 1) + "Hoof" + leg.substr(leg.length() - 1)
		var hoof := -1
		for i in skin.get_bind_count():
			if skin.get_bind_name(i) == hoof_name:
				hoof = i
		var ids := PackedInt32Array()
		var tip := -1
		for v in vertices.size():
			var best := 0.0
			for k in per_vertex:
				if bones[v * per_vertex + k] == hoof:
					best = weights[v * per_vertex + k]
			if best > 0.9:
				ids.append(v)
				if tip < 0 or (vertices[v].y < 0.02 and vertices[v].z > vertices[tip].z):
					tip = v
		feet[leg] = {"ids": ids, "tip": tip}
		print("  %s: %d toynak köşesi, uç %s" % [leg, ids.size(), vertices[tip]])
	for clip_name in player.get_animation_list():
		var anim := player.get_animation(clip_name)
		var row: Dictionary = (meta.get("clips", {}) as Dictionary).get(clip_name, {})
		var speed := float(row.get("speed_mps", 0.0))
		player.play(clip_name)
		var frames := int(ceil(anim.length * rate))
		var sink := 0.0
		for f in frames + 1:
			player.seek(anim.length * f / float(frames), true)
			var pose := _pose_matrices(skeleton, skin, bind_bone)
			for leg in LEGS:
				for v in feet[leg]["ids"]:
					sink = maxf(sink, -_skinned(vertices[v], v, per_vertex, bones, weights, pose).y)
		# Kayma: faz tablosu varsa her toynağın duruş yayında (basıştan kalkışa), yoksa bütün klipte. Dünya konumu: uç köşesi + hız × süre.
		var phases: Dictionary = row.get("phases", {})
		var duty := float(row.get("duty", 1.0))
		var slip := 0.0
		var slip_leg := ""
		for leg in LEGS:
			var start := float(phases.get(leg, 0.0))
			var low := Vector3.INF
			var high := -Vector3.INF
			var samples := maxi(int(anim.length * duty * rate), 2)
			for k in samples + 1:
				var unwrapped := (start + duty * k / float(samples)) * anim.length
				player.seek(fmod(unwrapped, anim.length), true)
				var pose := _pose_matrices(skeleton, skin, bind_bone)
				var tip: int = feet[leg]["tip"]
				var world := _skinned(vertices[tip], tip, per_vertex, bones, weights, pose) + Vector3(0.0, 0.0, speed * unwrapped)
				low = low.min(world)
				high = high.max(world)
			var spread := high - low
			var slide := maxf(spread.x, spread.z)
			if slide > slip:
				slip = slide
				slip_leg = leg
		# Döngü dikişi: ilk ve son karede kemik konumları aynı olmalı.
		player.seek(0.0, true)
		var first := _bone_origins(skeleton)
		player.seek(anim.length, true)
		var last := _bone_origins(skeleton)
		var seam := 0.0
		for b in first.size():
			seam = maxf(seam, first[b].distance_to(last[b]))
		var verdict := "tamam"
		if sink > SINK_LIMIT or slip > SLIP_LIMIT or seam > SEAM_LIMIT or anim.loop_mode != Animation.LOOP_LINEAR:
			verdict = "SINIR AŞILDI"
			failures += 1
		print("%-6s boy %.3f sn, döngü %d, hız %.2f m/sn, %d kare: gömülme %.1f mm, duruşta kayma %.1f mm (%s), dikiş %.2f mm: %s" % [clip_name, anim.length, anim.loop_mode, speed, frames, sink * 1000.0, slip * 1000.0, slip_leg, seam * 1000.0, verdict])
		if full:
			var lowest := INF
			var where := Vector3.ZERO
			var top := -INF
			for s in 12:
				player.seek(anim.length * s / 12.0, true)
				var pose := _pose_matrices(skeleton, skin, bind_bone)
				for v in range(0, vertices.size(), 2):
					var p := _skinned(vertices[v], v, per_vertex, bones, weights, pose)
					top = maxf(top, p.y)
					if p.y < lowest:
						lowest = p.y
						where = p
			print("       bütün köşeler (12 kare): en alt %.1f mm %s, en üst %.3f m" % [lowest * 1000.0, where, top])
	print("Sonuç: %s" % ("kabul" if failures == 0 else "%d klip sınırı aştı" % failures))
	quit(0 if failures == 0 else 1)


func _bone_origins(skeleton: Skeleton3D) -> PackedVector3Array:
	var out := PackedVector3Array()
	for b in skeleton.get_bone_count():
		out.append(skeleton.get_bone_global_pose(b).origin)
	return out


func _pose_matrices(skeleton: Skeleton3D, skin: Skin, bind_bone: PackedInt32Array) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	out.resize(bind_bone.size())
	for i in bind_bone.size():
		out[i] = skeleton.get_bone_global_pose(bind_bone[i]) * skin.get_bind_pose(i)
	return out


func _skinned(vertex: Vector3, v: int, per_vertex: int, bones: PackedInt32Array, weights: PackedFloat32Array, pose: Array[Transform3D]) -> Vector3:
	var p := Vector3.ZERO
	for k in per_vertex:
		var w := weights[v * per_vertex + k]
		if w > 0.0:
			p += pose[bones[v * per_vertex + k]] * vertex * w
	return p


func _find(node: Node, type_name: String) -> Node:
	if node.is_class(type_name):
		return node
	for child in node.get_children():
		var hit := _find(child, type_name)
		if hit:
			return hit
	return null
