class_name BonePlay
extends ChildhoodStep
## «Ak Kemik» oyunu (adım türü bone_play; Çocukluk, 20 Eylül MÖ 228 akşamı; K110, story.md §5 «İki yeni gün»; Kazakların «aksüyek»i): üç el.
## Atan (ilk elde Luhun, sonra son elin kazananı) kemiği bağlama direğinin önünden karanlık çayıra fırlatır (25–45 m, her elde başka yer);
## üç çocuk arar, kemik ay ışığında yakında ışıldar (BoneView); bulan direğe koşar, ötekiler kovalar; 1 m'ye yaklaşan yakalar ve kemiği
## alır, yakalanan 2 sn durur (soluklanır). Direğe varan eli kazanır. Oyuncu kazanırsa sonraki eli kendisi atar: direğin yanında E'yi basılı
## tutar (atış uzar, düşeceği yerde halka), bırakınca kemik uçar. Kurallar BoneRules'ta, çocukların aklı BoneBrain'dedir: arama, kovalama,
## kaçma; hızları oyuncunun koşusunu aşmaz (K105), kovalanan çocuk 2 sn'de bir kısa duraksar. Ceza yoktur: oyuncu hep yenilse de üç elde
## biter. Sözler olaylara bağlıdır (bulan, yakalanan, kazanan; Luhun'un takılması, Yançi'nin soluğu), gülüşme ve soluk sesleri
## (sfx_kids_laugh, sfx_child_pant), kemiğin düşüşü (sfx_bone_land), direğe vuruş (sfx_post_slap) ChildhoodAtmos'tan.
## Bitişte çocuklar soluklanır, saat görünür biçimde ilerler (ay yükselir), adım biter: uyku (sleep, Lan Hatun'un «Ay yükseldi.»si).
## Evreler (phase): throw (çocuk atar), aim (oyuncu atar), search, carry, won, end.

const VIEW_NAME := "BoneGame"
const KIDS: Array[String] = ["yanchi_child", "luhun_child"]
## Çocuğun ivmesi (m/sn²), dönüşünün keskinliği, oyuncudan ayrılığı (m).
const ACCEL := 9.0
const TURN := 10.0
const PLAYER_GAP := 0.65
## El arası: kazananın sevinci (sn), çocuk atanın direkte bekleyişi, kolunu kaldırışı (sn).
const WON_HOLD := 2.4
const THROW_PREP := 1.3
const THROW_WIND := 0.6
## Uçuş: taban süre ve metre başına (sn).
const FLIGHT_BASE := 0.95
const FLIGHT_PER_M := 0.022
## Oyuncunun atışı direğe bu kadar yakından olur (m); atılan kemik elden bu yükseklikte kalkar (m).
const PLAYER_POST := 4.5
const HAND_UP := 0.85
## Ses: koşan çocuğun solu (sn aralığı), kovalamacada gülüşme (sn aralığı); aynı sözün en kısa arası (sn).
const PANT_EVERY := Vector2(2.4, 3.8)
const LAUGH_EVERY := Vector2(6.0, 10.0)
const LINE_COOLDOWN := 7.0
## Luhun'un takılması («Yaşlı koyundan da yavaşsın!»): Mete'nin bu kadar yakınındayken (m), en çok TEASE_MAX kez, aralarında TEASE_GAP sn.
const TEASE_NEAR := 9.0
const TEASE_MAX := 2
const TEASE_GAP := 40.0
## Bitiş: soluklanma (sn) ve saatin görünür akışı.
const END_HOLD := 5.5

var rules: BoneRules
var brain: BoneBrain
var view: BoneView
## Ellerin süreleri (sn; bot günlüğü ve sınama).
var hand_times := PackedFloat32Array()
var cap := PaceLimit.CHILD_RUN

var _rng := RandomNumberGenerator.new()
var _pos: Dictionary = {}
var _vel: Dictionary = {}
var _yaw: Dictionary = {}
var _gesture: Dictionary = {}
var _pant: Dictionary = {}
var _laugh_left := 8.0
var _phase_t := 0.0
var _hand_t := 0.0
var _thrown := false
var _winding := false
var _charging := false
var _hold_s := 0.0
var _aim_at := Vector3.INF
var _player_frozen := false
var _said_at: Dictionary = {}
var _teases := 0
var _tease_at := -INF
var _won_left := 0.0
var _end_left := 0.0
var _obstacles: Array = []
var _tweens: Array[Tween] = []
var _bot_hold_left := 0.0


