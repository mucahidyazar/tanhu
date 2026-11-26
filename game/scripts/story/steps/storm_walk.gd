extends PrologueStep
## «Tipi»nin yolu (E21, K110; story.md §3; e21-atmosphere.md «Tipi»): Çocuk köz kabıyla ve Börü'yle on iki kazığı sayarak Kayın Obası'na
## iner. Görüş ≈25 m (tipinin sisi; kazıklar tek tek belirir), açıkta rüzgâr oyuncuyu yana iter (PlayerController.external_drift; kayaların,
## yurtların ve ormanın ardında kesilir: PrologueDays.shelter_at), karda iz kalır (PrologueTracks). Köz kabı sıcak, küçük bir ışıktır ve sönmez
## (K1). Kazık geçildikçe sayılır (amaç satırı «Kazık 4/12»); bayrak çırpar. Börü eşlikçidir: ardından gelir, yolda konuşur (boru_stakes,
## boru_six, boru_scared, boru_silent, boru_twelve), yoldan (kazıkların çizgisinden) 15 m uzaklaşınca «Kazığı göremiyorum!» der. Uzakta bir kez
## kurt uluması ve Börü'nün sorusu (K3: kurt görünmez). Obaya yaklaşınca köpek havlar. Künay'ın kapısına varınca biter.
##   {"kind": "storm_walk", "target": "kunay_door", "radius": 3.0, "lost_m": 15.0, "push_k": 0.045, "wolf_at_stake": 7,
##    "lines": {"start": …, "six": …, "eight": …, "ten": …, "twelve": …, "lost": …, "wolf": …}}

## Kazık geçilmiş sayılır: kazığa bu uzaklıkta (m) ya da yol boyu kazığın 1 m ötesinde.
const PASS_NEAR := 5.0
## Rüzgârın itişi: m/sn rüzgâr başına (en çok PUSH_MAX m/sn).
const PUSH_K := 0.045
const PUSH_MAX := 0.75
## Börü'nün ardından gelişi (m) ve «kayboldum» sözünün en kısa arası (sn).
const FOLLOW_GAP := 1.7
const LOST_COOLDOWN := 22.0
## Kurt: yolun bu kadar batısında (m), sesinden sonra Börü'nün sorusu (sn).
const WOLF_OFFSET := Vector3(-70.0, 0.0, 30.0)
const WOLF_LINE_AFTER := 1.8
## Köpeğin havladığı uzaklık (obanın ortasından, m).
const DOG_NEAR := 48.0

var passed := 0
var lost_said := 0
var wolf_heard := false
var _target := Vector3.INF
var _stakes: Array = []
var _lost_at := -INF
var _dog_barked := false
var _tracks: PrologueTracks
var _flag_left := 0.0
var _said := {}
var _lee := false
var _drift := Vector3.ZERO


func start() -> void:
	_target = point(step.get("target", "kunay_door"))
	_stakes = places().stake_points.duplicate() if places() else []
	if days.carried_id() != "ember_pot":
		carry("ember_pot")
	walk_mods({"speed_k": 0.95, "can_run": true, "can_jump": false})
	var boru := person("boru")
	if boru:
		boru.set_present(true)
		boru.follow_player(FOLLOW_GAP)
	bed("amb_blizzard_night", true, -3.0)
	bed("amb_ember_pot", true, -12.0)
	days.music("")
	_tracks = PrologueTracks.new()
	_tracks.set_ground(days.ground_y)
	days.root().add_child(_tracks)
	_tracks.walker(player(), 0.46, 0.09)
	if boru and boru.actor:
		_tracks.walker(boru.actor, 0.38, 0.07)
	_say_line("start", 2.5)
	_update_detail()


func tick(delta: float) -> void:
	var p := player()
	var at := p.global_position
	_tick_stakes(at)
	_tick_lost(at)
	_tick_wind(at)
	_tick_dog(at)
	if _tracks:
		_tracks.tick(delta)
	_flag_left -= delta
	if _flag_left <= 0.0 and places() and days.weather and days.weather.sim:
		_flag_left = 0.5
		places().set_storm(1.0, Vector2(days.weather.sim.fx.dir_x, days.weather.sim.fx.dir_z))
	if flat(at, _target) <= float(step.get("radius", 3.0)):
		done()


func target(from: Vector3) -> Vector3:
	if passed < _stakes.size():
		return _stakes[passed]
	return _target


func autoplay(bot: Node, _delta: float) -> void:
	var at := player().global_position
	bot.call(&"set_speed_limit", -1.0)
	bot.set(&"drift", _drift)
	if passed >= _stakes.size() or flat(at, _target) < 30.0:
		bot.call(&"go_to", _target, false)
		return
	var pr := places().road_projection(at)
	# Rüzgâr yoldan iterse önce yola döner, sonra yolun ilerisine.
	var ahead := 2.0 if pr.y > 3.0 else 7.0
	bot.call(&"go_to", places().road_point(minf(pr.x + ahead, places().road_length())), false)


