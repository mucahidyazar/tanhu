extends TestCase
## Ana akış testi: gerçek ana sahne (dünya dahil) pencere açmadan kurulur ve oyun baştan sona oynanır.
##   1) Açılış → SERBEST GEZ → kampta yürüyüş: işaretler (ilk gezinti, ateş başı) ve bildirim.
##   2) Esc → duraklatma kitabı (dünya durur) → KAYDET (1. yuva) → DEVAM ET.
##   3) Esc → ANA MENÜ: otomatik kayıt, kamera menü kadrajına uçar, DEVAM ET açılır.
##   4) DEVAM ET → son kayıt (otomatik) yüklenir, oyuncu kaydedildiği yerde belirir.
##   5) Esc → YÜKLE → 1. yuva: oyuncu oraya döner. 6) Esc → MASAÜSTÜNE DÖN: otomatik kayıt ve çıkış.
## Serbest Gez'de Çocuk yürür (K37): ateş başındaki yerinde oturur, ilk harekette kalkar; kayıtta bedeni işaretiyle durur.
## İkinci test: YENİ OYUN (kayıt varken sorulur; akış yalnız oluşturucu: new_game_only) → karakter oluşturucu → vazgeç / onayla →
## yeni yolculuk başlar ama kampa inilmez (K99), açılış ekranı gelir. Üçüncü test: YENİ OYUN → Önsöz (deneme çizelgesi; sinemada süre
## işlemez, altyazı görünür) → basılı Esc → kara perdeden oluşturucu → onayda "onsoz" işareti; görülen Önsöz ikinci Yeni Oyun'da atlanır.
## Yeni Oyun'un bütün akışı (Önsöz'ü atlayıp Çocukluk, Köprü 1, oluşturucu, Yola Çıkış, Köprü 2, son kart; takvim, «Çocukluğu geç», Kışlak'ın
## kancası) test_new_game_flow.gd'de, Yola Çıkış'ın ayrıntısı test_departure.gd'dedir.
## Kayıtlar geçici bir klasördedir; çıkış gerçek çıkış yerine sahte bir işlevle yakalanır.

const MAIN_SCENE := "res://scenes/main.tscn"
const CINE_TIMELINE := "res://data/cine/test_timeline.json"
const TempDir := preload("res://tests/support/temp_dir.gd")

var _quit_called := false
var _dir := ""


func before_each() -> void:
	MenuStyle.muted = true
	_quit_called = false
	_dir = TempDir.fresh("akis")


func after_each() -> void:
	get_tree().paused = false
	_press_escape(false)
	for action in CineHost.SKIP_ACTIONS:
		if InputMap.has_action(action):
			Input.action_release(action)
	Engine.time_scale = 1.0
	TempDir.wipe(_dir)


## Ana sahne; prologue: Yeni Oyun'un Önsöz dizisi ("" = Önsöz yok, bugünkü akış).
func _new_main(prologue: String = "") -> Node:
	var main = load(MAIN_SCENE).instantiate()
	main.quit_handler = func() -> void: _quit_called = true
	main.saves = SaveSystem.new(_dir)
	main.prologue_path = prologue
	# Önsöz'ün oynanan günleri (E21) bu dosyada değil: test_prologue_days.gd.
	main.prologue_days_path = ""
	add_child(main)
	return main


