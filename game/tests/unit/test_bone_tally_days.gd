extends TestCase
## «Ak Kemik» ve «Ebenin Çetelesi» ana sahnede (Yeni Oyun'un Çocukluk aşaması, günlerin sırası; K110, story.md §5 «İki yeni gün»):
##   - Ak Kemik: obanın akşamı kurulur (direk, kemik, ufuktaki ateşler), Yançi çağırır, Luhun kuralı söyler, üç el oynanır (bot: ChildhoodStep
##     autoplay'inin yüzü: follow, halt, interact, hold), çocuklar oyuncunun koşusunu aşmaz, kemik her elde 25–45 m öteye ve başka
##     yere düşer; bitişte uyku adımı gelir.
##   - Ebenin Çetelesi: kurut torbası heybeye girer, köpekler yolu keser (bot durur ve seslenir), Hereka köpekleri tutar, içeride kurut düşer,
##     çetele heybeye girer, obanın üç kişisi haber alır, dönüşte Lan Hatun karşılar; gün uykuyla biter.
##   - Sayım günü: çetele heybedeyse sayıcı «Bir çocuk.»tan önce «Hereka'nın çentikleri. Yedi.» der ve çetele düşer; yoksa sıra bugünkü gibi.

const MAIN_SCENE := "res://scenes/main.tscn"
const ORDOS := "res://scenes/maps/childhood_ordos.tscn"
const DAYS := "res://data/story/childhood_days.json"
const TempDir := preload("res://tests/support/temp_dir.gd")

var _dir := ""
var _warm: Array = []


func before_each() -> void:
	MenuStyle.muted = true
	Engine.time_scale = 1.0
	CineVideo.enabled = false
	_dir = TempDir.fresh("e21_bone_tally")


func after_each() -> void:
	Engine.time_scale = 1.0
	CineVideo.enabled = true
	get_tree().paused = false
	TempDir.wipe(_dir)


func test_bone_day_plays_three_hands_and_ends_in_sleep() -> void:
	var main := await _start_main("day1_bone", "")
	var scene: ChildhoodScene = main._childhood_scene
	assert_not_null(scene, "Ak Kemik'in sahnesi")
	if scene == null:
		await _free_main(main)
		return
	assert_eq(scene.day_id, "day1_bone")
	var bot := _bot(main, scene)
	var probe := PaceLimit.Probe.new()
	var started := scene.clock
	Engine.time_scale = 4.0
	var landings := PackedVector2Array()
	var winners := PackedStringArray()
	var post := Vector2.ZERO
	var deadline := Time.get_ticks_msec() + 150000
	while Time.get_ticks_msec() < deadline and is_instance_valid(scene) and scene.is_running() and scene.current_step_id() != "bone_sleep":
		for id: String in ["yanchi_child", "luhun_child"]:
			var m: StoryMover = scene.movers.get(id)
			if m:
				probe.sample(id, m.position(), scene.clock)
		var h := scene.step_handler()
		if h is BonePlay:
			landings = (h as BonePlay).rules.landings
			post = (h as BonePlay).rules.post
			winners = (h as BonePlay).rules.winners
		await get_tree().process_frame
	Engine.time_scale = 1.0
	var seconds := scene.clock - started if is_instance_valid(scene) else -1.0
	print("[e21] Ak Kemik: %.1f sn (oyun), %s" % [seconds, probe.report(PaceLimit.run_cap(main.player))])
	assert_eq(scene.current_step_id(), "bone_sleep", "Üç el biter, uyku gelir (%.0f sn)" % seconds)
	for key in ["call", "moon", "lan_watch", "rules"]:
		assert_true(scene.said_lines.has(key), "Söz: %s" % key)
	assert_true(scene.said_lines.has("throw"), "Luhun atar")
	assert_true(scene.said_lines.has("mete_won") or scene.said_lines.has("other_won") or scene.said_lines.has("again"), "Direğe varan")
	assert_eq(landings.size(), 3, "Üç atış")
	# Yançi bir el kazandıysa kendi sözü («İlk ben vardım! Ben!»), son el değilse ardından «Bir el daha!».
	if winners.has("yanchi_child"):
		assert_true(scene.said_lines.has("yanchi_won"), "Yançi'nin kazandığı elin sözü")
		var i_won := scene.said_lines.find("yanchi_won")
		var i_again := scene.said_lines.find("again")
		assert_true(i_again < 0 or i_won < i_again, "Önce yanchi_won, sonra again")
	for i in landings.size():
		assert_between(landings[i].distance_to(post), 24.9, 47.0, "Atış %d: 25–45 m (%.1f)" % [i + 1, landings[i].distance_to(post)])
		for j in i:
			assert_true(landings[i].distance_to(landings[j]) > 8.0, "Her elde başka yere")
	assert_true(probe.over(PaceLimit.run_cap(main.player)).is_empty(), "Çocuklar oyuncunun koşusunu aşmaz: %s" % probe.report(PaceLimit.run_cap(main.player)))
	assert_true(BonePlay.view_of(scene) != null and BonePlay.view_of(scene).fire_count() >= 6, "Ufukta Dailin'in ateşleri")
	# Uyku: bot yurda girer, yatar; sıradaki gün (21 Eylül) açılır.
	var next := await _next_day(main, "day1_bone")
	assert_eq(next, "day2_tally", "Uykudan sonra 21 Eylül açılır")
	# Ertesi günün obası ertesi günün kökündedir (önceki günün kökü silinmeyi beklerken yeni kök başka ad alır: «Story2»).
	await wait_frames(30)
	var s2: Variant = main.get(&"_childhood_scene")
	if is_instance_valid(s2):
		var camp := TallyCamp.of(s2 as ChildhoodScene, true)
		assert_not_null(camp, "Ebe Obası kurulur")
		if camp:
			camp.build_all()
			assert_true(camp.get_parent() == BoneView.story_root(s2 as ChildhoodScene) and not camp.is_queued_for_deletion(), "Oba yeni günün kökünde")
			assert_not_null(camp.dogs, "Köpekler kuruldu")
	bot.queue_free()
	await _free_main(main)


