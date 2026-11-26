extends TestCase
## Çocukluk «Koyun Sırtında»nın saati, sayımı ve kalabalığı (childhood-p2: childhood-scene, childhood-count; story.md §5, time.md §6, K67, K98):
##   - Veri: saat 08:40'ta açılır, sayımın vakti 11:00; Teoman ata binmiş, üç bey atlı; yol hattın ucundan gelir, çocuğun önünden geçer.
##   - Atlı düzeni (RiderColumn, saf): geçiş noktasına adım hızına inerek varır (durmaz), bırakılınca tırısla gider; beyler yanda ve geride;
##     bakış dönüşleri omurgadan başa toplamı tutar; odak Mete'yi karede tutar.
##   - Kalabalık (CrowdPlan, CrowdCards): saatle toplanır (08:40'ta erkenler, 11:00'de hepsi yerinde), atlıların yolunu ve çocukları
##     açık bırakır, uzaktadır; kişi başına 2 üçgenlik kart, tek çizim, gölgesiz (kart kademesi); atlas eksiksiz.
##   - Sürünün sayım süresi tahmini (HerdSim.count_eta) azalır, sayım bitince 0. Ağılda kalan koyunlar çocuk arkalarına yürüyünce çıkar.
##   - Binme adımı: önce geride kalan koyunlar çıkarılır («Koyunları ağıldan sen çıkaracaksın.»), yaşlı koyun yavaştır, taşta inilir.
##   - Sahnede (ana sahne, Yeni Oyun akışı): saat 08:40'ta açılır, 2,5 sn = 1 oyun dk akar, ışık izler, duraklatma ve bloklayan söz durdurur;
##     nişanda 90 sn'de Yançi hedefi gösterir, ıska ve uzun süre ceza değildir; sayımda saat görünür akışla 11:00'e yetişir, kalabalık toplanır,
##     söz sırası (Luhun uyarır, Luhun sözsüz, Yançi kuşuyla sayılır) saati durdurur, Teoman ve üç bey ata binmiş hâlde hattın ucundan gelir, Mete'nin önünden
##     adımla geçer (durmaz), Teoman dört saniye Mete'ye bakar (uzak kare, 26 m, odak ikisinin ortası), atlılar geçip gider, sonra «Beni gördü.»;
##     fareyi vuran için «İki kuş, bir fare.» ve child_spared yazılmaz.
##   - Hız sınırı (E20): atlılar ve kalabalık çocuğun koşusunu (3,6 m/sn) aşmaz; görünür akışta kalabalık yürüyerek yetişir.

const MAIN_SCENE := "res://scenes/main.tscn"
const ORDOS := "res://scenes/maps/childhood_ordos.tscn"
const LAYOUT := "res://data/maps/childhood_ordos/layout.json"
const TempDir := preload("res://tests/support/temp_dir.gd")

var _dir := ""
var _warm: Array = []


func before_each() -> void:
	MenuStyle.muted = true
	Engine.time_scale = 1.0
	CineVideo.enabled = false
	_dir = TempDir.fresh("cocukluk_sahne")


func after_each() -> void:
	Engine.time_scale = 1.0
	CineVideo.enabled = true
	get_tree().paused = false
	TempDir.wipe(_dir)


# --- Veri (saf) ----------------------------------------------------------------------------------------------

func test_data_opens_at_0840_and_counts_at_1100_with_mounted_riders() -> void:
	var d := ChildhoodScene.load_data()
	assert_eq(ChildhoodScene.validate(d), PackedStringArray(), "Veri sorunsuz")
	assert_eq(int(d["day_n"]), -5600, "22 Eylül MÖ 228")
	assert_almost(GameClock.parse_hhmm(d["clock"]["start"]), 520.0, 1e-9, "08:40'ta açılır")
	var count: Dictionary = (d["steps"] as Array)[3]
	assert_eq(str(count["id"]), "count")
	assert_almost(GameClock.parse_hhmm(count["beat"]["at"]), 660.0, 1e-9, "Sayımın vakti 11:00")
	var proc: Dictionary = count["procession"]
	assert_eq(str(proc["leader"]), "teoman")
	assert_true(str(d["actors"]["teoman"].get("horse", "")).begins_with("horse_"), "Teoman ata binmiş")
	assert_true((proc["escort"] as Array).size() >= 3, "En az üç atlı")
	for e: Dictionary in proc["escort"]:
		assert_true(StandIn.has_model(str(e["model"])), "Atlının modeli")
		assert_true(ResourceLoader.exists(ChildhoodScene.HORSE_DIR % [e["horse"], e["horse"]]), "Atlının atı")
	# Yol hattın güney ucundan gelir, hattın doğusundan geçer, çocuğun önünden geçip kuzeye gider.
	var layout := OrdosWorld.load_layout(LAYOUT)
	var line_south := OrdosGround._vec2(layout["counting_line"]["to"])
	var child := OrdosGround._vec2(layout["childhood"]["markers"]["children_at_line"])
	var pts := PackedVector2Array()
	for p: Array in proc["path"]:
		pts.append(Vector2(float(p[0]), float(p[1])))
	var column := RiderColumn.new(pts)
	assert_true(_path_distance(pts, line_south) < 6.0, "Yol hattın ucundan geçer")
	var closest := column.point_at(column.closest_offset(child))
	assert_between(closest.distance_to(child), 5.0, 12.0, "Çocuğun önünden, uzak karede okunur uzaklıkta geçer (%.1f m)" % closest.distance_to(child))
	assert_true(pts[pts.size() - 1].y < child.y - 30.0, "Geçip gider (kuzeye)")
	var gaze: Dictionary = count["gaze"]
	assert_almost(float(gaze["seconds"]), 4.0, 1e-9, "Dört saniye")
	assert_true(float(gaze["camera_distance"]) >= FollowCamera.CHILD_DISTANCE, "Uzak kare (K98)")
	assert_eq(str(gaze["line"]), "saw_me")
	# Söz sırası (E20/7): Luhun önce uyarır («Tanhu geçerken yere bak.»), Luhun sözsüz sayılır, Yançi sayılınca kuşunu da saydırır (ikinci
	# çentik), sonra Mete («Bir çocuk.»).
	var ex: Array = count["exchange"]
	assert_eq(str((ex[0] as Dictionary).get("line", "")), "look_down")
	assert_false((ex[1] as Dictionary).has("line"), "Luhun sözsüz sayılır")
	assert_eq(str(ex[3]["line"]), "my_bird")
	assert_true(bool((ex[4] as Dictionary).get("notch", false)) and not (ex[4] as Dictionary).has("line"), "Kuş için ikinci çentik")
	assert_eq(str(ex[5]["line"]), "count_child")


