extends TestCase
## Karakter oluşturucu ekranı (CharacterCreator) ve yardımcıları için testler.

const CREATOR_SCENE := preload("res://scenes/ui/character_creator.tscn")
const THEME_PATH := "res://ui/creator_theme.tres"

var creator: CharacterCreator


## Not: test koşucusu before_each / after_each'i beklemez (await yok); bu yüzden kurulum eşzamanlıdır.
## add_child() sırasında _ready() hemen çalışır, ekran hemen kullanıma hazırdır.
func before_each() -> void:
	InputSetup.ensure_actions()
	# Arka planda model yüklemek testleri yavaşlatır; ekran onsuz da aynı çalışır.
	CreatorTurntable.preload_enabled = false
	creator = CREATOR_SCENE.instantiate() as CharacterCreator
	add_child(creator)
	# Kayıtlı bir profil olsa bile her test aynı varsayılan profille başlasın.
	creator.open(CharacterProfile.new())


func after_each() -> void:
	if is_instance_valid(creator):
		creator.queue_free()
	creator = null
	CreatorTurntable.preload_enabled = true


# --- Satırlar ve renk örnekleri ---------------------------------------------------

func test_has_one_row_per_field_in_order() -> void:
	assert_eq(creator.get_row_count(), CharacterOptions.FIELDS.size())
	var rows := creator.get_rows()
	for i in CharacterOptions.FIELDS.size():
		var field: StringName = CharacterOptions.FIELDS[i]
		assert_eq(rows[i].field, field, "Satır sırası FIELDS ile aynı olmalı")
		assert_eq(rows[i].get_label_text(), CharacterOptions.FIELD_LABELS[field])
		# Varsayılan profilin değeri (zorlukta Normal, öteki alanlarda ilk seçenek).
		var value := creator.get_profile().get_value(field)
		var expected := CharacterOptions.value_name(field, value, 0) if creator.is_adjustable(field) else CharacterOptions.locked_text(field)
		assert_eq(rows[i].get_value_text(), expected)


func test_swatch_counts_match_colors() -> void:
	for row in creator.get_rows():
		var swatches := row.get_swatches()
		if row.field in CharacterOptions.COLOR_FIELDS:
			assert_not_null(swatches, "Renk alanında renk örnekleri olmalı: %s" % row.field)
			assert_eq(swatches.colors.size(), CharacterOptions.colors(row.field).size())
			assert_eq(swatches.selected, 0, "Başlangıçta 'Doğal' seçili olmalı")
		else:
			assert_null(swatches, "Renk alanı olmayan satırda renk örneği olmamalı: %s" % row.field)


func test_color_rows_are_taller() -> void:
	assert_true(CreatorRow.row_height(&"skin") > CreatorRow.row_height(&"beard"))


# --- Değiştirme, geri alma, onaylama --------------------------------------------------

func test_change_updates_profile_avatar_and_text() -> void:
	creator.change(&"hair_color", 1)
	assert_eq(creator.get_profile().hair_color, 1)
	assert_eq(creator.get_row(&"hair_color").get_value_text(), CharacterOptions.value_name(&"hair_color", 1))
	assert_true(creator.get_avatar().get_profile().equals(creator.get_profile()), "Önizleme profili canlı almalı")


func test_change_and_undo_restores_previous_profile() -> void:
	var before := creator.get_profile().copy()
	creator.change(&"skin", 1)
	creator.change(&"hair_color", -1)
	assert_false(creator.get_profile().equals(before))
	assert_eq(creator.get_history_size(), 2)
	assert_true(creator.undo())
	assert_eq(creator.get_profile().hair_color, 0)
	assert_eq(creator.get_profile().skin, 1)
	assert_true(creator.undo())
	assert_true(creator.get_profile().equals(before), "İki geri alma ilk profile dönmeli")
	assert_eq(creator.get_row(&"skin").get_value_text(), CharacterOptions.NATURAL)
	assert_true(creator.get_avatar().get_profile().equals(before), "Geri alma önizlemeye de uygulanmalı")


func test_undo_with_empty_history_emits_cancelled() -> void:
	var watcher := watch_signal(creator.cancelled)
	assert_false(creator.undo())
	assert_true(watcher.fired)
	assert_false(creator.is_active(), "Çıkış isteğinden sonra ekran girdi almamalı")


func test_accept_emits_copy_equal_to_current_profile() -> void:
	creator.change(&"hair_color", 3)
	creator.change(&"moustache", 1)
	var watcher := watch_signal(creator.accepted)
	creator.accept()
	assert_eq(watcher.count, 1)
	var sent := watcher.last_args[0] as CharacterProfile
	assert_not_null(sent)
	assert_true(sent.equals(creator.get_profile()))
	assert_ne(sent, creator.get_profile(), "Gönderilen profil bağımsız bir kopya olmalı")


func test_open_does_not_modify_given_profile() -> void:
	var original := CharacterProfile.new()
	original.set_value(&"skin", 4)
	creator.open(original)
	creator.change(&"skin", 1)
	assert_eq(original.skin, 4, "open() verilen profili değiştirmemeli")
	assert_eq(creator.get_profile().skin, 5)
	assert_eq(creator.get_history_size(), 1)


func test_open_while_hidden_then_show() -> void:
	creator.visible = false
	creator.open(CharacterProfile.new())
	creator.change(&"skin", 2)
	creator.visible = true
	assert_true(creator.is_active())
	assert_eq(creator.get_profile().skin, 2)
	assert_eq((creator.get_node(^"%Content") as Control).modulate.a, 0.0, "Görünür olunca açılış animasyonu baştan başlamalı")


func test_open_resets_history() -> void:
	creator.change(&"skin", 1)
	creator.open(CharacterProfile.new())
	assert_eq(creator.get_history_size(), 0)
	assert_true(creator.is_active())


