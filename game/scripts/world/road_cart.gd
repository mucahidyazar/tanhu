class_name RoadCart
extends Node3D
## Kantu'nun arabası (travel.md §3.2–§3.5, act1.md §9.4; Yol Haritası roads-relays): keçe örtülü iki tekerli araba. Gövde Meshy'nin
## tekerleksiz keçe araba ağıdır (assets/props/cart_felt; tools/cart_body.py ölçüsü: +Z ön, +X sol, köken dingil ortasının altındaki zemin),
## tekerlekler kodladır (DepartCart'ın ölçüsü: yarıçap 0,72, iz ±0,92; jant, göbek, on parmak tek ağda, iki çizim) ve yolda döner. Çeken
## at Yakve'dir (RideableHorse, «yakwe» satırı, binilmez: binek grubunda değildir); sürücü Kantu öndeki döşemede bağdaş oturur (kendi
## modeli, oturuş klibi). Yolcu (oyuncu) arka ağızda geriye bakarak oturur, bacakları sarkar (oturak S1; BenchPose).
##
## Hareket römork hesabıdır (CartMotion): at (koşum noktası) yolun üstünde yürür, arabanın yönü izler, dingil koşumun hitch_l gerisindedir;
## eğim ve yatış zeminden, tekerler yolun uzunluğuyla döner. Dünya düğümü dingildir; at üst düzeydedir (top_level).
## Engel: kasanın ve atın kutusu (ObstacleBox; aynı nesneler her karede güncellenir, oyuncunun listesi onları tutar).
## Uzaklık kademesi (travel.md §3.7; Godot'nun görünürlük aralığı): gövde ve tekerler 250 m, at 150 m, sürücü 120 m (sisin ötesi çizilmez).
##   var cart := RoadCart.new(); add_child(cart)
##   cart.place_hitch(hitch_xz, heading, ground, speed, delta)    # her kare (sürüş)
##   cart.seat_transform("S1")                                    # oturağın dünya dönüşümü (kalçanın oturduğu yüz; ön yüzü +Z)
##   cart.tail_point()                                            # binişin yeri (arkanın 0,9 m gerisi, zeminde)

const BODY_PATH := "res://assets/props/cart_felt/cart_felt.glb"
const BODY_META := "res://assets/props/cart_felt/cart_felt.json"
const HORSE_MODEL := "res://assets/animals/horse_brown/horse_brown.glb"
const TEXTURED_DOUBLE := preload("res://shaders/atw_textured_double.gdshader")
const TEXTURED_CUT := preload("res://shaders/atw_textured_cutaway.gdshader")
## Yolcu otururken keçe örtünün arka yarısı kalkar (K98: kapalı alana kamera girmez, içerisi yukarıdan görünür; yurdun kesiti gibi,
## include/cutaway.gdshaderinc): kesitin merkezi oturağın altı (yerel), yarıçapı, kesilen yükseklik (zeminden) ve kesitin başladığı tepe (m).
const ROOF_CUT_AT := Vector3(0.0, 0.0, -0.55)
const ROOF_CUT_RADIUS := 1.05
const ROOF_CUT_TOP := 1.86
const ROOF_CUT_CEILING := 2.6
const ROOF_RATE := 2.5
## Tekerlek (DepartCart ile aynı ölçü): yarıçap, yarı iz, jant içi, göbek, parmak sayısı.
const WHEEL_RADIUS := 0.72
const WHEEL_TRACK := 0.92
const RIM_INNER := 0.64
const HUB_RADIUS := 0.12
const HUB_LENGTH := 0.24
const SPOKES := 10
## Gövdenin kutusu (yerel; cart_felt.json box): arka −0,75, ön (oklar) 3,02; kasa −0,75..1,62.
const BED_Z := Vector2(-0.75, 1.62)
const BED_HALF_X := 0.98
## Koşum: atın kökü dingilin bu kadar önünde (m). cart_felt gövdesinde atın sağrısı döşemenin ön kenarından 0,19 m önde kalır (at yarı boyu
## 0,62 + 0,42); prototipin 2,70'i kendi kasasınındı (travel.md §3.5).
const HITCH_L := 2.85
## Sürücünün oturduğu yer (yerel; döşemenin önü, bağdaş) ve yolcunun binişte durduğu yer (arka kenarın gerisi).
const DRIVER_AT := Vector3(0.0, 0.962, 1.3)
const TAIL_BACK := 0.95
## Görünürlük aralıkları (m).
const BODY_RANGE := 250.0
const HORSE_RANGE := 150.0
const DRIVER_RANGE := 120.0
const WOOD_DARK := Color(0.24, 0.15, 0.09)

