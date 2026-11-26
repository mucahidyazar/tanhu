extends TestCase
## Toynakların yere basması (Yol Haritası horse-rig; godot.md §6.7 «Toynak yere TwoBoneIK3D ile basar», K65): RideableHooves (planlayıcı,
## TwoBoneIK3D, hizalayıcı) bineğin ve aynı planın her dört ayaklısının toynağını gerçek zemine koyar: yan yatık yamaçta, basamakta, yürürken;
## düz zeminde ve zemini verilmeyen binekte (kampın ve menünün atları) hiçbir kemiğe dokunulmaz; sıçramanın havasında kapanır.

const BROWN := "res://assets/animals/horse_brown/horse_brown.glb"
## Toynağın tabanla zemin arasındaki en büyük fark (m; basan toynak).
const SOLE_TOLERANCE := 0.015
const SPECIES: Array[String] = ["sheep", "camel", "cattle", "deer", "dog", "gazelle", "wolf"]


class Ground:
	extends TerrainShape
	var kind := "flat"
	var degrees := 14.0
	var step := 0.22

	func height_at(x: float, z: float) -> float:
		match kind:
			"lateral":
				return x * tan(deg_to_rad(degrees))
			"pitch":
				return z * tan(deg_to_rad(degrees))
			"step":
				# Basamak: 22 cm, 25 cm'lik kenarda yükselir (kampın ve iç haritanın ızgarasından keskin).
				return step * smoothstep(-0.125, 0.125, z)
		return 0.0


var _trash: Array[Node] = []


func before_each() -> void:
	Mount.reset_cache()


func after_each() -> void:
	for node in _trash:
		if is_instance_valid(node):
			node.queue_free()
	_trash.clear()


func test_without_ground_the_clip_pose_is_kept() -> void:
	var horse := _horse(Vector3.ZERO, 0.0)
	await wait_frames(3)
	assert_null(horse.hooves(), "Zemini verilmeyen atın (kampın ve menünün atları) toynak IK'sı kurulmaz: menü karesi değişmez")
	assert_eq(horse.body_offset(), 0.0)
	var skeleton: Skeleton3D = horse.find_children("*", "Skeleton3D", true, false)[0]
	for child in skeleton.get_children():
		assert_false(child is TwoBoneIK3D, "İskelette IK yok")


func test_flat_ground_leaves_every_bone_alone() -> void:
	var ground := Ground.new()
	var horse := _horse(Vector3.ZERO, 0.0)
	horse.set_ground(ground)
	await wait_frames(4)
	var hooves := horse.hooves()
	assert_not_null(hooves, "Zemin verilince kurulur")
	assert_false(hooves.touched, "Düz zeminde kemiklere dokunulmaz")
	assert_almost(hooves._ik.influence, 0.0, 0.0001, "IK'nın etkisi 0")
	for leg in RideableHooves.LEGS:
		var sole: Vector3 = hooves.last_soles[leg]
		assert_almost(sole.y, 0.0, 0.003, "%s klibin tabanında" % leg)


func test_lateral_slope_and_step_put_every_hoof_on_the_ground() -> void:
	for kind in ["lateral", "step"]:
		var ground := Ground.new()
		ground.kind = kind
		var horse := _horse(Vector3.ZERO, 0.0)
		horse.place(Vector3(0.0, ground.height_at(0.0, 0.0), 0.0), 0.0, PlayerController.ground_pitch(ground, Vector2.ZERO, 0.0, 0.83))
		horse.set_ground(ground)
		await wait_frames(40)
		var hooves := horse.hooves()
		assert_true(hooves.touched, "%s: kemiklere dokunulur" % kind)
		for leg in RideableHooves.LEGS:
			var sole: Vector3 = hooves.last_soles[leg]
			assert_almost(sole.y, ground.height_at(sole.x, sole.z), SOLE_TOLERANCE, "%s: %s zeminde (%.1f cm)" % [kind, leg, (sole.y - ground.height_at(sole.x, sole.z)) * 100.0])
		if kind == "lateral":
			assert_true(horse.body_offset() > 0.03, "Yan yamaçta gövde iner: alçak yandaki bacak yetişir (%.1f cm)" % (horse.body_offset() * 100.0))
		else:
			var front := (hooves.last_soles["FrontL"] as Vector3).y
			var hind := (hooves.last_soles["HindL"] as Vector3).y
			assert_almost(front - hind, ground.step, SOLE_TOLERANCE, "Ön toynaklar basamakta, arkalar aşağıda")
		horse.queue_free()