func test_body_type_change_keeps_hairstyle_valid_and_updates_text() -> void:
	creator.change(&"hairstyle", 1)
	var old_text := creator.get_row(&"hairstyle").get_value_text()
	creator.change(&"body_type", 1)
	var p := creator.get_profile()
	assert_eq(p.body_type, 1)
	assert_true(p.hairstyle < CharacterOptions.count(&"hairstyle", 1), "Saç modeli yeni tipin listesinde olmalı")
	var new_text := creator.get_row(&"hairstyle").get_value_text()
	assert_eq(new_text, CharacterOptions.value_name(&"hairstyle", p.hairstyle, 1))
	assert_ne(new_text, old_text, "Saç adı vücut tipine göre değişmeli")
	assert_eq(creator.get_avatar().model_id, p.model_id(), "Önizleme yeni modele geçmeli")
	assert_true(creator.undo())
	assert_eq(creator.get_row(&"hairstyle").get_value_text(), old_text)


func test_select_color_updates_selection_and_skips_no_op() -> void:
	creator.select_color(&"hair_color", 3)
	assert_eq(creator.get_profile().hair_color, 3)
	var row := creator.get_row(&"hair_color")
	assert_eq(row.get_swatches().selected, 3)
	assert_eq(row.get_value_text(), CharacterOptions.value_name(&"hair_color", 3))
	creator.select_color(&"hair_color", 3)
	assert_eq(creator.get_history_size(), 1, "Aynı rengi yeniden seçmek geçmişe eklenmemeli")
	creator.select_color(&"beard", 2)
	assert_eq(creator.get_profile().beard, 0, "Renk alanı olmayan alana renk seçilemez")


func test_select_color_ignores_out_of_range_index() -> void:
	creator.select_color(&"skin", CharacterOptions.colors(&"skin").size())
	creator.select_color(&"skin", 99)
	creator.select_color(&"eye_color", -1)
	assert_eq(creator.get_profile().skin, 0, "Listede olmayan renk başa sarılıp seçilmemeli")
	assert_eq(creator.get_profile().eye_color, 0)
	assert_eq(creator.get_history_size(), 0, "Geçersiz seçim geçmişe eklenmemeli")


func test_undo_focuses_the_reverted_row() -> void:
	creator.change(&"skin", 1)
	creator.move_focus(4)
	assert_ne(creator.get_focus_index(), CharacterOptions.FIELDS.find(&"skin"))
	assert_true(creator.undo())
	assert_eq(creator.get_focus_index(), CharacterOptions.FIELDS.find(&"skin"), "Geri alınan satır odaklanmalı")
	assert_true(creator.get_row(&"skin").focused)


func test_first_changed_field_helper() -> void:
	var a := CharacterProfile.new()
	var b := a.copy()
	assert_eq(CharacterCreator.first_changed_field(a, b), &"", "Aynı profillerde fark yok")
	b.set_value(&"eye_color", 2)
	b.set_value(&"skin", 3)
	assert_eq(CharacterCreator.first_changed_field(a, b), &"skin", "FIELDS sırasındaki ilk fark")
	assert_eq(CharacterCreator.first_changed_field(null, b), &"")


func test_history_is_limited() -> void:
	for i in CharacterCreator.MAX_HISTORY + 10:
		creator.change(&"skin", 1)
	assert_eq(creator.get_history_size(), CharacterCreator.MAX_HISTORY)


# --- Fare ile etkileşim (sinyaller) ------------------------------------------------

func test_arrow_and_swatch_clicks_change_values() -> void:
	var row := creator.get_row(&"eye_color")
	row.get_arrows()[1].pressed.emit()
	assert_eq(creator.get_profile().eye_color, 1, "▶ oku bir sonraki seçeneğe geçmeli")
	row.get_arrows()[0].pressed.emit()
	assert_eq(creator.get_profile().eye_color, 0, "◀ oku bir önceki seçeneğe dönmeli")
	row.get_swatches().swatch_pressed.emit(4)
	assert_eq(creator.get_profile().eye_color, 4)
	assert_eq(creator.get_focus_index(), CharacterOptions.FIELDS.find(&"eye_color"), "Tıklanan satır odaklanmalı")


func test_hovering_a_row_moves_focus() -> void:
	var row := creator.get_row(&"hair_color")
	row.hovered.emit(&"hair_color")
	assert_eq(creator.get_focus_index(), CharacterOptions.FIELDS.find(&"hair_color"))
	assert_true(row.focused)
	assert_false(creator.get_rows()[0].focused)


func test_hovering_arrow_or_swatch_moves_focus() -> void:
	# Oklar ve renk örnekleri fareyi kendileri tutar; imleç doğrudan onlara gelse de satır odaklanmalı.
	creator.get_row(&"skin").get_arrows()[0].mouse_entered.emit()
	assert_eq(creator.get_focus_index(), CharacterOptions.FIELDS.find(&"skin"), "Ok üzerine gelmek satırı odaklamalı")
	creator.get_row(&"hair_color").get_swatches().mouse_entered.emit()
	assert_eq(creator.get_focus_index(), CharacterOptions.FIELDS.find(&"hair_color"), "Renk örneği üzerine gelmek satırı odaklamalı")


func test_inactive_screen_ignores_mouse() -> void:
	creator.accept()
	creator.get_row(&"skin").get_arrows()[1].mouse_entered.emit()
	assert_eq(creator.get_focus_index(), 0, "Onaydan sonra fare odağı değiştirmemeli")
	creator.get_row(&"skin").get_arrows()[1].pressed.emit()
	assert_eq(creator.get_profile().skin, 0, "Onaydan sonra oklar değer değiştirmemeli")


# --- Klavye ----------------------------------------------------------------------

