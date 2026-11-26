extends TestCase
## FollowCamera testleri: kamera dönüşümü (açı, uzaklık, hedefe bakış), yakınlaştırmaya bağlı eğim,
## zemine gömülmeme, gecikmeli takip, döndürme/yakınlaştırma girişleri ve etkinleşme geçişi; eğim bandı (15–60°, K39) ve
## girdileri (orta tuş, Alt + tekerlek, ; '), `/` ile varsayılana dönüş, ayarın eğim payı, ön ayarlar (CameraPreset), K98 kadrajının
## sayıları (act1.md §4, k98-recalc) ve ses dinleyicisi (oyuncunun 1,5 m üstü; ateşin düzeyi 14–40 m'de ±1,5 dB, audio.md §1).

const DT := 1.0 / 60.0
## Projeksiyon sınamalarının ekranı (1080p, 16:9).
const SCREEN := Vector2i(1920, 1080)


## Sabit yükseklikli (isteğe bağlı eğimli) zemin.
class FlatShape:
	extends TerrainShape
	var level := 0.0
	var slope := Vector2.ZERO

	func height_at(x: float, z: float) -> float:
		return level + slope.x * x + slope.y * z


## Örten nesne casusu: FollowCamera'nın görüş hattı bildirimlerini kaydeder.
class OccluderSpy:
	extends Node
	var calls := 0
	var last_from := Vector3.ZERO
	var last_to := Vector3.ZERO

	func set_camera_occlusion(from: Vector3, to: Vector3) -> void:
		calls += 1
		last_from = from
		last_to = to


# --- Saf yardımcılar ------------------------------------------------------------

func test_compute_transform_keeps_distance_pitch_and_looks_at_target() -> void:
	var target := Vector3(3.0, 1.2, -4.0)
	for yaw in [0.0, 0.8, -2.4, PI]:
		for pitch in [35.0, 50.0, 70.0]:
			for distance in [5.0, 9.0, 14.0]:
				var xform := FollowCamera.compute_transform(target, yaw, pitch, distance)
				var label := "yaw %f, eğim %f, uzaklık %f" % [yaw, pitch, distance]
				assert_almost(xform.origin.distance_to(target), distance, 0.0001, "Uzaklık: " + label)
				var forward := -xform.basis.z.normalized()
				assert_vec_almost(forward, (target - xform.origin).normalized(), 0.0001, "Hedefe bakmalı: " + label)
				assert_almost(rad_to_deg(asin(-forward.y)), pitch, 0.01, "Aşağı bakış açısı: " + label)
				assert_true(xform.origin.y > target.y, "Kamera hedefin üstünde olmalı: " + label)
				assert_almost(xform.basis.x.y, 0.0, 0.0001, "Kamera yana yatmamalı: " + label)


func test_yaw_zero_sits_behind_on_plus_z_like_the_menu_camera() -> void:
	var xform := FollowCamera.compute_transform(Vector3.ZERO, 0.0, 50.0, 9.0)
	assert_almost(xform.origin.x, 0.0, 0.0001)
	assert_almost(xform.origin.z, 9.0 * cos(deg_to_rad(50.0)), 0.0001, "Kamera +Z tarafında olmalı")
	assert_almost(xform.origin.y, 9.0 * sin(deg_to_rad(50.0)), 0.0001)
	var right := FollowCamera.compute_transform(Vector3.ZERO, PI * 0.5, 50.0, 9.0)
	assert_true(right.origin.x > 5.0 and absf(right.origin.z) < 0.0001, "yaw 90° iken kamera +X tarafında olmalı")


func test_pitch_steepens_when_zooming_out_and_never_drops_when_zooming_in() -> void:
	assert_almost(FollowCamera.pitch_for_distance(9.0, 50.0, 9.0, 5.0, 14.0, 6.0), 50.0, 0.0001, "Başlangıç uzaklığında ~50°")
	assert_almost(FollowCamera.pitch_for_distance(14.0, 50.0, 9.0, 5.0, 14.0, 6.0), 56.0, 0.0001, "Uzakta daha dik")
	assert_almost(FollowCamera.pitch_for_distance(30.0, 50.0, 9.0, 5.0, 14.0, 6.0), 56.0, 0.0001, "Sınırın ötesinde sabit")
	assert_between(FollowCamera.pitch_for_distance(11.0, 50.0, 9.0, 5.0, 14.0, 6.0), 50.0, 56.0)
	for d in [8.0, 7.0, 5.0, 1.0]:
		assert_almost(FollowCamera.pitch_for_distance(d, 50.0, 9.0, 5.0, 14.0, 6.0), 50.0, 0.0001, "%.0f m: yakınlaşınca yatıklaşmaz" % d)


func test_lift_above_ground_raises_camera_and_keeps_looking_at_focus() -> void:
	var focus := Vector3(0.0, 0.7, 0.0)
	var low := FollowCamera.compute_transform(focus, 0.0, 50.0, 9.0)
	var lifted := FollowCamera.lift_above_ground(low, focus, 10.0, 1.0)
	assert_almost(lifted.origin.y, 11.0, 0.0001, "Zeminin clearance kadar üstüne çıkmalı")
	assert_almost(lifted.origin.x, low.origin.x, 0.0001)
	assert_almost(lifted.origin.z, low.origin.z, 0.0001)
	assert_vec_almost(-lifted.basis.z.normalized(), (focus - lifted.origin).normalized(), 0.0001, "Hâlâ odağa bakmalı")
	var high := FollowCamera.lift_above_ground(low, focus, -5.0, 1.0)
	assert_eq(high, low, "Zaten yüksekteyse değişmemeli")


func test_smoothing_is_frame_rate_independent() -> void:
	assert_almost(FollowCamera.smoothing(6.0, 0.0), 0.0, 0.0001)
	assert_between(FollowCamera.smoothing(6.0, 10.0), 0.999, 1.0)
	var one := FollowCamera.smoothing(6.0, 0.02)
	var two_steps := 1.0 - (1.0 - one) * (1.0 - one)
	assert_almost(two_steps, FollowCamera.smoothing(6.0, 0.04), 0.0001, "İki küçük adım = bir büyük adım")


# --- Sahnede takip ----------------------------------------------------------------

func test_snaps_behind_the_target_on_start() -> void:
	var rig := await _make_rig(FlatShape.new())
	var cam: FollowCamera = rig[0]
	var target: Node3D = rig[1]
	var expected := FollowCamera.compute_transform(target.position + Vector3(0.0, cam.look_height, 0.0), 0.0, cam.pitch_deg, cam.distance)
	assert_vec_almost(cam.camera.global_position, expected.origin, 0.001, "Açılışta karakterin arkasına oturmalı")
	assert_almost(cam.camera.fov, FollowCamera.DEFAULT_FOV, 0.001, "Görüş açısı kameranın varsayılanı olmalı")
	assert_almost(cam.get_yaw(), 0.0, 0.0001)
	assert_true(cam.camera.current, "Kamera etkin olmalı")
	_free_rig(rig)


func test_follow_lags_a_little_then_catches_up() -> void:
	var rig := await _make_rig(FlatShape.new())
	var cam: FollowCamera = rig[0]
	var target: Node3D = rig[1]
	var start := cam.camera.global_position
	target.position += Vector3(3.0, 0.0, 0.0)
	cam.update_camera(DT)
	var moved := cam.camera.global_position.distance_to(start)
	assert_between(moved, 0.01, 1.0, "Kamera hafif gecikmeyle izlemeli (bir karede 3 m atlamamalı)")
	for i in 180:
		cam.update_camera(DT)
	assert_almost(cam.camera.global_position.distance_to(start), 3.0, 0.01, "Kısa sürede yetişmeli")
	_free_rig(rig)


func test_camera_never_goes_below_the_terrain() -> void:
	# Kameranın durduğu taraf (+Z) yükselen bir yamaç: kamera zeminin üstünde kalmalı.
	var shape := FlatShape.new()
	shape.slope = Vector2(0.0, 1.2)
	var rig := await _make_rig(shape)
	var cam: FollowCamera = rig[0]
	var target: Node3D = rig[1]
	cam.snap_to_target()
	var p := cam.camera.global_position
	assert_true(p.y >= shape.height_at(p.x, p.z) + cam.ground_clearance - 0.001, "Kamera araziye gömülmemeli: %s" % p)
	var focus := target.position + Vector3(0.0, cam.look_height, 0.0)
	assert_vec_almost(-cam.camera.global_basis.z.normalized(), (focus - p).normalized(), 0.001, "Hâlâ karaktere bakmalı")
	_free_rig(rig)


