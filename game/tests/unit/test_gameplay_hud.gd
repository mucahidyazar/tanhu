extends TestCase
## Oyun içi HUD testleri (GameplayHud; kullanıcının görseli docs/media/review/hud_referans.webp): parçalar kurulur, yalnız oynanırken
## görünür, görev kartı kaynağın yazılarını gösterir, mini haritanın dönüşü ve kenara kırpması, ekran kenarındaki yön oku, I Envanter'i
## açar (oyun durur, Esc kapatır), M ve J kitabın HARİTA ve GÖREVLER sayfasını ister, Serbest Gez'in görevi («Kampı Dolaş»),
## Çocukluk'un görevinin adımları, envanter, girdi eylemleri ve tuşlar sayfası. Son test gerçek ana sahnede Serbest Gez'e iner: HUD,
## görev kartı, envanter ve kitabın harita sayfası orada çalışır.

const MAIN_SCENE := "res://scenes/main.tscn"
const TempDir := preload("res://tests/support/temp_dir.gd")

var hud: GameplayHud
var _live := true
var _dir := ""


func before_each() -> void:
	MenuStyle.muted = true
	InputSetup.ensure_actions()
	_live = true
	hud = GameplayHud.new()
	hud.live_check = func() -> bool: return _live
	add_child(hud)


func after_each() -> void:
	get_tree().paused = false
	if is_instance_valid(hud):
		hud.queue_free()
	hud = null
	if not _dir.is_empty():
		TempDir.wipe(_dir)
		_dir = ""


class FakeQuest extends RefCounted:
	var target := Vector3(10.0, 0.0, -20.0)
	var objective := "Sayım hattına koş"

	func hud_quest() -> Dictionary:
		return {"id": "mq0_sheep", "title": "Koyun Sırtında", "objective": objective, "detail": "Sayıcı sürüyü hattan geçiriyor.",
			"steps": [{"id": "wake", "text": "Ağıla git", "state": "done"}, {"id": "count", "text": "Sayım hattına koş", "state": "current"},
				{"id": "x", "text": "Gizli", "state": "todo"}], "done": false}

	func hud_target(_from: Vector3) -> Vector3:
		return target


# --- Kurulum ve görünürlük ---------------------------------------------------------------------------------

func test_builds_every_part_of_the_reference() -> void:
	for n in ["Portrait", "Minimap", "QuestCard", "Hotbar", "MenuButtons", "Pointer"]:
		assert_not_null(hud.get_node_or_null(NodePath(n)), "HUD parçası: %s" % n)
	for id in ["portrait_ring", "map_ring", "map_ring_large", "bar_frame", "bar_fill_red", "bar_fill_green", "slot_square", "badge_level",
			"quest_rule", "quest_banner", "marker_diamond", "marker_arrow", "marker_pin", "slot_hex", "button_round", "badge_count",
			"cloud_left", "cloud_right", "xp_frame", "xp_fill", "icon_toy_bow", "icon_bag", "icon_book", "icon_map", "icon_boot", "icon_herb",
			"icon_lark", "icon_mouse", "portrait_mete_child", "portrait_child"]:
		assert_not_null(HudKit.tex(id), "Takımın dokusu: %s" % id)
	assert_eq(HudHotbar.KEYS, ["1", "2", "3", "4", "", "", "", "Q", "E"] as Array[String], "Dokuz yuva: 1–4, üç boş, Q, E")
	assert_eq(HudMenuButtons.BUTTONS.map(func(b: Array) -> String: return str(b[0])), ["I", "J", "M"], "Düğmelerde I, J, M")


func test_shows_only_while_live_and_hides_at_once() -> void:
	await wait_frames(2)
	assert_true(hud.is_shown() and hud.visible, "Oynanırken görünür")
	_live = false
	await wait_frames(1)
	assert_false(hud.visible, "Oyun dışında hemen gizlenir")
	_live = true
	await wait_frames(1)
	assert_true(hud.visible)
	hud.hide_now()
	assert_false(hud.visible, "Duraklatmanın küçük resmi için anında gizlenir")


func test_child_loadout_has_only_the_toy_bow_in_slot_three() -> void:
	hud.hotbar.set_loadout(GameplayHud.CHILD_LOADOUT)
	for i in HudHotbar.KEYS.size():
		assert_eq(hud.hotbar.slot_icon(i), "icon_toy_bow" if i == 2 else "", "Yuva %d" % (i + 1))
	assert_true(HudHotbar.slot_center(0).x < 0.0 and HudHotbar.slot_center(8).x > 0.0, "Şerit ortalı")
	assert_almost(HudHotbar.slot_center(4).x, 0.0, 0.001, "Ortadaki yuva tam ortada")


# --- Görev kartı -------------------------------------------------------------------------------------------

func test_quest_card_shows_the_sources_texts() -> void:
	var q := FakeQuest.new()
	hud.set_quest_source(q)
	await wait_frames(2)
	hud._poll_quest()
	assert_eq(hud.quest_card.title, "Koyun Sırtında")
	assert_eq(hud.quest_card.objective, "Sayım hattına koş")
	assert_eq(hud.quest_card.detail, "Sayıcı sürüyü hattan geçiriyor.")
	assert_true(hud.quest_card.visible, "Görev varken kart görünür")
	q.objective = "Sayılmayı bekle"
	hud._poll_quest()
	assert_eq(hud.quest_card.objective, "Sayılmayı bekle", "Adımın evresi değişince kart yenilenir")
	hud.set_quest_source(null)
	hud._poll_quest()
	assert_false(hud.quest_card.visible, "Görev yoksa kart gizli")


