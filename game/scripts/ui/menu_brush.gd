@tool
class_name MenuBrush
extends ColorRect
## Ebeveyninin arkasına çizilen fırça darbesi (boyalı arka plan).
##
## Ebeveyn bir buton, panel ya da kap (container) olabilir: darbe her zaman ebeveynin dikdörtgenini
## "padding" kadar taşacak şekilde kaplar ve ebeveynin arkasında kalır (show_behind_parent).
## Taşan pay, üzerine gelince beliren altın parıltıya yer açar.
## Biçim ve renkler shaders/ui/menu_brush.gdshader içindedir.
##
## Kullanım:
##   var brush := MenuBrush.new()
##   brush.brush_seed = 2.0
##   button.add_child(brush)
##   brush.highlight = 1.0   # parıltı

const SHADER := preload("res://shaders/ui/menu_brush.gdshader")

## Darbenin ebeveyn dikdörtgeninden taştığı pay (piksel). Parıltı bu payın içinde söner.
@export var padding := 28.0:
	set(value):
		padding = maxf(value, 0.0)
		_set_param(&"padding", padding)
		_fit_to_parent()
## Darbenin gövdesinin ebeveynden taşma payı (x: sağ/sol, y: üst/alt; piksel). Düğüm butonunda
## plakanın iki yanından kuru fırça uçları görünsün diye kullanılır.
@export var overscan := Vector2.ZERO:
	set(value):
		overscan = Vector2(maxf(value.x, 0.0), maxf(value.y, 0.0))
		_fit_to_parent()
## Her darbe biraz farklı görünsün diye biçim tohumu.
@export var brush_seed := 0.0:
	set(value):
		brush_seed = value
		_set_param(&"seed", value)
## Mürekkep rengi; alfa değeri yoğunluğu belirler.
@export var ink := MenuStyle.INK:
	set(value):
		ink = value
		_set_param(&"ink_color", value)
## İnce krem kenar çizgisinin görünürlüğü (0 = yok).
@export_range(0.0, 1.0) var rim := 0.32:
	set(value):
		rim = value
		_set_param(&"rim_color", Color(MenuStyle.CREAM, value))
## Uçların kuru fırça gibi dağılma miktarı.
@export_range(0.0, 1.0) var fray := 1.0:
	set(value):
		fray = value
		_set_param(&"fray", value)
## Vurgu (0..1): sıcak mürekkep ve altın parıltı.
@export_range(0.0, 1.0) var highlight := 0.0:
	set(value):
		highlight = clampf(value, 0.0, 1.0)
		_set_param(&"highlight", highlight)
## Boyanma oranı (0..1): giriş animasyonunda darbe soldan sağa boyanır.
@export_range(0.0, 1.0) var reveal := 1.0:
	set(value):
		reveal = clampf(value, 0.0, 1.0)
		_set_param(&"reveal", reveal)
## Basılma anındaki kısa aydınlanma (0..1).
var press := 0.0:
	set(value):
		press = clampf(value, 0.0, 1.0)
		_set_param(&"press", press)

var _watched_parent: Control


func _init() -> void:
	color = Color.WHITE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_behind_parent = true


func _ready() -> void:
	_ensure_material()
	_push_all_params()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			_watch_parent(get_parent() as Control)
		NOTIFICATION_UNPARENTED:
			_watch_parent(null)
		NOTIFICATION_RESIZED:
			_set_param(&"rect_size", size)


## Darbenin ebeveyne göre kaplayacağı dikdörtgen (saf fonksiyon; test edilebilir). over: gövdenin
## ebeveynden taşma payı.
static func fitted_rect(parent_size: Vector2, pad: float, over: Vector2 = Vector2.ZERO) -> Rect2:
	return Rect2(-Vector2(pad, pad) - over, parent_size + (Vector2(pad, pad) + over) * 2.0)


func _watch_parent(parent: Control) -> void:
	if _watched_parent and is_instance_valid(_watched_parent):
		if _watched_parent.resized.is_connected(_fit_to_parent):
			_watched_parent.resized.disconnect(_fit_to_parent)
		if _watched_parent is Container and _watched_parent.sort_children.is_connected(_fit_to_parent):
			_watched_parent.sort_children.disconnect(_fit_to_parent)
	_watched_parent = parent
	if parent == null:
		return
	parent.resized.connect(_fit_to_parent)
	# Kaplar (ör. PanelContainer) çocuklarını kendileri yerleştirir; yerleştirme bitince darbeyi yeniden taşır.
	if parent is Container:
		parent.sort_children.connect(_fit_to_parent)
	_fit_to_parent()


func _fit_to_parent() -> void:
	if _watched_parent == null or not is_instance_valid(_watched_parent):
		return
	var rect := fitted_rect(_watched_parent.size, padding, overscan)
	position = rect.position
	size = rect.size
	_set_param(&"rect_size", size)


## Darbenin malzemesi. Yoksa (ya da başka bir shader'a aitse) yenisi oluşturulur.
## Sahneye kaydedilmiş bir malzeme varsa o kullanılır; böylece editörde kaydetmek bir şey bozmaz.
func _ensure_material() -> ShaderMaterial:
	var mat := material as ShaderMaterial
	if mat == null or mat.shader != SHADER:
		mat = ShaderMaterial.new()
		mat.shader = SHADER
		material = mat
	return mat


func _push_all_params() -> void:
	_set_param(&"rect_size", size)
	_set_param(&"padding", padding)
	_set_param(&"seed", brush_seed)
	_set_param(&"ink_color", ink)
	_set_param(&"rim_color", Color(MenuStyle.CREAM, rim))
	_set_param(&"warm_ink_color", MenuStyle.INK_WARM)
	_set_param(&"glow_color", MenuStyle.GLOW)
	_set_param(&"fray", fray)
	_set_param(&"highlight", highlight)
	_set_param(&"reveal", reveal)
	_set_param(&"press", press)


func _set_param(param: StringName, value: Variant) -> void:
	var mat := material as ShaderMaterial
	if mat and mat.shader == SHADER:
		mat.set_shader_parameter(param, value)
