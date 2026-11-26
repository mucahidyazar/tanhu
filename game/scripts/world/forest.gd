@tool
class_name Forest
extends Node3D
## Çamlar: kampın çevresi, menü kadrajının kenarları, yamaçlar ve vadiye yayılan orman.
##
## Üç katman; hepsi aynı foliage malzemesiyle (aynı ışık, boya ve renk ayarı) çizilir:
##  1) Kamp çamları (camp_trees): Meshy ladinleri (assets/nature/pine_b; isteğe bağlı pine_a),
##     4. referanstaki (assets/_reference/menu_camp.png) yerlerinde.
##  2) Çam kümeleri (groves): menü kadrajının sol ve sağ kenarlarında, kampın arkasında ve yamaçlarda sık,
##     koyu ladin kümeleri (yine Meshy ladinleri).
##     Kamp ve küme çamlarının her biri ayrı bir MeshInstance3D'dir: mesh, Meshy modelinin birleştirilmiş
##     (dokusu köşe rengine işlenmiş) sürümüdür ve LOD zinciri gömülüdür (TreeKit.lod_chain); motor her ağaç
##     için ekrandaki boyuna göre düzey seçer. Yalnızca kampa yakın olanlar gölge düşürür.
##  3) Vadi ormanı: TerrainShape.forest_density() lekelerine dağılmış ucuz prosedürel ladinler
##     (TreeKit.spruce, karelere bölünmüş MultiMesh; siluet ve renkler Meshy ladinine uydurulmuştur).
##
## Kümelerdeki ağaçlar patikalara, kamp nesnelerine ve kayalara girmez; takip kamerasının varsayılan
## açısından (yaw 0, 50°, 9 m) patikadaki oyuncuyu örtmez. Kamp ve küme çamlarının ve oyun alanına ulaşan vadi
## ağaçlarının gövdeleri serbest gezintide engeldir; oyuncuyla kamera arasında kalan dallar noktalı biçimde
## saydamlaşır (FollowCamera örtme grubu).
## Meshy modelleri yoksa bütün çamlar prosedürel ladinle çizilir.
##
## Not: Meshy'nin uzun ladini (pine_a) seyrek, çıplak dallı çıktı; bu yüzden uzun çamlar da varsayılan olarak
## dikeyde uzatılmış genç ladinle (pine_b) çizilir (tall_model ile değiştirilebilir).
##
## Bütçe kesintileri (godot.md §4.6, §7.5; K3: menü karesini değiştirmeyen kesintiler). Bütçe ölçümünde
## (2026-11-05) çamlar görünür geçişte 1,08M, gölgede 0,61M üçgen getiriyordu: motorun LOD zinciri bu uzaklıklarda
## hiç devreye girmiyor (ilk sade düzeyin hatası 7 m'lik çamda ~0,34 m; 1 piksellik eşik ancak ~240 m'de aşılır).
##  - Gölge: kampa yakın (shadow_radius) çamların gölgesini aynı çamın en sade düzeyi düşürür (TreeKit.baked_lod,
##    SHADOW_TRIANGLES; yalnız gölge veren kopya "Shadow", aynı malzeme: rüzgârda birlikte sallanır). Çamlar
##    üstlerine gölge almaz (foliage.gdshader shadows_disabled): kopyanın kendi üstüne düşen gölgesi yoktur.
##  - Uzak çam: kameradan FAR_DISTANCE'tan uzaktaki çam orta düzeyle (FAR_TRIANGLES) çizilir (her karede uzaklığa
##    bakılır, çamın ağı değişir; FAR_MARGIN payıyla, sınırda titremez). Menü kadrajındaki en uzak çam menü
##    gözünden 58,5 m'dedir: menü karesi değişmez. Godot'nun görünürlük aralığı kullanılmaz: 4.7.2'de aralıklı
##    düğümlerin ebeveyni gizlenip yeniden gösterilince aralık durumu bozuluyor (denendi: uzak çamlar bir daha
##    çizilmedi).
##  - Uzak vadi ladininde (near_distance ötesi) gövde yoktur: 420 m'de piksel altıdır, dal katları örter.

