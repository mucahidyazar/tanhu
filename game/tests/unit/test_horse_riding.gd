extends TestCase
## Ata binme (2026-11-07; Mount satırı «horse», RideableHorse, PlayerController'ın vault binişi, Horse ve Stable): satırın yürüyüşleri (giriş adım, Shift tırıs
## sonra dörtnal), iskeletli atın klipleri ve hızı, toynak vuruşlarının tozu, izi ve sesi, çocuğun ve yetişkinin yanaşıp sıçrayarak binişi, sürüş, iniş (at
## bırakıldığı yerde kalır), ikinci at, ahırın duvarları ve ağzı, kameranın hızla genişlemesi, toynak sesinin sentezi. Gerçek klavye yok: step() ve interact()
## doğrudan çağrılır; at ve kişiler gerçek modellerdir (assets/animals/horse_*, assets/characters/child, mete).

const DT := 1.0 / 60.0
const BROWN := "res://assets/animals/horse_brown/horse_brown.glb"
const WHITE := "res://assets/animals/horse_white/horse_white.glb"
const SHEEP_SCENE := preload("res://scenes/fauna/rideable_sheep.tscn")


class FlatShape:
	extends TerrainShape

	func height_at(_x: float, _z: float) -> float:
		return 0.0


var _trash: Array[Node] = []


func before_each() -> void:
	Mount.reset_cache()


func after_each() -> void:
	for node in _trash:
		if is_instance_valid(node):
			node.queue_free()
	_trash.clear()


# --- Satır -------------------------------------------------------------------------------------------

func test_horse_row_walks_on_input_and_shift_builds_trot_then_gallop() -> void:
	assert_true(Mount.ids().has("horse"), "Atın satırı var")
	var horse := Mount.new("horse")
	horse.start_ride()
	assert_true(horse.walks_on_input())
	assert_almost(horse.step(DT, true, false, false), horse.walk_speed(), 0.0001, "Giriş adım yürütür")
	assert_eq(horse.gait_name(), "walk")
	assert_almost(horse.step(DT, true, true, true), horse.trot_speed(), 0.0001, "Shift önce tırıs")
	assert_eq(horse.gait_name(), "trot")
	var t := DT
	while t < horse.value("gallop_after_s") - DT * 2.0:
		assert_almost(horse.step(DT, true, true, false), horse.trot_speed(), 0.0001, "Tuş basılı kalınca bir süre tırıs (%.2f)" % t)
		t += DT
	for i in 4:
		horse.step(DT, true, true, false)
	assert_almost(horse.step(DT, true, true, false), horse.gallop_speed(), 0.0001, "Basılı kalınca dörtnal")
	assert_eq(horse.gait_name(), "gallop")
	# Bırakılan tuş mahmuzun aralığı (spur_tap_s) boyunca dörtnalı tutar (yeniden basış mahmuzdur; test_riding.gd), sonra adım.
	assert_almost(horse.step(DT, true, false, false), horse.gallop_speed(), 0.0001, "Mahmuzun aralığında dörtnal sürer")
	for i in int(horse.value("spur_tap_s") / DT) + 1:
		horse.step(DT, true, false, false)
	assert_almost(horse.step(DT, true, false, false), horse.walk_speed(), 0.0001, "Tuş bırakılınca adım")
	assert_almost(horse.sprint_clock, 0.0, 0.0001, "Saat sıfırlanır")
	assert_almost(horse.step(DT, true, true, true), horse.trot_speed(), 0.0001, "Yeniden basınca yine önce tırıs")
	assert_almost(horse.step(DT, false, true, false), 0.0, 0.0001, "Girişsiz durur")
	assert_eq(horse.gait_name(), "stand")
	# Hızlar sıralı ve adım boyları kliplerinkiyle aynı.
	assert_true(horse.walk_speed() < horse.trot_speed() and horse.trot_speed() < horse.gallop_speed())
	assert_almost(horse.stride_at(horse.walk_speed()), 1.5, 0.0001)
	assert_almost(horse.stride_at(horse.gallop_speed()), 3.9, 0.0001)
	# Dörtnalda dönüş geniştir.
	assert_almost(horse.turn_at(0.0), horse.value("turn"), 0.0001)
	assert_almost(horse.turn_at(horse.gallop_speed()), horse.value("turn_fast"), 0.0001)
	assert_true(horse.turn_at(horse.gallop_speed()) < horse.turn_at(horse.walk_speed()))
	assert_eq(horse.mount_style(), "vault", "Ata yanaşıp sıçrayarak binilir")
	assert_true(horse.allows_rider(true) and horse.allows_rider(false), "Çocuk da yetişkin de biner")
	var sheep := Mount.new("sheep")
	assert_false(sheep.walks_on_input(), "Koyunun girişi tırıstır (eskisi gibi)")
	assert_eq(sheep.mount_style(), "hop")
	assert_true(sheep.allows_rider(true))
	assert_false(sheep.allows_rider(false), "Koyuna yetişkin binmez")


