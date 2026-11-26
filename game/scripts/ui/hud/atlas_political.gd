class_name AtlasPolitical
extends Node
## Atlasın siyasi katmanı (prototipin src/map/relief.js paintOverlay'i): dönemin açık devletleri, hakimiyetleri ve lekeleri iki dokuya
## çizilir. Renk araziyi örtmez, yalnız tonlar (hud_atlas.gdshader karıştırır): dağlar ve ırmaklar sınırların altında okunur.
##   dolgu (FILL_W)   devlet ve çekirdek düz renk (0,2 / 0,26), hakimiyet soluk (0,13; içindeki çekirdek oyulur), leke yumuşak elips
##   çizgi (LINE_W)   devlet ve çekirdek: içe sızan ışıma (sınırın içine kırpılmış geniş iki çizgi), keskin renkli çizgi, ince koyu mürekkep;
##                    hakimiyet: kesik çizgi
## Çizim sırası: hakimiyet en altta, sonra devlet, leke, en üstte çekirdek. Açılmamış satır hiç çizilmez: ne rengi ne sınırı kalır.
## İki SubViewport yalnız boyanınca bir kez çizer (UPDATE_ONCE: dönem, katman ya da açılma değişince); kare başına çizim yoktur (K63).
## Dokular kâğıdın sRGB'sinde, önceden çarpılmış alfayla durur (saydam zemin): gölgelendirici rengi alfaya böler.

const FILL_W := 1600
const LINE_W := 3072
## Prototipin canvas çizgi kalınlıkları (LINE_W'de piksel) ve kesik çizginin adımları.
const DASH_ON := 18.0
const DASH_OFF := 11.0
const RANK := {"realm": 0, "state": 1, "stain": 2, "core": 3}
const INK_LINE := Color(14.0 / 255.0, 8.0 / 255.0, 5.0 / 255.0, 0.55)
const ERASE_SHADER := "shader_type canvas_item;\nrender_mode blend_disabled;\nvoid fragment() { COLOR = vec4(0.0); }\n"

var geo: AtlasGeo
var fill_texture: Texture2D
var line_texture: Texture2D
## Son boyamanın anahtarı (dönem ve açık siyasi satırlar): değişmediyse yeniden boyanmaz.
var key := ""

var _fill_vp: SubViewport
var _line_vp: SubViewport
var _fill_root: Node2D
var _line_root: Node2D
var _erase: ShaderMaterial

static var _erase_shader: Shader


func _init(p_geo: AtlasGeo = null) -> void:
	geo = p_geo if p_geo else AtlasGeo.shared()
	name = "AtlasPolitical"
	# Dolgunun kenarı üçgendir (kenar yumuşatma ister: 2×), çizgiler kendi yumuşatmasıyla çizilir (büyük dokuda çoklu örnek bellek yer).
	_fill_vp = _viewport(FILL_W, Viewport.MSAA_2X)
	_line_vp = _viewport(LINE_W, Viewport.MSAA_DISABLED)
	_fill_root = Node2D.new()
	_line_root = Node2D.new()
	_fill_vp.add_child(_fill_root)
	_line_vp.add_child(_line_root)
	add_child(_fill_vp)
	add_child(_line_vp)
	fill_texture = _fill_vp.get_texture()
	line_texture = _line_vp.get_texture()
	if _erase_shader == null:
		_erase_shader = Shader.new()
		_erase_shader.code = ERASE_SHADER
	_erase = ShaderMaterial.new()
	_erase.shader = _erase_shader


func _viewport(w: int, msaa: Viewport.MSAA) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = Vector2i(w, roundi(w * geo.map_d / geo.map_w))
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	vp.msaa_2d = msaa
	return vp


## Satır bu dönemde boyanır mı (saf): söylenti dönemi yalnız sönük addır, rengi ve sınırı yoktur (relief.js drawnIn).
static func drawn_in(p: Dictionary, era: String) -> bool:
	if not (p.get("eras", []) as Array).has(era):
		return false
	var rumour: Variant = p.get("rumour")
	return not (rumour is Dictionary and ((rumour as Dictionary).get("eras", []) as Array).has(era))


