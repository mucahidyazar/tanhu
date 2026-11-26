class_name StagedMesh
extends RefCounted
## Aşama kitinin ağ üreticisi (godot.md §6.7; structures.md §3.3, §3.4, §9.1, §9.2): bir yapının bütün parçaları tek ağdır, her köşe
## parçasının aşamasını, aşama içindeki sırasını, kipini ve pivotunu taşır; gölgelendirici (shaders/staged.gdshader) örnek tekdüzeni
## `stage`'in üstündeki parçaları pivotuna çökertir, sıradaki aşamanın parçalarını `stage_t` ile kurar. Yapı başına çizim eklemez:
## iki yüzey vardır (0 kalın parçalar, cull_back; 1 ince parçalar: keçe, örtü, kuşak, halat; iki yüzlü).
##
## Köşe verisi (yapı ağları aynı biçimdedir, YurtField ve iç düzen de):
##   COLOR       rgb köşe rengi (doğrusal), a malzeme sınıfı / 8 (CLS_*: keçe yırtılır ve kar tutar, ışık parlar)
##   CUSTOM0     x aşama (0–7), y aşama içindeki sıra (0..1: parça stage_t'nin sıra × 0,88'inde başlar, 0,12'de biter), z kip (MODE_*), w tohum
##   CUSTOM1     xyz pivot (yerel), w kipin ölçüsü (HOIST: inişin yüksekliği m; STRIP: parçanın boyunca 0..1 yeri)
##   UV          desenin koordinatı (kuşak: çevre boyunca bant yüksekliği birimiyle, enine 0..1)
##   UV2         x gizlenme aşaması (aşama bunu bulunca parça görünmez: tam yurtta iskelet; 99 hiç), y desen kimliği (0 yok)
## Kipler (structures.md §9.2): RISE yükselir, POP pivotundan büyür, FAN kanat gibi pivotunun açısından açılır, HOIST tündük alttan
## kalkar, SWING uuk dikten iner, STRIP halat boyunca belirir, STATIC kip yok (yalnız görünür ya da gizli).
##   var m := StagedMesh.new()
##   m.part(2, 0.1, StagedMesh.MODE_FAN, Vector3(0, 0, 3.3), StagedMesh.CLS_WOOD)
##   m.beam(Vector3(0, 0, 3.3), Vector3(0.5, 2.2, 3.26), 0.04, 0.03, Color("#7a4a2a"))
##   var mesh := m.commit()          # ArrayMesh, iki yüzey

const CLS_PLAIN := 0
const CLS_FELT := 1
const CLS_ROPE := 2
const CLS_STONE := 3
const CLS_GLOW := 4
const CLS_REED := 5
const CLS_WOOD := 6
const MODE_RISE := 0
const MODE_POP := 1
const MODE_FAN := 2
const MODE_HOIST := 3
const MODE_SWING := 4
const MODE_STRIP := 5
const MODE_STATIC := 7
const NEVER := 99.0
const SOLID := 0
const THIN := 1

## Yüzey başına diziler.
class Surf:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var uv := PackedVector2Array()
	var uv2 := PackedVector2Array()
	var c0 := PackedFloat32Array()
	var c1 := PackedFloat32Array()
	var idx := PackedInt32Array()

var surfaces: Array[Surf] = [Surf.new(), Surf.new()]
## Şimdiki parçanın bilgisi.
var _stage := 7.0
var _order := 0.0
var _mode := float(MODE_STATIC)
var _seed := 0.0
var _pivot := Vector3.ZERO
var _sub := 0.0
var _cls := 0.0
var _hide := NEVER
var _pattern := 0.0
## Eklenen köşelere uygulanan dönüşüm (iç düzenin eşyaları kendi yerel uzayında kurulur).
var xform := Transform3D.IDENTITY
## Renk çarpanı (ton; keçe tonu ×0,78 / ×1 / ×1,12 YurtField'dadır, burada eşyanın gölgesi).
var tint := Color.WHITE


## Sıradaki köşelerin parçası: aşama, sıra, kip, pivot (xform uygulanmadan önceki yerel), sınıf; extra: seed, sub, hide, pattern.
func part(stage: int, order: float = 0.0, mode: int = MODE_STATIC, pivot: Vector3 = Vector3.ZERO, cls: int = CLS_PLAIN,
		extra: Dictionary = {}) -> void:
	_stage = float(stage)
	_order = clampf(order, 0.0, 1.0)
	_mode = float(mode)
	_pivot = xform * pivot
	_cls = float(cls)
	_seed = float(extra.get("seed", fposmod(float(stage) * 0.37 + order * 3.1, 1.0)))
	_sub = float(extra.get("sub", 0.0))
	_hide = float(extra.get("hide", NEVER))
	_pattern = float(extra.get("pattern", 0.0))


