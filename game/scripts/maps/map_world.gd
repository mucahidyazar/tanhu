class_name MapWorld
extends World
## İç haritanın kökü (godot.md §4.2): World'ün alt sınıfıdır, oyuncunun ve kameranın sorduğu yüz aynıdır (get_terrain_shape,
## collect_obstacles, collect_walls, collect_boxes) ve Ordos'un, Yola Çıkış'ın dünyalarının yüzünü de taşır (play_area, camera_bounds,
## clamp_camera_transform, marker, is_ready, get_sky_rig). Tarifi MapSpec'tir (data/maps/<id>/map.json); ağır üretim pişmiştir (MapBaker,
## tools/bake_map.gd): yükseklik, zemin maskesi, 100 m'lik arazi parçaları (üç düzey, görünürlük aralığıyla), dış halka, ot, navmesh karoları.
## WorldHost arka planda yükler (sahne, pişmiş parçalar, varlıklar), örnekler; kurulum ana iş parçacığında kare başına frame_budget_ms'lik
## adımlardır, is_ready() hepsi bitince true olur (world_ready yayılır).
##
## Düğümler:
##   Terrain/Chunk_<x>_<z>/Lod0..2  arazi parçaları (görünürlük aralığı: 0–150, 150–520, 520 m ötesi; pay lod_margin; geçiş kipi kapalı)
##   Terrain/Ring/Ring<i>           dış halka (haritanın kenarından 3,2 km'ye dek; tepeler ve dağ siluetleri)
##   Grass/Grass_<x>_<z>_<çeşit>     ot (atw_grass; MultiMesh, 40 m'lik parçalar)
##   Navigation/Tile_<x>_<z>         navmesh karoları (NavigationRegion3D; 100 m)
##   Places/<Kimlik>                yapı kayıtları: yurt, ocak, eşya, sancak, kaya, çam; atlar (RideableHorse, binilir)
##   Gates/<Kimlik>                 kapılar (Marker3D; meta: to, arrive, radius)
##   Layers/<Kimlik>                veri katmanları (map.json «layers»; MapLayers: deneme haritasının ateş ve av katmanı)
##   WorldEnvironment, SunLight, SkyRig: dünyanın kendi ışığı (sahnede; SkyRig açılış örneğini light.json'dan yazar)
## Ücretsiz varlıklar (K89): zemini çizen her parça ve halka withered_grass, dirt, dry_ground_rocks; WorldEnvironment qwantani_sunrise_puresky.
## Her düğüm free_asset meta verisini taşır.
##   var world := (load("res://scenes/maps/testmap.tscn") as PackedScene).instantiate() as MapWorld
##   world.spec = MapSpec.find("testmap"); add_child(world); while not world.is_ready(): await get_tree().process_frame
##   world.spawn("start")   # {at: Vector3, yaw}

signal world_ready

const GROUND_SHADER := preload("res://assets/maps/ordos/childhood_ground.gdshader")
const GRASS_SHADER := preload("res://shaders/atw_grass.gdshader")
## Kışlak'ın kar zemini (K2; GPU parçaları ve dış halka).
const SNOW_SHADER := preload("res://shaders/kislak_snow.gdshader")
## Zeminin ücretsiz dokuları: [FREE_ASSETS.json kimliği, dosya] (ot dibi, toprak, çakıl).
const FREE_GRASS := ["withered_grass", "res://assets/_free/texture/withered_grass/withered_grass_diff_2k.jpg"]
const FREE_SOIL := ["dirt", "res://assets/_free/texture/dirt/dirt_diff_1k.jpg"]
const FREE_GRAVEL := ["dry_ground_rocks", "res://assets/_free/texture/dry_ground_rocks/dry_ground_rocks_diff_1k.jpg"]
## Zemini çizen her düğümün free_asset meta verisi (K89: üç doku birlikte; test_free_assets.gd).
const FREE_GROUND: Array[String] = ["withered_grass", "dirt", "dry_ground_rocks"]
## Kar zemininin ücretsiz dokuları (toprak ve kaya; ot dibi yok).
const FREE_SNOW: Array[String] = ["dirt", "dry_ground_rocks"]
## Pişmiş parçaların türleri (MapBaker.bake).
const BAKE_KINDS: Array[String] = ["ground", "chunks", "grass", "nav"]
## Otun bir adımda kurulan parça sayısı.
const GRASS_PER_STEP := 12
## Kapının sancak ve iz renkleri (sancak kaydında yoksa).
const BANNER_COLOR := Color(0.48, 0.14, 0.09)
## Verisi haritada duran ama kurucusu MapWorld olmayan yapı türleri (Kışlak; act1.md §4): yapı kurucusu (StructureKit), katmanlar ve
## nöbet ateşi düğümü kurar; MapWorld uyarmadan geçer, marker(id) kaydın yerini verir.
const DATA_KINDS: Array[String] = ["watch_fire", "lantern", "yurt_pad", "work_board", "kitchen", "woodpile", "felt_yard", "stable",
	"tower", "lookout", "ramp", "waystation", "shed", "path_mark", "gate", "latrine", "scree"]