## Sahnenin kemik görünüşü (Story düğümünün altında; create ise yoksa kurulur). Gün bitince sahneyle gider.
static func view_of(p_scene: ChildhoodScene, create: bool = false) -> BoneView:
	if p_scene == null or p_scene.world == null:
		return null
	var root := BoneView.story_root(p_scene)
	if root == null:
		return null
	var v := root.get_node_or_null(NodePath(VIEW_NAME)) as BoneView
	if v == null and create:
		v = BoneView.new()
		v.name = VIEW_NAME
		root.add_child(v)
		var post_at := p_scene.point("bone_post")
		v.build(p_scene.world.call(&"get_terrain_shape") if p_scene.world.has_method(&"get_terrain_shape") else null, post_at)
	return v


func start() -> void:
	cap = pace(PaceLimit.CHILD_RUN) if player() == null else PaceLimit.run_cap(player())
	view = view_of(scene, true)
	var post := _flat(point(step.get("post", "bone_post")))
	rules = BoneRules.new(PackedStringArray([BoneRules.PLAYER] + KIDS), post, str(step.get("first_thrower", "luhun_child")))
	rules.hands = int(step.get("hands", BoneRules.HANDS))
	brain = BoneBrain.new(cap, step.get("traits", {}))
	var spots: Dictionary = step.get("spots", {})
	for id: String in spots:
		brain.spots[id] = _flat(point(spots[id]))
	_obstacles = _collect_obstacles()
	for id in KIDS:
		var m := mover(id)
		hold(id, true)
		_pos[id] = _flat(m.position()) if m else post
		_vel[id] = Vector2.ZERO
		_yaw[id] = m.heading() if m else 0.0
		_pant[id] = _rng.randf_range(PANT_EVERY.x, PANT_EVERY.y)
	_rng.seed = int(step.get("seed", 2209))
	rules.begin_hand()
	_enter_throw()


func tick(delta: float) -> void:
	_phase_t += delta
	_hand_t += delta
	var positions := _positions()
	if rules.phase in [BoneRules.Phase.SEARCH, BoneRules.Phase.CARRY]:
		brain.tick(delta)
		rules.step(delta, positions)
		_handle_events()
	for id in KIDS:
		_drive_kid(id, delta, positions)
	_tick_player_freeze()
	_tick_bone()
	view.tick(delta, player().global_position)
	_tick_voice(delta)
	_tick_shots()
	match phase:
		"throw":
			_tick_throw()
		"aim":
			_tick_aim(delta)
		"won":
			_won_left -= delta
			if _won_left <= 0.0 and (scene.voice == null or scene.voice.is_free()):
				_after_win()
		"end":
			_end_left -= delta
			if _end_left <= 0.0:
				done()


## HUD'un yönü: atışta ve aramada çayır (yakına varınca yok: kemik aranır), taşırken direk, kovalarken taşıyan.
func target(from: Vector3) -> Vector3:
	match phase:
		"aim":
			return point(step.get("post", "bone_post")) if not _near_post() else Vector3.INF
		"search", "throw":
			var field := point(step.get("field", "bone_field"))
			return field if flat(from, field) > float(step.get("field_hint_m", 16.0)) else Vector3.INF
		"carry":
			if rules.carrier == BoneRules.PLAYER:
				return point(step.get("post", "bone_post"))
			return _to3(_pos.get(rules.carrier, rules.bone))
	return Vector3.INF


