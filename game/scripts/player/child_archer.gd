class_name ChildArcher
extends Node3D
## Oyuncak yay (toy_bow; progression.md §7.2, architecture.md §3.9): çocuğun nişanı. Sağ tuş basılıyken kiriş gerilir, bırakınca atılır; kütle ok Projectiles'in analitik yayıyla
## uçar (data/combat/weapons.json), kan yoktur, vurulan düşer (hedefin işi), çocuk alır (PlayerController.interact). Yerden de koyun sırtından da aynı yol: nişanda yerde
## durulur; binekte binek yürümeyi sürdürür, nişan önden sağa ve sola MOUNT_CONE içinde kalır (arkaya atmak için bineği çevirmek gerekir).
##
## Nişan noktası imleç ışınının zemine değdiği yerdir (aim_override verilirse o: sınama ve otomatik sürüş). «targets» grubundaki bir hedef noktaya lock metreden yakınsa ya da
## ışına yakınsa ona kilitlenir; menzil dışına çıkan nokta menzile çekilir, kilit düşer. Zemindeki halka gerçek iniş yerini ve yayılmayı gösterir.
## Hedef sözleşmesi ArrowField'dadır.
##
## Ok, poz ve görünüş: BowPose (üst beden), ToyBowProp (yay, kiriş, gerilen ok), ArrowField (uçan oklar; tek MultiMesh). Bu düğüm PlayerController'ın çocuğudur.
##   archer.begin(); archer.release(); archer.tick(delta)       # PlayerController çağırır

## Ok çıktı (çıkış noktası, hedeflenen nokta).
signal loosed(from: Vector3, to: Vector3)

const BOW_ID := "toy_bow"
## Pozun geliş ve dönüş hızı (1/sn) ve okun çıkışından sonra kolun açık kaldığı süre (sn).
const BLEND_IN := 13.0
const BLEND_OUT := 7.0
const FOLLOW_THROUGH := 0.28
## Binekte nişanın önden en çok sapması (radyan).
const MOUNT_CONE := deg_to_rad(115.0)
## Bedenin atış yönünden sağa dönüklüğü (radyan; yerde: göğsün kalanı BowPose'un omurgasından). Alttaki klip yan duruşsa (bow_aim: sol yan hedefe,
## ayaklar atış çizgisinde) beden tam yana döner, göğüs omurgada hedefe doğru açılır.
const BODY_TURN := deg_to_rad(30.0)
const STANCE_BODY_TURN := deg_to_rad(90.0)
## İmleç ışınının en uzun erimi (m) ve ışına yakın hedefin kilitlendiği yarıçap payı (hedef havadayken).
const RAY_MAX := 140.0
## Halkanın en küçük yarıçapı (m) ve yedek çıkış noktası (m; model yokken).
const RING_MIN := 0.3
const LAUNCH_UP := 0.72
const LAUNCH_FORWARD := 0.3

var controller: PlayerController
var draw: BowDraw
var spec: Dictionary = {}
var arrow_spec: Dictionary = {}
var field: ArrowField
var prop: ToyBowProp
var pose: BowPose
var ring: MeshInstance3D
## Nişanı dışarıdan veren: Vector3 (dünya noktası) ya da Node3D (hedef); null ise imleç.
var aim_override: Variant = null
## O anki nişan noktası (dünya), kilitli hedef ve atış yönü (birim).
var aim_point := Vector3.ZERO
var aim_target: Node3D
var aim_dir := Vector3.BACK
## Yerde altta yan duruş klibi oynuyor (PlayerController yazar).
var stance_clip := false
## Pozun ağırlığı.
var amount := 0.0

var _rng := RandomNumberGenerator.new()
var _follow := 0.0


