extends TestCase
## Deneme haritasının ateş ve av katmanı (Yol Haritası fire-hunting, hunger-wounds; map.json «layers», SurvivalLayer): gerçek ana sahnede
## deneme haritasında Mete'nin heybesine hafif deneme takımı girer (koşu ve zıplama açık; yedeği Doru'nun terkisinde; yalnız yeni
## yolculukta), HUD'da Tokluk çubuğu ve yara baklavaları görünür; Eski Ocak'ı 2 tezekle kavsız yakar (taşlı, kazan hazır), Y ile besler, E
## dokunuşuyla tarif çemberini açar, şişte Tam Vuruş'la ★3 pişirir ve ateş başında hemen yer; E 3 sn basılı Bekle tekerini Dinlen kipinde
## açar; haritanın ocağında (yerleşimin ocağı) pişirilir, Y ve F işlemez; uzakta Y yer seçer ve kurar (yeni ateş dolu yanar), F basılı
## söndürür (çukur kalır); kapandaki tarbaganı E basılı yüzer, verimi verim verim Heybe'ye girer; yer yığını leş sayılmaz (yalnız «Aç»);
## yara sınırı dolunca Umay Eşiği: kararma, son barınakta uyanış, saat +2, 1 erzak eksik, başucunda küçük ok ve yay.

const MAIN_SCENE := "res://scenes/main.tscn"
const TempDir := preload("res://tests/support/temp_dir.gd")

var _dir := ""


func before_each() -> void:
	MenuStyle.muted = true
	_dir = TempDir.fresh("ates_katmani")


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


