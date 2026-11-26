class_name PastureFlock
extends RefCounted
## Açık otlağın sürüsü (fauna.md §10 «Sürü», §6 «Gece kuralı»; act1.md §4 Ak Otlak: 60 at, 200 koyun): FaunaDirector'un sürü işi, 4 Hz.
## Saftır: düğüm kurmaz, gölgelendiriciye dokunmaz; HerdField çizer (setup_flock) ve aradaki kareleri ara değerler. Sürü ajan taşımaz: her
## hayvan kısa bir hedef izler; ayrılma (yönlü gövde elipsi, ızgarayla komşu araması), kaçarken hizalanma ve toplanma, kurttan kaçış 4 Hz'de
## hesaplanır. Koyun kurttan sürünün içine kaçar (toplanır, fauna.md §1), at kaçar ve sürüyle döner. Sürünün merkezi otlağın içinde yavaşça
## gezinir. Gece atlar baş eğik dinlenir (21:00–05:00), koyun ağıla (fold) toplanır (fauna.md §6).
##
## HerdField'in okuduğu yüz HerdSim'inkiyle aynıdır: count, prev, pos, facing, grazing (0 baş yukarı, 1 otluyor, REST_HEAD dinleniyor),
## body_scale, events, avoid, obstacles, clock, step(), relax().
##   var flock := PastureFlock.new({"kind": "sheep", "count": 200, "center": [210, -300], "radius": 55, "fold": [90, -240]}, FaunaKind.named("sheep"))
##   flock.threats = [Vector3(wolf.x, wolf.z, 30.0)]   # kaçılacak noktalar (x, z, ürkme yarıçapı)
##   flock.set_time(minute)                            # gece: ağıl ya da dinlenme
##   flock.step()                                      # 4 Hz (FaunaDirector)
## Olaylar events'e yazılır: {"type": &"fled", "index": i, "from": Vector2} kaçışın ilk tikinde (ses: FaunaVoices).

enum Mode { GRAZE, AMBLE, FLEE, REST, FOLD }

## Benzetim adımı (sn): 4 Hz.
const TICK := 0.25
## Dinlenen atın başı (0 yukarı, 1 yerde): «baş eğik».
const REST_HEAD := 0.55
## Otlama ve ağır yürüyüş (HerdSim'le aynı).
const IDLE_RANGE := Vector2(3.0, 11.0)
const AMBLE_PACE := Vector2(0.45, 0.8)
const WANDER_RANGE := Vector2(1.0, 4.0)
const GRAZE_SHARE := 0.8
## Ayrılma itişinin hıza çevrilmesi (1/sn) ve en büyük itiş hızı (m/sn).
const PUSH_GAIN := 1.6
const PUSH_MAX := 1.4
## Kaçış: tehdit bu kadar açılınca (ürkme yarıçapının katı) ve en az CALM_S sonra durulur.
const CALM_RATIO := 1.7
const CALM_S := 3.0
## Sürünün merkezi kaçışta tehditten bu hızla uzaklaşır (kaçanların hızının payı).
const CENTER_FLEE_SHARE := 0.55
## Sürü merkezinin otlaktaki gezinme hızı (m/sn) ve hedef değiştirme aralığı (sn).
const DRIFT_SPEED := 0.12
const DRIFT_EVERY := Vector2(40.0, 90.0)
## Atların dinlendiği saatler (fauna.md §6, time.md §8.4): 21:00–05:00.
const REST_FROM := 1260.0
const REST_TO := 300.0
## Koyunun ağılda olduğu saatler: akşam aşından (17:30) sabaha (07:45).
const FOLD_FROM := 1050.0
const FOLD_TO := 465.0
## Kaçınılan hareketli noktanın (oyuncu) itişi.
const AVOID_GAIN := 1.4

var kind_id := "sheep"
var count := 0
var clock := 0.0
var pos := PackedVector2Array()
var prev := PackedVector2Array()
var vel := PackedVector2Array()
var facing := PackedVector2Array()
var grazing := PackedFloat32Array()
var body_scale := PackedFloat32Array()
var mode := PackedByteArray()
var timer := PackedFloat32Array()
var pace := PackedFloat32Array()
var flee_t := PackedFloat32Array()
var flee_from := PackedVector2Array()
var goal := PackedVector2Array()
var events: Array[Dictionary] = []
## Sabit engeller Vector3(x, z, yarıçap) ve kaçınılan hareketli noktalar (oyuncu; yol verilir).
var obstacles: Array[Vector3] = []
var avoid: Array[Vector3] = []
## Kaçılan noktalar Vector3(x, z, ürkme yarıçapı): kurt, dörtnaldaki atlı.
var threats: Array[Vector3] = []

