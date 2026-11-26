class_name SkyEagle
extends Node3D
## Gökteki altın kartal (fauna.md §5.2 «Yaban kartal», survival.md §4.1; K65): gerçek irtifada (70–110 m) geniş halkalarla süzülür, kadrajda yalnız
## gölgesi ve sesi vardır (K98'in tepeden kadrajı gökyüzünü göstermez). Kodla çizilir (FaunaMesh.eagle; küçük av gölgelendiricisi, çırpma seyrek),
## gölgesi zemine düşen yumuşak bir çıkartmadır (Decal; gerçek gölge 80 m yükseklikte gölge haritasının dışında kalır). Av değildir (I. Perde),
## hiçbir işe yardım etmez, Kut'a bağlanmaz (K65: Tanhu 1'in «kartal Tengri'nindir» deseni alınmaz). Gündüz uçar (survival.md §4.3: 0, 2, 3, 3, 1, 0),
## sev ≥3'te uçmaz. Kuş sayısına girer (≤64). Ara sıra öter: called(at) sinyali FaunaVoices'a gider (eagle_call; ince ve kısa).
##   var sky := SkyEagle.new()
##   sky.setup({"center": [770, -490], "radius": [70, 130], "height": [70, 110], "count": 2, "seed": 5}, world.ground)

signal called(at: Vector3)

const SHADER := preload("res://shaders/small_game.gdshader")
## Süzülme hızı (m/sn; kinds.json eagle.speed.flight) ve ötme aralığı (sn).
const CALL_EVERY := Vector2(50.0, 140.0)
## Gölgenin boyu (m; kanat açıklığı ≈2,1 m) ve koyuluğu.
const SHADOW_SIZE := Vector2(2.6, 1.5)
const SHADOW_ALPHA := 0.42

var kind: FaunaKind
var ground: TerrainShape
var center := Vector2.ZERO
var radius := Vector2(70.0, 130.0)
var height := Vector2(70.0, 110.0)
## Uçuyor mu (evre, hava)?
var flying := true

var _birds: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _mesh: Mesh
var _material: ShaderMaterial
var _shadow_tex: Texture2D
var _call_left := 0.0


func setup(def: Dictionary, shape: TerrainShape) -> void:
	kind = FaunaKind.named("eagle")
	ground = shape
	center = FaunaDirector._vec2(def.get("center", [0.0, 0.0]))
	var r: Variant = def.get("radius", [70.0, 130.0])
	radius = Vector2(float(r[0]), float(r[1])) if r is Array else Vector2(float(r), float(r))
	var h: Variant = def.get("height", [70.0, 110.0])
	height = Vector2(float(h[0]), float(h[1])) if h is Array else Vector2(float(h), float(h))
	_rng.seed = int(def.get("seed", 5))
	_call_left = _rng.randf_range(CALL_EVERY.x * 0.3, CALL_EVERY.y * 0.5)
	_mesh = FaunaMesh.mesh_for("eagle")
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	for key: String in FaunaMesh.shader_params("eagle"):
		_material.set_shader_parameter(key, FaunaMesh.shader_params("eagle")[key])
	_material.set_shader_parameter(&"flap_rate", float(kind.game_value("flap_rate", 4.0)) if kind else 4.0)
	_shadow_tex = _make_shadow()
	for k in int(def.get("count", 2)):
		_add_bird(k)


func bird_count() -> int:
	return _birds.size()


## Kuşların dünyadaki yerleri (ses ve sınama).
func positions() -> PackedVector3Array:
	var out := PackedVector3Array()
	for b in _birds:
		out.append((b["node"] as Node3D).global_position)
	return out


func shadow_positions() -> PackedVector3Array:
	var out := PackedVector3Array()
	for b in _birds:
		out.append((b["shadow"] as Node3D).global_position)
	return out


func _process(delta: float) -> void:
	for b in _birds:
		_fly(b, delta)
	if not flying:
		return
	_call_left -= delta
	if _call_left <= 0.0 and not _birds.is_empty():
		_call_left = _rng.randf_range(CALL_EVERY.x, CALL_EVERY.y)
		called.emit((_birds[_rng.randi() % _birds.size()]["node"] as Node3D).global_position)


func _fly(b: Dictionary, delta: float) -> void:
	var node: Node3D = b["node"]
	var shadow: Decal = b["shadow"]
	node.visible = flying
	shadow.visible = flying
	if not flying:
		return
	var speed := kind.speed("flight", 12.0) if kind else 12.0
	var r := float(b["r"])
	b["a"] = fposmod(float(b["a"]) + float(b["dir"]) * speed / r * delta, TAU)
	# Halkanın merkezi ağır ağır gezinir; yarıçap ve yükseklik yavaşça değişir (termik).
	b["t"] = float(b["t"]) + delta
	var t := float(b["t"])
	var c := center + Vector2(sin(t * 0.013 + float(b["ph"])), cos(t * 0.011 + float(b["ph"]))) * radius.x * 0.6
	r = lerpf(radius.x, radius.y, 0.5 + 0.5 * sin(t * 0.021 + float(b["ph"]) * 2.0))
	b["r"] = r
	var a := float(b["a"])
	var p := c + Vector2(cos(a), sin(a)) * r
	var gy := ground.height_at(p.x, p.y) if ground else 0.0
	var alt := lerpf(height.x, height.y, 0.5 + 0.5 * sin(t * 0.017 + float(b["ph"])))
	var tangent := Vector2(-sin(a), cos(a)) * float(b["dir"])
	var yaw := atan2(tangent.x, tangent.y)
	node.global_position = Vector3(p.x, gy + alt, p.y)
	# Halkanın içine doğru yatar.
	node.basis = Basis(Vector3.UP, yaw) * Basis(Vector3.BACK, -0.32 * float(b["dir"]))
	shadow.global_position = Vector3(p.x, gy + 4.0, p.y)
	shadow.rotation = Vector3(0.0, yaw, 0.0)


func _add_bird(k: int) -> void:
	var node := MeshInstance3D.new()
	node.name = "Eagle_%d" % k
	node.mesh = _mesh
	node.material_override = _material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.scale = Vector3.ONE * (kind.draw_scale if kind else 1.0)
	node.set_instance_shader_parameter(&"pose", Vector4(1.0, 0.0, 0.0, _rng.randf()))
	add_child(node)
	var shadow := Decal.new()
	shadow.name = "Shadow_%d" % k
	shadow.size = Vector3(SHADOW_SIZE.x, 12.0, SHADOW_SIZE.y)
	shadow.texture_albedo = _shadow_tex
	shadow.modulate = Color(0.0, 0.0, 0.0, SHADOW_ALPHA)
	shadow.upper_fade = 0.2
	shadow.lower_fade = 0.2
	shadow.cull_mask = 1
	add_child(shadow)
	_birds.append({"node": node, "shadow": shadow, "a": _rng.randf() * TAU, "r": lerpf(radius.x, radius.y, _rng.randf()),
		"dir": 1.0 if k % 2 == 0 else -1.0, "t": _rng.randf() * 100.0, "ph": _rng.randf() * TAU})


## Kanatlı yumuşak gölge: yatay uzun, ortası koyu elips (GradientTexture2D, radyal).
func _make_shadow() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	g.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	g.add_point(0.55, Color(1.0, 1.0, 1.0, 0.55))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	tex.width = 64
	tex.height = 64
	return tex
