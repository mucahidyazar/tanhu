extends TestCase
## PlayerController testleri: kameraya göre yön, hız yaklaşımı, engelden itilme, oyun alanı sınırı
## ve sahnede adım adım yürüme (gerçek klavye girişi olmadan, step() ile).

const DT := 1.0 / 60.0


## Hızlı ve öngörülebilir zemin: sabit yükseklik + isteğe bağlı eğim (gerçek arazi hesabı yok).
class FlatShape:
	extends TerrainShape
	var level := 0.0
	var slope := Vector2.ZERO

	func height_at(x: float, z: float) -> float:
		return level + slope.x * x + slope.y * z


# --- Saf yardımcılar ------------------------------------------------------------

func test_forward_is_minus_z_and_right_is_plus_x_when_camera_yaw_is_zero() -> void:
	assert_vec_almost(PlayerController.camera_relative_direction(Vector2(0.0, 1.0), 0.0), Vector3(0.0, 0.0, -1.0))
	assert_vec_almost(PlayerController.camera_relative_direction(Vector2(1.0, 0.0), 0.0), Vector3(1.0, 0.0, 0.0))
	assert_vec_almost(PlayerController.camera_relative_direction(Vector2(0.0, -1.0), 0.0), Vector3(0.0, 0.0, 1.0))


func test_direction_follows_camera_yaw() -> void:
	# Kamera sola döndü (yaw 90°): ekranda yukarı artık -X yönüdür, sağ ise -Z.
	assert_vec_almost(PlayerController.camera_relative_direction(Vector2(0.0, 1.0), PI * 0.5), Vector3(-1.0, 0.0, 0.0))
	assert_vec_almost(PlayerController.camera_relative_direction(Vector2(1.0, 0.0), PI * 0.5), Vector3(0.0, 0.0, -1.0))
	# Kamera ters yönde (yaw 180°): ileri +Z.
	assert_vec_almost(PlayerController.camera_relative_direction(Vector2(0.0, 1.0), PI), Vector3(0.0, 0.0, 1.0))


func test_direction_is_flat_normalized_and_zero_without_input() -> void:
	var diagonal := PlayerController.camera_relative_direction(Vector2(1.0, 1.0), 0.7)
	assert_almost(diagonal.length(), 1.0, 0.0001, "Çapraz giriş daha hızlı yürütmemeli")
	assert_almost(diagonal.y, 0.0, 0.0001, "Yön yatay olmalı")
	var half := PlayerController.camera_relative_direction(Vector2(0.0, 0.5), 0.0)
	assert_almost(half.length(), 0.5, 0.0001, "Analog giriş (yarım basış) korunmalı")
	assert_vec_almost(PlayerController.camera_relative_direction(Vector2.ZERO, 1.3), Vector3.ZERO)


func test_approach_velocity_limits_change_and_never_overshoots() -> void:
	var v := PlayerController.approach_velocity(Vector3.ZERO, Vector3(2.2, 0.0, 0.0), 10.0, 0.1)
	assert_vec_almost(v, Vector3(1.0, 0.0, 0.0), 0.0001, "Bir adımda en fazla accel * delta değişmeli")
	for i in 10:
		v = PlayerController.approach_velocity(v, Vector3(2.2, 0.0, 0.0), 10.0, 0.1)
	assert_vec_almost(v, Vector3(2.2, 0.0, 0.0), 0.0001, "Hedef hız aşılmamalı")
	var stopped := PlayerController.approach_velocity(Vector3(0.3, 0.0, 0.0), Vector3.ZERO, 14.0, 0.1)
	assert_vec_almost(stopped, Vector3.ZERO, 0.0001, "Yavaşlarken sıfırın ötesine geçmemeli")


