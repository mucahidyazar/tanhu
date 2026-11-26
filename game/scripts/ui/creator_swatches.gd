@tool
class_name CreatorSwatches
extends Control
## Renk seçenekleri için yuvarlak renk örnekleri (swatch) dizisi.
##
## - 0. renk (alfa = 0) "Doğal"dır: modelin kendi rengi korunur; iç içe iki halka simgesiyle çizilir.
## - Diğer renkler küçük, boyalı boncuklar gibi çizilir (üstte hafif parlaklık, altta gölge).
## - Seçili örneğin çevresinde koyu bir halka vardır; seçim değişince halka yeni örneğe kayar.
## - Fareyle üzerine gelinen örnek büyür; tıklayınca swatch_pressed yayılır.
## - fabric açıksa (pelerin boyası) örnekler boncuk değil kumaş parçasıdır: dokuma izi, kıvrım gölgesi ve alt kenarda
##   saçak; seçim halkası köşeleri yuvarlatılmış bir çerçevedir. Yerleşim ve tıklama alanı aynıdır.

signal swatch_pressed(index: int)
signal swatch_hovered(index: int)

## Bir örneğin yarıçapı ve iki örnek merkezi arasındaki uzaklık (piksel).
const RADIUS := 15.0
const SPACING := 38.0
## Kenarlarda halka için bırakılan boşluk.
const PADDING := 8.0
const RING_GAP := 4.5
## Seçim halkasının kayma hızı.
const RING_RATE := 16.0

const FALLBACK_RING := Color(0.14, 0.33, 0.33)
const FALLBACK_HOVER_RING := Color(0.15, 0.53, 0.58, 0.75)
const FALLBACK_NATURAL_FILL := Color(0.97, 0.95, 0.9)
const FALLBACK_NATURAL_LINE := Color(0.4, 0.38, 0.36)

## Gösterilen renkler (CharacterOptions.colors(field)).
var colors: Array[Color] = []:
	set(value):
		colors = value
		_hovered = -1
		update_minimum_size()
		queue_redraw()
## Seçili renk indeksi.
var selected := 0:
	set(value):
		selected = clampi(value, 0, maxi(colors.size() - 1, 0))
		set_process(true)
		queue_redraw()
## Örnekler kumaş parçası olarak mı çizilsin (pelerin boyası)?
var fabric := false:
	set(value):
		fabric = value
		queue_redraw()

var _hovered := -1
var _ring_x := -1.0
var _frame_box: StyleBoxFlat


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _get_minimum_size() -> Vector2:
	return CreatorSwatches.strip_size(colors.size())


## n örnekli dizinin kapladığı alan.
static func strip_size(count: int) -> Vector2:
	if count <= 0:
		return Vector2.ZERO
	return Vector2(PADDING * 2.0 + RADIUS * 2.0 + SPACING * float(count - 1), PADDING * 2.0 + RADIUS * 2.0)


## i. örneğin merkezinin yerel x konumu.
static func center_x(index: int) -> float:
	return PADDING + RADIUS + SPACING * float(index)


## Yerel bir noktanın hangi örneğe denk geldiği (yoksa -1). Saf fonksiyon: testlerde doğrudan sınanır.
static func index_at(local: Vector2, count: int, strip_height: float) -> int:
	if count <= 0:
		return -1
	if absf(local.y - strip_height * 0.5) > RADIUS + RING_GAP:
		return -1
	var i := roundi((local.x - PADDING - RADIUS) / SPACING)
	if i < 0 or i >= count:
		return -1
	if absf(local.x - center_x(i)) > SPACING * 0.5:
		return -1
	return i


## Üzerine gelinen örnek (yoksa -1).
func get_hovered() -> int:
	return _hovered


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_set_hovered(CreatorSwatches.index_at(event.position, colors.size(), size.y))
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var i := CreatorSwatches.index_at(event.position, colors.size(), size.y)
		if i >= 0:
			swatch_pressed.emit(i)
			accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		_set_hovered(-1)


