extends TestCase
## Ateş başındaki karakterler (CampNpcs, scenes/world/camp_npcs.tscn) için testler.
##
## Ocak halkı Göl Obası'nın ocağıdır (K37, K106): Ana, Çocuk, Baba, Ağabey ve Ozan; Mete yoktur. Ağabey kendi Meshy modeliyle
## oturur (E7.6; StandIn modeli kimlikten çözer, K89'un yer tutucusu kalktı). Ozanın kucağında kopuz vardır (Meshy modeli;
## modeller kapalıyken kodla çizim). Sahne testleri hız için Meshy modellerini yüklemez (chibi yedeği); yerleşim, ateşe dönme, gizleme ve
## eşyalar model olmadan da aynı çalışır. Modellerin ölçüm dosyaları (<id>_fit.json) ayrıca denetlenir.
## Oturuşlar elle seçilmiştir (CampNpcs.SEATS, ClipVariety): beş kişinin beş ayrı duruşu; ozan kopuzlu bağdaşını korur, çocuk alçak
## kütükte oturur, Ana topukları üstünde diz çöker, ötekilerin bedeni zemindedir (kalça boşluğu), ayaklar taş halkaya girmez, kimse birbirine
## girmez. Bu sınamalar gerçek modellerle koşar.

const NPC_SCENE := preload("res://scenes/world/camp_npcs.tscn")
## Ateşin başındaki karakterler: düğüm adı → gösterilen model.
const EXPECTED := {"Mother": "mother", "Child": "child", "Father": "father", "OlderBrother": "older_brother", "Elder": "elder"}
## Düğüm adı → kişinin kimliği (story.md §8).
const PERSONS := {"Mother": "mother", "Child": "child", "Father": "father", "OlderBrother": "older_brother", "Elder": "elder"}
## test_world_scene ile aynı sınırlar: karakterler ateşin içinde değil, çevresinde oturur.
const MIN_FIRE_DISTANCE := 1.5
const MAX_FIRE_DISTANCE := 4.0
## İki oturan karakterin merkezleri arasındaki en küçük uzaklık (metre; iç içe geçmesinler).
const MIN_NEIGHBOR_DISTANCE := 0.6

var npcs: CampNpcs


func before_each() -> void:
	npcs = NPC_SCENE.instantiate() as CampNpcs
	for avatar in npcs.get_avatars():
		avatar.use_meshy_models = false
	add_child(npcs)


func after_each() -> void:
	if is_instance_valid(npcs):
		npcs.queue_free()
	npcs = null


# --- Saf yardımcılar ------------------------------------------------------------------

func test_facing_yaw_points_plus_z_at_target() -> void:
	for from in [Vector3(0.0, 0.0, 2.0), Vector3(2.0, 0.0, 0.0), Vector3(-1.5, 0.0, -0.8), Vector3(0.9, 0.3, -1.3)]:
		var yaw := CampNpcs.facing_yaw(from, Vector3.ZERO)
		var forward := Basis(Vector3.UP, yaw) * Vector3.BACK
		var want := Vector3(-from.x, 0.0, -from.z).normalized()
		assert_vec_almost(forward, want, 0.0001, "+Z yüzü hedefe bakmalı (%s)" % from)
	assert_true(is_nan(CampNpcs.facing_yaw(Vector3(1.0, 0.0, 1.0), Vector3(1.0, 5.0, 1.0))), "Üst üste noktada yön tanımsız")


func test_visibility_helper() -> void:
	assert_true(CampNpcs.is_visible_for("child", ""), "Gizlenen yoksa herkes görünür")
	assert_false(CampNpcs.is_visible_for("child", "child"))
	assert_true(CampNpcs.is_visible_for("father", "child"))


# --- Sahne ------------------------------------------------------------------------------

