@tool
class_name RockField
extends Node3D
## Yosunlu gri kayalar (4. referans: gri granit, üstleri yeşil yosunlu):
##  - Kahraman kayalar (hero_rocks): Meshy kayaları (assets/nature/boulder_a büyük yuvarlak kaya,
##    boulder_b ikili yassı taş; MeshyProp ile), 4. referanstaki (assets/_reference/menu_camp.png) yerlerinde,
##    0,85–4,4 m boyunda (boyutlar referanstan ölçülür), gölgeli. Model yoksa prosedürel kaya çizilir.
##  - Çayıra serpiştirilmiş küçük kayalar: aynı Meshy kayalarının hafif sürümü (TreeKit.baked_lod: dokusu
##    köşe rengine işlenmiş, ~900 üçgen) MultiMesh ile; model yoksa prosedürel kaya.
##  - Vadi ve yamaç kayaları (MultiMesh): kampa yakın olanlar yine Meshy kayasının hafif sürümü, uzaktakiler
##    ucuz prosedürel kayalardır (köşe renkleri Meshy kayasının dokusundan ölçülen taş ve yosun renkleri);
##    hepsi serpiştirilmiş Meshy kayalarıyla aynı malzemeyi kullanır.
##  - Oyun alanının kenarlarındaki uzun, yuvarlak kaya kümeleri (formations): üstleri yosunlu, önleri dikey
##    çatlaklı gri taşlar; menü kadrajının dışında kalırlar.
##
## Kahraman kayalar ve kaya kümeleri serbest gezintide engeldir ("obstacles" grubu).
## Küme yerleşimi saf bir fonksiyondur (formation_layout); testler mesh üretmeden sınar.
## Not: Düğüm dünya başlangıcında (dönüşsüz) durmalıdır; kayalar arazi koordinatlarıyla yerleşir.
##
## Bütçe kesintileri (godot.md §7.5, K3: menü karesini değiştirmeyen, görünmeyen kesintiler; bütçe ölçümü
## 2026-11-05: kahraman kayalar görünürde 284k, gölgede 360k; uzak vadi kayaları her pozda 218k üçgen):
##  - Kahraman kayanın gölgesini, aynı kayanın birleştirilmiş ve sadeleştirilmiş ağı düşürür (yalnız gölge veren
##    kopya "Shadow", HERO_SHADOW_TRIANGLES üçgen); görünen dokulu model gölge vermez. Sade ağın sapması kayanın
##    boyunun ~%1'idir: yere ve kayanın kendi üstüne düşen gölge menü karesinde değişmez (ölçüldü).
##  - Çayıra serpiştirilmiş küçük kayalar (0,18–0,55 m) gölge düşürmez: gölgeleri birkaç piksellik lekedir.
##  - Vadi kayaları VALLEY_CHUNK'lık karelere bölünür: kadrajın dışındaki kareler çizilmez (tek MultiMesh bütün
##    vadiyi kaplıyor, her pozda çiziliyordu). FAR_ROCK_DISTANCE ötesindeki kayalar seyrek ikosferle çizilir.
##  - Kaya kümelerinin taşlarında motorun LOD zinciri vardır (with_lod_chain): ekrandaki hatası bir pikselin
##    altına inen sade düzey uzakta kendiliğinden seçilir.
##  - Kahraman kayaların dokulu ağına da LOD zinciri kurulur (hero_lod_mesh): içe aktarmanın zinciri işe yaramıyor
##    (normal birleştirme açısı 25°: tek düzey, %69 üçgen, hata 0,31 birim; motor hiç seçmez). 180° ile UV'si
##    korunan zincir ~%50'de 0,027 birim hatadadır: küçük ve uzak kayalar bir pikselin altında yarıya iner.