func _wait_until(cond: Callable, seconds: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while not bool(cond.call()) and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	return bool(cond.call())


func _layer(main: Node) -> SurvivalLayer:
	var map: MapWorld = main._map_world
	return map.get_node_or_null(^"Layers/Survival") as SurvivalLayer if map else null


func _put(main: Node, xz: Vector2, yaw: float) -> void:
	var map: MapWorld = main._map_world
	main.player.spawn_at(map.on_ground(xz), yaw)
	await wait_frames(2)


func test_mete_lights_feeds_cooks_skins_and_falls_at_the_threshold() -> void:
	var main = _new_main()
	await wait_frames(3)
	main.menu.finish_intro()
	await wait_frames(1)
	# Sınama Normal zorlukta (oyuncunun profili başka zorlukta olabilir): yara sınırı 3, Düşüş bedeli 1 erzak, 1 yarayla uyanış.
	main.profile.difficulty = CharacterOptions.default_index(&"difficulty")
	assert_eq(main.profile.difficulty_id(), "normal")
	await main._dev_testmap({})
	assert_eq(main.state, main.State.PLAYING, "Deneme haritasında oyun")
	var layer := _layer(main)
	assert_not_null(layer, "Ateş ve av katmanı kuruldu (map.json «layers»)")
	if layer == null:
		main.queue_free()
		return
	assert_true(await _wait_until(func() -> bool: return layer.survival != null, 5.0), "Katman oyuncuya bağlandı")
	var s := layer.survival
	var inv: Inventory = main.gameplay_hud.bag.inventory
	assert_eq(inv.count("dung"), 8, "Deneme takımı Heybe'de")
	assert_true(inv.has_tool("firestriker"), "Çakmak taşı")
	assert_eq(inv.equipped("blade"), "knife_iron", "Bıçak kuşanılı")
	assert_true(inv.can_run() and inv.can_jump(), "Takım hafif: koşu ve zıplama açık (%.1f / %.1f Yük)" % [inv.load_amount(), inv.capacity()])
	var doru_bag := inv.saddlebags("horse@Doru")
	assert_true(doru_bag != null and doru_bag.count("branch") == 10 and doru_bag.count("wood_pine") == 2, "Yedek Doru'nun terkisinde")
	assert_true(layer.session != null and layer.session.fresh("inventory"), "Yeni yolculuk: takım verildi")
	var needs_hud := main.gameplay_hud.portrait.get_node_or_null(^"Needs") as HudNeeds
	assert_not_null(needs_hud, "HUD'da Tokluk ve yara (portrenin çocuğu)")
	assert_eq(needs_hud.bar_text(), "60", "Tokluk 60")
	assert_eq(needs_hud.diamonds(), [0, 3], "Normal'de üç baklava, boş")
	# Eski Ocak: 2 tezekle kavsız yanar, taşlıdır, kazan hazırdır.
	await _put(main, Vector2(-11.0, 5.0), PI)
	assert_eq(str(layer._near_target().get("kind", "")), "old", "Eski Ocak 3 m içinde")
	layer._on_y_pressed()
	var old := s.fires.by_id("old_hearth_west")
	assert_not_null(old, "Eski Ocak yandı")
	assert_true(old.is_lit() and old.stones and old.old)
	assert_eq(inv.count("dung"), 6, "İki tezek gitti")
	assert_eq(inv.count("tag:tinder"), 2, "Kav istemez")
	await wait_frames(2)
	var view := layer._views.get("old_hearth_west") as FireView
	assert_true(view != null and view.look()["light"], "Ateşin ışığı yanıyor")
	assert_eq(str(view.look()["stage"]), "steady", "360 sn: Orta")
	layer._on_y_pressed()
	assert_almost(old.fuel, 540.0, 2.0, "Y: +1 tezek (180 sn)")
	# Tarif çemberi (E dokunuşu): şiş ve kazan; şişte Tam Vuruş.
	assert_true(layer._on_e_pressed(), "E'nin ateş başında işi var")
	assert_null(layer._wheel, "Çember basışta değil, bırakışta açılır")
	layer._on_e_released()
	assert_not_null(layer._wheel, "E dokunuşu tarif çemberini açar")
	var ids: Array = layer._wheel.slots().map(func(o: Dictionary) -> String: return str(o["id"]))
	assert_true(ids.has("spit_meat") and ids.has("meal") and ids.has("share"), "Şiş, kazan, Ocağa Pay: %s" % [ids])
	layer._wheel.pick(ids.find("spit_meat"))
	assert_null(layer._wheel, "Seçince çember kapanır")
	assert_not_null(s.job, "Pişiyor")
	assert_true(main.player.is_seated(), "Pişirirken oyuncu oturur")
	s.job.t = s.job.T
	assert_true(layer._on_e_pressed(), "E: Tam Vuruş")
	assert_eq(inv.count("spit_meat"), 1, "Şiş Et Heybe'de")
	var before := s.needs.fullness
	layer._on_e_pressed()
	assert_almost(s.needs.fullness - before, 39.0, 0.5, "Ateş başında hemen yenince ★3: +39")
	# E 3 sn basılı: Bekle tekeri Dinlen kipinde (WaitWheel); halka E_TAP_S'den sonra dolar.
	var wheel: WaitWheel = main.wait_wheel
	Input.action_press(&"accept")
	assert_true(layer._on_e_pressed(), "Basılı tutuş başlar")
	await get_tree().create_timer(1.2).timeout
	assert_false(wheel.is_open(), "3 sn dolmadan açılmaz")
	assert_null(layer._wheel, "Tutuş tarif çemberini açmaz")
	assert_true(main.gameplay_hud.hold_progress() > 0.2, "Tutuşun halkası dolar")
	assert_true(await _wait_until(func() -> bool: return wheel.is_open(), 4.0), "3 sn basılı E: Bekle tekeri")
	Input.action_release(&"accept")
	assert_eq(wheel.mode(), &"rest", "Ateş başı kipi (Dinlen)")
	assert_null(layer._wheel, "Tarif çemberi kapalı")
	wheel.close()
	await wait_frames(3)
	# T de oyuncunun yaktığı ateşin başında Dinlen açar: Eski Ocak dünyanın yerlerinde (WorldSpots) yoktur (WaitWheel.rest_sources).
	assert_eq(wheel.context_mode(), &"rest", "Yakılan Eski Ocak'ın başında T Dinlen")
	# Haritanın ocağı: yerleşimin ocağı; E dokunuşu pişirir, Y beslemez, F'nin işi yok.
	var hearth := s.fires.by_id("hearth_campfire")
	assert_true(hearth != null and hearth.hearth and hearth.is_lit(), "Haritanın ocağı yanan ocak")
	await _put(main, Vector2(0.0, -1.6), PI)
	assert_eq(layer._near_target().get("fire"), hearth, "Ocak 3 m içinde")
	var pairs: Array = layer.my_pairs().map(func(p: Array) -> String: return str(p[0]))
	assert_true(pairs.has("E") and pairs.has("E basılı") and not pairs.has("Y") and not pairs.has("F basılı"), "Ocakta yalnız E: %s" % [pairs])
	var dung_before := inv.count("dung")
	layer._on_y_pressed()
	assert_eq(inv.count("dung"), dung_before, "Ocağı halk besler: tezek gitmez")
	assert_false(layer._placing, "Y ocakta yer seçmez")
	assert_false(layer._on_f_pressed(), "F'nin ocakta işi yok")
	assert_true(layer._on_e_pressed())
	layer._on_e_released()
	assert_not_null(layer._wheel, "Ocakta tarif çemberi")
	layer._close_wheel()
	# Uzakta Y: yer seçimi ve kurma.
	await _put(main, Vector2(8.0, 2.0), 0.0)
	layer._on_y_pressed()
	assert_true(layer._placing, "Uzakta Y yer seçer")
	await wait_frames(2)
	assert_true(bool(layer._place_plan.get("ok", false)), "Geçerli yer: %s" % layer._place_plan.get("text", ""))
	layer._on_y_pressed()
	assert_eq(str(layer._work.get("kind", "")), "build", "Kurma işi")
	layer._work["t"] = float(layer._work["T"])
	await wait_frames(2)
	var built := s.fire_near(Vector2(8.0, 3.5), 2.5)
	assert_not_null(built, "Yeni ateş")
	if built:
		assert_true(built.is_lit() and is_equal_approx(built.fuel, FireState.fuel_max()) or built.fuel > 700.0, "Dolu yanar")
		await _put(main, built.xz() + Vector2(0.0, -1.6), 0.0)
		assert_true(layer._on_f_pressed(), "F: söndür (Dolu Tulum var)")
		layer._work["t"] = float(layer._work["T"])
		await wait_frames(2)
		assert_true(built.is_pit(), "Söndü; çukur kaldı")
		assert_eq(inv.count("skin_bag"), 1, "Tulum boşaldı")
	# Kapandaki tarbagan: E basılı yüz.
	await wait_frames(30)
	var fallen: Array = get_tree().get_nodes_in_group(PlayerController.FALLEN_GROUP)
	assert_eq(fallen.size(), 1, "Kapanda düşmüş bir av")
	if fallen.is_empty():
		main.queue_free()
		return
	var carcass := fallen[0] as Node3D
	assert_true(SurvivalLayer.is_carcass(carcass), "Kapandaki av leştir")
	await _put(main, Vector2(carcass.global_position.x, carcass.global_position.z + 0.9), PI)
	assert_not_null(layer._carcass_in_reach(), "Kapandaki av erimde")
	var meat := inv.count("meat")
	assert_true(layer._on_e_pressed(), "E basılı: Yüz")
	layer._work["t"] = float(layer._work["T"])
	await wait_frames(2)
	assert_eq(inv.count("meat"), meat + 1, "Et Heybe'de (verim verim)")
	assert_eq(inv.count("fat"), 1, "İç yağı (bahar: 1)")
	assert_eq(inv.count("hide_small"), 1, "Küçük post")
	assert_eq(inv.count("marmot"), 0, "Bütün hayvan değil")
	# Yer yığını (GroundPile) da «fallen_game» grubundadır ama leş değildir: yalnız «Aç» (E BASILI Yüz yok, yüzme başlamaz).
	var gp := GroundPile.new()
	gp.pile = ItemContainer.make("ground_pile", {"id": "pile.test", "owner": "world"})
	gp.pile.add("stone", 1)
	main._map_world.add_child(gp)
	gp.global_position = main.player.global_position + Vector3(0.4, 0.0, 0.0)
	await wait_frames(2)
	assert_true(gp.is_in_group(PlayerController.FALLEN_GROUP) and gp.is_down(), "Yığın yerdeki hedef grubunda")
	assert_false(SurvivalLayer.is_carcass(gp), "Yığın leş değil")
	assert_null(layer._carcass_in_reach(), "Yığının yanında yüzülecek leş yok")
	var pile_pairs: Array = layer.my_pairs().map(func(p: Array) -> String: return "%s %s" % [p[0], p[1]])
	assert_false(pile_pairs.has("E basılı Yüz"), "Yığında «E BASILI Yüz» yok: %s" % [pile_pairs])
	assert_false(layer._on_e_pressed(), "E yığında yüzme başlatmaz")
	assert_true(layer._work.is_empty(), "Yüzme işi yok")
	gp.queue_free()
	await wait_frames(1)
	# Umay Eşiği.
	var falls := s.wounds.falls
	var time_before: float = s.now_abs()
	var fish_before := inv.count("fish")
	s.wounds.add(s.wounds.limit())
	assert_true(await _wait_until(func() -> bool: return layer._umay != null, 2.0), "Perde iner")
	assert_true(await _wait_until(func() -> bool: return not layer._falling, 12.0), "Uyanış")
	assert_eq(s.wounds.falls, falls + 1)
	assert_eq(s.wounds.count, 1, "Normal'de 1 yarayla uyanılır")
	assert_true(s.now_abs() - time_before >= 119.0, "Saat +2 oyun saati")
	var shelter := Vector2(1.2, -16.6)
	assert_true(Vector2(main.player.global_position.x, main.player.global_position.z).distance_to(shelter) < 1.5, "Son barınakta uyanış")
	assert_not_null(layer._bedside, "Başucunda küçük ok ve yay")
	assert_eq(inv.count("fish"), fish_before - 1, "1 erzak eksik: en az Kıymetli yiyecek (Balık 2)")
	# Kayıttan dönen yolculuk (envanter bloğu kayıttan geldi): takım ikinci kez eklenmez.
	layer._kit_given = false
	layer.session._fresh["inventory"] = false
	var dung_now := inv.count("dung")
	var branch_bag := doru_bag.count("branch")
	layer._give_kit()
	assert_eq(inv.count("dung"), dung_now, "Kayıttan dönen heybeye takım eklenmez")
	assert_eq(doru_bag.count("branch"), branch_bag, "Terkiye de eklenmez")
	main.queue_free()
	await get_tree().create_timer(0.3).timeout
