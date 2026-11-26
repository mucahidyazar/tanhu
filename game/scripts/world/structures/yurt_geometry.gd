class_name YurtGeometry
extends RefCounted
## Parametrik yurdun ağı (K51; structures.md §3.1–§3.6, §13.5; godot.md §6.7): bir millet (YurtStyle), bir boy (s, m, l) ve bir hazır
## ayar (hero, winter, closed, dome) için aşama kitinin tek ağı. Ağ Hane'nin ölçüsündedir (duvar yarıçapı 3,3 m); boy kök ölçektir
## (StagedYurt ve YurtField dönüşüme yazar), bu yüzden aynı millet ve boyun bütün yurtları ağı paylaşır: durumları (aşama, hasar, yanık,
## yırtık, kar) örnek tekdüzenidir. Ağ önbellekte tutulur (anahtar millet|boy|ayar); ilk kurulum dünyanın yükleyicisindedir.
##
## Aşamalar (act1.md §9.3) ve adımlar (structures.md §3.1): 0 kazık, ip ve ocak taşları; 1 bosağa; 2 kerege kanatları (Küçük 4, Hane 6,
## Otağ 8; kapıdan iki yana, en son arka: FAN) ve kerege bağı; 3 tündük (bakanlarla üç hamlede kalkar: HOIST; bakan aşama 4'te gizlenir);
## 4 uuk (kapı dilimlerinden başlayarak dikten iner: SWING); 5 çiy ve iç örtü; 6 tuurduk (dört panel üstten sarkar) ve üzük (dört panel
## saçaktan çekilir), süs kuşağı; 7 kolan (üç çember, radyal halatlar: STRIP), kapı keçesi ve basamaklar, şırdak (iç düzen ayrı ağdır).
## Kerege, uuk ve çiy tam yurtta (aşama 7) gizlenir (UV2.x 7): yırtıkta frame_on onları gösterir.
##
## Hazır ayarlar (structures.md §3.5; Godot ölçüsü): hero ana kampın camp3'ü (en sık ızgara, 48 uuk), winter Kışlak'ın yakın yurdu
## (24 uuk, 12 radyal; iç ≤12k ayrı), closed kapalı yurt (aşamasız, tek yüzey, ≈1,5k; YurtField'in orta kademesi), dome uzak kubbe
## (96 üçgen; 220 m ötesi).
##   var mesh := YurtGeometry.mesh(YurtStyle.find("yuezhi"), "m", "winter")
##   var d := YurtGeometry.dims(YurtStyle.find("hun"), "m")   # {radius, wall, crown, door: Vector2, pad} (kök ölçeğiyle, m)

const HERO := "hero"
const WINTER := "winter"
const CLOSED := "closed"
const DOME := "dome"
const PRESETS: Array[String] = [HERO, WINTER, CLOSED, DOME]
## Adımların aşama içindeki payı (structures.md §3.1 emekleri; boyda oran aynıdır): aşama 2 kerege 146 / bağ 48; 6 tuurduk 129 / üzük
## 146; 7 kolan 113, eşik 21, şırdak 81, ocak 20.
const BAG_FROM := 0.75
const UZUK_FROM := 0.47
const ESIK_FROM := 0.48
const SIRDAK_FROM := 0.57
const OCAK_FROM := 0.91

static var _cache: Dictionary = {}


static func forget() -> void:
	_cache.clear()


## Hazır ayarın ızgarası.
static func detail(preset: String) -> Dictionary:
	match preset:
		HERO:
			return {"segs": 72, "wall_rows": 6, "roof_rows": 8, "lattice": 0.36, "radial": 24, "hoop": 96, "liner": 64, "stakes": 8, "stones": 1}
		CLOSED:
			return {"segs": 28, "wall_rows": 2, "roof_rows": 3, "lattice": 0.0, "radial": 8, "hoop": 28, "liner": 0, "stakes": 0, "stones": 0}
		DOME:
			return {"segs": 12, "wall_rows": 0, "roof_rows": 4}
	return {"segs": 44, "wall_rows": 4, "roof_rows": 6, "lattice": 0.55, "radial": 12, "hoop": 48, "liner": 40, "stakes": 8, "stones": 0}


