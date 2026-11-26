extends TestCase
## Kışlak'ın Menzil ağı ve ahırı (act-1-p2; Yol Haritası roads-relays, mount-bond-actions): gerçek ana sahnede --state=kislak yolu. Yol ağı
## arazinin yol dosyasından kurulur (23 kenar), 8 Menzil ve 14 Yol Kemiği (direkler yolun yanında, arabanın yolunda değil), Kantu'nun arabası
## Kışlak Menzili'nde; ahırda Yakve ve 8 at. Kesim Yeri'ne Yolu Kısalt'la sefer (rütbe 2, Kantu'nun çetelesi): araba Kesim Yeri'nin
## durağına varır, saat kalan doğal süre kadar atlar; araba seferdeyken ahırdaki Yakve görünmez (Yakve tektir).

const MAIN_SCENE := "res://scenes/main.tscn"
const TempDir := preload("res://tests/support/temp_dir.gd")
const DT := 1.0 / 30.0

var _dir := ""


func before_each() -> void:
	MenuStyle.muted = true
	_dir = TempDir.fresh("kislak_menzil")


func after_each() -> void:
	get_tree().paused = false
	TempDir.wipe(_dir)


func test_kislak_network_stable_and_a_trip() -> void:
	if MapSpec.find(MapSpec.KISLAK) == null or not ResourceLoader.exists("res://scenes/maps/kislak.tscn"):
		print("    atlandı: Kışlak yok")
		return
	var main = load(MAIN_SCENE).instantiate()
	main.quit_handler = func() -> void: pass
	main.saves = SaveSystem.new(_dir)
	main.prologue_path = ""
	add_child(main)
	await wait_frames(3)
	main.menu.finish_intro()
	await wait_frames(1)
	await main._dev_testmap({"flags": "tally_kantu,rank_2"}, MapSpec.KISLAK)
	var map: MapWorld = main._map_world
	assert_not_null(map, "Kışlak açıldı")
	if map == null:
		main.queue_free()
		return
	var layer := map.get_node_or_null(^"Layers/Travel") as TravelLayer
	var stable := map.get_node_or_null(^"Layers/Stable") as StableLayer
	assert_not_null(layer, "Menzil katmanı")
	assert_not_null(stable, "Ahır katmanı")
	if layer == null or stable == null:
		main.queue_free()
		return
	await _wait_until(func() -> bool: return layer._attached and stable._attached, 6.0)
	layer.set_process(false)
	assert_eq(layer.graph.edges.size(), 23, "Arabanın 23 kenarı (travel.md §4.1)")
	assert_eq(layer.station_ids().size(), 8, "8 Menzil")
	assert_eq(layer.posts.bones.size(), 14, "14 Yol Kemiği")
	for id: String in layer.travel.bone_defs:
		var p := layer.bone_point(id)
		var near := layer.graph.nearest_edge(p)
		assert_true(float(near["d"]) > 2.0, "%s yolun yanında (%.1f m)" % [id, float(near["d"])])
	var scape := map.get_node_or_null(^"Soundscape") as MapSoundscape
	if scape:
		assert_true(scape.repaired.is_valid(), "Ses profili Yol Kemiklerinin onarımını okur")
		assert_false(layer.posts.own_hum, "Uğultuyu ses profili çalar (çift ses yok)")
	assert_eq(layer.cart_station, "way_camp", "Araba Kışlak Menzili'nde")
	var sched := main.session.get_system(&"schedule") as Schedule
	layer._step_cart(DT)
	assert_false(layer.travel.on_duty, "Duran araba iş başında değil")
	if sched and sched.people.has("kantu"):
		assert_false(layer.cart.driver.visible, "Dururken Kantu programdadır (Menzil, turu, barınak): arabada ikinci Kantu yok")
	assert_true(layer.cart.axle_xz().distance_to(Vector2(57.9, 20.4)) < 0.3, "Dingil durağın noktasında")
	# Programın «cart» işi (10:30–13:23, Kantu'nun çevrimi): kişi arabadadır; araba durakta dururken sürücü yerinde, kişi katmanı onu gizler.
	var folk := map.get_node_or_null(^"Layers/Folk") as FolkLayer
	if sched and sched.people.has("kantu"):
		main.session.clock.set_to(GameClock.abs_of(main.session.clock.day_n + 1, 11.0 * 60.0), &"dev")
		await wait_frames(2)
		assert_eq(str(sched.state_of("kantu").get("job", "")), "cart", "11:00 Kantu'nun çevrimi")
		layer._step_cart(DT)
		assert_true(layer.cart.driver.visible, "Çevrimde Kantu arabada")
		if folk and folk.avatar_of("kantu"):
			assert_false(folk.avatar_of("kantu").visible, "Kişi katmanında Kantu yok: tek Kantu")
	assert_eq(stable.horses.size(), 9, "Ahırda Yakve ve 8 at")
	# Sekiz at yapı kitinin ahırının bölmelerinde (StructureKit.stable_stalls), Yakve kapının önünde.
	var stalls := StructureKit.stable_stalls(map.spec.structure("stable"))
	var at_stall := 0
	for k: String in stable.horses:
		var hn: Node3D = stable.horses[k]["node"]
		for st: Dictionary in stalls:
			if Vector2(hn.global_position.x, hn.global_position.z).distance_to(st["at"]) < 0.3:
				at_stall += 1
	assert_eq(at_stall, 8, "Sekiz at ahırın bölmelerinde")
	var yakwe: Rideable = stable.horses.get("yakwe@Yakwe", {}).get("node")
	assert_not_null(yakwe, "Yakve ahırda")
	assert_eq(stable.horse_name("yakwe@Yakwe"), "Yakve", "Yakve'nin adı sabittir")
	assert_false(stable.can_name("yakwe@Yakwe"))
	assert_eq(stable.stable().gear_of("horse@StableHorse1", "bridle"), "", "Ahırın atı başı çıplak")
	# Kesim Yeri: bulunur, bağlanır (direği yok).
	var player: PlayerController = main.player
	player.spawn_at(map.on_ground(Vector2(425.0, 16.0)), 0.0)
	layer._discover()
	assert_eq(layer.travel.state_of("way_cut"), "linked", "Kesim Yeri bağlandı")
	# Kışlak Menzili'nde bulunur, biner, Kesim Yeri'ne Yolu Kısalt.
	player.spawn_at(map.on_ground(Vector2(58.0, 28.0)), PI)
	layer._discover()
	assert_eq(layer.travel.state_of("way_camp"), "linked")
	main.session.clock.set_to(GameClock.abs_of(main.session.clock.day_n + 1, 10.0 * 60.0), &"dev")
	assert_true(layer.strike("way_camp"), "Direğe vuruş")
	player.spawn_at(layer.cart.tail_point("S1", layer._ground()), layer.cart.heading + PI)
	assert_true(layer.board(), "Biner")
	_drive(layer, func() -> bool: return layer.state == TravelLayer.Cart.CARD, 3.0)
	assert_true(layer.travel.on_duty and layer.cart.driver.visible, "Araba iş başında, Kantu sürücü yerinde (program onu gizler: on_duty)")
	if folk and folk.avatar_of("kantu"):
		assert_true(folk.on_cart("kantu"), "Kişi katmanı arabanın iş başında olduğunu bilir")
		await wait_frames(2)
		assert_false(folk.avatar_of("kantu").visible, "Seferde kişi katmanında Kantu yok: tek Kantu")
	assert_true(main.session.is_paused_by(&"modal"), "Yol Kartı açıkken saat durur")
	assert_true(layer.depart("way_cut", "shorten"), "Kesim Yeri'ne kalkış")
	layer._step_cart(DT)
	assert_false(yakwe.visible, "Araba seferdeyken ahırdaki Yakve görünmez")
	var minute := float(main.session.clock.abs_minute())
	_drive(layer, func() -> bool: return layer.state == TravelLayer.Cart.WAITING, 40.0)
	assert_eq(layer.state, TravelLayer.Cart.WAITING, "Kesim Yeri'ne varıldı")
	var off := layer.cart.axle_xz().distance_to(Vector2(429.9, 8.4))
	assert_true(off < 2.5, "Araba Kesim Yeri'nin durağında (%.2f m)" % off)
	var jumped := float(layer.last_skip.get("minutes", 0.0))
	assert_true(jumped > 20.0, "372 m'lik yolun saati atladı (%.1f oyun dk)" % jumped)
	assert_true(float(main.session.clock.abs_minute()) - minute >= jumped - 0.01)
	var pos := player.global_position
	assert_almost(pos.y, map.ground.height_at(pos.x, pos.z), 0.1, "Oyuncu zeminde iner")
	main.queue_free()
	await wait_frames(2)


func _drive(layer: TravelLayer, until: Callable, seconds: float) -> float:
	var t := 0.0
	while not until.call() and t < seconds:
		layer._step_cart(DT)
		t += DT
	return t


func _wait_until(condition: Callable, timeout: float) -> void:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
