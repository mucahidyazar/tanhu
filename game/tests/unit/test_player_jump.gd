extends TestCase
## Zıplama (2026-11-07; Boşluk, «jump» eylemi; klip regular_jump, Meshy 466): yerden olur, koşarken de; çömelme, havada kalış ve iniş evreleri; düğüm yerde kalır
## (kamera sarsılmaz), kalça klipte yükselir; havada yön az değişir; iniş yumuşaktır ve hareket varsa yürüyüşe karışır; binerken, nişanda, otururken zıplanmaz;
## çocukta ve yetişkinde aynı. Gerçek klavye yok: step() ve jump() doğrudan, eylem _unhandled_input'la.

const DT := 1.0 / 60.0
const SHEEP_SCENE := preload("res://scenes/fauna/rideable_sheep.tscn")


class FlatShape:
	extends TerrainShape
	var level := 0.4

	func height_at(_x: float, _z: float) -> float:
		return level


var _trash: Array[Node] = []


func after_each() -> void:
	for node in _trash:
		if is_instance_valid(node):
			node.queue_free()
	_trash.clear()


func test_jump_clip_is_in_the_library_and_its_phases_fit() -> void:
	var lib := ClipVariety.library()
	var spec := lib.clip(PlayerController.JUMP_CLIP)
	assert_false(spec.is_empty(), "Zıplama klibi kütüphanede")
	assert_eq(int(spec.get("meshy_action", 0)), 466, "Meshy «Regular Jump»")
	assert_true(bool(spec.get("scene_only", false)), "Varsayılan atamaya girmez")
	assert_false(bool(spec.get("loop", true)), "Bir kez oynar")
	var anim := lib.library_clip(PlayerController.JUMP_CLIP)
	assert_not_null(anim, "Oyun kaynağı (assets/animations/library/regular_jump.res)")
	if anim:
		assert_true(PlayerController.JUMP_SETTLE < anim.length, "Evreler klibin içinde")
	assert_true(PlayerController.JUMP_START < PlayerController.JUMP_RUN_START and PlayerController.JUMP_RUN_START < PlayerController.JUMP_TAKEOFF)
	assert_true(PlayerController.JUMP_TAKEOFF < PlayerController.JUMP_TOUCHDOWN and PlayerController.JUMP_TOUCHDOWN < PlayerController.JUMP_MOVE_EXIT)
	assert_true(PlayerController.JUMP_MOVE_EXIT < PlayerController.JUMP_SETTLE)
	# Kayıt: alım meshy.json'da (anim_batch_12), aynı hareket ikinci kez alınmadı.
	var tasks: Dictionary = (ClipLibrary.read_json("res://assets/_meshy_raw/_anim_library/meshy.json") as Dictionary).get("tasks", {})
	if tasks.is_empty():
		return
	var owners := 0
	for name: String in tasks:
		if (tasks[name] as Dictionary).get("action_ids", []).has(466.0):
			owners += 1
	assert_eq(owners, 1, "466 yalnız bir kez alındı (K90)")
	assert_eq(str((tasks["anim_batch_12"] as Dictionary).get("status")), "SUCCEEDED")


func test_child_jumps_in_place_and_lands_on_her_feet() -> void:
	var player := await _make_player(true)
	assert_true(player.get_avatar().available_roles().has(PlayerController.ROLE_JUMP), "Çocuğun zıplama rolü")
	var jumped := watch_signal(player.jumped)
	var landed := watch_signal(player.landed)
	var ground := player.global_position.y
	assert_true(player.jump(), "Zıplar")
	assert_true(player.is_jumping())
	assert_false(player.is_airborne(), "Önce çömelir")
	assert_false(player.jump(), "Zıplarken yeniden zıplamaz")
	var takeoff := -1.0
	var touchdown := -1.0
	var hips_peak := -INF
	var hips_stand := _hips_y(player)
	var t := 0.0
	while player.is_jumping() and t < 3.0:
		player.step(DT, Vector2.ZERO, false, 0.0)
		player.get_avatar().get_animation_player().advance(DT)
		t += DT
		assert_almost(player.global_position.y, ground, 0.0001, "Düğüm yerde kalır: kamera sarsılmaz")
		if player.is_airborne() and takeoff < 0.0:
			takeoff = t
		if takeoff >= 0.0 and not player.is_airborne() and touchdown < 0.0:
			touchdown = t
		if player.is_airborne():
			hips_peak = maxf(hips_peak, _hips_y(player))
	assert_eq(player.get_stance(), PlayerController.Stance.FOOT, "İner ve durur")
	assert_between(takeoff, 0.1, 0.3, "Çömelme kısa (%.2f sn)" % takeoff)
	assert_between(touchdown - takeoff, 0.45, 0.65, "Havada ≈0,56 sn (%.2f)" % (touchdown - takeoff))
	assert_between(t, 1.0, 1.6, "Bütün zıplama (%.2f sn)" % t)
	assert_eq(jumped.count, 1)
	assert_eq(landed.count, 1)
	assert_true(hips_peak > hips_stand + 0.15, "Kalça havada yükselir (%.2f → %.2f)" % [hips_stand, hips_peak])
	assert_almost(player.get_avatar().position.y, 0.0, 0.001, "Avatar yine düğümün kökünde")
	assert_almost(player.get_speed(), 0.0, 0.001, "Yerinde zıpladı")
	assert_eq(player.get_avatar().get_current_role(), &"idle", "Beklemeye döner")


