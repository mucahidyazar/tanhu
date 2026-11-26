class_name ChildhoodSite
extends Node3D
## Çocukluk'un oynanış yerleri (story.md §5; Yol Haritası childhood-world, childhood-herd; K98: kadraj 38°, 36°, 22–40 m, yakın plan yok): childhood_ordos dünyasına ayrı bir düğüm
## (OrdosWorld/Childhood). Önsöz'ün doğumu görmez: dünya kurulurken bu düğüm yoktur, OrdosWorld.prepare_childhood ya da set_childhood_mode(true) ile arka planda kurulur,
## set_childhood_mode(false) gizler. Düzen layout.json "childhood"tadır. 40 m kadrajda yurt, ağıl, yarış yolu, taş ve sayım hattı aynı karededir.
## Bozkırın kendisi (yükselti, maskeli zemin, kaya, çalı, çakıl, ot; "childhood.ground", "childhood.scatter") doğumda da görünür: dünya onu kendi Ground'unda kurar (aynı
## yükselti, aynı kaya ve çalı; doğumun maskesinde Çocukluk'un izleri yoktur). Bu düğüm Çocukluk'a özgü olanları ve Çocukluk'un zeminini taşır.
##
## Düğümler:
##   Terrain     Çocukluk'un zemini (Ground/Terrain'in yerine görünür): kendi yüzüyle (ground: kademe, tepe, kuru dere; ChildhoodGround) ve maskeli gölgelendiriciyle
##   Trampled    doğumun çiğnenmiş toprağı + ağıl, izler, yarış yolu (Ground/Trampled'ın yerine görünür)
##   Grass       çayırı da kaplayan ot (Ground/Grass'ın yerine görünür; ağılda, izde ve kısa otlu lekelerde yok; maskeye uyar)
##   Rocks       kaya öbekleri, kademe taşları (ChildhoodScatter; biçim başına bir MultiMesh)
##   Shrubs      pelin ve karagan (tür başına bir MultiMesh)
##   Pen         ağıl: Fence (kazıklar, ot, yalak), Wattle (örgü, wattle.gdshader) ve Gate (kapı kanadı; set_gate_open)
##   Stone       yarışın taşı
##   Marks       yarış yolunun taş yığınları ve sayım hattının bezleri (uzaktan okunsun)
##   Props       kampın eşyaları (CampProp: kazan, odun, heybe, sergi, mızrak sergisi, kova; Meshy modelleri arka planda yüklenir)
##   Herd        HerdField: 40 koyun, tek MultiMeshInstance3D
##   SmallGame   SmallGameField: kuş, keklik, karga, tarbagan, kum faresi ("targets" grubunda)
##   Crowd       CrowdCards: Dailin'in kalabalığı, kart kademesi (T3; "childhood.crowd", CrowdPlan): sayım hattının çevresinde, uzakta; oyunun
##               dakikasıyla toplanır (set_minute), atlılar geçerken onlara döner (watch_crowd)
##
## Yüz: ground, herd, game, solid_rocks, gate_is_open(), set_gate_open(açık, anında), gate_changed(açık), release_herd() (kapı açılır, sürü çıkar), drive_herd() (sayım),
## reset_herd() (anında ağıla), skip_herd_to_meadow() (anında çayıra), crowd, set_minute(dakika) (kalabalık saatle toplanır), watch_crowd(nokta). Çarpışma OrdosWorld.collect_obstacles, collect_walls, collect_boxes'tadır (duvar ağılın
## RingWall'u, kapalı kapı kutu). Oyuncu ve binekler sürüye çarpmaz, sürü yol verir: site.herd.set_avoid_nodes([oyuncu, binekler...]).
##
## Yükleme (godot.md §4.3): ağır üretim (çiğnenmiş toprak, ot, çit, kaya, çalı, hayvan ağları) WorkerThreadPool'da, ana iş parçacığındaki kurulum kare başına
## frame_budget_ms (4 ms) dilimlerle; yükselti, maske ve arazinin ağı dünyanın bozkırıyla aynıdır, ondan alınır. is_ready() bitince true olur, built yayılır.

signal built
## Kapı açıldı ya da kapandı: oyuncunun kutuları yenilensin (player.refresh_obstacles; OrdosWorld.collect_boxes).
signal gate_changed(open: bool)

const WATTLE_SHADER := preload("res://shaders/wattle.gdshader")
const ROCK_SHADER := preload("res://shaders/atw_rock.gdshader")
const SHRUB_SHADER := preload("res://shaders/steppe_shrub.gdshader")
const GROUND_SHADER := preload("res://assets/maps/ordos/childhood_ground.gdshader")
## Çitin renkleri.
const POST_COLOR := Color(0.26, 0.19, 0.13, 0.0)
const FRAME_COLOR := Color(0.33, 0.24, 0.16, 0.0)
const HAY_COLOR := Color(0.66, 0.54, 0.31, 1.0)
const CAIRN_COLOR := Color(0.6, 0.56, 0.5, 0.0)
const FLAG_COLORS: Array[Color] = [Color(0.66, 0.18, 0.12, 0.0), Color(0.82, 0.66, 0.32, 0.0)]
## Dikili taşın boyası (atw_rock; RockField'ın gri kayasının bozkır tonu).
const STONE_PARAMS := {
	"rock_color": Color(0.5, 0.47, 0.42), "blotch_color": Color(0.54, 0.51, 0.45), "speck_color": Color(0.3, 0.28, 0.25),
	"moss_color": Color(0.46, 0.43, 0.22), "moss_light": Color(0.56, 0.52, 0.3), "moss_amount": 0.16, "shadow_level": 0.6, "blotch_amount": 0.26,
}
## Kapı kanadının açılışı (derece) ve süresi (saniye).
const GATE_OPEN_DEG := 105.0
const GATE_SECONDS := 0.9
## Kapı kanadının yerden yüksekliği (metre).
const GATE_CLEARANCE := 0.12
## Yerel otun ve çiğnenmiş toprağın kendi işleri (OrdosWorld._Job ile aynı biçim).
const PER_STEP := 12
## Sayım kazıklarının çarpışma yarıçapı (metre).
const STAKE_RADIUS := 0.12

@export var frame_budget_ms := 4.0

var world: OrdosWorld
var layout: Dictionary = {}
var def: Dictionary = {}
## Çocukluk'un yüzü: kademe, tepe ve dereyle (bake bitene dek null).
var ground: OrdosGround
var herd: HerdField
var game: SmallGameField
## Dailin'in kalabalığı (kart kademesi; kurulunca).
var crowd: CrowdCards
## E21 (K110): Kamışlı Göl'ün kıyısı (sazlık, balçık, ak taş, ördekler, halkalar, sayım taşları) ve uzak yerler (Ebe Obası, bağlama direği,
## Dailin'in dumanları, uzak atlılar, turnalar); kurulunca.
var lake: ChildhoodLake
var reaches: ChildhoodReaches
## Büyük kayaların çarpışma daireleri Vector3(x, z, yarıçap).
var solid_rocks: Array[Vector3] = []
## Dağıtım sayıları (kaya, çalı).
var scatter_counts: Dictionary = {}
## Kurulum ölçüleri (OrdosWorld.build_stats gibi).
var build_stats := {"frames": 0, "max_frame_ms": 0.0, "main_ms": 0.0, "ready_ms": 0.0, "jobs_ms": {}, "steps": {}}

var _jobs: Array[_Job] = []
var _steps: Array[Callable] = []
var _ready_flag := false
var _started_us := 0
var _gate: Node3D
var _gate_open := false
var _gate_tween: Tween
var _gate_closed_yaw := 0.0
var _gate_open_yaw := 0.0
var _fauna_arrays: Dictionary = {}
var _spec: Dictionary = {}
var _mask: Dictionary = {}
var _rock_material: ShaderMaterial
var _prop_loads: PackedStringArray = []
var _props_queued := false
var _crowd_meta: Dictionary = {}
var _crowd_loads: PackedStringArray = []
var _crowd_textures: Array[Texture2D] = []
var _crowd_job: _Job
var _minute := 520.0
var _watch := Vector3.INF
var _lake_arrays: Dictionary = {}
## Dailin toplandı mı (sayım günü; set_dailin_gathered).
var _dailin_gathered := true
## E21: gece yurtların kapısından sızan ışığın zemindeki havuzları (sahte; set_minute yakar).
var door_pools: MultiMeshInstance3D
var _door_pool_mat: ShaderMaterial
var _door_pool_k := -1.0
## Başsızda eşzamanlı yüklenecek kalabalık dokuları (FaunaMesh.background_loads) ve yüklenenler (sırayla, birer adımda).
var _crowd_sync := PackedStringArray()
var _crowd_sync_tex: Array[Texture2D] = []
## E21: Çocukluk'un pişirdiği ızgara (geniş: ground.area_e21).
var _bake_grid: Dictionary = {}


## İş parçacığında koşan üretim: fn sonuç sözlüğünü döner.
class _Job:
	extends RefCounted
	var kind := ""
	var band := 0
	var fn: Callable
	var result: Dictionary = {}
	var task_id := -1
	var waited := false
	var applied := false
	var ms := 0.0

	func run() -> void:
		var started := Time.get_ticks_usec()
		result = fn.call()
		ms = (Time.get_ticks_usec() - started) / 1000.0


