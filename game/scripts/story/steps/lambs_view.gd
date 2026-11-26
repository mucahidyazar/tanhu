class_name LambsView
extends Node3D
## «Kuzular»ın görünüşü (LambFlock'un yüzü; Önsöz, 9 Nisan sabahı): dört ana koyun ve dört kuzu tek MultiMesh'te, sürünün gölgelendiricisiyle
## (HerdField.SHADER: yürüyüş, otlama ve kuyruk köşede; herd_field.gd'ye dokunulmaz, ağ ve özel veri burada yazılır). Ağ koyunun Meshy uzak ağıdır
## (assets/animals/sheep/sheep_far.glb, 1.300 üçgen; FaunaMesh.from_model), yoksa kodla çizilen koyun; kuzu aynı ağın küçültülmüşüdür
## (LAMB_SCALE). Donmuş kuzu karda yan yatar; kucaktaki kuzu MultiMesh'ten çıkar, ayrı bir ağ olarak çocuğun kollarında durur. Kardaki iz
## (LambFlock.track) yurdun ağılından her anaya giden çift toynak izidir: tek MultiMesh, tek çizim (yumuşak koyu mavi lekeler).
##   var v := LambsView.new(); v.flock = f; world.add_child(v); v.build()
##   v.carrier = oyuncu      # kucaktaki kuzu onun önünde
##   v.tick(dt)              # her kare (yürüyüş evresi, yerler)

const FAR_MODEL := "res://assets/animals/sheep/sheep_far.glb"
const LAMB_SCALE := 0.52
const EWE_SCALE := 1.0
## İzin lekesi (m), rengi ve kalkışı.
const PRINT_SIZE := Vector2(0.24, 0.32)
const PRINT_COLOR := Color(0.3, 0.38, 0.56, 0.72)
const PRINT_LIFT := 0.03
## Sürünün tamponu: kişi başına 12 dönüşüm + 4 özel.
const FLOATS := 16
## Kucaktaki kuzunun çocuğa göre yeri (m): önünde, göğüs hizasında, kollarında yan.
const CARRY_OFFSET := Vector3(0.0, 0.34, 0.27)
## Yürüyüşün adım boyu (m; koyunun yürüyüş klibi) ve kuzunun ananın ardından sıçrayışı.
const STRIDE := 0.86

var flock: LambFlock
## Taşıyan (oyuncu; kucaktaki kuzu onun önünde durur).
var carrier: Node3D
## Zeminin yüksekliği: (x, z) -> y (yoksa 0).
var ground: Callable

var _mm: MultiMesh
var _mm_node: MultiMeshInstance3D
var _material: ShaderMaterial
var _carried: MeshInstance3D
var _prints: MultiMeshInstance3D
var _buffer := PackedFloat32Array()
var _phase := PackedFloat32Array()
var _yaw := PackedFloat32Array()
var _last := PackedVector3Array()
var _speed := PackedFloat32Array()
var _mesh: ArrayMesh
var _uses_model := false


func _ready() -> void:
	name = "Lambs" if name.is_empty() else name


## Ağı, örnekleri ve izi kurar (perde kapalıyken; model eşzamanlı çevrilir, 1.300 üçgen).
func build() -> void:
	if flock == null:
		return
	_mesh = _make_mesh()
	_material = ShaderMaterial.new()
	_material.shader = HerdField.SHADER
	# Kuzular ve analar düz krem; koç boynuzu yok.
	_material.set_shader_parameter(&"ram_share", 0.0)
	_material.set_shader_parameter(&"dark_share", 0.0)
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_custom_data = true
	_mm.mesh = _mesh
	var n := flock.lamb_count() * 2
	_mm.instance_count = n
	_buffer.resize(n * FLOATS)
	_phase.resize(n)
	_yaw.resize(n)
	_last.resize(n)
	_speed.resize(n)
	for i in n:
		_phase[i] = float(i) * 0.37
		_yaw[i] = float(i) * 1.3
		_last[i] = Vector3.INF
	_mm_node = MultiMeshInstance3D.new()
	_mm_node.name = "Flock"
	_mm_node.multimesh = _mm
	_mm_node.material_override = _material
	_mm_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_mm_node.custom_aabb = AABB(Vector3(-300.0, -60.0, -300.0), Vector3(600.0, 120.0, 600.0))
	add_child(_mm_node)
	_carried = MeshInstance3D.new()
	_carried.name = "CarriedLamb"
	_carried.mesh = _mesh
	_carried.material_override = _material
	_carried.visible = false
	add_child(_carried)
	_build_prints()
	tick(0.0)


