@tool
class_name CreatorBrushButton
extends BaseButton
## Fırça darbesi biçimindeki düğme (ör. koyu "Esc  Geri Al", turkuaz "E  Onayla").
##
## Arkada kuru fırça shader'ıyla boyanmış bir şerit, önünde küçük bir tuş etiketi (klavye tuşu)
## ve metin bulunur. Üzerine gelince fırça hafifçe aydınlanır ve düğme büyür; basınca küçülür.
## Klavye kısayolu kullanıldığında pulse() aynı basma hissini verir.

const BRUSH_SHADER := preload("res://shaders/ui/creator_brush.gdshader")
## Animasyon hızları.
const HOVER_RATE := 9.0
const PRESS_RATE := 7.0

## Tuş etiketindeki yazı (ör. "Esc", "E").
@export var key_text := "E":
	set(value):
		key_text = value
		if _chip_label:
			_chip_label.text = value
## Düğme metni.
@export var text := "Onayla":
	set(value):
		text = value
		if _label:
			_label.text = value
## Fırça rengi.
@export var stroke_color := Color(0.17, 0.45, 0.47, 1.0):
	set(value):
		stroke_color = value
		if _material:
			_material.set_shader_parameter(&"stroke_color", value)
## Fırça izinin rastgelelik tohumu (iki düğme birbirinin aynısı olmasın).
@export var stroke_seed := 1.0:
	set(value):
		stroke_seed = value
		if _material:
			_material.set_shader_parameter(&"seed", value)

var _stroke: ColorRect
var _chip: PanelContainer
var _chip_label: Label
var _label: Label
var _material: ShaderMaterial
var _hover := 0.0
var _press := 0.0


func _init() -> void:
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _ready() -> void:
	_build()
	resized.connect(_on_resized)
	_on_resized()


## Klavye kısayoluyla tetiklendiğinde kısa bir "basıldı" animasyonu.
func pulse() -> void:
	_press = 1.0


## Düğme metni (testler için).
func get_text() -> String:
	return text


func _process(delta: float) -> void:
	# Editörde düğüm ölçeğine dokunulmaz; aksi halde sahne kaydedilince bu değerler de kaydedilirdi.
	if Engine.is_editor_hint():
		return
	var before := Vector2(_hover, _press)
	var hover_target := 1.0 if is_hovered() and not disabled else 0.0
	_hover = move_toward(_hover, hover_target, delta * HOVER_RATE * 0.5)
	var press_target := 1.0 if get_draw_mode() == DRAW_PRESSED else 0.0
	_press = move_toward(_press, press_target, delta * PRESS_RATE)
	if Vector2(_hover, _press) == before:
		return
	var ease_hover := ease(_hover, -1.8)
	scale = Vector2.ONE * (1.0 + 0.045 * ease_hover - 0.06 * _press)
	if _material:
		_material.set_shader_parameter(&"hover", ease_hover * 0.8 + _press * 0.2)


func _build() -> void:
	_material = ShaderMaterial.new()
	_material.shader = BRUSH_SHADER
	_material.set_shader_parameter(&"stroke_color", stroke_color)
	_material.set_shader_parameter(&"seed", stroke_seed)
	_material.set_shader_parameter(&"thickness", 0.68)
	_material.set_shader_parameter(&"tail", 0.3)
	_stroke = ColorRect.new()
	_stroke.name = "Stroke"
	_stroke.material = _material
	_stroke.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stroke.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Fırça izi düğmenin biraz dışına taşar; boyalı görünüm daha doğal olur.
	_stroke.offset_left = -10.0
	_stroke.offset_right = 10.0
	_stroke.offset_top = -10.0
	_stroke.offset_bottom = 10.0
	_stroke.resized.connect(func() -> void: _material.set_shader_parameter(&"rect_size", _stroke.size))
	add_child(_stroke, false, Node.INTERNAL_MODE_FRONT)

	var center := CenterContainer.new()
	center.name = "Content"
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center, false, Node.INTERNAL_MODE_FRONT)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", 12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(row)

	_chip = PanelContainer.new()
	_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_chip.add_theme_stylebox_override(&"panel", _chip_style())
	row.add_child(_chip)
	_chip_label = Label.new()
	_chip_label.theme_type_variation = &"CreatorKeyChip"
	_chip_label.text = key_text
	_chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_chip.add_child(_chip_label)

	_label = Label.new()
	_label.theme_type_variation = &"CreatorButtonText"
	_label.text = text
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_label)


## Tuş etiketi: açık renkli, yuvarlak köşeli küçük bir klavye tuşu.
func _chip_style() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = _theme_color(&"chip", Color(0.88, 0.86, 0.82))
	box.set_corner_radius_all(5)
	box.content_margin_left = 7.0
	box.content_margin_right = 7.0
	box.content_margin_top = 1.0
	box.content_margin_bottom = 1.0
	box.shadow_color = _theme_color(&"chip_shadow", Color(0.0, 0.0, 0.0, 0.3))
	box.shadow_size = 2
	box.shadow_offset = Vector2(0.0, 1.5)
	box.anti_aliasing = true
	return box


## Büyüme / küçülme animasyonu düğmenin ortasından olsun.
func _on_resized() -> void:
	if not Engine.is_editor_hint():
		pivot_offset = size * 0.5


func _theme_color(item: StringName, fallback: Color) -> Color:
	return get_theme_color(item, &"CreatorBrushButton") if has_theme_color(item, &"CreatorBrushButton") else fallback
