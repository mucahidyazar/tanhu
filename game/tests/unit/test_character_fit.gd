extends TestCase
## Gerçek boylu Meshy karakterleri için yardımcılar: klip aktarımı (ClipRetarget), poz ölçümü (PoseFit),
## CharacterAvatar'ın klip/zemin payı yardımcıları ve gerçek Mete modeliyle birkaç uçtan uca denetim.

const METE := "mete"


# --- CharacterAvatar yardımcıları -----------------------------------------------------

func test_make_in_place_removes_drift_but_keeps_sway() -> void:
	var anim := Animation.new()
	anim.length = 1.0
	var t := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(t, ^"Armature/Skeleton3D:Hips")
	anim.position_track_insert_key(t, 0.0, Vector3(0.0, 1.0, 0.0))
	anim.position_track_insert_key(t, 0.5, Vector3(0.1, 0.95, 0.5))
	anim.position_track_insert_key(t, 1.0, Vector3(0.0, 1.0, 1.0))
	CharacterAvatar.make_in_place(anim)
	assert_vec_almost(anim.track_get_key_value(t, 0), Vector3(0.0, 1.0, 0.0), 0.0001)
	assert_vec_almost(anim.track_get_key_value(t, 1), Vector3(0.1, 0.95, 0.0), 0.0001, "Yana salınma ve inip kalkma korunmalı")
	assert_vec_almost(anim.track_get_key_value(t, 2), Vector3(0.0, 1.0, 0.0), 0.0001, "İleri kayma silinmeli")


func test_make_in_place_leaves_in_place_clip_unchanged() -> void:
	var anim := Animation.new()
	var t := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(t, ^"Armature/Skeleton3D:Hips")
	anim.position_track_insert_key(t, 0.0, Vector3(-0.7, 102.0, 10.5))
	anim.position_track_insert_key(t, 0.5, Vector3(-0.2, 99.0, 11.0))
	anim.position_track_insert_key(t, 1.0, Vector3(-0.7, 102.0, 10.5))
	CharacterAvatar.make_in_place(anim)
	assert_vec_almost(anim.track_get_key_value(t, 1), Vector3(-0.2, 99.0, 11.0), 0.0001, "Yerinde klip değişmemeli")


func test_is_cyclic_detects_loops() -> void:
	var loop := Animation.new()
	var r := loop.add_track(Animation.TYPE_ROTATION_3D)
	loop.track_set_path(r, ^"Armature/Skeleton3D:Spine")
	loop.rotation_track_insert_key(r, 0.0, Quaternion.IDENTITY)
	loop.rotation_track_insert_key(r, 1.0, Quaternion(Vector3.RIGHT, 0.3))
	loop.rotation_track_insert_key(r, 2.0, Quaternion(Vector3.RIGHT, 0.005))
	assert_true(CharacterAvatar.is_cyclic(loop), "İlk ve son pozu aynı klip döngülüdür")
	var transition := Animation.new()
	var p := transition.add_track(Animation.TYPE_POSITION_3D)
	transition.track_set_path(p, ^"Armature/Skeleton3D:Hips")
	transition.position_track_insert_key(p, 0.0, Vector3(0.0, 100.0, 0.0))
	transition.position_track_insert_key(p, 2.0, Vector3(0.0, 28.0, 0.0))
	assert_false(CharacterAvatar.is_cyclic(transition), "Ayaktan oturmaya geçiş döngülü değildir")


func test_fit_value_and_run_threshold() -> void:
	var fit := {"ground_offset": {"sit": -0.05, "idle": 0.02}, "clip_speed": {"walk": 1.4}}
	assert_almost(CharacterAvatar.fit_value(fit, "ground_offset", &"sit", 0.0), -0.05)
	assert_almost(CharacterAvatar.fit_value(fit, "ground_offset", &"run", 0.3), 0.3, 0.0001, "Ölçülmemiş rol varsayılanı alır")
	assert_almost(CharacterAvatar.fit_value({}, "clip_speed", &"walk", 1.6), 1.6)
	assert_almost(CharacterAvatar.run_threshold(1.4, 4.6), 3.0)


