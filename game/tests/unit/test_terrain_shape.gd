extends TestCase
## TerrainShape (arazinin yükseklik fonksiyonu) ve Terrain (arazi meshi) testleri.
##
## Çimen, ağaç ve kaya dağıtıcıları ile serbest gezinti kamerası zemini hep TerrainShape'e sorar.
## Bu testler o sözleşmeyi korur: aynı tohum hep aynı araziyi verir, kamp düzdür, kampın arkasındaki çayır
## kamp düzleminde sürer ve yürünebilir, uzaktaki göl su altındadır, nehir kaynağından göle doğru genişler
## ve hiçbir yerde NaN çıkmaz.
## Not: Kamp ateşi kampın merkezinde, (0, 0)'dadır. Vadi -Z yönündedir; menü kamerası +Z tarafındadır.

## Oyunun kullandığı tohum (Terrain.seed_value varsayılanı).
const GAME_SEED := 1207
## Menü kamerasının ve kamp ateşinin konumlarının okunduğu sahneler (örneklenmeden okunur).
const MAIN_SCENE := "res://scenes/main.tscn"
const WORLD_SCENE := "res://scenes/world/world.tscn"
## Menü kadrajının odağı ateşin alevleridir: ateşin yerden bu kadar yukarısı (metre).
const FLAME_HEIGHT := 0.5
## Referanstan geri izdüşürülen yerleşim (menü kamerasıyla birlikte) ve kampın arkasındaki çayırdaki noktaları.
const CAMERA_FIT := "res://tools/menu_camera_fit.json"
const BACK_MEADOW_KEYS: Array[String] = ["kaya_R7", "kaya_R8", "kaya_R9", "kaya_R10", "kaya_R11", "çam_sol_üst", "çam_arka_sol", "çam_arka_sağ"]
## Arazi meshinde bulunması gereken diziler: Mesh.ARRAY_* → [tür, ad].
const TERRAIN_ARRAYS := {
	Mesh.ARRAY_VERTEX: [TYPE_PACKED_VECTOR3_ARRAY, "köşe"],
	Mesh.ARRAY_NORMAL: [TYPE_PACKED_VECTOR3_ARRAY, "normal"],
	Mesh.ARRAY_COLOR: [TYPE_PACKED_COLOR_ARRAY, "renk"],
	Mesh.ARRAY_INDEX: [TYPE_PACKED_INT32_ARRAY, "indeks"],
}

var shape: TerrainShape


func before_each() -> void:
	shape = TerrainShape.new(GAME_SEED)


# --- Belirlenimcilik ----------------------------------------------------------------

func test_same_seed_gives_identical_terrain() -> void:
	var twin := TerrainShape.new(GAME_SEED)
	var differing := 0
	for p in _sample_points(300, 11):
		if twin.height_at(p.x, p.y) != shape.height_at(p.x, p.y):
			differing += 1
	assert_eq(differing, 0, "Aynı tohum farklı yükseklikler üretti")
	assert_eq(twin.seed_value, GAME_SEED)


func test_different_seed_gives_different_terrain() -> void:
	var other := TerrainShape.new(GAME_SEED + 1)
	var differing := 0
	var points := _sample_points(200, 12)
	for p in points:
		if absf(other.height_at(p.x, p.y) - shape.height_at(p.x, p.y)) > 0.01:
			differing += 1
	# Göl tabanı ve kamp her tohumda aynıdır; geri kalan tepeler değişmeli.
	assert_true(differing * 2 > points.size(), "Başka tohum neredeyse aynı araziyi verdi (%d/%d farklı)" % [differing, points.size()])


# --- Kamp ---------------------------------------------------------------------------

func test_campfire_area_is_perfectly_flat() -> void:
	# Kamp merkezinin 10 m çevresinde ateş, başındaki karakterler, halılar ve yurtlar durur: zemin tam 0 olmalı.
	assert_eq(shape.height_at(0.0, 0.0), 0.0, "Kamp merkezinin altı 0 olmalı")
	var fire_origin: Variant = _scene_node_origin(WORLD_SCENE, "./Camp/Campfire")
	if fire_origin is Vector3:
		var fire: Vector3 = fire_origin
		assert_eq(shape.height_at(fire.x, fire.z), 0.0, "Kamp ateşinin altı (world.tscn'deki yerinde) 0 olmalı")
	var worst := _worst_height_in_disk(10.0, 0.5)
	assert_true(worst.x < 0.01, "Kamp zemini düz değil: |y| = %.3f m, nokta (%.1f, %.1f)" % [worst.x, worst.y, worst.z])


