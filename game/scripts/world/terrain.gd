@tool
class_name Terrain
extends Node3D
## TerrainShape'ten kutupsal bir arazi meshi üretir.
##
## Izgara kamp merkezinde çok sık, uzakta seyrektir (halkalar üstel aralıklı);
## böylece kameranın gördüğü her yerde ekranda benzer bir ayrıntı yoğunluğu elde edilir.
## Üretilen mesh sahneye KAYDEDİLMEZ; her açılışta yeniden oluşturulur.
##
## Görünmeyeni çizmemek için (godot.md §7.5, K3) ızgara parçalara bölünür: merkez diski (TerrainMesh, ilk
## CENTER_RINGS halka) tek parçadır; dış halkalar BAND_RINGS halkalık bantlara, bantlar SECTORS dilime ayrılır
## (Chunks/Band<b>_<d>). Her parça kendi sınır kutusuyla kırpılır: kameranın arkasındaki ve yanlarındaki
## dilimler, gölge bölümlerinin dışındaki parçalar çizilmez. Parçaların köşeleri tam ızgaranınkiyle aynıdır
## (aynı konum, normal ve renk; dikiş yoktur). Bütçe ölçümünde (2026-11-05) tek parça arazi her pozda görünür
## geçişte 316k, gölgede 632k üçgen getiriyordu (iki gölge bölümünün ikisinde de tamamı).
##
## Merkez diskinde (≈6,5 m, kampın düz toprağı) çevre yönündeki her CENTER_STEP bölütten biri kullanılır: tam
## ızgarada orada bölüt 1 cm'nin altına iner (ekranda piksel altı, 86k üçgen); seyrek diskin köşeleri ızgaranın
## aynı köşeleridir, son halkası dış bantların sık halkasına dikişsiz bağlanır (≈23k üçgen). Uzak kıyılar
## değişmesin diye dış bantlar tam çözünürlüktedir (denendi: bütün arazi 360 bölütle çizilince adaların kıyısı
## birkaç piksel kayıyordu).
##
## Arazi gölge düşürmez (cast_shadows): ay ışığı 50° yüksekten kamera tarafından gelir; arazinin kendi üstüne
## düşen gölgesi menü karesinde görünmez (ölçüldü: değişen piksel %0,06, arayüzün koşudan koşuya titremesi
## düzeyinde). Alçak güneşle (SkyRig, godot.md §4.9) tepelerin gölgesi gerekince açılır; parçalara bölündüğü
## için o zaman yalnız gölge bölümlerine giren parçalar çizilir.

const TERRAIN_SHADER := preload("res://shaders/terrain.gdshader")

## Arazi biçimini belirleyen tohum değeri.
@export var seed_value := 1207:
	set(value):
		seed_value = value
		_queue_build()
## Çevre boyunca bölüt sayısı (yanal çözünürlük).
@export_range(64, 2048) var angular_segments := 720:
	set(value):
		angular_segments = value
		_queue_build()
## Merkezden dışa halka sayısı (derinlik çözünürlüğü).
@export_range(16, 512) var rings := 220:
	set(value):
		rings = value
		_queue_build()
@export var inner_radius := 0.6
@export var outer_radius := 3600.0
## Arazi gölge düşürsün mü? (Bkz. dosyanın başı: ay ışığında görünmez, kapalıdır.)
@export var cast_shadows := false:
	set(value):
		cast_shadows = value
		_apply_shadow_setting()
## Pişmiş ağların haritası (MapBake; world-swap, godot.md §4.3 madde 4): boş değilse ağlar data/maps/<bake_id>/baked/terrain.res'ten
## gelir (tools/bake_map.gd yazar; ızgara yeniden hesaplanmaz). Ayarlar ya da biçim pişirilenden ayrıysa imza tutmaz, arazi kendisi üretir.
## Kampın dünyasında "camp"tır.
@export var bake_id := ""

## Merkez diskinin halka sayısı (ilk 60 halka ≈ 6,5 m yarıçap; neredeyse her kamp kadrajında görünür).
const CENTER_RINGS := 60
## Merkez diskinde çevre yönündeki seyreltme: her CENTER_STEP bölütten biri (720 → 180; bölüt sayısına tam bölünmeli).
const CENTER_STEP := 4
## Dış bantların halka sayısı ve bir bandın dilim sayısı (720 bölüt / 16 = 45 bölüt, 22,5°).
const BAND_RINGS := 20
const SECTORS := 16

## Kamp toprağı lekeleri: Vector4(x, z, yarıçap, şiddet). World tarafından doldurulur.
var dirt_spots: Array[Vector4] = []:
	set(value):
		dirt_spots = value
		_apply_dirt_spots()