func test_avatar_fallback_has_height_and_no_offsets() -> void:
	var avatar := CharacterAvatar.new()
	avatar.use_meshy_models = false
	add_child(avatar)
	await wait_frames(1)
	assert_true(avatar.get_model_height() > 0.5, "Chibi yedeğinin de bir boyu olmalı")
	assert_true(avatar.get_head_height() < avatar.get_model_height())
	assert_almost(avatar.ground_offset(&"sit"), 0.0)
	assert_almost(avatar.clip_speed(&"walk"), CharacterAvatar.WALK_SPEED)
	assert_null(avatar.get_skeleton())
	avatar.queue_free()


# --- ClipRetarget -----------------------------------------------------------------------

## İki kemikli küçük bir iskelet: kök "Hips" ve onun çocuğu "Leg". leg_rest: bacağın yerel dinlenme dönüşü.
func _skeleton(leg_rest: Quaternion, leg_offset: Vector3, hips_height: float) -> Skeleton3D:
	var skel := Skeleton3D.new()
	skel.add_bone("Hips")
	skel.add_bone("Leg")
	skel.add_bone("LegEnd")
	skel.set_bone_parent(1, 0)
	skel.set_bone_parent(2, 1)
	skel.set_bone_rest(0, Transform3D(Basis.IDENTITY, Vector3(0.0, hips_height, 0.0)))
	skel.set_bone_rest(1, Transform3D(Basis(leg_rest), leg_offset))
	skel.set_bone_rest(2, Transform3D(Basis.IDENTITY, Vector3(0.0, 40.0, 0.0)))
	return skel


func test_retarget_onto_same_skeleton_reproduces_clip() -> void:
	var skel := _skeleton(Quaternion(Vector3.RIGHT, PI), Vector3(10.0, -8.0, 0.0), 100.0)
	var anim := Animation.new()
	anim.length = 1.0
	var r := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(r, ^"Armature/Skeleton3D:Leg")
	var bent := Quaternion(Vector3.RIGHT, PI) * Quaternion(Vector3.RIGHT, -1.2)
	anim.rotation_track_insert_key(r, 0.0, bent)
	anim.rotation_track_insert_key(r, 1.0, bent)
	var p := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(p, ^"Armature/Skeleton3D:Hips")
	anim.position_track_insert_key(p, 0.0, Vector3(0.0, 30.0, 0.0))
	anim.position_track_insert_key(p, 1.0, Vector3(0.0, 30.0, 0.0))
	for mode in [ClipRetarget.Mode.ROTATION, ClipRetarget.Mode.DIRECTION]:
		var out := ClipRetarget.retarget(anim, skel, skel, mode)
		var leg := out.find_track(^"Armature/Skeleton3D:Leg", Animation.TYPE_ROTATION_3D)
		assert_true(leg >= 0, "Bacak izi olmalı")
		if leg >= 0:
			var q: Quaternion = out.rotation_track_interpolate(leg, 0.5)
			assert_almost(q.angle_to(bent), 0.0, 0.001, "Kendine aktarım aynı dönüşü vermeli (yöntem %d)" % mode)
		var hips := out.find_track(^"Armature/Skeleton3D:Hips", Animation.TYPE_POSITION_3D)
		assert_vec_almost(out.position_track_interpolate(hips, 0.5), Vector3(0.0, 30.0, 0.0), 0.001)
	skel.free()


