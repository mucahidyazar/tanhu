extends TestCase
## Dünya değişimi (Yol Haritası world-swap; godot.md §4.3, §8.4; K63, K64): gerçek ana sahnede kamp → deneme haritası → kamp. WorldHost
## kampı bırakır (Main/World ağaçtan çıkar, statik önbellekler boşalır, world, player.world ve cine.world boşalır), haritayı arka planda
## yükleyip kurar; dönüşte kamp pişmiş parçalarıyla (tools/bake_map.gd) Main/World'e yeniden oturur. Süreler kaydedilir ([world-swap]
## satırları): iç harita yüklemesi ≤6 sn, kampa dönüş karartma altında ≤2 sn. Sızıntı: iki tur arasında düğüm, öksüz düğüm, kaynak ve
## nesne sayısı büyümez, doku belleği (RENDER_TEXTURE_MEM_USED; başsızda boş çizici, pencerede main.gd --swap-probe) tabana döner, statik
## önbellekler bırakınca boştur. Haritada oluşturulan Mete oynar (mete-playable): profilin görünüşü, Kışlak Kaftanı ve Kışlak Pelerini, boya;
## yürür, koşar, zıplar, ata biner, atla sıçrar, iner. Kapılar ve «Ana Menü» kampa döner; haritada kayıt v2'nin map bloğuyla yazılır («Ana Menü»
## to_menu, kapı world); Serbest Gez'de Çocuk kalır (K37).

const MAIN_SCENE := "res://scenes/main.tscn"
const TempDir := preload("res://tests/support/temp_dir.gd")
## Hedefler (ms; K63, K64): iç harita yüklemesi ve kampa dönüş (karartma altında).
const MAP_LOAD_MS := 6000.0
const CAMP_RETURN_MS := 2000.0
## İki tur arasında izin verilen büyüme: nesne (yükleme belirteçleri, zamanlayıcılar) ve kaynak (önbelleğe giren küçük kaynaklar).
const OBJECT_SLACK := 40
const RESOURCE_SLACK := 12

var _dir := ""


func before_each() -> void:
	MenuStyle.muted = true
	_dir = TempDir.fresh("dunya_degisimi")


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


func test_camp_parts_come_from_the_bake() -> void:
	var main = _new_main()
	await wait_frames(3)
	await _wait_until(func() -> bool: return main.world.is_built(), 10.0)
	assert_not_null(main.world_host, "WorldHost kuruldu")
	assert_eq(main.world_host.camp, main.world, "Konağın kampı Main/World")
	assert_eq(main.world.get_parent(), main, "Kamp Main'in çocuğu")
	assert_eq(main.world.name, &"World")
	for part in ["Terrain", "Meadow", "Forest"]:
		assert_true(bool(main.world.get_node(part).get(&"used_bake")), "Kampın %s parçası pişmiş haliyle kuruldu (imza tuttu)" % part)
	main.queue_free()
	await _silence_audio()


