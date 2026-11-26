extends TestCase
## Orman (Forest) ve çam yardımcıları (TreeKit) testleri.
##
## Saf kurallar: prosedürel ladinin biçimi (dışa bakan üçgenler, ~10 birim boy, gövde/yaprak renkleri),
## Meshy meshinin konumla birleştirilmesi ve sadeleştirilmesi, dal konisi ve takip kamerasının görüş hattı,
## küme noktaları, küme ağacının boyu, çamın dünya dönüşümü ve menü kadrajındaki vadi seyreltmesi.
## Dünya testleri (world.tscn): kamp ve küme çamları Meshy modeliyle (LOD zinciri gömülü mesh) kurulur,
## patikalara ve engellere girmez, takip kamerasının görüşünü kapatmaz, gövdeleri engel listesindedir,
## kamera örtmesi malzemelere ulaşır; modeller kapatılınca prosedürel ladinlerle hatasız kurulur.

const WORLD_SCENE := "res://scenes/world/world.tscn"

var _world: World


# --- Prosedürel ladin ---------------------------------------------------------------

func test_spruce_has_trunk_and_foliage_and_stands_ten_units_tall() -> void:
	var mesh := TreeKit.spruce(11, 7, 7)
	var arrays := mesh.surface_get_arrays(0)
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var trunk := 0
	var foliage := 0
	for c in colors:
		if c.a == 0.0:
			trunk += 1
		elif c.a == 1.0:
			foliage += 1
	assert_true(trunk > 0, "Gövde köşesi olmalı (COLOR.a = 0)")
	assert_true(foliage > trunk, "Yapraklı katlar gövdeden büyük olmalı")
	var box := mesh.get_aabb()
	assert_between(box.position.y, -0.8, 0.01, "Ağaç yerden başlamalı (sarkık dal uçları biraz aşağı inebilir)")
	assert_between(box.end.y, 9.0, 10.6, "Ağaç boyu ~10 birim (TreeKit.UNIT_HEIGHT) olmalı")
	assert_between(maxf(box.size.x, box.size.z) / box.end.y, 0.4, 0.62, "Siluet Meshy ladini gibi ince olmalı")
	var again := TreeKit.spruce(11, 7, 7).surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array
	assert_true(again == (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array), "Aynı tohum aynı ağacı vermeli")


func test_spruce_faces_point_outward_for_back_face_culling() -> void:
	# foliage.gdshader arka yüzleri çizmez (cull_back): her üçgen dışarıdan bakınca saat yönünde olmalı.
	for mesh in [TreeKit.spruce(11, 7, 7), TreeKit.spruce(14, 3, 4)]:
		var arrays := (mesh as ArrayMesh).surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var inward := 0
		for i in range(0, indices.size(), 3):
			var a := verts[indices[i]]
			var b := verts[indices[i + 1]]
			var c := verts[indices[i + 2]]
			var center := (a + b + c) / 3.0
			if (c - a).cross(b - a).dot(Vector3(center.x, 0.0, center.z)) <= 0.0:
				inward += 1
		assert_eq(inward, 0, "İçe bakan üçgen olmamalı")


func test_spruce_colours_come_from_the_meshy_pine_palette() -> void:
	var palette := TreeKit.palette()
	var colors: PackedColorArray = TreeKit.spruce(12, 8, 7).surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	var lo := Color(1, 1, 1)
	var hi := Color(0, 0, 0)
	for c in colors:
		if c.a < 1.0:
			continue
		lo = Color(minf(lo.r, c.r), minf(lo.g, c.g), minf(lo.b, c.b))
		hi = Color(maxf(hi.r, c.r), maxf(hi.g, c.g), maxf(hi.b, c.b))
	# Yaprak renkleri koyu ile açık palet tonu arasında kalır (sRGB; köşe rengi 8 bit saklanır).
	assert_true(lo.g >= palette[0].g - 0.005 and hi.g <= palette[2].g + 0.005, "Yaprak yeşili paletin içinde olmalı: %s – %s" % [lo, hi])
	assert_true(hi.g > hi.r and hi.g > hi.b, "Yapraklar yeşil olmalı")


# --- Meshy meshinin birleştirilmesi -----------------------------------------------------

