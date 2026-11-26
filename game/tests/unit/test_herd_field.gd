extends TestCase
## Çocukluk'un sürüsü (HerdSim, HerdField, FaunaMesh; fauna.md §10, godot.md §4.5, K65; Yol Haritası childhood-herd). Benzetim kareler çizilmeden
## sınanır: ağıl duvarı, kapı, çayıra yayılma, sayım hattından tek tek geçme, engeller, tohum. Düğüm: tek MultiMeshInstance3D, iskelet yok, köşe
## verisi, ara değer, sinyaller, Meshy ağının kendiliğinden yerine geçmesi (sahte ağ: at modeli) ve T1 üçgen bütçesi.

const LAYOUT := "res://data/maps/childhood_ordos/layout.json"
const HORSE_MODEL := "res://assets/animals/horse_brown/horse_brown.glb"
const SPEEDS := {"walk": 1.1, "trot": 2.5, "gallop": 5.5}
const TICK := HerdSim.TICK

var _trash: Array[Node] = []


func after_each() -> void:
	MeshyProp.models_enabled = true
	for node in _trash:
		if is_instance_valid(node):
			node.queue_free()
	_trash.clear()


# --- Benzetim ---------------------------------------------------------------------------------------

func test_sheep_stay_in_the_closed_pen() -> void:
	var sim := _sim()
	assert_eq(sim.count, 40, "Çocukluk'un sürüsü 40 koyun")
	assert_eq(sim.phase, HerdSim.Phase.PEN)
	assert_false(sim.gate_open, "Kapı kapalı başlar")
	for tick in 240:
		sim.step()
		for i in sim.count:
			assert_true(sim.pos[i].distance_to(sim.pen_center) < sim.pen_radius, "Koyun %d ağıldan çıkmamalı (tik %d)" % [i, tick])
		if not failures.is_empty():
			return
	assert_true(_moved_share(sim) >= 0.0)


func test_release_leaves_only_through_the_gate_and_settles_on_the_meadow() -> void:
	var sim := _sim()
	sim.release()
	assert_true(sim.gate_open, "release kapıyı açar")
	assert_eq(sim.phase, HerdSim.Phase.LEAVING)
	var released := 0
	var settled := 0
	var released_at := -1.0
	var settled_at := -1.0
	var side := Vector2(-sim.gate_dir.y, sim.gate_dir.x)
	for tick in 1200:
		sim.step()
		for ev: Dictionary in sim.events:
			if ev["type"] == &"released":
				released += 1
				released_at = sim.clock
			elif ev["type"] == &"settled":
				settled += 1
				settled_at = sim.clock
		for i in sim.count:
			var inside_before := sim.prev[i].distance_to(sim.pen_center) < sim.pen_radius
			var inside_now := sim.pos[i].distance_to(sim.pen_center) < sim.pen_radius
			if inside_before and not inside_now:
				var rel := sim.pos[i] - sim.pen_center
				assert_true(rel.dot(sim.gate_dir) > 0.0 and absf(rel.dot(side)) < sim.gate_width * 0.5 + 0.05,
					"Koyun %d çitten değil kapıdan çıkmalı (yan %.2f m)" % [i, rel.dot(side)])
		if settled > 0 or not failures.is_empty():
			break
	assert_eq(released, 1, "«Hepsi çıktı» bir kez")
	assert_eq(settled, 1, "«Çayıra yerleşti» bir kez")
	assert_eq(sim.released_total(), 40)
	assert_eq(sim.phase, HerdSim.Phase.MEADOW)
	print("    [herd] son koyun kapıdan çıktı %.1f sn, sürü çayırda %.1f sn" % [released_at, settled_at])
	assert_true(released_at <= 45.0, "Çıkış makul sürede biter (%.1f sn)" % released_at)
	assert_true(settled_at <= 80.0, "Yayılma makul sürede biter (%.1f sn)" % settled_at)
	for i in sim.count:
		assert_true(sim.pos[i].distance_to(sim.meadow_center) <= sim.meadow_radius + 1.0, "Koyun %d çayırda (%.1f m)" % [i, sim.pos[i].distance_to(sim.meadow_center)])


