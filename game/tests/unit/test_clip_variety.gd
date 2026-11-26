extends TestCase
## Animasyon çeşitliliği (ClipVariety, CharacterAvatar, CineActor): kişi profili, uygun çeşitler (beden, yaş, stil, durum, oturak,
## hız), belirlenimci seçim, aynı sahnede tekillik, avatarın rolleri (klip, zemin payı, hız, sabit roller, aynı modeli gösteren iki
## kişi), ara hareketlerin saati, sinemada kapalı olmaları ve model değişiminden sonra poz (kök neden: T-poz ve motor hatası).
## Kamp ve doğum sahnesinin atamaları kendi sınamalarındadır (test_camp_npcs, test_prologue_birth).

const NPC_SCENE := preload("res://scenes/world/camp_npcs.tscn")
const TempDir := preload("res://tests/support/temp_dir.gd")
## Kadro: kişi → [beden, yaş].
## Sahnenin ağır yürüttüğü yaşlının hızı (m/sn).
const ELDER_WALK := 1.0
const CAST := {"mete": ["male", "adult"], "hero_f": ["female", "adult"], "mother": ["female", "adult"], "father": ["male", "adult"],
	"elder": ["male", "elder"], "child": ["child", "child"], "teoman": ["male", "adult"], "lan_hatun": ["female", "adult"],
	"older_brother": ["male", "adult"], "hereka": ["female", "elder"], "hereka_young": ["female", "adult"],
	"counter": ["male", "elder"], "crowd_hun_man": ["male", "adult"], "crowd_hun_woman": ["female", "adult"],
	"crowd_hun_rider": ["male", "adult"], "lan_woman_a": ["female", "adult"], "lan_woman_b": ["female", "adult"]}
const GROUPS: Array[String] = ["idle_loop", "walk", "run", "sit_ground"]
const MALE := {"body": "male", "age": "adult", "style": []}
const FEMALE := {"body": "female", "age": "adult", "style": []}
const CHILD := {"body": "child", "age": "child", "style": []}
const ELDER := {"body": "male", "age": "elder", "style": []}

var _trash: Array[Node] = []


func after_each() -> void:
	for node in _trash:
		if is_instance_valid(node):
			node.queue_free()
	_trash.clear()
	ClipVariety.release_sources()


## Modeli yüklü avatar (ağaçta); kişi verilirse çeşitlilik açık.
func _avatar(model: String, person: String = "", allocator: ClipVariety.Allocator = null, pose: StringName = &"idle") -> CharacterAvatar:
	var avatar := CharacterAvatar.new()
	avatar.model_override = model
	avatar.start_pose = pose
	avatar.variety_person = person
	avatar.variety_allocator = allocator
	add_child(avatar)
	_trash.append(avatar)
	return avatar


# --- Profil ---------------------------------------------------------------------------------------------

func test_profile_comes_from_meta_json() -> void:
	for id: String in CAST:
		var profile := ClipVariety.profile_of(id)
		assert_eq(profile["body"], CAST[id][0], "%s bedeni" % id)
		assert_eq(profile["age"], CAST[id][1], "%s yaşı" % id)
		var record: Variant = StandIn.meta(id).get("variety")
		assert_true(record is Dictionary, "%s: meta.json'da variety alanı" % id)
	assert_eq(ClipVariety.profile_of("teoman")["style"], ["proud"], "Teoman gururlu")
	assert_eq(ClipVariety.profile_of("crowd_hun_rider")["style"], ["warrior"], "Atlı savaşçı")
	assert_eq(ClipVariety.profile_of("counter")["age"], "elder", "Sayıcı yaşlı")
	assert_eq(ClipVariety.profile_of("hereka")["age"], "elder", "Yaşlı Hereka")
	assert_eq(ClipVariety.profile_of("hereka_young")["age"], "adult", "39 yaşındaki Hereka")
	assert_eq(ClipVariety.profile_of("child")["age"], "child")


func test_profile_falls_back_to_the_library() -> void:
	# meta.json'da variety yoksa beden kütüphanenin characters kaydından, yaş bedenden.
	var root := TempDir.fresh("clip_variety_profile")
	DirAccess.make_dir_recursive_absolute(root.path_join("mother"))
	var file := FileAccess.open(root.path_join("mother/meta.json"), FileAccess.WRITE)
	file.store_string("{\"id\": \"mother\"}")
	file.close()
	DirAccess.make_dir_recursive_absolute(root.path_join("child"))
	assert_eq(ClipVariety.profile_of("mother", root), {"body": "female", "age": "adult", "style": []}, "Kütüphanenin bedeni")
	assert_eq(ClipVariety.profile_of("child", root), {"body": "child", "age": "child", "style": []}, "Meta yok: kütüphane, çocuk bedeni")
	assert_eq(ClipVariety.profile_of("kimse_yok", root)["age"], "adult", "Bilinmeyen kişi yetişkin sayılır")
	DirAccess.remove_absolute(root.path_join("mother/meta.json"))
	DirAccess.remove_absolute(root.path_join("mother"))
	DirAccess.remove_absolute(root.path_join("child"))
	DirAccess.remove_absolute(root)


# --- Uygun çeşitler ---------------------------------------------------------------------------------------

func test_tags_filter_body_age_and_persona() -> void:
	assert_true(ClipVariety.eligible("idle_loop", FEMALE).has("idle_6"), "Kadınsı bekleme kadına")
	assert_false(ClipVariety.eligible("idle_loop", MALE).has("idle_6"), "Erkeğe gitmez")
	assert_false(ClipVariety.eligible("idle_loop", MALE).has("idle_11"), "Gururlu duruş stili olmayana gitmez")
	assert_true(ClipVariety.eligible("idle_loop", {"body": "male", "age": "adult", "style": ["proud"]}).has("idle_11"), "Gururlu kişiye")
	assert_false(ClipVariety.eligible("walk", FEMALE).has("casual_walk"), "Erkek yürüyüşü kadına gitmez")
	assert_true(ClipVariety.eligible("walk", CHILD).has("skip_forward"), "Seke seke yürüyüş çocuğa")
	assert_false(ClipVariety.eligible("walk", MALE).has("skip_forward"), "Yetişkine gitmez")
	assert_false(ClipVariety.eligible("idle_fidget", MALE).has("alert"), "Tetikte bekleme savaşçıya")
	assert_true(ClipVariety.eligible("idle_fidget", {"body": "male", "age": "adult", "style": ["warrior"]}).has("alert"))
	# Pozu kabul edilmemiş klip (scene_only) kimseye hash'le düşmez, stili uyan kişiye de; sahne isterse elle seçer.
	assert_true(bool(ClipVariety.library().variant("ground_side_sit").get("scene_only", false)), "ground_side_sit varsayılan atamada değil")
	for profile: Dictionary in [FEMALE, MALE, ClipVariety.profile_of("lan_hatun")]:
		assert_false(ClipVariety.eligible("sit_ground", profile).has("ground_side_sit"), "Varsayılan havuzda yok")
	assert_false(ClipVariety.eligible("sit_ground", FEMALE, {"situations": ["calm", "graceful"]}).has("ground_side_sit"), "Durum istemek de getirmez")
	var hand_pick := ClipVariety.Allocator.new()
	hand_pick.assign("lan_hatun", ClipVariety.GROUND_GROUP, "ground_side_sit")
	assert_eq(hand_pick.key_for("lan_hatun", ClipVariety.GROUND_GROUP), "ground_side_sit", "Sahnenin elle seçimi yine geçerli")
	assert_ne(ClipVariety.pick("lan_hatun", "sit_ground", ClipVariety.profile_of("lan_hatun")), "ground_side_sit", "Lan Hatun'un sahnesiz ataması değişti")
	assert_false(ClipVariety.eligible("run", ELDER).has("run_02"), "Yaşlı sıradan koşu klibiyle koşmaz")
	var lib := ClipVariety.library()
	for group: String in GROUPS:
		for id: String in CAST:
			for key: String in ClipVariety.eligible(group, ClipVariety.profile_of(id)):
				var tags: Dictionary = lib.variant(key).get("tags", {})
				assert_true((tags.get("body", []) as Array).has(CAST[id][0]), "%s/%s: beden" % [id, key])
				assert_true((tags.get("age", []) as Array).has(CAST[id][1]), "%s/%s: yaş" % [id, key])