const FOLIAGE_SHADER := preload("res://shaders/foliage.gdshader")
## Küme ağaçlarının patika kenarına (metre) ve engel dairelerine (metre, daire kenarından) en az uzaklığı.
const PATH_CLEARANCE := 1.4
const OBSTACLE_PADDING := 1.1
## Küme ağaçları arasındaki en az uzaklığın ağaç boyuna oranı.
const SPACING_PER_HEIGHT := 0.26
## Küme ağaçlarının dikilebildiği en dik yamaç (eğim, m/m). Vadi ormanından (is_good_spot: 0,85) diktir:
## ahırın arkasındaki kayalık yamaçta da çam olsun (gövde zemindeki en alçak noktaya oturur).
const GROVE_MAX_SLOPE := 1.4
## Kamp çamlarını seçen görüş hattının kadrajı (yaw 0, odak ayakların 0,7 m üstü). Takip kamerasının eski, yatık kadrajıdır ve bilerek sabittir: K98'in dik kamerası
## bu hattın üstünden bakar, kameraya bağlansaydı ağaçlar yer değiştirir ve menü karesi bozulurdu.
const VIEW_PITCH := 23.35
const VIEW_DISTANCE := 27.0
const VIEW_LOOK_HEIGHT := 0.7
## Kamera örtmesi: kamera ile oyuncu arasındaki görüş hattının bu yarıçapı (metre) içindeki dallar noktalı
## saydamlaşır (foliage.gdshader); hattın OCCLUSION_CORE kadar yakınında saydamlık tamdır (yarıçapın %55'i, payla).
const OCCLUSION_RADIUS := 1.6
const OCCLUSION_CORE := 0.6
## Görüş hattıyla dal konisi arasında bırakılan pay (metre). Menü kamerasıyla aynı, yatık açıda kampın kenarındaki
## çamlardan kaçınmak olanaksızdır; bu yüzden pay eksidir: dallar hatta tam saydam çekirdek kadar girebilir,
## oyuncu yine görünür.
const VIEW_MARGIN := -OCCLUSION_CORE
## Meshy ladinlerinin en/boy oranı: kısa ağaçlarda en fazla ilk değer, uzunlarda ikinci (referanstaki ince
## ladinler gibi). Geniş genç ladin dikeyde uzatılır; böylece bütün çamlar dal konisinin (TreeKit.cone_radius)
## içinde kalır.
const WIDTH_RATIO := Vector2(0.52, 0.4)
## Ağaçların LOD eğilimi (1 = motorun varsayılanı; küçüldükçe sade düzeye daha erken geçilir).
const LOD_BIAS := 0.5
## Çamın sade düzeyleri (TreeKit.baked_lod; Meshy genç ladini 13,5k üçgen): uzak çam orta düzeyle (~6,7k), gölge
## kopyası en sade düzeyle (~3,7k) çizilir. En sade düzey dal uçlarının köşe rengini ve açıklığını yitirir: uzak
## çamda (Serbest Gez, 60–85 m) dal uçları sönük kalıyordu (denendi: güney kenardan bakışta piksellerin %0,65'i);
## gölgede biçim yeter (gölge kareleri aynı çıktı).
const FAR_TRIANGLES := 6700
const SHADOW_TRIANGLES := 3700
## Bu uzaklıktan (kameradan çamın kutusunun merkezine, metre) ötedeki çam orta düzeyle çizilir. Menü kadrajındaki
## en uzak çam (Pine53) menü gözünden 58,5 m'dedir; eşik ve pay ondan uzak kalır (test_budget_cuts sınar).
const FAR_DISTANCE := 62.0
const FAR_MARGIN := 1.5
## Yaprak renginin doğrusal çarpanı: Meshy ladininin dokusu gece sahnesinde neredeyse siyah kalır; dal uçlarının
## açık, katların altının koyu boyandığı foliage.gdshader ile birlikte referanstaki koyu yeşil-gri ladinlere
## yaklaştırır (prosedürel ladinlerde de aynı, renkleri aynı dokudan gelir). Mavi bileşen biraz fazladır: gece
## renk ayarı yeşilleri zeytine çeker.
const FOLIAGE_GAIN := Vector3(1.4, 1.4, 1.5)
## Prosedürel ladinin tabandaki taç yarıçapı (TreeKit.spruce, birim).
const SPRUCE_RADIUS := 2.55
## Vadi ormanında dal uçlarının aydınlanması ve taç içinin koyuluğu (foliage.gdshader tip_light / inner_shade).
## Prosedürel ladinin her katının normali yukarı baktığından bütün kat kenarları aydınlanır; Meshy çamlarının
## ayarıyla vadi, açık çizgili koniler gibi görünürdü. 4. referanstaki vadi ormanları koyu kütlelerdir.
const VALLEY_TIP_LIGHT := 0.5
const VALLEY_INNER_SHADE := 0.35
## Ağaçların zemine gömülme payı (metre; eğimde gövde havada kalmasın).
const SINK := 0.15
## Gövde engellerinin toplandığı yarıçap (kamptan metre; uzak yamaçlarda oyuncu zaten dolaşmaz).
const OBSTACLE_RANGE := 70.0
## Vadi ormanının (MultiMesh ladinler) gövdelerinin de engel sayıldığı yarıçap (kamptan metre): oyun alanı
## (PlayerController.play_area_radius, 38 m) ve biraz payı. Çayırın kenarı kuzeybatıda ~25 m'dedir; orman şeridi
## oyun alanının içine (~34 m) kadar sokulur ve oyuncu o ağaçların içinden geçmemelidir.
const VALLEY_OBSTACLE_RANGE := 45.0
## Göl penceresinin gözü (bkz. lake_view_cap): K98'den önceki menü kamerasının yeri. Menü kamerası 2026-11-07'de yukarı ve
## geriye taşındı (scenes/main.tscn → MenuCamera; ateşe 26,4 m, 38°); göz bilerek eski yerinde kalır: ağaçların boyu ve
## kullanıcının onayladığı WIDE karesi (K68) değişmez (test_forest denetler).
const MENU_EYE := Vector3(0.27, 8.39, 13.86)
## Gözden yatay açılar (derece; 0 = kuzey, artı = sağ): pencerenin sol ve sağ sınırı, sınırlardaki yumuşak
## geçiş ve gölün yakın kıyısına inen bakış çizgisinin eğimi (yataydan aşağı). Kadraj gözden ±34° genişliktedir;
## pencere solda kadrajın kenarını da kapsar (4. referansta sol kenardaki ladinler kısadır, ardında vadinin
## aydınlık tepeleri görünür), sağda ahırın arkasındaki uzun ladinlerin ve kayalık yamacın önünde biter.
const LAKE_WINDOW := Vector4(-40.0, 10.0, 6.0, 8.0)
## Pencerenin kenarına doğru boy sınırının gevşemesi (metre; pencerenin dışında sınır yoktur).
const LAKE_CAP_FADE := 25.0
## Boy sınırının uygulandığı uzaklık (kamptan metre): çayır, çayırın kenarı, inişteki orman şeridi ve şeridin
## vadi tabanında gölün yakın kıyısına kadar uzanan kısmı (TerrainShape.BAND_REACH). Menü kadrajında çayırın
## kenarının hemen üstünde görünen vadi tabanı kamptan ~140–300 m uzaktadır; sınır yalnızca 120 m'ye kadar
## uygulanınca şeridin uzak ağaçları gölün yakın kıyısını örtüyordu. Ötesindeki (gölün çevresindeki) orman
## olduğu gibi kalır.
const LAKE_CAP_RANGE := 320.0
## Bundan kısa kalacak ağaç dikilmez (metre).
const MIN_TREE_HEIGHT := 2.0
## Vadi ormanındaki prosedürel ladinlerin ölçek aralığı (1 = 10 m boy).
const VALLEY_SCALE := Vector2(0.7, 1.3)
## Göl penceresinde sınıra takılan ağaç sınırın bu oranı ile tamamı arasında bir boya iner (bkz. capped_height).
const LAKE_CAP_LOW := 0.5