func test_free_roam_pause_save_title_continue_load_and_quit() -> void:
	var main = _new_main()
	await wait_frames(3)
	assert_eq(main.state, main.State.MENU, "Oyun açılış ekranında başlamalı")
	assert_true(main.menu.visible, "Açılış ekranı görünür olmalı")
	assert_true(main.menu.is_intro_running(), "Açılışta Tanhu 1'in girişi oynamalı")
	assert_false(main._wants_epigraph(), "Başsız çalıştırmada açılış sözü atlanmalı (menü hemen gelir)")
	assert_null(main.get_node_or_null(^"UI/Epigraph"), "Başsız çalıştırmada açılış sözü gösterilmemeli")
	assert_false(main.player.visible, "Menüde oyuncu gizli olmalı")
	assert_true(main.menu_camera.current, "Menüde menü kamerası etkin olmalı")
	assert_true(main.menu.get_button("continue").disabled, "Kayıt yokken DEVAM ET pasif")
	main.menu.finish_intro()

	# 1) Serbest gezinti: oyuncu kampta belirir, ilk gezinti işareti konur.
	main.menu.free_roam_requested.emit()
	await _wait_for_state(main, main.State.PLAYING, 6.0)
	assert_eq(main.state, main.State.PLAYING, "Serbest gezintiye geçilmeli")
	assert_true(main.player.visible and main.player.is_active(), "Oyuncu görünür ve kontrol edilebilir olmalı")
	assert_true(main.follow_camera.is_active(), "Takip kamerası etkin olmalı")
	var spawn: Vector3 = main.spawn_point()
	assert_true(_flat_distance(main.player.global_position, spawn) < 0.5, "Oyuncu ateş başındaki yerinde belirmeli")
	assert_true(main.journey.has_flag(JourneyFlags.FIRST_ROAM), "İlk gezinti işareti konmalı")
	assert_true(main.journey.has_flag(main.ROAM_CHILD_FLAG), "Yolculuk Çocuk'la")
	assert_false(main.journey.has_flag(JourneyFlags.FIRESIDE), "Belirme yeri ateş başı sayılmamalı")
	var npcs := main.world.get_node_or_null(^"Camp/CampNpcs") as CampNpcs
	assert_not_null(npcs, "Kampta ateş başındaki karakterler olmalı")
	# K37: Serbest Gez'de oluşturulan yetişkin değil Çocuk yürür; ateş başında ikinci Çocuk olmaz.
	assert_true(main.player.is_child(), "Çocuk denetleyicisi")
	assert_eq(main.player.get_avatar().model_id, "child", "Serbest Gez'de Çocuk")
	assert_true(main.player.is_seated(), "Ateş başındaki yerinde oturur")
	if npcs:
		assert_eq(npcs.hidden_model, "child", "Oturan kopyası gizlenir: ikinci Çocuk yok")
		assert_false((npcs.get_node(^"Child") as Node3D).visible)
		assert_vec_almost(main.player.global_position, (npcs.get_node(^"Child") as Node3D).global_position, 0.01, "Aynı yerde")
		assert_true(npcs.seat_left, "Kütüğü yerde kalır")
	assert_eq(main.player.get_avatar().get_current_role(), &"sit", "Aynı oturuş")
	# Otururken yer işareti yazılmaz; ilk harekette kalkar (bkz. test_child_controller).
	main.player.step(0.016, Vector2(0.0, 1.0), false, 0.0)
	assert_false(main.player.get_stance() == PlayerController.Stance.SEATED, "İlk harekette kalkar")
	assert_false(main.journey.has_flag(JourneyFlags.FIRESIDE), "Kalkmak da ateş başına varmak değil")

	# Ateşin başına yürüyünce işaret konur ve Destan Kitabı'na dize yazıldığı bildirilir.
	main.player.spawn_at(Vector3(1.4, 0.0, 1.8), PI)
	await _wait_until(func() -> bool: return main.journey.has_flag(JourneyFlags.FIRESIDE), 3.0)
	assert_true(main.journey.has_flag(JourneyFlags.FIRESIDE), "Ateşin başına varınca işaret konmalı")
	await wait_frames(2)
	var toasts: PackedStringArray = main._toast.texts()
	assert_true(toasts.has("Destan Kitabı'na yazıldı: Ateşin Sözü"), "Yeni dize bildirilmeli: %s" % [toasts])
	var fire_pos: Vector3 = main.player.global_position
	var fire_time: float = main.journey.play_time
	assert_true(fire_time > 0.0, "Oynanan süre işlemeli")

	# 2) Esc: kitap açılır, dünya durur; KAYDET ile 1. yuvaya yazılır, DEVAM ET ile sürer.
	await _open_pause(main)
	assert_eq(main.state, main.State.PAUSED, "Esc duraklatma kitabını açmalı")
	assert_true(main.pause_menu.is_open())
	assert_true(get_tree().paused, "Kitap açıkken dünya durmalı")
	assert_false(main.player.is_active())
	var book: GameMenu = main.pause_menu.get_menu()
	assert_eq(book.current_page(), "genel")
	book.open_slots("save")
	await wait_frames(3)
	var save_panel := book.find_children("*", "SaveLoadPanel", false, false)[0] as SaveLoadPanel
	await save_panel.pick(1)
	assert_true(main.saves.has_save(1), "KAYDET 1. yuvaya yazmalı")
	var slot1 := SaveData.parse(main.saves.slot_info(1))
	assert_true(_flat_distance(slot1["position"], fire_pos) < 0.05, "Kayıtta oyuncunun yeri olmalı")
	assert_true((slot1["flags"] as Dictionary).has(JourneyFlags.FIRESIDE), "Kayıtta işaretler olmalı")
	assert_eq(str(slot1["place"]), "ocak")
	save_panel.close()
	await wait_frames(2)
	book.close()
	await wait_frames(2)
	assert_eq(main.state, main.State.PLAYING, "DEVAM ET (Esc) oyuna dönmeli")
	assert_false(get_tree().paused)
	assert_true(main.player.is_active(), "Oyuncu yeniden kontrol edilebilmeli")

	# 3) Biraz yürüyüp Esc → ANA MENÜ: otomatik kayıt yazılır, kamera menüye uçar.
	main.player.spawn_at(Vector3(10.5, 0.0, -10.0), 0.7)
	await _wait_until(func() -> bool: return main.journey.has_flag(JourneyFlags.STABLE), 3.0)
	assert_true(main.journey.has_flag(JourneyFlags.STABLE), "Ahırın önüne varınca işaret konmalı")
	var stable_pos: Vector3 = main.player.global_position
	await _open_pause(main)
	(main.pause_menu.get_menu() as GameMenu)._on_general("main")
	await _wait_for_state(main, main.State.MENU, 6.0)
	assert_eq(main.state, main.State.MENU, "ANA MENÜ açılış ekranına dönmeli")
	assert_true(main.saves.has_save(SaveSystem.AUTO_SLOT), "Ana menüye dönerken otomatik kayıt yazılmalı")
	assert_true(main.menu_camera.current, "Menü kamerası etkin olmalı")
	assert_false(main.player.visible)
	if npcs:
		assert_eq(npcs.hidden_model, "", "Menüde ateş başındaki herkes görünmeli")
		assert_true((npcs.get_node(^"Child") as Node3D).visible, "Menüde Çocuk oturur")
		assert_false(npcs.seat_left)
	await wait_frames(2)
	assert_false(main.menu.get_button("continue").disabled, "Kayıt olunca DEVAM ET açılmalı")
	assert_false(main.menu.get_button("load").disabled, "Kayıt olunca YÜKLE açılmalı")

	# 4) DEVAM ET: son kayıt (otomatik) yüklenir; oyuncu ahırın önünde belirir.
	main.journey.flags = {}
	main.menu.continue_requested.emit()
	await _wait_for_state(main, main.State.PLAYING, 6.0)
	assert_eq(main.state, main.State.PLAYING, "DEVAM ET oyuna geçmeli")
	assert_true(_flat_distance(main.player.global_position, stable_pos) < 0.1, "Oyuncu kaydedildiği yerde belirmeli")
	assert_true(main.player.is_child(), "Kayıtta beden işaretiyle durur: yine Çocuk")
	assert_false(main.player.is_seated(), "Kaydedildiği yerde ayakta")
	assert_true(main.journey.has_flag(JourneyFlags.STABLE) and main.journey.has_flag(JourneyFlags.FIRESIDE), "İşaretler kayıttan gelmeli")

	# 5) Esc → YÜKLE → 1. yuva: oyuncu ateşin başına döner.
	await _open_pause(main)
	book = main.pause_menu.get_menu()
	book.open_slots("load")
	await wait_frames(3)
	var load_panel := book.find_children("*", "SaveLoadPanel", false, false)[0] as SaveLoadPanel
	load_panel.pick(1)
	await wait_frames(2)
	var ask := load_panel.find_children("*", "ConfirmDialog", false, false)
	assert_eq(ask.size(), 1, "Oyunda yüklemeden önce sorulmalı")
	if ask.size() == 1:
		(ask[0] as ConfirmDialog).answer(true)
	await _wait_for_state(main, main.State.PLAYING, 6.0)
	assert_eq(main.state, main.State.PLAYING)
	assert_false(get_tree().paused)
	assert_true(_flat_distance(main.player.global_position, fire_pos) < 0.1, "Yüklenen kayıtta oyuncu ateşin başında olmalı")
	assert_false(main.journey.has_flag(JourneyFlags.STABLE), "1. yuva ahırdan önce kaydedildi: o işaret olmamalı")
	assert_true(main.player.is_active())

	# 6) Esc → MASAÜSTÜNE DÖN: sorar, otomatik kayda yazar ve çıkar.
	main.saves.remove(SaveSystem.AUTO_SLOT)
	await _open_pause(main)
	(main.pause_menu.get_menu() as GameMenu)._on_general("quit")
	await wait_frames(2)
	var quit_ask: Array = main.pause_menu.get_menu().find_children("*", "ConfirmDialog", false, false)
	assert_eq(quit_ask.size(), 1, "MASAÜSTÜNE DÖN önce sormalı")
	if quit_ask.size() == 1:
		(quit_ask[0] as ConfirmDialog).answer(true)
	await _wait_until(func() -> bool: return _quit_called, 4.0)
	assert_true(_quit_called, "Çıkış işlevi çağrılmalı")
	assert_true(main.saves.has_save(SaveSystem.AUTO_SLOT), "Masaüstüne dönerken otomatik kayıt yazılmalı")
	main.queue_free()
	await _silence_audio()


