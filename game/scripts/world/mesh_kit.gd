class_name MeshKit
extends RefCounted
## Prosedürel mesh üretim yardımcıları (saf, statik fonksiyonlar).
##
## Not: Godot'da ön yüzler, yüzeye dışarıdan bakıldığında SAAT YÖNÜNDE sıralanan üçgenlerdir.


## 2B profili Y ekseni etrafında döndürerek mesh üretir (yurt duvarı, çatı, fıçı, kova...).
## profile: alttan üste Vector2(yarıçap, yükseklik) noktaları.
## arc_from/arc_to: kısmi dönüş için açı aralığı (radyan); pelerin gibi açık kabuklar üretir.
## UV: u = çevre boyunca (uv_repeat kez tekrar), v = profil boyunca 0..1.
static func lathe(profile: PackedVector2Array, segments: int, uv_repeat: float = 1.0, arc_from: float = 0.0, arc_to: float = TAU) -> ArrayMesh:
	var count := profile.size()
	var lengths := PackedFloat32Array()
	lengths.resize(count)
	var total := 0.0
	for i in count:
		if i > 0:
			total += profile[i].distance_to(profile[i - 1])
		lengths[i] = total
	total = maxf(total, 0.0001)

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	for s in segments + 1:
		var u := float(s) / float(segments)
		var a := lerpf(arc_from, arc_to, u)
		var ca := cos(a)
		var sa := sin(a)
		for i in count:
			var p := profile[i]
			var tangent := (profile[mini(i + 1, count - 1)] - profile[maxi(i - 1, 0)]).normalized()
			var n2 := Vector2(tangent.y, -tangent.x)
			vertices.append(Vector3(p.x * ca, p.y, p.x * sa))
			normals.append(Vector3(n2.x * ca, n2.y, n2.x * sa).normalized())
			uvs.append(Vector2(u * uv_repeat, lengths[i] / total))

	var indices := PackedInt32Array()
	for s in segments:
		for i in count - 1:
			var a0 := s * count + i
			var a1 := a0 + 1
			var b0 := (s + 1) * count + i
			var b1 := b0 + 1
			indices.append_array([a0, b0, a1, a1, b0, b1])
	return _commit(vertices, normals, uvs, PackedColorArray(), indices)


## Üst ya da alt kapak (düz disk) — lathe ile kapalı nesneler için.
static func disc(radius: float, y: float, segments: int, facing_up: bool = true) -> ArrayMesh:
	var vertices := PackedVector3Array([Vector3(0.0, y, 0.0)])
	var normals := PackedVector3Array([Vector3.UP if facing_up else Vector3.DOWN])
	var uvs := PackedVector2Array([Vector2(0.5, 0.5)])
	for s in segments:
		var a := TAU * float(s) / float(segments)
		vertices.append(Vector3(cos(a) * radius, y, sin(a) * radius))
		normals.append(Vector3.UP if facing_up else Vector3.DOWN)
		uvs.append(Vector2(cos(a), sin(a)) * 0.5 + Vector2(0.5, 0.5))
	var indices := PackedInt32Array()
	for s in segments:
		var a := 1 + s
		var b := 1 + (s + 1) % segments
		if facing_up:
			indices.append_array([0, a, b])
		else:
			indices.append_array([0, b, a])
	return _commit(vertices, normals, uvs, PackedColorArray(), indices)


