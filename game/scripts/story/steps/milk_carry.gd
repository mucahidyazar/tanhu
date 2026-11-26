extends PrologueStep
## «Süt»ün taşıması (E21, K110; story.md §3 «Göl Obası'nda üç gün»): Çocuk iki tulum kısrak sütünü omuz sırığında Göl Obası'ndan Kayın
## Obası'nın sabasına götürür. Koşu yasak değildir ama koşunca süt çalkalanır ve damlar (dökülme hızı koşunun yürüyüşü aştığı payla büyür);
## derenin sığ geçidinde taştan taşa yavaş basılmazsa (hız > FORD_SLOW) tulumlar damlar. Dökülen pay sözü seçer: full_max'a dek «Tek damla
## dökmemişsin.», ötesi «Yarısı yolda kalmış. Olsun, yine kımız olur.» (ceza yok). Yolda Ana arkadan seslenir, Kayın Obası'ndan inen adam
## yolda karşılaşınca söyler, obaya yaklaşınca kurut seren kadın Saruk'a seslenir. Sonuç: days.results.milk ("full" | "spilt"), işaret
## onsoz_sut. HUD'un yönü yolun ≈22 m ilerisidir (yol obaya iner); ayrıntı satırı sütün hâlini söyler.
##   {"kind": "milk_carry", "target": "saba_stand", "radius": 2.6, "ford": "ford", "ford_radius": 3.4, "full_max": 0.12,
##    "call_line": …, "road_man": {id, line, near, walk_to}, "greet": {line, near_point, near}, "arrive_line", "full_line", "spilt_line"}

## Yürüyüşün üstünde koşunun dökme hızı: (hız − WALK_FREE)^RUN_POW × RUN_SPILL pay/sn (3,6 m/sn'de ≈%1/sn).
const WALK_FREE := 1.75
const RUN_SPILL := 0.0045
const RUN_POW := 1.3
## Geçitte yavaş sayılan hız (m/sn) ve hızlı basışın dökme hızı (pay/sn).
const FORD_SLOW := 1.05
const FORD_SPILL := 0.035
## Taşımanın yürüyüşü (PlayerController.move_mods): yürüyüş aynı, zıplama yok (yavaşlık koşmamaktan gelir).
const CARRY_MODS := {"speed_k": 1.0, "can_run": true, "can_jump": false}
## HUD'un yönü: yolun bu kadar ilerisi (m).
const CARROT := 22.0
## Çalkalanma sesinin adım aralığı (sn): yürürken ve koşarken.
const SLOSH_WALK := 0.62
const SLOSH_RUN := 0.3

var spilled := 0.0
var _target := Vector3.INF
var _ford := Vector3.INF
var _start := Vector3.INF
var _called := false
var _man_said := false
var _greeted := false
var _arrived := false
var _slosh_left := 0.0
var _drip_left := 0.0
var _stone := -1
var _spill_rate := 0.0


func start() -> void:
	_target = point(step.get("target", "saba_stand"))
	_ford = point(step.get("ford", "ford"))
	_start = player().global_position
	if days.carried_id() != "milk_yoke":
		carry("milk_yoke")
	walk_mods(CARRY_MODS)
	_update_detail()


func tick(delta: float) -> void:
	if _arrived:
		return
	var p := player()
	var speed := p.get_speed()
	var at := p.global_position
	# Dökülme: koşu ve geçitte hızlı basış.
	_spill_rate = 0.0
	if speed > WALK_FREE:
		_spill_rate += pow(speed - WALK_FREE, RUN_POW) * RUN_SPILL
	var in_ford := _ford != Vector3.INF and flat(at, _ford) < float(step.get("ford_radius", 3.4))
	if in_ford and speed > FORD_SLOW:
		_spill_rate += FORD_SPILL
	spilled = clampf(spilled + _spill_rate * delta, 0.0, 1.0)
	var yoke := days.carried()
	if yoke:
		yoke.set(&"slosh", clampf(speed / 3.6, 0.0, 1.0) + (0.6 if _spill_rate > 0.0 else 0.0))
		var drops := yoke.get_node_or_null(^"Drops") as CPUParticles3D
		if drops:
			drops.emitting = _spill_rate > 0.002
	# Ses: adımda bir çalkalanma, dökülürken damla, geçitte taşa basış.
	if speed > 0.4:
		_slosh_left -= delta
		if _slosh_left <= 0.0:
			_slosh_left = SLOSH_RUN if speed > WALK_FREE else SLOSH_WALK
			sfx("sfx_milk_slosh", at + Vector3.UP * 0.9, -6.0 if speed > WALK_FREE else -16.0, randf_range(0.94, 1.06))
	if _spill_rate > 0.0:
		_drip_left -= delta
		if _drip_left <= 0.0:
			_drip_left = randf_range(0.35, 0.7)
			sfx("sfx_milk_drip", at + Vector3.UP * 0.5, -10.0)
	if in_ford:
		var s := _stone_under(at)
		if s >= 0 and s != _stone:
			sfx("sfx_stream_step", at, -8.0)
		_stone = s
	_update_detail()
	_tick_lines(at)
	if flat(at, _target) <= float(step.get("radius", 2.6)):
		_arrive()