func test_new_game_creator_and_title_quit() -> void:
	# Önceki bir yolculuğun kaydı: YENİ OYUN önce sormalı.
	SaveSystem.new(_dir).write(2, SaveData.build(CharacterProfile.new(), Vector3(2, 0, 2), 0.0, {"ahir_ziyaret": true}, 60.0, 1, "ocak"))
	var main = _new_main()
	main.new_game_only = PackedStringArray(["creator"])
	await wait_frames(3)
	main.menu.finish_intro()
	await wait_frames(1)
	main.menu.get_button("new").pressed.emit()
	await wait_frames(2)
	var dialog := main.menu.get_page() as ConfirmDialog
	assert_not_null(dialog, "Kayıt varken YENİ OYUN önce sormalı")
	if dialog:
		dialog.answer(true)
	await _wait_for_state(main, main.State.CREATOR, 6.0)
	assert_eq(main.state, main.State.CREATOR, "YENİ OYUN karakter oluşturucuyu açmalı")
	assert_true(main.creator.visible)
	assert_true(main.get_viewport().disable_3d, "Oluşturucu açıkken ana 3B sahne çizilmemeli")
	main.creator.cancelled.emit()
	await _wait_for_state(main, main.State.MENU, 6.0)
	assert_eq(main.state, main.State.MENU, "Vazgeçince açılış ekranına dönülmeli")
	assert_false(main.get_viewport().disable_3d, "3B sahne yeniden çizilmeli")

	# Onaylayınca yeni bir yolculuk başlar: eski işaretler yoktur, süre sıfırdan başlar; oluşturulan Mete kampa inmez (K99), açılış ekranı gelir.
	main.journey.flags = {"ahir_ziyaret": true}
	main.journey.play_time = 500.0
	main.menu.start_requested.emit()
	await _wait_for_state(main, main.State.CREATOR, 6.0)
	var chosen := CharacterProfile.new()
	chosen.set_value(&"skin", 4)
	main.creator.accepted.emit(chosen)
	await _wait_for_state(main, main.State.MENU, 8.0)
	assert_eq(main.state, main.State.MENU, "Onaydan sonra (sıradaki aşama yok) açılış ekranı")
	assert_true(main.profile.equals(chosen), "Seçilen karakter kullanılmalı")
	assert_true(main.journey.profile.equals(chosen), "Yolculuğun karakteri")
	assert_false(main.player.visible, "Oluşturulan Mete ana kampa inmez")
	assert_false(main.follow_camera.is_active(), "Takip kamerası kapalı")
	assert_true(main.menu_camera.current, "Menü kamerası")
	var npcs := main.world.get_node_or_null(^"Camp/CampNpcs") as CampNpcs
	if npcs:
		assert_true((npcs.get_node(^"Child") as Node3D).visible, "Ateş başındaki Çocuk yerinde")
	assert_false(main.journey.has_flag(JourneyFlags.STABLE), "Yeni yolculukta eski işaretler olmamalı")
	assert_true(main.journey.play_time < 30.0, "Yeni yolculuğun süresi sıfırdan başlamalı")
	assert_false(main.journey.has_flag(JourneyFlags.FIRST_ROAM), "Kampa inilmedi")
	assert_false(main.journey.has_flag(CineHost.PROLOGUE_FLAG), "Önsöz yokken onsoz işareti konmamalı")
	assert_false(main.saves.has_save(SaveSystem.AUTO_SLOT), "Yeni Oyun kayıt yazmaz")
	assert_true(main.saves.has_save(2), "Eski kayıt yerinde")

	# Ayarlar sahneye uygulanır: boyalı görünüm kapanınca efekt kapanır.
	var settings: Node = main.settings
	if settings:
		var before: bool = settings.painterly
		settings.painterly = false
		settings.apply()
		assert_false(main.overlay.enabled, "Ayar değişince boyalı efekt kapanmalı")
		settings.painterly = before
		settings.apply()

	# Açılış ekranından ÇIKIŞ.
	main.menu.quit_requested.emit()
	await _wait_until(func() -> bool: return _quit_called, 4.0)
	assert_true(_quit_called, "ÇIKIŞ çıkış işlevini çağırmalı")
	main.get_viewport().disable_3d = false
	main.queue_free()
	await _silence_audio()


