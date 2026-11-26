class_name SleepStep
extends ChildhoodStep
## Uyku ve günün sonu (E21, K110; tür «sleep»; docs/design/d3/e21-childhood-api.md §3): her Çocukluk günü Lan Hatun'un yurdunda uykuyla biter.
## Oyuncu yurda girince yurt diorama olur (K98: dış kabuk ve çatı gizlenir, içerisi yukarıdan görünür), yatağın yanında E «Uyu»: çocuk yatağa
## uzanır (Sleep_Normally; kütüphanenin sleep_normally'si), bir an sonra perde kararır, adım biter; günün son adımıysa sahne biter ve main.gd
## sıradaki günü kara perdede kendi kartıyla açar. Kişiler (sleepers) adım başında kendi yataklarına yatar (Lan Hatun döşeğinde).
## Veri: bed (işaret; varsayılan lan_bed), radius (E'nin erimi, m), yurt (diorama olan yer; varsayılan lan_yurt), yaw_deg (yatışın yönü;
## yoksa yatağın işaretinden yurdun ortasına dik), sleepers [{actor, at, yaw_deg, clip}], lie_s (uzandıktan sonra kararmaya dek), fade_s, hold_s.
## Kapı darsa takılmasın: kapının önünde (dışarıdan DOOR_REACH metreye dek) yurda yürüyen oyuncu kapının eksenine yavaşça kayar (DOOR_SLIDE
## m/sn); bot kapının eksenindeki iki noktadan (dışı, içi) girer.

const DEFAULT_BED := "lan_bed"
const DEFAULT_YURT := "lan_yurt"
const SLEEP_CLIP := "sleep_normally"
## Yurdun içi sayılan yarıçap (yurdun yarıçapına oran).
const INSIDE_RATIO := 0.92
## Kapının yönlendirmesi: duvarın dışında bu kadar metreye dek, eksenden en çok DOOR_SIDE metre yanda; kayma hızı (m/sn).
const DOOR_REACH := 3.4
const DOOR_SIDE := 2.6
const DOOR_SLIDE := 1.8

var _yurt := ""
var _lying := false
var _left := 0.0
var _dark := false
var _was_inside := false


func start() -> void:
	_yurt = str(step.get("yurt", DEFAULT_YURT))
	phase = "go"
	for s: Variant in step.get("sleepers", []):
		var e: Dictionary = s
		var id := str(e.get("actor", ""))
		var m := mover(id)
		var at_point := point(e.get("at"))
		if m and at_point != Vector3.INF:
			m.place(at_point, deg_to_rad(float(e.get("yaw_deg", 0.0))))
			pose(id, str(e.get("clip", SLEEP_CLIP)))


func tick(delta: float) -> void:
	var inside := _inside()
	if inside != _was_inside:
		_was_inside = inside
		var w := world()
		if w and w.has_method(&"set_yurt_diorama"):
			w.call(&"set_yurt_diorama", _yurt, inside or _lying)
	if not _lying:
		if not inside:
			_door_assist(delta)
		return
	_left -= delta
	if _left <= 0.0 and not _dark:
		_dark = true
		phase = "dark"
		var t := fade(1.0, float(step.get("fade_s", 1.6)))
		var hold_s := float(step.get("hold_s", 0.8))
		if t:
			t.tween_interval(hold_s)
			t.tween_callback(done)
		else:
			done()


func target(_from: Vector3) -> Vector3:
	return Vector3.INF if _lying else point(step.get("bed", DEFAULT_BED))


func interaction() -> Dictionary:
	if _lying or not near(point(step.get("bed", DEFAULT_BED)), float(step.get("radius", 1.4))):
		return {}
	return {"key": "E", "label": "Uyu", "run": lie_down}


## Yatağa uzanır: oyuncu durur, taşınan duruşa geçer (kendi yürüyüşü pozu ezmez), yatağın yerine ve yönüne konur, uyku klibi oynar.
func lie_down() -> void:
	if _lying:
		return
	_lying = true
	phase = "lie"
	var p := player()
	var bed := point(step.get("bed", DEFAULT_BED))
	p.set_active(false)
	p.carry(true)
	var yaw := deg_to_rad(float(step["yaw_deg"])) if step.has("yaw_deg") else _bed_yaw(bed)
	p.global_position = bed
	p.get_avatar().rotation.y = yaw
	p.get_avatar().play_job(SLEEP_CLIP)
	_left = float(step.get("lie_s", 1.4))
	var w := world()
	if w and w.has_method(&"set_yurt_diorama"):
		w.call(&"set_yurt_diorama", _yurt, true)


