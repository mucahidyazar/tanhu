@tool
class_name Water
extends Node3D
## Göl yüzeyi: su seviyesinde tek büyük bir düzlem.
## Kıyı çizgisi, arazi meshinin bu düzlemle kesiştiği yerde kendiliğinden oluşur.

const WATER_SHADER := preload("res://shaders/water.gdshader")

@export var size := Vector2(4600.0, 5200.0)
@export var center := Vector2(0.0, -2100.0)

var material: ShaderMaterial
var _mesh_instance: MeshInstance3D


func _ready() -> void:
	_build()


func _build() -> void:
	if _mesh_instance == null:
		_mesh_instance = MeshInstance3D.new()
		_mesh_instance.name = "WaterMesh"
		_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_mesh_instance)
	var plane := PlaneMesh.new()
	plane.size = size
	_mesh_instance.mesh = plane
	_mesh_instance.position = Vector3(center.x, TerrainShape.WATER_LEVEL, center.y)
	material = ShaderMaterial.new()
	material.shader = WATER_SHADER
	material.set_shader_parameter("ripple_a", _ripple_texture(19, 0.035))
	material.set_shader_parameter("ripple_b", _ripple_texture(43, 0.06))
	_mesh_instance.material_override = material


## Ay yönünü su parıltısıyla eşler (World çağırır).
func set_moon_direction(direction: Vector3) -> void:
	if material:
		material.set_shader_parameter("moon_direction", direction.normalized())


static func _ripple_texture(noise_seed: int, frequency: float) -> NoiseTexture2D:
	var noise := FastNoiseLite.new()
	noise.seed = noise_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	noise.fractal_octaves = 3
	var tex := NoiseTexture2D.new()
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	tex.as_normal_map = true
	tex.bump_strength = 6.0
	tex.noise = noise
	return tex
