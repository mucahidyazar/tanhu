@tool
class_name CampProp
extends Procedural3D
## Kamp eşyaları: tek bir düğüm, "kind" seçimine göre farklı bir nesne kurar.
##
## Çoğu eşyanın Meshy modeli vardır (res://assets/props/<id>/<id>.glb; bkz. MODELS): model gerçek boyunda
## gösterilir, engel dairesi modelin tabanından hesaplanır. Modeli olmayan (kurutma sergisi, bardak, kalkan)
## ya da modeli eksik olan eşyalar kodla çizilir.

## Yeni türler her zaman SONA eklenir (sahnelerdeki kayıtlı değerler değişmesin).
enum Kind { BARREL, CRATE, BUCKET, SHIELD, DRYING_RACK, TRIPOD_POT, STOOL, WOOD_PILE, SPEAR_RACK, CUP, SADDLE_BAGS, FENCE }

const MODEL_FOLDER := "props"
## Tür → [model kimliği, gerçek boy (en büyük kenar, metre; tools/asset_plan.json), iki yüzlü mü].
const MODELS := {
	Kind.BARREL: ["barrel", 0.95, false],
	Kind.CRATE: ["crate", 0.9, false],
	Kind.BUCKET: ["bucket", 0.45, true],
	Kind.TRIPOD_POT: ["cauldron", 1.4, true],
	Kind.STOOL: ["stool", 0.5, false],
	Kind.WOOD_PILE: ["firewood", 1.4, false],
	Kind.SPEAR_RACK: ["weapon_rack", 2.0, false],
	Kind.SADDLE_BAGS: ["saddlebags", 0.9, false],
	Kind.FENCE: ["fence", 2.2, false],
}
## Modeli olmayan (ya da modeli eksik) eşyaların engel yarıçapı (metre).
const FALLBACK_RADII := {Kind.DRYING_RACK: 0.9, Kind.TRIPOD_POT: 0.6, Kind.WOOD_PILE: 0.8, Kind.SPEAR_RACK: 0.6, Kind.FENCE: 0.3}
const DEFAULT_RADIUS := 0.4
## Çit gibi uzun, ince eşyalar tek daire yerine uzun kenarı boyunca dizilmiş dairelerle örtülür.
const LONG_PROP_RATIO := 1.6
## Meshy eşya dokularının doygunluğu: modellerin turuncu ahşabı ateş ışığında referanstaki (menu_camp.png)
## kahverengi ahşaptan çok daha doygun görünür; biraz kısılır (atw_textured "saturation").
const MODEL_SATURATION := 0.82

@export var kind: Kind = Kind.BARREL:
	set(value):
		kind = value
		queue_rebuild()
@export var tint := Color(1, 1, 1):
	set(value):
		tint = value
		queue_rebuild()
## Serbest gezintide içinden geçilmesin mi?
@export var blocks_movement := true:
	set(value):
		blocks_movement = value
		if is_inside_tree():
			if value:
				add_to_group(World.OBSTACLE_GROUP)
			else:
				remove_from_group(World.OBSTACLE_GROUP)

var _model: MeshyProp


func _ready() -> void:
	if blocks_movement:
		add_to_group(World.OBSTACLE_GROUP)
	super._ready()


## Bu türün Meshy model kimliği (modeli yoksa boş; saf fonksiyon).
static func model_id_for(p_kind: Kind) -> String:
	return MODELS[p_kind][0] if MODELS.has(p_kind) else ""


## Bu türün gerçek boyu (en büyük kenarı, metre; modeli yoksa 0; saf fonksiyon).
static func model_size_for(p_kind: Kind) -> float:
	return MODELS[p_kind][1] if MODELS.has(p_kind) else 0.0


## Meshy modeli gösteriliyor mu (false = kodla çizilen eşya)?
func uses_model() -> bool:
	return _model != null and _model.has_model()


func get_obstacle_circles() -> Array[Vector3]:
	var s := scale.x
	if uses_model():
		var box := _model.get_model_aabb()
		var local := footprint_circles(Vector2(box.size.x, box.size.z), Vector2(box.get_center().x, box.get_center().z))
		var result: Array[Vector3] = []
		for c in local:
			var p := global_transform * Vector3(c.x, 0.0, c.y)
			result.append(Vector3(p.x, p.z, c.z * s))
		return result
	var radius: float = FALLBACK_RADII.get(kind, DEFAULT_RADIUS)
	if kind == Kind.FENCE:
		var fence: Array[Vector3] = []
		for c in footprint_circles(Vector2(2.2, 0.2), Vector2.ZERO):
			var p := global_transform * Vector3(c.x, 0.0, c.y)
			fence.append(Vector3(p.x, p.z, c.z * s))
		return fence
	return [Vector3(global_position.x, global_position.z, radius * s)]


