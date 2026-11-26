class_name OrnateFrame
extends Control
## Tanhu 1'in her paneldeki çerçevesi: derin gece mavisi keçe, çift altın çizgi, düğüm işlemeli köşeler,
## üstte ve altta küçük gök mavisi birer taş, altında yumuşak bir gölge.
## İçeriğin arkasına OrnateFrame.wrap(içerik) ile konur.

@export var fill := Color(0.024, 0.031, 0.047, 0.95)
@export var gem := true
@export var corner := 34.0
@export var tint := UIKit.GOLD
## Kabın iç payı: çerçeve bu kadar büyük çizilir, içerik çizgilerin içinde nefes alır.
var pad := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


## Arka planı içeriğin çevresinde bir OrnateFrame olan PanelContainer.
static func wrap(content: Control, margin := 38.0, with_gem := true, corner_len := 34.0, tint_col := UIKit.GOLD, fill_col := Color(0.024, 0.031, 0.047, 0.95)) -> PanelContainer:
	var pc := PanelContainer.new()
	var sb := StyleBoxEmpty.new()
	sb.content_margin_left = margin
	sb.content_margin_right = margin
	sb.content_margin_top = margin * 0.8
	sb.content_margin_bottom = margin * 0.8
	pc.add_theme_stylebox_override("panel", sb)
	var f := OrnateFrame.new()
	f.gem = with_gem
	f.corner = corner_len
	f.tint = tint_col
	f.fill = fill_col
	f.pad = Vector2(margin, margin * 0.8)
	pc.add_child(f)
	pc.add_child(content)
	return pc


func _draw() -> void:
	var r := Rect2(-pad, size + pad * 2.0)
	for i in 7:                                         # yumuşak gölge
		draw_rect(r.grow(3.0 + i * 4.0), Color(0, 0, 0, 0.055), true)
	var top := fill.lightened(0.07)
	var bottom := fill.darkened(0.3)
	draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([top, top, bottom, bottom]))
	draw_rect(r.grow(-1.0), Color(tint.darkened(0.4), 0.95), false, 2.0)
	draw_rect(r.grow(-7.0), Color(tint, 0.45), false, 1.0)
	for c: Vector2 in [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), r.end]:
		_corner(c, r)
	if gem:
		_gem(Vector2(r.get_center().x, r.position.y))
		_gem(Vector2(r.get_center().x, r.end.y))


func _corner(c: Vector2, r: Rect2) -> void:
	var sx := 1.0 if c.x < r.get_center().x else -1.0
	var sy := 1.0 if c.y < r.get_center().y else -1.0
	var o := c + Vector2(sx, sy) * 7.0
	draw_line(o, o + Vector2(sx * corner, 0), tint, 2.0, true)
	draw_line(o, o + Vector2(0, sy * corner), tint, 2.0, true)
	var k := o + Vector2(sx, sy) * minf(13.0, corner * 0.4)
	var dr := minf(7.5, corner * 0.22)
	_diamond(k, dr, tint, 2.0)
	_diamond(k, dr * 0.4, Color(UIKit.SKY, 0.85), 1.6)


func _gem(p: Vector2) -> void:
	for s: float in [-1.0, 1.0]:
		draw_line(p + Vector2(s * 16.0, 0), p + Vector2(s * 64.0, 0), Color(tint, 0.9), 2.0, true)
	var pts := PackedVector2Array([p + Vector2(0, -11), p + Vector2(11, 0), p + Vector2(0, 11), p + Vector2(-11, 0)])
	draw_colored_polygon(pts, Color(0.05, 0.06, 0.085, 1.0))
	_diamond(p, 11.0, tint, 2.2)
	_diamond(p, 5.0, Color(UIKit.SKY, 0.95), 1.8)


func _diamond(p: Vector2, r: float, col: Color, w: float) -> void:
	draw_polyline(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r, 0), p + Vector2(0, r), p + Vector2(-r, 0), p + Vector2(0, -r)]), col, w, true)