## Tarifin kimliği (spec verilmezse MapSpec.find ile okunur).
@export var map_id := MapSpec.TESTMAP
## Ana iş parçacığında kare başına kurulum bütçesi (ms).
@export var frame_budget_ms := 4.0

var spec: MapSpec
## Yükseklik yüzü (HeightmapShape): oyuncu, kamera, binek ve kişiler sorar.
var ground: HeightmapShape
## Kurulum pişmiş parçalarla mı yapıldı (yoksa MapBaker burada üretti)?
var used_bake := false
## Binilen atlar ve yapı kayıtlarının düğümleri (kimlik → düğüm).
var horses: Array[RideableHorse] = []
var places: Dictionary = {}
## Akan çimen (grass.stream; yoksa null), nöbet ateşleri ve Kızıl Kazık hattı (Kışlak; yoksa null).
var grass_field: GrassField
var watch_fires: WatchFires
var red_stakes: RedStakes
## Kurulum ölçüleri (budget_probe; OrdosWorld.build_stats gibi): kare, en uzun kare, ana iş parçacığındaki toplam, hazır olma (ms).
var build_stats := {"frames": 0, "max_frame_ms": 0.0, "main_ms": 0.0, "ready_ms": 0.0, "steps": {}}

var _bakes: Dictionary = {}
var _steps: Array[Callable] = []
var _ready_flag := false
var _started_us := 0
var _terrain_node: Node3D
var _grass_node: Node3D
var _nav_node: Node3D
var _places_node: Node3D
var _gates_node: Node3D
var _ground_material: ShaderMaterial
## Dış halkanın malzemesi (kar zemininde displace kapalı kopya; öteki haritalarda zeminin kendisi) ve zemini çizen düğümlerin ücretsiz
## varlıkları.
var _ring_material: ShaderMaterial
var _ground_free: Array[String] = FREE_GROUND.duplicate()
var _grass_material: ShaderMaterial
var _grass_meshes: Array[Mesh] = []


func _ready() -> void:
	_started_us = Time.get_ticks_usec()
	if spec == null:
		spec = MapSpec.find(map_id)
	if spec == null:
		push_error("[map_world] haritanın tarifi yok: %s" % map_id)
		_finish()
		return
	var sig := MapBaker.signature(spec)
	var kinds := MapBaker.kinds_of(spec)
	for kind in kinds:
		var bake := MapBake.fetch(spec.id, kind, sig)
		if bake:
			_bakes[kind] = bake
	used_bake = _bakes.size() == kinds.size()
	if not used_bake:
		push_warning("[map_world] %s'in pişmiş parçaları eksik ya da eski: kurulumda üretiliyor (tools/bake_map.gd --map=%s)" % [spec.id, spec.id])
		var t := Time.get_ticks_usec()
		for bake in MapBaker.bake(spec):
			_bakes[bake.kind] = bake
		build_stats["steps"]["bake"] = (Time.get_ticks_usec() - t) / 1000.0
	ground = MapBaker.shape_of(_bakes["ground"])
	_terrain_node = _group("Terrain")
	_grass_node = _group("Grass")
	_nav_node = _group("Navigation")
	_places_node = _group("Places")
	_gates_node = _group("Gates")
	_steps.append(_build_materials)
	var chunks: MapBake = _bakes.get("chunks")
	if chunks:
		for chunk: Dictionary in chunks.data.get("chunks", []):
			_steps.append(_build_chunk.bind(chunk))
		_steps.append(_build_ring)
	var grass_bake: MapBake = _bakes.get("grass")
	var entries: Array = grass_bake.data.get("entries", []) if grass_bake else []
	for start in range(0, entries.size(), GRASS_PER_STEP):
		_steps.append(_build_grass_slice.bind(entries.slice(start, start + GRASS_PER_STEP)))
	if _bakes.has("nav"):
		_steps.append(_build_nav)
	_steps.append(_build_edge)
	if bool(spec.grass.get("stream", false)):
		_steps.append(_build_grass_field)
	_steps.append(_build_watch_fires)
	if spec.raw.get("red_stakes") is Dictionary:
		_steps.append(_build_red_stakes)
	for rec: Dictionary in spec.structures:
		_steps.append(_build_structure.bind(rec))
	_steps.append(_build_gates)
	_steps.append(_build_layers)
	set_process(true)


