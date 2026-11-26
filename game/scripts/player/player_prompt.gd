class_name PlayerPrompt
extends PanelContainer
## Oyuncunun o an yapabileceğinin küçük ipucu (alt ortada; GameHud'un paneli ve tuş kapakçıklarıyla aynı görünüş): «E Bin», «Shift Dürt · E İn · Sağ tık Nişan».
## Çocuk denetleyicisinin ipucunu gösterir (PlayerController.prompt_changed); boşsa gizlidir. Yazısı düz metin olarak okunabilir (sınama).

const SEPARATOR := "·"
const THEME := preload("res://ui/menu_theme.tres")
## Ekranın altından yukarı pay (piksel): sol alttaki GameHud panelinin üstünde kalır.
const BOTTOM_MARGIN := 104.0

var _pairs: Array = []
var _row: HBoxContainer


func _ready() -> void:
	theme = THEME
	theme_type_variation = &"HudPanel"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var brush := MenuBrush.new()
	brush.show_behind_parent = true
	brush.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brush.padding = 4.0
	brush.brush_seed = 5.1
	brush.ink = Color(0.04, 0.062, 0.15, 0.82)
	brush.rim = 0.2
	add_child(brush)
	_row = HBoxContainer.new()
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override(&"separation", 12)
	add_child(_row)
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_top = -BOTTOM_MARGIN
	offset_bottom = -BOTTOM_MARGIN
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	visible = false
	if not _pairs.is_empty():
		_rebuild()


## İpucunu yazar: [[tuş, eylem], ...]; boş liste gizler.
func show_pairs(pairs: Array) -> void:
	if pairs == _pairs:
		return
	_pairs = pairs.duplicate()
	if _row:
		_rebuild()


## Düz yazı: GameHud.format_hints biçiminde.
func get_text() -> String:
	return GameHud.format_hints(_pairs)


func _rebuild() -> void:
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	visible = not _pairs.is_empty()
	for i in _pairs.size():
		if i > 0:
			_row.add_child(_label(SEPARATOR, &"HudSeparator"))
		_row.add_child(_label(str(_pairs[i][0]), &"HudKey"))
		_row.add_child(_label(str(_pairs[i][1]), &"HudAction"))


func _label(text: String, variation: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
