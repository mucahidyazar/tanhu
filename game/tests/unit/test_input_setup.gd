extends TestCase
## InputSetup testleri: eylemlerin (WASD, koşma, kamera...) kaydı ve hareket vektörü; tuş ataması (K39, godot.md §5.6): değiştirme,
## çakışmada takas (eski eylem boş kalmaz), kayıt sözlüğü ([input]), bozuk satırın sessizce atlanması, varsayılana dönüş.
##
## Tuşlar "fiziksel" olarak kaydedilir: Türkçe Q ya da F klavyede de aynı yerdeki tuşlar çalışır.
## Testler tuşa basmayı Input.action_press ile taklit eder ve her testten sonra bırakır; atamayı her testten sonra varsayılana döndürür.


func before_each() -> void:
	InputSetup.ensure_actions()


func after_each() -> void:
	# Basılı kalan eylem ve değiştirilen atama sonraki testleri etkilemesin.
	for action in InputSetup.KEY_ACTIONS:
		Input.action_release(action)
	InputSetup.reset_bindings()


# --- ensure_actions -----------------------------------------------------------------

func test_every_action_is_registered_with_its_keys() -> void:
	for action in InputSetup.KEY_ACTIONS:
		assert_true(InputMap.has_action(action), "Eylem eksik: %s" % action)
		for key in InputSetup.KEY_ACTIONS[action]:
			assert_true(InputMap.action_has_event(action, _physical_key(key)), "%s eyleminde %s tuşu yok" % [action, OS.get_keycode_string(key)])


func test_ensure_actions_is_idempotent() -> void:
	var before := {}
	for action in InputSetup.KEY_ACTIONS:
		before[action] = InputMap.action_get_events(action).size()
	InputSetup.ensure_actions()
	InputSetup.ensure_actions()
	for action in InputSetup.KEY_ACTIONS:
		assert_eq(InputMap.action_get_events(action).size(), before[action], "Tekrar çağrı %s eylemine kopya tuş ekledi" % action)


func test_ensure_actions_restores_missing_key_and_keeps_custom_ones() -> void:
	# Eylem zaten varsa (ör. ileride project.godot'ta tanımlanırsa) eksik tuşu yine eklenmeli,
	# oraya elle eklenmiş başka tuşlar da silinmemeli.
	var w := _physical_key(KEY_W)
	var custom := _physical_key(KEY_I)
	InputMap.action_erase_event(&"move_forward", w)
	InputMap.action_add_event(&"move_forward", custom)
	InputSetup.ensure_actions()
	assert_true(InputMap.action_has_event(&"move_forward", w), "Silinen W tuşu geri eklenmeli")
	assert_true(InputMap.action_has_event(&"move_forward", custom), "Elle eklenen tuş korunmalı")
	# Temizlik: sonraki testler varsayılan tuşlarla başlasın.
	InputMap.action_erase_event(&"move_forward", custom)
	if not InputMap.action_has_event(&"move_forward", w):
		InputMap.action_add_event(&"move_forward", w)


func test_keys_are_bound_by_physical_position() -> void:
	for action in InputSetup.KEY_ACTIONS:
		for event in InputMap.action_get_events(action):
			var key := event as InputEventKey
			if key == null:
				continue
			assert_ne(key.physical_keycode, KEY_NONE, "%s fiziksel tuş kullanmalı" % action)
			assert_eq(key.keycode, KEY_NONE, "%s klavye düzenine bağlı tuş kullanmamalı" % action)


func test_book_intro_is_space_and_pad_y() -> void:
	# Destan Kitabı'nın hoparlörü (godot.md §3.8, K86): klavyede Boşluk, oyun kolunda Y.
	assert_true(InputMap.has_action(&"book_intro"))
	assert_true(InputMap.action_has_event(&"book_intro", _physical_key(KEY_SPACE)), "Boşluk tanıtımı çalar")
	var y := InputEventJoypadButton.new()
	y.button_index = JOY_BUTTON_Y
	assert_true(InputMap.action_has_event(&"book_intro", y), "Oyun kolunda Y")
	var before := InputMap.action_get_events(&"book_intro").size()
	InputSetup.ensure_actions()
	assert_eq(InputMap.action_get_events(&"book_intro").size(), before, "Tekrar çağrı kopya düğme eklemez")


