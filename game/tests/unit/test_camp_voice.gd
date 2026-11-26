extends TestCase
## Serbest Gez'in kamp sözleri (CampVoice; E20/7) gerçek ana sahnede: Çocuk ateş başındaki kütükten kalkınca Ana («Uzağa gitme, kızım.»),
## ozanın yanında durunca Ozan («Otur. Önce kopuz söylesin.»), ahırın önüne varınca Baba («Doru'nun arkasından geçme. Teper.») konuşur;
## sözler Voice yolunda çalar, altyazıda konuşanın adıyla görünür, her biri bir kez. Menüye dönüşte altyazı silinir.

const MAIN_SCENE := "res://scenes/main.tscn"
const TempDir := preload("res://tests/support/temp_dir.gd")

var _dir := ""


func before_each() -> void:
	MenuStyle.muted = true
	_dir = TempDir.fresh("kamp_sozleri")


func after_each() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	TempDir.wipe(_dir)


func test_fireside_people_speak_to_the_child() -> void:
	var main = load(MAIN_SCENE).instantiate()
	main.quit_handler = func() -> void: pass
	main.saves = SaveSystem.new(_dir)
	main.prologue_path = ""
	add_child(main)
	await wait_frames(3)
	main.menu.finish_intro()
	main.menu.free_roam_requested.emit()
	await _wait_until(func() -> bool: return main.state == main.State.PLAYING, 8.0)
	assert_eq(main.state, main.State.PLAYING, "Serbest Gez")
	var cv: CampVoice = main._camp_voice
	assert_not_null(cv, "Kamp sözleri kurulu")
	if cv == null:
		await _leave(main)
		return
	var player: PlayerController = main.player
	assert_true(player.is_child(), "Serbest Gez'in oyuncusu Çocuk")
	var voiced: Array[String] = []
	var audio := get_node_or_null(^"/root/AudioManager")
	var on_line := func(id: String) -> void: voiced.append(id)
	if audio:
		audio.line_started.connect(on_line)
	# Kalkış: oturan Çocuk ateşin yanından ayrılır.
	await _wait_until(func() -> bool: return player.is_seated(), 3.0)
	var seat := player.global_position
	player.spawn_at(seat + Vector3(2.0, 0.0, 2.0), 0.0)
	await _wait_until(func() -> bool: return cv.said().has("rise"), 4.0)
	assert_true(cv.said().has("rise"), "Ana: «Uzağa gitme, kızım.»")
	assert_eq(cv.hud.subtitles.current_text(), "Ana: Uzağa gitme, kızım.", "Altyazıda konuşanın adıyla")
	# Ahır: işaret konunca Baba seslenir (önceki söz bitince). Yerler yolculuğun yer işaretlerinden (x, z, yarıçap).
	var stable := _landmark(main, JourneyFlags.STABLE, JourneyFlags.DEFAULT_STABLE)
	player.spawn_at(Vector3(stable.x, 0.0, stable.y + 3.0), 0.0)
	await _wait_until(func() -> bool: return voiced.has("act0.camp.stable"), 8.0)
	assert_true(cv.said().has("stable"), "Baba: «Doru'nun arkasından geçme. Teper.»")
	assert_true(voiced.has("act0.camp.rise") and voiced.has("act0.camp.stable"), "Sözler Voice yolunda (%s)" % [voiced])
	# Ozan: yanında durmaya başlayınca.
	var bard := _landmark(main, JourneyFlags.BARD_LISTEN, JourneyFlags.DEFAULT_BARD)
	player.spawn_at(Vector3(bard.x + 1.2, 0.0, bard.y + 1.2), 0.0)
	await _wait_until(func() -> bool: return voiced.has("act0.camp.bard"), 8.0)
	assert_true(cv.said().has("bard"), "Ozan: «Otur. Önce kopuz söylesin.»")
	assert_true(voiced.has("act0.camp.bard"), "Ozanın sözü David'in sesiyle çaldı (%s)" % [voiced])
	# Her söz bir kez: ahıra dönüş yeni söz getirmez.
	var count := voiced.size()
	player.spawn_at(Vector3(stable.x, 0.0, stable.y + 3.0), 0.0)
	await get_tree().create_timer(1.0).timeout
	assert_eq(voiced.size(), count, "Söz bir kez söylenir")
	if audio and audio.line_started.is_connected(on_line):
		audio.line_started.disconnect(on_line)
	await _leave(main)


## Yolculuğun yer işaretinin merkezi (x, z); yoksa yedek.
func _landmark(main: Node, key: String, fallback: Vector2) -> Vector2:
	for c: Variant in (main.journey.landmarks as Dictionary).get(key, []):
		if c is Vector3:
			return Vector2((c as Vector3).x, (c as Vector3).y)
	return fallback


func _leave(main: Node) -> void:
	var audio := get_node_or_null(^"/root/AudioManager")
	if audio:
		for p in audio.get_children():
			if p is AudioStreamPlayer:
				(p as AudioStreamPlayer).stop()
				(p as AudioStreamPlayer).stream = null
	main.queue_free()
	await get_tree().create_timer(0.25).timeout


func _wait_until(condition: Callable, timeout: float) -> void:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
