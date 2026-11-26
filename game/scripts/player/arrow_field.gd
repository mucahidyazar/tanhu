class_name ArrowField
extends MultiMeshInstance3D
## Uçan ve yatan okların çizimi (godot.md §3 «Dövüş»: oklar tek MultiMesh, gölgesiz) ve hedeflerle köprüsü. Hesap Projectiles'tadır (saf): her kare oklar ilerler,
## yoldaki hedefin hit(point)'i çağrılır, dönüşümler tampona yazılır. Ok yokken düğüm gizlidir, çizim eklemez.
##
## Hedef sözleşmesi (SmallGame ile aynı adlar): «targets» grubundaki Node3D, hit(point: Vector3) taşır. İsteğe bağlı: hit_center() (yoksa global_position), hit_radius
## (yoksa DEFAULT_RADIUS), is_hittable() (false dönen hedefi ok geçer; yoksa is_down() değilse vurulabilir), startle(from) (ıska yakına düşünce ürker).
##   var field := ArrowField.new(); field.ground = terrain.height_at; parent.add_child(field)
##   field.fire(from, to, {"speed": 22.0, "arc": 0.06, "blunt": true, ...})

## Bir hedef vuruldu (hit çağrıldıktan sonra).
signal target_hit(target: Node, point: Vector3)
## Ok zemine indi.
signal arrow_landed(point: Vector3)

const TARGET_GROUP := &"targets"
const DEFAULT_RADIUS := 0.3
## Ok bu kadar yakına düşen hedef ürker (m; ıska bedavadır, av kaçar).
const STARTLE_RADIUS := 3.0
const SHAFT_COLOR := Color(0.72, 0.52, 0.27)
const KNOB_COLOR := Color(0.47, 0.27, 0.13)
const FLETCH_COLOR := Color(0.9, 0.84, 0.72)
const WRAP_COLOR := Color(0.36, 0.2, 0.11)

## Zemin yüksekliği: (x, z) → y (boşsa zemin yok).
var ground: Callable
## Hesap.
var pool := Projectiles.new()

static var _material: Material
var _arrow_length := 0.52


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = ToyBowProp.arrow_mesh(_arrow_length)
	mm.instance_count = Projectiles.CAPACITY
	mm.visible_instance_count = 0
	multimesh = mm
	material_override = ArrowField.arrow_material()
	visible = false


func _process(delta: float) -> void:
	step(delta)


## Okun boyunu ayarlar (ağaca girmeden önce ya da sonra).
func set_arrow_length(length: float) -> void:
	_arrow_length = length
	if multimesh:
		multimesh.mesh = ToyBowProp.arrow_mesh(length)


## Atış: Projectiles.fire'a geçer.
func fire(from: Vector3, to: Vector3, options: Dictionary = {}) -> int:
	var id := pool.fire(from, to, options)
	_write()
	return id


## Bir adım (her kare; sınamalar doğrudan çağırır).
func step(delta: float) -> void:
	if pool.shots.is_empty():
		return
	var events := pool.step(delta, ground, ArrowField.targets_in(get_tree()))
	for event in events:
		if event["type"] == Projectiles.EVENT_HIT:
			var target: Variant = event["target"]
			if target is Node and is_instance_valid(target):
				if (target as Node).has_method(&"hit"):
					(target as Node).call(&"hit", event["point"])
				target_hit.emit(target, event["point"])
		else:
			_startle_near(event["point"])
			arrow_landed.emit(event["point"])
	_write()


## Grubun vurulabilir hedefleri: [{id: düğüm, center, radius}, ...]. Düşmüş hedef (is_down) sayılmaz.
static func targets_in(tree: SceneTree) -> Array:
	var out := []
	if tree == null:
		return out
	for node in tree.get_nodes_in_group(TARGET_GROUP):
		if node is Node3D and ArrowField.is_hittable(node):
			out.append({"id": node, "center": ArrowField.target_center(node), "radius": ArrowField.target_radius(node)})
	return out


## Hedef vurulabilir mi (is_hittable; yoksa düşmemişse)?
static func is_hittable(node: Node) -> bool:
	if node.has_method(&"is_hittable"):
		return bool(node.call(&"is_hittable"))
	return not ArrowField.is_target_down(node)


