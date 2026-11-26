class_name DepartWorld
extends Node3D
## Yola Çıkış'ın küçük dünyası depart_yurt (story.md §6, docs-app story/childhood «Yola Çıkış»; K6, K98): 15 Aralık MÖ 213, şafaktan önce,
## kuzeydeki Tanhu Kampı, kış. Ana kampa dokunmaz (K6): kampın ve Ordos'un yapı taşlarıyla ayrı kurulur, Yeni Oyun'un Yola Çıkış aşamasında
## arka planda yüklenir (main.gd), aşama bitince bırakılır.
##
## Yerler data/maps/depart_yurt/layout.json'dadır:
##   Places/YanchiYurt  Yançi'nin yurdu (HomeYurt: OrdosWorld.BirthYurt'un içi, kerege astarı, toprak taban, keçeler, ortada ocak;
##                      HearthEmbers). Oyuncu içerideyken çatı kalkar, kameraya bakan duvar alçalır (K98 diorama; cutaway.gdshaderinc:
##                      FollowCamera'nın örten nesneleri gibi her kare set_camera_occlusion). İçinde beşik (cradle), kemerinde Mete'nin
##                      doğumundan kalan küçük ok-yay (cradle_bow) ve kundakta Jiyu (swaddled_baby): Önsöz'ün beşiğinin aynısı.
##   Places/HuyanYurt   Huyan Hatun'un yurdu (Yurt; kapı açık, içi ışıklı).
##   Places/TeomanOtag  Teoman'ın otağı (ClosedYurt): kapısı kapalı, kapıdan ışık sızmaz.
##   Places/Kin*        boyların yurtları.
##   Cart               armağan arabası (DepartCart) ve çeken beyaz at (RideableHorse, binilmez).
##   Horse              Mete'nin atı (RideableHorse, horse_brown): sahne açana dek binilmez (lock_horse).
##   Campfire, Props    avlunun ateşi (Campfire) ve eşyalar (CampProp).
##   Ground             karlı zemin (OrdosGround: yüz, düz yerler, çiğnenmiş kar; ordos_ground.gdshader kar tonlarıyla).
##   Snow               yağan kar (GPUParticles3D; kameranın odağını izler).
##   WorldEnvironment, SunLight, SkyRig: ay ışığı ve sivil alaca (light.json «predawn»).
## Oyuncu ve kamera için OrdosWorld'ün yüzü: get_terrain_shape, collect_obstacles, collect_walls, collect_boxes, play_area, camera_bounds,
## clamp_camera_transform, marker(id); is_ready() kurulum bitince true (world_ready). Kurulum kare başına frame_budget_ms'lik adımlara
## bölünür; zeminin ağı WorkerThreadPool'da pişer.
##   var world := (load(DepartWorld.SCENE_PATH) as PackedScene).instantiate() as DepartWorld
##   add_child(world); while not world.is_ready(): await get_tree().process_frame
##   world.marker("cradle"); world.hang_transform(); world.lock_horse(false)

signal world_ready

const SCENE_PATH := "res://scenes/maps/depart_yurt.tscn"
const LAYOUT_PATH := "res://data/maps/depart_yurt/layout.json"
const GROUND_SHADER := preload("res://assets/maps/ordos/ordos_ground.gdshader")
## Ücretsiz dokular: [FREE_ASSETS.json kimliği, dosya].
const FREE_SNOW := ["dry_ground_rocks", "res://assets/_free/texture/dry_ground_rocks/dry_ground_rocks_diff_1k.jpg"]
const FREE_FLOOR := ["dirt", "res://assets/_free/texture/dirt/dirt_diff_1k.jpg"]
const FREE_ASH := ["burned_ground_01", HearthEmbers.ASH_TEXTURE_PATH]
## Zemin gölgelendiricisinin bölge dizilerinin boyu (ordos_ground.gdshader).
const MAX_CIRCLES := 12
const MAX_TRAILS := 12
const TRAMPLED_LIFT := 0.02
## Beşik, küçük yay, kundak ve Mete'nin yayı (assets/props/<kimlik>; Önsöz'ün beşiğiyle aynı ölçüler: PrologueBirth).
const PROP_FOLDER := "props"
const CRADLE_MODEL := "cradle"
const SMALL_BOW_MODEL := "cradle_bow"
const SWADDLE_MODEL := "swaddled_baby"
const BOW_MODEL := "bow"
## Asılan yayın boyu (m) ve kemerdeki yeri: küçük yayın yanında, kemerin altında (beşiğin yerel uzayında; uzun eksen beşiğin boyunca).
const HUNG_BOW_LENGTH := 1.05
const HUNG_BOW_OFFSET := Vector3(0.0, 0.0, 0.07)
## Ev yurdunun kapı aralığının yarı genişliği (m): modelin kapısı ≈0,95 m; yetişkinin gövdesi (0,35) koridorda 0,13 m oynar.
const DOOR_HALF_WIDTH := 0.48
## Yurt engelinin payı (m) ve ev yurdunun ortadaki ocak dairesi.
const YURT_PAD := 0.25
const HEARTH_RADIUS := 0.62
## Çatı kesitinin açılıp kapanma hızı (1/sn).
const CUT_RATE := 1.6

@export_file("*.json") var layout_path := LAYOUT_PATH
## Sahneyle birlikte (arka planda) yüklenen kaynaklar (yurt modeli, dokular): kurulum diske gitmez.
@export var preloaded: Array[Resource] = []
## Ana iş parçacığında kare başına kurulum bütçesi (ms).
@export var frame_budget_ms := 5.0