func test_camp_to_testmap_to_camp_without_leaks() -> void:
	var main = _new_main()
	await wait_frames(3)
	main.menu.finish_intro()
	await _wait_until(func() -> bool: return main.world.is_built(), 10.0)
	await wait_frames(10)
	var counts: Array[Dictionary] = [_counts()]
	for round in 3:
		var camp_before: World = main.world
		await main._dev_testmap({})
		assert_eq(main.state, main.State.PLAYING, "Deneme haritasında oyun")
		assert_true(main._map_world is MapWorld, "Açık iç harita")
		var map: MapWorld = main._map_world
		if map == null:
			break
		assert_true(map.is_ready() and map.used_bake, "Harita pişmiş parçalarıyla kuruldu")
		assert_true(main.world_host.in_map(), "Konak haritada")
		assert_null(main.world, "Kamp bellekte değil: world boş")
		assert_null(main.player.world, "Oyuncunun kamp başvurusu boş")
		assert_null(main.cine.world, "Sinemanın kamp başvurusu boş")
		assert_false(is_instance_valid(camp_before), "Eski kamp bırakıldı")
		assert_null(main.get_node_or_null(^"World"), "Main/World yok")
		var enter: Dictionary = main.world_host.last_swap
		assert_eq(str(enter.get("kind", "")), "map")
		assert_true(float(enter.get("total_ms", INF)) <= MAP_LOAD_MS, "İç harita ≤6 sn'de yüklendi (%.0f ms)" % float(enter.get("total_ms", INF)))
		print("[world-swap] %d. tur: iç harita yüklemesi %.0f ms (bırakma %.0f, yükleme %.0f, kurulum %.0f)" % [round + 1, enter["total_ms"],
			enter["free_ms"], enter["wait_ms"], enter["build_ms"]])
		await _open_pause(main)
		assert_eq(main.pause_menu.save_note, "", "Haritada KAYDET açık (kayıt v2'nin map bloğu)")
		var book: GameMenu = main.pause_menu.get_menu()
		book._on_general("main")
		await _wait_for_state(main, main.State.MENU, 12.0)
		assert_eq(main.state, main.State.MENU, "Açılış ekranı")
		_assert_camp_back(main)
		var back: Dictionary = main.world_host.last_swap
		assert_eq(str(back.get("kind", "")), "camp")
		assert_true(float(back.get("total_ms", INF)) <= CAMP_RETURN_MS, "Kampa dönüş karartma altında ≤2 sn (%.0f ms)" % float(back.get("total_ms", INF)))
		print("[world-swap] %d. tur: kampa dönüş %.0f ms (bırakma %.0f, yükleme %.0f, kurulum %.0f)" % [round + 1, back["total_ms"],
			back["free_ms"], back["wait_ms"], back["build_ms"]])
		await wait_frames(10)
		counts.append(_counts())
	var auto: Dictionary = main.saves.slot_info(SaveSystem.AUTO_SLOT)
	assert_eq(str(auto.get("reason", "")), "to_menu", "Haritadan «Ana Menü» oto kayıt yazar")
	assert_eq(str(((auto.get("blocks", {}) as Dictionary).get("map", {}) as Dictionary).get("id", "")), "testmap", "Kaydın map bloğu haritayı söyler")
	print("[world-swap] sayılar (başta, her turdan sonra): %s" % [counts])
	if counts.size() == 4:
		# Bir turun bıraktığı büyüme yok: ikinci ve üçüncü tur aynı yere döner (ilk tur duraklatma kitabını tembel kurar).
		var a: Dictionary = counts[2]
		var b: Dictionary = counts[3]
		assert_eq(b["nodes"], a["nodes"], "Düğüm sayısı tabana döndü")
		assert_eq(b["orphans"], counts[0]["orphans"], "Öksüz düğüm birikmedi")
		assert_true(absi(b["resources"] - a["resources"]) <= RESOURCE_SLACK, "Kaynak sayısı tabana döndü (%d → %d)" % [a["resources"], b["resources"]])
		assert_true(absi(b["objects"] - a["objects"]) <= OBJECT_SLACK, "Nesne sayısı tabana döndü (%d → %d)" % [a["objects"], b["objects"]])
		assert_true(absf(b["texture"] - a["texture"]) <= 1.0, "Doku belleği tabana döndü")
	main.queue_free()
	await _silence_audio()