func test_camp_stays_nearly_flat_within_flat_radius() -> void:
	# Not: Plato maskesi vadiye bakan (-Z) kenarda 14 m'den biraz önce incelmeye başlar; bu yüzden
	# CAMP_FLAT_RADIUS sınırında birkaç santimden en fazla ~0,3 m'ye varan yumuşak bir eğim kalır.
	var worst := _worst_height_in_disk(TerrainShape.CAMP_FLAT_RADIUS, 0.5)
	assert_true(worst.x < 0.35, "Kamp çevresi fazla eğimli: |y| = %.3f m, nokta (%.1f, %.1f)" % [worst.x, worst.y, worst.z])


func test_plateau_mask_is_full_at_camp_and_empty_in_valley() -> void:
	assert_almost(shape.plateau_mask(0.0, 0.0), 1.0, 0.0001, "Kamp tam platonun üstünde olmalı")
	var outside := PackedVector2Array()
	for p in _disk_grid(10.0, 2.0):
		if shape.plateau_mask(p.x, p.y) < 0.9999:
			outside.append(p)
	assert_true(outside.is_empty(), "Kampın içinde plato maskesi 1 olmalı; dışında kalan noktalar: %s" % [outside.slice(0, 5)])
	assert_almost(shape.plateau_mask(0.0, -600.0), 0.0, 0.0001, "Uzak vadide plato olmamalı")
	# Kullanıcı tohumu değiştirse de kamp platoda kalmalı.
	for other_seed in [1, 42, 99, 2024]:
		assert_almost(TerrainShape.new(other_seed).plateau_mask(0.0, 0.0), 1.0, 0.0001, "Tohum %d" % other_seed)


func test_camp_meadow_continues_behind_the_camp_above_the_valley() -> void:
	# 4. referansta (menu_camp.png) kampın arkasındaki (-Z) çayır kamp düzleminde ~25–35 m sürer; vadiye iniş
	# onun ardından başlar ve vadi tabanı kampın çok altındadır. Menü kamerasının durduğu taraf (+Z) da platodur.
	for z in [25.0, 11.0, 0.0, -12.0, -20.0]:
		assert_almost(shape.plateau_mask(0.0, z), 1.0, 0.0001, "z = %.0f platoda olmalı" % z)
	assert_true(absf(shape.height_at(0.0, -24.0)) < 0.5, "Kampın 24 m arkası hâlâ çayır olmalı (y = %.2f)" % shape.height_at(0.0, -24.0))
	assert_true(shape.plateau_mask(0.0, -70.0) < 0.5, "Plato vadiye doğru bitmeli")
	var previous := 0.0
	for z in [-36.0, -48.0, -60.0, -72.0]:
		var h := shape.height_at(0.0, z)
		assert_true(h < previous, "Çayırın ardında zemin vadiye doğru alçalmalı (z = %.0f, y = %.2f)" % [z, h])
		previous = h
	assert_true(shape.height_at(0.0, -100.0) < -20.0, "Vadi tabanı kampın en az 20 m altında olmalı")


func test_back_meadow_holds_the_reference_boulders_and_pines_at_camp_level() -> void:
	# Referanstan geri izdüşürülen (y = 0 varsayımıyla) kayalar ve çamlar kampın arkasındaki çayırda durur:
	# zemin orada kamp düzlemine yakın ve neredeyse düz olmalı ki kadrajda referanstaki yerlerinde görünsünler.
	var fit := JSON.parse_string(FileAccess.get_file_as_string(CAMERA_FIT)) as Dictionary
	assert_not_null(fit, "tools/menu_camera_fit.json okunamadı")
	if fit == null:
		return
	var layout: Dictionary = fit["layout"]
	for key: String in BACK_MEADOW_KEYS:
		var p := Vector2(layout[key][0], layout[key][1])
		var h := shape.height_at(p.x, p.y)
		assert_true(absf(h) < 0.8, "%s çayırda kamp düzleminde olmalı (y = %.2f)" % [key, h])
		assert_true(_slope_deg(shape.height_at, p) < 12.0, "%s altındaki çayır neredeyse düz olmalı (%.0f°)" % [key, _slope_deg(shape.height_at, p)])
		assert_almost(shape.plateau_mask(p.x, p.y), 1.0, 0.02, "%s platonun üstünde olmalı" % key)


