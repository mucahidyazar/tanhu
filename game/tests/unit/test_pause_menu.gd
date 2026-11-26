extends TestCase
## Duraklatma menüsü ve oyun kitabı testleri: kitabın kiplere göre sayfaları («Gök ve Yer» dahil), GENEL sayfasının
## butonları (DEVAM ET / KAYDET / YÜKLE / AYARLAR / ANA MENÜ / MASAÜSTÜNE DÖN) ve durumları, dünyayı
## durdurup sürdürme, Esc / Q / E / F5 / F9, kayıt yuvalarına kaydetme ve yükleme, soru penceresi.
## Kayıtlar geçici bir klasördedir.

const TempDir := preload("res://tests/support/temp_dir.gd")

var dir := ""
var journey: Journey
var pause: PauseMenu


func before_each() -> void:
	MenuStyle.muted = true
	dir = TempDir.fresh("duraklat")
	journey = Journey.new(SaveSystem.new(dir))
	journey.play_time = 95.0
	journey.position = Vector3(1.0, 0.0, 2.0)
	pause = PauseMenu.new()
	pause.journey = journey
	add_child(pause)


func after_each() -> void:
	# Esc'in basılı durumu sonraki dosyalara kalmasın (CineHost basılı Esc'le atlar).
	for action in [&"ui_cancel", &"pause"]:
		if InputMap.has_action(action):
			Input.action_release(action)
	if is_instance_valid(pause):
		pause.close()
		pause.queue_free()
	get_tree().paused = false
	TempDir.wipe(dir)


func _book() -> GameMenu:
	return pause.get_menu()


func _general() -> GeneralPage:
	return _book().get_page() as GeneralPage if _book() else null


func _press_key(code: Key) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = true
	Input.parse_input_event(e)
	await wait_frames(2)


func test_book_pages_by_mode() -> void:
	var ids := func(mode: String) -> Array: return GameMenu.pages_for(mode).map(func(p: Dictionary) -> String: return str(p["id"]))
	assert_eq(ids.call("game"), ["genel", "harita", "gorevler", "destan", "gok_yer", "kisiler", "taslar", "tuslar", "ayarlar"], "Oyunda kitabın bütün sayfaları (HARİTA ve GÖREVLER oyun içi HUD'un)")
	assert_eq(ids.call("title"), ["ayarlar", "tuslar"], "Açılış ekranında yalnızca ayarlar ve tuşlar (Tanhu 1)")
	assert_eq(ids.call("book"), ["destan", "gok_yer", "kisiler", "taslar"], "Destan Kitabı'nın dört bölümü: Destan, Gök ve Yer, Kişiler, Taşlar")
	assert_eq(GameMenu.PAGE_SKY["glyph"], "sun", "«Gök ve Yer»in simgesi güneş")


func test_open_pauses_the_world_on_the_general_page_and_close_resumes() -> void:
	pause.open()
	await wait_frames(2)
	assert_true(pause.is_open())
	assert_true(get_tree().paused, "Kitap açıkken dünya durmalı")
	assert_eq(_book().mode, "game")
	assert_eq(_book().current_page(), "genel", "Esc kitabı GENEL sayfasında açar")
	var resumed := watch_signal(pause.resumed)
	_book().close()
	await wait_frames(1)
	assert_eq(resumed.count, 1, "Kapatmak oyunu sürdürmeli")
	assert_false(pause.is_open())
	assert_false(get_tree().paused, "Kitap kapanınca dünya yeniden akmalı")