func preset() -> void:
	var t := point(step.get("target", "kunay_door"))
	if t != Vector3.INF and player():
		# Kapının önü, yurda bakar (yan duvarın dibinde değil: ocağa kapıdan girilir).
		var c := point(str(step.get("target", "kunay_door")).trim_suffix("_door") + "_yurt")
		var out := Vector3(t.x - c.x, 0.0, t.z - c.z).normalized() if c != Vector3.INF else Vector3.BACK
		var at := t + out * 1.0
		player().spawn_at(at, atan2(-out.x, -out.z))
	if days.carried_id() != "ember_pot":
		carry("ember_pot")
	var boru := person("boru")
	if boru and t != Vector3.INF:
		boru.set_present(true)
		var c2 := point(str(step.get("target", "kunay_door")).trim_suffix("_door") + "_yurt")
		var out2 := Vector3(t.x - c2.x, 0.0, t.z - c2.z).normalized() if c2 != Vector3.INF else Vector3.BACK
		boru.place(t + out2 * 1.6 + Vector3(-out2.z, 0.0, out2.x) * 1.1, t)


func cleanup() -> void:
	if player():
		player().external_drift = Vector3.ZERO
	var boru := person("boru")
	if boru and bool(step.get("release_boru", false)):
		boru.stop_follow()


func line_keys() -> Array:
	return (step.get("lines", {}) as Dictionary).values()


static func check(s: Dictionary, _data: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	for key in ["lost", "wolf"]:
		if not (s.get("lines", {}) as Dictionary).has(key):
			out.append("%s: lines.%s yok" % [s.get("id", ""), key])
	return out


## Rüzgârın itişi (saf): rüzgâr (m/sn vektör) → oyuncunun sürüklenmesi (m/sn; en çok PUSH_MAX).
static func push_of(wind: Vector2, k: float = PUSH_K) -> Vector3:
	var v := wind * k
	if v.length() > PUSH_MAX:
		v = v.normalized() * PUSH_MAX
	return Vector3(v.x, 0.0, v.y)


func _update_detail() -> void:
	set_detail(text({"tr": "Kazık %d/%d", "en": "Stake %d/%d"}) % [passed, _stakes.size()])


func _tick_stakes(at: Vector3) -> void:
	while passed < _stakes.size():
		var s: Vector3 = _stakes[passed]
		var s_arc := places().road_projection(s).x
		var me_arc := places().road_projection(at).x
		if flat(at, s) <= PASS_NEAR or me_arc > s_arc + 1.0:
			passed += 1
			sfx("sfx_stake_flap", s + Vector3.UP * 1.4, -6.0)
			_update_detail()
			match passed:
				6:
					_say_line("six", 0.2)
				8:
					_say_line("eight", 1.2, true)
				10:
					_say_line("ten", 1.0, true)
				12:
					_say_line("twelve", 0.3)
			if passed == int(step.get("wolf_at_stake", 7)) and not wolf_heard:
				_wolf(at)
		else:
			break


func _tick_lost(at: Vector3) -> void:
	var off := places().road_projection(at).y
	if off > float(step.get("lost_m", 15.0)) and clock - _lost_at >= LOST_COOLDOWN:
		_lost_at = clock
		lost_said += 1
		_say_line("lost", 0.0, false, true)


func _tick_wind(at: Vector3) -> void:
	var w := days.wind_at(at)
	player().external_drift = push_of(w, float(step.get("push_k", PUSH_K)))
	_drift = player().external_drift
	var lee := days.shelter_at(at) >= 0.6
	if lee != _lee:
		_lee = lee
		bed("amb_blizzard_lee", lee, -2.0)
		bed("amb_blizzard_night", true, -12.0 if lee else -3.0)


func _tick_dog(at: Vector3) -> void:
	if _dog_barked:
		return
	var c := point("birch_center")
	if c != Vector3.INF and flat(at, c) < DOG_NEAR:
		_dog_barked = true
		sfx("sfx_dog_storm", c + Vector3(6.0, 0.6, -4.0), -2.0)


func _wolf(at: Vector3) -> void:
	wolf_heard = true
	sfx("sfx_wolf_far", at + WOLF_OFFSET + Vector3.UP * 2.0, 2.0)
	at_say("wolf", WOLF_LINE_AFTER)


func at_say(key: String, after: float) -> void:
	at(clock + after, func() -> void: _say_line(key, 0.0, false, true))


## Börü'nün yol sözü (bir kez; lost yinelenir). optional sözler konuşulurken düşer.
func _say_line(key: String, after: float, optional := false, repeat := false) -> void:
	var id := str((step.get("lines", {}) as Dictionary).get(key, ""))
	if id.is_empty() or (_said.has(key) and not repeat):
		return
	_said[key] = true
	if after > 0.0:
		at(clock + after, func() -> void: say(id, Callable(), optional))
	else:
		say(id, Callable(), optional)
