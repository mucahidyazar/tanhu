@tool
class_name KnotButton
extends Button
## Tanhu 1'in düğüm butonu, Tanhu'nun sıcak vurgusuyla.
##
## Görünüm (Tanhu 1): koyu keçe plaka, ince altın sırma kenar, iki yanda Türk sonsuzluk düğümü ve
## yazıya uzanan ince iplik çizgisi; yazı Cinzel, büyük harf.
## Vurgu (Tanhu): fare üzerine gelince ya da klavye / oyun kolu ile seçilince plakanın arkasında
## sıcak kehribar bir fırça darbesi ve yumuşak altın parıltı belirir, kenar ve düğümler altına döner,
## yazı altın tonuna geçer, buton hafifçe (×1,06) büyür; AudioManager.play_ui(&"hover") çalar.
## Basınca kısa bir aydınlanma + küçülme olur ve play_ui(&"click") çalar.
## Vurgu odağa bağlıdır: fareyle üzerine gelmek odağı alır, böylece aynı anda tek buton parlar.
## Pasif (disabled) buton soluk çizilir, parlamaz ve odak almaz.

## Vurgulu buton boyutu (1 = normal).
const HOVER_SCALE := 1.06
## Basılıyken buton boyutu.
const PRESS_SCALE := 0.97
## Vurgunun açılıp kapanma süresi (saniye).
const HIGHLIGHT_TIME := 0.22
## Odağı oyuncunun taşıdığını gösteren yön tuşları (bu sırada gelen odak "hover" sesi çalar).
const NAV_ACTIONS: Array[StringName] = [&"ui_up", &"ui_down", &"ui_left", &"ui_right", &"ui_focus_next", &"ui_focus_prev"]
## Düğümlerin ve ipliğin sönük rengi.
const KNOT_IDLE := Color(0.62, 0.52, 0.34, 0.9)
const KNOT_DISABLED := Color(0.35, 0.32, 0.28, 0.5)
## Vurgu parıltısının plakadan en çok taşma payı (piksel, 1080 satırlık tuvalde).
const GLOW_REACH := 10.0

## Yazı boyutu (piksel).
@export var font_size := 38:
	set(value):
		font_size = value
		if is_node_ready():
			add_theme_font_size_override("font_size", font_size)
## Fırça darbesinin biçim tohumu (her buton biraz farklı ışısın).
@export var brush_seed := 0.0:
	set(value):
		brush_seed = value
		if brush:
			brush.brush_seed = value
## Arayüz seslerini çalsın mı? (Testler kapatır.)
@export var play_sounds := true

## Plakanın arkasındaki fırça darbesi (vurguda ışır).
var brush: MenuBrush

var _glow := 0.0
var _tween: Tween
var _scale_tween: Tween
## Sıradaki odak fareden geliyor (oyuncu) mu?
var _by_mouse := false
## Odak kodla, sessizce veriliyor (menü açılırken).
var _quiet := false


func _init(label_text := "", size_px := 38) -> void:
	text = label_text
	font_size = size_px
	focus_mode = Control.FOCUS_ALL
	custom_minimum_size = Vector2(440, 74)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _ready() -> void:
	add_theme_font_override("font", UIKit.font("Cinzel", 600, 2))
	add_theme_font_size_override("font_size", font_size)
	add_theme_color_override("font_disabled_color", Color(0.55, 0.52, 0.47, 0.55))
	add_theme_color_override("font_pressed_color", Color(1.0, 0.95, 0.82))
	add_theme_stylebox_override("normal", UIKit.panel_style(Color(0.05, 0.06, 0.085, 0.86), Color(0.45, 0.38, 0.26, 0.8), 2, 3, Color(0, 0, 0, 0.45), 10))
	var hot := hot_style()
	add_theme_stylebox_override("hover", hot)
	add_theme_stylebox_override("focus", hot)
	add_theme_stylebox_override("pressed", hot)
	add_theme_stylebox_override("hover_pressed", hot)
	add_theme_stylebox_override("disabled", UIKit.panel_style(Color(0.05, 0.055, 0.07, 0.6), Color(0.3, 0.27, 0.22, 0.5), 2, 3, Color(0, 0, 0, 0.3), 6))
	brush = MenuBrush.new()
	brush.name = "Brush"
	# Parıltı plakanın üstünden ve altından en çok GLOW_REACH taşar (butonlar arası boşluğun yarısından az):
	# komşu butonun üstüne yayılmaz. Fırça darbesi yalnızca iki yandan taşar (kuru fırça uçları).
	brush.padding = GLOW_REACH
	brush.overscan = Vector2(18.0, 0.0)
	brush.brush_seed = brush_seed
	brush.ink = Color(MenuStyle.INK, 0.0)
	brush.rim = 0.0
	add_child(brush, false, Node.INTERNAL_MODE_FRONT)
	_set_glow(0.0)
	resized.connect(func() -> void: pivot_offset = size * 0.5)
	pivot_offset = size * 0.5
	if Engine.is_editor_hint():
		return
	mouse_entered.connect(_on_mouse_entered)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	pressed.connect(_play.bind(&"click"))


