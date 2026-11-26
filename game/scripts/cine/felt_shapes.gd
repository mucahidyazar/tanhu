class_name FeltShapes
extends RefCounted
## Keçe aplike şekillerinin saf dış hat üreticileri (Yol Haritası myth-panels; story.md §3 satır 1–6, godot.md §3.6).
## Düğüm kurmaz: FeltPanel bu dış hatları üçgenler, kenarına dikiş şeridi kurar. Her dış hat kapalıdır (son nokta
## ilkine bağlanır, yinelenmez), kendini kesmez ve saat yönünün tersindedir (y yukarı; işaretli alan > 0). Birimler
## metredir; şekiller ölçü 1'de yaklaşık 1 m'dir, p.size (ya da w, h) ile büyür. Karmaşık biçimler (kaz, at, insan,
## ağaç) basit parçaların (elips, konik kapsül, üçgen) birleşimidir (Geometry2D.merge_polygons): dış hat temiz kalır.
##
##   FeltShapes.make("goose", {"size": 0.8})     # [PackedVector2Array]; çember iki yay döndürür
##   FeltShapes.recommended_stitch("tree9", p)   # dikiş şeridinin en çok genişliği (ince dallarda dar)
##
## Şekiller ve parametreleri (hepsinde size; ayrıca):
##   circle {r}, ellipse {rx, ry}, ring {r, inner}, arc {r, inner, from, to (derece)}, rect {w, h}, strip {w, h},
##   wave_band {w, h, amp, waves, phase}, hills {w, h, amp, seed}, stone {r, aspect, rough, seed}, spark {r, inner,
##   points, seed}, star {r, inner, points}, goose, goose_wing, horse, human, tree9, yurt, dome {w, h}, stake {h},
##   river {w, h, amp, waves}, bridge {w, sag, t}, flame {seed}, shadow, bundle.

const KINDS: Array[String] = ["circle", "ellipse", "ring", "arc", "rect", "strip", "wave_band", "hills", "stone",
	"spark", "star", "goose", "goose_wing", "horse", "human", "tree9", "yurt", "dome", "stake", "river", "bridge",
	"flame", "shadow", "bundle"]
## Dikiş şeridinin varsayılan ve en dar genişliği (m).
const STITCH := 0.03
const STITCH_MIN := 0.006
## Şeklin en ince yerinin genişliği (ölçü 1'de, m): şerit bunun %35'ini geçmez (iç halka kendini kesmesin).
const THINNEST := {
	"goose": 0.1, "goose_wing": 0.08, "horse": 0.06, "human": 0.07, "tree9": 0.024, "stake": 0.03, "bridge": 0.025,
	"flame": 0.12, "shadow": 0.2, "bundle": 0.07, "strip": 0.0, "river": 0.0, "spark": 0.05, "star": 0.06,
}


