class_name PrologueProps
extends RefCounted
## Önsöz'ün kodla kurulan eşyaları (E21, K110; krediyle model yok, K89): elde taşınanlar (köz kabı, omuz sırığı ve iki tulum), yolun keçe
## bayraklı kazığı, sabanın ahşap çatısı ve deri saba, at bağı, güreş halkası, kayalar, derenin akan suyu, yolun toprağı (çıkartma), tezek ve
## çalı. Ağlar küçük ve köşe renklidir (Style.toon); bayrak ve dere kendi gölgelendiricileriyle oynar.
##   var pot := PrologueProps.make("ember_pot")     # Held: oyuncunun eline bağlanır (attach_to(player))
##   var stake := PrologueProps.stake(1.55, Color("#a33a22"))
##   var saba := PrologueProps.saba()                # set_churn(k): sopa iner kalkar

const FLAG_SHADER := preload("res://shaders/prologue_flag.gdshader")
const STREAM_SHADER := preload("res://shaders/prologue_stream.gdshader")
const WOOD := Color("#6b4a2e")
const WOOD_DARK := Color("#4a3322")
const LEATHER := Color("#7a4d2c")
const CLAY := Color("#8a4b30")
const FELT_RED := Color("#a33a22")
const FELT_CREAM := Color("#d8c9a4")
const ROPE := Color("#a88a62")
const STONE := Color("#8b8478")
## Köz kabının ışığı: turuncu halka (≈2,5 m; e21-atmosphere.md «Tipi»), sönmez (K1).
const EMBER_COLOR := Color(1.0, 0.55, 0.22)
const EMBER_RANGE := 3.2
const EMBER_ENERGY := 1.9

static var _road_tex: ImageTexture


## Elde taşınan eşya (Held; attach_to(player) ile oyuncunun kemiğine bağlanır). Bilinmeyen kimlik null.
static func make(id: String) -> Node3D:
	match id:
		"ember_pot":
			return PrologueProps._ember_pot()
		"milk_yoke":
			return PrologueProps._milk_yoke()
		"wood":
			return PrologueProps._held_mesh(Procedural3D.cylinder(0.05, 0.06, 0.9, 6), Style.toon(WOOD), "RightHand", Vector3(0, 0.02, 0.06))
		"stone":
			return PrologueProps._held_mesh(MeshKit.rock(77, 1, 0.3), Style.toon(STONE), "RightHand", Vector3(0, 0.0, 0.08), 0.22)
	return null


# --- Elde taşınanlar ---------------------------------------------------------------------------------------

class Held extends Node3D:
	## Oyuncunun kemiğine bağlı eşya: her kare kemiğin küresel duruşunu izler (top_level). Kemik yoksa oyuncunun gövdesinin önünde durur.
	var player: PlayerController
	var bone := "RightHand"
	var offset := Transform3D.IDENTITY
	## Kemik bulunamazsa avatara göre yerel yer.
	var fallback := Vector3(0.18, 0.75, 0.22)
	var _skeleton: Skeleton3D
	var _bone_idx := -1
	## Sallanma (tulumun çalkalanışı): dışarıdan yazılır (0..1).
	var slosh := 0.0
	var _t := 0.0

	func attach_to(p: PlayerController) -> void:
		player = p
		top_level = true
		_find_bone()

	func _find_bone() -> void:
		_skeleton = null
		_bone_idx = -1
		if player == null or player.get_avatar() == null:
			return
		_skeleton = player.get_avatar().get_skeleton()
		if _skeleton:
			_bone_idx = _skeleton.find_bone(bone)
			if _bone_idx < 0:
				for i in _skeleton.get_bone_count():
					if _skeleton.get_bone_name(i).ends_with(bone):
						_bone_idx = i
						break

	func _process(delta: float) -> void:
		if not is_instance_valid(player):
			return
		_t += delta
		if not is_instance_valid(_skeleton) or _bone_idx < 0:
			_find_bone()
		var base: Transform3D
		if is_instance_valid(_skeleton) and _bone_idx >= 0:
			base = _skeleton.global_transform * _skeleton.get_bone_global_pose(_bone_idx)
			base = Transform3D(base.basis.orthonormalized(), base.origin)
		else:
			var av := player.get_avatar()
			base = Transform3D(av.global_transform.basis.orthonormalized(), av.global_transform * fallback)
		global_transform = base * offset
		var sway := get_node_or_null(^"Sway") as Node3D
		if sway:
			sway.rotation.z = sin(_t * 7.0) * 0.06 * (0.3 + slosh)
			sway.rotation.x = sin(_t * 5.3 + 1.1) * 0.05 * (0.3 + slosh)


