extends PrologueStep
## «Şilde Gecesi»nin adımı (feast_roam; Önsöz, 9 Nisan gecesi, Kayın Obası; K110; story.md §3; e21-atmosphere.md): yeni doğanın ilk gecesi;
## büyük ateş, davul ve ağız kopuzu, el çırpan kadınlar, oturan yaşlılar, ateşin çevresinde kovalanan çocuklar (FeastWatch). Dolaşmak serbesttir;
## görev iki işle ilerler, sıra oyuncunundur:
##   kımız  Saruk ateşin başında seslenir («Gel kız. Bu kımız senin getirdiğin sütten. İki elinle al.»); sunmadan önce parmaklarıyla göğe, yere
##          ve ocağa serper («Önce Gök'e, sonra Yer'e, sonra ocağa.»; üç sfx_libation), kâseyi uzatır: E basılı (HOLD_S) Çocuk iki eliyle alır
##          ve içer (stand_and_drink, sfx_kumis_sip); Saruk «Ekşi mi? İlk kımız ekşi olur.»
##   kundak Künay'ın yurdunda (kunay_yurt; beşik ve beşiğe asılı küçük yay) kundak Künay'a verilir (E): «Ananın elinden mi? Daha ılık.»,
##          «Ateşi sen getirdin. Oğlum seni bilsin.»; Tonga beşiğin yayını anlatır: «Küçük yay beşikte durur. Büyüyünce kendisi gerer.»
## Arada obanın halkı tepki sözleri söyler (≥45 sn arayla). İkisi bitince güreş açılır (adım biter). Ceza yoktur.

const HOLD_S := 1.2
const DRINK_CLIP := "stand_and_drink"
## Saruk'un serpişi: [hedef, klip] (göğe, yere, ocağa) ve aralar (sn).
const LIBATION := [["sky", "wave_one_hand"], ["earth", "collect_object"], ["hearth", "crouch_pick_place_f"]]
const LIBATION_GAP := 1.35
## Saruk'a ve Künay'a yaklaşma erimi (m).
const SARUK_CALL_M := 7.5
const NEAR_M := 1.9

var watch: FeastWatch

var _kumis := "wait"
var _gift := "wait"
var _hold := 0.0
var _bowl: Node3D
var _libation_done := false
var _bot_wait := 0.0


func line_keys() -> Array:
	return ["act0.feast.saruk", "act0.feast.libation", "act0.feast.sour", "act0.feast.kunay_gift", "act0.feast.kunay",
		"act0.feast.tonga_bow"] + FeastWatch.BARKS.map(func(r: Array) -> String: return str(r[0]))


## Ailenin şildedeki yeri: [kimlik, ateşe göre açı (derece), uzaklık (m), iş].
const FAMILY_SPOTS := [["mother", 160.0, 3.6, "sit"], ["father", 128.0, 3.8, "sit"], ["older_brother", 95.0, 4.6, "talk"]]
## Kovalanan çocuklar: ateşin çevresinde halka (m), hız (m/sn; K105: Çocuk'un koşusunu aşmaz), aralarındaki açı (radyan).
const CHASE := ["birch_girl", "boru"]
const CHASE_R := 6.2
const CHASE_SPEED := 2.7
const CHASE_GAP := 0.7


func start() -> void:
	watch = FeastWatch.ensure(days.root() if days.root() else world(), point(step.get("fire", "feast_fire")), say, days.sound)
	HearthCold.ensure(days)
	_seat_family()
	_baby_in_cradle()
	phase = "roam"
	_refresh()
	E21Shots.shot(player(), "feast_fire", 2.5)


func cleanup() -> void:
	HearthProps.release_player_job(player())
	if is_instance_valid(_bowl):
		_bowl.queue_free()


func tick(delta: float) -> void:
	if watch:
		watch.tick(delta, player().global_position)
	_tick_chase(delta)
	_bot_wait = maxf(_bot_wait - delta, 0.0)
	# Saruk yaklaşan Çocuk'u çağırır, serper, kâseyi uzatır.
	if _kumis == "wait" and near(_saruk_at(), SARUK_CALL_M):
		_kumis = "libation"
		var t := say("act0.feast.saruk")
		at(clock + t + 0.2, _libation)
	if _kumis == "offer":
		var holding := Input.is_action_pressed(&"accept") or _bot_hold
		if holding and near(_saruk_at(), NEAR_M + 0.4):
			_hold += delta
			if _hold >= HOLD_S:
				_drink()
		else:
			_hold = maxf(_hold - delta * 2.0, 0.0)
		set_detail("" if _hold <= 0.0 else "%d%%" % int(round(100.0 * _hold / HOLD_S)))


var _bot_hold := false