## Şeklin dış hatları (çoğu bir tane; çember iki yay). Bilinmeyen tür boş döner.
static func make(kind: String, p: Dictionary = {}) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	var s := float(p.get("size", 1.0))
	match kind:
		"circle":
			out.append(ellipse(Vector2.ZERO, float(p.get("r", 0.5)) * s, float(p.get("r", 0.5)) * s, int(p.get("segments", 32))))
		"ellipse":
			out.append(ellipse(Vector2.ZERO, float(p.get("rx", 0.5)) * s, float(p.get("ry", 0.3)) * s, int(p.get("segments", 32))))
		"ring":
			var r := float(p.get("r", 0.5)) * s
			var inner := float(p.get("inner", 0.38)) * s
			out.append(arc(r, inner, 0.0, PI))
			out.append(arc(r, inner, PI, TAU))
		"arc":
			out.append(arc(float(p.get("r", 0.5)) * s, float(p.get("inner", 0.38)) * s,
					deg_to_rad(float(p.get("from", 0.0))), deg_to_rad(float(p.get("to", 180.0)))))
		"rect":
			out.append(rect(float(p.get("w", 1.0)) * s, float(p.get("h", 1.0)) * s))
		"strip":
			out.append(rect(float(p.get("w", 1.0)) * s, float(p.get("h", 0.04)) * s))
		"wave_band":
			out.append(wave_band(float(p.get("w", 5.0)) * s, float(p.get("h", 0.6)) * s, float(p.get("amp", 0.08)) * s,
					float(p.get("waves", 4.0)), float(p.get("phase", 0.0))))
		"hills":
			out.append(hills(float(p.get("w", 5.0)) * s, float(p.get("h", 0.5)) * s, float(p.get("amp", 0.12)) * s,
					int(p.get("seed", 1))))
		"stone":
			out.append(stone(float(p.get("r", 0.3)) * s, float(p.get("aspect", 0.75)), float(p.get("rough", 0.12)),
					int(p.get("seed", 1))))
		"spark":
			out.append(spark(float(p.get("r", 0.2)) * s, float(p.get("inner", 0.07)) * s, int(p.get("points", 8)),
					int(p.get("seed", 1))))
		"star":
			out.append(star(float(p.get("r", 0.1)) * s, float(p.get("inner", 0.045)) * s, int(p.get("points", 5))))
		"goose":
			out.append(_scaled(goose(), s))
		"goose_wing":
			out.append(_scaled(goose_wing(), s))
		"horse":
			out.append(_scaled(horse(), s))
		"human":
			out.append(_scaled(human(), s))
		"tree9":
			out.append(_scaled(tree9(), s))
		"yurt":
			out.append(_scaled(yurt(), s))
		"dome":
			out.append(dome(float(p.get("w", 1.0)) * s, float(p.get("h", 0.5)) * s))
		"stake":
			out.append(_scaled(stake(float(p.get("h", 0.6))), s))
		"river":
			out.append(river(float(p.get("w", 3.0)) * s, float(p.get("h", 0.25)) * s, float(p.get("amp", 0.12)) * s,
					float(p.get("waves", 2.0))))
		"bridge":
			out.append(bridge(float(p.get("w", 2.0)) * s, float(p.get("sag", 0.18)) * s, float(p.get("t", 0.025)) * s))
		"flame":
			out.append(_scaled(flame(int(p.get("seed", 1))), s))
		"shadow":
			out.append(_scaled(shadow(), s))
		"bundle":
			out.append(_scaled(bundle(), s))
	return out


## Dikiş şeridinin genişliği: istenen (varsayılan STITCH) ama şeklin en ince yerinin %35'inden geniş değil.
static func recommended_stitch(kind: String, p: Dictionary = {}, wanted: float = STITCH) -> float:
	var s := float(p.get("size", 1.0))
	var thin := float(THINNEST.get(kind, 1.0)) * s
	if kind == "strip":
		thin = float(p.get("h", 0.04)) * s
	elif kind == "river":
		thin = float(p.get("h", 0.25)) * s
	elif kind == "bridge":
		thin = float(p.get("t", 0.025)) * s
	elif kind == "ring" or kind == "arc":
		thin = (float(p.get("r", 0.5)) - float(p.get("inner", 0.38))) * s
	return clampf(minf(wanted, thin * 0.35), STITCH_MIN, wanted)


# --- Temel biçimler ---------------------------------------------------------------------------------

static func ellipse(c: Vector2, rx: float, ry: float, segments: int = 32, rot: float = 0.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := maxi(segments, 6)
	for i in n:
		var a := TAU * float(i) / float(n)
		out.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return out


## Halka dilimi: r ile inner arasında, from'dan to'ya (radyan, saat yönünün tersine).
static func arc(r: float, inner: float, from: float, to: float, segments: int = 24) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := maxi(segments, 3)
	for i in n + 1:
		var a := lerpf(from, to, float(i) / float(n))
		out.append(Vector2(cos(a), sin(a)) * r)
	for i in range(n, -1, -1):
		var a := lerpf(from, to, float(i) / float(n))
		out.append(Vector2(cos(a), sin(a)) * inner)
	return out


static func rect(w: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(-w, -h) * 0.5, Vector2(w, -h) * 0.5, Vector2(w, h) * 0.5, Vector2(-w, h) * 0.5])