func test_resolve_circles_pushes_point_to_the_rim() -> void:
	var circles: Array[Vector3] = [Vector3(0.0, 0.0, 1.0)]
	var pushed := PlayerController.resolve_circles(Vector2(0.5, 0.0), circles, 0.35)
	assert_almost(pushed.length(), 1.35, 0.0001, "Daire yarıçapı + gövde yarıçapına itilmeli")
	assert_almost(pushed.angle(), 0.0, 0.0001, "Merkezden dışa doğru itilmeli")
	var outside := Vector2(3.0, 1.0)
	assert_eq(PlayerController.resolve_circles(outside, circles, 0.35), outside, "Dışarıdaki nokta değişmemeli")
	var from_center := PlayerController.resolve_circles(Vector2.ZERO, circles, 0.35)
	assert_almost(from_center.length(), 1.35, 0.0001, "Tam merkezdeki nokta da dışarı çıkmalı")


func test_resolve_circles_handles_overlapping_circles() -> void:
	var circles: Array[Vector3] = [Vector3(-0.6, 0.0, 1.0), Vector3(0.6, 0.0, 1.0)]
	var p := PlayerController.resolve_circles(Vector2(0.0, 0.2), circles, 0.3)
	for c in circles:
		assert_true(p.distance_to(Vector2(c.x, c.y)) >= c.z + 0.3 - 0.001, "İki dairenin de dışında kalmalı: %s" % p)


func test_clamp_to_area_keeps_point_inside_circle() -> void:
	var center := Vector2(1.0, 2.0)
	assert_eq(PlayerController.clamp_to_area(Vector2(3.0, 2.0), center, 5.0), Vector2(3.0, 2.0), "İçerideki nokta değişmemeli")
	var clamped := PlayerController.clamp_to_area(Vector2(11.0, 2.0), center, 5.0)
	assert_almost(clamped.distance_to(center), 5.0, 0.0001, "Dışarıdaki nokta kenara çekilmeli")
	assert_almost(clamped.y, 2.0, 0.0001, "Aynı doğrultuda kalmalı")


func test_soften_at_edge_only_damps_outward_motion() -> void:
	var outward := Vector3(2.0, 0.0, 0.0)
	assert_vec_almost(PlayerController.soften_at_edge(outward, Vector2(10.0, 0.0), Vector2.ZERO, 38.0, 3.0), outward,
		0.0001, "Kenardan uzakta hız değişmemeli")
	var near := PlayerController.soften_at_edge(outward, Vector2(37.7, 0.0), Vector2.ZERO, 38.0, 3.0)
	assert_between(near.x, 0.01, 1.99, "Kenara yakınken dışa hız azalmalı")
	var room := 38.0 - PlayerController.EDGE_STOP_MARGIN - 37.7
	assert_almost(near.x, sqrt(2.0 * PlayerController.EDGE_BRAKE * room), 0.0001, "Sabit yavaşlamayla durabilecek hız")
	assert_almost(PlayerController.soften_at_edge(outward, Vector2(38.0, 0.0), Vector2.ZERO, 38.0, 3.0).x, 0.0, 0.0001,
		"Kenarda dışa hız sıfır olmalı")
	var fast := Vector3(4.6, 0.0, 0.0)
	assert_vec_almost(PlayerController.soften_at_edge(fast, Vector2(35.05, 0.0), Vector2.ZERO, 38.0, 3.0), fast, 0.0001,
		"Koşarken fren bölgeye girer girmez sert başlamamalı")
	var tangent := Vector3(0.0, 0.0, 2.0)
	assert_vec_almost(PlayerController.soften_at_edge(tangent, Vector2(37.5, 0.0), Vector2.ZERO, 38.0, 3.0), tangent,
		0.0001, "Kenar boyunca yürümek etkilenmemeli")
	var inward := Vector3(-2.0, 0.0, 0.0)
	assert_vec_almost(PlayerController.soften_at_edge(inward, Vector2(37.5, 0.0), Vector2.ZERO, 38.0, 3.0), inward,
		0.0001, "İçe dönmek etkilenmemeli")


func test_yaw_from_basis_matches_follow_camera_yaw() -> void:
	for yaw in [0.0, 0.6, -1.9, PI * 0.95]:
		for pitch in [20.0, 50.0, 89.5]:
			var xform := FollowCamera.compute_transform(Vector3.ZERO, yaw, pitch, 9.0)
			var got := PlayerController.yaw_from_basis(xform.basis)
			assert_almost(angle_difference(got, yaw), 0.0, 0.001, "yaw %f, eğim %f" % [yaw, pitch])