func test_horse_seat_equals_the_brown_model_measure() -> void:
	var seat := Mount.new("horse").seat()
	var meta := Rideable.read_meta(BROWN)
	if meta.is_empty():
		assert_true(true, "Model ölçüsü yok")
		return
	assert_almost(float(seat["saddle_y"]), float(meta["saddle_y"]), 0.002, "Satırın eyer yüksekliği doru atın ölçüsü")
	assert_almost(float(seat["saddle_z"]), float(meta["saddle_z"]), 0.002)
	var stride: Dictionary = Mount.row_of("horse")["stride"]
	for clip in ["walk", "trot", "gallop"]:
		assert_almost(float(stride[clip]), float(meta["clips"][clip]["stride_m"]), 0.001, "%s adım boyu klibinki" % clip)


# --- İskeletli at ------------------------------------------------------------------------------------

func test_rideable_horse_loads_the_rigged_model() -> void:
	var horse := _make_horse(BROWN, Vector3.ZERO, 0.0)
	assert_true(horse.uses_model(), "İskeletli model kurulur")
	assert_true(horse.is_in_group(Rideable.GROUP))
	assert_eq(horse.mount_kind(), "horse")
	var anim := horse.get_node("Body/HorseModel").find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	for clip in ["idle", "graze", "walk", "trot", "gallop"]:
		assert_true(anim.has_animation(clip), "%s klibi" % clip)
		assert_eq(anim.get_animation(clip).loop_mode, Animation.LOOP_LINEAR, "%s döngülü" % clip)
	assert_eq(horse.model_clip(), &"idle", "Bekler")
	var seat := horse.seat_transform()
	assert_almost(seat.origin.y, float(horse.meta["saddle_y"]), 0.05, "Oturma noktası eyerin yüzü (gövde kemiğini izler)")
	var box := horse.obstacle_box()
	assert_true(box.half.y > box.half.x * 2.0, "Engel kutusu uzun (gövde boyunca)")
	assert_true(box.contains(Vector2(0.0, 0.9)) and box.contains(Vector2(0.0, -0.9)), "Baştan sağrıya örter")


func test_gait_clips_follow_speed_without_foot_slide() -> void:
	var horse := _make_horse(BROWN, Vector3.ZERO, 0.0)
	var mount := horse.get_mount()
	for row: Array in [[mount.walk_speed(), &"walk"], [mount.trot_speed(), &"trot"], [mount.gallop_speed(), &"gallop"]]:
		for i in 10:
			horse.drive(float(row[0]), DT)
		assert_eq(horse.gait_role(), row[1], "%.1f m/sn: %s" % [row[0], row[1]])
		assert_almost(horse.clip_rate(StringName(row[1]), float(row[0])), 1.0, 0.03, "%s doğal hızında oynar (adım boyu × sıklık = hız)" % row[1])
	# Geçişte kayma payı: eşiğin hemen üstü ve altı oynayanı korur.
	assert_eq(RideableHorse.role_for(RideableHorse.WALK_TOP + 0.1, &"walk"), &"walk")
	assert_eq(RideableHorse.role_for(RideableHorse.WALK_TOP - 0.1, &"trot"), &"trot")
	assert_eq(RideableHorse.role_for(RideableHorse.GALLOP_FROM - 0.1, &"gallop"), &"gallop")
	assert_eq(RideableHorse.role_for(RideableHorse.GALLOP_FROM + 0.4, &"trot"), &"gallop")
	assert_eq(RideableHorse.role_for(0.0, &"gallop"), &"idle")
	# Döngülü evrenin geçişi.
	assert_true(RideableHorse.crossed(0.1, 0.3, 0.2))
	assert_false(RideableHorse.crossed(0.1, 0.3, 0.4))
	assert_true(RideableHorse.crossed(0.9, 0.05, 0.0), "Başa sarınca")
	assert_true(RideableHorse.crossed(0.9, 0.05, 0.95))
	assert_false(RideableHorse.crossed(0.9, 0.05, 0.5))


