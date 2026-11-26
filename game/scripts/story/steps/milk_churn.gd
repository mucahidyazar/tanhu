extends PrologueStep
## «Süt»ün sabası (E21, K110): süt sabaya dökülür (E «Sabaya dök»: sırık omuzdan iner, sfx_milk_pour), Saruk «Kımız bin kez çalkalanır…»
## der, Çocuk sabayı yirmi kez çalkalar. Ritim: dövme sopası beat_s'de bir iner; inişin window_s içinde basılan E vuruştur (sfx_churn, sopa
## dibe vurur), dışında basılan E kaçar (ceza yok, sayılmaz). Halka (GameplayHud.show_hold) sopanın inişine dek dolar: dolduğu an basılır.
## Saruk sayar: amaç satırının ayrıntısı «7/20» (Saruk'un sayma sözleri e21-lines.json'da yok; HUD sayar). Yirmide «Yirmi. Kolun sağlam.».
##   {"kind": "milk_churn", "target": "saba_stand", "saba": "saba", "strokes": 20, "beat_s": 1.05, "window_s": 0.32, "churn_line", "done_line"}

## Çocuğun çalkalama klibi (kütüphane: çekme hareketi) ve dökme klibi.
const CHURN_CLIP := "pull_radish"
const POUR_CLIP := "crouch_pick_place_f"
const POUR_S := 1.6

var strokes := 0
var misses := 0
var _target := Vector3.INF
var _saba: Node3D
var _beat := 0.0
var _phase_t := 0.0
var _poured := false
var _churning := false
var _finished := false
var _hit_flash := 0.0
var _last_press_beat := -1


func start() -> void:
	phase = "pour"
	_target = point(step.get("target", "saba_stand"))
	_saba = places().saba_node if places() else null
	_beat = float(step.get("beat_s", 1.05))


func interaction() -> Dictionary:
	if _finished:
		return {}
	if phase == "pour":
		if not near(_target, 2.4):
			return {}
		return {"key": "E", "label": text({"tr": "Sabaya dök", "en": "Pour into the churn"}), "run": _pour}
	if phase == "churn" and _churning:
		return {"key": "E", "label": text({"tr": "Çalkala", "en": "Churn"}), "run": _press}
	return {}


func target(_from: Vector3) -> Vector3:
	return _target if phase == "pour" else Vector3.INF


func tick(delta: float) -> void:
	if phase != "churn" or not _churning or _finished:
		return
	_phase_t += delta
	var k := fposmod(_phase_t, _beat) / _beat
	# Sopa: k 0 yukarıda, sonuna doğru iner; vuruşta dibe değer.
	var down := smoothstep(0.55, 1.0, k)
	if _hit_flash > 0.0:
		_hit_flash = maxf(_hit_flash - delta * 5.0, 0.0)
		down = maxf(down, _hit_flash)
	if _saba:
		PrologueProps.set_churn(_saba, down)
	if days.game_hud:
		days.game_hud.show_hold("%d/%d" % [strokes, int(step.get("strokes", 20))], k)


func autoplay(bot: Node, _delta: float) -> void:
	if phase == "pour":
		if near(_target, 1.6):
			bot.call(&"halt")
			bot.call(&"press_e")
		else:
			bot.call(&"go_to", _target, false)
		return
	if phase == "churn" and _churning:
		bot.call(&"halt")
		# Botun vuruşu inişin penceresinde (ara sıra kaçırır: cezasız).
		var k := fposmod(_phase_t, _beat) / _beat
		var beat_i := floori(_phase_t / _beat)
		if k > 0.93 and beat_i != _last_press_beat:
			bot.call(&"press_e")


func preset() -> void:
	carry("")
	walk_mods({})


func cleanup() -> void:
	if days.game_hud:
		days.game_hud.show_hold("", 0.0)
	days.player_work("")
	walk_mods({})


func line_keys() -> Array:
	return [step.get("churn_line", ""), step.get("done_line", "")]


## Basış vuruş mu (saf): beat'teki yeri (0..1; 1 iniş) inişin ±window/beat'i içinde mi?
static func on_beat(phase_k: float, beat_s: float, window_s: float) -> bool:
	var to_down := minf(phase_k, 1.0 - phase_k) * beat_s
	return to_down <= window_s


func _pour() -> void:
	if _poured:
		return
	_poured = true
	var p := player()
	walk_mods(HOLD_MODS)
	var face := CampNpcs.facing_yaw(p.global_position, point(step.get("saba", "saba")))
	if not is_nan(face):
		p.spawn_at(p.global_position, face)
	days.player_work(POUR_CLIP)
	sfx("sfx_milk_pour", _target + Vector3.UP * 1.0, -4.0)
	at(clock + POUR_S * 0.5, func() -> void: carry(""))
	at(clock + POUR_S, _begin_churn)


func _begin_churn() -> void:
	phase = "churn"
	set_objective(step.get("churn_objective", {"tr": "Sabayı çalkala", "en": "Churn the kumis"}))
	set_detail("%s %d/%d" % [text(step.get("hint", {})), strokes, int(step.get("strokes", 20))])
	var saruk := person("saruk")
	if saruk:
		saruk.face_point(player().global_position)
	var wait := say(str(step.get("churn_line", "")))
	days.player_work("")
	at(clock + maxf(wait, 0.5), func() -> void:
		_churning = true
		_phase_t = 0.0
		days.player_work(CHURN_CLIP))


func _press() -> void:
	if not _churning or _finished:
		return
	var k := fposmod(_phase_t, _beat) / _beat
	var beat_i := floori(_phase_t / _beat) + (1 if k > 0.5 else 0)
	if beat_i == _last_press_beat:
		return
	_last_press_beat = beat_i
	if on_beat(k, _beat, float(step.get("window_s", 0.32))):
		strokes += 1
		_hit_flash = 1.0
		sfx("sfx_churn", _target + Vector3.UP * 1.0, -5.0, randf_range(0.95, 1.05))
		set_detail("%s %d/%d" % [text(step.get("hint", {})), strokes, int(step.get("strokes", 20))])
		if strokes >= int(step.get("strokes", 20)):
			_finish()
	else:
		misses += 1


func _finish() -> void:
	_finished = true
	_churning = false
	if days.game_hud:
		days.game_hud.show_hold("", 0.0)
	result("churn_misses", misses)
	if _saba:
		PrologueProps.set_churn(_saba, 0.0)
	days.player_work("")
	walk_mods({})
	var t := say(str(step.get("done_line", "")))
	at(clock + maxf(t, 0.3), done)
