extends TestCase
## MeshKit (prosedürel mesh üreticileri) ve AtwKit (çayırın "After the Wind" çimen tutamı) testleri.
##
## Godot'da bir üçgenin ön yüzü, yüzeye dışarıdan bakınca saat yönünde sıralanan yüzdür; buna göre
## dışa bakan normal cross(c - a, b - a) olur. Ters sıralı üçgen oyunda görünmez olur (arka yüz
## kırpılır); bu yüzden sıralama testleri önemlidir. (Çimen tutamları iki yüzlü çizildiği için
## onlarda sıralama değil biçim sınanır.)
## Mesh dizileri _arrays() ile okunur: mesh boşsa ya da testin okuyacağı bir dizi (UV, renk...)
## eksikse test önce başarısız sayılır, sonra durur.

## Mesh dizilerinin (Mesh.ARRAY_*) beklenen türleri ve hata iletilerindeki adları.
const ATTRIBUTE_TYPES := {
	Mesh.ARRAY_VERTEX: TYPE_PACKED_VECTOR3_ARRAY,
	Mesh.ARRAY_NORMAL: TYPE_PACKED_VECTOR3_ARRAY,
	Mesh.ARRAY_TEX_UV: TYPE_PACKED_VECTOR2_ARRAY,
	Mesh.ARRAY_COLOR: TYPE_PACKED_COLOR_ARRAY,
	Mesh.ARRAY_INDEX: TYPE_PACKED_INT32_ARRAY,
}
const ATTRIBUTE_NAMES := {
	Mesh.ARRAY_VERTEX: "köşe",
	Mesh.ARRAY_NORMAL: "normal",
	Mesh.ARRAY_TEX_UV: "UV",
	Mesh.ARRAY_COLOR: "renk",
	Mesh.ARRAY_INDEX: "indeks",
}
## Her meshte bulunması gereken diziler; UV ya da renk okuyan testler onları da ister.
const BASIC_ARRAYS: Array[int] = [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_INDEX]
const WITH_UV: Array[int] = [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_TEX_UV, Mesh.ARRAY_INDEX]
const WITH_COLOR: Array[int] = [Mesh.ARRAY_VERTEX, Mesh.ARRAY_NORMAL, Mesh.ARRAY_COLOR, Mesh.ARRAY_INDEX]

## Oyundaki sabit kaya ayarları: Vector3(tohum, alt_bölüm, pürüz). Serpiştirilmiş kayalar
## (rock_field.gd) ve patika çakılları (path_network.gd). Ateş taşları ve kahraman kayalar _game_rocks()'ta.
const FIXED_GAME_ROCKS: Array[Vector3] = [
	Vector3(301.0, 2.0, 0.35), Vector3(302.0, 2.0, 0.3), Vector3(303.0, 2.0, 0.4),
	Vector3(911.0, 1.0, 0.3), Vector3(912.0, 1.0, 0.4), Vector3(913.0, 1.0, 0.35),
]
## Kamp ateşinin taş halkasındaki taş sayısı (campfire.gd: tohum 100 + i).
const FIRE_STONES := 11


# --- İkosfer ------------------------------------------------------------------------

func test_icosphere_vertex_and_face_counts_per_subdivision() -> void:
	# Her alt bölüm yüz sayısını 4 katına çıkarır: V = 10·4ⁿ + 2, F = 20·4ⁿ.
	for n in 4:
		var data := MeshKit.icosphere_data(n)
		var vertices: PackedVector3Array = data[0]
		var indices: PackedInt32Array = data[1]
		var factor := 1 << (2 * n)
		assert_eq(vertices.size(), 10 * factor + 2, "Alt bölüm %d köşe sayısı" % n)
		assert_eq(indices.size(), 20 * factor * 3, "Alt bölüm %d üçgen sayısı" % n)


func test_icosphere_faces_wind_outward() -> void:
	for n in 4:
		var data := MeshKit.icosphere_data(n)
		var vertices: PackedVector3Array = data[0]
		var indices: PackedInt32Array = data[1]
		var inward := 0
		for i in range(0, indices.size(), 3):
			var a := vertices[indices[i]]
			var b := vertices[indices[i + 1]]
			var c := vertices[indices[i + 2]]
			# Dış normal, üçgenin merkezinden (küre merkezinden) dışarı doğru olmalı.
			if (c - a).cross(b - a).dot(a + b + c) <= 0.0:
				inward += 1
		assert_eq(inward, 0, "Alt bölüm %d: içe bakan üçgen sayısı" % n)


