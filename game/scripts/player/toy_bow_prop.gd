class_name ToyBowProp
extends Node3D
## Oyuncak yayın görünüşü (toy_bow; story.md «Beşiğe asılan küçük ok-yay; Çocukluk'un yayı»): beşiğin küçük yayıdır. Ağ, kredisiz, beşikten ayrılan parçadan
## (assets/props/cradle_bow, yay + sadak + ipler tek ağ) çıkar: yalnız yayın kolları kalır (kolun merkez çizgisine BAND_RADIUS içindeki üçgenler), sadak ve
## asma ipleri atılır (BAND_RADII), ağ bir kez kurulur ve önbelleğe alınır. Kiriş ve gerilen ok kodla çizilir: kiriş gezin (nock) gittiği yere iki parça uzar. Dosya yoksa
## (ya da chibi denemelerinde) kol kodla çizilir.
##
## Yerel uzay: kökü kabza, +Y kolun ekseni (uçtan uca), +Z yayın sırtı (atış yönü), kiriş -Z'de. ChildArcher her kare yerini yazar (kendisi top_level).
##   prop.set_nock(Vector3(0, 0, -0.3))      # gez yerel uzayda; kiriş ona uzanır
##   prop.show_arrow(true)                   # gerilen ok (gezden +Z'ye)

const SOURCE_PATH := "res://assets/props/cradle_bow/cradle_bow.glb"
## Kolun merkez çizgisi (kaynak ağın uzayında; bir ucu öteki uca; ağın köşelerinden ölçüldü) ve şeridin yarıçapı (m; düğümlerde kalın, uçta ince: sadağın kayışı kalmasın).
const CENTER_LINE: Array[Vector3] = [
	Vector3(-0.4487, 0.3549, 0.2226), Vector3(-0.4185, 0.3857, 0.1912), Vector3(-0.3642, 0.3883, 0.1481), Vector3(-0.3128, 0.3786, 0.1091),
	Vector3(-0.2539, 0.3343, 0.0694), Vector3(-0.1994, 0.3367, 0.0323), Vector3(-0.1403, 0.3428, -0.0108), Vector3(-0.0927, 0.3542, -0.0521),
	Vector3(-0.0525, 0.3675, -0.0829), Vector3(-0.0049, 0.4289, -0.1177), Vector3(0.049, 0.46, -0.153), Vector3(0.127, 0.4691, -0.2063),
	Vector3(0.158, 0.4685, -0.232),
]
const BAND_RADII: Array[float] = [0.028, 0.028, 0.034, 0.047, 0.04, 0.04, 0.04, 0.04, 0.04, 0.047, 0.034, 0.024, 0.022]
## Kirişin uca bağlandığı yer (uçtan bir önceki noktaya oran).
const STRING_INSET := 0.3
## Yayın boyu (m; uçtan uca): çocuğun boyuna göre (1,2 m'lik çocuğun göğsüne kadar).
const SPAN := 0.62
## Kodla çizilen yedek kolun kabzadan geride duran ucu (span'a oran).
const BRACE_SHARE := 0.1
const STRING_COLOR := Color(0.9, 0.84, 0.66)
const STRING_RADIUS := 0.0035

## Ağın önbelleği.
static var _bow_mesh: ArrayMesh
static var _bow_material: Material
static var _arrow_meshes := {}

## Kiriş (iki parça) ve gerilen ok.
var string_a: MeshInstance3D
var string_b: MeshInstance3D
var arrow: MeshInstance3D
var limbs: MeshInstance3D
## Gezin yerel konumu.
var nock := Vector3.ZERO
## Uçların yerel konumu.
var tip_top := Vector3.ZERO
var tip_bottom := Vector3.ZERO
var _arrow_length := 0.5


func _ready() -> void:
	_build()


## Yayın kolu: kaynak ağdan ayrılmış (yoksa kodla çizilmiş) ağ, yerel uzayda; kök kabzada.
static func bow_mesh() -> ArrayMesh:
	if _bow_mesh == null:
		_bow_mesh = ToyBowProp._extract_bow()
		if _bow_mesh == null:
			_bow_mesh = ToyBowProp._draw_bow()
	return _bow_mesh