func test_long_detail_wraps_into_two_lines() -> void:
	var f := HudKit.body_font()
	var lines := HudKit.wrap_lines(f, "Shift dürter; koyun otlamaya durursa yeniden dürt ve taşa kadar sür.", 16, 230.0, 2)
	assert_eq(lines.size(), 2, "Uzun ayrıntı iki satır")
	for l in lines:
		assert_true(HudKit.text_width(f, l, 16) <= 230.5, "Satır kutuya sığar: %s" % l)
	assert_eq(HudKit.wrap_lines(f, "Kısa.", 16, 230.0, 2), PackedStringArray(["Kısa."]))


# --- Mini harita ve yön ---------------------------------------------------------------------------------

func test_minimap_rotates_with_the_camera_and_clamps_to_the_rim() -> void:
	# yaw 0: kamera kuzeye (-Z) bakar, kuzeydeki hedef dairede yukarıdadır.
	var up := HudMinimap.offset_on_map(Vector2(0.0, -10.0), 0.0, 2.0)
	assert_almost(up.x, 0.0, 0.001)
	assert_almost(up.y, -20.0, 0.001, "Kuzey yukarıda")
	# Kamera doğuya bakınca (yaw = -PI/2: kamera hedefin batısında) doğudaki hedef yukarıdadır.
	var east := HudMinimap.offset_on_map(Vector2(10.0, 0.0), -PI * 0.5, 1.0)
	assert_almost(east.x, 0.0, 0.001)
	assert_almost(east.y, -10.0, 0.001, "Kameranın baktığı yön yukarı")
	var far: Array = HudMinimap.clamp_to_disc(Vector2(300.0, 0.0), 98.0)
	assert_true(far[1], "Uzak hedef kenarda")
	assert_almost((far[0] as Vector2).length(), 98.0, 0.001)
	var near: Array = HudMinimap.clamp_to_disc(Vector2(20.0, 5.0), 98.0)
	assert_false(near[1])
	# Ok: kameradan uzağa (kuzeye, bakış PI) yürüyen çocuğun oku yukarı bakar.
	assert_almost(HudMinimap.arrow_rotation(PI, 0.0), 0.0, 0.001)
	assert_almost(HudMinimap.arrow_rotation(PI * 0.5, 0.0), PI * 0.5, 0.001, "Doğuya bakan ok sağa döner")


func test_pointer_sits_on_an_ellipse_inside_the_screen() -> void:
	var c := Vector2(960.0, 540.0)
	var half := Vector2(800.0, 380.0)
	var right := HudPointer.edge_point(c, Vector2(1.0, 0.0), half)
	assert_almost(right.x, 1760.0, 0.01)
	var diag := HudPointer.edge_point(c, Vector2(1.0, 1.0), half)
	assert_true(diag.x < 1760.0 and diag.y < 920.0, "Köşeye girmez")
	assert_eq(HudPointer.meters_text(33.6), "34 m")


func test_pointer_pins_visible_targets_and_points_at_hidden_ones() -> void:
	var cam := Camera3D.new()
	cam.fov = 36.0
	add_child(cam)
	cam.global_transform = FollowCamera.compute_transform(Vector3.ZERO, 0.0, 38.0, 22.0)
	cam.make_current()
	await wait_frames(1)
	var view := get_viewport().get_visible_rect().size
	var seen := HudPointer.compute(cam, Vector3(2.0, 0.0, -3.0), Vector3.ZERO, view, 1.0)
	assert_eq(str(seen.get("mode", "")), "pin", "Ekrandaki hedefin üstünde iğne")
	var off := HudPointer.compute(cam, Vector3(120.0, 0.0, 0.0), Vector3.ZERO, view, 1.0)
	assert_eq(str(off.get("mode", "")), "edge", "Ekranın dışındaki hedef: kenarda ok")
	assert_true((off["at"] as Vector2).x > view.x * 0.5, "Ok hedefin yanında (doğu, sağ)")
	var back := HudPointer.compute(cam, Vector3(0.0, 0.0, 60.0), Vector3.ZERO, view, 1.0)
	assert_eq(str(back.get("mode", "")), "edge", "Kameranın arkasındaki hedef de kenarda")
	assert_true((back["at"] as Vector2).y > view.y * 0.5, "Arkadaki hedefin oku ekranın altına bakar")
	assert_true(HudPointer.compute(cam, Vector3(0.5, 0.0, 0.5), Vector3.ZERO, view, 1.0).is_empty(), "Hedefe varınca işaret söner")
	cam.queue_free()


# --- Sayfalar -----------------------------------------------------------------------------------------------

func test_i_opens_the_inventory_and_m_j_ask_for_the_book() -> void:
	hud.set_quest_source(FakeQuest.new())
	hud.set_world_map(WorldMap.bake_fallback(WorldMap.camp_spec(null, null)))
	hud.bag.reset(true)
	await wait_frames(2)
	hud._unhandled_input(_key(KEY_I))
	assert_true(hud.is_screen_open(), "I Envanter'i açar")
	assert_true(hud.screen() is HudInventoryScreen, "Envanter ekranı")
	assert_true(get_tree().paused, "Envanter açıkken oyun durur")
	assert_false(hud.visible, "Envanter açıkken HUD gizli")
	await wait_frames(1)
	hud.screen()._unhandled_input(_key(KEY_ESCAPE))
	assert_false(hud.is_screen_open(), "Esc kapatır")
	assert_false(get_tree().paused, "Kapanınca oyun sürer")
	await wait_frames(2)
	hud._unhandled_input(_key(KEY_I))
	await wait_frames(1)
	hud.screen()._unhandled_input(_key(KEY_I))
	assert_false(hud.is_screen_open(), "I Envanter'i kapatır da")
	await wait_frames(2)
	var asked := watch_signal(hud.book_requested)
	hud._unhandled_input(_key(KEY_M))
	assert_eq(asked.count, 1, "M kitabı ister")
	assert_eq(asked.last_args, ["harita"], "Kitabın HARİTA sayfası")
	hud._unhandled_input(_key(KEY_J))
	assert_eq(asked.last_args, ["gorevler"], "J kitabın GÖREVLER sayfası")
	assert_false(hud.is_screen_open(), "M ve J ayrı ekran açmaz")
	var data := hud.map_page_data()
	assert_eq(data.get("map"), hud.map, "Harita sayfasının verisi pişmiş harita")
	_live = false
	await wait_frames(1)
	assert_false(hud.open_page("bag"), "HUD görünmüyorken sayfa açılmaz")


