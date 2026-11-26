class_name ClipRetarget
extends RefCounted
## Meshy iskeletleri arasında animasyon klibi aktarımı (ör. taşıyıcının bekleme klibi → Baba).
##
## Meshy'nin otomatik iskeletlerinde kemik adları ve hiyerarşi aynıdır ama kemiklerin YEREL eksenleri ve eklem yerleri
## karakterden karaktere değişir; yerel dönüşler doğrudan kopyalanamaz, aktarım iskelet uzayında yapılır. İki iskeletin de
## dinlenme (bind) pozu T-pozdur.
##
## Meshy klibi iskelete yazarken iskeletin şekline bağlı sabit bir fark ekler: Δ_iskelet(t) = Δ_başvuru(t) · C (K92). Bu sabit
## hareket değildir; zikzak omurgalı bir iskelette 40° bel kırığı olur. Her iskeletin C'si data/rig_calibration.json'dadır
## (tools/rig_fix.py kendi bedava yürüme klibinden ölçer). Aktarım kaynağınkini çıkarır, hedefinkini ekler:
##   Δ_hedef = Δ_kaynak · C_kaynak⁻¹ · C_hedef ;  G_hedef = Δ_hedef · G_hedef(dinlenme)
## Böylece klip hedefe, Meshy onu hedef için üretmiş gibi gelir. İskelet kimliği verilmezse C birimdir.
##
## İki yöntem var:
##   ROTATION:  her kemik yukarıdaki gibi döner.
##   DIRECTION: önce ROTATION gibi döndürülür, sonra kol kemikleri (eklemden çocuk ekleme uzanan çizgi) kaynağın pozdaki
##              kemik yönüne en kısa yoldan çevrilir; kemiğin kendi ekseni etrafındaki burulması Δ'dan gelir. Bacaklar
##              iki kemikli çözümle kurulur: ayak bileği iki kalça ekleminin ortasına göre kaynaktakiyle aynı yere gider (boy
##              oranıyla), dizin bükülme yönü kaynaktan gelir. Böylece kaynağın kalça eklemlerindeki yükseklik farkı ayağı havada
##              bırakmaz. İskeletin bu noktadaki sabit yan ve ön-arka farkı (F, rig_calibration.json feet; taşıyıcıda sağ bilek 5 cm
##              dışarıda) çıkarılır, hedefinki eklenir: yoksa bir bacak düzleşir, öteki bükülür. Bacak zincirin SOFT_REACH'inden sonra
##              yumuşak uzar: diz dümdüz kilitlenmez, kilide girerken sıçramaz. Gövde, el ve ayak ROTATION ile aktarılır.
## Kök kemiğin konumu dinlenmeden farkıyla ve iki iskeletin kalça yüksekliği oranıyla ölçeklenir; diğer kemiklerin konumları
## hedefin kendi kemik boylarında kalır (kol ve bacak boyu bozulmaz).
## Klipte izi olmayan kemik dinlenme pozundadır (Godot'nun içe aktarıcısı yalnızca dinlenme pozuna eşit izleri siler).

enum Mode { ROTATION, DIRECTION }

const DEFAULT_FPS := 30.0
## İskeletlerin sabit farkları (tools/rig_fix.py yazar).
const CALIBRATION_PATH := "res://data/rig_calibration.json"
## Bacak çözümünde kaynağın dizi kalça-bilek çizgisinden bundan az (iskelet birimi) sapıyorsa bükülme yönü hedefin önüdür.
const POLE_MIN := 0.5
## Bacak zincirin bu oranına kadar hedefe tam gider, sonrasında hedefe yaklaşır ama zinciri aşmaz. Sert sınırda diz, hedef sınıra
## değdiği karede 6 cm sıçrıyordu (2026-11-06, 8 kişi × 16 klip: düz kare 13.114 → 73, en büyük diz adımı 6,3 → 2,3 cm).
const SOFT_REACH := 0.97

