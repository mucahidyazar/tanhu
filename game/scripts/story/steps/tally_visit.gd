class_name TallyVisit
extends ChildhoodStep
## Hereka'nın yurdu (adım türü tally_visit; K110, story.md §5 «İki yeni gün»): köpekler tutuldu, Mete Hereka'ya yaklaşır. Kimin oğlu olduğunu
## söyler («Lan Hatun'un.»), Lan Hatun'un kurutunu verir («Anam gönderdi. Teşekkür için.»: kurut teşekkürdür; söz başlarken heybeden düşer,
## Hereka alır); Hereka hatırlar: altı güz önce kapıda onu kendisi saymıştır. Hereka yurduna yürür, Mete'yi içeri çağırır («Gir. Otlara
## dokunma; her biri bir doğum için.»; kapının önünde kuruyan otlar, içeride asılı otlar). İçeride (yurt çatısız diorama olur, K98: yukarıdan)
## Mete'nin doğduğu şafağı anlatır (dolunay batıyordu, güneş doğuyordu, Teoman ikisine de eğildi), yedi çentikli çeteleyi verir (Hereka'nın
## elinde görünür, Mete'nin heybesine girer). Köpekler yataklarına döner.
## Veri: keeper, near (Hereka'ya yaklaşma, m), inside {at, radius} (içeride oyuncunun yeri), keeper_route, keeper_speed, take_clip (kurudu
## alışı), give_clip (çeteleyi verişi), lines {name, give, counted, inside, memory, stick}, objectives {enter}.

const KEEPER := "hereka_young"
const NEAR := 3.2

var _camp: TallyCamp
var _left := 0.0
var _stick: TallyStick
var _remote: RemoteTransform3D
var _at_door := false
var _curd_given := false


func start() -> void:
	phase = "approach"
	_camp = TallyCamp.of(scene, true)
	if _camp and not _camp.is_built():
		_camp.build_all()


func tick(delta: float) -> void:
	var p := player()
	if _camp:
		_camp.tick(delta, p.global_position, p.get_speed())
	var lines: Dictionary = step.get("lines", {})
	var keeper := mover(str(step.get("keeper", KEEPER)))
	match phase:
		"approach":
			if keeper and near(keeper.position(), float(step.get("near", NEAR))):
				phase = "talk"
				set_objective({})
				set_hint({})
				keeper.face(p.global_position)
				say(str(lines.get("name", "name")))
				# Mete kurutu verir: söz başlarken torba heybeden düşer, Hereka alır (sözü düşse de torba verilir: bkz. gift).
				say(str(lines.get("give", "give")), func() -> bool:
					_hand_curd()
					return true)
				_left = say(str(lines.get("counted", "counted"))) + 0.3
		"talk":
			_left -= delta
			if _left <= 0.0 and _voice_free():
				phase = "walk_in"
				if _camp and _camp.dogs:
					_camp.dogs.calm()
				unpose(str(step.get("keeper", KEEPER)))
				if keeper:
					keeper.go(points(step.get("keeper_route", ["hereka_door", "hereka_yurt"])), pace(float(step.get("keeper_speed", 1.5))))
				say(str(lines.get("inside", "inside")))
				set_objective((step.get("objectives", {}) as Dictionary).get("enter", {"tr": "Hereka'nın yurduna gir", "en": "Go into Hereka's yurt"}))
		"walk_in":
			if near(point(step.get("keeper_after", "hereka_door")), 4.5):
				BoneView.shoot(scene, "e21_tally_door")
			if near(point((step.get("inside", {}) as Dictionary).get("at", "hereka_yurt")), float((step.get("inside", {}) as Dictionary).get("radius", 2.4))) and _voice_free():
				phase = "inside"
				set_objective({})
				if keeper:
					keeper.face(p.global_position)
				_left = say(str(lines.get("memory", "moon"))) + 0.2
		"inside":
			_left -= delta
			if _left <= 0.0 and _voice_free():
				phase = "gift"
				_hand_curd()
				_show_stick(true)
				if keeper and actor(str(step.get("keeper", KEEPER))):
					pose(str(step.get("keeper", KEEPER)), str(step.get("give_clip", "collect_object")))
				_left = say(str(lines.get("stick", "stick"))) + 0.2
		"gift":
			BoneView.shoot(scene, "e21_tally_stick")
			_left -= delta
			if _left <= 0.0 and _voice_free():
				TallyErrand.take_stick(scene.inventory)
				_show_stick(false)
				unpose(str(step.get("keeper", KEEPER)))
				done()