## Ölçüler (m; kök ölçeğiyle): radius duvar, wall duvarın boyu, crown tepenin yüksekliği, door kapının eni ve boyu, pad pedin yarıçapı,
## foot ayak izi (çarpışma ve navmesh dairesi), walk içinin yürünen yarıçapı. Kubbede wall 0'dır.
static func dims(style: YurtStyle, size: String) -> Dictionary:
	var sc := YurtStyle.size_scale(size)
	var r := style.radius() * sc.x
	var door := style.door_size()
	return {
		"radius": r, "wall": style.wall_height() * sc.y, "crown": style.crown_height() * sc.y,
		"door": Vector2(door.x * sc.x, door.y * sc.y), "pad": r * YurtStyle.body("pad_k", 1.21), "foot": r + 0.25,
		"walk": r - 0.32, "scale": sc, "crown_r": style.crown_radius() * sc.x,
	}


## Önbellekli ağ (anahtar millet|boy|ayar).
static func mesh(style: YurtStyle, size: String, preset: String) -> ArrayMesh:
	var key := "%s|%s|%s" % [style.id, size, preset]
	if _cache.has(key):
		return _cache[key]
	var m := YurtGeometry.build(style, size, preset)
	_cache[key] = m
	return m


## Ağı kurar (önbelleksiz).
static func build(style: YurtStyle, size: String, preset: String) -> ArrayMesh:
	var sm := StagedMesh.new()
	if preset == DOME:
		YurtGeometry._dome(sm, style)
		return sm.commit()
	var row := YurtStyle.size_row(size)
	var det := YurtGeometry.detail(preset)
	var kanat := int(row.get("kanat", 6))
	var uuk := int(row.get("uuk_winter", row.get("uuk", 48))) if preset == WINTER else int(row.get("uuk", 48))
	if preset == CLOSED:
		YurtGeometry._closed(sm, style, det)
	else:
		YurtGeometry._site(sm, style, det)
		YurtGeometry._door_frame(sm, style)
		YurtGeometry._lattice(sm, style, det, kanat)
		YurtGeometry._crown(sm, style, det, true)
		YurtGeometry._uuk(sm, style, uuk)
		YurtGeometry._liner(sm, style, det)
		YurtGeometry._felt(sm, style, det, true)
		YurtGeometry._ropes(sm, style, det, true)
		YurtGeometry._door_felt(sm, style)
	return sm.commit()


# --- Gövdenin biçimi ---------------------------------------------------------------------------------------------

## Kapının yarım açısı (radyan): kapı yeri duvarda açık kalır.
static func door_half(style: YurtStyle) -> float:
	return (style.door_size().x * 0.5 + 0.09) / style.radius()


## Duvarın yarıçapı yükseklikte (keregenin şişkinliği).
static func wall_r(style: YurtStyle, y: float) -> float:
	var h := maxf(style.wall_height(), 0.001)
	var t := clampf(y / h, 0.0, 1.0)
	return style.radius() * (0.985 + 0.03 * sin(PI * t * 0.9) - 0.01 * t)


