extends TestCase
## İskelet sağlığı (K92; tools/rig_fix.py, data/rig_calibration.json, ClipRetarget): Meshy'nin eklem hataları oyuna girmesin.
## Bütün kadroyu gerçek modelleriyle sınar: omurga çizgisi, diz yeri ve yüksekliği, iskelet kalibrasyonu (dönüş ve bilek farkı);
## aktarılan klibin kişinin kendi Meshy klibiyle karşılaştırması (ikiz sınaması: gövde ve bilek), ayakta klipte bel kırığı, diz kilidi,
## oturuşta diz açıklığı, ayak yüksekliği, her rol klibinin her kemiğe izi ve her kişinin 120 klip ölçüsü; omuz simetrisi, parmak kemikleri ve kumaş ağırlığının baskın kemiği.
## Eşikler aracın eşikleridir (rig_calibration.json limits): araç «sağlam» derse burası da der. Yeni kişi modeli tools/rig_fix.py'den geçmeden gelirse burası düşer.

const CARRIER := "_anim_library"
const SPINE: Array[String] = ["Hips", "Spine02", "Spine01", "Spine", "neck"]
const TORSO: Array[String] = ["Hips", "Spine02", "Spine01", "Spine", "neck", "Head"]
## İkiz sınaması: taşıyıcının yürümesi kişiye aktarılınca gövde kişinin kendi yürümesinden en çok bu kadar ayrışır (derece).
const TWIN_TORSO_MAX := 3.0
## İkiz sınaması: bileğin kalça eklemleri ortasına göre yeri, kişinin kendi yürümesinden en çok bu kadar ayrışır (cm). Bilek farkı (F)
## çıkarılmadan önce 8,2 cm, sonra 2,3-3,5. Kendi yürümesi yeniden aktarılan kişide (rebuild_own_clips) kıyas kendi klibi değildir, sayılmaz.
const TWIN_ANKLE_MAX := 4.0
## Ayakta duran klipte Hips ile Spine arasındaki bükülme (derece): düzeltmeden önce -48.
const WAIST_MIN := -22.0
const WAIST_MAX := 22.0
## Ayakta iki bileğin yükseklik farkı (cm; düzeltmeden önce 5 cm'ye çıkıyordu).
const FEET_GAP_MAX := 3.0
const STANDING: Array[String] = ["idle_7", "idle_9", "idle_12", "idle_3", "idle_4"]
## Ayakta kliplerde diz kalça-bilek çizgisinden en az bu kadar (cm) önde: sert sınırda sağ diz 1,2 cm'de kilitleniyordu (kaynakta 3-8).
const STANDING_LOCK: Array[String] = ["idle_7", "idle_12", "talk_angry", "wave_one_hand"]
const KNEE_LOCK_MIN := 1.5
## Eşiğin ölçüldüğü yetişkin bacağı (kalçadan bileğe, iskelet birimi: cm).
const ADULT_LEG := 78.0
## Dizin kare başına en büyük adımı (cm, 30 kare/sn): sert sınırda kilide girerken 6,3 cm.
const KNEE_STEP_MAX := 3.5
## Oturuşta dizler arası, kaynağınkinin (boy oranıyla) en az bu katı: diz eklemi yüksek bağışçıdan aktarımda 0,62'ye düşüyordu.
const KNEE_GAP_MIN := 0.75
## Parmağı kapanan elde orta boğumun bileğe uzaklığı en çok bu kat olur (düz ele göre).
const GRIP_CLOSE_MAX := 0.95
## Sol ve sağ elin parmak kemiği boy farkı en çok bu oran (iki elde ortalama boy yazılır; kök boğum el çerçevesine bağlıdır).
const FINGER_ASYMMETRY_MAX := 0.25
## Kumaş alanı: diz hizasının altında kalçaya baskın köşe payı en çok bu kadar (PoseFit bu köşeyi zemine değen beden sanır).
const HIPS_DOMINANT_MAX := 0.002
## Mete'nin döngülü klibinde sol el sağdan en çok bu kadar (cm) aşağıda: omuz düzelmeden 4,5.
const METE_HAND_DROP_MAX := 1.5


func _ids() -> Array:
	return ClipLibrary.new().characters_with_models()


