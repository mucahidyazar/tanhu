@tool
class_name HandGrip
extends SkeletonModifier3D
## Parmak kavraması (tools/hand_rig.py'nin eklediği kemikler): klip parmak izi taşımaz, el her karede burada kurulur. Varsayılan doğal yarı gevşek
## eldir; kişi bir şey tutarken kapanır (KopuzPlay, CineActor reach_grips ve gesture_grips). Dönüş kemiğin yerel +X ekseninde: artı açı parmağı avuca
## kapatır, her iki elde aynı işaret (hand_rig düğümü böyle yazar). Bir yana ait değerler parmak başına kapanma oranıdır: 0 dümdüz, 1 yumruk.
## Pozlar değer değişince hesaplanır; kare başına iş kemik başına tek atamadır (el başına 8-10 kemik). Kol ve bilek değişmez: başka değiştirici (ShoulderRelax, KopuzPlay,
## CineBow) el kemiğini oynatsa da parmaklar onunla gider, sıraları önemsizdir.
##
## Sinemada süre verilmez (seconds 0): değer sahnenin izinden yazılır, ileri sarmada da aynı kare çıkar. Süreli geçiş oyun içi içindir.
## Parmak kemiği olmayan iskelette (eski model, chibi yedeğinde iskelet yok) attach null döner, kullanan sessizce atlar.
##   var grip := HandGrip.attach(skeleton)
##   grip.set_grip(&"Right", 0.9, 0.3)       # sağ el 0,3 sn'de kapanır
##   grip.relax(&"Right", 0.3)               # doğal ele döner
##   grip.set_shape(&"Left", HandGrip.GRIP_NECK)

const SIDES: Array[StringName] = [&"Left", &"Right"]
## Başparmak yanından serçeye (tools/hand_rig.py FINGERS).
const FINGERS: Array[String] = ["Thumb", "Index", "Middle", "Ring", "Pinky"]
const JOINTS := 2
## Tam kapalı elde boğum açıları (derece): kök boğum, orta boğum. Orta boğum uç boğumun payını da taşır: kemik iki boğumludur.
const FULL_CURL: Array[Vector2] = [Vector2(35.0, 45.0), Vector2(75.0, 95.0), Vector2(80.0, 100.0), Vector2(85.0, 100.0), Vector2(90.0, 100.0)]
## Doğal el: serçeye doğru biraz daha kapalı.
const NATURAL_SHAPE: Array[float] = [0.25, 0.22, 0.28, 0.32, 0.36]
## Düz el (yere dayanan el; ClipLibrary.flatten_hand).
const OPEN_SHAPE: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
## Yumruğa yakın kavrama.
const FIST_SHAPE: Array[float] = [0.9, 1.0, 1.0, 1.0, 1.0]
## Kopuzun sapını saran sol el (KopuzPlay avucu sapın altına koyar): kısa yüzük ve serçe parmağı en çok kapanır, başparmak sapın arkasında kalır.
const GRIP_NECK: Array[float] = [0.3, 0.62, 0.68, 0.95, 1.0]
## Tellerin üstündeki sağ el: başparmak ve işaret parmağı yakın, öteki parmaklar gevşek.
const STRUM_SHAPE: Array[float] = [0.55, 0.55, 0.42, 0.4, 0.45]

var _shape := {&"Left": NATURAL_SHAPE, &"Right": NATURAL_SHAPE}
var _flat := {&"Left": false, &"Right": false}
var _tweens := {}
var _bones := PackedInt32Array()
var _rest: Array[Quaternion] = []
var _poses: Array[Quaternion] = []
## Kemik başına [yan, parmak, boğum] (hep aynı sırayla _bones ile).
var _slots := PackedInt32Array()
var _bones_for: Skeleton3D


## İskeletin parmak kemiği var mı?
static func has_fingers(skeleton: Skeleton3D) -> bool:
	if skeleton == null:
		return false
	for side: StringName in SIDES:
		if skeleton.find_bone("%sThumb1" % side) >= 0:
			return true
	return false


## Parmak kemiği adı mı (ClipRetarget ve dışa aktarma bu kemiklere klip yazmaz)?
static func is_finger_bone(bone_name: String) -> bool:
	for side: StringName in SIDES:
		if bone_name.begins_with(side):
			for finger: String in FINGERS:
				if bone_name.begins_with("%s%s" % [side, finger]):
					return true
	return false


## İskelete kavrama denetçisi ekler; parmak kemiği yoksa null.
static func attach(skeleton: Skeleton3D) -> HandGrip:
	if not HandGrip.has_fingers(skeleton):
		return null
	var grip := HandGrip.new()
	grip.name = "HandGrip"
	skeleton.add_child(grip)
	return grip


## Parmak boğumunun açısı (radyan; saf): parmak sırası, boğum sırası (0 kök, 1 orta), kapanma oranı.
static func joint_angle(finger: int, joint: int, amount: float) -> float:
	var full: Vector2 = FULL_CURL[finger]
	return deg_to_rad((full.x if joint == 0 else full.y) * amount)


