@tool
class_name Meadow
extends Node3D
## Kamp çevresindeki çayır (4. referanstaki gibi): rüzgârda salınan ince, kısa çimen kümeleri; çayıra serpilmiş
## küçük beyaz, sarı ve mavi çiçek kümeleri; ateş böcekleri.
##  - Kısa çayır tutamları küçüktür ve her yerleşim noktasına LAWN_SPLIT tane düşer: çimen iri "tarak" öbekleri
##    değil, ince ve sık bir doku gibi okunur (yaprak sayısı ve maliyet aynı kalır).
##  - Yurt, ateş, halı gibi nesnelerin altına çimen çıkmaz. Engellerin (kayalar, yurtlar, halılar) dibinde çimen
##    kısalır ve çiçek çoğalır: kayalar kısa çimenin, çiçeklerin arasında durur.
##  - Ateşin çevresi (trample_center) ve yurt kapılarının önü (World.yurt_door_spots) ezik topraktır: orada çimen
##    çıkmaz, kenara doğru seyrek ve kısa başlar.
##  - Toprak patikaların (PathNetwork) üstünde çimen çıkmaz; kenara yakın çimen seyrek ve kısadır.
##  - Kampın çevresinde (camp_center, camp_radius) çimen sık ve küçük tutamlıdır; çayırın uzak kenarlarında seyrek
##    ama iri tutamlıdır (menü kamerasından çok uzakta oldukları için ekranda yine küçük görünürler).
##
## Örnekler karelere (chunk) bölünür; kameranın görmediği kareler otomatik kırpılır.

const GRASS_SHADER := preload("res://shaders/atw_grass.gdshader")
## Çimen tutamı çeşitleri: Vector3i(yaprak sayısı, tohum, kök yayılımı × 100). Yayılım tutamın boyuna oranladır;
## yaprak eni ondan bağımsız ve incedir: yüksek menü kamerasından referanstaki ince, boyalı çimen gibi okunur.
## Modeller tuft_mesh ile kurulur (AtwKit.tuft'un ince yapraklı sürümü, aynı UV düzeni): ilk LAWN_VARIANTS çeşit
## kısa çayır tutamıdır (tek üçgenlik sivri yapraklar), kalanlar uzun ön plan tutamı (iki bölütlü, kavisli).
## Çeşit sayısı az tutulur: her kare × çeşit ayrı bir çizim çağrısıdır. Kısa çayır tutamları dar ve az yapraklıdır
## (yaprak aralığı uzun tutamlarla aynı); bir yerleşim noktasına LAWN_SPLIT tane düşer.
const TUFT_VARIANTS: Array[Vector3i] = [Vector3i(8, 5, 48), Vector3i(7, 11, 43), Vector3i(10, 23, 105), Vector3i(9, 37, 90)]
const LAWN_VARIANTS := 2
## Kısa çayırda her yerleşim noktasına düşen küçük tutam sayısı (ilki noktada, kalanlar 10–22 cm ötede).
const LAWN_SPLIT := 2
## grass_height() değerinin tutam ölçeğine çevrilmesi (tutam modeli ~1 birim yüksekliğindedir).
const TUFT_HEIGHT_SCALE := 1.15
## Bu boydan (metre) uzun tutamlar kavisli, iki bölütlü yapraklarla çizilir; kısalar tek üçgenlik yapraklarla.
const TALL_TUFT := 0.32
## Yaprağın dipteki eni (modelin yatay birimiyle; x: kısa çayır, y: uzun tutam). Yapraklar sivri uçlu ve
## çoğunlukla 2–6 cm enindedir: daha ince yapraklar menü kamerasından piksel altına düşer, GPU'yu (MSAA ile)
## çok yorar ve referanstaki fırça darbelerinden incedir.
const BLADE_WIDTH := Vector2(0.1, 0.1)
## Tutamın yatay ölçeğinin boyuna oranı: kısa çimen (çayır) tutamları geniş ve alçak bir öbek, uzun (ön plan)
## tutamlar dar ve diktir; ezik (çok kısa) çimen daha da yayvandır ki zemini yine örtsün.
## x: 0,06 m, y: 0,15 m, z: 0,4 m (ve daha uzun) tutam (bkz. tuft_aspect).
const TUFT_ASPECT := Vector3(4.2, 3.1, 0.95)
const FLOWER_SHADER := preload("res://shaders/flower.gdshader")
## Çiçek türleri (flower.gdshader, INSTANCE_CUSTOM.r): beyaz papatya, sarı düğün çiçeği, açık mavi unutmabeni.
const FLOWER_WHITE := 0.0
const FLOWER_YELLOW := 0.5
const FLOWER_BLUE := 1.0
## Çiçek öbeği modeli: Vector2i(çiçek sayısı, tohum) ve iki sap boyu (metre; kısa ve uzun çimen için). Az
## çizim çağrısı için yalnızca iki model vardır; örnekler düzgün ölçeklenir ki başlar yatay kalsın.
const FLOWER_CLUSTER := Vector2i(3, 7)
const FLOWER_STEMS: Array[float] = [0.11, 0.24]
## Çimen yerleşim ızgarasının hücre boyu (metre): her hücreye en çok bir aday düşer (bkz. _grass_points).
const GRASS_CELL := 0.22
## Engel ızgarasının hücre boyu ve bir noktaya "yakın" sayılan en büyük engel kenarı uzaklığı (metre).
const BLOCKER_CELL := 2.0
const BLOCKER_REACH := 2.0

