class_name BoneView
extends Node3D
## «Ak Kemik»in görünüşü (Çocukluk, 20 Eylül MÖ 228 akşamı; K110): bağlama direği, ak kemik ve ay ışığındaki ışıltısı, oyuncunun atışının
## düşeceği yerin halkası ve ufukta Dailin'e gelen boyların ateşleri. Kurallar BoneRules'ta, kişiler bone_play.gd'dedir.
## Kemik: koyunun incik kemiği gibi kısa ak bir kemik (kodla: gövde ve iki uç topuzu). Ay ışığında uzaktan görünmez; oyuncu yaklaşınca
## (GLINT_FAR'dan içeride, GLINT_NEAR'da tam) ışıldar: kemiğin kendi parıltısı ve üstünde göz kırpan küçük bir ışıltı kartı. Uçuşu bir
## yaydır (from → to, saniyede), düşünce landed yayılır.
## Ateşler sahtedir (gerçek ışık eklenmez; WatchFires'ın kalıbı): alev kartı (flame.gdshader, tek MultiMesh) ve zemine düşen sıcak bir
## halka (tek MultiMesh, toplamalı); Dailin'in kalabalığı iki gün sonra sayıma gelir, boylar ovada konaklar.
##   var view := BoneView.new()
##   root.add_child(view)
##   view.build(shape, post_at, fire_points)
##   view.fly(from, to, 1.6); view.landed.connect(...)
##   view.lie(at) / view.carry(at, yaw) / view.hide_bone()
##   view.tick(delta, player_pos)        # ışıltı ve uçuş

signal landed(at: Vector3)

## Işıltı: oyuncu bu uzaklıkta (m) tam, GLINT_FAR'da söner.
const GLINT_NEAR := 3.5
const GLINT_FAR := 9.0
## Kemiğin boyu (m) ve elde tutulduğu yer (oyuncunun ya da çocuğun önü ve yüksekliği, m).
const BONE_LENGTH := 0.24
const HAND_AHEAD := 0.28
const HAND_SIDE := 0.18
const HAND_HEIGHT := 0.62
## Direğin boyu ve kalınlığı (m).
const POST_HEIGHT := 1.75
const POST_RADIUS := 0.075
## Ateşin alev kartının boyu ve zemindeki halkasının yarıçapı (m).
const FIRE_SIZE := Vector2(1.5, 2.1)
const FIRE_GLOW := 3.2
const FLAME_SHADER := preload("res://shaders/flame.gdshader")

const BONE_SHADER := "shader_type spatial;
render_mode cull_back;
uniform vec3 base : source_color = vec3(0.86, 0.84, 0.78);
uniform float glint = 0.0;
void fragment() {
	ALBEDO = base * mix(0.55, 1.0, glint);
	ROUGHNESS = 0.6;
	EMISSION = vec3(0.75, 0.82, 1.0) * glint * 0.9;
}"
const SPARK_SHADER := "shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform float glint = 0.0;
uniform float seed = 0.0;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float twinkle = 0.65 + 0.35 * sin(TIME * 7.3 + seed) * sin(TIME * 3.1 + seed * 2.0);
	float rays = max(0.0, 1.0 - abs(p.x) * 9.0) * max(0.0, 1.0 - abs(p.y) * 1.1) + max(0.0, 1.0 - abs(p.y) * 9.0) * max(0.0, 1.0 - abs(p.x) * 1.1);
	float core = exp(-r * r * 9.0);
	float a = clamp((core + rays * 0.8) * glint * twinkle, 0.0, 1.0);
	ALBEDO = vec3(0.86, 0.92, 1.0) * a * 1.6;
}"
const GLOW_SHADER := "shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform vec3 tint : source_color = vec3(1.0, 0.45, 0.16);
uniform float energy = 0.55;
varying float vid;
void vertex() {
	vid = float(INSTANCE_ID);
}
void fragment() {
	float r = length(UV * 2.0 - 1.0);
	float flicker = 0.85 + 0.15 * sin(TIME * 9.0 + vid * 1.7) * sin(TIME * 4.3 + vid * 0.6);
	ALBEDO = tint * energy * flicker * pow(max(1.0 - r, 0.0), 2.2);
}"
const RING_SHADER := "shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;
uniform float alpha = 0.0;
void fragment() {
	float r = length(UV * 2.0 - 1.0);
	float ring = smoothstep(0.78, 0.9, r) * (1.0 - smoothstep(0.92, 1.0, r));
	ALBEDO = vec3(0.85, 0.9, 1.0) * ring * alpha;
}"

