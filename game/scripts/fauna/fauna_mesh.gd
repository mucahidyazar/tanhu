class_name FaunaMesh
extends RefCounted
## Kodla çizilen hayvan ağları (saf; fauna.md §10: küçük memeli ≤1,2k üçgen, kuş programatik, sürünün T1 ağı ≤1.800 üçgen).
## Düğüm kurmaz, ağaca dokunmaz: arrays(kind_id) WorkerThreadPool'da da çalışır, make_mesh ana iş parçacığındadır. Ağlar türün
## yaşayan boyundadır: taban y = 0, baş +Z'ye bakar (Horse ile aynı kural).
##
## Köşe verisi:
##   COLOR.rgb  boya (doğrusal); COLOR.a yünlülük (1 yün ya da tüy: gölgelendirici leke ekler, 0 deri, boynuz, gaga; sürüde 0,5 tohumdan boyanan yüz).
##   CUSTOM0    gölgelendiricinin parça bilgisi (ARRAY_CUSTOM_RGBA_FLOAT).
##              Sürü (herd_field.gdshader): x bacak (1 sol arka, 2 sol ön, 3 sağ arka, 4 sağ ön; 0 yok), y bacağın salınım
##              ağırlığı, z baş ağırlığı (otlama: boyun dibinden döner), w kuyruk ağırlığı; w = −1 boynuz (başla döner, koçta görünür).
##              Küçük av (small_game.gdshader): x kanat (işaretli: −1 sol uç, +1 sağ uç), y baş ağırlığı, z kuyruk ağırlığı,
##              w bacak (işaretli, ±1).
##
## Meshy ağı gelince (assets/animals/sheep/sheep.glb) HerdField from_model ile aynı köşe verisini ağın biçiminden ve dokusundan çıkarır, T1 bütçesine
## indirir: kod ve sahne değişmez.

## Sürü ağının eklem ölçüleri (kodla çizilen koyun; metre, boy 1,1 m). herd_field.gdshader'ın varsayılanlarıyla aynıdır.
const SHEEP_HIP := 0.4
const SHEEP_NECK := Vector3(0.0, 0.55, 0.25)
const SHEEP_TAIL := Vector3(0.0, 0.58, -0.44)
const SHEEP_LENGTH := 1.14
const SHEEP_HEIGHT := 0.96
## Kodla çizilen yaban domuzunun eklem ölçüleri (sürü gölgelendiricisi; metre, boy 1,5 m).
const BOAR_HIP := 0.44
const BOAR_NECK := Vector3(0.0, 0.62, 0.4)
const BOAR_TAIL := Vector3(0.0, 0.62, -0.6)

## Krem yün ve incik (kavram görseli; binilen koyunla aynı aile: RideableSheep).
const WOOL := Color(0.93, 0.84, 0.66, 1.0)
const WOOL_SHADE := Color(0.73, 0.62, 0.45, 1.0)
const SHIN := Color(0.27, 0.19, 0.14, 1.0)
const HOOF := Color(0.13, 0.11, 0.09, 1.0)
const HORN := Color(0.66, 0.57, 0.42, 0.0)
const EYE := Color(0.03, 0.025, 0.02, 0.0)
## Yüz: boyası gölgelendiricide tohumdan gelir (koyu, sarımsı, açık); köşe rengi aydınlık-gölge çarpanıdır, COLOR.a = FACE_ALPHA işarettir.
const FACE_PAINT := Color(1.0, 1.0, 1.0, 0.5)
const FACE_ALPHA := 0.5

## Bir bölük ağın köşe verisi; parçalar (damla, boru, yaprak) buna eklenir.
class Draft:
	extends RefCounted
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var custom := PackedFloat32Array()
	var indices := PackedInt32Array()

	## Yumuşak damla: ikosferden, radii ile yassıltılmış, basis ile döndürülmüş, center'a konmuş. lump > 0 yüzeyi gürültüyle
	## kabartır (yün). paint(v, n) köşe rengini, tag(v) parça bilgisini verir (Color ya da Callable; Vector4 ya da Callable).
	## v ağ uzayındadır; n normali ağ uzayındadır.
	func blob(center: Vector3, radii: Vector3, basis: Basis, subdivisions: int, paint: Variant, tag: Variant, lump: float = 0.0, noise_seed: int = 1) -> void:
		var data := MeshKit.icosphere_data(subdivisions)
		var points: PackedVector3Array = data[0]
		var faces: PackedInt32Array = data[1]
		var noise: FastNoiseLite = null
		var fine: FastNoiseLite = null
		if lump > 0.0:
			noise = FastNoiseLite.new()
			noise.seed = noise_seed
			noise.frequency = 1.5
			noise.fractal_octaves = 2
			fine = FastNoiseLite.new()
			fine.seed = noise_seed + 5
			fine.frequency = 4.2
			fine.fractal_octaves = 1
		var shaped := PackedVector3Array()
		shaped.resize(points.size())
		for i in points.size():
			var unit := points[i]
			var d := 1.0
			if noise:
				d += noise.get_noise_3dv(unit) * lump + fine.get_noise_3dv(unit) * lump * 0.45
			shaped[i] = center + basis * (unit * radii * d)
		var smooth := MeshKit.smooth_normals(shaped, faces)
		var base := vertices.size()
		for i in shaped.size():
			_add_vertex(shaped[i], smooth[i], paint, tag)
		for k in faces:
			indices.append(base + k)

	## Boru: points boyunca, radii kalınlığında (nokta başına), sides kenarlı; uçlar kapanır.
	func tube(points: PackedVector3Array, radii: PackedFloat32Array, sides: int, paint: Variant, tag: Variant) -> void:
		var base := vertices.size()
		var rows := points.size()
		for r in rows:
			var along := (points[mini(r + 1, rows - 1)] - points[maxi(r - 1, 0)]).normalized()
			var side := along.cross(Vector3.FORWARD if absf(along.z) < 0.9 else Vector3.RIGHT).normalized()
			var up := side.cross(along).normalized()
			for s in sides:
				var a := TAU * float(s) / float(sides)
				var n := side * cos(a) + up * sin(a)
				_add_vertex(points[r] + n * radii[r], n, paint, tag)
		for r in rows - 1:
			for s in sides:
				var s2 := (s + 1) % sides
				_quad(base + r * sides + s, base + r * sides + s2, base + (r + 1) * sides + s, base + (r + 1) * sides + s2)
		_cap(base, sides, points[0], -(points[1] - points[0]).normalized(), paint, tag)
		_cap(base + (rows - 1) * sides, sides, points[rows - 1], (points[rows - 1] - points[rows - 2]).normalized(), paint, tag)

	## Yaprak: köşeleri verilen ince yüzey (kanat, kuyruk yelpazesi; iki yüzlü malzemeyle çizilir). Sıra: iki kenar boyunca
	## çiftler (a0, b0, a1, b1...).
	func strip(points: PackedVector3Array, normal: Vector3, paint: Variant, tag: Variant) -> void:
		var base := vertices.size()
		for p in points:
			_add_vertex(p, normal, paint, tag)
		for i in range(0, points.size() - 2, 2):
			_tri(base + i, base + i + 1, base + i + 2, normal)
			_tri(base + i + 1, base + i + 3, base + i + 2, normal)

	func triangles() -> int:
		return indices.size() / 3

	func arrays() -> Dictionary:
		return {"vertices": vertices, "normals": normals, "colors": colors, "custom": custom, "indices": indices}

	func _add_vertex(v: Vector3, n: Vector3, paint: Variant, tag: Variant) -> void:
		vertices.append(v)
		normals.append(n)
		# Boyalar sRGB yazılır; köşe rengi gölgelendiriciye doğrusal gider (source_color tekdüzeniyle aynı sonuç).
		var c: Color = (paint as Callable).call(v, n) if paint is Callable else paint
		colors.append(c.srgb_to_linear())
		var t: Vector4 = (tag as Callable).call(v) if tag is Callable else tag
		custom.append_array(PackedFloat32Array([t.x, t.y, t.z, t.w]))

	func _quad(a: int, b: int, c: int, d: int) -> void:
		var n := normals[a] + normals[b] + normals[c] + normals[d]
		_tri(a, b, c, n)
		_tri(b, d, c, n)

	## Üçgen: outward'a bakan yüz ön yüz olsun (Godot: dışarıdan saat yönünde).
	func _tri(a: int, b: int, c: int, outward: Vector3) -> void:
		var f := (vertices[c] - vertices[a]).cross(vertices[b] - vertices[a])
		if f.dot(outward) >= 0.0:
			indices.append_array(PackedInt32Array([a, b, c]))
		else:
			indices.append_array(PackedInt32Array([a, c, b]))

	func _cap(start: int, sides: int, center: Vector3, outward: Vector3, paint: Variant, tag: Variant) -> void:
		var hub := vertices.size()
		_add_vertex(center, outward, paint, tag)
		for s in sides:
			_tri(hub, start + s, start + (s + 1) % sides, outward)


