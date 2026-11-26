extends PrologueStep
## «Şilde Gecesi»nin ilk adımı (feast_walk; Önsöz, 9 Nisan gecesi, K110; story.md §3; e21-atmosphere.md «Şilde Gecesi»): Göl Obası'nda gece,
## dereden davul ve ağız kopuzu duyulur (mus_shilde Kayın Obası'nın ateşinden konumlu çalar, uzakta kısık ve boğuk; dosyası yoksa kodla
## basılan kısa döngü shilde_drum_jaw). Ana şildeyi anlatır ve keçe kundağı verir (E: Çocuk kundağı alır, iki elinde taşır), aile (Ana, Baba,
## Ağabey) Çocuk'la yola çıkar: Ana «Şildeye giden eli boş gitmez.», Baba «Gidelim. Işığın dışında oturan gürültüyü sevmez.». Yol yokuşun başına
## varınca kısa bir kararma yokuşu ve ormanı açık vadiye dek kısaltır (ROAD_CUT: oyun saati 3 dk ileri, aile ve Çocuk vadide); davul yükselir. Geçitten
## Kayın Obası'na girilir: Baba «Tonga, oğlun uzun yaşasın.», Tonga «Ateşi getiren sendin. Bu ocakta yerin var.» Adım biter, şilde başlar.
## Yerler places.json'dandır (gol_family_door, gol_road_start, road_descent, road_forest, road_open, ford, birch_gate, feast_fire); adımın
## verisi ezebilir.

const FAMILY: Array[String] = ["mother", "father", "older_brother"]
## Kısaltmanın başladığı ve bittiği yerler, perdenin süresi (sn) ve saatin atlaması (oyun dk).
const ROAD_CUT := ["road_descent", "road_open"]
const CUT_FADE := 0.8
const CUT_MINUTES := 3.0
## Ailenin yürüyüşü (m/sn; K105: Çocuk'un koşusunu aşmaz) ve aralarındaki boşluk (m).
const FAMILY_SPEED := 1.45
const FAMILY_GAP := 1.6
## Kayın Obası'na girildi sayılan uzaklık (m; birch_gate'ten).
const GATE_R := 9.0

var _phase_t := 0.0
var _cut_done := false
var _arrived := false
var _gift_taken := false
var _route: Array[Vector3] = []
var _bot_wait := 0.0


func line_keys() -> Array:
	return ["act0.feast.ana", "act0.feast.gift", "act0.feast.walk", "act0.feast.baba", "act0.feast.baba_tonga", "act0.feast.tonga_thanks"]


func start() -> void:
	_route = _route_points()
	_start_music()
	FeastWatch.ensure(days.root() if days.root() else world(), point(step.get("fire", "feast_fire")), say, days.sound)
	HearthCold.ensure(days)
	phase = "call"
	var t := say_seq(["act0.feast.ana", "act0.feast.gift"])
	at(clock + t * 0.6, func() -> void:
		phase = "gift"
		set_objective({"tr": "Kundağı Ana'dan al", "en": "Take the swaddle from Mother"})
		set_hint({"tr": "Keçe kundak Künay'ın bebeğine.", "en": "A felt swaddle for Kunay's baby."}))


func cleanup() -> void:
	pass


## Şildenin müziği: Kayın Obası'nın ateşinden konumlu (FeastWatch.ensure_music; adımlar aynı düğümü paylaşır).
func _start_music() -> void:
	FeastWatch.ensure_music(days.root() if days.root() else world(), point(step.get("fire", "feast_fire")))


## Geliştirme: sonraki adımdan açılınca aile ve Çocuk Kayın Obası'nın girişinde, kundak elde değil (verilecek), müzik çalıyor.
func preset() -> void:
	var gate := point(step.get("gate", "birch_gate"))
	var fire := point(step.get("fire", "feast_fire"))
	if gate == Vector3.INF:
		return
	var dir := (fire - gate).normalized() if fire != Vector3.INF else Vector3.FORWARD
	player().spawn_at(gate + dir * 3.0, atan2(dir.x, dir.z))
	for i in FAMILY.size():
		var p := person(FAMILY[i])
		if p:
			p.place(gate + dir * (1.2 + float(i)) + Vector3(dir.z, 0.0, -dir.x) * (1.6 if i % 2 == 0 else -1.6), fire)
	result("swaddle", true)
	_start_music()
	music("")


func target(_from: Vector3) -> Vector3:
	match phase:
		"gift":
			var m := actor("mother")
			return m.global_position if m else point("gol_family_door")
		"walk":
			return point(step.get("gate", "birch_gate"))
	return Vector3.INF