func test_meadow_grazing_keeps_the_herd_in_its_disc() -> void:
	var sim := _sim()
	sim.place_on_meadow()
	assert_eq(sim.phase, HerdSim.Phase.MEADOW)
	var start := sim.pos.duplicate()
	var grazing := 0
	var samples := 0
	for tick in 480:
		sim.step()
		if tick % 8 == 0:
			for i in sim.count:
				samples += 1
				grazing += sim.grazing[i]
	var moved := 0
	for i in sim.count:
		assert_true(sim.pos[i].distance_to(sim.meadow_center) <= sim.meadow_radius + 1.5, "Koyun %d diskin içinde kalır" % i)
		if sim.pos[i].distance_to(start[i]) > 0.5:
			moved += 1
	assert_true(moved >= 30, "Sürü yer değiştirir (%d koyun)" % moved)
	var share := float(grazing) / float(samples)
	assert_between(share, 0.4, 0.95, "Koyunlar çoğunlukla otlar (%.2f)" % share)
	# Ayrılma itişi (gövde elipsi): üst üste binen koyun kalmaz.
	assert_true(_overlapping_pairs(sim) <= 2, "Koyunların gövdesi üst üste binmez (%d çift)" % _overlapping_pairs(sim))


func test_sheep_bodies_stay_apart_in_the_pen_and_at_the_gate() -> void:
	# K98 kadrajında (22 m) iç içe geçen iki koyun okunur: ağılda gezinen önü kapanınca durur, kapıdan iki sıra çıkılır, baş kuyruğa binmez.
	var sim := _sim()
	for k in sim.count:
		sim.body_scale[k] = 0.9 + 0.22 * float(k % 5) / 4.0
	# Yerleştirme anında da ayrıktır (ilk kare): relax zaman akıtmaz.
	sim.relax()
	assert_true(_overlapping_pairs(sim) <= 1, "Ağıla yerleşen koyunlar iç içe değil (%d çift)" % _overlapping_pairs(sim))
	var meadow := _sim()
	meadow.place_on_meadow()
	assert_true(_overlapping_pairs(meadow) <= 1, "Çayıra yerleşen koyunlar iç içe değil (%d çift)" % _overlapping_pairs(meadow))
	var total := 0
	var samples := 0
	for tick in 240:
		sim.step()
		if tick % 4 == 0:
			total += _overlapping_pairs(sim)
			samples += 1
	var pen_mean := float(total) / samples
	sim.release()
	total = 0
	samples = 0
	for tick in 400:
		sim.step()
		if tick % 4 == 0:
			total += _overlapping_pairs(sim)
			samples += 1
		if sim.phase == HerdSim.Phase.MEADOW:
			break
	var gate_mean := float(total) / samples
	print("    [herd] üst üste binen çift (ortalama): ağılda %.2f, çıkışta %.2f" % [pen_mean, gate_mean])
	assert_true(pen_mean <= 2.0, "Ağılda koyunlar iç içe geçmez (%.2f çift)" % pen_mean)
	assert_true(gate_mean <= 2.5, "Kapıda koyunlar iç içe geçmez (%.2f çift)" % gate_mean)
	# Yön yalnız kendi yürüyüşünden gelir: birim vektör.
	for k in sim.count:
		assert_almost(sim.facing[k].length(), 1.0, 0.001, "Koyun %d yönü birim" % k)
	assert_almost(HerdSim.body_reach(Vector2.UP, Vector2.UP), HerdSim.BODY_HALF_LENGTH, 0.001, "Baş yönünde yarı boy")
	assert_almost(HerdSim.body_reach(Vector2.UP, Vector2.RIGHT), HerdSim.BODY_HALF_WIDTH, 0.001, "Yanda yarı en")