## Modelsiz yedek kayalar: "After the Wind" kaya malzemesi (gri-yosun renkleriyle).
const ROCK_SHADER := preload("res://shaders/atw_rock.gdshader")
## Kaya kümeleri ve serpiştirilmiş Meshy kayaları.
const FORMATION_SHADER := preload("res://shaders/rock_formation.gdshader")
## Kahraman kayanın engel yarıçapı / taban yarıçapı (oyuncu kayaya biraz sokulabilsin).
const HERO_OBSTACLE_SCALE := 0.85
## Küme taşının engel yarıçapı / taban yarı genişliği.
const STONE_OBSTACLE_SCALE := 0.92
## Taş türleri: büyük çatlaklı kubbe ve dar dilim ("parmak").
const KIND_DOME := 0
const KIND_SLICE := 1
## Her türden kaç farklı mesh üretilir (taşlar bunları paylaşır).
const VARIANTS := 4
## Meshy kayaları: büyük yuvarlak kaya ve bu boydan (metre) küçük kahraman kayalar için ikili yassı taş.
const BOULDER := "boulder_a"
const BOULDER_PAIR := "boulder_b"
const PAIR_MAX_SIZE := 1.0
## Kahraman kayanın zemine gömülme payı (boyuna oranla).
const HERO_SINK := 0.04
## Kahraman kayaların dikey uzatması: Meshy kayası referanstakilerden basıktır (yükseklik/genişlik 0,52);
## biraz yükseltilince 4. referanstaki yuvarlak kubbelere yaklaşır. En büyük kenar (genişlik) değişmez.
const HERO_RAISE := 1.18
## Serpiştirilmiş Meshy kayasının üçgen sayısı.
const SMALL_ROCK_TRIANGLES := 900
## Kahraman kayanın gölgesini düşüren sadeleştirilmiş kopyanın üçgen sayısı (Meshy kayası 11,8k–15,3k üçgendir).
const HERO_SHADOW_TRIANGLES := 7600
## Kahraman kayanın LOD zincirinde normal birleştirme açısı (derece; bkz. hero_lod_mesh).
const HERO_LOD_MERGE_ANGLE := 180.0
## Vadi kayalarının kare boyu (metre; vadi ormanının karesiyle aynı): her kare × çeşit bir çizimdir.
const VALLEY_CHUNK := 350.0
## Kamptan bu uzaklığın (metre) ötesindeki vadi kayaları seyrek ikosferle (FAR_ROCK_SUBDIVISIONS: 80 üçgen, 320
## yerine) çizilir: orada 1–4,5 m'lik kaya ekranda birkaç pikseldir. Yakındaki büyük kayalar (menü kadrajında kampın
## arkasındaki yamaç) tam kalır (denendi: hepsi seyrek olunca yamaçtaki kayaların kenarı 1–2 piksel kayıyordu).
const FAR_ROCK_DISTANCE := 400.0
const FAR_ROCK_SUBDIVISIONS := 1
## Kamptan bu uzaklığa (metre) kadar vadi kayaları da Meshy kayasının hafif sürümüdür (menüde kampın
## arkasındaki yamaçta görünürler); ötesindekiler ucuz prosedürel kayadır.
const NEAR_VALLEY_ROCKS := 170.0
## Meshy kayalarının dokusu krem-pembe taş ve sarı-yeşil yosundur; referanstaki gri granite ve yeşil yosuna
## yaklaştırmak için kırmızısı görece azaltılır (yosun yeşile, taş açık griye döner) ve biraz soldurulur
## (kahraman, serpiştirilmiş ve vadi kayalarında aynı).
const MESHY_TINT := Color(0.94, 1.08, 1.08)
const MESHY_SATURATION := 0.85
## Meshy kayasının (boulder_a) dokusundan ölçülen taş ve yosun renkleri (sRGB); vadi kayalarına işlenir.
const STONE_SRGB := Color(0.545, 0.482, 0.396)
const MOSS_SRGB := Color(0.455, 0.408, 0.114)
## Yedek kayaların gri-yosun renkleri (atw_rock.gdshader parametreleri, gündüz renkleri).
const GREY_ROCK_PARAMS := {
	"rock_color": Color(0.56, 0.56, 0.54), "blotch_color": Color(0.68, 0.68, 0.66),
	"speck_color": Color(0.34, 0.34, 0.33), "moss_color": Color(0.3, 0.4, 0.12),
	"moss_light": Color(0.46, 0.55, 0.2), "moss_amount": 0.4, "shadow_level": 0.62,
}

@export var seed_value := 5
@export var terrain_seed := 1207
## Büyük kayalar: Vector4(x, z, boyut (m, en büyük kenar), yön_derece).
## Konumlar 4. referanstan geri izdüşürülmüştür (tools/menu_camera_fit.json → kaya_R1 … kaya_R12): menü
## kamerasının önündeki büyük kayalar R1, R2, R3, R4, R6, R12; kampın arkasındaki çayırdakiler R7–R11; ardından
## referanstaki küçük kayalar. Boyutlar da referanstan ölçülmüştür (kayanın kadrajdaki genişliği / o noktada
## metrenin piksel boyu): kampın arkasındaki kayalar iri, yuvarlak granit kubbelerdir (R8 ~3,8 m, R10 ~4,4 m).
## 1 m'ye kadar olanlar ikili yassı taş (boulder_b) modeliyle çizilir.
@export var hero_rocks: Array[Vector4] = [
	Vector4(-8.19, 1.38, 3.2, 24.0), # R1
	Vector4(-3.87, 3.08, 2.25, 137.0), # R2
	Vector4(1.05, 5.11, 3.2, 211.0), # R3
	Vector4(5.82, 2.08, 2.05, 302.0), # R4
	Vector4(4.53, 3.33, 1.05, 61.0), # R5 (patikanın yanında)
	Vector4(-4.95, 4.62, 1.15, 255.0), # R6
	Vector4(-12.81, -6.73, 2.8, 168.0), # R7
	Vector4(-2.12, -15.96, 3.8, 84.0), # R8
	Vector4(6.94, -23.43, 3.1, 329.0), # R9
	Vector4(12.23, -33.66, 4.4, 12.0), # R10
	Vector4(-3.66, -11.74, 2.1, 193.0), # R11
	Vector4(6.72, 5.17, 1.9, 118.0), # R12
	Vector4(-3.36, 4.66, 0.85, 31.0), # R6'nın sağındaki ikili taş
	Vector4(-1.09, 4.52, 0.9, 286.0), # alt ortadaki yassı taşlar
	Vector4(-13.92, -10.93, 1.6, 147.0), # sol arkadaki kayalar
	Vector4(-13.03, -13.28, 1.4, 74.0),
	Vector4(-7.4, -19.6, 1.8, 232.0), # sol yurdun arkasındaki çayırda
	Vector4(-4.45, -23.16, 1.3, 348.0),
	Vector4(9.3, -34.4, 1.5, 70.0), # R10'un solundaki küçük kaya
]
## Kaya kümeleri: Vector4(x, z, ölçek, yön_derece). Yön, kümenin ön yüzünün (yerel +Z) baktığı açıdır:
## 0 = +Z, 90 = +X. Kümeler menü kamerasının (scenes/main.tscn) görüş alanının dışındadır; ön yüzleri
## yanlarından geçen patikaya ve güneydeki oyun kamerasına döner. Güneydoğudaki iki küme ana patikanın
## iki yanındadır (patika aralarından geçer).
## Oyun kamerası varsayılan olarak kuzeye (-Z) baktığı için kümeler ağaçların ÖNÜNE (güneyine) konur;
## böylece patikada yürürken çam dalları ne kümeyi ne de karakteri örter.
@export var formations: Array[Vector4] = [
	Vector4(-20.6, 2.3, 1.0, 18.0), # Solda, kampın batısında.
	Vector4(22.6, 2.2, 1.0, -58.0), # Sağda, ahır yolunun doğusunda.
	Vector4(15.0, 9.0, 0.85, -42.0), # Ana patikanın doğusunda (önü patikaya döner).
	Vector4(8.4, 21.2, 1.0, 75.0), # Ana patikanın batısında (önü patikaya döner).
]
@export var formation_seed := 71
@export var meadow_rocks := 70
@export var meadow_radius := 32.0
@export var valley_rocks := 700
## Küçük kayalar patika kenarına bu kadar yaklaşmasın (metre).
@export var path_clearance := 0.35
@export_tool_button("Yeniden oluştur", "Reload") var rebuild_button: Callable = rebuild

