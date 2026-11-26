extends TestCase
## Çocuk denetleyicisi (K37, story.md §5, godot.md §9.4): küçük Mete ve Serbest Gez'in Çocuğu aynı yürüyüşü, koşuyu, binmeyi ve yayı paylaşır. Gerçek klavye yok: step(), interact(),
## begin_aim(), release_aim() ve _unhandled_input doğrudan çağrılır. Hedef sahtedir (TargetDummy; küçük avın sözleşmesiyle aynı adlar). Sahne sınamalarının çoğu chibi yedeğiyle koşar (hızlı);
## binme ve yay pozu gerçek modellerle (mete_child, child) kemiklerden ölçülür.

const DT := 1.0 / 60.0
const SHEEP_SCENE := preload("res://scenes/fauna/rideable_sheep.tscn")
const TempDir := preload("res://tests/support/temp_dir.gd")


class FlatShape:
	extends TerrainShape
	var level := 0.0

	func height_at(_x: float, _z: float) -> float:
		return level


var _trash: Array[Node] = []


func after_each() -> void:
	for node in _trash:
		if is_instance_valid(node):
			node.queue_free()
	_trash.clear()


# --- Çocuk kipi --------------------------------------------------------------------------------------

func test_child_walks_and_runs_at_her_own_speeds() -> void:
	var player := await _make_child()
	assert_true(player.is_child())
	assert_eq(player.person_id(), ChildLook.PERSON_CHILD)
	assert_almost(player.walk_speed, PlayerController.CHILD_WALK_SPEED, 0.001)
	assert_almost(player.run_speed, PlayerController.CHILD_RUN_SPEED, 0.001)
	_steps(player, Vector2(0.0, 1.0), false, 1.5)
	assert_almost(player.get_speed(), player.walk_speed, 0.01, "Yürür")
	_steps(player, Vector2(0.0, 1.0), true, 1.5)
	assert_almost(player.get_speed(), player.run_speed, 0.01, "Koşar")
	assert_almost(angle_difference(player.get_facing_yaw(), PI), 0.0, 0.03, "Gittiği yöne bakar")


func test_the_same_controller_shows_either_child() -> void:
	# Küçük Mete ve Çocuk aynı denetleyicide; kendi modelleri, ayak kaymaz: hız klibin sınırını aşmaz.
	for person: String in [ChildLook.PERSON_CHILD, ChildLook.PERSON_METE]:
		var player := await _make_child(person, true)
		var avatar := player.get_avatar()
		assert_eq(avatar.model_id, person, "%s kendi modeliyle" % person)
		assert_true(avatar.has_meshy_model())
		for role in [RidePose.ROLE, PlayerController.ROLE_RISE, PlayerController.ROLE_COLLECT, &"idle", &"walk", &"run", &"sit"]:
			assert_true(avatar.available_roles().has(role), "%s: %s klibi" % [person, role])
		assert_true(player.walk_speed <= avatar.clip_speed(&"walk") * CharacterAvatar.WALK_RATE_RANGE.y + 0.001, "%s: yürüme klibin hız sınırında" % person)
		assert_true(player.run_speed <= avatar.clip_speed(&"run") * CharacterAvatar.RUN_RATE_RANGE.y + 0.001, "%s: koşu klibin hız sınırında" % person)
		assert_true(player.walk_speed < player.run_speed)
		assert_true(player.walk_speed < 2.5 and player.run_speed > 2.5, "%s: koyunun tırısı yürümeyle koşu arasında" % person)
		_steps(player, Vector2(0.0, 1.0), false, 0.5)
		assert_eq(avatar.get_current_role(), &"walk", "%s yürür" % person)
		_steps(player, Vector2(0.0, 1.0), true, 0.8)
		assert_eq(avatar.get_current_role(), &"run", "%s koşar" % person)


func test_child_look_falls_back_to_the_child_model() -> void:
	var dir := TempDir.fresh("gorunus")
	var look := ChildLook.resolve("kimse_yok", dir)
	assert_eq(look["model"], ChildLook.PERSON_CHILD, "Modeli ve kaydı yok: çocuğun modeli yer tutar (K89)")
	assert_true(look["stand_in"])
	assert_almost(float(look["scale"]), ChildLook.FALLBACK_SCALE, 0.0001)
	assert_ne(look["tint"], Color.WHITE, "Çocuk'tan ayrılır")
	assert_eq(ChildLook.resolve(ChildLook.PERSON_METE)["model"], ChildLook.PERSON_METE, "Küçük Mete'nin kendi modeli geldi")
	assert_eq(ChildLook.resolve(ChildLook.PERSON_CHILD)["model"], ChildLook.PERSON_CHILD)
	TempDir.wipe(dir)


func test_use_profile_brings_the_adult_back() -> void:
	var player := await _make_child()
	var walk := player.walk_speed
	assert_almost(walk, PlayerController.CHILD_WALK_SPEED, 0.001)
	assert_not_null(player.archer())
	player.use_profile(CharacterProfile.new())
	assert_false(player.is_child())
	assert_null(player.archer(), "Yay kalkar")
	assert_almost(player.walk_speed, 1.8, 0.001, "Yetişkinin yürüyüşü")
	assert_almost(player.run_speed, 4.6, 0.001, "Yetişkinin koşusu")
	assert_almost(player.body_radius, 0.35, 0.001)
	assert_false(player.interact(), "Yetişkin E ile binmez")
	assert_false(player.begin_aim(), "Yetişkin yay atmaz")
	assert_eq(player.get_avatar().model_override, "", "Profilin modeli")


# --- Binme -------------------------------------------------------------------------------------------

func test_e_mounts_within_reach_only() -> void:
	var player := await _make_child()
	var sheep := await _make_sheep(Vector3(5.0, 0.0, 0.0))
	player.spawn_at(Vector3(0.0, 0.0, 0.0), 0.0)
	assert_false(player.has_interaction(), "Uzakta E'nin işi yok")
	assert_false(player.interact(), "Uzakta binilmez")
	assert_eq(player.get_stance(), PlayerController.Stance.FOOT)
	player.spawn_at(Vector3(4.2, 0.0, 0.0), 0.0)
	assert_true(player.has_interaction(), "Erimde")
	assert_eq(player.mount_in_reach(), sheep)
	var watcher := watch_signal(player.mounted)
	assert_true(player.interact(), "E ile biner")
	assert_eq(player.get_stance(), PlayerController.Stance.MOUNTING)
	assert_true(sheep.ridden)
	assert_null(player.mount_in_reach(), "Binilen binek bir daha seçilmez")
	var mid_height := 0.0
	var steps := 0
	while player.get_stance() == PlayerController.Stance.MOUNTING and steps < 120:
		player.step(DT, Vector2(1.0, 0.0), false, 0.0)
		mid_height = maxf(mid_height, player.get_avatar().global_position.y)
		steps += 1
	assert_eq(player.get_stance(), PlayerController.Stance.RIDING, "Geçiş biter, sırtta")
	assert_almost(steps * DT, Mount.new("sheep").value("mount_s"), 0.05, "Geçişin süresi")
	assert_true(watcher.fired)
	assert_true(player.is_riding())
	assert_eq(player.riding_node(), sheep)
	assert_vec_almost(player.global_position, sheep.global_position, 0.05, "Düğüm bineğin yerinde")
	assert_true(mid_height > 0.2, "Yerden kalkar")


