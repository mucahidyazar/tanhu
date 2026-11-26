extends TestCase
## Klip kütüphanesinin oyun kaynakları (K90, E9; tools/anim_library_import.gd): 117 kaynak (assets/animations/library) ve
## taşıyıcı iskelet (assets/animations/donor), ham GLB gerekmeden yüklenir; sık öbeklerde en az 10 çeşit; etiketler ve temas
## kemikleri; ters klipler; kişiye aktarım (clip_for: NaN yok, önbellekli, oyunun kuralları); ölçüler
## (data/clip_library_measure.json); zemin payı (ayak, kalça ve el zemine oturur); bacak düzeltmesi (kalça ve ayak zemine iner); kısa
## bacak düzeltmesi ve döngü dikişi; tools/meshy_pipeline.py'nin K90 denetimi.

const IMPORT := preload("res://tools/anim_library_import.gd")
const EXPORT := preload("res://tools/clip_library_export.gd")
const CARRIER := "_anim_library"
## Kadronun on beş kişisi (altı eski, dokuz yeni): ölçüler hepsinde olmalı.
const CAST: Array[String] = ["mete", "hero_f", "mother", "father", "elder", "child", "teoman", "lan_hatun", "older_brother",
	"hereka", "hereka_young", "counter", "crowd_hun_man", "crowd_hun_woman", "crowd_hun_rider"]
## Ters klipler: anahtar → ana klip.
const REVERSED := {"rev_stand_up_3": "stand_up_3", "rev_stand_up_9": "stand_up_9", "rev_stand_up_7": "stand_up_7",
	"rev_kneel_and_stand": "kneel_and_stand", "rev_stand_up_1": "stand_up_1", "rev_stand_up_10": "stand_up_10"}
## Sık kullanılan hareketler: en az 10 çeşit (kullanıcı isteği; bekleme ve oturma iki öbek birden).
const FREQUENT := [["idle_loop", "idle_fidget"], ["walk"], ["run"], ["sit_ground", "sit_chair"], ["sit_down"], ["stand_up"], ["talk"]]
## Havaya sıçrayan klipler (kalçanın en yüksek yeri ayaktakinin üstünde).
const JUMPS: Array[String] = ["regular_jump"]
## Kadronun beden ve yaş birleşimleri.
const PROFILES := [["male", "adult"], ["female", "adult"], ["male", "elder"], ["female", "elder"], ["child", "child"]]
const BODIES: Array[String] = ["male", "female", "child"]
const AGES: Array[String] = ["adult", "elder", "child"]
const FEET: Array[String] = ["LeftFoot", "RightFoot", "LeftToeBase", "RightToeBase"]
const SAMPLES := 12
## Yatma klipleri (temas kemikleri gövde ve baş, ya da geçişin bir ucu yatış); zemine ayak bu kadardan çok girmez, klipte bu kadar anda sınanır.
const LYING_CLIPS: Array[String] = ["sleep_normally", "toss_and_turn", "cough_while_sleeping", "groan_in_sleep", "lie_hands_spread", "wake_up_look_up", "stand_up_1", "stand_up_5", "stand_up_8", "arise", "stand_to_side_lying"]
const LYING_FOOT_MARGIN := 0.012
const LYING_CHECKS := 13
## Köşelerle sınananlar: ayağı en çok gömülen ince sırtlılar, uzun cüppeliler, çocuk (bütün kadro bir klipte ≈30 sn sürer, ölçü dosyası kadroyu kapsar).
const LYING_CAST: Array[String] = ["crowd_hun_man", "crowd_hun_woman", "mother", "father", "child", "elder"]


func _raw_available() -> bool:
	var here := FileAccess.file_exists(ProjectSettings.globalize_path(ClipLibrary.RAW_ROOT.path_join(CARRIER).path_join("anim_batch_01.glb")))
	if not here:
		print("        (atlandı: E9 taşıyıcısının ham GLB'leri yok)")
	return here


func _instantiate(id: String) -> Node3D:
	return (load(StandIn.model_path(id)) as PackedScene).instantiate() as Node3D


## Modeli ağaca koyar ve oynatıcısını boşaltır (yoksa oluşturur); [kök, iskelet, oynatıcı].
func _stage(id: String) -> Array:
	var model := _instantiate(id)
	var players := model.find_children("*", "AnimationPlayer", true, false)
	var player: AnimationPlayer = players[0] if not players.is_empty() else null
	if player == null:
		player = AnimationPlayer.new()
		player.name = "AnimationPlayer"
		model.add_child(player)
		player.root_node = NodePath("..")
	for lib_name in player.get_animation_library_list():
		player.remove_animation_library(lib_name)
	player.add_animation_library(&"", AnimationLibrary.new())
	add_child(model)
	return [model, ClipLibrary.find_skeleton(model), player]


## Klibin en alt noktası (örnek karelerde): contact kemiklerine baskın köşeler.
func _lowest(model: Node3D, player: AnimationPlayer, anim: Animation, name: String, contact: Array[String]) -> float:
	var library := player.get_animation_library(&"")
	if not library.has_animation(name):
		library.add_animation(name, anim)
	player.play(name)
	var low := INF
	for i in SAMPLES:
		player.seek(anim.length * i / float(SAMPLES - 1), true)
		low = minf(low, PoseFit.skinned_min_y(model, contact))
	return low


## İkisi de aynı anda, kemiğin eklem yüksekliğinin en azı (model uzayı).
func _lowest_joint(model: Node3D, skel: Skeleton3D, player: AnimationPlayer, anim: Animation, name: String, bone: String) -> float:
	var library := player.get_animation_library(&"")
	if not library.has_animation(name):
		library.add_animation(name, anim)
	player.play(name)
	var to_model := PoseFit.relative_transform(model, skel)
	var low := INF
	for i in SAMPLES:
		player.seek(anim.length * i / float(SAMPLES - 1), true)
		low = minf(low, (to_model * skel.get_bone_global_pose(skel.find_bone(bone)).origin).y)
	return low


## Klibin örnek karelerinde oturan bedenin en altı (PoseFit.seat_min_y).
func _seat_low(model: Node3D, player: AnimationPlayer, anim: Animation, name: String) -> float:
	var library := player.get_animation_library(&"")
	if not library.has_animation(name):
		library.add_animation(name, anim)
	player.play(name)
	var low := INF
	for i in SAMPLES:
		player.seek(anim.length * i / float(SAMPLES - 1), true)
		low = minf(low, PoseFit.seat_min_y(model))
	return low


# --- Oyun kaynakları ---------------------------------------------------------------------------------------

func test_all_117_resources_load_with_valid_tracks() -> void:
	var lib := ClipLibrary.new()
	var donor := lib.donor_skeleton()
	assert_not_null(donor, "Taşıyıcı iskelet oyun kaynağından yüklenmeli")
	assert_true(ResourceLoader.exists(ClipLibrary.DONOR_SCENE), "assets/animations/donor/donor.glb içe aktarılmış olmalı")
	var keys := lib.carrier_keys(CARRIER)
	assert_eq(keys.size(), 117, "E9'un 109 klibi, 6 ters klip, E14'ün yay nişanı ve zıplama")
	var prefix := String(donor.owner.get_path_to(donor))
	var problems := []
	for key in keys:
		var spec := lib.clip(key)
		var path := str(spec.get("resource", ""))
		if path != ClipLibrary.resource_path_of(key) or not ResourceLoader.exists(path):
			problems.append("%s: kaynak yok: %s" % [key, path])
			continue
		var anim := load(path) as Animation
		if anim == null:
			problems.append("%s: Animation değil" % key)
			continue
		if anim.length <= 0.0 or anim.get_track_count() == 0:
			problems.append("%s: süre %f, iz %d" % [key, anim.length, anim.get_track_count()])
		if anim.resource_name != key:
			problems.append("%s: adı %s" % [key, anim.resource_name])
		if anim.loop_mode != Animation.LOOP_NONE:
			problems.append("%s: kaynak döngüsüz saklanır (kurallar clip_for'da)" % key)
		var bones := {}
		for t in anim.get_track_count():
			var track := anim.track_get_path(t)
			var bone := String(track.get_concatenated_subnames())
			if String(track.get_concatenated_names()) != prefix or donor.find_bone(bone) < 0:
				problems.append("%s: geçersiz iz %s" % [key, track])
			elif anim.track_get_key_count(t) == 0:
				problems.append("%s: anahtarsız iz %s" % [key, track])
			if anim.track_get_type(t) == Animation.TYPE_ROTATION_3D:
				bones[bone] = true
		if bones.size() < 20 or not bones.has("Hips") and not bones.has("Spine"):
			problems.append("%s: dönüş izi az: %d kemik" % [key, bones.size()])
	assert_eq(problems, [], "Kaynak sorunları")
	assert_eq(lib.library_clip("idle_3"), null, "Çekirdek klip taşıyıcı klibi değildir: karakterin kendi dosyalarından gelir")


func test_resources_load_without_raw_glbs() -> void:
	# Dışa aktarılmış oyunda ham GLB yoktur: kaynak ve aktarım yalnız res:// dosyalarından gelmeli.
	var lib := ClipLibrary.new()
	var sources := lib.native_sources(CARRIER)
	assert_eq(sources.size(), 117)
	for key in sources:
		assert_true(str(sources[key]["path"]).begins_with("res://assets/animations/library/"), "%s kaynağı: %s" % [key, sources[key]["path"]])
	var model := _instantiate("father")
	var anim := lib.clip_for("father", "proud_strut", ClipLibrary.find_skeleton(model))
	assert_not_null(anim, "Aktarım oyun kaynağından kurulmalı")
	assert_eq(lib.library_clip("proud_strut").resource_path, ClipLibrary.resource_path_of("proud_strut"))
	for path in lib._scenes:
		assert_true(str(path).begins_with("res://"), "Ham GLB açılmamalı: %s" % path)
	model.free()
	lib.release()
	assert_true(ClipLibrary.shared() == ClipLibrary.shared(), "Oyunun ortak kütüphanesi tektir (clip_for önbelleği paylaşılır)")


