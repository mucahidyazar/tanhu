@tool
class_name HearthEmbers
extends Procedural3D
## Lan Hatun'un yurdunun ocağı (story.md §4, godot.md §3.6): üç ocak taşı, kül yatağı, közler, alçak iki alev ve
## Campfire.flicker ile titreyen sıcak köz ışığı (OmniLight3D). Şafaktan önce ateş köze inmiştir.
##
## Mit sinemasının iki panosu burada bir kez de dünyada olur: «ocak üç taşın üstüne kuruldu» (pano 5) ve «Al Karısı
## doğum yurduna geldi, ocak taşını geçemedi» (pano 6). Taşlar üçtür; biri kapıya bakar (yerel +Z, yurdun kapı
## yönü): eşik taşı (StoneDoor). Doğum sahnesinde (prologue_birth) kapıdan düşen gölge onda durur:
## door_stone_position() dünya konumunu verir.
##
## Köz ışığı gölgelidir (godot.md §7.2: gölgeli konumsal ışık ≤4): yurdun içinde kişilerin gölgesi keregeye düşer.
## Kül yatağı ücretsiz bir dokuyla boyanır (burned_ground_01, assets/_free; düğüm free_asset meta verisini taşır).

const FLAME_SHADER := preload("res://shaders/flame.gdshader")
const ROCK_SHADER := preload("res://shaders/rock.gdshader")
const GROUND_SHADER := preload("res://assets/maps/ordos/ordos_ground.gdshader")
## Kül yatağının ücretsiz dokusu (FREE_ASSETS.json kimliği ve dosyası).
const ASH_ASSET_ID := "burned_ground_01"
const ASH_TEXTURE_PATH := "res://assets/_free/texture/burned_ground_01/burned_ground_01_diff_1k.jpg"
## Titremenin sınırları (Campfire.flicker; test_campfire.gd).
const FLICKER_LOW := 0.72
const FLICKER_HIGH := 1.18
## Taşların adları: kapıya bakan (eşik taşı), sol ve sağ (kapıdan içeri bakınca).
const STONE_NAMES: Array[String] = ["StoneDoor", "StoneLeft", "StoneRight"]

@export var light_color := Color(1.0, 0.5, 0.2)
@export var light_energy := 1.6
@export var light_range := 4.5
## Işığın uzaklıkla sönümü (Godot'nun omni_attenuation üssü): köz ocağın çevresini aydınlatır, keregenin üstü ve
## uuk karanlıkta kalır.
@export var light_attenuation := 1.6
## Köz ışığı gölge düşürsün mü?
@export var cast_shadows := true
## Taşların merkeze uzaklığı ve kül yatağının yarıçapı (metre).
@export var stone_ring := 0.36:
	set(value):
		stone_ring = value
		queue_rebuild()
@export var ash_radius := 0.66:
	set(value):
		ash_radius = value
		queue_rebuild()
## Alevlerin boyu (0 = yalnız köz).
@export_range(0.0, 2.0) var flame_scale := 0.55:
	set(value):
		flame_scale = value
		queue_rebuild()
## Kül dokusu (boşsa ASH_TEXTURE_PATH; dünya, sahneyle birlikte yüklenen dokuyu verir).
@export var ash_texture: Texture2D:
	set(value):
		ash_texture = value
		queue_rebuild()

var _light: OmniLight3D
var _time := 0.0
var _seed := 0.0


func _ready() -> void:
	_seed = float(StableSeed.of(self, 1000)) * 0.37 + 11.0
	super._ready()


## Köz ışığının titreme çarpanı (saf; Campfire.flicker): [0,72; 1,18].
static func ember_flicker(t: float, flicker_seed: float = 0.0) -> float:
	return Campfire.flicker(t, flicker_seed)


## Işığın şu anki titreme çarpanı (light_energy'ye oran).
func flicker_factor() -> float:
	return _light.light_energy / light_energy if _light and light_energy > 0.0 else 0.0


## Kapıya bakan ocak taşının (eşik taşı) dünya konumu.
func door_stone_position() -> Vector3:
	var stone := get_node_or_null(^"StoneDoor") as Node3D
	return stone.global_position if stone else to_global(Vector3(0.0, 0.0, stone_ring))


## Köz ışığı (sahne, gölgenin bedelini çekime göre ayarlar; kurulmadan null).
func ember_light() -> OmniLight3D:
	return _light


func _process(delta: float) -> void:
	if _light == null:
		return
	_time += delta
	var f := ember_flicker(_time, _seed)
	_light.light_energy = light_energy * f
	_light.position = Vector3(sin(_time * 2.3) * 0.02, 0.32 + (f - 1.0) * 0.08, cos(_time * 1.9) * 0.02)


