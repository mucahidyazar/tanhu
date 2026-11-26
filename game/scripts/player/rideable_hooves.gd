class_name RideableHooves
extends Node3D
## Toynakların yere basması (godot.md §6.7 «Toynak yere TwoBoneIK3D ile basar»; K65; Yol Haritası horse-rig). Bineğin (at, koyun) ve aynı
## iskelet planından çıkan her dört ayaklının (deve, köpek, maral, kurt, ceylan, sığır; tools/blender/quadruped_rig.py, bacak başına Upper,
## Lower, Cannon, Hoof) bacağı klibin pozunda kalır; toynak klibin zemin payıyla (klipte toynak ucunun model düzleminden yüksekliği) altındaki
## gerçek zemine konur: eğimde, yan yatık yamaçta ve basamakta. Düz zeminde hiçbir kemiğe dokunulmaz (menü karesi değişmez).
##
## Üç değiştirici iskeletin çocuğudur ve sırayla çalışır (klip uygulandıktan sonra, deri giydirmeden önce):
##   Planner      (GDScript) bacak başına hedef: toynak ucu zeminin klip payı kadar üstüne, basan toynak zeminin eğimine yatar; bilek (Hoof
##                kemiğinin kökü) hedefinden incik dünyada klibin yönünde kalacak biçimde karpus (ön bacakta diz, arkada topuk: Cannon'un kökü)
##                hedefi ve dirseğin (Lower) büküm yönü (pole: klipteki bükümün yönü) işaretlere yazılır.
##   TwoBoneIK3D  dört ayar: kök Upper (omuz, kalça), orta Lower (dirsek, diz), uç Cannon (karpus, topuk). Uç orta kemiğin doğrudan çocuğudur:
##                arada bükük bir eklem kalırsa (Lower → Cannon → Hoof zinciri) TwoBoneIK3D o eklemin klipteki bükümünü dinlenmedeki gibi sayar,
##                salınımda bilek hedeften 32–35 cm kaçar (2026-11-08 denemesi; doğrudan zincirde sapma 0).
##   Aligner      (GDScript) incik dünyada klibin yönüne, toynak hedefin yönüne döner (bilek hedefe iner, toynak ucu zemine).
## Gövde: basan toynakların en aşağıdakine ulaşamayan bacak için gövde iner (yan yamaçta alçak yandaki bacak açılır), hepsi yukarıdaysa kalkar
## (body_offset, artı aşağı; en çok OFFSET_MAX). Sahibi (Rideable) bunu Body düğümüne yazar: binici oturma noktasıyla aynı karede iner.
## Sıçramanın havasında kapanır (active false), yumuşakça açılıp kapanır.
##   var hooves := RideableHooves.attach(skeleton, terrain_shape)   # bacak kemikleri yoksa null
##   hooves.active = not airborne; body.position.y = lift - hooves.body_offset
##   hooves.last_soles                                              # son karede toynak uçları (dünya; sınama okur)

## Bacaklar ve bölümleri (quadruped_rig.py LEG_IDS, LEG_PARTS).
const LEGS: Array[String] = ["FrontL", "FrontR", "HindL", "HindR"]
## Toynağın «basıyor» sayıldığı klip yüksekliği (m): STANCE_H'nin altı tam basar (zemine yatar, gövdeyi taşır), SWING_H'nin üstü salınımdadır.
const STANCE_H := 0.03
const SWING_H := 0.12
## Gövdenin inip kalkması (m): en çok OFFSET_MAX, hedefe OFFSET_RATE (1/sn) ile yaklaşır.
const OFFSET_MAX := 0.3
const OFFSET_RATE := 12.0
## IK'nın açılıp kapanma hızı (1/sn): sıçramanın havasında kapanır.
const BLEND_RATE := 10.0
## Bu kadar küçük düzeltmede (m, derece) kemiklere dokunulmaz: düz zeminde poz klibinkiyle aynı kalır.
const EPSILON := 0.0005
const TILT_EPSILON_DEG := 0.2
## Toynağın zeminin eğimine yatışının sınırı (derece) ve eğimin ölçüldüğü aralık (m).
const TILT_MAX_DEG := 30.0
const NORMAL_STEP := 0.08
## Dizin büküm işaretinin eklemden uzaklığı (m) ve bacağın bükük sayıldığı sapma (orta eklemin kök-bilek çizgisinden uzaklığının boya oranı):
## BEND_STRAIGHT'in altında dinlenmedeki yön, BEND_CLEAR'ın üstünde klibin yönü.
const POLE_REACH := 0.6
const BEND_STRAIGHT := 0.02
const BEND_CLEAR := 0.06