## Dalga bandı: alt kenar düz (y = 0), üst kenar h çevresinde dalgalanır.
static func wave_band(w: float, h: float, amp: float, waves: float, phase: float) -> PackedVector2Array:
	var out := PackedVector2Array([Vector2(-w * 0.5, 0.0), Vector2(w * 0.5, 0.0)])
	var n := maxi(int(waves * 10.0), 12)
	for i in range(n, -1, -1):
		var u := float(i) / float(n)
		var x := lerpf(-w * 0.5, w * 0.5, u)
		# Sivri tepeli dalga: sinüsün üstü keskinleşir.
		var s := sin(TAU * waves * u + phase)
		out.append(Vector2(x, h + amp * (s - 0.35 * s * s)))
	return out


## Tepeler: alt kenar düz, üst kenar iki sinüsün toplamıyla yumuşak tepeler.
static func hills(w: float, h: float, amp: float, seed_value: int) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var f1 := 1.0 + rng.randf()
	var f2 := 2.5 + rng.randf() * 1.5
	var p1 := rng.randf() * TAU
	var p2 := rng.randf() * TAU
	var out := PackedVector2Array([Vector2(-w * 0.5, 0.0), Vector2(w * 0.5, 0.0)])
	var n := 40
	for i in range(n, -1, -1):
		var u := float(i) / float(n)
		out.append(Vector2(lerpf(-w * 0.5, w * 0.5, u), h + amp * (0.7 * sin(TAU * f1 * u + p1) + 0.3 * sin(TAU * f2 * u + p2))))
	return out


## Taş: yarıçapı tohumlu gürültüyle oynayan yıldız biçimli (her yöne tek kesişim: kendini kesmez) yuvarlak.
static func stone(r: float, aspect: float, rough: float, seed_value: int, segments: int = 20) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var offsets := PackedFloat32Array()
	for i in 5:
		offsets.append(rng.randf() * TAU)
	var out := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		var k := 1.0 + rough * (0.6 * sin(2.0 * a + offsets[0]) + 0.3 * sin(3.0 * a + offsets[1]) + 0.25 * sin(5.0 * a + offsets[2]))
		out.append(Vector2(cos(a) * r * k, sin(a) * r * aspect * k))
	return out


## Kıvılcım: düzensiz uçlu ışın patlaması.
static func spark(r: float, inner: float, points: int, seed_value: int) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var out := PackedVector2Array()
	var n := maxi(points, 3)
	for i in n * 2:
		var a := PI * 0.5 + PI * float(i) / float(n) + (rng.randf() - 0.5) * 0.18
		var rr := r * (0.65 + 0.35 * rng.randf()) if i % 2 == 0 else inner * (0.8 + 0.3 * rng.randf())
		out.append(Vector2(cos(a), sin(a)) * rr)
	return out


static func star(r: float, inner: float, points: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := maxi(points, 3)
	for i in n * 2:
		var a := PI * 0.5 + PI * float(i) / float(n)
		out.append(Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else inner))
	return out


## Kubbe: yarım elips (gök çadırı); taban y = 0.
static func dome(w: float, h: float, segments: int = 32) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in segments + 1:
		var a := PI * float(i) / float(segments)
		out.append(Vector2(cos(a) * w * 0.5, sin(a) * h))
	# Taban: soldan sağa (CCW kapanış).
	return _ccw(out)


## Irmak: sinüs boyunca kıvrılan, h kalınlığında şerit.
static func river(w: float, h: float, amp: float, waves: float) -> PackedVector2Array:
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	var n := maxi(int(waves * 16.0), 16)
	for i in n + 1:
		var u := float(i) / float(n)
		var x := lerpf(-w * 0.5, w * 0.5, u)
		var y := amp * sin(TAU * waves * u)
		var taper := 0.55 + 0.45 * u
		bottom.append(Vector2(x, y - h * 0.5 * taper))
		top.append(Vector2(x, y + h * 0.5 * taper))
	top.reverse()
	bottom.append_array(top)
	return bottom


