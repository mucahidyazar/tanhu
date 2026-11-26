extends TestCase
## Kışlak'ın kişi katmanı (FolkLayer; data/maps/kislak/folk.json, map.json «layers» «folk»; Yol Haritası folk-generator, npc-schedules,
## crowd-tiers; act1.md §4–§5):
##   - katman Kışlak'ın haritasına bağlıdır, MapLayers'ın sözleşmesiyle (script, setup(world, def)) kurulur; oturum yoksa kendi saatiyle;
##   - tam kişiler ≤16 (adlılar; kendi modelleri ya da Folk'un görünüşü), kalabalık CrowdField'de; yuvalarla birlikte T0 16'yı aşmaz;
##   - gündüz Ulu Ocak'ın çevresinde 40 kişilik pazar; gece dokuz nöbet ateşinin nöbetçisi yerinde; Çukur'da gece 31 esir; Demir Diş'te
##     gündüz 16 esir ve 2 nöbetçi; adlılar vakit bloklarına göre yerinde (Amaga 12:00'de Ulu Ocak'ta, 13:00'te yurdunda, görünmez);
##   - saat olağan akarken kişiler yürüyerek yetişir: hiçbir kişi oyuncunun koşusunu aşmaz (K105).

const DAY_II := 1042

var _trash: Array[Node] = []


func after_each() -> void:
	for node in _trash:
		if is_instance_valid(node):
			node.queue_free()
	_trash.clear()


func test_kislak_map_lists_the_folk_layer() -> void:
	var spec := MapSpec.find(MapSpec.KISLAK)
	assert_not_null(spec, "Kışlak'ın tarifi")
	if spec == null:
		return
	assert_eq(str(spec.layers.get("folk", "")), "res://data/maps/kislak/folk.json", "map.json «layers» «folk»")
	var def := MapLayers.read("res://data/maps/kislak/folk.json")
	assert_eq(str(def.get("script", "")), "res://scripts/crowd/folk_layer.gd")
	assert_true(ResourceLoader.exists(str(def["script"])), "Katmanın betiği")
	assert_true(FileAccess.file_exists(str(def.get("npcs", ""))), "Programın verisi")


func test_layer_on_the_real_kislak_map() -> void:
	# Kışlak'ın kendisi (A'nın haritası, pişmiş parçalar, MapNav) yalnız bu katmanla başsız kurulur: betikler hatasız yüklenir, katman
	# Layers/Folk'tadır, kişiler kurulur, navmesh eşlenince yürüyüşler navmesh yolundan gelir.
	var scene := load("res://scenes/maps/kislak.tscn") as PackedScene
	assert_not_null(scene, "Kışlak'ın sahnesi")
	if scene == null:
		return
	var world := scene.instantiate() as MapWorld
	var spec := MapSpec.from_dict(MapSpec.find(MapSpec.KISLAK).raw.duplicate(true))
	spec.layers = {"folk": "res://data/maps/kislak/folk.json"}
	world.spec = spec
	add_child(world)
	_trash.append(world)
	var deadline := Time.get_ticks_msec() + 60000
	while not world.is_ready() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	assert_true(world.is_ready(), "Kışlak kuruldu")
	var layer := world.get_node_or_null(^"Layers/Folk") as FolkLayer
	assert_not_null(layer, "Layers/Folk")
	if layer == null:
		return
	while not layer.is_built() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	assert_true(layer.is_built(), "Katman kuruldu")
	assert_true(layer.people.size() >= 12, "Tam kişiler")
	assert_true(layer.avatar_of("amaga").has_meshy_model(), "Amaga'nın modeli")
	var nav := MapNav.of(world)
	assert_not_null(nav, "MapNav")
	while nav and not nav.is_ready() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	for f in 20:
		await get_tree().process_frame
	# Farnak Ahır'dan Çoban Durağı'na yürür: plan navmesh yolundan (ikiden çok köşe ya da düz çizgi değil).
	var path := layer._nav_path(Vector2(-72.0, 34.0), Vector2(210.0, -250.0))
	assert_true(path.size() >= 2, "Navmesh yolu")
	assert_eq(path[0], Vector2(-72.0, 34.0), "Yol bloğun yerinden çıkar")
	assert_eq(path[path.size() - 1], Vector2(210.0, -250.0), "Yol bloğun yerinde biter")
	var mid := layer.schedule.plan("farnak", GameClock.abs_of(DAY_II, 580.0))
	assert_eq(str(mid["kind"]), "walk", "09:40'ta Farnak yolda")
	var y := world.get_terrain_shape().height_at(0.0, 0.0)
	assert_true(absf(layer.field.position_of(0).y - world.get_terrain_shape().height_at(layer.field.position_of(0).x, layer.field.position_of(0).z)) < 0.7, "Kalabalık zeminde")
	assert_true(is_finite(y))
	world.queue_free()
	await get_tree().create_timer(0.35).timeout


