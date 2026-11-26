extends TestCase
## Meshy modelleri ve onları gösteren kamp nesneleri: MeshyProp'un saf yardımcıları (model yolu, ölçek,
## sığdırma, yerleştirme), model dosyası yokken sessizce yedek görünüme dönmesi, gerçek bir modeli gerçek
## boyunda zemine oturtması ve AtW dokulu malzemeyle göstermesi; yurt, ahır, at, ateş ve eşyaların modelle
## de modelsiz de (yedek görünüm) kurulması, engel dairelerinin nesneyi örtmesi.

## Kamp nesnelerinin modellerinin zemine oturduğu kabul edilen tolerans (metre).
const GROUND_EPS := 0.05


func after_each() -> void:
	# Her test kendi açtığı anahtarı geri koysun (diğer testler gerçek modelleri görsün).
	MeshyProp.models_enabled = true


# --- Saf yardımcılar -----------------------------------------------------------------

func test_model_path() -> void:
	assert_eq(MeshyProp.model_path("props", "barrel"), "res://assets/props/barrel/barrel.glb")
	assert_eq(MeshyProp.model_path("structures", "yurt"), "res://assets/structures/yurt/yurt.glb")
	assert_eq(MeshyProp.model_path("animals", "horse_white"), "res://assets/animals/horse_white/horse_white.glb")


func test_fit_scale_uses_the_chosen_axis() -> void:
	var box := AABB(Vector3(-1.0, -2.0, -0.5), Vector3(2.0, 4.0, 1.0))
	assert_almost(MeshyProp.fit_scale(box, 2.0, MeshyProp.SizeAxis.HEIGHT), 0.5, 1e-6, "Yükseklik 4 → 2")
	assert_almost(MeshyProp.fit_scale(box, 2.0, MeshyProp.SizeAxis.LONGEST), 0.5, 1e-6, "En büyük kenar 4 → 2")
	assert_almost(MeshyProp.fit_scale(box, 1.0, MeshyProp.SizeAxis.FOOTPRINT), 0.5, 1e-6, "Taban çapı max(2, 1) → 1")
	assert_almost(MeshyProp.fit_scale(box, 3.0, MeshyProp.SizeAxis.WIDTH), 1.5, 1e-6, "Genişlik 2 → 3")
	assert_almost(MeshyProp.fit_scale(box, 3.0, MeshyProp.SizeAxis.DEPTH), 3.0, 1e-6, "Derinlik 1 → 3")
	# Eski tamsayı değerleri (sahnelerde kayıtlı) aynı anlamı korur.
	assert_almost(MeshyProp.fit_scale(box, 2.0, 0), 0.5, 1e-6)
	assert_almost(MeshyProp.fit_scale(box, 2.0, 1), 0.5, 1e-6)
	assert_almost(MeshyProp.fit_scale(box, 1.0, 2), 0.5, 1e-6)


func test_fit_scale_of_an_empty_box_is_neutral() -> void:
	for axis in MeshyProp.SizeAxis.values():
		assert_eq(MeshyProp.fit_scale(AABB(), 2.0, axis), 1.0, "Boş kutu ölçeği bozmamalı (eksen %d)" % axis)


func test_fit_inside_keeps_the_proportions() -> void:
	var box := AABB(Vector3.ZERO, Vector3(2.0, 1.0, 4.0))
	assert_almost(MeshyProp.fit_inside(box, Vector3(1.0, 0.0, 1.0)), 0.25, 1e-6, "Derinlik sınırlar (4 → 1)")
	assert_almost(MeshyProp.fit_inside(box, Vector3(1.0, 0.0, 8.0)), 0.5, 1e-6, "Genişlik sınırlar (2 → 1)")
	assert_almost(MeshyProp.fit_inside(box, Vector3(0.0, 3.0, 0.0)), 3.0, 1e-6, "Yalnız yükseklik verilirse ona göre")
	assert_eq(MeshyProp.fit_inside(box, Vector3.ZERO), 1.0, "Sınır yoksa ölçek 1")


