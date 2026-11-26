extends TestCase
## Önsöz'ün oynanan günleri (E21, K110; story.md §3 «Göl Obası'nda üç gün»; docs/design/d3/e21-prologue-api.md):
##   - Sıra: üç gün (8–10 Nisan MÖ 209, dayN 1.168–1.170), kartlar takvimle aynı; sahneler sırayla; --day ve --quest çözülür.
##   - Sözler: data/story/prologue_days/lines.json e21-lines.json'un kopyasıdır (tools/sync_prologue_lines.py); «Süt» ve «Tipi»nin andığı her
##     satır, işaret ve tür vardır.
##   - Yerler (saf): Kayın Obası Göl Obası'nın ≈320 m güneybatısında, menü kadrajının dışında (arkasında); yolun en dik yeri ≤16°; on iki kazık
##     yokuşun başından geçidin önüne eşit arayla; yürünür alan yolu, kazıkları, geçidi ve obanın yerlerini kapsar.
##   - Saf parçalar: sütün dökülmesi (koşu ve geçit), sabanın vuruşu (ritim), rüzgârın itişi, birleşik yürünür alan (PlayerController).
##   - Ana sahnede (Yeni Oyun → Önsöz): kara perdede kart, günün başında kayıt noktası (yolculuğun işaretleri), Çocuk aile yurdunun yatağında
##     uyanır, kampın Önsöz düzeni kurulur (Kayın Obası, yol, kazıklar, açık aile yurdu, kampın halkı gizli), camp3 kurulmaz; Esc basılı tutmak
##     Önsöz'ü atlar ve kampın düzeni geri gelir.

const MAIN_SCENE := "res://scenes/main.tscn"
const TempDir := preload("res://tests/support/temp_dir.gd")
const MILK := "res://data/story/prologue_days/day1_milk.json"
const STORM := "res://data/story/prologue_days/day1_storm.json"
## Kayıt noktasının heybesini sınayan eşya (köz kabı).
const BAG_ITEM := "ember_pot"

var _dir := ""


func before_each() -> void:
	MenuStyle.muted = true
	Engine.time_scale = 1.0
	CineVideo.enabled = false
	_dir = TempDir.fresh("onsoz_gunler")


func after_each() -> void:
	Engine.time_scale = 1.0
	CineVideo.enabled = true
	get_tree().paused = false
	if InputMap.has_action(&"pause"):
		Input.action_release(&"pause")
	TempDir.wipe(_dir)


# --- Sıra ve veri (saf) ------------------------------------------------------------------------------------------

func test_three_days_in_order_with_their_calendar_cards() -> void:
	var o := PrologueDays.load_order()
	var days := PrologueDays.days_of(o)
	assert_eq(days.size(), 3, "Üç gün")
	var want := [[1168, "8 Nisan MÖ 209"], [1169, "9 Nisan MÖ 209"], [1170, "10 Nisan MÖ 209"]]
	for i in 3:
		var d: Dictionary = days[i]
		assert_eq(int(d["day_n"]), want[i][0], "Günün takvimi")
		assert_true(PrologueDays.date_text(o, i, "tr").begins_with(want[i][1]), "Kart: %s" % PrologueDays.date_text(o, i, "tr"))
		assert_true(PrologueDays.date_text(o, i, "en").contains("209 BC"), "İngilizce kart")
		var calendar_path := "res://scripts/sim/time/game_calendar.gd"
		var calendar: Script = load(calendar_path) if ResourceLoader.exists(calendar_path) else null
		if calendar and calendar.has_method(&"format_tr"):
			assert_eq(calendar.call(&"format_tr", int(d["day_n"])), want[i][1], "Takvimle aynı gün")
	assert_eq(PrologueDays.scene_ids(o).slice(0, 2), PackedStringArray(["milk", "storm"]), "8 Nisan: Süt, Tipi")
	assert_eq(PrologueDays.resolve(o, 1, "storm"), {"day_index": 0, "scene_index": 1}, "--day=1 --quest=storm")
	assert_eq(PrologueDays.resolve(o, 0, "day1_storm"), {"day_index": 0, "scene_index": 1}, "Dosya adıyla")
	assert_eq(PrologueDays.resolve(o, 3, ""), {"day_index": 2, "scene_index": 0}, "--day=3")
	assert_eq(PrologueDays.resolve(o, 0, "yok"), {"day_index": 0, "scene_index": 0}, "Bilinmeyen görev: baştan")
	assert_eq(PrologueDays.day_index_of(o, "day2"), 1)


