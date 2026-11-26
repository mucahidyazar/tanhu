extends TestCase
## MenuCamera: ekran oranına göre görüş açısı uyarlaması ve salınım fonksiyonu; menü kadrajının K98 kuralı (eğim ≥30°,
## ateşe ≥25 m, görüş 30–40°, ufuk yok, ayakta kişi karenin %6–15'i); Önsöz'ün geri çekilmesi (K68): WIDE (ateşe 40 m,
## eğim 9°, görüş 41,76°; izdüşümde ateş %80, ufuk %29), menü kadrajından (26,4 m, 38°, 36°) 1,52 kat, 0/3/6 sn pozları,
## uzaklık hiç azalmaz ve ateş karede kalır, 6 sn'lik uçuş, WIDE çevresinde paralakssız salınım (menu_transform değişmez) ve
## yolun engellere payı (saf hesap; dünyadaki çam, kaya ve zemin payı test_world_scene.gd'de).


func test_wider_screen_keeps_vertical_fov() -> void:
	var fit := MenuCamera.fit_fov(32.5, 16.0 / 9.0, 21.0 / 9.0)
	assert_eq(fit["keep"], Camera3D.KEEP_HEIGHT)
	assert_almost(fit["fov"], 32.5, 0.0001)


func test_design_aspect_keeps_vertical_fov() -> void:
	var fit := MenuCamera.fit_fov(32.5, 16.0 / 9.0, 16.0 / 9.0)
	assert_eq(fit["keep"], Camera3D.KEEP_HEIGHT)
	assert_almost(fit["fov"], 32.5, 0.0001)


func test_narrower_screen_keeps_horizontal_fov() -> void:
	# 16:10 ekranda yatay açı, 16:9 tasarımdaki yatay açıya eşit olmalı (yanlar kesilmesin).
	var design_aspect := 16.0 / 9.0
	var fit := MenuCamera.fit_fov(32.5, design_aspect, 1.6)
	assert_eq(fit["keep"], Camera3D.KEEP_WIDTH)
	var design_half_width := atan(tan(deg_to_rad(32.5) * 0.5) * design_aspect)
	assert_almost(deg_to_rad(fit["fov"]) * 0.5, design_half_width, 0.0001)
	# Dikey açı tasarımdakinden büyük olur: üstte/altta daha fazla görünür.
	assert_true(MenuCamera.vertical_fov_of(fit["fov"], fit["keep"], 1.6) > 32.5)


func test_vertical_fov_round_trip() -> void:
	# 4:3 ekranda yatay açı korunur; o yatay açının dikey karşılığından tekrar yatay açı hesaplanınca aynısı çıkmalı.
	var fit := MenuCamera.fit_fov(30.0, 16.0 / 9.0, 4.0 / 3.0)
	var vfov := MenuCamera.vertical_fov_of(fit["fov"], fit["keep"], 4.0 / 3.0)
	var hfov := rad_to_deg(2.0 * atan(tan(deg_to_rad(vfov) * 0.5) * 4.0 / 3.0))
	assert_almost(hfov, fit["fov"], 0.0001)
	assert_almost(MenuCamera.vertical_fov_of(30.0, Camera3D.KEEP_HEIGHT, 2.0), 30.0, 0.0001)


func test_invalid_aspect_falls_back_to_design() -> void:
	var fit := MenuCamera.fit_fov(32.5, 16.0 / 9.0, 0.0)
	assert_eq(fit["keep"], Camera3D.KEEP_HEIGHT)
	assert_almost(fit["fov"], 32.5, 0.0001)


func test_drift_is_identity_without_motion() -> void:
	var base := Transform3D(Basis(Vector3.UP, 0.3), Vector3(1.0, 2.0, 3.0))
	var t := MenuCamera.drift_transform(base, 0.0, Vector2.ZERO, 0.0, 0.2, 1.0)
	assert_vec_almost(t.origin, base.origin, 0.0001)
	assert_vec_almost(t.basis.z, base.basis.z, 0.0001)