## Çatı kesiti (saçaktan tepeye): Vector2(yarıçap, yükseklik). inset: içe pay (iç örtü).
static func roof_profile(style: YurtStyle, rows: int, inset: float = 0.0, lift: float = 0.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	var r0 := style.radius() + YurtStyle.body("eave", 0.12) - inset
	var y0 := style.wall_height() - 0.05 + lift
	var rc := style.crown_radius() + 0.06 - inset * 0.3
	var h := style.roof_height() - 0.02
	var convex := 0.08 + style.bulge
	if style.family == YurtStyle.FAMILY_DOME:
		r0 = style.radius() - inset
		y0 = lift
	for i in rows + 1:
		var t := float(i) / float(rows)
		var r := lerpf(r0, rc, t)
		var y := y0 + h * (t + convex * sin(PI * t))
		if style.family == YurtStyle.FAMILY_DOME:
			# Kubbe: yerden dikçe kalkan çeyrek elips; tepe düzleşir.
			var a := t * PI * 0.5
			r = lerpf(rc, r0, cos(a))
			y = y0 + h * pow(sin(a), 0.85)
		out.append(Vector2(r, y))
	return out


# --- Aşama 0: zemin ---------------------------------------------------------------------------------------------

static func _site(sm: StagedMesh, style: YurtStyle, det: Dictionary) -> void:
	var r := style.radius()
	var stakes := int(det.get("stakes", 8))
	var stake_col := Color("#6b4a2e")
	var pts := PackedVector3Array()
	for i in stakes:
		var a := TAU * float(i) / float(stakes) + 0.2
		var p := Vector3(sin(a), 0.0, cos(a)) * (r + 0.45)
		sm.part(0, float(i) / float(stakes) * 0.4, StagedMesh.MODE_POP, p, StagedMesh.CLS_WOOD, {"hide": 6.0})
		sm.beam(p + Vector3(0, -0.05, 0), p + Vector3(0, 0.5, 0), 0.05, 0.05, stake_col)
		pts.append(p + Vector3(0, 0.36, 0))
	if stakes > 0:
		pts.append(pts[0])
		var nrms := PackedVector3Array()
		for p in pts:
			nrms.append(Vector3(p.x, 0.0, p.z).normalized())
		sm.part(0, 0.3, StagedMesh.MODE_STRIP, Vector3.ZERO, StagedMesh.CLS_ROPE, {"hide": 6.0})
		sm.ribbon(pts, nrms, 0.022, Color("#c8b48a"), true)
	# Ocak taşları (ortada, biraz kapıya doğru).
	var center := Vector3(0.0, 0.0, 0.25)
	var stone_col := Color("#8a8276")
	for i in 6:
		var a := TAU * float(i) / 6.0
		var p := center + Vector3(sin(a), 0.0, cos(a)) * 0.38
		sm.part(0, 0.6 + 0.05 * float(i), StagedMesh.MODE_POP, p, StagedMesh.CLS_STONE)
		sm.blob(p, Vector3(0.13, 0.12, 0.11), 40 + i, stone_col.lightened(0.04 * float(i % 3)))


# --- Aşama 1: bosağa --------------------------------------------------------------------------------------------

static func _door_frame(sm: StagedMesh, style: YurtStyle) -> void:
	var door := style.door_size()
	var z := style.radius() + 0.02
	if style.family == YurtStyle.FAMILY_DOME:
		z = style.radius() - 0.15
	var half := door.x * 0.5
	var wood := style.trim
	if style.door_kind == "bosaga":
		for s: float in [-1.0, 1.0]:
			var base := Vector3(s * (half + 0.07), 0.0, z)
			sm.part(1, 0.15 + (0.0 if s < 0 else 0.08), StagedMesh.MODE_RISE, base, StagedMesh.CLS_WOOD)
			sm.box(Transform3D(Basis.IDENTITY, base + Vector3(0, (door.y + 0.12) * 0.5, 0)), Vector3(0.14, door.y + 0.12, 0.18), wood)
		sm.part(1, 0.55, StagedMesh.MODE_POP, Vector3(0, door.y + 0.1, z), StagedMesh.CLS_WOOD)
		sm.box(Transform3D(Basis.IDENTITY, Vector3(0, door.y + 0.12, z)), Vector3(door.x + 0.42, 0.16, 0.22), wood.darkened(0.1))
		# Lentonun süs üçgenleri ve tunç çiviler.
		for i in 3:
			var x := (float(i) - 1.0) * (door.x * 0.32)
			sm.part(1, 0.72 + 0.05 * float(i), StagedMesh.MODE_POP, Vector3(x, door.y + 0.12, z + 0.12), StagedMesh.CLS_WOOD)
			sm.box(Transform3D(Basis(Vector3.BACK, PI * 0.25), Vector3(x, door.y + 0.12, z + 0.115)), Vector3(0.07, 0.07, 0.02), style.accent)
		sm.part(1, 0.05, StagedMesh.MODE_POP, Vector3(0, 0, z), StagedMesh.CLS_WOOD)
		sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.035, z)), Vector3(door.x + 0.3, 0.07, 0.24), wood.darkened(0.2))
	else:
		# Keçe perde: iki ince dikme, üstte sırık.
		for s: float in [-1.0, 1.0]:
			var base := Vector3(s * (half + 0.05), 0.0, z)
			sm.part(1, 0.2, StagedMesh.MODE_RISE, base, StagedMesh.CLS_WOOD)
			sm.beam(base, base + Vector3(0, door.y + 0.08, 0), 0.07, 0.07, wood)
		sm.part(1, 0.6, StagedMesh.MODE_POP, Vector3(0, door.y + 0.06, z), StagedMesh.CLS_WOOD)
		sm.beam(Vector3(-half - 0.15, door.y + 0.06, z), Vector3(half + 0.15, door.y + 0.06, z), 0.06, 0.06, wood)


# --- Aşama 2: kerege ve bağı -----------------------------------------------------------------------------------