func test_each_day_asks_only_for_its_own_lines() -> void:
	# Ses havuzu gün başınadır (test_audio_budget, test_vo_budget): 1. gün Süt ve Tipi, 2. gün Kuzular, Şilde, Güreş, 3. gün Ocak.
	var o := PrologueDays.load_order()
	var lines := _lines()
	var want := [["act0.milk.", "act0.storm."], ["act0.lambs.", "act0.feast.", "act0.wrestle."], ["act0.hearth."]]
	var seen := {}
	for i in 3:
		var ids := PrologueDays.day_line_ids(o, i, lines)
		assert_false(ids.is_empty(), "%d. günün sözleri" % (i + 1))
		for id in ids:
			var ok := false
			for pre: String in want[i]:
				ok = ok or id.begins_with(pre)
			assert_true(ok, "%d. gün yalnız kendi sözünü ister: %s" % [i + 1, id])
			assert_false(seen.has(id), "Söz iki güne düşmez: %s" % id)
			seen[id] = true
		if i == 0:
			assert_true(ids.has("act0.milk.wake") and ids.has("act0.storm.lit"), "1. gün: Süt ve Tipi")
	assert_true(PrologueDays.day_line_ids(o, 3, lines).is_empty(), "Gün yoksa söz yok")


func test_lines_are_the_synced_copy_of_the_design_file() -> void:
	var design := ProjectSettings.globalize_path("res://").path_join("../docs/design/d3/e21-lines.json").simplify_path()
	var mine: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PrologueDays.LINES_PATH))
	assert_true(mine.get("lines") is Array and not (mine["lines"] as Array).is_empty(), "Sözler var")
	if not FileAccess.file_exists(design):
		return
	var src: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(design))
	var by_id := {}
	for l: Dictionary in src["lines"]:
		by_id[str(l["id"])] = l
	for l: Dictionary in mine["lines"]:
		var id := str(l["id"])
		assert_true(by_id.has(id), "Kaynakta var: %s" % id)
		if by_id.has(id):
			assert_eq([l["tr"], l["en"], l["speaker"]], [by_id[id]["tr"], by_id[id]["en"], by_id[id]["speaker"]], "Metin aynı: %s (python3 tools/sync_prologue_lines.py)" % id)
	var count := 0
	for id: String in by_id:
		if id.begins_with("act0.milk.") or id.begins_with("act0.storm."):
			count += 1
	var mine_ids := {}
	for l: Dictionary in mine["lines"]:
		mine_ids[str(l["id"])] = true
	for id: String in by_id:
		if id.begins_with("act0.milk.") or id.begins_with("act0.storm."):
			assert_true(mine_ids.has(id), "Eşitlendi: %s" % id)
	assert_true(count >= 23, "«Süt» ve «Tipi»nin sözleri (%d)" % count)