func test_drift_stays_small() -> void:
	var base := Transform3D.IDENTITY
	for i in 50:
		var t := MenuCamera.drift_transform(base, float(i) * 0.37, Vector2(1.0, -1.0), 0.06, 0.18, 1.2)
		assert_true(t.origin.length() <= 0.0601 * 1.2)
		assert_true(t.basis.z.angle_to(Vector3.BACK) <= deg_to_rad(1.5))


# --- Önsöz'ün geri çekilmesi (K68, godot.md §3.6; Yol Haritası prologue-pullback) -------------------

## Ateş (kamp merkezi) ve menü kadrajı (main.tscn'deki MenuCamera).
const FIRE := Vector3.ZERO
const MAIN_SCENE := "res://scenes/main.tscn"

var _cameras: Array[Node] = []


func after_each() -> void:
	Engine.time_scale = 1.0
	for node in _cameras:
		if is_instance_valid(node):
			node.queue_free()
	_cameras.clear()


func test_wide_frame_matches_the_design() -> void:
	var wide := MenuCamera.wide_transform()
	assert_almost(wide.origin.distance_to(FIRE), 40.0, 0.1, "WIDE ateşe 40 m")
	var forward := -wide.basis.z
	assert_almost(rad_to_deg(asin(-forward.y)), 9.0, 0.01, "Eğim 9°")
	assert_almost(atan2(forward.x, -forward.z), 0.0, 0.0001, "Yön kuzey (-Z)")
	assert_almost(MenuCamera.WIDE_FOV, 41.76, 0.0001, "WIDE'ın görüş açısı (K68'de onaylanan kare)")
	var menu := _menu_transform()
	assert_almost(menu.origin.distance_to(FIRE), 26.4, 0.05, "Menü kadrajı ateşe 26,4 m")
	assert_almost(wide.origin.distance_to(FIRE) / menu.origin.distance_to(FIRE), 1.52, 0.01, "WIDE menüden 1,52 kat geride")
	# İzdüşüm (16:9): WIDE'da ateş yukarıdan %80, ufuk %29; menü karesinde ateş sağ ortada, ufuk yok.
	assert_almost(MenuCamera.screen_y(wide, MenuCamera.WIDE_FOV, FIRE), 0.80, 0.02, "Ateş karenin %80'inde")
	assert_almost(MenuCamera.horizon_y(wide, MenuCamera.WIDE_FOV), 0.29, 0.02, "Ufuk karenin %29'unda")
	assert_almost(MenuCamera.screen_y(menu, MenuCamera.MENU_FOV, FIRE), 0.605, 0.02, "Menü karesinde ateş yukarıdan %60")
	assert_almost(_screen_x(menu, MenuCamera.MENU_FOV, FIRE), 0.583, 0.02, "Menü karesinde ateş soldan %58 (sağ ortada)")
	assert_true(MenuCamera.horizon_y(menu, MenuCamera.MENU_FOV) < 0.0, "Menü karesinde ufuk yok (gök görünmez)")


## K98 (kullanıcının sözü; docs/media/review/kadraj_referans.webp): menü kamerası da uzak ve yüksek açılıdır.
func test_menu_frame_follows_the_far_rule() -> void:
	var menu := _menu_transform()
	var vfov := _menu_design_fov()
	assert_almost(vfov, MenuCamera.MENU_FOV, 0.001, "Sahnenin görüş açısı MENU_FOV")
	assert_almost(_pitch(menu), MenuCamera.MENU_PITCH_DEG, 0.01, "Sahnenin eğimi MENU_PITCH_DEG")
	assert_true(_pitch(menu) >= 30.0, "Eğim ≥30° (%.1f°)" % _pitch(menu))
	assert_between(_pitch(menu), 35.0, 50.0, "Eğim hedef bandında")
	assert_between(vfov, 30.0, 40.0, "Görüş 30–40°")
	assert_true(menu.origin.distance_to(FIRE) >= 25.0, "Ateşe ≥25 m (%.1f m)" % menu.origin.distance_to(FIRE))
	assert_true(MenuCamera.horizon_y(menu, vfov) < 0.0, "Ufuk görünmez")
	assert_almost(atan2(-menu.basis.z.x, menu.basis.z.z), 0.0, 0.0001, "Yön kuzey")
	# Ateşin başında ayakta duran kişi (1,7 m) karenin %6–15'i.
	var person := MenuCamera.screen_y(menu, vfov, FIRE) - MenuCamera.screen_y(menu, vfov, FIRE + Vector3(0.0, 1.7, 0.0))
	assert_between(person, 0.06, 0.15, "Ayakta kişi karenin %.1f%%'i" % (person * 100.0))
	# Yurtlar ve ahır karede; ateş sol yarının (menü panelinin) dışında.
	for point: Vector3 in [Vector3(-6.18, 1.5, -4.31), Vector3(6.64, 1.5, -7.26), Vector3(13.76, 1.5, -14.65)]:
		var y := MenuCamera.screen_y(menu, vfov, point)
		var x := _screen_x(menu, vfov, point)
		assert_true(x > 0.0 and x < 1.0 and y > 0.0 and y < 1.0, "%s karede (%.2f, %.2f)" % [point, x, y])
	assert_true(_screen_x(menu, vfov, FIRE) > 0.5, "Ateş karenin sağ yarısında")