func test_journal_marks_done_steps_and_hides_the_future() -> void:
	var steps := HudJournalPage.visible_steps(FakeQuest.new().hud_quest()["steps"])
	assert_eq(steps.size(), 3, "Biten, o anki ve tek bir «…»")
	assert_eq(str(steps[0]["state"]), "done")
	assert_eq(str(steps[1]["state"]), "current")
	assert_eq(str(steps[2]["text"]), "…", "Sonraki adım gizli")


func test_bag_holds_the_toy_bow_and_collected_game() -> void:
	var bag := HudBag.new()
	bag.reset(true)
	assert_eq(bag.count("toy_bow"), 1, "Çocuğun yayı hep yanında")
	bag.on_collected(null, {"kind": "lark", "yield": {}})
	bag.on_collected(null, {"kind": "lark", "yield": {}})
	bag.on_collected(null, {"kind": "gerbil", "yield": {}})
	bag.on_collected(null, {})
	assert_eq(bag.count("lark"), 2)
	assert_eq(bag.count("gerbil"), 1)
	var names: Array = bag.entries().map(func(e: Dictionary) -> String: return str(e["name"]))
	assert_eq(names, ["Oyuncak Yay", "Tarla Kuşu", "Kum Faresi"], "Adlar eşya kataloğundan (data/economy/items.json)")
	assert_eq(bag.equipped().keys(), ["bow"], "Oyuncak yay yay yuvasında kuşanılı (progression.md §6.1)")
	var grid: Array = bag.grid().map(func(e: Dictionary) -> String: return str(e["id"]))
	assert_eq(grid, ["lark", "gerbil"], "Izgarada alınan av")
	assert_eq(bag.coins, 0, "I. Perde'de ve Çocukluk'ta kese yok (K48)")
	assert_almost(bag.load_amount(), 0.6, 1e-9, "Av heybede Yük tutar: iki kuş ve fare 0,6 (kuşanılan yay sınırdan düşmez)")
	assert_almost(bag.limit, HudBag.LIMIT_CHILD, 1e-9, "Çocuğun yük sınırı 6")
	bag.reset(false)
	assert_true(bag.entries().is_empty(), "Yetişkinin envanteri boş başlar")
	assert_almost(bag.limit, HudBag.LIMIT_ADULT, 1e-9, "Yetişkin Bilek 3: 21")


func test_inventory_layout_follows_the_design() -> void:
	# Kitabın dili: geniş pencere; kuşanma yuvaları karakterin alanının dışında, ızgara sağ kartta, düğmeler çekmecede.
	assert_true(HudInventoryScreen.SIZE.x >= 1300.0, "Envanter eskisinden (1096) geniş")
	for i in HudInventoryScreen.COLS * HudInventoryScreen.ROWS:
		assert_true(HudInventoryScreen.RIGHT_BOX.encloses(HudInventoryScreen.cell_rect(i)), "Izgara yuvası %d sağ kartta" % i)
	var a := HudInventoryScreen.cell_rect(0)
	var b := HudInventoryScreen.cell_rect(1)
	assert_almost(b.position.x - a.end.x, HudInventoryScreen.GAP, 0.001, "Yuvaların arası 12 px")
	for slot: String in HudBag.EQUIP_LEFT + HudBag.EQUIP_RIGHT:
		var r := HudInventoryScreen.equip_rect(slot)
		assert_true(HudInventoryScreen.LEFT_BOX.encloses(r), "Kuşanma yuvası sol kartta: %s" % slot)
		assert_false(r.grow(24.0).intersects(HudInventoryScreen.CHAR_RECT), "Yuva karaktere değmez (24 px pay): %s" % slot)
	for i in HudInventoryScreen.BUTTONS.size():
		assert_true(HudInventoryScreen.DRAWER.encloses(HudInventoryScreen.button_rect(i)), "Düğme çekmecede")
	assert_eq(HudInventoryScreen.BUTTONS.map(func(btn: Array) -> String: return str(btn[1])), ["Kullan", "Taşı", "Bırak"])
	var inv := HudInventoryScreen.new()
	var bag := HudBag.new()
	bag.reset(true)
	bag.add("lark", 2)
	inv.bag = bag
	inv.person = ChildLook.PERSON_METE
	add_child(inv)
	await wait_frames(2)
	# Çekmece hep görünmez: seçim yokken kapalı; bir eşyanın üstüne gelince ya da seçilince açılır.
	assert_true(inv.selected_entry().is_empty(), "Açılışta seçim yok")
	assert_false(inv.drawer_visible(), "Seçim yokken çekmece kapalı")
	inv._content_gui_input(_motion(HudInventoryScreen.cell_rect(0).get_center()))
	assert_true(inv.drawer_visible(), "Eşyanın üstüne gelince çekmece açılır")
	assert_eq(str(inv.shown_entry().get("id", "")), "lark")
	inv._content_gui_input(_motion(HudInventoryScreen.cell_rect(7).get_center()))
	assert_false(inv.drawer_visible(), "Boş yuvanın üstünde çekmece kapalı")
	assert_true(inv._content_input(_key(KEY_RIGHT)), "Ok tuşu seçer")
	assert_eq(str(inv.selected_entry().get("id", "")), "lark", "İlk ızgara eşyası seçili")
	assert_true(inv.drawer_visible(), "Seçilince çekmece açılır")
	for btn: Array in HudInventoryScreen.BUTTONS:
		assert_false(inv.action_enabled(str(btn[0])), "İşi olmayan eşyada %s sönük" % btn[1])
	inv._content_gui_input(_click(Vector2(660.0, 700.0)))
	assert_false(inv.drawer_visible(), "Boş yere tıklamak seçimi bırakır")
	inv._content_gui_input(_click(HudInventoryScreen.equip_rect("bow").get_center()))
	assert_eq(str(inv.selected_entry().get("id", "")), "toy_bow", "Kuşanılı yay seçilir")
	# 3B karakter: kişinin modeli bekleme klibinde; sürükleyince döner.
	var view := inv.character_view()
	assert_not_null(view, "Karakterin 3B görseli")
	assert_true(HudInventoryScreen.CHAR_RECT.encloses(Rect2(view.position, view.size)), "Görsel karakterin alanında")
	var av := inv.character_avatar()
	assert_not_null(av, "Karakter kurulur")
	if av:
		assert_not_null(av.get_model_node(), "Kişinin modeli yüklü")
		assert_eq(av.get_current_role(), &"idle", "Bekleme klibi")
	var yaw0 := inv.character_yaw()
	view._gui_input(_press_at(Vector2(100.0, 200.0), true))
	var drag := InputEventMouseMotion.new()
	drag.relative = Vector2(80.0, 0.0)
	drag.position = Vector2(180.0, 200.0)
	view._gui_input(drag)
	view._gui_input(_press_at(Vector2(180.0, 200.0), false))
	assert_almost(inv.character_yaw() - yaw0, 80.0 * HudInventoryScreen.DRAG_SENSITIVITY, 0.0001, "Sürükleyince döner")
	inv.queue_free()
	get_tree().paused = false


