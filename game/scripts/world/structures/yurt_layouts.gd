class_name YurtLayouts
extends RefCounted
## Yurdun iç düzenleri (K51 «Düzen»; structures.md §3.6, §13.5): data/structures/yurt_layouts.json'un eşyalarını tek ağa kurar (aşama
## kitinin biçimi: StagedMesh; eşya aşama 7'de, y_sirdak'ın sırasında belirir: önce taban keçeleri, sonra eşya). İç düzen yurdun ters
## ölçekli çocuğudur: eşya ×1 kalır, konum boyun yatay ölçeğiyle çarpılır. Hazır ayar: hero bütün eşya; winter yalnız ocak, halılar ve
## «big» eşyalar (≤12k üçgen; structures.md §13.5); Küçük Yurt'ta yalnız «small» eşyalar (ev ≤6k). Ağ önbelleklidir (düzen|boy|ayar).
## Eşyanın engel kutusu (yerel, boyla) boxes()'tadır: odaya girilen yurtta oyuncu eşyanın içinden geçmez.
##   var mesh := YurtLayouts.mesh("otaci", "m", "hero")
##   YurtLayouts.boxes("otaci", "m", "hero")    # [[merkez Vector2, yarı Vector2, açı], ...] (yerel, iç düzenin uzayında)

const PATH := "res://data/structures/yurt_layouts.json"
## Eşyanın aşama 7 içindeki sırası (y_sirdak: 0,57–0,91; taban keçesi önce).
const RUG_ORDER := 0.6
const ITEM_ORDER := 0.68
const WINTER_TRIS := 12000
const SMALL_TRIS := 6000

