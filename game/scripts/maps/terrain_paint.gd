class_name TerrainPaint
extends RefCounted
## İç haritanın elle tarif edilen yüksekliği ve zemin boyası (act1.md §4 «Yükseklik»; godot.md §4.4; K2): map.json «ground.relief» sıralı
## işlemlerdir, 1 m'lik ızgaraya boyanır (resim yazılımındaki katmanlar gibi: her işlem o ana dek boyanmış yüksekliği kendi hedefine doğru
## kendi maskesiyle çeker). Sonra yapıların, ocakların ve kayıtlı düz yerlerin altı (disk; merkezin yüksekliği), yollar (roads.json: en
## kesitinde düz, boyunda yumuşak, eğimi sınırlı) ve ince gürültü (düz yerlerde ve yolda bastırılır) gelir. Saftır: düğüm kurmaz,
## tools/paint_height.gd ile başsız koşar, sonucu data/maps/<id>/height.exr (R32F, 1 m), mask.png (RGBA8, 2 m) ve cover.png (RGBA8, 4 m)
## olur; MapBaker o dosyaları okur (dosya yoksa bunu kendisi koşar).
##
## İşlemler («op»):
##   base     {height, swell{amplitude, wavelength}}: bütün ızgara
##   region   {center, size | radius, shape ellipse|box, round (süperelips üssü), height, tilt{toward (pusula °), deg, origin}, blend,
##            strength, mode, warp{amplitude, wavelength}, relief{amplitude, wavelength}}: bölgenin (eğimli) düzlemi; maske sınırda %50'dir
##            (blend sınırın iki yanına yarı yarıya yayılır), sınır gürültüyle bükülür, düzlüğe hafif dalga katılır
##   ridge    {points [[x, z, tepe]...], width, blend, side_blend{toward, blend}, jag{amplitude, wavelength}, mode}: sırt ya da duvar
##            (Demir Diş, Kemik Boğazı); mode lerp ile rampa (Yar Rampası, Boğaz'ın vadi tabanı)
##   channel  {points [[x, z, düzey, en]...], bank}: ırmak (Buz Kolu); yatak düz (buz), kıyı bank kadar yükselir
##   lake     {center, size, level, shore}: göl (Ayna Göl); buz düz
##   bluff    {points, low_toward (pusula °), top, low, drop, reach}: yar (Yar kenarı −5 → Yar dibi −14); yalnız aşağı keser
##   dome     {at, radius, height}: höyük, tepe (eklenir)
##   noise    {amplitude, wavelength, octaves, type fbm|ridged, center, size, blend}: bölgeye sınırlı gürültü (Kara Tepeler)
## mode: lerp (varsayılan), max (yalnız yükseltir), min (yalnız alçaltır), add.
## Kapaklar (sırayla ve kendiliğinden): düz yerler (yapı kayıtları ve «flats»), yollar (roads.json «roads»: points, width, grade, smooth,
## surface), ince gürültü (detail). Maskeler (2 m, mask_image): R kar örtüsü, G toprak (çiğnenmiş kar, ezik yer), B yol izi, A Kar
## Kabuğu payı (açık, düz, rüzgârlı yer; hava kabuğu yazınca görünür, weather.md). Örtü (4 m, cover_image): R buz, G kaya, B saz,
## A orman yeri.
##   var paint := TerrainPaint.paint(MapSpec.find("kislak"))
##   paint.height_at(0.0, 0.0)       # Ulu Ocak: 0
##   paint.height_image()            # FORMAT_RF, 1.401 × 1.051

## Yolun boyundaki örnek aralığı (m) ve en kesitinin kenar geçişi (m; yolun kenarından dışa).
const ROAD_STEP := 2.0
const ROAD_BLEND := 3.5
## Yapı türünün düz yerinin yarıçapı ve geçişi (m; yapı kaydında «flat» yoksa). Yurt boyları K51: s ×0,7, m ×1, l ×1,4.
const FLAT_BY_KIND := {
	"yurt": [5.2, 7.0], "yurt_pad": [5.6, 7.0], "great_hearth": [14.0, 10.0], "hearth": [2.2, 3.0], "watch_fire": [2.0, 3.0],
	"lantern": [1.0, 2.0], "count_stone": [2.0, 3.0], "work_board": [2.5, 3.0], "kitchen": [4.5, 4.0], "woodpile": [3.5, 3.0],
	"felt_yard": [7.0, 5.0], "stable": [11.0, 6.0], "tower": [4.0, 4.0], "shed": [4.5, 4.0], "latrine": [2.0, 2.0],
	"gate": [3.0, 3.0], "landmark": [3.0, 4.0], "lookout": [3.0, 3.0],
}
const YURT_SCALE := {"s": 0.7, "m": 1.0, "l": 1.4}
## Ezik yer (maskenin G'si) yapı türüne göre: yarıçap (m).
const TRAMPLE_BY_KIND := {
	"yurt": 5.2, "yurt_pad": 5.6, "great_hearth": 15.0, "hearth": 3.0, "watch_fire": 3.4, "kitchen": 6.0, "woodpile": 4.0,
	"felt_yard": 8.0, "stable": 13.0, "shed": 5.0, "work_board": 3.5, "count_stone": 2.5, "tower": 4.5, "latrine": 2.5,
	"lantern": 1.2, "gate": 3.0,
}
## Ocağın çevresinde kar erir (m): yarıçap ve geçiş.
const MELT_BY_KIND := {"great_hearth": [9.0, 4.0], "hearth": [1.8, 1.6], "watch_fire": [2.4, 1.8], "kitchen": [2.6, 2.0]}
## Kayanın göründüğü eğim (derece): bu açıdan dikte kar tutmaz.
const ROCK_SLOPE := Vector2(33.0, 46.0)
## Yurdun yarıçapı (m; kayıtta «radius» yoksa boyundan: K51 Küçük ×0,7, Hane ×1, Otağ ×1,4; Godot'nun yurdu Hane'de 3,4 m).
const YURT_RADIUS := {"s": 2.4, "m": 3.4, "l": 4.8}
## Navmesh'in çıkıntı engeli (m; yarıçap) yapı türüne ve simgenin tipine göre (0: engel değil, üstünden yürünür). Yurt YURT_RADIUS'tandır.
const OBSTACLE_BY_KIND := {
	"great_hearth": 1.4, "hearth": 0.8, "watch_fire": 0.8, "count_stone": 0.9, "kitchen": 1.6, "woodpile": 1.8, "tower": 2.2,
	"shed": 2.6, "work_board": 0.8, "latrine": 1.0, "stable": 5.0, "lantern": 0.25,
}
const OBSTACLE_BY_TYPE := {
	"stone": 0.9, "deer_stone": 0.6, "tower": 1.8, "shed": 2.2, "tent_qiang": 2.6, "kiln": 1.6, "forge": 1.8, "granary": 2.6,
	"huts": 2.2, "pole": 0.25, "bones": 0.5, "platform": 1.6, "shelter": 2.0, "tree": 0.6,
}