## Geliştirme: --e21-shots=klasör verilmişse adımlar inceleme karelerini (JPEG) o klasöre yazar, her adı bir kez (shoot).
static var _shots_dir := "?"
static var _shots_taken: Dictionary = {}

## Zeminin yüzü (height_at taşıyan; OrdosGround).
var shape: RefCounted
var post: Node3D
var bone: Node3D
## Kemiğin durumu: hidden, ground, carried, flying.
var state := "hidden"
## Oyuncunun kemiğe uzaklığının ışıltısı (0..1; sınama okur).
var glint := 0.0

var _bone_mat: ShaderMaterial
var _spark: MeshInstance3D
var _spark_mat: ShaderMaterial
var _ring: MeshInstance3D
var _ring_mat: ShaderMaterial
var _flames: MultiMeshInstance3D
var _glows: MultiMeshInstance3D
var _doors: MultiMeshInstance3D
var _fly_from := Vector3.ZERO
var _fly_to := Vector3.ZERO
var _fly_t := 0.0
var _fly_s := 1.0
var _fly_h := 6.0


## Kurulum: direk (post_at; INF ise yok), kemik, ışıltı, halka, ateşler (zemindeki noktalar).
func build(p_shape: RefCounted, post_at: Vector3, fires: Array = []) -> void:
	shape = p_shape
	name = "BoneGame" if name.is_empty() else name
	if post_at != Vector3.INF:
		post = _make_post()
		add_child(post)
		post.global_position = post_at
	bone = _make_bone()
	add_child(bone)
	bone.visible = false
	_spark = _make_quad(Vector2(0.9, 0.9), SPARK_SHADER)
	_spark_mat = _spark.material_override as ShaderMaterial
	_spark_mat.set_shader_parameter(&"seed", 3.7)
	add_child(_spark)
	_spark.visible = false
	_ring = _make_quad(Vector2(2.6, 2.6), RING_SHADER)
	_ring.rotation_degrees.x = -90.0
	_ring_mat = _ring.material_override as ShaderMaterial
	add_child(_ring)
	_ring.visible = false
	if not fires.is_empty():
		_build_fires(fires)


## İnceleme karesi (geliştirme; --e21-shots=klasör): görüntünün o anki karesi <klasör>/<ad>.jpg, her ad bir kez. Argüman yoksa bir şey olmaz.
static func shoot(node: Node, shot: String) -> void:
	if _shots_dir == "?":
		var args: Dictionary = (load("res://scripts/dev/capture.gd") as GDScript).call(&"parse_args", OS.get_cmdline_user_args())
		_shots_dir = str(args.get("e21-shots", "")) if str(args.get("e21-shots", "true")) != "true" else ""
		if not _shots_dir.is_empty():
			DirAccess.make_dir_recursive_absolute(_shots_dir)
	if _shots_dir.is_empty() or _shots_taken.has(shot) or node == null or not node.is_inside_tree() or DisplayServer.get_name() == "headless":
		return
	_shots_taken[shot] = true
	var img := node.get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		return
	var path := _shots_dir.path_join(shot + ".jpg")
	var err := img.save_jpg(path, 0.88)
	# Bütçenin kaba ölçüsü (karenin çizimi; iç harita satırı: çizim 900 / 500, üçgen 3M / 1,5M).
	var vp := node.get_viewport()
	var info := "çizim %d/%d · üçgen %d/%d · %d fps" % [
		vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
		vp.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
		vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),
		vp.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),
		Engine.get_frames_per_second()]
	print("[e21] kare %s (%s) · %s" % [path, error_string(err), info])