func test_pullback_poses_follow_the_table() -> void:
	var menu := _menu_transform()
	var start := MenuCamera.pullback_pose(menu, 0.0)
	assert_vec_almost(start.origin, menu.origin, 0.0001, "0 sn: menü kadrajı")
	var mid := MenuCamera.pullback_pose(menu, 3.0)
	assert_vec_almost(mid.origin, Vector3(-1.12, 16.23, 28.33), 0.05, "3 sn: yolun ortası")
	assert_almost(_pitch(mid), 23.5, 0.2, "3 sn: eğim 23,5°")
	assert_almost(mid.origin.distance_to(FIRE), 32.7, 0.1, "3 sn: ateşe 32,7 m")
	var mid_fov := lerpf(MenuCamera.MENU_FOV, MenuCamera.WIDE_FOV, MenuCamera.ease_in_out(0.5))
	assert_true(MenuCamera.horizon_y(mid, mid_fov) < 0.0, "3 sn: ufuk henüz karede değil")
	var late := MenuCamera.pullback_pose(menu, 4.0)
	var late_fov := lerpf(MenuCamera.MENU_FOV, MenuCamera.WIDE_FOV, MenuCamera.ease_in_out(4.0 / 6.0))
	assert_almost(MenuCamera.horizon_y(late, late_fov), 0.10, 0.02, "4 sn: ufuk %10'da (gök kareye girer)")
	var end := MenuCamera.pullback_pose(menu, 6.0)
	assert_vec_almost(end.origin, MenuCamera.WIDE_ORIGIN, 0.05, "6 sn: WIDE")
	assert_almost(_pitch(end), 9.0, 0.2)
	# Tween'in eğrisi (TRANS_SINE, EASE_IN_OUT): başta ve sonda yavaş, ortada simetrik.
	assert_almost(MenuCamera.ease_in_out(0.5), 0.5, 0.0001)
	assert_true(MenuCamera.ease_in_out(0.1) < 0.1 and MenuCamera.ease_in_out(0.9) > 0.9)
	assert_almost(MenuCamera.ease_in_out(0.25) + MenuCamera.ease_in_out(0.75), 1.0, 0.0001)


func test_pullback_moves_away_and_keeps_the_fire_in_frame() -> void:
	# Kamera ozana yaklaşmaz (K68): ateşe (ozanın yanı) uzaklık 0–6 sn boyunca hiç azalmaz; ateş ve ozan karede kalır,
	# karede sıçramaz (0,1 sn'de ≤%2 kayar). Görüş açısı uçuşla birlikte 36°'den 41,76°'ye yürür.
	var menu := _menu_transform()
	var last_d := 0.0
	var last := Vector2(-1.0, -1.0)
	for i in 61:
		var t := float(i) * 0.1
		var pose := MenuCamera.pullback_pose(menu, t)
		var vfov := lerpf(MenuCamera.MENU_FOV, MenuCamera.WIDE_FOV, MenuCamera.ease_in_out(t / MenuCamera.PULLBACK_TIME))
		var d := pose.origin.distance_to(FIRE)
		assert_true(d >= last_d - 0.0001, "t=%.1f: uzaklık azalmaz (%.2f → %.2f m)" % [t, last_d, d])
		last_d = d
		var at := Vector2(_screen_x(pose, vfov, FIRE), MenuCamera.screen_y(pose, vfov, FIRE))
		assert_true(at.x > 0.1 and at.x < 0.9 and at.y > 0.1 and at.y < 0.9, "t=%.1f: ateş karede %s" % [t, at])
		if last.x >= 0.0:
			assert_true(at.distance_to(last) <= 0.02, "t=%.1f: ateş karede sıçramaz (%s → %s)" % [t, last, at])
		last = at
	assert_almost(last_d, 40.0, 0.1, "Yolun sonu WIDE")


