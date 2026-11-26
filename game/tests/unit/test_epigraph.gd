extends TestCase
## Epigraph testleri: Mete'nin açılış sözü (Tanhu 1'deki gibi) — yazılar, siyahtan açılma, bekleme, basışla
## kısalma (belirirken basılan sayılmaz), F11 ve tekerleğin sayılmaması, arayüz ölçeğiyle ortalanma.

var epigraph: Epigraph


func before_each() -> void:
	InputSetup.ensure_actions()
	epigraph = Epigraph.new()
	epigraph.fade_in = 0.05
	epigraph.hold = 30.0
	epigraph.fade_out = 0.05
	add_child(epigraph)


func after_each() -> void:
	if is_instance_valid(epigraph):
		epigraph.queue_free()
	epigraph = null


## Koşul sağlanana ya da süre dolana kadar bekler; sağlandıysa true döner.
func await_condition(condition: Callable, timeout_sec: float = 3.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while not condition.call():
		if Time.get_ticks_msec() > deadline:
			return false
		await get_tree().process_frame
	return true


static func _key(code: Key, pressed := true, echo := false) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = pressed
	e.echo = echo
	return e


static func _mouse(button: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.pressed = true
	return e


func test_texts_are_metes_words_like_tanhu_1() -> void:
	assert_eq(Epigraph.QUOTE, "«Yer, devletin temelidir. Onu kimseye vermem.»")
	assert_eq(Epigraph.BY, "Mete, Hunların Tanhusu · MÖ 3. yüzyıl")
	var quote := epigraph.find_child("Quote", true, false) as Label
	var by := epigraph.find_child("By", true, false) as Label
	assert_not_null(quote, "Söz yazısı olmalı")
	assert_not_null(by, "Kimin söylediği yazısı olmalı")
	assert_eq(quote.text, Epigraph.QUOTE)
	assert_eq(by.text, Epigraph.BY)
	assert_eq(quote.get_theme_font_size(&"font_size"), 48)
	assert_eq(by.get_theme_font_size(&"font_size"), 24)
	assert_eq(quote.horizontal_alignment, HORIZONTAL_ALIGNMENT_CENTER)
	assert_eq(by.horizontal_alignment, HORIZONTAL_ALIGNMENT_CENTER)


func test_starts_black_covers_screen_and_blocks_mouse() -> void:
	assert_almost(epigraph.modulate.a, 0.0, 0.001, "Söz siyahtan açılmalı (başta görünmez)")
	assert_eq(epigraph.mouse_filter, Control.MOUSE_FILTER_STOP, "Alttaki menüye fare ulaşmamalı")
	var bg := epigraph.find_child("Background", true, false) as ColorRect
	assert_not_null(bg, "Koyu arka plan olmalı")
	assert_eq(bg.color, Epigraph.BACKGROUND)
	assert_eq(bg.anchor_right, 1.0)
	assert_eq(bg.anchor_bottom, 1.0)


func test_plays_through_emits_finished_and_frees_itself() -> void:
	epigraph.hold = 0.1
	var watcher := watch_signal(epigraph.finished)
	var started := Time.get_ticks_msec()
	await epigraph.play()
	assert_eq(watcher.count, 1, "finished bir kez yayılmalı")
	assert_true(Time.get_ticks_msec() - started >= 150, "Belirme + bekleme + kaybolma süresi kadar sürmeli")
	await wait_frames(2)
	assert_false(is_instance_valid(epigraph), "Bitince kendini silmeli")


func test_press_during_hold_skips_the_wait() -> void:
	var watcher := watch_signal(epigraph.finished)
	epigraph.play()
	assert_true(await await_condition(func() -> bool: return epigraph.is_waiting()), "Söz belirip beklemeli")
	assert_almost(epigraph.modulate.a, 1.0, 0.001, "Beklerken tam görünür olmalı")
	epigraph._input(_key(KEY_SPACE))
	assert_true(await await_condition(func() -> bool: return watcher.count == 1, 1.0), "Basış 30 sn'lik beklemeyi kısaltmalı")


func test_press_while_fading_in_does_not_skip() -> void:
	epigraph.fade_in = 0.4
	epigraph.play()
	await wait_frames(2)
	assert_false(epigraph.is_waiting(), "Henüz belirme sürüyor")
	epigraph._input(_key(KEY_ENTER))
	assert_true(await await_condition(func() -> bool: return epigraph.is_waiting()), "Belirme bitince beklemeli")
	await wait_frames(5)
	assert_true(epigraph.is_waiting(), "Belirirken basılan tuş beklemeyi kısaltmamalı")
	# Test bitmeden söz kapansın (askıda bekleyen bir await kalmasın).
	var watcher := watch_signal(epigraph.finished)
	epigraph._input(_key(KEY_SPACE))
	assert_true(await await_condition(func() -> bool: return watcher.count == 1, 1.0), "Beklerken basış kısaltmalı")


func test_skip_event_kinds() -> void:
	assert_true(Epigraph.is_skip_event(_key(KEY_SPACE)), "Tuşa basmak")
	assert_false(Epigraph.is_skip_event(_key(KEY_SPACE, false)), "Tuşu bırakmak sayılmaz")
	assert_false(Epigraph.is_skip_event(_key(KEY_SPACE, true, true)), "Basılı tutulan tuşun tekrarı sayılmaz")
	assert_false(Epigraph.is_skip_event(_key(KEY_F11)), "F11 (tam ekran) sayılmaz")
	assert_true(Epigraph.is_skip_event(_mouse(MOUSE_BUTTON_LEFT)), "Sol tık")
	assert_false(Epigraph.is_skip_event(_mouse(MOUSE_BUTTON_WHEEL_UP)), "Tekerlek sayılmaz")
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_A
	pad.pressed = true
	assert_true(Epigraph.is_skip_event(pad), "Oyun kolu düğmesi")
	assert_false(Epigraph.is_skip_event(InputEventMouseMotion.new()), "Fare hareketi sayılmaz")


func test_quote_block_is_centred_at_the_ui_scale() -> void:
	await wait_frames(2)
	var box := epigraph.find_child("Box", true, false) as Control
	var k := UIKit.ui_k()
	assert_almost(box.scale.x, k, 0.001, "Söz bloğu arayüz ölçeğinde çizilmeli")
	var centre := box.position + box.size * k * 0.5
	var vp := epigraph.get_viewport_rect().size
	assert_almost(centre.x, vp.x * 0.5, 1.0, "Yatayda ortada")
	assert_almost(centre.y, vp.y * 0.5, 1.0, "Dikeyde ortada")
	assert_true(box.size.x > 400.0, "Söz tek satırda, geniş bir blok olmalı")