func test_icosphere_vertices_lie_on_unit_sphere() -> void:
	var vertices: PackedVector3Array = MeshKit.icosphere_data(3)[0]
	var worst := 0.0
	for v in vertices:
		worst = maxf(worst, absf(v.length() - 1.0))
	assert_true(worst < 0.00001, "Köşe birim küreden sapıyor (%f)" % worst)


func test_icosphere_is_closed_and_consistently_wound() -> void:
	# Kapalı ve tutarlı yüzey: her yönlü kenar (a→b) tam bir kez geçer, tersi (b→a) de komşu üçgende bulunur.
	for n in 3:
		var data := MeshKit.icosphere_data(n)
		var vertices: PackedVector3Array = data[0]
		var indices: PackedInt32Array = data[1]
		var directed := {}
		var out_of_range := 0
		for i in range(0, indices.size(), 3):
			for k in 3:
				var a := indices[i + k]
				var b := indices[i + (k + 1) % 3]
				if a < 0 or a >= vertices.size():
					out_of_range += 1
				var edge := Vector2i(a, b)
				directed[edge] = int(directed.get(edge, 0)) + 1
		var broken := 0
		for edge in directed:
			var e: Vector2i = edge
			if directed[edge] != 1 or not directed.has(Vector2i(e.y, e.x)):
				broken += 1
		assert_eq(out_of_range, 0, "Alt bölüm %d: geçersiz indeks" % n)
		assert_eq(broken, 0, "Alt bölüm %d: delik ya da ters sıralı komşu kenar" % n)


func test_smooth_normals_on_sphere_point_outward() -> void:
	var data := MeshKit.icosphere_data(2)
	var vertices: PackedVector3Array = data[0]
	var normals := MeshKit.smooth_normals(vertices, data[1])
	assert_eq(normals.size(), vertices.size())
	var worst := 1.0
	for i in vertices.size():
		worst = minf(worst, normals[i].dot(vertices[i]))
	assert_true(worst > 0.99, "Küre normali köşe yönünden sapıyor (en kötü nokta çarpımı %f)" % worst)


# --- Lathe ve disk ------------------------------------------------------------------

func test_lathe_vertex_and_index_counts() -> void:
	var profile := PackedVector2Array([Vector2(1.0, 0.0), Vector2(1.0, 1.0), Vector2(0.5, 1.5)])
	var mesh := MeshKit.lathe(profile, 12)
	_assert_valid_triangles(mesh, "Lathe")
	var arrays := _arrays(mesh, "Lathe", WITH_UV)
	if arrays.is_empty():
		return
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	assert_eq(vertices.size(), (12 + 1) * profile.size(), "(bölüt + 1) × profil noktası (dikiş köşeleri ikilenir)")
	assert_eq(indices.size(), 12 * (profile.size() - 1) * 6, "Her bölüt × profil aralığı için iki üçgen")
	assert_eq((arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array).size(), vertices.size())
	assert_eq((arrays[Mesh.ARRAY_TEX_UV] as PackedVector2Array).size(), vertices.size())


func test_lathe_faces_and_normals_point_away_from_axis() -> void:
	var profile := PackedVector2Array([Vector2(1.0, 0.0), Vector2(1.05, 0.5), Vector2(1.0, 1.0)])
	var arrays := _arrays(MeshKit.lathe(profile, 16), "Lathe")
	if arrays.is_empty():
		return
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var inward_faces := 0
	for i in range(0, indices.size(), 3):
		var a := vertices[indices[i]]
		var b := vertices[indices[i + 1]]
		var c := vertices[indices[i + 2]]
		var centroid := (a + b + c) / 3.0
		if (c - a).cross(b - a).dot(Vector3(centroid.x, 0.0, centroid.z)) <= 0.0:
			inward_faces += 1
	assert_eq(inward_faces, 0, "Silindir duvarında içe bakan üçgen var")
	var bad_normals := 0
	for i in vertices.size():
		var radial := Vector3(vertices[i].x, 0.0, vertices[i].z)
		if absf(normals[i].length() - 1.0) > 0.001 or normals[i].dot(radial) <= 0.0:
			bad_normals += 1
	assert_eq(bad_normals, 0, "Normal birim değil ya da eksene doğru bakıyor")