## Yurt kaydının yarıçapı (m; saf).
static func yurt_radius(rec: Dictionary) -> float:
	if rec.has("radius"):
		return float(rec["radius"])
	return float(YURT_RADIUS.get(str(rec.get("size", "m")), 3.4))


## Yapı kaydının navmesh engeli (m; 0 engel yok; saf): türün ya da simgenin tipinin yarıçapı, kayıtta «obstacle» varsa o.
static func obstacle_radius(rec: Dictionary) -> float:
	if rec.has("obstacle"):
		return float(rec["obstacle"])
	var kind := str(rec.get("kind", ""))
	if kind == "landmark":
		return float(OBSTACLE_BY_TYPE.get(str(rec.get("type", "")), 0.0))
	if kind == "hearth" and not bool(rec.get("outdoor", false)):
		return 0.0
	return float(OBSTACLE_BY_KIND.get(kind, 0.0))

var rect := Rect2()
var cell := 1.0
var width := 0
var depth := 0
var heights := PackedFloat32Array()
## Gürültünün bastırıldığı pay (yol, düz yer; 0..1).
var calm := PackedFloat32Array()
## Yol izi (0..1) ve yolun türünün katsayısı (çiğnenmiş yol 1, kızak 0,8, patika 0,6, kar izi 0,4).
var road := PackedFloat32Array()
## Ezik yer (0..1) ve erime (0..1): yapı kayıtlarından.
var trample := PackedFloat32Array()
var melt := PackedFloat32Array()
## Buz (ırmak, göl), saz ve orman yeri (0..1).
var ice := PackedFloat32Array()
var reeds := PackedFloat32Array()
var forest := PackedFloat32Array()
## Kar Kabuğu payı (0..1; açık düzlükler).
var crust := PackedFloat32Array()
## Tarifin tohumu ve işlem sayısı (sınama, günlük).
var seed_value := 0
var op_count := 0

var _spec_ground: Dictionary = {}


## Tariften boyar (saf; MapSpec.ground.relief, roads.json, yapı kayıtları). Döner: boyanmış ızgara.
static func paint(spec: MapSpec, roads: Dictionary = {}) -> TerrainPaint:
	var p := TerrainPaint.new()
	p.setup(spec.rect(), float(spec.ground.get("cell", 1.0)))
	p._spec_ground = spec.ground
	p.seed_value = int(spec.ground.get("seed", 1041))
	for op: Dictionary in spec.ground.get("relief", []):
		p.apply(op)
	# Önce yapıların düz yerleri, sonra yollar: yolun boyu düz yerleri görür, ama yolu hiçbir düz yer basamaklamaz (yol kesitte ve boyda
	# kendi sınırında kalır).
	for f in flats_of(spec):
		p.apply_flat(f)
	var road_def := roads if not roads.is_empty() else load_roads(spec)
	var pins := p.junction_pins(road_def)
	for r: Dictionary in road_def.get("roads", []):
		p.apply_road(r, pins)
	p.apply_detail(spec.ground.get("detail", {}))
	p.apply_covers(spec.ground.get("covers", []))
	return p


## Haritanın yol dosyası (map.json «roads»; yoksa data/maps/<id>/roads.json). Yoksa boş.
static func load_roads(spec: MapSpec) -> Dictionary:
	var path := str(spec.raw.get("roads", "res://data/maps/%s/roads.json" % spec.id))
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## Düz yerler (saf): yapı kayıtlarından (türün yarıçapı; kayıtta «flat»: [yarıçap, geçiş] ya da false) ve map.json «ground.flats».
## Döner: [Vector4(x, z, yarıçap, geçiş), ...] ile ezik ve erime: [{at, flat, trample, melt}].
static func flats_of(spec: MapSpec) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s: Dictionary in spec.structures:
		var kind := str(s.get("kind", ""))
		var f: Variant = s.get("flat", FLAT_BY_KIND.get(kind, null))
		if f is bool and not f:
			continue
		var k := float(YURT_SCALE.get(str(s.get("size", "m")), 1.0)) if kind == "yurt" or kind == "yurt_pad" else 1.0
		var entry := {"at": MapSpec.vec2(s.get("at", [0.0, 0.0])), "flat": Vector2.ZERO, "trample": 0.0, "melt": Vector2.ZERO}
		if f is Array and (f as Array).size() >= 2:
			entry["flat"] = Vector2(float(f[0]) * k, float(f[1]))
		entry["trample"] = float(s.get("trample", TRAMPLE_BY_KIND.get(kind, 0.0))) * k
		var m: Variant = MELT_BY_KIND.get(kind, null)
		if m is Array:
			entry["melt"] = Vector2(float(m[0]), float(m[1]))
		if s.has("y"):
			entry["y"] = float(s["y"])
		out.append(entry)
	for f: Dictionary in spec.ground.get("flats", []):
		out.append({"at": MapSpec.vec2(f.get("at", [0.0, 0.0])), "flat": Vector2(float(f.get("radius", 4.0)), float(f.get("blend", 5.0))),
			"trample": float(f.get("trample", 0.0)), "melt": Vector2.ZERO})
	return out