static var _data: Dictionary = {}
static var _cache: Dictionary = {}
static var _boxes: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty() and FileAccess.file_exists(PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data = parsed if parsed is Dictionary else {}
	return _data


static func forget() -> void:
	_data = {}
	_cache.clear()
	_boxes.clear()


## Anahtar (takma adlar: feast → han, council → otag; eski design alanı da aynı anahtarı taşır). Bilinmeyen ev.
static func resolve(key: String) -> String:
	var aliases: Dictionary = data().get("aliases", {})
	var k := str(aliases.get(key, key))
	return k if (data().get("layouts", {}) as Dictionary).has(k) else "ev"


static func keys() -> PackedStringArray:
	return PackedStringArray((data().get("layouts", {}) as Dictionary).keys())


static func items(key: String) -> Array:
	return ((data().get("layouts", {}) as Dictionary).get(YurtLayouts.resolve(key), {}) as Dictionary).get("items", [])


## Önbellekli ağ.
static func mesh(key: String, size: String, preset: String) -> ArrayMesh:
	var k := "%s|%s|%s" % [YurtLayouts.resolve(key), size, preset]
	if _cache.has(k):
		return _cache[k]
	var boxes: Array = []
	var m := YurtLayouts.build(key, size, preset, boxes)
	_cache[k] = m
	_boxes[k] = boxes
	return m


static func boxes(key: String, size: String, preset: String) -> Array:
	var k := "%s|%s|%s" % [YurtLayouts.resolve(key), size, preset]
	if not _boxes.has(k):
		YurtLayouts.mesh(key, size, preset)
	return _boxes.get(k, [])


## Ağı kurar. boxes_out'a eşyanın engel kutusu eklenir.
static func build(key: String, size: String, preset: String, boxes_out: Array = []) -> ArrayMesh:
	var sm := StagedMesh.new()
	var scale := YurtStyle.size_scale(size).x
	var list := YurtLayouts.items(key)
	var budget := SMALL_TRIS if size == "s" else (WINTER_TRIS if preset != "hero" else 60000)
	var i := 0
	for it: Variant in list:
		if not it is Dictionary:
			continue
		var row: Dictionary = it
		if size == "s" and not bool(row.get("small", false)):
			continue
		if preset != "hero" and size != "s" and not bool(row.get("big", false)):
			continue
		var before := sm.tri_count()
		YurtLayouts._place(sm, row, scale, i, boxes_out)
		if sm.tri_count() > budget:
			# Bütçe: eşyayı geri alamayız (diziler eklendi); son eşya bütçeyi aşarsa uyarı (veri düzeltilir).
			push_warning("[yurt_layouts] %s/%s/%s iç düzeni bütçeyi aştı: %d > %d" % [key, size, preset, sm.tri_count(), budget])
			break
		if sm.tri_count() == before:
			pass
		i += 1
	return sm.commit()


static func _col(v: Variant, fallback: String) -> Color:
	var s := str(v) if v != null else fallback
	return Color.html(s) if Color.html_is_valid(s) else Color.html(fallback)


## Eşyanın yeri ve yönü (yerel; Hane'nin ölçüsü × boyun yatay ölçeği).
static func _frame(row: Dictionary, scale: float) -> Transform3D:
	var p := Vector3.ZERO
	if row.has("at"):
		var at: Array = row["at"]
		p = Vector3(sin(float(at[0])), 0.0, cos(float(at[0]))) * float(at[1])
	elif row.has("xz"):
		var xz: Array = row["xz"]
		p = Vector3(float(xz[0]), 0.0, float(xz[1]))
	p *= Vector3(scale, 1.0, scale)
	var yaw := 0.0
	var face: Variant = row.get("face")
	if face is String and str(face) == "center":
		# Önü (+Z) merkeze döner.
		yaw = atan2(-p.x, -p.z) if Vector2(p.x, p.z).length() > 0.01 else 0.0
	elif face is String and str(face) == "wall":
		yaw = atan2(p.x, p.z)
	elif face is float or face is int:
		yaw = deg_to_rad(float(face))
	return Transform3D(Basis(Vector3.UP, yaw), p)


static func _place(sm: StagedMesh, row: Dictionary, scale: float, i: int, boxes_out: Array) -> void:
	var item := str(row.get("item", ""))
	var args: Dictionary = row.get("args", {})
	var xf := YurtLayouts._frame(row, scale)
	var order := RUG_ORDER if item == "rug" else clampf(ITEM_ORDER + 0.012 * float(i), ITEM_ORDER, 0.9)
	var mode := StagedMesh.MODE_RISE if item == "rug" or item == "screen_line" else StagedMesh.MODE_RISE
	sm.xform = xf
	sm.part(7, order, mode, Vector3.ZERO, StagedMesh.CLS_PLAIN, {"seed": fposmod(float(i) * 0.137, 1.0)})
	var foot := Vector2.ZERO
	match item:
		"hearth":
			YurtLayouts._hearth(sm, args)
		"rug":
			YurtLayouts._rug(sm, float(args.get("w", 2.0)), float(args.get("d", 1.4)), YurtLayouts._col(args.get("field"), "#7a2822"), YurtLayouts._col(args.get("border"), "#2f2238"))
		"chest":
			foot = YurtLayouts._chest(sm, float(args.get("w", 1.1)), float(args.get("h", 0.6)), float(args.get("d", 0.6)), YurtLayouts._col(args.get("color"), "#7a2f20"))
		"bedding":
			foot = YurtLayouts._bedding(sm, float(args.get("w", 1.1)), i)
		"shrine":
			foot = YurtLayouts._shrine(sm)
		"saddle_stand":
			foot = YurtLayouts._saddle_stand(sm)
		"bow_wall":
			YurtLayouts._bow_wall(sm, float(args.get("y", 1.45)))
		"mattress", "pallet":
			foot = YurtLayouts._mattress(sm, YurtLayouts._col(args.get("color"), "#8a2f22"), item == "pallet")
		"screen":
			foot = YurtLayouts._screen(sm, float(args.get("w", 1.5)))
		"screen_line":
			var a: Array = args.get("from", [0.0, 0.0])
			var b: Array = args.get("to", [1.0, 0.0])
			sm.xform = Transform3D.IDENTITY
			sm.part(7, ITEM_ORDER, StagedMesh.MODE_RISE, Vector3.ZERO, StagedMesh.CLS_REED)
			YurtLayouts._screen_line(sm, Vector3(float(a[0]) * scale, 0.0, float(a[1]) * scale), Vector3(float(b[0]) * scale, 0.0, float(b[1]) * scale), boxes_out)
		"shelf":
			foot = YurtLayouts._shelf(sm, false)
		"jar_shelf":
			foot = YurtLayouts._shelf(sm, true)
		"skin_bag":
			YurtLayouts._skin_bag(sm)
		"sack":
			YurtLayouts._sack(sm, YurtLayouts._col(args.get("color"), "#b8a57c"), 30 + i)
			foot = Vector2(0.3, 0.3)
		"sack_pile":
			foot = YurtLayouts._sack_pile(sm, int(args.get("n", 5)), i)
		"bucket":
			YurtLayouts._bucket(sm)
		"log_pile":
			foot = YurtLayouts._log_pile(sm)
		"cushion":
			YurtLayouts._cushion(sm, YurtLayouts._col(args.get("color"), "#a53a2c"))
		"low_table":
			foot = YurtLayouts._low_table(sm)
		"long_table":
			foot = YurtLayouts._long_table(sm, float(args.get("len", 2.4)))
		"work_table":
			foot = YurtLayouts._work_table(sm)
		"crate":
			foot = YurtLayouts._crate(sm, float(args.get("w", 0.8)), float(args.get("h", 0.5)), float(args.get("d", 0.6)))
		"barrel", "kumis_barrel", "arrow_barrel":
			foot = YurtLayouts._barrel(sm, float(args.get("r", 0.3)), float(args.get("h", 0.7)), item)
		"hide_stack":
			foot = YurtLayouts._hide_stack(sm)
		"dais":
			YurtLayouts._dais(sm, float(args.get("w", 2.6)), float(args.get("d", 1.2)))
		"seat":
			foot = YurtLayouts._seat(sm)
		"tug":
			YurtLayouts._tug(sm)
			foot = Vector2(0.15, 0.15)
		"shield_wall":
			YurtLayouts._shield_wall(sm, float(args.get("y", 1.6)), YurtLayouts._col(args.get("color"), "#7a2620"))
		"horns":
			YurtLayouts._horns(sm, float(args.get("y", 2.0)))
		"lamp":
			YurtLayouts._lamp(sm)
		"weapon_rack":
			foot = YurtLayouts._weapon_rack(sm)
		"armor_stand":
			foot = YurtLayouts._armor_stand(sm)
		"target":
			foot = YurtLayouts._target(sm)
		"drying_rack":
			foot = YurtLayouts._drying_rack(sm)
		"drum":
			foot = YurtLayouts._drum(sm)
		"fur":
			YurtLayouts._fur(sm, YurtLayouts._col(args.get("color"), "#8a7a60"))
		"hanging":
			YurtLayouts._hanging(sm, float(args.get("y", 1.2)), YurtLayouts._col(args.get("color"), "#a53a2c"))
		"kopuz_stand":
			foot = YurtLayouts._kopuz_stand(sm)
		_:
			push_warning("[yurt_layouts] bilinmeyen eşya: %s" % item)
	sm.xform = Transform3D.IDENTITY
	if foot != Vector2.ZERO:
		var yaw := xf.basis.get_euler().y
		boxes_out.append([Vector2(xf.origin.x, xf.origin.z), foot, yaw])


# --- Eşya kiti (yerel: önü +Z, taban y 0) ----------------------------------------------------------------

static func _hearth(sm: StagedMesh, args: Dictionary) -> void:
	var r := float(args.get("r", 0.42))
	var stone := Color("#8a8276")
	if bool(args.get("stones", false)):
		for k in 8:
			var a := TAU * float(k) / 8.0
			sm.blob(Vector3(sin(a) * r, 0.0, cos(a) * r), Vector3(0.12, 0.1, 0.1), 70 + k, stone.lightened(0.03 * float(k % 3)), 1)
	sm.part(7, 0.6, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_PLAIN)
	sm.disc(Vector3(0, 0.015, 0), r * 0.8, 10, Color("#2a1e18"))
	for k in 3:
		var a := TAU * float(k) / 3.0 + 0.3
		sm.log_between(Vector3(sin(a) * r * 0.7, 0.06, cos(a) * r * 0.7), Vector3(sin(a + PI) * r * 0.25, 0.1, cos(a + PI) * r * 0.25), 0.04, 6, Color("#5a3a24"))
	if bool(args.get("chalk", false)):
		sm.part(7, 0.6, StagedMesh.MODE_STATIC, Vector3.ZERO, StagedMesh.CLS_PLAIN)
		var pts := PackedVector3Array()
		var nrms := PackedVector3Array()
		for k in 25:
			var a := TAU * float(k) / 24.0
			pts.append(Vector3(sin(a), 0.012, cos(a)) * Vector3(r + 0.3, 1.0, r + 0.3))
			nrms.append(Vector3.UP)
		sm.ribbon(pts, nrms, 0.05, Color("#e8dcc0"))
	if bool(args.get("tripod", false)) or bool(args.get("cauldron", false)):
		var top := Vector3(0, 1.05, 0)
		for k in 3:
			var a := TAU * float(k) / 3.0
			sm.beam(Vector3(sin(a) * (r + 0.15), 0.0, cos(a) * (r + 0.15)), top, 0.035, 0.035, Color("#3e2a1c"))
		var prof := PackedVector2Array([Vector2(0.05, 0.3), Vector2(0.2, 0.36), Vector2(0.24, 0.48), Vector2(0.21, 0.6), Vector2(0.18, 0.63)])
		var old := sm.xform
		sm.xform = sm.xform * Transform3D(Basis.IDENTITY, Vector3(0, 0.05, 0))
		sm.lathe(prof, 12, 0.0, TAU, Color("#3a3634"), StagedMesh.SOLID)
		sm.xform = old
	if bool(args.get("spit", false)):
		for s: float in [-1.0, 1.0]:
			sm.beam(Vector3(s * (r + 0.2), 0.0, 0), Vector3(s * (r + 0.2), 0.7, 0), 0.04, 0.04, Color("#3e2a1c"))
		sm.log_between(Vector3(-r - 0.3, 0.68, 0), Vector3(r + 0.3, 0.68, 0), 0.02, 5, Color("#3e2a1c"))
		sm.blob(Vector3(0, 0.55, 0), Vector3(0.32, 0.18, 0.2), 9, Color("#7a3b26"), 1)


static func _rug(sm: StagedMesh, w: float, d: float, field: Color, border: Color) -> void:
	var old := sm.xform
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.012, 0)), Vector3(w, 0.02, d), border)
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.024, 0)), Vector3(w - 0.24, 0.02, d - 0.24), field)
	sm.box(Transform3D(Basis(Vector3.UP, PI * 0.25), Vector3(0, 0.034, 0)), Vector3(minf(w, d) * 0.32, 0.01, minf(w, d) * 0.32), border.lightened(0.35))
	sm.xform = old