func test_placement_puts_the_base_center_on_the_origin() -> void:
	var box := AABB(Vector3(1.0, -0.5, -3.0), Vector3(2.0, 1.0, 2.0))
	var s := 2.0
	var offset := MeshyProp.placement_offset(box, s, 0.0)
	# Tabanın ortası (2, -0.5, -2) ölçeklenip kaydırılınca (0, 0, 0)'a gelmeli.
	assert_vec_almost(Vector3(2.0, -0.5, -2.0) * s + offset, Vector3.ZERO, 1e-6)
	var sunk := MeshyProp.placement_offset(box, s, 0.03)
	assert_almost(sunk.y - offset.y, -0.03, 1e-6, "sink modeli o kadar gömer")


# --- Model yokken -------------------------------------------------------------------

func test_missing_model_shows_nothing_quietly() -> void:
	var prop := MeshyProp.new()
	prop.model_id = "boyle_bir_model_yok"
	prop.register_obstacle = true
	var collector := _ErrorLog.new()
	OS.add_logger(collector)
	add_child(prop)
	await wait_frames(1)
	OS.remove_logger(collector)
	assert_false(MeshyProp.exists("props", "boyle_bir_model_yok"))
	assert_false(prop.has_model(), "Eksik model has_model() = false vermeli")
	assert_eq(prop.get_child_count(), 0, "Eksik modelde hiçbir şey kurulmamalı")
	assert_eq(prop.get_footprint_radius(), 0.0)
	assert_eq(prop.get_model_aabb(), AABB())
	assert_true(prop.get_obstacle_circles().is_empty(), "Modeli olmayan nesne engel olmamalı")
	assert_true(prop.get_materials().is_empty())
	assert_eq(collector.take(), PackedStringArray(), "Eksik model konsola hata yazmamalı (yedek görünüm olağandır)")
	prop.queue_free()


func test_empty_model_id_is_not_a_model() -> void:
	assert_false(MeshyProp.exists("props", ""))


func test_models_can_be_switched_off() -> void:
	if not _require_model("props", "barrel"):
		return
	MeshyProp.models_enabled = false
	assert_false(MeshyProp.exists("props", "barrel"), "Anahtar kapalıyken modeller yok sayılmalı")
	var prop := _make_prop("barrel", 0.95)
	add_child(prop)
	await wait_frames(1)
	assert_false(prop.has_model())
	prop.queue_free()


# --- Gerçek model ---------------------------------------------------------------------

func test_real_model_is_scaled_and_stands_on_the_ground() -> void:
	if not _require_model("props", "barrel"):
		return
	var prop := _make_prop("barrel", 0.95)
	prop.position = Vector3(3.0, 0.0, -2.0)
	add_child(prop)
	await wait_frames(1)
	assert_true(prop.has_model(), "Fıçı modeli yüklenmeli")
	var box := prop.get_model_aabb()
	assert_almost(maxf(box.size.x, maxf(box.size.y, box.size.z)), 0.95, 0.001, "En büyük kenar target_size olmalı")
	assert_almost(box.position.y, 0.0, 0.001, "Taban düğümün yerinde (y = 0) olmalı")
	assert_almost(box.get_center().x, 0.0, 0.001, "Yatayda ortalanmalı (x)")
	assert_almost(box.get_center().z, 0.0, 0.001, "Yatayda ortalanmalı (z)")
	assert_true(prop.get_footprint_radius() > 0.2 and prop.get_footprint_radius() < 0.5, "Taban yarıçapı fıçıya uygun olmalı (%.2f)" % prop.get_footprint_radius())
	var circles := prop.get_obstacle_circles()
	assert_eq(circles.size(), 1)
	if circles.size() == 1:
		assert_almost(circles[0].x, 3.0, 0.001)
		assert_almost(circles[0].y, -2.0, 0.001)
	prop.queue_free()


func test_sink_lowers_the_model() -> void:
	if not _require_model("props", "barrel"):
		return
	var prop := _make_prop("barrel", 0.95)
	prop.sink = 0.03
	add_child(prop)
	await wait_frames(1)
	assert_almost(prop.get_model_aabb().position.y, -0.03, 0.001, "Model sink kadar gömülmeli")
	prop.queue_free()


