extends Node3D
## Çevre stil laboratuvarı: 2. referans görüntüdeki (After the Wind oynanış) gibi yukarıdan 3/4 bir kamerayla
## çimen tutamları, toprak patika, yosunlu somun kayalar ve karakteri gün ışığında gösterir.
## Shader ayarları burada ölçülerek bulunur, sonra bütün dünyaya uygulanır.
##
## Komut satırı: --grade=none (renk derecelendirmesini kapat), --frame=N (karakterin bekleme animasyonunu sabitle).

const GRASS_SHADER := preload("res://shaders/atw_grass.gdshader")
const GROUND_SHADER := preload("res://shaders/atw_ground.gdshader")
const ROCK_SHADER := preload("res://shaders/atw_rock.gdshader")
const CaptureTool := preload("res://scripts/dev/capture.gd")

## Patikalar (x, z noktaları) ve yarı genişlikleri: ana yol sağ üstten gelir, karakterin altında ikiye ayrılır.
const PATHS: Array = [
	[[Vector2(9.0, -9.0), Vector2(5.5, -5.6), Vector2(2.6, -2.8), Vector2(0.6, -0.9), Vector2(0.0, 0.9), Vector2(-0.4, 2.6)], 0.62],
	[[Vector2(-0.4, 2.6), Vector2(-2.6, 3.0), Vector2(-5.5, 3.3), Vector2(-10.0, 3.9)], 0.5],
	[[Vector2(-0.4, 2.6), Vector2(0.5, 4.4), Vector2(1.1, 6.5), Vector2(1.4, 9.0)], 0.52],
]
## Kaya kümeleri: Vector4(x, z, boyut, yön derece). Her küme referanstaki gibi üstte büyük yumurta biçimli
## bir kaya ve önünde/altında dikey bölünmüş 3-4 bloktan oluşur.
const FORMATIONS: Array[Vector4] = [
	Vector4(-6.4, -0.6, 1.25, 20.0), Vector4(-4.0, -1.3, 1.35, -5.0), Vector4(-1.7, -2.0, 1.3, 10.0), Vector4(0.6, -3.2, 1.45, -15.0),
]
const TUFT_SPACING := 0.34
## Tutam çeşitleri: Vector3i(yaprak sayısı, tohum, genişlik × 100).
const VARIANTS: Array[Vector3i] = [Vector3i(11, 5, 75), Vector3i(9, 11, 62), Vector3i(13, 23, 88), Vector3i(10, 37, 70)]
const LAB_RADIUS := 14.0

var _segments: Array[Vector4] = []
var _height_noise: FastNoiseLite
var _widths: Array[float] = []


func _ready() -> void:
	var args := CaptureTool.parse_args(OS.get_cmdline_user_args())
	if str(args.get("grade", "")) != "none":
		ColorGrade.world().apply_to(($WorldEnvironment as WorldEnvironment).environment)
	_collect_segments()
	_build_ground()
	_build_rocks()
	_build_grass()
	var avatar := CharacterAvatar.new()
	avatar.model_override = "mete"
	avatar.position = Vector3(0.3, 0.0, 0.0)
	avatar.rotation.y = deg_to_rad(150.0)
	add_child(avatar)


func _collect_segments() -> void:
	for path in PATHS:
		var points: Array = path[0]
		for i in points.size() - 1:
			var a: Vector2 = points[i]
			var b: Vector2 = points[i + 1]
			_segments.append(Vector4(a.x, a.y, b.x, b.y))
			_widths.append(float(path[1]))


## Noktanın patika kenarına uzaklığı (içeride eksi).
func path_distance(p: Vector2) -> float:
	var best := INF
	for i in _segments.size():
		var s := _segments[i]
		var a := Vector2(s.x, s.y)
		var ab := Vector2(s.z, s.w) - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-6), 0.0, 1.0)
		best = minf(best, p.distance_to(a + ab * t) - _widths[i])
	return best


func _build_ground() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = GROUND_SHADER
	mat.set_shader_parameter("path_segments", PackedVector4Array(_segments))
	mat.set_shader_parameter("path_widths", PackedFloat32Array(_widths))
	mat.set_shader_parameter("path_count", _segments.size())
	var plane := PlaneMesh.new()
	plane.size = Vector2(LAB_RADIUS * 2.6, LAB_RADIUS * 2.6)
	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	ground.mesh = plane
	ground.material_override = mat
	add_child(ground)
	_ground_material = mat


