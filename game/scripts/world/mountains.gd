@tool
class_name Mountains
extends Node3D
## Vadiyi çevreleyen uzak dağ halkası.
##
## Halka kutupsal bir şerittir: içte alçak, ormanlık etekler; dışta karlı, sivri zirveler.
## Vadinin bittiği yönde (-Z) dağlar daha yüksektir; menü kamerası tam oraya bakar.
##
## Halka SECTORS dilime bölünür (MountainMesh/Sector<k>): kamera halkanın ortasında durduğu için tek parça halka
## her karede bütünüyle (154k üçgen) çizilirdi; dilimler kendi sınır kutularıyla kırpılır, kadrajın dışındakiler
## çizilmez (godot.md §7.5, K3: görünmeyen kesinti). Dilimlerin köşeleri tam halkanınkiyle aynıdır (dikiş yoktur).

const MOUNTAIN_SHADER := preload("res://shaders/mountain.gdshader")

@export var seed_value := 77:
	set(value):
		seed_value = value
		_queue_build()
@export var inner_radius := 1900.0
@export var outer_radius := 5400.0
@export_range(128, 4096) var angular_segments := 1400
@export_range(8, 256) var rings := 56
## En yüksek zirvenin vadiden yüksekliği (metre).
@export var peak_height := 560.0:
	set(value):
		peak_height = value
		_queue_build()

## Halkanın dilim sayısı (1400 bölüt / 40 = 35 bölüt, 9°): dilimin sınır kutusu dar kalır, 68°'lik yatay görüş
## açısına 8–10 dilim girer (20 dilimle geniş kutular yüzünden kadrajın iki yanından fazladan dilim çiziliyordu).
const SECTORS := 40

var _ridge_big: FastNoiseLite
var _ridge: FastNoiseLite
var _hills: FastNoiseLite
## Dilimlerin tutucusu (MountainMesh).
var _holder: Node3D
var _build_queued := false


func _ready() -> void:
	_build()


func _queue_build() -> void:
	if not is_inside_tree() or _build_queued:
		return
	_build_queued = true
	_build.call_deferred()


func _build() -> void:
	_build_queued = false
	_ridge_big = TerrainShape._make_noise(seed_value, 0.00042, 3, FastNoiseLite.FRACTAL_RIDGED)
	_ridge = TerrainShape._make_noise(seed_value + 3, 0.0016, 4, FastNoiseLite.FRACTAL_RIDGED)
	_hills = TerrainShape._make_noise(seed_value + 5, 0.003, 3, FastNoiseLite.FRACTAL_FBM)
	if _holder == null:
		_holder = Node3D.new()
		_holder.name = "MountainMesh"
		add_child(_holder)
	for child in _holder.get_children():
		_holder.remove_child(child)
		child.queue_free()
	var mat := ShaderMaterial.new()
	mat.shader = MOUNTAIN_SHADER
	var grid := _build_grid()
	var segments := angular_segments
	var per := maxi(segments / SECTORS, 1)
	var k := 0
	var seg := 0
	while seg < segments:
		var count := per if seg + per * 2 <= segments else segments - seg
		var mi := MeshInstance3D.new()
		mi.name = "Sector%d" % k
		mi.mesh = build_sector(grid, segments, rings, seg, count)
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_holder.add_child(mi)
		seg += count
		k += 1


## Halkanın dilimleri (MountainMesh altındaki MeshInstance3D'ler).
func get_sectors() -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if _holder:
		for child in _holder.get_children():
			if child is MeshInstance3D:
				result.append(child as MeshInstance3D)
	return result