func _process(_delta: float) -> void:
	if _ready_flag:
		return
	var started := Time.get_ticks_usec()
	while not _steps.is_empty():
		var step: Callable = _steps.pop_front()
		var step_started := Time.get_ticks_usec()
		step.call()
		var steps: Dictionary = build_stats["steps"]
		var key := step.get_method()
		steps[key] = maxf(float(steps.get(key, 0.0)), (Time.get_ticks_usec() - step_started) / 1000.0)
		if (Time.get_ticks_usec() - started) / 1000.0 >= frame_budget_ms:
			break
	var ms := (Time.get_ticks_usec() - started) / 1000.0
	build_stats["frames"] = int(build_stats["frames"]) + 1
	build_stats["main_ms"] = float(build_stats["main_ms"]) + ms
	build_stats["max_frame_ms"] = maxf(float(build_stats["max_frame_ms"]), ms)
	if _steps.is_empty():
		_finish()


func _finish() -> void:
	_ready_flag = true
	set_process(false)
	_bakes.clear()
	build_stats["ready_ms"] = (Time.get_ticks_usec() - _started_us) / 1000.0
	var rig := get_sky_rig()
	if rig:
		rig.refresh()
	world_ready.emit()


## Godot 4.7.2'de gözlendi (godot.md §4.6): görünürlük aralığı taşıyan düğümün üst düğümü gizlenip gösterilince aralık durumu bozuluyor.
## Harita hiçbir akışta gizlenmez (CineHost yalnız kampı gizler); yine de görünür olunca parçaların aralıkları bir kare sonra yeniden yazılır.
func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and _ready_flag and is_visible_in_tree():
		refresh_ranges.call_deferred()


## Arazi parçalarının görünürlük aralıklarını yeniden yazar (değer aynı, çizim sunucusunun durumu tazelenir).
func refresh_ranges() -> void:
	if _terrain_node == null:
		return
	for mi: MeshInstance3D in _terrain_node.find_children("Lod*", "MeshInstance3D", true, false):
		var begin := mi.visibility_range_begin
		var end := mi.visibility_range_end
		mi.visibility_range_begin = begin + 0.001
		mi.visibility_range_begin = begin
		mi.visibility_range_end = end + 0.001 if end > 0.0 else 0.0
		mi.visibility_range_end = end


## Arazi parçalarının aralık payı (WorldMap.bake; hud_map_spec «ranges»). Pay yeni bir görüntü alanının ilk çiziminde düzeyler arasında ölü bant
## açar (Godot'nun gecikmesi: görünmeyen düzey ancak sınırı payı kadar geçince görünür): haritanın dik bakışında kameradan 508–532 m'deki
## parçalarda ne orta ne uzak düzey çizilir, kâğıt rengi kare kalırdı (Kışlak'ın HUD haritasında Ulu Ocak'ın ve çevrenin parçaları). on false
## payı sıfırlar (düzeyler bitişik), true geri yazar.
func set_range_margins(on: bool) -> void:
	if _terrain_node == null:
		return
	var margin := float((_bakes["chunks"] as MapBake).data.get("lod_margin", 12.0)) if _bakes.has("chunks") else 12.0
	for mi: MeshInstance3D in _terrain_node.find_children("Lod*", "MeshInstance3D", true, false):
		mi.visibility_range_begin_margin = margin if on and mi.visibility_range_begin > 0.0 else 0.0
		mi.visibility_range_end_margin = margin if on and mi.visibility_range_end > 0.0 else 0.0


# --- Yüz ------------------------------------------------------------------------------------------

## Kuruldu mu (arazi, ot, navmesh, yapılar, kapılar)?
func is_ready() -> bool:
	return _ready_flag


## Kamp dünyasının kurulum sorusu (WorldHost): iç harita hazırsa kurulmuştur.
func is_built() -> bool:
	return _ready_flag


func get_terrain_shape() -> TerrainShape:
	return ground if ground else TerrainShape.new()


func get_sky_rig() -> SkyRig:
	return get_node_or_null(^"SkyRig") as SkyRig


## Oturumun saatini haritanın ışığına bağlar (MapSky; light.json LightStops tablosuysa: Kışlak). Döner: bağlandı mı (deneme haritasında
## false: açılış örneği durur).
func bind_clock(clock: GameClock) -> bool:
	var sky := get_node_or_null(^"MapSky") as MapSky
	if sky == null:
		sky = MapSky.new()
		sky.name = "MapSky"
		add_child(sky)
	return sky.bind(clock, get_sky_rig(), spec.light if spec else "", spec.id if spec else "")


## Oyuncunun çarpıştığı daireler: yalnız bu dünyanın "obstacles" grubundakiler (yurtlar, ocak, eşya, kaya, çam).
func collect_obstacles() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for node in _own_obstacles():
		if node.has_method(&"get_collision_circles"):
			out.append_array(node.call(&"get_collision_circles"))
		elif node.has_method(&"get_obstacle_circles"):
			out.append_array(node.call(&"get_obstacle_circles"))
	return out