## Hedef düşmüş mü (is_down yoksa hayır)?
static func is_target_down(node: Node) -> bool:
	return bool(node.call(&"is_down")) if node.has_method(&"is_down") else false


## Hedefin vurulacak noktası.
static func target_center(node: Node3D) -> Vector3:
	return node.call(&"hit_center") if node.has_method(&"hit_center") else node.global_position


## Hedefin vuruş yarıçapı (m).
static func target_radius(node: Node) -> float:
	return float(node.get(&"hit_radius")) if &"hit_radius" in node else DEFAULT_RADIUS


## Iska yakına düştü: yakındaki hedefler ürker.
func _startle_near(point: Vector3) -> void:
	for node in get_tree().get_nodes_in_group(TARGET_GROUP):
		if node is Node3D and node.has_method(&"startle") and (node as Node3D).global_position.distance_to(point) <= STARTLE_RADIUS:
			node.call(&"startle", point)


## Okların malzemesi (köşe renkli toon; yeni program yok).
static func arrow_material() -> Material:
	if _material == null:
		_material = Style.toon(Color.WHITE, {"use_vertex_color": true, "brush_strength": 0.08})
	return _material


## Ok ağı (saf): ucu kökte (+Z'ye bakar), gövde -Z boyunca; küt, topuzlu uç, bağlı gövde, iki tüy (kavram görseli arrow_toy).
static func make_arrow_mesh(length: float) -> ArrayMesh:
	var parts: Array = []
	var radius := maxf(length * 0.012, 0.004)
	var knob := maxf(length * 0.032, 0.012)
	# Topuz: uç kökte biter (kürenin önü z = 0).
	parts.append([Procedural3D.sphere(knob), Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, 1.0, 1.5)), Vector3(0.0, 0.0, -knob * 1.5)), KNOB_COLOR])
	parts.append([Procedural3D.cylinder(radius * 1.5, radius * 1.5, length * 0.04, 6), _along(-knob * 3.2, length * 0.04), WRAP_COLOR])
	parts.append([Procedural3D.cylinder(radius, radius, length, 6), _along(-length * 0.5, length), SHAFT_COLOR])
	parts.append([Procedural3D.cylinder(radius * 1.4, radius * 1.4, length * 0.035, 6), _along(-length * 0.8, length * 0.035), WRAP_COLOR])
	# Tüyler: yassı elipsler, gövdeye dik iki yönde.
	var feather_at := -length * 0.9
	for side: float in [-1.0, 1.0]:
		var xform := Transform3D(Basis.IDENTITY.scaled(Vector3(0.12, 1.0, 2.6)), Vector3(0.0, side * knob * 0.9, feather_at))
		parts.append([Procedural3D.sphere(knob * 0.95), xform, FLETCH_COLOR])
	return ArrowField.merge_parts(parts)


## Parçaları tek ağda birleştirir (saf): parts: [[ilkel ağ, dönüşüm, renk], ...]; renk köşeye yazılır (use_vertex_color).
static func merge_parts(parts: Array) -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for part: Array in parts:
		var arrays: Array = (part[0] as Mesh).surface_get_arrays(0)
		var xform: Transform3D = part[1]
		var color: Color = part[2]
		var base := verts.size()
		var src_v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var src_n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var normal_basis := xform.basis.inverse().transposed()
		for i in src_v.size():
			verts.append(xform * src_v[i])
			normals.append((normal_basis * src_n[i]).normalized())
			colors.append(color)
		for index: int in arrays[Mesh.ARRAY_INDEX]:
			indices.append(base + index)
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	out[Mesh.ARRAY_VERTEX] = verts
	out[Mesh.ARRAY_NORMAL] = normals
	out[Mesh.ARRAY_COLOR] = colors
	out[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out)
	return mesh


## -Z boyunca uzanan silindirin dönüşümü (merkez z, boy dönüşüme girmez).
static func _along(z: float, _length: float) -> Transform3D:
	return Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.0, 0.0, z))


func _write() -> void:
	if multimesh == null:
		return
	var xforms := pool.transforms()
	multimesh.visible_instance_count = xforms.size()
	for i in xforms.size():
		multimesh.set_instance_transform(i, xforms[i])
	visible = not xforms.is_empty()