func test_zoom_is_clamped_between_min_and_max() -> void:
	var rig := await _make_rig(FlatShape.new())
	var cam: FollowCamera = rig[0]
	cam.zoom_by(-100.0)
	assert_almost(cam.get_target_distance(), cam.min_distance, 0.0001, "En yakın sınırda durmalı")
	cam.zoom_by(100.0)
	assert_almost(cam.get_target_distance(), cam.max_distance, 0.0001, "En uzak sınırda durmalı")
	for i in 120:
		cam.update_camera(DT)
	var target: Node3D = rig[1]
	var focus := target.position + Vector3(0.0, cam.look_height, 0.0)
	assert_almost(cam.camera.global_position.distance_to(focus), cam.max_distance, 0.02, "Uzaklık yumuşakça hedefe varmalı")
	_free_rig(rig)


func test_mouse_wheel_zooms_and_right_drag_rotates() -> void:
	var rig := await _make_rig(FlatShape.new())
	var cam: FollowCamera = rig[0]
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	cam._unhandled_input(wheel)
	assert_almost(cam.get_target_distance(), cam.distance + cam.zoom_step, 0.0001, "Tekerlek aşağı = uzaklaş")
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	cam._unhandled_input(wheel)
	cam._unhandled_input(wheel)
	assert_almost(cam.get_target_distance(), cam.distance - cam.zoom_step, 0.0001, "Tekerlek yukarı = yaklaş")
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	cam._unhandled_input(press)
	var drag := InputEventMouseMotion.new()
	drag.relative = Vector2(100.0, 0.0)
	drag.button_mask = MOUSE_BUTTON_MASK_RIGHT
	cam._unhandled_input(drag)
	for i in 120:
		cam.update_camera(DT)
	assert_almost(rad_to_deg(cam.get_yaw()), -100.0 * cam.mouse_sensitivity, 0.05, "Sağa sürüklemek görüşü sağa çevirmeli")
	press.pressed = false
	cam._unhandled_input(press)
	cam._unhandled_input(drag)
	for i in 30:
		cam.update_camera(DT)
	assert_almost(rad_to_deg(cam.get_yaw()), -100.0 * cam.mouse_sensitivity, 0.05, "Tuş bırakılınca sürükleme dönmemeli")
	_free_rig(rig)


func test_trackpad_gestures_count_once_though_godot_sends_them_twice() -> void:
	# Godot 4.7.2'de Input'tan geçen jest dinleyiciye iki kopya varır (GestureDedupe); kıstırma ve iki parmakla kaydırma bir kez işlenir.
	var rig := await _make_rig(FlatShape.new())
	var cam: FollowCamera = rig[0]
	cam.set_active(true)
	await wait_frames(2)
	var before := cam.get_target_distance()
	var pan := InputEventPanGesture.new()
	pan.position = Vector2(400.0, 300.0)
	pan.delta = Vector2(0.0, 2.0)
	Input.parse_input_event(pan)
	await wait_frames(3)
	assert_almost(cam.get_target_distance() - before, 2.0 * cam.pan_zoom_scale, 0.001, "İki parmakla kaydırma bir kez yakınlaştırır")
	var mid := cam.get_target_distance()
	var pinch := InputEventMagnifyGesture.new()
	pinch.position = Vector2(400.0, 300.0)
	pinch.factor = 1.25
	Input.parse_input_event(pinch)
	await wait_frames(3)
	assert_almost(cam.get_target_distance(), mid / 1.25, 0.001, "Kıstırma bir kez yakınlaştırır")
	# Aynı karede elle verilen iki ayrı jest (değerleri farklı) ikisi de işlenir.
	var a := InputEventPanGesture.new()
	a.delta = Vector2(0.0, 1.0)
	var b := InputEventPanGesture.new()
	b.delta = Vector2(0.0, 0.5)
	var start := cam.get_target_distance()
	cam._unhandled_input(a)
	cam._unhandled_input(b)
	assert_almost(cam.get_target_distance() - start, 1.5 * cam.pan_zoom_scale, 0.001, "Farklı iki jest ikisi de sayılır")
	_free_rig(rig)


func test_drag_ends_when_the_release_event_was_missed() -> void:
	var rig := await _make_rig(FlatShape.new())
	var cam: FollowCamera = rig[0]
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	cam._unhandled_input(press)
	# Tuş pencerenin dışında bırakıldı: bırakma olayı hiç gelmedi, sonraki harekette tuş basılı değil.
	var hover := InputEventMouseMotion.new()
	hover.relative = Vector2(80.0, 0.0)
	cam._unhandled_input(hover)
	var held := InputEventMouseMotion.new()
	held.relative = Vector2(80.0, 0.0)
	held.button_mask = MOUSE_BUTTON_MASK_RIGHT
	cam._unhandled_input(held)
	for i in 60:
		cam.update_camera(DT)
	assert_almost(cam.get_yaw(), 0.0, 0.0001, "Basılı tuş yokken fare hareketi kamerayı döndürmemeli")
	_free_rig(rig)


func test_e_turns_the_camera_only_while_it_has_no_other_job() -> void:
	# godot.md §5.3: E hem kamera hem «kullan»dır; oyuncu E'yi başka işe kullanıyorsa kamera o yöne dönmez, Q'ya dokunulmaz.
	var rig := await _make_rig(FlatShape.new())
	var cam: FollowCamera = rig[0]
	cam.set_active(true)
	Input.action_press(&"camera_right")
	var before := cam.get_yaw()
	cam._process(DT)
	assert_ne(cam._target_yaw, before, "E kamerayı döndürür")
	var turned: float = cam._target_yaw
	cam.hold_turn_right = true
	cam._process(DT)
	assert_almost(cam._target_yaw, turned, 0.0001, "E'nin işi varken dönmez")
	Input.action_release(&"camera_right")
	Input.action_press(&"camera_left")
	cam._process(DT)
	assert_ne(cam._target_yaw, turned, "Q yine döndürür")
	Input.action_release(&"camera_left")
	_free_rig(rig)


func test_right_drag_can_be_given_to_aiming_and_middle_drag_always_rotates() -> void:
	var rig := await _make_rig(FlatShape.new())
	var cam: FollowCamera = rig[0]
	cam.set_active(true)
	cam.right_drag = false
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	cam._unhandled_input(press)
	var drag := InputEventMouseMotion.new()
	drag.relative = Vector2(50.0, 0.0)
	drag.button_mask = MOUSE_BUTTON_MASK_RIGHT
	var before: float = cam._target_yaw
	cam._unhandled_input(drag)
	assert_almost(cam._target_yaw, before, 0.0001, "Sağ tuş nişansa kamera sürüklenmez")
	press.pressed = false
	cam._unhandled_input(press)
	var middle := InputEventMouseButton.new()
	middle.button_index = MOUSE_BUTTON_MIDDLE
	middle.pressed = true
	cam._unhandled_input(middle)
	drag.button_mask = MOUSE_BUTTON_MASK_MIDDLE
	cam._unhandled_input(drag)
	assert_ne(cam._target_yaw, before, "Orta tuşla sürükleme döndürür (K27)")
	_free_rig(rig)


func test_transform_filter_gets_the_last_word() -> void:
	var rig := await _make_rig(FlatShape.new())
	var cam: FollowCamera = rig[0]
	cam.set_active(true)
	cam.snap_to_target()
	var free_xform := cam.get_follow_transform()
	var seen := []
	cam.transform_filter = func(xform: Transform3D, focus: Vector3) -> Transform3D:
		seen.append(focus)
		return Transform3D(xform.basis, xform.origin + Vector3.UP)
	assert_vec_almost(cam.get_follow_transform().origin, free_xform.origin + Vector3.UP, 0.0001, "Süzgeç dönüşümü değiştirir")
	assert_eq(seen.size(), 1, "Odakla çağrılır")
	_free_rig(rig)


func test_yaw_turns_smoothly() -> void:
	var rig := await _make_rig(FlatShape.new())
	var cam: FollowCamera = rig[0]
	cam.add_yaw(1.0)
	cam.update_camera(DT)
	assert_between(cam.get_yaw(), 0.01, 0.9, "Dönüş yumuşak olmalı (bir karede bitmemeli)")
	for i in 120:
		cam.update_camera(DT)
	assert_almost(cam.get_yaw(), 1.0, 0.001, "Sonunda hedef açıya varmalı")
	_free_rig(rig)


func test_inactive_camera_leaves_the_camera_alone() -> void:
	var rig := await _make_rig(FlatShape.new())
	var cam: FollowCamera = rig[0]
	var target: Node3D = rig[1]
	cam.set_active(false)
	assert_false(cam.is_active())
	var before := cam.camera.global_transform
	target.position += Vector3(5.0, 0.0, 0.0)
	cam._process(0.5)
	assert_eq(cam.camera.global_transform, before, "Kapalıyken kameraya dokunmamalı")
	_free_rig(rig)