var shape: TerrainShape
var material: ShaderMaterial
## Son kurulum pişmiş ağlarla mı yapıldı (bake_id)?
var used_bake := false
## Merkez diski (TerrainMesh) ve dış halkaların parçaları (Chunks altında).
var _mesh_instance: MeshInstance3D
var _chunks: Node3D
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
	shape = TerrainShape.new(seed_value)
	if _mesh_instance == null:
		_mesh_instance = MeshInstance3D.new()
		_mesh_instance.name = "TerrainMesh"
		add_child(_mesh_instance)
	if material == null:
		material = ShaderMaterial.new()
		material.shader = TERRAIN_SHADER
		material.set_shader_parameter("water_level", TerrainShape.WATER_LEVEL)
	if _chunks == null:
		_chunks = Node3D.new()
		_chunks.name = "Chunks"
		add_child(_chunks)
	for child in _chunks.get_children():
		_chunks.remove_child(child)
		child.queue_free()
	var bake := MapBake.fetch(bake_id, "terrain", bake_signature()) if not bake_id.is_empty() else null
	used_bake = bake != null
	if bake:
		# Pişmiş ağlar: merkez diski ilk ağdır, parçalar adlarıyla sırayla (tools/bake_map.gd, bake_payload).
		_mesh_instance.mesh = bake.meshes[0]
		_mesh_instance.material_override = material
		var names: PackedStringArray = bake.data.get("names", PackedStringArray())
		for i in names.size():
			var part := MeshInstance3D.new()
			part.name = names[i]
			part.mesh = bake.meshes[i + 1]
			part.material_override = material
			_chunks.add_child(part)
		_apply_shadow_setting()
		_apply_dirt_spots()
		return
	var grid := build_grid(shape, angular_segments, rings, inner_radius, outer_radius)
	var center_rings := mini(CENTER_RINGS, rings - 1)
	var step := CENTER_STEP if angular_segments % CENTER_STEP == 0 else 1
	_mesh_instance.mesh = build_center(grid, angular_segments, center_rings, step)
	_mesh_instance.material_override = material
	var per := maxi(angular_segments / SECTORS, 1)
	for part in chunk_plan(angular_segments, rings, center_rings, BAND_RINGS, SECTORS):
		var mi := MeshInstance3D.new()
		mi.name = "Band%d_%d" % [(part.x - center_rings) / BAND_RINGS, part.z / per]
		mi.mesh = build_chunk(grid, angular_segments, part.x, part.y, part.z, part.w)
		mi.material_override = material
		_chunks.add_child(mi)
	_apply_shadow_setting()
	_apply_dirt_spots()


## Pişmiş ağların imzası (MapBake.signature_of): ayarlar, değişmezler ve biçimin örnek noktalarındaki yükseklik ve köşe rengi.
func bake_signature() -> String:
	var src := shape if shape else TerrainShape.new(seed_value)
	return MapBake.signature_of(["terrain", MapBake.script_inputs(self), MapBake.probe_shape(src, [&"height_at", &"vertex_tint"])])


## Son kurulumun ağları pişirilecek parça olarak (tools/bake_map.gd): merkez diski ve parçalar adlarıyla.
func bake_payload() -> MapBake:
	var bake := MapBake.new()
	bake.kind = "terrain"
	bake.map_id = bake_id
	bake.signature = bake_signature()
	var names := PackedStringArray()
	bake.meshes.append(_mesh_instance.mesh)
	for child in _chunks.get_children():
		var mi := child as MeshInstance3D
		if mi and not mi.is_queued_for_deletion():
			names.append(mi.name)
			bake.meshes.append(mi.mesh)
	bake.data = {"names": names}
	return bake


## Gölge ayarını (cast_shadows) arazinin bütün parçalarına uygular.
func _apply_shadow_setting() -> void:
	var setting := GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for mi in get_parts():
		mi.cast_shadow = setting


## Arazinin bütün parçaları: merkez diski ve dış halkaların parçaları.
func get_parts() -> Array[MeshInstance3D]:
	var parts: Array[MeshInstance3D] = []
	if _mesh_instance:
		parts.append(_mesh_instance)
	if _chunks:
		for child in _chunks.get_children():
			if child is MeshInstance3D:
				parts.append(child as MeshInstance3D)
	return parts


func _apply_dirt_spots() -> void:
	if material == null:
		return
	var spots: Array[Vector4] = dirt_spots.slice(0, 12)
	while spots.size() < 12:
		spots.append(Vector4.ZERO)
	material.set_shader_parameter("dirt_spots", spots)
	material.set_shader_parameter("dirt_spot_count", mini(dirt_spots.size(), 12))


## i. halkanın yarıçapı (üstel aralık: her halka bir öncekinin sabit katı).
static func ring_radius(i: int, ring_count: int, inner: float, outer: float) -> float:
	return inner * pow(outer / inner, float(i) / float(ring_count - 1))