# --- Atlı düzeni (saf) -------------------------------------------------------------------------------------------

func test_column_slows_to_a_walk_and_never_stops() -> void:
	var column := RiderColumn.new(PackedVector2Array([Vector2(0, 60), Vector2(0, 0), Vector2(0, -60)]))
	column.pass_at = column.closest_offset(Vector2(8.0, 0.0)) - 2.5
	assert_almost(column.pass_at, 57.5, 0.1)
	var seconds := 9.0
	column.start(column.start_offset_for(seconds))
	var t := 0.0
	var min_speed := INF
	while not column.at_pass() and t < 30.0:
		column.tick(1.0 / 60.0)
		t += 1.0 / 60.0
		min_speed = minf(min_speed, column.speed)
	assert_almost(t, seconds, 0.35, "Söz sırası biterken geçiş noktasında (%.2f sn)" % t)
	assert_almost(column.speed, column.pass_speed, 0.15, "Adım hızına inmiş")
	assert_true(min_speed >= column.pass_speed - 0.05, "Yaklaşırken durmaz")
	assert_eq(RideableHorse.role_for(column.speed, &"walk"), &"walk", "Geçerken adım")
	assert_eq(RideableHorse.role_for(column.approach, &"trot"), &"trot", "Tırısla gelir")
	for i in 240:
		column.tick(1.0 / 60.0)
	assert_true(column.speed >= column.pass_speed - 0.01, "Bırakılmadan da durmaz")
	column.release()
	for i in 240:
		column.tick(1.0 / 60.0)
	assert_almost(column.speed, column.leave, 0.05, "Bırakılınca tırısla gider")
	# Profil (saf).
	assert_almost(RiderColumn.profile(0.0, 50.0, 3.6, 1.25, 1.5, false, 4.4), 3.6, 1e-6)
	assert_almost(RiderColumn.profile(50.0, 50.0, 3.6, 1.25, 1.5, false, 4.4), 1.25, 1e-6)
	assert_almost(RiderColumn.profile(10.0, 50.0, 3.6, 1.25, 1.5, true, 4.4), 4.4, 1e-6)


func test_column_formation_keeps_the_left_side_clear() -> void:
	# Kuzeye (−z) giden düzen: liderin solu batıdır (−x). Beyler sağda (doğu) ve geride; çocuğa bakan yan açık kalır.
	var column := RiderColumn.new(PackedVector2Array([Vector2(34, 20), Vector2(34, -40)]))
	column.add(null, Vector2.ZERO)
	column.add(null, Vector2(-1.9, 3.0))
	column.add(null, Vector2(0.3, 6.2))
	column.s = 30.0
	var lead: Dictionary = column.member_pose(0)
	var bey: Dictionary = column.member_pose(1)
	var back: Dictionary = column.member_pose(2)
	assert_vec_almost(Vector3((lead["xz"] as Vector2).x, 0, (lead["xz"] as Vector2).y), Vector3(34, 0, -10), 0.05)
	assert_true((bey["xz"] as Vector2).x > 34.0 + 1.5, "Bey liderin sağında (doğu)")
	assert_true((bey["xz"] as Vector2).y > -10.0 + 2.5, "Bey geride")
	assert_true((back["xz"] as Vector2).y > -10.0 + 5.5, "Arkadaki bey geride")
	assert_almost(absf(angle_difference(float(lead["yaw"]), PI)), 0.0, 0.01, "Yüzü kuzeye")
	# Bakış: dönüşler omurgadan başa toplamı verir, işaret korunur (+ sol).
	var turns := RiderColumn.look_turns(60.0)
	var sum := 0.0
	for t: Array in turns:
		assert_eq(str(t[1]), "up")
		sum += float(t[2])
	assert_almost(sum, 60.0, 1e-6)
	assert_eq(str((turns[turns.size() - 1] as Array)[0]), "Head", "Baş en çok döner")
	# Odak: Mete ile Teoman'ın ortası, Mete'den en çok 8,5 m.
	var mid := RiderColumn.midpoint_focus(Vector3(26.4, 1.0, -14.5), Vector3(34.0, 2.0, -14.5), 8.5)
	assert_vec_almost(mid, Vector3(30.2, 1.0, -14.5), 0.001)
	var far := RiderColumn.midpoint_focus(Vector3(0, 0, 0), Vector3(0, 0, -40.0), 8.5)
	assert_almost(far.z, -8.5, 0.001, "Mete karede kalır")


