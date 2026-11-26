class_name OrdosWorld
extends Node3D
## Çocukluk'un küçük dünyası childhood_ordos (≈220 × 160 m; story.md §4–§5, godot.md §3.6, §4.3): Ordos, Sarı
## Irmak kıvrımının içinde Teoman'ın güz otlağı, Dailin'in toplandığı yer. Önsöz'ün doğumu burada 3B oynar
## (27 Eylül MÖ 234 şafağı); Çocukluk (childhood-p1) aynı dünyayı ağıl, yarış yolu ve sürüyle genişletir.
##
## Yerler data/maps/childhood_ordos/layout.json'dadır (yerler, boyutlar, tohumlar, kamera noktaları):
##   Places/LanYurt        Lan Hatun'un yurdu (BirthYurt): kapı doğuya; içi kerege astarlı, keçeli, toprak tabanlı;
##                         ortada ocak (Places/LanYurt/Hearth, HearthEmbers: üç taş, köz, titreyen ışık), kase.
##   Places/TeomanOtag     Teoman'ın otağı (büyük Yurt, kapı doğuya); Places/KinYurt*: boyların yurtları.
##   Places/CountingLine   sayım hattı: kazık sırası ve ip (Stakes, Rope).
##   Markers/*             Counter (sayıcı noktası), LineNorth, LineSouth, Cradle (beşik), Burial (eşin gömüleceği
##                         yer), LanDoor, TeomanDoor: Marker3D, zemine oturur.
##   Cameras/*             çekim önerileri (Marker3D; meta fov). camera_point(id) dönüşümü ve görüş açısını verir.
##   Ground/Terrain        güz otlağının bozkırı (steppe: OrdosGround + ChildhoodGround'un yükseltisi; 2 m ızgara, dışı 3 km'ye dek seyrek):
##                         kademe, tepecik, kuru dere; maskeli zemin (childhood_ground.gdshader: ot dibi, toprak, kum, çakıl, koyu otluk;
##                         doğumun maskesi: Çocukluk'un izleri yok). Çiğnenmiş toprak (avlu, kapı önleri, sayım hattının izi) maskede dokulu
##                         açık topraktır.
##   Ground/Trampled       yalnız çiğnenmiş toprağın üst katmanının malzemesi (doğumda ağı yok; Çocukluk'un üst katmanı ondan kurulur)
##   Ground/Grass          sarı ot (MultiMesh, atw_grass; maskeye uyar)
##   Ground/Rocks, Shrubs  kaya öbekleri, kademe taşları, çakıl, pelin ve karagan (ChildhoodScatter; Çocukluk'unkilerle aynı yerde)
##   River                 ufukta Sarı Irmak (water.gdshader).
##   MÖ 234 ile MÖ 228 aynı otlaktır: doğum ve Çocukluk aynı yükseltiyi, kayayı ve çalıyı görür.
##   WorldEnvironment, SunLight, SkyRig: dünyanın kendi ışığı; SkyRig açılışta birth_light.json'un "inside"
##                         örneğini yazar, sinema çekim başına sabit örnek verir (godot.md §4.9).
##
## Yükleme (godot.md §4.3): sahne ResourceLoader.load_threaded_request ile arka planda gelir (CineHost'un preload
## olayı; yurt modeli ve dokular preloaded ile birlikte yüklenir). Örnekleme ve ağaca ekleme ana iş parçacığındadır;
## ağır üretim WorkerThreadPool'dadır: önce yükselti ve maske satır bantlarıyla pişer (ChildhoodGround.bake_rows), sonra arazinin
## bantları (OrdosGround.build_rows), otun bantları ve dağıtım (kaya, çalı) birlikte koşar (JOB_BANDS iş parçacığı).
## Ana iş parçacığındaki kurulum adımlara bölünür, kare başına frame_budget_ms (4 ms) dolunca sonraki kareye kalır.
## is_ready() hepsi bitince true olur (world_ready yayılır); CineHost segmenti o ana dek bekletir.
##
## Ücretsiz varlıklar (K89, E7.5; assets/_free, usage.jsonl): Ground/Terrain withered_grass (ve metre ölçeğinde dry_ground_rocks,
## dirt), Ground/Trampled dry_ground_rocks, Places/LanYurt/Floor dirt, Places/LanYurt/Hearth/Ash burned_ground_01, WorldEnvironment
## qwantani_sunrise_puresky (ortam panoraması). Her düğüm free_asset meta verisini taşır.
##
## Çocukluk (story.md §5; Yol Haritası childhood-world, childhood-herd): ağıl, yarış yolu ve taşı, sürü, küçük av, sayım hattının bezleri ve
## kampın gündelik eşyaları ChildhoodSite'tadır (OrdosWorld/Childhood), dünyayla birlikte kurulmaz, doğumda yoktur; Çocukluk'un zemini (ağılın
## ve izlerin çiğnenmiş toprağı, kendi otu, maskesi) de oradadır ve açılınca Ground'un yerini alır:
##   world.prepare_childhood()           arka planda kurar (gizli); doğumun sonunda çağrılırsa geçişte beklenmez
##   world.set_childhood_mode(true)      gösterir (kurulmamışsa kurar, childhood_ready'de görünür); ışık 08:40'a döner; false geri alır
##   world.is_childhood_ready(), world.is_childhood_mode(), world.childhood() -> ChildhoodSite (herd, game, set_gate_open, release_herd, drive_herd)
##   world.set_childhood_time(dakika)    güneş ve gök (renkler 08:40–11:00 örnekleri arasında, güneş o dakikada; ChildhoodScene'in GameClock'u 4 Hz yazar),
##                                       kalabalık da (set_crowd_minute: yalnız kalabalık, her kare)
##   world.marker(id)                    düzenin "markers" ve "childhood.markers" işaretleri (child_start, pen_gate, race_stone...)
## Oyuncu ve kamera için (PlayerController world: World ister; bu dünyanın yüzü aynı adlarla):
##   player.terrain_shape = world.get_terrain_shape()  (OrdosGround bir TerrainShape'tir: bozkırın yüzü steppe, Çocukluk açıkken onunki; ikisinin
##     yüksekliği aynıdır: kademe, tepe, dere); follow_camera.terrain_shape da
##   player.obstacles = world.collect_obstacles(); player.walls = world.collect_walls(); player.boxes = world.collect_boxes()
##     (kapı açılınca kutular değişir: collect_boxes yeniden sorulur)
##   var area := world.play_area()       {center: Vector2, radius, soft_edge}: play_area_center, play_area_radius, play_area_soft_edge
##   world.camera_bounds() -> Rect2 (x, z); world.clamp_camera_transform(xform, focus) -> Transform3D: kamerayı kutuda tutar, odağa çevirir

signal world_ready
## Çocukluk'un yerleri kuruldu (prepare_childhood, set_childhood_mode).
signal childhood_ready

const LAYOUT_PATH := "res://data/maps/childhood_ordos/layout.json"
const GRASS_SHADER := preload("res://shaders/atw_grass.gdshader")
const GROUND_SHADER := preload("res://assets/maps/ordos/ordos_ground.gdshader")
## Bozkırın zemini (doğumun ve Çocukluk'un; maskeli).
const STEPPE_SHADER := preload("res://assets/maps/ordos/childhood_ground.gdshader")
const WATER_SHADER := preload("res://shaders/water.gdshader")
## Ücretsiz dokular: düğüm adı → [FREE_ASSETS.json kimliği, dosya].
const FREE_GROUND := ["withered_grass", "res://assets/_free/texture/withered_grass/withered_grass_diff_2k.jpg"]
const FREE_TRAMPLED := ["dry_ground_rocks", "res://assets/_free/texture/dry_ground_rocks/dry_ground_rocks_diff_1k.jpg"]
const FREE_FLOOR := ["dirt", "res://assets/_free/texture/dirt/dirt_diff_1k.jpg"]
const FREE_ASH := ["burned_ground_01", HearthEmbers.ASH_TEXTURE_PATH]
## Ot tutamı çeşitleri (Meadow.tuft_mesh): Vector4i(yaprak, tohum, yayılım × 100, bölüt). İlk ikisi kısa, sonuncu uzun.
const TUFT_VARIANTS: Array[Vector4i] = [Vector4i(8, 5, 48, 1), Vector4i(7, 11, 43, 1), Vector4i(10, 23, 105, 2)]
## MultiMesh tamponunda örnek başına sayı: 12 dönüşüm (3 × 4, satır satır) + 4 özel veri.
const FLOATS_PER_TUFT := 16
## Çiğnenmiş toprak katmanının zeminden yüksekliği (metre).
const TRAMPLED_LIFT := 0.02
## Gölgelendiricinin bölge dizilerinin boyu (ordos_ground.gdshader MAX_CIRCLES, MAX_TRAILS).
const MAX_CIRCLES := 12
const MAX_TRAILS := 12
## Bantlara bölünen işlerin (yükselti, arazi, ot) iş parçacığı sayısı: sonuç tek parçalı üretimle aynıdır (otun bantları kendi tohumuyla).
## Dörtten çoğu hızlandırmaz: nesnenin her yöntem çağrısı (gürültü) ObjectDB'nin ortak kilidinden geçer (ölçüm 2026-11-07, arazi: 1 bant
## 584 ms, 4 bant 307 ms, 8 bant 496 ms).
const JOB_BANDS := 4
## Bozkırın zemininin ücretsiz dokuları (free_asset meta verisi; dokular ground_textures()'ın sırasıyla).
const STEPPE_ASSETS: Array[String] = ["withered_grass", "dry_ground_rocks", "dirt"]
## Çocukluk'un ışık örnekleri ve saatin iki ucu (gün dakikası: 08:40, 11:00).
const CHILDHOOD_LIGHT := "res://data/maps/childhood_ordos/light.json"
const CHILDHOOD_START_MINUTE := 520.0
const CHILDHOOD_END_MINUTE := 660.0