func _limits() -> Dictionary:
	return (ClipLibrary.read_json(ClipRetarget.CALIBRATION_PATH) as Dictionary)["limits"]


func _instantiate(id: String) -> Node:
	return (load(StandIn.model_path(id)) as PackedScene).instantiate()


func _points(skel: Skeleton3D) -> Dictionary:
	var out := {}
	for b in skel.get_bone_count():
		out[skel.get_bone_name(b)] = skel.get_bone_global_rest(b).origin
	return out


func _tilt(a: Vector3, b: Vector3) -> float:
	return rad_to_deg(atan2(b.z - a.z, b.y - a.y))


## Ağın boyu (metre; rig_fix.height_of ile aynı).
func _height(model: Node) -> float:
	var best := 0.0
	for node in model.find_children("*", "MeshInstance3D", true, false):
		best = maxf(best, (node as MeshInstance3D).mesh.get_aabb().size.y)
	return best


## Klibin t anındaki eklem konumları (iskelet uzayı, cm).
func _pose(skel: Skeleton3D, anim: Animation, rest: Array[Quaternion], prefix: String, t: float) -> PackedVector3Array:
	var local := ClipRetarget.local_rotations_at(anim, skel, rest, prefix, t)
	return ClipRetarget.pose_points(skel, local, ClipRetarget.global_rotations(skel, local), anim, prefix, t)


## Kuaterniyonun en kısa dönüş açısı (radyan; işareti keyfi, araçtaki qangle_deg ile aynı ölçü).
func _turn(q: Quaternion) -> float:
	return 2.0 * acos(minf(absf(q.w), 1.0))


## Dizin kalça-bilek çizgisinden sapması (cm).
func _knee_offset(pts: PackedVector3Array, up: int, leg: int, foot: int) -> float:
	var line := (pts[foot] - pts[up]).normalized()
	var knee := pts[leg] - pts[up]
	return (knee - line * knee.dot(line)).length()


func test_cast_is_present() -> void:
	assert_true(_ids().size() >= 15, "Kadroda en az 15 model olmalı (%d)" % _ids().size())


func test_every_spine_is_a_straight_line() -> void:
	var limit := float(_limits()["spine_span_deg"])
	for id: String in _ids():
		var model := _instantiate(id)
		var p := _points(ClipLibrary.find_skeleton(model))
		var tilts := []
		for i in SPINE.size() - 1:
			tilts.append(_tilt(p[SPINE[i]], p[SPINE[i + 1]]))
		assert_true(tilts.max() - tilts.min() <= limit, "%s: omurga zikzak (%.1f°): tools/rig_fix.py --apply %s" % [id, tilts.max() - tilts.min(), id])
		model.free()


func test_every_knee_sits_on_the_leg_line() -> void:
	var limits := _limits()
	var tolerance := float(limits["knee_tolerance_cm"])
	for id: String in _ids():
		var model := _instantiate(id)
		var p := _points(ClipLibrary.find_skeleton(model))
		var target := float(limits["knee_forward_cm_at_170"]) * _height(model) / 1.7
		var chains := []
		for side in ["Left", "Right"]:
			var hip: Vector3 = p[side + "UpLeg"]
			var knee: Vector3 = p[side + "Leg"]
			var ankle: Vector3 = p[side + "Foot"]
			var along := (ankle - hip).normalized()
			var off := (knee - hip) - along * (knee - hip).dot(along)
			var forward := (Vector3.BACK - along * Vector3.BACK.dot(along)).normalized()
			var side_axis := along.cross(forward).normalized()
			assert_between(off.dot(forward), target - tolerance, target + tolerance, "%s %s diz öne sapması: tools/rig_fix.py --apply %s" % [id, side, id])
			assert_between(off.dot(side_axis), -tolerance, tolerance, "%s %s diz yana sapması" % [id, side])
			var thigh := knee.distance_to(hip)
			var shin := ankle.distance_to(knee)
			assert_true(thigh / (thigh + shin) >= float(limits["thigh_share_min"]), "%s %s diz yüksek (uyluk payı %.3f)" % [id, side, thigh / (thigh + shin)])
			chains.append(thigh + shin)
		assert_true(absf(chains[0] - chains[1]) / minf(chains[0], chains[1]) <= float(limits["leg_asymmetry"]), "%s: iki bacak farklı boyda" % id)
		model.free()