## Yanı verilen kapanma oranına getirir (bütün parmaklar aynı oranda; 0 düz, 1 yumruk).
func set_grip(side: StringName, amount: float, seconds: float = 0.0) -> void:
	var a := clampf(amount, 0.0, 1.0)
	var values: Array[float] = [FIST_SHAPE[0] * a, a, a, a, a]
	set_shape(side, values, seconds)


## Doğal yarı gevşek ele döner.
func relax(side: StringName, seconds: float = 0.0) -> void:
	set_shape(side, NATURAL_SHAPE, seconds)


## Parmak başına kapanma oranı (FINGERS sırasıyla). seconds 0: hemen.
func set_shape(side: StringName, values: Array[float], seconds: float = 0.0) -> void:
	_kill_tween(side)
	if seconds <= 0.0 or not is_inside_tree():
		_shape[side] = values
		_refresh()
		return
	var from: Array[float] = _shape[side]
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		_shape[side] = HandGrip.blend(from, values, t)
		_refresh(), 0.0, 1.0, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tweens[side] = tween


## Yanın o anki kapanma oranları.
func shape_of(side: StringName) -> Array[float]:
	return _shape[side]


## Yere dayanan eller (clip_library.json pose_fix flatten_hand, kemik adlarıyla: ["LeftHand"]): klip oynarken düz durur, doğal kapanma parmağı zemine sokardı.
func set_flat_hands(hand_bones: Array) -> void:
	for side: StringName in SIDES:
		_flat[side] = hand_bones.has("%sHand" % side)
	_refresh()


## İki kapanma dizisi arası (saf).
static func blend(a: Array[float], b: Array[float], t: float) -> Array[float]:
	var out: Array[float] = []
	for i in a.size():
		out.append(lerpf(a[i], b[i], t))
	return out


func _process_modification() -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	if _bones_for != skeleton:
		_collect(skeleton)
	for i in _bones.size():
		skeleton.set_bone_pose_rotation(_bones[i], _poses[i])


func _collect(skeleton: Skeleton3D) -> void:
	_bones_for = skeleton
	_bones = PackedInt32Array()
	_slots = PackedInt32Array()
	_rest = []
	for s in SIDES.size():
		for f in FINGERS.size():
			for j in JOINTS:
				var bone := skeleton.find_bone("%s%s%d" % [SIDES[s], FINGERS[f], j + 1])
				if bone >= 0:
					_bones.append(bone)
					_slots.append_array(PackedInt32Array([s, f, j]))
					_rest.append(skeleton.get_bone_rest(bone).basis.get_rotation_quaternion())
	_poses.resize(_bones.size())
	_refresh()


func _refresh() -> void:
	if _bones_for == null:
		var skeleton := get_skeleton()
		if skeleton == null:
			return
		_collect(skeleton)
		return
	for i in _bones.size():
		var side := SIDES[_slots[i * 3]]
		var amounts: Array[float] = OPEN_SHAPE if _flat[side] else _shape[side]
		_poses[i] = _rest[i] * Quaternion(Vector3.RIGHT, HandGrip.joint_angle(_slots[i * 3 + 1], _slots[i * 3 + 2], amounts[_slots[i * 3 + 1]]))


func _kill_tween(side: StringName) -> void:
	var tween: Tween = _tweens.get(side)
	if tween and tween.is_valid():
		tween.kill()
	_tweens.erase(side)


## Klibin parmak izlerini sabit pozla yazar (belge sitesinde HandGrip yok, el düz durmasın): shape parmak başına kapanma, flat_hands düz kalacak el kemikleri (pose_fix flatten_hand).
## İz yoksa eklenir, varsa anahtarları değişir. Parmak kemiği yoksa bir şey yapmaz. Yazılan iz sayısını döndürür.
static func bake_pose(anim: Animation, skeleton: Skeleton3D, shape_values: Array[float] = NATURAL_SHAPE, flat_hands: Array = []) -> int:
	var prefix := ClipRetarget.track_prefix(anim)
	var end := maxf(anim.length, 0.0)
	var written := 0
	for side: StringName in SIDES:
		var amounts: Array[float] = OPEN_SHAPE if flat_hands.has("%sHand" % side) else shape_values
		for f in FINGERS.size():
			for j in JOINTS:
				var bone_name := "%s%s%d" % [side, FINGERS[f], j + 1]
				var bone := skeleton.find_bone(bone_name)
				if bone < 0:
					continue
				var path := NodePath("%s:%s" % [prefix, bone_name])
				var track := anim.find_track(path, Animation.TYPE_ROTATION_3D)
				if track >= 0:
					anim.remove_track(track)
				track = anim.add_track(Animation.TYPE_ROTATION_3D)
				anim.track_set_path(track, path)
				var pose := skeleton.get_bone_rest(bone).basis.get_rotation_quaternion() * Quaternion(Vector3.RIGHT, HandGrip.joint_angle(f, j, amounts[f]))
				anim.rotation_track_insert_key(track, 0.0, pose)
				if end > 0.0:
					anim.rotation_track_insert_key(track, end, pose)
				written += 1
	return written