func test_situations_stay_out_of_the_default_assignment() -> void:
	# chore, talk, festive... varsayılan atamaya girmez; açıkça istenince havuz o duruma daralır.
	for key in ["carry_heavy_object_walk", "spear_walk", "discuss_while_moving", "carry_water_bucket_walk"]:
		assert_false(ClipVariety.eligible("walk", MALE).has(key), "%s varsayılan yürüyüş değil" % key)
	for key in ["ground_mend", "ground_eat_bowl", "ground_doze"]:
		assert_false(ClipVariety.eligible("sit_ground", ELDER).has(key), "%s varsayılan oturuş değil" % key)
	assert_false(ClipVariety.eligible("idle_loop", MALE).has("listening_gesture"), "Dinleme durum çeşidi")
	assert_eq(ClipVariety.eligible("sit_ground", FEMALE, {"situations": ["chore"]}), ["ground_mend"], "Yama açıkça istenir")
	assert_eq(ClipVariety.eligible("sit_ground", MALE, {"situations": ["meal"]}), ["ground_eat_bowl"], "Yemek açıkça istenir")
	assert_eq(ClipVariety.eligible("sit_ground", ELDER, {"situations": ["night"]}), ["ground_warm_hands", "ground_doze"], "Gece çeşitleri")
	assert_eq(ClipVariety.pick("mother", "sit_ground", FEMALE, [], {"situations": ["chore"]}), "ground_mend")
	assert_eq(ClipVariety.eligible("sit_ground", MALE, {"situations": ["leisure"]}), ["ground_lean_back"], "Mola oturuşu sahne ister")
	# Stili olan kişi kendi durumunu istemeden alır.
	assert_true(ClipVariety.eligible("idle_loop", {"body": "male", "age": "adult", "style": ["listen"]}).has("listening_gesture"))
	# «calm» de taşıyan çeşit durum sayılmaz: el ısıtma ve topuk üstü diz çökme sıradan birer oturuştur.
	assert_true(ClipVariety.eligible("sit_ground", MALE).has("ground_warm_hands"))
	assert_true(ClipVariety.eligible("sit_ground", MALE).has("ground_kneel_heels"))
	# Kıpırdanmada da süzülür: anlatan eller ve koşudan sonra soluklanma durup dururken oynamaz.
	assert_eq(ClipVariety.fidget_pool(MALE), ["idle_03", "confused_scratch", "shrug"], "Sıradan kişinin ara hareketleri")


func test_props_and_floating_seats_need_the_scene() -> void:
	var warrior := {"body": "male", "age": "adult", "style": ["warrior"]}
	assert_false(ClipVariety.eligible("walk", warrior).has("spear_walk"), "Mızraksız mızrak yürüyüşü yok")
	assert_true(ClipVariety.eligible("walk", warrior, {"props": ["spear"], "speeds": {"walk": 1.5}}).has("spear_walk"), "Sahne mızrak verirse")
	# Dizlerini kucaklayan klipte kalça havada kalır: yalnız elle seçilir, altına oturak konur (ateş başında Çocuk'un kütüğü).
	var lib := ClipVariety.library()
	assert_false(ClipVariety.eligible("sit_ground", MALE).has("ground_hug_knees"), "Kişi söylenmezse kadronun en kötüsü sayılır")
	for id: String in CAST:
		var options := {"model": ClipVariety.model_of(id)}
		var gap := lib.seat_gap_for(options["model"], "ground_hug_knees")
		assert_true(gap > ClipVariety.MAX_SEAT_GAP, "%s: gerekçesi ölçüde (kalça zeminden %.3f m yukarıda)" % [id, gap])
		assert_false(ClipVariety.eligible("sit_ground", ClipVariety.profile_of(id), options).has("ground_hug_knees"), "%s: varsayılan havuzda değil" % id)
		# Havuzdaki her oturuşta beden zemindedir.
		for key: String in ClipVariety.eligible("sit_ground", ClipVariety.profile_of(id), options):
			assert_true(lib.seat_gap_for(options["model"], key) <= ClipVariety.MAX_SEAT_GAP, "%s/%s: kalça boşluğu %.3f m" % [id, key, lib.seat_gap_for(options["model"], key)])
	var allocator := ClipVariety.Allocator.new()
	allocator.assign("child", ClipVariety.GROUND_GROUP, "ground_hug_knees")
	assert_eq(allocator.key_for("child", ClipVariety.GROUND_GROUP), "ground_hug_knees", "Sahne elle seçebilir")


func test_chair_seats_only_with_a_seat_of_the_right_height() -> void:
	# Bugünkü sahnelerde oturak yok: varsayılan oturuş yerdedir; oturak isteyen çeşitler sahne verirse gelir.
	assert_eq(ClipVariety.group_for(&"sit"), "sit_ground")
	assert_eq(ClipVariety.eligible("sit_chair", MALE), [], "Oturak yoksa oturak çeşidi yok")
	assert_eq(ClipVariety.pick("father", "sit_chair", MALE), "", "Seçilemez")
	var seat := {"seat": {"type": "chair"}, "model": "father"}
	assert_eq(ClipVariety.group_for(&"sit", seat), "sit_chair")
	var any := ClipVariety.eligible("sit_chair", MALE, seat)
	assert_true(any.has("chair_sit_idle_m") and any.has("sit_arms_crossed"), "Oturak varsa")
	assert_false(any.has("sit_and_drink"), "İçmek durum çeşidi")
	assert_false(ClipVariety.eligible("sit_chair", CHILD, seat).is_empty(), "Çocuğun da oturak çeşidi var")
	var lib := ClipVariety.library()
	var hips := lib.hips_height_for("father", "chair_sit_idle_m")
	var fitted := ClipVariety.eligible("sit_chair", MALE, {"seat": {"type": "chair", "hips_m": hips}, "model": "father"})
	assert_true(fitted.has("chair_sit_idle_m"), "Yüksekliği tutan çeşit")
	for key: String in fitted:
		assert_true(absf(lib.hips_height_for("father", key) - hips) <= ClipVariety.SEAT_TOLERANCE, "%s oturağa uymalı" % key)
	assert_eq(ClipVariety.eligible("sit_chair", MALE, {"seat": {"type": "chair", "hips_m": 0.2}, "model": "father"}), [], "Çok alçak oturak")
	var allocator := ClipVariety.Allocator.new()
	allocator.register("father", {}, {"seat": {"type": "chair"}})
	assert_true(ClipVariety.library().variants_in("sit_chair").has(allocator.key_for_role("father", &"sit")), "Oturaklı sahnede oturma rolü")