func test_riding_trots_prods_to_gallop_and_carries_the_sheep() -> void:
	var player := await _make_child()
	var sheep := await _mount_up(player)
	var start := player.global_position
	_steps(player, Vector2(0.0, 1.0), false, 1.5)
	assert_almost(player.get_speed(), 2.5, 0.02, "Tırıs 2,5 m/sn")
	assert_true(player.global_position.distance_to(start) > 2.0, "Yürür")
	assert_vec_almost(sheep.global_position, player.global_position, 0.0001, "Koyun altında")
	assert_almost(angle_difference(player.get_facing_yaw(), PI), 0.0, 0.03, "Koyun gidilen yöne döner")
	assert_almost(angle_difference(sheep.global_rotation.y, PI), 0.0, 0.03, "Düğümü de")
	assert_true(sheep.gait_amplitude() > 0.3, "Bacaklar yürür")
	var phase := sheep.gait_phase()
	_steps(player, Vector2(0.0, 1.0), true, 1.5)
	assert_almost(player.get_speed(), 3.0, 0.02, "Koşu tuşu: hızlı tırıs 3 m/sn")
	assert_ne(sheep.gait_phase(), phase)
	_steps(player, Vector2.ZERO, false, 2.5)
	assert_almost(player.get_speed(), 0.0, 0.001, "Giriş bitince durur")
	assert_eq(player.get_stance(), PlayerController.Stance.RIDING, "Sırtta kalır")


func test_sheep_stops_every_ten_seconds_and_a_prod_moves_it_on() -> void:
	var player := await _make_child()
	var sheep := await _mount_up(player)
	sheep.get_mount().start_ride()
	var seconds := 0.0
	while not sheep.get_mount().is_grazing() and seconds < 12.0:
		player.step(DT, Vector2(0.0, 1.0), false, 0.0)
		seconds += DT
	assert_almost(seconds, 10.0, 0.1, "On saniyede bir otlamak için durur")
	_steps(player, Vector2(0.0, 1.0), false, 1.0)
	assert_almost(player.get_speed(), 0.0, 0.001, "Otlarken giriş yürütmez")
	assert_true(sheep.graze_amount() > 0.9, "Başını indirir")
	var at := player.global_position
	_steps(player, Vector2(0.0, 1.0), false, 0.5)
	assert_vec_almost(player.global_position, at, 0.001, "Yerinde")
	# Dürtme: koşu tuşuna yeni basış. Basılı kalan yeniden sayılmaz.
	player.step(DT, Vector2(0.0, 1.0), true, 0.0)
	assert_false(sheep.get_mount().is_grazing(), "Dürtünce yürür")
	_steps(player, Vector2(0.0, 1.0), false, 1.0)
	assert_almost(player.get_speed(), 2.5, 0.02, "Tuş bırakılınca tırıs")
	assert_true(sheep.graze_amount() < 0.1, "Başını kaldırır")


func test_e_dismounts_beside_the_sheep_and_the_sheep_stays() -> void:
	var player := await _make_child()
	var sheep := await _mount_up(player)
	_steps(player, Vector2(0.0, 1.0), false, 1.0)
	var parked := sheep.global_position
	var watcher := watch_signal(player.dismounted)
	assert_true(player.has_interaction())
	assert_true(player.interact(), "E ile iner")
	assert_eq(player.get_stance(), PlayerController.Stance.DISMOUNTING)
	_steps(player, Vector2(0.0, 1.0), false, 1.0)
	assert_eq(player.get_stance(), PlayerController.Stance.FOOT, "Yere iner")
	assert_true(watcher.fired)
	assert_false(sheep.ridden)
	assert_null(player.riding_node())
	assert_vec_almost(player.get_avatar().position, Vector3.ZERO, 0.001, "Avatar düğümün kökünde")
	assert_true(sheep.global_position.distance_to(parked) < 0.001, "Koyun durur")
	var side := Mount.new("sheep").value("dismount_side")
	assert_true(player.global_position.distance_to(parked) > side * 0.5, "Yanına iner")
	_steps(player, Vector2(0.0, 1.0), false, 1.0)
	assert_almost(player.get_speed(), player.walk_speed, 0.02, "Yerde yine yürür")
	player.spawn_at(parked + Vector3(1.0, 0.0, 0.0), 0.0)
	assert_not_null(player.mount_in_reach(), "Bir daha binilebilir")


func test_dismount_picks_a_free_side() -> void:
	var player := await _make_child()
	var sheep := await _mount_up(player)
	# Sol yan (ön yüz +Z iken +X) kapalı: sağa iner.
	sheep.place(Vector3.ZERO, 0.0)
	player.spawn_at(Vector3(1.0, 0.0, 0.0), 0.0)
	player.begin_mount(sheep)
	_steps(player, Vector2.ZERO, false, 1.0)
	var blocked: Array[Vector3] = [Vector3(0.85, 0.0, 0.3)]
	player.obstacles = blocked
	player.interact()
	_steps(player, Vector2.ZERO, false, 1.0)
	assert_true(player.global_position.x < -0.5, "Kapalı yana inmez: %s" % player.global_position)


func test_riding_keeps_obstacles_and_the_play_area() -> void:
	var player := await _make_child()
	await _mount_up(player)
	var circles: Array[Vector3] = [Vector3(0.0, -5.0, 1.0)]
	player.obstacles = circles
	_steps(player, Vector2(0.0, 1.0), true, 3.0)
	var p := Vector2(player.global_position.x, player.global_position.z)
	var radius := Mount.new("sheep").value("radius")
	assert_true(p.distance_to(Vector2(0.0, -5.0)) >= 1.0 + radius - 0.01, "Koyun engele girmez: %s" % p)
	player.obstacles = []
	player.play_area_radius = 6.0
	player.play_area_soft_edge = 1.5
	_steps(player, Vector2(1.0, 0.0), true, 4.0)
	assert_true(Vector2(player.global_position.x, player.global_position.z).length() <= 6.001, "Oyun alanında kalır")


func test_inactive_rider_stays_on_the_sheep_and_spawn_takes_her_off() -> void:
	var player := await _make_child()
	var sheep := await _mount_up(player)
	player.set_active(false)
	assert_true(player.is_riding(), "Kapatmak inmek değil (duraklatma)")
	player.spawn_at(Vector3(9.0, 0.0, 9.0), 0.0)
	assert_eq(player.get_stance(), PlayerController.Stance.FOOT, "spawn_at yere kor")
	assert_false(sheep.ridden)
	assert_vec_almost(player.get_avatar().position, Vector3.ZERO, 0.001)
	assert_vec_almost(player.global_position, Vector3(9.0, 0.0, 9.0), 0.001)


# --- Koyun ---------------------------------------------------------------------------------------------

func test_without_a_model_the_sheep_is_the_herd_drawing_with_a_seat() -> void:
	var sheep := SHEEP_SCENE.instantiate() as RideableSheep
	sheep.model_path = ""
	add_child(sheep)
	_trash.append(sheep)
	sheep.place(Vector3(2.0, 0.0, 3.0), 0.0)
	await wait_frames(1)
	assert_false(sheep.uses_model(), "Model yoksa çizim")
	assert_true(sheep.is_in_group(RideableSheep.GROUP))
	var instance := sheep.get_node_or_null(^"Body/Sheep") as MultiMeshInstance3D
	assert_not_null(instance, "Sürünün çizimi")
	if instance:
		assert_eq(instance.multimesh.instance_count, 1)
		assert_eq((instance.material_override as ShaderMaterial).shader, HerdField.SHADER, "Sürünün gölgelendiricisi")
	var seat := sheep.seat_transform()
	var spec := Mount.row_of("sheep")["seat"] as Dictionary
	assert_almost(seat.origin.y, float(spec["saddle_y"]), 0.03, "Sırtta")
	assert_almost(seat.origin.x, 2.0, 0.03)
	sheep.place(Vector3(1.0, 0.5, 1.0), PI * 0.5)
	assert_almost((sheep.seat_transform().basis * Vector3.BACK).x, 1.0, 0.01, "Oturma noktası koyunla döner")