## Kanatlar kapıdan iki yana, en son arka açılır (k0, k(n-1), k1, k(n-2), …); her kanat FAN kipiyle kendi kapı tarafındaki kenarından.
static func _lattice(sm: StagedMesh, style: YurtStyle, det: Dictionary, kanat: int) -> void:
	var step := float(det.get("lattice", 0.5))
	if step <= 0.0 or style.family == YurtStyle.FAMILY_DOME:
		return
	var h := style.wall_height()
	var half := YurtGeometry.door_half(style)
	var a_from := half
	var a_to := TAU - half
	var span := (a_to - a_from) / float(kanat)
	var order := YurtGeometry.wing_order(kanat)
	var col := style.trim.lerp(Color("#a8542a"), 0.5)
	var r_lat := style.radius() - 0.07
	# Çıta: helis; yükselirken açı h / r kadar ilerler (45°). Çıta kapı aralığının dışında kırpılır.
	var turn := h / r_lat
	var n_slats := int(ceilf((a_to - a_from + turn) * r_lat / step))
	var segs := 4
	for dir: float in [1.0, -1.0]:
		for i in n_slats + 1:
			# a(t) = a_s + dir · turn · t; dir +1'de a_s a_from − turn'den, −1'de a_from'dan başlar.
			var a_s := a_from - turn + float(i) * step / r_lat if dir > 0.0 else a_from + float(i) * step / r_lat
			var t0 := 0.0
			var t1 := 1.0
			if dir > 0.0:
				t0 = maxf(0.0, (a_from - a_s) / turn)
				t1 = minf(1.0, (a_to - a_s) / turn)
			else:
				t0 = maxf(0.0, (a_s - a_to) / turn)
				t1 = minf(1.0, (a_s - a_from) / turn)
			if t1 - t0 < 0.02:
				continue
			var pts := PackedVector3Array()
			var nrms := PackedVector3Array()
			for k in segs + 1:
				var t := lerpf(t0, t1, float(k) / float(segs))
				var a := a_s + dir * turn * t
				var y := h * t * 0.985 + 0.04
				var rr := YurtGeometry.wall_r(style, y) - 0.07
				pts.append(Vector3(sin(a) * rr, y, cos(a) * rr))
				nrms.append(Vector3(sin(a), 0.0, cos(a)))
			var mid := pts[segs / 2]
			var am := fposmod(atan2(mid.x, mid.z) - a_from, TAU)
			var wing := clampi(int(am / span), 0, kanat - 1)
			var w_start := a_from + float(wing) * span
			var w_end := w_start + span
			# Kanadın kapıya yakın kenarı pivottur: kapının bir yanındaki kanat başından, öbür yanındaki sonundan açılır.
			var pivot_a := w_start if absf(w_start - PI) > absf(w_end - PI) else w_end
			var pivot := Vector3(sin(pivot_a) * r_lat, 0.0, cos(pivot_a) * r_lat)
			var o := float(order.find(wing)) / float(kanat) * BAG_FROM
			sm.part(2, o, StagedMesh.MODE_FAN, pivot, StagedMesh.CLS_WOOD, {"hide": 7.0, "seed": float(wing) / float(kanat)})
			sm.ribbon(pts, nrms, 0.032, col.darkened(0.1 if dir > 0.0 else 0.0))
	# Kerege bağı: kapının iki yanından arkada birleşen kızıl kuşak (STRIP).
	for s: float in [1.0, -1.0]:
		var pts := PackedVector3Array()
		var nrms := PackedVector3Array()
		var n := 24
		for k in n + 1:
			var t := float(k) / float(n)
			var a := half + (PI - half) * t if s > 0.0 else TAU - half - (PI - half) * t
			var y := h - 0.1
			var rr := YurtGeometry.wall_r(style, y) - 0.05
			pts.append(Vector3(sin(a) * rr, y, cos(a) * rr))
			nrms.append(Vector3(sin(a), 0.0, cos(a)))
		sm.part(2, BAG_FROM + 0.02, StagedMesh.MODE_STRIP, Vector3.ZERO, StagedMesh.CLS_ROPE, {"hide": 7.0})
		sm.ribbon(pts, nrms, 0.13, style.band, true)


## Kanatların açılış sırası: kapıdan iki yana, en son arka (Hane 6: k0, k5, k1, k4, k2, k3).
static func wing_order(kanat: int) -> Array:
	var out: Array = []
	var lo := 0
	var hi := kanat - 1
	while lo <= hi:
		out.append(lo)
		if hi != lo:
			out.append(hi)
		lo += 1
		hi -= 1
	return out


# --- Aşama 3: tündük -------------------------------------------------------------------------------------------

