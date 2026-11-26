class_name HearthProps
extends RefCounted
## «Ocak»ın ve şildenin kodla çizilen küçük eşyaları (Önsöz, K110; yeni model yok): kuru kütük ve parçaları, odun demeti, talaş, derenin büyük
## taşı ve ondan çıkan üç ocak taşı, taş kırıntısı, Ağabey'in keçe heybesi, keçe kundak; yer tutucu balta vuruşunun pozu (gövde öne iner).
## Hepsi Style'ın toon gölgelendiricisiyle, gölgesiz değilse tek ağdır (uzak kamerada 20–60 piksel; K98).
##   var log := HearthProps.log_node(0); parent.add_child(log)
##   HearthProps.chips(parent, at)                 # tek seferlik talaş
##   HearthProps.chop_pose(avatar, t)              # t 0..1: vuruşun yer tutucusu

const ROCK_SHADER := preload("res://shaders/rock.gdshader")
const BARK := Color(0.36, 0.3, 0.24)
const HEARTWOOD := Color(0.72, 0.58, 0.4)
const STONE := Color(0.62, 0.6, 0.57)
const FELT := Color(0.58, 0.47, 0.34)
## Yer tutucu vuruşun gövde eğilişi (derece).
const CHOP_DEG := 22.0


## Kuru, kabuğu soyulmuş kütük (yatık): gövde ve iki kırık dal.
static func log_node(seed_value: int) -> Node3D:
	var root := Node3D.new()
	root.name = "DryLog%d" % seed_value
	var rng := RandomNumberGenerator.new()
	rng.seed = 300 + seed_value
	var bark := Style.toon(BARK, {"brush_strength": 0.25})
	var length := rng.randf_range(1.5, 1.9)
	_mesh(root, Procedural3D.capsule(0.13, length), bark, Procedural3D.limb_transform(Vector3(-length * 0.5, 0.13, 0.0), Vector3(length * 0.5, 0.15, 0.0)))
	for k in 2:
		var x := rng.randf_range(-0.5, 0.5)
		_mesh(root, Procedural3D.capsule(0.035, 0.45), bark, Procedural3D.limb_transform(Vector3(x, 0.2, 0.0), Vector3(x + 0.18, 0.55, 0.12 * (1.0 if k == 0 else -1.0))))
	# Kesik uçlar açık renk.
	_mesh(root, MeshKit.disc(0.12, 0.0, 12), Style.toon(HEARTWOOD), Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), Vector3(length * 0.5 + 0.12, 0.15, 0.0)))
	return root


## Kütükten ayrılan parça (kucak odunu): kısa, yarık yüzü açık.
static func piece_node(seed_value: int) -> Node3D:
	var root := Node3D.new()
	root.name = "WoodPiece%d" % seed_value
	var rng := RandomNumberGenerator.new()
	rng.seed = 500 + seed_value
	var length := rng.randf_range(0.5, 0.65)
	_mesh(root, Procedural3D.capsule(0.06, length), Style.toon(BARK.lerp(HEARTWOOD, 0.35), {"brush_strength": 0.2}),
		Procedural3D.limb_transform(Vector3(-length * 0.5, 0.06, 0.0), Vector3(length * 0.5, 0.07, 0.0)))
	return root


## Odun demeti (altı parça, iple bağlı): yere konan ya da kucakta taşınan.
static func bundle_node() -> Node3D:
	var root := Node3D.new()
	root.name = "WoodBundle"
	var wood := Style.toon(BARK.lerp(HEARTWOOD, 0.3), {"brush_strength": 0.2})
	for i in 6:
		var y := 0.07 + float(i / 3) * 0.1
		var z := (float(i % 3) - 1.0) * 0.11 + (0.05 if i >= 3 else 0.0)
		_mesh(root, Procedural3D.capsule(0.055, 0.6), wood, Procedural3D.limb_transform(Vector3(-0.3, y, z), Vector3(0.3, y + 0.01, z)))
	_mesh(root, Procedural3D.torus(0.17, 0.2), Style.toon(Color(0.5, 0.42, 0.3)), Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), Vector3(0.0, 0.12, 0.0)))
	return root


## Talaş (tek seferlik parçacık, 1 sn).
static func chips(parent: Node, at: Vector3) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var p := Fx.embers(10)
	p.name = "Chips"
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.7
	var pm := p.process_material as ParticleProcessMaterial
	if pm:
		pm.gravity = Vector3(0.0, -6.0, 0.0)
		pm.initial_velocity_min = 1.2
		pm.initial_velocity_max = 2.4
		pm.spread = 60.0
		pm.color_ramp = null
		pm.color = Color(0.86, 0.72, 0.5)
	parent.add_child(p)
	p.global_position = at + Vector3(0.0, 0.3, 0.0)
	p.emitting = true
	parent.get_tree().create_timer(1.4).timeout.connect(p.queue_free)


## Taş kırıntısı (tek seferlik).
static func stone_chips(parent: Node, at: Vector3) -> void:
	chips(parent, at)
	var p := parent.get_child(parent.get_child_count() - 1) as GPUParticles3D
	if p and p.process_material is ParticleProcessMaterial:
		(p.process_material as ParticleProcessMaterial).color = Color(0.7, 0.68, 0.64)


