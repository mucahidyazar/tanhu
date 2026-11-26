extends TestCase
## Parmak kavraması (HandGrip; kemikleri tools/hand_rig.py ekler): varsayılan doğal el, set_grip, düz el, klip aktarımının parmaklara dokunmaması, belge sitesinin sabit izi,
## KopuzPlay ve CineActor bağı. Burada küçük bir iskelet kullanılır; bütün kadronun gerçek kemikleri test_rig_health.gd'dedir.

## El kemiğinden parmak ucuna uzaklık (iskelet birimi, parmak dümdüz).
const SEGMENT := 3.0


## İki elli küçük iskelet: parmaklar +Y boyunca, +X dönüşü parmağı +Z'ye (avuca) kapatır.
func _skeleton(fingers: bool = true) -> Skeleton3D:
	var skel := Skeleton3D.new()
	skel.add_bone("Hips")
	skel.set_bone_rest(0, Transform3D(Basis.IDENTITY, Vector3(0.0, 100.0, 0.0)))
	for side: StringName in HandGrip.SIDES:
		var hand := skel.get_bone_count()
		skel.add_bone("%sHand" % side)
		skel.set_bone_parent(hand, 0)
		skel.set_bone_rest(hand, Transform3D(Basis.IDENTITY, Vector3(-20.0 if side == &"Right" else 20.0, 0.0, 0.0)))
		if not fingers:
			continue
		for f: String in HandGrip.FINGERS:
			var parent := hand
			for j in HandGrip.JOINTS:
				var bone := skel.get_bone_count()
				skel.add_bone("%s%s%d" % [side, f, j + 1])
				skel.set_bone_parent(bone, parent)
				skel.set_bone_rest(bone, Transform3D(Basis.IDENTITY, Vector3(0.0, SEGMENT, 0.0)))
				parent = bone
	skel.reset_bone_poses()
	add_child(skel)
	return skel


## Parmağın ucunun (orta boğumdan SEGMENT ileride) el kemiğine göre yeri.
func _tip(skel: Skeleton3D, side: StringName, finger: String) -> Vector3:
	var hand := skel.get_bone_global_pose(skel.find_bone("%sHand" % side))
	var last := skel.get_bone_global_pose(skel.find_bone("%s%s2" % [side, finger]))
	return hand.affine_inverse() * (last * Vector3(0.0, SEGMENT, 0.0))


func test_finger_names_are_not_meshy_names() -> void:
	for bone_name: String in ["LeftThumb1", "RightPinky2", "LeftMiddle1", "RightRing2", "LeftIndex2"]:
		assert_true(HandGrip.is_finger_bone(bone_name), "%s parmaktır" % bone_name)
	for bone_name: String in ["LeftHand", "RightHand", "LeftForeArm", "LeftArm", "LeftShoulder", "LeftLeg", "RightUpLeg", "LeftFoot", "LeftToeBase", "Hips", "Spine02", "headfront"]:
		assert_false(HandGrip.is_finger_bone(bone_name), "%s Meshy kemiğidir" % bone_name)
		assert_true(ClipRetarget.is_limb(bone_name) or not bone_name.contains("Thumb"), "ad çakışmaz")
	for bone_name: String in ["LeftThumb1", "LeftIndex1", "LeftMiddle2", "LeftRing1", "LeftPinky2"]:
		assert_false(ClipRetarget.is_limb(bone_name), "%s kol ya da bacak anahtarı taşımaz" % bone_name)


func test_no_finger_bones_means_no_grip() -> void:
	var skel := _skeleton(false)
	assert_false(HandGrip.has_fingers(skel))
	assert_null(HandGrip.attach(skel), "Parmak kemiği yoksa denetçi yok")
	assert_null(HandGrip.attach(null), "İskelet yoksa denetçi yok")
	skel.free()


func test_chibi_fallback_is_silent() -> void:
	var avatar := CharacterAvatar.new()
	avatar.use_meshy_models = false
	add_child(avatar)
	await wait_frames(1)
	assert_null(avatar.hand_grip, "Chibi yedeğinde kavrama yok")
	avatar.set_grip(&"Right", 1.0)
	avatar.relax_hand(&"Right", 0.5)
	avatar.free()