func test_definition_files_exist() -> void:
	var lib := ClipLibrary.new()
	for key in lib.carrier_keys():
		assert_true(FileAccess.file_exists(str(lib.clip(key)["resource"])), "%s: %s" % [key, lib.clip(key)["resource"]])
	if not _raw_available():
		return
	for key in lib.carrier_keys():
		var spec := lib.clip(key)
		if spec.get("kind") == ClipLibrary.KIND_DERIVED:
			assert_false(spec.has("file"), "%s: türetilmiş klibin ham dosyası yok" % key)
			continue
		var path := lib.carrier_file_path(CARRIER, str(spec["file"]))
		assert_true(FileAccess.file_exists(path), "%s: %s" % [key, path])


func test_donor_skeleton_is_only_a_skeleton_and_matches_the_raw_files() -> void:
	var lib := ClipLibrary.new()
	var donor := lib.donor_skeleton()
	assert_eq(donor.get_bone_count(), 24, "Meshy iskeleti")
	assert_eq(String(donor.owner.get_path_to(donor)), "Armature/Skeleton3D")
	assert_true(donor.owner.find_children("*", "MeshInstance3D", true, false).is_empty(), "Ağ yok")
	assert_true(donor.owner.find_children("*", "AnimationPlayer", true, false).is_empty(), "Klip yok")
	assert_true(FileAccess.get_file_as_bytes(ClipLibrary.DONOR_SCENE).size() < 20000, "Yalnız iskelet: küçük dosya")
	if not _raw_available():
		lib.release()
		return
	var files := {IMPORT.DONOR_SOURCE: true}
	for key in lib.carrier_keys():
		if lib.clip(key).has("file"):
			files[lib.clip(key)["file"]] = true
	assert_eq(files.size(), 22, "Taşıyıcının kaynağı, 12 toplu alım ve 9 metinden hareket")
	for file in files:
		var skel := ClipLibrary.find_skeleton(lib._scene_root(lib.carrier_file_path(CARRIER, str(file))))
		assert_eq(EXPORT._rest_difference(skel, donor), "", "%s: dinlenme pozu taşıyıcıyla aynı olmalı" % file)
	lib.release()


func test_strip_to_skeleton_keeps_joints_and_drops_the_rest() -> void:
	if not _raw_available():
		return
	var lib := ClipLibrary.new()
	var source := FileAccess.get_file_as_bytes(lib.carrier_file_path(CARRIER, IMPORT.DONOR_SOURCE))
	var stripped: PackedByteArray = IMPORT.strip_to_skeleton(source)
	assert_true(stripped.size() > 0 and stripped.size() < source.size() / 4, "Küçülmeli: %d → %d" % [source.size(), stripped.size()])
	var gltf: Dictionary = JSON.parse_string(stripped.slice(20, 20 + stripped.decode_u32(12)).get_string_from_utf8())
	assert_false(gltf.has("animations"), "Klip yok")
	assert_false(gltf.has("meshes"), "Ağ yok")
	assert_eq((gltf["skins"][0]["joints"] as Array).size(), 24)
	assert_eq(stripped.decode_u32(8), stripped.size(), "GLB başlığındaki boy dosyanın boyu")
	assert_eq(IMPORT.strip_to_skeleton(PackedByteArray([1, 2, 3])), PackedByteArray(), "Bozuk dosya reddedilir")
	lib.release()


# --- Çeşitler ve etiketler ----------------------------------------------------------------------------------

func test_frequent_groups_have_at_least_ten_variants() -> void:
	var lib := ClipLibrary.new()
	for groups: Array in FREQUENT:
		var total := 0
		for group in groups:
			total += lib.variants_in(str(group)).size()
		assert_true(total >= 10, "%s: %d çeşit" % [groups, total])
	assert_eq(lib.variants_in("yok_böyle_öbek"), [], "Bilinmeyen öbek boş")
	# Gerçek yürüme ve koşma döngüleri de on çeşit (geçişe benzeyen «yürüyüp durur» klipleri sayılmaz).
	for group in ["walk", "run"]:
		var loops := lib.variants_in(group).filter(func(key: String) -> bool: return lib.variant(key)["loop"])
		assert_true(loops.size() >= 10, "%s: %d döngü" % [group, loops.size()])
	assert_eq(lib.variants_in("idle_loop").slice(0, 2), ["idle_3", "idle_4"], "Çekirdek bekleme klipleri öbekte")
	assert_true(lib.variants_in("sit_ground").has("sit"), "Çekirdek bağdaş yerde oturuş öbeğinde")
	assert_true(lib.variants_in("walk").has("walk") and lib.variants_in("run").has("run"), "İskelet hediyeleri öbekte")
	# Her beden ve yaş birleşimi her sık öbekte seçim bulur (en az 3 çeşit; yaşlı koşmaz: tek koşu klibi).
	for groups: Array in FREQUENT:
		for profile: Array in PROFILES:
			var fits := []
			for group in groups:
				fits.append_array(lib.variants_in(str(group)).filter(func(key: String) -> bool:
					var tags: Dictionary = lib.variant(key)["tags"]
					return (tags["body"] as Array).has(profile[0]) and (tags["age"] as Array).has(profile[1])))
			assert_true(fits.size() >= (1 if groups == ["run"] and profile[1] == "elder" else 3), "%s, %s: %s" % [profile, groups, fits])
	# Etiketler çelişmez: çocuk bedeni çocuk yaşıyla gelir, yoksa klip çocuğa asla gitmez.
	for key in lib.clip_keys():
		var tags: Dictionary = lib.variant(key)["tags"]
		assert_eq((tags["body"] as Array).has("child"), (tags["age"] as Array).has("child"), "%s: beden %s, yaş %s" % [key, tags["body"], tags["age"]])


func test_every_clip_has_tags_contact_and_a_known_group() -> void:
	var lib := ClipLibrary.new()
	var groups: Dictionary = lib.definition["groups"]
	var states: Dictionary = lib.definition["states"]
	assert_eq(groups["idle_loop"]["role"], "idle")
	assert_eq(groups["walk"]["role"], "walk")
	assert_eq(groups["run"]["role"], "run")
	assert_eq(groups["sit_ground"]["role"], "sit")
	assert_eq(groups["sit_chair"]["role"], "sit")
	for group in ["idle_fidget", "sit_down", "stand_up", "talk", "sleep", "work"]:
		assert_null(groups[group]["role"], "%s rol dışı" % group)
	for group in groups:
		assert_false(str(groups[group].get("tr", "")).is_empty() or str(groups[group].get("en", "")).is_empty(), "%s adı" % group)
		assert_false(lib.variants_in(group).is_empty(), "%s boş" % group)
	for key in lib.clip_keys():
		var spec := lib.variant(key)
		assert_true(groups.has(str(spec.get("group", ""))), "%s: bilinmeyen öbek %s" % [key, spec.get("group")])
		assert_true(spec.has("seat") and spec["seat"] in ["ground", "chair", null], "%s: seat %s" % [key, spec.get("seat")])
		assert_true(spec.has("contact"), "%s: contact alanı yok" % key)
		assert_true(float(spec.get("weight", 0.0)) > 0.0, "%s: weight" % key)
		var tags: Variant = spec.get("tags")
		assert_true(tags is Dictionary, "%s: tags" % key)
		if not tags is Dictionary:
			continue
		assert_false((tags["body"] as Array).is_empty(), "%s: tags.body boş" % key)
		for body in tags["body"]:
			assert_true(BODIES.has(str(body)), "%s: beden %s" % [key, body])
		assert_false((tags["age"] as Array).is_empty(), "%s: tags.age boş" % key)
		for age in tags["age"]:
			assert_true(AGES.has(str(age)), "%s: yaş %s" % [key, age])
		assert_true(tags["style"] is Array, "%s: tags.style" % key)
		var transition: Variant = spec.get("transition")
		if transition != null:
			assert_true(states.has(str(transition["from"])) and states.has(str(transition["to"])), "%s: geçiş %s" % [key, transition])
			assert_false(spec["loop"], "%s: geçiş bir kez oynar" % key)
		elif str(spec["group"]) in ["sit_down", "stand_up"]:
			fail("%s: geçiş öbeğinde transition yok" % key)
		if lib.carrier_of(key).is_empty():
			assert_false(spec.has("resource"), "%s: çekirdek klibin kaynağı karakterin dosyalarıdır" % key)
	# Gözlem: özel klipler doğru etiketli.
	assert_eq(lib.variant("elderly_shaky_walk")["tags"]["age"], ["elder"])
	assert_eq(lib.variant("skip_forward")["tags"]["body"], ["child"])
	assert_true((lib.variant("proud_strut")["tags"]["style"] as Array).has("proud"))
	assert_true((lib.variant("spear_walk")["tags"]["style"] as Array).has("warrior"))
	assert_true((lib.variant("cough_while_sleeping")["tags"]["style"] as Array).has("sick"))
	assert_true((lib.variant("sitting_clap")["tags"]["style"] as Array).has("festive"))
	assert_eq(lib.variant("ground_side_sit")["tags"]["body"], ["female"])
	assert_eq(lib.variant("chair_sit_idle_m")["seat"], "chair")
	assert_eq(lib.variant("ground_doze")["seat"], "ground")
	assert_null(lib.variant("idle_7")["seat"])
	assert_eq(lib.variant("sit_to_stand_m")["transition"], {"from": "sit_chair", "to": "stand"})
	assert_eq(lib.variant("stand_up_1")["transition"], {"from": "lie_back", "to": "stand"})
	assert_eq(lib.variant("nope"), {}, "Bilinmeyen anahtar boş")


