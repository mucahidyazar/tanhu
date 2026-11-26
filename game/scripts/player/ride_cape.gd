class_name RideCape
extends Node
## Mete'nin pelerin iskeleti (K58 #6, M5–M8; godot.md §6.6 «pelerin köşeleri kalçaya ağırlıklanır ya da SpringBoneSimulator3D ile salınır»;
## Yol Haritası mete-model-checks). Meshy ağında pelerinin kalça altı arka örtüsü (11.782 köşe) %93,9 bacaklara bağlıdır (uyluk, baldır, ayak):
## sürüş pozunda uyluk ata sarılınca örtünün %25'i at gövdesine girer, en çok 23 cm (ölçü RideFit, 2026-11-08). Çözüm kodladır, varlığa
## dokunulmaz (ağ, UV, doku, GLB ve klipler aynı kalır; kredi yok):
##   1. Kemik: oyuncu karakterinin iskeletine kalçanın çocuğu beş zincir (CHAINS: sol dış, sol iç, orta, sağ iç, sağ dış; zincir başına üç kemik,
##      JOINT_Y yüksekliklerinde) eklenir; dinlenmede pelerinin örtüsünün iç yüzü boyunca aşağı sarkar (örtü serilince bütün katları kemiğin
##      üstünde kalır).
##   2. Ağırlık (atın ağı): boya maskesinde pelerin olan (<id>_dye.png R) köşelerin bacak payı (uyluk, baldır, ayak; etekte baldır payı %30'a
##      çıkar) örtünün gerisinde (z ≤ SHEET_Z.y) bütünüyle, halkayla örtü arasında (SHEET_Z) yumuşakça zincirlere geçer: yanda iki komşu zincir,
##      boyda iki komşu kemik paylaşır; kalça, omurga ve kol payı kalır.
##      Uyluğun önündeki ve yanındaki etek halkası uyluğa bağlı kalır (sürüşte uyluğun üstüne serilir). Aynı yerdeki köşeler (UV dikişi) aynı
##      ağırlığı alır: ağırlık yalnız dinlenme konumunun işlevidir.
##   3. Seriliş (_Drape, iskeletin çocuğu, klipten sonra): atta her kemik yerçekimiyle sarkar, hızla arkaya akar (TRAIL_PER_MPS, en çok TRAIL_MAX;
##      yay yarı ömrü TRAIL_HALF_LIFE, M8), bacağın kapsülüne ve bineğin sırtına (Rideable.back_clearance; eyerin kaşı, sağrı) değmeden en az
##      dönüşle geriye ve yukarı açılır: örtü sağrıya serilir. Kalkış hemen, iniş yumuşak (DROP_HALF_LIFE): örtü titremez, gövdeye girmez.
##   4. İki ağ: yaya modelin kendi ağırlığıyla yürür (walk_mesh; yürüyüşte ve koşuda örtü bacak arasında en çok 3,3 cm açılır, M5), atta zincirli ağ
##      (ride_mesh) serilir. Seriliş yürüyüşte örtüyü bacak arasında 8 cm açıyordu, zincirin uyluğu izlemesi de (beş zincir kaba) 8 cm
##      (2026-11-08 ölçüsü). Binişin başında (dururken) zincirli ağa geçilir; zincir uyluğun deri matrisini taşır (orta zincir iki uyluğun
##      karışımı; FOLLOW_SPLIT): iki ağ aynı yeri verir. Oturunca seriliş RIDE_BLEND sn'de karışır (sıçrayışta bacak sırttan geçerken seriliş
##      karede 70 cm sıçrardı; M7); inişin başında uyluk izleyişine döner, inince yayanın ağına geçilir.
## Kurulum oyuncu karakterinde bir kezdir (PlayerController.use_profile; model değişince yeniden): oluşturucu, Destan Kitabı ve sinemadaki Mete
## modelin kendi ağırlığıyla kalır.
##   var cape := RideCape.install(avatar, controller)   # pelerinsiz modelde null
##   cape.solve_now()                                    # kemiklerin bu karedeki pozu (sınama; iskelet uzayı)