func test_milk_and_storm_data_are_complete() -> void:
	var lines := _lines()
	var places := PrologueWorld.new()
	await places.build()
	var markers := places.markers()
	for path in [MILK, STORM]:
		var d := PrologueDays.load_scene(path)
		assert_false(d.is_empty(), "Sahne var: %s" % path)
		assert_eq(PrologueSteps.validate(d, lines, markers), PackedStringArray(), "Sorunsuz: %s" % path)
		for id: String in (d.get("cast", {}) as Dictionary):
			if id.begins_with("dog") or id.begins_with("horse"):
				continue
			var model := str(PrologueCast.MODELS.get(id, id))
			assert_true(StandIn.has_model(model) or not StandIn.meta(model).is_empty(), "Kişinin modeli ya da yer tutucusu: %s" % id)
			if not StandIn.has_model(model):
				var r := StandIn.resolve(model)
				assert_true(StandIn.has_model(str(r["model"])), "Yer tutucunun ağı var: %s → %s" % [id, r["model"]])
	# «Süt»ün ve «Tipi»nin akışı tasarımdaki gibi: uyanış, sırık, taşıma, saba; tipi, köz kabı, kazıklar, kara yurt, kapı, sayı.
	var milk := PrologueDays.step_ids(PrologueDays.load_scene(MILK))
	for id in ["wake", "yoke", "carry", "churn", "talk", "kunay", "home"]:
		assert_true(milk.has(id), "«Süt»te %s" % id)
	assert_true(milk.find("carry") < milk.find("churn"), "Önce taşıma, sonra saba")
	var storm := PrologueDays.step_ids(PrologueDays.load_scene(STORM))
	for id in ["dusk", "baba", "boru", "pot", "walk", "hearth", "door", "count", "tonga", "end"]:
		assert_true(storm.has(id), "«Tipi»de %s" % id)
	assert_eq(str((PrologueDays.load_scene(STORM)["steps"] as Array).back()["kind"]), "night_end", "Tipi gecesi kararmayla biter (gün biter)")
	var said := PrologueSteps.line_refs(PrologueDays.load_scene(STORM))
	for id in ["act0.storm.count", "act0.storm.lost", "act0.storm.wolf", "act0.storm.boru_six", "act0.storm.door_1", "act0.storm.door_2"]:
		assert_true(said.has(id), "Tipi'de söylenir: %s" % id)
	places.free()


func test_kinds_are_registered_and_load() -> void:
	for kind in ["say", "reach", "wait", "interact", "fade", "clock", "weather", "cast", "wake", "sleep", "night_end", "cinema", "place", "sound",
			"milk_carry", "milk_churn", "storm_walk", "storm_hearth"]:
		assert_true(PrologueSteps.has(kind), "Kayıtlı: %s" % kind)
		assert_not_null(PrologueSteps.script_of(kind), "Betik yüklenir: %s" % kind)
		var h := PrologueSteps.make(kind, null, {"id": "t", "kind": kind})
		assert_true(h is PrologueStep, "PrologueStep: %s" % kind)


# --- Yerler (saf) ------------------------------------------------------------------------------------------------

func test_birch_camp_is_southwest_behind_the_menu_frame() -> void:
	var places := PrologueWorld.new()
	await places.build()
	var c := places.marker("birch_center")
	var d := Vector2(c.x, c.z).length()
	assert_between(d, 300.0, 360.0, "≈350 m (vadinin açıklığı; %.0f m)" % d)
	assert_true(c.x < -150.0 and c.z > 150.0, "Güneybatıda (x batı, z güney)")
	# Menü kadrajı (main.tscn MenuCamera: kuzeye bakar, eğim 38°, görüş 36°): Önsöz'ün kurduğu hiçbir şey kadraja girmez.
	var cam := Camera3D.new()
	add_child(cam)
	cam.transform = Transform3D(Basis(Vector3(1, 0, 0), Vector3(0, 0.788011, -0.615661), Vector3(0, 0.615661, 0.788011)), Vector3(-2.5, 17.55, 19.56))
	cam.fov = 36.0
	cam.make_current()
	await wait_frames(1)
	var shown := 0
	var pts: Array[Vector3] = []
	for s in places.road.size():
		pts.append(Vector3(places.road[s].x, 0.0, places.road[s].y))
	for id: String in places.markers():
		if not id.begins_with("gol_"):
			pts.append(places.marker(id))
	for p in pts:
		if p.z < 10.0:
			continue
		if not cam.is_position_behind(p) and cam.is_position_in_frustum(p + Vector3.UP * 0.5):
			shown += 1
	assert_eq(shown, 0, "Yol, kazıklar ve oba menü kadrajının dışında")
	# Yolun başı obanın güney kıyısıdır (kadrajın altı z ≈ 7,7 m).
	assert_true(places.road[0].y > 8.0, "Yol menü kadrajının altından başlar")
	cam.queue_free()
	places.free()