var layout: Dictionary = {}
## Zeminin yüzü (TerrainShape): oyuncu, kamera ve kişiler sorar.
var ground: OrdosGround
## Kurulum ölçüleri (budget_probe; OrdosWorld.build_stats gibi).
var build_stats := {"frames": 0, "max_frame_ms": 0.0, "main_ms": 0.0, "ready_ms": 0.0, "steps": {}}
var home: HomeYurt
var cradle: Node3D
var cradle_model: MeshyProp
var swaddle: Node3D
var small_bow: Node3D
## Mete'nin asılacak yayı (sahne asana dek gizli; DepartScene taşır).
var mete_bow: Node3D
var cart: DepartCart
var cart_horse: RideableHorse
var horse: RideableHorse
var campfire: Campfire
var props: Array[CampProp] = []
var snow: GPUParticles3D

var _places: Node3D
var _ground_node: Node3D
var _steps: Array[Callable] = []
var _ready_flag := false
var _started_us := 0
var _job_id := -1
var _job_result: Dictionary = {}
var _job_done := false
var _horse_locked := false
## Kar yağışının izlediği düğüm (kamera odağı; yoksa yerinde).
var snow_follow: Node3D


func _ready() -> void:
	_started_us = Time.get_ticks_usec()
	layout = load_layout(layout_path)
	ground = OrdosGround.new(layout)
	_places = _group("Places")
	_ground_node = _group("Ground")
	# Zeminin ağı iş parçacığında kendi yüzüyle pişer (FastNoiseLite örnek başınadır).
	var spec := layout.duplicate(true)
	_job_id = WorkerThreadPool.add_task(func() -> void: _job_result = DepartWorld.bake_ground(spec), false, "depart_ground")
	var places: Dictionary = layout.get("places", {})
	for id: String in places:
		_steps.append(_build_place.bind(id, places[id]))
	_steps.append(_build_cradle)
	_steps.append(_build_cart)
	_steps.append(_build_horse)
	_steps.append(_build_campfire)
	_steps.append(_build_props)
	_steps.append(_build_snowfall)
	set_process(true)


func _exit_tree() -> void:
	if _job_id >= 0 and not _job_done:
		WorkerThreadPool.wait_for_task_completion(_job_id)
		_job_done = true


func _process(_delta: float) -> void:
	if _ready_flag:
		_follow_snow()
		return
	var started := Time.get_ticks_usec()
	if not _job_done and _job_id >= 0 and WorkerThreadPool.is_task_completed(_job_id):
		WorkerThreadPool.wait_for_task_completion(_job_id)
		_job_done = true
		_steps.push_front(_apply_ground)
	while not _steps.is_empty():
		var step: Callable = _steps.pop_front()
		var step_started := Time.get_ticks_usec()
		step.call()
		var steps: Dictionary = build_stats["steps"]
		steps[step.get_method()] = maxf(float(steps.get(step.get_method(), 0.0)), (Time.get_ticks_usec() - step_started) / 1000.0)
		if (Time.get_ticks_usec() - started) / 1000.0 >= frame_budget_ms:
			break
	var ms := (Time.get_ticks_usec() - started) / 1000.0
	build_stats["frames"] = int(build_stats["frames"]) + 1
	build_stats["main_ms"] = float(build_stats["main_ms"]) + ms
	build_stats["max_frame_ms"] = maxf(float(build_stats["max_frame_ms"]), ms)
	if _steps.is_empty() and _job_done and _job_result.is_empty():
		_ready_flag = true
		build_stats["ready_ms"] = (Time.get_ticks_usec() - _started_us) / 1000.0
		world_ready.emit()


# --- Yüz ------------------------------------------------------------------------------------------

## Kuruldu mu (zemin, yurtlar, eşyalar)?
func is_ready() -> bool:
	return _ready_flag


func get_terrain_shape() -> OrdosGround:
	return ground


func get_sky_rig() -> SkyRig:
	return get_node_or_null(^"SkyRig") as SkyRig


## Yerin düğümü (layout "places" kimliği; yoksa null).
func place(id: String) -> Node3D:
	return _places.get_node_or_null(NodePath(_node_name(id))) as Node3D if _places else null


## İşaretin dünya konumu, zeminde: layout "markers", ev yurdunun yerli işaretleri (mete_start, hang_spot, yanchi_stand, inside, door_out),
## yerlerin kendileri (cradle, horse, cart, campfire). Yoksa Vector3.INF.
func marker(id: String) -> Vector3:
	match id:
		"cradle":
			if is_instance_valid(cradle):
				return cradle.global_position
		"horse":
			if is_instance_valid(horse):
				return horse.global_position
		"cart":
			if is_instance_valid(cart):
				return cart.global_position
		"campfire":
			if is_instance_valid(campfire):
				return campfire.global_position
	var markers: Dictionary = layout.get("markers", {})
	if markers.has(id):
		return _on_ground(OrdosGround._vec2(markers[id]))
	for place_id: String in layout.get("places", {}):
		var def: Dictionary = layout["places"][place_id]
		var local: Dictionary = def.get("local", {})
		if local.has(id):
			return _on_ground(place_point(def, OrdosGround._vec2(local[id])))
		if id == "cradle" and def.has("cradle"):
			return _on_ground(place_point(def, OrdosGround._vec2((def["cradle"] as Dictionary).get("at", [0.0, 0.0]))))
	return Vector3.INF


## Yerin yerli noktasının dünya noktası (saf; x, z): yerin dönüşü kapının pusula yönündendir (kapı yerel +z).
static func place_point(def: Dictionary, local: Vector2) -> Vector2:
	var at := OrdosGround._vec2(def.get("at", [0.0, 0.0]))
	var p := OrdosWorld.door_basis(float(def.get("door_az", 180.0))) * Vector3(local.x, 0.0, local.y)
	return at + Vector2(p.x, p.z)


## Pusula yönünün (0 kuzey, 90 doğu) yatay birim vektörü (saf; x, z).
static func azimuth_vector(az_deg: float) -> Vector2:
	var a := deg_to_rad(az_deg)
	return Vector2(sin(a), -cos(a))


## Pusula yönüne bakan düğümün dönüşü (yerel +Z o yöne; radyan, PlayerController.spawn_at ve Rideable.place gibi).
static func yaw_of(az_deg: float) -> float:
	return deg_to_rad(180.0 - az_deg)