# --- Modele çizili özellikler -------------------------------------------------------

func test_painted_features_are_locked_on_meshy_models() -> void:
	# Meshy modellerinde sakal, bıyık ve göz biçimi yüze çizilidir: satırları soluk ve oksuzdur,
	# değer yerine "Modelde çizili" yazar; oklar ya da tuşlar alanı değiştirmez.
	assert_true(creator.get_avatar().has_meshy_model(), "Varsayılan karakter Meshy modeli (Mete) olmalı")
	for field in CharacterOptions.PAINTED_FIELDS:
		var row := creator.get_row(field)
		assert_false(row.adjustable, "%s Meshy modelinde ayarlanamamalı" % field)
		assert_eq(row.get_value_text(), CharacterOptions.PAINTED_TEXT)
		for arrow in row.get_arrows():
			assert_false(arrow.visible, "Kilitli satırda ok görünmemeli (%s)" % field)
		var before := creator.get_profile().get_value(field)
		creator.change(field, 1)
		assert_eq(creator.get_profile().get_value(field), before, "Kilitli alan değişmemeli (%s)" % field)
	assert_eq(creator.get_history_size(), 0, "Kilitli alanlar geçmişe adım eklememeli")
	for field in CharacterOptions.FIELDS:
		if not field in CharacterOptions.PAINTED_FIELDS:
			assert_true(creator.get_row(field).adjustable, "%s ayarlanabilir kalmalı" % field)


func test_keyboard_and_mouse_skip_locked_rows() -> void:
	var hair := CharacterOptions.FIELDS.find(&"hair_color")
	var eye := CharacterOptions.FIELDS.find(&"eye_color")
	creator.get_row(&"hair_color").hovered.emit(&"hair_color")
	assert_eq(creator.get_focus_index(), hair)
	creator._unhandled_input(_action(&"ui_down"))
	assert_eq(creator.get_focus_index(), eye, "Aşağı ok kilitli satırları atlamalı")
	creator._unhandled_input(_action(&"ui_up"))
	assert_eq(creator.get_focus_index(), hair, "Yukarı ok da kilitli satırları atlamalı")
	creator.get_row(&"beard").hovered.emit(&"beard")
	assert_eq(creator.get_focus_index(), hair, "Fare kilitli satıra gelince odak değişmemeli")


func test_painted_features_unlock_on_the_chibi_fallback() -> void:
	creator.get_avatar().use_meshy_models = false
	creator.open(CharacterProfile.new())
	assert_false(creator.get_avatar().has_meshy_model(), "Modeller kapalıyken chibi yedeği gösterilmeli")
	for field in CharacterOptions.PAINTED_FIELDS:
		assert_true(creator.get_row(field).adjustable, "%s chibi karakterde ayarlanabilmeli" % field)
	creator.change(&"beard", 1)
	assert_eq(creator.get_profile().beard, 1)
	assert_eq(creator.get_row(&"beard").get_value_text(), CharacterOptions.value_name(&"beard", 1))


func test_step_focus_helper_skips_locked_rows() -> void:
	var flags: Array[bool] = [true, true, true, true, false, false, false, true]
	assert_eq(CharacterCreator.step_focus(3, 1, flags), 7, "Kilitli satırlar atlanmalı")
	assert_eq(CharacterCreator.step_focus(7, -1, flags), 3)
	assert_eq(CharacterCreator.step_focus(7, 1, flags), 0, "Sondan başa sarmalı")
	assert_eq(CharacterCreator.step_focus(0, -1, flags), 7, "Baştan sona sarmalı")
	assert_eq(CharacterCreator.step_focus(1, 2, flags), 3, "İki adımda iki açık satır ilerlemeli")
	assert_eq(CharacterCreator.step_focus(2, 0, flags), 2)
	var none: Array[bool] = [false, false]
	assert_eq(CharacterCreator.step_focus(1, 1, none), 1, "Hiç açık satır yoksa odak yerinde kalmalı")
	var empty: Array[bool] = []
	assert_eq(CharacterCreator.step_focus(3, 1, empty), 0)
	assert_true(CharacterOptions.is_adjustable(&"beard", false), "Chibi karakterde sakal ayarlanabilir")
	assert_false(CharacterOptions.is_adjustable(&"beard", true), "Meshy modelinde sakal yüze çizili")
	assert_true(CharacterOptions.is_adjustable(&"hair_color", true), "Saç rengi her modelde ayarlanabilir")


func test_wrap_focus_helper() -> void:
	assert_eq(CharacterCreator.wrap_focus(0, -1, 8), 7, "İlk satırdan yukarı: son satır")
	assert_eq(CharacterCreator.wrap_focus(7, 1, 8), 0, "Son satırdan aşağı: ilk satır")
	assert_eq(CharacterCreator.wrap_focus(3, 1, 8), 4)
	assert_eq(CharacterCreator.wrap_focus(2, 0, 0), 0, "Satır yoksa 0")


func test_command_for_event_maps_actions() -> void:
	assert_eq(CharacterCreator.command_for_event(_action(&"ui_up")), &"up")
	assert_eq(CharacterCreator.command_for_event(_action(&"move_back")), &"down")
	assert_eq(CharacterCreator.command_for_event(_action(&"ui_left")), &"left")
	assert_eq(CharacterCreator.command_for_event(_action(&"move_right")), &"right")
	assert_eq(CharacterCreator.command_for_event(_action(&"accept")), &"accept")
	assert_eq(CharacterCreator.command_for_event(_action(&"undo")), &"undo")
	assert_eq(CharacterCreator.command_for_event(_action(&"ui_focus_next")), &"view")
	assert_eq(CharacterCreator.command_for_event(_action(&"ui_up", false)), &"", "Bırakılan tuş komut değildir")
	assert_eq(CharacterCreator.command_for_event(_action(&"sprint")), &"")
	assert_eq(CharacterCreator.command_for_event(null), &"")


