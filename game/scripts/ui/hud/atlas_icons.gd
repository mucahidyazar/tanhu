class_name AtlasIcons
extends RefCounted
## Atlasın küçük simgeleri (prototipin src/map/atlas.js ICONS'u: kabartmanın üstünde duran minyatürler); burada 2B, hafif yukarıdan
## bakan çizimler: başkent ve şehir (sur, köşe kuleleri, damlı yapı), vaha (kum avlu, ağaçlar), ordu (büyük yurt, iki küçük yurt,
## sancak), kanat beyi (yurt ve sancak), yurtlar (üç yurt), kutsal yer (taş yığını, direk, renkli bezler), olay (bayrak).
## Boy ekranda sabittir (prototip: görüşle ölçeklenen minyatür, ekranda ≈30 px). Ayak noktası yerdeki noktadır.
##   AtlasIcons.draw(ci, "city", Vector2(400, 300), 30.0)

const WALL := Color("#b8a88a")
const WALL_DARK := Color("#8f8268")
const ROOF := Color("#7c3a2a")
const HALL := Color("#a53a2c")
const SLATE := Color("#3f3a44")
const FELT := Color("#e6d7b6")
const FELT_SHADE := Color("#bfae88")
const CROWN := Color("#7c2a22")
const POLE := Color("#5c4128")
const GOLD := Color("#d9b26a")
const RED := Color("#8a2622")
const LEAF := Color("#5f8247")
const SAND := Color("#c9a878")
const STONE := Color("#8f8678")
const OUTLINE := Color(0.08, 0.05, 0.03, 0.75)


static func draw(ci: CanvasItem, kind: String, at: Vector2, size: float) -> void:
	var s := size / 30.0
	# Yere düşen yumuşak gölge.
	_ellipse(ci, at + Vector2(1.5, 1.0) * s, Vector2(15.0, 5.0) * s, Color(0.05, 0.03, 0.02, 0.32))
	match kind:
		"capital":
			_walled(ci, at, s * 1.15, true)
		"city":
			_walled(ci, at, s, false)
		"oasis":
			_oasis(ci, at, s)
		"ordu":
			_yurt(ci, at + Vector2(-9.0, 1.0) * s, s * 0.62, FELT_SHADE)
			_yurt(ci, at + Vector2(9.0, 2.0) * s, s * 0.62, FELT_SHADE)
			_yurt(ci, at, s, FELT)
			_banner(ci, at + Vector2(6.0, -2.0) * s, s, RED)
		"clan":
			_yurt(ci, at, s * 0.8, FELT)
			_banner(ci, at + Vector2(7.0, 0.0) * s, s * 0.8, GOLD)
		"tents":
			_yurt(ci, at + Vector2(-6.0, -2.0) * s, s * 0.55, Color("#cdbb94"))
			_yurt(ci, at + Vector2(6.0, -1.0) * s, s * 0.5, Color("#d8c7a0"))
			_yurt(ci, at + Vector2(0.0, 2.0) * s, s * 0.5, FELT_SHADE)
		"shrine":
			_shrine(ci, at, s)
		"flag":
			_flag(ci, at, s)