func test_default_view_is_the_far_high_frame() -> void:
	# K98: oyun içi her çekim uzak ve yüksek açılı; ufuk görünmez, yakın plan yok (referans: docs/media/review/kadraj_referans.webp).
	var cam := FollowCamera.new()
	assert_almost(cam.pitch_deg, 38.0, 0.0001)
	assert_almost(cam.fov, 36.0, 0.0001)
	assert_almost(cam.distance, 28.0, 0.0001)
	assert_almost(cam.min_distance, 14.0, 0.0001)
	assert_almost(cam.max_distance, 40.0, 0.0001)
	for d in [cam.min_distance, FollowCamera.CHILD_DISTANCE, cam.distance, cam.max_distance]:
		var pitch := FollowCamera.pitch_for_distance(d, cam.pitch_deg, cam.distance, cam.min_distance, cam.max_distance, cam.zoom_tilt_deg)
		assert_true(pitch >= cam.pitch_deg, "%.0f m: açı varsayılandan yatık olmamalı" % d)
		assert_true(pitch - cam.fov * 0.5 > 15.0, "%.0f m: karenin üst kenarı ufkun çok altında olmalı" % d)
	cam.free()


func test_people_read_at_the_size_of_the_reference_frame() -> void:
	# Kişinin kare yüksekliğindeki payı: boyu bakış açısıyla kısalır, kare kişinin uzaklığında 2·d·tan(fov/2) metre gösterir.
	var share := func(height: float, d: float) -> float:
		return height * cos(deg_to_rad(FollowCamera.DEFAULT_PITCH_DEG)) / (2.0 * d * tan(deg_to_rad(FollowCamera.DEFAULT_FOV) * 0.5))
	assert_between(share.call(1.72, FollowCamera.DEFAULT_DISTANCE) * 100.0, 7.0, 12.0, "Yetişkin varsayılan kadrajda %8–12 dolayında")
	assert_between(share.call(1.1, FollowCamera.CHILD_DISTANCE) * 1080.0, 60.0, 80.0, "Çocuk 1080p'de 60–80 piksel")
	assert_true(share.call(1.72, 14.0) < 0.2, "En yakında bile yakın plan değil: yetişkin karenin beşte birini geçmez")


func test_start_distance_moves_the_camera_and_stays_in_the_limits() -> void:
	var rig := await _make_rig(FlatShape.new())
	var cam: FollowCamera = rig[0]
	var target: Node3D = rig[1]
	cam.set_start_distance(FollowCamera.CHILD_DISTANCE)
	assert_almost(cam.get_target_distance(), 22.0, 0.0001)
	assert_almost(cam.distance, 22.0, 0.0001)
	cam.snap_to_target()
	var focus := target.position + Vector3(0.0, cam.look_height, 0.0)
	assert_almost(cam.camera.global_position.distance_to(focus), 22.0, 0.01, "Kamera yeni uzaklıkta")
	assert_almost(cam.current_pitch(), cam.pitch_deg, 0.0001, "Başlangıç uzaklığında açı değişmez")
	cam.zoom_by(-100.0)
	for i in 120:
		cam.update_camera(DT)
	assert_almost(cam.current_pitch(), cam.pitch_deg, 0.0001, "En yakında da yatıklaşmaz")
	cam.set_start_distance(2.0)
	assert_almost(cam.get_target_distance(), cam.min_distance, 0.0001, "Sınırın altına inmez")
	cam.set_start_distance(100.0)
	assert_almost(cam.get_target_distance(), cam.max_distance, 0.0001, "Sınırın üstüne çıkmaz")
	_free_rig(rig)


func test_activation_blends_from_the_previous_camera() -> void:
	var rig := await _make_rig(FlatShape.new())
	var cam: FollowCamera = rig[0]
	cam.set_active(false)
	var menu := Camera3D.new()
	menu.fov = 45.0
	add_child(menu)
	menu.global_transform = Transform3D(Basis.IDENTITY, Vector3(0.3, 3.6, 11.0))
	menu.make_current()
	cam.activation_blend = 1.0
	cam.set_active(true)
	assert_true(cam.camera.current, "Takip kamerası etkin olmalı")
	cam.update_camera(0.1)
	var mid := cam.camera.global_position
	assert_true(mid.distance_to(Vector3(0.3, 3.6, 11.0)) < 3.0, "Geçiş menü kamerasının yanından başlamalı: %s" % mid)
	assert_between(cam.camera.fov, FollowCamera.DEFAULT_FOV, 45.0)
	for i in 120:
		cam.update_camera(DT)
	assert_vec_almost(cam.camera.global_position, cam.get_follow_transform().origin, 0.001, "Geçiş bitince takip konumunda")
	assert_almost(cam.camera.fov, FollowCamera.DEFAULT_FOV, 0.001)
	menu.queue_free()
	_free_rig(rig)


func test_vertical_fov_converts_keep_width_cameras() -> void:
	assert_almost(FollowCamera.vertical_fov(40.0, Camera3D.KEEP_HEIGHT, 1.6), 40.0, 0.0001, "KEEP_HEIGHT zaten dikey")
	# 16:9 için tasarlanmış 32.5° dikey açının yatay karşılığı (dar ekranda menü kamerası bunu korur).
	var horizontal := rad_to_deg(2.0 * atan(tan(deg_to_rad(32.5) * 0.5) * 16.0 / 9.0))
	assert_almost(FollowCamera.vertical_fov(horizontal, Camera3D.KEEP_WIDTH, 16.0 / 9.0), 32.5, 0.001, "Yatay → dikey")
	assert_true(FollowCamera.vertical_fov(horizontal, Camera3D.KEEP_WIDTH, 1.6) > 32.5, "Dar ekranda dikey açı büyür")


func test_activation_from_a_keep_width_camera_does_not_jump() -> void:
	# 16:10 ekran (ör. MacBook): menü kamerası yatay açıyı korur (KEEP_WIDTH, fov = yatay açı).
	# Başsız çalışmada kök pencere kare olduğundan sahne bilinen boyutlu bir SubViewport'ta kurulur.
	var screen := SubViewport.new()
	screen.size = Vector2i(1600, 1000)
	add_child(screen)
	var target := Node3D.new()
	target.position = Vector3(0.0, 0.0, 4.0)
	screen.add_child(target)
	var menu := Camera3D.new()
	menu.keep_aspect = Camera3D.KEEP_WIDTH
	menu.fov = 54.8
	screen.add_child(menu)
	menu.global_transform = Transform3D(Basis.IDENTITY, Vector3(0.3, 3.6, 11.0))
	menu.make_current()
	var cam := FollowCamera.new()
	cam.start_active = false
	cam.terrain_shape = FlatShape.new()
	cam.target = target
	cam.activation_blend = 1.0
	cam.add_child(Camera3D.new())
	screen.add_child(cam)
	cam.set_process(false)
	await wait_frames(1)
	cam.set_active(true)
	cam.update_camera(0.0001)
	var on_screen := rad_to_deg(2.0 * atan(tan(deg_to_rad(54.8) * 0.5) / 1.6))
	assert_eq(cam.camera.keep_aspect, Camera3D.KEEP_HEIGHT, "Takip kamerası dikey açıyla çalışmalı")
	assert_almost(cam.camera.fov, on_screen, 0.05, "Geçiş, menü kamerasının ekrandaki (dikey) açısından başlamalı")
	screen.queue_free()


func test_freed_target_is_ignored_safely() -> void:
	var rig := await _make_rig(FlatShape.new())
	var cam: FollowCamera = rig[0]
	var target: Node3D = rig[1]
	var before := cam.camera.global_transform
	target.free()
	cam._process(DT)
	cam.update_camera(DT)
	cam.snap_to_target()
	assert_eq(cam.camera.global_transform, before, "Hedef silinince kamera yerinde kalmalı (hata vermeden)")
	cam.queue_free()


func test_occluders_receive_the_line_of_sight_every_update() -> void:
	var rig := await _make_rig(FlatShape.new())
	var cam: FollowCamera = rig[0]
	var target: Node3D = rig[1]
	var spy := OccluderSpy.new()
	spy.add_to_group(FollowCamera.OCCLUDER_GROUP)
	add_child(spy)
	cam.update_camera(DT)
	assert_eq(spy.calls, 1, "Her güncellemede örten nesnelere bildirilmeli")
	assert_vec_almost(spy.last_from, cam.camera.global_position, 0.0001, "Görüş hattı kameradan başlamalı")
	assert_vec_almost(spy.last_to, target.position + Vector3(0.0, cam.look_height, 0.0), 0.0001, "Karakterin göğsünde bitmeli")
	spy.queue_free()
	_free_rig(rig)