## Çeken atın satırı ve modeli, sürücünün modeli ("" sürücüsüz).
@export var horse_mount := "yakwe"
@export var horse_model := HORSE_MODEL
@export var driver_model := "kantu"
## Atın kuyruk ve toynak etkileri (toz, iz, ses; sınamada kapalı).
@export var effects := true

var body: Node3D
var horse: RideableHorse
var driver: CharacterAvatar
var wheels: Array[Node3D] = []
## Arabanın yönü (radyan; travel.md: atan2(dx, dz)), atın yeri (x, z) ve tekerin açısı.
var heading := 0.0
var hitch := Vector2.ZERO
var wheel_angle := 0.0
## Gövdenin ölçüsü (cart_felt.json; yoksa boş).
var meta: Dictionary = {}
## Oturaklar (rules.json cart.seats): kimlik → {at: Vector3 yerel, yaw}.
var seats: Dictionary = {}

## Örtünün açıklığı (0 kapalı, 1 açık) ve hedefi.
var roof_open := 0.0
var _roof_goal := 0.0
var _body_mats: Array[ShaderMaterial] = []
var _box := ObstacleBox.new()
var _horse_box := ObstacleBox.new()
var _placed := false


func _ready() -> void:
	add_to_group(World.OBSTACLE_GROUP)
	if FileAccess.file_exists(BODY_META):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BODY_META))
		meta = parsed if parsed is Dictionary else {}
	_build_body()
	_build_wheels()
	_build_horse()
	_build_driver()
	var raw: Variant = Travel.rule("cart.seats", {})
	if raw is Dictionary:
		for id: String in raw:
			var row: Dictionary = raw[id]
			var a: Array = row.get("at", [0.0, 1.1, 0.0])
			seats[id] = {"at": Vector3(float(a[0]), float(a[1]), float(a[2])), "yaw": float(row.get("yaw", 0.0)), "pose": str(row.get("pose", "bench"))}
	_update_boxes()


func _build_body() -> void:
	body = Node3D.new()
	body.name = "Body"
	add_child(body)
	if not ResourceLoader.exists(BODY_PATH):
		push_warning("[road_cart] gövde modeli yok: %s" % BODY_PATH)
		return
	var scene := (load(BODY_PATH) as PackedScene).instantiate() as Node3D
	scene.name = "Model"
	body.add_child(scene)
	for mi: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
		mi.visibility_range_end = BODY_RANGE
		# Görünen gövde kesitlidir (örtü yolcunun üstünde kalkar) ve gölge vermez; gölgeyi kesilmeyen kopyası verir (MeshyProp.cutaway gibi).
		var shadow := MeshInstance3D.new()
		shadow.name = "%sShadow" % mi.name
		shadow.mesh = mi.mesh
		shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		shadow.visibility_range_end = BODY_RANGE
		mi.add_sibling(shadow)
		shadow.transform = mi.transform
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for s in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(s)
			var tex: Texture2D = (src as BaseMaterial3D).albedo_texture if src is BaseMaterial3D else null
			# Keçe örtünün içi arka ağızdan görünür: iki yüzlü çizim.
			mi.set_surface_override_material(s, RoadCart._body_material(TEXTURED_CUT, tex, mi.get_aabb().position.y))
			_body_mats.append(mi.get_surface_override_material(s) as ShaderMaterial)
			shadow.set_surface_override_material(s, RoadCart._body_material(TEXTURED_DOUBLE, tex, mi.get_aabb().position.y))
	_write_roof()


