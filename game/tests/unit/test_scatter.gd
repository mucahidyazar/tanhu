extends TestCase
## Scatter (nesneleri araziye dağıtma yardımcıları) ve bunları kullanan çayır kuralları testleri.
##
## Daireler Vector3(x, z, yarıçap) biçimindedir: yurtlar, ateş ve halılar çimenin çıkmayacağı yerleri
## bu dairelerle bildirir.

## foreground_weight testlerinin dikdörtgeni (Meadow.foreground'un varsayılan değeriyle aynı).
const FOREGROUND := Rect2(-12.0, 1.5, 24.0, 7.0)
## world.tscn'deki çayır ayarları: menü kamerasının önündeki çimenlik ve ezik çimenin merkezi (ateşin yeri).
const SCENE_FOREGROUND := Rect2(-10.0, 8.0, 20.0, 9.0)
const SCENE_TRAMPLE_CENTER := Vector2(0.0, 2.5)


# --- is_blocked ---------------------------------------------------------------------

func test_is_blocked_inside_and_outside_circles() -> void:
	var circles: Array[Vector3] = [Vector3(0.0, 0.0, 2.0), Vector3(10.0, -5.0, 1.0)]
	assert_true(Scatter.is_blocked(0.5, 0.5, circles), "Birinci dairenin içi")
	assert_true(Scatter.is_blocked(10.2, -5.3, circles), "İkinci dairenin içi")
	assert_false(Scatter.is_blocked(5.0, 0.0, circles), "İki dairenin arası boş")
	assert_false(Scatter.is_blocked(2.0, 0.0, circles), "Tam kenar engel sayılmaz")


func test_is_blocked_padding_grows_circles() -> void:
	var circles: Array[Vector3] = [Vector3(0.0, 0.0, 2.0)]
	assert_false(Scatter.is_blocked(2.4, 0.0, circles))
	assert_true(Scatter.is_blocked(2.4, 0.0, circles, 0.5), "Pay (padding) daireyi büyütmeli")


func test_is_blocked_without_circles_is_free() -> void:
	var none: Array[Vector3] = []
	assert_false(Scatter.is_blocked(0.0, 0.0, none))
	assert_false(Scatter.is_blocked(0.0, 0.0, none, 5.0))


# --- distance_to_circles ------------------------------------------------------------

func test_distance_to_circles_outside_and_inside() -> void:
	var circles: Array[Vector3] = [Vector3(0.0, 0.0, 2.0)]
	assert_almost(Scatter.distance_to_circles(5.0, 0.0, circles), 3.0, 0.0001, "Dışarıda: merkeze uzaklık - yarıçap")
	assert_almost(Scatter.distance_to_circles(0.5, 0.0, circles), -1.5, 0.0001, "İçeride negatif olmalı")
	assert_almost(Scatter.distance_to_circles(0.0, 2.0, circles), 0.0, 0.0001, "Kenarda sıfır")


func test_distance_to_circles_picks_nearest_edge() -> void:
	var circles: Array[Vector3] = [Vector3(0.0, 0.0, 1.0), Vector3(10.0, 0.0, 3.0)]
	# (6, 0): birinci kenara 5 m, ikinci kenara 1 m.
	assert_almost(Scatter.distance_to_circles(6.0, 0.0, circles), 1.0, 0.0001)


func test_distance_to_circles_without_circles_is_infinite() -> void:
	var none: Array[Vector3] = []
	assert_true(is_inf(Scatter.distance_to_circles(1.0, 2.0, none)), "Daire yoksa INF dönmeli")


# --- chunk_key ----------------------------------------------------------------------

func test_chunk_key_uses_floor_for_negative_coordinates() -> void:
	assert_eq(Scatter.chunk_key(5.0, 5.0, 12.0), Vector2i(0, 0))
	assert_eq(Scatter.chunk_key(12.0, 0.0, 12.0), Vector2i(1, 0), "Kare sınırı bir sonraki kareye aittir")
	assert_eq(Scatter.chunk_key(-0.1, -0.1, 12.0), Vector2i(-1, -1), "Negatif koordinatlar aşağı yuvarlanmalı (sıfıra değil)")
	assert_eq(Scatter.chunk_key(-12.0, 11.99, 12.0), Vector2i(-1, 0))
	assert_eq(Scatter.chunk_key(25.0, -25.0, 12.0), Vector2i(2, -3))