func cleanup() -> void:
	for s: Variant in step.get("sleepers", []):
		unpose(str((s as Dictionary).get("actor", "")))
	var w := world()
	if w and w.has_method(&"set_yurt_diorama"):
		w.call(&"set_yurt_diorama", _yurt, false)
	var p := player()
	if _lying and is_instance_valid(p):
		p.carry(false)
		p.get_avatar().set_locomotion(0.0)
		p.spawn_at(p.global_position, p.get_facing_yaw())
		p.set_active(true)


func preset() -> void:
	pass


func autoplay(bot: Node, _delta: float) -> void:
	if _lying:
		bot.call(&"halt")
		return
	var route: Array = ["lan_door", "lan_yurt_in", step.get("bed", DEFAULT_BED)]
	var axis := _door_axis()
	if not axis.is_empty():
		# Kapının ekseninden: önce dışarıdaki nokta, sonra eşiğin içi.
		var c: Vector3 = axis[0]
		var d: Vector3 = axis[1]
		var r: float = axis[2]
		route = [c + d * (r + 2.2), c + d * (r - 1.0), step.get("bed", DEFAULT_BED)]
	if bool(bot.call(&"follow", route, "sleep_bed", false, 0.9)):
		bot.call(&"halt")
		var d := interaction()
		if not d.is_empty():
			(d["run"] as Callable).call()


static func check(s: Dictionary, _data: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	for key in ["objective"]:
		if not s.get(key) is Dictionary:
			out.append("%s: %s iki dilde olmalı" % [s.get("id", ""), key])
	return out


## Kapının ekseni: [yurdun ortası (zeminde), kapının yönü (düzlemde, birim), yarıçap]; yurt yoksa boş.
func _door_axis() -> Array:
	var w := world()
	var yurt := w.call(&"place", _yurt) as Node3D if w and w.has_method(&"place") else null
	if yurt == null:
		return []
	var d := yurt.global_basis.z
	d.y = 0.0
	if d.length_squared() < 0.0001:
		return []
	var r := float(yurt.get(&"radius")) if yurt.get(&"radius") != null else 3.0
	return [yurt.global_position, d.normalized(), r]


## Kapının önünde yurda yürüyen oyuncu kapının eksenine kayar (dar kapıda kenara takılmasın).
func _door_assist(delta: float) -> void:
	var axis := _door_axis()
	var p := player()
	if axis.is_empty() or p == null:
		return
	var c: Vector3 = axis[0]
	var d := Vector2((axis[1] as Vector3).x, (axis[1] as Vector3).z)
	var r: float = axis[2]
	var rel := Vector2(p.global_position.x - c.x, p.global_position.z - c.z)
	var along := rel.dot(d)
	if along < r - 0.5 or along > r + DOOR_REACH:
		return
	var side := Vector2(-d.y, d.x)
	var lat := rel.dot(side)
	if absf(lat) < 0.1 or absf(lat) > DOOR_SIDE:
		return
	var v: Vector3 = p.velocity
	var flat_v := Vector2(v.x, v.z)
	if flat_v.length() < 0.3 or flat_v.dot(-d) <= 0.0:
		return
	var shift := -signf(lat) * minf(absf(lat), DOOR_SLIDE * delta)
	p.global_position += Vector3(side.x, 0.0, side.y) * shift


## Oyuncu yurdun içinde mi?
func _inside() -> bool:
	var w := world()
	if w == null or not w.has_method(&"place"):
		return false
	var yurt := w.call(&"place", _yurt) as Node3D
	if yurt == null:
		return false
	var r := float(yurt.get(&"radius")) if yurt.get(&"radius") != null else 3.0
	return flat(player().global_position, yurt.global_position) < r * INSIDE_RATIO


## Yatağın yönü: yurdun ortasından yatağa doğru doğrultuya dik (duvar boyunca uzanır).
func _bed_yaw(bed: Vector3) -> float:
	var w := world()
	var yurt := w.call(&"place", _yurt) as Node3D if w and w.has_method(&"place") else null
	if yurt == null:
		return 0.0
	var out := Vector2(bed.x - yurt.global_position.x, bed.z - yurt.global_position.z)
	return atan2(out.x, out.y) + PI * 0.5