# --- Sahnede yürüme ---------------------------------------------------------------

func test_walks_forward_at_walk_speed_and_follows_the_ground() -> void:
	var player := await _make_player(FlatShape.new())
	(player.terrain_shape as FlatShape).level = 0.5
	_walk(player, Vector2(0.0, 1.0), false, 0.0, 2.0)
	assert_almost(player.get_speed(), player.walk_speed, 0.01, "Yürüme hızına ulaşmalı")
	# 2 sn'de gidilen yol: tam hızla 2 sn, eksi duruştan hızlanırken kaybedilen v²/(2a).
	var expected := player.walk_speed * 2.0 - player.walk_speed * player.walk_speed / (2.0 * player.acceleration)
	assert_between(player.position.z, -expected - 0.2, -expected + 0.2, "2 sn'de ~%.1f m ileri (-Z) gitmeli" % expected)
	assert_almost(player.position.x, 0.0, 0.001, "Yana kaymamalı")
	assert_almost(player.position.y, 0.5, 0.0001, "Zemin yüksekliğinde durmalı")
	assert_almost(angle_difference(player.get_facing_yaw(), PI), 0.0, 0.02, "Karakter yürüdüğü yöne (-Z) bakmalı")
	assert_almost(angle_difference(player.get_avatar().rotation.y, PI), 0.0, 0.02, "Avatar da aynı yöne dönmeli")
	player.queue_free()


func test_sprint_reaches_run_speed() -> void:
	var player := await _make_player(FlatShape.new())
	_walk(player, Vector2(1.0, 0.0), true, 0.0, 1.5)
	assert_almost(player.get_speed(), player.run_speed, 0.01, "Shift ile koşma hızına ulaşmalı")
	assert_true(player.position.x > 5.0, "Sağa (+X) koşmalı")
	player.queue_free()


func test_acceleration_and_deceleration_are_smooth() -> void:
	var player := await _make_player(FlatShape.new())
	player.step(DT, Vector2(0.0, 1.0), false, 0.0)
	assert_between(player.get_speed(), 0.01, player.walk_speed * 0.5, "İlk karede hemen tam hıza çıkmamalı")
	_walk(player, Vector2(0.0, 1.0), false, 0.0, 1.0)
	player.step(DT, Vector2.ZERO, false, 0.0)
	assert_between(player.get_speed(), 0.5, player.walk_speed, "Tuş bırakılınca bir karede durmamalı")
	_walk(player, Vector2.ZERO, false, 0.0, 0.5)
	assert_almost(player.get_speed(), 0.0, 0.001, "Kısa sürede tamamen durmalı")
	player.queue_free()


func test_turning_is_smooth_but_completes() -> void:
	var player := await _make_player(FlatShape.new())
	_walk(player, Vector2(0.0, 1.0), false, 0.0, 0.5)
	player.step(DT, Vector2(1.0, 0.0), false, 0.0)
	var after_one := player.get_facing_yaw()
	assert_true(absf(angle_difference(after_one, PI * 0.5)) > 0.5, "Dönüş tek karede bitmemeli")
	_walk(player, Vector2(1.0, 0.0), false, 0.0, 0.6)
	assert_almost(angle_difference(player.get_facing_yaw(), PI * 0.5), 0.0, 0.02, "Yeni yöne (+X) dönmüş olmalı")
	player.queue_free()


func test_obstacle_blocks_the_way() -> void:
	var player := await _make_player(FlatShape.new())
	var circles: Array[Vector3] = [Vector3(0.0, -2.0, 1.0)]
	player.obstacles = circles
	_walk(player, Vector2(0.0, 1.0), false, 0.0, 3.0)
	var p := Vector2(player.position.x, player.position.z)
	assert_true(p.distance_to(Vector2(0.0, -2.0)) >= 1.0 + player.body_radius - 0.001, "Engelin içine girmemeli: %s" % p)
	player.queue_free()