## At kılından köprü: ırmağın üstünde sarkan ince yay ve iki uçta kısa kazık.
static func bridge(w: float, sag: float, t: float) -> PackedVector2Array:
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	var n := 32
	for i in n + 1:
		var u := float(i) / float(n)
		var x := lerpf(-w * 0.5, w * 0.5, u)
		var y := -sag * (1.0 - pow(2.0 * u - 1.0, 2.0))
		bottom.append(Vector2(x, y - t * 0.5))
		top.append(Vector2(x, y + t * 0.5))
	top.reverse()
	bottom.append_array(top)
	var posts: Array = [bottom]
	for side: float in [-1.0, 1.0]:
		var x0 := side * w * 0.5
		posts.append(PackedVector2Array([Vector2(x0 - t * 1.2, -t * 6.0), Vector2(x0 + t * 1.2, -t * 6.0),
			Vector2(x0 + t * 1.2, t * 3.0), Vector2(x0 - t * 1.2, t * 3.0)]))
	return union(posts)


# --- Canlılar ve nesneler (ölçü 1) ---------------------------------------------------------------------

## Uçan kaz (sağa bakar): gövde, boyun, baş, gaga, kuyruk. Kanat ayrı parçadır (goose_wing), omuzdan döner.
static func goose() -> PackedVector2Array:
	return union([
		ellipse(Vector2(0.0, 0.0), 0.42, 0.15, 28, -0.06),
		capsule(Vector2(0.28, 0.03), Vector2(0.62, 0.13), 0.075, 0.048),
		ellipse(Vector2(0.67, 0.135), 0.085, 0.065, 20),
		capsule(Vector2(0.72, 0.13), Vector2(0.86, 0.115), 0.03, 0.014, 12),
		capsule(Vector2(-0.34, -0.01), Vector2(-0.56, -0.03), 0.07, 0.022, 12),
	])


## Kazın kanadı: omuz (0, 0) dönme noktasıdır; kanat geriye ve yukarı açılır, arka kenarı tüylüdür.
static func goose_wing() -> PackedVector2Array:
	return _ccw(PackedVector2Array([Vector2(0.07, -0.02), Vector2(0.02, 0.1), Vector2(-0.1, 0.3), Vector2(-0.28, 0.5),
		Vector2(-0.42, 0.56), Vector2(-0.37, 0.46), Vector2(-0.45, 0.42), Vector2(-0.38, 0.34), Vector2(-0.46, 0.29),
		Vector2(-0.36, 0.21), Vector2(-0.42, 0.14), Vector2(-0.28, 0.07), Vector2(-0.16, -0.02)]))


## Tırısta at (sağa bakar), yere basan toynaklar y ≈ 0: gövde, boyun, baş, kulak, dört bacak, kuyruk.
static func horse() -> PackedVector2Array:
	return union([
		ellipse(Vector2(0.0, 0.55), 0.42, 0.17, 28),
		capsule(Vector2(0.3, 0.6), Vector2(0.5, 0.88), 0.12, 0.075),
		capsule(Vector2(0.5, 0.9), Vector2(0.68, 0.74), 0.075, 0.042),
		PackedVector2Array([Vector2(0.44, 0.93), Vector2(0.49, 1.03), Vector2(0.53, 0.93)]),
		capsule(Vector2(0.29, 0.47), Vector2(0.4, 0.03), 0.048, 0.03),
		capsule(Vector2(0.19, 0.47), Vector2(0.12, 0.03), 0.048, 0.03),
		capsule(Vector2(-0.27, 0.47), Vector2(-0.38, 0.03), 0.05, 0.03),
		capsule(Vector2(-0.18, 0.47), Vector2(-0.1, 0.04), 0.05, 0.03),
		capsule(Vector2(-0.39, 0.62), Vector2(-0.58, 0.3), 0.055, 0.024),
	])