func _set_hovered(index: int) -> void:
	if index == _hovered:
		return
	_hovered = index
	if index >= 0:
		swatch_hovered.emit(index)
	queue_redraw()


func _process(delta: float) -> void:
	var target := CreatorSwatches.center_x(selected)
	if _ring_x < 0.0:
		_ring_x = target
	_ring_x = lerpf(_ring_x, target, 1.0 - exp(-RING_RATE * delta))
	if absf(_ring_x - target) < 0.05:
		_ring_x = target
		set_process(false)
	queue_redraw()


func _draw() -> void:
	var cy := size.y * 0.5
	for i in colors.size():
		var center := Vector2(CreatorSwatches.center_x(i), cy)
		var r := RADIUS + (1.5 if i == _hovered else 0.0)
		if fabric:
			_draw_fabric(center, r, colors[i], i)
		elif colors[i].a <= 0.0:
			_draw_natural(center, r)
		else:
			_draw_bead(center, r, colors[i])
		if i == _hovered and i != selected:
			if fabric:
				_draw_frame(center, r + RING_GAP - 0.5, _color(&"hover_ring", FALLBACK_HOVER_RING), 2.0)
			else:
				draw_arc(center, r + RING_GAP - 0.5, 0.0, TAU, 48, _color(&"hover_ring", FALLBACK_HOVER_RING), 2.0, true)
	if not colors.is_empty():
		var ring_x := _ring_x if _ring_x >= 0.0 else CreatorSwatches.center_x(selected)
		if fabric:
			_draw_frame(Vector2(ring_x, cy), RADIUS + RING_GAP, _color(&"ring", FALLBACK_RING), 2.4)
		else:
			draw_arc(Vector2(ring_x, cy), RADIUS + RING_GAP, 0.0, TAU, 56, _color(&"ring", FALLBACK_RING), 2.4, true)


## Kumaş örneği: dört kenarı hafif dalgalı bir yün parçası, üstte iğne izi, solda kıvrımın ışığı, sağda gölgesi,
## ince dokuma çizgileri ve alt kenarda saçak. Her örnek indeksine bağlı küçük farklarla çizilir (el işi görünsün).
func _draw_fabric(center: Vector2, r: float, color: Color, index: int) -> void:
	var w := r * 0.92
	var h := r * 1.0
	var top := center.y - h
	var bottom := center.y + h * 0.78
	var outline := PackedVector2Array()
	var steps := 6
	# Üst kenar düz (askıdaki gibi), yan kenarlar hafif içe, alt kenar dalgalı.
	for i in steps + 1:
		outline.append(Vector2(lerpf(center.x - w, center.x + w, float(i) / steps), top))
	for i in range(1, steps + 1):
		var t := float(i) / steps
		outline.append(Vector2(center.x + w - sin(t * PI) * 1.2, lerpf(top, bottom, t)))
	for i in range(1, steps + 1):
		var t := float(i) / steps
		var wave := sin(t * TAU * 1.5 + float(index)) * 1.4
		outline.append(Vector2(lerpf(center.x + w, center.x - w, t), bottom + wave))
	for i in range(1, steps):
		var t := float(i) / steps
		outline.append(Vector2(center.x - w + sin(t * PI) * 1.2, lerpf(bottom, top, t)))
	# Gölge (parşömene düşen), koyu kenar, gövde.
	var shadow := PackedVector2Array()
	for p in outline:
		shadow.append(p + Vector2(1.6, 2.0))
	draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, 0.16))
	draw_colored_polygon(outline, color.darkened(0.3))
	var inner := PackedVector2Array()
	for p in outline:
		inner.append(center + (p - center) * 0.9 + Vector2(0.0, 0.4))
	draw_colored_polygon(inner, color)
	# Kıvrım: solda ışık, sağda gölge şeridi.
	var fold_x := center.x + w * 0.28
	draw_colored_polygon(PackedVector2Array([Vector2(center.x - w * 0.82, top + 2.0), Vector2(center.x - w * 0.15, top + 2.0),
		Vector2(center.x - w * 0.35, bottom - 2.0), Vector2(center.x - w * 0.82, bottom - 2.5)]), Color(1.0, 1.0, 1.0, 0.1))
	draw_colored_polygon(PackedVector2Array([Vector2(fold_x, top + 2.0), Vector2(fold_x + w * 0.42, top + 2.0),
		Vector2(fold_x + w * 0.3, bottom - 2.0), Vector2(fold_x - w * 0.1, bottom - 2.0)]), Color(0.0, 0.0, 0.0, 0.13))
	# Dokuma: ince yatay ve dikey izler.
	var weave := color.darkened(0.35)
	weave.a = 0.22
	for k in range(1, 5):
		var y := lerpf(top + 3.0, bottom - 3.0, float(k) / 5.0)
		draw_line(Vector2(center.x - w * 0.8, y), Vector2(center.x + w * 0.8, y), weave, 0.8, true)
	for k in range(1, 4):
		var x := lerpf(center.x - w * 0.8, center.x + w * 0.8, float(k) / 4.0)
		draw_line(Vector2(x, top + 3.0), Vector2(x, bottom - 3.0), weave, 0.6, true)
	# Üst kenarda iğne izi.
	var stitch := color.lightened(0.35)
	stitch.a = 0.55
	var x0 := center.x - w * 0.78
	while x0 < center.x + w * 0.7:
		draw_line(Vector2(x0, top + 2.6), Vector2(x0 + 2.4, top + 2.6), stitch, 1.0, true)
		x0 += 4.6
	# Saçak.
	var fringe := color.darkened(0.12)
	for k in 7:
		var x := lerpf(center.x - w * 0.8, center.x + w * 0.8, float(k) / 6.0)
		var y := bottom + sin(float(k) * 1.7 + float(index)) * 1.2
		draw_line(Vector2(x, y), Vector2(x + 0.4, y + 3.6), fringe, 1.1, true)


