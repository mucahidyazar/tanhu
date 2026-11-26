class_name RiderColumn
extends RefCounted
## Atlı düzeni (story.md §5 «Teoman atlılarıyla geçer, çocuğa dört saniye bakar, durmaz»; K98): önde lider (Teoman), arkasında beyler; hepsi ata
## binmiştir (StoryMover + RideableHorse: adım, tırıs ve dörtnal klipleri ile toynak tozu, izi ve sesi atın kendisinden). Yol yumuşak bir eğridir
## (Curve2D, x z); lider yolda s metrededir, her üye liderin back metre gerisinde ve yolun normalinde side metre yanındadır (side > 0: liderin
## solu), yönü yolun teğetidir. Hız profili: yaklaşırken approach, geçiş noktasına (pass_at) pass hızına inerek varır (frenleme eğrisi; durmaz),
## bırakılınca (release) leave hızına çıkar. Liderin bakışı (look): omurgadan başa dağılan dönüş (CineBow, «up» ekseni) hedefe çevrilir, etkisi
## look_amount ile açılır; açı her kare yeniden hesaplanır (geçerken baş çocuğu izler). Yolun sonunu geçen üye gizlenir.
## Hız sınırı (E20; PaceLimit): kıvrımın dışındaki üye liderden hızlı gider (stretch: en büyük oran); limit_speeds(cap) üç hızı en hızlı üye
## cap'i (oyuncunun koşusu) aşmayacak kadar indirir. Atlı da oyuncudan hızlı gitmez.
##   var column := RiderColumn.new(PackedVector2Array([...]), world.get_terrain_shape())
##   column.add(teoman_mover, Vector2.ZERO); column.add(bey_mover, Vector2(-1.7, 3.4))
##   column.limit_speeds(PaceLimit.run_cap(player))       # üyeler eklendikten sonra
##   column.pass_at = column.closest_offset(Vector2(child.x, child.z)) - 2.5
##   column.start(column.start_offset_for(9.5))       # 9,5 sn sonra geçiş noktasında
##   column.tick(delta)                               # her kare
##   column.look = child_head; column.look_amount = 1.0
##   column.release()                                 # geçip gider

## Varsayılan hızlar (m/sn): tırısla gelir, adımla geçer, tırısla gider (RideableHorse.role_for: adım < 2,6 ≤ tırıs < 6,2). Tırıs 3,1'dir: atlı
## çocuğun koşusunu (3,6) kıvrımın dışında da aşmaz (E20; limit_speeds yolun kıvrımına göre ayrıca indirir).
const APPROACH := 3.1
const PASS := 1.25
const LEAVE := 3.1
## Hızlanma ve frenleme (m/sn²).
const ACCEL := 1.5
## Yolun pişirme aralığı (m) ve teğet ölçüsü (m).
const BAKE := 0.2
const TANGENT_SPAN := 0.6
## Bakışın en büyük açısı (derece) ve kemiklere dağılışı (alttan üste; payların toplamı 1).
const LOOK_MAX := 85.0
const LOOK_SHARES := [["Spine02", 0.14], ["Spine01", 0.18], ["Spine", 0.18], ["neck", 0.22], ["Head", 0.28]]
## Bakışın göz yüksekliği (m, binicinin kalçasının üstünde) ve hedefinkinin yerden yüksekliği.
const LOOK_EYE := 0.75
## Bakış düzeltmesinin düğüm adı.
const LOOK_NODE := "CineLook"

## Hızlar ve hızlanma.
var approach := APPROACH
var pass_speed := PASS
var leave := LEAVE
var accel := ACCEL
## Geçiş noktası (yolda, m): lider buraya pass hızıyla varır.
var pass_at := 0.0
## Liderin bakış hedefi (dünya; Vector3.INF: yok) ve etkisi (0..1).
var look := Vector3.INF
var look_amount := 0.0

## Liderin yoldaki yeri (m) ve hızı (m/sn).
var s := 0.0
var speed := 0.0
var running := false
var released := false
## Son hesaplanan bakış açısı (derece; + sol; sınama okur).
var look_deg := 0.0

var _curve := Curve2D.new()
var _length := 0.0
var _members: Array[Dictionary] = []
var _shape: RefCounted


## points: yolun noktaları (x, z), en az iki; shape: zeminin yüzü (height_at).
func _init(points: PackedVector2Array = PackedVector2Array(), p_shape: RefCounted = null) -> void:
	_shape = p_shape
	set_path(points)


## Yolu kurar: noktalar arasında yumuşak eğri (Catmull-Rom tutamakları).
func set_path(points: PackedVector2Array) -> void:
	_curve = Curve2D.new()
	_curve.bake_interval = BAKE
	for i in points.size():
		var handle := Vector2.ZERO
		if i > 0 and i < points.size() - 1:
			handle = (points[i + 1] - points[i - 1]) * 0.22
		_curve.add_point(points[i], -handle, handle)
	_length = _curve.get_baked_length() if points.size() >= 2 else 0.0


