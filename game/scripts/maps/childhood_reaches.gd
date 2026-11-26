class_name ChildhoodReaches
extends Node3D
## Çocukluk'un uzak yerleri (E21, K110; layout.json "childhood.ebe", "childhood.far"): yalnız Çocukluk'ta (ChildhoodSite kurar).
##   Ebe/Structures  Ebe Obası'nın üç yurdu: kodla kurulan yurt (StructureKit, StructureSet: ≤40 m tam yurt, 40–220 m kapalı örnek, ötesi
##                   kubbe; godot.md §4.6); Hereka'nın yurdu açıktır (içine girilir, iç düzeni kurulur). Ocağın dumanı.
##   Post            bağlama direği (Ak Kemik'in direği): dikili kazık, başında sarılı ip
##   Smokes          Dailin'e gelen boyların ocak dumanları: ufukta, ≈0,6–1,1 km (kadrajın ötesi; kamera bakışı kaldırınca görünür)
##   Riders          uzak atlı kümeleri: ufukta yürüyerek sayıma gelir (koyu siluet; tek MultiMesh)
##   Fires           Dailin'e gelen boyların gece ateşleri: dumanların dibinde turuncu ışık noktaları (tek MultiMesh, toplamalı, sisten
##                   etkilenmez; gerçek ışık yok); gün batımından sonra belirir, şafakta söner (set_minute)
##   Cranes          güneye geçen turnalar (CraneFlock; fly_cranes() bir kez geçirir: V gökte, gölgesi zeminde)

const RIDER_COLOR := Color(0.14, 0.12, 0.11, 0.0)
const HORSE_COLOR := Color(0.24, 0.18, 0.13, 0.0)

var ground: OrdosGround
var layout: Dictionary = {}
var structures: StructureSet
var cranes: CraneFlock
var riders: MultiMeshInstance3D
var post: Node3D

## Parçaları ChildhoodSite mi kuracak (kare bütçesinde; parts)? Değilse _ready hepsini kurar (sınama).
var deferred := false
## Yurtların saati (StructureSet.clock_source; ChildhoodSite oyunun dakikasını verir).
var clock_source: Callable

var fires: MultiMeshInstance3D
var _fire_mat: StandardMaterial3D
var _fire_alpha := -1.0
var _rider_groups: Array[Dictionary] = []
var _crane_t := -1.0
var _crane_s := 60.0
var _ebe: Node3D


func setup(p_ground: OrdosGround, p_layout: Dictionary) -> void:
	ground = p_ground
	layout = p_layout


func _ready() -> void:
	if deferred:
		return
	for part in parts():
		part.call()


## Kurulumun parçaları (sırayla; her biri bir karenin dilimine sığar): obanın kökü, her yurt, ocak, direk, dumanlar, atlılar, turnalar.
func parts() -> Array[Callable]:
	var d: Dictionary = layout.get("childhood", {})
	var out: Array[Callable] = []
	var ebe: Dictionary = d.get("ebe", {})
	if not ebe.is_empty():
		out.append(_build_ebe_root)
		for rec: Variant in ebe.get("yurts", []):
			out.append(_build_ebe_yurt.bind(rec))
		out.append(_build_ebe_fire.bind(ebe.get("fire", {})))
	var far: Dictionary = d.get("far", {})
	out.append(_build_post.bind(far.get("post", {})))
	out.append(_build_smokes.bind(far.get("smokes", [])))
	out.append(_build_fires.bind(far.get("smokes", [])))
	out.append(_build_riders.bind(far.get("riders", [])))
	out.append(_build_cranes.bind(far.get("cranes", {})))
	return out


func _process(delta: float) -> void:
	_tick_riders(delta)
	if _crane_t >= 0.0 and cranes:
		_crane_t += delta / _crane_s
		cranes.progress = clampf(_crane_t, 0.0, 1.0)
		if _crane_t >= 1.0:
			_crane_t = -1.0
			cranes.visible = false
			cranes.set_sounding(false)


# --- Yüz -------------------------------------------------------------------------------------------------

## Turnaları bir kez geçirir (seconds saniyede yolun başından sonuna; ses açık).
func fly_cranes(seconds: float = 60.0) -> void:
	if cranes == null:
		return
	_crane_s = maxf(seconds, 1.0)
	_crane_t = 0.0
	cranes.progress = 0.0
	cranes.visible = true
	cranes.set_sounding(true, false)


func cranes_flying() -> bool:
	return _crane_t >= 0.0