## Sahnenin kişi kökü (ChildhoodScene'in «Story» düğümü). Adıyla aranmaz: önceki günün kökü silinmeyi beklerken yeni günün kökü başka ad
## alır («Story2»); kökün kendisi kişilerin üst düğümüdür. Kişi yoksa adıyla, silinmeyi beklemeyen.
static func story_root(p_scene: ChildhoodScene) -> Node3D:
	if p_scene == null:
		return null
	for a: Variant in p_scene.actors.values():
		if is_instance_valid(a) and (a as Node).get_parent() is Node3D and not (a as Node).get_parent().is_queued_for_deletion():
			return (a as Node).get_parent() as Node3D
	if p_scene.world == null:
		return null
	var root := p_scene.world.get_node_or_null(NodePath(ChildhoodScene.ROOT_NAME)) as Node3D
	return root if root and not root.is_queued_for_deletion() else null


## Geliştirme günlüğü (--e21-diag=dosya): satır dosyaya yazılır ve hemen boşaltılır (oyun kapanmadan okunur). Argüman yoksa bir şey olmaz.
static var _diag_path := "?"


static var _diag_at: Dictionary = {}


## Adımın durumu en çok every saniyede bir (geliştirme günlüğü): adım, evre, oyuncunun yeri ve duruşu.
static func diag_step(handler: ChildhoodStep, every: float = 3.0) -> void:
	if _diag_path.is_empty() or handler == null or handler.scene == null:
		return
	var key := str(handler.step.get("id", ""))
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_diag_at.get(key, -INF)) < every:
		return
	_diag_at[key] = now
	var p := handler.player()
	diag("%s %.1f · %s · konum %s · duruş %d · etkin %s · hız %.2f" % [key, handler.clock, handler.phase,
		p.global_position.snapped(Vector3.ONE * 0.1) if p else Vector3.ZERO, p.get_stance() if p else -1, p.is_active() if p else false,
		p.get_speed() if p else 0.0])


static func diag(text: String) -> void:
	if _diag_path == "?":
		var args: Dictionary = (load("res://scripts/dev/capture.gd") as GDScript).call(&"parse_args", OS.get_cmdline_user_args())
		_diag_path = str(args.get("e21-diag", "")) if str(args.get("e21-diag", "true")) != "true" else ""
	if _diag_path.is_empty():
		return
	var f := FileAccess.open(_diag_path, FileAccess.READ_WRITE if FileAccess.file_exists(_diag_path) else FileAccess.WRITE)
	if f == null:
		return
	f.seek_end()
	f.store_line("%s · %s" % [Time.get_time_string_from_system(), text])
	f.flush()


## Işıltının gücü (saf): oyuncu GLINT_NEAR'dan yakınsa 1, GLINT_FAR'dan uzaksa 0.
static func glint_of(distance: float, near: float = GLINT_NEAR, far: float = GLINT_FAR) -> float:
	return 1.0 - smoothstep(near, far, distance)


## Uçuşun yayı (saf): from → to, t (0..1) anında yer; tepe yüksekliği h (m).
static func arc_point(from: Vector3, to: Vector3, t: float, h: float) -> Vector3:
	var p := from.lerp(to, t)
	p.y += 4.0 * h * t * (1.0 - t)
	return p


## Kemik yerde yatar.
func lie(at: Vector3) -> void:
	state = "ground"
	bone.visible = true
	bone.global_position = Vector3(at.x, _height(at.x, at.z) + 0.035, at.z)
	bone.rotation = Vector3(0.0, fposmod(at.x * 1.7 + at.z * 0.9, TAU), PI * 0.5)


## Kemik birinin elinde (yer: kişinin ayağı; yaw: yönü).
func carry(at: Vector3, yaw: float) -> void:
	state = "carried"
	bone.visible = true
	var fwd := Vector3(sin(yaw), 0.0, cos(yaw))
	var side := Vector3(cos(yaw), 0.0, -sin(yaw))
	bone.global_position = at + fwd * HAND_AHEAD - side * HAND_SIDE + Vector3.UP * HAND_HEIGHT
	bone.rotation = Vector3(0.0, yaw, PI * 0.35)


## Kemik uçar: from → to, seconds saniyede, tepe height m. Düşünce lie ve landed.
func fly(from: Vector3, to: Vector3, seconds: float, height: float = -1.0) -> void:
	state = "flying"
	_fly_from = from
	_fly_to = Vector3(to.x, _height(to.x, to.z) + 0.035, to.z)
	_fly_t = 0.0
	_fly_s = maxf(seconds, 0.2)
	_fly_h = height if height > 0.0 else clampf(from.distance_to(to) * 0.22, 3.0, 10.0)
	bone.visible = true
	bone.global_position = from