@export var seed_value := 31
@export var terrain_seed := 1207
## Vadi ormanının dikildiği bölge: Rect2(x, z, genişlik, derinlik).
@export var area := Rect2(-1500.0, -2000.0, 3000.0, 2600.0)
## Vadi ormanının aday ızgara aralığı (metre). Küçüldükçe orman sıklaşır ama üretim yavaşlar.
@export var spacing := 9.5
## Bu mesafeden (kamp merkezine) yakın vadi ağaçları ayrıntılı meshle çizilir.
@export var near_distance := 420.0
@export var chunk_size := 350.0
## Kamp çevresinde vadi ormanının dikilmediği açıklık yarıçapı (kümeler bunun içinde de olabilir). Platonun
## üstünde (kampın arkasındaki çayırda) zaten vadi ormanı yoktur (TerrainShape.forest_density); bu yarıçap
## inişteki orman şeridinin çayırın kenarına kadar sokulabilmesi için küçüktür.
@export var camp_clearing := 26.0
## Menü kadrajının ortasında (kampın önünde, -Z yönünde) vadi ormanının seyreltildiği kama:
## Vector4(en yakın, en uzak (metre), yarım açı (derece), kalan oran). 4. referansta çayırın ardında göle kadar
## koyu bir orman şeridi (TerrainShape.BAND_REACH), gölün yakın kıyısında dağınık orman öbekleri vardır: kama
## şeridin ötesinden başlar, içinde ağaçların yalnızca bir kısmı öbekler halinde kalır (göl açık görünsün).
@export var view_clearing := Vector4(230.0, 360.0, 40.0, 0.3)
## Kamp çevresine elle yerleştirilen çamlar: Vector4(x, z, ölçek, tohum). Ölçek 1 = 10 m boy
## (TreeKit.UNIT_HEIGHT); 6,5 m'den kısalar young_model, uzunlar tall_model ile çizilir.
## Yerler tools/menu_camera_fit.json'daki "çam_*" noktalarından (4. referanstan geri izdüşüm) ve
## referanstaki diğer çamlardan alınmıştır. Menü kamerası kampa yakın olduğundan kadrajın kenarındaki çamlar
## kısa tutulur (yine de kadrajda iri görünürler). Perspektif kadraj kenarındaki ağaçları dışarı doğru yatırır;
## referanstaki köşe kümeleri bu yüzden gövdeleri kadrajın biraz içinde, tepeleri kenara yakın dikilmiştir.
## Kamp çamları kümeler gibi süzülmez: patikalara ve engellere girmemeleri, takip kamerasının görüşünü
## kapatmamaları ve göl penceresinde boylarının sınırı (lake_view_cap) aşmamaları testlerle denetlenir
## (test_path_network, test_forest). Kampın arkasındaki çayırdakiler referanstaki gibi genç, kısa ladinlerdir.
@export var camp_trees: Array[Vector4] = [
	Vector4(-5.3, 6.0, 0.35, 1.0), # çam_sol_alt: kadrajın sol alt köşesindeki ladin (tepesi R1 kayasının önünde)
	Vector4(-4.3, 6.6, 0.28, 13.0), # yanındaki genç ladin
	Vector4(-7.0, 5.2, 0.38, 14.0), # sol alt köşenin kenarındaki koyu dal kütlesi
	Vector4(-7.6, 3.9, 0.36, 2.0),
	Vector4(-10.71, -1.06, 0.42, 3.0), # çam_sol_orta: sol kenar
	Vector4(-12.4, -3.4, 0.48, 4.0),
	Vector4(-16.65, -13.83, 0.36, 5.0), # çam_sol_üst: sol üstteki küme
	Vector4(-9.6, -17.2, 0.36, 6.0), # çam_arka_sol: sol yurdun arkasında, dumanın solundaki ince ladin
	Vector4(11.3, 0.8, 0.38, 7.0), # çam_sağ_orta: sağ kenar (ahır yolunun güneyinde; kamerayı örtmeyecek boyda)
	Vector4(7.0, 3.85, 0.42, 8.0), # çam_sağ_alt: kadrajın sağ alt köşesindeki küme (R12 kayasının arkasında)
	Vector4(6.2, 3.6, 0.32, 15.0),
	Vector4(7.6, 2.9, 0.46, 16.0),
	Vector4(8.6, 6.4, 0.5, 9.0),
	Vector4(14.2, -37.4, 0.55, 10.0), # çam_arka_sağ: R10 kayasının arkasındaki uzun ladin
	Vector4(-1.9, 6.6, 0.26, 11.0), # alt ortadaki genç ladinler
	Vector4(0.35, 7.1, 0.22, 12.0),
]
## Çam kümeleri: Vector4(x, z, yarıçap, ağaç sayısı). 4. referanstaki gibi menü kadrajının sol ve sağ
## kenarlarında, sol üstte (yamaçtan yükselen uzun çamlar), kampın arkasındaki çayırda (sol yurdun arkasında,
## çayırın kenarında ve R10 kayasının çevresinde) genç ladin öbekleri, ahırın arkasında sık koyu ladinler.
## Göl penceresindeki küme ağaçları lake_view_cap boyunu aşmaz.
@export var groves: Array[Vector4] = [
	Vector4(-15.0, 2.0, 4.0, 6.0), # kampın batısı (menü kadrajının hemen solunda; serbest gezintide görünür)
	Vector4(-9.5, 9.5, 4.0, 5.0), # sol ön (kameranın solunda)
	Vector4(-20.5, -10.0, 5.0, 8.0), # sol üst: platonun kıyısı
	Vector4(-23.0, -20.0, 6.0, 9.0), # sol üst: yamaçtan yükselen uzun çamlar
	Vector4(-12.8, -20.6, 3.6, 6.0), # sol yurdun arkasındaki genç ladinler
	Vector4(-2.4, -24.2, 3.4, 5.0), # çayırın kenarındaki genç ladinler (kadrajın ortası)
	Vector4(17.0, -39.5, 5.0, 7.0), # R10 kayasının arkası
	Vector4(22.5, -31.0, 6.0, 9.0), # ahırın arkası
	Vector4(22.0, -14.0, 6.0, 9.0), # ahırın doğusu
	Vector4(15.5, -4.5, 3.5, 5.0), # ahır yolunun doğusu (menü kadrajının hemen sağında)
	Vector4(10.4, 2.8, 2.8, 4.0), # sağ alt köşedeki kamp çamlarının arkası
	Vector4(12.0, 7.5, 4.5, 6.0), # sağ ön (kameranın sağında)
]
@export var grove_seed := 57
## Küme ağaçlarının boy aralığı (metre): kampa yakın olanlar (menü kamerasına yakın oldukları için kadrajda
## zaten iri görünürler) kısa, uzaktakiler uzun; aradaki geçiş kamptan 12–32 m arasındadır. 4. referanstaki
## ladinler genç ve ince ağaçlardır (kampın arkasındakiler bile 4–8 m).
@export var grove_heights_near := Vector2(4.0, 7.0)
@export var grove_heights_far := Vector2(5.0, 9.0)
## Kamptan bu uzaklığa kadar çamlar gölge düşürür. Ay ışığı menü kamerasının arkasından geldiği için daha
## uzaktaki çamların (sol kenardaki kümeler, çayırdaki genç ladinler, ahırın doğusu) gölgesi ağacın arkasına
## düşer ve menüden görünmez; gölge geçişine girmezler (performans).
@export var shadow_radius := 22.0
## Uzun ve genç ladin modelleri (assets/nature/<id>/<id>.glb). Uzun çamlar için varsayılan da pine_b'dir
## (bkz. yukarıdaki not); pine_a seçilebilir.
@export var tall_model := TreeKit.PINE_YOUNG
@export var young_model := TreeKit.PINE_YOUNG
## Pişmiş ormanın haritası (MapBake; world-swap): boş değilse dikilen çamlar, ağları (LOD zinciri, uzak ve gölge düzeyi, ladinler) ve
## vadinin örnekleri data/maps/<bake_id>/baked/forest.res'ten gelir (tools/bake_map.gd; plan ve vadinin taraması yeniden yapılmaz, çam
## modelleri yüklenmez). Ayarlar, engeller, patikalar, bakış hatları ya da biçim pişirilenden ayrıysa imza tutmaz, orman kendisi üretir.
## Kampın dünyasında "camp"tır.
@export var bake_id := ""
@export_tool_button("Yeniden oluştur", "Reload") var rebuild_button: Callable = rebuild