func test_every_rig_is_calibrated() -> void:
	var foot_limit := deg_to_rad(float(_limits()["foot_constant_deg"]))
	for id: String in _ids() + [CARRIER]:
		var entry := ClipRetarget.calibration_entry(id)
		assert_false(entry.is_empty(), "%s data/rig_calibration.json'da yok: tools/rig_fix.py --calibrate" % id)
		if entry.is_empty():
			continue
		for bone: String in TORSO:
			assert_true((entry["bones"] as Dictionary).has(bone), "%s: %s kalibre değil" % [id, bone])
			assert_true(float(entry["spread_deg"][bone]) < 1.0, "%s: %s farkı sabit değil" % [id, bone])
		for side: String in ["Left", "Right"]:
			assert_true((entry["feet"] as Dictionary).has(side), "%s: %s bilek farkı ölçülmeli" % [id, side])
			assert_eq(float(entry["feet"][side][1]), 0.0, "%s: bilek farkı tabanı ayırmasın (yükseklik sıfır)" % id)
		if id != CARRIER:
			var table := ClipRetarget.calibration_of(id)
			assert_true(_turn(table["LeftFoot"]) <= foot_limit, "%s: sol ayak sabiti dinlenmeye taşınmalı" % id)
			assert_true(_turn(table["RightFoot"]) <= foot_limit, "%s: sağ ayak sabiti dinlenmeye taşınmalı" % id)
	# Taşıyıcının farkları büyük kalmalı (Mete'nin modelinden kuruldu): sıfırsa ölçüm bozulmuştur.
	assert_true(_turn(ClipRetarget.calibration_of(CARRIER)["Hips"]) > deg_to_rad(10.0), "Taşıyıcının kalça farkı ölçülmeli")
	assert_true(float(ClipRetarget.calibration_entry(CARRIER)["feet"]["Right"][0]) < -3.0, "Taşıyıcıda sağ bilek dışarıda ölçülmeli")


## İkiz sınaması: taşıyıcının bedava yürümesi kişiye aktarılınca kişinin kendi Meshy yürümesinin gövdesini ve ayak yerini vermeli.
func test_retarget_reproduces_the_characters_own_walk() -> void:
	var lib := ClipLibrary.new()
	var raw := lib.carrier_file_path(CARRIER, "donor_walking.glb")
	if not FileAccess.file_exists(raw):
		print("        (atlandı: ham taşıyıcı yürümesi yok)")
		return
	var root := lib._scene_root(raw)
	var player := root.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
	var names := player.get_animation_list()
	var source := player.get_animation(names[names.size() - 1])
	var donor := lib.donor_skeleton()
	for id: String in _ids():
		var own_path := ClipLibrary.res_path(id, "walk")
		if not ResourceLoader.exists(own_path) or ClipLibrary.FIT_TOOL.donors_of(id).has("walk"):
			continue
		var own := load(own_path) as Animation
		var model := _instantiate(id)
		var skel := ClipLibrary.find_skeleton(model)
		var out := ClipRetarget.retarget(source, donor, skel, ClipRetarget.Mode.DIRECTION, ClipRetarget.DEFAULT_FPS, ClipRetarget.LIMB_KEYS, CARRIER, id)
		var worst := 0.0
		var worst_ankle := 0.0
		var rest := ClipRetarget.rest_rotations(skel)
		var own_prefix := ClipRetarget.track_prefix(own)
		var out_prefix := ClipRetarget.track_prefix(out)
		var hips := [skel.find_bone("LeftUpLeg"), skel.find_bone("RightUpLeg")]
		var feet := [skel.find_bone("LeftFoot"), skel.find_bone("RightFoot")]
		for i in 9:
			var t := out.length * i / 8.0
			var a := ClipRetarget.global_rotations(skel, ClipRetarget.local_rotations_at(out, skel, rest, out_prefix, t))
			var b := ClipRetarget.global_rotations(skel, ClipRetarget.local_rotations_at(own, skel, rest, own_prefix, t))
			for bone: String in TORSO:
				var k := skel.find_bone(bone)
				worst = maxf(worst, rad_to_deg(a[k].angle_to(b[k])))
			var pa := _pose(skel, out, rest, out_prefix, t)
			var pb := _pose(skel, own, rest, own_prefix, t)
			var mid_a := (pa[hips[0]] + pa[hips[1]]) * 0.5
			var mid_b := (pb[hips[0]] + pb[hips[1]]) * 0.5
			for foot: int in feet:
				worst_ankle = maxf(worst_ankle, (pa[foot] - mid_a).distance_to(pb[foot] - mid_b))
		assert_true(worst <= TWIN_TORSO_MAX, "%s: aktarılan yürümenin gövdesi kendi klibinden %.1f° ayrışıyor" % [id, worst])
		if not bool(ClipRetarget.calibration_entry(id).get("rebuild_own_clips", false)):
			assert_true(worst_ankle <= TWIN_ANKLE_MAX, "%s: aktarılan yürümede bilek kendi klibinden %.1f cm ayrışıyor" % [id, worst_ankle])
		model.free()
	lib.release()