@export var seed_value := 9
@export var terrain_seed := 1207
@export var center := Vector2(0.0, -2.0)
@export var radius := 36.0
@export var clump_count := 26000
@export var flower_count := 2600
@export var chunk_size := 12.0
## Menü kamerasının önündeki çimenlik (yoğunluğu ve boyu artırılır): Rect2(x, z, genişlik, derinlik).
@export var foreground := Rect2(-12.0, 1.5, 24.0, 7.0)
@export var foreground_boost := 2.4
@export var fireflies := true
## Ateşin (ezik, kısa çimenin) merkezi (x, z).
@export var trample_center := Vector2.ZERO
## Ateşin çevresindeki ezik toprağın yarıçapı (metre): yarısından içeride çimen yok, kenarına doğru gürleşir.
@export var trample_radius := 2.3
## Patika kenarından bu mesafeye kadar çimen seyrek ve kısa kalır (metre). Kısa tutulur: referanstaki gibi çimen
## ve çiçekler patikanın kenarına kadar gelir.
@export var path_fade := 0.35
## Kampın çevresi: bu dairenin içinde çimen sık ve küçük tutamlı, dışına doğru seyrek ve iri tutamlı olur.
@export var camp_center := Vector2(1.0, -3.0)
@export var camp_radius := 16.0
## Çayırın uzak kenarındaki çimen yoğunluğu ve tutam büyüklüğü (kamp çevresine oranla).
@export var periphery_density := 0.22
@export var periphery_tuft_scale := 1.6
## Engellerin (kaya, yurt, halı) kenarından bu mesafeye kadar çimen kısalır, çiçek çoğalır (metre).
@export var blocker_clearance := 1.3
## Pişmiş örneklerin haritası (MapBake; world-swap): boş değilse çimen ve çiçek örnekleri data/maps/<bake_id>/baked/meadow.res'ten
## gelir (tools/bake_map.gd). Ayarlar, engeller, kapı önleri, patikalar ya da biçim pişirilenden ayrıysa imza tutmaz, çayır kendisi
## üretir. Kampın dünyasında "camp"tır.
@export var bake_id := ""
@export_tool_button("Yeniden oluştur", "Reload") var rebuild_button: Callable = rebuild

## Son kurulum pişmiş örneklerle mi yapıldı (bake_id)?
var used_bake := false
var _noise: FastNoiseLite
## Çimen renk lekelerinin gürültüsü (atw_grass.gdshader'a örnek başına INSTANCE_CUSTOM.a olarak gider).
var _patch_noise: FastNoiseLite
## Sahnedeki patika ağı (rebuild sırasında bulunur; yoksa patika etkisi yoktur).
var _paths: PathNetwork
## Yurt kapılarının önündeki ezik toprak lekeleri: Vector4(x, z, yarıçap, şiddet) (rebuild sırasında bulunur).
var _door_spots: Array[Vector4] = []
## Engel daireleri ve hızlı sorgu ızgarası: Vector2i hücre → o hücreye BLOCKER_REACH kadar yakın dairelerin listesi.
var _blockers: Array[Vector3] = []
var _blocker_grid := {}
## Pişirme aracı için saklanan örnekler (MapBake.capture): önek → [[anahtar, ham dizi], ...] (üretim sırasıyla).
var _captured := {}