func test_road_is_walkable_and_stakes_lead_to_the_ford() -> void:
	var places := PrologueWorld.new()
	await places.build()
	# Yokuşun eğimi yol boyunca kayan pencerede: 8 m'de ≤22° (kollar ≈12°, dönemeci içine alan pencere ≈20°), 3 m'de ≤30° (yamaç 30–45°;
	# patika dönemeçte dikleşir).
	var shape := TerrainShape.new(1207)
	var leg_worst := 0.0
	var turn_worst := 0.0
	var w := 0.0
	while w + 8.0 <= places.road_length():
		var a := places.road_point(w)
		var b8 := places.road_point(w + 8.0)
		var b3 := places.road_point(w + 3.0)
		leg_worst = maxf(leg_worst, rad_to_deg(atan(absf(shape.height_at(b8.x, b8.z) - shape.height_at(a.x, a.z)) / 8.0)))
		turn_worst = maxf(turn_worst, rad_to_deg(atan(absf(shape.height_at(b3.x, b3.z) - shape.height_at(a.x, a.z)) / 3.0)))
		w += 0.5
	assert_true(leg_worst <= 22.0, "8 m'lik pencerede en dik yer ≤22° (%.1f°)" % leg_worst)
	assert_true(turn_worst <= 30.0, "Dönemeçlerin en dik yeri ≤30° (%.1f°)" % turn_worst)
	assert_between(places.road_length(), 330.0, 470.0, "Yolun boyu (%.0f m)" % places.road_length())
	var stakes: Array[Vector3] = []
	for i in 12:
		var s := places.marker("stake_%d" % (i + 1))
		assert_ne(s, Vector3.INF, "Kazık %d" % (i + 1))
		stakes.append(s)
	var arcs: Array[float] = []
	for s in stakes:
		arcs.append(places.road_projection(s).x)
	var gaps: Array[float] = []
	for i in range(1, 12):
		gaps.append(arcs[i] - arcs[i - 1])
	assert_true(gaps.min() > 18.0 and gaps.max() < 40.0, "Kazıklar ≈eşit arayla (%.0f–%.0f m; görüş ≈25 m)" % [gaps.min(), gaps.max()])
	var ford_arc := places.road_projection(places.marker("ford")).x
	assert_true(ford_arc - arcs[11] > 0.0 and ford_arc - arcs[11] < 12.0, "On ikincide dereye inilir")
	# Yürünür alan: kampın dairesi + Önsöz'ün daireleri yolu, kazıkları, geçidi ve obanın yerlerini kapsar.
	var circles: Array[Vector3] = [Vector3(0, 0, 38)]
	circles.append_array(places.walk_circles())
	for s in range(0, int(places.road_length()), 3):
		var p := places.road_point(float(s))
		assert_eq(PlayerController.clamp_to_circles(Vector2(p.x, p.z), circles), Vector2(p.x, p.z), "Yol yürünür (%d m)" % s)
	for id in ["ford", "ford_stone_1", "ford_stone_4", "saba_stand", "kunay_door", "kunay_hearth", "saruk_door", "wrestle_ring", "birch_gate",
			"horse_tether", "forest_edge", "lamb_slope", "lamb_slope_far", "stream_stones", "birch_fire", "kunay_cradle"]:
		var m := places.marker(id)
		assert_ne(m, Vector3.INF, "İşaret: %s" % id)
		assert_eq(PlayerController.clamp_to_circles(Vector2(m.x, m.z), circles), Vector2(m.x, m.z), "Yürünür: %s" % id)
	# Açık vadide yoldan 15 m uzaklaşılabilir (Börü'nün «Kazığı göremiyorum!»u).
	var open_p := places.road_point(places.road_projection(places.marker("road_open")).x + 30.0)
	var side := Vector2(open_p.x, open_p.z) + Vector2(0.0, -15.5)
	assert_true(PlayerController.clamp_to_circles(side, circles).distance_to(Vector2(open_p.x, open_p.z)) > 15.0, "Açıkta yoldan 15 m'yi aşabilir")
	places.free()


# --- Saf parçalar ------------------------------------------------------------------------------------------------