func test_walking_over_a_step_keeps_the_stance_hooves_down() -> void:
	var ground := Ground.new()
	ground.kind = "step"
	var horse := _horse(Vector3(0.0, 0.0, -2.5), 0.0)
	var player := PlayerController.new()
	player.terrain_shape = ground
	player.start_active = false
	player.add_child(CharacterAvatar.new())
	add_child(player)
	_trash.append(player)
	player.set_process(false)
	await wait_frames(1)
	player.obstacles = []
	player.use_child(ChildLook.PERSON_CHILD)
	player.set_active(true)
	player.spawn_at(Vector3(1.3, 0.0, -2.2), -PI * 0.5)
	assert_true(player.interact(), "Biner")
	var anim: AnimationPlayer = horse.find_children("*", "AnimationPlayer", true, false)[0]
	var dt := 1.0 / 60.0
	for i in 150:
		player.step(dt, Vector2.ZERO, false, 0.0)
		anim.advance(dt)
	assert_true(player.is_riding())
	var worst := 0.0
	var worst_at := ""
	var samples := 0
	var off_target := 0.0
	# Kameranın açısı π: giriş ileri +Z'ye yürütür (basamağa doğru).
	for i in 240:
		player.step(dt, Vector2(0.0, 1.0), false, PI)
		anim.advance(dt)
		await wait_frames(1)
		var hooves := horse.hooves()
		for leg in RideableHooves.LEGS:
			# Her toynak (salınımdaki de) hedefine iner: TwoBoneIK3D'nin zinciri doğrudan (Upper → Lower → Cannon), incik ve toynak hizalanır.
			if hooves.touched and hooves.blend >= 0.99 and hooves.last_soles.has(leg) and hooves.last_targets.has(leg):
				off_target = maxf(off_target, (hooves.last_soles[leg] as Vector3).distance_to(hooves.last_targets[leg]))
			if float(hooves.last_stance.get(leg, 0.0)) >= 0.99 and hooves.last_soles.has(leg):
				var sole: Vector3 = hooves.last_soles[leg]
				# Basamağın kenarı (rampa ve iki yanı 15 cm) sayılmaz: toynak orada rampanın eğimine yatar.
				# Basan toynağın zeminden yüksekliği klibin payı kadardır (klipte basan toynak düzlemden en çok STANCE_H kadar yukarıda).
				if absf(sole.z) > 0.15:
					var miss := absf(sole.y - ground.height_at(sole.x, sole.z) - float(hooves.last_clearance.get(leg, 0.0)))
					if miss > worst:
						worst = miss
						worst_at = "%s at z %.2f y %.3f taban %s hedef %s pay %.3f gövde %.3f etki %.2f" % [leg, horse.global_position.z, horse.global_position.y, sole, hooves.last_targets.get(leg), float(hooves.last_clearance.get(leg, -1.0)), horse.body_offset(), hooves._ik.influence]
					samples += 1
	assert_true(horse.global_position.z > 1.5, "At basamağı geçti (z %.2f)" % horse.global_position.z)
	assert_true(samples > 200, "Basan toynaklar ölçüldü (%d)" % samples)
	assert_true(off_target <= 0.01, "Salınımdaki toynak da hedefinde (en çok %.1f cm)" % (off_target * 100.0))
	assert_true(worst <= SOLE_TOLERANCE, "Basamağı geçerken basan toynak zeminde, klibin payıyla (en çok %.1f cm; %s)" % [worst * 100.0, worst_at])


func test_leap_switches_the_hooves_off_in_the_air() -> void:
	var ground := Ground.new()
	ground.kind = "lateral"
	var horse := _horse(Vector3.ZERO, 0.0)
	horse.set_ground(ground)
	horse.set_ridden(true)
	await wait_frames(20)
	assert_true(horse.hooves().blend > 0.9)
	assert_true(horse.leap(4.0))
	var airborne_blend := 1.0
	for i in 60:
		horse.drive(4.0, 1.0 / 60.0)
		await wait_frames(1)
		if horse.is_airborne():
			airborne_blend = minf(airborne_blend, horse.hooves().blend)
	assert_true(airborne_blend < 0.5, "Havada IK kapanır (en düşük etki %.2f)" % airborne_blend)


func test_the_same_rig_grounds_the_other_quadrupeds() -> void:
	var ground := Ground.new()
	ground.kind = "lateral"
	ground.degrees = 12.0
	for species in SPECIES:
		var path := "res://assets/animals/%s/%s.glb" % [species, species]
		if not ResourceLoader.exists(path):
			continue
		var root := (load(path) as PackedScene).instantiate() as Node3D
		add_child(root)
		_trash.append(root)
		var skeleton: Skeleton3D = root.find_children("*", "Skeleton3D", true, false)[0]
		assert_true(RideableHooves.has_legs(skeleton), "%s: aynı bacak planı (quadruped_rig.py)" % species)
		var anim: AnimationPlayer = root.find_children("*", "AnimationPlayer", true, false)[0]
		var idle := ""
		for clip in anim.get_animation_list():
			if String(clip).to_lower().contains("idle"):
				idle = clip
		if not idle.is_empty():
			anim.play(idle)
		var hooves := RideableHooves.attach(skeleton, ground, root)
		assert_not_null(hooves, species)
		# Gövde, toynakların inişini düğümde taşır (Rideable'ın Body'si gibi): kökü iner.
		for i in 30:
			await wait_frames(1)
			root.position.y = -hooves.step_offset(1.0 / 60.0)
		for leg in RideableHooves.LEGS:
			var sole: Vector3 = hooves.last_soles[leg]
			assert_almost(sole.y, ground.height_at(sole.x, sole.z), 0.02, "%s %s yan yamaçta zeminde (%.1f cm)" % [species, leg, (sole.y - ground.height_at(sole.x, sole.z)) * 100.0])


func _horse(at: Vector3, yaw: float) -> RideableHorse:
	var horse := RideableHorse.new()
	horse.model_path = BROWN
	horse.effects_enabled = false
	add_child(horse)
	_trash.append(horse)
	horse.place(at, yaw)
	return horse
