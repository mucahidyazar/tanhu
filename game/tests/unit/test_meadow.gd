extends TestCase
## Kamp zemininin saf yardımcıları: çayırın ince çimen tutamları ve çiçek öbekleri (Meadow), engel ızgarası,
## ezik toprak kuralları, halının örtü daireleri (Rug), yurt kapısı önündeki toprak (World) ve yurt dumanı (Fx).
## Sahne kurmadan çalışır; sahnedeki yerleşim test_world_scene.gd'de sınanır.


# --- Çimen tutamları ------------------------------------------------------------------

func test_tuft_mesh_is_a_flat_upright_card() -> void:
	# Shader her tutamı Y ekseni etrafında kameraya döndürür: tutam XY düzleminde ince bir kart olmalı,
	# kökleri yerde, uçları ~1 birim yukarıda. UV.x yaprağın tonu, UV.y kökten uca 0..1'dir.
	for v in Meadow.TUFT_VARIANTS:
		for segments in [1, 2]:
			# (Sahnede ilk LAWN_VARIANTS çeşit tek, kalanlar iki bölütlüdür; model her ikisini de kurabilir.)
			var label := "Tutam %s / %d bölüt" % [v, segments]
			var mesh := Meadow.tuft_mesh(v.x, v.y, float(v.z) / 100.0, segments)
			var arrays := mesh.surface_get_arrays(0)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var per_blade := 3 if segments == 1 else 5
			assert_eq(vertices.size(), v.x * per_blade, "%s: köşe sayısı" % label)
			assert_eq(indices.size(), v.x * (3 if segments == 1 else 9), "%s: üçgen sayısı" % label)
			var aabb := mesh.get_aabb()
			assert_almost(aabb.position.y, 0.0, 0.0001, "%s: kökler yerde olmalı" % label)
			assert_between(aabb.end.y, 0.6, 1.15, "%s: boy ~1 birim olmalı" % label)
			assert_true(aabb.size.z < 0.2 and aabb.size.x > aabb.size.z * 3.0, "%s: XY düzleminde ince bir kart olmalı (%s)" % [label, aabb.size])
			var outside := 0
			for uv in uvs:
				if uv.y < 0.0 or uv.y > 1.0 or uv.x < 0.0 or uv.x > 1.0:
					outside += 1
			assert_eq(outside, 0, "%s: UV 0..1 aralığında olmalı" % label)


func test_short_grass_blades_stay_thin() -> void:
	# Referanstaki çimen ince fırça darbeleridir: yaprak eni (model eni × tutamın yatay ölçeği) tipik olarak
	# 6 cm'nin, en kötü rastgele değerlerle bile 9 cm'nin altında kalmalı (eski iri yapraklar 10–27 cm idi).
	for h in [0.06, 0.1, 0.15, 0.27, 0.32, 0.33, 0.45, 0.6]:
		var tall: bool = h > Meadow.TALL_TUFT
		var blade := Meadow.BLADE_WIDTH.y if tall else Meadow.BLADE_WIDTH.x
		var typical: float = blade * h * Meadow.tuft_aspect(h)
		assert_true(typical < 0.06, "%.2f m tutamda yaprak eni %.3f m: çok kalın" % [h, typical])
		assert_true(typical * 1.2 * 1.15 < 0.09, "%.2f m tutamda en geniş yaprak %.3f m: çok kalın" % [h, typical * 1.38])


func test_tuft_aspect_shrinks_with_height() -> void:
	var prev := INF
	for h in [0.03, 0.06, 0.1, 0.15, 0.25, 0.45, 0.8]:
		var a := Meadow.tuft_aspect(h)
		assert_true(a <= prev + 0.0001, "Uzun tutam daha dar olmalı (boy %.2f)" % h)
		prev = a
	assert_almost(Meadow.tuft_aspect(0.15), Meadow.TUFT_ASPECT.y, 0.0001)
	assert_almost(Meadow.tuft_aspect(0.45), Meadow.TUFT_ASPECT.z, 0.0001)


