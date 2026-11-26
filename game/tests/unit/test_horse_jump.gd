extends TestCase
## Atla sıçrama (2026-11-08; Boşluk sırttayken: PlayerController.jump → Rideable.leap, Mount.jump_plan; klip tools/blender/quadruped_rig.py pose_jump):
## satırın planı (durarak kısa ve alçak, tırısta ve dörtnalda ileri doğru uzun; koyun sıçramaz), modelin bir kez oynayan jump klibi ve evreleri, sıçrayışın
## yüksekliği ve havada kalışı, binicinin attan kopmaması (kalça eyerde, atla kalkar ve iner), düğümün ve kameranın yerde kalması (sarsılmaz), havada
## dönüşün azalması, havada inilememesi, nişanla sıçramanın birbirini bozmaması, kalkış ve inişin tozu ve toynak sesi, modelsiz atın da sıçraması.
## Gerçek klavye yok: step(), jump(), interact() doğrudan; at ve çocuk gerçek modellerdir (assets/animals/horse_*, assets/characters/child).

const DT := 1.0 / 60.0
const BROWN := "res://assets/animals/horse_brown/horse_brown.glb"
const WHITE := "res://assets/animals/horse_white/horse_white.glb"


class FlatShape:
	extends TerrainShape
	var level := 0.0

	func height_at(_x: float, _z: float) -> float:
		return level


## Bir sıçrayışın ölçüsü (_leap_through doldurur).
class LeapLog:
	var seconds := 0.0
	var takeoff := -1.0
	var touchdown := -1.0
	var peak_lift := 0.0
	var peak_rider := -INF
	var rider_rest := 0.0
	var hips_gap := Vector2(INF, -INF)
	var node_y := Vector2(INF, -INF)
	var start := Vector3.ZERO
	var at_takeoff := Vector3.ZERO
	var at_touchdown := Vector3.ZERO
	var yaw_takeoff := 0.0
	var yaw_touchdown := 0.0
	var speed_takeoff := 0.0
	var speed_touchdown := 0.0
	var phases: Array[int] = []


var _trash: Array[Node] = []


func before_each() -> void:
	Mount.reset_cache()


func after_each() -> void:
	for node in _trash:
		if is_instance_valid(node):
			node.queue_free()
	_trash.clear()


# --- Satır ve klip -------------------------------------------------------------------------------------

func test_horse_row_plans_short_standing_and_long_running_leaps_and_sheep_does_not_leap() -> void:
	var horse := Mount.new("horse")
	assert_true(horse.can_jump(), "Atın satırı sıçrar")
	assert_false(Mount.new("sheep").can_jump(), "Koyun sıçramaz: binicisini taşır")
	assert_true(Mount.new("sheep").jump_plan(2.0).is_empty())
	var stand := horse.jump_plan(0.0)
	var walk := horse.jump_plan(horse.walk_speed())
	var trot := horse.jump_plan(horse.trot_speed())
	var gallop := horse.jump_plan(horse.gallop_speed())
	assert_false(bool(stand["running"]) or bool(walk["running"]), "Duruşta ve adımda durarak sıçrar (toplanır)")
	assert_true(bool(trot["running"]) and bool(gallop["running"]), "Tırısta ve dörtnalda koşarak")
	assert_between(float(stand["height"]), 0.2, 0.4, "Durarak alçak (%.2f m)" % stand["height"])
	assert_true(float(trot["height"]) > float(stand["height"]) + 0.15 and float(gallop["height"]) >= float(trot["height"]), "Koşarak yüksek")
	assert_true(float(gallop["air_s"]) > float(stand["air_s"]) + 0.1, "Dörtnalda havada uzun kalır")
	assert_true(float(trot["air_s"]) * horse.trot_speed() > 2.0, "Tırısta ileri doğru uzun (%.1f m)" % (float(trot["air_s"]) * horse.trot_speed()))
	assert_true(float(gallop["air_s"]) * horse.gallop_speed() > 6.0, "Dörtnalda daha da uzun (%.1f m)" % (float(gallop["air_s"]) * horse.gallop_speed()))
	assert_true(float(stand["prep_s"]) > float(gallop["prep_s"]), "Durarak toplanma uzun, koşarak kısa")
	assert_between(float(gallop["air_turn"]), 0.05, 0.6, "Havada dönüş azalır")
	assert_between(float(gallop["land_keep"]), 0.6, 1.0, "İnişte hız biraz düşer")
	for plan: Dictionary in [stand, trot, gallop]:
		assert_between(float(plan["gravity"]), 7.0, 14.0, "Yayın yerçekimi doğal (%.1f m/sn²)" % plan["gravity"])
	# Üç değerli alanın ara hızları doğrusaldır.
	assert_almost(Mount.by_speed([0.3, 0.6, 0.8], 2.0, 4.0, 10.0), 0.45, 0.0001)
	assert_almost(Mount.by_speed([0.3, 0.6, 0.8], 7.0, 4.0, 10.0), 0.7, 0.0001)
	assert_almost(Mount.by_speed([0.3, 0.6, 0.8], 14.0, 4.0, 10.0), 0.8, 0.0001, "Dörtnalın ötesi son değer")
	assert_almost(Mount.by_speed([0.5], 9.0, 4.0, 10.0), 0.5, 0.0001)


