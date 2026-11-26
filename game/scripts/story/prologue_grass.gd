class_name PrologueGrass
extends Node3D
## Önsöz'ün yolunun ve Kayın Obası'nın çimeni (E21, K110). Kampın çayırı (Meadow) yalnız Göl Obası'nın 36 m'sini örter; vadinin zemini
## uzak kameradan çıplak bir yeşildir. Yolun iki yanına (yol kenarından NEAR_BAND m sık, BAND m'ye dek seyrek) ve obanın açıklığına
## (ctx.oba: merkez ve yarıçap; PrologueWorld.OBA_GRASS_R) kampın çayırının tutam ağlarıyla ve malzemesiyle (Meadow.tuft_mesh,
## atw_grass.gdshader; uzak kenarın iri tutamı gibi) çayır ve çiçek serpilir (≈13 bin tutam, ≈650 çiçek; kurulumu ≈0,2 sn). Yolun üstünde, derede, kazıkların, kayaların, yurtların dibinde çimen çıkmaz; obanın ocağının,
## kapıların, sabanın ve güreş halkasının çevresi ezik topraktır. Göl Obası'nın çayırına yaklaşınca seyrelir (çayırın kenarıyla karışır).
## Karelere bölünür (CHUNK); gölge düşürmez; kar örtüsünde tutamlar kısalır (atw_grass'ın hava payı). Yalnız Önsöz'de kurulur.
##   var g := PrologueGrass.new()
##   add_child(g)
##   g.build({"shape": shape, "road": road, "road_arc": arcs, "road_half": 0.85, "stream": stream, "stream_half": 1.3,
##            "blockers": [Vector3(x, z, r), ...], "trample": [Vector3(x, z, r), ...], "oba": Vector3(x, z, r)})

const CHUNK := 32.0
## Yol boyu örnek adımı (m) ve şeritler (yol kenarından, m).
const STEP := 0.5
const NEAR_BAND := 4.0
const BAND := 10.0
## Tutam yoğunluğu (m² başına): yolun yakın şeridi, uzak şeridi, oba.
const NEAR_DENSITY := 2.2
const FAR_DENSITY := 1.0
const OBA_DENSITY := 1.0
const OBA_CELL := 0.62
## Göl Obası'nın çayırı (Meadow: merkez, yarıçap 36 m; kenarı 26 m'den seyrelir): bu dairenin içinde çimen yok, BLEND m'de gürleşir.
const CAMP := Vector3(0.0, -2.0, 30.0)
const CAMP_BLEND := 8.0
## Tutamın boyu (m) ve iriliği (Meadow.periphery_tuft_scale gibi: uzak kameradan okunsun).
const HEIGHT := Vector2(0.14, 0.28)
const SPREAD := 1.5
const TALL_P := 0.22
const TALL_HEIGHT := Vector2(0.38, 0.6)
## Çiçek olasılığı (tutam başına) ve iriliği.
const FLOWER_P := 0.045
const FLOWER_SCALE := 1.35
## Kampın çayırının çeşitleri (Meadow.TUFT_VARIANTS sırası): kısa çayır ve uzun tutam.
const LAWN := 0
const TALL := 2
const HASH_CELL := 4.0

var tufts := 0
var flowers := 0

var _rng := RandomNumberGenerator.new()
var _patch: FastNoiseLite
var _road_hash := {}
var _stream_hash := {}
var _ctx: Dictionary = {}
var _grass: Dictionary = {}
var _flowers: Dictionary = {}


func build(ctx: Dictionary) -> void:
	_ctx = ctx
	_rng.seed = 20904081
	_patch = TerrainShape._make_noise(4108, 0.07, 2, FastNoiseLite.FRACTAL_FBM)
	var road: PackedVector2Array = ctx.get("road", PackedVector2Array())
	var arc: PackedFloat32Array = ctx.get("road_arc", PackedFloat32Array())
	_road_hash = PrologueGrass.line_hash(road, 1.0)
	_stream_hash = PrologueGrass.line_hash(ctx.get("stream", PackedVector2Array()), 1.0)
	if road.size() >= 2:
		_corridor(road, arc)
	_oba()
	_emit()


