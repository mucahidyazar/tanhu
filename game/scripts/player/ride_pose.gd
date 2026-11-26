class_name RidePose
extends RefCounted
## Binme pozu (godot.md §6.6, story.md §5): kütüphanede binme klibi yok, oturma klibinden kodla türetilir (0 kredi). Bağdaş oturuşunun gövdesi,
## boynu ve başı kalır; leğen dikleşir, bacaklar bineğin gövdesini saracak biçimde iki yana açılır, baldırlar böğüre sarkar, eller yünü tutar.
## Klip bir kez kurulur, oynatıcıda bir roldür (CharacterAvatar.set_role_clip); kare içinde hesap yoktur, üstüne yay pozu (BowPose) biner.
##
## Ölçüler bineğin satırından (data/fauna/mounts.json seat): girth uyluğun, shin_girth baldırın aşması gereken yarı genişlik, hand_* elin kalçaya göre
## yeri. Aynı işlev at için de çalışır (satırı farklıdır); kemik adları Meshy iskeletinindir. Eksik kemikte (chibi yedeği) null döner, kullanan atlar.
##   var anim := RidePose.build(skeleton, sit_clip, mount.seat(), avatar.model_scale)
##   avatar.set_role_clip(RidePose.ROLE, anim); avatar.play_pose(RidePose.ROLE)

const ROLE := &"ride"
const LENGTH := 2.0
## Gövdenin öne eğilişi (derece): oturan çocuk azıcık öne verir. Oturuşun kamburu bu oranda açılır (omurga dinlenme pozuna yaklaşır: bağdaşta kişi kucağına bakar).
const LEAN_DEG := 4.0
const SPINE_OPEN := 0.65
const SPINE_BONES: Array[String] = ["Spine02", "Spine01", "Spine"]
## Baş ileri bakar: kalan açının boyundaki payı.
const NECK_SHARE := 0.4
## Nefes (derece, klibin ortasında göğsün öne gidişi).
const BREATH_DEG := 1.2
## Uyluğun öne açılışı (bileşen) ve dışa açılışın sınırları: dizin yan yana geldiği yer girth'ten çıkar.
const THIGH_FORWARD := 0.42
const THIGH_OUT := Vector2(0.3, 0.86)
## Baldırın geriye açılışı ve bileğin aşması gereken pay (m).
const SHIN_BACK := 0.12
const KNEE_CLEAR := 0.02
const ANKLE_CLEAR := 0.015
## Ayak ucunun yönü (bileşenler: öne, aşağı, dışa).
const TOE_DIR := Vector3(0.12, -0.62, 0.78)
## Dirseğin bükülme yönü (bileşenler: dışa, aşağı, geriye).
const ELBOW_HINT := Vector3(0.75, -0.5, -0.25)
## Elin parmakları (dışa, aşağı, öne) ve avucu (aşağı): yünü üstten kavrar.
const FINGERS := Vector3(-0.2, -0.45, 0.85)
const PALM := Vector3(0.0, -1.0, 0.1)
const REQUIRED_BONES: Array[String] = ["Hips", "LeftUpLeg", "LeftLeg", "LeftFoot", "RightUpLeg", "RightLeg", "RightFoot", "LeftArm", "LeftForeArm", "LeftHand", "RightArm", "RightForeArm", "RightHand"]
const SIDES := {"Left": 1.0, "Right": -1.0}


## Klibi kurar. skeleton: oynatıcının iskeleti; sit: aynı iskeletin oturma klibi; seat: satırın ölçüleri (metre); model_scale: modelin ölçeği.
## Kemikler eksikse null.
static func build(skeleton: Skeleton3D, sit: Animation, seat: Dictionary, model_scale: float = 1.0) -> Animation:
	if skeleton == null or sit == null:
		return null
	for bone_name in REQUIRED_BONES:
		if skeleton.find_bone(bone_name) < 0:
			return null
	var solved := solve(skeleton, sit, seat, model_scale)
	return _write(skeleton, solved["local"], solved["hips"], ClipRetarget.track_prefix(sit))