func test_scene_has_the_five_campfire_characters() -> void:
	var avatars := npcs.get_avatars()
	assert_eq(avatars.size(), EXPECTED.size(), "Ateşin başında beş karakter olmalı")
	for name in EXPECTED:
		var avatar := npcs.get_node_or_null(NodePath(name)) as CharacterAvatar
		assert_not_null(avatar, "Eksik karakter: %s" % name)
		if avatar:
			assert_eq(avatar.model_override, EXPECTED[name], "%s modeli" % name)
			assert_eq(avatar.start_pose, &"sit", "%s oturmalı" % name)
			assert_eq(avatar.model_id, EXPECTED[name])
			assert_eq(CampNpcs.person_id(avatar), PERSONS[name], "%s kişisi" % name)


func test_mete_is_not_at_the_hearth() -> void:
	# Ana kamp Göl Obası'dır; Mete orada yoktur (K37, K106): mete.glb kamptan çıktı.
	for avatar in npcs.get_avatars():
		assert_ne(avatar.model_override, "mete", "%s Mete olmamalı" % avatar.name)
		assert_ne(avatar.model_id, "mete")
		assert_ne(CampNpcs.person_id(avatar), "mete")
	assert_null(npcs.get_node_or_null(^"Warrior"), "Eski Warrior düğümü kalkmalı")
	assert_null(npcs.get_avatar_for_model("mete"))


func test_older_brother_shows_his_own_model() -> void:
	var brother := npcs.get_node_or_null(^"OlderBrother") as CharacterAvatar
	assert_not_null(brother)
	if brother == null:
		return
	assert_true(StandIn.has_model("older_brother"), "Ağabey'in Meshy modeli geldi (E7.6)")
	assert_eq(npcs.stand_ins.get("OlderBrother"), "older_brother", "Düğüm kişinin kimliğini taşır")
	var r: Dictionary = npcs.resolved.get("OlderBrother", {})
	assert_false(r.is_empty(), "Kimlik _ready'de çözülmeli")
	assert_false(bool(r.get("stand_in", true)), "Kendi modeli varken yer tutucu kalkar")
	assert_eq(r.get("model"), "older_brother")
	assert_eq(brother.model_override, "older_brother", "Sahnedeki eski yer tutucu modeli (father) kimliğe döner")
	assert_almost(brother.model_scale, 1.0, 0.0001, "Kendi modeli kendi boyunda")
	assert_eq(brother.get_meta(StandIn.PERSON_META, ""), "older_brother")
	assert_eq(npcs.get_avatar_for_person("older_brother"), brother)


func test_older_brother_real_model_sits_at_the_fire() -> void:
	# Öteki sahne testleri chibi yedeğiyle koşar; burada sahnenin kendisi gerçek modellerle: Ağabey kendi modeliyle oturma
	# rolünde açılır (T-pozda kalmaz), oturma ve bekleme klipleri bağışçılardan aktarılmış, boyu 1,75 m.
	var real := NPC_SCENE.instantiate() as CampNpcs
	add_child(real)
	await wait_frames(2)
	var brother := real.get_node(^"OlderBrother") as CharacterAvatar
	assert_true(brother.has_meshy_model(), "Ağabey'in Meshy modeli yüklenmeli")
	assert_eq(brother.model_id, "older_brother", "Kendi modeli")
	for role in CharacterAvatar.ROLES:
		assert_true(brother.available_roles().has(role), "%s klibi" % role)
	assert_eq(brother.get_current_role(), &"sit", "Ateş başında oturur")
	assert_almost(brother.get_model_height(), 1.75, 0.01, "Boyu meta.json'daki gibi")
	real.queue_free()


func test_characters_use_real_scale() -> void:
	# Modeller gerçek boyludur; düğüm ölçeği 1 kalmalı (eski chibi modeller 1.7 kat büyütülüyordu). Yer tutucu olsaydı
	# modeli kendi ölçeğinde olurdu (StandIn.resolve).
	for avatar in npcs.get_avatars():
		assert_vec_almost(avatar.scale, Vector3.ONE, 0.0001, "%s ölçeği 1 olmalı" % avatar.name)
		var key := String(avatar.name)
		var want := float(StandIn.resolve(PERSONS[key])["scale"]) if npcs.stand_ins.has(key) else 1.0
		assert_almost(avatar.model_scale, want, 0.0001, "%s model ölçeği" % avatar.name)


