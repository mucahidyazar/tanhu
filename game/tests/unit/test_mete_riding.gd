extends TestCase
## Mete'nin sürüşteki sınamaları (K58, sanat-animasyon.md öneri 12, Yol Haritası mete-model-checks ve riding): pelerin iskeleti (RideCape), M6 (arka
## pelerin köşeleri at gövdesine ≤%3 ve ≤2 cm girer), M7 (binme ve inme sıçramasız), M8 (dörtnalda 20 fps'te titreme yok, pelerinin yayı 0,2 sn
## yarı ömür), M9 (kalça eyer noktasında ±1 cm), M10 (diz ve kaval ≤1 cm). Ölçü RideFit'tir: köşeler işlemcide deri giydirilir, at gövdesinin
## o anki üçgenlerine en yakın yüzün yönü ve üç ışının tek-çift sayısıyla içte mi bakılır. Gerçek modeller (assets/characters/mete, horse_brown).

const DT := 1.0 / 60.0
const BROWN := "res://assets/animals/horse_brown/horse_brown.glb"
const DYE := "res://assets/characters/mete/mete_dye.png"
const DYE2 := "res://assets/characters/mete/mete_dye2.png"
## Ölçütler (K58): M6 köşe payı ve derinliği, M9 eyer noktası, M10 diz ve kaval.
const M6_SHARE := 0.03
const M6_DEPTH := 0.02
const M9_SEAT := 0.01
const M10_DEPTH := 0.01


class FlatShape:
	extends TerrainShape

	func height_at(_x: float, _z: float) -> float:
		return 0.0


var _trash: Array[Node] = []
var _player: PlayerController
var _horse: RideableHorse
var _horse_anim: AnimationPlayer
var _rider_anim: AnimationPlayer
var _cape: RideCape


func before_each() -> void:
	Mount.reset_cache()


func after_each() -> void:
	for node in _trash:
		if is_instance_valid(node):
			node.queue_free()
	_trash.clear()


func test_cape_rig_moves_only_the_cape_sheet_to_its_bones() -> void:
	await _setup(false)
	assert_not_null(_cape, "Oyuncu karakterine pelerin iskeleti kurulur")
	var skel := _cape.skeleton
	assert_eq(_cape.bones.size(), RideCape.CHAINS.size(), "Beş zincir")
	for chain: Array in _cape.bones:
		assert_eq(chain.size(), RideCape.JOINT_Y.size() - 1, "Zincir başına üç kemik")
		for bone: int in chain:
			assert_eq(skel.get_bone_parent(chain[0]), skel.find_bone("Hips"), "Zincirin kökü kalçanın çocuğu")
			assert_true(RideCape.is_cape_bone(skel.get_bone_name(bone)))
	assert_between(float(_cape.moved_vertices), 10000.0, 20000.0, "Örtünün köşeleri zincire geçer (%d)" % _cape.moved_vertices)
	# Ağırlıklar dörtlü, toplamı 1; yüz ve el köşeleri hiç değişmez.
	var mi := RideCape.skinned_mesh(_player.get_avatar())
	assert_eq(mi.mesh, _cape.walk_mesh, "Yaya modelin kendi ağırlığıyla yürür (M5)")
	var arrays := _cape.ride_mesh.surface_get_arrays(0)
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var worst := 0.0
	for v in range(0, verts.size(), 7):
		var total := weights[v * 4] + weights[v * 4 + 1] + weights[v * 4 + 2] + weights[v * 4 + 3]
		worst = maxf(worst, absf(total - 1.0))
	assert_true(worst < 0.002, "Ağırlık toplamı 1 (en büyük sapma %.4f)" % worst)
	var original := (load("res://assets/characters/mete/mete.glb") as PackedScene).instantiate() as Node3D
	var omi: MeshInstance3D = original.find_children("*", "MeshInstance3D", true, false)[0]
	var o_arrays := omi.mesh.surface_get_arrays(0)
	var o_bones: PackedInt32Array = o_arrays[Mesh.ARRAY_BONES]
	var o_weights: PackedFloat32Array = o_arrays[Mesh.ARRAY_WEIGHTS]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var head_changed := 0
	for v in verts.size():
		if verts[v].y > 1.3:
			for k in 4:
				if bones[v * 4 + k] != o_bones[v * 4 + k] or absf(weights[v * 4 + k] - o_weights[v * 4 + k]) > 1e-6:
					head_changed += 1
					break
	assert_eq(head_changed, 0, "Göğüs, kol ve baş ağırlığı değişmez")
	original.free()
	# Yeniden kurulum aynı düğümü verir (bir kez kurulur).
	assert_eq(RideCape.install(_player.get_avatar(), _player), _cape)