func test_chunk_key_groups_points_of_the_same_square() -> void:
	var key := Scatter.chunk_key(36.0, -24.0, 12.0)
	for p in [Vector2(36.0, -24.0), Vector2(47.9, -12.1), Vector2(40.0, -20.0)]:
		assert_eq(Scatter.chunk_key(p.x, p.y, 12.0), key, "Aynı karedeki nokta: %s" % p)
	assert_ne(Scatter.chunk_key(48.0, -20.0, 12.0), key, "Komşu kare farklı anahtar almalı")


# --- foreground_weight --------------------------------------------------------------

func test_foreground_weight_is_one_inside_the_area() -> void:
	assert_almost(Scatter.foreground_weight(0.0, 4.0, FOREGROUND), 1.0, 0.0001)
	assert_almost(Scatter.foreground_weight(12.0, 8.5, FOREGROUND), 1.0, 0.0001, "Köşe de bölgeye dahil")


func test_foreground_weight_fades_out_over_falloff() -> void:
	# Sağ kenardan 1,5 m dışarısı: smoothstep(0, 3, 1,5) = 0,5 → ağırlık 0,5.
	assert_almost(Scatter.foreground_weight(13.5, 4.0, FOREGROUND), 0.5, 0.0001)
	assert_almost(Scatter.foreground_weight(15.0, 4.0, FOREGROUND), 0.0, 0.0001, "Falloff mesafesinde sıfıra inmeli")
	assert_almost(Scatter.foreground_weight(0.0, -30.0, FOREGROUND), 0.0, 0.0001, "Uzakta sıfır")
	assert_almost(Scatter.foreground_weight(13.0, 4.0, FOREGROUND, 1.0), 0.0, 0.0001, "Kısa falloff daha çabuk söner")


func test_foreground_weight_decreases_with_distance() -> void:
	var previous := 1.0
	for i in 40:
		var w := Scatter.foreground_weight(12.0 + float(i) * 0.1, 4.0, FOREGROUND)
		assert_true(w <= previous + 0.000001, "Ağırlık uzaklaştıkça artmamalı (adım %d)" % i)
		assert_between(w, 0.0, 1.0)
		previous = w


# --- random_in_disk -----------------------------------------------------------------

func test_random_in_disk_stays_inside() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var center := Vector2(3.0, -4.0)
	var farthest := 0.0
	for i in 3000:
		farthest = maxf(farthest, Scatter.random_in_disk(rng, center, 5.0).distance_to(center))
	assert_true(farthest <= 5.0 + 0.0001, "Disk dışına nokta düştü (%.4f m)" % farthest)
	assert_true(farthest > 4.9, "Noktalar diskin kenarına kadar yayılmalı")


func test_random_in_disk_is_uniform_over_area() -> void:
	# Düzgün dağılımda noktaların ~%25'i yarı yarıçapın içinde, ~%50'si sağ yarıda olur.
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var samples := 4000
	var inner := 0
	var right := 0
	for i in samples:
		var p := Scatter.random_in_disk(rng, Vector2.ZERO, 10.0)
		if p.length() < 5.0:
			inner += 1
		if p.x > 0.0:
			right += 1
	assert_between(float(inner) / samples, 0.21, 0.29, "Merkezde yığılma ya da boşluk var")
	assert_between(float(right) / samples, 0.45, 0.55, "Açısal dağılım dengesiz")


func test_random_in_disk_is_repeatable_with_same_seed() -> void:
	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	a.seed = 1234
	b.seed = 1234
	for i in 50:
		assert_eq(Scatter.random_in_disk(a, Vector2.ZERO, 3.0), Scatter.random_in_disk(b, Vector2.ZERO, 3.0))