func test_idle_sheep_grazes_by_itself_and_ridden_sheep_obeys_the_mount() -> void:
	var sheep := await _make_sheep(Vector3.ZERO)
	sheep.set_process(false)
	sheep.set("_want_graze", true)
	for i in 120:
		sheep.call("_animate", 0.0, DT)
	assert_true(sheep.graze_amount() > 0.9, "Otlarken baş iner")
	sheep.set_ridden(true)
	sheep.drive(0.0, DT)
	assert_true(sheep.graze_amount() < 1.0, "Binilince kalkar")
	sheep.get_mount().gait = Mount.Gait.GRAZE
	for i in 120:
		sheep.drive(0.0, DT)
	assert_true(sheep.graze_amount() > 0.9, "Mount otlatınca iner")


func test_sheep_glb_and_its_clips_take_over_when_they_exist() -> void:
	var dir := TempDir.fresh("koyun")
	var path := _write_fake_sheep(dir)
	assert_true(ResourceLoader.exists(path))
	var sheep := SHEEP_SCENE.instantiate() as RideableSheep
	sheep.model_path = path
	add_child(sheep)
	_trash.append(sheep)
	await wait_frames(1)
	assert_true(sheep.uses_model(), "Model varsa o")
	assert_null(sheep.get_node_or_null(^"Body/Sheep"), "Çizim kurulmaz")
	assert_eq(sheep.model_clip(), &"sheep_idle", "Durur")
	sheep.set_ridden(true)
	for i in 30:
		sheep.drive(2.5, DT)
	assert_eq(sheep.model_clip(), &"sheep_trot", "Tırıs klibi")
	for i in 60:
		sheep.drive(3.0, DT)
	assert_eq(sheep.model_clip(), &"sheep_gallop", "Dörtnal klibi")
	sheep.get_mount().gait = Mount.Gait.GRAZE
	sheep.drive(0.0, DT)
	assert_eq(sheep.model_clip(), &"sheep_graze", "Otlama klibi")
	var clips := RideableSheep.map_clips(PackedStringArray(["Armature|Eat", "Walk", "Idle_2"]))
	assert_eq(clips[&"graze"], &"Armature|Eat", "Ad parçasıyla")
	assert_eq(clips[&"trot"], &"Walk")
	assert_eq(clips[&"idle"], &"Idle_2")
	assert_false(clips.has(&"gallop"), "Yoksa rol yok: en yakın klibe düşer")
	sheep.free()
	_trash.clear()
	TempDir.wipe(dir)


# --- Binme pozu (gerçek model) ---------------------------------------------------------------------------

func test_ride_pose_is_derived_from_sitting_and_straddles_the_body() -> void:
	# Klip oturuştan türer; bacaklar gövdeyi sarar: diz ve bilek yünün dışında, ayak yerden yüksekte, el yünün üstünde. Köşelerden ölçülür.
	var verts := _sheep_vertices()
	for person: String in [ChildLook.PERSON_METE, ChildLook.PERSON_CHILD]:
		var player := await _make_child(person, true)
		var avatar := player.get_avatar()
		var skeleton := avatar.get_skeleton()
		var seat: Dictionary = Mount.row_of("sheep")["seat"]
		var sit := ClipVariety.library().clip_for(avatar.model_id, "sit", skeleton)
		var solved := RidePose.solve(skeleton, sit, seat, avatar.model_scale)
		var points: PackedVector3Array = solved["points"]
		var to_node := PoseFit.relative_transform(skeleton.owner as Node3D, skeleton)
		var hips := to_node * points[skeleton.find_bone("Hips")]
		var seat_at := RideableSheep.saddle_point(RideableSheep.read_meta(RideableSheep.MODEL_PATH), seat) + Vector3.UP * player.hips_lift()
		var lift := seat_at - hips
		for side: String in ["Left", "Right"]:
			var sign_x := 1.0 if side == "Left" else -1.0
			var knee := to_node * points[skeleton.find_bone(side + "Leg")] + lift
			var ankle := to_node * points[skeleton.find_bone(side + "Foot")] + lift
			var toe := to_node * points[skeleton.find_bone(side + "ToeBase")] + lift
			var wrist := to_node * points[skeleton.find_bone(side + "Hand")] + lift
			# Yün yumuşaktır: bacak en çok birkaç santim gömülür.
			assert_true(knee.x * sign_x >= _half_width(verts, knee.y, knee.z) - 0.05, "%s %s dizi yünün dışında (x %.3f, gövde %.3f)" % [person, side, knee.x, _half_width(verts, knee.y, knee.z)])
			assert_true(ankle.x * sign_x >= _half_width(verts, ankle.y, ankle.z) - 0.05, "%s %s bileği yünün dışında (x %.3f, gövde %.3f)" % [person, side, ankle.x, _half_width(verts, ankle.y, ankle.z)])
			assert_true(ankle.x * sign_x <= _half_width(verts, ankle.y, ankle.z) + 0.12, "%s %s bileği böğre yakın (x %.3f, gövde %.3f)" % [person, side, ankle.x, _half_width(verts, ankle.y, ankle.z)])
			assert_true(ankle.y > 0.25, "%s %s ayağı havada (%.3f m)" % [person, side, ankle.y])
			assert_true(ankle.y < knee.y, "%s baldır aşağı sarkar" % person)
			assert_true(toe.z > ankle.z, "%s ayak ucu öne" % person)
			assert_true(wrist.z > hips.z + lift.z + 0.1, "%s el önde" % person)
			assert_true(wrist.y > _top(verts, wrist.z) - 0.02, "%s eli yüne değer, gömülmez (y %.3f, yün %.3f)" % [person, wrist.y, _top(verts, wrist.z)])
			assert_almost(sign(wrist.x), sign_x, 0.01, "%s elleri iki yanda" % person)
		# Baş dik: yüzü aşağı bakmaz.
		var head_rest := skeleton.get_bone_global_rest(skeleton.find_bone("Head")).origin
		assert_true(head_rest.y > 0.0)
		var clip := RidePose.build(skeleton, sit, seat, avatar.model_scale)
		assert_not_null(clip)
		assert_eq(clip.loop_mode, Animation.LOOP_LINEAR)
		assert_almost(clip.length, RidePose.LENGTH, 0.0001)


func test_real_rider_sits_on_the_seat_and_her_feet_follow() -> void:
	var player := await _make_child(ChildLook.PERSON_METE, true)
	var sheep := await _mount_up(player)
	await wait_frames(30)
	var avatar := player.get_avatar()
	assert_eq(avatar.get_current_role(), RidePose.ROLE, "Binme rolü")
	var skeleton := avatar.get_skeleton()
	var hips := skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("Hips")).origin
	var lift := Vector3.UP * player.hips_lift()
	assert_between(player.hips_lift(), 0.08, 0.16, "Kalça sırtın oturuş yüksekliği kadar üstünde (ölçü: hips_height_for)")
	assert_vec_almost(hips, sheep.seat_transform().origin + lift, 0.04, "Kalça oturma noktasında")
	if avatar.hand_grip:
		assert_almost(avatar.hand_grip.shape_of(&"Left")[2], PlayerController.GRIP_WOOL, 0.2, "El yünü tutar")
	_steps(player, Vector2(0.0, 1.0), false, 1.0)
	await wait_frames(2)
	var moved := skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("Hips")).origin
	assert_true(moved.distance_to(sheep.seat_transform().origin + lift) < 0.06, "Yürürken de oturur")
	player.interact()
	_steps(player, Vector2.ZERO, false, 1.0)
	await wait_frames(30)
	assert_eq(avatar.get_current_role(), &"idle", "İnince bekleme klibi")
	if avatar.hand_grip:
		assert_almost(avatar.hand_grip.shape_of(&"Left")[2], HandGrip.NATURAL_SHAPE[2], 0.1, "El gevşer")


