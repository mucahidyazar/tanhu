class_name StoryMover
extends RefCounted
## Sahnenin kişisini (CineActor) yürütür ya da bir bineğin (Rideable: koyun ya da at) sırtında sürer: Çocukluk'ta Luhun'un hızlı koyunu,
## Yançi'nin ve sayıcının yürüyüşü, Teoman ve beylerinin atları (story.md §5). Yol düz çizgilerle yol noktalarını izler; yön yumuşakça döner.
## Yürüyen kişide avatarın yürüme ya da koşu klibi gerçek hızına göre seçilir (CharacterAvatar.set_locomotion: ayak kaymaz). Binen
## kişinin bineği yürür (Rideable.place, drive: koyunun ya da atın klipleri ve atın toynak efektleri), kişi oturma noktasına oturur: poz
## oyuncunun binme pozuyla aynı koddan çıkar (RidePose; oturma klibinden ve bineğin satırından türer, kalçanın yeri
## PlayerController._seated_transform'unki). Çarpışma yoktur: oyuncu sürüye değmez, sürü ona yol verir (HerdField.set_avoid_nodes); yollar
## engelsiz yere çizilir (data/story/childhood/scene.json). Düzenle giden atlılar (RiderColumn) yolu kendileri hesaplar ve move_to ile sürer.
##   var mover := StoryMover.new(actor, world.get_terrain_shape(), sheep)   # ride null: yürür
##   mover.seat()                                     # binicinin pozu ve yeri
##   mover.go([Vector3(27, 0, 28), Vector3(37, 0, 18)], 2.6)
##   mover.tick(delta)                                # her kare; varınca arrived() true
##   mover.move_to(at, yaw, 1.3, delta)               # dışarıdan sürülen (düzen): yer, yön, hız

## Yürürken hızlanma (m/sn²) ve dönüş keskinliği.
const ACCEL := 3.0
const TURN := 6.0
## Yol noktasına bu uzaklıkta varılmış sayılır (m).
const REACH := 0.25
## Bineğin eğimini ölçen yarı boy (m): satırında half_length yoksa (koyun) bu.
const PITCH_HALF_LENGTH := 0.42
## Binicinin kalçası ölçü yokken sırtın bu kadar üstünde (m; PlayerController.RIDE_HIPS_LIFT).
const RIDE_HIPS_LIFT := 0.11
## Elin yünü kavrayışı (PlayerController.GRIP_WOOL).
const GRIP_WOOL := 0.75

var actor: CineActor
## Binek (koyun ya da at; yoksa null: yürür).
var ride: Rideable
## Zeminin yüzü (height_at taşıyan; OrdosGround).
var shape: RefCounted

var _path := PackedVector3Array()
var _goal_speed := 0.0
var _speed := 0.0
var _yaw := 0.0
var _seated := false
var _hips_offset := Vector3(0.0, 0.5, 0.0)
var _hips_lift := RIDE_HIPS_LIFT
var _face_at := Vector3.INF


func _init(p_actor: CineActor, p_shape: RefCounted, p_ride: Rideable = null) -> void:
	actor = p_actor
	shape = p_shape
	ride = p_ride
	if actor:
		_yaw = actor.rotation.y
	if ride:
		_yaw = ride.rotation.y


## Bineğe oturtur: binme pozu oturma klibinden ve bineğin satırından kurulur (bir kez), binek binilmiş sayılır, kişi sırta konur.
func seat() -> void:
	if ride == null or actor == null or actor.avatar == null:
		return
	var avatar := actor.avatar
	var skeleton := avatar.get_skeleton()
	if skeleton and not avatar.available_roles().has(RidePose.ROLE):
		var sit := ClipVariety.library().clip_for(avatar.model_id, "sit", skeleton)
		var pose := RidePose.build(skeleton, sit, Mount.row_of(ride.mount_id).get("seat", {}), avatar.model_scale)
		if pose:
			avatar.set_role_clip(RidePose.ROLE, pose)
	_hips_offset = RidePose.hips_in_model(skeleton, avatar.model_scale) if skeleton else Vector3(0.0, 0.5, 0.0)
	var measured := ClipVariety.library().hips_height_for(avatar.model_id, "sit") if skeleton else 0.0
	_hips_lift = (measured if measured > 0.0 else RIDE_HIPS_LIFT) * avatar.model_scale
	avatar.play_pose(RidePose.ROLE)
	avatar.snap_transition()
	avatar.set_grip(&"Left", GRIP_WOOL, 0.0)
	avatar.set_grip(&"Right", GRIP_WOOL, 0.0)
	ride.set_ridden(true)
	_seated = true
	_yaw = ride.rotation.y
	_place_rider()


func is_seated() -> bool:
	return _seated


## Yolu verir: noktalar dünya konumudur (y zeminden alınır), hız m/sn.
func go(points: Array, speed: float) -> void:
	_path = PackedVector3Array()
	for p: Variant in points:
		if p is Vector3:
			_path.append(p)
	_goal_speed = maxf(speed, 0.0)
	_face_at = Vector3.INF


