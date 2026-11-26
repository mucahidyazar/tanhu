@tool
class_name MeshyProp
extends Node3D
## Meshy ile üretilmiş bir modeli (res://assets/<folder>/<id>/<id>.glb) sahneye koyar:
##   - gerçek boyuna ölçekler (target_size: yükseklik, en büyük kenar, taban çapı, genişlik ya da derinlik;
##     ya da fit_box ile verilen kutuya sığacak en büyük boy),
##   - tabanını bu düğümün yerine (y = 0) oturtur, yatayda ortalar ve isteğe bağlı olarak biraz gömer (sink),
##   - modelin boyalı dokusunu "After the Wind" dokulu malzemesiyle (atw_textured) gösterir.
## Model dosyası yoksa hiçbir şey göstermez: has_model() false döner, çağıran eski (prosedürel) görünümü kullanır.
##
## Meshy modelleri glTF düzenindedir: ön yüz +Z'ye bakar (yurdun kapısı, atın başı, ahırın açık önü).
## Aynı model ve ayarlarla oluşturulan kopyalar malzemeyi paylaşır (kesitli modeller hariç, bkz. cutaway).

const SHADER := preload("res://shaders/atw_textured.gdshader")
const DOUBLE_SHADER := preload("res://shaders/atw_textured_double.gdshader")
const CUT_SHADER := preload("res://shaders/atw_textured_cutaway.gdshader")
## Kesitli modelin yalnızca gölge veren kopyalarının işareti (meta).
const SHADOW_PROXY_META := &"shadow_proxy"
const OBSTACLE_GROUP := &"obstacles"

## size_axis değerleri: target_size hangi ölçüye uygulanır.
enum SizeAxis { HEIGHT, LONGEST, FOOTPRINT, WIDTH, DEPTH }

## Model kimliği ve klasörü (ör. "yurt" + "structures" → res://assets/structures/yurt/yurt.glb).
@export var model_id := "":
	set(value):
		model_id = value
		_queue_rebuild()
@export var folder := "props":
	set(value):
		folder = value
		_queue_rebuild()
## Hedef boyut (metre) ve hangi ölçüye uygulandığı.
@export var target_size := 1.0:
	set(value):
		target_size = value
		_queue_rebuild()
@export_enum("Yükseklik", "En büyük kenar", "Taban çapı", "Genişlik (X)", "Derinlik (Z)") var size_axis := 0:
	set(value):
		size_axis = value
		_queue_rebuild()
## Sığdırma kutusu (metre; genişlik, yükseklik, derinlik). Sıfırdan büyük bir bileşen varsa target_size yerine
## modelin bu kutuya (oranı bozulmadan) sığacağı en büyük boy kullanılır; 0 olan bileşen sınır koymaz.
@export var fit_box := Vector3.ZERO:
	set(value):
		fit_box = value
		_queue_rebuild()
## Modeli zemine bu kadar gömer (metre): taban düzlemi zeminle titreşmez (z-fighting), taşlar ve toynaklar
## zemine oturur. Birkaç santimetre yeter.
@export_range(0.0, 0.5, 0.005) var sink := 0.0:
	set(value):
		sink = value
		_queue_rebuild()
## Dikey uzatma: model sığdırıldıktan sonra yalnızca boyu bu oranda büyütülür (ör. yurdun kapısı insan boyuna
## yetsin diye); genişlik ve taban yerinde kalır. 1 = modelin kendi oranı. Model kuruluysa hemen uygulanır.
@export_range(0.5, 2.0, 0.01) var vertical_stretch := 1.0:
	set(value):
		vertical_stretch = maxf(value, 0.01)
		_apply_fit()
## İki yüzlü çizim: içi görünen (yurt kapısından iç duvar, kovanın içi) ya da ince yüzeyli modeller için.
@export var double_sided := false:
	set(value):
		double_sided = value
		_queue_rebuild()
## Doku rengi çarpanı (ör. aynı modelin ikinci kopyası biraz daha sıcak).
@export var tint := Color(1, 1, 1):
	set(value):
		tint = value
		_queue_rebuild()
## Kenarlardaki ince mürekkep koyulaşması (0 = yok).
@export_range(0.0, 1.0) var ink_strength := 0.25:
	set(value):
		ink_strength = value
		_queue_rebuild()