## data/rig_calibration.json'un iskeletleri (ilk okumada yüklenir) ve çevrilmiş kuaterniyonları.
static var _calibration := {}
static var _quaternions := {}
## Bir kemiğin yönü belirlenirken tercih edilen çocuk kemik (birden çok çocuğu olanlar için).
const PRIMARY_CHILD := {"Hips": "Spine02", "Spine": "neck", "Head": "head_end"}
## DIRECTION yönteminde yönü kaynağa eşlenen kemikler (adında bunlardan biri geçen: kol ve bacak zinciri).
const LIMB_KEYS: Array[String] = ["shoulder", "arm", "leg", "foot"]


## Kaynak iskelet için yazılmış klibi hedef iskelete aktarır; yeni bir Animation döndürür.
## Klip fps kare/saniyeyle yeniden örneklenir (son kare tam klip sonundadır).
## direction_keys: DIRECTION yönteminde yönü eşlenecek kemik adı parçaları ("*" = kök dışındaki her kemik).
## source_rig, target_rig: data/rig_calibration.json'daki iskelet kimlikleri (boşsa sabit fark yok sayılır).
static func retarget(source_anim: Animation, source: Skeleton3D, target: Skeleton3D, mode: Mode = Mode.DIRECTION, fps: float = DEFAULT_FPS, direction_keys: Array[String] = LIMB_KEYS, source_rig: String = "", target_rig: String = "") -> Animation:
	var result := Animation.new()
	result.length = source_anim.length
	result.loop_mode = source_anim.loop_mode
	if source_anim.get_track_count() == 0:
		return result
	var prefix := track_prefix(source_anim)
	var source_rest := rest_rotations(source)
	var source_rest_global := global_rotations(source, source_rest)
	var target_rest_global := global_rotations(target, rest_rotations(target))
	var target_rest_points := rest_points(target)
	var bone_map := _bone_map(source, target)
	var children := primary_children(target)
	var legs := _leg_chains(source, target) if mode == Mode.DIRECTION else []
	var leg_scale := _leg_scale(source, target, legs)
	var solved := {}
	for chain: Dictionary in legs:
		solved[chain["up"]] = true
		solved[chain["leg"]] = true
	var limbs := PackedByteArray()
	for b in target.get_bone_count():
		var is_direction := mode == Mode.DIRECTION and target.get_bone_parent(b) >= 0 and is_limb(target.get_bone_name(b), direction_keys)
		limbs.append(1 if is_direction and not solved.has(b) and not _is_foot(target.get_bone_name(b)) else 0)
	var source_cal := _bone_calibration(calibration_of(source_rig), target)
	var target_cal := _bone_calibration(calibration_of(target_rig), target)
	var source_feet := _foot_offsets(source_rig)
	var target_feet := _foot_offsets(target_rig)
	var ratio := hips_ratio(source, target)
	var root := _first_root(target)
	var source_root := _first_root(source)
	var rot_tracks := {}
	var pos_tracks := {}
	for b in target.get_bone_count():
		if bone_map[b] < 0:
			continue
		var path := NodePath("%s:%s" % [prefix, target.get_bone_name(b)])
		rot_tracks[b] = result.add_track(Animation.TYPE_ROTATION_3D)
		result.track_set_path(rot_tracks[b], path)
		var source_pos := source_anim.find_track(path, Animation.TYPE_POSITION_3D)
		if target.get_bone_parent(b) < 0 and source_pos >= 0:
			var pt := result.add_track(Animation.TYPE_POSITION_3D)
			result.track_set_path(pt, path)
			pos_tracks[b] = [pt, source_pos]
	for t in sample_times(source_anim.length, fps):
		var source_local := local_rotations_at(source_anim, source, source_rest, prefix, t)
		var source_pose := global_rotations(source, source_local)
		var source_points := pose_points(source, source_local, source_pose, source_anim, prefix, t)
		var target_pose: Array[Quaternion] = []
		target_pose.resize(target.get_bone_count())
		for b in target.get_bone_count():
			var sb: int = bone_map[b]
			if sb < 0:
				target_pose[b] = target_rest_global[b]
				continue
			var delta: Quaternion = source_pose[sb] * ((source_cal[b] as Quaternion) * source_rest_global[sb]).inverse()
			var turn: Quaternion = delta * (target_cal[b] as Quaternion)
			var q := (turn * target_rest_global[b]).normalized()
			var c: int = children[b]
			if limbs[b] == 1 and c >= 0 and bone_map[c] >= 0:
				var rest_dir := target_rest_points[c] - target_rest_points[b]
				var want := source_points[bone_map[c]] - source_points[sb]
				q = (shortest_arc(turn * rest_dir, want) * q).normalized()
			target_pose[b] = q
		var root_position := target_rest_points[root] if root >= 0 else Vector3.ZERO
		if root >= 0 and source_root >= 0:
			root_position = target_rest_points[root] + (source_points[source_root] - source.get_bone_global_rest(source_root).origin) * ratio
		if not legs.is_empty():
			var root_turn: Quaternion = target_pose[root] * target_rest_global[root].inverse()
			# Kalçanın iskeletten arınmış dönüşü: F kalça çerçevesindedir, yatarken ve otururken kalçayla döner.
			var body_turn: Quaternion = source_pose[source_root] * ((source_cal[root] as Quaternion) * source_rest_global[source_root]).inverse()
			var target_hips := Vector3.ZERO
			var source_hips := Vector3.ZERO
			for chain: Dictionary in legs:
				target_hips += root_position + root_turn * (target_rest_points[chain["up"]] - target_rest_points[root])
				source_hips += source_points[chain["s_up"]]
			target_hips /= legs.size()
			source_hips /= legs.size()
			for chain: Dictionary in legs:
				var side: String = chain["side"]
				var source_foot: Vector3 = source_points[chain["s_foot"]] - source_hips - body_turn * (source_feet.get(side, Vector3.ZERO) as Vector3)
				var goal: Vector3 = target_hips + source_foot * leg_scale + body_turn * (target_feet.get(side, Vector3.ZERO) as Vector3)
				_solve_leg(chain, target_pose, target_rest_global, target_rest_points, source_points, root_turn, root_position + root_turn * (target_rest_points[chain["up"]] - target_rest_points[root]), goal)
		for b in rot_tracks:
			var parent := target.get_bone_parent(b)
			var local := target_pose[b] if parent < 0 else target_pose[parent].inverse() * target_pose[b]
			result.rotation_track_insert_key(rot_tracks[b], t, local.normalized())
		for b in pos_tracks:
			var pair: Array = pos_tracks[b]
			result.position_track_insert_key(pair[0], t, root_position)
	return result