@export_file("*.json") var layout_path := LAYOUT_PATH
## Sahneyle birlikte (arka planda) yüklenen kaynaklar: yurt modeli ve dokular. Kurulum bunları önbellekten alır,
## ana iş parçacığında diske gidilmez.
@export var preloaded: Array[Resource] = []
## Ana iş parçacığında kare başına kurulum bütçesi (milisaniye; godot.md §4.3 madde 4).
@export var frame_budget_ms := 4.0

var layout: Dictionary = {}
## Düzenin yalın yüzü (yükseltisiz): yurtlar, kazıklar ve işaretler bunun üstünde kurulur; yükselti oralarda sıfırdır.
var ground: OrdosGround
## Bozkırın yüzü (yalın yüz + ChildhoodGround'un yükseltisi, doğumun çiğnenmiş toprağı ve maskesi; pişene dek null): görünen zemin budur.
var steppe: OrdosGround
## Pişmiş yükselti ve maskeler (ChildhoodGround.bake, birth: relief, mask, mask_birth; dağıtım bitince yalnız bunlar tutulur).
var baked: Dictionary = {}
## Bozkırın dağıtım sayıları (kaya, çalı) ve büyük kayaların çarpışma daireleri Vector3(x, z, yarıçap).
var scatter_counts: Dictionary = {}
var solid_rocks: Array[Vector3] = []
## Kurulum ölçüleri: ana iş parçacığında en uzun kare (ms), kare sayısı, toplam (ms), hazır olana dek geçen (ms),
## iş parçacığı işlerinin süresi (ms) ve adım başına en uzun süre (ms).
var build_stats := {"frames": 0, "max_frame_ms": 0.0, "main_ms": 0.0, "ready_ms": 0.0, "jobs_ms": {}, "steps": {}}

var _jobs: Array[_Job] = []
var _steps: Array[Callable] = []
## Yükselti pişti, bozkırın işleri başladı mı?
var _detail_started := false
var _ready_flag := false
var _started_us := 0
var _places: Node3D
var _markers: Node3D
var _cameras: Node3D
var _ground_node: Node3D
var _grass_node: Node3D
var _stakes := PackedVector3Array()
var _site: ChildhoodSite
var _childhood_on := false
var _childhood_samples: Dictionary = {}
var _childhood_minute := CHILDHOOD_START_MINUTE
## Çocukluk açılmadan önceki hâl (kapanınca geri yazılır).
var _saved_view: Dictionary = {}


func _ready() -> void:
	_started_us = Time.get_ticks_usec()
	layout = load_layout(layout_path)
	ground = OrdosGround.new(layout)
	_places = _group("Places")
	_markers = _group("Markers")
	_cameras = _group("Cameras")
	_ground_node = _group("Ground")
	_grass_node = Node3D.new()
	_grass_node.name = "Grass"
	_ground_node.add_child(_grass_node)
	_start_jobs()
	var places: Dictionary = layout.get("places", {})
	_steps.append(_warm_caches.bind(places))
	for id: String in places:
		_steps.append(_build_place.bind(id, places[id]))
	_steps.append(_build_counting_line.bind(layout.get("counting_line", {})))
	_steps.append(_build_markers)
	_steps.append(_build_cameras)
	_steps.append(_build_river)
	set_process(true)


func _exit_tree() -> void:
	# Bitmemiş işler beklenir (WorkerThreadPool her görevin beklenmesini ister); sonuçları atılır.
	for job in _jobs:
		if job.task_id >= 0 and not job.waited:
			WorkerThreadPool.wait_for_task_completion(job.task_id)
			job.waited = true


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
		_finish()


# --- Yüz ------------------------------------------------------------------------------------------

## Dünya kuruldu mu (iş parçacığı işleri bitti, düğümler eklendi)? CineHost segmenti buna göre bekletir.
func is_ready() -> bool:
	return _ready_flag


## Zeminin yüzü (height_at, normal_at): oyuncu, kamera ve dağıtıcı ona sorar (godot.md §4.4). Görünen zeminin yüzüdür: bozkır (steppe; kademe,
## tepe, dere), Çocukluk açıkken onunki (aynı yükseklik, Çocukluk'un çiğnenmiş toprağıyla); pişmeden önce düzenin yalın yüzü.
func get_terrain_shape() -> OrdosGround:
	if _childhood_on and _site and _site.ground:
		return _site.ground
	return steppe if steppe else ground


func get_sky_rig() -> SkyRig:
	return get_node_or_null(^"SkyRig") as SkyRig


## Yerin düğümü (layout "places" kimliği; ör. "lan_yurt"). Yoksa null.
func place(id: String) -> Node3D:
	return _places.get_node_or_null(NodePath(_node_name(id))) as Node3D if _places else null


## Lan Hatun'un yurdunun ocağı.
func hearth() -> HearthEmbers:
	var yurt := place("lan_yurt")
	return yurt.get_node_or_null(^"Hearth") as HearthEmbers if yurt else null


## İşaretin dünya konumu (layout "markers" ya da "childhood.markers" kimliği; ör. "cradle", "pen_gate"), zemine oturur. Yoksa Vector3.INF.
func marker(id: String) -> Vector3:
	var node := _markers.get_node_or_null(NodePath(_node_name(id))) as Node3D if _markers else null
	if node:
		return node.global_position
	var extra: Dictionary = (layout.get("childhood", {}) as Dictionary).get("markers", {})
	var shape := get_terrain_shape()
	if extra.has(id) and shape:
		var at := OrdosGround._vec2(extra[id])
		return Vector3(at.x, shape.height_at(at.x, at.y), at.y)
	return Vector3.INF


## Çekim önerisi: {transform, fov}. Yoksa boş.
func camera_point(id: String) -> Dictionary:
	var node := _cameras.get_node_or_null(NodePath(_node_name(id))) as Node3D if _cameras else null
	if node == null:
		return {}
	return {"transform": node.global_transform, "fov": float(node.get_meta(&"fov", 50.0))}


## Sayım hattının kazıklarının dünya konumları (dipleri, zeminde).
func counting_line_stakes() -> PackedVector3Array:
	return _stakes


## E21 (K98: yurdun içi çatısız diorama gibi yukarıdan): yurdun dış kabuğu, çatı astarı ve dumanı gizlenir, duvar astarının dış yüzü çizilmez
## (PrologueBirth.set_diorama'nın aynısı; doğumun sineması kendi bayrağını tutar). Kapanınca önceki hâl döner.
func set_yurt_diorama(id: String, on: bool) -> void:
	var yurt := place(id)
	if yurt == null:
		return
	var saved: Array = yurt.get_meta(&"diorama_saved", [])
	if on and saved.is_empty():
		for path: NodePath in PrologueBirth.DIORAMA_HIDDEN:
			var node := yurt.get_node_or_null(path) as Node3D
			if node:
				saved.append([node, node.visible])
				node.visible = false
		yurt.set_meta(&"diorama_saved", saved)
	elif not on and not saved.is_empty():
		for pair: Array in saved:
			if is_instance_valid(pair[0]):
				(pair[0] as Node3D).visible = pair[1]
		yurt.remove_meta(&"diorama_saved")
	var wall := yurt.get_node_or_null(PrologueBirth.LINING_WALL) as GeometryInstance3D
	var mat := wall.material_override as ShaderMaterial if wall else null
	if mat:
		mat.set_shader_parameter(PrologueBirth.HIDE_BACK_PARAM, on)


func is_yurt_diorama(id: String) -> bool:
	var yurt := place(id)
	return yurt != null and yurt.has_meta(&"diorama_saved")


# --- Çocukluk ----------------------------------------------------------------------------------------

## Çocukluk'un yerlerini arka planda kurar (gizli). Dünya henüz kurulmadıysa bitince başlar. Döner: site (dünya hazır değilse null).
func prepare_childhood() -> ChildhoodSite:
	if _site:
		return _site
	if not _ready_flag:
		if not world_ready.is_connected(_on_world_ready_for_childhood):
			world_ready.connect(_on_world_ready_for_childhood, CONNECT_ONE_SHOT)
		return null
	if not layout.has("childhood"):
		push_warning("[ordos] düzende childhood bölümü yok")
		return null
	_site = ChildhoodSite.new()
	_site.name = "Childhood"
	_site.visible = false
	_site.built.connect(_on_childhood_built)
	add_child(_site)
	_site.start(self)
	return _site


## Çocukluk'un yerlerini gösterir ya da gizler. Kurulum bitmediyse bitince görünür (childhood_ready); doğumun görüntüsüne geri dönüş tamdır.
func set_childhood_mode(on: bool) -> void:
	if on == _childhood_on:
		return
	_childhood_on = on
	if on:
		prepare_childhood()
	if _site and _site.is_ready():
		_apply_childhood_view(on)


func is_childhood_mode() -> bool:
	return _childhood_on


## Kuruldu mu ve görünür mü?
func is_childhood_ready() -> bool:
	return _site != null and _site.is_ready()


## Çocukluk'un düğümü (yoksa null).
func childhood() -> ChildhoodSite:
	return _site


