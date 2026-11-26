extends TestCase
## Yola Çıkış (mq0_depart; K6, K37, K58, K61, K67, K98, K99; story.md §6, docs-app story/childhood «Yola Çıkış»):
##   - Veri eksiksiz: üç adım (yay, avlu, at), satırlar iki dilde ve tasarımdaki gibi, beş kişi (Gutu Huyan Hatun'un kucağında).
##   - Dünya (depart_yurt; ana kampa dokunmaz, K6) kampın ve Ordos'un yapı taşlarıyla kurulur: Yançi'nin yurdu (içi, ocağı, beşiği, küçük yayı,
##     kundağı; kapılı duvar; oyuncu içerideyken çatı kalkar, K98 diorama), Huyan Hatun'un ışıklı yurdu, Teoman'ın kapısı kapalı ve ışıksız otağı,
##     armağan arabası ve binilmeyen atı, Mete'nin (sahne açana dek kilitli) atı, ateş, karlı zemin.
##   - Ana sahnede Yeni Oyun'un Yola Çıkış aşaması (oluşturulan Mete): tarih kartı, HUD'un görev kartı, yönü ve Görevler sayfası (ChildhoodScene'in
##     yüzüyle), duraklatma kitabında KAYDET kapalı; E ile yay asılır (kamera E ile dönmez), Yançi'nin sözü; Eskam'ın sözü, Teoman'ın kapısında
##     uzak kare dört saniye; Lan Hatun'un sözü, E ile ata binilir; oyuncu atı batı yolunda kendisi sürer (E20: amaç ve yön yolun eşiği, at
##     dörtnala kalkmaz, attan inene «Atına bin»), eşikte kamera arkada kalan kampa döner (uzak kare), perde kararır, Köprü 2. Kişilerin hızı
##     yetişkinin koşusunu aşmaz. Kayıt yazılmaz, kampa inilmez.
##   - Batı yolu: kampın dış yurtları ve çit yolun iki yanında, eşik hepsinin ötesinde; çiğnenmiş kar yolu eşiğe dek götürür, kamera sınırı ve
##     sürüşün alanı yolu kapsar. Eşik ve arkaya bakışın açısı saf hesaptır.
##   - Kişiler: kendi modelleri varsa onlar; yoksa (sahte klasör: glb'siz, meta.json'da stand_in) StandIn yer tutucuları. İki hâlde de sahne aynı akar.

const MAIN_SCENE := "res://scenes/main.tscn"
const TempDir := preload("res://tests/support/temp_dir.gd")
const PEOPLE: Array[String] = ["yanchi", "eskam", "huyan_hatun", "gutu", "lan_hatun"]
## Modeli bugün gelen dört kişi (yer tutucu sınaması bunları sahte klasörde modelsiz kurar).
const NEW_MODELS: Array[String] = ["yanchi", "eskam", "huyan_hatun", "gutu"]
## Yer tutucunun sınamada verilen modeli ve ölçeği.
const STAND_INS := {"yanchi": ["hero_f", 0.98], "eskam": ["elder", 1.0], "huyan_hatun": ["mother", 1.0], "gutu": ["child", 0.62]}
const LINES := {
	"yanchi_bow": ["Yay burada kalır, ben gererim. Sen git, sayılmaya.", "The bow stays here; I'll keep it strung. Go on, go and be counted."],
	"eskam_road": ["Evladım, yol uzun. Ben her kış gelirim.", "My boy, the road is long. I will come every winter."],
	"lan_days": ["Kırk iki gün yol.", "Forty-two days of road."],
	"eskam_ride": ["Sen sür evladım, araba ardından yetişir.", "Ride on, my boy. The cart will catch up."],
}
const SPEED := 4.0

var _dir := ""
var _camp_play := false
var _saved := false


func before_each() -> void:
	MenuStyle.muted = true
	Engine.time_scale = 1.0
	CineVideo.enabled = false
	_dir = TempDir.fresh("yola_cikis")
	_camp_play = false
	_saved = false


func after_each() -> void:
	Engine.time_scale = 1.0
	CineVideo.enabled = true
	get_tree().paused = false
	_key(KEY_E, false)
	TempDir.wipe(_dir)


# --- Veri ------------------------------------------------------------------------------------------------