## İkosfer köşeleri ve üçgenleri: [PackedVector3Array, PackedInt32Array].
## Her üçgen dışarıdan bakınca saat yönünde sıralanır.
static func icosphere_data(subdivisions: int) -> Array:
	var t := (1.0 + sqrt(5.0)) / 2.0
	var verts: Array[Vector3] = [
		Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1),
	]
	for i in verts.size():
		verts[i] = verts[i].normalized()
	var faces: Array[Vector3i] = [
		Vector3i(0, 11, 5), Vector3i(0, 5, 1), Vector3i(0, 1, 7), Vector3i(0, 7, 10), Vector3i(0, 10, 11),
		Vector3i(1, 5, 9), Vector3i(5, 11, 4), Vector3i(11, 10, 2), Vector3i(10, 7, 6), Vector3i(7, 1, 8),
		Vector3i(3, 9, 4), Vector3i(3, 4, 2), Vector3i(3, 2, 6), Vector3i(3, 6, 8), Vector3i(3, 8, 9),
		Vector3i(4, 9, 5), Vector3i(2, 4, 11), Vector3i(6, 2, 10), Vector3i(8, 6, 7), Vector3i(9, 8, 1),
	]
	for _level in subdivisions:
		var cache := {}
		var next: Array[Vector3i] = []
		for f in faces:
			var a := _midpoint(verts, cache, f.x, f.y)
			var b := _midpoint(verts, cache, f.y, f.z)
			var c := _midpoint(verts, cache, f.z, f.x)
			next.append_array([Vector3i(f.x, a, c), Vector3i(f.y, b, a), Vector3i(f.z, c, b), Vector3i(a, b, c)])
		faces = next
	var out_verts := PackedVector3Array(verts)
	var out_indices := PackedInt32Array()
	for f in faces:
		# Godot sırası: dışa bakan normal cross(c - a, b - a) olmalı.
		var va := out_verts[f.x]
		var vb := out_verts[f.y]
		var vc := out_verts[f.z]
		if (vc - va).cross(vb - va).dot(va + vb + vc) >= 0.0:
			out_indices.append_array([f.x, f.y, f.z])
		else:
			out_indices.append_array([f.x, f.z, f.y])
	return [out_verts, out_indices]


## Yuvarlak, hafif yassı, doğal görünümlü kaya.
## Tabanı düzleştirilir ve y=0 civarına oturtulur; boyut ~1 birimdir (örnek başına ölçeklenir).
static func rock(rng_seed: int, subdivisions: int = 3, roughness: float = 0.32) -> ArrayMesh:
	var data := icosphere_data(subdivisions)
	var verts: PackedVector3Array = data[0]
	var indices: PackedInt32Array = data[1]
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var big := FastNoiseLite.new()
	big.seed = rng_seed
	big.frequency = 0.9
	big.fractal_octaves = 3
	var small := FastNoiseLite.new()
	small.seed = rng_seed + 7
	small.frequency = 3.0
	small.fractal_octaves = 2
	var stretch := Vector3(rng.randf_range(0.95, 1.35), rng.randf_range(0.6, 0.9), rng.randf_range(0.85, 1.2))
	var floor_y := -0.45 * stretch.y
	for i in verts.size():
		var v := verts[i]
		var d := 1.0 + big.get_noise_3dv(v) * roughness + small.get_noise_3dv(v) * roughness * 0.2
		var p := v * d * stretch
		if p.y < floor_y:
			p.y = lerpf(p.y, floor_y, 0.85)
		verts[i] = p
	var lowest := INF
	for v in verts:
		lowest = minf(lowest, v.y)
	for i in verts.size():
		verts[i].y -= lowest + 0.06
	return _commit(verts, smooth_normals(verts, indices), PackedVector2Array(), PackedColorArray(), indices)


## Yüz normallerinin ortalamasıyla yumuşak köşe normalleri.
static func smooth_normals(verts: PackedVector3Array, indices: PackedInt32Array) -> PackedVector3Array:
	var normals := PackedVector3Array()
	normals.resize(verts.size())
	for i in range(0, indices.size(), 3):
		var a := indices[i]
		var b := indices[i + 1]
		var c := indices[i + 2]
		var n := (verts[c] - verts[a]).cross(verts[b] - verts[a])
		normals[a] += n
		normals[b] += n
		normals[c] += n
	for i in normals.size():
		normals[i] = normals[i].normalized()
	return normals