func test_walk_and_run_must_reach_the_speed() -> void:
	# Doğal hızı kişinin hızına yetişmeyen klipte ayak yerde kayar: elderly_shaky_walk kök hızıyla ≈0,18 m/sn.
	var options := {"model": "counter"}
	assert_false(ClipVariety.eligible("walk", ELDER, options).has("elderly_shaky_walk"), "1,2 m/sn'de titrek yürüyüş yok")
	options["speeds"] = {"walk": 0.28}
	assert_eq(ClipVariety.eligible("walk", ELDER, options), ["walk_slowly_look_around", "elderly_shaky_walk"], "Ağır yürüyen yaşlıya ağır klipler")
	# Hiçbiri yetişmezse sınıra en yakını: 3 m/sn'ye en çok normal yürüyüş yaklaşır (1,8 katla ≈2,6).
	options["speeds"] = {"walk": 3.0}
	assert_eq(ClipVariety.eligible("walk", ELDER, options), ["walk"], "Yetişen yoksa en yakını")
	for id: String in CAST:
		var model := ClipVariety.model_of(id)
		for group: String in ["walk", "run"]:
			var rates := CharacterAvatar.WALK_RATE_RANGE if group == "walk" else CharacterAvatar.RUN_RATE_RANGE
			var speed := float(ClipVariety.DEFAULT_SPEEDS[group])
			var pool := ClipVariety.eligible(group, ClipVariety.profile_of(id), {"model": model})
			assert_false(pool.is_empty(), "%s: %s havuzu" % [id, group])
			if pool.size() < 2:
				continue
			for key: String in pool:
				var natural := ClipVariety.library().speed_for(model, key)
				assert_between(speed / natural, rates.x, rates.y, "%s/%s: oynatma hızı sınırda (%.2f m/sn)" % [id, key, natural])
	assert_false(ClipVariety.eligible("walk", MALE, {"model": "father"}).has("discuss_while_moving"), "Geçiş yürüme rolü olamaz")


func test_transitions_are_chosen_by_their_ends() -> void:
	# Oturma ve kalkma geçişleri rol değildir; sahne iki ucuyla seçer.
	var ups := ClipVariety.eligible("stand_up", FEMALE, {"from": "sit_ground", "to": "stand"})
	assert_true(ups.has("stand_up_3") and ups.has("stand_up_9"), "Yerden kalkışlar: %s" % [ups])
	assert_false(ups.has("sit_to_stand_f"), "Oturaktan kalkış değil")
	var downs := ClipVariety.eligible("sit_down", MALE, {"from": "stand", "to": "sit_ground"})
	assert_true(downs.has("rev_stand_up_3"), "Ayaktan yere")
	assert_false(downs.has("rev_stand_up_9"), "Kadınsı olan erkeğe gitmez")
	assert_false(ClipVariety.pick("father", "stand_up", MALE, [], {"from": "sit_chair", "to": "stand"}).is_empty())
	# Kişinin bugün oturduğu her yerden kalkış ve oraya iniş var: Ozan, Sayıcı, Hereka ve Çocuk dahil.
	var ends := [["stand_up", "sit_ground", "stand"], ["sit_down", "stand", "sit_ground"], ["stand_up", "sit_chair", "stand"], ["sit_down", "stand", "sit_chair"],
		["stand_up", "lie_back", "stand"], ["stand_up", "kneel", "stand"], ["sit_down", "stand", "kneel"]]
	for id: String in CAST:
		for end: Array in ends:
			assert_false(ClipVariety.pick(id, end[0], ClipVariety.profile_of(id), [], {"from": end[1], "to": end[2]}).is_empty(), "%s: %s → %s" % [id, end[1], end[2]])


func test_every_person_has_real_choice() -> void:
	# «En az 10 çeşit» kütüphanenin sayısıdır; etiket ve hız süzgecinden sonra kişiye kalan da gerçek bir seçim olmalı: kişi başına
	# hedefler. Yaşlı koşmaz (tek koşu klibi kalır), ağır yürür. Yetişkin yürüyüşünde sınır kütüphanedir: 1,2 m/sn'ye yetişen, kişiye özgü
	# ve durum çeşidi olmayan dört erkek ve beş kadın yürüyüşü var; düşünceli yürüyüş kısa adımlı erkekte sınırın altında kalır.
	const WANT := {"adult": {"idle_loop": 7, "walk": 3, "run": 3, "sit_ground": 4}, "elder": {"idle_loop": 7, "walk": 3, "sit_ground": 4},
		"child": {"idle_loop": 7, "walk": 3, "run": 3, "sit_ground": 4}}
	for id: String in CAST:
		var profile := ClipVariety.profile_of(id)
		var options := {"model": ClipVariety.model_of(id)}
		var want: Dictionary = WANT[profile["age"]]
		for group: String in want:
			var scene := options if group != "walk" or profile["age"] != "elder" else {"model": options["model"], "speeds": {"walk": ELDER_WALK}}
			var pool := ClipVariety.eligible(group, profile, scene)
			assert_true(pool.size() >= want[group], "%s/%s: %d çeşit, en az %d: %s" % [id, group, pool.size(), want[group], pool])
		assert_true(ClipVariety.fidget_pool(profile).size() >= 3, "%s: ara hareket" % id)
		for key: String in ClipVariety.fidget_pool(profile):
			assert_true(float(ClipVariety.library().measure(key)["duration"]) <= 8.0, "%s: ara hareket kısa olmalı" % key)
	assert_eq(ClipVariety.eligible("walk", {"body": "male", "age": "adult", "style": []}, {"model": "father"}).size(), 4, "Sınır kütüphanede: yeni yürüyüş alınırsa bu sayı ve hedef artar")


# --- Seçim ---------------------------------------------------------------------------------------------

func test_pick_is_deterministic() -> void:
	for id: String in CAST:
		var profile := ClipVariety.profile_of(id)
		var options := {"model": ClipVariety.model_of(id)}
		for group: String in GROUPS:
			var first := ClipVariety.pick(id, group, profile, [], options)
			assert_false(first.is_empty(), "%s/%s" % [id, group])
			for i in 3:
				assert_eq(ClipVariety.pick(id, group, profile, [], options), first, "%s/%s her seferinde aynı" % [id, group])
			assert_true(ClipVariety.eligible(group, profile, options).has(first), "%s/%s uygun çeşitlerden" % [id, group])
	assert_eq(ClipVariety.stable_hash("teoman:walk"), absi("teoman:walk".hash()), "StableSeed'in yöntemi")
	# Sabit değer: String.hash çalıştırmadan çalıştırmaya (ya da motor sürümüyle) değişirse sınama yakalar.
	assert_eq(ClipVariety.stable_hash("teoman:walk"), 995672626, "Çalıştırmadan çalıştırmaya aynı")


func test_persona_comes_first() -> void:
	# Stil kişiyi ayırsın: Teoman'ın duruşu ve yürüyüşü hash'e kalmaz.
	assert_eq(ClipVariety.pick("teoman", "idle_loop", ClipVariety.profile_of("teoman")), "idle_11")
	assert_eq(ClipVariety.pick("teoman", "walk", ClipVariety.profile_of("teoman")), "proud_strut")
	assert_eq(ClipVariety.pick("crowd_hun_rider", "run", ClipVariety.profile_of("crowd_hun_rider")), "lean_forward_sprint")
	assert_eq(ClipVariety.pick("hereka_young", "sit_ground", ClipVariety.profile_of("hereka_young")), "ground_kneel_heels", "Topuk üstü diz çöken ebe")
	# Alınmışsa sırası gelen.
	assert_ne(ClipVariety.pick("teoman", "walk", ClipVariety.profile_of("teoman"), ["proud_strut"]), "proud_strut")


func test_taken_is_skipped_and_the_hash_wins_when_all_are_taken() -> void:
	var order := ClipVariety.pick_order("father", "idle_loop", MALE)
	assert_eq(ClipVariety.pick("father", "idle_loop", MALE, [order[0]]), order[1], "Alınmış çeşit atlanır")
	assert_eq(ClipVariety.pick("father", "idle_loop", MALE, [order[0], order[1]]), order[2])
	assert_eq(ClipVariety.pick("father", "idle_loop", MALE, order), order[0], "Hepsi alınmışsa hash'li olan")


func test_weight_moves_the_start() -> void:
	# Ağırlık başlangıcı kaydırır: çok kişide ağırlığı yüksek çeşit daha sık başa gelir.
	var counts := {}
	for i in 400:
		var key: String = ClipVariety.pick_order("kisi_%d" % i, "walk", FEMALE, {"model": "mother"})[0]
		counts[key] = int(counts.get(key, 0)) + 1
	assert_true(int(counts.get("walk", 0)) > int(counts.get("thoughtful_walk", 0)), "Ağırlık 1 olan, 0,6 olandan sık: %s" % counts)
	assert_true(counts.size() >= 4, "Kişiler çeşitlere dağılır: %s" % counts)