func test_data_is_complete_and_says_the_design_lines() -> void:
	var d := DepartScene.load_data()
	assert_eq(DepartScene.validate(d), PackedStringArray(), "Veri sorunsuz")
	assert_eq(DepartScene.step_ids(d), PackedStringArray(["yurt", "yard", "horse"]), "Üç adım: yurt, avlu, at")
	assert_eq(str(d["id"]), "mq0_depart")
	assert_eq(int(d["day_n"]), -41, "15 Aralık MÖ 213 (K67)")
	assert_eq(str(d["date"]["tr"]), "15 Aralık MÖ 213 · Tanhu Kampı")
	assert_eq(str(d["title"]["tr"]), "Yola Çıkış")
	var lines: Dictionary = d["lines"]
	for id: String in LINES:
		assert_eq(str(lines[id]["tr"]), LINES[id][0], "%s tasarımdaki gibi" % id)
		assert_eq(str(lines[id]["en"]), LINES[id][1], "%s İngilizcesi tasarımdaki gibi" % id)
	assert_eq(str(lines["yanchi_bow"]["speaker"]), "yanchi")
	assert_eq(str(lines["eskam_road"]["speaker"]), "eskam")
	assert_eq(str(lines["lan_days"]["speaker"]), "lan_hatun")
	var actors: Dictionary = d["actors"]
	for id in PEOPLE:
		assert_true(actors.has(id), "%s sahnede" % id)
	assert_eq(str(actors["gutu"]["carried_by"]), "huyan_hatun", "Gutu Huyan Hatun'un kucağında")
	assert_eq(str((d["steps"][1] as Dictionary)["door"]["focus"]), "door_focus")
	assert_almost(float((d["steps"][1] as Dictionary)["door"]["seconds"]), 4.0, 0.001, "Kapıda dört saniye")
	# Görev: adımların amaçları ve durumu (HUD'un Görevler sayfası).
	var q := DepartScene.quest_of(d, 1)
	assert_eq(q["title"], "Yola Çıkış")
	assert_eq((q["steps"] as Array).map(func(s: Dictionary) -> String: return s["state"]), ["done", "current", "todo"])
	assert_true(bool(DepartScene.quest_of(d, 3)["done"]), "Üç adımdan sonra bitti")


# --- Dünya --------------------------------------------------------------------------------------------------