## Oyuncunun çarpıştığı daireler Vector3(x, z, yarıçap): yurtlar (ev yurdunun yalnız ocağı: duvarı RingWall'dur), ateş, eşyalar.
func collect_obstacles() -> Array[Vector3]:
	var out := DepartWorld.yurt_circles(layout)
	if is_instance_valid(campfire):
		out.append_array(campfire.get_obstacle_circles())
	for p in props:
		if is_instance_valid(p):
			out.append_array(p.get_obstacle_circles())
	return out


## Yurtların daireleri (saf): kapalı yurtlar bütün, ev yurdunun ortasında ocak.
static func yurt_circles(p_layout: Dictionary) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var places: Dictionary = p_layout.get("places", {})
	for id: String in places:
		var def: Dictionary = places[id]
		var at := OrdosGround._vec2(def.get("at", [0.0, 0.0]))
		if str(def.get("kind", "")) == "home":
			out.append(Vector3(at.x, at.y, HEARTH_RADIUS))
		else:
			out.append(Vector3(at.x, at.y, float(def.get("radius", 3.0)) + YURT_PAD))
	return out


## Kapılı duvarlar (saf): ev yurdunun keçe duvarı (kapıdan girilir, çıkılır).
static func yurt_walls(p_layout: Dictionary) -> Array[RingWall]:
	var out: Array[RingWall] = []
	var places: Dictionary = p_layout.get("places", {})
	for id: String in places:
		var def: Dictionary = places[id]
		if str(def.get("kind", "")) == "home":
			var r := float(def.get("radius", 3.2))
			var door := azimuth_vector(float(def.get("door_az", 180.0)))
			# Duvar keçe ile astar arasındadır (OrdosWorld'ün doğum yurdu gibi); kapı aralığı modelin kapısı.
			out.append(RingWall.new(OrdosGround._vec2(def.get("at", [0.0, 0.0])), r * 0.85, door, DOOR_HALF_WIDTH, r * 0.17))
	return out


func collect_walls() -> Array[RingWall]:
	return DepartWorld.yurt_walls(layout)


## Kutular: ev yurdunun döşeği ve beşiği, araba, çeken at; sahne açana dek Mete'nin atı (binilmezken grupta değildir).
func collect_boxes() -> Array[ObstacleBox]:
	var out: Array[ObstacleBox] = []
	var def: Dictionary = (layout.get("places", {}) as Dictionary).get("yanchi_yurt", {})
	if def.has("bed"):
		var bed: Dictionary = def["bed"]
		var size := OrdosGround._vec2(bed.get("size", [0.95, 1.8]))
		var at := place_point(def, OrdosGround._vec2(bed.get("at", [0.0, 0.0])))
		var basis := OrdosWorld.door_basis(float(def.get("door_az", 180.0)))
		out.append(ObstacleBox.from_transform(Transform3D(basis, Vector3(at.x, 0.0, at.y)), size * 0.5))
	if is_instance_valid(cradle):
		out.append(ObstacleBox.from_transform(cradle.global_transform, Vector2(PrologueBirth.CRADLE_SIZE.x * 0.5, PrologueBirth.CRADLE_SIZE.z * 0.5 + 0.04)))
	if is_instance_valid(cart):
		out.append(cart.obstacle_box())
	if is_instance_valid(cart_horse):
		out.append(cart_horse.obstacle_box())
	if is_instance_valid(horse) and _horse_locked:
		out.append(horse.obstacle_box())
	return out


## Yürünür alan: {center, radius, soft_edge}.
func play_area() -> Dictionary:
	var area: Dictionary = layout.get("walk_area", {})
	return {
		"center": OrdosGround._vec2(area.get("center", [0.0, 0.0])),
		"radius": float(area.get("radius", 30.0)),
		"soft_edge": float(area.get("soft_edge", 3.0)),
	}


func camera_bounds() -> Rect2:
	var bounds: Dictionary = layout.get("camera_bounds", {})
	var a := OrdosGround._vec2(bounds.get("min", [-50.0, -50.0]))
	var b := OrdosGround._vec2(bounds.get("max", [50.0, 50.0]))
	return Rect2(a, b - a)


func clamp_camera_transform(xform: Transform3D, focus: Vector3) -> Transform3D:
	return OrdosWorld.clamp_to_bounds(xform, focus, camera_bounds())


## Mete'nin atı binilemez (locked) ya da binilir: binilemezken mounts grubunda değildir (E'nin işi yok, ipucu çıkmaz), engel kutusudur.
func lock_horse(locked: bool) -> void:
	_horse_locked = locked
	if not is_instance_valid(horse):
		return
	if locked and horse.is_in_group(Rideable.GROUP):
		horse.remove_from_group(Rideable.GROUP)
	elif not locked and not horse.is_in_group(Rideable.GROUP):
		horse.add_to_group(Rideable.GROUP)


func is_horse_locked() -> bool:
	return _horse_locked


## Mete'nin yayının kemerde asılı dönüşümü (dünya): küçük yayın yanında, beşiğin boyunca yatık, kirişi yukarıda.
func hang_transform() -> Transform3D:
	if not is_instance_valid(cradle):
		return Transform3D.IDENTITY
	var local := Vector3(0.0, PrologueBirth.CRADLE_LIFT + PrologueBirth.CRADLE_SIZE.y + PrologueBirth.ARCH_RISE - 0.2, 0.0)
	if is_instance_valid(small_bow) and small_bow.get_child_count() > 0:
		local = small_bow.position
	elif is_instance_valid(cradle_model):
		local = cradle_model.model_to_local(PrologueBirth.BOW_SPOT)
	# Yayın modeli dikeydir (uzun eksen +Y, kavisi X): beşiğin uzun eksenine (yerel X) yatırılır, sırtı aşağı.
	var lay := Basis(Vector3.BACK, PI * 0.5) * Basis(Vector3.UP, PI * 0.5)
	return cradle.global_transform * Transform3D(lay, local + HUNG_BOW_OFFSET)