func test_lawn_tufts_are_small_and_split() -> void:
	# Kısa çayır iri "tarak" öbekleri değil, ince bir doku gibi okunmalı: tutam dar ve az yapraklıdır, her yerleşim
	# noktasına LAWN_SPLIT tane düşer. Yaprakların sıklığı (kök yayılımı / yaprak sayısı) önceki geniş çayır
	# tutamlarınınkiyle (0,95 / 16 ≈ 0,06) aynı kalır: toplam yaprak sayısı, dolayısıyla maliyet değişmez.
	assert_true(Meadow.LAWN_SPLIT >= 2, "Kısa çayır noktası birden çok küçük tutama bölünmeli")
	for i in Meadow.LAWN_VARIANTS:
		var v := Meadow.TUFT_VARIANTS[i]
		var gap := float(v.z) / 100.0 / float(v.x)
		assert_between(gap, 0.045, 0.075, "Çeşit %s: yaprak aralığı (model birimi) değişmemeli" % v)
		var mesh := Meadow.tuft_mesh(v.x, v.y, float(v.z) / 100.0, 1, Meadow.BLADE_WIDTH.x)
		# 15 cm'lik bir tutamın gerçek eni (model eni × yatay ölçek): küçük bir öbek, yarım metrelik tarak değil.
		var width := mesh.get_aabb().size.x * 0.15 * Meadow.tuft_aspect(0.15)
		assert_true(width < 0.45, "Çeşit %s: 15 cm'lik tutam %.2f m eninde, çok geniş" % [v, width])

# --- Ezik toprak kuralları ------------------------------------------------------------

func test_trample_weight_clears_the_fire_and_fades_out() -> void:
	assert_almost(Meadow.trample_weight(0.5, 2.3), 0.0, 0.0001, "Ateşin dibinde çimen yok")
	assert_almost(Meadow.trample_weight(2.3 * 0.55, 2.3), 0.0, 0.0001)
	assert_between(Meadow.trample_weight(1.8, 2.3), 0.05, 0.95)
	assert_almost(Meadow.trample_weight(2.3, 2.3), 1.0, 0.0001, "Yarıçapta tam yoğunluk")
	assert_almost(Meadow.trample_weight(9.0, 2.3), 1.0, 0.0001)


func test_door_weight_keeps_the_steps_bare() -> void:
	var spots: Array[Vector4] = [Vector4(2.0, -1.0, 1.2, 0.8)]
	assert_almost(Meadow.door_weight(Vector2(2.0, -1.0), spots), 0.0, 0.0001, "Basamakların üstünde çimen yok")
	assert_almost(Meadow.door_weight(Vector2(2.6, -1.0), spots), 0.0, 0.0001, "Lekenin yarıçapının yarısına kadar çıplak")
	assert_between(Meadow.door_weight(Vector2(3.0, -1.0), spots), 0.05, 0.95)
	assert_almost(Meadow.door_weight(Vector2(5.0, -1.0), spots), 1.0, 0.0001, "Uzakta etkisiz")
	var none: Array[Vector4] = []
	assert_almost(Meadow.door_weight(Vector2(2.0, -1.0), none), 1.0, 0.0001, "Leke yoksa etkisiz")


# --- Engel ızgarası -------------------------------------------------------------------