## Kutupsal ızgaradan arazi meshi üretir (tek parça, bütün halkalar). Saf fonksiyondur; testlerden de
## çağrılabilir. Sahnedeki arazi aynı ızgaranın parçalarıdır (build_grid, build_center, build_chunk).
static func build_mesh(p_shape: TerrainShape, segments: int, ring_count: int, inner: float, outer: float) -> ArrayMesh:
	var grid := build_grid(p_shape, segments, ring_count, inner, outer)
	var vertices: PackedVector3Array = grid[Mesh.ARRAY_VERTEX]
	var center := vertices.size() - 1
	# Üçgenler (Godot'da ön yüzler saat yönünde sıralanır).
	var indices := PackedInt32Array()
	indices.resize(segments * 3 + (ring_count - 1) * segments * 6)
	var k := 0
	for j in segments:
		indices[k] = center
		indices[k + 1] = j
		indices[k + 2] = (j + 1) % segments
		k += 3
	for i in ring_count - 1:
		for j in segments:
			var a := i * segments + j
			var b := i * segments + (j + 1) % segments
			var c := (i + 1) * segments + j
			var d := (i + 1) * segments + (j + 1) % segments
			indices[k] = a
			indices[k + 1] = c
			indices[k + 2] = b
			indices[k + 3] = b
			indices[k + 4] = c
			indices[k + 5] = d
			k += 6
	var arrays := grid.duplicate()
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Parçaların planı (saf): her dış parça Vector4i(ilk halka, son halka, ilk bölüt, bölüt sayısı); halka aralığı
## köşe halkalarıdır (iki uç dahil), dilim son bölütten sonra ilk bölüte sarar. Merkez diski (0..center_rings)
## plana girmez. Bantlar center_rings'ten dışa band_rings halkalıktır (sonuncusu kalanı alır); her bant
## sectors dilimdir (bölüt sayısı dilim sayısına tam bölünmezse son dilim kalanı alır).
static func chunk_plan(segments: int, ring_count: int, center_rings: int, band_rings: int, sectors: int) -> Array[Vector4i]:
	var plan: Array[Vector4i] = []
	var last := ring_count - 1
	var per := maxi(segments / maxi(sectors, 1), 1)
	var start := center_rings
	while start < last:
		var stop := mini(start + maxi(band_rings, 1), last)
		var seg := 0
		while seg < segments:
			var count := per if seg + per * 2 <= segments else segments - seg
			plan.append(Vector4i(start, stop, seg, count))
			seg += count
		start = stop
	return plan