var skeleton: Skeleton3D
## Zemin: height_at(x, z) taşıyan nesne (TerrainShape, OrdosGround) ya da Callable(x, z) -> float.
var ground: Variant
## Açık mı (sıçramanın havasında kapalı)?
var active := true
## Gövdenin inişi (m, artı aşağı; sahibi Body'ye yazar) ve hedefi.
var body_offset := 0.0
var wanted_offset := 0.0
## IK'nın etkisi (0..1; active'e doğru BLEND_RATE ile).
var blend := 1.0
## Son karede: bacak → toynak ucunun dünya konumu (IK'dan sonra), hedefi, klip payı (m) ve basma ağırlığı.
var last_soles := {}
var last_targets := {}
var last_clearance := {}
var last_stance := {}
## Son karede bacak başına klibin toynak ucu (dünya, IK'dan önce) ve hedefe gereken düşey yol (m).
var last_anim := {}
var last_need := {}
## Son karede bacak başına bilek hedefi, IK'dan sonra bilek (dünya) ve hedefin erimi (kökten uzaklığın iki bölümün boyuna oranı).
var last_fetlock_targets := {}
var last_fetlocks := {}
var last_reach := {}
## Son karede kemiklere dokunuldu mu?
var touched := false

var _legs := {}
var _planner: _Planner
var _aligner: _Aligner
var _ik: TwoBoneIK3D
var _targets := {}
var _poles := {}
var _model_root: Node3D
var _hoof_basis := {}
var _cannon_basis := {}


## İskeletin bacak kemikleri varsa kurar ve iskelete bağlar (değiştiriciler iskeletin çocuğu, işaretler bu düğümün). Yoksa null.
static func attach(p_skeleton: Skeleton3D, p_ground: Variant, model_root: Node3D = null) -> RideableHooves:
	if p_skeleton == null or not RideableHooves.has_legs(p_skeleton):
		return null
	var hooves := RideableHooves.new()
	hooves.name = "Hooves"
	hooves.skeleton = p_skeleton
	hooves.ground = p_ground
	hooves._model_root = model_root if model_root else p_skeleton.owner as Node3D
	p_skeleton.add_child(hooves)
	hooves._build()
	return hooves


## İskelette dört bacağın dört kemiği de var mı?
static func has_legs(p_skeleton: Skeleton3D) -> bool:
	for leg in LEGS:
		for part in ["Upper", "Lower", "Cannon", "Hoof"]:
			if p_skeleton.find_bone(RideableHooves.bone_name(leg, part)) < 0:
				return false
	return true


## FrontL, Upper → FrontUpperL (quadruped_rig.py leg_bone).
static func bone_name(leg: String, part: String) -> String:
	return leg.substr(0, leg.length() - 1) + part + leg.substr(leg.length() - 1)


## Kurulumu bırakır (değiştiriciler ve işaretler silinir; iskelet klibin pozunda kalır).
func detach() -> void:
	for node in [_planner, _ik, _aligner]:
		if is_instance_valid(node):
			(node as Node).queue_free()
	_planner = null
	_aligner = null
	_ik = null
	queue_free()