func test_physical_w_key_moves_forward() -> void:
	var event := _physical_key(KEY_W)
	event.pressed = true
	assert_true(InputMap.event_is_action(event, &"move_forward"))
	assert_false(InputMap.event_is_action(event, &"move_back"))


# --- move_vector --------------------------------------------------------------------

func test_move_vector_is_zero_without_input() -> void:
	assert_eq(InputSetup.move_vector(), Vector2.ZERO)


func test_move_vector_axes() -> void:
	var expected := {
		&"move_forward": Vector2(0.0, 1.0),
		&"move_back": Vector2(0.0, -1.0),
		&"move_right": Vector2(1.0, 0.0),
		&"move_left": Vector2(-1.0, 0.0),
	}
	for action in expected:
		Input.action_press(action)
		assert_eq(InputSetup.move_vector(), expected[action], "%s yönü yanlış" % action)
		Input.action_release(action)


func test_diagonal_movement_is_limited_to_length_one() -> void:
	# Çapraz yürüyüş düz yürüyüşten hızlı olmamalı.
	Input.action_press(&"move_forward")
	Input.action_press(&"move_right")
	var v := InputSetup.move_vector()
	assert_almost(v.length(), 1.0, 0.0001, "Çapraz vektör uzunluğu 1 olmalı")
	assert_almost(v.x, v.y, 0.0001, "İleri + sağ tam 45 derece olmalı")
	assert_true(v.x > 0.0 and v.y > 0.0)


func test_opposite_keys_cancel_out() -> void:
	Input.action_press(&"move_left")
	Input.action_press(&"move_right")
	Input.action_press(&"move_forward")
	assert_eq(InputSetup.move_vector(), Vector2(0.0, 1.0), "Sol + sağ birbirini sıfırlamalı")


func test_partial_strength_is_kept() -> void:
	# Analog girişte (gamepad) yarım basış yarım hız olmalı; 1'e yuvarlanmamalı.
	Input.action_press(&"move_right", 0.5)
	assert_vec_almost(_v3(InputSetup.move_vector()), Vector3(0.5, 0.0, 0.0), 0.0001)


func test_move_vector_never_exceeds_one() -> void:
	var actions: Array[StringName] = [&"move_forward", &"move_back", &"move_left", &"move_right"]
	for mask in 16:
		for i in actions.size():
			if mask & (1 << i):
				Input.action_press(actions[i])
			else:
				Input.action_release(actions[i])
		assert_true(InputSetup.move_vector().length() <= 1.0 + 0.0001, "Tuş birleşimi %d: uzunluk 1'i aştı" % mask)


# --- Kamera eylemleri (K27, K39) ------------------------------------------------------------------

func test_camera_actions_have_their_design_keys() -> void:
	var want := {
		&"camera_left": [KEY_Q, KEY_COMMA], &"camera_right": [KEY_E, KEY_PERIOD],
		&"camera_pitch_up": [KEY_SEMICOLON], &"camera_pitch_down": [KEY_APOSTROPHE],
		&"camera_zoom_in": [KEY_MINUS], &"camera_zoom_out": [KEY_EQUAL], &"camera_reset": [KEY_SLASH],
	}
	for action: StringName in want:
		for key: Key in want[action]:
			assert_true(InputMap.event_is_action(_pressed(key), action), "%s: %s" % [action, OS.get_keycode_string(key)])
		assert_eq(InputSetup.CONTEXTS[action], "game", "Kamera eylemi oyunda dinlenir")
	assert_eq(InputSetup.conflicts(), [], "Varsayılan atamada aynı bağlamda çakışma yok")


# --- Tuş ataması (godot.md §5.6) ----------------------------------------------------------------------