## Türün ağ verisi (saf; iş parçacığında çalışır). Bilinmeyen tür boş döner.
static func arrays(kind_id: String) -> Dictionary:
	match kind_id:
		"sheep":
			return sheep().arrays()
		"lark":
			return lark().arrays()
		"partridge":
			return partridge().arrays()
		"crow":
			return crow().arrays()
		"marmot":
			return marmot().arrays()
		"gerbil":
			return gerbil().arrays()
		"hare":
			return hare().arrays()
		"eagle":
			return eagle().arrays()
		"boar":
			return boar().arrays()
	return {}


## Köşe verisinden ağ (ana iş parçacığında çağrılır).
static func make_mesh(data: Dictionary) -> ArrayMesh:
	var surface := []
	surface.resize(Mesh.ARRAY_MAX)
	surface[Mesh.ARRAY_VERTEX] = data["vertices"]
	surface[Mesh.ARRAY_NORMAL] = data["normals"]
	if data.has("colors"):
		surface[Mesh.ARRAY_COLOR] = data["colors"]
	if data.has("uvs"):
		surface[Mesh.ARRAY_TEX_UV] = data["uvs"]
	surface[Mesh.ARRAY_INDEX] = data["indices"]
	var flags := 0
	if data.has("custom"):
		surface[Mesh.ARRAY_CUSTOM0] = data["custom"]
		flags = Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface, [], {}, flags)
	return mesh


## Türün ağı.
static func mesh_for(kind_id: String) -> ArrayMesh:
	var data := arrays(kind_id)
	return make_mesh(data) if not data.is_empty() else null


# --- Koyun -----------------------------------------------------------------------------------------

## Yağlı kuyruklu bozkır koyunu (kavram görseli assets/_concepts/sheep.png; K89: Meshy gelene dek): kalın kümeler hâlinde krem yün, koyu yüz ve
## bacak, ağır yağlı kuyruk; koçta kıvrık küçük boynuz. Tek ağ, T1 bütçesi ≤1.800 üçgen.
static func sheep() -> Draft:
	var d := Draft.new()
	var body := Vector4.ZERO
	var woolly := func(v: Vector3, n: Vector3) -> Color:
		# Karın ve kaburga altı gölgede kalır (boyalı hacim).
		var shade := clampf((v.y - 0.3) / 0.36, 0.0, 1.0) * (0.72 + 0.28 * clampf(n.y * 0.5 + 0.5, 0.0, 1.0))
		return WOOL_SHADE.lerp(WOOL, shade)
	# Gövde: tek damla; üstünde yün kümeleri (sırtın ve böğrün engebesi).
	var core := Vector3(0.0, 0.53, -0.03)
	var radii := Vector3(0.25, 0.235, 0.385)
	d.blob(core, radii, Basis.IDENTITY, 2, woolly, body, 0.06, 11)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2211
	for i in 13:
		var along := lerpf(-0.88, 0.86, (float(i) + rng.randf()) / 13.0)
		var around := rng.randf_range(-1.9, 1.9)
		var ring := sqrt(maxf(1.0 - along * along, 0.05))
		var at := core + Vector3(sin(around) * radii.x * ring, cos(around) * radii.y * ring, along * radii.z) * 0.9
		var size := rng.randf_range(0.085, 0.135)
		d.blob(at, Vector3(size, size * 0.78, size * 1.25), Basis(Vector3.UP, rng.randf() * TAU), 1 if i % 2 == 0 else 0, woolly, body, 0.0)
	# Boyun: kalın yün yakası; dipte gövdede kalır, yukarı doğru başla döner.
	var neck_tag := func(v: Vector3) -> Vector4:
		return Vector4(0.0, 0.0, smoothstep(0.24, 0.44, v.z), 0.0)
	d.blob(Vector3(0.0, 0.685, 0.365), Vector3(0.125, 0.165, 0.18), Basis(Vector3.RIGHT, deg_to_rad(-42.0)), 1, woolly, neck_tag, 0.08, 14)
	# Baş: kısa, geniş, öne ve aşağı eğik; alında yün kâkül, yanlarda kulak, koyu burun. Yüz boyası gölgelendiricide tohumdan (COLOR.a = FACE_ALPHA).
	var head_tag := Vector4(0.0, 0.0, 1.0, 0.0)
	var tilt := Basis(Vector3.RIGHT, deg_to_rad(30.0))
	var head_at := Vector3(0.0, 0.84, 0.47)
	var axis := tilt * Vector3.BACK
	var face := func(v: Vector3, _n: Vector3) -> Color:
		var c: Color = FACE_PAINT.lerp(FACE_PAINT.darkened(0.4), smoothstep(0.08, 0.15, (v - head_at).dot(axis)))
		c.a = FACE_ALPHA
		return c
	d.blob(head_at, Vector3(0.066, 0.074, 0.105), tilt, 1, face, head_tag)
	d.blob(head_at + axis * 0.085, Vector3(0.05, 0.048, 0.055), tilt, 1, face, head_tag)
	d.blob(head_at + Vector3(0.0, 0.066, -0.05), Vector3(0.062, 0.042, 0.06), Basis.IDENTITY, 0, woolly, head_tag)
	for sx: float in [-1.0, 1.0]:
		d.blob(head_at + Vector3(sx * 0.098, 0.022, -0.04), Vector3(0.06, 0.016, 0.03), Basis(Vector3.BACK, deg_to_rad(sx * -16.0)), 0, face, head_tag)
		d.blob(head_at + Vector3(sx * 0.058, 0.022, 0.03), Vector3.ONE * 0.012, Basis.IDENTITY, 0, EYE, head_tag)
	# Boynuz: alından arkaya ve dışa kıvrılır; yalnız koçta görünür (gölgelendirici başa çeker).
	var horn_tag := Vector4(0.0, 0.0, 1.0, -1.0)
	for sx: float in [-1.0, 1.0]:
		var path := PackedVector3Array()
		var radius := PackedFloat32Array()
		for i in 6:
			var t := float(i) / 5.0
			var a := t * 3.8
			path.append(head_at + Vector3(sx * (0.04 + 0.07 * t), 0.07 + 0.065 * sin(a * 0.9) - 0.03 * t, -0.05 - 0.085 * sin(a * 0.62) + 0.09 * t * t))
			radius.append(lerpf(0.026, 0.008, t))
		d.tube(path, radius, 4, HORN, horn_tag)
	# Bacaklar: sol arka, sol ön, sağ arka, sağ ön (fauna.md yürüyüş sırası).
	var legs := [[1.0, -1.0, -0.24], [2.0, -1.0, 0.2], [3.0, 1.0, -0.24], [4.0, 1.0, 0.2]]
	for row: Array in legs:
		_sheep_leg(d, float(row[0]), float(row[1]) * 0.125, float(row[2]))
	# Kuyruk: ağır, yağlı, sağrıdan sarkar.
	var tail_tag := func(v: Vector3) -> Vector4:
		return Vector4(0.0, 0.0, 0.0, clampf((SHEEP_TAIL.y - v.y) / 0.25, 0.0, 1.0))
	d.blob(Vector3(0.0, 0.45, -0.43), Vector3(0.145, 0.185, 0.105), Basis.IDENTITY, 1, woolly, tail_tag, 0.06, 16)
	return d


