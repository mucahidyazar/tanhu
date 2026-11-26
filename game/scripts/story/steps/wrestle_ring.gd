extends PrologueStep
## «Güreş»in adımı (wrestle_ring; Önsöz, 9 Nisan gecesi, Kayın Obası'nın güreş halkası; K110; story.md §3): Börü meydan okur («Kızdan pehlivan olmaz
## dedim.»), obanın bir adamı halkayı açar, kalabalık halka olup izler; Tonga hakemdir: kuralı söyler, öğüt verir, «Tutun!». Kuşak güreşi
## BeltWrestle'dır (scripts/minigames/belt_wrestle.gd; HUD BeltWrestleHud): Börü iter ya da çeker, yönü gövdesinin eğilişiyle ≈0,4 sn önceden
## belli olur; oyuncu karşı yöne basar (WASD, sol çubuk: girişin güreşçilerin eksenine izdüşümü), denge çubuğunu ortada tutar; Börü fazla
## yüklenince ≈0,5 sn'lik pencere açılır, E atar. Denge uca varırsa Çocuk düşer (stand_to_side_lying), Börü «Bir daha!» der, yeniden tutunulur.
## G basılı (1 sn) kuşağı bırakmaktır: vazgeçilir, görev yine biter, söz değişir (Saruk ve Börü; kazanma sözü yok). Kazanınca kalabalık
## coşar, Börü «Ebem haklıymış.», Tonga «Kazanan kartal gibi açar kollarını.» der, Çocuk kollarını açar (yer tutucu: big_wave_hello), Saruk
## «Düşen kalkar, kalkan güler.», Börü «Yarın yine güreşelim.» Kamera K98'in uzak karesinde kalır (22 m, 38°): halkayı yandan gösterir, Çocuk
## solda, Börü sağda; güreş sürerken kamera döndürülmez. Güreşin hareketi kodla yer tutucudur (gövdenin eğilişi; itme ve atma klipleri onayla
## gelir: Push_and_Walk_Forward 261, Grip_and_Throw_Down 389, falling_down 366 — PUSH_CLIP, THROW_CLIP, FALL_CLIP).

## Yer tutucu klipler (kimlikleriyle değiştirilebilir; kütüphanede olanlar): düşüş, kartal, alkış.
const FALL_CLIP := "stand_to_side_lying"
const PUSH_CLIP := ""
const THROW_CLIP := ""
const EAGLE_CLIP := "big_wave_hello"
const RISE_CLIP := "stand_up_3"
## Güreşçilerin merkezden uzaklığı (m), gövdenin en çok eğilişi (derece) ve kalabalığın halkası (m).
const GRIP_GAP := 0.38
const LEAN_DEG := 16.0
const CROWD_R := 4.4
## Vazgeçmenin basılı tutuşu (sn) ve kameranın uzaklığı (m).
const GIVE_UP_S := 1.0
const CAMERA_M := 22.0
## Halkaya girildi sayılan uzaklık (m).
const ENTER_R := 1.7
## İzleyenler: [kimlik, açı (derece), iş].
const WATCHERS := [
	["tonga", 90.0, "talk_hands_open"], ["saruk", 140.0, "stand"], ["mother", 180.0, "stand"], ["father", 205.0, "stand"],
	["older_brother", 230.0, "stand"], ["birch_man", 270.0, "talk_right_hand_open"], ["birch_woman", 315.0, "stand"],
	["birch_elder", 345.0, "stand"], ["birch_girl", 30.0, "stand"], ["kunay", 60.0, "stand"],
]

var sim: BeltWrestle
var hud: BeltWrestleHud

var _center := Vector3.ZERO
var _axis := Vector3(1.0, 0.0, 0.0)
var _focus: Node3D
var _give_hold := 0.0
var _saved_target: Node3D
var _saved_input := true
var _ended := false
var _last_scuffle := -10.0
var _boru: Node3D
var _lean_shown := 0.0
var _child_lean := 0.0
var _bot_t := 0.0