func test_characters_sit_around_the_fire_and_face_it() -> void:
	for avatar in npcs.get_avatars():
		var d := Vector2(avatar.position.x, avatar.position.z).length()
		assert_between(d, MIN_FIRE_DISTANCE, MAX_FIRE_DISTANCE, "%s ateşe uzaklığı" % avatar.name)
		assert_almost(avatar.position.y, 0.0, 0.0001, "%s zeminde" % avatar.name)
		var forward := avatar.transform.basis.z.normalized()
		var to_fire := Vector3(-avatar.position.x, 0.0, -avatar.position.z).normalized()
		assert_vec_almost(forward, to_fire, 0.01, "%s yüzünü ateşe çevirmeli" % avatar.name)
		assert_true(avatar.auto_face, "%s auto_face açık olmalı" % avatar.name)
		assert_vec_almost(avatar.face_point, npcs.global_position, 0.001)


func test_characters_keep_facing_when_node_moves() -> void:
	npcs.position = Vector3(3.0, 0.0, -2.0)
	npcs.rotation.y = 0.7
	# Dönüşüm bildirimi kare sonunda gelir.
	await wait_frames(2)
	for avatar in npcs.get_avatars():
		var forward := avatar.global_transform.basis.z.normalized()
		var to_fire := (npcs.global_position - avatar.global_position) * Vector3(1.0, 0.0, 1.0)
		assert_vec_almost(forward, to_fire.normalized(), 0.01, "%s taşınınca da ateşe bakmalı" % avatar.name)
		assert_vec_almost(avatar.face_point, npcs.global_position, 0.001)


func test_seated_characters_do_not_overlap() -> void:
	var avatars := npcs.get_avatars()
	for i in avatars.size():
		for j in range(i + 1, avatars.size()):
			var a := Vector2(avatars[i].position.x, avatars[i].position.z)
			var b := Vector2(avatars[j].position.x, avatars[j].position.z)
			assert_true(a.distance_to(b) >= MIN_NEIGHBOR_DISTANCE, "%s ile %s çok yakın (%.2f m)" % [avatars[i].name, avatars[j].name, a.distance_to(b)])


func test_child_sits_in_front_of_her_mother() -> void:
	# Menü referansındaki gibi çocuk annesinin hemen önünde (ateş tarafında), biraz sağında oturur.
	var mother := npcs.get_node(^"Mother") as Node3D
	var child := npcs.get_node(^"Child") as Node3D
	var local := mother.transform.affine_inverse() * child.position
	assert_between(local.z, 0.45, 0.8, "Çocuk annenin önünde olmalı (%.2f m)" % local.z)
	assert_between(-local.x, 0.0, 0.35, "Çocuk annenin hafif sağında olmalı (%.2f m)" % -local.x)


func test_set_hidden_model_hides_only_that_character() -> void:
	npcs.set_hidden_model("child")
	for avatar in npcs.get_avatars():
		assert_eq(avatar.visible, avatar.name != "Child", "%s görünürlüğü" % avatar.name)
	assert_eq(npcs.hidden_model, "child")
	npcs.set_hidden_model("elder")
	assert_true((npcs.get_node(^"Child") as Node3D).visible, "Başka model gizlenince Çocuk geri gelmeli")
	assert_false((npcs.get_node(^"Elder") as Node3D).visible)
	npcs.set_hidden_model("")
	for avatar in npcs.get_avatars():
		assert_true(avatar.visible, "Boş kimlik herkesi göstermeli (%s)" % avatar.name)
	for id in ["mete", "hero_f", "yok_boyle_model"]:
		npcs.set_hidden_model(id)
		for avatar in npcs.get_avatars():
			assert_true(avatar.visible, "Oyuncunun modeli (%s) ateş başında yok: kimse gizlenmemeli" % id)