func _ready() -> void:
	# Engeller (yurtlar, halılar) ağaca eklendikten sonra kur.
	rebuild.call_deferred()


func rebuild() -> void:
	for child in get_children():
		if child.has_meta(&"generated"):
			remove_child(child)
			child.queue_free()
	_noise = TerrainShape._make_noise(seed_value, 0.08, 2, FastNoiseLite.FRACTAL_FBM)
	_patch_noise = TerrainShape._make_noise(seed_value + 17, 0.09, 3, FastNoiseLite.FRACTAL_FBM)
	_paths = PathNetwork.find_in_tree(get_tree())
	_door_spots = World.yurt_door_spots(get_tree())
	var shape := TerrainShape.new(terrain_seed)
	var blockers := collect_blockers(get_tree())
	_index_blockers(blockers)
	_captured.clear()
	var bake := MapBake.fetch(bake_id, "meadow", bake_signature(shape)) if not bake_id.is_empty() else null
	used_bake = bake != null
	if bake:
		# Pişmiş örnekler: kareler üretimdeki sırayla, aynı ağ ve malzemeyle (tools/bake_map.gd, bake_payload).
		_emit_buffers(bake.data.get("grass", []), _grass_meshes(), _grass_material(), "Grass")
		_emit_buffers(bake.data.get("flowers", []), _flower_meshes(), _flower_material(), "Flowers")
	else:
		_build_grass(shape)
		_build_flowers(shape)
	if fireflies:
		var ff := Fx.fireflies(46, Vector3(15.0, 1.1, 12.0))
		ff.position = Vector3(center.x, 1.1, center.y)
		_add(ff)


## Çimen yoğunluğu (0..~3): engellerin içinde 0, ön planda yüksek, ateşin çevresinde ve kapı önlerinde ezik.
## blockers: çimen çıkmayacak daireler (bkz. collect_blockers; noktanın çevresindekiler yeterlidir).
func grass_density(p: Vector2, blockers: Array[Vector3]) -> float:
	if Scatter.is_blocked(p.x, p.y, blockers, 0.12):
		return 0.0
	var edge := 1.0 - smoothstep(radius * 0.72, radius, p.distance_to(center))
	var fg := Scatter.foreground_weight(p.x, p.y, foreground)
	var trample := trample_weight(p.distance_to(trample_center), trample_radius)
	var near_blocker := smoothstep(0.0, 1.2, Scatter.distance_to_circles(p.x, p.y, blockers))
	var path := path_weight(path_edge_distance(p), path_fade)
	var camp := lerpf(1.0, periphery_density, periphery_weight(p))
	return edge * trample * door_weight(p, _door_spots) * lerpf(0.8, 1.0, near_blocker) * path * camp * (1.0 + foreground_boost * fg)


## Çimen boyu (metre): ön planda daha uzun; ateşin, kapıların, patikanın ve engellerin dibinde kısa; gürültüyle
## dalgalanır. (Tutamın kendi ölçeği ayrıca periphery_weight ile büyür, bkz. _build_grass.)
func grass_height(p: Vector2) -> float:
	var fg := Scatter.foreground_weight(p.x, p.y, foreground)
	var n := _noise.get_noise_2d(p.x, p.y) * 0.5 + 0.5
	var trample := smoothstep(trample_radius * 0.5, trample_radius * 2.0, p.distance_to(trample_center))
	var path_trample := smoothstep(0.0, path_fade, path_edge_distance(p))
	var shelter := smoothstep(0.0, blocker_clearance, Scatter.distance_to_circles(p.x, p.y, near_blockers(p)))
	var door := door_weight(p, _door_spots)
	return (0.15 + n * 0.08 + fg * 0.27) * lerpf(0.6, 1.0, trample) * lerpf(0.55, 1.0, shelter) \
		* lerpf(0.5, 1.0, door) * lerpf(0.7, 1.0, path_trample)