func test_stays_inside_play_area() -> void:
	var player := await _make_player(FlatShape.new())
	player.play_area_radius = 5.0
	player.play_area_soft_edge = 1.5
	_walk(player, Vector2(0.0, 1.0), true, 0.0, 4.0)
	var p := Vector2(player.position.x, player.position.z)
	assert_true(p.length() <= 5.0 + 0.001, "Oyun alanının dışına çıkmamalı: %s" % p)
	assert_true(p.length() > 4.8, "Kenara kadar yürüyebilmeli")
	assert_almost(player.get_speed(), 0.0, 0.001, "Kenarda durmalı (yerinde koşmamalı)")
	player.queue_free()


func test_frame_spike_does_not_teleport_through_obstacles() -> void:
	var player := await _make_player(FlatShape.new())
	var circles: Array[Vector3] = [Vector3(0.0, -1.5, 0.6)]
	player.obstacles = circles
	_walk(player, Vector2(0.0, 1.0), true, 0.0, 0.2)
	# Tek bir 3 saniyelik takılma karesi: karakter engelin öbür yanına geçmemeli.
	player.step(3.0, Vector2(0.0, 1.0), true, 0.0)
	assert_true(player.position.z > -1.5, "Uzun karede engelin içinden geçmemeli: %s" % player.position)
	assert_true(player.position.z > -1.0, "Bir adımda en fazla MAX_STEP kadar ilerlemeli")
	player.queue_free()


func test_push_out_of_a_new_obstacle_does_not_fling_the_player() -> void:
	# Engel karakter zaten içindeyken eklenir (ör. ertelenmiş refresh_obstacles): karakter kenara
	# itilmeli ama bu itme hıza dönüşüp onu haritanın öbür ucuna fırlatmamalı.
	var player := await _make_player(FlatShape.new())
	player.spawn_at(Vector3(0.0, 0.0, 4.0), PI)
	var circles: Array[Vector3] = [Vector3(0.0, 4.2, 1.0)]
	player.obstacles = circles
	_walk(player, Vector2.ZERO, false, 0.0, 1.0)
	var p := Vector2(player.position.x, player.position.z)
	var rim := 1.0 + player.body_radius
	assert_true(p.distance_to(Vector2(0.0, 4.2)) >= rim - 0.001, "Engelin dışına çıkmalı: %s" % p)
	assert_true(p.distance_to(Vector2(0.0, 4.2)) < rim + 0.05, "Kenarda kalmalı, uzağa fırlamamalı: %s" % p)
	assert_almost(player.get_speed(), 0.0, 0.0001, "Giriş yokken hız sıfır kalmalı")
	player.queue_free()


func test_shrinking_play_area_pulls_in_without_speed() -> void:
	var player := await _make_player(FlatShape.new())
	player.spawn_at(Vector3(0.0, 0.0, 30.0), 0.0)
	player.play_area_radius = 20.0
	_walk(player, Vector2.ZERO, false, 0.0, 1.0)
	assert_almost(player.position.z, 20.0, 0.01, "Yeni sınırın kenarına çekilmeli, öbür uca savrulmamalı")
	assert_almost(player.get_speed(), 0.0, 0.0001)
	player.queue_free()


func test_follows_sloped_ground() -> void:
	var shape := FlatShape.new()
	shape.slope = Vector2(0.1, -0.2)
	var player := await _make_player(shape)
	_walk(player, Vector2(0.7, 0.7), false, 0.0, 1.0)
	var p := player.position
	assert_almost(p.y, shape.height_at(p.x, p.z), 0.0001, "Eğimli zeminde de ayaklar yere basmalı")
	player.queue_free()


func test_inactive_player_ignores_input_and_does_not_pause() -> void:
	var player := await _make_player(FlatShape.new())
	_walk(player, Vector2(0.0, 1.0), false, 0.0, 0.5)
	player.set_active(false)
	assert_false(player.is_active())
	assert_almost(player.get_speed(), 0.0, 0.0001, "Kapatınca karakter hemen beklemeye geçmeli")
	var before := player.position
	player._process(0.2)
	assert_vec_almost(player.position, before, 0.0001, "Kapalıyken yürümemeli")
	var watcher := watch_signal(player.pause_requested)
	player._unhandled_input(_pause_event())
	assert_false(watcher.fired, "Kapalıyken duraklatma isteği gelmemeli")
	player.queue_free()