## Bacak: üstü yünlü ve kalın (gövdeye girer), incik ince ve koyu, tırnak daha koyu.
static func _sheep_leg(d: Draft, leg: float, x: float, z: float) -> void:
	var tag := func(v: Vector3) -> Vector4:
		return Vector4(leg, clampf((SHEEP_HIP + 0.05 - v.y) / 0.1, 0.0, 1.0), 0.0, 0.0)
	var bend := 0.016 if z > 0.0 else -0.03
	var points := PackedVector3Array([Vector3(x, 0.44, z), Vector3(x, 0.3, z + bend * 0.5), Vector3(x, 0.21, z + bend), Vector3(x, 0.08, z), Vector3(x, 0.03, z), Vector3(x, 0.0, z + 0.008)])
	var radii := PackedFloat32Array([0.08, 0.066, 0.034, 0.027, 0.03, 0.034])
	var paint := func(v: Vector3, _n: Vector3) -> Color:
		if v.y < 0.035:
			return HOOF
		if v.y > 0.26:
			return WOOL_SHADE
		return SHIN.lerp(SHIN.darkened(0.25), smoothstep(0.22, 0.06, v.y))
	d.tube(points, radii, 5, paint, tag)


# --- Kuşlar -----------------------------------------------------------------------------------------

## Tarla kuşu (çizgili kahverengi sırt, açık karın, küçük tepelik).
static func lark() -> Draft:
	var back := Color(0.42, 0.33, 0.22, 1.0)
	var belly := Color(0.82, 0.74, 0.58, 1.0)
	var streak := func(v: Vector3, n: Vector3) -> Color:
		var c: Color = belly.lerp(back, smoothstep(-0.25, 0.35, n.y))
		return c.darkened(0.22 if fmod(absf(v.z) * 38.0 + absf(v.x) * 16.0, 2.0) < 0.7 else 0.0)
	return _bird(0.175, streak, back.darkened(0.15), back, Color(0.3, 0.26, 0.2, 0.0), Color(0.45, 0.33, 0.25, 0.0), {
		"body": Vector3(0.042, 0.042, 0.078), "body_y": 0.078, "head_r": 0.03, "head": Vector3(0.0, 0.118, 0.068),
		"beak": 0.026, "wing": 0.14, "tail": 0.07, "leg": 0.04, "crest": true,
	})


## Keklik (kavram görseli partridge.png): gri göğüs, kahve sırt, turuncu yüz, kızıl böğür çizgileri, karında kestane leke; gri gaga, açık bacak.
static func partridge() -> Draft:
	var grey := Color(0.62, 0.6, 0.56, 1.0)
	var back := Color(0.5, 0.38, 0.26, 1.0)
	var face := Color(0.76, 0.5, 0.28, 1.0)
	var rust := Color(0.5, 0.31, 0.2, 1.0)
	var chestnut := Color(0.38, 0.2, 0.14, 1.0)
	var paint := func(v: Vector3, n: Vector3) -> Color:
		if v.z > 0.09 and v.y > 0.17 and n.y < 0.7:
			return face
		if n.y > 0.45:
			return back.lerp(back.darkened(0.3), 0.5 if fmod(absf(v.z) * 34.0 + absf(v.x) * 12.0, 2.0) < 0.9 else 0.0)
		if n.y < -0.25 and absf(v.z - 0.02) < 0.05:
			return chestnut
		if absf(n.x) > 0.45 and fmod(absf(v.z) * 30.0, 2.0) < 0.8:
			return rust
		return grey
	return _bird(0.33, paint, back, back.darkened(0.1), Color(0.42, 0.42, 0.4, 0.0), Color(0.62, 0.45, 0.34, 0.0), {
		"body": Vector3(0.07, 0.072, 0.115), "body_y": 0.128, "head_r": 0.042, "head": Vector3(0.0, 0.195, 0.115),
		"beak": 0.024, "wing": 0.2, "tail": 0.06, "leg": 0.075, "crest": false,
	})


## Karga (kavram görseli crow.png: kara, mavi parıltı, ağır gaga, uzun kuyruk).
static func crow() -> Draft:
	var black := Color(0.09, 0.09, 0.11, 1.0)
	var sheen := Color(0.15, 0.16, 0.22, 1.0)
	var paint := func(_v: Vector3, n: Vector3) -> Color:
		return black.lerp(sheen, clampf(n.y, 0.0, 1.0))
	return _bird(0.46, paint, black, black, Color(0.05, 0.05, 0.06, 0.0), Color(0.06, 0.06, 0.07, 0.0), {
		"body": Vector3(0.062, 0.066, 0.135), "body_y": 0.165, "head_r": 0.048, "head": Vector3(0.0, 0.24, 0.125),
		"beak": 0.07, "wing": 0.3, "tail": 0.17, "leg": 0.105, "crest": false,
	})