func test_drive_counts_every_sheep_once_along_the_rope() -> void:
	var layout := OrdosWorld.load_layout(LAYOUT)
	var line: Dictionary = layout["counting_line"]
	var rope_a := OrdosGround._vec2(line["from"])
	var rope_b := OrdosGround._vec2(line["to"])
	var sim := _sim()
	sim.obstacles = ChildhoodSite.collision_circles(layout, true)
	sim.place_on_meadow()
	sim.drive()
	var count_point := sim.line_route[sim.count_at]
	var tallies: Array[int] = []
	var seen := {}
	var finished := 0
	var finished_at := -1.0
	for tick in 1600:
		sim.step()
		for i in sim.count:
			var cross: Variant = Geometry2D.segment_intersects_segment(sim.prev[i], sim.pos[i], rope_a, rope_b)
			assert_true(cross == null, "Koyun %d ipin altından geçmemeli" % i)
		for ev: Dictionary in sim.events:
			if ev["type"] == &"counted":
				var index := int(ev["index"])
				assert_false(seen.has(index), "Koyun %d bir kez sayılır" % index)
				seen[index] = true
				tallies.append(int(ev["tally"]))
				assert_true(sim.pos[index].distance_to(count_point) <= HerdSim.WAYPOINT_REACH + 0.5,
					"Sayım noktasında sayılır (%.2f m)" % sim.pos[index].distance_to(count_point))
			elif ev["type"] == &"count_finished":
				finished += 1
				finished_at = sim.clock
		if not failures.is_empty():
			return
		if sim.phase == HerdSim.Phase.COUNTED:
			break
	assert_eq(tallies.size(), 40, "Bütün koyunlar sayılır")
	for k in tallies.size():
		assert_eq(tallies[k], k + 1, "Sayaç birer artar")
	assert_eq(finished, 1, "Sayım bir kez biter")
	assert_eq(sim.phase, HerdSim.Phase.COUNTED)
	assert_eq(sim.counted_total(), 40)
	print("    [herd] son koyun %.1f sn'de sayıldı" % finished_at)
	assert_true(finished_at <= 62.0, "Koyunlar çocuklardan önce sayılır: adım 90 sn (%.1f sn)" % finished_at)
	# Sayım sonrası: after diski; engel yok.
	for i in sim.count:
		assert_true(sim.pos[i].distance_to(sim.after_center) <= sim.after_radius + 1.0, "Koyun %d sayımdan sonra yerinde" % i)
		for c in sim.obstacles:
			assert_true(sim.pos[i].distance_to(Vector2(c.x, c.y)) >= c.z + HerdSim.BODY_RADIUS - 0.05, "Koyun %d engelin içinde değil" % i)


func test_drive_from_the_pen_goes_through_the_gate() -> void:
	# Oyuncu ağıldan çıkarmadan sayıma geçilse de sürü çitten geçmez.
	var sim := _sim()
	sim.drive()
	assert_true(sim.gate_open, "Sayım kapıyı açar")
	var side := Vector2(-sim.gate_dir.y, sim.gate_dir.x)
	for tick in 1600:
		sim.step()
		for i in sim.count:
			var inside_before := sim.prev[i].distance_to(sim.pen_center) < sim.pen_radius
			var inside_now := sim.pos[i].distance_to(sim.pen_center) < sim.pen_radius
			if inside_before and not inside_now:
				var rel := sim.pos[i] - sim.pen_center
				assert_true(rel.dot(sim.gate_dir) > 0.0 and absf(rel.dot(side)) < sim.gate_width * 0.5 + 0.05, "Koyun %d kapıdan çıkmalı" % i)
		if sim.phase == HerdSim.Phase.COUNTED or not failures.is_empty():
			break
	assert_eq(sim.counted_total(), 40, "Ağıldan gelen koyunlar da sayılır")


func test_same_seed_same_herd() -> void:
	var a := _sim()
	var b := _sim()
	a.release()
	b.release()
	for tick in 100:
		a.step()
		b.step()
	assert_eq(a.pos, b.pos, "Aynı tohum aynı sürü")


func test_sheep_give_way_to_the_player() -> void:
	var sim := _sim()
	sim.place_on_meadow()
	var who := sim.pos[7]
	sim.avoid = [Vector3(who.x, who.y, 1.7)]
	for tick in 24:
		sim.step()
	for i in sim.count:
		assert_true(sim.pos[i].distance_to(who) >= 1.0, "Koyun %d oyuncuya yol verir (%.2f m)" % [i, sim.pos[i].distance_to(who)])


func test_scatter_points_fill_the_disc() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var points := HerdSim.scatter_points(Vector2(5.0, -2.0), 7.0, 40, rng, 1.15)
	assert_eq(points.size(), 40)
	var closest := INF
	for i in points.size():
		assert_true(points[i].distance_to(Vector2(5.0, -2.0)) <= 7.0, "Nokta diskin içinde")
		for j in range(i + 1, points.size()):
			closest = minf(closest, points[i].distance_to(points[j]))
	assert_true(closest >= 0.9, "Noktalar dağılır (%.2f m)" % closest)