func test_hidden_model_set_before_ready_is_applied() -> void:
	var other := NPC_SCENE.instantiate() as CampNpcs
	for avatar in other.get_avatars():
		avatar.use_meshy_models = false
	other.set_hidden_model("child")
	add_child(other)
	assert_false((other.get_node(^"Child") as Node3D).visible, "Ağaca girmeden verilen gizleme de uygulanmalı")
	assert_true((other.get_node(^"Mother") as Node3D).visible)
	other.queue_free()


func test_avatar_lookup_by_model_and_person() -> void:
	assert_eq(npcs.get_avatar_for_model("elder"), npcs.get_node(^"Elder"))
	assert_eq(npcs.get_avatar_for_model("father"), npcs.get_node(^"Father"), "İlk Baba modelli karakter Baba'dır")
	assert_eq(npcs.get_avatar_for_person("older_brother"), npcs.get_node(^"OlderBrother"))
	assert_eq(npcs.get_avatar_for_person("father"), npcs.get_node(^"Father"))
	assert_null(npcs.get_avatar_for_model("hero_f"))
	assert_eq(npcs.get_bard(), npcs.get_node(^"Elder"))


func test_props_belong_to_their_characters() -> void:
	# Kopuz ozanın kucağında, yay Ağabey'in yanında: karakterle döner, onunla gizlenir.
	var kopuz := npcs.get_node_or_null(^"Elder/Kopuz") as Kopuz
	var bow := npcs.get_node_or_null(^"OlderBrother/Bow") as MeshyProp
	assert_not_null(kopuz, "Kopuz ozanın alt düğümü olmalı")
	assert_not_null(bow, "Yay Ağabey'in alt düğümü olmalı")
	assert_null(npcs.get_node_or_null(^"Elder/Dombra"), "Dombra kamptan çıktı (K60)")
	if kopuz == null or bow == null:
		return
	assert_eq(npcs.get_kopuz(), kopuz)
	assert_eq(bow.model_id, "bow")
	assert_almost(bow.target_size, 1.3, 0.001, "Yay gerçek boyunda (asset_plan: 1.3 m)")
	# Kopuz kucakta: kalça hizasında ve karakterin önünde (ateş tarafında); yay yerde.
	assert_between(kopuz.position.y, 0.1, 0.5, "Kopuz kucak yüksekliğinde")
	assert_true(kopuz.position.z > 0.0, "Kopuz karakterin önünde (ateş tarafında)")
	assert_between(bow.position.y, 0.0, 0.1, "Yay yerde yatmalı")
	# Çalış pozu: sap sola (+X) ve yukarı, kucaktakinden dik; gövde yine önde.
	var rest_neck := kopuz.rest_transform.basis.y.normalized()
	var play_neck := kopuz.play_transform.basis.y.normalized()
	assert_true(play_neck.x > 0.3 and play_neck.y > rest_neck.y + 0.1, "Çalışta sap sola-yukarı kalkar (%s)" % play_neck)
	assert_between(kopuz.play_transform.origin.y, 0.1, 0.5, "Çalış pozu da kucak yüksekliğinde")
	assert_true(kopuz.play_transform.origin.z > 0.0)
	npcs.set_hidden_model("elder")
	assert_false(kopuz.is_visible_in_tree(), "Ozan gizlenince kopuz da gizlenmeli")


# --- Oturuşlar (gerçek modeller) -----------------------------------------------------------

func test_seats_are_hand_picked_and_distinct() -> void:
	var lib := ClipVariety.library()
	var seen := {}
	assert_eq(CampNpcs.SEATS.size(), EXPECTED.size(), "Beş kişinin beş oturuşu")
	for node_name: String in CampNpcs.SEATS:
		assert_true(EXPECTED.has(node_name), "%s ateş başında" % node_name)
		var key: String = CampNpcs.SEATS[node_name]
		var spec := lib.variant(key)
		assert_eq(spec.get("group"), ClipVariety.GROUND_GROUP, "%s yerde oturur" % node_name)
		assert_false(seen.has(key), "%s başkasının oturuşu" % key)
		seen[key] = true
		var profile := ClipVariety.profile_of(PERSONS[node_name])
		var tags: Dictionary = spec.get("tags", {})
		assert_true((tags.get("body", []) as Array).has(profile["body"]), "%s bedene uyar" % key)
		assert_true((tags.get("age", []) as Array).has(profile["age"]), "%s yaşa uyar" % key)
	assert_eq(CampNpcs.SEATS["Elder"], "sit", "Ozan bağdaşını korur: kopuz bu poza ayarlı")