## Kurulumu başlatır: düğüm ağaçtadır, dünya hazırdır. Yükselti, Çocukluk'un maskesi ve arazinin ağı dünyanın bozkırından gelir (yoksa önce
## yükselti ve maske pişer, arazi kendi işinde kurulur); ona bağlı işler hemen başlar.
func start(p_world: OrdosWorld) -> void:
	world = p_world
	layout = world.layout
	def = layout.get("childhood", {})
	_started_us = Time.get_ticks_usec()
	# İşlerin kullandığı sınıflar ana iş parçacığında yüklensin.
	Meadow.tuft_aspect(0.2)
	Scatter.is_blocked(0.0, 0.0, [], 0.0)
	FaunaMesh.Draft.new()
	var wide := ((def.get("ground", {}) as Dictionary).has("area_e21"))
	if not world.baked.is_empty() and not wide:
		# Dünya yükseltiyi ve Çocukluk'un maskesini bozkırıyla birlikte pişirdi (aynı otlak, aynı sonuç): yeniden pişirilmez.
		_start_detail_jobs(world.baked)
	else:
		# E21 (K110): Çocukluk'un yükseltisi ve maskesi göle ve Ebe Obası'na dek (ground.area_e21) kendi satır bantlarında pişer; doğumunki
		# kampın ızgarasıdır (OrdosWorld). Kampın içinde ikisi aynıdır (aynı hücreler, aynı biçim).
		_bake_grid = ChildhoodGround.grid(layout, wide)
		var k := 0
		for band in ChildhoodGround.row_bands(_bake_grid, OrdosWorld.JOB_BANDS):
			var spec := layout.duplicate(true)
			_start_job("bake", func() -> Dictionary: return ChildhoodGround.bake_rows(spec, band.x, band.y, false, wide), k)
			k += 1
	_start_crowd()
	# Eşyaların modelleri arka planda gelsin: örnekleme önbellekten, kare bütçesinde. Başsızda istek açılmaz (godot.md §4.5,
	# FaunaMesh.background_loads: boş çizicinin ağ ve doku kimlikleri iş parçacığına karşı korunmuyor; «Parameter "t" is null»): eşya
	# kurulurken eşzamanlı yüklenir. İşlerin kendisi (WorkerThreadPool) yalnız dizi hesaplar, kimlik kurmaz.
	var requested: Array = (def.get("props", {}) as Dictionary).get("items", []) if FaunaMesh.background_loads() else []
	for item: Dictionary in requested:
		var path := _prop_model_path(str(item.get("kind", "")))
		if not path.is_empty() and ResourceLoader.exists(path) and not _prop_loads.has(path):
			# Alt iş parçacıksız: use_sub_threads (4.7.2) alındıktan sonra da yükleyicide bir RefCounted bırakır (çıkışta ObjectDB sızıntısı).
			if ResourceLoader.load_threaded_request(path, "", false) == OK:
				_prop_loads.append(path)
	set_process(true)


## Pişen yükselti ve maskeyle düzen: Çocukluk'un yüzünün tanımı. İşler bunu yalnız okur (paylaşılır, kopyalanmaz).
static func baked_spec(p_layout: Dictionary, baked: Dictionary) -> Dictionary:
	var spec := merged_spec(p_layout)
	if not baked.is_empty():
		spec["ground_relief"] = baked["relief"]
		spec["ground_mask"] = baked["mask"]
	return spec


func _start_detail_jobs(baked: Dictionary) -> void:
	_spec = baked_spec(layout, baked)
	_mask = baked.get("mask", {})
	ground = OrdosGround.new(_spec)
	var spec := _spec
	# Arazinin ağı bozkırınkiyle aynıdır (aynı yükselti ve düz yerler; çiğnenmiş toprak yüksekliği değiştirmez): dünyanın ağı paylaşılır,
	# yalnız malzeme (Çocukluk'un maskesi) ayrıdır.
	# E21 (K110): Çocukluk'un ağı göle ve Ebe Obası'na dek sık ızgaradır (childhood.ground.dense): kendi bantlarında kurulur, her bant kendi
	# ağıdır (kare başına bir parça; dikiş yok).
	var steppe_terrain := world.get_node_or_null(^"Ground/Terrain") as MeshInstance3D
	if steppe_terrain and steppe_terrain.mesh and world.steppe and not ground.dense_min.is_finite():
		_steps.push_back(_add_terrain.bind(steppe_terrain.mesh))
	else:
		var rows := ground.row_count()
		for k in OrdosWorld.JOB_BANDS:
			var a := rows * k / OrdosWorld.JOB_BANDS
			var b := rows * (k + 1) / OrdosWorld.JOB_BANDS
			if b > a:
				_start_job("terrain", func() -> Dictionary: return OrdosGround.new(spec).build_chunk(a, b), k)
	_start_job("trampled", func() -> Dictionary: return OrdosGround.new(spec).build_overlay_arrays(OrdosWorld.TRAMPLED_LIFT))
	var grass_spec := spec.duplicate()
	grass_spec["grass"] = def.get("grass", {})
	var blockers := grass_blockers(layout)
	_start_job("grass", func() -> Dictionary: return OrdosWorld.grass_buffers(grass_spec, blockers))
	# E21: otun ek daireleri (göle ve obaya giden yollar, göl, oba): her daire kendi tohumuyla, öncekilerin içine ot koymaz.
	var zones: Array = (def.get("grass_zones", {}) as Dictionary).get("zones", [])
	if not zones.is_empty():
		var zone_spec := spec.duplicate()
		var base_grass: Dictionary = def.get("grass", {})
		_start_job("grass_e21", func() -> Dictionary: return ChildhoodSite.zone_grass(zone_spec, base_grass, zones, blockers))
	_start_job("pen", func() -> Dictionary: return pen_arrays(spec))
	_start_job("scatter", func() -> Dictionary: return ChildhoodScatter.build(spec))
	var fauna_def := def
	_start_job("fauna", func() -> Dictionary: return fauna_arrays(fauna_def))
	# E21: Kamışlı Göl'ün kıyısının ağır dizileri (sazlık, balçık, kıyının dalgası).
	if def.has("lake_site"):
		var lake_spec := spec
		_start_job("lake", func() -> Dictionary: return ChildhoodLake.compute(lake_spec))


func _exit_tree() -> void:
	for job in _jobs:
		if job.task_id >= 0 and not job.waited:
			WorkerThreadPool.wait_for_task_completion(job.task_id)
			job.waited = true
	# Alınmamış arka plan yüklemesi yükleyicide öksüz kalır (çıkışta ObjectDB sızıntısı): bitmesi beklenip alınır.
	for path in _prop_loads:
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS or status == ResourceLoader.THREAD_LOAD_LOADED:
			ResourceLoader.load_threaded_get(path)
	_prop_loads.clear()
	for path in _crowd_loads:
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS or status == ResourceLoader.THREAD_LOAD_LOADED:
			ResourceLoader.load_threaded_get(path)
	_crowd_loads.clear()


func _process(_delta: float) -> void:
	if _ready_flag:
		set_process(false)
		return
	var started := Time.get_ticks_usec()
	_poll_jobs()
	while not _steps.is_empty():
		var step: Callable = _steps.pop_front()
		var step_started := Time.get_ticks_usec()
		step.call()
		var step_ms := (Time.get_ticks_usec() - step_started) / 1000.0
		var steps: Dictionary = build_stats["steps"]
		steps[step.get_method()] = maxf(float(steps.get(step.get_method(), 0.0)), step_ms)
		if (Time.get_ticks_usec() - started) / 1000.0 >= frame_budget_ms:
			break
	var ms := (Time.get_ticks_usec() - started) / 1000.0
	build_stats["frames"] = int(build_stats["frames"]) + 1
	build_stats["main_ms"] = float(build_stats["main_ms"]) + ms
	build_stats["max_frame_ms"] = maxf(float(build_stats["max_frame_ms"]), ms)
	if _steps.is_empty() and _jobs_done():
		_ready_flag = true
		build_stats["ready_ms"] = (Time.get_ticks_usec() - _started_us) / 1000.0
		set_process(false)
		built.emit()


func is_ready() -> bool:
	return _ready_flag


# --- Yüz ---------------------------------------------------------------------------------------------

func gate_is_open() -> bool:
	return _gate_open


## Kapının kanadı: açılır, kapanır; çarpışma hemen değişir.
func set_gate_open(open: bool, instant: bool = false) -> void:
	var changed := open != _gate_open
	_gate_open = open
	if herd and herd.sim:
		herd.sim.gate_open = open
	if changed:
		gate_changed.emit(open)
	if _gate == null:
		return
	if _gate_tween:
		_gate_tween.kill()
		_gate_tween = null
	var yaw := _gate_open_yaw if open else _gate_closed_yaw
	if instant or not is_inside_tree():
		_gate.rotation.y = yaw
		return
	_gate_tween = create_tween()
	_gate_tween.tween_property(_gate, "rotation:y", yaw, GATE_SECONDS).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Lan Hatun'un sözü: kapı açılır, koyunlar sırayla çıkıp çayıra yayılır (HerdField.released, settled). hold: kapıdan en uzaktaki o kadar
## koyun ağılda kalır, çocuk arkalarından yürüyünce çıkar (HerdSim.release; «Koyunları ağıldan sen çıkaracaksın.»).
func release_herd(hold: int = 0) -> void:
	set_gate_open(true)
	herd.release(null, -1.0, hold)


