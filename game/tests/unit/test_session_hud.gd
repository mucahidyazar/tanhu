extends TestCase
## Oturumun HUD'a ve oyuncuya bağları (Yol Haritası inventory, levels-skills; economy.md §4.1, §4.2, §4.6; progression.md §2.5;
## godot.md §5.4 PortraitBaker):
##   - Seviye rozeti ve XP çubuğu gerçek ilerlemeyi okur (vitals.bind_progression).
##   - Yük yürüyüşü yavaşlatır: çocukta tek kütük (4 / 6 Yük) hız ×0,8, koşu açık, zıplama kapalı; koşunun takat gideri 1 + doluluk.
##     Çocukluk'un iki tarla kuşu çocuğu yürütür (≥0,95), Serbest Gez'in Çocuğu yüksüz tam hızdadır.
##   - G basılı 0,6 sn «Yükü Bırak»: Sırt sekmesi yer yığını olur; kısa basış bir şey yapmaz.
##   - E dünyadaki kabı (deneme haritasının fıçısı: Mete'nin sandığı) ve yetişkinde yer yığınını aktarma sekmesinde açar.
##   - Yetişkinin portresi görünüşünden pişer (PortraitBaker): yuvarlak kesim, görünüşün anahtarı, HUD pişmiş dokuyu çizer; çocukta boyalı
##     portre kalır.

const TempDir := preload("res://tests/support/temp_dir.gd")
const MAIN_SCENE := "res://scenes/main.tscn"

var _dir := ""
var _nodes: Array[Node] = []


func before_each() -> void:
	MenuStyle.muted = true
	InputSetup.ensure_actions()
	_dir = TempDir.fresh("oturum_hud")


func after_each() -> void:
	get_tree().paused = false
	Input.action_release(&"drop_load")
	for n in _nodes:
		if is_instance_valid(n):
			n.queue_free()
	_nodes.clear()
	TempDir.wipe(_dir)


# --- Saf ------------------------------------------------------------------------------------------------------------

func test_child_log_is_one_log_at_point_eight() -> void:
	var inv := Inventory.new()
	inv.reset_body(Inventory.BODY_CHILD)
	assert_almost(inv.capacity(), 6.0, 1e-9, "Çocuğun sınırı 6 Yük")
	assert_eq(int(inv.add("wood_pine", 1, "gather")["added"]), 1, "Bir kütük (4 Yük) sığar")
	assert_eq(int(inv.add("wood_pine", 1, "gather")["added"]), 0, "İkincisi sığmaz: tek kütük")
	var mods := inv.move_mods()
	assert_almost(float(mods["speed_k"]), 0.8, 1e-9, "Hız ×0,8 (progression.md §2.5)")
	assert_true(bool(mods["can_run"]), "Kütükle koşulur (doluluk ≤0,75)")
	assert_false(bool(mods["can_jump"]), "Kütükle zıplanmaz (doluluk >0,5)")
	assert_almost(float(mods["run_cost_k"]), 1.0 + 4.0 / 6.0, 1e-9, "Koşunun takat gideri 1 + doluluk")
	var v := Vitals.new()
	v.run_cost_k = float(mods["run_cost_k"])
	v.tick(1.0, 3.0, false, 1.2, 2.88)
	assert_almost(v.stamina, Vitals.STAMINA_MAX - Vitals.DRAIN * v.run_cost_k, 1e-6, "Yüklü koşu takati daha çok yer")


func test_player_walks_slower_and_cannot_jump_with_the_log() -> void:
	var p := PlayerController.new()
	p.start_active = false
	add_child(p)
	_nodes.append(p)
	await wait_frames(1)
	var walk := p.walk_speed
	p.move_mods = {"speed_k": 0.8, "can_run": true, "can_jump": false, "run_cost_k": 1.67}
	for i in 40:
		p.step(0.05, Vector2(0.0, 1.0), false, 0.0)
	assert_almost(p.get_speed(), walk * 0.8, 0.05, "Yürüyüş ×0,8")
	assert_false(p.jump(), "Zıplanmaz")
	p.move_mods = {"speed_k": 0.7, "can_run": false, "can_jump": false}
	for i in 40:
		p.step(0.05, Vector2(0.0, 1.0), true, 0.0)
	assert_almost(p.get_speed(), walk * 0.7, 0.05, "Tam yükte koşu yok: yürüyüşün ×0,7'si")
	p.move_mods = {}
	for i in 40:
		p.step(0.05, Vector2(0.0, 1.0), true, 0.0)
	assert_almost(p.get_speed(), p.run_speed, 0.1, "Yüksüz koşu tam")
	assert_true(p.jump(), "Yüksüz zıplar")