## Dönemin boyanacak satırları (saf; çizim sırasıyla): katmanı açık (layers'ta false olmayan) ve açılmış olanlar.
static func painted_rows(polities: Array, era: String, layers: Dictionary, is_open: Callable) -> Array:
	var out: Array = []
	for p: Dictionary in polities:
		if drawn_in(p, era) and layers.get(str(p.get("layer", "")), true) != false and bool(is_open.call(p)):
			out.append(p)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(RANK.get(str(a["style"]), 3)) < int(RANK.get(str(b["style"]), 3)))
	return out


## Dönemin çekirdek devleti: hakimiyet dolgusu onun yerini oyar (açılmamışsa oyulmaz, yeri delik gibi sezilmesin).
static func core_of(polities: Array, era: String, is_open: Callable) -> Dictionary:
	for p: Dictionary in polities:
		if str(p.get("style", "")) == "core" and drawn_in(p, era) and bool(is_open.call(p)):
			return p
	return {}


## Boyar (anahtar değişmediyse ve force yoksa bir şey yapmaz); çizim bir sonraki karededir.
func paint(era: String, layers: Dictionary, is_open: Callable, force := false) -> void:
	var polities := geo.rows("polities")
	var list := painted_rows(polities, era, layers, is_open)
	var k := era
	for p: Dictionary in list:
		k += "," + str(p["id"])
	if not force and k == key:
		return
	key = k
	for c in _fill_root.get_children():
		c.queue_free()
		_fill_root.remove_child(c)
	for c in _line_root.get_children():
		c.queue_free()
		_line_root.remove_child(c)
	var core := core_of(polities, era, is_open)
	var kf := float(FILL_W) / geo.map_w
	var kl := float(LINE_W) / geo.map_w
	for p: Dictionary in list:
		var col := Color(str(p["color"]))
		var style := str(p["style"])
		if style == "stain":
			_stain(_fill_root, p, kf, col)
			continue
		var pts: PackedVector2Array = geo.borders.get(str(p["id"]), PackedVector2Array())
		if pts.size() < 3:
			continue
		var fill_pts := _scaled(pts, kf)
		var line_pts := _scaled(pts, kl)
		if style == "realm":
			_polygon(_fill_root, fill_pts, Color(col, 0.13))
			if not core.is_empty() and geo.borders.has(str(core["id"])):
				var hole := _polygon(_fill_root, _scaled(geo.borders[str(core["id"])], kf), Color(0, 0, 0, 0))
				hole.material = _erase
			_dashed(_line_root, line_pts, Color(col, 0.92), 3.4)
			continue
		var strong := style == "core"
		_polygon(_fill_root, fill_pts, Color(col, 0.26 if strong else 0.2))
		# Sınırın içine sızan ışıma (canvas'ta çokgene kırpılmış geniş çizgi): kırpılan çizginin içte kalan yarısı, sınırdan çeyrek
		# genişlik içeri kaydırılmış yarım genişlikte bir çizgidir.
		_inner_band(_line_root, line_pts, Color(col, 0.18), 46.0 if strong else 32.0)
		_inner_band(_line_root, line_pts, Color(col, 0.3), 20.0 if strong else 14.0)
		_stroke(_line_root, line_pts, Color(col, 1.0), 3.6 if strong else 2.8)
		_stroke(_line_root, line_pts, INK_LINE, 0.9)
	_fill_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	_line_vp.render_target_update_mode = SubViewport.UPDATE_ONCE


