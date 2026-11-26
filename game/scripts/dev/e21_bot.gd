class_name E21Bot
extends RefCounted
## Geliştirme: Önsöz'ün son dört görevinin otomatik oynatma botunun yolu (Ö2; scripts/dev/prologue_autoplay.gd'nin go_to'su düz çizgidir).
## Yürünür alan kampın dairesi ve Önsöz'ün daireleridir (PlayerController.play_area_extra: yol boyunca daireler, obalar, yamaç): düz çizgi
## alanın dışına taşıyorsa bot yolun çizgisini izler (PrologueWorld.road; yol boyunca 6 m ileri bakar), yoksa doğrudan hedefe gider. Aile yurdu
## açıksa (içine girilir) duvardan değil kapıdan geçilir.
##   bot.go_to(E21Bot.next_point(days, player.global_position, hedef), koş)

## Kampın dairesi (PlayerController.play_area_radius) ve kenar payı (m); yolda ileri bakış (m); çizginin örnek aralığı (m).
const CAMP_RADIUS := 38.0
const EDGE := 1.0
const LOOK_AHEAD := 6.0
const SAMPLE := 1.5
## Takılma: bu sürede (sn) bu kadar (m) yol alınmadıysa geri çekilip yandan dolaşılır (ESCAPE_S sn).
const STUCK_S := 1.6
const STUCK_M := 0.4
const ESCAPE_S := 1.8

static var _anchor := Vector3.INF
static var _anchor_ms := 0
static var _escape := Vector3.INF
static var _escape_until := 0
static var _escape_side := 1.0


## Bot için sıradaki nokta (saf değil: koşucunun yerlerine ve oyuncunun alanına bakar).
static func next_point(days: PrologueDays, from: Vector3, to: Vector3) -> Vector3:
	if days == null or to == Vector3.INF:
		return to
	var escape := E21Bot._unstick(from, to)
	if escape != Vector3.INF:
		return escape
	var via := E21Bot._yurt_door(days, from, to)
	if via != Vector3.INF:
		return via
	var circles := E21Bot.walk_circles(days)
	if E21Bot.segment_walkable(Vector2(from.x, from.z), Vector2(to.x, to.z), circles):
		return E21Bot.around(days, from, to)
	var places := days.places
	if places == null or places.road.size() < 2:
		return to
	var a := PrologueWorld.project(places.road, places.road_arc, Vector2(from.x, from.z))
	var b := PrologueWorld.project(places.road, places.road_arc, Vector2(to.x, to.z))
	# Yola uzaksa önce yola.
	if a.y > 3.0:
		var on := PrologueWorld.point_at_arc(places.road, places.road_arc, a.x)
		return days.point([on.x, on.y])
	# Yol boyunca hedefin izdüşümüne vardıysa (ya da çok yakınsa) doğrudan hedefe.
	if absf(b.x - a.x) < LOOK_AHEAD * 0.5:
		return to
	var dir := signf(b.x - a.x)
	var s := a.x + dir * minf(LOOK_AHEAD, absf(b.x - a.x))
	var q := PrologueWorld.point_at_arc(places.road, places.road_arc, s)
	return E21Bot.around(days, from, days.point([q.x, q.y]))


## Yoldaki engelin (oyuncunun engel daireleri: kaya, ağaç gövdesi, ateş) yanından geçen nokta; engel yoksa hedef. Yalnız önümüzdeki 4 m'ye
## bakılır; daire hedefin kendisini kapsıyorsa (ateşin başı) hedef kalır.
static func around(days: PrologueDays, from: Vector3, to: Vector3) -> Vector3:
	var pl := days.player if days else null
	if pl == null:
		return to
	var a := Vector2(from.x, from.z)
	var b := Vector2(to.x, to.z)
	var seg := b - a
	var length := seg.length()
	if length < 0.3:
		return to
	var dir := seg / length
	var best := Vector3.INF
	var best_t := INF
	var body := pl.body_radius + 0.15
	for c in pl.obstacles:
		var center := Vector2(c.x, c.y)
		if center.distance_to(b) <= c.z + body:
			continue
		var t := (center - a).dot(dir)
		if t <= 0.0 or t > minf(length, 4.0) + c.z:
			continue
		var closest := a + dir * clampf(t, 0.0, length)
		if closest.distance_to(center) >= c.z + body:
			continue
		if t < best_t:
			best_t = t
			var side := Vector2(-dir.y, dir.x)
			if (center - a).dot(side) > 0.0:
				side = -side
			# Engelin yanından ve biraz ilerisinden: varınca engel geride kalır (yanındaki noktada takılıp durmaz).
			var p := center + side * (c.z + body + 0.5) + dir * (c.z + 0.6)
			if p.distance_to(a) < 0.9:
				p += dir * 1.2
			best = days.point([p.x, p.y])
	return best if best != Vector3.INF else to