static func _held_mesh(mesh: Mesh, mat: Material, bone_name: String, at: Vector3, scale_k: float = 1.0) -> Held:
	var h := Held.new()
	h.bone = bone_name
	h.offset = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * scale_k), at)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	h.add_child(mi)
	return h


## Köz kabı: kulplu küçük kil kap, içinde kor; ışığı sıcak ve küçüktür, sönmez (K1). Sağ elde, kulpundan sarkar.
static func _ember_pot() -> Held:
	var h := Held.new()
	h.name = "EmberPot"
	h.bone = "RightHand"
	h.offset = Transform3D(Basis.IDENTITY, Vector3(0.0, -0.1, 0.05))
	var sway := Node3D.new()
	sway.name = "Sway"
	h.add_child(sway)
	var pot := MeshInstance3D.new()
	pot.name = "Pot"
	var profile := PackedVector2Array([Vector2(0.0, -0.2), Vector2(0.07, -0.2), Vector2(0.11, -0.15), Vector2(0.12, -0.08), Vector2(0.1, -0.03),
		Vector2(0.085, -0.02)])
	pot.mesh = MeshKit.lathe(profile, 14)
	pot.material_override = Style.toon(CLAY, {"brush_strength": 0.2})
	pot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sway.add_child(pot)
	var handle := MeshInstance3D.new()
	handle.mesh = Procedural3D.torus(0.085, 0.1)
	handle.material_override = Style.toon(ROPE)
	handle.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	handle.position = Vector3(0.0, -0.01, 0.0)
	handle.scale = Vector3(1.0, 1.0, 0.6)
	sway.add_child(handle)
	var coal := MeshInstance3D.new()
	coal.name = "Coals"
	coal.mesh = MeshKit.disc(0.08, 0.0, 10)
	coal.material_override = Style.glow(Color(1.0, 0.42, 0.12), 3.2)
	coal.position = Vector3(0.0, -0.035, 0.0)
	coal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sway.add_child(coal)
	var light := OmniLight3D.new()
	light.name = "Glow"
	light.light_color = EMBER_COLOR
	light.light_energy = EMBER_ENERGY
	light.omni_range = EMBER_RANGE
	light.omni_attenuation = 1.3
	light.shadow_enabled = false
	light.light_volumetric_fog_energy = 0.6
	light.position = Vector3(0.0, 0.12, 0.0)
	sway.add_child(light)
	return h