## Vurgulu plaka: sıcak koyu keçe, altın kenar ve yumuşak, kısa altın parıltı (en çok GLOW_REACH).
static func hot_style() -> StyleBoxFlat:
	return UIKit.panel_style(Color(0.1, 0.072, 0.04, 0.9), Color(MenuStyle.HOT_GOLD, 0.95), 2, 3, Color(1.0, 0.72, 0.36, 0.22), int(GLOW_REACH * 0.8))


## Vurgu ve basılma durumuna göre hedef boyut (saf fonksiyon; test edilebilir).
static func target_scale(highlighted: bool, held: bool) -> float:
	if held:
		return PRESS_SCALE
	return HOVER_SCALE if highlighted else 1.0


## Vurgu oranına (0..1) göre yazı rengi: kremden sıcak altına (saf fonksiyon).
static func text_color(glow: float) -> Color:
	var hot := Color(UIKit.TEXT.r * MenuStyle.HOT_TINT.r, UIKit.TEXT.g * MenuStyle.HOT_TINT.g, UIKit.TEXT.b * MenuStyle.HOT_TINT.b)
	return UIKit.TEXT.lerp(hot, clampf(glow, 0.0, 1.0))


## Odağı ses çalmadan alır (menü açılırken varsayılan butonu seçmek için).
## Buton görünmüyorsa, pasifse ya da odağa kapalıysa bir şey yapmaz.
func grab_focus_quietly() -> void:
	if disabled or not is_visible_in_tree() or focus_mode == Control.FOCUS_NONE:
		return
	_quiet = true
	grab_focus()
	_quiet = false


## Buton şu an vurgulu mu (odakta mı)?
func is_highlighted() -> bool:
	return _glow > 0.5 or has_focus()


## Vurgunun şu anki oranı (0..1).
func get_glow() -> float:
	return _glow


## Butonu fareye ve odağa açar ya da kapatır (ör. menü kaybolurken). Kapalıyken görünür kalır ama
## tepki vermez. Pasif butonlar açılınca da odak almaz.
func set_interactive(on: bool) -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE
	if not on and has_focus():
		release_focus()
	focus_mode = Control.FOCUS_ALL if on and not disabled else Control.FOCUS_NONE


## Buton şu an fareye ve odağa açık mı?
func is_interactive() -> bool:
	return mouse_filter != Control.MOUSE_FILTER_IGNORE and focus_mode != Control.FOCUS_NONE


## Butonu kullanılabilir / pasif yapar: pasif buton soluk çizilir ve odak almaz.
func set_available(on: bool) -> void:
	disabled = not on
	if disabled:
		if has_focus():
			release_focus()
		focus_mode = Control.FOCUS_NONE
		_kill(_tween)
		_set_glow(0.0)
		scale = Vector2.ONE
	elif mouse_filter != Control.MOUSE_FILTER_IGNORE:
		focus_mode = Control.FOCUS_ALL
	queue_redraw()


## Oyuncu şu an yön tuşlarıyla odağı taşıyor mu? (O sırada gelen odak "hover" sesi çalar.)
static func navigating() -> bool:
	for a in NAV_ACTIONS:
		if InputMap.has_action(a) and Input.is_action_pressed(a):
			return true
	return false