## Zincirlerin yanal yeri (m, modelin dinlenme uzayı; +X sol) ve eklemlerin yüksekliği (kökten eteğe; üç kemik).
const CHAINS: Array[float] = [0.3, 0.15, 0.0, -0.15, -0.3]
const JOINT_Y: Array[float] = [1.16, 0.93, 0.7, 0.47]
## Örtünün derinlik sınırı (m): z ≥ SHEET_Z.x uyluğa bağlı halka, z ≤ SHEET_Z.y örtü; arası yumuşak geçiş.
const SHEET_Z := Vector2(-0.04, -0.1)
## Eklemin boydaki paylaşım bandı (m; iki kemik yalnız eklemin bu kadar çevresinde paylaşır).
const JOINT_BLEND := 0.04
## Eklemin yerini veren köşelerin yanda ve boyda erimi (m) ve kemiğin iç yüzden bedene doğru payı.
const JOINT_REACH := Vector2(0.09, 0.13)
const INNER_PAD := 0.01
## Boya maskesinin eşiği ve örtünün en üstü (m; üstünde uyluk payı yoktur).
const DYE_CUT := 0.5
const TOP_Y := 1.25
## Seriliş: hızla arkaya akış (derece / (m/sn)) ve sınırı, yay yarı ömrü (sn; M8 0,2), inişin yarı ömrü (sn).
const TRAIL_PER_MPS := 5.0
const TRAIL_MAX := 55.0
const TRAIL_HALF_LIFE := 0.2
const DROP_HALF_LIFE := 0.12
## Bacak kapsülleri (m): uyluk ve baldırın yarıçapı, pelerinin kapsüle bıraktığı pay.
const THIGH_RADIUS := 0.1
const SHIN_RADIUS := 0.08
const LEG_GAP := 0.03
## Bineğin sırtına bırakılan pay (m; M6: ≤2 cm giriş; kemik örtünün iç yüzünde olduğu için yalnız kirişin ve yan zincirler arasının sarkması).
const BACK_GAP := 0.045
## Açılışın en büyük açısı (derece; sarkıştan geriye ve yukarı) ve taraması.
const OPEN_MAX := 165.0
const OPEN_STEPS := 22
const OPEN_REFINE := 6
## Yayanın uyluk izleyişi: zincirin sol uyluk payı smoothstep(-FOLLOW_SPLIT, FOLLOW_SPLIT, x) (+X sol); biniş ve inişte karışma süresi (sn).
const FOLLOW_SPLIT := 0.2
const RIDE_BLEND := 0.3

var skeleton: Skeleton3D
var mesh_instance: MeshInstance3D
## Hız ve binek kaynağı (PlayerController: get_speed, riding_node, get_facing_yaw).
var controller: Node
## Eklenen kemikler: [zincir][kemik] → kemik sırası; uzunlukları (m) ve dinlenme yönleri.
var bones: Array = []
## Seçilen (uyluk payı zincire geçen) köşe sayısı.
var moved_vertices := 0
## Son karede kemiklerin iskelet uzayındaki pozu (kemik → Transform3D; sınama ve RideFit okur) ve açılış açıları (derece).
var last_poses := {}
var last_open := {}

var _hips := -1
var _avatar: CharacterAvatar
var _drape: _Drape
var _trail := 0.0
var _open := {}
var _lengths := {}
## Serilişin payı (0 yaya: uyluk izleyişi, 1 atta: seriliş).
var _ride := 0.0
## Deri bağlarının pozları (kemik → bind; uyluklar ve zincirler): zincir, uyluğun deri matrisini aynen taşır.
var _binds := {}
## Yayanın ağı (modelin kendi ağırlığı) ve atın ağı (pelerin örtüsü zincirlerde).
var walk_mesh: Mesh
var ride_mesh: ArrayMesh


## Oyuncu karakterine kurar: iskelet, deri ve ağ (pelerin örtüsünün ağırlığı) değişir, seriliş değiştiricisi eklenir. Boya maskesi, kalça ya da
## uyluk yoksa null.
static func install(avatar: CharacterAvatar, p_controller: Node = null) -> RideCape:
	if avatar == null:
		return null
	var skel := avatar.get_skeleton()
	var mi := RideCape.skinned_mesh(avatar)
	if skel == null or mi == null or skel.find_bone("Hips") < 0 or skel.find_bone("LeftUpLeg") < 0:
		return null
	if skel.find_bone(RideCape.bone_name(0, 0)) >= 0:
		# Bu iskelete kurulmuş: kurulumun düğümü bulunur.
		for child in skel.get_children():
			if child is _Drape and is_instance_valid((child as _Drape).cape):
				return (child as _Drape).cape
		return null
	var dye := RideCape.dye_image(avatar.model_id)
	if dye == null:
		return null
	var cape := RideCape.new()
	cape.name = "RideCape"
	cape.controller = p_controller
	cape._avatar = avatar
	if not cape._build(skel, mi, dye):
		cape.free()
		return null
	avatar.add_child(cape)
	return cape