func test_both_models_carry_a_one_shot_jump_clip_with_its_phases() -> void:
	for path in [BROWN, WHITE]:
		var meta := Rideable.read_meta(path)
		if meta.is_empty() or not ResourceLoader.exists(path):
			assert_true(true, "Model yok")
			continue
		var row: Dictionary = (meta["clips"] as Dictionary).get("jump", {})
		assert_false(row.is_empty(), "%s: jump klibinin ölçüsü" % path.get_file())
		assert_false(bool(row.get("loop", true)), "Bir kez oynar")
		var t: Dictionary = row["times"]
		assert_true(float(t["lift"]) < float(t["run_start"]) and float(t["run_start"]) < float(t["takeoff"]), "Ön kalkar, sonra arka iter")
		assert_true(float(t["takeoff"]) < float(t["touchdown"]) and float(t["touchdown"]) < float(t["hind_down"]), "Önce ön, sonra arka iner")
		assert_true(float(t["hind_down"]) < float(row["length_s"]), "Toparlanma klibin içinde")
		var horse := _make_horse(path, Vector3.ZERO, 0.0)
		var anim := _anim(horse)
		assert_true(anim.has_animation(&"jump"), "Oynatıcıda jump")
		assert_eq(anim.get_animation(&"jump").loop_mode, Animation.LOOP_NONE, "Sıçrama döngüsüz")
		for clip in ["idle", "walk", "trot", "gallop"]:
			assert_eq(anim.get_animation(clip).loop_mode, Animation.LOOP_LINEAR, "%s yine döngülü" % clip)
		assert_true(horse.can_leap())


# --- Sıçrayış ------------------------------------------------------------------------------------------