## Sürü sayım hattından geçer (HerdField.sheep_counted, count_finished).
func drive_herd() -> void:
	set_gate_open(true)
	herd.drive_through_line()


## Sürüyü anında ağıla koyar, kapıyı kapatır.
func reset_herd() -> void:
	herd.place_in_pen()
	set_gate_open(false, true)


## Sürüyü anında çayıra koyar, kapı açık kalır (atlanan adım).
func skip_herd_to_meadow() -> void:
	set_gate_open(true, true)
	herd.place_on_meadow()


## Oyunun dakikası (OrdosWorld.set_childhood_time, set_crowd_minute): kalabalık bu saate göre toplanır.
func set_minute(minute: float) -> void:
	_minute = minute
	if crowd:
		crowd.set_minute(minute)
	if reaches:
		reaches.set_minute(minute)
	_update_door_pools(minute)


## E21 (K110): gecenin kapı ışığı: kampın yurtlarının kapısının önünde zemine düşen turuncu havuz (toplamalı kart, kapı doğrultusunda uzun;
## gerçek ışık yok: Lan Hatun'un yurdunun kendi ışığı DoorSpill'dir, OrdosWorld yakar). Gün batımından sonra belirir (ChildhoodReaches.night_of).
const DOOR_POOL_SHADER := "shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform vec3 tint : source_color = vec3(1.0, 0.55, 0.24);
uniform float energy = 0.0;
varying float vid;
void vertex() {
	vid = float(INSTANCE_ID);
}
void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float r = length(q);
	float flicker = 0.9 + 0.1 * sin(TIME * 7.0 + vid * 1.9) * sin(TIME * 3.1 + vid);
	ALBEDO = tint * energy * flicker * pow(max(1.0 - r, 0.0), 1.7);
}"


func _build_door_pools() -> void:
	var places: Dictionary = layout.get("places", {})
	var spots: Array[Transform3D] = []
	for id: String in places:
		var place: Dictionary = places[id]
		if not str(place.get("kind", "yurt")) in ["yurt", "birth_yurt"]:
			continue
		var at := OrdosGround._vec2(place.get("at", [0.0, 0.0]))
		var r := float(place.get("radius", 3.0))
		var dir := HerdSim.azimuth_vector(float(place.get("door_az", 90.0)))
		var c := at + dir * (r + 1.9)
		var side := Vector2(-dir.y, dir.x)
		var basis := Basis(Vector3(side.x, 0.0, side.y) * 3.4, Vector3.UP, Vector3(dir.x, 0.0, dir.y) * 4.8)
		spots.append(Transform3D(basis, Vector3(c.x, ground.height_at(c.x, c.y) + 0.06, c.y)))
	if spots.is_empty():
		return
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	quad.orientation = PlaneMesh.FACE_Y
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = quad
	mm.instance_count = spots.size()
	for i in spots.size():
		mm.set_instance_transform(i, spots[i])
	_door_pool_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = DOOR_POOL_SHADER
	_door_pool_mat.shader = sh
	door_pools = MultiMeshInstance3D.new()
	door_pools.name = "DoorPools"
	door_pools.multimesh = mm
	door_pools.material_override = _door_pool_mat
	door_pools.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	door_pools.visible = false
	add_child(door_pools)
	_update_door_pools(_minute)


func _update_door_pools(minute: float) -> void:
	if door_pools == null:
		return
	var k := ChildhoodReaches.night_of(minute)
	if absf(k - _door_pool_k) < 0.01:
		return
	_door_pool_k = k
	door_pools.visible = k > 0.01
	_door_pool_mat.set_shader_parameter(&"energy", 0.8 * k)


## Dailin toplandı mı (E21, K110): sayım günü (22 Eylül) kalabalık ve sayım hattının bayrakları görünür; önceki günlerde (20–21 Eylül)
## yoktur, ufukta yalnız Dailin'in dumanları ve gece ateşleri görünür (ChildhoodReaches). ChildhoodScene gün başında yazar.
func set_dailin_gathered(on: bool) -> void:
	_dailin_gathered = on
	if crowd:
		crowd.visible = on
		crowd.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	var flags := get_node_or_null(^"Marks/Flags") as Node3D
	if flags:
		flags.visible = on


func is_dailin_gathered() -> bool:
	return _dailin_gathered


## Kalabalığın bakacağı nokta (Teoman'ın atlıları); Vector3.INF kendi hâline bırakır.
func watch_crowd(point: Vector3) -> void:
	_watch = point
	if crowd:
		crowd.watch(point)


# --- Saf hesaplar (tests/unit/test_childhood_site.gd) ---------------------------------------------------

## Doğumun düzeni + Çocukluk'un düz yerleri, çiğnenmiş toprağı ve izleri (saf): "paths" ve "race" parçalara bölünür.
static func merged_spec(p_layout: Dictionary) -> Dictionary:
	var spec := p_layout.duplicate(true)
	var d: Dictionary = p_layout.get("childhood", {})
	var extra: Dictionary = d.get("trampled", {})
	var trampled: Dictionary = spec.get("trampled", {})
	var circles: Array = (trampled.get("circles", []) as Array).duplicate(true)
	circles.append_array(extra.get("circles", []))
	var trails: Array = (trampled.get("trails", []) as Array).duplicate(true)
	var lines: Array = []
	var paths: Dictionary = d.get("paths", {})
	for id: String in paths:
		if paths[id] is Dictionary:
			lines.append(paths[id])
	var race: Dictionary = d.get("race", {})
	if not race.is_empty():
		lines.append({"points": race.get("path", []), "width": race.get("width", 1.3)})
	for line: Dictionary in lines:
		var points: Array = line.get("points", [])
		for i in range(1, points.size()):
			trails.append([points[i - 1][0], points[i - 1][1], points[i][0], points[i][1], line.get("width", 1.3)])
	trampled["circles"] = circles
	trampled["trails"] = trails
	spec["trampled"] = trampled
	var flats: Array = (spec.get("flats", []) as Array).duplicate(true)
	flats.append_array(d.get("flats", []))
	spec["flats"] = flats
	# E21 (K110): Kamışlı Göl ve ağın geniş sık ızgarası Çocukluk'un yüzündedir (doğumun bozkırında yok: OrdosWorld.steppe_spec çıkarır).
	if d.has("lake"):
		spec["lake"] = (d["lake"] as Dictionary).duplicate(true)
	var child_ground: Dictionary = d.get("ground", {})
	if child_ground.has("dense"):
		var g: Dictionary = spec.get("ground", {})
		g["dense"] = (child_ground["dense"] as Dictionary).duplicate(true)
		g["grid_normals"] = true
		spec["ground"] = g
	return spec


## Otun engelleri (saf): yurtlar, ağılın dış yüzü, taş, küçük avın kısa otlu lekeleri ve inler.
static func grass_blockers(p_layout: Dictionary) -> Array[Vector3]:
	var out := OrdosWorld.grass_blockers(p_layout)
	var d: Dictionary = p_layout.get("childhood", {})
	var pen: Dictionary = d.get("pen", {})
	if not pen.is_empty():
		var at := OrdosGround._vec2(pen.get("at", [0.0, 0.0]))
		out.append(Vector3(at.x, at.y, float(pen.get("radius", 8.0)) + 0.35))
	var stone: Dictionary = d.get("stone", {})
	if not stone.is_empty():
		var at := OrdosGround._vec2(stone.get("at", [0.0, 0.0]))
		out.append(Vector3(at.x, at.y, float(stone.get("radius", 0.7)) + 0.3))
	for group: Dictionary in (d.get("game", {}) as Dictionary).get("groups", []):
		for p: Array in group.get("patches", []):
			out.append(Vector3(float(p[0]), float(p[1]), float(p[2])))
		for h: Array in group.get("holes", []):
			out.append(Vector3(float(h[0]), float(h[1]), maxf(float(group.get("mound", 0.2)) * 1.3, 0.3)))
	return out


## Çarpışma daireleri (saf; x, z, yarıçap): yurtlar (kapılı doğum yurdu hariç: onun duvarı walls'tadır; içinde ocak), taş, ağılın eşyaları,
## sayım kazıkları.
static func collision_circles(p_layout: Dictionary, include_birth_yurt: bool = false) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var places: Dictionary = p_layout.get("places", {})
	for id: String in places:
		var place: Dictionary = places[id]
		var at := OrdosGround._vec2(place.get("at", [0.0, 0.0]))
		if str(place.get("kind", "yurt")) == "birth_yurt" and not include_birth_yurt:
			out.append(Vector3(at.x, at.y, 0.62))
		else:
			out.append(Vector3(at.x, at.y, float(place.get("radius", 3.0)) + 0.25))
	var d: Dictionary = p_layout.get("childhood", {})
	var stone: Dictionary = d.get("stone", {})
	if not stone.is_empty():
		var at := OrdosGround._vec2(stone.get("at", [0.0, 0.0]))
		out.append(Vector3(at.x, at.y, float(stone.get("radius", 0.7))))
	for prop: Dictionary in (d.get("pen", {}) as Dictionary).get("props", []):
		var at := OrdosGround._vec2(prop.get("at", [0.0, 0.0]))
		out.append(Vector3(at.x, at.y, float(prop.get("radius", 0.6))))
	var line: Dictionary = p_layout.get("counting_line", {})
	if not line.is_empty():
		var a := OrdosGround._vec2(line.get("from", [0.0, 0.0]))
		var b := OrdosGround._vec2(line.get("to", [0.0, 1.0]))
		var n := maxi(int(line.get("stakes", 11)), 2)
		for i in n:
			var q := a.lerp(b, float(i) / float(n - 1))
			out.append(Vector3(q.x, q.y, STAKE_RADIUS))
	# E21: Ebe Obası'nın kapalı yurtları, sayım taşları, bağlama direği.
	out.append_array(ChildhoodReaches.ebe_circles(p_layout))
	var stones: Dictionary = (d.get("lake_site", {}) as Dictionary).get("count_stones", {})
	for key in ["a", "b"]:
		if stones.has(key):
			var at := OrdosGround._vec2(stones[key])
			out.append(Vector3(at.x, at.y, 0.42))
	var post: Dictionary = (d.get("far", {}) as Dictionary).get("post", {})
	if not post.is_empty():
		var at := OrdosGround._vec2(post.get("at", [0.0, 0.0]))
		out.append(Vector3(at.x, at.y, 0.12))
	return out