func test_m6_back_cape_corners_stay_out_of_the_horse() -> void:
	await _setup(true)
	var mi := RideCape.skinned_mesh(_player.get_avatar())
	var horse_mi: MeshInstance3D = _horse.find_children("*", "MeshInstance3D", true, false)[0]
	var corners := RideFit.cape_corners(mi.mesh, _image(DYE))
	assert_between(float(corners.size()), 10000.0, 13000.0, "Kalça altı arka pelerin köşeleri (%d)" % corners.size())
	var worst_share := 0.0
	var worst_depth := 0.0
	for gait: Array in [["dur", Vector2.ZERO, false, 1.0], ["adım", Vector2(0, 1), false, 2.0], ["tırıs", Vector2(0, 1), true, 0.6], ["dörtnal", Vector2(0, 1), true, 2.0]]:
		_steps(gait[1], gait[2], gait[3])
		for k in 2:
			_steps(gait[1], gait[2], 0.13)
			var body := RideFit.Surface.from_mesh(horse_mi, _horse_box())
			var r := RideFit.penetration(RideFit.skinned_points(mi, corners, 0, _cape.last_poses), body)
			worst_share = maxf(worst_share, r["share"])
			worst_depth = maxf(worst_depth, r["max_depth"])
			assert_true(float(r["share"]) <= M6_SHARE and float(r["max_depth"]) <= M6_DEPTH,
				"M6 %s: köşelerin %%%.2f'si içte, en derin %.1f cm (≤%%3, ≤2 cm)" % [gait[0], 100.0 * float(r["share"]), 100.0 * float(r["max_depth"])])
	print("    M6: en kötü %%%.2f, %.1f cm" % [100.0 * worst_share, 100.0 * worst_depth])


func test_m10_knee_and_shin_stay_out_of_the_horse() -> void:
	await _setup(true)
	var mi := RideCape.skinned_mesh(_player.get_avatar())
	var horse_mi: MeshInstance3D = _horse.find_children("*", "MeshInstance3D", true, false)[0]
	var legs := RideFit.leg_vertices(mi, _image(DYE), 0, _image(DYE2))
	assert_true(legs.size() > 2000, "Diz ve kaval köşeleri (%d)" % legs.size())
	var worst := 0.0
	for gait: Array in [["dur", Vector2.ZERO, false, 1.0], ["tırıs", Vector2(0, 1), true, 0.6], ["dörtnal", Vector2(0, 1), true, 2.0]]:
		_steps(gait[1], gait[2], gait[3])
		var body := RideFit.Surface.from_mesh(horse_mi, _horse_box())
		var r := RideFit.penetration(RideFit.skinned_points(mi, legs, 0, _cape.last_poses), body)
		worst = maxf(worst, r["max_depth"])
		assert_true(float(r["max_depth"]) <= M10_DEPTH, "M10 %s: diz ve kaval en çok %.1f cm girer (≤1 cm)" % [gait[0], 100.0 * float(r["max_depth"])])
	print("    M10: en derin %.2f cm" % (100.0 * worst))


func test_m9_hips_sit_on_the_saddle_point() -> void:
	await _setup(true)
	var skel := _player.get_avatar().get_skeleton()
	var hips := skel.find_bone("Hips")
	var worst := 0.0
	var worst_lag := 0.0
	for gait: Array in [["dur", Vector2.ZERO, false, 1.0], ["adım", Vector2(0, 1), false, 1.5], ["dörtnal", Vector2(0, 1), true, 2.0]]:
		for i in int(float(gait[3]) / DT):
			_player.step(DT, gait[1], gait[2], 0.0)
			_horse_anim.advance(DT)
			_rider_anim.advance(DT)
			var want := _seat_point()
			var lagged := (skel.global_transform * skel.get_bone_global_pose(hips).origin).distance_to(want)
			worst_lag = maxf(worst_lag, lagged)
			# Karenin sonunda (SeatSync) binici bineğin bu karesine oturur.
			_player.sync_seat()
			_rider_anim.advance(0.0)
			var have := skel.global_transform * skel.get_bone_global_pose(hips).origin
			worst = maxf(worst, have.distance_to(want))
	assert_true(worst <= M9_SEAT, "M9: kalça eyer noktasından en çok %.2f cm (±1 cm)" % (100.0 * worst))
	print("    M9: %.2f cm (karenin sonundaki yeniden oturuş olmasa %.2f cm)" % [100.0 * worst, 100.0 * worst_lag])