func test_lathe_full_turn_closes_the_seam() -> void:
	var profile := PackedVector2Array([Vector2(2.0, 0.0), Vector2(1.5, 1.0)])
	var segments := 10
	var arrays := _arrays(MeshKit.lathe(profile, segments), "Lathe")
	if arrays.is_empty():
		return
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	assert_eq(vertices.size(), (segments + 1) * profile.size(), "Dikiş halkası ikilenmeli")
	if vertices.size() != (segments + 1) * profile.size():
		return
	for i in profile.size():
		assert_vec_almost(vertices[i], vertices[segments * profile.size() + i], 0.0001, "İlk ve son halka çakışmalı (dikiş)")


func test_lathe_partial_arc_leaves_an_opening() -> void:
	# Yurt duvarı kapı için bu açıklığı kullanır: 0 rad çevresinde ±0,5 rad boşluk kalmalı.
	var profile := PackedVector2Array([Vector2(3.0, 0.0), Vector2(3.0, 1.7)])
	var arrays := _arrays(MeshKit.lathe(profile, 24, 1.0, 0.5, TAU - 0.5), "Kısmi lathe")
	if arrays.is_empty():
		return
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	assert_eq(vertices.size(), (24 + 1) * profile.size())
	var inside_opening := 0
	for v in vertices:
		if absf(atan2(v.z, v.x)) < 0.5 - 0.0001:
			inside_opening += 1
	assert_eq(inside_opening, 0, "Açıklığın içine köşe düşmemeli")


func test_lathe_uvs_span_profile_and_circumference() -> void:
	var profile := PackedVector2Array([Vector2(1.0, 0.0), Vector2(1.0, 2.0), Vector2(0.2, 3.0)])
	var arrays := _arrays(MeshKit.lathe(profile, 8, 3.0), "Lathe", WITH_UV)
	if arrays.is_empty():
		return
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for uv in uvs:
		low = Vector2(minf(low.x, uv.x), minf(low.y, uv.y))
		high = Vector2(maxf(high.x, uv.x), maxf(high.y, uv.y))
	assert_vec_almost(Vector3(low.x, low.y, 0.0), Vector3.ZERO, 0.0001, "UV alt sınırı (0, 0)")
	assert_vec_almost(Vector3(high.x, high.y, 0.0), Vector3(3.0, 1.0, 0.0), 0.0001, "u = uv_repeat'e, v = 1'e kadar gitmeli")


func test_disc_faces_up_or_down() -> void:
	for facing_up in [true, false]:
		var arrays := _arrays(MeshKit.disc(1.5, 0.25, 12, facing_up), "Disk")
		if arrays.is_empty():
			return
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var expected := Vector3.UP if facing_up else Vector3.DOWN
		assert_eq(vertices.size(), 12 + 1, "Merkez + kenar köşeleri")
		var wrong := 0
		for i in range(0, indices.size(), 3):
			var a := vertices[indices[i]]
			if (vertices[indices[i + 2]] - a).cross(vertices[indices[i + 1]] - a).dot(expected) <= 0.0:
				wrong += 1
		for i in vertices.size():
			# Godot normalleri sıkıştırarak (oktahedral) saklar; bu yüzden küçük bir tolerans kullanılır.
			if not is_equal_approx(vertices[i].y, 0.25) or normals[i].distance_to(expected) > 0.001:
				wrong += 1
		assert_eq(wrong, 0, "Disk (yukarı = %s) yanlış yöne bakıyor" % facing_up)


# --- Kaya ---------------------------------------------------------------------------

func test_rock_sits_on_the_ground() -> void:
	# Kaya tabanı y = 0'ın birkaç santim altına gömülür: arazide asla havada durmaz.
	# Oyundaki her kaya ayarı denenir: ateş taşları, kahraman kayalar, serpiştirilmiş kayalar, çakıllar.
	for r in _game_rocks():
		var aabb := MeshKit.rock(int(r.x), int(r.y), r.z).get_aabb()
		assert_between(aabb.position.y, -0.1, 0.0, "Kaya %d tabanı y≈0'da olmalı" % int(r.x))
		assert_between(aabb.size.y, 0.5, 2.0, "Kaya %d yüksekliği ~1 birim olmalı" % int(r.x))
		assert_between(aabb.size.x, 1.2, 3.5, "Kaya %d genişliği ~2 birim olmalı" % int(r.x))
		assert_between(aabb.size.z, 1.2, 3.5, "Kaya %d derinliği ~2 birim olmalı" % int(r.x))