func _build() -> void:
	top_level = false
	for leg in LEGS:
		var ids := {}
		for part in ["Upper", "Lower", "Cannon", "Hoof"]:
			ids[part] = skeleton.find_bone(RideableHooves.bone_name(leg, part))
		# Toynak ucu: dinlenmede kemiğin +Y ekseni toynak ucuna (tabana) bakar (quadruped_rig.py frame_from_y); boyu tabana kadar.
		var hoof_rest := skeleton.get_bone_global_rest(ids["Hoof"])
		var to_model := _to_model()
		var origin_m := to_model * hoof_rest.origin
		var dir_m := (to_model.basis * hoof_rest.basis.y).normalized()
		var length_m := origin_m.y / maxf(-dir_m.y, 0.2)
		var scale := (to_model.basis * hoof_rest.basis.y).length()
		ids["hoof_len"] = length_m / maxf(scale, 0.000001)
		# Dirseğin (dizin) büküm yönü (dinlenmede, üst kemiğin yerel uzayında): orta eklemin kök-karpus çizgisinden sapması; bacak dinlenmede
		# düzse ön bacakta dirsek geriye, arka bacakta diz öne bakar (modelin ekseniyle).
		var upper_rest := skeleton.get_bone_global_rest(int(ids["Upper"]))
		var j1_rest := skeleton.get_bone_global_rest(int(ids["Lower"])).origin
		var carpus_rest := skeleton.get_bone_global_rest(int(ids["Cannon"])).origin
		var bend := j1_rest - (upper_rest.origin + carpus_rest) * 0.5
		if bend.length() < 0.01 * scale:
			bend = (Vector3.BACK if leg.begins_with("Front") else Vector3.FORWARD) * -1.0
		ids["bend"] = (upper_rest.basis.inverse() * bend).normalized()
		_legs[leg] = ids
		var target := Marker3D.new()
		target.name = "Target" + leg
		add_child(target)
		_targets[leg] = target
		var pole := Marker3D.new()
		pole.name = "Pole" + leg
		add_child(pole)
		_poles[leg] = pole
	_planner = _Planner.new()
	_planner.name = "HoofPlanner"
	_planner.hooves = self
	skeleton.add_child(_planner)
	_ik = TwoBoneIK3D.new()
	_ik.name = "HoofIK"
	skeleton.add_child(_ik)
	_ik.set_setting_count(LEGS.size())
	for i in LEGS.size():
		var leg: String = LEGS[i]
		_ik.set_root_bone(i, int(_legs[leg]["Upper"]))
		_ik.set_middle_bone(i, int(_legs[leg]["Lower"]))
		_ik.set_end_bone(i, int(_legs[leg]["Cannon"]))
		_ik.set_target_node(i, _ik.get_path_to(_targets[leg]))
		_ik.set_pole_node(i, _ik.get_path_to(_poles[leg]))
	_ik.influence = 0.0
	_aligner = _Aligner.new()
	_aligner.name = "HoofAligner"
	_aligner.hooves = self
	skeleton.add_child(_aligner)


## İskeletten model köküne dönüşüm (modelin zemin düzlemi y = 0).
func _to_model() -> Transform3D:
	if _model_root == null or not is_instance_valid(_model_root):
		return Transform3D.IDENTITY
	return PoseFit.relative_transform(_model_root, skeleton)


## Dünyada zeminin yüksekliği.
func ground_at(x: float, z: float) -> float:
	if ground is Callable:
		return float((ground as Callable).call(x, z))
	if ground is Object and (ground as Object).has_method(&"height_at"):
		return float((ground as Object).call(&"height_at", x, z))
	return 0.0


func has_ground() -> bool:
	return (ground is Callable and (ground as Callable).is_valid()) or (ground is Object and is_instance_valid(ground) and (ground as Object).has_method(&"height_at"))


## Gövdenin inişini hedefine yaklaştırır (sahibi her karede çağırır; döner: body_offset).
func step_offset(delta: float) -> float:
	var goal := wanted_offset if active and has_ground() else 0.0
	body_offset = lerpf(body_offset, goal, 1.0 - exp(-OFFSET_RATE * maxf(delta, 0.0)))
	if absf(body_offset) < 0.0001 and absf(goal) < 0.0001:
		body_offset = 0.0
	return body_offset