func test_m7_mounting_and_dismounting_have_no_jumps() -> void:
	await _setup(false)
	var skel := _player.get_avatar().get_skeleton()
	var tracked: Array[int] = [skel.find_bone("Hips"), skel.find_bone("LeftHand"), skel.find_bone("RightFoot"), int(_cape.bones[2][2]), int(_cape.bones[0][2])]
	var paths := []
	for b in tracked:
		paths.append([])
	# Pelerinin köşeleri de (binişin başında zincirli ağa, inişin sonunda yayanın ağına geçilir): her 40. köşe.
	var mi := RideCape.skinned_mesh(_player.get_avatar())
	var all_corners := RideFit.cape_corners(_cape.ride_mesh, _image(DYE))
	var sample := PackedInt32Array()
	for i in range(0, all_corners.size(), 40):
		sample.append(all_corners[i])
	var walk_arrays := _cape.walk_mesh.surface_get_arrays(0)
	var ride_arrays := _cape.ride_mesh.surface_get_arrays(0)
	var vertex_paths: Array[PackedVector3Array] = []
	_player.spawn_at(Vector3(1.4, 0.0, 0.3), -PI * 0.5)
	assert_true(_player.interact(), "E biner")
	var t := 0.0
	var phase_frames := 0
	while t < 6.0:
		var riding := _player.is_riding()
		if riding and phase_frames == 0:
			phase_frames = 1
			_player.interact()
		_player.step(DT, Vector2.ZERO, false, 0.0)
		_horse_anim.advance(DT)
		_rider_anim.advance(DT)
		_cape.solve_now(DT)
		var poses := RideFit.global_poses(skel, _cape.last_poses)
		for i in tracked.size():
			(paths[i] as Array).append(skel.global_transform * poses[tracked[i]].origin)
		vertex_paths.append(RideFit.skin_arrays(walk_arrays if mi.mesh == _cape.walk_mesh else ride_arrays, RideFit.skin_matrices(mi, _cape.last_poses), sample, mi.global_transform))
		t += DT
		if phase_frames == 1 and _player.get_stance() == PlayerController.Stance.FOOT:
			break
	assert_eq(_player.get_stance(), PlayerController.Stance.FOOT, "Binip indi")
	for i in tracked.size():
		var path: Array = paths[i]
		var spikes := 0
		var biggest := 0.0
		for f in range(1, path.size() - 1):
			var d := (path[f] as Vector3).distance_to(path[f - 1])
			var before := (path[f - 1] as Vector3).distance_to(path[f - 2]) if f >= 2 else d
			var after := (path[f + 1] as Vector3).distance_to(path[f])
			biggest = maxf(biggest, d)
			# Sıçrama: bir karelik yol, komşu karelerinkinin iki buçuk katından ve 3 cm'den büyük.
			if d > 2.5 * maxf(before, after) + 0.03:
				spikes += 1
		assert_eq(spikes, 0, "M7 %s: binme ve inme sıçramasız (karede en çok %.1f cm)" % [skel.get_bone_name(tracked[i]), 100.0 * biggest])
	var vertex_spikes := 0
	var vertex_biggest := 0.0
	for f in range(2, vertex_paths.size() - 1):
		for k in sample.size():
			var d := vertex_paths[f][k].distance_to(vertex_paths[f - 1][k])
			var around := maxf(vertex_paths[f - 1][k].distance_to(vertex_paths[f - 2][k]), vertex_paths[f + 1][k].distance_to(vertex_paths[f][k]))
			vertex_biggest = maxf(vertex_biggest, d)
			if d > 2.5 * around + 0.03:
				vertex_spikes += 1
	assert_eq(vertex_spikes, 0, "M7 pelerinin köşeleri sıçramasız (%d köşe; karede en çok %.1f cm)" % [sample.size(), 100.0 * vertex_biggest])


