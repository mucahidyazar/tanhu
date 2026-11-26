class_name FlockGate
extends FlockStep
## «Çobanlık» 2: ağılın kapısı (tür «flock_gate»; bugünkü ağıl adımının düzeneği: ChildhoodSite.release_herd, HerdSim LEAVING). Çocuk kapıda
## E ile kapıyı açar, kırk baş sırayla çıkar ve kapının önünde (flock_gather) toplanır; Luhun ve Yançi ağılın önünde bekler. Son koyun
## çıkınca Luhun yolu söyler: «Göl ötede, ılgınların ardında. Ardımdan gelin.» ve öne geçer; söz başlayınca adım biter. Veri: gate (işaret),
## gather (toplanma yeri), gather_radius, go_line, kids: {actor: işaret}.

var _opened := false
var _out_said := false
var _out_t := 0.0


func start() -> void:
	phase = "gate"
	for id: String in (step.get("kids", {}) as Dictionary):
		var m := mover(id)
		if m:
			m.go([point(step["kids"][id])], pace(2.2))


func tick(delta: float) -> void:
	tick_followers(delta)
	var h := herd()
	match phase:
		"gate":
			pass
		"out":
			_out_t += delta
			# Son koyun çıkınca (ya da kapıda takılan olursa en geç out_max_s'de: sürü yolda toparlanır).
			# Çoğu çıkınca (go_share) yola düşülür: kalanlar kapıdan çıkıp sürüye katılır (drive_along ağıldakini kapıdan çıkarır).
			var enough := int(ceilf(float(h.count()) * float(step.get("go_share", 1.0)))) if h else 0
			if h and (h.released_total() >= enough or h.phase() == HerdSim.Phase.MEADOW or _out_t > float(step.get("out_max_s", 40.0))) and not _out_said:
				_out_said = true
				var wait := say(str(step.get("go_line", "go")))
				at(clock + minf(wait, 1.2), done)


func interaction() -> Dictionary:
	if _opened or not near(point(step.get("gate", "pen_gate")), float(step.get("radius", 2.6))):
		return {}
	return {"key": "E", "label": "Kapıyı aç", "run": open_gate}


## Kapı açılır, sürü salınır (kapının önündeki toplanma yerine).
func open_gate() -> void:
	if _opened:
		return
	_opened = true
	phase = "out"
	set_objective(step.get("out_objective"))
	set_hint(step.get("out_hint"))
	var s := site()
	if s:
		s.set_gate_open(true)
		# Sabah sürü kapıya yığılır: koyunlar sayım günündekinden sık çıkar (release_cadence).
		var cadence := s.herd.sim.release_cadence
		var lead := s.herd.sim.lead_speed
		s.herd.sim.release_cadence = float(step.get("release_cadence", 0.28))
		# Sabah koyun çıkmaya heveslidir: kapıdan sayım günündekinden hızlı yürür (release_pace, m/sn).
		s.herd.sim.lead_speed = float(step.get("release_pace", lead))
		s.herd.release(Vector2(point(step.get("gather", "flock_gather")).x, point(step.get("gather", "flock_gather")).z), float(step.get("gather_radius", 9.0)))
		s.herd.sim.release_cadence = cadence
		s.herd.sim.lead_speed = lead
	sfx("sfx_sheep", point(step.get("gate", "pen_gate")), -4.0)


func target(_from: Vector3) -> Vector3:
	return point(step.get("gate", "pen_gate")) if phase == "gate" else Vector3.INF


func preset() -> void:
	var s := site()
	if s and s.herd:
		s.set_gate_open(true, true)
		s.herd.place_on_meadow(Vector2(point(step.get("gather", "flock_gather")).x, point(step.get("gather", "flock_gather")).z), float(step.get("gather_radius", 9.0)))
	player().spawn_at(point(step.get("gather", "flock_gather")) + Vector3(-12.0, 0.0, 0.0), PI * 0.5)


func autoplay(bot: Node, _delta: float) -> void:
	if phase == "gate":
		if bool(bot.call(&"follow", [step.get("gate", "pen_gate")], "gate", true, 1.6)):
			var d := interaction()
			if not d.is_empty():
				(d["run"] as Callable).call()
	elif bool(bot.call(&"follow", [step.get("aside", [25.6, 20.4])], "aside", false, 0.8)):
		# Kapının önünden çekilir (koyunlar kapıdan çıksın).
		bot.call(&"halt")


func line_keys() -> Array:
	return [str(step.get("go_line", "go"))]