static func _chest(sm: StagedMesh, w: float, h: float, d: float, col: Color) -> Vector2:
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, h * 0.36, 0)), Vector3(w, h * 0.72, d), col)
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, h * 0.86, 0)), Vector3(w + 0.03, h * 0.28, d + 0.03), col.lightened(0.08))
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, h * 0.4, d * 0.5 + 0.006)), Vector3(w * 0.44, h * 0.42, 0.012), col.lerp(Color("#e0c98f"), 0.6))
	for k: float in [-0.38, 0.38]:
		sm.box(Transform3D(Basis.IDENTITY, Vector3(k * w, h * 0.5, 0)), Vector3(0.06, h + 0.02, d + 0.05), Color("#b08b4e"))
	return Vector2(w * 0.5 + 0.05, d * 0.5 + 0.05)


static func _bedding(sm: StagedMesh, w: float, seed_value: int) -> Vector2:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 13
	YurtLayouts._chest(sm, w, 0.5, 0.62, Color("#5e2a1c"))
	var colors := ["#8a2f22", "#d8c58f", "#2f4860", "#b9653a", "#e8dcc0", "#6a2c4a"]
	var y := 0.5
	for k in 6:
		var hh := rng.randf_range(0.11, 0.16)
		sm.box(Transform3D(Basis(Vector3.UP, rng.randf_range(-0.03, 0.03)), Vector3(rng.randf_range(-0.03, 0.03), y + hh * 0.5, 0)),
			Vector3(w - 0.12, hh, 0.54), Color.html(colors[k % colors.size()]))
		y += hh - 0.004
	return Vector2(w * 0.5 + 0.05, 0.36)