func test_tally_morning_curd_walk_and_dog_manners() -> void:
	var main := await _start_main("day2_tally", "")
	var scene: ChildhoodScene = main._childhood_scene
	assert_not_null(scene, "Çetele'nin sahnesi")
	if scene == null:
		await _free_main(main)
		return
	var inv: Inventory = main.gameplay_hud.bag.inventory
	assert_true(scene.inventory == inv, "Heybe sahnenin de heybesi")
	var bot := _bot(main, scene)
	var run := await _run_until(main, scene, "tally_visit", 165.0)
	var camp := TallyCamp.of(scene)
	print("[e21] Ebenin Çetelesi (sabah → köpekler): %.1f sn (oyun)" % run["seconds"])
	assert_eq(scene.current_step_id(), "tally_visit", "Köpekler tutulunca ziyaret başlar")
	assert_true(bool(run["curd"]), "Kurut torbası heybeye girdi")
	assert_true(TallyErrand.has_curd(inv), "Kurut yolda heybede")
	assert_true(bool(run["blocked"]), "Köpekler yolu kesti")
	assert_true(float(run["closest"]) >= TallyDogs.MIN_GAP - 0.05, "Köpekler değmedi (%.2f m)" % run["closest"])
	assert_true(camp != null and camp.dogs.state == TallyDogs.State.HELD, "Hereka köpekleri tuttu")
	assert_eq(camp.people.size(), 5, "Obanın kişileri (üç yetişkin, iki çocuk)")
	for key in ["errand", "why", "news_task", "dogs", "dogs_held"]:
		assert_true(scene.said_lines.has(key), "Söz: %s" % key)
	assert_true(scene.said_lines.find("dogs") < scene.said_lines.find("dogs_held"), "Önce seslenilir, sonra tutulur")
	bot.queue_free()
	await _free_main(main)


func test_tally_visit_news_and_home() -> void:
	var main := await _start_main("day2_tally", "tally_visit")
	var scene: ChildhoodScene = main._childhood_scene
	assert_not_null(scene, "Çetele'nin sahnesi (ziyaretten)")
	if scene == null:
		await _free_main(main)
		return
	var inv: Inventory = main.gameplay_hud.bag.inventory
	assert_true(TallyErrand.has_curd(inv), "Atlanan sabah kurudu verdi")
	var bot := _bot(main, scene)
	var run := await _run_until(main, scene, "tally_sleep", 165.0)
	print("[e21] Ebenin Çetelesi (ziyaret → dönüş): %.1f sn (oyun)" % run["seconds"])
	assert_eq(scene.current_step_id(), "tally_sleep", "Görev uykuya dek akar")
	assert_false(TallyErrand.has_curd(inv), "Kurut Hereka'ya verildi")
	assert_true(TallyErrand.has_stick(inv), "Çetele heybede")
	var camp := TallyCamp.of(scene)
	assert_eq(camp.told_count(), 3, "Obanın üç kişisi haber aldı")
	for key in ["name", "give", "counted", "inside", "moon", "stick", "news", "reply_1", "reply_2", "reply_3", "bye", "home", "lan_ask", "mete_answer",
			"lan_answer"]:
		assert_true(scene.said_lines.has(key), "Söz: %s" % key)
	assert_true(scene.said_lines.find("name") < scene.said_lines.find("give") and scene.said_lines.find("give") < scene.said_lines.find("counted"),
		"Mete kurutu Hereka'nın «Bilirim.»inden önce verir (teşekkür)")
	assert_true(scene.said_lines.find("stick") < scene.said_lines.find("news"), "Önce çetele, sonra haber")
	assert_true(scene.minute() >= GameClock.parse_hhmm("19:00"), "Öğleden akşama atlandı (%s)" % scene.clock_text())
	bot.queue_free()
	await _free_main(main)