## Kuşun ortak bedeni: damla gövde ve baş, gaga, açık duran iki kanat (gölgelendirici yerdeyken katlar), kuyruk yelpazesi, iki bacak.
## paint gövde ve başın rengi (Color ya da Callable), wing kanadın, tail kuyruğun, beak gagasının, leg bacağın rengidir.
static func _bird(_length: float, paint: Variant, wing: Color, tail: Color, beak: Color, leg: Color, s: Dictionary) -> Draft:
	var d := Draft.new()
	var radii: Vector3 = s["body"]
	var y0 := float(s["body_y"])
	var head: Vector3 = s["head"]
	var r_head := float(s["head_r"])
	var body_tag := Vector4.ZERO
	d.blob(Vector3(0.0, y0, 0.0), radii, Basis(Vector3.RIGHT, deg_to_rad(-12.0)), 2, paint, body_tag)
	var head_tag := func(_v: Vector3) -> Vector4:
		return Vector4(0.0, 1.0, 0.0, 0.0)
	d.blob(head, Vector3(r_head, r_head, r_head * 1.12), Basis.IDENTITY, 2, paint, head_tag)
	if bool(s["crest"]):
		d.blob(head + Vector3(0.0, r_head * 0.95, -r_head * 0.35), Vector3(r_head * 0.3, r_head * 0.42, r_head * 0.6), Basis(Vector3.RIGHT, deg_to_rad(28.0)), 1, wing, head_tag)
	# Göz.
	for sx: float in [-1.0, 1.0]:
		d.blob(head + Vector3(sx * r_head * 0.8, r_head * 0.2, r_head * 0.42), Vector3.ONE * r_head * 0.18, Basis.IDENTITY, 0, EYE, head_tag)
	# Gaga: başın önünde, hafif aşağı.
	var beak_len := float(s["beak"])
	var tip := head + Vector3(0.0, -r_head * 0.22, r_head + beak_len)
	var root := head + Vector3(0.0, -r_head * 0.1, r_head * 0.82)
	d.tube(PackedVector3Array([root, root.lerp(tip, 0.55), tip]), PackedFloat32Array([r_head * 0.34, r_head * 0.2, 0.003]), 5, beak, head_tag)
	# Kanat: iki yanda düz yelpaze; kök gövdenin omzunda, uç açık. Gölgelendirici yerdeyken sırta katlar.
	var span := float(s["wing"])
	var chord := radii.z * 1.15
	var w_y := y0 + radii.y * 0.5
	for sx: float in [-1.0, 1.0]:
		var wing_tag := func(v: Vector3) -> Vector4:
			return Vector4(signf(v.x) * clampf((absf(v.x) - radii.x * 0.5) / span, 0.0, 1.0), 0.0, 0.0, 0.0)
		var wing_paint := func(v: Vector3, _n: Vector3) -> Color:
			return wing.darkened(0.25 * clampf((absf(v.x) - radii.x) / span, 0.0, 1.0))
		var rows := PackedVector3Array()
		for k in 4:
			var t := float(k) / 3.0
			var x := sx * (radii.x * 0.5 + span * t)
			var c := chord * lerpf(1.0, 0.42, t * t)
			rows.append(Vector3(x, w_y + 0.006 * t, radii.z * 0.45 - c * 0.12 * t))
			rows.append(Vector3(x, w_y + 0.006 * t, radii.z * 0.45 - c))
		d.strip(rows, Vector3.UP, wing_paint, wing_tag)
	# Kuyruk: arkaya uzanan yelpaze.
	var tail_len := float(s["tail"])
	var tail_w := radii.x * 0.55
	var tail_tag := func(v: Vector3) -> Vector4:
		return Vector4(0.0, 0.0, clampf((-v.z - radii.z * 0.6) / tail_len, 0.0, 1.0), 0.0)
	var z0 := -radii.z * 0.72
	var z1 := z0 - tail_len
	var ty := y0 - radii.y * 0.05
	d.strip(PackedVector3Array([Vector3(-tail_w * 0.6, ty, z0), Vector3(tail_w * 0.6, ty, z0), Vector3(-tail_w, ty - 0.01, z1), Vector3(tail_w, ty - 0.01, z1)]), Vector3.UP, tail, tail_tag)
	# Bacaklar.
	var leg_h := float(s["leg"])
	for sx: float in [-1.0, 1.0]:
		var tag := Vector4(0.0, 0.0, 0.0, sx)
		var x := sx * radii.x * 0.42
		d.tube(PackedVector3Array([Vector3(x, y0 - radii.y * 0.7, 0.0), Vector3(x, leg_h * 0.3, 0.005), Vector3(x, 0.0, 0.015)]), PackedFloat32Array([0.006, 0.005, 0.009]), 3, leg, tag)
		# Parmaklar: öne uzanan küçük ayak.
		d.tube(PackedVector3Array([Vector3(x, 0.004, 0.0), Vector3(x, 0.002, 0.03 + radii.z * 0.1)]), PackedFloat32Array([0.007, 0.003]), 3, leg, tag)
	return d


# --- Küçük memeliler ---------------------------------------------------------------------------------

## Tarbagan (kavram görseli marmot.png): şişman, kısa bacaklı; altın sarısı post, koyu tepe, açık burun, küçük kulak, kısa kuyruk.
static func marmot() -> Draft:
	var fur := Color(0.68, 0.5, 0.3, 1.0)
	var top := Color(0.36, 0.27, 0.19, 1.0)
	var under := Color(0.8, 0.66, 0.44, 1.0)
	var paint := func(_v: Vector3, n: Vector3) -> Color:
		var c: Color = under.lerp(fur, smoothstep(-0.5, 0.1, n.y))
		return c.lerp(top, smoothstep(0.45, 0.98, n.y) * 0.85)
	return _rodent(paint, top, Color(0.2, 0.15, 0.11, 0.0), {
		"body": Vector3(0.12, 0.125, 0.215), "body_y": 0.155, "head": Vector3(0.0, 0.23, 0.21), "head_r": Vector3(0.076, 0.07, 0.088),
		"ear": 0.022, "leg": 0.055, "leg_r": 0.03, "tail_len": 0.13, "tail_r": 0.03, "lump": 0.07, "seed": 31,
	})


## Kum faresi (Moğol gerbili; çocuk yayına uygun kemirgen): kum rengi sırt, açık karın, uzun püsküllü kuyruk, iri kulak.
static func gerbil() -> Draft:
	var sand := Color(0.68, 0.53, 0.34, 1.0)
	var pale := Color(0.92, 0.86, 0.72, 1.0)
	var paint := func(_v: Vector3, n: Vector3) -> Color:
		return pale.lerp(sand, smoothstep(-0.45, 0.05, n.y))
	return _rodent(paint, sand.darkened(0.3), Color(0.5, 0.36, 0.28, 0.0), {
		"body": Vector3(0.04, 0.042, 0.08), "body_y": 0.05, "head": Vector3(0.0, 0.074, 0.082), "head_r": Vector3(0.028, 0.027, 0.036),
		"ear": 0.012, "leg": 0.018, "leg_r": 0.009, "tail_len": 0.16, "tail_r": 0.006, "lump": 0.05, "seed": 37,
	})


