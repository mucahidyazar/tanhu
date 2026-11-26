extends SceneTree
## Geliştirme aracı: Meshy karakterlerini ölçer ve sonuçları res://assets/characters/<id>/<id>_fit.json
## dosyasına yazar (CharacterAvatar bu dosyayı okur).
##
##   - Bağışçı klip: bir karakterde olmayan rolün klibi (ör. kadın kahramanın bağdaş kurup oturması) aynı iskelet
##     yapısındaki başka bir karakterden ClipRetarget ile aktarılır ve <id>_<rol>.res olarak kaydedilir.
##   - Zemin payı: her rolün klibi birkaç karede örneklenir, baldır ve ayakların (PoseFit.CONTACT_BONES) en alt
##     noktası bulunur; model bu payla kaydırılınca karakter ne havada kalır ne zemine gömülür.
##   - Klip hızı: yürüme ve koşmada ayağın yere bastığı karelerdeki kayma hızı (klibin doğal hızı).
##
## Kullanım (proje klasöründe; önce "Godot --headless --path . --import" ile içe aktarma yapılmış olmalı):
##   Godot --headless --path . -s res://scripts/character/character_fit_tool.gd -- mete hero_f mother child father elder
## Bağışçı klipler yalnızca eksikse üretilir; yeniden üretmek için --retarget ekleyin.

## Model → {rol: bağışçı model}. Bağışçının o rol için kendi klibi olmalıdır.
const DONORS := {"hero_f": {"sit": "mother"}}
## Zemin payı için klip başına örnek kare sayısı ve adım hızı için örnek sayısı.
const SAMPLES := 12
const STRIDE_SAMPLES := 64
const FEET: Array[String] = ["LeftToeBase", "RightToeBase"]
## Hedef köprücük eğimi (derece): yataya kadar indirilince omuz çizgisi doğal görünür (yan yana denendi: 0°, 10°,
## 18°). Fazlası ShoulderRelax ile indirilir, en çok SHOULDER_MAX_DROP_DEG (kol gövdeye girmesin).
const SHOULDER_TARGET_DEG := 0.0
const SHOULDER_MAX_DROP_DEG := 18.0
## Taşıyıcı (tools/rig_fix.py CARRIER, test_rig_health CARRIER): kendi klibi kanonik olmayan kişinin yürüme ve koşmasının kaynağı.
const CARRIER := "_anim_library"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := Array(OS.get_cmdline_user_args())
	var force := args.has("--retarget")
	var ids := args.filter(func(a: String) -> bool: return not a.begins_with("--"))
	for id in ids:
		if not ResourceLoader.exists(CharacterOptions.model_path(id)):
			print("[fit] model yok: %s" % id)
			continue
		_make_donor_clips(id, force)
		_rebuild_own_clips(id, force)
		await _measure(id)
	quit(0)


## Kişinin bağışçıları {rol: bağışçı model}: DONORS ile meta.json'daki clip_donors (ikisinde de olan rolde
## meta.json kazanır). Ücretli animasyonu olmayan Meshy kişileri (ör. Önsöz'ün Teoman'ı) bekleme ve oturma
## kliplerini böyle alır.
static func donors_of(id: String) -> Dictionary:
	var donors: Dictionary = (DONORS.get(id, {}) as Dictionary).duplicate()
	var extra: Variant = StandIn.meta(id).get("clip_donors")
	if extra is Dictionary:
		for role in extra:
			donors[str(role)] = str(extra[role])
	return donors


