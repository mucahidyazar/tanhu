class_name TallyErrandStep
extends ChildhoodStep
## «Ebenin Çetelesi»nin sabahı (adım türü tally_errand; Çocukluk, 21 Eylül MÖ 228, 08:30; K110, story.md §5 «İki yeni gün»): Lan Hatun'un
## yurdunun önünde serin sabah. Lan Hatun bir torba kurut verir (kurut torbası heybeye girer: TallyErrand) ve isteğin nedenini söyler: sayım
## öbür gün, Hereka yeni doğanları sayar, çetelesi olmazsa sayıcı eksik yazar; sayımı Hereka'nın obasına da söylemek gerekir. Sözler
## sürerken Ebe Obası'nın kişileri, köpekleri ve eşyası kare kare kurulur (TallyCamp; yolda takılma olmaz). Adım sözler bitince biter (oyuncu
## istediği an yola çıkabilir: amaç baştan «Hereka'ya git»tir).
## Veri: lines {errand, why, news_task}, errand_at (sn), curd_at (söz başlayınca torbanın verilişi, sn).

var _queued := false
var _given := false
var _camp: TallyCamp


func start() -> void:
	phase = "talk"
	_camp = TallyCamp.of(scene, true)
	var lines: Dictionary = step.get("lines", {})
	at(float(step.get("errand_at", 1.2)), func() -> void:
		var lh := mover("lan_hatun")
		if lh and player():
			lh.face(player().global_position)
		say(str(lines.get("errand", "errand")))
		say(str(lines.get("why", "why")))
		say(str(lines.get("news_task", "news_task")))
		_queued = true)
	at(float(step.get("errand_at", 1.2)) + float(step.get("curd_at", 2.6)), _give_curd)


func tick(_delta: float) -> void:
	if _camp and not _camp.is_built():
		_camp.build_some()
	if clock > 4.0:
		BoneView.shoot(scene, "e21_tally_morning")
	if _queued and (scene.voice == null or scene.voice.is_free()) and (_camp == null or _camp.is_built()):
		_give_curd()
		done()


func target(_from: Vector3) -> Vector3:
	return point(step.get("goal", "ebe_call"))


func preset() -> void:
	var camp := TallyCamp.of(scene, true)
	if camp:
		camp.build_all()
	TallyErrand.give_curd(scene.inventory)


func autoplay(bot: Node, _delta: float) -> void:
	BoneView.diag_step(self)
	# Lan Hatun'u dinler (insan gibi), sonra yola çıkar.
	if not _queued or clock < float(step.get("errand_at", 1.2)) + 4.0:
		bot.call(&"halt")
		return
	bot.call(&"follow", points(step.get("route", ["ebe_call"])), "tally_errand", true)


static func check(p_step: Dictionary, data: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	var lines: Dictionary = data.get("lines", {})
	for key: String in ["errand", "why", "news_task"]:
		var line := str((p_step.get("lines", {}) as Dictionary).get(key, ""))
		if not lines.has(line):
			out.append("%s: satır yok: %s" % [p_step.get("id", ""), key])
	if not (data.get("camp", {}) as Dictionary).has("people"):
		out.append("%s: günün camp.people'ı yok" % p_step.get("id", ""))
	return out


func line_keys() -> Array:
	return (step.get("lines", {}) as Dictionary).values()


## Lan Hatun torbayı verir (bir kez; heybe yoksa söz yine akar).
func _give_curd() -> void:
	if _given:
		return
	_given = true
	TallyErrand.give_curd(scene.inventory)