## Eşyanın tabanını (yerel x/z ölçüsü ve ortası) örten engel daireleri (saf fonksiyon): Vector3(x, z, yarıçap).
## Toplu eşyalar tek daire (taban yarıçapının ~%90'ı: oyuncu yanına kadar gelebilir); çit gibi uzun eşyalar
## uzun kenarı boyunca dizilmiş, kısa kenarı örten daireler.
static func footprint_circles(size: Vector2, center: Vector2) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var long_side := maxf(size.x, size.y)
	var short_side := minf(size.x, size.y)
	if long_side <= 0.0:
		return result
	if long_side < short_side * LONG_PROP_RATIO:
		result.append(Vector3(center.x, center.y, (size.x + size.y) * 0.25 * 0.9))
		return result
	var r := maxf(short_side * 0.5, 0.25)
	var count := ceili(long_side / (r * 2.0))
	var step := (long_side - r * 2.0) / float(maxi(count - 1, 1))
	for i in count:
		var along := -long_side * 0.5 + r + step * float(i) if count > 1 else 0.0
		var offset := Vector2(along, 0.0) if size.x >= size.y else Vector2(0.0, along)
		result.append(Vector3(center.x + offset.x, center.y + offset.y, r))
	return result


func _build() -> void:
	_model = null
	var id := model_id_for(kind)
	if MeshyProp.exists(MODEL_FOLDER, id):
		_build_model(id)
	if uses_model():
		return
	match kind:
		Kind.BARREL: _barrel()
		Kind.CRATE: _crate()
		Kind.BUCKET: _bucket()
		Kind.SHIELD: _shield()
		Kind.DRYING_RACK: _drying_rack()
		Kind.TRIPOD_POT: _tripod_pot()
		Kind.STOOL: _stool()
		Kind.WOOD_PILE: _wood_pile()
		Kind.SPEAR_RACK: _spear_rack()
		Kind.CUP: _cup()
		Kind.SADDLE_BAGS: _saddle_bags()
		Kind.FENCE: _fence()


func _build_model(id: String) -> void:
	var entry: Array = MODELS[kind]
	var prop := MeshyProp.new()
	prop.name = "PropModel"
	prop.model_id = id
	prop.folder = MODEL_FOLDER
	prop.size_axis = MeshyProp.SizeAxis.LONGEST
	prop.target_size = entry[1]
	prop.double_sided = entry[2]
	prop.sink = 0.01
	prop.tint = tint
	prop.ink_strength = 0.3
	prop.set_shader_parameter(&"saturation", MODEL_SATURATION)
	add_generated(prop)
	if prop.has_model():
		_model = prop
	else:
		remove_child(prop)
		prop.queue_free()


# --- Kodla çizilen eşyalar -----------------------------------------------------------------

func _wood(base: Color = Style.WOOD) -> ShaderMaterial:
	return Style.toon(base * tint, {"brush_strength": 0.16})


func _barrel() -> void:
	var profile := PackedVector2Array([Vector2(0.24, 0.0), Vector2(0.28, 0.2), Vector2(0.3, 0.4), Vector2(0.28, 0.6), Vector2(0.24, 0.8)])
	add_mesh(MeshKit.lathe(profile, 18), _wood())
	add_mesh(MeshKit.disc(0.24, 0.8, 18), _wood(Style.WOOD_DARK))
	var iron := Style.toon(Style.IRON)
	for y in [0.1, 0.4, 0.7]:
		var r := 0.28 if y == 0.4 else 0.265
		add_mesh(torus(r - 0.012, r + 0.018), iron, Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, 0.6, 1.0)), Vector3(0.0, y, 0.0)))


func _crate() -> void:
	add_mesh(box(Vector3(0.62, 0.5, 0.5)), Style.toon(Style.WOOD_LIGHT * tint, {"stripe_count": 6.0, "stripe_strength": 0.4, "brush_strength": 0.15}),
		Transform3D(Basis.IDENTITY, Vector3(0.0, 0.25, 0.0)))
	var edge := _wood(Style.WOOD_DARK)
	for x in [-0.3, 0.3]:
		for z in [-0.24, 0.24]:
			add_mesh(box(Vector3(0.05, 0.52, 0.05)), edge, Transform3D(Basis.IDENTITY, Vector3(x, 0.26, z)))