## Omuz sırığı ve iki tulum kısrak sütü: sırık ensede, iki ucunda deri tulum sallanır (slosh).
static func _milk_yoke() -> Held:
	var h := Held.new()
	h.name = "MilkYoke"
	h.bone = "Neck"
	h.fallback = Vector3(0.0, 0.95, -0.05)
	h.offset = Transform3D(Basis.IDENTITY, Vector3(0.0, 0.02, -0.07))
	var pole := MeshInstance3D.new()
	pole.name = "Pole"
	pole.mesh = Procedural3D.cylinder(0.022, 0.022, 1.28, 6)
	pole.material_override = Style.toon(WOOD)
	pole.rotation = Vector3(0.0, 0.0, PI * 0.5)
	pole.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	h.add_child(pole)
	var sway := Node3D.new()
	sway.name = "Sway"
	h.add_child(sway)
	for side: float in [-1.0, 1.0]:
		var hang := Node3D.new()
		hang.position = Vector3(0.6 * side, 0.0, 0.0)
		sway.add_child(hang)
		var cord := MeshInstance3D.new()
		cord.mesh = Procedural3D.cylinder(0.006, 0.006, 0.22, 4)
		cord.material_override = Style.toon(ROPE)
		cord.position = Vector3(0.0, -0.11, 0.0)
		hang.add_child(cord)
		var skin := MeshInstance3D.new()
		skin.name = "Skin"
		skin.mesh = Procedural3D.sphere(0.13, 1.35)
		skin.material_override = Style.toon(LEATHER, {"brush_strength": 0.25})
		skin.position = Vector3(0.0, -0.36, 0.0)
		skin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		hang.add_child(skin)
		var neck := MeshInstance3D.new()
		neck.mesh = Procedural3D.cylinder(0.035, 0.05, 0.08, 6)
		neck.material_override = Style.toon(LEATHER.darkened(0.2))
		neck.position = Vector3(0.0, -0.2, 0.0)
		hang.add_child(neck)
	# Dökülen süt: tulumların altından ak damlalar (dökülürken açılır; milk_carry).
	var drops := CPUParticles3D.new()
	drops.name = "Drops"
	drops.emitting = false
	drops.amount = 18
	drops.lifetime = 0.55
	drops.local_coords = false
	drops.mesh = Procedural3D.sphere(0.012, 1.4)
	drops.material_override = Style.toon(Color("#f3efe4"))
	drops.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	drops.emission_box_extents = Vector3(0.62, 0.02, 0.06)
	drops.position = Vector3(0.0, -0.5, 0.0)
	drops.direction = Vector3(0, -1, 0)
	drops.spread = 12.0
	drops.initial_velocity_min = 0.2
	drops.initial_velocity_max = 0.6
	drops.gravity = Vector3(0, -9.8, 0)
	h.add_child(drops)
	return h


# --- Yolun ve obanın eşyası ----------------------------------------------------------------------------------

## Keçe bayraklı kazık: ağaç direk ve tepesine bağlı keçe şerit (prologue_flag.gdshader: rüzgârla dalgalanır, tipide yatay çırpar).
static func stake(height: float, flag_color: Color, seed_value: float = 0.0) -> Node3D:
	var root := Node3D.new()
	root.name = "Stake"
	var post := MeshInstance3D.new()
	post.name = "Post"
	post.mesh = Procedural3D.cylinder(0.04, 0.055, height, 6)
	post.material_override = Style.toon(WOOD_DARK)
	post.position = Vector3(0.0, height * 0.5 - 0.05, 0.0)
	root.add_child(post)
	var flag := MeshInstance3D.new()
	flag.name = "Flag"
	flag.mesh = MeshKit.cloth(0.42, 0.16, 8, 3)
	var mat := ShaderMaterial.new()
	mat.shader = FLAG_SHADER
	mat.set_shader_parameter(&"cloth_color", flag_color)
	mat.set_shader_parameter(&"seed", seed_value)
	flag.material_override = mat
	flag.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flag.position = Vector3(0.0, height - 0.1, 0.0)
	root.add_child(flag)
	return root


## Bayrağın rüzgârı (0: sarkık, 1: tipide yatay çırpar) ve yönü (yerel değil dünya xz).
static func set_flag_wind(stake_node: Node3D, k: float, flow: Vector2) -> void:
	var flag := stake_node.get_node_or_null(^"Flag") as MeshInstance3D
	if flag == null or not flag.material_override is ShaderMaterial:
		return
	var mat := flag.material_override as ShaderMaterial
	mat.set_shader_parameter(&"wind", clampf(k, 0.0, 1.0))
	if flow.length_squared() > 0.0001:
		flag.global_rotation.y = atan2(flow.x, flow.y) - PI * 0.5