## Kipin ölçüsü (STRIP'te köşe köşe değişir).
func set_sub(v: float) -> void:
	_sub = v


func set_pattern(p: int) -> void:
	_pattern = float(p)


## Köşe ekler (dizin döner). p ve nrm yerel (xform uygulanır).
func vertex(s: int, p: Vector3, nrm: Vector3, col: Color, uv: Vector2 = Vector2.ZERO) -> int:
	var su: Surf = surfaces[s]
	su.v.append(xform * p)
	su.n.append((xform.basis * nrm).normalized())
	var lc := Color(col.r * tint.r, col.g * tint.g, col.b * tint.b).srgb_to_linear()
	lc.a = _cls / 8.0
	su.c.append(lc)
	su.uv.append(uv)
	su.uv2.append(Vector2(_hide, _pattern))
	su.c0.append_array(PackedFloat32Array([_stage, _order, _mode, _seed]))
	su.c1.append_array(PackedFloat32Array([_pivot.x, _pivot.y, _pivot.z, _sub]))
	return su.v.size() - 1


func tri(s: int, a: int, b: int, c: int) -> void:
	surfaces[s].idx.append_array(PackedInt32Array([a, b, c]))


## Dörtgen (a b c d saat yönünde dışarıdan; Godot'nun ön yüzü saat yönüdür).
func quad(s: int, a: int, b: int, c: int, d: int) -> void:
	surfaces[s].idx.append_array(PackedInt32Array([a, b, c, a, c, d]))


## Üçgen sayısı (iki yüzey).
func tri_count() -> int:
	return (surfaces[0].idx.size() + surfaces[1].idx.size()) / 3


func vertex_count() -> int:
	return surfaces[0].v.size() + surfaces[1].v.size()


# --- Parçalar --------------------------------------------------------------------------------------------

## Dönüşümlü kutu (merkez xf.origin, kenarlar xf.basis boyunca; size tam ölçü).
func box(xf: Transform3D, size: Vector3, col: Color, s: int = SOLID) -> void:
	var h := size * 0.5
	var faces := [
		[Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0)], [Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0)],
		[Vector3(0, 1, 0), Vector3(1, 0, 0), Vector3(0, 0, -1)], [Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)],
		[Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)], [Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(0, 1, 0)],
	]
	for f: Array in faces:
		var nrm: Vector3 = f[0]
		var u: Vector3 = f[1]
		var w: Vector3 = f[2]
		var c := nrm * h
		var du := u * h
		var dw := w * h
		var corners := [c - du - dw, c - du + dw, c + du + dw, c + du - dw]
		var shade := 0.82 if nrm.y < -0.5 else (1.0 if nrm.y > 0.5 else 0.92)
		var cc := Color(col.r * shade, col.g * shade, col.b * shade)
		var ids := PackedInt32Array()
		for k in 4:
			ids.append(vertex(s, xf * (corners[k] as Vector3), xf.basis * nrm, cc))
		quad(s, ids[0], ids[1], ids[2], ids[3])


## İki nokta arasında kesiti w × h kutu (kiriş, sırık, dikme). up: kesitin dikey ekseninin yönü.
func beam(a: Vector3, b: Vector3, w: float, h: float, col: Color, up: Vector3 = Vector3.UP, s: int = SOLID) -> void:
	var d := b - a
	var length := d.length()
	if length < 0.0001:
		return
	var z := d / length
	var x := up.cross(z)
	if x.length_squared() < 0.000001:
		x = Vector3.RIGHT.cross(z)
	x = x.normalized()
	var y := z.cross(x).normalized()
	box(Transform3D(Basis(x, y, z), (a + b) * 0.5), Vector3(w, h, length), col, s)


## Boru: noktalar boyunca sides kenarlı halka (kalın yüzey). Uçlar açık.
func tube(points: PackedVector3Array, r: float, sides: int, col: Color, s: int = SOLID, strip: bool = false) -> void:
	var count := points.size()
	if count < 2:
		return
	var total := 0.0
	var lengths := PackedFloat32Array([0.0])
	for i in range(1, count):
		total += points[i].distance_to(points[i - 1])
		lengths.append(total)
	var base := surfaces[s].v.size()
	var prev_x := Vector3.ZERO
	for i in count:
		var t := (points[mini(i + 1, count - 1)] - points[maxi(i - 1, 0)]).normalized()
		var x := Vector3.UP.cross(t)
		if x.length_squared() < 0.0001:
			x = Vector3.RIGHT.cross(t)
		x = x.normalized()
		if i > 0 and x.dot(prev_x) < 0.0:
			x = -x
		prev_x = x
		var y := t.cross(x).normalized()
		if strip:
			set_sub(lengths[i] / maxf(total, 0.0001))
		for k in sides:
			var a := TAU * float(k) / float(sides)
			var nrm := x * cos(a) + y * sin(a)
			vertex(s, points[i] + nrm * r, nrm, col, Vector2(float(k) / float(sides), lengths[i]))
	for i in count - 1:
		for k in sides:
			var a0 := base + i * sides + k
			var a1 := base + i * sides + (k + 1) % sides
			var b0 := a0 + sides
			var b1 := a1 + sides
			quad(s, a0, b0, b1, a1)