func test_layer_builds_people_and_crowd_and_follows_the_day() -> void:
	var layer := await _layer("10:30")
	assert_true(layer.is_built(), "Katman kuruldu")
	var counts := layer.counts()
	assert_between(float(layer.people.size()), 12.0, 16.0, "Tam kişi kadrosu ≤16")
	assert_true(int(counts["t0"]) <= FolkLayer.T0_CAP, "Yuvalarla T0 ≤16")
	assert_eq(layer.field.t0_slots, FolkLayer.T0_CAP - layer.people.size(), "Kalan yuvalar kalabalığın")
	for id in ["amaga", "farnak", "palak", "uldin", "berik", "kujul"]:
		assert_not_null(layer.avatar_of(id), "%s tam kişi" % id)
	assert_true(layer.avatar_of("farnak").has_meshy_model(), "Farnak kendi modelinde")
	assert_eq(layer.avatar_of("uldin").model_override, "crowd_hun_man", "Uldın Folk'un görünüşünde")
	assert_false(layer.avatar_of("uldin").shader_overrides.is_empty(), "Uldın'ın boyası")
	# 12:05: pazar dolu, Amaga Ulu Ocak'ta.
	await _jump(layer, "12:05")
	var market := _members(layer, "market")
	var at_market := 0
	for i in market:
		var p := layer.field.position_of(i)
		if layer.field.state_of(i) == CrowdPlan.State.STAND and Vector2(p.x, p.z).length() <= 17.0:
			at_market += 1
	assert_eq(at_market, 40, "Gündüz Ulu Ocak'ta 40 kişilik pazar")
	var amaga := layer.avatar_of("amaga")
	assert_true(amaga.visible, "Amaga dışarıda")
	assert_true(Vector2(amaga.global_position.x, amaga.global_position.z).distance_to(Vector2(6.0, -4.0)) < 0.1, "Amaga ilk kasede")
	# Demir Diş'te 16 esir ve 2 nöbetçi.
	var iron := 0
	for i in _members(layer, "column") + _members(layer, "column_escort"):
		if layer.field.position_of(i).x < -250.0:
			iron += 1
	assert_eq(iron, 18, "Demir Diş'te gündüz 16 esir ve 2 nöbetçi")
	# 13:00: Amaga yurdunda (görünmez).
	await _jump(layer, "13:00")
	assert_false(amaga.visible, "Amaga yurdunda")
	# 20:30: gece; dokuz nöbet, Çukur'da 31 esir, pazar boş.
	await _jump(layer, "20:30")
	var guards := 0
	for i in layer.members.size():
		var m: Dictionary = layer.members[i]
		if str(m["kind"]) == "person" and str(m["ref"]).begins_with("guard_wf") and layer.field.state_of(i) != CrowdPlan.State.ABSENT:
			guards += 1
	assert_eq(guards, 9, "Gece dokuz nöbet")
	var hollow := 0
	for i in _members(layer, "hollow") + _members(layer, "column"):
		var p := layer.field.position_of(i)
		if layer.field.state_of(i) != CrowdPlan.State.ABSENT and absf(p.x - 92.0) <= 60.0 and absf(p.z - 165.0) <= 45.0:
			hollow += 1
	assert_eq(hollow, 31, "Esir Çukuru'nda 31 esir")
	var night_market := 0
	for i in market:
		if layer.field.state_of(i) != CrowdPlan.State.ABSENT:
			night_market += 1
	assert_eq(night_market, 0, "Gece pazar boş")
	assert_true(int(layer.counts()["t0"]) <= FolkLayer.T0_CAP)
	await _release(layer)