## Haritanın tarifi (WorldMap.bake): yürünür alan ve yerler; atlar, kişiler gizlenir (hide).
func map_spec(extra_hide: Array = []) -> Dictionary:
	var area := play_area()
	var places: Array = []
	for pair: Array in [["Yançi'nin yurdu", "inside"], ["Avlu", "courtyard"], ["Huyan Hatun'un yurdu", "huyan_stand"],
			["Teoman'ın otağı", "teoman_door"], ["At", "horse"]]:
		var at := marker(pair[1])
		if at != Vector3.INF:
			places.append({"name": pair[0], "at": Vector2(at.x, at.z)})
	var hide: Array = extra_hide.duplicate()
	for n: Node in [horse, cart_horse, snow]:
		if is_instance_valid(n):
			hide.append(n)
	return {
		"key": "depart_yurt", "title": "Tanhu Kampı", "subtitle": "Kış, şafaktan önce", "center": area["center"],
		"radius": float(area["radius"]), "places": places, "hide": hide,
	}


## Düzen dosyası (JSON sözlüğü; okunamazsa boş).
static func load_layout(path: String = LAYOUT_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("[depart] düzen yok: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## Zeminin ve çiğnenmiş karın dizileri (saf; iş parçacığında, kendi yüzüyle).
static func bake_ground(spec: Dictionary) -> Dictionary:
	var shape := OrdosGround.new(spec)
	return {"ground": shape.build_arrays(), "trampled": shape.build_overlay_arrays(TRAMPLED_LIFT)}


# --- Kurulum ---------------------------------------------------------------------------------------

func _apply_ground() -> void:
	var colors: Dictionary = layout.get("colors", {})
	var mi := MeshInstance3D.new()
	mi.name = "Terrain"
	mi.mesh = OrdosGround.make_mesh(_job_result["ground"])
	mi.material_override = _ground_material(0, colors)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta(&"free_asset", FREE_SNOW[0])
	_ground_node.add_child(mi)
	_ground_node.move_child(mi, 0)
	var top := MeshInstance3D.new()
	top.name = "Trampled"
	top.mesh = OrdosGround.make_mesh(_job_result["trampled"])
	top.material_override = _ground_material(1, colors)
	top.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	top.set_meta(&"free_asset", FREE_SNOW[0])
	_ground_node.add_child(top)
	_job_result = {}


## Karın malzemesi (ordos_ground.gdshader; mode 0 kar, 1 çiğnenmiş kar): renkler layout "colors"tan.
func _ground_material(mode: int, colors: Dictionary) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = GROUND_SHADER
	mat.set_shader_parameter("mode", mode)
	var keys := ["ground", "ground_sunny", "ground_dark"] if mode == 0 else ["trampled", "trampled_light", "trampled_edge"]
	for i in keys.size():
		if colors.has(keys[i]):
			mat.set_shader_parameter(["base_color", "sunny_color", "dark_color"][i], SkyRig.to_color(colors[keys[i]]))
	if colors.has("trampled_tint"):
		mat.set_shader_parameter("trampled_tint", SkyRig.to_color(colors["trampled_tint"]))
	if colors.has("shadow_tint"):
		mat.set_shader_parameter("shadow_tint", SkyRig.to_color(colors["shadow_tint"]))
	mat.set_shader_parameter("mottle_tex", _texture(FREE_SNOW[1]))
	mat.set_shader_parameter("mottle_tile", 7.0 if mode == 0 else 4.0)
	mat.set_shader_parameter("mottle_strength", 0.1 if mode == 0 else 0.32)
	mat.set_shader_parameter("variation_scale", 0.035)
	mat.set_shader_parameter("slope_light", 0.35)
	var zones := ground.ground_uniforms(MAX_CIRCLES, MAX_TRAILS)
	for key: String in zones:
		mat.set_shader_parameter(key, zones[key])
	return mat


func _build_place(id: String, def: Dictionary) -> void:
	var at := OrdosGround._vec2(def.get("at", [0.0, 0.0]))
	var kind := str(def.get("kind", "yurt"))
	var yurt: Yurt
	match kind:
		"home":
			var h := HomeYurt.new()
			h.floor_texture = _texture(FREE_FLOOR[1])
			h.bed = def.get("bed", {})
			yurt = h
		"closed":
			yurt = ClosedYurt.new()
		_:
			yurt = Yurt.new()
	yurt.name = _node_name(id)
	yurt.radius = float(def.get("radius", 3.0))
	if def.has("felt"):
		yurt.felt_color = SkyRig.to_color(def["felt"])
	yurt.has_smoke = bool(def.get("smoke", true))
	yurt.hanging_angle = float(def.get("hanging_angle", 0.0))
	yurt.emblem_angle = float(def.get("emblem_angle", 0.0))
	yurt.interior_light_energy = float(def.get("interior_light", yurt.interior_light_energy))
	yurt.transform = Transform3D(OrdosWorld.door_basis(float(def.get("door_az", 180.0))), _on_ground(at))
	_places.add_child(yurt)
	OrdosWorld._clean_steps(yurt)
	DepartWorld.simple_shadow(yurt)
	if yurt is HomeYurt:
		home = yurt as HomeYurt
		var hearth_def: Dictionary = def.get("hearth", {})
		var hearth := HearthEmbers.new()
		hearth.name = "Hearth"
		hearth.ash_texture = _texture(FREE_ASH[1])
		var local := OrdosGround._vec2(hearth_def.get("at", [0.0, 0.0]))
		hearth.position = Vector3(local.x, 0.0, local.y)
		hearth.light_energy = float(hearth_def.get("light_energy", hearth.light_energy))
		hearth.light_range = float(hearth_def.get("light_range", hearth.light_range))
		# Köz ışığının gölgesi küp gölgedir (altı yüz): içerideki kişiler altı kez çizilirdi (bütçe, K63). Menzil yurdun içiyle sınırlıdır,
		# ışık keçeden dışarı taşmaz.
		hearth.cast_shadows = bool(hearth_def.get("shadows", hearth.cast_shadows))
		home.add_child(hearth)


## Yurdun gölgesi yalın bir gövdeden düşer (keçe duvarın silindiri, çatının konisi: ≈130 üçgen): Meshy modelinin ≈51 bin üçgeni gölge
## geçişlerinde yeniden çizilmez (bütçe: iç haritanın gölge üçgeni ≤1,5 M, K63; iki gölge dilimi). Yurdun öteki parçaları (taş basamak, kumaş,
## duman) gölge vermez. Kesitli ev yurdunun gölge kopyaları da (MeshyProp.cutaway) bununla değişir: çatı yine ayı keser, içerisi köz ışığındadır.
static func simple_shadow(yurt: Yurt) -> void:
	for mi: MeshInstance3D in yurt.find_children("*", "MeshInstance3D", true, false):
		if mi.name != "ShadowBody":
			DepartWorld._drop_shadow(mi)
	if yurt.get_node_or_null(^"ShadowBody"):
		return
	var model := yurt.find_child("YurtModel", false, false) as MeshyProp
	var h := model.get_model_aabb().size.y if model and model.has_model() else yurt.crown_height
	var r := yurt.radius * (Yurt.MODEL_WALL_RATIO if model and model.has_model() else 1.0)
	var wall := h * 0.58
	var profile := PackedVector2Array([Vector2(r, 0.0), Vector2(r, wall), Vector2(r * 1.04, wall), Vector2(r * 0.16, h * 0.97)])
	var body := MeshInstance3D.new()
	body.name = "ShadowBody"
	body.mesh = MeshKit.lathe(profile, 22)
	body.material_override = Style.toon_double(Color.WHITE)
	body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	yurt.add_child(body)


## Gölgesi bütçeye değmeyen küçük şeyler (yurdun içindeki beşik ve yay, küçük eşya, ateşin taşları) gölge vermez.
static func no_shadow(node: Node) -> void:
	if node is GeometryInstance3D:
		DepartWorld._drop_shadow(node as GeometryInstance3D)
	for gi: GeometryInstance3D in node.find_children("*", "GeometryInstance3D", true, false):
		DepartWorld._drop_shadow(gi)


## Çizimin gölgesi kalkar. Yalnız gölge veren kopya (MeshyProp.cutaway'in kesilmeyen gölge ağı) gizlenir: gölgesiz yapılsaydı görünür
## olur, kesitin üstüne bütün kabuğu çizerdi.
static func _drop_shadow(gi: GeometryInstance3D) -> void:
	if gi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
		gi.visible = false
	else:
		gi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Beşik, küçük yay ve kundak (Önsöz'ün beşiği: PrologueBirth'ün ölçüleri) ve Mete'nin asılacak yayı (gizli).
func _build_cradle() -> void:
	var def: Dictionary = (layout.get("places", {}) as Dictionary).get("yanchi_yurt", {})
	var spec: Dictionary = def.get("cradle", {})
	cradle = Node3D.new()
	cradle.name = "Cradle"
	add_child(cradle)
	var at := place_point(def, OrdosGround._vec2(spec.get("at", [0.0, 0.0])))
	var yaw := yaw_of(float(def.get("door_az", 180.0))) + deg_to_rad(float(spec.get("yaw_deg", 0.0)))
	cradle.global_transform = Transform3D(Basis(Vector3.UP, yaw), _on_ground(at))
	cradle_model = _add_model(cradle, CRADLE_MODEL, Vector3(PrologueBirth.CRADLE_SIZE.x, 0.0, PrologueBirth.CRADLE_SIZE.z))
	if cradle_model == null:
		var box := MeshInstance3D.new()
		box.name = "CradleFallback"
		box.mesh = Procedural3D.box(Vector3(PrologueBirth.CRADLE_SIZE.x, PrologueBirth.CRADLE_SIZE.y, PrologueBirth.CRADLE_SIZE.z))
		box.material_override = Style.toon(Style.WOOD)
		box.position = Vector3(0.0, PrologueBirth.CRADLE_LIFT + PrologueBirth.CRADLE_SIZE.y * 0.5, 0.0)
		cradle.add_child(box)
	swaddle = Node3D.new()
	swaddle.name = "Swaddle"
	cradle.add_child(swaddle)
	swaddle.position = cradle_model.model_to_local(PrologueBirth.SWADDLE_SPOT) if cradle_model else Vector3(0.05, PrologueBirth.CRADLE_LIFT + 0.17, 0.0)
	var baby := _add_model(swaddle, SWADDLE_MODEL, Vector3.ZERO, PrologueBirth.SWADDLE_LENGTH)
	if baby:
		baby.transform = PrologueBirth.swaddle_lay(PrologueBirth.SWADDLE_LENGTH)
		baby.set_shader_parameter(&"base_shade_strength", 0.0)
	# Küçük yay beşiğin ağından ayrılmış parçadır (cradle_bow.glb, köşeleri beşiğin model uzayında): gövdenin ölçeğiyle gösterilir, ortası
	# özgün yerine gelir (Önsöz'deki gibi: PrologueBirth._build_bow_model).
	small_bow = Node3D.new()
	small_bow.name = "SmallBow"
	cradle.add_child(small_bow)
	if cradle_model and MeshyProp.exists(PROP_FOLDER, SMALL_BOW_MODEL):
		var box := PrologueBirth.model_bounds(MeshyProp.model_path(PROP_FOLDER, SMALL_BOW_MODEL))
		var height := box.size.y * cradle_model.get_model_scale()
		var part := _add_model(small_bow, SMALL_BOW_MODEL, Vector3.ZERO, height)
		if part:
			part.position = Vector3(0.0, -height * 0.5, 0.0)
			part.set_shader_parameter(&"base_shade_strength", 0.0)
			small_bow.position = cradle_model.model_to_local(box.get_center())
	mete_bow = Node3D.new()
	mete_bow.name = "MeteBow"
	add_child(mete_bow)
	var bow := _add_model(mete_bow, BOW_MODEL, Vector3.ZERO, HUNG_BOW_LENGTH)
	if bow:
		# Modelin tabanı düğümün yerindedir: ortası düğüme gelsin (asılı yeri ve el yayın ortasındadır).
		bow.position = Vector3(0.0, -HUNG_BOW_LENGTH * 0.5, 0.0)
	else:
		var stave := MeshInstance3D.new()
		stave.name = "Stave"
		stave.mesh = Procedural3D.cylinder(0.018, 0.018, HUNG_BOW_LENGTH, 6)
		stave.material_override = Style.toon(Style.WOOD_DARK)
		mete_bow.add_child(stave)
	mete_bow.visible = false
	mete_bow.global_transform = hang_transform()
	# Yurdun içi çatının gölgesindedir: beşik, kundak ve yaylar gölge vermez (bütçe).
	DepartWorld.no_shadow(cradle)
	DepartWorld.no_shadow(mete_bow)


func _build_cart() -> void:
	var def: Dictionary = layout.get("cart", {})
	if def.is_empty():
		return
	cart = DepartCart.new()
	cart.name = "Cart"
	add_child(cart)
	var at := OrdosGround._vec2(def.get("at", [0.0, 0.0]))
	cart.global_transform = Transform3D(Basis(Vector3.UP, yaw_of(float(def.get("facing_az", 270.0)))), _on_ground(at))
	var path := str(def.get("horse", ""))
	if not path.is_empty() and ResourceLoader.exists(path):
		cart_horse = RideableHorse.new()
		cart_horse.name = "CartHorse"
		cart_horse.model_path = path
		cart_horse.effects_enabled = false
		add_child(cart_horse)
		# Arabanın atı binilmez: binek grubunda değildir, engelini dünya verir (collect_boxes).
		cart_horse.remove_from_group(Rideable.GROUP)
		var half := cart_horse.get_mount().value("half_length") + 0.55
		var local := DepartCart.horse_offset(half, float(def.get("horse_gap", 0.5)))
		var p := cart.global_transform * local
		cart_horse.place(_on_ground(Vector2(p.x, p.z)), yaw_of(float(def.get("facing_az", 270.0))))


func _build_horse() -> void:
	var def: Dictionary = layout.get("horse", {})
	var path := str(def.get("model", ""))
	if def.is_empty() or path.is_empty() or not ResourceLoader.exists(path):
		return
	horse = RideableHorse.new()
	horse.name = "Horse"
	horse.model_path = path
	add_child(horse)
	horse.place(_on_ground(OrdosGround._vec2(def.get("at", [0.0, 0.0]))), yaw_of(float(def.get("facing_az", 270.0))))
	lock_horse(true)


func _build_campfire() -> void:
	var def: Dictionary = layout.get("campfire", {})
	if def.is_empty():
		return
	campfire = Campfire.new()
	campfire.name = "Campfire"
	campfire.light_energy = float(def.get("light_energy", campfire.light_energy))
	campfire.light_range = float(def.get("light_range", campfire.light_range))
	if def.has("light_color"):
		campfire.light_color = SkyRig.to_color(def["light_color"])
	add_child(campfire)
	campfire.global_position = _on_ground(OrdosGround._vec2(def.get("at", [0.0, 0.0])))
	DepartWorld.no_shadow(campfire)
	# Karın mavisinde turuncu ışık uzağında pembeye döner, sisi boyar: ateşin havuzu küçük, sisteki payı az.
	for light: OmniLight3D in campfire.find_children("*", "OmniLight3D", true, false):
		light.light_volumetric_fog_energy = float(def.get("fog_energy", 0.2))
		light.omni_attenuation = float(def.get("light_attenuation", light.omni_attenuation))


func _build_props() -> void:
	var node := _group("Props")
	for item: Dictionary in layout.get("props", []):
		var kind: int = CampProp.Kind.get(str(item.get("kind", "")), -1)
		if kind < 0:
			continue
		var prop := CampProp.new()
		prop.kind = kind as CampProp.Kind
		prop.name = "%s%d" % [str(item.get("kind", "")).to_pascal_case(), props.size()]
		node.add_child(prop)
		prop.global_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(float(item.get("yaw_deg", 0.0)))), _on_ground(OrdosGround._vec2(item.get("at", [0.0, 0.0]))))
		if not bool(item.get("shadow", false)):
			DepartWorld.no_shadow(prop)
		props.append(prop)


