class_name HearthView
extends Procedural3D
## «Ocak»ta kurulan ateşin görünüşü (HearthFire'ın yüzü; kamp ateşinin, Campfire'ın, dilinde): kül yatağı, tipinin çatlattığı eski taşlar
## (yeni taş gelince yana itilir), üçgen dizilen üç ocak taşı, konan ve beslenen odun, kavın tütmesi, kor yatağı, boyalı alevler
## (flame.gdshader; katmanları Campfire'ınkiyle aynıdır: büyük evrede alev menü ateşinin alevidir), kıvılcım, duman, titreyen sıcak ışık
## (gölgesiz, K63) ve vuruşun kıvılcım patlaması. Görünüş kesik anahtar değişince (taş, odun, evre) yeniden kurulur; kare başına yalnız ışığın
## menzili ve enerjisi (HearthFire.light_now × Campfire.flicker), alevin boyu (HearthFire.flame_scale) ve dumanın boyu yazılır.
## Ses (çıtırtı) adımın işidir (hearth_build.gd: evreye göre yatak).
##   var v := HearthView.new(); v.bind(fire); world.add_child(v); v.global_position = ateşin_yeri
##   v.burst()              # vuruşun kıvılcımı
##   v.cracked = false      # eski taşlar gizli

const FLAME_SHADER := preload("res://shaders/flame.gdshader")
const ROCK_SHADER := preload("res://shaders/rock.gdshader")
const LIGHT_COLOR := Color(1.0, 0.74, 0.42)
const ASH_COLOR := Color(0.24, 0.22, 0.21)
const CHAR_COLOR := Color(0.11, 0.08, 0.07)
## Campfire'ın alev katmanları (boy, enerji, hız, tohum, kayma): büyük evrede ölçek 1, menü ateşinin alevi.
const LAYERS := [
	[Vector2(1.25, 1.2), 1.5, 1.4, 0.0, Vector3(0.0, 0.0, 0.0)],
	[Vector2(0.95, 1.05), 1.3, 1.8, 0.37, Vector3(0.14, 0.0, 0.06)],
	[Vector2(0.85, 0.9), 1.15, 2.1, 0.71, Vector3(-0.15, 0.0, -0.05)],
	[Vector2(0.7, 0.75), 1.0, 2.4, 0.53, Vector3(0.05, 0.0, -0.12)],
	[Vector2(0.55, 0.55), 0.9, 2.7, 0.13, Vector3(0.0, 0.0, 0.1)],
]
## Eski taşların itildiği halka (m) ve yeni taşların boyu.
const CRACKED_PUSH := 1.05
const STONE_SIZE := Vector2(0.16, 0.2)

var fire: HearthFire
## Tipinin çatlattığı eski taşlar görünsün mü (Ocak başlamadan önceki günlerde de)?
var cracked := true:
	set(value):
		cracked = value
		queue_rebuild()

var _light: OmniLight3D
var _flames: Node3D
var _smoke: MeshInstance3D
var _smoke_size := Vector2.ZERO
var _wisp: MeshInstance3D
var _bursts: Array[GPUParticles3D] = []
var _time := 0.0
var _key := ""


func _ready() -> void:
	name = "HearthView" if name.is_empty() else name
	super._ready()


func bind(p_fire: HearthFire) -> void:
	fire = p_fire
	queue_rebuild()


## Görünüşün kesik anahtarı: taş, odun, yanıyor mu, evre (yuvarlak), eski taşlar.
func look_key() -> String:
	if fire == null:
		return "cold|%s" % cracked
	return "%d|%d|%s|%d|%s" % [fire.stones, fire.wood_laid, fire.lit, int(round(maxf(fire.stage_f, -1.0))), cracked]


## Görünüşün özeti (sınama): {stones, logs, lit, light_range, light_energy, flame_scale, smoke, sparks}.
func look() -> Dictionary:
	var out := {"stones": 0, "cracked": 0, "logs": 0, "lit": _light != null, "light_range": _light.omni_range if _light else 0.0,
		"light_energy": _light.light_energy if _light else 0.0, "flame_scale": _flames.scale.x if _flames else 0.0,
		"smoke": _smoke != null and _smoke.visible, "sparks": 0}
	for c in get_children():
		if not c.has_meta(&"generated"):
			continue
		match str(c.get_meta(&"part", "")):
			"stone":
				out["stones"] = int(out["stones"]) + 1
			"cracked":
				out["cracked"] = int(out["cracked"]) + 1
			"log":
				out["logs"] = int(out["logs"]) + 1
			"sparks":
				out["sparks"] = (c as GPUParticles3D).amount
	return out