## Yassı şerit: noktalar boyunca, her noktada verilen yüz normaline dik width enli (ince yüzey; iki yüzlü çizilir).
## strip: STRIP kipinde köşenin boyunca yeri sub'a yazılır. uv_scale: UV.x'in birimi (m başına).
func ribbon(points: PackedVector3Array, normals: PackedVector3Array, width: float, col: Color, strip: bool = false,
		uv_scale: float = 1.0) -> void:
	var count := points.size()
	if count < 2:
		return
	var total := 0.0
	var lengths := PackedFloat32Array([0.0])
	for i in range(1, count):
		total += points[i].distance_to(points[i - 1])
		lengths.append(total)
	var base := surfaces[THIN].v.size()
	for i in count:
		var t := (points[mini(i + 1, count - 1)] - points[maxi(i - 1, 0)]).normalized()
		var nrm := normals[mini(i, normals.size() - 1)]
		var side := nrm.cross(t).normalized()
		if strip:
			set_sub(lengths[i] / maxf(total, 0.0001))
		vertex(THIN, points[i] - side * width * 0.5, nrm, col, Vector2(lengths[i] * uv_scale, 0.0))
		vertex(THIN, points[i] + side * width * 0.5, nrm, col, Vector2(lengths[i] * uv_scale, 1.0))
	for i in count - 1:
		var a := base + i * 2
		# (boyuna, yana, normal) sağ elli: normal yönünden bakınca saat yönü ön yüzdür.
		quad(THIN, a, a + 1, a + 3, a + 2)


## Döner yüzey (profil: alttan üste Vector2(yarıçap, yükseklik)), a0..a1 açı aralığı (yön (sin a, cos a): a 0 kapı +Z). Açı başına renk
## için col_fn (Callable(a, v) → Color) verilebilir. uv: x açının çevredeki metresi / uv_unit, y profil boyunca 0..1. s: yüzey.
func lathe(profile: PackedVector2Array, segs: int, a0: float, a1: float, col: Color, s: int = THIN, uv_unit: float = 1.0,
		col_fn: Callable = Callable(), outward: bool = true) -> void:
	var count := profile.size()
	if count < 2 or segs < 1:
		return
	var lengths := PackedFloat32Array([0.0])
	var total := 0.0
	for i in range(1, count):
		total += profile[i].distance_to(profile[i - 1])
		lengths.append(total)
	total = maxf(total, 0.0001)
	var base := surfaces[s].v.size()
	var r_ref := profile[0].x
	for k in segs + 1:
		var a := lerpf(a0, a1, float(k) / float(segs))
		var dir := Vector3(sin(a), 0.0, cos(a))
		for i in count:
			var p := profile[i]
			var tng := (profile[mini(i + 1, count - 1)] - profile[maxi(i - 1, 0)]).normalized()
			var n2 := Vector2(tng.y, -tng.x)
			if not outward:
				n2 = -n2
			var nrm := (dir * n2.x + Vector3.UP * n2.y).normalized()
			var c := col
			if col_fn.is_valid():
				c = col_fn.call(a, lengths[i] / total)
			vertex(s, dir * p.x + Vector3.UP * p.y, nrm, c, Vector2(a * r_ref / uv_unit, lengths[i] / total))
	for k in segs:
		for i in count - 1:
			var p0 := base + k * count + i
			var p1 := p0 + 1
			var q0 := base + (k + 1) * count + i
			var q1 := q0 + 1
			# Açı artıyorken (sin a, cos a) yönü dışarıdan bakınca saat yönünün tersine döner: ön yüz için sıra p0 q0 q1 p1.
			if outward:
				quad(s, p0, p1, q1, q0)
			else:
				quad(s, p0, q0, q1, p1)


## Yatay disk (y yüksekliğinde, yukarı bakar).
func disc(center: Vector3, r: float, segs: int, col: Color, s: int = SOLID) -> void:
	var c := vertex(s, center, Vector3.UP, col, Vector2(0.5, 0.5))
	var ring := PackedInt32Array()
	for k in segs:
		var a := TAU * float(k) / float(segs)
		ring.append(vertex(s, center + Vector3(sin(a) * r, 0.0, cos(a) * r), Vector3.UP, col, Vector2(sin(a), cos(a)) * 0.5 + Vector2(0.5, 0.5)))
	for k in segs:
		tri(s, c, ring[(k + 1) % segs], ring[k])