## Avatarın deri giydirilmiş ağı (yoksa null).
static func skinned_mesh(avatar: CharacterAvatar) -> MeshInstance3D:
	for node in avatar.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.skin != null and mi.mesh != null:
			return mi
	return null


## Kişinin boya maskesi (açık görüntü; yoksa null).
static func dye_image(model_id: String) -> Image:
	var path := "res://assets/characters/%s/%s_dye.png" % [model_id, model_id]
	if model_id.is_empty() or not ResourceLoader.exists(path):
		return null
	var tex := load(path) as Texture2D
	var img := tex.get_image() if tex else null
	if img == null:
		return null
	if img.is_compressed():
		img.decompress()
	return img


## Zincirin kemiğinin adı (CapeL2_1 gibi değil: Cape<zincir><kemik>, zincir 0 sol dış).
static func bone_name(chain: int, bone: int) -> String:
	return "Cape%d%d" % [chain, bone + 1]


## Pelerin kemiği mi (HandGrip'in parmakları gibi: klip ve aktarım yazmaz)?
static func is_cape_bone(p_name: String) -> bool:
	return p_name.length() == 6 and p_name.begins_with("Cape") and p_name.substr(4).is_valid_int()


func _build(skel: Skeleton3D, mi: MeshInstance3D, dye: Image) -> bool:
	skeleton = skel
	mesh_instance = mi
	_hips = skel.find_bone("Hips")
	var arrays := mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var bone_ids: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	if bone_ids.is_empty() or weights.is_empty():
		return false
	var stride := bone_ids.size() / verts.size()
	var skin := mi.skin.duplicate() as Skin
	var thigh_binds := {}
	var hips_bind := -1
	for i in skin.get_bind_count():
		var b := skin.get_bind_bone(i)
		var bname := skel.get_bone_name(b) if b >= 0 else String(skin.get_bind_name(i))
		if bname in ["LeftUpLeg", "RightUpLeg", "LeftLeg", "RightLeg", "LeftFoot", "RightFoot", "LeftToeBase", "RightToeBase"]:
			thigh_binds[i] = true
		if bname == "Hips":
			hips_bind = i
	if hips_bind < 0 or thigh_binds.is_empty():
		return false
	# Örtünün köşeleri: boya maskesinde pelerin, örtünün gerisinde ya da geçişte, uyluğa bağlı. Dikişin öbür yüzündeki köşe aynı yerdedir: ağırlık
	# yalnız konumdan hesaplandığı için onu da kapsamak için konum anahtarıyla seçilir.
	var w := dye.get_width()
	var h := dye.get_height()
	var dyed_at := {}
	var sheet := PackedVector3Array()
	for v in verts.size():
		var p := verts[v]
		if p.y >= TOP_Y or p.z > SHEET_Z.x:
			continue
		var c := dye.get_pixel(clampi(int(uvs[v].x * w), 0, w - 1), clampi(int(uvs[v].y * h), 0, h - 1))
		if c.r >= DYE_CUT:
			dyed_at[RideCape._key(p)] = true
			sheet.append(p)
	if dyed_at.is_empty():
		return false
	# Kemiklerin dinlenmesi: zincir başına eklemler örtünün üstünde (yandaki ve boydaki köşelerin derinliğinin ortancası).
	var joints := _chain_joints(sheet)
	var bind_hips := skin.get_bind_pose(hips_bind)
	var hips_rest := skel.get_bone_global_rest(_hips)
	var mesh_to_skel := hips_rest * bind_hips
	var first_new := skin.get_bind_count()
	var bind_of := {}
	for c in CHAINS.size():
		var chain_bones: Array[int] = []
		var parent := _hips
		var parent_rest := hips_rest
		for k in JOINT_Y.size() - 1:
			var head_m: Vector3 = joints[c][k]
			var tail_m: Vector3 = joints[c][k + 1]
			var head_s := mesh_to_skel * head_m
			var tail_s := mesh_to_skel * tail_m
			var y_axis := (tail_s - head_s).normalized()
			var x_axis := (mesh_to_skel.basis * Vector3.RIGHT).normalized()
			x_axis = (x_axis - y_axis * x_axis.dot(y_axis)).normalized()
			var basis := Basis(x_axis, y_axis, x_axis.cross(y_axis)).orthonormalized()
			var global_rest := Transform3D(basis, head_s)
			var bone := skel.add_bone(RideCape.bone_name(c, k))
			skel.set_bone_parent(bone, parent)
			var local := parent_rest.affine_inverse() * global_rest
			skel.set_bone_rest(bone, local)
			skel.set_bone_pose(bone, local)
			skin.add_named_bind(RideCape.bone_name(c, k), global_rest.affine_inverse() * mesh_to_skel)
			bind_of[Vector2i(c, k)] = first_new + c * (JOINT_Y.size() - 1) + k
			_lengths[bone] = head_m.distance_to(tail_m)
			chain_bones.append(bone)
			parent = bone
			parent_rest = global_rest
		bones.append(chain_bones)
	# Ağırlık: uyluk payı örtüde zincirlere geçer.
	var moved := 0
	for v in verts.size():
		var p := verts[v]
		if p.y >= TOP_Y or p.z > SHEET_Z.x or not dyed_at.has(RideCape._key(p)):
			continue
		var share := smoothstep(SHEET_Z.x, SHEET_Z.y, p.z)
		if share <= 0.0:
			continue
		var base := v * stride
		var thigh := 0.0
		var keep := {}
		for k in stride:
			var wt := weights[base + k]
			if wt <= 0.0:
				continue
			if thigh_binds.has(bone_ids[base + k]):
				thigh += wt
				keep[bone_ids[base + k]] = float(keep.get(bone_ids[base + k], 0.0)) + wt * (1.0 - share)
			else:
				keep[bone_ids[base + k]] = float(keep.get(bone_ids[base + k], 0.0)) + wt
		if thigh <= 0.0:
			continue
		var moved_w := thigh * share
		for pair: Array in RideCape.chain_weights(p):
			var bind: int = bind_of[pair[0]]
			keep[bind] = float(keep.get(bind, 0.0)) + moved_w * float(pair[1])
		var top := RideCape._top_four(keep)
		for k in stride:
			if k < top.size():
				bone_ids[base + k] = int(top[k][0])
				weights[base + k] = float(top[k][1])
			else:
				bone_ids[base + k] = 0
				weights[base + k] = 0.0
		moved += 1
	moved_vertices = moved
	arrays[Mesh.ARRAY_BONES] = bone_ids
	arrays[Mesh.ARRAY_WEIGHTS] = weights
	var old_mesh := mi.mesh
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, old_mesh.surface_get_material(0))
	# Serilen örtü dinlenme kutusunun dışına çıkar (sağrıya 0,7 m): kesilmesin.
	mesh.custom_aabb = old_mesh.custom_aabb if old_mesh.custom_aabb.has_volume() else old_mesh.get_aabb().grow(0.8)
	mi.skin = skin
	walk_mesh = old_mesh
	ride_mesh = mesh
	_drape = _Drape.new()
	_drape.name = "CapeDrape"
	_drape.cape = self
	skel.add_child(_drape)
	return true