## Saat (oyunun saati, GameClock; ChildhoodScene 4 Hz, görünür akışta her kare yazar): güneş ve gök gün dakikasına göre; renkler 08:40 ile
## 11:00 örnekleri arasında karışır, güneşin yönü o dakikanın gerçek güneşidir (11:00'ü geçen saatte de ilerler). Kalabalık da bu dakikayla
## toplanır (ChildhoodSite.set_minute). Çocukluk açık değilse yalnız saklanır.
func set_childhood_time(minute: float) -> void:
	_childhood_minute = minute
	if _site:
		_site.set_minute(minute)
	if _childhood_on and is_childhood_ready():
		var rig := get_sky_rig()
		if rig:
			rig.feed_clock(childhood_sample(minute))
		# E21 (K110): gece Lan Hatun'un yurdunun kapısından sıcak ışık sızar (gerçek ışık; öteki kapıların havuzu sahtedir: ChildhoodSite).
		var spill := place("lan_yurt").get_node_or_null(^"DoorSpill") as Light3D if place("lan_yurt") else null
		if spill:
			spill.visible = ChildhoodReaches.night_of(minute) > 0.25


## Yalnız kalabalığın dakikası (her kare; ışık 4 Hz'de set_childhood_time ile).
func set_crowd_minute(minute: float) -> void:
	if _site:
		_site.set_minute(minute)


## Dakikanın ışık örneği (saf değil: dosyayı bir kez okur): renkler dakikayı kuşatan iki örnek arasında, güneş o dakikada. E21 (K110): örnekler
## sabahtan geceye sıralıdır (light.json: dew 07:00 … moon 20:30); sayım günü (08:40–11:00) morning ile late arasında, bugünkü gibi. İlk örnekten
## önce ilk örnek, sondan sonra son örnek (güneş yine o dakikada). Akşamdan geceye ışık aya döner (light_from_moon: ayın yönü, en az 15°).
func childhood_sample(minute: float) -> Dictionary:
	if _childhood_samples.is_empty():
		_childhood_samples = SkyRig.load_samples(CHILDHOOD_LIGHT)
	var pair := sample_pair(_childhood_samples, minute)
	if pair.is_empty():
		return {}
	var a: Dictionary = pair[0]
	var b: Dictionary = pair[1]
	var t: float = pair[2]
	var at := minute if minute >= float(a.get("minute", 0.0)) else float(a.get("minute", minute))
	var out := blend_samples(a, b, t, at)
	var moon_k := lerpf(float(a.get("light_from_moon", 0.0)), float(b.get("light_from_moon", 0.0)), t)
	if moon_k > 0.0 and out.has("moon") and out.has("light_dir"):
		var moon: Dictionary = out["moon"]
		var to_moon := Daylight.light_dir(moon)
		out["light_dir"] = (out["light_dir"] as Vector3).slerp(to_moon, clampf(moon_k, 0.0, 1.0)).normalized()
	return out


## Dakikayı kuşatan iki örnek ve aradaki oran (saf): [a, b, t]; örnekler minute'larına göre sıralanır. Boşsa boş.
static func sample_pair(samples: Dictionary, minute: float) -> Array:
	var list: Array = samples.values()
	if list.is_empty():
		return []
	list.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return float(x.get("minute", 0.0)) < float(y.get("minute", 0.0)))
	if minute <= float((list[0] as Dictionary).get("minute", 0.0)):
		return [list[0], list[0], 0.0]
	# a: dakikası minute'tan küçük ya da eşit son örnek; b: sonraki (minute tam bir örneğin dakikasıysa a odur, t 0).
	for i in range(list.size() - 1, -1, -1):
		var a: Dictionary = list[i]
		if float(a.get("minute", 0.0)) <= minute:
			if i == list.size() - 1:
				return [a, a, 0.0]
			var b: Dictionary = list[i + 1]
			var span := maxf(float(b["minute"]) - float(a["minute"]), 0.001)
			return [a, b, clampf((minute - float(a["minute"])) / span, 0.0, 1.0)]
	return [list[0], list[0], 0.0]


## İki ışık örneğinin ara değeri (saf): sayılar, renkler ve iç sözlükler karışır; güneşin yönü ara dakikadan (ya da verilen dakikadan)
## yeniden hesaplanır.
static func blend_samples(a: Dictionary, b: Dictionary, t: float, at_minute: float = NAN) -> Dictionary:
	var out := {}
	for key: String in a:
		if key in ["sun", "sun_dir", "light_dir", "dec", "moon", "moon_dir"]:
			continue
		out[key] = _blend_value(a[key], b.get(key, a[key]), t)
	if not is_nan(at_minute) and out.has("minute"):
		out["minute"] = at_minute
	return SkyRig.resolve(out)


static func _blend_value(x: Variant, y: Variant, t: float) -> Variant:
	if x is float and y is float:
		return lerpf(x, y, t)
	if x is Color and y is Color:
		return (x as Color).lerp(y, t)
	if x is Dictionary and y is Dictionary:
		var out := {}
		for key: String in x:
			out[key] = _blend_value(x[key], (y as Dictionary).get(key, x[key]), t)
		return out
	return x


## Oyuncunun çarpıştığı daireler Vector3(x, z, yarıçap): yurtlar, doğum yurdunun ocağı, taş, ağılın ve kampın eşyaları, sayım kazıkları, büyük kayalar.
func collect_obstacles() -> Array[Vector3]:
	var out := ChildhoodSite.collision_circles(layout)
	out.append_array(ChildhoodSite.prop_circles(layout))
	if _site:
		out.append_array(_site.solid_rocks)
	return out


## Kapılı duvarlar: doğum yurdu ve ağıl.
func collect_walls() -> Array[RingWall]:
	return ChildhoodSite.collision_walls(layout)


## Kutular: doğum yurdunun döşeği; ağılın kapısı kapalıyken kanadı. Kapı değişince yeniden sorulur.
func collect_boxes() -> Array[ObstacleBox]:
	var out := ChildhoodSite.collision_boxes(layout)
	var pen: Dictionary = (layout.get("childhood", {}) as Dictionary).get("pen", {})
	if not pen.is_empty() and (_site == null or not _site.gate_is_open()):
		out.append(HerdSim.pen_gate_box(pen))
	return out


## Yürünür alan: {center: Vector2, radius, soft_edge, extra: [Vector3(x, z, yarıçap)]} (PlayerController.play_area_*; E21: extra birleşime
## katılır: göle ve Ebe Obası'na giden koridorlar, gölün ve obanın daireleri).
func play_area() -> Dictionary:
	var area: Dictionary = (layout.get("childhood", {}) as Dictionary).get("walk_area", {})
	return {
		"center": OrdosGround._vec2(area.get("center", [0.0, 0.0])),
		"radius": float(area.get("radius", 38.0)),
		"soft_edge": float(area.get("soft_edge", 3.0)),
		"extra": ChildhoodSite.walk_extra(layout),
	}


# --- Kamışlı Göl (E21, K110) ------------------------------------------------------------------------

## Suyun yüzü (x, z): {level, depth (su yüzünden zemine; kuruda ≤ 0), inside, inset (kıyıdan içeri m), deep (en derin bölge mi)}. Göl yoksa
## level NAN. Çocuğun yüzmesi (ChildSwim), sürünün suya inişi ve sesler sorar.
func water_at(x: float, z: float) -> Dictionary:
	var shape := get_terrain_shape()
	if shape == null or shape.lake_half_width <= 0.0:
		return {"level": NAN, "depth": 0.0, "inside": false, "inset": -1.0e6, "deep": false}
	var out := shape.water_at(x, z)
	var core := float(lake_def().get("deep_core", 7.5))
	out["deep"] = bool(out["inside"]) and shape.lake_distance(x, z) < core
	return out


## Gölün tanımı (layout "childhood.lake"; yoksa boş). Göl yalnız Çocukluk'un yüzündedir: doğumda water_at kurudur.
func lake_def() -> Dictionary:
	return (layout.get("childhood", {}) as Dictionary).get("lake", {})


## Gölün ölçüleri (düzenden; yoksa boş): {level, half_width, deep_core, line: PackedVector2Array}.
func lake_info() -> Dictionary:
	var shape := get_terrain_shape()
	if shape == null or shape.lake_half_width <= 0.0:
		return {}
	return {"level": shape.lake_level, "half_width": shape.lake_half_width, "line": shape.lake_points,
		"deep_core": float(lake_def().get("deep_core", 7.5))}


## Oynanış kamera sınırı (x, z).
func camera_bounds() -> Rect2:
	return ChildhoodSite.bounds_rect(layout.get("childhood", {}))


## Kamerayı sınırın içine çeker ve odağa çevirir (saf): sınırın içindeyken dönüşüm değişmez.
static func clamp_to_bounds(xform: Transform3D, focus: Vector3, bounds: Rect2) -> Transform3D:
	var o := xform.origin
	var inside := Vector2(clampf(o.x, bounds.position.x, bounds.end.x), clampf(o.z, bounds.position.y, bounds.end.y))
	if inside.x == o.x and inside.y == o.z:
		return xform
	var at := Vector3(inside.x, o.y, inside.y)
	var look := focus - at
	if look.length_squared() < 0.000001:
		return Transform3D(xform.basis, at)
	return Transform3D(Basis.looking_at(look, Vector3.UP), at)


## Takip kamerasının dönüşümünü oynanış sınırına uydurur.
func clamp_camera_transform(xform: Transform3D, focus: Vector3) -> Transform3D:
	return clamp_to_bounds(xform, focus, camera_bounds())