## Silindir (dikey; uçları kapalı).
func cylinder(center: Vector3, r_bottom: float, r_top: float, h: float, segs: int, col: Color, s: int = SOLID,
		caps: bool = true) -> void:
	var prof := PackedVector2Array([Vector2(r_bottom, 0.0), Vector2(r_top, h)])
	var old := xform
	xform = xform * Transform3D(Basis.IDENTITY, center)
	lathe(prof, segs, 0.0, TAU, col, s, 1.0)
	if caps:
		disc(Vector3(0.0, h, 0.0), r_top, segs, col.darkened(0.06), s)
	xform = old


## Yatay silindir (kütük, rulo): a'dan b'ye.
func log_between(a: Vector3, b: Vector3, r: float, segs: int, col: Color) -> void:
	var pts := PackedVector3Array([a, b])
	tube(pts, r, segs, col)
	var d := (b - a).normalized()
	for e: Array in [[a, -d], [b, d]]:
		var center: Vector3 = e[0]
		var nrm: Vector3 = e[1]
		var x := Vector3.UP.cross(nrm)
		if x.length_squared() < 0.0001:
			x = Vector3.RIGHT
		x = x.normalized()
		var y := nrm.cross(x)
		var c := vertex(SOLID, center, nrm, col.lightened(0.18))
		var ring := PackedInt32Array()
		for k in segs:
			var ang := TAU * float(k) / float(segs)
			ring.append(vertex(SOLID, center + (x * cos(ang) + y * sin(ang)) * r, nrm, col.lightened(0.12)))
		for k in segs:
			tri(SOLID, c, ring[(k + 1) % segs], ring[k])


## Küçük taş (ikosfer, gürültüyle bozulmuş; alt yüzü düz).
func blob(center: Vector3, size: Vector3, seed_value: int, col: Color, subdiv: int = 0) -> void:
	var data := MeshKit.icosphere_data(subdiv)
	var verts: PackedVector3Array = data[0]
	var ids: PackedInt32Array = data[1]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var base := surfaces[SOLID].v.size()
	for p in verts:
		var q := p * (1.0 + rng.randf_range(-0.16, 0.16))
		q.y = maxf(q.y, -0.35)
		var nrm := p.normalized()
		var shade := 0.86 + 0.14 * clampf(nrm.y, 0.0, 1.0)
		vertex(SOLID, center + Vector3(q.x * size.x, (q.y + 0.35) * size.y, q.z * size.z), nrm, Color(col.r * shade, col.g * shade, col.b * shade))
	for i in range(0, ids.size(), 3):
		tri(SOLID, base + ids[i], base + ids[i + 1], base + ids[i + 2])


# --- Bitiş ----------------------------------------------------------------------------------------------

## Ağ: iki yüzey (boş yüzey atlanır; hangi yüzeyin hangisi olduğu surface_kinds'tadır).
func commit() -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var kinds := PackedInt32Array()
	var flags := (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT) | (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT)
	for s in surfaces.size():
		var su: Surf = surfaces[s]
		if su.idx.is_empty():
			continue
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = su.v
		arrays[Mesh.ARRAY_NORMAL] = su.n
		arrays[Mesh.ARRAY_COLOR] = su.c
		arrays[Mesh.ARRAY_TEX_UV] = su.uv
		arrays[Mesh.ARRAY_TEX_UV2] = su.uv2
		arrays[Mesh.ARRAY_CUSTOM0] = su.c0
		arrays[Mesh.ARRAY_CUSTOM1] = su.c1
		arrays[Mesh.ARRAY_INDEX] = su.idx
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, flags)
		kinds.append(s)
	mesh.set_meta(&"surface_kinds", kinds)
	mesh.set_meta(&"triangles", tri_count())
	return mesh


## Ağın yüzey türleri (commit'in yazdığı; SOLID ya da THIN).
static func surface_kinds(mesh: Mesh) -> PackedInt32Array:
	if mesh and mesh.has_meta(&"surface_kinds"):
		return mesh.get_meta(&"surface_kinds")
	return PackedInt32Array([SOLID])


## Ağın üçgen sayısı (commit'in yazdığı; yoksa yüzeylerden sayılır).
static func triangles_of(mesh: Mesh) -> int:
	if mesh == null:
		return 0
	if mesh.has_meta(&"triangles"):
		return int(mesh.get_meta(&"triangles"))
	var t := 0
	for s in mesh.get_surface_count():
		var arr := mesh.surface_get_arrays(s)
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		t += idx.size() / 3 if not idx.is_empty() else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return t