## Çiçek kümesi olasılığı (0..~2,6): çimenli her yerde biraz; kampın çevresinde, ön planda, kayaların dibinde
## ve patika kenarlarında daha çok. Toprakta, patikada ve engellerin içinde 0.
func flower_weight(p: Vector2, blockers: Array[Vector3]) -> float:
	if grass_density(p, blockers) <= 0.05:
		return 0.0
	var camp := lerpf(1.0, 0.55, periphery_weight(p))
	var fg := Scatter.foreground_weight(p.x, p.y, foreground)
	var by_blocker := 1.0 - smoothstep(0.3, blocker_clearance + 0.5, Scatter.distance_to_circles(p.x, p.y, blockers))
	var by_path := 1.0 - smoothstep(0.25, 1.1, path_edge_distance(p))
	return camp * (0.7 + fg * 0.7 + by_blocker * 0.9 + by_path * 0.5)


## Kampın çevresinden (0) çayırın uzak kenarına (1) geçiş.
func periphery_weight(p: Vector2) -> float:
	return smoothstep(camp_radius, camp_radius * 1.7, p.distance_to(camp_center))


## Patika kenarına işaretli uzaklık (içeride eksi). Patika ağı yoksa ya da uzaksa path_fade + 1.
func path_edge_distance(p: Vector2) -> float:
	if _paths == null:
		return path_fade + 1.0
	return _paths.distance_to_paths_clamped(p, path_fade + 1.0)


## Noktanın BLOCKER_REACH yakınındaki engel daireleri (rebuild sırasında kurulan ızgaradan; kurulmadıysa boş).
## is_blocked ve distance_to_circles bu listeyle tüm engellerle aynı sonucu verir (uzaktaki engellerin etkisi yok).
func near_blockers(p: Vector2) -> Array[Vector3]:
	var key := Vector2i(floori(p.x / BLOCKER_CELL), floori(p.y / BLOCKER_CELL))
	var ids: PackedInt32Array = _blocker_grid.get(key, PackedInt32Array())
	var result: Array[Vector3] = []
	for i in ids:
		result.append(_blockers[i])
	return result


## Tutamın yatay ölçeğinin boyuna oranı (saf fonksiyon; bkz. TUFT_ASPECT): boy uzadıkça azalır.
static func tuft_aspect(height: float) -> float:
	if height < 0.15:
		return lerpf(TUFT_ASPECT.x, TUFT_ASPECT.y, smoothstep(0.06, 0.15, height))
	return lerpf(TUFT_ASPECT.y, TUFT_ASPECT.z, smoothstep(0.15, 0.4, height))


## Patikanın çimen yoğunluğuna etkisi (saf fonksiyon): patikada ve kenarın hemen dibinde 0,
## kenardan uzaklaştıkça seyrekten (0.3) tam yoğunluğa (1) yumuşakça çıkar.
static func path_weight(edge_distance: float, fade: float) -> float:
	if edge_distance <= 0.04:
		return 0.0
	return lerpf(0.3, 1.0, smoothstep(0.04, maxf(fade, 0.05), edge_distance))


## Ezik bölgenin (ateş çevresi) çimen yoğunluğuna etkisi (saf fonksiyon): yarıçapın %55'ine kadar 0, kenarda 1.
static func trample_weight(distance: float, trample_radius_m: float) -> float:
	return smoothstep(trample_radius_m * 0.55, maxf(trample_radius_m, 0.01), distance)


## Kapı önü lekelerinin çimen yoğunluğuna etkisi (saf fonksiyon): lekenin yarıçapının %55'ine kadar 0 (basamaklar
## çıplak toprakta durur), yarıçapın 1,1 katında 1. spots: Vector4(x, z, yarıçap, şiddet).
static func door_weight(p: Vector2, spots: Array[Vector4]) -> float:
	var w := 1.0
	for s in spots:
		w = minf(w, smoothstep(s.z * 0.55, s.z * 1.1, p.distance_to(Vector2(s.x, s.y))))
	return w


## "obstacles" ve "ground_cover" gruplarından çimen çıkmayacak daireleri toplar.
static func collect_blockers(tree: SceneTree) -> Array[Vector3]:
	var result: Array[Vector3] = []
	if tree == null:
		return result
	for node in tree.get_nodes_in_group(World.OBSTACLE_GROUP):
		if node.has_method("get_obstacle_circles"):
			result.append_array(node.get_obstacle_circles())
	for node in tree.get_nodes_in_group(Rug.GROUND_COVER_GROUP):
		if node.has_method("get_cover_circles"):
			result.append_array(node.get_cover_circles())
	return result