# --- Kalabalık (saf ve düğüm) -------------------------------------------------------------------------------------

func test_crowd_gathers_with_the_clock_and_keeps_the_lanes_clear() -> void:
	var layout := OrdosWorld.load_layout(LAYOUT)
	var spec: Dictionary = layout["childhood"]["crowd"]
	var blockers := ChildhoodSite.crowd_blockers(layout)
	var plan := CrowdPlan.build(spec, blockers)
	var again := CrowdPlan.build(spec, blockers)
	assert_true(plan.size() >= 120, "Dailin kalabalığı (%d kişi)" % plan.size())
	assert_eq(plan.size(), again.size(), "Tohumlu")
	assert_vec_almost(_v3(plan[17]["spot"]), _v3(again[17]["spot"]), 1e-6, "Aynı düzen aynı kalabalık")
	var early := CrowdPlan.counts(plan, 520.0)
	assert_true(int(early["standing"]) > 10 and int(early["standing"]) < plan.size() / 2, "08:40'ta erkenler yerinde (%d)" % int(early["standing"]))
	var mid := CrowdPlan.counts(plan, 625.0)
	assert_true(int(mid["walking"]) > 0, "Sayıma doğru kalabalık yolda (%d)" % int(mid["walking"]))
	var late := CrowdPlan.counts(plan, 660.0)
	assert_eq(int(late["standing"]), plan.size(), "11:00'de hepsi yerinde")
	var child := OrdosGround._vec2(layout["childhood"]["markers"]["children_at_line"])
	var gap := float(spec["min_gap"])
	for i in plan.size():
		var p: Vector2 = plan[i]["spot"]
		assert_true(p.distance_to(child) >= 8.0, "Uzakta: çocuklardan ≥8 m (%s)" % p)
		for c: Dictionary in spec["keep_clear"]:
			var a := OrdosGround._vec2(c["a"])
			var b := OrdosGround._vec2(c.get("b", c["a"]))
			assert_true(Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p) >= float(c["r"]) - 0.001, "Açık yolda kimse durmaz (%s)" % p)
		for b in blockers:
			assert_true(p.distance_to(Vector2(b.x, b.y)) >= b.z - 0.001, "Yurt ve eşyanın içinde değil (%s)" % p)
		for j in range(i + 1, plan.size()):
			assert_true(p.distance_to(plan[j]["spot"]) >= gap - 0.001, "Kişiler üst üste değil")
		if failures.size() > 3:
			return
	# Yürüyen kişi yolunda ilerler, belirerek gelir.
	var walker: Dictionary = {}
	for p: Dictionary in plan:
		if not bool(p["early"]):
			walker = p
			break
	var half := lerpf(float(walker["from"]), float(walker["to"]), 0.5)
	var pose := CrowdPlan.pose_at(walker, half)
	assert_eq(int(pose["state"]), CrowdPlan.State.WALK)
	assert_almost(float(pose["walked"]), float(walker["length"]) * 0.5, 0.01)
	assert_almost(float(CrowdPlan.pose_at(walker, float(walker["from"]) + 0.0001)["presence"]), 0.0, 0.05, "Belirerek gelir")
	assert_eq(int(CrowdPlan.pose_at(walker, float(walker["from"]) - 1.0)["state"]), CrowdPlan.State.ABSENT)