## Yağan kar: kameranın odağının çevresinde yavaş, seyrek taneler (dünya uzayında; yayıcı odakla gider).
func _build_snowfall() -> void:
	var def: Dictionary = layout.get("snowfall", {})
	if def.is_empty():
		return
	var ext: Array = def.get("extents", [18.0, 8.0, 14.0])
	var extents := Vector3(float(ext[0]), float(ext[1]), float(ext[2]))
	snow = GPUParticles3D.new()
	snow.name = "Snow"
	snow.amount = int(def.get("amount", 600))
	snow.lifetime = float(def.get("lifetime", 9.0))
	snow.preprocess = snow.lifetime
	snow.local_coords = false
	snow.visibility_aabb = AABB(-extents * 1.6 - Vector3(0.0, extents.y * 2.0, 0.0), extents * 3.2 + Vector3(0.0, extents.y * 2.0, 0.0))
	snow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = extents
	pm.direction = Vector3(0.15, -1.0, 0.05)
	pm.spread = 12.0
	pm.initial_velocity_min = 0.2
	pm.initial_velocity_max = 0.45
	pm.gravity = Vector3(0.12, -float(def.get("fall", 0.85)) * 0.25, 0.04)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.35
	pm.turbulence_noise_scale = 5.0
	pm.scale_min = 0.6
	pm.scale_max = 1.25
	snow.process_material = pm
	var quad := QuadMesh.new()
	var size := float(def.get("size", 0.1))
	quad.size = Vector2(size, size)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true
	mat.albedo_texture = Fx.soft_dot_texture()
	mat.albedo_color = Color(0.92, 0.95, 1.0, 0.85)
	mat.disable_receive_shadows = true
	quad.material = mat
	snow.draw_pass_1 = quad
	add_child(snow)
	snow.global_position = Vector3(0.0, extents.y, 0.0)