## Çizginin örnekleri ızgarada (saf): hücre → noktalar (her step m'de bir).
static func line_hash(line: PackedVector2Array, step: float) -> Dictionary:
	var out := {}
	for i in range(1, line.size()):
		var a := line[i - 1]
		var b := line[i]
		var n := maxi(ceili(a.distance_to(b) / step), 1)
		for k in n + 1:
			var p := a.lerp(b, float(k) / float(n))
			var key := Vector2i(floori(p.x / HASH_CELL), floori(p.y / HASH_CELL))
			if not out.has(key):
				# Dizi (Array) başvurudur; Packed dizi kopyalanarak taşınır, eklenen kaybolurdu.
				out[key] = []
			(out[key] as Array).append(p)
	return out


## Izgaradaki çizgiye en yakın uzaklık (saf; HASH_CELL'den uzaksa INF).
static func hash_distance(h: Dictionary, p: Vector2) -> float:
	var c := Vector2i(floori(p.x / HASH_CELL), floori(p.y / HASH_CELL))
	var best := INF
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var pts: Variant = h.get(c + Vector2i(dx, dz))
			if pts == null:
				continue
			for q: Vector2 in pts:
				best = minf(best, p.distance_squared_to(q))
	return sqrt(best) if best < INF else INF


## Noktada çimen çıkar mı, çıkarsa olasılığı (0..1): yol, dere, engeller, ezik toprak, kampın çayırı.
func chance(p: Vector2) -> float:
	var half := float(_ctx.get("road_half", 0.85))
	if PrologueGrass.hash_distance(_road_hash, p) < half + 0.15:
		return 0.0
	if PrologueGrass.hash_distance(_stream_hash, p) < float(_ctx.get("stream_half", 1.3)) + 0.35:
		return 0.0
	for c: Vector3 in _ctx.get("blockers", []):
		if p.distance_squared_to(Vector2(c.x, c.y)) < c.z * c.z:
			return 0.0
	var k := smoothstep(CAMP.z, CAMP.z + CAMP_BLEND, p.distance_to(Vector2(CAMP.x, CAMP.y)))
	for t: Vector3 in _ctx.get("trample", []):
		k *= smoothstep(t.z * 0.55, t.z * 1.35, p.distance_to(Vector2(t.x, t.y)))
	return k * (0.6 + 0.4 * _patch01(p))


func _patch01(p: Vector2) -> float:
	return clampf(_patch.get_noise_2d(p.x, p.y) * 0.5 + 0.5, 0.0, 1.0)


func _corridor(road: PackedVector2Array, arc: PackedFloat32Array) -> void:
	var half := float(_ctx.get("road_half", 0.85))
	var oba: Vector3 = _ctx.get("oba", Vector3(0.0, 0.0, -1.0))
	var length := arc[arc.size() - 1]
	var s := 0.0
	while s < length:
		var p0 := PrologueWorld.point_at_arc(road, arc, s)
		var t := (PrologueWorld.point_at_arc(road, arc, minf(s + 0.5, length)) - PrologueWorld.point_at_arc(road, arc, maxf(s - 0.5, 0.0))).normalized()
		var n := Vector2(-t.y, t.x)
		for side: float in [-1.0, 1.0]:
			for band: Vector3 in [Vector3(half + 0.2, half + NEAR_BAND, NEAR_DENSITY), Vector3(half + NEAR_BAND, half + BAND, FAR_DENSITY)]:
				var expect := band.z * (band.y - band.x) * STEP
				var count := floori(expect) + (1 if _rng.randf() < expect - floorf(expect) else 0)
				for i in count:
					var d := _rng.randf_range(band.x, band.y)
					var p := p0 + n * side * d + t * _rng.randf_range(-STEP * 0.5, STEP * 0.5)
					if oba.z > 0.0 and p.distance_to(Vector2(oba.x, oba.y)) < oba.z:
						continue
					if _rng.randf() < chance(p):
						_tuft(p, band.x > half + 1.0)
		s += STEP


func _oba() -> void:
	var oba: Vector3 = _ctx.get("oba", Vector3(0.0, 0.0, -1.0))
	if oba.z <= 0.0:
		return
	var c := Vector2(oba.x, oba.y)
	var n := ceili(oba.z / OBA_CELL)
	for ix in range(-n, n):
		for iz in range(-n, n):
			var p := c + Vector2(ix + _rng.randf(), iz + _rng.randf()) * OBA_CELL
			var d := p.distance_to(c)
			if d > oba.z:
				continue
			var edge := 1.0 - smoothstep(oba.z * 0.8, oba.z, d)
			if _rng.randf() < chance(p) * edge * OBA_DENSITY:
				_tuft(p, d > oba.z * 0.6)