func test_crowd_is_card_tier() -> void:
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/crowd/dailin_cards.json"))
	var cells := (meta["variants"] as Array).size() * int(meta["dirs"]) * (meta["frames"] as Array).size()
	assert_true(cells <= int(meta["cols"]) * int(meta["rows"]), "Hücreler atlasa sığar")
	assert_eq(int(meta["dirs"]), 8, "8 yön (army.md §7.4)")
	for path in ChildhoodSite.crowd_texture_paths("res://assets/crowd/dailin_cards.json"):
		var tex := load(path) as Texture2D
		assert_not_null(tex, path)
		if tex:
			assert_eq(Vector2i(tex.get_size()), Vector2i(int(meta["atlas_px"][0]), int(meta["atlas_px"][1])), "Atlasın boyu")
	var layout := OrdosWorld.load_layout(LAYOUT)
	var plan := CrowdPlan.build(layout["childhood"]["crowd"], ChildhoodSite.crowd_blockers(layout))
	var crowd := CrowdCards.new()
	crowd.setup(plan, null, meta, load("res://assets/crowd/dailin_cards.png"), load("res://assets/crowd/dailin_cards_normal.png"))
	add_child(crowd)
	crowd.set_minute(660.0)
	await wait_frames(2)
	var cards := crowd.cards_node()
	assert_eq(cards.multimesh.instance_count, plan.size(), "Kişi başına bir kart")
	assert_eq(_triangles(cards.multimesh.mesh), 2, "Kart 2 üçgen (T3)")
	assert_eq(cards.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "Kart gölge düşürmez")
	var draws := 0
	for node in crowd.find_children("*", "MultiMeshInstance3D", true, false):
		draws += 1
		assert_eq((node as GeometryInstance3D).cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	assert_eq(draws, 2, "İki çizim: kartlar ve temas lekeleri")
	assert_eq(int(crowd.counts()["standing"]), plan.size())
	# İzleme: duran kişiler atlılara döner.
	var target := Vector3(34.0, 0.0, -14.5)
	crowd.watch(target)
	for i in 120:
		crowd._process(1.0 / 30.0)
	var turned := 0
	for i in plan.size():
		var spot: Vector2 = plan[i]["spot"]
		var want := atan2(target.x - spot.x, target.z - spot.y)
		if absf(angle_difference(crowd.shown_yaw(i), want)) < 0.05:
			turned += 1
	assert_true(turned >= plan.size() * 9 / 10, "Kalabalık Teoman'a döner (%d / %d)" % [turned, plan.size()])
	crowd.queue_free()
	await wait_frames(1)


func test_herd_count_eta_shrinks_to_zero() -> void:
	var layout := OrdosWorld.load_layout(LAYOUT)
	var sim := HerdSim.new(layout["childhood"], {"walk": 1.1, "trot": 2.5})
	sim.place_on_meadow()
	assert_almost(sim.count_eta(), 0.0, 1e-9, "Sürüş yokken 0")
	sim.drive()
	var first := sim.count_eta()
	assert_true(first > 20.0, "Sürü uzakta: sayım sürer (%.1f sn)" % first)
	var last := first
	for tick in 2000:
		sim.step()
		if tick % 20 == 0 and sim.counted_total() < sim.count:
			var eta := sim.count_eta()
			assert_true(eta <= last + HerdSim.TICK * 20.0 + 3.0, "Tahmin azalır")
			last = eta
		if sim.counted_total() == sim.count:
			break
	assert_eq(sim.counted_total(), sim.count)
	assert_almost(sim.count_eta(), 0.0, 1e-9, "Sayılınca 0")
	print("    [sayım] ilk tahmin %.1f sn, gerçek %.1f sn" % [first, sim.clock])
	assert_true(sim.clock <= first * 1.6 + 5.0, "Tahmin gerçeğe yakın")


func test_stragglers_stay_in_the_pen_until_the_child_walks_behind_them() -> void:
	# «Koyunları ağıldan sen çıkaracaksın.»: kapıdan en uzaktaki beş koyun ağılda kalır, çocuk yaklaşınca çıkar.
	var layout := OrdosWorld.load_layout(LAYOUT)
	var spec: Dictionary = layout["childhood"]
	var sim := HerdSim.new(spec, {"walk": 1.1, "trot": 2.5})
	sim.release(null, -1.0, 5)
	assert_eq(sim.held_count(), 5, "Beş koyun geride")
	var released := [false]
	for tick in 400:
		sim.step()
		for ev: Dictionary in sim.events:
			if ev["type"] == &"released":
				released[0] = true
	assert_eq(sim.released_total(), 35, "Öteki 35 koyun kendiliğinden çıkar")
	assert_false(bool(released[0]), "Sürü daha bütün çıkmadı")
	assert_eq(sim.phase, HerdSim.Phase.LEAVING)
	var pen := OrdosGround._vec2(spec["pen"]["at"])
	for p in sim.held_positions():
		assert_true(p.distance_to(pen) < float(spec["pen"]["radius"]), "Geride kalan ağılın içinde")
	# Çocuk birinin arkasına yürür: ona (ve yanındakilere) NUDGE_RADIUS içinde olanlar çıkar, uzaktakiler kalır.
	var first := sim.held_positions()[0]
	var child := Vector2(first.x - 1.0, first.y)
	var near := 0
	for p in sim.held_positions():
		if p.distance_to(child) <= HerdSim.NUDGE_RADIUS:
			near += 1
	sim.avoid = [Vector3(child.x, child.y, 0.35)]
	sim.step()
	assert_true(near >= 1)
	assert_eq(sim.held_count(), 5 - near, "Yaklaşılan koyunlar yola düşer, uzaktakiler kalır")
	sim.avoid = []
	for tick in 200:
		sim.step()
		for ev: Dictionary in sim.events:
			if ev["type"] == &"released":
				released[0] = true
	assert_eq(sim.released_total(), 35 + near, "Dürtülen koyunlar kapıdan çıktı")
	# Yaşlı koyun binicisiyle çıkınca geride kalanlar ardından gelir.
	sim.release_held()
	assert_eq(sim.held_count(), 0)
	for tick in 600:
		sim.step()
		for ev: Dictionary in sim.events:
			if ev["type"] == &"released":
				released[0] = true
		if sim.phase == HerdSim.Phase.MEADOW:
			break
	assert_true(bool(released[0]), "Sürünün hepsi çıktı")
	assert_eq(sim.phase, HerdSim.Phase.MEADOW, "Çayıra yayıldı")
	# hold'suz salma eskisi gibi: hepsi çıkar.
	var plain := HerdSim.new(spec, {"walk": 1.1, "trot": 2.5})
	plain.release()
	assert_eq(plain.held_count(), 0)


# --- Sahnede ------------------------------------------------------------------------------------------------------

func test_clock_flows_light_follows_and_pause_stops_it() -> void:
	var main := await _start_main("wake")
	var scene: ChildhoodScene = main._childhood_scene
	assert_not_null(scene)
	if scene == null:
		await _free_main(main)
		return
	var ordos: OrdosWorld = main._childhood_world
	assert_eq(scene.clock_text(), "08:40", "Sahne 08:40'ta açılır")
	assert_eq(scene.game_clock.day_n, -5600, "22 Eylül MÖ 228")
	assert_eq(GameCalendar.format_tr(scene.game_clock.day_n), "22 Eylül MÖ 228")
	var m0 := scene.minute()
	var s0 := scene.clock
	await get_tree().create_timer(2.0).timeout
	var flowed := scene.minute() - m0
	var real := scene.clock - s0
	assert_almost(flowed, real / 2.5, 0.05, "2,5 sn = 1 oyun dk (%.3f dk / %.2f sn)" % [flowed, real])
	await wait_frames(20)
	assert_almost(float(ordos.get(&"_childhood_minute")), scene.minute(), 0.15, "Işık saati izler")
	var sun_el := float((ordos.get_sky_rig().current_sample()["sun"] as Dictionary)["el"])
	assert_between(sun_el, 29.0, 32.0, "08:40'ta güneş ≈30° (%.1f)" % sun_el)
	# Duraklatma kitabı ağacı durdurur: saat durur.
	main.player.pause_requested.emit()
	await _wait_until(func() -> bool: return main.pause_menu.is_open(), 3.0)
	var held := scene.minute()
	await get_tree().create_timer(1.5).timeout
	assert_almost(scene.minute(), held, 1e-6, "Duraklatmada saat durur")
	main.pause_menu.get_menu().close()
	await _wait_until(func() -> bool: return main.state == main.State.PLAYING, 3.0)
	await wait_frames(30)
	assert_true(scene.minute() > held, "Devamda saat akar")
	# Bloklayan söz (dialogue) saati durdurur.
	scene.game_clock.pause(&"dialogue", true)
	var at := scene.minute()
	await wait_frames(30)
	assert_almost(scene.minute(), at, 1e-6, "Bloklayan sözde saat durur")
	scene.game_clock.pause(&"dialogue", false)
	await _free_main(main)


func test_ride_lets_the_sheep_out_and_ends_with_getting_off() -> void:
	var main := await _start_main("ride")
	var scene: ChildhoodScene = main._childhood_scene
	assert_not_null(scene)
	if scene == null:
		await _free_main(main)
		return
	var ordos: OrdosWorld = main._childhood_world
	var site := ordos.childhood()
	assert_eq(scene.current_step_id(), "ride")
	assert_eq(scene.current_phase(), "herd", "Önce geride kalan koyunlar")
	assert_eq(scene.hud.objective_text(), "Koyunları ağıldan çıkar", "Lan Hatun'un dediği iş")
	assert_true(site.herd.held_count() > 0, "Ağılda koyun kaldı")
	var held := site.herd.held_positions()
	assert_vec_almost(scene.hud_target(main.player.global_position), _nearest3(held, main.player.global_position), 0.5, "Yön en yakın koyunda")
	# Yaşlı koyunun huyu: yavaş ve sık otlar (yalnız bu koyunun satırı).
	var old: RideableSheep = scene.sheep["old_sheep"]
	var fast: RideableSheep = scene.sheep["fast_sheep"]
	assert_almost(old.get_mount().value("base"), 2.3, 1e-6, "Yaşlısı yavaş")
	assert_almost(old.get_mount().value("graze_every"), 7.5, 1e-6)
	assert_almost(fast.get_mount().value("base"), float(Mount.row_of("sheep")["base"]), 1e-6, "Hızlısı değişmez")
	# Çocuk her birinin arkasına yürür: hepsi çıkınca amaç «Yaşlı koyuna bin».
	var gate := ordos.marker("pen_gate")
	var deadline := Time.get_ticks_msec() + 30000
	while site.herd.held_count() > 0 and Time.get_ticks_msec() < deadline:
		var p := _nearest3(site.herd.held_positions(), main.player.global_position)
		var away := Vector3(p.x - gate.x, 0.0, p.z - gate.z).normalized()
		main.player.spawn_at(p + away * 1.2, 0.0)
		await wait_frames(20)
	assert_eq(site.herd.held_count(), 0, "Geride koyun kalmadı")
	await wait_frames(2)
	assert_eq(scene.current_phase(), "mount")
	assert_eq(scene.hud.objective_text(), "Yaşlı koyuna bin")
	main.player.spawn_at(old.global_position + Vector3(0.0, 0.0, 0.85), PI)
	assert_true(main.player.interact(), "E biner")
	await _wait_until(func() -> bool: return main.player.is_riding(), 3.0)
	await wait_frames(2)
	assert_eq(scene.hud.objective_text(), "Luhun'la taşa yarış")
	await _wait_until(func() -> bool: return scene.said_lines.has("race"), 6.0)
	assert_true(scene.said_lines.has("race"), "Luhun: «Yaşlısı senin, hızlısı benim.»")
	# Taşa binekle varılır: önce inilir («bin, sür, in»), sonra nişan.
	var stone := ordos.marker("race_stone")
	# Binicinin düğümü sürüşün kaynağıdır: koyun onun altına konur.
	main.player.global_position = stone + Vector3(-1.6, 0.0, 0.0)
	await wait_frames(3)
	await _wait_until(func() -> bool: return scene.current_phase() == "dismount", 3.0)
	assert_eq(scene.current_phase(), "dismount", "Taşta inme")
	assert_eq(scene.hud.objective_text(), "Koyundan in")
	assert_eq(scene.current_step_id(), "ride", "İnmeden nişan başlamaz")
	assert_true(main.player.interact(), "E iner")
	await _wait_until(func() -> bool: return scene.current_step_id() == "hunt", 4.0)
	assert_eq(scene.current_step_id(), "hunt", "İnince nişan")
	scene.stop()
	assert_almost(old.get_mount().value("base"), float(Mount.row_of("sheep")["base"]), 1e-6, "Sahne bitince yaşlı koyunun satırı geri döner")
	await _free_main(main)


func test_hunt_has_no_penalty_and_yanchi_points_at_ninety_seconds() -> void:
	var main := await _start_main("hunt")
	var scene: ChildhoodScene = main._childhood_scene
	assert_not_null(scene)
	if scene == null:
		await _free_main(main)
		return
	assert_eq(scene.current_step_id(), "hunt")
	assert_eq(scene.hud.objective_text(), "İki tarla kuşu vur ve al (0/2)")
	assert_false(scene.is_pointing(), "Başta gösterilmez")
	# Iska: ok kuşun 3 m yanına düşer; ceza yok, amaç ve av aynı.
	var site: ChildhoodSite = main._childhood_world.childhood()
	var lark: SmallGame = _free_lark(scene, site)
	if lark and main.player.archer() and main.player.archer().field:
		main.player.spawn_at(lark.global_position + Vector3(8.0, 0.0, 0.0), -PI * 0.5)
		var from: Vector3 = main.player.global_position + Vector3.UP * 0.6
		main.player.archer().field.fire(from, lark.global_position + Vector3(0.0, 0.0, 3.0), {"speed": 14.0, "blunt": true, "drift": 0.0})
		await get_tree().create_timer(1.5).timeout
		assert_true(scene.is_running(), "Iska ceza değil")
		assert_eq(int(scene.catch["lark"]), 0, "Iska av saymaz")
		assert_eq(scene.hud.objective_text(), "İki tarla kuşu vur ve al (0/2)", "Amaç aynı")
	scene.step_clock = 89.5
	await wait_frames(5)
	assert_false(scene.is_pointing(), "90 sn dolmadan gösterilmez")
	await _wait_until(func() -> bool: return scene.is_pointing(), 3.0)
	assert_true(scene.is_pointing(), "90 sn'de Yançi hedefi gösterir")
	assert_not_null(scene.shown_target(), "Gösterilen kuş")
	assert_eq(scene.hud.hint_text(), "Yançi bir kuşu gösteriyor.")
	assert_true((scene.get("_ring") as MeshInstance3D).visible, "Kuşun altında halka")
	# Çok uzun süre de ceza değildir: sahne sürer, amaç aynı.
	scene.step_clock = 600.0
	await wait_frames(5)
	assert_true(scene.is_running())
	assert_eq(scene.current_step_id(), "hunt")
	assert_eq(scene.hud.objective_text(), "İki tarla kuşu vur ve al (0/2)")
	assert_eq(int(scene.catch["lark"]), 0)
	await _free_main(main)


func test_count_beat_riders_gaze_and_the_mouse() -> void:
	var main := await _start_main("count")
	var scene: ChildhoodScene = main._childhood_scene
	assert_not_null(scene)
	if scene == null:
		await _free_main(main)
		return
	var ordos: OrdosWorld = main._childhood_world
	var site := ordos.childhood()
	assert_eq(scene.current_step_id(), "count")
	assert_eq(scene.clock_text(), "10:28", "Atlanan adımlarda saat tasarımın anında (08:40 + 270 / 2,5 dk)")
	assert_true(scene.escort.size() >= 3, "Üç bey")
	var teoman: CineActor = scene.actors["teoman"]
	assert_false(teoman.visible, "Teoman henüz yok")
	assert_not_null(site.crowd, "Kalabalık kurulu")
	# Fareyi vurmuş Mete: «İki kuş, bir fare.», child_spared yazılmaz.
	scene.catch["gerbil"] = 1
	scene.mouse_hit = true
	# Sözler seslidir (E20/7): Voice yolunda başlayan satırlar.
	var voiced: Array[String] = []
	var audio := get_node_or_null(^"/root/AudioManager")
	var on_line := func(id: String) -> void: voiced.append(id)
	if audio:
		audio.line_started.connect(on_line)
	# Mete hatta: saat sürünün sayımına yayılan görünür akışla vakte yetişir.
	main.player.spawn_at(ordos.marker("children_at_line"), PI)
	await _wait_until(func() -> bool: return scene.current_phase() == "wait", 5.0)
	assert_true(scene.game_clock.is_lapsing(), "Saat görünür biçimde akar")
	var crowd_before := int(site.crowd.counts()["standing"])
	Engine.time_scale = 4.0
	var minute_track: Array[float] = []
	await _wait_until(func() -> bool:
		minute_track.append(scene.minute())
		return scene.current_phase() in ["settle", "exchange"], 60.0)
	Engine.time_scale = 1.0
	assert_true(scene.current_phase() in ["settle", "exchange"], "Söz sırası başladı")
	assert_almost(scene.minute(), 660.0, 0.6, "Sayım 11:00'de (%s)" % scene.clock_text())
	assert_true(scene.game_clock.is_paused_by(&"dialogue"), "Söz sırası saati durdurur")
	assert_false(scene.game_clock.is_lapsing())
	var crowd_after := int(site.crowd.counts()["standing"])
	assert_true(crowd_after > crowd_before, "Kalabalık toplandı (%d → %d)" % [crowd_before, crowd_after])
	# E20: saat görünür biçimde akarken kalabalık ışınlanmaz, koşmaz; planda 11:00'de herkes yerindedir, görünen kalabalık yürüyerek yetişir.
	assert_eq(int(site.crowd.planned_counts()["standing"]), site.crowd.size(), "Planda 11:00'de herkes yerinde")
	assert_eq(int(site.crowd.counts()["absent"]), 0, "Yola çıkması gereken herkes yolda ya da yerinde")
	assert_true(site.crowd.peak_speed <= scene.speed_cap() + PaceLimit.TOLERANCE,
		"Kalabalık çocuğun koşusunu aşmaz (%.2f m/sn ≤ %.2f)" % [site.crowd.peak_speed, scene.speed_cap()])
	for i in range(1, minute_track.size()):
		assert_true(minute_track[i] >= minute_track[i - 1] - 1e-6, "Saat geri gitmez")
	# Atlılar: Teoman ve üç bey ata binmiş, hattın ucundan gelir.
	# Sesli söz sırası uzundur (E20/7): atlılar söz sırasının son approach_s saniyesinde yola çıkar.
	await _wait_until(func() -> bool: return teoman.visible, 25.0)
	assert_true(teoman.visible, "Teoman göründü")
	var column := scene.column
	assert_not_null(column, "Atlı düzeni")
	if column == null:
		await _free_main(main)
		return
	assert_true(column.size() >= 4, "Teoman + en az üç atlı")
	for i in column.size():
		var mv := column.mover(i)
		assert_true(mv.is_seated(), "Atlı eyerde (%d)" % i)
		assert_true(mv.ride is RideableHorse, "Bineği at (%d)" % i)
		assert_true(mv.ride.visible and mv.actor.visible, "Görünür (%d)" % i)
	var start_at := column.leader().position()
	var line_south := ordos.marker("line_south")
	assert_true(Vector2(start_at.x - line_south.x, start_at.z - line_south.z).length() < 26.0, "Hattın güney ucundan gelir")
	# Geçiş: adıma iner (durmaz), dört saniye bakar, uzak kare. (Lambda yerel değişkeni kopyalar: ölçüler sözlükte.) Atlıların hızı ölçülür
	# (E20: atlı da çocuğun koşusunu aşmaz).
	var seen := {"min_speed": INF, "trot": false, "look": 0.0, "gaze_speed": INF}
	var probe := PaceLimit.Probe.new()
	var sample := func() -> void:
		for i in column.size():
			var mv := column.mover(i)
			if mv.actor.is_visible_in_tree():
				probe.sample("atli_%d" % i, mv.position(), scene.clock)
			else:
				probe.forget("atli_%d" % i)
	await _wait_until(func() -> bool:
		sample.call()
		if column.running:
			seen["min_speed"] = minf(float(seen["min_speed"]), column.speed)
			if (column.leader().ride as RideableHorse).gait_role() == &"trot":
				seen["trot"] = true
		return scene.current_phase() == "gaze", 30.0)
	assert_eq(scene.current_phase(), "gaze", "Teoman bakıyor")
	assert_true(bool(seen["trot"]), "Atlar tırısla gelir (klip)")
	assert_true(float(seen["min_speed"]) >= column.pass_speed - 0.05, "Atlılar durmaz (en düşük %.2f m/sn)" % float(seen["min_speed"]))
	assert_eq((column.leader().ride as RideableHorse).gait_role(), &"walk", "Geçerken adım")
	var child: Vector3 = main.player.global_position
	var lead := column.leader().position()
	assert_between(Vector2(lead.x - child.x, lead.z - child.z).length(), 4.0, 12.0, "Çocuğun önünden geçer")
	assert_ne(main.follow_camera.target, main.player, "Odak ikisinin ortası")
	assert_almost(main.follow_camera.get_target_distance(), 26.0, 0.01, "Uzak kare: 26 m")
	assert_false(main.player.is_active(), "Oyuncu durur")
	var held := scene.minute()
	await _wait_until(func() -> bool:
		sample.call()
		seen["look"] = maxf(float(seen["look"]), column.look_deg * column.look_amount)
		if scene.current_phase() == "gaze":
			seen["gaze_speed"] = minf(float(seen["gaze_speed"]), column.speed)
		return scene.current_phase() != "gaze", 8.0)
	assert_almost(scene.gaze_seconds, 4.0, 0.1, "Dört saniye bakar (%.2f sn)" % scene.gaze_seconds)
	assert_true(float(seen["look"]) > 40.0, "Teoman başını ve gövdesini sola, Mete'ye çevirir (%.0f°)" % float(seen["look"]))
	assert_true(float(seen["gaze_speed"]) > 0.5, "Bakarken de durmaz (%.2f m/sn)" % float(seen["gaze_speed"]))
	assert_true(site.crowd.is_watching(), "Kalabalık Teoman'a bakar")
	assert_almost(scene.minute(), held, 1e-6, "Geçiş sinemadır: saat durur")
	# Geçip gider, sonra «Beni gördü.»
	var s_at_gaze_end := column.s
	await _wait_until(func() -> bool:
		sample.call()
		return scene.said_lines.has("saw_me"), 8.0)
	assert_eq(probe.peaks.size(), column.size(), "Bütün atlılar ölçüldü")
	assert_eq(probe.over(scene.speed_cap()), PackedStringArray(), "Atlılar çocuğun koşusunu aşmaz: %s" % probe.report(scene.speed_cap()))
	assert_true(scene.said_lines.has("saw_me"), "Mete: «Beni gördü.»")
	assert_true(column.s > s_at_gaze_end + 3.0, "Atlılar geçip gider")
	assert_true(column.speed > column.pass_speed + 0.5, "Tırısla uzaklaşır")
	var order := PackedStringArray()
	for id in scene.said_lines:
		if id in ["count_child", "mete_catch", "mete_catch_spared", "count_answer", "saw_me"]:
			order.append(id)
	assert_eq(order, PackedStringArray(["count_child", "mete_catch", "count_answer", "saw_me"]), "Fareyi vuran: «İki kuş, bir fare.»")
	# Söz sırası ve bekleme sesli (E20/7): Luhun'un uyarısı, Yançi'nin kuşu, sayıcı, Mete; Luhun söz sırasının başında konuşur. Ana söz
	# kısmanın payından (PREROLL) sonra başlar: «Beni gördü.»nün sesi altyazısından az sonra gelir.
	await _wait_until(func() -> bool: return voiced.has("act0.child.saw_me"), 2.0)
	for id in ["sheep_first", "look_down", "my_bird", "count_child", "mete_catch", "count_answer", "saw_me"]:
		assert_true(voiced.has("act0.child." + id), "%s sesli çaldı (%s)" % [id, voiced])
	assert_true(scene.said_lines.find("look_down") < scene.said_lines.find("count_child"), "«Tanhu geçerken yere bak.» sayımdan önce")
	assert_true(scene.said_lines.find("my_bird") < scene.said_lines.find("count_child"), "Yançi kuşunu saydırır, sonra Mete sayılır")
	if audio and audio.line_started.is_connected(on_line):
		audio.line_started.disconnect(on_line)
	var result := scene.result()
	assert_false((result["flags"] as PackedStringArray).has("child_spared"), "Fareyi vurana child_spared yazılmaz")
	assert_true((result["flags"] as PackedStringArray).has("mq0_sheep"))
	await _free_main(main)


# --- Yardımcılar ----------------------------------------------------------------------------------------------------

func _start_main(step: String) -> Node:
	if _warm.is_empty():
		_warm.append(load(ORDOS))
	var main = load(MAIN_SCENE).instantiate()
	main.quit_handler = func() -> void: pass
	main.saves = SaveSystem.new(_dir)
	main.prologue_path = ""
	add_child(main)
	await wait_frames(3)
	main.menu.finish_intro()
	await wait_frames(1)
	main.new_game_from = "childhood"
	main.childhood_step = step
	main.menu.start_requested.emit()
	await _wait_until(func() -> bool: return main.state == main.State.PLAYING and main._childhood_scene != null, 90.0)
	return main


func _free_main(main: Node) -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
	main.get_viewport().disable_3d = false
	main.queue_free()
	var audio := get_node_or_null(^"/root/AudioManager")
	if audio:
		for p in audio.get_children():
			if p is AudioStreamPlayer:
				(p as AudioStreamPlayer).stop()
				(p as AudioStreamPlayer).stream = null
	await get_tree().create_timer(0.3).timeout


func _wait_until(condition: Callable, timeout: float) -> void:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame


func _free_lark(scene: ChildhoodScene, site: ChildhoodSite) -> SmallGame:
	for a: SmallGame in site.game.of_kind("lark"):
		if a != scene.get("_yanchi_bird") and a.is_hittable():
			return a
	return null


static func _nearest3(points: PackedVector3Array, from: Vector3) -> Vector3:
	var best := Vector3.INF
	for p in points:
		if best == Vector3.INF or Vector2(p.x - from.x, p.z - from.z).length() < Vector2(best.x - from.x, best.z - from.z).length():
			best = p
	return best


static func _path_distance(pts: PackedVector2Array, p: Vector2) -> float:
	var best := INF
	for i in range(1, pts.size()):
		best = minf(best, Geometry2D.get_closest_point_to_segment(p, pts[i - 1], pts[i]).distance_to(p))
	return best


static func _triangles(mesh: Mesh) -> int:
	var total := 0
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		var index: Variant = arrays[Mesh.ARRAY_INDEX]
		total += ((index as PackedInt32Array).size() if index != null and (index as PackedInt32Array).size() > 0 else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	return total


static func _v3(p: Vector2) -> Vector3:
	return Vector3(p.x, 0.0, p.y)