func test_real_model_uses_the_textured_atw_material() -> void:
	if not _require_model("props", "barrel"):
		return
	var prop := _make_prop("barrel", 0.95)
	prop.tint = Color(0.9, 0.8, 0.7)
	add_child(prop)
	await wait_frames(1)
	var materials := prop.get_materials()
	assert_false(materials.is_empty(), "Modelin yüzeylerine malzeme verilmeli")
	for mat in materials:
		assert_eq(mat.shader, MeshyProp.SHADER, "Tek yüzlü model atw_textured kullanmalı")
		assert_true(mat.get_shader_parameter("albedo_texture") is Texture2D, "Modelin kendi dokusu korunmalı")
		assert_eq(mat.get_shader_parameter("albedo_tint"), Color(0.9, 0.8, 0.7))
		assert_almost(float(mat.get_shader_parameter("model_scale")), prop.get_model_scale(), 1e-5, "Taban gölgesi için ölçek verilmeli")
	prop.queue_free()


func test_double_sided_and_shader_parameters() -> void:
	if not _require_model("props", "bucket"):
		return
	var prop := _make_prop("bucket", 0.45)
	prop.double_sided = true
	prop.set_shader_parameter(&"ember_glow", 1.5)
	add_child(prop)
	await wait_frames(1)
	for mat in prop.get_materials():
		assert_eq(mat.shader, MeshyProp.DOUBLE_SHADER, "İçi görünen model iki yüzlü çizilmeli")
		assert_eq(mat.get_shader_parameter("ember_glow"), 1.5, "Ek parametre malzemeye geçmeli")
	# Yeniden kurulumdan sonra da ek parametre korunur.
	prop.target_size = 0.5
	await wait_frames(2)
	assert_true(prop.has_model())
	for mat in prop.get_materials():
		assert_eq(mat.get_shader_parameter("ember_glow"), 1.5, "Yeniden kurulumda ek parametre kaybolmamalı")
	prop.queue_free()


func test_render_layers_reach_every_mesh_and_survive_rebuilds() -> void:
	if not _require_model("props", "barrel"):
		return
	var prop := _make_prop("barrel", 0.95)
	prop.render_layers = 1 << 10
	add_child(prop)
	await wait_frames(1)
	var meshes := prop.find_children("*", "MeshInstance3D", true, false)
	assert_false(meshes.is_empty())
	for mi in meshes:
		assert_eq((mi as MeshInstance3D).layers, 1 << 10, "Model meshleri verilen çizim katmanında olmalı")
	# Kurulmuş modelde değiştirilince de, yeniden kurulumdan sonra da uygulanır.
	prop.render_layers = 1 | (1 << 3)
	prop.target_size = 1.2
	await wait_frames(2)
	for mi in prop.find_children("*", "MeshInstance3D", true, false):
		assert_eq((mi as MeshInstance3D).layers, 1 | (1 << 3), "Yeniden kurulumda çizim katmanı korunmalı")
	prop.queue_free()


func test_rebuild_replaces_the_model() -> void:
	if not _require_model("props", "barrel"):
		return
	var prop := _make_prop("barrel", 0.95)
	add_child(prop)
	await wait_frames(1)
	prop.target_size = 1.9
	await wait_frames(2)
	assert_eq(prop.get_child_count(), 1, "Yeniden kurulum eski modeli silmeli")
	assert_almost(prop.get_model_aabb().size.y, 1.9, 0.01, "Yeni boy uygulanmalı")
	prop.queue_free()


# --- Kamp nesneleri: modelle ve modelsiz ----------------------------------------------

func test_vertical_stretch_raises_only_the_height() -> void:
	if not _require_model(Yurt.MODEL_FOLDER, Yurt.MODEL_ID):
		return
	var prop := MeshyProp.new()
	prop.folder = Yurt.MODEL_FOLDER
	prop.model_id = Yurt.MODEL_ID
	prop.size_axis = MeshyProp.SizeAxis.WIDTH
	prop.target_size = 6.0
	prop.sink = 0.03
	add_child(prop)
	var before := prop.get_model_aabb()
	prop.vertical_stretch = 1.25
	var after := prop.get_model_aabb()
	assert_almost(after.size.y, before.size.y * 1.25, 0.001, "Boy uzatma oranında büyümeli")
	assert_almost(after.size.x, before.size.x, 0.001, "Genişlik değişmemeli")
	assert_almost(after.size.z, before.size.z, 0.001, "Derinlik değişmemeli")
	assert_almost(after.position.y, -0.03, 0.001, "Taban zeminde (gömülü) kalmalı")
	assert_vec_almost(MeshyProp.stretched_scale(2.0, 1.5), Vector3(2.0, 3.0, 2.0), 0.0001)
	prop.queue_free()