func line_keys() -> Array:
	return ["act0.wrestle.dare", "act0.wrestle.ring", "act0.wrestle.rules", "act0.wrestle.tip", "act0.wrestle.start",
		"act0.wrestle.again", "act0.wrestle.win", "act0.wrestle.eagle", "act0.wrestle.saruk", "act0.wrestle.boru_after"]


func start() -> void:
	_center = point(step.get("ring", "wrestle_ring"))
	phase = "dare"
	_boru = actor("boru")
	var t := say("act0.wrestle.dare")
	at(clock + t + 0.3, func() -> void:
		say("act0.wrestle.ring")
		_gather_crowd())
	# Börü halkanın ortasında bekler.
	_walk("boru", _center + Vector3(GRIP_GAP * 2.0, 0.0, 0.0))
	set_objective({"tr": "Halkaya gir", "en": "Step into the ring"})
	set_hint({"tr": "Börü halkada bekliyor.", "en": "Boru is waiting in the ring."})
	phase = "enter"


func target(_from: Vector3) -> Vector3:
	return _center if phase == "enter" else Vector3.INF


func tick(delta: float) -> void:
	match phase:
		"enter":
			if near(_center, ENTER_R):
				_begin_rules()
		"match":
			_tick_match(delta)


func _begin_rules() -> void:
	phase = "rules"
	set_objective({"tr": "Tonga'yı dinle", "en": "Listen to Tonga"})
	set_hint({})
	_setup_pair()
	E21Shots.shot(player(), "wrestle_ring", 1.5)
	var t := say_seq(["act0.wrestle.rules", "act0.wrestle.tip"])
	at(clock + t + 0.4, func() -> void:
		var g := say("act0.wrestle.start")
		at(clock + maxf(g, 0.6), _begin_match))


func _begin_match() -> void:
	if _ended:
		return
	sim = BeltWrestle.new(int(step.get("seed", 20900409)), step.get("wrestle", {}) as Dictionary)
	sim.start()
	hud = BeltWrestleHud.new()
	hud.lang = SubtitleBar.ui_lang()
	# Perdenin (UI/Fade) altında: kararma HUD'u da örter.
	var ui: Node = days.ui_parent if days and days.ui_parent else world()
	ui.add_child(hud)
	if days and days.fade_rect and days.fade_rect.get_parent() == ui:
		ui.move_child(hud, days.fade_rect.get_index())
	hud.bind(sim)
	phase = "match"
	E21Shots.shot(player(), "wrestle_match", 3.0)
	set_objective({"tr": "Kuşak güreşi", "en": "Belt wrestling"})
	set_hint({"tr": "Börü'nün eğildiği yönün tersine bas; fazla yüklenince E.", "en": "Press against Boru's lean; when he overreaches, E."})


func _tick_match(delta: float) -> void:
	if sim == null or sim.is_over():
		return
	var lean_in := _lean_input()
	var throw := Input.is_action_just_pressed(&"accept")
	if _bot_input.has("lean"):
		lean_in = float(_bot_input["lean"])
		throw = bool(_bot_input.get("throw", false))
	# Kuşağı bırakmak: G basılı.
	if Input.is_action_pressed(&"drop_load") or bool(_bot_input.get("give_up", false)):
		_give_hold += delta
		if _give_hold >= GIVE_UP_S:
			_on_events(sim.give_up())
			return
	else:
		_give_hold = 0.0
	if hud:
		hud.give_up_fill = _give_hold / GIVE_UP_S
	var events := sim.step(delta, lean_in, throw)
	_on_events(events)
	if _ended:
		return
	_pose_pair(delta, lean_in)
	if hud:
		hud.refresh()


var _bot_input: Dictionary = {}


