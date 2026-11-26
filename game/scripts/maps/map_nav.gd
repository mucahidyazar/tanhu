class_name MapNav
extends Node
## İç haritanın yol bulması (godot.md §4.7; companions.md §5.3; Yol Haritası navigation). Haritanın navmesh'i 100 m'lik karolardır
## (NavigationRegion3D, arazi parçalarıyla aynı; tools/bake_map.gd başsız pişirir: filter_baking_aabb ve border_size karo dikişini hizalar).
## MapWorld kurulurken MapNav dünyanın çocuğudur (MapWorld/MapNav; karolar MapWorld/Navigation/Tile_<x>_<z>); kişiler (C), hayvanlar (D) ve
## oyuncunun tıkla yürüsü bu tek yüzü kullanır:
##
##   var nav := MapNav.of(world)                  # haritanın navigasyonu (MapWorld/MapNav; harita değilse ya da navmesh'i yoksa null)
##   nav.path(from, to)                           # PackedVector3Array: NavigationServer3D.map_get_path (düzeltilmiş köşeler; yol yoksa boş)
##   nav.walk_path(from, to)                      # oyuncu için: navmesh yolu, yoksa düz çizgi [from, to] (oyuncu navmesh'e bağlı değildir)
##   nav.closest(p)                               # navmesh'in noktaya en yakın yeri (navmesh hazır değilse p)
##   nav.is_ready()                               # harita eşlendi mi (ilk eşlemeden önce yol boştur)
##   MapNav.setup_agent(agent, MapNav.WALKER, 0.5)   # NavigationAgent3D'nin yarıçapı, komşuları, ufukları, önceliği, yol payı
##   MapNav.profile(MapNav.RIDER)                 # profilin sayıları (sözlük)
##   nav.add_obstacle("yurt_new", Vector3(x, z, r))         # daire engel; değen karolar eşzamansız yeniden pişer
##   nav.add_outline("pen", PackedVector2Array([...]))       # çokgen engel (yapının izi)
##   nav.remove_obstacle("yurt_new"); nav.rebake_rect(Rect2(...))
##
## Ajan profilleri (companions.md §5.3): yaya yarıçap 0,45 m, neighbor_distance 6 m; atlı 1,1 m, 12 m; max_neighbors 6; time_horizon_agents
## 0,8 sn, time_horizon_obstacles 0,4 sn; avoidance_priority Mete 1,0, yoldaş ve kişi 0,5; path_max_distance yaya 2 m, atlı 4 m; hedef 4 Hz'de
## yenilenir (çağıranın işi: TARGET_HZ). Hayvanlar: küçük (koyun, keçi, köpek, kurt) 0,4 m, büyük (at, deve, sığır, maral) 0,9 m; açık
## bozkırda kaçınma kapalıdır (army.md'nin itmesi yeter): avoidance false verilir. Navmesh'in kendisi yaya ajanıyla pişer (yarıçap 0,5 m, boy
## 1,75 m, eğim ≤40°, tırmanış 0,5 m; map.json «nav»): atlı ve büyük hayvan aynı ağı kullanır, dar yerden (yurt arası ≥1,1 m) yolun
## köşesiyle geçer.
##
## Yeniden pişirme (Plan Kipi, yeni yapı, yıkılan çit): değen karoların kaynağı (yükseklik ızgarasının üçgenleri, haritanın yapı kayıtları ve
## eklenen engeller; MapBaker.nav_source) WorkerThreadPool'da kurulur, pişirme NavigationServer3D.bake_from_source_geometry_data_async ile
## ana iş parçacığının dışındadır; biten karo yeni NavigationMesh olarak bölgesine yazılır. İstekler 0,25 sn birikir (art arda değişiklik
## bir kez pişer), aynı anda en çok MAX_JOBS karo.

signal tile_rebaked(key: Vector2i)