func _build() -> void:
	_build_ash()
	_build_stones()
	_build_embers()
	_build_flames()
	_light = OmniLight3D.new()
	_light.name = "EmberLight"
	_light.light_color = light_color
	_light.light_energy = light_energy * ember_flicker(0.0, _seed)
	_light.omni_range = light_range
	_light.omni_attenuation = light_attenuation
	_light.shadow_enabled = cast_shadows
	_light.shadow_blur = 1.3
	_light.light_size = 0.18
	_light.light_volumetric_fog_energy = 1.4
	_light.position = Vector3(0.0, 0.32, 0.0)
	add_generated(_light)
	var sparks := Fx.embers(8)
	sparks.name = "Sparks"
	sparks.position = Vector3(0.0, 0.12, 0.0)
	add_generated(sparks)


## Kül yatağı: ocağın çevresinde küllü, yanık toprak (zemin gölgelendiricisinin disk kipi; kenarı gürültülü).
func _build_ash() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = GROUND_SHADER
	mat.set_shader_parameter("mode", 2)
	mat.set_shader_parameter("disc_center", Vector2.ZERO)
	mat.set_shader_parameter("disc_radius", ash_radius)
	mat.set_shader_parameter("disc_soft", 0.16)
	mat.set_shader_parameter("base_color", Color(0.16, 0.135, 0.125))
	mat.set_shader_parameter("dark_color", Color(0.33, 0.29, 0.25))
	mat.set_shader_parameter("mottle_tex", _ash_texture())
	mat.set_shader_parameter("mottle_tile", 1.4)
	mat.set_shader_parameter("mottle_lod", 2.0)
	mat.set_shader_parameter("mottle_strength", 0.7)
	mat.set_shader_parameter("interior", 1.0)
	var mi := add_mesh(MeshKit.disc(ash_radius + 0.12, 0.016, 28), mat)
	mi.name = "Ash"
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.set_meta(&"free_asset", ASH_ASSET_ID)


## Üç ocak taşı (120° arayla; biri kapıya bakar): kazanı taşıyan dik, köşeli, isli taşlar; ince yüzleri ocağa döner.
func _build_stones() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = ROCK_SHADER
	mat.set_shader_parameter("moss_amount", 0.0)
	mat.set_shader_parameter("rock_color", Color(0.5, 0.47, 0.44))
	mat.set_shader_parameter("rock_shadow", Color(0.22, 0.21, 0.24))
	mat.set_shader_parameter("soot", 0.7)
	for i in 3:
		# Yerel +Z kapıdır: açı 0 kapıya bakan taş. Taşın yerel z'si (ince yanı) ocağın merkezine bakar.
		var a := TAU * float(i) / 3.0
		var dir := Vector3(sin(a), 0.0, cos(a))
		var size := Vector3(0.2, 0.26, 0.13) * (1.0 - 0.05 * float(i))
		var lean := Basis(Vector3.RIGHT, deg_to_rad(-6.0 + 3.0 * float(i)))
		var basis := (Basis(Vector3.UP, a) * lean).scaled(size)
		var mi := add_mesh(MeshKit.rock(310 + i * 7, 1, 0.42), mat, Transform3D(basis, dir * stone_ring + Vector3(0.0, -0.03, 0.0)))
		mi.name = STONE_NAMES[i]


## Taşların arasında kor yatağı ve kor parçaları (kendi kendine parlar).
func _build_embers() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2341
	add_mesh(MeshKit.disc(0.2, 0.03, 18), Style.glow(Color(1.0, 0.36, 0.1), 2.0))
	for i in 7:
		var a := rng.randf() * TAU
		var r := rng.randf_range(0.04, 0.18)
		var mi := add_mesh(sphere(rng.randf_range(0.025, 0.045), 0.55), Style.glow(Color(1.0, 0.42, 0.12), 3.2),
			Transform3D(Basis.IDENTITY, Vector3(cos(a) * r, 0.045, sin(a) * r)))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Közün üstünde alçak iki alev (flame.gdshader); flame_scale 0 ise yok.
func _build_flames() -> void:
	if flame_scale <= 0.0:
		return
	var layers := [[Vector2(0.5, 0.45), 1.05, 1.5, 0.21, Vector3(0.02, 0.0, 0.0)], [Vector2(0.36, 0.32), 0.9, 2.1, 0.63, Vector3(-0.04, 0.0, 0.03)]]
	for i in layers.size():
		var layer: Array = layers[i]
		var size: Vector2 = layer[0] * flame_scale
		var quad := QuadMesh.new()
		quad.size = size
		quad.center_offset = Vector3(0.0, size.y * 0.5, 0.0)
		var mat := ShaderMaterial.new()
		mat.shader = FLAME_SHADER
		mat.set_shader_parameter("energy", layer[1])
		mat.set_shader_parameter("speed", layer[2])
		mat.set_shader_parameter("seed", layer[3])
		var mi := add_mesh(quad, mat, Transform3D(Basis.IDENTITY, layer[4] + Vector3(0.0, 0.03, 0.0)))
		mi.name = "Flame%d" % i
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _ash_texture() -> Texture2D:
	if ash_texture:
		return ash_texture
	return load(ASH_TEXTURE_PATH) as Texture2D if ResourceLoader.exists(ASH_TEXTURE_PATH) else null