func _scaled(pts: PackedVector2Array, k: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(pts.size())
	var half := Vector2(geo.map_w, geo.map_d) * 0.5
	for i in pts.size():
		out[i] = (pts[i] + half) * k
	return out


func _polygon(parent: Node, pts: PackedVector2Array, col: Color) -> Node2D:
	var n := Node2D.new()
	var tri := Geometry2D.triangulate_polygon(pts)
	n.draw.connect(func() -> void:
		if tri.is_empty():
			n.draw_colored_polygon(pts, col)
			return
		var colors := PackedColorArray()
		colors.resize(pts.size())
		colors.fill(col)
		RenderingServer.canvas_item_add_triangle_array(n.get_canvas_item(), tri, pts, colors))
	parent.add_child(n)
	return n


## Çokgenin içine kırpılmış width genişliğinde çizgi: içe width/4 kaydırılmış yol, width/2 kalınlıkta (yuvarlak köşe).
func _inner_band(parent: Node, pts: PackedVector2Array, col: Color, width: float) -> void:
	# offset_polygon eksi payla yönden bağımsız içe büzer; büzülen çokgen birkaç parçaya ayrılabilir, her biri çizilir.
	for inset: PackedVector2Array in Geometry2D.offset_polygon(pts, -width * 0.25, Geometry2D.JOIN_ROUND):
		if inset.size() >= 3:
			_stroke(parent, inset, col, width * 0.5)


func _stroke(parent: Node, pts: PackedVector2Array, col: Color, width: float) -> void:
	var n := Node2D.new()
	var closed := pts.duplicate()
	closed.append(pts[0])
	n.draw.connect(func() -> void: n.draw_polyline(closed, col, width, true))
	parent.add_child(n)


## Kesik çizgi (hakimiyet): yol boyunca DASH_ON çizili, DASH_OFF boş; adım köşeden köşeye taşınır.
func _dashed(parent: Node, pts: PackedVector2Array, col: Color, width: float) -> void:
	var dashes: Array[PackedVector2Array] = []
	var cur := PackedVector2Array()
	var on := true
	var left := DASH_ON
	var n := pts.size()
	for i in n:
		var a := pts[i]
		var b := pts[(i + 1) % n]
		var seg := a.distance_to(b)
		var t := 0.0
		if on and cur.is_empty():
			cur.append(a)
		while seg - t > left:
			t += left
			var p := a.lerp(b, t / seg)
			if on:
				cur.append(p)
				dashes.append(cur)
				cur = PackedVector2Array()
			else:
				cur = PackedVector2Array([p])
			on = not on
			left = DASH_ON if on else DASH_OFF
		left -= seg - t
		if on:
			cur.append(b)
	if cur.size() > 1:
		dashes.append(cur)
	var node := Node2D.new()
	node.draw.connect(func() -> void:
		for d in dashes:
			node.draw_polyline(d, col, width, true))
	parent.add_child(node)


## Sınırı belirsiz yurt: elips, ortası 0,34, 0,65'te 0,22, kenarda saydam (prototipin radyal geçişi).
func _stain(parent: Node, p: Dictionary, k: float, col: Color) -> void:
	var blob: Array = p.get("blob", [])
	if blob.size() < 4:
		return
	var c := geo.to_map(float(blob[0]), float(blob[1]))
	var center := Vector2((c.x + geo.map_w * 0.5) * k, (c.y + geo.map_d * 0.5) * k)
	var rx := float(blob[2]) * geo.units_per_deg_lon() * k
	var rz := float(blob[3]) * geo.units_per_deg_lat() * k
	var seg := 48
	var points := PackedVector2Array([center])
	var colors := PackedColorArray([Color(col, 0.34)])
	for ring: Array in [[0.65, 0.22], [1.0, 0.0]]:
		for i in seg:
			var a := TAU * i / seg
			points.append(center + Vector2(cos(a) * rx, sin(a) * rz) * float(ring[0]))
			colors.append(Color(col, float(ring[1])))
	var idx := PackedInt32Array()
	for i in seg:
		var j := (i + 1) % seg
		idx.append_array([0, 1 + i, 1 + j])
		idx.append_array([1 + i, 1 + seg + i, 1 + seg + j])
		idx.append_array([1 + i, 1 + seg + j, 1 + j])
	var n := Node2D.new()
	n.draw.connect(func() -> void: RenderingServer.canvas_item_add_triangle_array(n.get_canvas_item(), idx, points, colors))
	parent.add_child(n)