func test_contact_lists_resolve() -> void:
	var lib := ClipLibrary.new()
	assert_eq(lib.contact_for("idle_7"), FEET, "Ayakta: ayak")
	assert_eq(lib.contact_for("chair_sit_idle_m"), FEET, "Oturakta: ayak")
	assert_true(lib.contact_for("ground_warm_hands").has("Hips"), "Yerde oturuş: kalça da")
	assert_false(lib.contact_for("ground_warm_hands").has("LeftUpLeg"), "Uyluğa bağlı kumaş sayılmaz")
	assert_true(lib.contact_for("ground_side_sit").has("LeftHand"), "Yana oturuşta sol el yerde")
	assert_eq(lib.contact_for("sleep_normally"), PoseFit.LYING_BONES, "Yatarken gövde")
	assert_eq(lib.contact_for("pull_radish"), PoseFit.CONTACT_BONES, "null: varsayılan")
	assert_eq(lib.contact_for("yok"), PoseFit.CONTACT_BONES)
	assert_eq(lib.contact_for_state("stand"), FEET)
	assert_eq(lib.contact_for_state("sit_ground"), PoseFit.SEAT_BONES)
	assert_eq(lib.contact_for_state("lie_back"), PoseFit.LYING_BONES)
	assert_eq(lib.contact_for_state("kneel"), PoseFit.CONTACT_BONES)
	assert_eq(lib.contact_for_state("yok"), PoseFit.CONTACT_BONES)
	assert_eq(PoseFit.contact_list(null), PoseFit.CONTACT_BONES)
	assert_eq(PoseFit.contact_list([]), PoseFit.CONTACT_BONES)
	assert_eq(PoseFit.contact_list(["Hips"]), ["Hips"] as Array[String])


# --- Ters klipler --------------------------------------------------------------------------------------------

func _clip_with_tracks() -> Animation:
	var anim := Animation.new()
	anim.length = 2.0
	var p := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(p, ^"Armature/Skeleton3D:Hips")
	anim.position_track_insert_key(p, 0.0, Vector3(0.0, 30.0, 0.0))
	anim.position_track_insert_key(p, 1.0, Vector3(0.0, 60.0, 10.0))
	anim.position_track_insert_key(p, 2.0, Vector3(0.0, 100.0, 20.0))
	var r := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(r, ^"Armature/Skeleton3D:Spine")
	anim.rotation_track_insert_key(r, 0.0, Quaternion(Vector3.RIGHT, 0.8))
	anim.rotation_track_insert_key(r, 2.0, Quaternion.IDENTITY)
	return anim


func test_reverse_clip_plays_backwards_and_can_stop_early() -> void:
	var anim := _clip_with_tracks()
	var rev := ClipLibrary.reverse_clip(anim)
	assert_almost(rev.length, 2.0, 0.0001)
	assert_eq(rev.loop_mode, Animation.LOOP_NONE)
	assert_vec_almost(rev.position_track_interpolate(0, 0.0), Vector3(0.0, 100.0, 20.0), 0.0001, "İlk kare ana klibin son karesi")
	assert_vec_almost(rev.position_track_interpolate(0, 1.0), Vector3(0.0, 60.0, 10.0), 0.0001, "Orta kare aynı")
	assert_vec_almost(rev.position_track_interpolate(0, 2.0), Vector3(0.0, 30.0, 0.0), 0.0001, "Son kare ana klibin ilk karesi")
	assert_true(rev.rotation_track_interpolate(1, 2.0).angle_to(Quaternion(Vector3.RIGHT, 0.8)) < 0.001)
	var cut := ClipLibrary.reverse_clip(anim, 1.5)
	assert_almost(cut.length, 0.5, 0.0001, "Kesilen bölüm oynamaz")
	assert_vec_almost(cut.position_track_interpolate(0, 0.0), Vector3(0.0, 100.0, 20.0), 0.0001)
	assert_vec_almost(cut.position_track_interpolate(0, 0.5), anim.position_track_interpolate(0, 1.5), 0.0001, "Son kare ana klibin kesildiği an")
	assert_eq(ClipLibrary.derive_clip(anim, {"op": "reverse", "trim_start": 1.0}).length, 1.0)
	expect_errors(PackedStringArray(["bilinmeyen türetme"]))
	assert_null(ClipLibrary.derive_clip(anim, {"op": "yok"}))


func test_trim_clip_start_keeps_the_tail() -> void:
	var anim := _clip_with_tracks()
	var at_two: Vector3 = anim.position_track_interpolate(0, 2.0)
	var at_half: Vector3 = anim.position_track_interpolate(0, 0.5)
	ClipLibrary.trim_clip_start(anim, 0.5)
	assert_almost(anim.length, 1.5, 0.0001)
	assert_vec_almost(anim.position_track_interpolate(0, 0.0), at_half, 0.0001, "Yeni ilk kare kesilen an")
	assert_vec_almost(anim.position_track_interpolate(0, 1.5), at_two, 0.0001, "Son kare aynı")


func test_trim_clip_end_keeps_the_head() -> void:
	var anim := _clip_with_tracks()
	var at_half: Vector3 = anim.position_track_interpolate(0, 0.5)
	var at_cut: Vector3 = anim.position_track_interpolate(0, 1.5)
	ClipLibrary.trim_clip_end(anim, 1.5)
	assert_almost(anim.length, 1.5, 0.0001)
	assert_vec_almost(anim.position_track_interpolate(0, 0.5), at_half, 0.0001, "Baş değişmez")
	assert_vec_almost(anim.position_track_interpolate(0, 1.5), at_cut, 0.0001, "Son kare kesilen an")
	var lib := ClipLibrary.new()
	assert_almost(lib.library_clip("confused_scratch").length, float(lib.variant("confused_scratch")["pose_fix"]["trim_end"]), 0.001, "Oyun kaynağına işlenmiş")
	lib.release()


func test_reversed_clips_mirror_their_parents() -> void:
	var lib := ClipLibrary.new()
	var derived := lib.carrier_keys(CARRIER)
	var found := []
	for key in derived:
		if lib.clip(key).get("kind") == ClipLibrary.KIND_DERIVED:
			found.append(key)
	found.sort()
	var want: Array = REVERSED.keys()
	want.sort()
	assert_eq(found, want, "Altı ters klip")
	for key in REVERSED:
		var spec := lib.variant(key)
		var info: Dictionary = spec["derived"]
		assert_eq(info["from"], REVERSED[key])
		assert_eq(info["op"], "reverse")
		assert_eq(spec["group"], "sit_down", key)
		assert_eq(spec["role"], "sit_down", key)
		assert_eq(spec["credits"], 0.0, key)
		assert_eq(spec["seat"], "ground", key)
		assert_eq(spec["transition"]["from"], "stand", key)
		assert_true(spec["transition"]["to"] in ["sit_ground", "kneel"], "%s: %s" % [key, spec["transition"]])
		var rev := lib.library_clip(key)
		var parent := lib.library_clip(str(info["from"]))
		var trim := float(info.get("trim_start", 0.0))
		assert_almost(rev.length, parent.length - trim, 0.002, "%s süresi" % key)
		assert_eq(rev.get_track_count(), parent.get_track_count(), key)
		for t in rev.get_track_count():
			var u := parent.find_track(rev.track_get_path(t), rev.track_get_type(t))
			assert_true(u >= 0, "%s: %s izi ana klipte yok" % [key, rev.track_get_path(t)])
			if u < 0:
				continue
			match rev.track_get_type(t):
				Animation.TYPE_ROTATION_3D:
					var first := rev.rotation_track_interpolate(t, 0.0).normalized().angle_to(parent.rotation_track_interpolate(u, parent.length).normalized())
					var last := rev.rotation_track_interpolate(t, rev.length).normalized().angle_to(parent.rotation_track_interpolate(u, trim).normalized())
					assert_true(first < 0.005, "%s: ilk kare ana klibin son karesi (%s, %.4f rad)" % [key, rev.track_get_path(t), first])
					assert_true(last < 0.005, "%s: son kare ana klibin %.2f. saniyesi (%s, %.4f rad)" % [key, trim, rev.track_get_path(t), last])
				Animation.TYPE_POSITION_3D:
					assert_vec_almost(rev.position_track_interpolate(t, 0.0), parent.position_track_interpolate(u, parent.length), 0.001, "%s konum" % key)
					assert_vec_almost(rev.position_track_interpolate(t, rev.length), parent.position_track_interpolate(u, trim), 0.001, "%s konum" % key)


# --- Kişiye aktarım ------------------------------------------------------------------------------------------

## Klipte sonlu olmayan değer var mı?
func _first_nan(anim: Animation) -> String:
	for t in anim.get_track_count():
		for k in anim.track_get_key_count(t):
			var value: Variant = anim.track_get_key_value(t, k)
			if value is Quaternion and (value as Quaternion).is_finite() and absf((value as Quaternion).length() - 1.0) < 0.01:
				continue
			if value is Vector3 and (value as Vector3).is_finite():
				continue
			return "%s anahtar %d: %s" % [anim.track_get_path(t), k, value]
	return ""


func test_clip_for_retargets_every_body_without_nan() -> void:
	var lib := ClipLibrary.new()
	var targets := {"father": ["proud_strut", "ground_warm_hands", "rev_stand_up_3", "sit_to_stand_m", "agree_gesture", "sleep_normally"],
		"hereka": ["walking_woman", "ground_side_sit", "rev_stand_up_9", "chair_sit_idle_f", "talk_hand_on_hip", "crouch_fruit_basket_f"],
		"child": ["skip_forward", "run_fast_5", "sit", "kneel_and_stand", "big_wave_hello", "walk"]}
	for id in targets:
		var model := _instantiate(id)
		var skel := ClipLibrary.find_skeleton(model)
		for key in targets[id]:
			var anim := lib.clip_for(id, key, skel)
			assert_not_null(anim, "%s/%s kurulmalı" % [id, key])
			if anim == null:
				continue
			assert_eq(_first_nan(anim), "", "%s/%s: NaN" % [id, key])
			assert_eq(anim.resource_name, key)
			assert_eq(ClipRetarget.track_prefix(anim), String(model.get_path_to(skel)), "%s/%s: iz yolu modelin iskeletine göre" % [id, key])
			assert_true(lib.clip_for(id, key, skel) == anim, "%s/%s: önbellekten aynı klip" % [id, key])
		model.free()
	assert_null(lib.clip_for("father", "yok_boyle", null), "İskelet yoksa kurulmaz")
	lib.release()