## Sabanın ahşap çatısı ve deri saba: dört direk, kiriş ve tahta dam; damın kirişinden asılı şişkin deri saba, içinde dövme sopası
## (set_churn ile iner kalkar). Kök sabanın ortasıdır, ön yüz +Z.
static func saba() -> Node3D:
	var root := Node3D.new()
	root.name = "Saba"
	var wood := Style.toon(WOOD)
	var dark := Style.toon(WOOD_DARK)
	var half := Vector2(1.5, 1.15)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var post := MeshInstance3D.new()
			var h := 2.25 if sz < 0.0 else 1.95
			post.mesh = Procedural3D.cylinder(0.06, 0.07, h, 6)
			post.material_override = dark
			post.position = Vector3(half.x * sx, h * 0.5, half.y * sz)
			root.add_child(post)
	for sz: float in [-1.0, 1.0]:
		var beam := MeshInstance3D.new()
		beam.mesh = Procedural3D.box(Vector3(half.x * 2.0 + 0.3, 0.1, 0.1))
		beam.material_override = wood
		beam.position = Vector3(0.0, 2.25 if sz < 0.0 else 1.95, half.y * sz)
		root.add_child(beam)
	var roof := MeshInstance3D.new()
	roof.name = "Roof"
	roof.mesh = Procedural3D.box(Vector3(half.x * 2.0 + 0.5, 0.06, half.y * 2.0 + 0.6))
	roof.material_override = Style.toon(Color("#7c6040"), {"brush_strength": 0.3})
	roof.rotation = Vector3(-atan2(0.3, half.y * 2.0), 0.0, 0.0)
	roof.position = Vector3(0.0, 2.16, 0.0)
	root.add_child(roof)
	var hang := Node3D.new()
	hang.name = "Hang"
	hang.position = Vector3(0.2, 2.2, -0.2)
	root.add_child(hang)
	var cord := MeshInstance3D.new()
	cord.mesh = Procedural3D.cylinder(0.01, 0.01, 0.5, 4)
	cord.material_override = Style.toon(ROPE)
	cord.position = Vector3(0.0, -0.25, 0.0)
	hang.add_child(cord)
	var bag := MeshInstance3D.new()
	bag.name = "Bag"
	bag.mesh = Procedural3D.sphere(0.36, 1.45)
	bag.material_override = Style.toon(LEATHER.darkened(0.1), {"brush_strength": 0.3})
	bag.position = Vector3(0.0, -0.98, 0.0)
	hang.add_child(bag)
	var stick := MeshInstance3D.new()
	stick.name = "Stick"
	stick.mesh = Procedural3D.cylinder(0.02, 0.025, 1.0, 6)
	stick.material_override = wood
	stick.position = Vector3(0.0, -0.45, 0.0)
	hang.add_child(stick)
	var bench := MeshInstance3D.new()
	bench.mesh = Procedural3D.box(Vector3(0.9, 0.3, 0.35))
	bench.material_override = dark
	bench.position = Vector3(-0.8, 0.15, 0.55)
	root.add_child(bench)
	return root


## Sabanın sopası: k 0 yukarı, 1 aşağı (vuruş).
static func set_churn(saba_node: Node3D, k: float) -> void:
	var stick := saba_node.get_node_or_null(^"Hang/Stick") as Node3D
	var bag := saba_node.get_node_or_null(^"Hang/Bag") as Node3D
	if stick:
		stick.position.y = -0.45 - 0.28 * clampf(k, 0.0, 1.0)
	if bag:
		var s := 1.0 + 0.05 * sin(clampf(k, 0.0, 1.0) * PI)
		bag.scale = Vector3(s, 2.0 - s, s)