static func _ellipse(ci: CanvasItem, c: Vector2, r: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	ci.draw_colored_polygon(pts, col)


static func _poly(ci: CanvasItem, pts: PackedVector2Array, col: Color, outline := true) -> void:
	ci.draw_colored_polygon(pts, col)
	if outline:
		var closed := pts.duplicate()
		closed.append(pts[0])
		ci.draw_polyline(closed, OUTLINE, 1.0, true)


## Sur ve kuleler (yukarıdan eğik: ön yüz ve üst yüz), içinde damlı yapı.
static func _walled(ci: CanvasItem, at: Vector2, s: float, capital: bool) -> void:
	var w := 13.0 * s
	var d := 5.0 * s
	var h := 4.0 * s
	var base := at + Vector2(0.0, -1.0) * s
	# Üst yüz (avlu), ön duvar.
	_poly(ci, PackedVector2Array([base + Vector2(-w, -h), base + Vector2(0.0, -h - d), base + Vector2(w, -h), base + Vector2(0.0, -h + d)]), WALL_DARK)
	_poly(ci, PackedVector2Array([base + Vector2(-w, -h), base + Vector2(0.0, -h + d), base + Vector2(0.0, d), base + Vector2(-w, 0.0)]), WALL)
	_poly(ci, PackedVector2Array([base + Vector2(0.0, -h + d), base + Vector2(w, -h), base + Vector2(w, 0.0), base + Vector2(0.0, d)]), WALL.darkened(0.12))
	# Köşe kuleleri.
	for p: Vector2 in [Vector2(-w, -h), Vector2(w, -h), Vector2(0.0, -h + d), Vector2(0.0, -h - d)]:
		var t := base + p
		ci.draw_rect(Rect2(t + Vector2(-1.8, -4.5) * s, Vector2(3.6, 5.0) * s), WALL)
		ci.draw_rect(Rect2(t + Vector2(-1.8, -4.5) * s, Vector2(3.6, 5.0) * s), OUTLINE, false, 1.0)
	# Damlı yapı.
	var hall := base + Vector2(0.0, -h - 1.0 * s)
	var hw := (6.0 if capital else 4.0) * s
	var hh := (5.0 if capital else 3.5) * s
	ci.draw_rect(Rect2(hall + Vector2(-hw * 0.7, -hh), Vector2(hw * 1.4, hh)), HALL if capital else WALL)
	ci.draw_rect(Rect2(hall + Vector2(-hw * 0.7, -hh), Vector2(hw * 1.4, hh)), OUTLINE, false, 1.0)
	_poly(ci, PackedVector2Array([hall + Vector2(-hw, -hh), hall + Vector2(0.0, -hh - hw * 0.8), hall + Vector2(hw, -hh)]), SLATE if capital else ROOF)


static func _oasis(ci: CanvasItem, at: Vector2, s: float) -> void:
	_poly(ci, PackedVector2Array([at + Vector2(-11.0, -2.0) * s, at + Vector2(0.0, -7.0) * s, at + Vector2(11.0, -2.0) * s, at + Vector2(0.0, 3.0) * s]), SAND)
	ci.draw_rect(Rect2(at + Vector2(-3.0, -7.0) * s, Vector2(6.0, 4.0) * s), Color("#d8bd83"))
	for p: Vector2 in [Vector2(-7.0, -3.0), Vector2(6.0, -4.0), Vector2(1.0, 1.0)]:
		var b := at + p * s
		ci.draw_line(b, b + Vector2(0.0, -6.0) * s, Color("#6a4c30"), 1.4 * s, true)
		ci.draw_circle(b + Vector2(0.0, -7.0) * s, 3.4 * s, LEAF)
		ci.draw_circle(b + Vector2(-1.0, -8.0) * s, 1.5 * s, LEAF.lightened(0.2))


## Keçe yurt: kubbe, duvar, tepesinde koyu tünlük halkası.
static func _yurt(ci: CanvasItem, at: Vector2, s: float, felt: Color) -> void:
	var r := 8.0 * s
	var wall_h := 4.0 * s
	var pts := PackedVector2Array([at + Vector2(-r, 0.0), at + Vector2(-r, -wall_h)])
	for i in 9:
		var a := PI + PI * i / 8.0
		pts.append(at + Vector2(cos(a) * r, -wall_h + sin(a) * r * 0.75))
	pts.append(at + Vector2(r, 0.0))
	_poly(ci, pts, felt)
	ci.draw_line(at + Vector2(-r, -wall_h), at + Vector2(r, -wall_h), Color("#6a2c20"), 1.2 * s, true)
	ci.draw_circle(at + Vector2(0.0, -wall_h - r * 0.72), 2.0 * s, CROWN)
	ci.draw_rect(Rect2(at + Vector2(-1.6, -3.2) * s, Vector2(3.2, 3.2) * s), Color("#6a2c20"))


static func _banner(ci: CanvasItem, at: Vector2, s: float, col: Color) -> void:
	var top := at + Vector2(0.0, -24.0) * s
	ci.draw_line(at, top, POLE, 1.6 * s, true)
	_poly(ci, PackedVector2Array([top + Vector2(0.0, 1.0) * s, top + Vector2(9.0, 3.0) * s, top + Vector2(0.0, 7.0) * s]), col)
	ci.draw_circle(top, 1.4 * s, GOLD)


static func _shrine(ci: CanvasItem, at: Vector2, s: float) -> void:
	var r := 7.0 * s
	var pts := PackedVector2Array()
	for i in 13:
		var a := PI + PI * i / 12.0
		pts.append(at + Vector2(cos(a) * r, sin(a) * r * 0.8))
	_poly(ci, pts, STONE)
	var top := at + Vector2(0.0, -22.0) * s
	ci.draw_line(at + Vector2(0.0, -4.0) * s, top, Color("#7a5a38"), 1.6 * s, true)
	var cols := [Color("#3f7fa8"), Color("#e8dcc0"), Color("#a53a2c"), GOLD, Color("#3f7fa8")]
	for i in 5:
		var a := -PI * 0.5 + (i - 2) * 0.45
		var end := at + Vector2(cos(a + PI * 0.5) * 11.0, -2.0 + absf(i - 2) * 1.5) * s
		ci.draw_line(top + Vector2(0.0, 2.0) * s, end, cols[i], 1.2 * s, true)


static func _flag(ci: CanvasItem, at: Vector2, s: float) -> void:
	_ellipse(ci, at, Vector2(3.0, 1.6) * s, Color("#6f6a64"))
	var top := at + Vector2(0.0, -26.0) * s
	ci.draw_line(at, top, Color("#2f2c2a"), 1.8 * s, true)
	_poly(ci, PackedVector2Array([top + Vector2(0.5, 1.0) * s, top + Vector2(12.0, 1.0) * s, top + Vector2(12.0, 9.0) * s, top + Vector2(0.5, 9.0) * s]), GOLD)
	ci.draw_rect(Rect2(top + Vector2(3.0, 3.0) * s, Vector2(7.0, 4.0) * s), RED)
