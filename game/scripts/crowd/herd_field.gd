class_name HerdField
extends Node3D
## Sürü (fauna.md §10, godot.md §4.5, K65): tek ağlı, tek çizimli MultiMeshInstance3D; iskelet yoktur. Yürüyüş, otlama, kuyruk ve soluk
## köşe gölgelendiricisindedir (shaders/herd_field.gdshader); evre, genlik, otlama ve tohum INSTANCE_CUSTOM'dadır. Konumları HerdSim
## 4 Hz'de hesaplar, aradaki kareler ara değerlenir. Oyun kodu burada ajan tutmaz; Çocukluk'un sürüsü 40 koyundur.
##
## Ağ: türün Meshy modeli varsa (FaunaKind.herd_model_path: önce uzak ağ assets/animals/sheep/sheep_far.glb, 1.300 üçgen; yoksa sheep.glb) arka planda yüklenir,
## köşe verisi ve boyası FaunaMesh.from_model ile ağdan ve dokudan çıkarılır, gerekirse T1 bütçesine (≤1.800 üçgen; türün model.max_triangles'ı) indirilir, boyu modelin
## ölçüsüdür (sheep.json length_m) ve kendiliğinden yerine geçer (model_ready); dosya yokken FaunaMesh'in kodla çizdiği koyun görünür. Kod ve sahne değişmez.
##
## Dışarıdan sürüş (dört adım, childhood-p2; hepsi anlıktır, olay sinyalle gelir):
##   herd.setup(layout["childhood"], world.ground, obstacles)  # ağaca eklemeden önce (ChildhoodSite kurar)
##   herd.release()                 # kapı açık kabul edilir: tek tek çıkar, çayıra yayılır. released → settled
##   herd.drive_through_line()      # tek sıra rotada; her koyun sayılınca sheep_counted(i, tally); sonunda count_finished(total)
##   herd.tally()                   # sayılan koyun; herd.released_total(): ağıldan çıkan; herd.count_eta(): sayımın bitmesine kalan sn
##   herd.place_in_pen() / place_on_meadow() / place_after_count()   # anında (atlanan sahne, ölçüm)
##   herd.set_avoid_nodes([oyuncu, ...]); koyun yol verir, oyuncuya çarpmaz (oyuncunun koyunla çarpışması yoktur)
##   herd.sheep_position(i), herd.count(), herd.phase()
##
## Açık otlağın sürüsü (Kışlak, Ak Otlak: 60 at, 200 koyun; act-1-p2): setup_flock(flock, shape) PastureFlock'u çizer. FaunaDirector sürüyü 4 Hz'de
## adımlar (external_tick): HerdField kendi tikini atmaz, sürünün saati (flock.clock) ilerleyince yükseklikleri ve olayları okur, aradaki kareleri
## ara değerler. Türün görünüşü kinds.json «herd»dendir (don çeşitleri, otlama açısı; Hun Atı boy ×0,94, K65); kamera write_range'in ötesindeyken
## tampon yazılmaz (sürü görünmez, kare başına iş yok).

signal released
signal settled
signal sheep_counted(index: int, tally: int)
signal count_finished(total: int)
## Meshy ağı yerine geçti.
signal model_ready
## E21 (K110, «Çobanlık»): sürülen sürü (HerdSim.Phase.DRIVEN): koyun yoldan saptı / sürüye döndü, sürünün ortası hedefe vardı, sayım kapısından
## geçti (iki taşın arası), ağıla girerken sayıldı, hepsi ağılda.
signal strayed(index: int)
signal stray_back(index: int)
signal arrived
signal gate_counted(index: int, tally: int)
signal penned(index: int, tally: int)
signal all_in(total: int)