static func _body_material(shader: Shader, tex: Texture2D, base_y: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("albedo_texture", tex)
	mat.set_shader_parameter("albedo_tint", Color(1, 1, 1))
	mat.set_shader_parameter("ink_strength", 0.25)
	mat.set_shader_parameter("brush_strength", 0.05)
	mat.set_shader_parameter("model_base_y", base_y)
	mat.set_shader_parameter("model_scale", 1.0)
	return mat


## Örtünün arka yarısı yolcunun üstünde kalkar (true) ya da iner.
func open_roof(on: bool, instant := false) -> void:
	_roof_goal = 1.0 if on else 0.0
	if instant:
		roof_open = _roof_goal
	_write_roof()


func _process(delta: float) -> void:
	if not is_equal_approx(roof_open, _roof_goal):
		roof_open = move_toward(roof_open, _roof_goal, delta * ROOF_RATE)
		_write_roof()


func _write_roof() -> void:
	if _body_mats.is_empty():
		return
	var xform := global_transform if is_inside_tree() else transform
	var c := xform * ROOF_CUT_AT
	for mat in _body_mats:
		mat.set_shader_parameter("cut_amount", roof_open)
		mat.set_shader_parameter("cut_center", c)
		mat.set_shader_parameter("cut_radius", ROOF_CUT_RADIUS)
		mat.set_shader_parameter("cut_low", ROOF_CUT_TOP)
		mat.set_shader_parameter("cut_top", ROOF_CUT_TOP)
		mat.set_shader_parameter("cut_ceiling", ROOF_CUT_CEILING)


## İki tekerlek: jant, göbek ve on parmak tek ağda (iki örnek, iki çizim); dingilin ekseni X.
func _build_wheels() -> void:
	var mesh := RoadCart.wheel_mesh()
	var mat := Style.toon(WOOD_DARK, {"brush_strength": 0.1})
	for side: float in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.name = "Wheel%s" % ("R" if side < 0.0 else "L")
		pivot.position = Vector3(side * WHEEL_TRACK, WHEEL_RADIUS, 0.0)
		body.add_child(pivot)
		var mi := MeshInstance3D.new()
		mi.name = "Mesh"
		mi.mesh = mesh
		mi.material_override = mat
		mi.visibility_range_end = BODY_RANGE
		pivot.add_child(mi)
		wheels.append(pivot)


## Tekerleğin ağı (saf): jant (simit), göbek (silindir) ve on parmak; eksen X, merkez kökte.
static func wheel_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var parts: Array = []
	var rim := TorusMesh.new()
	rim.inner_radius = RIM_INNER
	rim.outer_radius = WHEEL_RADIUS
	rim.rings = 24
	rim.ring_segments = 6
	parts.append([rim, Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO)])
	var hub := CylinderMesh.new()
	hub.top_radius = HUB_RADIUS
	hub.bottom_radius = HUB_RADIUS
	hub.height = HUB_LENGTH
	hub.radial_segments = 10
	hub.rings = 1
	parts.append([hub, Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3.ZERO)])
	for i in SPOKES:
		var a := TAU * float(i) / float(SPOKES)
		var spoke := BoxMesh.new()
		spoke.size = Vector3(0.05, WHEEL_RADIUS - 0.14, 0.05)
		# Parmak göbekten janta uzanır: X çevresinde a kadar dönen kutunun ekseni (0, cos a, sin a)'dır, yeri de o yönde.
		parts.append([spoke, Transform3D(Basis(Vector3.RIGHT, a), Vector3(0.0, cos(a), sin(a)) * (WHEEL_RADIUS * 0.5))])
	for part: Array in parts:
		var m: PrimitiveMesh = part[0]
		st.append_from(m, 0, part[1])
	st.generate_normals()
	return st.commit()


func _build_horse() -> void:
	horse = RideableHorse.new()
	horse.name = "Horse"
	horse.mount_id = horse_mount
	horse.model_path = horse_model if ResourceLoader.exists(horse_model) else ""
	horse.effects_enabled = effects
	horse.top_level = true
	add_child(horse)
	# Arabanın atı binilmez (DepartWorld'ün arabası gibi): binek grubunda değildir, engelini araba verir.
	horse.remove_from_group(Rideable.GROUP)
	horse.set_ridden(true)
	for mi: MeshInstance3D in horse.find_children("*", "MeshInstance3D", true, false):
		mi.visibility_range_end = HORSE_RANGE


func _build_driver() -> void:
	if driver_model.is_empty():
		return
	driver = CharacterAvatar.new()
	driver.name = "Driver"
	driver.model_override = driver_model
	driver.start_pose = &"sit"
	body.add_child(driver)
	driver.position = DRIVER_AT
	driver.play_pose(&"sit")
	for mi: MeshInstance3D in driver.find_children("*", "MeshInstance3D", true, false):
		mi.visibility_range_end = DRIVER_RANGE


## Sürücü görünsün mü (Kantu uyurken, arabayı başka kişi sürerken gizli).
func set_driver_visible(on: bool) -> void:
	if driver:
		driver.visible = on


# --- Yer ve hareket --------------------------------------------------------------------------------------------------

## Arabayı atın yerinden kurar (her kare): at hitch_xz'de, yolun yönü horse_heading; arabanın yönü römork hesabıyla izler (ilk çağrıda
## atın yönündedir). ground: height_at(x, z) taşıyan nesne (TerrainShape) ya da null (düz). speed: atın hızı (m/sn; klip ve teker).
func place_hitch(hitch_xz: Vector2, horse_heading: float, ground: Object, speed: float, delta: float) -> void:
	var moved := hitch_xz - hitch
	if not _placed:
		heading = horse_heading
		moved = Vector2.ZERO
	else:
		heading = CartMotion.step_heading(heading, moved, HITCH_L)
	hitch = hitch_xz
	var axle := CartMotion.axle_of(hitch, heading, HITCH_L)
	var ds := moved.length() if _placed else 0.0
	_placed = true
	_pose_body(axle, ground)
	wheel_angle = CartMotion.spin(wheel_angle, ds * signf(moved.dot(CartMotion.forward(heading))) if ds > 0.0 else 0.0, WHEEL_RADIUS)
	for w in wheels:
		w.rotation.x = wheel_angle
	var hy := RoadCart._height(ground, hitch)
	horse.place(Vector3(hitch.x, hy, hitch.y), horse_heading)
	horse.drive(speed, delta)
	_update_boxes()