func test_hoof_strikes_raise_dust_and_prints_at_the_gallop() -> void:
	var horse := _make_horse(BROWN, Vector3.ZERO, 0.0)
	var anim := horse.get_node("Body/HorseModel").find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var effects := horse.effects()
	assert_not_null(effects, "Toz, iz ve ses kurulur")
	# Adım: ses var, toz ve iz yok.
	_drive(horse, anim, horse.get_mount().walk_speed(), 2.0)
	assert_true(horse.strikes >= 6, "Adımda toynaklar vurur (%d)" % horse.strikes)
	assert_eq(effects.dust_count, 0, "Adımda toz kalkmaz")
	assert_eq(effects.print_count, 0, "Adımda iz bırakmaz")
	# Dörtnal: adım başına dört vuruş, toz ve iz.
	var before := horse.strikes
	var gallop := horse.get_mount().gallop_speed()
	_drive(horse, anim, gallop, 1.5)
	var cycles := 1.5 * gallop / 3.9
	assert_between(float(horse.strikes - before), cycles * 4.0 - 3.0, cycles * 4.0 + 3.0, "Dörtnalda adım başına dört vuruş")
	assert_true(effects.dust_count > 4, "Dörtnalda toz kalkar (%d)" % effects.dust_count)
	assert_true(effects.print_count > 4, "Dörtnalda iz kalır (%d)" % effects.print_count)
	assert_not_null(effects.get_node_or_null(^"Hooves") as AudioStreamPlayer3D, "Toynak sesi")
	assert_true(effects.top_level, "Toz ve iz dünyada kalır, atla gitmez")
	# Durunca toz söner, iz bir süre kalır.
	for i in int(1.5 / DT):
		effects._process(DT)
	assert_eq(effects.dust_count, 0, "Toz söner")
	assert_true(effects.print_count > 0, "İz kalır")


# --- Biniş, sürüş, iniş ------------------------------------------------------------------------------