func test_creates_a_camera_child_when_none_is_given() -> void:
	var cam := FollowCamera.new()
	cam.start_active = false
	add_child(cam)
	assert_not_null(cam.camera, "Kamera yoksa oluşturulmalı")
	assert_eq(cam.camera.get_parent(), cam)
	cam.queue_free()


# --- Eğim bandı (K39, godot.md §5.1) --------------------------------------------------------------

func test_pitch_band_is_15_to_60_and_slows_in_the_last_four_degrees() -> void:
	assert_eq(FollowCamera.PITCH_MIN, 15.0)
	assert_eq(FollowCamera.PITCH_MAX, 60.0)
	assert_almost(FollowCamera.compose_pitch(38.0, -40.0), 15.0, 0.0001, "Alt sınır")
	assert_almost(FollowCamera.compose_pitch(44.0, 30.0), 60.0, 0.0001, "Üst sınır")
	assert_almost(FollowCamera.compose_pitch(38.0, 4.0), 42.0, 0.0001)
	assert_almost(FollowCamera.compose_pitch(13.0, 0.0, 13.0, 60.0), 13.0, 0.0001, "Ufuk istisnası kendi eğiminde (Tengri 13°)")
	assert_almost(FollowCamera.soft_pitch_step(40.0, 2.0), 2.0, 0.0001, "Bandın ortasında tam hız")
	assert_almost(FollowCamera.soft_pitch_step(57.0, 2.0), 0.6, 0.0001, "Son 4°'de sınıra doğru ×0,3")
	assert_almost(FollowCamera.soft_pitch_step(57.0, -2.0), -2.0, 0.0001, "Sınırdan uzaklaşırken tam hız")
	assert_almost(FollowCamera.soft_pitch_step(17.0, -2.0), -0.6, 0.0001, "Alt sınırda da yavaşlar")
	var rig := await _make_rig(FlatShape.new())
	var cam: FollowCamera = rig[0]
	for i in 400:
		cam.add_pitch(1.0)
	_settle(cam)
	assert_almost(cam.current_pitch(), 60.0, 0.001, "Yükselte yükselte 60°'de durur")
	for i in 400:
		cam.add_pitch(-1.0)
	_settle(cam)
	assert_almost(cam.current_pitch(), 15.0, 0.001, "Alçalta alçalta 15°'de durur")
	cam.add_pitch(2.0)
	_settle(cam)
	assert_almost(cam.current_pitch(), 17.0, 0.001, "Sınırdan uzaklaşırken tam hız")
	cam.zoom_by(100.0)
	_settle(cam)
	assert_almost(cam.current_pitch(), 23.0, 0.001, "Uzaklaşınca uzaklığın eğimi (+6°) oturum payının üstüne eklenir")
	# Üst sınırda ölü bölge yok: 60°'deyken uzaklaşınca pay kırpılır, aşağı eğmek hemen işler.
	cam.zoom_by(-12.0)
	for i in 400:
		cam.add_pitch(1.0)
	_settle(cam)
	assert_almost(cam.current_pitch(), 60.0, 0.001)
	cam.zoom_by(100.0)
	_settle(cam)
	assert_almost(cam.current_pitch(), 60.0, 0.001, "En uzakta da 60°")
	cam.add_pitch(-2.0)
	_settle(cam)
	assert_almost(cam.current_pitch(), 58.0, 0.001, "Sınırda bekleme yok: −2° hemen")
	_free_rig(rig)


func test_setting_bias_is_the_players_default_and_stays_in_the_k98_family() -> void:
	var rig := await _make_rig(FlatShape.new())
	var cam: FollowCamera = rig[0]
	cam.pitch_bias = 6.0
	_settle(cam)
	assert_almost(cam.current_pitch(), 44.0, 0.001, "Ayarın payı varsayılan kareye eklenir")
	cam.add_pitch(-10.0)
	_settle(cam)
	assert_almost(cam.current_pitch(), 34.0, 0.001, "Oturum payı onun üstüne")
	cam.reset_view()
	_settle(cam)
	assert_almost(cam.current_pitch(), 44.0, 0.001, "`/` ayarın payını silmez")
	# K98: varsayılan kare (38° + ayarın payı) her uçta 35–50°'de kalır.
	var script := preload("res://scripts/settings/game_settings.gd")
	for bias in [script.PITCH_BIAS_MIN, script.PITCH_BIAS_MAX]:
		assert_between(FollowCamera.DEFAULT_PITCH_DEG + bias, 35.0, 50.0, "Ayarın payı %+.0f° K98'in ailesinde" % bias)
	_free_rig(rig)


func test_reset_key_returns_to_north_session_zero_and_start_distance_in_half_a_second() -> void:
	var rig := await _make_rig(FlatShape.new())
	var cam: FollowCamera = rig[0]
	cam.add_yaw(2.0)
	cam.add_pitch(12.0)
	cam.zoom_by(9.0)
	_settle(cam)
	assert_almost(cam.get_target_distance(), 37.0, 0.0001)
	cam._unhandled_input(_key(KEY_SLASH))
	assert_true(cam.is_resetting(), "`/` (camera_reset) varsayılana dönüşü başlatır")
	for i in 15:
		cam.update_camera(DT)
	assert_true(cam.is_resetting(), "0,25 sn'de dönüş sürer")
	assert_between(cam.get_yaw(), 0.05, 1.95, "Açı yolun ortasında")
	for i in 16:
		cam.update_camera(DT)
	assert_false(cam.is_resetting(), "0,5 sn'de biter")
	assert_almost(cam.get_yaw(), 0.0, 0.0001, "Kuzey")
	assert_almost(cam.get_session_pitch(), 0.0, 0.0001, "Oturum eğimi 0")
	assert_almost(cam.get_target_distance(), FollowCamera.DEFAULT_DISTANCE, 0.0001, "28 m")
	assert_almost(cam.current_pitch(), FollowCamera.DEFAULT_PITCH_DEG, 0.0001, "38°")
	# Çocukta başlangıç uzaklığı 22 m'dir.
	cam.set_start_distance(FollowCamera.CHILD_DISTANCE)
	cam.zoom_by(10.0)
	cam.reset_view()
	for i in 40:
		cam.update_camera(DT)
	assert_almost(cam.get_target_distance(), FollowCamera.CHILD_DISTANCE, 0.0001, "Çocukta 22 m")
	# Dönüş sürerken gelen girdi dönüşü bırakır: oyuncunun eli kazanır.
	cam.add_yaw(1.0)
	cam.reset_view()
	cam.update_camera(DT)
	cam.add_yaw(0.5)
	assert_false(cam.is_resetting(), "Girdi dönüşü keser")
	_free_rig(rig)


func test_middle_click_aligns_north_and_middle_drag_locks_to_the_dominant_axis() -> void:
	var rig := await _make_rig(FlatShape.new())
	var cam: FollowCamera = rig[0]
	cam.set_yaw(1.2, true)
	cam._unhandled_input(_mouse(MOUSE_BUTTON_MIDDLE, true))
	cam._unhandled_input(_motion(Vector2(4.0, 3.0), MOUSE_BUTTON_MASK_MIDDLE))
	cam._unhandled_input(_mouse(MOUSE_BUTTON_MIDDLE, false))
	_settle(cam)
	assert_almost(cam.get_yaw(), 0.0, 0.001, "Sürüklemesiz orta tık kuzeye hizalar (K27)")
	assert_almost(cam.current_pitch(), 38.0, 0.0001, "Eğime dokunmaz")
	# Yatay sürükleme: 12 pikselde yataya kilitlenir, dikey kıpırtı eğmez.
	cam._unhandled_input(_mouse(MOUSE_BUTTON_MIDDLE, true))
	for i in 10:
		cam._unhandled_input(_motion(Vector2(10.0, 2.0), MOUSE_BUTTON_MASK_MIDDLE))
	_settle(cam)
	assert_almost(rad_to_deg(cam.get_yaw()), -100.0 * cam.mouse_sensitivity, 0.05, "Yatay sürükleme döndürür (biriken de sayılır)")
	assert_almost(cam.current_pitch(), 38.0, 0.0001, "Yataya kilitliyken eğilmez")
	cam._unhandled_input(_mouse(MOUSE_BUTTON_MIDDLE, false))
	# Dikey sürükleme: 0,15°/px; fareyi aşağı çekmek kamerayı yükseltir.
	var yaw := cam.get_yaw()
	cam._unhandled_input(_mouse(MOUSE_BUTTON_MIDDLE, true))
	for i in 10:
		cam._unhandled_input(_motion(Vector2(1.0, 8.0), MOUSE_BUTTON_MASK_MIDDLE))
	cam._unhandled_input(_mouse(MOUSE_BUTTON_MIDDLE, false))
	_settle(cam)
	assert_almost(cam.current_pitch(), 38.0 + 80.0 * FollowCamera.PITCH_DRAG_DEG, 0.001, "Dikey sürükleme eğer (80 px × 0,15°)")
	assert_almost(cam.get_yaw(), yaw, 0.0001, "Dikeye kilitliyken dönmez")
	# Ters dikey: aynı sürükleme alçaltır.
	cam.invert_y = true
	cam._unhandled_input(_mouse(MOUSE_BUTTON_MIDDLE, true))
	for i in 10:
		cam._unhandled_input(_motion(Vector2(0.0, 8.0), MOUSE_BUTTON_MASK_MIDDLE))
	cam._unhandled_input(_mouse(MOUSE_BUTTON_MIDDLE, false))
	_settle(cam)
	assert_almost(cam.current_pitch(), 38.0, 0.001, "Ters dikeyde yön değişir")
	_free_rig(rig)