func test_weld_by_position_merges_seam_duplicates_and_averages_colours() -> void:
	# İki üçgenlik bir kare: köşegen kenarındaki iki köşe UV dikişi gibi ikişer kez yazılmış.
	var verts := PackedVector3Array([Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0, 0, 1),
			Vector3(1, 0, 0), Vector3(1, 0, 1), Vector3(0, 0, 1)])
	var normals := PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP])
	var uvs := PackedVector2Array([Vector2(0.25, 0.5), Vector2(0.25, 0.5), Vector2(0.25, 0.5),
			Vector2(0.75, 0.5), Vector2(0.75, 0.5), Vector2(0.75, 0.5)])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 3, 4, 5])
	# Sol yarısı kırmızı, sağ yarısı mavi bir doku.
	var image := Image.create(4, 1, false, Image.FORMAT_RGB8)
	for x in 4:
		image.set_pixel(x, 0, Color(1, 0, 0) if x < 2 else Color(0, 0, 1))
	var welded := TreeKit.weld_by_position(arrays, image, Transform3D.IDENTITY, Color.WHITE, 0.0)
	var out_v: PackedVector3Array = welded[Mesh.ARRAY_VERTEX]
	var out_c: PackedColorArray = welded[Mesh.ARRAY_COLOR]
	var out_i: PackedInt32Array = welded[Mesh.ARRAY_INDEX]
	assert_eq(out_v.size(), 4, "Altı köşe dört konuma birleşmeli")
	assert_eq(out_i.size(), 6, "Üçgenler korunmalı")
	for k in out_i.size():
		assert_eq(out_v[out_i[k]], verts[k], "İndeks aynı konumu göstermeli")
	# Dikişteki köşe (1,0,0) hem kırmızı hem mavi örneklerden oluşur → ikisinin ortası (sRGB).
	var seam := out_c[out_i[1]]
	assert_almost(seam.r, 0.5, 0.01, "Dikiş köşesinin rengi iki tarafın ortalaması olmalı: %s" % seam)
	assert_almost(seam.b, 0.5, 0.01, "Dikiş köşesinin rengi iki tarafın ortalaması olmalı: %s" % seam)
	assert_almost(out_c[out_i[0]].r, 1.0, 0.01, "Yalnız sol üçgendeki köşe kırmızı kalmalı")
	assert_almost(out_c[out_i[4]].b, 1.0, 0.01, "Yalnız sağ üçgendeki köşe mavi kalmalı")
	assert_almost(seam.a, 0.0, 0.0001, "Alfa verilen değer olmalı")