## theta: 0 = -Z (ileri), saat yönünde artar. r: merkezden uzaklık.
func height_at(theta: float, r: float) -> float:
	var x := r * sin(theta)
	var z := -r * cos(theta)
	var t := clampf(inverse_lerp(inner_radius, outer_radius, r), 0.0, 1.0)
	# Önde (vadinin ucunda) dağlar daha yüksek, arkada daha alçak tepeler.
	var forward := cos(theta)
	var direction_gain := lerpf(0.5, 1.0, smoothstep(-0.3, 0.85, forward))
	# Büyük zirveler: düşük frekanslı sırt gürültüsü, üs alınarak sivriltilir (az ama görkemli tepe).
	var big := pow(_ridge_big.get_noise_2d(x, z) * 0.5 + 0.5, 2.2)
	var detail := _ridge.get_noise_2d(x, z) * 0.5 + 0.5
	var rolling := _hills.get_noise_2d(x, z) * 0.5 + 0.5
	# İki kat: ormanlık etekler (içte) ve karlı ana sıra (dışta).
	var foothills := smoothstep(0.0, 0.1, t) * (1.0 - smoothstep(0.3, 0.5, t)) * (0.1 + rolling * 0.16)
	var main_mask := smoothstep(0.15, 0.45, t) * (1.0 - 0.35 * smoothstep(0.7, 1.0, t))
	var main_range := main_mask * (0.2 + big * 0.72 + detail * 0.16)
	return -45.0 + peak_height * direction_gain * maxf(foothills, main_range)


## Bir dilim (saf): seg_from'dan başlayan seg_count bölüt (son bölüt ilk bölüte sarar), bütün halkalar.
## grid: _build_grid'in dizileri (köşe, normal); köşe sırası halka × bölüt. Üçgen sırası tam halkanınkiyle aynıdır.
static func build_sector(grid: Array, segments: int, ring_count: int, seg_from: int, seg_count: int) -> ArrayMesh:
	var vertices: PackedVector3Array = grid[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = grid[Mesh.ARRAY_NORMAL]
	var width := seg_count + 1
	var out_v := PackedVector3Array()
	var out_n := PackedVector3Array()
	for i in ring_count:
		for s in width:
			var idx := i * segments + (seg_from + s) % segments
			out_v.append(vertices[idx])
			out_n.append(normals[idx])
	var indices := PackedInt32Array()
	indices.resize((ring_count - 1) * seg_count * 6)
	var k := 0
	for i in ring_count - 1:
		for s in seg_count:
			var a := i * width + s
			var b := a + 1
			var c := a + width
			var d := c + 1
			# Yukarıdan bakınca saat yönünde sıralama (arazi ile aynı).
			indices[k] = a
			indices[k + 1] = c
			indices[k + 2] = b
			indices[k + 3] = b
			indices[k + 4] = c
			indices[k + 5] = d
			k += 6
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = out_v
	arrays[Mesh.ARRAY_NORMAL] = out_n
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Halkanın köşe dizileri: Mesh.ARRAY_MAX boyunda dizi (köşe ve normal; köşe sırası halka × bölüt).
func _build_grid() -> Array:
	var segments := angular_segments
	var vertex_count := segments * rings
	var vertices := PackedVector3Array()
	vertices.resize(vertex_count)
	for i in rings:
		# Halkaları içe doğru sıklaştır: siluetler ve etekler daha ayrıntılı olsun.
		var f := float(i) / float(rings - 1)
		var r := lerpf(inner_radius, outer_radius, f * f * 0.6 + f * 0.4)
		for j in segments:
			var theta := TAU * float(j) / float(segments)
			var h := height_at(theta, r)
			vertices[i * segments + j] = Vector3(r * sin(theta), h, -r * cos(theta))

	var normals := PackedVector3Array()
	normals.resize(vertex_count)
	for i in rings:
		for j in segments:
			var inner_p := vertices[maxi(i - 1, 0) * segments + j]
			var outer_p := vertices[mini(i + 1, rings - 1) * segments + j]
			var left_p := vertices[i * segments + (j + segments - 1) % segments]
			var right_p := vertices[i * segments + (j + 1) % segments]
			var n := (right_p - left_p).cross(outer_p - inner_p)
			if n.y < 0.0:
				n = -n
			normals[i * segments + j] = n.normalized()

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	return arrays