func test_standing_leap_is_short_and_low_and_the_rider_goes_up_with_the_horse() -> void:
	var horse := _make_horse(BROWN, Vector3.ZERO, 0.0)
	var player := await _ride(horse)
	var jumped := watch_signal(player.jumped)
	var landed := watch_signal(player.landed)
	assert_true(player.jump(), "Boşluk: at sıçrar")
	assert_true(player.is_jumping() and horse.is_leaping())
	assert_false(player.is_airborne(), "Önce toplanır")
	assert_false(player.jump(), "Sıçrarken yeniden sıçranmaz")
	assert_eq(player.get_stance(), PlayerController.Stance.RIDING, "Binici sırtta kalır")
	var plan := horse.leap_plan()
	var log := _leap_through(player, horse, Vector2.ZERO, false)
	assert_false(horse.is_leaping(), "Sıçrayış biter")
	assert_eq(jumped.count, 1, "Kalkış bir kez")
	assert_eq(landed.count, 1, "İniş bir kez")
	assert_between(log.takeoff, 0.2, 0.4, "Toplanma (%.2f sn)" % log.takeoff)
	assert_almost(log.touchdown - log.takeoff, float(plan["air_s"]), 0.04, "Havada kalış planınki (%.2f sn)" % (log.touchdown - log.takeoff))
	assert_almost(log.peak_lift, float(plan["height"]), 0.03, "Yay planın yüksekliği (%.2f m)" % log.peak_lift)
	assert_between(log.peak_lift, 0.2, 0.4, "Durarak alçak")
	var flight := _flat(log.at_touchdown - log.at_takeoff)
	assert_between(flight, 0.6, 2.0, "Durarak kısa: ileri biraz fırlar (%.2f m)" % flight)
	assert_between(log.seconds, 0.9, 1.6, "Bütün sıçrayış (%.2f sn)" % log.seconds)
	# Binici atla kalkar: kalça eyerde kalır, yükseklik yayla artar.
	assert_true(log.peak_rider > log.rider_rest + log.peak_lift * 0.8, "Binici atla kalkar (%.2f → %.2f)" % [log.rider_rest, log.peak_rider])
	assert_between(log.hips_gap.x, -0.02, 0.4, "Kalça hep eyerin üstünde (en az %.2f m)" % log.hips_gap.x)
	assert_between(log.hips_gap.y, -0.02, 0.4, "Kalça eyerden kopmaz (en çok %.2f m)" % log.hips_gap.y)
	# Düğüm (kameranın izlediği) yerde kalır.
	assert_almost(log.node_y.x, 0.0, 0.0001, "Düğüm yerde: kamera sarsılmaz")
	assert_almost(log.node_y.y, 0.0, 0.0001)
	_steps(player, Vector2.ZERO, false, 0.6)
	assert_almost(player.get_speed(), 0.0, 0.01, "Durur")
	assert_eq(horse.gait_role(), &"idle", "Beklemeye döner")
	assert_almost(horse.leap_lift(), 0.0, 0.0001)
	assert_almost(horse.get_node("Body").position.y, 0.0, 0.0001, "Gövde yerinde")


func test_galloping_leap_flies_far_keeps_its_speed_and_turns_little_in_the_air() -> void:
	var horse := _make_horse(BROWN, Vector3.ZERO, 0.0)
	var player := await _ride(horse)
	var cam := FollowCamera.new()
	cam.target = player
	cam.terrain_shape = player.terrain_shape
	add_child(cam)
	_trash.append(cam)
	_steps(player, Vector2(0.0, 1.0), true, 3.0)
	assert_eq(player.mount_gait(), "gallop")
	var gallop := player.get_speed()
	for i in 30:
		cam.update_camera(DT)
	var cam_y := cam.camera.global_position.y
	assert_true(player.jump())
	var plan := horse.leap_plan()
	assert_true(bool(plan["running"]), "Koşarak sıçrar")
	# Havada sağa çekilir: yön az değişir.
	var log := _leap_through(player, horse, Vector2(0.0, 1.0), true, Vector2(1.0, 0.0), cam)
	assert_between(log.takeoff, 0.08, 0.2, "Koşarak hemen kalkar (%.2f sn)" % log.takeoff)
	assert_almost(log.touchdown - log.takeoff, float(plan["air_s"]), 0.04, "Havada kalış (%.2f sn)" % (log.touchdown - log.takeoff))
	assert_between(log.peak_lift, 0.6, 0.9, "Dörtnalda yüksek (%.2f m)" % log.peak_lift)
	var flight := _flat(log.at_touchdown - log.at_takeoff)
	assert_between(flight, 6.0, 9.0, "Dörtnalda ileri doğru uzun (%.2f m)" % flight)
	assert_almost(log.speed_takeoff, gallop, 0.3, "Hız korunur")
	assert_almost(log.speed_touchdown, gallop, 0.3, "Havada hız değişmez")
	var air_turn := absf(angle_difference(log.yaw_takeoff, log.yaw_touchdown))
	assert_true(air_turn < deg_to_rad(20.0), "Havada az döner (%.1f°)" % rad_to_deg(air_turn))
	# Aynı süre yerde dörtnalda sağa çekmek çok daha çok döndürür.
	var yaw := player.get_facing_yaw()
	_steps(player, Vector2(1.0, 0.0), true, log.touchdown - log.takeoff)
	var ground_turn := absf(angle_difference(yaw, player.get_facing_yaw()))
	assert_true(ground_turn > air_turn * 2.0, "Yerde daha çok döner (%.1f° / %.1f°)" % [rad_to_deg(ground_turn), rad_to_deg(air_turn)])
	assert_between(log.hips_gap.x, -0.02, 0.4, "Kalça eyerde (%.2f)" % log.hips_gap.x)
	assert_between(log.hips_gap.y, -0.02, 0.4, "Binici kopmaz (%.2f)" % log.hips_gap.y)
	assert_true(log.peak_rider > log.rider_rest + 0.5, "Binici yükselir (%.2f → %.2f)" % [log.rider_rest, log.peak_rider])
	assert_almost(log.node_y.y - log.node_y.x, 0.0, 0.0001, "Düğüm yerde")
	assert_almost(cam.camera.global_position.y, cam_y, 0.02, "Kamera sarsılmaz (yükseklik %.3f → %.3f)" % [cam_y, cam.camera.global_position.y])
	# İnişten sonra dörtnal sürer.
	_steps(player, Vector2(0.0, 1.0), true, 1.0)
	assert_eq(horse.gait_role(), &"gallop", "Dörtnala döner")
	assert_almost(player.get_speed(), gallop, 0.2, "Hız yerine gelir")