func test_portrait_baker_cuts_round_and_keys_the_look() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.2, 0.4, 0.8, 1.0))
	var cut := PortraitBaker.round_cut(img)
	assert_almost(cut.get_pixel(16, 16).a, 1.0, 1e-6, "Ortası opak")
	assert_almost(cut.get_pixel(0, 0).a, 0.0, 1e-6, "Köşesi saydam")
	assert_almost(cut.get_pixel(31, 31).a, 0.0, 1e-6)
	var a := CharacterProfile.new()
	var b := a.copy()
	assert_eq(PortraitBaker.key_of(a), PortraitBaker.key_of(b), "Aynı görünüş aynı anahtar")
	b.hair_color = (b.hair_color + 1) % maxi(CharacterOptions.count(&"hair_color", b.body_type), 2)
	assert_ne(PortraitBaker.key_of(a), PortraitBaker.key_of(b), "Görünüş değişince yeniden pişer")
	assert_ne(PortraitBaker.key_of(a, &"hostage_coat"), PortraitBaker.key_of(a), "Kılık anahtara girer")
	var portrait := HudPortrait.new()
	add_child(portrait)
	_nodes.append(portrait)
	portrait.set_person("")
	assert_null(portrait.portrait_texture(), "Pişmeden önce yetişkinin portresi yok (gök mavisi boşluk)")
	portrait.baked = ImageTexture.create_from_image(cut)
	assert_eq(portrait.portrait_texture(), portrait.baked, "Yetişkinde pişmiş portre çizilir")
	portrait.set_person(ChildLook.PERSON_CHILD)
	assert_eq(portrait.portrait_texture(), HudKit.tex("portrait_child"), "Çocukta boyalı portre")


# --- Ana sahne ------------------------------------------------------------------------------------------------------