func test_child_aims_with_the_right_button_and_tilts_only_with_the_middle_button() -> void:
	# Çocuk denetleyicisi: sağ tuş nişandır (right_drag kapalı); orta tuş döndürür ve eğer. Eğim girdisi nişanla çakışmaz.
	var rig := await _make_rig(FlatShape.new())
	var cam: FollowCamera = rig[0]
	cam.right_drag = false
	cam._unhandled_input(_mouse(MOUSE_BUTTON_RIGHT, true))
	for i in 10:
		cam._unhandled_input(_motion(Vector2(6.0, 9.0), MOUSE_BUTTON_MASK_RIGHT))
	cam._unhandled_input(_mouse(MOUSE_BUTTON_RIGHT, false))
	_settle(cam)
	assert_almost(cam.get_yaw(), 0.0, 0.0001, "Sağ tuşla nişan kamerayı döndürmez")
	assert_almost(cam.current_pitch(), 38.0, 0.0001, "Sağ tuşla nişan kamerayı eğmez")
	cam._unhandled_input(_mouse(MOUSE_BUTTON_MIDDLE, true))
	for i in 10:
		cam._unhandled_input(_motion(Vector2(0.0, -6.0), MOUSE_BUTTON_MASK_MIDDLE | MOUSE_BUTTON_MASK_RIGHT))
	cam._unhandled_input(_mouse(MOUSE_BUTTON_MIDDLE, false))
	_settle(cam)
	assert_almost(cam.current_pitch(), 38.0 - 60.0 * FollowCamera.PITCH_DRAG_DEG, 0.001, "Nişan alırken de orta tuş eğer")
	_free_rig(rig)


func test_alt_wheel_tilts_shift_wheel_turns_and_the_plain_wheel_zooms() -> void:
	var rig := await _make_rig(FlatShape.new())
	var cam: FollowCamera = rig[0]
	var up := _mouse(MOUSE_BUTTON_WHEEL_UP, true)
	up.alt_pressed = true
	cam._unhandled_input(up)
	cam._unhandled_input(up)
	_settle(cam)
	assert_almost(cam.current_pitch(), 38.0 - 2.0 * FollowCamera.PITCH_WHEEL_DEG, 0.001, "Alt + tekerlek: çentik başına 2°")
	assert_almost(cam.get_target_distance(), cam.distance, 0.0001, "Alt + tekerlek yakınlaştırmaz")
	var shift := _mouse(MOUSE_BUTTON_WHEEL_DOWN, true)
	shift.shift_pressed = true
	cam._unhandled_input(shift)
	_settle(cam)
	assert_almost(rad_to_deg(cam.get_yaw()), -FollowCamera.YAW_WHEEL_DEG, 0.01, "Shift + tekerlek döndürür (K27)")
	cam._unhandled_input(_mouse(MOUSE_BUTTON_WHEEL_RIGHT, true))
	_settle(cam)
	assert_almost(rad_to_deg(cam.get_yaw()), -2.0 * FollowCamera.YAW_WHEEL_DEG, 0.01, "Yatay kaydırma döndürür")
	cam._unhandled_input(_mouse(MOUSE_BUTTON_WHEEL_DOWN, true))
	assert_almost(cam.get_target_distance(), cam.distance + cam.zoom_step, 0.0001, "Düz tekerlek uzaklaştırır")
	_free_rig(rig)


func test_keys_tilt_at_40_degrees_per_second_and_zoom() -> void:
	var rig := await _make_rig(FlatShape.new())
	var cam: FollowCamera = rig[0]
	cam.set_active(true)
	Input.action_press(&"camera_pitch_up")
	for i in 15:
		cam._process(DT)
	Input.action_release(&"camera_pitch_up")
	_settle(cam)
	assert_almost(cam.current_pitch(), 38.0 + 0.25 * FollowCamera.PITCH_KEY_SPEED, 0.05, "; basılıyken 0,25 sn: +10°")
	Input.action_press(&"camera_zoom_in")
	for i in 30:
		cam._process(DT)
	Input.action_release(&"camera_zoom_in")
	assert_almost(cam.get_target_distance(), cam.distance - 0.5 * FollowCamera.KEY_ZOOM_SPEED, 0.05, "- basılıyken yaklaşır")
	_free_rig(rig)


func test_tilt_setting_off_ignores_every_tilt_input() -> void:
	var rig := await _make_rig(FlatShape.new())
	var cam: FollowCamera = rig[0]
	cam.set_active(true)
	cam.tilt_enabled = false
	cam.pitch_bias = 3.0
	cam._unhandled_input(_mouse(MOUSE_BUTTON_MIDDLE, true))
	for i in 10:
		cam._unhandled_input(_motion(Vector2(0.0, 8.0), MOUSE_BUTTON_MASK_MIDDLE))
	cam._unhandled_input(_mouse(MOUSE_BUTTON_MIDDLE, false))
	var alt := _mouse(MOUSE_BUTTON_WHEEL_UP, true)
	alt.alt_pressed = true
	cam._unhandled_input(alt)
	Input.action_press(&"camera_pitch_down")
	cam._process(0.5)
	Input.action_release(&"camera_pitch_down")
	_settle(cam)
	assert_almost(cam.current_pitch(), 41.0, 0.001, "«Oyunda eğim» kapalı: girdiler eğmez, ayarın payı kalır")
	_free_rig(rig)


func test_session_resets_when_the_camera_leaves_play() -> void:
	# K27: açı ve oturum eğimi kaydedilmez, menüye dönüşte sıfırlanır; Serbest Gez her oturumda kuzeye bakarak açılır.
	var rig := await _make_rig(FlatShape.new())
	var cam: FollowCamera = rig[0]
	cam.add_yaw(1.5)
	cam.add_pitch(9.0)
	cam.zoom_by(-6.0)
	_settle(cam)
	cam.set_active(false)
	cam.set_active(true)
	cam.snap_to_target()
	assert_almost(cam.get_yaw(), 0.0, 0.0001, "Kuzey")
	assert_almost(cam.get_session_pitch(), 0.0, 0.0001, "Oturum eğimi sıfır")
	assert_almost(cam.get_target_distance(), FollowCamera.DEFAULT_DISTANCE, 0.0001, "Başlangıç uzaklığı")
	_free_rig(rig)


# --- Ön ayarlar (godot.md §5.7; K98 kadrajıyla act1.md §4) ------------------------------------------

func test_presets_are_built_from_the_godot_base() -> void:
	var ids := CameraPreset.all().map(func(p: CameraPreset) -> StringName: return p.id)
	assert_eq(ids, [&"walk", &"ride", &"crouch", &"room", &"lookout", &"tengri"])
	for p: CameraPreset in CameraPreset.all():
		assert_almost(p.blend, 1.1, 0.0001, "%s 1,1 sn'de karışır" % p.id)
		if p.id in [&"lookout", &"tengri"]:
			assert_true(p.pitch_deg < 18.0 and p.distance >= 40.0, "%s K98'in ufuk istisnası: eğim düşer, uzaklık ≥40 m" % p.id)
			assert_true(p.holds_bias, "Sahne çekimi oyuncunun payını bekletir")
		else:
			assert_between(p.pitch_deg, 35.0, 50.0, "%s K98'in 35–50° ailesinde" % p.id)
	assert_almost(CameraPreset.walk().distance, 28.0, 0.0001)
	assert_almost(CameraPreset.walk(true).distance, 22.0, 0.0001)