func _ready() -> void:
	spec = Weapons.bow(BOW_ID)
	arrow_spec = Weapons.arrow_of(BOW_ID)
	draw = BowDraw.new(spec)
	_rng.seed = 7741
	prop = ToyBowProp.new()
	prop.name = "ToyBow"
	prop.top_level = true
	add_child(prop)
	prop.set_arrow_length(float(arrow_spec.get("length", 0.5)))
	field = ArrowField.new()
	field.name = "Arrows"
	field.set_arrow_length(float(arrow_spec.get("length", 0.5)))
	add_child(field)
	ring = _make_ring()
	add_child(ring)


## Zemin yüksekliği (x, z) → y: okların ve halkanın zemini.
func set_ground(height_at: Callable) -> void:
	if field:
		field.ground = height_at


## İskelet değişti (model yüklendi): poz yeniden eklenir. Chibi yedeğinde poz yoktur, yay gövdenin önünde durur.
func attach_pose(skeleton: Skeleton3D, model_scale: float) -> void:
	if is_instance_valid(pose):
		pose.get_parent().remove_child(pose)
		pose.queue_free()
	pose = BowPose.attach(skeleton, prop, model_scale)


func is_drawing() -> bool:
	return draw != null and draw.is_drawing()


## Germeye başlar; bekleme sürüyorsa false.
func begin() -> bool:
	if draw == null or not draw.begin():
		return false
	_follow = 0.0
	_update_aim()
	return true


## Bırakma isteği: min_draw dolunca ok çıkar.
func release() -> void:
	if draw:
		draw.release()


## Okunmadan bırakır (kipten çıkarken).
func cancel() -> void:
	if draw:
		draw.cancel()
	_follow = 0.0
	if ring:
		ring.visible = false


## Bir adım: nişan güncellenir, kiriş gerilir, zamanı gelince ok çıkar, poz ağırlığı yazılır.
func tick(delta: float) -> void:
	if draw == null:
		return
	if draw.is_drawing():
		_update_aim()
	if draw.tick(delta):
		_loose()
	_follow = maxf(_follow - delta, 0.0)
	var want := 1.0 if draw.is_drawing() or _follow > 0.0 else 0.0
	amount = move_toward(amount, want, delta * (BLEND_IN if want > 0.0 else BLEND_OUT))
	_write_pose()


## Yerde nişanda bedenin bakacağı açı (radyan): atış yönünden sağa dönük (sol omuz önde; yan duruş klibinde tam yan).
func body_yaw() -> float:
	return atan2(aim_dir.x, aim_dir.z) - (STANCE_BODY_TURN if stance_clip else BODY_TURN)


## Okun çıkacağı yer: kabza (poz varsa), yoksa gövdenin önü.
func launch_point() -> Vector3:
	if is_instance_valid(pose) and amount > 0.2 and pose.grip_world != Vector3.ZERO:
		return pose.grip_world
	var at := controller.global_position if controller and controller.is_inside_tree() else Vector3.ZERO
	var base := controller.rider_height() if controller else 0.0
	return at + Vector3.UP * (LAUNCH_UP + base) + Vector3(aim_dir.x, 0.0, aim_dir.z) * LAUNCH_FORWARD


# --- Nişan (saf yardımcılar) ------------------------------------------------------------------------

## Nişan noktasını menzile ve en küçük uzaklığa çeker (saf): yatay uzaklık range'in dışına çıkarsa yönünde range'e, min_aim'in içine girerse dışına.
## Döner: {point: Vector3 (y: yatayı değişmişse ground'dan), clamped: bool}. forward: nokta üstüne denk gelirse yön.
static func clamp_range(from: Vector3, point: Vector3, min_aim: float, max_range: float, forward: Vector3) -> Dictionary:
	var flat := Vector2(point.x - from.x, point.z - from.z)
	var distance := flat.length()
	if distance >= min_aim and distance <= max_range:
		return {"point": point, "clamped": false}
	var dir := flat / distance if distance > 0.001 else Vector2(forward.x, forward.z).normalized()
	var at := clampf(distance, min_aim, max_range)
	return {"point": Vector3(from.x + dir.x * at, point.y, from.z + dir.y * at), "clamped": true}