func test_circle_grid_gives_the_same_answers_as_all_circles() -> void:
	# Çayır her noktada yalnızca yakındaki engellere bakar; sonuç tüm engellere bakmakla aynı olmalı
	# (BLOCKER_REACH'ten uzak engellerin çimen kurallarına etkisi yoktur).
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var circles: Array[Vector3] = []
	for i in 60:
		circles.append(Vector3(rng.randf_range(-20.0, 20.0), rng.randf_range(-20.0, 20.0), rng.randf_range(0.2, 3.0)))
	var meadow := Meadow.new()
	meadow._index_blockers(circles)
	var mismatches := 0
	for i in 400:
		var p := Vector2(rng.randf_range(-22.0, 22.0), rng.randf_range(-22.0, 22.0))
		var near := meadow.near_blockers(p)
		var full_d := minf(Scatter.distance_to_circles(p.x, p.y, circles), Meadow.BLOCKER_REACH)
		var near_d := minf(Scatter.distance_to_circles(p.x, p.y, near), Meadow.BLOCKER_REACH)
		if Scatter.is_blocked(p.x, p.y, circles, 0.12) != Scatter.is_blocked(p.x, p.y, near, 0.12) or absf(full_d - near_d) > 0.0001:
			mismatches += 1
	meadow.free()
	assert_eq(mismatches, 0, "Izgara yakındaki tüm engelleri vermeli")


# --- Çiçekler ------------------------------------------------------------------------

func test_flower_cluster_has_only_heads() -> void:
	# Saplar çizilmez (menü kamerasından piksel altına düşerler); her çiçek tek bir baş dörtgenidir.
	for count in [1, Meadow.FLOWER_CLUSTER.x, 4]:
		var mesh := Meadow.flower_cluster(count, Meadow.FLOWER_CLUSTER.y, 0.2, 0.065)
		var arrays := mesh.surface_get_arrays(0)
		var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var heads := 0
		var top := 0.0
		for i in colors.size():
			if colors[i].a > 0.5:
				heads += 1
				top = maxf(top, vertices[i].y)
		assert_eq(heads, count * 4, "Öbekte %d çiçek başı (4 köşe) olmalı" % count)
		assert_eq(colors.size(), count * 4, "Her çiçek yalnızca baştır (4 köşe)")
		assert_between(top, 0.12, 0.23, "Başlar sap boyunda olmalı")
		assert_true(mesh.get_aabb().position.y > 0.1, "Başlar havada, çimenin üst hizasında durmalı")
		var aabb := mesh.get_aabb()
		assert_true(aabb.size.x < 0.4 and aabb.size.z < 0.4, "Öbek küçük olmalı (%s)" % aabb.size)


func test_flower_heads_follow_the_grass_height() -> void:
	# Çiçek başları çimenin üst hizasında kalır: kısa çimende kısa, uzun çimende uzun saplı model.
	assert_eq(Meadow.flower_stem_variant(0.08), 0, "Kısa çimende kısa sap")
	assert_eq(Meadow.flower_stem_variant(0.4), 1, "Uzun çimende uzun sap")
	assert_true(Meadow.FLOWER_STEMS[0] < Meadow.FLOWER_STEMS[1])


func test_flower_kinds_are_mostly_white_with_some_yellow() -> void:
	var counts := {Meadow.FLOWER_WHITE: 0, Meadow.FLOWER_YELLOW: 0, Meadow.FLOWER_BLUE: 0}
	for i in 1000:
		var kind := Meadow.flower_kind(float(i) / 1000.0, -0.3)
		counts[kind] += 1
	assert_true(counts[Meadow.FLOWER_WHITE] > 700, "Çiçeklerin çoğu beyaz olmalı (%s)" % counts)
	assert_between(counts[Meadow.FLOWER_YELLOW], 50, 200)
	assert_between(counts[Meadow.FLOWER_BLUE], 30, 120)
	var yellow_patch := 0
	for i in 1000:
		if Meadow.flower_kind(float(i) / 1000.0, 0.6) == Meadow.FLOWER_YELLOW:
			yellow_patch += 1
	assert_true(yellow_patch > 400, "Sarılar kendi lekelerinde öbeklenmeli (%d)" % yellow_patch)


# --- Halı, kapı önü, duman --------------------------------------------------------------