## Ayakta insan (önden): baş, boyun, kaftan, kollar, bacaklar; ayaklar y ≈ 0.
static func human() -> PackedVector2Array:
	return union([
		ellipse(Vector2(0.0, 0.89), 0.085, 0.09, 20),
		capsule(Vector2(0.0, 0.78), Vector2(0.0, 0.86), 0.035, 0.035),
		PackedVector2Array([Vector2(-0.19, 0.18), Vector2(0.19, 0.18), Vector2(0.11, 0.8), Vector2(-0.11, 0.8)]),
		capsule(Vector2(0.1, 0.74), Vector2(0.21, 0.42), 0.04, 0.032),
		capsule(Vector2(-0.1, 0.74), Vector2(-0.21, 0.42), 0.04, 0.032),
		capsule(Vector2(0.07, 0.22), Vector2(0.08, 0.02), 0.042, 0.038),
		capsule(Vector2(-0.07, 0.22), Vector2(-0.08, 0.02), 0.042, 0.038),
	])


## Dokuz dallı ağaç: incelen gövde, sağa sola dokuz dal ve uçlarında yaprak öbeği; kök y = 0.
static func tree9() -> PackedVector2Array:
	var parts: Array = [
		capsule(Vector2(0.0, 0.0), Vector2(0.0, 0.8), 0.06, 0.028),
		PackedVector2Array([Vector2(-0.16, 0.0), Vector2(0.16, 0.0), Vector2(0.03, 0.12), Vector2(-0.03, 0.12)]),
	]
	for k in 9:
		var y0 := 0.24 + float(k) * 0.068
		var side := -1.0 if k % 2 == 0 else 1.0
		var length := 0.4 - float(k) * 0.03
		var a := deg_to_rad(32.0 + float(k) * 4.0)
		var end := Vector2(side * cos(a) * length, y0 + sin(a) * length)
		if k == 8:
			end = Vector2(0.0, y0 + length)
		parts.append(capsule(Vector2(0.0, y0), end, 0.024, 0.013))
		parts.append(ellipse(end, 0.075 - float(k) * 0.003, 0.05, 14, a * side * 0.5))
	return union(parts)


## Yurt: kerege duvarı, kubbe ve tünlük; taban y = 0, eni 1.
static func yurt() -> PackedVector2Array:
	var wall := PackedVector2Array([Vector2(-0.5, 0.0), Vector2(0.5, 0.0), Vector2(0.5, 0.42), Vector2(-0.5, 0.42)])
	var roof := dome(1.08, 0.32)
	for i in roof.size():
		roof[i] += Vector2(0.0, 0.4)
	var crown := PackedVector2Array([Vector2(-0.09, 0.68), Vector2(0.09, 0.68), Vector2(0.09, 0.76), Vector2(-0.09, 0.76)])
	return union([wall, roof, crown])


## Demir kazık: gökte dönmeyen nokta (beş köşeli yıldız) ve altında kısa kazık; yıldızın merkezi (0, 0).
static func stake(h: float) -> PackedVector2Array:
	return union([
		star(0.13, 0.055, 5),
		PackedVector2Array([Vector2(-0.016, -h), Vector2(0.016, -h), Vector2(0.016, -0.02), Vector2(-0.016, -0.02)]),
	])


## Alev: gözyaşı biçimli ana dil ve iki yan dil; taban y ≈ 0.
static func flame(seed_value: int) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var lean := (rng.randf() - 0.5) * 0.08
	return union([
		hull(ellipse(Vector2(0.0, 0.17), 0.17, 0.17, 20), [Vector2(0.02 + lean, 0.82)]),
		hull(ellipse(Vector2(-0.09, 0.15), 0.1, 0.1, 16), [Vector2(-0.17 + lean, 0.52)]),
		hull(ellipse(Vector2(0.1, 0.14), 0.09, 0.09, 16), [Vector2(0.18 + lean, 0.46)]),
	])


