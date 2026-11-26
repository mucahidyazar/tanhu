extends PrologueStep
## Önsöz'ün genel adım türleri (E21, K110; docs/design/d3/e21-prologue-api.md §3): kind'a göre tek betik.
##   say        {lines: [id | {line, by, face, after}], wait: true}: söz sırası; konuşan oyuncuya döner. wait false ise hemen biter.
##   reach      {target, radius, approach_line: {line, near}, lines: [{line, near_stake|at}], follow: kişi}: yere varınca biter.
##   wait       {seconds}: bekler (say listesi saatle çalar); {until: "quiet"} söz bitene dek.
##   interact   {target, reach, label, hold_s, clip, sfx, line, carry}: yerde E (basılı hold_s); kişinin klibi, ses, söz; biter.
##   fade       {to, seconds}: perde.
##   clock      {set: "18:20"} anında ya da {lapse: "19:10", seconds}: görünür akış (akış bitince biter).
##   weather    {type, blend, params, snow, snow_s, mist}: hava; hemen biter.
##   cast       {actions: [{id, at, walk: [yer], speed, work, face, hide, show}], wait: false}: kişiler; wait ise yürüyenler varınca biter.
##   wake       {line | lines, by, rise_after}: yatakta uyanış; sözden sonra (ya da oyuncu hareket edince) Çocuk kalkar.
##   sleep      {bed, radius, label}: yatağa E «Uyu»: Çocuk uzanır, perde kararır, gün biter.
##   night_end  {fade_s, hold_s}: perde kararır, gün biter (yatağa gidilmeyen gece: tipi).
##   cinema     {}: sinemaya geçiş (PrologueDays.to_cinema).
##   place      {at, face, clock, actions}: perde karayken oyuncuyu yere koyar, saati atlatır, kişileri (cast'ın actions'ı) yerleştirir; hemen biter.
##   sound      {sfx, at, db, beds: [{id, on, db}]}: tek seferlik ses (konumlu) ve yataklar; hemen biter.

const DEFAULT_REACH := 1.8
const SLEEP_CLIP := "sleep_normally"
const WAKE_CLIP := "wake_up_look_up"

var _target := Vector3.INF
var _wait_left := 0.0
var _hold := 0.0
var _approach_said := false
var _pressed := false
var _risen := false
var _rise_at := -1.0
var _walkers: Array[String] = []
var _lines_said := {}
var _pending_says := 0


func kind() -> String:
	return str(step.get("kind", ""))


func start() -> void:
	match kind():
		"say":
			_start_say()
		"reach":
			_target = point(step.get("target"))
			if step.has("follow"):
				var p := person(str(step["follow"]))
				if p:
					p.follow_player(float(step.get("follow_gap", 1.6)))
		"wait":
			_wait_left = float(step.get("seconds", 1.0))
		"interact":
			_target = point(step.get("target"))
		"fade":
			_run_fade()
		"clock":
			if step.has("set"):
				jump_clock(step["set"])
				done()
			elif step.has("lapse"):
				clock_to(step["lapse"], float(step.get("seconds", 4.0)))
			else:
				done()
		"weather":
			_apply_weather()
			done()
		"cast":
			_apply_cast()
			if not bool(step.get("wait", false)) or _walkers.is_empty():
				done()
		"wake":
			_start_wake()
		"sleep":
			_target = point(step.get("bed", "gol_family_bed"))
		"night_end":
			_run_night_end()
		"cinema":
			_run_cinema()
		"place":
			_run_place()
			done()
		"sound":
			if step.has("sfx"):
				sfx(str(step["sfx"]), point(step.get("at", "")) if step.has("at") else null, float(step.get("db", 0.0)))
			for b: Variant in step.get("beds", []):
				bed(str((b as Dictionary).get("id", "")), bool((b as Dictionary).get("on", true)), float((b as Dictionary).get("db", 0.0)))
			done()
		_:
			done()


func tick(delta: float) -> void:
	match kind():
		"say":
			if _pending_says <= 0 and days.voice.is_free() and clock > 0.2:
				done()
		"reach":
			_tick_reach()
		"wait":
			if str(step.get("until", "")) == "quiet":
				if days.voice.is_free() and clock > 0.2:
					done()
			else:
				_wait_left -= delta
				if _wait_left <= 0.0:
					done()
		"interact":
			_tick_interact(delta)
		"clock":
			if days.clock and not days.clock.is_lapsing():
				done()
		"cast":
			var all_there := true
			for id in _walkers:
				var p := person(id)
				if p and p.is_walking():
					all_there = false
			if all_there:
				done()
		"wake":
			_tick_wake()


func target(_from: Vector3) -> Vector3:
	match kind():
		"reach", "interact", "sleep":
			return _target
	return Vector3.INF


func interaction() -> Dictionary:
	match kind():
		"interact":
			if _pressed or not near(_target, float(step.get("reach", DEFAULT_REACH))):
				return {}
			return {"key": "E", "label": text(step.get("label", {"tr": "Al", "en": "Take"})), "run": _on_interact}
		"sleep":
			if _pressed or not near(_target, float(step.get("radius", 1.6))):
				return {}
			return {"key": "E", "label": text(step.get("label", {"tr": "Uyu", "en": "Sleep"})), "run": _on_sleep}
	return {}