func hide_bone() -> void:
	state = "hidden"
	bone.visible = false
	_spark.visible = false


## Oyuncunun atışının halkası: at'ta (zeminde), on açıkken görünür; strength 0..1 (atışın gücü: halka parlar).
func show_aim(at: Vector3, on: bool, strength: float = 1.0) -> void:
	_ring.visible = on and at != Vector3.INF
	if _ring.visible:
		_ring.global_position = Vector3(at.x, _height(at.x, at.z) + 0.06, at.z)
		_ring_mat.set_shader_parameter(&"alpha", lerpf(0.35, 0.9, clampf(strength, 0.0, 1.0)))


## Her kare: uçuş ve ışıltı (oyuncunun yeri; uçarken ve elde ışıltı yok).
func tick(delta: float, player_at: Vector3) -> void:
	if state == "flying":
		_fly_t += delta / _fly_s
		var t := minf(_fly_t, 1.0)
		bone.global_position = arc_point(_fly_from, _fly_to, t, _fly_h)
		bone.rotate_object_local(Vector3.FORWARD, delta * 11.0)
		if _fly_t >= 1.0:
			lie(_fly_to)
			landed.emit(_fly_to)
	glint = 0.0
	if state == "ground" and player_at != Vector3.INF:
		glint = glint_of(Vector2(player_at.x - bone.global_position.x, player_at.z - bone.global_position.z).length())
	_bone_mat.set_shader_parameter(&"glint", glint)
	_spark.visible = glint > 0.01
	if _spark.visible:
		_spark.global_position = bone.global_position + Vector3.UP * 0.12
		_spark_mat.set_shader_parameter(&"glint", glint)


## Kemiğin yeri (dünya).
func bone_position() -> Vector3:
	return bone.global_position if bone else Vector3.INF


# --- Kurulum yardımcıları -------------------------------------------------------------------------------------

