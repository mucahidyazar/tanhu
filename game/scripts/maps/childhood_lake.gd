class_name ChildhoodLake
extends Node3D
## Kamışlı Göl (E21, K110; story.md §5 «İki yeni gün»; layout.json "childhood.lake", "childhood.lake_site"): yalnız Çocukluk'ta (ChildhoodSite kurar;
## doğumun bozkırında göl yoktur). Suyu ve kıyının yaşamını taşır:
##   Water       su yüzü: kampın gölünün gölgelendiricisi (water.gdshader; Ordos'un renkleri), su seviyesinde düz ağ (kıyı çizgisinden 2,5 m
##               dışarıya dek 2 m'lik hücreler; kıyıdaki kum suyun altında kalır, derinliğe göre açılır ve kıyıda söner)
##   Reeds       sazlık: kıyının sığında ve kıyıda uzun saz tutamları (atw_grass; rüzgârla eğilir), parça başına bir MultiMesh
##   Mud         sazın dibinde balçık: parlak, ıslak koyu toprak (kuzu burada saplanır)
##   WhiteStone  ak taş: sazlığın dibinde, yüzme derinliğinde; suyun altından soluk parlar (yaklaşınca seçilir), dalışla alınır (take_stone)
##   CountStones iki sayım taşı (ikindi sayımı)
##   Ducks       ördekler: gölün ortasında ağır ağır yüzer, oyuncu yaklaşınca kanat çırpıp uzağa konar
##   Rings       suda halkalar (ring(yer, boy)): dalış, yüzme, içen koyun, ördek, arada balık
##   Shore       kıyıya vuran küçük dalga: kıyı çizgisi boyunca köpük şeridi (lake_shore.gdshader)
## Dalışta su yüzü saydamlaşır (reveal): dip ve taş görünür (Water'ın GeometryInstance3D.transparency'si).
## Ağır diziler iş parçacığında hesaplanır (compute); düğümler parça parça kurulur (parts: ChildhoodSite kare bütçesinde sırayla çağırır,
## deferred iken _ready kurmaz; sınamada _ready hepsini kurar).

const RING_SHADER := preload("res://shaders/water_ring.gdshader")
const SHORE_SHADER := preload("res://shaders/lake_shore.gdshader")
const GRASS_SHADER := preload("res://shaders/atw_grass.gdshader")
const MAX_RINGS := 24
## Sazın renkleri (güz: kökte yeşil, uçta saman sarısı) ve rüzgârı.
const REED_COLORS := {"root_color": Color(0.33, 0.36, 0.2), "mid_color": Color(0.5, 0.52, 0.27), "tip_color": Color(0.76, 0.66, 0.4),
	"sun_color": Color(0.84, 0.72, 0.42), "deep_color": Color(0.36, 0.38, 0.22)}
## Ak taşın erimi (dalışta alınır, m) ve suyun altından seçildiği uzaklık (m).
const STONE_REACH := 1.9
const STONE_SEEN := 14.0
## Ördeğin yüzüşü (m/sn) ve kaçışı.
const DUCK_PADDLE := 0.35
const DUCK_FLY := 7.0

var world: Node3D
var ground: OrdosGround
var def: Dictionary = {}
## Suyun renkleri (childhood.lake.water).
var water_colors: Dictionary = {}
var level := 0.0
## Ak taş alındı mı?
var stone_taken := false
var stone_node: Node3D
var ducks: Array[Dictionary] = []

## Parçaları ChildhoodSite mi kuracak (kare bütçesinde)?
var deferred := false
var water: MeshInstance3D

var _arrays: Dictionary = {}
var _built := false
var _rings: MultiMeshInstance3D
var _ring_data: Array[Vector4] = []
var _ring_power := PackedFloat32Array()
var _player_cache: Node3D
var _rng := RandomNumberGenerator.new()
var _fish_left := 3.0
var _reveal_tween: Tween
var _halo: MeshInstance3D
var _time := 0.0


## Kurulum (ağaca eklenmeden önce): dünya, Çocukluk'un yüzü, düzen ve iş parçacığında hazırlanan diziler (compute; yoksa burada hesaplanır).
func setup(p_world: Node3D, p_ground: OrdosGround, layout: Dictionary, arrays: Dictionary = {}) -> void:
	world = p_world
	ground = p_ground
	def = (layout.get("childhood", {}) as Dictionary).get("lake_site", {})
	water_colors = ((layout.get("childhood", {}) as Dictionary).get("lake", {}) as Dictionary).get("water", {})
	level = ground.lake_level if ground and ground.lake_half_width > 0.0 else 0.0
	_rng.seed = 2026
	_arrays = arrays


