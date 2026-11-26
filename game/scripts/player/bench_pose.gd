class_name BenchPose
extends RefCounted
## Oturak pozu (travel.md §3.4 «benchK»; K58 M15, mete-model-checks): arabanın arka ağzında ya da bir kenarda oturan kişinin pozu. Kütüphanede
## yoktur, RidePose gibi oturma klibinden kodla türer (0 kredi): bağdaşın gövdesi, boynu ve başı kalır, leğen dikleşir; uyluklar öne ve
## hafifçe aşağı uzanır (diz oturağın kenarının ötesinde), baldırlar dizden aşağı sarkar (azıcık öne), ayak ucu öne ve aşağı bakar; eller dizlerin
## üstündedir. Kalça dinlenmedeki yerinde kalır: oturan, kalçayı oturak noktasına koyar (oturuşun yüksekliği kadar üstüne).
## Ölçüler opts'tan (metre): thigh_drop uyluğun aşağı eğimi (derece), knee_out dizlerin ortadan açıklığı, shin_forward baldırın öne açısı
## (derece), hand_up elin uyluk üstündeki yüksekliği, hand_back dizden kalçaya doğru payı. Kemik adları Meshy iskeletinindir; eksik kemikte null.
##   var anim := BenchPose.build(skeleton, sit_clip, {}, avatar.model_scale)
##   avatar.set_role_clip(BenchPose.ROLE, anim); avatar.play_pose(BenchPose.ROLE)

const ROLE := &"bench"
const DEFAULTS := {"thigh_drop": 4.0, "knee_out": 0.11, "shin_forward": 9.0, "hand_up": 0.07, "hand_back": 0.12, "hand_in": 0.03}
## Ayak ucunun yönü (bileşenler: öne, aşağı, dışa) ve elin parmakları (öne, aşağı) ile avucu (aşağı).
const TOE_DIR := Vector3(0.04, -0.45, 0.89)
const FINGERS := Vector3(0.0, -0.35, 0.94)
const PALM := Vector3(0.0, -1.0, 0.0)
const ELBOW_HINT := Vector3(0.8, -0.35, -0.3)


## Klibi kurar (RidePose ile aynı yazım: kemik başına iki anahtar, göğüste nefes; rolün adı «bench»). Kemikler eksikse null.
static func build(skeleton: Skeleton3D, sit: Animation, opts: Dictionary = {}, model_scale: float = 1.0) -> Animation:
	if skeleton == null or sit == null:
		return null
	for bone_name in RidePose.REQUIRED_BONES:
		if skeleton.find_bone(bone_name) < 0:
			return null
	var solved := solve(skeleton, sit, opts, model_scale)
	var anim := RidePose._write(skeleton, solved["local"], solved["hips"], ClipRetarget.track_prefix(sit))
	anim.resource_name = String(ROLE)
	return anim


## Pozun hesabı (saf; iskeleti değiştirmez): {local, hips, points (iskelet uzayı), units}.
static func solve(skeleton: Skeleton3D, sit: Animation, opts: Dictionary = {}, model_scale: float = 1.0) -> Dictionary:
	var o := DEFAULTS.duplicate()
	o.merge(opts, true)
	var prefix := ClipRetarget.track_prefix(sit)
	var rest := ClipRetarget.rest_rotations(skeleton)
	var rest_points := ClipRetarget.rest_points(skeleton)
	var local := ClipRetarget.local_rotations_at(sit, skeleton, rest, prefix, 0.0)
	for bone_name in RidePose.SPINE_BONES:
		var spine := skeleton.find_bone(bone_name)
		if spine >= 0:
			local[spine] = local[spine].slerp(rest[spine], RidePose.SPINE_OPEN)
	var axes := CineBow.character_axes(skeleton)
	var to_model := PoseFit.relative_transform(skeleton.owner as Node3D, skeleton)
	var units := 1.0 / maxf(to_model.basis.x.length() * model_scale, 0.000001)
	var hips := skeleton.find_bone("Hips")
	local[hips] = RidePose._upright_hips(skeleton, local, axes)
	var hips_at := rest_points[hips]
	RidePose._level_head(skeleton, local, rest, axes)
	var global := ClipRetarget.global_rotations(skeleton, local)
	var points := RidePose._points(skeleton, global, hips, hips_at)
	var rest_global := RidePose._rest_globals(skeleton, rest)
	for side: String in RidePose.SIDES:
		_solve_leg(skeleton, side, float(RidePose.SIDES[side]), o, axes, units, rest_global, rest_points, global, points, local)
	global = ClipRetarget.global_rotations(skeleton, local)
	points = RidePose._points(skeleton, global, hips, hips_at)
	for side: String in RidePose.SIDES:
		_solve_arm(skeleton, side, float(RidePose.SIDES[side]), o, axes, units, rest_points, rest_global, global, points, local)
	global = ClipRetarget.global_rotations(skeleton, local)
	return {"local": local, "hips": hips_at, "points": RidePose._points(skeleton, global, hips, hips_at), "units": units}