const SHADER := preload("res://shaders/herd_field.gdshader")
## Örnek başına sayı: 12 dönüşüm + 4 özel veri (evre, genlik, otlama, tohum).
const FLOATS_PER_SHEEP := 16
## Bacağın kalçadan ayağa boyu (metre): adımın salınım genliği buradan çıkar.
const LEG_LENGTH := FaunaMesh.SHEEP_HIP
## Kalan koyunların ağırlığı için ölçek: küçük koyunlar kuzu (güzde yarı büyümüş).
const SCALE_RANGE := Vector2(0.9, 1.12)
const LAMB_SHARE := 0.15
const LAMB_RANGE := Vector2(0.66, 0.8)
## Yön dönüşünün keskinliği, hızın ivmesi (m/sn²) ve otlamanın geçiş hızı (1/sn).
const TURN_SHARPNESS := 6.0
const SPEED_RATE := 4.0
const GRAZE_RATE := 1.4
## Kaçınılan düğümlerin yarıçapı (metre).
const AVOID_RADIUS := 1.7
## Sürünün kırpma kutusunun yarı boyu (metre; bütün oyun alanı): buffer her kare yazılır, AABB yeniden hesaplanmasın.
const CULL_HALF := Vector3(200.0, 30.0, 200.0)

@export var kind_id := "sheep"
## Dışarıdan adımlanır mı (FaunaDirector; setup_flock açar)? Kapalıyken HerdField kendi 4 Hz tikini atar (Çocukluk).
@export var external_tick := false
## Kamera sürünün merkezine bundan uzaksa tampon yazılmaz (m; 0 ise hep yazılır).
@export var write_range := 0.0
## Dışarıdan adımlanan sürüde kadrajın odağı (kameranın baktığı yer; düzlem) ve yarıçapı: ötesindeki hayvanın karesi yazılmaz (0: hepsi).
var focus := Vector2.INF
var focus_radius := 0.0

var sim: HerdSim
## Açık otlağın sürüsü (setup_flock; o zaman sim boştur).
var flock: PastureFlock
var kind: FaunaKind
var ground: TerrainShape
var instance: MultiMeshInstance3D

var _mm: MultiMesh
var _material: ShaderMaterial
var _buffer := PackedFloat32Array()
var _accum := 0.0
var _y0 := PackedFloat32Array()
var _y1 := PackedFloat32Array()
var _yaw := PackedFloat32Array()
var _speed := PackedFloat32Array()
var _phase := PackedFloat32Array()
var _graze := PackedFloat32Array()
var _size := PackedFloat32Array()
var _seed := PackedFloat32Array()
var _stride_walk := 0.86
var _stride_trot := 1.19
var _speed_trot := 2.5
var _speed_walk := 1.1
var _avoid_nodes: Array[Node3D] = []
## E21: sürücüler (düğüm, ürkme yarıçapı) ve öndeki (Luhun).
var _driver_nodes: Array[Node3D] = []
var _driver_radii := PackedFloat32Array()
var _leader_node: Node3D
var _model_path := ""
## 0 yok, 1 yükleniyor, 2 iş parçacığında çevriliyor, 3 yüklendi (ağaçtan çıkarken alındı), işi bekliyor.
var _model_state := 0
var _model_scene: PackedScene
var _model_job: _ModelJob
var _uses_model := false
var _seen_clock := -1.0
var _young_share := LAMB_SHARE
var _young_range := LAMB_RANGE
var _model_scale := 1.0


## İş parçacığında Meshy ağının sürü ağına çevrilmesi.
class _ModelJob:
	extends RefCounted
	var surface: Array = []
	var image: Image
	var length := 1.264
	var max_triangles := 1800
	var ratios: Dictionary = {}
	var result: Dictionary = {}
	var task_id := -1
	var waited := false

	func run() -> void:
		if image and image.is_compressed():
			image.decompress()
		result = FaunaMesh.from_model(surface, length, max_triangles, image, ratios)


## Kurulum (ağaca eklenmeden önce): spec layout.json "childhood" sözlüğü, shape yükseklik yüzü, obstacles Vector3(x, z, yarıçap).
## arrays verilirse kodla çizilen ağın hazır verisidir (iş parçacığından); verilmezse burada çizilir.
func setup(spec: Dictionary, shape: TerrainShape, obstacles: Array[Vector3] = [], arrays: Dictionary = {}) -> void:
	kind = FaunaKind.named(kind_id)
	ground = shape
	var speeds: Dictionary = kind.def.get("speed", {}) if kind else {}
	sim = HerdSim.new(spec, speeds)
	sim.obstacles = obstacles
	if kind:
		_stride_walk = kind.stride("walk", _stride_walk)
		_stride_trot = kind.stride("trot", _stride_trot)
		_speed_walk = kind.speed("walk", _speed_walk)
		_speed_trot = kind.speed("trot", _speed_trot)
	_alloc()
	# Boylar (kuzu, iri koç) ve engeller şimdi belli: ağıldaki ilk yerleşim onlarla bir daha ayrılır.
	sim.relax()
	_build_instance(arrays)
	snap()


