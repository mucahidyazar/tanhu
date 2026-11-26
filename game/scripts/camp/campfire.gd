@tool
class_name Campfire
extends Procedural3D
## Kamp ateşi: taş halka, odunlar, kor yatağı, boyalı alevler, kıvılcımlar,
## titreyen sıcak ışık ve konumlu çıtırtı sesi.
##
## Taş halka ve odunlar Meshy modelidir (res://assets/props/campfire/campfire.glb; dokudaki korlar
## titreyerek parlar). Model yoksa taşlar ve odunlar kodla çizilir. Alevler, kıvılcımlar ve ışık her iki
## durumda da koddan gelir.

const FLAME_SHADER := preload("res://shaders/flame.gdshader")
const ROCK_SHADER := preload("res://shaders/rock.gdshader")
const CRACKLE_PATH := "res://audio/ambience/campfire_loop.wav"
const MODEL_ID := "campfire"
const MODEL_FOLDER := "props"
## Taş halkanın dış çapı (metre).
const RING_DIAMETER := 1.6
## Engel dairesinin en küçük yarıçapı (kodla çizilen halka ve alevler bunun içinde kalır).
const MIN_OBSTACLE_RADIUS := 0.9

@export var light_color := Color(1.0, 0.56, 0.24)
@export var light_energy := 2.6
@export var light_range := 8.0
@export var flame_scale := 1.0:
	set(value):
		flame_scale = value
		queue_rebuild()

var _light: OmniLight3D
var _time := 0.0
var _seed := 0.0
var _model: MeshyProp


func _ready() -> void:
	add_to_group(World.OBSTACLE_GROUP)
	_seed = float(StableSeed.of(self, 1000)) * 0.37
	super._ready()


func get_obstacle_circles() -> Array[Vector3]:
	var r := MIN_OBSTACLE_RADIUS
	if uses_model():
		r = maxf(r, _model.get_footprint_radius() + 0.05)
	return [Vector3(global_position.x, global_position.z, r)]


## Meshy modeli gösteriliyor mu (false = kodla çizilen taşlar ve odunlar)?
func uses_model() -> bool:
	return _model != null and _model.has_model()


## Ateş ışığının titreme çarpanı (saf fonksiyon, test edilebilir). Sonuç ~[0.72, 1.18] aralığındadır.
static func flicker(t: float, flicker_seed: float = 0.0) -> float:
	var s := t + flicker_seed
	var slow := sin(s * 1.7) * 0.06 + sin(s * 2.9 + 1.3) * 0.05
	var fast := sin(s * 11.0 + 0.7) * 0.035 + sin(s * 17.3 + 2.1) * 0.025
	var pops := maxf(sin(s * 0.9 + 4.0), 0.0) * sin(s * 23.0) * 0.04
	return clampf(0.96 + slow + fast + pops, 0.72, 1.18)


func _process(delta: float) -> void:
	if _light == null:
		return
	_time += delta
	var f := flicker(_time, _seed)
	_light.light_energy = light_energy * f
	_light.position = Vector3(sin(_time * 3.1) * 0.03, 0.65 + (f - 1.0) * 0.15, cos(_time * 2.6) * 0.03)


func _build() -> void:
	_model = null
	if MeshyProp.exists(MODEL_FOLDER, MODEL_ID):
		_build_model()
	if uses_model():
		_build_ember_bed(0.26, 3)
	else:
		_build_stones()
		_build_logs()
		_build_ember_bed(0.38, 7)
	_build_flames()
	_light = OmniLight3D.new()
	_light.name = "FireLight"
	_light.light_color = light_color
	_light.light_energy = light_energy
	_light.omni_range = light_range
	# Düşük sönüm: ateş, referanstaki gibi kampın çevresini (≈ 6 m) geniş ve yumuşak bir sıcak halkayla
	# aydınlatır; menzilin sonunda söner, ön plandaki çayıra taşmaz.
	_light.omni_attenuation = 0.45
	_light.shadow_enabled = false
	_light.shadow_blur = 1.5
	_light.light_size = 0.25
	_light.light_volumetric_fog_energy = 2.2
	_light.position = Vector3(0.0, 0.65, 0.0)
	add_generated(_light)
	var embers := Fx.embers()
	embers.name = "Embers"
	embers.position = Vector3(0.0, 0.25, 0.0)
	add_generated(embers)
	if not Engine.is_editor_hint():
		_build_sound()


func _build_model() -> void:
	var prop := MeshyProp.new()
	prop.name = "FireRing"
	prop.model_id = MODEL_ID
	prop.folder = MODEL_FOLDER
	prop.size_axis = MeshyProp.SizeAxis.FOOTPRINT
	prop.target_size = RING_DIAMETER
	prop.sink = 0.03
	prop.ink_strength = 0.3
	# Ateş taşları referanstaki gibi açık gri, ama biraz isli: güçlü ateş ışığında beyaza patlamasın.
	prop.tint = Color(0.8, 0.78, 0.76)
	# Dokudaki korlar kendi kendine parlar; taşlar ateşin ışığını alır.
	prop.set_shader_parameter(&"ember_glow", 2.2)
	prop.set_shader_parameter(&"base_shade_height", 0.12)
	add_generated(prop)
	if prop.has_model():
		_model = prop
	else:
		remove_child(prop)
		prop.queue_free()