func test_standing_clips_have_no_waist_kink() -> void:
	var lib := ClipLibrary.new()
	for id: String in _ids():
		var model := _instantiate(id)
		var skel := ClipLibrary.find_skeleton(model)
		var rest := ClipRetarget.rest_rotations(skel)
		var rest_global := ClipRetarget.global_rotations(skel, rest)
		var hips := skel.find_bone("Hips")
		var spine := skel.find_bone("Spine")
		for key: String in STANDING:
			var anim := lib.clip_for(id, key, skel)
			if anim == null:
				continue
			var prefix := ClipRetarget.track_prefix(anim)
			for i in 5:
				var pose := ClipRetarget.global_rotations(skel, ClipRetarget.local_rotations_at(anim, skel, rest, prefix, anim.length * i / 4.0))
				var dh: Quaternion = pose[hips] * rest_global[hips].inverse()
				var ds: Quaternion = pose[spine] * rest_global[spine].inverse()
				var up: Vector3 = (dh.inverse() * ds) * Vector3.UP
				assert_between(rad_to_deg(atan2(up.z, up.y)), WAIST_MIN, WAIST_MAX, "%s/%s: belde kırık" % [id, key])
		model.free()
	lib.release()


func test_standing_feet_stay_level() -> void:
	var lib := ClipLibrary.new()
	for id: String in _ids():
		var model := _instantiate(id)
		var skel := ClipLibrary.find_skeleton(model)
		var rest := ClipRetarget.rest_rotations(skel)
		for key: String in ["idle_7", "idle_9"]:
			var anim := lib.clip_for(id, key, skel)
			if anim == null:
				continue
			var prefix := ClipRetarget.track_prefix(anim)
			for i in 5:
				var pts := _pose(skel, anim, rest, prefix, anim.length * i / 4.0)
				var gap: float = pts[skel.find_bone("RightFoot")].y - pts[skel.find_bone("LeftFoot")].y
				assert_true(absf(gap) <= FEET_GAP_MAX, "%s/%s: bilekler arasında %.1f cm" % [id, key, gap])
		model.free()
	lib.release()


## Ayakta dururken iki diz de hafif bükülü kalır: bilek hedefi zincirin sonuna yaklaşınca bacak yumuşar, dümdüz kilitlenmez.
func test_standing_knees_do_not_lock() -> void:
	var lib := ClipLibrary.new()
	for id: String in _ids():
		var model := _instantiate(id)
		var skel := ClipLibrary.find_skeleton(model)
		var rest := ClipRetarget.rest_rotations(skel)
		for key: String in STANDING_LOCK:
			# Aktarımın kendisi; bacak düzeltmesinin (fit_legs) sınaması test_fitted_knees_do_not_lock.
			var anim := lib.retarget_from(key, CARRIER, skel, id)
			if anim == null:
				continue
			var prefix := ClipRetarget.track_prefix(anim)
			var least := {"Left": INF, "Right": INF}
			for t in ClipRetarget.sample_times(anim.length, 5.0):
				var pts := _pose(skel, anim, rest, prefix, t)
				for side: String in least:
					least[side] = minf(least[side], _knee_offset(pts, skel.find_bone(side + "UpLeg"), skel.find_bone(side + "Leg"), skel.find_bone(side + "Foot")))
			for side: String in least:
				assert_true(least[side] >= KNEE_LOCK_MIN, "%s/%s %s diz kilitli (%.1f cm)" % [id, key, side, least[side]])
		model.free()
	lib.release()