## Stilize çam ağacı: gövde + üst üste binen, kenarları sarkık koni katları.
## COLOR.rgb köşe rengi (alttan üste koyu→açık), COLOR.a = 1 yaprak, 0 gövde.
## Yükseklik ~10 birim; örnek başına ölçeklenir.
static func conifer(rng_seed: int, tiers: int = 4, segments: int = 10) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	# Gövde: kısa bir kesik koni.
	_add_frustum(vertices, normals, colors, indices, 0.26, 0.15, 0.0, 2.4, 6, Color(0.2, 0.13, 0.08, 0.0), Color(0.3, 0.2, 0.12, 0.0))
	var height := rng.randf_range(9.0, 10.5)
	for t in tiers:
		var f := float(t) / float(maxi(tiers - 1, 1))
		var radius := lerpf(2.6, 1.05, f) * rng.randf_range(0.9, 1.1)
		var y0 := lerpf(1.3, height * 0.6, f)
		var tier_height := lerpf(3.9, 3.0, f) if t < tiers - 1 else height - y0
		var bottom_col := Color(0.04, 0.12, 0.05, 1.0).lerp(Color(0.06, 0.16, 0.06, 1.0), f)
		var top_col := Color(0.2, 0.37, 0.11, 1.0).lerp(Color(0.3, 0.46, 0.14, 1.0), f)
		_add_tier(vertices, normals, colors, indices, rng, y0, radius, tier_height, segments, bottom_col, top_col)
	return _commit(vertices, normals, PackedVector2Array(), colors, indices)


## Çimen kümesi: tabandan uca daralan, hafif kavisli yapraklar.
## UV.y = yaprak boyunca yükseklik (0 taban, 1 uç). Yükseklik ~1 birim.
static func grass_clump(blades: int, rng_seed: int, spread: float = 0.16) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var segs := 3
	for _b in blades:
		var angle := rng.randf() * TAU
		var dir := Vector3(cos(angle), 0.0, sin(angle))
		var side := Vector3(-dir.z, 0.0, dir.x)
		var root := Vector3(rng.randf_range(-spread, spread), 0.0, rng.randf_range(-spread, spread))
		var height := rng.randf_range(0.55, 1.0)
		var width := rng.randf_range(0.035, 0.06)
		var lean := rng.randf_range(0.08, 0.3) * height
		var base := vertices.size()
		for s in segs + 1:
			var t := float(s) / float(segs)
			var w := width * (1.0 - t * 0.92) * 0.5
			var center := root + dir * (lean * t * t) + Vector3(0.0, height * t, 0.0)
			vertices.append(center - side * w)
			vertices.append(center + side * w)
			normals.append(Vector3.UP)
			normals.append(Vector3.UP)
			uvs.append(Vector2(0.0, t * height))
			uvs.append(Vector2(1.0, t * height))
		for s in segs:
			var i0 := base + s * 2
			indices.append_array([i0, i0 + 1, i0 + 2, i0 + 1, i0 + 3, i0 + 2])
	return _commit(vertices, normals, uvs, PackedColorArray(), indices)


