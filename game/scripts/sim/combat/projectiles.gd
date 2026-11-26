class_name Projectiles
extends RefCounted
## Mermiler (saf; godot.md §3 «Dövüş», architecture.md §3.10): okların analitik yayı ve havuzu. Konum adım adım tümlenmez, kapalı formülle
## hesaplanır: p(t) = from + v·t + ½·a·t², a = rüzgârın yan ivmesi − g·y. Çarpışma alt adımlarla bakılır (bir alt adımda en çok STEP_M yol: hızlı
## ok ince hedefi atlamaz). Düğüm kurmaz; zemin ve hedefler adıma verilir, çizim ArrowField'dadır.
##
##   var pool := Projectiles.new()
##   pool.fire(from, to, {"speed": 22.0, "arc": 0.06, "blunt": true})   # to'ya tam iner (rüzgârsız)
##   for event in pool.step(delta, ground_height, targets):             # targets: [{id, center, radius}, ...]
##       if event["type"] == Projectiles.EVENT_HIT: ...
##
## Küt ok saplanmaz: hedefe değince seker, zemine değince yatar; yerde GROUND_S durur, son FADE_S'te küçülerek erir. Havuz doluysa önce en eski
## yatan, sonra en eski uçan geri alınır.

const CAPACITY := 64
const GRAVITY := 9.8
const MAX_FLIGHT := 6.0
const GROUND_S := 8.0
const FADE_S := 2.0
## Bir alt adımda en çok yol (m) ve zeminin kesin yeri için ikiye bölme sayısı.
const STEP_M := 0.7
const BISECT := 8
## Küt okun yerde yattığı yükseklik ve saplanan okun gömülme derinliği (m).
const REST_LIFT := 0.012
const BURY := 0.12
## Yüzeye tam inen nokta kaçmasın diye (m).
const HIT_EPS := 0.04
const EVENT_HIT := "hit"
const EVENT_GROUND := "ground"

enum Phase { FLY, FALL, REST }


## Havuzun bir oku: bir yay parçası (from, velocity, gravity, accel) ve o parçanın saati t.
class Shot:
	extends RefCounted
	var id := 0
	var born := 0
	var phase: int = Phase.FLY
	var blunt := false
	var from := Vector3.ZERO
	var velocity := Vector3.ZERO
	var gravity := GRAVITY
	## Rüzgârın yan ivmesi (m/sn²): atışta donar.
	var accel := Vector2.ZERO
	var t := 0.0
	## Toplam uçuş ve yerde bekleme süresi.
	var flight := 0.0
	var rest_age := 0.0
	var rest_at := Vector3.ZERO
	var rest_dir := Vector3.BACK
	## Hedef verisi (sahip olan kod için; kimlik, tag).
	var info: Dictionary = {}

	func position() -> Vector3:
		return rest_at if phase == Phase.REST else Projectiles.point_at(from, velocity, gravity, t, accel)

	func direction() -> Vector3:
		if phase == Phase.REST:
			return rest_dir
		var v := Projectiles.velocity_at(velocity, gravity, t, accel)
		return v.normalized() if v.length_squared() > 0.000001 else Vector3.BACK


var shots: Array[Shot] = []
var _seq := 0
var _clock := 0
var _rng := RandomNumberGenerator.new()


func _init(p_seed: int = 3421) -> void:
	_rng.seed = p_seed


# --- Yörünge (saf) --------------------------------------------------------------------------------

## from'dan to'ya yörünge: tepesi kirişin arc × yatay uzaklık üstünde olan parabol, süre = uzaklık / hız. Döner {velocity, gravity, time}.
static func solve(from: Vector3, to: Vector3, speed: float, arc: float) -> Dictionary:
	var along := to - from
	var v := maxf(speed, 1.0)
	var time := maxf(along.length() / v, 0.05)
	var horizontal := Vector2(along.x, along.z).length()
	var h := maxf(arc, 0.0) * horizontal
	return {"velocity": along / time + Vector3.UP * (4.0 * h / time), "gravity": 8.0 * h / (time * time), "time": time}


## Yolun t anındaki noktası.
static func point_at(from: Vector3, velocity: Vector3, gravity: float, t: float, accel := Vector2.ZERO) -> Vector3:
	return from + velocity * t + Vector3(accel.x, -gravity, accel.y) * (0.5 * t * t)