## Kaya kümelerinin ortak malzemesi (kamera örtme bilgisi buna yazılır).
var _formation_material: ShaderMaterial
## Kahraman kayaların LOD zincirli ağları (kaynak ağ → kopya; bkz. hero_lod_mesh).
static var _hero_lods := {}
## Prosedürel (yedek) kahraman kaya meshleri ve ölçülmüş ortalama taban yarıçapları (ilk istekte üretilir).
var _hero_meshes: Array[Mesh] = []
var _hero_radii := PackedFloat32Array()
## Yarıçapların hesaplandığı hero_rocks verisi (değişince önbellek yenilenir).
var _hero_radii_source: Array[Vector4] = []


func _ready() -> void:
	add_to_group(World.OBSTACLE_GROUP)
	add_to_group(FollowCamera.OCCLUDER_GROUP)
	rebuild.call_deferred()


## FollowCamera her karede çağırır: kamera ile karakter arasındaki kaya parçaları noktalı (dither)
## biçimde saydamlaşır; uzun kayaların arkasına geçen karakter kaybolmaz.
func set_camera_occlusion(camera_position: Vector3, target_position: Vector3) -> void:
	if _formation_material == null:
		return
	_formation_material.set_shader_parameter("occlusion_from", camera_position)
	_formation_material.set_shader_parameter("occlusion_to", target_position)


## Serbest gezintide içinden geçilemeyen daireler: Vector3(x, z, yarıçap).
## Kahraman kayalar ve kaya kümelerinin her taşı ayrı bir dairedir.
func get_obstacle_circles() -> Array[Vector3]:
	var result: Array[Vector3] = []
	for i in hero_rocks.size():
		var r := hero_rocks[i]
		result.append(Vector3(r.x, r.y, hero_radius(i) * HERO_OBSTACLE_SCALE))
	for i in formations.size():
		for stone in formation_layout(formations[i], formation_seed + i * 101):
			result.append(stone_circle(stone))
	return result


## i. kahraman kayanın taban yarıçapı (metre): Meshy modeli varsa model kutusundan (MeshyProp ile aynı
## ölçü), yoksa prosedürel meshten ölçülür. Kayalar kurulmadan önce de doğru değeri verir.
func hero_radius(i: int) -> float:
	var r := hero_rocks[i]
	var model := TreeKit.load_model(hero_model(r.z))
	if not model.is_empty():
		return meshy_footprint(model["aabb"], r.z)
	return _hero_footprints()[i]


## Bu boydaki (metre) kahraman kaya hangi Meshy modeliyle çizilir? (saf fonksiyon)
static func hero_model(size: float) -> String:
	return BOULDER_PAIR if size <= PAIR_MAX_SIZE else BOULDER


## En büyük kenarı size metre olacak şekilde ölçeklenen modelin taban yarıçapı (MeshyProp ile aynı ölçü:
## x/z kenarlarının yarısının ortalaması; saf fonksiyon).
static func meshy_footprint(box: AABB, size: float) -> float:
	var s := MeshyProp.fit_scale(box, size, MeshyProp.SizeAxis.LONGEST)
	return (box.size.x + box.size.z) * 0.25 * s


func rebuild() -> void:
	for child in get_children():
		if child.has_meta(&"generated"):
			remove_child(child)
			child.queue_free()
	var shape := TerrainShape.new(terrain_seed)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var grey := _grey_rock_material()
	_build_heroes(shape, grey)
	_build_formations(shape)
	_build_scatter(shape, rng, grey)


# --- Kahraman kayalar -----------------------------------------------------------