const WALKER := &"walker"
const RIDER := &"rider"
const ANIMAL_SMALL := &"animal_small"
const ANIMAL_LARGE := &"animal_large"
## Profillerin sayıları (companions.md §5.3; hayvanlar fauna.md'nin boylarından).
const PROFILES := {
	&"walker": {"radius": 0.45, "height": 1.75, "neighbor_distance": 6.0, "max_neighbors": 6, "time_horizon_agents": 0.8,
		"time_horizon_obstacles": 0.4, "path_max_distance": 2.0, "avoidance": true, "max_speed": 7.6},
	&"rider": {"radius": 1.1, "height": 2.6, "neighbor_distance": 12.0, "max_neighbors": 6, "time_horizon_agents": 0.8,
		"time_horizon_obstacles": 0.4, "path_max_distance": 4.0, "avoidance": true, "max_speed": 10.5},
	&"animal_small": {"radius": 0.4, "height": 0.9, "neighbor_distance": 5.0, "max_neighbors": 6, "time_horizon_agents": 0.8,
		"time_horizon_obstacles": 0.4, "path_max_distance": 2.0, "avoidance": false, "max_speed": 9.0},
	&"animal_large": {"radius": 0.9, "height": 2.0, "neighbor_distance": 10.0, "max_neighbors": 6, "time_horizon_agents": 0.8,
		"time_horizon_obstacles": 0.4, "path_max_distance": 3.0, "avoidance": false, "max_speed": 12.0},
}
## Kaçınma önceliği (companions.md §5.3): Mete 1,0, yoldaş ve kişi 0,5.
const PRIORITY_METE := 1.0
const PRIORITY_FOLLOWER := 0.5
## Ajanın hedefini yenileme sıklığı (Hz; companions.md §5.3).
const TARGET_HZ := 4.0
## Yeniden pişirme isteğinin birikme süresi (sn) ve aynı anda en çok iş.
const DEBOUNCE := 0.25
const MAX_JOBS := 2

var world: Node3D
var spec: MapSpec
var shape: HeightmapShape
## Karo anahtarı → NavigationRegion3D.
var regions: Dictionary = {}
## Eklenen engeller: kimlik → Vector3(x, z, r) ya da PackedVector2Array.
var obstacles: Dictionary = {}
## Yeniden pişen karoların sayısı (sınama, ölçüm) ve sürmekte olanlar.
var rebaked := 0

var _static_obstacles: Array[Vector3] = []
## Yapı kitinin kutularının çokgenleri (MapBaker.nav_outlines; pişirmeyle aynı): yeniden pişen karo da onları taşır.
var _static_outlines: Array[PackedVector2Array] = []
## Yeni ağ yazıldığında haritanın eşleme sayacı: sunucu bir sonraki eşlemeyi bitirene dek (4.7'de eşleme eşzamansızdır) yol eski ağdan
## gelir, is_busy true kalır.
var _write_iteration := -1
var _ready_after := 0
var _pending: Dictionary = {}
var _wait := 0.0
var _jobs: Dictionary = {}


## Haritanın navigasyonu (MapWorld/MapNav); yoksa null.
static func of(node: Node) -> MapNav:
	if node == null:
		return null
	return node.get_node_or_null(^"MapNav") as MapNav


## Profilin sayıları (bilinmeyen profil yaya).
static func profile(id: StringName) -> Dictionary:
	return PROFILES.get(id, PROFILES[WALKER])


## NavigationAgent3D'yi profile göre kurar (companions.md §5.3). priority: kaçınma önceliği (Mete 1,0, yoldaş ve kişi 0,5).
static func setup_agent(agent: NavigationAgent3D, id: StringName = WALKER, priority: float = PRIORITY_FOLLOWER) -> void:
	var p := profile(id)
	agent.radius = float(p["radius"])
	agent.height = float(p["height"])
	agent.neighbor_distance = float(p["neighbor_distance"])
	agent.max_neighbors = int(p["max_neighbors"])
	agent.time_horizon_agents = float(p["time_horizon_agents"])
	agent.time_horizon_obstacles = float(p["time_horizon_obstacles"])
	agent.path_max_distance = float(p["path_max_distance"])
	agent.max_speed = float(p["max_speed"])
	agent.avoidance_enabled = bool(p["avoidance"])
	agent.avoidance_priority = clampf(priority, 0.0, 1.0)
	agent.path_desired_distance = 0.6
	agent.target_desired_distance = 0.8