## Ağır dizilerin hesabı (saf; iş parçacığında): sazlığın iki tamponu, balçığın ve kıyının dalgasının ağ dizileri. spec Çocukluk'un yüzünün
## tanımıdır (ChildhoodSite.baked_spec).
static func compute(spec: Dictionary) -> Dictionary:
	var shape := OrdosGround.new(spec)
	if shape.lake_half_width <= 0.0:
		return {}
	var d: Dictionary = (spec.get("childhood", {}) as Dictionary).get("lake_site", {})
	return compute_from_ground(shape, d)


func _ready() -> void:
	if ground == null or ground.lake_half_width <= 0.0:
		set_process(false)
		return
	if deferred:
		return
	for part in parts():
		part.call()


## Kurulumun parçaları (sırayla; her biri bir karenin dilimine sığar): su, sazlık, balçık, ak taş, sayım taşları, ördekler, halkalar, kıyı.
func parts() -> Array[Callable]:
	if _built or ground == null or ground.lake_half_width <= 0.0:
		return []
	_built = true
	if _arrays.is_empty():
		_arrays = compute_from_ground(ground, def)
	return [_build_water, _build_reeds, _build_mud, _build_stone, _build_count_stones, _build_ducks, _build_rings, _build_shore]


func _process(delta: float) -> void:
	_time += delta
	_tick_rings(delta)
	_tick_ducks(delta)
	_fish_left -= delta
	if _fish_left <= 0.0:
		_fish_left = _rng.randf_range(4.0, 9.0)
		var p := _random_water_point(4.0)
		if p != Vector3.INF:
			ring(p, _rng.randf_range(0.8, 1.4), 0.6)
	if is_instance_valid(_halo) and is_instance_valid(stone_node):
		var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
		var player := _player_pos()
		var near := 0.0 if player == Vector3.INF else 1.0 - smoothstep(STONE_SEEN * 0.5, STONE_SEEN, ChildhoodStep.flat(player, stone_node.global_position))
		_halo.visible = not stone_taken and near > 0.01 and cam != null
		if _halo.visible:
			(_halo.material_override as StandardMaterial3D).albedo_color.a = near * (0.55 + 0.25 * sin(_time * 2.2))


# --- Yüz ---------------------------------------------------------------------------------------------------

## Suda halka: yer (yüzeye oturur), boy (en büyük yarıçap, m), güç (0..1).
func ring(at: Vector3, size: float = 1.2, power: float = 1.0) -> void:
	if _ring_data.size() >= MAX_RINGS:
		_ring_data.pop_front()
		_ring_power.remove_at(0)
	_ring_data.append(Vector4(at.x, at.z, size, 0.0))
	_ring_power.append(clampf(power, 0.0, 1.0))


## Süren halka sayısı (sınama).
func ring_count() -> int:
	return _ring_data.size()


## Ak taşın yeri (alındıysa Vector3.INF).
func stone_position() -> Vector3:
	return stone_node.global_position if is_instance_valid(stone_node) and not stone_taken else Vector3.INF


## Ak taş erimde mi (dalışta; düzlemde)?
func stone_in_reach(at: Vector3) -> bool:
	var p := stone_position()
	return p != Vector3.INF and ChildhoodStep.flat(at, p) <= STONE_REACH


## Ak taşı alır (gizlenir); alındıysa false.
func take_stone() -> bool:
	if stone_taken or not is_instance_valid(stone_node):
		return false
	stone_taken = true
	stone_node.visible = false
	if is_instance_valid(_halo):
		_halo.visible = false
	return true


## Ak taşı yerine koyar (atlanan adım, sınama).
func reset_stone() -> void:
	stone_taken = false
	if is_instance_valid(stone_node):
		stone_node.visible = true


## Dalışta su yüzü saydamlaşır (dip görünür); kapanınca döner.
func reveal(on: bool, seconds: float = 0.35) -> void:
	var lake := water
	if lake == null or not is_instance_valid(lake) or not is_inside_tree():
		return
	if _reveal_tween and _reveal_tween.is_valid():
		_reveal_tween.kill()
	_reveal_tween = create_tween()
	_reveal_tween.tween_property(lake, ^"transparency", 0.72 if on else 0.0, seconds).set_trans(Tween.TRANS_SINE)


