class_name RideEffects
extends Node3D
## Sürüşün izleri (at; RideableHorse her toynak vuruşunda hoof_strike çağırır): toz bulutu, yerde toynak izi, toynak sesi. Düğüm dünya uzayındadır (top_level):
## toz ve iz atla gitmez, yerinde söner. Toz ve iz birer MultiMesh'tir (tek çizim), örnekler sıradaki eski örnekten döner (havuz); ses tek
## AudioStreamPlayer3D'dir, çok sesli (max_polyphony), üç kodla basılmış vuruştan rastgele (audio/sfx/gen/hoof_*.wav; data/audio/bake/hoof_*.json).
## Yürüyüşe göre: adımda yalnız ses (kısık), tırısta küçük toz ve iz, dörtnalda tam toz (geriye savrulur, kabarır) ve derin iz.
## Sıçrama (2026-11-08): kalkışta arka toynaklar «leap» (toz, iz, ses), inişte her toynak «land» vurur: en büyük toz bulutu, derin iz, yüksek ses ve üstüne
## ağır bir iniş gümlemesi (ikinci oynatıcı, audio/sfx/gen/hoof_land_*.wav; data/audio/bake/hoof_land_*.json).
## Gölgelendiriciler koddadır (DUST_CODE, PRINT_CODE): toz yarı saydam, ışık alan bir billboard; iz zemine yatan, açılmış toprak rengi bir
## lekedir, ortasında toynağın koyu çukuru (gecede koyu leke koyu çimende kaybolur, yolun toprağı gibi açık leke okunur; 2026-11-08 karesi).

const DUST_POOL := 40
const PRINT_POOL := 56
## Tozun ömrü (sn), başlangıç ve son boyu (m), yükselişi (m/sn), rengi (kuru bozkır toprağı) ve kendi ışığı (gecede kararmasın: ay ışığında
## yalnız yansıyan toz yeşile döner, kaybolur; payı rengin bu katıdır).
const DUST_LIFE := 0.95
const DUST_SIZE := Vector2(0.3, 1.1)
const DUST_RISE := 0.25
const DUST_COLOR := Color(0.56, 0.5, 0.42, 0.34)
const DUST_GLOW := 0.22
## Vuruş başına toz bulutu (dörtnalda iki, tırısta bir; sıçramanın kalkışında iki, inişinde üç).
const DUST_PUFFS := {&"trot": 1, &"gallop": 2, &"leap": 2, &"land": 3}
## İzin ömrü (sn; son çeyreğinde solar), boyu (m; okunsun diye gerçeğinden iri: ezilip savrulan ot ve toprak), zeminden yüksekliği (m; kısa otun
## dibini örter) ve rengi (açılmış toprak: arazinin dirt_color'ından biraz koyu, nemli; uzak kamerada yolun toprağı gibi okunur).
const PRINT_LIFE := 12.0
const PRINT_SIZE := Vector2(0.27, 0.33)
const PRINT_LIFT := 0.05
const PRINT_COLOR := Color(0.47, 0.38, 0.28, 0.85)
## Yürüyüşe göre tozun ve izin gücü (0..1) ve sesin kazancı (dB). İnişin tozu dörtnalınkinden de kabarık (gücü 1'in üstü: boy ve saydamlık).
const STRENGTH := {&"walk": 0.0, &"trot": 0.45, &"gallop": 1.0, &"leap": 0.8, &"land": 1.25}
const PRINT_GAITS: Array[StringName] = [&"trot", &"gallop", &"leap", &"land"]
const VOLUME_DB := {&"walk": -15.0, &"trot": -10.0, &"gallop": -5.0, &"leap": -6.0, &"land": -3.0}
const SOUNDS: Array[String] = ["res://audio/sfx/gen/hoof_a.wav", "res://audio/sfx/gen/hoof_b.wav", "res://audio/sfx/gen/hoof_c.wav"]
## İnişin ağır gümlemesi (toynak sesinin üstüne; yoksa yalnız toynak sesi) ve kazancı (dB).
const LAND_SOUNDS: Array[String] = ["res://audio/sfx/gen/hoof_land_a.wav", "res://audio/sfx/gen/hoof_land_b.wav"]
const LAND_VOLUME_DB := -4.0