## İskeletin data/rig_calibration.json kaydı (yoksa boş).
static func calibration_entry(rig_id: String) -> Dictionary:
	if _calibration.is_empty():
		var data: Variant = ClipLibrary.read_json(CALIBRATION_PATH)
		_calibration = data.get("rigs", {}) if data is Dictionary else {}
		if _calibration.is_empty():
			_calibration = {"": {}}
	return _calibration.get(rig_id, {})


## İskeletin sabit farkları {kemik adı: Quaternion} (data/rig_calibration.json; kimlik boşsa ya da yoksa boş).
static func calibration_of(rig_id: String) -> Dictionary:
	if rig_id.is_empty():
		return {}
	if not _quaternions.has(rig_id):
		var out := {}
		var rig: Variant = calibration_entry(rig_id)
		if (rig as Dictionary).get("bones") is Dictionary:
			for bone: String in rig["bones"]:
				var q: Array = rig["bones"][bone]
				out[bone] = Quaternion(q[0], q[1], q[2], q[3]).normalized()
		else:
			push_warning("[clip_retarget] %s için kalibrasyon yok: tools/rig_fix.py --calibrate" % rig_id)
		_quaternions[rig_id] = out
	return _quaternions[rig_id]


## İskeletin bilek farkları (F): {"Left": Vector3, "Right": Vector3}, kalça çerçevesinde, iskeletin biriminde. Kimlik boşsa ya da
## kayıtta yoksa boş (fark yok sayılır).
static func _foot_offsets(rig_id: String) -> Dictionary:
	var out := {}
	if rig_id.is_empty():
		return out
	var feet: Variant = calibration_entry(rig_id).get("feet")
	if feet is Dictionary:
		for side: String in feet:
			out[side] = Vector3(feet[side][0], feet[side][1], feet[side][2])
	return out


## Hedef iskeletin kemik sırasıyla sabit farklar (kemik yoksa birim).
static func _bone_calibration(table: Dictionary, skel: Skeleton3D) -> Array:
	var out := []
	for b in skel.get_bone_count():
		out.append(table.get(skel.get_bone_name(b), Quaternion.IDENTITY))
	return out