func test_child_vaults_onto_the_horse_rides_and_leaves_it_where_it_stands() -> void:
	var horse := _make_horse(BROWN, Vector3.ZERO, 0.0)
	var player := await _make_rider(true)
	player.spawn_at(Vector3(1.4, 0.0, 0.4), -PI * 0.5)
	assert_eq(player.mount_in_reach(), horse, "Yanında at erimde")
	assert_true(player.has_interaction(), "E'nin işi var: kamera E ile dönmez")
	assert_eq(player.prompt_pairs(), [["E", "Bin"]])
	var watcher := watch_signal(player.mounted)
	assert_true(player.interact(), "E biner")
	assert_eq(player.get_stance(), PlayerController.Stance.MOUNTING)
	assert_true(horse.ridden)
	var highest := -INF
	var seconds := 0.0
	while player.get_stance() == PlayerController.Stance.MOUNTING and seconds < 4.0:
		player.step(DT, Vector2.ZERO, false, 0.0)
		highest = maxf(highest, player.get_avatar().global_position.y)
		seconds += DT
	assert_eq(player.get_stance(), PlayerController.Stance.RIDING, "Biniş biter")
	assert_between(seconds, 0.8, 2.6, "Biniş kısa: yanaşma, çömelme, sıçrayış, oturma (%.2f sn)" % seconds)
	assert_eq(watcher.count, 1)
	assert_eq(player.riding_node(), horse)
	assert_eq(player.mount_kind(), "horse")
	# Avatarın kökü ayaklarıdır: oturunca kalça eyerin üstünde, kök onun kalça boyu kadar altında. Sıçrayış oturuşun da üstüne bir yay çizer.
	var seated_y := player.get_avatar().global_position.y
	var seat_y := horse.seat_transform().origin.y
	assert_true(seated_y > 0.5, "Binici yerden kalktı, sırtta (kök %.2f m)" % seated_y)
	assert_true(highest > seated_y + 0.08, "Sıçrayış oturuşun üstüne yay çizer (en yüksek %.2f, oturuş %.2f)" % [highest, seated_y])
	var hips := player.get_avatar().get_skeleton()
	if hips:
		var bone := hips.find_bone("Hips")
		var hips_y := (hips.global_transform * hips.get_bone_global_pose(bone).origin).y
		assert_between(hips_y - seat_y, 0.0, 0.35, "Kalça eyerin üstünde (%.2f m)" % (hips_y - seat_y))
	assert_eq(player.get_avatar().get_current_role(), RidePose.ROLE, "Binme pozu")
	assert_eq(player.prompt_pairs(), [["Shift", "Hızlan"], ["E", "İn"], ["Sağ tık", "Nişan"]])
	# Sürüş: giriş adım, Shift tırıs sonra dörtnal; at binicinin altında gider.
	_steps(player, Vector2(0.0, 1.0), false, 2.0)
	assert_almost(player.get_speed(), horse.get_mount().walk_speed(), 0.05, "Adım")
	assert_eq(player.mount_gait(), "walk")
	_steps(player, Vector2(0.0, 1.0), true, 0.6)
	assert_eq(player.mount_gait(), "trot", "Shift'le tırıs")
	_steps(player, Vector2(0.0, 1.0), true, 2.6)
	assert_eq(player.mount_gait(), "gallop", "Basılı kalınca dörtnal")
	assert_almost(player.get_speed(), horse.get_mount().gallop_speed(), 0.1, "Dörtnal hızı")
	assert_eq(horse.gait_role(), &"gallop", "At dörtnal klibinde")
	var flat := Vector2(horse.global_position.x - player.global_position.x, horse.global_position.z - player.global_position.z)
	assert_almost(flat.length(), 0.0, 0.01, "At binicinin altında")
	assert_true(player.global_position.length() > 10.0, "Yol aldı (%.1f m)" % player.global_position.length())
	# İniş: yandan atlar, at bırakıldığı yerde kalır.
	_steps(player, Vector2.ZERO, false, 3.0)
	var left_at := horse.global_position
	var down := watch_signal(player.dismounted)
	assert_true(player.interact(), "E iner")
	seconds = 0.0
	while player.get_stance() == PlayerController.Stance.DISMOUNTING and seconds < 3.0:
		player.step(DT, Vector2.ZERO, false, 0.0)
		seconds += DT
	assert_eq(player.get_stance(), PlayerController.Stance.FOOT, "Yere iner")
	assert_between(seconds, 0.5, 1.4, "İniş kısa (%.2f sn)" % seconds)
	assert_eq(down.count, 1)
	assert_false(horse.ridden)
	assert_null(player.riding_node())
	assert_vec_almost(horse.global_position, left_at, 0.001, "At bırakıldığı yerde kalır")
	var side := Vector2(player.global_position.x - left_at.x, player.global_position.z - left_at.z).length()
	assert_between(side, 0.6, 1.4, "Atın yanına iner (%.2f m)" % side)
	assert_almost(player.get_avatar().position.y, 0.0, 0.001, "Ayak yerde")
	_steps(player, Vector2.ZERO, false, 2.0)
	assert_vec_almost(horse.global_position, left_at, 0.001, "Kendiliğinden ahıra dönmez")
	assert_eq(player.mount_in_reach(), horse, "Bir daha binilebilir")