func interaction() -> Dictionary:
	if phase != "gift" or _gift_taken:
		return {}
	var m := actor("mother")
	if m == null or not near(m.global_position, 2.0):
		return {}
	return {"key": "E", "label": str({"tr": "Kundağı al", "en": "Take the swaddle"}.get(SubtitleBar.ui_lang(), "Kundağı al")), "run": _take_gift}


func _take_gift() -> void:
	_gift_taken = true
	E21Shots.log("şilde: kundak alındı, yola çıkıldı")
	HearthProps.hold(days.root() if days.root() else world(), player(), HearthProps.swaddle_node(), "HeldSwaddle")
	result("swaddle", true)
	phase = "walk"
	set_objective({"tr": "Ailenle Kayın Obası'na yürü", "en": "Walk to Birch Camp with your family"})
	set_hint({"tr": "Davul dereden geliyor.", "en": "The drum is coming up from the stream."})
	var t := say("act0.feast.walk")
	at(clock + t + 0.4, func() -> void: say("act0.feast.baba"))
	_send_family(0)


func tick(delta: float) -> void:
	_phase_t += delta
	if phase != "walk":
		return
	var p := player().global_position
	# Ormanın içinde kısaltma: aile ve Çocuk açık vadiye.
	if not _cut_done and _near_route_point(p, ROAD_CUT[0], 10.0):
		_cut_done = true
		_road_cut()
	if not _arrived and near(point(step.get("gate", "birch_gate")), GATE_R):
		_arrived = true
		E21Shots.log("şilde: Kayın Obası'na varıldı")
		phase = "arrive"
		E21Shots.shot(player(), "feast_arrive", 1.0)
		for id in FAMILY:
			var who := person(id)
			if who:
				who.stop_follow()
		set_objective({})
		set_hint({})
		var t := say_seq(["act0.feast.baba_tonga", "act0.feast.tonga_thanks"])
		at(clock + t + 0.5, done)


func _road_cut() -> void:
	fade(1.0, CUT_FADE)
	at(clock + CUT_FADE + 0.05, func() -> void:
		var to := point(ROAD_CUT[1])
		var ahead := point(step.get("gate", "birch_gate"))
		var dir := (ahead - to).normalized() if ahead != Vector3.INF else Vector3.FORWARD
		player().spawn_at(to, atan2(dir.x, dir.z))
		for i in FAMILY.size():
			_place_person(FAMILY[i], to + dir * (2.0 + FAMILY_GAP * float(i)) + Vector3(dir.z, 0.0, -dir.x) * (0.8 if i % 2 == 0 else -0.8), ahead)
		_send_family(_route.find(to) if _route.has(to) else 3)
		# Gecenin müziği söner; şildenin davulu ve ağız kopuzu yaklaştıkça yükselir (konumlu).
		music("")
		if days and days.has_method(&"minute"):
			var m := float(days.call(&"minute")) + CUT_MINUTES
			days.call(&"set_time", GameClock.hhmm(m))
		fade(0.0, CUT_FADE)
		E21Shots.shot(player(), "feast_road", 3.0))


func _send_family(_from_index: int) -> void:
	# Aile Çocuk'un ardından yürür (PrologueCast.Person.follow_player; hız oyuncunun koşusunu aşmaz, K105).
	for i in FAMILY.size():
		var p := person(FAMILY[i])
		if p:
			p.follow_player(FAMILY_GAP * float(i + 1))


func autoplay(bot: Node, delta: float) -> void:
	_bot_wait = maxf(_bot_wait - delta, 0.0)
	match phase:
		"gift":
			var act := interaction()
			if not act.is_empty() and _bot_wait <= 0.0:
				bot.call(&"halt")
				bot.call(&"press_e")
				_bot_wait = 0.8
			else:
				bot.call(&"go_to", E21Bot.next_point(days, player().global_position, target(player().global_position)), false)
		"walk":
			var gate := point(step.get("gate", "birch_gate"))
			bot.call(&"go_to", E21Bot.next_point(days, player().global_position, gate), false)
		_:
			bot.call(&"halt")


func _route_points() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for id: Variant in step.get("route", ["gol_road_start", "road_descent", "road_forest", "road_open", "ford", "birch_gate"]):
		var p := point(id)
		if p != Vector3.INF:
			out.append(p)
	return out


func _near_route_point(p: Vector3, id: String, r: float) -> bool:
	var q := point(id)
	return q != Vector3.INF and Vector2(p.x - q.x, p.z - q.z).length() <= r


func _place_person(id: String, at_p: Vector3, face_at: Vector3) -> void:
	var p := person(id)
	if p:
		p.place(at_p, face_at)