## Merkez diski (saf): merkez yelpazesi ve 0..rings_to halkaları arasındaki şeritler. step > 1 ise 0..rings_to − 1
## halkalarında her step bölütten biri kullanılır (köşeler ızgaranın aynı köşeleridir); son halka (rings_to) tam
## çözünürlüktedir ve seyrek halkaya üçgen yelpazeleriyle bağlanır: dış bantlarla ortak kenar aynıdır, çatlak olmaz.
## step = 1 tam ızgaradır. segments step'e tam bölünmelidir.
static func build_center(grid: Array, segments: int, rings_to: int, step: int = 1) -> ArrayMesh:
	var vertices: PackedVector3Array = grid[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = grid[Mesh.ARRAY_NORMAL]
	var colors: PackedColorArray = grid[Mesh.ARRAY_COLOR]
	var coarse := segments / maxi(step, 1)
	var out_v := PackedVector3Array()
	var out_n := PackedVector3Array()
	var out_c := PackedColorArray()
	# Köşeler: 0..rings_to − 1 halkaları seyrek (coarse bölüt), son halka sık (segments bölüt), en sonda merkez.
	for i in rings_to:
		for k in coarse:
			var idx := i * segments + k * step
			out_v.append(vertices[idx])
			out_n.append(normals[idx])
			out_c.append(colors[idx])
	var outer := out_v.size()
	for j in segments:
		var idx := rings_to * segments + j
		out_v.append(vertices[idx])
		out_n.append(normals[idx])
		out_c.append(colors[idx])
	var center := out_v.size()
	out_v.append(vertices[vertices.size() - 1])
	out_n.append(normals[normals.size() - 1])
	out_c.append(colors[colors.size() - 1])
	var indices := PackedInt32Array()
	# Merkez yelpazesi ve seyrek şeritler (build_mesh'in sırası: ön yüz saat yönünde).
	for k in coarse:
		indices.append_array([center, k, (k + 1) % coarse])
	for i in rings_to - 1:
		for k in coarse:
			var a := i * coarse + k
			var b := i * coarse + (k + 1) % coarse
			var c := (i + 1) * coarse + k
			var d := (i + 1) * coarse + (k + 1) % coarse
			indices.append_array([a, c, b, b, c, d])
	# Seyrek halkadan (rings_to − 1) sık son halkaya: her seyrek bölütün iki ucu sık bölütlerin yarısına yelpaze açar,
	# ortadaki üçgen iki seyrek köşeyi sık halkanın orta köşesine bağlar.
	var inner := (rings_to - 1) * coarse
	var half := step / 2
	for k in coarse:
		var a := inner + k
		var b := inner + (k + 1) % coarse
		var first := k * step
		for m in half:
			indices.append_array([a, outer + first + m, outer + (first + m + 1) % segments])
		indices.append_array([a, outer + (first + half) % segments, b])
		for m in range(half, step):
			indices.append_array([b, outer + (first + m) % segments, outer + (first + m + 1) % segments])
	return _commit(out_v, out_n, out_c, indices)


## Bir dış parça (saf): ring_from..ring_to halkaları ve seg_from'dan başlayan seg_count bölüt (son bölüt
## ilk bölüte sarar). Köşeler ızgaranın aynı köşeleridir; üçgen sırası build_mesh'inkiyle aynıdır.
static func build_chunk(grid: Array, segments: int, ring_from: int, ring_to: int, seg_from: int, seg_count: int) -> ArrayMesh:
	var vertices: PackedVector3Array = grid[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = grid[Mesh.ARRAY_NORMAL]
	var colors: PackedColorArray = grid[Mesh.ARRAY_COLOR]
	var width := seg_count + 1
	var out_v := PackedVector3Array()
	var out_n := PackedVector3Array()
	var out_c := PackedColorArray()
	for i in range(ring_from, ring_to + 1):
		for s in width:
			var idx := i * segments + (seg_from + s) % segments
			out_v.append(vertices[idx])
			out_n.append(normals[idx])
			out_c.append(colors[idx])
	var indices := PackedInt32Array()
	indices.resize((ring_to - ring_from) * seg_count * 6)
	var k := 0
	for i in ring_to - ring_from:
		for s in seg_count:
			var a := i * width + s
			var b := a + 1
			var c := a + width
			var d := c + 1
			indices[k] = a
			indices[k + 1] = c
			indices[k + 2] = b
			indices[k + 3] = b
			indices[k + 4] = c
			indices[k + 5] = d
			k += 6
	return _commit(out_v, out_n, out_c, indices)


static func _commit(vertices: PackedVector3Array, normals: PackedVector3Array, colors: PackedColorArray, indices: PackedInt32Array) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Kutupsal ızgaranın köşe dizileri (saf): Mesh.ARRAY_MAX boyunda dizi (köşe, normal, renk; indeks yok).
## Köşe sırası halka × bölüt + merkez (en sonda).
static func build_grid(p_shape: TerrainShape, segments: int, ring_count: int, inner: float, outer: float) -> Array:
	var vertex_count := segments * ring_count + 1
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	vertices.resize(vertex_count)
	colors.resize(vertex_count)

	# 1) Köşe konumları: önce yükseklikler (her köşe için tek değerlendirme).
	var cos_table := PackedFloat32Array()
	var sin_table := PackedFloat32Array()
	cos_table.resize(segments)
	sin_table.resize(segments)
	for j in segments:
		var a := TAU * float(j) / float(segments)
		cos_table[j] = cos(a)
		sin_table[j] = sin(a)
	for i in ring_count:
		var r := ring_radius(i, ring_count, inner, outer)
		for j in segments:
			var x := r * cos_table[j]
			var z := r * sin_table[j]
			var idx := i * segments + j
			vertices[idx] = Vector3(x, p_shape.height_at(x, z), z)
			colors[idx] = p_shape.vertex_tint(x, z)
	var center := vertex_count - 1
	vertices[center] = Vector3(0.0, p_shape.height_at(0.0, 0.0), 0.0)
	colors[center] = p_shape.vertex_tint(0.0, 0.0)

	# 2) Normaller: komşu köşelerden (ek yükseklik hesabı gerektirmez).
	var normals := PackedVector3Array()
	normals.resize(vertex_count)
	for i in ring_count:
		for j in segments:
			var idx := i * segments + j
			var inner_p := vertices[center] if i == 0 else vertices[(i - 1) * segments + j]
			var outer_p := vertices[mini(i + 1, ring_count - 1) * segments + j]
			var left_p := vertices[i * segments + (j + segments - 1) % segments]
			var right_p := vertices[i * segments + (j + 1) % segments]
			var n := (right_p - left_p).cross(outer_p - inner_p)
			if n.y < 0.0:
				n = -n
			normals[idx] = n.normalized()
	normals[center] = Vector3.UP

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	return arrays