func test_tally_sleep_opens_the_count_day_with_the_stick() -> void:
	var main := await _start_main("day2_tally", "tally_sleep")
	var scene: ChildhoodScene = main._childhood_scene
	if scene == null:
		fail("Çetele'nin uykusu")
		await _free_main(main)
		return
	var inv: Inventory = main.gameplay_hud.bag.inventory
	assert_true(TallyErrand.has_stick(inv), "Atlanan adımlar çeteleyi verdi")
	var bot := _bot(main, scene)
	# Uyku: sıradaki gün sayım günüdür; çetele heybede kalır.
	var next := await _next_day(main, "day2_tally")
	assert_eq(next, "count", "Uykudan sonra 22 Eylül (sayım günü) açılır")
	assert_true(TallyErrand.has_stick(inv), "Çetele sayım gününe taşındı")
	bot.queue_free()
	await _free_main(main)


func test_count_day_hands_over_the_stick_only_when_carried() -> void:
	for carried in [true, false]:
		var main := await _start_main("count", "count")
		var scene: ChildhoodScene = main._childhood_scene
		if scene == null:
			fail("Sayım gününün sahnesi")
			await _free_main(main)
			return
		var inv: Inventory = main.gameplay_hud.bag.inventory
		if carried:
			TallyErrand.take_stick(inv)
		var bot := _bot(main, scene)
		bot.goal = scene.point("children_at_line")
		Engine.time_scale = 4.0
		await _wait_until(func() -> bool: return scene.said_lines.has("count_answer") or not scene.is_running(), 80.0)
		Engine.time_scale = 1.0
		var lines := scene.said_lines
		if carried:
			assert_true(lines.has("count_stick"), "Çetele varken sayıcı çentikleri sayar")
			assert_true(lines.find("count_stick") < lines.find("count_child"), "«Bir çocuk.»tan önce")
			assert_false(TallyErrand.has_stick(inv), "Çetele sayıcıya geçti")
		else:
			assert_false(lines.has("count_stick"), "Çetele yoksa söz yok")
			assert_true(lines.has("count_child"), "Sıra bugünkü gibi")
		bot.queue_free()
		await _free_main(main)


# --- Yardımcılar -----------------------------------------------------------------------------------------------

func _start_main(day: String, step: String) -> Node:
	if _warm.is_empty():
		_warm.append(load(ORDOS))
	var main = load(MAIN_SCENE).instantiate()
	main.quit_handler = func() -> void: pass
	main.saves = SaveSystem.new(_dir)
	main.prologue_path = ""
	var flow: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/new_game.json"))
	for s: Dictionary in flow.get("stages", []):
		if str(s.get("id", "")) == "childhood" and not s.has("days"):
			s["days"] = DAYS
	main.new_game_data = flow
	main.new_game_only = PackedStringArray(["childhood"])
	add_child(main)
	await wait_frames(3)
	main.menu.finish_intro()
	await wait_frames(1)
	main.new_game_from = "childhood"
	main.childhood_day = day
	main.childhood_step = step
	main.menu.start_requested.emit()
	await _wait_until(func() -> bool: return main.state == main.State.PLAYING and main._childhood_scene != null, 90.0)
	return main


## Bot sahneyi until adımına dek oynar (en çok limit gerçek sn): {seconds (oyun), curd, blocked, closest}.
func _run_until(main: Node, scene: ChildhoodScene, until: String, limit: float) -> Dictionary:
	var started := scene.clock
	var inv: Inventory = main.gameplay_hud.bag.inventory
	var out := {"curd": false, "blocked": false, "closest": INF}
	Engine.time_scale = 4.0
	var deadline := Time.get_ticks_msec() + int(limit * 1000.0)
	var log_at := 0
	while Time.get_ticks_msec() < deadline and is_instance_valid(scene) and scene.is_running() and scene.current_step_id() != until:
		if Time.get_ticks_msec() >= log_at:
			log_at = Time.get_ticks_msec() + 6000
			print("[e21] %.1f sn · %s/%s · oyuncu %s · %s" % [scene.clock, scene.current_step_id(), scene.current_phase(),
				main.player.global_position.snapped(Vector3.ONE * 0.1), scene.clock_text()])
		out["curd"] = bool(out["curd"]) or TallyErrand.has_curd(inv)
		var camp := TallyCamp.of(scene)
		if camp and camp.dogs:
			out["blocked"] = bool(out["blocked"]) or camp.dogs.blocks()
			out["closest"] = minf(float(out["closest"]), camp.dogs.closest)
		await get_tree().process_frame
	Engine.time_scale = 1.0
	out["seconds"] = scene.clock - started
	return out