func test_fly_to_reaches_wide_in_six_seconds() -> void:
	var camera := _camera()
	Engine.time_scale = 6.0
	var started := Time.get_ticks_msec()
	camera.fly_to(MenuCamera.wide_transform(), MenuCamera.PULLBACK_TIME, MenuCamera.WIDE_FOV)
	await _wait_scaled(started, 3.0)
	assert_true(camera.is_flying(), "6 sn dolmadan uçuş sürer")
	await _wait_scaled(started, MenuCamera.PULLBACK_TIME + 0.2)
	Engine.time_scale = 1.0
	assert_false(camera.is_flying())
	assert_vec_almost(camera.global_transform.origin, MenuCamera.WIDE_ORIGIN, 0.001, "6 sn'de WIDE")
	assert_almost(camera.fov, MenuCamera.WIDE_FOV, 0.001)
	camera.fly_to(_menu_transform(), 10.0)
	camera.stop_flight()
	assert_false(camera.is_flying(), "stop_flight uçuşu durdurur")


func test_drift_around_wide_keeps_the_menu_transform() -> void:
	var camera := _camera()
	var menu := camera.menu_transform
	var wide := MenuCamera.wide_transform()
	camera.start_drift(wide)
	assert_true(camera.has_drift_base and camera.drifting)
	assert_vec_almost(camera.global_transform.origin, wide.origin, 0.0001, "Salınım WIDE'dan zıplamadan başlar")
	# WIDE kendi görüşüyle (41,76°, K68'in onaylı karesi) nefes alır; menü kadrajı K98 ile 36°'ye daraldı.
	var size := camera.get_viewport().get_visible_rect().size
	var aspect := size.x / size.y if size.y > 0.0 else 16.0 / 9.0
	var fit := MenuCamera.fit_fov(MenuCamera.WIDE_FOV, camera.design_aspect, aspect)
	assert_almost(camera.fov, float(fit["fov"]), 0.01, "WIDE'da görüş WIDE_FOV (bu ekran oranında)")
	assert_eq(camera.keep_aspect, int(fit["keep"]))
	Engine.time_scale = 8.0
	var started := Time.get_ticks_msec()
	var widest := 0.0
	while float(Time.get_ticks_msec() - started) / 1000.0 * Engine.time_scale < 9.0:
		await get_tree().process_frame
		var local := wide.basis.inverse() * (camera.global_transform.origin - wide.origin)
		assert_true(absf(local.x) <= 0.0601 and absf(local.y) <= 0.0301 and absf(local.z) <= 0.0001, "Salınım WIDE çevresinde ≤0,06 m (%s)" % local)
		widest = maxf(widest, absf(local.x))
		assert_true(camera.global_transform.basis.is_equal_approx(wide.basis), "WIDE'da fare paralaksı yok")
	Engine.time_scale = 1.0
	assert_true(widest > 0.01, "Kamera WIDE'da nefes almalı (%.3f m)" % widest)
	assert_eq(camera.menu_transform, menu, "menu_transform değişmez")
	camera.clear_drift()
	assert_false(camera.has_drift_base)
	camera.start_drift(wide)
	Engine.time_scale = 20.0
	camera.return_to_menu(0.2)
	await wait_frames(2)
	assert_false(camera.has_drift_base, "return_to_menu drift_base'i boşaltır")
	await _wait_scaled(Time.get_ticks_msec(), 0.4)
	Engine.time_scale = 1.0
	assert_vec_almost(camera.global_transform.origin, menu.origin, 0.07, "Menüye dönüş kadrajı")