## Binekte nişan açısı (saf): heading'den en çok cone kadar sapan açı.
static func clamp_cone(yaw: float, heading: float, cone: float) -> float:
	return heading + clampf(angle_difference(heading, yaw), -cone, cone)


## Kilitlenecek hedefin sırası (saf; yoksa -1): nişan noktasına yatayda lock'tan yakın (ya da ışına lock'tan yakın) en yakın merkez. range_from'dan uzak olanlar sayılmaz.
static func pick_lock(point: Vector3, centers: Array[Vector3], lock: float, ray_origin := Vector3.INF, ray_dir := Vector3.ZERO) -> int:
	var best := -1
	var best_d := INF
	for i in centers.size():
		var c := centers[i]
		var d := Vector2(c.x - point.x, c.z - point.z).length()
		if ray_origin != Vector3.INF and ray_dir != Vector3.ZERO:
			var along := maxf((c - ray_origin).dot(ray_dir), 0.0)
			d = minf(d, c.distance_to(ray_origin + ray_dir * along))
		if d <= lock and d < best_d:
			best = i
			best_d = d
	return best


## Işının zemine değdiği yer (saf; zemin Callable): yükseklik yinelemeyle bulunur. Yukarı bakan ışın için Vector3.INF.
static func ray_ground(origin: Vector3, dir: Vector3, height_at: Callable, start_y: float = 0.0) -> Vector3:
	if dir.y > -0.01:
		return Vector3.INF
	var y := start_y
	var p := Vector3.INF
	for _i in 5:
		var t := (y - origin.y) / dir.y
		if t < 0.0 or t > RAY_MAX:
			return Vector3.INF
		p = origin + dir * t
		y = float(height_at.call(p.x, p.z)) if height_at.is_valid() else start_y
	return Vector3(p.x, y, p.z)


# --- İç işler ---------------------------------------------------------------------------------------

func _update_aim() -> void:
	var from := controller.global_position if controller and controller.is_inside_tree() else Vector3.ZERO
	var forward := controller.forward_vector() if controller else Vector3.BACK
	var height_at: Callable = field.ground if field else Callable()
	var ray_origin := Vector3.INF
	var ray_dir := Vector3.ZERO
	var point := Vector3.INF
	aim_target = null
	if aim_override is Node3D and is_instance_valid(aim_override):
		aim_target = aim_override
		point = ArrowField.target_center(aim_override)
	elif aim_override is Vector3:
		point = aim_override
	else:
		var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
		if cam and DisplayServer.get_name() != "headless":
			var mouse := get_viewport().get_mouse_position()
			ray_origin = cam.project_ray_origin(mouse)
			ray_dir = cam.project_ray_normal(mouse)
			point = ChildArcher.ray_ground(ray_origin, ray_dir, height_at, from.y)
	var min_aim := float(spec.get("min_aim", 1.6))
	var max_range := float(spec.get("range", 14.0))
	if point == Vector3.INF:
		point = from + forward * max_range * 0.7
		ray_origin = Vector3.INF
	if aim_target == null and aim_override == null:
		aim_target = _lock_near(point, ray_origin, ray_dir)
		if aim_target:
			point = ArrowField.target_center(aim_target)
	var ranged := ChildArcher.clamp_range(from, point, min_aim, max_range, forward)
	if bool(ranged["clamped"]):
		point = ranged["point"]
		if height_at.is_valid():
			point.y = float(height_at.call(point.x, point.z))
		aim_target = null
	if controller and controller.is_riding():
		var yaw := atan2(point.x - from.x, point.z - from.z)
		var limited := ChildArcher.clamp_cone(yaw, controller.get_facing_yaw(), MOUNT_CONE)
		if not is_equal_approx(angle_difference(yaw, limited), 0.0):
			var distance := Vector2(point.x - from.x, point.z - from.z).length()
			point = Vector3(from.x + sin(limited) * distance, point.y, from.z + cos(limited) * distance)
			if height_at.is_valid():
				point.y = float(height_at.call(point.x, point.z))
			aim_target = null
	aim_point = point
	var start := launch_point()
	var along := aim_point - start
	# Yay okun yüksekliğini kaldırır: kol, düz çizginin biraz üstüne bakar.
	var flat := Vector2(along.x, along.z).length()
	along.y += float(spec.get("arc", 0.06)) * flat * 2.0
	aim_dir = along.normalized() if along.length_squared() > 0.0001 else forward