## Dokunun üstüne binen düşük frekanslı fırça lekeleri (0 = yok).
@export_range(0.0, 0.3) var brush_strength := 0.05:
	set(value):
		brush_strength = value
		_queue_rebuild()
@export var cast_shadows := true:
	set(value):
		cast_shadows = value
		_queue_rebuild()
## Otağ kesiti (bkz. shaders/include/cutaway.gdshaderinc): görünen meshler iki yüzlü, kesitli ve örneğe özel
## (paylaşılmayan) malzemeyle çizilir ve gölge vermez; gölgeyi aynı meshlerin kesilmeyen, yalnızca gölge veren
## kopyaları verir. Böylece kesit açıkken de model ay ışığını keser. Kesit parametreleri get_materials() ile verilir.
@export var cutaway := false:
	set(value):
		cutaway = value
		_queue_rebuild()
## Modelin çizim katmanları (VisualInstance3D.layers). Bir ışığın light_cull_mask'i bu katmanları dışarıda
## bırakırsa ışık modeli aydınlatmaz (ör. yurdun kapı ışığı kendi kapı kanadını parlatmasın).
@export_flags_3d_render var render_layers := 1:
	set(value):
		render_layers = value
		if _model:
			_apply_instance_settings(_model)
## true ise serbest gezintide engel olur (World.OBSTACLE_GROUP); yarıçap = taban yarıçapı × obstacle_scale.
@export var register_obstacle := false
@export var obstacle_scale := 0.85

var _model: Node3D
var _footprint_radius := 0.0
## Ölçeklenmiş ve yerleştirilmiş modelin bu düğümün yerel uzayındaki sınır kutusu.
var _bounds := AABB()
var _scale := 1.0
## Modelin kendi (ölçeksiz) sınır kutusu; ölçek ve uzatma buna uygulanır.
var _raw_box := AABB()
var _rebuild_pending := false
## Malzemelere ayrıca verilen shader parametreleri (ör. atın baş sallama ayarları).
var _extra_params := {}

## Aynı doku ve ayarlarla istenen malzemeler paylaşılır (anahtar → ShaderMaterial).
static var _material_cache := {}
## Geliştirme ve testler için genel anahtar: false iken hiçbir model yüklenmez, her nesne kodla çizilen
## yedek görünümüne döner (model dosyaları eksikmiş gibi).
static var models_enabled := true


func _ready() -> void:
	if register_obstacle:
		add_to_group(OBSTACLE_GROUP)
	_rebuild()


## Model dosyasının yolu (saf fonksiyon).
static func model_path(p_folder: String, id: String) -> String:
	return "res://assets/%s/%s/%s.glb" % [p_folder, id, id]


## Bu klasörde bu kimlikle oyuna hazırlanmış bir model var mı?
static func exists(p_folder: String, id: String) -> bool:
	return models_enabled and not id.is_empty() and ResourceLoader.exists(model_path(p_folder, id))


## AABB'yi hedef boya getiren ölçek (saf fonksiyon). axis: SizeAxis (0 yükseklik, 1 en büyük kenar,
## 2 taban çapı, 3 genişlik X, 4 derinlik Z).
static func fit_scale(box: AABB, target: float, axis: int) -> float:
	var measure := axis_measure(box.size, axis)
	return target / measure if measure > 0.0001 else 1.0


## Bir boyutun seçilen eksendeki ölçüsü (saf fonksiyon).
static func axis_measure(size: Vector3, axis: int) -> float:
	match axis:
		SizeAxis.LONGEST:
			return maxf(size.x, maxf(size.y, size.z))
		SizeAxis.FOOTPRINT:
			return maxf(size.x, size.z)
		SizeAxis.WIDTH:
			return size.x
		SizeAxis.DEPTH:
			return size.z
	return size.y


## AABB'yi oranını bozmadan bounds kutusuna sığdıran en büyük ölçek (saf fonksiyon).
## bounds'un 0 (ya da eksi) bileşenleri sınır koymaz; hiç sınır yoksa 1 döner.
static func fit_inside(box: AABB, bounds: Vector3) -> float:
	var best := INF
	for i in 3:
		if bounds[i] > 0.0 and box.size[i] > 0.0001:
			best = minf(best, bounds[i] / box.size[i])
	return best if best < INF else 1.0


## Ölçeklenmiş modelin tabanının ortasını düğümün yerine getiren kaydırma (saf fonksiyon).
static func placement_offset(box: AABB, s: float, p_sink: float) -> Vector3:
	var center := box.get_center()
	return -Vector3(center.x, box.position.y, center.z) * s - Vector3(0.0, p_sink, 0.0)