func test_simplify_reduces_a_welded_sphere_towards_the_target() -> void:
	var data := MeshKit.icosphere_data(4)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	var verts: PackedVector3Array = data[0]
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = MeshKit.smooth_normals(verts, data[1])
	var colors := PackedColorArray()
	colors.resize(verts.size())
	colors.fill(Color(0.5, 0.5, 0.5, 0.0))
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = data[1]
	var full := (data[1] as PackedInt32Array).size() / 3
	var mesh := TreeKit.simplify(arrays, 600)
	var tris := (mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	assert_true(tris < full / 2, "Sadeleştirilmiş mesh belirgin derecede az üçgenli olmalı (%d / %d)" % [tris, full])
	assert_between(float(tris), 150.0, 2400.0, "Hedefe (600) yakın olmalı")
	var used := (mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	assert_true(used < verts.size(), "Kullanılmayan köşeler atılmalı")


func test_sample_image_is_bilinear_and_wraps() -> void:
	var image := Image.create(2, 1, false, Image.FORMAT_RGB8)
	image.set_pixel(0, 0, Color(0, 0, 0))
	image.set_pixel(1, 0, Color(1, 1, 1))
	assert_almost(TreeKit.sample_image(image, Vector2(0.25, 0.5)).r, 0.0, 0.01, "Piksel merkezi")
	assert_almost(TreeKit.sample_image(image, Vector2(0.5, 0.5)).r, 0.5, 0.01, "İki piksel arası ortalama")
	assert_almost(TreeKit.sample_image(image, Vector2(1.25, 0.5)).r, 0.0, 0.01, "UV tekrarlanır")


# --- Dal konisi ve görüş hattı -----------------------------------------------------------

func test_cone_radius_narrows_to_the_top() -> void:
	assert_almost(TreeKit.cone_radius(1.0, 1.0), TreeKit.CONE_BASE_RADIUS, 0.001, "Dalların başladığı yerde taban yarıçapı")
	assert_almost(TreeKit.cone_radius(0.5, 5.0), TreeKit.CONE_TOP_RADIUS * 0.5, 0.001, "Tepede (ölçek birimiyle)")
	assert_true(TreeKit.cone_radius(1.0, 6.0) < TreeKit.cone_radius(1.0, 3.0), "Yukarı doğru daralmalı")
	assert_eq(TreeKit.cone_radius(1.0, 0.2), 0.0, "Gövdenin dibinde dal yok")
	assert_eq(TreeKit.cone_radius(1.0, 12.0), 0.0, "Tepenin üstünde dal yok")


func test_sight_clearance_is_negative_through_the_branches() -> void:
	var tree := Vector4(0.0, 0.0, 0.6, 1.0)
	var through := TreeKit.sight_clearance(Vector3(0.0, 6.0, 6.0), Vector3(0.0, 1.0, -2.0), tree, 0.0)
	assert_true(through < 0.0, "Ağacın içinden geçen görüş hattı eksi pay vermeli (%.2f)" % through)
	var beside := TreeKit.sight_clearance(Vector3(6.0, 6.0, 6.0), Vector3(6.0, 1.0, -2.0), tree, 0.0)
	assert_true(beside > 2.0, "6 m yandaki görüş hattı ağaca değmemeli (%.2f)" % beside)
	var above := TreeKit.sight_clearance(Vector3(0.0, 20.0, 6.0), Vector3(0.0, 15.0, -2.0), tree, 0.0)
	assert_eq(above, INF, "Ağacın çok üstünden geçen hat koniye yaklaşmaz")


func test_blocks_view_uses_eye_focus_pairs() -> void:
	var views: Array[Vector3] = [Vector3(0.0, 7.6, 5.8), Vector3(0.0, 0.7, 0.0)]
	assert_true(Forest.blocks_view(Vector4(0.0, 3.0, 0.6, 1.0), views, 0.0, 0.3), "Oyuncunun güneyindeki uzun çam görüşü kapatır")
	assert_false(Forest.blocks_view(Vector4(0.0, -3.0, 0.6, 1.0), views, 0.0, 0.3), "Oyuncunun kuzeyindeki çam görüşü kapatmaz")
	assert_false(Forest.blocks_view(Vector4(5.0, 3.0, 0.6, 1.0), views, 0.0, 0.3), "Yandaki çam görüşü kapatmaz")


func test_path_views_put_the_eye_south_of_and_above_each_point() -> void:
	var segments: Array[Vector4] = [Vector4(0.0, 0.0, 4.0, 0.0)]
	var views := Forest.path_views(segments, _FlatShape.new())
	assert_eq(views.size(), 4, "Her parça için baş ve orta: iki göz-odak çifti")
	for k in range(0, views.size(), 2):
		var eye := views[k]
		var focus := views[k + 1]
		assert_almost(focus.y, Forest.VIEW_LOOK_HEIGHT, 0.001, "Odak ayakların biraz üstünde")
		assert_almost(eye.distance_to(focus), Forest.VIEW_DISTANCE, 0.01, "Kamera uzaklığı")
		assert_true(eye.z > focus.z and eye.y > focus.y, "Kamera oyuncunun güneyinde ve yukarıda")


# --- Kümeler ve çam yerleşimi -------------------------------------------------------------

func test_grove_points_stay_in_the_disc_and_keep_their_distance() -> void:
	var grove := Vector4(10.0, -5.0, 6.0, 12.0)
	var points := Forest.grove_points(grove, 7, 1.5)
	assert_true(points.size() > 6 and points.size() <= 12, "Kümede istenen kadar (en fazla) nokta olmalı (%d)" % points.size())
	for i in points.size():
		assert_true(points[i].distance_to(Vector2(grove.x, grove.y)) <= grove.z + 0.001, "Nokta diskin içinde olmalı")
		for j in i:
			assert_true(points[i].distance_to(points[j]) >= 1.5, "Noktalar birbirinden en az 1,5 m uzak olmalı")
	assert_eq(Forest.grove_points(grove, 7, 1.5), points, "Aynı tohum aynı kümeyi vermeli")


func test_grove_trees_grow_taller_away_from_the_camp() -> void:
	var near := Vector2(3.5, 6.5)
	var far := Vector2(7.0, 12.0)
	var close_h := Forest.grove_tree_height(Vector2(8.0, 0.0), 0.0, 1.0, near, far)
	var far_h := Forest.grove_tree_height(Vector2(0.0, -40.0), 0.0, 1.0, near, far)
	assert_almost(close_h, near.y, 0.001, "Kampa yakın küme ağacı kısa aralıkta")
	assert_almost(far_h, far.y, 0.001, "Uzak küme ağacı uzun aralıkta")
	var rim := Forest.grove_tree_height(Vector2(0.0, -40.0), 1.0, 1.0, near, far)
	assert_true(rim < far_h, "Kümenin kenarındaki ağaç ortadakinden kısa")
	assert_true(rim >= far.x, "Kenardaki ağaç da aralığın içinde kalır")


func test_tree_transform_puts_the_model_on_the_ground_at_the_right_size() -> void:
	# Meshy ladini gibi geniş (en/boy 0,75) ve merkezi kaymış bir model kutusu.
	var box := AABB(Vector3(-0.72, -0.94, -0.69), Vector3(1.46, 1.89, 1.39))
	var tree := Vector4(4.0, -6.0, 0.9, 3.0)
	var xform := Forest.tree_transform(tree, 1.5, box)
	var lowest := INF
	var highest := -INF
	var widest := 0.0
	for i in 8:
		var corner := box.position + box.size * Vector3(i & 1, (i >> 1) & 1, (i >> 2) & 1)
		var p := xform * corner
		lowest = minf(lowest, p.y)
		highest = maxf(highest, p.y)
	var bottom := xform * Vector3(box.get_center().x, box.position.y, box.get_center().z)
	assert_vec_almost(bottom, Vector3(4.0, 1.5 - Forest.SINK, -6.0), 0.001, "Kutunun taban ortası ağacın yerinde, zemine gömülü")
	assert_almost(highest - lowest, TreeKit.tree_height(0.9), 0.001, "Boy ölçek × 10 m olmalı")
	widest = (xform.basis.x.length() * box.size.x + xform.basis.z.length() * box.size.z) * 0.5
	assert_true(widest / TreeKit.tree_height(0.9) <= Forest.width_ratio(9.0) + 0.001, "En/boy oranı sınırı aşmamalı")


func test_width_ratio_makes_tall_pines_slimmer() -> void:
	assert_almost(Forest.width_ratio(3.0), Forest.WIDTH_RATIO.x, 0.001)
	assert_almost(Forest.width_ratio(14.0), Forest.WIDTH_RATIO.y, 0.001)
	assert_true(Forest.width_ratio(8.0) < Forest.width_ratio(4.0), "Uzun çam daha ince")
	# Her çam takip kamerası testlerindeki dal konisinin içinde kalır (tabanda 0,28 × boy yarıçap).
	assert_true(Forest.WIDTH_RATIO.x * 0.5 <= TreeKit.CONE_BASE_RADIUS / TreeKit.UNIT_HEIGHT, "Taban yarıçapı dal konisine sığmalı")


func test_view_keep_thins_the_valley_only_inside_the_menu_wedge() -> void:
	var wedge := Vector4(30.0, 330.0, 40.0, 0.3)
	assert_eq(Forest.view_keep(Vector2(0.0, -10.0), wedge, 0.5), 1.0, "Kama yakınında (kamp) seyreltme yok")
	assert_eq(Forest.view_keep(Vector2(0.0, 40.0), wedge, 0.5), 1.0, "Kameranın arkasında seyreltme yok")
	assert_eq(Forest.view_keep(Vector2(-300.0, -100.0), wedge, 0.5), 1.0, "Kadrajın dışında seyreltme yok")
	assert_almost(Forest.view_keep(Vector2(0.0, -150.0), wedge, 0.5), 0.3, 0.001, "Kadrajın ortasında ağaçların bir kısmı kalır")
	assert_true(Forest.view_keep(Vector2(0.0, -150.0), wedge, 1.0) > Forest.view_keep(Vector2(0.0, -150.0), wedge, 0.1), "Öbeklerde daha çok ağaç kalır")


func test_lake_view_cap_keeps_tree_tops_below_the_menu_sight_line() -> void:
	var eye := Forest.MENU_EYE
	# Kampın arkasındaki çayırda (pencerenin ortası) kısa ağaçlar: tepe, gözden 8° aşağı inen çizgide.
	var p := Vector2(0.0, -24.0)
	var d := Vector2(p.x - eye.x, p.y - eye.z).length()
	var expected := eye.y - d * tan(deg_to_rad(Forest.LAKE_WINDOW.w))
	assert_almost(Forest.lake_view_cap(p, 0.0), expected, 0.01, "Çayırdaki sınır bakış çizgisinin yüksekliği olmalı")
	assert_between(Forest.lake_view_cap(p, 0.0), 2.0, 4.5, "Çayırın kenarındaki çamlar referanstaki gibi genç ve kısa")
	assert_almost(Forest.lake_view_cap(p, -6.0), expected + 6.0, 0.01, "Yamaçta aşağıdaki ağaç daha uzun olabilir")
	assert_eq(Forest.lake_view_cap(Vector2(-30.0, -5.0), 0.0), INF, "Kadrajın solunda (dışında) sınır yok")
	assert_eq(Forest.lake_view_cap(Vector2(30.0, -20.0), 0.0), INF, "Ahırın arkasında (pencerenin sağı) sınır yok")
	assert_eq(Forest.lake_view_cap(Vector2(0.0, 20.0), 0.0), INF, "Kameranın arkasında sınır yok")
	assert_eq(Forest.lake_view_cap(Vector2(0.0, -400.0), -36.0), INF, "Gölün ötesindeki uzak vadide sınır yok")
	# Menü kadrajında çayırın kenarının hemen üstünde görünen vadi tabanı (~140–300 m) da sınırlıdır: orman
	# şeridinin uzak ağaçları gölün yakın kıyısını örtmez. Kadrajın sol kenarındaki çamlar da (4. referansta
	# vadinin aydınlık tepeleri önünde kısa ladinler) sınırın içindedir.
	var band := Vector2(0.0, -200.0)
	var band_expected := eye.y - Vector2(band.x - eye.x, band.y - eye.z).length() * tan(deg_to_rad(Forest.LAKE_WINDOW.w)) + 26.0
	assert_almost(Forest.lake_view_cap(band, -26.0), band_expected, 0.01, "Vadi tabanındaki orman şeridi de sınırlı olmalı")
	assert_between(Forest.lake_view_cap(Vector2(-16.65, -13.83), 0.0), 2.5, 4.5, "Kadrajın sol kenarındaki çamlar kısa kalmalı")
	# Pencerenin kenarına doğru sınır yumuşakça gevşer (ani bir boy sıçraması olmaz).
	var inner := Forest.lake_view_cap(Vector2(5.5, -30.0), 0.0)
	var edge := Forest.lake_view_cap(Vector2(9.5, -30.0), 0.0)
	assert_true(edge > inner, "Pencerenin kenarında sınır gevşemeli (%.1f → %.1f m)" % [inner, edge])


func test_capped_height_stays_below_the_cap_with_ragged_tops() -> void:
	# Sınıra takılan ağaçlar sınırın LAKE_CAP_LOW katı ile tamamı arasına iner: tepeler bakış çizgisini hiç aşmaz
	# ama tek bir düz çizgide (budanmış çit gibi) dizilmez.
	var cap := 8.0
	assert_eq(Forest.capped_height(3.0, cap, 0.0), 3.0, "Sınırın alt payından kısa ağaç değişmez")
	assert_eq(Forest.capped_height(12.0, INF, 0.3), 12.0, "Pencerenin dışında (INF) ağaç değişmez")
	assert_almost(Forest.capped_height(12.0, cap, 1.0), cap, 0.0001, "En uzun zar sınıra kadar çıkar")
	assert_almost(Forest.capped_height(12.0, cap, 0.0), cap * Forest.LAKE_CAP_LOW, 0.0001, "En kısa zar sınırın alt payında")
	var previous := 0.0
	for i in 11:
		var h := Forest.capped_height(12.0, cap, float(i) / 10.0)
		assert_true(h <= cap + 0.0001, "Tepe sınırı aşmamalı (%.2f m)" % h)
		assert_true(h >= previous, "Zar büyüdükçe ağaç kısalmamalı")
		previous = h
	assert_true(Forest.capped_height(12.0, -2.0, 0.5) < Forest.MIN_TREE_HEIGHT, "Sınır zeminin altındaysa ağaç dikilmez")


func test_lake_window_keeps_the_old_menu_eye() -> void:
	# Göl penceresi K98'den önceki menü kamerasının gözünden ölçülür ve orada kalır: menü kamerası yukarı ve geriye taşındı
	# (ateşe 26,4 m, 38°), ağaçların boyu ve onaylı WIDE karesi değişmesin diye göz taşınmaz. Yeni kamera gözün üstünden bakar.
	assert_vec_almost(Forest.MENU_EYE, Vector3(0.27, 8.39, 13.86), 0.001, "Göl penceresinin gözü eski menü kamerasının yeri")
	var packed := load("res://scenes/main.tscn") as PackedScene
	var state := packed.get_state()
	for i in state.get_node_count():
		if state.get_node_name(i) != &"MenuCamera":
			continue
		for k in state.get_node_property_count(i):
			if state.get_node_property_name(i, k) == &"transform":
				var xform: Transform3D = state.get_node_property_value(i, k)
				assert_true(xform.origin.y > Forest.MENU_EYE.y + 5.0, "Menü kamerası gözün üstünde: %s" % xform.origin)
				assert_true(xform.origin.z > Forest.MENU_EYE.z, "Menü kamerası gözün gerisinde: %s" % xform.origin)
				return
	fail("scenes/main.tscn içinde MenuCamera bulunamadı")


func test_trunk_ground_takes_the_lowest_point_on_a_slope() -> void:
	var shape := _SlopeShape.new()
	assert_almost(Forest.trunk_ground(shape, Vector2(0.0, 0.0), 0.5), -0.5, 0.001, "Yokuş aşağı taraftaki zemin")


# --- Dünya ------------------------------------------------------------------------------

func test_world_pines_use_the_meshy_spruce_with_a_lod_chain() -> void:
	var world := await _get_world()
	var forest := world.get_node_or_null(^"Forest") as Forest
	assert_not_null(forest, "Dünyada Forest olmalı")
	if forest == null:
		return
	var planted := forest.get_planted_trees()
	assert_true(planted.size() > forest.camp_trees.size() + 20, "Kamp çamlarına ek olarak küme ağaçları dikilmeli (%d)" % planted.size())
	var pines := forest.find_children("Pine*", "MeshInstance3D", true, false)
	assert_eq(pines.size(), planted.size(), "Her çam ayrı bir MeshInstance3D olmalı")
	if pines.is_empty():
		return
	var first := pines[0] as MeshInstance3D
	if MeshyProp.exists(TreeKit.FOLDER, forest.young_model):
		var mesh := first.mesh as ArrayMesh
		assert_not_null(mesh, "Çam meshi ArrayMesh olmalı")
		if mesh:
			assert_true(RenderingServer.mesh_get_surface(mesh.get_rid(), 0).get("lods", []).size() > 1, "Meshte LOD zinciri gömülü olmalı")
			assert_true(mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR] != null, "Doku köşe rengine işlenmiş olmalı")
	var mat := first.material_override as ShaderMaterial
	assert_true(mat != null and mat.shader == Forest.FOLIAGE_SHADER, "Çamlar foliage malzemesiyle çizilmeli")
	# Gölgeyi çamın kendisi ya da sade düzeydeki gölge kopyası ("Shadow", yalnız gölge) düşürür (bütçe kesintisi).
	var shadowed := 0
	for node in pines:
		var proxy := node.get_node_or_null(^"Shadow") as MeshInstance3D
		if (node as MeshInstance3D).cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF \
				or (proxy and proxy.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY):
			shadowed += 1
	assert_true(shadowed > 0 and shadowed < pines.size(), "Yalnızca kampa yakın çamlar gölge düşürmeli (%d / %d)" % [shadowed, pines.size()])


func test_world_pines_keep_clear_of_paths_obstacles_and_the_default_view() -> void:
	var world := await _get_world()
	var forest := world.get_node_or_null(^"Forest") as Forest
	var net := world.get_node_or_null(^"PathNetwork") as PathNetwork
	if forest == null or net == null:
		fail("Forest ya da PathNetwork yok")
		return
	var shape := world.get_terrain_shape()
	var views := Forest.path_views(net.get_segments(), shape)
	var others: Array[Vector3] = []
	for node in world.get_tree().get_nodes_in_group(World.OBSTACLE_GROUP):
		if node != forest and node.has_method("get_obstacle_circles"):
			others.append_array(node.get_obstacle_circles())
	for tree in forest.get_planted_trees():
		var p := Vector2(tree.x, tree.y)
		var trunk := TreeKit.trunk_radius(TreeKit.tree_height(tree.z))
		assert_true(net.distance_to_paths(p) > trunk + 0.3, "Çam patikanın üstünde: %s" % tree)
		assert_false(Scatter.is_blocked(p.x, p.y, others, trunk), "Çam bir engelin (kaya, kamp nesnesi) içinde: %s" % tree)
		var clearance := INF
		for k in range(0, views.size() - 1, 2):
			clearance = minf(clearance, TreeKit.sight_clearance(views[k], views[k + 1], tree, shape.height_at(tree.x, tree.y)))
		# Dallar görüş hattına en fazla kamera örtmesinin tam saydam çekirdeği kadar girebilir (oyuncu görünür kalır).
		assert_true(clearance > -Forest.OCCLUSION_CORE, "Çam takip kamerasıyla patikadaki oyuncu arasında: %s (%.2f m)" % [tree, clearance])


func test_world_pines_keep_the_lake_visible_from_the_menu() -> void:
	# 4. referansta göl kadrajın üstünde açıkça görünür: göl penceresindeki kamp ve küme çamlarının tepesi
	# menü gözünden göle inen bakış çizgisini aşmaz; kampın arkasındaki çayırda genç ladin öbekleri vardır.
	var world := await _get_world()
	var forest := world.get_node_or_null(^"Forest") as Forest
	if forest == null:
		fail("Forest yok")
		return
	var shape := world.get_terrain_shape()
	var meadow_pines := 0
	for tree in forest.get_planted_trees():
		var p := Vector2(tree.x, tree.y)
		var cap := Forest.lake_view_cap(p, shape.height_at(p.x, p.y))
		assert_true(TreeKit.tree_height(tree.z) <= cap + 0.05, "Çam gölün önünü kapatıyor: %s (en fazla %.1f m)" % [tree, cap])
		if p.y < -15.0 and p.y > -30.0 and absf(p.x) < 16.0:
			meadow_pines += 1
	assert_true(meadow_pines >= 6, "Kampın arkasındaki çayırda genç ladin öbekleri olmalı (%d)" % meadow_pines)


func test_world_pine_trunks_are_obstacles_and_branches_fade_for_the_camera() -> void:
	var world := await _get_world()
	var forest := world.get_node_or_null(^"Forest") as Forest
	if forest == null:
		fail("Forest yok")
		return
	assert_true(forest.is_in_group(World.OBSTACLE_GROUP), "Çam gövdeleri engel grubunda olmalı")
	assert_true(forest.is_in_group(FollowCamera.OCCLUDER_GROUP), "Çamlar kamera örtme grubunda olmalı")
	var circles := world.collect_obstacles()
	for tree in forest.camp_trees:
		var expected := Vector3(tree.x, tree.y, TreeKit.trunk_radius(TreeKit.tree_height(tree.z)))
		assert_true(circles.has(expected), "Kamp çamının gövdesi engel listesinde olmalı: %s" % tree)
	var pine := forest.find_children("Pine*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var mat := pine.material_override as ShaderMaterial
	forest.set_camera_occlusion(Vector3(1.0, 8.0, 2.0), Vector3(0.0, 0.7, -3.0))
	assert_eq(mat.get_shader_parameter("occlusion_from"), Vector3(1.0, 8.0, 2.0))
	assert_eq(mat.get_shader_parameter("occlusion_to"), Vector3(0.0, 0.7, -3.0))
	assert_true(float(mat.get_shader_parameter("occlusion_radius")) > 0.5, "Örtme tüpü açık olmalı")


func test_world_valley_trunks_near_the_play_area_are_obstacles() -> void:
	# Orman şeridi çayırın kenarından (kuzeybatıda ~25 m) başlar ve oyun alanının (38 m) içine sokulur: oyun alanına
	# ulaşabilen vadi ağaçlarının gövdeleri de engeldir (oyuncu ağaçların içinden geçmez), kamp açıklığında yoktur.
	var world := await _get_world()
	var forest := world.get_node_or_null(^"Forest") as Forest
	if forest == null:
		fail("Forest yok")
		return
	var planted := {}
	for tree in forest.get_planted_trees():
		planted[Vector2(tree.x, tree.y)] = true
	var valley := 0
	for c in forest.get_obstacle_circles():
		var p := Vector2(c.x, c.y)
		if planted.has(p):
			continue
		valley += 1
		assert_true(p.length() >= forest.camp_clearing and p.length() < Forest.VALLEY_OBSTACLE_RANGE, "Vadi ağacı engeli yanlış yerde: %s" % c)
		assert_between(c.z, 0.25, 0.8, "Vadi ağacı gövde yarıçapı: %s" % c)
	assert_true(valley > 0, "Kampa yakın vadi ağaçlarının gövdeleri engel listesinde olmalı")
	var player := PlayerController.new()
	var play_radius := player.play_area_radius
	player.free()
	assert_true(Forest.VALLEY_OBSTACLE_RANGE > play_radius + 2.0, "Engel yarıçapı oyun alanını (%.0f m) kapsamalı" % play_radius)


func test_world_valley_forest_is_instanced_and_casts_no_shadows() -> void:
	var world := await _get_world()
	var forest := world.get_node_or_null(^"Forest") as Forest
	if forest == null:
		fail("Forest yok")
		return
	var instances := 0
	for node in forest.find_children("Trees_*", "MultiMeshInstance3D", true, false):
		var mmi := node as MultiMeshInstance3D
		instances += mmi.multimesh.instance_count
		assert_eq(mmi.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Vadi ağaçları gölge düşürmemeli: %s" % mmi.name)
		# Vadi ormanı ucuz ve koyu çizilir: fırça/mürekkep kapalı, dal uçları Meshy çamlarından az aydınlık.
		var mat := mmi.material_override as ShaderMaterial
		assert_true(mat != null and not bool(mat.get_shader_parameter("detail")), "Vadi malzemesinde ayrıntı kapalı olmalı: %s" % mmi.name)
		if mat:
			assert_almost(float(mat.get_shader_parameter("tip_light")), Forest.VALLEY_TIP_LIGHT, 0.0001, "Vadi dal ucu ışığı")
	assert_true(instances > 5000, "Vadi ormanı binlerce ağaç olmalı (%d)" % instances)


## Son dünya testi: paylaşılan dünyayı serbest bırakır.
func test_world_is_freed_cleanly() -> void:
	if _world == null:
		return
	var world := _world
	_world = null
	world.queue_free()
	await get_tree().create_timer(0.2).timeout
	await wait_frames(2)
	assert_false(is_instance_valid(world), "Dünya silinmeli")


func test_forest_falls_back_to_procedural_spruces_without_models() -> void:
	# Modeller yokmuş gibi: her çam prosedürel ladinle, konsola hata yazmadan kurulur.
	MeshyProp.models_enabled = false
	var collector := _ErrorLog.new()
	OS.add_logger(collector)
	var forest := Forest.new()
	forest.groves = []
	forest.area = Rect2(-200.0, -200.0, 400.0, 160.0)
	add_child(forest)
	await wait_frames(2)
	var model_while_disabled := TreeKit.load_model(TreeKit.PINE_YOUNG)
	OS.remove_logger(collector)
	MeshyProp.models_enabled = true
	assert_true(model_while_disabled.is_empty(), "Modeller kapalıyken TreeKit model vermemeli")
	var pines := forest.find_children("Pine*", "MeshInstance3D", true, false)
	assert_eq(pines.size(), forest.camp_trees.size(), "Her kamp çamı kurulmalı")
	if not pines.is_empty():
		var box := (pines[0] as MeshInstance3D).mesh.get_aabb()
		assert_between(box.end.y, 9.0, 10.6, "Yedek çam prosedürel ladin olmalı (10 birim)")
	assert_eq(collector.take(), PackedStringArray(), "Model yokken hata yazılmamalı")
	forest.queue_free()
	await wait_frames(1)


# --- Yardımcılar ---------------------------------------------------------------------

func _get_world() -> World:
	if _world == null:
		var packed := load(WORLD_SCENE) as PackedScene
		_world = packed.instantiate() as World
		add_child(_world)
		# Forest, RockField ve Meadow kurulumu bir sonraki kareye ertelenir.
		await wait_frames(3)
	return _world


class _FlatShape extends TerrainShape:
	func height_at(_x: float, _z: float) -> float:
		return 0.0


## x boyunca 1 m'de 1 m alçalan yamaç.
class _SlopeShape extends TerrainShape:
	func height_at(x: float, _z: float) -> float:
		return -x


class _ErrorLog extends Logger:
	var _mutex := Mutex.new()
	var _messages := PackedStringArray()

	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		_mutex.lock()
		_messages.append(rationale if not rationale.is_empty() else code)
		_mutex.unlock()

	func take() -> PackedStringArray:
		_mutex.lock()
		var result := _messages
		_mutex.unlock()
		return result
