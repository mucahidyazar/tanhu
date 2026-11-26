class_name GatherField
extends Node3D
## Toplama düğümlerinin görünüşü (godot.md §4.5 «Düğüm»; economy.md §3.7, §11.3–§11.4): NodeStore'un kaydı tür başına bir
## MultiMeshInstance3D'dir (bir çizim), tükenme ve evre örneğin dönüşümüyle gösterilir (çizim eklemez): saz her hakta kısalır, bitince
## kısa anız; ot yığını ve kil yığını küçülür; tezek, dal ve ot gizlenir; damar ve ocak söner (çöker); kesilen çam kütük olur (kütükler
## ayrı bir MultiMesh'tir), devrilişi 1,2 sn'lik geçici bir ağdır (taban ekseninde t², oyuncudan uzağa). Vuruşta düğüm 0,03 m, 140 ms
## sarsılır ve talaş ya da taş tozu saçılır (tek parçacık havuzu); kazanç yazısı düğümün üstünde 1,1 sn yükselir («+2 Saz»; aynı anda en
## çok 4). Engel daireleri («obstacles» grubu) yalnız ayakta duran engel düğümlerindir (çam, ardıç, kaya, damar, kütük, ocak).
##   var field := GatherField.new()
##   field.setup(store)              # ağaca girmeden ya da girdikten sonra
##   field.refresh()                 # store.version değişince kendiliğinden de
##   field.strike(i, "axe")          # sarsıntı ve talaş
##   field.fell(i, away_dir)         # devrilen çam
##   field.gain(i, "+2 Saz")

const SHAKE_S := 0.14
const SHAKE_M := 0.03
const FALL_S := 1.2
const GAIN_S := 1.1
const GAIN_MAX := 4
## Engel yarıçapı (m; türün r'si), engel olmayan türlerde yok.
const STUMP_KEY := "_stump"
const CHIP := Color("#c9a878")
const DUST := Color("#aca69a")
const SPARK := Color("#ffb15a")

var store: NodeStore
## Tür → MultiMeshInstance3D; düğüm → [tür, örnek].
var layers: Dictionary = {}
var _slot: Dictionary = {}
var _stump_slot: Dictionary = {}
var _version := -1
var _shakes: Dictionary = {}
var _falls: Array = []
var _gains: Array = []
var _material: ShaderMaterial
var _particles: CPUParticles3D
var _meshes: Dictionary = {}


func _ready() -> void:
	add_to_group(World.OBSTACLE_GROUP)
	set_process(true)


## Kaydı bağlar ve katmanları kurar (tür başına bir MultiMesh).
func setup(p_store: NodeStore) -> void:
	store = p_store
	for c in get_children():
		c.queue_free()
	layers.clear()
	_slot.clear()
	_stump_slot.clear()
	_material = Style.toon(Color.WHITE, {"use_vertex_color": true, "brush_strength": 0.12})
	var counts := {}
	for i in store.count:
		var kind_id := store.kind_of(i)
		counts[kind_id] = int(counts.get(kind_id, 0)) + 1
	var stumps := 0
	for kind_id: String in counts:
		var row := NodeStore.kind_row(kind_id)
		var look: Dictionary = row.get("look", {}) if row.get("look") is Dictionary else {}
		var mmi := _layer(kind_id, _mesh_for(kind_id, look), int(counts[kind_id]), row.get("tree", false) or row.get("block", false))
		layers[kind_id] = mmi
		if str(look.get("depleted", "")) == "stump":
			stumps += int(counts[kind_id])
	if stumps > 0:
		layers[STUMP_KEY] = _layer(STUMP_KEY, GatherMeshes.stump(), stumps, false)
	var next := {}
	for i in store.count:
		var kind_id := store.kind_of(i)
		var k: int = int(next.get(kind_id, 0))
		_slot[i] = [kind_id, k]
		next[kind_id] = k + 1
		if str((NodeStore.kind_row(kind_id).get("look", {}) as Dictionary).get("depleted", "")) == "stump":
			var s: int = int(next.get(STUMP_KEY, 0))
			_stump_slot[i] = s
			next[STUMP_KEY] = s + 1
	_particles = CPUParticles3D.new()
	_particles.name = "Chips"
	_particles.emitting = false
	_particles.one_shot = true
	_particles.explosiveness = 0.95
	_particles.amount = 10
	_particles.lifetime = 0.55
	_particles.direction = Vector3.UP
	_particles.spread = 55.0
	_particles.initial_velocity_min = 1.6
	_particles.initial_velocity_max = 3.0
	_particles.gravity = Vector3(0, -9.0, 0)
	_particles.scale_amount_min = 0.05
	_particles.scale_amount_max = 0.09
	var quad := BoxMesh.new()
	quad.size = Vector3.ONE
	_particles.mesh = quad
	var pm := StandardMaterial3D.new()
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.vertex_color_use_as_albedo = true
	_particles.material_override = pm
	_particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_particles)
	_version = -1
	refresh()