func test_clip_for_follows_the_game_rules() -> void:
	var lib := ClipLibrary.new()
	var model := _instantiate("teoman")
	var skel := ClipLibrary.find_skeleton(model)
	var hips_of := func(anim: Animation) -> int:
		return anim.find_track(NodePath("%s:Hips" % ClipRetarget.track_prefix(anim)), Animation.TYPE_POSITION_3D)
	# Döngülü yürüme ham klipte ilerler (walking_2: 1,2 m): yerinde oynar ve dikişi kapalıdır.
	var walk := lib.clip_for("teoman", "walking_2", skel)
	assert_eq(walk.loop_mode, Animation.LOOP_LINEAR)
	assert_true(CharacterAvatar.is_cyclic(walk), "Dikiş kapatılmış olmalı")
	var track: int = hips_of.call(walk)
	var first: Vector3 = walk.track_get_key_value(track, 0)
	var last: Vector3 = walk.track_get_key_value(track, walk.track_get_key_count(track) - 1)
	assert_vec_almost(Vector3(last.x, 0.0, last.z), Vector3(first.x, 0.0, first.z), 0.01, "Yürüme yerinde")
	# Geçiş bir kez oynar, kök hareketini korur.
	var up := lib.clip_for("teoman", "sit_to_stand_m", skel)
	assert_eq(up.loop_mode, Animation.LOOP_NONE)
	track = hips_of.call(up)
	first = up.track_get_key_value(track, 0)
	last = up.track_get_key_value(track, up.track_get_key_count(track) - 1)
	assert_true(last.y - first.y > 20.0, "Kalça yükselir: %s → %s" % [first, last])
	assert_true(absf(last.z - first.z) > 10.0, "Tabureden öne kalkarken kök ilerler: %s → %s" % [first, last])
	var down := lib.clip_for("teoman", "rev_stand_up_3", skel)
	assert_eq(down.loop_mode, Animation.LOOP_NONE)
	track = hips_of.call(down)
	assert_true((down.track_get_key_value(track, 0) as Vector3).y > (down.track_get_key_value(track, down.track_get_key_count(track) - 1) as Vector3).y + 30.0, "Ters klip iner")
	# Tek seferlik jest: döngü yok, yerinde (agree_gesture ham klipte 20 cm kayar).
	var nod := lib.clip_for("teoman", "agree_gesture", skel)
	assert_eq(nod.loop_mode, Animation.LOOP_NONE)
	track = hips_of.call(nod)
	first = nod.track_get_key_value(track, 0)
	last = nod.track_get_key_value(track, nod.track_get_key_count(track) - 1)
	assert_vec_almost(Vector3(last.x, 0.0, last.z), Vector3(first.x, 0.0, first.z), 0.01, "Jest yerinde")
	assert_eq(lib.clip_for("teoman", "formal_bow", skel).loop_mode, Animation.LOOP_NONE, "Selam bir kez")
	assert_eq(lib.clip_for("teoman", "idle_03", skel).loop_mode, Animation.LOOP_NONE, "Kıpırdanma bir kez")
	# Oturuş: nefes döngüsü sürer; kalkıp oturan klip ilk ve son pozu aynı olsa da bir kez oynar.
	assert_eq(lib.clip_for("teoman", "chair_sit_idle_m", skel).loop_mode, Animation.LOOP_LINEAR)
	assert_eq(lib.clip_for("teoman", "stand_clap_sit_down", skel).loop_mode, Animation.LOOP_NONE)
	assert_eq(lib.clip_for("teoman", "idle_7", skel).loop_mode, Animation.LOOP_LINEAR)
	model.free()
	lib.release()


func test_close_loop_closes_the_seam_only_when_needed() -> void:
	var cyclic := Animation.new()
	cyclic.length = 1.0
	var r := cyclic.add_track(Animation.TYPE_ROTATION_3D)
	cyclic.track_set_path(r, ^"Armature/Skeleton3D:Spine")
	cyclic.rotation_track_insert_key(r, 0.0, Quaternion.IDENTITY)
	cyclic.rotation_track_insert_key(r, 0.5, Quaternion(Vector3.RIGHT, 0.5))
	cyclic.rotation_track_insert_key(r, 1.0, Quaternion.IDENTITY)
	assert_false(ClipLibrary.close_loop(cyclic), "İlk ve son pozu aynıysa dokunulmaz")
	var open := Animation.new()
	open.length = 1.0
	var q := open.add_track(Animation.TYPE_ROTATION_3D)
	open.track_set_path(q, ^"Armature/Skeleton3D:Spine")
	var p := open.add_track(Animation.TYPE_POSITION_3D)
	open.track_set_path(p, ^"Armature/Skeleton3D:Hips")
	for i in 5:
		var t := i * 0.25
		open.rotation_track_insert_key(q, t, Quaternion(Vector3.RIGHT, t * 0.6))
		open.position_track_insert_key(p, t, Vector3(0.0, 100.0 + t * 4.0, 0.0))
	var middle: Quaternion = open.track_get_key_value(q, 2)
	assert_true(ClipLibrary.close_loop(open), "Dikiş kapatılır")
	assert_true(CharacterAvatar.is_cyclic(open), "Artık döngüye uygun")
	assert_true((open.track_get_key_value(q, 4) as Quaternion).angle_to(open.track_get_key_value(q, 0)) < 0.001, "Son kare ilk kare")
	assert_vec_almost(open.track_get_key_value(p, 4), open.track_get_key_value(p, 0), 0.001)
	assert_true((open.track_get_key_value(q, 2) as Quaternion).angle_to(middle) < 0.001, "Son çeyreğe kadar klip değişmez")


func test_repaired_long_leg_keeps_both_feet_level() -> void:
	# hereka_young'ın ham iskeletinde sol bacak 7 cm uzundu (uzun etek altında şaşan diz): tools/rig_fix.py iki bacağı eşitler.
	var lib := ClipLibrary.new()
	var stage := _stage("hereka_young")
	var anim := lib.clip_for("hereka_young", "idle_3", stage[1])
	var left := _lowest(stage[0], stage[2], anim, "idle_3", ["LeftFoot", "LeftToeBase"] as Array[String])
	var right := _lowest(stage[0], stage[2], anim, "idle_3", ["RightFoot", "RightToeBase"] as Array[String])
	assert_true(absf(left - right) < 0.025, "İki ayağın farkı %.3f m" % absf(left - right))
	stage[0].free()
	lib.release()


# --- Bacak düzeltmesi ----------------------------------------------------------------------------------------

## Kemik ucunun model uzayındaki yeri, klibin t anında.
func _joint_at(model: Node3D, skel: Skeleton3D, player: AnimationPlayer, bone: String, t: float) -> Vector3:
	player.seek(t, true)
	return PoseFit.relative_transform(model, skel) * skel.get_bone_global_pose(skel.find_bone(bone)).origin


func test_fit_legs_lowers_the_body_and_keeps_the_ankles() -> void:
	var stage := _stage("father")
	var model: Node3D = stage[0]
	var skel: Skeleton3D = stage[1]
	var player: AnimationPlayer = stage[2]
	await wait_frames(1)
	var lib := ClipLibrary.new()
	lib.use_leg_fit = false
	var raw := lib.clip_for("father", "ground_warm_hands", skel)
	var library := player.get_animation_library(&"")
	library.add_animation("raw", raw)
	player.play("raw")
	var t := raw.length * 0.4
	var hips_before := _joint_at(model, skel, player, "Hips", t)
	var ankle_before := _joint_at(model, skel, player, "LeftFoot", t)
	var toe_before := _joint_at(model, skel, player, "LeftToeBase", t)
	var head_before := _joint_at(model, skel, player, "Head", t)
	var fixed := raw.duplicate(true) as Animation
	assert_false(ClipLibrary.fit_legs(fixed, skel, {}), "Düzeltme yoksa dokunmaz")
	assert_true(ClipLibrary.fit_legs(fixed, skel, {"hips": 0.12, "left": 0.03}))
	library.add_animation("fixed", fixed)
	player.play("fixed")
	var hips_after := _joint_at(model, skel, player, "Hips", t)
	assert_vec_almost(hips_after, hips_before + Vector3.DOWN * 0.12, 0.002, "Kalça tam o kadar iner")
	assert_vec_almost(_joint_at(model, skel, player, "Head", t), head_before + Vector3.DOWN * 0.12, 0.002, "Üst beden kalçayla iner")
	assert_vec_almost(_joint_at(model, skel, player, "LeftFoot", t), ankle_before + Vector3.DOWN * 0.03, 0.003, "Bilek istenen yere")
	assert_vec_almost(_joint_at(model, skel, player, "LeftToeBase", t) - _joint_at(model, skel, player, "LeftFoot", t), toe_before - ankle_before, 0.002, "Ayağın yönü değişmez")
	var thigh_rest := skel.get_bone_global_rest(skel.find_bone("LeftUpLeg")).origin.distance_to(skel.get_bone_global_rest(skel.find_bone("LeftLeg")).origin)
	var to_model := PoseFit.relative_transform(model, skel)
	var unit := to_model.basis.get_scale().y
	assert_almost(_joint_at(model, skel, player, "LeftUpLeg", t).distance_to(_joint_at(model, skel, player, "LeftLeg", t)), thigh_rest * unit, 0.002, "Uyluk boyu değişmez")
	player.stop()
	stage[0].free()
	lib.release()