# --- Görevler ----------------------------------------------------------------------------------------------

func test_camp_tour_walks_the_landmarks_in_order() -> void:
	var journey := Journey.new()
	journey.landmarks = JourneyFlags.build_landmarks(Vector2.ZERO, Vector2(13.76, -14.65), [Vector4(8.0, 6.0, 3.0, 0.0), Vector4(-20.0, 4.0, 2.5, 0.0)],
		[Vector4(-14.0, 12.0, 1.0, 0.0)], Vector2(2.35, -0.65))
	var tour := CampTour.new(journey)
	var q := tour.hud_quest()
	assert_eq(str(q["title"]), "Kampı Dolaş")
	assert_eq(str(q["objective"]), "Ateşin başına var", "İlk adım ateşin başı")
	assert_eq(tour.hud_target(), Vector3.ZERO, "Hedef ocak")
	journey.set_flag(JourneyFlags.FIRESIDE)
	journey.set_flag(JourneyFlags.BARD_LISTEN)
	assert_eq(str(tour.hud_quest()["objective"]), "Ahırdaki atlara bak")
	assert_vec_almost(tour.hud_target(), Vector3(13.76, 0.0, -14.65), 0.01)
	journey.set_flag(JourneyFlags.STABLE)
	assert_vec_almost(tour.hud_target(Vector3(-19.0, 0.0, 4.0)), Vector3(-20.0, 0.0, 4.0), 0.01, "En yakın yosunlu kaya")
	for key in [JourneyFlags.BOULDER, JourneyFlags.FORMATION]:
		journey.set_flag(key)
	var lake := tour.hud_target()
	assert_true(JourneyFlags.overlooks_lake(Vector2(lake.x, lake.z)), "Göl hedefi yamacın içinde")
	journey.set_flag(JourneyFlags.LAKE_VIEW)
	q = tour.hud_quest()
	assert_true(bool(q["done"]), "Hepsi bitti")
	assert_eq(str(q["objective"]), CampTour.DONE_TEXT)
	assert_eq(tour.hud_target(), Vector3.INF, "Bitince hedef yok")
	for s: Dictionary in q["steps"]:
		assert_eq(str(s["state"]), "done")


func test_childhood_quest_lists_its_four_steps() -> void:
	var data := ChildhoodScene.load_data()
	var q := ChildhoodScene.quest_of(data, 1)
	assert_eq(str(q["title"]), "Koyun Sırtında")
	assert_eq(str(q["objective"]), "Yaşlı koyuna bin")
	var states: Array = (q["steps"] as Array).map(func(s: Dictionary) -> String: return str(s["state"]))
	assert_eq(states, ["done", "current", "todo", "todo"])
	var texts: Array = (q["steps"] as Array).map(func(s: Dictionary) -> String: return str(s["text"]))
	assert_eq(texts, ["Ağıla git", "Yaşlı koyuna bin", "İki tarla kuşu vur ve al", "Sayım hattına koş"])
	assert_true(bool(ChildhoodScene.quest_of(data, 4)["done"]), "Bitmiş görev (Serbest Gez'in Görevler sayfası)")