func test_meadow_behind_the_camp_is_walkable() -> void:
	# Yurtların arkasında uçurum ya da basamak yok: kampın 24 m çevresi yumuşak bir çayırdır, oyun alanının
	# kenarına (38 m) kadar iniş yürünebilir bir yamaçtır. Ahırın kuzeydoğusundaki kayalık sırtın (25°–80°) eteği
	# daha diktir ama yine de uçurum gibi dikleşmez (bu turdan önceki arazide orada ~58° vardı).
	var worst_meadow := 0.0
	var worst_slope := 0.0
	var worst_ridge := 0.0
	var at := Vector2.ZERO
	for p in _disk_grid(38.0, 1.0):
		var angle := rad_to_deg(atan2(p.x, -p.y))
		var s := _slope_deg(shape.height_at, p)
		if angle > 25.0 and angle < 80.0:
			worst_ridge = maxf(worst_ridge, s)
			continue
		if p.length() < 24.0:
			worst_meadow = maxf(worst_meadow, s)
		if s > worst_slope:
			worst_slope = s
			at = p
	assert_true(worst_meadow < 20.0, "Kampın arkasındaki çayır fazla eğimli (%.0f°)" % worst_meadow)
	assert_true(worst_slope < 46.0, "Oyun alanındaki iniş fazla dik: %s (%.0f°)" % [at, worst_slope])
	assert_true(worst_ridge < 55.0, "Kayalık sırtın oyun alanındaki eteği uçurum gibi dik (%.0f°)" % worst_ridge)


func test_plateau_edge_follows_the_reference_and_wraps_around() -> void:
	# Kuzeyde (vadi) iniş ~28 m'de, sağ arkada (R10 kayasının arkası) daha geride, doğuda (tepe) çok geride başlar.
	var north := TerrainShape.plateau_edge(0.0)
	assert_between(north.x, 24.0, 34.0, "Kuzeyde çayır kampın ~28 m arkasına kadar sürmeli")
	assert_true(TerrainShape.plateau_edge(20.0).x > 38.0, "R10 kayası (20°, 36 m) çayırda kalmalı")
	assert_true(TerrainShape.plateau_edge(90.0).x > 55.0, "Doğuda plato ahırın arkasındaki tepeye karışmalı")
	for angle in [-180.0, -97.5, 0.0, 33.0, 179.9]:
		var a := TerrainShape.plateau_edge(angle)
		var b := TerrainShape.plateau_edge(angle + 360.0)
		assert_vec_almost(Vector3(a.x, a.y, 0.0), Vector3(b.x, b.y, 0.0), 0.001, "Kenar 360° döngüsel olmalı (%.1f°)" % angle)
	# Kontrol noktaları arasında sıçrama yok: 1°'lik adımlarda kenar en fazla ~1,5 m değişir.
	var jump := 0.0
	for i in 360:
		jump = maxf(jump, absf(TerrainShape.plateau_edge(float(i) + 1.0).x - TerrainShape.plateau_edge(float(i)).x))
	assert_true(jump < 1.5, "Plato kenarı yöne göre yumuşak değişmeli (en büyük sıçrama %.2f m)" % jump)


func test_descent_profile_has_a_soft_shoulder_and_settles_in_the_valley() -> void:
	assert_eq(TerrainShape.descent_profile(-3.0, 70.0), 1.0, "Kenardan önce tam plato")
	assert_eq(TerrainShape.descent_profile(0.0, 70.0), 1.0, "Kenarda tam plato")
	assert_eq(TerrainShape.descent_profile(70.0, 70.0), 0.0, "İnişin sonunda vadi")
	assert_true(TerrainShape.descent_profile(1.0, 70.0) > 0.995, "Kenarda yumuşak omuz (basamak yok)")
	var previous := 1.0
	var steepest := 0.0
	var steepest_at := 0.0
	for i in range(1, 71):
		var value := TerrainShape.descent_profile(float(i), 70.0)
		assert_true(value <= previous, "İniş hep alçalmalı (s = %d)" % i)
		if previous - value > steepest:
			steepest = previous - value
			steepest_at = float(i)
		previous = value
	assert_between(steepest_at, 8.0, 25.0, "En dik yer inişin ilk üçte birinde olmalı")