# --- make_multimesh -----------------------------------------------------------------
# Not: Başsız (headless) çalıştırmada sahte çizim sunucusu örnek dönüşümlerini saklamaz;
# bu yüzden burada yalnızca örnek sayısı ve ayarlar sınanır.

func test_make_multimesh_counts_and_flags() -> void:
	var mesh := BoxMesh.new()
	var transforms: Array[Transform3D] = [Transform3D.IDENTITY, Transform3D(Basis.IDENTITY, Vector3(1.0, 0.0, 2.0)), Transform3D.IDENTITY]
	var plain := Scatter.make_multimesh(mesh, transforms)
	assert_eq(plain.instance_count, 3)
	assert_eq(plain.mesh, mesh)
	assert_eq(plain.transform_format, MultiMesh.TRANSFORM_3D)
	assert_false(plain.use_custom_data, "Renk verilmezse özel veri kapalı olmalı")
	var tinted := Scatter.make_multimesh(mesh, transforms, PackedColorArray([Color.RED, Color.GREEN, Color.BLUE]))
	assert_true(tinted.use_custom_data, "Renk verilince özel veri açılmalı")
	assert_eq(tinted.instance_count, 3)


func test_make_multimesh_accepts_empty_list() -> void:
	var none: Array[Transform3D] = []
	assert_eq(Scatter.make_multimesh(BoxMesh.new(), none).instance_count, 0)


# --- Çayır kuralları (Meadow.grass_density) ---------------------------------------------
# Çayır sahneye eklenmeden kurulur (çimen üretilmez); ayarlar world.tscn'dekilerle aynı verilir.

func test_meadow_grass_avoids_blockers_and_prefers_foreground() -> void:
	var meadow := _scene_meadow()
	var yurt: Array[Vector3] = [Vector3(-6.2, -2.8, 3.25)]
	var none: Array[Vector3] = []
	var open_field := meadow.grass_density(Vector2(-6.0, -14.0), yurt)
	assert_eq(meadow.grass_density(Vector2(-6.2, -2.8), yurt), 0.0, "Yurdun altında çimen çıkmamalı")
	assert_true(open_field > 0.5, "Açık çayırda çimen olmalı (%.2f)" % open_field)
	assert_true(meadow.grass_density(Vector2(0.0, 12.0), yurt) > open_field, "Menü kamerasının önündeki çimenlik daha gür olmalı")
	assert_almost(meadow.grass_density(Vector2(0.0, 40.0), none), 0.0, 0.0001, "Çayır yarıçapının dışında çimen yok")
	meadow.free()


func test_meadow_tramples_grass_around_trample_center() -> void:
	# Ateşin çevresindeki çimen ezik (seyrek) olur. Ezik bölge trample_center'ı izler:
	# ateş taşınıp bu değer güncellenince ezik halka da ateşle birlikte gitmeli.
	var meadow := _scene_meadow()
	var none: Array[Vector3] = []
	var by_fire := Vector2(0.5, 3.0)
	var away := Vector2(6.0, -6.0)
	var full := meadow.grass_density(away, none)
	assert_true(meadow.grass_density(by_fire, none) < full * 0.5, "Ateşin hemen yanındaki çimen ezik (seyrek) olmalı")
	meadow.trample_center = away
	assert_true(meadow.grass_density(away, none) < full * 0.5, "Ezik bölge trample_center ile taşınmalı")
	assert_almost(meadow.grass_density(by_fire, none), full, 0.0001, "Eski yerde çimen yeniden gürleşmeli")
	meadow.free()


# --- Yardımcılar ---------------------------------------------------------------------

## world.tscn'deki gibi ayarlanmış bir çayır (sahneye eklenmez; çağıran free() etmelidir).
## Yalnızca grass_density gibi saf kurallar için: grass_height rebuild() sırasında kurulan gürültüyü ister.
static func _scene_meadow() -> Meadow:
	var meadow := Meadow.new()
	meadow.foreground = SCENE_FOREGROUND
	meadow.foreground_boost = 1.3
	meadow.trample_center = SCENE_TRAMPLE_CENTER
	return meadow
