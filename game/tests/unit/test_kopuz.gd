extends TestCase
## Ozanın kopuzu (Kopuz, scripts/camp/kopuz.gd) ve çalışı (KopuzPlay, scripts/camp/kopuz_play.gd; K60, Yol Haritası
## kopuz-model):
##   - Meshy modeli yokken kopuz kodla çizilir: üç tel, ayrı deri yüzeyi (göğsün alt üçte ikisi), boy 0,9–1,0 m;
##     sahte bir model varken kod çizmez, model gerçek boyuna ölçeklenir.
##   - Gerçek model (assets/props/kopuz/kopuz.glb): boy 0,95 m, üç tel (tools/kopuz_three_strings.py), sap +Y ve ortada, göğüs +Z'ye
##     bakar ve z = 0'da; sol elin kavradığı yer sapın kesitinde, sağ elin vurduğu yer tellerin önünde (kodla çizimle aynı yerel uzay: GRIP,
##     STRUM, sahnedeki pozlar).
##   - KopuzPlay: kol kaydın vuruş ızgarasına uyar (K60, K95): STROKE_HZ × 2 seçili çekimin 1 / dönem'inin %2'si içinde (3104:
##     0,3989 sn, 1,2534 tur/sn), aşağı vuruş ızgarada (faz sabiti ölçünün çapası), kaldırma 1,1 sn, avuç susturunca salınım 0,
##     kucağa dönüş ilk dönüşümle aynı; ozanın Meshy modelinde RightForeArm bulunur.
##   - El duruşu ozanın gerçek ağından ölçülür (derili köşeler kopuzun uzayında): sol avuç sapa bakar ve sapa oturur, parmak uçları sapın önünden
##     sarar, sağ avuç deriye bakar ve parmak uçları tellere değer, ön kol kaseden geçmez, bilek sınır içinde kırılır. Ağırlık 0'da hiçbir kemiğe
##     dokunulmaz, kucak pozu (menü karesi) sabittir.

const TempDir := preload("res://tests/support/temp_dir.gd")
const NPC_SCENE := preload("res://scenes/world/camp_npcs.tscn")
const MISSING_MODEL := "res://assets/props/kopuz/yok_boyle_model.glb"
## Şarkı çekimlerinin ölçüsü (tools/song/song_measure.mjs yazar) ve şarkının satırı (seçili çekim `take`).
const SONG_MEASURE := "res://tools/song/k75_measure.json"
const SONG := "act0.bard.song"
## Kolun hızı ile kaydın ızgarası arasındaki en büyük fark (oran).
const GRID_TOLERANCE := 0.02
## Menü karesinin kucak pozu (scenes/world/camp_npcs.tscn): çalış pozu değişse de bu değişmez.
const LAP_POSE := Transform3D(Vector3(0.5867914, -0.7588429, 0.2825479), Vector3(0.7990019, 0.5992514, -0.04993762), Vector3(-0.1314224, 0.2550593, 0.9579525), Vector3(-0.164, 0.242, 0.39))
## Sol elin ölçüleri (metre, derece; kopuzun uzayında, sap ekseni x = 0, z = Kopuz.GRIP.z): sapın kesiti yaklaşık bu yarıçapta (ölçüldü: x ±0,018, tahtası z ±0,015).
const NECK_RADIUS := 0.016
## Avuç ortasının sap eksenine uzaklığı: sapın yarıçapı ile avucun kalınlığı arası.
const PALM_TO_NECK := Vector2(0.03, 0.06)
## Avucun sapa bakış sapması ve avucun kesitteki yeri (+X aşağı kenar 0°, +Z ön 90°).
const PALM_AIM_MAX := 15.0
const PALM_SIDE_MAX := 40.0
## Parmak ucunun sap eksenine en küçük uzaklığı ve kesitteki ortalama açısı (uç sapın önüne geçmiş olmalı), ağın sapın içine giren payı.
const FINGER_TIP_REACH := 0.032
const FINGER_TIP_ANGLE_MIN := 60.0
const FINGER_INSIDE_MAX := 0.2
const PALM_INSIDE_MAX := 0.1
## Bileğin kırılması (ön kol ile bilekten parmak köküne yön arası).
const LEFT_WRIST_BEND_MAX := 55.0
const RIGHT_WRIST_BEND_MAX := 45.0
## Sağ el: avucun deriye bakış sapması, parmak uçlarının tellere uzaklığı, telin yüksekliği (ölçü: test_real_model_has_three_strings'in z'si, model uzayından kopuz uzayına ≈0,02).
const STRUM_AIM_MAX := 25.0
const STRUM_TIP_REACH := 0.03
const STRING_Z := 0.02
## Kaseye girmeyen ön kol: kesitin arka yüzü (metre; modelin kasesi z ≈ −0,069).
const BOWL_BACK := -0.07
## Kalkış boyunca 0,1 ağırlık adımında elin en büyük yer ve yön değişimi.
const LIFT_STEP_MAX := 0.15
const LIFT_TURN_MAX := 40.0
const FINGERS: Array[String] = ["Index", "Middle", "Ring", "Pinky"]

var _trash: Array[Node] = []
var _dir := ""


func before_each() -> void:
	Engine.time_scale = 1.0


func after_each() -> void:
	Engine.time_scale = 1.0
	for node in _trash:
		if is_instance_valid(node):
			node.queue_free()
	_trash.clear()
	if not _dir.is_empty():
		TempDir.wipe(_dir)
		_dir = ""


# --- Kodla çizim --------------------------------------------------------------------------------