## İnceleme kareleri (geliştirme; --e21-shots): ay ışığında arama, kovalamaca, direğe varış, bitiş.
func _tick_shots() -> void:
	match phase:
		"search":
			if _phase_t > 2.5 and _player_flat().distance_to(rules.bone) < 14.0:
				BoneView.shoot(scene, "e21_bone_search")
		"carry":
			if rules.carrier != BoneRules.PLAYER and _player_flat().distance_to(_pos.get(rules.carrier, rules.bone)) < 6.0:
				BoneView.shoot(scene, "e21_bone_chase")
			elif rules.carrier == BoneRules.PLAYER and _phase_t > 1.5:
				BoneView.shoot(scene, "e21_bone_run")
		"won":
			if WON_HOLD - _won_left > 0.35:
				BoneView.shoot(scene, "e21_bone_post")
		"end":
			if float(step.get("end_hold", END_HOLD)) - _end_left > 2.0:
				BoneView.shoot(scene, "e21_bone_end")


## Oyuncunun E'si: kazandığı elden sonra direğin yanında atış (basılı tut, bırak).
func interaction() -> Dictionary:
	if phase != "aim":
		return {}
	var labels: Dictionary = step.get("labels", {})
	if _charging:
		return {"key": "E", "label": text(labels.get("release", {"tr": "Bırak: at", "en": "Release: throw"})), "run": func() -> void: pass}
	if not _near_post():
		return {}
	return {"key": "E", "label": text(labels.get("hold", {"tr": "Basılı tut: at", "en": "Hold: throw"})), "run": _begin_charge}


func preset() -> void:
	var spots: Dictionary = step.get("spots", {})
	for id: String in spots:
		var m := mover(id)
		if m:
			m.place(point(spots[id]), 0.0)
	var v := view_of(scene, true)
	if v:
		v.hide_bone()


func cleanup() -> void:
	for t in _tweens:
		if t and t.is_valid():
			t.kill()
	_tweens.clear()
	if view and is_instance_valid(view):
		view.show_aim(Vector3.INF, false)
		view.hide_bone()
		if view.landed.is_connected(_on_landed):
			view.landed.disconnect(_on_landed)
	if _player_frozen and player():
		player().set_active(true)
	_player_frozen = false
	if scene and scene.auto_hold:
		scene.auto_hold = false
	var home: Dictionary = step.get("home", {})
	for id in KIDS:
		var a := actor(id)
		if a and a.avatar:
			a.avatar.set_locomotion(0.0)
		hold(id, false)
		var m := mover(id)
		if m and home.has(id):
			m.go([point(home[id])], pace(1.3))


func autoplay(bot: Node, delta: float) -> void:
	BoneView.diag_step(self)
	if rules == null or rules.is_frozen(BoneRules.PLAYER):
		bot.call(&"halt")
		return
	var post := point(step.get("post", "bone_post"))
	match phase:
		"aim":
			if not _near_post():
				bot.call(&"follow", [post], "bone_aim", true)
				return
			bot.call(&"halt")
			if not _charging and scene.camera:
				# Atış kameranın baktığı yöne: çayıra dön, E'ye bas ve bir süre basılı tut (bot.hold), sonra bırak.
				var to := _flat(point(step.get("field", "bone_field"))) - _flat(player().global_position)
				scene.camera.set_yaw(atan2(-to.x, -to.y), true)
				bot.call(&"interact")
				bot.call(&"hold", true)
				_bot_hold_left = float(step.get("bot_hold_s", 0.9))
			elif _charging:
				_bot_hold_left -= delta
				if _bot_hold_left <= 0.0:
					bot.call(&"hold", false)
		"search":
			bot.call(&"follow", [_to3(rules.bone)], "bone_search_%d" % rules.hand, true)
		"carry":
			if rules.carrier == BoneRules.PLAYER:
				bot.call(&"follow", [post], "bone_carry_%d" % rules.hand, true)
			else:
				# Kovalanan yürür: anahtar onun yeriyle değişir (bot yolu yeniler).
				var at: Vector2 = _pos.get(rules.carrier, rules.bone)
				bot.call(&"follow", [_to3(at)], "bone_chase_%s_%d_%d" % [rules.carrier, roundi(at.x), roundi(at.y)], true)
		_:
			bot.call(&"halt")