## Planlayıcının işi: hedefler, büküm yönleri, toynağın yatışı, gövdenin hedef inişi.
func _plan(delta: float) -> void:
	blend = move_toward(blend, 1.0 if active and has_ground() else 0.0, BLEND_RATE * maxf(delta, 0.0))
	touched = false
	if not has_ground() or blend <= 0.0 or not skeleton.is_inside_tree():
		_ik.influence = 0.0
		last_soles.clear()
		return
	var xf := skeleton.global_transform
	var to_model := _to_model()
	var body_up := xf.basis.y.normalized()
	var biggest := 0.0
	var lowest_need := INF
	for leg in LEGS:
		var ids: Dictionary = _legs[leg]
		var j0 := skeleton.get_bone_global_pose(int(ids["Upper"])).origin
		var j1 := skeleton.get_bone_global_pose(int(ids["Lower"])).origin
		var cannon := skeleton.get_bone_global_pose(int(ids["Cannon"]))
		var hoof := skeleton.get_bone_global_pose(int(ids["Hoof"]))
		var toe_s := hoof * Vector3(0.0, float(ids["hoof_len"]), 0.0)
		var toe_w := xf * toe_s
		var fetlock_w := xf * hoof.origin
		var clearance := maxf((to_model * toe_s).y, 0.0)
		var stance := 1.0 - smoothstep(STANCE_H, SWING_H, clearance)
		var floor_y := ground_at(toe_w.x, toe_w.z)
		var target_toe := Vector3(toe_w.x, floor_y + clearance, toe_w.z)
		var need := target_toe.y - toe_w.y
		last_anim[leg] = toe_w
		last_need[leg] = need
		if stance > 0.5:
			lowest_need = minf(lowest_need, need)
		# Basan toynak zeminin eğimine yatar (gövdenin «yukarı»sından zeminin normaline, basma ağırlığıyla).
		var normal := _normal_at(target_toe.x, target_toe.z)
		var tilt := Quaternion(body_up, normal) if body_up.angle_to(normal) > 0.0001 else Quaternion.IDENTITY
		var tilt_deg := rad_to_deg(tilt.get_angle())
		if tilt_deg > TILT_MAX_DEG:
			tilt = Quaternion.IDENTITY.slerp(tilt, TILT_MAX_DEG / tilt_deg)
		tilt = Quaternion.IDENTITY.slerp(tilt, stance)
		var hoof_world := Basis(tilt) * (xf.basis * hoof.basis)
		_hoof_basis[leg] = hoof_world
		# Toynak bilekte döner (bukağı esner), bilek yalnız düşeyde yer değiştirir: eğime yatan toynağın ucu yatıştan sonra nereye düşüyorsa orada
		# zemine konur (yokuşta uç kalkar, zemin de yükselir; düz yerde eğik gövdenin toynağı düzelince uç iner, bilek kalkar). Bileği yatay
		# kaydırmak duruşta düz olan bacağı uzatmak isterdi.
		var tilted_toe := fetlock_w + Basis(tilt) * (toe_w - fetlock_w)
		target_toe = Vector3(tilted_toe.x, ground_at(tilted_toe.x, tilted_toe.z) + clearance, tilted_toe.z)
		var target_fetlock := target_toe - Basis(tilt) * (toe_w - fetlock_w)
		# İncik dünyada klibin yönünde kalır (hizalayıcı döndürür): karpus bilekle aynı yolu gider.
		var target_carpus := xf * cannon.origin + (target_fetlock - fetlock_w)
		_cannon_basis[leg] = cannon.basis
		(_targets[leg] as Marker3D).global_position = target_carpus
		last_fetlock_targets[leg] = target_fetlock
		last_reach[leg] = (xf.affine_inverse() * target_carpus).distance_to(j0) / maxf(j0.distance_to(j1) + j1.distance_to(cannon.origin), 0.000001)
		# Büküm yönü: kol klipte bükükse klibin kendi bükümü (dirseğin kök-karpus çizgisinden sapması: IK klibin düzleminde kalır); düzse sapma
		# karede bir yana kaçar, dinlenmedeki yön üst kemiğin bugünkü dönüşüyle taşınır.
		var bend: Vector3 = j1 - (j0 + cannon.origin) * 0.5
		var bend_rest: Vector3 = (skeleton.get_bone_global_pose(int(ids["Upper"])).basis.orthonormalized() * (ids["bend"] as Vector3)).normalized()
		var bulge := bend.length() / maxf(j0.distance_to(cannon.origin), 0.000001)
		bend = bend_rest.slerp(bend.normalized(), smoothstep(BEND_STRAIGHT, BEND_CLEAR, bulge)) if bend.length_squared() > 1e-12 else bend_rest
		(_poles[leg] as Marker3D).global_position = xf * (j1 + bend * POLE_REACH / maxf(xf.basis.get_scale().x, 0.000001))
		biggest = maxf(biggest, maxf(target_fetlock.distance_to(fetlock_w), deg_to_rad(tilt.get_angle()) * float(ids["hoof_len"])))
		last_targets[leg] = target_toe
		last_clearance[leg] = clearance
		last_stance[leg] = stance
	if lowest_need < INF:
		wanted_offset = clampf(body_offset - lowest_need, -OFFSET_MAX, OFFSET_MAX)
	touched = biggest > EPSILON
	_ik.influence = blend if touched else 0.0