func test_menu_camera_stands_on_the_plateau_with_a_clear_view_of_the_fire() -> void:
	# Menü kamerası (konumu main.tscn'den, ateşinki world.tscn'den okunur) platonun üstünde durur ve
	# ateşi engelsiz görür: aradaki arazi görüş çizgisine yükselmemeli (kadraja tepe girmemeli).
	# K98 (2026-11-07; docs/media/review/kadraj_referans.webp): kampa uzaktan ve yukarıdan bakar, kamera zeminden
	# 14–22 m yukarıda, ateşe 35–50° aşağı bakar (4. referansın alçak kadrajı, 6–11 m ve 20–35°, kalktı).
	var camera_origin: Variant = _scene_node_origin(MAIN_SCENE, "./MenuCamera")
	var fire_origin: Variant = _scene_node_origin(WORLD_SCENE, "./Camp/Campfire")
	if not (camera_origin is Vector3 and fire_origin is Vector3):
		return
	var cam: Vector3 = camera_origin
	var focus: Vector3 = fire_origin + Vector3(0.0, FLAME_HEIGHT, 0.0)
	assert_almost(shape.plateau_mask(cam.x, cam.z), 1.0, 0.0001, "Menü kamerası platonun üstünde olmalı")
	var ground := shape.height_at(cam.x, cam.z)
	assert_true(absf(ground) < 0.3, "Kameranın altındaki zemin kamp düzleminde olmalı (y = %.2f)" % ground)
	assert_between(cam.y - ground, 14.0, 22.0, "Menü kamerası kampa yüksekten bakmalı (K98)")
	var to_fire := focus - cam
	var down_angle := rad_to_deg(atan2(-to_fire.y, Vector2(to_fire.x, to_fire.z).length()))
	assert_between(down_angle, 35.0, 50.0, "Menü kamerası ateşe yukarıdan bakmalı (K98)")
	var blocked := PackedVector2Array()
	for i in range(1, 20):
		var p := cam.lerp(focus, float(i) / 20.0)
		if shape.height_at(p.x, p.z) > p.y - 0.2:
			blocked.append(Vector2(p.x, p.z))
	assert_true(blocked.is_empty(), "Menü kamerası ile ateş arasındaki zemin görüşü kapatıyor: %s" % [blocked])


func test_stable_stands_on_a_flat_pad() -> void:
	# Ahır platonun vadiye bakan kenarındadır; altı (ahırın tamamı, atlar, bayrak ve heybeler için
	# ~4,5 m) kamp düzleminde kalmalı. Düz alan doğal yamaca yumuşakça bağlanmalı: geçiş doğal eğimi
	# en fazla ~20° dikleştirebilir (uçurum gibi bir basamak oluşmamalı), dışında arazi doğal kalır.
	var stable_origin: Variant = _scene_node_origin(WORLD_SCENE, "./Camp/Stable")
	if not stable_origin is Vector3:
		return
	var stable: Vector3 = stable_origin
	var worst := 0.0
	for p in _disk_grid(4.5, 0.5):
		worst = maxf(worst, absf(shape.height_at(stable.x + p.x, stable.z + p.y)))
	assert_true(worst < 0.02, "Ahırın altındaki zemin düz olmalı (|y| = %.3f m)" % worst)
	for pad in TerrainShape.FLAT_PADS:
		assert_almost(shape.flat_pad_weight(pad.x, pad.y), 1.0, 0.0001, "Düz alanın ortası tam düz olmalı")
		var outside := Vector2(pad.x + pad.z + pad.w + 0.1, pad.y)
		assert_almost(shape.flat_pad_weight(outside.x, outside.y), 0.0, 0.0001, "Düz alanın etkisi geçişten sonra bitmeli")
		assert_eq(shape.height_at(outside.x, outside.y), shape.natural_height_at(outside.x, outside.y), "Geçişin dışında arazi doğal kalmalı")
		var steepest := Vector2.ZERO
		var steepening := -INF
		for i in 24:
			var dir := Vector2.from_angle(TAU * float(i) / 24.0)
			var r := pad.z
			while r < pad.z + pad.w:
				var p := Vector2(pad.x, pad.y) + dir * r
				var extra := _slope_deg(shape.height_at, p) - _slope_deg(shape.natural_height_at, p)
				if extra > steepening:
					steepening = extra
					steepest = p
				r += 1.0
		assert_true(steepening < 20.0, "Düz alanın geçişi yamacı fazla dikleştiriyor: %s (+%.0f°)" % [steepest, steepening])