func collect_walls() -> Array[RingWall]:
	var out: Array[RingWall] = []
	for node in _own_obstacles():
		if node.has_method(&"get_obstacle_walls"):
			out.append_array(node.call(&"get_obstacle_walls"))
	return out


func collect_boxes() -> Array[ObstacleBox]:
	var out: Array[ObstacleBox] = []
	for node in _own_obstacles():
		if node.has_method(&"get_obstacle_boxes"):
			out.append_array(node.call(&"get_obstacle_boxes"))
	return out


## Yürünür alan: {center, radius, soft_edge} (PlayerController.use_map).
func play_area() -> Dictionary:
	return {"center": spec.play_center, "radius": spec.play_radius, "soft_edge": spec.play_soft_edge}


func camera_bounds() -> Rect2:
	return spec.camera_bounds if spec.camera_bounds.has_area() else spec.rect().grow(28.0)


func clamp_camera_transform(xform: Transform3D, focus: Vector3) -> Transform3D:
	return OrdosWorld.clamp_to_bounds(xform, focus, camera_bounds())


## İşaretin dünya noktası, zeminde: belirme noktaları, kapılar, yapı kayıtları (kimlikleriyle). Yoksa Vector3.INF.
func marker(id: String) -> Vector3:
	var s := spec.spawn(id)
	if not s.is_empty():
		return on_ground(s["at"])
	var g := spec.gate(id)
	if not g.is_empty():
		return on_ground(g["at"])
	var node := places.get(id) as Node3D
	if is_instance_valid(node):
		return node.global_position
	for rec: Dictionary in spec.structures:
		if str(rec.get("id", "")) == id:
			return on_ground(rec["at"])
	return Vector3.INF


## Belirme: {at: Vector3 (zeminde), yaw: radyan (PlayerController.spawn_at; yerel +Z pusula yönüne)}; yoksa boş.
func spawn(id: String) -> Dictionary:
	var s := spec.spawn(id)
	if s.is_empty():
		return {}
	return {"at": on_ground(s["at"]), "yaw": DepartWorld.yaw_of(float(s["facing"]))}


## Noktayı kapsayan kapı (MapSpec.gate_at; yoksa boş).
func gate_at(p: Vector3) -> Dictionary:
	return spec.gate_at(Vector2(p.x, p.z))


## Kimlikle at (yoksa null).
func horse(id: String) -> RideableHorse:
	return places.get(id) as RideableHorse


## Zemindeki nokta.
func on_ground(p: Vector2) -> Vector3:
	return Vector3(p.x, ground.height_at(p.x, p.y) if ground else 0.0, p.y)


## HUD haritasının tarifi (WorldMap.bake): yürünür alan ve bölgeler; atlar gizlenir.
func hud_map_spec(extra_hide: Array = []) -> Dictionary:
	var named: Array = []
	for r: Dictionary in spec.regions:
		named.append({"name": str((r.get("name", {}) as Dictionary).get("tr", r.get("id", ""))), "at": r["center"]})
	# Haritada adı yazılan yapılar (map.json «map_places»: yapı kimlikleri; Kışlak'ın Ulu Ocak'ı, yurtları, Yar Bakışı...).
	for pid: Variant in (spec.raw.get("map_places", []) if spec.raw.get("map_places") is Array else []):
		var rec := spec.structure(str(pid))
		if not rec.is_empty():
			named.append({"name": str((rec.get("name", {}) as Dictionary).get("tr", pid)), "at": rec["at"]})
	var hide: Array = extra_hide.duplicate()
	for h in horses:
		if is_instance_valid(h):
			hide.append(h)
	var out := {
		"key": spec.id, "title": spec.title_text("tr"), "subtitle": str(spec.subtitle.get("tr", "")), "center": spec.play_center,
		"radius": spec.play_radius, "places": named, "hide": hide, "ranges": Callable(self, &"set_range_margins"),
	}
	# Dikdörtgen harita (Kışlak; «edge»): yürünür alan kenar payının içidir (MapEdge.walkable).
	var edge_def: Variant = spec.raw.get("edge")
	if edge_def is Dictionary:
		out["box"] = spec.rect().grow(-float((edge_def as Dictionary).get("margin", 6.0)))
	return out


## Kurulumun düğüm sayıları (sınama ve ölçüm).
func part_counts() -> Dictionary:
	return {
		"chunks": _terrain_node.get_child_count() - (1 if _terrain_node.has_node(^"Ring") else 0) if _terrain_node else 0,
		"grass": _grass_node.get_child_count() if _grass_node else 0,
		"nav_tiles": _nav_node.get_child_count() if _nav_node else 0,
		"places": _places_node.get_child_count() if _places_node else 0,
		"gates": _gates_node.get_child_count() if _gates_node else 0,
	}