func test_physical_keys_map_to_commands() -> void:
	assert_eq(CharacterCreator.command_for_event(_key(KEY_ESCAPE)), &"undo")
	assert_eq(CharacterCreator.command_for_event(_key(KEY_E)), &"accept")
	assert_eq(CharacterCreator.command_for_event(_key(KEY_ENTER)), &"accept")
	assert_eq(CharacterCreator.command_for_event(_key(KEY_S)), &"down")
	assert_eq(CharacterCreator.command_for_event(_key(KEY_D)), &"right")
	assert_eq(CharacterCreator.command_for_event(_key(KEY_RIGHT, true)), &"right", "Yön tuşu basılı tutulunca tekrarlar")
	assert_eq(CharacterCreator.command_for_event(_key(KEY_E, true)), &"", "Onay tuşu tekrarlamaz")
	assert_eq(CharacterCreator.command_for_event(_key(KEY_SPACE)), &"", "Boşluk tuşu onaylamamalı")


func test_keypad_enter_accepts() -> void:
	var kp := InputEventKey.new()
	kp.keycode = KEY_KP_ENTER
	kp.pressed = true
	assert_eq(CharacterCreator.command_for_event(kp), &"accept", "Sayısal tuş takımındaki Enter da onaylamalı")
	kp.echo = true
	assert_eq(CharacterCreator.command_for_event(kp), &"", "Basılı tutulan Enter tekrar onaylamaz")


func test_gamepad_buttons_map_to_commands() -> void:
	assert_eq(CharacterCreator.command_for_event(_joy_button(JOY_BUTTON_A)), &"accept")
	assert_eq(CharacterCreator.command_for_event(_joy_button(JOY_BUTTON_B)), &"undo")
	assert_eq(CharacterCreator.command_for_event(_joy_button(JOY_BUTTON_DPAD_DOWN)), &"down")


func test_analog_stick_steps_once_per_push() -> void:
	# İtili tutulan çubuk sürekli yeni hareket olayları üretir; her biri ayrı adım sayılmamalı.
	creator._unhandled_input(_stick(JOY_AXIS_LEFT_Y, 0.7))
	creator._unhandled_input(_stick(JOY_AXIS_LEFT_Y, 0.9))
	creator._unhandled_input(_stick(JOY_AXIS_LEFT_Y, 1.0))
	assert_eq(creator.get_focus_index(), 1, "Tutulan çubuk tek adım atmalı")
	creator._unhandled_input(_stick(JOY_AXIS_LEFT_Y, 0.1))
	creator._unhandled_input(_stick(JOY_AXIS_LEFT_Y, 0.9))
	assert_eq(creator.get_focus_index(), 2, "Bırakıp yeniden itmek bir adım daha atmalı")
	creator._unhandled_input(_stick(JOY_AXIS_LEFT_Y, -0.9))
	assert_eq(creator.get_focus_index(), 1, "Ters yöne itmek hemen geri gitmeli")
	var field: StringName = CharacterOptions.FIELDS[1]
	creator._unhandled_input(_stick(JOY_AXIS_LEFT_X, 0.8))
	creator._unhandled_input(_stick(JOY_AXIS_LEFT_X, 0.95))
	assert_eq(creator.get_profile().get_value(field), 1, "Yatay eksen de itiş başına bir değer değiştirmeli")


func test_is_stick_repeat_helper() -> void:
	assert_false(CharacterCreator.is_stick_repeat(&"", &"down"), "İlk itiş yeni adımdır")
	assert_true(CharacterCreator.is_stick_repeat(&"down", &"down"), "Aynı yönde tutmak tekrardır")
	assert_false(CharacterCreator.is_stick_repeat(&"down", &"up"), "Ters yön yeni adımdır")
	assert_false(CharacterCreator.is_stick_repeat(&"down", &""), "Bırakmak adım değildir ama tekrar da değildir")


func test_hover_sound_gap_helper() -> void:
	assert_true(CharacterCreator.hover_sound_allowed(1000, 1000 - CharacterCreator.HOVER_SOUND_GAP_MS))
	assert_false(CharacterCreator.hover_sound_allowed(1000, 990), "Aynı anda gelen ikinci ses çalınmamalı")


func test_open_releases_foreign_keyboard_focus() -> void:
	# Arkada odakta kalan bir düğme ok tuşlarını ve Enter'ı yutmamalı.
	var button := Button.new()
	add_child(button)
	button.grab_focus()
	assert_eq(get_viewport().gui_get_focus_owner(), button)
	creator.open(CharacterProfile.new())
	assert_null(get_viewport().gui_get_focus_owner(), "Ekran açılınca başka denetimin odağı bırakılmalı")
	button.queue_free()


func test_keyboard_moves_focus_and_changes_value() -> void:
	creator._unhandled_input(_action(&"ui_down"))
	assert_eq(creator.get_focus_index(), 1)
	var field: StringName = CharacterOptions.FIELDS[1]
	creator._unhandled_input(_action(&"ui_right"))
	assert_eq(creator.get_profile().get_value(field), 1)
	creator._unhandled_input(_action(&"ui_left"))
	creator._unhandled_input(_action(&"ui_left"))
	assert_eq(creator.get_profile().get_value(field), CharacterOptions.count(field) - 1, "Geri ok başa sarar")
	creator._unhandled_input(_action(&"ui_up"))
	creator._unhandled_input(_action(&"ui_up"))
	assert_eq(creator.get_focus_index(), CharacterOptions.FIELDS.size() - 1)