func test_people_never_outrun_the_player() -> void:
	var layer := await _layer("16:50")
	# Akşamüstü (16:50 → 17:30): kol dönüşe çıkar, kasabalılar Mutfak'a yürür; saat olağan akar (dt 1/30 sn, 40 oyun dk).
	for f in 3000:
		layer._process(1.0 / 30.0)
	assert_true(layer.field.peak_speed <= PaceLimit.ADULT_RUN + PaceLimit.TOLERANCE, "Kalabalık ≤ oyuncunun koşusu (%.2f)" % layer.field.peak_speed)
	assert_true(layer.field.peak_speed <= 1.4 * 1.5 + 0.01, "Yetişme yürüyüşün 1,5 katı (%.2f)" % layer.field.peak_speed)
	assert_true(layer.peak_speed <= PaceLimit.ADULT_RUN + PaceLimit.TOLERANCE, "Tam kişiler ≤ oyuncunun koşusu (%.2f)" % layer.peak_speed)
	var walking := 0
	for i in _members(layer, "column"):
		if layer.field.state_of(i) == CrowdPlan.State.WALK:
			walking += 1
	assert_eq(walking, 16, "17:30'da kol yolda")
	await _release(layer)


func test_cart_driver_is_never_doubled() -> void:
	# Tek Kantu (travel.md §5.3 madde 6, act1.md §5): araba iş başındayken (Travel.on_duty: çağrıldı, bekliyor, seferde, dönüyor) ve programın
	# «cart» işinde (10:30–13:23, Kantu'nun çevrimi) Kantu arabadadır, katman onu gizler; araba bırakınca planının yerinde belirir.
	var layer := await _layer("09:00")
	var kantu := layer.avatar_of("kantu")
	assert_not_null(kantu, "Kantu tam kişi")
	if kantu == null:
		await _release(layer)
		return
	layer._process(1.0 / 60.0)
	assert_true(kantu.visible, "09:00 Kantu Menzil'de")
	var travel := Travel.new()
	travel.define(MapLayers.read("res://data/maps/kislak/travel.json"))
	assert_eq(travel.driver, "kantu", "Arabanın sürücüsü (travel.json cart.driver)")
	layer.travel_override = travel
	travel.on_duty = true
	layer._process(1.0 / 60.0)
	assert_false(kantu.visible, "Araba iş başında: Kantu arabada, burada yok")
	travel.on_duty = false
	layer._process(1.0 / 60.0)
	assert_true(kantu.visible, "Araba bırakınca yerinde")
	var plan: Vector2 = layer.schedule.state_of("kantu")["pos"]
	assert_true(Vector2(kantu.global_position.x, kantu.global_position.z).distance_to(plan) < 0.1, "Planının yerinde belirir (yürümez)")
	await _jump(layer, "11:00")
	assert_eq(str(layer.schedule.state_of("kantu")["job"]), "cart", "11:00 Kantu'nun çevrimi")
	assert_false(kantu.visible, "Çevrimde Kantu arabadadır (araba E'nin; çevrimin yerine yürümez)")
	await _release(layer)


func _layer(time: String) -> FolkLayer:
	var world := Node3D.new()
	world.name = "World"
	add_child(world)
	_trash.append(world)
	var def := MapLayers.read("res://data/maps/kislak/folk.json")
	def["local_clock"] = {"day": DAY_II, "time": time}
	var layer := FolkLayer.new()
	layer.setup(world, def)
	world.add_child(layer)
	for i in 240:
		if layer.is_built():
			break
		await wait_frames(1)
	layer.set_process(false)
	return layer


## Dünyayı test içinde bırakır: avatarların geçiş arası (zemin payının 0,25 sn'lik tween'i) koşunun sonuna kalmasın.
func _release(layer: FolkLayer) -> void:
	layer.get_parent().queue_free()
	await get_tree().create_timer(0.35).timeout


## Saati ileri alır ve herkesi planının yerine oturtur (sahne atlanınca olduğu gibi).
func _jump(layer: FolkLayer, time: String) -> void:
	var m := GameClock.parse_hhmm(time)
	var target := GameClock.abs_of(layer.clock.day_n, m)
	if target <= layer.clock.abs_minute():
		target += 1440.0
	layer.clock.set_to(target, &"dev")
	layer.snap()
	layer._process(1.0 / 60.0)
	layer._process(1.0 / 60.0)


func _members(layer: FolkLayer, group: String) -> Array[int]:
	var out: Array[int] = []
	for i in layer.members.size():
		var m: Dictionary = layer.members[i]
		if str(m["kind"]) == "group" and str(layer.schedule.crowd[int(m["ref"])]["group"]) == group:
			out.append(i)
	return out
