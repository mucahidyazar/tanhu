extends TestCase
## Kışlak'a geçiş (act-1-p2 çıkış ölçütü; godot.md §4.3, §9.5; K63, K64, K102): gerçek ana sahnede kamp → Kışlak → kamp. WorldHost kampı
## bırakır, Kışlak'ı (scenes/maps/kislak.tscn, pişmiş zemin, GPU parçaları, navmesh karoları) yükleyip kurar; dönüşte kamp pişmiş
## parçalarıyla yeniden kurulur. Süreler: iç harita ≤6 sn, kampa dönüş karartma altında ≤2 sn ([kislak-swap] satırları; başsızda boş
## çizici; pencerede main.gd --state=kislak --swap-probe). Köprü 2'nin önyüklediği sahne (K102, take_preloaded) enter_map'e verilince sahne
## yeniden istenmez. Oluşturulan Mete Rehine Yurdu'nun kapısında belirir, ışık oturumun saatine bağlanır (MapSky), kenar ve kamera kutusu
## haritanındır.

const MAIN_SCENE := "res://scenes/main.tscn"
const TempDir := preload("res://tests/support/temp_dir.gd")
const MAP_LOAD_MS := 6000.0
const CAMP_RETURN_MS := 2000.0

var _dir := ""


func before_each() -> void:
	MenuStyle.muted = true
	_dir = TempDir.fresh("kislak_gecisi")


func after_each() -> void:
	get_tree().paused = false
	TempDir.wipe(_dir)


func _new_main() -> Node:
	var main = load(MAIN_SCENE).instantiate()
	main.quit_handler = func() -> void: pass
	main.saves = SaveSystem.new(_dir)
	main.prologue_path = ""
	add_child(main)
	return main


func test_camp_to_kislak_to_camp_within_targets() -> void:
	var main = _new_main()
	await wait_frames(3)
	main.menu.finish_intro()
	await _wait_until(func() -> bool: return main.world.is_built(), 10.0)
	await wait_frames(5)
	await main._dev_testmap({}, MapSpec.KISLAK)
	assert_eq(main.state, main.State.PLAYING, "Kışlak'ta oyun")
	var map: MapWorld = main._map_world
	assert_true(map is MapWorld and map.spec.id == MapSpec.KISLAK, "Açık iç harita Kışlak")
	if map == null:
		main.queue_free()
		await _silence_audio()
		return
	assert_true(map.used_bake, "Pişmiş parçalarla kuruldu")
	var enter: Dictionary = main.world_host.last_swap
	assert_true(float(enter.get("total_ms", INF)) <= MAP_LOAD_MS, "Kışlak ≤6 sn'de yüklendi (%.0f ms)" % float(enter.get("total_ms", INF)))
	print("[kislak-swap] yükleme %.0f ms (bırakma %.0f, yükleme %.0f, kurulum %.0f)" % [enter["total_ms"], enter["free_ms"], enter["wait_ms"],
		enter["build_ms"]])
	var start: Vector2 = map.spec.spawn("start")["at"]
	var p: Vector3 = main.player.global_position
	assert_true(Vector2(p.x, p.z).distance_to(start) < 1.0, "Mete Rehine Yurdu'nun kapısında")
	assert_almost(p.y, map.ground.height_at(p.x, p.z), 0.2, "Mete zeminde")
	assert_true(main.session != null and int(main.session.clock.day_n) == 1041, "Saat Gün I (1.041)")
	var sky := map.get_node_or_null(^"MapSky") as MapSky
	assert_true(sky != null and sky.last_fed.x == 1041.0, "Işık oturumun saatine bağlı (MapSky)")
	assert_eq(main.player.terrain_shape, map.ground, "Oyuncunun zemini Kışlak'ın yüzü")
	assert_true(main.follow_camera.transform_filter.is_valid(), "Kamera kutusu haritanın")
	await main._leave_map()
	var back: Dictionary = main.world_host.last_swap
	assert_eq(str(back.get("kind", "")), "camp")
	assert_true(float(back.get("total_ms", INF)) <= CAMP_RETURN_MS, "Kampa dönüş ≤2 sn (%.0f ms)" % float(back.get("total_ms", INF)))
	print("[kislak-swap] kampa dönüş %.0f ms (bırakma %.0f, yükleme %.0f, kurulum %.0f)" % [back["total_ms"], back["free_ms"], back["wait_ms"],
		back["build_ms"]])
	assert_true(main.world is World and main.world.is_built(), "Kamp yeniden kuruldu")
	assert_eq(WorldHost.static_cache_size() > 0, true, "Kampın önbellekleri yeniden doldu")
	main.queue_free()
	await _silence_audio()


func test_preloaded_scene_is_taken_without_a_second_request() -> void:
	var main = _new_main()
	await wait_frames(3)
	main.menu.finish_intro()
	await _wait_until(func() -> bool: return main.world.is_built(), 10.0)
	var spec := MapSpec.find(MapSpec.KISLAK)
	# Köprü 2'nin önyüklemesi (K102): sahne önceden alınmış PackedScene olarak verilir; konak onu yeniden istemez.
	var preloaded := load(spec.scene) as PackedScene
	main.state = main.State.BUSY
	var map: MapWorld = await main.world_host.enter_map(spec, preloaded)
	assert_not_null(map, "Önyüklenen sahneyle kuruldu")
	assert_false(main.world_host._requests.has(spec.scene), "Sahne ikinci kez istenmedi")
	if map:
		assert_eq(map.spec.id, MapSpec.KISLAK)
		assert_true(map.is_ready())
	await main.world_host.return_to_camp()
	main.state = main.State.MENU
	main.queue_free()
	await _silence_audio()


func _wait_until(condition: Callable, timeout: float) -> void:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame


func _silence_audio() -> void:
	var audio := get_node_or_null(^"/root/AudioManager")
	if audio:
		for p in audio.get_children():
			if p is AudioStreamPlayer:
				(p as AudioStreamPlayer).stop()
				(p as AudioStreamPlayer).stream = null
	await get_tree().create_timer(0.25).timeout