func _own_obstacles() -> Array[Node]:
	var out: Array[Node] = []
	if not is_inside_tree():
		return out
	for node in get_tree().get_nodes_in_group(OBSTACLE_GROUP):
		if is_ancestor_of(node):
			out.append(node)
	return out


# --- Kurulum ----------------------------------------------------------------------------------------

func _build_materials() -> void:
	var g: MapBake = _bakes["ground"]
	var colors: Dictionary = spec.ground.get("colors", {})
	var chunk_bake: MapBake = _bakes.get("chunks")
	if chunk_bake and bool(chunk_bake.data.get("gpu", false)):
		_build_snow_materials(g, colors)
		return
	_ground_material = ShaderMaterial.new()
	_ground_material.shader = GROUND_SHADER
	_ground_material.set_shader_parameter(&"grass_tex", _texture(FREE_GRASS[1]))
	_ground_material.set_shader_parameter(&"soil_tex", _texture(FREE_SOIL[1]))
	_ground_material.set_shader_parameter(&"gravel_tex", _texture(FREE_GRAVEL[1]))
	var mask := g.data.get("mask") as Image
	if mask:
		_ground_material.set_shader_parameter(&"mask_tex", ImageTexture.create_from_image(mask))
		var r: Vector4 = g.data.get("mask_rect", Vector4(0.0, 0.0, 0.01, 0.01))
		_ground_material.set_shader_parameter(&"mask_rect", r)
	for key: String in colors:
		_ground_material.set_shader_parameter(StringName(key), SkyRig.to_color(colors[key]))
	var gr := spec.grass
	_grass_material = ShaderMaterial.new()
	_grass_material.shader = GRASS_SHADER
	_grass_material.set_shader_parameter(&"instance_patches", true)
	var gcolors: Dictionary = gr.get("colors", {})
	for key: String in gcolors:
		_grass_material.set_shader_parameter(StringName(key), SkyRig.to_color(gcolors[key]))
	_grass_material.set_shader_parameter(&"wind_strength", float(gr.get("wind_strength", 0.09)))
	_grass_material.set_shader_parameter(&"fade_start", float(gr.get("fade_start", 34.0)))
	_grass_material.set_shader_parameter(&"fade_end", float(gr.get("fade_end", 52.0)))
	_grass_material.set_shader_parameter(&"shadow_tint", SkyRig.to_color(colors.get("shadow_tint", [0.62, 0.68, 0.84])))
	_grass_meshes.clear()
	for v in MapBaker.TUFT_VARIANTS:
		_grass_meshes.append(Meadow.tuft_mesh(v.x, v.y, float(v.z) / 100.0, v.w, Meadow.BLADE_WIDTH.x if v.w == 1 else Meadow.BLADE_WIDTH.y))


## Kışlak'ın zemini (K2; kislak_snow.gdshader): parçalar yüksekliği dokudan alır (GPU), dış halka kendi köşesini taşır (displace kapalı).
## Dokular pişmiş zeminin görüntüleridir: yükseklik (RF, en yakın örnek), normal (RG8), maske (2 m) ve örtü (4 m). Ücretsiz dokular (K89):
## toprak (dirt) ve kaya (dry_ground_rocks).
func _build_snow_materials(g: MapBake, colors: Dictionary) -> void:
	_ground_material = ShaderMaterial.new()
	_ground_material.shader = SNOW_SHADER
	var origin: Vector2 = g.data.get("origin", Vector2.ZERO)
	_ground_material.set_shader_parameter(&"height_grid", Vector3(origin.x, origin.y, float(g.data.get("cell", 1.0))))
	_ground_material.set_shader_parameter(&"mask_rect", g.data.get("mask_rect", Vector4(0.0, 0.0, 0.001, 0.001)))
	for pair: Array in [[&"height_tex", "height"], [&"normal_tex", "normal"], [&"mask_tex", "mask"], [&"cover_tex", "cover"]]:
		var img := g.data.get(pair[1]) as Image
		if img:
			_ground_material.set_shader_parameter(pair[0], ImageTexture.create_from_image(img))
	_ground_material.set_shader_parameter(&"soil_tex", _texture(FREE_SOIL[1]))
	_ground_material.set_shader_parameter(&"rock_tex", _texture(FREE_GRAVEL[1]))
	for key: String in colors:
		_ground_material.set_shader_parameter(StringName(key), SkyRig.to_color(colors[key]))
	var wind := TerrainPaint.compass_dir(float((spec.ground.get("detail", {}) as Dictionary).get("drift", {}).get("toward", 135.0)))
	_ground_material.set_shader_parameter(&"wind_dir", wind)
	_ring_material = _ground_material.duplicate() as ShaderMaterial
	_ring_material.set_shader_parameter(&"displace", false)
	_ground_free = FREE_SNOW.duplicate()