## Otlak (merkezi ve yarıçapı): sürünün merkezi bunun içinde gezer.
var home := Vector2.ZERO
var home_radius := 80.0
## Sürünün o anki merkezi ve diski.
var center := Vector2.ZERO
var radius := 30.0
## Gecenin ağılı (koyun; yoksa INF) ve yarıçapı.
var fold := Vector2.INF
var fold_radius := 11.0
## Ağıl çitli bir dikdörtgense (Mene'nin Ağılı; StructureKit.pen_area, set_pen): {center, half, gate, gap, in, out}. Koyun geceyi çitin
## içinde geçirir, kapıdan girer ve çıkar (çit ağılı kesen yolu köşeden dolaştırır); boşsa ağıl açık dairedir (fold_radius).
var pen := {}
## Çarpışılan kutular (ağılın çiti ve yakındaki yapıların duvarları; FaunaLayer haritadan verir): gövde kutunun dışına itilir.
var boxes: Array[ObstacleBox] = []
## Kaçış biçimi: "bunch" sürünün içine (koyun), "scatter" tehditten uzağa, sürüyle (at).
var flee_style := "bunch"
## Gece dinlenir mi (at)?
var rests := false
## Hızlar (m/sn; FaunaKind): adım, tırıs, dörtnal; kaçışın tepe ve sürek hızı, T.
var walk_speed := 1.1
var trot_speed := 2.5
var peak_speed := 5.5
var sustained_speed := 2.5
var flight_t := 8.0
## Gövde elipsinin yarı boyu ve yarı eni (metre, boy çarpanı 1).
var half_length := 0.68
var half_width := 0.32
## Gece mi (ağıl ya da dinlenme saatleri)?
var night := false

var _rng := RandomNumberGenerator.new()
var _push := PackedVector2Array()
var _grid := {}
var _cell := 3.0
var _drift_goal := Vector2.ZERO
var _drift_left := 0.0
var _flee_any := false


## def: {kind, count, center, radius, home, home_radius, fold, fold_radius, flee, rests, seed} (fauna.json «flocks»); kind: türün kaydı.
func _init(def: Dictionary = {}, kind: FaunaKind = null) -> void:
	kind_id = str(def.get("kind", kind.id if kind else "sheep"))
	count = maxi(int(def.get("count", 20)), 1)
	_rng.seed = int(def.get("seed", 911))
	center = _vec2(def.get("center", [0.0, 0.0]))
	radius = float(def.get("radius", 30.0))
	home = _vec2(def.get("home", def.get("center", [0.0, 0.0])))
	home_radius = float(def.get("home_radius", radius * 2.0))
	if def.get("fold") is Array:
		fold = _vec2(def["fold"])
		fold_radius = float(def.get("fold_radius", fold_radius))
	flee_style = str(def.get("flee", "bunch" if kind_id == "sheep" else "scatter"))
	rests = bool(def.get("rests", kind_id == "horse"))
	if kind:
		walk_speed = kind.speed("walk", walk_speed)
		trot_speed = kind.speed("trot", trot_speed)
		peak_speed = kind.peak_speed()
		sustained_speed = kind.sustained_speed()
		flight_t = kind.flight_time()
		var length := kind.length if kind.length > 0.0 else 1.264
		half_length = length * 0.54
		half_width = maxf(length * 0.16, 0.25)
	_cell = maxf(half_length * 2.6, 2.0)
	_alloc()
	_drift_goal = center
	_place(center, radius)


# --- Yüz ------------------------------------------------------------------------------------------------

## Saat (gün dakikası): gece ağıla ya da dinlenmeye geçilir. Döner: gece mi?
func set_time(minute: float) -> bool:
	var was := night
	if fold.is_finite():
		night = minute >= FOLD_FROM or minute < FOLD_TO
	elif rests:
		night = minute >= REST_FROM or minute < REST_TO
	else:
		night = false
	if night != was:
		for i in count:
			if mode[i] != Mode.FLEE:
				_settle(i)
	return night


