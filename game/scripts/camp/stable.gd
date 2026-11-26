@tool
class_name Stable
extends Procedural3D
## Ahşap at barınağı: direkler, çatı, saman ve asılı fener; üç yanı kapalı, önü açık (2026-11-07).
## Ön yüz yerel +Z yönüne bakar. Atları sahnede bu düğümün alt düğümü olarak ekleyin.
##
## Meshy modeli (res://assets/structures/stable/stable.glb) varsa o gösterilir: oranı bozulmadan
## width × depth tabanına sığacak en büyük boyda (önü +Z'de, açık). Modelin arkası tahta duvardır; ön bağlama korkuluğu oyun kopyasından
## kesildi (assets/structures/stable/split.json), iki yanı kodla kapanır: yan çitlerin hemen dışında dikey tahtalar, iki kuşak ve arka köşede
## arka duvara bağlanan dönüş (Walls; tek çizim, arka duvarın tahtasıyla aynı renk dili). Çarpışma: arka ve yan duvarlar kutu
## (get_obstacle_boxes), dört köşe direği daire (get_collision_circles); ön ağızdan girilir. Çimen ve patikalar bütün tabandan uzak durur
## (get_obstacle_circles). Model yoksa ahır kodla çizilir (eski çardak; çarpışması tabanın daireleri).

const HORSE_SOUND := "res://audio/sfx/horse_snort.wav"
const MODEL_ID := "stable"
const MODEL_FOLDER := "structures"
## Modeldeki fenerin yeri (model biriminde; ön sol direğe yakın kirişte asılı). Dokudaki parlak sarı
## camın köşe noktalarından ölçüldü.
const MODEL_LANTERN := Vector3(-0.34, 0.075, 0.59)
const LANTERN_COLOR := Color(1.0, 0.62, 0.3)
## Fenerin çevresindeki ışık halesinin çapı (metre): fener camı (~0,25 m) okunacak kadar küçük kalır
## (referanstaki gibi küçük, parlak bir fener; büyük hale fenerin önünde sarı bir top gibi görünür).
const HALO_SIZE := 0.5
## Duvarlar (model biriminde ölçüldü, 2026-11-07): yan çitler x ±0,755'te, duvar hemen dışında; arka duvar z -0,51 (tahtaları -0,59'a dek), arka
## direkler z -0,51, ön direkler (±0,66; z 0,58). Duvarın boyu çatının yan saçağının altında kalır (metre).
const WALL_MODEL_X := 0.80
const WALL_MODEL_Z := Vector2(-0.64, 0.62)
const BACK_MODEL_Z := -0.55
const BACK_EDGE_MODEL_X := 0.68
const POSTS_MODEL: Array[Vector2] = [Vector2(0.654, 0.58), Vector2(-0.666, 0.581), Vector2(0.669, -0.512), Vector2(-0.648, -0.515)]
const POST_RADIUS := 0.17
const WALL_HEIGHT := 1.95
const PLANK_WIDTH := 0.24
const PLANK_GAP := 0.014
const PLANK_THICK := 0.05
## Duvarın kalınlığı çarpışmada (yarı; metre).
const WALL_HALF_THICK := 0.16
## Tahtanın rengi (modelin arka tahtalarının dokusundan: ortalama 0,52 0,31 0,16; toon ışığında biraz koyu).
const PLANK_COLOR := Color(0.44, 0.27, 0.15)

@export var width := 6.0:
	set(value):
		width = value
		queue_rebuild()
## Taban derinliği. Model varsayılan genişlikte kendi oranıyla bu derinliğe sığar.
@export var depth := 4.6:
	set(value):
		depth = value
		queue_rebuild()
@export var post_height := 2.35:
	set(value):
		post_height = value
		queue_rebuild()
@export var lantern_energy := 1.6

var _snort_player: AudioStreamPlayer3D
var _snort_timer := 12.0
var _model: MeshyProp
var _walls: MeshInstance3D


func _ready() -> void:
	add_to_group(World.OBSTACLE_GROUP)
	super._ready()


## Meshy modeli gösteriliyor mu (false = kodla çizilen yedek ahır)?
func uses_model() -> bool:
	return _model != null and _model.has_model()


## Ahırın gerçek taban ölçüsü (metre; x = genişlik, y = derinlik): modelde ölçeklenmiş modelin tabanı.
func get_footprint() -> Vector2:
	if uses_model():
		var box := _model.get_model_aabb()
		return Vector2(box.size.x, box.size.z)
	return Vector2(width, depth)