# --- Yay -----------------------------------------------------------------------------------------------

func test_aim_from_the_ground_hits_the_target_and_she_picks_it_up() -> void:
	var player := await _make_child()
	var target := _make_target(Vector3(0.0, 0.0, -6.0))
	player.spawn_at(Vector3.ZERO, PI)
	player.archer().aim_override = target
	assert_true(player.begin_aim(), "Nişan alır")
	assert_true(player.is_aiming())
	_steps(player, Vector2(0.0, 1.0), true, 1.6)
	assert_almost(player.get_speed(), 0.0, 0.001, "Nişanda yerde durulur")
	assert_vec_almost(player.global_position, Vector3.ZERO, 0.05, "Yürümez")
	assert_almost(angle_difference(player.get_facing_yaw(), player.archer().body_yaw()), 0.0, 0.05, "Bedeni yana döner")
	var loosed := watch_signal(player.archer().loosed)
	player.release_aim()
	player.step(DT, Vector2.ZERO, false, 0.0)
	assert_true(loosed.fired, "Bırakınca ok çıkar")
	assert_false(player.is_aiming())
	var field := player.archer().field
	assert_eq(field.pool.flying_count(), 1, "Uçuyor")
	assert_true(field.multimesh.visible_instance_count == 1 and field.visible, "Tek MultiMesh'te")
	var seen := watch_signal(field.target_hit)
	await _wait_arrow(field, 60)
	assert_eq(target.hits, 1, "Vurulan hit alır")
	assert_true(seen.fired)
	assert_true(target.is_down(), "Düşer")
	assert_false(target.is_in_group(ArrowField.TARGET_GROUP), "Gruptan çıkar")
	assert_eq(ArrowField.targets_in(get_tree()).size(), 0, "Düşmüş hedef bir daha vurulmaz")
	# Yanına gidip alır.
	assert_null(player.pickup_in_reach(), "Uzakta alınmaz")
	player.spawn_at(Vector3(0.0, 0.0, -5.2), PI)
	assert_eq(player.pickup_in_reach(), target)
	assert_true(player.has_interaction())
	var picked := watch_signal(player.target_collected)
	assert_true(player.interact(), "E ile alır")
	assert_true(picked.fired)
	assert_true(target.collected, "Alındı")


func test_real_child_bends_down_for_it_and_is_held_until_up() -> void:
	var player := await _make_child(ChildLook.PERSON_CHILD, true)
	var target := _make_target(Vector3(0.0, 0.0, -0.9))
	target.hit(target.global_position)
	player.spawn_at(Vector3.ZERO, 0.0)
	assert_true(player.interact())
	assert_eq(player.get_stance(), PlayerController.Stance.COLLECTING, "Klip oynar")
	assert_eq(player.get_avatar().get_current_role(), PlayerController.ROLE_COLLECT)
	assert_almost(angle_difference(player.get_facing_yaw(), PI), 0.0, 0.01, "Hedefe döner")
	assert_false(target.collected, "Daha eğilmedi")
	var at := player.global_position
	var seconds := 0.0
	while player.get_stance() == PlayerController.Stance.COLLECTING and seconds < 8.0:
		player.step(DT, Vector2(0.0, 1.0), false, 0.0)
		seconds += DT
	assert_true(target.collected, "Eğilince alır")
	assert_eq(player.get_stance(), PlayerController.Stance.FOOT)
	assert_vec_almost(player.global_position, at, 0.001, "Alırken yürümez")
	assert_eq(player.get_avatar().get_current_role(), &"idle", "Doğrulur")


func test_quick_click_falls_short() -> void:
	var player := await _make_child()
	player.spawn_at(Vector3.ZERO, PI)
	var aim := Vector3(0.0, 0.0, -10.0)
	player.archer().aim_override = aim
	player.begin_aim()
	player.release_aim()
	_steps(player, Vector2.ZERO, false, 0.2)
	var field := player.archer().field
	assert_eq(field.pool.shots.size(), 1)
	var landed := watch_signal(field.arrow_landed)
	await _wait_arrow(field, 180)
	assert_true(landed.fired, "İner")
	var p: Vector3 = landed.last_args[0]
	assert_true(Vector2(p.x, p.z).length() < 8.0, "Az gerilen kiriş kısa düşer: %s" % p)
	_steps(player, Vector2.ZERO, false, 0.5)
	assert_true(player.get_avatar().is_processing(), "Yay inince avatar ara hareketlerini sürdürür")


func test_shooting_from_the_sheep_back_while_it_walks() -> void:
	var player := await _make_child()
	var sheep := await _mount_up(player)
	var target := _make_target(Vector3(0.0, 0.0, -8.0))
	player.archer().aim_override = target
	assert_true(player.begin_aim(), "Koyun sırtından nişan")
	_steps(player, Vector2(0.0, 1.0), false, 1.5)
	assert_almost(player.get_speed(), 2.5, 0.02, "Koyun yürümeyi sürdürür")
	assert_true(player.is_riding())
	# Nişanda koşu tuşu dörtnala kaldırmaz (ama otlayanı dürter).
	_steps(player, Vector2(0.0, 1.0), true, 0.8)
	assert_almost(player.get_speed(), 2.5, 0.02, "Nişanda tırıs")
	_steps(player, Vector2.ZERO, false, 0.3)
	player.release_aim()
	player.step(DT, Vector2.ZERO, false, 0.0)
	assert_eq(player.archer().field.pool.shots.size(), 1, "Sırttan atar")
	await _wait_arrow(player.archer().field, 90)
	assert_eq(target.hits, 1, "Sırttan vurur")
	assert_true(sheep.ridden, "Sırtta kalır")


func test_mounted_aim_stays_inside_the_cone() -> void:
	var player := await _make_child()
	await _mount_up(player)
	player.spawn_at(player.global_position, player.get_facing_yaw())
	var sheep := _last_sheep(player)
	sheep.place(player.global_position, 0.0)
	player.begin_mount(sheep)
	_steps(player, Vector2.ZERO, false, 1.0)
	# Binek +Z'ye bakar; nişan arkasında.
	player.archer().aim_override = player.global_position + Vector3(0.0, 0.0, -8.0)
	player.begin_aim()
	player.step(DT, Vector2.ZERO, false, 0.0)
	var to := player.archer().aim_point - player.global_position
	var yaw := atan2(to.x, to.z)
	assert_almost(absf(angle_difference(player.get_facing_yaw(), yaw)), ChildArcher.MOUNT_CONE, 0.01, "Arkaya atılmaz: koni kenarı")
	player.release_aim()