func test_retarget_transfers_pose_across_different_bone_axes() -> void:
	# Kaynakta bacak kemiğinin yerel ekseni farklı (dinlenmede X etrafında 180° dönük), hedefte birim. Aktarımdan
	# sonra iki iskelette de bacağın ucu (LegEnd) iskelet uzayında aynı yöne bakmalı.
	var source := _skeleton(Quaternion(Vector3.RIGHT, PI), Vector3(10.0, -8.0, 0.0), 100.0)
	var target := _skeleton(Quaternion.IDENTITY, Vector3(10.0, -8.0, 0.0), 90.0)
	target.set_bone_rest(2, Transform3D(Basis.IDENTITY, Vector3(0.0, -40.0, 0.0)))
	var anim := Animation.new()
	anim.length = 1.0
	var r := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(r, ^"Armature/Skeleton3D:Leg")
	var posed := Quaternion(Vector3.RIGHT, PI) * Quaternion(Vector3.RIGHT, -1.0)
	anim.rotation_track_insert_key(r, 0.0, posed)
	anim.rotation_track_insert_key(r, 1.0, posed)
	var p := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(p, ^"Armature/Skeleton3D:Hips")
	anim.position_track_insert_key(p, 0.0, Vector3(0.0, 40.0, 0.0))
	anim.position_track_insert_key(p, 1.0, Vector3(0.0, 40.0, 0.0))
	var out := ClipRetarget.retarget(anim, source, target)
	var leg := out.find_track(^"Armature/Skeleton3D:Leg", Animation.TYPE_ROTATION_3D)
	var q: Quaternion = out.rotation_track_interpolate(leg, 0.0)
	var source_dir := (posed * Vector3(0.0, 40.0, 0.0)).normalized()
	var target_dir := (q * Vector3(0.0, -40.0, 0.0)).normalized()
	assert_vec_almost(target_dir, source_dir, 0.001, "Bacak iki iskelette de aynı yöne uzanmalı")
	var hips := out.find_track(^"Armature/Skeleton3D:Hips", Animation.TYPE_POSITION_3D)
	assert_vec_almost(out.position_track_interpolate(hips, 0.0), Vector3(0.0, 36.0, 0.0), 0.001, "Kalça yüksekliği boy oranıyla ölçeklenmeli (90/100)")
	source.free()
	target.free()


## İki bacaklı küçük iskelet: Hips, iki kalça, iki diz, iki bilek. Dizler kalça-bilek çizgisinin biraz önünde.
func _legged_skeleton(hips_height: float, thigh: float, shin: float, right_hip_lift: float = 0.0) -> Skeleton3D:
	var skel := Skeleton3D.new()
	skel.add_bone("Hips")
	skel.set_bone_rest(0, Transform3D(Basis.IDENTITY, Vector3(0.0, hips_height, 0.0)))
	for side: String in ["Left", "Right"]:
		var x := 10.0 if side == "Left" else -10.0
		var up := skel.add_bone(side + "UpLeg")
		skel.set_bone_parent(up, 0)
		skel.set_bone_rest(up, Transform3D(Basis.IDENTITY, Vector3(x, -8.0 + (right_hip_lift if side == "Right" else 0.0), 0.0)))
		var leg := skel.add_bone(side + "Leg")
		skel.set_bone_parent(leg, up)
		skel.set_bone_rest(leg, Transform3D(Basis.IDENTITY, Vector3(0.0, -thigh, 2.0)))
		var foot := skel.add_bone(side + "Foot")
		skel.set_bone_parent(foot, leg)
		skel.set_bone_rest(foot, Transform3D(Basis.IDENTITY, Vector3(0.0, -shin, -2.0)))
	return skel


func _still_clip(tracks: Dictionary, hips: Vector3) -> Animation:
	var anim := Animation.new()
	anim.length = 1.0
	for bone: String in tracks:
		var r := anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(r, NodePath("Armature/Skeleton3D:%s" % bone))
		anim.rotation_track_insert_key(r, 0.0, tracks[bone])
		anim.rotation_track_insert_key(r, 1.0, tracks[bone])
	var p := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(p, ^"Armature/Skeleton3D:Hips")
	anim.position_track_insert_key(p, 0.0, hips)
	anim.position_track_insert_key(p, 1.0, hips)
	return anim