## Modelin kökü (avatarın altındaki ilk Node3D; iskeletin sahibi).
func _avatar_model_root() -> Node3D:
	return skeleton.owner as Node3D if skeleton and skeleton.owner else skeleton


## Konum anahtarı (UV dikişindeki kopyalar aynı anahtarı alır).
static func _key(p: Vector3) -> Vector3i:
	return Vector3i((p * 10000.0).round())


## Zincirlerin eklem yerleri (modelin dinlenme uzayı): zincirin yanındaki (JOINT_REACH.x) ve eklemin boyundaki (JOINT_REACH.y) zincire geçen
## köşelerin bedene en yakını (en büyük z) ve INNER_PAD: kemik örtünün iç yüzündedir. Dinlenmede kemiğin gerisindeki köşe kemik arkaya yatınca onun
## üstüne gelir: örtünün bütün katları (iç etek kanadı ve dış pelerin) serilince kemiğin üstünde kalır.
func _chain_joints(sheet: PackedVector3Array) -> Array:
	var out := []
	for c in CHAINS.size():
		var row: Array[Vector3] = []
		for k in JOINT_Y.size():
			var inner := -INF
			for p in sheet:
				if absf(p.x - CHAINS[c]) <= JOINT_REACH.x and absf(p.y - JOINT_Y[k]) <= JOINT_REACH.y and smoothstep(SHEET_Z.x, SHEET_Z.y, p.z) >= 0.3:
					inner = maxf(inner, p.z)
			row.append(Vector3(CHAINS[c], JOINT_Y[k], (inner + INNER_PAD) if inner > -INF else -0.12))
		out.append(row)
	return out