## Ahırın kapladığı yer (çimen ve patikalar uzak durur): tabanı örten daireler. Modelsiz ahırda çarpışma da budur.
func get_obstacle_circles() -> Array[Vector3]:
	var result: Array[Vector3] = []
	for c in footprint_circles(get_footprint()):
		var p := global_transform * Vector3(c.x, 0.0, c.y)
		result.append(Vector3(p.x, p.z, c.z))
	return result


## Çarpışılan daireler (model varken; World.collect_obstacles bunu tabanın yerine alır): yalnız dört köşe direği, içeri girilir.
func get_collision_circles() -> Array[Vector3]:
	if not uses_model():
		return get_obstacle_circles()
	var result: Array[Vector3] = []
	for post in POSTS_MODEL:
		var p := global_transform * _model.to_parent_space(Vector3(post.x, 0.0, post.y))
		result.append(Vector3(p.x, p.z, POST_RADIUS))
	return result


## Duvarların çarpışması (dünya x, z; model varken): arka duvar ve iki yan duvar. Ön açıktır.
func get_obstacle_boxes() -> Array[ObstacleBox]:
	var result: Array[ObstacleBox] = []
	if not uses_model():
		return result
	for wall in wall_rects():
		var center := Vector3(wall.position.x + wall.size.x * 0.5, 0.0, wall.position.y + wall.size.y * 0.5)
		result.append(ObstacleBox.from_transform(Transform3D(global_basis.orthonormalized(), global_transform * center), wall.size * 0.5))
	return result


## Duvarların yerel dikdörtgenleri (x, z; metre): arka, sol, sağ. Model yoksa boş.
func wall_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	if not uses_model():
		return rects
	var left := _model.to_parent_space(Vector3(-WALL_MODEL_X, 0.0, 0.0)).x
	var right := _model.to_parent_space(Vector3(WALL_MODEL_X, 0.0, 0.0)).x
	var back := _model.to_parent_space(Vector3(0.0, 0.0, BACK_MODEL_Z)).z
	var front := _model.to_parent_space(Vector3(0.0, 0.0, WALL_MODEL_Z.y)).z
	var rear := _model.to_parent_space(Vector3(0.0, 0.0, WALL_MODEL_Z.x)).z
	rects.append(Rect2(left - WALL_HALF_THICK, back - WALL_HALF_THICK, right - left + 2.0 * WALL_HALF_THICK, 2.0 * WALL_HALF_THICK))
	rects.append(Rect2(left - WALL_HALF_THICK, rear, 2.0 * WALL_HALF_THICK, front - rear))
	rects.append(Rect2(right - WALL_HALF_THICK, rear, 2.0 * WALL_HALF_THICK, front - rear))
	return rects


## Dikdörtgen bir tabanı uzun kenarı boyunca dizilmiş dairelerle örter (saf fonksiyon).
## Döner: yerel Vector3(x, z, yarıçap) listesi; köşeler de dairelerin içinde kalır.
static func footprint_circles(size: Vector2) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var along_x := size.x >= size.y
	var long_side := maxf(size.x, size.y)
	var short_side := minf(size.x, size.y)
	if long_side <= 0.0:
		return result
	var count := maxi(1, ceili(long_side / maxf(short_side, 0.01) - 0.01))
	var cell := long_side / float(count)
	var r := sqrt(pow(cell * 0.5, 2.0) + pow(short_side * 0.5, 2.0))
	for i in count:
		var offset := -long_side * 0.5 + cell * (float(i) + 0.5)
		result.append(Vector3(offset, 0.0, r) if along_x else Vector3(0.0, offset, r))
	return result


func _process(delta: float) -> void:
	if _snort_player == null or Engine.is_editor_hint():
		return
	_snort_timer -= delta
	if _snort_timer <= 0.0:
		_snort_timer = randf_range(18.0, 40.0)
		_snort_player.pitch_scale = randf_range(0.92, 1.08)
		_snort_player.play()


func _build() -> void:
	_model = null
	_walls = null
	if MeshyProp.exists(MODEL_FOLDER, MODEL_ID):
		_build_model()
	if uses_model():
		_build_lantern_light(_model.to_parent_space(MODEL_LANTERN), false)
		_build_walls()
	else:
		_build_procedural()
	_build_sound()


