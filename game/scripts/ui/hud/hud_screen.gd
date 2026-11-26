class_name HudScreen
extends Control
## HUD'un açılır sayfalarının temeli (Heybe I, Görevler J, Harita M): oyun durur (GameplayHud), arkada koyu bir perde, ortada HUD'un
## dilinde bir pano: lacivert mine, ince altın kenar, üst köşelerde gümüş bulut kıvrımları, altın Cinzel başlık ve altında görev
## kartının süs çubuğu; altta «Esc Kapat» tuş kapağı. Esc (ui_cancel, pause) ya da sayfanın kendi tuşu kapatır. Pano 1080 satıra
## çizilir, UIKit.ui_k() ile ölçeklenip ortalanır. Alt sınıflar _draw_content(ci) ile içini çizer, _content_input(e) ile girdi alır.

signal closed

const PANEL_BG := Color(0.055, 0.1, 0.19, 0.97)
const PANEL_RIM := Color("#d9b56c")
const BACKDROP := Color(0.01, 0.015, 0.03, 0.74)
const TITLE_SIZE := 30
const FADE := 0.18

## Sayfanın kimliği ("bag", "journal", "map") ve onu açıp kapatan eylem.
var kind := ""
var toggle_action: StringName
## Panonun tasarım boyu (1080 satır).
var panel_size := Vector2(900.0, 600.0)
var title := ""
## Pano çizilecek mi (harita kendi halkasını çizer)?
var framed := true

var _backdrop: ColorRect
var _panel: Canvas
var _closing := false


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Kendi katmanındadır (CanvasLayer HUD'un süzgecini aktarmaz): küçültülen dokular mip'le süzülsün.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	UIKit.full_rect(self)
	_backdrop = ColorRect.new()
	_backdrop.color = BACKDROP
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(_backdrop)
	add_child(_backdrop)
	_panel = Canvas.new()
	_panel.host = self
	_panel.size = panel_size
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)
	resized.connect(_layout)
	UIKit.on_ui_scale_changed(self, _layout)
	_layout()
	modulate.a = 0.0
	var t := create_tween()
	t.tween_property(self, ^"modulate:a", 1.0, FADE).set_trans(Tween.TRANS_SINE)
	MenuStyle.play_ui(self, &"page_turn", -10.0)


## Panonun denetimi (sınama ve alt sınıflar).
func panel() -> Control:
	return _panel


func _layout() -> void:
	if _panel == null:
		return
	var k := minf(UIKit.ui_k(), minf(size.x / (panel_size.x + 60.0), size.y / (panel_size.y + 40.0)))
	_panel.scale = Vector2(k, k)
	_panel.position = ((size - panel_size * k) * 0.5).round()


func _unhandled_input(event: InputEvent) -> void:
	if _closing:
		return
	if event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause") or (not toggle_action.is_empty() and InputMap.has_action(toggle_action) and event.is_action_pressed(toggle_action)):
		get_viewport().set_input_as_handled()
		close()
		return
	if _content_input(event):
		get_viewport().set_input_as_handled()


## Sayfayı kapatır (closed yayılır; düğüm silinir).
func close() -> void:
	if _closing:
		return
	_closing = true
	MenuStyle.play_ui(self, &"page_turn", -12.0)
	closed.emit()
	queue_free()


func is_closing() -> bool:
	return _closing


## Alt sınıfın girdisi (işlendiyse true).
func _content_input(_event: InputEvent) -> bool:
	return false


## Alt sınıfın çizimi (panonun içi; 1080 satır).
func _draw_content(_ci: Control) -> void:
	pass


## Alt sınıfın fare girdisi (panoya göre).
func _content_gui_input(_event: InputEvent) -> void:
	pass


func _draw_panel(ci: Control) -> void:
	if framed:
		draw_frame(ci, Rect2(Vector2.ZERO, panel_size), title)
	_draw_content(ci)
	_draw_footer(ci)


## HUD dilinde bir pano: lacivert, altın kenar, bulutlar, başlık ve süs çubuğu (saf çizim).
static func draw_frame(ci: CanvasItem, r: Rect2, p_title: String) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL_BG
	sb.border_color = PANEL_RIM
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(16)
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 26
	sb.anti_aliasing = true
	ci.draw_style_box(sb, r)
	var inner := StyleBoxFlat.new()
	inner.bg_color = Color(0, 0, 0, 0)
	inner.border_color = Color(PANEL_RIM, 0.35)
	inner.set_border_width_all(1)
	inner.set_corner_radius_all(12)
	inner.anti_aliasing = true
	ci.draw_style_box(inner, r.grow(-7.0))
	HudKit.draw_centered(ci, "cloud_right", r.position + Vector2(22.0, 4.0), Vector2(88.0, 44.0))
	HudKit.draw_centered(ci, "cloud_left", Vector2(r.end.x - 22.0, r.position.y + 4.0), Vector2(88.0, 44.0))
	if p_title.is_empty():
		return
	var f := HudKit.title_font()
	HudKit.draw_text(ci, f, Vector2(r.get_center().x, r.position.y + 62.0), p_title.to_upper(), TITLE_SIZE, HudKit.GOLD, 1, HudKit.SHADOW, 4)
	var w := minf(r.size.x - 120.0, 460.0)
	var k := HudKit.RULE_SCALE * 1.1
	HudKit.draw_hslice(ci, "quest_rule", Rect2(r.get_center().x - w * 0.5, r.position.y + 76.0 - HudKit.RULE_ROD_Y * k, w, HudKit.RULE_SIZE.y * k),
		HudKit.RULE_PATCH.x, HudKit.RULE_PATCH.y)


## Altta kapatan tuşlar: Esc ve sayfanın kendi tuşu (ör. M), «Kapat».
func _draw_footer(ci: Control) -> void:
	var text := "Kapat"
	var f := HudKit.body_font(500)
	var keys: Array = ["Esc"]
	if not toggle_action.is_empty():
		keys.append_array(ControlsPage.keys_of(String(toggle_action)))
	var widths: Array = keys.map(func(k: String) -> float: return GameMenu.keycap_width(k))
	var total := 0.0
	for w: float in widths:
		total += w + 8.0
	var tw := HudKit.text_width(f, text, 19)
	var x := panel_size.x * 0.5 - (total + 4.0 + tw) * 0.5
	var y := panel_size.y - 46.0
	for i in keys.size():
		GameMenu.draw_keycap(ci, Rect2(Vector2(x, y), Vector2(widths[i], 30.0)), str(keys[i]))
		x += float(widths[i]) + 8.0
	HudKit.draw_text(ci, f, Vector2(x + 4.0, y + 22.0), text, 19, HudKit.TEXT_DIM, 0, HudKit.SHADOW, 2)


## Panonun çizim yüzeyi.
class Canvas extends Control:
	var host: HudScreen

	func _draw() -> void:
		if host:
			host._draw_panel(self)

	func _gui_input(event: InputEvent) -> void:
		if host:
			host._content_gui_input(event)