## Yüzü olmayan karanlık biçim (Erlik'in inişi, Al Karısı'nın gölgesi): başlık ve yırtık etekli pelerin; taban y ≈ 0.
static func shadow() -> PackedVector2Array:
	return union([
		ellipse(Vector2(0.0, 0.86), 0.13, 0.15, 22),
		PackedVector2Array([Vector2(-0.3, 0.0), Vector2(-0.16, -0.02), Vector2(-0.04, 0.04), Vector2(0.08, -0.03),
			Vector2(0.18, 0.04), Vector2(0.3, 0.0), Vector2(0.13, 0.82), Vector2(-0.13, 0.82)]),
	])


## Umay'ın payı: sarılmış küçük bohça ve düğümü.
static func bundle() -> PackedVector2Array:
	return union([ellipse(Vector2.ZERO, 0.13, 0.09, 20), ellipse(Vector2(0.0, 0.09), 0.04, 0.035, 12)])


# --- Yardımcılar ------------------------------------------------------------------------------------

## Konik kapsül: a'da ra, b'de rb yarıçaplı iki dairenin dışbükey zarfı.
static func capsule(a: Vector2, b: Vector2, ra: float, rb: float, segments: int = 16) -> PackedVector2Array:
	var pts := ellipse(a, ra, ra, segments)
	pts.append_array(ellipse(b, rb, rb, segments))
	return _ccw(Geometry2D.convex_hull(_open(pts)))


## Dış hat ve ek noktaların dışbükey zarfı.
static func hull(points: PackedVector2Array, extra: Array) -> PackedVector2Array:
	var pts := points.duplicate()
	for p: Vector2 in extra:
		pts.append(p)
	return _ccw(Geometry2D.convex_hull(pts))


## Parçaların birleşimi: dış hattı en büyük alanlı parça (delikler doldurulur); ters yönlü (CCW) döner.
static func union(parts: Array) -> PackedVector2Array:
	var acc := PackedVector2Array()
	for part: PackedVector2Array in parts:
		if acc.is_empty():
			acc = _ccw(part)
			continue
		var merged := Geometry2D.merge_polygons(acc, _ccw(part))
		var best := PackedVector2Array()
		var best_area := 0.0
		for poly: PackedVector2Array in merged:
			var area := absf(signed_area(poly))
			if area > best_area:
				best_area = area
				best = poly
		if not best.is_empty():
			acc = _ccw(best)
	return _clean(acc)


## İşaretli alan (y yukarı; saat yönünün tersi > 0).
static func signed_area(poly: PackedVector2Array) -> float:
	var a := 0.0
	var n := poly.size()
	for i in n:
		var p := poly[i]
		var q := poly[(i + 1) % n]
		a += p.x * q.y - q.x * p.y
	return a * 0.5


## Dış hat kendini kesiyor mu (komşu olmayan iki kenar kesişir)? Sınama ve FeltPanel'in iç halkası için.
static func self_intersects(poly: PackedVector2Array) -> bool:
	var n := poly.size()
	if n < 4:
		return false
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		for j in range(i + 2, n):
			if i == 0 and j == n - 1:
				continue
			var c := poly[j]
			var d := poly[(j + 1) % n]
			if Geometry2D.segment_intersects_segment(a, b, c, d) != null:
				return true
	return false


static func _ccw(poly: PackedVector2Array) -> PackedVector2Array:
	var out := _open(poly)
	if signed_area(out) < 0.0:
		out.reverse()
	return out


## Kapanış noktası (ilkinin yinelenmesi) varsa atılır.
static func _open(poly: PackedVector2Array) -> PackedVector2Array:
	var out := poly.duplicate()
	while out.size() > 1 and out[0].distance_to(out[out.size() - 1]) < 1e-6:
		out.remove_at(out.size() - 1)
	return out


## Çok yakın ardışık noktalar (Clipper'ın tamsayı yuvarlamasından) birleştirilir.
static func _clean(poly: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in poly:
		if out.is_empty() or out[out.size() - 1].distance_to(p) > 1e-4:
			out.append(p)
	return _ccw(out)


static func _scaled(poly: PackedVector2Array, s: float) -> PackedVector2Array:
	var out := poly.duplicate()
	for i in out.size():
		out[i] *= s
	return out