## Kahraman kayaları kurar: Meshy modeli varsa MeshyProp, yoksa prosedürel kaya.
func _build_heroes(shape: TerrainShape, fallback: ShaderMaterial) -> void:
	for i in hero_rocks.size():
		var r := hero_rocks[i]
		var id := hero_model(r.z)
		var ground := footprint_ground(shape, Vector2(r.x, r.y), r.z * 0.4)
		if MeshyProp.exists(TreeKit.FOLDER, id):
			var prop := MeshyProp.new()
			prop.name = "HeroRock%d" % i
			prop.folder = TreeKit.FOLDER
			prop.model_id = id
			prop.size_axis = MeshyProp.SizeAxis.LONGEST
			prop.target_size = r.z
			prop.sink = r.z * HERO_SINK
			prop.tint = MESHY_TINT
			prop.ink_strength = 0.2
			prop.set_shader_parameter("saturation", MESHY_SATURATION)
			var raise := HERO_RAISE if id == BOULDER else 1.0
			prop.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(r.w)) * Basis.from_scale(Vector3(1.0, raise, 1.0)), Vector3(r.x, ground, r.y))
			var shadow_mesh := TreeKit.baked_lod(id, HERO_SHADOW_TRIANGLES, Color(0.55, 0.53, 0.48), 0.0)
			# Ağaca girmeden önce: ayar değişince model yeniden kurulmasın.
			prop.cast_shadows = shadow_mesh == null
			_add(prop)
			var model := prop.get_node_or_null(^"Model") as Node3D
			if model:
				for mi in model.find_children("*", "MeshInstance3D", true, false):
					(mi as MeshInstance3D).mesh = hero_lod_mesh((mi as MeshInstance3D).mesh)
			if shadow_mesh and model:
				prop.add_child(shadow_proxy(shadow_mesh, model.transform))
			elif shadow_mesh:
				prop.cast_shadows = true
		else:
			var mi := MeshInstance3D.new()
			mi.name = "HeroRock%d" % i
			mi.mesh = _hero_mesh(i)
			mi.material_override = fallback
			mi.transform = Transform3D(fallback_basis(_hero_mesh(i).get_aabb(), r), Vector3(r.x, ground, r.y))
			_add(mi)


## Yalnız gölge veren kopya (saf): verilen ağ, modelin dönüşümüyle; görünmez, yalnız gölge geçişine girer.
static func shadow_proxy(mesh: Mesh, xform: Transform3D) -> MeshInstance3D:
	var proxy := MeshInstance3D.new()
	proxy.name = "Shadow"
	proxy.mesh = mesh
	proxy.transform = xform
	proxy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	return proxy


## Kahraman kayanın dokulu ağının LOD zincirli kopyası (bir kez kurulur, aynı ağı kullanan kayalar paylaşır):
## yüzeyler, malzemeler ve UV aynıdır; düzeyler normal birleştirme açısı 180° ile üretilir (bkz. dosyanın başı).
static func hero_lod_mesh(source: Mesh) -> Mesh:
	if source == null or not source is ArrayMesh:
		return source
	if _hero_lods.has(source):
		return _hero_lods[source]
	var importer := ImporterMesh.new()
	for s in source.get_surface_count():
		importer.add_surface(Mesh.PRIMITIVE_TRIANGLES, source.surface_get_arrays(s), [], {}, source.surface_get_material(s))
	importer.generate_lods(HERO_LOD_MERGE_ANGLE, 60.0, [])
	var mesh := importer.get_mesh()
	_hero_lods[source] = mesh
	return mesh


## Kodla kurulan kapalı ağa motorun LOD zincirini ekler (saf; godot.md §4.6: ImporterMesh.generate_lods):
## motor her örnek için ekrandaki hatası bir pikselin altında kalan en sade düzeyi seçer, yakında tam ağ çizilir.
static func with_lod_chain(mesh: ArrayMesh) -> ArrayMesh:
	var importer := ImporterMesh.new()
	importer.add_surface(Mesh.PRIMITIVE_TRIANGLES, mesh.surface_get_arrays(0))
	importer.generate_lods(60.0, 60.0, [])
	return importer.get_mesh()


## Kayanın oturacağı zemin: taban çevresindeki en alçak nokta (eğimde kaya havada kalmaz; saf fonksiyon).
static func footprint_ground(shape: TerrainShape, p: Vector2, reach: float) -> float:
	var ground := shape.height_at(p.x, p.y)
	for k in 6:
		var a := TAU * float(k) / 6.0
		ground = minf(ground, shape.height_at(p.x + cos(a) * reach, p.y + sin(a) * reach))
	return ground


## Prosedürel (yedek) kahraman kayanın dönüşüm tabanı (saf fonksiyon): Meshy kayası gibi en büyük kenarı
## r.z metredir (MeshKit.rock yaklaşık 2–3 birim genişliğindedir; boyut doğrudan ölçek olarak kullanılırsa
## kaya 2–3 kat büyük çıkar). box: prosedürel meshin kutusu; r: hero_rocks öğesi.
static func fallback_basis(box: AABB, r: Vector4) -> Basis:
	var s := MeshyProp.fit_scale(box, r.z, MeshyProp.SizeAxis.LONGEST)
	return Basis(Vector3.UP, deg_to_rad(r.w)).scaled(Vector3(s, s, s))


## Prosedürel kahraman kayaların taban yarıçapı: 16 yöndeki en uzak noktanın ortalaması (mesh'ten ölçülür).
func _hero_footprints() -> PackedFloat32Array:
	if _hero_radii_source == hero_rocks and _hero_radii.size() == hero_rocks.size():
		return _hero_radii
	_hero_radii_source = hero_rocks.duplicate()
	_hero_radii = PackedFloat32Array()
	for i in hero_rocks.size():
		var verts: PackedVector3Array = _hero_mesh(i).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		_hero_radii.append(mean_extent(verts, fallback_basis(_hero_mesh(i).get_aabb(), hero_rocks[i])))
	return _hero_radii


