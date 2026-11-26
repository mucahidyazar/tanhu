extends PrologueStep
## «Ocak»ın odunu (hearth_wood; Önsöz, 10 Nisan ikindisi; K110; story.md §3): Baba «Kuru dal orman kıyısında. Yaş odun yalnız duman eder.»
## Orman kıyısında (forest_edge) iki kuru kütük yatar; Çocuk baltayla her kütüğe üç kez vurur (E; vuruş kodla yer tutucudur: gövde öne iner,
## balta kalkar; gerçek klip onayla gelir: Charged_Axe_Chop 237 → CHOP_CLIP), üçüncü vuruşta kütük üç parçaya ayrılır. Altı parça tek tek
## toplanır (E; collect_object). Ağabey kıyıya gelir, yanında durur; altı parça toplanınca «Bu kadar odunla sabaha dek yanar.» der, sonra
## «Derede taş çok. Büyüğünü kır, üçünü getir.» Odun demeti yolun kıyısında bekler (dönüşte alınır: hearth_stone), adım biter.
## Yerler: forest_edge (işaret), kütüklerin yeri adımın logs'u ([x, z] ya da işarete göre [dx, dz]); yoksa kıyıya göre iki yer.

## Kütük başına vuruş, kütük sayısı ve kütükten çıkan parça (2 × 3 = 6).
const HITS := 3
const PIECES := 3
## Vuruşun erimi (m), vuruşlar arası en az süre (sn) ve yer tutucu vuruşun süresi (sn).
const CHOP_REACH := 1.6
const CHOP_GAP := 0.55
const CHOP_S := 0.42
const CHOP_CLIP := ""
const PICK_REACH := 1.7
const PICK_CLIP := "collect_object"

var logs: Array[Dictionary] = []
var pieces: Array[Dictionary] = []
var picked := 0

var _root: Node3D
var _gap := 0.0
var _chop_t := -1.0
var _bundle: Node3D
var _bot_wait := 0.0
var _bot_log := 0.0
var _said := false


func line_keys() -> Array:
	return ["act0.hearth.bard", "act0.hearth.ana", "act0.hearth.wood", "act0.hearth.wood_done", "act0.hearth.stone"]


func start() -> void:
	# Ocak tipinin çatlattığı hâlde (geliştirmede gün 3'ten açılınca da).
	HearthCold.ensure(days)
	# İstemin nedeni: ozanın gecesi; ateşi Çocuk kuracak, odun orman kıyısında.
	var intro: Array = step.get("intro", [])
	if not intro.is_empty():
		for i in intro.size():
			var id := str(intro[i])
			var who := person(days.speaker_of(id))
			at(clock + 0.6 + float(i) * 0.1, func() -> void:
				if who:
					who.face_point(player().global_position)
				say(id))
	_root = Node3D.new()
	_root.name = "E21Wood"
	(days.root() if days.root() else world()).add_child(_root)
	var edge := point(step.get("edge", "forest_edge"))
	var spots: Array = step.get("logs", [[1.6, -1.2], [-1.4, 0.9]])
	for i in spots.size():
		var o: Array = spots[i]
		var at_p := point([edge.x + float(o[0]), edge.z + float(o[1])])
		var node := HearthProps.log_node(i)
		_root.add_child(node)
		node.global_position = at_p
		node.rotation.y = 0.6 + float(i) * 1.9
		logs.append({"at": at_p, "hits": 0, "node": node})
	var brother := person("older_brother")
	if brother and not logs.is_empty():
		var near_log: Vector3 = logs[0]["at"]
		brother.walk([near_log + Vector3(1.6, 0.0, 1.2)], pace(1.6), "stand", near_log)
	phase = "chop"
	_refresh()


func cleanup() -> void:
	# Demet ve kütükler sahnede kalır (dönüşte alınır); kök koşucuyla silinir.
	HearthProps.release_player_job(player())


func tick(delta: float) -> void:
	HearthProps.release_if_moving(player())
	_gap = maxf(_gap - delta, 0.0)
	_bot_wait = maxf(_bot_wait - delta, 0.0)
	if _chop_t >= 0.0:
		_chop_t += delta
		HearthProps.chop_pose(player().get_avatar(), _chop_t / CHOP_S)
		if _chop_t >= CHOP_S:
			_chop_t = -1.0
			HearthProps.chop_pose(player().get_avatar(), 1.0)


func target(from: Vector3) -> Vector3:
	match phase:
		"chop":
			var best := Vector3.INF
			for l in logs:
				if int(l["hits"]) < HITS and (best == Vector3.INF or flat(l["at"], from) < flat(best, from)):
					best = l["at"]
			if best != Vector3.INF:
				return best
			for p in pieces:
				if not bool(p["taken"]) and (best == Vector3.INF or flat(p["at"], from) < flat(best, from)):
					best = p["at"]
			return best
	return Vector3.INF