## Önbelleği bırakır (sınamalar).
static func clear_cache() -> void:
	_bow_mesh = null
	_bow_material = null
	_arrow_meshes.clear()


## Nokta şeridin içinde mi (saf): çizgiye en yakın yerdeki yarıçaptan yakın (radii: çizginin noktaları başına).
static func in_band(p: Vector3, line: Array[Vector3], radii: Array[float]) -> bool:
	var best := INF
	var best_radius := 0.0
	for i in line.size() - 1:
		var a := line[i]
		var ab := line[i + 1] - a
		var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
		var d := p.distance_to(a + ab * t)
		if d < best:
			best = d
			best_radius = lerpf(radii[i], radii[i + 1], t)
	return best <= best_radius


## Yayın yerel çerçevesi (saf): uçlar line'ın iki ucu, kök kabza (orta nokta), -Z kirişe (uçların ortası kabzanın gerisinde).
## Döner: kaynak uzayından yerele dönüşüm, boyu SPAN'a ölçekli.
static func bow_frame(line: Array[Vector3]) -> Transform3D:
	var tip_a := line[0]
	var tip_b := line[line.size() - 1]
	var axis := (tip_b - tip_a).normalized()
	var mid := (tip_a + tip_b) * 0.5
	# Kabza: uçların ortasına göre kolun en geride kalan noktası.
	var grip := line[line.size() / 2]
	var back := grip - mid
	back = (back - axis * back.dot(axis)).normalized()
	var side := axis.cross(back).normalized()
	var k := SPAN / tip_a.distance_to(tip_b)
	# Kaynak → yerel: x side, y axis, z back; kök kabza.
	var to_local := Basis(side, axis, back).transposed().scaled(Vector3.ONE * k)
	return Transform3D(to_local, to_local * -grip)


static func _extract_bow() -> ArrayMesh:
	if not ResourceLoader.exists(SOURCE_PATH):
		return null
	var scene := load(SOURCE_PATH) as PackedScene
	if scene == null:
		return null
	var root := scene.instantiate()
	var found := root.find_children("*", "MeshInstance3D", true, false)
	var source: Mesh = (found[0] as MeshInstance3D).mesh if not found.is_empty() else null
	if source == null:
		root.free()
		return null
	var arrays := source.surface_get_arrays(0)
	var src_material := source.surface_get_material(0)
	root.free()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var frame := ToyBowProp.bow_frame(CENTER_LINE)
	var normal_basis := frame.basis.orthonormalized()
	var inside := PackedByteArray()
	inside.resize(verts.size())
	for i in verts.size():
		inside[i] = 1 if ToyBowProp.in_band(verts[i], CENTER_LINE, BAND_RADII) else 0
	var remap := PackedInt32Array()
	remap.resize(verts.size())
	remap.fill(-1)
	var out_v := PackedVector3Array()
	var out_n := PackedVector3Array()
	var out_uv := PackedVector2Array()
	var out_i := PackedInt32Array()
	for t in range(0, indices.size(), 3):
		var ia := indices[t]
		var ib := indices[t + 1]
		var ic := indices[t + 2]
		if inside[ia] == 0 or inside[ib] == 0 or inside[ic] == 0:
			continue
		for index in [ia, ib, ic]:
			if remap[index] < 0:
				remap[index] = out_v.size()
				out_v.append(frame * verts[index])
				out_n.append((normal_basis * normals[index]).normalized())
				out_uv.append(uvs[index])
			out_i.append(remap[index])
	if out_i.is_empty():
		return null
	var mesh_arrays := []
	mesh_arrays.resize(Mesh.ARRAY_MAX)
	mesh_arrays[Mesh.ARRAY_VERTEX] = out_v
	mesh_arrays[Mesh.ARRAY_NORMAL] = out_n
	mesh_arrays[Mesh.ARRAY_TEX_UV] = out_uv
	mesh_arrays[Mesh.ARRAY_INDEX] = out_i
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
	_bow_material = ToyBowProp._toon_from(src_material)
	return mesh


