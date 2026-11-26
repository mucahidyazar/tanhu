extends TestCase
## Akan çimen (Yol Haritası grass-streaming; godot.md §4.5): GrassField deneme haritasının verisiyle (pişmiş yükseklik ve maske, bahar
## otu kuralı) odağın çevresinde parça kurar; parçanın dizisi WorkerThreadPool'da kurulur, MultiMesh.buffer tek atamayla yazılır (örnek
## başına çağrı yok), uzaklaşan parça havuza döner ve yeni parça havuzdan alınır; aynı anahtar aynı örnekleri verir; otun çıkmadığı daireler
## (yurt, ocak) boş kalır. Kışlak'ın kuralı (kar altı) test_kislak_map.gd'de, saf kurallar test_terrain_paint.gd'dedir.

var _field: GrassField


func after_each() -> void:
	if is_instance_valid(_field):
		_field.queue_free()
	_field = null
	await wait_frames(2)


func _testmap_field() -> GrassField:
	var spec := MapSpec.find(MapSpec.TESTMAP)
	var ground := MapBake.fetch(spec.id, "ground", MapBaker.signature(spec))
	assert_not_null(ground, "Deneme haritasının pişmiş zemini")
	if ground == null:
		return null
	var def := spec.grass.duplicate(true)
	def["kind"] = "meadow"
	def["chunk"] = 20.0
	def["radius"] = 40.0
	def["density"] = 3.0
	var field := GrassField.new()
	field.setup(MapBaker.shape_of(ground), def, ground.data["mask"], ground.data["mask_rect"], MapBaker.grass_blockers(spec))
	add_child(field)
	return field


func test_streams_chunks_around_the_focus_on_the_testmap() -> void:
	_field = _testmap_field()
	if _field == null:
		return
	_field.focus = Vector3(0.0, 0.0, 30.0)
	for i in 6:
		_field.update()
		_field.flush()
	var count := _field.live.size()
	assert_true(count >= 12, "Odağın çevresinde parçalar (%d)" % count)
	assert_true(_field.instance_count() > 2000, "Bahar otu (%d tutam)" % _field.instance_count())
	assert_true(int(_field.stats["writes"]) >= count, "Her çeşit dizisi tek atamayla yazıldı")
	for key: Vector2i in _field.live:
		assert_true(_field.chunk_center(key).distance_to(Vector2(0.0, 30.0)) <= _field.radius + _field.chunk, "Parça yarıçapın içinde")
	# Otun çıkmadığı yer: kuzey yurdunun (0, −22) içi.
	var inside := 0
	for key: Vector2i in _field.live:
		for mmi: MultiMeshInstance3D in _field.live[key]:
			var mm := mmi.multimesh
			for i in mm.instance_count:
				var o := mm.get_instance_transform(i).origin
				if Vector2(o.x, o.z).distance_to(Vector2(0.0, -22.0)) < 3.0:
					inside += 1
	assert_eq(inside, 0, "Yurdun içinde ot yok")


func test_far_chunks_return_to_the_pool_and_are_reused() -> void:
	_field = _testmap_field()
	if _field == null:
		return
	_field.focus = Vector3(-120.0, 0.0, 0.0)
	for i in 6:
		_field.update()
		_field.flush()
	var first: Array = _field.live.keys()
	var nodes_before := _field.get_child_count()
	_field.focus = Vector3(120.0, 0.0, 0.0)
	for i in 6:
		_field.update()
		_field.flush()
	for k: Vector2i in first:
		assert_false(_field.live.has(k), "Uzaklaşan parça bırakıldı")
	assert_true(int(_field.stats["reused"]) > 0, "Havuzdaki düğüm yeniden kullanıldı")
	assert_true(_field.get_child_count() <= nodes_before + 8, "Düğüm sayısı büyümez (%d → %d)" % [nodes_before, _field.get_child_count()])


func test_same_key_gives_the_same_instances() -> void:
	_field = _testmap_field()
	if _field == null:
		return
	var a := _field.build_chunk(Vector2i(1, -1))
	var b := _field.build_chunk(Vector2i(1, -1))
	assert_eq(a, b, "Parça tohumdan kurulur")
	var c := _field.build_chunk(Vector2i(2, -1))
	assert_ne(a, c, "Komşu parça başka")
	# İş parçacığında kurulan dizi ana iş parçacığındakiyle aynı.
	var holder := {"out": []}
	var task := WorkerThreadPool.add_task(func() -> void: holder["out"] = _field.build_chunk(Vector2i(1, -1)))
	WorkerThreadPool.wait_for_task_completion(task)
	assert_eq(holder["out"], a, "İş parçacığında aynı sonuç")