func _make_post() -> Node3D:
	var root := Node3D.new()
	root.name = "HitchPost"
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.36, 0.27, 0.19)
	wood.roughness = 0.92
	var pole := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = POST_RADIUS * 0.85
	cyl.bottom_radius = POST_RADIUS
	cyl.height = POST_HEIGHT
	cyl.radial_segments = 8
	pole.mesh = cyl
	pole.material_override = wood
	pole.position.y = POST_HEIGHT * 0.5
	root.add_child(pole)
	# Tepedeki topuz ve bağlama halkası (yular buraya bağlanır), at kılından püskül.
	var knob := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = POST_RADIUS * 1.25
	sph.height = POST_RADIUS * 2.0
	sph.radial_segments = 8
	sph.rings = 4
	knob.mesh = sph
	knob.material_override = wood
	knob.position.y = POST_HEIGHT
	root.add_child(knob)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.07
	torus.outer_radius = 0.095
	torus.rings = 10
	torus.ring_segments = 6
	ring.mesh = torus
	var rope := StandardMaterial3D.new()
	rope.albedo_color = Color(0.55, 0.47, 0.36)
	rope.roughness = 1.0
	ring.material_override = rope
	ring.position = Vector3(0.0, POST_HEIGHT * 0.72, 0.0)
	root.add_child(ring)
	var tassel := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.025
	cone.bottom_radius = 0.06
	cone.height = 0.32
	cone.radial_segments = 6
	tassel.mesh = cone
	var hair := StandardMaterial3D.new()
	hair.albedo_color = Color(0.12, 0.1, 0.09)
	hair.roughness = 1.0
	tassel.material_override = hair
	tassel.position = Vector3(0.09, POST_HEIGHT * 0.86, 0.0)
	tassel.rotation_degrees.z = 8.0
	root.add_child(tassel)
	for m in [pole, knob, ring, tassel]:
		(m as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return root


func _make_bone() -> Node3D:
	var root := Node3D.new()
	root.name = "WhiteBone"
	_bone_mat = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = BONE_SHADER
	_bone_mat.shader = sh
	var shaft := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.022
	cap.height = BONE_LENGTH * 0.85
	cap.radial_segments = 8
	cap.rings = 2
	shaft.mesh = cap
	shaft.material_override = _bone_mat
	root.add_child(shaft)
	for end in [-1.0, 1.0]:
		for side in [-1.0, 1.0]:
			var knob := MeshInstance3D.new()
			var sph := SphereMesh.new()
			sph.radius = 0.024
			sph.height = 0.048
			sph.radial_segments = 8
			sph.rings = 4
			knob.mesh = sph
			knob.material_override = _bone_mat
			knob.position = Vector3(side * 0.018, end * BONE_LENGTH * 0.45, 0.0)
			root.add_child(knob)
	for c in root.get_children():
		(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root


func _make_quad(size: Vector2, code: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = size
	mi.mesh = quad
	var mat := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = code
	mat.shader = sh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.top_level = true
	return mi


## Ufuktaki ateşler (bir kez; zemindeki noktalar).
func add_fires(points: Array) -> void:
	if _flames == null and not points.is_empty():
		_build_fires(points)


## Yurtların açık kapısından sızan ateş ışığı (sahte, gerçek ışık yok): kapının önünde zemine düşen sıcak, titrek bir leke (tek MultiMesh).
## points: zemindeki noktalar (kapının hemen önü).
func add_door_glows(points: Array) -> void:
	if _doors != null or points.is_empty():
		return
	var quad := QuadMesh.new()
	quad.size = Vector2(3.2, 3.2)
	quad.orientation = PlaneMesh.FACE_Y
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = quad
	mm.instance_count = points.size()
	for i in points.size():
		var p: Vector3 = points[i]
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(p.x, _height(p.x, p.z) + 0.05, p.z)))
	var mat := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = GLOW_SHADER
	mat.shader = sh
	mat.set_shader_parameter(&"tint", Color(1.0, 0.58, 0.26))
	mat.set_shader_parameter(&"energy", 0.32)
	_doors = MultiMeshInstance3D.new()
	_doors.name = "DoorGlow"
	_doors.multimesh = mm
	_doors.material_override = mat
	_doors.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_doors.top_level = true
	add_child(_doors)


## Ufuktaki ateşler: alev kartları (iki kart bir ateş) ve zemindeki sıcak halkalar, iki çizim.
func _build_fires(points: Array) -> void:
	var flame_mat := ShaderMaterial.new()
	flame_mat.shader = FLAME_SHADER
	flame_mat.set_shader_parameter(&"energy", 3.4)
	flame_mat.set_shader_parameter(&"coverage", 0.35)
	var quad := QuadMesh.new()
	quad.size = FIRE_SIZE
	quad.center_offset = Vector3(0.0, FIRE_SIZE.y * 0.45, 0.0)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = quad
	mm.instance_count = points.size() * 2
	var glow_quad := QuadMesh.new()
	glow_quad.size = Vector2.ONE * FIRE_GLOW * 2.0
	glow_quad.orientation = PlaneMesh.FACE_Y
	var gm := MultiMesh.new()
	gm.transform_format = MultiMesh.TRANSFORM_3D
	gm.mesh = glow_quad
	gm.instance_count = points.size()
	for i in points.size():
		var p: Vector3 = points[i]
		var at := Vector3(p.x, _height(p.x, p.z), p.z)
		for k in 2:
			var s := 1.0 - 0.3 * float(k) + 0.1 * sin(float(i) * 2.3)
			mm.set_instance_transform(i * 2 + k, Transform3D(Basis().scaled(Vector3.ONE * s), at + Vector3(0.15 * float(k), 0.02, -0.12 * float(k))))
		gm.set_instance_transform(i, Transform3D(Basis(), at + Vector3.UP * 0.05))
	_flames = MultiMeshInstance3D.new()
	_flames.name = "DailinFires"
	_flames.multimesh = mm
	_flames.material_override = flame_mat
	_flames.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flames.top_level = true
	add_child(_flames)
	var glow_mat := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = GLOW_SHADER
	glow_mat.shader = sh
	_glows = MultiMeshInstance3D.new()
	_glows.name = "DailinFireGlow"
	_glows.multimesh = gm
	_glows.material_override = glow_mat
	_glows.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_glows.top_level = true
	add_child(_glows)


## Ateş sayısı (sınama).
func fire_count() -> int:
	return _glows.multimesh.instance_count if _glows else 0


func _height(x: float, z: float) -> float:
	return float(shape.call(&"height_at", x, z)) if shape else 0.0