func test_fit_legs_fades_out_as_a_transition_rises() -> void:
	var stage := _stage("teoman")
	var model: Node3D = stage[0]
	var skel: Skeleton3D = stage[1]
	var player: AnimationPlayer = stage[2]
	await wait_frames(1)
	var lib := ClipLibrary.new()
	lib.use_leg_fit = false
	var raw := lib.clip_for("teoman", "rev_stand_up_3", skel)
	var fixed := raw.duplicate(true) as Animation
	assert_eq(ClipLibrary.seat_end_of(lib.variant("rev_stand_up_3")), 1, "Son karede yerde")
	assert_eq(ClipLibrary.seat_end_of(lib.variant("stand_up_3")), 0, "İlk karede yerde")
	assert_eq(ClipLibrary.seat_end_of(lib.variant("stand_up_1")), -1, "Yatıştan kalkışta düzeltme yok")
	assert_eq(ClipLibrary.seat_end_of(lib.variant("idle_7")), -1, "Geçiş değil")
	ClipLibrary.fit_legs(fixed, skel, {"hips": 0.1}, 1)
	var library := player.get_animation_library(&"")
	library.add_animation("raw", raw)
	library.add_animation("fixed", fixed)
	var read := func(clip: String, time: float) -> Vector3:
		player.play(clip)
		return _joint_at(model, skel, player, "Hips", time)
	assert_vec_almost(read.call("fixed", 0.0), read.call("raw", 0.0), 0.002, "Ayakta uç değişmez")
	var end: float = raw.length
	assert_vec_almost(read.call("fixed", end), (read.call("raw", end) as Vector3) + Vector3.DOWN * 0.1, 0.002, "Yerdeki uçta tam")
	player.stop()
	stage[0].free()
	lib.release()


## Klibin t anındaki eklemler (iskelet uzayı, cm) ve küresel dönüşler.
func _clip_pose(skel: Skeleton3D, anim: Animation, t: float) -> Array:
	var local := ClipRetarget.local_rotations_at(anim, skel, ClipRetarget.rest_rotations(skel), ClipRetarget.track_prefix(anim), t)
	var global := ClipRetarget.global_rotations(skel, local)
	return [ClipRetarget.pose_points(skel, local, global, anim, ClipRetarget.track_prefix(anim), t), global]


## Bacağın klip boyu özeti: kalça-bilek uzaklığının zincire en küçük oranı ve dizin beş karelik en büyük yer değiştirmesi (cm).
func _leg_fold_stats(skel: Skeleton3D, anim: Animation, side: String) -> Dictionary:
	var up := skel.find_bone(side + "UpLeg")
	var leg := skel.find_bone(side + "Leg")
	var foot := skel.find_bone(side + "Foot")
	var reach := skel.get_bone_rest(leg).origin.length() + skel.get_bone_rest(foot).origin.length()
	var fold := INF
	var swing := 0.0
	var knees: Array[Vector3] = []
	for t in ClipRetarget.sample_times(anim.length, ClipRetarget.DEFAULT_FPS):
		var pts: PackedVector3Array = _clip_pose(skel, anim, t)[0]
		fold = minf(fold, pts[foot].distance_to(pts[up]) / reach)
		knees.append(pts[leg])
		if knees.size() > 5:
			swing = maxf(swing, knees[knees.size() - 1].distance_to(knees[knees.size() - 6]))
	return {"fold": fold, "swing": swing}


func test_fit_legs_does_not_fold_the_leg_shut() -> void:
	# Kalçayı indirmek bacağı katlanma sınırına itiyordu: stand_up_3'te oran 0,16, sol diz beş karede 34 cm (klibin kendisinde 0,25 ve 18 cm).
	var plain := ClipLibrary.new()
	plain.use_leg_fit = false
	var fitted := ClipLibrary.new()
	for id: String in ["mother", "lan_hatun", "father"]:
		var model := _instantiate(id)
		var skel := ClipLibrary.find_skeleton(model)
		for key: String in ["stand_up_3", "rev_stand_up_3", "stand_up_7", "stand_up_9", "rev_stand_up_9"]:
			var raw := plain.clip_for(id, key, skel)
			var fit := fitted.clip_for(id, key, skel)
			assert_false(fitted.leg_fit_for(id, key).is_empty(), "%s/%s kalçası iner" % [id, key])
			for side: String in ["Left", "Right"]:
				var a := _leg_fold_stats(skel, raw, side)
				var b := _leg_fold_stats(skel, fit, side)
				assert_true(b["fold"] >= minf(float(a["fold"]), ClipLibrary.LEG_FIT_MIN_FOLD) - 0.002, "%s/%s %s: oran %.3f (klipte %.3f)" % [id, key, side, b["fold"], a["fold"]])
				assert_true(b["swing"] <= float(a["swing"]) + 4.0, "%s/%s %s: diz beş karede %.1f cm (klipte %.1f)" % [id, key, side, b["swing"], a["swing"]])
			# Sınır geçişin ortasındadır: yerdeki uçta düzeltme tamdır, beden zemine iner.
			var seat_end := ClipLibrary.seat_end_of(fitted.variant(key))
			var end := raw.length if seat_end == 1 else 0.0
			var hips := skel.find_bone("Hips")
			var drop: float = (_clip_pose(skel, raw, end)[0] as PackedVector3Array)[hips].y - (_clip_pose(skel, fit, end)[0] as PackedVector3Array)[hips].y
			assert_almost(drop, float(fitted.leg_fit_for(id, key)["hips"]) * 100.0, 0.5, "%s/%s yerdeki uçta tam" % [id, key])
		model.free()
		plain._clip_cache.clear()
		fitted._clip_cache.clear()
	plain.release()
	fitted.release()


func test_fit_legs_lifts_the_hip_smoothly_at_the_limit() -> void:
	assert_eq(ClipLibrary._smooth_below(PackedFloat32Array([0.1, 0.1, 0.1, 0.1]), 2), PackedFloat32Array([0.1, 0.1, 0.1, 0.1]), "Sınır değmiyorsa eğri olduğu gibi")
	var dip := PackedFloat32Array([0.2, 0.2, 0.2, 0.2, 0.0, 0.2, 0.2, 0.2, 0.2])
	var smooth := ClipLibrary._smooth_below(dip, 2)
	for i in dip.size():
		assert_true(smooth[i] <= dip[i] + 0.00001, "%d. örnek sınırı aşmaz" % i)
	assert_true(smooth[3] > 0.0 and smooth[3] < smooth[2] and smooth[1] < smooth[0] + 0.00001, "Sınıra yavaşça iner: %s" % smooth)


func test_stand_up_9_knee_stays_on_the_front_of_the_pelvis() -> void:
	# Baba'nın sol dizi birkaç karede kalçanın önünün gerisine geçiyordu (6,6-7,2 cm): oran 0,21'de kalça inince kalça-bilek çizgisi kalçanın önüyle
	# hizalanır. Klibin kendisinde olmayan bu kusur kalça sınırıyla kalkar.
	var lib := ClipLibrary.new()
	var model := _instantiate("father")
	var skel := ClipLibrary.find_skeleton(model)
	var rest_global := ClipRetarget.global_rotations(skel, ClipRetarget.rest_rotations(skel))
	var anim := lib.clip_for("father", "stand_up_9", skel)
	var hips := skel.find_bone("Hips")
	var worst := INF
	for side: String in ["Left", "Right"]:
		var up := skel.find_bone(side + "UpLeg")
		var leg := skel.find_bone(side + "Leg")
		var foot := skel.find_bone(side + "Foot")
		for t in ClipRetarget.sample_times(anim.length, ClipRetarget.DEFAULT_FPS):
			var pose := _clip_pose(skel, anim, t)
			var pts: PackedVector3Array = pose[0]
			var line := (pts[foot] - pts[up]).normalized()
			var knee := pts[leg] - pts[up]
			var forward: Vector3 = ((pose[1][hips] as Quaternion) * (rest_global[hips] as Quaternion).inverse()) * Vector3.BACK
			forward = forward - line * forward.dot(line)
			if forward.length() > 0.2:
				worst = minf(worst, (knee - line * knee.dot(line)).dot(forward.normalized()))
	assert_true(worst >= 0.0, "Diz kalçanın önünün gerisine geçmez: %.1f cm" % worst)
	model.free()
	lib.release()


func test_fit_legs_keeps_a_grounded_ankle_exactly_in_place() -> void:
	# Yumuşak sınır bileği yalnız uzarken tutar: aktarımın zaten yumuşattığı bacak ikinci kez yumuşamaz.
	assert_eq(ClipLibrary._fit_reach(80.0, 88.0, 90.0), 80.0, "Kısalan zincir tam gider")
	assert_eq(ClipLibrary._fit_reach(88.0, 88.0, 90.0), 88.0, "Değişmeyen zincir değişmez")
	var longer := ClipLibrary._fit_reach(92.0, 88.0, 90.0)
	assert_true(longer > 88.0 and longer < 90.0 * ClipLibrary.LEG_FIT_REACH_MAX, "Uzayan zincir sınıra yaklaşır: %.3f" % longer)
	assert_almost(ClipLibrary._fit_reach(88.0001, 88.0, 90.0), 88.0, 0.001, "Sınırda sıçrama yok")
	assert_eq(ClipLibrary._fit_reach(95.0, 89.95, 90.0), 89.95, "Klipte zaten sınırdaysa uzamaz")
	for soft: float in [50.0, 87.0, 88.0, 89.0, 89.9]:
		assert_almost(ClipRetarget._soft_reach(ClipRetarget._soft_reach_inverse(soft, 90.0), 90.0), soft, 0.0001, "Ters işlev (%.1f)" % soft)
	var stage := _stage("father")
	var lib := ClipLibrary.new()
	lib.use_leg_fit = false
	var raw := lib.clip_for("father", "idle_03", stage[1])
	var fixed := raw.duplicate(true) as Animation
	ClipLibrary.fit_legs(fixed, stage[1], {"left": 0.05})
	var foot: int = (stage[1] as Skeleton3D).find_bone("RightFoot")
	for i in 6:
		var t := raw.length * i / 5.0
		var a: Vector3 = (_clip_pose(stage[1], raw, t)[0] as PackedVector3Array)[foot]
		var b: Vector3 = (_clip_pose(stage[1], fixed, t)[0] as PackedVector3Array)[foot]
		assert_vec_almost(b, a, 0.05, "Düzeltilmeyen bacağın bileği yerinde (t=%.2f)" % t)
	stage[0].free()
	lib.release()