## Çimen tutamı modeli (saf fonksiyon; XY düzleminde ince bir kart, kökler yerde, en uzun yaprak ~1 birim):
## yapraklar ortada uzun, kenarlarda kısa ve dışa eğik, sivri uçlu. segments = 1: her yaprak tek üçgen (3 köşe;
## kısa çayır), 2: kavisli iki bölüt (5 köşe, 3 üçgen; uzun çimen). spread: köklerin x yönündeki yayılımı (dar
## tutamda yapraklar da az açılır), blade_width: yaprağın dipteki eni. UV.x yaprağın tonu, UV.y kökten uca 0..1,
## UV2.x köşenin yaprak ekseninden yatay uzaklığı (shader uzaktaki yaprakları bununla genişletir; bkz.
## atw_grass.gdshader "widen_*").
static func tuft_mesh(blades: int, rng_seed: int, spread: float, segments: int = 2, blade_width: float = 0.075) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var vertices := PackedVector3Array()
	var uvs := PackedVector2Array()
	var offsets := PackedVector2Array()
	var indices := PackedInt32Array()
	for b in blades:
		var k := (float(b) + rng.randf_range(0.15, 0.85)) / float(blades) * 2.0 - 1.0
		var root := Vector3(k * spread * 0.5, 0.0, rng.randf_range(-0.03, 0.03))
		var h := lerpf(1.0, 0.5, pow(absf(k), 1.2)) * rng.randf_range(0.72, 1.08)
		var fan := k * h * rng.randf_range(0.2, 0.5) * minf(spread / 0.85, 1.0)
		var lean := Vector3(fan + rng.randf_range(-0.1, 0.1) * h, 0.0, rng.randf_range(-0.06, 0.06) * h)
		var half := blade_width * rng.randf_range(0.8, 1.2) * 0.5
		var tone := rng.randf()
		var base := vertices.size()
		var rows: Array[float] = [0.0]
		if segments > 1:
			rows.append(0.55)
		for t in rows:
			var c: Vector3 = root + lean * (t * t) + Vector3(0.0, h * t, 0.0)
			var w: float = half * (1.0 - t * 0.7)
			vertices.append_array(PackedVector3Array([c - Vector3(w, 0.0, 0.0), c + Vector3(w, 0.0, 0.0)]))
			uvs.append_array(PackedVector2Array([Vector2(tone, t), Vector2(tone, t)]))
			offsets.append_array(PackedVector2Array([Vector2(-w, 0.0), Vector2(w, 0.0)]))
		vertices.append(root + lean + Vector3(0.0, h, 0.0))
		uvs.append(Vector2(tone, 1.0))
		offsets.append(Vector2.ZERO)
		if rows.size() == 1:
			indices.append_array(PackedInt32Array([base, base + 1, base + 2]))
		else:
			indices.append_array(PackedInt32Array([base, base + 1, base + 2, base + 1, base + 3, base + 2, base + 2, base + 3, base + 4]))
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	normals.fill(Vector3.UP)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_TEX_UV2] = offsets
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Engel ızgarası (saf fonksiyon): her hücreye, kenarı hücreye reach kadar yaklaşan dairelerin sırası.
static func build_circle_grid(circles: Array[Vector3], cell: float, reach: float) -> Dictionary:
	var grid := {}
	for i in circles.size():
		var c := circles[i]
		var pad := c.z + reach
		for cx in range(floori((c.x - pad) / cell), floori((c.x + pad) / cell) + 1):
			for cz in range(floori((c.y - pad) / cell), floori((c.y + pad) / cell) + 1):
				var key := Vector2i(cx, cz)
				var ids: PackedInt32Array = grid.get(key, PackedInt32Array())
				ids.append(i)
				grid[key] = ids
	return grid