## Yer tutucu balta vuruşu (t 0..1): gövde öne iner, sonra doğrulur (gerçek klip onayla gelir: Charged_Axe_Chop 237).
static func chop_pose(avatar: Node3D, t: float) -> void:
	if avatar == null:
		return
	var k := sin(clampf(t, 0.0, 1.0) * PI)
	avatar.rotation.x = deg_to_rad(CHOP_DEG) * k


## Derenin büyük taşı (sığda yarı gömülü).
static func big_stone_node() -> Node3D:
	var root := Node3D.new()
	root.name = "BigStone"
	var mi := _mesh(root, MeshKit.rock(911, 3, 0.25), _rock(STONE.darkened(0.08), 0.05), Transform3D(Basis().scaled(Vector3(0.62, 0.42, 0.55)), Vector3(0.0, 0.05, 0.0)))
	mi.name = "Rock"
	return root


## Ocak taşı (büyük taştan çıkan üç parçadan biri).
static func hearthstone_node(index: int) -> Node3D:
	var root := Node3D.new()
	root.name = "Hearthstone%d" % index
	var s := 0.21 + 0.02 * float(index % 2)
	_mesh(root, MeshKit.rock(400 + index, 2, 0.28), _rock(STONE, 0.0), Transform3D(Basis(Vector3.UP, float(index) * 1.3).scaled(Vector3(s, s * 0.85, s)), Vector3.ZERO))
	return root


## Keçe heybe (Ağabey'in omzunda ya da yerde; taşlar içinde).
static func sack_node() -> Node3D:
	var root := Node3D.new()
	root.name = "FeltSack"
	var mi := _mesh(root, Procedural3D.sphere(0.26, 0.8), Style.toon(FELT, {"brush_strength": 0.3}), Transform3D(Basis().scaled(Vector3(1.0, 0.9, 0.75)), Vector3(0.0, 0.22, 0.0)))
	mi.name = "Bag"
	_mesh(root, Procedural3D.torus(0.08, 0.11), Style.toon(Color(0.42, 0.3, 0.2)), Transform3D(Basis.IDENTITY, Vector3(0.0, 0.42, 0.0)))
	return root


## Keçe kundak (Ana'nın verdiği, Künay'ın bebeğine): sarılı küçük demet.
static func swaddle_node() -> Node3D:
	var root := Node3D.new()
	root.name = "Swaddle"
	_mesh(root, Procedural3D.capsule(0.09, 0.36), Style.toon(Color(0.86, 0.8, 0.7), {"brush_strength": 0.25}),
		Procedural3D.limb_transform(Vector3(-0.18, 0.0, 0.0), Vector3(0.18, 0.0, 0.0)))
	_mesh(root, Procedural3D.torus(0.085, 0.1), Style.toon(Color(0.62, 0.18, 0.12)), Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), Vector3.ZERO))
	return root


## Çocuğun elindeki eşya (koşucunun PrologueProps.Held'i: kemiği her kare izler): node onun çocuğu olur; parent koşucunun köküdür. Önceki
## aynı adlı eşya kaldırılır. Kemik yoksa gövdenin önünde durur.
static func hold(parent: Node, player: PlayerController, node: Node3D, held_name: String, bone: String = "Spine2",
		at: Vector3 = Vector3(0.0, 0.05, 0.22)) -> Node3D:
	if parent == null or player == null:
		return null
	HearthProps.release(parent, held_name)
	var h := PrologueProps.Held.new()
	h.name = held_name
	h.bone = bone
	h.offset = Transform3D(Basis.IDENTITY, at)
	h.fallback = Vector3(0.0, 0.82, 0.26)
	h.add_child(node)
	parent.add_child(h)
	h.attach_to(player)
	return h


static func release(parent: Node, held_name: String) -> void:
	var old := parent.get_node_or_null(NodePath(held_name)) if parent else null
	if old:
		old.queue_free()


## Oyuncunun bir kez oynayan klibi (kütüphanenin anahtarı): oyuncu denetleyicisinin iş rolü (PlayerController.work_role) olarak kurulur;
## karakter dururken oynar, yürüyünce yürüyüş döner (release_player_job). Klip kurulamazsa (iskeletsiz model) false.
static func play_player(player: PlayerController, key: String) -> bool:
	if player == null or key.is_empty() or player.get_avatar() == null or player.get_avatar().get_skeleton() == null:
		return false
	var role := StringName("e21_" + key)
	player.call(&"_add_once_clip", role, key)
	if not player.get_avatar().available_roles().has(role):
		return false
	player.work_role = role
	return true


## Oyuncunun iş rolü bırakılır (yalnız bu adımların kurduğu).
static func release_player_job(player: PlayerController) -> void:
	if player and String(player.work_role).begins_with("e21_"):
		player.work_role = &""


## Oyuncu yürümeye başladıysa iş rolünü bırakır (her kare).
static func release_if_moving(player: PlayerController) -> void:
	if player and String(player.work_role).begins_with("e21_") and player.get_speed() > 0.3:
		player.work_role = &""


static func _rock(color: Color, soot: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = ROCK_SHADER
	mat.set_shader_parameter("moss_amount", 0.0)
	mat.set_shader_parameter("rock_color", color)
	mat.set_shader_parameter("rock_shadow", Color(0.26, 0.26, 0.3))
	mat.set_shader_parameter("soot", soot)
	return mat


static func _mesh(parent: Node3D, mesh: Mesh, mat: Material, xf: Transform3D = Transform3D.IDENTITY) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = xf
	parent.add_child(mi)
	return mi