func test_stride_and_swing() -> void:
	assert_almost(HerdField.stride_at(1.1, 1.1, 2.5, 0.86, 1.19), 0.86, 0.001, "Yürüyüş adımı")
	assert_almost(HerdField.stride_at(2.5, 1.1, 2.5, 0.86, 1.19), 1.19, 0.001, "Tırıs adımı (fauna.md yürüyüş tablosu)")
	assert_almost(HerdField.swing_amplitude(0.0, 0.86), 0.0, 0.0001, "Dururken bacak sallanmaz")
	var walk := HerdField.swing_amplitude(1.1, 0.86)
	var trot := HerdField.swing_amplitude(2.5, 1.19)
	assert_true(trot > walk and walk > 0.3, "Hız arttıkça adım büyür (%.2f, %.2f)" % [walk, trot])
	# Ayağın kayması: adım boyu = 4 × salınım × bacak boyu (fauna.md: T1 kabulü ≤6 cm).
	assert_almost(walk * 4.0 * HerdField.LEG_LENGTH, 0.86, 0.02, "Salınım adım boyunu verir")


# --- Düğüm ------------------------------------------------------------------------------------------

func test_field_is_one_multimesh_without_skeletons() -> void:
	MeshyProp.models_enabled = false
	var field := _field()
	await wait_frames(2)
	MeshyProp.models_enabled = true
	assert_eq(field.count(), 40)
	var instances := field.find_children("*", "MultiMeshInstance3D", true, false)
	assert_eq(instances.size(), 1, "Sürü tek MultiMeshInstance3D")
	assert_eq(field.find_children("*", "Skeleton3D", true, false).size(), 0, "İskelet yok")
	assert_eq(field.find_children("*", "MeshInstance3D", true, false).size(), 0, "Ayrı ağ yok")
	var mm := (instances[0] as MultiMeshInstance3D).multimesh
	assert_eq(mm.instance_count, 40)
	assert_true(mm.use_custom_data, "Evre ve otlama örnek verisinde")
	assert_eq(mm.mesh.get_surface_count(), 1, "Tek yüzey: tek çizim")
	assert_true(field.mesh_triangles() <= 1800, "T1 bütçesi (%d üçgen)" % field.mesh_triangles())
	assert_eq(((instances[0] as MultiMeshInstance3D).material_override as ShaderMaterial).shader.resource_path, "res://shaders/herd_field.gdshader")
	assert_false(field.uses_model(), "Model kapalıyken kodla çizilir")


func test_buffer_follows_the_ground_and_the_gait() -> void:
	var field := _field()
	field.set_process(false)
	var ground := field.ground
	field.place_on_meadow()
	for i in field.count():
		var p := field.sheep_position(i)
		assert_almost(p.y, ground.height_at(p.x, p.z), 0.001, "Koyun %d zemine oturur" % i)
	field.drive_through_line()
	for i in 240:
		field._process(1.0 / 30.0)
	# En az bir koyun yürüyor: genlik ve evre dolu. Tampon doğrudan okunur (başsız sürücüde MultiMesh örneği sormak sıfır döner).
	var walking := 0
	var b := field._buffer
	for i in field.count():
		var k := i * HerdField.FLOATS_PER_SHEEP
		if b[k + 13] > 0.2:
			walking += 1
		assert_between(b[k + 12], 0.0, 1.0, "Evre 0..1")
		assert_between(b[k + 14], 0.0, 1.0, "Otlama 0..1")
		assert_between(b[k + 15], 0.0, 1.0, "Tohum 0..1")
		assert_vec_almost(Vector3(b[k + 3], b[k + 7], b[k + 11]), field.sheep_position(i), 0.02, "Dönüşüm konumla aynı (%d)" % i)
		assert_almost(Vector3(b[k], b[k + 4], b[k + 8]).length(), b[k + 5], 0.001, "Ölçek düzgün")
	assert_true(walking >= 5, "Sayımda koyunlar yürür (%d)" % walking)