static func _crown(sm: StagedMesh, style: YurtStyle, det: Dictionary, staged: bool) -> void:
	var rc := style.crown_radius()
	var y := style.crown_height() - 0.02
	var wood := style.trim.darkened(0.15)
	var drop := maxf(y - 1.3, 0.0)
	var stage := 3 if staged else 7
	var mode := StagedMesh.MODE_HOIST if staged else StagedMesh.MODE_STATIC
	sm.part(stage, 0.35, mode, Vector3(0, y, 0), StagedMesh.CLS_WOOD, {"sub": drop})
	var ring := PackedVector3Array()
	for k in 25:
		var a := TAU * float(k) / 24.0
		ring.append(Vector3(sin(a) * rc, y, cos(a) * rc))
	sm.tube(ring, 0.06, 6, wood)
	# Tündüğün kemerleri: iki çapraz yay.
	for i in 2:
		var a := PI * 0.5 * float(i) + PI * 0.25
		var pts := PackedVector3Array()
		for k in 7:
			var t := float(k) / 6.0
			var p := Vector3(sin(a), 0.0, cos(a)) * rc * (t * 2.0 - 1.0)
			p.y = y + 0.16 * sin(PI * t)
			pts.append(p)
		sm.tube(pts, 0.035, 5, wood.lightened(0.08))
	if not staged:
		return
	# Bakanlar: üç çatal sırık, tündüğü iter; aşama 4'te alınır.
	for i in 3:
		var a := TAU * float(i) / 3.0 + 0.4
		var foot := Vector3(sin(a), 0.0, cos(a)) * 1.25
		sm.part(3, 0.12 + 0.04 * float(i), StagedMesh.MODE_RISE, foot, StagedMesh.CLS_WOOD, {"hide": 4.0})
		sm.beam(foot, Vector3(sin(a), 0.0, cos(a)) * rc * 0.9 + Vector3(0, y - 0.05, 0), 0.06, 0.06, Color("#7a5a3a"))


# --- Aşama 4: uuk ----------------------------------------------------------------------------------------------

static func _uuk(sm: StagedMesh, style: YurtStyle, count: int) -> void:
	if style.family == YurtStyle.FAMILY_DOME:
		return
	var h := style.wall_height()
	var rc := style.crown_radius()
	var ycrown := style.crown_height() - 0.08
	var r0 := style.radius() - 0.06
	var col := Color("#b0562c").lerp(style.trim, 0.3)
	var idx: Array = []
	for i in count:
		idx.append(i)
	# Kapı dilimlerinden başlar: açının kapıya (0) uzaklığına göre sıra.
	idx.sort_custom(func(a: int, b: int) -> bool:
		return YurtGeometry._door_dist(TAU * (float(a) + 0.5) / float(count)) < YurtGeometry._door_dist(TAU * (float(b) + 0.5) / float(count)))
	var prof := YurtGeometry.roof_profile(style, 6, 0.1, -0.06)
	for rank in count:
		var i: int = idx[rank]
		var a := TAU * (float(i) + 0.5) / float(count)
		var dir := Vector3(sin(a), 0.0, cos(a))
		var top := dir * (rc * 0.95) + Vector3(0, ycrown, 0)
		sm.part(4, float(rank) / float(count) * 0.95, StagedMesh.MODE_SWING, top, StagedMesh.CLS_WOOD, {"hide": 7.0})
		var pts := PackedVector3Array()
		for p in prof:
			pts.append(dir * p.x + Vector3(0, p.y, 0))
		pts[0] = dir * r0 + Vector3(0, h - 0.02, 0)
		pts[pts.size() - 1] = top
		for k in pts.size() - 1:
			sm.beam(pts[k], pts[k + 1], 0.05, 0.04, col, dir.cross(Vector3.UP).cross(pts[k + 1] - pts[k]).normalized())


static func _door_dist(a: float) -> float:
	var d := fposmod(a, TAU)
	return minf(d, TAU - d)


# --- Aşama 5: çiy ve iç örtü -----------------------------------------------------------------------------------