## K92: kaynağın sabiti çıkarılır, hedefin sabiti eklenir. Kaynak Hips'i sabit kadar dönük olsa da hedef düz durur.
func test_retarget_removes_source_constant_and_adds_target_constant() -> void:
	var source := _skeleton(Quaternion.IDENTITY, Vector3(10.0, -8.0, 0.0), 100.0)
	var target := _skeleton(Quaternion.IDENTITY, Vector3(10.0, -8.0, 0.0), 100.0)
	var constant := Quaternion(Vector3.RIGHT, deg_to_rad(16.0))
	var extra := Quaternion(Vector3.RIGHT, deg_to_rad(-5.0))
	ClipRetarget._quaternions["test_kaynak"] = {"Hips": constant}
	ClipRetarget._quaternions["test_hedef"] = {"Hips": extra}
	var anim := _still_clip({"Hips": constant}, Vector3(0.0, 100.0, 0.0))
	var plain := ClipRetarget.retarget(anim, source, target, ClipRetarget.Mode.ROTATION)
	var hips := plain.find_track(^"Armature/Skeleton3D:Hips", Animation.TYPE_ROTATION_3D)
	assert_almost((plain.rotation_track_interpolate(hips, 0.5) as Quaternion).angle_to(constant), 0.0, 0.001, "Kimlik verilmezse sabit olduğu gibi kopyalanır")
	var clean := ClipRetarget.retarget(anim, source, target, ClipRetarget.Mode.ROTATION, ClipRetarget.DEFAULT_FPS, ClipRetarget.LIMB_KEYS, "test_kaynak")
	assert_almost((clean.rotation_track_interpolate(hips, 0.5) as Quaternion).angle_to(Quaternion.IDENTITY), 0.0, 0.001, "Kaynağın sabiti çıkmalı")
	var own := ClipRetarget.retarget(anim, source, target, ClipRetarget.Mode.ROTATION, ClipRetarget.DEFAULT_FPS, ClipRetarget.LIMB_KEYS, "test_kaynak", "test_hedef")
	assert_almost((own.rotation_track_interpolate(hips, 0.5) as Quaternion).angle_to(extra), 0.0, 0.001, "Hedefin sabiti eklenmeli")
	ClipRetarget._quaternions.erase("test_kaynak")
	ClipRetarget._quaternions.erase("test_hedef")
	source.free()
	target.free()


## Bilek, kalça eklemlerinin ortasına göre kaynaktaki yere gider (bacak boyu oranıyla); diz öne bükülür, boy değişmez.
func test_retarget_solves_legs_to_the_source_ankles() -> void:
	var source := _legged_skeleton(100.0, 45.0, 45.0)
	var target := _legged_skeleton(80.0, 36.0, 36.0)
	# Kaynağın sol uyluğu öne kalkık, baldırı geri bükülü.
	var thigh := Quaternion(Vector3.RIGHT, deg_to_rad(-35.0))
	var shin := Quaternion(Vector3.RIGHT, deg_to_rad(50.0))
	var anim := _still_clip({"LeftUpLeg": thigh, "LeftLeg": shin}, Vector3(0.0, 100.0, 0.0))
	var out := ClipRetarget.retarget(anim, source, target)
	var prefix := ClipRetarget.track_prefix(out)
	var rest := ClipRetarget.rest_rotations(target)
	var local := ClipRetarget.local_rotations_at(out, target, rest, prefix, 0.5)
	var pts := ClipRetarget.pose_points(target, local, ClipRetarget.global_rotations(target, local), out, prefix, 0.5)
	var src_rest := ClipRetarget.rest_rotations(source)
	var src_local := ClipRetarget.local_rotations_at(anim, source, src_rest, prefix, 0.5)
	var src := ClipRetarget.pose_points(source, src_local, ClipRetarget.global_rotations(source, src_local), anim, prefix, 0.5)
	var scale := target.get_bone_global_rest(target.find_bone("LeftFoot")).origin.distance_to(target.get_bone_global_rest(target.find_bone("LeftUpLeg")).origin) / source.get_bone_global_rest(source.find_bone("LeftFoot")).origin.distance_to(source.get_bone_global_rest(source.find_bone("LeftUpLeg")).origin)
	var ankle := target.find_bone("LeftFoot")
	var hips := (pts[target.find_bone("LeftUpLeg")] + pts[target.find_bone("RightUpLeg")]) * 0.5
	var src_hips := (src[source.find_bone("LeftUpLeg")] + src[source.find_bone("RightUpLeg")]) * 0.5
	assert_vec_almost(pts[ankle] - hips, (src[source.find_bone("LeftFoot")] - src_hips) * scale, 0.05, "Bilek kaynaktaki yerine gitmeli")
	assert_true(pts[target.find_bone("LeftLeg")].z > hips.z + 3.0, "Diz öne bükülmeli")
	source.free()
	target.free()