func test_world_map_maps_the_walk_area_north_up() -> void:
	var r := WorldMap.area_rect(Vector2(26.0, 10.0), 58.0)
	assert_almost(r.size.x, (58.0 * WorldMap.REACH + WorldMap.MARGIN) * 2.0, 0.001, "Yürünür alanın çevresi de pişer (tam ekran harita)")
	var map := WorldMap.bake_fallback({"key": "t", "center": Vector2(26.0, 10.0), "radius": 58.0})
	assert_almost(map.uv(Vector2(26.0, 10.0)).x, 0.5, 0.001, "Alanın ortası haritanın ortası")
	assert_true(map.uv(Vector2(26.0, -30.0)).y < 0.5, "Kuzey (-Z) yukarıda")
	assert_true(map.uv(Vector2(60.0, 10.0)).x > 0.5, "Doğu (+X) sağda")
	assert_not_null(map.texture, "Başsızda yedek doku")
	assert_false(map.baked)
	var t := WorldMap.top_down_transform(Vector2(3.0, 4.0), WorldMap.CAMERA_HEIGHT)
	assert_vec_almost(-t.basis.z, Vector3.DOWN, 0.0001, "Pişirme kamerası dik aşağı bakar")
	assert_vec_almost(t.basis.y, Vector3(0.0, 0.0, -1.0), 0.0001, "Görüntünün yukarısı kuzey")
	assert_vec_almost(t.basis.x, Vector3.RIGHT, 0.0001, "Görüntünün sağı doğu")
	assert_vec_almost(t.origin, Vector3(3.0, WorldMap.CAMERA_HEIGHT, 4.0), 0.0001)


# --- Girdi ve tuşlar sayfası ---------------------------------------------------------------------------------

func test_input_actions_for_the_hud_and_jump() -> void:
	for pair: Array in [[&"inventory", KEY_I], [&"journal", KEY_J], [&"map", KEY_M], [&"jump", KEY_SPACE]]:
		assert_true(InputMap.has_action(pair[0]), "Eylem: %s" % pair[0])
		assert_true(InputMap.event_is_action(_key(pair[1]), pair[0]), "%s tuşu" % pair[0])
	assert_true(InputMap.event_is_action(_key(KEY_SPACE), &"book_intro"), "Boşluk menüde tanıtımı çalar")
	assert_ne(InputSetup.CONTEXTS[&"jump"], InputSetup.CONTEXTS[&"book_intro"], "Boşluğun iki işi ayrı bağlamda")
	assert_eq(InputSetup.conflicts(), [], "Aynı bağlamda aynı tuşu paylaşan eylem yok")


func test_controls_page_lists_i_j_m_and_jump() -> void:
	var rows := PackedStringArray()
	for g: Array in ControlsPage.GROUPS:
		for row: Array in g[1]:
			var keys: Array = (row[2] as Array).duplicate()
			if str(row[1]) != "":
				keys = ControlsPage.keys_of(str(row[1])) + keys
			rows.append("%s=%s" % [row[0], ",".join(PackedStringArray(keys))])
	for want in ["Envanter=I", "Görevler=J", "Harita=M", "Zıpla=Boşluk", "Atı sıçrat=Boşluk", "Ata bin / in=E"]:
		assert_true(rows.has(want), "Tuşlar sayfası: %s" % want)
	var uses := ControlsPage.key_uses()
	var space: Array = (uses.get("Space", []) as Array).map(func(u: Array) -> String: return str(u[0]))
	assert_true(space.has("Zıpla") and space.has("Tanıtım"), "Klavyede Boşluk: oyunda zıpla, menüde tanıtım")


# --- HUD ölçeği (K104: tek arayüz ölçeği) ------------------------------------------------------------------------

## HUD'un ölçeği ayrı bir ayar değildir: Ayarlar'ın tek «Arayüz ölçeği» (%50–%150) menüleri ui_k() ile, HUD'u ui_k() × 0,8 ile çizer;
## ayar %100'de HUD eski «HUD ölçeği %80»inin boyundadır (kullanıcının E20'deki eşlemesi).
func test_hud_scale_is_a_share_of_the_one_ui_scale() -> void:
	assert_almost(HudKit.HUD_SCALE, 0.8, 0.0001, "HUD menülerin 0,8 katı")
	assert_almost(HudKit.hud_scale(), HudKit.HUD_SCALE, 0.0001)
	var script := preload("res://scripts/settings/game_settings.gd")
	var as_script: Script = script
	assert_false(as_script.get_script_constant_map().has("HUD_SCALES"), "Ayrı HUD ölçeği adımları yok")
	var st: Node = script.new()
	st.persist = false
	st.apply_window = false
	assert_false("hud_scale" in st, "Ayrı HUD ölçeği ayarı yok")
	st.ui_scale = 1.0
	assert_almost(st.ui_k() * HudKit.hud_scale(), 1.0 * 0.8 * script.res_ui_factor(st.window_pixels()), 0.0001,
		"Ayar %100: HUD eski arayüz %100 + HUD %80'i gibi")
	st.free()