func test_allocator_gives_different_clips_in_one_scene() -> void:
	var people := ["father", "crowd_hun_man", "teoman", "older_brother", "counter", "crowd_hun_rider"]
	var allocator := ClipVariety.Allocator.new()
	for id: String in people:
		allocator.register(id)
	for group: String in ["idle_loop", "walk", "run", "sit_ground"]:
		var seen := []
		for id: String in people:
			var key := allocator.key_for(id, group)
			# Havuz bittiyse (hepsi alınmış) tekrar kabul: o kişinin bütün uygun çeşitleri alınmış olmalı.
			if seen.has(key):
				var pool := ClipVariety.eligible(group, allocator.profile_for(id), {"model": ClipVariety.model_of(id)})
				for other: String in pool:
					assert_true(seen.has(other), "%s/%s: %s boştayken aynı klip" % [id, group, other])
			seen.append(key)
		assert_true(seen.size() > 1, "%s: atama yapıldı" % group)
	var idles := []
	for id: String in people:
		idles.append(allocator.key_for(id, "idle_loop"))
	var unique := {}
	for key: String in idles:
		unique[key] = true
	assert_eq(unique.size(), people.size(), "Altı kişi altı ayrı bekleme: %s" % [idles])


func test_allocator_order_is_stable() -> void:
	var run := func() -> Dictionary:
		var allocator := ClipVariety.Allocator.new()
		var out := {}
		for id: String in CAST:
			allocator.register(id)
		for id: String in CAST:
			for group: String in GROUPS:
				out["%s/%s" % [id, group]] = allocator.key_for(id, group)
		return out
	assert_eq(run.call(), run.call(), "Aynı sıra aynı atama")


func test_assign_reserves_a_clip() -> void:
	var allocator := ClipVariety.Allocator.new()
	allocator.assign("father", "sit_ground", "ground_warm_hands")
	assert_eq(allocator.key_for("father", "sit_ground"), "ground_warm_hands", "Elle seçim kalır")
	allocator.register("father")
	assert_eq(allocator.key_for("father", "sit_ground"), "ground_warm_hands", "Kayıt elle seçimi ezmez")
	allocator.register("crowd_hun_man")
	assert_ne(allocator.key_for("crowd_hun_man", "sit_ground"), "ground_warm_hands", "Başkasına verilmez")
	assert_true((allocator.taken["sit_ground"] as Array).has("ground_warm_hands"))
	assert_true(allocator.order.has("father") and allocator.order.has("crowd_hun_man"))


# --- Avatar ---------------------------------------------------------------------------------------------

func test_avatar_plays_the_assigned_clips_with_their_measures() -> void:
	var allocator := ClipVariety.Allocator.new()
	allocator.register("teoman")
	var avatar := _avatar("teoman", "teoman", allocator)
	await wait_frames(1)
	var lib := ClipVariety.library()
	assert_eq(avatar.variety_key(&"idle"), "idle_11", "Teoman'ın duruşu")
	assert_eq(avatar.variety_key(&"walk"), "proud_strut", "Teoman'ın yürüyüşü")
	assert_eq(avatar.get_current_role(), &"idle")
	assert_eq(avatar.clip_name(&"idle"), String(ClipVariety.clip_name("idle_11")))
	assert_eq(avatar.get_animation_player().assigned_animation, ClipVariety.clip_name("idle_11"), "Oynayan klip")
	assert_almost(avatar.ground_offset(&"idle"), lib.ground_offset_for("teoman", "idle_11"), 0.0001, "Zemin payı çeşidin ölçüsü")
	assert_almost(avatar.get_model_node().position.y, lib.ground_offset_for("teoman", "idle_11"), 0.0001, "Model o kadar kaymış")
	assert_almost(avatar.clip_speed(&"walk"), lib.speed_for("teoman", "proud_strut"), 0.0001, "Klip hızı çeşidin ölçüsü")
	avatar.set_locomotion(0.98)
	assert_eq(avatar.get_current_role(), &"walk")
	assert_eq(avatar.get_animation_player().assigned_animation, ClipVariety.clip_name("proud_strut"))
	assert_almost(avatar.get_animation_player().speed_scale, 0.98 / lib.speed_for("teoman", "proud_strut"), 0.001, "Oynatma hızı doğal hıza göre: ayak kaymaz")
	avatar.play_walk(1.3)
	assert_eq(avatar.get_current_role(), &"walk", "play_walk her hızda yürür")
	assert_almost(avatar.get_animation_player().speed_scale, 1.3 / lib.speed_for("teoman", "proud_strut"), 0.001)
	assert_false(avatar.is_processing(), "Ara hareket kapalıyken kare başına iş yok")


func test_unmeasured_model_scales_the_carrier_speed_by_hips() -> void:
	var avatar := _avatar("father")
	await wait_frames(1)
	var skel := avatar.get_skeleton()
	var lib := ClipVariety.library()
	assert_almost(ClipVariety.natural_speed("father", "casual_walk", skel), lib.speed_for("father", "casual_walk"), 0.0001, "Ölçülmüş model")
	var carrier := float(lib.measure("casual_walk").get("speed_mps", 0.0))
	assert_true(carrier > 0.1, "Taşıyıcının ölçüsü var")
	var ratio := ClipRetarget.hips_ratio(lib.donor_skeleton(), skel)
	assert_almost(ClipVariety.natural_speed("olculmemis_model", "casual_walk", skel), carrier * ratio, 0.0001, "Ölçülmemiş model kalça oranıyla")
	assert_almost(ClipVariety.natural_speed("olculmemis_model", "casual_walk"), carrier, 0.0001, "İskelet yoksa taşıyıcınınki")


func test_own_clip_needs_no_retarget_and_reads_the_measures() -> void:
	# Modelin o rolde zaten oynattığı klip atanırsa aktarım yapılmaz; hız <id>_fit.json'dan kalır, zemin payı ölçü dosyasındandır (ölçüsü
	# yoksa <id>_fit.json). Kişinin o klipte bacak düzeltmesi varsa kendi klibi sayılmaz: clip_for'dan düzeltilmiş kurulur.
	assert_true(ClipVariety.is_own_clip("elder", "sit", &"sit"), "Ozanın bağdaşı kendi klibi")
	assert_true(ClipVariety.is_own_clip("father", "walk", &"walk"))
	assert_false(ClipVariety.is_own_clip("father", "casual_walk", &"walk"))
	assert_false(ClipVariety.is_own_clip("elder", "sit", &"walk"))
	assert_eq(ClipVariety.own_key("father", &"walk"), "walk")
	assert_eq(ClipVariety.own_key("mete", &"idle"), "idle_4")
	assert_eq(ClipVariety.own_key("father", &"idle"), "", "Baba'nın bekleme klibi yok")
	assert_false(ClipVariety.library().leg_fit_for("father", "sit").is_empty(), "Baba'nın bağdaşı düzeltilir (kalça 6 cm havadaydı)")
	assert_false(ClipVariety.is_own_clip("father", "sit", &"sit"), "Düzeltilen klip kendi klibi sayılmaz")
	var seated := ClipVariety.Allocator.new()
	seated.assign("father", ClipVariety.GROUND_GROUP, "sit")
	var father := _avatar("father", "father", seated, &"sit")
	await wait_frames(1)
	assert_eq(father.variety_key(&"sit"), "sit", "clip_for'dan kurulur")
	var walker := _avatar("father")
	await wait_frames(1)
	assert_almost(walker.ground_offset(&"walk"), ClipVariety.library().ground_offset_for("father", "walk"), 0.0001, "Kendi yürüyüşünün payı ölçü dosyasından")
	var plain_seat := _avatar("father", "", null, &"sit")
	await wait_frames(1)
	assert_almost(plain_seat.ground_offset(&"sit"), CharacterAvatar.fit_value(CharacterAvatar._load_fit("father"), "ground_offset", &"sit", NAN), 0.0001, "Düzeltmesiz oynayan kendi klibi: ölçü düzeltilmiş klibin, pay kendi dosyasından")
	var allocator := ClipVariety.Allocator.new()
	allocator.assign("elder", ClipVariety.GROUND_GROUP, "sit")
	var avatar := _avatar("elder", "elder", allocator, &"sit")
	await wait_frames(1)
	assert_eq(avatar.variety_key(&"sit"), "", "Kendi klibinde")
	assert_ne(avatar.clip_name(&"sit"), String(ClipVariety.clip_name("sit")))
	assert_almost(avatar.ground_offset(&"sit"), CharacterAvatar.fit_value(CharacterAvatar._load_fit("elder"), "ground_offset", &"sit", NAN), 0.0001)