func _tuft(p: Vector2, outer: bool) -> void:
	var shape: Variant = _ctx.get("shape")
	var y := float(shape.call(&"height_at", p.x, p.y)) if shape != null else 0.0
	var patch := _patch01(p)
	var tall := outer and _rng.randf() < TALL_P
	var h := (_rng.randf_range(TALL_HEIGHT.x, TALL_HEIGHT.y) if tall else lerpf(HEIGHT.x, HEIGHT.y, patch) * _rng.randf_range(0.85, 1.2)) * SPREAD
	var w := h * Meadow.tuft_aspect(h / SPREAD) * _rng.randf_range(0.9, 1.15)
	var xf := Transform3D(Basis.IDENTITY.scaled(Vector3(w, h, w)), Vector3(p.x, y - 0.02, p.y))
	_push(_grass, Vector3i(floori(p.x / CHUNK), floori(p.y / CHUNK), TALL if tall else LAWN), xf,
		Color(_rng.randf(), _rng.randf(), _rng.randf(), patch))
	tufts += 1
	if _rng.randf() < FLOWER_P * (0.6 + patch):
		var q := p + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(0.15, 0.4)
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.85, 1.2) * FLOWER_SCALE)
		var fy := float(shape.call(&"height_at", q.x, q.y)) if shape != null else 0.0
		var kind := Meadow.flower_kind(_rng.randf(), patch * 2.0 - 1.0)
		var stem := 1 if tall or h > 0.32 else 0
		_push(_flowers, Vector3i(floori(q.x / CHUNK), floori(q.y / CHUNK), stem), Transform3D(basis, Vector3(q.x, fy - 0.01, q.y)),
			Color(kind, _rng.randf(), 0.0, 0.0))
		flowers += 1


## Kareye örnek ekler (Packed diziler kopyalanarak taşındığı için burada normal diziler tutulur; Meadow._push gibi).
func _push(chunks: Dictionary, key: Vector3i, xf: Transform3D, custom: Color) -> void:
	if not chunks.has(key):
		chunks[key] = [[], []]
	(chunks[key][0] as Array).append(xf)
	(chunks[key][1] as Array).append(custom)


func _emit() -> void:
	var grass_mat := ShaderMaterial.new()
	grass_mat.shader = Meadow.GRASS_SHADER
	grass_mat.set_shader_parameter("instance_patches", true)
	var grass_meshes := {}
	for v: int in [LAWN, TALL]:
		var spec := Meadow.TUFT_VARIANTS[v]
		var lawn := v < Meadow.LAWN_VARIANTS
		grass_meshes[v] = Meadow.tuft_mesh(spec.x, spec.y, float(spec.z) / 100.0, 1 if lawn else 2,
			Meadow.BLADE_WIDTH.x if lawn else Meadow.BLADE_WIDTH.y)
	_emit_chunks(_grass, grass_meshes, grass_mat, "Grass")
	var flower_mat := ShaderMaterial.new()
	flower_mat.shader = Meadow.FLOWER_SHADER
	flower_mat.set_shader_parameter("light_wrap", 0.6)
	var flower_meshes := {}
	for i in Meadow.FLOWER_STEMS.size():
		flower_meshes[i] = Meadow.flower_cluster(Meadow.FLOWER_CLUSTER.x, Meadow.FLOWER_CLUSTER.y, Meadow.FLOWER_STEMS[i], 0.065)
	_emit_chunks(_flowers, flower_meshes, flower_mat, "Flowers")


func _emit_chunks(chunks: Dictionary, meshes: Dictionary, mat: Material, prefix: String) -> void:
	for key: Vector3i in chunks:
		var list: Array[Transform3D] = []
		list.assign(chunks[key][0])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "%s_%d_%d_%d" % [prefix, key.x, key.y, key.z]
		mmi.multimesh = Scatter.make_multimesh(meshes[key.z], list, PackedColorArray(chunks[key][1]))
		mmi.material_override = mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