## i. kahraman kayanın prosedürel meshi (tohum 200 + i; bir kez üretilir).
func _hero_mesh(i: int) -> Mesh:
	while _hero_meshes.size() <= i:
		_hero_meshes.append(MeshKit.rock(200 + _hero_meshes.size(), 3, 0.3))
	return _hero_meshes[i]


## Köşelerin yatay düzlemdeki ortalama uzanımı (16 yönün en uzak noktalarının ortalaması).
static func mean_extent(verts: PackedVector3Array, p_basis: Basis) -> float:
	var total := 0.0
	for k in 16:
		var a := TAU * float(k) / 16.0
		var dir := Vector2(cos(a), sin(a))
		var best := 0.0
		for v in verts:
			var p := p_basis * v
			best = maxf(best, Vector2(p.x, p.z).dot(dir))
		total += best
	return total / 16.0


# --- Serpiştirilmiş kayalar ---------------------------------------------------------

## Çayır kayaları (Meshy kayalarının hafif sürümü) ve vadi/yamaç kayaları (yakında Meshy, uzakta prosedürel).
## Çayır kayaları engellerin ve patikaların üstüne düşmez.
func _build_scatter(shape: TerrainShape, rng: RandomNumberGenerator, grey: ShaderMaterial) -> void:
	var blockers := Meadow.collect_blockers(get_tree())
	var paths := PathNetwork.find_in_tree(get_tree())
	var small := _small_rock_meshes()
	var small_material := _baked_rock_material() if small.size() > 0 else grey
	if small.is_empty():
		small = [MeshKit.rock(301, 2, 0.35), MeshKit.rock(302, 2, 0.3), MeshKit.rock(303, 2, 0.4)]
	var small_boxes: Array[AABB] = []
	for mesh in small:
		small_boxes.append(mesh.get_aabb())
	var buckets: Array = []
	for v in small.size():
		buckets.append([] as Array[Transform3D])
	for i in meadow_rocks:
		var p := Scatter.random_in_disk(rng, Vector2(0.0, -4.0), meadow_radius)
		if p.length() < 4.0 or Scatter.is_blocked(p.x, p.y, blockers, 0.5):
			continue
		if paths and paths.distance_to_paths_clamped(p, path_clearance + 0.5) < path_clearance:
			continue
		var v := i % small.size()
		var size := rng.randf_range(0.18, 0.55)
		(buckets[v] as Array[Transform3D]).append(scatter_transform(shape, p, size, rng.randf() * TAU, rng.randf_range(0.75, 1.0), small_boxes[v]))
	# Küçük kayalar gölge düşürmez (birkaç piksellik gölgeleri menü karesinde görünmez; bütçe: gölgede 50–100k üçgen).
	for v in small.size():
		_add_multimesh("Rocks%d" % v, small[v], buckets[v], small_material, false)
	# Vadi ve yamaç kayaları: dik yamaçları tercih eder (kayalık yamaçlar), suya inmez. Kampa yakın olanlar
	# (menüde kampın arkasındaki yamaçta görünenler) Meshy kayasının hafif sürümüdür, uzaktakiler prosedürel.
	# Çeşitler 0–2 orta uzaklıkta (FAR_ROCK_DISTANCE'a dek), 3–5 aynı kayaların seyrek ikosferli sürümü (daha uzakta).
	var far_rocks: Array[Mesh] = []
	for sub in [2, FAR_ROCK_SUBDIVISIONS]:
		far_rocks.append_array([painted_rock(MeshKit.rock(301, sub, 0.35), 41), painted_rock(MeshKit.rock(302, sub, 0.3), 42),
				painted_rock(MeshKit.rock(303, sub, 0.4), 43)])
	var near_rocks := _small_rock_meshes()
	var valley_material := _baked_rock_material()
	# Kareler: Vector3i(kare x, kare z, çeşit) → dönüşümler; uzak (prosedürel) ve yakın (Meshy) ayrı.
	var far_chunks := {}
	var near_chunks := {}
	var placed := 0
	var guard := valley_rocks * 6
	while placed < valley_rocks and guard > 0:
		guard -= 1
		var p := Vector2(rng.randf_range(-700.0, 700.0), rng.randf_range(-1400.0, -30.0))
		var h := shape.height_at(p.x, p.y)
		if h < TerrainShape.WATER_LEVEL + 0.5:
			continue
		var steep := Vector2(shape.height_at(p.x + 2.0, p.y) - h, shape.height_at(p.x, p.y + 2.0) - h).length() / 2.0
		if steep < 0.35 and rng.randf() > 0.15:
			continue
		var size := rng.randf_range(1.0, 4.5)
		var yaw := rng.randf() * TAU
		var flatten := rng.randf_range(0.75, 1.0)
		placed += 1
		var c := Scatter.chunk_key(p.x, p.y, VALLEY_CHUNK)
		if not near_rocks.is_empty() and p.length() < NEAR_VALLEY_ROCKS:
			var v := placed % near_rocks.size()
			_push_chunk(near_chunks, Vector3i(c.x, c.y, v), scatter_transform(shape, p, size, yaw, flatten, near_rocks[v].get_aabb()))
		else:
			# Prosedürel kaya ~2,5 birim geniştir (yarıçap ≈ 1,25 × size); dik yamaçta yokuş aşağı kenarı havada
			# kalmasın diye taban, kayanın altındaki en alçak zemine oturur.
			var rock_basis := Basis(Vector3.UP, yaw).scaled(Vector3(size, size * flatten, size))
			var ground := footprint_ground(shape, p, size)
			_push_chunk(far_chunks, Vector3i(c.x, c.y, placed % 3 + valley_rock_tier(p)), Transform3D(rock_basis, Vector3(p.x, ground - size * 0.1, p.y)))
	for key: Vector3i in far_chunks:
		_add_multimesh("ValleyRocks%d_%d_%d" % [key.z, key.x, key.y], far_rocks[key.z], far_chunks[key], valley_material, false)
	for key: Vector3i in near_chunks:
		_add_multimesh("ValleyRocksNear%d_%d_%d" % [key.z, key.x, key.y], near_rocks[key.z], near_chunks[key], valley_material, false)