func autoplay(bot: Node, _delta: float) -> void:
	match kind():
		"reach":
			bot.call(&"go_to", _target, bool(step.get("bot_run", false)))
		"interact", "sleep":
			var r := float(step.get("reach", step.get("radius", DEFAULT_REACH))) * 0.6
			if near(_target, r):
				bot.call(&"halt")
				if float(step.get("hold_s", 0.0)) > 0.0:
					bot.call(&"hold_e", float(step["hold_s"]) + 0.2)
				else:
					bot.call(&"press_e")
			else:
				bot.call(&"go_to", _target, false)
		"wake":
			if clock > 2.0:
				bot.call(&"nudge")
		_:
			bot.call(&"halt")


func preset() -> void:
	match kind():
		"weather":
			_apply_weather(true)
		"cast":
			_apply_cast(true)
		"place":
			_run_place()
		"clock":
			if step.has("set"):
				jump_clock(step["set"])
			elif step.has("lapse"):
				jump_clock(step["lapse"])
		"interact":
			if step.has("carry"):
				carry(str(step["carry"]))
		"reach":
			var t := point(step.get("target"))
			if t != Vector3.INF and player():
				player().spawn_at(t + Vector3(0.6, 0.0, 0.6), player().get_facing_yaw())


func cleanup() -> void:
	if kind() == "reach" and step.has("follow") and bool(step.get("follow_release", false)):
		var p := person(str(step["follow"]))
		if p:
			p.stop_follow()