static func _liner(sm: StagedMesh, style: YurtStyle, det: Dictionary) -> void:
	var segs := int(det.get("liner", 40))
	if segs <= 0:
		return
	var half := YurtGeometry.door_half(style)
	var h := style.wall_height()
	if style.family != YurtStyle.FAMILY_DOME:
		# Çiy: keregenin dışında kamış hasır, dört dilimde yükselir (kapı dışı).
		for q in 4:
			var a0 := lerpf(half, TAU - half, float(q) / 4.0)
			var a1 := lerpf(half, TAU - half, float(q + 1) / 4.0)
			var prof := PackedVector2Array([Vector2(YurtGeometry.wall_r(style, 0.04) - 0.035, 0.04), Vector2(YurtGeometry.wall_r(style, h * 0.5) - 0.035, h * 0.5), Vector2(YurtGeometry.wall_r(style, h - 0.2) - 0.035, h - 0.2)])
			sm.part(5, 0.04 + 0.12 * float(q), StagedMesh.MODE_RISE, Vector3(0, 0, 0), StagedMesh.CLS_REED, {"hide": 7.0, "pattern": 9})
			sm.lathe(prof, maxi(segs / 4, 3), a0, a1, Color("#b89a62"), StagedMesh.THIN, h * 0.9)
		# İç örtünün duvarı: boyalı kerege deseni (içe bakar).
		for q in 4:
			var a0 := lerpf(half, TAU - half, float(q) / 4.0)
			var a1 := lerpf(half, TAU - half, float(q + 1) / 4.0)
			var prof := PackedVector2Array([Vector2(YurtGeometry.wall_r(style, 0.0) - 0.13, 0.0), Vector2(YurtGeometry.wall_r(style, h * 0.5) - 0.13, h * 0.5), Vector2(YurtGeometry.wall_r(style, h) - 0.13, h - 0.03)])
			sm.part(5, 0.35 + 0.1 * float(q), StagedMesh.MODE_RISE, Vector3(0, 0, 0), StagedMesh.CLS_FELT, {"pattern": 7})
			sm.lathe(prof, maxi(segs / 4, 3), a0, a1, style.felt.darkened(0.2), StagedMesh.THIN, h, Callable(), false)
	# İç örtünün çatısı: uuk deseni ve tepeye doğru is.
	var roof := YurtGeometry.roof_profile(style, 4, 0.16, -0.1)
	sm.part(5, 0.78, StagedMesh.MODE_POP, Vector3(0, style.wall_height(), 0), StagedMesh.CLS_FELT, {"pattern": 8})
	var count := 24.0
	var ring := TAU * roof[0].x
	sm.lathe(roof, segs, 0.0, TAU, style.felt.darkened(0.22), StagedMesh.THIN, ring / count, Callable(), false)


# --- Aşama 6: keçe ---------------------------------------------------------------------------------------------

## Tuurduk (duvar keçesi, dört panel üstten sarkar) ve üzük (çatı keçesi, dört panel saçaktan çekilir); süs kuşağı panelle gelir.
## staged false (closed): aşama 7, kipsiz, tek yüzey.
static func _felt(sm: StagedMesh, style: YurtStyle, det: Dictionary, staged: bool) -> void:
	var segs := int(det.get("segs", 44))
	var wall_rows := int(det.get("wall_rows", 4))
	var roof_rows := int(det.get("roof_rows", 6))
	var half := YurtGeometry.door_half(style)
	var h := style.wall_height()
	var felt := style.felt
	var surf := StagedMesh.THIN if staged else StagedMesh.SOLID
	var stage := 6 if staged else 7
	var quarter_segs := maxi(segs / 4, 2)
	if style.family != YurtStyle.FAMILY_DOME and h > 0.0:
		for q in 4:
			var a0 := lerpf(half, TAU - half, float(q) / 4.0)
			var a1 := lerpf(half, TAU - half, float(q + 1) / 4.0)
			var prof := PackedVector2Array()
			for i in wall_rows + 1:
				var y := h * float(i) / float(wall_rows)
				prof.append(Vector2(YurtGeometry.wall_r(style, y), y - (0.12 if i == 0 else 0.0)))
			var am := (a0 + a1) * 0.5
			var pivot := Vector3(sin(am) * style.radius(), h, cos(am) * style.radius())
			var o := 0.03 + float(q) * 0.11
			sm.part(stage, o if staged else 0.0, StagedMesh.MODE_RISE if staged else StagedMesh.MODE_STATIC, pivot, StagedMesh.CLS_FELT, {"seed": float(q) * 0.25})
			sm.lathe(prof, quarter_segs, a0, a1, felt, surf)
			# Süs kuşağı: duvarın üst bandı, milletin deseniyle (UV.x bant yüksekliği birimiyle).
			if style.pattern > 0:
				var b0 := h * 0.72
				var b1 := h * 0.92
				var bprof := PackedVector2Array([Vector2(YurtGeometry.wall_r(style, b0) + 0.012, b0), Vector2(YurtGeometry.wall_r(style, b1) + 0.012, b1)])
				sm.part(stage, (o + 0.06) if staged else 0.0, StagedMesh.MODE_RISE if staged else StagedMesh.MODE_STATIC, pivot, StagedMesh.CLS_FELT, {"pattern": style.pattern, "seed": float(q) * 0.25})
				sm.lathe(bprof, quarter_segs, a0, a1, style.band, surf, b1 - b0)
	# Üzük: dört panel; tündük örtüsü en son.
	var roof := YurtGeometry.roof_profile(style, roof_rows)
	var rays := float(style.rays) if style.roof_pattern == 4 else 1.0
	for q in 4:
		var a0 := TAU * float(q) / 4.0 - PI * 0.25
		var a1 := a0 + TAU / 4.0
		var am := (a0 + a1) * 0.5
		var pivot := Vector3(sin(am) * roof[0].x, roof[0].y, cos(am) * roof[0].x)
		var o := UZUK_FROM + 0.04 + float(q) * 0.11
		var extra := {"seed": 0.5 + float(q) * 0.12}
		if style.roof_pattern > 0:
			extra["pattern"] = style.roof_pattern
		sm.part(stage, o if staged else 0.0, StagedMesh.MODE_RISE if staged else StagedMesh.MODE_STATIC, pivot, StagedMesh.CLS_FELT, extra)
		var ring_len := TAU * roof[0].x
		sm.lathe(roof, quarter_segs, a0, a1, felt.lightened(0.02), surf, ring_len / rays)
	# Tündük örtüsü (kapak): tepeyi yarı kapatan keçe.
	var top := roof[roof.size() - 1]
	var rc := style.crown_radius()
	sm.part(stage, 0.97 if staged else 0.0, StagedMesh.MODE_POP if staged else StagedMesh.MODE_STATIC, Vector3(0, top.y, 0), StagedMesh.CLS_FELT)
	var cover := PackedVector2Array([Vector2(rc + 0.12, top.y - 0.02), Vector2(rc * 0.5, top.y + 0.08), Vector2(0.02, top.y + 0.1)])
	sm.lathe(cover, 8 if staged else 6, PI * 0.2, PI * 1.25, felt.darkened(0.12), surf)