## Duvarlar (saf): doğum yurdu (kapı aralığından girilir) ve ağıl.
static func collision_walls(p_layout: Dictionary) -> Array[RingWall]:
	var out: Array[RingWall] = []
	var places: Dictionary = p_layout.get("places", {})
	for id: String in places:
		var place: Dictionary = places[id]
		if str(place.get("kind", "yurt")) == "birth_yurt":
			var at := OrdosGround._vec2(place.get("at", [0.0, 0.0]))
			var r := float(place.get("radius", 3.1))
			var door := HerdSim.azimuth_vector(float(place.get("door_az", 90.0)))
			# Duvar keçe ile astar arasındadır (astar r × 0,76, keçe r × 0,93); kapı aralığı modelin kapısı.
			out.append(RingWall.new(at, r * 0.85, door, 0.42, r * 0.17))
	var pen: Dictionary = (p_layout.get("childhood", {}) as Dictionary).get("pen", {})
	if not pen.is_empty():
		out.append(HerdSim.pen_wall(pen))
	# E21: Hereka'nın açık yurdu (kapı aralığından girilir).
	out.append_array(ChildhoodReaches.ebe_walls(p_layout))
	return out


## E21: yürünür alanın ek daireleri (saf): walk_area.extra [x, z, yarıçap] → Vector3(x, z, yarıçap).
static func walk_extra(p_layout: Dictionary) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for row: Variant in (((p_layout.get("childhood", {}) as Dictionary).get("walk_area", {}) as Dictionary).get("extra", [])):
		var r: Array = row
		out.append(Vector3(float(r[0]), float(r[1]), float(r[2])))
	return out


## E21: nokta yürünür alanın birleşiminde mi (saf; kampın dairesi ve ek daireler)?
static func in_walk_area(p_layout: Dictionary, p: Vector2, margin: float = 0.0) -> bool:
	var area: Dictionary = (p_layout.get("childhood", {}) as Dictionary).get("walk_area", {})
	if p.distance_to(OrdosGround._vec2(area.get("center", [0.0, 0.0]))) <= float(area.get("radius", 38.0)) - margin:
		return true
	for c in walk_extra(p_layout):
		if p.distance_to(Vector2(c.x, c.y)) <= c.z - margin:
			return true
	return false


## E21: otun ek dairelerinin tamponları (saf; iş parçacığında): her daire kendi tohumu ve sayısıyla, önceki dairelerin (ve çayırın) içine ot
## koymaz; daireler birleşir (OrdosWorld.merge_grass).
static func zone_grass(spec: Dictionary, base_grass: Dictionary, zones: Array, blockers: Array[Vector3]) -> Dictionary:
	var parts: Array = []
	var base_center := OrdosGround._vec2(base_grass.get("center", [0.0, 0.0]))
	var skip: Array[Vector3] = [Vector3(base_center.x, base_center.y, float(base_grass.get("radius", 0.0)))]
	for z: Variant in zones:
		var zone: Dictionary = z
		var g := base_grass.duplicate()
		g["center"] = zone.get("center", [0.0, 0.0])
		g["radius"] = float(zone.get("radius", 40.0))
		g["count"] = int(zone.get("count", 4000))
		g["seed"] = int(zone.get("seed", 91))
		# Yolların otu iri parçalarda (çizim sayısı az; kadraj uzak ve yüksek).
		g["chunk"] = float(zone.get("chunk", 44.0))
		var zspec := spec.duplicate()
		zspec["grass"] = g
		parts.append(OrdosWorld.grass_buffers(zspec, blockers, 0, 1, skip))
		var c := OrdosGround._vec2(g["center"])
		skip.append(Vector3(c.x, c.y, float(g["radius"])))
	return OrdosWorld.merge_grass(parts)


## Kutular (saf): doğum yurdunun döşeği.
static func collision_boxes(p_layout: Dictionary) -> Array[ObstacleBox]:
	var out: Array[ObstacleBox] = []
	var places: Dictionary = p_layout.get("places", {})
	for id: String in places:
		var place: Dictionary = places[id]
		if str(place.get("kind", "yurt")) == "birth_yurt":
			var at := OrdosGround._vec2(place.get("at", [0.0, 0.0]))
			var basis := OrdosWorld.door_basis(float(place.get("door_az", 90.0)))
			var center := basis * Vector3(1.3, 0.0, -0.3)
			out.append(ObstacleBox.from_transform(Transform3D(basis, Vector3(at.x + center.x, 0.0, at.y + center.z)), Vector2(0.48, 0.93)))
	return out


## Kameranın kutusu (saf): layout'taki oynanış sınırı (x, z düzleminde).
static func bounds_rect(d: Dictionary) -> Rect2:
	var bounds: Dictionary = d.get("camera_bounds", {})
	var a := OrdosGround._vec2(bounds.get("min", [-110.0, -80.0]))
	var b := OrdosGround._vec2(bounds.get("max", [110.0, 80.0]))
	return Rect2(a, b - a)


## Yarış yolunun boyu (saf; metre).
static func race_length(d: Dictionary) -> float:
	return polyline_length((d.get("race", {}) as Dictionary).get("path", []))


## Çizginin boyu (saf; metre).
static func polyline_length(path: Array) -> float:
	var total := 0.0
	for i in range(1, path.size()):
		total += OrdosGround._vec2(path[i - 1]).distance_to(OrdosGround._vec2(path[i]))
	return total


## Hayvan ağlarının verisi (saf; iş parçacığında): koyun ve küçük avın türleri.
static func fauna_arrays(d: Dictionary) -> Dictionary:
	var out := {}
	var herd_def: Dictionary = d.get("herd", {})
	var herd_kind := str(herd_def.get("kind", "sheep"))
	out[herd_kind] = FaunaMesh.arrays(herd_kind)
	for group: Dictionary in (d.get("game", {}) as Dictionary).get("groups", []):
		var kind_id := str(group.get("kind", ""))
		if not out.has(kind_id):
			out[kind_id] = FaunaMesh.arrays(kind_id)
	return out


## Ağılın ve taşın ağ verisi (saf; iş parçacığında): {fence, leaf, stone}, ek olarak kapının yerleri.
static func pen_arrays(p_layout: Dictionary) -> Dictionary:
	var shape := OrdosGround.new(p_layout)
	var d: Dictionary = p_layout.get("childhood", {})
	var pen: Dictionary = d.get("pen", {})
	var out := {}
	if not pen.is_empty():
		out = _fence(pen, shape)
	var stone: Dictionary = d.get("stone", {})
	if not stone.is_empty():
		out["stone"] = _stone(stone, shape)
	out["marks"] = _cairns(d, shape)
	out["flags"] = _line_flags(p_layout, d, shape)
	return out


## Yarış yolunun taş yığınları: yolun iki yanında dönüşümlü, küçük; 40 m kadrajdan yolu okutur.
static func _cairns(d: Dictionary, shape: OrdosGround) -> Dictionary:
	var race: Dictionary = d.get("race", {})
	var path: Array = race.get("path", [])
	var total := polyline_length(path)
	var draft := FaunaMesh.Draft.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 511
	var side := 1.0
	for ratio: float in race.get("cairns", []):
		var along := ratio * total
		var at := Vector2.ZERO
		var dir := Vector2.RIGHT
		var walked := 0.0
		for i in range(1, path.size()):
			var a := OrdosGround._vec2(path[i - 1])
			var b := OrdosGround._vec2(path[i])
			var seg := a.distance_to(b)
			if along <= walked + seg or i == path.size() - 1:
				at = a.lerp(b, clampf((along - walked) / maxf(seg, 0.001), 0.0, 1.0))
				dir = (b - a).normalized()
				break
			walked += seg
		var p := at + Vector2(-dir.y, dir.x) * side * (float(race.get("width", 1.3)) * 0.5 + 0.9)
		side = -side
		var y := shape.height_at(p.x, p.y)
		var tone := CAIRN_COLOR.lightened(rng.randf_range(-0.08, 0.1))
		draft.blob(Vector3(p.x, y + 0.1, p.y), Vector3(0.3, 0.17, 0.27), Basis(Vector3.UP, rng.randf() * TAU), 1, tone, Vector4.ZERO, 0.14, rng.randi() % 1000)
		draft.blob(Vector3(p.x + 0.04, y + 0.28, p.y - 0.03), Vector3(0.2, 0.12, 0.18), Basis(Vector3.UP, rng.randf() * TAU), 1, tone.lightened(0.06), Vector4.ZERO, 0.12, rng.randi() % 1000)
		draft.blob(Vector3(p.x - 0.02, y + 0.42, p.y + 0.01), Vector3(0.11, 0.08, 0.1), Basis(Vector3.UP, rng.randf() * TAU), 0, tone.darkened(0.08), Vector4.ZERO)
	return draft.arrays()