func test_default_hand_is_half_relaxed_and_grip_closes_toward_the_palm() -> void:
	var skel := _skeleton()
	var grip := HandGrip.attach(skel)
	assert_not_null(grip)
	skel.reset_bone_poses()
	var straight := _tip(skel, &"Left", "Middle")
	assert_vec_almost(straight, Vector3(0.0, SEGMENT * 3.0, 0.0), 0.001, "Dinlenmede parmak düz")
	grip._process_modification()
	var natural := _tip(skel, &"Left", "Middle")
	assert_true(natural.z > 0.5, "Doğal el avuca doğru biraz kapalı (%.2f)" % natural.z)
	assert_true(natural.y < straight.y, "Doğal elde uç gelir")
	grip.set_grip(&"Left", 1.0)
	grip._process_modification()
	var fist := _tip(skel, &"Left", "Middle")
	assert_true(fist.length() < natural.length() * 0.75, "Yumrukta uç avuca yaklaşır (%.2f → %.2f)" % [natural.length(), fist.length()])
	assert_almost((skel.get_bone_pose_rotation(skel.find_bone("LeftIndex1"))).get_angle(), deg_to_rad(HandGrip.FULL_CURL[1].x), 0.001, "Kök boğum tam açı")
	# Öteki el etkilenmez, aynı adımda aynı açıyla kapanır.
	assert_almost(skel.get_bone_pose_rotation(skel.find_bone("RightIndex1")).get_angle(), deg_to_rad(HandGrip.FULL_CURL[1].x * HandGrip.NATURAL_SHAPE[1]), 0.001, "Sağ el doğal kaldı")
	grip.set_grip(&"Right", 1.0)
	grip._process_modification()
	assert_almost(skel.get_bone_pose_rotation(skel.find_bone("RightIndex1")).get_angle(), skel.get_bone_pose_rotation(skel.find_bone("LeftIndex1")).get_angle(), 0.0001, "Sol ve sağ simetrik")
	grip.relax(&"Left")
	grip._process_modification()
	assert_vec_almost(_tip(skel, &"Left", "Middle"), natural, 0.001, "Doğal ele döner")
	skel.free()


func test_flat_hands_stay_open_on_the_ground() -> void:
	var skel := _skeleton()
	var grip := HandGrip.attach(skel)
	grip.set_flat_hands(["LeftHand"])
	grip._process_modification()
	assert_vec_almost(_tip(skel, &"Left", "Ring"), Vector3(0.0, SEGMENT * 3.0, 0.0), 0.001, "Yere dayanan el düz")
	assert_true(_tip(skel, &"Right", "Ring").z > 0.5, "Öteki el doğal")
	grip.set_flat_hands([])
	grip._process_modification()
	assert_true(_tip(skel, &"Left", "Ring").z > 0.5, "Klip bitince doğal ele döner")
	skel.free()


func test_timed_grip_reaches_its_target() -> void:
	var skel := _skeleton()
	var grip := HandGrip.attach(skel)
	grip.set_grip(&"Right", 1.0, 0.05)
	assert_true(grip.shape_of(&"Right")[1] < 0.5, "Süreli geçiş hemen bitmez")
	await get_tree().create_timer(0.15).timeout
	# Yük altında tek kare süreyi aşabilir: zamanlayıcı geçişten önce işlenir.
	await wait_frames(2)
	assert_almost(grip.shape_of(&"Right")[1], 1.0, 0.001, "Süre sonunda hedefte")
	skel.free()


func test_grip_cost_stays_small() -> void:
	var skel := _skeleton()
	var grip := HandGrip.attach(skel)
	grip._process_modification()
	var start := Time.get_ticks_usec()
	for i in 200:
		grip._process_modification()
		skel.get_bone_global_pose(skel.find_bone("RightPinky2"))
	var per_frame := (Time.get_ticks_usec() - start) / 200.0
	assert_true(per_frame < 200.0, "Kare başına %.0f mikrosaniye (kişi başına)" % per_frame)
	skel.free()


func test_retarget_leaves_fingers_alone_and_keeps_the_rest_of_the_clip() -> void:
	var source := _skeleton(false)
	var with_fingers := _skeleton(true)
	var without := _skeleton(false)
	var anim := Animation.new()
	anim.length = 1.0
	for bone_name: String in ["Hips", "LeftHand", "RightHand"]:
		var t := anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(t, NodePath("Armature/Skeleton3D:%s" % bone_name))
		anim.rotation_track_insert_key(t, 0.0, Quaternion.IDENTITY)
		anim.rotation_track_insert_key(t, 1.0, Quaternion(Vector3.RIGHT, 0.4))
	var a := ClipRetarget.retarget(anim, source, with_fingers, ClipRetarget.Mode.ROTATION)
	var b := ClipRetarget.retarget(anim, source, without, ClipRetarget.Mode.ROTATION)
	var prefix := ClipRetarget.track_prefix(a)
	assert_eq(a.find_track(NodePath("%s:LeftIndex1" % prefix), Animation.TYPE_ROTATION_3D), -1, "Parmak kemiğine klip yazılmaz")
	assert_eq(a.get_track_count(), b.get_track_count(), "İz sayısı parmaktan etkilenmez")
	for t in b.get_track_count():
		var other := a.find_track(b.track_get_path(t), b.track_get_type(t))
		assert_true(other >= 0)
		if b.track_get_type(t) == Animation.TYPE_ROTATION_3D:
			var p: Quaternion = a.rotation_track_interpolate(other, 0.5)
			var q: Quaternion = b.rotation_track_interpolate(t, 0.5)
			assert_true(Vector4(p.x - q.x, p.y - q.y, p.z - q.z, p.w - q.w).length() < 0.00001, "Parmak dışında çıktı aynı")
	# Oyunun klip kuralı: parmakta dinlenme izi; poz HandGrip'ten gelir.
	assert_true(ClipLibrary.complete_rest_tracks(a, with_fingers) >= 20, "Parmaklara dinlenme izi")
	source.free()
	with_fingers.free()
	without.free()


