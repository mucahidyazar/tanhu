class_name GestureDedupe
extends RefCounted
## Dokunmatik yüzey jestinin ikinci kopyasını ayıklar. Godot 4.7.2'de Input'tan geçen jest (iz dörtgeninin gerçek olayı da,
## Input.parse_input_event de) dinleyiciye iki kez varır: iki ayrı kopya, aynı değerler, aynı karede. İkincisi yok sayılmazsa
## kıstırma ve iki parmakla kaydırma iki kat hızlı yakınlaşır. Haritanın sayfası (HudMapPage), takip kamerası (FollowCamera) ve
## oluşturucunun döner tablası (CreatorTurntable) birer tane taşır.

var _last := ""


## Bu olay az önceki jestin ikinci kopyası mı? Tek kopya yine işlenir; aynı karede üçüncü kez gelen yeni bir jest sayılır.
func repeated(g: InputEventGesture) -> bool:
	var key := "%s|%s|%.1f|%.1f|%d" % [g.get_class(), _value(g), g.position.x, g.position.y, Engine.get_process_frames()]
	if key == _last:
		_last = ""
		return true
	_last = key
	return false


static func _value(g: InputEventGesture) -> String:
	if g is InputEventMagnifyGesture:
		return "%.5f" % (g as InputEventMagnifyGesture).factor
	if g is InputEventPanGesture:
		var d := (g as InputEventPanGesture).delta
		return "%.5f,%.5f" % [d.x, d.y]
	return ""