## Yolun t anındaki hızı.
static func velocity_at(velocity: Vector3, gravity: float, t: float, accel := Vector2.ZERO) -> Vector3:
	return velocity + Vector3(accel.x, -gravity, accel.y) * t


## İniş noktası (nişan halkası ve telgraf okur): rüzgârsızken to; rüzgârda düşey hareket değişmez, iniş to + ½·a·T².
static func predict(from: Vector3, to: Vector3, speed: float, accel := Vector2.ZERO) -> Vector3:
	var time := maxf((to - from).length() / maxf(speed, 1.0), 0.05)
	return to + Vector3(accel.x, 0.0, accel.y) * (0.5 * time * time)


## a→b kesitinin küreyle ilk kesiştiği oran (0..1; kesişmiyorsa -1). a kürenin içindeyse 0.
static func segment_sphere(a: Vector3, b: Vector3, center: Vector3, radius: float) -> float:
	var d := b - a
	var f := a - center
	var c := f.length_squared() - radius * radius
	if c <= 0.0:
		return 0.0
	var aa := d.length_squared()
	if aa < 0.00000001:
		return -1.0
	var bb := f.dot(d)
	var disc := bb * bb - aa * c
	if disc < 0.0:
		return -1.0
	var hit := (-bb - sqrt(disc)) / aa
	return hit if hit >= 0.0 and hit <= 1.0 else -1.0


# --- Havuz ---------------------------------------------------------------------------------------

## Oku atar: from → to. options: speed (22), arc (0,06), blunt (false), wind (Vector2, m/sn; atışta donar), drift (rüzgâr katsayısı, 0,15),
## info (Dictionary). Oku havuza koyar, kimliğini döndürür.
func fire(from: Vector3, to: Vector3, options: Dictionary = {}) -> int:
	var path := Projectiles.solve(from, to, float(options.get("speed", 22.0)), float(options.get("arc", 0.06)))
	var shot := _take()
	_seq += 1
	_clock += 1
	shot.id = _seq
	shot.born = _clock
	shot.phase = Phase.FLY
	shot.blunt = bool(options.get("blunt", false))
	shot.from = from
	shot.velocity = path["velocity"]
	shot.gravity = path["gravity"]
	shot.accel = (options.get("wind", Vector2.ZERO) as Vector2) * float(options.get("drift", 0.15))
	shot.t = 0.0
	shot.flight = 0.0
	shot.rest_age = 0.0
	shot.info = options.get("info", {})
	return shot.id


## Bir adım: uçan oklar ilerler, yatanlar yaşlanır. ground: (x, z) → yükseklik (boşsa zemin yok); targets: [{id, center (Vector3), radius}, ...].
## Döner: olaylar [{type, shot (kimlik), point, target (hedefin id'si), info}].
func step(delta: float, ground: Callable = Callable(), targets: Array = []) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if delta <= 0.0:
		return events
	for i in range(shots.size() - 1, -1, -1):
		var shot := shots[i]
		if shot.phase == Phase.REST:
			shot.rest_age += delta
			if shot.rest_age >= GROUND_S:
				shots.remove_at(i)
			continue
		shot.flight += delta
		if shot.flight >= MAX_FLIGHT:
			shots.remove_at(i)
			continue
		_fly(shot, delta, ground, targets, events)
	return events


func clear() -> void:
	shots.clear()


func flying_count() -> int:
	var n := 0
	for shot in shots:
		if shot.phase != Phase.REST:
			n += 1
	return n


func resting_count() -> int:
	return shots.size() - flying_count()


## Çizim dönüşümleri: tip yerelde başlangıçta, gövde -Z boyunca, yön +Z. Yatan ok ömrünün son FADE_S'inde küçülür.
func transforms() -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	for shot in shots:
		var dir := shot.direction()
		var up := Vector3.UP if absf(dir.y) < 0.999 else Vector3.RIGHT
		var basis := Basis.looking_at(-dir, up)
		if shot.phase == Phase.REST:
			var fade := 1.0 - smoothstep(GROUND_S - FADE_S, GROUND_S, shot.rest_age)
			basis = basis.scaled(Vector3.ONE * maxf(fade, 0.001))
		out.append(Transform3D(basis, shot.position()))
	return out