func test_camp_clearing_has_no_trees_or_cliff() -> void:
	# Orman 24 m'den, kayalık sırt 22 m'den önce başlamaz: kamp açıklığı temiz kalır.
	var forest := 0.0
	var cliff := 0.0
	for p in _disk_grid(22.0, 1.0):
		forest = maxf(forest, shape.forest_density(p.x, p.y))
		cliff = maxf(cliff, shape.cliff_mask(p.x, p.y))
	assert_eq(forest, 0.0, "Kamp açıklığında ağaç yoğunluğu olmamalı")
	assert_eq(cliff, 0.0, "Kayalık sırt kampa taşmamalı")


func test_cliff_ridge_stands_at_its_center() -> void:
	var c := TerrainShape.CLIFF_CENTER
	assert_true(shape.cliff_mask(c.x, c.y) > 0.9, "Sırtın merkezi kayalık olmalı (%.2f)" % shape.cliff_mask(c.x, c.y))
	assert_eq(shape.cliff_mask(0.0, -600.0), 0.0, "Göl ortasında kayalık olmamalı")


# --- Su, nehir ve göl ---------------------------------------------------------------

func test_far_river_and_lake_are_under_water() -> void:
	# Nehir/göl merkez hattı boyunca zemin suyun altında kalmalı (adacıkların üstü hariç).
	var dry: Array[float] = []
	var z := -160.0
	while z >= -2600.0:
		var river := shape.river_at(z)
		if not _on_island(river.x, z) and not shape.is_underwater(river.x, z):
			dry.append(z)
		z -= 20.0
	assert_true(dry.is_empty(), "Nehir merkezinin su üstünde kaldığı z değerleri: %s" % [dry])


func test_lake_at_z_minus_600_is_under_water() -> void:
	# z = -600'de göl çok geniştir; merkez hattı büyük adanın (10, -650) üstüne denk gelir.
	# Bu yüzden adanın iki yanındaki açık suyu örnekliyoruz.
	for x in [-60.0, -30.0, 50.0, 80.0]:
		assert_false(_on_island(x, -600.0), "Örnek nokta adada kalmamalı: x = %.0f" % x)
		assert_true(shape.is_underwater(x, -600.0), "(%.0f, -600) su altında olmalı, y = %.2f" % [x, shape.height_at(x, -600.0)])


func test_islands_rise_above_water() -> void:
	for island in TerrainShape.ISLANDS:
		assert_false(shape.is_underwater(island.x, island.y), "Ada su altında kaldı: %s" % island)


func test_side_lake_is_under_water() -> void:
	for lake in TerrainShape.SIDE_LAKES:
		assert_true(shape.is_underwater(lake.x, lake.y), "Yan göl su altında olmalı: %s" % lake)


func test_river_has_no_width_before_its_start() -> void:
	var start := TerrainShape.RIVER_POINTS[0].x
	for z in [300.0, 50.0, 0.0, -60.0, -100.0, start]:
		assert_eq(shape.river_at(z).y, 0.0, "Nehir henüz başlamamalı (z = %.0f)" % z)


func test_river_passes_through_its_control_points() -> void:
	for p in TerrainShape.RIVER_POINTS:
		var river := shape.river_at(p.x)
		assert_almost(river.x, p.y, 0.001, "Nehir merkezi kontrol noktasından geçmeli (z = %.0f)" % p.x)
		assert_almost(river.y, p.z, 0.001, "Nehir genişliği kontrol noktasındaki gibi olmalı (z = %.0f)" % p.x)