## Yan duvarlar (tek ağ): yan çitlerin dışında dikey tahtalar, dış yüzde iki kuşak; arka köşede arka duvara dönen kısa tahta sırası. Tahtanın eni,
## boyu ve eğimi tohumla oynar (her açılışta aynı), rengi tahta başına biraz değişir.
func _build_walls() -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7731
	var left := _model.to_parent_space(Vector3(-WALL_MODEL_X, 0.0, 0.0)).x
	var right := _model.to_parent_space(Vector3(WALL_MODEL_X, 0.0, 0.0)).x
	var rear := _model.to_parent_space(Vector3(0.0, 0.0, WALL_MODEL_Z.x)).z
	var front := _model.to_parent_space(Vector3(0.0, 0.0, WALL_MODEL_Z.y)).z
	var back_z := _model.to_parent_space(Vector3(0.0, 0.0, BACK_MODEL_Z)).z
	var edge_left := _model.to_parent_space(Vector3(-BACK_EDGE_MODEL_X, 0.0, 0.0)).x
	var edge_right := _model.to_parent_space(Vector3(BACK_EDGE_MODEL_X, 0.0, 0.0)).x
	for side in [-1.0, 1.0]:
		var x: float = right if side > 0.0 else left
		# Yan duvar: tahtalar arkadan öne dizilir, yüzleri yana (±X) bakar.
		_add_plank_row(tool, rng, Vector3(x, 0.0, rear), Vector3(x, 0.0, front), Vector3(side, 0.0, 0.0))
		# Arka köşe: arka duvarın kenarından yan duvara.
		var edge: float = edge_right if side > 0.0 else edge_left
		_add_plank_row(tool, rng, Vector3(edge, 0.0, back_z), Vector3(x, 0.0, back_z), Vector3(0.0, 0.0, -1.0))
		# Kuşaklar: dış yüzde iki yatay kalas.
		for y in [0.55, 1.55]:
			_add_box(tool, Vector3(x + side * (PLANK_THICK * 0.5 + 0.035), y, (rear + front) * 0.5), Vector3(0.07, 0.11, front - rear + 0.1), Basis.IDENTITY,
				Color(0.82, 0.8, 0.78))
	tool.generate_tangents()
	var mesh := tool.commit()
	_walls = MeshInstance3D.new()
	_walls.name = "Walls"
	_walls.mesh = mesh
	_walls.material_override = Style.toon(PLANK_COLOR, {"use_vertex_color": true, "brush_strength": 0.22, "brush_scale": 3.0, "stripe_count": 3.0, "stripe_strength": 0.3})
	add_generated(_walls)


## A'dan B'ye bir sıra dikey tahta; outward tahtaların dış yüzü.
func _add_plank_row(tool: SurfaceTool, rng: RandomNumberGenerator, a: Vector3, b: Vector3, outward: Vector3) -> void:
	var length := a.distance_to(b)
	if length < 0.05:
		return
	var along := (b - a) / length
	var count := maxi(1, int(round(length / (PLANK_WIDTH + PLANK_GAP))))
	var width := length / float(count)
	for i in count:
		var w := width - PLANK_GAP + rng.randf_range(-0.02, 0.01)
		var h := WALL_HEIGHT + rng.randf_range(-0.14, 0.06)
		var center := a + along * (width * (float(i) + 0.5)) + Vector3.UP * h * 0.5 + outward * rng.randf_range(-0.008, 0.008)
		# Tahta biraz eğik durur (elle çakılmış).
		var tilt := Basis(outward, rng.randf_range(-0.018, 0.018))
		var basis := Basis(along, Vector3.UP, outward) if absf(outward.x) > 0.5 else Basis(along, Vector3.UP, along.cross(Vector3.UP))
		var tone := rng.randf_range(0.82, 1.12)
		_add_box(tool, center, Vector3(w, h, PLANK_THICK), tilt * basis, Color(tone, tone * rng.randf_range(0.96, 1.02), tone * rng.randf_range(0.94, 1.0)))


