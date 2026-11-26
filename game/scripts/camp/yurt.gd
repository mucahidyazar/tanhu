@tool
class_name Yurt
extends Procedural3D
## Keçe kaplı geleneksel yurt.
##
## Kapı yerel +Z yönüne bakar; kapıyı çevirmek için düğümü döndürün.
## Meshy modeli (res://assets/structures/yurt/yurt.glb) varsa o gösterilir: kapıya dik genişliği 2 × radius
## olacak şekilde ölçeklenir. Model yoksa yurt kodla çizilir (yedek görünüm; duvar, çatı ve kapı ayarları ona
## uygulanır).
## İçerideki ocak ve sıcak ışık kapıdan görünür, önündeki zemini aydınlatır; tacından duman yükselir.
## Süsler (kamp referansındaki gibi): kapının yanında asılı işlemeli kumaş (hanging_angle) ve keçeye boyanmış
## koyu damga (emblem_angle).

const FELT_SHADER := preload("res://shaders/felt.gdshader")
const BANNER_SHADER := preload("res://shaders/banner.gdshader")
const FLAME_SHADER := preload("res://shaders/flame.gdshader")
const STONE_SHADER := preload("res://shaders/rock.gdshader")
const DOOR_WIDTH := 0.95
const DOOR_HEIGHT := 1.42
const MODEL_ID := "yurt"
const MODEL_FOLDER := "structures"
## Modelin kapısının +Z'den +X'e doğru açısı (derece). Meshy yurdunun kapısı tam +Z'dedir; model yeniden
## üretilirse bu değer modelin önizlemelerine bakılarak güncellenir.
const MODEL_DOOR_YAW_DEG := 0.0
## Model ölçüleri (assets/_meshy_raw/yurt önizlemeleri ve köşe noktalarından ölçüldü): duvarın yarıçapı
## (radius'a oranla), kapı açıklığının üst kenarı ve süs bandının alt kenarı (model boyuna oranla).
const MODEL_WALL_RATIO := 0.93
const MODEL_DOOR_TOP := 0.5
const MODEL_BAND_BOTTOM := 0.37
## Model zemine bu kadar gömülür: tabanındaki taban düzlemi zeminle titreşmesin.
const MODEL_SINK := 0.03
## Modelin çizim katmanı (11. katman). Kapıdan dışarı sızan spot (DoorSpill) bu katmanı aydınlatmaz: spot
## kapının hemen içinden çıktığı için dışa açılmış kapı kanadını, çerçeveyi ve kapı içindeki tabanı yakından
## fazladan parlatırdı (referansta kapı koyu ahşaptır). Zemin, basamaklar ve kapının önündekiler aydınlanır.
const MODEL_RENDER_LAYER := 1 << 10
## Model dokusunun doygunluğu (atw_textured "saturation"): ateş ışığında keçe şeftali, kapı turuncu görünür;
## referanstaki krem keçe ve koyu ahşap kapıya yaklaşmak için biraz kısılır.
const MODEL_SATURATION := 0.8
## Keçeye boyalı damganın boyu (metre) ve rengi (süs bandıyla aynı koyu kahve).
const EMBLEM_SIZE := 0.8
const EMBLEM_COLOR := Color(0.3, 0.17, 0.1)

@export var radius := 3.0:
	set(value):
		radius = value
		queue_rebuild()
@export var wall_height := 1.7:
	set(value):
		wall_height = value
		queue_rebuild()
@export var roof_height := 1.45:
	set(value):
		roof_height = value
		queue_rebuild()
## Keçe rengi. Modelde dokunun tonunu bu rengin varsayılana (Style.FELT) oranı kadar değiştirir.
@export var felt_color := Style.FELT:
	set(value):
		felt_color = value
		queue_rebuild()
@export var band_color := Style.ORNAMENT_BROWN:
	set(value):
		band_color = value
		queue_rebuild()