## Ördeklerin yeri (sınama, kuşun kalkışı).
func duck_positions() -> PackedVector3Array:
	var out := PackedVector3Array()
	for d in ducks:
		out.append((d["node"] as Node3D).global_position)
	return out


# --- Kurulum ------------------------------------------------------------------------------------------------

## Su yüzü: düzenin renkleri (childhood.lake.water), kampın gölünün dalgacık dokuları.
func _build_water() -> void:
	var arrays: Dictionary = _arrays.get("water", {})
	if arrays.is_empty() or (arrays.get("indices", PackedInt32Array()) as PackedInt32Array).is_empty():
		return
	water = MeshInstance3D.new()
	water.name = "Water"
	var surface := []
	surface.resize(Mesh.ARRAY_MAX)
	surface[Mesh.ARRAY_VERTEX] = arrays["vertices"]
	surface[Mesh.ARRAY_NORMAL] = arrays["normals"]
	surface[Mesh.ARRAY_INDEX] = arrays["indices"]
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
	water.mesh = mesh
	var mat := ShaderMaterial.new()
	mat.shader = OrdosWorld.WATER_SHADER
	var colors: Dictionary = water_colors
	for key: String in ["deep_color", "shallow_color", "reflection_horizon", "reflection_zenith", "glint_color"]:
		if colors.has(key):
			mat.set_shader_parameter(key, SkyRig.to_color(colors[key]))
	mat.set_shader_parameter("glint_energy", float(colors.get("glint_energy", 4.0)))
	mat.set_shader_parameter("ripple_strength", float(colors.get("ripple_strength", 0.22)))
	mat.set_shader_parameter("shore_fade", 0.7)
	mat.set_shader_parameter("ripple_a", OrdosWorld._ripple_texture(19, 0.035))
	mat.set_shader_parameter("ripple_b", OrdosWorld._ripple_texture(43, 0.06))
	water.material_override = mat
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(water)


## Su yüzünün dizileri (saf; iş parçacığında): orta çizginin kutusunda cell aralıklı ızgara, orta çizgiye half_width + margin'den yakın
## hücreler; düz, seviyede, dizinli (köşeler paylaşılır).
static func water_arrays(shape: OrdosGround, cell: float = 2.0, margin: float = 2.5) -> Dictionary:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	if shape == null or shape.lake_half_width <= 0.0:
		return {"vertices": vertices, "normals": normals, "indices": indices}
	var reach := shape.lake_half_width + margin
	var box := Rect2(shape.lake_points[0], Vector2.ZERO)
	for p in shape.lake_points:
		box = box.expand(p)
	box = box.grow(reach + cell)
	var y := shape.lake_level
	var nx := ceili(box.size.x / cell)
	var nz := ceili(box.size.y / cell)
	var index_of := PackedInt32Array()
	index_of.resize((nx + 1) * (nz + 1))
	index_of.fill(-1)
	for j in nz:
		for i in nx:
			var x0 := box.position.x + float(i) * cell
			var z0 := box.position.y + float(j) * cell
			if shape.lake_distance(x0 + cell * 0.5, z0 + cell * 0.5) > reach:
				continue
			var ids := PackedInt32Array()
			for corner: Vector2i in [Vector2i(i, j), Vector2i(i + 1, j), Vector2i(i, j + 1), Vector2i(i + 1, j + 1)]:
				var key := corner.y * (nx + 1) + corner.x
				if index_of[key] < 0:
					index_of[key] = vertices.size()
					vertices.append(Vector3(box.position.x + float(corner.x) * cell, y, box.position.y + float(corner.y) * cell))
					normals.append(Vector3.UP)
				ids.append(index_of[key])
			indices.append_array(PackedInt32Array([ids[0], ids[1], ids[2], ids[1], ids[3], ids[2]]))
	return {"vertices": vertices, "normals": normals, "indices": indices}