## Açık otlağın sürüsünü kurar (ağaca eklenmeden önce; Kışlak): sürüyü FaunaDirector adımlar. young_share ve young_range genç hayvanların
## payı ve boy çarpanı (kuzu, tay); arrays kodla çizilen ağın hazır verisi (yaban domuzu gibi modelsiz tür).
func setup_flock(p_flock: PastureFlock, shape: TerrainShape, young_share: float = LAMB_SHARE, young_range: Vector2 = LAMB_RANGE, arrays: Dictionary = {}) -> void:
	flock = p_flock
	kind_id = flock.kind_id
	kind = FaunaKind.named(kind_id)
	ground = shape
	external_tick = true
	_young_share = young_share
	_young_range = young_range
	if kind:
		_model_scale = kind.model_scale()
		_stride_walk = kind.stride("walk", _stride_walk) * 1.0
		_stride_trot = kind.stride("trot", _stride_trot)
		_speed_walk = kind.speed("walk", _speed_walk)
		_speed_trot = kind.speed("trot", _speed_trot)
	_alloc()
	flock.relax()
	_build_instance(arrays)
	_apply_look()
	# Sürünün bütün otlağı (ve ağılı) kırpma kutusunda: düğüm haritanın kökündedir.
	var lo := flock.home - Vector2.ONE * (flock.home_radius + 40.0)
	var hi := flock.home + Vector2.ONE * (flock.home_radius + 40.0)
	if flock.fold.is_finite():
		lo = lo.min(flock.fold - Vector2.ONE * 30.0)
		hi = hi.max(flock.fold + Vector2.ONE * 30.0)
	instance.custom_aabb = AABB(Vector3(lo.x, -80.0, lo.y), Vector3(hi.x - lo.x, 200.0, hi.y - lo.y))
	snap()


func _ready() -> void:
	if sim == null and flock == null:
		push_warning("[herd] setup çağrılmadı")
		set_process(false)
		return
	_request_model()