## Klip oyunda görünen hâliyle (omuz düzeltmesi işlenmiş) oynarken kemiklerin en alt köşesi, kişinin zemin payıyla.
func _relaxed_low(lib: ClipLibrary, id: String, stage: Array, key: String, bones: Array[String]) -> float:
	var model: Node3D = stage[0]
	var skel: Skeleton3D = stage[1]
	var anim := lib.clip_for(id, key, skel).duplicate(true) as Animation
	var up := (PoseFit.relative_transform(model, skel).basis.inverse() * Vector3.UP).normalized()
	var drop := float(CharacterAvatar._load_fit(id).get("shoulder_drop", 0.0))
	assert_true(bool(ClipLibrary.bake_shoulder_relax(anim, skel, up, drop)["baked"]), "%s/%s omuz düzeltmesi işlenir" % [id, key])
	return _lowest(model, stage[2], anim, key, bones) + lib.ground_offset_for(id, key)


func test_lowered_hips_do_not_bury_the_hands() -> void:
	# ground_lean_back: kalça inerken omuz da iner, el zemine giriyordu (Baba 6-10 cm). Bilek yerinde kalır, dirsek bükülür, el zemine göre ölçülür.
	var lib := ClipLibrary.new()
	assert_true(PoseFit.has_hand_contact(lib.variant("ground_lean_back")), "Eli yere dayanır")
	assert_true(PoseFit.has_hand_contact(lib.variant("ground_side_sit")), "Eli yere dayanır")
	assert_false(PoseFit.has_hand_contact(lib.variant("sit")), "Bağdaşta el yerde değil")
	for id in CAST:
		var stage := _stage(id)
		await wait_frames(1)
		for bones: Array[String] in [["LeftHand"] as Array[String], ["RightHand"] as Array[String]]:
			var hand := _relaxed_low(lib, id, stage, "ground_lean_back", bones)
			assert_true(hand >= -0.012, "%s/%s zemine giriyor: %.3f m" % [id, bones[0], hand])
			# Kalçası inen kişide el zemine de değer; kalçası inmeyende kol yetişmeyebilir (kalan kusur, bkz. asset-pipeline).
			if lib.leg_fit_for(id, "ground_lean_back").has("hips"):
				assert_true(hand <= 0.03, "%s/%s havada: %.3f m" % [id, bones[0], hand])
		stage[0].free()
	var fit := lib.leg_fit_for("father", "ground_lean_back")
	assert_true(float(fit.get("hips", 0.0)) > 0.1 and fit.has("hand_left") and fit.has("hand_right"), "Baba'nın kalçası iner, iki eli dengelenir: %s" % fit)
	lib.release()


func test_shoulder_relax_does_not_bury_a_grounded_hand() -> void:
	# Eli yere dayanan klibin payı oyunun gördüğü pozdan ölçülür: ShoulderRelax bileği indirir, düzeltmesiz ölçülen pay eli 2,4 cm gömüyordu (Ana).
	var lib := ClipLibrary.new()
	for id in ["mother", "lan_hatun", "teoman", "hereka"]:
		var stage := _stage(id)
		await wait_frames(1)
		var hand := _relaxed_low(lib, id, stage, "ground_side_sit", ["LeftHand"] as Array[String])
		assert_true(hand >= -0.006, "%s: sol el zemine %.3f m" % [id, hand])
		stage[0].free()
	lib.release()


func test_curve_at_reads_even_samples() -> void:
	assert_eq(ClipLibrary._curve_at([], 0.5), 0.0, "Örnek yoksa 0")
	assert_almost(ClipLibrary._curve_at([0.0, 0.2, 0.0], 0.0), 0.0, 0.0001)
	assert_almost(ClipLibrary._curve_at([0.0, 0.2, 0.0], 0.25), 0.1, 0.0001, "Örnekler arası doğrusal")
	assert_almost(ClipLibrary._curve_at([0.0, 0.2, 0.0], 0.5), 0.2, 0.0001)
	assert_almost(ClipLibrary._curve_at([0.0, 0.2, 0.3], 1.0), 0.3, 0.0001, "Son örnek son kare")


## Yatarken zemin payı gövde ve başa göredir, klipte bacak aşağı eğimlidir: ayak zemine giriyordu (kadroda 11 yatma klibinin 165 kaydından 128'i, 18 cm'ye kadar).
func test_lying_feet_stay_on_the_floor_and_the_back_stays_down() -> void:
	var lib := ClipLibrary.new()
	for id: String in LYING_CAST:
		var stage := _stage(id)
		var model: Node3D = stage[0]
		var skel: Skeleton3D = stage[1]
		var player: AnimationPlayer = stage[2]
		await wait_frames(1)
		var library: AnimationLibrary = player.get_animation_library(&"")
		for key: String in LYING_CLIPS:
			var anim := lib.clip_for(id, key, skel)
			library.add_animation(key, anim)
			player.play(key)
			var worst := INF
			# Bu klipler zemin payını ölçüden okur: geçişte iki uç arasında doğrusal.
			var ends := lib.ground_offset_ends(id, key)
			var transition: Variant = lib.variant(key).get("transition")
			for i in LYING_CHECKS:
				var share := i / float(LYING_CHECKS - 1)
				player.seek(anim.length * share, true)
				worst = minf(worst, PoseFit.skinned_min_y(model, FEET) + lerpf(ends.x, ends.y, share))
			# Sırt: yatan uçta gövde ve baş zeminde; sabit klipte zemin payının ölçüldüğü anlarda.
			var back := INF
			if transition is Dictionary:
				for end: int in [0, 1]:
					if str(transition["from" if end == 0 else "to"]).begins_with("lie"):
						player.seek(anim.length * end, true)
						back = minf(back, PoseFit.skinned_min_y(model, PoseFit.LYING_BONES) + (ends.x if end == 0 else ends.y))
			else:
				for time in PoseFit.floor_times(anim.length, lib.variant(key)):
					player.seek(time, true)
					back = minf(back, PoseFit.skinned_min_y(model, PoseFit.LYING_BONES) + ends.x)
			player.stop()
			library.remove_animation(key)
			skel.reset_bone_poses()
			assert_true(worst >= -LYING_FOOT_MARGIN, "%s/%s: ayak zemine %.3f m" % [id, key, worst])
			assert_almost(back, 0.0, 0.01, "%s/%s: gövde ve baş zeminde (%.3f m)" % [id, key, back])
		stage[0].free()
	lib.release()


func test_lying_lift_raises_only_the_feet() -> void:
	# Bilek istenen kadar kalkar, kalça ve gövde yerinde kalır, ayağın yönü değişmez.
	var stage := _stage("crowd_hun_man")
	var skel: Skeleton3D = stage[1]
	var lib := ClipLibrary.new()
	lib.use_leg_fit = false
	var raw := lib.clip_for("crowd_hun_man", "sleep_normally", skel)
	var fixed := raw.duplicate(true) as Animation
	assert_true(ClipLibrary.fit_legs(fixed, skel, {"lift_left": [0.1, 0.1], "lift_right": [0.05, 0.05]}), "Yalnız kalkış da düzeltmedir")
	var t := raw.length * 0.5
	var a: PackedVector3Array = _clip_pose(skel, raw, t)[0]
	var b: PackedVector3Array = _clip_pose(skel, fixed, t)[0]
	var bone := func(bone_name: String) -> int: return skel.find_bone(bone_name)
	assert_vec_almost(b[bone.call("LeftFoot")], a[bone.call("LeftFoot")] + Vector3.UP * 10.0, 0.05, "Sol bilek 10 cm")
	assert_vec_almost(b[bone.call("RightFoot")], a[bone.call("RightFoot")] + Vector3.UP * 5.0, 0.05, "Sağ bilek 5 cm")
	assert_vec_almost(b[bone.call("Hips")], a[bone.call("Hips")], 0.01, "Kalça yerinde")
	assert_vec_almost(b[bone.call("Head")], a[bone.call("Head")], 0.01, "Baş yerinde")
	assert_vec_almost(b[bone.call("LeftToeBase")] - b[bone.call("LeftFoot")], a[bone.call("LeftToeBase")] - a[bone.call("LeftFoot")], 0.05, "Ayağın yönü değişmez")
	stage[0].free()
	lib.release()