func test_pinned_roles_keep_their_own_clip() -> void:
	var avatar := CharacterAvatar.new()
	avatar.model_override = "mete"
	avatar.variety_person = "mete"
	avatar.pinned_roles = CharacterAvatar.PLAYER_PINNED
	add_child(avatar)
	_trash.append(avatar)
	await wait_frames(1)
	assert_eq(avatar.variety_key(&"walk"), "", "Oyuncunun yürüyüşü kendi klibinde")
	assert_eq(avatar.variety_key(&"run"), "", "Oyuncunun koşusu kendi klibinde")
	var plain := _avatar("mete")
	await wait_frames(1)
	assert_eq(avatar.clip_name(&"walk"), plain.clip_name(&"walk"), "Yürüme klibi aynı")
	assert_almost(avatar.clip_speed(&"run"), plain.clip_speed(&"run"), 0.0001, "Ölçüsü de")


func test_without_a_person_the_avatar_is_unchanged() -> void:
	var avatar := _avatar("father")
	await wait_frames(1)
	for role in CharacterAvatar.ROLES:
		assert_eq(avatar.variety_key(role), "", "%s çeşitsiz" % role)
	assert_false(avatar.clip_name(&"walk").begins_with(ClipVariety.CLIP_PREFIX))
	assert_null(avatar.variety_allocator)


func test_chibi_fallback_ignores_variety() -> void:
	var avatar := CharacterAvatar.new()
	avatar.use_meshy_models = false
	avatar.model_override = "father"
	avatar.variety_person = "father"
	avatar.auto_fidget = true
	add_child(avatar)
	_trash.append(avatar)
	await wait_frames(1)
	assert_false(avatar.has_meshy_model())
	assert_eq(avatar.variety_key(&"idle"), "")
	avatar.tick_fidget(100.0)
	assert_eq(avatar.fidget_key(), "", "Yedekte ara hareket yok")
	avatar.play_pose(&"sit")
	avatar.set_locomotion(1.0)


func test_two_people_on_one_model_do_not_share_clips() -> void:
	# İki Lan kadını aynı ağı gösterir: GLB'nin klip kütüphanesi paylaşılır, kişiler kendi kütüphanelerini alır. Oturuşlar doğum sahnesindeki gibidir,
	# elle verilir: hash'le modelin kendi oturuşu (sit) düşerse çeşit klibi kurulmaz, sınanan şey kalmaz.
	var allocator := ClipVariety.Allocator.new()
	allocator.assign("lan_woman_a", ClipVariety.GROUND_GROUP, "ground_warm_hands")
	allocator.assign("lan_woman_b", ClipVariety.GROUND_GROUP, PrologueBirth.SEAT_PICKS["LanWomanB"])
	allocator.register("lan_woman_a")
	allocator.register("lan_woman_b")
	var a := _avatar("crowd_hun_woman", "lan_woman_a", allocator, &"sit")
	var b := _avatar("crowd_hun_woman", "lan_woman_b", allocator, &"sit")
	var plain := _avatar("crowd_hun_woman")
	await wait_frames(1)
	assert_ne(a.variety_key(&"sit"), b.variety_key(&"sit"), "Farklı oturuş")
	assert_eq(a.get_animation_player().assigned_animation, ClipVariety.clip_name(a.variety_key(&"sit")))
	assert_eq(b.get_animation_player().assigned_animation, ClipVariety.clip_name(b.variety_key(&"sit")))
	assert_false(a.get_animation_player().has_animation(ClipVariety.clip_name(b.variety_key(&"sit"))), "Kişinin kütüphanesinde ötekinin klibi yok")
	var shared := plain.get_animation_player().get_animation_list()
	for clip in shared:
		assert_false(String(clip).begins_with(ClipVariety.CLIP_PREFIX), "Modelin ortak kütüphanesine çeşit karışmaz: %s" % clip)
	assert_ne(plain.get_animation_player().get_animation_library(&""), a.get_animation_player().get_animation_library(&""))
	assert_eq(a.get_animation_player().get_animation(ClipVariety.clip_name(a.variety_key(&"sit"))).loop_mode, Animation.LOOP_LINEAR, "Oturuş donmaz")


func test_seated_clip_loops_with_a_closed_seam() -> void:
	# Metinden hareketler tanımda bir kez oynar (8 sn): oturuşta son karede donmasın diye dikişi kapatılmış kopyası oynar; ortak klip değişmez.
	var avatar := _avatar("father")
	await wait_frames(1)
	var skel := avatar.get_skeleton()
	var once := ClipVariety.library().clip_for("father", "ground_warm_hands", skel)
	assert_eq(once.loop_mode, Animation.LOOP_NONE, "Ortak klip tanımdaki gibi")
	var loop := ClipVariety.role_clip("father", "ground_warm_hands", &"sit", skel)
	assert_eq(loop.loop_mode, Animation.LOOP_LINEAR, "Rol kopyası döngülü")
	assert_true(CharacterAvatar.is_cyclic(loop), "İlk ve son kare aynı")
	assert_true(ClipVariety.role_clip("father", "ground_warm_hands", &"sit", skel) == loop, "Kopya önbellekte")
	assert_eq(once.loop_mode, Animation.LOOP_NONE, "Ortak klibe dokunulmadı")
	assert_true(ClipVariety.role_clip("father", "casual_walk", &"walk", skel) == ClipVariety.library().clip_for("father", "casual_walk", skel), "Yürüyüş ortak klibin kendisi")


func test_arms_crossed_seat_holds_its_last_pose() -> void:
	# sit_arms_crossed'in ilk ve son karesi 107° ayrışır: dikişi kapatılsa kollar 2,4 sn'de bir açılıp kavuşurdu. Son pozunda durur.
	var avatar := _avatar("father")
	await wait_frames(1)
	var skel := avatar.get_skeleton()
	assert_true(float(ClipVariety.library().measure("sit_arms_crossed")["cycle_gap_deg"]) > ClipVariety.MAX_SEAT_SEAM_DEG, "Gerekçesi ölçüde")
	assert_eq(ClipVariety.role_clip("father", "sit_arms_crossed", &"sit", skel).loop_mode, Animation.LOOP_NONE, "Döngüye sokulmaz")
	assert_eq(ClipVariety.role_clip("father", "chair_sit_idle_f", &"sit", skel).loop_mode, Animation.LOOP_LINEAR, "Dikişi küçük olan döngüye girer")
	var allocator := ClipVariety.Allocator.new()
	allocator.assign("father", ClipVariety.SEAT_GROUP, "sit_arms_crossed")
	allocator.register("father", {}, {"seat": {"type": "chair"}})
	var seated := _avatar("father", "father", allocator, &"sit")
	await wait_frames(1)
	var player := seated.get_animation_player()
	assert_eq(player.assigned_animation, ClipVariety.clip_name("sit_arms_crossed"))
	assert_almost(player.current_animation_position, player.get_animation(player.assigned_animation).length, 0.05, "Sahne açılınca kolları kavuşuk")