func test_yurt_door_stretch_helper() -> void:
	# Kapı modelin boyunun yarısındadır: 3,6 m'lik modelde kapı 1,8 m; 2,05 m'ye yetmesi için ~%15 uzatılır.
	var stretch := Yurt.door_stretch(3.6, 2.05)
	assert_almost(3.6 * stretch * Yurt.MODEL_DOOR_TOP - Yurt.MODEL_SINK, 2.05, 0.001, "Uzatılmış kapı istenen yükseklikte olmalı")
	assert_almost(Yurt.door_stretch(5.0, 2.05), 1.0, 0.0001, "Kapı zaten yüksekse uzatılmaz")
	assert_almost(Yurt.door_stretch(0.0, 2.05), 1.0, 0.0001, "Boyu olmayan modelde uzatma yok")


func test_yurt_shows_the_model_and_keeps_its_api() -> void:
	if not _require_model(Yurt.MODEL_FOLDER, Yurt.MODEL_ID):
		return
	var yurt := Yurt.new()
	yurt.radius = 2.7
	yurt.hanging_angle = -42.0
	yurt.emblem_angle = 40.0
	add_child(yurt)
	await wait_frames(1)
	assert_true(yurt.uses_model(), "Yurt Meshy modelini göstermeli")
	var model := yurt.get_node_or_null(^"YurtModel") as MeshyProp
	assert_not_null(model)
	if model:
		var box := model.get_model_aabb()
		assert_almost(box.size.x, 5.4, 0.01, "Kapıya dik genişlik 2 × radius olmalı")
		# Kapı 1,82 m'lik Mete'nin eğilmeden geçebileceği kadar yüksek olmalı: model dikeyde uzatılır.
		assert_true(yurt._door_top() >= yurt.min_door_height - 0.01, "Kapı en az min_door_height yüksekliğinde olmalı (%.2f m)" % yurt._door_top())
		assert_true(yurt.min_door_height >= 1.82 + 0.15, "Kapı Mete'nin boyundan (1,82 m) yüksek olmalı")
		assert_between(box.size.y, 3.6, 4.8, "Yurt boyu yüksek kapıya göre olmalı")
		assert_almost(box.position.y, -Yurt.MODEL_SINK, 0.002, "Taban zemine oturmalı (biraz gömülü)")
	for light_name in ["InteriorLight", "DoorSpill"]:
		assert_not_null(yurt.get_node_or_null(NodePath(light_name)), "%s kurulmalı" % light_name)
	assert_not_null(yurt.get_node_or_null(^"DoorGlow"), "Kapıdan içerinin ışığı görünmeli")
	assert_not_null(yurt.get_node_or_null(^"HearthFlame0"), "Kapıdan içerideki ocağın alevi görünmeli")
	assert_not_null(yurt.get_node_or_null(^"Step0"), "Kapının önünde taş basamak olmalı")
	assert_not_null(yurt.get_node_or_null(^"Smoke"), "Tacından duman çıkmalı")
	assert_not_null(yurt.get_node_or_null(^"Emblem") as Decal, "emblem_angle verilince keçeye damga boyanmalı")
	assert_true(_has_banner_cloth(yurt), "hanging_angle verilince duvara kumaş asılmalı")
	var interior := yurt.get_node_or_null(^"InteriorLight") as OmniLight3D
	if interior and model:
		assert_true(interior.position.y + interior.omni_range < model.get_model_aabb().end.y - 0.3, "İç ışık tacın iç yüzüne ulaşmamalı")
	var spill := yurt.get_node_or_null(^"DoorSpill") as SpotLight3D
	if spill:
		assert_true(-spill.transform.basis.z.z > 0.5, "Kapı ışığı +Z'ye (kapının baktığı yöne) sızmalı")
	if spill and model:
		# Kapı ışığı yurdun kendisini (dışa açılmış kapı kanadı, çerçeve) yakından parlatmamalı; zemini ve
		# basamakları (1. katman) aydınlatmalı.
		assert_eq(model.render_layers, Yurt.MODEL_RENDER_LAYER, "Yurt modeli kendi çizim katmanında olmalı")
		assert_eq(spill.light_cull_mask & Yurt.MODEL_RENDER_LAYER, 0, "Kapı ışığı yurt modelini aydınlatmamalı")
		assert_true(spill.light_cull_mask & 1 != 0, "Kapı ışığı zemini ve basamakları aydınlatmalı")
		var interior_light := yurt.get_node_or_null(^"InteriorLight") as OmniLight3D
		if interior_light:
			assert_true(interior_light.light_cull_mask & Yurt.MODEL_RENDER_LAYER != 0, "İç ışık yurdun içini aydınlatmalı")
	var circles := yurt.get_obstacle_circles()
	assert_eq(circles.size(), 1)
	if circles.size() == 1:
		assert_almost(circles[0].z, 2.95, 0.001, "Engel dairesi radius + 0,25 olmalı")
	await _free_and_settle(yurt)