## Eksik rollerin kliplerini bağışçılardan aktarır.
func _make_donor_clips(id: String, force: bool) -> void:
	var donors := donors_of(id)
	for role in donors:
		var out := "res://assets/characters/%s/%s_%s.res" % [id, id, role]
		if ResourceLoader.exists(out) and not force:
			continue
		var donor_id: String = donors[role]
		var target := _instantiate(id)
		var donor := _instantiate(donor_id)
		if target == null or donor == null:
			print("[fit] %s/%s: model açılamadı" % [id, role])
			continue
		var donor_player := donor.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
		var clip_name: String = CharacterAvatar.map_clips(donor_player.get_animation_list(), []).get(StringName(role), "")
		if clip_name.is_empty():
			print("[fit] %s: bağışçıda '%s' klibi yok" % [donor_id, role])
		else:
			var clip := ClipRetarget.retarget(donor_player.get_animation(clip_name), _skeleton(donor), _skeleton(target), ClipRetarget.Mode.DIRECTION, ClipRetarget.DEFAULT_FPS, ClipRetarget.LIMB_KEYS, donor_id, id)
			clip.resource_name = String(role).capitalize()
			var err := ResourceSaver.save(clip, out)
			print("[fit] %s ← %s (%s) → %s hata=%d" % [id, donor_id, clip_name, out, err])
		target.free()
		donor.free()


## İki bacağı çok ayrışan ham iskelet (rig_calibration.json rebuild_own_clips): yeni Meshy iskeletlerinde klip bacağı eski boylara
## göre büker, düzeltilen iskelette ayak havada kalır. Kişinin kendi yürüme ve koşması ham iskeletinden düzeltilmiş iskelete aktarılır.
## Kendi klibi Meshy'nin kanonik biçiminde olmayan kişide (rig_calibration.json own_clips_canonical: false; Atşo: gövde sapması 2,3°,
## kök %5,7 alçak, bacak bükülü kalır; Kujul: Meshy bacağı kayık kalça eklemine göre kurmuş) kaynak taşıyıcının yürüme ve koşmasıdır
## (test_rig_health'in ikiz sınamasının kaynağıyla aynı).
func _rebuild_own_clips(id: String, force: bool) -> void:
	var entry := ClipRetarget.calibration_entry(id)
	var from_carrier := not (entry.get("own_clips_canonical", true) as bool)
	if not force or not ((entry.get("rebuild_own_clips", false) as bool) or from_carrier):
		return
	var lib := ClipLibrary.new()
	var target := _instantiate(id)
	for pair: Array in [["walk", "walking"], ["run", "running"]]:
		var path := lib.carrier_file_path(CARRIER, "donor_%s.glb" % pair[1]) if from_carrier else ProjectSettings.globalize_path(ClipLibrary.RAW_ROOT.path_join(id).path_join("%s_%s.glb" % [id, pair[1]]))
		var raw := lib._scene_root(path)
		var players: Array = raw.find_children("*", "AnimationPlayer", true, false) if raw else []
		if players.is_empty():
			print("[fit] %s/%s: ham klip yok (%s)" % [id, pair[0], path])
			continue
		var player := players[0] as AnimationPlayer
		var names := player.get_animation_list()
		var source := player.get_animation(names[names.size() - 1])
		var source_skeleton := lib.donor_skeleton() if from_carrier else ClipLibrary.find_skeleton(raw)
		var clip := ClipRetarget.retarget(source, source_skeleton, _skeleton(target), ClipRetarget.Mode.DIRECTION, ClipRetarget.DEFAULT_FPS, ClipRetarget.LIMB_KEYS, CARRIER if from_carrier else id, id)
		clip.resource_name = String(pair[0]).capitalize()
		var out := "res://assets/characters/%s/%s_%s.res" % [id, id, pair[0]]
		var err := ResourceSaver.save(clip, out)
		print("[fit] %s ← %s %s → %s hata=%d" % [id, "taşıyıcının" if from_carrier else "kendi ham", pair[1], out, err])
	target.free()
	lib.release()


