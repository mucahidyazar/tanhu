extends TestCase
## Tuşlar sayfası (ControlsPage) testleri: dört görünüm, «Atama» görünümünde «Değiştir» ile tuş dinleme, çakışmada «Şuna da bağlı:
## {eylem}» sorusu ve takas (eski eylem boş kalmaz), Esc ile vazgeçme, oyun kolu düğmesi, «Varsayılana dön», atamanın ayarın [input]
## bölümüne hemen yazılması (K39, godot.md §5.6) ve tuş adlarının dizilişten okunması (başsızda ABD dizilişi).
## Her test kendi GameSettings örneğini geçici bir dosyayla kullanır; atama her testten sonra varsayılana döner.

const SettingsScript := preload("res://scripts/settings/game_settings.gd")
const TempDir := preload("res://tests/support/temp_dir.gd")

var dir := ""
var settings: Node
var page: ControlsPage


func before_each() -> void:
	MenuStyle.muted = true
	InputSetup.ensure_actions()
	InputSetup.reset_bindings()
	dir = TempDir.fresh("tuslar")
	settings = SettingsScript.new()
	settings.path = dir.path_join("settings.cfg")
	settings.persist = true
	settings.apply_window = false


func after_each() -> void:
	if is_instance_valid(page):
		page.queue_free()
	page = null
	if is_instance_valid(settings):
		settings.free()
	InputSetup.reset_bindings()
	TempDir.wipe(dir)


func _open(view := ControlsPage.REBIND_VIEW) -> ControlsPage:
	page = ControlsPage.new()
	page.settings = settings
	page.size = Vector2(1920, 900)
	add_child(page)
	page.show_view(view)
	await wait_frames(2)
	return page


func _row(action: StringName) -> Control:
	return page.find_child(String(action), true, false) as Control


func _button(action: StringName) -> Button:
	var row := _row(action)
	return row.get_node(^"Change") as Button if row else null


func _shown_keys(action: StringName) -> Array:
	var row := _row(action)
	return (row.get_node(^"Keys") as ControlsPage.KeysView).keys if row else []


func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = true
	return e


func _dialog() -> ConfirmDialog:
	for c in page.get_children():
		if c is ConfirmDialog:
			return c as ConfirmDialog
	return null


func _pressed(code: Key) -> InputEventKey:
	return _key(code)


# --- Görünümler ----------------------------------------------------------------------------------

func test_four_views_and_the_rebind_view_lists_every_rebindable_action() -> void:
	assert_eq(ControlsPage.VIEWS.map(func(v: Array) -> String: return str(v[1])), ["Liste", "Klavye", "Oyun kolu", "Atama"])
	assert_true(str(GameMenu.PAGE_HINTS["tuslar"]).contains("atama"), "Alt ipucu dört görünümü söyler")
	await _open()
	assert_eq(page.get_view(), ControlsPage.REBIND_VIEW)
	var view := page.get_child(page.get_child_count() - 1).get_child(0) as Control
	assert_true(view.get_combined_minimum_size().y <= 900.0 - 78.0, "Atama görünümü sayfaya sığar (%.0f px)" % view.get_combined_minimum_size().y)
	for action in InputSetup.rebindable_actions():
		var b := _button(action)
		assert_not_null(b, "Satır ve «Değiştir»: %s" % action)
		if b:
			assert_eq(b.text, ControlsPage.CHANGE_TEXT)
	assert_null(_row(&"pause"), "Esc (oyun menüsü) atanmaz")
	assert_eq(_shown_keys(&"camera_left"), ["Q", ","], "Kamera Q ve , ile döner (K27; Türkçe Q'da Ö)")
	assert_eq(_shown_keys(&"camera_reset"), ["/"])
	var reset := page.find_child("ResetAll", true, false) as Button
	assert_not_null(reset, "«Varsayılana dön»")
	assert_eq(reset.text, ControlsPage.RESET_TEXT)
	page.show_view(0)
	await wait_frames(1)
	assert_null(_row(&"jump"), "Liste görünümünde atama satırı yok")


# --- Değiştir --------------------------------------------------------------------------------------