## At bağı: iki direk ve aralarında gergin ip (a, b yerel).
static func tether(a: Vector3, b: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "Tether"
	var dark := Style.toon(WOOD_DARK)
	for p: Vector3 in [a, b]:
		var post := MeshInstance3D.new()
		post.mesh = Procedural3D.cylinder(0.06, 0.08, 1.5, 6)
		post.material_override = dark
		post.position = p + Vector3(0.0, 0.7, 0.0)
		root.add_child(post)
	var rope := MeshInstance3D.new()
	rope.mesh = Procedural3D.cylinder(0.012, 0.012, a.distance_to(b), 4)
	rope.material_override = Style.toon(ROPE)
	rope.transform = Procedural3D.limb_transform(a + Vector3(0, 1.3, 0), b + Vector3(0, 1.3, 0))
	root.add_child(rope)
	return root


## Güreş halkası: çiğnenmiş toprak ve çevresinde küçük taşlar (r m).
static func ring(radius: float, ground: Callable) -> Node3D:
	var root := Node3D.new()
	root.name = "WrestleRing"
	var disc := MeshInstance3D.new()
	disc.mesh = MeshKit.disc(radius, 0.015, 28)
	disc.material_override = Style.toon(Color("#7b6447"), {"brush_strength": 0.35})
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(disc)
	var n := 22
	for i in n:
		var a := TAU * float(i) / float(n)
		var p := Vector3(cos(a) * (radius + 0.12), 0.0, sin(a) * (radius + 0.12))
		var stone := MeshInstance3D.new()
		stone.mesh = MeshKit.rock(300 + i, 1, 0.35)
		stone.material_override = Style.toon(STONE.darkened(0.05 * float(i % 3)))
		var s := 0.11 + 0.04 * float(i % 4)
		stone.transform = Transform3D(Basis(Vector3.UP, a).scaled(Vector3(s, s * 0.6, s)), p)
		root.add_child(stone)
	return root


## Kaya (r m yarıçap; tohumlu biçim).
static func rock(radius: float, seed_value: int) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = MeshKit.rock(seed_value, 2, 0.32)
	mi.material_override = Style.toon(STONE.lerp(Color("#6f6a60"), float(seed_value % 5) / 5.0), {"brush_strength": 0.3})
	mi.scale = Vector3(radius, radius * 0.72, radius * 0.9)
	return mi


## Tezek sepeti ve çalı demeti (ocağın yakıtı).
static func fuel(kind: String) -> Node3D:
	var root := Node3D.new()
	root.name = kind.to_pascal_case()
	if kind == "dung":
		var basket := MeshInstance3D.new()
		basket.mesh = Procedural3D.cylinder(0.24, 0.2, 0.26, 10)
		basket.material_override = Style.toon(Color("#8a7048"))
		basket.position = Vector3(0, 0.13, 0)
		root.add_child(basket)
		for i in 4:
			var cake := MeshInstance3D.new()
			cake.mesh = Procedural3D.cylinder(0.09, 0.09, 0.035, 8)
			cake.material_override = Style.toon(Color("#5b4630"))
			cake.position = Vector3(-0.08 + 0.05 * float(i), 0.27 + 0.03 * float(i % 2), 0.04 * float(i % 3 - 1))
			cake.rotation = Vector3(0.3 * float(i % 2), 0.0, 0.2)
			root.add_child(cake)
	else:
		for i in 7:
			var twig := MeshInstance3D.new()
			twig.mesh = Procedural3D.cylinder(0.01, 0.016, 0.7, 4)
			twig.material_override = Style.toon(Color("#6d5636"))
			twig.rotation = Vector3(PI * 0.5 + 0.1 * float(i % 3 - 1), 0.25 * float(i - 3), 0.0)
			twig.position = Vector3(0.0, 0.05 + 0.02 * float(i % 3), 0.0)
			root.add_child(twig)
	return root


## Kurut sergisi: alçak tahta ve üstünde ak kurut topakları.
static func kurut_rack() -> Node3D:
	var root := Node3D.new()
	root.name = "KurutRack"
	var board := MeshInstance3D.new()
	board.mesh = Procedural3D.box(Vector3(1.6, 0.06, 0.7))
	board.material_override = Style.toon(WOOD)
	board.position = Vector3(0, 0.45, 0)
	root.add_child(board)
	for sx: float in [-0.7, 0.7]:
		for sz: float in [-0.28, 0.28]:
			var leg := MeshInstance3D.new()
			leg.mesh = Procedural3D.cylinder(0.025, 0.025, 0.45, 4)
			leg.material_override = Style.toon(WOOD_DARK)
			leg.position = Vector3(sx, 0.22, sz)
			root.add_child(leg)
	for i in 14:
		var k := MeshInstance3D.new()
		k.mesh = Procedural3D.sphere(0.045, 0.8)
		k.material_override = Style.toon(Color("#efe6cf"))
		k.position = Vector3(-0.62 + 0.095 * float(i % 14), 0.5, -0.18 + 0.12 * float(i % 4))
		root.add_child(k)
	return root


# --- Dere ve yol ------------------------------------------------------------------------------------------------

## Derenin akan suyu: çizgi boyunca şerit (genişlik m), zemine oturur (ground(x, z) → y), akış yönü UV'nin v'sidir.
static func stream_mesh(points: PackedVector2Array, width: float, ground: Callable, lift: float = 0.07) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var along := 0.0
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	for i in points.size():
		var p := points[i]
		var dir := (points[mini(i + 1, points.size() - 1)] - points[maxi(i - 1, 0)]).normalized()
		var side := Vector2(-dir.y, dir.x)
		if i > 0:
			along += points[i].distance_to(points[i - 1])
		for s: float in [-1.0, 1.0]:
			var q := p + side * width * 0.5 * s
			verts.append(Vector3(q.x, float(ground.call(q.x, q.y)) + lift, q.y))
			uvs.append(Vector2(0.5 + 0.5 * s, along / width))
	for i in points.size() - 1:
		var a := i * 2
		for idx in [a, a + 2, a + 1, a + 1, a + 2, a + 3]:
			st.set_uv(uvs[idx])
			st.set_normal(Vector3.UP)
			st.add_vertex(verts[idx])
	var mi := MeshInstance3D.new()
	mi.name = "Stream"
	mi.mesh = st.commit()
	var mat := ShaderMaterial.new()
	mat.shader = STREAM_SHADER
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Yolun toprağı: çizgi boyunca çıkartmalar (Decal; arazinin ağına oturur), her biri ≈8 m.
static func road_decals(points: PackedVector2Array, width: float, ground: Callable) -> Node3D:
	var root := Node3D.new()
	root.name = "RoadDecals"
	var tex := PrologueProps.road_texture()
	var seg := 8.0
	var acc := 0.0
	var start := points[0]
	for i in range(1, points.size()):
		acc += points[i].distance_to(points[i - 1])
		if acc < seg and i < points.size() - 1:
			continue
		var a := start
		var b := points[i]
		var mid := (a + b) * 0.5
		var length := a.distance_to(b)
		if length < 0.5:
			continue
		var dec := Decal.new()
		var y := float(ground.call(mid.x, mid.y))
		var ha := float(ground.call(a.x, a.y))
		var hb := float(ground.call(b.x, b.y))
		dec.size = Vector3(width + 1.2, absf(ha - hb) + 6.0, length + 1.4)
		dec.texture_albedo = tex
		dec.modulate = Color(1, 1, 1, 0.92)
		dec.albedo_mix = 1.0
		dec.normal_fade = 0.35
		dec.upper_fade = 0.25
		dec.lower_fade = 0.25
		dec.cull_mask = 1
		dec.position = Vector3(mid.x, (ha + hb) * 0.5, mid.y)
		dec.rotation.y = atan2(b.x - a.x, b.y - a.y)
		root.add_child(dec)
		start = b
		acc = 0.0
	return root


## Yolun dokusu (kodla: yumuşak kenarlı toprak, ortası açık, çakıl benekleri; bir kez).
static func road_texture() -> ImageTexture:
	if _road_tex:
		return _road_tex
	var w := 64
	var h := 128
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.seed = 913
	noise.frequency = 0.09
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	for y in h:
		for x in w:
			var u := (float(x) + 0.5) / float(w) * 2.0 - 1.0
			var n := noise.get_noise_2d(float(x), float(y)) * 0.5 + 0.5
			var edge := 0.7 + 0.22 * n
			var a := 1.0 - smoothstep(edge - 0.25, edge, absf(u))
			var center := 1.0 - absf(u)
			var col := Color("#6f5a42").lerp(Color("#9b8466"), center * 0.7 + n * 0.3)
			if rng.randf() < 0.025:
				col = col.lerp(Color("#c9bfae"), 0.6)
			img.set_pixel(x, y, Color(col.r, col.g, col.b, a * 0.92))
	img.generate_mipmaps()
	_road_tex = ImageTexture.create_from_image(img)
	return _road_tex


## Basma taşı (yassı, suyun üstünde).
static func step_stone(seed_value: int) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = MeshKit.rock(seed_value, 2, 0.25)
	mi.material_override = Style.toon(STONE.lightened(0.05), {"brush_strength": 0.25})
	mi.scale = Vector3(0.36, 0.17, 0.32)
	return mi
