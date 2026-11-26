class_name Fx
extends RefCounted
## Efekt fabrikası: yurt dumanı (shader ile çizilen duman sütunu), ateş kıvılcımları ve ateş böcekleri (parçacık).
## Hiçbiri doku dosyası gerektirmez; parçacıklar kodla üretilen yumuşak dairesel dokular kullanır.

const SMOKE_SHADER := preload("res://shaders/smoke.gdshader")
## Duman dörtgeninin düğümün altına uzandığı pay (metre): duman tacın içinden çıkıyor gibi görünür.
const SMOKE_SINK := 0.3


## Yurt tacından yükselen ince, yumuşak duman sütunu (4. referanstaki gibi): kameraya dönen tek bir dörtgen
## üzerinde, yukarı akan gürültüyle çizilir (smoke.gdshader). Parçacık değildir, durumu yoktur: yavaş ilk kareler
## ya da takılmalar onu bir topa toplayamaz; maliyeti de çok düşüktür. Düğümün kökü dumanın çıktığı noktadır.
## size: dörtgenin genişliği ve yüksekliği (metre). drift: rüzgârın dumanı tepede sürüklediği yatay uzaklık
## (dünya XZ, metre; eksi x = menü kamerasından bakınca sola).
static func smoke(size: Vector2 = Vector2(1.6, 2.6), drift: Vector2 = Vector2(-0.6, -0.15)) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = size
	quad.center_offset = Vector3(0.0, size.y * 0.5, 0.0)
	var mat := ShaderMaterial.new()
	mat.shader = SMOKE_SHADER
	mat.set_shader_parameter("plume_size", size)
	mat.set_shader_parameter("wind", drift)
	mat.set_shader_parameter("sink", SMOKE_SINK)
	var plume := MeshInstance3D.new()
	plume.mesh = quad
	plume.material_override = mat
	plume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Dörtgen shader'da kameraya döner ve rüzgârla eğilir: kırpma kutusu her yönü kapsasın.
	plume.custom_aabb = smoke_bounds(size, drift)
	return plume


## Duman dörtgeninin her bakış yönünü kapsayan kırpma kutusu (saf fonksiyon; düğümün yerel uzayında).
static func smoke_bounds(size: Vector2, drift: Vector2) -> AABB:
	var reach := size.x * 0.5 + drift.length()
	return AABB(Vector3(-reach, -SMOKE_SINK, -reach), Vector3(reach * 2.0, size.y, reach * 2.0))


## Ateşten yükselen parlak kıvılcımlar.
static func embers(amount: int = 22) -> GPUParticles3D:
	var particles := _base_particles(amount, 2.4, AABB(Vector3(-2.0, -0.5, -2.0), Vector3(4.0, 5.0, 4.0)))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.22
	pm.direction = Vector3.UP
	pm.spread = 22.0
	pm.initial_velocity_min = 0.6
	pm.initial_velocity_max = 1.5
	pm.gravity = Vector3(0.0, 0.25, 0.0)
	pm.scale_min = 0.6
	pm.scale_max = 1.2
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.7
	pm.turbulence_noise_scale = 2.0
	pm.color_ramp = _gradient_texture(
		[0.0, 0.15, 0.7, 1.0],
		[Color(3.0, 1.6, 0.5, 0.0), Color(3.2, 1.5, 0.4, 1.0), Color(2.0, 0.6, 0.15, 0.8), Color(0.8, 0.2, 0.05, 0.0)],
		true)
	particles.process_material = pm
	particles.draw_pass_1 = _billboard_quad(0.045, soft_dot_texture(), true)
	return particles


## Çayırda dolaşan, yanıp sönen ateş böcekleri.
static func fireflies(amount: int, extents: Vector3) -> GPUParticles3D:
	var particles := _base_particles(amount, 7.0, AABB(-extents - Vector3.ONE, (extents + Vector3.ONE) * 2.0))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = extents
	pm.direction = Vector3.UP
	pm.spread = 180.0
	pm.initial_velocity_min = 0.05
	pm.initial_velocity_max = 0.22
	pm.gravity = Vector3.ZERO
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.25
	pm.turbulence_noise_scale = 6.0
	pm.color_ramp = _gradient_texture(
		[0.0, 0.2, 0.35, 0.5, 0.7, 0.85, 1.0],
		[Color(1.6, 2.0, 0.6, 0.0), Color(1.6, 2.0, 0.6, 1.0), Color(1.2, 1.5, 0.45, 0.25), Color(1.7, 2.1, 0.6, 1.0),
			Color(1.3, 1.6, 0.5, 0.3), Color(1.6, 2.0, 0.6, 0.9), Color(1.6, 2.0, 0.6, 0.0)],
		true)
	particles.process_material = pm
	particles.draw_pass_1 = _billboard_quad(0.07, soft_dot_texture(), true)
	return particles


## Ortası dolu, kenarları yumuşakça kaybolan beyaz daire dokusu.
static func soft_dot_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.55), Color(1, 1, 1, 0)])
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.width = 64
	tex.height = 64
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	return tex


# --- İç yardımcılar ---------------------------------------------------------

static func _base_particles(amount: int, lifetime: float, aabb: AABB) -> GPUParticles3D:
	var particles := GPUParticles3D.new()
	particles.amount = amount
	particles.lifetime = lifetime
	particles.preprocess = lifetime
	particles.visibility_aabb = aabb
	particles.draw_order = GPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return particles


static func _billboard_quad(size: float, texture: Texture2D, additive: bool) -> QuadMesh:
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if additive:
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = texture
	mat.disable_receive_shadows = true
	quad.material = mat
	return quad


static func _gradient_texture(offsets: Array, colors: Array, hdr: bool) -> GradientTexture1D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array(offsets)
	gradient.colors = PackedColorArray(colors)
	var tex := GradientTexture1D.new()
	tex.gradient = gradient
	tex.use_hdr = hdr
	return tex