func _fly(shot: Shot, delta: float, ground: Callable, targets: Array, events: Array[Dictionary]) -> void:
	var speed := Projectiles.velocity_at(shot.velocity, shot.gravity, shot.t, shot.accel).length()
	var count := maxi(ceili(speed * delta / STEP_M), 1)
	var h := delta / float(count)
	for _i in count:
		var a := shot.position()
		var next_t := shot.t + h
		var b := Projectiles.point_at(shot.from, shot.velocity, shot.gravity, next_t, shot.accel)
		if shot.phase == Phase.FLY and _hit_target(shot, a, b, targets, events):
			return
		if ground.is_valid() and b.y <= float(ground.call(b.x, b.z)):
			_land(shot, a, b, next_t, ground, events)
			return
		shot.t = next_t


## Yoldaki ilk hedef: olay yazılır, küt ok seker (uçuş biter, düşer), saplanan ok düşmez, havuzdan çıkar.
func _hit_target(shot: Shot, a: Vector3, b: Vector3, targets: Array, events: Array[Dictionary]) -> bool:
	var best := -1.0
	var hit_target: Variant = null
	for target: Dictionary in targets:
		var at := Projectiles.segment_sphere(a, b, target["center"], float(target["radius"]) + HIT_EPS)
		if at >= 0.0 and (best < 0.0 or at < best):
			best = at
			hit_target = target
	if hit_target == null:
		return false
	var point := a.lerp(b, best)
	events.append({"type": EVENT_HIT, "shot": shot.id, "point": point, "target": (hit_target as Dictionary).get("id"), "info": shot.info})
	if shot.blunt:
		_deflect(shot, point, (b - a).normalized())
	else:
		shots.erase(shot)
	return true


## Seker: hızın küçük bir kısmı geri ve yukarı, yana rastgele; bir daha vurmaz, yere inince yatar.
func _deflect(shot: Shot, point: Vector3, dir: Vector3) -> void:
	var speed := minf(Projectiles.velocity_at(shot.velocity, shot.gravity, shot.t, shot.accel).length(), 30.0) * 0.12
	var side := (_rng.randf() - 0.5) * 1.6
	shot.from = point - dir * 0.04
	shot.velocity = Vector3(-dir.x * speed - dir.z * side, 1.4 + _rng.randf() * 0.8, -dir.z * speed + dir.x * side)
	shot.gravity = GRAVITY
	shot.accel = Vector2.ZERO
	shot.t = 0.0
	shot.phase = Phase.FALL


## Zemin: kesin nokta ikiye bölmeyle bulunur. Küt ok yatar (uçuşun yatay yönünde), saplanan ok gömülür. Uçarken değdiyse olay yazılır.
func _land(shot: Shot, a: Vector3, b: Vector3, next_t: float, ground: Callable, events: Array[Dictionary]) -> void:
	var lo := 0.0
	var hi := 1.0
	for _k in BISECT:
		var mid := (lo + hi) * 0.5
		var p := a.lerp(b, mid)
		if p.y > float(ground.call(p.x, p.z)):
			lo = mid
		else:
			hi = mid
	var point := a.lerp(b, hi)
	var v := Projectiles.velocity_at(shot.velocity, shot.gravity, next_t, shot.accel)
	var was_flying := shot.phase == Phase.FLY
	if shot.blunt or not was_flying:
		var flat := Vector3(v.x, 0.0, v.z)
		flat = flat.normalized() if flat.length_squared() > 0.000001 else Vector3.BACK
		shot.rest_dir = (flat + Vector3.DOWN * 0.04).normalized()
		shot.rest_at = Vector3(point.x, float(ground.call(point.x, point.z)) + REST_LIFT, point.z)
	else:
		shot.rest_dir = v.normalized() if v.length_squared() > 0.000001 else Vector3.DOWN
		shot.rest_at = point + shot.rest_dir * BURY
	shot.phase = Phase.REST
	shot.rest_age = 0.0
	if was_flying:
		events.append({"type": EVENT_GROUND, "shot": shot.id, "point": shot.rest_at, "target": null, "info": shot.info})


func _take() -> Shot:
	if shots.size() < CAPACITY:
		var fresh := Shot.new()
		shots.append(fresh)
		return fresh
	var oldest_rest: Shot = null
	var oldest: Shot = null
	for shot in shots:
		if shot.phase == Phase.REST and (oldest_rest == null or shot.born < oldest_rest.born):
			oldest_rest = shot
		if oldest == null or shot.born < oldest.born:
			oldest = shot
	return oldest_rest if oldest_rest else oldest
