class_name TargetDummy
extends Node3D
## Sınama hedefi (geliştirme ve testler; asıl av SmallGame): hedef sözleşmesini gösterir. «targets» grubundadır, hit(point) ile devrilir, gruptan çıkar, «fallen_game»e girer;
## is_down() ve collect() taşır. Küçük kazık ve üstünde saman top.

signal was_hit(point: Vector3)
signal was_collected

var hit_radius := 0.3
var hits := 0
var down := false
var collected := false
## Hedefin vurulacak noktasının yerden yüksekliği (m).
var center_height := 0.42

var _body: MeshInstance3D


func _ready() -> void:
	add_to_group(ArrowField.TARGET_GROUP)
	_body = MeshInstance3D.new()
	_body.name = "Body"
	_body.mesh = ArrowField.merge_parts([
		[Procedural3D.capsule(0.03, 0.42), Transform3D(Basis.IDENTITY, Vector3(0.0, 0.21, 0.0)), Style.WOOD_DARK],
		[Procedural3D.sphere(0.14), Transform3D(Basis.IDENTITY, Vector3(0.0, center_height, 0.0)), Style.STRAW],
	])
	_body.material_override = Style.toon(Color.WHITE, {"use_vertex_color": true})
	add_child(_body)


func hit_center() -> Vector3:
	return global_position + Vector3.UP * center_height


func hit(point: Vector3) -> bool:
	if down:
		return false
	hits += 1
	down = true
	remove_from_group(ArrowField.TARGET_GROUP)
	add_to_group(PlayerController.FALLEN_GROUP)
	was_hit.emit(point)
	if _body:
		_body.rotation = Vector3(deg_to_rad(82.0), 0.0, 0.0)
	return true


func is_hittable() -> bool:
	return not down


func is_down() -> bool:
	return down


func collect() -> Dictionary:
	if not down or collected:
		return {}
	collected = true
	remove_from_group(PlayerController.FALLEN_GROUP)
	was_collected.emit()
	visible = false
	return {"kind": "dummy"}