func _libation() -> void:
	E21Shots.shot(player(), "feast_libation", 1.6)
	var t := say("act0.feast.libation")
	for i in LIBATION.size():
		var row: Array = LIBATION[i]
		at(clock + 0.3 + float(i) * LIBATION_GAP, func() -> void:
			_pose("saruk", str(row[1]))
			sfx("sfx_libation", _libation_point(str(row[0]))))
	at(clock + maxf(t, float(LIBATION.size()) * LIBATION_GAP) + 0.4, func() -> void:
		_kumis = "offer"
		_pose("saruk", "stand")
		_show_bowl()
		_refresh())


func _drink() -> void:
	_kumis = "drinking"
	E21Shots.log("şilde: kımız içildi")
	_hold = 0.0
	set_detail("")
	player().set_active(false)
	HearthProps.play_player(player(), DRINK_CLIP)
	_move_bowl_to_child()
	E21Shots.shot(player(), "feast_kumis", 0.8)
	sfx("sfx_kumis_sip", player().global_position + Vector3(0.0, 1.2, 0.0))
	at(clock + 2.6, func() -> void:
		HearthProps.release_player_job(player())
		player().set_active(true)
		if is_instance_valid(_bowl):
			_bowl.queue_free()
		var s := say("act0.feast.sour")
		at(clock + s + 0.3, func() -> void:
			_kumis = "done"
			result("kumis", true)
			_refresh()
			_maybe_done()))


func interaction() -> Dictionary:
	if _gift == "wait" and _kunay_near():
		return {"key": "E", "label": _t({"tr": "Kundağı ver", "en": "Give the swaddle"}), "run": _give}
	if _kumis == "offer" and near(_saruk_at(), NEAR_M + 0.4):
		return {"key": "E", "label": _t({"tr": "İki elinle al (basılı)", "en": "Take it with both hands (hold)"}), "run": func() -> void: pass}
	return {}


func _give() -> void:
	_gift = "talk"
	E21Shots.log("şilde: kundak Künay'a verildi")
	E21Shots.shot(player(), "feast_cradle", 0.6)
	HearthProps.release(days.root() if days.root() else world(), "HeldSwaddle")
	result("swaddle_given", true)
	var t := say_seq(["act0.feast.kunay_gift", "act0.feast.kunay"])
	at(clock + t + 0.3, func() -> void:
		var b := say("act0.feast.tonga_bow")
		at(clock + b + 0.3, func() -> void:
			_gift = "done"
			_refresh()
			_maybe_done()))
	_refresh()


func _maybe_done() -> void:
	if _kumis == "done" and _gift == "done":
		at(clock + 0.8, done)


func target(_from: Vector3) -> Vector3:
	if _kumis in ["wait", "offer"]:
		return _saruk_at()
	if _gift == "wait":
		return point(step.get("kunay", "kunay_cradle"))
	return Vector3.INF


func _refresh() -> void:
	if _kumis == "offer":
		set_objective({"tr": "Kımızı iki elinle al", "en": "Take the kumis with both hands"})
		set_hint({"tr": "E basılı tut.", "en": "Hold E."})
		return
	if _kumis == "wait" and _gift == "wait":
		set_objective({"tr": "Şildede dolaş", "en": "Join the watch-night"})
		set_hint({"tr": "Saruk ateşin başında; Künay yurdunda.", "en": "Saruk is by the fire; Kunay is in her yurt."})
	elif _gift == "wait":
		set_objective({"tr": "Kundağı Künay'a ver", "en": "Give the swaddle to Kunay"})
		set_hint({"tr": "Künay yurdunda, beşiğin yanında.", "en": "Kunay is in her yurt, by the cradle."})
	elif _kumis in ["wait", "libation"]:
		set_objective({"tr": "Saruk'un yanına git", "en": "Go to Saruk"})
		set_hint({"tr": "Ateşin başında.", "en": "By the fire."})
	else:
		set_objective({})
		set_hint({})


func autoplay(bot: Node, delta: float) -> void:
	_bot_hold = false
	if _kumis == "offer":
		if near(_saruk_at(), NEAR_M):
			bot.call(&"halt")
			_bot_hold = true
		else:
			bot.call(&"go_to", E21Bot.next_point(days, player().global_position, _saruk_at()), false)
		return
	if _kumis in ["libation", "drinking"] or _gift == "talk":
		bot.call(&"halt")
		return
	if _kumis == "wait":
		bot.call(&"go_to", E21Bot.next_point(days, player().global_position, _saruk_at()), true)
		return
	if _gift == "wait":
		if not interaction().is_empty() and _bot_wait <= 0.0:
			bot.call(&"halt")
			bot.call(&"press_e")
			_bot_wait = 1.0
		else:
			bot.call(&"go_to", E21Bot.next_point(days, player().global_position, _kunay_at()), false)
		return
	bot.call(&"halt")


# --- Şildenin yaşamı ------------------------------------------------------------------------------