func test_keyboard_accept_and_undo() -> void:
	creator.change(&"skin", 1)
	creator._unhandled_input(_action(&"undo"))
	assert_eq(creator.get_profile().skin, 0)
	var watcher := watch_signal(creator.accepted)
	creator._unhandled_input(_action(&"accept"))
	assert_true(watcher.fired)
	creator._unhandled_input(_action(&"ui_right"))
	assert_eq(creator.get_profile().get_value(CharacterOptions.FIELDS[0]), 0, "Onaydan sonra girdi yok sayılmalı")


# --- Yardımcı sınıflar ------------------------------------------------------------------

func test_swatch_index_at() -> void:
	var size := CreatorSwatches.strip_size(5)
	var cy := size.y * 0.5
	assert_eq(CreatorSwatches.index_at(Vector2(CreatorSwatches.center_x(0), cy), 5, size.y), 0)
	assert_eq(CreatorSwatches.index_at(Vector2(CreatorSwatches.center_x(3) + 6.0, cy - 4.0), 5, size.y), 3)
	assert_eq(CreatorSwatches.index_at(Vector2(CreatorSwatches.center_x(4) + CreatorSwatches.SPACING, cy), 5, size.y), -1)
	assert_eq(CreatorSwatches.index_at(Vector2(CreatorSwatches.center_x(2), -20.0), 5, size.y), -1)
	assert_eq(CreatorSwatches.index_at(Vector2(10.0, cy), 0, size.y), -1)
	assert_true(CreatorSwatches.strip_size(11).x > CreatorSwatches.strip_size(9).x)


func test_arrow_triangle_points_toward_direction() -> void:
	var right := CreatorArrow.triangle_points(Vector2.ZERO, Vector2(10.0, 12.0), 1)
	assert_eq(right.size(), 3)
	assert_almost(right[0].x, 5.0)
	assert_almost(right[1].x, -5.0)
	var left := CreatorArrow.triangle_points(Vector2.ZERO, Vector2(10.0, 12.0), -1)
	assert_almost(left[0].x, -5.0)


func test_turntable_helpers() -> void:
	assert_almost(CreatorTurntable.drag_yaw(0.0, 100.0, 1.0), 100.0 * CreatorTurntable.DRAG_SENSITIVITY)
	assert_almost(CreatorTurntable.drag_yaw(0.0, 100.0, 2.0), 50.0 * CreatorTurntable.DRAG_SENSITIVITY, 0.0001,
		"Yüksek çözünürlükte aynı fare hareketi aynı dönüşü vermeli")
	assert_almost(CreatorTurntable.follow(0.0, 1.0, 9.0, 10.0), 1.0, 0.001)
	var half := CreatorTurntable.follow(0.0, 1.0, 9.0, 1.0 / 60.0)
	assert_between(half, 0.05, 0.3, "Tek karede hedefin bir kısmına yaklaşmalı")
	# Önceden yüklenecek modeller: her vücut tipi x saç modeli bir kez (katalog büyüse de geçerli).
	var paths := CreatorTurntable.player_model_paths()
	for body_type in CharacterOptions.BODY_TYPES.size():
		for i in CharacterOptions.count(&"hairstyle", body_type):
			var path := CharacterOptions.model_path(CharacterOptions.model_for(body_type, i))
			assert_true(paths.has(path), "Önceden yükleme listesinde olmalı: %s" % path)
	var unique := {}
	for model_path in paths:
		unique[model_path] = true
	assert_eq(unique.size(), paths.size(), "Model yolları tekrarsız olmalı")
	assert_almost(CreatorTurntable.render_scale_for(Vector2(3456.0, 2104.0), Vector2(1920.0, 1169.0)), 1.8, 0.01)
	assert_almost(CreatorTurntable.render_scale_for(Vector2(1280.0, 720.0), Vector2(1920.0, 1080.0)), 1.0)
	assert_almost(CreatorTurntable.render_scale_for(Vector2.ZERO, Vector2.ZERO), 1.0)
	assert_almost(CreatorTurntable.render_scale_for(Vector2(7680.0, 4320.0), Vector2(1920.0, 1080.0)), CreatorTurntable.MAX_RENDER_SCALE)


func test_pan_gesture_zoom_direction() -> void:
	assert_eq(CreatorTurntable.zoom_direction_for_pan(Vector2(0.0, -0.4)), 1, "Yukarı kaydırma yakınlaştırır (tekerlek gibi)")
	assert_eq(CreatorTurntable.zoom_direction_for_pan(Vector2(0.0, 0.4)), -1, "Aşağı kaydırma tam boya döner")
	assert_eq(CreatorTurntable.zoom_direction_for_pan(Vector2(0.0, 0.01)), 0, "Çok küçük hareket yok sayılır")
	assert_eq(CreatorTurntable.zoom_direction_for_pan(Vector2(0.6, 0.2)), 0, "Çoğunlukla yatay hareket yakınlığı değiştirmez")
	var turntable := creator.get_turntable()
	var pan := InputEventPanGesture.new()
	pan.delta = Vector2(0.0, -0.5)
	turntable._gui_input(pan)
	assert_true(turntable.is_close_up(), "Dokunmatik yüzeyde iki parmakla kaydırma yakın plana geçmeli")
	pan.delta = Vector2(0.0, 0.5)
	turntable._gui_input(pan)
	assert_false(turntable.is_close_up())


func test_closing_during_preload_collects_pending_models() -> void:
	# Ekran, modeller arka planda yüklenirken kapatılırsa bekleyen yüklemeler teslim alınmalı;
	# yoksa yükleme kayıtları ve modeller oyun kapanana kadar bellekte kalır.
	CreatorTurntable.preload_enabled = true
	var other := CREATOR_SCENE.instantiate() as CharacterCreator
	other.auto_open = false
	add_child(other)
	var turntable := other.get_turntable()
	remove_child(other)
	assert_false(turntable.is_preloading(), "Ağaçtan çıkarken bekleyen yükleme kalmamalı")
	other.free()
	CreatorTurntable.preload_enabled = false