## Bir köşenin zincir ağırlıkları (saf): yanda iki komşu zincir, boyda iki komşu kemik (kemiğin ortası tam payı alır). Döner: [[Vector2i(zincir,
## kemik), pay], ...], paylar toplamı 1.
static func chain_weights(p: Vector3) -> Array:
	var lateral := []
	var xs := CHAINS
	if p.x >= xs[0]:
		lateral = [[0, 1.0]]
	elif p.x <= xs[xs.size() - 1]:
		lateral = [[xs.size() - 1, 1.0]]
	else:
		for c in xs.size() - 1:
			if p.x <= xs[c] and p.x >= xs[c + 1]:
				var t := (xs[c] - p.x) / (xs[c] - xs[c + 1])
				lateral = [[c, 1.0 - t], [c + 1, t]]
				break
	# Boyda kemik eklemin yalnız JOINT_BLEND kadar çevresinde paylaşılır: serilen örtü eklemde bükülür, geniş paylaşım içteki katı ata çökertir.
	var vertical := [[0, 1.0]]
	for k in range(1, JOINT_Y.size() - 1):
		var joint := JOINT_Y[k]
		if p.y < joint - JOINT_BLEND:
			vertical = [[k, 1.0]]
		elif p.y <= joint + JOINT_BLEND:
			var t := smoothstep(joint + JOINT_BLEND, joint - JOINT_BLEND, p.y)
			vertical = [[k - 1, 1.0 - t], [k, t]]
			break
		else:
			break
	var out := []
	for a: Array in lateral:
		for b: Array in vertical:
			var share := float(a[1]) * float(b[1])
			if share > 0.0:
				out.append([Vector2i(int(a[0]), int(b[0])), share])
	return out


## En büyük dört ağırlık, toplamı 1 (saf): {bağ: ağırlık} → [[bağ, ağırlık], ...].
static func _top_four(weights: Dictionary) -> Array:
	var pairs := []
	for b: int in weights:
		if float(weights[b]) > 0.0:
			pairs.append([b, float(weights[b])])
	pairs.sort_custom(func(a: Array, b: Array) -> bool: return float(a[1]) > float(b[1]))
	pairs = pairs.slice(0, 4)
	var total := 0.0
	for pair: Array in pairs:
		total += float(pair[1])
	for pair: Array in pairs:
		pair[1] = float(pair[1]) / maxf(total, 0.000001)
	return pairs


# --- Seriliş -------------------------------------------------------------------------------------------------------