## Döndürülmüş kutu (size: yerel x, y, z); UV.y enine (tahtanın damarı boyuna çizgi olur).
func _add_box(tool: SurfaceTool, center: Vector3, size: Vector3, basis: Basis, color: Color) -> void:
	var half := size * 0.5
	var axes := [basis.x.normalized(), basis.y.normalized(), basis.z.normalized()]
	for axis in 3:
		for sign in [-1.0, 1.0]:
			var n: Vector3 = axes[axis] * sign
			var u: Vector3 = axes[(axis + 1) % 3]
			var v: Vector3 = axes[(axis + 2) % 3]
			var hu: float = half[(axis + 1) % 3]
			var hv: float = half[(axis + 2) % 3]
			var c := center + n * half[axis]
			var corners := [c - u * hu - v * hv, c + u * hu - v * hv, c + u * hu + v * hv, c - u * hu + v * hv]
			var uvs := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
			var order := [0, 1, 2, 0, 2, 3] if u.cross(v).dot(n) < 0.0 else [0, 2, 1, 0, 3, 2]
			for k in order:
				tool.set_normal(n)
				tool.set_color(color)
				# Damar tahtanın enine: uzun kenar boyunca çizgi.
				var uv: Vector2 = uvs[k]
				tool.set_uv(Vector2(uv.y, uv.x) if axis == 2 else uv)
				tool.add_vertex(corners[k])


func _build_model() -> void:
	var prop := MeshyProp.new()
	prop.name = "StableModel"
	prop.model_id = MODEL_ID
	prop.folder = MODEL_FOLDER
	prop.fit_box = Vector3(width, 0.0, depth)
	prop.sink = 0.02
	prop.double_sided = true
	prop.ink_strength = 0.3
	# Ahşabın turuncusu ateş ve fener ışığında referanstakinden doygun görünür; biraz kısılır.
	prop.set_shader_parameter(&"saturation", 0.85)
	add_generated(prop)
	if prop.has_model():
		_model = prop
	else:
		remove_child(prop)
		prop.queue_free()


## Fenerin ışığı ve parıltısı. with_body: kodla çizilen fener gövdesi de kurulsun mu (modelde fener zaten var).
func _build_lantern_light(lantern_pos: Vector3, with_body: bool) -> void:
	if with_body:
		var wood_dark := Style.toon(Style.WOOD_DARK, {"brush_strength": 0.16})
		add_mesh(box(Vector3(0.02, 0.4, 0.02)), wood_dark, Transform3D(Basis.IDENTITY, lantern_pos + Vector3(0.0, 0.32, 0.0)))
		add_mesh(box(Vector3(0.2, 0.26, 0.2)), Style.toon(Style.IRON.darkened(0.2)), Transform3D(Basis.IDENTITY, lantern_pos))
		add_mesh(box(Vector3(0.16, 0.2, 0.21)), Style.glow(Color(1.0, 0.7, 0.3), 5.0), Transform3D(Basis.IDENTITY, lantern_pos))
	# Camın çevresinde yumuşak bir ışık halesi (uzaktan da fenerin yandığı okunur).
	var halo := MeshInstance3D.new()
	halo.name = "LanternHalo"
	var quad := QuadMesh.new()
	quad.size = Vector2(HALO_SIZE, HALO_SIZE)
	halo.mesh = quad
	halo.material_override = _halo_material()
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	halo.position = lantern_pos
	add_generated(halo)
	var light := OmniLight3D.new()
	light.name = "LanternLight"
	light.light_color = LANTERN_COLOR
	light.light_energy = lantern_energy
	light.omni_range = 5.5
	light.omni_attenuation = 1.4
	light.light_volumetric_fog_energy = 2.0
	# Modelde ışık fenerin camının içindedir: camın dış yüzü ışığı arkadan alır, birkaç santimetreden aşırı
	# parlayıp gece renk ayarında soluk maviye dönmez (fenerin parıltısını hale verir). Kodla çizilen fenerde
	# ışık, parlayan çekirdeğin hemen önündedir.
	light.position = lantern_pos + (Vector3(0.0, -0.05, 0.15) if with_body else Vector3.ZERO)
	add_generated(light)


static func _halo_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.no_depth_test = false
	mat.disable_receive_shadows = true
	mat.albedo_texture = Fx.soft_dot_texture()
	mat.albedo_color = Color(1.0, 0.66, 0.3, 0.85)
	return mat


func _build_sound() -> void:
	# Önceki kurulumun sesi silindi; ses dosyası yüklenemezse eski (silinmiş) oynatıcı çalınmasın.
	_snort_player = null
	if Engine.is_editor_hint():
		return
	var stream := AudioUtil.load_stream(HORSE_SOUND, false)
	if stream == null:
		return
	_snort_player = AudioStreamPlayer3D.new()
	_snort_player.stream = stream
	_snort_player.bus = AudioUtil.bus_or_master(&"SFX")
	_snort_player.volume_db = -8.0
	_snort_player.unit_size = 2.5
	_snort_player.max_distance = 35.0
	_snort_player.position = Vector3(0.0, 1.5, 0.0)
	add_generated(_snort_player)