func test_real_models_play_their_seats_on_the_ground() -> void:
	var real := NPC_SCENE.instantiate() as CampNpcs
	add_child(real)
	await wait_frames(2)
	var lib := ClipVariety.library()
	for avatar in real.get_avatars():
		var node_name := String(avatar.name)
		var key: String = CampNpcs.SEATS[node_name]
		var player := avatar.get_animation_player()
		assert_eq(avatar.get_current_role(), &"sit", "%s oturur" % node_name)
		if node_name == "Elder":
			assert_eq(avatar.variety_key(&"sit"), "", "Ozan kendi klibinde")
			assert_false(String(player.assigned_animation).begins_with(ClipVariety.CLIP_PREFIX))
			assert_almost(avatar.get_model_node().position.y, CharacterAvatar.fit_value(CharacterAvatar._load_fit("elder"), "ground_offset", &"sit", NAN), 0.0001, "Zemin payı eski ölçü")
			continue
		assert_eq(avatar.variety_key(&"sit"), key, "%s atanan oturuşta" % node_name)
		assert_eq(player.assigned_animation, ClipVariety.clip_name(key), "%s klibi oynar" % node_name)
		assert_eq(player.get_animation(player.assigned_animation).loop_mode, Animation.LOOP_LINEAR, "%s donmaz" % node_name)
		assert_almost(avatar.get_model_node().position.y, lib.ground_offset_for(avatar.model_id, key), 0.0001, "%s zeminde" % node_name)
		var contact := lib.contact_for(key)
		var lowest := INF
		var seat := INF
		for i in 5:
			player.seek(player.get_animation(player.assigned_animation).length * i / 4.0, true)
			lowest = minf(lowest, PoseFit.skinned_min_y(avatar.get_model_node(), contact) + avatar.get_model_node().position.y)
			seat = minf(seat, PoseFit.seat_min_y(avatar.get_model_node()) + avatar.get_model_node().position.y)
		assert_almost(lowest, 0.0, 0.06, "%s ne havada ne gömülü" % node_name)
		# Temas kemikleri zemindeyken beden havada kalabilir: Baba ve Ağabey'in kalçası düzeltmeden önce 10-14 cm havadaydı. Çocuk kütükte
		# oturur; diz çöken Ana'nın bedeni dizlerinde ve topuklarındadır, kalça boşluğu sayılmaz (ölçüde de yazılmaz: seat_gap_m).
		if node_name != "Child" and not (lib.variant(key).get("leg_fit", []) as Array).has("kneel"):
			assert_true(seat <= ClipVariety.MAX_SEAT_GAP, "%s: kalça zeminden %.3f m yukarıda" % [node_name, seat])
	var elder := real.get_node(^"Elder") as CharacterAvatar
	elder.get_animation_player().seek(1.0, true)
	var elder_seat := PoseFit.seat_min_y(elder.get_model_node()) + elder.get_model_node().position.y
	assert_true(elder_seat <= ClipVariety.MAX_SEAT_GAP, "Ozan: kalça zeminden %.3f m yukarıda" % elder_seat)
	assert_false(lib.leg_fit_for("father", CampNpcs.SEATS["Father"]).is_empty(), "Baba'nın oturuşu düzeltilir")
	assert_false(lib.leg_fit_for("older_brother", CampNpcs.SEATS["OlderBrother"]).is_empty(), "Ağabey'in oturuşu düzeltilir")
	real.queue_free()