func test_river_widens_toward_the_lake() -> void:
	# Kaynaktan (z = -140) göle (z = -660) kadar nehir hiç daralmamalı.
	var narrowing: Array[float] = []
	var previous := 0.0
	var z := -140.0
	while z >= -660.0:
		var width := shape.river_at(z).y
		if width < previous - 0.0001:
			narrowing.append(z)
		previous = width
		z -= 5.0
	assert_true(narrowing.is_empty(), "Nehrin daraldığı z değerleri: %s" % [narrowing])
	assert_almost(previous, 185.0, 0.01, "Göl ağzında yarı genişlik 185 m olmalı")


func test_river_keeps_last_values_beyond_the_end() -> void:
	var last := TerrainShape.RIVER_POINTS[TerrainShape.RIVER_POINTS.size() - 1]
	for z in [last.x, -3000.0, -10000.0]:
		assert_eq(shape.river_at(z), Vector2(last.y, last.z), "z = %.0f" % z)


# --- Sayısal sağlamlık --------------------------------------------------------------

func test_heights_are_finite_and_sane_over_coarse_grid() -> void:
	var bad := PackedVector2Array()
	var lowest := INF
	var highest := -INF
	for p in _grid(Rect2(-3000.0, -3000.0, 6000.0, 6000.0), 61):
		var h := shape.height_at(p.x, p.y)
		if is_nan(h) or is_inf(h):
			bad.append(p)
			continue
		lowest = minf(lowest, h)
		highest = maxf(highest, h)
	assert_true(bad.is_empty(), "NaN/sonsuz yükseklik: %s" % [bad.slice(0, 5)])
	assert_between(lowest, -60.0, TerrainShape.WATER_LEVEL, "En alçak nokta (göl tabanı) beklenen aralıkta değil")
	assert_between(highest, 0.0, 400.0, "En yüksek nokta beklenen aralıkta değil")


func test_normals_are_unit_length_and_face_up() -> void:
	assert_vec_almost(shape.normal_at(0.0, 0.0), Vector3.UP, 0.0001, "Düz kampta normal tam yukarı bakmalı")
	var points := _grid(Rect2(-1500.0, -2500.0, 3000.0, 3000.0), 31)
	points.append(TerrainShape.CLIFF_CENTER)
	var worst_length_error := 0.0
	var lowest_y := 1.0
	var not_finite := 0
	for p in points:
		var n := shape.normal_at(p.x, p.y)
		if not n.is_finite():
			not_finite += 1
			continue
		worst_length_error = maxf(worst_length_error, absf(n.length() - 1.0))
		lowest_y = minf(lowest_y, n.y)
	assert_eq(not_finite, 0, "Sonlu olmayan normal bulundu")
	assert_true(worst_length_error < 0.0001, "Normal birim uzunlukta değil (hata %f)" % worst_length_error)
	assert_true(lowest_y > 0.0, "Aşağı bakan normal bulundu (en düşük y = %f)" % lowest_y)


func test_normal_leans_downhill_on_a_slope() -> void:
	# Yamaçta normal yokuş aşağı eğilir: y = 2x yamacında yönü (-2, 1, 0) olmalı.
	# (Sonlu farkların işareti ters olsa normal yine birim ve yukarı bakardı; bu test onu yakalar.)
	var rising_x := _tilted(2.0, 0.0).normal_at(5.0, -3.0)
	assert_vec_almost(rising_x, Vector3(-2.0, 1.0, 0.0).normalized(), 0.0001, "+X yönünde yükselen yamaç")
	var falling_z := _tilted(0.0, -0.5).normal_at(5.0, -3.0)
	assert_vec_almost(falling_z, Vector3(0.0, 1.0, 0.5).normalized(), 0.0001, "+Z yönünde alçalan yamaç")
	# Gerçek arazide: kamptan vadiye (-Z) inen yamaçta normalin z bileşeni eksi olmalı.
	assert_true(shape.normal_at(0.0, -40.0).z < 0.0, "Vadiye bakan yamacın normali vadiye (-Z) eğilmeli")