func test_clips_start_at_a_phase_of_the_person() -> void:
	# Havuz bitince aynı klibi alan iki kişi aynı adımda salınmaz; evre her çalıştırmada aynıdır.
	var key := "idle_7"
	var make := func(person: String) -> CharacterAvatar:
		var allocator := ClipVariety.Allocator.new()
		allocator.assign(person, "idle_loop", key)
		return _avatar("crowd_hun_man", person, allocator)
	var a: CharacterAvatar = make.call("crowd_hun_man")
	var b: CharacterAvatar = make.call("lan_woman_a")
	var c: CharacterAvatar = make.call("crowd_hun_man")
	var length := ClipVariety.library().measure(key).get("duration", 0.0) as float
	assert_true(length > 1.0)
	assert_almost(a.get_animation_player().current_animation_position, ClipVariety.phase_of("crowd_hun_man") * length, 0.2, "Kişinin evresi")
	assert_almost(a.get_animation_player().current_animation_position, c.get_animation_player().current_animation_position, 0.0001, "Aynı kişi aynı evre")
	assert_true(absf(a.get_animation_player().current_animation_position - b.get_animation_player().current_animation_position) > 0.1, "Başka kişi başka evre")
	assert_ne(ClipVariety.phase_of("lan_woman_a"), ClipVariety.phase_of("lan_woman_b"))
	assert_between(ClipVariety.phase_of("teoman"), 0.0, 1.0)


func test_warm_builds_once_and_no_retarget_happens_in_a_frame() -> void:
	var lib := ClipVariety.library()
	var avatar := _avatar("crowd_hun_man", "crowd_hun_man", ClipVariety.Allocator.new())
	await wait_frames(1)
	avatar.warm_variety()
	var built := lib._clip_cache.size()
	for speed in [0.0, 1.2, 4.2, 0.0]:
		avatar.set_locomotion(speed)
	avatar.play_pose(&"sit")
	avatar.play_pose(&"idle")
	assert_eq(lib._clip_cache.size(), built, "Isıtılmış kişide oynatırken aktarım yok")
	avatar.warm_variety()
	assert_eq(lib._clip_cache.size(), built, "İkinci ısıtma iş yapmaz")
	var other := _avatar("crowd_hun_man", "crowd_hun_man", ClipVariety.Allocator.new())
	await wait_frames(1)
	other.warm_variety()
	assert_eq(lib._clip_cache.size(), built, "Aynı model ve aynı kişi: önbellekten")
	assert_eq(other.clip_name(&"idle"), avatar.clip_name(&"idle"))
	var anim_a := avatar.get_animation_player().get_animation(avatar.clip_name(&"idle"))
	var anim_b := other.get_animation_player().get_animation(other.clip_name(&"idle"))
	assert_true(anim_a == anim_b, "Klip kaynağı paylaşılır")


func test_start_pose_builds_only_what_it_plays() -> void:
	# Kurulum hafif kalsın: oturan kişi için yalnız oturuşu aktarılır; öteki roller ısıtınca ya da ilk oynarken.
	var lib := ClipVariety.library()
	var allocator := ClipVariety.Allocator.new()
	allocator.assign("hero_f", ClipVariety.GROUND_GROUP, "ground_one_knee")
	allocator.register("hero_f")
	var avatar := _avatar("hero_f", "hero_f", allocator, &"sit")
	await wait_frames(1)
	assert_true(lib._clip_cache.has("hero_f|ground_one_knee"), "Oturuş kuruldu")
	assert_eq(avatar.available_roles().size(), 4, "Dört rol de oynanabilir")
	assert_true(avatar.get_current_role() == &"sit")


# --- Ara hareket -----------------------------------------------------------------------------------------

func test_fidget_clock_is_seeded_by_person() -> void:
	var pool := ["a", "b", "c"]
	var first := ClipVariety.FidgetClock.new("teoman", pool)
	var again := ClipVariety.FidgetClock.new("teoman", pool)
	var other := ClipVariety.FidgetClock.new("counter", pool)
	var same_as_other := true
	var last := ""
	for i in 40:
		var wait := first.next_wait()
		var key := first.next_key()
		assert_almost(wait, again.next_wait(), 0.00001, "Aynı kişi aynı bekleme")
		assert_eq(key, again.next_key(), "Aynı kişi aynı klip")
		assert_between(wait, ClipVariety.FIDGET_WAIT.x, ClipVariety.FIDGET_WAIT.y, "8-20 sn")
		assert_ne(key, last, "Art arda aynısı değil")
		last = key
		if not is_equal_approx(wait, other.next_wait()):
			same_as_other = false
		other.next_key()
	assert_false(same_as_other, "Başka kişinin saati başka")
	var single := ClipVariety.FidgetClock.new("x", ["a"])
	assert_eq(single.next_key(), "a")
	assert_eq(single.next_key(), "a", "Havuz tek klipse o")
	assert_eq(ClipVariety.FidgetClock.new("x", []).next_key(), "", "Boş havuz")
	assert_eq(ClipVariety.FIDGET_WAIT, Vector2(8.0, 20.0))


func test_fidget_plays_while_idle_and_returns() -> void:
	var avatar := CharacterAvatar.new()
	avatar.model_override = "crowd_hun_man"
	avatar.variety_person = "crowd_hun_man"
	avatar.variety_allocator = ClipVariety.Allocator.new()
	avatar.auto_fidget = true
	add_child(avatar)
	_trash.append(avatar)
	assert_true(avatar.is_processing(), "Saat her kare işler")
	avatar.set_process(false) # saati sınama sürer: kare süreleri koşudan koşuya değişir
	await wait_frames(1)
	var player := avatar.get_animation_player()
	var idle := StringName(avatar.clip_name(&"idle"))
	assert_eq(player.assigned_animation, idle)
	# Beklerken ara hareket hemen oynamaz: süre tohumla belirlenir.
	var clock := ClipVariety.FidgetClock.new("crowd_hun_man", ClipVariety.fidget_pool(ClipVariety.profile_of("crowd_hun_man")))
	clock.next_wait() # saat kurulurken
	var wait := clock.next_wait() # rol beklemeye geçerken
	assert_between(wait, 8.0, 20.0)
	avatar.tick_fidget(wait - 0.01)
	assert_eq(avatar.fidget_key(), "", "Süre dolmadan yok")
	avatar.tick_fidget(0.02)
	var key := avatar.fidget_key()
	assert_false(key.is_empty(), "Süre dolunca oynar")
	assert_eq(key, clock.next_key(), "Zamanlama ve klip tohumdan: aynı kişi aynı sırayı oynar")
	assert_true(ClipVariety.fidget_pool(ClipVariety.profile_of("crowd_hun_man")).has(key), "Kişinin havuzundan")
	assert_eq(player.assigned_animation, ClipVariety.clip_name(key), "Ara hareketin klibi")
	assert_eq(avatar.get_current_role(), &"idle", "Rol bekleme kalır")
	avatar.set_locomotion(0.0)
	assert_eq(avatar.fidget_key(), key, "Her kare gelen bekleme isteği ara hareketi kesmez")
	assert_almost(player.speed_scale, 1.0, 0.001)
	# Bitince beklemeye döner, sonraki kez başka klip.
	player.advance(player.get_animation(player.assigned_animation).length + 0.1)
	await wait_frames(1)
	assert_eq(avatar.fidget_key(), "", "Bitti")
	assert_eq(player.assigned_animation, idle, "Beklemeye döndü")
	avatar.tick_fidget(21.0)
	assert_ne(avatar.fidget_key(), key, "Art arda aynısı değil")
	# Yürümeye geçince kesilir, yürürken saat işlemez.
	avatar.set_locomotion(1.2)
	assert_eq(avatar.fidget_key(), "", "Yürümek ara hareketi keser")
	assert_eq(avatar.get_current_role(), &"walk")
	avatar.tick_fidget(100.0)
	assert_eq(avatar.fidget_key(), "", "Yürürken ara hareket yok")
	avatar.play_pose(&"sit")
	avatar.tick_fidget(100.0)
	assert_eq(avatar.fidget_key(), "", "Otururken ara hareket yok")