## Kemiklerin bu karedeki pozunu hesaplar (iskeletin klipli pozundan; uygulamaz). Döner: kemik → Transform3D (iskelet uzayı). delta 0 ise
## yaylar ilerlemez (sınama).
func solve_now(delta := 0.0) -> Dictionary:
	if skeleton == null or not is_instance_valid(skeleton) or not skeleton.is_inside_tree():
		return {}
	var xf := skeleton.global_transform
	var xf_inv := xf.affine_inverse()
	var speed := float(controller.call(&"get_speed")) if controller and controller.has_method(&"get_speed") else 0.0
	var mount: Rideable = controller.call(&"riding_node") if controller and controller.has_method(&"riding_node") else null
	if delta > 0.0:
		var goal := minf(speed * TRAIL_PER_MPS, TRAIL_MAX)
		_trail += (goal - _trail) * (1.0 - pow(0.5, delta / TRAIL_HALF_LIFE))
		# Seriliş yalnız oturunca: biniş ve inişin sıçrayışında bacak atın sırtından geçer, örtü o sürede uyluğu izler (seriliş karede yön
		# değiştirirdi; M7).
		var seated := mount != null and controller.has_method(&"is_riding") and bool(controller.call(&"is_riding"))
		_ride = move_toward(_ride, 1.0 if seated else 0.0, delta / RIDE_BLEND)
		_use_mesh(ride_mesh if mount or _ride > 0.0 else walk_mesh)
		if mount == null and _ride <= 0.0:
			# Yaya: modelin kendi ağırlığı (zincirlere bağlı köşe yok).
			last_poses = {}
			return {}
	var hips_pose := skeleton.get_bone_global_pose(_hips)
	# Binicinin arkası (dünya, yatay): avatarın ön yüzü yerel +Z'dir (Meshy kemiklerinin eksenleri kişiden kişiye değişir, kalçadan okunmaz).
	var facing := _avatar.global_basis.z if _avatar and is_instance_valid(_avatar) and _avatar.is_inside_tree() else xf.basis.z
	var back := -facing
	back.y = 0.0
	back = back.normalized() if back.length_squared() > 0.0001 else Vector3.BACK
	# open_dir'in ekseni: yukarı × arka (0 aşağı, 90 arkaya, 180 yukarı).
	var lateral := Vector3.UP.cross(back).normalized()
	var caps := _leg_capsules(xf)
	var poses := {}
	for c in bones.size():
		var chain: Array = bones[c]
		var parent_pose := hips_pose
		for k in chain.size():
			var bone: int = chain[k]
			var current := parent_pose * skeleton.get_bone_rest(bone)
			var joint_w := xf * current.origin
			var length := float(_lengths[bone])
			var open := _open_angle(joint_w, length, back, lateral, mount, caps)
			var applied := open
			if delta > 0.0:
				var prev := float(_open.get(bone, open))
				applied = open if open >= prev else prev + (open - prev) * (1.0 - pow(0.5, delta / DROP_HALF_LIFE))
				_open[bone] = applied
			var dir_w := RideCape.open_dir(back, lateral, _trail + applied)
			var dir_s := (xf_inv.basis * dir_w).normalized()
			var have := current.basis.y.normalized()
			var basis := current.basis
			if have.angle_to(dir_s) > 0.00001:
				basis = Basis(Quaternion(have, dir_s)) * current.basis
			var pose := Transform3D(basis, current.origin)
			poses[bone] = pose
			last_open[bone] = applied
			parent_pose = pose
	if _ride < 1.0:
		var follow := _follow_poses()
		for bone: int in poses:
			if follow.has(bone):
				poses[bone] = RideCape.blend_pose(follow[bone], poses[bone], _ride)
	last_poses = poses
	return poses


## MeshInstance3D'nin ağı (yüzeyin malzemeleri korunur).
func _use_mesh(m: Mesh) -> void:
	if m == null or mesh_instance == null or not is_instance_valid(mesh_instance) or mesh_instance.mesh == m:
		return
	var overrides: Array[Material] = []
	for s in mesh_instance.get_surface_override_material_count():
		overrides.append(mesh_instance.get_surface_override_material(s))
	mesh_instance.mesh = m
	for s in mini(overrides.size(), mesh_instance.get_surface_override_material_count()):
		mesh_instance.set_surface_override_material(s, overrides[s])


## Yayanın pozu (iskelet uzayı): her zincir yanındaki uyluğun (ortada ikisinin karışımı) dinlenmeden bu yana dönüşünü ve yerini taşır.
func _follow_poses() -> Dictionary:
	var out := {}
	var left := skeleton.find_bone("LeftUpLeg")
	var right := skeleton.find_bone("RightUpLeg")
	if left < 0 or right < 0:
		return out
	if _binds.is_empty():
		var skin := mesh_instance.skin if mesh_instance and is_instance_valid(mesh_instance) else null
		if skin == null:
			return out
		for i in skin.get_bind_count():
			var b := skin.get_bind_bone(i)
			if b < 0:
				b = skeleton.find_bone(String(skin.get_bind_name(i)))
			if b >= 0:
				_binds[b] = skin.get_bind_pose(i)
	if not _binds.has(left) or not _binds.has(right):
		return out
	# Zincirin deri matrisi uyluğunkiyle aynı: poz · bind = uyluğun pozu · uyluğun bind'ı.
	var skin_l := skeleton.get_bone_global_pose(left) * (_binds[left] as Transform3D)
	var skin_r := skeleton.get_bone_global_pose(right) * (_binds[right] as Transform3D)
	for c in bones.size():
		var share := smoothstep(-FOLLOW_SPLIT, FOLLOW_SPLIT, CHAINS[c])
		for bone: int in bones[c]:
			if not _binds.has(bone):
				continue
			var unbind := (_binds[bone] as Transform3D).affine_inverse()
			out[bone] = RideCape.blend_pose(skin_r * unbind, skin_l * unbind, share)
	return out