func target(_from: Vector3) -> Vector3:
	match phase:
		"approach":
			var keeper := mover(str(step.get("keeper", KEEPER)))
			return keeper.position() if keeper else Vector3.INF
		"walk_in":
			return point((step.get("inside", {}) as Dictionary).get("at", "hereka_yurt"))
	return Vector3.INF


func preset() -> void:
	var camp := TallyCamp.of(scene, true)
	if camp:
		camp.build_all()
		if camp.dogs:
			camp.dogs.call_out()
			camp.dogs.hold(Vector2.ZERO)
			camp.dogs.calm()
	TallyErrand.hand_curd(scene.inventory)
	TallyErrand.take_stick(scene.inventory)
	var keeper := mover(str(step.get("keeper", KEEPER)))
	if keeper:
		keeper.place(point(step.get("keeper_after", "hereka_door")), PI * 0.5)
	if player():
		player().spawn_at(point(step.get("keeper_after", "hereka_door")) + Vector3(2.5, 0.0, 0.5), -PI * 0.5)


func cleanup() -> void:
	_show_stick(false)


func autoplay(bot: Node, _delta: float) -> void:
	BoneView.diag_step(self)
	match phase:
		"approach":
			var keeper := mover(str(step.get("keeper", KEEPER)))
			if keeper:
				var at := keeper.position()
				bot.call(&"follow", [at], "tally_keeper_%d_%d" % [roundi(at.x), roundi(at.z)], false)
		"walk_in":
			# Kapının ekseninde dışarıdan içeri (kapı aralığı dardır): önce eksende kapının önü, sonra içerisi; her biri tek noktalı yol.
			var center := point((step.get("inside", {}) as Dictionary).get("at", "hereka_yurt"))
			var door := point(step.get("keeper_after", "hereka_door"))
			var axis := Vector3(door.x - center.x, 0.0, door.z - center.z).normalized()
			var reach_door := flat(door, center)
			if not _at_door:
				_at_door = bool(bot.call(&"follow", [center + axis * (reach_door + 1.1)], "tally_door", false, 0.25))
			elif _voice_free() or not near(center, reach_door + 0.4):
				bot.call(&"follow", [center + axis * 0.9], "tally_inside", false, 0.3)
			else:
				bot.call(&"halt")
		_:
			bot.call(&"halt")


static func check(p_step: Dictionary, data: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	var lines: Dictionary = data.get("lines", {})
	for key: String in ["name", "give", "counted", "inside", "memory", "stick"]:
		var line := str((p_step.get("lines", {}) as Dictionary).get(key, ""))
		if not lines.has(line):
			out.append("%s: satır yok: %s" % [p_step.get("id", ""), key])
	return out


func line_keys() -> Array:
	return (step.get("lines", {}) as Dictionary).values()


func _voice_free() -> bool:
	return scene.voice == null or scene.voice.is_free()


## Kurut Hereka'ya geçer (bir kez): heybeden düşer, Hereka kısa bir alış hareketiyle alır.
func _hand_curd() -> void:
	if _curd_given:
		return
	_curd_given = true
	TallyErrand.hand_curd(scene.inventory)
	var id := str(step.get("keeper", KEEPER))
	var clip := str(step.get("take_clip", "collect_object"))
	if not clip.is_empty() and actor(id):
		pose(id, clip)
		at(clock + float(step.get("take_s", 1.2)), func() -> void:
			if phase in ["talk", "approach"]:
				unpose(id))


## Hereka'nın elindeki çetele (kodla çizilmiş çubuk; sağ eline bağlı). Mete alınca kaybolur (heybede).
func _show_stick(on: bool) -> void:
	if not on:
		if is_instance_valid(_remote):
			_remote.queue_free()
		if is_instance_valid(_stick):
			_stick.queue_free()
		_remote = null
		_stick = null
		return
	var a := actor(str(step.get("keeper", KEEPER)))
	if a == null or a.avatar == null or _camp == null:
		return
	var skeleton := a.avatar.get_skeleton()
	if skeleton == null or skeleton.find_bone("RightHand") < 0:
		return
	_stick = TallyStick.new()
	_stick.name = "HerekaTally"
	_stick.notches = TallyErrand.notches()
	_camp.add_child(_stick)
	_stick.build()
	var attach := skeleton.get_node_or_null(^"TallyHand") as BoneAttachment3D
	if attach == null:
		attach = BoneAttachment3D.new()
		attach.name = "TallyHand"
		attach.bone_name = "RightHand"
		skeleton.add_child(attach)
	_remote = RemoteTransform3D.new()
	_remote.name = "TallyRemote"
	_remote.update_scale = false
	_remote.position = Vector3(0.0, 0.06, 0.03)
	attach.add_child(_remote)
	_remote.remote_path = _remote.get_path_to(_stick)