## Son kurulum pişmiş ormanla mı yapıldı (bake_id)?
var used_bake := false
## Kamera örtmesinin yazıldığı malzemeler (yakın çamlar).
var _occluding: Array[ShaderMaterial] = []
## Kamp ve küme çamlarının (ve oyun alanına yakın vadi ağaçlarının) gövde engelleri: Vector3(x, z, yarıçap).
var _trunks: Array[Vector3] = []
## Son kurulumda dikilen kamp ve küme çamları: Vector4(x, z, ölçek, tohum).
var _planted: Array[Vector4] = []
## Uzak düzeyi olan çamlar (bkz. update_far_levels): düğüm, tam ve uzak ağ, kutusunun merkezi (dünya), uzak mı.
var _far_pines: Array[MeshInstance3D] = []
var _far_full: Array[Mesh] = []
var _far_simple: Array[Mesh] = []
var _far_centers := PackedVector3Array()
var _far_state := PackedByteArray()
## Son kurulumun imzası ve pişirme aracı için saklananlar (MapBake.capture): ladin ağları, kullanılan çam modelleri, vadinin kareleri
## ([[anahtar, ham dizi], ...]) ve vadinin gövdeleri.
var _signature := ""
var _captured := {}


func _ready() -> void:
	add_to_group(World.OBSTACLE_GROUP)
	add_to_group(FollowCamera.OCCLUDER_GROUP)
	# Kamp nesneleri, kayalar ve patikalar ağaca eklenip engellerini kaydettikten sonra kur.
	rebuild.call_deferred()


## Serbest gezintide içinden geçilemeyen gövdeler: Vector3(x, z, yarıçap).
func get_obstacle_circles() -> Array[Vector3]:
	return _trunks.duplicate()


## Son kurulumda dikilen kamp ve küme çamları (Vector4(x, z, ölçek, tohum)).
func get_planted_trees() -> Array[Vector4]:
	return _planted.duplicate()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or _far_pines.is_empty():
		return
	var camera := get_viewport().get_camera_3d()
	if camera:
		update_far_levels(camera.global_position)


## Uzak çamların düzeyi: kameradan (eye) uzaklığı FAR_DISTANCE + FAR_MARGIN'i aşan çam uzak düzeye (FAR_TRIANGLES),
## FAR_DISTANCE − FAR_MARGIN'in altına inen çam tam ağa geçer (arada önceki düzeyinde kalır). Değişen çam sayısı döner.
func update_far_levels(eye: Vector3) -> int:
	var out_sq := (FAR_DISTANCE + FAR_MARGIN) * (FAR_DISTANCE + FAR_MARGIN)
	var in_sq := (FAR_DISTANCE - FAR_MARGIN) * (FAR_DISTANCE - FAR_MARGIN)
	var changed := 0
	for i in _far_pines.size():
		var d := eye.distance_squared_to(_far_centers[i])
		var simple := _far_state[i] == 1
		if not simple and d > out_sq:
			_far_pines[i].mesh = _far_simple[i]
			_far_state[i] = 1
			changed += 1
		elif simple and d < in_sq:
			_far_pines[i].mesh = _far_full[i]
			_far_state[i] = 0
			changed += 1
	return changed


## Uzak düzeyde çizilen çam sayısı (testler ve ölçüm için).
func get_far_pine_count() -> int:
	return _far_state.count(1)


## FollowCamera her karede çağırır: kamera ile karakter arasındaki dallar noktalı biçimde saydamlaşır.
func set_camera_occlusion(camera_position: Vector3, target_position: Vector3) -> void:
	for mat in _occluding:
		mat.set_shader_parameter("occlusion_from", camera_position)
		mat.set_shader_parameter("occlusion_to", target_position)


func rebuild() -> void:
	for child in get_children():
		if child.has_meta(&"generated"):
			remove_child(child)
			child.queue_free()
	_occluding.clear()
	_trunks.clear()
	_planted.clear()
	_far_pines.clear()
	_far_full.clear()
	_far_simple.clear()
	_far_centers.clear()
	_far_state.clear()
	_captured = {}
	var shape := TerrainShape.new(terrain_seed)
	var inputs := _plan_inputs(shape)
	_signature = bake_signature(shape, inputs) if not bake_id.is_empty() else ""
	var bake := MapBake.fetch(bake_id, "forest", _signature) if not bake_id.is_empty() else null
	used_bake = bake != null
	if bake:
		# Pişmiş orman: aynı çamlar aynı sırayla, ağları dosyadan (tools/bake_map.gd, bake_payload).
		var ids: Array = bake.data.get("spruce", [])
		var baked_near: Array[Mesh] = []
		for k in ids.size() - 1:
			baked_near.append(bake.meshes[int(ids[k])])
		_planted.assign(bake.data.get("planted", []))
		_build_planted(shape, baked_near, bake)
		_build_valley_baked(bake, baked_near, bake.meshes[int(ids[ids.size() - 1])])
		return
	var spruce_near: Array[Mesh] = [TreeKit.spruce(11, 7, 7), TreeKit.spruce(12, 8, 7), TreeKit.spruce(13, 6, 6)]
	var spruce_far := TreeKit.spruce(14, 3, 4, false)
	_planted = _plan_trees(shape, inputs)
	_build_planted(shape, spruce_near)
	_build_valley(shape, spruce_near, spruce_far)
	if MapBake.capture:
		var spruces: Array[Mesh] = spruce_near.duplicate()
		spruces.append(spruce_far)
		_captured["spruce"] = spruces