func setup(p_rect: Rect2, p_cell: float) -> void:
	rect = p_rect
	cell = maxf(p_cell, 0.01)
	width = int(roundf(rect.size.x / cell)) + 1
	depth = int(roundf(rect.size.y / cell)) + 1
	var n := width * depth
	for buf: PackedFloat32Array in [heights, calm, road, trample, melt, ice, reeds, forest, crust]:
		buf.resize(n)
		buf.fill(0.0)


# --- Okuma ------------------------------------------------------------------------------------------

## Izgaranın çift doğrusal yüksekliği (dışarısı en yakın kenar örneği).
func height_at(x: float, z: float) -> float:
	return sample(heights, x, z)


## Bir tamponun çift doğrusal değeri (dünya x, z).
func sample(buf: PackedFloat32Array, x: float, z: float) -> float:
	var fx := clampf((x - rect.position.x) / cell, 0.0, float(width - 1))
	var fz := clampf((z - rect.position.y) / cell, 0.0, float(depth - 1))
	var ix := mini(int(fx), width - 2)
	var iz := mini(int(fz), depth - 2)
	var tx := fx - float(ix)
	var tz := fz - float(iz)
	var i := iz * width + ix
	return lerpf(lerpf(buf[i], buf[i + 1], tx), lerpf(buf[i + width], buf[i + width + 1], tx), tz)


## Yükseklik görüntüsü (FORMAT_RF; satır z, sütun x).
func height_image() -> Image:
	return Image.create_from_data(width, depth, false, Image.FORMAT_RF, heights.to_byte_array())


## Eğim (derece) ızgara noktasında (merkezi fark).
func slope_deg(ix: int, iz: int) -> float:
	var x0 := heights[iz * width + maxi(ix - 1, 0)]
	var x1 := heights[iz * width + mini(ix + 1, width - 1)]
	var z0 := heights[maxi(iz - 1, 0) * width + ix]
	var z1 := heights[mini(iz + 1, depth - 1) * width + ix]
	var gx := (x1 - x0) / (2.0 * cell)
	var gz := (z1 - z0) / (2.0 * cell)
	return rad_to_deg(atan(sqrt(gx * gx + gz * gz)))


## Zemin maskesi (RGBA8, mcell aralıklı; MapBaker «mask»): R kar, G toprak, B yol, A Kar Kabuğu.
func mask_image(mcell: float) -> Image:
	var w := int(roundf(rect.size.x / mcell)) + 1
	var d := int(roundf(rect.size.y / mcell)) + 1
	var bytes := PackedByteArray()
	bytes.resize(w * d * 4)
	var k := 0
	for jz in d:
		var z := rect.position.y + float(jz) * mcell
		for jx in w:
			var x := rect.position.x + float(jx) * mcell
			var ix := clampi(int(roundf((x - rect.position.x) / cell)), 0, width - 1)
			var iz := clampi(int(roundf((z - rect.position.y) / cell)), 0, depth - 1)
			var rock := smoothstep(ROCK_SLOPE.x, ROCK_SLOPE.y, slope_deg(ix, iz))
			var rd := sample(road, x, z)
			var tr := sample(trample, x, z)
			var ml := sample(melt, x, z)
			var snow := clampf(1.0 - 0.92 * rock - ml, 0.0, 1.0)
			var soil := clampf(maxf(tr * 0.85, ml * 0.9) * (1.0 - rock), 0.0, 1.0)
			var cr := sample(crust, x, z) * (1.0 - rock) * (1.0 - rd) * (1.0 - tr)
			bytes[k] = int(snow * 255.0)
			bytes[k + 1] = int(soil * 255.0)
			bytes[k + 2] = int(clampf(rd, 0.0, 1.0) * 255.0)
			bytes[k + 3] = int(clampf(cr, 0.0, 1.0) * 255.0)
			k += 4
	return Image.create_from_data(w, d, false, Image.FORMAT_RGBA8, bytes)


## Örtü (RGBA8, ccell aralıklı): R buz, G kaya (dik yamaç), B saz, A orman yeri.
func cover_image(ccell: float) -> Image:
	var w := int(roundf(rect.size.x / ccell)) + 1
	var d := int(roundf(rect.size.y / ccell)) + 1
	var bytes := PackedByteArray()
	bytes.resize(w * d * 4)
	var k := 0
	for jz in d:
		var z := rect.position.y + float(jz) * ccell
		for jx in w:
			var x := rect.position.x + float(jx) * ccell
			var ix := clampi(int(roundf((x - rect.position.x) / cell)), 0, width - 1)
			var iz := clampi(int(roundf((z - rect.position.y) / cell)), 0, depth - 1)
			bytes[k] = int(clampf(sample(ice, x, z), 0.0, 1.0) * 255.0)
			bytes[k + 1] = int(smoothstep(ROCK_SLOPE.x - 4.0, ROCK_SLOPE.y, slope_deg(ix, iz)) * 255.0)
			bytes[k + 2] = int(clampf(sample(reeds, x, z), 0.0, 1.0) * 255.0)
			bytes[k + 3] = int(clampf(sample(forest, x, z), 0.0, 1.0) * 255.0)
			k += 4
	return Image.create_from_data(w, d, false, Image.FORMAT_RGBA8, bytes)


# --- İşlemler ---------------------------------------------------------------------------------------

## Bir işlemi uygular (yukarıdaki «op» tablosu). Bilinmeyen işlem uyarıyla atlanır.
func apply(op: Dictionary) -> void:
	op_count += 1
	match str(op.get("op", "")):
		"base":
			_op_base(op)
		"region":
			_op_region(op)
		"ridge":
			_op_ridge(op)
		"channel":
			_op_channel(op)
		"lake":
			_op_lake(op)
		"bluff":
			_op_bluff(op)
		"dome":
			_op_dome(op)
		"noise":
			_op_noise(op)
		_:
			push_warning("[terrain_paint] bilinmeyen işlem: %s" % op.get("op", ""))