func test_bake_pose_writes_natural_fingers_for_the_site() -> void:
	var skel := _skeleton()
	var anim := Animation.new()
	anim.length = 2.0
	var t := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(t, ^"Armature/Skeleton3D:Hips")
	anim.rotation_track_insert_key(t, 0.0, Quaternion.IDENTITY)
	ClipLibrary.complete_rest_tracks(anim, skel)
	assert_eq(HandGrip.bake_pose(anim, skel, HandGrip.NATURAL_SHAPE, ["LeftHand"]), 20, "İki elde yirmi kemik")
	var right := anim.find_track(^"Armature/Skeleton3D:RightMiddle1", Animation.TYPE_ROTATION_3D)
	assert_true(right >= 0)
	assert_almost((anim.rotation_track_interpolate(right, 1.0)).get_angle(), deg_to_rad(HandGrip.FULL_CURL[2].x * HandGrip.NATURAL_SHAPE[2]), 0.001, "Doğal el sabit iz")
	var left := anim.find_track(^"Armature/Skeleton3D:LeftMiddle1", Animation.TYPE_ROTATION_3D)
	assert_almost((anim.rotation_track_interpolate(left, 1.0)).get_angle(), 0.0, 0.001, "Yere dayanan el düz")
	assert_eq(HandGrip.bake_pose(anim, _empty_skeleton(), HandGrip.NATURAL_SHAPE), 0, "Parmak kemiği yoksa iz yazılmaz")
	skel.free()


func _empty_skeleton() -> Skeleton3D:
	var skel := Skeleton3D.new()
	skel.add_bone("Hips")
	add_child(skel)
	skel.queue_free()
	return skel


func test_kopuz_lift_closes_the_hands() -> void:
	var skel := _skeleton()
	var bard := CharacterAvatar.new()
	bard.hand_grip = HandGrip.attach(skel)
	var play := KopuzPlay.attach(bard, null)
	assert_eq(play.grip, bard.hand_grip)
	play.set_lift(1.0)
	assert_almost(bard.hand_grip.shape_of(&"Left")[2], HandGrip.GRIP_NECK[2], 0.0001, "Sol el sapı kavrar")
	assert_almost(bard.hand_grip.shape_of(&"Right")[1], HandGrip.STRUM_SHAPE[1], 0.0001, "Sağ el teller üstünde")
	play.set_lift(0.5)
	assert_almost(bard.hand_grip.shape_of(&"Left")[2], lerpf(HandGrip.NATURAL_SHAPE[2], HandGrip.GRIP_NECK[2], 0.5), 0.0001, "Kalkışla birlikte")
	play.set_lift(0.0)
	assert_almost(bard.hand_grip.shape_of(&"Left")[2], HandGrip.NATURAL_SHAPE[2], 0.0001, "Kucakta doğal el")
	skel.free()
	play.grip = null
	bard.free()


func test_cine_actor_grip_follows_its_amount() -> void:
	var skel := _skeleton()
	var actor := CineActor.new()
	var avatar := CharacterAvatar.new()
	avatar.hand_grip = HandGrip.attach(skel)
	actor.avatar = avatar
	actor.reach_grips = {&"Right": 0.85}
	actor.reach_amount = 1.0
	assert_almost(avatar.hand_grip.shape_of(&"Right")[2], lerpf(HandGrip.NATURAL_SHAPE[2], HandGrip.FIST_SHAPE[2], 0.85), 0.0001, "Uzanan el kapanır")
	assert_almost(avatar.hand_grip.shape_of(&"Left")[2], HandGrip.NATURAL_SHAPE[2], 0.0001, "Öteki el doğal")
	actor.reach_amount = 0.0
	assert_almost(avatar.hand_grip.shape_of(&"Right")[2], HandGrip.NATURAL_SHAPE[2], 0.0001, "Etki bitince doğal el; ileri sarmada da aynı kare")
	actor.avatar = null
	skel.free()
	avatar.hand_grip = null
	avatar.free()
	actor.free()