func _follow_snow() -> void:
	if snow == null or not is_instance_valid(snow_follow):
		return
	var at := snow_follow.global_position
	snow.global_position = Vector3(at.x, at.y + float(snow.process_material.get(&"emission_box_extents").y) * 0.6, at.z)


# --- Yardımcılar ------------------------------------------------------------------------------------

func _on_ground(p: Vector2) -> Vector3:
	return Vector3(p.x, ground.height_at(p.x, p.y) if ground else 0.0, p.y)


func _group(group_name: String) -> Node3D:
	var node := get_node_or_null(NodePath(group_name)) as Node3D
	if node == null:
		node = Node3D.new()
		node.name = group_name
		add_child(node)
	return node


static func _node_name(id: String) -> String:
	return id.to_pascal_case()


## Doku: önce sahneyle birlikte yüklenenlerden, yoksa ResourceLoader'dan.
func _texture(path: String) -> Texture2D:
	for res in preloaded:
		if res is Texture2D and res.resource_path == path:
			return res
	return load(path) as Texture2D if ResourceLoader.exists(path) else null


## Meshy modeli (assets/props/<kimlik>): fit kutusuna ya da size boyuna sığar; yoksa null.
func _add_model(parent: Node3D, id: String, fit: Vector3 = Vector3.ZERO, size: float = 1.0) -> MeshyProp:
	if not MeshyProp.exists(PROP_FOLDER, id):
		return null
	var prop := MeshyProp.new()
	prop.name = "Model"
	prop.model_id = id
	prop.folder = PROP_FOLDER
	prop.fit_box = fit
	prop.target_size = size
	parent.add_child(prop)
	if prop.has_model():
		return prop
	parent.remove_child(prop)
	prop.free()
	return null