## Vuruşun kıvılcım patlaması (tek seferlik): taşların üstünde, ateşin merkezine yakın.
func burst(strength: float = 1.0) -> void:
	var p := Fx.embers(int(round(14.0 * strength)))
	p.name = "StrikeBurst"
	p.one_shot = true
	p.explosiveness = 0.95
	p.lifetime = 0.9
	p.position = Vector3(0.12, 0.32, 0.18)
	add_child(p)
	p.emitting = true
	_bursts.append(p)
	var t := get_tree().create_timer(1.6) if is_inside_tree() else null
	if t:
		t.timeout.connect(func() -> void:
			_bursts.erase(p)
			if is_instance_valid(p):
				p.queue_free())


func _process(delta: float) -> void:
	_time += delta
	if fire == null:
		return
	if look_key() != _key:
		queue_rebuild()
		return
	if _light:
		var now := fire.light_now()
		var f := Campfire.flicker(_time, 3.7)
		_light.omni_range = maxf(float(now["range"]), 0.5)
		_light.light_energy = float(now["energy"]) * f
		_light.position = Vector3(sin(_time * 3.1) * 0.03, 0.65 + (f - 1.0) * 0.15, cos(_time * 2.6) * 0.03)
	if _flames:
		var s := maxf(HearthFire.flame_scale(fire.stage_f), 0.01)
		_flames.scale = Vector3(s, s, s)
	if _smoke and _smoke_size.y > 0.0:
		var want := HearthFire.smoke_size(fire.stage_f)
		var k := want.y / _smoke_size.y
		_smoke.scale = Vector3(k, k, k)
	if _wisp:
		_wisp.visible = fire.smolder > 0.02 and not fire.lit
		_wisp.scale = Vector3.ONE * (0.4 + 0.6 * fire.smolder)


func _build() -> void:
	_key = look_key()
	_light = null
	_flames = null
	_smoke = null
	_wisp = null
	var stones := fire.stones if fire else 0
	var lit := fire != null and fire.lit
	_build_bed(lit)
	if cracked:
		_build_cracked(stones)
	_build_stones(stones)
	if fire and fire.wood_laid > 0:
		_build_wood(fire.wood_laid, maxi(fire.stage, 0) if lit else 0, lit)
	if fire and not lit:
		_build_wisp()
	if lit:
		var sf := fire.stage_f
		_build_embers(sf)
		_build_flames()
		_build_light()
		var n := HearthFire.spark_count(sf)
		if n > 0:
			var sparks := Fx.embers(n)
			sparks.position = Vector3(0.0, 0.25, 0.0)
			_part(sparks, "sparks")
		_smoke_size = HearthFire.smoke_size(float(fire.stage))
		if _smoke_size.y > 0.0:
			_smoke = Fx.smoke(_smoke_size, Vector2(-0.45, -0.12))
			_smoke.position = Vector3(0.0, 0.4, 0.0)
			_part(_smoke, "smoke")


## Kül yatağı ve kömür parçaları: çatlayan ocağın yeri.
func _build_bed(lit: bool) -> void:
	add_mesh(MeshKit.disc(0.55, 0.012, 22), Style.toon(ASH_COLOR if lit else Color(0.34, 0.32, 0.3), {"brush_strength": 0.15}))
	var rng := RandomNumberGenerator.new()
	rng.seed = 921
	var char_mat := Style.toon(CHAR_COLOR)
	for i in 6:
		var a := rng.randf() * TAU
		var r := rng.randf_range(0.08, 0.4)
		var s := rng.randf_range(0.035, 0.06)
		add_mesh(sphere(s, 0.55), char_mat, Transform3D(Basis(Vector3.UP, rng.randf() * TAU), Vector3(cos(a) * r, 0.02, sin(a) * r)))


## Tipinin çatlattığı eski taşlar: üçgenin yerinde ikiye ayrılmış isli taşlar; yeni taş geldikçe o yerin parçaları halkanın dışına itilir.
func _build_cracked(placed: int) -> void:
	var mat := _rock_material(Color(0.34, 0.32, 0.31), 0.7)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5150
	for i in HearthFire.STONE_ANGLES.size():
		var at := HearthFire.stone_offset(i)
		var pushed := i < placed
		var out_dir := at.normalized()
		for half in 2:
			var side := Vector3(-out_dir.z, 0.0, out_dir.x) * (0.07 if half == 0 else -0.07)
			var pos := at + side
			if pushed:
				pos = out_dir * CRACKED_PUSH + side * 2.2 + Vector3(0.0, 0.0, 0.0)
			var s := rng.randf_range(0.11, 0.15)
			var basis := Basis(Vector3.UP, rng.randf() * TAU).rotated(Vector3(out_dir.z, 0.0, -out_dir.x), (0.5 if half == 0 else -0.5))
			var mi := add_mesh(MeshKit.rock(300 + i * 2 + half, 2, 0.35), mat, Transform3D(basis.scaled(Vector3(s, s * 0.7, s)), pos))
			mi.set_meta(&"part", "cracked")