## Sayım hattının kazıklarında bez: rüzgâr altına sarkan şerit (iki yüzlü malzeme).
static func _line_flags(p_layout: Dictionary, d: Dictionary, shape: OrdosGround) -> Dictionary:
	var line: Dictionary = p_layout.get("counting_line", {})
	var flags: Dictionary = d.get("line_flags", {})
	var draft := FaunaMesh.Draft.new()
	if line.is_empty() or flags.is_empty():
		return draft.arrays()
	var a := OrdosGround._vec2(line.get("from", [0.0, 0.0]))
	var b := OrdosGround._vec2(line.get("to", [0.0, 1.0]))
	var n := maxi(int(line.get("stakes", 11)), 2)
	var height := float(line.get("height", 1.05)) + 0.2
	var length := float(flags.get("length", 0.42))
	var width := float(flags.get("width", 0.16))
	var every := maxi(int(flags.get("every", 1)), 1)
	for i in range(0, n, every):
		var q := a.lerp(b, float(i) / float(n - 1))
		var y := shape.height_at(q.x, q.y) + height
		var tone := FLAG_COLORS[i % FLAG_COLORS.size()]
		var points := PackedVector3Array()
		for k in 3:
			var t := float(k) / 2.0
			var along := Vector3(t * length * 0.8, -t * t * length * 0.5, t * 0.06)
			points.append(Vector3(q.x, y, q.y) + along + Vector3(0.0, width * 0.5, 0.0))
			points.append(Vector3(q.x, y, q.y) + along - Vector3(0.0, width * 0.5, 0.0))
		draft.strip(points, Vector3.BACK, tone, Vector4.ZERO)
	return draft.arrays()