## Pozun hesabı (saf; iskeleti değiştirmez). Döner: {local: yerel dönüşler (kemik sırasıyla), hips: kök konumu, points: eklem konumları (iskelet uzayı)}.
static func solve(skeleton: Skeleton3D, sit: Animation, seat: Dictionary, model_scale: float = 1.0) -> Dictionary:
	var prefix := ClipRetarget.track_prefix(sit)
	var rest := ClipRetarget.rest_rotations(skeleton)
	var rest_points := ClipRetarget.rest_points(skeleton)
	var local := ClipRetarget.local_rotations_at(sit, skeleton, rest, prefix, 0.0)
	for bone_name in SPINE_BONES:
		var spine := skeleton.find_bone(bone_name)
		if spine >= 0:
			local[spine] = local[spine].slerp(rest[spine], SPINE_OPEN)
	var axes := CineBow.character_axes(skeleton)
	var to_model := PoseFit.relative_transform(skeleton.owner as Node3D, skeleton)
	# Bir metre kaç iskelet birimi?
	var units := 1.0 / maxf(to_model.basis.x.length() * model_scale, 0.000001)
	var hips := skeleton.find_bone("Hips")
	local[hips] = _upright_hips(skeleton, local, axes)
	var hips_at := rest_points[hips]
	_level_head(skeleton, local, rest, axes)
	var global := ClipRetarget.global_rotations(skeleton, local)
	var points := _points(skeleton, global, hips, hips_at)
	var rest_global := _rest_globals(skeleton, rest)
	for side: String in SIDES:
		_solve_leg(skeleton, side, float(SIDES[side]), seat, axes, units, rest_global, rest_points, global, points, local)
	global = ClipRetarget.global_rotations(skeleton, local)
	points = _points(skeleton, global, hips, hips_at)
	for side: String in SIDES:
		_solve_arm(skeleton, side, float(SIDES[side]), seat, axes, units, rest_points, rest_global, global, points, local, hips_at)
	global = ClipRetarget.global_rotations(skeleton, local)
	return {"local": local, "hips": hips_at, "points": _points(skeleton, global, hips, hips_at), "units": units}


## Kalçanın düğüm uzayındaki yeri (metre; model ölçeğiyle): binici bu noktayı oturma noktasına koyar.
static func hips_in_model(skeleton: Skeleton3D, model_scale: float = 1.0) -> Vector3:
	var hips := skeleton.find_bone("Hips")
	if hips < 0:
		return Vector3.ZERO
	return PoseFit.relative_transform(skeleton.owner as Node3D, skeleton) * skeleton.get_bone_global_rest(hips).origin * model_scale


## Leğen: gövde (kalçadan boyna) dik ve biraz önde, omuz hattı yana; oturuşun kendi eğikliği düzelir.
static func _upright_hips(skeleton: Skeleton3D, local: Array[Quaternion], axes: Basis) -> Quaternion:
	var hips := skeleton.find_bone("Hips")
	var global := ClipRetarget.global_rotations(skeleton, local)
	var points := _points(skeleton, global, hips, skeleton.get_bone_global_rest(hips).origin)
	var neck := skeleton.find_bone("neck")
	var want := (axes.y * cos(deg_to_rad(LEAN_DEG)) + axes.z * sin(deg_to_rad(LEAN_DEG))).normalized()
	var turned := local[hips]
	if neck >= 0:
		turned = (ClipRetarget.shortest_arc(points[neck] - points[hips], want) * turned).normalized()
	# Yanal eksen: uyluk köklerinin yönü bedenin soluna (yatay düzlemde).
	var left_leg := skeleton.find_bone("LeftUpLeg")
	var right_leg := skeleton.find_bone("RightUpLeg")
	var lateral := turned * (skeleton.get_bone_rest(left_leg).origin - skeleton.get_bone_rest(right_leg).origin)
	var flat := lateral - want * lateral.dot(want)
	var goal := axes.x - want * axes.x.dot(want)
	return (ClipRetarget.shortest_arc(flat, goal) * turned).normalized()


## Baş ileri bakar: boyun ve baş dinlenmedeki yüzünü yatay öne çevirir.
static func _level_head(skeleton: Skeleton3D, local: Array[Quaternion], rest: Array[Quaternion], axes: Basis) -> void:
	var head := skeleton.find_bone("Head")
	var neck := skeleton.find_bone("neck")
	if head < 0 or neck < 0:
		return
	var rest_global := _rest_globals(skeleton, rest)
	var global := ClipRetarget.global_rotations(skeleton, local)
	var turned: Quaternion = global[head] * rest_global[head].inverse()
	var arc := ClipRetarget.shortest_arc(turned * axes.z, axes.z)
	var neck_turn := Quaternion.IDENTITY.slerp(arc, NECK_SHARE)
	local[neck] = (global[skeleton.get_bone_parent(neck)].inverse() * neck_turn * global[neck]).normalized()
	var new_neck: Quaternion = neck_turn * global[neck]
	local[head] = (new_neck.inverse() * arc * global[head]).normalized()