func has_model() -> bool:
	return _model != null


## Ölçeklenmiş modelin taban yarıçapı (metre; x/z kenarlarının yarısının ortalaması).
func get_footprint_radius() -> float:
	return _footprint_radius


## Ölçeklenmiş ve yerleştirilmiş modelin bu düğümün yerel uzayındaki sınır kutusu (model yoksa boş).
func get_model_aabb() -> AABB:
	return _bounds


## Modele uygulanan ölçek (metre / model birimi; model yoksa 1).
func get_model_scale() -> float:
	return _scale


## Model uzayındaki (Meshy birimi) bir noktanın bu düğümün yerel uzayındaki yeri.
func model_to_local(p: Vector3) -> Vector3:
	return _model.transform * p if _model else p


## Model uzayındaki bir noktanın ebeveyn düğüme göre yeri (ör. ahırdaki fenerin ahıra göre konumu).
func to_parent_space(p: Vector3) -> Vector3:
	return transform * model_to_local(p)


## Serbest gezinti engel dairesi: Vector3(x, z, yarıçap).
func get_obstacle_circles() -> Array[Vector3]:
	var result: Array[Vector3] = []
	if register_obstacle and _model and _footprint_radius > 0.0:
		var p := global_position
		result.append(Vector3(p.x, p.z, _footprint_radius * obstacle_scale))
	return result


## Modelin tüm malzemelerine bir shader parametresi verir (ör. "ember_glow"). Model kurulmadan önce de
## çağrılabilir; yeniden kurulumda korunur.
func set_shader_parameter(param: StringName, value: Variant) -> void:
	_extra_params[param] = value
	if _model:
		_apply_materials(_model)


## Modelin kullandığı malzemeler (yüzey sırasıyla; kesitli modelin gölge kopyaları hariç).
func get_materials() -> Array[ShaderMaterial]:
	var result: Array[ShaderMaterial] = []
	if _model == null:
		return result
	for mi in _visible_meshes(_model):
		if mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var mat := mi.get_surface_override_material(i) as ShaderMaterial
			if mat:
				result.append(mat)
	return result


func _queue_rebuild() -> void:
	if not is_inside_tree() or _rebuild_pending:
		return
	_rebuild_pending = true
	_rebuild.call_deferred()


func _rebuild() -> void:
	_rebuild_pending = false
	if _model:
		remove_child(_model)
		_model.queue_free()
		_model = null
	_footprint_radius = 0.0
	_bounds = AABB()
	_scale = 1.0
	if not exists(folder, model_id):
		return
	var scene := load(model_path(folder, model_id)) as PackedScene
	if scene == null:
		return
	_model = scene.instantiate() as Node3D
	if _model == null:
		return
	_model.name = "Model"
	_model.set_meta(&"generated", true)
	add_child(_model)
	var box := _model_aabb(_model)
	var has_box := fit_box.x > 0.0 or fit_box.y > 0.0 or fit_box.z > 0.0
	_scale = fit_inside(box, fit_box) if has_box else fit_scale(box, target_size, size_axis)
	_raw_box = box
	_apply_fit()
	_footprint_radius = (box.size.x + box.size.z) * 0.25 * _scale
	_apply_instance_settings(_model)
	_apply_materials(_model)
	if cutaway:
		_add_shadow_proxies(_model)


## Ölçeği ve dikey uzatmayı modele uygular: tabanın ortası düğümün yerine oturur, sınır kutusu güncellenir.
func _apply_fit() -> void:
	if _model == null:
		return
	var s := MeshyProp.stretched_scale(_scale, vertical_stretch)
	_model.scale = s
	_model.position = MeshyProp.stretched_offset(_raw_box, s, sink)
	_bounds = AABB(_raw_box.position * s + _model.position, _raw_box.size * s)


## Uzatılmış ölçek: yatayda s, dikeyde s × stretch (saf fonksiyon).
static func stretched_scale(s: float, stretch: float) -> Vector3:
	return Vector3(s, s * stretch, s)


## placement_offset'in eşit olmayan ölçekli hâli: tabanın ortasını düğümün yerine getiren kaydırma (saf fonksiyon).
static func stretched_offset(box: AABB, s: Vector3, p_sink: float) -> Vector3:
	var center := box.get_center()
	return -Vector3(center.x, box.position.y, center.z) * s - Vector3(0.0, p_sink, 0.0)