@export var door_color := Color(0.8, 0.42, 0.18):
	set(value):
		door_color = value
		queue_rebuild()
@export var interior_light_color := Color(1.0, 0.6, 0.28)
@export var interior_light_energy := 2.4
## Tacından duman yükselsin mi?
@export var has_smoke := true:
	set(value):
		has_smoke = value
		queue_rebuild()
## Kapının yanında duvara asılı işlemeli kumaşın kapıya göre açısı (derece; artı = dışarıdan bakınca kapının
## solu). 0 = kumaş yok.
@export var hanging_angle := 0.0:
	set(value):
		hanging_angle = value
		queue_rebuild()
## Keçeye boyanmış koyu damganın (tamga) kapıya göre açısı (derece). 0 = damga yok.
@export var emblem_angle := 0.0:
	set(value):
		emblem_angle = value
		queue_rebuild()
## Kapı açıklığının en az yüksekliği (metre): 1,82 m boyundaki Mete eğilmeden girebilsin. Meshy modeli bunun için
## dikeyde uzatılır (genişliği 2 × radius kalır); kodla çizilen yedek yurtta kapı ve duvar buna göre yükselir.
@export var min_door_height := 2.05:
	set(value):
		min_door_height = value
		queue_rebuild()

## Otağın içi (geleneksel döşeme, bkz. YurtInterior) kurulsun mu? Ölçüm araçları ve hafif testler kapatır.
@export var build_interior := true:
	set(value):
		build_interior = value
		queue_rebuild()

var crown_height: float:
	get:
		return _fallback_wall_height() - 0.06 + roof_height

var _model: MeshyProp


func _ready() -> void:
	add_to_group(World.OBSTACLE_GROUP)
	super._ready()


## Serbest gezintide içinden geçilemeyen daire: Vector3(x, z, yarıçap).
func get_obstacle_circles() -> Array[Vector3]:
	return [Vector3(global_position.x, global_position.z, radius + 0.25)]


## Meshy modeli gösteriliyor mu (false = kodla çizilen yedek yurt)?
func uses_model() -> bool:
	return _model != null and _model.has_model()


## Keçe rengini modelin dokusuna uygulanacak çarpana çevirir (saf fonksiyon; varsayılan keçe → beyaz).
## Modelin kapısı min_door yüksekliğine yetsin diye gereken dikey uzatma (saf fonksiyon; 1 = uzatma yok).
## model_height: modelin kendi oranıyla boyu (metre). Kapının üst kenarı boyun MODEL_DOOR_TOP oranındadır.
static func door_stretch(model_height: float, min_door: float) -> float:
	var natural := model_height * MODEL_DOOR_TOP
	if natural <= 0.0001:
		return 1.0
	return maxf(1.0, (min_door + MODEL_SINK) / natural)


static func felt_tint(color: Color) -> Color:
	var base := Style.FELT
	return Color(clampf(color.r / base.r, 0.0, 2.0), clampf(color.g / base.g, 0.0, 2.0), clampf(color.b / base.b, 0.0, 2.0))


func _build() -> void:
	_model = null
	if MeshyProp.exists(MODEL_FOLDER, MODEL_ID):
		_build_model()
	var top := crown_height
	if uses_model():
		top = _model.get_model_aabb().end.y
		_build_door_glow()
		_build_hearth()
		_build_steps()
	else:
		_build_shell()
		_build_crown()
		_build_door()
		_build_interior()
	_build_lights()
	if hanging_angle != 0.0:
		_build_hanging()
	if emblem_angle != 0.0:
		_build_emblem()
	if has_smoke:
		var smoke := Fx.smoke()
		smoke.name = "Smoke"
		smoke.position = Vector3(0.0, top + 0.15, 0.0)
		add_generated(smoke)


# --- Meshy modeli ---------------------------------------------------------------------