func _bucket() -> void:
	var profile := PackedVector2Array([Vector2(0.15, 0.0), Vector2(0.17, 0.15), Vector2(0.19, 0.3)])
	add_mesh(MeshKit.lathe(profile, 14), _wood(Style.WOOD_LIGHT))
	add_mesh(MeshKit.disc(0.17, 0.24, 14), Style.toon(Color(0.2, 0.25, 0.4)))
	add_mesh(torus(0.17, 0.2), Style.toon(Style.IRON), Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, 0.5, 1.0)), Vector3(0.0, 0.26, 0.0)))


func _shield() -> void:
	# Yere yaslanmış yuvarlak ahşap kalkan (yüzü yerel +Z'ye bakar): krem yüzde kırmızı Hun güneşi (silah
	# sehpası modelindeki kalkanla aynı motif), koyu demir kenar, ortada umbo ve bronz çiviler.
	var pivot := add_pivot("Shield", Transform3D(Basis(Vector3.RIGHT, deg_to_rad(72.0)), Vector3(0.0, 0.42, 0.0)))
	add_mesh(cylinder(0.42, 0.42, 0.05, 24), Style.toon(Color(0.42, 0.27, 0.16) * tint, {"brush_strength": 0.2}),
		Transform3D.IDENTITY, pivot)
	add_mesh(MeshKit.disc(0.41, 0.028, 32), _shield_face_material(), Transform3D.IDENTITY, pivot)
	var iron := Style.toon(Color(0.27, 0.24, 0.22), {"brush_strength": 0.15})
	add_mesh(torus(0.4, 0.45), iron, Transform3D.IDENTITY, pivot)
	add_mesh(ChibiCharacter._dome(0.085, 8), Style.toon(Style.GOLD.darkened(0.3)), Transform3D(Basis.IDENTITY, Vector3(0.0, 0.026, 0.0)), pivot)
	for i in 8:
		var a := TAU * float(i) / 8.0 + 0.2
		add_mesh(sphere(0.02), Style.toon(Style.GOLD.darkened(0.1)), Transform3D(Basis.IDENTITY, Vector3(cos(a) * 0.36, 0.03, sin(a) * 0.36)), pivot)


## Kalkan yüzü: üretilmiş güneş dokusu, Meshy modelleriyle aynı AtW dokulu malzemeyle (aynı boyalı görünüm).
func _shield_face_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = MeshyProp.SHADER
	mat.set_shader_parameter("albedo_texture", Style.shield_texture())
	mat.set_shader_parameter("albedo_tint", tint)
	mat.set_shader_parameter("paint_softness", 0.0)
	mat.set_shader_parameter("ink_strength", 0.0)
	return mat


func _drying_rack() -> void:
	var wood := _wood(Style.WOOD_DARK)
	for x in [-0.8, 0.8]:
		for z in [-0.25, 0.25]:
			add_mesh(cylinder(0.03, 0.035, 1.45, 8), wood, Transform3D(Basis(Vector3.RIGHT, z * 0.6), Vector3(x, 0.7, z * 0.4)))
	add_mesh(cylinder(0.03, 0.03, 1.8, 8), wood, Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.0, 1.38, 0.0)))
	# Asılı postlar ve kumaşlar (krem post, kırmızı ve kahverengi keçe: kamp referansının renkleri).
	var pelts := [Color(0.62, 0.45, 0.3), Color(0.88, 0.82, 0.7), Color(0.56, 0.16, 0.11)]
	for i in 3:
		var x := -0.5 + i * 0.5
		var mat := Style.toon_double(pelts[i] * tint, {"brush_strength": 0.25, "brush_scale": 12.0})
		add_mesh(box(Vector3(0.38, 0.7 - i * 0.1, 0.03)), mat, Transform3D(Basis(Vector3.UP, (i - 1) * 0.15), Vector3(x, 1.38 - (0.7 - i * 0.1) * 0.5, 0.0)))


func _tripod_pot() -> void:
	var wood := _wood(Style.WOOD_DARK)
	var top := Vector3(0.0, 1.15, 0.0)
	for i in 3:
		var a := TAU * float(i) / 3.0
		var foot := Vector3(cos(a) * 0.55, 0.0, sin(a) * 0.55)
		add_mesh(capsule(0.03, foot.distance_to(top) + 0.15), wood, limb_transform(foot, top + (top - foot).normalized() * 0.12))
	add_mesh(cylinder(0.006, 0.006, 0.5, 4), Style.toon(Style.IRON), Transform3D(Basis.IDENTITY, Vector3(0.0, 0.9, 0.0)))
	var pot_profile := PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.16, 0.03), Vector2(0.22, 0.15), Vector2(0.2, 0.28), Vector2(0.17, 0.32)])
	add_mesh(MeshKit.lathe(pot_profile, 16), Style.toon(Style.IRON.darkened(0.35)), Transform3D(Basis.IDENTITY, Vector3(0.0, 0.33, 0.0)))