static func check(s: Dictionary, _data: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	var k := str(s.get("kind", ""))
	if k in ["reach", "interact"] and not s.has("target"):
		out.append("%s: target yok" % s.get("id", ""))
	if k == "say" and not s.get("lines") is Array:
		out.append("%s: lines yok" % s.get("id", ""))
	return out


# --- say ------------------------------------------------------------------------------------------------

func _start_say() -> void:
	var t := 0.0
	for e: Variant in step.get("lines", []):
		var entry: Dictionary = e if e is Dictionary else {"line": str(e)}
		var id := str(entry.get("line", ""))
		var by := str(entry.get("by", days.cast_id_of(days.speaker_of(id))))
		var face: Variant = entry.get("face", "player")
		var after := float(entry.get("after", 0.0))
		if after > 0.0:
			t += after
			_pending_says += 1
			at(t, func() -> void:
				_pending_says -= 1
				_say_one(id, by, face))
		else:
			_say_one(id, by, face)
	if not bool(step.get("wait", true)):
		done()


func _say_one(id: String, by: String, face: Variant) -> void:
	var p := person(by)
	if p:
		if face is String and face == "player":
			p.face_point(player().global_position)
		elif face is String and person(face):
			p.face_point(person(face).position())
		elif face != null:
			var f := point(face)
			if f != Vector3.INF:
				p.face_point(f)
	say(id)


# --- reach ------------------------------------------------------------------------------------------------

func _tick_reach() -> void:
	var call: Dictionary = step.get("approach_line", {})
	if not call.is_empty() and not _approach_said and near(_target, float(call.get("near", 12.0))):
		_approach_said = true
		var by := person(days.cast_id_of(days.speaker_of(str(call.get("line", "")))))
		if by:
			by.face_point(player().global_position)
		say(str(call.get("line", "")))
	for e: Variant in step.get("lines", []):
		var entry: Dictionary = e
		var id := str(entry.get("line", ""))
		if _lines_said.has(id):
			continue
		var where := point(entry.get("near_point", ""))
		if where != Vector3.INF and near(where, float(entry.get("near", 10.0))):
			_lines_said[id] = true
			var by2 := person(days.cast_id_of(days.speaker_of(id)))
			if by2:
				by2.face_point(player().global_position)
			say(id)
	if near(_target, float(step.get("radius", 3.0))):
		done()


# --- interact ---------------------------------------------------------------------------------------------

func _tick_interact(delta: float) -> void:
	var hold := float(step.get("hold_s", 0.0))
	if hold <= 0.0 or not _pressed:
		return
	if Input.is_action_pressed(&"accept"):
		_hold += delta
		if days.game_hud:
			days.game_hud.show_hold(text(step.get("label", {})), _hold / hold)
		if _hold >= hold:
			if days.game_hud:
				days.game_hud.show_hold("", 0.0)
			_finish_interact()
	else:
		_pressed = false
		_hold = 0.0
		if days.game_hud:
			days.game_hud.show_hold("", 0.0)


func _on_interact() -> void:
	if _pressed:
		return
	_pressed = true
	if float(step.get("hold_s", 0.0)) > 0.0:
		_hold = 0.0
		return
	_finish_interact()


func _finish_interact() -> void:
	var clip := str(step.get("clip", ""))
	if not clip.is_empty() and player():
		days.player_work(clip)
	if step.has("sfx"):
		sfx(str(step["sfx"]), _target)
	if step.has("carry"):
		carry(str(step["carry"]))
	if step.has("line"):
		say(str(step["line"]))
	var settle := float(step.get("settle_s", 0.6 if not clip.is_empty() else 0.0))
	if settle > 0.0:
		var mods := player().move_mods.duplicate() if player() else {}
		walk_mods(HOLD_MODS)
		at(clock + settle, func() -> void:
			days.player_work("")
			walk_mods(mods if step.get("carry", "") != "milk_yoke" else {"speed_k": 1.0, "can_run": true, "can_jump": false})
			done())
	else:
		done()


# --- fade, weather, cast -------------------------------------------------------------------------------------

func _run_fade() -> void:
	await fade(float(step.get("to", 1.0)), float(step.get("seconds", 0.8)))
	done()


func _apply_weather(instant: bool = false) -> void:
	if step.has("type"):
		weather(str(step["type"]), 0.0 if instant else float(step.get("blend", 6.0)), step.get("params", {}))
	if step.has("snow"):
		days.set_snow(float(step["snow"]), float(step.get("snow_s", 0.0)))
	if step.has("mist"):
		days.set_mist(float(step["mist"]))


func _apply_cast(instant: bool = false) -> void:
	for a: Variant in step.get("actions", []):
		var action: Dictionary = a
		var id := str(action.get("id", ""))
		if id.begins_with("dog") or id.begins_with("horse"):
			days.cast.call(&"_apply_animal", id, action)
			continue
		var p := person(id)
		if p == null:
			continue
		if bool(action.get("hide", false)):
			p.set_present(false)
			continue
		if bool(action.get("show", false)) or action.has("at"):
			p.set_present(true)
		if action.has("at"):
			var at_point := point(action["at"])
			if at_point != Vector3.INF:
				p.place(at_point, point(action.get("face", "")))
		if action.has("walk"):
			var path := points(action["walk"])
			if instant and not path.is_empty():
				p.place(path.back(), point(action.get("face", "")))
			elif not path.is_empty():
				p.walk(path, float(action.get("speed", 1.2)), str(action.get("work", "")), point(action.get("face", "")))
				_walkers.append(id)
		elif action.has("work"):
			p.work(str(action["work"]))
		if action.has("face") and not action.has("walk"):
			var f := point(action["face"])
			if f != Vector3.INF:
				p.face_point(f)


# --- wake, sleep, night_end, cinema --------------------------------------------------------------------------

func _start_wake() -> void:
	var ids: Array = step.get("lines", [step.get("line", "")])
	var by := person(str(step.get("by", "mother")))
	if by:
		by.face_point(player().global_position)
	var t := float(step.get("delay", 1.2))
	for id: Variant in ids:
		if str(id).is_empty():
			continue
		at(t, func() -> void: say(str(id)))
		t += 0.1
	var av := player().get_avatar() if player() else null
	if av:
		av.play_job(SLEEP_CLIP)


func _tick_wake() -> void:
	if _risen:
		if _rise_at >= 0.0 and clock >= _rise_at:
			done()
		return
	var quiet := days.voice.is_free() and clock > float(step.get("delay", 1.2)) + 0.4
	var moved := player() and InputSetup.move_vector().length() > 0.2
	if quiet or moved or (step.has("rise_after") and clock >= float(step["rise_after"])):
		_rise()


func _rise() -> void:
	_risen = true
	var av := player().get_avatar()
	if av and av.play_job(WAKE_CLIP):
		_rise_at = clock + float(step.get("rise_s", 2.2))
		player().set_active(false)
		at(_rise_at, func() -> void:
			var spot := player().global_position
			player().spawn_at(spot, player().get_facing_yaw())
			player().set_active(true))
	else:
		player().spawn_at(player().global_position, player().get_facing_yaw())
		_rise_at = clock


func _on_sleep() -> void:
	if _pressed:
		return
	_pressed = true
	var p := player()
	p.set_active(false)
	var bed_point := _target
	var yaw := p.get_facing_yaw()
	p.sit_at(Transform3D(Basis(Vector3.UP, yaw), bed_point))
	var av := p.get_avatar()
	if av:
		av.play_job(SLEEP_CLIP)
	await days.get_tree().create_timer(float(step.get("lie_s", 1.0))).timeout
	await fade(1.0, float(step.get("fade_s", 1.6)))
	await days.get_tree().create_timer(float(step.get("hold_s", 0.6))).timeout
	days.end_day()


func _run_night_end() -> void:
	if player():
		player().set_active(false)
	await fade(1.0, float(step.get("fade_s", 2.0)))
	await days.get_tree().create_timer(float(step.get("hold_s", 0.8))).timeout
	days.end_day()


func _run_cinema() -> void:
	await days.to_cinema()


func _run_place() -> void:
	if step.has("clock"):
		jump_clock(step["clock"])
	_apply_cast(true)
	var at_point := point(step.get("at", ""))
	if at_point != Vector3.INF and player():
		var yaw := player().get_facing_yaw()
		var f := point(step.get("face", ""))
		if f != Vector3.INF:
			var y := CampNpcs.facing_yaw(at_point, f)
			if not is_nan(y):
				yaw = y
		player().spawn_at(at_point, yaw)
		if days.camera:
			days.camera.snap_to_target()
