class_name GameHud
extends Control
## Serbest gezintide sol alt köşede beliren küçük, boyalı ipucu paneli.
##
## Tuşlar küçük krem "tuş kapakçıkları" olarak, eylemler yanında yazıyla gösterilir:
##   WASD: Yürü · Shift: Koş · Q/E: Kamerayı döndür · Tekerlek: Yakınlaş · Esc: Menü
## show_hints() paneli yumuşakça gösterir ve hint_duration saniye sonra kendiliğinden soldurur.
## hide_hud() paneli hemen (ya da kısa bir solmayla) gizler; örneğin menüye dönerken.
##
## Panel arayüz ölçeğinde (UIKit.ui_k) çizilir: sol alt köşesi yerinde kalır, yüksek çözünürlükte küçülür.
## Oyun içi HUD açıkken (GameplayHud, hud_style) panel HUD'un dilindedir ve yerini değiştirir: yuva şeridinin ve XP çubuğunun altında,
## ortalı ince bir lacivert şerit (altın kenar çizgileri, iki ucunda gümüş bulut), tuşlar lacivert-altın kapaklarda krem Cinzel.
##
## Bu düğüm, boyalı ekran efektinin (PainterlyOverlay, katman 1) üstündeki bir CanvasLayer'da durmalıdır.

## Panel tamamen kaybolduğunda yayılır (kendiliğinden ya da hide_hud ile).
signal hints_hidden

## Tuş → eylem çiftleri, ekrandaki sırayla (yürüyüş ve kamera; Çocukluk'un ilk ipucu da budur, story.md §5 «tek ipucu»).
const HINTS: Array = [
	["WASD", "Yürü"],
	["Shift", "Koş"],
	["Q/E", "Kamerayı döndür"],
	["Tekerlek", "Yakınlaş"],
	["Esc", "Menü"],
]
## Çocuk denetleyicisinin tuşları (Serbest Gez'in Çocuğu, küçük Mete): E biner, iner, yerden alır; Shift koşar, binekte dürter; sağ tuş
## nişan alır, sol tuş (ya da sağ tuşu bırakmak) oku bırakır; sağ tuş nişan olduğu için kamerayı orta tuşla sürükleme döndürür.
const CHILD_HINTS: Array = [
	["WASD", "Yürü"],
	["Shift", "Koş · dürt"],
	["E", "Bin · in · al"],
	["Sağ tık", "Nişan"],
	["Sol tık", "Bırak"],
	["Orta tuş", "Kamera"],
	["Esc", "Menü"],
]
## Düz yazı biçiminde çiftler arasındaki ayraç.
const SEPARATOR := " · "
const FADE_IN := 0.7
const FADE_OUT := 1.4
const QUICK_FADE := 0.3
## Belirirken panelin aşağıdan yükseldiği mesafe (piksel).
const RISE := 10.0

## Panelin tam görünür kaldığı süre (saniye); sonra kendiliğinden solar.
@export var hint_duration := 7.0
## Animasyon hız çarpanı (testler hızlandırmak için kullanır).
@export var transition_speed := 1.0
## Panelin alt kenarının ekranın altına uzaklığı (1080 satır; ölçekle küçülür). Oyun içi HUD açıkken (GameplayHud) yuva şeridinin ve
## ipucunun üstüne kalkar.
var bottom_margin := 34.0:
	set(value):
		bottom_margin = value
		if _panel:
			_place_panel()
## HUD'un arayüz ölçeğine göre çarpanı (HudKit.hud_scale, 0,8; K104; GameplayHud verir, yalnız HUD'un dilindeyken 1'den farklı): şerit
## ui_k() × bu çarpanla, ekranın alt ortası çevresinde çizilir. GameplayHud XP çubuğunu şeridin üstünde tutar (xp_floor).
var extra_scale := 1.0:
	set(value):
		if is_equal_approx(extra_scale, value):
			return
		extra_scale = value
		if _panel:
			_apply_ui_scale()