## Ağılı çitli dikdörtgen yapar (StructureKit.pen_area: center, half, gate, gap; kapı kuzey kenardadır): gecenin yeri dikdörtgenin içi,
## fold ortası, fold_radius yarı köşegeni olur. Boş sözlük ağılı açık daireye döndürür.
func set_pen(area: Dictionary) -> void:
	pen = {}
	if area.is_empty() or not area.has("center") or not area.has("half"):
		return
	pen = area.duplicate()
	var half: Vector2 = pen["half"]
	var gate: Vector2 = pen.get("gate", Vector2(pen["center"]) - Vector2(0.0, half.y))
	pen["gate"] = gate
	pen["gap"] = float(pen.get("gap", 3.2))
	# Kapının içi ve dışı (çit kuzey kenarda: dışı kuzeyde, −z).
	pen["in"] = gate + Vector2(0.0, 2.0)
	pen["out"] = gate - Vector2(0.0, 2.2)
	fold = pen["center"]
	fold_radius = half.length()


## Nokta ağılın içinde mi (margin dışa doğru pay; eksi içe)?
func in_pen(p: Vector2, margin := 0.0) -> bool:
	if pen.is_empty():
		return false
	var d := (p - Vector2(pen["center"])).abs()
	var half: Vector2 = pen["half"]
	return d.x <= half.x + margin and d.y <= half.y + margin


## Sürüyü bir yere anında yerleştirir (kurulum, ölçüm, atlama): gece ise ağıla ya da dinlenmeye.
func place_now() -> void:
	if night and fold.is_finite():
		if pen.is_empty():
			_place(fold, fold_radius)
		else:
			_place_rect(Vector2(pen["center"]), Vector2(pen["half"]) - Vector2.ONE)
		for i in count:
			mode[i] = Mode.REST
			grazing[i] = 0.0
	else:
		_place(center, radius)
		if night and rests:
			for i in count:
				mode[i] = Mode.REST
				grazing[i] = REST_HEAD
	prev = pos.duplicate()


## Yerleştirmeden sonra gövdeler ayrılır (zaman akmadan; rng ilerlemez).
func relax(rounds: int = 8) -> void:
	for _round in rounds:
		_grid.clear()
		_compute_push()
		for i in count:
			pos[i] = _resolve(pos[i] + _push[i])
	_grid.clear()
	for i in count:
		goal[i] = pos[i]
	prev = pos.duplicate()


## Kaçan hayvan var mı (son tikte)?
func is_fleeing() -> bool:
	return _flee_any


## Sürünün o anki ağırlık merkezi (ses ve tehdit hesabı için).
func centroid() -> Vector2:
	var sum := Vector2.ZERO
	for p in pos:
		sum += p
	return sum / float(maxi(count, 1))


## Noktaya en yakın hayvanın sırası ve uzaklığı: Vector2(sıra, uzaklık).
func nearest(p: Vector2) -> Vector2:
	var best := -1
	var best_d := INF
	for i in count:
		var d := pos[i].distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = i
	return Vector2(best, sqrt(best_d) if best >= 0 else INF)


# --- Adım -----------------------------------------------------------------------------------------------

## Bir benzetim adımı (TICK saniye).
func step() -> void:
	clock += TICK
	prev = pos.duplicate()
	events.clear()
	_flee_any = false
	_drift_center()
	_build_grid()
	_compute_push()
	var flee_sum := Vector2.ZERO
	var flee_n := 0
	for i in count:
		_check_threat(i)
	_spread_alarm()
	_grid.clear()
	for i in count:
		if mode[i] == Mode.FLEE:
			flee_n += 1
			flee_sum += vel[i]
	# Kaçışta hizalanma: kaçanların ortalama yönü (atlar sürüyle döner).
	var flee_mean := flee_sum / float(flee_n) if flee_n > 0 else Vector2.ZERO
	for i in count:
		_step_member(i, flee_mean)
	if flee_n > 0:
		_flee_any = true
		# Sürünün merkezi kaçanlarla birlikte kayar: hayvanlar eski yere geri yürümez.
		var c := centroid()
		center = center.lerp(c, 0.25)
		center = _clamp_disc(center, home, home_radius)


