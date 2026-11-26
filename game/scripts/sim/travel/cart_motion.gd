class_name CartMotion
extends RefCounted
## Arabanın hareketinin saf hesabı (travel.md §3.5; Yol Haritası roads-relays): tek dingilli römork. Çeken hayvanın kökü (koşum noktası,
## hitch) yolun üstünde yürür; arabanın yönü θ römork denklemiyle izler, dingil koşumun L gerisindedir:
##   θ'   = (v / L) · sin(ψ − θ)        (ψ: koşumun gidiş yönü; L = 2,70 m)
##   axle = hitch − L · (sin θ, cos θ)
##   pitch = atan2(y(hitch) − y(axle), L),  roll = atan((y(sol teker) − y(sağ teker)) / iz)
##   teker dönüşü ω = v / R
## Yön (heading) travel.md'nin kuralıdır: atan2(dx, dz), 0 güney (+Z), π/2 doğu. Ağaca dokunmaz; RoadCart ve TravelLayer kullanır.
##   theta = CartMotion.step_heading(theta, hitch_now - hitch_before, 2.7)
##   var axle := CartMotion.axle_of(hitch_now, theta, 2.7)
##   var path := CartMotion.pull_over(points, 1.6, 12.0, true)     # yolun sonunda sağa çekilir (durak: dingil yolun 1,6 m sağında)


## Römorkun yönü bir adımda (saf): koşum hitch_move kadar yürüdü.
static func step_heading(theta: float, hitch_move: Vector2, length: float) -> float:
	var d := hitch_move.length()
	if d < 0.000001 or length <= 0.0:
		return theta
	var psi := atan2(hitch_move.x, hitch_move.y)
	# Düz adımın tam çözümü (φ = θ − ψ, dφ/ds = −sin φ / L): tan(φ/2) = tan(φ0/2) · e^(−d/L). Büyük adımda da (kare takılması,
	# karartmada taşıma) kararlıdır; geri giderken (φ0 ≈ π) yön dönmez.
	var phi0 := angle_difference(psi, theta)
	if absf(absf(phi0) - PI) < 0.0001:
		return theta
	var phi := 2.0 * atan(tan(phi0 * 0.5) * exp(-d / length))
	return wrapf(psi + phi, -PI, PI)


## Dingilin yeri (saf): koşumun L gerisinde, arabanın yönünde.
static func axle_of(hitch: Vector2, theta: float, length: float) -> Vector2:
	return hitch - Vector2(sin(theta), cos(theta)) * length


## Yönün birim vektörü (x, z) ve sağı (yüz güneyde ise sağ batıdır).
static func forward(theta: float) -> Vector2:
	return Vector2(sin(theta), cos(theta))


static func right(theta: float) -> Vector2:
	return Vector2(-cos(theta), sin(theta))


## Eğim ve yatış (saf; radyan): koşumla dingil arası yükseklik farkı, iki teker arası fark (track: tekerin yarı izi, m).
static func pitch_of(h_hitch: float, h_axle: float, length: float) -> float:
	return atan2(h_hitch - h_axle, maxf(length, 0.01))


static func roll_of(h_left: float, h_right: float, track: float) -> float:
	return atan2(h_left - h_right, maxf(2.0 * track, 0.01))


## Tekerin açısı (saf): ds yol (m), R yarıçap; ileri yürüyüşte teker yerel X ekseninde öne döner.
static func spin(angle: float, ds: float, radius: float) -> float:
	return wrapf(angle + ds / maxf(radius, 0.01), -TAU, TAU)