## Oyun içi HUD'un dili ve yeri (GameplayHud açar): alt ortada, XP çubuğunun altında; kapalıyken Tanhu 1'in fırça paneli, sol altta.
var hud_style := false:
	set(value):
		if hud_style == value:
			return
		hud_style = value
		if _panel:
			_apply_style()

var _tween: Tween
var _showing := false
var _ribbon: Control
## Gösterilen çiftler (show_hints değiştirir).
var _hints: Array = HINTS

@onready var _content: Control = %Content
@onready var _panel: Control = %HintPanel
@onready var _row: HBoxContainer = %HintRow


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# HUD'un şeridi panelin kardeşidir (kap içi değil: PanelContainer çocuklarını yerleştirir); panelin yerini ve ölçeğini izler.
	_ribbon = Ribbon.new()
	_ribbon.name = "Ribbon"
	_ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ribbon.visible = false
	_content.add_child(_ribbon)
	_content.move_child(_ribbon, _panel.get_index())
	_build_hints()
	_panel.resized.connect(_apply_ui_scale)
	UIKit.on_ui_scale_changed(self, _apply_ui_scale)
	_apply_ui_scale()
	if _showing:
		# show_hints() sahneye eklenmeden önce çağrıldıysa şimdi düzgünce başlat.
		show_hints()
	else:
		visible = false
		modulate.a = 0.0


## İpuçlarını gösterir; hint_duration saniye sonra kendiliğinden solar. hints verilirse o çiftler (ör. CHILD_HINTS), yoksa HINTS.
func show_hints(hints: Array = []) -> void:
	var wanted: Array = hints if not hints.is_empty() else HINTS
	if wanted != _hints:
		_hints = wanted
		if _row:
			_build_hints()
	_kill_tween()
	_showing = true
	visible = true
	if not is_inside_tree():
		modulate.a = 1.0
		return
	_content.position.y = RISE * (1.0 - modulate.a)
	_tween = create_tween().set_speed_scale(maxf(transition_speed, 0.01))
	_tween.set_parallel(true)
	_tween.tween_property(self, "modulate:a", 1.0, FADE_IN).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_content, "position:y", 0.0, FADE_IN + 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.chain().tween_interval(hint_duration)
	# Solma başlayınca panel artık "gösteriliyor" sayılmaz (bkz. is_showing).
	_tween.chain().tween_callback(_mark_fading)
	_tween.chain().tween_property(self, "modulate:a", 0.0, FADE_OUT).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.chain().tween_callback(_on_faded_out)
	# Serbest gezinti ağır bir yüklemenin ardından başlayabilir: ipucu süresi o kareye harcanmasın.
	MenuStyle.play_when_settled(self, _tween)


## Paneli gizler. animated=true ise kısa bir solmayla.
## Oyun duraklatılmış olsa bile (ör. Esc ile menüye dönülürken) solma tamamlanır.
func hide_hud(animated: bool = true) -> void:
	_kill_tween()
	_showing = false
	if not animated or not visible or not is_inside_tree():
		_on_faded_out()
		return
	_tween = create_tween().set_speed_scale(maxf(transition_speed, 0.01))
	_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_tween.tween_property(self, "modulate:a", 0.0, QUICK_FADE).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.tween_callback(_on_faded_out)


## Panel şu an gösteriliyor mu (belirirken ve tam görünürken true; solmaya başlayınca false)?
func is_showing() -> bool:
	return _showing and visible


## İpuçlarının düz yazı hâli: "WASD: Yürü · Shift: Koş · ..."
func get_hint_text() -> String:
	return format_hints(_hints)


## Tuş/eylem çiftlerini tek satırlık yazıya çevirir (saf fonksiyon; test edilebilir).
static func format_hints(hints: Array) -> String:
	var parts := PackedStringArray()
	for pair in hints:
		parts.append("%s: %s" % [pair[0], pair[1]])
	return SEPARATOR.join(parts)