func test_yurt_falls_back_to_the_procedural_yurt() -> void:
	MeshyProp.models_enabled = false
	var yurt := Yurt.new()
	yurt.hanging_angle = -42.0
	add_child(yurt)
	await wait_frames(1)
	assert_false(yurt.uses_model())
	assert_null(yurt.get_node_or_null(^"YurtModel"), "Model yokken model düğümü kalmamalı")
	assert_true(yurt.get_child_count() > 10, "Yedek yurt duvar, çatı, kapı ve tacıyla kurulmalı (%d parça)" % yurt.get_child_count())
	assert_not_null(yurt.get_node_or_null(^"InteriorLight"))
	assert_null(yurt.get_node_or_null(^"Emblem"), "emblem_angle verilmeyince damga olmamalı")
	assert_true(_has_banner_cloth(yurt), "Yedek yurtta da kumaş asılmalı")
	assert_null(yurt.get_node_or_null(^"HearthFlame0"), "Yedek yurdun kendi ocağı var")
	await _free_and_settle(yurt)


func test_stable_model_fits_its_footprint_and_keeps_the_lantern() -> void:
	if not _require_model(Stable.MODEL_FOLDER, Stable.MODEL_ID):
		return
	var stable := Stable.new()
	add_child(stable)
	await wait_frames(1)
	assert_true(stable.uses_model(), "Ahır Meshy modelini göstermeli")
	var size := stable.get_footprint()
	assert_true(size.x <= stable.width + 0.001 and size.y <= stable.depth + 0.001, "Model width × depth tabanına sığmalı (%s)" % size)
	assert_true(size.x >= stable.width - 0.1 or size.y >= stable.depth - 0.1, "Model tabanı doldurmalı (%s)" % size)
	var lantern := stable.get_node_or_null(^"LanternLight") as OmniLight3D
	assert_not_null(lantern, "Fener ışığı korunmalı")
	if lantern:
		assert_true(lantern.position.z > 0.0, "Fener ahırın önünde (+Z) olmalı")
		assert_between(lantern.position.y, 1.5, 3.5, "Fener kirişte asılı olmalı (%.2f m)" % lantern.position.y)
		# Işık modelin fenerinin içindedir (camın birkaç cm önünde olursa cam aşırı parlar).
		var halo := stable.get_node_or_null(^"LanternHalo") as Node3D
		assert_not_null(halo, "Fenerin ışık halesi kurulmalı")
		if halo:
			assert_vec_almost(lantern.position, halo.position, 0.001, "Fener ışığı fenerin içinde olmalı")
	_assert_circles_cover(stable.get_obstacle_circles(), stable, size, "Ahır", true)
	await _free_and_settle(stable)


func test_stable_falls_back_to_the_procedural_stable() -> void:
	MeshyProp.models_enabled = false
	var stable := Stable.new()
	add_child(stable)
	await wait_frames(1)
	assert_false(stable.uses_model())
	assert_true(stable.get_child_count() > 10, "Yedek ahır direk, çatı ve korkuluklarıyla kurulmalı")
	assert_not_null(stable.get_node_or_null(^"LanternLight"))
	assert_eq(stable.get_footprint(), Vector2(stable.width, stable.depth))
	await _free_and_settle(stable)


