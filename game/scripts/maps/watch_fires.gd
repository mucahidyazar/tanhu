class_name WatchFires
extends Node3D
## Kışlak'ın dokuz nöbet ateşi (act1.md §4 «9 nöbet ateşi», §5, §15; job_watchfire): 16:30'da yanar, 07:40'ta söner (6 oyun dakikasında
## süzülür). Işık sahtedir (§15: gerçek ışık eklenmez): alev kendi parlayan kartıdır (flame.gdshader, tek MultiMesh: dokuz ateş bir çizim),
## zemin parıltısı kar gölgelendiricisinin içindedir (kislak_snow.gdshader fires[]: ateşin yerinde, Yakacak'ın yarıçapında turuncu
## yayılım; ekstra çizim yok). Yarıçap Yakacak'tan gelir (act1.md §2: ≤%60 6 m, ≥%100 12 m; set_fuel). Ocak taşı ve odunlar kamp ateşinin
## modelidir (MeshyProp, ışıksız). Saat MapWorld'ün saatidir (clock_source; yoksa gündüz: sönük).
##   var fires := WatchFires.new()
##   fires.setup(records, ground, [snow_material, ring_material])
##   fires.clock_source = func() -> GameClock: return session.clock
##   fires.set_fuel(0.6)

## Yanma ve sönme dakikası (oyun dakikası; act1.md §4) ve süzülme (oyun dakikası).
const LIGHT_AT := 990.0
const OUT_AT := 460.0
const FADE_MIN := 6.0
## Yakacak'ın yarıçapı (m; act1.md §2): ≤%60 6 m, ≥%100 12 m.
const RADIUS_LOW := 6.0
const RADIUS_HIGH := 12.0
## Gölgelendiricinin ateş tavanı (kislak_snow.gdshader fires[]).
const MAX_FIRES := 12
const FLAME_SHADER := preload("res://shaders/flame.gdshader")
const UPDATE_S := 0.5

## Saatin kaynağı (GameClock ya da null döner).
var clock_source: Callable
## Ateşlerin yeri (dünya; zeminde) ve kimlikleri.
var points: PackedVector3Array = []
var ids: PackedStringArray = []
## Yakacak (0..1+, act1.md §2'nin Kış Hesabı) ve o anki yanma payı (0..1).
var fuel := 0.6
var lit := 0.0
var materials: Array[ShaderMaterial] = []

var _flames: MultiMeshInstance3D
var _flame_mat: ShaderMaterial
var _acc := 0.0


## Saf: dakikanın yanma payı (16:30–07:40 yanık; sınırda FADE_MIN dakikada süzülür).
static func lit_at(minute: float) -> float:
	var m := fposmod(minute, 1440.0)
	var on := smoothstep(LIGHT_AT, LIGHT_AT + FADE_MIN, m)
	var off := 1.0 - smoothstep(OUT_AT, OUT_AT + FADE_MIN, m)
	return maxf(on, off) if m >= LIGHT_AT or m < OUT_AT + FADE_MIN else 0.0


## Saf: Yakacak payından parıltının yarıçapı (m).
static func radius_for(p_fuel: float) -> float:
	return lerpf(RADIUS_LOW, RADIUS_HIGH, smoothstep(0.6, 1.0, p_fuel))


## Kurar: yapı kayıtları (kind watch_fire), yükseklik yüzü ve parıltıyı yazacak zemin malzemeleri.
func setup(records: Array, shape: TerrainShape, p_materials: Array[ShaderMaterial]) -> void:
	materials = p_materials
	points.clear()
	ids.clear()
	for rec: Dictionary in records:
		if str(rec.get("kind", "")) != "watch_fire":
			continue
		var at: Vector2 = MapSpec.vec2(rec.get("at", [0.0, 0.0]))
		points.append(Vector3(at.x, shape.height_at(at.x, at.y) if shape else 0.0, at.y))
		ids.append(str(rec.get("id", "")))


func _ready() -> void:
	for i in points.size():
		var pit := MeshyProp.new()
		pit.name = ids[i].to_pascal_case()
		pit.folder = "props"
		pit.model_id = "campfire"
		pit.target_size = 1.4
		pit.size_axis = MeshyProp.SizeAxis.LONGEST
		pit.sink = 0.04
		pit.register_obstacle = true
		pit.obstacle_scale = 0.7
		pit.position = points[i]
		pit.rotation.y = float(i) * 1.37
		add_child(pit)
	_flame_mat = ShaderMaterial.new()
	_flame_mat.shader = FLAME_SHADER
	_flame_mat.set_shader_parameter(&"energy", 0.0)
	var quad := QuadMesh.new()
	quad.size = Vector2(0.95, 1.35)
	quad.center_offset = Vector3(0.0, 0.62, 0.0)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = quad
	mm.instance_count = points.size() * 2
	for i in points.size():
		for k in 2:
			var s := 1.0 - 0.28 * float(k) + 0.08 * sin(float(i) * 3.1)
			mm.set_instance_transform(i * 2 + k, Transform3D(Basis().scaled(Vector3.ONE * s), points[i] + Vector3(0.12 * float(k), 0.05, -0.1 * float(k))))
	_flames = MultiMeshInstance3D.new()
	_flames.name = "Flames"
	_flames.multimesh = mm
	_flames.material_override = _flame_mat
	_flames.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flames.visible = false
	add_child(_flames)
	refresh()


func _process(delta: float) -> void:
	_acc += delta
	if _acc < UPDATE_S:
		return
	_acc = 0.0
	refresh()


## Yakacağı yazar (Kış Hesabı; 0,6 = %60).
func set_fuel(p_fuel: float) -> void:
	fuel = p_fuel
	refresh()


## Saatten yanma payını okur, alevin parlaklığını ve zeminin parıltısını yazar.
func refresh() -> void:
	var clock: GameClock = clock_source.call() if clock_source.is_valid() else null
	lit = lit_at(clock.minute) if clock else 0.0
	if _flame_mat:
		_flame_mat.set_shader_parameter(&"energy", 3.0 * lit)
	if _flames:
		_flames.visible = lit > 0.01
	var arr := PackedVector4Array()
	var r := radius_for(fuel)
	for i in mini(points.size(), MAX_FIRES):
		arr.append(Vector4(points[i].x, points[i].z, r, lit))
	while arr.size() < MAX_FIRES:
		arr.append(Vector4.ZERO)
	for mat in materials:
		if mat:
			mat.set_shader_parameter(&"fires", arr)
			mat.set_shader_parameter(&"fire_count", mini(points.size(), MAX_FIRES) if lit > 0.0 else 0)