func test_trotting_leap_goes_forward_and_lands_into_the_trot() -> void:
	# Ön yüzü girişin yönünde (-Z): dönmeden tırısa kalkar.
	var horse := _make_horse(WHITE, Vector3.ZERO, PI)
	var player := await _ride(horse)
	_steps(player, Vector2(0.0, 1.0), true, 0.85)
	assert_eq(player.mount_gait(), "trot")
	var trot := player.get_speed()
	assert_true(player.jump())
	assert_true(bool(horse.leap_plan()["running"]), "Tırısta koşarak sıçrar (%.1f m/sn)" % trot)
	var log := _leap_through(player, horse, Vector2(0.0, 1.0), true)
	var flight := _flat(log.at_touchdown - log.at_takeoff)
	assert_between(flight, 1.8, 3.5, "Tırısta ileri (%.2f m)" % flight)
	assert_between(log.peak_lift, 0.45, 0.75, "Tırısta orta yükseklik (%.2f m)" % log.peak_lift)
	assert_true(log.speed_takeoff > trot * 0.9, "Tırıs hızıyla kalkar")
	assert_between(log.hips_gap.y, -0.02, 0.4, "Binici kopmaz")
	_steps(player, Vector2(0.0, 1.0), true, 0.4)
	assert_true(horse.gait_role() == &"trot" or horse.gait_role() == &"gallop", "Koşu sürer (%s)" % horse.gait_role())


func test_no_dismount_while_leaping_but_after_landing() -> void:
	var horse := _make_horse(BROWN, Vector3.ZERO, 0.0)
	var player := await _ride(horse)
	assert_true(player.jump())
	var tried := 0
	var t := 0.0
	while horse.is_leaping() and t < 3.0:
		if player.has_interaction() == false:
			fail("Sıçrarken E'nin işi var sayılır: kamera E ile dönmez")
		assert_false(player.interact(), "Sıçrarken E inmez (%s)" % ["hazırlık", "hava", "iniş"][int(horse.leap_phase()) - 1])
		player.begin_dismount()
		assert_eq(player.get_stance(), PlayerController.Stance.RIDING, "Havada inilmez")
		tried += 1
		_steps(player, Vector2.ZERO, false, DT)
		t += DT
	assert_true(tried > 30, "Bütün sıçrayış boyunca denendi (%d kare)" % tried)
	assert_eq(player.riding_node(), horse)
	assert_true(player.interact(), "İnince E iner")
	_steps(player, Vector2.ZERO, false, 2.0)
	assert_eq(player.get_stance(), PlayerController.Stance.FOOT)
	assert_false(horse.ridden)


