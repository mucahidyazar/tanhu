@tool
class_name World
extends Node3D
## Sahnenin kökü.
##
## - Gökyüzündeki ay ile su üzerindeki parıltıyı aynı yöne hizalar.
## - Ay ışığının (DirectionalLight3D) geliş yönünü ayarlar.
## - Kamp toprağı lekelerini araziye iletir: elle verilen lekeler (dirt_spots) ve yurtların kapı önlerindeki
##   ezik toprak (yurt_door_spots; yurt taşınınca leke de onunla gider).
## - Serbest gezinti için "obstacles" grubundaki engelleri toplar: daireler, kapılı dairesel duvarlar (otağlar) ve
##   döndürülmüş kutular (otağın içindeki yatak, sandık...).

const OBSTACLE_GROUP := &"obstacles"
## Yurt kapısının önündeki ezik toprak (basamakların oturduğu yer): merkezi kapı yönünde yurdun yarıçapının
## DOOR_SPOT_DISTANCE katı uzakta, yarıçapı yurdun yarıçapının DOOR_SPOT_RADIUS katı.
const DOOR_SPOT_DISTANCE := 1.2
const DOOR_SPOT_RADIUS := 0.42
const DOOR_SPOT_STRENGTH := 0.8

## Gökyüzündeki ayın yatay açısı (derece). 0 = menü kamerasının baktığı yön (-Z), pozitif = sağ.
@export_range(-180.0, 180.0) var moon_azimuth := 24.0:
	set(value):
		moon_azimuth = value
		_apply_directions()
## Ayın ufuktan yüksekliği (derece).
@export_range(0.0, 90.0) var moon_elevation := 14.0:
	set(value):
		moon_elevation = value
		_apply_directions()
## Ay ışığının sahneye geldiği yön. Görsel aydan bağımsızdır: ressamların yaptığı gibi
## karakterlerin yüzü karanlıkta kalmasın diye ışık kamera tarafından gelir.
@export_range(-180.0, 180.0) var light_azimuth := 140.0:
	set(value):
		light_azimuth = value
		_apply_directions()
@export_range(5.0, 90.0) var light_elevation := 50.0:
	set(value):
		light_elevation = value
		_apply_directions()
## Kamp toprağı lekeleri: Vector4(x, z, yarıçap, şiddet). Yurt kapılarının önündekiler kendiliğinden eklenir
## (bkz. ground_dirt_spots). Ateşin çevresinde küçük, koyu bir ezik toprak (referanstaki gibi çimen halılara kadar
## gelir); merkezi biraz öne kaydırılmıştır ki patikanın başına (0.7, 1.4) bağlansın. (Arazi shader'ı her
## pikselde her lekeyi dolaştığı için leke sayısı az tutulur.)
@export var dirt_spots: Array[Vector4] = [
	Vector4(0.2, 0.4, 2.2, 0.72),
	Vector4(12.4, -11.8, 2.6, 0.55),
]:
	set(value):
		dirt_spots = value
		_apply_dirt_spots()


## Gece renk ayarının LUT'u (bir kez üretilir, tüm dünya örnekleri paylaşır).
static var _night_lut: ImageTexture3D


func _ready() -> void:
	_apply_directions()
	_apply_dirt_spots()
	_apply_color_grade()


## Gündüz renkleriyle ayarlı AtW malzemelerini gece görünümüne çeviren renk ayarını bağlar
## (bkz. ColorGrade.world_night).
func _apply_color_grade() -> void:
	var env_node := get_node_or_null(^"WorldEnvironment") as WorldEnvironment
	if env_node == null or env_node.environment == null:
		return
	# Geliştirme: "--no-grade" ile ham renkler görülür (renk ayarını ölçerek uydurmak için).
	if not Engine.is_editor_hint() and OS.get_cmdline_user_args().has("--no-grade"):
		env_node.environment.adjustment_color_correction = null
		return
	if _night_lut == null:
		_night_lut = ColorGrade.world_night().build_lut()
	env_node.environment.adjustment_enabled = true
	env_node.environment.adjustment_color_correction = _night_lut


## Kurulum bitti mi? Dağlar, orman, kayalar ve çayır ertelenmiş kurulur (engeller önce kaydolur); kurulan düğüm çocuk taşır. WorldHost kampı
## yeniden kurarken perdeyi bunu bekleyerek kaldırır.
func is_built() -> bool:
	for path: NodePath in [^"Mountains", ^"Forest", ^"RockField", ^"Meadow"]:
		var node := get_node_or_null(path)
		if node and node.get_child_count() == 0:
			return false
	return true


## Ortak arazi biçimi (serbest gezinti ve dağıtıcılar kullanır).
func get_terrain_shape() -> TerrainShape:
	var terrain := get_node_or_null(^"Terrain") as Terrain
	if terrain and terrain.shape:
		return terrain.shape
	return TerrainShape.new()