static func _shrine(sm: StagedMesh) -> Vector2:
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.35, 0)), Vector3(0.7, 0.7, 0.36), Color("#4a3322"))
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.72, 0)), Vector3(0.78, 0.04, 0.4), Color("#6a4a30"))
	for k in 3:
		var x := (float(k) - 1.0) * 0.2
		sm.cylinder(Vector3(x, 0.74, 0.02), 0.06, 0.04, 0.22 + 0.04 * float(k % 2), 6, Color("#d8c8a0").darkened(0.08 * float(k)))
		sm.blob(Vector3(x, 0.96 + 0.04 * float(k % 2), 0.02), Vector3(0.05, 0.05, 0.05), 90 + k, Color("#c9a24f"))
	return Vector2(0.42, 0.24)


static func _saddle_stand(sm: StagedMesh) -> Vector2:
	for s: float in [-0.35, 0.35]:
		sm.beam(Vector3(s, 0.0, -0.2), Vector3(s, 0.62, 0.0), 0.05, 0.05, Color("#4d3520"))
		sm.beam(Vector3(s, 0.0, 0.2), Vector3(s, 0.62, 0.0), 0.05, 0.05, Color("#4d3520"))
	sm.beam(Vector3(-0.4, 0.64, 0), Vector3(0.4, 0.64, 0), 0.06, 0.05, Color("#4d3520"))
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.78, 0)), Vector3(0.62, 0.16, 0.42), Color("#6a3a22"))
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.86, -0.16)), Vector3(0.5, 0.16, 0.12), Color("#7a4a2a"))
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.86, 0.16)), Vector3(0.5, 0.2, 0.12), Color("#7a4a2a"))
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.62, 0)), Vector3(0.72, 0.06, 0.6), Color("#a53a2c"))
	return Vector2(0.42, 0.32)


static func _bow_wall(sm: StagedMesh, y: float) -> void:
	var pts := PackedVector3Array()
	for k in 9:
		var t := float(k) / 8.0
		pts.append(Vector3((t - 0.5) * 1.1, y + 0.18 * sin(PI * t) - 0.05, 0.02 + 0.04 * sin(PI * t)))
	sm.tube(pts, 0.018, 5, Color("#6a4a2a"))
	sm.box(Transform3D(Basis(Vector3.BACK, 0.4), Vector3(0.25, y - 0.25, 0.05)), Vector3(0.16, 0.6, 0.1), Color("#5a3a24"))