func test_aim_and_leap_do_not_break_each_other() -> void:
	var horse := _make_horse(BROWN, Vector3.ZERO, 0.0)
	var player := await _ride(horse)
	var archer := player.archer()
	archer.aim_override = player.global_position + Vector3(2.0, 0.0, 10.0)
	# Nişanda at adımlar (koşu tuşu nişanda hız vermez): nişandaki sıçrayış durarak olur.
	_steps(player, Vector2(0.0, 1.0), false, 0.5)
	assert_true(player.begin_aim(), "Sırtta nişan")
	_steps(player, Vector2(0.0, 1.0), false, 0.6)
	var seat_y := archer.launch_point().y
	assert_true(player.jump(), "Nişandayken de at sıçrar")
	assert_true(player.is_aiming(), "Sıçrayış nişanı bırakmaz")
	var t := 0.0
	while not horse.is_airborne() and t < 1.0:
		_steps(player, Vector2(0.0, 1.0), false, DT)
		t += DT
	assert_true(player.is_aiming(), "Toplanırken nişan sürer")
	while horse.is_airborne() and horse.leap_lift() < float(horse.leap_plan()["height"]) * 0.9 and t < 2.0:
		_steps(player, Vector2(0.0, 1.0), false, DT)
		t += DT
	assert_true(horse.is_airborne() and player.is_aiming(), "Havada nişan sürer")
	var shots := archer.field.pool.shots.size()
	var loosed := watch_signal(archer.loosed)
	player.release_aim()
	while loosed.count == 0 and t < 3.0:
		_steps(player, Vector2(0.0, 1.0), false, DT)
		t += DT
	assert_eq(loosed.count, 1, "Havada ok atılır")
	assert_eq(archer.field.pool.shots.size(), shots + 1)
	var from: Vector3 = loosed.last_args[0]
	assert_true(from.y > seat_y + 0.15, "Ok havadaki binicinin elinden çıkar (%.2f, yerde %.2f)" % [from.y, seat_y])
	assert_eq(player.get_stance(), PlayerController.Stance.RIDING)
	while horse.is_leaping() and t < 4.0:
		_steps(player, Vector2(0.0, 1.0), false, DT)
		t += DT
	assert_false(horse.is_leaping(), "Sıçrayış nişandan etkilenmeden biter")
	assert_eq(player.get_stance(), PlayerController.Stance.RIDING)
	# Dörtnalda sıçrayıp havada nişana başlanır; inince nişan sürer.
	_steps(player, Vector2(0.0, 1.0), true, 2.5)
	assert_true(player.jump())
	while not horse.is_airborne() and t < 8.0:
		_steps(player, Vector2(0.0, 1.0), true, DT)
		t += DT
	_steps(player, Vector2(0.0, 1.0), true, 0.15)
	assert_true(horse.is_airborne())
	assert_true(player.begin_aim(), "Havada nişana başlanır")
	while horse.is_leaping() and t < 10.0:
		_steps(player, Vector2(0.0, 1.0), true, DT)
		t += DT
	assert_true(player.is_aiming(), "İnişte nişan bırakılmaz")
	player.release_aim()
	_steps(player, Vector2(0.0, 1.0), true, 0.3)
	assert_false(player.is_aiming())


func test_takeoff_and_landing_raise_dust_and_hoof_strikes() -> void:
	var horse := _make_horse(BROWN, Vector3.ZERO, 0.0)
	var player := await _ride(horse)
	var effects := horse.effects()
	assert_not_null(effects)
	_steps(player, Vector2(0.0, 1.0), true, 2.5)
	for i in int(1.5 / DT):
		effects._process(DT)
	var strikes := horse.strikes
	assert_true(player.jump())
	var t := 0.0
	var dust_air := 0
	while horse.is_leaping() and t < 3.0:
		_steps(player, Vector2(0.0, 1.0), true, DT)
		effects._process(DT)
		if horse.is_airborne():
			dust_air = maxi(dust_air, effects.dust_count)
		t += DT
	assert_true(dust_air >= 2, "Kalkışta arka toynaklar toz kaldırır (%d)" % dust_air)
	assert_true(horse.strikes - strikes >= 6, "Kalkışta iki, inişte dört vuruş (%d)" % (horse.strikes - strikes))
	assert_true(effects.dust_count >= 6, "İnişte toz kalkar (%d)" % effects.dust_count)
	assert_true(effects.print_count > 0, "İz kalır")
	assert_not_null(effects.get_node_or_null(^"Hooves") as AudioStreamPlayer3D, "Toynak sesi")
	assert_true(RideEffects.VOLUME_DB[&"land"] > RideEffects.VOLUME_DB[&"gallop"], "İniş dörtnal vuruşundan yüksek")
	assert_true(RideEffects.STRENGTH[&"land"] >= RideEffects.STRENGTH[&"gallop"], "İnişin tozu dörtnalınkinden az değil")
	for path in RideEffects.LAND_SOUNDS:
		assert_true(ResourceLoader.exists(path), "%s basılmış (tools/bake_music.sh --only=hoof_land_a,hoof_land_b)" % path)
	assert_not_null(effects.get_node_or_null(^"Landing") as AudioStreamPlayer3D, "İnişin gümlemesi")