## Bağlar: dünya, tarif, yükseklik yüzü ve karolar (MapWorld._build_nav kurar).
func setup(p_world: Node3D, p_spec: MapSpec, p_shape: HeightmapShape, p_regions: Dictionary) -> void:
	world = p_world
	spec = p_spec
	shape = p_shape
	regions = p_regions
	_static_obstacles = MapBaker.nav_obstacles(spec) if spec else ([] as Array[Vector3])
	_static_outlines = MapBaker.nav_outlines(spec) if spec else ([] as Array[PackedVector2Array])
	# Gezinti haritası dünyanındır (World3D'nin varsayılanı) ve önceki dünyalardan eşleme sayacı taşır: karolar bu sayaçtan sonraki ilk
	# eşlemeyle hazır sayılır.
	var rid := map_rid()
	_ready_after = NavigationServer3D.map_get_iteration_id(rid) if rid.is_valid() else 0


func _exit_tree() -> void:
	# Süren iş parçacığı işleri beklenir (dünya bırakılırken kaynak yarım kalmasın).
	for key: Vector2i in _jobs.keys():
		var job: Dictionary = _jobs[key]
		if int(job.get("task", -1)) >= 0 and not bool(job.get("joined", false)):
			WorkerThreadPool.wait_for_task_completion(int(job["task"]))
	_jobs.clear()


func map_rid() -> RID:
	if world == null or not world.is_inside_tree():
		return RID()
	return world.get_world_3d().navigation_map


## Harita eşlendi mi (karolar eklendikten sonra sunucunun ilk eşlemesi; o zamana dek yol boştur)?
func is_ready() -> bool:
	var rid := map_rid()
	# Bölgeler de eşzamansız eşlenir (4.7): ilk eşlemeden sonra da bir süre yol boş dönebilir; çağıran yolu yine dener.
	return rid.is_valid() and NavigationServer3D.map_get_iteration_id(rid) > _ready_after


## Navmesh yolu (düzeltilmiş köşeler). Yol yoksa ya da harita henüz eşlenmediyse boş (çağıran sonra yeniden sorar).
func path(from: Vector3, to: Vector3, layers: int = 1) -> PackedVector3Array:
	var rid := map_rid()
	if not rid.is_valid():
		return PackedVector3Array()
	return NavigationServer3D.map_get_path(rid, from, to, true, layers)


## Oyuncunun tıkla yürü yolu (godot.md §4.7: oyuncu navmesh'e bağlı değildir): navmesh yolu varsa o, yoksa düz çizgi [from, to].
func walk_path(from: Vector3, to: Vector3) -> PackedVector3Array:
	var p := path(from, to)
	if p.size() >= 2:
		return p
	return PackedVector3Array([from, to])


## Navmesh'in noktaya en yakın yeri (harita eşlenmediyse nokta).
func closest(p: Vector3) -> Vector3:
	if not is_ready():
		return p
	var q := NavigationServer3D.map_get_closest_point(map_rid(), p)
	return p if q == Vector3.ZERO and p.length_squared() > 1.0 else q


## Yolun ucu hedefe slack metreden yakın mı (ulaşılır mı)?
func reachable(from: Vector3, to: Vector3, slack: float = 1.5) -> bool:
	var p := path(from, to)
	return p.size() >= 2 and p[p.size() - 1].distance_to(to) <= slack


## Daire engel ekler (Vector3(x, z, yarıçap)); değen karolar yeniden pişer.
func add_obstacle(id: String, circle: Vector3) -> void:
	obstacles[id] = circle
	rebake_rect(Rect2(Vector2(circle.x, circle.y) - Vector2.ONE * circle.z, Vector2.ONE * circle.z * 2.0))


## Çokgen engel ekler (yapının izi, x-z); değen karolar yeniden pişer.
func add_outline(id: String, outline: PackedVector2Array) -> void:
	if outline.size() < 3:
		return
	obstacles[id] = outline
	rebake_rect(_outline_rect(outline))


## Engeli kaldırır; değen karolar yeniden pişer.
func remove_obstacle(id: String) -> void:
	if not obstacles.has(id):
		return
	var o: Variant = obstacles[id]
	obstacles.erase(id)
	if o is Vector3:
		var c: Vector3 = o
		rebake_rect(Rect2(Vector2(c.x, c.y) - Vector2.ONE * c.z, Vector2.ONE * c.z * 2.0))
	else:
		rebake_rect(_outline_rect(o))