## Takılma kaçışı (bot her kare çağırır): STUCK_S sn'de STUCK_M'den az yol alındıysa (hedef uzakken) geri ve yana bir nokta, ESCAPE_S sn.
static func _unstick(from: Vector3, to: Vector3) -> Vector3:
	var now := Time.get_ticks_msec()
	if _escape != Vector3.INF:
		if now < _escape_until and PrologueStep.flat(from, _escape) > 0.5:
			return _escape
		_escape = Vector3.INF
		_anchor = from
		_anchor_ms = now
	if _anchor == Vector3.INF or PrologueStep.flat(from, _anchor) > STUCK_M:
		_anchor = from
		_anchor_ms = now
		return Vector3.INF
	if PrologueStep.flat(from, to) < 1.5 or float(now - _anchor_ms) / 1000.0 < STUCK_S:
		return Vector3.INF
	var dir := Vector3(to.x - from.x, 0.0, to.z - from.z).normalized()
	var side := Vector3(-dir.z, 0.0, dir.x) * _escape_side
	_escape_side = -_escape_side
	_escape = from - dir * 1.4 + side * 2.6
	_escape_until = now + int(ESCAPE_S * 1000.0)
	return _escape


## Yürünür alanın daireleri: kampın dairesi + Önsöz'ün daireleri (x, z, r).
static func walk_circles(days: PrologueDays) -> Array[Vector3]:
	var out: Array[Vector3] = [Vector3(0.0, 0.0, CAMP_RADIUS)]
	if days and days.player:
		for c in days.player.play_area_extra:
			out.append(c)
	return out


## Doğru parçası alanın içinde mi (saf): her örnek noktası en az bir dairenin içinde (kenar payıyla).
static func segment_walkable(a: Vector2, b: Vector2, circles: Array[Vector3]) -> bool:
	var n := maxi(int(ceil(a.distance_to(b) / SAMPLE)), 1)
	for i in n + 1:
		var p := a.lerp(b, float(i) / float(n))
		var inside := false
		for c in circles:
			if p.distance_to(Vector2(c.x, c.y)) <= c.z - EDGE:
				inside = true
				break
		if not inside:
			return false
	return true


## Açık yurtların kapısı (içeriden dışarıya ya da dışarıdan içeriye geçerken; yoksa INF): aile yurdu (açıksa) ve Kayın Obası'nın açık
## yurtları (Saruk'un, Künay'ın: işaretleri <kimlik>_yurt, _door, _in).
static func _yurt_door(days: PrologueDays, from: Vector3, to: Vector3) -> Vector3:
	var keys: Array[String] = ["saruk", "kunay"]
	if days.places and days.places.is_family_open():
		keys.append("gol_family")
	for key in keys:
		var center := days.point(key + "_yurt")
		var door_out := days.point(key + "_door")
		var door_in := days.point(key + "_in")
		if center == Vector3.INF or door_out == Vector3.INF or door_in == Vector3.INF:
			continue
		var r := 3.6
		var p_in := PrologueStep.flat(from, center) < r
		var g_in := PrologueStep.flat(to, center) < r
		if p_in == g_in:
			continue
		if p_in:
			return door_in if PrologueStep.flat(from, door_in) > 0.8 and PrologueStep.flat(from, door_out) > PrologueStep.flat(door_in, door_out) else door_out
		return door_out if PrologueStep.flat(from, door_out) > 0.8 and PrologueStep.flat(from, door_in) > PrologueStep.flat(door_in, door_out) else door_in
	return Vector3.INF
