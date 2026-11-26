extends TestCase
## Kamp ateşi testleri: ışığın titreme fonksiyonu (Campfire.flicker) ve ateş düğümünün kurulumu
## (taş halkası Meshy modeliyle; modelsiz yedek görünüm test_meshy_prop.gd'de sınanır).
##
## Titreme yumuşak ve sınırlı olmalı: ışık "nefes alır" ama asla sönmez, patlamaz ya da
## çakar gibi sıçramaz (yumuşak, sıcak atmosfer için önemli).

const LOW := 0.72
const HIGH := 1.18
## Oyundaki kare süresi (60 FPS).
const FRAME := 1.0 / 60.0
## Ateşin görünen parçaları (taşlar, alevler) engel dairesinden en fazla bu kadar taşabilir (metre).
const OBSTACLE_SLACK := 0.05
## Engel dairesi ateşin kendisinden en fazla bu kadar büyük olabilir: oyuncu ateşe yaklaşabilmeli.
const OBSTACLE_MAX_MARGIN := 0.5


# --- flicker ------------------------------------------------------------------------

func test_flicker_stays_within_bounds() -> void:
	var lowest := INF
	var highest := -INF
	for seed_index in 5:
		var flicker_seed := float(seed_index) * 13.7
		for i in 6000:
			var f := Campfire.flicker(float(i) * 0.0173, flicker_seed)
			lowest = minf(lowest, f)
			highest = maxf(highest, f)
	assert_true(lowest >= LOW, "Işık çok kısılıyor: %f" % lowest)
	assert_true(highest <= HIGH, "Işık çok parlıyor: %f" % highest)


func test_flicker_stays_within_bounds_for_unusual_times() -> void:
	# Uzun oturumlar (saatler), negatif zaman ve büyük tohumlar da sınırı aşmamalı.
	for t in [-1000.0, -0.5, 0.0, 3600.0, 86400.0, 1.0e6]:
		for flicker_seed in [0.0, 369.63, 1.0e4]:
			assert_between(Campfire.flicker(t, flicker_seed), LOW, HIGH, "t = %s, tohum = %s" % [t, flicker_seed])


func test_flicker_is_deterministic() -> void:
	for i in 300:
		var t := float(i) * 0.37
		assert_eq(Campfire.flicker(t, 2.5), Campfire.flicker(t, 2.5), "Aynı girdi aynı sonucu vermeli (t = %f)" % t)


func test_flicker_breathes_around_a_warm_average() -> void:
	var lowest := INF
	var highest := -INF
	var total := 0.0
	var samples := 6000
	for i in samples:
		var f := Campfire.flicker(float(i) * FRAME)
		lowest = minf(lowest, f)
		highest = maxf(highest, f)
		total += f
	assert_true(highest - lowest > 0.15, "Ateş canlı görünmeli: titreme aralığı çok dar (%f)" % (highest - lowest))
	assert_between(total / samples, 0.92, 1.0, "Ortalama parlaklık ~0,96 olmalı")


func test_flicker_changes_gently_between_frames() -> void:
	# 60 FPS'te bir kareden diğerine en fazla %6'lık değişim: göz yoran çakma olmamalı.
	var biggest_jump := 0.0
	var previous := Campfire.flicker(0.0)
	for i in range(1, 6000):
		var f := Campfire.flicker(float(i) * FRAME)
		biggest_jump = maxf(biggest_jump, absf(f - previous))
		previous = f
	assert_true(biggest_jump < 0.06, "Kareler arası sıçrama çok büyük: %f" % biggest_jump)


func test_seed_shifts_the_phase() -> void:
	# Farklı tohumlu iki ateş aynı anda titrememeli (sahnedeki her ateş kendi ritminde).
	var total_difference := 0.0
	for i in 600:
		var t := float(i) * FRAME
		total_difference += absf(Campfire.flicker(t, 0.0) - Campfire.flicker(t, 5.3))
	assert_true(total_difference / 600.0 > 0.01, "Tohum titremeyi değiştirmiyor")


# --- Ateş düğümü --------------------------------------------------------------------

func test_campfire_builds_light_embers_and_obstacle() -> void:
	var fire := Campfire.new()
	fire.position = Vector3(2.0, 0.0, -3.0)
	add_child(fire)
	await wait_frames(3)
	var light := fire.get_node_or_null(^"FireLight") as OmniLight3D
	assert_not_null(light, "FireLight ışığı kurulmalı")
	if light:
		assert_between(light.light_energy, fire.light_energy * LOW, fire.light_energy * HIGH, "Işık enerjisi titreme sınırında olmalı")
		assert_eq(light.light_color, fire.light_color)
	assert_true(fire.get_node_or_null(^"Embers") is GPUParticles3D, "Kıvılcım parçacıkları kurulmalı")
	assert_true(fire.is_in_group(World.OBSTACLE_GROUP), "Ateş serbest gezintide engel olmalı")
	var circles := fire.get_obstacle_circles()
	assert_eq(circles.size(), 1)
	if circles.size() == 1:
		assert_almost(circles[0].x, 2.0, 0.0001, "Engel dairesi ateşin konumunda olmalı (x)")
		assert_almost(circles[0].y, -3.0, 0.0001, "Engel dairesi ateşin konumunda olmalı (z)")
	await _free_and_settle(fire)