func test_change_listens_binds_a_free_key_and_saves_it_at_once() -> void:
	await _open()
	_button(&"jump").pressed.emit()
	assert_eq(page.listening_action(), &"jump", "«Değiştir» sonraki tuşu dinler")
	assert_eq(_button(&"jump").text, ControlsPage.CANCEL_TEXT)
	page._input(_key(KEY_K))
	await wait_frames(1)
	assert_eq(page.listening_action(), &"", "Tuş gelince dinleme biter")
	assert_true(InputMap.event_is_action(_pressed(KEY_K), &"jump"), "K zıplatır")
	assert_false(InputMap.event_is_action(_pressed(KEY_SPACE), &"jump"), "Boşluk artık zıplatmaz")
	assert_true(InputMap.event_is_action(_pressed(KEY_SPACE), &"book_intro"), "Boşluk menüde tanıtım kalır")
	assert_eq(_shown_keys(&"jump"), ["K"], "Satır yeni tuşu gösterir")
	var want := [{"type": "key", "physical": KEY_K}, {"type": "joy_button", "index": JOY_BUTTON_A}]
	assert_eq(settings.input_bindings, {"jump": want}, "Ayara yazıldı: eylemin bütün olayları (kolda A kalır)")
	var cfg := ConfigFile.new()
	assert_eq(cfg.load(settings.path), OK, "Hemen kaydedildi")
	assert_eq(cfg.get_value("input", "jump"), want, "[input] jump")


func test_conflict_asks_and_yes_swaps_so_the_old_action_keeps_a_key() -> void:
	await _open()
	page.begin_listen(&"jump")
	page._input(_key(KEY_Q))
	await wait_frames(2)
	var d := _dialog()
	assert_not_null(d, "Çakışmada soru sorulur")
	if d == null:
		return
	var text := (d.find_children("*", "Label", true, false)[0] as Label).text
	assert_true(text.contains("şuna da bağlı: Kamerayı sola döndür"), "«Şuna da bağlı: {eylem}»: %s" % text)
	assert_true(text.contains("«Boşluk»"), "Eski tuş söylenir: %s" % text)
	assert_true(InputMap.event_is_action(_pressed(KEY_Q), &"camera_left"), "Soru sürerken bir şey değişmez")
	d.answer(true)
	await wait_frames(3)
	assert_true(InputMap.event_is_action(_pressed(KEY_Q), &"jump"), "Q zıplatır")
	assert_true(InputMap.event_is_action(_pressed(KEY_SPACE), &"camera_left"), "Kamera eski tuşu (Boşluk) aldı: boş kalmaz")
	assert_eq(InputSetup.conflicts(), [], "Çakışma kalmaz")
	assert_eq(_shown_keys(&"camera_left"), ["Boşluk", ","], "Kameranın satırı da yenilenir: eski tuş Q'nun yerinde")
	assert_true(settings.input_bindings.has("camera_left") and settings.input_bindings.has("jump"), "İkisi de kaydedildi")


func test_conflict_no_changes_nothing() -> void:
	await _open()
	page.begin_listen(&"jump")
	page._input(_key(KEY_E))
	await wait_frames(2)
	var d := _dialog()
	assert_not_null(d, "E oyunda kameranın ve onayın")
	if d == null:
		return
	d.answer(false)
	await wait_frames(3)
	assert_true(InputMap.event_is_action(_pressed(KEY_SPACE), &"jump"), "Zıpla yerinde")
	assert_false(InputMap.event_is_action(_pressed(KEY_E), &"jump"))
	assert_eq(InputSetup.bindings(), {}, "Atama yok")
	assert_false(FileAccess.file_exists(settings.path), "Yazılacak bir şey yok")


func test_escape_cancels_and_menu_keys_do_not_leak_while_listening() -> void:
	await _open()
	page.begin_listen(&"map")
	page._input(_key(KEY_ESCAPE))
	assert_eq(page.listening_action(), &"", "Esc vazgeçer")
	assert_true(InputMap.event_is_action(_pressed(KEY_M), &"map"), "Harita M'de kalır")
	assert_eq(_button(&"map").text, ControlsPage.CHANGE_TEXT)
	# Dinlerken Z ve C görünüm değiştirmez, tuş olarak alınır (menüde Z / C bölüm değiştirir; oyunda boştur).
	page.begin_listen(&"map")
	page._input(_key(KEY_Z))
	await wait_frames(1)
	assert_eq(page.get_view(), ControlsPage.REBIND_VIEW, "Görünüm değişmedi")
	assert_true(InputMap.event_is_action(_pressed(KEY_Z), &"map"), "Z haritayı açar")