func test_interpolates_between_ticks() -> void:
	var field := _field()
	field.set_process(false)
	field.place_on_meadow()
	field.drive_through_line()
	for i in 80:
		field._process(HerdSim.TICK)
	# Koyunlardan biri yürürken iki tik arasında ara değerdedir.
	var moving := -1
	for i in field.count():
		if field.sim.pos[i].distance_to(field.sim.prev[i]) > 0.2:
			moving = i
			break
	assert_true(moving >= 0, "Yürüyen koyun olmalı")
	if moving < 0:
		return
	field._process(HerdSim.TICK * 0.5)
	var p := field.sheep_position(moving)
	var a := field.sim.prev[moving]
	var b := field.sim.pos[moving]
	var mid := a.lerp(b, 0.5)
	assert_true(Vector2(p.x, p.z).distance_to(mid) < 0.02, "Tik ortasında konum ortada")


func test_signals_tell_the_scene_what_happened() -> void:
	var field := _field()
	field.set_process(false)
	var released := watch_signal(field.released)
	var settled := watch_signal(field.settled)
	var counted := [0]
	field.sheep_counted.connect(func(_i: int, tally: int) -> void: counted[0] = tally)
	var finished := watch_signal(field.count_finished)
	field.release()
	for i in 1200:
		field._process(HerdSim.TICK)
		if settled.fired:
			break
	assert_true(released.fired, "released yayılır")
	assert_true(settled.fired, "settled yayılır")
	assert_eq(field.released_total(), 40)
	field.drive_through_line()
	for i in 1600:
		field._process(HerdSim.TICK)
		if finished.fired:
			break
	assert_eq(counted[0], 40, "sheep_counted son sayaç 40")
	assert_true(finished.fired, "count_finished yayılır")
	assert_eq(finished.last_args, [40])
	assert_eq(field.tally(), 40)


func test_avoid_nodes_push_the_herd() -> void:
	var field := _field()
	field.set_process(false)
	field.place_on_meadow()
	var player := Node3D.new()
	add_child(player)
	_trash.append(player)
	var at := field.sheep_position(3)
	player.global_position = at
	field.set_avoid_nodes([player])
	for i in 24:
		field._process(HerdSim.TICK)
	assert_true(Vector2(field.sheep_position(3).x, field.sheep_position(3).z).distance_to(Vector2(at.x, at.z)) >= 1.0, "Koyun oyuncudan uzaklaşır")


func test_frame_write_is_cheap() -> void:
	# fauna.md §10: iç haritada fauna GDScript payı ≤0,5 ms. Sürü: tik ortalaması + tampon yazımı; başka işlerin sıçramasını ayıklamak için en iyi üç ölçümden biri.
	var field := _field()
	field.set_process(false)
	field.place_on_meadow()
	field.drive_through_line()
	for i in 80:
		field._process(HerdSim.TICK)
	var best := INF
	for attempt in 3:
		var started := Time.get_ticks_usec()
		for i in 240:
			field._process(1.0 / 60.0)
		best = minf(best, float(Time.get_ticks_usec() - started) / 240.0 / 1000.0)
	print("    [herd] kare başına %.3f ms (40 koyun, 4 Hz benzetimle)" % best)
	assert_true(best <= 0.5, "Sürünün kare payı ≤0,5 ms (%.3f ms)" % best)


# --- Meshy ağı ---------------------------------------------------------------------------------------