func test_fidget_clips_are_warm_and_offset_follows() -> void:
	var lib := ClipVariety.library()
	var avatar := CharacterAvatar.new()
	avatar.model_override = "older_brother"
	avatar.auto_fidget = true
	avatar.variety_person = "older_brother"
	add_child(avatar)
	_trash.append(avatar)
	await wait_frames(1)
	var pool := ClipVariety.fidget_pool(ClipVariety.profile_of("older_brother"))
	assert_true(pool.has("alert"), "Savaşçının ara hareketi")
	var player := avatar.get_animation_player()
	for key: String in pool:
		assert_true(player.has_animation(ClipVariety.clip_name(key)), "%s önceden kuruldu" % key)
		assert_eq(player.get_animation(ClipVariety.clip_name(key)).loop_mode, Animation.LOOP_NONE, "%s bir kez oynar" % key)
	var built := lib._clip_cache.size()
	avatar.tick_fidget(100.0)
	assert_eq(lib._clip_cache.size(), built, "Kare içinde aktarım yok")
	await get_tree().create_timer(CharacterAvatar.BLEND_TIME + 0.1).timeout
	assert_almost(avatar.get_model_node().position.y, lib.ground_offset_for("older_brother", avatar.fidget_key()), 0.002, "Zemin payı ara hareketin ölçüsü")


func test_fidget_works_without_variety_for_a_player() -> void:
	var avatar := CharacterAvatar.new()
	avatar.model_override = "mete"
	avatar.auto_fidget = true
	add_child(avatar)
	_trash.append(avatar)
	await wait_frames(1)
	assert_eq(avatar.variety_key(&"idle"), "", "Çeşitlilik kapalı")
	avatar.tick_fidget(100.0)
	assert_false(avatar.fidget_key().is_empty(), "Ara hareket yine oynar")
	avatar.auto_fidget = false
	assert_false(avatar.is_processing(), "Kapatınca saat durur")


func test_fidget_turned_on_at_runtime_keeps_the_clip_playing() -> void:
	# Saat açılınca oynatıcı kendi kütüphanesine geçer: oynayan klip düşmez, kaldığı yerden sürer.
	var avatar := _avatar("teoman")
	await wait_frames(1)
	var player := avatar.get_animation_player()
	var clip := player.assigned_animation
	player.seek(1.0, true)
	avatar.auto_fidget = true
	assert_true(player.is_playing(), "Klip sürer")
	assert_eq(player.assigned_animation, clip)
	assert_almost(player.current_animation_position, 1.0, 0.05, "Kaldığı yerden")
	assert_true(avatar.is_processing())
	avatar.tick_fidget(100.0)
	assert_false(avatar.fidget_key().is_empty())
	# Modelin ortak kütüphanesi temiz kalır.
	var plain := _avatar("teoman")
	await wait_frames(1)
	for name in plain.get_animation_player().get_animation_list():
		assert_false(String(name).begins_with(ClipVariety.CLIP_PREFIX), "%s ortak kütüphaneye karışmadı" % name)


func test_cinema_has_no_fidgets() -> void:
	var holder := Node3D.new()
	add_child(holder)
	_trash.append(holder)
	var actor := CineActor.new()
	actor.character_id = "counter"
	actor.build_on_ready = false
	holder.add_child(actor)
	actor.build()
	await wait_frames(1)
	assert_false(actor.avatar.auto_fidget, "Sinemada kapalı")
	assert_false(actor.avatar.is_processing(), "Kare başına iş yok")
	assert_null(actor.avatar._fidget_clock, "Saat kurulmaz")
	actor.avatar.tick_fidget(100.0)
	assert_eq(actor.avatar.fidget_key(), "", "Çekim belirlenimci kalır")


# --- CineActor -------------------------------------------------------------------------------------------

func test_actors_of_a_scene_share_one_allocator_in_scene_order() -> void:
	var build_order := func(order: Array) -> Dictionary:
		var holder := Node3D.new()
		add_child(holder)
		_trash.append(holder)
		var actors := {}
		for id: String in ["lan_woman_a", "lan_woman_b", "crowd_hun_woman"]:
			var actor := CineActor.new()
			actor.character_id = id
			actor.build_on_ready = false
			holder.add_child(actor)
			actors[id] = actor
		var out := {}
		for id: String in order:
			(actors[id] as CineActor).pose = &"sit"
			(actors[id] as CineActor).build()
		for id: String in order:
			out[id] = (actors[id] as CineActor).avatar.variety_key(&"sit")
		return out
	var forward: Dictionary = build_order.call(["lan_woman_a", "lan_woman_b", "crowd_hun_woman"])
	var backward: Dictionary = build_order.call(["crowd_hun_woman", "lan_woman_b", "lan_woman_a"])
	assert_eq(forward, backward, "Atama kurulum sırasına bağlı değil: sahnedeki sıra sayılır")
	assert_ne(forward["lan_woman_a"], forward["lan_woman_b"], "İki kadın farklı oturur")
	assert_ne(forward["lan_woman_b"], forward["crowd_hun_woman"])


func test_actor_with_reach_turns_keeps_its_seat() -> void:
	# Kol dönüşleri o pozun üstüne ayarlıdır.
	var holder := Node3D.new()
	add_child(holder)
	_trash.append(holder)
	var actor := CineActor.new()
	actor.character_id = "lan_hatun"
	actor.build_on_ready = false
	actor.pose = &"sit"
	actor.reach_turns = [["RightArm", "forward", -105.0]]
	holder.add_child(actor)
	var other := CineActor.new()
	other.character_id = "lan_woman_a"
	other.build_on_ready = false
	holder.add_child(other)
	actor.build()
	await wait_frames(1)
	assert_eq(actor.avatar.variety_key(&"sit"), "", "Oturuş kendi klibinde")
	assert_true(actor.avatar.pinned_roles.has(&"sit"))
	assert_false(actor.avatar.variety_key(&"idle").is_empty(), "Öteki rolleri çeşitli")
	var allocator: ClipVariety.Allocator = holder.get_meta(ClipVariety.ALLOCATOR_META)
	assert_true((allocator.taken[ClipVariety.GROUND_GROUP] as Array).has("sit"), "Bağdaşı başkasına verilmez")


func test_ensure_idle_warms_without_a_second_transfer() -> void:
	var lib := ClipVariety.library()
	var holder := Node3D.new()
	add_child(holder)
	_trash.append(holder)
	var actor := CineActor.new()
	actor.character_id = "crowd_hun_rider"
	actor.build_on_ready = false
	holder.add_child(actor)
	actor.build()
	await wait_frames(1)
	actor.ensure_idle()
	var built := lib._clip_cache.size()
	actor.pose = &"walk"
	assert_eq(actor.avatar.get_current_role(), &"walk")
	actor.pose = &"idle"
	assert_eq(actor.avatar.get_current_role(), &"idle")
	assert_eq(lib._clip_cache.size(), built, "Kesmede ısıtılan kişide çekim içinde aktarım yok")
	assert_true(actor.avatar.get_animation_player().has_animation(actor.avatar.clip_name(&"walk")))
	assert_false((CineActor as Script).get_script_constant_map().has("IDLE_DONOR"), "Bağışçı tek kaynaktan: ClipLibrary.donor_for")
	# Çeşit ve kendi klibi olmayan model için yedek: bağışçıyı kütüphane seçer.
	assert_false(lib.donor_for(ClipVariety.FALLBACK_IDLE, "father").is_empty())


# --- İlk kare ve model değişimi (kök neden) ------------------------------------------------------------------