func test_gamepad_button_is_bound_while_listening() -> void:
	await _open()
	page.begin_listen(&"inventory")
	var x := InputEventJoypadButton.new()
	x.button_index = JOY_BUTTON_X
	x.pressed = true
	page._input(x)
	await wait_frames(1)
	assert_true(InputMap.event_is_action(x, &"inventory"), "Kolda X envanteri açar")
	assert_true(InputMap.event_is_action(_pressed(KEY_I), &"inventory"), "Klavyedeki I kalır")
	var row := _row(&"inventory")
	assert_eq((row.get_node(^"Keys") as ControlsPage.KeysView).pads, ["X"], "Satırda kol düğmesi")
	assert_eq(settings.input_bindings["inventory"], [{"type": "key", "physical": KEY_I}, {"type": "joy_button", "index": JOY_BUTTON_X}])


func test_reset_all_restores_defaults_and_clears_the_saved_section() -> void:
	await _open()
	page.begin_listen(&"sprint")
	page._input(_key(KEY_K))
	await wait_frames(1)
	assert_false(settings.input_bindings.is_empty())
	page.reset_all(false)
	await wait_frames(1)
	assert_eq(InputSetup.bindings(), {}, "Atama silindi")
	assert_eq(settings.input_bindings, {})
	assert_true(InputMap.event_is_action(_pressed(KEY_SHIFT), &"sprint"), "Koşu Shift'te")
	var cfg := ConfigFile.new()
	cfg.load(settings.path)
	assert_false(cfg.has_section("input"), "[input] bölümü boşaldı")
	assert_eq(_shown_keys(&"sprint"), ["Shift"])


# --- Adlar ve liste --------------------------------------------------------------------------------

func test_names_follow_the_layout_and_the_list_reads_the_current_binding() -> void:
	# Başsızda diziliş okunamaz: ABD dizilişinin işaretleri gösterilir (pencerede DisplayServer.keyboard_get_label_from_physical).
	assert_eq(ControlsPage.key_label(KEY_SLASH), "/")
	assert_eq(ControlsPage.key_label(KEY_SEMICOLON), ";")
	assert_eq(ControlsPage.key_label(KEY_I), "I")
	assert_eq(ControlsPage.key_label(KEY_SPACE), "Boşluk")
	assert_eq(ControlsPage.key_label(KEY_F11), "F11")
	assert_eq(ControlsPage.KeyboardView.cap_text("Slash", "/"), "/")
	assert_eq(ControlsPage.KeyboardView.cap_text("Escape", "Esc"), "Esc")
	var side := InputEventMouseButton.new()
	side.button_index = MOUSE_BUTTON_XBUTTON1
	assert_eq(ControlsPage.event_name(side), "Fare 4")
	var a := InputEventJoypadButton.new()
	a.button_index = JOY_BUTTON_A
	assert_eq(ControlsPage.event_name(a), "A")
	assert_eq(ControlsPage.composite_keys([&"move_forward", &"move_left", &"move_back", &"move_right"]), ["W A S D", "↑ ← ↓ →"])
	InputSetup.rebind(&"camera_left", InputSetup.key_event(KEY_K))
	assert_eq(ControlsPage.composite_keys([&"camera_left", &"camera_right"]), ["K E", ", ."], "Liste atamayı okur")
	var text := ControlsPage.conflict_text(&"jump", InputSetup.key_event(KEY_E), InputSetup.conflicts_for(&"jump", InputSetup.key_event(KEY_E)))
	assert_true(text.contains("«E» şuna da bağlı: Kamerayı sağa döndür, Kullan · onayla."), text)
	assert_true(text.contains("«Zıpla» satırına atansın mı?"), text)
	assert_true(text.contains("eski tuşu alır: «Boşluk»"), text)


func test_list_view_shows_the_camera_rows() -> void:
	await _open(0)
	var labels := PackedStringArray()
	for l in page.find_children("*", "Label", true, false):
		labels.append((l as Label).text)
	for want in ["Kamerayı döndür", "Kamerayı eğ", "Yakınlaş / uzaklaş", "Varsayılan kamera", "Kuzeye hizala"]:
		assert_true(labels.has(want), "Liste: %s" % want)
	var uses := ControlsPage.key_uses()
	assert_true((uses.get("Slash", []) as Array).any(func(u: Array) -> bool: return str(u[0]) == "Varsayılan"), "Klavyede / varsayılan kamera")
	assert_true((uses.get("Semicolon", []) as Array).any(func(u: Array) -> bool: return str(u[0]) == "Yükselt"), "Klavyede ; yükseltir")