## Kaynağın dokusuyla karakterlerin toon malzemesi.
static func _toon_from(source: Material) -> Material:
	var mat := ShaderMaterial.new()
	mat.shader = CharacterAvatar.CHARACTER_SHADER
	if source is BaseMaterial3D:
		mat.set_shader_parameter("albedo_texture", (source as BaseMaterial3D).albedo_texture)
		mat.set_shader_parameter("albedo_tint", (source as BaseMaterial3D).albedo_color)
	mat.set_shader_parameter("ink_strength", 0.25)
	return mat


## Yedek: kodla ağaç kol (kaynak yoksa).
static func _draw_bow() -> ArrayMesh:
	var half := SPAN * 0.5
	var parts: Array = []
	var points: Array[Vector3] = []
	for i in 11:
		var t := float(i) / 10.0 * 2.0 - 1.0
		points.append(Vector3(0.0, t * half, (1.0 - t * t) * half * BRACE_SHARE * 2.0 - half * BRACE_SHARE * 2.0))
	for i in points.size() - 1:
		parts.append([Procedural3D.capsule(0.009, points[i].distance_to(points[i + 1])), Procedural3D.limb_transform(points[i], points[i + 1]), Color(0.55, 0.38, 0.22)])
	_bow_material = Style.toon(Color.WHITE, {"use_vertex_color": true, "brush_strength": 0.15})
	return ArrowField.merge_parts(parts)


func _build() -> void:
	limbs = MeshInstance3D.new()
	limbs.name = "Limbs"
	limbs.mesh = ToyBowProp.bow_mesh()
	limbs.material_override = _bow_material
	add_child(limbs)
	var frame := ToyBowProp.bow_frame(CENTER_LINE)
	var last := CENTER_LINE.size() - 1
	tip_top = frame * CENTER_LINE[last].lerp(CENTER_LINE[last - 1], STRING_INSET)
	tip_bottom = frame * CENTER_LINE[0].lerp(CENTER_LINE[1], STRING_INSET)
	nock = rest_nock()
	var string_material := Style.toon(STRING_COLOR)
	string_a = _make_string(string_material, "StringTop")
	string_b = _make_string(string_material, "StringBottom")
	arrow = MeshInstance3D.new()
	arrow.name = "Arrow"
	arrow.mesh = ToyBowProp.arrow_mesh(_arrow_length)
	arrow.material_override = ArrowField.arrow_material()
	arrow.visible = false
	add_child(arrow)
	_update_string()


func _make_string(mat: Material, node_name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = Procedural3D.cylinder(STRING_RADIUS, STRING_RADIUS, 1.0, 5)
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi


## Gezi (yerel) koyar, kiriş ona uzanır. Ok görünürse gezden kabzaya doğru durur.
func set_nock(at: Vector3) -> void:
	nock = at
	_update_string()
	if arrow and arrow.visible:
		_place_arrow()


## Gerilmemiş kirişin gezi (uçların ortası).
func rest_nock() -> Vector3:
	return (tip_top + tip_bottom) * 0.5


func show_arrow(on: bool) -> void:
	if arrow:
		arrow.visible = on
		if on:
			_place_arrow()


## Gerilen okun boyu (m).
func set_arrow_length(length: float) -> void:
	_arrow_length = length
	if arrow:
		arrow.mesh = ToyBowProp.arrow_mesh(length)


func _place_arrow() -> void:
	# Okun ucu yerelde başlangıçta, gövdesi -Z boyunca: gezden kabzaya bakar, ucu yayın önüne çıkar.
	arrow.transform = Transform3D(Basis.IDENTITY, nock + Vector3(0.0, 0.0, _arrow_length))


func _update_string() -> void:
	if string_a == null:
		return
	_stretch(string_a, tip_top, nock)
	_stretch(string_b, tip_bottom, nock)


static func _stretch(mi: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var length := a.distance_to(b)
	var xform := Procedural3D.limb_transform(a, b)
	mi.transform = Transform3D(xform.basis * Basis.from_scale(Vector3(1.0, length, 1.0)), xform.origin)


## Okun ağı, önbellekli: ucu kökte, gövde -Z boyunca (ArrowField ile aynı).
static func arrow_mesh(length: float) -> ArrayMesh:
	var key := snappedf(length, 0.001)
	if not _arrow_meshes.has(key):
		_arrow_meshes[key] = ArrowField.make_arrow_mesh(length)
	return _arrow_meshes[key]