func target(from: Vector3) -> Vector3:
	if _arrived:
		return Vector3.INF
	if flat(from, _target) < CARROT + 6.0:
		return _target
	var pr := places().road_projection(from)
	return places().road_point(minf(pr.x + CARROT, places().road_length()))


func autoplay(bot: Node, _delta: float) -> void:
	var at := player().global_position
	var ford_near := _ford != Vector3.INF and flat(at, _ford) < 6.0
	if ford_near:
		bot.call(&"set_speed_limit", 0.9)
	else:
		bot.call(&"set_speed_limit", -1.0)
	if flat(at, _target) < 26.0:
		bot.call(&"go_to", _target, false)
		return
	var pr := places().road_projection(at)
	var ahead := 2.0 if pr.y > 3.0 else 6.0
	bot.call(&"go_to", places().road_point(minf(pr.x + ahead, places().road_length())), false)


func preset() -> void:
	var t := point(step.get("target", "saba_stand"))
	if t != Vector3.INF and player():
		player().spawn_at(t + Vector3(1.2, 0.0, -0.8), player().get_facing_yaw())
	result("milk", "full")
	flag("onsoz_sut", "full")


func cleanup() -> void:
	var yoke := days.carried()
	if yoke:
		var drops := yoke.get_node_or_null(^"Drops") as CPUParticles3D
		if drops:
			drops.emitting = false


func line_keys() -> Array:
	return [step.get("call_line", ""), step.get("arrive_line", ""), step.get("full_line", ""), step.get("spilt_line", ""),
		(step.get("road_man", {}) as Dictionary).get("line", ""), (step.get("greet", {}) as Dictionary).get("line", "")]


static func check(s: Dictionary, _data: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	for key in ["target", "arrive_line", "full_line", "spilt_line"]:
		if not s.has(key):
			out.append("%s: %s yok" % [s.get("id", ""), key])
	return out


## Sütün hâli (saf): 0 tam, 0..full_max «biraz», ötesi «yarısı».
static func state_of(share: float, full_max: float = 0.12) -> String:
	if share <= 0.005:
		return "full"
	return "little" if share <= full_max else "spilt"


func _update_detail() -> void:
	var st := state_of(spilled, float(step.get("full_max", 0.12)))
	var words := {
		"full": {"tr": "Tulumlar dolu.", "en": "The skins are full."},
		"little": {"tr": "Biraz süt döküldü.", "en": "A little milk has spilled."},
		"spilt": {"tr": "Sütün çoğu döküldü.", "en": "Much of the milk has spilled."},
	}
	var hint := text(step.get("hint", {}))
	set_detail("%s %s" % [text(words[st]), hint] if not hint.is_empty() else text(words[st]))


func _tick_lines(at: Vector3) -> void:
	if not _called and flat(at, _start) > float(step.get("call_after_m", 9.0)):
		_called = true
		var mother := person("mother")
		if mother:
			mother.face_point(at)
		say(str(step.get("call_line", "")))
	var man: Dictionary = step.get("road_man", {})
	if not man.is_empty() and not _man_said:
		var p := person(str(man.get("id", "birch_man")))
		if p and p.is_present():
			if flat(at, p.position()) <= float(man.get("near", 7.0)):
				_man_said = true
				p.face_point(at)
				say(str(man.get("line", "")))
				var to := point(man.get("walk_to", "gol_road_start"))
				if to != Vector3.INF:
					var from_s := places().road_projection(p.position()).x
					var to_s := places().road_projection(to).x
					at_walk(p, places().road_path(from_s, to_s, 6.0))
	var greet: Dictionary = step.get("greet", {})
	if not greet.is_empty() and not _greeted:
		var g := point(greet.get("near_point", "birch_gate"))
		if g != Vector3.INF and flat(at, g) <= float(greet.get("near", 14.0)):
			_greeted = true
			var w := person(str(greet.get("by", days.cast_id_of(days.speaker_of(str(greet.get("line", "")))))))
			if w:
				w.face_point(at)
			say(str(greet.get("line", "")))


func at_walk(p: PrologueCast.Person, path: Array) -> void:
	at(clock + 2.6, func() -> void:
		if p and p.is_present():
			p.walk(path, 1.25, "stand"))


func _stone_under(at: Vector3) -> int:
	for i in 4:
		var s := point("ford_stone_%d" % (i + 1))
		if s != Vector3.INF and flat(at, s) < 0.45:
			return i
	return -1


func _arrive() -> void:
	_arrived = true
	var full := spilled <= float(step.get("full_max", 0.12))
	var outcome := "full" if full else "spilt"
	result("milk", outcome)
	result("milk_spilled", snappedf(spilled, 0.01))
	flag("onsoz_sut", outcome)
	var saruk := person("saruk")
	if saruk:
		saruk.face_point(player().global_position)
	say(str(step.get("arrive_line", "")))
	say(str(step.get("full_line" if full else "spilt_line", "")))
	done()
