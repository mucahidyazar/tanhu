class_name ToolSwing
extends SkeletonModifier3D
## Balta ve kazma vuruşu (economy.md §3.1 «Vuruş», §3.8 «chop», «pick»): altta hangi klip oynarsa oynasın üst beden vuruşun evresine göre
## kurulur. Klip kütüphanesinde balta ve kazma klibi yoktur (K90: hareketler bir kez alınır, kredi harcanmaz): vuruş BowPose'un yolunda
## (KopuzPlay'in iki kemikli ters kinematiği) iki eli sapın üstünde tutar. Evreler prototipin Rig.play('chop', T)'si gibidir: 0–0,45 kaldır
## (eller sağ omzun üstünde, gövde geriye ve sağa döner), 0,45–0,72 indir (eller düğüme, gövde öne eğilir; temas 0,72), 0,72–1 dönüş.
## Kazmada kaldırış daha dik, iniş daha aşağıdır, diz hafif kırılır (crouch). Araç (balta ya da kazma) her kare iki elin arasına yazılır.
## Ağırlık (amount) 0'ken kemiğe dokunulmaz; chibi yedeğinde ve kemiği eksik iskelette eklenmez.
##   var swing := ToolSwing.attach(skeleton, prop, avatar.model_scale)
##   swing.target = node_world_point; swing.kind = "pick"; swing.phase = t / T; swing.amount = 1.0

const LEFT_ARM: Array[String] = ["LeftArm", "LeftForeArm", "LeftHand"]
const RIGHT_ARM: Array[String] = ["RightArm", "RightForeArm", "RightHand"]
const SPINE: Array = [["Spine02", 0.3], ["Spine01", 0.34], ["Spine", 0.36]]
## Evrelerin sınırları (k; temas 0,72).
const RAISE_END := 0.45
const CONTACT := 0.72
## Ellerin sap üstündeki yeri (m; sapın tutulan ucundan) ve sapın boyu.
const LOW_HAND := 0.08
const HIGH_HAND := 0.34
const HANDLE := 0.8
## Gövdenin dönüşü ve eğilmesi (radyan): kaldırışta, temasta.
const TWIST_RAISE := -0.5
const TWIST_HIT := 0.32
const PITCH_RAISE := -0.12
const PITCH_HIT := 0.38

## Dünya noktası: vuruşun hedefi (ağaç gövdesi 1 m'de, kaya ve damarın yüzü).
var target := Vector3.ZERO
## "chop" (balta) ya da "pick" (kazma).
var kind := "chop"
## Vuruşun evresi (0..1; t / T) ve ağırlığı (0..1).
var phase := 0.0
var amount := 0.0
var prop: Node3D
var model_scale := 1.0

## Son karenin hesabı (sınama ve inceleme): tutulan ucun omuzların ortasına göre yeri (m; karakter ekseninde: x sol, y yukarı, z ön) ve sapın
## yönü (karakter ekseninde).
var last_grip := Vector3.ZERO
var last_handle := Vector3.ZERO

var _axes := Basis.IDENTITY
var _axes_for: Skeleton3D
var _units := 100.0


## İskelete değiştirici ekler (kemikler eksikse null). prop: elde taşınan araç (her kare yeri yazılır).
static func attach(skeleton: Skeleton3D, p_prop: Node3D, p_model_scale: float = 1.0) -> ToolSwing:
	if skeleton == null:
		return null
	for bone_name in LEFT_ARM + RIGHT_ARM + ["Spine", "Hips"]:
		if skeleton.find_bone(bone_name) < 0:
			return null
	var swing := ToolSwing.new()
	swing.name = "ToolSwing"
	swing.prop = p_prop
	swing.model_scale = p_model_scale
	skeleton.add_child(swing)
	return swing


## Evrenin ağırlıklı karışımı: kaldır (0..1), indir (0..1) ve dönüş; saf. → [raise, hit] ağırlıkları.
static func phase_weights(k: float) -> Vector2:
	var u := clampf(k, 0.0, 1.0)
	if u < RAISE_END:
		return Vector2(smoothstep(0.0, RAISE_END, u), 0.0)
	if u < CONTACT:
		var s := (u - RAISE_END) / (CONTACT - RAISE_END)
		return Vector2(1.0 - s * s, s * s)
	var back := (u - CONTACT) / (1.0 - CONTACT)
	return Vector2(0.0, 1.0 - smoothstep(0.0, 1.0, back))