func test_hud_parts_follow_the_ui_scale_and_keep_off_the_hints() -> void:
	var auto := UIKit.settings_node()
	assert_not_null(auto, "Ayar autoload'u")
	if auto == null:
		return
	var was: float = auto.ui_scale
	hud.action_prompt.set_pairs([["E", "Bin"]])
	await wait_frames(1)
	for u: float in [0.5, 1.0, 1.5]:
		auto.ui_scale = u
		auto.apply()
		await wait_frames(1)
		var k := UIKit.ui_k()
		var pct := roundi(u * 100.0)
		assert_almost(k, u * auto.res_ui_factor(auto.window_pixels()), 0.0001, "ui_k oyuncunun ölçeğini taşır (%d%%)" % pct)
		for c: Control in [hud.portrait, hud.minimap, hud.quest_card, hud.hotbar, hud.buttons, hud.action_prompt]:
			assert_almost(c.scale.x, k * HudKit.HUD_SCALE, 0.0001, "%s ölçeği (%d%%)" % [c.name, pct])
		assert_almost(hud.pointer.ui_scale, k * HudKit.HUD_SCALE, 0.0001)
		# XP çubuğunun alt kenarı ekranın altından HUD_FLOOR × ui_k uzakta (altındaki tuş ipuçlarına değmez): yuvalar yukarı doğru büyür.
		var view_h := hud.get_rect().size.y
		var xp_bottom := hud.hotbar.get_global_transform() * (HudKit.XP_RECT.end - HudHotbar.BOX.position)
		assert_almost(view_h - xp_bottom.y, HudKit.HUD_FLOOR * k, 0.6, "XP çubuğu yerinde (%d%%)" % pct)
		var prompt_bottom := hud.action_prompt.get_global_transform() * Vector2(0.0, hud.action_prompt.size.y)
		var slots_top := hud.hotbar.get_global_transform() * (Vector2(0.0, HudKit.SLOT_CENTER_Y - HudKit.SLOT_SIZE.y * 0.5) - HudHotbar.BOX.position)
		assert_true(prompt_bottom.y <= slots_top.y + 0.5, "Eylem şeridi yuvaların üstünde (%d%%)" % pct)
		# Basılı tutuşun halkası (ateş başında Dinlen, G Yükü Bırak) eylem şeridinin üstündedir; adı halkanın üstünde yazar.
		var prompt_top := hud.action_prompt.get_global_transform() * Vector2.ZERO
		var rk := k * HudKit.hud_scale()
		var ring := hud.hold_center()
		assert_true(ring.y + (GameplayHud.HOLD_RADIUS + 6.0) * rk <= prompt_top.y - 0.5, "Halka eylem şeridine değmez (%d%%)" % pct)
		assert_almost(ring.x, hud.get_rect().size.x * 0.5, 0.5, "Halka ortada (%d%%)" % pct)
		var portrait_end := hud.portrait.get_global_transform() * HudKit.PORTRAIT_SIZE
		var card_left := hud.quest_card.get_global_transform() * Vector2.ZERO
		assert_true(portrait_end.x < card_left.x, "Portre görev kartına değmez (%d%%)" % pct)
	auto.ui_scale = was
	auto.apply()


func test_key_hints_follow_the_ui_scale_below_the_xp_bar() -> void:
	# E18.4, K104: tuş ipuçları şeridi HUD'un ölçeğindedir (arayüz × 0,8); XP çubuğu her ölçekte şeridin üstünde kalır, %100'de yeri değişmez.
	var auto := UIKit.settings_node()
	assert_not_null(auto, "Ayar autoload'u")
	if auto == null:
		return
	var was: float = auto.ui_scale
	var strip := preload("res://scenes/ui/game_hud.tscn").instantiate() as GameHud
	add_child(strip)
	hud.hints = strip
	hud.call("_lift_prompt", true)
	await wait_frames(1)
	var panel := strip.get_node("%HintPanel") as Control
	for u: float in [0.5, 1.0, 1.5]:
		auto.ui_scale = u
		auto.apply()
		await wait_frames(1)
		var k := UIKit.ui_k()
		var pct := roundi(u * 100.0)
		assert_almost(panel.scale.x, k * HudKit.HUD_SCALE, 0.0001, "Şerit HUD'un ölçeğinde (%d%%)" % pct)
		var xp_bottom := hud.hotbar.get_global_transform() * (HudKit.XP_RECT.end - HudHotbar.BOX.position)
		var strip_top := panel.get_global_rect().position.y
		assert_true(strip_top >= xp_bottom.y + HudKit.HINTS_GAP * k - 0.6, "Şerit XP çubuğunun altında (%d%%): %.1f ≥ %.1f" % [pct, strip_top, xp_bottom.y])
		if is_equal_approx(u, 1.0):
			assert_almost(hud.get_rect().size.y - xp_bottom.y, HudKit.HUD_FLOOR * k, 0.6, "%100'de XP çubuğu yerinde")
	hud.call("_lift_prompt", false)
	await wait_frames(1)
	assert_almost(panel.scale.x, UIKit.ui_k(), 0.0001, "HUD kapanınca şerit arayüz ölçeğine döner")
	auto.ui_scale = was
	auto.apply()
	hud.hints = null
	strip.queue_free()


func test_hud_kit_lift_keeps_the_xp_bar_floor() -> void:
	for s: float in [0.8, 0.9, 1.0, 1.1, 1.2, 1.3]:
		var lift := HudKit.lift_for(s)
		# Çapanın çevresinde s ile ölçeklenen, lift kadar kaymış XP çubuğunun alt kenarı: -(FLOOR − lift) × s = -FLOOR.
		assert_almost((-HudKit.HUD_FLOOR + lift) * s, -HudKit.HUD_FLOOR, 0.0001)
	assert_almost(HudKit.lift_for(1.0), 0.0, 0.0001, "%100'de kayma yok")


# --- Yuva basılma efekti ----------------------------------------------------------------------------------------