func test_avatar_without_an_idle_clip_is_never_in_t_pose() -> void:
	# Ana, Baba, Çocuk ve Ozan'ın bekleme klibi yok; Ansiklopedi'nin görünümü onları çeşitliliksiz, bekleme pozuyla kurar.
	for id: String in ["father", "mother", "child", "elder"]:
		var avatar := _avatar(id)
		assert_false(avatar.available_roles().has(&"idle"), "%s: bekleme klibi yok" % id)
		assert_eq(avatar.get_current_role(), &"sit", "%s elindeki klibi oynar" % id)
		var player := avatar.get_animation_player()
		assert_true(player.is_playing(), "%s oynuyor" % id)
		await wait_frames(1)
		var skel := avatar.get_skeleton()
		var farthest := 0.0
		for bone in skel.get_bone_count():
			farthest = maxf(farthest, skel.get_bone_rest(bone).basis.get_rotation_quaternion().normalized().angle_to(skel.get_bone_pose_rotation(bone).normalized()))
		assert_true(rad_to_deg(farthest) > 10.0, "%s dinlenme pozunda değil (%.1f°)" % [id, rad_to_deg(farthest)])
	var mete := _avatar("mete")
	assert_eq(mete.get_current_role(), &"idle", "Bekleme klibi olan bekler")


func test_encyclopedia_view_shows_people_without_an_idle_clip_in_a_pose() -> void:
	var threaded := EncyclopediaPage.threaded_loads
	EncyclopediaPage.threaded_loads = false
	var view := EncyclopediaModelView.new("father")
	add_child(view)
	_trash.append(view)
	await wait_frames(2)
	assert_not_null(view.get_avatar(), "Görünüm modeli kurar")
	if view.get_avatar():
		assert_false(view.get_avatar().get_current_role().is_empty(), "T-pozda kalmaz")
		assert_true(view.get_avatar().get_animation_player().is_playing())
	EncyclopediaPage.threaded_loads = threaded



func test_model_change_keeps_the_pose_playing() -> void:
	var avatar := _avatar("father", "", null, &"sit")
	await wait_frames(1)
	assert_eq(avatar.get_current_role(), &"sit")
	avatar.model_override = "older_brother"
	assert_eq(avatar.model_id, "older_brother")
	assert_eq(avatar.get_current_role(), &"sit", "Değişimden sonra son poz yeniden oynar: T-poz yok")
	assert_true(avatar.get_animation_player().is_playing())
	await wait_frames(1)
	avatar.play_pose(&"idle")
	avatar.model_override = "teoman"
	assert_eq(avatar.get_current_role(), &"idle", "Son poz")
	avatar.set_locomotion(1.0)
	assert_eq(avatar.get_current_role(), &"walk")
	avatar.model_override = "father"
	assert_eq(avatar.get_current_role(), &"walk", "Son hareket")
	# Yeni modelde o rol yoksa (Baba'nın bekleme klibi yok) kişi T-pozda kalmaz: elindeki bir klibi oynar.
	avatar.set_locomotion(0.0)
	assert_eq(avatar.get_current_role(), &"walk", "Oynayan rol sürer")
	avatar.play_pose(&"idle")
	assert_false(avatar.available_roles().has(&"idle"))
	avatar.model_override = "mother"
	assert_eq(avatar.model_id, "mother")
	assert_eq(avatar.get_current_role(), &"sit", "Rolü olmayan modelde oturur")


func test_model_change_replays_the_start_pose_if_nothing_was_asked() -> void:
	var avatar := CharacterAvatar.new()
	avatar.use_meshy_models = false
	avatar.start_pose = &"sit"
	add_child(avatar)
	_trash.append(avatar)
	await wait_frames(1)
	avatar.use_meshy_models = true
	avatar.model_override = "father"
	assert_true(avatar.has_meshy_model())
	assert_eq(avatar.get_current_role(), &"sit", "Başlangıç pozu")


func test_model_change_in_the_first_frame_leaves_no_engine_error() -> void:
	# Kök neden: aynı karede kurulup değişen modelin malzemesi, örneği çizim sunucusunda işlenmeden düşerse sunucu silinmiş
	# malzemenin örnek parametrelerini okur. Ağ başka bir kişide yaşarken görülür. Hata olursa koşucu bu sınamayı düşürür.
	# Önce önceki sınamaların silinecekleri düşsün: onların silinişi sunucuyu erkenden işletir, hata gizlenir.
	await wait_frames(1)
	var keeper := _avatar("father")
	var avatar := _avatar("father", "", null, &"sit")
	avatar.model_override = "older_brother"
	assert_eq(avatar.get_current_role(), &"sit")
	await wait_frames(2)
	assert_eq(avatar.get_current_role(), &"sit", "Oturuş sürer")
	assert_true(keeper.has_meshy_model())


func test_avatar_freed_in_its_first_frame_leaves_no_engine_error() -> void:
	# Avatarın kendisi silinirken _materials sona kadar yaşar: örnek malzemeden önce düşer.
	await wait_frames(1)
	var keeper := _avatar("father")
	var avatar := _avatar("father")
	avatar.queue_free()
	await wait_frames(2)
	assert_true(keeper.has_meshy_model())


func test_camp_with_a_stale_scene_model_resolves_before_loading() -> void:
	# Sahnede eski yer tutucu kalsa da kişi modeli yüklenmeden çözülür: iki kez yükleme ve hata yok, oturuş yerinde.
	var npcs := NPC_SCENE.instantiate() as CampNpcs
	var brother := npcs.get_node(^"OlderBrother") as CharacterAvatar
	brother.model_override = "father"
	var loads := []
	brother.model_changed.connect(func(id: String) -> void: loads.append(id))
	add_child(npcs)
	_trash.append(npcs)
	await wait_frames(2)
	assert_eq(brother.model_id, "older_brother")
	assert_eq(loads, ["older_brother"], "Bir kez yüklenir")
	assert_eq(brother.get_current_role(), &"sit", "T-pozda kalmaz")
	assert_eq(brother.variety_key(&"sit"), CampNpcs.SEATS["OlderBrother"])


func test_camp_person_turned_stand_in_at_runtime_keeps_sitting() -> void:
	# Modeli olmayan kişi çalışırken yer tutucuya döner (glb silinmiş ya da kişi değişmiş): hata yok, çarpan uygulanır, oturur.
	var npcs := NPC_SCENE.instantiate() as CampNpcs
	add_child(npcs)
	_trash.append(npcs)
	await wait_frames(2)
	var brother := npcs.get_node(^"OlderBrother") as CharacterAvatar
	npcs.stand_ins = {"OlderBrother": "lan_woman_a"}
	npcs.resolve_stand_ins()
	assert_eq(brother.model_id, "crowd_hun_woman", "Yer tutucunun modeli")
	assert_eq(brother.get_current_role(), &"sit", "Oturmaya devam eder")
	assert_false(StandIn.own_materials(brother).is_empty(), "Malzemeler yeni modelde")
	assert_almost(brother.model_scale, float(StandIn.resolve("lan_woman_a")["scale"]), 0.0001, "Çarpan ve ölçek yeniden uygulanır")
	await wait_frames(2)
	assert_eq(brother.get_current_role(), &"sit")


func test_set_variety_at_runtime_replaces_the_clips() -> void:
	var avatar := _avatar("father", "", null, &"sit")
	await wait_frames(1)
	var own := avatar.clip_name(&"sit")
	var allocator := ClipVariety.Allocator.new()
	allocator.assign("father", ClipVariety.GROUND_GROUP, "ground_warm_hands")
	avatar.set_variety("father", allocator)
	assert_eq(avatar.variety_key(&"sit"), "ground_warm_hands")
	assert_eq(avatar.get_animation_player().assigned_animation, ClipVariety.clip_name("ground_warm_hands"), "Hemen oynar")
	avatar.set_variety("")
	assert_eq(avatar.variety_key(&"sit"), "", "Kapatınca")
	assert_eq(avatar.clip_name(&"sit"), own, "Kendi klibine döner")
	assert_eq(avatar.get_current_role(), &"sit")