func test_masks_stay_between_zero_and_one() -> void:
	var out_of_range := 0
	for p in _grid(Rect2(-1500.0, -2500.0, 3000.0, 3000.0), 41):
		var tint := shape.vertex_tint(p.x, p.y)
		for value in [shape.plateau_mask(p.x, p.y), shape.forest_density(p.x, p.y), shape.cliff_mask(p.x, p.y), tint.r, tint.g, tint.b]:
			if value < 0.0 or value > 1.0:
				out_of_range += 1
		if tint.a != 1.0:
			out_of_range += 1
	assert_eq(out_of_range, 0, "0..1 aralığı dışında maske değeri bulundu")


# --- Terrain (arazi meshi) ------------------------------------------------------------

func test_ring_radius_spans_inner_to_outer_with_constant_ratio() -> void:
	var inner := 0.6
	var outer := 3600.0
	var count := 12
	assert_almost(Terrain.ring_radius(0, count, inner, outer), inner, 0.0001)
	assert_almost(Terrain.ring_radius(count - 1, count, inner, outer), outer, 0.01)
	var ratio := Terrain.ring_radius(1, count, inner, outer) / inner
	assert_true(ratio > 1.0, "Halkalar dışa doğru büyümeli")
	for i in range(1, count):
		var step := Terrain.ring_radius(i, count, inner, outer) / Terrain.ring_radius(i - 1, count, inner, outer)
		assert_almost(step, ratio, 0.0001, "Halka aralığı üstel olmalı (halka %d)" % i)


func test_terrain_mesh_matches_shape_and_faces_up() -> void:
	var segments := 24
	var rings := 10
	var arrays := _terrain_arrays(Terrain.build_mesh(shape, segments, rings, 0.6, 3600.0))
	if arrays.is_empty():
		return
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	assert_eq(vertices.size(), segments * rings + 1, "Köşe sayısı: halka × bölüt + merkez")
	assert_eq(indices.size(), segments * 3 + (rings - 1) * segments * 6, "Merkez yelpazesi + halka şeritleri")
	assert_eq(colors.size(), vertices.size())
	var invalid := 0
	for index in indices:
		if index < 0 or index >= vertices.size():
			invalid += 1
	assert_eq(invalid, 0, "Geçersiz üçgen indeksi")
	if invalid > 0 or indices.size() % 3 != 0:
		return
	# Godot'da ön yüz için dış normal cross(c - a, b - a) olmalı; arazi yukarıdan görünmeli.
	var facing_down := 0
	for i in range(0, indices.size(), 3):
		var a := vertices[indices[i]]
		if (vertices[indices[i + 2]] - a).cross(vertices[indices[i + 1]] - a).y <= 0.0:
			facing_down += 1
	assert_eq(facing_down, 0, "Aşağı bakan üçgen bulundu")
	var mismatched := 0
	var wrong_tint := 0
	for i in vertices.size():
		var v := vertices[i]
		if absf(v.y - shape.height_at(v.x, v.z)) > 0.01 or normals[i].y <= 0.0:
			mismatched += 1
		# Köşe renkleri 8 bit saklanır: 1/255'lik yuvarlama payı bırak.
		var tint := shape.vertex_tint(v.x, v.z)
		var c := colors[i]
		if maxf(maxf(absf(c.r - tint.r), absf(c.g - tint.g)), absf(c.b - tint.b)) > 0.005:
			wrong_tint += 1
	assert_eq(mismatched, 0, "Mesh köşeleri TerrainShape yüksekliğiyle örtüşmüyor ya da normali aşağı bakıyor")
	assert_eq(wrong_tint, 0, "Köşe renkleri TerrainShape.vertex_tint ile örtüşmüyor")


# --- Yardımcılar ---------------------------------------------------------------------

## Vadiye yayılmış, her çalıştırmada aynı olan rastgele noktalar (kampın dışında).
static func _sample_points(count: int, rng_seed: int) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var points := PackedVector2Array()
	for i in count:
		points.append(Vector2(rng.randf_range(-800.0, 800.0), rng.randf_range(-1500.0, -60.0)))
	return points