func test_slots_flash_when_pressed_even_empty() -> void:
	await wait_frames(2)
	var bar := hud.hotbar
	var pressed := watch_signal(bar.slot_pressed)
	assert_false(bar.is_pressing(0))
	bar._input(_key(KEY_1))
	assert_true(bar.is_pressing(0), "1 boş yuvaya basar")
	assert_eq(pressed.last_args, [0])
	bar._input(_key(KEY_Q))
	assert_eq(pressed.last_args, [7], "Q yedinci yuva")
	bar._input(_key(KEY_E))
	assert_eq(pressed.last_args, [8], "E dokuzuncu yuva")
	bar._input(_key(KEY_5))
	assert_eq(pressed.count, 3, "Yuvası olmayan tuş basmaz")
	var held := InputEventKey.new()
	held.physical_keycode = KEY_2
	held.pressed = true
	held.echo = true
	bar._input(held)
	assert_eq(pressed.count, 3, "Basılı tutulan tuşun yinelemesi saymaz")
	# Fare: yalnız altıgenin içi tutulur ve basar.
	var c3 := HudHotbar.slot_center(2) - HudHotbar.BOX.position
	assert_true(bar._has_point(c3), "Yuvanın içi fareyi tutar")
	assert_false(bar._has_point(Vector2(c3.x, c3.y + 60.0)), "XP çubuğu ve aralar fareyi geçirir")
	bar._gui_input(_click(c3))
	assert_eq(pressed.last_args, [2], "Tıklamak da basar (dolu yuva: oyuncak yay)")
	# Efekt: kısa sürede küçülür, hafif taşar, PRESS_TIME'da yerine döner.
	assert_almost(HudHotbar.press_scale(0.0), 1.0, 0.0001)
	assert_almost(HudHotbar.press_scale(HudHotbar.PRESS_DOWN), HudHotbar.PRESS_SQUASH, 0.0001, "En küçük ölçek")
	var peak := 0.0
	for i in 40:
		peak = maxf(peak, HudHotbar.press_scale(HudHotbar.PRESS_DOWN + (HudHotbar.PRESS_TIME - HudHotbar.PRESS_DOWN) * i / 40.0))
	assert_true(peak > 1.0 and peak < 1.06, "Geri gelirken hafif taşar")
	assert_almost(HudHotbar.press_scale(HudHotbar.PRESS_TIME), 1.0, 0.0001)
	assert_true(HudHotbar.press_glow(0.0) > 0.99 and HudHotbar.press_glow(HudHotbar.PRESS_TIME) == 0.0, "Işıltı söner")
	await get_tree().create_timer(HudHotbar.PRESS_TIME + 0.15).timeout
	assert_false(bar.is_pressing(0), "Efekt biter")
	assert_almost(bar.slot_scale(0), 1.0, 0.0001)
	get_tree().paused = true
	bar._input(_key(KEY_1))
	assert_false(bar.is_pressing(0), "Oyun dururken basmaz")
	get_tree().paused = false


# --- Harita ve Görevler sayfaları --------------------------------------------------------------------------------

# Haritanın kamerası, yakınlaşması ve atlası: tests/unit/test_atlas.gd.

func test_book_map_page_fills_under_the_tab_bar() -> void:
	var book := GameMenu.new()
	book.mode = "game"
	book.hud = hud
	hud.set_world_map(WorldMap.bake_fallback(WorldMap.camp_spec(null, null)))
	add_child(book)
	book.show_page("harita")
	await wait_frames(2)
	var page := book.get_page()
	assert_true(page is HudMapPage, "HARİTA sayfası")
	var content := page.get_parent() as Control
	assert_almost(content.offset_top, GameMenu.BAR_H, 0.01, "Üst menünün hemen altından")
	assert_almost(content.offset_bottom, 0.0, 0.01, "Ekranın altına dek")
	assert_false(book._foot_bar.visible, "Alt şerit gizli")
	book.show_page("gorevler")
	await wait_frames(1)
	assert_true(book._foot_bar.visible, "Görevler'de alt şerit yerinde")
	assert_almost((book.get_page().get_parent() as Control).offset_bottom, -GameMenu.FOOT_H - 4.0, 0.01)
	book.queue_free()


func test_journal_page_lives_in_the_book_without_its_own_card() -> void:
	var jp := HudJournalPage.new()
	var done := {"id": "old", "title": "Eski İş", "objective": "", "steps": [], "done": true}
	jp.quests = [done, FakeQuest.new().hud_quest()]
	jp.size = Vector2(1920.0, 900.0)
	add_child(jp)
	jp.size = Vector2(1920.0, 900.0)
	await wait_frames(1)
	var cards: Array = HudJournalPage.cards_for(jp.size)
	var list: Rect2 = cards[0]
	var detail: Rect2 = cards[1]
	assert_almost(detail.end.x - list.position.x, HudJournalPage.MAX_W, 0.5, "Kartlar sayfanın genişliğine yayılır (TUŞLAR gibi)")
	assert_almost(list.position.y, HudJournalPage.MARGIN.y, 0.01, "Üst menünün hemen altından başlar")
	var lay := HudJournalPage.layout_rows(jp.quests, 0.0)
	assert_eq((lay["rows"] as Array).map(func(r: Dictionary) -> int: return int(r["index"])), [1, 0], "Süren görev önce, biten sonra")
	assert_eq((lay["heads"] as Array).map(func(h: Dictionary) -> String: return str(h["text"])), ["SÜREN", "BİTEN"])
	jp.selected = 1
	jp._unhandled_input(_key(KEY_DOWN))
	assert_eq(jp.selected, 0, "Aşağı: listede sonraki (biten) görev")
	jp._gui_input(_click(jp.row_rect(1).get_center()))
	assert_eq(jp.selected, 1, "Tıklamak seçer")
	jp.queue_free()


# --- Ana sahne: Serbest Gez ------------------------------------------------------------------------------------

