class_name AtwKit
extends RefCounted
## "After the Wind" görünümü için prosedürel modeller.
##
## - tuft(): kameraya dönük, geniş ve sivri yapraklardan oluşan çimen tutamı. Tutamlar üst üste
##   bindikçe referanstaki "testere dişi" çimen halısı oluşur.
## - loaf_rock(): yuvarlak tepeli, dik duran "somun" kaya (yan yana dizilince sütunlu kaya kümesi olur).
## Tüm fonksiyonlar saf ve tohum (seed) ile tekrarlanabilirdir; testler aynı tohumla aynı modeli bekler.


## Çimen tutamı: yerel XY düzleminde (yüzü +Z'ye bakan) yelpaze gibi açılan yapraklar.
## UV.y = yaprağın kendi yüksekliği içindeki oranı (0 kök, 1 uç); UV.x = yaprağın rastgele tonu (0..1).
## Shader tutamı kameraya döndürür; normaller yukarı bakar (çimenlik tek yüzey gibi aydınlanır).
static func tuft(blades: int = 9, rng_seed: int = 1, width: float = 0.5, height: float = 1.0) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var segs := 3
	for b in blades:
		# Yapraklar tutamın ortasında uzun, kenarlarda kısa ve dışa eğik.
		var k := (float(b) + rng.randf_range(0.15, 0.85)) / float(blades) * 2.0 - 1.0
		var root := Vector3(k * width * 0.42, 0.0, rng.randf_range(-0.04, 0.04))
		var h := height * lerpf(1.0, 0.55, absf(k)) * rng.randf_range(0.75, 1.1)
		var lean := Vector3(k * h * rng.randf_range(0.15, 0.4) + rng.randf_range(-0.08, 0.08), 0.0, rng.randf_range(-0.05, 0.05) * h)
		var w := width * rng.randf_range(0.16, 0.24)
		var tone := rng.randf()
		var base := vertices.size()
		for s in segs + 1:
			var t := float(s) / float(segs)
			var half := w * 0.5 * pow(1.0 - t, 0.85)
			# Yaprak hafifçe kavislenir: eğim yukarıda artar.
			var center := root + lean * (t * t) + Vector3(0.0, h * t, 0.0)
			vertices.append(center - Vector3(half, 0.0, 0.0))
			vertices.append(center + Vector3(half, 0.0, 0.0))
			normals.append(Vector3.UP)
			normals.append(Vector3.UP)
			uvs.append(Vector2(tone, t))
			uvs.append(Vector2(tone, t))
		for s in segs:
			var i0 := base + s * 2
			indices.append_array([i0, i0 + 1, i0 + 2, i0 + 1, i0 + 3, i0 + 2])
	return _commit(vertices, normals, uvs, indices)


## Somun kaya: dik duran, tepesi yuvarlak, tabanı hafif genişleyen yumuşak sütun.
## Yükseklik 1, genişlik ~0.9 birimdir (sahnede ölçeklenir). Yüzeyde yumuşak gürültü vardır.
## dome: yüksekliğin ne kadarının yuvarlak tepe olduğu (0.2 düz tepeli blok, 0.6 yumurta).
## squareness: kesitin köşeliliği (2 = daire, 4 = yuvarlatılmış kare; sütun blokları için).
## COLOR yok; UV.y = 0 taban, 1 tepe.
static func loaf_rock(rng_seed: int = 1, dome: float = 0.45, squareness: float = 2.0, bumpiness: float = 0.06, rings: int = 14, sides: int = 22) -> ArrayMesh:
	var noise := FastNoiseLite.new()
	noise.seed = rng_seed
	noise.frequency = 1.6
	noise.fractal_octaves = 3
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var squash := rng.randf_range(0.78, 1.0)  # Kesitin bir yönde basıklığı.
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for r in rings + 1:
		var t := float(r) / float(rings)
		var y := t
		var radius := loaf_profile(t, dome) * 0.45
		for s in sides:
			var a := TAU * float(s) / float(sides)
			var dir := Vector3(cos(a), 0.0, sin(a) * squash) * superellipse_radius(a, squareness)
			var p := Vector3(dir.x * radius, y, dir.z * radius)
			var n := noise.get_noise_3d(p.x * 2.0, p.y * 2.0, p.z * 2.0)
			p += dir * n * bumpiness * (0.3 + radius * 2.0)
			vertices.append(p)
			uvs.append(Vector2(float(s) / float(sides), t))
	# Tepe noktası.
	var top := vertices.size()
	vertices.append(Vector3(0.0, 1.0, 0.0))
	uvs.append(Vector2(0.5, 1.0))
	for r in rings:
		for s in sides:
			var a := r * sides + s
			var b := r * sides + (s + 1) % sides
			var c := (r + 1) * sides + s
			var d := (r + 1) * sides + (s + 1) % sides
			# Godot'da ön yüz saat yönündedir (dışarıdan bakınca).
			indices.append_array([a, b, c, b, d, c])
	for s in sides:
		indices.append_array([rings * sides + s, rings * sides + (s + 1) % sides, top])
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in vertices.size():
		st.set_uv(uvs[i])
		st.add_vertex(vertices[i])
	for i in indices:
		st.add_index(i)
	st.generate_normals()
	return st.commit()


## Somun kayanın yüksekliğe göre yarıçap oranı (0 taban, 1 tepe; saf fonksiyon).
## Altta hafif genişler, gövde dik iner, son "dome" kadarlık kısımda yarım küre gibi kapanır.
static func loaf_profile(t: float, dome: float = 0.45) -> float:
	var foot := 1.0 + 0.12 * (1.0 - smoothstep(0.0, 0.18, t))
	var d := clampf(dome, 0.05, 1.0)
	var cap := sqrt(maxf(0.0, 1.0 - pow(maxf(0.0, (t - (1.0 - d)) / d), 2.0)))
	return foot * cap


## Süper elips kesitinde a açısındaki yarıçap oranı (n = 2 daire, n büyüdükçe kareye yaklaşır).
static func superellipse_radius(a: float, n: float) -> float:
	var c := pow(absf(cos(a)), n)
	var s := pow(absf(sin(a)), n)
	return pow(maxf(c + s, 1e-6), -1.0 / n)


static func _commit(vertices: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array, indices: PackedInt32Array) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