## Uzak vadi kayasının çeşit kaydırması (saf): FAR_ROCK_DISTANCE ötesinde seyrek ikosferli çeşitler (3–5), berisinde
## tam çeşitler (0–2).
static func valley_rock_tier(p: Vector2) -> int:
	return 3 if p.length() > FAR_ROCK_DISTANCE else 0


## Kayayı karesine ekler (kare yoksa açılır): anahtar Vector3i(kare x, kare z, çeşit).
static func _push_chunk(chunks: Dictionary, key: Vector3i, xform: Transform3D) -> void:
	if not chunks.has(key):
		chunks[key] = [] as Array[Transform3D]
	(chunks[key] as Array[Transform3D]).append(xform)


## Prosedürel kayaya Meshy kayasının renklerini işler (saf fonksiyon): yukarı bakan yüzlerde yosun,
## yanlarda gürültüyle açılıp koyulaşan taş. Köşe rengi sRGB, alfa 0 (rock_formation.gdshader köşe rengi
## kipi; Meshy kayalarıyla aynı doku tonu uygulanır).
static func painted_rock(mesh: ArrayMesh, rng_seed: int) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var noise := FastNoiseLite.new()
	noise.seed = rng_seed
	noise.frequency = 1.6
	var colors := PackedColorArray()
	colors.resize(verts.size())
	for i in verts.size():
		var n := noise.get_noise_3dv(verts[i]) * 0.5 + 0.5
		var moss := smoothstep(0.35, 0.75, normals[i].y + (n - 0.5) * 0.7)
		var stone := STONE_SRGB * lerpf(0.78, 1.12, n)
		var c := stone.lerp(MOSS_SRGB, moss * 0.9)
		colors[i] = Color(c.r, c.g, c.b, 0.0)
	arrays[Mesh.ARRAY_COLOR] = colors
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


## Serpiştirilmiş kayanın dünya dönüşümü: model kutusunun tabanı zemine oturur ve biraz gömülür; en büyük
## kenarı size metredir, yüksekliği flatten oranında basıktır (saf fonksiyon).
static func scatter_transform(shape: TerrainShape, p: Vector2, size: float, yaw: float, flatten: float, box: AABB) -> Transform3D:
	var s := size / maxf(maxf(box.size.x, box.size.z), 0.0001)
	var rock_basis := Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3(s, s * flatten, s))
	var bottom := Vector3(box.get_center().x, box.position.y, box.get_center().z)
	var ground := footprint_ground(shape, p, size * 0.4) - size * 0.08
	return Transform3D(rock_basis, Vector3(p.x, ground, p.y) - rock_basis * bottom)


## Meshy kayalarının hafif sürümleri (modeller yoksa boş).
func _small_rock_meshes() -> Array[Mesh]:
	var result: Array[Mesh] = []
	for id in [BOULDER, BOULDER_PAIR]:
		var mesh := TreeKit.baked_lod(id, SMALL_ROCK_TRIANGLES, Color(0.55, 0.53, 0.48), 0.0)
		if mesh:
			result.append(mesh)
	return result


## Serpiştirilmiş Meshy kayalarının malzemesi: kahraman kayalarla aynı doku tonu.
func _baked_rock_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = FORMATION_SHADER
	mat.set_shader_parameter("use_vertex_albedo", true)
	mat.set_shader_parameter("albedo_tint", MESHY_TINT)
	mat.set_shader_parameter("saturation", MESHY_SATURATION)
	return mat


## Modelsiz yedek kayaların malzemesi (atw_rock, gri granit + yeşil yosun).
func _grey_rock_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = ROCK_SHADER
	for param: String in GREY_ROCK_PARAMS:
		mat.set_shader_parameter(param, GREY_ROCK_PARAMS[param])
	return mat


func _add_multimesh(node_name: String, mesh: Mesh, transforms: Array[Transform3D], material: Material, shadows: bool) -> void:
	if transforms.is_empty():
		return
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = Scatter.make_multimesh(mesh, transforms)
	mmi.material_override = material
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add(mmi)


# --- Kaya kümeleri ------------------------------------------------------------