func test_turntable_drag_rotates_target() -> void:
	var turntable := creator.get_turntable()
	var before := turntable.target_yaw
	turntable.rotate_by_drag(80.0)
	assert_true(turntable.target_yaw > before, "Sağa sürüklemek hedef açıyı artırmalı")
	turntable.reset_rotation(true)
	assert_almost(turntable.yaw, deg_to_rad(turntable.start_yaw_degrees))


func test_camera_frame_interpolates_between_views() -> void:
	var a := Vector3(0.0, 1.0, 3.0)
	var b := Vector3(0.0, 1.2, 1.5)
	var start := CreatorTurntable.camera_frame(0.0, a, Vector3.ZERO, b, Vector3.UP)
	assert_vec_almost(start[0], a)
	assert_vec_almost(start[1], Vector3.ZERO)
	var finish := CreatorTurntable.camera_frame(1.0, a, Vector3.ZERO, b, Vector3.UP)
	assert_vec_almost(finish[0], b)
	assert_vec_almost(finish[1], Vector3.UP)
	var middle := CreatorTurntable.camera_frame(0.5, a, Vector3.ZERO, b, Vector3.UP)
	assert_vec_almost(middle[0], (a + b) * 0.5)
	assert_vec_almost(CreatorTurntable.camera_frame(7.0, a, Vector3.ZERO, b, Vector3.UP)[0], b, 0.001, "t sınırlandırılmalı")


## Bir dünya noktasının kadrajdaki dikey yeri (0 = üst kenar, 1 = alt kenar; dikey görüş açısı fov_deg).
static func _screen_v(frame: Array[Vector3], point: Vector3, fov_deg: float) -> float:
	var basis := Basis.looking_at(frame[1] - frame[0], Vector3.UP)
	var local := basis.inverse() * (point - frame[0])
	return 0.5 - (local.y / -local.z) / tan(deg_to_rad(fov_deg) * 0.5) * 0.5


func test_full_frame_fits_any_height() -> void:
	# Kadraj boya göre kurulur: 1.82 m Mete de 1.3 m'lik bir karakter de baştan ayağa, aynı oranda görünür.
	for height in [1.3, 1.68, 1.82]:
		var frame := CreatorTurntable.full_frame(height, 30.0, 0.8, 0.535, 5.0)
		var top := _screen_v(frame, Vector3(0.0, height, 0.0), 30.0)
		var bottom := _screen_v(frame, Vector3.ZERO, 30.0)
		assert_almost(bottom - top, 0.8, 0.03, "Karakter ekran yüksekliğinin ~%%80'ini kaplamalı (boy %.2f)" % height)
		assert_between(top, 0.05, 0.2, "Baş başlık şeridinin altında kalmalı (boy %.2f)" % height)
		assert_between(bottom, 0.8, 0.95, "Ayaklar ipucu yazısının üstünde kalmalı (boy %.2f)" % height)
	var tall := CreatorTurntable.full_frame(1.82, 30.0, 0.8, 0.535, 5.0)
	var short := CreatorTurntable.full_frame(1.3, 30.0, 0.8, 0.535, 5.0)
	assert_true(tall[0].z > short[0].z, "Uzun karakterde kamera geri çekilmeli")


func test_close_frame_centers_the_face() -> void:
	var frame := CreatorTurntable.close_frame(1.82, 1.54, 30.0, 0.7, 0.46, 3.0)
	var face_y := 1.54 + (1.82 - 1.54) * 0.35
	assert_almost(_screen_v(frame, Vector3(0.0, face_y, 0.0), 30.0), 0.46, 0.02, "Yüz kadrajda verilen yükseklikte")
	assert_between(_screen_v(frame, Vector3(0.0, 1.82, 0.0), 30.0), 0.05, 0.35, "Kafanın tepesi kadrajın içinde")
	assert_between(_screen_v(frame, Vector3(0.0, 1.54, 0.0), 30.0), 0.5, 0.85, "Çene hizası kadrajın içinde")
	var full := CreatorTurntable.full_frame(1.82, 30.0, 0.8, 0.535, 5.0)
	assert_true(frame[0].distance_to(frame[1]) < full[0].distance_to(full[1]) * 0.5, "Yakın plan tam boydan çok daha yakın")


func test_turntable_frames_follow_model_height() -> void:
	var turntable := creator.get_turntable()
	var avatar := creator.get_avatar()
	var camera := turntable.get_node(^"Viewport/Camera") as Camera3D
	var height := avatar.get_model_height()
	var expected := CreatorTurntable.full_frame(height, camera.fov, turntable.full_fill, turntable.full_center,
		turntable.full_elevation_degrees)
	var frames := turntable.get_frames()
	assert_vec_almost(frames[0], expected[0], 0.001, "Tam boy kadraj gösterilen karakterin boyuna göre kurulmalı")
	assert_vec_almost(frames[1], expected[1], 0.001)
	# Vücut tipi değişince (Mete 1.82 m → kadın kahraman 1.68 m) kadraj yeni boya göre yeniden kurulur.
	creator.change(&"body_type", 1)
	await wait_frames(1)
	var other := avatar.get_model_height()
	if absf(other - height) > 0.05:
		assert_true(turntable.get_frames()[1].y < frames[1].y, "Kısa karakterde kameranın baktığı nokta aşağı inmeli")
	assert_vec_almost(turntable.get_frames()[1], CreatorTurntable.full_frame(other, camera.fov, turntable.full_fill,
		turntable.full_center, turntable.full_elevation_degrees)[1], 0.001)