func test_adult_rides_the_horse_too_but_not_a_sheep() -> void:
	var horse := _make_horse(WHITE, Vector3(0.0, 0.0, 0.0), PI * 0.5)
	var player := await _make_rider(false)
	assert_false(player.is_child())
	player.spawn_at(Vector3(0.3, 0.0, 1.2), PI)
	assert_eq(player.mount_in_reach(), horse, "Yetişkine de erimde")
	assert_eq(player.prompt_pairs(), [["E", "Bin"]], "Yetişkine binmenin ipucu")
	assert_true(player.interact())
	_steps(player, Vector2.ZERO, false, 3.0)
	assert_true(player.is_riding(), "Yetişkin biner")
	assert_eq(player.prompt_pairs(), [["Shift", "Hızlan"], ["E", "İn"]], "Yetişkinin yayı yok")
	_steps(player, Vector2(1.0, 0.0), true, 3.0)
	assert_eq(player.mount_gait(), "gallop")
	assert_true(player.interact())
	_steps(player, Vector2.ZERO, false, 2.0)
	assert_eq(player.get_stance(), PlayerController.Stance.FOOT)
	# Koyuna yetişkin binmez.
	var sheep := SHEEP_SCENE.instantiate() as RideableSheep
	add_child(sheep)
	_trash.append(sheep)
	sheep.place(player.global_position + Vector3(0.8, 0.0, 0.0), 0.0)
	await wait_frames(1)
	assert_true(player.mount_in_reach() != sheep, "Yetişkine koyun erimde sayılmaz")


func test_second_horse_is_rideable_and_horses_block_the_way() -> void:
	var brown := _make_horse(BROWN, Vector3(0.0, 0.0, 0.0), 0.0)
	var white := _make_horse(WHITE, Vector3(3.0, 0.0, 0.0), 0.0)
	var player := await _make_rider(true)
	# Yerde atın gövdesinden geçilmez.
	player.spawn_at(Vector3(-1.5, 0.0, 0.0), PI * 0.5)
	_steps(player, Vector2(1.0, 0.0), false, 2.5)
	assert_true(player.global_position.x < -0.3, "Atın böğründen geçilmez (x %.2f)" % player.global_position.x)
	player.spawn_at(Vector3(1.6, 0.0, 0.2), 0.0)
	var nearest := player.mount_in_reach()
	assert_true(nearest == brown or nearest == white)
	player.begin_mount(white)
	_steps(player, Vector2.ZERO, false, 3.0)
	assert_eq(player.riding_node(), white, "İkinci ata binilir")
	assert_true(white.ridden and not brown.ridden)
	# Binilen at ötekinin içinden geçmez.
	_steps(player, Vector2(-1.0, 0.0), false, 6.0)
	var gap := white.global_position.distance_to(brown.global_position)
	assert_true(gap > 0.6, "Atlar iç içe girmez (%.2f m)" % gap)
	player.interact()
	_steps(player, Vector2.ZERO, false, 2.0)
	assert_false(white.ridden)
	player.spawn_at(Vector3(-1.0, 0.0, -0.8), 0.0)
	player.begin_mount(brown)
	_steps(player, Vector2.ZERO, false, 3.0)
	assert_eq(player.riding_node(), brown, "Öteki ata da binilir")


func test_horse_of_a_hidden_world_is_neither_reached_nor_in_the_way() -> void:
	# Çocukluk'ta kamp gizlenir ama ağaçta kalır (CineHost.release_camp): atları binekler grubundadır.
	var camp := Node3D.new()
	add_child(camp)
	_trash.append(camp)
	var horse := RideableHorse.new()
	horse.model_path = BROWN
	camp.add_child(horse)
	horse.place(Vector3.ZERO, 0.0)
	var player := await _make_rider(true)
	player.spawn_at(Vector3(1.2, 0.0, 0.0), 0.0)
	assert_eq(player.mount_in_reach(), horse, "Görünürken erimde")
	camp.visible = false
	assert_null(player.mount_in_reach(), "Gizli dünyanın atına binilmez")
	assert_false(player.interact(), "E bir şey yapmaz")
	player.spawn_at(Vector3(-1.5, 0.0, 0.0), PI * 0.5)
	_steps(player, Vector2(1.0, 0.0), false, 2.5)
	assert_true(player.global_position.x > 0.5, "Gizli at yolu kesmez (x %.2f)" % player.global_position.x)


