extends TestCase
## MainMenu (Tanhu 1'in açılış ekranı) testleri: logo, süs çizgisi ve alt yazı; düğüm butonları sütunu
## ve sırası; kayıt yokken / varken DEVAM ET ve YÜKLE; yukarı / aşağı başa saran ve pasifleri atlayan
## odak; SERBEST GEZ; DEVAM ET'in yanındaki kart; YENİ OYUN sorusu; YÜKLE paneli; AYARLAR ve
## DESTAN KİTABI kitapları; atlanabilir giriş; görünürlük geçişleri; 16:9 / 16:10 / 21:9 yerleşimi.
## Düğüm butonunun Tanhu vurgusu (sıcak parıltı, fırça, altın yazı, hafif büyüme) da burada sınanır.

const MENU_SCENE := preload("res://scenes/ui/main_menu.tscn")
const TempDir := preload("res://tests/support/temp_dir.gd")
const EXPECTED_TEXTS: Array[String] = ["YENİ OYUN", "DEVAM ET", "YÜKLE", "DESTAN KİTABI", "AYARLAR", "ÇIKIŞ"]

var menu: MainMenu
var dir := ""


func before_each() -> void:
	# Arayüz sesleri susturulur (çıkışta yarım kalan ses oynatıcısı kalmasın); sonraki testler de sessiz kalır.
	MenuStyle.muted = true
	dir = TempDir.fresh("menu")
	menu = _new_menu(false)
	add_child(menu)


# Not: koşucu after_each'i beklemez (await etmez); burada bekleme yapılırsa geri kalanı bir sonraki
# testin ortasında çalışır (ör. onun kayıtlarını siler). Bu yüzden her şey hemen yapılır.
func after_each() -> void:
	for action in [&"ui_up", &"ui_down", &"ui_left", &"ui_right", &"ui_accept"]:
		Input.action_release(action)
	if is_instance_valid(menu):
		menu.queue_free()
	menu = null
	TempDir.wipe(dir)


func _new_menu(auto: bool) -> MainMenu:
	var m := MENU_SCENE.instantiate() as MainMenu
	m.auto_show = auto
	m.transition_speed = 12.0
	m.saves = SaveSystem.new(dir)
	return m


## Geçici klasöre bir kayıt yazar.
func _write_save(slot: int, flags: Dictionary = {}, unix: float = 1000.0, save_no: int = 1) -> void:
	var record := SaveData.build(CharacterProfile.new(), Vector3(1, 0, 2), 0.5, flags, 125.0, save_no, "ocak", "2026-10-26T06:53:12", unix)
	assert_true(SaveSystem.new(dir).write(slot, record), "Deneme kaydı yazılmalı")


func _with_saves() -> void:
	_write_save(1, {"ahir_ziyaret": true}, 1000.0, 1)
	menu.saves = SaveSystem.new(dir)