func test_general_page_has_the_six_buttons_in_order() -> void:
	pause.open()
	await wait_frames(2)
	var page := _general()
	assert_not_null(page)
	if page == null:
		return
	var texts: Array = []
	for item in GeneralPage.ITEMS:
		texts.append(page.get_button(str(item[0])).text)
	assert_eq(texts, ["DEVAM ET", "KAYDET", "YÜKLE", "AYARLAR", "ANA MENÜ", "MASAÜSTÜNE DÖN"])
	assert_false(page.get_button("save").disabled, "Oyunda kaydedilebilir")
	assert_true(page.get_button("load").disabled, "Kayıt yokken YÜKLE pasif olmalı")
	assert_eq(get_viewport().gui_get_focus_owner(), page.get_button("resume"), "Odak DEVAM ET'te başlamalı")
	var resume := page.get_button("resume")
	assert_eq(resume.get_node(resume.focus_neighbor_bottom), page.get_button("save"))
	var save := page.get_button("save")
	assert_eq(save.get_node(save.focus_neighbor_bottom), page.get_button("settings"), "Aşağı pasif YÜKLE'yi atlamalı")
	var facts := "\n".join(GeneralPage.journey_facts(journey))
	assert_true(facts.contains("Oynanan süre") and facts.contains("1 dk"), facts)
	assert_true(facts.contains("Destan") and facts.contains("1 / 7"), "Kartta Destan Kitabı'nda açılanlar yazmalı: %s" % facts)


func test_load_is_enabled_when_a_save_exists() -> void:
	journey.save_manual(1)
	pause.open()
	await wait_frames(2)
	assert_false(_general().get_button("load").disabled)


func test_general_buttons_do_their_jobs() -> void:
	pause.open()
	await wait_frames(2)
	var page := _general()
	page.get_button("settings").pressed.emit()
	assert_eq(_book().current_page(), "ayarlar", "AYARLAR kitabın ayarlar sayfasını açmalı")
	_book().show_page("genel")
	await wait_frames(2)
	var main_req := watch_signal(pause.main_menu_requested)
	_general().get_button("main").pressed.emit()
	assert_eq(main_req.count, 1, "ANA MENÜ main_menu_requested yaymalı")
	assert_false(pause.is_open(), "Ana menüye dönerken kitap kapanmalı")
	assert_false(get_tree().paused)


func test_quit_asks_first() -> void:
	pause.open()
	await wait_frames(2)
	var quit := watch_signal(pause.quit_requested)
	_general().get_button("quit").pressed.emit()
	await wait_frames(2)
	var dialog := _book().find_children("*", "ConfirmDialog", false, false)
	assert_eq(dialog.size(), 1, "MASAÜSTÜNE DÖN önce sormalı")
	if dialog.is_empty():
		return
	assert_true(_book().has_overlay())
	(dialog[0] as ConfirmDialog).answer(true)
	await wait_frames(3)
	assert_eq(quit.count, 1, "EVET denince çıkış istenmeli")


func test_pause_book_opens_the_encyclopedia_pages() -> void:
	journey.set_flag(JourneyFlags.PROLOGUE)
	pause.open()
	await wait_frames(2)
	_book().show_page("gok_yer")
	var sky := _book().get_page() as EncyclopediaPage
	assert_not_null(sky, "Duraklatmada da «Gök ve Yer» ansiklopedi düzeninde")
	if sky == null:
		return
	assert_true("erlik" in sky.get_listed_ids(), "Önsöz'den sonra mitler açıktır")
	await _press_key(KEY_E)
	assert_eq(_book().current_page(), "kisiler", "Tek bölümlü sayfada E kitabın sonraki sayfasına geçer")
	await _press_key(KEY_Q)
	assert_eq(_book().current_page(), "gok_yer")