# --- Yurtlar ---------------------------------------------------------------------------------------

## Yançi'nin yurdu: Lan Hatun'un doğum yurdunun içi (toprak taban, kerege astarı) kendi döşemesiyle: başköşede keçe, erkekler yanında
## döşek, kadınlar yanında beşik (beşik dünyanındır). Oyuncu içerideyken kabuk ve astar kesilir (çatı kalkar, kameraya bakan duvar alçalır;
## K98 diorama): FollowCamera'nın örten nesnelerindendir, her kare set_camera_occlusion(kamera, hedef) gelir.
class HomeYurt:
	extends OrdosWorld.BirthYurt

	## Döşek: {at: [x, z], size: [en, boy]} (yerel).
	var bed: Dictionary = {}
	## Kesitin o anki ve istenen açıklığı (0 kapalı, 1 açık).
	var cut := 0.0
	var cut_goal := 0.0
	## Kesit kendiliğinden mi (oyuncu içerideyse açık) yoksa sahnenin elinde mi (force_cut; -1 kendiliğinden)?
	var force_cut := -1.0
	var _cut_mats: Array[ShaderMaterial] = []
	var _cut_ready := false
	var _camera_dir := Vector2(0.0, 1.0)

	func _ready() -> void:
		super._ready()
		add_to_group(FollowCamera.OCCLUDER_GROUP)
		_enable_cut.call_deferred()

	func _process(delta: float) -> void:
		var goal := force_cut if force_cut >= 0.0 else cut_goal
		if not is_equal_approx(cut, goal):
			cut = move_toward(cut, goal, delta * CUT_RATE)
			_write_cut()

	## Takip kamerasının görüş hattı (FollowCamera._notify_occluders): hedef içerideyse kesit açılır; kesitin yönü kameraya doğrudur.
	func set_camera_occlusion(from: Vector3, to: Vector3) -> void:
		var c := global_position
		var d := Vector2(from.x - c.x, from.z - c.z)
		if d.length_squared() > 0.0001:
			_camera_dir = d.normalized()
		cut_goal = 1.0 if Vector2(to.x - c.x, to.z - c.z).length() < radius * 0.9 else 0.0
		_write_cut()

	## Kesitin hemen açıklığı (sahnenin ilk karesi: oyuncu içeride doğar).
	func snap_cut(amount: float) -> void:
		cut = clampf(amount, 0.0, 1.0)
		cut_goal = cut
		_write_cut()

	## Modelin kabuğu kesitli malzemeye geçer (MeshyProp.cutaway: görünen meshler gölge vermez, gölgeyi kesilmeyen kopya verir); astarın
	## malzemeleri zaten kesitlidir.
	func _enable_cut() -> void:
		if not is_inside_tree():
			return
		var shell: MeshyProp = _model
		if shell and not shell.cutaway:
			shell.cutaway = true
			await get_tree().process_frame
			await get_tree().process_frame
		# Kesitli kabuğun gölge kopyaları (modelin bütün ağı) yerine yurdun yalın gölge gövdesi (simple_shadow).
		DepartWorld.simple_shadow(self)
		_collect_cut_materials()
		_cut_ready = true
		_write_cut()

	func _collect_cut_materials() -> void:
		_cut_mats.clear()
		var shell: MeshyProp = _model
		if shell:
			_cut_mats.append_array(shell.get_materials())
		var lining := get_node_or_null(^"Lining")
		if lining:
			for mi: MeshInstance3D in lining.find_children("*", "MeshInstance3D", true, false):
				if mi.material_override is ShaderMaterial:
					_cut_mats.append(mi.material_override as ShaderMaterial)

	func cut_materials() -> Array[ShaderMaterial]:
		return _cut_mats

	func _write_cut() -> void:
		if not _cut_ready:
			return
		var c := global_position
		var h := _model.get_model_aabb().size.y if _model else 4.0
		var wall_top := h * 0.58 - 0.12
		for mat in _cut_mats:
			mat.set_shader_parameter(&"cut_amount", cut)
			mat.set_shader_parameter(&"cut_center", c)
			mat.set_shader_parameter(&"cut_dir", _camera_dir)
			mat.set_shader_parameter(&"cut_radius", radius * 1.08)
			mat.set_shader_parameter(&"cut_low", 0.5)
			mat.set_shader_parameter(&"cut_top", wall_top)
			mat.set_shader_parameter(&"cut_ceiling", h + 0.3)

	## Keçeler: başköşede (tör) şırdak, kadınlar yanında küçük keçe, erkekler yanında döşek (üstünde şırdak).
	func _build_felts() -> void:
		var tor_mat := ShaderMaterial.new()
		tor_mat.shader = SHYRDAK_SHADER
		tor_mat.set_shader_parameter("size", Vector2(2.0, 1.1))
		tor_mat.set_shader_parameter("color_a", Color(0.5, 0.09, 0.06))
		tor_mat.set_shader_parameter("color_b", Color(0.12, 0.16, 0.32))
		var tor := PlaneMesh.new()
		tor.size = Vector2(2.0, 1.1)
		var tor_mi := add_mesh(tor, tor_mat, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.02, -1.45)))
		tor_mi.name = "FeltTor"
		tor_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var side_mat := ShaderMaterial.new()
		side_mat.shader = SHYRDAK_SHADER
		side_mat.set_shader_parameter("size", Vector2(1.3, 0.9))
		side_mat.set_shader_parameter("color_a", Color(0.2, 0.25, 0.42))
		side_mat.set_shader_parameter("color_b", Color(0.72, 0.62, 0.48))
		var side := PlaneMesh.new()
		side.size = Vector2(1.3, 0.9)
		var side_mi := add_mesh(side, side_mat, Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(1.0, 0.021, -0.55)))
		side_mi.name = "FeltSide"
		side_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var at := OrdosGround._vec2(bed.get("at", [-1.35, -0.55]))
		var size := OrdosGround._vec2(bed.get("size", [0.95, 1.8]))
		var bed_mi := add_mesh(box(Vector3(size.x, 0.14, size.y)), Style.toon(Style.FELT.darkened(0.1), {"brush_strength": 0.2}),
			Transform3D(Basis.IDENTITY, Vector3(at.x, 0.07, at.y)))
		bed_mi.name = "FeltBed"
		var top_mat := ShaderMaterial.new()
		top_mat.shader = SHYRDAK_SHADER
		top_mat.set_shader_parameter("size", size - Vector2(0.05, 0.05))
		top_mat.set_shader_parameter("color_a", Color(0.46, 0.1, 0.07))
		top_mat.set_shader_parameter("color_b", Color(0.74, 0.66, 0.5))
		var top := PlaneMesh.new()
		top.size = size - Vector2(0.05, 0.05)
		var top_mi := add_mesh(top, top_mat, Transform3D(Basis.IDENTITY, Vector3(at.x, 0.142, at.y)))
		top_mi.name = "FeltBedTop"
		top_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	## Kase ocağın erkekler yanında (beşiğin önü açık kalsın).
	func _build_bowl() -> void:
		var profile := PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.06, 0.0), Vector2(0.1, 0.04),
			Vector2(0.12, 0.095), Vector2(0.122, 0.11)])
		var at := Transform3D(Basis.IDENTITY, Vector3(-0.72, 0.01, 0.55))
		var bowl := add_mesh(MeshKit.lathe(profile, 20), Style.toon_double(Style.WOOD_DARK, {"brush_strength": 0.15}), at)
		bowl.name = "Bowl"
		var milk := add_mesh(MeshKit.disc(0.112, 0.092, 20), Style.toon(Color(0.95, 0.93, 0.88)), at)
		milk.name = "BowlMilk"