func test_path_clearance_measures_crowns_rocks_and_ground() -> void:
	# Ölçeği 0,5 olan çam (5 m): tacı 0,5–5 m arasında, tabanda 1,4 m yarıçaplı koni.
	var tree := Vector4(10.0, 0.0, 0.5, 0.0)
	var beside := MenuCamera.crown_clearance(Vector3(13.0, 0.5, 0.0), tree)
	assert_almost(beside, 3.0 - TreeKit.CONE_BASE_RADIUS * 0.5, 0.01, "Tacın dibinde yatay pay")
	assert_true(MenuCamera.crown_clearance(Vector3(10.2, 2.0, 0.0), tree) < 0.0, "Tacın içinde eksi")
	assert_almost(MenuCamera.crown_clearance(Vector3(10.0, 7.0, 0.0), tree), 7.0 - TreeKit.CONE_TOP * 0.5, 0.01, "Tepenin üstünde dikey pay")
	var ground := func(_x: float, _z: float) -> float: return 1.0
	var samples := PackedVector3Array([Vector3(0.0, 4.0, 0.0), Vector3(0.0, 2.5, 5.0)])
	var trees: Array[Vector4] = [tree]
	var rocks: Array[Vector4] = [Vector4(0.0, 1.0, 9.0, 1.5)]
	assert_almost(MenuCamera.path_clearance(samples, trees, rocks, ground), 1.5, 0.001, "En küçük pay zemine (2,5 − 1)")
	var none: Array[Vector4] = []
	assert_almost(MenuCamera.path_clearance(PackedVector3Array([Vector3(0.0, 9.0, 0.0)]), none, rocks, Callable()),
		Vector3(0.0, 9.0, 0.0).distance_to(Vector3(0.0, 1.0, 9.0)) - 1.5, 0.001, "Kaya küredir")
	var path := MenuCamera.pullback_samples(_menu_transform(), 0.1)
	assert_eq(path.size(), 61, "0–6 sn, 0,1 sn adım")
	assert_vec_almost(path[path.size() - 1], MenuCamera.WIDE_ORIGIN, 0.0001)


func _camera() -> MenuCamera:
	var camera := MenuCamera.new()
	camera.design_fov = MenuCamera.MENU_FOV
	camera.menu_transform = _menu_transform()
	camera.drift_amount = 0.06
	add_child(camera)
	camera.global_transform = camera.menu_transform
	_cameras.append(camera)
	return camera


## main.tscn'deki MenuCamera'nın dönüşümü (menü kadrajı).
static func _menu_transform() -> Transform3D:
	var state := (load(MAIN_SCENE) as PackedScene).get_state()
	for i in state.get_node_count():
		if state.get_node_name(i) != &"MenuCamera":
			continue
		for p in state.get_node_property_count(i):
			if state.get_node_property_name(i, p) == &"transform":
				return state.get_node_property_value(i, p)
	return Transform3D.IDENTITY


## main.tscn'deki MenuCamera'nın design_fov'u (16:9'daki dikey görüş).
static func _menu_design_fov() -> float:
	var state := (load(MAIN_SCENE) as PackedScene).get_state()
	for i in state.get_node_count():
		if state.get_node_name(i) != &"MenuCamera":
			continue
		for p in state.get_node_property_count(i):
			if state.get_node_property_name(i, p) == &"design_fov":
				return float(state.get_node_property_value(i, p))
	return NAN


static func _pitch(xform: Transform3D) -> float:
	return rad_to_deg(asin(xform.basis.z.y))


## Noktanın karede soldan oranı (16:9; dikey görüş vfov_deg).
static func _screen_x(xform: Transform3D, vfov_deg: float, point: Vector3) -> float:
	var local := xform.affine_inverse() * point
	return 0.5 + (local.x / -local.z) / (tan(deg_to_rad(vfov_deg) * 0.5) * 16.0 / 9.0) * 0.5


func _wait_scaled(started_msec: int, seconds: float) -> void:
	while float(Time.get_ticks_msec() - started_msec) / 1000.0 * Engine.time_scale < seconds:
		await get_tree().process_frame