func autoplay(bot: Node, delta: float) -> void:
	match phase:
		"enter":
			bot.call(&"go_to", E21Bot.next_point(days, player().global_position, _center), true)
		"match":
			_bot_t += delta
			_bot_input = BeltWrestle.bot_input(sim, 0.2) if sim else {}
		_:
			bot.call(&"halt")


func _on_events(events: PackedStringArray) -> void:
	for e in events:
		match e:
			"bout":
				if sim.clock - _last_scuffle > 1.2:
					_last_scuffle = sim.clock
					sfx("sfx_wrestle_scuffle", _center)
			"window":
				E21Shots.shot(player(), "wrestle_window")
			"whiff":
				sfx("sfx_wrestle_scuffle", _center)
			"fall":
				E21Shots.shot(player(), "wrestle_fall", 0.9)
				sfx("sfx_child_fall", _center)
				_play(player(), FALL_CLIP)
			"again":
				say("act0.wrestle.again")
			"regrip":
				_play(player(), RISE_CLIP)
			"restart":
				HearthProps.release_player_job(player())
				_setup_pair()
			"won":
				_finish(true)
			"gave_up":
				_finish(false)


func _finish(won: bool) -> void:
	if _ended:
		return
	_ended = true
	E21Shots.log("güreş: %s · deneme %d · düşüş %d · %.1f sn" % ["kazandı" if won else "bıraktı", sim.tries if sim else 0, sim.falls if sim else 0, sim.clock if sim else 0.0])
	phase = "after"
	result("wrestle", "won" if won else "gave_up")
	flag("onsoz_gures", "won" if won else "gave_up")
	_close_hud()
	set_objective({})
	set_hint({})
	var t := 0.4
	if won:
		sfx("sfx_crowd_cheer", _center)
		_cheer_crowd()
		if _boru:
			_play_actor("boru", FALL_CLIP)
		t += say("act0.wrestle.win")
		at(clock + t + 0.3, func() -> void:
			var e := say("act0.wrestle.eagle")
			at(clock + e + 0.2, func() -> void:
				_play(player(), EAGLE_CLIP)
				E21Shots.shot(player(), "wrestle_eagle", 0.8))
			at(clock + e + 2.4, func() -> void:
				var s := say_seq(["act0.wrestle.saruk", "act0.wrestle.boru_after"])
				at(clock + s + 0.8, _end)))
	else:
		t += say_seq(["act0.wrestle.saruk", "act0.wrestle.boru_after"])
		at(clock + t + 0.8, _end)


func _end() -> void:
	_restore_camera()
	_unlean()
	player().set_active(true)
	done()


## Gövdelerin eğilişini sıfırlar (güreşin yer tutucu pozu).
func _unlean() -> void:
	HearthProps.release_player_job(player())
	var pl_av := player().get_avatar() if player() else null
	if pl_av:
		pl_av.rotation.x = 0.0
	var b := actor("boru")
	if b and b.avatar:
		b.avatar.rotation.x = 0.0


func cleanup() -> void:
	_close_hud()
	_restore_camera()
	if is_instance_valid(_focus):
		_focus.queue_free()
	_unlean()
	if is_instance_valid(player()) and not player().is_active():
		player().set_active(true)


## İki çocuğu halkanın ortasına, yüz yüze koyar; kamerayı yandan kadrajlar.
func _setup_pair() -> void:
	var pl := player()
	# Eksen: Çocuk'tan Börü'ye; kamera Çocuk'u solda, Börü'yü sağda gösterecek biçimde döner.
	var from := pl.global_position
	var d := Vector3(_center.x - from.x, 0.0, _center.z - from.z)
	if d.length() < 0.2:
		d = Vector3(1.0, 0.0, 0.0)
	_axis = d.normalized()
	var child_at := _center - _axis * GRIP_GAP
	var boru_at := _center + _axis * GRIP_GAP
	pl.spawn_at(child_at, atan2(_axis.x, _axis.z))
	pl.set_active(false)
	_place_actor("boru", boru_at, child_at)
	_frame_camera()