const DUST_CODE := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, diffuse_lambert_wrap, specular_disabled, skip_vertex_transform;
uniform sampler2D dot_texture : source_color, filter_linear;
uniform float glow = 0.45;
varying float v_life;
void vertex() {
	// Billboard (görüş uzayında): dörtgen kameraya döner, boyu örneğin dönüşümünün ölçeğinden.
	float size = length(MODEL_MATRIX[0].xyz);
	vec3 center = (MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	// Yayvan bulut: yere yakın, eni boyundan geniş.
	VERTEX = center + vec3(VERTEX.x * 1.45, VERTEX.y * 0.8, 0.0) * size;
	NORMAL = vec3(0.0, 0.0, 1.0);
	v_life = INSTANCE_CUSTOM.x;
}
void fragment() {
	vec4 dot = texture(dot_texture, UV);
	float fade = smoothstep(0.0, 0.12, v_life) * (1.0 - smoothstep(0.35, 1.0, v_life));
	ALBEDO = COLOR.rgb;
	EMISSION = COLOR.rgb * glow;
	ALPHA = pow(dot.a, 1.8) * COLOR.a * fade;
	ROUGHNESS = 1.0;
}
"""

const PRINT_CODE := """
shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled, specular_disabled;
// Arazinin ışığı (AtW cel: aydınlık taraf düz); Lambert'le alçak ay ışığında iz araziden çok koyu, mavi kalıyordu.
#include "res://shaders/include/atw_light.gdshaderinc"
void fragment() {
	// Toynak izi (+V atın gittiği yön): savrulmuş toprağın lekesi, kenarı düzensiz ve yumuşak (dalga dünya konumundan: her iz başka),
	// arkaya doğru biraz uzun; önde toynağın çukuru koyu.
	vec2 p = UV * 2.0 - 1.0;
	vec3 w = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float a = atan(p.y, p.x);
	float wob = 0.1 * sin(a * 5.0 + w.x * 9.0) + 0.07 * sin(a * 3.0 + w.z * 11.0);
	float r = length(vec2(p.x, p.y * (p.y < 0.0 ? 0.85 : 1.15)));
	float patch = 1.0 - smoothstep(0.3 + wob, 0.95 + wob, r);
	float cup = (1.0 - smoothstep(0.16, 0.4, length((p - vec2(0.0, 0.22)) * vec2(1.0, 1.3)))) * smoothstep(-0.1, 0.25, p.y);
	ALBEDO = COLOR.rgb * mix(1.0, 0.5, cup);
	ALPHA = patch * COLOR.a;
	ROUGHNESS = 1.0;
}
"""

## Zemin yüksekliği kaynağı (height_at; yoksa vuruşun yüksekliği).
var terrain_shape: RefCounted
## Etkin toz ve iz sayısı (sınama okur).
var dust_count := 0
var print_count := 0

var _dust: MultiMeshInstance3D
var _prints: MultiMeshInstance3D
var _dust_age := PackedFloat32Array()
var _dust_pos := PackedVector3Array()
var _dust_vel := PackedVector3Array()
var _dust_strength := PackedFloat32Array()
var _print_age := PackedFloat32Array()
var _print_xform: Array[Transform3D] = []
var _next_dust := 0
var _next_print := 0
var _sound: AudioStreamPlayer3D
var _land_sound: AudioStreamPlayer3D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	top_level = true
	global_transform = Transform3D.IDENTITY
	_rng.seed = StableSeed.of(self, 7717)
	if terrain_shape == null:
		var world := PlayerController.find_world(self)
		terrain_shape = world.get_terrain_shape() if world else null
	_dust = _make_multimesh("Dust", DUST_POOL, _dust_material(), true)
	_prints = _make_multimesh("Prints", PRINT_POOL, _print_material(), false)
	_dust_age.resize(DUST_POOL)
	_dust_age.fill(-1.0)
	_dust_pos.resize(DUST_POOL)
	_dust_vel.resize(DUST_POOL)
	_dust_strength.resize(DUST_POOL)
	_print_age.resize(PRINT_POOL)
	_print_age.fill(-1.0)
	_print_xform.resize(PRINT_POOL)
	_build_sound()
	set_process(false)


## Bir toynak vuruşu: at (yer; y zeminden alınır), heading (atın yönü, yatay birim), speed (m/sn), gait (walk, trot, gallop; sıçramada leap kalkış,
## land iniş), front (ön toynak mı).
func hoof_strike(at: Vector3, heading: Vector3, speed: float, gait: StringName, front: bool) -> void:
	var ground := at
	if terrain_shape:
		ground.y = float(terrain_shape.call(&"height_at", at.x, at.z))
	_play_sound(ground, gait, speed)
	if gait == &"land":
		_play_land(ground, front)
	var strength := float(STRENGTH.get(gait, 0.0))
	if strength > 0.0:
		for i in int(DUST_PUFFS.get(gait, 1)):
			_add_dust(ground, heading, speed, strength * (0.8 if front else 1.0))
	if PRINT_GAITS.has(gait):
		_add_print(ground, heading)
	set_process(true)


func _process(delta: float) -> void:
	var alive := false
	dust_count = 0
	var mm := _dust.multimesh
	for i in DUST_POOL:
		if _dust_age[i] < 0.0:
			continue
		_dust_age[i] += delta / DUST_LIFE
		if _dust_age[i] >= 1.0:
			_dust_age[i] = -1.0
			mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))
			continue
		alive = true
		dust_count += 1
		var life := _dust_age[i]
		# Toz yavaşlayarak geriye savrulur, yükselir, kabarır.
		_dust_vel[i] = _dust_vel[i] * exp(-2.5 * delta)
		_dust_pos[i] += (_dust_vel[i] + Vector3.UP * DUST_RISE * (1.0 - life)) * delta
		var size := lerpf(DUST_SIZE.x, DUST_SIZE.y, 1.0 - pow(1.0 - life, 2.0)) * lerpf(0.6, 1.0, _dust_strength[i])
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * size), _dust_pos[i]))
		mm.set_instance_custom_data(i, Color(life, 0.0, 0.0, 0.0))
	print_count = 0
	var pm := _prints.multimesh
	for i in PRINT_POOL:
		if _print_age[i] < 0.0:
			continue
		_print_age[i] += delta / PRINT_LIFE
		if _print_age[i] >= 1.0:
			_print_age[i] = -1.0
			pm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))
			continue
		alive = true
		print_count += 1
		var fade := 1.0 - smoothstep(0.75, 1.0, _print_age[i])
		var c := PRINT_COLOR
		pm.set_instance_color(i, Color(c.r, c.g, c.b, c.a * fade))
	if not alive:
		set_process(false)


func _add_dust(ground: Vector3, heading: Vector3, speed: float, strength: float) -> void:
	var i := _next_dust
	_next_dust = (_next_dust + 1) % DUST_POOL
	var side := heading.cross(Vector3.UP)
	_dust_age[i] = _rng.randf_range(0.0, 0.08)
	_dust_pos[i] = ground + Vector3.UP * _rng.randf_range(0.05, 0.14) + side * _rng.randf_range(-0.18, 0.18) - heading * _rng.randf_range(0.0, 0.3)
	# Toynak toprağı geriye ve yana savurur: hızın bir payı kadar.
	_dust_vel[i] = -heading * speed * 0.18 * strength + side * _rng.randf_range(-0.4, 0.4) + Vector3.UP * 0.25
	_dust_strength[i] = strength * _rng.randf_range(0.75, 1.25)
	var c := DUST_COLOR
	_dust.multimesh.set_instance_color(i, Color(c.r, c.g, c.b, c.a * lerpf(0.55, 1.0, strength)))
	_dust.multimesh.set_instance_custom_data(i, Color(0.0, 0.0, 0.0, 0.0))
	_dust.multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * DUST_SIZE.x), _dust_pos[i]))


func _add_print(ground: Vector3, heading: Vector3) -> void:
	var i := _next_print
	_next_print = (_next_print + 1) % PRINT_POOL
	_print_age[i] = 0.0
	var normal := _ground_normal(ground)
	var forward := (heading - normal * heading.dot(normal)).normalized() if heading.length_squared() > 0.0001 else Vector3.FORWARD
	# Her iz biraz başka: yönü ±12°, boyu ×0,85..1,15 (sıra sıra aynı leke damga gibi durur).
	forward = forward.rotated(normal, deg_to_rad(_rng.randf_range(-12.0, 12.0)))
	var right := forward.cross(normal).normalized()
	var grow := _rng.randf_range(0.85, 1.15)
	var basis := Basis(right * PRINT_SIZE.x * grow, normal, forward * PRINT_SIZE.y * grow)
	var xform := Transform3D(basis, ground + normal * PRINT_LIFT)
	_print_xform[i] = xform
	_prints.multimesh.set_instance_transform(i, xform)
	_prints.multimesh.set_instance_color(i, PRINT_COLOR)


func _ground_normal(at: Vector3) -> Vector3:
	if terrain_shape == null:
		return Vector3.UP
	var e := 0.25
	var hx := float(terrain_shape.call(&"height_at", at.x + e, at.z)) - float(terrain_shape.call(&"height_at", at.x - e, at.z))
	var hz := float(terrain_shape.call(&"height_at", at.x, at.z + e)) - float(terrain_shape.call(&"height_at", at.x, at.z - e))
	return Vector3(-hx, 2.0 * e, -hz).normalized()


func _play_sound(at: Vector3, gait: StringName, speed: float) -> void:
	if _sound == null:
		return
	_sound.global_position = at + Vector3.UP * 0.2
	_sound.volume_db = float(VOLUME_DB.get(gait, -12.0)) + clampf(speed - 4.0, 0.0, 6.0) * 0.3
	_sound.play()


## İnişin ağır gümlemesi (ön toynakta tam, arkada kısık).
func _play_land(at: Vector3, front: bool) -> void:
	if _land_sound == null:
		return
	_land_sound.global_position = at + Vector3.UP * 0.2
	_land_sound.volume_db = LAND_VOLUME_DB - (0.0 if front else 4.0)
	_land_sound.play()


func _build_sound() -> void:
	_sound = _make_player("Hooves", SOUNDS, 1.12, 2.5, 6)
	_land_sound = _make_player("Landing", LAND_SOUNDS, 1.06, 1.5, 4)


## Çok sesli 3B oynatıcı: kayıtlardan rastgele, perde ve yükseklik oynar (kayıt yoksa null).
func _make_player(node_name: String, paths: Array[String], pitch: float, volume: float, polyphony: int) -> AudioStreamPlayer3D:
	var randomizer := AudioStreamRandomizer.new()
	randomizer.random_pitch = pitch
	randomizer.random_volume_offset_db = volume
	for path in paths:
		var stream := AudioUtil.load_stream(path, false)
		if stream:
			randomizer.add_stream(-1, stream)
	if randomizer.streams_count == 0:
		return null
	var player := AudioStreamPlayer3D.new()
	player.name = node_name
	player.stream = randomizer
	player.max_polyphony = polyphony
	player.bus = AudioUtil.bus_or_master(&"SFX")
	player.unit_size = 3.0
	player.max_distance = 45.0
	add_child(player)
	return player


func _make_multimesh(node_name: String, count: int, material: Material, billboard: bool) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = billboard
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	if not billboard:
		# Zemine yatan dörtgen: yüzü +Y (örneğin dönüşümü zeminin normaline çevirir).
		quad.orientation = PlaneMesh.FACE_Y
	mm.mesh = quad
	mm.instance_count = count
	for i in count:
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.material_override = material
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Örnekler dünyanın her yerine düşebilir: sınır kutusu geniş tutulur (kırpılmasın).
	mmi.custom_aabb = AABB(Vector3(-200.0, -50.0, -200.0), Vector3(400.0, 150.0, 400.0))
	add_child(mmi)
	return mmi


## Malzemeler örneğe aittir (gölgelendirici küçük; durağan önbellek çıkışta kaynak tutardı).
static func _dust_material() -> ShaderMaterial:
	var mat := _material(DUST_CODE)
	mat.set_shader_parameter("glow", DUST_GLOW)
	return mat


static func _print_material() -> ShaderMaterial:
	return _material(PRINT_CODE, false)


static func _material(code: String, dot := true) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = code
	var mat := ShaderMaterial.new()
	mat.shader = shader
	if dot:
		mat.set_shader_parameter("dot_texture", Fx.soft_dot_texture())
	return mat