## Yolun uzunluğu (m).
func length() -> float:
	return _length


## Üye ekler: slot.x yan (+ sol), slot.y geri (m). İlk eklenen liderdir.
func add(mover: StoryMover, slot: Vector2 = Vector2.ZERO) -> void:
	_members.append({"mover": mover, "slot": slot, "hidden": false})


func size() -> int:
	return _members.size()


func mover(i: int) -> StoryMover:
	return _members[i]["mover"] if i >= 0 and i < _members.size() else null


func leader() -> StoryMover:
	return mover(0)


## Yolda bir noktanın en yakın yerinin mesafesi (m).
func closest_offset(p: Vector2) -> float:
	return _curve.get_closest_offset(p) if _length > 0.0 else 0.0


## Yoldaki nokta (x, z; uçların ötesinde teğet boyunca uzar).
func point_at(offset: float) -> Vector2:
	if _length <= 0.0:
		return Vector2.ZERO
	if offset < 0.0:
		return _curve.sample_baked(0.0, true) - tangent_at(0.0) * -offset
	if offset > _length:
		return _curve.sample_baked(_length, true) + tangent_at(_length) * (offset - _length)
	return _curve.sample_baked(offset, true)


## Yolun yönü (birim, x z).
func tangent_at(offset: float) -> Vector2:
	if _length <= 0.0:
		return Vector2.DOWN
	# Ölçü penceresi hep yolun içinde ve tam boydadır: uçların ötesinde (gelmeden ya da geçip giderken) yön ucun yönüdür. Pencere uçta
	# daralırsa yön birden değişir, yanda giden atlı bir karede metrelerce sıçrardı (E20 ölçüsü yakaladı).
	var span := minf(TANGENT_SPAN, _length)
	var lo := clampf(offset - span * 0.5, 0.0, _length - span)
	var a := _curve.sample_baked(lo, true)
	var b := _curve.sample_baked(lo + span, true)
	if a.distance_squared_to(b) < 0.000001:
		return Vector2.DOWN
	return (b - a).normalized()


## Üyenin o andaki yeri (x, z) ve yönü (yaw).
func member_pose(i: int) -> Dictionary:
	var slot: Vector2 = _members[i]["slot"]
	var at := s - slot.y
	var t := tangent_at(at)
	var left := Vector2(t.y, -t.x)
	return {"xz": point_at(at) + left * slot.x, "yaw": atan2(t.x, t.y)}


## Düzenin hız oranı (saf hesap; ≥ 1): üyenin yolda aldığı yolun liderinkine en büyük oranı. Kıvrımda dıştaki üye (yolun normalinde side
## metre yanda) liderden hızlı, içteki yavaş gider; uçların ötesinde yol düzdür (oran 1). step: ölçü adımı (m).
func stretch(step := 0.5) -> float:
	var best := 1.0
	if _length <= 0.0:
		return best
	for m: Dictionary in _members:
		var side := (m["slot"] as Vector2).x
		if absf(side) < 0.001:
			continue
		var u := 0.0
		var prev := _side_point(0.0, side)
		while u < _length - 0.0001:
			var next_u := minf(u + step, _length)
			var p := _side_point(next_u, side)
			best = maxf(best, prev.distance_to(p) / maxf(next_u - u, 0.0001))
			prev = p
			u = next_u
	return best


## Hız sınırı (E20; PaceLimit): yaklaşma, geçiş ve gidiş hızları en hızlı üye cap'i aşmayacak kadar iner (cap / stretch). Üyeler eklendikten
## sonra çağrılır. Döner: oran (stretch).
func limit_speeds(cap: float) -> float:
	var k := stretch()
	var top := maxf(cap, 0.0) / k
	approach = minf(approach, top)
	pass_speed = minf(pass_speed, top)
	leave = minf(leave, top)
	return k


func _side_point(offset: float, side: float) -> Vector2:
	var t := tangent_at(offset)
	return point_at(offset) + Vector2(t.y, -t.x) * side


## Liderin varması istenen süre (sn) için başlangıç yeri (m): approach hızıyla gelir, pass_at'te pass hızına inmiş olur (saf hesap).
func start_offset_for(seconds: float) -> float:
	var brake_t := maxf(approach - pass_speed, 0.0) / maxf(accel, 0.01)
	var brake_d := (approach * approach - pass_speed * pass_speed) / (2.0 * maxf(accel, 0.01))
	var d := brake_d + approach * maxf(seconds - brake_t, 0.0)
	return pass_at - d