func test_without_model_the_kopuz_is_drawn_with_code() -> void:
	var kopuz := _kopuz(MISSING_MODEL)
	assert_true(kopuz.is_drawn(), "Model yokken kodla çizilmeli")
	assert_false(kopuz.has_model())
	assert_between(kopuz.get_length(), 0.9, 1.0, "Boy 0,9–1,0 m (K60)")
	var strings := kopuz.get_strings()
	assert_eq(strings.size(), 3, "Üç tel")
	for s in strings:
		assert_true(s.mesh != null and s.mesh.get_surface_count() > 0, "%s ağı olmalı" % s.name)
		assert_true(s.mesh.get_aabb().size.y > 0.6, "Tel kuyruktan sapın başına uzanmalı")
		assert_eq(s.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Teller gölge vermez")
	var skin := kopuz.get_skin()
	assert_not_null(skin, "Deri göğüs ayrı yüzey olmalı")
	if skin == null:
		return
	var wood := kopuz.get_node(^"Wood") as MeshInstance3D
	assert_ne(skin.material_override, wood.material_override, "Deri ahşaptan ayrı malzemede")
	var skin_color: Color = (skin.material_override as ShaderMaterial).get_shader_parameter("albedo")
	var wood_color: Color = (wood.material_override as ShaderMaterial).get_shader_parameter("albedo")
	assert_true(skin_color.get_luminance() > wood_color.get_luminance() + 0.2, "Deri ahşaptan açık: geniş planda okunur")
	# Deri göğsün alt üçte ikisidir (gövde tabandan sapın başına BODY_LENGTH).
	var skin_box := skin.mesh.get_aabb()
	assert_almost(skin_box.position.y, 0.0, 0.001, "Deri gövdenin dibinden başlar")
	assert_between(skin_box.end.y / Kopuz.BODY_LENGTH, 0.58, 0.72, "Deri göğsün alt üçte ikisi")
	assert_almost(skin_box.size.x, Kopuz.HALF_WIDTH * 2.0, 0.01, "Deri gövdenin en geniş yerini kaplar")
	# Taban düğümün yerinde, sap +Y'de, göğüs +Z'ye bakar (eski dombra eşyasıyla aynı yerel uzay).
	var box := kopuz.local_bounds()
	assert_almost(box.position.y, 0.0, 0.01)
	assert_true(skin.mesh.get_faces().size() > 0)
	assert_true(_faces_toward(skin.mesh, Vector3.BACK), "Deri göğüs +Z'ye bakmalı (önden görünür)")


func test_body_outline_is_a_pear() -> void:
	assert_almost(Kopuz.half_width(0.0), 0.0, 0.0001)
	assert_almost(Kopuz.half_width(Kopuz.WIDE_AT), Kopuz.HALF_WIDTH, 0.0001, "En geniş yer")
	assert_almost(Kopuz.half_width(Kopuz.BODY_LENGTH), Kopuz.NECK_HALF_WIDTH, 0.0001, "Sapın başı")
	var last := INF
	for i in 20:
		var y := lerpf(Kopuz.WIDE_AT, Kopuz.NECK_TOP, float(i) / 19.0)
		var w := Kopuz.half_width(y)
		assert_true(w <= last + 0.00001, "Gövde en geniş yerden sapa daralmalı (%.3f m)" % y)
		last = w
	var edge := Kopuz.skin_edge_y()
	assert_almost(Kopuz.skin_top(Kopuz.half_width(edge)), edge, 0.001, "Derinin yayı gövde kenarına değer")


func test_fake_model_replaces_the_drawing() -> void:
	_dir = TempDir.fresh("kopuz_model")
	var path := _dir.path_join("kopuz.tscn")
	assert_eq(ResourceSaver.save(_fake_model(), path), OK)
	var kopuz := _kopuz(path)
	assert_true(kopuz.has_model(), "Model varken o gösterilmeli")
	assert_false(kopuz.is_drawn(), "Model varken kod çizmez")
	assert_true(kopuz.get_strings().is_empty() and kopuz.get_skin() == null)
	assert_null(kopuz.get_node_or_null(^"Wood"))
	assert_almost(kopuz.get_length(), Kopuz.LENGTH, 0.001, "Model gerçek boyuna ölçeklenmeli")
	assert_almost(kopuz.local_bounds().position.y, 0.0, 0.001, "Tabanı düğümün yerine oturmalı")
	assert_eq(Kopuz.MODEL_PATH, "res://assets/props/kopuz/kopuz.glb", "Meshy modeli bu yola gelir (meshy-final)")


func test_real_model_is_shown_at_its_true_size_in_the_same_local_space() -> void:
	assert_true(ResourceLoader.exists(Kopuz.MODEL_PATH), "Meshy modeli oyunda: %s" % Kopuz.MODEL_PATH)
	var kopuz := _kopuz(Kopuz.MODEL_PATH)
	assert_true(kopuz.has_model(), "Model gösterilmeli")
	assert_false(kopuz.is_drawn(), "Model varken kod çizmez")
	assert_almost(kopuz.get_length(), Kopuz.LENGTH, 0.001, "Boy 0,95 m (K60: 0,9–1,0)")
	var box := kopuz.local_bounds()
	assert_almost(box.position.y, 0.0, 0.001, "Tabanı (kuyruk) düğümün yerinde, sap +Y")
	assert_almost(box.get_center().x, 0.0, 0.001, "Yatayda ortada")
	assert_almost(box.size.x, Kopuz.HALF_WIDTH * 2.0, 0.01, "Gövdesi kodla çizim kadar geniş")
	# Kesitler (yerel uzay): gövde altta geniş, sap üstte dar ve ortada; kafa ve burgular +Y ucunda.
	var body := _slice(kopuz, 0.15, 0.2)
	var neck := _slice(kopuz, 0.6, 0.68)
	assert_true(body.size.x > 0.25, "Gövde altta (%.3f m)" % body.size.x)
	assert_true(neck.size.x < 0.05, "Sap üstte ve dar (%.3f m)" % neck.size.x)
	assert_almost(neck.get_center().x, 0.0, 0.005, "Sap X'te ortada: GRIP ve STRUM sapın ve tellerin üstünde")
	# Göğüs +Z'ye bakar: kase arkada derin, önde yalnız eşik ve teller; deri ve sapın önü z = 0 çevresinde.
	assert_true(body.position.z < -0.05, "Kasesi arkada (%.3f)" % body.position.z)
	assert_between(body.end.z, 0.015, 0.035, "Önde eşik ve teller (%.3f)" % body.end.z)
	var neck_back := _slice_back(kopuz, 0.6, 0.68)
	assert_between(neck_back, -0.03, -0.01, "Sapın arkası z = −0,02 çevresinde: sapın önü z ≈ 0 (%.3f)" % neck_back)
	# Eller kodla çizimle aynı yerde: sol elin kavradığı yer sapın kesitinde, sağ elin vurduğu yer tellerin önünde.
	assert_almost(Kopuz.GRIP.x, 0.0, 0.0001)
	assert_between(Kopuz.GRIP.z, neck_back, 0.0, "Sol elin kavradığı yer sapın kesitinde (%.3f..0)" % neck_back)
	assert_between(Kopuz.GRIP.y, 0.45, 0.8, "Sol el sapta (gövdenin üstünde, kafanın altında)")
	assert_true(Kopuz.STRUM.z > _slice(kopuz, Kopuz.STRUM.y - 0.03, Kopuz.STRUM.y + 0.03).end.z, "Sağ el tellerin önünde")
	# Malzeme: modelin dokusu AtW dokulu malzemeyle.
	var mi := kopuz.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var mat := mi.get_surface_override_material(0) as ShaderMaterial
	assert_not_null(mat, "AtW dokulu malzeme")
	assert_not_null(mat.get_shader_parameter("albedo_texture"), "Modelin dokusu")


func test_real_model_has_three_strings() -> void:
	# K60: üç tel. Meshy ağında dört tel izi vardı, tools/kopuz_three_strings.py ham ağdan üç telli oyun kopyasını çıkarır. Teller
	# tahtanın üstünde boşlukta durur (model uzayında z > 0,055): kesitte her telin bir kümesi vardır, ortadaki sapın ortasında.
	var root := (load(Kopuz.MODEL_PATH) as PackedScene).instantiate()
	var faces: PackedVector3Array = (root.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh.get_faces()
	root.free()
	for y: float in [-0.8, -0.6, -0.45, -0.3, -0.15, 0.0, 0.15, 0.3, 0.45]:
		var spans := _string_spans(faces, y)
		assert_eq(spans.size(), 3, "y=%.2f: üç tel: %s" % [y, spans])
		if spans.size() == 3:
			assert_true(spans[0].y < -0.008 and spans[2].x > 0.008, "y=%.2f: iki yanda birer tel: %s" % [y, spans])
			if y > -0.75:
				assert_almost((spans[1].x + spans[1].y) * 0.5, 0.0, 0.005, "y=%.2f: orta tel ortada: %s" % [y, spans])


func test_camp_kopuz_is_the_model_in_one_draw() -> void:
	var npcs := _npcs(false)
	var kopuz := npcs.get_kopuz()
	assert_true(kopuz.has_model(), "Kampın kopuzu Meshy modeli")
	assert_eq(kopuz.find_children("*", "MeshInstance3D", true, false).size(), 1, "Tek çizim")
	assert_true(kopuz.get_strings().is_empty() and kopuz.get_skin() == null, "Kodla parça yok")
	assert_true(kopuz.grip_point().distance_to(kopuz.strum_point()) > 0.3, "Eller sapta ve tellerde: iki ayrı yer")


# --- KopuzPlay ----------------------------------------------------------------------------------

func test_stroke_rate_and_phase_follow_the_grid_of_the_selected_take() -> void:
	# Kol kaydın vuruş ızgarasına uyar (K60, K95): bir tur iki vuruş, aşağı vuruş ızgarada. K75'in counted.strokesPerSec'i (sessiz baş
	# ve kuyruğu da böler) kolun hızı değildir. Çekim değişirse sabitler de değişir.
	var take := int(VoLines.line(SONG).get("take", 0))
	assert_eq(take, int(VoLines.timing(SONG).get("take", -1)), "Satır ve zaman dosyası aynı çekimden")
	var grid := {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SONG_MEASURE))
	assert_true(parsed is Dictionary, "%s okunmalı" % SONG_MEASURE)
	if parsed is Dictionary:
		for row: Variant in (parsed as Dictionary).get("takes", []):
			if int((row as Dictionary).get("seed", 0)) == take:
				grid = row["info"]["strokeGrid"]
	assert_false(grid.is_empty(), "Çekim %d'ün ızgarası ölçüde olmalı" % take)
	if grid.is_empty():
		return
	var per_second := 1.0 / float(grid["period"])
	assert_true(absf(KopuzPlay.STROKE_HZ * 2.0 - per_second) <= per_second * GRID_TOLERANCE,
			"Vuruş/sn %.3f, çekim %d'ün ızgarası %.3f (±%%2)" % [KopuzPlay.STROKE_HZ * 2.0, take, per_second])
	assert_almost(KopuzPlay.STROKE_ANCHOR, float(grid["anchor"]), 0.001, "Aşağı vuruş ızgaranın ilk noktasında")
	assert_true(float(grid["share"]) >= 0.6, "Çekimin vuruşları ızgaraya oturur (%%%d)" % int(float(grid["share"]) * 100.0))
	# Son ızgara noktasına dek kol kaymaz: el orada da telleri geçer (faz hatası ±35 ms'in, vuruş eşleşmesinin, içinde).
	var turns := (float(grid["lastGrid"]) - KopuzPlay.STROKE_ANCHOR) * KopuzPlay.STROKE_HZ
	assert_true(absf(turns * 2.0 - roundf(turns * 2.0)) / (KopuzPlay.STROKE_HZ * 2.0) < 0.035, "Son noktada kayma (%.3f tur)" % turns)


func test_strum_turns_on_the_song_clock() -> void:
	var play := KopuzPlay.new()
	_trash.append(play)
	play.start_strum()
	# Faz sabitinde el telleri aşağı geçer: salınım 0, artıya doğru.
	play.song_time = KopuzPlay.STROKE_ANCHOR
	assert_almost(play.cycles(), 0.0, 0.0001)
	assert_almost(play.swing(), 0.0, 0.0001, "Aşağı vuruşta el tellerin üstünde")
	play.song_time = KopuzPlay.STROKE_ANCHOR + 0.05
	assert_true(play.swing() > 0.0, "Aşağı doğru geçer")
	play.song_time = KopuzPlay.STROKE_ANCHOR + 2.0
	assert_almost(play.cycles(), 2.5068, 0.001, "2 sn'de 2,5068 tur")
	# 2 sn'de ellerin telleri geçişi (sıfır geçişi) 2,5 turun iki katıdır; söylerken yavaşlamaz (faz şarkının saatinden).
	var crossings := 0
	var previous := 0.0
	for i in 2401:
		play.song_time = 0.0005 + 2.0 * float(i) / 2400.0
		var s := play.swing()
		if i > 0 and signf(s) != signf(previous):
			crossings += 1
		previous = s
	assert_between(float(crossings), 5.0, 6.0, "2 sn'de 5–6 tel geçişi (%d)" % crossings)
	play.song_time = 0.1
	var a := play.swing()
	play.song_time = 0.1 + 1.0 / KopuzPlay.STROKE_HZ
	assert_almost(play.swing(), a, 0.0001, "Salınım bir turda (1/STROKE_HZ sn) yinelenir")


func test_palm_mute_stops_the_swing() -> void:
	var play := KopuzPlay.new()
	_trash.append(play)
	play.song_time = 0.5
	assert_almost(play.swing(), 0.0, 0.0001, "Çalmazken salınım yok")
	play.start_strum()
	assert_true(absf(play.swing()) > 0.1, "Çalarken el salınır")
	play.palm_mute()
	for t in [0.3, 0.55, 1.0, 7.7]:
		play.song_time = t
		assert_almost(play.swing(), 0.0, 0.0001, "Avuç tellerde: salınım 0")
		assert_almost(play.strum_offset(), 0.0, 0.0001)


func test_lift_takes_1_1_seconds_and_rest_returns_to_the_first_transform() -> void:
	var npcs := _npcs(false)
	var kopuz := npcs.get_kopuz()
	assert_not_null(kopuz)
	if kopuz == null:
		return
	var first := kopuz.transform
	assert_true(first.is_equal_approx(kopuz.rest_transform), "Kucak pozu sahnedeki dönüşüm")
	var play := KopuzPlay.attach(npcs.get_bard(), kopuz)
	assert_almost(KopuzPlay.LIFT_TIME, 1.1, 0.0001)
	Engine.time_scale = 4.0
	# Kurulumun süresi geçişin ilk adımına girmesin.
	await wait_frames(1)
	var tween := play.lift()
	var samples := 0
	var finished_at := -1.0
	while finished_at < 0.0:
		await get_tree().process_frame
		var t := tween.get_total_elapsed_time()
		if play.lift_weight >= 1.0:
			finished_at = t
		elif t > 0.0:
			# Geçişin her anı 1,1 sn'lik yumuşak eğrinin üstünde (TRANS_SINE, EASE_IN_OUT).
			assert_almost(play.lift_weight, MenuCamera.ease_in_out(t / KopuzPlay.LIFT_TIME), 0.01, "t = %.3f sn" % t)
			samples += 1
	assert_true(samples >= 3, "Geçiş birkaç karede izlenmeli (%d)" % samples)
	assert_between(finished_at, KopuzPlay.LIFT_TIME - 0.001, KopuzPlay.LIFT_TIME + 0.3, "1,1 sn'de çalış pozuna varmalı")
	assert_true(kopuz.transform.is_equal_approx(kopuz.play_transform), "Çalış pozu")
	var back := play.rest()
	while back.is_valid() and back.is_running():
		await get_tree().process_frame
	Engine.time_scale = 1.0
	assert_eq(kopuz.transform, first, "Kucağa dönüş ilk dönüşümle aynı")
	play.set_lift(1.0)
	play.detach()
	assert_eq(kopuz.transform, first, "Kaldırılan değiştirici kopuzu kucağa koyar")


func test_bard_model_has_the_arm_bones_and_lap_pose_touches_no_bone() -> void:
	var npcs := _npcs(true)
	var bard := npcs.get_bard()
	var kopuz := npcs.get_kopuz()
	if not bard.has_meshy_model():
		fail("Ozanın Meshy modeli yüklenmeli (assets/characters/elder/elder.glb)")
		return
	var play := KopuzPlay.attach(bard, kopuz)
	assert_true(play.get_parent() is Skeleton3D, "Değiştirici ozanın iskeletinde")
	assert_true(play.bone_index("RightForeArm") >= 0, "RightForeArm bulunmalı")
	assert_true(play.has_arms(), "İki kolun kemikleri bulunmalı")
	var skeleton := bard.get_skeleton()
	# Kucakta (ağırlık 0) kemiklere dokunulmaz, kopuz kucak pozundadır: menü karesi değişmez.
	assert_true(kopuz.rest_transform.is_equal_approx(LAP_POSE), "Kucak pozu sahnedeki gibi: %s" % kopuz.rest_transform)
	assert_true(kopuz.transform.is_equal_approx(LAP_POSE), "Kopuz kucakta")
	var before := _bone_poses(skeleton)
	play._process_modification()
	assert_eq(_bone_poses(skeleton), before, "Ağırlık 0'da hiçbir kemiğin pozu değişmez")
	var lap := await _posed(skeleton)
	var rest_left: Vector3 = skeleton.global_transform * lap[skeleton.find_bone("LeftHand")].origin
	assert_true(rest_left.distance_to(kopuz.grip_point()) > 0.1, "Kucakta sol el sapta değil")
	play.detach()


func test_left_hand_wraps_the_neck() -> void:
	var npcs := _npcs(true)
	var bard := npcs.get_bard()
	var kopuz := npcs.get_kopuz()
	if not bard.has_meshy_model():
		fail("Ozanın Meshy modeli yüklenmeli (assets/characters/elder/elder.glb)")
		return
	var skeleton := bard.get_skeleton()
	assert_true(HandGrip.has_fingers(skeleton), "Ozanın parmak kemikleri olmalı")
	if not HandGrip.has_fingers(skeleton):
		return
	var play := KopuzPlay.attach(bard, kopuz)
	play.set_lift(1.0)
	var poses := await _posed(skeleton)
	assert_true(kopuz.transform.is_equal_approx(kopuz.play_transform), "Çalış pozu")
	var to_kopuz := kopuz.global_transform.affine_inverse() * skeleton.global_transform
	var mesh := _skinned_mesh(bard)
	# Avuç: sapa oturur ve sapa bakar, sapın altında durur.
	var hand := poses[skeleton.find_bone("LeftHand")]
	var middle := skeleton.get_bone_rest(skeleton.find_bone("LeftMiddle1"))
	var palm := to_kopuz * (hand * (middle.origin * KopuzPlay.PALM_SHARE))
	var section := _in_section(palm)
	assert_between(section.length(), PALM_TO_NECK.x, PALM_TO_NECK.y, "Avuç sapa oturur: sap ekseninden %.3f m" % section.length())
	var aim := (to_kopuz.basis * (hand.basis * middle.basis.z)).normalized()
	var to_axis := Vector3(-section.x, 0.0, -section.y).normalized()
	assert_true(rad_to_deg(aim.angle_to(to_axis)) <= PALM_AIM_MAX, "Avuç sapa bakar: %.0f° sapma" % rad_to_deg(aim.angle_to(to_axis)))
	assert_true(absf(_section_angle(section)) <= PALM_SIDE_MAX, "Avuç sapın altında (%.0f°)" % _section_angle(section))
	var palm_points := _skinned_points(mesh, skeleton, poses, ["LeftHand"], to_kopuz)
	var near_points := PackedVector3Array()
	for p in palm_points:
		if absf(p.y - Kopuz.GRIP.y) < 0.05:
			near_points.append(p)
	assert_true(_inside_share(near_points) <= PALM_INSIDE_MAX, "Avuç sapın içine girmez (pay %.2f)" % _inside_share(near_points))
	# Parmaklar: uçlar sapa değer ve sapın önüne geçer, ağ sapın içine girmez.
	for finger: String in FINGERS:
		var tip := _skinned_points(mesh, skeleton, poses, ["Left%s2" % finger], to_kopuz)
		assert_true(tip.size() > 10, "%s ucunun köşeleri (%d)" % [finger, tip.size()])
		assert_true(_nearest_to_neck(tip) <= FINGER_TIP_REACH, "%s ucu sapa değer: %.3f m" % [finger, _nearest_to_neck(tip)])
		assert_true(_mean_section_angle(tip) >= FINGER_TIP_ANGLE_MIN, "%s ucu sapın önünden sarar: %.0f°" % [finger, _mean_section_angle(tip)])
		var whole := _skinned_points(mesh, skeleton, poses, ["Left%s1" % finger, "Left%s2" % finger], to_kopuz)
		assert_true(_inside_share(whole) <= FINGER_INSIDE_MAX, "%s sapın içine girmez (pay %.2f)" % [finger, _inside_share(whole)])
	# Kol: kemik boyları korunur, bilek sınır içinde kırılır.
	_assert_arm_lengths(skeleton, poses, "Left")
	var bend := _wrist_bend(skeleton, poses, "Left")
	assert_true(bend <= LEFT_WRIST_BEND_MAX, "Sol bilek %.0f° kırılır" % bend)
	play.detach()


func test_right_hand_comes_to_the_strings() -> void:
	var npcs := _npcs(true)
	var bard := npcs.get_bard()
	var kopuz := npcs.get_kopuz()
	if not bard.has_meshy_model():
		fail("Ozanın Meshy modeli yüklenmeli (assets/characters/elder/elder.glb)")
		return
	var skeleton := bard.get_skeleton()
	assert_true(HandGrip.has_fingers(skeleton), "Ozanın parmak kemikleri olmalı")
	if not HandGrip.has_fingers(skeleton):
		return
	var play := KopuzPlay.attach(bard, kopuz)
	play.set_lift(1.0)
	var mesh := _skinned_mesh(bard)
	# Vuruşun ortası ve iki ucu (salınım 0, +1, −1).
	var strokes: Array[float] = [0.0, 0.25, 0.75]
	var crossed := {}
	for cycle: float in strokes:
		play.start_strum()
		play.song_time = KopuzPlay.STROKE_ANCHOR + cycle / KopuzPlay.STROKE_HZ
		var poses := await _posed(skeleton)
		var to_kopuz := kopuz.global_transform.affine_inverse() * skeleton.global_transform
		var hand := poses[skeleton.find_bone("RightHand")]
		var middle := skeleton.get_bone_rest(skeleton.find_bone("RightMiddle1"))
		var aim := (to_kopuz.basis * (hand.basis * middle.basis.z)).normalized()
		var off_skin := rad_to_deg(aim.angle_to(Vector3.FORWARD))
		assert_true(off_skin <= STRUM_AIM_MAX, "Sağ avuç deriye bakar: %.0f° sapma (tur %.2f)" % [off_skin, cycle])
		var nearest := INF
		var sides := Vector2(INF, -INF)
		for finger: String in FINGERS:
			for p: Vector3 in _skinned_points(mesh, skeleton, poses, ["Right%s2" % finger], to_kopuz):
				nearest = minf(nearest, Vector2(p.x, p.z - STRING_Z).length())
				sides = Vector2(minf(sides.x, p.x), maxf(sides.y, p.x))
		assert_true(nearest <= STRUM_TIP_REACH, "Parmak uçları tellere değer: %.3f m (tur %.2f)" % [nearest, cycle])
		crossed[cycle] = sides
		# Ön kol kaseden geçmez: kemiğin çizgisi kesitin dışında kalır (kenarın dışından ya da deri önünden).
		var elbow := to_kopuz * poses[skeleton.find_bone("RightForeArm")].origin
		var wrist := to_kopuz * hand.origin
		for i in 11:
			var p := elbow.lerp(wrist, float(i) / 10.0)
			var in_bowl := absf(p.x) < Kopuz.half_width(p.y) and p.z > BOWL_BACK and p.z < 0.0
			assert_false(in_bowl, "Ön kol kaseden geçmez (%s, tur %.2f)" % [p, cycle])
		_assert_arm_lengths(skeleton, poses, "Right")
		var bend := _wrist_bend(skeleton, poses, "Right")
		assert_true(bend <= RIGHT_WRIST_BEND_MAX, "Sağ bilek %.0f° kırılır (tur %.2f)" % [bend, cycle])
	# Vuruşun iki ucunda parmak uçları telleri geçer: orta tel uçların süpürdüğü aralıkta.
	assert_true(minf(crossed[0.25].x, crossed[0.75].x) < 0.0 and maxf(crossed[0.25].y, crossed[0.75].y) > 0.0, "Uçlar telleri süpürür: %s" % str(crossed))
	assert_true(crossed[0.25].y > crossed[0.75].y + 0.03, "Salınım uçları taşır: %s" % str(crossed))
	play.detach()


func test_hands_move_smoothly_through_the_lift() -> void:
	var npcs := _npcs(true)
	var bard := npcs.get_bard()
	var kopuz := npcs.get_kopuz()
	if not bard.has_meshy_model():
		fail("Ozanın Meshy modeli yüklenmeli (assets/characters/elder/elder.glb)")
		return
	var skeleton := bard.get_skeleton()
	var play := KopuzPlay.attach(bard, kopuz)
	var previous: Array[Transform3D] = []
	for step in 11:
		play.set_lift(float(step) / 10.0)
		var poses := await _posed(skeleton)
		var now: Array[Transform3D] = []
		for bone_name: String in ["LeftHand", "RightHand"]:
			now.append(skeleton.global_transform * poses[skeleton.find_bone(bone_name)])
		if not previous.is_empty():
			for i in now.size():
				var moved := previous[i].origin.distance_to(now[i].origin)
				var turned := rad_to_deg(previous[i].basis.get_rotation_quaternion().angle_to(now[i].basis.get_rotation_quaternion()))
				assert_true(moved <= LIFT_STEP_MAX, "El adımda %.3f m gider (ağırlık %.1f)" % [moved, float(step) / 10.0])
				assert_true(turned <= LIFT_TURN_MAX, "El adımda %.0f° döner (ağırlık %.1f)" % [turned, float(step) / 10.0])
		previous = now
	play.detach()


func test_hand_basis_points_the_fingers_and_the_palm() -> void:
	var rest := Transform3D(Basis(Vector3.RIGHT, 0.4), Vector3(0.5, 9.0, 1.0))
	var fingers := Vector3(0.2, 0.3, 0.9).normalized()
	var palm := Vector3(-0.9, 0.1, 0.2)
	var hand := KopuzPlay.hand_basis(rest, fingers, palm)
	assert_vec_almost((hand * rest.origin).normalized(), fingers, 0.0001, "Parmak kökü fingers yönünde")
	var flat := (palm - fingers * palm.dot(fingers)).normalized()
	var aim := hand * rest.basis.z
	assert_true((aim - fingers * aim.dot(fingers)).normalized().distance_to(flat) < 0.0001, "Avuç palm yönünde")
	assert_almost(hand.determinant(), 1.0, 0.0001, "Saf dönüş")
	assert_almost(KopuzPlay.twist_about(Quaternion(Vector3.UP, 0.7), Vector3.UP), 0.7, 0.0001, "Eksen çevresindeki burulma")
	assert_almost(KopuzPlay.twist_about(Quaternion(Vector3.RIGHT, 0.7), Vector3.UP), 0.0, 0.0001, "Dik dönüşte burulma yok")


func test_two_bone_solver_keeps_bone_lengths() -> void:
	var s := Vector3(0.0, 1.0, 0.0)
	var e := Vector3(0.3, 0.8, 0.1)
	var w := Vector3(0.5, 0.6, 0.3)
	var target := Vector3(0.2, 1.1, 0.4)
	var solved := KopuzPlay.solve_two_bone(s, e, w, target, Vector3.DOWN)
	assert_almost(s.distance_to(solved[0]), s.distance_to(e), 0.0001, "Kol boyu korunur")
	assert_almost(solved[0].distance_to(solved[1]), e.distance_to(w), 0.0001, "Ön kol boyu korunur")
	assert_vec_almost(solved[1], target, 0.0001, "Erişilen hedefe varılır")
	var far := KopuzPlay.solve_two_bone(s, e, w, Vector3(5.0, 1.0, 0.0), Vector3.DOWN)
	assert_true(far[1].distance_to(s) <= s.distance_to(e) + e.distance_to(w) + 0.0001, "Erişilmeyen hedefe kol uzanır")
	var hinted := KopuzPlay.solve_two_bone(s, e, w, target, Vector3.DOWN, Vector3(-1.0, 0.0, 0.0))
	assert_almost(s.distance_to(hinted[0]), s.distance_to(e), 0.0001, "İpucuyla da kol boyu korunur")
	assert_vec_almost(hinted[1], target, 0.0001, "İpucuyla da hedefe varılır")
	var mid := s.lerp(target, 0.5)
	assert_true((hinted[0] - mid).x < 0.0, "Dirsek ipucunun yanına bükülür (%s)" % hinted[0])


# --- Yardımcılar ---------------------------------------------------------------------------------

## Değiştiriciler çalıştıktan sonraki kemik pozları (iskelet uzayında; ardışık iki kare, ilki ağırlığı oturtur).
func _posed(skeleton: Skeleton3D) -> Array[Transform3D]:
	var poses: Array[Transform3D] = []
	var grab := func() -> void:
		poses.assign(_bone_poses(skeleton))
	skeleton.skeleton_updated.connect(grab)
	await wait_frames(2)
	skeleton.skeleton_updated.disconnect(grab)
	return poses


static func _bone_poses(skeleton: Skeleton3D) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	for bone in skeleton.get_bone_count():
		out.append(skeleton.get_bone_global_pose(bone))
	return out


static func _skinned_mesh(bard: CharacterAvatar) -> MeshInstance3D:
	for node in bard.find_children("*", "MeshInstance3D", true, false):
		if (node as MeshInstance3D).skin != null:
			return node
	return null


## Ağın verilen kemiklere baskın köşeleri, derilenmiş, kopuzun uzayında (poses: iskelet uzayında).
static func _skinned_points(mesh: MeshInstance3D, skeleton: Skeleton3D, poses: Array[Transform3D], bone_names: Array, to_kopuz: Transform3D) -> PackedVector3Array:
	var skin := mesh.skin
	var bind_bones := PackedInt32Array()
	var matrices: Array[Transform3D] = []
	for i in skin.get_bind_count():
		var bone := skin.get_bind_bone(i)
		if bone < 0:
			bone = skeleton.find_bone(skin.get_bind_name(i))
		bind_bones.append(bone)
		matrices.append(poses[bone] * skin.get_bind_pose(i))
	var wanted := {}
	for bone_name: String in bone_names:
		wanted[skeleton.find_bone(bone_name)] = true
	var out := PackedVector3Array()
	for surface in mesh.mesh.get_surface_count():
		var arrays := mesh.mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var per := bones.size() / vertices.size()
		for v in vertices.size():
			var share := 0.0
			for k in per:
				if wanted.has(bind_bones[bones[v * per + k]]):
					share += weights[v * per + k]
			if share <= 0.5:
				continue
			var at := Vector3.ZERO
			for k in per:
				var w := weights[v * per + k]
				if w > 0.0:
					at += (matrices[bones[v * per + k]] * vertices[v]) * w
			out.append(to_kopuz * at)
	return out


## Noktanın sap kesitindeki yeri: x, z − GRIP.z (eksen sıfırda).
static func _in_section(p: Vector3) -> Vector2:
	return Vector2(p.x, p.z - Kopuz.GRIP.z)


## Kesitte açı (derece): +X aşağı kenar 0, +Z ön 90, −X üst kenar 180.
static func _section_angle(section: Vector2) -> float:
	return rad_to_deg(atan2(section.y, section.x))


static func _nearest_to_neck(points: PackedVector3Array) -> float:
	var nearest := INF
	for p in points:
		nearest = minf(nearest, _in_section(p).length())
	return nearest


## Kesitte ortalama açı (birim vektörlerin ortalamasından: ±180° sınırında kırılmaz).
static func _mean_section_angle(points: PackedVector3Array) -> float:
	var total := Vector2.ZERO
	for p in points:
		total += _in_section(p).normalized()
	return _section_angle(total)


## Noktaların sapın içine giren payı (kesit yarıçapından yakın).
static func _inside_share(points: PackedVector3Array) -> float:
	if points.is_empty():
		return 0.0
	var inside := 0
	for p in points:
		if _in_section(p).length() < NECK_RADIUS:
			inside += 1
	return float(inside) / float(points.size())


func _assert_arm_lengths(skeleton: Skeleton3D, poses: Array[Transform3D], side: String) -> void:
	var arm := skeleton.find_bone(side + "Arm")
	var fore := skeleton.find_bone(side + "ForeArm")
	var hand := skeleton.find_bone(side + "Hand")
	assert_almost(poses[arm].origin.distance_to(poses[fore].origin), skeleton.get_bone_rest(fore).origin.length(), 0.05, "%s kol boyu korunur (iskelet birimi)" % side)
	assert_almost(poses[fore].origin.distance_to(poses[hand].origin), skeleton.get_bone_rest(hand).origin.length(), 0.05, "%s ön kol boyu korunur (iskelet birimi)" % side)


## Bileğin kırılması (derece): ön kol ile bilekten parmak köküne yön arası.
static func _wrist_bend(skeleton: Skeleton3D, poses: Array[Transform3D], side: String) -> float:
	var fore := poses[skeleton.find_bone(side + "ForeArm")].origin
	var hand := poses[skeleton.find_bone(side + "Hand")].origin
	var middle := poses[skeleton.find_bone(side + "Middle1")].origin
	return rad_to_deg((hand - fore).angle_to(middle - hand))


func _kopuz(path: String) -> Kopuz:
	var kopuz := Kopuz.new()
	kopuz.model_path = path
	add_child(kopuz)
	_trash.append(kopuz)
	return kopuz


func _npcs(meshy: bool) -> CampNpcs:
	var npcs := NPC_SCENE.instantiate() as CampNpcs
	for avatar in npcs.get_avatars():
		avatar.use_meshy_models = meshy and avatar.name == "Elder"
	add_child(npcs)
	_trash.append(npcs)
	return npcs


## Tellerin y kesiti (model uzayında): tahtanın üstündeki üçgenlerin kenarlarının x'leri kümelenir; Vector2(sol, sağ) dizisi.
static func _string_spans(faces: PackedVector3Array, y: float) -> Array[Vector2]:
	var xs := PackedFloat32Array()
	for i in range(0, faces.size(), 3):
		var tri: Array[Vector3] = [faces[i], faces[i + 1], faces[i + 2]]
		if minf(tri[0].z, minf(tri[1].z, tri[2].z)) < 0.055 or maxf(absf(tri[0].x), maxf(absf(tri[1].x), absf(tri[2].x))) > 0.075:
			continue
		for k in 3:
			var a := tri[k]
			var b := tri[(k + 1) % 3]
			if (a.y - y) * (b.y - y) <= 0.0 and not is_equal_approx(a.y, b.y):
				xs.append(lerpf(a.x, b.x, (y - a.y) / (b.y - a.y)))
	xs.sort()
	var out: Array[Vector2] = []
	for x in xs:
		if out.is_empty() or x - out[out.size() - 1].y > 0.008:
			out.append(Vector2(x, x))
		else:
			out[out.size() - 1].y = x
	return out


## Modelin yerel uzaydaki y0..y1 kesitinin sınır kutusu (köşelerden).
static func _slice(kopuz: Kopuz, y0: float, y1: float) -> AABB:
	var box := AABB()
	var first := true
	for p in _local_vertices(kopuz):
		if p.y < y0 or p.y > y1:
			continue
		box = AABB(p, Vector3.ZERO) if first else box.expand(p)
		first = false
	return box


## Kesitin en arka yüzü (z).
static func _slice_back(kopuz: Kopuz, y0: float, y1: float) -> float:
	return _slice(kopuz, y0, y1).position.z


## Modelin köşeleri düğümün yerel uzayında.
static func _local_vertices(kopuz: Kopuz) -> PackedVector3Array:
	var out := PackedVector3Array()
	for node in kopuz.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var xform := Kopuz.relative_transform(kopuz, mi)
		for s in mi.mesh.get_surface_count():
			for p: Vector3 in (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				out.append(xform * p)
	return out


## Sahte model: 2 m boyunda kutu (Kopuz onu 0,95 m'ye ölçekler).
static func _fake_model() -> PackedScene:
	var root := Node3D.new()
	root.name = "FakeKopuz"
	var mi := MeshInstance3D.new()
	mi.name = "Body"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.2, 2.0, 0.1)
	mi.mesh = mesh
	root.add_child(mi)
	mi.owner = root
	var packed := PackedScene.new()
	packed.pack(root)
	root.free()
	return packed


## Ağın üçgen normallerinin çoğu bu yöne mi bakıyor? (Godot'da ön yüz önden saat yönünde: normal = (b−a)×(c−a) tersi.)
static func _faces_toward(mesh: Mesh, direction: Vector3) -> bool:
	var faces := mesh.get_faces()
	var toward := 0
	for i in range(0, faces.size(), 3):
		var n := (faces[i + 2] - faces[i]).cross(faces[i + 1] - faces[i])
		if n.dot(direction) > 0.0:
			toward += 1
	return toward * 3 >= faces.size() * 0.9


## Engine.time_scale'li bekleme: başlangıçtan bu yana ölçekli süre seconds olana dek.
func _wait_scaled(started_msec: int, seconds: float) -> void:
	while float(Time.get_ticks_msec() - started_msec) / 1000.0 * Engine.time_scale < seconds:
		await get_tree().process_frame