## Kumaş örneğinin seçim çerçevesi: köşeleri yuvarlatılmış ince dikdörtgen (kutu bir kez kurulur, rengi ve kalınlığı güncellenir).
func _draw_frame(center: Vector2, half: float, color: Color, width: float) -> void:
	var rect := Rect2(center - Vector2(half - 1.0, half), Vector2((half - 1.0) * 2.0, half * 2.0 + 3.0))
	if _frame_box == null:
		_frame_box = StyleBoxFlat.new()
		_frame_box.draw_center = false
		_frame_box.set_corner_radius_all(5)
		_frame_box.anti_aliasing = true
	_frame_box.border_color = color
	_frame_box.set_border_width_all(int(round(width)))
	draw_style_box(_frame_box, rect)


## "Doğal" simgesi: açık zemin üzerinde iç içe iki ince halka (◎).
func _draw_natural(center: Vector2, r: float) -> void:
	var line := _color(&"natural_line", FALLBACK_NATURAL_LINE)
	draw_circle(center, r, _color(&"natural_fill", FALLBACK_NATURAL_FILL), true, -1.0, true)
	draw_arc(center, r - 1.2, 0.0, TAU, 48, line, 1.6, true)
	draw_arc(center, r * 0.56, 0.0, TAU, 40, line, 1.6, true)


## Renk boncuğu: koyu kenar, gövde, üst-solda yumuşak parlaklık.
func _draw_bead(center: Vector2, r: float, color: Color) -> void:
	draw_circle(center, r, color.darkened(0.28), true, -1.0, true)
	draw_circle(center + Vector2(-0.6, -0.8), r - 1.6, color, true, -1.0, true)
	draw_circle(center + Vector2(-r * 0.22, -r * 0.26), r * 0.5, Color(1.0, 1.0, 1.0, 0.13), true, -1.0, true)
	draw_circle(center + Vector2(-r * 0.3, -r * 0.36), r * 0.22, Color(1.0, 1.0, 1.0, 0.22), true, -1.0, true)


func _color(item: StringName, fallback: Color) -> Color:
	return get_theme_color(item, &"CreatorSwatches") if has_theme_color(item, &"CreatorSwatches") else fallback
