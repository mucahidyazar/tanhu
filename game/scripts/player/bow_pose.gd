class_name BowPose
extends SkeletonModifier3D
## Oyuncak yayla nişan pozu: altta hangi klip oynarsa oynasın (yerde kütüphanenin yan duruş klibi bow_aim, binekte binme klibi) üst beden hedefe göre
## kurulur. Göğüs yan döner (sol omuz hedefe), baş hedefe bakar, sol kol yayı hedefe uzatır, sağ el kirişi çeneye çeker; ellerin yeri ve yönü
## iki kemikli ters kinematikle (KopuzPlay'in yolu) yay kabzasından ve gezden çıkar: klip bir yöne bakar, hedef her yerde olabilir. Ağırlık (amount) 0'ken kemiğe dokunulmaz: yay sırtta durur (Spine01'in arkasında).
## Yay yeri her kare burada hesaplanır ve prop'a yazılır (iskeletin son pozuna bağlı): gerilmemişken sırtta, nişanda kabzası sol avuçta.
##
## Kemik adları Meshy iskeletinindir. Eksik kemikte değiştirici bir şey yapmaz; chibi yedeğinde hiç eklenmez, ChildArcher yayı gövdenin önüne koyar.
##   var pose := BowPose.attach(skeleton, prop, avatar.model_scale)
##   pose.aim_dir = dir; pose.amount = 1.0; pose.draw = 0.6

const LEFT_ARM: Array[String] = ["LeftArm", "LeftForeArm", "LeftHand"]
const RIGHT_ARM: Array[String] = ["RightArm", "RightForeArm", "RightHand"]
## Göğsün dönüşünün omurgaya dağılımı (toplamı 1).
const SPINE: Array = [["Spine02", 0.26], ["Spine01", 0.34], ["Spine", 0.4]]
## Baş ve boyunun payı (başın hedefe kalan açısı).
const NECK_SHARE := 0.4
const HEAD_SHARE := 0.6
const HEAD_LIMIT := deg_to_rad(75.0)
## Göğsün hedefe göre yan duruşu (radyan; sol omuz hedefe) ve omurganın en çok dönüşü.
const STANCE := deg_to_rad(55.0)
const MAX_TWIST := deg_to_rad(85.0)
## Kabzanın kol boyuna oranı (kol tam uzamaz), yayın eğikliği (üst kol sağa yatık; atlı okçu duruşu, derece).
const GRIP_REACH := 0.96
const CANT_DEG := 12.0
## Avucun kabzaya uzaklığı (m) ve avuç ortasının el kemiğindeki payı (KopuzPlay.PALM_SHARE).
const GRIP_STANDOFF := 0.018
const PALM_SHARE := 0.75
## Bilekteki burulmanın ön kola geçen payı (KopuzPlay.FOREARM_TWIST).
const FOREARM_TWIST := 0.6
## Gezin çeneye göre yeri (m; aşağı, sağa): sağ el çenenin altında durur.
const CHIN_DROP := 0.045
const CHIN_RIGHT := 0.035
## Sırtta duruş (m ve derece): omurganın arkasında, çapraz.
const STOW_BACK := 0.085
const STOW_TILT_DEG := 58.0

## Dünya uzayında birim atış yönü.
var aim_dir := Vector3.BACK
## Pozun ağırlığı (0..1) ve kirişin gerilmesi (0..1).
var amount := 0.0
var draw := 0.0
## Yay ve okun görünüşü (yeri her kare buraya yazılır).
var prop: ToyBowProp
var model_scale := 1.0
## Son hesaplanan: kabzanın ve gezin dünya konumu.
var grip_world := Vector3.ZERO
var nock_world := Vector3.ZERO

var _axes := Basis.IDENTITY
var _axes_for: Skeleton3D
var _units := 100.0


## İskelete değiştirici ekler (kemikler eksikse null).
static func attach(skeleton: Skeleton3D, p_prop: ToyBowProp, p_model_scale: float = 1.0) -> BowPose:
	if skeleton == null:
		return null
	for bone_name in LEFT_ARM + RIGHT_ARM:
		if skeleton.find_bone(bone_name) < 0:
			return null
	var pose := BowPose.new()
	pose.name = "BowPose"
	pose.prop = p_prop
	pose.model_scale = p_model_scale
	skeleton.add_child(pose)
	return pose