func _op_base(op: Dictionary) -> void:
	var h0 := float(op.get("height", 0.0))
	var sw: Dictionary = op.get("swell", {})
	var amp := float(sw.get("amplitude", 0.0))
	var noise := _noise(seed_value + 3, 1.0 / maxf(float(sw.get("wavelength", 150.0)), 1.0), 3)
	for iz in depth:
		var z := rect.position.y + float(iz) * cell
		for ix in width:
			var x := rect.position.x + float(ix) * cell
			heights[iz * width + ix] = h0 + amp * noise.get_noise_2d(x, z)


func _op_region(op: Dictionary) -> void:
	var c := MapSpec.vec2(op.get("center", [0.0, 0.0]))
	var half := MapSpec.vec2(op.get("size", [0.0, 0.0])) * 0.5
	if op.has("radius"):
		half = Vector2.ONE * float(op["radius"])
	# Biçim: süperelips (round 2 elips, 4 yuvarlak köşeli kutu, 8 kutuya yakın); «box» tam kutu.
	var shape := str(op.get("shape", "ellipse"))
	var round_n := float(op.get("round", 2.0 if shape == "ellipse" else 4.0))
	var blend := maxf(float(op.get("blend", 20.0)), 0.01)
	var h0 := float(op.get("height", 0.0))
	var tilt: Dictionary = op.get("tilt", {})
	var dir := compass_dir(float(tilt.get("toward", 0.0)))
	var grade := tan(deg_to_rad(float(tilt.get("deg", 0.0))))
	# Eğimli düzlemin yüksekliği h0 olan noktası (varsayılan bölgenin ortası).
	var origin := MapSpec.vec2(tilt.get("origin", [c.x, c.y]))
	var strength := clampf(float(op.get("strength", 1.0)), 0.0, 1.0)
	var mode := str(op.get("mode", "lerp"))
	# Sınırı gürültüyle bük (warp, m) ve düzlüğe hafif dalga kat (relief): bölgeler kutu ve tepsi gibi okunmasın.
	var warp: Dictionary = op.get("warp", {"amplitude": minf(blend * 0.45, 30.0), "wavelength": 120.0})
	var warp_amp := float(warp.get("amplitude", 0.0))
	var warp_noise := _noise(seed_value + 101 + op_count, 1.0 / maxf(float(warp.get("wavelength", 120.0)), 1.0), 2)
	var rel: Dictionary = op.get("relief", {})
	var rel_amp := float(rel.get("amplitude", 0.0))
	var rel_noise := _noise(seed_value + 131 + op_count, 1.0 / maxf(float(rel.get("wavelength", 90.0)), 1.0), 3)
	var box := _range(Rect2(c - half, half * 2.0).grow(blend + warp_amp))
	for iz in range(box.position.y, box.end.y):
		var z := rect.position.y + float(iz) * cell
		for ix in range(box.position.x, box.end.x):
			var x := rect.position.x + float(ix) * cell
			var p := Vector2(x, z)
			var q := p
			if warp_amp > 0.0:
				q += Vector2(warp_noise.get_noise_2d(x, z), warp_noise.get_noise_2d(x + 517.0, z - 311.0)) * warp_amp
			var sd := box_sd(q - c, half) if shape == "box" else superellipse_sd(q - c, half, round_n)
			var m := (1.0 - smoothstep(-blend * 0.5, blend * 0.5, sd)) * strength
			if m <= 0.0:
				continue
			var i := iz * width + ix
			var target := h0 + grade * (p - origin).dot(dir)
			if rel_amp > 0.0:
				target += rel_amp * rel_noise.get_noise_2d(x, z)
			heights[i] = _mix(heights[i], target, m, mode)


func _op_ridge(op: Dictionary) -> void:
	var pts := _points3(op.get("points", []), float(op.get("height", 0.0)))
	if pts.size() < 2:
		return
	var half_w := float(op.get("width", 10.0)) * 0.5
	var blend := maxf(float(op.get("blend", 20.0)), 0.01)
	var mode := str(op.get("mode", "max"))
	var jag: Dictionary = op.get("jag", {})
	var jag_amp := float(jag.get("amplitude", 0.0))
	var jag_noise := _noise(seed_value + 41 + op_count, 1.0 / maxf(float(jag.get("wavelength", 12.0)), 1.0), 3, FastNoiseLite.FRACTAL_RIDGED)
	# Bir yanın geçişi ayrı olabilir (side_blend{toward, blend}): Demir Diş'in ırmağa bakan yüzü dik.
	var side: Dictionary = op.get("side_blend", {})
	var side_dir := compass_dir(float(side.get("toward", 0.0)))
	var side_b := maxf(float(side.get("blend", blend)), 0.01)
	var field := _line_field(pts, half_w + maxf(blend, side_b))
	for i: int in field:
		var info: Vector3 = field[i]
		var x := rect.position.x + float(i % width) * cell
		var z := rect.position.y + float(i / width) * cell
		var b := blend
		if not side.is_empty() and _side_distance(pts, Vector2(x, z), side_dir).x > 0.0:
			b = side_b
		var m := 1.0 - smoothstep(half_w, half_w + b, info.x)
		if m <= 0.0:
			continue
		var top := info.y
		if jag_amp > 0.0:
			top += jag_amp * jag_noise.get_noise_2d(x, z)
		heights[i] = _mix(heights[i], top, m * m * (3.0 - 2.0 * m), mode)


func _op_channel(op: Dictionary) -> void:
	var raw: Array = op.get("points", [])
	var pts := PackedVector4Array()
	for p: Variant in raw:
		var a: Array = p
		pts.append(Vector4(float(a[0]), float(a[1]), float(a[2]) if a.size() > 2 else float(op.get("level", 0.0)),
			float(a[3]) if a.size() > 3 else float(op.get("width", 40.0))))
	if pts.size() < 2:
		return
	var bank := maxf(float(op.get("bank", 20.0)), 0.01)
	var max_w := 0.0
	for p in pts:
		max_w = maxf(max_w, p.w)
	var field := _line_field4(pts, max_w * 0.5 + bank)
	for i: int in field:
		var info: Vector4 = field[i]
		var half_w := info.z * 0.5
		var m := 1.0 - smoothstep(half_w, half_w + bank, info.x)
		if m <= 0.0:
			continue
		heights[i] = minf(heights[i], lerpf(heights[i], info.y, m))
		ice[i] = maxf(ice[i], 1.0 - smoothstep(half_w - 2.0, half_w + 1.5, info.x))


