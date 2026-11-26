class_name TallyHome
extends ChildhoodStep
## Dönüş (adım türü tally_home; K110, story.md §5 «İki yeni gün»): Mete çetelesiyle obadan çıkar; köpekler yatağındadır. Ebe Obası'ndan
## cut_after_m uzaklaşınca yol kısalır (kısa kararma; aynı yolun dönüşü yinelenmez, saat öğleye doğru ilerler): Mete Lan Hatun'un yurdunun
## yakınındadır. Lan Hatun çeteleyi görür («Getirdin mi? Yedi. Sayıcı sevinir.»), Hereka'yı sorar; Mete «Beni o saymış.» der; Lan Hatun
## «Öyle. Kapıda onun sesi vardı.». Sonra öğleden akşama kararmayla atlanır (saat evening'e; uyku adımı: yurtta yatağa E).
## Veri: from (obanın ortası), cut_after_m, arrive [x, z], arrive_yaw_deg, arrive_clock (hh:mm), meet (Lan Hatun'un yeri), near (m),
## lines {home, ask, answer, reply}, evening (hh:mm), fade_s, objectives {home}.

const KEEPER := "lan_hatun"

var _camp: TallyCamp
var _left := 0.0
var _cut := false
var _busy := false


func start() -> void:
	phase = "walk"
	_camp = TallyCamp.of(scene, false)
	if _camp:
		_camp.end_diorama()


func tick(delta: float) -> void:
	var p := player()
	if _camp and phase == "walk":
		_camp.tick(delta, p.global_position, p.get_speed())
	match phase:
		"walk":
			var from := point(step.get("from", "ebe_center"))
			if not _cut and float(step.get("cut_after_m", 0.0)) > 0.0 and from != Vector3.INF and flat(p.global_position, from) >= float(step.get("cut_after_m", 0.0)):
				_cut_home()
			elif near(point(step.get("meet", "lan_stand")), float(step.get("near", 6.0))) and not _busy:
				_meet()
		"talk":
			BoneView.shoot(scene, "e21_tally_home")
			_left -= delta
			if _left <= 0.0 and (scene.voice == null or scene.voice.is_free()):
				_evening()
		"evening":
			pass


func target(_from: Vector3) -> Vector3:
	return point(step.get("meet", "lan_stand")) if phase == "walk" else Vector3.INF


func preset() -> void:
	TallyErrand.hand_curd(scene.inventory)
	TallyErrand.take_stick(scene.inventory)
	if player():
		player().spawn_at(point(step.get("meet", "lan_stand")) + Vector3(2.0, 0.0, 1.0), -PI * 0.5)


func autoplay(bot: Node, _delta: float) -> void:
	BoneView.diag_step(self)
	if phase != "walk" or _busy:
		bot.call(&"halt")
		return
	# Yol kısaldıysa yalnız Lan Hatun'a; kısalmadıysa kuruyan dere boyunca.
	if _cut:
		bot.call(&"follow", [point(step.get("meet", "lan_stand"))], "tally_home_near", true)
	else:
		bot.call(&"follow", points(step.get("route", ["dry_stream_north", "dry_stream_south", "lan_stand"])), "tally_home_far", true)


static func check(p_step: Dictionary, data: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	var lines: Dictionary = data.get("lines", {})
	for key: String in ["home", "ask", "answer", "reply"]:
		var line := str((p_step.get("lines", {}) as Dictionary).get(key, ""))
		if not lines.has(line):
			out.append("%s: satır yok: %s" % [p_step.get("id", ""), key])
	return out


func line_keys() -> Array:
	return (step.get("lines", {}) as Dictionary).values()


## Yol kısalır: kısa kararma, Mete evin yakınında, saat öğleye doğru.
func _cut_home() -> void:
	_cut = true
	_busy = true
	var fade := float(step.get("cut_fade_s", 0.7))
	player().set_active(false)
	var t := scene.screen_fade_to(1.0, fade)
	t.tween_callback(func() -> void:
		var at := point(step.get("arrive", "lan_stand"))
		player().spawn_at(at, deg_to_rad(float(step.get("arrive_yaw_deg", 180.0))))
		if scene.camera:
			scene.camera.set_yaw(player().get_facing_yaw() + PI, true)
			scene.camera.snap_to_target()
		var when := GameClock.parse_hhmm(step.get("arrive_clock", ""))
		if when >= 0.0 and scene.game_clock and when > scene.game_clock.minute:
			scene.game_clock.skip_to(scene.game_clock.day_n, when, &"travel")
		if _camp:
			_camp.visible = false
			_camp.process_mode = Node.PROCESS_MODE_DISABLED)
	t.tween_interval(0.25)
	t.tween_property(scene.screen_fade, ^"color:a", 0.0, fade)
	t.tween_callback(func() -> void:
		_busy = false
		if scene.is_running():
			player().set_active(true))


## Lan Hatun karşılar: çeteleyi görür, Hereka'yı sorar.
func _meet() -> void:
	phase = "talk"
	_busy = true
	set_objective({})
	set_hint({})
	var keeper := mover(str(step.get("keeper", KEEPER)))
	if keeper:
		keeper.face(player().global_position)
	var lines: Dictionary = step.get("lines", {})
	say(str(lines.get("home", "home")))
	say(str(lines.get("ask", "lan_ask")))
	say(str(lines.get("answer", "mete_answer")))
	_left = say(str(lines.get("reply", "lan_answer"))) + 0.4


## Öğleden akşama kararmayla atlanır: perde kararır, saat akşama, perde açılır; adım biter (uyku).
func _evening() -> void:
	phase = "evening"
	var fade := float(step.get("fade_s", 1.2))
	player().set_active(false)
	var t := scene.screen_fade_to(1.0, fade)
	t.tween_callback(func() -> void:
		var when := GameClock.parse_hhmm(step.get("evening", "19:40"))
		if when >= 0.0 and scene.game_clock and when > scene.game_clock.minute:
			scene.game_clock.skip_to(scene.game_clock.day_n, when, &"wait")
		# Akşam: çocuk yurdun kapısının önünde, kapıya dönük (yatmaya girecek; kapı aralığı dardır, eksenin üstünde durur).
		var door := point(step.get("evening_at", "lan_door"))
		var off: Array = step.get("evening_offset", [1.8, 0.0])
		if door != Vector3.INF and player():
			player().spawn_at(point([door.x + float(off[0]), door.z + float(off[1])]), deg_to_rad(float(step.get("evening_yaw_deg", -90.0))))
			if scene.camera:
				scene.camera.snap_to_target())
	t.tween_interval(float(step.get("hold_s", 0.9)))
	t.tween_property(scene.screen_fade, ^"color:a", 0.0, fade)
	t.tween_callback(func() -> void:
		if scene.is_running():
			player().set_active(true)
		done())