func test_rock_normals_point_away_from_its_center() -> void:
	for r in _game_rocks():
		var mesh := MeshKit.rock(int(r.x), int(r.y), r.z)
		var center := mesh.get_aabb().get_center()
		var arrays := _arrays(mesh, "Kaya %d" % int(r.x))
		if arrays.is_empty():
			continue
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var outward := 0
		var not_unit := 0
		for i in vertices.size():
			if normals[i].dot(vertices[i] - center) > 0.0:
				outward += 1
			if absf(normals[i].length() - 1.0) > 0.001:
				not_unit += 1
		assert_eq(not_unit, 0, "Kaya %d: birim olmayan normal" % int(r.x))
		assert_true(float(outward) / vertices.size() > 0.99, "Kaya %d: normallerin çoğu dışa bakmalı (%d/%d)" % [int(r.x), outward, vertices.size()])


func test_rock_is_repeatable_and_seed_dependent() -> void:
	var a := _vertices(MeshKit.rock(42), "Kaya 42")
	var b := _vertices(MeshKit.rock(42), "Kaya 42 (tekrar)")
	var c := _vertices(MeshKit.rock(43), "Kaya 43")
	assert_false(a.is_empty(), "Kaya köşesi yok")
	assert_true(a == b, "Aynı tohum aynı kayayı vermeli")
	assert_false(a == c, "Farklı tohum farklı kaya vermeli")


# --- Bitki örtüsü ve kumaş ----------------------------------------------------------

func test_grass_clump_is_a_non_empty_tuft() -> void:
	var mesh := MeshKit.grass_clump(7, 9)
	_assert_valid_triangles(mesh, "Çimen")
	var arrays := _arrays(mesh, "Çimen", WITH_UV)
	if arrays.is_empty():
		return
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	assert_true(vertices.size() > 0, "Çimen kümesi boş")
	assert_eq(uvs.size(), vertices.size())
	var aabb := mesh.get_aabb()
	assert_almost(aabb.position.y, 0.0, 0.0001, "Yapraklar yerden başlamalı")
	assert_between(aabb.end.y, 0.5, 1.0, "Çimen boyu ~1 birim olmalı")
	var uv_outside := 0
	for uv in uvs:
		if uv.y < 0.0 or uv.y > 1.0:
			uv_outside += 1
	assert_eq(uv_outside, 0, "UV.y yaprak boyunca 0..1 olmalı")
	var double := _vertices(MeshKit.grass_clump(14, 9), "Çimen (14 yaprak)")
	assert_eq(double.size(), vertices.size() * 2, "Köşe sayısı yaprak sayısıyla doğru orantılı olmalı")