func test_rebinding_a_free_key_replaces_the_primary_key_only() -> void:
	var r := InputSetup.rebind(&"move_forward", _physical_key(KEY_K))
	assert_true(bool(r["changed"]))
	assert_true(InputSetup.same_event(r["old"], _physical_key(KEY_W)), "Eski tuş W")
	assert_true(InputMap.event_is_action(_pressed(KEY_K), &"move_forward"), "K ileri yürütür")
	assert_false(InputMap.event_is_action(_pressed(KEY_W), &"move_forward"), "W artık yürütmez")
	assert_true(InputMap.event_is_action(_pressed(KEY_UP), &"move_forward"), "İkincil tuş (↑) kalır")
	assert_eq(InputSetup.bindings(), {"move_forward": [{"type": "key", "physical": KEY_K}, {"type": "key", "physical": KEY_UP}]})
	InputSetup.ensure_actions()
	assert_false(InputMap.event_is_action(_pressed(KEY_W), &"move_forward"), "ensure_actions atamayı korur: W geri gelmez")


func test_conflict_in_the_same_context_swaps_so_the_old_action_is_never_empty() -> void:
	# Q oyunda kamerayı döndürür; Zıpla'ya verilirse «Şuna da bağlı: Kamerayı sola döndür»: o eylem Zıpla'nın eski tuşunu (Boşluk) alır.
	assert_eq(InputSetup.conflicts_for(&"jump", _physical_key(KEY_Q)), [&"camera_left"] as Array[StringName])
	assert_eq(InputSetup.conflicts_for(&"jump", _physical_key(KEY_K)), [] as Array[StringName], "Boş tuş")
	assert_eq(InputSetup.conflicts_for(&"book_intro", _physical_key(KEY_Q)), [] as Array[StringName], "Menüdeki eylemle oyundaki çakışmaz")
	var r := InputSetup.rebind(&"jump", _physical_key(KEY_Q))
	assert_eq(r["swapped"], [&"camera_left"] as Array[StringName])
	assert_true(InputMap.event_is_action(_pressed(KEY_Q), &"jump"))
	assert_false(InputMap.event_is_action(_pressed(KEY_Q), &"camera_left"), "Q kameradan alındı")
	assert_true(InputMap.event_is_action(_pressed(KEY_SPACE), &"camera_left"), "Kamera Zıpla'nın eski tuşunu aldı")
	assert_true(InputMap.event_is_action(_pressed(KEY_COMMA), &"camera_left"), "Kameranın öteki tuşu kalır")
	assert_true(InputMap.event_is_action(_pressed(KEY_SPACE), &"book_intro"), "Boşluk menüde tanıtım olarak kalır")
	assert_eq(InputSetup.conflicts(), [], "Takastan sonra çakışma kalmaz")
	for action in InputSetup.managed_actions():
		assert_false(InputSetup.events_of(action).is_empty(), "%s boş kalmadı" % action)


func test_gamepad_buttons_and_mouse_side_buttons_are_rebound_too() -> void:
	var x := InputEventJoypadButton.new()
	x.button_index = JOY_BUTTON_X
	var r := InputSetup.rebind(&"inventory", x)
	assert_true(bool(r["changed"]))
	assert_true(InputMap.event_is_action(x, &"inventory"), "Kolda X envanteri açar")
	assert_true(InputMap.event_is_action(_pressed(KEY_I), &"inventory"), "Klavyedeki I kalır (tür ayrı)")
	var a := InputEventJoypadButton.new()
	a.button_index = JOY_BUTTON_A
	assert_eq(InputSetup.conflicts_for(&"sprint", a), [&"jump"] as Array[StringName], "Kolda A oyunda zıplar")
	var side := InputEventMouseButton.new()
	side.button_index = MOUSE_BUTTON_XBUTTON1
	assert_true(bool(InputSetup.rebind(&"camera_reset", side)["changed"]))
	assert_eq(InputSetup.bindings()["camera_reset"], [{"type": "key", "physical": KEY_SLASH}, {"type": "mouse", "button": MOUSE_BUTTON_XBUTTON1}])
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	assert_false(bool(InputSetup.rebind(&"camera_reset", wheel)["changed"]), "Tekerlek eylem olmaz")
	assert_false(bool(InputSetup.rebind(&"pause", _physical_key(KEY_P))["changed"]), "Esc (oyun menüsü) atanmaz")