## Çiçek öbeği modeli (saf fonksiyon): count çiçek başı; her biri hafif eğik, yukarı bakan kare bir dörtgen
## (taç yaprakları UV üzerinde çizilir, flower.gdshader). Saplar çizilmez: menü kamerasından piksel altına düşen
## ince saplar GPU'yu yorar; başlar çimenin üst hizasında durduğu için sap zaten çimenin içinde kalır.
## Kökler 0,12 m'lik bir alana dağılır; boylar stem_height'ın %70–100'üdür. COLOR.a = 1 (baş), COLOR.r: çiçek
## başına rastgele değer.
static func flower_cluster(count: int, rng_seed: int, stem_height: float, head_size: float) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in maxi(count, 1):
		var root := Vector3.ZERO if i == 0 else Vector3(rng.randf_range(-0.12, 0.12), 0.0, rng.randf_range(-0.12, 0.12))
		var top := root + Vector3(rng.randf_range(-0.02, 0.02), stem_height * rng.randf_range(0.7, 1.0), rng.randf_range(-0.02, 0.02))
		var size := head_size * rng.randf_range(0.8, 1.15)
		var tilt := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, deg_to_rad(rng.randf_range(10.0, 30.0)))
		_add_flower_head(st, i * 4, top, size, tilt, rng.randf())
	return st.commit()


## Bir çiçek başını (dörtgen) SurfaceTool'a ekler; first: başın ilk köşesinin sırası.
static func _add_flower_head(st: SurfaceTool, first: int, top: Vector3, size: float, tilt: Basis, value: float) -> void:
	var h := size * 0.5
	var corners: Array[Vector2] = [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
	for k in 4:
		st.set_normal(tilt * Vector3.UP)
		st.set_uv(Vector2(float(k % 2), 0.0 if k < 2 else 1.0))
		st.set_color(Color(value, 0.0, 0.0, 1.0))
		st.add_vertex(top + tilt * Vector3(corners[k].x * h, 0.0, corners[k].y * h))
	for idx in [first, first + 2, first + 1, first + 1, first + 2, first + 3]:
		st.add_index(idx)


func _index_blockers(blockers: Array[Vector3]) -> void:
	_blockers = blockers
	_blocker_grid = build_circle_grid(blockers, BLOCKER_CELL, BLOCKER_REACH)


## Çimen tutamlarının yerleri: titreştirilmiş ızgara (her hücrede bir aday) ve yoğunluğa göre kabul. Rastgele
## (Poisson) dağılımdaki boşluklar ve kümelenmeler olmaz; beklenen tutam sayısı clump_count'tur. Yoğunluğun
## bir hücreye birden fazla tutam düşürdüğü yerlerde (ön plan) fazlası hücrenin içine serpilir.
func _grass_points(rng: RandomNumberGenerator) -> Array[Vector2]:
	var candidates := PackedVector2Array()
	var weights := PackedFloat32Array()
	var total := 0.0
	var n := ceili(radius / GRASS_CELL)
	for ix in range(-n, n):
		for iz in range(-n, n):
			var p := center + Vector2(ix + rng.randf(), iz + rng.randf()) * GRASS_CELL
			if p.distance_to(center) > radius:
				continue
			var d := grass_density(p, near_blockers(p))
			if d <= 0.0:
				continue
			candidates.append(p)
			weights.append(d)
			total += d
	var k := float(clump_count) / maxf(total, 0.0001)
	var result: Array[Vector2] = []
	for i in candidates.size():
		var expected := weights[i] * k
		var count := floori(expected) + (1 if rng.randf() < expected - floorf(expected) else 0)
		for c in count:
			var p := candidates[i]
			if c > 0:
				p += Vector2(rng.randf() - 0.5, rng.randf() - 0.5) * GRASS_CELL
				if Scatter.is_blocked(p.x, p.y, near_blockers(p), 0.12):
					continue
			result.append(p)
	return result


func _build_grass(shape: TerrainShape) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var chunks := {}
	for p in _grass_points(rng):
		var spread := lerpf(1.0, periphery_tuft_scale, periphery_weight(p))
		var h := grass_height(p) * TUFT_HEIGHT_SCALE * spread * rng.randf_range(0.85, 1.15)
		if h / spread > TALL_TUFT:
			var tall_variant := LAWN_VARIANTS + rng.randi() % (TUFT_VARIANTS.size() - LAWN_VARIANTS)
			_push_tuft(chunks, shape, p, h, spread, tall_variant, Color(rng.randf(), rng.randf(), rng.randf(), 0.0), rng)
			continue
		# Kısa çayır: nokta LAWN_SPLIT küçük tutama bölünür (ince, sık doku; toplam yaprak sayısı aynı).
		for s in LAWN_SPLIT:
			var q := p
			if s > 0:
				q += Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.1, 0.22) * spread
				if grass_density(q, near_blockers(q)) <= 0.0:
					continue
			# Özel veri: r, g = ton (kullanılmıyor), b = yön sapması (atw_grass.gdshader).
			var custom := Color(rng.randf(), rng.randf(), rng.randf(), 0.0)
			_push_tuft(chunks, shape, q, h * rng.randf_range(0.9, 1.1), spread, rng.randi() % LAWN_VARIANTS, custom, rng)
	_emit_chunks(chunks, _grass_meshes(), _grass_material(), "Grass")