func _process_modification() -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	if _axes_for != skeleton:
		_axes = CineBow.character_axes(skeleton)
		_axes_for = skeleton
		var to_model := PoseFit.relative_transform(skeleton.owner as Node3D, skeleton)
		_units = 1.0 / maxf(to_model.basis.x.length() * model_scale, 0.000001)
	if amount <= 0.0001:
		if prop and is_instance_valid(prop):
			prop.visible = false
		return
	var w := ToolSwing.phase_weights(phase)
	var up := _axes.y
	var fwd := _axes.z
	var right := -_axes.x
	# Gövde: kaldırışta geriye ve sağa, temasta öne.
	var twist := (TWIST_RAISE * w.x + TWIST_HIT * w.y) * amount
	var pitch := (PITCH_RAISE * w.x + PITCH_HIT * w.y * (1.25 if kind == "pick" else 1.0)) * amount
	for row: Array in SPINE:
		var bone := skeleton.find_bone(str(row[0]))
		if bone < 0:
			continue
		var pose := skeleton.get_bone_global_pose(bone)
		pose.basis = Basis(_axes.x, pitch * float(row[1])) * Basis(up, twist * float(row[1])) * pose.basis
		skeleton.set_bone_global_pose(bone, pose)
	var l_sh := skeleton.get_bone_global_pose(skeleton.find_bone(LEFT_ARM[0])).origin
	var r_sh := skeleton.get_bone_global_pose(skeleton.find_bone(RIGHT_ARM[0])).origin
	var mid := (l_sh + r_sh) * 0.5
	var world := skeleton.global_transform
	var to_skel := world.affine_inverse()
	var tgt := to_skel * target
	var toward := tgt - mid
	if toward.length() < 0.001:
		toward = fwd * 0.6 * _units - up * 0.3 * _units
	var hit_dir := toward.normalized()
	# Sapın tutulan ucunun yeri ve sapın yönü: hazır (önde, belde), kaldırış (sağ omzun üstünde), temas (hedefe doğru, kol boyunda).
	var lift := 0.62 if kind == "pick" else 0.5
	var ready := mid + (fwd * 0.3 - up * 0.42 + right * 0.08) * _units
	var raised := mid + (up * lift + right * 0.16 - fwd * 0.06) * _units
	var reach := 0.5 if kind == "pick" else 0.46
	var hit := mid + hit_dir * reach * _units - up * (0.12 if kind == "pick" else 0.04) * _units
	var grip := ready.lerp(raised, w.x).lerp(hit, w.y) if w.y <= 0.0 else raised.lerp(hit, w.y)
	if phase >= CONTACT:
		grip = ready.lerp(hit, w.y)
	var h_ready := (fwd * 0.9 + up * 0.45).normalized()
	var h_raised := (up * 0.75 - fwd * 0.55 + right * 0.25).normalized()
	var h_hit := (hit_dir + fwd * 0.2 - up * 0.1).normalized()
	var handle := h_ready.slerp(h_raised, w.x).slerp(h_hit, w.y) if phase < CONTACT else h_ready.slerp(h_hit, w.y)
	var to_char := _axes.inverse()
	last_grip = to_char * ((grip - mid) / _units)
	last_handle = to_char * handle
	var low := grip + handle * LOW_HAND * _units
	var high := grip + handle * HIGH_HAND * _units
	_reach(skeleton, LEFT_ARM, low, -up, amount, mid + (-right * 0.35 - up * 0.25) * _units)
	_reach(skeleton, RIGHT_ARM, high, -up, amount, mid + (right * 0.45 - up * 0.1) * _units)
	if prop and is_instance_valid(prop):
		prop.visible = true
		var side := handle.cross(up).normalized() if absf(handle.dot(up)) < 0.98 else right
		var basis_skel := Basis(side, handle, side.cross(handle).normalized())
		var wb := world.basis.orthonormalized() * basis_skel
		prop.global_transform = Transform3D(wb.orthonormalized(), world * grip)


## Kol zincirini hedefe uzatır (BowPose._reach'in yolu): weight el hedefle eski yeri arasında; elbow_at dirseğin yönü.
func _reach(skeleton: Skeleton3D, chain: Array[String], p_target: Vector3, down: Vector3, weight: float, elbow_at := Vector3.ZERO) -> void:
	var arm := skeleton.find_bone(chain[0])
	var fore := skeleton.find_bone(chain[1])
	var hand := skeleton.find_bone(chain[2])
	var a := skeleton.get_bone_global_pose(arm)
	var f := skeleton.get_bone_global_pose(fore)
	var h := skeleton.get_bone_global_pose(hand)
	var bend_hint := (f.origin - a.origin).lerp(elbow_at - a.origin, weight) if elbow_at != Vector3.ZERO else Vector3.ZERO
	var solved := KopuzPlay.solve_two_bone(a.origin, f.origin, h.origin, h.origin.lerp(p_target, weight), down, bend_hint)
	var new_elbow: Vector3 = solved[0]
	var wrist: Vector3 = solved[1]
	var q1 := KopuzPlay.arc(f.origin - a.origin, new_elbow - a.origin)
	skeleton.set_bone_global_pose(arm, Transform3D(Basis(q1) * a.basis, a.origin))
	var q2 := KopuzPlay.arc(Basis(q1) * (h.origin - f.origin), wrist - new_elbow)
	var turn := Basis(q2) * Basis(q1)
	skeleton.set_bone_global_pose(fore, Transform3D(turn * f.basis, new_elbow))
	skeleton.set_bone_global_pose(hand, Transform3D(turn * h.basis, wrist))