func test_running_jump_keeps_its_way_and_turns_little_in_the_air() -> void:
	var player := await _make_player(true)
	_steps(player, Vector2(0.0, 1.0), true, 1.0)
	var run := player.get_speed()
	assert_almost(run, player.run_speed, 0.05)
	var from := player.global_position
	assert_true(player.jump())
	var heading := Vector2(player.velocity.x, player.velocity.z).normalized()
	# Havada sağa çekiş: yön az değişir.
	var air_turn := 0.0
	var t := 0.0
	while player.is_jumping() and t < 3.0:
		var input := Vector2(1.0, 0.0) if player.is_airborne() else Vector2(0.0, 1.0)
		player.step(DT, input, true, 0.0)
		t += DT
		if player.is_airborne():
			air_turn = maxf(air_turn, absf(Vector2(player.velocity.x, player.velocity.z).normalized().angle_to(heading)))
	assert_true(air_turn < deg_to_rad(35.0), "Havada yön az değişir (%.1f°)" % rad_to_deg(air_turn))
	assert_true(air_turn > deg_to_rad(2.0), "Ama biraz değişir (%.1f°)" % rad_to_deg(air_turn))
	var distance := Vector2(player.global_position.x - from.x, player.global_position.z - from.z).length()
	assert_true(distance > 2.0, "Koşarak zıplayınca yol alır (%.2f m)" % distance)
	assert_true(t < 1.0, "Koşarken iniş biter bitmez koşuya karışır (%.2f sn)" % t)
	_steps(player, Vector2(0.0, 1.0), true, 0.4)
	assert_eq(player.get_avatar().get_current_role(), &"run", "Koşmayı sürdürür")
	assert_true(player.get_speed() > run * 0.8, "Hız düşmez (%.2f)" % player.get_speed())


func test_no_jump_while_riding_aiming_seated_or_mounting() -> void:
	var player := await _make_player(true)
	var sheep := SHEEP_SCENE.instantiate() as RideableSheep
	add_child(sheep)
	_trash.append(sheep)
	sheep.place(Vector3(0.0, 0.4, 0.0), 0.0)
	await wait_frames(1)
	player.spawn_at(Vector3(0.9, 0.0, 0.0), 0.0)
	player.begin_mount(sheep)
	assert_false(player.jump(), "Binerken zıplanmaz")
	_steps(player, Vector2.ZERO, false, 1.0)
	assert_true(player.is_riding())
	assert_false(player.jump(), "Sırttayken zıplanmaz")
	player.interact()
	_steps(player, Vector2.ZERO, false, 1.0)
	assert_true(player.begin_aim(), "Nişan")
	assert_false(player.jump(), "Nişanda zıplanmaz")
	player.archer().cancel()
	player.sit_at(Transform3D(Basis.IDENTITY, Vector3(3.0, 0.4, 0.0)))
	assert_false(player.jump(), "Otururken zıplanmaz")


func test_adult_jumps_the_same_way() -> void:
	var player := await _make_player(false)
	assert_false(player.is_child())
	assert_true(player.get_avatar().available_roles().has(PlayerController.ROLE_JUMP), "Yetişkinin de zıplama rolü")
	var hips_stand := _hips_y(player)
	var hips_peak := -INF
	assert_true(player.jump())
	var t := 0.0
	while player.is_jumping() and t < 3.0:
		player.step(DT, Vector2.ZERO, false, 0.0)
		player.get_avatar().get_animation_player().advance(DT)
		if player.is_airborne():
			hips_peak = maxf(hips_peak, _hips_y(player))
		t += DT
	assert_eq(player.get_stance(), PlayerController.Stance.FOOT)
	assert_between(t, 1.0, 1.6, "Çocuktaki gibi (%.2f sn)" % t)
	assert_true(hips_peak > hips_stand + 0.25, "Yetişkin boyunca yükselir (%.2f → %.2f)" % [hips_stand, hips_peak])


func test_chibi_fallback_hops_with_code() -> void:
	var player := PlayerController.new()
	player.terrain_shape = FlatShape.new()
	player.start_active = false
	var avatar := CharacterAvatar.new()
	avatar.use_meshy_models = false
	player.add_child(avatar)
	add_child(player)
	_trash.append(player)
	player.set_process(false)
	await wait_frames(1)
	assert_true(player.jump(), "Klip yoksa da zıplar")
	var peak := 0.0
	var t := 0.0
	while player.is_jumping() and t < 2.0:
		player.step(DT, Vector2.ZERO, false, 0.0)
		peak = maxf(peak, avatar.position.y)
		t += DT
	assert_between(peak, PlayerController.HOP_HEIGHT * 0.8, PlayerController.HOP_HEIGHT * 1.01, "Kodla seker")
	assert_almost(avatar.position.y, 0.0, 0.0001)


func test_jump_action_jumps_when_registered() -> void:
	var player := await _make_player(true)
	var added := false
	if not InputMap.has_action(&"jump"):
		InputMap.add_action(&"jump")
		added = true
	var event := InputEventAction.new()
	event.action = &"jump"
	event.pressed = true
	player._unhandled_input(event)
	assert_true(player.is_jumping(), "Boşluk (jump eylemi) zıplatır")
	if added:
		InputMap.erase_action(&"jump")


func _make_player(child: bool) -> PlayerController:
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
		player.use_profile(CharacterProfile.new())
	player.set_active(true)
	player.spawn_at(Vector3.ZERO, 0.0)
	return player


func _steps(player: PlayerController, input: Vector2, sprint: bool, seconds: float) -> void:
	for i in int(round(seconds / DT)):
		player.step(DT, input, sprint, 0.0)


## Kalça kemiğinin dünya yüksekliği (oynatıcının son uyguladığı poz).
func _hips_y(player: PlayerController) -> float:
	var skeleton := player.get_avatar().get_skeleton()
	if skeleton == null:
		return 0.0
	skeleton.force_update_all_bone_transforms()
	return (skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("Hips")).origin).y