func test_route_grass_keeps_off_the_road_the_stream_and_the_yurts() -> void:
	var places := PrologueWorld.new()
	places.data = PrologueWorld.load_places()
	await places.build()
	var g := PrologueGrass.new()
	var yurt: Vector2 = places.markers().get("kunay_yurt", Vector2(-238, 210))
	g.build({"shape": TerrainShape.new(), "road": places.road, "road_arc": places.road_arc, "road_half": 0.85, "stream": places.stream,
		"stream_half": 1.3, "blockers": [Vector3(yurt.x, yurt.y, PrologueWorld.YURT_GRASS_R)], "trample": [Vector3(-250, 198, 3.4)],
		"oba": Vector3(-250, 197, PrologueWorld.OBA_GRASS_R)})
	assert_between(g.tufts, 4000, 40000, "Yolun ve obanın tutamları (%d)" % g.tufts)
	assert_eq(PrologueGrass.hash_distance(PrologueGrass.line_hash(PackedVector2Array([Vector2(0, 0), Vector2(10, 0)]), 1.0), Vector2(5, 2)), 2.0, "Izgaradaki çizgiye uzaklık")
	var ford: Vector2 = places.markers()["ford"]
	assert_eq(g.chance(ford), 0.0, "Geçitte (yolda ve derede) çimen yok")
	assert_eq(g.chance(PrologueWorld.point_at_arc(places.road, places.road_arc, 120.0)), 0.0, "Yolun üstünde çimen yok")
	assert_eq(g.chance(yurt), 0.0, "Yurdun içinde çimen yok")
	assert_eq(g.chance(Vector2(-250, 198)), 0.0, "Obanın ocağı ezik toprak")
	assert_eq(g.chance(Vector2(0, 10)), 0.0, "Göl Obası'nın çayırına çimen eklenmez")
	var side := PrologueWorld.point_at_arc(places.road, places.road_arc, 120.0)
	var off := (PrologueWorld.point_at_arc(places.road, places.road_arc, 121.0) - side).normalized().orthogonal() * 3.0
	assert_true(g.chance(side + off) > 0.0, "Yolun 3 m yanında çimen çıkar")
	g.free()
	places.free()


func test_milk_spills_when_running_and_at_the_ford() -> void:
	var script: Script = load("res://scripts/story/steps/milk_carry.gd")
	assert_eq(script.call(&"state_of", 0.0, 0.12), "full")
	assert_eq(script.call(&"state_of", 0.08, 0.12), "little")
	assert_eq(script.call(&"state_of", 0.4, 0.12), "spilt")
	var walk_rate := pow(maxf(1.5 - 1.75, 0.0), 1.3) * 0.0045
	var run_rate := pow(3.6 - 1.75, 1.3) * 0.0045
	assert_eq(walk_rate, 0.0, "Yürürken dökülmez")
	assert_between(run_rate, 0.006, 0.02, "Koşarken saniyede ≈%1")
	var churn: Script = load("res://scripts/story/steps/milk_churn.gd")
	assert_true(churn.call(&"on_beat", 0.98, 1.05, 0.32), "İnişte vuruş")
	assert_true(churn.call(&"on_beat", 0.03, 1.05, 0.32), "İnişin hemen ardı da vuruş")
	assert_false(churn.call(&"on_beat", 0.5, 1.05, 0.32), "Ortada kaçar (cezasız)")
	var walk: Script = load("res://scripts/story/steps/storm_walk.gd")
	var push: Vector3 = walk.call(&"push_of", Vector2(13.0, 0.0), 0.045)
	assert_almost(push.x, 0.585, 0.01, "13 m/sn rüzgâr ≈0,6 m/sn iter (çocuğun yürüyüşü 1,5)")
	var gust: Vector3 = walk.call(&"push_of", Vector2(30.0, 0.0), 0.045)
	assert_almost(gust.length(), 0.75, 0.001, "İtiş sınırlı (bora)")


func test_union_play_area_clamps_to_the_nearest_circle() -> void:
	var circles: Array[Vector3] = [Vector3(0, 0, 10), Vector3(15, 0, 6)]
	assert_eq(PlayerController.clamp_to_circles(Vector2(12, 0), circles), Vector2(12, 0), "İkinci dairenin içi")
	assert_eq(PlayerController.clamp_to_circles(Vector2(0, 14), circles), Vector2(0, 10), "Birinci dairenin kenarı")
	var r := PlayerController.roomiest_circle(Vector2(14, 0), circles)
	assert_eq(r, Vector3(15, 0, 6), "En çok pay ikinci daire")
	var p := PlayerController.new()
	add_child(p)
	p.play_area_extra = [Vector3(30, 0, 8)]
	p.spawn_at(Vector3(32, 0, 1), 0.0)
	assert_almost(p.global_position.x, 32.0, 0.01, "Ek dairenin içinde durulur")
	p.play_area_extra = []
	p.spawn_at(Vector3(32, 0, 1), 0.0)
	assert_true(Vector2(p.global_position.x, p.global_position.z).length() <= p.play_area_radius + 0.01, "Ek daire yokken eski tek daire")
	p.queue_free()


