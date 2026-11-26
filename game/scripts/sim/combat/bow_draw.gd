class_name BowDraw
extends RefCounted
## Yayı germek ve bırakmak (saf; progression.md §7.2 «sağ tuş bas çek, bırak at», architecture.md §3.9). Tuş basılıyken kiriş gerilir,
## bırakınca atılır. Kısa tıklama min_draw oranına gerip atar; tam gerildikten sonra yayılma steady sürede yarıya iner («tutuş süresi
## isabeti artırır»); hold_max dolunca kol yorulur, kendiliğinden bırakır. Az gerilen kiriş kısa düşer ve daha çok saçılır.
##
##   var draw := BowDraw.new(Weapons.bow("toy_bow"))
##   draw.begin()
##   if draw.tick(delta):               # bu adımda ok çıkar
##       var k := draw.loosed_k         # atıştaki gerilme oranı

## Yarım gerilişte yayılmanın en büyük çarpanı ve kol yorulunca yayılmanın yarısı.
const SLACK_SPREAD := 2.2
const STEADY_SPREAD := 0.5
## Az gerilen kirişte uzaklık ve hız çarpanının alt sınırı.
const SLACK_REACH := 0.5
const SLACK_SPEED := 0.6

var spec: Dictionary = {}
## Germe süresi (sn; gerilmiyorsa 0) ve sonraki germeye kalan süre.
var held := 0.0
var cooldown := 0.0
## Atış anındaki gerilme oranı (son atış).
var loosed_k := 0.0

var _drawing := false
var _release := false


func _init(p_spec: Dictionary = {}) -> void:
	spec = p_spec


func is_drawing() -> bool:
	return _drawing


## Germeye başlar; zaten geriliyorsa ya da bekleme sürüyorsa false.
func begin() -> bool:
	if _drawing or cooldown > 0.0:
		return false
	_drawing = true
	_release = false
	held = 0.0
	return true


## Bırakma isteği: min_draw dolunca ok çıkar.
func release() -> void:
	if _drawing:
		_release = true


## Germeyi oksuz bırakır.
func cancel() -> void:
	_drawing = false
	_release = false
	held = 0.0


## Bir adım; bu adımda ok çıktıysa true (loosed_k okunur).
func tick(delta: float) -> bool:
	cooldown = maxf(cooldown - maxf(delta, 0.0), 0.0)
	if not _drawing:
		return false
	held += maxf(delta, 0.0)
	var k := draw_k()
	if (_release and k >= float(spec.get("min_draw", 0.0))) or held >= float(spec.get("hold_max", INF)):
		loosed_k = k
		_drawing = false
		_release = false
		cooldown = float(spec.get("cooldown", 0.0))
		held = 0.0
		return true
	return false


## Gerilme oranı (0..1).
func draw_k() -> float:
	var draw_s := float(spec.get("draw", 0.0))
	return clampf(held / draw_s, 0.0, 1.0) if draw_s > 0.0 else 1.0


## O anki yayılma (derece, tam koni): gerilme arttıkça daralır, tam gerildikten sonra steady sürede yarıya iner.
func spread_deg() -> float:
	var base := float(spec.get("spread", 0.0))
	var k := draw_k()
	if k < 1.0:
		return base * lerpf(SLACK_SPREAD, 1.0, k)
	var steady_s := float(spec.get("steady", 0.0))
	var steady := clampf((held - float(spec.get("draw", 0.0))) / steady_s, 0.0, 1.0) if steady_s > 0.0 else 1.0
	return base * lerpf(1.0, STEADY_SPREAD, steady)


## Gerilme oranından uzaklık ve hız çarpanı (saf).
static func reach_k(k: float) -> float:
	return lerpf(SLACK_REACH, 1.0, clampf(k, 0.0, 1.0))


static func speed_k(k: float) -> float:
	return lerpf(SLACK_SPEED, 1.0, clampf(k, 0.0, 1.0))


## Yayılma: nişan noktası atışın düzleminde bir disk içinde kayar (saf). spread_deg: tam koni; u, v: 0..1 arası iki rastgele sayı.
static func scatter(from: Vector3, to: Vector3, p_spread_deg: float, u: float, v: float) -> Vector3:
	var along := to - from
	var distance := along.length()
	if distance < 0.0001:
		return to
	var dir := along / distance
	var side := Vector3(dir.z, 0.0, -dir.x)
	side = side.normalized() if side.length_squared() > 0.00000001 else Vector3.RIGHT
	var lift := side.cross(dir).normalized()
	var radius := distance * tan(deg_to_rad(p_spread_deg) * 0.5) * sqrt(clampf(u, 0.0, 1.0))
	var angle := clampf(v, 0.0, 1.0) * TAU
	return to + side * cos(angle) * radius + lift * sin(angle) * radius