static func _mattress(sm: StagedMesh, col: Color, pallet: bool) -> Vector2:
	var w := 0.8
	var d := 1.8 if not pallet else 1.7
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.07, 0)), Vector3(w, 0.14, d), Color("#d8c8a8"))
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.15, 0.1)), Vector3(w - 0.06, 0.03, d - 0.4), col)
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.19, -d * 0.5 + 0.18)), Vector3(0.5, 0.1, 0.26), Color("#e8dcc0"))
	return Vector2(w * 0.5, d * 0.5)


static func _screen(sm: StagedMesh, w: float) -> Vector2:
	var old_cls := StagedMesh.CLS_REED
	sm.part(7, ITEM_ORDER, StagedMesh.MODE_RISE, Vector3.ZERO, old_cls, {"pattern": 9})
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.8, 0)), Vector3(w, 1.6, 0.04), Color("#b89a62"))
	for s: float in [-0.5, 0.5]:
		sm.beam(Vector3(s * w, 0.0, 0), Vector3(s * w, 1.7, 0), 0.05, 0.05, Color("#4d3520"))
	return Vector2(w * 0.5, 0.08)


static func _screen_line(sm: StagedMesh, a: Vector3, b: Vector3, boxes_out: Array) -> void:
	var d := b - a
	var len := d.length()
	if len < 0.05:
		return
	var yaw := atan2(d.x, d.z)
	var mid := (a + b) * 0.5
	sm.set_pattern(9)
	sm.box(Transform3D(Basis(Vector3.UP, yaw), mid + Vector3(0, 0.85, 0)), Vector3(0.05, 1.7, len), Color("#b89a62"))
	sm.set_pattern(0)
	var n := int(ceilf(len / 1.2))
	for k in n + 1:
		var p := a.lerp(b, float(k) / float(n))
		sm.beam(p, p + Vector3(0, 1.8, 0), 0.05, 0.05, Color("#4d3520"))
	boxes_out.append([Vector2(mid.x, mid.z), Vector2(0.06, len * 0.5), yaw])


static func _shelf(sm: StagedMesh, jars: bool) -> Vector2:
	var w := 1.2
	for x: float in [-w * 0.5, w * 0.5]:
		sm.beam(Vector3(x, 0, 0), Vector3(x, 1.5, 0), 0.04, 0.04, Color("#4d3520"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7 if jars else 3
	var palette := ["#8a5a3a", "#6a7a5a", "#b9653a", "#c9b48b", "#3a4a58", "#7c2a22"]
	for y: float in [0.45, 0.95, 1.42]:
		sm.box(Transform3D(Basis.IDENTITY, Vector3(0, y, 0)), Vector3(w + 0.08, 0.04, 0.34), Color("#6a4a30"))
		for k in 4:
			var x := (float(k) + 0.5) / 4.0 * (w - 0.1) - (w - 0.1) * 0.5
			var c := Color.html(palette[rng.randi() % palette.size()])
			if jars:
				sm.cylinder(Vector3(x, y + 0.02, 0), 0.07, 0.05, rng.randf_range(0.16, 0.26), 6, c)
			else:
				sm.cylinder(Vector3(x, y + 0.02, 0), 0.1, 0.12, 0.07, 8, c)
	return Vector2(w * 0.5 + 0.05, 0.2)


static func _skin_bag(sm: StagedMesh) -> void:
	sm.blob(Vector3(0, 0.0, 0), Vector3(0.22, 0.42, 0.18), 21, Color("#7a5a3a"), 1)
	sm.beam(Vector3(0, 0.8, 0), Vector3(0, 1.0, 0), 0.04, 0.04, Color("#4d3520"))


static func _sack(sm: StagedMesh, col: Color, seed_value: int) -> void:
	sm.blob(Vector3.ZERO, Vector3(0.24, 0.42, 0.22), seed_value, col, 1)
	sm.cylinder(Vector3(0, 0.56, 0), 0.07, 0.04, 0.1, 6, col.darkened(0.15))


static func _sack_pile(sm: StagedMesh, n: int, seed_value: int) -> Vector2:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 5
	for k in n:
		var a := TAU * float(k) / float(maxi(n, 1))
		var p := Vector3(sin(a) * 0.38, 0.0, cos(a) * 0.3) if k > 0 else Vector3.ZERO
		if k >= 5:
			p = Vector3(rng.randf_range(-0.2, 0.2), 0.36, rng.randf_range(-0.15, 0.15))
		var old := sm.xform
		sm.xform = sm.xform * Transform3D(Basis(Vector3.UP, rng.randf_range(0.0, TAU)), p)
		YurtLayouts._sack(sm, Color("#b8a57c").darkened(rng.randf_range(0.0, 0.2)), seed_value * 3 + k)
		sm.xform = old
	return Vector2(0.65, 0.55)


static func _bucket(sm: StagedMesh) -> void:
	sm.cylinder(Vector3.ZERO, 0.17, 0.2, 0.32, 10, Color("#6a4a2a"))
	sm.disc(Vector3(0, 0.27, 0), 0.18, 10, Color("#40606e"))


static func _log_pile(sm: StagedMesh) -> Vector2:
	for k in 7:
		var row := 0 if k < 4 else (1 if k < 6 else 2)
		var starts: Array[int] = [0, 4, 6]
		var mids: Array[float] = [1.5, 0.5, 0.0]
		var x := (float(k - starts[row]) - mids[row]) * 0.15
		var y := 0.07 + float(row) * 0.12
		sm.log_between(Vector3(x, y, -0.35), Vector3(x, y, 0.35), 0.065, 6, Color("#6a4a2e").darkened(0.05 * float(k % 3)))
	return Vector2(0.32, 0.38)


static func _cushion(sm: StagedMesh, col: Color) -> void:
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.06, 0)), Vector3(0.62, 0.12, 0.46), col)
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.125, 0)), Vector3(0.5, 0.01, 0.34), col.lightened(0.2))