func test_testmap_hud_reads_progression_drops_load_and_opens_the_barrel() -> void:
	var main = load(MAIN_SCENE).instantiate()
	main.quit_handler = func() -> void: pass
	main.saves = SaveSystem.new(_dir)
	main.prologue_path = ""
	add_child(main)
	_nodes.append(main)
	await wait_frames(3)
	main.menu.finish_intro()
	await wait_frames(1)
	await main._dev_testmap({})
	var s: Session = main.session
	var hud: GameplayHud = main.gameplay_hud
	assert_not_null(s)
	if s == null:
		await _end(main)
		return
	await _wait_until(func() -> bool: return hud.is_shown(), 4.0)
	# Haritanın katmanları (ateş ve av, toplama) kendi deneme takımlarını heybeye verir: takım sandığa konur, Yük'ün etkisi temiz ölçülür.
	await wait_frames(10)
	s.inventory.move_all(s.inventory.pack, s.inventory.chest, null, Callable(), true)
	await wait_frames(1)
	# Seviye ve XP.
	s.progression.add_xp(400, "test")
	await wait_frames(2)
	assert_eq(hud.vitals.level, 2, "Rozet ilerlemenin seviyesi")
	assert_almost(hud.vitals.xp_ratio(), s.progression.xp_ratio(), 1e-9, "XP çubuğu ilerlemenin oranı")
	assert_eq(hud.portrait.person, "", "Yetişkinin portresi")
	assert_false(hud.portrait.profile_key.is_empty(), "Portre görünüşün anahtarıyla istenir (başsızda pişmez)")
	# Yük: iki taş (10 Yük) yürüyüşü yavaşlatır (haritanın katmanlarının deneme takımı da heybede olabilir).
	var k0: float = main.player.load_speed_k()
	s.inventory.add("stone", 2, "gather")
	await wait_frames(1)
	var k: float = main.player.load_speed_k()
	assert_almost(k, s.inventory.speed_k(), 1e-9, "Oyuncunun hızı envanterin Yük'ünden")
	assert_true(k < k0, "Yük yavaşlatır (%.3f < %.3f)" % [k, k0])
	# G kısa basış: bir şey olmaz.
	Input.action_press(&"drop_load")
	var g := InputEventAction.new()
	g.action = &"drop_load"
	g.pressed = true
	hud._unhandled_input(g)
	await get_tree().create_timer(0.2).timeout
	Input.action_release(&"drop_load")
	await wait_frames(2)
	assert_eq(s.inventory.count("stone"), 2, "Kısa basış bırakmaz (ileride Ku'ya «Bak»)")
	# G basılı 0,6 sn: Sırt sekmesi yere.
	Input.action_press(&"drop_load")
	hud._unhandled_input(g)
	await get_tree().create_timer(0.35).timeout
	assert_true(hud.hold_progress() > 0.2, "Basılı tutuşun halkası")
	await get_tree().create_timer(0.5).timeout
	Input.action_release(&"drop_load")
	await wait_frames(2)
	assert_eq(s.inventory.count("stone"), 0, "Yükü Bırak: taşlar heybeden çıktı")
	assert_eq(s.inventory.tab("back"), [], "Sırt sekmesi boş")
	assert_eq(s.inventory.piles().size(), 1, "Yer yığını")
	assert_eq(hud.bag.pile_nodes().size(), 1, "Yığının torbası dünyada")
	assert_true(main.player.load_speed_k() > k, "Yük kalkınca hız artar")
	assert_almost(main.player.load_speed_k(), s.inventory.speed_k(), 1e-9)
	# E: yetişkin yer yığınını aktarma sekmesinde açar.
	var pile_at: Vector3 = s.inventory.pile_position(s.inventory.piles()[0])
	main.player.spawn_at(pile_at + Vector3(0.5, 0.0, 0.0), 0.0)
	await wait_frames(2)
	var e: Dictionary = main._interaction()
	assert_eq(str(e.get("label", "")), "Aç", "Yer yığınında E «Aç»")
	assert_true(main.player.interact(), "E yığını açar")
	await wait_frames(2)
	assert_true(hud.is_screen_open(), "Envanter açıldı")
	var screen := hud.screen() as HudInventoryScreen
	assert_eq(screen.page, "transfer", "Aktarma sekmesi")
	var panel := screen.transfer_panel()
	assert_not_null(panel)
	if panel:
		assert_eq(panel.target, s.inventory.piles()[0], "Kap: yer yığını")
	s.inventory.take_pile(s.inventory.piles()[0])
	hud.close_screen()
	await wait_frames(3)
	assert_false(hud.is_screen_open())
	# E: deneme haritasının fıçısı Mete'nin sandığıdır.
	var spots: WorldSpots = main._world_spots()
	var barrel: Dictionary = spots.list("containers")[0]
	var at: Vector2 = barrel["at"]
	main.player.spawn_at(Vector3(at.x + 1.0, 0.0, at.y + 0.6), 0.0)
	await wait_frames(2)
	e = main._interaction()
	assert_eq(str(e.get("label", "")), "Aç", "Fıçıda E «Aç»")
	assert_true(main.player.interact())
	await wait_frames(2)
	screen = hud.screen() as HudInventoryScreen
	assert_not_null(screen, "Aktarma sekmesi açık")
	if screen and screen.transfer_panel():
		assert_eq(screen.transfer_panel().target, s.inventory.chest, "Fıçı: Mete'nin sandığı (kayıtta)")
		assert_eq(screen.transfer_panel().title, "FIÇI · SANDIK")
	hud.close_screen()
	await wait_frames(2)
	await _end(main)


func test_free_roam_child_keeps_full_speed_and_a_fresh_body() -> void:
	var main = load(MAIN_SCENE).instantiate()
	main.quit_handler = func() -> void: pass
	main.saves = SaveSystem.new(_dir)
	main.prologue_path = ""
	add_child(main)
	_nodes.append(main)
	await wait_frames(3)
	main.menu.free_roam_requested.emit()
	await _wait_until(func() -> bool: return main.state == main.State.PLAYING, 10.0)
	assert_true(main.player.is_child())
	assert_eq(main.session.inventory.body, Inventory.BODY_CHILD, "Serbest Gez'in Çocuğu kayıtsız beden (begin_body)")
	assert_eq(main.session.inventory.equipped("bow"), "toy_bow", "Oyuncak yay kuşanılı")
	assert_almost(main.player.load_speed_k(), 1.0, 1e-9, "Yüksüz çocuk tam hızda")
	main.session.inventory.add("wood_pine", 1, "gather")
	await wait_frames(1)
	assert_almost(main.player.load_speed_k(), 0.8, 1e-9, "Kütükle ×0,8")
	await _end(main)


# --- Yardımcılar ----------------------------------------------------------------------------------------------------

func _end(main: Node) -> void:
	main.queue_free()
	var audio := get_node_or_null(^"/root/AudioManager")
	if audio:
		for p in audio.get_children():
			if p is AudioStreamPlayer:
				(p as AudioStreamPlayer).stop()
				(p as AudioStreamPlayer).stream = null
	await get_tree().create_timer(0.25).timeout


func _wait_until(cond: Callable, seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while not cond.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