func _build_reeds() -> void:
	var buffers: Array = _arrays.get("reeds", [])
	if buffers.is_empty():
		return
	var meshes: Array[Mesh] = [Meadow.tuft_mesh(7, 41, 0.34, 2, 0.05), Meadow.tuft_mesh(9, 43, 0.42, 2, 0.045)]
	var mat := ShaderMaterial.new()
	mat.shader = GRASS_SHADER
	mat.set_shader_parameter("instance_patches", true)
	for key: String in REED_COLORS:
		mat.set_shader_parameter(key, REED_COLORS[key])
	mat.set_shader_parameter("wind_strength", 0.16)
	mat.set_shader_parameter("wind_speed", 0.8)
	mat.set_shader_parameter("fade_start", 90.0)
	mat.set_shader_parameter("fade_end", 130.0)
	mat.set_shader_parameter("widen_max", 1.0)
	var node := Node3D.new()
	node.name = "Reeds"
	add_child(node)
	for k in mini(buffers.size(), 2):
		var buffer: PackedFloat32Array = buffers[k]
		if buffer.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = meshes[k]
		mm.instance_count = buffer.size() / 16
		mm.buffer = buffer
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Reeds%d" % k
		mmi.multimesh = mm
		mmi.material_override = mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.add_child(mmi)


## Sazlığın iki tamponu (saf): bölgelerde (daireler), kıyıdan içeri inset aralığında; boy suyun derinliğiyle kısalır.
static func reed_buffers(r: Dictionary, shape: OrdosGround) -> Array:
	var buffers: Array = [PackedFloat32Array(), PackedFloat32Array()]
	if r.is_empty():
		return buffers
	var rng := RandomNumberGenerator.new()
	rng.seed = int(r.get("seed", 515))
	var h := OrdosGround._vec2(r.get("height", [1.25, 2.05]))
	var inset := OrdosGround._vec2(r.get("inset", [-3.0, 7.0]))
	var zones: Array = r.get("zones", [])
	var count := int(r.get("count", 1000))
	var tries := 0
	var placed := 0
	while placed < count and tries < count * 4 and not zones.is_empty():
		tries += 1
		var z: Array = zones[rng.randi() % zones.size()]
		var p := Vector2(float(z[0]), float(z[1])) + Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * float(z[2])
		var s := shape.lake_half_width - shape.lake_distance(p.x, p.y)
		if s < inset.x or s > inset.y:
			continue
		var height := rng.randf_range(h.x, h.y) * lerpf(1.0, 0.8, clampf(s / inset.y, 0.0, 1.0))
		var w := height * 0.34 * rng.randf_range(0.85, 1.2)
		var y := shape.height_at(p.x, p.y) - 0.05
		var k := rng.randi() % 2
		var buffer: PackedFloat32Array = buffers[k]
		buffer.append_array(PackedFloat32Array([w, 0.0, 0.0, p.x, 0.0, height, 0.0, y, 0.0, 0.0, w, p.y,
			rng.randf(), rng.randf(), rng.randf(), rng.randf()]))
		buffers[k] = buffer
		placed += 1
	return buffers


## Balçık: lekelerin üstünde zemini izleyen ince ağ, ıslak parlak koyu toprak (kenarı köşe rengiyle söner).
func _build_mud() -> void:
	var arrays: Dictionary = _arrays.get("mud", {})
	if arrays.is_empty() or (arrays.get("vertices", PackedVector3Array()) as PackedVector3Array).is_empty():
		return
	var mi := MeshInstance3D.new()
	mi.name = "Mud"
	mi.mesh = _mesh_of(arrays)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.22
	mat.metallic_specular = 0.7
	mat.albedo_color = Color(1, 1, 1, 1)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## Balçığın ağ dizileri (saf): her leke halkalı bir disk, zeminin 3,5 cm üstünde, kenarda saydamlaşır.
static func mud_arrays(m: Dictionary, shape: OrdosGround) -> Dictionary:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var color := SkyRig.to_color(m.get("color", [0.17, 0.13, 0.09]))
	for row: Array in m.get("patches", []):
		var c := Vector2(float(row[0]), float(row[1]))
		var r := float(row[2])
		var rings := 5
		var segs := 28
		for ri in rings:
			for si in segs:
				var corners: Array[Vector2] = []
				for q: Vector2i in [Vector2i(ri, si), Vector2i(ri + 1, si), Vector2i(ri, si + 1), Vector2i(ri + 1, si + 1)]:
					var rr := r * float(q.x) / float(rings) * (1.0 + 0.12 * sin(float(q.y) * 1.7 + float(ri)))
					var a := TAU * float(q.y) / float(segs)
					corners.append(c + Vector2(cos(a), sin(a)) * rr)
				for idx in [0, 2, 1, 1, 2, 3]:
					var p: Vector2 = corners[idx]
					var edge := clampf(p.distance_to(c) / r, 0.0, 1.0)
					colors.append(Color(color.r, color.g, color.b, 1.0 - smoothstep(0.6, 1.0, edge)))
					normals.append(Vector3.UP)
					vertices.append(Vector3(p.x, shape.height_at(p.x, p.y) + 0.035, p.y))
	return {"vertices": vertices, "normals": normals, "colors": colors}