static func _solve_leg(skeleton: Skeleton3D, side: String, s: float, seat: Dictionary, axes: Basis, units: float, rest_global: Array[Quaternion],
		rest_points: PackedVector3Array, global: Array[Quaternion], points: PackedVector3Array, local: Array[Quaternion]) -> void:
	var up_leg := skeleton.find_bone(side + "UpLeg")
	var leg := skeleton.find_bone(side + "Leg")
	var foot := skeleton.find_bone(side + "Foot")
	var hip := points[up_leg]
	var thigh := rest_points[leg].distance_to(rest_points[up_leg])
	var shin := rest_points[foot].distance_to(rest_points[leg])
	var center := points[skeleton.find_bone("Hips")]
	# Uyluk: diz girth'in dışında kalacak kadar yana açılır.
	var hip_out := (hip - center).dot(axes.x) * s
	var need := (float(seat.get("girth", 0.25)) * units + KNEE_CLEAR * units - hip_out) / maxf(thigh, 0.001)
	var out := clampf(need, THIGH_OUT.x, THIGH_OUT.y)
	var down := sqrt(maxf(1.0 - out * out - THIGH_FORWARD * THIGH_FORWARD, 0.01))
	var thigh_dir := (axes.x * s * out - axes.y * down + axes.z * THIGH_FORWARD).normalized()
	var knee := hip + thigh_dir * thigh
	# Baldır: bilek shin_girth'in dışında, böğre sarkar.
	var knee_out := (knee - center).dot(axes.x) * s
	var shin_out := clampf(((float(seat.get("shin_girth", 0.27)) + ANKLE_CLEAR) * units - knee_out) / maxf(shin, 0.001), -0.25, 0.6)
	var shin_down := sqrt(maxf(1.0 - shin_out * shin_out - SHIN_BACK * SHIN_BACK, 0.01))
	var shin_dir := (axes.x * s * shin_out - axes.y * shin_down - axes.z * SHIN_BACK).normalized()
	# Dizin hizası: uyluk ve baldırın düzlemi; bükülme öne bakar.
	var knee_front := (thigh_dir - shin_dir).normalized() if (thigh_dir - shin_dir).length_squared() > 0.0001 else axes.z
	var thigh_q := _aim(rest_global[up_leg], rest_points[leg] - rest_points[up_leg], axes.z, thigh_dir, knee_front)
	var shin_q := _aim(rest_global[leg], rest_points[foot] - rest_points[leg], axes.z, shin_dir, knee_front)
	var toe := skeleton.find_bone(side + "ToeBase")
	var foot_q := rest_global[foot]
	if toe >= 0:
		var toe_dir := (axes.x * s * TOE_DIR.x + axes.y * TOE_DIR.y + axes.z * TOE_DIR.z).normalized()
		foot_q = _aim(rest_global[foot], rest_points[toe] - rest_points[foot], rest_points[leg] - rest_points[foot], toe_dir, -shin_dir)
	var hips_q := global[skeleton.get_bone_parent(up_leg)]
	local[up_leg] = (hips_q.inverse() * thigh_q).normalized()
	local[leg] = (thigh_q.inverse() * shin_q).normalized()
	local[foot] = (shin_q.inverse() * foot_q).normalized()
	if toe >= 0:
		local[toe] = skeleton.get_bone_rest(toe).basis.get_rotation_quaternion()


static func _solve_arm(skeleton: Skeleton3D, side: String, s: float, seat: Dictionary, axes: Basis, units: float, rest_points: PackedVector3Array,
		rest_global: Array[Quaternion], global: Array[Quaternion], points: PackedVector3Array, local: Array[Quaternion], hips_at: Vector3) -> void:
	var arm := skeleton.find_bone(side + "Arm")
	var fore := skeleton.find_bone(side + "ForeArm")
	var hand := skeleton.find_bone(side + "Hand")
	var shoulder := points[arm]
	var upper := rest_points[fore].distance_to(rest_points[arm])
	var lower := rest_points[hand].distance_to(rest_points[fore])
	var wrist_goal := hips_at + (axes.z * float(seat.get("hand_forward", 0.2)) + axes.y * float(seat.get("hand_up", 0.0)) + axes.x * s * float(seat.get("hand_side", 0.1))) * units
	var bend := axes.x * s * ELBOW_HINT.x + axes.y * ELBOW_HINT.y + axes.z * ELBOW_HINT.z
	var elbow_rest := shoulder + (rest_points[fore] - rest_points[arm])
	var wrist_rest := elbow_rest + (rest_points[hand] - rest_points[fore])
	var solved := KopuzPlay.solve_two_bone(shoulder, elbow_rest, wrist_rest, wrist_goal, -axes.y, bend)
	var upper_dir: Vector3 = ((solved[0] as Vector3) - shoulder) / maxf(upper, 0.001)
	var lower_dir: Vector3 = ((solved[1] as Vector3) - (solved[0] as Vector3)) / maxf(lower, 0.001)
	# Kolun yüzü: T-pozun üstü (y) dirseğin dışına döner.
	var arm_q := _aim(rest_global[arm], rest_points[fore] - rest_points[arm], axes.y, upper_dir, _outward_up(upper_dir, lower_dir, axes.y))
	var fore_q := _aim(rest_global[fore], rest_points[hand] - rest_points[fore], axes.y, lower_dir, _outward_up(upper_dir, lower_dir, axes.y))
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