func test_rug_cover_circles_cover_the_rug_tightly() -> void:
	var body := Vector2(2.0, 1.3)
	var fringe := 0.08
	var xform := Transform3D(Basis(Vector3.UP, 0.6), Vector3(1.5, 0.0, -1.0))
	var circles := Rug.cover_circles(xform, body, fringe)
	assert_true(circles.size() >= 4, "Halıyı birkaç daire örtmeli")
	var total := Rug.mesh_size(body, fringe)
	var uncovered := 0
	for ix in 21:
		for iz in 11:
			var local := Vector3((float(ix) / 20.0 - 0.5) * total.x, 0.0, (float(iz) / 10.0 - 0.5) * total.y)
			var p := xform * local
			if not Scatter.is_blocked(p.x, p.z, circles, 0.001):
				uncovered += 1
	assert_eq(uncovered, 0, "Halının her noktası bir dairenin içinde olmalı")
	# Çimen halının kenarına kadar gelsin: daireler uzun kenardan en fazla birkaç santim taşar.
	var beside := xform * Vector3(0.0, 0.0, total.y * 0.5 + 0.12)
	assert_false(Scatter.is_blocked(beside.x, beside.z, circles), "Uzun kenarın 12 cm dışı açık olmalı")


func test_door_spot_lies_in_front_of_the_door() -> void:
	# Kapı yurdun yerel +Z yönüne bakar; leke basamakların üstünde, kapının önündedir.
	var yaw := deg_to_rad(55.1)
	var door := Basis(Vector3.UP, yaw).z
	var spot := World.door_spot(Vector3(-6.18, 0.0, -4.31), door, 2.8)
	var center := Vector2(spot.x, spot.y)
	var dir := Vector2(door.x, door.z).normalized()
	assert_almost(center.distance_to(Vector2(-6.18, -4.31)), 2.8 * World.DOOR_SPOT_DISTANCE, 0.001)
	assert_true((center - Vector2(-6.18, -4.31)).normalized().dot(dir) > 0.999, "Leke kapı yönünde olmalı")
	# Basamaklar kapıdan ~1,03–1,22 × yarıçap ileridedir: hepsi lekenin çıplak (çimensiz) iç kısmında kalmalı.
	var spots: Array[Vector4] = [spot]
	for k in [1.03, 1.12, 1.22]:
		var step: Vector2 = Vector2(-6.18, -4.31) + dir * 2.8 * k
		assert_almost(Meadow.door_weight(step, spots), 0.0, 0.0001, "Basamak (%.2f r) çıplak toprakta olmalı" % k)
	assert_true(World.yurt_door_spots(null).is_empty(), "Ağaç yoksa kapı lekesi yok")


func test_smoke_is_a_thin_stateless_plume() -> void:
	# Duman parçacık değildir (yavaş kareler onu bir topa toplayamaz): tek bir dörtgen, duman shader'ı.
	var smoke: Node3D = Fx.smoke()
	assert_true(smoke is MeshInstance3D, "Duman bir MeshInstance3D olmalı")
	assert_false(smoke is GPUParticles3D, "Duman parçacık olmamalı")
	if not smoke is MeshInstance3D:
		smoke.free()
		return
	var plume := smoke as MeshInstance3D
	var quad := plume.mesh as QuadMesh
	assert_not_null(quad, "Duman bir dörtgen (QuadMesh) olmalı")
	if quad:
		assert_true(quad.size.x < quad.size.y, "Sütun ince ve uzun olmalı (%s)" % quad.size)
		assert_true(quad.size.y > 1.5 and quad.size.y < 4.0, "Duman tacın 1,5–4 m üstüne kadar yükselmeli")
	var mat := plume.material_override as ShaderMaterial
	assert_true(mat != null and mat.shader == Fx.SMOKE_SHADER, "Duman shader'ı kullanılmalı")
	var box := plume.custom_aabb
	assert_true(box.position.y < 0.0 and box.end.y > 1.5, "Kırpma kutusu sütunu kapsamalı (%s)" % box)
	assert_true(box.position.x < -0.5 and box.end.x > 0.5 and box.position.z < -0.5, "Kutu her bakış yönünü kapsamalı")
	smoke.free()