## Çit: kazıklar ve aralarında dokunmuş beş sıra çubuk; kapı için iki kalın dikme; kanat ayrı ağdır; ağılın eşyaları (ot, yalak).
static func _fence(pen: Dictionary, shape: OrdosGround) -> Dictionary:
	var center := OrdosGround._vec2(pen.get("at", [0.0, 0.0]))
	var radius := float(pen.get("radius", 8.0))
	var dir := HerdSim.azimuth_vector(float(pen.get("gate_az", 90.0)))
	var width := float(pen.get("gate_width", 2.4))
	var height := float(pen.get("height", 1.12))
	var posts := maxi(int(pen.get("posts", 26)), 8)
	var rails := maxi(int(pen.get("rails", 5)), 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(pen.get("seed", 47))
	var gate_angle := atan2(dir.y, dir.x)
	var half := asin(clampf(width * 0.5 / radius, 0.0, 0.9))
	var d := FaunaMesh.Draft.new()
	var tag := Vector4.ZERO
	var points := PackedVector3Array()
	var bases := PackedVector2Array()
	for i in posts:
		var t := float(i) / float(posts - 1)
		var a := gate_angle + half + t * (TAU - half * 2.0)
		var p := center + Vector2(cos(a), sin(a)) * radius
		bases.append(p)
		points.append(Vector3(p.x, shape.height_at(p.x, p.y), p.y))
	for i in posts:
		var p := points[i]
		var gate_post := i == 0 or i == posts - 1
		var h := height + (0.38 if gate_post else rng.randf_range(-0.05, 0.1))
		var r := 0.085 if gate_post else rng.randf_range(0.045, 0.06)
		var lean := Vector3(rng.randf_range(-0.04, 0.04), 0.0, rng.randf_range(-0.04, 0.04)) * (0.2 if gate_post else 1.0)
		var tone := POST_COLOR.lightened(rng.randf_range(-0.05, 0.12))
		d.tube(PackedVector3Array([p + Vector3.DOWN * 0.15, p + Vector3.UP * h * 0.5 + lean * 0.5, p + Vector3.UP * h + lean]),
			PackedFloat32Array([r * 1.1, r, r * 0.8]), 6, tone, tag)
	_pen_props(d, pen, shape, rng)
	# Kapının kanadı: menteşe kuzey dikmede; yerel +X menteşeden mandala. Çerçeve ağaç, içi aynı örgü.
	var lat := Vector2(-dir.y, dir.x)
	var hinge := center + dir * radius * cos(half) - lat * (width * 0.5)
	var leaf := FaunaMesh.Draft.new()
	var w := width - 0.14
	var top := height + 0.02
	for x: float in [0.05, w - 0.03]:
		leaf.tube(PackedVector3Array([Vector3(x, GATE_CLEARANCE, 0.0), Vector3(x, top, 0.0)]), PackedFloat32Array([0.04, 0.036]), 5, FRAME_COLOR, tag)
	for y: float in [GATE_CLEARANCE + 0.03, top - 0.03]:
		leaf.tube(PackedVector3Array([Vector3(0.03, y, 0.0), Vector3(w, y, 0.0)]), PackedFloat32Array([0.03, 0.03]), 5, FRAME_COLOR.lightened(0.06), tag)
	return {
		"fence": d.arrays(), "leaf": leaf.arrays(), "wattle": _wattle_band(points, center, height, rng), "leaf_panel": _wattle_panel(w, GATE_CLEARANCE + 0.03, top - 0.03),
		"gate_hinge": Vector3(hinge.x, shape.height_at(hinge.x, hinge.y), hinge.y),
		"gate_lat": lat, "gate_dir": dir,
	}


## Örgünün şeridi: kazıklar arasında yerden height'a; her aralıkta üç sütun, orta sütun hafifçe dışa bombeli, üst kenar düzensiz. UV metredir
## (x çit boyunca, y yerden; wattle.gdshader).
static func _wattle_band(points: PackedVector3Array, center: Vector2, height: float, rng: RandomNumberGenerator) -> Dictionary:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var u := 0.0
	var top_a := height + rng.randf_range(-0.06, 0.03)
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var mid := a.lerp(b, 0.5)
		var out := Vector3(mid.x - center.x, 0.0, mid.z - center.y).normalized()
		var top_b := height + rng.randf_range(-0.06, 0.03)
		var top_m := (top_a + top_b) * 0.5 + rng.randf_range(-0.03, 0.02)
		var span := Vector2(b.x - a.x, b.z - a.z).length()
		var base := vertices.size()
		var columns := [[a, top_a, 0.0], [mid + out * 0.045, top_m, 0.5], [b, top_b, 1.0]]
		for column: Array in columns:
			var p: Vector3 = column[0]
			var top: float = column[1]
			var t: float = column[2]
			var n := (out + Vector3(b.x - a.x, 0.0, b.z - a.z).normalized() * (t - 0.5) * 0.3).normalized()
			for y: float in [0.03, top]:
				vertices.append(p + Vector3.UP * y)
				normals.append(n)
				uvs.append(Vector2(u + span * t, y))
		for k in 2:
			var c := base + k * 2
			indices.append_array(PackedInt32Array([c, c + 2, c + 1, c + 1, c + 2, c + 3]))
		u += span
		top_a = top_b
	return {"vertices": vertices, "normals": normals, "uvs": uvs, "indices": indices}


## Kapı kanadının örgüsü: tek dikdörtgen, yerel +X boyunca.
static func _wattle_panel(width: float, bottom: float, top: float) -> Dictionary:
	var vertices := PackedVector3Array([Vector3(0.05, bottom, 0.0), Vector3(0.05, top, 0.0), Vector3(width, bottom, 0.0), Vector3(width, top, 0.0)])
	var normals := PackedVector3Array([Vector3.BACK, Vector3.BACK, Vector3.BACK, Vector3.BACK])
	var uvs := PackedVector2Array([Vector2(0.05, bottom), Vector2(0.05, top), Vector2(width, bottom), Vector2(width, top)])
	return {"vertices": vertices, "normals": normals, "uvs": uvs, "indices": PackedInt32Array([0, 1, 2, 1, 3, 2])}


## Ağılın eşyaları: ot yığını, oyma yalak.
static func _pen_props(d: FaunaMesh.Draft, pen: Dictionary, shape: OrdosGround, rng: RandomNumberGenerator) -> void:
	var tag := Vector4.ZERO
	for prop: Dictionary in pen.get("props", []):
		var at := OrdosGround._vec2(prop.get("at", [0.0, 0.0]))
		var y := shape.height_at(at.x, at.y)
		var r := float(prop.get("radius", 0.6))
		match str(prop.get("kind", "")):
			"hay":
				d.blob(Vector3(at.x, y + r * 0.28, at.y), Vector3(r, r * 0.72, r * 0.9), Basis.IDENTITY, 2, HAY_COLOR, tag, 0.18, rng.randi() % 1000)
				d.blob(Vector3(at.x + r * 0.5, y + r * 0.18, at.y - r * 0.4), Vector3(r * 0.62, r * 0.42, r * 0.6), Basis.IDENTITY, 1, HAY_COLOR.darkened(0.08), tag, 0.14, rng.randi() % 1000)
			"trough":
				var yaw := deg_to_rad(float(prop.get("yaw", 0.0)))
				var along := Vector3(sin(yaw), 0.0, cos(yaw)) * float(prop.get("length", 1.8)) * 0.5
				var c := Vector3(at.x, y + 0.16, at.y)
				d.tube(PackedVector3Array([c - along, c + along]), PackedFloat32Array([0.17, 0.17]), 7, POST_COLOR.lightened(0.14), tag)
				d.tube(PackedVector3Array([c - along * 0.9 + Vector3.UP * 0.1, c + along * 0.9 + Vector3.UP * 0.1]), PackedFloat32Array([0.115, 0.115]), 7, Color(0.15, 0.17, 0.2, 0.0), tag)


## Dikili taş: dik, yassı, kertikli bir kaya (düzlemlerle yontulmuş ikosfer); dibinde iki küçük taş. UV.y yükseklik (atw_rock).
static func _stone(stone: Dictionary, shape: OrdosGround) -> Dictionary:
	var at := OrdosGround._vec2(stone.get("at", [0.0, 0.0]))
	var y := shape.height_at(at.x, at.y)
	var raw: Array = stone.get("size", [0.58, 0.74, 0.42])
	var size := Vector3(float(raw[0]), float(raw[1]), float(raw[2]))
	var seed_value := int(stone.get("seed", 212))
	var out := {"vertices": PackedVector3Array(), "normals": PackedVector3Array(), "uvs": PackedVector2Array(), "indices": PackedInt32Array()}
	_add_rock(out, Vector3(at.x, y + size.y * 0.9, at.y), size, Basis(Vector3.UP, 0.5) * Basis(Vector3.BACK, 0.06), 3, seed_value, y, size.y * 1.9)
	_add_rock(out, Vector3(at.x + 0.62, y + 0.07, at.y + 0.28), Vector3(0.27, 0.17, 0.22), Basis(Vector3.UP, 1.1), 2, seed_value + 3, y, 0.3)
	_add_rock(out, Vector3(at.x - 0.45, y + 0.03, at.y - 0.5), Vector3(0.18, 0.11, 0.2), Basis(Vector3.UP, 2.3), 2, seed_value + 5, y, 0.3)
	return out


## Kaya parçası: ikosfer, birkaç rastgele düzlemle kesilir, hafif gürültü. Yüzler düz gölgelenir (köşeli taş; her üçgenin kendi köşeleri).
static func _add_rock(out: Dictionary, center: Vector3, size: Vector3, basis: Basis, subdivisions: int, seed_value: int, floor_y: float, full_height: float) -> void:
	var data := MeshKit.icosphere_data(subdivisions)
	var points: PackedVector3Array = data[0]
	var faces: PackedInt32Array = data[1]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var cuts: Array[Vector4] = []
	for _i in 9:
		var n := Vector3(rng.randf_range(-1.0, 1.0), rng.randf_range(-0.5, 1.0), rng.randf_range(-1.0, 1.0)).normalized()
		cuts.append(Vector4(n.x, n.y, n.z, rng.randf_range(0.52, 0.8)))
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 2.2
	noise.fractal_octaves = 2
	var shaped := PackedVector3Array()
	shaped.resize(points.size())
	for i in points.size():
		var v := points[i]
		for c in cuts:
			var n := Vector3(c.x, c.y, c.z)
			var over := v.dot(n) - c.w
			if over > 0.0:
				v -= n * over
		v *= 1.0 + noise.get_noise_3dv(points[i]) * 0.07
		shaped[i] = center + basis * (v * size)
	var smooth := MeshKit.smooth_normals(shaped, faces)
	var vertices: PackedVector3Array = out["vertices"]
	var normals: PackedVector3Array = out["normals"]
	var uvs: PackedVector2Array = out["uvs"]
	var indices: PackedInt32Array = out["indices"]
	for k in range(0, faces.size(), 3):
		var a := shaped[faces[k]]
		var b := shaped[faces[k + 1]]
		var c := shaped[faces[k + 2]]
		# Düz yüz, kenarda biraz yumuşak: köşe normalinin yarısı yüzün normali.
		var flat := (c - a).cross(b - a).normalized()
		for q in 3:
			var v := shaped[faces[k + q]]
			indices.append(vertices.size())
			vertices.append(v)
			normals.append((flat * 0.75 + smooth[faces[k + q]] * 0.25).normalized())
			uvs.append(Vector2(0.0, clampf((v.y - floor_y) / full_height, 0.0, 1.0)))
	out["vertices"] = vertices
	out["normals"] = normals
	out["uvs"] = uvs
	out["indices"] = indices


# --- Kurulum -------------------------------------------------------------------------------------------

func _start_job(kind: String, fn: Callable, band: int = 0) -> void:
	var job := _Job.new()
	job.kind = kind
	job.band = band
	job.fn = fn
	# Düşük öncelik (E21): Çocukluk doğumun ve önsözün altında arka planda kurulur; işler iş parçacıklarının bir kısmında koşar, ana
	# iş parçacığının kareleri (sinema, kurulumun adımları) çekirdeklerle yarışmaz.
	job.task_id = WorkerThreadPool.add_task(job.run, false, "childhood %s" % kind)
	_jobs.append(job)


func _poll_jobs() -> void:
	# Yükselti bitince yeni işler eklenir: dizi üstünde dönerken eklenmesin.
	var baked: Variant = null
	for job in _jobs:
		if job.waited or not WorkerThreadPool.is_task_completed(job.task_id):
			continue
		WorkerThreadPool.wait_for_task_completion(job.task_id)
		job.waited = true
		var jobs_ms: Dictionary = build_stats["jobs_ms"]
		jobs_ms[job.kind] = maxf(float(jobs_ms.get(job.kind, 0.0)), job.ms)
		match job.kind:
			"bake":
				job.applied = true
				# Bantların hepsi bitince birleşir (sırayla).
				var bands := _jobs_of("bake")
				if bands.all(func(b: _Job) -> bool: return b.waited):
					var parts: Array = []
					for b in bands:
						parts.append(b.result)
						b.result = {}
					baked = ChildhoodGround.join_rows(_bake_grid, parts)
			"terrain":
				_steps.push_back(_apply_terrain.bind(job))
			"trampled":
				_steps.push_front(_apply_trampled.bind(job))
			"grass":
				_queue_grass(job)
			"grass_e21":
				_queue_grass(job, "GrassReaches")
			"pen":
				_steps.push_back(_apply_pen.bind(job))
			"scatter":
				_steps.push_back(_apply_scatter.bind(job))
			"fauna":
				_fauna_arrays = job.result
				_steps.push_back(_apply_fauna.bind(job))
			"lake":
				_lake_arrays = job.result
				job.applied = true
			"crowd":
				_crowd_job = job
	if baked != null:
		_start_detail_jobs(baked)
	# Kalabalık: plan, zemin ve iki doku hazır olunca tek adım.
	if _crowd_job and ground != null and _crowd_loaded():
		_steps.push_back(_apply_crowd.bind(_crowd_job))
		_crowd_job = null
	if not _props_queued and ground != null and _props_loaded():
		_props_queued = true
		var props := Node3D.new()
		props.name = "Props"
		add_child(props)
		for item: Dictionary in (def.get("props", {}) as Dictionary).get("items", []):
			_steps.push_back(_build_prop.bind(props, item))
		# E21: Ebe Obası'nın eşyaları (kampınkilerle aynı modeller).
		for item: Dictionary in (def.get("ebe", {}) as Dictionary).get("props", []):
			_steps.push_back(_build_prop.bind(props, item))


func _props_loaded() -> bool:
	for path in _prop_loads:
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			return false
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			ResourceLoader.load_threaded_get(path)
	return true


## Eşyanın Meshy modelinin yolu (CampProp.MODELS; modeli olmayan tür için boş).
static func _prop_model_path(kind_name: String) -> String:
	var kind: int = CampProp.Kind.get(kind_name, -1)
	var id := CampProp.model_id_for(kind) if kind >= 0 else ""
	return MeshyProp.model_path(CampProp.MODEL_FOLDER, id) if not id.is_empty() else ""


func _build_prop(parent: Node3D, item: Dictionary) -> void:
	var kind: int = CampProp.Kind.get(str(item.get("kind", "")), -1)
	if kind < 0:
		push_warning("[childhood] bilinmeyen eşya: %s" % item.get("kind"))
		return
	var prop := CampProp.new()
	prop.name = str(item.get("kind", "")).to_pascal_case()
	prop.kind = kind as CampProp.Kind
	# Çarpışmayı OrdosWorld.collect_obstacles verir (prop_circles): kampın engel grubuna girmez.
	prop.blocks_movement = false
	var at := OrdosGround._vec2(item.get("at", [0.0, 0.0]))
	prop.position = Vector3(at.x, ground.height_at(at.x, at.y), at.y)
	prop.rotation.y = deg_to_rad(float(item.get("yaw", 0.0)))
	parent.add_child(prop)
	# Küçük eşyanın gölgesi yukarıdan seçilmez, Meshy ağı gölge bütçesini (iç harita ≤1,5M) yer: gölge vekili kapatılır.
	for gi: Node in prop.find_children("*", "GeometryInstance3D", true, false):
		if gi.has_meta(MeshyProp.SHADOW_PROXY_META):
			(gi as GeometryInstance3D).visible = false
		else:
			(gi as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Eşyaların çarpışma daireleri (saf): Vector3(x, z, yarıçap); boy türün gerçek boyundan (CampProp.MODELS), yoksa yedek yarıçap.
static func prop_circles(p_layout: Dictionary) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for item: Dictionary in ((p_layout.get("childhood", {}) as Dictionary).get("props", {}) as Dictionary).get("items", []):
		var kind: int = CampProp.Kind.get(str(item.get("kind", "")), -1)
		if kind < 0:
			continue
		var size := CampProp.model_size_for(kind as CampProp.Kind)
		var r: float = size * 0.42 if size > 0.0 else float(CampProp.FALLBACK_RADII.get(kind, CampProp.DEFAULT_RADIUS))
		var at := OrdosGround._vec2(item.get("at", [0.0, 0.0]))
		out.append(Vector3(at.x, at.y, r))
	return out


func _jobs_done() -> bool:
	if ground == null or not _props_queued:
		return false
	for job in _jobs:
		if not job.applied:
			return false
	return true


## Çocukluk'un zemini: kendi ağı ve bozkırın maskeli gölgelendiricisi (OrdosWorld.steppe_material) Çocukluk'un maskesiyle; dokular doğumun
## dokularıdır (metre ölçeğinde okunur).
func _apply_terrain(job: _Job) -> void:
	_add_terrain(OrdosGround.make_mesh(job.result), job.band)
	job.applied = true
	job.result = {}


## Zeminin düğümü (ağ bozkırınki ya da kendi işinin bandının ağı; bantlar Terrain, Terrain1, …).
func _add_terrain(mesh: Mesh, band: int = 0) -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Terrain" if band == 0 else "Terrain%d" % band
	mi.mesh = mesh
	mi.material_override = world.steppe_material(_mask)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta(&"free_asset", ["withered_grass", "dry_ground_rocks", "dirt"])
	add_child(mi)


func _apply_trampled(job: _Job) -> void:
	var base := world.get_node_or_null(^"Ground/Trampled") as MeshInstance3D
	var mi := MeshInstance3D.new()
	mi.name = "Trampled"
	mi.mesh = OrdosGround.make_mesh(job.result)
	if base:
		var mat := base.material_override.duplicate() as ShaderMaterial
		var zones := ground.ground_uniforms(OrdosWorld.MAX_CIRCLES, OrdosWorld.MAX_TRAILS)
		for key: String in zones:
			mat.set_shader_parameter(key, zones[key])
		# Gün ışığında toprak daha soluk, iz kenarı daha az dalgalı.
		var look: Dictionary = (def.get("trampled", {}) as Dictionary).get("look", {})
		for key: String in look:
			var value: Variant = look[key]
			mat.set_shader_parameter(key, SkyRig.to_color(value) if value is Array else value)
		mi.material_override = mat
		mi.set_meta(&"free_asset", base.get_meta(&"free_asset", ""))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	job.applied = true
	job.result = {}


## Otun parçalarını adımlara böler (OrdosWorld._queue_grass ile aynı): aynı tutam ağları ve malzeme.
func _queue_grass(job: _Job, node_name: String = "Grass") -> void:
	var keys: Array = job.result.keys()
	keys.sort()
	var meshes: Array[Mesh] = []
	for v in OrdosWorld.TUFT_VARIANTS:
		meshes.append(Meadow.tuft_mesh(v.x, v.y, float(v.z) / 100.0, v.w, Meadow.BLADE_WIDTH.x if v.w == 1 else Meadow.BLADE_WIDTH.y))
	var node := Node3D.new()
	node.name = node_name
	add_child(node)
	var mat := world.grass_material(def.get("grass", {}))
	for start_i in range(0, keys.size(), PER_STEP):
		_steps.push_back(_apply_grass_slice.bind(job, keys.slice(start_i, start_i + PER_STEP), meshes, mat, node))
	_steps.push_back(_mark_applied.bind(job))


func _apply_grass_slice(job: _Job, keys: Array, meshes: Array[Mesh], mat: ShaderMaterial, node: Node3D) -> void:
	for key: Vector3i in keys:
		var buffer: PackedFloat32Array = job.result[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = meshes[key.z]
		mm.instance_count = buffer.size() / OrdosWorld.FLOATS_PER_TUFT
		mm.buffer = buffer
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Grass_%d_%d_%d" % [key.x, key.y, key.z]
		mmi.multimesh = mm
		mmi.material_override = mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.add_child(mmi)


func _mark_applied(job: _Job) -> void:
	job.applied = true
	job.result = {}


func _apply_pen(job: _Job) -> void:
	var data := job.result
	var mat := Style.toon(Color.WHITE, {"use_vertex_color": true, "brush_strength": 0.14})
	if data.has("fence"):
		var pen := Node3D.new()
		pen.name = "Pen"
		add_child(pen)
		var fence := MeshInstance3D.new()
		fence.name = "Fence"
		fence.mesh = FaunaMesh.make_mesh(data["fence"])
		fence.material_override = mat
		pen.add_child(fence)
		var wattle_mat := ShaderMaterial.new()
		wattle_mat.shader = WATTLE_SHADER
		var band := MeshInstance3D.new()
		band.name = "Wattle"
		band.mesh = FaunaMesh.make_mesh(data["wattle"])
		band.material_override = wattle_mat
		pen.add_child(band)
		_gate = Node3D.new()
		_gate.name = "Gate"
		var hinge: Vector3 = data["gate_hinge"]
		var lat: Vector2 = data["gate_lat"]
		var dir: Vector2 = data["gate_dir"]
		_gate_closed_yaw = atan2(-lat.y, lat.x)
		# Kanat dışarı açılır: yerel +X kapının baktığı yöne döner, biraz geçer ve çite yaslanır.
		var quarter := Basis(Vector3.UP, _gate_closed_yaw + PI * 0.5) * Vector3.RIGHT
		var turn_sign := 1.0 if Vector2(quarter.x, quarter.z).dot(dir) > 0.0 else -1.0
		_gate_open_yaw = _gate_closed_yaw + turn_sign * deg_to_rad(GATE_OPEN_DEG)
		_gate.position = hinge
		_gate.rotation.y = _gate_open_yaw if _gate_open else _gate_closed_yaw
		pen.add_child(_gate)
		var leaf := MeshInstance3D.new()
		leaf.name = "Leaf"
		leaf.mesh = FaunaMesh.make_mesh(data["leaf"])
		leaf.material_override = mat
		_gate.add_child(leaf)
		var panel := MeshInstance3D.new()
		panel.name = "LeafWattle"
		panel.mesh = FaunaMesh.make_mesh(data["leaf_panel"])
		panel.material_override = wattle_mat
		_gate.add_child(panel)
	if data.has("stone"):
		var stone := MeshInstance3D.new()
		stone.name = "Stone"
		stone.mesh = FaunaMesh.make_mesh(data["stone"])
		stone.material_override = _rock_mat()
		add_child(stone)
	var marks := Node3D.new()
	marks.name = "Marks"
	add_child(marks)
	var cairns := MeshInstance3D.new()
	cairns.name = "Cairns"
	cairns.mesh = FaunaMesh.make_mesh(data["marks"])
	cairns.material_override = mat
	marks.add_child(cairns)
	var flags := MeshInstance3D.new()
	flags.name = "Flags"
	flags.mesh = FaunaMesh.make_mesh(data["flags"])
	flags.material_override = Style.toon_double(Color.WHITE, {"use_vertex_color": true, "brush_strength": 0.1})
	flags.visible = _dailin_gathered
	marks.add_child(flags)
	job.applied = true
	job.result = {}


func _rock_mat() -> ShaderMaterial:
	if _rock_material == null:
		_rock_material = make_rock_material()
	return _rock_material


## Kayaların ve dikili taşın malzemesi (atw_rock, bozkır tonu; doğumun kayaları da bununla boyanır).
static func make_rock_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = ROCK_SHADER
	for key: String in STONE_PARAMS:
		mat.set_shader_parameter(key, STONE_PARAMS[key])
	return mat


## Kaya ve çalı: biçim ve tür başına bir MultiMesh.
func _apply_scatter(job: _Job) -> void:
	var data := job.result
	solid_rocks = data.get("solid", solid_rocks)
	scatter_counts = data.get("counts", {})
	for node in scatter_nodes(data, _rock_mat()):
		add_child(node)
	job.applied = true
	job.result = {}


## Dağıtımın düğümleri (ChildhoodScatter.build'in sonucundan; doğumun bozkırı da bunları kurar): Rocks (biçim başına bir MultiMesh; çakılın
## gölgesi yoktur) ve Shrubs (tür başına bir MultiMesh).
static func scatter_nodes(data: Dictionary, rock_mat: Material) -> Array[Node3D]:
	var rocks := Node3D.new()
	rocks.name = "Rocks"
	var k := 0
	for row: Dictionary in data.get("rocks", []):
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = FaunaMesh.make_mesh(row["arrays"])
		var buffer: PackedFloat32Array = row["buffer"]
		mm.instance_count = buffer.size() / ChildhoodScatter.ROCK_FLOATS
		mm.buffer = buffer
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Rocks%d" % k
		mmi.multimesh = mm
		mmi.material_override = rock_mat
		# E21: göle ve obaya giden yolların satırı (yalnız Çocukluk'ta; bölge: 0 doğu, 1 kuzey).
		if row.has("region"):
			mmi.set_meta(&"e21_region", int(row["region"]))
		# Çakıl taşının gölgesi görünmez: gölge geçişine girmez.
		if bool(row.get("pebbles", false)):
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		rocks.add_child(mmi)
		k += 1
	var shrubs := Node3D.new()
	shrubs.name = "Shrubs"
	var shrub_mat := ShaderMaterial.new()
	shrub_mat.shader = SHRUB_SHADER
	k = 0
	for row: Dictionary in data.get("shrubs", []):
		var buffer: PackedFloat32Array = row["buffer"]
		if buffer.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = FaunaMesh.make_mesh(row["arrays"])
		mm.instance_count = buffer.size() / ChildhoodScatter.SHRUB_FLOATS
		mm.buffer = buffer
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Shrubs%d" % k
		mmi.multimesh = mm
		mmi.material_override = shrub_mat
		if row.has("region"):
			mmi.set_meta(&"e21_region", int(row["region"]))
		shrubs.add_child(mmi)
		k += 1
	return [rocks, shrubs]


## Hayvan ağları hazır: dağıtım bitince sürü ve av kurulur (sürü büyük kayaları bilir).
func _apply_fauna(job: _Job) -> void:
	if not _job_named("scatter").applied:
		_steps.push_back(_apply_fauna.bind(job))
		return
	_build_herd()
	_steps.push_front(_add_herd)
	_steps.push_back(_build_game)
	_steps.push_back(_build_lake)
	_steps.push_back(_build_reaches)
	_steps.push_back(_build_door_pools)
	job.applied = true


## Kalabalık: atlasın ölçüleri okunur, iki dokusu arka planda yüklenir, plan (CrowdPlan) iş parçacığında kurulur.
func _start_crowd() -> void:
	var spec: Dictionary = def.get("crowd", {})
	if spec.is_empty():
		return
	var meta_path := str(spec.get("atlas", ""))
	if not FileAccess.file_exists(meta_path):
		push_warning("[childhood] kalabalığın atlası yok: %s" % meta_path)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
	_crowd_meta = parsed if parsed is Dictionary else {}
	for path in crowd_texture_paths(meta_path):
		# Başsızda dokular kurulurken eşzamanlı yüklenir (FaunaMesh.background_loads; yukarıdaki eşyalar gibi).
		if not FaunaMesh.background_loads():
			if ResourceLoader.exists(path):
				_crowd_sync.append(path)
				_steps.push_back(_load_crowd_texture.bind(path))
		elif ResourceLoader.exists(path) and ResourceLoader.load_threaded_request(path, "", false) == OK:
			_crowd_loads.append(path)
	var blockers := crowd_blockers(layout)
	var plan_spec := spec.duplicate(true)
	# Plan, yerlerin yüksekliği ve kırpma kutusu iş parçacığında (işin kendi zemini: öteki işler gibi; zemin henüz yoksa kurulumda hesaplanır).
	var shape_spec := _spec
	_start_job("crowd", func() -> Dictionary:
		var plan := CrowdPlan.build(plan_spec, blockers)
		if shape_spec.is_empty():
			return {"plan": plan}
		var shape := OrdosGround.new(shape_spec)
		return {"plan": plan, "heights": CrowdPlan.heights(plan, shape), "bounds": CrowdPlan.bounds(plan, shape)})


## Atlasın iki dokusu (renk, normal): <ad>.png ve <ad>_normal.png.
static func crowd_texture_paths(meta_path: String) -> PackedStringArray:
	var base := meta_path.get_basename()
	return PackedStringArray([base + ".png", base + "_normal.png"])


## Kalabalığın kaçındığı daireler (saf): yurtlar, eşyalar, ağıl.
static func crowd_blockers(p_layout: Dictionary) -> Array[Vector3]:
	var out := collision_circles(p_layout, true)
	out.append_array(prop_circles(p_layout))
	var pen: Dictionary = (p_layout.get("childhood", {}) as Dictionary).get("pen", {})
	if not pen.is_empty():
		var at := OrdosGround._vec2(pen.get("at", [0.0, 0.0]))
		out.append(Vector3(at.x, at.y, float(pen.get("radius", 8.0)) + 1.5))
	return out


## Başsızda kalabalığın bir dokusu (kendi adımında; sırayla).
func _load_crowd_texture(path: String) -> void:
	_crowd_sync_tex.append(load(path) as Texture2D)


## Kalabalığı kurar: dokular yüklenince (beklerken adım sıraya döner).
func _crowd_loaded() -> bool:
	if _crowd_sync_tex.size() < _crowd_sync.size():
		return false
	for path in _crowd_loads:
		if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			return false
	return true


func _apply_crowd(job: _Job) -> void:
	_crowd_textures.clear()
	for path in _crowd_loads:
		var tex := ResourceLoader.load_threaded_get(path) as Texture2D
		_crowd_textures.append(tex)
	_crowd_loads.clear()
	_crowd_textures.append_array(_crowd_sync_tex)
	_crowd_sync.clear()
	_crowd_sync_tex.clear()
	job.applied = true
	if _crowd_textures.size() < 2 or _crowd_textures[0] == null or _crowd_textures[1] == null:
		push_warning("[childhood] kalabalığın dokuları yüklenemedi")
		return
	var plan: Array[Dictionary] = []
	plan.assign(job.result.get("plan", []))
	crowd = CrowdCards.new()
	crowd.name = "Crowd"
	crowd.setup(plan, ground, _crowd_meta, _crowd_textures[0], _crowd_textures[1], job.result.get("heights", PackedFloat32Array()),
		job.result.get("bounds", AABB()))
	add_child(crowd)
	crowd.set_minute(_minute)
	if _watch != Vector3.INF:
		crowd.watch(_watch)
	if not _dailin_gathered:
		set_dailin_gathered(false)


func _job_named(kind: String) -> _Job:
	for job in _jobs:
		if job.kind == kind:
			return job
	return null


## Bir türün bantları (sırayla).
func _jobs_of(kind: String) -> Array[_Job]:
	var out: Array[_Job] = []
	for job in _jobs:
		if job.kind == kind:
			out.append(job)
	out.sort_custom(func(a: _Job, b: _Job) -> bool: return a.band < b.band)
	return out


func _build_herd() -> void:
	var herd_def: Dictionary = def.get("herd", {})
	herd = HerdField.new()
	herd.name = "Herd"
	herd.kind_id = str(herd_def.get("kind", "sheep"))
	var obstacles := collision_circles(layout, true)
	obstacles.append_array(solid_rocks)
	obstacles.append_array(prop_circles(layout))
	herd.setup(def, ground, obstacles, _fauna_arrays.get(herd.kind_id, {}))
	herd.sim.gate_open = _gate_open
	# E21: sürü göle ve geri sürülür: kırpma kutusu oynanış sınırının bütünüdür.
	var b := bounds_rect(def)
	herd.instance.custom_aabb = AABB(Vector3(b.position.x - 20.0, -60.0, b.position.y - 20.0), Vector3(b.size.x + 40.0, 160.0, b.size.y + 40.0))


## Sürü ağaca girer (kendi adımı: başsızda koyunun modeli burada eşzamanlı yüklenir).
func _add_herd() -> void:
	if herd and not herd.is_inside_tree():
		add_child(herd)


func _build_game() -> void:
	game = SmallGameField.new()
	game.name = "SmallGame"
	game.auto_add = false
	game.setup(def.get("game", {}), ground, _fauna_arrays)
	add_child(game)
	_fauna_arrays = {}
	_steps.push_back(_add_game_animals)


## Av hayvanları birkaç birkaç eklenir (her biri kendi ağını kurar): kare bütçesi.
func _add_game_animals() -> void:
	if game.add_pending(4):
		_steps.push_front(_add_game_animals)


## E21: Kamışlı Göl'ün kıyısı (sazlık, balçık, ak taş, ördekler, halkalar, kıyının dalgası, sayım taşları).
func _build_lake() -> void:
	if ground == null or ground.lake_half_width <= 0.0 or not def.has("lake_site"):
		return
	var job := _job_named("lake")
	if job and not job.applied:
		# Diziler iş parçacığında; bitince kurulur.
		_steps.push_back(_build_lake)
		return
	lake = ChildhoodLake.new()
	lake.name = "Lake"
	lake.setup(world, ground, layout, _lake_arrays)
	lake.deferred = true
	_lake_arrays = {}
	add_child(lake)
	# Parçalar kare bütçesinde sırayla (su, sazlık, balçık, taşlar, ördekler, halkalar, kıyı).
	var parts := lake.parts()
	parts.reverse()
	for part in parts:
		_steps.push_front(part)


## E21: uzak yerler (Ebe Obası'nın yurtları, bağlama direği, Dailin'in dumanları, uzak atlılar, turnalar).
func _build_reaches() -> void:
	if not def.has("ebe") and not def.has("far"):
		return
	reaches = ChildhoodReaches.new()
	reaches.name = "Reaches"
	reaches.setup(ground, layout)
	reaches.clock_source = func() -> float: return _minute
	reaches.deferred = true
	add_child(reaches)
	# Parçalar kare bütçesinde sırayla (obanın kökü, yurtlar, ocak, direk, dumanlar, atlılar, turnalar).
	var parts := reaches.parts()
	parts.reverse()
	for part in parts:
		_steps.push_front(part)
