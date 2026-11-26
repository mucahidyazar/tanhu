extends PrologueStep
## «Güreş»in sonu ve eve dönüş (feast_home; Önsöz, 9 Nisan gecesi; K110): Ana yarını söyler («Yarın ocağı sen kur. Ozan uzun söyleyecek.»), aile
## yola döner; söz bitince perde yavaşça kararır, şildenin sahnesi (FeastWatch: büyük ateş, müzik, uğultu) karanlıkta sessizce kalkar ve adım
## biter; sıradaki night_end günü bitirir (10 Nisan'ın kartı). Kalkış karanlıkta olur: ertesi gün Göl Obası'nda şildenin sesi duyulmaz.

const FAMILY: Array[String] = ["mother", "father", "older_brother"]
const FADE_S := 1.8


func line_keys() -> Array:
	return ["act0.wrestle.home"]


func start() -> void:
	set_objective({})
	set_hint({})
	var road := point(step.get("road", "birch_gate"))
	for id in FAMILY:
		var p := person(id)
		if p:
			p.stop_follow()
			if road != Vector3.INF:
				p.walk([road], 1.3, "", Vector3.INF)
	var t := say("act0.wrestle.home")
	at(clock + maxf(t, 1.0) + 0.6, _leave)


func _leave() -> void:
	await fade(1.0, FADE_S)
	var parent: Node = days.root() if days.root() else world()
	var w := parent.get_node_or_null(^"ShildeWatch") as FeastWatch if parent else null
	if w:
		w.teardown()
		w.queue_free()
	var m := FeastWatch.music_node(parent)
	if m:
		m.queue_free()
	done()


func autoplay(bot: Node, _delta: float) -> void:
	bot.call(&"halt")