## Bacak: uyluk öne ve thigh_drop kadar aşağı, diz ortadan knee_out açık; baldır dizden aşağı, shin_forward kadar öne; ayak ucu öne ve aşağı.
static func _solve_leg(skeleton: Skeleton3D, side: String, s: float, o: Dictionary, axes: Basis, units: float, rest_global: Array[Quaternion],
		rest_points: PackedVector3Array, global: Array[Quaternion], points: PackedVector3Array, local: Array[Quaternion]) -> void:
	var up_leg := skeleton.find_bone(side + "UpLeg")
	var leg := skeleton.find_bone(side + "Leg")
	var foot := skeleton.find_bone(side + "Foot")
	var hip := points[up_leg]
	var thigh := rest_points[leg].distance_to(rest_points[up_leg])
	var center := points[skeleton.find_bone("Hips")]
	var drop := deg_to_rad(float(o["thigh_drop"]))
	# Dizin yanal yeri: ortadan knee_out (m); uyluğun yanal bileşeni kalçanın ve dizin farkından.
	var hip_out := (hip - center).dot(axes.x) * s
	var lateral := clampf((float(o["knee_out"]) * units - hip_out) / maxf(thigh, 0.001), -0.3, 0.3)
	var thigh_dir := (axes.z * cos(drop) - axes.y * sin(drop) + axes.x * s * lateral).normalized()
	var fwd := deg_to_rad(float(o["shin_forward"]))
	var shin_dir := (-axes.y * cos(fwd) + axes.z * sin(fwd) + axes.x * s * lateral * 0.25).normalized()
	var knee_front := (thigh_dir - shin_dir).normalized() if (thigh_dir - shin_dir).length_squared() > 0.0001 else axes.z
	var thigh_q := RidePose._aim(rest_global[up_leg], rest_points[leg] - rest_points[up_leg], axes.z, thigh_dir, knee_front)
	var shin_q := RidePose._aim(rest_global[leg], rest_points[foot] - rest_points[leg], axes.z, shin_dir, knee_front)
	var toe := skeleton.find_bone(side + "ToeBase")
	var foot_q := rest_global[foot]
	if toe >= 0:
		var toe_dir := (axes.x * s * TOE_DIR.x + axes.y * TOE_DIR.y + axes.z * TOE_DIR.z).normalized()
		foot_q = RidePose._aim(rest_global[foot], rest_points[toe] - rest_points[foot], rest_points[leg] - rest_points[foot], toe_dir, -shin_dir)
	var hips_q := global[skeleton.get_bone_parent(up_leg)]
	local[up_leg] = (hips_q.inverse() * thigh_q).normalized()
	local[leg] = (thigh_q.inverse() * shin_q).normalized()
	local[foot] = (shin_q.inverse() * foot_q).normalized()
	if toe >= 0:
		local[toe] = skeleton.get_bone_rest(toe).basis.get_rotation_quaternion()