var _ground_material: ShaderMaterial


func _build_rocks() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = ROCK_SHADER
	var top_mat := ShaderMaterial.new()
	top_mat.shader = ROCK_SHADER
	top_mat.set_shader_parameter("moss_base", 0.3)
	for i in FORMATIONS.size():
		var f := FORMATIONS[i]
		var unit := Node3D.new()
		unit.position = Vector3(f.x, 0.0, f.y)
		unit.rotation.y = deg_to_rad(f.w)
		add_child(unit)
		var size := f.z
		# Üstteki büyük, yumurta biçimli kaya.
		_add_rock(unit, AtwKit.loaf_rock(700 + i, 0.6, 2.0, 0.07), top_mat, Vector3(0.0, 0.7 * size, -0.25 * size), Vector3(1.6, 1.75, 1.35) * size)
		# Altında yan yana dikey bloklar (aralarında ince yarıklar).
		var blocks := 4
		for b in blocks:
			var k := (float(b) + 0.5) / float(blocks) * 2.0 - 1.0
			var h := (1.0 - absf(k) * 0.25) * size
			_add_rock(unit, AtwKit.loaf_rock(800 + i * 10 + b, 0.24, 3.4, 0.04), mat,
				Vector3(k * 0.6 * size, -0.05, 0.3 * size + absf(k) * -0.14 * size), Vector3(0.4 * size, h * 0.95, 0.55 * size))
		_rock_circles.append(Vector3(f.x, f.y, 1.05 * size))


var _rock_circles: Array[Vector3] = []


func _add_rock(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3, scale_v: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	mi.scale = scale_v
	parent.add_child(mi)


func _build_grass() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var transforms := []
	var customs := []
	for v in VARIANTS.size():
		transforms.append([])
		customs.append([])
	_height_noise = FastNoiseLite.new()
	_height_noise.seed = 31
	_height_noise.frequency = 0.12
	var steps := int(LAB_RADIUS * 2.0 / TUFT_SPACING)
	for iz in steps:
		for ix in steps:
			var p := Vector2(-LAB_RADIUS + (ix + rng.randf()) * TUFT_SPACING, -LAB_RADIUS + (iz + rng.randf()) * TUFT_SPACING)
			if p.length() > LAB_RADIUS:
				continue
			var edge := path_distance(p)
			if edge < 0.02 or _inside_rock(p):
				continue
			# Patika kenarında tutamlar kısalır ve seyrekleşir; kenara taşanlar yola sarkar.
			var near := smoothstep(0.0, 0.5, edge)
			if rng.randf() > lerpf(0.55, 1.0, near):
				continue
			# Büyük ölçekli gürültü: bazı bölgelerde çimen daha uzun ve gür.
			var tall := _height_noise.get_noise_2d(p.x, p.y) * 0.5 + 0.5
			var h := rng.randf_range(0.5, 0.72) * lerpf(0.8, 1.3, tall) * lerpf(0.7, 1.0, near)
			var w := rng.randf_range(0.85, 1.3)
			var basis := Basis.IDENTITY.scaled(Vector3(w, h, w))
			var v := rng.randi() % VARIANTS.size()
			(transforms[v] as Array).append(Transform3D(basis, Vector3(p.x, -0.01, p.y)))
			(customs[v] as Array).append(Color(rng.randf(), rng.randf(), rng.randf(), 0.0))
	var mat := ShaderMaterial.new()
	mat.shader = GRASS_SHADER
	var count := 0
	for v in VARIANTS.size():
		var spec: Vector3i = VARIANTS[v]
		var xforms: Array[Transform3D] = []
		xforms.assign(transforms[v])
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Grass%d" % v
		mmi.multimesh = Scatter.make_multimesh(AtwKit.tuft(spec.x, spec.y, float(spec.z) / 100.0), xforms, PackedColorArray(customs[v]))
		mmi.material_override = mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mmi)
		count += xforms.size()
	print("[env_lab] tutam: ", count)


func _inside_rock(p: Vector2) -> bool:
	for c in _rock_circles:
		if p.distance_to(Vector2(c.x, c.y)) < c.z:
			return true
	return false