## Tavşan (tolay tavşanı; Kışlak'ın kapan ve sapan avı, survival.md §4.1): kumlu boz sırt, açık karın, uzun kulak (ucu kara), iri arka
## bacak, ak kuyruk püskülü. Küçük av gölgelendiricisiyle (small_game.gdshader) koşar ve dikilir; ≤1,2k üçgen (fauna.md §10).
static func hare() -> Draft:
	var d := Draft.new()
	var back := Color(0.55, 0.47, 0.37, 1.0)
	var belly := Color(0.86, 0.82, 0.74, 1.0)
	var paint := func(_v: Vector3, n: Vector3) -> Color:
		return belly.lerp(back, smoothstep(-0.45, 0.15, n.y))
	var body_tag := func(v: Vector3) -> Vector4:
		return Vector4(0.0, smoothstep(0.0, 0.14, v.z) * 0.4, 0.0, 0.0)
	d.blob(Vector3(0.0, 0.15, -0.02), Vector3(0.085, 0.1, 0.17), Basis(Vector3.RIGHT, deg_to_rad(-14.0)), 2, paint, body_tag, 0.05, 41)
	var head_tag := Vector4(0.0, 1.0, 0.0, 0.0)
	var head := Vector3(0.0, 0.22, 0.155)
	d.blob(head, Vector3(0.05, 0.055, 0.07), Basis(Vector3.RIGHT, deg_to_rad(18.0)), 2, paint, head_tag)
	var skin := Color(0.35, 0.27, 0.22, 0.0)
	d.blob(head + Vector3(0.0, -0.012, 0.06), Vector3(0.022, 0.018, 0.016), Basis.IDENTITY, 0, skin, head_tag)
	for sx: float in [-1.0, 1.0]:
		# Uzun kulak: başın tepesinden arkaya yatık; ucu kara.
		var ear_paint := func(v: Vector3, _n: Vector3) -> Color:
			return Color(0.12, 0.1, 0.09, 1.0) if v.y > 0.345 else back.lightened(0.08)
		d.blob(head + Vector3(sx * 0.026, 0.085, -0.045), Vector3(0.017, 0.075, 0.028), Basis(Vector3.RIGHT, deg_to_rad(-28.0)) * Basis(Vector3.BACK, deg_to_rad(sx * 10.0)), 1, ear_paint, head_tag)
		d.blob(head + Vector3(sx * 0.04, 0.012, 0.022), Vector3.ONE * 0.009, Basis.IDENTITY, 0, EYE, head_tag)
	# Bacaklar: iri arka bacak (uyluk), ince ön bacak; w bacağın işareti (koşuda çapraz).
	for sx: float in [-1.0, 1.0]:
		var hind_tag := Vector4(0.0, 0.0, 0.0, sx)
		d.blob(Vector3(sx * 0.06, 0.1, -0.1), Vector3(0.035, 0.07, 0.085), Basis(Vector3.RIGHT, deg_to_rad(20.0)), 1, paint, hind_tag)
		d.tube(PackedVector3Array([Vector3(sx * 0.06, 0.05, -0.12), Vector3(sx * 0.06, 0.012, -0.06), Vector3(sx * 0.058, 0.0, 0.0)]),
			PackedFloat32Array([0.018, 0.014, 0.012]), 4, back.darkened(0.15), hind_tag)
		var fore_tag := Vector4(0.0, 0.0, 0.0, -sx)
		d.tube(PackedVector3Array([Vector3(sx * 0.04, 0.12, 0.09), Vector3(sx * 0.04, 0.05, 0.1), Vector3(sx * 0.04, 0.0, 0.11)]),
			PackedFloat32Array([0.016, 0.011, 0.01]), 4, back, fore_tag)
	var tail_tag := Vector4(0.0, 0.0, 1.0, 0.0)
	d.blob(Vector3(0.0, 0.17, -0.19), Vector3(0.03, 0.03, 0.025), Basis.IDENTITY, 1, Color(0.95, 0.94, 0.9, 1.0), tail_tag)
	return d


## Altın kartal (fauna.md §5.2; kadrajda yalnız gölgesi ve sesi vardır, gerçek irtifada süzülür): koyu kahve gövde, altın ense, açık ve uzun
## kanat (iki yanda ≈1 m: açıklık ≈2,1 m), geniş kuyruk, çengel gaga. Küçük av gölgelendiricisiyle süzülür (çırpma seyrek, kanat esner).
static func eagle() -> Draft:
	var brown := Color(0.25, 0.17, 0.11, 1.0)
	var gold := Color(0.62, 0.46, 0.24, 1.0)
	var paint := func(v: Vector3, n: Vector3) -> Color:
		if v.y > 0.25 and v.z > 0.1:
			return gold
		return brown.lerp(brown.lightened(0.12), clampf(n.y, 0.0, 1.0))
	return _bird(0.85, paint, brown.darkened(0.15), brown, Color(0.75, 0.66, 0.3, 0.0), Color(0.78, 0.66, 0.3, 0.0), {
		"body": Vector3(0.12, 0.13, 0.3), "body_y": 0.27, "head_r": 0.075, "head": Vector3(0.0, 0.36, 0.27),
		"beak": 0.07, "wing": 0.95, "tail": 0.3, "leg": 0.16, "crest": false,
	})