func test_new_game_prologue_then_creator_and_flag() -> void:
	var main = _new_main(CINE_TIMELINE)
	main.new_game_only = PackedStringArray(["prologue", "creator"])
	await wait_frames(3)
	main.menu.finish_intro()
	await wait_frames(1)
	assert_eq(main.prologue_file(), CINE_TIMELINE, "Önsöz dosyası okunmalı")
	# Önsöz'ün görüldüğünü sahte bir ayar nesnesi tutar (oyuncunun ayarına yazılmaz).
	var seen := SeenSettings.new()
	main.settings = seen
	main.remember_prologue = true
	var holds := watch_signal(main.cine.clock_hold_changed)
	main.journey.play_time = 123.0
	# Sinema bittiği anda (yeni yolculuk başlamadan) yolculuğun süresi.
	var played_at_end: Array[float] = [-1.0]
	main.cine.finished.connect(func(_skipped: bool) -> void: played_at_end[0] = main.journey.play_time, CONNECT_ONE_SHOT)
	main.menu.start_requested.emit()
	await _wait_for_state(main, main.State.CINE, 3.0)
	assert_eq(main.state, main.State.CINE, "Yeni Oyun Önsöz'ü oynatmalı")
	assert_true(main.cine.is_playing())
	assert_eq(holds.last_args, [true], "Sinemada saat durmalı")
	await _wait_until(func() -> bool: return main.cine.time() > 0.3, 5.0)
	assert_eq(main.journey.play_time, 123.0, "Sinemada yolculuğun süresi işlememeli")
	assert_false(main.player.visible, "Sinemada oyuncu yok")
	# Hızlanınca şarkının ilk dizesi altyazıda görünür.
	main.cine.speed = 10.0
	var verse: String = VoLines.sub_lines("act0.bard.song")[0]["tr"]
	await _wait_until(func() -> bool: return main.cine.subtitles.current_text() == verse, 5.0)
	assert_eq(main.cine.subtitles.current_text(), verse, "Şarkının dizesi altyazıda")
	main.cine.speed = 1.0
	# Basılı Esc atlar: kara perdeden oluşturucu açılır.
	_press_escape(true)
	await _wait_for_state(main, main.State.CREATOR, 6.0)
	_press_escape(false)
	assert_eq(main.state, main.State.CREATOR, "Atlanan Önsöz'den sonra oluşturucu açılmalı")
	assert_true(main.creator.visible)
	assert_false(main.cine.is_playing())
	assert_eq(holds.last_args, [false], "Önsöz bitince saat bırakılmalı")
	assert_almost(main.fade.color.a, 0.0, 0.01, "Perde kalkmalı")
	assert_true(main.menu_camera.current, "Menü kamerası etkin")
	assert_true(main.menu_camera.global_position.distance_to(main.menu_camera.menu_transform.origin) < 0.2, "Menü kamerası menü kadrajında")
	assert_true(main.world.visible and main.world.process_mode == Node.PROCESS_MODE_INHERIT, "Kamp dünyası yerinde")
	assert_eq(played_at_end[0], 123.0, "Önsöz boyunca süre işlemedi")
	assert_true(main.journey.play_time < 1.0, "Yeni yolculuk Önsöz'den sonra sıfırdan başlar")
	assert_true(seen.prologue_seen, "İlk oynatmada prologue_seen yazılmalı")
	assert_eq(seen.saves, 1)
	# Vazgeç → menü → ikinci Yeni Oyun: görülen Önsöz varsayılanla atlanır.
	main.creator.cancelled.emit()
	await _wait_for_state(main, main.State.MENU, 6.0)
	var plays := holds.count
	main.menu.start_requested.emit()
	await _wait_for_state(main, main.State.CREATOR, 6.0)
	assert_eq(main.state, main.State.CREATOR, "İkinci Yeni Oyun doğrudan oluşturucuyu açmalı")
	assert_eq(holds.count, plays, "Görülen Önsöz yeniden oynamamalı")
	seen.prologue_always = true
	assert_false(main._prologue_skipped_by_setting(), "«Her yeni oyunda» seçiliyse Önsöz oynar")
	seen.prologue_always = false
	# Yeni yolculuk Önsöz'den sonraki ilk aşamada başlar (journey.reset), Önsöz'ün işareti yazılır; onaydan sonra açılış ekranı (K99).
	assert_true(main.journey.has_flag(CineHost.PROLOGUE_FLAG), "Önsöz görülünce onsoz işareti konmalı")
	assert_true(main.journey.play_time < 30.0, "Yeni yolculuğun süresi sıfırdan")
	main.creator.accepted.emit(CharacterProfile.new())
	await _wait_for_state(main, main.State.MENU, 8.0)
	assert_eq(main.state, main.State.MENU, "Kampa inilmez")
	assert_true(main.journey.has_flag(CineHost.PROLOGUE_FLAG))
	assert_false(main.player.visible)
	main.get_viewport().disable_3d = false
	main.queue_free()
	seen.queue_free()
	await _silence_audio()