# --- Ana sahnede --------------------------------------------------------------------------------------------------

func test_new_game_opens_the_three_days_with_a_card_and_a_save_point() -> void:
	var main := await _new_main()
	main.menu.start_requested.emit()
	await _wait_until(func() -> bool: return main.prologue_runner() != null and main.prologue_runner().is_running() and main.state == main.State.PLAYING, 60.0)
	var days: PrologueDays = main.prologue_runner()
	assert_not_null(days, "Önsöz'ün günleri başladı")
	if days == null:
		await _free_main(main)
		return
	assert_eq(main.flow_stage_id(), "prologue", "Akışın Önsöz aşaması")
	assert_eq(days.day_index(), 0, "8 Nisan")
	assert_eq(days.scene_id(), "milk", "«Süt» ile açılır")
	assert_eq(days.clock.day_n, 1168, "Saat 8 Nisan MÖ 209")
	assert_between(days.clock.minute, 375.0, 400.0, "Sabah (06:20)")
	assert_true(main.cine.card_text().begins_with("8 Nisan MÖ 209"), "Günün kartı: %s" % main.cine.card_text())
	assert_true(main.player.visible and main.player.is_child(), "Oyuncu Çocuk")
	assert_true(main.player.is_seated(), "Yatakta uyanır")
	assert_true(days.places.is_family_open(), "Aile yurdu açık (içine girilir)")
	assert_false(main.world.get_node(^"Camp/YurtLeft").visible, "Kampın Meshy yurdu gizli (açık yurtla değişti)")
	assert_false(main.world.get_node(^"Camp/CampNpcs").visible, "Ateş başı halkı yerinde değil: kişiler işinde")
	assert_true(days.cast.person("mother") != null and days.cast.person("saruk") != null, "Ana ve Saruk kuruldu")
	assert_false(main._camp_life.is_running(), "camp3 kurulmaz (K109, K110)")
	assert_false(main.player.play_area_extra.is_empty(), "Yürünür alan genişledi")
	assert_true(days.day_lines().has("act0.milk.wake") and not days.day_lines().has("act0.lambs.ana"), "Yalnız 1. günün sözleri istendi")
	# Kayıt noktası: günün başında oto kayıt, Yeni Oyun'un aşaması ve günüyle.
	var info: Dictionary = main.saves.slot_info(SaveSystem.AUTO_SLOT)
	assert_false(info.is_empty(), "Günün başında kayıt yazıldı")
	if not info.is_empty():
		assert_eq(main.flow_stage_of(info), "prologue", "Kaydın aşaması")
		assert_eq(str((info["flags"] as Dictionary).get(main.FLOW_DAY_FLAG, "")), "day1", "Kaydın günü")
	# Basılı Esc Önsöz'ü (günler ve sinema) atlar; kampın düzeni geri gelir.
	main.new_game_only = PackedStringArray(["prologue"])
	Input.action_press(&"pause")
	main.player.pause_requested.emit()
	await _wait_until(func() -> bool: return main.prologue_runner() == null, 10.0)
	Input.action_release(&"pause")
	assert_null(main.prologue_runner(), "Atlandı")
	assert_true(main.world.get_node(^"Camp/YurtLeft").visible, "Kampın yurdu geri geldi")
	assert_true(main.world.get_node(^"Camp/CampNpcs").visible, "Ateş başı halkı geri geldi")
	assert_true(main.player.play_area_extra.is_empty(), "Yürünür alan eski hâlinde")
	assert_true(main.journey.has_flag(CineHost.PROLOGUE_FLAG), "Önsöz işareti yazıldı")
	await _free_main(main)