static func _low_table(sm: StagedMesh) -> Vector2:
	sm.cylinder(Vector3(0, 0.0, 0), 0.4, 0.4, 0.04, 14, Color("#6e4a2c"), StagedMesh.SOLID, true)
	var old := sm.xform
	sm.xform = sm.xform * Transform3D(Basis.IDENTITY, Vector3(0, 0.24, 0))
	sm.cylinder(Vector3.ZERO, 0.46, 0.46, 0.05, 16, Color("#6e4a2c"))
	sm.xform = old
	for k in 3:
		sm.cylinder(Vector3(sin(float(k) * 2.1) * 0.22, 0.29, cos(float(k) * 2.1) * 0.22), 0.08, 0.1, 0.05, 8, Color("#c9a24f"))
	return Vector2(0.48, 0.48)


static func _long_table(sm: StagedMesh, length: float) -> Vector2:
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.32, 0)), Vector3(0.7, 0.06, length), Color("#6e4a2c"))
	for s: float in [-1.0, 1.0]:
		for z: float in [-0.42, 0.42]:
			sm.beam(Vector3(s * 0.26, 0, z * length), Vector3(s * 0.26, 0.3, z * length), 0.04, 0.04, Color("#4d3520"))
	var n := int(length / 0.45)
	for k in n:
		var z := ((float(k) + 0.5) / float(n) - 0.5) * (length - 0.2)
		sm.cylinder(Vector3(0.1 * (1.0 if k % 2 == 0 else -1.0), 0.35, z), 0.09, 0.11, 0.05, 8, Color("#c9a24f").darkened(0.1 * float(k % 3)))
	return Vector2(0.4, length * 0.5)


static func _work_table(sm: StagedMesh) -> Vector2:
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.74, 0)), Vector3(1.3, 0.06, 0.62), Color("#6e4a2c"))
	for sx: float in [-0.56, 0.56]:
		for sz: float in [-0.24, 0.24]:
			sm.beam(Vector3(sx, 0, sz), Vector3(sx, 0.72, sz), 0.05, 0.05, Color("#4d3520"))
	sm.cylinder(Vector3(-0.3, 0.77, 0), 0.1, 0.12, 0.12, 8, Color("#8a8276"))
	sm.cylinder(Vector3(0.3, 0.77, 0.05), 0.12, 0.14, 0.06, 8, Color("#b08b4e"))
	return Vector2(0.68, 0.34)


static func _crate(sm: StagedMesh, w: float, h: float, d: float) -> Vector2:
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, h * 0.5, 0)), Vector3(w, h, d), Color("#7a5a3a"))
	for s: float in [-1.0, 1.0]:
		sm.box(Transform3D(Basis.IDENTITY, Vector3(s * w * 0.4, h * 0.5, 0)), Vector3(0.05, h + 0.01, d + 0.01), Color("#5a3f28"))
	return Vector2(w * 0.5, d * 0.5)