func test_riding_a_horse_switches_to_the_ride_preset_and_back() -> void:
	var rig := await _make_rig(FlatShape.new(), RiderProbe.new())
	var cam: FollowCamera = rig[0]
	var rider: RiderProbe = rig[1]
	assert_eq(cam.get_preset_id(), &"walk")
	rider.riding = true
	rider.kind = "sheep"
	cam.update_camera(DT)
	assert_eq(cam.get_preset_id(), &"walk", "Koyunda yürüyüş kalır (çocuğun kadrajı)")
	rider.kind = "horse"
	cam.update_camera(DT)
	assert_eq(cam.get_preset_id(), &"ride", "Atta Sürüş")
	assert_almost(cam.get_target_distance(), 34.0, 0.0001, "Yürüyüşün 6 m ötesi: 34 m")
	var heights := []
	for i in 90:
		cam.update_camera(DT)
		heights.append(cam.camera.global_position.y)
	assert_true(heights[10] < heights[89] - 1.0, "1,1 sn'de yumuşakça açılır")
	assert_almost(cam.current_pitch(), 38.0, 0.01, "Eğim ailede kalır")
	cam.zoom_by(2.0)
	rider.riding = false
	cam.update_camera(DT)
	assert_eq(cam.get_preset_id(), &"walk")
	assert_almost(cam.get_target_distance(), 30.0, 0.0001, "İnince tekerlek payı korunur (28 + 2)")
	# Ata binmişken açılan kamera (ör. Serbest Gez yüklenince) hemen Sürüş'te oturur: kamera sarsılmaz.
	rider.riding = true
	cam.set_active(false)
	cam.set_active(true)
	cam.snap_to_target()
	assert_almost(cam.get_target_distance(), 34.0, 0.0001)
	var y := cam.camera.global_position.y
	for i in 60:
		cam.update_camera(DT)
	assert_almost(cam.camera.global_position.y, y, 0.01, "Sürüş hemen oturdu")
	_free_rig(rig)


func test_room_and_scene_presets_hold_the_players_bias() -> void:
	var rig := await _make_rig(FlatShape.new())
	var cam: FollowCamera = rig[0]
	cam.pitch_bias = 4.0
	cam.add_pitch(-8.0)
	cam.set_yaw(1.3, true)
	_settle(cam)
	assert_almost(cam.current_pitch(), 34.0, 0.001)
	cam.apply_preset(CameraPreset.room(), true)
	_settle(cam)
	assert_almost(cam.current_pitch(), 50.0, 0.001, "Oda 50°: payı bekletir (K27)")
	assert_almost(cam.get_yaw(), 0.0, 0.001, "Odada kuzeye döner (K27)")
	assert_almost(cam.get_target_distance(), 28.0, 0.0001, "Oyuncunun uzaklığı kalır")
	cam.add_pitch(5.0)
	_settle(cam)
	assert_almost(cam.current_pitch(), 50.0, 0.001, "Odada eğim girdisi yok")
	cam.apply_preset(CameraPreset.tengri(), true)
	_settle(cam)
	assert_almost(cam.current_pitch(), 13.0, 0.001, "Tengri 13°: bandın altı (ufuk istisnası)")
	assert_almost(cam.get_target_distance(), 70.0, 0.0001, "70 m, sınırın dışında")
	cam.zoom_by(-5.0)
	cam.reset_view()
	_settle(cam)
	assert_almost(cam.get_target_distance(), 70.0, 0.0001, "Sahne çekiminde tekerlek ve `/` bekler")
	cam.clear_preset()
	for i in 200:
		cam.update_camera(DT)
	assert_almost(cam.get_target_distance(), 23.0, 0.0001, "Sahne bitince oyuncunun uzaklığı (bekleyen tekerlekle)")
	assert_almost(cam.current_pitch(), 34.0, 0.001, "Oyuncunun payı geri gelir")
	assert_almost(cam.get_yaw(), 1.3, 0.001, "Oyuncunun açısı geri gelir")
	_free_rig(rig)


func test_crouch_frames_the_sentrys_16_m_circle() -> void:
	# k98-recalc (3): nöbetçinin 16 m'lik görüş çemberi %5 payla kadrajdadır (kenarlarda %2,5). K98 kadrajında 40 m'de bile güneye
	# 13,6 m görünür; Çömelme en az 34 m'ye açılır (eğim 41°) ve bakılan noktayı 4,7 m kameraya doğru kaydırır.
	var crouch := CameraPreset.crouch()
	var pitch := FollowCamera.pitch_for_distance(crouch.distance, 38.0, 28.0, 14.0, 40.0, 6.0)
	assert_almost(pitch, 41.0, 0.0001)
	for yaw in [0.0, 1.1, -2.3]:
		var feet := Vector3(5.0, 0.0, -3.0)
		var forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
		var xform := FollowCamera.compute_transform(feet + Vector3.UP * 0.7 + forward * crouch.lead, yaw, pitch, crouch.distance)
		var cam := _frame_camera(xform, FollowCamera.DEFAULT_FOV)
		for i in 72:
			var a := TAU * i / 72.0
			for h in [0.0, 1.2]:
				var p := feet + Vector3(sin(a) * 16.0, h, cos(a) * 16.0)
				assert_true(_on_screen(cam, p, 0.025), "Çemberin noktası kadrajda (yaw %.1f, %d°, %.1f m)" % [yaw, i * 5, h])
		cam.get_parent().queue_free()
	# Payın olmadığı 40 m'lik en uzak kadraj çemberi tutamaz (eski kural neden yeniden kuruldu).
	var far := FollowCamera.ground_reach(44.0, 40.0, FollowCamera.DEFAULT_FOV)
	assert_almost(float(far["south"]), 13.6, 0.05, "40 m'de güneye 13,6 m")
	var rig := await _make_rig(FlatShape.new())
	var follow: FollowCamera = rig[0]
	follow.zoom_by(-6.0)
	follow.apply_preset(crouch, true)
	assert_almost(follow.get_target_distance(), 34.0, 0.0001, "Uzaklık en az 34 m")
	follow.reset_view()
	_settle(follow)
	assert_almost(follow.get_target_distance(), 34.0, 0.0001, "Çömelmede `/` 34 m'nin altına inmez")
	follow.clear_preset()
	assert_almost(follow.get_target_distance(), 22.0, 0.0001, "Kalkınca oyuncunun uzaklığı geri gelir")
	_free_rig(rig)


# --- K98 kadrajının sayıları (act1.md §4, §10; army.md §4.3; companions.md §7.3) --------------------------

func test_k98_frame_reach_matches_the_design_numbers() -> void:
	var walk := FollowCamera.ground_reach(38.0, 28.0, 36.0)
	assert_almost(float(walk["north"]), 27.2, 0.05, "Kuzeye 27,2 m")
	assert_almost(float(walk["south"]), 10.0, 0.05, "Güneye 10,0 m")
	assert_almost(float(walk["side"]), 16.4, 0.05, "Kahraman hizasında ±16,4 m")
	var far := FollowCamera.ground_reach(44.0, 40.0, 36.0)
	assert_almost(float(far["north"]), 29.6, 0.05)
	assert_almost(float(far["side"]), 23.4, 0.05)
	var ride := FollowCamera.ground_reach(38.0, 34.0, 36.0)
	assert_almost(float(ride["north"]), 32.6, 0.05, "Sürüş: kuzeye 32,6 m")
	assert_almost(float(ride["south"]), 12.2, 0.05, "Sürüş: güneye 12,2 m")
	assert_almost(float(ride["side"]), 19.9, 0.05)
	var gallop := FollowCamera.ground_reach(38.0, 34.0, 36.0 + FollowCamera.SPEED_WIDEN_DEG)
	assert_almost(float(gallop["north"]), 36.9, 0.05, "Dörtnalda kuzeye 36,9 m")
	assert_almost(float(gallop["south"]), 12.9, 0.05)
	var old := FollowCamera.ground_reach(23.35, 27.0, 41.76)
	assert_almost(float(old["north"]), 239.5, 0.5, "K98'den önce kuzeye ≈240 m")
	var crouch := FollowCamera.ground_reach(41.0, 34.0, 36.0, 16.0 / 9.0, 0.7, -4.7)
	assert_almost(float(crouch["south"]), 16.5, 0.05, "Çömelme: güneye 16,5 m")
	assert_almost(float(crouch["north"]), 23.8, 0.05)