## Koşul sağlanana ya da süre dolana kadar bekler; sağlandıysa true döner.
func await_condition(condition: Callable, timeout_sec: float = 3.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while not condition.call():
		if Time.get_ticks_msec() > deadline:
			return false
		await get_tree().process_frame
	return true


## Sinyal yayılana ya da süre dolana kadar bekler; geldiyse true döner (testler takılmasın diye).
func await_or_timeout(sig: Signal, timeout_sec: float = 3.0) -> bool:
	var state := {"done": false}
	var on_done := func(_a: Variant = null) -> void: state["done"] = true
	sig.connect(on_done, CONNECT_ONE_SHOT)
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while not state["done"] and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	if sig.is_connected(on_done):
		sig.disconnect(on_done)
	return state["done"]


## Bir eylem tuşuna basıp bırakır (klavye / oyun kolu benzetimi).
func _tap_action(action: StringName) -> void:
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		Input.parse_input_event(event)
		await wait_frames(2)


func _focused() -> Control:
	return get_viewport().gui_get_focus_owner()


# --- Başlık, sütun ve köşe ------------------------------------------------------------------

func test_column_has_tanhu1_buttons_in_order() -> void:
	var buttons := menu.get_main_buttons()
	assert_eq(buttons.size(), EXPECTED_TEXTS.size(), "Masaüstünde altı buton olmalı")
	var column := buttons[0].get_parent().get_parent()
	for i in buttons.size():
		assert_true(buttons[i] is KnotButton, "%d. buton düğüm butonu olmalı" % i)
		assert_eq(buttons[i].text, EXPECTED_TEXTS[i], "%d. buton yazısı" % i)
		assert_eq(buttons[i].get_parent().get_parent(), column, "Butonlar aynı sütunda olmalı")
		assert_eq(buttons[i].get_parent().get_index(), i, "Sütundaki sıra")
	for key in ["new", "continue", "load", "book", "settings", "quit"]:
		assert_not_null(menu.get_button(key), "Buton eksik: %s" % key)
	assert_eq(MainMenu.items().size(), EXPECTED_TEXTS.size(), "ÇIKIŞ yalnızca web ve mobilde gizlenir")


func test_logo_ornament_subtitle_and_footer() -> void:
	var logo := menu.find_child("Logo", true, false)
	assert_true(logo is TextureRect, "Tanhu 1'in logosu (assets/title/logo.png) gösterilmeli")
	if logo is TextureRect:
		assert_eq((logo as TextureRect).texture.resource_path, MainMenu.LOGO_PATH)
	assert_eq(menu.find_children("*", "OrnamentLine", true, false).size(), 1, "Logonun altında süs çizgisi olmalı")
	var sub := menu.find_child("Subtitle", true, false) as Label
	assert_not_null(sub)
	if sub:
		assert_eq(sub.text, "BİR BOZKIR DESTANI")
	var texts := PackedStringArray()
	for l in menu.find_children("*", "Label", true, false):
		texts.append((l as Label).text)
	assert_true("Kulaklıkla oynaman önerilir" in texts, "Sağ altta kulaklık önerisi olmalı")
	assert_true(MainMenu.version_text() in texts, "Sağ altta sürüm yazmalı")
	assert_eq(MainMenu.version_text(), "v0.1.0")
	assert_true("Kampta dolaş" in texts, "SERBEST GEZ'in altında ipucu olmalı")
	assert_eq(menu.get_free_roam_button().text, "SERBEST GEZ")
	assert_false(menu.get_free_roam_button() in menu.get_main_buttons(), "Serbest Gez sütunun dışında olmalı")


func test_continue_and_load_are_disabled_without_saves() -> void:
	menu.show_menu(false)
	for key in ["continue", "load"]:
		var b := menu.get_button(key)
		assert_true(b.disabled, "%s kayıt yokken pasif olmalı" % b.text)
		assert_eq(b.focus_mode, Control.FOCUS_NONE, "Pasif buton odak almamalı")
		assert_almost(b.modulate.a, MainMenu.DISABLED_ALPHA, 0.01, "Pasif buton soluk görünmeli")
	for key in ["new", "book", "settings", "quit"]:
		assert_false(menu.get_button(key).disabled, "%s her zaman açık olmalı" % key)
	await wait_frames(1)
	assert_eq(_focused(), menu.get_button("new"), "Kayıt yokken odak YENİ OYUN'da başlamalı")


func test_continue_and_load_enabled_with_a_save_and_focus_starts_on_continue() -> void:
	_with_saves()
	menu.show_menu(false)
	for key in ["continue", "load"]:
		assert_false(menu.get_button(key).disabled, "%s kayıt varken açık olmalı" % key)
	await wait_frames(1)
	assert_eq(_focused(), menu.get_button("continue"), "Kayıt varken odak DEVAM ET'te başlamalı")


func test_card_shows_latest_save_beside_continue() -> void:
	_write_save(1, {}, 1000.0, 1)
	_write_save(4, {}, 5000.0, 2)
	menu.saves = SaveSystem.new(dir)
	menu.show_menu(false)
	await wait_frames(2)
	assert_true(menu.is_card_shown(), "DEVAM ET seçiliyken kart görünmeli")
	var card := menu.get_card()
	assert_true(card.summary().contains("Gece Kampı · Ocak başı"), "Kartta yer yazmalı: %s" % card.summary())
	assert_true(card.summary().contains("Kayıt #2"), "Kart en son kaydı (4. yuva, #2) göstermeli: %s" % card.summary())
	assert_true(card.summary().contains("0 sa 02 dk"), "Kartta oynanan süre yazmalı")
	var cont := menu.get_button("continue")
	assert_true(card.position.x > cont.get_global_rect().end.x - 1.0, "Kart DEVAM ET'in sağında durmalı")
	menu.get_button("new").grab_focus()
	assert_true(await await_condition(func() -> bool: return not menu.is_card_shown()), "Odak gidince kart kaybolmalı")


# --- Odak ve gezinme -------------------------------------------------------------------------

func test_up_down_wrap_and_skip_disabled_buttons() -> void:
	menu.show_menu(false)
	await wait_frames(1)
	var new := menu.get_button("new")
	assert_eq(new.get_node(new.focus_neighbor_bottom), menu.get_button("book"), "Aşağı pasif butonları atlamalı")
	assert_eq(new.get_node(new.focus_neighbor_top), menu.get_button("quit"), "Yukarı baştan sona sarmalı")
	var quit := menu.get_button("quit")
	assert_eq(quit.get_node(quit.focus_neighbor_bottom), new, "Aşağı sondan başa sarmalı")
	await _tap_action(&"ui_down")
	assert_eq(_focused(), menu.get_button("book"), "Aşağı ok DESTAN KİTABI'na inmeli")
	await _tap_action(&"ui_up")
	await _tap_action(&"ui_up")
	assert_eq(_focused(), quit, "Yukarı ok baştan sona sarmalı")


func test_right_goes_to_free_roam_and_left_comes_back() -> void:
	menu.show_menu(false)
	await wait_frames(1)
	menu.get_button("settings").grab_focus()
	await _tap_action(&"ui_right")
	assert_eq(_focused(), menu.get_free_roam_button(), "Sağ ok SERBEST GEZ'e geçmeli")
	await _tap_action(&"ui_left")
	assert_eq(_focused(), menu.get_button("settings"), "Sol ok son seçilen sütun butonuna dönmeli")


func test_mouse_hover_takes_focus_but_not_on_disabled_buttons() -> void:
	menu.show_menu(false)
	await wait_frames(1)
	menu.get_button("continue").mouse_entered.emit()
	assert_ne(_focused(), menu.get_button("continue"), "Pasif butona gelmek odak vermemeli")
	menu.get_button("quit").mouse_entered.emit()
	assert_eq(_focused(), menu.get_button("quit"), "Üzerine gelinen buton odak almalı")


func test_gamepad_buttons_drive_the_menu() -> void:
	MenuStyle.ensure_pad_actions()
	var a := InputEventJoypadButton.new()
	a.button_index = JOY_BUTTON_A
	a.pressed = true
	var b := InputEventJoypadButton.new()
	b.button_index = JOY_BUTTON_B
	b.pressed = true
	assert_true(a.is_action(&"ui_accept"), "Oyun kolunda A seçmeli")
	assert_true(b.is_action(&"ui_cancel"), "Oyun kolunda B geri çıkmalı")
	var before := InputMap.action_get_events(&"ui_accept").size()
	MenuStyle.ensure_pad_actions()
	assert_eq(InputMap.action_get_events(&"ui_accept").size(), before, "Tekrar çağrı düğmeyi iki kez eklememeli")
	var down := InputEventJoypadButton.new()
	down.button_index = JOY_BUTTON_DPAD_DOWN
	assert_true(down.is_action(&"ui_down"), "Yön tuşları butonlarda gezmeli")


# --- Butonların işleri --------------------------------------------------------------------------

func test_buttons_emit_their_signals() -> void:
	_with_saves()
	menu.show_menu(false)
	await wait_frames(1)
	var cont := watch_signal(menu.continue_requested)
	var quit := watch_signal(menu.quit_requested)
	var free := watch_signal(menu.free_roam_requested)
	var start := watch_signal(menu.start_requested)
	menu.get_button("continue").pressed.emit()
	menu.get_button("quit").pressed.emit()
	menu.get_free_roam_button().pressed.emit()
	assert_eq(cont.count, 1, "DEVAM ET continue_requested yaymalı")
	assert_eq(quit.count, 1, "ÇIKIŞ quit_requested yaymalı")
	assert_eq(free.count, 1, "SERBEST GEZ free_roam_requested yaymalı")
	assert_false(start.fired, "Diğer butonlar başlatmamalı")


func test_new_game_starts_right_away_without_saves() -> void:
	menu.show_menu(false)
	var start := watch_signal(menu.start_requested)
	menu.get_button("new").pressed.emit()
	assert_eq(start.count, 1, "Kayıt yokken YENİ OYUN hemen başlamalı")
	assert_false(menu.is_page_open())


func test_new_game_asks_first_when_a_save_exists() -> void:
	_with_saves()
	menu.show_menu(false)
	await wait_frames(1)
	var start := watch_signal(menu.start_requested)
	menu.get_button("new").pressed.emit()
	await wait_frames(2)
	var dialog := menu.get_page() as ConfirmDialog
	assert_not_null(dialog, "Kayıt varken YENİ OYUN önce sormalı (Tanhu 1'in sorusu)")
	if dialog == null:
		return
	assert_eq(_focused(), dialog.no_button, "Odak önce HAYIR'da olmalı")
	assert_false(menu.is_accepting_input(), "Soru açıkken menü butonları tepki vermemeli")
	dialog.answer(false)
	assert_true(await await_condition(func() -> bool: return not menu.is_page_open()), "Soru kapanmalı")
	assert_false(start.fired, "HAYIR denince başlamamalı")
	assert_eq(_focused(), menu.get_button("new"), "Odak YENİ OYUN'a dönmeli")
	menu.get_button("new").pressed.emit()
	await wait_frames(2)
	(menu.get_page() as ConfirmDialog).answer(true)
	assert_true(await await_or_timeout(menu.start_requested), "EVET denince başlamalı")


func test_load_panel_lists_slots_and_emits_load_requested() -> void:
	_write_save(1, {}, 1000.0, 1)
	_write_save(3, {}, 2000.0, 2)
	menu.saves = SaveSystem.new(dir)
	menu.show_menu(false)
	menu.get_button("load").pressed.emit()
	await wait_frames(3)
	var panel := menu.get_page() as SaveLoadPanel
	assert_not_null(panel, "YÜKLE kayıt panelini açmalı")
	if panel == null:
		return
	assert_eq(panel.mode, "load")
	assert_false(panel.in_game, "Açılış ekranında yüklemeden önce sorulmaz")
	assert_eq(panel.get_cards().size(), SaveSystem.SLOTS + 1, "Otomatik kayıt ve 10 yuva listelenmeli")
	assert_false(panel.card_for(1).disabled)
	assert_true(panel.card_for(2).disabled, "Boş yuva seçilemez")
	assert_true(panel.card_for(3).summary().contains("Ocak başı #2"), panel.card_for(3).summary())
	assert_false(menu.get_button("new").is_visible_in_tree(), "Panel açıkken sütun gizlenmeli")
	var loaded := watch_signal(menu.load_requested)
	await panel.pick(3)
	assert_eq(loaded.count, 1, "Seçilen yuva bildirilmeli")
	assert_eq(loaded.last_args, [3])
	await wait_frames(1)
	assert_false(menu.is_page_open(), "Yükleme seçilince panel kapanmalı")


func test_load_panel_back_returns_focus_to_load() -> void:
	_with_saves()
	menu.show_menu(false)
	menu.get_button("load").pressed.emit()
	await wait_frames(3)
	var panel := menu.get_page() as SaveLoadPanel
	if panel == null:
		fail("Panel açılmadı")
		return
	panel.close()
	await wait_frames(2)
	assert_false(menu.is_page_open())
	assert_true(menu.get_button("new").is_visible_in_tree(), "Sütun geri gelmeli")
	assert_eq(_focused(), menu.get_button("load"), "Odak YÜKLE'ye dönmeli")


func test_settings_opens_the_title_book_with_two_pages() -> void:
	menu.show_menu(false)
	menu.get_button("settings").pressed.emit()
	await wait_frames(2)
	var book := menu.get_page() as GameMenu
	assert_not_null(book, "AYARLAR tam ekran kitabı açmalı")
	if book == null:
		return
	assert_eq(book.mode, "title")
	assert_eq(book.pages.size(), 2, "Açılış ekranında kitapta yalnızca AYARLAR ve TUŞLAR olur")
	assert_eq(book.current_page(), "ayarlar")
	assert_true(book.get_page() is SettingsPanel)
	book.turn(1)
	assert_eq(book.current_page(), "tuslar")
	assert_true(book.get_page() is ControlsPage)
	book.turn(1)
	assert_eq(book.current_page(), "ayarlar", "Q / E sayfaları başa sararak çevirir")
	book.close()
	await wait_frames(2)
	assert_false(menu.is_page_open(), "Esc / Geri kitabı kapatmalı")
	assert_eq(_focused(), menu.get_button("settings"), "Odak AYARLAR'a dönmeli")


func test_book_reads_the_latest_save_flags() -> void:
	_write_save(1, {}, 1000.0, 1)
	_write_save(2, {"ahir_ziyaret": true}, 9000.0, 2)
	menu.saves = SaveSystem.new(dir)
	assert_eq(menu.latest_flags(), {"ahir_ziyaret": true}, "Menü son kaydın işaretlerini okumalı")
	menu.show_menu(false)
	menu.get_button("book").pressed.emit()
	await wait_frames(2)
	var book := menu.get_page() as GameMenu
	assert_not_null(book, "DESTAN KİTABI kitabı açmalı")
	if book == null:
		return
	assert_eq(book.mode, "book")
	assert_eq(book.current_page(), "destan")
	var page := book.get_page() as DestanKitabiPage
	var titles := page.get_entries().map(func(e: Dictionary) -> String: return str(e["title"]))
	assert_true("Ahırda İki At" in titles, "Son kayıtta ahır görüldüyse dizesi açık olmalı: %s" % [titles])
	book.turn(1)
	assert_eq(book.current_page(), "gok_yer", "Destan'dan sonra Gök ve Yer")
	assert_true(book.get_page() is EncyclopediaPage)
	book.turn(1)
	assert_eq(book.current_page(), "kisiler")
	var people := (book.get_page() as EncyclopediaPage).get_listed_ids()
	assert_true("doru" in people and "akbulut" in people, "Atlar ahır görülünce açılır: %s" % [people])
	book.close()
	await wait_frames(2)
	assert_eq(_focused(), menu.get_button("book"))


func test_book_without_saves_shows_only_what_is_open_from_the_start() -> void:
	assert_eq(menu.latest_flags(), {}, "Kayıt yoksa işaret de yok")
	menu.show_menu(false)
	menu.get_button("book").pressed.emit()
	await wait_frames(2)
	var book := menu.get_page() as GameMenu
	if book == null:
		fail("Kitap açılmadı")
		return
	var page := book.get_page() as DestanKitabiPage
	assert_eq(page.get_entries().size(), 1, "Baştan yalnızca ilk dize açıktır")
	book.show_page("taslar")
	var stones := book.get_page() as DestanKitabiPage
	assert_eq(stones.get_entries().size(), 0)
	assert_true(stones.get_shown_text().contains(DestanKitabi.EMPTY_TEXT), "Boş bölüm boş sayfa yazısını göstermeli")


# --- Giriş ve geçişler ----------------------------------------------------------------------------

func test_intro_reveals_title_then_buttons_and_any_press_skips_it() -> void:
	menu.transition_speed = 1.0
	var finished := watch_signal(menu.transition_finished)
	menu.play_intro()
	assert_true(menu.is_intro_running(), "Giriş oynamalı")
	assert_false(menu.is_accepting_input(), "Giriş sürerken butonlar tepki vermemeli")
	var start := watch_signal(menu.start_requested)
	await wait_frames(3)
	await _tap_action(&"ui_accept")
	assert_false(menu.is_intro_running(), "Bir tuş girişi atlamalı")
	assert_false(start.fired, "Atlayan basış bir butona ulaşmamalı")
	assert_true(menu.is_accepting_input())
	assert_eq(_focused(), menu.get_button("new"), "Giriş bitince odak ilk basılabilir butonda olmalı")
	for b in menu.get_main_buttons():
		assert_almost(b.position.x, 0.0, 0.01, "Butonlar yerine gelmiş olmalı")
	assert_eq(finished.count, 1, "Atlanan giriş de bitti sinyalini bir kez yaymalı")


func test_intro_plays_to_the_end() -> void:
	var done := menu.play_intro()
	assert_true(await await_or_timeout(done, 4.0), "Giriş kendiliğinden bitmeli")
	assert_false(menu.is_intro_running())
	for b in menu.get_main_buttons():
		assert_almost(b.modulate.a, MainMenu.button_alpha(b.disabled), 0.01)
		assert_almost(b.position.x, 0.0, 0.01)


func test_hide_and_show_without_animation() -> void:
	menu.hide_menu(false)
	assert_false(menu.visible, "hide_menu(false) hemen gizlemeli")
	assert_false(menu.is_accepting_input())
	menu.show_menu(false)
	assert_true(menu.visible, "show_menu(false) hemen göstermeli")
	assert_almost(menu.modulate.a, 1.0)
	assert_true(menu.is_accepting_input())


func test_animated_show_and_hide_are_awaitable() -> void:
	menu.hide_menu(false)
	await wait_frames(1)
	var shown := menu.show_menu(true)
	assert_true(menu.visible)
	assert_true(await await_or_timeout(shown), "show_menu sinyali yayılmalı")
	for b in menu.get_main_buttons():
		assert_almost(b.position.x, 0.0, 0.01, "Butonlar soldan kayarak yerine gelmeli")
	var hidden := menu.hide_menu(true)
	assert_true(await await_or_timeout(hidden), "hide_menu sinyali yayılmalı")
	assert_false(menu.visible)


func test_buttons_inert_while_hiding() -> void:
	menu.show_menu(false)
	await wait_frames(1)
	var start := watch_signal(menu.start_requested)
	menu.hide_menu(true)
	menu.get_button("new").pressed.emit()
	assert_false(start.fired, "Kaybolurken butonlar sinyal yaymamalı")
	for b in menu.get_main_buttons():
		assert_false(b.is_interactive(), "%s kaybolurken tepki vermemeli" % b.text)
	menu.get_button("quit").mouse_entered.emit()
	await wait_frames(1)
	assert_null(_focused(), "Kaybolan menüde hiçbir buton odak almamalı")
	assert_true(await await_condition(func() -> bool: return not menu.visible), "Menü kaybolmalı")
	menu.show_menu(false)
	menu.get_button("new").pressed.emit()
	assert_eq(start.count, 1, "Yeniden açılınca butonlar çalışmalı")


func test_show_while_shown_does_not_restart() -> void:
	menu.show_menu(false)
	await wait_frames(1)
	var watcher := watch_signal(menu.transition_finished)
	menu.show_menu(true)
	await wait_frames(2)
	assert_almost(menu.modulate.a, 1.0, 0.001, "Açık menü yeniden gösterilince göz kırpmamalı")
	for b in menu.get_main_buttons():
		assert_almost(b.position.x, 0.0, 0.001, "Butonlar yeniden kaymamalı")
	assert_eq(watcher.count, 1, "Yine de bitiş sinyali bir kez yayılmalı")


func test_show_during_hide_returns_from_current_state() -> void:
	menu.transition_speed = 1.0
	menu.show_menu(false)
	menu.hide_menu(true)
	assert_true(await await_condition(func() -> bool: return menu.modulate.a < 0.85), "Menü solmaya başlamalı")
	var alpha_before := menu.modulate.a
	var back := menu.show_menu(true)
	await wait_frames(1)
	assert_true(menu.modulate.a >= alpha_before - 0.01, "Geri gelirken önce saydama düşmemeli")
	assert_true(menu.is_accepting_input())
	assert_true(await await_or_timeout(back))
	assert_almost(menu.modulate.a, 1.0)


func test_hide_right_after_instant_show_waits_for_the_fade() -> void:
	menu.transition_speed = 1.0
	menu.show_menu(false)
	var hidden := menu.hide_menu(true)
	assert_true(await await_or_timeout(hidden))
	assert_false(menu.visible, "await hide_menu() ancak menü gerçekten gizlenince dönmeli")


func test_interrupted_show_still_resumes_awaiting_caller() -> void:
	menu.hide_menu(false)
	await wait_frames(1)
	var shown := menu.show_menu(true)
	menu.hide_menu(true)
	assert_true(await await_or_timeout(shown), "Bekleyen çağıran takılı kalmamalı")
	assert_false(menu.visible, "Son istenen durum (gizli) geçerli olmalı")


func test_setting_visible_directly_opens_usable_menu() -> void:
	menu.hide_menu(false)
	menu.visible = true
	assert_true(menu.is_accepting_input())
	await wait_frames(1)
	assert_eq(_focused(), menu.get_button("new"))


func test_auto_show_and_hide_before_ready() -> void:
	var auto := _new_menu(true)
	add_child(auto)
	assert_true(await await_or_timeout(auto.transition_finished), "auto_show açıkken menü kendiliğinden açılmalı")
	assert_true(auto.visible)
	auto.queue_free()
	var hidden := _new_menu(true)
	hidden.hide_menu(false)
	add_child(hidden)
	await wait_frames(3)
	assert_false(hidden.visible, "Eklenmeden önce gizlenen menü gizli başlamalı")
	hidden.queue_free()
	var instant := _new_menu(false)
	instant.show_menu(false)
	add_child(instant)
	assert_true(instant.visible and instant.is_accepting_input(), "Önceden show_menu(false) istenen menü açık başlamalı")
	instant.queue_free()
	var intro := _new_menu(false)
	intro.play_intro()
	add_child(intro)
	await wait_frames(2)
	assert_true(intro.is_intro_running(), "Eklenmeden önce istenen giriş eklenince oynamalı")
	intro.queue_free()
	await wait_frames(1)


func test_toast_shows_and_fades() -> void:
	menu.show_menu(false)
	menu.show_toast("Bu kayıt açılamadı.", "warn")
	assert_true("Bu kayıt açılamadı." in menu.toast_texts())
	menu.hide_menu(false)
	await wait_frames(1)
	assert_eq(menu.toast_texts().size(), 0, "Menü gizlenince bildirimler kalkmalı")


# --- Yerleşim ------------------------------------------------------------------------------------

func test_layout_keeps_title_and_column_on_screen_at_16_9_16_10_and_21_9() -> void:
	var menu_h := 6 * MainMenu.BUTTON_H + 5 * MainMenu.BUTTON_GAP
	for canvas in [Vector2(1920, 1080), Vector2(1920, 1200), Vector2(2560, 1080)]:
		for k in [1.0, 0.8]:
			var lay := MainMenu.layout_for(canvas, k, menu_h, 390.0)
			var lk: float = lay["logo_scale"]
			var logo := Rect2(lay["logo_pos"], Vector2(760, 390) * lk)
			var column := Rect2(lay["menu_pos"], Vector2(MainMenu.MENU_W, menu_h) * k)
			var screen := Rect2(Vector2.ZERO, canvas)
			assert_true(screen.encloses(logo), "%s / %.1f: başlık ekranda olmalı %s" % [canvas, k, logo])
			assert_true(screen.encloses(column), "%s / %.1f: sütun ekranda olmalı %s" % [canvas, k, column])
			assert_true(logo.end.y <= column.position.y + 0.5, "%s: sütun başlığın altında başlamalı" % canvas)
			assert_almost(column.get_center().x, logo.position.x + 380.0 * lk, 1.0, "%s: sütun başlığın ortasına hizalı" % canvas)
	var wide := MainMenu.layout_for(Vector2(2560, 1080), 1.0, menu_h, 390.0)
	assert_almost(float(wide["safe_x"]), 320.0, 0.01, "21:9'da başlık ortadaki 16:9 alanda kalmalı")
	assert_almost((wide["logo_pos"] as Vector2).x, 440.0, 0.01)
	var tall := MainMenu.layout_for(Vector2(1920, 1200), 1.0, menu_h, 390.0)
	assert_almost(float(tall["logo_scale"]), 1.0, 0.001, "16:10'da başlık tam boyunda olmalı")


## K104: arayüz ölçeği %150'ye çıkar; menü sütunu ve başlık tuvale sığdığı ölçekten büyümez (MainMenu.fit_k). %100'de 1080 satır sığar
## (menü karesi referansı değişmez).
func test_layout_fits_the_canvas_at_large_ui_scales() -> void:
	var menu_h := 6 * MainMenu.BUTTON_H + 5 * MainMenu.BUTTON_GAP
	assert_true(MainMenu.fit_k(1080.0, menu_h, 390.0) >= 1.0, "%100'de 1080 satır sığar: ölçek değişmez")
	for canvas in [Vector2(1920, 1080), Vector2(1280, 720), Vector2(1920, 1200)]:
		var k := minf(1.5, MainMenu.fit_k(canvas.y, menu_h, 390.0))
		var lay := MainMenu.layout_for(canvas, k, menu_h, 390.0)
		var lk: float = lay["logo_scale"]
		var logo := Rect2(lay["logo_pos"], Vector2(760, 390) * lk)
		var column := Rect2(lay["menu_pos"], Vector2(MainMenu.MENU_W, menu_h) * k)
		var screen := Rect2(Vector2.ZERO, canvas).grow(0.5)
		assert_true(screen.encloses(logo) and screen.encloses(column), "%s / %%150 → %.3f: başlık ve sütun ekranda" % [canvas, k])
		assert_true(logo.end.y <= column.position.y + 0.5, "%s: sütun başlığın altında" % canvas)
	var settings := UIKit.settings_node()
	if settings == null:
		return
	var was: float = settings.ui_scale
	settings.ui_scale = 1.5
	settings.apply()
	var holder := Control.new()
	holder.size = Vector2(1920, 1080)
	add_child(holder)
	var m := _new_menu(false)
	holder.add_child(m)
	m.show_menu(false)
	await wait_frames(2)
	var view := Rect2(Vector2.ZERO, holder.size).grow(0.5)
	for b in m.get_main_buttons():
		assert_true(view.encloses(b.get_global_rect()), "%%150'de %s ekranda" % b.text)
	settings.ui_scale = was
	settings.apply()
	holder.queue_free()
	await wait_frames(1)


func test_scene_layout_follows_the_canvas() -> void:
	var holder := Control.new()
	holder.size = Vector2(2560, 1080)
	add_child(holder)
	var wide := _new_menu(false)
	holder.add_child(wide)
	wide.show_menu(false)
	await wait_frames(2)
	var screen := Rect2(Vector2.ZERO, holder.size).grow(0.5)
	for b in wide.get_main_buttons():
		assert_true(screen.encloses(b.get_global_rect()), "%s 21:9 ekranda olmalı" % b.text)
		assert_true(b.get_global_rect().position.x >= 320.0, "21:9'da sütun ortadaki 16:9 alanda olmalı")
	var free := wide.get_free_roam_button().get_global_rect()
	assert_true(screen.encloses(free) and free.end.x > 2560.0 - 120.0, "SERBEST GEZ sağ altta olmalı: %s" % free)
	holder.queue_free()
	await wait_frames(1)


# --- Düğüm butonu: Tanhu 1 görünümü, Tanhu vurgusu -----------------------------------------------

func test_knot_button_hover_glows_warm_and_grows() -> void:
	menu.show_menu(false)
	await wait_frames(1)
	var b := menu.get_button("settings")
	b.grab_focus()
	await get_tree().create_timer(KnotButton.HIGHLIGHT_TIME + 0.35).timeout
	assert_true(b.is_highlighted())
	assert_almost(b.get_glow(), 1.0, 0.01, "Odaktaki buton tam ışımalı")
	assert_almost(b.brush.highlight, 1.0, 0.01, "Arkadaki fırça darbesi sıcak parıltıyla yanmalı")
	assert_almost(b.scale.x, KnotButton.HOVER_SCALE, 0.01, "Buton hafifçe büyümeli")
	var gold := b.get_theme_color(&"font_focus_color")
	assert_true(gold.is_equal_approx(KnotButton.text_color(1.0)), "Yazı altın tonuna dönmeli")
	assert_true(gold.b < UIKit.TEXT.b - 0.1, "Altın ton kremden daha sıcak olmalı")
	var other := menu.get_button("new")
	assert_almost(other.get_glow(), 0.0, 0.01, "Odağı kaybeden butonun parıltısı sönmeli")
	assert_almost(other.scale.x, 1.0, 0.01)
	assert_true(b.brush.show_behind_parent, "Fırça plakanın arkasında çizilmeli")
	assert_eq(b.brush.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_true(b.brush.overscan.x > 0.0, "Fırça uçları plakanın iki yanından taşmalı")


func test_knot_button_plate_and_font_follow_tanhu1() -> void:
	var b := menu.get_button("new")
	var normal := b.get_theme_stylebox(&"normal") as StyleBoxFlat
	assert_not_null(normal)
	if normal:
		assert_true(normal.bg_color.v < 0.12 and normal.bg_color.a > 0.8, "Koyu keçe plaka")
		assert_eq(normal.border_width_left, 2, "İnce sırma kenar")
	var hot := b.get_theme_stylebox(&"focus") as StyleBoxFlat
	assert_true(hot and hot.border_color.r > hot.border_color.b + 0.3, "Vurgulu kenar gök mavisi değil sıcak altın olmalı")
	var font := b.get_theme_font(&"font")
	assert_true(font is FontVariation and (font as FontVariation).base_font.resource_path.ends_with("Cinzel.ttf"), "Yazı Cinzel olmalı")
	assert_eq(b.text, b.text.to_upper(), "Yazı büyük harf olmalı")


func test_knot_button_disabled_and_inert_states() -> void:
	var b := KnotButton.new("DENE", 30)
	b.play_sounds = false
	add_child(b)
	b.set_available(false)
	assert_true(b.disabled)
	assert_eq(b.focus_mode, Control.FOCUS_NONE, "Pasif buton odak almamalı")
	b.mouse_entered.emit()
	assert_false(b.has_focus())
	b.set_available(true)
	b.set_interactive(false)
	b.grab_focus_quietly()
	assert_false(b.has_focus(), "Kapalı (kaybolan menüdeki) buton odak almamalı")
	b.set_interactive(true)
	b.grab_focus_quietly()
	assert_true(b.has_focus())
	b.queue_free()


func test_knot_button_pure_helpers() -> void:
	assert_almost(KnotButton.target_scale(true, false), KnotButton.HOVER_SCALE)
	assert_almost(KnotButton.target_scale(false, false), 1.0)
	assert_almost(KnotButton.target_scale(true, true), KnotButton.PRESS_SCALE)
	assert_true(KnotButton.HOVER_SCALE > 1.0 and KnotButton.HOVER_SCALE < 1.12, "Büyüme hafif olmalı")
	assert_true(KnotButton.text_color(0.0).is_equal_approx(UIKit.TEXT))
	assert_false(KnotButton.navigating(), "Tuşa basılmıyorken oyuncu gezinmiyor sayılır")
	assert_eq(MainMenu.neighbor_index(0, -1, 4), 3)
	assert_eq(MainMenu.neighbor_index(3, 1, 4), 0)
	assert_eq(MainMenu.neighbor_index(0, 1, 0), 0)
	assert_almost(MainMenu.button_alpha(true), MainMenu.DISABLED_ALPHA)
	assert_almost(MainMenu.button_alpha(false), 1.0)
	assert_almost(OrnamentLine.half_length(1.0), 330.0)
	assert_almost(OrnamentLine.half_length(0.0), 30.0)


func test_brush_fits_parent_with_padding_and_overscan() -> void:
	var rect := MenuBrush.fitted_rect(Vector2(200.0, 50.0), 20.0)
	assert_eq(rect.position, Vector2(-20.0, -20.0))
	assert_eq(rect.size, Vector2(240.0, 90.0))
	var wide := MenuBrush.fitted_rect(Vector2(200.0, 50.0), 20.0, Vector2(10.0, 2.0))
	assert_eq(wide.position, Vector2(-30.0, -22.0))
	assert_eq(wide.size, Vector2(260.0, 94.0))
	var saved := ShaderMaterial.new()
	saved.shader = MenuBrush.SHADER
	var brush := MenuBrush.new()
	brush.material = saved
	brush.highlight = 0.7
	var holder := Control.new()
	holder.size = Vector2(100.0, 40.0)
	holder.add_child(brush)
	add_child(holder)
	await wait_frames(1)
	assert_eq(brush.material, saved, "Hazır malzeme değiştirilmemeli")
	assert_almost(float(saved.get_shader_parameter(&"highlight")), 0.7)
	holder.queue_free()


func test_missing_assets_fall_back_quietly() -> void:
	assert_not_null(UIKit.font("BoyleBirYaziTipiYok"), "Eksik yazı tipi yedeğe düşmeli")
	assert_eq(DestanKitabi.data("yok"), {}, "Eksik veri dosyası boş sayılmalı")
	MenuStyle.muted = false
	MenuStyle.play_ui(menu, &"boyle_bir_ses_yok")   # çökmemeli
	MenuStyle.muted = true
	assert_true(MenuStyle.EXTRA_SOUNDS.size() >= 2)
	for path in MenuStyle.EXTRA_SOUNDS.values():
		assert_true(ResourceLoader.exists(str(path)), "Arayüz sesi eksik: %s" % path)