func test_horse_without_a_model_leaps_by_code_and_the_sheep_never_leaps() -> void:
	var horse := RideableHorse.new()
	add_child(horse)
	_trash.append(horse)
	horse.place(Vector3.ZERO, 0.0)
	assert_false(horse.uses_model())
	var player := await _ride(horse)
	var seat := horse.seat_transform().origin.y
	assert_true(player.jump(), "Modelsiz at da sıçrar")
	var peak := -INF
	var t := 0.0
	while horse.is_leaping() and t < 3.0:
		_steps(player, Vector2.ZERO, false, DT)
		peak = maxf(peak, horse.seat_transform().origin.y)
		t += DT
	assert_false(horse.is_leaping())
	assert_almost(peak - seat, Mount.new("horse").jump_plan(0.0)["height"], 0.03, "Oturma noktası yayla kalkar (%.2f m)" % (peak - seat))
	assert_almost(horse.seat_transform().origin.y, seat, 0.001, "Yerine iner")
	# Koyun sıçramaz.
	var sheep := (load("res://scenes/fauna/rideable_sheep.tscn") as PackedScene).instantiate() as RideableSheep
	add_child(sheep)
	_trash.append(sheep)
	sheep.place(Vector3(6.0, 0.0, 0.0), 0.0)
	assert_false(sheep.can_leap(), "Koyun sıçramaz")
	assert_false(sheep.leap(2.0))
	assert_false(sheep.is_leaping())


func test_adult_rider_leaps_the_same_way() -> void:
	var horse := _make_horse(WHITE, Vector3.ZERO, PI)
	var player := await _ride(horse, false)
	assert_false(player.is_child())
	_steps(player, Vector2(0.0, 1.0), true, 3.0)
	assert_eq(player.mount_gait(), "gallop")
	assert_true(player.jump(), "Yetişkinle de at sıçrar")
	var log := _leap_through(player, horse, Vector2(0.0, 1.0), true)
	assert_between(log.peak_lift, 0.6, 0.9, "Dörtnalda yüksek (%.2f m)" % log.peak_lift)
	assert_between(log.hips_gap.x, -0.02, 0.45, "Yetişkinin kalçası eyerde (%.2f)" % log.hips_gap.x)
	assert_between(log.hips_gap.y, -0.02, 0.45, "Yetişkin attan kopmaz (%.2f)" % log.hips_gap.y)
	assert_true(log.peak_rider > log.rider_rest + 0.5, "Yetişkin atla kalkar")


func test_leap_ends_cleanly_when_the_rider_is_taken_off() -> void:
	var horse := _make_horse(BROWN, Vector3.ZERO, 0.0)
	var player := await _ride(horse)
	_steps(player, Vector2(0.0, 1.0), true, 2.0)
	assert_true(player.jump())
	var t := 0.0
	while not horse.is_airborne() and t < 1.0:
		_steps(player, Vector2(0.0, 1.0), true, DT)
		t += DT
	_steps(player, Vector2(0.0, 1.0), true, 0.2)
	assert_true(horse.leap_lift() > 0.2)
	player.spawn_at(Vector3(5.0, 0.0, 5.0), 0.0)
	assert_false(horse.is_leaping(), "Binici alınınca sıçrayış biter")
	assert_almost(horse.get_node("Body").position.y, 0.0, 0.0001, "Gövde yere iner")
	assert_false(player.is_jumping())
	assert_almost(player.get_avatar().position.y, 0.0, 0.0001, "Binici yerde")