## İki iskelette de tam olan bacaklar: [{side, up, leg, foot (hedef kemikleri), s_up, s_leg, s_foot (kaynak)}].
static func _leg_chains(source: Skeleton3D, target: Skeleton3D) -> Array:
	var out := []
	for side in ["Left", "Right"]:
		var chain := {
			"up": target.find_bone(side + "UpLeg"), "leg": target.find_bone(side + "Leg"), "foot": target.find_bone(side + "Foot"),
			"s_up": source.find_bone(side + "UpLeg"), "s_leg": source.find_bone(side + "Leg"), "s_foot": source.find_bone(side + "Foot"),
		}
		if chain.values().all(func(b: int) -> bool: return b >= 0):
			chain["side"] = side
			out.append(chain)
	return out


## Bacakların boy oranı (hedef / kaynak; dinlenmede kalça-bilek uzaklığı). Ayak bileği iki kalça ekleminin ortasına göre bu oranla
## taşınır: bacağın açıklığı kaynaktakiyle aynı kalır, kaynağın kalça eklemleri arasındaki yükseklik farkı ayağa geçmez.
static func _leg_scale(source: Skeleton3D, target: Skeleton3D, legs: Array) -> float:
	var target_length := 0.0
	var source_length := 0.0
	for chain: Dictionary in legs:
		target_length += target.get_bone_global_rest(chain["foot"]).origin.distance_to(target.get_bone_global_rest(chain["up"]).origin)
		source_length += source.get_bone_global_rest(chain["s_foot"]).origin.distance_to(source.get_bone_global_rest(chain["s_up"]).origin)
	return target_length / source_length if source_length > 0.0 else 1.0


## Bacağı iki kemikli çözümle kurar: bilek goal'e gider, zincirin sonuna yaklaşırken yumuşar (_soft_reach). Dizin bükülme yönü kaynaktan gelir.
## Uyluk ve baldır kendi eksenleri etrafındaki burulmasını korur, yalnız yönleri çevrilir.
static func _solve_leg(chain: Dictionary, pose: Array[Quaternion], rest_global: Array[Quaternion], rest_points: PackedVector3Array, source_points: PackedVector3Array, root_turn: Quaternion, hip: Vector3, goal: Vector3) -> void:
	var up: int = chain["up"]
	var leg: int = chain["leg"]
	var foot: int = chain["foot"]
	var thigh := rest_points[leg].distance_to(rest_points[up])
	var shin := rest_points[foot].distance_to(rest_points[leg])
	var to_goal := goal - hip
	var distance := maxf(_soft_reach(to_goal.length(), thigh + shin), absf(thigh - shin) * 1.001 + 0.001)
	var along := to_goal.normalized() if to_goal.length_squared() > 1e-8 else Vector3.DOWN
	var source_hip: Vector3 = source_points[chain["s_up"]]
	var source_line: Vector3 = (source_points[chain["s_foot"]] - source_hip).normalized()
	var source_knee: Vector3 = source_points[chain["s_leg"]] - source_hip
	var pole: Vector3 = source_knee - source_line * source_knee.dot(source_line)
	if pole.length() < POLE_MIN:
		pole = root_turn * Vector3.BACK
	pole = (pole - along * pole.dot(along))
	pole = pole.normalized() if pole.length_squared() > 1e-8 else root_turn * Vector3.BACK
	var x := (thigh * thigh - shin * shin + distance * distance) / (2.0 * distance)
	var height := sqrt(maxf(thigh * thigh - x * x, 0.0))
	var knee := hip + along * x + pole * height
	var ankle := hip + along * distance
	var up_turn: Quaternion = pose[up] * rest_global[up].inverse()
	pose[up] = (shortest_arc(up_turn * (rest_points[leg] - rest_points[up]), knee - hip) * pose[up]).normalized()
	var leg_turn: Quaternion = pose[leg] * rest_global[leg].inverse()
	pose[leg] = (shortest_arc(leg_turn * (rest_points[foot] - rest_points[leg]), ankle - knee) * pose[leg]).normalized()