func _stool() -> void:
	var wood := _wood(Style.WOOD)
	add_mesh(cylinder(0.2, 0.2, 0.06, 16), wood, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.36, 0.0)))
	for i in 3:
		var a := TAU * float(i) / 3.0
		add_mesh(cylinder(0.025, 0.03, 0.36, 6), wood, Transform3D(Basis.IDENTITY, Vector3(cos(a) * 0.13, 0.18, sin(a) * 0.13)))


func _wood_pile() -> void:
	var wood := Style.toon(Style.WOOD * tint, {"brush_strength": 0.2})
	var ends := Style.toon(Style.WOOD_LIGHT * tint)
	var rows := [[-0.36, -0.12, 0.12, 0.36], [-0.24, 0.0, 0.24], [-0.12, 0.12]]
	for row in rows.size():
		for x in rows[row]:
			var p := Vector3(x, 0.12 + row * 0.2, 0.0)
			add_mesh(cylinder(0.11, 0.11, 1.1, 10), wood, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), p))
			add_mesh(MeshKit.disc(0.1, 0.0, 10), ends, Transform3D(Basis(Vector3.RIGHT, PI * 0.5), p + Vector3(0.0, 0.0, 0.551)))


func _spear_rack() -> void:
	var wood := _wood(Style.WOOD_DARK)
	add_mesh(box(Vector3(1.0, 0.06, 0.06)), wood, Transform3D(Basis.IDENTITY, Vector3(0.0, 1.1, 0.0)))
	for x in [-0.45, 0.45]:
		add_mesh(cylinder(0.03, 0.035, 1.15, 8), wood, Transform3D(Basis.IDENTITY, Vector3(x, 0.57, 0.0)))
	var iron := Style.toon(Style.IRON.lightened(0.25))
	for i in 3:
		var x := -0.3 + i * 0.3
		var pivot := add_pivot("Spear", Transform3D(Basis(Vector3.RIGHT, -0.22), Vector3(x, 0.0, 0.18)))
		add_mesh(cylinder(0.018, 0.02, 2.2, 6), wood, Transform3D(Basis.IDENTITY, Vector3(0.0, 1.1, 0.0)), pivot)
		add_mesh(cylinder(0.0, 0.035, 0.22, 6), iron, Transform3D(Basis.IDENTITY, Vector3(0.0, 2.3, 0.0)), pivot)


func _cup() -> void:
	# Ahşap kupa: hafif genişleyen gövde, koyu ağız kenarı ve içinde koyu içecek (referanstaki kupalar gibi).
	var profile := PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.05, 0.0), Vector2(0.055, 0.06), Vector2(0.06, 0.11)])
	add_mesh(MeshKit.lathe(profile, 14), _wood(Style.WOOD_LIGHT))
	add_mesh(torus(0.054, 0.064), _wood(Style.WOOD_DARK), Transform3D(Basis.IDENTITY.scaled(Vector3(1.0, 0.5, 1.0)), Vector3(0.0, 0.11, 0.0)))
	add_mesh(MeshKit.disc(0.055, 0.095, 14), Style.toon(Color(0.2, 0.1, 0.06)))


func _saddle_bags() -> void:
	var leather := Style.toon(Color(0.45, 0.26, 0.14) * tint, {"brush_strength": 0.18})
	add_mesh(sphere(0.3), leather, Transform3D(Basis.IDENTITY.scaled(Vector3(1.3, 0.75, 0.9)), Vector3(0.0, 0.2, 0.0)))
	add_mesh(box(Vector3(0.5, 0.05, 0.42)), Style.toon(Color(0.6, 0.18, 0.13)), Transform3D(Basis.IDENTITY, Vector3(0.0, 0.41, 0.0)))


func _fence() -> void:
	# Yerel X boyunca 2,2 m'lik kısa çit: üç kaba direk, iki yatay kiriş (modeldeki gibi).
	var wood := _wood(Style.WOOD)
	for x in [-1.0, 0.0, 1.0]:
		add_mesh(cylinder(0.05, 0.06, 0.8, 8), wood, Transform3D(Basis.IDENTITY, Vector3(x, 0.4, 0.0)))
	for y in [0.32, 0.62]:
		add_mesh(cylinder(0.035, 0.035, 2.2, 8), _wood(Style.WOOD_LIGHT), Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0.0, y, 0.0)))