static func _barrel(sm: StagedMesh, r: float, h: float, kind_id: String) -> Vector2:
	var col := Color("#6a4a2a") if kind_id != "kumis_barrel" else Color("#7a5a3a")
	if kind_id == "arrow_barrel":
		r = 0.2
		h = 0.5
	var prof := PackedVector2Array([Vector2(r * 0.86, 0.0), Vector2(r, h * 0.5), Vector2(r * 0.86, h)])
	var old := sm.xform
	sm.lathe(prof, 10, 0.0, TAU, col, StagedMesh.SOLID)
	sm.disc(Vector3(0, h, 0), r * 0.86, 10, col.lightened(0.1))
	for y: float in [0.18, 0.82]:
		var p2 := PackedVector2Array([Vector2(r * (0.9 + 0.1 * sin(PI * y)) + 0.005, h * y - 0.025), Vector2(r * (0.9 + 0.1 * sin(PI * y)) + 0.005, h * y + 0.025)])
		sm.lathe(p2, 10, 0.0, TAU, Color("#3a3634"), StagedMesh.SOLID)
	if kind_id == "arrow_barrel":
		for k in 6:
			var a := TAU * float(k) / 6.0
			sm.beam(Vector3(sin(a) * 0.08, h - 0.1, cos(a) * 0.08), Vector3(sin(a) * 0.1, h + 0.4, cos(a) * 0.1), 0.012, 0.012, Color("#a58a5f"))
	sm.xform = old
	return Vector2(r, r)


static func _hide_stack(sm: StagedMesh) -> Vector2:
	for k in 5:
		sm.box(Transform3D(Basis(Vector3.UP, 0.1 * float(k % 2) - 0.05), Vector3(0, 0.03 + 0.06 * float(k), 0)), Vector3(1.0, 0.05, 0.7), Color("#8a6a4a").darkened(0.06 * float(k % 3)))
	return Vector2(0.52, 0.38)


static func _dais(sm: StagedMesh, w: float, d: float) -> void:
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.05, 0)), Vector3(w, 0.1, d), Color("#3f2a1c"))
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.11, 0)), Vector3(w - 0.25, 0.02, d - 0.25), Color("#7a2620"))
	sm.box(Transform3D(Basis(Vector3.UP, PI * 0.25), Vector3(0, 0.125, 0)), Vector3(0.4, 0.01, 0.4), Color("#d9b26a"))


static func _seat(sm: StagedMesh) -> Vector2:
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.22, 0)), Vector3(1.0, 0.24, 0.7), Color("#4a3322"))
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.36, 0)), Vector3(0.96, 0.05, 0.66), Color("#efe3c6"))
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 0.38, 0.05)), Vector3(0.8, 0.03, 0.5), Color("#c9a24f"))
	return Vector2(0.52, 0.38)


static func _tug(sm: StagedMesh) -> void:
	sm.beam(Vector3.ZERO, Vector3(0, 2.5, 0), 0.05, 0.05, Color("#4d3520"))
	sm.cylinder(Vector3(0, 2.0, 0), 0.08, 0.2, 0.5, 8, Color("#2a2320"))
	sm.blob(Vector3(0, 2.5, 0), Vector3(0.06, 0.1, 0.06), 3, Color("#c9a24f"))


static func _shield_wall(sm: StagedMesh, y: float, col: Color) -> void:
	var old := sm.xform
	sm.xform = sm.xform * Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, y, 0.03))
	sm.cylinder(Vector3.ZERO, 0.32, 0.32, 0.04, 12, col)
	sm.cylinder(Vector3(0, 0.04, 0), 0.08, 0.05, 0.05, 8, Color("#b08b4e"))
	sm.xform = old


static func _horns(sm: StagedMesh, y: float) -> void:
	for s: float in [-1.0, 1.0]:
		var pts := PackedVector3Array()
		for k in 6:
			var t := float(k) / 5.0
			pts.append(Vector3(s * (0.08 + 0.35 * t), y + 0.25 * sin(PI * t * 0.8), 0.05 + 0.1 * t))
		sm.tube(pts, 0.035 * (1.0), 5, Color("#d8c8a0"))
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, y - 0.05, 0.02)), Vector3(0.2, 0.22, 0.08), Color("#efe3c6"))


static func _lamp(sm: StagedMesh) -> void:
	sm.beam(Vector3.ZERO, Vector3(0, 1.1, 0), 0.04, 0.04, Color("#3a3634"))
	sm.cylinder(Vector3(0, 1.1, 0), 0.1, 0.12, 0.06, 8, Color("#b08b4e"))
	sm.part(7, ITEM_ORDER, StagedMesh.MODE_RISE, Vector3.ZERO, StagedMesh.CLS_GLOW)
	sm.blob(Vector3(0, 1.16, 0), Vector3(0.035, 0.07, 0.035), 5, Color("#ffb060"))