## Bir arazi parçası: üç düzey görünürlük aralığıyla (geçiş kipi kapalı, pay sınırda titremeyi önler; godot.md §4.6). GPU parçasında
## (Kışlak) ağ ortak düz ızgaradır: düğüm parçanın köşesindedir, kırpma kutusu (custom_aabb) pişmiş yükseklik aralığıdır.
func _build_chunk(chunk: Dictionary) -> void:
	var bake: MapBake = _bakes["chunks"]
	var gpu := bool(bake.data.get("gpu", false))
	var ranges: Array = bake.data.get("lod_ranges", [150.0, 520.0])
	var margin := float(bake.data.get("lod_margin", 12.0))
	var key: Vector2i = chunk["key"]
	var holder := Node3D.new()
	holder.name = "Chunk_%d_%d" % [key.x, key.y]
	if gpu:
		var r: Rect2 = chunk["rect"]
		holder.position = Vector3(r.position.x, 0.0, r.position.y)
	_terrain_node.add_child(holder)
	var ids: Array = chunk["lods"]
	for li in ids.size():
		var mi := MeshInstance3D.new()
		mi.name = "Lod%d" % li
		mi.mesh = bake.meshes[int(ids[li])]
		if gpu:
			mi.custom_aabb = chunk.get("aabb", AABB())
		mi.material_override = _ground_material
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_begin = 0.0 if li == 0 else float(ranges[li - 1])
		mi.visibility_range_end = float(ranges[li]) if li < ranges.size() else 0.0
		mi.visibility_range_begin_margin = 0.0 if li == 0 else margin
		mi.visibility_range_end_margin = margin if li < ranges.size() else 0.0
		mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		mi.set_meta(&"free_asset", _ground_free.duplicate())
		holder.add_child(mi)


func _build_ring() -> void:
	var bake: MapBake = _bakes["chunks"]
	var ring := Node3D.new()
	ring.name = "Ring"
	_terrain_node.add_child(ring)
	var ids: Array = bake.data.get("ring", [])
	for i in ids.size():
		var mi := MeshInstance3D.new()
		mi.name = "Ring%d" % i
		mi.mesh = bake.meshes[int(ids[i])]
		mi.material_override = _ring_material if _ring_material else _ground_material
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.set_meta(&"free_asset", _ground_free.duplicate())
		ring.add_child(mi)


func _build_grass_slice(entries: Array) -> void:
	for entry: Array in entries:
		var key: Vector3i = entry[0]
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Grass_%d_%d_%d" % [key.x, key.y, key.z]
		mmi.multimesh = MapBake.multimesh_from(_grass_meshes[key.z], entry[1], true)
		mmi.material_override = _grass_material
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_grass_node.add_child(mmi)


func _build_nav() -> void:
	var bake: MapBake = _bakes["nav"]
	var by_key := {}
	for tile: Dictionary in bake.data.get("tiles", []):
		var key: Vector2i = tile["key"]
		var region := NavigationRegion3D.new()
		region.name = "Tile_%d_%d" % [key.x, key.y]
		region.navigation_mesh = tile["mesh"]
		region.set_meta(&"rect", tile["rect"])
		_nav_node.add_child(region)
		by_key[key] = region
	# Yol bulmanın yüzü (MapNav: yol, en yakın nokta, ajan profilleri, değen karonun eşzamansız yeniden pişmesi); «Navigation» yalnız
	# karoları taşır.
	var nav := MapNav.new()
	nav.name = "MapNav"
	nav.setup(self, spec, ground, by_key)
	add_child(nav)