func _build_stones() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = ROCK_SHADER
	mat.set_shader_parameter("moss_amount", 0.0)
	# Ateş taşları koyu, isli gri: güçlü ateş ışığında bile beyaz görünmesin.
	mat.set_shader_parameter("rock_color", Color(0.46, 0.44, 0.43))
	mat.set_shader_parameter("rock_shadow", Color(0.26, 0.26, 0.3))
	mat.set_shader_parameter("soot", 0.45)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var count := 11
	for i in count:
		var a := TAU * float(i) / float(count) + rng.randf_range(-0.12, 0.12)
		var r := 0.62 + rng.randf_range(-0.05, 0.05)
		var s := rng.randf_range(0.15, 0.22)
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.8, 1.1), s))
		add_mesh(MeshKit.rock(100 + i, 2, 0.3), mat, Transform3D(basis, Vector3(cos(a) * r, 0.0, sin(a) * r)))


func _build_logs() -> void:
	var wood := Style.toon(Style.WOOD_DARK.darkened(0.2), {"brush_strength": 0.2})
	var charred := Style.toon(Color(0.12, 0.08, 0.07))
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 5:
		var a := TAU * float(i) / 5.0 + 0.3
		var foot := Vector3(cos(a) * 0.46, 0.04, sin(a) * 0.46)
		var top := Vector3(cos(a + 2.4) * 0.06, 0.42 + rng.randf_range(-0.05, 0.06), sin(a + 2.4) * 0.06)
		add_mesh(capsule(0.055, foot.distance_to(top)), wood if i % 2 == 0 else charred, limb_transform(foot, top))


## Alevlerin dibindeki kor yatağı: parlayan disk ve birkaç kor parçası (alevler odunlarla buradan birleşir).
func _build_ember_bed(bed_radius: float, pieces: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	add_mesh(MeshKit.disc(bed_radius, 0.035, 20), Style.glow(Color(1.0, 0.38, 0.1), 2.2))
	for i in pieces:
		var a := rng.randf() * TAU
		var r := rng.randf_range(0.05, bed_radius * 0.8)
		add_mesh(sphere(rng.randf_range(0.03, 0.05), 0.6), Style.glow(Color(1.0, 0.45, 0.12), 3.5),
			Transform3D(Basis.IDENTITY, Vector3(cos(a) * r, 0.05, sin(a) * r)))


func _build_flames() -> void:
	# Farklı boyut ve hızlarda üst üste binen alev kartları.
	# Katmanlar arkalarındakini kısmen örter (flame.gdshader "coverage"): çekirdekte enerjiler toplanmaz, en
	# üstteki katman baskın olur. Enerjiler, alevin dibi sarı-turuncu kalacak kadardır: beyaza patlarsa gece renk
	# ayarı onu soluk griye çevirir. İçteki küçük katmanlar daha sönüktür.
	var layers := [
		[Vector2(1.25, 1.2), 1.5, 1.4, 0.0, Vector3(0.0, 0.0, 0.0)],
		[Vector2(0.95, 1.05), 1.3, 1.8, 0.37, Vector3(0.14, 0.0, 0.06)],
		[Vector2(0.85, 0.9), 1.15, 2.1, 0.71, Vector3(-0.15, 0.0, -0.05)],
		[Vector2(0.7, 0.75), 1.0, 2.4, 0.53, Vector3(0.05, 0.0, -0.12)],
		[Vector2(0.55, 0.55), 0.9, 2.7, 0.13, Vector3(0.0, 0.0, 0.1)],
	]
	for layer in layers:
		var size: Vector2 = layer[0] * flame_scale
		var quad := QuadMesh.new()
		quad.size = size
		quad.center_offset = Vector3(0.0, size.y * 0.5, 0.0)
		var mat := ShaderMaterial.new()
		mat.shader = FLAME_SHADER
		mat.set_shader_parameter("energy", layer[1])
		mat.set_shader_parameter("speed", layer[2])
		mat.set_shader_parameter("seed", layer[3])
		var mi := add_mesh(quad, mat, Transform3D(Basis.IDENTITY, layer[4] + Vector3(0.0, 0.02, 0.0)))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_sound() -> void:
	var stream := AudioUtil.load_stream(CRACKLE_PATH, true)
	if stream == null:
		return
	var player := AudioStreamPlayer3D.new()
	player.name = "Crackle"
	player.stream = stream
	player.bus = AudioUtil.bus_or_master(&"Ambience")
	player.volume_db = -4.0
	player.unit_size = 3.0
	player.max_distance = 40.0
	player.autoplay = true
	player.position = Vector3(0.0, 0.4, 0.0)
	add_generated(player)