## Planın sahneden okunan girdileri: engel daireleri (Meadow.collect_blockers), patika ağı ve takip kamerasının bakış hatları.
func _plan_inputs(shape: TerrainShape) -> Dictionary:
	var tree := get_tree() if is_inside_tree() else null
	var paths := PathNetwork.find_in_tree(tree)
	return {
		"blockers": Meadow.collect_blockers(tree),
		"paths": paths,
		"views": path_views(paths.get_segments() if paths else ([] as Array[Vector4]), shape),
	}


## Pişmiş ormanın imzası (MapBake.signature_of): ayarlar ve değişmezler (TreeKit'inkiler de), engeller, patikalar, bakış hatları,
## modellerin varlığı, biçimin örnek noktalarındaki yükseklik ve orman yoğunluğu.
func bake_signature(shape: TerrainShape, inputs: Dictionary) -> String:
	var paths := inputs.get("paths") as PathNetwork
	var path_data: Array = [paths.get_segments(), paths.get_half_widths()] if paths else []
	return MapBake.signature_of(["forest", MapBake.script_inputs(self), MapBake.script_constants(TreeKit), inputs.get("blockers", []),
		path_data, inputs.get("views", []), MeshyProp.exists(TreeKit.FOLDER, young_model), MeshyProp.exists(TreeKit.FOLDER, tall_model),
		MapBake.probe_shape(shape, [&"height_at", &"forest_density"])])


## Son kurulumun ormanı pişirilecek parça olarak (tools/bake_map.gd; yalnız MapBake.capture açıkken üretildiyse dolu): ladin ağları,
## kullanılan her çam modelinin LOD zinciri, uzak ve gölge düzeyi ve kutusu (TreeKit'in önbelleğinden), dikilen çamlar, vadinin kareleri.
func bake_payload() -> MapBake:
	var bake := MapBake.new()
	bake.kind = "forest"
	bake.map_id = bake_id
	bake.signature = _signature
	var meshes: Array[Mesh] = []
	var spruce: Array = []
	for m: Mesh in _captured.get("spruce", []):
		spruce.append(meshes.size())
		meshes.append(m)
	var pines := {}
	for id: String in _captured.get("models", []):
		var entry := {"aabb": TreeKit.load_model(id)["aabb"], "full": meshes.size()}
		meshes.append(TreeKit.lod_chain(id, TreeKit.FOLIAGE_MID_SRGB))
		entry["far"] = meshes.size()
		meshes.append(TreeKit.baked_lod(id, FAR_TRIANGLES, TreeKit.FOLIAGE_MID_SRGB))
		entry["shadow"] = meshes.size()
		meshes.append(TreeKit.baked_lod(id, SHADOW_TRIANGLES, TreeKit.FOLIAGE_MID_SRGB))
		pines[id] = entry
	bake.meshes = meshes
	bake.data = {
		"spruce": spruce, "pines": pines, "planted": _planted.duplicate(),
		"valley": _captured.get("valley", []), "valley_trunks": _captured.get("valley_trunks", []),
	}
	return bake


# --- Kamp ve küme çamları --------------------------------------------------------------

## Kamp çamları + engellere, patikalara ve takip kamerasının görüşüne takılmayan küme ağaçları.
func _plan_trees(shape: TerrainShape, inputs: Dictionary = {}) -> Array[Vector4]:
	var trees: Array[Vector4] = []
	trees.assign(camp_trees)
	if inputs.is_empty():
		inputs = _plan_inputs(shape)
	var blockers: Array[Vector3] = []
	blockers.assign(inputs["blockers"])
	var paths := inputs["paths"] as PathNetwork
	var views: Array[Vector3] = []
	views.assign(inputs["views"])
	for i in groves.size():
		var grove := groves[i]
		var rng := RandomNumberGenerator.new()
		rng.seed = grove_seed + i * 131
		for p in grove_points(grove, grove_seed + i * 131, grove_heights_near.x * SPACING_PER_HEIGHT * 2.0):
			var edge := p.distance_to(Vector2(grove.x, grove.y)) / maxf(grove.z, 0.001)
			var roll := rng.randf()
			var height := grove_tree_height(p, edge, roll, grove_heights_near, grove_heights_far)
			height = capped_height(height, lake_view_cap(p, shape.height_at(p.x, p.y)), roll)
			if height < MIN_TREE_HEIGHT:
				continue
			var candidate := Vector4(p.x, p.y, height / TreeKit.UNIT_HEIGHT, float(1000 + i * 100 + trees.size()))
			if can_plant(candidate, trees, blockers, paths, views, shape):
				trees.append(candidate)
	return trees


## Küme ağacı bu yere dikilebilir mi? (Su/yamaç kuralı, engeller, patikalar, diğer çamlar ve görüş hattı.)
static func can_plant(tree: Vector4, others: Array[Vector4], blockers: Array[Vector3], paths: PathNetwork,
		views: Array[Vector3], shape: TerrainShape) -> bool:
	var p := Vector2(tree.x, tree.y)
	if not is_good_spot(shape, p, GROVE_MAX_SLOPE):
		return false
	var height := TreeKit.tree_height(tree.z)
	if Scatter.is_blocked(p.x, p.y, blockers, OBSTACLE_PADDING + TreeKit.trunk_radius(height)):
		return false
	if paths and paths.distance_to_paths(p) < PATH_CLEARANCE + TreeKit.trunk_radius(height):
		return false
	for o in others:
		var gap := maxf(TreeKit.tree_height(o.z), height) * SPACING_PER_HEIGHT
		if p.distance_to(Vector2(o.x, o.y)) < gap:
			return false
	return not blocks_view(tree, views, shape.height_at(p.x, p.y), VIEW_MARGIN)