func _frame_camera() -> void:
	var cam := _follow_camera()
	if cam == null:
		return
	if _focus == null:
		_focus = Node3D.new()
		_focus.name = "WrestleFocus"
		world().add_child(_focus)
	_focus.global_position = _center
	if _saved_target == null:
		_saved_target = cam.target
		_saved_input = cam.input_enabled
	cam.target = _focus
	cam.input_enabled = false
	# Kameranın sağı eksen olsun: Çocuk solda, Börü sağda.
	cam.set_yaw(BeltWrestle.camera_yaw_for_axis(_axis))


func _restore_camera() -> void:
	var cam := _follow_camera()
	if cam == null or _saved_target == null:
		return
	cam.target = _saved_target
	cam.input_enabled = _saved_input
	_saved_target = null


func _close_hud() -> void:
	if is_instance_valid(hud):
		hud.queue_free()
	hud = null


## Oyuncunun eğilişi: hareket girişinin kameraya göre dünyadaki yönü, güreşçilerin eksenine izdüşümü (+: Börü'ye doğru).
func _lean_input() -> float:
	var cam := _follow_camera()
	return BeltWrestle.lean_from_input(InputSetup.move_vector(), cam.get_yaw() if cam else 0.0, _axis)


## Gövdelerin eğilişi (kodla yer tutucu): Börü sim.lean() ile öne ya da arkaya, Çocuk dengenin ve kendi eğilişinin yönünde.
func _pose_pair(delta: float, lean_in: float) -> void:
	_lean_shown = lerpf(_lean_shown, sim.lean(), 1.0 - exp(-10.0 * delta))
	_child_lean = lerpf(_child_lean, clampf(lean_in * 0.6 - sim.balance * 0.5, -1.0, 1.0), 1.0 - exp(-8.0 * delta))
	var pl_av := player().get_avatar()
	if pl_av and sim.phase != BeltWrestle.FALLEN:
		pl_av.rotation.x = deg_to_rad(LEAN_DEG) * _child_lean
	var b := actor("boru")
	if b and b.avatar:
		b.avatar.rotation.x = deg_to_rad(LEAN_DEG) * _lean_shown


func _gather_crowd() -> void:
	for w: Array in WATCHERS:
		var id := str(w[0])
		if actor(id) == null:
			continue
		var a := deg_to_rad(float(w[1]))
		var spot := _center + Vector3(cos(a), 0.0, sin(a)) * CROWD_R
		_walk(id, spot, _center, str(w[2]))


## Kazanınca halkadakiler coşar (birkaç saniye), sonra yine durur.
func _cheer_crowd() -> void:
	for w: Array in WATCHERS:
		var id := str(w[0])
		if id in ["tonga", "saruk", "mother"]:
			continue
		var p := person(id)
		if p and not p.is_walking():
			p.work("cheer")
	at(clock + 3.2, func() -> void:
		for w: Array in WATCHERS:
			var p := person(str(w[0]))
			if p and not p.is_walking():
				p.work("stand"))


func _follow_camera() -> FollowCamera:
	return days.camera if days else null


func _play(pl: PlayerController, clip: String) -> void:
	if clip.is_empty() or pl == null:
		return
	var av := pl.get_avatar()
	if av:
		av.rotation.x = 0.0
	HearthProps.play_player(pl, clip)


func _play_actor(id: String, clip: String) -> void:
	var p := person(id)
	if p:
		p.work(clip)


# --- Kişiler (PrologueCast'in yüzü) -------------------------------------------------------------------

func _walk(id: String, to: Vector3, face_at: Vector3 = Vector3.INF, work: String = "") -> void:
	var p := person(id)
	if p == null:
		return
	p.stop_follow()
	p.walk([to], pace(1.5), work, face_at)


func _place_actor(id: String, at_p: Vector3, face_at: Vector3) -> void:
	var p := person(id)
	if p == null:
		return
	p.stop_follow()
	p.place(at_p, face_at)