## Kodla çizilen ya da Meshy ağı gösteriliyor mu (sınama)?
func uses_model() -> bool:
	return _uses_model


## Örneğin dünyadaki yeri (sınama): i kuzunun sırası; ewe doğruysa anası.
func instance_position(i: int, ewe: bool) -> Vector3:
	if _mm == null:
		return Vector3.INF
	return _mm.get_instance_transform(i * 2 + (0 if ewe else 1)).origin


func carried_visible() -> bool:
	return _carried != null and _carried.visible


func tick(delta: float) -> void:
	if flock == null or _mm == null:
		return
	var k := 0
	for i in flock.lamb_count():
		var l: Dictionary = flock.lambs[i]
		var state: StringName = l["state"]
		# Ana.
		var ewe_at: Vector3 = l["ewe_at"]
		k = _put(k, i * 2, ewe_at, EWE_SCALE, delta, false, 0.25 if state == LambFlock.LOST else 0.0)
		# Kuzu: kucaktayken MultiMesh'te gizli.
		var lamb_at: Vector3 = l["at"]
		if state == LambFlock.LOST:
			# Ananın yanında, ona sokulmuş.
			lamb_at = lamb_at.lerp(ewe_at, 0.0)
		elif state in [LambFlock.HOME, LambFlock.WARMED]:
			lamb_at = ewe_at + Vector3(0.55, 0.0, 0.35)
		var lying := bool(l["frozen"]) and state in [LambFlock.LOST, LambFlock.BY_HEARTH]
		k = _put(k, i * 2 + 1, lamb_at, 0.0 if state == LambFlock.CARRIED else LAMB_SCALE, delta, lying, 0.0)
	_mm.buffer = _buffer
	_update_carried()


func _put(k: int, idx: int, at: Vector3, s: float, delta: float, lying: bool, graze: float) -> int:
	var y := _ground(at.x, at.z)
	var last := _last[idx]
	var v := 0.0
	if last != Vector3.INF and delta > 0.0:
		var d := Vector2(at.x - last.x, at.z - last.z)
		v = d.length() / delta
		if d.length() > 0.004:
			_yaw[idx] = lerp_angle(_yaw[idx], atan2(d.x, d.y), 1.0 - exp(-6.0 * delta))
	_last[idx] = at
	_speed[idx] = move_toward(_speed[idx], v, 4.0 * delta)
	var sp := _speed[idx]
	if sp > 0.01:
		_phase[idx] = fposmod(_phase[idx] + sp / maxf(STRIDE * maxf(s, 0.3), 0.1) * delta, 1.0)
	var basis := Basis(Vector3.UP, _yaw[idx])
	var origin := Vector3(at.x, y, at.z)
	if lying:
		# Yan yatmış: gövdenin uzun ekseni çevresinde ≈80°, biraz gömülü.
		basis = basis * Basis(Vector3(0.0, 0.0, 1.0), deg_to_rad(80.0))
		origin.y += 0.08 * s
	basis = basis.scaled(Vector3(s, s, s)) if s > 0.0 else Basis().scaled(Vector3(0.0001, 0.0001, 0.0001))
	_buffer[k] = basis.x.x
	_buffer[k + 1] = basis.y.x
	_buffer[k + 2] = basis.z.x
	_buffer[k + 3] = origin.x
	_buffer[k + 4] = basis.x.y
	_buffer[k + 5] = basis.y.y
	_buffer[k + 6] = basis.z.y
	_buffer[k + 7] = origin.y
	_buffer[k + 8] = basis.x.z
	_buffer[k + 9] = basis.y.z
	_buffer[k + 10] = basis.z.z
	_buffer[k + 11] = origin.z
	_buffer[k + 12] = _phase[idx]
	_buffer[k + 13] = HerdField.swing_amplitude(sp, STRIDE) if sp > 0.05 else 0.0
	_buffer[k + 14] = graze * (0.5 + 0.5 * sin(float(idx) * 1.7 + Time.get_ticks_msec() * 0.0003))
	_buffer[k + 15] = fposmod(float(idx) * 0.618, 1.0)
	return k + FLOATS