func test_free_roam_after_a_new_game_switches_to_the_child_and_back() -> void:
	var main = _new_main()
	main.new_game_only = PackedStringArray(["creator"])
	await wait_frames(3)
	main.menu.finish_intro()
	main.menu.start_requested.emit()
	await _wait_for_state(main, main.State.CREATOR, 6.0)
	main.creator.accepted.emit(CharacterProfile.new())
	await _wait_for_state(main, main.State.MENU, 8.0)
	assert_eq(main.state, main.State.MENU, "Yeni Oyun kampa inmez: açılış ekranı (K99)")
	assert_false(main.player.visible)
	main.menu.free_roam_requested.emit()
	await _wait_for_state(main, main.State.PLAYING, 8.0)
	assert_true(main.player.is_child(), "Serbest Gez: Çocuk")
	assert_true(main.player.is_seated())
	assert_almost(main.player.walk_speed, PlayerController.CHILD_WALK_SPEED, 0.01, "Çocuğun hızı")
	assert_eq(main.hud.get_hint_text(), GameHud.format_hints(GameHud.CHILD_HINTS), "Çocuğun tuşları ipucunda")
	var bow_prop: ToyBowProp = main.player.archer().prop
	assert_not_null(bow_prop, "Aynı yay")
	# Yayla yürür: Serbest Gez'de binek yoktur (K65), E kamerayı döndürür.
	main.player.spawn_at(Vector3(4.0, 0.0, 6.0), PI)
	assert_false(main.player.has_interaction(), "Kampta binilecek koyun yok")
	main.player.archer().aim_override = Vector3(4.0, 0.0, 0.0)
	assert_true(main.player.begin_aim(), "Serbest Gez'de de nişan")
	assert_eq(main.player.prompt_pairs(), [["Sol tık", "Bırak"]], "Nişanda sol tuş bırakır")
	var loosed := watch_signal(main.player.archer().loosed)
	await wait_frames(4)
	# Sol tuş oku bırakır (sağ tuşu bırakmak da atar: test_child_controller).
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	main.player._unhandled_input(click)
	await _wait_until(func() -> bool: return loosed.fired, 2.0)
	assert_true(loosed.fired, "Ok çıkar")
	# Yeni Oyun yine kampa inmez; Serbest Gez yine Çocuk.
	await _open_pause(main)
	(main.pause_menu.get_menu() as GameMenu)._on_general("main")
	await _wait_for_state(main, main.State.MENU, 6.0)
	main.menu.start_requested.emit()
	await _wait_for_state(main, main.State.CREATOR, 6.0)
	main.creator.accepted.emit(CharacterProfile.new())
	await _wait_for_state(main, main.State.MENU, 8.0)
	assert_eq(main.state, main.State.MENU, "İkinci Yeni Oyun da açılış ekranında biter")
	assert_false(main.player.visible, "Oyuncu kampta değil")
	main.get_viewport().disable_3d = false
	main.queue_free()
	await _silence_audio()


