@tool
class_name CreatorArrow
extends BaseButton
## Seçenek satırındaki ◀ / ▶ oku.
##
## Üçgen kodla çizilir; yazı tipindeki ok karakterlerine (bazı sistemlerde emoji olarak çizilir)
## bağlı değildir ve her ekran ölçeğinde keskin kalır. Üzerine gelince büyür ve açılır, basınca
## gittiği yöne doğru küçük bir adım atar.

## -1 = sola (◀), 1 = sağa (▶).
@export_range(-1, 1, 2) var direction := 1:
	set(value):
		direction = -1 if value < 0 else 1
		queue_redraw()
## Üçgenin boyutu (piksel): genişlik x yükseklik.
@export var arrow_size := Vector2(12.0, 15.0):
	set(value):
		arrow_size = value
		queue_redraw()

const FALLBACK_COLOR := Color(0.15, 0.53, 0.58)
const FALLBACK_HOVER := Color(0.2, 0.67, 0.72)
const FALLBACK_PRESSED := Color(0.1, 0.4, 0.44)
## Üzerine gelme animasyonunun hızı.
const HOVER_RATE := 14.0

var _hover := 0.0
var _nudge := 0.0


func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size = Vector2(38.0, 42.0)


func _ready() -> void:
	pressed.connect(nudge)


func _process(delta: float) -> void:
	var target := 1.0 if is_hovered() and not disabled else 0.0
	var before := Vector2(_hover, _nudge)
	_hover = move_toward(_hover, target, delta * HOVER_RATE * 0.5)
	_nudge = move_toward(_nudge, 0.0, delta * 6.0)
	if Vector2(_hover, _nudge) != before:
		queue_redraw()


## Okun kısa bir "adım" animasyonu yapmasını sağlar (klavyeyle değiştirince de çağrılır).
func nudge() -> void:
	_nudge = 1.0
	queue_redraw()


func _draw() -> void:
	var grow := 1.0 + 0.2 * _hover
	var center := size * 0.5 + Vector2(direction * 4.0 * _nudge, 0.0)
	var points := CreatorArrow.triangle_points(center, arrow_size * grow, direction)
	var color := _color(&"arrow", FALLBACK_COLOR).lerp(_color(&"arrow_hover", FALLBACK_HOVER), _hover)
	if get_draw_mode() == DRAW_PRESSED:
		color = _color(&"arrow_pressed", FALLBACK_PRESSED)
	draw_colored_polygon(points, color)
	# Doldurulmuş çokgen yumuşatılmaz; ince, yumuşatılmış bir kontur kenarları pürüzsüz yapar.
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, color, 1.2, true)


## Yönüne göre üçgenin köşe noktaları: uç, yön tarafında; taban, karşı tarafta.
static func triangle_points(center: Vector2, tri_size: Vector2, dir: int) -> PackedVector2Array:
	var half := tri_size * 0.5
	var s := float(signi(dir)) if dir != 0 else 1.0
	return PackedVector2Array([
		center + Vector2(half.x * s, 0.0),
		center + Vector2(-half.x * s, -half.y),
		center + Vector2(-half.x * s, half.y),
	])


func _color(item: StringName, fallback: Color) -> Color:
	return get_theme_color(item, &"CreatorArrow") if has_theme_color(item, &"CreatorArrow") else fallback