## Bacağın uzanacağı uzaklık: zincirin SOFT_REACH'ine kadar istenen, sonrasında zincire üstel yaklaşır (hiç erişmez).
static func _soft_reach(distance: float, reach: float) -> float:
	var start := reach * SOFT_REACH
	if distance <= start:
		return distance
	var room := reach - start
	return start + room * (1.0 - exp((start - distance) / room))


## _soft_reach'in tersi: yumuşamış uzaklığı veren istek. Zincirin sonunda (ters sonsuza gider) zincirin %99,99'una göre okunur.
static func _soft_reach_inverse(soft: float, reach: float) -> float:
	var start := reach * SOFT_REACH
	if soft <= start:
		return soft
	var room := reach - start
	return start - room * log(maxf(1.0 - (soft - start) / room, 0.0001))


static func _is_foot(bone_name: String) -> bool:
	return bone_name.to_lower().contains("foot")


## Kemik yönü eşlenecek zincirde mi (varsayılan: kol ve bacak)? Uç kemikler (el, ayak parmağı) hariç.
static func is_limb(bone_name: String, keys: Array[String] = LIMB_KEYS) -> bool:
	var lower := bone_name.to_lower()
	if lower.contains("hand") or lower.contains("toe"):
		return false
	for key in keys:
		if key == "*" or lower.contains(key):
			return true
	return false


## a yönünü b yönüne çeviren en kısa dönüş (biri sıfırsa birim dönüş).
static func shortest_arc(a: Vector3, b: Vector3) -> Quaternion:
	if a.length_squared() < 1e-12 or b.length_squared() < 1e-12:
		return Quaternion.IDENTITY
	var u := a.normalized()
	var v := b.normalized()
	var d := u.dot(v)
	if d > 0.999999:
		return Quaternion.IDENTITY
	if d < -0.999999:
		var axis := u.cross(Vector3.RIGHT)
		if axis.length_squared() < 1e-6:
			axis = u.cross(Vector3.UP)
		return Quaternion(axis.normalized(), PI)
	return Quaternion(u, v)


## Klibin kemik izlerinin düğüm yolu (ör. "Armature/Skeleton3D").
static func track_prefix(anim: Animation) -> String:
	for i in anim.get_track_count():
		var path := anim.track_get_path(i)
		if path.get_subname_count() > 0:
			return String(path.get_concatenated_names())
	return "Skeleton3D"


## Örnekleme zamanları: 0, 1/fps, 2/fps, ... ve tam olarak length.
static func sample_times(length: float, fps: float) -> PackedFloat32Array:
	var times := PackedFloat32Array()
	var step := 1.0 / maxf(fps, 1.0)
	var t := 0.0
	while t < length - step * 0.5:
		times.append(t)
		t += step
	times.append(length)
	return times


## İki iskeletin kök kemik (Hips) dinlenme yüksekliklerinin oranı (hedef / kaynak).
static func hips_ratio(source: Skeleton3D, target: Skeleton3D) -> float:
	var sb := _first_root(source)
	var tb := _first_root(target)
	if sb < 0 or tb < 0:
		return 1.0
	var sy := source.get_bone_rest(sb).origin.y
	var ty := target.get_bone_rest(tb).origin.y
	return ty / sy if absf(sy) > 0.0001 else 1.0


## Her kemiğin yön belirleyen çocuğu (yoksa -1): PRIMARY_CHILD'daki ya da tek/ilk çocuk.
static func primary_children(skel: Skeleton3D) -> PackedInt32Array:
	var result := PackedInt32Array()
	result.resize(skel.get_bone_count())
	result.fill(-1)
	for b in skel.get_bone_count():
		var parent := skel.get_bone_parent(b)
		if parent >= 0 and result[parent] < 0:
			result[parent] = b
	for name in PRIMARY_CHILD:
		var b := skel.find_bone(name)
		var c := skel.find_bone(PRIMARY_CHILD[name])
		if b >= 0 and c >= 0 and skel.get_bone_parent(c) == b:
			result[b] = c
	return result


## Her kemiğin yerel dinlenme dönüşü.
static func rest_rotations(skel: Skeleton3D) -> Array[Quaternion]:
	var result: Array[Quaternion] = []
	for b in skel.get_bone_count():
		result.append(skel.get_bone_rest(b).basis.get_rotation_quaternion())
	return result