func test_gate_returns_to_the_title() -> void:
	var main = _new_main()
	await wait_frames(3)
	main.menu.finish_intro()
	await wait_frames(1)
	await main._dev_testmap({"spawn": "east_gate"})
	assert_eq(main.state, main.State.PLAYING)
	var map: MapWorld = main._map_world
	var gate := map.spec.gate("east_gate")
	var gate_at: Vector3 = map.on_ground(gate["at"])
	assert_false(main._gate_armed, "Kapının yanında belirince kapı hemen işlemez")
	# Kapının alanının içinde belirilirse de beklenir: önce dışarı çıkılır.
	main.player.spawn_at(gate_at, PI * 0.5)
	await get_tree().create_timer(main.FLAG_CHECK_INTERVAL * 2.5).timeout
	assert_eq(main.state, main.State.PLAYING, "Silahsız kapı işlemedi")
	main.player.spawn_at(gate_at + Vector3(-float(gate["radius"]) - 6.0, 0.0, 0.0), PI * 0.5)
	await get_tree().create_timer(main.FLAG_CHECK_INTERVAL * 2.5).timeout
	assert_true(main._gate_armed, "Kapının alanından çıkınca kapı kurulur")
	main.player.spawn_at(gate_at, PI * 0.5)
	await _wait_for_state(main, main.State.MENU, 12.0)
	assert_eq(main.state, main.State.MENU, "Doğu Kapısı açılış ekranına döndü")
	_assert_camp_back(main)
	var auto: Dictionary = main.saves.slot_info(SaveSystem.AUTO_SLOT)
	assert_eq(str(auto.get("reason", "")), "world", "Kapı dünya değişimidir: zorunlu oto kayıt «world»")
	var place: Dictionary = (auto.get("blocks", {}) as Dictionary).get("map", {})
	assert_eq(str(place.get("id", "")), "testmap", "Kayıt haritada, kapının yanında")
	if place.get("pos") is Array:
		assert_true(_flat(Vector3(place["pos"][0], 0.0, place["pos"][2]), gate_at) <= float(gate["radius"]) + 0.5, "Kaydın yeri kapının alanı")
	main.queue_free()
	await _silence_audio()


func test_testmap_mete_walks_runs_jumps_and_rides() -> void:
	var main = _new_main()
	await wait_frames(3)
	main.menu.finish_intro()
	await wait_frames(1)
	var dye_before: int = main.profile.cape_dye
	await main._dev_testmap({"dye": "4"})
	assert_eq(main.state, main.State.PLAYING)
	var map: MapWorld = main._map_world
	var player: PlayerController = main.player
	# Oluşturulan Mete (K37: Çocuk değil), oyuncunun kılığıyla: Kışlak Kaftanı ve Kışlak Pelerini, boya --dye ile (yazılmaz).
	assert_false(player.is_child(), "Haritada oluşturulan Mete")
	var avatar := player.get_avatar()
	assert_eq(avatar.worn_outfit(), CharacterOptions.start_outfit(), "Kışlak Kaftanı")
	assert_eq(avatar.worn_cape(), CharacterOptions.start_cape(), "Kışlak Pelerini")
	assert_eq(avatar.get_cape_color(), CharacterOptions.cape_tint(CharacterOptions.start_cape(), 4), "Pelerin seçilen boyada (Menekşe)")
	assert_eq(main.profile.cape_dye, dye_before, "Profilin boyasına yazılmadı")
	assert_eq(player.terrain_shape, map.get_terrain_shape(), "Zemin haritanın")
	assert_eq(main.follow_camera.terrain_shape, map.get_terrain_shape())
	assert_true(main.follow_camera.transform_filter.is_valid(), "Kamera kutusu")
	assert_almost(player.play_area_radius, map.spec.play_radius, 0.001, "Yürünür alan haritanın")
	var start := map.spawn("start")
	assert_true(_flat(player.global_position, start["at"]) < 0.6, "Belirme yerinde")
	assert_almost(player.global_position.y, map.ground.height_at(player.global_position.x, player.global_position.z), 0.02, "Zeminde")
	# Yük yürüyüşü yavaşlatır (economy.md §4.1; oturumun envanteri): haritanın katmanlarının deneme takımı sandığa konur, hareket yüksüz
	# ölçülür.
	await _wait_until(func() -> bool: return main.gameplay_hud.is_shown(), 4.0)
	await wait_frames(10)
	var inv: Inventory = main.session.inventory if main.session else main.gameplay_hud.bag.inventory
	inv.move_all(inv.pack, inv.chest, null, Callable(), true)
	await wait_frames(1)
	assert_almost(player.load_speed_k(), 1.0, 1e-9, "Heybe boşken yük yok")
	# Yürür ve koşar (kameraya göre ileri: kuzey).
	player.set_active(false)
	player.auto_move = Vector2(0.0, 1.0)
	await get_tree().create_timer(1.2).timeout
	assert_almost(player.get_speed(), player.walk_speed, 0.25, "Yürür")
	player.auto_sprint = true
	await get_tree().create_timer(1.2).timeout
	assert_almost(player.get_speed(), player.run_speed, 0.4, "Koşar")
	assert_almost(player.global_position.y, map.ground.height_at(player.global_position.x, player.global_position.z), 0.05, "Zemini izler")
	assert_true(player.jump(), "Koşarken zıplar")
	assert_true(player.is_jumping(), "Zıplıyor")
	await _wait_until(func() -> bool: return not player.is_jumping(), 3.0)
	player.auto_move = Vector2.ZERO
	player.auto_sprint = false
	await get_tree().create_timer(0.6).timeout
	# Ata biner: Doru'nun yanına, E.
	var horse := map.horse("doru")
	assert_not_null(horse, "Doru haritada")
	if horse == null:
		main.queue_free()
		await _silence_audio()
		return
	assert_true(horse.is_in_group(Rideable.GROUP), "Binilir")
	player.spawn_at(horse.global_position + horse.global_basis.x * 1.1, horse.rotation.y)
	await wait_frames(2)
	assert_eq(player.mount_in_reach(), horse, "At erimde")
	assert_true(player.interact(), "E ile biner")
	await _wait_until(func() -> bool: return player.is_riding(), 4.0)
	assert_true(player.is_riding(), "Sırtta")
	# Doğu Yolu'na doğru (ekranda sağ): önü açık bozkır.
	main.follow_camera.set_yaw(0.0, true)
	player.auto_move = Vector2(1.0, 0.0)
	player.auto_sprint = true
	await get_tree().create_timer(3.5).timeout
	assert_eq(player.mount_gait(), "gallop", "Dörtnal")
	assert_true(player.velocity.length() > RideableHorse.GALLOP_FROM, "Dörtnalın hızı (%.1f m/sn)" % player.velocity.length())
	assert_almost(horse.global_position.y, map.ground.height_at(horse.global_position.x, horse.global_position.z), 0.1, "At zeminde")
	assert_true(player.jump(), "Atla sıçrar")
	await _wait_until(func() -> bool: return not horse.is_leaping(), 4.0)
	player.auto_move = Vector2.ZERO
	player.auto_sprint = false
	await _wait_until(func() -> bool: return player.get_speed() < 0.2, 4.0)
	assert_true(player.interact(), "E ile iner")
	await _wait_until(func() -> bool: return not player.is_riding() and player.get_stance() == PlayerController.Stance.FOOT, 4.0)
	assert_false(player.is_riding(), "İndi")
	await _open_pause(main)
	main.pause_menu.get_menu()._on_general("main")
	await _wait_for_state(main, main.State.MENU, 12.0)
	assert_eq(main.state, main.State.MENU)
	main.queue_free()
	await _silence_audio()