func _process_modification() -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	if _axes_for != skeleton:
		_axes = CineBow.character_axes(skeleton)
		_axes_for = skeleton
		var to_model := PoseFit.relative_transform(skeleton.owner as Node3D, skeleton)
		_units = 1.0 / maxf(to_model.basis.x.length() * model_scale, 0.000001)
	var world := skeleton.global_transform
	var world_basis := world.basis.orthonormalized()
	var stow := _stow_transform(skeleton)
	if amount <= 0.0001:
		_place_prop(world, world_basis, stow, 0.0)
		return
	var to_skeleton := world.affine_inverse()
	var dir := (to_skeleton.basis * aim_dir).normalized()
	var up := _axes.y
	_turn_chest(skeleton, dir, up)
	_turn_head(skeleton, dir, up)
	var grip := _grip_transform(skeleton, dir, up)
	var chin := skeleton.get_bone_global_pose(skeleton.find_bone("Head")).origin
	var right := dir.cross(up).normalized()
	chin += (right * CHIN_RIGHT - up * CHIN_DROP) * _units
	var full := maxf((grip.origin - chin).dot(dir), 0.0)
	var rest_back := -prop.rest_nock().z * _units if prop else 0.05 * _units
	var nock := grip.origin - dir * lerpf(rest_back, maxf(full, rest_back), clampf(draw, 0.0, 1.0))
	_hold_grip(skeleton, grip, dir, right)
	_hold_string(skeleton, nock, dir, right, up)
	_place_prop(world, world_basis, stow.interpolate_with(grip, smoothstep(0.0, 1.0, amount)), (grip.origin - nock).dot(dir) / _units)
	grip_world = world * grip.origin
	nock_world = world * nock


## Yayın dünya dönüşümü ve gezi.
func _place_prop(world: Transform3D, world_basis: Basis, in_skeleton: Transform3D, nock_back: float) -> void:
	if prop == null or not is_instance_valid(prop):
		return
	prop.global_transform = Transform3D(world_basis * in_skeleton.basis, world * in_skeleton.origin)
	prop.set_nock(Vector3(0.0, 0.0, -nock_back) if nock_back > 0.0 else prop.rest_nock())


## Sırtta duruş (iskelet uzayı): Spine01'in arkasında, sırtı arkaya bakar, kol çapraz.
func _stow_transform(skeleton: Skeleton3D) -> Transform3D:
	var bone := skeleton.find_bone("Spine01")
	var pose := skeleton.get_bone_global_pose(bone) if bone >= 0 else Transform3D.IDENTITY
	var chest := pose.basis.orthonormalized() * skeleton.get_bone_global_rest(bone).basis.orthonormalized().inverse() if bone >= 0 else Basis.IDENTITY
	var forward := chest * _axes.z
	var up := chest * _axes.y
	var left := chest * _axes.x
	var limb := (up * cos(deg_to_rad(STOW_TILT_DEG)) + left * sin(deg_to_rad(STOW_TILT_DEG))).normalized()
	var back := -forward
	var side := limb.cross(back).normalized()
	return Transform3D(Basis(side, limb, back), pose.origin - forward * STOW_BACK * _units)


## Göğüs: atış yönünden STANCE kadar sağa dönük yön; dönüş omurgaya dağılır.
func _turn_chest(skeleton: Skeleton3D, dir: Vector3, up: Vector3) -> void:
	var chest_goal := Basis(up, -STANCE) * dir
	var want := clampf(BowPose.flat_angle(_axes.z, chest_goal, up), -MAX_TWIST, MAX_TWIST) * amount
	for row: Array in SPINE:
		var bone := skeleton.find_bone(str(row[0]))
		if bone < 0:
			continue
		var pose := skeleton.get_bone_global_pose(bone)
		pose.basis = Basis(up, want * float(row[1])) * pose.basis
		skeleton.set_bone_global_pose(bone, pose)


## Baş hedefe döner: kalan açı boyun ve başa paylaşılır.
func _turn_head(skeleton: Skeleton3D, dir: Vector3, up: Vector3) -> void:
	var head := skeleton.find_bone("Head")
	var neck := skeleton.find_bone("neck")
	if head < 0 or neck < 0:
		return
	var head_pose := skeleton.get_bone_global_pose(head)
	var turned := head_pose.basis.orthonormalized() * skeleton.get_bone_global_rest(head).basis.orthonormalized().inverse()
	var want := clampf(BowPose.flat_angle(turned * _axes.z, dir, up), -HEAD_LIMIT, HEAD_LIMIT) * amount
	var neck_pose := skeleton.get_bone_global_pose(neck)
	neck_pose.basis = Basis(up, want * NECK_SHARE) * neck_pose.basis
	skeleton.set_bone_global_pose(neck, neck_pose)
	head_pose = skeleton.get_bone_global_pose(head)
	head_pose.basis = Basis(up, want * HEAD_SHARE) * head_pose.basis
	skeleton.set_bone_global_pose(head, head_pose)


## Kabzanın duruşu (iskelet uzayı): sol omuzdan atış yönüne kol boyunca; +Y kol (üst uç biraz sağa yatık), +Z atış yönü.
func _grip_transform(skeleton: Skeleton3D, dir: Vector3, up: Vector3) -> Transform3D:
	var arm := skeleton.find_bone(LEFT_ARM[0])
	var fore := skeleton.find_bone(LEFT_ARM[1])
	var hand := skeleton.find_bone(LEFT_ARM[2])
	var shoulder := skeleton.get_bone_global_pose(arm).origin
	var length := skeleton.get_bone_global_rest(fore).origin.distance_to(skeleton.get_bone_global_rest(arm).origin) + skeleton.get_bone_global_rest(hand).origin.distance_to(skeleton.get_bone_global_rest(fore).origin)
	var limb := Basis(dir, deg_to_rad(CANT_DEG)) * (up - dir * up.dot(dir)).normalized()
	var side := limb.cross(dir).normalized()
	return Transform3D(Basis(side, limb, dir), shoulder + dir * length * GRIP_REACH)