func test_m8_gallop_at_20_fps_does_not_jitter() -> void:
	await _setup(true)
	var dt := 1.0 / 20.0
	for i in int(4.5 / dt):
		_player.step(dt, Vector2(0, 1), true, 0.0)
		_horse_anim.advance(dt)
		_rider_anim.advance(dt)
		_cape.solve_now(dt)
	assert_eq(_player.mount_gait(), "gallop")
	# Yay: dörtnala geçişte arkaya akış hedefine yarı ömür 0,2 sn ile yaklaşır.
	var goal := minf(_player.get_speed() * RideCape.TRAIL_PER_MPS, RideCape.TRAIL_MAX)
	assert_almost(_cape._trail, goal, 1.0, "Akış dörtnalın hedefinde (%.1f°)" % goal)
	var skel := _cape.skeleton
	var tip := int(_cape.bones[2][2])
	var dirs: Array[Vector3] = []
	for i in int(2.0 / dt):
		_player.step(dt, Vector2(0, 1), true, 0.0)
		_horse_anim.advance(dt)
		_rider_anim.advance(dt)
		_cape.solve_now(dt)
		dirs.append((skel.global_transform.basis * (_cape.last_poses[tip] as Transform3D).basis.y).normalized())
	# Titreme: kemiğin yönü karede bir yöne, sonraki karede ters yöne 4°'den çok dönüyorsa.
	var flips := 0
	var biggest := 0.0
	for i in range(2, dirs.size()):
		var a := rad_to_deg(dirs[i - 2].angle_to(dirs[i - 1]))
		var b := rad_to_deg(dirs[i - 1].angle_to(dirs[i]))
		biggest = maxf(biggest, b)
		var turn_a := dirs[i - 2].cross(dirs[i - 1])
		var turn_b := dirs[i - 1].cross(dirs[i])
		if a > 4.0 and b > 4.0 and turn_a.dot(turn_b) < 0.0:
			flips += 1
	assert_true(flips <= 1, "M8: 20 fps dörtnalda pelerin titremez (%d ters dönüş, karede en çok %.1f°)" % [flips, biggest])
	# Yayın yarı ömrü: hedefin değiştiği an farkın yarısı 0,2 sn'de kapanır.
	var cape := RideCape.new()
	cape._trail = 0.0
	var half := 0.0
	var target := 40.0
	var elapsed := 0.0
	while half == 0.0 and elapsed < 1.0:
		cape._trail += (target - cape._trail) * (1.0 - pow(0.5, dt / RideCape.TRAIL_HALF_LIFE))
		elapsed += dt
		if cape._trail >= target * 0.5:
			half = elapsed
	assert_almost(half, RideCape.TRAIL_HALF_LIFE, dt * 0.51, "Yay yarı ömrü 0,2 sn (M8)")
	cape.free()


# --- Yardımcılar ---------------------------------------------------------------------------------------------------

## Mete (profil, pelerin iskeleti) ve kampın atı, düz zemin; mounted ise binmiş ve oturmuş.
func _setup(mounted: bool) -> void:
	_horse = RideableHorse.new()
	_horse.model_path = BROWN
	_horse.effects_enabled = false
	add_child(_horse)
	_trash.append(_horse)
	_horse.place(Vector3.ZERO, 0.0)
	_player = PlayerController.new()
	_player.terrain_shape = FlatShape.new()
	_player.start_active = false
	var avatar := CharacterAvatar.new()
	_player.add_child(avatar)
	add_child(_player)
	_trash.append(_player)
	_player.set_process(false)
	await wait_frames(1)
	_player.obstacles = []
	_player.use_profile(CharacterProfile.new())
	_player.set_active(true)
	_cape = avatar.get_node_or_null(^"RideCape") as RideCape
	_horse_anim = _horse.find_children("*", "AnimationPlayer", true, false)[0]
	_rider_anim = avatar.get_animation_player()
	if mounted:
		_player.spawn_at(Vector3(1.3, 0.0, 0.3), -PI * 0.5)
		_player.interact()
		_steps(Vector2.ZERO, false, 3.0)
		assert_true(_player.is_riding(), "Binildi")


func _steps(input: Vector2, sprint: bool, seconds: float) -> void:
	for i in int(round(seconds / DT)):
		_player.step(DT, input, sprint, 0.0)
		_horse_anim.advance(DT)
		_rider_anim.advance(DT)
		_player.sync_seat()
		if _cape:
			_cape.solve_now(DT)


## Atın gövdesinin ölçüldüğü kutu (dünya; atın çevresi).
func _horse_box() -> AABB:
	return AABB(_horse.global_position - Vector3(1.0, -0.4, 1.8), Vector3(2.0, 1.6, 3.6))


## Eyer noktası: oturma noktası ve binicinin oturuş yüksekliği (sırtın yukarısında).
func _seat_point() -> Vector3:
	var seat := _horse.seat_transform()
	return seat.origin + seat.basis.y.normalized() * _player.hips_lift()


func _image(path: String) -> Image:
	return Image.load_from_file(ProjectSettings.globalize_path(path))