## Yaban domuzu (yer tutucu, K89: Meshy modeli gelene dek; suid planı, omuz 0,85 m, boy 1,45 m): yüksek omuz ve sırtta kıl yelesi, kama baş ve
## uzun burun, kısa ince bacak, küçük diş, ince kuyruk. Sürü gölgelendiricisiyle (herd_field.gdshader) yürür ve burnuyla toprağı eşeler;
## parça etiketleri koyununkiyle aynı dildedir. ≤1.800 üçgen.
static func boar() -> Draft:
	var d := Draft.new()
	var hide := Color(0.3, 0.25, 0.21, 1.0)
	var under := Color(0.22, 0.18, 0.16, 1.0)
	var bristle := Color(0.14, 0.12, 0.11, 1.0)
	var snout := Color(0.42, 0.33, 0.3, 0.0)
	var hoof := Color(0.1, 0.09, 0.08, 0.0)
	var tusk := Color(0.86, 0.8, 0.66, 0.0)
	var shade := func(v: Vector3, n: Vector3) -> Color:
		return under.lerp(hide, clampf((v.y - 0.32) / 0.4, 0.0, 1.0) * (0.75 + 0.25 * clampf(n.y * 0.5 + 0.5, 0.0, 1.0)))
	var body := Vector4.ZERO
	# Gövde: önde yüksek omuz, arkaya inen sırt.
	d.blob(Vector3(0.0, 0.54, -0.12), Vector3(0.24, 0.26, 0.5), Basis(Vector3.RIGHT, deg_to_rad(4.0)), 2, shade, body, 0.05, 51)
	d.blob(Vector3(0.0, 0.62, 0.2), Vector3(0.25, 0.27, 0.3), Basis.IDENTITY, 2, shade, body, 0.06, 52)
	# Kıl yelesi: sırt boyunca koyu küçük kabarıklar.
	for k in 7:
		var t := float(k) / 6.0
		var z := lerpf(0.38, -0.3, t)
		var y := lerpf(0.86, 0.76, t)
		d.blob(Vector3(0.0, y, z), Vector3(0.05, 0.07 - 0.02 * t, 0.07), Basis.IDENTITY, 0, bristle, body)
	# Baş: kama; boyun dibinden döner (otlamada burun yere iner).
	var neck_tag := func(v: Vector3) -> Vector4:
		return Vector4(0.0, 0.0, smoothstep(0.36, 0.52, v.z), 0.0)
	var head_tag := Vector4(0.0, 0.0, 1.0, 0.0)
	d.blob(Vector3(0.0, 0.56, 0.48), Vector3(0.16, 0.19, 0.18), Basis(Vector3.RIGHT, deg_to_rad(18.0)), 1, shade, neck_tag, 0.04, 53)
	d.blob(Vector3(0.0, 0.47, 0.66), Vector3(0.1, 0.12, 0.17), Basis(Vector3.RIGHT, deg_to_rad(28.0)), 1, shade, head_tag)
	d.tube(PackedVector3Array([Vector3(0.0, 0.43, 0.72), Vector3(0.0, 0.38, 0.82), Vector3(0.0, 0.35, 0.88)]), PackedFloat32Array([0.07, 0.055, 0.05]), 6, shade, head_tag)
	d.blob(Vector3(0.0, 0.35, 0.89), Vector3(0.052, 0.045, 0.02), Basis.IDENTITY, 0, snout, head_tag)
	for sx: float in [-1.0, 1.0]:
		d.blob(Vector3(sx * 0.07, 0.66, 0.56), Vector3(0.035, 0.06, 0.02), Basis(Vector3.BACK, deg_to_rad(sx * -20.0)), 0, bristle, head_tag)
		d.blob(Vector3(sx * 0.075, 0.53, 0.72), Vector3.ONE * 0.014, Basis.IDENTITY, 0, EYE, head_tag)
		d.tube(PackedVector3Array([Vector3(sx * 0.05, 0.37, 0.8), Vector3(sx * 0.07, 0.4, 0.82), Vector3(sx * 0.075, 0.44, 0.8)]), PackedFloat32Array([0.012, 0.009, 0.003]), 3, tusk, head_tag)
	# Bacaklar: sol arka, sol ön, sağ arka, sağ ön (fauna.md yürüyüş sırası); kısa, ince.
	for row: Array in [[1.0, -1.0, -0.42], [2.0, -1.0, 0.26], [3.0, 1.0, -0.42], [4.0, 1.0, 0.26]]:
		var leg := float(row[0])
		var x := float(row[1]) * 0.12
		var z := float(row[2])
		var tag := func(v: Vector3) -> Vector4:
			return Vector4(leg, clampf((BOAR_HIP + 0.05 - v.y) / 0.1, 0.0, 1.0), 0.0, 0.0)
		var paint := func(v: Vector3, _n: Vector3) -> Color:
			return hoof if v.y < 0.04 else under.darkened(0.2)
		d.tube(PackedVector3Array([Vector3(x, 0.46, z), Vector3(x, 0.3, z + 0.01), Vector3(x, 0.12, z), Vector3(x, 0.03, z + 0.01), Vector3(x, 0.0, z + 0.02)]),
			PackedFloat32Array([0.075, 0.055, 0.035, 0.03, 0.033]), 5, paint, tag)
	# Kuyruk: ince, ucu püsküllü.
	var tail_tag := func(v: Vector3) -> Vector4:
		return Vector4(0.0, 0.0, 0.0, clampf((BOAR_TAIL.y - v.y) / 0.2, 0.0, 1.0))
	d.tube(PackedVector3Array([Vector3(0.0, 0.62, -0.6), Vector3(0.0, 0.52, -0.66), Vector3(0.0, 0.42, -0.67)]), PackedFloat32Array([0.018, 0.013, 0.01]), 4, bristle, tail_tag)
	d.blob(Vector3(0.0, 0.4, -0.67), Vector3(0.025, 0.04, 0.025), Basis.IDENTITY, 0, bristle, tail_tag)
	return d


static func _rodent(paint: Variant, tail_tip: Color, skin: Color, s: Dictionary) -> Draft:
	var d := Draft.new()
	var radii: Vector3 = s["body"]
	var y0 := float(s["body_y"])
	var head: Vector3 = s["head"]
	var r_head: Vector3 = s["head_r"]
	var body_tag := func(v: Vector3) -> Vector4:
		return Vector4(0.0, smoothstep(0.0, radii.z * 0.8, v.z), 0.0, 0.0)
	d.blob(Vector3(0.0, y0, 0.0), radii, Basis(Vector3.RIGHT, deg_to_rad(-6.0)), 2, paint, body_tag, float(s["lump"]), int(s["seed"]))
	var head_tag := Vector4(0.0, 1.0, 0.0, 0.0)
	d.blob(head, r_head, Basis.IDENTITY, 2, paint, head_tag)
	# Burun ve kulaklar.
	d.blob(head + Vector3(0.0, -r_head.y * 0.2, r_head.z * 0.92), Vector3(r_head.x * 0.28, r_head.y * 0.22, r_head.z * 0.18), Basis.IDENTITY, 0, skin, head_tag)
	var ear := float(s["ear"])
	for sx: float in [-1.0, 1.0]:
		d.blob(head + Vector3(sx * r_head.x * 0.72, r_head.y * 0.78, -r_head.z * 0.18), Vector3(ear * 0.8, ear, ear * 0.42), Basis.IDENTITY, 0, skin, head_tag)
		d.blob(head + Vector3(sx * r_head.x * 0.78, r_head.y * 0.32, r_head.z * 0.42), Vector3.ONE * r_head.x * 0.17, Basis.IDENTITY, 0, EYE, head_tag)
	# Bacaklar: dört kısa kütük.
	var leg_h := float(s["leg"])
	var leg_r := float(s["leg_r"])
	for row: Array in [[-1.0, 0.62, 1.0], [1.0, 0.62, -1.0], [-1.0, -0.6, -1.0], [1.0, -0.6, 1.0]]:
		var x := float(row[0]) * radii.x * 0.62
		var z := float(row[1]) * radii.z
		d.tube(PackedVector3Array([Vector3(x, leg_h * 1.6, z), Vector3(x, leg_h * 0.5, z), Vector3(x, 0.0, z + leg_r * 0.5)]),
			PackedFloat32Array([leg_r * 1.1, leg_r, leg_r * 0.9]), 5, skin, Vector4(0.0, 0.0, 0.0, float(row[2])))
	# Kuyruk.
	var len_t := float(s["tail_len"])
	var r_t := float(s["tail_r"])
	var tail_tag := func(v: Vector3) -> Vector4:
		return Vector4(0.0, 0.0, clampf((-v.z - radii.z * 0.8) / len_t, 0.0, 1.0), 0.0)
	var tail_paint := func(v: Vector3, _n: Vector3) -> Color:
		if -v.z > radii.z * 0.8 + len_t * 0.72:
			return tail_tip
		return (paint as Callable).call(v, Vector3.UP)
	d.tube(PackedVector3Array([Vector3(0.0, y0 - radii.y * 0.1, -radii.z * 0.85), Vector3(0.0, y0 - radii.y * 0.35, -radii.z * 0.85 - len_t * 0.5), Vector3(0.0, y0 - radii.y * 0.55, -radii.z * 0.85 - len_t)]),
		PackedFloat32Array([r_t, r_t * 1.05, r_t * 0.75]), 5, tail_paint, tail_tag)
	return d