func test_measured_leg_fits_seat_the_body_and_plant_the_feet() -> void:
	var lib := ClipLibrary.new()
	for id in CAST:
		for key in lib.clip_keys():
			var spec := lib.variant(key)
			var fit := lib.leg_fit_for(id, key)
			if not spec.has("leg_fit"):
				assert_true(fit.is_empty(), "%s/%s: tanımda leg_fit yok" % [id, key])
				continue
			if spec["group"] == ClipVariety.GROUND_GROUP and (spec["leg_fit"] as Array).has("seat"):
				assert_true(lib.seat_gap_for(id, key) <= 0.045, "%s/%s: kalça boşluğu %.3f m" % [id, key, lib.seat_gap_for(id, key)])
			if ClipLibrary.seat_end_of(spec) >= 0:
				assert_true(lib.seat_gap_for(id, key) <= 0.07, "%s/%s: yerdeki uçta beden zeminden %.3f m yukarıda" % [id, key, lib.seat_gap_for(id, key)])
			if spec["group"] in ["idle_loop", "idle_fidget"]:
				var feet := lib.foot_gap_for(id, key)
				assert_true(minf(feet.x, feet.y) <= 0.005, "%s/%s: bir ayak zeminde (%s)" % [id, key, feet])
				assert_true(maxf(feet.x, feet.y) <= 0.03, "%s/%s: öteki ayak en çok 3 cm havada (%s)" % [id, key, feet])
	# Düzeltme kişiye göredir: Baba'nın kalçası Hereka'nınkinden çok iner.
	assert_true(float(lib.leg_fit_for("father", "ground_warm_hands")["hips"]) > float(lib.leg_fit_for("hereka", "ground_warm_hands").get("hips", 0.0)) + 0.05)
	assert_true(float(lib.leg_fit_for("father", "ground_kneel_heels")["right"]) > 0.05, "Diz çökmede ayaklar iner")
	assert_eq(lib.leg_fit_for("nobody", "ground_warm_hands"), {}, "Ölçülmemiş kişi: düzeltme yok")
	assert_eq(lib.seat_gap_for("nobody", "ground_hug_knees"), float(lib.measure("ground_hug_knees")["seat_gap_max"]), "Ölçülmemiş kişi: kadronun en kötüsü")
	assert_eq(lib.foot_gap_for("nobody", "idle_7"), Vector2.ZERO)
	# Geçiş başında kişinin kayacağı yer: bekleme klibinden geçişi oynatan sahne bunu çıkarır.
	var start := lib.root_start_for("father", "rev_stand_up_10")
	assert_true(start.y > 0.3, "rev_stand_up_10 kökü ilk karede önde: %s" % start)
	assert_eq(lib.root_start_for("nobody", "rev_stand_up_10"), Vector2(lib.measure("rev_stand_up_10")["root_start_m"][0], lib.measure("rev_stand_up_10")["root_start_m"][1]))
	assert_eq(lib.root_start_for("father", "idle_7"), Vector2.ZERO, "Geçiş değil")


func test_built_clip_uses_the_measured_fit() -> void:
	var stage := _stage("father")
	var skel: Skeleton3D = stage[1]
	var plain := ClipLibrary.new()
	plain.use_leg_fit = false
	var fitted := ClipLibrary.new()
	var hips_y := func(anim: Animation) -> float:
		return anim.position_track_interpolate(anim.find_track(NodePath("%s:Hips" % ClipRetarget.track_prefix(anim)), Animation.TYPE_POSITION_3D), 1.0).y
	var drop := float(fitted.leg_fit_for("father", "ground_warm_hands")["hips"])
	var unit := PoseFit.relative_transform(stage[0], skel).basis.get_scale().y
	assert_almost((hips_y.call(plain.clip_for("father", "ground_warm_hands", skel)) - hips_y.call(fitted.clip_for("father", "ground_warm_hands", skel))) * unit, drop, 0.002, "clip_for düzeltmeyi işler")
	stage[0].free()
	plain.release()
	fitted.release()


# --- Ölçüler ------------------------------------------------------------------------------------------------

func test_measure_file_covers_every_clip_and_character() -> void:
	var lib := ClipLibrary.new()
	var data: Variant = ClipLibrary.read_json(ClipLibrary.MEASURE_PATH)
	assert_true(data is Dictionary, "data/clip_library_measure.json okunmalı")
	if not data is Dictionary:
		return
	assert_true(str(data["_aciklama"]).contains("tools/anim_library_import.gd"), "Dosyayı kimin yazdığı")
	assert_eq(Array((data["clips"] as Dictionary).keys()).size(), 122)
	for key in lib.clip_keys():
		var m := lib.measure(key)
		assert_false(m.is_empty(), "%s ölçülmeli" % key)
		if m.is_empty():
			continue
		assert_true(float(m["duration"]) > 0.0, "%s süresi" % key)
		assert_true(m["cyclic"] is bool, "%s cyclic" % key)
		assert_true(float(m["frames"]) >= 2.0, "%s kare" % key)
		var hips: Dictionary = m["hips_m"]
		# Zıplamada kalça havada ayakta durduğundan ≈0,47 m yukarı çıkar (taşıyıcı 1,82 m): sınırı o klipte yüksektir.
		var top := 1.6 if JUMPS.has(key) else 1.2
		assert_true(float(hips["min"]) > 0.1 and float(hips["max"]) < top and float(hips["min"]) <= float(hips["mean"]) and float(hips["mean"]) <= float(hips["max"]), "%s kalça %s" % [key, hips])
		if not lib.carrier_of(key).is_empty():
			assert_almost(float(m["duration"]), lib.library_clip(key).length, 0.002, "%s süresi kaynakla aynı" % key)
		var spec := lib.variant(key)
		if str(spec["group"]) in ["walk", "run"] and spec["loop"]:
			assert_true(float(m.get("speed_mps", 0.0)) > 0.05, "%s doğal hız" % key)
		if bool(spec["loop"]) and str(spec["group"]) != "sit_chair" and str(spec["group"]) != "sit_ground":
			assert_true(m["cyclic"], "%s döngülü: oyunun kurallarından sonra ilk ve son pozu aynı olmalı" % key)
	assert_true(lib.measure("yok").is_empty())
	# Hızlar: koşu yürümeden hızlı, yaşlı yürüyüşü yavaş.
	assert_true(float(lib.measure("run_fast")["speed_mps"]) > 3.0 * float(lib.measure("casual_walk")["speed_mps"]))
	assert_true(float(lib.measure("elderly_shaky_walk")["speed_mps"]) < float(lib.measure("casual_walk")["speed_mps"]))
	# Ham klipte kök ilerliyorsa doğal hız kökün hızıdır (ayağın kayma hızı %10-39 sapıyordu); kişide kalça oranıyla.
	var carried_root := 0
	var donor := lib.donor_skeleton()
	for key in lib.clip_keys():
		var m := lib.measure(key)
		if not m.has("speed_mps") or float(m["root_speed_mps"]) <= IMPORT.ROOT_MOTION_MIN:
			continue
		carried_root += 1
		assert_almost(float(m["speed_mps"]), float(m["root_speed_mps"]), 0.005, "%s: kök hızı" % key)
	assert_eq(carried_root, 13, "Kök hareketli on üç döngü")
	var father_root := _instantiate("father")
	var ratio := ClipRetarget.hips_ratio(donor, ClipLibrary.find_skeleton(father_root))
	assert_almost(lib.speed_for("father", "walking_2"), float(lib.measure("walking_2")["root_speed_mps"]) * ratio, 0.02, "Kişide kalça oranıyla")
	father_root.free()
	lib.release()
	# Kalça: sandalye yerden yüksek.
	assert_true(float(lib.measure("chair_sit_idle_m")["hips_m"]["mean"]) > float(lib.measure("ground_warm_hands")["hips_m"]["mean"]) + 0.2)
	# Karakterler: her klipte zemin payı.
	for id in CAST:
		var model: Dictionary = data["models"].get(id, {})
		assert_false(model.is_empty(), "%s ölçülmeli" % id)
		if model.is_empty():
			continue
		for key in lib.clip_keys():
			assert_true((model["offset"] as Dictionary).has(key), "%s/%s payı" % [id, key])
			var offset := lib.ground_offset_for(id, key)
			assert_true(absf(offset) < 0.3, "%s/%s payı %.3f" % [id, key, offset])
			if lib.variant(key).has("transition"):
				assert_true((model["ends"] as Dictionary).has(key), "%s/%s uçları" % [id, key])
		assert_true(lib.speed_for(id, "proud_strut") > 0.05, "%s doğal hızı" % id)
		assert_true(lib.hips_height_for(id, "chair_sit_idle_m") > 0.3, "%s oturak yüksekliği" % id)
	var ends := lib.ground_offset_ends("mother", "rev_stand_up_3")
	assert_eq(ends, Vector2(data["models"]["mother"]["ends"]["rev_stand_up_3"][0], data["models"]["mother"]["ends"]["rev_stand_up_3"][1]))
	assert_eq(lib.ground_offset_ends("mother", "idle_7"), Vector2(lib.ground_offset_for("mother", "idle_7"), lib.ground_offset_for("mother", "idle_7")), "Geçiş değilse tek pay")
	assert_eq(lib.ground_offset_for("nobody", "idle_7"), 0.0, "Ölçülmemiş kişi: 0")
	assert_eq(lib.speed_for("nobody", "proud_strut"), float(lib.measure("proud_strut")["speed_mps"]), "Ölçülmemiş kişi: taşıyıcının hızı")


func test_low_share_offset_takes_the_low_slice() -> void:
	var lows := PackedFloat32Array([0.05, 0.01, 0.06, 0.02, 0.07, 0.03, 0.08, 0.04])
	assert_almost(PoseFit.low_share_offset(lows, 0.25), -0.03, 0.0001, "Alttan dörtte bir")
	assert_almost(PoseFit.low_share_offset(lows, 0.0), -0.01, 0.0001, "En alçak an")
	assert_eq(PoseFit.low_share_offset(PackedFloat32Array(), 0.25), 0.0, "Örnek yoksa 0")


func test_floor_rule_is_one_for_the_game_and_the_page() -> void:
	# Oyunun payı (tools/anim_library_import.gd) ve belge sitesinin payı (tools/clip_library_export.gd) aynı kuraldan ölçülür.
	var lib := ClipLibrary.new()
	var walk := lib.variant("walk")
	assert_true(PoseFit.is_stride(walk) and PoseFit.is_stride(lib.variant("run")), "Yürüme ve koşma")
	assert_false(PoseFit.is_stride(lib.variant("discuss_while_moving")), "Bir kez oynayan yürüyüş sayılmaz")
	assert_false(PoseFit.is_stride(lib.variant("sit")))
	var stride := PoseFit.floor_times(2.0, walk)
	assert_eq(stride.size(), PoseFit.STRIDE_FLOOR_SAMPLES)
	assert_almost(stride[stride.size() - 1], 2.0 - 2.0 / PoseFit.STRIDE_FLOOR_SAMPLES, 0.0001, "Son örnek süreden bir adım önce: seek(süre) ilk kareye sarar")
	var still := PoseFit.floor_times(2.0, lib.variant("sit"))
	assert_eq(still.size(), PoseFit.FLOOR_SAMPLES)
	assert_almost(still[still.size() - 1], 2.0, 0.0001, "Öteki kliplerde son kare dahil")
	var lows := PackedFloat32Array([0.05, 0.01, 0.06, 0.02, 0.07, 0.03, 0.08, 0.04])
	assert_almost(PoseFit.floor_offset(lows, walk), -0.03, 0.0001, "Yürümede alttan dörtte bir")
	assert_almost(PoseFit.floor_offset(lows, lib.variant("run")), -0.01, 0.0001, "Koşuda alttan onda bir")
	assert_almost(PoseFit.floor_offset(lows, lib.variant("sit")), -0.01, 0.0001, "Öteki kliplerde en alçak an")
	lib.release()


