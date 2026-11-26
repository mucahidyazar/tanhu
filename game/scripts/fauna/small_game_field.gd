class_name SmallGameField
extends Node3D
## Çocukluk'un küçük avı (layout.json "childhood.game"; story.md §5, fauna.md §10): türler kısa otlu ev lekelerinde dolaşır, tehdit
## yaklaşınca kaçar, vurulunca düşer. Tek yerden sürülür: bekleyen hayvan kare başına iş yapmaz, kararlar 5 Hz'dedir (iç haritada fauna
## GDScript payı ≤0,5 ms, fauna.md §10). Her hayvan SmallGame düğümüdür ("targets" grubunda; arayüzü orada).
##
##   field.setup(layout["childhood"]["game"], world.ground)   # ağaca eklemeden önce (ChildhoodSite kurar)
##   field.set_threat(oyuncu)                                 # kaçılacak düğüm
##   field.animals(), field.of_kind("lark"), field.first_alive("lark")
##   field.startle_near(point, radius)                        # ıska düştü: yakındakiler ürker
##   field.nearest_fallen(point, max_distance) -> SmallGame   # alınacak düşmüş av (collect() onda)
##   field.collected_count("lark")

signal target_fell(target: SmallGame)
signal target_collected(target: SmallGame)

const SHADER := preload("res://shaders/small_game.gdshader")
const THINK_INTERVAL := 0.2
const BURROW_COLOR := Color(0.5, 0.4, 0.27, 0.0)
const HOLE_COLOR := Color(0.06, 0.045, 0.03, 0.0)

var shape: TerrainShape
var threat: Node3D
## Ağaca girince bütün hayvanlar eklensin mi? Kurucu (ChildhoodSite) kare bütçesi için kapatır ve add_pending ile parça parça ekler.
var auto_add := true

var _def: Dictionary = {}
var _animals: Array[SmallGame] = []
var _active: Array[SmallGame] = []
var _clock := 0.0
var _think_left := 0.0
var _think_i := 0
var _meshes: Dictionary = {}


## Kurulum (ağaca eklenmeden önce). meshes: tür → hazır ağ verisi (FaunaMesh.arrays; iş parçacığından); boşsa burada çizilir.
func setup(def: Dictionary, p_shape: TerrainShape, arrays: Dictionary = {}) -> void:
	_def = def
	shape = p_shape
	var kinds := FaunaKind.table()
	var base_seed := int(def.get("seed", 91))
	var n := 0
	for group: Dictionary in def.get("groups", []):
		var kind_id := str(group.get("kind", ""))
		if not kinds.has(kind_id):
			push_warning("[game] katalogda %s yok" % kind_id)
			continue
		var kind := FaunaKind.from_def(kind_id, kinds[kind_id])
		var mesh := _mesh_of(kind_id, arrays)
		var mat := _material_of(kind)
		var patches: Array[Vector3] = []
		for p: Array in group.get("patches", []):
			patches.append(Vector3(float(p[0]), float(p[1]), float(p[2])))
		var holes := PackedVector2Array()
		for h: Array in group.get("holes", []):
			holes.append(Vector2(float(h[0]), float(h[1])))
		for _i in int(group.get("count", 1)):
			var a := SmallGame.new()
			a.name = "%s_%d" % [kind_id.capitalize(), n]
			a.configure(kind, mesh, mat, patches, holes, shape, base_seed + n * 17)
			a.fell.connect(_on_fell)
			a.picked_up.connect(_on_collected)
			a.alarmed.connect(_on_alarmed)
			a.woke.connect(_mark_active)
			_animals.append(a)
			n += 1
	_build_burrows(def)


func _ready() -> void:
	if auto_add:
		add_pending(_animals.size())


## Henüz eklenmemiş hayvanlardan en çok count tanesini ekler. Döner: eklenmeyen kaldı mı?
func add_pending(count: int) -> bool:
	var added := 0
	for a in _animals:
		if added >= count:
			break
		if a.get_parent() == null:
			add_child(a)
			added += 1
	for a in _animals:
		if a.get_parent() == null:
			return true
	return false


func _exit_tree() -> void:
	# Eklenmeden kalan hayvanlar ağaç dışında öksüz kalmasın.
	for a in _animals:
		if a.get_parent() == null and not a.is_queued_for_deletion():
			a.free()


func _process(delta: float) -> void:
	_clock += delta
	_think_left -= delta
	if _think_left <= 0.0:
		_think_left = THINK_INTERVAL
		_think()
	var i := _active.size() - 1
	while i >= 0:
		var a := _active[i]
		if not a.advance(delta):
			_active.remove_at(i)
		i -= 1


# --- Yüz ---------------------------------------------------------------------------------------------

func set_threat(node: Node3D) -> void:
	threat = node


func animals() -> Array[SmallGame]:
	return _animals