# --- Aşama 7: kolan, kapı keçesi --------------------------------------------------------------------------------

static func _ropes(sm: StagedMesh, style: YurtStyle, det: Dictionary, staged: bool) -> void:
	var hoop_segs := int(det.get("hoop", 48))
	var radial := int(det.get("radial", 12))
	var h := style.wall_height()
	var half := YurtGeometry.door_half(style)
	var rope := style.rope
	var stage := 7 if staged else 7
	var surf_mode := StagedMesh.MODE_STRIP if staged else StagedMesh.MODE_STATIC
	var hoops: Array = []
	if style.family != YurtStyle.FAMILY_DOME and h > 0.0:
		hoops = [h * 0.36, h * 0.66]
	var roof := YurtGeometry.roof_profile(style, 6, -0.015)
	for hi in hoops.size() + 1:
		var pts := PackedVector3Array()
		var nrms := PackedVector3Array()
		for k in hoop_segs + 1:
			var t := float(k) / float(hoop_segs)
			var a := lerpf(half, TAU - half, t)
			var p: Vector3
			if hi < hoops.size():
				var y: float = hoops[hi]
				p = Vector3(sin(a), 0.0, cos(a)) * (YurtGeometry.wall_r(style, y) + 0.022) + Vector3(0, y, 0)
			else:
				var rp := roof[1]
				p = Vector3(sin(a), 0.0, cos(a)) * rp.x + Vector3(0, rp.y + 0.01, 0)
			pts.append(p)
			nrms.append(Vector3(sin(a), 0.25 if hi == hoops.size() else 0.0, cos(a)).normalized())
		sm.part(stage, 0.04 + 0.1 * float(hi) if staged else 0.0, surf_mode, Vector3.ZERO, StagedMesh.CLS_ROPE)
		sm.ribbon(pts, nrms, 0.045, rope, staged)
	# Radyal halatlar: saçaktan tepeye, çatının üstünde.
	for i in radial:
		var a := TAU * (float(i) + 0.5) / float(radial)
		var dir := Vector3(sin(a), 0.0, cos(a))
		var pts := PackedVector3Array()
		var nrms := PackedVector3Array()
		for k in roof.size():
			var p := roof[k]
			pts.append(dir * (p.x + 0.015) + Vector3(0, p.y + 0.018, 0))
			var tng := (roof[mini(k + 1, roof.size() - 1)] - roof[maxi(k - 1, 0)]).normalized()
			nrms.append((dir * tng.y - Vector3.UP * tng.x).normalized())
		sm.part(stage, 0.3 + 0.16 * float(i) / float(radial) if staged else 0.0, surf_mode, Vector3.ZERO, StagedMesh.CLS_ROPE)
		sm.ribbon(pts, nrms, 0.028, rope.lightened(0.05), staged)