func test_aim_locks_a_near_target_and_range_holds() -> void:
	var player := await _make_child()
	player.spawn_at(Vector3.ZERO, PI)
	# İmleç yokken (başsız) nişan ileri, menzilin %70'i: oraya yakın hedef kilitlenir.
	var range_m := float(Weapons.bow("toy_bow")["range"])
	var target := _make_target(Vector3(0.6, 0.0, -range_m * 0.7))
	player.begin_aim()
	assert_eq(player.archer().aim_target, target, "Yakın hedefe kilit")
	assert_vec_almost(player.archer().aim_point, ArrowField.target_center(target), 0.001, "Nişan hedefin merkezinde")
	player.archer().cancel()
	# Menzil dışındaki nokta menzile çekilir.
	player.archer().aim_override = Vector3(0.0, 0.0, -50.0)
	await wait_frames(14)
	player.begin_aim()
	assert_almost(Vector2(player.archer().aim_point.x, player.archer().aim_point.z).length(), range_m, 0.01, "Menzil")
	assert_null(player.archer().aim_target)
	player.archer().cancel()


func test_near_miss_startles_and_field_hides_when_empty() -> void:
	var player := await _make_child()
	var target := _make_target(Vector3(2.0, 0.0, -6.0))
	var field := player.archer().field
	assert_false(field.visible, "Ok yokken çizim yok")
	field.fire(Vector3(0.0, 0.8, 0.0), Vector3(0.0, 0.0, -6.0), {"speed": 22.0, "arc": 0.06, "blunt": true})
	await _wait_arrow(field, 60)
	assert_eq(target.hits, 0, "Vurmaz")
	assert_eq(target.startled, 1, "Yakına düşen ok ürkütür")
	field.pool.clear()
	field.step(DT)
	field.pool.fire(Vector3.ZERO, Vector3.ONE, {})
	field.pool.clear()
	field.call("_write")
	assert_false(field.visible, "Boşalınca gizlenir")


func test_target_contract_defaults() -> void:
	var bare := Node3D.new()
	add_child(bare)
	_trash.append(bare)
	bare.global_position = Vector3(1.0, 2.0, 3.0)
	assert_true(ArrowField.is_hittable(bare), "hit dışında bir şey istemez")
	assert_vec_almost(ArrowField.target_center(bare), Vector3(1.0, 2.0, 3.0), 0.0001, "Merkez düğümün yeri")
	assert_almost(ArrowField.target_radius(bare), ArrowField.DEFAULT_RADIUS, 0.0001)
	var dummy := _make_target(Vector3.ZERO)
	assert_almost(ArrowField.target_radius(dummy), dummy.hit_radius, 0.0001)
	assert_vec_almost(ArrowField.target_center(dummy), Vector3(0.0, dummy.center_height, 0.0), 0.0001, "hit_center")
	dummy.hit(Vector3.ZERO)
	assert_false(ArrowField.is_hittable(dummy), "Düşmüş vurulmaz")


func test_pure_aim_helpers() -> void:
	var from := Vector3.ZERO
	var inside := ChildArcher.clamp_range(from, Vector3(0.0, 1.0, 8.0), 1.6, 14.0, Vector3.BACK)
	assert_false(inside["clamped"])
	var far := ChildArcher.clamp_range(from, Vector3(20.0, 1.0, 0.0), 1.6, 14.0, Vector3.BACK)
	assert_true(far["clamped"])
	assert_vec_almost(far["point"], Vector3(14.0, 1.0, 0.0), 0.0001, "Menzile")
	var near := ChildArcher.clamp_range(from, Vector3(0.5, 0.0, 0.0), 1.6, 14.0, Vector3.BACK)
	assert_vec_almost(near["point"], Vector3(1.6, 0.0, 0.0), 0.0001, "Ayağının dibine atmaz")
	var under := ChildArcher.clamp_range(from, Vector3.ZERO, 1.6, 14.0, Vector3.BACK)
	assert_vec_almost(under["point"], Vector3(0.0, 0.0, 1.6), 0.0001, "Üstüne denk gelirse baktığı yöne")
	assert_almost(ChildArcher.clamp_cone(0.2, 0.0, 1.0), 0.2, 0.0001, "Koni içinde")
	assert_almost(ChildArcher.clamp_cone(2.0, 0.0, 1.0), 1.0, 0.0001, "Koni kenarı")
	assert_almost(ChildArcher.clamp_cone(-3.0, 0.0, 1.0), -1.0, 0.0001)
	var centers: Array[Vector3] = [Vector3(5.0, 0.0, 0.0), Vector3(1.0, 0.0, 0.0), Vector3(0.0, 4.0, 0.0)]
	assert_eq(ChildArcher.pick_lock(Vector3(0.5, 0.0, 0.0), centers, 1.6), 1, "Yakın olan")
	assert_eq(ChildArcher.pick_lock(Vector3(9.0, 0.0, 9.0), centers, 1.6), -1, "Uzakta kilit yok")
	assert_eq(ChildArcher.pick_lock(Vector3(9.0, 0.0, 9.0), centers, 1.6, Vector3(0.0, 4.5, -5.0), Vector3.BACK), 2, "Havadaki hedef ışına yakın")
	var ground := func(x: float, _z: float) -> float: return x * 0.1
	var hit := ChildArcher.ray_ground(Vector3(0.0, 5.0, 0.0), Vector3(0.6, -0.8, 0.0), ground)
	assert_almost(hit.y, hit.x * 0.1, 0.01, "Eğimli zemin yinelemeyle bulunur")
	assert_eq(ChildArcher.ray_ground(Vector3.ZERO, Vector3.UP, ground), Vector3.INF, "Yukarı bakan ışın")