## Durur (yerini değiştirmeden): at bekler, klip «idle».
func idle(delta: float) -> void:
	if horse:
		horse.drive(0.0, delta)


## Arabayı dingilinden kurar (park; karartmada taşıma): yön verilir, at hitch_l önünde.
func place_axle(axle_xz: Vector2, p_heading: float, ground: Object) -> void:
	heading = p_heading
	hitch = axle_xz + CartMotion.forward(p_heading) * HITCH_L
	_placed = true
	_pose_body(axle_xz, ground)
	if horse:
		horse.place(Vector3(hitch.x, RoadCart._height(ground, hitch), hitch.y), p_heading)
	_update_boxes()


func _pose_body(axle: Vector2, ground: Object) -> void:
	var h_axle := RoadCart._height(ground, axle)
	var h_hitch := RoadCart._height(ground, hitch)
	var r := CartMotion.right(heading)
	# Sol teker +X'tedir (arabanın solu): sağın tersi.
	var h_left := RoadCart._height(ground, axle - r * WHEEL_TRACK)
	var h_right := RoadCart._height(ground, axle + r * WHEEL_TRACK)
	var pitch := CartMotion.pitch_of(h_hitch, h_axle, HITCH_L)
	var roll := CartMotion.roll_of(h_left, h_right, WHEEL_TRACK)
	var basis := Basis(Vector3.UP, heading) * Basis(Vector3.RIGHT, -pitch) * Basis(Vector3.BACK, roll)
	var xform := Transform3D(basis, Vector3(axle.x, (h_left + h_right) * 0.5, axle.y))
	if is_inside_tree():
		global_transform = xform
	else:
		transform = xform
	if roof_open > 0.0:
		_write_roof()


static func _height(ground: Object, p: Vector2) -> float:
	if ground and ground.has_method(&"height_at"):
		return float(ground.call(&"height_at", p.x, p.y))
	return 0.0


## Dingilin yeri (x, z).
func axle_xz() -> Vector2:
	var at := global_position if is_inside_tree() else position
	return Vector2(at.x, at.z)


# --- Oturaklar ---------------------------------------------------------------------------------------------------------

## Oturağın dünya dönüşümü: kalçanın oturduğu yüz (yerel at; dünya eksenleri arabanınki), ön yüzü +Z (oturağın yaw'ıyla döner).
func seat_transform(id := "S1") -> Transform3D:
	var row: Dictionary = seats.get(id, {"at": Vector3(0.3, 1.11, -0.3), "yaw": PI})
	var local := Transform3D(Basis(Vector3.UP, float(row["yaw"])), row["at"])
	var xform := global_transform if is_inside_tree() else transform
	return xform * local


## Binişin ve inişin yeri (dünya, zeminde): oturağın ardında, arka kenarın TAIL_BACK gerisi.
func tail_point(id := "S1", ground: Object = null) -> Vector3:
	var row: Dictionary = seats.get(id, {"at": Vector3(0.3, 1.11, -0.3)})
	var at: Vector3 = row["at"]
	var xform := global_transform if is_inside_tree() else transform
	var p := xform * Vector3(at.x, 0.0, BED_Z.x - TAIL_BACK)
	return Vector3(p.x, RoadCart._height(ground, Vector2(p.x, p.z)) if ground else p.y, p.z)


## Arka kenarın ortası (dünya, zeminde; erim ölçüsü).
func tail_center() -> Vector3:
	var xform := global_transform if is_inside_tree() else transform
	return xform * Vector3(0.0, 0.0, BED_Z.x)


# --- Engel -------------------------------------------------------------------------------------------------------------

func get_obstacle_boxes() -> Array[ObstacleBox]:
	var out: Array[ObstacleBox] = [_box]
	if horse and is_instance_valid(horse) and horse.visible:
		out.append(_horse_box)
	return out


func _update_boxes() -> void:
	var xform := global_transform if is_inside_tree() else transform
	var x := Vector2(xform.basis.x.x, xform.basis.x.z).normalized()
	var center := xform * Vector3(0.0, 0.0, (BED_Z.x + BED_Z.y) * 0.5)
	_box.center = Vector2(center.x, center.z)
	_box.half = Vector2(BED_HALF_X, (BED_Z.y - BED_Z.x) * 0.5)
	_box.axis_x = x
	_box.axis_z = Vector2(-x.y, x.x)
	if horse and is_instance_valid(horse):
		var hb := horse.obstacle_box()
		_horse_box.center = hb.center
		_horse_box.half = hb.half
		_horse_box.axis_x = hb.axis_x
		_horse_box.axis_z = hb.axis_z