# --- Olaylar ----------------------------------------------------------------

func _on_mouse_entered() -> void:
	if disabled or focus_mode == Control.FOCUS_NONE or has_focus():
		return
	_by_mouse = true
	grab_focus()


func _on_focus_entered() -> void:
	# "hover" sesi oyuncuya (fare ya da yön tuşu) yanıt verir; kodun verdiği odağa değil.
	var by_player := (_by_mouse or navigating()) and not _quiet
	_by_mouse = false
	_hot(true)
	if by_player:
		_play(&"hover")


func _on_focus_exited() -> void:
	_by_mouse = false
	_hot(false)


func _on_button_down() -> void:
	_animate_scale(target_scale(true, true), 0.08)
	if brush:
		brush.press = 1.0


func _on_button_up() -> void:
	_animate_scale(target_scale(has_focus(), false), 0.18)
	if brush and is_inside_tree():
		create_tween().tween_property(brush, "press", 0.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


# --- Görünüm ----------------------------------------------------------------

func _hot(on: bool) -> void:
	if disabled and on:
		return
	_kill(_tween)
	var target := 1.0 if on else 0.0
	if not is_inside_tree():
		_set_glow(target)
		scale = Vector2.ONE * target_scale(on, false)
		return
	_tween = create_tween()
	_tween.tween_method(_set_glow, _glow, target, HIGHLIGHT_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_animate_scale(target_scale(on, false), HIGHLIGHT_TIME + 0.06)


func _animate_scale(target: float, duration: float) -> void:
	_kill(_scale_tween)
	if not is_inside_tree():
		scale = Vector2.ONE * target
		return
	_scale_tween = create_tween()
	_scale_tween.tween_property(self, "scale", Vector2.ONE * target, duration) \
		.set_trans(Tween.TRANS_BACK if target > 1.0 else Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _set_glow(value: float) -> void:
	_glow = value
	if brush:
		brush.highlight = value
	var c := text_color(value)
	for key in [&"font_color", &"font_hover_color", &"font_focus_color", &"font_hover_pressed_color"]:
		add_theme_color_override(key, c)
	queue_redraw()


func _process(_delta: float) -> void:
	# Yalnızca yanan düğüm nabız gibi atar; sönük olanı buton kendisi çizer.
	if _glow > 0.001:
		queue_redraw()


func _draw() -> void:
	var c := KNOT_DISABLED if disabled else KNOT_IDLE.lerp(MenuStyle.HOT_GOLD, _glow)
	var y := size.y * 0.5
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.004)
	for side: float in [-1.0, 1.0]:
		var x := 34.0 if side < 0.0 else size.x - 34.0
		_draw_knot(Vector2(x, y), 13.0, c)
		# yazıya uzanan iplik
		draw_line(Vector2(x + side * -26.0, y), Vector2(x + side * -58.0, y), Color(c, 0.6), 2.0, true)
		if _glow > 0.01 and not disabled:
			draw_circle(Vector2(x, y), 20.0 + 4.0 * pulse, Color(MenuStyle.HOT_GOLD, 0.14 * _glow))


## Türk sonsuzluk düğümü: iç içe geçmiş, döndürülmüş iki kare ve ortada bir nokta.
func _draw_knot(center: Vector2, r: float, c: Color) -> void:
	var pts_a := PackedVector2Array()
	var pts_b := PackedVector2Array()
	for i in 5:
		var a := PI * 0.5 * i + PI * 0.25
		pts_a.append(center + Vector2(cos(a), sin(a)) * r)
		pts_b.append(center + Vector2(cos(a - PI * 0.25), sin(a - PI * 0.25)) * r * 0.82)
	draw_polyline(pts_a, c, 2.2, true)
	draw_polyline(pts_b, c, 2.2, true)
	draw_circle(center, 2.6, c)


func _play(kind: StringName) -> void:
	if play_sounds and not Engine.is_editor_hint():
		MenuStyle.play_ui(self, kind)


static func _kill(tween: Tween) -> void:
	if tween and tween.is_valid():
		tween.kill()