func test_world_builds_from_camp_and_ordos_blocks() -> void:
	var world := (load(DepartWorld.SCENE_PATH) as PackedScene).instantiate() as DepartWorld
	add_child(world)
	await _wait_until(func() -> bool: return world.is_ready(), 30.0)
	assert_true(world.is_ready(), "Dünya kuruldu")
	assert_true(float(world.build_stats["ready_ms"]) > 0.0)
	for id in ["cradle", "hang_spot", "mete_start", "door_in", "door_out", "inside", "eskam_stand", "eskam_talk", "eskam_seat", "huyan_stand",
			"teoman_door", "door_focus", "horse", "lan_stand", "mount_approach", "road_west", "courtyard", "camp_view", "road_gate", "road_end",
			"road_far"]:
		assert_ne(world.marker(id), Vector3.INF, "%s işareti" % id)
	assert_eq(world.marker("yok"), Vector3.INF)
	# Yançi'nin yurdu: doğum yurdunun içi (kerege astarı), ocak, kapılı duvar; beşik, küçük yay ve kundak içeride.
	var home := world.place("yanchi_yurt")
	assert_true(home is DepartWorld.HomeYurt, "Ev yurdu")
	assert_true(home is OrdosWorld.BirthYurt, "Ordos'un doğum yurdunun içi")
	assert_not_null(home.get_node_or_null(^"Hearth"), "Ocak")
	assert_not_null(home.get_node_or_null(^"Lining"), "Kerege astarı")
	var center := Vector2(home.global_position.x, home.global_position.z)
	for id in ["cradle", "hang_spot", "mete_start", "inside"]:
		var p := world.marker(id)
		assert_true(Vector2(p.x, p.z).distance_to(center) < 3.2 * 0.85, "%s yurdun içinde" % id)
	assert_not_null(world.cradle.get_node_or_null(^"Swaddle/Model"), "Kundakta Jiyu (swaddled_baby)")
	assert_true(world.small_bow.get_child_count() > 0, "Kemerde küçük ok-yay (cradle_bow)")
	assert_false(world.mete_bow.visible, "Mete'nin yayı asılana dek görünmez")
	var walls := world.collect_walls()
	assert_eq(walls.size(), 1, "Ev yurdunun keçe duvarı")
	if not walls.is_empty():
		var inside := Vector2(world.marker("inside").x, world.marker("inside").z)
		assert_true(walls[0].contains(inside), "Duvarın içi")
		var door := Vector2(world.marker("door_out").x, world.marker("door_out").z)
		assert_false(walls[0].contains(door), "Kapının önü dışarıda")
	# Teoman'ın otağı: kapısı kapalı, kapıdan ışık sızmaz.
	var otag := world.place("teoman_otag")
	assert_true(otag is DepartWorld.ClosedYurt, "Teoman'ın otağı")
	assert_not_null(otag.find_child("DoorClosed", true, false), "Kapalı kapı")
	assert_eq(otag.find_children("*", "Light3D", true, false).size(), 0, "Kapalı otaktan ışık sızmaz")
	assert_not_null(world.place("huyan_yurt").find_child("DoorSpill", true, false), "Huyan Hatun'un kapısı ışıklı")
	# Araba ve atlar: çeken at binilmez; Mete'nin atı sahne açana dek kilitli, açınca binilir.
	assert_not_null(world.cart.get_node_or_null(^"Cover"), "Keçe örtülü araba")
	assert_false(world.cart_horse.is_in_group(Rideable.GROUP), "Arabanın atı binilmez")
	assert_true(world.is_horse_locked(), "Mete'nin atı kilitli")
	assert_false(world.horse.is_in_group(Rideable.GROUP))
	var boxes_locked := world.collect_boxes().size()
	world.lock_horse(false)
	assert_true(world.horse.is_in_group(Rideable.GROUP), "Açınca binilir")
	assert_eq(world.collect_boxes().size(), boxes_locked - 1, "Binilir at engel kutusunu binek kodundan alır")
	world.lock_horse(true)
	assert_not_null(world.campfire, "Avlunun ateşi")
	assert_eq(world.horse.mount_kind(), "horse")
	# Zemin: kar (ordos_ground.gdshader), çiğnenmiş kar katmanı.
	assert_not_null(world.get_node_or_null(^"Ground/Terrain"), "Karlı zemin")
	assert_not_null(world.get_node_or_null(^"Ground/Trampled"), "Çiğnenmiş kar")
	assert_true(is_finite(world.get_terrain_shape().height_at(0.0, 0.0)))
	# Diorama (K98): içerideyken çatı kalkar, dışarıda iner; kesit kameraya bakar.
	var yurt := home as DepartWorld.HomeYurt
	await _wait_until(func() -> bool: return not yurt.cut_materials().is_empty(), 5.0)
	assert_true(yurt.cut_materials().size() >= 3, "Kabuk ve astar kesitli")
	# Kesilmeyen gölge kopyaları çizilmez (yerine yalın gölge gövdesi): görünür olsalardı kesitin üstüne bütün kabuğu çizerlerdi.
	await wait_frames(2)
	for mi: MeshInstance3D in yurt.find_children("*", "MeshInstance3D", true, false):
		if mi.has_meta(MeshyProp.SHADOW_PROXY_META) or mi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:
			assert_true(not mi.is_visible_in_tree() or mi.name == "ShadowBody", "%s yalnız gölgedir, çizilmez" % mi.name)
	assert_eq(yurt.find_children("ShadowBody", "MeshInstance3D", false, false).size(), 1, "Yurdun yalın gölge gövdesi")
	var shadow_tris := 0
	for mi: MeshInstance3D in world.find_children("*", "MeshInstance3D", true, false):
		if mi.is_visible_in_tree() and mi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and mi.mesh:
			for k in mi.mesh.get_surface_count():
				var arr := mi.mesh.surface_get_arrays(k)
				shadow_tris += (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3 if arr[Mesh.ARRAY_INDEX] != null else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	assert_true(shadow_tris < 400000, "Dünyanın gölge veren ağları bütçede (%d üçgen; kişiler hariç)" % shadow_tris)
	var cam := yurt.global_position + Vector3(0.0, 17.0, 22.0)
	yurt.set_camera_occlusion(cam, world.marker("inside") + Vector3(0.0, 0.7, 0.0))
	await _wait_until(func() -> bool: return yurt.cut >= 0.999, 3.0)
	assert_almost(yurt.cut, 1.0, 0.001, "İçerideyken çatı kalkar")
	assert_almost(float(yurt.cut_materials()[0].get_shader_parameter(&"cut_amount")), 1.0, 0.001)
	var dir: Vector2 = yurt.cut_materials()[0].get_shader_parameter(&"cut_dir")
	assert_true(dir.dot(Vector2(0.0, 1.0)) > 0.99, "Kesit kameraya bakar")
	yurt.set_camera_occlusion(cam, world.marker("eskam_talk") + Vector3(0.0, 0.7, 0.0))
	await _wait_until(func() -> bool: return yurt.cut <= 0.001, 3.0)
	assert_almost(yurt.cut, 0.0, 0.001, "Dışarıdayken çatı yerinde")
	# Batı yolu (E20): eşik kampın son yurtlarının ve çitin ötesinde, yol eşiğe dek çiğnenmiş kar, ızgara ve kamera sınırı yolu kapsar.
	var road_end := world.marker("road_end")
	var gate := world.marker("road_gate")
	var places: Dictionary = world.layout["places"]
	for id: String in places:
		var at := OrdosGround._vec2(places[id]["at"])
		assert_true(road_end.x < at.x - float(places[id].get("radius", 3.0)) - 3.0, "Eşik %s yurdunun ötesinde" % id)
	var fences := 0
	for item: Dictionary in world.layout["props"]:
		if str(item["kind"]) == "FENCE":
			fences += 1
			assert_true(road_end.x < float(item["at"][0]) - 2.0, "Eşik çitin ötesinde (%s)" % str(item["at"]))
	assert_true(fences >= 4, "Kampın batı ucunda çit")
	for t in [0.0, 0.25, 0.5, 0.75, 1.0]:
		var p := world.marker("horse").lerp(road_end, t)
		assert_true(world.ground.trampled_weight(Vector2(p.x, p.z)) > 0.9, "Yol çiğnenmiş kar (%.0f, %.0f)" % [p.x, p.z])
		assert_true(world.ground.in_map(p.x, p.z), "Yol ızgaranın içinde")
	for c: Vector3 in world.collect_obstacles():
		var near := Geometry2D.get_closest_point_to_segment(Vector2(c.x, c.y), Vector2(world.marker("horse").x, world.marker("horse").z), Vector2(road_end.x, road_end.z))
		assert_true(near.distance_to(Vector2(c.x, c.y)) > c.z + 1.0, "Yolun üstünde engel yok (%s)" % c)
	assert_true(world.camera_bounds().position.x < world.marker("road_far").x, "Kamera sınırı yolu kapsar")
	assert_true(DepartScene.past_threshold(Vector2(road_end.x - 0.5, road_end.z), Vector2(gate.x, gate.z), Vector2(road_end.x, road_end.z), 30.0), "Eşiğin ötesi")
	assert_false(DepartScene.past_threshold(Vector2(road_end.x + 0.5, road_end.z), Vector2(gate.x, gate.z), Vector2(road_end.x, road_end.z), 30.0), "Eşiğin berisi")
	assert_false(DepartScene.past_threshold(Vector2(road_end.x - 5.0, road_end.z + 40.0), Vector2(gate.x, gate.z), Vector2(road_end.x, road_end.z), 30.0), "Yoldan çok uzak değil")
	var yaw := DepartScene.look_back_yaw(road_end, world.marker("camp_view"))
	var cam_xform := FollowCamera.compute_transform(road_end, yaw, 38.0, 40.0)
	assert_true(cam_xform.origin.x < road_end.x, "Arkaya bakışta kamera atlının batısında")
	assert_true((-cam_xform.basis.z).x > 0.5, "Kamera doğuya, arkada kalan kampa bakar")
	var ride: Dictionary = (DepartScene.load_data()["steps"][2] as Dictionary)["ride"]
	var area_c := OrdosGround._vec2(ride["area"]["center"])
	for p in [world.marker("horse"), world.marker("lan_stand"), world.marker("courtyard"), road_end + Vector3(-20.0, 0.0, 0.0)]:
		assert_true(Vector2(p.x, p.z).distance_to(area_c) < float(ride["area"]["radius"]) - 2.0, "Sürüşün alanı yolu ve eşiğin 20 m ötesini kapsar (%s)" % p)
	# Harita: yerler ve gizlenen atlar.
	var spec := world.map_spec()
	assert_eq(spec["key"], "depart_yurt")
	assert_true((spec["places"] as Array).size() >= 4)
	assert_true((spec["hide"] as Array).has(world.horse))
	world.queue_free()
	await wait_frames(3)


# --- Ana sahnede ----------------------------------------------------------------------------------------------

func test_departure_plays_in_the_new_game_flow() -> void:
	var main := await _new_main()
	await _play_departure(main, "")
	await _free_main(main)


## Dört kişinin modeli yokken (sahte klasör: glb'siz, meta.json'da stand_in) yer tutucular çıkar; sahne aynı akar.
func test_stand_ins_fill_in_until_the_models_arrive() -> void:
	var root := _fake_actor_root()
	for id in NEW_MODELS:
		var r := StandIn.resolve(id, root)
		assert_true(bool(r["stand_in"]), "%s: modeli yok, yer tutucu" % id)
		assert_eq(str(r["model"]), str(STAND_INS[id][0]))
		assert_false(bool(StandIn.resolve(id)["stand_in"]), "%s: oyunun klasöründe kendi modeli" % id)
	var main := await _new_main()
	main.depart_actor_root = root
	await _play_departure(main, root)
	await _free_main(main)


# --- Yardımcılar ---------------------------------------------------------------------------------------------

## Yola Çıkış'tan Köprü 2'ye (yalnız bu iki aşama): adımlar doğrudan sürülür.
func _play_departure(main: Node, root: String) -> void:
	var chosen := CharacterProfile.new()
	chosen.set_value(&"skin", 2)
	main.profile = chosen
	main.new_game_from = "depart"
	main.new_game_only = PackedStringArray(["depart", "bridge_2"])
	main.cine_speed = 24.0
	var probe := func() -> void:
		if main.state == main.State.PLAYING and main._story_world() == null:
			_camp_play = true
		if main.saves.has_any_save():
			_saved = true
	get_tree().process_frame.connect(probe)
	var prompts: Array = []
	main.player.prompt_changed.connect(func(pairs: Array) -> void: prompts.append(pairs))
	main.menu.start_requested.emit()
	await _wait_until(func() -> bool: return main.cine.card_text() != "", 5.0)
	assert_eq(main.cine.card_text(), "15 Aralık MÖ 213 · Tanhu Kampı", "Kara perdede tarih kartı")
	assert_eq(main.flow_stage_id(), "depart")
	await _wait_until(func() -> bool: return main.state == main.State.PLAYING, 90.0)
	assert_eq(main.state, main.State.PLAYING, "Yola Çıkış oynanır")
	var scene: DepartScene = main._depart_scene
	var world: DepartWorld = main._depart_world
	assert_not_null(scene, "Sahne")
	assert_not_null(world, "Dünya")
	if scene == null or world == null:
		get_tree().process_frame.disconnect(probe)
		return
	var said: Array[String] = []
	scene.said.connect(func(id: String) -> void: said.append(id))
	# Sözler seslidir (E20/7): Voice yolunda başlayan satırlar.
	var voiced: Array[String] = []
	var audio := get_node_or_null(^"/root/AudioManager")
	var on_line := func(id: String) -> void: voiced.append(id)
	if audio:
		audio.line_started.connect(on_line)
	# Kişilerin hızı (E20): sahne boyunca görünen her kişi kare kare ölçülür.
	var people := PaceLimit.Probe.new()
	var measure := func() -> void:
		var sc: DepartScene = main._depart_scene
		if sc == null or not sc.is_running():
			return
		for id: String in sc.actors:
			var a: CineActor = sc.actors[id]
			if is_instance_valid(a) and a.is_visible_in_tree():
				people.sample(id, a.global_position, sc.clock)
	get_tree().process_frame.connect(measure)
	assert_false(main.world.visible, "Ana kamp bırakıldı (K6)")
	assert_eq(int(main.journey.flags.get(NewGameFlow.DAY_FLAG, 0)), -41, "Takvim 15 Aralık MÖ 213")
	# Oluşturulan Mete (K37): yetişkin, profilin görünüşüyle, takip kamerası 28 m (K98).
	var player: PlayerController = main.player
	assert_false(player.is_child(), "Yetişkin Mete")
	assert_true(player.get_avatar().get_profile().equals(chosen), "Oluşturucunun görünüşü")
	assert_eq(main.follow_camera.target, player)
	assert_almost(main.follow_camera.get_target_distance(), FollowCamera.DEFAULT_DISTANCE, 0.01, "28 m: yakın plan yok")
	assert_true(Vector2(player.global_position.x - world.home.global_position.x, player.global_position.z - world.home.global_position.z).length() < 3.0,
		"Yançi'nin yurdunda")
	await wait_frames(3)
	assert_almost(world.home.cut, 1.0, 0.001, "İçerideyken çatı kalkık (diorama)")
	# Kişiler: kendi modeli ya da yer tutucu.
	for id in PEOPLE:
		var a: CineActor = scene.actors.get(id)
		assert_not_null(a, "%s kurulu" % id)
		if a and NEW_MODELS.has(id):
			assert_eq(a.is_stand_in(), not root.is_empty(), "%s: %s" % [id, "yer tutucu" if not root.is_empty() else "kendi modeli"])
			assert_eq(a.model_id(), str(STAND_INS[id][0]) if not root.is_empty() else id)
	# HUD: görev kartı, yönü, Görevler sayfası (ChildhoodScene'in yüzü: hud_quest, hud_target).
	var ghud: GameplayHud = main.gameplay_hud
	await wait_frames(2)
	assert_true(ghud.is_shown(), "Yola Çıkış'ta HUD açık")
	assert_eq(ghud.quest_source, scene, "Görev kaynağı sahne")
	ghud._poll_quest()
	assert_eq(ghud.quest_card.title, "Yola Çıkış")
	assert_eq(ghud.quest_card.objective, "Yayını Jiyu'nun beşiğine as")
	assert_vec_almost(ghud.pointer.target, world.marker("cradle"), 0.01, "Yön beşik")
	var journal: Array = ghud.journal_quests()
	assert_eq(str((journal[0] as Dictionary)["id"]), "mq0_depart", "Görevler sayfasında Yola Çıkış")
	assert_not_null(ghud.map, "Tanhu Kampı'nın haritası")
	if ghud.map:
		assert_eq(ghud.map.key, "depart_yurt")
	await _assert_pause_blocks_saving(main)

	# 1) Yurt: beşiğin önünde E ipucu; E yayı asar (kamera E ile dönmez); Yançi konuşur.
	assert_eq(scene.current_step_id(), "yurt")
	player.spawn_at(world.marker("hang_spot"), CampNpcs.facing_yaw(world.marker("hang_spot"), world.marker("cradle")))
	await wait_frames(3)
	assert_true(scene.can_hang(), "Beşiğin önünde")
	assert_true(prompts.has([["E", "Yayı as"]]), "İpucu: E Yayı as")
	var yaw_before: float = main.follow_camera.get_yaw()
	_key(KEY_E, true)
	await wait_frames(2)
	_key(KEY_E, false)
	assert_eq(scene.current_phase(), "hang", "E yayı asar")
	assert_false(player.is_active(), "Asarken oyuncu durur")
	Engine.time_scale = SPEED
	await _wait_until(func() -> bool: return said.has("yanchi_bow"), 10.0)
	assert_true(said.has("yanchi_bow"), "Yançi: «Yay burada kalır, ben gererim. Sen git, sayılmaya.»")
	assert_eq(scene.hud.subtitles.current_text(), "Yançi: " + LINES["yanchi_bow"][0], "Söz altyazıda")
	assert_true(scene.bow_hung and world.mete_bow.visible, "Yay beşikte")
	assert_vec_almost(world.mete_bow.global_position, world.hang_transform().origin, 0.01, "Küçük yayın yanında")
	assert_almost(wrapf(main.follow_camera.get_yaw() - yaw_before, -PI, PI), 0.0, 0.02, "E kamerayı döndürmedi")

	# 2) Avlu: Huyan Hatun el sallar, Gutu kucağında; Eskam'ın sözü; Teoman'ın kapısında uzak kare, dört saniye.
	await _wait_until(func() -> bool: return scene.current_step_id() == "yard", 10.0)
	assert_eq(scene.current_step_id(), "yard")
	assert_true(player.is_active(), "Söz bitince yürür")
	ghud._poll_quest()
	assert_eq(ghud.quest_card.objective, "Avluya çık: Eskam bekliyor")
	await wait_frames(2)
	assert_vec_almost(ghud.pointer.target, world.marker("eskam_talk"), 0.01, "Yön Eskam")
	var huyan: CineActor = scene.actors["huyan_hatun"]
	var gutu: CineActor = scene.actors["gutu"]
	await wait_frames(5)
	assert_true(huyan.gesture_amount > 0.5 and gutu.gesture_amount > 0.5, "El sallıyorlar")
	assert_true(huyan.reach_amount > 0.99, "Kol çocuğu taşıyor")
	assert_true(Vector2(gutu.global_position.x - huyan.global_position.x, gutu.global_position.z - huyan.global_position.z).length() < 0.5, "Gutu kucakta")
	assert_true(gutu.global_position.y - huyan.global_position.y > 0.4, "Gutu yerde değil")
	player.spawn_at(world.marker("eskam_talk"), 0.0)
	await _wait_until(func() -> bool: return said.has("eskam_road"), 5.0)
	assert_true(said.has("eskam_road"), "Eskam: «Evladım, yol uzun. Ben her kış gelirim.»")
	assert_false(player.is_active(), "Söz sırasında oyuncu durur")
	await _wait_until(func() -> bool: return scene.current_phase() == "door_hold", 10.0)
	assert_eq(scene.current_phase(), "door_hold", "Kamera kapıda")
	var held_at := scene.clock
	assert_ne(main.follow_camera.target, player, "Odak kapıda")
	var focus := main.follow_camera.target as Node3D
	assert_true(focus.global_position.distance_to(world.marker("door_focus")) < 0.6, "Teoman'ın kapısı")
	assert_true(main.follow_camera.get_target_distance() >= FollowCamera.DEFAULT_DISTANCE, "Uzak kare (K98)")
	await _wait_until(func() -> bool: return scene.current_phase() == "door_back", 10.0)
	assert_almost(scene.clock - held_at, 4.0, 0.25, "Kapıda dört saniye")
	await _wait_until(func() -> bool: return scene.current_step_id() == "horse", 10.0)

	# 3) At: binilir olur; Lan Hatun dizginleri uzatır, «Kırk iki gün yol.»; E ile binilir. Oyuncu atı kendisi sürer (E20): amaç «Batı yoluna
	#    çık», yön yolun eşiği; uyuyan kampta at dörtnala kalkmaz (Shift tırıs). Attan inene amaç «Atına bin». Eşikte girdi bırakılır, at adımla
	#    yürür, kamera arkada kalan kampa döner (uzak kare, K98), perde kararır, Köprü 2.
	assert_eq(scene.current_step_id(), "horse")
	assert_eq(main.follow_camera.target, player, "Kamera oyuncuda")
	assert_true(world.horse.is_in_group(Rideable.GROUP), "At binilir")
	ghud._poll_quest()
	assert_eq(ghud.quest_card.objective, "Atına bin")
	player.spawn_at(world.marker("mount_approach"), -PI * 0.5)
	await _wait_until(func() -> bool: return said.has("lan_days"), 5.0)
	assert_true(said.has("lan_days"), "Lan Hatun: «Kırk iki gün yol.»")
	await wait_frames(10)
	assert_true((scene.actors["lan_hatun"] as CineActor).reach_amount > 0.3, "Dizginleri uzatıyor")
	assert_eq(player.mount_in_reach(), world.horse, "At erimde")
	assert_true(player.interact(), "E biner")
	await _wait_until(func() -> bool: return player.is_riding(), 5.0)
	assert_true(player.is_riding(), "Atta")
	await _wait_until(func() -> bool: return scene.current_phase() == "ride", 5.0)
	assert_eq(scene.current_phase(), "ride", "Binince sürüş: sahne kararmaz")
	assert_almost(main.fade.color.a, 0.0, 0.01, "Perde açık")
	assert_true(player.is_active(), "Atı oyuncu sürer")
	ghud._poll_quest()
	assert_eq(ghud.quest_card.objective, "Batı yoluna çık", "Görev kartı yolu gösterir")
	await wait_frames(2)
	assert_vec_almost(ghud.pointer.target, world.marker("road_end"), 0.01, "Yön yolun eşiği")
	assert_eq(main.follow_camera.target, player, "Kamera atlıyı izler")
	assert_true(main.follow_camera.get_target_distance() >= FollowCamera.DEFAULT_DISTANCE, "Sürüşte uzak kare (K98)")
	var mount := world.horse.get_mount()
	assert_true(mount.value("gallop_after_s") > 100.0 and mount.value("spur") <= 0.0, "Uyuyan kampta dörtnal ve mahmuz yok")
	# Binişten 2 sn sonra Eskam avludan seslenir (ride.line): «Sen sür evladım, araba ardından yetişir.»
	await _wait_until(func() -> bool: return said.has("eskam_ride"), 5.0)
	assert_true(said.has("eskam_ride"), "Eskam binişten sonra avludan seslenir")
	# Attan inince amaç «Atına bin», yön at; yeniden binince yol.
	assert_true(player.interact(), "E iner")
	await _wait_until(func() -> bool: return not player.is_riding() and player.get_stance() == PlayerController.Stance.FOOT, 5.0)
	await wait_frames(2)
	ghud._poll_quest()
	assert_eq(ghud.quest_card.objective, "Atına bin", "Attan inene amaç at")
	assert_vec_almost(ghud.pointer.target, world.horse.global_position, 0.05, "Yön at")
	assert_eq(player.mount_in_reach(), world.horse)
	assert_true(player.interact(), "Yeniden biner")
	await _wait_until(func() -> bool: return player.is_riding() and player.get_stance() == PlayerController.Stance.RIDING, 5.0)
	await wait_frames(2)
	ghud._poll_quest()
	assert_eq(ghud.quest_card.objective, "Batı yoluna çık")
	# Yolda tırısla (Shift basılı) eşiğe: kampın son yurtlarının ve çitin ötesi.
	var ride := {"top": 0.0}
	await _wait_until(func() -> bool:
		if scene.current_phase() == "ride" and player.is_active():
			player.auto_move = _steer_input(player, world.marker("road_end") + Vector3(-8.0, 0.0, 0.0))
			player.auto_sprint = true
			ride["top"] = maxf(float(ride["top"]), player.get_speed())
		return scene.current_phase() != "ride", 60.0)
	assert_eq(scene.current_phase(), "look_back", "Eşikte arkaya bakış")
	assert_true(float(ride["top"]) <= mount.trot_speed() + 0.05, "En çok tırıs (%.2f m/sn)" % float(ride["top"]))
	assert_true(float(ride["top"]) > mount.walk_speed() + 1.0, "Shift tırısa kaldırır (%.2f m/sn)" % float(ride["top"]))
	assert_true(scene.ride_distance > 70.0, "Kamptan batıya yol alındı (%.0f m)" % scene.ride_distance)
	assert_true(player.global_position.x <= world.marker("road_end").x + 0.1, "Eşiğin ötesinde")
	assert_false(player.is_active(), "Eşikte girdi sahnenin")
	assert_true(player.is_riding(), "At yolda yürür")
	await wait_frames(3)
	var cam: FollowCamera = main.follow_camera
	assert_ne(cam.target, player, "Odak atlı ile arkada kalan kampın arası")
	assert_eq(cam.get_preset_id(), &"depart_look_back", "Sahnenin kadrajı")
	assert_almost(cam.get_target_distance(), 40.0, 0.01, "Uzak kare: 40 m (K98)")
	var at_back := player.global_position
	await _wait_until(func() -> bool: return scene.current_phase() == "fade", 10.0)
	assert_eq(scene.current_phase(), "fade", "Arkaya bakıştan sonra perde iner")
	# Sözler Voice yolunda çaldı (E20/7): Yançi, Eskam, Lan Hatun; dizginde Mete'nin cevabı ve Lan Hatun'un son sözü.
	for id in ["yanchi_bow", "eskam_road", "lan_days", "mete_count", "lan_home", "eskam_ride"]:
		assert_true(voiced.has("act0.depart." + id), "%s sesli çaldı (%s)" % [id, voiced])
	if audio and audio.line_started.is_connected(on_line):
		audio.line_started.disconnect(on_line)
	assert_almost(cam.current_pitch(), 38.0, 0.05, "38° (K98; geçiş bitti)")
	assert_true(player.global_position.x < at_back.x - 2.0, "At batıya yürür (%.1f m)" % (at_back.x - player.global_position.x))
	assert_true(player.get_speed() <= mount.walk_speed() + 0.2, "Adımla (%.2f m/sn)" % player.get_speed())
	# Arkada kalan kamp karede: kampın dış yurtları ve çit kameranın önünde, ekranın içinde.
	var view := cam.camera.get_viewport().get_visible_rect()
	for id in ["camp_view", "road_gate"]:
		var p := world.marker(id)
		assert_false(cam.camera.is_position_behind(p), "%s kameranın önünde" % id)
		assert_true(view.has_point(cam.camera.unproject_position(p)), "%s karede" % id)
	var yurt := world.place("kin_k").global_position
	assert_true(view.has_point(cam.camera.unproject_position(yurt)), "Kampın son yurtları karede")
	assert_true(view.has_point(cam.camera.unproject_position(player.global_position)), "Atlı karede")
	await _wait_until(func() -> bool: return main.flow_stage_id() == "bridge_2", 15.0)
	Engine.time_scale = 1.0
	get_tree().process_frame.disconnect(measure)
	assert_eq(people.over(PaceLimit.ADULT_RUN), PackedStringArray(), "Kişiler yetişkinin koşusunu aşmaz: %s" % people.report(PaceLimit.ADULT_RUN))
	assert_true(people.peaks.size() >= 4, "Kişiler ölçüldü")
	assert_eq(main.flow_stage_id(), "bridge_2", "Yola Çıkış'tan sonra Köprü 2")
	assert_true(main.journey.has_flag("mq0_depart"), "Yola Çıkış bitti işareti")
	assert_null(main._depart_world, "Dünya bırakıldı")
	assert_null(main._depart_scene, "Sahne bırakıldı")
	assert_false(player.visible, "Mete gizli")
	assert_false(player.is_riding(), "Attan kalktı")
	await _wait_until(func() -> bool: return main.state == main.State.MENU, 30.0)
	get_tree().process_frame.disconnect(probe)
	assert_eq(main.state, main.State.MENU, "Köprü 2'den sonra (yalnız bu aşamalar) açılış ekranı")
	assert_false(_camp_play, "Kampa inilmedi")
	assert_false(_saved, "Kayıt yazılmadı")
	assert_eq(DirAccess.get_files_at(_dir).size(), 0, "Kayıt klasörü boş")


func _assert_pause_blocks_saving(main: Node) -> void:
	main.player.pause_requested.emit()
	await _wait_until(func() -> bool: return main.pause_menu.is_open(), 3.0)
	await wait_frames(2)
	var book: GameMenu = main.pause_menu.get_menu()
	assert_not_null(book, "Duraklatma kitabı")
	if book == null:
		return
	assert_false(book.can_save, "Yola Çıkış'ta kaydedilmez")
	var general := book.get_page() as GeneralPage
	if general:
		assert_true(general.get_button("save").disabled, "KAYDET kapalı")
		var note := general.find_child("SaveNote", true, false) as Label
		if note:
			assert_eq(note.text, main.DEPART_SAVE_NOTE)
		var place := general.find_child("Place", true, false) as Label
		if place:
			assert_eq(place.text, "Tanhu Kampı · Yola Çıkış", "Kartta yer")
	book.close()
	await _wait_until(func() -> bool: return main.state == main.State.PLAYING, 3.0)
	assert_eq(main.state, main.State.PLAYING, "Devam")


## Sahte kişi klasörü: dört kişi glb'siz, meta.json'larında yer tutucu; Lan Hatun'unki gerçek kaydı (yer tutuculu) kopyalanır.
func _fake_actor_root() -> String:
	var root := _dir.path_join("characters")
	for id in PEOPLE:
		DirAccess.make_dir_recursive_absolute(root.path_join(id))
		var meta := StandIn.meta(id)
		if STAND_INS.has(id):
			meta["stand_in"] = {"model": STAND_INS[id][0], "tint": "#e8dccc", "scale": STAND_INS[id][1]}
		var f := FileAccess.open(root.path_join(id).path_join(StandIn.META_FILE), FileAccess.WRITE)
		f.store_string(JSON.stringify(meta))
		f.close()
	return root


func _new_main() -> Node:
	var main = load(MAIN_SCENE).instantiate()
	main.quit_handler = func() -> void: pass
	main.saves = SaveSystem.new(_dir)
	main.prologue_path = ""
	add_child(main)
	await wait_frames(3)
	main.menu.finish_intro()
	await wait_frames(1)
	return main


func _free_main(main: Node) -> void:
	Engine.time_scale = 1.0
	main.get_viewport().disable_3d = false
	main.queue_free()
	var audio := get_node_or_null(^"/root/AudioManager")
	if audio:
		for p in audio.get_children():
			if p is AudioStreamPlayer:
				(p as AudioStreamPlayer).stop()
				(p as AudioStreamPlayer).stream = null
	await get_tree().create_timer(0.3).timeout


## Dünya noktasına giden yönün kameraya göre girdisi (W ekranda yukarı; DepartAutoplay._steer gibi).
func _steer_input(player: PlayerController, to: Vector3) -> Vector2:
	var dir := Vector2(to.x - player.global_position.x, to.z - player.global_position.z).normalized()
	var cy := player.camera_yaw()
	var forward := Vector2(-sin(cy), -cos(cy))
	var right := Vector2(cos(cy), -sin(cy))
	return Vector2(dir.dot(right), dir.dot(forward)).limit_length(1.0)


func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _wait_until(condition: Callable, timeout: float) -> void:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