static func _weapon_rack(sm: StagedMesh) -> Vector2:
	for s: float in [-0.55, 0.55]:
		sm.beam(Vector3(s, 0, 0), Vector3(s, 1.6, 0), 0.05, 0.05, Color("#4d3520"))
	for y: float in [0.5, 1.2]:
		sm.beam(Vector3(-0.6, y, 0), Vector3(0.6, y, 0), 0.05, 0.05, Color("#4d3520"))
	for k in 4:
		var x := (float(k) - 1.5) * 0.28
		sm.beam(Vector3(x, 0.05, 0.08), Vector3(x + 0.05, 1.9, 0.04), 0.025, 0.025, Color("#6a4a2a"))
		sm.box(Transform3D(Basis.IDENTITY, Vector3(x + 0.05, 1.95, 0.04)), Vector3(0.05, 0.14, 0.02), Color("#9a9a9a"))
	return Vector2(0.62, 0.15)


static func _armor_stand(sm: StagedMesh) -> Vector2:
	sm.beam(Vector3.ZERO, Vector3(0, 1.55, 0), 0.05, 0.05, Color("#4d3520"))
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, 1.15, 0)), Vector3(0.5, 0.6, 0.26), Color("#5a4a3a"))
	sm.blob(Vector3(0, 1.48, 0), Vector3(0.13, 0.14, 0.13), 17, Color("#6a6a6a"))
	return Vector2(0.3, 0.2)


static func _target(sm: StagedMesh) -> Vector2:
	sm.beam(Vector3(-0.3, 0, -0.1), Vector3(0, 1.1, 0), 0.04, 0.04, Color("#4d3520"))
	sm.beam(Vector3(0.3, 0, -0.1), Vector3(0, 1.1, 0), 0.04, 0.04, Color("#4d3520"))
	var old := sm.xform
	sm.xform = sm.xform * Transform3D(Basis(Vector3.RIGHT, PI * 0.5 - 0.15), Vector3(0, 0.8, 0.05))
	sm.cylinder(Vector3.ZERO, 0.38, 0.38, 0.12, 12, Color("#c9b48b"))
	sm.cylinder(Vector3(0, 0.12, 0), 0.18, 0.18, 0.01, 10, Color("#8a2f22"))
	sm.xform = old
	return Vector2(0.4, 0.2)


static func _drying_rack(sm: StagedMesh) -> Vector2:
	for s: float in [-0.6, 0.6]:
		sm.beam(Vector3(s, 0, 0), Vector3(s, 1.5, 0), 0.04, 0.04, Color("#4d3520"))
	sm.beam(Vector3(-0.65, 1.45, 0), Vector3(0.65, 1.45, 0), 0.03, 0.03, Color("#6a4a30"))
	for k in 6:
		var x := (float(k) - 2.5) * 0.2
		sm.beam(Vector3(x, 1.44, 0), Vector3(x, 1.12, 0.02), 0.06, 0.04, Color("#7c9a3a").darkened(0.08 * float(k % 3)))
	return Vector2(0.65, 0.1)


static func _drum(sm: StagedMesh) -> Vector2:
	var old := sm.xform
	sm.xform = sm.xform * Transform3D(Basis(Vector3.RIGHT, 0.3), Vector3(0, 0.6, 0))
	sm.cylinder(Vector3(0, -0.06, 0), 0.32, 0.32, 0.1, 14, Color("#8a6a4a"))
	sm.disc(Vector3(0, 0.045, 0), 0.31, 14, Color("#e0cfa8"))
	sm.xform = old
	sm.beam(Vector3(0, 0, -0.1), Vector3(0, 0.5, -0.02), 0.04, 0.04, Color("#4d3520"))
	return Vector2(0.34, 0.2)


static func _fur(sm: StagedMesh, col: Color) -> void:
	sm.box(Transform3D(Basis(Vector3.UP, 0.4), Vector3(0, 0.015, 0)), Vector3(0.9, 0.025, 0.65), col)
	sm.box(Transform3D(Basis(Vector3.UP, 0.4), Vector3(0, 0.022, 0.36)), Vector3(0.3, 0.02, 0.2), col.darkened(0.1))


static func _hanging(sm: StagedMesh, y: float, col: Color) -> void:
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, y, 0.03)), Vector3(1.0, 1.0, 0.02), col)
	sm.box(Transform3D(Basis.IDENTITY, Vector3(0, y, 0.042)), Vector3(0.7, 0.7, 0.01), Color("#d9b26a"))


static func _kopuz_stand(sm: StagedMesh) -> Vector2:
	sm.beam(Vector3(0, 0, -0.1), Vector3(0, 0.8, 0), 0.04, 0.04, Color("#4d3520"))
	sm.blob(Vector3(0, 0.55, 0.06), Vector3(0.16, 0.2, 0.08), 11, Color("#8a5a3a"))
	sm.beam(Vector3(0, 0.75, 0.06), Vector3(0, 1.25, 0.04), 0.035, 0.025, Color("#6a4a2a"))
	return Vector2(0.2, 0.2)