func test_free_roam_shows_the_hud_with_the_camp_tour_and_map() -> void:
	hud.queue_free()
	_dir = TempDir.fresh("hud")
	var main = load(MAIN_SCENE).instantiate()
	main.quit_handler = func() -> void: pass
	main.saves = SaveSystem.new(_dir)
	main.prologue_path = ""
	add_child(main)
	await wait_frames(3)
	var g: GameplayHud = main.gameplay_hud
	assert_not_null(g, "Ana sahnede oyun içi HUD")
	assert_false(g.visible, "Menüde HUD gizli")
	main.menu.finish_intro()
	main.menu.free_roam_requested.emit()
	var deadline := Time.get_ticks_msec() + 8000
	while main.state != main.State.PLAYING and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	await wait_frames(2)
	assert_true(g.visible and g.is_shown(), "Serbest Gez'de HUD görünür")
	assert_eq(g.get_index(), main.fade.get_index() - 1, "HUD perdenin altında")
	assert_eq(g.portrait.person, ChildLook.PERSON_CHILD, "Çocuğun portresi")
	assert_eq(g.hotbar.slot_icon(2), "icon_toy_bow", "Çocuğun yayı 3. yuvada")
	g._poll_quest()
	assert_eq(str(g.quest_info().get("title", "")), "Kampı Dolaş", "Serbest Gez'in görevi")
	assert_eq(g.quest_card.objective, "Ateşin başına var")
	assert_ne(g.pointer.target, Vector3.INF, "Görevin hedefi yön işaretinde")
	assert_not_null(g.map, "Kampın haritası")
	assert_almost(main._prompt.modulate.a, 0.0, 0.001, "Oyuncunun ipucu panelinin yerine HUD'un şeridi")
	assert_eq(g.action_prompt.get_text(), main._prompt.get_text(), "HUD'un şeridi aynı ipucunu gösterir")
	assert_true(main.hud.hud_style, "Tuş ipuçları HUD'un dilinde")
	assert_almost(main.hud.bottom_margin, GameplayHud.HINTS_BOTTOM, 0.01, "Tuş ipuçları XP çubuğunun altında")
	assert_true(main._toast.centered, "Bildirim mini haritanın önüne düşmesin: üst ortada")
	# Esc: duraklatma kitabı, HUD gizli; Devam Et: HUD geri.
	main._on_pause_requested()
	await wait_frames(2)
	assert_false(g.visible, "Duraklatmada HUD gizli")
	assert_false(main._toast.centered, "HUD gizliyken bildirim yerine döner")
	main.pause_menu.close()
	main._on_pause_resumed()
	await wait_frames(2)
	assert_true(g.visible, "Oyuna dönünce HUD geri")
	# I: Envanter açılır, oyun durur; Esc kapatır.
	g._unhandled_input(_key(KEY_I))
	assert_true(g.is_screen_open() and get_tree().paused, "I Envanter'i açar, oyun durur")
	var inv := g.screen() as HudInventoryScreen
	assert_not_null(inv)
	assert_false(main._toast.visible, "Envanter açıkken bildirim gizli")
	assert_false(main.hud.visible, "Envanter açıkken tuş ipuçları gizli")
	if inv:
		assert_eq(inv.person, ChildLook.PERSON_CHILD, "Envanterde oynanan kişinin görseli")
		assert_true(inv.bag.equipped().has("bow"), "Çocuğun yayı kuşanılı")
		assert_false(inv.drawer_visible(), "Çekmece seçimsiz kapalı")
		assert_true(inv.character_avatar() != null and inv.character_avatar().get_model_node() != null, "Çocuğun 3B görseli")
		inv._unhandled_input(_key(KEY_ESCAPE))
	assert_false(get_tree().paused)
	assert_true(main._toast.visible, "Envanter kapanınca bildirim geri")
	await wait_frames(2)
	# M: duraklatma kitabı HARİTA sayfasında açılır (oyun durur); M yeniden kitabı kapatır.
	g._unhandled_input(_key(KEY_M))
	await wait_frames(2)
	assert_true(main.pause_menu.is_open() and get_tree().paused, "M duraklatma kitabını açar")
	var book: GameMenu = main.pause_menu.get_menu()
	if book:
		assert_eq(book.current_page(), "harita", "Kitap HARİTA sayfasında")
		var page := book.get_page() as HudMapPage
		assert_not_null(page, "Harita sayfası")
		if page:
			assert_eq(page.map, g.map, "Kitabın haritası aynı pişmiş harita")
			assert_ne(page.target_xz, Vector2.INF, "Görevin baklavası haritada")
			assert_false(book._foot_bar.visible, "Harita sayfasında alt şerit gizli")
			assert_almost(page.get_parent().offset_bottom, 0.0, 0.01, "Harita üst menünün altını ekranın altına dek kaplar")
		book._input(_key(KEY_J))
		assert_eq(book.current_page(), "gorevler", "J kitabın GÖREVLER sayfasına geçer")
		assert_true(book._foot_bar.visible, "Öteki sayfalarda alt şerit yerinde")
		var jp := book.get_page() as HudJournalPage
		assert_true(jp != null and not jp.quests.is_empty() and str(jp.quests[0]["title"]) == "Kampı Dolaş", "Görevler sayfasında süren görev")
		book._input(_key(KEY_M))
		assert_eq(book.current_page(), "harita")
		book._input(_key(KEY_M))
	await wait_frames(2)
	assert_false(main.pause_menu.is_open(), "Açık sayfanın tuşu kitabı kapatır")
	assert_false(get_tree().paused)
	main.queue_free()
	await wait_frames(2)


static func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = true
	return e


static func _motion(at: Vector2) -> InputEventMouseMotion:
	var e := InputEventMouseMotion.new()
	e.position = at
	return e


static func _press_at(at: Vector2, down: bool, button := MOUSE_BUTTON_LEFT) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.position = at
	e.button_index = button
	e.pressed = down
	return e


static func _click(at: Vector2) -> InputEventMouseButton:
	return _press_at(at, true)