## Bacak düzeltmesi (fit_legs) ayağı zemine indirirken de diz dümdüz kilitlenmez: sert 0,9995 sınırında 15 kişide 22 kayıt 0,8-1,3 cm'deydi
## (çoğu idle_03; shrug, alert, idle_12).
func test_fitted_knees_do_not_lock() -> void:
	var lib := ClipLibrary.new()
	for id: String in _ids():
		var model := _instantiate(id)
		var skel := ClipLibrary.find_skeleton(model)
		var rest := ClipRetarget.rest_rotations(skel)
		# Eşik boya göredir: çocuğun bacağı yetişkininkinin ≈%60'ıdır, aynı açı daha az santimetre eder.
		var thigh := skel.get_bone_global_rest(skel.find_bone("LeftUpLeg")).origin
		var knee := skel.get_bone_global_rest(skel.find_bone("LeftLeg")).origin
		var ankle := skel.get_bone_global_rest(skel.find_bone("LeftFoot")).origin
		var lock_min := KNEE_LOCK_MIN * minf(1.0, (thigh.distance_to(knee) + knee.distance_to(ankle)) / ADULT_LEG)
		for key: String in lib.clip_keys():
			var fit := lib.leg_fit_for(id, key)
			if not fit.has("left") and not fit.has("right"):
				continue
			var anim := lib.clip_for(id, key, skel)
			var prefix := ClipRetarget.track_prefix(anim)
			var least := {"Left": INF, "Right": INF}
			for t in ClipRetarget.sample_times(anim.length, 15.0):
				var pts := _pose(skel, anim, rest, prefix, t)
				for side: String in least:
					least[side] = minf(least[side], _knee_offset(pts, skel.find_bone(side + "UpLeg"), skel.find_bone(side + "Leg"), skel.find_bone(side + "Foot")))
			for side: String in least:
				assert_true(least[side] >= lock_min, "%s/%s %s diz kilitli (%.2f cm, eşik %.2f; %s)" % [id, key, side, least[side], lock_min, fit])
		model.free()
		lib._clip_cache.clear()
	lib.release()


## Hedef zincirin sonuna değerken diz sıçramaz (Ana, ağır yürüyüş: sert sınırda 6,3 cm/kare).
func test_knee_does_not_jump_at_full_reach() -> void:
	var lib := ClipLibrary.new()
	var model := _instantiate("mother")
	var skel := ClipLibrary.find_skeleton(model)
	var rest := ClipRetarget.rest_rotations(skel)
	var anim := lib.clip_for("mother", "walk_slowly_look_around", skel)
	var prefix := ClipRetarget.track_prefix(anim)
	for side: String in ["Left", "Right"]:
		var knee := skel.find_bone(side + "Leg")
		var worst := 0.0
		var previous := Vector3.INF
		for t in ClipRetarget.sample_times(anim.length, 30.0):
			var point := _pose(skel, anim, rest, prefix, t)[knee]
			if previous != Vector3.INF:
				worst = maxf(worst, point.distance_to(previous))
			previous = point
		assert_true(worst <= KNEE_STEP_MAX, "%s diz adımı %.1f cm/kare" % [side, worst])
	model.free()
	lib.release()


