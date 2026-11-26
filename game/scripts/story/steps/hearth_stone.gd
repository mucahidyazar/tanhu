extends PrologueStep
## «Ocak»ın taşları (hearth_stone; Önsöz, 10 Nisan ikindisi; K110; story.md §3): derede büyük taş (stream_stones'un yanı) yarı gömülü durur.
## Yol yokuşun başında kısa bir kararmayla kısalır (Ağabey'le derenin kıyısına; saat 8 dk ileri). Çocuk taşı
## üç kez vurarak kırar (E; el taşıyla vuruş kodla yer tutucudur, son vuruşta sfx_stone_crack ve kırıntı), büyük taş üç ocak taşına ayrılır.
## Taşlar tek tek taşınır (E al: days.carry("stone"), yalnız yürüme; E koy): kıyıda bekleyen Ağabey'in keçe heybesine. Üçü heybeye girince
## Ağabey heybeyi omzuna alır; dönüş yolu kısa bir kararmayla kısalır (TRAVEL_CUT: saat 12 dk ileri, ikindi altını) ve ikisi orman kıyısında,
## odun demetinin yanındadır. Çocuk demeti kucağına alır (E), obaya, ocağın başına yürür; varınca adım biter (hearth_build taşları dizer).
## Tasarım boşluğu (K87): dere obadan ≈260 m uzaktadır; taşı tek tek obaya taşımak üç gidiş dönüş (≈1,5 km) ederdi. Taşlar tek tek taşınır,
## ama heybeye; heybeyi Ağabey getirir, ocakta taşlar yine tek tek dizilir. Yürünen yol da iki kararmayla kısalır: yokuş ve orman Şilde
## Gecesi'nde ve tipide yürünmüştür.

const HITS := 3
const STRIKE_GAP := 0.6
const STRIKE_S := 0.42
const REACH := 1.6
const SACK_REACH := 1.5
const CARRY_MODS := {"speed_k": 0.8, "can_run": false, "can_jump": false}
const WOOD_MODS := {"speed_k": 0.85, "can_run": false, "can_jump": false}
## Gidiş ve dönüşün kısaltması: perde (sn), saatin atlaması (oyun dk); gidiş yokuşun başında (road_descent'e bu kadar yaklaşınca, m) kısalır.
const CUT_FADE := 0.9
const CUT_MINUTES := 12.0
const OUT_MINUTES := 8.0
const OUT_CUT_R := 7.0
## Ocağın başına varıldı sayılan uzaklık (m).
const HOME_R := 4.0

var stones: Array[Dictionary] = []
var bagged := 0
var hits := 0

var _root: Node3D
var _big: Node3D
var _sack: Node3D
var _bundle: Node3D
var _gap := 0.0
var _strike_t := -1.0
var _carrying := -1
var _bot_wait := 0.0
var _out_cut := false
var _bot_log := 0.0


func start() -> void:
	HearthCold.ensure(days)
	_root = Node3D.new()
	_root.name = "E21Stones"
	(days.root() if days.root() else world()).add_child(_root)
	var at_p := point(step.get("stone_at", "stream_stones"))
	_big = HearthProps.big_stone_node()
	_root.add_child(_big)
	_big.global_position = at_p
	_sack = HearthProps.sack_node()
	_root.add_child(_sack)
	_sack.global_position = _sack_point()
	var brother := person("older_brother")
	if brother:
		brother.stop_follow()
		brother.walk([_sack_point() + Vector3(0.9, 0.0, 0.4)], pace(2.2), "stand", at_p)
	phase = "go"
	set_objective({"tr": "Dereye in, büyük taşı bul", "en": "Go down to the stream, find the big stone"})
	set_hint({"tr": "Yol dereye iner.", "en": "The road goes down to the stream."})


func tick(delta: float) -> void:
	HearthProps.release_if_moving(player())
	_gap = maxf(_gap - delta, 0.0)
	_bot_wait = maxf(_bot_wait - delta, 0.0)
	if _strike_t >= 0.0:
		_strike_t += delta
		HearthProps.chop_pose(player().get_avatar(), _strike_t / STRIKE_S)
		if _strike_t >= STRIKE_S:
			_strike_t = -1.0
			HearthProps.chop_pose(player().get_avatar(), 1.0)
	match phase:
		"go":
			if not _out_cut and near(point(step.get("descent", "road_descent")), OUT_CUT_R):
				_out_cut = true
				_outbound_cut()
				return
			if near(_big.global_position, 6.0):
				phase = "break"
				set_objective({"tr": "Büyük taşı kır", "en": "Break the big stone"})
				set_detail("%d/%d" % [hits, HITS])
		"home":
			if near(_hearth(), HOME_R):
				done()