## Çiçek: ince sap + taç yaprakları shader'da çizilen küçük bir kafa.
## COLOR.a = 1 çiçek kafası, 0 sap. Kafa UV'si 0..1 (taç yaprak deseni için).
static func flower(stem_height: float = 0.3, head_size: float = 0.13) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var stem_w := 0.008
	var stem := [Vector3(-stem_w, 0.0, 0.0), Vector3(stem_w, 0.0, 0.0), Vector3(-stem_w, stem_height, 0.0), Vector3(stem_w, stem_height, 0.0)]
	for p in stem:
		vertices.append(p)
		normals.append(Vector3.UP)
		uvs.append(Vector2(0.5, 0.5))
		colors.append(Color(1, 1, 1, 0))
	indices.append_array([0, 2, 1, 1, 2, 3])
	# Kafa: hafif öne eğik kare.
	var h := head_size * 0.5
	var tilt := Basis(Vector3.RIGHT, deg_to_rad(-55.0))
	var head_base := vertices.size()
	var corners := [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
	for c in corners:
		var local := tilt * Vector3(c.x * h, 0.0, c.y * h)
		vertices.append(Vector3(0.0, stem_height, 0.0) + local)
		normals.append((tilt * Vector3.UP).normalized())
		uvs.append(Vector2(c.x * 0.5 + 0.5, c.y * 0.5 + 0.5))
		colors.append(Color(1, 1, 1, 1))
	indices.append_array([head_base, head_base + 1, head_base + 2, head_base + 1, head_base + 3, head_base + 2])
	return _commit(vertices, normals, uvs, colors, indices)


## Asılı bayrak kumaşı: üst kenarı y=0'da, aşağı doğru uzanır; normal +Z.
## UV (0,0) sol üst. cols x rows ızgara dalgalanma için yeterli çözünürlük verir.
static func cloth(width: float, height: float, cols: int = 10, rows: int = 14) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for r in rows + 1:
		for c in cols + 1:
			var u := float(c) / float(cols)
			var v := float(r) / float(rows)
			vertices.append(Vector3((u - 0.5) * width, -v * height, 0.0))
			normals.append(Vector3.BACK)
			uvs.append(Vector2(u, v))
	for r in rows:
		for c in cols:
			var tl := r * (cols + 1) + c
			var tr := tl + 1
			var bl := tl + cols + 1
			var br := bl + 1
			indices.append_array([tl, tr, bl, tr, br, bl])
	return _commit(vertices, normals, uvs, PackedColorArray(), indices)


# --- İç yardımcılar ---------------------------------------------------------

static func _midpoint(verts: Array[Vector3], cache: Dictionary, a: int, b: int) -> int:
	var key := Vector2i(mini(a, b), maxi(a, b))
	if cache.has(key):
		return cache[key]
	verts.append(((verts[a] + verts[b]) * 0.5).normalized())
	cache[key] = verts.size() - 1
	return verts.size() - 1


static func _add_frustum(vertices: PackedVector3Array, normals: PackedVector3Array, colors: PackedColorArray, indices: PackedInt32Array,
		r_bottom: float, r_top: float, y0: float, y1: float, segments: int, col_bottom: Color, col_top: Color) -> void:
	var base := vertices.size()
	var slope := (r_bottom - r_top) / maxf(y1 - y0, 0.001)
	for s in segments + 1:
		var a := TAU * float(s) / float(segments)
		var dir := Vector3(cos(a), 0.0, sin(a))
		var n := (dir + Vector3(0.0, slope, 0.0)).normalized()
		vertices.append(dir * r_bottom + Vector3(0.0, y0, 0.0))
		vertices.append(dir * r_top + Vector3(0.0, y1, 0.0))
		normals.append(n)
		normals.append(n)
		colors.append(col_bottom)
		colors.append(col_top)
	for s in segments:
		var b0 := base + s * 2
		indices.append_array([b0, b0 + 2, b0 + 1, b0 + 1, b0 + 2, b0 + 3])


static func _add_tier(vertices: PackedVector3Array, normals: PackedVector3Array, colors: PackedColorArray, indices: PackedInt32Array,
		rng: RandomNumberGenerator, y0: float, radius: float, tier_height: float, segments: int, col_bottom: Color, col_top: Color) -> void:
	var base := vertices.size()
	var apex := Vector3(rng.randf_range(-0.08, 0.08), y0 + tier_height, rng.randf_range(-0.08, 0.08))
	var rim_count := segments * 2
	for s in rim_count + 1:
		var a := TAU * float(s % rim_count) / float(rim_count) + rng.randf_range(-0.05, 0.05)
		# Dal uçları: çift/tek köşelerde farklı yarıçap → yıldız biçimli, tırtıklı siluet.
		var r := radius * (1.0 if s % 2 == 0 else 0.7) * rng.randf_range(0.88, 1.08)
		var droop := rng.randf_range(0.3, 0.65) if s % 2 == 0 else -0.05
		var dir := Vector3(cos(a), 0.0, sin(a))
		vertices.append(dir * r + Vector3(0.0, y0 - droop, 0.0))
		normals.append((dir * tier_height + Vector3(0.0, radius * 0.9, 0.0)).normalized())
		colors.append(col_bottom)
	vertices.append(apex)
	normals.append(Vector3.UP)
	colors.append(col_top)
	var apex_index := vertices.size() - 1
	for s in rim_count:
		indices.append_array([base + s, base + s + 1, apex_index])


static func _commit(vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, colors: PackedColorArray, indices: PackedInt32Array) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	if not uvs.is_empty():
		arrays[Mesh.ARRAY_TEX_UV] = uvs
	if not colors.is_empty():
		arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