## Aile ateşin halkasına katılır: Ana ile Baba oturur, Ağabey ayakta konuşur.
func _seat_family() -> void:
	var fire := point(step.get("fire", "feast_fire"))
	for row: Array in FAMILY_SPOTS:
		var p := person(str(row[0]))
		if p == null:
			continue
		var a := deg_to_rad(float(row[1]))
		var spot := point([fire.x + cos(a) * float(row[2]), fire.z + sin(a) * float(row[2])])
		p.stop_follow()
		p.walk([spot], pace(1.3), str(row[3]), fire)


## Künay'ın oğlu beşikte (kundaklı bebeğin Meshy eşyası; beşik ve yayı Ö1'in): şilde onun gecesidir.
func _baby_in_cradle() -> void:
	var cradle: Node3D = places().cradle if places() else null
	if cradle == null or cradle.get_node_or_null(^"Baby") != null or not MeshyProp.exists("props", "swaddled_baby"):
		return
	var baby := MeshyProp.new()
	baby.name = "Baby"
	baby.model_id = "swaddled_baby"
	baby.folder = "props"
	baby.size_axis = 1
	baby.target_size = 0.5
	baby.position = Vector3(0.0, 0.34, 0.0)
	cradle.add_child(baby)


var _chase_a := 0.0


## Çocuklar ateşin çevresinde kovalanır (kız önde, Börü ardında); güreş başlayınca Börü halkaya gider.
func _tick_chase(delta: float) -> void:
	var fire := point(step.get("fire", "feast_fire"))
	if fire == Vector3.INF:
		return
	_chase_a = fposmod(_chase_a + delta * CHASE_SPEED / CHASE_R, TAU)
	for i in CHASE.size():
		var p := person(CHASE[i])
		if p == null or not p.is_present():
			continue
		if p.is_walking() and PrologueStep.flat(p.position(), _chase_point(fire, _chase_a - float(i) * CHASE_GAP)) > 2.2:
			continue
		# Önündeki noktaya koşar (yürütücü yolu kısa tutar: dairede kalır).
		p.walk([_chase_point(fire, _chase_a - float(i) * CHASE_GAP + 0.45)], pace(CHASE_SPEED), "", Vector3.INF)


func _chase_point(fire: Vector3, a: float) -> Vector3:
	return point([fire.x + cos(a) * CHASE_R, fire.z + sin(a) * CHASE_R])


# --- Yardımcılar ---------------------------------------------------------------------------------

func _saruk_at() -> Vector3:
	var s := actor("saruk")
	return s.global_position if s else point(step.get("saruk_at", "feast_fire"))


func _kunay_at() -> Vector3:
	var k := actor("kunay")
	return k.global_position if k else point(step.get("kunay", "kunay_cradle"))


func _kunay_near() -> bool:
	return near(_kunay_at(), NEAR_M + 0.3)


func _libation_point(kind: String) -> Vector3:
	var s := _saruk_at()
	match kind:
		"sky":
			return s + Vector3(0.0, 2.2, 0.0)
		"earth":
			return s + Vector3(0.0, 0.1, 0.0)
	return point(step.get("fire", "feast_fire")) + Vector3(0.0, 0.4, 0.0)


## Kişinin işi (PrologueCast.Person.work: iş sürerken yürütücü klibi ezmez); "stand" ayakta durur.
func _pose(id: String, clip: String) -> void:
	var p := person(id)
	if p:
		p.work(clip)


## Saruk'un elindeki tahta kâse (kodla): kucak hizasında.
func _show_bowl() -> void:
	var s := actor("saruk")
	if s == null:
		return
	_bowl = _bowl_mesh()
	s.add_child(_bowl)
	_bowl.position = Vector3(0.0, 1.05, 0.32)


## Tahta kâse ve içinde kımız (kodla).
func _bowl_mesh() -> Node3D:
	var root := Node3D.new()
	root.name = "KumisBowl"
	var cup := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.09
	mesh.bottom_radius = 0.055
	mesh.height = 0.07
	cup.mesh = mesh
	cup.material_override = Style.toon(Style.WOOD.lightened(0.1), {"brush_strength": 0.2})
	root.add_child(cup)
	var milk := MeshInstance3D.new()
	milk.mesh = MeshKit.disc(0.082, 0.0, 14)
	milk.material_override = Style.toon(Color(0.93, 0.9, 0.82))
	milk.position = Vector3(0.0, 0.03, 0.0)
	root.add_child(milk)
	return root


## Kâse Çocuk'un ellerine geçer (koşucunun Held'i: sağ elin kemiğini izler).
func _move_bowl_to_child() -> void:
	if is_instance_valid(_bowl):
		_bowl.queue_free()
	_bowl = HearthProps.hold(days.root() if days.root() else world(), player(), _bowl_mesh(), "HeldBowl", "RightHand", Vector3(0.0, 0.04, 0.09))


func _t(entry: Dictionary) -> String:
	return str(entry.get(SubtitleBar.ui_lang(), entry.get("tr", "")))