## Bir kaya kümesinin taşlarını üretir (saf ve belirlenimci; mesh üretmez).
## data: Vector4(x, z, ölçek, yön_derece). Her öğe bir sözlüktür:
##   "position": Vector2 (dünya x, z) · "size": Vector3 (genişlik, yükseklik, derinlik, metre)
##   "yaw": float (radyan) · "kind": KIND_DOME / KIND_SLICE · "variant": 0..VARIANTS-1
## Yerel düzen: arkada üç uzun kubbe, önlerinde dilimli "parmak" bloklar, en önde küçük dilimler.
static func formation_layout(data: Vector4, layout_seed: int) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = layout_seed
	var stones: Array[Dictionary] = []
	# 1) Arka sıra: yan yana dizilmiş, birbirine hafifçe gömülen üç büyük kubbe (ortadaki en uzun).
	var widths := [rng.randf_range(2.4, 2.8), rng.randf_range(2.6, 3.0), rng.randf_range(2.3, 2.7)]
	var total := 0.0
	for w in widths:
		total += w - 0.35
	var u := -total * 0.5
	for k in 3:
		var w: float = widths[k]
		var h := rng.randf_range(2.5, 2.9) + (0.5 if k == 1 else 0.0)
		var d := rng.randf_range(2.2, 2.6)
		var v := -0.9 + rng.randf_range(-0.3, 0.3) - (0.25 if k == 1 else 0.0)
		stones.append(_local_stone(Vector2(u + w * 0.5, v), Vector3(w, h, d), rng.randf_range(-0.15, 0.15), KIND_DOME, rng.randi() % VARIANTS))
		u += w - 0.35
	# 2) Orta sıra: kubbelerin önünde 3-4 dilimden oluşan iki blok.
	for center_u in [-1.25, 1.35]:
		var slices := 3 + rng.randi() % 2
		var block_w := rng.randf_range(1.6, 2.0)
		var block_h := rng.randf_range(1.45, 1.95)
		var depth := rng.randf_range(1.15, 1.45)
		_add_slices(stones, rng, Vector2(center_u + rng.randf_range(-0.2, 0.2), 0.55 + rng.randf_range(-0.1, 0.15)),
				slices, block_w, block_h, depth)
	# 3) Ön sıra: yanlarda alçak, küçük dilimler.
	for side in [-1.0, 1.0]:
		if rng.randf() < 0.25:
			continue
		var slices := 2 + rng.randi() % 2
		_add_slices(stones, rng, Vector2(side * rng.randf_range(2.6, 3.1), 1.15 + rng.randf_range(-0.15, 0.2)),
				slices, rng.randf_range(1.0, 1.3), rng.randf_range(0.7, 1.05), rng.randf_range(0.85, 1.05))
	# Yerel düzeni dünyaya taşı: döndür, ölçekle, kaydır.
	var center := Vector2(data.x, data.y)
	var stone_scale := data.z
	var yaw := deg_to_rad(data.w)
	var c := cos(yaw)
	var s := sin(yaw)
	for stone in stones:
		var local: Vector2 = stone["position"] * stone_scale
		stone["position"] = center + Vector2(local.x * c + local.y * s, -local.x * s + local.y * c)
		stone["size"] = (stone["size"] as Vector3) * stone_scale
		stone["yaw"] = float(stone["yaw"]) + yaw
	return stones


## Taşın engel dairesi: Vector3(x, z, yarıçap).
static func stone_circle(stone: Dictionary) -> Vector3:
	var p: Vector2 = stone["position"]
	var size: Vector3 = stone["size"]
	return Vector3(p.x, p.y, maxf(size.x, size.z) * 0.5 * STONE_OBSTACLE_SCALE)