func _op_lake(op: Dictionary) -> void:
	var c := MapSpec.vec2(op.get("center", [0.0, 0.0]))
	var half := MapSpec.vec2(op.get("size", [100.0, 100.0])) * 0.5
	var level := float(op.get("level", 0.0))
	var shore := maxf(float(op.get("shore", 20.0)), 0.01)
	var box := _range(Rect2(c - half, half * 2.0).grow(shore))
	for iz in range(box.position.y, box.end.y):
		var z := rect.position.y + float(iz) * cell
		for ix in range(box.position.x, box.end.x):
			var x := rect.position.x + float(ix) * cell
			var sd := ellipse_sd(Vector2(x, z) - c, half)
			var m := 1.0 - smoothstep(0.0, shore, sd)
			if m <= 0.0:
				continue
			var i := iz * width + ix
			heights[i] = minf(heights[i], lerpf(heights[i], level, m))
			ice[i] = maxf(ice[i], 1.0 - smoothstep(-2.0, 1.5, sd))


func _op_bluff(op: Dictionary) -> void:
	var pts := _points3(op.get("points", []), 0.0)
	if pts.size() < 2:
		return
	var low_dir := compass_dir(float(op.get("low_toward", 0.0)))
	var top := float(op.get("top", 0.0))
	var low := float(op.get("low", -10.0))
	var drop := maxf(float(op.get("drop", 8.0)), 0.01)
	var reach := maxf(float(op.get("reach", 40.0)), drop)
	var end_fade := maxf(float(op.get("end_fade", 40.0)), 0.01)
	var field := _line_field(pts, reach + end_fade)
	for i: int in field:
		var x := rect.position.x + float(i % width) * cell
		var z := rect.position.y + float(i / width) * cell
		# Yönlü uzaklık (low_dir yanında artı) ve uçların ötesindeki sönüm (0..1).
		var sd := _side_distance(pts, Vector2(x, z), low_dir)
		if sd.x < 0.0 or sd.y >= end_fade:
			continue
		var profile := lerpf(top, low, smoothstep(0.0, drop, sd.x))
		var m := (1.0 - smoothstep(reach * 0.55, reach, sd.x)) * (1.0 - smoothstep(0.0, end_fade, sd.y))
		heights[i] = minf(heights[i], lerpf(heights[i], profile, m))


func _op_dome(op: Dictionary) -> void:
	var c := MapSpec.vec2(op.get("at", [0.0, 0.0]))
	var r := maxf(float(op.get("radius", 10.0)), 0.01)
	var h := float(op.get("height", 1.0))
	var box := _range(Rect2(c - Vector2.ONE * r, Vector2.ONE * r * 2.0))
	for iz in range(box.position.y, box.end.y):
		var z := rect.position.y + float(iz) * cell
		for ix in range(box.position.x, box.end.x):
			var x := rect.position.x + float(ix) * cell
			var t := Vector2(x, z).distance_to(c) / r
			if t >= 1.0:
				continue
			var b := 1.0 - t * t
			heights[iz * width + ix] += h * b * b


func _op_noise(op: Dictionary) -> void:
	var amp := float(op.get("amplitude", 1.0))
	var ridged := str(op.get("type", "fbm")) == "ridged"
	var noise := _noise(seed_value + 61 + op_count, 1.0 / maxf(float(op.get("wavelength", 60.0)), 1.0), int(op.get("octaves", 3)),
		FastNoiseLite.FRACTAL_RIDGED if ridged else FastNoiseLite.FRACTAL_FBM)
	var whole := not op.has("center")
	var c := MapSpec.vec2(op.get("center", [0.0, 0.0]))
	var half := MapSpec.vec2(op.get("size", [0.0, 0.0])) * 0.5
	var blend := maxf(float(op.get("blend", 30.0)), 0.01)
	var area := rect if whole else Rect2(c - half, half * 2.0).grow(blend)
	var box := _range(area)
	for iz in range(box.position.y, box.end.y):
		var z := rect.position.y + float(iz) * cell
		for ix in range(box.position.x, box.end.x):
			var x := rect.position.x + float(ix) * cell
			var m := 1.0 if whole else 1.0 - smoothstep(-blend * 0.5, blend * 0.5, ellipse_sd(Vector2(x, z) - c, half))
			if m <= 0.0:
				continue
			var v := noise.get_noise_2d(x, z)
			if ridged:
				v = v * 0.5 + 0.5
			heights[iz * width + ix] += amp * v * m


# --- Yollar, düz yerler, ince gürültü, örtüler ----------------------------------------------------------