## Göl penceresinde ağacın en fazla boyu (metre; saf fonksiyon). 4. referansta göl kadrajın üstünde açıkça
## görünür: kampın arkasındaki çayırdaki çamlar genç ve kısadır, çayırın ardındaki orman şeridi gölün yakın
## kıyısının altında kalır. Bunun için ağacın tepesi menü gözünden göle inen bakış çizgisinin (LAKE_WINDOW.w
## derece eğimli; kadrajda gölün yakın kıyısı) altında kalır. Pencerenin kenarlarına doğru sınır gevşer;
## pencerenin dışında (kadrajın iki yanı, kameranın arkası) ve LAKE_CAP_RANGE ötesinde sınır yoktur (INF).
## p: ağacın yeri (x, z); ground: tabanındaki zemin.
static func lake_view_cap(p: Vector2, ground: float) -> float:
	var d := p - Vector2(MENU_EYE.x, MENU_EYE.z)
	if d.y > -1.0 or p.length() > LAKE_CAP_RANGE:
		return INF
	var angle := rad_to_deg(atan2(d.x, -d.y))
	var inside := smoothstep(LAKE_WINDOW.x - LAKE_WINDOW.z, LAKE_WINDOW.x, angle) \
			* (1.0 - smoothstep(LAKE_WINDOW.y, LAKE_WINDOW.y + LAKE_WINDOW.z, angle))
	if inside <= 0.0:
		return INF
	var sight := MENU_EYE.y - d.length() * tan(deg_to_rad(LAKE_WINDOW.w))
	return sight - ground + (1.0 - inside) * LAKE_CAP_FADE


## Küme ağacının boyu (metre; saf fonksiyon): kamptan uzaklaştıkça near aralığından far aralığına geçer;
## kümenin kenarındakiler (edge: merkezden uzaklık / yarıçap) daha kısadır, küme dışa doğru alçalır.
static func grove_tree_height(p: Vector2, edge: float, roll: float, near: Vector2, far: Vector2) -> float:
	var w := smoothstep(12.0, 32.0, p.length())
	var low := lerpf(near.x, far.x, w)
	var high := lerpf(near.y, far.y, w)
	var height := lerpf(low, high, roll)
	return lerpf(height, low, smoothstep(0.55, 1.0, edge) * 0.6)


## Kümenin aday noktaları: disk içinde, birbirinden en az min_gap uzak, belirlenimci (saf fonksiyon).
## grove: Vector4(x, z, yarıçap, sayı). Sayıya ulaşılamazsa daha az nokta döner.
static func grove_points(grove: Vector4, rng_seed: int, min_gap: float) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var points := PackedVector2Array()
	var wanted := int(grove.w)
	var attempts := wanted * 30
	while points.size() < wanted and attempts > 0:
		attempts -= 1
		var p := Scatter.random_in_disk(rng, Vector2(grove.x, grove.y), grove.z)
		var ok := true
		for q in points:
			if p.distance_to(q) < min_gap:
				ok = false
				break
		if ok:
			points.append(p)
	return points


## Takip kamerasının varsayılan açısından patika noktalarına bakış hatları: [göz0, odak0, göz1, odak1, ...].
## Her parçanın başı ve ortası alınır (saf fonksiyon).
static func path_views(segments: Array[Vector4], shape: TerrainShape) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for s in segments:
		for t in [0.0, 0.5]:
			var p := Vector2(s.x, s.y).lerp(Vector2(s.z, s.w), t)
			var focus := Vector3(p.x, shape.height_at(p.x, p.y) + VIEW_LOOK_HEIGHT, p.y)
			result.append(FollowCamera.compute_transform(focus, 0.0, VIEW_PITCH, VIEW_DISTANCE).origin)
			result.append(focus)
	return result


## Çam, bakış hatlarından birini (margin payıyla) kapatıyor mu? (saf fonksiyon)
static func blocks_view(tree: Vector4, views: Array[Vector3], ground: float, margin: float) -> bool:
	for k in range(0, views.size() - 1, 2):
		if TreeKit.sight_clearance(views[k], views[k + 1], tree, ground) < margin:
			return true
	return false


## Çamın dünya dönüşümü: model kutusunun tabanı zemine oturur, boyu ölçek × 10 m'dir; en/boy oranı
## width_ratio()'yu aşmaz. Yön ve hafif incelme tohumdan gelir (saf fonksiyon).
static func tree_transform(tree: Vector4, ground: float, model_box: AABB) -> Transform3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(tree.w) * 7919 + 13
	var height := TreeKit.tree_height(tree.z)
	var s := height / maxf(model_box.size.y, 0.0001)
	var ratio := (model_box.size.x + model_box.size.z) * 0.5 / maxf(model_box.size.y, 0.0001)
	var squeeze := minf(1.0, width_ratio(height) / maxf(ratio, 0.0001)) * rng.randf_range(0.88, 1.0)
	var tree_basis := Basis(Vector3.UP, rng.randf() * TAU) * Basis.from_scale(Vector3(s * squeeze, s, s * squeeze))
	var bottom := Vector3(model_box.get_center().x, model_box.position.y, model_box.get_center().z)
	return Transform3D(tree_basis, Vector3(tree.x, ground - SINK, tree.y) - tree_basis * bottom)


## Bu boydaki (metre) çamın en büyük en/boy oranı: kısa ağaçlar biraz daha dolgun, uzunlar ince (saf fonksiyon).
static func width_ratio(height_m: float) -> float:
	return lerpf(WIDTH_RATIO.x, WIDTH_RATIO.y, smoothstep(4.0, 12.0, height_m))


## Ağacın oturacağı zemin: gövdenin çevresindeki en alçak nokta (eğimde gövde havada kalmaz).
static func trunk_ground(shape: TerrainShape, p: Vector2, radius: float) -> float:
	var ground := shape.height_at(p.x, p.y)
	for k in 4:
		var a := TAU * float(k) / 4.0
		ground = minf(ground, shape.height_at(p.x + cos(a) * radius, p.y + sin(a) * radius))
	return ground


## Ağaç dikmeye uygun yer mi? (Su üstünde ve max_slope'tan dik olmayan bir yamaçta.)
static func is_good_spot(shape: TerrainShape, p: Vector2, max_slope: float = 0.85) -> bool:
	var h := shape.height_at(p.x, p.y)
	if h < TerrainShape.WATER_LEVEL + 1.2:
		return false
	var hx := shape.height_at(p.x + 2.0, p.y)
	var hz := shape.height_at(p.x, p.y + 2.0)
	return Vector2(hx - h, hz - h).length() / 2.0 < max_slope