func test_obstacle_circle_covers_the_whole_fire() -> void:
	# Oyuncu taş halkanın ya da alevlerin içine yürüyememeli; ama ateşin başına kadar gelebilmeli.
	# (Ateşin görünüşü değişse de bu söz geçerli kalır: yarıçap parçalara göre ölçülür.)
	var fire := Campfire.new()
	add_child(fire)
	await wait_frames(1)
	var circles := fire.get_obstacle_circles()
	var reach := _part_reach(fire)
	assert_true(reach > 0.3, "Ateşin taşları ve alevleri kurulmalı (en uzak parça %.2f m)" % reach)
	if circles.size() == 1:
		var radius := circles[0].z
		assert_true(radius + OBSTACLE_SLACK >= reach, "Engel dairesi (%.2f m) ateşin en uzak parçasını (%.2f m) örtmeli" % [radius, reach])
		assert_true(radius <= reach + OBSTACLE_MAX_MARGIN, "Engel dairesi (%.2f m) ateşten (%.2f m) çok büyük: oyuncu ateşe yaklaşamaz" % [radius, reach])
	else:
		fail("Ateşin tek bir engel dairesi olmalı (%d)" % circles.size())
	await _free_and_settle(fire)


func test_fire_light_flickers_in_the_scene() -> void:
	# flicker() doğru olsa da ışığa uygulanmazsa ateş donuk görünür: enerji zamanla değişmeli.
	var fire := Campfire.new()
	add_child(fire)
	await wait_frames(1)
	var light := fire.get_node_or_null(^"FireLight") as OmniLight3D
	assert_not_null(light, "FireLight ışığı kurulmalı")
	if light:
		var lowest := INF
		var highest := -INF
		for i in 6:
			await get_tree().create_timer(0.08).timeout
			lowest = minf(lowest, light.light_energy)
			highest = maxf(highest, light.light_energy)
		assert_true(highest - lowest > 0.01, "Ateş ışığı titremiyor (enerji %.3f – %.3f)" % [lowest, highest])
		assert_between(lowest, fire.light_energy * LOW, fire.light_energy * HIGH, "En düşük ışık enerjisi")
		assert_between(highest, fire.light_energy * LOW, fire.light_energy * HIGH, "En yüksek ışık enerjisi")
	await _free_and_settle(fire)


func test_rebuild_does_not_duplicate_parts() -> void:
	# Editördeki "Yeniden oluştur" düğmesi eski parçaları silip yenisini kurmalı, üst üste eklememeli.
	var fire := Campfire.new()
	add_child(fire)
	await wait_frames(1)
	var parts := fire.get_child_count()
	assert_true(parts > 10, "Ateş taşları (ya da taş halkası modeli), korlar, alevler ve ışık kurulmalı (%d parça)" % parts)
	fire.rebuild()
	fire.rebuild()
	await wait_frames(1)
	assert_eq(fire.get_child_count(), parts, "Yeniden üretim parça sayısını değiştirmemeli")
	assert_eq(fire.find_children("FireLight*", "OmniLight3D", false, false).size(), 1, "Tek bir ateş ışığı kalmalı")
	fire.flame_scale = 2.0
	await wait_frames(2)
	assert_eq(fire.get_child_count(), parts, "Özellik değişince de parçalar çoğalmamalı")
	await _free_and_settle(fire)


# --- Yardımcılar ---------------------------------------------------------------------

## Ateşin görünür parçalarının (taş halkası modeli ya da kodla çizilen taşlar, odunlar, alevler, korlar) ateş
## merkezine en uzak köşesinin yatay uzaklığı (metre, ateşin yerel uzayında). Parçacıklar ve ışık sayılmaz.
## Meshy modelinin meshleri model düğümünün altındadır; onlar da sayılır.
static func _part_reach(fire: Campfire) -> float:
	var reach := 0.0
	var to_fire := fire.global_transform.affine_inverse()
	for node in fire.find_children("*", "MeshInstance3D", true, false):
		var part := node as MeshInstance3D
		if part.mesh == null or not _is_generated_part(fire, part):
			continue
		var xform := to_fire * part.global_transform
		for surface in part.mesh.get_surface_count():
			var arrays := part.mesh.surface_get_arrays(surface)
			if typeof(arrays[Mesh.ARRAY_VERTEX]) != TYPE_PACKED_VECTOR3_ARRAY:
				continue
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			for v in vertices:
				var p: Vector3 = xform * v
				reach = maxf(reach, Vector2(p.x, p.z).length())
	return reach


## Parça ateşin ürettiği bir düğümün (kendisi ya da ateşin doğrudan alt düğümü olan atası) içinde mi?
static func _is_generated_part(fire: Node, node: Node) -> bool:
	var n := node
	while n != null and n.get_parent() != fire:
		n = n.get_parent()
	return n != null and n.has_meta(&"generated")


## Ateşi siler ve ses sunucusunun durdurulan çıtırtı sesini bırakmasını bekler
## (beklemeden çıkılırsa test süreci kapanırken "sızıntı" uyarısı yazılır).
func _free_and_settle(node: Node) -> void:
	node.queue_free()
	await get_tree().create_timer(0.2).timeout
	await wait_frames(2)