## Ak taş: yassı yuvarlak beyaz çakıl, suyun dibinde; yaklaşınca suyun altından soluk bir parıltı (derinlik sınaması kapalı, yukarıdan seçilir).
func _build_stone() -> void:
	var s: Dictionary = def.get("white_stone", {})
	if s.is_empty():
		return
	var at := OrdosGround._vec2(s.get("at", [0.0, 0.0]))
	var r := float(s.get("radius", 0.2))
	stone_node = Node3D.new()
	stone_node.name = "WhiteStone"
	add_child(stone_node)
	stone_node.global_position = Vector3(at.x, ground.height_at(at.x, at.y) + r * 0.45, at.y)
	var mi := MeshInstance3D.new()
	mi.name = "Pebble"
	var sphere := SphereMesh.new()
	sphere.radius = r
	sphere.height = r * 1.1
	sphere.radial_segments = 14
	sphere.rings = 7
	mi.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.96, 0.95, 0.9)
	mat.emission_enabled = true
	mat.emission = SkyRig.to_color(s.get("glow", [1.0, 0.98, 0.9]))
	mat.emission_energy_multiplier = 0.6
	mat.roughness = 0.4
	mi.material_override = mat
	stone_node.add_child(mi)
	_halo = MeshInstance3D.new()
	_halo.name = "Halo"
	var quad := QuadMesh.new()
	quad.size = Vector2(1.3, 1.3)
	_halo.mesh = quad
	var hm := StandardMaterial3D.new()
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	hm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	hm.no_depth_test = true
	hm.albedo_texture = Fx.soft_dot_texture()
	hm.albedo_color = Color(1.0, 0.97, 0.86, 0.0)
	_halo.material_override = hm
	_halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_halo.visible = false
	stone_node.add_child(_halo)


## İki sayım taşı: dikili, yassı (ChildhoodSite'ın yarış taşının biçimi), aralarından sürü geçer.
func _build_count_stones() -> void:
	var c: Dictionary = def.get("count_stones", {})
	if c.is_empty():
		return
	var mat := ChildhoodSite.make_rock_material()
	var ready: Array = _arrays.get("count_stones", [])
	var k := 0
	for key in ["a", "b"]:
		var arrays: Dictionary = ready[k] if k < ready.size() else ChildhoodSite._stone({"at": c.get(key, [0.0, 0.0]), "size": c.get("size", [0.5, 0.95, 0.4]), "seed": int(c.get("seed", 318)) + k * 7}, ground)
		var mi := MeshInstance3D.new()
		mi.name = "CountStone%s" % key.to_upper()
		mi.mesh = FaunaMesh.make_mesh(arrays)
		mi.material_override = mat
		add_child(mi)
		k += 1


# --- Ördekler ----------------------------------------------------------------------------------------------

func _build_ducks() -> void:
	var dd: Dictionary = def.get("ducks", {})
	if dd.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = int(dd.get("seed", 77))
	var center := OrdosGround._vec2(dd.get("center", [0.0, 0.0]))
	var radius := float(dd.get("radius", 10.0))
	var mesh := _duck_mesh()
	var mat := Style.toon(Color.WHITE, {"use_vertex_color": true, "brush_strength": 0.1})
	for i in int(dd.get("count", 5)):
		var node := MeshInstance3D.new()
		node.name = "Duck%d" % i
		node.mesh = mesh
		node.material_override = mat
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(node)
		var p := center + Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * radius
		node.global_position = Vector3(p.x, level, p.y)
		ducks.append({"node": node, "home": center, "radius": radius, "goal": p, "state": "swim", "t": rng.randf() * 4.0,
			"phase": rng.randf() * TAU, "fly_from": Vector3.ZERO, "fly_to": Vector3.ZERO, "flee": float(dd.get("flee", 14.0))})