func _drift_center() -> void:
	if night and fold.is_finite():
		return
	_drift_left -= TICK
	if _drift_left <= 0.0 or center.distance_to(_drift_goal) < 1.0:
		_drift_left = _rng.randf_range(DRIFT_EVERY.x, DRIFT_EVERY.y)
		var a := _rng.randf() * TAU
		_drift_goal = _clamp_disc(home + Vector2.from_angle(a) * sqrt(_rng.randf()) * maxf(home_radius - radius, 0.0), home, home_radius - radius)
	center = center.move_toward(_drift_goal, DRIFT_SPEED * TICK)


## Ürkü sürüde dalga gibi yayılır: kaçanın ızgara komşusu da kaçar (sürüyü izler, fauna.md §1). Tik başına bir hücre.
func _spread_alarm() -> void:
	var joined := PackedInt32Array()
	for i in count:
		if mode[i] == Mode.FLEE:
			continue
		var pi := pos[i]
		var cx := floori(pi.x / _cell)
		var cz := floori(pi.y / _cell)
		var found := -1
		for gx in range(cx - 1, cx + 2):
			for gz in range(cz - 1, cz + 2):
				var list: Variant = _grid.get(Vector2i(gx, gz))
				if list == null:
					continue
				for j: int in (list as PackedInt32Array):
					if mode[j] == Mode.FLEE and flee_t[j] <= CALM_S:
						found = j
						break
				if found >= 0:
					break
			if found >= 0:
				break
		if found >= 0:
			joined.append(i)
			flee_from[i] = flee_from[found]
	for i in joined:
		mode[i] = Mode.FLEE
		flee_t[i] = 0.0
		grazing[i] = 0.0


## Tehdit ürkme yarıçapındaysa hayvan kaçmaya başlar (ilk tikte olay yazılır).
func _check_threat(i: int) -> void:
	var p := pos[i]
	for t in threats:
		var from := Vector2(t.x, t.y)
		if p.distance_squared_to(from) < t.z * t.z:
			if mode[i] != Mode.FLEE:
				mode[i] = Mode.FLEE
				flee_t[i] = 0.0
				grazing[i] = 0.0
				events.append({"type": &"fled", "index": i, "from": from})
			flee_from[i] = from
			return


func _step_member(i: int, flee_mean: Vector2) -> void:
	var p := pos[i]
	var desired := Vector2.ZERO
	match mode[i]:
		Mode.GRAZE:
			timer[i] -= TICK
			if timer[i] <= 0.0:
				_wander(i)
		Mode.AMBLE:
			var d := p.distance_to(goal[i])
			if d < 0.35:
				_settle(i)
			else:
				var to_way := _waypoint(p, goal[i]) - p
				desired = to_way.normalized() * pace[i] if to_way.length_squared() > 0.0001 else Vector2.ZERO
		Mode.FOLD:
			var df := p.distance_to(goal[i])
			if df < 0.6:
				mode[i] = Mode.REST
				grazing[i] = 0.0
			else:
				var to_way := _waypoint(p, goal[i]) - p
				desired = to_way.normalized() * walk_speed * 1.1 if to_way.length_squared() > 0.0001 else Vector2.ZERO
		Mode.REST:
			pass
		Mode.FLEE:
			desired = _flee_velocity(i, flee_mean)
	var push := (_push[i] * PUSH_GAIN).limit_length(PUSH_MAX)
	if desired.length_squared() > 0.0025:
		facing[i] = facing[i].slerp(desired.normalized(), 0.7).normalized()
	elif push.length_squared() > 0.25:
		facing[i] = push.normalized()
	var v := desired + push
	vel[i] = v
	pos[i] = _resolve(p + v * TICK, i)