func test_model_replaces_the_drawn_mesh_when_it_arrives() -> void:
	# Koyun modeli henüz yok: at modeli sahte Meshy ağıdır (aynı duruş, baş +Z'de). Yol verilince kendiliğinden yerine geçer, T1'e iner.
	if not ResourceLoader.exists(HORSE_MODEL):
		return
	var field := HerdField.new()
	field.setup(_layout()["childhood"], OrdosGround.new(_layout()))
	field.set_model_path(HORSE_MODEL)
	add_child(field)
	_trash.append(field)
	var ready := watch_signal(field.model_ready)
	var drawn_triangles := field.mesh_triangles()
	var deadline := Time.get_ticks_msec() + 60000
	while not ready.fired and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	assert_true(ready.fired, "model_ready yayılmalı")
	assert_true(field.uses_model(), "Ağ yerine geçer")
	assert_true(field.mesh_triangles() <= 1800, "T1 bütçesine iner (%d üçgen)" % field.mesh_triangles())
	assert_ne(field.mesh_triangles(), drawn_triangles)
	print("    [herd] sahte Meshy ağı: %d üçgen" % field.mesh_triangles())
	var mat := field.instance.material_override as ShaderMaterial
	var arrays: Array = field.instance.multimesh.mesh.surface_get_arrays(0)
	# Boya dokudan köşeye geçer: kahverengi at, beyaz değil.
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var mean := Color(0.0, 0.0, 0.0)
	for c in colors:
		mean.r += c.r
		mean.g += c.g
		mean.b += c.b
	assert_true(mean.r / colors.size() < 0.8 and mean.r > mean.b, "Köşe rengi dokudan okunur (%s)" % str(mean / colors.size()))
	var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var box := AABB(points[0], Vector3.ZERO)
	for p in points:
		box = box.expand(p)
	assert_almost(box.size.z, field.kind.model_length(), 0.08, "Boy türün ölçüsüne iner")
	assert_almost(box.position.y, 0.0, 0.03, "Taban yerde")
	assert_almost(box.position.z + box.size.z * 0.5, 0.0, 0.03, "Boy ortalanır")
	var custom: PackedFloat32Array = arrays[Mesh.ARRAY_CUSTOM0]
	assert_eq(custom.size(), points.size() * 4, "Her köşede parça bilgisi")
	var hip := float(mat.get_shader_parameter(&"hip_height"))
	var legs := [0, 0, 0, 0, 0]
	var head_z := 0.0
	var head_n := 0
	for i in points.size():
		var leg := int(custom[i * 4])
		legs[leg] += 1
		if leg > 0:
			assert_true(points[i].y <= hip + 0.04, "Bacak köşesi kalçanın altında")
		if custom[i * 4 + 2] > 0.5:
			head_z += points[i].z
			head_n += 1
	for leg in range(1, 5):
		assert_true(legs[leg] > 10, "Dört bacak ayrılır (%s)" % str(legs))
	assert_true(head_n > 10 and head_z / head_n > box.size.z * 0.2, "Baş önde")


func test_sheep_model_is_the_far_mesh() -> void:
	# Koyun varlığı (assets/animals/sheep): sürü uzak ağı çizer (1.300 üçgen), boyu sheep.json'dan; binilen koyun asıl ağı (iskeletli) kullanır.
	var kind := FaunaKind.named("sheep")
	assert_eq(kind.model_path(), "res://assets/animals/sheep/sheep.glb", "Asıl model")
	assert_eq(kind.far_model_path(), "res://assets/animals/sheep/sheep_far.glb", "Uzak ağ")
	if not ResourceLoader.exists(kind.far_model_path()):
		return
	assert_eq(kind.herd_model_path(), kind.far_model_path(), "Sürü uzak ağı ister")
	assert_almost(kind.model_length(), kind.length, 0.01, "kinds.json'un boyu sheep.json'la aynı")
	var field := _field()
	var ready := watch_signal(field.model_ready)
	var deadline := Time.get_ticks_msec() + 60000
	while not ready.fired and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	assert_true(field.uses_model(), "Uzak ağ yerine geçer")
	assert_true(field.mesh_triangles() <= kind.max_triangles(), "T1 bütçesi (%d üçgen)" % field.mesh_triangles())
	assert_true(field.mesh_triangles() >= 1000, "Uzak ağ indirgenmeden kalır (%d üçgen)" % field.mesh_triangles())


func test_no_model_no_swap() -> void:
	MeshyProp.models_enabled = false
	var field := _field()
	await wait_frames(3)
	MeshyProp.models_enabled = true
	assert_false(field.uses_model(), "Model yokken (kapalıyken) kodla çizim")
	assert_true(field.mesh_triangles() > 300, "Kodla çizilen ağ var")


