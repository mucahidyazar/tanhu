@tool
class_name Rug
extends Procedural3D
## Ateş çevresine serilen desenli keçe halı (kilim): koyu kırmızı-kahve zemin, ince bordür, ince geometrik desenler
## ve kısa kenarlarda püsküller (4. referanstaki gibi küçük, koyu kilimler; çimenin üstüne serilidir).
## Çimenler halının altında çıkmaz ("ground_cover" grubu; halıyı sıkıca örten küçük daireler, böylece çimen
## halının kenarına kadar gelir); serbest gezintide ise üzerinden yürünebilir.

const RUG_SHADER := preload("res://shaders/rug.gdshader")
const GROUND_COVER_GROUP := &"ground_cover"
## Örtü dairelerinin halı boyunca aralığı (metre): küçüldükçe daireler halıya daha sıkı oturur.
const COVER_SPACING := 0.4

## Halının gövdesi (metre; x uzun kenar). Püsküller kısa kenarlardan fringe kadar dışarı taşar.
@export var size := Vector2(2.0, 1.25):
	set(value):
		size = value
		queue_rebuild()
@export var field_color := Color(0.3, 0.09, 0.06):
	set(value):
		field_color = value
		queue_rebuild()
@export var border_color := Color(0.15, 0.075, 0.05):
	set(value):
		border_color = value
		queue_rebuild()
## Desen (soluk bej) ve vurgu (aşı boyası kahve-turuncu) renkleri.
@export var pattern_color := Color(0.56, 0.4, 0.28):
	set(value):
		pattern_color = value
		queue_rebuild()
@export var accent_color := Color(0.42, 0.2, 0.09):
	set(value):
		accent_color = value
		queue_rebuild()
## Püskül uzunluğu (metre; 0 = püskül yok).
@export_range(0.0, 0.3) var fringe := 0.08:
	set(value):
		fringe = value
		queue_rebuild()


func _ready() -> void:
	add_to_group(GROUND_COVER_GROUP)
	super._ready()


## Çimen dağıtıcısı için kaplanan alan: halıyı (püsküller dahil) örten daireler, Vector3(x, z, yarıçap).
func get_cover_circles() -> Array[Vector3]:
	return cover_circles(global_transform, size, fringe)


## Halıyı örten daireler (saf fonksiyon): uzun kenar boyunca iki sıra, COVER_SPACING aralıklı daireler.
## Her nokta en az bir dairenin içindedir; daireler kenarlardan en fazla birkaç santim taşar.
static func cover_circles(xform: Transform3D, body: Vector2, fringe_length: float) -> Array[Vector3]:
	var total := mesh_size(body, fringe_length)
	var count := maxi(ceili(total.x / COVER_SPACING), 1)
	var step := total.x / float(count)
	var r := Vector2(step * 0.5, total.y * 0.25).length()
	var result: Array[Vector3] = []
	for i in count:
		var x := -total.x * 0.5 + step * (float(i) + 0.5)
		for row in [-0.25, 0.25]:
			var p := xform * Vector3(x, 0.0, total.y * row)
			result.append(Vector3(p.x, p.z, r))
	return result


## Püsküller dahil mesh ölçüsü (saf fonksiyon).
static func mesh_size(body: Vector2, fringe_length: float) -> Vector2:
	return body + Vector2(maxf(fringe_length, 0.0) * 2.0, 0.0)


func _build() -> void:
	var plane := PlaneMesh.new()
	plane.size = mesh_size(size, fringe)
	var mat := ShaderMaterial.new()
	mat.shader = RUG_SHADER
	mat.set_shader_parameter("size", size)
	mat.set_shader_parameter("fringe", maxf(fringe, 0.0))
	mat.set_shader_parameter("field_color", field_color)
	mat.set_shader_parameter("border_color", border_color)
	mat.set_shader_parameter("pattern_color", pattern_color)
	mat.set_shader_parameter("accent_color", accent_color)
	var mi := add_mesh(plane, mat, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.018, 0.0)))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