## Sol el kabzayı tutar: avuç atış yönüne bakar, parmaklar sağa sarar.
func _hold_grip(skeleton: Skeleton3D, grip: Transform3D, dir: Vector3, right: Vector3) -> void:
	var middle := skeleton.find_bone("LeftMiddle1")
	var palm_at := grip.origin - dir * GRIP_STANDOFF * _units
	var down := -_axes.y
	if middle < 0:
		_reach(skeleton, LEFT_ARM, palm_at, down, amount)
		return
	var rest := skeleton.get_bone_rest(middle)
	var goal := KopuzPlay.hand_basis(rest, right * 0.86 + dir * 0.5, dir)
	_reach(skeleton, LEFT_ARM, palm_at - goal * (rest.origin * PALM_SHARE), down, amount, goal)


## Sağ el kirişi tutar: parmaklar öne, avuç içeri (sola); dirsek geride ve yukarıda.
func _hold_string(skeleton: Skeleton3D, nock: Vector3, dir: Vector3, right: Vector3, up: Vector3) -> void:
	var middle := skeleton.find_bone("RightMiddle1")
	var elbow := skeleton.get_bone_global_pose(skeleton.find_bone(RIGHT_ARM[0])).origin + (-dir * 0.72 + right * 0.5 + up * 0.2) * _units
	if middle < 0:
		_reach(skeleton, RIGHT_ARM, nock, -up, amount, null, elbow)
		return
	var rest := skeleton.get_bone_rest(middle)
	var goal := KopuzPlay.hand_basis(rest, dir * 0.95 - up * 0.3, -right)
	_reach(skeleton, RIGHT_ARM, nock - goal * rest.origin, -up, amount, goal, elbow)


## Kol zincirini hedefe uzatır (KopuzPlay._reach): weight el hedefle eski yeri arasında; hand_goal elin yönü, burulmanın payı ön kola geçer; elbow_at dirseğin yönü.
func _reach(skeleton: Skeleton3D, chain: Array[String], target: Vector3, down: Vector3, weight: float, hand_goal: Variant = null, elbow_at := Vector3.ZERO) -> void:
	var arm := skeleton.find_bone(chain[0])
	var fore := skeleton.find_bone(chain[1])
	var hand := skeleton.find_bone(chain[2])
	var a := skeleton.get_bone_global_pose(arm)
	var f := skeleton.get_bone_global_pose(fore)
	var h := skeleton.get_bone_global_pose(hand)
	var bend_hint := (f.origin - a.origin).lerp(elbow_at - a.origin, weight) if elbow_at != Vector3.ZERO else Vector3.ZERO
	var solved := KopuzPlay.solve_two_bone(a.origin, f.origin, h.origin, h.origin.lerp(target, weight), down, bend_hint)
	var new_elbow: Vector3 = solved[0]
	var wrist: Vector3 = solved[1]
	var q1 := KopuzPlay.arc(f.origin - a.origin, new_elbow - a.origin)
	skeleton.set_bone_global_pose(arm, Transform3D(Basis(q1) * a.basis, a.origin))
	var q2 := KopuzPlay.arc(Basis(q1) * (h.origin - f.origin), wrist - new_elbow)
	var turn := Basis(q2) * Basis(q1)
	var fore_basis := turn * f.basis
	var hand_turned := turn * h.basis
	if hand_goal is Basis:
		var goal: Quaternion = hand_turned.get_rotation_quaternion().slerp((hand_goal as Basis).get_rotation_quaternion(), weight)
		var axis := (wrist - new_elbow).normalized()
		var relaxed := (fore_basis * skeleton.get_bone_rest(hand).basis).get_rotation_quaternion()
		fore_basis = Basis(axis, KopuzPlay.twist_about(goal * relaxed.inverse(), axis) * FOREARM_TWIST) * fore_basis
		hand_turned = Basis(goal)
	skeleton.set_bone_global_pose(fore, Transform3D(fore_basis, new_elbow))
	skeleton.set_bone_global_pose(hand, Transform3D(hand_turned, wrist))


## İki yön arasındaki açı (radyan; yatay düzlemde, up çevresinde, -π..π; saf).
static func flat_angle(from: Vector3, to: Vector3, up: Vector3) -> float:
	var a := from - up * from.dot(up)
	var b := to - up * to.dot(up)
	if a.length_squared() < 0.0000001 or b.length_squared() < 0.0000001:
		return 0.0
	return a.signed_angle_to(b, up)