## Dikdörtgeni n × n düzgün ızgarayla örnekler (kenarlar dahil).
static func _grid(area: Rect2, n: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in n:
		for j in n:
			points.append(area.position + area.size * Vector2(float(i), float(j)) / float(n - 1))
	return points


## Merkezdeki diskin içinde kalan ızgara noktaları (adım metre cinsinden).
static func _disk_grid(radius: float, step: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count := floori(radius * 2.0 / step)
	for i in count + 1:
		for j in count + 1:
			var p := Vector2(-radius + step * float(i), -radius + step * float(j))
			if p.length() <= radius:
				points.append(p)
	return points


## Bir yükseklik fonksiyonunun (x, z) → y noktadaki eğimi (derece; merkezî farklarla).
static func _slope_deg(height: Callable, p: Vector2, eps: float = 0.5) -> float:
	var gx := (float(height.call(p.x + eps, p.y)) - float(height.call(p.x - eps, p.y))) / (2.0 * eps)
	var gz := (float(height.call(p.x, p.y + eps)) - float(height.call(p.x, p.y - eps))) / (2.0 * eps)
	return rad_to_deg(atan(Vector2(gx, gz).length()))


## Disk içindeki en büyük |yükseklik| ve yeri: Vector3(değer, x, z).
func _worst_height_in_disk(radius: float, step: float) -> Vector3:
	var worst := Vector3.ZERO
	for p in _disk_grid(radius, step):
		var h := absf(shape.height_at(p.x, p.y))
		if h > worst.x:
			worst = Vector3(h, p.x, p.y)
	return worst


## Bir sahnedeki düğümün kayıtlı konumu, sahne kökünün uzayında (ara düğümlerin dönüşümleri de
## eklenir). Sahne örneklenmez (dünya kurulmaz): PackedScene.get_state() ile yalnızca kayıtlı
## "transform" özellikleri okunur. node_path sahne kayıtlarındaki biçimdedir (ör. "./Camp/Campfire").
## Düğüm bulunamazsa testi başarısız sayar ve null döndürür.
func _scene_node_origin(scene_path: String, node_path: String) -> Variant:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		fail("Sahne yüklenemedi: %s" % scene_path)
		return null
	var state := packed.get_state()
	var local_transforms := {}
	for i in state.get_node_count():
		var local := Transform3D.IDENTITY
		for j in state.get_node_property_count(i):
			if state.get_node_property_name(i, j) == &"transform":
				local = state.get_node_property_value(i, j)
		local_transforms[String(state.get_node_path(i))] = local
	if not local_transforms.has(node_path):
		fail("%s içinde %s düğümü bulunamadı" % [scene_path, node_path])
		return null
	var xform := Transform3D.IDENTITY
	var path := node_path
	while path != "." and not path.is_empty():
		xform = (local_transforms.get(path, Transform3D.IDENTITY) as Transform3D) * xform
		path = path.get_base_dir()
	return xform.origin


## Nokta herhangi bir adacığın üstünde mi?
static func _on_island(x: float, z: float) -> bool:
	for island in TerrainShape.ISLANDS:
		if Vector2(x - island.x, z - island.y).length() < island.z:
			return true
	return false


## Arazi meshinin dizileri. Tek yüzey yoksa ya da köşe/normal/renk/indeks dizilerinden biri eksikse
## testi başarısız sayar ve boş dizi döndürür. (Eksik diziyi tipli bir değişkene atamak betik
## hatasıdır; Godot testi yarıda keser ve koşucu onu "geçti" gösterirdi.)
func _terrain_arrays(mesh: Mesh) -> Array:
	assert_eq(mesh.get_surface_count(), 1, "Arazi meshi tek yüzeyli olmalı")
	if mesh.get_surface_count() == 0:
		return []
	var arrays := mesh.surface_get_arrays(0)
	for slot in TERRAIN_ARRAYS:
		var expected: Array = TERRAIN_ARRAYS[slot]
		if typeof(arrays[slot]) != expected[0]:
			fail("Arazi meshinde %s dizisi yok" % expected[1])
			return []
	return arrays


## Eğik düzlem biçiminde sahte arazi: y = slope_x · x + slope_z · z.
static func _tilted(slope_x: float, slope_z: float) -> TerrainShape:
	var tilted := _TiltedShape.new()
	tilted.slope = Vector2(slope_x, slope_z)
	return tilted


class _TiltedShape extends TerrainShape:
	var slope := Vector2.ZERO

	func height_at(x: float, z: float) -> float:
		return slope.x * x + slope.y * z