## Çimenin malzemesi ve tutam modelleri (TUFT_VARIANTS sırası): üretim de pişmiş örnekler de bunları kullanır.
func _grass_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = GRASS_SHADER
	mat.set_shader_parameter("instance_patches", true)
	return mat


func _grass_meshes() -> Array[Mesh]:
	var meshes: Array[Mesh] = []
	for i in TUFT_VARIANTS.size():
		var v := TUFT_VARIANTS[i]
		var lawn := i < LAWN_VARIANTS
		meshes.append(tuft_mesh(v.x, v.y, float(v.z) / 100.0, 1 if lawn else 2, BLADE_WIDTH.x if lawn else BLADE_WIDTH.y))
	return meshes


## Bir çimen tutamını kareye (chunk) ekler. custom: r, g, b atw_grass.gdshader'ın örnek verisi; a (renk lekesi)
## burada doldurulur. Tutamlar shader'da kameraya döner: örnek dönüşümünde dönme yoktur, yalnızca ölçek. Yatay
## ölçek boyla birlikte büyür (kısa tutamın yaprakları da incedir). Kareler tutam modeline göre de ayrılır: her
## MultiMesh tek bir model kullanır (uzak kenarın büyütülmüş kısa tutamları da kısa çayır modelini kullanır).
func _push_tuft(chunks: Dictionary, shape: TerrainShape, p: Vector2, h: float, spread: float, variant: int,
		custom: Color, rng: RandomNumberGenerator) -> void:
	var w := h * tuft_aspect(h / spread) * rng.randf_range(0.9, 1.15)
	var xform := Transform3D(Basis.IDENTITY.scaled(Vector3(w, h, w)), Vector3(p.x, shape.height_at(p.x, p.y) - 0.02, p.y))
	custom.a = clampf(_patch_noise.get_noise_2d(p.x, p.y) * 0.5 + 0.5, 0.0, 1.0)
	var key := Scatter.chunk_key(p.x, p.y, chunk_size)
	_push(chunks, Vector3i(key.x, key.y, variant), xform, custom)


func _build_flowers(shape: TerrainShape) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 101
	var cluster := TerrainShape._make_noise(seed_value + 5, 0.11, 2, FastNoiseLite.FRACTAL_FBM)
	var kinds := TerrainShape._make_noise(seed_value + 29, 0.07, 2, FastNoiseLite.FRACTAL_FBM)
	var chunks := {}
	var placed := 0
	var attempts := flower_count * 24
	while placed < flower_count and attempts > 0:
		attempts -= 1
		var p := Scatter.random_in_disk(rng, center, radius * 0.9)
		var clump := smoothstep(-0.15, 0.4, cluster.get_noise_2d(p.x, p.y))
		if rng.randf() * 2.6 > flower_weight(p, near_blockers(p)) * clump:
			continue
		var s := rng.randf_range(0.85, 1.2)
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * s)
		var xform := Transform3D(basis, Vector3(p.x, shape.height_at(p.x, p.y) - 0.01, p.y))
		var kind := flower_kind(rng.randf(), kinds.get_noise_2d(p.x, p.y))
		var key := Scatter.chunk_key(p.x, p.y, chunk_size)
		_push(chunks, Vector3i(key.x, key.y, flower_stem_variant(grass_height(p))), xform, Color(kind, rng.randf(), 0.0, 0.0))
		placed += 1
	_emit_chunks(chunks, _flower_meshes(), _flower_material(), "Flowers")


## Çiçeklerin malzemesi ve öbek modelleri (FLOWER_STEMS sırası).
func _flower_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = FLOWER_SHADER
	mat.set_shader_parameter("light_wrap", 0.6)
	return mat