func interaction() -> Dictionary:
	if phase != "chop" or _gap > 0.0:
		return {}
	var p := player().global_position
	for p_i in pieces.size():
		var piece: Dictionary = pieces[p_i]
		if not bool(piece["taken"]) and flat(piece["at"], p) <= PICK_REACH:
			return {"key": "E", "label": text({"tr": "Odunu al", "en": "Pick up the wood"}), "run": _pick.bind(p_i)}
	for i in logs.size():
		var l: Dictionary = logs[i]
		if int(l["hits"]) < HITS and flat(l["at"], p) <= CHOP_REACH:
			return {"key": "E", "label": text({"tr": "Baltayla vur", "en": "Strike with the axe"}), "run": _chop.bind(i)}
	return {}


func _chop(i: int) -> void:
	var l: Dictionary = logs[i]
	_gap = CHOP_GAP
	l["hits"] = int(l["hits"]) + 1
	_chop_t = 0.0
	E21Shots.shot(_root, "hearth_wood", 0.15)
	if CHOP_CLIP.is_empty():
		HearthProps.release_player_job(player())
	else:
		HearthProps.play_player(player(), CHOP_CLIP)
	_face(l["at"])
	sfx("sfx_axe_chop", l["at"])
	HearthProps.chips(_root, l["at"])
	if int(l["hits"]) >= HITS:
		var node: Node3D = l["node"]
		node.visible = false
		# Parçalar Çocuk'un durduğu yana düşer (vuranın önüne; ulaşılır yer).
		var pl := player().global_position
		var toward := atan2(pl.z - float(l["at"].z), pl.x - float(l["at"].x))
		for k in PIECES:
			var a := toward + (float(k) - 1.0) * 0.8
			var at_p := point([float(l["at"].x) + cos(a) * 0.75, float(l["at"].z) + sin(a) * 0.75])
			var piece := HearthProps.piece_node(i * PIECES + k)
			_root.add_child(piece)
			piece.global_position = at_p
			piece.rotation.y = a * 1.7
			pieces.append({"at": at_p, "taken": false, "node": piece})
	_refresh()


func _pick(p_i: int) -> void:
	var piece: Dictionary = pieces[p_i]
	_gap = 0.7
	piece["taken"] = true
	(piece["node"] as Node3D).visible = false
	picked += 1
	_face(piece["at"])
	HearthProps.play_player(player(), PICK_CLIP)
	_refresh()
	if picked >= logs.size() * PIECES:
		_all_gathered()


func _all_gathered() -> void:
	E21Shots.log("ocak: altı parça odun toplandı")
	phase = "talk"
	result("wood", picked)
	# Demet yolun kıyısında bekler.
	_bundle = HearthProps.bundle_node()
	_root.add_child(_bundle)
	var edge := point(step.get("edge", "forest_edge"))
	_bundle.global_position = point(step.get("bundle_at", [edge.x + 0.8, edge.z - 1.6]))
	var brother := person("older_brother")
	if brother:
		brother.face_point(player().global_position)
	var t := say_seq(["act0.hearth.wood_done", "act0.hearth.stone"])
	set_objective({})
	set_hint({})
	at(clock + t + 0.4, done)


func _refresh() -> void:
	if phase != "chop":
		return
	var chopped := 0
	for l in logs:
		if int(l["hits"]) >= HITS:
			chopped += 1
	if chopped < logs.size() and pieces.size() - picked == 0:
		set_objective({"tr": "Kuru kütükleri baltayla kır", "en": "Split the dry logs with the axe"})
	else:
		set_objective({"tr": "Odunu topla", "en": "Gather the wood"})
	set_detail("%d/%d" % [picked, logs.size() * PIECES])


func _face(p: Vector3) -> void:
	var pl := player()
	var d := Vector3(p.x - pl.global_position.x, 0.0, p.z - pl.global_position.z)
	if d.length() > 0.05:
		pl.spawn_at(pl.global_position, atan2(d.x, d.z))


func autoplay(bot: Node, _delta: float) -> void:
	if phase != "chop":
		bot.call(&"halt")
		return
	if _bot_wait > 0.0 or _chop_t >= 0.0:
		bot.call(&"halt")
		return
	if not interaction().is_empty():
		bot.call(&"halt")
		bot.call(&"press_e")
		_bot_wait = CHOP_GAP + 0.15
		return
	var t := target(player().global_position)
	_bot_log -= _delta
	if _bot_log <= 0.0:
		_bot_log = 4.0
		var pp := player().global_position
		E21Shots.log("ocak bot (odun): oyuncu (%.1f, %.1f) hedef %s" % [pp.x, pp.z, str(t)])
	if t != Vector3.INF:
		bot.call(&"go_to", E21Bot.next_point(days, player().global_position, t), true)


## Geliştirme: sonraki adımdan açılınca odun toplanmış, demet orman kıyısında (hearth_stone dönüşte alır).
func preset() -> void:
	result("wood", 6)
	HearthCold.ensure(days)