func _tick_ducks(delta: float) -> void:
	var player := _player_pos()
	for d in ducks:
		var node: Node3D = d["node"]
		var at := node.global_position
		d["phase"] = float(d["phase"]) + delta
		match str(d["state"]):
			"swim":
				d["t"] = float(d["t"]) - delta
				var goal: Vector2 = d["goal"]
				if float(d["t"]) <= 0.0 or Vector2(at.x, at.z).distance_to(goal) < 0.3:
					d["t"] = _rng.randf_range(3.0, 8.0)
					var home: Vector2 = d["home"]
					d["goal"] = home + Vector2.from_angle(_rng.randf() * TAU) * sqrt(_rng.randf()) * float(d["radius"])
				var dir := (d["goal"] as Vector2) - Vector2(at.x, at.z)
				if dir.length() > 0.05:
					var step := dir.normalized() * minf(DUCK_PADDLE * delta, dir.length())
					at += Vector3(step.x, 0.0, step.y)
					node.rotation.y = lerp_angle(node.rotation.y, atan2(dir.x, dir.y), 1.0 - exp(-3.0 * delta))
					if _rng.randf() < delta * 0.25:
						ring(at, 0.5, 0.35)
				at.y = level + sin(float(d["phase"]) * 2.1) * 0.012
				node.global_position = at
				if player != Vector3.INF and ChildhoodStep.flat(player, at) < float(d["flee"]):
					_duck_takeoff(d, player)
			"fly":
				d["t"] = float(d["t"]) + delta / maxf(float(d["dur"]), 0.1)
				var t := clampf(float(d["t"]), 0.0, 1.0)
				var from: Vector3 = d["fly_from"]
				var to: Vector3 = d["fly_to"]
				var p := from.lerp(to, t)
				p.y += sin(t * PI) * 6.0
				node.global_position = p
				node.rotation.y = atan2(to.x - from.x, to.z - from.z)
				node.scale = Vector3(1.0 + 0.25 * absf(sin(float(d["phase"]) * 14.0)), 1.0, 1.0)
				if t >= 1.0:
					node.scale = Vector3.ONE
					d["state"] = "swim"
					d["t"] = 2.0
					d["home"] = Vector2(to.x, to.z)
					d["goal"] = Vector2(to.x, to.z)
					ring(to, 1.0, 0.7)


func _duck_takeoff(d: Dictionary, from_player: Vector3) -> void:
	var node: Node3D = d["node"]
	var at := node.global_position
	var away := Vector2(at.x - from_player.x, at.z - from_player.z).normalized()
	var target := _water_point_toward(Vector2(at.x, at.z) + away * _rng.randf_range(22.0, 34.0))
	d["state"] = "fly"
	d["t"] = 0.0
	d["fly_from"] = at
	d["fly_to"] = Vector3(target.x, level, target.y)
	d["dur"] = at.distance_to(d["fly_to"]) / DUCK_FLY
	ring(at, 1.1, 0.9)


## Gölün içinde, verilen noktaya en yakın su (orta çizgiye çekilir).
func _water_point_toward(p: Vector2) -> Vector2:
	var d := ground.lake_distance(p.x, p.y)
	var limit := ground.lake_half_width - 4.0
	if d <= limit:
		return p
	var best := p
	var best_d := INF
	for i in ground.lake_points.size() - 1:
		var a := ground.lake_points[i]
		var b := ground.lake_points[i + 1]
		var q := a.lerp(b, OrdosGround._segment_t(p, a, b))
		var dd := q.distance_to(p)
		if dd < best_d:
			best_d = dd
			best = q + (p - q).normalized() * minf(limit, dd)
	return best


## Ördeğin ağı (saf): gövde, boyun ve baş, gaga, kuyruk (köşe renkli; erkek yeşil başlı yaban ördeği).
static func _duck_mesh() -> ArrayMesh:
	var d := FaunaMesh.Draft.new()
	var body := Color(0.5, 0.42, 0.32, 0.0)
	var head := Color(0.12, 0.3, 0.2, 0.0)
	var bill := Color(0.86, 0.72, 0.24, 0.0)
	d.blob(Vector3(0.0, 0.07, 0.0), Vector3(0.14, 0.08, 0.24), Basis.IDENTITY, 1, body, Vector4.ZERO)
	d.blob(Vector3(0.0, 0.17, 0.16), Vector3(0.065, 0.07, 0.07), Basis.IDENTITY, 1, head, Vector4.ZERO)
	d.blob(Vector3(0.0, 0.155, 0.235), Vector3(0.03, 0.018, 0.05), Basis.IDENTITY, 0, bill, Vector4.ZERO)
	d.blob(Vector3(0.0, 0.1, -0.23), Vector3(0.05, 0.03, 0.06), Basis.IDENTITY, 0, body.darkened(0.3), Vector4.ZERO)
	return FaunaMesh.make_mesh(d.arrays())