func test_ride_preset_keeps_the_galloping_wedge_and_flank_rider_in_frame() -> void:
	# army.md §4.3 (9): Mete C sırasındayken dörtnalda (×1,25) arka sıra 10,5 m geride, sancağın atı 12,0 m'ye uzanır.
	# Yürüyüş kadrajında (28 m) sancağın ayakları kenardadır; Sürüş'te (34 m) at %4 iç payla kadrajdadır.
	var walk := _frame_camera(FollowCamera.compute_transform(Vector3(0.0, 0.7, 0.0), 0.0, 38.0, 28.0), 36.0)
	assert_false(_on_screen(walk, Vector3(0.0, 0.0, 10.5), 0.04), "28 m: sancağın ayakları %4 payın dışında")
	var ride := _frame_camera(FollowCamera.compute_transform(Vector3(0.0, 0.7, 0.0), 0.0, 38.0, 34.0), 36.0)
	for slot in [Vector3(4.8, 0.0, 5.25), Vector3(-4.8, 0.0, 5.25), Vector3(0.0, 0.0, 10.5)]:
		assert_true(_on_screen(ride, slot, 0.04), "Sürüş: kamanın arka sırası %%4 iç payla kadrajda %s" % slot)
	assert_true(_on_screen(ride, Vector3(0.0, 0.0, 12.03), 0.0), "Sürüş: sancağın atı (12,0 m) kadrajda")
	# act1.md §10 (10): FLANK bandı ±10–13,5 m: 2 m geride bile atlının göğsü (2,3 m) %5 paylı kadrajda; ±16 m kenara dayanıyordu.
	for side in [-1.0, 1.0]:
		for back in [0.0, 2.0]:
			assert_true(_on_screen(walk, Vector3(side * 13.5, 2.3, back), 0.025), "FLANK 13,5 m kadrajda")
		assert_false(_on_screen(walk, Vector3(side * 16.0, 2.3, 2.0), 0.025), "16 m kadrajın kenarında, %5 payın dışında")
	walk.get_parent().queue_free()
	ride.get_parent().queue_free()


func test_edge_cards_at_the_nearest_14_m_frame() -> void:
	# companions.md §7.3 (8): kart, göğüs noktası (yaya 1,2 m, atlı 2,3 m) ekranın %4 içindeki dikdörtgenin dışındayken çıkar.
	# 14 m'de: yayada gevşek düzen (army.md §4.1) hep kadrajda; atlı kamada 2 kart (dörtnalda 4); varsayılan 28 m'de ikisi de kartsız.
	var loose := [Vector2(1.01, -2.18), Vector2(-1.01, -2.18), Vector2(2.32, -0.62), Vector2(-2.32, -0.62), Vector2(1.09, -4.06),
		Vector2(-1.09, -4.06), Vector2(2.97, -2.97), Vector2(-2.97, -2.97), Vector2(4.06, -1.09), Vector2(-4.06, -1.09)]
	var wedge := [Vector2(0.0, 8.4), Vector2(1.6, 4.2), Vector2(-1.6, 4.2), Vector2(3.2, 0.0), Vector2(-3.2, 0.0), Vector2(4.8, -4.2),
		Vector2(1.6, -4.2), Vector2(-1.6, -4.2), Vector2(-4.8, -4.2), Vector2(0.0, -8.4)]
	var near := _frame_camera(FollowCamera.compute_transform(Vector3(0.0, 0.7, 0.0), 0.0, 38.0, 14.0), 36.0)
	var default := _frame_camera(FollowCamera.compute_transform(Vector3(0.0, 0.7, 0.0), 0.0, 38.0, 28.0), 36.0)
	assert_eq(_cards(near, loose, 1.2, 1.0), 0, "14 m: yaya partide kart yok")
	assert_eq(_cards(near, wedge, 2.3, 1.0), 2, "14 m: atlı kamada 2 kart")
	assert_eq(_cards(near, wedge, 2.3, 1.25), 4, "14 m: dörtnalda 4 kart")
	assert_eq(_cards(default, loose, 1.2, 1.0), 0)
	assert_eq(_cards(default, wedge, 2.3, 1.25), 0, "28 m: dörtnalda da kartsız (göğüsler kadrajda)")
	near.get_parent().queue_free()
	default.get_parent().queue_free()


# --- Ses dinleyicisi (K39, godot.md §5.5, audio.md §1) ------------------------------------------------

func test_listener_sits_above_the_player_and_faces_the_camera_yaw() -> void:
	var rig := await _make_rig(FlatShape.new())
	var cam: FollowCamera = rig[0]
	var target: Node3D = rig[1]
	var listener := cam.get_listener()
	assert_not_null(listener, "Takip kamerası ekrandayken dinleyici vardır")
	assert_true(listener.is_current(), "Dinleyici oyuncuda (kamera değil)")
	assert_vec_almost(listener.global_position, target.global_position + Vector3.UP * 1.5, 0.001, "Ayağın 1,5 m üstü")
	cam.add_yaw(1.0)
	target.position += Vector3(3.0, 0.0, -2.0)
	for i in 120:
		cam.update_camera(DT)
	assert_vec_almost(listener.global_position, target.global_position + Vector3.UP * 1.5, 0.001, "Oyuncuyu gecikmesiz izler")
	assert_almost(PlayerController.yaw_from_basis(listener.global_basis), cam.get_yaw(), 0.001, "Yönü kameranın yatay açısı")
	assert_almost(listener.global_basis.z.y, 0.0, 0.0001, "Eğilmez: yalnız yatay açı")
	_free_rig(rig)


func test_listener_returns_to_the_camera_in_menu_and_cinema() -> void:
	var rig := await _make_rig(FlatShape.new())
	var cam: FollowCamera = rig[0]
	var listener := cam.get_listener()
	# Sinema: başka bir kamera ekrana gelir, takip açık kalsa da dinleyici o kameraya kayar ve bırakılır.
	var cine := Camera3D.new()
	add_child(cine)
	cine.global_position = Vector3(30.0, 20.0, 30.0)
	cine.make_current()
	cam.update_camera(DT)
	assert_true(listener.is_current(), "Bırakılırken kayar (sıçramaz)")
	for i in int(cam.activation_blend / DT) + 2:
		cam.update_camera(DT)
	assert_false(listener.is_current(), "Sinemada dinleyici kameradır")
	# Takip kamerası geri gelince dinleyici yine oyuncuda.
	cam.camera.make_current()
	cam.update_camera(DT)
	assert_true(listener.is_current())
	# Menü: takip kapanır.
	cam.set_active(false)
	for i in int(cam.activation_blend / DT) + 2:
		cam._process(DT)
	assert_false(listener.is_current(), "Menüde dinleyici kameradır")
	cine.queue_free()
	_free_rig(rig)


func test_fire_beside_the_player_stays_within_1_5_db_from_14_to_40_m() -> void:
	# audio.md §1 kabulü: kamera 14 m'den 40 m'ye giderken oyuncunun yanındaki ateş ±1,5 dB içinde kalır. Düzey Godot 4'ün
	# AudioStreamPlayer3D hesabıyla (ters uzaklık, max_db, max_distance'ın doğrusal sönümü) ve kampın gerçek ateşinin sesiyle ölçülür.
	var rig := await _make_rig(FlatShape.new())
	var cam: FollowCamera = rig[0]
	var target: Node3D = rig[1]
	var fire := Campfire.new()
	add_child(fire)
	fire.global_position = target.global_position + Vector3(2.0, 0.0, 0.5)
	await wait_frames(1)
	var crackle := fire.find_child("Crackle", true, false) as AudioStreamPlayer3D
	assert_not_null(crackle, "Ateşin çıtırtısı (campfire.gd _build_sound)")
	if crackle == null:
		fire.queue_free()
		_free_rig(rig)
		return
	var on_player: Array[float] = []
	var on_camera: Array[float] = []
	var report := PackedStringArray()
	for d in [14.0, 18.0, 22.0, 28.0, 34.0, 40.0]:
		cam.zoom_by(d - cam.get_target_distance())
		_settle(cam)
		var src := crackle.global_position
		var level := _player_db(crackle, cam.get_listener().global_position.distance_to(src))
		var old := _player_db(crackle, cam.camera.global_position.distance_to(src))
		on_player.append(level)
		on_camera.append(old)
		report.append("%.0f m: oyuncuda %.2f dB, kamerada %s" % [d, level, "sessiz" if old == -INF else "%.2f dB" % old])
	print("  [dinleyici] " + " · ".join(report))
	var spread: float = on_player.max() - on_player.min()
	assert_true(spread <= 3.0, "±1,5 dB içinde (oynama %.3f dB)" % spread)
	assert_between(on_camera[0] - on_camera[3], 11.0, 15.0, "Kamerada dinleyen eski düzen 14–28 m'de ≈13 dB oynardı (%.1f)" % (on_camera[0] - on_camera[3]))
	assert_true(on_camera[5] < -60.0, "Kamerada dinlenseydi 40 m'de susardı (%.1f dB)" % on_camera[5])
	fire.free()
	_free_rig(rig)
	await wait_frames(2)


# --- Yardımcılar ------------------------------------------------------------------

## Binmeyi taklit eden hedef: is_riding() ve mount_kind() (PlayerController'ın yüzü).
class RiderProbe:
	extends Node3D
	var riding := false
	var kind := ""

	func is_riding() -> bool:
		return riding

	func mount_kind() -> String:
		return kind if riding else ""