func of_kind(kind_id: String) -> Array[SmallGame]:
	var out: Array[SmallGame] = []
	for a in _animals:
		if a.kind_id == kind_id:
			out.append(a)
	return out


## Türün vurulabilir ilk hayvanı (Yançi'nin ilk kuşu, 90 sn'de gösterilen hedef); yoksa null.
func first_alive(kind_id: String) -> SmallGame:
	for a in _animals:
		if a.kind_id == kind_id and a.is_hittable():
			return a
	return null


## Ok yere düştü: yakındakiler ürker (ıska bedavadır).
func startle_near(point: Vector3, radius: float = 3.0) -> void:
	for a in _animals:
		if a.is_hittable() and a.global_position.distance_squared_to(point) < radius * radius:
			a.startle(point)


## En yakın düşmüş av; yoksa null.
func nearest_fallen(point: Vector3, max_distance: float = 2.0) -> SmallGame:
	var best: SmallGame = null
	var best_d := max_distance * max_distance
	for a in _animals:
		if a.is_down():
			var d := a.global_position.distance_squared_to(point)
			if d <= best_d:
				best_d = d
				best = a
	return best


func collected_count(kind_id: String = "") -> int:
	var n := 0
	for a in _animals:
		if a.collected and (kind_id.is_empty() or a.kind_id == kind_id):
			n += 1
	return n


# --- İç işler ------------------------------------------------------------------------------------------

## 5 Hz: tehdit ve bekleme kararları. Hayvan başına en çok küçük bir iş.
func _think() -> void:
	var has_threat := is_instance_valid(threat) and threat.is_inside_tree()
	var at := threat.global_position if has_threat else Vector3.ZERO
	for a in _animals:
		# Henüz eklenmemiş hayvan (add_pending'in parça parça kurulumu) düşünmez.
		if not a.is_inside_tree():
			continue
		a.clock_time = _clock
		if a.state >= SmallGame.State.FALLING:
			continue
		if has_threat and a.threatened_by(at):
			a.startle(at)
		else:
			a.think(_clock, at, has_threat)


func _mark_active(a: SmallGame) -> void:
	if not _active.has(a):
		_active.append(a)


func _on_fell(target: SmallGame) -> void:
	target_fell.emit(target)


func _on_collected(target: SmallGame) -> void:
	target_collected.emit(target)


## Kuş kümesi birlikte havalanır (keklik: toplu havalanır; fauna.md §1).
func _on_alarmed(target: SmallGame) -> void:
	var flock := float(target.kind.game_value("flock", 0.0))
	if flock <= 0.0:
		return
	var at := target.global_position
	for a in _animals:
		if a != target and a.kind_id == target.kind_id and a.state <= SmallGame.State.WALK and a.global_position.distance_squared_to(at) < flock * flock:
			a.startle(at)


func _mesh_of(kind_id: String, arrays: Dictionary) -> Mesh:
	if _meshes.has(kind_id):
		return _meshes[kind_id]
	var data: Dictionary = arrays.get(kind_id, {})
	var mesh: Mesh = FaunaMesh.make_mesh(data) if not data.is_empty() else FaunaMesh.mesh_for(kind_id)
	_meshes[kind_id] = mesh
	return mesh


func _material_of(kind: FaunaKind) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	var params := FaunaMesh.shader_params(kind.id)
	for key: String in params:
		mat.set_shader_parameter(key, params[key])
	mat.set_shader_parameter(&"flap_rate", float(kind.game_value("flap_rate", 30.0)))
	mat.set_shader_parameter(&"peck_rate", float(kind.game_value("peck_rate", 2.0)))
	mat.set_shader_parameter(&"gait_rate", float(kind.game_value("gait_rate", 18.0)))
	return mat


## İn tümsekleri ve ağızları: kodla, tek ağ.
func _build_burrows(def: Dictionary) -> void:
	var d := FaunaMesh.Draft.new()
	var any := false
	for group: Dictionary in def.get("groups", []):
		var size := float(group.get("mound", 0.0))
		if size <= 0.0:
			continue
		for h: Array in group.get("holes", []):
			any = true
			var x := float(h[0])
			var z := float(h[1])
			var y := shape.height_at(x, z) if shape else 0.0
			d.blob(Vector3(x, y - size * 0.05, z), Vector3(size, size * 0.34, size), Basis.IDENTITY, 2, BURROW_COLOR, Vector4.ZERO, 0.12, int(x * 13.0))
			d.blob(Vector3(x, y + size * 0.255, z), Vector3(size * 0.34, size * 0.04, size * 0.3), Basis.IDENTITY, 1, HOLE_COLOR, Vector4.ZERO)
	if not any:
		return
	var mi := MeshInstance3D.new()
	mi.name = "Burrows"
	mi.mesh = FaunaMesh.make_mesh(d.arrays())
	mi.material_override = Style.toon(Color.WHITE, {"use_vertex_color": true, "brush_strength": 0.15})
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