## Hizalayıcının işi: incik klibin yönüne (bilek hedefe iner), toynağın dünya dönüşü hedefinkine (IK'nın etkisiyle karışarak); son toynak
## uçları kaydedilir.
func _align() -> void:
	var xf := skeleton.global_transform
	for leg in LEGS:
		var ids: Dictionary = _legs[leg]
		if touched and _cannon_basis.has(leg):
			var cannon_bone := int(ids["Cannon"])
			var cannon := skeleton.get_bone_global_pose(cannon_bone)
			var cannon_scale := cannon.basis.get_scale()
			var cannon_have := cannon.basis.orthonormalized().get_rotation_quaternion()
			var cannon_want := (_cannon_basis[leg] as Basis).orthonormalized().get_rotation_quaternion()
			skeleton.set_bone_global_pose(cannon_bone, Transform3D(Basis(cannon_have.slerp(cannon_want, blend)).scaled(cannon_scale), cannon.origin))
		var bone := int(ids["Hoof"])
		var pose := skeleton.get_bone_global_pose(bone)
		if touched and _hoof_basis.has(leg):
			var want := (xf.basis.inverse() * (_hoof_basis[leg] as Basis)).orthonormalized()
			var have := pose.basis.orthonormalized()
			var scale := pose.basis.get_scale()
			var mixed := Basis(have.get_rotation_quaternion().slerp(want.get_rotation_quaternion(), blend)).scaled(scale)
			pose = Transform3D(mixed, pose.origin)
			skeleton.set_bone_global_pose(bone, pose)
		last_soles[leg] = xf * (pose * Vector3(0.0, float(ids["hoof_len"]), 0.0))
		last_fetlocks[leg] = xf * pose.origin


## Zeminin normali (sonlu farklarla).
func _normal_at(x: float, z: float) -> Vector3:
	var s := NORMAL_STEP
	var dx := ground_at(x + s, z) - ground_at(x - s, z)
	var dz := ground_at(x, z + s) - ground_at(x, z - s)
	return Vector3(-dx, 2.0 * s, -dz).normalized()


class _Planner:
	extends SkeletonModifier3D
	var hooves: RideableHooves

	func _process_modification_with_delta(delta: float) -> void:
		if is_instance_valid(hooves):
			hooves._plan(delta)


class _Aligner:
	extends SkeletonModifier3D
	var hooves: RideableHooves

	func _process_modification_with_delta(_delta: float) -> void:
		if is_instance_valid(hooves):
			hooves._align()