## Kol düzleminin «üst» yönü: kolun iki kemiğinin normali, up'a yakın işaretle.
static func _outward_up(upper_dir: Vector3, lower_dir: Vector3, up: Vector3) -> Vector3:
	var normal := upper_dir.cross(lower_dir)
	if normal.length_squared() < 0.0001:
		return up
	normal = normal.normalized()
	return normal if normal.dot(up) >= 0.0 else -normal


## Dinlenme dönüşünden yeni dönüş: kemiğin ekseni (rest_dir → dir) ve yan yönü (rest_side → side) hizalanır.
static func _aim(rest_q: Quaternion, rest_dir: Vector3, rest_side: Vector3, dir: Vector3, side: Vector3) -> Quaternion:
	var from := _frame(rest_dir, rest_side)
	var to := _frame(dir, side)
	return (to * from.inverse()).get_rotation_quaternion() * rest_q


## x ekseni x, y ekseni y'nin x'e dik bileşeni olan ortonormal taban. y x'e koşutsa başka bir yön alınır.
static func _frame(x: Vector3, y: Vector3) -> Basis:
	var fx := x.normalized()
	var fy := y - fx * y.dot(fx)
	if fy.length_squared() < 0.000001:
		fy = fx.cross(Vector3.RIGHT if absf(fx.x) < 0.9 else Vector3.UP)
	fy = fy.normalized()
	return Basis(fx, fy, fx.cross(fy))


static func _rest_globals(skeleton: Skeleton3D, rest: Array[Quaternion]) -> Array[Quaternion]:
	return ClipRetarget.global_rotations(skeleton, rest)


## Eklem konumları (iskelet uzayı): kemik boyları dinlenme pozundan, kök hips_at'te.
static func _points(skeleton: Skeleton3D, global: Array[Quaternion], root: int, root_at: Vector3) -> PackedVector3Array:
	var out := PackedVector3Array()
	out.resize(skeleton.get_bone_count())
	var done := PackedByteArray()
	done.resize(skeleton.get_bone_count())
	for b in skeleton.get_bone_count():
		_point(skeleton, global, b, root, root_at, out, done)
	return out


static func _point(skeleton: Skeleton3D, global: Array[Quaternion], bone: int, root: int, root_at: Vector3, out: PackedVector3Array, done: PackedByteArray) -> Vector3:
	if done[bone] == 1:
		return out[bone]
	var parent := skeleton.get_bone_parent(bone)
	var at := root_at if bone == root or parent < 0 else _point(skeleton, global, parent, root, root_at, out, done) + global[parent] * skeleton.get_bone_rest(bone).origin
	out[bone] = at
	done[bone] = 1
	return at


## Kemik başına iki anahtar (dikişsiz döngü), göğüste küçük bir nefes; kök konumu sabit.
static func _write(skeleton: Skeleton3D, local: Array[Quaternion], hips_at: Vector3, prefix: String) -> Animation:
	var anim := Animation.new()
	anim.resource_name = String(ROLE)
	anim.length = LENGTH
	anim.loop_mode = Animation.LOOP_LINEAR
	var breath := skeleton.find_bone("Spine01")
	for b in skeleton.get_bone_count():
		if HandGrip.is_finger_bone(skeleton.get_bone_name(b)):
			continue
		var track := anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(track, NodePath("%s:%s" % [prefix, skeleton.get_bone_name(b)]))
		anim.rotation_track_insert_key(track, 0.0, local[b])
		if b == breath:
			anim.rotation_track_insert_key(track, LENGTH * 0.5, (local[b] * Quaternion(Vector3.RIGHT, deg_to_rad(BREATH_DEG))).normalized())
		anim.rotation_track_insert_key(track, LENGTH, local[b])
	var hips := skeleton.find_bone("Hips")
	var position_track := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(position_track, NodePath("%s:%s" % [prefix, skeleton.get_bone_name(hips)]))
	anim.position_track_insert_key(position_track, 0.0, hips_at)
	anim.position_track_insert_key(position_track, LENGTH, hips_at)
	ClipLibrary.complete_rest_tracks(anim, skeleton)
	return anim