func test_escape_and_page_keys() -> void:
	pause.open()
	await wait_frames(2)
	await _press_key(KEY_E)
	assert_eq(_book().current_page(), "harita", "E bir sonraki sayfa")
	await _press_key(KEY_Q)
	await _press_key(KEY_Q)
	assert_eq(_book().current_page(), "ayarlar", "Q geri, baştan sona sarar")
	await _press_key(KEY_F9)
	assert_false(_book().has_overlay(), "Kayıt yokken F9 bir şey açmamalı")
	await _press_key(KEY_F5)
	assert_true(_book().has_overlay(), "F5 kayıt yuvalarını açmalı")
	var resumed := watch_signal(pause.resumed)
	var esc := InputEventAction.new()
	esc.action = &"ui_cancel"
	esc.pressed = true
	Input.parse_input_event(esc)
	await wait_frames(2)
	assert_false(_book().has_overlay(), "Esc önce kayıt yuvalarını kapatmalı")
	assert_eq(resumed.count, 0)
	Input.parse_input_event(esc)
	await wait_frames(2)
	assert_eq(resumed.count, 1, "İkinci Esc kitabı kapatıp oyunu sürdürmeli")


func test_save_into_a_slot_and_confirm_overwrite() -> void:
	pause.open()
	await wait_frames(2)
	_book().open_slots("save")
	await wait_frames(3)
	var panel := _book().find_children("*", "SaveLoadPanel", false, false)
	assert_eq(panel.size(), 1, "KAYDET yuvaları açmalı")
	if panel.is_empty():
		return
	var p := panel[0] as SaveLoadPanel
	assert_eq(p.get_cards().size(), SaveSystem.SLOTS, "Kaydederken otomatik kayıt yuvası listelenmez")
	var saved := watch_signal(_book().saved)
	await p.pick(2)
	assert_eq(saved.count, 1, "Yuvaya kaydedilmeli")
	assert_true(journey.saves.has_save(2))
	assert_true(p.card_for(2).summary().contains("#1"), "Kart yeni kaydı göstermeli: %s" % p.card_for(2).summary())
	p.pick(2)
	await wait_frames(2)
	var dialog := p.find_children("*", "ConfirmDialog", false, false)
	assert_eq(dialog.size(), 1, "Dolu yuvanın üstüne yazmadan önce sorulmalı")
	if dialog.size() == 1:
		(dialog[0] as ConfirmDialog).answer(false)
		await wait_frames(2)
		assert_eq(int(journey.saves.slot_info(2).get("save_no", 0)), 1, "HAYIR denince kayıt değişmemeli")


func test_load_from_the_book_asks_and_reports_the_slot() -> void:
	journey.save_manual(3)
	pause.open()
	await wait_frames(2)
	_book().open_slots("load")
	await wait_frames(3)
	var p := _book().find_children("*", "SaveLoadPanel", false, false)[0] as SaveLoadPanel
	assert_eq(p.get_cards().size(), SaveSystem.SLOTS + 1, "Yüklerken otomatik kayıt da listelenir")
	var loaded := watch_signal(pause.load_requested)
	p.pick(3)
	await wait_frames(2)
	var dialog := p.find_children("*", "ConfirmDialog", false, false)
	assert_eq(dialog.size(), 1, "Oyunda yüklemeden önce sorulmalı (kaydedilmemiş ilerleme kaybolur)")
	if dialog.is_empty():
		return
	(dialog[0] as ConfirmDialog).answer(true)
	await wait_frames(3)
	assert_eq(loaded.count, 1)
	assert_eq(loaded.last_args, [3])
	assert_false(pause.is_open(), "Yükleme seçilince kitap kapanmalı")


func test_confirm_dialog_defaults_to_no_and_escape_means_no() -> void:
	var d := ConfirmDialog.new()
	add_child(d)
	var state := {"result": null}
	var run := func() -> void: state["result"] = await d.run("Emin misin?")
	run.call()
	await wait_frames(2)
	assert_eq(get_viewport().gui_get_focus_owner(), d.no_button, "Odak önce HAYIR'da olmalı")
	assert_eq(d.yes_button.text, "EVET")
	assert_eq(d.no_button.text, "HAYIR")
	var esc := InputEventAction.new()
	esc.action = &"ui_cancel"
	esc.pressed = true
	Input.parse_input_event(esc)
	await wait_frames(3)
	assert_eq(state["result"], false, "Esc 'hayır' demektir")