func test_real_archer_pose_hands_on_bow_and_string_and_stows_on_the_back() -> void:
	for person: String in [ChildLook.PERSON_METE, ChildLook.PERSON_CHILD]:
		var player := await _make_child(person, true)
		player.set_process(false)
		player.spawn_at(Vector3.ZERO, PI)
		var archer := player.archer()
		var pose := archer.pose
		assert_not_null(pose, "%s: poz eklenir" % person)
		var skeleton := player.get_avatar().get_skeleton()
		var stowed := await _posed(skeleton, ["Spine01", "LeftToeBase", "RightToeBase"])
		# Gerilmeden yay sırtta.
		assert_true(archer.prop.global_position.distance_to(stowed["Spine01"]) < 0.2, "%s: yay sırtta" % person)
		archer.aim_override = Vector3(0.0, 0.3, -9.0)
		player.begin_aim()
		for i in 60:
			player.step(DT, Vector2.ZERO, false, 0.0)
			await get_tree().process_frame
		var posed := await _posed(skeleton, ["LeftHand", "RightHand", "Head", "LeftToeBase", "RightToeBase"])
		# Yerde altta kütüphanenin yan duruş klibi: beden yana döner, ayak yere değer (zemin payı klibe yazılı).
		assert_eq(player.get_avatar().get_current_role(), PlayerController.ROLE_AIM, "%s: nişan duruşu klibi" % person)
		assert_true(archer.stance_clip, "%s: yan duruş" % person)
		var toe_idle := minf((stowed["LeftToeBase"] as Vector3).y, (stowed["RightToeBase"] as Vector3).y)
		var toe_aim := minf((posed["LeftToeBase"] as Vector3).y, (posed["RightToeBase"] as Vector3).y)
		assert_almost(toe_aim, toe_idle, 0.02, "%s: nişanda ayak yerde (bekleme %.3f, nişan %.3f)" % [person, toe_idle, toe_aim])
		assert_almost(pose.amount, 1.0, 0.001, "%s: poz tam" % person)
		assert_almost(pose.draw, 1.0, 0.001, "%s: kiriş gergin" % person)
		var hand_l: Vector3 = posed["LeftHand"]
		var hand_r: Vector3 = posed["RightHand"]
		var grip := archer.prop.global_position
		assert_true(hand_l.distance_to(grip) < 0.11, "%s: sol el kabzada (%.3f m)" % [person, hand_l.distance_to(grip)])
		var nock := pose.nock_world
		assert_true(hand_r.distance_to(nock) < 0.14, "%s: sağ el kirişte (%.3f m)" % [person, hand_r.distance_to(nock)])
		var dir := pose.aim_dir
		assert_true((grip - nock).dot(dir) > 0.16, "%s: kiriş geride (%.3f m)" % [person, (grip - nock).dot(dir)])
		assert_true((grip - nock).dot(dir) < 0.5, "%s: çocuğun kolu kadar (%.3f m)" % [person, (grip - nock).dot(dir)])
		assert_true(archer.prop.global_transform.basis.z.dot(dir) > 0.95, "%s: yayın sırtı hedefe" % person)
		assert_true(archer.prop.global_transform.basis.y.dot(Vector3.UP) > 0.9, "%s: yay dik" % person)
		assert_true(archer.prop.arrow.visible, "%s: ok kirişte" % person)
		assert_true(archer.launch_point().distance_to(grip) < 0.02, "%s: ok kabzadan çıkar" % person)
		var head_forward: Vector3 = posed["Head_basis"] * skeleton.get_bone_global_rest(skeleton.find_bone("Head")).basis.orthonormalized().inverse() * CineBow.character_axes(skeleton).z
		assert_true((skeleton.global_basis.orthonormalized() * head_forward).dot(Vector3(dir.x, 0.0, dir.z).normalized()) > 0.75, "%s: baş hedefe bakar" % person)
		if player.get_avatar().hand_grip:
			assert_true(player.get_avatar().hand_grip.shape_of(&"Left")[2] > 0.6, "%s: sol el kapalı" % person)
		player.release_aim()
		player.step(DT, Vector2.ZERO, false, 0.0)
		assert_false(archer.prop.arrow.visible, "%s: ok çıktı" % person)
		for i in 60:
			player.step(DT, Vector2.ZERO, false, 0.0)
			await get_tree().process_frame
		assert_almost(pose.amount, 0.0, 0.001, "%s: poz söner" % person)
		assert_eq(player.get_avatar().get_current_role(), &"idle", "%s: bırakınca bekleme klibi" % person)
		var back := await _posed(skeleton, ["Spine01"])
		assert_true(archer.prop.global_position.distance_to(back["Spine01"]) < 0.2, "%s: yay sırta döner" % person)


# --- Oturuş --------------------------------------------------------------------------------------------

func test_seated_child_rises_on_first_move_and_is_held_until_up() -> void:
	var player := await _make_child(ChildLook.PERSON_CHILD, true)
	var seat := Transform3D(Basis(Vector3.UP, 1.2), Vector3(1.0, 0.0, 2.0))
	player.sit_at(seat)
	var avatar := player.get_avatar()
	assert_true(player.is_seated())
	assert_eq(avatar.get_current_role(), &"sit", "Oturur")
	assert_eq(avatar.variety_key(&"sit"), CampNpcs.SEATS["Child"], "Ateş başındaki oturuş")
	_steps(player, Vector2.ZERO, false, 1.0)
	assert_eq(player.get_stance(), PlayerController.Stance.SEATED, "Girişsiz oturur")
	assert_vec_almost(player.global_position, seat.origin, 0.001, "Yerinde")
	assert_almost(angle_difference(player.get_facing_yaw(), 1.2), 0.0, 0.001, "Yönü")
	player.step(DT, Vector2(0.0, 1.0), false, 0.0)
	assert_eq(player.get_stance(), PlayerController.Stance.RISING, "İlk harekette kalkar")
	assert_eq(avatar.get_current_role(), PlayerController.ROLE_RISE)
	assert_false(player.begin_aim(), "Kalkarken yay yok")
	var seconds := 0.0
	while player.get_stance() == PlayerController.Stance.RISING and seconds < 8.0:
		player.step(DT, Vector2(0.0, 1.0), false, 0.0)
		seconds += DT
	assert_eq(player.get_stance(), PlayerController.Stance.FOOT, "Ayakta")
	assert_true(seconds > 0.5, "Kayarak kalkılmaz (%.2f sn)" % seconds)
	assert_vec_almost(player.global_position, seat.origin, 0.001, "Kalkarken yürümez")
	assert_almost(avatar.position.y, 0.0, 0.0001, "Avatar zeminde")
	_steps(player, Vector2(0.0, 1.0), false, 0.5)
	assert_true(player.get_speed() > 0.5, "Sonra yürür")
	assert_eq(avatar.get_current_role(), &"walk")


func test_interact_and_spawn_also_end_sitting() -> void:
	var player := await _make_child()
	player.sit_at(Transform3D.IDENTITY)
	assert_true(player.has_interaction(), "Otururken E kalkar")
	assert_true(player.interact())
	assert_false(player.is_seated(), "Chibi yedeğinde klip yok: hemen ayakta")
	player.sit_at(Transform3D.IDENTITY)
	player.spawn_at(Vector3(3.0, 0.0, 0.0), 0.0)
	assert_eq(player.get_stance(), PlayerController.Stance.FOOT, "spawn_at kaldırır")


# --- Girişler --------------------------------------------------------------------------------------------

func test_right_mouse_aims_and_looses_only_for_the_child() -> void:
	var player := await _make_child()
	player.set_active(true)
	player.archer().aim_override = Vector3(0.0, 0.0, -6.0)
	player._unhandled_input(_mouse(MOUSE_BUTTON_RIGHT, true))
	assert_true(player.is_aiming(), "Sağ tuş nişan alır")
	_steps(player, Vector2.ZERO, false, 0.3)
	var loosed := watch_signal(player.archer().loosed)
	player._unhandled_input(_mouse(MOUSE_BUTTON_RIGHT, false))
	player.step(DT, Vector2.ZERO, false, 0.0)
	assert_true(loosed.fired, "Bırakınca atar")
	var adult := await _make_child()
	adult.use_profile(CharacterProfile.new())
	adult.set_active(true)
	adult._unhandled_input(_mouse(MOUSE_BUTTON_RIGHT, true))
	assert_false(adult.is_aiming(), "Yetişkinde sağ tuş kameranındır")


func test_e_key_mounts_and_camera_yields_it_only_when_it_has_a_job() -> void:
	var player := await _make_child()
	var cam := FollowCamera.new()
	cam.start_active = false
	cam.target = player
	add_child(cam)
	_trash.append(cam)
	player.camera = cam
	player.set_active(true)
	player.use_child(ChildLook.PERSON_METE)
	assert_false(player.has_interaction())
	player.call("_refresh_camera_keys")
	assert_false(cam.hold_turn_right, "Binek yokken E kamerayı döndürür")
	player.use_profile(CharacterProfile.new())
	player.use_child(ChildLook.PERSON_CHILD)
	assert_false(cam.right_drag, "Çocukta sağ tuş nişan: kamerayı sürüklemez")
	var sheep := await _make_sheep(Vector3(1.0, 0.0, 0.0))
	player.spawn_at(Vector3.ZERO, 0.0)
	player.call("_refresh_camera_keys")
	assert_true(cam.hold_turn_right, "Binek erimde: E binmenin")
	player._unhandled_input(_action(&"accept"))
	assert_eq(player.get_stance(), PlayerController.Stance.MOUNTING, "accept (E) biner")
	assert_true(sheep.ridden)
	_steps(player, Vector2.ZERO, false, 1.0)
	player.call("_refresh_camera_keys")
	assert_true(cam.hold_turn_right, "Sırtta E inmenin")
	player._unhandled_input(_action(&"accept"))
	assert_eq(player.get_stance(), PlayerController.Stance.DISMOUNTING, "accept (E) iner")
	player.use_profile(CharacterProfile.new())
	assert_true(cam.right_drag, "Yetişkinde sağ tuş yine kameranın")
	assert_false(cam.hold_turn_right)