func test_escape_requests_pause_when_active() -> void:
	var player := await _make_player(FlatShape.new())
	player.set_active(true)
	var watcher := watch_signal(player.pause_requested)
	player._unhandled_input(_pause_event())
	assert_true(watcher.fired, "Esc duraklatma isteği göndermeli")
	player.queue_free()


func test_spawn_at_places_on_ground_outside_obstacles_and_faces_yaw() -> void:
	var shape := FlatShape.new()
	shape.level = 1.25
	var player := await _make_player(shape)
	var circles: Array[Vector3] = [Vector3(0.0, 4.0, 0.5)]
	player.obstacles = circles
	player.spawn_at(Vector3(0.2, 9.0, 4.0), PI)
	var p := player.position
	assert_almost(p.y, 1.25, 0.0001, "Yükseklik zeminden alınmalı")
	assert_true(Vector2(p.x, p.z).distance_to(Vector2(0.0, 4.0)) >= 0.5 + player.body_radius - 0.001, "Engelin içinde doğmamalı")
	assert_almost(player.get_facing_yaw(), PI, 0.0001)
	assert_almost(player.get_avatar().rotation.y, PI, 0.0001)
	assert_almost(player.get_speed(), 0.0, 0.0001)
	player.queue_free()


func test_auto_move_walks_without_player_input() -> void:
	var player := await _make_player(FlatShape.new())
	player.set_active(false)
	player.auto_move = Vector2(0.0, 1.0)
	for i in 60:
		player._process(DT)
	assert_true(player.position.z < -1.5, "Senaryolu hareket kapalı kontrolde de yürütmeli")
	player.queue_free()


func test_movement_uses_follow_camera_yaw() -> void:
	var player := await _make_player(FlatShape.new())
	var cam := FollowCamera.new()
	cam.start_active = false
	add_child(cam)
	cam.set_yaw(PI * 0.5, true)
	player.camera = cam
	assert_almost(player.camera_yaw(), PI * 0.5, 0.0001, "Hareket takip kamerasının açısını kullanmalı")
	player.auto_move = Vector2(0.0, 1.0)
	for i in 30:
		player._process(DT)
	assert_true(player.position.x < -0.3 and absf(player.position.z) < 0.01, "W, kamera 90° dönükken -X'e yürütmeli")
	player.queue_free()
	cam.queue_free()


func test_creates_avatar_when_missing() -> void:
	var player := PlayerController.new()
	player.terrain_shape = FlatShape.new()
	player.start_active = false
	var avatar := player.get_avatar()
	assert_not_null(avatar, "Avatar yoksa oluşturulmalı")
	assert_eq(avatar.get_parent(), player, "Avatar oyuncunun çocuğu olmalı")
	player.free()