func _mesh_for(kind_id: String, look: Dictionary) -> Mesh:
	if not _meshes.has(kind_id):
		_meshes[kind_id] = GatherMeshes.for_look(look, hash(kind_id) & 0xFF)
	return _meshes[kind_id]


func _layer(id: String, mesh: Mesh, n: int, shadow: bool) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = n
	var mmi := MultiMeshInstance3D.new()
	mmi.name = id.to_pascal_case()
	mmi.multimesh = mm
	mmi.material_override = _material
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	return mmi


## Kaydın şu anki durumu örneklere (değişmediyse bir şey yapmaz).
func refresh(force := false) -> void:
	if store == null or (not force and store.version == _version):
		return
	_version = store.version
	for i in store.count:
		_write(i, 0.0)


## Düğümün örneği: konum, dönüş ve ölçek kayıttan; evre ve tükenme görünüşü türün look'undan. jitter: sarsıntının payı (m).
func _write(i: int, jitter: float) -> void:
	var slot: Array = _slot.get(i, [])
	if slot.is_empty():
		return
	var mmi: MultiMeshInstance3D = layers[slot[0]]
	var row := store.row_of(i)
	var look: Dictionary = row.get("look", {}) if row.get("look") is Dictionary else {}
	var base := Vector3(store.x[i], store.y[i], store.z[i])
	var s := float(store.scale[i])
	var k := Vector3.ONE * s
	var sink := 0.0
	var hidden := false
	var stump := false
	var shrink := float(look.get("shrink", 1.0))
	var full := int(store.stage_of(i).get("charges", 1))
	if store.available(i):
		if shrink < 1.0:
			k.y *= pow(shrink, maxi(0, full - int(store.charges[i])))
		if store.stage(i) == 1 and row.get("then") is Dictionary:
			k *= 0.9
	else:
		match str(look.get("depleted", "keep")):
			"hide":
				hidden = true
			"stump":
				hidden = true
				stump = true
			"stubble":
				k.y *= 0.22
			"rubble":
				k *= Vector3(1.0, 0.35, 1.0)
			"shrink":
				k.y *= pow(shrink, full) if shrink < 1.0 else 0.4
			"dim":
				k *= 0.92
				sink = 0.12
	var basis := Basis(Vector3.UP, float(store.yaw[i])).scaled(k)
	if hidden:
		basis = Basis().scaled(Vector3.ONE * 0.00001)
	var off := Vector3.ZERO
	if jitter > 0.0:
		off = Vector3(sin(i * 12.9898 + jitter * 400.0), 0.0, cos(i * 78.233 + jitter * 330.0)) * SHAKE_M
	mmi.multimesh.set_instance_transform(int(slot[1]), Transform3D(basis, base + off - Vector3(0, sink + (2.0 if hidden else 0.0), 0)))
	if _stump_slot.has(i) and layers.has(STUMP_KEY):
		var sb := Basis(Vector3.UP, float(store.yaw[i])).scaled(Vector3.ONE * (s if stump else 0.00001))
		(layers[STUMP_KEY] as MultiMeshInstance3D).multimesh.set_instance_transform(int(_stump_slot[i]), Transform3D(sb, base - Vector3(0, 0.0 if stump else 2.0, 0)))


func _process(delta: float) -> void:
	if store == null:
		return
	refresh()
	for i: int in _shakes.keys():
		var left := float(_shakes[i]) - delta
		if left <= 0.0:
			_shakes.erase(i)
			_write(i, 0.0)
		else:
			_shakes[i] = left
			_write(i, left)
	var j := 0
	while j < _falls.size():
		var f: Dictionary = _falls[j]
		f["t"] = float(f["t"]) + delta
		var node: MeshInstance3D = f["node"]
		var u := clampf(float(f["t"]) / FALL_S, 0.0, 1.0)
		if is_instance_valid(node):
			var axis: Vector3 = f["axis"]
			node.transform = Transform3D(Basis(axis, u * u * deg_to_rad(86.0)) * (f["basis"] as Basis), f["at"])
		if u >= 1.0:
			if is_instance_valid(node):
				node.queue_free()
			_falls.remove_at(j)
		else:
			j += 1
	j = 0
	while j < _gains.size():
		var g: Dictionary = _gains[j]
		g["t"] = float(g["t"]) + delta
		var label: Label3D = g["node"]
		var u := float(g["t"]) / GAIN_S
		if is_instance_valid(label):
			label.position = (g["at"] as Vector3) + Vector3(0, 0.6 * u, 0)
			label.modulate.a = clampf(1.6 - 1.6 * u, 0.0, 1.0)
		if u >= 1.0:
			if is_instance_valid(label):
				label.queue_free()
			_gains.remove_at(j)
		else:
			j += 1