# --- Yardımcılar ---------------------------------------------------------------------------------------

## Sıçrayışı sonuna dek sürer ve ölçer: kalkış ve iniş anı, yayın ve binicinin tepesi, kalçanın eyere uzaklığı, düğümün yüksekliği, yer ve yön.
## air_input verilirse havada o giriş (yönü çekmek için) kullanılır.
func _leap_through(player: PlayerController, horse: RideableHorse, input: Vector2, sprint: bool, air_input := Vector2.INF, cam: FollowCamera = null) -> LeapLog:
	var log := LeapLog.new()
	var anim := _anim(horse)
	log.start = player.global_position
	log.rider_rest = _hips_y(player)
	var t := 0.0
	while horse.is_leaping() and t < 4.0:
		var use := air_input if air_input != Vector2.INF and horse.is_airborne() else input
		player.step(DT, use, sprint, 0.0)
		if anim:
			anim.advance(DT)
		if cam:
			cam.update_camera(DT)
		t += DT
		if horse.is_airborne() and log.takeoff < 0.0:
			log.takeoff = t
			log.at_takeoff = player.global_position
			log.yaw_takeoff = player.get_facing_yaw()
			log.speed_takeoff = player.get_speed()
		if log.takeoff >= 0.0 and log.touchdown < 0.0 and not horse.is_airborne():
			log.touchdown = t
			log.at_touchdown = player.global_position
			log.yaw_touchdown = player.get_facing_yaw()
			log.speed_touchdown = player.get_speed()
		log.peak_lift = maxf(log.peak_lift, horse.leap_lift())
		var hips := _hips_y(player)
		log.peak_rider = maxf(log.peak_rider, hips)
		var gap := hips - horse.seat_transform().origin.y
		log.hips_gap = Vector2(minf(log.hips_gap.x, gap), maxf(log.hips_gap.y, gap))
		log.node_y = Vector2(minf(log.node_y.x, player.global_position.y), maxf(log.node_y.y, player.global_position.y))
		log.phases.append(int(horse.leap_phase()))
	log.seconds = t
	return log


func _make_horse(path: String, at: Vector3, yaw: float) -> RideableHorse:
	var horse := RideableHorse.new()
	horse.model_path = path
	add_child(horse)
	_trash.append(horse)
	horse.place(at, yaw)
	return horse


## Çocuğu (child false: yetişkini) atın yanına koyar ve bindirir (biniş biter).
func _ride(horse: RideableHorse, child: bool = true) -> PlayerController:
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
	# Dörtnal uzun yol alır: oyun alanının kenarı frenlemesin.
	player.play_area_radius = 1000.0
	if child:
		player.use_child(ChildLook.PERSON_CHILD)
	else:
		player.use_profile(CharacterProfile.new())
	player.set_active(true)
	var side := Vector3(cos(horse.rotation.y), 0.0, -sin(horse.rotation.y)) * 1.3
	player.spawn_at(horse.global_position + side, horse.rotation.y)
	player.begin_mount(horse)
	_steps(player, Vector2.ZERO, false, 3.0)
	assert_true(player.is_riding(), "Biner")
	return player


func _steps(player: PlayerController, input: Vector2, sprint: bool, seconds: float) -> void:
	for i in maxi(int(round(seconds / DT)), 1):
		player.step(DT, input, sprint, 0.0)


func _anim(horse: RideableHorse) -> AnimationPlayer:
	var model := horse.get_node_or_null(^"Body/HorseModel")
	if model == null:
		return null
	var players := model.find_children("*", "AnimationPlayer", true, false)
	return players[0] as AnimationPlayer if not players.is_empty() else null


## Binicinin kalça kemiğinin dünya yüksekliği (iskelet yoksa avatarın kökü).
func _hips_y(player: PlayerController) -> float:
	var skeleton := player.get_avatar().get_skeleton()
	if skeleton == null:
		return player.get_avatar().global_position.y
	return (skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("Hips")).origin).y


func _flat(v: Vector3) -> float:
	return Vector2(v.x, v.z).length()