## Oturuşta dizler kaynaktakinin en az %75'i kadar açık kalır: diz eklemi yüksek iskeletten ya da iskelete aktarımda bağdaş kapanıyordu.
func test_seated_knees_stay_open() -> void:
	var lib := ClipLibrary.new()
	var pairs := []
	for id: String in _ids():
		var table: Dictionary = lib.resolve(id)
		for key: String in ["sit", "ground_warm_hands", "ground_kneel_heels"]:
			if str((table[key] as Dictionary).get("source", "")) == ClipLibrary.RETARGET:
				pairs.append([id, key, str(table[key]["donor"])])
	assert_true(pairs.size() >= 30, "Oturuş aktarımları sınanmalı (%d)" % pairs.size())
	for pair: Array in pairs:
		var model := _instantiate(pair[0])
		var skel := ClipLibrary.find_skeleton(model)
		var native: Dictionary = lib.native_sources(pair[2]).get(pair[1], {})
		var src := lib._load_source(pair[2], str(native["path"]), str(native["role"]), str(native.get("clip", "")))
		var anim := lib.retarget_from(pair[1], pair[2], skel, pair[0])
		var source_skel: Skeleton3D = src["skeleton"]
		var scale := skel.get_bone_global_rest(skel.find_bone("LeftFoot")).origin.distance_to(skel.get_bone_global_rest(skel.find_bone("LeftUpLeg")).origin) / source_skel.get_bone_global_rest(source_skel.find_bone("LeftFoot")).origin.distance_to(source_skel.get_bone_global_rest(source_skel.find_bone("LeftUpLeg")).origin)
		var t: float = anim.length * 0.5
		var pts := _pose(skel, anim, ClipRetarget.rest_rotations(skel), ClipRetarget.track_prefix(anim), t)
		var source_pts := _pose(source_skel, src["anim"], ClipRetarget.rest_rotations(source_skel), ClipRetarget.track_prefix(src["anim"]), t)
		var gap := pts[skel.find_bone("LeftLeg")].distance_to(pts[skel.find_bone("RightLeg")])
		var source_gap := source_pts[source_skel.find_bone("LeftLeg")].distance_to(source_pts[source_skel.find_bone("RightLeg")]) * scale
		assert_true(gap >= source_gap * KNEE_GAP_MIN, "%s/%s (bağışçı %s): dizler arası %.1f cm, kaynak %.1f" % [pair[0], pair[1], pair[2], gap, source_gap])
		model.free()
	lib.release()


## Kişinin kendi klibinde izi olmayan kemik önceki klibin pozunda kalır: yürümeden Spine izi olmayan beklemeye geçince gövde eğik kalıyordu.
func test_role_clips_cover_every_bone() -> void:
	for id: String in _ids():
		var avatar := CharacterAvatar.new()
		avatar.model_override = id
		add_child(avatar)
		await wait_frames(1)
		var skel := avatar.get_skeleton()
		var player := avatar.get_animation_player()
		for role: StringName in avatar._clips:
			var anim := player.get_animation(avatar._clips[role])
			var prefix := ClipRetarget.track_prefix(anim)
			for b in skel.get_bone_count():
				assert_true(anim.find_track(NodePath("%s:%s" % [prefix, skel.get_bone_name(b)]), Animation.TYPE_ROTATION_3D) >= 0, "%s/%s: %s kemiğinin izi yok" % [id, role, skel.get_bone_name(b)])
		avatar.free()


## Yeni iskeletlerin kendi yürüme ve koşmasında uyluğun konum izi vardır (0,4-1,7 cm). Oyunda sonraki klibe kalmaz: Godot kemiğin konum ve dönüşünü
## tek önbellekte uygular, sonraki klibin uyluk dönüş izi (complete_rest_tracks) konumu da dinlenmeye döndürür. Motor ya da klip kuralı değişirse burası düşer;
## o zaman clip_library_export.gd'nin complete_position_tracks'i oyuna da gerekir.
func test_thigh_position_does_not_linger_after_walking() -> void:
	for id: String in ["older_brother", "teoman", "lan_hatun"]:
		for variety: bool in [false, true]:
			var avatar := CharacterAvatar.new()
			avatar.model_override = id
			if variety:
				avatar.variety_person = id
				avatar.pinned_roles = [&"walk", &"run"]
			add_child(avatar)
			await wait_frames(1)
			var skel := avatar.get_skeleton()
			var player := avatar.get_animation_player()
			var thigh := skel.find_bone("LeftUpLeg")
			var rest := skel.get_bone_rest(thigh).origin
			avatar.set_locomotion(1.4)
			await wait_frames(2)
			player.advance(CharacterAvatar.BLEND_TIME + 0.1)
			await wait_frames(2)
			assert_true(skel.get_bone_pose_position(thigh).distance_to(rest) > 0.3, "%s: kendi yürümesinde uyluk dinlenmeden kayık" % id)
			avatar.set_locomotion(0.0)
			await wait_frames(2)
			player.advance(CharacterAvatar.BLEND_TIME + 0.1)
			await wait_frames(2)
			assert_vec_almost(skel.get_bone_pose_position(thigh), rest, 0.001, "%s (%s): beklemede uyluk dinlenmede" % [id, player.assigned_animation])
			avatar.free()