## Turnaların o anki merkezi (geçmiyorsa Vector3.INF).
func cranes_position() -> Vector3:
	return cranes.global_position if cranes and _crane_t >= 0.0 else Vector3.INF


## Dailin'in en yakın dumanının yönü (kameranın bakışı için; yoksa Vector3.INF).
func nearest_smoke(from: Vector3) -> Vector3:
	var best := Vector3.INF
	for row: Array in ((layout.get("childhood", {}) as Dictionary).get("far", {}) as Dictionary).get("smokes", []):
		var p := Vector3(float(row[0]), 0.0, float(row[1]))
		if best == Vector3.INF or ChildhoodStep.flat(p, from) < ChildhoodStep.flat(best, from):
			best = p
	return best


## Ebe Obası'nın yurtlarının kayıtları (saf): StructureKit.normalize ile.
static func ebe_records(p_layout: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for rec: Variant in (((p_layout.get("childhood", {}) as Dictionary).get("ebe", {}) as Dictionary).get("yurts", [])):
		if rec is Dictionary:
			out.append(StructureKit.normalize(rec, {"style": "hun"}))
	return out


## Ebe Obası'nın yurtlarının engeli (saf): kapalı yurt daire (foot), açık yurt kapı aralıklı halka duvar.
static func ebe_circles(p_layout: Dictionary) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for r in ebe_records(p_layout):
		if bool(r.get("open", false)):
			continue
		var d := YurtGeometry.dims(YurtStyle.find(str(r["style"])), str(r["size"]))
		var at: Vector2 = r["at"]
		out.append(Vector3(at.x, at.y, float(d["foot"])))
	return out


static func ebe_walls(p_layout: Dictionary) -> Array[RingWall]:
	var out: Array[RingWall] = []
	for r in ebe_records(p_layout):
		if not bool(r.get("open", false)):
			continue
		var d := YurtGeometry.dims(YurtStyle.find(str(r["style"])), str(r["size"]))
		var at: Vector2 = r["at"]
		var rot := float(r["rot"])
		var door: Vector2 = d["door"]
		out.append(RingWall.new(at, float(d["radius"]), Vector2(sin(rot), cos(rot)), door.x * 0.5, 0.18))
	return out


# --- Kurulum ---------------------------------------------------------------------------------------------

func _build_ebe_root() -> void:
	_ebe = Node3D.new()
	_ebe.name = "Ebe"
	add_child(_ebe)
	structures = StructureSet.new()
	structures.ground = ground
	structures.clock_source = clock_source if clock_source.is_valid() else func() -> float: return 600.0
	_ebe.add_child(structures)


func _build_ebe_yurt(rec: Variant) -> void:
	if structures == null:
		return
	var node := StructureKit.build(rec as Dictionary, {"ground": ground, "set": structures, "style": "hun"})
	if node:
		structures.add_child(node)


func _build_ebe_fire(fire: Dictionary) -> void:
	var ebe := _ebe
	if ebe == null:
		return
	if not fire.is_empty():
		var at := OrdosGround._vec2(fire.get("at", [0.0, 0.0]))
		var smoke := Fx.smoke(Vector2(1.4, 4.2), Vector2(-0.9, -0.3))
		smoke.name = "FireSmoke"
		ebe.add_child(smoke)
		smoke.global_position = Vector3(at.x, ground.height_at(at.x, at.y) + 0.3, at.y)
		var stones := MeshInstance3D.new()
		stones.name = "FireRing"
		var draft := FaunaMesh.Draft.new()
		for k in 7:
			var a := TAU * float(k) / 7.0
			draft.blob(Vector3(cos(a) * 0.55, 0.08, sin(a) * 0.55), Vector3(0.16, 0.1, 0.13), Basis(Vector3.UP, a), 1, Color(0.42, 0.4, 0.37, 0.0), Vector4.ZERO)
		draft.blob(Vector3(0.0, 0.03, 0.0), Vector3(0.38, 0.04, 0.38), Basis.IDENTITY, 1, Color(0.12, 0.09, 0.07, 0.0), Vector4.ZERO)
		stones.mesh = FaunaMesh.make_mesh(draft.arrays())
		stones.material_override = Style.toon(Color.WHITE, {"use_vertex_color": true})
		ebe.add_child(stones)
		stones.global_position = Vector3(at.x, ground.height_at(at.x, at.y), at.y)


## Bağlama direği: kazık, başında sarılı ip ve sarkan ucu.
func _build_post(def: Dictionary) -> void:
	if def.is_empty():
		return
	var at := OrdosGround._vec2(def.get("at", [0.0, 0.0]))
	var h := float(def.get("height", 1.5))
	var draft := FaunaMesh.Draft.new()
	draft.tube(PackedVector3Array([Vector3(0.0, -0.2, 0.0), Vector3(0.01, h * 0.5, 0.0), Vector3(0.02, h, 0.01)]), PackedFloat32Array([0.075, 0.065, 0.055]), 7,
		Color(0.3, 0.21, 0.14, 0.0), Vector4.ZERO)
	draft.tube(PackedVector3Array([Vector3(0.0, h - 0.18, 0.0), Vector3(0.0, h - 0.08, 0.0)]), PackedFloat32Array([0.085, 0.085]), 8, Color(0.68, 0.58, 0.42, 0.0), Vector4.ZERO)
	draft.tube(PackedVector3Array([Vector3(0.07, h - 0.14, 0.0), Vector3(0.16, h - 0.5, 0.05), Vector3(0.18, h - 0.82, 0.08)]), PackedFloat32Array([0.012, 0.011, 0.01]), 4,
		Color(0.66, 0.56, 0.4, 0.0), Vector4.ZERO)
	post = MeshInstance3D.new()
	post.name = "Post"
	(post as MeshInstance3D).mesh = FaunaMesh.make_mesh(draft.arrays())
	(post as MeshInstance3D).material_override = Style.toon(Color.WHITE, {"use_vertex_color": true, "brush_strength": 0.15})
	add_child(post)
	post.global_position = Vector3(at.x, ground.height_at(at.x, at.y), at.y)


## Dailin'in dumanları: ufukta büyük, ağır duman sütunları (Fx.smoke; rüzgârla doğuya eğilir), her biri bir boyun ocakları.
func _build_smokes(rows: Array) -> void:
	if rows.is_empty():
		return
	var node := Node3D.new()
	node.name = "Smokes"
	add_child(node)
	var k := 0
	for row: Array in rows:
		var h := float(row[2]) if row.size() > 2 else 36.0
		var smoke := Fx.smoke(Vector2(h * 0.32, h), Vector2(h * 0.4, h * 0.06))
		smoke.name = "Smoke%d" % k
		var mat := smoke.material_override as ShaderMaterial
		if mat:
			mat.set_shader_parameter("smoke_color", Color(0.72, 0.68, 0.64, 1.0))
			mat.set_shader_parameter("opacity", 0.32)
		node.add_child(smoke)
		var x := float(row[0])
		var z := float(row[1])
		smoke.global_position = Vector3(x, ground.height_at(x, z), z)
		k += 1


## Dailin'in gece ateşleri: her dumanın dibinde 4–6 ateş (boyun konağı), tohumlu dağılım; kart kameraya döner, uzaklıkla büyür (≈1 km'de
## birkaç piksellik turuncu nokta).
func _build_fires(rows: Array) -> void:
	if rows.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 7311
	var spots: Array[Vector3] = []
	for row: Array in rows:
		var cx := float(row[0])
		var cz := float(row[1])
		for k in rng.randi_range(4, 6):
			var p := Vector2(cx, cz) + Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(6.0, 48.0)
			spots.append(Vector3(p.x, rng.randf_range(0.75, 1.25), p.y))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var quad := QuadMesh.new()
	quad.size = Vector2(1.0, 1.0)
	mm.mesh = quad
	mm.instance_count = spots.size()
	for i in spots.size():
		var q := spots[i]
		var size := 7.0 * q.y
		var y := ground.height_at(q.x, q.z) + size * 0.3
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * size), Vector3(q.x, y, q.z)))
	fires = MultiMeshInstance3D.new()
	fires.name = "Fires"
	fires.multimesh = mm
	_fire_mat = StandardMaterial3D.new()
	_fire_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_fire_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_fire_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_fire_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_fire_mat.billboard_keep_scale = true
	_fire_mat.disable_fog = true
	_fire_mat.albedo_texture = Fx.soft_dot_texture()
	_fire_mat.albedo_color = Color(1.0, 0.56, 0.22, 0.0)
	fires.material_override = _fire_mat
	fires.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fires.visible = false
	add_child(fires)