func test_people_differ_in_their_other_roles_too() -> void:
	var real := NPC_SCENE.instantiate() as CampNpcs
	for avatar in real.get_avatars():
		avatar.use_meshy_models = false
	add_child(real)
	for group: String in ["idle_loop", "sit_ground"]:
		var seen := {}
		for id: String in PERSONS.values():
			seen[real.allocator.key_for(id, group)] = true
		assert_eq(seen.size(), PERSONS.size(), "%s: beş kişi beş ayrı klip: %s" % [group, seen.keys()])
	real.queue_free()


func test_seats_do_not_load_a_model_twice() -> void:
	# Kişiler modelleri yüklenmeden dağıtıcıya kaydolur: oturuş ilk karede doğrudur, sonradan değişmez.
	var real := NPC_SCENE.instantiate() as CampNpcs
	var loads := {}
	for avatar in real.get_avatars():
		avatar.model_changed.connect(func(id: String) -> void: loads[id] = int(loads.get(id, 0)) + 1)
	add_child(real)
	for avatar in real.get_avatars():
		assert_eq(avatar.get_current_role(), &"sit", "%s ağaca girince oturur" % avatar.name)
	for id: String in loads:
		assert_eq(loads[id], 1, "%s bir kez yüklenir" % id)
	real.queue_free()


func test_feet_stay_out_of_the_stone_ring() -> void:
	# Baba'nın ve Ağabey'in ayak eklemleri bu kliplerde düğümden 0,7-0,8 m öne uzanır: düğümleri ona göre geridedir. Eklem halkadan en az 9 cm uzakta; en yakın köşe Baba'da 10, Ağabey'de 8 cm.
	var real := NPC_SCENE.instantiate() as CampNpcs
	add_child(real)
	await wait_frames(2)
	var ring := Campfire.RING_DIAMETER * 0.5
	for avatar in real.get_avatars():
		var skeleton := avatar.get_skeleton()
		var player := avatar.get_animation_player()
		var length := player.get_animation(player.assigned_animation).length
		for i in 5:
			player.seek(length * i / 4.0, true)
			for bone_name in ["LeftFoot", "RightFoot", "LeftToeBase", "RightToeBase"]:
				var at: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(bone_name)).origin
				assert_true(Vector2(at.x, at.z).length() > ring + 0.09, "%s/%s halkaya girmemeli (%.2f m)" % [avatar.name, bone_name, Vector2(at.x, at.z).length()])
	real.queue_free()


## Kişinin ağı dünya uzayında, o anki pozda (işlemcide deri giydirilir): köşelerin her step'incisi.
func _world_points(avatar: CharacterAvatar, step: int = 3) -> PackedVector3Array:
	var out := PackedVector3Array()
	var skeleton := avatar.get_skeleton()
	var mi := avatar.get_model_node().find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var skin := mi.skin
	var matrices: Array[Transform3D] = []
	for i in skin.get_bind_count():
		var bone := skin.get_bind_bone(i)
		if bone < 0:
			bone = skeleton.find_bone(skin.get_bind_name(i))
		matrices.append(skeleton.global_transform * skeleton.get_bone_global_pose(bone) * skin.get_bind_pose(i))
	for s in mi.mesh.get_surface_count():
		var arrays := mi.mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var stride := bones.size() / verts.size()
		for v in range(0, verts.size(), step):
			var p := Vector3.ZERO
			for k in stride:
				var w := weights[v * stride + k]
				if w > 0.0:
					p += (matrices[bones[v * stride + k]] * verts[v]) * w
			out.append(p)
	return out


## İki nokta bulutunun arası (metre; hücre ızgarasıyla, radius'tan uzaksa INF).
func _cloud_gap(a: PackedVector3Array, b: PackedVector3Array, radius: float = 0.5) -> float:
	var cells := {}
	for p in b:
		var key := Vector3i((p / radius).floor())
		if not cells.has(key):
			cells[key] = PackedVector3Array()
		cells[key].append(p)
	var best := INF
	for p in a:
		var center := Vector3i((p / radius).floor())
		for x in range(-1, 2):
			for y in range(-1, 2):
				for z in range(-1, 2):
					var cell: Variant = cells.get(center + Vector3i(x, y, z))
					if cell == null:
						continue
					for q: Vector3 in cell:
						best = minf(best, p.distance_squared_to(q))
	return sqrt(best)