func test_free_roam_after_the_testmap_walks_the_child() -> void:
	var main = _new_main()
	await wait_frames(3)
	main.menu.finish_intro()
	await wait_frames(1)
	await main._dev_testmap({})
	assert_false(main.player.is_child(), "Haritada Mete")
	await main._return_to_title()
	assert_eq(main.state, main.State.MENU)
	_assert_camp_back(main)
	main.menu.free_roam_requested.emit()
	await _wait_for_state(main, main.State.PLAYING, 8.0)
	assert_eq(main.state, main.State.PLAYING, "Serbest Gez")
	assert_true(main.player.is_child(), "Serbest Gez'de Çocuk (K37)")
	assert_eq(main.player.terrain_shape, main.world.get_terrain_shape(), "Zemin yeni kampın")
	assert_false(main.follow_camera.transform_filter.is_valid(), "Kamera kutusu kalktı")
	var npcs := main.world.get_node_or_null(^"Camp/CampNpcs") as CampNpcs
	assert_not_null(npcs, "Yeni kampta ateş başı")
	assert_true(main.player.obstacles.size() > 0, "Engeller yeni kampın")
	main.queue_free()
	await _silence_audio()


func test_static_caches_are_released_with_the_world() -> void:
	# Kamp kuruluyken önbellekler doludur; bırakılınca boşalır, yeniden kurulunca dolar.
	var main = _new_main()
	await wait_frames(3)
	main.menu.finish_intro()
	await _wait_until(func() -> bool: return main.world.is_built(), 10.0)
	assert_true(WorldHost.static_cache_size() > 0, "Kampın önbellekleri dolu")
	main.state = main.State.BUSY
	var map: MapWorld = await main.world_host.enter_map(MapSpec.find(MapSpec.TESTMAP))
	assert_not_null(map)
	# Harita kendi modellerini (yurt, kaya, çam) önbelleğe koyar; kampa özgü olanlar (ahır, kopuz, kazan, ladin LOD zinciri) kalmaz.
	var camp_only := ["/structures/stable/", "/props/kopuz/", "/props/cauldron/", "/props/weapon_rack/"]
	assert_eq(_cached_textures(camp_only), PackedStringArray(), "Kampa özgü dokular önbellekte kalmadı")
	assert_eq(TreeKit._lods.size(), 0, "Kampın LOD zincirleri bırakıldı")
	await main.world_host.return_to_camp()
	assert_true(main.world_host.has_camp() and not main.world_host.in_map())
	var map_only := ["/_free/texture/withered_grass/"]
	for path in map_only:
		assert_false(ResourceLoader.has_cached(path + "withered_grass_diff_2k.jpg"), "Haritanın zemin dokusu bırakıldı")
	main.state = main.State.MENU
	main.queue_free()
	await _silence_audio()