func test_state_childhood_opens_ordos_with_little_mete() -> void:
	var main = _new_main()
	await wait_frames(3)
	main.menu.finish_intro()
	await wait_frames(1)
	await main._dev_childhood({})
	assert_eq(main.state, main.State.PLAYING, "Ordos'ta oyun")
	assert_true(main._childhood_world is OrdosWorld, "Çocukluk'un dünyası")
	var ordos: OrdosWorld = main._childhood_world
	assert_true(ordos.is_ready(), "Kuruldu")
	assert_true(ordos.is_childhood_mode() and ordos.is_childhood_ready(), "Çocukluk kipi")
	assert_false(main.world.visible, "Kamp bırakıldı")
	assert_eq(main.player.person_id(), ChildLook.PERSON_METE, "Küçük Mete")
	assert_eq(main.player.get_avatar().model_id, ChildLook.resolve(ChildLook.PERSON_METE)["model"], "Modeli")
	assert_true(main.player.visible and main.player.is_active())
	assert_true(main.follow_camera.is_active() and main.follow_camera.target == main.player, "FollowCamera")
	# Zemin dünyanın verdiğidir (Çocukluk kipinde ağılın ve yolların düzlediği zemin: OrdosWorld.get_terrain_shape).
	assert_eq(main.player.terrain_shape, ordos.get_terrain_shape(), "Zemin Ordos'un")
	assert_eq(main.follow_camera.terrain_shape, ordos.get_terrain_shape())
	assert_true(main.follow_camera.transform_filter.is_valid(), "Kamera sınırı")
	var area := ordos.play_area()
	assert_almost(main.player.play_area_radius, float(area["radius"]), 0.001, "Yürünür alan")
	assert_true(main.player.obstacles.size() > 0 and main.player.walls.size() > 0, "Engeller Ordos'un")
	var start := ordos.marker("child_start")
	assert_true(_flat_distance(main.player.global_position, start) < 1.0, "Yurdun kapısında")
	# Koyun ağılda, işaretinde; binilir.
	# Binekler grubunda kampın atları da vardır (kamp gizli, ağaçta kalır; ne binilir ne engeldir: PlayerController._mount_present).
	var sheep_nodes: Array = main.get_tree().get_nodes_in_group(Rideable.GROUP).filter(func(n: Node) -> bool: return n is RideableSheep)
	assert_eq(sheep_nodes.size(), main.CHILDHOOD_SHEEP.size(), "İki binilen koyun")
	for node in main.get_tree().get_nodes_in_group(Rideable.GROUP):
		if node is RideableHorse:
			assert_false((node as Node3D).is_visible_in_tree(), "Kampın atı gizli dünyada")
	var old_sheep: RideableSheep = sheep_nodes[0]
	assert_true(_flat_distance(old_sheep.global_position, ordos.marker("old_sheep")) < 0.01, "Yaşlısı işaretinde")
	assert_almost(old_sheep.global_position.y, ordos.get_terrain_shape().height_at(old_sheep.global_position.x, old_sheep.global_position.z), 0.01, "Zeminde")
	main.player.spawn_at(old_sheep.global_position + Vector3(0.9, 0.0, 0.0), 0.0)
	assert_eq(main.player.mount_in_reach(), old_sheep)
	assert_true(main.player.interact(), "E ile biner")
	await _wait_until(func() -> bool: return main.player.is_riding(), 3.0)
	assert_true(main.player.is_riding(), "Sırtta")
	assert_eq(main.player.get_avatar().get_current_role(), RidePose.ROLE)
	# Küçük av yayın hedefi: gerçek hedefe atar.
	var game: Array = main.get_tree().get_nodes_in_group(ArrowField.TARGET_GROUP)
	assert_true(game.size() > 0, "Av «targets» grubunda")
	# Duraklatma: dünya durur, binici iner değil.
	await _open_pause(main)
	assert_true(main.player.is_riding(), "Duraklatınca iner değil")
	var book: GameMenu = main.pause_menu.get_menu()
	book._on_general("main")
	await _wait_for_state(main, main.State.MENU, 8.0)
	assert_eq(main.state, main.State.MENU, "Ana menü")
	assert_null(main._childhood_world, "Dünya bırakıldı")
	assert_true(main.world.visible, "Kamp geri geldi")
	assert_almost(main.player.play_area_radius, 38.0, 0.001, "Oyun alanı kampın")
	assert_false(main.follow_camera.transform_filter.is_valid(), "Kamera sınırı kalktı")
	assert_true(main.menu_camera.current, "Menü kamerası")
	assert_false(main.saves.has_save(SaveSystem.AUTO_SLOT), "Çocukluk'un yeri kampın kaydına yazılmaz")
	main.queue_free()
	await _silence_audio()


# --- Yardımcılar ---------------------------------------------------------------------------------

func _press_escape(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.physical_keycode = KEY_ESCAPE
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


## Ana sahnenin başlattığı müzik ve ortam sesi AudioManager autoload'unda çalmayı sürdürür; koşu bitince
## ses sunucusu bunları "sızıntı" diye yazmasın diye durdurulur ve ses iş parçacığına zaman tanınır.
func _silence_audio() -> void:
	var audio := get_node_or_null(^"/root/AudioManager")
	if audio:
		for p in audio.get_children():
			if p is AudioStreamPlayer:
				(p as AudioStreamPlayer).stop()
				(p as AudioStreamPlayer).stream = null
	await get_tree().create_timer(0.25).timeout

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


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## Önsöz ayarlarını taşıyan sahte ayar düğümü (GameSettings.prologue_seen / prologue_always); kaydı sayar.
class SeenSettings:
	extends Node

	var prologue_seen := false
	var prologue_always := false
	var saves := 0

	func save_settings() -> bool:
		saves += 1
		return true