func _build_structure(rec: Dictionary) -> void:
	var id := str(rec.get("id", ""))
	# Yapı kiti (K51 yurtları ve Kışlak'ın yapı kataloğu; StructureKit): kayıt onunsa düğümü o kurar, izini engel toplamasına o verir
	# (StagedStructure, YurtSlot ve «Structures»: StructureSet). Navmesh'in izi kayıttan: StructureKit.footprint(rec).
	if StructureKit.handles(rec):
		var built := StructureKit.build(rec, StructureKit.world_ctx(self))
		if built:
			_add_place(built, id)
		return
	var at: Vector2 = rec["at"]
	var facing := float(rec.get("facing", 0.0))
	var node: Node3D
	match str(rec.get("kind", "")):
		"yurt":
			var yurt := Yurt.new()
			yurt.radius = TerrainPaint.yurt_radius(rec)
			yurt.has_smoke = bool(rec.get("smoke", true))
			yurt.hanging_angle = float(rec.get("hanging_angle", 0.0))
			yurt.emblem_angle = float(rec.get("emblem_angle", 0.0))
			yurt.interior_light_energy = float(rec.get("interior_light", 1.2))
			yurt.transform = Transform3D(OrdosWorld.door_basis(facing), on_ground(at))
			_add_place(yurt, id)
			OrdosWorld._clean_steps(yurt)
			DepartWorld.simple_shadow(yurt)
			# K51 kaydı (boylu): yalnız açık yurt (open, ≤3; act1.md §4) içini aydınlatır; kapalı yurtta ışık yok (gölgesiz ≤32, §7.2).
			if not bool(rec.get("open", not rec.has("size"))):
				for light: Light3D in yurt.find_children("*", "Light3D", true, false):
					light.queue_free()
			node = yurt
		"great_hearth", "hearth":
			# Ulu Ocak ve açık havadaki ocak (yurt içindeki ocak yurdun dumanıdır, kaydı veridir).
			if str(rec.get("kind", "")) == "hearth" and not bool(rec.get("outdoor", false)):
				return
			var great := str(rec.get("kind", "")) == "great_hearth"
			var hearth := Campfire.new()
			hearth.flame_scale = 1.5 if great else 0.8
			hearth.light_energy = float(rec.get("light_energy", 1.6 if great else 0.7))
			hearth.light_range = float(rec.get("light_range", 9.0 if great else 4.5))
			hearth.position = on_ground(at)
			_add_place(hearth, id)
			DepartWorld.no_shadow(hearth)
			node = hearth
		"campfire":
			var fire := Campfire.new()
			fire.light_energy = float(rec.get("light_energy", 1.1))
			fire.light_range = float(rec.get("light_range", 6.0))
			fire.position = on_ground(at)
			_add_place(fire, id)
			DepartWorld.no_shadow(fire)
			node = fire
		"prop":
			var prop := CampProp.new()
			var kind: int = CampProp.Kind.get(str(rec.get("prop", "BARREL")), CampProp.Kind.BARREL)
			prop.kind = kind as CampProp.Kind
			prop.transform = Transform3D(OrdosWorld.door_basis(facing), on_ground(at))
			_add_place(prop, id)
			node = prop
		"horse":
			var path := str(rec.get("model", ""))
			var horse_node := RideableHorse.new()
			horse_node.model_path = path if ResourceLoader.exists(path) else ""
			_add_place(horse_node, id)
			horse_node.place(on_ground(at), DepartWorld.yaw_of(facing))
			horses.append(horse_node)
			node = horse_node
		"banner":
			var banner := Banner.new()
			banner.kind = int(rec.get("banner", 0)) as Banner.Kind
			banner.cloth_color = SkyRig.to_color(rec.get("cloth", BANNER_COLOR.to_html(false)))
			banner.transform = Transform3D(OrdosWorld.door_basis(facing), on_ground(at))
			_add_place(banner, id)
			node = banner
		"rock", "tree":
			var tree := str(rec.get("kind", "")) == "tree"
			var model := MeshyProp.new()
			model.folder = TreeKit.FOLDER
			model.model_id = str(rec.get("model", "boulder_a"))
			model.target_size = float(rec.get("size", 2.0))
			model.size_axis = MeshyProp.SizeAxis.HEIGHT if tree else MeshyProp.SizeAxis.LONGEST
			model.sink = 0.12 if not tree else 0.05
			model.register_obstacle = true
			model.obstacle_scale = 0.12 if tree else 0.8
			model.transform = Transform3D(OrdosWorld.door_basis(facing), on_ground(at))
			_add_place(model, id)
			node = model
		"count_stone", "landmark":
			# Dikili taşlar (Sayım Taşı, Geyik Taşları, Sak'ın Taşı) kayayla durur; öteki simgeler veridir (katmanlar ve yapı kurucusu kurar).
			var typ := str(rec.get("type", "stone"))
			if str(rec.get("kind", "")) == "landmark" and not typ in ["stone", "deer_stone"]:
				return
			var stone := MeshyProp.new()
			stone.folder = TreeKit.FOLDER
			stone.model_id = "boulder_b"
			stone.target_size = float(rec.get("height", 1.6 if typ == "deer_stone" else 1.3))
			stone.size_axis = MeshyProp.SizeAxis.HEIGHT
			stone.sink = 0.1
			stone.register_obstacle = true
			stone.obstacle_scale = 0.6
			stone.transform = Transform3D(OrdosWorld.door_basis(facing), on_ground(at))
			_add_place(stone, id)
			node = stone
		_:
			# Verisi haritada duran, kurucusu başka yerde olan türler (DATA_KINDS: nöbet ateşi, fener, ped, ahır, kule... ; yapı kurucusu
			# ve katmanlar kurar) uyarısız geçer.
			if not str(rec.get("kind", "")) in DATA_KINDS:
				push_warning("[map_world] bilinmeyen yapı türü: %s" % rec.get("kind", ""))
	if node:
		node.set_meta(&"record", id)