## Kol: bilek dizin üstünde (hand_up yukarı, hand_back kalçaya doğru, hand_in içe), dirsek dışa ve geriye; avuç uyluğa bakar.
static func _solve_arm(skeleton: Skeleton3D, side: String, s: float, o: Dictionary, axes: Basis, units: float, rest_points: PackedVector3Array,
		rest_global: Array[Quaternion], global: Array[Quaternion], points: PackedVector3Array, local: Array[Quaternion]) -> void:
	var arm := skeleton.find_bone(side + "Arm")
	var fore := skeleton.find_bone(side + "ForeArm")
	var hand := skeleton.find_bone(side + "Hand")
	var knee := points[skeleton.find_bone(side + "Leg")]
	var shoulder := points[arm]
	var upper := rest_points[fore].distance_to(rest_points[arm])
	var lower := rest_points[hand].distance_to(rest_points[fore])
	var wrist_goal := knee + (axes.y * float(o["hand_up"]) - axes.z * float(o["hand_back"]) - axes.x * s * float(o["hand_in"])) * units
	var bend := axes.x * s * ELBOW_HINT.x + axes.y * ELBOW_HINT.y + axes.z * ELBOW_HINT.z
	var elbow_rest := shoulder + (rest_points[fore] - rest_points[arm])
	var wrist_rest := elbow_rest + (rest_points[hand] - rest_points[fore])
	var solved := KopuzPlay.solve_two_bone(shoulder, elbow_rest, wrist_rest, wrist_goal, -axes.y, bend)
	var upper_dir: Vector3 = ((solved[0] as Vector3) - shoulder) / maxf(upper, 0.001)
	var lower_dir: Vector3 = ((solved[1] as Vector3) - (solved[0] as Vector3)) / maxf(lower, 0.001)
	var arm_q := RidePose._aim(rest_global[arm], rest_points[fore] - rest_points[arm], axes.y, upper_dir, RidePose._outward_up(upper_dir, lower_dir, axes.y))
	var fore_q := RidePose._aim(rest_global[fore], rest_points[hand] - rest_points[fore], axes.y, lower_dir, RidePose._outward_up(upper_dir, lower_dir, axes.y))
	var hand_q := fore_q * skeleton.get_bone_rest(hand).basis.get_rotation_quaternion()
	var middle := skeleton.find_bone(side + "Middle1")
	if middle >= 0:
		var fingers := axes.x * s * FINGERS.x + axes.y * FINGERS.y + axes.z * FINGERS.z
		var palm := axes.x * s * PALM.x + axes.y * PALM.y + axes.z * PALM.z
		hand_q = KopuzPlay.hand_basis(skeleton.get_bone_rest(middle), fingers, palm).get_rotation_quaternion()
	var parent_q := global[skeleton.get_bone_parent(arm)]
	local[arm] = (parent_q.inverse() * arm_q).normalized()
	local[fore] = (arm_q.inverse() * fore_q).normalized()
	local[hand] = (fore_q.inverse() * hand_q).normalized()


## Oturanın kalçası oturak yüzünün ne kadar üstünde (m): kişinin yerde oturuşundaki kalça yüksekliği (ClipLibrary.hips_height_for «sit»;
## ölçü yoksa PlayerController.RIDE_HIPS_LIFT) × modelin ölçeği.
static func hips_lift(avatar: CharacterAvatar) -> float:
	if avatar == null:
		return PlayerController.RIDE_HIPS_LIFT
	var measured := ClipVariety.library().hips_height_for(avatar.model_id, PlayerController.RIDE_SIT_KEY) if avatar.get_skeleton() else 0.0
	return (measured if measured > 0.0 else PlayerController.RIDE_HIPS_LIFT) * avatar.model_scale


## Kalçanın avatarın uzayındaki dinlenme yeri (rolün zemin payı dahil; PlayerController._hips_in_avatar ile aynı).
static func hips_in_avatar(avatar: CharacterAvatar) -> Vector3:
	var skeleton := avatar.get_skeleton() if avatar else null
	var hips := skeleton.find_bone("Hips") if skeleton else -1
	if hips < 0:
		return Vector3(0.0, 0.5, 0.0)
	return PoseFit.relative_transform(avatar, skeleton) * skeleton.get_bone_global_rest(hips).origin


## Oturağa göre avatarın dönüşümü: kalça seat'in yüzünün hips_lift üstünde, avatarın ön yüzü seat'in +Z'si.
static func seated_transform(seat: Transform3D, avatar: CharacterAvatar, lift: float) -> Transform3D:
	var basis := seat.basis.orthonormalized()
	return Transform3D(basis, seat.origin + basis.y * lift - basis * BenchPose.hips_in_avatar(avatar))


## Oturak pozu kişinin bu modeli için (kişi başına bir kez kurulur; kurulamazsa false). Rol avatarda «bench».
static func prepare(avatar: CharacterAvatar, opts: Dictionary = {}) -> bool:
	if avatar == null or avatar.get_skeleton() == null:
		return false
	if avatar.available_roles().has(ROLE):
		return true
	var skeleton := avatar.get_skeleton()
	var sit := ClipVariety.library().clip_for(avatar.model_id, "sit", skeleton)
	var anim := BenchPose.build(skeleton, sit, opts, avatar.model_scale)
	# Klibin kaynak sahnesi bırakılır (PlayerController'ın binme pozu gibi): ağaç dışındaki kök önbellekte kalıp çıkışta sızmasın.
	ClipVariety.release_sources()
	if anim == null:
		return false
	avatar.set_role_clip(ROLE, anim)
	return true