## Kaynağın kalça eklemleri farklı yükseklikteyse (taşıyıcı) ayaklar yerde düz: hedefte de düz kalmalı.
func test_retarget_does_not_copy_source_hip_asymmetry() -> void:
	var source := _legged_skeleton(100.0, 45.0, 45.0, 4.0)
	var target := _legged_skeleton(100.0, 45.0, 45.0)
	# Kaynakta sağ kalça 4 birim yukarıda; iki bacak da bükülü (yumuşak uzama payının dışında), bilekler yere yakın aynı yükseklikte.
	var left_open := Quaternion(Vector3.RIGHT, deg_to_rad(-30.0))
	var left_back := Quaternion(Vector3.RIGHT, deg_to_rad(30.0))
	var right_open := Quaternion(Vector3.RIGHT, deg_to_rad(-22.0))
	var right_back := Quaternion(Vector3.RIGHT, deg_to_rad(22.0))
	var anim := _still_clip({"LeftUpLeg": left_open, "LeftLeg": left_back, "RightUpLeg": right_open, "RightLeg": right_back}, Vector3(0.0, 100.0, 0.0))
	var prefix := ClipRetarget.track_prefix(anim)
	var rest := ClipRetarget.rest_rotations(source)
	var local := ClipRetarget.local_rotations_at(anim, source, rest, prefix, 0.5)
	var src := ClipRetarget.pose_points(source, local, ClipRetarget.global_rotations(source, local), anim, prefix, 0.5)
	var gap: float = src[source.find_bone("RightFoot")].y - src[source.find_bone("LeftFoot")].y
	var out := ClipRetarget.retarget(anim, source, target)
	var t_rest := ClipRetarget.rest_rotations(target)
	var t_local := ClipRetarget.local_rotations_at(out, target, t_rest, ClipRetarget.track_prefix(out), 0.5)
	var pts := ClipRetarget.pose_points(target, t_local, ClipRetarget.global_rotations(target, t_local), out, ClipRetarget.track_prefix(out), 0.5)
	var target_gap: float = pts[target.find_bone("RightFoot")].y - pts[target.find_bone("LeftFoot")].y
	assert_almost(target_gap, gap, 0.2, "Bilekler arası fark kaynaktaki kadar olmalı, kalça farkı eklenmemeli")
	source.free()
	target.free()


func test_retarget_helpers() -> void:
	var arc := ClipRetarget.shortest_arc(Vector3.UP, Vector3.FORWARD)
	assert_vec_almost(arc * Vector3.UP, Vector3.FORWARD, 0.0001)
	var flip := ClipRetarget.shortest_arc(Vector3.UP, Vector3.DOWN)
	assert_vec_almost(flip * Vector3.UP, Vector3.DOWN, 0.0001, "Ters yönler de çevrilebilmeli")
	assert_true(ClipRetarget.shortest_arc(Vector3.ZERO, Vector3.UP).is_equal_approx(Quaternion.IDENTITY))
	assert_true(ClipRetarget.is_limb("LeftUpLeg"))
	assert_true(ClipRetarget.is_limb("RightForeArm"))
	assert_false(ClipRetarget.is_limb("LeftHand"), "El uç kemiktir")
	assert_false(ClipRetarget.is_limb("RightToeBase"))
	assert_false(ClipRetarget.is_limb("Spine01"), "Gövde ROTATION ile aktarılır")
	var times := ClipRetarget.sample_times(1.0, 4.0)
	assert_eq(times.size(), 5)
	assert_almost(times[times.size() - 1], 1.0)