func test_continue_opens_the_saved_day_from_its_start() -> void:
	# 9 Nisan'ın kayıt noktası: Devam Et Yeni Oyun'u Önsöz'ün ikinci gününün başından açar; heybe kayıttaki gibidir.
	var rec := SaveData.build(CharacterProfile.new(), Vector3(-6, 0, 2), 0.0, {"yeni_oyun_asama": "prologue", "yeni_oyun_gun": "day2", "onsoz_sut": "spilt"}, 120.0, 0, "ocak")
	rec["mode"] = SaveData.MODE_STORY
	var bag := Inventory.new()
	bag.reset_body(Inventory.BODY_CHILD)
	assert_eq(int(bag.add(BAG_ITEM, 1, "test")["added"]), 1, "Sınamanın heybesi: köz kabı")
	rec["blocks"] = {"flow_bag": bag.to_dict()}
	SaveSystem.new(_dir).write(SaveSystem.AUTO_SLOT, rec)
	var main := await _new_main()
	main.menu.continue_requested.emit()
	await _wait_until(func() -> bool: return main.prologue_runner() != null and main.prologue_runner().is_running() and main.state == main.State.PLAYING, 60.0)
	var days: PrologueDays = main.prologue_runner()
	assert_not_null(days, "Önsöz kayıttan açıldı")
	if days:
		assert_eq(days.day_index(), 1, "9 Nisan'dan")
		assert_eq(days.clock.day_n, 1169)
		assert_eq(str(main.journey.get_flag("onsoz_sut", "")), "spilt", "Günler arası sonuç kayıttan")
	assert_eq(main.gameplay_hud.bag.count(BAG_ITEM), 1, "Heybe kayıttaki gibi (günün başında begin_body'den sonra geri kondu)")
	# Açılan günün başındaki kayıt noktası heybeyi yeniden yazar: Devam Et yine aynı heybeyle açar.
	assert_eq(_saved_bag_count(main), 1, "Yeni kayıt noktasında heybe aynı")
	await _free_main(main)


func test_save_point_carries_the_bag_and_keeps_it_out_of_the_session() -> void:
	var main := await _new_main()
	main.menu.start_requested.emit()
	await _wait_until(func() -> bool: return main.prologue_runner() != null and main.prologue_runner().is_running() and main.state == main.State.PLAYING, 60.0)
	assert_not_null(main.prologue_runner(), "Önsöz'ün günleri başladı")
	assert_eq(_saved_bag_count(main), 0, "Günün başında heybe boş yazıldı")
	var info: Dictionary = main.saves.slot_info(SaveSystem.AUTO_SLOT)
	assert_true((info.get("blocks", {}) as Dictionary).has(main.FLOW_BAG_BLOCK), "Kayıt noktasında heybe bloğu var")
	assert_false((info.get("blocks", {}) as Dictionary).has("inventory"), "Oturumun envanter bloğu değil (oturum yok)")
	main.gameplay_hud.bag.add(BAG_ITEM, 1)
	assert_eq(main.gameplay_hud.bag.count(BAG_ITEM), 1)
	assert_true(main.flow_save_point("prologue", "day1"), "Kayıt noktası yazıldı")
	assert_eq(_saved_bag_count(main), 1, "Heybedeki köz kabı kayıtta")
	assert_false(main.flow_restore_bag(), "Geri konacak heybe yok (yeni oyun)")
	await _free_main(main)


# --- Yardımcılar --------------------------------------------------------------------------------------------------

## Oto kaydın heybe bloğundaki eşya sayısı (yoksa -1).
func _saved_bag_count(main: Node) -> int:
	var info: Dictionary = main.saves.slot_info(SaveSystem.AUTO_SLOT)
	var block: Variant = (info.get("blocks", {}) as Dictionary).get(main.FLOW_BAG_BLOCK)
	if not block is Dictionary:
		return -1
	var inv := Inventory.new()
	if not inv.from_dict(block):
		return -1
	return inv.count(BAG_ITEM)


func _lines() -> Dictionary:
	var out := {}
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(PrologueDays.LINES_PATH))
	for l: Dictionary in d.get("lines", []):
		out[str(l["id"])] = l
	return out


func _new_main() -> Node:
	var main: Node = load(MAIN_SCENE).instantiate()
	main.quit_handler = func() -> void: pass
	main.saves = SaveSystem.new(_dir)
	main.prologue_path = "res://data/cine/prologue.json"
	main.new_game_only = PackedStringArray(["prologue"])
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


func _wait_until(condition: Callable, timeout: float) -> void:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