## Modelin her rolünü ölçer ve <id>_fit.json yazar.
func _measure(id: String) -> void:
	var avatar := CharacterAvatar.new()
	avatar.model_override = id
	# Ham pozu ölç: omuz düzeltmesi kapalı.
	avatar.shoulder_relax = false
	root.add_child(avatar)
	await process_frame
	var player := avatar.get_animation_player()
	var model := avatar.get_model_node()
	var skel := avatar.get_skeleton()
	if player == null or skel == null:
		print("[fit] %s: iskeletli model değil" % id)
		avatar.free()
		return
	var offsets := {}
	var speeds := {}
	for role in avatar.available_roles():
		var anim := player.get_animation(avatar.clip_name(role))
		player.play(avatar.clip_name(role), 0.0)
		var lows := PackedFloat32Array()
		for i in SAMPLES:
			player.seek(anim.length * i / float(SAMPLES - 1), true)
			lows.append(PoseFit.skinned_min_y(model))
		offsets[String(role)] = snappedf(PoseFit.ground_offset(lows), 0.001)
		if role == &"walk" or role == &"run":
			speeds[String(role)] = snappedf(_stride_speed(player, anim, model, skel), 0.01)
	var drop := _shoulder_drop(avatar, player, skel)
	var fit := {
		"_aciklama": "scripts/character/character_fit_tool.gd ile ölçüldü. ground_offset: rol oynarken modelin dikey kaydırması (metre; baldır ve ayakların en alt noktası zemine değsin). clip_speed: yürüme/koşma klibinin ayak kaymayan doğal hızı (m/s). shoulder_drop: kalkık görünen omuzların ShoulderRelax ile indirildiği açı (derece).",
		"ground_offset": offsets,
		"clip_speed": speeds,
		"height": snappedf(avatar.get_model_height(), 0.001),
		"head_height": snappedf(avatar.get_head_height(), 0.001),
		"shoulder_drop": drop,
	}
	var path := "res://assets/characters/%s/%s_fit.json" % [id, id]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(fit, "  ") + "\n")
		file.close()
	print("[fit] %s → %s %s" % [id, path, JSON.stringify(fit)])
	avatar.free()


## Köprücüklerin yataydan eğimi doğal duruştakinden (SHOULDER_TARGET_DEG) ne kadar fazla (derece; 0 = düzeltme
## gerekmez). Bekleme rolünde (yoksa ilk rolde) birkaç karede ölçülür, iki yanın ortalaması alınır.
func _shoulder_drop(avatar: CharacterAvatar, player: AnimationPlayer, skel: Skeleton3D) -> float:
	var roles := avatar.available_roles()
	if roles.is_empty():
		return 0.0
	var role: StringName = &"idle" if roles.has(&"idle") else roles[0]
	var anim := player.get_animation(avatar.clip_name(role))
	player.play(avatar.clip_name(role), 0.0)
	var up := (skel.global_basis.inverse() * Vector3.UP).normalized()
	var total := 0.0
	var count := 0
	for i in SAMPLES:
		player.seek(anim.length * i / float(SAMPLES - 1), true)
		for pair: Array in ShoulderRelax.PAIRS:
			var c := skel.find_bone(str(pair[0]))
			var a := skel.find_bone(str(pair[1]))
			if c < 0 or a < 0:
				continue
			total += ShoulderRelax.elevation_deg(skel.get_bone_global_pose(a).origin - skel.get_bone_global_pose(c).origin, up)
			count += 1
	if count == 0:
		return 0.0
	return snappedf(clampf(total / count - SHOULDER_TARGET_DEG, 0.0, SHOULDER_MAX_DROP_DEG), 0.1)


## Yerinde oynayan yürüme/koşma klibinin doğal hızı (iki ayağın ortalaması).
func _stride_speed(player: AnimationPlayer, anim: Animation, model: Node3D, skel: Skeleton3D) -> float:
	var to_model := PoseFit.relative_transform(model, skel)
	var dt := anim.length / float(STRIDE_SAMPLES)
	var total := 0.0
	var feet := 0
	for foot in FEET:
		var bone := skel.find_bone(foot)
		if bone < 0:
			continue
		var heights := PackedFloat32Array()
		var forward := PackedFloat32Array()
		for i in STRIDE_SAMPLES + 1:
			player.seek(dt * i, true)
			var p := to_model * skel.get_bone_global_pose(bone).origin
			heights.append(p.y)
			forward.append(p.z)
		total += PoseFit.stance_speed(heights, forward, dt)
		feet += 1
	return total / feet if feet > 0 else 0.0


func _instantiate(id: String) -> Node3D:
	var scene := load(CharacterOptions.model_path(id)) as PackedScene
	return scene.instantiate() as Node3D if scene else null


func _skeleton(model: Node3D) -> Skeleton3D:
	return model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