## Dikilen çamları kurar: her biri ayrı bir MeshInstance3D (LOD zinciri gömülü; uzakta uzak düzeye geçer, bkz.
## update_far_levels; kampa yakın olanın gölgesini "Shadow" kopyası düşürür). Model yoksa prosedürel ladin.
## Gövde engellerini de kaydeder. bake verilirse ağlar ve model kutusu ondan gelir (TreeKit'e ve modele gidilmez).
func _build_planted(shape: TerrainShape, fallback: Array[Mesh], bake: MapBake = null) -> void:
	var holder := Node3D.new()
	holder.name = "Pines"
	_add(holder)
	var materials := {}
	var pines: Dictionary = bake.data.get("pines", {}) if bake else {}
	var used_models: Array[String] = []
	for i in _planted.size():
		var tree := _planted[i]
		var p := Vector2(tree.x, tree.y)
		var height := TreeKit.tree_height(tree.z)
		var model_id := young_model if height < TreeKit.YOUNG_MAX_HEIGHT else tall_model
		var baked: Dictionary = pines.get(model_id, {})
		var model: Dictionary
		var mesh: Mesh
		if bake:
			model = {"aabb": baked["aabb"]} if not baked.is_empty() else {}
			mesh = bake.meshes[int(baked["full"])] if not baked.is_empty() else null
		else:
			model = TreeKit.load_model(model_id)
			mesh = TreeKit.lod_chain(model_id, TreeKit.FOLIAGE_MID_SRGB)
			if mesh and not used_models.has(model_id):
				used_models.append(model_id)
		var ground := trunk_ground(shape, p, TreeKit.trunk_radius(height))
		var mi := MeshInstance3D.new()
		mi.name = "Pine%d" % i
		if mesh == null:
			# Yedek: prosedürel ladin (10 birim boyunda; ölçek doğrudan uygulanır).
			mi.mesh = fallback[int(tree.w) % fallback.size()]
			mi.transform = Transform3D(Basis(Vector3.UP, fposmod(tree.w * 2.39, TAU)).scaled(Vector3.ONE * tree.z), Vector3(p.x, ground - SINK, p.y))
			if not materials.has(""):
				materials[""] = _spruce_material(true)
			mi.material_override = materials[""]
		else:
			mi.mesh = mesh
			mi.transform = tree_transform(tree, ground, model["aabb"])
			if not materials.has(model_id):
				materials[model_id] = _model_material(model)
			mi.material_override = materials[model_id]
		mi.lod_bias = LOD_BIAS
		var shadows := p.length() < shadow_radius
		var simple: Mesh = null
		var shadow_mesh: Mesh = null
		if mesh and bake:
			simple = bake.meshes[int(baked["far"])]
			shadow_mesh = bake.meshes[int(baked["shadow"])] if shadows else null
		elif mesh:
			simple = TreeKit.baked_lod(model_id, FAR_TRIANGLES, TreeKit.FOLIAGE_MID_SRGB)
			shadow_mesh = TreeKit.baked_lod(model_id, SHADOW_TRIANGLES, TreeKit.FOLIAGE_MID_SRGB) if shadows else null
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows and shadow_mesh == null else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if shadow_mesh:
			mi.add_child(shadow_proxy(shadow_mesh, mi.material_override))
		holder.add_child(mi)
		if simple:
			_far_pines.append(mi)
			_far_full.append(mi.mesh)
			_far_simple.append(simple)
			var xform := mi.global_transform if mi.is_inside_tree() else transform * mi.transform
			_far_centers.append((xform * mi.mesh.get_aabb()).get_center())
			_far_state.append(0)
		if p.length() < OBSTACLE_RANGE:
			_trunks.append(Vector3(p.x, p.y, TreeKit.trunk_radius(height)))
	if MapBake.capture and bake == null:
		_captured["models"] = used_models


## Çamın gölgesini düşüren kopya (saf; bkz. dosyanın başı): çamın çocuğu "Shadow", en sade ağ ve çamın malzemesiyle
## (aynı dönüşüm, aynı rüzgâr salınımı); görünmez, yalnız gölge geçişine girer.
static func shadow_proxy(simple: Mesh, material: Material) -> MeshInstance3D:
	var proxy := MeshInstance3D.new()
	proxy.name = "Shadow"
	proxy.mesh = simple
	proxy.material_override = material
	proxy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	return proxy


## Meshy ladininin malzemesi (birleştirilmiş meshin köşe rengi; taban, boy, eksen ve taç yarıçapı model kutusundan).
func _model_material(model: Dictionary) -> ShaderMaterial:
	var box: AABB = model["aabb"]
	var mat := _base_material()
	mat.set_shader_parameter("model_bottom", box.position.y)
	mat.set_shader_parameter("model_height", box.size.y)
	mat.set_shader_parameter("model_axis", Vector2(box.get_center().x, box.get_center().z))
	mat.set_shader_parameter("model_radius", (box.size.x + box.size.z) * 0.25)
	mat.set_shader_parameter("occlusion_radius", OCCLUSION_RADIUS)
	_occluding.append(mat)
	return mat


## Prosedürel ladinin malzemesi (köşe rengi; boy 10 birim, taban y = 0, eksen merkezde).
## near false ise (vadi ormanı) fırça lekeleri ve mürekkep kapalıdır, kamera örtmesi yoktur, dal uçları daha az
## aydınlanır (VALLEY_TIP_LIGHT).
func _spruce_material(near: bool) -> ShaderMaterial:
	var mat := _base_material()
	mat.set_shader_parameter("model_bottom", 0.0)
	mat.set_shader_parameter("model_height", TreeKit.UNIT_HEIGHT)
	mat.set_shader_parameter("model_radius", SPRUCE_RADIUS)
	mat.set_shader_parameter("detail", near)
	if near:
		mat.set_shader_parameter("occlusion_radius", OCCLUSION_RADIUS)
		_occluding.append(mat)
	else:
		mat.set_shader_parameter("tip_light", VALLEY_TIP_LIGHT)
		mat.set_shader_parameter("inner_shade", VALLEY_INNER_SHADE)
	return mat


func _base_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = FOLIAGE_SHADER
	mat.set_shader_parameter("albedo_gain", FOLIAGE_GAIN)
	return mat


# --- Vadi ormanı ------------------------------------------------------------------------