func _on_world_ready_for_childhood() -> void:
	prepare_childhood()


func _on_childhood_built() -> void:
	if _childhood_on:
		_apply_childhood_view(true)
	else:
		_site.process_mode = Node.PROCESS_MODE_DISABLED
	childhood_ready.emit()


## Çocukluk'un görüntüsü: ayrı düğüm görünür, doğumun zemini, otu, çiğnenmiş toprağı, kayası ve çalısı yerini verir (Çocukluk'unkiler aynı yerdedir),
## gün ışığı gelir, yurdun gece ışıkları söner.
func _apply_childhood_view(on: bool) -> void:
	_site.visible = on
	_site.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	if _grass_node:
		_grass_node.visible = not on
	for path: NodePath in [^"Ground/Trampled", ^"Ground/Terrain", ^"Ground/Rocks", ^"Ground/Shrubs"]:
		var node := get_node_or_null(path) as Node3D
		if node:
			node.visible = not on
	var rig := get_sky_rig()
	var sun := get_node_or_null(^"SunLight") as DirectionalLight3D
	var spill := place("lan_yurt").get_node_or_null(^"DoorSpill") as Light3D if place("lan_yurt") else null
	var ember := hearth().get_node_or_null(^"EmberLight") as Light3D if hearth() else null
	if on:
		_saved_view = {"sample": rig.current_sample() if rig else {}}
		if spill:
			_saved_view["spill"] = spill.visible
			spill.visible = false
		if ember:
			_saved_view["ember_shadow"] = ember.shadow_enabled
			ember.shadow_enabled = false
		if sun:
			# Şafağın yumuşak gölgesi (PCSS) gündüz kısa gölgede beneklenir: gün ışığı keskin kenarlı, süzgeçle yumuşar.
			_saved_view["sun_angular"] = sun.light_angular_distance
			sun.light_angular_distance = 0.0
		if rig:
			rig.feed_clock(childhood_sample(_childhood_minute))
	else:
		if spill and _saved_view.has("spill"):
			spill.visible = bool(_saved_view["spill"])
		if ember and _saved_view.has("ember_shadow"):
			ember.shadow_enabled = bool(_saved_view["ember_shadow"])
		if sun and _saved_view.has("sun_angular"):
			sun.light_angular_distance = float(_saved_view["sun_angular"])
		var sample: Dictionary = _saved_view.get("sample", {})
		if rig and not sample.is_empty():
			rig.feed_clock(sample)
		_saved_view = {}