func target(from: Vector3) -> Vector3:
	match phase:
		"go":
			var descent := point(step.get("descent", "road_descent"))
			return descent if not _out_cut and descent != Vector3.INF else _big.global_position
		"break":
			return _big.global_position
		"carry":
			if _carrying >= 0:
				return _sack_point()
			for s in stones:
				if not bool(s["bagged"]):
					return (s["node"] as Node3D).global_position
		"wood":
			return _bundle.global_position if is_instance_valid(_bundle) else Vector3.INF
		"home":
			return _hearth()
	return Vector3.INF


func interaction() -> Dictionary:
	if _gap > 0.0:
		return {}
	match phase:
		"break":
			if near(_big.global_position, REACH):
				return {"key": "E", "label": text({"tr": "Taşa vur", "en": "Strike the stone"}), "run": _strike}
		"carry":
			if _carrying >= 0:
				if near(_sack_point(), SACK_REACH):
					return {"key": "E", "label": text({"tr": "Heybeye koy", "en": "Put it in the bag"}), "run": _bag}
				return {}
			for i in stones.size():
				var s: Dictionary = stones[i]
				if not bool(s["bagged"]) and near((s["node"] as Node3D).global_position, REACH - 0.3):
					return {"key": "E", "label": text({"tr": "Taşı al", "en": "Lift the stone"}), "run": _lift.bind(i)}
		"wood":
			if is_instance_valid(_bundle) and near(_bundle.global_position, REACH):
				return {"key": "E", "label": text({"tr": "Odunu kucakla", "en": "Take up the wood"}), "run": _take_wood}
	return {}


func _strike() -> void:
	_gap = STRIKE_GAP
	hits += 1
	_strike_t = 0.0
	HearthProps.stone_chips(_root, _big.global_position)
	if hits < HITS:
		sfx("sfx_stone_set", _big.global_position, -4.0)
		set_detail("%d/%d" % [hits, HITS])
		return
	sfx("sfx_stone_crack", _big.global_position)
	E21Shots.shot(_root, "hearth_stone", 0.3)
	_big.visible = false
	# Taşlar vuranın yanına düşer (ulaşılır yer).
	var pl := player().global_position
	var toward := atan2(pl.z - _big.global_position.z, pl.x - _big.global_position.x)
	for k in 3:
		var a := toward + (float(k) - 1.0) * 0.9
		var node := HearthProps.hearthstone_node(k)
		_root.add_child(node)
		node.global_position = point([_big.global_position.x + cos(a) * 0.8, _big.global_position.z + sin(a) * 0.8])
		stones.append({"node": node, "bagged": false})
	phase = "carry"
	set_objective({"tr": "Üç taşı Ağabey'in heybesine taşı", "en": "Carry the three stones to your brother's bag"})
	set_detail("%d/3" % bagged)


func _lift(i: int) -> void:
	_gap = 0.5
	_carrying = i
	(stones[i]["node"] as Node3D).visible = false
	carry("stone")
	walk_mods(CARRY_MODS)
	HearthProps.play_player(player(), "collect_object")


func _bag() -> void:
	_gap = 0.5
	stones[_carrying]["bagged"] = true
	_carrying = -1
	bagged += 1
	carry("")
	walk_mods({})
	sfx("sfx_stone_set", _sack_point())
	set_detail("%d/3" % bagged)
	E21Shots.log("ocak: taş %d/3 heybede" % bagged)
	if bagged >= 3:
		result("stones", 3)
		_travel_cut()


## Gidiş yolu yokuşun başında kararmayla kısalır (yolu Şilde Gecesi'nde ve tipide yürüdü): Çocuk ve Ağabey derenin kıyısında, heybenin yanında.
func _outbound_cut() -> void:
	phase = "cut"
	await fade(1.0, CUT_FADE)
	var big := _big.global_position
	var sack := _sack_point()
	var stand := point([sack.x + (big.x - sack.x) * 0.45, sack.z + (big.z - sack.z) * 0.45])
	player().spawn_at(stand, atan2(big.x - stand.x, big.z - stand.z))
	var brother := person("older_brother")
	if brother:
		brother.place(sack + Vector3(0.9, 0.0, 0.4), big)
		brother.work("stand")
	if days and days.clock:
		jump_clock(days.minute() + OUT_MINUTES)
	await fade(0.0, CUT_FADE)
	phase = "go"