func test_meadow_tufts_are_flat_upright_cards() -> void:
	# AtwKit.tuft kalın yapraklı AtW tutamıdır (geliştirme sahneleri kullanır; çayır artık aynı kart düzeninde
	# ince yapraklı Meadow.tuft_mesh kurar, bkz. test_meadow.gd). Burada çayırın tutam ölçüleriyle
	# (Meadow.TUFT_VARIANTS) sınanır. Shader her tutamı Y ekseni etrafında kameraya döndürür; bu yüzden tutam
	# XY düzleminde ince bir kart olmalı (yoksa yandan çizgi gibi görünür), kökleri yerde, uçları ~1 birim
	# yukarıda. UV.x yaprağın tonu, UV.y kökten uca 0..1'dir.
	for v in Meadow.TUFT_VARIANTS:
		var label := "Tutam %s" % v
		var mesh := AtwKit.tuft(v.x, v.y, float(v.z) / 100.0)
		_assert_valid_triangles(mesh, label)
		var arrays := _arrays(mesh, label, WITH_UV)
		if arrays.is_empty():
			continue
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		assert_eq(vertices.size(), v.x * 8, "%s: her yaprak 4 sıra × 2 köşe" % label)
		assert_eq((arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size(), v.x * 18, "%s: her yaprak 3 bölüt × 2 üçgen" % label)
		var aabb := mesh.get_aabb()
		assert_almost(aabb.position.y, 0.0, 0.0001, "%s: kökler yerde olmalı" % label)
		assert_between(aabb.end.y, 0.6, 1.15, "%s: boy ~1 birim olmalı" % label)
		assert_true(aabb.size.z < 0.2 and aabb.size.x > aabb.size.z * 3.0, "%s: XY düzleminde ince bir kart olmalı (boyut %s)" % [label, aabb.size])
		var low := Vector2(INF, INF)
		var high := Vector2(-INF, -INF)
		for uv in uvs:
			low = Vector2(minf(low.x, uv.x), minf(low.y, uv.y))
			high = Vector2(maxf(high.x, uv.x), maxf(high.y, uv.y))
		assert_true(low.x >= 0.0 and high.x <= 1.0, "%s: UV.x (ton) 0..1 olmalı" % label)
		assert_almost(low.y, 0.0, 0.0001, "%s: UV.y kökte 0 olmalı" % label)
		assert_almost(high.y, 1.0, 0.0001, "%s: UV.y uçta 1 olmalı" % label)


func test_meadow_tuft_is_repeatable_and_seed_dependent() -> void:
	# AtwKit sözü: aynı tohum aynı tutamı verir (çayır her açılışta aynı görünür).
	var a := _vertices(AtwKit.tuft(11, 5, 0.75), "Tutam")
	var b := _vertices(AtwKit.tuft(11, 5, 0.75), "Tutam (tekrar)")
	var c := _vertices(AtwKit.tuft(11, 6, 0.75), "Tutam (başka tohum)")
	assert_false(a.is_empty(), "Tutam köşesi yok")
	assert_true(a == b, "Aynı tohum aynı tutamı vermeli")
	assert_false(a == c, "Farklı tohum farklı tutam vermeli")


func test_flower_has_stem_and_head() -> void:
	var mesh := MeshKit.flower(0.3, 0.13)
	_assert_valid_triangles(mesh, "Çiçek")
	var arrays := _arrays(mesh, "Çiçek", WITH_COLOR)
	if arrays.is_empty():
		return
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var stem := 0
	var head := 0
	for c in colors:
		if c.a == 0.0:
			stem += 1
		elif c.a == 1.0:
			head += 1
	assert_true(stem > 0, "Sap köşesi yok (COLOR.a = 0)")
	assert_true(head > 0, "Çiçek kafası köşesi yok (COLOR.a = 1)")
	assert_eq(stem + head, colors.size())
	var aabb := mesh.get_aabb()
	assert_almost(aabb.position.y, 0.0, 0.0001, "Sap yerden başlamalı")
	assert_between(aabb.end.y, 0.3, 0.4, "Kafa sapın ucunda olmalı")


func test_cloth_grid_hangs_down_and_faces_forward() -> void:
	var cols := 4
	var rows := 8
	var mesh := MeshKit.cloth(0.62, 1.0, cols, rows)
	_assert_valid_triangles(mesh, "Kumaş")
	var arrays := _arrays(mesh, "Kumaş")
	if arrays.is_empty():
		return
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	assert_eq(vertices.size(), (cols + 1) * (rows + 1))
	assert_eq(indices.size(), cols * rows * 6)
	var aabb := mesh.get_aabb()
	assert_almost(aabb.end.y, 0.0, 0.0001, "Üst kenar y = 0'da")
	assert_almost(aabb.position.y, -1.0, 0.0001, "Alt kenar -yükseklik'te")
	assert_almost(aabb.size.x, 0.62, 0.0001, "Genişlik")
	var backwards := 0
	for i in range(0, indices.size(), 3):
		var a := vertices[indices[i]]
		if (vertices[indices[i + 2]] - a).cross(vertices[indices[i + 1]] - a).z <= 0.0:
			backwards += 1
	for n in normals:
		if n.distance_to(Vector3.BACK) > 0.001:
			backwards += 1
	assert_eq(backwards, 0, "Kumaşın ön yüzü ve normali +Z'ye bakmalı")


func test_conifer_has_trunk_and_foliage() -> void:
	var mesh := MeshKit.conifer(11, 6, 11)
	_assert_valid_triangles(mesh, "Çam")
	var arrays := _arrays(mesh, "Çam", WITH_COLOR)
	if arrays.is_empty():
		return
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var trunk := 0
	var foliage := 0
	for c in colors:
		if c.a == 0.0:
			trunk += 1
		elif c.a == 1.0:
			foliage += 1
	assert_true(trunk > 0, "Gövde köşesi yok")
	assert_true(foliage > trunk, "Yapraklı katlar gövdeden büyük olmalı")
	var aabb := mesh.get_aabb()
	assert_almost(aabb.position.y, 0.0, 0.0001, "Ağaç yerden başlamalı")
	assert_between(aabb.end.y, 8.5, 11.5, "Ağaç boyu ~10 birim olmalı")
	var again := _vertices(MeshKit.conifer(11, 6, 11), "Çam (tekrar)")
	assert_true(again == (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array), "Aynı tohum aynı ağacı vermeli")


# --- Yardımcılar ---------------------------------------------------------------------

## Oyunda kullanılan tüm kaya ayarları: Vector3(tohum, alt_bölüm, pürüz).
## Ateş taşları 100 + i (campfire.gd), kahraman kayalar 200 + i (rock_field.gd; hero_rocks kadar),
## serpiştirilmiş kayalar ve patika çakılları FIXED_GAME_ROCKS'ta.
static func _game_rocks() -> Array[Vector3]:
	var rocks: Array[Vector3] = []
	for i in FIRE_STONES:
		rocks.append(Vector3(100.0 + float(i), 2.0, 0.3))
	var field := RockField.new()
	for i in field.hero_rocks.size():
		rocks.append(Vector3(200.0 + float(i), 3.0, 0.3))
	field.free()
	rocks.append_array(FIXED_GAME_ROCKS)
	return rocks


## Mesh'in ilk yüzeyinin dizileri. Yüzey yoksa ya da istenen dizilerden (required) biri eksikse
## testi başarısız sayar ve boş dizi döndürür; çağıran test o zaman hemen return etmelidir.
## Denetim okumadan ÖNCE yapılır: eksik bir diziyi tipli bir değişkene atamak betik hatasıdır,
## Godot testi yarıda keser ve koşucu onu "geçti" gösterirdi.
func _arrays(mesh: Mesh, label: String, required: Array[int] = BASIC_ARRAYS) -> Array:
	if mesh == null or mesh.get_surface_count() == 0:
		fail("%s: mesh boş (yüzey yok)" % label)
		return []
	var arrays := mesh.surface_get_arrays(0)
	var missing := PackedStringArray()
	for slot in required:
		if typeof(arrays[slot]) != ATTRIBUTE_TYPES[slot]:
			missing.append(ATTRIBUTE_NAMES[slot])
	if not missing.is_empty():
		fail("%s: mesh dizisi eksik: %s" % [label, ", ".join(missing)])
		return []
	return arrays


## Mesh'in köşe konumları (yüzey ya da köşe dizisi yoksa boş).
func _vertices(mesh: Mesh, label: String) -> PackedVector3Array:
	var arrays := _arrays(mesh, label, [Mesh.ARRAY_VERTEX])
	return PackedVector3Array() if arrays.is_empty() else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array)


## Mesh tek yüzeyli bir üçgen listesi mi, indeksler geçerli mi?
func _assert_valid_triangles(mesh: ArrayMesh, label: String) -> void:
	assert_eq(mesh.get_surface_count(), 1, "%s: tek yüzey olmalı" % label)
	var arrays := _arrays(mesh, label)
	if arrays.is_empty():
		return
	assert_eq(mesh.surface_get_primitive_type(0), Mesh.PRIMITIVE_TRIANGLES, "%s: üçgen listesi olmalı" % label)
	var count := (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	assert_true(indices.size() > 0 and indices.size() % 3 == 0, "%s: indeks sayısı 3'ün katı olmalı" % label)
	var invalid := 0
	for i in indices:
		if i < 0 or i >= count:
			invalid += 1
	assert_eq(invalid, 0, "%s: geçersiz indeks" % label)
	assert_eq((arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array).size(), count, "%s: her köşenin normali olmalı" % label)