## Dikdörtgene değen karoları (border_size payıyla) yeniden pişirme kuyruğuna koyar.
func rebake_rect(r: Rect2) -> void:
	for key: Vector2i in tiles_touching(r):
		_pending[key] = true
	_wait = DEBOUNCE
	set_process(true)


## Dikdörtgene (karonun border_size payıyla) değen karolar.
func tiles_touching(r: Rect2) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var border := maxf(float(spec.nav.get("agent_radius", 0.5)) * 2.0, 1.0) if spec else 1.0
	for key: Vector2i in regions:
		var region := regions[key] as NavigationRegion3D
		var tile: Rect2 = region.get_meta(&"rect", Rect2())
		if tile.grow(border + 2.0).intersects(r, true):
			out.append(key)
	out.sort()
	return out


## Sürmekte olan ya da bekleyen iş var mı (yazılan karonun haritaya eşlenmesi dahil)?
func is_busy() -> bool:
	return not _pending.is_empty() or not _jobs.is_empty() or _awaiting_sync()


func _awaiting_sync() -> bool:
	if _write_iteration < 0:
		return false
	var rid := map_rid()
	if not rid.is_valid() or NavigationServer3D.map_get_iteration_id(rid) > _write_iteration:
		_write_iteration = -1
		return false
	return true


func _ready() -> void:
	set_process(false)


func _process(delta: float) -> void:
	# Biten işler: kaynak kuruldu → eşzamansız pişirme; pişti → bölgeye yaz.
	for key: Vector2i in _jobs.keys():
		var job: Dictionary = _jobs[key]
		if not bool(job.get("joined", false)):
			if not WorkerThreadPool.is_task_completed(int(job["task"])):
				continue
			WorkerThreadPool.wait_for_task_completion(int(job["task"]))
			job["joined"] = true
			var made: Array = job["result"]
			if made.size() < 2:
				_jobs.erase(key)
				continue
			job["mesh"] = made[0]
			NavigationServer3D.bake_from_source_geometry_data_async(made[0], made[1], _on_baked.bind(key))
		elif bool(job.get("baked", false)):
			var region := regions.get(key) as NavigationRegion3D
			if is_instance_valid(region):
				region.navigation_mesh = job["mesh"]
				var rid := map_rid()
				_write_iteration = NavigationServer3D.map_get_iteration_id(rid) if rid.is_valid() else -1
			_jobs.erase(key)
			rebaked += 1
			tile_rebaked.emit(key)
	if not _pending.is_empty():
		_wait -= delta
		if _wait <= 0.0:
			for key: Vector2i in _pending.keys():
				if _jobs.size() >= MAX_JOBS:
					break
				if _jobs.has(key):
					continue
				_pending.erase(key)
				_start(key)
	if _pending.is_empty() and _jobs.is_empty() and not _awaiting_sync():
		set_process(false)


func _start(key: Vector2i) -> void:
	var region := regions.get(key) as NavigationRegion3D
	if not is_instance_valid(region) or shape == null:
		return
	var tile: Rect2 = region.get_meta(&"rect", Rect2())
	var circles := _static_obstacles.duplicate()
	var outlines: Array[PackedVector2Array] = _static_outlines.duplicate()
	for o: Variant in obstacles.values():
		if o is Vector3:
			circles.append(o)
		else:
			outlines.append(o)
	var job := {"result": []}
	var map_rect := spec.rect()
	var nav_def := spec.nav.duplicate(true)
	var src_shape := shape
	job["task"] = WorkerThreadPool.add_task(func() -> void:
		job["result"] = MapBaker.nav_source(src_shape, map_rect, tile, nav_def, circles, outlines), false, "MapNav karo")
	_jobs[key] = job


func _on_baked(key: Vector2i) -> void:
	# Pişirme sunucunun işçisinde biter: yalnız bayrak yazılır, bölgeyi _process yazar (iş sürerken süreç açıktır).
	var job: Dictionary = _jobs.get(key, {})
	if not job.is_empty():
		job["baked"] = true


static func _outline_rect(outline: PackedVector2Array) -> Rect2:
	var r := Rect2(outline[0], Vector2.ZERO)
	for q in outline:
		r = r.expand(q)
	return r