## Yol (roads.json'un bir satırı): orta çizgisi ROAD_STEP aralıkla örneklenir, yükseklik boyunca smooth metrede yumuşar, eğim grade'le
## sınırlanır (ileri ve geri geçişin ortalaması: yarı kazı, yarı dolgu; Yar Rampası böyle iner); en kesitte yolun yüksekliği tutulur,
## kenardan ROAD_BLEND metrede araziye karışır. Yol izi (maskenin B'si) yüzeyin katsayısıyla yazılır.
func apply_road(r: Dictionary, pins: Dictionary = {}) -> void:
	var raw: Array = r.get("points", [])
	if raw.size() < 2:
		return
	var line := PackedVector2Array()
	for p: Variant in raw:
		line.append(MapSpec.vec2(p))
	var half_w := float(r.get("width", 3.0)) * 0.5
	var grade := tan(deg_to_rad(float(r.get("grade", 9.0))))
	var smooth := maxf(float(r.get("smooth", 16.0)), ROAD_STEP)
	var surface := float(r.get("decal", {"road": 1.0, "sled": 0.8, "path": 0.6, "track": 0.4}.get(str(r.get("surface", "road")), 1.0)))
	# Orta çizginin örnekleri ve yükseklikleri.
	var samples := resample(line, ROAD_STEP)
	var hs := PackedFloat32Array()
	for p in samples:
		hs.append(height_at(p.x, p.y))
	hs = smooth_profile(hs, int(roundf(smooth / ROAD_STEP)))
	hs = limit_grade(hs, grade * ROAD_STEP)
	if not pins.is_empty():
		hs = pin_profile(hs, samples, line, pins)
	var pts := PackedVector3Array()
	for k in samples.size():
		pts.append(Vector3(samples[k].x, samples[k].y, hs[k]))
	var field := _line_field(pts, half_w + ROAD_BLEND)
	for i: int in field:
		var info: Vector3 = field[i]
		var m := 1.0 - smoothstep(half_w, half_w + ROAD_BLEND, info.x)
		if m <= 0.0:
			continue
		heights[i] = lerpf(heights[i], info.y, m)
		calm[i] = maxf(calm[i], m)
		road[i] = maxf(road[i], surface * (1.0 - smoothstep(half_w - 0.4, half_w + 0.8, info.x)))


## Kavşakların yüksekliği (yollar boyanmadan önce): adlı düğümler (roads.json «nodes») ve iki ya da daha çok yolun paylaştığı köşeler →
## o anki ızgaranın yüksekliği. Her yol kavşakta bu yüksekliğe iğnelenir: sonra boyanan yol öncekinin ucunda basamak bırakmaz.
func junction_pins(road_def: Dictionary) -> Dictionary:
	var count := {}
	for r: Dictionary in road_def.get("roads", []):
		var seen := {}
		for q: Variant in r.get("points", []):
			var key := _pin_key(MapSpec.vec2(q))
			if not seen.has(key):
				seen[key] = true
				count[key] = int(count.get(key, 0)) + 1
	var nodes := {}
	for id: Variant in (road_def.get("nodes", {}) as Dictionary):
		nodes[_pin_key(MapSpec.vec2(road_def["nodes"][id]))] = true
	var out := {}
	for key: Vector2i in count:
		if int(count[key]) >= 2 or nodes.has(key):
			var at := Vector2(key) / 10.0
			out[key] = height_at(at.x, at.y)
	return out


## Profilin iğnelere çekilmesi (saf): her iğnelenen köşenin en yakın örneğinde fark hesaplanır, farklar örnekler boyunca doğrusal yayılır
## (uçlarda sabit): profil kavşakta düğümün yüksekliğine oturur, arada yumuşak kalır.
static func pin_profile(hs: PackedFloat32Array, samples: PackedVector2Array, line: PackedVector2Array, pins: Dictionary) -> PackedFloat32Array:
	var marks: Array = []
	for q in line:
		var key := _pin_key(q)
		if not pins.has(key):
			continue
		var best := 0
		var best_d := INF
		for k in samples.size():
			var d := samples[k].distance_squared_to(q)
			if d < best_d:
				best_d = d
				best = k
		marks.append([best, float(pins[key]) - hs[best]])
	if marks.is_empty():
		return hs
	marks.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
	var out := hs.duplicate()
	for k in out.size():
		var off := 0.0
		if k <= int(marks[0][0]):
			off = float(marks[0][1])
		elif k >= int(marks[marks.size() - 1][0]):
			off = float(marks[marks.size() - 1][1])
		else:
			for m in marks.size() - 1:
				var a: Array = marks[m]
				var b: Array = marks[m + 1]
				if k >= int(a[0]) and k <= int(b[0]):
					var t := float(k - int(a[0])) / maxf(float(int(b[0]) - int(a[0])), 1.0)
					off = lerpf(float(a[1]), float(b[1]), t)
					break
		out[k] += off
	return out


static func _pin_key(q: Vector2) -> Vector2i:
	return Vector2i(roundi(q.x * 10.0), roundi(q.y * 10.0))


## Düz yer: diskin içi merkezin (o anki) yüksekliğine çekilir; ezik yer ve erime maskeye yazılır.
func apply_flat(f: Dictionary) -> void:
	var c: Vector2 = f["at"]
	var fl: Vector2 = f.get("flat", Vector2.ZERO)
	var tr := float(f.get("trample", 0.0))
	var ml: Vector2 = f.get("melt", Vector2.ZERO)
	var reach := maxf(fl.x + fl.y, maxf(tr + 2.0, ml.x + ml.y))
	if reach <= 0.0:
		return
	var target := float(f["y"]) if f.has("y") else height_at(c.x, c.y)
	var box := _range(Rect2(c - Vector2.ONE * reach, Vector2.ONE * reach * 2.0))
	for iz in range(box.position.y, box.end.y):
		var z := rect.position.y + float(iz) * cell
		for ix in range(box.position.x, box.end.x):
			var x := rect.position.x + float(ix) * cell
			var dist := Vector2(x, z).distance_to(c)
			var i := iz * width + ix
			if fl.x > 0.0:
				var m := 1.0 - smoothstep(fl.x, fl.x + fl.y, dist)
				if m > 0.0:
					heights[i] = lerpf(heights[i], target, m)
					calm[i] = maxf(calm[i], m)
			if tr > 0.0:
				trample[i] = maxf(trample[i], 1.0 - smoothstep(tr * 0.7, tr + 1.5, dist))
			if ml.x > 0.0:
				melt[i] = maxf(melt[i], 1.0 - smoothstep(ml.x, ml.x + ml.y, dist))