func test_player_fidgets_while_waiting_and_moving_cuts_it_at_once() -> void:
	# K91: oyuncu beklerken ara hareket oynar; çeşit atanmaz, rolleri kendi kliplerindedir. Sahnedeki avatar da, kurulan avatar da açıktır.
	var created := PlayerController.new()
	created.terrain_shape = FlatShape.new()
	created.start_active = false
	assert_true(created.get_avatar().auto_fidget, "Kurulan avatarda açık")
	created.free()
	var player := PlayerController.new()
	player.terrain_shape = FlatShape.new()
	player.start_active = false
	var avatar := CharacterAvatar.new()
	avatar.model_override = "mete"
	player.add_child(avatar)
	add_child(player)
	player.set_process(false)
	await wait_frames(1)
	player.obstacles = []
	assert_eq(player.get_avatar(), avatar, "Sahnedeki avatar kullanılır")
	assert_true(avatar.auto_fidget, "Sahnedeki avatarda açık")
	assert_true(avatar.has_meshy_model(), "Gerçek model")
	assert_eq(avatar.variety_person, "", "Oyuncuya çeşit atanmaz")
	for role in CharacterAvatar.ROLES:
		assert_eq(avatar.variety_key(role), "", "%s kendi klibinde" % role)
	player.set_active(false)
	assert_eq(avatar.get_current_role(), &"idle")
	var pool := ClipVariety.fidget_pool(ClipVariety.profile_of("mete"))
	assert_false(pool.is_empty(), "Ara hareket havuzu")
	avatar.tick_fidget(100.0)
	var key := avatar.fidget_key()
	assert_true(pool.has(key), "Bekleme süresi dolunca ara hareket oynar: %s" % key)
	var anim_player := avatar.get_animation_player()
	assert_eq(anim_player.assigned_animation, ClipVariety.clip_name(key), "Klibi oynar")
	# Durduğu her kare gelen bekleme isteği ara hareketi kesmez.
	player.step(DT, Vector2.ZERO, false, 0.0)
	assert_eq(avatar.fidget_key(), key, "Dururken sürer")
	# İlk adımda kesilir: hız eşiği geçer geçmez yürüme klibi başlar.
	var steps := 0
	while avatar.get_current_role() != &"walk" and steps < 5:
		player.step(DT, Vector2.UP, false, 0.0)
		steps += 1
	assert_true(steps <= 2, "Hemen harekete geçer: %d adım" % steps)
	assert_eq(avatar.get_current_role(), &"walk")
	assert_eq(avatar.fidget_key(), "", "Hareket ara hareketi keser")
	assert_ne(anim_player.assigned_animation, ClipVariety.clip_name(key), "Ara hareket klibi kalmaz")
	avatar.tick_fidget(100.0)
	assert_eq(avatar.fidget_key(), "", "Yürürken ara hareket başlamaz")
	# Durunca bekleme klibine döner, saat yeniden işler.
	for i in 60:
		player.step(DT, Vector2.ZERO, false, 0.0)
	assert_eq(avatar.get_current_role(), &"idle")
	assert_eq(avatar.fidget_key(), "", "Durunca hemen oynamaz")
	avatar.tick_fidget(100.0)
	assert_false(avatar.fidget_key().is_empty(), "Yeniden bekleyince oynar")
	player.queue_free()


func test_demo_parses_the_capture_pose() -> void:
	# Deneme sahnesi (scenes/player/player_demo.tscn) --pose=x,y,z,yaw,pitch isteğini kendisi okur.
	var demo := preload("res://scripts/player/player_demo.gd")
	assert_eq(demo.parse_pose("-19.5,9,6.2,0,50"), PackedFloat32Array([-19.5, 9.0, 6.2, 0.0, 50.0]))
	assert_eq(demo.parse_pose(" 1, 2 ,3,4,5,6"), PackedFloat32Array([1.0, 2.0, 3.0, 4.0, 5.0]), "Boşluklar ve fazla değerler sorun olmamalı")
	assert_true(demo.parse_pose("").is_empty(), "Poz yoksa boş")
	assert_true(demo.parse_pose("1,2,3").is_empty(), "Eksik değer: geçersiz")
	assert_true(demo.parse_pose("1,2,x,4,5").is_empty(), "Sayı olmayan değer: geçersiz")


# --- Yardımcılar ------------------------------------------------------------------

## Chibi yedekli bir avatarla, dünyasız (enjekte edilmiş zeminle) bir oyuncu kurar.
func _make_player(shape: TerrainShape) -> PlayerController:
	var player := PlayerController.new()
	player.terrain_shape = shape
	player.start_active = false
	var avatar := CharacterAvatar.new()
	avatar.use_meshy_models = false
	player.add_child(avatar)
	add_child(player)
	# Gerçek giriş ve ertelenmiş engel toplama testi bozmasın.
	player.set_process(false)
	await wait_frames(1)
	player.obstacles = []
	return player


## seconds boyunca sabit girişle adım atar.
func _walk(player: PlayerController, input: Vector2, sprint: bool, yaw: float, seconds: float) -> void:
	for i in int(round(seconds / DT)):
		player.step(DT, input, sprint, yaw)


func _pause_event() -> InputEventAction:
	var event := InputEventAction.new()
	event.action = &"pause"
	event.pressed = true
	return event