func test_stride_offset_keeps_uneven_steps_near_the_floor() -> void:
	# Adımları eşit olmayan yürüyüşte en alçak ana göre pay kişiyi çoğu karede havada bırakıyordu (Baba, quick_walk: 4-5 cm).
	var lib := ClipLibrary.new()
	var stage := _stage("father")
	var model: Node3D = stage[0]
	var player: AnimationPlayer = stage[2]
	await wait_frames(1)
	for key in ["quick_walk", "casual_walk"]:
		var anim := lib.clip_for("father", key, stage[1])
		player.get_animation_library(&"").add_animation(key, anim)
		player.play(key)
		var lows := PackedFloat32Array()
		for i in 60:
			player.seek(anim.length * i / 60.0, true)
			lows.append(PoseFit.skinned_min_y(model, FEET) + lib.ground_offset_for("father", key))
		lows.sort()
		assert_true(lows[30] < 0.03, "%s: karelerin yarısında ayak en çok 3 cm havada (%.3f)" % [key, lows[30]])
		assert_true(lows[0] > -0.045, "%s: en derin anda en çok 4,5 cm gömülü (%.3f)" % [key, lows[0]])
	player.stop()
	stage[0].free()
	lib.release()


func test_ground_offsets_put_the_right_bones_on_the_floor() -> void:
	# Ölçülerin kararını gerçek köşelerle sınar (uzun cüppeli, kısa ve uzun kollu kişiler).
	var lib := ClipLibrary.new()
	for id in ["mete", "mother", "teoman", "hereka_young", "child"]:
		var stage := _stage(id)
		var model: Node3D = stage[0]
		var skel: Skeleton3D = stage[1]
		var player: AnimationPlayer = stage[2]
		# Ayakta: ayak zeminde (cüppenin baldıra bağlı eteği sayılmaz).
		for key in ["idle_7", "talk_hands_open"]:
			var anim := lib.clip_for(id, key, skel)
			assert_almost(_lowest(model, player, anim, key, FEET) + lib.ground_offset_for(id, key), 0.0, 0.01, "%s/%s ayak zeminde" % [id, key])
		# Yana oturuş: kol açılmış, el yere yatmış; ne el ne kalça gömülür, kalça da havada kalmaz.
		var side := lib.clip_for(id, "ground_side_sit", skel)
		var offset := lib.ground_offset_for(id, "ground_side_sit")
		var hand := _lowest(model, player, side, "ground_side_sit", ["LeftHand"] as Array[String]) + offset
		assert_true(hand > -0.012 and hand < 0.20, "%s: sol el zemine %.3f m" % [id, hand])
		var hips := _lowest(model, player, side, "ground_side_sit", ["Hips"] as Array[String]) + offset
		assert_true(hips > -0.012, "%s: kalça zemine %.3f m" % [id, hips])
		var joint := _lowest_joint(model, skel, player, side, "ground_side_sit", "Hips") + offset
		assert_true(joint > 0.10 and joint < 0.32, "%s: kalça eklemi %.3f m" % [id, joint])
		# Kalçası indirilen oturuş: beden ve ayak zeminde, cüppenin baldıra bağlı eteği kişiyi kaldırmaz.
		var warm := lib.clip_for(id, "ground_warm_hands", skel)
		var warm_offset := lib.ground_offset_for(id, "ground_warm_hands")
		assert_almost(_lowest(model, player, warm, "ground_warm_hands", FEET) + warm_offset, 0.0, 0.02, "%s: ayak zeminde" % id)
		assert_true(_seat_low(model, player, warm, "ground_warm_hands") + warm_offset <= 0.045, "%s: kalça zeminde" % id)
		# Diz çökerek oturuş: ayak zeminde, diz eklemi zemine yakın (ham klipte ayaklar 6-19 cm havadaydı).
		var kneel := lib.clip_for(id, "ground_kneel_heels", skel)
		var kneel_offset := lib.ground_offset_for(id, "ground_kneel_heels")
		assert_almost(_lowest(model, player, kneel, "ground_kneel_heels", FEET) + kneel_offset, 0.0, 0.01, "%s: diz çökünce ayak zeminde" % id)
		var knee := minf(_lowest_joint(model, skel, player, kneel, "ground_kneel_heels", "LeftLeg"), _lowest_joint(model, skel, player, kneel, "ground_kneel_heels", "RightLeg")) + kneel_offset
		assert_between(knee, 0.0, 0.16, "%s: diz eklemi zeminden %.3f m yukarıda" % [id, knee])
		# Yatış: sırt zeminde.
		var lying := lib.clip_for(id, "sleep_normally", skel)
		assert_almost(_lowest(model, player, lying, "sleep_normally", PoseFit.LYING_BONES) + lib.ground_offset_for(id, "sleep_normally"), 0.0, 0.01, "%s: sırt zeminde" % id)
		stage[0].free()
	lib.release()


func test_ground_side_sit_hand_lies_flat_and_catching_breath_starts_at_the_rest() -> void:
	var lib := ClipLibrary.new()
	var skel := lib.donor_skeleton()
	var anim := lib.library_clip("ground_side_sit")
	var prefix := ClipRetarget.track_prefix(anim)
	var rest := ClipRetarget.rest_rotations(skel)
	var rest_global := ClipRetarget.global_rotations(skel, rest)
	var points := ClipRetarget.rest_points(skel)
	var hand := skel.find_bone("LeftHand")
	var fingers := (points[hand] - points[skel.get_bone_parent(hand)]).normalized()
	var global := ClipRetarget.global_rotations(skel, ClipRetarget.local_rotations_at(anim, skel, rest, prefix, anim.length * 0.5))
	var now: Vector3 = (global[hand] * rest_global[hand].inverse()) * fingers
	assert_true(now.y > -0.2 and now.y < 0.0, "Parmaklar neredeyse yatay: %s" % now)
	var breath := lib.library_clip("catching_breath")
	assert_true(breath.length < 3.0, "Koşup gelme kesilir: %.2f sn" % breath.length)
	var hips := breath.find_track(NodePath("%s:Hips" % ClipRetarget.track_prefix(breath)), Animation.TYPE_POSITION_3D)
	var first: Vector3 = breath.track_get_key_value(hips, 0)
	var last: Vector3 = breath.track_get_key_value(hips, breath.track_get_key_count(hips) - 1)
	assert_true(Vector2(last.x - first.x, last.z - first.z).length() < 30.0, "Kök yerinde kalır: %s → %s" % [first, last])
	lib.release()


# --- K90: tekrar alım denetimi ------------------------------------------------------------------------------

func test_meshy_pipeline_refuses_a_repurchase() -> void:
	var tools_dir := ProjectSettings.globalize_path("res://tools")
	# OS.execute çıktı okurken argümanları kabuk komutuna çift tırnakla sarar: kodda çift tırnak olmamalı.
	var code := """
import json, sys
sys.path.insert(0, '%s')
import meshy_pipeline as m
plan = m.load_plan()
owners = m.purchased_actions()
out = {'real': m.validate_plan(plan), 'owners_246': owners.get(246), 'owners_243': owners.get(243), 'owners_28': owners.get(28)}
row = dict([a for a in plan['assets'] if a['id'] == 'teoman'][0])
row['animations'] = [246]
out['batch'] = m.k90_errors(row, owners)
row['animations'] = [363, 999999]
out['single'] = m.k90_errors(row, owners)
out['own'] = m.k90_errors({'id': 'mete', 'animations': [244, 363]}, owners)
out['free'] = m.k90_errors({'id': 'yeni', 'animations': [999999]}, owners)
plan2 = json.loads(json.dumps(plan))
[a for a in plan2['assets'] if a['id'] == 'teoman'][0]['animations'] = [246]
out['validate'] = [e for e in m.validate_plan(plan2) if 'K90' in e]
print(json.dumps(out))
""" % tools_dir
	var output := []
	var exit_code := OS.execute("python3", ["-B", "-c", code], output, true)
	assert_eq(exit_code, 0, "Python denetimi koşmalı: %s" % output)
	var last_line := str(output[0]).strip_edges().get_slice("\n", str(output[0]).strip_edges().get_slice_count("\n") - 1)
	var result: Variant = JSON.parse_string(last_line)
	assert_true(result is Dictionary, "Çıktı okunmalı: %s" % output)
	if not result is Dictionary:
		return
	var k90 := (result["real"] as Array).filter(func(e: String) -> bool: return e.contains("K90"))
	assert_eq(k90, [], "Bugünkü plan temiz: eski satırların kendi aldıkları hata sayılmaz")
	assert_eq(result["owners_246"], [CARRIER], "Toplu alımın hareketi taşıyıcıda")
	assert_eq(result["owners_28"], [CARRIER], "Son toplu alım da okunur")
	assert_eq(result["owners_243"], ["hero_f", "mete"], "Tek hareket görevleri okunur")
	assert_eq(result["batch"], ["teoman: K90: hareket 246 zaten _anim_library'de alındı; ClipRetarget ile aktar"])
	assert_eq(result["single"], ["teoman: K90: hareket 363 zaten child, elder, father, mete, mother'de alındı; ClipRetarget ile aktar"], "Kimsenin almadığı hareket hata değil")
	assert_eq(result["own"], [], "Kendi aldığı hareket hata değil")
	assert_eq(result["free"], [], "Alınmamış hareket serbest")
	assert_eq(result["validate"], result["batch"], "Plan denetimi aynı hatayı verir")