## Grupta düşmemiş en yakın hedef (kilit).
func _lock_near(point: Vector3, ray_origin: Vector3, ray_dir: Vector3) -> Node3D:
	if not is_inside_tree():
		return null
	var nodes: Array[Node3D] = []
	var centers: Array[Vector3] = []
	for target: Dictionary in ArrowField.targets_in(get_tree()):
		nodes.append(target["id"])
		centers.append(target["center"])
	var index := ChildArcher.pick_lock(point, centers, float(spec.get("lock", 1.6)), ray_origin, ray_dir)
	return nodes[index] if index >= 0 else null


func _loose() -> void:
	var k := draw.loosed_k
	var from := launch_point()
	var to := from + (aim_point - from) * BowDraw.reach_k(k)
	to = BowDraw.scatter(from, to, draw_spread_at(k), _rng.randf(), _rng.randf())
	field.fire(from, to, {"speed": float(spec.get("speed", 22.0)) * BowDraw.speed_k(k), "arc": float(spec.get("arc", 0.06)), "blunt": bool(arrow_spec.get("blunt", true)),
		"drift": float(arrow_spec.get("drift", 0.15)), "info": {"tag": str(arrow_spec.get("tag", "")), "bow": BOW_ID}})
	_follow = FOLLOW_THROUGH
	if ring:
		ring.visible = false
	loosed.emit(from, to)


## Atıştaki yayılma (derece).
func draw_spread_at(k: float) -> float:
	if k >= 1.0:
		return float(spec.get("spread", 0.0)) * BowDraw.STEADY_SPREAD
	return float(spec.get("spread", 0.0)) * lerpf(BowDraw.SLACK_SPREAD, 1.0, k)


func _write_pose() -> void:
	if is_instance_valid(pose):
		pose.amount = amount
		pose.aim_dir = aim_dir
		pose.draw = draw.draw_k() if draw.is_drawing() else 0.0
	elif prop and controller and controller.is_inside_tree():
		# Chibi yedeği: yay gövdenin önünde.
		var at := controller.global_position + Vector3.UP * (LAUNCH_UP + controller.rider_height()) + Vector3(aim_dir.x, 0.0, aim_dir.z) * LAUNCH_FORWARD
		var limb := (Vector3.UP - aim_dir * aim_dir.y).normalized()
		prop.global_transform = Transform3D(Basis(limb.cross(aim_dir).normalized(), limb, aim_dir), at)
		prop.visible = amount > 0.01
	if prop:
		prop.show_arrow(draw.is_drawing())
	if controller:
		controller.apply_bow_hands(amount)
	if ring:
		ring.visible = draw.is_drawing()
		if ring.visible:
			_write_ring()


func _write_ring() -> void:
	var start := launch_point()
	var distance := start.distance_to(aim_point)
	var radius := maxf(distance * tan(deg_to_rad(draw.spread_deg()) * 0.5), RING_MIN)
	var at := aim_point
	if field.ground.is_valid():
		at.y = float(field.ground.call(at.x, at.z)) + 0.04
	ring.global_transform = Transform3D(Basis.IDENTITY.scaled(Vector3(radius, 1.0, radius)), at)


func _make_ring() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "AimRing"
	mi.top_level = true
	mi.visible = false
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.mesh = Procedural3D.torus(0.93, 1.0)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.95, 0.78, 0.8)
	mat.no_depth_test = true
	mi.material_override = mat
	return mi