## Üst kol eklemi sol-sağ ayna: eklem bir yanda içeride kalırsa üst kol uzar, kol inince el aşağıda durur (Mete, K92).
func test_every_shoulder_is_symmetric() -> void:
	var limit := float(_limits().get("shoulder_asymmetry_cm_at_170", 4.0))
	for id: String in _ids():
		var model := _instantiate(id)
		var p := _points(ClipLibrary.find_skeleton(model))
		var left: Vector3 = p["LeftArm"]
		var right: Vector3 = p["RightArm"]
		var gap := left.distance_to(Vector3(-right.x, right.y, right.z))
		assert_true(gap <= limit * _height(model) / 1.7, "%s: omuz ayna farkı %.1f cm: tools/rig_fix.py --apply %s" % [id, gap, id])
		model.free()


## Mete'nin iki eli aynı hizada: taşıyıcının klibinde iki el yüksekliği ±2 cm içindedir, omuz düzelmeden sol el 4,5 cm aşağıdaydı.
func test_mete_hands_are_level() -> void:
	var lib := ClipLibrary.new()
	var model := _instantiate("mete")
	var skel := ClipLibrary.find_skeleton(model)
	var rest := ClipRetarget.rest_rotations(skel)
	var left := skel.find_bone("LeftHand")
	var right := skel.find_bone("RightHand")
	for key: String in ["idle_9", "casual_walk", "quick_walk"]:
		var anim := lib.clip_for("mete", key, skel)
		var prefix := ClipRetarget.track_prefix(anim)
		var total := 0.0
		for i in 12:
			var pts := _pose(skel, anim, rest, prefix, anim.length * i / 12.0)
			total += pts[left].y - pts[right].y
		assert_true(total / 12.0 >= -METE_HAND_DROP_MAX, "mete/%s: sol el sağdan %.1f cm aşağıda" % [key, -total / 12.0])
	model.free()
	lib.release()


## Her modelde parmak kemikleri: iki elde aynı adlar, zincir bilekten başlar, adlar Meshy kemikleriyle çakışmaz, ağırlık alırlar ve kapanınca orta boğum bileğe yaklaşır.
func test_every_hand_has_finger_bones() -> void:
	for id: String in _ids():
		var model := _instantiate(id)
		var skel := ClipLibrary.find_skeleton(model)
		assert_true(HandGrip.has_fingers(skel), "%s: parmak kemiği yok: tools/rig_fix.py --apply %s" % [id, id])
		for finger: String in HandGrip.FINGERS:
			for joint in HandGrip.JOINTS:
				var left := skel.find_bone("Left%s%d" % [finger, joint + 1])
				var right := skel.find_bone("Right%s%d" % [finger, joint + 1])
				assert_eq(left >= 0, right >= 0, "%s: %s iki elde birlikte olmalı" % [id, finger])
				if left < 0:
					continue
				for pair: Array in [["Left", left], ["Right", right]]:
					var parent := skel.get_bone_parent(pair[1])
					var expected := "%sHand" % pair[0] if joint == 0 else "%s%s%d" % [pair[0], finger, joint]
					assert_eq(skel.get_bone_name(parent), expected, "%s: zincir" % id)
				if joint > 0:
					var a := skel.get_bone_rest(left).origin.length()
					var b := skel.get_bone_rest(right).origin.length()
					assert_true(absf(a - b) <= maxf(a, b) * FINGER_ASYMMETRY_MAX, "%s: %s%d iki elde çok farklı (%.1f, %.1f)" % [id, finger, joint + 1, a, b])
		# Kapanma: bilek düşmez, orta boğum yaklaşır.
		for side: StringName in HandGrip.SIDES:
			var hand := skel.get_bone_global_rest(skel.find_bone("%sHand" % side)).origin
			var open_sum := 0.0
			var closed_sum := 0.0
			for f in HandGrip.FINGERS.size():
				var first := skel.find_bone("%s%s1" % [side, HandGrip.FINGERS[f]])
				var second := skel.find_bone("%s%s2" % [side, HandGrip.FINGERS[f]])
				if first < 0 or second < 0:
					continue
				var pose := skel.get_bone_global_rest(first)
				pose.basis = pose.basis * Basis(Vector3.RIGHT, HandGrip.joint_angle(f, 0, 1.0))
				open_sum += skel.get_bone_global_rest(second).origin.distance_to(hand)
				closed_sum += (pose * skel.get_bone_rest(second).origin).distance_to(hand)
			assert_true(closed_sum < open_sum * GRIP_CLOSE_MAX, "%s %s: kapanınca orta boğum avuca yaklaşmalı (%.1f → %.1f)" % [id, side, open_sum, closed_sum])
		model.free()