## Kaçışın hızı (fauna.md §4.1 formülü): «bunch» sürünün içine ve tehditten uzağa, «scatter» uzağa ve sürünün ortalama yönüyle.
func _flee_velocity(i: int, flee_mean: Vector2) -> Vector2:
	flee_t[i] += TICK
	var p := pos[i]
	var from := flee_from[i]
	var away := (p - from).normalized() if p.distance_squared_to(from) > 0.0001 else Vector2.RIGHT
	var spd := FaunaDirector.flight_speed(peak_speed, sustained_speed, flight_t, flee_t[i])
	var dir := away
	if flee_style == "bunch":
		var inward := (centroid_cached() - p)
		var dist_in := inward.length()
		if dist_in > 0.5:
			dir = (away * 0.55 + inward / dist_in * 0.75).normalized()
		spd = minf(spd, trot_speed * 1.1)
	elif flee_mean.length_squared() > 0.01:
		dir = (away * 0.6 + flee_mean.normalized() * 0.4).normalized()
	# Durulma: tehdit açıldı ve yeterince koşuldu.
	var far := true
	for t in threats:
		if p.distance_squared_to(Vector2(t.x, t.y)) < (t.z * CALM_RATIO) * (t.z * CALM_RATIO):
			far = false
			break
	if far and flee_t[i] > CALM_S:
		_settle(i)
		return Vector2.ZERO
	return dir * spd


var _centroid_tick := -1.0
var _centroid := Vector2.ZERO


func centroid_cached() -> Vector2:
	if _centroid_tick != clock:
		_centroid_tick = clock
		_centroid = centroid()
	return _centroid


## Hayvan yerine oturur: gece ağıla ya da dinlenmeye, gündüz otlamaya.
func _settle(i: int) -> void:
	vel[i] = Vector2.ZERO
	if night and fold.is_finite():
		mode[i] = Mode.FOLD
		if pen.is_empty():
			var a := _rng.randf() * TAU
			goal[i] = fold + Vector2.from_angle(a) * sqrt(_rng.randf()) * (fold_radius - 1.0)
		else:
			var inner := Vector2(pen["half"]) - Vector2.ONE
			goal[i] = fold + Vector2(_rng.randf_range(-inner.x, inner.x), _rng.randf_range(-inner.y, inner.y))
		grazing[i] = 0.0
		pace[i] = walk_speed
		return
	if night and rests:
		mode[i] = Mode.REST
		grazing[i] = REST_HEAD
		return
	mode[i] = Mode.GRAZE
	timer[i] = _rng.randf_range(IDLE_RANGE.x, IDLE_RANGE.y)
	grazing[i] = 1.0 if _rng.randf() < GRAZE_SHARE else 0.0


## Otlayan hayvan kısa bir yer değiştirir: hedef sürünün diskinin içindedir, merkeze hafifçe çekilir (toplanma).
func _wander(i: int) -> void:
	var p := pos[i]
	var a := _rng.randf() * TAU
	var r := _rng.randf_range(WANDER_RANGE.x, WANDER_RANGE.y)
	var target := p + Vector2.from_angle(a) * r
	target = target.lerp(center, 0.12)
	goal[i] = _clamp_disc(target, center, radius)
	mode[i] = Mode.AMBLE
	grazing[i] = 0.0
	pace[i] = walk_speed * _rng.randf_range(AMBLE_PACE.x, AMBLE_PACE.y)


# --- Ayrılma ve engeller -----------------------------------------------------------------------------

func _build_grid() -> void:
	_grid.clear()
	for i in count:
		var key := Vector2i(floori(pos[i].x / _cell), floori(pos[i].y / _cell))
		var list: PackedInt32Array = _grid.get(key, PackedInt32Array())
		list.append(i)
		_grid[key] = list


## Gövde elipslerinin ayrılma itişi: komşular ızgaranın 3×3 hücresinden (O(n)).
func _compute_push() -> void:
	_push.fill(Vector2.ZERO)
	if _grid.is_empty():
		_build_grid()
	for i in count:
		var pi := pos[i]
		var cx := floori(pi.x / _cell)
		var cz := floori(pi.y / _cell)
		for gx in range(cx - 1, cx + 2):
			for gz in range(cz - 1, cz + 2):
				var list: Variant = _grid.get(Vector2i(gx, gz))
				if list == null:
					continue
				for j: int in (list as PackedInt32Array):
					if j <= i:
						continue
					var delta := pos[j] - pi
					var ds := delta.length_squared()
					var reach := (half_length * 2.0) * maxf(body_scale[i], body_scale[j])
					if ds >= reach * reach:
						continue
					var dist := sqrt(ds)
					var u := delta / dist if dist > 0.001 else Vector2.RIGHT
					var need := body_reach(facing[i], u) * body_scale[i] + body_reach(facing[j], u) * body_scale[j]
					if dist < need:
						var away := u * (need - dist) * 0.5
						_push[i] -= away
						_push[j] += away
		for a in avoid:
			var off := pi - Vector2(a.x, a.y)
			var d2 := off.length_squared()
			if d2 < a.z * a.z:
				var dist := sqrt(d2)
				_push[i] += (off / dist if dist > 0.001 else Vector2.RIGHT) * (a.z - dist) * AVOID_GAIN