static func check(p_step: Dictionary, data: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	var lines: Dictionary = data.get("lines", {})
	var sid := str(p_step.get("id", ""))
	for key in _line_list(p_step):
		if not lines.has(key):
			out.append("%s: satır yok: %s" % [sid, key])
	for key: String in ["post", "field"]:
		if not p_step.has(key):
			out.append("%s: %s gerekli" % [sid, key])
	var actors: Dictionary = data.get("actors", {})
	for id in KIDS:
		if not actors.has(id):
			out.append("%s: kişi yok: %s" % [sid, id])
	return out


func line_keys() -> Array:
	return _line_list(step)


static func _line_list(p_step: Dictionary) -> Array:
	var out: Array = []
	var lines: Dictionary = p_step.get("lines", {})
	for k: String in lines:
		var v: Variant = lines[k]
		if v is Dictionary:
			for kk: Variant in v:
				out.append(str(v[kk]))
		else:
			out.append(str(v))
	return out


# --- El ------------------------------------------------------------------------------------------------------

func _enter_throw() -> void:
	_thrown = false
	_winding = false
	_charging = false
	_hold_s = 0.0
	_hand_t = 0.0
	_phase_t = 0.0
	view.hide_bone()
	var obj: Dictionary = step.get("objectives", {})
	if rules.thrower == BoneRules.PLAYER:
		phase = "aim"
		set_objective(_hand_text(obj.get("aim", {"tr": "Kemiği at", "en": "Throw the bone"})))
		set_hint(obj.get("aim_hint", {}))
	else:
		phase = "throw"
		set_objective(_hand_text(obj.get("throw_" + rules.thrower, obj.get("throw", {"tr": "Atışı bekle", "en": "Watch the throw"}))))
		set_hint(obj.get("throw_hint", {}))


## Çocuk atar: direğe varır, kolunu kaldırır (Luhun: «Ak kemik, ay ışığında yat!»), bırakır.
func _tick_throw() -> void:
	if _thrown:
		return
	var id := rules.thrower
	var at: Vector2 = _pos.get(id, rules.post)
	if not _winding and (at.distance_to(rules.post) <= 1.6 or _phase_t > 4.5) and _phase_t >= THROW_PREP:
		_winding = true
		if id == "luhun_child":
			_say_event(str((step.get("lines", {}) as Dictionary).get("throw", "throw")))
		var a := actor(id)
		if a:
			var t := scene.create_tween()
			_tweens.append(t)
			t.tween_property(a, ^"gesture_amount", 1.0, THROW_WIND).set_trans(Tween.TRANS_SINE)
			t.tween_callback(_release_npc.bind(id))
			t.tween_property(a, ^"gesture_amount", 0.0, 0.18)
		else:
			_release_npc(id)


func _release_npc(id: String) -> void:
	if _thrown:
		return
	var dir := (_flat(point(step.get("field", "bone_field"))) - rules.post).normalized()
	var spread := deg_to_rad(float(step.get("spread_deg", 30.0)))
	_rng.seed = int(step.get("seed", 2209)) + rules.hand * 31
	var land := BoneRules.pick_landing(_rng, rules.post, dir, spread, BoneRules.THROW_RANGE, rules.landings, _obstacles,
		_flat(point(step.get("field", "bone_field"))), float(step.get("field_radius", 30.0)))
	var from := _to3(_pos.get(id, rules.post)) + Vector3.UP * HAND_UP
	_throw(from, land)


## Oyuncunun atışı: E basılı tutulunca başlar.
func _begin_charge() -> void:
	if phase != "aim" or _charging or _thrown:
		return
	_charging = true
	_hold_s = 0.0


func _tick_aim(delta: float) -> void:
	if _thrown:
		return
	var obj: Dictionary = step.get("objectives", {})
	if not _charging:
		set_objective(_hand_text(obj.get("aim", {}) if _near_post() else obj.get("aim_far", {"tr": "Direğe dön", "en": "Go back to the post"})))
		view.show_aim(Vector3.INF, false)
		return
	_hold_s += delta
	_aim_at = _to3(_aimed_landing())
	view.show_aim(_aim_at, true, clampf(_hold_s / BoneRules.HOLD_FULL_S, 0.0, 1.0))
	if not is_holding():
		_charging = false
		view.show_aim(Vector3.INF, false)
		var from := player().global_position + Vector3.UP * HAND_UP
		_throw(from, _flat(_aim_at))


## Oyuncunun atışının düşeceği yer: direkten kameranın baktığı yöne, basılı tutma süresinin uzaklığında.
func _aimed_landing() -> Vector2:
	var cy := player().camera_yaw()
	var fwd := Vector2(-sin(cy), -cos(cy))
	return BoneRules.aimed_landing(_flat(player().global_position), fwd, BoneRules.throw_distance(_hold_s), _obstacles,
		_flat(point(step.get("field", "bone_field"))), float(step.get("field_radius", 30.0)) + 4.0)


func _throw(from: Vector3, land: Vector2) -> void:
	_thrown = true
	var to := _to3(land)
	var seconds := FLIGHT_BASE + from.distance_to(to) * FLIGHT_PER_M
	if not view.landed.is_connected(_on_landed):
		view.landed.connect(_on_landed)
	view.fly(from, to, seconds)


func _on_landed(at: Vector3) -> void:
	if rules.phase != BoneRules.Phase.THROW:
		return
	rules.land(_flat(at))
	brain.landed(rules)
	_sfx("land", at, -3.0)
	phase = "search"
	_phase_t = 0.0
	var obj: Dictionary = step.get("objectives", {})
	set_objective(_hand_text(obj.get("search", {"tr": "Ak kemiği bul", "en": "Find the white bone"})))
	set_hint(obj.get("search_hint", {}))


## Kuralların olayları: söz, ses, poz, amaç.
func _handle_events() -> void:
	var lines: Dictionary = step.get("lines", {})
	var obj: Dictionary = step.get("objectives", {})
	for e: Dictionary in rules.take_events():
		match str(e["type"]):
			"found":
				var by := str(e["by"])
				phase = "carry"
				_phase_t = 0.0
				_say_event(str((lines.get("found", {}) as Dictionary).get(by, "")))
				if by != BoneRules.PLAYER:
					_gesture_kid(by, "bend_over_pick_up_m" if by == "luhun_child" else "crouch_pick_place_f", 0.4)
					_laugh_at(_to3(_pos[by]))
					# Luhun kemiği Mete'nin burnunun dibinden kaptı.
					if by == "luhun_child" and _player_flat().distance_to(_pos[by]) <= 4.0:
						_tease()
				else:
					_laugh_at(_to3(_pos.get("yanchi_child", rules.bone)))
				_carry_objective()
			"tagged":
				var from := str(e["from"])
				var by := str(e["by"])
				var tagged_lines: Dictionary = lines.get("tagged", {})
				if from == BoneRules.PLAYER:
					_say_event(str((lines.get("found", {}) as Dictionary).get(by, "")))
				else:
					_say_event(str(tagged_lines.get(from, "")))
					_gesture_kid(from, "catching_breath", rules.freeze_s)
					_sfx("pant", _to3(_pos[from]), -6.0)
				_laugh_at(_to3(_pos.get(by, rules.bone)) if by != BoneRules.PLAYER else player().global_position)
				_carry_objective()
			"won":
				var by := str(e["by"])
				phase = "won"
				_won_left = WON_HOLD
				hand_times.append(_hand_t)
				_sfx("slap", _to3(rules.post) + Vector3.UP * 1.0, -2.0)
				_laugh_at(_to3(rules.post))
				set_objective("")
				set_hint("")
				var won_lines: Dictionary = lines.get("won", {})
				_say_event(str(won_lines.get(by, "")))
				if by == "luhun_child" and _player_flat().distance_to(rules.post) <= TEASE_NEAR:
					_tease()
				if by == "yanchi_child" and not rules.is_last_hand():
					say(str(lines.get("again", "again")))
				if by != BoneRules.PLAYER:
					_gesture_kid(by, "regular_jump", 0.9)
				for id in KIDS:
					if id != by:
						_gesture_kid(id, "catching_breath", 1.6)


func _after_win() -> void:
	rules.finish_hand()
	if rules.is_done():
		_enter_end()
		return
	_enter_throw()


func _enter_end() -> void:
	phase = "end"
	_end_left = float(step.get("end_hold", END_HOLD))
	set_objective("")
	set_hint("")
	if rules.player_wins() > 0:
		flag(str(step.get("won_flag", "child_bone_won")))
	for id in KIDS:
		_gesture_kid(id, "catching_breath", 2.5)
	_laugh_at(_to3(rules.post))
	var end_clock := str(step.get("end_clock", ""))
	if not end_clock.is_empty():
		clock_to(end_clock, _end_left)


func _carry_objective() -> void:
	var obj: Dictionary = step.get("objectives", {})
	if rules.carrier == BoneRules.PLAYER:
		set_objective(_hand_text(obj.get("carry", {"tr": "Direğe koş!", "en": "Run for the post!"})))
		set_hint(obj.get("carry_hint", {}))
	else:
		var who: Dictionary = (obj.get("chase", {}) as Dictionary).get(rules.carrier, {"tr": "Kemiği kap", "en": "Get the bone"})
		set_objective(_hand_text(who))
		set_hint(obj.get("chase_hint", {}))


func _hand_text(entry: Variant) -> String:
	var t := text(entry)
	return "%s (%d/%d)" % [t, rules.hand + 1, rules.hands] if not t.is_empty() else ""


# --- Çocuklar ve oyuncu ------------------------------------------------------------------------------------------

func _drive_kid(id: String, delta: float, positions: Dictionary) -> void:
	var m := mover(id)
	if m == null:
		return
	var here: Vector2 = _pos[id]
	if float(_gesture.get(id, 0.0)) > 0.0:
		_gesture[id] = float(_gesture[id]) - delta
		_vel[id] = Vector2.ZERO
		if float(_gesture[id]) <= 0.0:
			var a := actor(id)
			if a and a.avatar:
				a.avatar.set_locomotion(0.0)
		return
	var w := brain.want(id, rules, positions, delta)
	var to: Vector2 = w["to"]
	var speed := float(w["speed"])
	var off := to - here
	var desired := off.normalized() * minf(speed, off.length() / maxf(delta, 0.001)) if off.length() > 0.08 else Vector2.ZERO
	var v: Vector2 = (_vel[id] as Vector2).move_toward(desired, ACCEL * delta)
	var next := BoneRules.push_out(here + v * delta, _obstacles, 0.35)
	# Oyuncunun içinden geçmez (yakalarken 1 m'ye yaklaşır, üstüne binmez).
	var p := _player_flat()
	if next.distance_to(p) < PLAYER_GAP:
		next = p + (next - p).normalized() * PLAYER_GAP if next.distance_to(p) > 0.001 else next
	# Hız sınırı (K105): itilse de (engel, oyuncu) bir karede koşunun ötesine geçmez.
	if (next - here).length() > cap * delta:
		next = here + (next - here).normalized() * cap * delta
	v = (next - here) / maxf(delta, 0.001)
	_vel[id] = v
	_pos[id] = next
	var yaw := float(_yaw[id])
	if v.length() > 0.15:
		yaw = lerp_angle(yaw, atan2(v.x, v.y), 1.0 - exp(-TURN * delta))
	elif w["face"] is Vector2 and (w["face"] as Vector2) != Vector2.INF:
		var f: Vector2 = (w["face"] as Vector2) - next
		if f.length() > 0.05:
			yaw = lerp_angle(yaw, atan2(f.x, f.y), 1.0 - exp(-TURN * 0.5 * delta))
	_yaw[id] = yaw
	m.move_to(_to3(next), yaw, v.length(), delta)
	# Koşan çocuğun soluğu.
	if v.length() > 2.4:
		_pant[id] = float(_pant[id]) - delta
		if float(_pant[id]) <= 0.0:
			_pant[id] = _rng.randf_range(PANT_EVERY.x, PANT_EVERY.y)
			_sfx("pant", _to3(next) + Vector3.UP, -10.0)


## Çocuğa kütüphane klibi (iş olarak; seconds sonra yürüyüşüne döner).
func _gesture_kid(id: String, clip: String, seconds: float) -> void:
	var a := actor(id)
	if a == null or a.avatar == null:
		return
	if a.avatar.play_job(clip):
		_gesture[id] = seconds


## Yakalanan oyuncu 2 sn durur (kontrol kapalı); sonra yine koşar.
func _tick_player_freeze() -> void:
	var frozen := rules.is_frozen(BoneRules.PLAYER)
	if frozen and not _player_frozen:
		_player_frozen = true
		player().set_active(false)
		_sfx("pant", player().global_position + Vector3.UP, -4.0)
	elif not frozen and _player_frozen:
		_player_frozen = false
		if scene.is_running():
			player().set_active(true)


## Kemiğin yeri: taşıyanın elinde ya da yerde (kurallar taşırken taşıyanın yerini yazar).
func _tick_bone() -> void:
	if rules.phase == BoneRules.Phase.CARRY or (rules.phase == BoneRules.Phase.WON and not rules.carrier.is_empty()):
		if rules.carrier == BoneRules.PLAYER:
			view.carry(player().global_position, player().get_facing_yaw())
		else:
			var m := mover(rules.carrier)
			if m:
				view.carry(m.position(), float(_yaw.get(rules.carrier, m.heading())))


func _positions() -> Dictionary:
	var out := {BoneRules.PLAYER: _player_flat()}
	for id in KIDS:
		out[id] = _pos[id]
	return out


# --- Söz ve ses -------------------------------------------------------------------------------------------------

## Olayın sözü: aynı söz LINE_COOLDOWN içinde yinelenmez; söz sıraya girerse el değişince düşer.
func _say_event(key: String) -> void:
	if key.is_empty():
		return
	if scene.clock - float(_said_at.get(key, -INF)) < LINE_COOLDOWN:
		return
	_said_at[key] = scene.clock
	var h := rules.hand
	say(key, func() -> bool: return rules.hand == h)


func _tease() -> void:
	if _teases >= TEASE_MAX or scene.clock - _tease_at < TEASE_GAP:
		return
	_teases += 1
	_tease_at = scene.clock
	say(str((step.get("lines", {}) as Dictionary).get("tease", "tease")), Callable(), true)


func _tick_voice(delta: float) -> void:
	if not phase in ["search", "carry"]:
		return
	_laugh_left -= delta
	if _laugh_left <= 0.0:
		_laugh_left = _rng.randf_range(LAUGH_EVERY.x, LAUGH_EVERY.y)
		var id := KIDS[_rng.randi() % KIDS.size()]
		_laugh_at(_to3(_pos[id]))


func _laugh_at(at: Vector3) -> void:
	_sfx("laugh", at + Vector3.UP, -5.0)


## Tek seferlik ses (verinin sfx'i: anahtar → kimlik; ChildhoodAtmos).
func _sfx(key: String, at: Vector3, db: float) -> void:
	if scene.atmos == null:
		return
	var id := str((step.get("sfx", {}) as Dictionary).get(key, ""))
	if not id.is_empty():
		scene.atmos.sfx(id, at, db)


# --- Yardımcılar ------------------------------------------------------------------------------------------------

func _near_post() -> bool:
	return near(point(step.get("post", "bone_post")), PLAYER_POST)


func _player_flat() -> Vector2:
	return _flat(player().global_position) if player() else Vector2.ZERO


func _collect_obstacles() -> Array:
	var out: Array = []
	var w := world()
	if w and w.has_method(&"collect_obstacles"):
		for c: Vector3 in w.call(&"collect_obstacles"):
			out.append(c)
	var layout: Variant = w.get(&"layout") if w else null
	if layout is Dictionary:
		var pen: Dictionary = ((layout as Dictionary).get("childhood", {}) as Dictionary).get("pen", {})
		if pen.get("at") is Array:
			out.append(Vector3(float(pen["at"][0]), float(pen["at"][1]), float(pen.get("radius", 8.0)) + 0.4))
	return out


static func _flat(p: Vector3) -> Vector2:
	return Vector2(p.x, p.z) if p != Vector3.INF else Vector2.ZERO


func _to3(p: Variant) -> Vector3:
	if not p is Vector2 or (p as Vector2) == Vector2.INF:
		return Vector3.INF
	var v: Vector2 = p
	var shape: Variant = world().call(&"get_terrain_shape") if world() and world().has_method(&"get_terrain_shape") else null
	return Vector3(v.x, float(shape.call(&"height_at", v.x, v.y)) if shape else 0.0, v.y)