func test_child_frame_starts_at_22_m_and_the_adult_gets_the_default_back() -> void:
	var player := await _make_child()
	var cam := FollowCamera.new()
	cam.start_active = false
	cam.target = player
	add_child(cam)
	_trash.append(cam)
	player.camera = cam
	player.use_profile(CharacterProfile.new())
	assert_almost(cam.get_target_distance(), FollowCamera.DEFAULT_DISTANCE, 0.0001, "Yetişkin varsayılan uzaklıkta")
	for person in [ChildLook.PERSON_CHILD, ChildLook.PERSON_METE]:
		player.use_child(person)
		assert_almost(cam.get_target_distance(), FollowCamera.CHILD_DISTANCE, 0.0001, "%s 22 m'den görünür" % person)
		assert_almost(cam.current_pitch(), cam.pitch_deg, 0.0001, "Çocuk kadrajında açı aynı")
		player.use_profile(CharacterProfile.new())
		assert_almost(cam.get_target_distance(), FollowCamera.DEFAULT_DISTANCE, 0.0001, "Yetişkine dönünce 28 m")


func test_aiming_does_not_bring_the_camera_closer() -> void:
	var player := await _make_child()
	var cam := FollowCamera.new()
	cam.start_active = false
	cam.target = player
	add_child(cam)
	_trash.append(cam)
	player.camera = cam
	player.use_child(ChildLook.PERSON_METE)
	player.set_active(true)
	cam.set_active(true)
	cam.snap_to_target()
	player.spawn_at(Vector3.ZERO, PI)
	for i in 30:
		cam.update_camera(DT)
	var before := cam.camera.global_position
	var fov := cam.camera.fov
	player.archer().aim_override = Vector3(0.0, 0.0, -8.0)
	assert_true(player.begin_aim())
	for i in 90:
		player.step(DT, Vector2.ZERO, false, 0.0)
		cam.update_camera(DT)
		assert_almost(cam.get_target_distance(), FollowCamera.CHILD_DISTANCE, 0.0001, "Nişanda uzaklık değişmez")
	assert_true(player.archer().draw.draw_k() > 0.9, "Kiriş gerildi")
	assert_vec_almost(cam.camera.global_position, before, 0.001, "Kamera yerinde")
	assert_almost(cam.camera.fov, fov, 0.001, "Görüş açısı daralmaz")
	player.set_active(false)
	cam.set_active(false)


func test_prompt_follows_what_can_be_done() -> void:
	var player := await _make_child()
	player.set_active(true)
	var sheep := await _make_sheep(Vector3(1.0, 0.0, 0.0))
	var seen := watch_signal(player.prompt_changed)
	player.spawn_at(Vector3(4.0, 0.0, 0.0), 0.0)
	player.step(DT, Vector2.ZERO, false, 0.0)
	assert_eq(player.prompt_pairs(), [["Sağ tık", "Nişan"]], "Yay ilk atışa dek söylenir")
	assert_true(seen.fired)
	player.spawn_at(Vector3.ZERO, 0.0)
	assert_eq(player.prompt_pairs(), [["E", "Bin"]])
	player.begin_mount(sheep)
	_steps(player, Vector2.ZERO, false, 1.0)
	assert_eq(player.prompt_pairs()[1], ["E", "İn"])
	assert_eq(player.prompt_pairs()[0], ["Shift", "Dürt"])
	sheep.get_mount().gait = Mount.Gait.GRAZE
	assert_eq(player.prompt_pairs().size(), 2, "Otlarken yay söylenmez, dürtme önde")
	player.set_active(false)
	player.step(DT, Vector2.ZERO, false, 0.0)
	assert_eq(seen.last_args, [[]], "Kapalıyken ipucu yok")
	var prompt := PlayerPrompt.new()
	add_child(prompt)
	_trash.append(prompt)
	assert_false(prompt.visible, "Boşken gizli")
	prompt.show_pairs([["E", "Bin"]])
	assert_true(prompt.visible)
	assert_eq(prompt.get_text(), "E: Bin")
	prompt.show_pairs([])
	assert_false(prompt.visible)


# --- Yay ağı ---------------------------------------------------------------------------------------------

func test_toy_bow_mesh_is_cut_from_the_cradle_bow() -> void:
	ToyBowProp.clear_cache()
	var mesh := ToyBowProp.bow_mesh()
	assert_not_null(mesh)
	var triangles: int = mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size() / 3
	assert_between(triangles, 700, 1600, "Yayın kolu: sadak ve asma ipleri yok (kaynak 3.906)")
	var box := mesh.get_aabb()
	assert_between(box.size.y, ToyBowProp.SPAN * 0.95, ToyBowProp.SPAN * 1.1, "Boyu")
	assert_true(box.size.x < 0.08, "Sadak yok (yana %.3f m)" % box.size.x)
	assert_true(box.size.z < 0.14, "Asma ipleri yok (derin %.3f m)" % box.size.z)
	var line: Array[Vector3] = [Vector3.ZERO, Vector3(1.0, 0.0, 0.0)]
	var radii: Array[float] = [0.1, 0.3]
	assert_true(ToyBowProp.in_band(Vector3(0.0, 0.09, 0.0), line, radii), "Şeridin içinde")
	assert_false(ToyBowProp.in_band(Vector3(0.0, 0.12, 0.0), line, radii), "Dışında")
	assert_true(ToyBowProp.in_band(Vector3(1.0, 0.29, 0.0), line, radii), "Yarıçap çizgi boyunca değişir")
	var prop := ToyBowProp.new()
	add_child(prop)
	_trash.append(prop)
	var frame := ToyBowProp.bow_frame(ToyBowProp.CENTER_LINE)
	assert_vec_almost(frame * ToyBowProp.CENTER_LINE[ToyBowProp.CENTER_LINE.size() / 2], Vector3.ZERO, 0.001, "Kök kabza")
	assert_true(prop.tip_top.y > 0.2 and prop.tip_bottom.y < -0.2, "Uçlar +Y ekseninde")
	assert_true(prop.rest_nock().z < 0.0, "Kiriş kabzanın gerisinde")
	prop.set_nock(Vector3(0.0, 0.0, -0.3))
	assert_almost(prop.string_a.transform.basis.y.length(), prop.tip_top.distance_to(Vector3(0.0, 0.0, -0.3)), 0.001, "Kiriş geze uzanır")
	prop.show_arrow(true)
	assert_true(prop.arrow.visible)
	assert_almost(prop.arrow.position.z, -0.3 + 0.52, 0.2, "Ok gezden öne")


func test_arrow_mesh_has_a_blunt_knob_at_the_root() -> void:
	var mesh := ArrowField.make_arrow_mesh(0.5)
	var box := mesh.get_aabb()
	assert_almost(box.end.z, 0.0, 0.01, "Uç kökte")
	assert_between(box.position.z, -0.6, -0.48, "Gövde -Z boyunca")
	assert_true(box.size.x < 0.06, "İnce")
	assert_eq(ToyBowProp.arrow_mesh(0.5), ToyBowProp.arrow_mesh(0.5), "Önbellekte")