static func _door_felt(sm: StagedMesh, style: YurtStyle) -> void:
	var door := style.door_size()
	var z := style.radius() + 0.11 if style.family != YurtStyle.FAMILY_DOME else style.radius() - 0.05
	var half := door.x * 0.5
	# Sarılı kapak: kapının üstünde rulo keçe, iki bağ (y_esik).
	sm.part(7, ESIK_FROM + 0.01, StagedMesh.MODE_POP, Vector3(0, door.y - 0.1, z), StagedMesh.CLS_FELT)
	sm.log_between(Vector3(-half - 0.08, door.y - 0.12, z), Vector3(half + 0.08, door.y - 0.12, z), 0.11, 10, style.felt.darkened(0.08))
	for s: float in [-1.0, 1.0]:
		var x := s * half * 0.6
		sm.part(7, ESIK_FROM + 0.04, StagedMesh.MODE_POP, Vector3(x, door.y, z), StagedMesh.CLS_ROPE)
		sm.beam(Vector3(x, door.y + 0.06, z - 0.02), Vector3(x, door.y - 0.28, z + 0.06), 0.03, 0.02, style.band)
	# İki basamak (taş ya da tahta).
	for i in 2:
		var p := Vector3(0.0, 0.0, z + 0.25 + 0.34 * float(i))
		sm.part(7, ESIK_FROM + 0.06 + 0.02 * float(i), StagedMesh.MODE_RISE, p, StagedMesh.CLS_STONE)
		sm.box(Transform3D(Basis(Vector3.UP, 0.06 * (float(i) * 2.0 - 1.0)), p + Vector3(0, 0.09 - 0.03 * float(i), 0)),
			Vector3(door.x + 0.1 - 0.12 * float(i), 0.18 - 0.06 * float(i), 0.32), Color("#9a9080").darkened(0.05 * float(i)))


# --- Kapalı yurt ve uzak kubbe ------------------------------------------------------------------------------------

## Kapalı yurt (aşamasız, tek yüzey): keçe, süs kuşağı, tündük ve örtü, kapalı keçe kapı, kapı aralığında ocağın sızan ışığı (glow),
## iki çember ve radyal halatlar.
static func _closed(sm: StagedMesh, style: YurtStyle, det: Dictionary) -> void:
	YurtGeometry._felt(sm, style, det, false)
	YurtGeometry._crown(sm, style, det, false)
	YurtGeometry._ropes(sm, style, det, false)
	var door := style.door_size()
	var z := style.radius()
	var half := YurtGeometry.door_half(style) * style.radius()
	sm.part(7, 0.0, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_WOOD)
	if style.door_kind == "bosaga" and style.family != YurtStyle.FAMILY_DOME:
		sm.box(Transform3D(Basis.IDENTITY, Vector3(0, door.y + 0.1, z + 0.02)), Vector3(door.x + 0.4, 0.15, 0.2), style.trim.darkened(0.1))
		for s: float in [-1.0, 1.0]:
			sm.box(Transform3D(Basis.IDENTITY, Vector3(s * (door.x * 0.5 + 0.07), (door.y + 0.1) * 0.5, z + 0.02)), Vector3(0.13, door.y + 0.1, 0.16), style.trim)
	# Kapalı kapı keçesi ve ocağın sızan ışığı (kenar aralığı).
	sm.part(7, 0.0, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_FELT)
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, door.y * 0.5, z - 0.01)), Vector3(half * 2.0 - 0.02, door.y, 0.04), style.felt.darkened(0.25))
	sm.part(7, 0.0, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_GLOW)
	sm.box(Transform3D(Basis.IDENTITY, Vector3(door.x * 0.36, door.y * 0.45, z + 0.012)), Vector3(0.05, door.y * 0.85, 0.02), Color("#ff9a4a"))
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.03, z + 0.012)), Vector3(door.x * 0.8, 0.05, 0.02), Color("#ff8a3a"))


## Uzak kubbe: 12 dilim × 4 sıra = 96 üçgen, keçe rengi.
static func _dome(sm: StagedMesh, style: YurtStyle) -> void:
	sm.part(7, 0.0, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_FELT)
	var h := style.wall_height()
	var top := style.crown_height()
	var r := style.radius()
	var prof := PackedVector2Array([Vector2(r, -0.1), Vector2(r, maxf(h, 0.2)), Vector2(r * 0.55, h + (top - h) * 0.6), Vector2(style.crown_radius(), top)])
	if style.family == YurtStyle.FAMILY_DOME:
		prof = PackedVector2Array([Vector2(r, -0.1), Vector2(r * 0.92, top * 0.5), Vector2(r * 0.55, top * 0.88), Vector2(style.crown_radius(), top)])
	# Tepe kapalıdır (dördüncü sıra; 2 cm'lik aralık uzaktan görünmez): açık taç uzaktan yurdun içine, yere bakan bir delikti.
	prof.append(Vector2(0.02, top + 0.06))
	sm.lathe(prof, 12, 0.0, TAU, style.felt, StagedMesh.SOLID)