## Model arka planda mı yüklenir (ResourceLoader.load_threaded_request)? Başsızda hayır (WorldHost.threaded gibi): boş çizicinin
## (RendererDummy) ağ ve doku kimlikleri iş parçacığına karşı korunmuyor. Kışlak bütün katmanlarıyla başsız kurulurken yükleyici iş
## parçacığındaki uzak ağ ve doku, ana iş parçacığının kurduğu ağla (AgentCrowd.setup, yaban domuzu) yarışıyor, «Parameter "t" is null»
## yazıyordu; çıkışta boş çizicinin doku kimliği sızıyordu. Başsızda model eşzamanlı yüklenir; ağın çevrilmesi (from_model: yalnız dizi
## ve görüntü, kimlik kurmaz) yine WorkerThreadPool'dadır. Pencerede gerçek çizici iş parçacığından kurulan kaynakları taşır.
static func background_loads() -> bool:
	return DisplayServer.get_name() != "headless"


## Modelin ilk yüzeyinin doku görüntüsü (ana iş parçacığında; from_model'in boyası). Dokusu yoksa null.
static func model_image(mesh: Mesh) -> Image:
	var material := mesh.surface_get_material(0) if mesh else null
	var texture: Texture2D = (material as BaseMaterial3D).albedo_texture if material is BaseMaterial3D else null
	return texture.get_image() if texture else null


## Küçük avın gölgelendirici ölçüleri (small_game.gdshader; ağ uzayında): boyun ve kalça, kanat açıklığı.
static func shader_params(kind_id: String) -> Dictionary:
	match kind_id:
		"lark":
			return {"neck_pivot": Vector3(0.0, 0.1, 0.045), "hip_pivot": Vector3(0.0, 0.07, -0.03), "wing_span": 0.14}
		"partridge":
			return {"neck_pivot": Vector3(0.0, 0.165, 0.075), "hip_pivot": Vector3(0.0, 0.1, -0.05), "wing_span": 0.2}
		"crow":
			return {"neck_pivot": Vector3(0.0, 0.2, 0.085), "hip_pivot": Vector3(0.0, 0.13, -0.06), "wing_span": 0.3}
		"marmot":
			return {"neck_pivot": Vector3(0.0, 0.19, 0.14), "hip_pivot": Vector3(0.0, 0.08, -0.14), "wing_span": 0.0}
		"gerbil":
			return {"neck_pivot": Vector3(0.0, 0.06, 0.055), "hip_pivot": Vector3(0.0, 0.025, -0.055), "wing_span": 0.0}
		"hare":
			return {"neck_pivot": Vector3(0.0, 0.19, 0.12), "hip_pivot": Vector3(0.0, 0.08, -0.12), "wing_span": 0.0}
		"eagle":
			return {"neck_pivot": Vector3(0.0, 0.32, 0.2), "hip_pivot": Vector3(0.0, 0.2, -0.12), "wing_span": 0.95, "flap_lift": 0.12}
	return {}


## Kodla çizilen dört ayaklının sürü gölgelendiricisi ölçüleri (herd_field.gdshader; ağ uzayında): kalça, boyun ve sağrı. Koyun için
## gölgelendiricinin varsayılanları geçer (boş sözlük).
static func herd_params(kind_id: String) -> Dictionary:
	match kind_id:
		"boar":
			return {"hip_height": BOAR_HIP, "neck_pivot": BOAR_NECK, "tail_pivot": BOAR_TAIL, "graze_angle": 0.75}
	return {}


# --- Meshy ağı (sürü) ---------------------------------------------------------------------------------

## Meshy ağının yüzeyini sürü ağına çevirir (saf; iş parçacığında çalışır): dikişlerde bölünmüş köşeler kaynaşır (Meshy'nin ağı UV dikişinde
## bölünmüştür, indirgeyici dikişi kilitler; varlik-hatti.md §3.1), üçgen sayısı max_triangles'a iner (army.md §7.1, T1), boy length'e, taban y = 0'a gelir.
## Doku yerine köşe rengi: renk köşenin UV'sinden okunur (image verilmezse beyaz), sürü 4K doku taşımaz; T1'de emek renge gider (fauna.md §10). Parça
## bilgisi ağın biçiminden çıkar: tabandan yükseklik ve boyun yeri (başı +Z'de duran hayvan). Döner: arrays() biçiminde sözlük; ek olarak hip, neck, tail
## ölçüleri ve triangles; yüzey boşsa boş sözlük.
## ratios (FaunaKind.herd_look: hip, neck [y, z], tail [y, z]) verilirse eklemler türün oranındadır; yoksa koyunun (bovid_s).
static func from_model(surface: Array, length: float, max_triangles: int, image: Image = null, ratios: Dictionary = {}) -> Dictionary:
	var points: PackedVector3Array = surface[Mesh.ARRAY_VERTEX]
	if points.is_empty():
		return {}
	var uvs: PackedVector2Array = surface[Mesh.ARRAY_TEX_UV] if surface[Mesh.ARRAY_TEX_UV] is PackedVector2Array else PackedVector2Array()
	var source_faces := _surface_indices(surface)
	# Dikişleri kaynaştır: aynı noktadaki köşeler bir köşe olur (rengi ilkinin).
	var box := AABB(points[0], Vector3.ZERO)
	for p in points:
		box = box.expand(p)
	var quant := maxf(box.size.length(), 0.001) * 0.0002
	var welded_of := {}
	var welded_points := PackedVector3Array()
	var welded_uvs := PackedVector2Array()
	var remap := PackedInt32Array()
	remap.resize(points.size())
	for i in points.size():
		var key := Vector3i((points[i] / quant).round())
		var w: int = welded_of.get(key, -1)
		if w < 0:
			w = welded_points.size()
			welded_of[key] = w
			welded_points.append(points[i])
			welded_uvs.append(uvs[i] if uvs.size() == points.size() else Vector2.ZERO)
		remap[i] = w
	var faces := PackedInt32Array()
	for k in range(0, source_faces.size(), 3):
		var a := remap[source_faces[k]]
		var b := remap[source_faces[k + 1]]
		var c := remap[source_faces[k + 2]]
		if a != b and b != c and a != c:
			faces.append_array(PackedInt32Array([a, b, c]))
	var welded_normals := MeshKit.smooth_normals(welded_points, faces)
	var hip_ratio := float(ratios.get("hip", SHEEP_HIP / SHEEP_HEIGHT))
	var chosen := reduced_indices(welded_points, faces, box, max_triangles, hip_ratio)
	# Ölçü: boy length'e iner, boy ortalanır, taban yere.
	var scale := length / maxf(box.size.z, 0.001)
	var center_x := box.position.x + box.size.x * 0.5
	var center_z := box.position.z + box.size.z * 0.5
	var joints := model_joints(box.size.y * scale, length, ratios)
	var used := {}
	var out := {"vertices": PackedVector3Array(), "normals": PackedVector3Array(), "colors": PackedColorArray(), "custom": PackedFloat32Array(), "indices": PackedInt32Array()}
	var out_vertices: PackedVector3Array = out["vertices"]
	var out_normals: PackedVector3Array = out["normals"]
	var out_colors: PackedColorArray = out["colors"]
	var out_custom: PackedFloat32Array = out["custom"]
	var out_indices: PackedInt32Array = out["indices"]
	var size := image.get_size() if image else Vector2i.ONE
	for k in chosen:
		if not used.has(k):
			used[k] = out_vertices.size()
			var p := welded_points[k]
			var v := Vector3((p.x - center_x) * scale, (p.y - box.position.y) * scale, (p.z - center_z) * scale)
			out_vertices.append(v)
			out_normals.append(welded_normals[k])
			var color := Color.WHITE
			if image:
				var uv := welded_uvs[k]
				color = image.get_pixel(posmod(int(uv.x * size.x), size.x), posmod(int(uv.y * size.y), size.y)).srgb_to_linear()
				color.a = 1.0
			out_colors.append(color)
			var tag := model_tag(v, joints, length)
			out_custom.append_array(PackedFloat32Array([tag.x, tag.y, tag.z, tag.w]))
		out_indices.append(int(used[k]))
	out["vertices"] = out_vertices
	out["normals"] = out_normals
	out["colors"] = out_colors
	out["custom"] = out_custom
	out["indices"] = out_indices
	out["hip"] = joints["hip"]
	out["neck"] = joints["neck"]
	out["tail"] = joints["tail"]
	return out