## Ağabey heybeyi omzuna alır; dönüş yolu kararmayla kısalır: ikisi orman kıyısında, demetin yanında.
func _travel_cut() -> void:
	phase = "cut"
	set_objective({})
	set_hint({})
	await fade(1.0, CUT_FADE)
	var bundle_at := _bundle_point()
	_bundle = (days.root() if days.root() else world()).find_child("WoodBundle", true, false) as Node3D
	if _bundle == null:
		_bundle = HearthProps.bundle_node()
		_root.add_child(_bundle)
		_bundle.global_position = bundle_at
	var stand := bundle_at + Vector3(-1.2, 0.0, 1.4)
	player().spawn_at(stand, atan2(_bundle.global_position.x - stand.x, _bundle.global_position.z - stand.z))
	var brother := person("older_brother")
	if brother:
		brother.place(stand + Vector3(1.6, 0.0, 0.8), _hearth())
		brother.follow_player(2.2)
	# Heybe Ağabey'in omzunda (görünüş: kişinin sırtında).
	if is_instance_valid(_sack) and brother and brother.actor:
		_sack.reparent(brother.actor, false)
		_sack.position = Vector3(-0.18, 1.05, -0.22)
		_sack.scale = Vector3.ONE * 0.85
	for s in stones:
		(s["node"] as Node3D).visible = false
	if days and days.clock:
		jump_clock(days.minute() + CUT_MINUTES)
	await fade(0.0, CUT_FADE)
	phase = "wood"
	set_objective({"tr": "Odunu al, ocağa dön", "en": "Take the wood, go back to the hearth"})
	set_hint({})


func _take_wood() -> void:
	_gap = 0.5
	if is_instance_valid(_bundle):
		_bundle.visible = false
	# Kucak odunu (altı parça demet) göğüs hizasında.
	var held := HearthProps.bundle_node()
	held.scale = Vector3.ONE * 0.8
	HearthProps.hold(days.root() if days.root() else world(), player(), held, "HeldWood", "Spine2", Vector3(0.0, -0.05, 0.28))
	walk_mods(WOOD_MODS)
	result("wood_carried", true)
	phase = "home"
	set_objective({"tr": "Ocağa dön", "en": "Back to the hearth"})
	E21Shots.shot(_root, "hearth_dusk_walk", 6.0)


## Geliştirme: sonraki adımdan açılınca taşlar heybede, odun Çocuk'un kucağında sayılır (ocağın başında bırakılır).
func preset() -> void:
	HearthCold.ensure(days)
	result("stones", 3)
	result("wood_carried", true)


func cleanup() -> void:
	HearthProps.release_player_job(player())
	if _carrying >= 0:
		carry("")
		walk_mods({})


func autoplay(bot: Node, _delta: float) -> void:
	if phase == "cut" or _strike_t >= 0.0 or _bot_wait > 0.0:
		bot.call(&"halt")
		return
	if not interaction().is_empty():
		bot.call(&"halt")
		bot.call(&"press_e")
		_bot_wait = 0.75
		return
	var t := target(player().global_position)
	_bot_log -= _delta
	if _bot_log <= 0.0:
		_bot_log = 4.0
		var pp := player().global_position
		E21Shots.log("ocak bot (taş): %s oyuncu (%.1f, %.1f) hedef %s duruş %d hız %.2f giriş %s etkin %s" % [phase, pp.x, pp.z, str(t),
			player().get_stance(), player().get_speed(), str(player().auto_move), player().is_active()])
	if t != Vector3.INF:
		bot.call(&"go_to", E21Bot.next_point(days, player().global_position, t), phase in ["go", "wood"])


func _sack_point() -> Vector3:
	if step.has("sack_at"):
		return point(step["sack_at"])
	var at_p := point(step.get("stone_at", "stream_stones"))
	var ford := point(step.get("bank", "ford"))
	var dir := (ford - at_p) if ford != Vector3.INF else Vector3(1.0, 0.0, 0.0)
	dir.y = 0.0
	return point([at_p.x + dir.normalized().x * 5.0, at_p.z + dir.normalized().z * 5.0])


func _bundle_point() -> Vector3:
	var edge := point(step.get("edge", "forest_edge"))
	return point(step.get("bundle_at", [edge.x + 0.8, edge.z - 1.6]))


func _hearth() -> Vector3:
	return point(step.get("hearth", "gol_fire"))