## Pass noktasına kalan süre (sn; tahmini, frenleme dahil).
func seconds_to_pass() -> float:
	var d := pass_at - s
	if d <= 0.0:
		return 0.0
	var v := maxf(speed, 0.1)
	var brake_d := maxf(v * v - pass_speed * pass_speed, 0.0) / (2.0 * maxf(accel, 0.01))
	if d <= brake_d:
		return d / maxf((v + pass_speed) * 0.5, 0.1)
	return (d - brake_d) / v + maxf(v - pass_speed, 0.0) / maxf(accel, 0.01)


## Başlatır: lider offset'te, approach hızında (koşarak girer); üyeler görünür olur.
func start(offset: float) -> void:
	s = offset
	speed = approach
	running = true
	released = false
	for m: Dictionary in _members:
		m["hidden"] = false
	_place_all(0.0)


## Geçip gider: leave hızına çıkar.
func release() -> void:
	released = true


## Lider geçiş noktasına vardı mı?
func at_pass() -> bool:
	return running and s >= pass_at - 0.05


## Bütün üyeler yolun sonunu geçti mi?
func finished() -> bool:
	if not running:
		return false
	for i in _members.size():
		if s - (_members[i]["slot"] as Vector2).y <= _length:
			return false
	return true


## Bir adım: hız profile yaklaşır, lider yolda ilerler, üyeler yerlerine; liderin bakışı güncellenir.
func tick(delta: float) -> void:
	if not running or delta <= 0.0:
		return
	var want := approach
	if released:
		want = leave
	elif s >= pass_at:
		want = pass_speed
	else:
		want = minf(approach, sqrt(pass_speed * pass_speed + 2.0 * accel * (pass_at - s)))
	speed = move_toward(speed, want, accel * delta)
	s += speed * delta
	_place_all(delta)
	_update_look()


## Hız profili (saf; sınama): liderin s'deki istenen hızı.
static func profile(p_s: float, p_pass_at: float, p_approach: float, p_pass: float, p_accel: float, p_released: bool, p_leave: float) -> float:
	if p_released:
		return p_leave
	if p_s >= p_pass_at:
		return p_pass
	return minf(p_approach, sqrt(p_pass * p_pass + 2.0 * p_accel * (p_pass_at - p_s)))


func _place_all(delta: float) -> void:
	for i in _members.size():
		var m: Dictionary = _members[i]
		var mv: StoryMover = m["mover"]
		if mv == null:
			continue
		var pose := member_pose(i)
		var xz: Vector2 = pose["xz"]
		var past := s - (m["slot"] as Vector2).y > _length + 0.5
		if past and not bool(m["hidden"]):
			m["hidden"] = true
			_show(mv, false)
		if past:
			continue
		mv.move_to(Vector3(xz.x, 0.0, xz.y), float(pose["yaw"]), speed, delta)


func _show(mv: StoryMover, on: bool) -> void:
	if mv.actor:
		mv.actor.visible = on
	if mv.ride:
		mv.ride.visible = on


## Liderin omurgası, boynu ve başı hedefe döner (CineBow «up»): açı liderin kendi yönüne göre, ±LOOK_MAX.
func _update_look() -> void:
	var lead := leader()
	if lead == null or lead.actor == null or lead.actor.avatar == null:
		return
	var skeleton := lead.actor.avatar.get_skeleton()
	if skeleton == null:
		return
	var mod := skeleton.get_node_or_null(NodePath(LOOK_NODE)) as CineBow
	if mod == null:
		if look_amount <= 0.0:
			return
		mod = CineBow.new()
		mod.name = LOOK_NODE
		skeleton.add_child(mod)
	look_deg = 0.0
	if look != Vector3.INF and lead.actor.is_inside_tree():
		var xform := lead.actor.global_transform
		var eye := xform.origin + Vector3.UP * LOOK_EYE
		var local := xform.basis.orthonormalized().inverse() * (look - eye)
		look_deg = clampf(rad_to_deg(atan2(local.x, local.z)), -LOOK_MAX, LOOK_MAX)
	mod.turns = RiderColumn.look_turns(look_deg)
	mod.amount = clampf(look_amount, 0.0, 1.0)


## Odak (saf; K98 uzak kare): Mete ile liderin ortası, Mete'den en çok max_shift metre (Mete karede kalır); yükseklik Mete'ninki.
static func midpoint_focus(child: Vector3, leader_at: Vector3, max_shift: float) -> Vector3:
	var half := Vector2(leader_at.x - child.x, leader_at.z - child.z) * 0.5
	if half.length() > max_shift:
		half = half.normalized() * max_shift
	return Vector3(child.x + half.x, child.y, child.z + half.y)


## Bakış açısının kemiklere dağılışı (saf): [[kemik, "up", derece], ...] (+ sol).
static func look_turns(deg: float) -> Array:
	var out: Array = []
	for row: Array in LOOK_SHARES:
		out.append([row[0], "up", deg * float(row[1])])
	return out