# --- PoseFit ----------------------------------------------------------------------------

func test_stance_speed_measures_ground_contact() -> void:
	# Ayak yarım döngü yerde (geriye 1.5 m/s kayar), yarım döngü havada (ileri gider).
	var heights := PackedFloat32Array()
	var forward := PackedFloat32Array()
	var dt := 1.0 / 60.0
	var z := 0.3
	for i in 61:
		var on_ground := i < 30
		heights.append(0.17 if on_ground else 0.17 + 0.1 * sin(PI * (i - 30) / 30.0) + 0.02)
		forward.append(z)
		z += (-1.5 if on_ground else 1.5) * dt
	assert_almost(PoseFit.stance_speed(heights, forward, dt), 1.5, 0.05)
	assert_almost(PoseFit.stance_speed(PackedFloat32Array(), PackedFloat32Array(), dt), 0.0)


func test_ground_offset_lifts_or_lowers_to_floor() -> void:
	assert_almost(PoseFit.ground_offset(PackedFloat32Array([0.09, 0.05, 0.07])), -0.05, 0.0001, "Havadaki model indirilir")
	assert_almost(PoseFit.ground_offset(PackedFloat32Array([0.01, -0.03])), 0.03, 0.0001, "Gömülen model kaldırılır")
	assert_almost(PoseFit.ground_offset(PackedFloat32Array()), 0.0)


# --- Gerçek model (Mete) ----------------------------------------------------------------

func test_mete_model_has_real_height_and_clips() -> void:
	if not ResourceLoader.exists(CharacterOptions.model_path(METE)):
		return
	var avatar := CharacterAvatar.new()
	avatar.model_override = METE
	add_child(avatar)
	await wait_frames(1)
	assert_true(avatar.has_meshy_model())
	assert_almost(avatar.get_model_height(), 1.82, 0.03, "Mete 1.82 m boyunda")
	assert_between(avatar.get_head_height(), 1.4, 1.7, "Kafa eklemi boyun üstünde")
	for role in [&"idle", &"walk", &"run", &"sit"]:
		assert_true(avatar.available_roles().has(role), "Mete'nin %s klibi olmalı" % role)
	assert_between(avatar.clip_speed(&"walk"), 1.0, 2.0, "Ölçülmüş yürüme hızı")
	assert_between(avatar.clip_speed(&"run"), 3.0, 6.0, "Ölçülmüş koşma hızı")
	assert_eq(avatar.get_animation_player().get_animation(avatar.clip_name(&"sit")).loop_mode, Animation.LOOP_LINEAR,
		"Oturma (nefes) klibi döngülü olmalı")
	assert_almost(avatar.get_model_node().position.y, avatar.ground_offset(&"idle"), 0.0001, "İlk pozda zemin payı hemen uygulanır")
	avatar.play_pose(&"sit")
	assert_eq(avatar.get_current_role(), &"sit")
	await get_tree().create_timer(CharacterAvatar.BLEND_TIME + 0.1).timeout
	assert_almost(avatar.get_model_node().position.y, avatar.ground_offset(&"sit"), 0.001, "Geçişten sonra oturma payına ulaşmalı")
	avatar.queue_free()