## Durur (yavaşlayarak); point verilirse durunca oraya döner.
func stop(face_point: Vector3 = Vector3.INF) -> void:
	_path = PackedVector3Array()
	_goal_speed = 0.0
	_face_at = face_point


## Hemen yerine koyar (yol ve hız silinir).
func place(at: Vector3, yaw: float) -> void:
	_path = PackedVector3Array()
	_goal_speed = 0.0
	_speed = 0.0
	_yaw = yaw
	_face_at = Vector3.INF
	_write(_ground(at), 0.0)


## Durduğu yerde bir noktaya döner (yumuşakça; binekte bineğiyle).
func face(point: Vector3) -> void:
	_face_at = point


func is_moving() -> bool:
	return not _path.is_empty() or _speed > 0.05


## Yolun sonuna varıldı ve durdu mu?
func arrived() -> bool:
	return _path.is_empty() and _speed <= 0.05


func position() -> Vector3:
	if ride:
		return ride.global_position if ride.is_inside_tree() else ride.position
	return actor.global_position if actor else Vector3.ZERO


func current_speed() -> float:
	return _speed


## Yön (yaw; +Z = 0).
func heading() -> float:
	return _yaw


## Dışarıdan sürülen bir adım (düzen: RiderColumn): yer (zemine oturur), yön ve hız verilir, bineğin klibi bu hızla oynar. Yol silinir.
func move_to(at: Vector3, p_yaw: float, speed: float, delta: float) -> void:
	_path = PackedVector3Array()
	_goal_speed = 0.0
	_face_at = Vector3.INF
	_yaw = p_yaw
	_speed = maxf(speed, 0.0)
	_write(_ground(at), delta)


## Bir adım: hız hedefe yaklaşır, düğüm yolda ilerler, yön döner; binekte koyun yürür ve binici sırtına oturur.
func tick(delta: float) -> void:
	if delta <= 0.0 or (actor == null and ride == null):
		return
	var at := position()
	var target_yaw := _yaw
	if not _path.is_empty():
		var next := _path[0]
		var to := Vector2(next.x - at.x, next.z - at.z)
		while to.length() <= REACH and not _path.is_empty():
			_path.remove_at(0)
			if _path.is_empty():
				break
			next = _path[0]
			to = Vector2(next.x - at.x, next.z - at.z)
		if not _path.is_empty():
			target_yaw = atan2(to.x, to.y)
			# Son noktaya yaklaşırken yavaşlar: durduğu yerde kaymaz.
			var left := _remaining(at)
			var want := minf(_goal_speed, sqrt(2.0 * ACCEL * maxf(left, 0.0)) + 0.2)
			_speed = move_toward(_speed, want, ACCEL * delta)
		else:
			_speed = move_toward(_speed, 0.0, ACCEL * 2.0 * delta)
	else:
		_speed = move_toward(_speed, 0.0, ACCEL * 2.0 * delta)
		if _face_at != Vector3.INF:
			var d := Vector2(_face_at.x - at.x, _face_at.z - at.z)
			if d.length_squared() > 0.0001:
				target_yaw = atan2(d.x, d.y)
	_yaw = lerp_angle(_yaw, target_yaw, 1.0 - exp(-TURN * delta))
	var step := Vector3(sin(_yaw), 0.0, cos(_yaw)) * _speed * delta
	if not _path.is_empty():
		# Adım yol noktasını aşmasın.
		var next := _path[0]
		var flat := Vector2(next.x - at.x, next.z - at.z)
		if Vector2(step.x, step.z).length() > flat.length():
			step = Vector3(flat.x, 0.0, flat.y)
	_write(_ground(at + step), delta)


func _remaining(from: Vector3) -> float:
	var total := 0.0
	var prev := Vector2(from.x, from.z)
	for p in _path:
		var q := Vector2(p.x, p.z)
		total += prev.distance_to(q)
		prev = q
	return total


func _write(at: Vector3, delta: float) -> void:
	if ride:
		var half := ride.get_mount().value("half_length") if ride.get_mount() else 0.0
		var pitch := PlayerController.ground_pitch(shape, Vector2(at.x, at.z), _yaw, half if half > 0.0 else PITCH_HALF_LENGTH)
		ride.place(at, _yaw, pitch)
		ride.drive(_speed, delta)
		if _seated:
			_place_rider()
		elif actor:
			actor.global_position = at
			actor.rotation.y = _yaw
		return
	if actor == null:
		return
	if actor.is_inside_tree():
		actor.global_position = at
	else:
		actor.position = at
	actor.rotation.y = _yaw
	if actor.avatar:
		actor.avatar.set_locomotion(_speed if _speed > 0.08 else 0.0)


## Binicinin kalçası oturma noktasının (sırtın yünü) üstünde: PlayerController._seated_transform'un hesabı.
func _place_rider() -> void:
	if actor == null or ride == null or not ride.is_inside_tree():
		return
	var seat := ride.seat_transform()
	actor.global_transform = Transform3D(seat.basis, seat.origin + seat.basis.y.normalized() * _hips_lift - seat.basis * _hips_offset)


func _ground(p: Vector3) -> Vector3:
	if shape == null:
		return p
	return Vector3(p.x, float(shape.call(&"height_at", p.x, p.z)), p.z)