# --- Halkalar ve kıyı ----------------------------------------------------------------------------------------

func _build_rings() -> void:
	_rings = MultiMeshInstance3D.new()
	_rings.name = "Rings"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	quad.orientation = PlaneMesh.FACE_Y
	mm.mesh = quad
	mm.instance_count = MAX_RINGS
	mm.visible_instance_count = 0
	_rings.multimesh = mm
	var mat := ShaderMaterial.new()
	mat.shader = RING_SHADER
	_rings.material_override = mat
	_rings.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_rings.custom_aabb = AABB(Vector3(-600.0, -50.0, -600.0), Vector3(1200.0, 100.0, 1200.0))
	add_child(_rings)


func _tick_rings(delta: float) -> void:
	if _rings == null:
		return
	var i := 0
	while i < _ring_data.size():
		var r := _ring_data[i]
		r.w += delta / (1.6 + r.z * 0.5)
		_ring_data[i] = r
		if r.w >= 1.0:
			_ring_data.remove_at(i)
			_ring_power.remove_at(i)
		else:
			i += 1
	var mm := _rings.multimesh
	mm.visible_instance_count = _ring_data.size()
	for k in _ring_data.size():
		var r := _ring_data[k]
		var s := r.z * (0.35 + 0.65 * sqrt(r.w))
		mm.set_instance_transform(k, Transform3D(Basis.IDENTITY.scaled(Vector3(s, 1.0, s)), Vector3(r.x, level + 0.02, r.y)))
		mm.set_instance_custom_data(k, Color(r.w, _ring_power[k], 0.0, 0.0))


## Kıyının köpük şeridi: diziler iş parçacığında (shore_arrays), burada ağ ve malzeme.
func _build_shore() -> void:
	var arrays: Dictionary = _arrays.get("shore", {})
	if arrays.is_empty() or (arrays.get("vertices", PackedVector3Array()) as PackedVector3Array).is_empty():
		return
	var mi := MeshInstance3D.new()
	mi.name = "Shore"
	mi.mesh = _mesh_of(arrays)
	var mat := ShaderMaterial.new()
	mat.shader = SHORE_SHADER
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)