# --- Yardımcılar -----------------------------------------------------------------------------------------

## Dünyasız (düz zeminli) çocuk. real: gerçek model (yoksa chibi yedeği).
func _make_child(person: String = ChildLook.PERSON_CHILD, real: bool = false) -> PlayerController:
	var player := PlayerController.new()
	player.terrain_shape = FlatShape.new()
	player.start_active = false
	var avatar := CharacterAvatar.new()
	avatar.use_meshy_models = real
	player.add_child(avatar)
	add_child(player)
	_trash.append(player)
	player.set_process(false)
	await wait_frames(1)
	player.obstacles = []
	player.use_child(person)
	return player


func _make_sheep(at: Vector3) -> RideableSheep:
	var sheep := SHEEP_SCENE.instantiate() as RideableSheep
	add_child(sheep)
	_trash.append(sheep)
	sheep.place(at, 0.0)
	await wait_frames(1)
	return sheep


## Koyun koyar, binip geçişi bitirir.
func _mount_up(player: PlayerController) -> RideableSheep:
	var sheep := await _make_sheep(Vector3.ZERO)
	player.spawn_at(Vector3(0.9, 0.0, 0.0), 0.0)
	player.begin_mount(sheep)
	_steps(player, Vector2.ZERO, false, 1.0)
	return sheep


func _last_sheep(_player: PlayerController) -> RideableSheep:
	for i in range(_trash.size() - 1, -1, -1):
		if _trash[i] is RideableSheep:
			return _trash[i]
	return null


func _make_target(at: Vector3) -> TargetDummyProbe:
	var target := TargetDummyProbe.new()
	add_child(target)
	_trash.append(target)
	target.global_position = at
	return target


## Sahte hedef: ürkmeyi de sayar.
class TargetDummyProbe:
	extends TargetDummy
	var startled := 0

	func startle(_from: Vector3) -> void:
		startled += 1


func _steps(player: PlayerController, input: Vector2, sprint: bool, seconds: float) -> void:
	for i in int(round(seconds / DT)):
		player.step(DT, input, sprint, 0.0)


## Oklar uçuşunu bitirene dek (kareler) alan ilerler.
func _wait_arrow(field: ArrowField, frames: int) -> void:
	for i in frames:
		field.step(DT)
		if field.pool.flying_count() == 0:
			return
	await wait_frames(1)


func _mouse(button: MouseButton, pressed: bool) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	return event


func _action(action: StringName) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


## Değiştiriciler çalıştıktan sonraki kemiklerin dünya konumu (poz yalnız skeleton_updated anında okunur; test_kopuz'la aynı yol); ayrıca <ad>_basis.
func _posed(skeleton: Skeleton3D, bones: Array) -> Dictionary:
	var out := {}
	var grab := func() -> void:
		for bone: String in bones:
			var pose := skeleton.get_bone_global_pose(skeleton.find_bone(bone))
			out[bone] = skeleton.global_transform * pose.origin
			out[bone + "_basis"] = pose.basis.orthonormalized()
	skeleton.skeleton_updated.connect(grab)
	await wait_frames(2)
	skeleton.skeleton_updated.disconnect(grab)
	return out


## Binilen koyunun köşeleri (modeli varsa dinlenme pozunda, yoksa sürünün çizimi).
func _sheep_vertices() -> PackedVector3Array:
	if ResourceLoader.exists(RideableSheep.MODEL_PATH):
		var root: Node = (load(RideableSheep.MODEL_PATH) as PackedScene).instantiate()
		var found := root.find_children("*", "MeshInstance3D", true, false)
		var verts: PackedVector3Array = (found[0] as MeshInstance3D).mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		root.free()
		return verts
	return FaunaMesh.sheep().vertices


## Koyunun yarı genişliği: köşelerden (y, z yakınında en dıştaki).
func _half_width(verts: PackedVector3Array, y: float, z: float) -> float:
	var best := 0.0
	for v in verts:
		if absf(v.y - y) < 0.05 and absf(v.z - z) < 0.08:
			best = maxf(best, absf(v.x))
	return best


## Koyunun sırtı: köşelerden (z yakınında en yüksek).
func _top(verts: PackedVector3Array, z: float) -> float:
	var best := 0.0
	for v in verts:
		if absf(v.z - z) < 0.06 and absf(v.x) < 0.14:
			best = maxf(best, v.y)
	return best


## Oturma noktası sırtın yünündedir (modelin ölçüsü, saddle_y, saddle_z): yünün tepesinden biraz aşağıda (yün yumuşak), içine gömülmez.
func test_seat_rests_on_the_back() -> void:
	var verts := _sheep_vertices()
	var sheep := await _make_sheep(Vector3.ZERO)
	var saddle := sheep.seat_transform().origin
	if sheep.uses_model():
		assert_false(sheep.meta.is_empty(), "Modelin ölçüsü okunur")
		assert_almost(saddle.y, float(sheep.meta["saddle_y"]), 0.02, "Modelin sırt yüksekliği")
		assert_almost(saddle.z, float(sheep.meta["saddle_z"]), 0.02, "Modelin sırt noktası")
	var back := _top(verts, saddle.z)
	assert_between(back - saddle.y, 0.0, 0.06, "Oturak yünün tepesinde ya da azıcık içinde (sırt %.3f m, oturak %.3f m)" % [back, saddle.y])


func test_real_sheep_walks_slowly_and_never_overspeeds_its_clips() -> void:
	# Dörtnal klibi yok: tırıs klibi en çok CLIP_RATE.y kat hızlanır, yavaşta yürüme klibi oynar (ayak kaymaz, adım telaşlanmaz).
	var sheep := await _make_sheep(Vector3.ZERO)
	if not sheep.uses_model():
		assert_true(true, "Model yok")
		return
	sheep.set_ridden(true)
	var mount := sheep.get_mount()
	for speed: float in [1.0, mount.trot_speed(), mount.gallop_speed()]:
		for i in 40:
			sheep.drive(speed, DT)
		var clip := sheep.model_clip()
		var rate := sheep.clip_rate(clip, speed)
		if speed < RideableSheep.WALK_TOP:
			assert_true(String(clip).contains("walk"), "%.1f m/sn yürür (%s)" % [speed, clip])
		else:
			assert_true(String(clip).contains("run"), "%.1f m/sn tırıs klibi (%s)" % [speed, clip])
		assert_between(rate, RideableSheep.CLIP_RATE.x, RideableSheep.CLIP_RATE.y, "%.1f m/sn: %s klibi %.2f kat" % [speed, clip, rate])
	assert_almost(sheep.clip_stride(&"walk", 1.0), 0.86, 0.01, "Adım boyu modelin ölçüsünden")


## Sahte Meshy koyunu: klipli küçük sahne (dosyaya yazılır, load edilir).
func _write_fake_sheep(dir: String) -> String:
	var root := Node3D.new()
	root.name = "FakeSheep"
	var player := AnimationPlayer.new()
	player.name = "AnimationPlayer"
	root.add_child(player)
	player.owner = root
	var library := AnimationLibrary.new()
	for clip in ["sheep_idle", "sheep_graze", "sheep_trot", "sheep_gallop"]:
		var anim := Animation.new()
		anim.length = 1.0
		library.add_animation(clip, anim)
	player.add_animation_library(&"", library)
	var packed := PackedScene.new()
	packed.pack(root)
	root.free()
	var path := dir.path_join("sheep.scn")
	ResourceSaver.save(packed, path)
	return path