## İnce gürültü (detail{amplitude, wavelength}): yolda ve düz yerde bastırılır; rüzgârın kar dalgaları (drift{amplitude, wavelength,
## toward}) rüzgâr yönünde uzamış gürültüdür.
func apply_detail(def: Dictionary) -> void:
	var amp := float(def.get("amplitude", 0.0))
	var noise := _noise(seed_value + 11, 1.0 / maxf(float(def.get("wavelength", 9.0)), 1.0), 2)
	var drift: Dictionary = def.get("drift", {})
	var damp := float(drift.get("amplitude", 0.0))
	var dnoise := _noise(seed_value + 13, 1.0 / maxf(float(drift.get("wavelength", 14.0)), 1.0), 2)
	var along := compass_dir(float(drift.get("toward", 135.0)))
	var across := Vector2(-along.y, along.x)
	var stretch := float(drift.get("stretch", 3.0))
	for iz in depth:
		var z := rect.position.y + float(iz) * cell
		for ix in width:
			var x := rect.position.x + float(ix) * cell
			var i := iz * width + ix
			var k := 1.0 - calm[i]
			if k <= 0.0:
				continue
			var p := Vector2(x, z)
			var v := amp * noise.get_noise_2d(x, z)
			if damp > 0.0:
				v += damp * dnoise.get_noise_2d(p.dot(along) / stretch, p.dot(across)) * (1.0 - ice[i])
			heights[i] += v * k


## Örtü bölgeleri (ground.covers: [{cover: reeds|forest|crust, center, size | points+width, blend, strength}]).
func apply_covers(defs: Array) -> void:
	for def: Dictionary in defs:
		var buf: PackedFloat32Array
		match str(def.get("cover", "")):
			"reeds":
				buf = reeds
			"forest":
				buf = forest
			"crust":
				buf = crust
			_:
				continue
		var strength := float(def.get("strength", 1.0))
		var blend := maxf(float(def.get("blend", 20.0)), 0.01)
		if def.has("points"):
			var pts := _points3(def["points"], 0.0)
			var half_w := float(def.get("width", 20.0)) * 0.5
			var field := _line_field(pts, half_w + blend)
			for i: int in field:
				var m := (1.0 - smoothstep(half_w, half_w + blend, (field[i] as Vector3).x)) * strength
				buf[i] = maxf(buf[i], m)
			continue
		var c := MapSpec.vec2(def.get("center", [0.0, 0.0]))
		var half := MapSpec.vec2(def.get("size", [0.0, 0.0])) * 0.5
		var box := _range(Rect2(c - half, half * 2.0).grow(blend))
		for iz in range(box.position.y, box.end.y):
			var z := rect.position.y + float(iz) * cell
			for ix in range(box.position.x, box.end.x):
				var x := rect.position.x + float(ix) * cell
				var m := (1.0 - smoothstep(-blend * 0.5, blend * 0.5, ellipse_sd(Vector2(x, z) - c, half))) * strength
				var i := iz * width + ix
				buf[i] = maxf(buf[i], m)


# --- Yardımcılar (saf) ------------------------------------------------------------------------------

## Pusula yönünün birim yönü (x, z): 0 kuzey (−Z), 90 doğu (+X).
static func compass_dir(deg: float) -> Vector2:
	var a := deg_to_rad(deg)
	return Vector2(sin(a), -cos(a))


## Eksene hizalı kutunun işaretli uzaklığı (içeride eksi).
static func box_sd(p: Vector2, half: Vector2) -> float:
	var q := p.abs() - half
	return Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length() + minf(maxf(q.x, q.y), 0.0)


## Elipsin yaklaşık işaretli uzaklığı (m; içeride eksi): ölçeklenmiş birim çemberden, küçük yarı eksenle.
static func ellipse_sd(p: Vector2, half: Vector2) -> float:
	var h := Vector2(maxf(half.x, 0.01), maxf(half.y, 0.01))
	return ((p / h).length() - 1.0) * minf(h.x, h.y)


## Süperelipsin yaklaşık işaretli uzaklığı ((|x|/a)^n + (|z|/b)^n)^(1/n) − 1, küçük yarı eksenle; n 2 elips, büyüdükçe kutu.
static func superellipse_sd(p: Vector2, half: Vector2, n: float) -> float:
	var h := Vector2(maxf(half.x, 0.01), maxf(half.y, 0.01))
	var e := maxf(n, 1.0)
	var v := pow(pow(absf(p.x) / h.x, e) + pow(absf(p.y) / h.y, e), 1.0 / e)
	return (v - 1.0) * minf(h.x, h.y)