## İki pozun karışımı (saf): dönüş küresel, yer doğrusal, ölçek a'nınki. t 0 → a, 1 → b.
static func blend_pose(a: Transform3D, b: Transform3D, t: float) -> Transform3D:
	if t <= 0.0:
		return a
	if t >= 1.0:
		return b
	var scale := a.basis.get_scale()
	var q := a.basis.orthonormalized().get_rotation_quaternion().slerp(b.basis.orthonormalized().get_rotation_quaternion(), t)
	return Transform3D(Basis(q).scaled(scale), a.origin.lerp(b.origin, t))


## Sarkışın yönü (saf; dünya): yerçekimi, binicinin arkasına doğru açı kadar (derece) dönmüş: 0 aşağı, 90 arkaya yatay, 180 yukarı.
static func open_dir(back: Vector3, lateral: Vector3, degrees: float) -> Vector3:
	return Vector3.DOWN.rotated(lateral, -deg_to_rad(degrees)) if lateral.length_squared() > 0.0001 else Vector3.DOWN


## Kemiğin engele değmeden en az açılışı (derece, arkaya akışın üstüne): uç ve kiriş bacağın kapsülüne ve bineğin sırtına payını bırakır.
func _open_angle(joint: Vector3, length: float, back: Vector3, lateral: Vector3, mount: Rideable, caps: Array) -> float:
	var free_at := -1.0
	var blocked_at := 0.0
	for i in OPEN_STEPS + 1:
		var a := OPEN_MAX * float(i) / float(OPEN_STEPS)
		if a + _trail > OPEN_MAX:
			break
		if not _blocked(joint, RideCape.open_dir(back, lateral, _trail + a) * length, mount, caps):
			free_at = a
			break
		blocked_at = a
	if free_at < 0.0:
		return maxf(OPEN_MAX - _trail, 0.0)
	if free_at <= 0.0:
		return 0.0
	var lo := blocked_at
	var hi := free_at
	for i in OPEN_REFINE:
		var mid := (lo + hi) * 0.5
		if _blocked(joint, RideCape.open_dir(back, lateral, _trail + mid) * length, mount, caps):
			lo = mid
		else:
			hi = mid
	return hi


## Kemik (eklemden uca, üç noktada) bir engele değiyor mu?
func _blocked(joint: Vector3, along: Vector3, mount: Rideable, caps: Array) -> bool:
	for t: float in [0.34, 0.67, 1.0]:
		var p: Vector3 = joint + along * t
		for cap: Array in caps:
			var a: Vector3 = cap[0]
			var b: Vector3 = cap[1]
			if Geometry3D.get_closest_point_to_segment(p, a, b).distance_to(p) < float(cap[2]) + LEG_GAP:
				return true
		if mount and mount.back_clearance(p) < BACK_GAP:
			return true
	return false


## Bacağın kapsülleri (dünya): [uç, uç, yarıçap] uyluk ve baldır, iki yan.
func _leg_capsules(xf: Transform3D) -> Array:
	var out := []
	for side in ["Left", "Right"]:
		var up := skeleton.find_bone(side + "UpLeg")
		var knee := skeleton.find_bone(side + "Leg")
		var foot := skeleton.find_bone(side + "Foot")
		if up < 0 or knee < 0 or foot < 0:
			continue
		var a := xf * skeleton.get_bone_global_pose(up).origin
		var b := xf * skeleton.get_bone_global_pose(knee).origin
		var c := xf * skeleton.get_bone_global_pose(foot).origin
		out.append([a, b, THIGH_RADIUS])
		out.append([b, c, SHIN_RADIUS])
	return out


func _apply(delta: float) -> void:
	var poses := solve_now(delta)
	for c in bones.size():
		for bone: int in bones[c]:
			if poses.has(bone):
				skeleton.set_bone_global_pose(bone, poses[bone])


func _process(_delta: float) -> void:
	# Model değişti (oluşturucunun profili, beden): kurulum yeni iskelette yinelenir.
	if _avatar and is_instance_valid(_avatar) and _avatar.get_skeleton() != skeleton:
		var fresh := RideCape.install(_avatar, controller)
		if fresh != self:
			queue_free()


class _Drape:
	extends SkeletonModifier3D
	var cape: RideCape

	func _process_modification_with_delta(delta: float) -> void:
		if is_instance_valid(cape):
			cape._apply(delta)