## "obstacles" grubundaki düğümlerden serbest gezintide çarpışılan daireleri toplar: Vector3(x, z, yarıçap).
## Düğüm get_collision_circles() veriyorsa o kullanılır (içine girilen otağ: yalnızca içindeki eşyalar; duvarı
## collect_walls'tadır), yoksa get_obstacle_circles(). (get_obstacle_circles nesnenin kapladığı yerdir: çimen ve
## patikalar oradan uzak durur.)
func collect_obstacles() -> Array[Vector3]:
	var result: Array[Vector3] = []
	if not is_inside_tree():
		return result
	for node in get_tree().get_nodes_in_group(OBSTACLE_GROUP):
		if node.has_method("get_collision_circles"):
			result.append_array(node.get_collision_circles())
		elif node.has_method("get_obstacle_circles"):
			result.append_array(node.get_obstacle_circles())
	return result


## Kapılı dairesel duvarlar (otağların keçe duvarları; get_obstacle_walls).
func collect_walls() -> Array[RingWall]:
	var result: Array[RingWall] = []
	if not is_inside_tree():
		return result
	for node in get_tree().get_nodes_in_group(OBSTACLE_GROUP):
		if node.has_method("get_obstacle_walls"):
			result.append_array(node.get_obstacle_walls())
	return result


## Döndürülmüş kutu engeller (otağın içindeki yatak, sandık, dolap; get_obstacle_boxes).
func collect_boxes() -> Array[ObstacleBox]:
	var result: Array[ObstacleBox] = []
	if not is_inside_tree():
		return result
	for node in get_tree().get_nodes_in_group(OBSTACLE_GROUP):
		if node.has_method("get_obstacle_boxes"):
			result.append_array(node.get_obstacle_boxes())
	return result


## Araziye giden tüm toprak lekeleri: dirt_spots ve yurtların kapı önleri.
func ground_dirt_spots() -> Array[Vector4]:
	var spots: Array[Vector4] = dirt_spots.duplicate()
	if is_inside_tree():
		spots.append_array(yurt_door_spots(get_tree()))
	return spots


## Yurt kapısının önündeki toprak lekesi (saf fonksiyon): Vector4(x, z, yarıçap, şiddet).
## door_direction: kapının baktığı yön (yurdun yerel +Z ekseni, dünya uzayında).
static func door_spot(yurt_position: Vector3, door_direction: Vector3, yurt_radius: float) -> Vector4:
	var dir := Vector2(door_direction.x, door_direction.z).normalized()
	var c := Vector2(yurt_position.x, yurt_position.z) + dir * yurt_radius * DOOR_SPOT_DISTANCE
	return Vector4(c.x, c.y, yurt_radius * DOOR_SPOT_RADIUS, DOOR_SPOT_STRENGTH)


## Sahnedeki yurtların ("obstacles" grubundaki Yurt düğümleri) kapı önü lekeleri. Ağaç yoksa boş.
static func yurt_door_spots(tree: SceneTree) -> Array[Vector4]:
	var result: Array[Vector4] = []
	if tree == null:
		return result
	for node in tree.get_nodes_in_group(OBSTACLE_GROUP):
		var yurt := node as Yurt
		if yurt and yurt.is_inside_tree():
			result.append(door_spot(yurt.global_position, yurt.global_transform.basis.z, yurt.radius))
	return result


## Açılardan birim yön vektörü üretir. azimuth 0 = -Z, 90 = +X.
static func direction_from_angles(azimuth_deg: float, elevation_deg: float) -> Vector3:
	var az := deg_to_rad(azimuth_deg)
	var el := deg_to_rad(elevation_deg)
	return Vector3(sin(az) * cos(el), sin(el), -cos(az) * cos(el))


func _apply_directions() -> void:
	if not is_inside_tree():
		return
	var moon_dir := direction_from_angles(moon_azimuth, moon_elevation)
	var env_node := get_node_or_null(^"WorldEnvironment") as WorldEnvironment
	if env_node and env_node.environment and env_node.environment.sky:
		var sky_mat := env_node.environment.sky.sky_material as ShaderMaterial
		if sky_mat:
			sky_mat.set_shader_parameter("moon_direction", moon_dir)
	var water := get_node_or_null(^"Water") as Water
	if water:
		water.set_moon_direction(moon_dir)
	var light := get_node_or_null(^"MoonLight") as DirectionalLight3D
	if light:
		var light_dir := direction_from_angles(light_azimuth, light_elevation)
		# Işık kendi -Z ekseni boyunca ilerler; ışık kaynağına bakan yön light_dir'dir.
		light.basis = Basis.looking_at(-light_dir, Vector3.UP)


func _apply_dirt_spots() -> void:
	if not is_inside_tree():
		return
	var terrain := get_node_or_null(^"Terrain") as Terrain
	if terrain:
		terrain.dirt_spots = ground_dirt_spots()