func test_mother_kneels_behind_the_child_clear_of_her_neighbours() -> void:
	# Ana topukları üstünde diz çöker: dizleri kalçasının ≈35 cm önündedir. Çocuğa kucak gibi yakın, ama içine girmez; Baba'ya da, taş halkaya da.
	var real := NPC_SCENE.instantiate() as CampNpcs
	add_child(real)
	await wait_frames(2)
	var mother := real.get_node(^"Mother") as CharacterAvatar
	assert_eq(mother.variety_key(&"sit"), "ground_kneel_heels", "Ana diz çöker")
	var player := mother.get_animation_player()
	var length := player.get_animation(player.assigned_animation).length
	var ring := Campfire.RING_DIAMETER * 0.5
	var child_points := _world_points(real.get_node(^"Child") as CharacterAvatar)
	var father_points := _world_points(real.get_node(^"Father") as CharacterAvatar)
	var nearest_child := INF
	var nearest_father := INF
	var nearest_fire := INF
	for i in 3:
		player.seek(length * i / 2.0, true)
		var points := _world_points(mother)
		nearest_child = minf(nearest_child, _cloud_gap(points, child_points))
		nearest_father = minf(nearest_father, _cloud_gap(points, father_points))
		for p in points:
			nearest_fire = minf(nearest_fire, Vector2(p.x, p.z).length())
	assert_true(nearest_child >= 0.03, "Ana çocuğa girmez: %.3f m" % nearest_child)
	assert_true(nearest_child <= 0.25, "Çocuk kucağının önünde: %.3f m" % nearest_child)
	assert_true(nearest_father >= 0.2, "Baba'yla arası: %.3f m" % nearest_father)
	assert_true(nearest_fire - ring >= 0.5, "Taş halkadan uzakta: %.3f m" % (nearest_fire - ring))
	real.queue_free()


func test_child_sits_on_a_low_log() -> void:
	# Dizlerini kucaklayan klip kalçayı havada tutar: altında kütük vardır, üstü kalçaya değer.
	assert_null(npcs.get_node_or_null(^"Child/SeatLog"), "Chibi yedeği bağdaş kurar: kütük yok")
	var real := NPC_SCENE.instantiate() as CampNpcs
	add_child(real)
	await wait_frames(2)
	var child := real.get_node(^"Child") as CharacterAvatar
	var seat := child.get_node_or_null(^"SeatLog") as MeshInstance3D
	assert_not_null(seat, "Child/SeatLog")
	if seat == null:
		real.queue_free()
		return
	var radius := float(CampNpcs.SEAT_LOG["radius"])
	assert_almost(seat.position.y, radius, 0.001, "Kütük zeminde yatar")
	assert_almost(absf(seat.transform.basis.y.normalized().x), 1.0, 0.001, "Uzun ekseni omuzlara koşut")
	child.get_animation_player().seek(1.0, true)
	var hips: Array[String] = ["Hips"]
	var seat_y := PoseFit.skinned_min_y(child.get_model_node(), hips) + child.get_model_node().position.y
	assert_almost(radius * 2.0, seat_y, 0.04, "Kütüğün üstü kalçaya değer (%.3f m)" % seat_y)
	var skeleton := child.get_skeleton()
	var hip_at: Vector3 = child.get_model_node().transform * (PoseFit.relative_transform(child.get_model_node(), skeleton) * skeleton.get_bone_global_pose(skeleton.find_bone("Hips")).origin)
	assert_almost(hip_at.z, seat.position.z, 0.07, "Kalçanın altında")
	real.set_hidden_model("child")
	assert_false(seat.is_visible_in_tree(), "Çocuk gizlenince kütük de gizlenir")
	real.queue_free()