## Eğim, açı ve uzaklık hedeflerine varana dek günceller (2 sn).
func _settle(cam: FollowCamera) -> void:
	for i in 120:
		cam.update_camera(DT)


func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = true
	return e


func _mouse(button: MouseButton, pressed: bool) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.pressed = pressed
	return e


func _motion(relative: Vector2, mask: int) -> InputEventMouseMotion:
	var e := InputEventMouseMotion.new()
	e.relative = relative
	e.button_mask = mask
	return e


## 1920×1080'lik bir SubViewport'ta gerçek izdüşümle kamera (dikey görüş, KEEP_HEIGHT); SubViewport'u çağıran bırakır.
func _frame_camera(xform: Transform3D, fov_deg: float) -> Camera3D:
	var screen := SubViewport.new()
	screen.size = SCREEN
	screen.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(screen)
	var cam := Camera3D.new()
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.fov = fov_deg
	cam.near = 0.05
	cam.far = 2000.0
	screen.add_child(cam)
	cam.global_transform = xform
	cam.make_current()
	return cam


## Nokta ekranın her kenardan margin oranı içeride çizilen dikdörtgeninde mi?
func _on_screen(cam: Camera3D, p: Vector3, margin: float) -> bool:
	if cam.is_position_behind(p):
		return false
	var px := cam.unproject_position(p)
	var size := Vector2(SCREEN)
	return px.x >= size.x * margin and px.x <= size.x * (1.0 - margin) and px.y >= size.y * margin and px.y <= size.y * (1.0 - margin)


## Kuzeye giden bir düzende kenar kartına düşen kişi sayısı (yuva: (yan, ileri) metre; göğüs yüksekliği; dörtnal açılması).
func _cards(cam: Camera3D, slots: Array, chest: float, spread: float) -> int:
	var n := 0
	for s: Vector2 in slots:
		if not _on_screen(cam, Vector3(s.x * spread, chest, -s.y * spread), 0.04):
			n += 1
	return n


## AudioStreamPlayer3D'nin dinleyiciye uzaklıkla düzeyi (dB; Godot 4): ters uzaklık modeli, volume_db, max_db tavanı ve max_distance'ın
## doğrusal sönümü (1 − d / max_distance). Sessizse -INF.
static func _player_db(p: AudioStreamPlayer3D, dist: float) -> float:
	var att := 0.0
	match p.attenuation_model:
		AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE:
			att = linear_to_db(1.0 / (dist / p.unit_size + 0.00001))
		AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE:
			var k := dist / p.unit_size
			att = linear_to_db(1.0 / (k * k + 0.00001))
		AudioStreamPlayer3D.ATTENUATION_LOGARITHMIC:
			att = -20.0 * log(dist / p.unit_size + 0.00001)
	var gain := db_to_linear(minf(att + p.volume_db, p.max_db))
	if p.max_distance > 0.0:
		gain *= maxf(0.0, 1.0 - dist / p.max_distance)
	return linear_to_db(gain) if gain > 0.0 else -INF


## [FollowCamera, hedef] kurar; hedef (0, 0, 4) noktasında, kamera onun Camera3D çocuğunu sürer.
func _make_rig(shape: TerrainShape, target_node: Node3D = null) -> Array:
	var target := target_node if target_node else Node3D.new()
	target.position = Vector3(0.0, shape.height_at(0.0, 4.0), 4.0)
	add_child(target)
	var cam := FollowCamera.new()
	cam.terrain_shape = shape
	cam.target = target
	var camera := Camera3D.new()
	cam.add_child(camera)
	add_child(cam)
	# Gerçek klavye girişi testi bozmasın; güncellemeler elle yapılır.
	cam.set_process(false)
	await wait_frames(1)
	return [cam, target]


func _free_rig(rig: Array) -> void:
	for node in rig:
		(node as Node).queue_free()


# --- Sürüşte açı izlemesi (Yol Haritası riding; godot.md §5.7, act1.md §4, §10) ---------------------------------------

## Yönü olan binici: atta, baktığı açı (radyan; 0 = +Z).
class FacingRider:
	extends Node3D
	var riding := false
	var yaw := PI

	func is_riding() -> bool:
		return riding

	func mount_kind() -> String:
		return "horse" if riding else ""

	func get_facing_yaw() -> float:
		return yaw


func test_ride_follow_turns_behind_the_horse_with_a_1_1_second_lag() -> void:
	var rig := await _make_rig(FlatShape.new(), FacingRider.new())
	var cam: FollowCamera = rig[0]
	var rider: FacingRider = rig[1]
	cam.set_yaw(0.0, true)
	rider.riding = true
	rider.yaw = PI * 0.5
	# Doğuya dönen at: arkası batıda; seçilen açıdan fark 90°, sınır 75°.
	assert_almost(rad_to_deg(FollowCamera.ride_follow_offset(rider.yaw, 0.0)), -75.0, 0.001, "±75° sınırı")
	var t := 0.0
	while t < FollowCamera.RIDE_FOLLOW_LAG - DT * 0.5:
		cam.update_camera(DT)
		t += DT
	assert_almost(rad_to_deg(cam.get_follow_yaw()), -75.0 * (1.0 - exp(-1.0)), 1.0, "1,1 sn'de farkın %63'ü (üstel gecikme)")
	for i in int(5.0 / DT):
		cam.update_camera(DT)
	assert_almost(rad_to_deg(cam.get_follow_yaw()), -75.0, 0.5, "Sonra sınıra varır")
	assert_almost(rad_to_deg(cam.get_yaw()), -75.0, 1.0, "Görünen açı izlemeyi içerir (W ekranda yukarı kalır)")
	# Kameraya dönen at (135°'den çok): izlenmez, kamera seçilen açıya döner.
	rider.yaw = 0.0
	assert_almost(FollowCamera.ride_follow_offset(rider.yaw, 0.0), 0.0, 0.0001, "At kameraya geliyor")
	for i in int(7.0 / DT):
		cam.update_camera(DT)
	assert_almost(rad_to_deg(cam.get_follow_yaw()), 0.0, 0.5, "Seçilen açıya döner")
	# Elle döndürme: görünen açı seçilen olur, izleme 2 sn bekler.
	rider.yaw = PI * 0.5
	for i in int(3.0 / DT):
		cam.update_camera(DT)
	var seen := cam.get_yaw()
	cam.add_yaw(deg_to_rad(10.0))
	assert_almost(cam.get_follow_yaw(), 0.0, 0.0001, "Pay seçilen açıya katılır")
	assert_almost(angle_difference(seen, cam.get_yaw()), 0.0, deg_to_rad(0.5), "Görünen açı sıçramaz (pay seçilen açıya katıldı)")
	for i in int((FollowCamera.RIDE_FOLLOW_WAIT - 0.1) / DT):
		cam.update_camera(DT)
	assert_almost(cam.get_follow_yaw(), 0.0, 0.0001, "2 sn bekler")
	assert_almost(angle_difference(seen + deg_to_rad(10.0), cam.get_yaw()), 0.0, deg_to_rad(1.0), "Elle döndürülen açıya varır")
	for i in int(1.0 / DT):
		cam.update_camera(DT)
	assert_true(absf(cam.get_follow_yaw()) > deg_to_rad(5.0), "Sonra yine izler")
	# İnince görünen açı kalır.
	seen = cam.get_yaw()
	rider.riding = false
	cam.update_camera(DT)
	assert_almost(cam.get_follow_yaw(), 0.0, 0.0001)
	assert_almost(angle_difference(seen, cam.get_yaw()), 0.0, deg_to_rad(1.0), "İnince kamera geri dönmez")
	# «Kamera takibi: Kapalı» izlemez.
	cam.ride_follow = false
	rider.riding = true
	for i in int(3.0 / DT):
		cam.update_camera(DT)
	assert_almost(cam.get_follow_yaw(), 0.0, 0.0001, "Kapalıyken oyuncunun açısı kalır")
	_free_rig(rig)


func test_camera_follow_off_is_a_setting_choice() -> void:
	var settings_script: GDScript = load("res://scripts/settings/game_settings.gd")
	assert_true((settings_script.FOLLOW_MODES as Dictionary).has("off"), "Kamera takibi: Kapalı")
	var settings: Node = settings_script.new()
	settings.persist = false
	settings.apply_window = false
	settings.migrate_user_dir = false
	var cam := FollowCamera.new()
	settings.camera_follow = "off"
	settings.apply_to_camera(cam)
	assert_false(cam.ride_follow, "Kapalı: atta kamera kendiliğinden dönmez")
	assert_almost(cam.follow_sharpness, 5.5, 0.0001, "Konum takibi Normal kalır")
	settings.camera_follow = "soft"
	settings.apply_to_camera(cam)
	assert_true(cam.ride_follow)
	cam.free()
	settings.free()