## Vuruşun teması: sarsıntı ve parçacık (balta talaş, kazma taş tozu, cevherde kıvılcım).
func strike(i: int, cls: String) -> void:
	if store == null or i < 0 or i >= store.count:
		return
	_shakes[i] = SHAKE_S
	var row := store.row_of(i)
	var col := CHIP if cls == "axe" or cls == "knife" else (SPARK if row.get("ore", false) else DUST)
	burst(Vector3(store.x[i], store.y[i] + (1.0 if row.get("tree", false) else 0.6), store.z[i]), col)


## Toz ya da talaş saçar (tek havuz).
func burst(at: Vector3, color: Color) -> void:
	if _particles == null:
		return
	_particles.position = at
	_particles.color = color
	_particles.restart()
	_particles.emitting = true


## Kesilen çam devrilir: geçici ağ taban ekseninde 1,2 sn, away yönüne (oyuncudan uzağa).
func fell(i: int, away: Vector3) -> void:
	if store == null or i < 0 or i >= store.count:
		return
	var slot: Array = _slot.get(i, [])
	if slot.is_empty():
		return
	var mesh: Mesh = (layers[slot[0]] as MultiMeshInstance3D).multimesh.mesh
	var node := MeshInstance3D.new()
	node.name = "Falling"
	node.mesh = mesh
	node.material_override = _material
	add_child(node)
	var dir := Vector3(away.x, 0.0, away.z)
	if dir.length_squared() < 0.0001:
		dir = Vector3.FORWARD
	dir = dir.normalized()
	var axis := Vector3.UP.cross(dir).normalized()
	var basis := Basis(Vector3.UP, float(store.yaw[i])).scaled(Vector3.ONE * float(store.scale[i]))
	var at := Vector3(store.x[i], store.y[i], store.z[i])
	node.transform = Transform3D(basis, at)
	# UP × dir çevresinde artı dönüş tepeyi dir'e yatırır: ağaç oyuncudan uzağa devrilir.
	_falls.append({"node": node, "t": 0.0, "axis": axis, "basis": basis, "at": at})


## Kazanç yazısı düğümün üstünde («+2 Saz»; en çok 4 aynı anda).
func gain(i: int, text: String) -> void:
	if store == null or i < 0 or i >= store.count:
		return
	while _gains.size() >= GAIN_MAX:
		var old: Dictionary = _gains.pop_front()
		if is_instance_valid(old["node"]):
			(old["node"] as Node).queue_free()
	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.fixed_size = true
	label.pixel_size = 0.0011
	label.font = UIKit.font("Alegreya", 700)
	label.font_size = 30
	label.outline_size = 10
	label.modulate = Color("#f6eedb")
	label.outline_modulate = Color(0.05, 0.04, 0.03, 0.85)
	var h := 1.6 if store.row_of(i).get("tree", false) else 1.1
	var at := Vector3(store.x[i], store.y[i] + h, store.z[i])
	label.position = at
	add_child(label)
	_gains.append({"node": label, "t": 0.0, "at": at})


## Engel daireleri (x, z, yarıçap): ayakta duran engel düğümleri (economy.md §11.4: çam, ardıç, söğüt 0,45; kaya ve damar 0,9).
func get_obstacle_circles() -> Array[Vector3]:
	var out: Array[Vector3] = []
	if store == null:
		return out
	for i in store.count:
		var row := store.row_of(i)
		if not row.get("block", false) or not store.available(i):
			continue
		out.append(Vector3(store.x[i], store.z[i], float(row.get("r", 0.45)) * float(store.scale[i])))
	return out


## Düğümün dünya noktası (görünüşün tabanı).
func node_position(i: int) -> Vector3:
	return store.position_of(i) if store else Vector3.ZERO


## Kaç örnek görünür (sınama): tür → görünen örnek sayısı.
func visible_counts() -> Dictionary:
	var out := {}
	if store == null:
		return out
	for i in store.count:
		var slot: Array = _slot.get(i, [])
		if slot.is_empty():
			continue
		var t: Transform3D = (layers[slot[0]] as MultiMeshInstance3D).multimesh.get_instance_transform(int(slot[1]))
		if t.basis.get_scale().x > 0.001:
			out[slot[0]] = int(out.get(slot[0], 0)) + 1
	return out