## Küme taşı: tabanı düz, alt yarısı dike yakın, tepesi yuvarlak bir "somun".
## Birim boyutludur (genişlik/derinlik 1, yükseklik 1, taban y≈0); örnek başına ölçeklenir.
## cracks: ön, üst ve arka yüzde dikey çatlak sayısı (0 = çatlaksız dilim).
## Köşe rengi: r = çatlak derinliği, g = dilim tonu (0..1), b = yükseklik (0 taban, 1 tepe).
static func boulder_mesh(rng_seed: int, cracks: int, subdivisions: int = 4, boxiness: float = 0.56) -> ArrayMesh:
	var data := MeshKit.icosphere_data(subdivisions)
	var verts: PackedVector3Array = data[0]
	var indices: PackedInt32Array = data[1]
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var lumps := FastNoiseLite.new()
	lumps.seed = rng_seed
	lumps.frequency = 1.15
	lumps.fractal_octaves = 3
	var bumps := FastNoiseLite.new()
	bumps.seed = rng_seed + 13
	bumps.frequency = 3.6
	bumps.fractal_octaves = 2
	var dome := rng.randf_range(0.95, 1.1)
	var taper := rng.randf_range(0.82, 0.92)
	var lean := Vector2(rng.randf_range(-0.05, 0.05), rng.randf_range(-0.05, 0.02))
	var crack_x := PackedFloat32Array()
	for k in cracks:
		var base := lerpf(-0.55, 0.55, (float(k) + 0.5) / float(cracks)) if cracks > 1 else 0.0
		crack_x.append(base + rng.randf_range(-0.1, 0.1))
	var tints := PackedFloat32Array()
	for k in cracks + 1:
		tints.append(rng.randf())
	var colors := PackedColorArray()
	colors.resize(verts.size())
	for i in verts.size():
		var v := verts[i]
		# 1) Köşeleri yuvarlatılmış kutu kesiti (boxiness < 1 köşelere doğru şişirir);
		#    tepeye doğru kesit yuvarlaklaşır, böylece taşın üstü kubbe gibi olur.
		var e := lerpf(boxiness, 0.95, smoothstep(0.25, 0.95, v.y))
		var x := signf(v.x) * pow(absf(v.x), e)
		var z := signf(v.z) * pow(absf(v.z), e)
		# 2) Dikey profil: alt yarı dik yanlı, üst yarı kubbe. h: 0 taban, 1 tepe.
		var y := pow(v.y, dome) if v.y >= 0.0 else -pow(-v.y, 0.42)
		var h := clampf((y + 1.0) * 0.5, 0.0, 1.0)
		var narrow := lerpf(1.0, taper, smoothstep(0.35, 1.0, h))
		var p := Vector3(x * 0.5 * narrow + lean.x * h * h, h, z * 0.5 * narrow + lean.y * h * h)
		# 3) Büyük topaklar ve küçük yumrular (taban düz kalsın diye alta doğru söner).
		var outward := Vector3(x, (h - 0.4) * 0.9, z).normalized()
		var bump := lumps.get_noise_3dv(v) * 0.075 + bumps.get_noise_3dv(v) * 0.022
		p += outward * bump * smoothstep(0.0, 0.18, h)
		# 4) Dikey çatlaklar: yan yüzler (±x) dışında her yerde içe doğru V biçimli oluk.
		var groove := 0.0
		var slice := 0
		for k in crack_x.size():
			groove = maxf(groove, pow(1.0 - smoothstep(0.0, 0.17, absf(x - crack_x[k])), 2.0))
			if x > crack_x[k]:
				slice = k + 1
		groove *= 1.0 - v.x * v.x
		p -= outward * groove * 0.075
		# 5) Düz taban, hafifçe toprağa gömülü.
		if h < 0.035:
			p.y = 0.0
		p.y -= 0.04
		verts[i] = p
		colors[i] = Color(groove, tints[slice], h, 1.0)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = MeshKit.smooth_normals(verts, indices)
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Kümeleri kurar: taşlar ortak meshleri paylaşır, her biri kendi boyutu ve yönüyle yerleşir.
func _build_formations(shape: TerrainShape) -> void:
	_formation_material = null
	if formations.is_empty():
		return
	var mat := ShaderMaterial.new()
	mat.shader = FORMATION_SHADER
	mat.set_shader_parameter("occlusion_radius", 1.4)
	mat.set_shader_parameter("atw_shadow_level", 0.62)
	mat.set_shader_parameter("atw_softness", 0.3)
	_formation_material = mat
	var pool: Array = [[], []]
	for v in VARIANTS:
		pool[KIND_DOME].append(with_lod_chain(boulder_mesh(500 + v, 2 + v % 2, 4)))
		pool[KIND_SLICE].append(with_lod_chain(boulder_mesh(600 + v, 0, 3, 0.48)))
	for i in formations.size():
		var root := Node3D.new()
		root.name = "Formation%d" % i
		_add(root)
		var stones := formation_layout(formations[i], formation_seed + i * 101)
		for j in stones.size():
			var stone := stones[j]
			var mi := MeshInstance3D.new()
			mi.name = "Stone%d" % j
			mi.mesh = pool[int(stone["kind"])][int(stone["variant"])]
			mi.material_override = mat
			mi.transform = stone_transform(stone, shape)
			root.add_child(mi)


## Taşın dünya dönüşümü: taban, ayak izindeki en alçak zemin noktasına oturur (eğimde havada kalmaz).
static func stone_transform(stone: Dictionary, shape: TerrainShape) -> Transform3D:
	var p: Vector2 = stone["position"]
	var size: Vector3 = stone["size"]
	var yaw := float(stone["yaw"])
	var reach := maxf(size.x, size.z) * 0.45
	var ground := shape.height_at(p.x, p.y)
	for k in 6:
		var a := TAU * float(k) / 6.0
		ground = minf(ground, shape.height_at(p.x + cos(a) * reach, p.y + sin(a) * reach))
	var stone_basis := Basis(Vector3.UP, yaw) * Basis.from_scale(size)
	return Transform3D(stone_basis, Vector3(p.x, ground - size.y * 0.03, p.y))


static func _local_stone(pos: Vector2, size: Vector3, yaw: float, kind: int, variant: int) -> Dictionary:
	return {"position": pos, "size": size, "yaw": yaw, "kind": kind, "variant": variant}


## Bir bloğu yan yana dilimlere böler (aralarındaki ince boşluklar derin çatlak gibi görünür).
static func _add_slices(stones: Array[Dictionary], rng: RandomNumberGenerator, center: Vector2, count: int,
		width: float, height: float, depth: float) -> void:
	var slice_w := width / float(count)
	var block_yaw := rng.randf_range(-0.18, 0.18)
	var c := cos(block_yaw)
	var s := sin(block_yaw)
	for k in count:
		var offset := (float(k) - float(count - 1) * 0.5) * slice_w
		var local := Vector2(offset * c, -offset * s)
		var h := height * rng.randf_range(0.84, 1.0)
		var size := Vector3(slice_w * rng.randf_range(1.0, 1.08), h, depth * rng.randf_range(0.9, 1.05))
		stones.append(_local_stone(center + local, size, block_yaw + rng.randf_range(-0.06, 0.06), KIND_SLICE, rng.randi() % VARIANTS))


func _add(node: Node) -> void:
	node.set_meta(&"generated", true)
	add_child(node)