# --- Kodla çizilen yedek ahır ------------------------------------------------------------

func _build_procedural() -> void:
	var wood := Style.toon(Style.WOOD, {"brush_strength": 0.16, "stripe_count": 3.0, "stripe_strength": 0.2})
	var wood_dark := Style.toon(Style.WOOD_DARK, {"brush_strength": 0.16})
	var roof_mat := Style.toon(Color(0.36, 0.22, 0.13), {"stripe_count": 18.0, "stripe_strength": 0.45, "brush_strength": 0.2})
	var hw := width * 0.5
	var hd := depth * 0.5

	# Direkler (önde ve arkada üçer tane).
	for x in [-hw, 0.0, hw]:
		for z in [-hd, hd]:
			add_mesh(cylinder(0.085, 0.1, post_height, 10), wood, Transform3D(Basis.IDENTITY, Vector3(x, post_height * 0.5, z)))
	# Üst kirişler.
	for z in [-hd, hd]:
		add_mesh(box(Vector3(width + 0.5, 0.16, 0.16)), wood_dark, Transform3D(Basis.IDENTITY, Vector3(0.0, post_height, z)))
	for x in [-hw, hw]:
		add_mesh(box(Vector3(0.14, 0.14, depth + 0.3)), wood_dark, Transform3D(Basis.IDENTITY, Vector3(x, post_height + 0.05, 0.0)))

	# Kırma çatı: mahyası X ekseni boyunca uzanır, saçaklar taşar.
	var rise := 1.0
	var slope_len := sqrt(pow(hd + 0.55, 2.0) + rise * rise)
	var angle := atan2(rise, hd + 0.55)
	for side in [-1.0, 1.0]:
		var center := Vector3(0.0, post_height + 0.12 + rise * 0.5, side * (hd + 0.55) * 0.5)
		var basis := Basis(Vector3.RIGHT, side * angle)
		add_mesh(box(Vector3(width + 1.0, 0.08, slope_len)), roof_mat, Transform3D(basis, center))
	add_mesh(box(Vector3(width + 1.1, 0.14, 0.18)), wood_dark, Transform3D(Basis.IDENTITY, Vector3(0.0, post_height + 0.14 + rise, 0.0)))
	# Ön saçakta oymalı süs tahtası.
	add_mesh(box(Vector3(width + 0.9, 0.22, 0.05)), Style.toon(Color(0.7, 0.38, 0.17), {"stripe_count": 5.0, "stripe_strength": 0.4}),
		Transform3D(Basis.IDENTITY, Vector3(0.0, post_height - 0.12, hd + 0.1)))

	# Yan ve arka korkuluklar.
	for y in [0.55, 1.05]:
		add_mesh(box(Vector3(width, 0.08, 0.06)), wood, Transform3D(Basis.IDENTITY, Vector3(0.0, y, -hd)))
		for x in [-hw, hw]:
			add_mesh(box(Vector3(0.06, 0.08, depth)), wood, Transform3D(Basis.IDENTITY, Vector3(x, y, 0.0)))
	# Önde, solda kısa bir çit.
	add_mesh(box(Vector3(hw * 0.8, 0.08, 0.06)), wood, Transform3D(Basis.IDENTITY, Vector3(-hw * 0.6, 0.75, hd)))

	# Saman ve yemlik.
	var straw := Style.toon(Style.STRAW, {"brush_strength": 0.3, "brush_scale": 14.0})
	add_mesh(box(Vector3(0.9, 0.5, 0.6)), straw, Transform3D(Basis(Vector3.UP, 0.2), Vector3(-hw + 0.7, 0.25, -hd + 0.45)))
	add_mesh(box(Vector3(0.8, 0.45, 0.55)), straw, Transform3D(Basis(Vector3.UP, -0.15), Vector3(-hw + 0.8, 0.72, -hd + 0.5)))
	add_mesh(sphere(0.55), straw, Transform3D(Basis.IDENTITY.scaled(Vector3(1.4, 0.45, 1.0)), Vector3(hw - 0.9, 0.12, -hd + 0.6)))
	add_mesh(box(Vector3(1.6, 0.35, 0.42)), wood_dark, Transform3D(Basis.IDENTITY, Vector3(0.6, 0.45, -hd + 0.3)))

	# Asılı fener: sıcak ışık ve parlayan çekirdek.
	_build_lantern_light(Vector3(-0.9, post_height - 0.55, hd + 0.05), true)