# --- Yardımcılar ---------------------------------------------------------------------------------

## MeshyProp'un önbelleğindeki malzemelerin dokularından parçalardan birini taşıyanlar.
static func _cached_textures(fragments: Array) -> PackedStringArray:
	var out := PackedStringArray()
	for mat: Variant in MeshyProp._material_cache.values():
		var tex := (mat as ShaderMaterial).get_shader_parameter(&"albedo_texture") as Texture2D if mat is ShaderMaterial else null
		if tex == null:
			continue
		for f: String in fragments:
			if tex.resource_path.contains(f):
				out.append(tex.resource_path)
	return out


func _assert_camp_back(main: Node) -> void:
	assert_true(main.world is World and is_instance_valid(main.world), "Kamp yeniden kuruldu")
	if not (main.world is World):
		return
	assert_eq(main.world.name, &"World", "Main/World")
	assert_eq(main.get_node_or_null(^"World"), main.world)
	assert_eq(main.world.get_index(), 0, "Kamp eski yerinde (Main'in ilk çocuğu)")
	assert_eq(main.player.world, main.world, "Oyuncu yeni kampa bağlı")
	assert_eq(main.cine.world, main.world, "Sinema yeni kampa bağlı")
	assert_null(main._map_world, "Harita bırakıldı")
	assert_false(main.world_host.in_map())
	assert_true(main.world.is_built(), "Kamp kuruldu")
	assert_true(main.world.visible and main.world.process_mode == Node.PROCESS_MODE_INHERIT, "Kamp görünür, süreci sürer")
	for part in ["Terrain", "Meadow", "Forest"]:
		assert_true(bool(main.world.get_node(part).get(&"used_bake")), "Yeni kampın %s parçası pişmiş" % part)
	assert_true(main.menu_camera.current, "Menü kamerası")
	assert_false(main.follow_camera.transform_filter.is_valid(), "Kamera kutusu kalktı")
	assert_eq(main.get_tree().get_nodes_in_group(Rideable.GROUP).filter(func(n: Node) -> bool: return n is RideableHorse and not main.world.is_ancestor_of(n)).size(), 0, "Haritanın atları gitti")


func _counts() -> Dictionary:
	return {
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"orphans": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		"resources": int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"texture": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
	}


func _open_pause(main: Node) -> void:
	main.player.pause_requested.emit()
	await _wait_until(func() -> bool: return main.pause_menu.is_open(), 3.0)
	await wait_frames(2)


func _wait_for_state(main: Node, wanted: int, timeout: float) -> void:
	await _wait_until(func() -> bool: return main.state == wanted, timeout)


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


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