# --- Ahır --------------------------------------------------------------------------------------------

func test_stable_is_closed_on_three_sides_and_open_in_front() -> void:
	MeshyProp.models_enabled = true
	var stable := Stable.new()
	add_child(stable)
	_trash.append(stable)
	await wait_frames(1)
	if not stable.uses_model():
		assert_true(true, "Ahır modeli yok")
		return
	var walls := stable.get_node_or_null(^"Walls") as MeshInstance3D
	assert_not_null(walls, "Yan duvarlar kurulur")
	var box := walls.get_aabb()
	assert_true(box.size.x > 4.5 and box.size.z > 3.5 and box.size.y > 1.7, "İki yan duvar tabanı boydan boya örter: %s" % box)
	assert_eq(stable.get_obstacle_boxes().size(), 3, "Arka ve iki yan duvar çarpışır")
	assert_eq(stable.get_collision_circles().size(), 4, "Çarpışma yalnız köşe direkleri: içeri girilir")
	assert_false(stable.get_obstacle_circles().is_empty(), "Çimen ve patika bütün tabandan uzak durur")
	var player := await _make_rider(true)
	player.obstacles.assign(stable.get_collision_circles())
	player.boxes.assign(stable.get_obstacle_boxes())
	# Ön ağızdan girilir.
	player.spawn_at(Vector3(0.0, 0.0, 4.0), PI)
	_steps(player, Vector2(0.0, 1.0), false, 3.0)
	assert_true(player.global_position.z < 0.5, "Önden içeri girer (z %.2f)" % player.global_position.z)
	# Yan duvardan geçilmez (içeriden dışarı da, dışarıdan içeri de).
	player.spawn_at(Vector3(0.0, 0.0, 0.0), PI * 0.5)
	_steps(player, Vector2(1.0, 0.0), false, 4.0)
	assert_true(player.global_position.x < 2.4, "Sağ duvardan çıkılmaz (x %.2f)" % player.global_position.x)
	player.spawn_at(Vector3(-4.0, 0.0, 0.0), PI * 0.5)
	_steps(player, Vector2(1.0, 0.0), false, 4.0)
	assert_true(player.global_position.x < -2.6, "Sol duvardan girilmez (x %.2f)" % player.global_position.x)
	player.spawn_at(Vector3(0.0, 0.0, -4.0), 0.0)
	_steps(player, Vector2(0.0, -1.0), false, 4.0)
	assert_true(player.global_position.z < -1.9, "Arka duvardan girilmez (z %.2f)" % player.global_position.z)
	# Atla da duvardan çıkılmaz, ağızdan çıkılır.
	var horse := _make_horse(BROWN, Vector3(0.0, 0.0, 0.0), PI * 0.5)
	player.spawn_at(Vector3(0.0, 0.0, 1.0), 0.0)
	player.begin_mount(horse)
	_steps(player, Vector2.ZERO, false, 3.0)
	assert_true(player.is_riding())
	_steps(player, Vector2(1.0, 0.0), true, 4.0)
	assert_true(horse.global_position.x < 2.0, "At yan duvardan çıkmaz (x %.2f)" % horse.global_position.x)
	_steps(player, Vector2(0.0, -1.0), false, 6.0)
	assert_true(horse.global_position.z > 3.0, "At ön ağızdan çıkar (z %.2f)" % horse.global_position.z)


func test_camp_horses_are_rideable_rigged_horses() -> void:
	var horse := Horse.new()
	add_child(horse)
	_trash.append(horse)
	await wait_frames(1)
	if not Horse.has_rigged_model(horse.resolved_model_id()):
		assert_true(true, "İskeletli model yok")
		return
	var ride := horse.rideable()
	assert_not_null(ride, "Kampın atı binilebilir")
	assert_true(horse.uses_model())
	assert_eq(ride.mount_kind(), "horse")
	var aabb := CharacterAvatar.rest_bounds(ride.get_node("Body/HorseModel"))
	assert_almost(aabb.size.z, Horse.MODEL_LENGTH, 0.02, "Burundan kuyruğa 2,3 m (eski boyu)")
	assert_between(aabb.size.y, 1.5, 2.1, "At boyu")