## Eklemlerin dinlenme pozundaki iskelet uzayı konumları.
static func rest_points(skel: Skeleton3D) -> PackedVector3Array:
	var result := PackedVector3Array()
	for b in skel.get_bone_count():
		result.append(skel.get_bone_global_rest(b).origin)
	return result


## Klibin t anındaki yerel dönüşleri (izi olmayan kemik dinlenme pozunda kalır).
static func local_rotations_at(anim: Animation, skel: Skeleton3D, rest: Array[Quaternion], prefix: String, t: float) -> Array[Quaternion]:
	var result: Array[Quaternion] = rest.duplicate()
	for b in skel.get_bone_count():
		var track := anim.find_track(NodePath("%s:%s" % [prefix, skel.get_bone_name(b)]), Animation.TYPE_ROTATION_3D)
		if track >= 0:
			result[b] = anim.rotation_track_interpolate(track, t)
	return result


## Pozdaki eklem konumları (iskelet uzayı): kemik boyları dinlenme pozundan, kök konumu klipten.
static func pose_points(skel: Skeleton3D, local: Array[Quaternion], global: Array[Quaternion], anim: Animation, prefix: String, t: float) -> PackedVector3Array:
	var result := PackedVector3Array()
	result.resize(skel.get_bone_count())
	var done := PackedByteArray()
	done.resize(skel.get_bone_count())
	for b in skel.get_bone_count():
		_resolve_point(skel, global, anim, prefix, t, b, result, done)
	return result


static func _resolve_point(skel: Skeleton3D, global: Array[Quaternion], anim: Animation, prefix: String, t: float, bone: int, out: PackedVector3Array, done: PackedByteArray) -> Vector3:
	if done[bone] == 1:
		return out[bone]
	var parent := skel.get_bone_parent(bone)
	var offset := skel.get_bone_rest(bone).origin
	var track := anim.find_track(NodePath("%s:%s" % [prefix, skel.get_bone_name(bone)]), Animation.TYPE_POSITION_3D)
	if track >= 0:
		offset = anim.position_track_interpolate(track, t)
	var p := offset
	if parent >= 0:
		p = _resolve_point(skel, global, anim, prefix, t, parent, out, done) + global[parent] * offset
	out[bone] = p
	done[bone] = 1
	return p


## Yerel dönüşlerden iskelet uzayındaki (global) dönüşler. Ebeveyn her zaman çocuktan önce hesaplanır.
static func global_rotations(skel: Skeleton3D, local: Array[Quaternion]) -> Array[Quaternion]:
	var result: Array[Quaternion] = []
	result.resize(skel.get_bone_count())
	var done := PackedByteArray()
	done.resize(skel.get_bone_count())
	for b in skel.get_bone_count():
		_resolve_global(skel, local, b, result, done)
	return result


static func _resolve_global(skel: Skeleton3D, local: Array[Quaternion], bone: int, out: Array[Quaternion], done: PackedByteArray) -> Quaternion:
	if done[bone] == 1:
		return out[bone]
	var parent := skel.get_bone_parent(bone)
	var q := local[bone]
	if parent >= 0:
		q = _resolve_global(skel, local, parent, out, done) * q
	out[bone] = q
	done[bone] = 1
	return q


## Hedef kemik → aynı adlı kaynak kemik (yoksa -1). Parmak kemiği aktarılmaz: Meshy klibi parmak izi taşımaz, el HandGrip'ten gelir; el kemiği kalibrasyonlu döndüğü için
## kaynağın dinlenme parmağını kopyalamak sabit bir açı bırakırdı.
static func _bone_map(source: Skeleton3D, target: Skeleton3D) -> PackedInt32Array:
	var result := PackedInt32Array()
	for b in target.get_bone_count():
		var bone_name := target.get_bone_name(b)
		result.append(-1 if HandGrip.is_finger_bone(bone_name) else source.find_bone(bone_name))
	return result


static func _first_root(skel: Skeleton3D) -> int:
	for b in skel.get_bone_count():
		if skel.get_bone_parent(b) < 0:
			return b
	return -1