func _build_model() -> void:
	var prop := MeshyProp.new()
	prop.name = "YurtModel"
	prop.model_id = MODEL_ID
	prop.folder = MODEL_FOLDER
	prop.size_axis = MeshyProp.SizeAxis.WIDTH
	prop.target_size = radius * 2.0
	prop.sink = MODEL_SINK
	prop.double_sided = true
	prop.tint = felt_tint(felt_color)
	prop.ink_strength = 0.3
	prop.render_layers = MODEL_RENDER_LAYER
	prop.set_shader_parameter(&"saturation", MODEL_SATURATION)
	prop.rotation.y = deg_to_rad(-MODEL_DOOR_YAW_DEG)
	add_generated(prop)
	if prop.has_model():
		_model = prop
		prop.vertical_stretch = Yurt.door_stretch(_model_height(), min_door_height)
	else:
		remove_child(prop)
		prop.queue_free()


## Duvarın yarıçapı (metre): modelde keçenin yüzü, yedek yurtta radius.
func _wall_radius() -> float:
	return radius * MODEL_WALL_RATIO if uses_model() else radius


## Kapı açıklığının üst kenarı (metre).
func _door_top() -> float:
	return _model_height() * MODEL_DOOR_TOP - MODEL_SINK if uses_model() else _fallback_door_height()


## Süs bandının alt kenarı (metre): kumaş ve damga bunun altına gelir.
func _band_bottom() -> float:
	return _model_height() * MODEL_BAND_BOTTOM - MODEL_SINK if uses_model() else _fallback_wall_height() * 0.76


func _model_height() -> float:
	return _model.get_model_aabb().size.y


## Yedek yurdun kapı yüksekliği (metre): en az min_door_height.
func _fallback_door_height() -> float:
	return maxf(DOOR_HEIGHT, min_door_height)


## Yedek yurdun duvar yüksekliği (metre): kapının üstünde kiriş için yer kalır.
func _fallback_wall_height() -> float:
	return maxf(wall_height, _fallback_door_height() + 0.3)


## Modelin içi boştur ve kapısı açıktır. Kapıdan bakınca içerisi referanstaki gibi ateşle aydınlanmış görünsün
## diye içeride, ocağın aydınlattığı arka duvarı taklit eden sıcak bir parıltı durur. Duvarların arkasında
## kaldığı için yalnızca kapıdan görünür.
func _build_door_glow() -> void:
	var height := _door_top() * 1.15
	var quad := QuadMesh.new()
	quad.size = Vector2(radius * 0.7, height)
	quad.center_offset = Vector3(0.0, height * 0.5, 0.0)
	var glow := MeshInstance3D.new()
	glow.name = "DoorGlow"
	glow.mesh = quad
	glow.material_override = _door_glow_material()
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	glow.position = Vector3(0.0, 0.0, _wall_radius() - radius * 0.5)
	add_generated(glow)