## Kıyının köpük şeridi (saf): gölün uzaklık alanında kıyı çizgisini (orta çizgiye half_width) 1 m'lik karelerle bulur (kare yürüyüşü), her
## kesişim parçası suyun yanından karaya doğru ince bir dörtgen olur. UV.x kıyı boyunca metre (dalganın evresi), UV.y sudan karaya.
static func shore_arrays(shape: OrdosGround) -> Dictionary:
	var e := shape.lake_half_width
	var level := shape.lake_level
	var box := Rect2(shape.lake_points[0], Vector2.ZERO)
	for p in shape.lake_points:
		box = box.expand(p)
	box = box.grow(e + 3.0)
	var cell := 1.0
	var nx := ceili(box.size.x / cell)
	var nz := ceili(box.size.y / cell)
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	# Kıyıya uzak hücreler atlanır (orta çizgiye uzaklık kıyıdan 2 m'den uzaksa kesişim yoktur).
	var along := 0.0
	var row_prev := PackedFloat32Array()
	row_prev.resize(nx + 1)
	var row_next := PackedFloat32Array()
	row_next.resize(nx + 1)
	for i in nx + 1:
		row_prev[i] = shape.lake_distance(box.position.x + float(i) * cell, box.position.y) - e
	for j in nz:
		var z0 := box.position.y + float(j) * cell
		for i in nx + 1:
			row_next[i] = shape.lake_distance(box.position.x + float(i) * cell, z0 + cell) - e
		for i in nx:
			var v: Array[float] = [row_prev[i], row_prev[i + 1], row_next[i + 1], row_next[i]]
			if absf(v[0]) > 2.0 and absf(v[1]) > 2.0 and absf(v[2]) > 2.0 and absf(v[3]) > 2.0:
				continue
			var x0 := box.position.x + float(i) * cell
			var corners: Array[Vector2] = [Vector2(x0, z0), Vector2(x0 + cell, z0), Vector2(x0 + cell, z0 + cell), Vector2(x0, z0 + cell)]
			var pts: Array[Vector2] = []
			for k in 4:
				var a := v[k]
				var b := v[(k + 1) % 4]
				if (a < 0.0) != (b < 0.0):
					pts.append(corners[k].lerp(corners[(k + 1) % 4], a / (a - b)))
			if pts.size() != 2:
				continue
			var p0 := pts[0]
			var p1 := pts[1]
			var mid := (p0 + p1) * 0.5
			var grad := Vector2(shape.lake_distance(mid.x + 0.1, mid.y) - shape.lake_distance(mid.x - 0.1, mid.y),
				shape.lake_distance(mid.x, mid.y + 0.1) - shape.lake_distance(mid.x, mid.y - 0.1)).normalized()
			var quad := [p0 - grad * 0.5, p1 - grad * 0.5, p0 + grad * 0.9, p1 + grad * 0.9]
			var uv := [Vector2(along, 0.0), Vector2(along + 1.0, 0.0), Vector2(along, 1.0), Vector2(along + 1.0, 1.0)]
			along += p0.distance_to(p1)
			for idx in [0, 2, 1, 1, 2, 3]:
				var q: Vector2 = quad[idx]
				vertices.append(Vector3(q.x, maxf(level + 0.03, shape.height_at(q.x, q.y) + 0.03), q.y))
				normals.append(Vector3.UP)
				uvs.append(uv[idx])
		var swap := row_prev
		row_prev = row_next
		row_next = swap
	return {"vertices": vertices, "normals": normals, "uvs": uvs}


## Diziler hazır değilse (iş parçacığı yok: sınama) burada hesaplanır.
static func compute_from_ground(shape: OrdosGround, d: Dictionary) -> Dictionary:
	if shape == null or shape.lake_half_width <= 0.0:
		return {}
	return {"reeds": reed_buffers(d.get("reeds", {}), shape), "mud": mud_arrays(d.get("mud", {}), shape), "shore": shore_arrays(shape),
		"water": water_arrays(shape, 2.0, 2.5), "count_stones": count_stone_arrays(d.get("count_stones", {}), shape)}


## İki sayım taşının ağ dizileri (saf; iş parçacığında): [a, b] (ChildhoodSite._stone: yarış taşının biçimi).
static func count_stone_arrays(c: Dictionary, shape: OrdosGround) -> Array:
	var out: Array = []
	if c.is_empty():
		return out
	var k := 0
	for key in ["a", "b"]:
		out.append(ChildhoodSite._stone({"at": c.get(key, [0.0, 0.0]), "size": c.get("size", [0.5, 0.95, 0.4]), "seed": int(c.get("seed", 318)) + k * 7}, shape))
		k += 1
	return out


static func _mesh_of(arrays: Dictionary) -> ArrayMesh:
	var surface := []
	surface.resize(Mesh.ARRAY_MAX)
	surface[Mesh.ARRAY_VERTEX] = arrays["vertices"]
	surface[Mesh.ARRAY_NORMAL] = arrays["normals"]
	if arrays.has("colors"):
		surface[Mesh.ARRAY_COLOR] = arrays["colors"]
	if arrays.has("uvs"):
		surface[Mesh.ARRAY_TEX_UV] = arrays["uvs"]
	var mesh := ArrayMesh.new()
	if (arrays["vertices"] as PackedVector3Array).size() > 0:
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
	return mesh


# --- Yardımcılar --------------------------------------------------------------------------------------------

func _player_pos() -> Vector3:
	return _player_cache.global_position if is_instance_valid(_player_cache) and _player_cache.is_inside_tree() else Vector3.INF


## Oyuncuyu bağlar (ördeklerin kaçışı, taşın parıltısı).
func set_player(p: Node3D) -> void:
	_player_cache = p


func _random_water_point(margin: float) -> Vector3:
	for _i in 8:
		var a := ground.lake_points[_rng.randi() % ground.lake_points.size()]
		var p := a + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf() * (ground.lake_half_width - margin)
		if ground.lake_distance(p.x, p.y) < ground.lake_half_width - margin:
			return Vector3(p.x, level, p.y)
	return Vector3.INF