func test_footprint_circles_cover_the_rectangle() -> void:
	for size in [Vector2(6.0, 4.6), Vector2(5.6, 3.0), Vector2(2.0, 2.0), Vector2(1.0, 7.0)]:
		var circles := Stable.footprint_circles(size)
		assert_false(circles.is_empty())
		for corner in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1), Vector2(0, 0)]:
			var p: Vector2 = corner * size * 0.5
			var covered := false
			for c in circles:
				if Vector2(c.x, c.y).distance_to(p) <= c.z + 0.001:
					covered = true
			assert_true(covered, "%s tabanının %s noktası örtülmeli" % [size, p])
	assert_true(Stable.footprint_circles(Vector2.ZERO).is_empty())


func test_horse_picks_its_model_from_the_coat() -> void:
	assert_eq(Horse.default_model_for(Color(0.46, 0.27, 0.15)), "horse_brown", "Doru at")
	assert_eq(Horse.default_model_for(Color(0.93, 0.91, 0.87)), "horse_white", "Kır at")
	var horse := Horse.new()
	assert_eq(horse.resolved_model_id(), "horse_brown", "Varsayılan tüy kahverengidir")
	horse.coat_color = Color(0.93, 0.91, 0.87)
	assert_eq(horse.resolved_model_id(), "horse_white")
	horse.model_id = "horse_brown"
	assert_eq(horse.resolved_model_id(), "horse_brown", "model_id verilirse o kullanılır")
	horse.free()


func test_horse_model_is_life_sized_and_alive() -> void:
	if not _require_model(Horse.MODEL_FOLDER, Horse.BROWN_MODEL):
		return
	var horse := Horse.new()
	add_child(horse)
	await wait_frames(1)
	assert_true(horse.uses_model(), "At Meshy modelini göstermeli")
	var ride := horse.rideable()
	if Horse.has_rigged_model(Horse.BROWN_MODEL):
		# İskeletli model (2026-11-07): binilebilir at; canlılığı klipleri verir (bekleme, otlama, nefes, kuyruk).
		assert_not_null(ride, "Oyunda binilebilir at kurulmalı")
		assert_null(horse.get_node_or_null(^"HorseModel"), "Donuk model kurulmamalı")
		var model := ride.get_node(^"Body/HorseModel") as Node3D
		var box := CharacterAvatar.rest_bounds(model)
		assert_almost(box.size.z, Horse.MODEL_LENGTH, 0.02, "Burundan kuyruğa uzunluk (baş +Z yönünde)")
		assert_between(box.size.y, 1.5, 2.1, "At boyu (kulak ucu) 1,8 m'lik karakterlere uygun olmalı")
		assert_eq(ride.model_clip(), &"idle", "Bekleme klibi oynamalı")
		assert_not_null(model.find_children("*", "Skeleton3D", true, false)[0], "İskelet")
	else:
		var model := horse.get_node_or_null(^"HorseModel") as MeshyProp
		assert_not_null(model)
		if model:
			var box := model.get_model_aabb()
			assert_almost(box.size.z, Horse.MODEL_LENGTH, 0.01, "Burundan kuyruğa uzunluk (baş +Z yönünde)")
			assert_between(box.size.y, 1.5, 2.1, "At boyu (kulak ucu) 1,8 m'lik karakterlere uygun olmalı")
			for mat in model.get_materials():
				assert_true(float(mat.get_shader_parameter("nod_angle")) > 0.0, "Model baş sallamalı")
				assert_true(float(mat.get_shader_parameter("swish_amount")) > 0.0, "Model kuyruk sallamalı")
	await _free_and_settle(horse)


func test_horse_falls_back_to_the_procedural_horse() -> void:
	MeshyProp.models_enabled = false
	var horse := Horse.new()
	add_child(horse)
	await wait_frames(1)
	assert_false(horse.uses_model())
	assert_not_null(horse.get_node_or_null(^"Neck"), "Yedek atın boyun eklemi olmalı")
	assert_not_null(horse.get_node_or_null(^"Tail"), "Yedek atın kuyruk eklemi olmalı")
	await _free_and_settle(horse)


