@tool
class_name Banner
extends Procedural3D
## Rüzgârda dalgalanan sancak (kamp referansındaki gibi boyalı keçe kumaş, ortada kampın damgası).
##  SPEAR: mızrak ucunda, çapraz çubuktan sarkan koyu kızıl, yırtık bir bayrak.
##  STANDARD: T biçimli direkten sarkan açık renkli, damgalı bir bayrak.

const BANNER_SHADER := preload("res://shaders/banner.gdshader")

enum Kind { SPEAR, STANDARD }

@export var kind: Kind = Kind.SPEAR:
	set(value):
		kind = value
		queue_rebuild()
@export var pole_height := 3.3:
	set(value):
		pole_height = value
		queue_rebuild()
@export var cloth_size := Vector2(0.72, 1.35):
	set(value):
		cloth_size = value
		queue_rebuild()
@export var cloth_color := Color(0.42, 0.1, 0.08):
	set(value):
		cloth_color = value
		queue_rebuild()
@export var emblem_color := Color(0.93, 0.85, 0.66):
	set(value):
		emblem_color = value
		queue_rebuild()
@export var trim_color := Color(0.22, 0.11, 0.07):
	set(value):
		trim_color = value
		queue_rebuild()
@export_range(0.0, 1.0) var tatter := 1.0:
	set(value):
		tatter = value
		queue_rebuild()


func _build() -> void:
	var wood := Style.toon(Style.WOOD_DARK, {"brush_strength": 0.15})
	add_mesh(cylinder(0.035, 0.045, pole_height, 10), wood, Transform3D(Basis.IDENTITY, Vector3(0.0, pole_height * 0.5, 0.0)))
	var bar_y := pole_height - (0.32 if kind == Kind.SPEAR else 0.06)
	var bar_width := cloth_size.x + 0.16
	var bar_center_x := cloth_size.x * 0.5 if kind == Kind.SPEAR else 0.0
	add_mesh(box(Vector3(bar_width, 0.045, 0.045)), wood, Transform3D(Basis.IDENTITY, Vector3(bar_center_x, bar_y, 0.0)))
	if kind == Kind.SPEAR:
		var iron := Style.toon(Style.IRON.lightened(0.2))
		add_mesh(cylinder(0.0, 0.05, 0.32, 8), iron, Transform3D(Basis.IDENTITY, Vector3(0.0, pole_height + 0.16, 0.0)))
		add_mesh(sphere(0.045), Style.toon(Style.GOLD), Transform3D(Basis.IDENTITY, Vector3(0.0, pole_height, 0.0)))
	else:
		for side in [-1.0, 1.0]:
			add_mesh(sphere(0.04), Style.toon(Style.GOLD), Transform3D(Basis.IDENTITY, Vector3(side * bar_width * 0.5, bar_y, 0.0)))
	var mat := ShaderMaterial.new()
	mat.shader = BANNER_SHADER
	mat.set_shader_parameter("cloth_color", cloth_color)
	mat.set_shader_parameter("emblem_color", emblem_color)
	mat.set_shader_parameter("trim_color", trim_color)
	mat.set_shader_parameter("tatter", tatter)
	mat.set_shader_parameter("aspect", cloth_size.x / cloth_size.y)
	mat.set_shader_parameter("wave_amplitude", 0.07 if kind == Kind.SPEAR else 0.05)
	var cloth := add_mesh(MeshKit.cloth(cloth_size.x, cloth_size.y), mat, Transform3D(Basis.IDENTITY, Vector3(bar_center_x, bar_y - 0.02, 0.0)))
	cloth.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