## Kırık çizgiyi step aralıkla yeniden örnekler (iki uç dahil).
static func resample(line: PackedVector2Array, step: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	if line.size() == 0:
		return out
	out.append(line[0])
	var carry := 0.0
	for i in line.size() - 1:
		var a := line[i]
		var b := line[i + 1]
		var seg := a.distance_to(b)
		var t := step - carry
		while t <= seg:
			out.append(a.lerp(b, t / seg))
			t += step
		carry = seg - (t - step)
	if out[out.size() - 1].distance_to(line[line.size() - 1]) > 0.01:
		out.append(line[line.size() - 1])
	return out


## Kayan ortalama (pencere 2·half + 1 örnek; uçlarda kısalır).
static func smooth_profile(hs: PackedFloat32Array, half: int) -> PackedFloat32Array:
	if half <= 0 or hs.size() < 3:
		return hs
	var out := PackedFloat32Array()
	out.resize(hs.size())
	for i in hs.size():
		var a := maxi(i - half, 0)
		var b := mini(i + half, hs.size() - 1)
		var sum := 0.0
		for k in range(a, b + 1):
			sum += hs[k]
		out[i] = sum / float(b - a + 1)
	return out


## Eğim sınırı: ardışık örnekler arasındaki fark ≤ step_rise; ileri ve geri geçişin ortalaması (yarı kazı, yarı dolgu).
static func limit_grade(hs: PackedFloat32Array, step_rise: float) -> PackedFloat32Array:
	if hs.size() < 2:
		return hs
	var fwd := hs.duplicate()
	for i in range(1, fwd.size()):
		fwd[i] = clampf(fwd[i], fwd[i - 1] - step_rise, fwd[i - 1] + step_rise)
	var back := hs.duplicate()
	for i in range(back.size() - 2, -1, -1):
		back[i] = clampf(back[i], back[i + 1] - step_rise, back[i + 1] + step_rise)
	var out := PackedFloat32Array()
	out.resize(hs.size())
	for i in hs.size():
		out[i] = (fwd[i] + back[i]) * 0.5
	# Ortalama sınırı yeniden aşabilir (iki geçiş ters yönde kaydırdıysa): son bir ileri geçiş.
	for i in range(1, out.size()):
		out[i] = clampf(out[i], out[i - 1] - step_rise, out[i - 1] + step_rise)
	return out


static func _mix(h: float, target: float, m: float, mode: String) -> float:
	match mode:
		"max":
			return maxf(h, lerpf(h, target, m))
		"min":
			return minf(h, lerpf(h, target, m))
		"add":
			return h + target * m
	return lerpf(h, target, m)


## [[x, z, (h)], ...] → Vector3(x, z, h) (h yoksa varsayılan).
static func _points3(raw: Variant, default_h: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	if not raw is Array:
		return out
	for p: Variant in raw:
		var a: Array = p
		out.append(Vector3(float(a[0]), float(a[1]), float(a[2]) if a.size() > 2 else default_h))
	return out


## Dünya dikdörtgeninin ızgara aralığı (kırpılmış).
func _range(r: Rect2) -> Rect2i:
	var x0 := clampi(floori((r.position.x - rect.position.x) / cell), 0, width)
	var z0 := clampi(floori((r.position.y - rect.position.y) / cell), 0, depth)
	var x1 := clampi(ceili((r.end.x - rect.position.x) / cell) + 1, 0, width)
	var z1 := clampi(ceili((r.end.y - rect.position.y) / cell) + 1, 0, depth)
	return Rect2i(x0, z0, maxi(x1 - x0, 0), maxi(z1 - z0, 0))


## Kırık çizginin uzaklık alanı: reach içindeki her ızgara noktası → Vector3(uzaklık, çizginin o noktadaki h'si, parametre). Parça başına
## kutusu taranır; en yakın parça kazanır.
func _line_field(pts: PackedVector3Array, reach: float, _signed: bool = false) -> Dictionary:
	var out := {}
	for k in pts.size() - 1:
		var a := Vector2(pts[k].x, pts[k].y)
		var b := Vector2(pts[k + 1].x, pts[k + 1].y)
		var ab := b - a
		var len2 := maxf(ab.length_squared(), 1e-9)
		var box := _range(Rect2(a, Vector2.ZERO).expand(b).grow(reach))
		for iz in range(box.position.y, box.end.y):
			var z := rect.position.y + float(iz) * cell
			for ix in range(box.position.x, box.end.x):
				var x := rect.position.x + float(ix) * cell
				var p := Vector2(x, z)
				var t := clampf((p - a).dot(ab) / len2, 0.0, 1.0)
				var dist := p.distance_to(a + ab * t)
				if dist > reach:
					continue
				var i := iz * width + ix
				var prev: Variant = out.get(i)
				if prev == null or dist < (prev as Vector3).x:
					out[i] = Vector3(dist, lerpf(pts[k].z, pts[k + 1].z, t), float(k) + t)
	return out


## _line_field'in dört bileşenlisi (ırmak): Vector4(x, z, düzey, en) noktaları → Vector4(uzaklık, düzey, en, parametre).
func _line_field4(pts: PackedVector4Array, reach: float) -> Dictionary:
	var out := {}
	for k in pts.size() - 1:
		var a := Vector2(pts[k].x, pts[k].y)
		var b := Vector2(pts[k + 1].x, pts[k + 1].y)
		var ab := b - a
		var len2 := maxf(ab.length_squared(), 1e-9)
		var box := _range(Rect2(a, Vector2.ZERO).expand(b).grow(reach))
		for iz in range(box.position.y, box.end.y):
			var z := rect.position.y + float(iz) * cell
			for ix in range(box.position.x, box.end.x):
				var x := rect.position.x + float(ix) * cell
				var p := Vector2(x, z)
				var t := clampf((p - a).dot(ab) / len2, 0.0, 1.0)
				var dist := p.distance_to(a + ab * t)
				if dist > reach:
					continue
				var i := iz * width + ix
				var prev: Variant = out.get(i)
				if prev == null or dist < (prev as Vector4).x:
					out[i] = Vector4(dist, lerpf(pts[k].z, pts[k + 1].z, t), lerpf(pts[k].w, pts[k + 1].w, t), float(k) + t)
	return out


## Noktanın kırık çizgiye göre yönlü uzaklığı: Vector2(dikine uzaklık (low_dir yanında artı), uçtan ötesi (m; çizginin boyunca 0)). İlk
## ve son parçanın ucunun ötesinde (en yakın nokta uçsa) ikinci bileşen boyuna uzaklıktır: çağıran yarı onunla söndürür (yar uçlarda yamaca
## karışır).
static func _side_distance(pts: PackedVector3Array, p: Vector2, low_dir: Vector2) -> Vector2:
	var best := INF
	var out := Vector2(-1.0, 0.0)
	for k in pts.size() - 1:
		var a := Vector2(pts[k].x, pts[k].y)
		var b := Vector2(pts[k + 1].x, pts[k + 1].y)
		var ab := b - a
		var len2 := maxf(ab.length_squared(), 1e-9)
		var raw_t := (p - a).dot(ab) / len2
		var q := a + ab * clampf(raw_t, 0.0, 1.0)
		var dist := p.distance_to(q)
		if dist >= best:
			continue
		best = dist
		var n := Vector2(-ab.y, ab.x).normalized()
		if n.dot(low_dir) < 0.0:
			n = -n
		var dir := ab / sqrt(len2)
		var beyond := 0.0
		if k == 0 and raw_t < 0.0:
			beyond = -(p - a).dot(dir)
		elif k == pts.size() - 2 and raw_t > 1.0:
			beyond = (p - b).dot(dir)
		out = Vector2((p - q).dot(n), beyond)
	return out


static func _noise(p_seed: int, frequency: float, octaves: int, fractal: FastNoiseLite.FractalType = FastNoiseLite.FRACTAL_FBM) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.seed = p_seed
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = frequency
	n.fractal_type = fractal
	n.fractal_octaves = octaves
	return n