func test_seated_mete_touches_the_ground() -> void:
	# Meshy'nin oturma klibiyle (363) Mete'nin baldır/ayakları zemine değmeli (zemin payı uygulanınca).
	if not ResourceLoader.exists(CharacterOptions.model_path(METE)):
		return
	var avatar := CharacterAvatar.new()
	avatar.model_override = METE
	avatar.start_pose = &"sit"
	add_child(avatar)
	await wait_frames(1)
	var player := avatar.get_animation_player()
	player.seek(0.5, true)
	var lowest := PoseFit.skinned_min_y(avatar.get_model_node()) + avatar.ground_offset(&"sit")
	assert_almost(lowest, 0.0, 0.03, "Oturan Mete ne havada ne gömülü")
	avatar.queue_free()


# --- Omuz düzeltmesi (ShoulderRelax) ---------------------------------------------------

func test_shoulder_drop_rotation_lowers_the_clavicle_only() -> void:
	# Sol köprücük +X'e 16° yukarı bakıyor: 16° indirilince yatay olmalı, yatay yönü (+X) değişmemeli.
	var up := Vector3.UP
	var left := Vector3(cos(deg_to_rad(16.0)), sin(deg_to_rad(16.0)), 0.0)
	assert_almost(ShoulderRelax.elevation_deg(left, up), 16.0, 0.01)
	var turned := ShoulderRelax.drop_rotation(left, up, deg_to_rad(16.0)) * left
	assert_almost(ShoulderRelax.elevation_deg(turned, up), 0.0, 0.01, "Köprücük yataya inmeli")
	assert_true(turned.x > 0.99, "Yön yatayda aynı tarafa bakmalı: %s" % turned)
	# Sağ köprücük -X'e bakar: aynı açı onu da aşağı çevirmeli (yukarı değil).
	var right := Vector3(-left.x, left.y, 0.0)
	var turned_right := ShoulderRelax.drop_rotation(right, up, deg_to_rad(10.0)) * right
	assert_almost(ShoulderRelax.elevation_deg(turned_right, up), 6.0, 0.01, "Sağ köprücük de aşağı inmeli")
	assert_eq(ShoulderRelax.drop_rotation(Vector3.UP, up, 0.3), Basis.IDENTITY, "Dik yönde dönüş tanımsız: dokunma")
	assert_eq(ShoulderRelax.drop_rotation(left, up, 0.0), Basis.IDENTITY)


func test_meshy_characters_get_a_measured_shoulder_relax() -> void:
	# T-pozu iskeletlerinde köprücükler kollar inikken de yukarı bakar (omuzlar kalkık görünür). Ölçüm aracı
	# indirme açısını <id>_fit.json'a yazar; avatar bu açıyla iskelete bir ShoulderRelax ekler.
	for id in ["mete", "hero_f", "mother", "child", "father", "elder"]:
		if not ResourceLoader.exists(CharacterOptions.model_path(id)):
			continue
		var fit := CharacterAvatar._load_fit(id)
		assert_between(float(fit.get("shoulder_drop", -1.0)), 0.0, 18.0, "%s için omuz açısı ölçülmüş olmalı" % id)
	if not ResourceLoader.exists(CharacterOptions.model_path(METE)):
		return
	var avatar := CharacterAvatar.new()
	avatar.model_override = METE
	add_child(avatar)
	await wait_frames(1)
	var relax := avatar.get_skeleton().get_node_or_null(^"ShoulderRelax") as ShoulderRelax
	assert_not_null(relax, "Mete'nin iskeletinde omuz düzeltmesi olmalı")
	if relax:
		assert_almost(relax.drop_deg, float(CharacterAvatar._load_fit(METE)["shoulder_drop"]), 0.001)
		assert_true(relax.drop_deg > 8.0, "Mete'nin omuzları belirgin biçimde indirilmeli (%.1f°)" % relax.drop_deg)
	avatar.queue_free()
	var raw := CharacterAvatar.new()
	raw.model_override = METE
	raw.shoulder_relax = false
	add_child(raw)
	await wait_frames(1)
	assert_null(raw.get_skeleton().get_node_or_null(^"ShoulderRelax"), "Kapatılınca düzeltme eklenmemeli (ölçüm aracı için)")
	raw.queue_free()