# --- Kamera ve ses -----------------------------------------------------------------------------------

func test_camera_widens_only_a_little_and_only_at_riding_speed() -> void:
	assert_almost(FollowCamera.speed_widen(0.0), 0.0, 0.0001)
	assert_almost(FollowCamera.speed_widen(4.6), 0.0, 0.0001, "Yürüyüş ve koşuda değişmez")
	assert_almost(FollowCamera.speed_widen(10.5), FollowCamera.SPEED_WIDEN_DEG, 0.0001, "Dörtnalda tam")
	assert_true(FollowCamera.SPEED_WIDEN_DEG <= 3.0, "Çok hafif (K98: kadraj uzak ve yüksek kalır)")
	assert_true(FollowCamera.DEFAULT_FOV + FollowCamera.SPEED_WIDEN_DEG <= 40.0, "Görüş 30–40° içinde kalır")
	var cam := FollowCamera.new()
	var target := SpeedProbe.new()
	add_child(target)
	_trash.append(target)
	cam.target = target
	add_child(cam)
	_trash.append(cam)
	await wait_frames(1)
	var pitch := cam.current_pitch()
	target.speed = 10.5
	for i in 600:
		cam.update_camera(DT)
	assert_almost(cam.get_widen(), FollowCamera.SPEED_WIDEN_DEG, 0.05, "Dörtnalda genişler")
	assert_almost(cam.camera.fov, cam.fov + FollowCamera.SPEED_WIDEN_DEG, 0.05)
	assert_almost(cam.current_pitch(), pitch, 0.0001, "Eğim değişmez")
	target.speed = 0.0
	for i in 600:
		cam.update_camera(DT)
	assert_almost(cam.get_widen(), 0.0, 0.05, "Durunca eski açısına döner")


class SpeedProbe:
	extends Node3D
	var speed := 0.0

	func get_speed() -> float:
		return speed


func test_hoof_sound_is_a_short_dull_strike() -> void:
	var rng := SynthDsp.make_rng(4411)
	var out := SynthHoof.render({"seconds": 0.26, "rate": 22050}, rng)
	assert_eq(out.size(), int(0.26 * 22050))
	assert_almost(SynthDsp.peak(out), SynthHoof.LEVEL, 0.001, "Tepe ölçülü")
	var early := SynthDsp.rms(out, 0, int(0.06 * 22050))
	var late := SynthDsp.rms(out, int(0.12 * 22050), out.size())
	assert_true(early > late * 8.0, "Kısa vuruş: enerjisi ilk 60 ms'de (%.3f / %.3f)" % [early, late])
	for path in RideEffects.SOUNDS:
		assert_true(ResourceLoader.exists(path), "%s basılmış (tools/bake_music.sh --only=hoof_a,hoof_b,hoof_c)" % path)


# --- Yardımcılar -------------------------------------------------------------------------------------

func _make_horse(path: String, at: Vector3, yaw: float) -> RideableHorse:
	var horse := RideableHorse.new()
	horse.model_path = path
	add_child(horse)
	_trash.append(horse)
	horse.place(at, yaw)
	return horse


func _make_rider(child: bool) -> PlayerController:
	var player := PlayerController.new()
	player.terrain_shape = FlatShape.new()
	player.start_active = false
	var avatar := CharacterAvatar.new()
	player.add_child(avatar)
	add_child(player)
	_trash.append(player)
	player.set_process(false)
	await wait_frames(1)
	player.obstacles = []
	if child:
		player.use_child(ChildLook.PERSON_CHILD)
	else:
		var profile := CharacterProfile.new()
		player.use_profile(profile)
	player.set_active(true)
	return player


func _steps(player: PlayerController, input: Vector2, sprint: bool, seconds: float) -> void:
	for i in int(round(seconds / DT)):
		player.step(DT, input, sprint, 0.0)


func _drive(horse: RideableHorse, anim: AnimationPlayer, speed: float, seconds: float) -> void:
	for i in int(round(seconds / DT)):
		horse.drive(speed, DT)
		anim.advance(DT)
		if horse.effects():
			horse.effects()._process(DT)