func test_child_leaves_her_seat_but_the_log_stays() -> void:
	# Serbest Gez'de oyuncu Çocuk'tur (K37): oturan kopyası gizlenir, oyuncu aynı yerde aynı oturuşla belirir, kütük yerde kalır. Menüde hiçbir şey değişmez.
	var real := NPC_SCENE.instantiate() as CampNpcs
	add_child(real)
	await wait_frames(2)
	var child := real.get_node(^"Child") as CharacterAvatar
	var seat := real.child_seat()
	assert_false(seat.is_empty(), "Yeri okunur")
	assert_vec_almost((seat["transform"] as Transform3D).origin, child.global_position, 0.0001)
	assert_true(float(seat["clip_time"]) >= 0.0, "Klibin anı")
	assert_null(real.get_node_or_null(NodePath(CampNpcs.LEFT_LOG_NAME)), "Menüde kopya kurulmaz: çizim eklemez")
	real.set_seat_left(true)
	assert_null(real.get_node_or_null(NodePath(CampNpcs.LEFT_LOG_NAME)), "Çocuk görünürken kopya yok")
	real.set_hidden_model("child")
	assert_false(child.visible, "İkinci Çocuk olmaz")
	var kept := real.get_node_or_null(NodePath(CampNpcs.LEFT_LOG_NAME)) as MeshInstance3D
	assert_not_null(kept, "Kütük yerde")
	if kept:
		var original := child.get_node(NodePath(CampNpcs.SEAT_LOG_NAME)) as MeshInstance3D
		assert_true(kept.is_visible_in_tree(), "Görünür")
		assert_vec_almost(kept.global_position, original.global_position, 0.0001, "Aynı yerde")
		assert_eq(kept.mesh, original.mesh)
		assert_eq(real.get_avatars().size(), 5, "Kopya kişi sayılmaz")
		real.set_seat_left(false)
		assert_false(kept.visible, "Bırakılınca kalkar (kütük kişiyle gizli)")
		real.set_seat_left(true)
		real.set_hidden_model("")
		assert_true(child.visible, "Menüye dönüşte Çocuk oturur")
		assert_false(kept.visible, "Kopya gider: iki kütük yok")
	real.free()


func test_bow_lies_clear_of_the_brothers_legs() -> void:
	var real := NPC_SCENE.instantiate() as CampNpcs
	add_child(real)
	await wait_frames(2)
	var brother := real.get_node(^"OlderBrother") as CharacterAvatar
	var bow := brother.get_node(^"Bow") as Node3D
	var skeleton := brother.get_skeleton()
	for bone_name in ["LeftLeg", "LeftFoot", "LeftToeBase", "RightLeg", "RightFoot", "RightToeBase"]:
		var at: Vector3 = brother.to_local(skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(bone_name)).origin)
		assert_true(absf(at.x - bow.position.x) > 0.25 or at.y > 0.3, "%s yaya değmez (%s)" % [bone_name, at])
	real.queue_free()


# --- Modellerin ölçüm dosyaları ---------------------------------------------------------

func test_seated_models_have_ground_offsets() -> void:
	# Her oturan modelin "sit" zemin payı ölçülmüş olmalı; yoksa karakter havada kalır ya da gömülür.
	# (Model yeniden üretilirse scripts/character/character_fit_tool.gd yeniden çalıştırılmalı.)
	for id in EXPECTED.values():
		if not ResourceLoader.exists(CharacterOptions.model_path(id)):
			continue
		var fit := CharacterAvatar._load_fit(id)
		assert_false(fit.is_empty(), "%s_fit.json eksik" % id)
		var offset := CharacterAvatar.fit_value(fit, "ground_offset", &"sit", NAN)
		assert_false(is_nan(offset), "%s için oturma zemin payı yok" % id)
		assert_between(offset, -0.2, 0.2, "%s oturma zemin payı makul olmalı" % id)