func _build_hints() -> void:
	for child in _row.get_children():
		_row.remove_child(child)
		child.queue_free()
	for i in _hints.size():
		if i > 0:
			_row.add_child(_make_label("·", &"HudSeparator"))
		var pair := HBoxContainer.new()
		pair.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pair.add_theme_constant_override(&"separation", 8)
		var key := _make_label(str(_hints[i][0]), &"HudKey")
		key.name = "Key"
		var action := _make_label(str(_hints[i][1]), &"HudAction")
		action.name = "Action"
		pair.add_child(key)
		pair.add_child(action)
		pair.name = "Hint%d" % i
		_row.add_child(pair)


func _make_label(text: String, variation: StringName) -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if hud_style:
		HudKit.style_key_label(label, variation)
	return label


## HUD'un dili açılıp kapanınca: yer, şerit ve yazıların biçimi.
func _apply_style() -> void:
	var brush := _panel.get_node_or_null(^"Brush") as CanvasItem
	if brush:
		brush.visible = not hud_style
	_ribbon.visible = hud_style
	if hud_style:
		_panel.anchor_left = 0.5
		_panel.anchor_right = 0.5
		_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
		_panel.add_theme_stylebox_override(&"panel", HudKit.key_strip_box())
		_row.add_theme_constant_override(&"separation", 10)
	else:
		_panel.anchor_left = 0.0
		_panel.anchor_right = 0.0
		_panel.grow_horizontal = Control.GROW_DIRECTION_END
		_panel.offset_left = 34.0
		_panel.offset_right = 34.0
		_panel.remove_theme_stylebox_override(&"panel")
		_row.add_theme_constant_override(&"separation", 14)
	_build_hints()
	_panel.reset_size()
	_place_panel()


## Şeridin üst kenarının ekranın altına uzaklığı (1080 satır, ölçeksiz: alt pay ve panelin boyu); ekranda × ui_k() × extra_scale.
func strip_top() -> float:
	if _panel == null:
		return 0.0
	return bottom_margin + maxf(_panel.offset_bottom - _panel.offset_top, _panel.get_combined_minimum_size().y)


## Paneli arayüz ölçeğinde (HUD'un dilinde × HUD ölçeği), çapasının çevresinde çizer; HUD'un şeridi panelin üstüne oturur.
func _apply_ui_scale() -> void:
	UIKit.scale_at_anchor(_panel, UIKit.ui_k() * extra_scale)
	if _ribbon:
		_ribbon.position = _panel.position
		_ribbon.size = _panel.size
		_ribbon.pivot_offset = _panel.pivot_offset
		_ribbon.scale = _panel.scale
		_ribbon.queue_redraw()


func _place_panel() -> void:
	var h := maxf(_panel.offset_bottom - _panel.offset_top, _panel.get_combined_minimum_size().y)
	_panel.offset_bottom = -bottom_margin
	_panel.offset_top = -bottom_margin - h
	if hud_style:
		var w := _panel.get_combined_minimum_size().x
		_panel.offset_left = -w * 0.5
		_panel.offset_right = w * 0.5
	_apply_ui_scale()


## HUD'un dilindeki şerit: lacivert, yarı saydam; üstte ve altta ince altın çizgi, iki ucunda gümüş bulut (XP çubuğununki gibi).
class Ribbon extends Control:
	func _draw() -> void:
		var r := Rect2(Vector2(22.0, 1.0), size - Vector2(44.0, 2.0))
		if r.size.x <= 0.0:
			return
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.035, 0.07, 0.14, 0.78)
		sb.set_corner_radius_all(int(r.size.y * 0.5))
		sb.border_color = Color(HudKit.GOLD, 0.55)
		sb.set_border_width_all(1)
		sb.anti_aliasing = true
		draw_style_box(sb, r)
		var cloud := Vector2(r.size.y * 2.0, r.size.y)
		HudKit.draw_centered(self, "cloud_left", Vector2(r.position.x - cloud.x * 0.18, r.get_center().y), cloud)
		HudKit.draw_centered(self, "cloud_right", Vector2(r.end.x + cloud.x * 0.18, r.get_center().y), cloud)


func _mark_fading() -> void:
	_showing = false


func _on_faded_out() -> void:
	var was_visible := visible
	_showing = false
	visible = false
	modulate.a = 0.0
	if was_visible:
		hints_hidden.emit()


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null