func _flower_meshes() -> Array[Mesh]:
	var meshes: Array[Mesh] = []
	for stem in FLOWER_STEMS:
		meshes.append(flower_cluster(FLOWER_CLUSTER.x, FLOWER_CLUSTER.y, stem, 0.065))
	return meshes


## Çiçek türü (saf fonksiyon): çoğu beyaz; sarılar gürültünün yüksek olduğu yerlerde öbeklenir; birkaç mavi.
## roll: 0..1 rastgele sayı, patch: -1..1 gürültü.
static func flower_kind(roll: float, patch: float) -> float:
	var yellow := 0.12 + 0.45 * smoothstep(0.0, 0.45, patch)
	if roll < yellow:
		return FLOWER_YELLOW
	if roll > 0.92:
		return FLOWER_BLUE
	return FLOWER_WHITE


## Çimen boyuna uygun çiçek sapı (saf fonksiyon; FLOWER_STEMS sırası): başlar çimenin üst hizasında kalır.
static func flower_stem_variant(grass_h: float) -> int:
	return 1 if grass_h * 1.15 > (FLOWER_STEMS[0] + FLOWER_STEMS[1]) * 0.5 else 0


## Kareye örnek ekler. (Packed diziler kopyalanarak taşındığı için burada normal diziler tutulur.)
func _push(chunks: Dictionary, key: Vector3i, xform: Transform3D, custom: Color) -> void:
	if not chunks.has(key):
		var transforms: Array[Transform3D] = []
		chunks[key] = [transforms, []]
	(chunks[key][0] as Array).append(xform)
	(chunks[key][1] as Array).append(custom)


## Her kare için bir MultiMesh: anahtar Vector3i(kare x, kare z, model sırası). Pişirme aracı açıkken (MapBake.capture) karelerin
## ham dizileri de saklanır (bake_payload).
func _emit_chunks(chunks: Dictionary, meshes: Array[Mesh], material: Material, prefix: String) -> void:
	var captured: Array = []
	for key: Vector3i in chunks:
		var data: Array = chunks[key]
		var transforms: Array[Transform3D] = data[0]
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "%s_%d_%d_%d" % [prefix, key.x, key.y, key.z]
		mmi.multimesh = Scatter.make_multimesh(meshes[key.z], transforms, PackedColorArray(data[1]))
		mmi.material_override = material
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_add(mmi)
		if MapBake.capture:
			captured.append([key, MapBake.instance_buffer(transforms, data[1])])
	if MapBake.capture:
		_captured[prefix] = captured


## Pişmiş karelerden MultiMesh'ler (_emit_chunks'ın eşi): entries [[Vector3i anahtar, ham dizi (custom'lı)], ...], üretimdeki sırayla.
func _emit_buffers(entries: Array, meshes: Array[Mesh], material: Material, prefix: String) -> void:
	for entry: Array in entries:
		var key: Vector3i = entry[0]
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "%s_%d_%d_%d" % [prefix, key.x, key.y, key.z]
		mmi.multimesh = MapBake.multimesh_from(meshes[key.z], entry[1], true)
		mmi.material_override = material
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_add(mmi)


## Pişmiş örneklerin imzası (MapBake.signature_of): ayarlar ve değişmezler, engeller, kapı önleri, patikalar, biçimin örnek noktaları.
func bake_signature(shape: TerrainShape = null) -> String:
	var paths: Array = []
	if _paths:
		paths = [_paths.get_segments(), _paths.get_half_widths()]
	var src := shape if shape else TerrainShape.new(terrain_seed)
	return MapBake.signature_of(["meadow", MapBake.script_inputs(self), _blockers, _door_spots, paths, MapBake.probe_shape(src)])


## Son kurulumun örnekleri pişirilecek parça olarak (tools/bake_map.gd; yalnız MapBake.capture açıkken üretildiyse dolu).
func bake_payload() -> MapBake:
	var bake := MapBake.new()
	bake.kind = "meadow"
	bake.map_id = bake_id
	bake.signature = bake_signature()
	bake.data = {"grass": _captured.get("Grass", []), "flowers": _captured.get("Flowers", [])}
	return bake


func _add(node: Node) -> void:
	node.set_meta(&"generated", true)
	add_child(node)