## Gecenin oranı (saf; 0..1): gün batımından (17:55) bir saatte belirir, şafakta (05:40–06:30) söner.
static func night_of(minute: float) -> float:
	var m := fposmod(minute, 1440.0)
	return maxf(smoothstep(1075.0, 1135.0, m), 1.0 - smoothstep(340.0, 390.0, m))


## Oyunun dakikası (ChildhoodSite.set_minute): gece ateşleri.
func set_minute(minute: float) -> void:
	if fires == null:
		return
	var a := night_of(minute)
	if absf(a - _fire_alpha) < 0.01:
		return
	_fire_alpha = a
	fires.visible = a > 0.01
	_fire_mat.albedo_color.a = a * 0.95


## Uzak atlılar: kümeler from'dan to'ya yürür, varınca baştan (ufukta hep birileri gelir); tek MultiMesh, gölgesiz.
func _build_riders(groups: Array) -> void:
	if groups.is_empty():
		return
	var total := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 228
	for g: Variant in groups:
		var e: Dictionary = g
		var offsets: Array[Vector2] = []
		for i in int(e.get("count", 5)):
			offsets.append(Vector2(rng.randf_range(-6.0, 6.0), float(i) * 4.5 + rng.randf_range(-1.0, 1.0)))
		_rider_groups.append({"from": OrdosGround._vec2(e.get("from", [0.0, 0.0])), "to": OrdosGround._vec2(e.get("to", [0.0, 0.0])),
			"speed": float(e.get("speed", 2.0)), "t": rng.randf(), "offsets": offsets, "first": total})
		total += offsets.size()
	var draft := FaunaMesh.Draft.new()
	draft.blob(Vector3(0.0, 1.2, 0.0), Vector3(0.32, 0.36, 0.95), Basis.IDENTITY, 1, HORSE_COLOR, Vector4.ZERO)
	draft.blob(Vector3(0.0, 1.62, 0.88), Vector3(0.16, 0.34, 0.2), Basis(Vector3.RIGHT, -0.6), 1, HORSE_COLOR, Vector4.ZERO)
	for x: float in [-0.18, 0.18]:
		for z: float in [-0.6, 0.6]:
			draft.tube(PackedVector3Array([Vector3(x, 0.95, z), Vector3(x, 0.0, z)]), PackedFloat32Array([0.07, 0.05]), 4, HORSE_COLOR, Vector4.ZERO)
	draft.blob(Vector3(0.0, 2.05, -0.05), Vector3(0.24, 0.42, 0.2), Basis.IDENTITY, 1, RIDER_COLOR, Vector4.ZERO)
	draft.blob(Vector3(0.0, 2.55, -0.02), Vector3(0.13, 0.15, 0.13), Basis.IDENTITY, 1, RIDER_COLOR, Vector4.ZERO)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = FaunaMesh.make_mesh(draft.arrays())
	mm.instance_count = total
	riders = MultiMeshInstance3D.new()
	riders.name = "Riders"
	riders.multimesh = mm
	riders.material_override = Style.toon(Color.WHITE, {"use_vertex_color": true})
	riders.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	riders.custom_aabb = AABB(Vector3(-1500.0, -60.0, -1500.0), Vector3(3000.0, 160.0, 3000.0))
	add_child(riders)
	_tick_riders(0.0)