func test_saved_bindings_round_trip_and_broken_rows_are_skipped_silently() -> void:
	InputSetup.rebind(&"jump", _physical_key(KEY_K))
	var saved := InputSetup.bindings()
	InputSetup.reset_bindings()
	assert_true(InputMap.event_is_action(_pressed(KEY_SPACE), &"jump"), "Varsayılana dönüş")
	var applied := InputSetup.apply_bindings(saved)
	assert_eq(applied, saved, "Kayıt sözlüğü aynen geri gelir")
	assert_true(InputMap.event_is_action(_pressed(KEY_K), &"jump"))
	InputSetup.reset_bindings()
	# Bilinmeyen eylem, atanamayan eylem, bozuk satır, yinelenen satır ve olayı kalmayan eylem: hata yazmadan atlanır.
	var dirty := {
		"jump": [{"type": "key", "physical": KEY_L}, {"type": "key", "physical": KEY_L}, {"type": "joy_button", "index": 999}, "bozuk", {"type": "mouse", "button": 4}],
		"fly": [{"type": "key", "physical": KEY_F}],
		"pause": [{"type": "key", "physical": KEY_P}],
		"map": "M",
		"journal": [{"type": "key"}, {"physical": KEY_J}],
		12: [{"type": "key", "physical": KEY_Z}],
	}
	var clean := InputSetup.apply_bindings(dirty)
	assert_eq(clean, {"jump": [{"type": "key", "physical": KEY_L}]}, "Yalnız geçerli satır kalır")
	assert_true(InputMap.event_is_action(_pressed(KEY_L), &"jump"))
	assert_true(InputMap.event_is_action(_pressed(KEY_P), &"camera_left") == false and InputMap.event_is_action(_pressed(KEY_ESCAPE), &"pause"), "Esc yerinde")
	assert_true(InputMap.event_is_action(_pressed(KEY_J), &"journal"), "Bozuk satırlı eylem varsayılanında kalır")
	assert_true(InputMap.event_is_action(_pressed(KEY_M), &"map"))
	assert_eq(InputSetup.sanitize_bindings("bozuk"), {}, "Sözlük olmayan kayıt boş sayılır")


func test_reset_bindings_restores_every_default() -> void:
	InputSetup.rebind(&"jump", _physical_key(KEY_Q))
	InputSetup.rebind(&"move_left", _physical_key(KEY_H))
	InputSetup.reset_bindings()
	assert_eq(InputSetup.bindings(), {}, "Atama silindi")
	for action in InputSetup.managed_actions():
		var now := InputSetup.events_of(action)
		var want := InputSetup.default_events(action)
		assert_eq(now.size(), want.size(), "%s varsayılan olay sayısında" % action)
		for i in want.size():
			assert_true(InputSetup.same_event(now[i], want[i]), "%s varsayılanında" % action)


func test_binding_keeps_the_physical_key_whatever_the_layout() -> void:
	# Kayıt fiziksel tuşu tutar: Türkçe Q'da / tuşunun yazısı «.» olsa da kayıtta KEY_SLASH vardır (dizilişten bağımsız).
	var event := InputEventKey.new()
	event.physical_keycode = KEY_SLASH
	event.keycode = KEY_PERIOD
	assert_eq(InputSetup.event_to_dict(event), {"type": "key", "physical": KEY_SLASH})
	var back := InputSetup.event_from_dict({"type": "key", "physical": KEY_SLASH}) as InputEventKey
	assert_eq(back.physical_keycode, KEY_SLASH)
	assert_eq(back.keycode, KEY_NONE, "Dizilişe bağlı kod yazılmaz")


# --- Yardımcılar ---------------------------------------------------------------------

static func _pressed(key: Key) -> InputEventKey:
	var event := _physical_key(key)
	event.pressed = true
	return event


## Fiziksel tuş olayı (klavye düzeninden bağımsız).
static func _physical_key(key: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = key
	return event


static func _v3(v: Vector2) -> Vector3:
	return Vector3(v.x, v.y, 0.0)