## Ormanlık lekelere dağılmış prosedürel ladinler (karelere bölünmüş MultiMesh).
func _build_valley(shape: TerrainShape, near_meshes: Array[Mesh], far_mesh: Mesh) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var clusters := FastNoiseLite.new()
	clusters.seed = seed_value + 7
	clusters.frequency = 0.035
	var chunks := {}
	var trunk_from := _trunks.size()
	var x := area.position.x
	while x < area.end.x:
		var z := area.position.y
		while z < area.end.y:
			var p := Vector2(x + rng.randf_range(-0.45, 0.45) * spacing, z + rng.randf_range(-0.45, 0.45) * spacing)
			z += spacing
			if p.length() < camp_clearing:
				continue
			var density := shape.forest_density(p.x, p.y)
			if density <= 0.0 or rng.randf() > density * view_keep(p, view_clearing, clusters.get_noise_2dv(p) * 0.5 + 0.5):
				continue
			if not is_good_spot(shape, p):
				continue
			var variant := -1 if p.length() > near_distance else rng.randi() % near_meshes.size()
			# Göl penceresindeki şerit ağaçları menü gözünden göle inen bakış çizgisinin altında kalır (lake_view_cap).
			var scale := rng.randf_range(VALLEY_SCALE.x, VALLEY_SCALE.y)
			var roll := inverse_lerp(VALLEY_SCALE.x, VALLEY_SCALE.y, scale)
			var height := capped_height(scale * TreeKit.UNIT_HEIGHT, lake_view_cap(p, shape.height_at(p.x, p.y)), roll)
			if height < MIN_TREE_HEIGHT * 1.25:
				continue
			_place_valley_tree(chunks, shape, rng, p, height / TreeKit.UNIT_HEIGHT, variant)
			# Orman şeridi kuzeyde ve batıda oyun alanının kenarına kadar sokulur: oraya ulaşabilen gövdeler engeldir.
			if p.length() < VALLEY_OBSTACLE_RANGE:
				_trunks.append(Vector3(p.x, p.y, TreeKit.trunk_radius(height)))
		x += spacing
	var mat := _spruce_material(false)
	var captured: Array = []
	for key: Vector3i in chunks:
		var data: Array = chunks[key]
		var transforms: Array[Transform3D] = data[0]
		var variant: int = key.z
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Trees_%d_%d_%d" % [key.x, key.y, variant]
		mmi.multimesh = Scatter.make_multimesh(far_mesh if variant < 0 else near_meshes[variant], transforms)
		mmi.material_override = mat
		# Vadi ağaçları gölge düşürmez: kamp açıklığının (camp_clearing) dışındadırlar, ay ışığındaki gölgeleri
		# menüden görünmez; kampa yakın gölgeleri kümelerdeki Meshy çamları verir (performans: ~0,6 ms).
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_add(mmi)
		if MapBake.capture:
			captured.append([key, MapBake.instance_buffer(transforms)])
	if MapBake.capture:
		_captured["valley"] = captured
		_captured["valley_trunks"] = _trunks.slice(trunk_from)


## Pişmiş vadi ormanı (_build_valley'nin eşi): kareler üretimdeki sırayla ve adla, aynı ağ ve malzemeyle; vadinin gövdeleri engellere eklenir.
func _build_valley_baked(bake: MapBake, near_meshes: Array[Mesh], far_mesh: Mesh) -> void:
	for t: Vector3 in bake.data.get("valley_trunks", []):
		_trunks.append(t)
	var mat := _spruce_material(false)
	for entry: Array in bake.data.get("valley", []):
		var key: Vector3i = entry[0]
		var variant: int = key.z
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Trees_%d_%d_%d" % [key.x, key.y, variant]
		mmi.multimesh = MapBake.multimesh_from(far_mesh if variant < 0 else near_meshes[variant], entry[1], false)
		mmi.material_override = mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_add(mmi)


## Vadi ormanının bu noktada kalan oranı (1 = hepsi; saf fonksiyon). wedge: view_clearing; cluster: 0..1
## öbek gürültüsü (yüksek olduğu yerlerde ağaçlar kalır, aralarda çayır açılır).
static func view_keep(p: Vector2, wedge: Vector4, cluster: float) -> float:
	var d := p.length()
	if p.y >= 0.0 or d <= wedge.x or d >= wedge.y:
		return 1.0
	var angle := rad_to_deg(absf(atan2(p.x, -p.y)))
	var inside := (1.0 - smoothstep(wedge.z * 0.75, wedge.z, angle)) * smoothstep(wedge.x, wedge.x + 20.0, d) \
			* (1.0 - smoothstep(wedge.y - 60.0, wedge.y, d))
	return lerpf(1.0, clampf(wedge.w * cluster * 2.0, 0.0, 1.0), inside)


## Göl penceresindeki ağacın boyu (metre; saf fonksiyon). height: doğal boy; cap: lake_view_cap sınırı (metre,
## pencerenin dışında INF); roll: 0..1 zar (kümelerde boyu da belirleyen zar, vadide doğal ölçeğin aralıktaki
## yeri). Ağaç en fazla cap × lerp(LAKE_CAP_LOW, 1, roll) boyunda olur: tepeler hep bakış çizgisinin altında
## kalır ama çizgi boyunca budanmış bir çit gibi dizilmez (4. referansta şeridin ve çayırdaki genç ladinlerin
## tepeleri düzensizdir). Sınırın LAKE_CAP_LOW katından kısa ağaçlar olduğu gibi kalır.
static func capped_height(height: float, cap: float, roll: float) -> float:
	return minf(height, cap * lerpf(LAKE_CAP_LOW, 1.0, clampf(roll, 0.0, 1.0)))


func _place_valley_tree(chunks: Dictionary, shape: TerrainShape, rng: RandomNumberGenerator, p: Vector2, scale: float, variant: int) -> void:
	var h := shape.height_at(p.x, p.y)
	var squeeze := rng.randf_range(0.85, 1.05)
	var tree_basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(scale * squeeze, scale, scale * squeeze))
	var xform := Transform3D(tree_basis, Vector3(p.x, h - SINK, p.y))
	var c := Scatter.chunk_key(p.x, p.y, chunk_size)
	var key := Vector3i(c.x, c.y, variant)
	if not chunks.has(key):
		chunks[key] = [[] as Array[Transform3D]]
	(chunks[key][0] as Array[Transform3D]).append(xform)


func _add(node: Node) -> void:
	node.set_meta(&"generated", true)
	add_child(node)