func test_view_toggle_switches_camera_and_subtitle() -> void:
	var turntable := creator.get_turntable()
	var watcher := watch_signal(turntable.view_changed)
	creator._unhandled_input(_action(&"ui_focus_next"))
	assert_true(turntable.is_close_up(), "Tab yakın plana geçmeli")
	assert_eq(watcher.count, 1)
	assert_eq(watcher.last_args[0], true)
	turntable.set_close_up(true)
	assert_eq(watcher.count, 1, "Aynı çerçeveye tekrar geçmek sinyal yaymamalı")
	await get_tree().create_timer(0.5).timeout
	# «Yola Hazırlan»: alt yazı Mete'nin yaşı ve tarihidir, kadrajla değişmez; yakın planda ipucu söner.
	assert_eq((creator.get_node(^"%Subtitle") as Label).text, CharacterCreator.SUBTITLE_TEXT)
	assert_almost((creator.get_node(^"%Hint") as Label).modulate.a, 0.0, 0.05, "Yakın planda ipucu gizlenmeli")
	assert_true(turntable.zoom > 0.5, "Kamera yakın plana doğru ilerlemeli")
	creator.open(CharacterProfile.new())
	assert_false(turntable.is_close_up(), "Yeniden açılınca tam boydan başlamalı")
	assert_almost(turntable.zoom, 0.0)


func test_reopen_resets_view_texts_at_once() -> void:
	# Yakın planda kapatılan ekran yeniden açılınca ipucu beklemeden tam boya dönmeli; alt yazı (yaş ve tarih) yerinde kalır.
	var turntable := creator.get_turntable()
	var subtitle := creator.get_node(^"%Subtitle") as Label
	var hint := creator.get_node(^"%Hint") as Label
	creator._unhandled_input(_action(&"ui_focus_next"))
	await get_tree().create_timer(0.4).timeout
	assert_true(hint.modulate.a < 0.5, "Yakın planda ipucu sönmeli")
	creator.accept()
	creator.open(CharacterProfile.new())
	assert_false(turntable.is_close_up())
	assert_eq(subtitle.text, CharacterCreator.SUBTITLE_TEXT, "Alt yazı Mete'nin yaşı ve tarihidir")
	assert_almost(subtitle.modulate.a, 1.0)
	assert_almost(hint.modulate.a, 1.0, 0.001, "İpucu yazısı hemen görünmeli")


func test_quick_view_toggle_leaves_hint_visible() -> void:
	# Tab'a art arda iki kez basılınca ipucu yazısının solma animasyonları birbiriyle yarışmamalı.
	var hint := creator.get_node(^"%Hint") as Label
	creator._unhandled_input(_action(&"ui_focus_next"))
	creator._unhandled_input(_action(&"ui_focus_next"))
	await get_tree().create_timer(0.5).timeout
	assert_false(creator.get_turntable().is_close_up())
	assert_almost(hint.modulate.a, 1.0, 0.01, "Tam boya dönünce ipucu yeniden görünmeli")


func test_preview_is_isolated_and_transparent() -> void:
	var viewport := creator.get_turntable().get_node(^"Viewport") as SubViewport
	assert_true(viewport.own_world_3d, "Önizlemenin kendi 3B dünyası olmalı")
	assert_true(viewport.transparent_bg, "Önizleme arka planı saydam olmalı")
	assert_not_null(creator.get_avatar())


func test_preview_uses_soft_film_grade() -> void:
	var environment := (creator.get_turntable().get_node(^"Viewport/WorldEnvironment") as WorldEnvironment).environment
	assert_true(environment.adjustment_enabled)
	var lut := environment.adjustment_color_correction as Texture3D
	assert_not_null(lut, "Önizlemeye referanstaki soluk film renk ayarı (LUT) uygulanmalı")
	if lut:
		assert_eq(lut.get_width(), CreatorTurntable.GRADE_LUT_SIZE)


func test_hidden_preview_stops_processing() -> void:
	# Oyun sırasında gizli duran oluşturucunun karakter animasyonu boşuna işlenmemeli.
	var viewport := creator.get_turntable().get_node(^"Viewport") as SubViewport
	assert_true(viewport.can_process(), "Görünür ekranda önizleme işlenmeli")
	creator.visible = false
	assert_false(viewport.can_process(), "Gizli ekranda önizleme işlenmemeli")
	creator.visible = true
	assert_true(viewport.can_process(), "Ekran yeniden görününce önizleme devam etmeli")


func test_preview_does_not_take_keyboard_focus() -> void:
	# Karakteri fareyle çevirdikten sonra da ok tuşları ve Enter doğrudan bu ekrana gelmeli.
	var turntable := creator.get_turntable()
	assert_eq(turntable.focus_mode, Control.FOCUS_NONE)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = turntable.get_global_rect().get_center()
	press.global_position = press.position
	get_viewport().push_input(press, true)
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false
	get_viewport().push_input(release, true)
	assert_null(get_viewport().gui_get_focus_owner(), "Önizlemeye tıklamak klavye odağını almamalı")


func test_touch_drag_rotates_once() -> void:
	# Parmakla sürükleme hem ScreenDrag hem de ondan türetilmiş bir fare hareketi üretir.
	var turntable := creator.get_turntable()
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	turntable._gui_input(press)
	var before := turntable.target_yaw
	var emulated := InputEventMouseMotion.new()
	emulated.device = InputEvent.DEVICE_ID_EMULATION
	emulated.relative = Vector2(50.0, 0.0)
	turntable._gui_input(emulated)
	assert_almost(turntable.target_yaw, before, 0.0001, "Dokunmatikten türetilmiş fare hareketi ikinci kez döndürmemeli")
	var drag := InputEventScreenDrag.new()
	drag.relative = Vector2(50.0, 0.0)
	turntable._gui_input(drag)
	var after_touch := turntable.target_yaw
	assert_true(after_touch > before, "Parmakla sürüklemek döndürmeli")
	var mouse := InputEventMouseMotion.new()
	mouse.relative = Vector2(50.0, 0.0)
	turntable._gui_input(mouse)
	assert_true(turntable.target_yaw > after_touch, "Fareyle sürüklemek döndürmeli")
	press.pressed = false
	turntable._gui_input(press)


