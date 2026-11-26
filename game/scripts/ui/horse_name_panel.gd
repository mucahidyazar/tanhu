class_name HorseNamePanel
extends Control
## Ata ad koyma (progression.md §6.4 «ad koymak +10», act1.md §8.8 stallion_name; Yol Haritası mount-bond-actions): HUD'un dilinde küçük
## pencere. Öneri listesi (1–5 ya da tık) ve serbest ad yazısı (en çok 16 harf); Enter onaylar, Esc vazgeçer. Ad bir kez konur (Bağ +10).
##   var panel := HorseNamePanel.new()
##   panel.setup(["Küldoru", "Tanyeli", "Arkvi"], "tr", "Doru")
##   panel.named.connect(func(n: String) -> void: ...); panel.cancelled.connect(...)

signal named(horse_name: String)
signal cancelled

const MAX_LEN := 16
const BOX := Vector2(520.0, 0.0)

var suggestions: PackedStringArray = PackedStringArray()
var lang := "tr"
var current := ""

var _edit: LineEdit
var _k := 1.0
var _hover := -1


func _init() -> void:
	name = "HorseNamePanel"


func setup(p_suggestions: Array, p_lang := "tr", p_current := "") -> void:
	suggestions = PackedStringArray(p_suggestions)
	lang = p_lang
	current = p_current
	queue_redraw()


func _ready() -> void:
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_k = UIKit.ui_k() * HudKit.hud_scale()
	_edit = LineEdit.new()
	_edit.name = "Name"
	_edit.max_length = MAX_LEN
	_edit.placeholder_text = "Adını yaz" if lang != "en" else "Type a name"
	_edit.add_theme_font_override(&"font", HudKit.body_font(500))
	_edit.add_theme_font_size_override(&"font_size", int(20 * _k))
	_edit.text_submitted.connect(func(t: String) -> void: confirm(t))
	add_child(_edit)
	_layout()
	_edit.grab_focus()


func _layout() -> void:
	var r := box_rect()
	_edit.position = r.position + Vector2(24.0, r.size.y - 92.0 * _k)
	_edit.size = Vector2(r.size.x - 48.0, 42.0 * _k)


func box_rect() -> Rect2:
	var h := (120.0 + suggestions.size() * 44.0 + 110.0) * _k
	var w := BOX.x * _k
	return Rect2(size * 0.5 - Vector2(w, h) * 0.5, Vector2(w, h))


func _row_rect(i: int) -> Rect2:
	var r := box_rect()
	return Rect2(r.position + Vector2(20.0 * _k, (96.0 + i * 44.0) * _k), Vector2(r.size.x - 40.0 * _k, 38.0 * _k))


## Adı onaylar (boşsa ya da yalnız boşluksa olmaz). Döner: kondu mu.
func confirm(text_value: String) -> bool:
	var n := HorseNamePanel.clean(text_value)
	if n.is_empty():
		MenuStyle.play_ui(self, &"deny")
		return false
	named.emit(n)
	return true


## Adın temizi (saf): baştaki ve sondaki boşluk gider, iç boşluk teke iner, en çok MAX_LEN harf.
static func clean(text_value: String) -> String:
	var parts := text_value.strip_edges().split(" ", false)
	return " ".join(parts).substr(0, MAX_LEN)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		var key := (event as InputEventKey).physical_keycode
		if key == KEY_ESCAPE:
			cancelled.emit()
			get_viewport().set_input_as_handled()
		elif key >= KEY_1 and key <= KEY_5 and int(key - KEY_1) < suggestions.size() and (_edit == null or _edit.text.is_empty()):
			confirm(suggestions[int(key - KEY_1)])
			get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := -1
		for i in suggestions.size():
			if _row_rect(i).has_point((event as InputEventMouseMotion).position):
				h = i
		if h != _hover:
			_hover = h
			queue_redraw()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		for i in suggestions.size():
			if _row_rect(i).has_point((event as InputEventMouseButton).position):
				confirm(suggestions[i])
				accept_event()
				return


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _edit:
		_layout()
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.35))
	var r := box_rect()
	draw_rect(r, Color(HudKit.NAVY_DEEP, 0.94))
	draw_rect(r, Color(HudKit.GOLD, 0.6), false, 2.0 * _k)
	var title := ("AD KOY" if lang != "en" else "NAME THE HORSE")
	HudKit.draw_text(self, HudKit.title_font(), r.position + Vector2(r.size.x * 0.5, 40.0 * _k), title, int(24 * _k), HudKit.GOLD, 1)
	if not current.is_empty():
		HudKit.draw_text(self, HudKit.body_font(500), r.position + Vector2(r.size.x * 0.5, 70.0 * _k), current, int(16 * _k), HudKit.TEXT_DIM, 1)
	for i in suggestions.size():
		var rr := _row_rect(i)
		if i == _hover:
			draw_rect(rr, Color(HudKit.GOLD_DEEP, 0.3))
		draw_rect(rr, Color(HudKit.GOLD, 0.3), false, 1.0 * _k)
		HudKit.draw_text(self, HudKit.body_font(600), rr.position + Vector2(14.0 * _k, 26.0 * _k), "%d  %s" % [i + 1, suggestions[i]], int(19 * _k), HudKit.CREAM)
	HudKit.draw_text(self, HudKit.body_font(400), r.position + Vector2(r.size.x * 0.5, r.size.y - 18.0 * _k),
		"Enter · Esc" + (" vazgeç" if lang != "en" else " cancel"), int(13 * _k), Color(HudKit.TEXT_DIM, 0.8), 1)