## Çizgiyi sona doğru (at_end) ya da baştan (not at_end) yana çeker (saf): son over_m metrede yanal kayma 0'dan side_m'ye yumuşakça
## (smoothstep) artar; side_m artı sağdır. Durakta dingil yolun sağında durur, kalkışta yola geri döner.
static func pull_over(points: PackedVector2Array, side_m: float, over_m: float, at_end := true) -> PackedVector2Array:
	var n := points.size()
	if n < 2 or absf(side_m) < 0.001 or over_m <= 0.0:
		return points.duplicate()
	var cum := RoadGraph.cumulative(points)
	var total := float(cum[n - 1])
	# Kaymanın başladığı yerde yeni köşe: kayma o noktadan yumuşakça başlasın (seyrek köşeli çizgide de).
	var src := CartMotion.densify(points, 2.0)
	var src_cum := RoadGraph.cumulative(src)
	var out := PackedVector2Array()
	for i in src.size():
		var s := float(src_cum[i])
		var into := (s - (total - over_m)) / over_m if at_end else (over_m - s) / over_m
		var k := smoothstep(0.0, 1.0, clampf(into, 0.0, 1.0))
		var h := RoadGraph.heading_at(src, src_cum, clampf(s - 0.01 if i == src.size() - 1 else s, 0.0, total))
		out.append(src[i] + CartMotion.right(h) * side_m * k)
	return out


## Çizginin köşelerini step metreden seyrek olmayacak biçimde sıklaştırır (saf; uçlar ve köşeler korunur).
static func densify(points: PackedVector2Array, step: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	if points.is_empty():
		return out
	out.append(points[0])
	for i in range(1, points.size()):
		var a := points[i - 1]
		var b := points[i]
		var k := maxi(1, ceili(a.distance_to(b) / maxf(step, 0.1)))
		for j in range(1, k + 1):
			out.append(a.lerp(b, float(j) / float(k)))
	return out


## Köşeleri yayla açar (saf; travel.md §3.5 «yol köşeleri açılır, en küçük yarıçap 6 m»): her iç köşenin iki yanında r = min(radius, komşu
## parçaların yarısı) kadar geri ve ileri noktalar arası, köşenin kendisi denetim noktası olan ikinci derece eğri (8 parça). Uçlar korunur.
static func fillet(points: PackedVector2Array, radius: float, segments := 8) -> PackedVector2Array:
	var n := points.size()
	if n < 3 or radius <= 0.0:
		return points.duplicate()
	var out := PackedVector2Array()
	out.append(points[0])
	for i in range(1, n - 1):
		var a := points[i - 1]
		var b := points[i]
		var c := points[i + 1]
		var la := a.distance_to(b)
		var lc := b.distance_to(c)
		if la < 0.001 or lc < 0.001:
			continue
		var r := minf(radius, minf(la, lc) * 0.5)
		var p0 := b + (a - b) / la * r
		var p2 := b + (c - b) / lc * r
		# Neredeyse düz köşe yay istemez.
		if absf((b - a).normalized().cross((c - b).normalized())) < 0.01 and (b - a).dot(c - b) > 0.0:
			out.append(b)
			continue
		for k in segments + 1:
			var t := float(k) / float(segments)
			out.append(p0 * (1.0 - t) * (1.0 - t) + b * 2.0 * (1.0 - t) * t + p2 * t * t)
	out.append(points[n - 1])
	return out


## Çizgiyi sonunda dümdüz uzatır (saf): koşum son noktanın extra_m ötesine yürüsün, dingil son noktada dursun.
static func extend(points: PackedVector2Array, extra_m: float) -> PackedVector2Array:
	var out := points.duplicate()
	var n := points.size()
	if n < 2 or extra_m <= 0.0:
		return out
	var dir := (points[n - 1] - points[n - 2]).normalized()
	out.append(points[n - 1] + dir * extra_m)
	return out


## Hızın hedefi (saf): kalan yol remaining (m) ile durmak için yavaşlama (decel, m/sn²) sınırı; en çok top.
static func target_speed(remaining: float, top: float, decel: float, crawl := 0.6) -> float:
	if remaining <= 0.0:
		return 0.0
	return minf(top, maxf(sqrt(2.0 * maxf(decel, 0.01) * remaining), crawl))