func _update_carried() -> void:
	var on := flock.carrying >= 0 and is_instance_valid(carrier)
	_carried.visible = on
	if not on:
		return
	var yaw := carrier.global_rotation.y
	var avatar: Node3D = (carrier as PlayerController).get_avatar() if carrier is PlayerController else carrier.get_node_or_null(^"Avatar") as Node3D
	if avatar:
		yaw = avatar.global_rotation.y
	var basis := Basis(Vector3.UP, yaw)
	var at := carrier.global_position + basis * CARRY_OFFSET
	# Kollarda yan: kuzunun boyu çocuğun omuzlarına dik.
	_carried.global_transform = Transform3D((basis * Basis(Vector3.UP, PI * 0.5)).scaled(Vector3.ONE * LAMB_SCALE), at)


func _build_prints() -> void:
	var quad := QuadMesh.new()
	quad.size = PRINT_SIZE
	quad.orientation = PlaneMesh.FACE_Y
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = PRINT_COLOR
	mat.albedo_texture = Fx.soft_dot_texture()
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	quad.material = mat
	var points: Array[Dictionary] = []
	for i in flock.lamb_count():
		for p: Dictionary in LambFlock.track(flock.home, flock.lambs[i]["ewe"], i + 1):
			points.append(p)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = quad
	mm.instance_count = points.size() * 2
	for j in points.size():
		var p: Dictionary = points[j]
		var at: Vector3 = p["at"]
		var yaw := float(p["yaw"])
		var side := Vector3(cos(yaw), 0.0, -sin(yaw)) * 0.12
		for h in 2:
			var q := at + side * (1.0 if h == 0 else -1.0) + Vector3(sin(yaw), 0.0, cos(yaw)) * (0.22 if h == 0 else 0.0)
			mm.set_instance_transform(j * 2 + h, Transform3D(Basis(Vector3.UP, yaw), Vector3(q.x, _ground(q.x, q.z) + PRINT_LIFT, q.z)))
	_prints = MultiMeshInstance3D.new()
	_prints.name = "Tracks"
	_prints.multimesh = mm
	_prints.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_prints)


func track_count() -> int:
	return _prints.multimesh.instance_count if _prints and _prints.multimesh else 0


func _ground(x: float, z: float) -> float:
	return float(ground.call(x, z)) if ground.is_valid() else 0.0


## Koyunun ağı: Meshy uzak ağı (varsa, eşzamanlı çevrilir), yoksa kodla çizilen koyun.
func _make_mesh() -> ArrayMesh:
	_uses_model = false
	if MeshyProp.models_enabled and ResourceLoader.exists(FAR_MODEL):
		var scene := load(FAR_MODEL) as PackedScene
		if scene:
			var root := scene.instantiate()
			var found: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
			if root is MeshInstance3D:
				found.push_front(root)
			var mi := found[0] as MeshInstance3D if not found.is_empty() else null
			if mi and mi.mesh:
				var kind := FaunaKind.named("sheep")
				# Doku sıkıştırılmışsa açılır (HerdField._ModelJob gibi): köşe rengi UV'den okunur.
				var image := FaunaMesh.model_image(mi.mesh)
				if image and image.is_compressed():
					image = image.duplicate() as Image
					image.decompress()
				var data := FaunaMesh.from_model(mi.mesh.surface_get_arrays(0), kind.model_length() * kind.model_scale() if kind else 1.264,
					kind.max_triangles() if kind else 1800, image, kind.herd_look() if kind else {})
				root.free()
				if not data.is_empty():
					_uses_model = true
					call_deferred(&"_apply_joints", data)
					return FaunaMesh.make_mesh(data)
			else:
				root.free()
	return FaunaMesh.mesh_for("sheep")


func _apply_joints(data: Dictionary) -> void:
	if _material == null:
		return
	_material.set_shader_parameter(&"hip_height", float(data.get("hip", 0.4)))
	_material.set_shader_parameter(&"neck_pivot", data.get("neck", Vector3(0.0, 0.55, 0.25)))
	_material.set_shader_parameter(&"tail_pivot", data.get("tail", Vector3(0.0, 0.58, -0.44)))