func _exit_tree() -> void:
	if _model_job and _model_job.task_id >= 0 and not _model_job.waited:
		WorkerThreadPool.wait_for_task_completion(_model_job.task_id)
		_model_job.waited = true
	# Alınmamış arka plan yüklemesi yükleyicide öksüz kalır (çıkışta ObjectDB sızıntısı): bitmesi beklenip alınır. Düğüm ağaca
	# dönerse model oradan sürer.
	if _model_state == 1:
		var status := ResourceLoader.load_threaded_get_status(_model_path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS or status == ResourceLoader.THREAD_LOAD_LOADED:
			_model_scene = ResourceLoader.load_threaded_get(_model_path) as PackedScene
			_model_state = 3
		else:
			_model_state = 0


func _process(delta: float) -> void:
	_poll_model()
	if external_tick:
		_process_external(delta)
		return
	_accum += delta
	var ticks := 0
	while _accum >= HerdSim.TICK and ticks < 4:
		_accum -= HerdSim.TICK
		ticks += 1
		_tick()
	if _accum >= HerdSim.TICK:
		_accum = 0.0
	_write(_accum / HerdSim.TICK, delta)


# --- Yüz ---------------------------------------------------------------------------------------------

func count() -> int:
	return _n()


func phase() -> HerdSim.Phase:
	return sim.phase


func tally() -> int:
	return sim.counted_total()


func released_total() -> int:
	return sim.released_total()


## Sayımın bitmesine kalan tahmini süre (sn; HerdSim.count_eta).
func count_eta() -> float:
	return sim.count_eta() if sim else 0.0


func release(center: Variant = null, radius: float = -1.0, hold: int = 0) -> void:
	sim.release(center, radius, hold)


## Ağılda bırakılan koyunlar (HerdSim.release'in hold'u): sayı, dünya yerleri, hepsini salmak.
func held_count() -> int:
	return sim.held_count() if sim else 0


func held_positions() -> PackedVector3Array:
	var out := PackedVector3Array()
	if sim == null:
		return out
	for p in sim.held_positions():
		out.append(Vector3(p.x, ground.height_at(p.x, p.y) if ground else 0.0, p.y))
	return out


func release_held() -> void:
	if sim:
		sim.release_held()


func drive_through_line() -> void:
	sim.drive()


func place_in_pen() -> void:
	sim.place_in_pen()
	snap()


func place_on_meadow(center: Variant = null, radius: float = -1.0) -> void:
	sim.place_on_meadow(center, radius)
	snap()


func place_after_count() -> void:
	sim.place_after_count()
	snap()


## Kaçınılacak düğümler (oyuncu, binek): 4 Hz'de konumları sorulur.
func set_avoid_nodes(nodes: Array[Node3D]) -> void:
	_avoid_nodes = nodes


# --- E21 (K110): sürülen sürü ------------------------------------------------------------------------------------

## Sürücüler (oyuncu, kanattaki çocuklar) ve ürkme yarıçapları (m); 4 Hz'de konumları sorulur.
func set_drivers(nodes: Array[Node3D], radii: PackedFloat32Array) -> void:
	_driver_nodes = nodes
	_driver_radii = radii
	if sim and nodes.is_empty():
		sim.drivers = []


## Öndeki (Luhun): koyun onu izler (yoksa null).
func set_leader(node: Node3D) -> void:
	_leader_node = node
	if sim and node == null:
		sim.leader = Vector2.INF


func drive_along(path: PackedVector2Array, radius: float = 10.0) -> void:
	sim.drive_along(path, radius)


func stray(side: float, n: int = 3, dist: float = 26.0) -> PackedInt32Array:
	return sim.stray(side, n, dist)


func stray_positions() -> PackedVector3Array:
	var out := PackedVector3Array()
	for p in sim.stray_positions():
		out.append(Vector3(p.x, ground.height_at(p.x, p.y) if ground else 0.0, p.y))
	return out


## Sürünün ortası (dünya; zemine oturur).
func flock_center() -> Vector3:
	var c := sim.flock_center()
	return Vector3(c.x, ground.height_at(c.x, c.y) if ground else 0.0, c.y)


func count_through(a: Vector2, b: Vector2) -> void:
	sim.count_through(a, b)


## Sayımın sonu: kapıya en yakın sayılmamış koyunu sayar (gate_counted verir). Döner: dizin ya da −1.
func count_gate_one() -> int:
	var i := sim.count_gate_one()
	if i >= 0:
		gate_counted.emit(i, sim.gate_tally)
	return i


func water(line: PackedVector2Array, graze: Vector2, graze_radius: float, speed: float = 2.4, drink_s: float = 6.0) -> void:
	sim.water(line, graze, graze_radius, speed, drink_s)


func home_to_pen() -> void:
	sim.home_to_pen()


func settle_in_pen() -> void:
	sim.settle_in_pen()


func take_out(i: int) -> void:
	sim.take_out(i)


func put_back(i: int, at: Vector3) -> void:
	sim.put_back(i, Vector2(at.x, at.z))
	var y := ground.height_at(at.x, at.z) if ground else at.y
	_y0[i] = y
	_y1[i] = y
	_speed[i] = 0.0


## Koyunun boy çarpanı (kuzu küçüktür).
func sheep_size(i: int) -> float:
	return _size[i] if i >= 0 and i < _size.size() else 1.0


## Koyunun dünya konumu (o anki ara değer).
func sheep_position(i: int) -> Vector3:
	var alpha := _accum / HerdSim.TICK
	var p := _prev_arr()[i].lerp(_pos_arr()[i], alpha)
	return Vector3(p.x, lerpf(_y0[i], _y1[i], alpha), p.y)


## Kodla çizilen ağ yerine Meshy ağı mı görünüyor?
func uses_model() -> bool:
	return _uses_model


## Modeli dışarıdan verir (sınama, ağaca eklenmeden önce): yol verilirse türün yolu yerine o yüklenir.
func set_model_path(path: String) -> void:
	_model_path = path


## Ağın üçgen sayısı (bütçe sınaması).
func mesh_triangles() -> int:
	var mesh := _mm.mesh as ArrayMesh if _mm else null
	if mesh == null or mesh.get_surface_count() == 0:
		return 0
	var indices := mesh.surface_get_array_index_len(0)
	return (indices if indices > 0 else mesh.surface_get_array_len(0)) / 3


## Dizi ağırlıkları değişince (yerleştirme) görüntü hemen yazılır: ara değer ve yön sıfırlanır.
func snap() -> void:
	_accum = 0.0
	var pos_now := _pos_arr()
	for i in _n():
		var p := pos_now[i]
		var y := ground.height_at(p.x, p.y) if ground else 0.0
		_y0[i] = y
		_y1[i] = y
		_speed[i] = 0.0
		_graze[i] = _graze_target(i)
	if flock:
		flock.prev = flock.pos.duplicate()
		_seen_clock = flock.clock
	else:
		sim.prev = sim.pos.duplicate()
	_write(0.0, 0.0)


# --- Saf hesaplar --------------------------------------------------------------------------------------

## Adım boyu (metre): yürüyüşten tırısa doğrusal (fauna.md §10 yürüyüş tablosu).
static func stride_at(speed_mps: float, walk_speed: float, trot_speed: float, stride_walk: float, stride_trot: float) -> float:
	return lerpf(stride_walk, stride_trot, clampf((speed_mps - walk_speed) / maxf(trot_speed - walk_speed, 0.001), 0.0, 1.0))


## Salınım genliği (sin açısının katsayısı): ayak hızı sürüyü izlesin diye çeyrek adımın bacak boyuna oranı; dururken sıfıra iner.
static func swing_amplitude(speed_mps: float, stride: float, leg_length: float = LEG_LENGTH) -> float:
	return minf(stride * 0.25 / maxf(leg_length, 0.001), 0.85) * smoothstep(0.0, 0.25, speed_mps)


# --- Kurulum -------------------------------------------------------------------------------------------

func _alloc() -> void:
	var n := _n()
	_buffer.resize(n * FLOATS_PER_SHEEP)
	_y0.resize(n)
	_y1.resize(n)
	_yaw.resize(n)
	_speed.resize(n)
	_phase.resize(n)
	_graze.resize(n)
	_size.resize(n)
	_seed.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = n * 1009 + 7
	for i in n:
		_yaw[i] = rng.randf() * TAU
		_phase[i] = rng.randf()
		var lamb := rng.randf() < _young_share
		var span := _young_range if lamb else SCALE_RANGE
		_size[i] = rng.randf_range(span.x, span.y)
		_seed[i] = rng.randf()
		# Ayrılma elipsi koyunun boyuyla büyür: kuzu sokulur, iri koç yer kaplar.
		if flock:
			flock.body_scale[i] = _size[i]
		else:
			sim.body_scale[i] = _size[i]


func _build_instance(arrays: Dictionary) -> void:
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_custom_data = true
	var data := arrays if not arrays.is_empty() else FaunaMesh.arrays(kind_id)
	# Kodla çizimi olmayan tür (at, deve, sığır): Meshy'nin uzak ağı gelene dek boş ağ (sürü görünmez, yeri ve adımı yine işler).
	_mm.mesh = FaunaMesh.make_mesh(data) if not data.is_empty() else ArrayMesh.new()
	_mm.instance_count = _n()
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	instance = MultiMeshInstance3D.new()
	instance.name = "Sheep" if kind_id == "sheep" else kind_id.to_pascal_case()
	instance.multimesh = _mm
	instance.material_override = _material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	instance.custom_aabb = AABB(-CULL_HALF, CULL_HALF * 2.0)
	add_child(instance)


## Dışarıdan adımlanan sürü (FaunaDirector): saat ilerleyince tikin işi yapılır, ara değer o andan sayılır.
func _process_external(delta: float) -> void:
	if flock == null:
		return
	if flock.clock != _seen_clock:
		_seen_clock = flock.clock
		_after_step(flock.prev, flock.pos)
		_accum = 0.0
	else:
		_accum = minf(_accum + delta, HerdSim.TICK)
	if write_range > 0.0:
		var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
		if cam and (Vector2(cam.global_position.x, cam.global_position.z).distance_to(flock.center) > write_range \
				or not aabb_in_frustum(cam.get_frustum(), instance.custom_aabb)):
			# Görünmeyen sürü: tampon yazılmaz (kare başına iş yok); benzetim 4 Hz'de sürer.
			instance.visible = false
			return
		instance.visible = true
		if cam:
			# Kadrajın odağı: kameranın bakışının zemine değdiği yer (K98: eğim 15–60°, uzaklık 14–40 m); görüş ≤ ≈60 m.
			var fwd := -cam.global_basis.z
			var t := cam.global_position.y / maxf(-fwd.y, 0.2)
			var hit := cam.global_position + fwd * minf(t, 80.0)
			focus = Vector2(hit.x, hit.z)
			focus_radius = 75.0
	_write(_accum / HerdSim.TICK, delta)


## Kutu kameranın görüş hacminde mi (saf; Camera3D.get_frustum düzlemleri, normaller dışarı bakar)? Sekiz köşenin hepsi bir düzlemin
## dışındaysa görünmez.
static func aabb_in_frustum(planes: Array[Plane], box: AABB) -> bool:
	for pl in planes:
		var outside := true
		for k in 8:
			if not pl.is_point_over(box.get_endpoint(k)):
				outside = false
				break
		if outside:
			return false
	return true


## Bir tik: benzetim, varış noktalarının yüksekliği, olaylar.
func _tick() -> void:
	_update_avoid()
	sim.step()
	_after_step(sim.prev, sim.pos)
	_emit_events(sim.events)


## Tikten sonra: varış noktalarının yüksekliği.
func _after_step(before: PackedVector2Array, after: PackedVector2Array) -> void:
	for i in _n():
		_y0[i] = _y1[i]
		if before[i] != after[i] and ground:
			_y1[i] = ground.height_at(after[i].x, after[i].y)


func _emit_events(list: Array[Dictionary]) -> void:
	for ev: Dictionary in list:
		match ev["type"]:
			&"released":
				released.emit()
			&"settled":
				settled.emit()
			&"counted":
				sheep_counted.emit(int(ev["index"]), int(ev["tally"]))
			&"count_finished":
				count_finished.emit(int(ev["tally"]))
			&"strayed":
				strayed.emit(int(ev["index"]))
			&"stray_back":
				stray_back.emit(int(ev["index"]))
			&"arrived":
				arrived.emit()
			&"gate_counted":
				gate_counted.emit(int(ev["index"]), int(ev["tally"]))
			&"penned":
				penned.emit(int(ev["index"]), int(ev["tally"]))
			&"all_in":
				all_in.emit(int(ev["tally"]))


## Görüntü: her koyunun dönüşümü ve özel verisi tek tamponda, bir kerede.
func _write(alpha: float, delta: float) -> void:
	var prev := _prev_arr()
	var pos := _pos_arr()
	var facing := _facing_arr()
	var n := _n()
	var turn := 1.0 - exp(-TURN_SHARPNESS * delta) if delta > 0.0 else 1.0
	var speed_step := SPEED_RATE * delta
	var graze_step := GRAZE_RATE * delta
	var k := 0
	# Dışarıdan adımlanan sürüde kadrajın odağından uzak hayvanın hesabı atlanır (görünmez; tampondaki son yeri kalır, kadraja girince yazılır).
	var skip_far := external_tick and focus_radius > 0.0 and focus.is_finite()
	var far2 := focus_radius * focus_radius
	for i in n:
		var a: Vector2 = prev[i]
		var b: Vector2 = pos[i]
		if skip_far and b.distance_squared_to(focus) > far2:
			k += FLOATS_PER_SHEEP
			continue
		var dir := b - a
		var ds := dir.length_squared()
		var v := 0.0
		if ds > 0.00001:
			v = sqrt(ds) / HerdSim.TICK
		# Gövde benzetimin yönüne döner (HerdSim.facing): itişle yana kayan koyun dönmez, elipsi ayrılmayla aynı yöne bakar.
		var f: Vector2 = facing[i]
		_yaw[i] = lerp_angle(_yaw[i], atan2(f.x, f.y), turn)
		var sp := move_toward(_speed[i], v, speed_step)
		_speed[i] = sp
		var stride := stride_at(sp, _speed_walk, _speed_trot, _stride_walk, _stride_trot)
		var ph := _phase[i]
		if sp > 0.01:
			ph = fposmod(ph + sp / stride * delta, 1.0)
			_phase[i] = ph
		var gz := move_toward(_graze[i], _graze_target(i), graze_step)
		_graze[i] = gz
		var yaw := _yaw[i]
		var s := _size[i]
		if sim and sim.hidden[i] == 1:
			# E21: benzetimden çıkarılan koyun (balçıktaki kuzu) çizilmez.
			s = 0.0
		var cs := cos(yaw) * s
		var sn := sin(yaw) * s
		var x := a.x + dir.x * alpha
		var z := a.y + dir.y * alpha
		var y0 := _y0[i]
		_buffer[k] = cs
		_buffer[k + 1] = 0.0
		_buffer[k + 2] = sn
		_buffer[k + 3] = x
		_buffer[k + 4] = 0.0
		_buffer[k + 5] = s
		_buffer[k + 6] = 0.0
		_buffer[k + 7] = y0 + (_y1[i] - y0) * alpha
		_buffer[k + 8] = -sn
		_buffer[k + 9] = 0.0
		_buffer[k + 10] = cs
		_buffer[k + 11] = z
		_buffer[k + 12] = ph
		_buffer[k + 13] = swing_amplitude(sp, stride)
		_buffer[k + 14] = gz
		_buffer[k + 15] = _seed[i]
		k += FLOATS_PER_SHEEP
	_mm.buffer = _buffer


func _update_avoid() -> void:
	if sim and not _driver_nodes.is_empty():
		var list: Array[Vector3] = []
		for k in _driver_nodes.size():
			var node := _driver_nodes[k]
			if is_instance_valid(node) and node.is_inside_tree() and node.visible:
				list.append(Vector3(node.global_position.x, node.global_position.z, _driver_radii[k]))
		sim.drivers = list
	if sim and is_instance_valid(_leader_node) and _leader_node.is_inside_tree():
		sim.leader = Vector2(_leader_node.global_position.x, _leader_node.global_position.z)
	if _avoid_nodes.is_empty() or sim == null:
		return
	var list: Array[Vector3] = []
	for node in _avoid_nodes:
		if is_instance_valid(node) and node.is_inside_tree():
			list.append(Vector3(node.global_position.x, node.global_position.z, AVOID_RADIUS))
	sim.avoid = list


# --- Sürünün yüzü (HerdSim ya da PastureFlock) ------------------------------------------------------------------

func _n() -> int:
	return flock.count if flock else (sim.count if sim else 0)


func _prev_arr() -> PackedVector2Array:
	return flock.prev if flock else sim.prev


func _pos_arr() -> PackedVector2Array:
	return flock.pos if flock else sim.pos


func _facing_arr() -> PackedVector2Array:
	return flock.facing if flock else sim.facing


func _graze_target(i: int) -> float:
	return flock.grazing[i] if flock else float(sim.grazing[i])


## Türün görünüşü (kinds.json «herd»: don çeşitleri, yün beneği, otlama açısı; kodla çizilen türün eklemleri).
func _apply_look() -> void:
	if kind == null or _material == null:
		return
	for key: String in FaunaMesh.herd_params(kind_id):
		_material.set_shader_parameter(key, FaunaMesh.herd_params(kind_id)[key])
	var look := kind.herd_look()
	if look.has("graze"):
		_material.set_shader_parameter(&"graze_angle", float(look["graze"]))
	var tints: Dictionary = look.get("tints", {})
	if not tints.is_empty():
		_material.set_shader_parameter(&"wool_warm", Color(str(tints.get("warm", "#fff8e6"))))
		_material.set_shader_parameter(&"wool_cool", Color(str(tints.get("cool", "#f2f2f0"))))
		_material.set_shader_parameter(&"wool_dark", Color(str(tints.get("dark", "#6b5f59"))))
		_material.set_shader_parameter(&"dark_share", float(tints.get("dark_share", 0.05)))
		_material.set_shader_parameter(&"curl_strength", float(tints.get("curl", 0.14)))
		_material.set_shader_parameter(&"dark_all", float(tints.get("dark_all", 0.0)))
	if kind_id != "sheep":
		# Boynuz (koç) yalnız koyunda; öteki türde gizli kalsın.
		_material.set_shader_parameter(&"ram_share", 0.0)


# --- Meshy ağı --------------------------------------------------------------------------------------------

## Model dosyası varsa arka planda istenir (kodla çizilen ağ görünür kalır).
func _request_model() -> void:
	var path := _model_path if not _model_path.is_empty() else (kind.herd_model_path() if kind else "")
	if path.is_empty() or not MeshyProp.models_enabled or not ResourceLoader.exists(path):
		return
	_model_path = path
	# Başsızda eşzamanlı (FaunaMesh.background_loads: boş çizicinin kimlikleri iş parçacığına karşı korunmuyor); ağın çevrilmesi yine
	# iş parçacığındadır, model_ready sonraki karelerde yayılır.
	if not FaunaMesh.background_loads():
		_start_model_job(load(path) as PackedScene)
		return
	# Alt iş parçacıksız: use_sub_threads (4.7.2) alındıktan sonra da yükleyicide bir RefCounted bırakır (çıkışta ObjectDB sızıntısı).
	if ResourceLoader.load_threaded_request(path, "", false) == OK:
		_model_state = 1


func _poll_model() -> void:
	match _model_state:
		1:
			var status := ResourceLoader.load_threaded_get_status(_model_path)
			if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				return
			if status != ResourceLoader.THREAD_LOAD_LOADED:
				push_warning("[herd] model yüklenemedi: %s" % _model_path)
				_model_state = 0
				return
			_start_model_job(ResourceLoader.load_threaded_get(_model_path) as PackedScene)
		3:
			# Ağaçtan çıkarken alınmış model (bkz. _exit_tree).
			var scene := _model_scene
			_model_scene = null
			_start_model_job(scene)
		2:
			if not WorkerThreadPool.is_task_completed(_model_job.task_id):
				return
			WorkerThreadPool.wait_for_task_completion(_model_job.task_id)
			_model_job.waited = true
			_adopt_model(_model_job.result)
			_model_job = null
			_model_state = 0


## Modelin ilk ağını ve dokusunu alır; köşe verisini iş parçacığına verir.
func _start_model_job(scene: PackedScene) -> void:
	_model_state = 0
	if scene == null:
		return
	var root := scene.instantiate()
	var found: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D:
		found.push_front(root)
	var mesh_instance := found[0] as MeshInstance3D if not found.is_empty() else null
	if mesh_instance == null or mesh_instance.mesh == null:
		push_warning("[herd] modelde ağ yok: %s" % _model_path)
		root.free()
		return
	_model_job = _ModelJob.new()
	_model_job.surface = mesh_instance.mesh.surface_get_arrays(0)
	_model_job.image = FaunaMesh.model_image(mesh_instance.mesh)
	_model_job.length = kind.model_length() * kind.model_scale() if kind else 1.264
	_model_job.max_triangles = kind.max_triangles() if kind else 1800
	_model_job.ratios = kind.herd_look() if kind else {}
	root.free()
	_model_job.task_id = WorkerThreadPool.add_task(_model_job.run, true, "herd model")
	_model_state = 2


func _adopt_model(data: Dictionary) -> void:
	if data.is_empty():
		push_warning("[herd] model ağı okunamadı: %s" % _model_path)
		return
	_mm.mesh = FaunaMesh.make_mesh(data)
	_material.set_shader_parameter(&"hip_height", float(data["hip"]))
	_material.set_shader_parameter(&"neck_pivot", data["neck"])
	_material.set_shader_parameter(&"tail_pivot", data["tail"])
	_uses_model = true
	model_ready.emit()