## Düzen dosyası (JSON sözlüğü; okunamazsa boş).
static func load_layout(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("[ordos] düzen dosyası yok: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## layout kimliği → düğüm adı ("lan_yurt" → "LanYurt").
static func _node_name(id: String) -> String:
	return id.to_pascal_case()


# --- İş parçacığı işleri -----------------------------------------------------------------------------

## İş parçacığında koşan üretim: fn sonuç sözlüğünü döner. Sonuç kendi alanındadır; ana iş parçacığı yalnız iş bitince okur. Bantlı işlerin
## (bake, ground, grass) her bandı bir iştir (band sırası).
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


## Önce yükselti ve maske pişer (satır bantları); bitince bozkırın işleri başlar (_on_baked).
func _start_jobs() -> void:
	# İşlerin kullandığı sınıflar ana iş parçacığında yüklensin (betik ilk kez iş parçacığında yüklenmesin).
	Meadow.tuft_aspect(0.2)
	Scatter.is_blocked(0.0, 0.0, [], 0.0)
	FaunaMesh.Draft.new()
	ChildhoodScatter.keep_outs({})
	ChildhoodSite.bounds_rect({})
	var g := ChildhoodGround.grid(layout)
	if g.is_empty():
		_on_baked([] as Array[_Job])
		return
	var k := 0
	for band in ChildhoodGround.row_bands(g, JOB_BANDS):
		# Her bant düzenin kendi kopyasını okur: paylaşılan sözlüğün ve dizinin sayacı (her okumada artar) iş parçacıklarını birbirine
		# bekletmesin (aynı kopyayla sekiz bant tek bandın süresini sürüyordu).
		var spec := layout.duplicate(true)
		_start_job("bake", k, func() -> Dictionary: return ChildhoodGround.bake_rows(spec, band.x, band.y, true))
		k += 1


func _start_job(kind: String, band: int, fn: Callable) -> void:
	var job := _Job.new()
	job.kind = kind
	job.band = band
	job.fn = fn
	job.task_id = WorkerThreadPool.add_task(job.run, true, "ordos %s %d" % [kind, band])
	_jobs.append(job)


## Yükselti ve maskeler hazır: bozkırın yüzü kurulur, arazinin bantları, otun bantları ve dağıtım başlar; çiğnenmiş toprağın katmanı
## (yalnız malzemesi) bir adımdır.
func _on_baked(bands: Array[_Job]) -> void:
	var parts: Array = []
	for job in bands:
		parts.append(job.result)
		job.result = {}
		job.applied = true
	baked = ChildhoodGround.join_rows(ChildhoodGround.grid(layout), parts, true) if not bands.is_empty() else {}
	var spec := steppe_spec(layout, baked)
	steppe = OrdosGround.new(spec)
	var rows := steppe.row_count()
	# Her iş tanımın kendi derin kopyasını okur (_start_jobs'taki gibi).
	for k in JOB_BANDS:
		var a := rows * k / JOB_BANDS
		var b := rows * (k + 1) / JOB_BANDS
		var band_spec := spec.duplicate(true)
		_start_job("ground", k, func() -> Dictionary: return OrdosGround.new(band_spec).build_rows(a, b))
	_steps.push_back(_add_trampled_layer)
	for k in JOB_BANDS:
		var grass_spec := spec.duplicate(true)
		grass_spec["grass"] = (layout.get("grass", {}) as Dictionary).duplicate(true)
		var blockers := grass_blockers(layout)
		_start_job("grass", k, func() -> Dictionary: return OrdosWorld.grass_buffers(grass_spec, blockers, k, JOB_BANDS))
	if not baked.is_empty():
		# Doğumun kayası ve çalısı Çocukluk'unkilerle aynı yerde; E21'in göle ve obaya giden dağıtımı yalnız Çocukluk'ta (birth_spec).
		var child_spec := birth_spec(ChildhoodSite.baked_spec(layout, baked))
		_start_job("scatter", 0, func() -> Dictionary: return ChildhoodScatter.build(child_spec))
	_detail_started = true


## Bozkırın yüzünün tanımı (saf): Çocukluk'unkiyle aynı yükselti ve düz yerler (yükseklik aynıdır), doğumun çiğnenmiş toprağı ve maskesi.
static func steppe_spec(p_layout: Dictionary, p_baked: Dictionary) -> Dictionary:
	var spec := birth_spec(ChildhoodSite.baked_spec(p_layout, p_baked))
	spec["trampled"] = (p_layout.get("trampled", {}) as Dictionary).duplicate(true)
	if p_baked.has("mask_birth"):
		spec["ground_mask"] = p_baked["mask_birth"]
	return spec


## Çocukluk'un yüzünün tanımından doğumunki (E21, K110): Kamışlı Göl, geniş sık ızgara ve E21'in dağıtımı çıkar (doğumun bozkırı bugünkü gibi;
## göl ve oba yalnız Çocukluk'tadır). Tanım yerinde değişir, döner.
static func birth_spec(spec: Dictionary) -> Dictionary:
	spec.erase("lake")
	var g: Dictionary = spec.get("ground", {})
	g.erase("dense")
	g.erase("grid_normals")
	spec["e21_scatter"] = false
	return spec


func _poll_jobs() -> void:
	var finished := {}
	for job in _jobs:
		if job.waited or not WorkerThreadPool.is_task_completed(job.task_id):
			continue
		WorkerThreadPool.wait_for_task_completion(job.task_id)
		job.waited = true
		var jobs_ms: Dictionary = build_stats["jobs_ms"]
		jobs_ms[job.kind] = maxf(float(jobs_ms.get(job.kind, 0.0)), job.ms)
		finished[job.kind] = true
	# Bantların hepsi bitince işlenir (sırayla).
	for kind: String in finished:
		var group: Array[_Job] = []
		for job in _jobs:
			if job.kind == kind:
				group.append(job)
		if group.any(func(job: _Job) -> bool: return not job.waited):
			continue
		group.sort_custom(func(a: _Job, b: _Job) -> bool: return a.band < b.band)
		match kind:
			"bake":
				_on_baked(group)
			"ground":
				_steps.push_front(_apply_ground.bind(group))
			"grass":
				_queue_grass(group)
			"scatter":
				_steps.push_back(_apply_scatter.bind(group[0]))


func _jobs_done() -> bool:
	if not _detail_started:
		return false
	for job in _jobs:
		if not job.applied:
			return false
	return true


func _finish() -> void:
	_ready_flag = true
	build_stats["ready_ms"] = (Time.get_ticks_usec() - _started_us) / 1000.0
	var rig := get_sky_rig()
	if rig:
		rig.refresh()
	set_process(false)
	world_ready.emit()


# --- Zemin ------------------------------------------------------------------------------------------

## Bozkırın zemini: arazinin bantları tek ağda, maskeli gölgelendirici (doğumun maskesi).
func _apply_ground(bands: Array[_Job]) -> void:
	var parts: Array = []
	for job in bands:
		parts.append(job.result)
	var mi := MeshInstance3D.new()
	mi.name = "Terrain"
	mi.mesh = OrdosGround.make_mesh(steppe.join_rows(parts))
	mi.material_override = steppe_material(baked.get("mask_birth", {}))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta(&"free_asset", ["withered_grass", "dry_ground_rocks", "dirt"])
	_ground_node.add_child(mi)
	_ground_node.move_child(mi, 0)
	for job in bands:
		job.applied = true
		job.result = {}


## Çiğnenmiş toprağın katmanı: doğumda ağı yoktur. Avlu, kapı önleri ve izler bozkırın maskesinde dokulu açık topraktır (ChildhoodGround
## doğumun çiğnenmiş toprağını maskeye işler, ot oralarda çıkmaz): düz boyalı üst katman yukarıdan büyük kahverengi lekeler gibi okunuyordu.
## Düğüm katmanın malzemesini (ordos_ground.gdshader mode 1, doğumun bölgeleri) taşır: Çocukluk'un üst katmanı ondan kurulur.
func _add_trampled_layer() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Trampled"
	mi.mesh = ArrayMesh.new()
	mi.material_override = _ground_material(1, FREE_TRAMPLED[1])
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta(&"free_asset", FREE_TRAMPLED[0])
	_ground_node.add_child(mi)


## Kaya öbekleri ve çalı (Çocukluk'unkilerle aynı yerde ve aynı malzemeyle): Ground/Rocks, Ground/Shrubs.
func _apply_scatter(job: _Job) -> void:
	var data := job.result
	solid_rocks = data.get("solid", solid_rocks)
	scatter_counts = data.get("counts", {})
	for node in ChildhoodSite.scatter_nodes(data, ChildhoodSite.make_rock_material()):
		_ground_node.add_child(node)
	job.applied = true
	job.result = {}


## Bozkırın zemininin malzemesi (childhood_ground.gdshader; doğumun ve Çocukluk'un zemini): üç ücretsiz doku metre ölçeğinde, maske ve
## maskenin dikdörtgeni. Maske boşsa ot dibi.
func steppe_material(mask: Dictionary) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = STEPPE_SHADER
	var textures := ground_textures()
	mat.set_shader_parameter(&"grass_tex", textures[0])
	mat.set_shader_parameter(&"gravel_tex", textures[1])
	mat.set_shader_parameter(&"soil_tex", textures[2])
	if not mask.is_empty():
		mat.set_shader_parameter(&"mask_tex", ChildhoodGround.mask_texture(mask))
		mat.set_shader_parameter(&"mask_rect", ChildhoodGround.mask_rect(mask))
	return mat


## Zemin gölgelendiricisinin malzemesi (mode 0 zemin, 1 çiğnenmiş toprak); renkler layout "colors"tan.
func _ground_material(mode: int, texture_path: String) -> ShaderMaterial:
	var colors: Dictionary = layout.get("colors", {})
	var mat := ShaderMaterial.new()
	mat.shader = GROUND_SHADER
	mat.set_shader_parameter("mode", mode)
	var keys := ["ground", "ground_sunny", "ground_dark"] if mode == 0 else ["trampled", "trampled_light", "trampled_edge"]
	for i in keys.size():
		if colors.has(keys[i]):
			mat.set_shader_parameter(["base_color", "sunny_color", "dark_color"][i], SkyRig.to_color(colors[keys[i]]))
	if colors.has("trampled_tint"):
		mat.set_shader_parameter("trampled_tint", SkyRig.to_color(colors["trampled_tint"]))
	mat.set_shader_parameter("mottle_tex", _texture(texture_path))
	mat.set_shader_parameter("mottle_tile", 9.0 if mode == 0 else 5.0)
	var zones := ground.ground_uniforms(MAX_CIRCLES, MAX_TRAILS)
	for key: String in zones:
		mat.set_shader_parameter(key, zones[key])
	return mat


# --- Ot ---------------------------------------------------------------------------------------------

## Otun engelleri (saf): yurtların tabanları Vector3(x, z, yarıçap).
static func grass_blockers(spec: Dictionary) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var places: Dictionary = spec.get("places", {})
	for id: String in places:
		var def: Dictionary = places[id]
		var at := OrdosGround._vec2(def.get("at", [0.0, 0.0]))
		out.append(Vector3(at.x, at.y, float(def.get("radius", 3.0)) + 0.35))
	return out


## Ot tutamlarının MultiMesh tamponları (saf, iş parçacığında): Vector3i(parça x, parça z, çeşit) →
## PackedFloat32Array (örnek başına 12 dönüşüm + 4 özel veri: r, g ton, b yön sapması, a renk lekesi; atw_grass).
## Ot, çiğnenmiş toprakta ve yurtların altında çıkmaz; çayırın kenarına doğru seyrekleşir. bands > 1 ise ızgaranın x sütunları o kadar banda
## bölünür ve yalnız band'ınki üretilir (iş parçacığı başına bir bant; her bandın kendi tohumu): bantların birleşimi (merge_grass) belirlidir.
## bands = 1 tek parçalı üretimdir (Çocukluk'un otu).
static func grass_buffers(spec: Dictionary, blockers: Array[Vector3], band: int = 0, bands: int = 1, skip: Array[Vector3] = []) -> Dictionary:
	var shape := OrdosGround.new(spec)
	var g: Dictionary = spec.get("grass", {})
	var seed_value := int(g.get("seed", 77))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value if bands <= 1 else seed_value + 7919 * (band + 1)
	var center := OrdosGround._vec2(g.get("center", [0.0, 0.0]))
	var radius := float(g.get("radius", 60.0))
	var count := maxi(int(g.get("count", 12000)), 1)
	var chunk := float(g.get("chunk", 20.0))
	var tall_share := float(g.get("tall_share", 0.3))
	var short_h := OrdosGround._vec2(g.get("short_height", [0.18, 0.32]))
	var tall_h := OrdosGround._vec2(g.get("tall_height", [0.42, 0.66]))
	var clump := OrdosGround._noise(seed_value + 5, 0.07, 2)
	var tall_noise := OrdosGround._noise(seed_value + 9, 0.05, 2)
	var patch := OrdosGround._noise(seed_value + 17, 0.09, 3)
	var cell := sqrt(PI * radius * radius / float(count))
	var n := ceili(radius / cell)
	var out := {}
	# Bozkırın zemin maskesi (ChildhoodGround; doğumun ya da Çocukluk'un): çakılda ve kumda seyrek, koyu otlukta sık ve uzun.
	var mask: Dictionary = spec.get("ground_mask", {})
	var columns := 2 * n
	var parts := maxi(bands, 1)
	for ix in range(-n + columns * band / parts, -n + columns * (band + 1) / parts):
		for iz in range(-n, n):
			var p := center + Vector2(float(ix) + rng.randf(), float(iz) + rng.randf()) * cell
			var dist := p.distance_to(center)
			if dist > radius or Scatter.is_blocked(p.x, p.y, blockers, 0.1) or (not skip.is_empty() and Scatter.is_blocked(p.x, p.y, skip, 0.0)):
				continue
			# E21: ot suda çıkmaz (Kamışlı Göl; kıyı çizgisinden 0,5 m içeri).
			if shape.lake_half_width > 0.0 and shape.lake_box.has_point(p) and shape.lake_distance(p.x, p.y) < shape.lake_half_width + 0.5:
				continue
			var trampled := shape.trampled_weight(p)
			var density := (1.0 - smoothstep(radius * 0.7, radius, dist)) * (1.0 - trampled)
			density *= lerpf(0.5, 1.1, clump.get_noise_2d(p.x, p.y) * 0.5 + 0.5)
			var lush := 0.0
			if not mask.is_empty():
				var m := ChildhoodGround.mask_at(mask, p.x, p.y)
				lush = m.w
				density *= (1.0 - 0.6 * m.x) * (1.0 - 0.97 * m.y) * (1.0 - 0.85 * m.z) * (0.72 + 0.6 * m.w)
			if rng.randf() > density:
				continue
			var tall := rng.randf() < tall_share * (1.0 + lush * 1.2) * smoothstep(-0.2, 0.4, tall_noise.get_noise_2d(p.x, p.y)) * 2.0
			var variant := TUFT_VARIANTS.size() - 1 if tall else rng.randi() % (TUFT_VARIANTS.size() - 1)
			var span := tall_h if tall else short_h
			# Çiğnenmiş toprağın kenarında ot ezik ve kısadır.
			var h := rng.randf_range(span.x, span.y) * lerpf(1.0, 0.55, smoothstep(0.0, 0.4, trampled))
			var w := h * Meadow.tuft_aspect(h) * rng.randf_range(0.9, 1.15)
			var y := shape.height_at(p.x, p.y) - 0.02
			var key := Vector3i(floori(p.x / chunk), floori(p.y / chunk), variant)
			var buffer: PackedFloat32Array = out.get(key, PackedFloat32Array())
			# Sözlükten çıkarılınca tampon tek sahiplidir: ekleme yerinde olur (her tutamda bütün parçanın kopyası alınmaz). Sıra
			# değişir, içerik değişmez (anahtarlar kurulurken sıralanır).
			out.erase(key)
			buffer.append_array(PackedFloat32Array([w, 0.0, 0.0, p.x, 0.0, h, 0.0, y, 0.0, 0.0, w, p.y,
				rng.randf(), rng.randf(), rng.randf(), clampf(patch.get_noise_2d(p.x, p.y) * 0.5 + 0.5, 0.0, 1.0)]))
			out[key] = buffer
	return out


## Otun bantlarını (grass_buffers, band sırasıyla) birleştirir: aynı parçanın tamponları ardı ardına.
static func merge_grass(parts: Array) -> Dictionary:
	var out := {}
	for part: Dictionary in parts:
		for key: Vector3i in part:
			var buffer: PackedFloat32Array = out.get(key, PackedFloat32Array())
			out.erase(key)
			buffer.append_array(part[key])
			out[key] = buffer
	return out


## Otun parçalarını adımlara böler (her adım birkaç MultiMesh; kare bütçesi aşılmasın). Bantlar önce birleşir (ilk bandın sonucuna).
func _queue_grass(bands: Array[_Job]) -> void:
	var parts: Array = []
	for b in bands:
		parts.append(b.result)
	var job := bands[0]
	job.result = merge_grass(parts)
	for b in bands:
		if b != job:
			b.result = {}
			b.applied = true
	var keys: Array = job.result.keys()
	keys.sort()
	var meshes: Array[Mesh] = []
	for v in TUFT_VARIANTS:
		meshes.append(Meadow.tuft_mesh(v.x, v.y, float(v.z) / 100.0, v.w, Meadow.BLADE_WIDTH.x if v.w == 1 else Meadow.BLADE_WIDTH.y))
	var mat := grass_material(layout.get("grass", {}))
	const PER_STEP := 12
	for start in range(0, keys.size(), PER_STEP):
		_steps.push_front(_apply_grass_slice.bind(job, keys.slice(start, start + PER_STEP), meshes, mat))
	_steps.push_back(_mark_applied.bind(job))
	if keys.is_empty():
		job.applied = true


func _mark_applied(job: _Job) -> void:
	job.applied = true
	job.result = {}


func _apply_grass_slice(job: _Job, keys: Array, meshes: Array[Mesh], mat: ShaderMaterial) -> void:
	for key: Vector3i in keys:
		var buffer: PackedFloat32Array = job.result[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = meshes[key.z]
		mm.instance_count = buffer.size() / FLOATS_PER_TUFT
		mm.buffer = buffer
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Grass_%d_%d_%d" % [key.x, key.y, key.z]
		mmi.multimesh = mm
		mmi.material_override = mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_grass_node.add_child(mmi)


## Otun malzemesi: renkler layout "colors"tan, rüzgâr ve sönme g'den (doğumun ya da Çocukluk'un otu).
func grass_material(g: Dictionary) -> ShaderMaterial:
	var colors: Dictionary = layout.get("colors", {})
	var mat := ShaderMaterial.new()
	mat.shader = GRASS_SHADER
	mat.set_shader_parameter("instance_patches", true)
	for key in ["root_color", "mid_color", "tip_color", "sun_color", "deep_color"]:
		if colors.has("grass_" + key):
			mat.set_shader_parameter(key, SkyRig.to_color(colors["grass_" + key]))
	if colors.has("ground"):
		mat.set_shader_parameter("root_color", SkyRig.to_color(colors["ground"]))
	mat.set_shader_parameter("wind_strength", float(g.get("wind_strength", 0.09)))
	mat.set_shader_parameter("fade_start", float(g.get("fade_start", 28.0)))
	mat.set_shader_parameter("fade_end", float(g.get("fade_end", 44.0)))
	mat.set_shader_parameter("shadow_tint", SkyRig.to_color(colors.get("shadow_tint", [0.62, 0.68, 0.84])))
	return mat


# --- Yerler -----------------------------------------------------------------------------------------

## Yerlerin ortak önbellekleri (damga dokusu) kendi adımında ısınır: yurdun adımı bir kareyi aşmasın. Kampta zaten
## ısınmıştır (Önsöz'de kamp önce kurulur).
func _warm_caches(places: Dictionary) -> void:
	for def: Dictionary in places.values():
		if float(def.get("emblem_angle", 0.0)) != 0.0:
			Style.tamga_texture()
			return


## Yurt (kabuk). Doğum yurdunun içi ve ocağı sonraki adımlardadır (kare bütçesi).
func _build_place(id: String, def: Dictionary) -> void:
	var at := OrdosGround._vec2(def.get("at", [0.0, 0.0]))
	var yurt: Yurt = BirthYurt.new() if str(def.get("kind", "yurt")) == "birth_yurt" else Yurt.new()
	yurt.name = _node_name(id)
	yurt.radius = float(def.get("radius", 3.0))
	if def.has("felt"):
		yurt.felt_color = SkyRig.to_color(def["felt"])
	yurt.has_smoke = bool(def.get("smoke", true))
	yurt.hanging_angle = float(def.get("hanging_angle", 0.0))
	yurt.emblem_angle = float(def.get("emblem_angle", 0.0))
	yurt.interior_light_energy = float(def.get("interior_light", yurt.interior_light_energy))
	yurt.transform = Transform3D(door_basis(float(def.get("door_az", 90.0))), Vector3(at.x, ground.height_at(at.x, at.y), at.y))
	if yurt is BirthYurt:
		(yurt as BirthYurt).floor_texture = _texture(FREE_FLOOR[1])
		(yurt as BirthYurt).defer_interior = true
		_steps.push_front(_build_hearth.bind(yurt, def.get("hearth", {})))
		_steps.push_front((yurt as BirthYurt).build_interior_parts)
	_places.add_child(yurt)
	_clean_steps(yurt)


## Kapı basamaklarının yosunu (Yurt'un taş gölgelendiricisi) kampın gece ayarı içindir; şafak ışığında yeşil leke
## olur: Ordos'un kuru güz otlağında yosun yoktur. Malzeme yurdun kendisinindir (kampı etkilemez).
static func _clean_steps(yurt: Node) -> void:
	for step in ["Step0", "Step1"]:
		var mi := yurt.get_node_or_null(NodePath(step)) as MeshInstance3D
		var mat := mi.material_override as ShaderMaterial if mi else null
		if mat:
			mat.set_shader_parameter("moss_amount", 0.0)


## Doğum yurdunun ocağı (HearthEmbers): yurdun çocuğu, üretilmiş değil (yurt yeniden kurulsa da kalır).
func _build_hearth(yurt: Yurt, def: Dictionary) -> void:
	if def.is_empty() or not is_instance_valid(yurt):
		return
	var hearth := HearthEmbers.new()
	hearth.name = "Hearth"
	hearth.ash_texture = _texture(FREE_ASH[1])
	var local := OrdosGround._vec2(def.get("at", [0.0, 0.0]))
	hearth.position = Vector3(local.x, 0.0, local.y)
	hearth.light_energy = float(def.get("light_energy", hearth.light_energy))
	hearth.light_range = float(def.get("light_range", hearth.light_range))
	yurt.add_child(hearth)


## Kapının pusula yönünden (0 kuzey, 90 doğu) yurdun dönüşü: yurdun yerel +Z'si (kapısı) o yöne bakar.
static func door_basis(door_az: float) -> Basis:
	return Basis(Vector3.UP, deg_to_rad(180.0 - door_az))


## Sayım hattı: from'dan to'ya kazık sırası, kazıkların tepesinden sarkan ip.
func _build_counting_line(def: Dictionary) -> void:
	if def.is_empty():
		return
	var line := Node3D.new()
	line.name = "CountingLine"
	_places.add_child(line)
	var a := OrdosGround._vec2(def.get("from", [0.0, 0.0]))
	var b := OrdosGround._vec2(def.get("to", [0.0, 1.0]))
	var count := maxi(int(def.get("stakes", 11)), 2)
	var height := float(def.get("height", 1.05))
	var sag := float(def.get("sag", 0.12))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(def.get("seed", 31))
	var post := Procedural3D.cylinder(0.032, 0.045, height + 0.25, 7)
	var stakes := SurfaceTool.new()
	stakes.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tops := PackedVector3Array()
	_stakes = PackedVector3Array()
	for i in count:
		var p := a.lerp(b, float(i) / float(count - 1))
		var y := ground.height_at(p.x, p.y)
		var tilt := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, deg_to_rad(rng.randf_range(-4.0, 4.0)))
		stakes.append_from(post, 0, Transform3D(tilt, Vector3(p.x, y + (height + 0.25) * 0.5 - 0.25, p.y)))
		_stakes.append(Vector3(p.x, y, p.y))
		tops.append(Vector3(p.x, y + height - 0.04, p.y))
	var stakes_mi := MeshInstance3D.new()
	stakes_mi.name = "Stakes"
	stakes_mi.mesh = stakes.commit()
	stakes_mi.material_override = Style.toon(Style.WOOD.darkened(0.1), {"stripe_count": 6.0, "stripe_strength": 0.3})
	line.add_child(stakes_mi)
	var rope_mi := MeshInstance3D.new()
	rope_mi.name = "Rope"
	rope_mi.mesh = rope_mesh(tops, sag, 0.012)
	rope_mi.material_override = Style.toon(Color(0.7, 0.6, 0.44))
	line.add_child(rope_mi)


## İp (saf): ardışık noktalar arasında sarkan (parabol) ince dört yüzlü boru.
static func rope_mesh(points: PackedVector3Array, sag: float, thickness: float, segments: int = 8) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var path := PackedVector3Array()
	for i in points.size() - 1:
		for k in segments:
			var t := float(k) / float(segments)
			path.append(points[i].lerp(points[i + 1], t) + Vector3.DOWN * sag * 4.0 * t * (1.0 - t))
	if points.size() > 0:
		path.append(points[points.size() - 1])
	for i in path.size() - 1:
		var d := (path[i + 1] - path[i]).normalized()
		var side := d.cross(Vector3.UP).normalized() * thickness
		var up := side.cross(d).normalized() * thickness
		var ring: Array[Vector3] = [side, up, -side, -up]
		for r in 4:
			var r2 := (r + 1) % 4
			var quad: Array[Vector3] = [path[i] + ring[r], path[i + 1] + ring[r], path[i] + ring[r2], path[i + 1] + ring[r2]]
			var n := (ring[r] + ring[r2]).normalized()
			for idx in [0, 2, 1, 1, 2, 3]:
				st.set_normal(n)
				st.add_vertex(quad[idx])
	return st.commit()


func _build_markers() -> void:
	var markers: Dictionary = layout.get("markers", {})
	for id: String in markers:
		var at := OrdosGround._vec2(markers[id])
		var m := Marker3D.new()
		m.name = _node_name(id)
		m.position = Vector3(at.x, ground.height_at(at.x, at.y), at.y)
		_markers.add_child(m)


func _build_cameras() -> void:
	var cameras: Dictionary = layout.get("cameras", {})
	for id: String in cameras:
		var def: Dictionary = cameras[id]
		var pos := Vector3(float(def["pos"][0]), float(def["pos"][1]), float(def["pos"][2]))
		var target := Vector3(float(def["look_at"][0]), float(def["look_at"][1]), float(def["look_at"][2]))
		var m := Marker3D.new()
		m.name = _node_name(id)
		m.transform = Transform3D(Basis.looking_at(target - pos, Vector3.UP), pos)
		m.set_meta(&"fov", float(def.get("fov", 50.0)))
		_cameras.add_child(m)


## Ufukta Sarı Irmak: su seviyesinde, ırmağın yatağını örten uzun bir dörtgen (water.gdshader; kıyı çizgisi zeminin
## suyla kesiştiği yerde kendiliğinden oluşur). Parıltının yönünü SkyRig yazar (güneş ufuktayken güneş).
func _build_river() -> void:
	var colors: Dictionary = layout.get("colors", {})
	var plane := PlaneMesh.new()
	var reach := ground.river_width + ground.river_bank * 2.0 + ground.river_meander * 2.0 + 40.0
	plane.size = Vector2(reach, ground.far * 2.0)
	var mat := ShaderMaterial.new()
	mat.shader = WATER_SHADER
	var keys := {"river_deep": "deep_color", "river_shallow": "shallow_color", "river_horizon": "reflection_horizon",
		"river_zenith": "reflection_zenith", "river_glint": "glint_color"}
	for key: String in keys:
		if colors.has(key):
			mat.set_shader_parameter(keys[key], SkyRig.to_color(colors[key]))
	mat.set_shader_parameter("ripple_a", _ripple_texture(19, 0.035))
	mat.set_shader_parameter("ripple_b", _ripple_texture(43, 0.06))
	mat.set_shader_parameter("glint_energy", 6.0)
	var mi := MeshInstance3D.new()
	mi.name = "River"
	mi.mesh = plane
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(ground.center.x + ground.river_x, ground.water_level, ground.center.y)
	add_child(mi)


static func _ripple_texture(noise_seed: int, frequency: float) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.seed = noise_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	noise.fractal_octaves = 3
	var tex := NoiseTexture2D.new()
	tex.width = 128
	tex.height = 128
	tex.seamless = true
	tex.as_normal_map = true
	tex.bump_strength = 6.0
	tex.noise = noise
	return tex


# --- Yardımcılar ------------------------------------------------------------------------------------

func _group(group_name: String) -> Node3D:
	var node := get_node_or_null(NodePath(group_name)) as Node3D
	if node == null:
		node = Node3D.new()
		node.name = group_name
		add_child(node)
	return node


## Sahnenin ücretsiz dokuları: [zemin, çiğnenmiş toprak, yurdun tabanı] (Çocukluk'un zemini aynı dokuları metre ölçeğinde okur).
func ground_textures() -> Array[Texture2D]:
	return [_texture(FREE_GROUND[1]), _texture(FREE_TRAMPLED[1]), _texture(FREE_FLOOR[1])]


## Doku: önce sahneyle birlikte yüklenenlerden (preloaded), yoksa ResourceLoader'dan (önbellekteyse oradan).
func _texture(path: String) -> Texture2D:
	for res in preloaded:
		if res is Texture2D and res.resource_path == path:
			return res
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


# --- Doğum yurdu ------------------------------------------------------------------------------------

## Lan Hatun'un yurdu: Yurt'un kabuğu (Meshy modeli ya da kodla çizilen yedek) ve kapıdan dışarı sızan sıcak ışık;
## içi gerçektir: sahte kapı parıltısı ve kapı dibindeki küçük ocak yoktur (ocak ortadadır, HearthEmbers), içeriyi
## köz ışığı aydınlatır. İç: toprak taban (Floor; ücretsiz doku dirt), kerege astarı (Lining: duvar ve uuk; modelin
## iç ölçüleriyle, assets/structures/yurt/yurt_fit.json), keçeler (FeltTor, FeltBed, FeltSouth; şırdak) ve kase (Bowl).
## Kapı yerel +Z'dir; kapıdan girince sağ (yerel +X) kadınların yanıdır: doğum döşeği oradadır.
class BirthYurt:
	extends Yurt

	const KEREGE_SHADER := preload("res://shaders/kerege.gdshader")
	const SHYRDAK_SHADER := preload("res://shaders/shyrdak.gdshader")
	const GROUND_SHADER := preload("res://assets/maps/ordos/ordos_ground.gdshader")
	const FIT_PATH := "res://assets/structures/yurt/yurt_fit.json"
	const FLOOR_ASSET_ID := "dirt"
	## Astarın duvarı (yarıçapa oran): modelin iç duvarının en içteki ölçüsünün (0,77–0,82) içinde.
	const LINING_RATIO := 0.76
	## Astarın modelin çatısından içeri payı (metre).
	const LINING_MARGIN := 0.09
	## Toprak tabanın yarıçapı (yarıçapa oran; kenarı astarın ve duvarın altında kalır).
	const FLOOR_RATIO := 0.8
	## Astarın keçesi ve kafesi: içeride isli, eskimiş keçe ve koyu kızıl boyalı kerege (köz ışığında okunur).
	const LINING_FELT := Color(0.66, 0.6, 0.5)
	const LINING_LATTICE := Color(0.5, 0.18, 0.09)

	var floor_texture: Texture2D
	## İç (taban, astar, keçeler, kase) kabuktan ayrı adımda kurulsun mu (OrdosWorld'ün kare bütçesi)?
	## build_interior_parts çağrılınca false olur: sonraki yeniden üretimler içi de kurar.
	var defer_interior := false

	func _build_door_glow() -> void:
		pass

	func _build_hearth() -> void:
		pass

	func _build_interior() -> void:
		pass

	## Yalnız kapıdan dışarı sızan sıcak ışık; içeriyi köz ışığı (HearthEmbers) aydınlatır.
	func _build_lights() -> void:
		var spill := SpotLight3D.new()
		spill.name = "DoorSpill"
		spill.light_color = interior_light_color
		spill.light_energy = interior_light_energy * 1.4
		spill.spot_range = 5.0
		spill.spot_angle = 36.0
		spill.spot_angle_attenuation = 1.6
		spill.light_volumetric_fog_energy = 1.2
		spill.light_cull_mask = 0xFFFFFFFF ^ MODEL_RENDER_LAYER
		var origin := Vector3(0.0, minf(_door_top() * 0.8, 1.15), _wall_radius() - 0.6)
		spill.transform = Transform3D(Basis.looking_at(Vector3(0.0, -0.55, 1.0), Vector3.UP), origin)
		add_generated(spill)

	func _build() -> void:
		super._build()
		if not defer_interior:
			build_interior_parts()

	## İçi kurar: toprak taban, kerege astarı (Meshy modelinde), keçeler, kase.
	func build_interior_parts() -> void:
		defer_interior = false
		if not is_inside_tree():
			return
		_build_floor()
		if uses_model():
			_build_lining()
		_build_felts()
		_build_bowl()

	func _build_floor() -> void:
		var mat := ShaderMaterial.new()
		mat.shader = GROUND_SHADER
		mat.set_shader_parameter("mode", 2)
		mat.set_shader_parameter("disc_center", Vector2.ZERO)
		mat.set_shader_parameter("disc_radius", radius * FLOOR_RATIO)
		mat.set_shader_parameter("disc_soft", 0.05)
		mat.set_shader_parameter("base_color", Color(0.38, 0.32, 0.26))
		mat.set_shader_parameter("dark_color", Color(0.3, 0.25, 0.2))
		mat.set_shader_parameter("mottle_tex", floor_texture)
		mat.set_shader_parameter("mottle_tile", 2.5)
		mat.set_shader_parameter("mottle_lod", 2.5)
		mat.set_shader_parameter("interior", 1.0)
		var mi := add_mesh(MeshKit.disc(radius * FLOOR_RATIO + 0.1, 0.008, 48), mat)
		mi.name = "Floor"
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.set_meta(&"free_asset", FLOOR_ASSET_ID)

	## Kerege astarı: duvar (kafes, üst kenarda dokuma bant; kapı aralığı açık) ve çatı (uuk sırıkları), modelin iç
	## ölçülerinin biraz içinde. Yalnız Meshy modelinde: yedek yurdun keçesi içeriden zaten kafes gösterir.
	func _build_lining() -> void:
		var fit := _read_fit()
		var h := _model_height()
		var circle: Dictionary = fit.get("circle", {})
		var c := Vector3(float(circle.get("x", 0.0)) * radius, 0.0, float(circle.get("z", 0.0)) * radius)
		var r_wall := radius * LINING_RATIO
		var wall_top := float(fit.get("wall_top", 0.58)) * h
		var levels: Array = fit.get("inner", [])
		var wall_h := wall_top * (float(levels.size() - 2) / float(maxi(levels.size() - 1, 1)) if levels.size() > 2 else 0.9)
		var door: Dictionary = fit.get("door", {})
		var door_a := PI * 0.5 - deg_to_rad(float(door.get("center_deg", 0.0)))
		var half := asin(clampf(sin(deg_to_rad(float(door.get("half_width_deg", 7.6)))) * float(circle.get("r", 0.88)) / LINING_RATIO, 0.0, 0.95)) + deg_to_rad(1.5)
		var root := Node3D.new()
		root.name = "Lining"
		root.position = c
		add_generated(root)
		var wall_mat := ShaderMaterial.new()
		wall_mat.shader = KEREGE_SHADER
		wall_mat.set_shader_parameter("part", 0)
		wall_mat.set_shader_parameter("felt_color", LINING_FELT)
		wall_mat.set_shader_parameter("lattice_color", LINING_LATTICE)
		wall_mat.set_shader_parameter("wall_height", wall_h)
		wall_mat.set_shader_parameter("band_height", 0.2)
		wall_mat.set_shader_parameter("cut_center", to_global(c))
		var wall := add_mesh(lining_wall(r_wall, wall_h, door_a + half, door_a - half + TAU, 56), wall_mat, Transform3D.IDENTITY, root)
		wall.name = "Wall"
		var roof_mat := ShaderMaterial.new()
		roof_mat.shader = KEREGE_SHADER
		roof_mat.set_shader_parameter("part", 1)
		roof_mat.set_shader_parameter("felt_color", LINING_FELT)
		roof_mat.set_shader_parameter("lattice_color", LINING_LATTICE)
		roof_mat.set_shader_parameter("pole_count", 48.0)
		roof_mat.set_shader_parameter("cut_center", to_global(c))
		var roof := add_mesh(lining_roof(_roof_profile(fit, r_wall, wall_h, h), 48), roof_mat, Transform3D.IDENTITY, root)
		roof.name = "Roof"

	## Çatı astarının kesiti (yarıçap, yükseklik): duvarın üstünden tacın altına; modelin iç ölçülerinden margin kadar
	## içeride, yarıçap yukarı doğru azalır.
	func _roof_profile(fit: Dictionary, r_wall: float, wall_h: float, h: float) -> PackedVector2Array:
		var profile := PackedVector2Array([Vector2(r_wall, wall_h)])
		var levels: Array = fit.get("inner", [])
		var points: Array[Vector2] = []
		if not levels.is_empty():
			var top_level: Array = levels[levels.size() - 1]
			var lowest := 1.0
			for v in top_level:
				if float(v) > 0.0:
					lowest = minf(lowest, float(v))
			points.append(Vector2(lowest * radius, float(fit.get("wall_top", 0.58)) * h))
		for pair in fit.get("roof", []):
			points.append(Vector2(float(pair[1]) * radius, float(pair[0]) * h))
		var crown: Dictionary = fit.get("crown", {})
		var crown_y := float(crown.get("y", 0.88)) * h - 0.04
		var crown_r := float(crown.get("r", 0.2)) * radius
		var last := r_wall
		var last_y := wall_h
		for p in points:
			var y := p.y - LINING_MARGIN * 0.5
			if y <= last_y + 0.01 or y >= crown_y:
				continue
			var r := maxf(minf(p.x - LINING_MARGIN, last), crown_r)
			profile.append(Vector2(r, y))
			last = r
			last_y = y
		profile.append(Vector2(minf(crown_r, last), crown_y))
		return profile

	func _read_fit() -> Dictionary:
		if not FileAccess.file_exists(FIT_PATH):
			return {}
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIT_PATH))
		return parsed if parsed is Dictionary else {}

	## Şırdak keçeler: ocağın ardında baş köşe (tör), kadınların yanında döşek, öteki yanda oturma keçesi.
	func _build_felts() -> void:
		var felts := [
			["FeltTor", Vector2(2.0, 1.15), Vector3(0.0, 0.02, -1.4), 0.0, Color(0.52, 0.09, 0.06), Color(0.12, 0.16, 0.32)],
			["FeltSouth", Vector2(1.5, 1.0), Vector3(-1.45, 0.02, -0.05), PI * 0.5, Color(0.2, 0.25, 0.4), Color(0.7, 0.62, 0.48)],
		]
		for f in felts:
			var mat := ShaderMaterial.new()
			mat.shader = SHYRDAK_SHADER
			mat.set_shader_parameter("size", f[1])
			mat.set_shader_parameter("color_a", f[4])
			mat.set_shader_parameter("color_b", f[5])
			var plane := PlaneMesh.new()
			plane.size = f[1]
			var mi := add_mesh(plane, mat, Transform3D(Basis(Vector3.UP, f[3]), f[2]))
			mi.name = f[0]
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		# Döşek: kalın keçe yatak, üstünde şırdak; doğum burada olur.
		var bed := add_mesh(box(Vector3(0.95, 0.14, 1.85)), Style.toon(Style.FELT.darkened(0.08), {"brush_strength": 0.2}),
			Transform3D(Basis.IDENTITY, Vector3(1.3, 0.07, -0.3)))
		bed.name = "FeltBed"
		var top_mat := ShaderMaterial.new()
		top_mat.shader = SHYRDAK_SHADER
		top_mat.set_shader_parameter("size", Vector2(0.9, 1.8))
		top_mat.set_shader_parameter("color_a", Color(0.5, 0.08, 0.06))
		top_mat.set_shader_parameter("color_b", Color(0.7, 0.62, 0.48))
		var top := PlaneMesh.new()
		top.size = Vector2(0.9, 1.8)
		var top_mi := add_mesh(top, top_mat, Transform3D(Basis.IDENTITY, Vector3(1.3, 0.142, -0.3)))
		top_mi.name = "FeltBedTop"
		top_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	## Oyma ahşap kase, ocağın yanında; içinde süt.
	func _build_bowl() -> void:
		var profile := PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.06, 0.0), Vector2(0.1, 0.04),
			Vector2(0.12, 0.095), Vector2(0.122, 0.11)])
		var at := Transform3D(Basis.IDENTITY, Vector3(0.68, 0.01, 0.52))
		var bowl := add_mesh(MeshKit.lathe(profile, 20), Style.toon_double(Style.WOOD_DARK, {"brush_strength": 0.15}), at)
		bowl.name = "Bowl"
		var milk := add_mesh(MeshKit.disc(0.112, 0.092, 20), Style.toon(Color(0.95, 0.93, 0.88)), at)
		milk.name = "BowlMilk"

	## Astarın duvarı (saf): r yarıçaplı, h boyunda, from..to açı aralığında (radyan; yön (cos a, 0, sin a)) şerit.
	## UV metredir (x çevre boyunca, y zeminden): kerege.gdshader'ın beklediği gibi. Normal içe bakar.
	static func lining_wall(r: float, h: float, from: float, to: float, segments: int) -> ArrayMesh:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in segments:
			var a0 := lerpf(from, to, float(i) / float(segments))
			var a1 := lerpf(from, to, float(i + 1) / float(segments))
			var d0 := Vector3(cos(a0), 0.0, sin(a0))
			var d1 := Vector3(cos(a1), 0.0, sin(a1))
			var u0 := (a0 - from) * r
			var u1 := (a1 - from) * r
			var corners := [[d0 * r, Vector2(u0, 0.0), -d0], [d1 * r, Vector2(u1, 0.0), -d1],
				[d0 * r + Vector3(0.0, h, 0.0), Vector2(u0, h), -d0], [d1 * r + Vector3(0.0, h, 0.0), Vector2(u1, h), -d1]]
			for idx in [0, 2, 1, 1, 2, 3]:
				st.set_normal(corners[idx][2])
				st.set_uv(corners[idx][1])
				st.add_vertex(corners[idx][0])
		return st.commit()

	## Astarın çatısı (saf): kesit (yarıçap, yükseklik) Y çevresinde döner. UV.x açı (0..1), UV.y saçaktan (0) tepeye (1).
	static func lining_roof(profile: PackedVector2Array, segments: int) -> ArrayMesh:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var count := profile.size()
		for i in segments:
			var a0 := TAU * float(i) / float(segments)
			var a1 := TAU * float(i + 1) / float(segments)
			for k in count - 1:
				var p0 := profile[k]
				var p1 := profile[k + 1]
				var v0 := float(k) / float(count - 1)
				var v1 := float(k + 1) / float(count - 1)
				var corners := [
					[Vector3(cos(a0) * p0.x, p0.y, sin(a0) * p0.x), Vector2(float(i) / segments, v0)],
					[Vector3(cos(a1) * p0.x, p0.y, sin(a1) * p0.x), Vector2(float(i + 1) / segments, v0)],
					[Vector3(cos(a0) * p1.x, p1.y, sin(a0) * p1.x), Vector2(float(i) / segments, v1)],
					[Vector3(cos(a1) * p1.x, p1.y, sin(a1) * p1.x), Vector2(float(i + 1) / segments, v1)],
				]
				for idx in [0, 1, 2, 1, 3, 2]:
					st.set_uv(corners[idx][1])
					st.add_vertex(corners[idx][0])
		st.generate_normals()
		return st.commit()