func test_buttons_show_turkish_texts() -> void:
	var undo_button := creator.get_node(^"%UndoButton") as CreatorBrushButton
	var accept_button := creator.get_node(^"%AcceptButton") as CreatorBrushButton
	assert_eq(undo_button.get_text(), "Geri Al")
	assert_eq(undo_button.key_text, "Esc")
	assert_eq(accept_button.get_text(), "Onayla")
	assert_eq(accept_button.key_text, "E")
	assert_eq((creator.get_node(^"%Title") as Label).text, "YOLA HAZIRLAN")
	assert_eq((creator.get_node(^"%Subtitle") as Label).text, "Mete · 20 yaşında · 10 Eylül MÖ 213")


func test_buttons_trigger_undo_and_accept() -> void:
	var cancelled := watch_signal(creator.cancelled)
	(creator.get_node(^"%UndoButton") as BaseButton).pressed.emit()
	assert_true(cancelled.fired, "Geçmiş boşken Geri Al çıkış ister")
	creator.open(CharacterProfile.new())
	var accepted := watch_signal(creator.accepted)
	(creator.get_node(^"%AcceptButton") as BaseButton).pressed.emit()
	assert_true(accepted.fired)


func test_baked_rect_texture_size() -> void:
	assert_eq(CreatorBakedRect.texture_size(Vector2(1920.0, 1080.0), 1.0), Vector2i(1920, 1080))
	assert_eq(CreatorBakedRect.texture_size(Vector2(760.0, 918.0), 1.8), Vector2i(1368, 1653), "Yukarı yuvarlanmalı")
	assert_eq(CreatorBakedRect.texture_size(Vector2.ZERO, 2.0), Vector2i(1, 1), "En az 1 x 1 olmalı")


func test_background_and_paper_are_baked_once() -> void:
	var background := creator.get_node(^"Background") as CreatorBakedRect
	var paper := creator.get_node(^"%Content/Paper") as CreatorBakedRect
	assert_not_null(background)
	assert_not_null(paper)
	assert_not_null(background.bake_material)
	assert_true(paper.transparent, "Kâğıdın gölgeli kenarları saydam pişirilmeli")
	await wait_frames(3)
	var count := background.get_bake_count()
	assert_true(count >= 1)
	await wait_frames(3)
	assert_eq(background.get_bake_count(), count, "Boyut değişmedikçe yeniden pişirilmemeli")
	background.size += Vector2(10.0, 0.0)
	background.queue_bake()
	background.queue_bake()
	await wait_frames(2)
	assert_eq(background.get_bake_count(), count + 1, "Aynı karedeki istekler tek pişirmeye dönüşmeli")
	var rect_size: Vector2 = background.bake_material.get_shader_parameter(&"rect_size")
	assert_vec_almost(Vector3(rect_size.x, rect_size.y, 0.0), Vector3(background.size.x, background.size.y, 0.0))


func test_theme_defines_type_variations() -> void:
	var theme := load(THEME_PATH) as Theme
	assert_not_null(theme)
	for variation in [&"CreatorTitle", &"CreatorSubtitle", &"CreatorFieldLabel", &"CreatorValue", &"CreatorButtonText", &"CreatorKeyChip", &"CreatorHint"]:
		assert_eq(theme.get_type_variation_base(variation), &"Label", "%s bir Label varyasyonu olmalı" % variation)
		assert_true(theme.has_font(&"font", variation), "%s için yazı tipi tanımlı olmalı" % variation)
	assert_true(theme.has_color(&"label_focus", &"CreatorRow"))
	assert_true(theme.has_color(&"ring", &"CreatorSwatches"))


# --- Yardımcılar ------------------------------------------------------------------------

func _action(action: StringName, pressed: bool = true) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	return event


# --- Arayüz ölçeği ------------------------------------------------------------------------

func test_banner_panel_and_hint_follow_the_ui_scale_around_their_anchors() -> void:
	var nodes: Array[Control] = []
	for path in ["%TitleBanner", "%Panel", "%Hint"]:
		nodes.append(creator.get_node(path) as Control)
	for c in nodes:
		assert_almost(c.scale.x, UIKit.ui_k(), 0.001, "%s arayüz ölçeğinde çizilmeli" % c.name)
		assert_eq(c.pivot_offset, Vector2(-c.offset_left, -c.offset_top), "%s çapa noktasının çevresinde ölçeklenmeli" % c.name)
	# Panel sağ kenarın ortasına çapalı: ölçek ne olursa olsun çapa noktası orada kalır.
	var panel := nodes[1]
	var anchor_point := panel.position + panel.pivot_offset
	assert_almost(anchor_point.x, creator.size.x, 0.5, "Panelin çapası sağ kenarda")
	assert_almost(anchor_point.y, creator.size.y * 0.5, 0.5, "Panelin çapası dikeyde ortada")
	# Oyuncu ölçeği değiştirince (ayarlar "changed" yayar) hemen uyulur.
	var settings := UIKit.settings_node()
	if settings == null:
		return
	var before: float = settings.ui_scale
	settings.ui_scale = 0.8
	settings.changed.emit()
	for c in nodes:
		assert_almost(c.scale.x, UIKit.ui_k(), 0.001, "%s yeni ölçeğe geçmeli" % c.name)
	settings.ui_scale = before
	settings.changed.emit()


func _joy_button(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	event.pressed = true
	return event


func _stick(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	return event


func _key(keycode: Key, echo: bool = false) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = true
	event.echo = echo
	return event
