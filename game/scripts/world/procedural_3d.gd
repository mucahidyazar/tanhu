@tool
class_name Procedural3D
extends Node3D
## Görselini kodla üreten düğümlerin ortak temeli (yurt, karakter, ahır, dekor...).
##
## - Sahne açılınca (editörde de) _build() çağrılır.
## - Üretilen alt düğümler sahneye KAYDEDİLMEZ; her açılışta yeniden oluşur.
## - Editörde özellikleri değiştirip "Yeniden oluştur" düğmesine basabilirsiniz;
##   alt sınıfların önemli özellikleri bunu zaten kendiliğinden tetikler.

@export_tool_button("Yeniden oluştur", "Reload") var rebuild_button: Callable = rebuild

var _rebuild_queued := false


func _ready() -> void:
	rebuild()


## Aynı karedeki birden fazla değişikliği tek bir yeniden üretimde toplar.
func queue_rebuild() -> void:
	if not is_inside_tree() or _rebuild_queued:
		return
	_rebuild_queued = true
	rebuild.call_deferred()


## Önceki üretimi siler ve görseli baştan kurar.
func rebuild() -> void:
	_rebuild_queued = false
	for child in get_children():
		if child.has_meta(&"generated"):
			remove_child(child)
			child.queue_free()
	_build()


## Alt sınıflar görselini burada üretir.
func _build() -> void:
	pass


## Üretilmiş bir düğüm ekler (kaydedilmez, yeniden üretimde silinir).
func add_generated(node: Node, parent: Node = null) -> Node:
	if parent == null or parent == self:
		node.set_meta(&"generated", true)
		add_child(node)
	else:
		parent.add_child(node)
	return node


## Kısayol: mesh ve malzemeyle bir MeshInstance3D ekler.
func add_mesh(mesh: Mesh, material: Material, xform: Transform3D = Transform3D.IDENTITY, parent: Node = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.transform = xform
	add_generated(mi, parent)
	return mi


## Kısayol: boş bir dönme/eklem noktası ekler.
func add_pivot(pivot_name: String, xform: Transform3D = Transform3D.IDENTITY, parent: Node = null) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = pivot_name
	pivot.transform = xform
	add_generated(pivot, parent)
	return pivot


## İki nokta arasına uzanan kapsül (kol, bacak, boyun). Kapsül uçları noktalara tam oturur.
static func limb_transform(from: Vector3, to: Vector3) -> Transform3D:
	var dir := to - from
	var length := dir.length()
	var basis := Basis.IDENTITY
	if length > 0.0001:
		basis = Basis(Quaternion(Vector3.UP, dir / length))
	return Transform3D(basis, (from + to) * 0.5)


static func capsule(radius: float, length: float) -> CapsuleMesh:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = maxf(length + radius * 2.0, radius * 2.0)
	mesh.radial_segments = 16
	mesh.rings = 6
	return mesh


static func sphere(radius: float, squash: float = 1.0) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0 * squash
	mesh.radial_segments = 24
	mesh.rings = 12
	return mesh


static func box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


static func cylinder(r_top: float, r_bottom: float, height: float, segments: int = 16) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = r_top
	mesh.bottom_radius = r_bottom
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 1
	return mesh


static func torus(inner: float, outer: float) -> TorusMesh:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 24
	mesh.ring_segments = 10
	return mesh