func test_campfire_ring_model_glows() -> void:
	if not _require_model(Campfire.MODEL_FOLDER, Campfire.MODEL_ID):
		return
	var fire := Campfire.new()
	add_child(fire)
	await wait_frames(1)
	assert_true(fire.uses_model(), "Ateş taş halkası Meshy modeli olmalı")
	var ring := fire.get_node_or_null(^"FireRing") as MeshyProp
	if ring:
		assert_almost(maxf(ring.get_model_aabb().size.x, ring.get_model_aabb().size.z), Campfire.RING_DIAMETER, 0.01)
		for mat in ring.get_materials():
			assert_true(float(mat.get_shader_parameter("ember_glow")) > 0.0, "Dokudaki korlar parlamalı")
	assert_not_null(fire.get_node_or_null(^"FireLight"), "Ateş ışığı korunmalı")
	await _free_and_settle(fire)


func test_campfire_falls_back_to_procedural_stones() -> void:
	MeshyProp.models_enabled = false
	var fire := Campfire.new()
	add_child(fire)
	await wait_frames(1)
	assert_false(fire.uses_model())
	assert_null(fire.get_node_or_null(^"FireRing"))
	assert_true(fire.get_child_count() > 20, "Yedek ateş taşları ve odunlarıyla kurulmalı (%d parça)" % fire.get_child_count())
	assert_almost(fire.get_obstacle_circles()[0].z, Campfire.MIN_OBSTACLE_RADIUS, 0.0001)
	await _free_and_settle(fire)


func test_camp_prop_kinds_keep_their_values() -> void:
	# Sahnelerde tür, sayı olarak kayıtlıdır: eski değerler değişmemeli, yeni tür (çit) sona eklenmeli.
	var expected := ["BARREL", "CRATE", "BUCKET", "SHIELD", "DRYING_RACK", "TRIPOD_POT", "STOOL", "WOOD_PILE", "SPEAR_RACK", "CUP", "SADDLE_BAGS", "FENCE"]
	assert_eq(CampProp.Kind.keys().map(func(k: Variant) -> String: return str(k)), expected)
	assert_eq(CampProp.Kind.FENCE, 11)
	assert_eq(CampProp.model_id_for(CampProp.Kind.WOOD_PILE), "firewood")
	assert_eq(CampProp.model_id_for(CampProp.Kind.TRIPOD_POT), "cauldron")
	assert_eq(CampProp.model_id_for(CampProp.Kind.SPEAR_RACK), "weapon_rack")
	assert_eq(CampProp.model_id_for(CampProp.Kind.FENCE), "fence")
	for kind in [CampProp.Kind.DRYING_RACK, CampProp.Kind.CUP, CampProp.Kind.SHIELD]:
		assert_eq(CampProp.model_id_for(kind), "", "%s kodla çizilir" % CampProp.Kind.keys()[kind])


func test_every_camp_prop_builds_with_and_without_models() -> void:
	for enabled in [true, false]:
		MeshyProp.models_enabled = enabled
		for kind in CampProp.Kind.values():
			var prop := CampProp.new()
			prop.kind = kind
			add_child(prop)
			await wait_frames(1)
			var label := "%s (modeller %s)" % [CampProp.Kind.keys()[kind], "açık" if enabled else "kapalı"]
			assert_true(prop.get_child_count() > 0, "%s kurulmalı" % label)
			var id := CampProp.model_id_for(kind)
			var expect_model: bool = enabled and MeshyProp.exists(CampProp.MODEL_FOLDER, id)
			assert_eq(prop.uses_model(), expect_model, "%s modeli kullanmalı mı" % label)
			if prop.uses_model():
				var model := prop.get_node_or_null(^"PropModel") as MeshyProp
				var box := model.get_model_aabb()
				assert_almost(maxf(box.size.x, maxf(box.size.y, box.size.z)), CampProp.model_size_for(kind), 0.01, "%s gerçek boyunda olmalı" % label)
				assert_between(box.position.y, -0.03, 0.0, "%s zemine oturmalı" % label)
				var center := Vector2(box.get_center().x, box.get_center().z)
				_assert_circles_cover(prop.get_obstacle_circles(), prop, Vector2(box.size.x, box.size.z) * 0.85, label, false, center)
			for c in prop.get_obstacle_circles():
				assert_true(c.z > 0.0 and c.z < 1.6, "%s engel yarıçapı makul olmalı (%.2f)" % [label, c.z])
			prop.queue_free()
			await wait_frames(1)