func _tick_riders(delta: float) -> void:
	if riders == null:
		return
	var mm := riders.multimesh
	for g in _rider_groups:
		var from: Vector2 = g["from"]
		var to: Vector2 = g["to"]
		var length := maxf(from.distance_to(to), 1.0)
		g["t"] = fposmod(float(g["t"]) + float(g["speed"]) * delta / length, 1.0)
		var dir := (to - from).normalized()
		var side := Vector2(-dir.y, dir.x)
		var base := from.lerp(to, float(g["t"]))
		var yaw := atan2(dir.x, dir.y)
		var offsets: Array[Vector2] = g["offsets"]
		for i in offsets.size():
			var p := base + side * offsets[i].x - dir * offsets[i].y
			var y := ground.height_at(p.x, p.y) if ground else 0.0
			mm.set_instance_transform(int(g["first"]) + i, Transform3D(Basis(Vector3.UP, yaw), Vector3(p.x, y, p.y)))


func _build_cranes(def: Dictionary) -> void:
	if def.is_empty():
		return
	cranes = CraneFlock.new()
	cranes.name = "Cranes"
	cranes.count = clampi(int(def.get("count", 11)), 8, 12)
	var h := float(def.get("height", 70.0))
	var a := OrdosGround._vec2(def.get("from", [0.0, 0.0]))
	var b := OrdosGround._vec2(def.get("to", [0.0, 0.0]))
	cranes.start_point = Vector3(a.x, h, a.y)
	cranes.end_point = Vector3(b.x, h, b.y)
	cranes.ground_shadows = true
	cranes.ground_y = 0.0
	cranes.call_unit_size = 90.0
	cranes.visible = false
	add_child(cranes)