## Uyku adımının sonuna dek bekler (bot yurda girer, yatar); döner: açılan günün kimliği ("" açılmadıysa).
func _next_day(main: Node, from_day: String) -> String:
	Engine.time_scale = 3.0
	var deadline := Time.get_ticks_msec() + 60000
	var found := ""
	while Time.get_ticks_msec() < deadline:
		var s: Variant = main.get(&"_childhood_scene")
		if is_instance_valid(s) and str((s as ChildhoodScene).day_id) != from_day:
			found = str((s as ChildhoodScene).day_id)
			break
		await get_tree().process_frame
	Engine.time_scale = 1.0
	return found


func _bot(main: Node, scene: ChildhoodScene) -> StepBot:
	var bot := StepBot.new()
	bot.scene = scene
	bot.player = main.player
	add_child(bot)
	return bot


func _free_main(main: Node) -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	# Sahne ağaçtayken durur (ChildhoodAtmos sesini ağaçta söndürür).
	if is_instance_valid(main._childhood_scene):
		main._childhood_scene.stop()
	await wait_frames(1)
	main.get_viewport().disable_3d = false
	main.queue_free()
	var audio := get_node_or_null(^"/root/AudioManager")
	if audio:
		for p in audio.get_children():
			if p is AudioStreamPlayer:
				(p as AudioStreamPlayer).stop()
				(p as AudioStreamPlayer).stream = null
	await get_tree().create_timer(0.3).timeout


func _wait_until(condition: Callable, timeout: float) -> void:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame


## Adımların autoplay yüzü (ChildhoodAutoplay'inki gibi): follow(points, key, run, reach) -> bool, halt(), interact(), hold(açık). Kayıtlı
## tür yoksa (sayım günü) goal'e yürür.
class StepBot:
	extends Node

	var scene: ChildhoodScene
	var player: PlayerController
	var goal := Vector3.INF
	var _route: Array = []
	var _key := ""
	var _stuck_t := 0.0
	var _stuck_from := Vector3.INF
	var _side_t := 0.0
	var _side := Vector2.ZERO

	func _process(delta: float) -> void:
		if not is_instance_valid(scene) or not scene.is_running() or not is_instance_valid(player):
			return
		var h := scene.step_handler()
		if h:
			h.autoplay(self, delta)
		elif goal != Vector3.INF:
			follow([goal], "goal", true, 1.2)

	func follow(points: Array, key: String, run: bool, reach: float = 0.6) -> bool:
		if key != _key:
			_key = key
			_route = []
			for p: Variant in points:
				var at := scene.point(p) if not p is Vector3 else p as Vector3
				if at != Vector3.INF:
					_route.append(at)
			_stuck_t = 0.0
			_stuck_from = player.global_position
		while _route.size() > 1 and _flat(player.global_position, _route[0]) <= maxf(reach, 1.0):
			_route.remove_at(0)
		if _route.is_empty() or (_route.size() == 1 and _flat(player.global_position, _route[0]) <= reach):
			halt()
			return true
		var to: Vector3 = _route[0]
		var dir := Vector2(to.x - player.global_position.x, to.z - player.global_position.z).normalized()
		if _side_t > 0.0:
			_side_t -= get_process_delta_time()
			dir = _side
		_steer(dir, run)
		_stuck_t += get_process_delta_time()
		if _stuck_t >= 1.4:
			if _flat(player.global_position, _stuck_from) < 0.3:
				_side = Vector2(-dir.y, dir.x) * (1.0 if randf() < 0.5 else -1.0)
				_side_t = 0.7
			_stuck_t = 0.0
			_stuck_from = player.global_position
		return false

	func halt() -> void:
		player.auto_move = Vector2.ZERO
		player.auto_sprint = false

	func interact() -> bool:
		return player.interact()

	func hold(on: bool) -> void:
		scene.auto_hold = on

	func _steer(dir: Vector2, run: bool) -> void:
		var cy := player.camera_yaw()
		var forward := Vector2(-sin(cy), -cos(cy))
		var right := Vector2(cos(cy), -sin(cy))
		player.auto_move = Vector2(dir.dot(right), dir.dot(forward)).limit_length(1.0)
		player.auto_sprint = run

	static func _flat(a: Vector3, b: Vector3) -> float:
		return Vector2(a.x - b.x, a.z - b.z).length()