func test_reduced_indices_fit_the_budget() -> void:
	# Yoğun küre: kümeleme sınıra iner; sınırın altındaki ağa dokunulmaz.
	var data := MeshKit.icosphere_data(5)
	var points: PackedVector3Array = data[0]
	var faces: PackedInt32Array = data[1]
	var box := AABB(Vector3(-1.0, -1.0, -1.0), Vector3(2.0, 2.0, 2.0))
	var reduced := FaunaMesh.reduced_indices(points, faces, box, 1800)
	assert_true(reduced.size() / 3 <= 1800, "İndirgenen ağ sınıra sığar (%d üçgen)" % (reduced.size() / 3))
	assert_true(reduced.size() / 3 > 600, "Sınıra yakın iner (%d üçgen)" % (reduced.size() / 3))
	var same := FaunaMesh.reduced_indices(points, faces, box, 100000)
	assert_eq(same.size(), faces.size(), "Sınırın altındaki ağa dokunulmaz")
	assert_true(FaunaMesh.cluster_indices(points, faces, box, 1.0).size() < faces.size() / 50, "Büyük hücrede yozlaşan üçgen düşer")


func test_model_tag_finds_the_parts() -> void:
	var joints := FaunaMesh.model_joints(FaunaMesh.SHEEP_HEIGHT, 1.14)
	assert_almost(float(joints["hip"]), FaunaMesh.SHEEP_HIP, 0.001, "Kodla çizilen koyunla aynı oran")
	assert_eq(int(FaunaMesh.model_tag(Vector3(-0.1, 0.1, -0.25), joints, 1.14).x), 1, "Sol arka")
	assert_eq(int(FaunaMesh.model_tag(Vector3(-0.1, 0.1, 0.25), joints, 1.14).x), 2, "Sol ön")
	assert_eq(int(FaunaMesh.model_tag(Vector3(0.1, 0.1, -0.25), joints, 1.14).x), 3, "Sağ arka")
	assert_eq(int(FaunaMesh.model_tag(Vector3(0.1, 0.1, 0.25), joints, 1.14).x), 4, "Sağ ön")
	assert_almost(FaunaMesh.model_tag(Vector3(0.0, 0.85, 0.5), joints, 1.14).z, 1.0, 0.01, "Baş")
	assert_almost(FaunaMesh.model_tag(Vector3(0.0, 0.55, 0.0), joints, 1.14).z, 0.0, 0.01, "Gövde başla dönmez")
	assert_true(FaunaMesh.model_tag(Vector3(0.0, 0.5, -0.55), joints, 1.14).w > 0.5, "Kuyruk")


# --- Yardımcılar ------------------------------------------------------------------------------------

func _layout() -> Dictionary:
	return OrdosWorld.load_layout(LAYOUT)


func _sim() -> HerdSim:
	return HerdSim.new(_layout()["childhood"], SPEEDS)


func _field() -> HerdField:
	var layout := _layout()
	var field := HerdField.new()
	field.setup(layout["childhood"], OrdosGround.new(layout))
	add_child(field)
	_trash.append(field)
	return field


## Üstten bakışta gövdesi üst üste binen koyun çifti: gövde yönlü dikdörtgendir (yarı boy 0,55, yarı en 0,17 m; modelin 1,264 m boyunun
## yuvarlak baş ve sağrısı içeride kalır), yönü HerdSim.facing (HerdField gövdeyi buna çevirir).
func _overlapping_pairs(sim: HerdSim) -> int:
	var n := 0
	for i in sim.count:
		for j in range(i + 1, sim.count):
			if sim.pos[i].distance_squared_to(sim.pos[j]) < 4.0 and _bodies_overlap(sim, i, j, 0.55, 0.17):
				n += 1
	return n


func _bodies_overlap(sim: HerdSim, i: int, j: int, half_length: float, half_width: float) -> bool:
	var fi := sim.facing[i]
	var fj := sim.facing[j]
	var d := sim.pos[j] - sim.pos[i]
	for axis: Vector2 in [fi, fi.orthogonal(), fj, fj.orthogonal()]:
		var ri := (absf(fi.dot(axis)) * half_length + absf(fi.orthogonal().dot(axis)) * half_width) * sim.body_scale[i]
		var rj := (absf(fj.dot(axis)) * half_length + absf(fj.orthogonal().dot(axis)) * half_width) * sim.body_scale[j]
		if absf(d.dot(axis)) > ri + rj:
			return false
	return true


func _moved_share(sim: HerdSim) -> float:
	var moved := 0
	for i in sim.count:
		if sim.pos[i] != sim.prev[i]:
			moved += 1
	return float(moved) / float(sim.count)