## Klipler parmağa dokunmaz: aktarılan klipte parmak izi dinlenme izidir, poz HandGrip'ten gelir.
func test_clips_leave_fingers_at_rest() -> void:
	var lib := ClipLibrary.new()
	var model := _instantiate("father")
	var skel := ClipLibrary.find_skeleton(model)
	var anim := lib.clip_for("father", "idle_7", skel)
	var prefix := ClipRetarget.track_prefix(anim)
	for finger: String in HandGrip.FINGERS:
		var track := anim.find_track(NodePath("%s:Left%s1" % [prefix, finger]), Animation.TYPE_ROTATION_3D)
		if track >= 0:
			var rest := skel.get_bone_rest(skel.find_bone("Left%s1" % finger)).basis.get_rotation_quaternion()
			var q: Quaternion = anim.track_get_key_value(track, 0)
			assert_true(Vector4(q.x - rest.x, q.y - rest.y, q.z - rest.z, q.w - rest.w).length() < 0.001, "%s dinlenmede" % finger)
	assert_null(ClipRetarget.calibration_of("father").get("LeftThumb1"), "Parmak kalibre edilmez")
	model.free()
	lib.release()


## Etek alanı (data/garment_weights.json): uyluk baskın kalır. PoseFit zemin payını ve kalça boşluğunu baskın kemikten okur: kalçaya baskın etek ucu bedenden sayılır, kişi havada kalırdı.
func test_garment_field_keeps_the_thigh_dominant() -> void:
	var table: Variant = ClipLibrary.read_json("res://data/garment_weights.json")
	assert_true(table is Dictionary and (table["people"] as Dictionary).size() >= 8, "Uzun giysili kişiler listede")
	for id: String in table["people"]:
		var model := _instantiate(id)
		var skel := ClipLibrary.find_skeleton(model)
		var mi: MeshInstance3D = model.find_children("*", "MeshInstance3D", true, false)[0]
		var arrays := mi.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var stride := bones.size() / verts.size()
		var skin := mi.skin
		var hips_binds := {}
		for i in skin.get_bind_count():
			var bone := skin.get_bind_bone(i)
			var bone_name := skel.get_bone_name(bone) if bone >= 0 else String(skin.get_bind_name(i))
			if bone_name == "Hips":
				hips_binds[i] = true
		var to_model := PoseFit.relative_transform(model, skel)
		var knee_y: float = (to_model * skel.get_bone_global_rest(skel.find_bone("LeftLeg")).origin).y
		var low := 0
		var dominant_hips := 0
		for v in verts.size():
			if verts[v].y >= knee_y:
				continue
			low += 1
			var base := v * stride
			var best := 0
			for k in range(1, stride):
				if weights[base + k] > weights[base + best]:
					best = k
			if hips_binds.has(bones[base + best]):
				dominant_hips += 1
		assert_true(low > 0)
		assert_true(float(dominant_hips) / low <= HIPS_DOMINANT_MAX, "%s: diz altında %d/%d köşe kalçaya baskın" % [id, dominant_hips, low])
		model.free()


## Kişi kadroya girdiyse 120 klibin ölçüsü de vardır: yoksa çeşitler yanlış zemin payı ve taşıyıcı hızıyla oynar (anim_library_import --measure).
func test_every_model_is_measured() -> void:
	var lib := ClipLibrary.new()
	for id: String in _ids():
		var offsets: Variant = lib._model_measures(id).get("offset")
		assert_true(offsets is Dictionary and (offsets as Dictionary).size() == lib.clip_keys().size(), "%s: tools/anim_library_import.gd --measure %s" % [id, id])
	lib.release()
