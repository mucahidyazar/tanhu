extends TestCase
## GameHud testleri: ipucu yazısı, tuş kapakçıkları, gösterme / kendiliğinden solma / gizleme.

const HUD_SCENE := preload("res://scenes/ui/game_hud.tscn")
const EXPECTED_TEXT := "WASD: Yürü · Shift: Koş · Q/E: Kamerayı döndür · Tekerlek: Yakınlaş · Esc: Menü"

var hud: GameHud


func before_each() -> void:
	hud = HUD_SCENE.instantiate() as GameHud
	hud.transition_speed = 10.0
	add_child(hud)


func after_each() -> void:
	if is_instance_valid(hud):
		hud.queue_free()
	hud = null


## Koşul sağlanana ya da süre dolana kadar bekler; sağlandıysa true döner.
func await_condition(condition: Callable, timeout_sec: float = 3.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout_sec * 1000.0)
	while not condition.call():
		if Time.get_ticks_msec() > deadline:
			return false
		await get_tree().process_frame
	return true


func test_hint_text_is_exact() -> void:
	assert_eq(hud.get_hint_text(), EXPECTED_TEXT)
	assert_eq(GameHud.format_hints(GameHud.HINTS), EXPECTED_TEXT)
	assert_eq(GameHud.format_hints([["A", "B"]]), "A: B")
	assert_eq(GameHud.format_hints([]), "")


func test_builds_one_key_cap_per_hint() -> void:
	var keys: Array[String] = []
	var actions: Array[String] = []
	for label in hud.find_children("*", "Label", true, false):
		var l := label as Label
		if l.theme_type_variation == &"HudKey":
			keys.append(l.text)
		elif l.theme_type_variation == &"HudAction":
			actions.append(l.text)
	assert_eq(keys, ["WASD", "Shift", "Q/E", "Tekerlek", "Esc"] as Array[String])
	assert_eq(actions, ["Yürü", "Koş", "Kamerayı döndür", "Yakınlaş", "Menü"] as Array[String])


func test_starts_hidden_and_does_not_block_mouse() -> void:
	assert_false(hud.visible, "HUD başta gizli olmalı")
	assert_false(hud.is_showing())
	assert_eq(hud.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	for control in hud.find_children("*", "Control", true, false):
		assert_eq((control as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s fareyi engellememeli" % control.name)


func test_hint_panel_follows_the_ui_scale_around_its_corner() -> void:
	var panel := hud.get_node("%HintPanel") as Control
	assert_almost(panel.scale.x, UIKit.ui_k(), 0.001, "İpucu paneli arayüz ölçeğinde çizilmeli")
	assert_eq(panel.pivot_offset, Vector2(-panel.offset_left, -panel.offset_top), "Sol alt köşesinin çevresinde ölçeklenmeli")
	var corner := panel.position + panel.pivot_offset
	var content := panel.get_parent() as Control
	assert_almost(corner.x, 0.0, 0.5, "Çapa noktası sol kenarda")
	assert_almost(corner.y, content.size.y, 0.5, "Çapa noktası alt kenarda")
	var settings := UIKit.settings_node()
	if settings == null:
		return
	var before: float = settings.ui_scale
	settings.ui_scale = 0.8
	settings.changed.emit()
	assert_almost(panel.scale.x, UIKit.ui_k(), 0.001, "Ölçek ayarı değişince panel de küçülmeli")
	settings.ui_scale = before
	settings.changed.emit()


func test_show_hints_fades_in_then_out_by_itself() -> void:
	hud.hint_duration = 0.2
	var watcher := watch_signal(hud.hints_hidden)
	hud.show_hints()
	assert_true(hud.visible, "show_hints görünür yapmalı")
	assert_true(hud.is_showing())
	assert_true(await await_condition(func() -> bool: return hud.modulate.a > 0.99), "Tam görünür olmalı")
	assert_true(await await_condition(func() -> bool: return not hud.visible), "Süre dolunca kendiliğinden solmalı")
	assert_false(hud.is_showing())
	assert_eq(watcher.count, 1, "hints_hidden bir kez yayılmalı")


func test_hide_hud_immediately_and_animated() -> void:
	hud.show_hints()
	hud.hide_hud(false)
	assert_false(hud.visible, "hide_hud(false) hemen gizlemeli")
	assert_false(hud.is_showing())
	hud.show_hints()
	hud.hide_hud()
	assert_false(hud.is_showing(), "Solmaya başlayınca artık 'gösteriliyor' sayılmaz")
	assert_true(await await_condition(func() -> bool: return not hud.visible), "Kısa solmadan sonra gizlenmeli")


func test_is_showing_turns_false_when_auto_fade_starts() -> void:
	hud.hint_duration = 0.1
	hud.transition_speed = 2.0
	hud.show_hints()
	assert_true(await await_condition(func() -> bool: return hud.modulate.a > 0.99), "Önce tam görünür olmalı")
	# Kendiliğinden solma başlayınca (ama panel henüz kaybolmadan) artık "gösteriliyor" sayılmamalı.
	assert_true(await await_condition(func() -> bool: return hud.modulate.a < 0.9), "Kendiliğinden solmalı")
	if hud.visible:
		assert_false(hud.is_showing(), "Solarken is_showing() false olmalı")


func test_hide_hud_finishes_while_game_is_paused() -> void:
	hud.show_hints()
	await wait_frames(3)
	get_tree().paused = true
	hud.hide_hud()
	var hidden: bool = await await_condition(func() -> bool: return not hud.visible)
	get_tree().paused = false
	assert_true(hidden, "Oyun duraklatılmışken de (ör. Esc ile menüye dönerken) panel solup gizlenmeli")


func test_show_again_restarts_timer() -> void:
	hud.hint_duration = 0.25
	hud.show_hints()
	await get_tree().create_timer(0.05).timeout
	hud.show_hints()
	assert_true(hud.visible)
	assert_true(hud.is_showing(), "Yeniden gösterilince süre baştan başlamalı")


func test_show_before_ready_is_kept() -> void:
	var other := HUD_SCENE.instantiate() as GameHud
	other.show_hints()
	add_child(other)
	assert_true(other.visible, "Sahneye eklenmeden önce istenen ipuçları gösterilmeli")
	assert_true(other.is_showing())
	other.queue_free()