## Tüm meshlerin model uzayındaki birleşik sınır kutusu.
static func _model_aabb(root: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for node in root.find_children("*", "VisualInstance3D", true, false):
		var vi := node as VisualInstance3D
		var local := _relative_transform(root, vi) * vi.get_aabb()
		box = local if first else box.merge(local)
		first = false
	return box


static func _relative_transform(root: Node3D, node: Node3D) -> Transform3D:
	var xform := Transform3D.IDENTITY
	var n: Node = node
	while n != null and n != root:
		if n is Node3D:
			xform = (n as Node3D).transform * xform
		n = n.get_parent()
	return xform


## Modelin görünen meshleri (kesitli modelin yalnızca gölge veren kopyaları hariç).
static func _visible_meshes(root: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	for node in root.find_children("*", "MeshInstance3D", true, false):
		if not node.has_meta(SHADOW_PROXY_META):
			result.append(node as MeshInstance3D)
	return result


## Modelin meshlerine gölge ve çizim katmanı ayarlarını uygular (kesitli modelde görünen meshler gölge vermez).
func _apply_instance_settings(root: Node) -> void:
	for mi in _visible_meshes(root):
		var shadows := cast_shadows and not cutaway
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.layers = render_layers


## Kesitli model için her meshin yanına kesilmeyen, yalnızca gölge veren bir kopya koyar (aynı mesh, düz iki yüzlü
## malzeme).
func _add_shadow_proxies(root: Node) -> void:
	for mi in _visible_meshes(root):
		if mi.mesh == null:
			continue
		var proxy := MeshInstance3D.new()
		proxy.name = "%sShadow" % mi.name
		proxy.mesh = mi.mesh
		proxy.transform = mi.transform
		proxy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY if cast_shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		proxy.set_meta(SHADOW_PROXY_META, true)
		var box := mi.get_aabb()
		for i in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(i)
			var texture: Texture2D = (src as BaseMaterial3D).albedo_texture if src is BaseMaterial3D else null
			proxy.set_surface_override_material(i, _material_for(texture, box.position.y, false))
		mi.get_parent().add_child(proxy)


## Modelin kendi dokularını koruyarak her yüzeye AtW dokulu malzeme verir.
func _apply_materials(root: Node) -> void:
	for mi in _visible_meshes(root):
		if mi.mesh == null:
			continue
		var box := mi.get_aabb()
		for i in mi.mesh.get_surface_count():
			# Kaynak her zaman modelin kendi malzemesidir (üstüne yazılmış AtW malzemesi değil).
			var src := mi.mesh.surface_get_material(i)
			var texture: Texture2D = (src as BaseMaterial3D).albedo_texture if src is BaseMaterial3D else null
			mi.set_surface_override_material(i, _material_for(texture, box.position.y))


## Bir yüzeyin malzemesi. cut: kesitli (örneğe özel) malzeme mi; değilse aynı ayarlı kopyalar paylaşır.
func _material_for(texture: Texture2D, base_y: float, cut: bool = cutaway) -> ShaderMaterial:
	var two_sided := double_sided or cutaway
	var key := "%s|%d|%s|%.3f|%.3f|%.4f|%.4f|%s" % [
		texture.get_rid().get_id() if texture else 0, int(two_sided), tint.to_html(), ink_strength, brush_strength,
		base_y, _scale, str(_extra_params)]
	if not cut and _material_cache.has(key):
		return _material_cache[key]
	var mat := ShaderMaterial.new()
	mat.shader = CUT_SHADER if cut else (DOUBLE_SHADER if two_sided else SHADER)
	mat.set_shader_parameter("albedo_texture", texture)
	mat.set_shader_parameter("albedo_tint", tint)
	mat.set_shader_parameter("ink_strength", ink_strength)
	mat.set_shader_parameter("brush_strength", brush_strength)
	mat.set_shader_parameter("model_base_y", base_y)
	mat.set_shader_parameter("model_scale", _scale)
	for param in _extra_params:
		mat.set_shader_parameter(param, _extra_params[param])
	if not cut:
		_material_cache[key] = mat
	return mat


## Paylaşılan malzeme önbelleğini temizler (testlerde ve editörde yeniden üretim için).
static func clear_cache() -> void:
	_material_cache.clear()