## Teoman'ın otağı: kapısı kapalıdır (keçe kanat ve ahşap çerçeve), içeriden ışık sızmaz; kapı önündeki taş basamaklar kalır. Duman tacından
## yükselir (içeride ocak yanar, kapı açılmaz).
class ClosedYurt:
	extends Yurt

	const DOOR_COLOR := Color(0.38, 0.13, 0.08)
	const FRAME_COLOR := Color(0.24, 0.13, 0.07)

	func _build_door_glow() -> void:
		var wall_r := _wall_radius()
		var top := _door_top()
		var leaf := add_mesh(box(Vector3(Yurt.DOOR_WIDTH + 0.16, top + 0.04, 0.08)),
			Style.toon(DOOR_COLOR, {"stripe_count": 12.0, "stripe_strength": 0.35, "brush_strength": 0.12}),
			Transform3D(Basis.IDENTITY, Vector3(0.0, (top + 0.04) * 0.5, wall_r + 0.06)))
		leaf.name = "DoorClosed"
		var frame := Style.toon(FRAME_COLOR, {"brush_strength": 0.1})
		for side: float in [-1.0, 1.0]:
			var post := add_mesh(box(Vector3(0.12, top + 0.16, 0.14)), frame,
				Transform3D(Basis.IDENTITY, Vector3(side * (Yurt.DOOR_WIDTH * 0.5 + 0.14), (top + 0.16) * 0.5, wall_r + 0.08)))
			post.name = "DoorPost%s" % ("L" if side < 0.0 else "R")
		var lintel := add_mesh(box(Vector3(Yurt.DOOR_WIDTH + 0.5, 0.14, 0.16)), frame,
			Transform3D(Basis.IDENTITY, Vector3(0.0, top + 0.1, wall_r + 0.08)))
		lintel.name = "DoorLintel"

	func _build_hearth() -> void:
		pass

	func _build_lights() -> void:
		pass