## Gövde elipsinin u yönündeki yarıçapı (boy çarpanı 1).
func body_reach(f: Vector2, u: Vector2) -> float:
	var c := u.dot(f)
	var s2 := maxf(1.0 - c * c, 0.0)
	return half_length * half_width / sqrt(half_width * half_width * c * c + half_length * half_length * s2)


## Konumu engellerden çıkarır: daireler, kutular (çit, duvar; gövdenin yarı eni payıyla). i verilirse (adım) otlağın kıyısı yalnız kaçışta
## çeker: ağıldan sabah otlağa dönen koyun yürüyerek gider (ışınlanmaz); yerleştirmede (i < 0) her zaman.
func _resolve(p: Vector2, i := -1) -> Vector2:
	var out := p
	for c in obstacles:
		var center_o := Vector2(c.x, c.y)
		var min_dist := c.z + half_width
		var off := out - center_o
		var ds := off.length_squared()
		if ds < min_dist * min_dist:
			var dist := sqrt(ds)
			out = center_o + (off / dist if dist > 0.0001 else Vector2.RIGHT) * min_dist
	var from := pos[i] if i >= 0 else out
	for b in boxes:
		out = _push_box(b, from, out)
	# Otlağın dışına taşan geri çekilir (kaçış da otlağın içinde biter; ağıl otlağın dışında olabilir).
	if not (night and fold.is_finite()) and (i < 0 or mode[i] == Mode.FLEE):
		out = _clamp_disc(out, home, home_radius + 25.0)
	return out


## Kutudan iter (gövdenin yarı eni payıyla), önceki yerin yanına: adım çitin kalınlığından uzun olsa da (itişle 0,65 m) hayvan öbür yana
## geçmez (ObstacleBox.push_out en yakın kenara iterdi: çitin ortasını geçen adım içeride kalıyordu).
func _push_box(b: ObstacleBox, from: Vector2, p: Vector2) -> Vector2:
	var r := half_width
	var rel := p - b.center
	var lx := rel.dot(b.axis_x)
	var lz := rel.dot(b.axis_z)
	if absf(lx) >= b.half.x + r or absf(lz) >= b.half.y + r:
		return p
	var f := from - b.center
	var fx := f.dot(b.axis_x)
	var fz := f.dot(b.axis_z)
	if absf(fx) - b.half.x >= absf(fz) - b.half.y:
		lx = (b.half.x + r) * (1.0 if fx >= 0.0 else -1.0)
	else:
		lz = (b.half.y + r) * (1.0 if fz >= 0.0 else -1.0)
	return b.center + b.axis_x * lx + b.axis_z * lz


## Hedefe giden ara nokta (çitli ağıl): hayvanla hedef çitin ayrı yanlarındaysa kapıdan geçer (dışarıdan önce kapının dışı, kapının
## koridorunda içi; içeriden önce kapının içi, koridorda dışı); dışarıdaki yol ağılı kesiyorsa köşeden dolaşır. Çitsiz ağılda hedefin kendisi.
func _waypoint(p: Vector2, target: Vector2) -> Vector2:
	if pen.is_empty():
		return target
	var inside_p := in_pen(p, -0.1)
	var inside_t := in_pen(target, -0.1)
	if inside_p == inside_t:
		if inside_p or not _crosses_pen(p, target):
			return target
		return _corner_toward(p, target)
	var g: Vector2 = pen["gate"]
	var lane := absf(p.x - g.x) <= float(pen["gap"]) * 0.5 - 0.2 and absf(p.y - g.y) <= 2.4
	if lane:
		return pen["in"] if inside_t else pen["out"]
	if inside_p:
		return pen["in"]
	var out: Vector2 = pen["out"]
	return out if not _crosses_pen(p, out) else _corner_toward(p, out)