## Kapının biraz içinde yanan küçük ocak: kor yatağı ve iki boyalı alev (kapıdan görünür).
func _build_hearth() -> void:
	var hearth := Vector3(0.0, 0.02, _wall_radius() - radius * 0.27)
	add_mesh(MeshKit.disc(0.2, 0.0, 14), Style.glow(Color(1.0, 0.4, 0.12), 2.5), Transform3D(Basis.IDENTITY, hearth))
	for i in 2:
		var size := Vector2(0.42, 0.5) * (1.0 - 0.3 * i)
		var flame := QuadMesh.new()
		flame.size = size
		flame.center_offset = Vector3(0.0, size.y * 0.5, 0.0)
		var mat := ShaderMaterial.new()
		mat.shader = FLAME_SHADER
		mat.set_shader_parameter("energy", 1.1 - 0.2 * i)
		mat.set_shader_parameter("speed", 1.6 + 0.5 * i)
		mat.set_shader_parameter("seed", 0.3 + 0.41 * i)
		var mi := add_mesh(flame, mat, Transform3D(Basis.IDENTITY, hearth + Vector3(0.05 * i, 0.0, 0.0)))
		mi.name = "HearthFlame%d" % i
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _door_glow_material() -> StandardMaterial3D:
	# Ocak aşağıda ortada: oradan dışa doğru turuncudan koyu kızıla sönen yumuşak bir ışık lekesi.
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.3, 0.7, 1.0])
	gradient.colors = PackedColorArray([Color(1.0, 0.7, 0.36), Color(0.86, 0.38, 0.12), Color(0.38, 0.12, 0.05), Color(0.15, 0.055, 0.03)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 1.0)
	texture.fill_to = Vector2(0.5, 0.05)
	texture.width = 32
	texture.height = 64
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = texture
	mat.albedo_color = Color(1.15, 1.05, 0.95)
	mat.disable_receive_shadows = true
	return mat


## Kapının önünde iki taş basamak (referanstaki gibi): kapı açıklığından biraz geniş, kalın yontulmuş taşlar;
## alt kısımları toprağa gömülüdür. Renkleri referanstaki gibi sıcak krem taştır (soğuk gri taş ay ışığında
## mavimsi görünür).
func _build_steps() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = STONE_SHADER
	mat.set_shader_parameter("moss_amount", 0.08)
	mat.set_shader_parameter("rock_color", Color(0.66, 0.6, 0.52))
	mat.set_shader_parameter("rock_shadow", Color(0.38, 0.34, 0.32))
	var front := radius * 1.03
	var steps := [[Vector3(0.92, 0.15, 0.36), 0.035, 0.0], [Vector3(0.8, 0.11, 0.32), 0.0, 0.38]]
	for i in steps.size():
		var size: Vector3 = steps[i][0]
		var stone := BoxMesh.new()
		stone.size = size
		var mi := add_mesh(stone, mat, Transform3D(Basis(Vector3.UP, 0.07 * (i * 2 - 1)), Vector3(0.03 * i, steps[i][1], front + float(steps[i][2]))))
		mi.name = "Step%d" % i


# --- Işıklar (model ve yedek görünüm ortak) -------------------------------------------

## İçeriyi aydınlatan kısa menzilli ışık ve kapıdan dışarı sızan, önündeki zemine ışık lekesi düşüren spot.
## Modelde iç ışık alçak ve kısadır: tacın iç yüzünü aydınlatıp kızartmasın.
func _build_lights() -> void:
	var wall_r := _wall_radius()
	# Gölgesiz (ucuz) ve duvarların dışına taşmayan iç ışık.
	var light := OmniLight3D.new()
	light.name = "InteriorLight"
	light.light_color = interior_light_color
	light.light_energy = interior_light_energy
	light.omni_range = wall_r * (0.75 if uses_model() else 0.95)
	light.omni_attenuation = 0.9
	light.light_volumetric_fog_energy = 0.0
	light.position = Vector3(0.0, 0.6 if uses_model() else 1.0, 0.0)
	add_generated(light)
	var spill := SpotLight3D.new()
	spill.name = "DoorSpill"
	spill.light_color = interior_light_color
	spill.light_energy = interior_light_energy * 1.6
	spill.spot_range = 5.5
	spill.spot_angle = 38.0
	spill.spot_angle_attenuation = 1.6
	spill.light_volumetric_fog_energy = 1.5
	spill.light_cull_mask = 0xFFFFFFFF ^ MODEL_RENDER_LAYER
	var origin := Vector3(0.0, minf(_door_top() * 0.8, 1.15), wall_r - 0.6)
	spill.transform = Transform3D(Basis.looking_at(Vector3(0.0, -0.55, 1.0), Vector3.UP), origin)
	add_generated(spill)


# --- Kodla çizilen yedek yurt -----------------------------------------------------------

func _build_shell() -> void:
	# Duvar: kapı için açıklık bırakılmış, hafifçe şişkin silindir.
	var door_angle := PI * 0.5
	var half_gap := (DOOR_WIDTH * 0.5 + 0.03) / radius
	var wall_h := _fallback_wall_height()
	var wall_profile := PackedVector2Array([
		Vector2(radius * 0.985, 0.0),
		Vector2(radius, wall_h * 0.5),
		Vector2(radius * 0.99, wall_h),
	])
	var wall := MeshKit.lathe(wall_profile, 72, 1.0, door_angle + half_gap, door_angle - half_gap + TAU)
	var circumference := TAU * radius
	var band_height := wall_h * 0.17
	var wall_mi := add_mesh(wall, _felt_material(0, circumference / band_height))
	wall_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED

	# Çatı: saçaktan taca hafif dışbükey koni.
	var roof_profile := PackedVector2Array()
	var crown_r := radius * 0.15
	for i in 10:
		var t := float(i) / 9.0
		var r := lerpf(radius * 1.05, crown_r, t)
		var y := wall_h - 0.06 + roof_height * (t + 0.14 * sin(PI * t))
		roof_profile.append(Vector2(r, y))
	var roof := MeshKit.lathe(roof_profile, 72)
	var roof_mi := add_mesh(roof, _felt_material(1, 60.0))
	roof_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED


func _build_crown() -> void:
	var crown_r := radius * 0.15
	var y := crown_height
	var wood := Style.toon(Style.WOOD_DARK)
	add_mesh(torus(crown_r - 0.05, crown_r + 0.06), wood, Transform3D(Basis.IDENTITY, Vector3(0.0, y, 0.0)))
	add_mesh(MeshKit.disc(crown_r - 0.03, y - 0.03, 16), Style.toon(Color(0.08, 0.06, 0.06)))
	for i in 2:
		var bar := box(Vector3(crown_r * 2.0, 0.05, 0.06))
		add_mesh(bar, wood, Transform3D(Basis(Vector3.UP, PI * 0.5 * i), Vector3(0.0, y + 0.02, 0.0)))


func _build_door() -> void:
	var frame_mat := Style.toon(door_color.darkened(0.25), {"stripe_count": 10.0, "stripe_strength": 0.35})
	var leaf_mat := Style.toon(door_color, {"stripe_count": 14.0, "stripe_strength": 0.4, "brush_strength": 0.12})
	var z := radius + 0.02
	var half := DOOR_WIDTH * 0.5
	var door_h := _fallback_door_height()
	for side in [-1.0, 1.0]:
		var post := box(Vector3(0.13, door_h + 0.14, 0.18))
		add_mesh(post, frame_mat, Transform3D(Basis.IDENTITY, Vector3(side * (half + 0.065), (door_h + 0.14) * 0.5, z)))
	add_mesh(box(Vector3(DOOR_WIDTH + 0.4, 0.17, 0.2)), frame_mat, Transform3D(Basis.IDENTITY, Vector3(0.0, door_h + 0.1, z)))
	add_mesh(box(Vector3(DOOR_WIDTH + 0.26, 0.07, 0.22)), frame_mat, Transform3D(Basis.IDENTITY, Vector3(0.0, 0.035, z)))
	# İçe doğru açılmış iki kanat (menteşeler kapı kenarlarında).
	var leaf := box(Vector3(half, door_h - 0.04, 0.05))
	var left_hinge := add_pivot("LeftLeaf", Transform3D(Basis(Vector3.UP, deg_to_rad(72.0)), Vector3(-half, 0.0, z - 0.04)))
	add_mesh(leaf, leaf_mat, Transform3D(Basis.IDENTITY, Vector3(half * 0.5, door_h * 0.5, 0.0)), left_hinge)
	var right_hinge := add_pivot("RightLeaf", Transform3D(Basis(Vector3.UP, deg_to_rad(-48.0)), Vector3(half, 0.0, z - 0.04)))
	add_mesh(leaf, leaf_mat, Transform3D(Basis.IDENTITY, Vector3(-half * 0.5, door_h * 0.5, 0.0)), right_hinge)


func _build_interior() -> void:
	# Zemin halısı ve ortadaki ocak; içerideki ışık kapıdan dışarı sızar.
	add_mesh(MeshKit.disc(radius * 0.96, 0.02, 32), Style.toon(Color(0.45, 0.14, 0.1), {"brush_strength": 0.25}))
	add_mesh(box(Vector3(0.5, 0.42, 0.5)), Style.toon(Style.IRON.darkened(0.3)), Transform3D(Basis.IDENTITY, Vector3(0.0, 0.21, 0.0)))
	add_mesh(box(Vector3(0.36, 0.12, 0.04)), Style.glow(Color(1.0, 0.55, 0.2), 6.0), Transform3D(Basis.IDENTITY, Vector3(0.0, 0.24, 0.26)))


## Keçeye boyanmış damga: duvara dışarıdan yansıtılan bir Decal (duvarın eğrisine ve eğimine kendiliğinden uyar).
func _build_emblem() -> void:
	var dir := _direction_at(emblem_angle)
	var x_axis := Vector3.UP.cross(dir)
	var decal := Decal.new()
	decal.name = "Emblem"
	# Yansıtma yönü Decal'ın -Y eksenidir: +Y duvardan dışarı bakar, dokunun üstü yukarıda kalır.
	decal.size = Vector3(EMBLEM_SIZE, 0.34, EMBLEM_SIZE)
	decal.texture_albedo = Style.tamga_texture()
	decal.modulate = EMBLEM_COLOR
	decal.albedo_mix = 1.0
	decal.normal_fade = 0.3
	decal.upper_fade = 0.1
	decal.lower_fade = 0.1
	var center := Vector3(0.0, _band_bottom() - EMBLEM_SIZE * 0.42, 0.0)
	decal.transform = Transform3D(Basis(x_axis, dir, x_axis.cross(dir)), dir * _wall_radius() + center)
	add_generated(decal)


## Kapıya göre verilen açıdaki (derece) duvar yönü (yerel, birim vektör; 0 = kapı, +Z).
static func _direction_at(angle_deg: float) -> Vector3:
	var angle := PI * 0.5 + deg_to_rad(angle_deg)
	return Vector3(cos(angle), 0.0, sin(angle))


## Duvara asılı krem kumaş: süs bandının hemen altından sarkar, ortasında koyu damga.
func _build_hanging() -> void:
	var dir := _direction_at(hanging_angle)
	var size := Vector2(0.56, 0.74) if uses_model() else Vector2(0.62, 1.0)
	var mat := ShaderMaterial.new()
	mat.shader = BANNER_SHADER
	mat.set_shader_parameter("cloth_color", Color(0.93, 0.89, 0.8))
	mat.set_shader_parameter("emblem_color", Color(0.3, 0.17, 0.1))
	mat.set_shader_parameter("trim_color", Color(0.5, 0.28, 0.15))
	mat.set_shader_parameter("wave_amplitude", 0.012)
	mat.set_shader_parameter("fold_strength", 0.1)
	mat.set_shader_parameter("aspect", size.x / size.y)
	var cloth := MeshKit.cloth(size.x, size.y, 4, 8)
	# Kumaş duvara teğet, yüzü dışa dönük. Modelin duvarı yukarı doğru biraz içe eğik: kumaş alt kenarına göre konur.
	var basis := Basis.looking_at(-dir, Vector3.UP)
	var wall := radius * 0.945 if uses_model() else radius
	add_mesh(cloth, mat, Transform3D(basis, dir * (wall + 0.04) + Vector3(0.0, _band_bottom() - 0.03, 0.0)))


func _felt_material(part: int, motif_count: float) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = FELT_SHADER
	mat.set_shader_parameter("part", part)
	mat.set_shader_parameter("felt_color", felt_color)
	mat.set_shader_parameter("band_color", band_color)
	mat.set_shader_parameter("motif_count", roundf(motif_count))
	mat.set_shader_parameter("light_wrap", 0.5)
	return mat
