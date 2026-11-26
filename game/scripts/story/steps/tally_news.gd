class_name TallyNews
extends ChildhoodStep
## Sayımın haberi (adım türü tally_news; K110, story.md §5 «İki yeni gün»; Lan Hatun: «Sayımı obasına da söyle. Herkes duysun.»): Ebe
## Obası'nın üç kişisi işindedir (TallyCamp: kurut seren kadın Hereka'nın yurdunun önünde, at bağlayan adam, tayının yanındaki adam). Oyuncu
## her birinin yanında E'ye basar: Mete «Sayım öbür gün!» der, kişi işini bırakıp döner ve cevap verir (kişinin reply'ı: «Duyduk, duyduk.»,
## «Atlar semiz. Gelir sayılırız.», «Sayıcıya söyle, bizim tay da sayılsın.»), sonra işine döner. Üçü de duyunca Hereka kapısından seslenir:
## «Anana söyle: kurudu güzel olmuş.» (kurut teşekkürdür). Adım onun sözüyle biter. Hereka kapısının önünde durur.
## Veri: reach (E'nin erimi, m), lines {news, bye}, keeper, keeper_at, objectives {news}.

const KEEPER := "hereka_young"
const REACH := 2.8

var _camp: TallyCamp
var _talking := ""
var _left := 0.0
var _bye_left := -1.0
var _out_aligned := false


func start() -> void:
	phase = "news"
	_camp = TallyCamp.of(scene, true)
	if _camp and not _camp.is_built():
		_camp.build_all()
	var keeper := mover(str(step.get("keeper", KEEPER)))
	if keeper:
		keeper.go(points(step.get("keeper_route", ["hereka_door"])), pace(1.2))
	_update_objective()


func tick(delta: float) -> void:
	var p := player()
	if _camp:
		_camp.tick(delta, p.global_position, p.get_speed())
	match phase:
		"news":
			if not _talking.is_empty():
				BoneView.shoot(scene, "e21_tally_news")
				_left -= delta
				if _left <= 0.0 and (scene.voice == null or scene.voice.is_free()):
					_camp.release(_talking)
					_talking = ""
					_update_objective()
					if _camp.told_count() >= _camp.news_count():
						_say_bye()
		"bye":
			_bye_left -= delta
			if _bye_left <= 0.0:
				done()


func target(from: Vector3) -> Vector3:
	if phase != "news" or _camp == null or not _talking.is_empty():
		return Vector3.INF
	var id := _camp.nearest_untold(from, 400.0)
	return _camp.person(id).get("at", Vector3.INF) if not id.is_empty() else Vector3.INF


## Oyuncunun E'si: haber verilmemiş kişinin yanında «Haber ver».
func interaction() -> Dictionary:
	if phase != "news" or _camp == null or not _talking.is_empty():
		return {}
	var id := _camp.nearest_untold(player().global_position, float(step.get("reach", REACH)))
	if id.is_empty():
		return {}
	var labels: Dictionary = step.get("labels", {})
	return {"key": "E", "label": text(labels.get("news", {"tr": "Haber ver", "en": "Tell the news"})), "run": _tell.bind(id)}


func preset() -> void:
	var camp := TallyCamp.of(scene, true)
	if camp:
		camp.build_all()
		for id: String in camp.people:
			if not str((camp.people[id] as Dictionary).get("reply", "")).is_empty():
				camp.people[id]["told"] = true
	TallyErrand.hand_curd(scene.inventory)
	TallyErrand.take_stick(scene.inventory)


func cleanup() -> void:
	if _camp and not _talking.is_empty():
		_camp.release(_talking)


func autoplay(bot: Node, _delta: float) -> void:
	BoneView.diag_step(self)
	if phase != "news" or not _talking.is_empty():
		bot.call(&"halt")
		return
	# Yurdun içindeyse önce kapının ekseninden dışarı (kapı aralığı dardır): eksende içeride, sonra kapının dışı.
	var center := point(step.get("yurt", "hereka_yurt"))
	var door := point(step.get("door", "hereka_door"))
	if center != Vector3.INF and door != Vector3.INF and flat(player().global_position, center) < flat(door, center) - 0.3:
		var axis := Vector3(door.x - center.x, 0.0, door.z - center.z).normalized()
		if not _out_aligned:
			_out_aligned = bool(bot.call(&"follow", [center + axis * 1.0], "tally_out_a", false, 0.25))
		else:
			bot.call(&"follow", [center + axis * (flat(door, center) + 1.2)], "tally_out_b", false, 0.35)
		return
	var id := _camp.nearest_untold(player().global_position, 400.0)
	if id.is_empty():
		bot.call(&"halt")
		return
	var at: Vector3 = _camp.person(id)["at"]
	if near(at, float(step.get("reach", REACH)) * 0.75):
		bot.call(&"halt")
		bot.call(&"interact")
	else:
		bot.call(&"follow", [at], "tally_news_%s" % id, true)


static func check(p_step: Dictionary, data: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	var lines: Dictionary = data.get("lines", {})
	for key: String in ["news", "bye"]:
		var line := str((p_step.get("lines", {}) as Dictionary).get(key, ""))
		if not lines.has(line):
			out.append("%s: satır yok: %s" % [p_step.get("id", ""), key])
	var replies := 0
	for p: Variant in (data.get("camp", {}) as Dictionary).get("people", []):
		var reply := str((p as Dictionary).get("reply", ""))
		if reply.is_empty():
			continue
		replies += 1
		if not lines.has(reply):
			out.append("%s: cevap satırı yok: %s" % [p_step.get("id", ""), reply])
	if replies < 3:
		out.append("%s: obanın üç kişisi haber alır (%d)" % [p_step.get("id", ""), replies])
	return out


func line_keys() -> Array:
	return (step.get("lines", {}) as Dictionary).values()


func _tell(id: String) -> void:
	if not _talking.is_empty() or _camp == null:
		return
	var rec := _camp.person(id)
	if rec.is_empty() or bool(rec.get("told", false)):
		return
	_talking = id
	rec["told"] = true
	_camp.face_player(id, player().global_position)
	say(str((step.get("lines", {}) as Dictionary).get("news", "news")))
	_left = say(str(rec.get("reply", ""))) + 0.2


func _say_bye() -> void:
	phase = "bye"
	set_objective({})
	set_hint({})
	var keeper := mover(str(step.get("keeper", KEEPER)))
	if keeper and player():
		keeper.face(player().global_position)
	_bye_left = say(str((step.get("lines", {}) as Dictionary).get("bye", "bye"))) * 0.6


func _update_objective() -> void:
	var obj: Dictionary = step.get("objectives", {})
	var t := text(obj.get("news", {"tr": "Obaya sayımı haber ver", "en": "Tell the camp about the count"}))
	if _camp:
		set_objective("%s (%d/%d)" % [t, _camp.told_count(), _camp.news_count()])
	set_hint(obj.get("news_hint", {}))