func test_footprint_circles_of_long_props() -> void:
	var fence := CampProp.footprint_circles(Vector2(2.2, 0.2), Vector2.ZERO)
	assert_true(fence.size() >= 3, "Çit uzun kenarı boyunca birden çok daireyle örtülmeli")
	for c in fence:
		assert_true(c.z <= 0.3, "Çit daireleri ince olmalı (oyuncu çitin yanından geçebilmeli)")
	assert_true(absf(fence[0].x) + fence[0].z >= 1.09, "Çitin uçları örtülmeli")
	var barrel := CampProp.footprint_circles(Vector2(0.8, 0.8), Vector2(0.1, -0.2))
	assert_eq(barrel.size(), 1, "Toplu eşya tek daire")
	assert_vec_almost(Vector3(barrel[0].x, barrel[0].y, 0.0), Vector3(0.1, -0.2, 0.0), 1e-6, "Daire tabanın ortasında")


func test_tamga_texture() -> void:
	assert_true(Style.tamga_distance(Vector2.ZERO) < 0.0, "Damganın ortası (dikey çubuk) dolu")
	assert_true(Style.tamga_distance(Vector2(0.15, 0.0)) < 0.0, "Halka dolu")
	assert_true(Style.tamga_distance(Vector2(0.07, -0.06)) > 0.0, "Halkanın içi (çubuğun yanı) boş")
	assert_true(Style.tamga_distance(Vector2(0.38, 0.38)) > 0.0, "Köşe boş")
	var img := Style.tamga_image(32)
	assert_eq(img.get_size(), Vector2i(32, 32))
	assert_almost(img.get_pixel(0, 0).a, 0.0, 0.01, "Kenarlar saydam (damga taşmamalı)")
	assert_true(img.get_pixel(16, 16).a > 0.5, "Ortası boyalı")
	assert_eq(Yurt.felt_tint(Style.FELT), Color(1, 1, 1), "Varsayılan keçe modelin rengini değiştirmez")


# --- Yardımcılar ---------------------------------------------------------------------

func _make_prop(id: String, size: float) -> MeshyProp:
	var prop := MeshyProp.new()
	prop.model_id = id
	prop.folder = "props"
	prop.size_axis = MeshyProp.SizeAxis.LONGEST
	prop.target_size = size
	prop.register_obstacle = true
	return prop


## Model dosyası oyuna hazırlanmış mı? Değilse test atlanmaz, başarısız sayılır (modeller depodadır).
func _require_model(folder: String, id: String) -> bool:
	var ok := MeshyProp.exists(folder, id)
	if not ok:
		fail("Model bulunamadı: %s" % MeshyProp.model_path(folder, id))
	return ok


## Nesnenin yerel tabanının (size ölçüsünde, ortası center) ortası ve kenar ortaları (corners: köşeleri de)
## engel daireleriyle örtülmeli. Toplu eşyalarda köşeler bilerek dışarıda kalır: oyuncu yanına kadar gelebilir.
func _assert_circles_cover(circles: Array[Vector3], node: Node3D, size: Vector2, label: String, corners: bool,
		center: Vector2 = Vector2.ZERO) -> void:
	assert_false(circles.is_empty(), "%s engel olmalı" % label)
	var points: Array[Vector2] = [Vector2.ZERO, Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]
	if corners:
		points.append_array([Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)])
	for corner in points:
		var local: Vector2 = center + corner * size * 0.5
		var p := node.global_transform * Vector3(local.x, 0.0, local.y)
		var covered := false
		for c in circles:
			if Vector2(c.x - p.x, c.y - p.z).length() <= c.z + 0.05:
				covered = true
		assert_true(covered, "%s tabanının %s noktası engel dairesiyle örtülmeli" % [label, local])


## Yurdun duvarına asılı (bayrak shader'lı) bir kumaş var mı?
static func _has_banner_cloth(yurt: Yurt) -> bool:
	for child in yurt.get_children():
		var mi := child as MeshInstance3D
		if mi and mi.material_override is ShaderMaterial and (mi.material_override as ShaderMaterial).shader == Yurt.BANNER_SHADER:
			return true
	return false


## Düğümü siler ve ses sunucusunun durdurulan sesleri bırakmasını bekler.
func _free_and_settle(node: Node) -> void:
	node.queue_free()
	await get_tree().create_timer(0.2).timeout
	await wait_frames(2)


## Hata iletilerini toplayan günlükçü (uyarılar hariç).
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