## Üçgen dizilen yeni ocak taşları (derenin açık gri taşı).
func _build_stones(count: int) -> void:
	var mat := _rock_material(Color(0.62, 0.6, 0.57), 0.15)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7311
	for i in count:
		var s := rng.randf_range(STONE_SIZE.x, STONE_SIZE.y)
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * 0.85, s))
		var mi := add_mesh(MeshKit.rock(400 + i, 2, 0.28), mat, Transform3D(basis, HearthFire.stone_offset(i)))
		mi.set_meta(&"part", "stone")


## Odun: konan üç parça çatı gibi yaslanır; her beslenen evre bir parça daha.
func _build_wood(laid: int, fed: int, lit: bool) -> void:
	var wood := Style.toon(Style.WOOD_DARK.darkened(0.15), {"brush_strength": 0.2})
	var charred := Style.toon(Color(0.12, 0.08, 0.07))
	var rng := RandomNumberGenerator.new()
	rng.seed = 79
	var count := laid + fed
	for i in count:
		var a := TAU * float(i) / float(maxi(count, 3)) + 0.3
		var foot := Vector3(cos(a) * 0.34, 0.04, sin(a) * 0.34)
		var top := Vector3(cos(a + 2.4) * 0.05, 0.36 + rng.randf_range(-0.04, 0.06), sin(a + 2.4) * 0.05)
		var mi := add_mesh(capsule(0.045, foot.distance_to(top)), charred if lit and i % 2 == 1 else wood, limb_transform(foot, top))
		mi.set_meta(&"part", "log")


## Kavın tütmesi: ince duman ve sönük kızıllık (vuruşlar arasında).
func _build_wisp() -> void:
	_wisp = Fx.smoke(Vector2(0.35, 1.1), Vector2(-0.2, -0.05))
	_wisp.position = Vector3(0.0, 0.12, 0.0)
	_wisp.visible = false
	_part(_wisp, "wisp")


func _build_embers(sf: float) -> void:
	var energy := lerpf(1.7, 2.4, clampf(sf / 3.0, 0.0, 1.0))
	add_mesh(MeshKit.disc(0.26, 0.035, 20), Style.glow(Color(1.0, 0.38, 0.1), energy))
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var bit := Style.glow(Color(1.0, 0.45, 0.12), energy + 1.2)
	for i in 3:
		var a := rng.randf() * TAU
		var r := rng.randf_range(0.05, 0.2)
		add_mesh(sphere(rng.randf_range(0.03, 0.05), 0.6), bit, Transform3D(Basis.IDENTITY, Vector3(cos(a) * r, 0.05, sin(a) * r)))


func _build_flames() -> void:
	_flames = Node3D.new()
	_flames.name = "Flames"
	add_generated(_flames)
	for layer: Array in LAYERS:
		var size: Vector2 = layer[0]
		var quad := QuadMesh.new()
		quad.size = size
		quad.center_offset = Vector3(0.0, size.y * 0.5, 0.0)
		var mat := ShaderMaterial.new()
		mat.shader = FLAME_SHADER
		mat.set_shader_parameter("energy", layer[1])
		mat.set_shader_parameter("speed", layer[2])
		mat.set_shader_parameter("seed", layer[3])
		var mi := MeshInstance3D.new()
		mi.mesh = quad
		mi.material_override = mat
		mi.position = (layer[4] as Vector3) + Vector3(0.0, 0.02, 0.0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_flames.add_child(mi)
	var s := maxf(HearthFire.flame_scale(fire.stage_f), 0.01)
	_flames.scale = Vector3(s, s, s)


func _build_light() -> void:
	_light = OmniLight3D.new()
	_light.name = "FireLight"
	_light.light_color = LIGHT_COLOR
	var now := fire.light_now()
	_light.light_energy = float(now["energy"])
	_light.omni_range = maxf(float(now["range"]), 0.5)
	# Kamp ateşinin sönümü (Campfire): geniş, yumuşak sıcak halka; menzilin sonunda söner.
	_light.omni_attenuation = 0.45
	_light.shadow_enabled = false
	_light.light_size = 0.25
	_light.light_volumetric_fog_energy = 2.2
	_light.position = Vector3(0.0, 0.65, 0.0)
	_part(_light, "light")


func _rock_material(color: Color, soot: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = ROCK_SHADER
	mat.set_shader_parameter("moss_amount", 0.0)
	mat.set_shader_parameter("rock_color", color)
	mat.set_shader_parameter("rock_shadow", Color(0.26, 0.26, 0.3))
	mat.set_shader_parameter("soot", soot)
	return mat


func _part(node: Node, part: String) -> void:
	node.set_meta(&"part", part)
	add_generated(node)