## Doğru parçası ağılın (çitten biraz içerideki) dikdörtgenini kesiyor mu?
func _crosses_pen(a: Vector2, b: Vector2) -> bool:
	var c: Vector2 = pen["center"]
	var h: Vector2 = Vector2(pen["half"]) - Vector2(0.3, 0.3)
	var corners := [c + Vector2(-h.x, -h.y), c + Vector2(h.x, -h.y), c + Vector2(h.x, h.y), c + Vector2(-h.x, h.y)]
	for k in 4:
		if Geometry2D.segment_intersects_segment(a, b, corners[k], corners[(k + 1) % 4]) != null:
			return true
	return false


## Dolaşma köşesi: ağılın dışa açılmış dört köşesinden hayvandan görüneni (yolu ağılı kesmeyen), hayvan → köşe → hedef en kısa olanı.
func _corner_toward(p: Vector2, target: Vector2) -> Vector2:
	var c: Vector2 = pen["center"]
	var h: Vector2 = Vector2(pen["half"]) + Vector2(1.6, 1.6)
	var best := target
	var best_d := INF
	for k in 4:
		var q := c + Vector2(h.x if k == 1 or k == 2 else -h.x, h.y if k >= 2 else -h.y)
		if _crosses_pen(p, q):
			continue
		var d := p.distance_to(q) + q.distance_to(target)
		if d < best_d:
			best_d = d
			best = q
	return best


# --- Yardımcılar ---------------------------------------------------------------------------------------

func _alloc() -> void:
	pos.resize(count)
	prev.resize(count)
	vel.resize(count)
	facing.resize(count)
	grazing.resize(count)
	body_scale.resize(count)
	body_scale.fill(1.0)
	mode.resize(count)
	timer.resize(count)
	pace.resize(count)
	flee_t.resize(count)
	flee_from.resize(count)
	goal.resize(count)
	_push.resize(count)
	for i in count:
		facing[i] = Vector2.from_angle(fposmod(float(i) * 2.39996 + 0.7, TAU))


func _place(at: Vector2, r: float) -> void:
	var points := HerdSim.scatter_points(at, r, count, _rng, half_length * 1.4)
	for i in count:
		pos[i] = points[i]
		goal[i] = points[i]
		vel[i] = Vector2.ZERO
		mode[i] = Mode.GRAZE
		timer[i] = _rng.randf_range(0.0, IDLE_RANGE.y)
		grazing[i] = 1.0 if _rng.randf() < GRAZE_SHARE else 0.0
		pace[i] = walk_speed * AMBLE_PACE.x
	prev = pos.duplicate()


## Dikdörtgenin içine titreşen ızgarayla yerleştirir (çitli ağılın gecesi; gövdeleri relax ayırır).
func _place_rect(c: Vector2, half: Vector2) -> void:
	var h := half.max(Vector2(0.5, 0.5))
	var cols := maxi(ceili(sqrt(float(count) * h.x / h.y)), 1)
	var rows := maxi(ceili(float(count) / float(cols)), 1)
	var cell := Vector2(h.x * 2.0 / float(cols), h.y * 2.0 / float(rows))
	for i in count:
		var k := Vector2(float(i % cols) + 0.5 + _rng.randf_range(-0.3, 0.3), float(i / cols) + 0.5 + _rng.randf_range(-0.3, 0.3))
		pos[i] = c - h + k * cell
		goal[i] = pos[i]
		vel[i] = Vector2.ZERO
		mode[i] = Mode.GRAZE
		timer[i] = _rng.randf_range(0.0, IDLE_RANGE.y)
		grazing[i] = 0.0
		pace[i] = walk_speed * AMBLE_PACE.x
	prev = pos.duplicate()


static func _clamp_disc(p: Vector2, c: Vector2, r: float) -> Vector2:
	return c + (p - c).limit_length(maxf(r, 0.0))


static func _vec2(v: Variant) -> Vector2:
	if v is Array and (v as Array).size() >= 2:
		return Vector2(float(v[0]), float(v[1]))
	if v is Vector2:
		return v
	return Vector2.ZERO