## Modelin eklem ölçüleri (saf): boy ve uzunluktan, bir bovid_s'in oranlarıyla (kodla çizilen koyunla aynı).
## ratios: türün oranları (hip boyun payı; neck ve tail [boyun payı, uzunluğun payı]); yoksa koyunun.
static func model_joints(height: float, length: float, ratios: Dictionary = {}) -> Dictionary:
	var neck: Array = ratios.get("neck", [SHEEP_NECK.y / SHEEP_HEIGHT, SHEEP_NECK.z / SHEEP_LENGTH])
	var tail: Array = ratios.get("tail", [SHEEP_TAIL.y / SHEEP_HEIGHT, SHEEP_TAIL.z / SHEEP_LENGTH])
	return {
		"height": height,
		"hip": height * float(ratios.get("hip", SHEEP_HIP / SHEEP_HEIGHT)),
		"neck": Vector3(0.0, height * float(neck[0]), length * float(neck[1])),
		"tail": Vector3(0.0, height * float(tail[0]), length * float(tail[1])),
	}


## Köşenin parça bilgisi (saf; v ölçeklenmiş model uzayında): kalça altı bacak, boyun önü baş, sağrı arkası kuyruk.
static func model_tag(v: Vector3, joints: Dictionary, length: float) -> Vector4:
	var hip := float(joints["hip"])
	var neck: Vector3 = joints["neck"]
	var tail: Vector3 = joints["tail"]
	var half := length * 0.5
	if v.y < hip + 0.03 and absf(v.z) < half * 0.82:
		var swing := clampf((hip + 0.03 - v.y) / 0.1, 0.0, 1.0)
		var leg := 0.0
		if v.x < 0.0:
			leg = 2.0 if v.z > 0.0 else 1.0
		else:
			leg = 4.0 if v.z > 0.0 else 3.0
		return Vector4(leg, swing, 0.0, 0.0)
	var head := smoothstep(neck.z + 0.03, neck.z + 0.19, v.z) * smoothstep(neck.y - 0.1, neck.y + 0.04, v.y)
	var back := smoothstep(tail.z + 0.05, tail.z - 0.03, v.z)
	return Vector4(0.0, 0.0, head, back)


## Dizinler en çok max_triangles üçgene iner (saf): kaynaşmış ağda ızgara kümelemesi; hücre boyu ikiye bölmeyle sınıra en yakın değere iner. Bacaklar
## (kalçanın altı) yarım hücreyle kümelenir: ince parça kaybolmasın (motorun LOD üreticisi Meshy ağında ince bacakları siliyor, 8k üçgenin altına inemiyor).
## Sınırın altındaysa özgün dizinler.
static func reduced_indices(points: PackedVector3Array, faces: PackedInt32Array, box: AABB, max_triangles: int,
		hip_ratio: float = SHEEP_HIP / SHEEP_HEIGHT) -> PackedInt32Array:
	if faces.size() / 3 <= max_triangles:
		return faces
	var low := box.size.length() / 512.0
	var high := box.size.length() / 12.0
	var best := PackedInt32Array()
	for _i in 9:
		var cell := sqrt(low * high)
		var candidate := cluster_indices(points, faces, box, cell, hip_ratio)
		if candidate.size() / 3 <= max_triangles:
			best = candidate
			high = cell
		else:
			low = cell
	return best if not best.is_empty() else cluster_indices(points, faces, box, high, hip_ratio)


## Izgara kümelemesi (saf): aynı hücredeki köşeler ilk köşede birleşir; yozlaşan ve yinelenen üçgen düşer.
static func cluster_indices(points: PackedVector3Array, faces: PackedInt32Array, box: AABB, cell: float,
		hip_ratio: float = SHEEP_HIP / SHEEP_HEIGHT) -> PackedInt32Array:
	var leg_top := box.position.y + box.size.y * hip_ratio
	var fine := cell * 0.5
	var first := {}
	var rep := PackedInt32Array()
	rep.resize(points.size())
	for i in points.size():
		var p := points[i]
		var size := fine if p.y < leg_top else cell
		var key := Vector4i(floori(p.x / size), floori(p.y / size), floori(p.z / size), 1 if p.y < leg_top else 0)
		var r: int = first.get(key, -1)
		if r < 0:
			r = i
			first[key] = i
		rep[i] = r
	var seen := {}
	var out := PackedInt32Array()
	for k in range(0, faces.size(), 3):
		var a := rep[faces[k]]
		var b := rep[faces[k + 1]]
		var c := rep[faces[k + 2]]
		if a == b or b == c or a == c:
			continue
		# Sırayı koruyan anahtar: aynı üçgen üç dönüşte aynı.
		var low_i := mini(a, mini(b, c))
		var face_key := Vector3i(a, b, c)
		if low_i == b:
			face_key = Vector3i(b, c, a)
		elif low_i == c:
			face_key = Vector3i(c, a, b)
		if seen.has(face_key):
			continue
		seen[face_key] = true
		out.append_array(PackedInt32Array([a, b, c]))
	return out


static func _surface_indices(surface: Array) -> PackedInt32Array:
	var points: PackedVector3Array = surface[Mesh.ARRAY_VERTEX]
	if surface[Mesh.ARRAY_INDEX] is PackedInt32Array and not (surface[Mesh.ARRAY_INDEX] as PackedInt32Array).is_empty():
		return surface[Mesh.ARRAY_INDEX]
	var faces := PackedInt32Array()
	faces.resize(points.size())
	for i in points.size():
		faces[i] = i
	return faces