func _add_place(node: Node3D, id: String) -> void:
	node.name = id.to_pascal_case() if not id.is_empty() else node.get_class()
	_places_node.add_child(node)
	if not id.is_empty():
		places[id] = node


func _build_gates() -> void:
	for g: Dictionary in spec.gates:
		var m := Marker3D.new()
		m.name = str(g.get("id", "gate")).to_pascal_case()
		m.position = on_ground(g["at"])
		m.rotation.y = DepartWorld.yaw_of(float(g.get("facing", 0.0)))
		m.set_meta(&"to", str(g.get("to", "")))
		m.set_meta(&"arrive", str(g.get("arrive", "")))
		m.set_meta(&"radius", float(g.get("radius", 6.0)))
		_gates_node.add_child(m)


## Veri katmanları (map.json «layers»; MapLayers): ateş ve av gibi kendi düğümünü kuran katmanlar «Layers» altına. Ses profili (map.json «audio» →
## data/audio/profiles/<kimlik>.json; MapSoundscape: perdenin rengi, gündelik müzik, ortam döngüleri): profil dosyası yoksa bir şey kurulmaz.
func _build_layers() -> void:
	MapLayers.build(self, spec.layers)
	MapSoundscape.build(self, spec.audio)


## Akan çimen (map.json grass.stream; GrassField, godot.md §4.5): parçalar kameranın baktığı yerin çevresinde iş parçacığında kurulur.
func _build_grass_field() -> void:
	var g: MapBake = _bakes["ground"]
	grass_field = GrassField.new()
	grass_field.name = "GrassField"
	grass_field.setup(ground, spec.grass, g.data.get("mask") as Image, g.data.get("mask_rect", Vector4.ZERO), MapBaker.grass_blockers(spec),
		g.data.get("cover") as Image)
	grass_field.follow = _view_focus
	grass_field.focus = on_ground(spec.spawn("start").get("at", spec.play_center))
	_grass_node.add_child(grass_field)


## Nöbet ateşleri (kind watch_fire; WatchFires): sahte ışık, zemin parıltısı kar malzemesinde; saat MapSky'nin saatidir.
func _build_watch_fires() -> void:
	var has_fire := false
	for rec: Dictionary in spec.structures:
		if str(rec.get("kind", "")) == "watch_fire":
			has_fire = true
			break
	if not has_fire:
		return
	watch_fires = WatchFires.new()
	watch_fires.name = "WatchFires"
	var mats: Array[ShaderMaterial] = []
	for m in [_ground_material, _ring_material]:
		if m and m.shader == SNOW_SHADER:
			mats.append(m)
	watch_fires.setup(spec.structures, ground, mats)
	watch_fires.clock_source = func() -> GameClock:
		var sky := get_node_or_null(^"MapSky") as MapSky
		return sky.clock if sky else null
	_places_node.add_child(watch_fires)


## Kızıl Kazık hattı (map.json «red_stakes»; RedStakes): yolların geçtiği yerde boşluklu.
func _build_red_stakes() -> void:
	red_stakes = RedStakes.new()
	red_stakes.name = "RedStakes"
	red_stakes.setup(spec.raw["red_stakes"], ground, TerrainPaint.load_roads(spec).get("roads", []))
	_places_node.add_child(red_stakes)


## Kameranın baktığı yer (zeminde; kamera yoksa belirme noktası): akan çimenin odağı.
func _view_focus() -> Vector3:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam == null:
		return grass_field.focus if grass_field else Vector3.ZERO
	var o := cam.global_position
	var fwd := -cam.global_basis.z
	var ground_y := ground.height_at(o.x, o.z) if ground else 0.0
	var t := clampf((o.y - ground_y) / maxf(-fwd.y, 0.15), 0.0, 60.0)
	return o + fwd * t


## Haritanın kenarı (map.json «edge» {margin}): dikdörtgen haritanın sınırı dört engel kutusudur (MapEdge); «edge» yoksa yok.
func _build_edge() -> void:
	var def: Dictionary = spec.raw.get("edge", {}) if spec.raw.get("edge") is Dictionary else {}
	if def.is_empty():
		return
	var edge := MapEdge.new()
	edge.name = "Edge"
	edge.setup(spec.rect(), float(def.get("margin", 6.0)))
	add_child(edge)


func _group(group_name: String) -> Node3D:
	var node := get_node_or_null(NodePath(group_name)) as Node3D
	if node == null:
		node = Node3D.new()
		node.name = group_name
		add_child(node)
	return node


func _texture(path: String) -> Texture2D:
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


## Bütün parçalar (pişirme aracı; MapBaker.bake).
static func bake(p_spec: MapSpec) -> Array[MapBake]:
	return MapBaker.bake(p_spec)
