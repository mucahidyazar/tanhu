extends TestCase
## Kişilerin günlük programı (Schedule; scripts/story/schedule.gd, data/story/act_1/npcs.json; Yol Haritası npc-schedules; act1.md §5,
## time.md §9.4; godot.md §9.5 «kişi programı bir oyun günü hatasız akar»):
##   - veri: her kişinin blokları günü boşluksuz örter (genel gün ve hikâye günlerinin özelleri), yerler, yollar ve işler bilinir;
##   - bir oyun günü hızlandırılmış saatle akar (Gün II 06:40'tan ertesi gün 06:40'a, dörtte bir oyun dakikası adımla): hata yazılmaz,
##     her plan haritanın içinde ve sonludur, plan hiçbir yerde ışınlanmaz (iki adım arasında olağan saatte yürünebilecek yoldan uzun
##     sıçrama yok; arabadaki Kantu ve haritada olmayan kişi dışında) ve yürüyüş 1,4 m/sn'dir (≤ oyuncunun koşusu, K105);
##   - gündüz ve gece hâli 06:40'ta ve 19:30'da değişir (K20): dokuz nöbetçi 19:30'da ateşinin yanındadır, gündüz Nöbet Yurdu'nda;
##   - kişi bir sonraki bloğa yürüme süresi kadar önce çıkar, vaktinde varır (Farnak Çoban Durağı'na 10:30'da); kol 07:00'de çıkar;
##   - kalabalık: pazarın 40 kişisi öğlen Ulu Ocak'ta, gece evinde; Çukur'da gece 31 esir; Demir Diş'te gündüz 16 esir ve 2 nöbetçi;
##     Esir Yolu'nun kolu günde iki kez 16 kişidir (07:00 gidiş, 17:00 dönüş);
##   - hikâye günlerinin özeli: Gün III'te Eskam 11:30–14:00 Ulu Ocak'ta, Farnak av için kampın dışında, Uldın 12:00'de güreşte;
##     Nandu yalnız Gün II–IV'te.

const MAP_MIN := Vector2(-450.0, -760.0)
const MAP_MAX := Vector2(950.0, 290.0)
const DAY_II := 1042
const DAY_III := 1043
const STEP_MIN := 0.25
## Planın bir adımda en çok yürüyebileceği (m): oyun dakikasında 3,5 m, pay ile.
const STEP_SLACK := 1.25

var _schedule: Schedule
var _clock: GameClock


func before_each() -> void:
	_clock = GameClock.new(DAY_II, 400.0)
	_schedule = Schedule.new()
	_schedule.setup(Schedule.load_data(), _clock)


func test_data_validates() -> void:
	var problems := _schedule.validate()
	for p in problems:
		fail(p)
	assert_true(problems.is_empty(), "Program verisi geçerli")
	# Adlılar tam kişi, ≤16 (act1.md §3; ≤16 tam kişi).
	var full := 0
	for id in _schedule.people_ids:
		if str((_schedule.people[id] as Dictionary).get("tier", "")) == "full":
			full += 1
	assert_between(float(full), 12.0, 16.0, "Tam kişi sayısı")
	for id in ["amaga", "farnak", "nanay", "ardoksha", "kantu", "mene", "palak", "atsho", "kujul", "uldin", "berik"]:
		assert_eq(str((_schedule.people[id] as Dictionary).get("tier", "")), "full", "%s tam kişi" % id)
	assert_eq(_schedule.crowd.size(), 40 + 15 + 16 + 2, "Kalabalık: pazar 40, Çukur 15, kol 16, iki nöbetçi")


func test_one_game_day_flows_without_errors() -> void:
	var states := []
	var changes: Array[StringName] = []
	_schedule.day_state_changed.connect(func(s: StringName) -> void: changes.append(s))
	var last := {}
	var last_crowd := {}
	var steps := int(1440.0 / STEP_MIN)
	var max_step := _schedule.metres_per_minute() * STEP_MIN * STEP_SLACK
	var jumps := PackedStringArray()
	var walked_steps := 0
	for k in steps:
		_schedule.step(0.0)
		for id in _schedule.people_ids:
			var s := _schedule.state_of(id)
			var pos: Vector2 = s["pos"]
			assert_true(is_finite(pos.x) and is_finite(pos.y), "%s konumu sonlu" % id)
			if pos.x < MAP_MIN.x or pos.x > MAP_MAX.x or pos.y < MAP_MIN.y or pos.y > MAP_MAX.y:
				fail("%s haritanın dışında: %s (%s)" % [id, pos, _clock.text()])
			if last.has(id):
				var prev: Dictionary = last[id]
				var exempt := str(s["job"]) == "cart" or str(prev["job"]) == "cart" or str(s["kind"]) == "absent" or str(prev["kind"]) == "absent"
				var d := (prev["pos"] as Vector2).distance_to(pos)
				if not exempt and d > max_step:
					jumps.append("%s %s: %.2f m" % [id, _clock.text(), d])
				if bool(s["moving"]):
					walked_steps += 1
			last[id] = s
		for i in _schedule.crowd.size():
			var pose := _schedule.crowd_pose(i, _clock.minute)
			var xz: Vector2 = pose["xz"]
			if last_crowd.has(i):
				var prev_xz: Vector2 = last_crowd[i]["xz"]
				var both_absent := int(pose["state"]) == CrowdPlan.State.ABSENT and int(last_crowd[i]["state"]) == CrowdPlan.State.ABSENT
				var lane := absf(float(_schedule.crowd[i].get("lane", 0.0)))
				if not both_absent and prev_xz.distance_to(xz) > max_step + lane * 0.35:
					jumps.append("kalabalık %s %s: %.2f m" % [_schedule.crowd[i]["seed"], _clock.text(), prev_xz.distance_to(xz)])
			last_crowd[i] = pose
		_clock.skip(STEP_MIN, &"dev")
	_schedule.step(0.0)
	for j in jumps.slice(0, 8):
		fail("Plan ışınlandı: " + j)
	assert_true(jumps.is_empty(), "Plan bir günde hiç ışınlanmaz (%d sıçrama)" % jumps.size())
	assert_true(walked_steps > 1000, "Kişiler gün boyu yürür (%d adım)" % walked_steps)
	assert_eq(_clock.day_n, DAY_II + 1, "Bir gün geçti")
	assert_eq(changes, [Schedule.DAY, Schedule.NIGHT, Schedule.DAY], "Gündüz, 19:30'da gece, 06:40'ta gündüz")
	# Yürüyüşün hızı oyuncunun koşusunu aşmaz (K105).
	assert_true(_schedule.walk_speed <= PaceLimit.ADULT_RUN, "Yürüyüş 1,4 m/sn")
	assert_almost(_schedule.metres_per_minute(), 3.5, 1e-6, "Oyun dakikasında 3,5 m")


func test_day_and_night_states() -> void:
	assert_eq(Schedule.day_state_at(399.0), Schedule.NIGHT)
	assert_eq(Schedule.day_state_at(400.0), Schedule.DAY, "06:40 gündüz")
	assert_eq(Schedule.day_state_at(1169.9), Schedule.DAY)
	assert_eq(Schedule.day_state_at(1170.0), Schedule.NIGHT, "19:30 gece")
	# Dokuz nöbetçi 19:30'da ateşinin yanında, dışarı bakar; öğlen Nöbet Yurdu'nda (görünmez).
	var posts: Array = Schedule.load_data()["watch"]["posts"]
	assert_eq(posts.size(), 9)
	for post: Dictionary in posts:
		var id := "guard_%s" % post["id"]
		var fire := Schedule.vec2(post["fire"])
		var night := _schedule.plan(id, GameClock.abs_of(DAY_II, 1171.0))
		assert_almost((night["pos"] as Vector2).distance_to(fire), 2.2, 0.01, "%s ateşinin yanında" % id)
		assert_true(bool(night["visible"]), "%s gece görünür" % id)
		var out_dir := fire.normalized()
		assert_almost(float(night["yaw"]), atan2(out_dir.x, out_dir.y), 0.001, "%s dışarı bakar" % id)
		var noon := _schedule.plan(id, GameClock.abs_of(DAY_II, 720.0))
		assert_false(bool(noon["visible"]), "%s öğlen Nöbet Yurdu'nda" % id)
		var dawn := _schedule.plan(id, GameClock.abs_of(DAY_II, 300.0))
		assert_true(bool(dawn["visible"]) and (dawn["pos"] as Vector2).distance_to(fire) < 2.3, "%s gece yarısından sonra da yerinde" % id)


func test_walk_departs_early_and_arrives_on_time() -> void:
	# Farnak Ahır'dan (−72, 34) Çoban Durağı'na (210, −250): 400 m, 114,3 oyun dk; 10:30'da varır.
	var walk := Vector2(-72.0, 34.0).distance_to(Vector2(210.0, -250.0)) / 3.5
	var depart := 630.0 - walk
	var before := _schedule.plan("farnak", GameClock.abs_of(DAY_II, depart - 1.0))
	assert_eq(before["kind"], "stay")
	assert_true((before["pos"] as Vector2).distance_to(Vector2(-72.0, 34.0)) < 0.01, "Çıkmadan önce Ahır'da")
	var mid := _schedule.plan("farnak", GameClock.abs_of(DAY_II, depart + walk * 0.5))
	assert_eq(mid["kind"], "walk")
	assert_true(bool(mid["moving"]))
	var at := _schedule.plan("farnak", GameClock.abs_of(DAY_II, 630.5))
	assert_eq(at["kind"], "stay")
	assert_true((at["pos"] as Vector2).distance_to(Vector2(210.0, -250.0)) < 0.01, "10:30'da Çoban Durağı'nda")
	# Amaga 12:00'de ilk kaseyi kaldırır; 12:20'de yurduna döner (içeride görünmez).
	var bowl := _schedule.plan("amaga", GameClock.abs_of(DAY_II, 725.0))
	assert_true((bowl["pos"] as Vector2).distance_to(Vector2(6.0, -4.0)) < 0.01, "Amaga Ulu Ocak'ta")
	assert_true(bool(bowl["visible"]))
	var inside := _schedule.plan("amaga", GameClock.abs_of(DAY_II, 800.0))
	assert_false(bool(inside["visible"]), "Amaga yurdunda")
	# Atşo taşır: köz Ulu Ocak ile Ateş Yurdu arasında gidip gelir.
	var moved := 0
	for m in range(400, 620, 7):
		if bool(_schedule.plan("atsho", GameClock.abs_of(DAY_II, float(m)))["moving"]):
			moved += 1
	assert_true(moved > 10, "Atşo köz taşır (%d)" % moved)


func test_column_and_iron_tooth() -> void:
	var column := _crowd_of("column")
	var escort := _crowd_of("column_escort")
	assert_eq(column.size(), 16, "Kol 16 esir")
	assert_eq(escort.size(), 2, "İki nöbetçi")
	# 06:55 toplanmış, 07:05 yürüyor (07:00'de çıkar), 12:00 Demir Diş'te işte.
	for i in column:
		assert_eq(int(_schedule.crowd_pose(i, 415.0)["state"]), CrowdPlan.State.STAND, "06:55 kapıda")
		var noon := _schedule.crowd_pose(i, 720.0)
		assert_eq(int(noon["state"]), CrowdPlan.State.WORK, "Öğlen işte")
		assert_true((noon["xz"] as Vector2).x < -250.0, "Demir Diş'te: %s" % noon["xz"])
	var walking := 0
	for i in column:
		if int(_schedule.crowd_pose(i, 425.0)["state"]) == CrowdPlan.State.WALK:
			walking += 1
	assert_eq(walking, 16, "07:05'te kolun hepsi yolda")
	# Gidiş ve dönüş: günde iki kez 16 kişilik kol.
	var out_walk := 0
	var back_walk := 0
	for i in column:
		if int(_schedule.crowd_pose(i, 480.0)["state"]) == CrowdPlan.State.WALK:
			out_walk += 1
		if int(_schedule.crowd_pose(i, 1080.0)["state"]) == CrowdPlan.State.WALK:
			back_walk += 1
	assert_eq(out_walk, 16, "Sabah kolu 16 kişi")
	assert_eq(back_walk, 16, "Akşam kolu 16 kişi")
	for i in escort:
		assert_true((_schedule.crowd_pose(i, 720.0)["xz"] as Vector2).x < -250.0, "Nöbetçi Demir Diş'te")
	# Gece Çukur'da 31 esir (kol 16 + kalanlar 15).
	var hollow := _crowd_of("hollow")
	assert_eq(hollow.size(), 15)
	var in_hollow := 0
	for i in column + hollow:
		var pose := _schedule.crowd_pose(i, 1230.0)
		var xz: Vector2 = pose["xz"]
		if int(pose["state"]) != CrowdPlan.State.ABSENT and absf(xz.x - 92.0) <= 60.0 and absf(xz.y - 165.0) <= 45.0:
			in_hollow += 1
	assert_eq(in_hollow, 31, "20:30'da Çukur'da 31 esir")
	# Uldın kolun başında yürür (tam kişi).
	var uldin := _schedule.plan("uldin", GameClock.abs_of(DAY_II, 480.0))
	assert_eq(uldin["kind"], "walk", "Uldın kolla yürür")
	var at_work := _schedule.plan("uldin", GameClock.abs_of(DAY_II, 720.0))
	assert_true((at_work["pos"] as Vector2).distance_to(Vector2(-300.0, -170.0)) < 0.01, "Uldın Galeri'de")


func test_market_by_day_and_night() -> void:
	var market := _crowd_of("market")
	assert_eq(market.size(), 40)
	var at_noon := 0
	var at_night := 0
	var kitchen := 0
	for i in market:
		var noon := _schedule.crowd_pose(i, 720.0)
		if int(noon["state"]) == CrowdPlan.State.STAND and (noon["xz"] as Vector2).length() <= 17.0:
			at_noon += 1
			assert_true((noon["xz"] as Vector2).length() >= 4.5, "Ocağın taş halkasına girmez")
		if int(_schedule.crowd_pose(i, 1320.0)["state"]) != CrowdPlan.State.ABSENT:
			at_night += 1
		var evening := _schedule.crowd_pose(i, 1095.0)
		if (evening["xz"] as Vector2).distance_to(Vector2(15.0, 17.0)) < 6.0:
			kitchen += 1
	assert_eq(at_noon, 40, "Öğlen pazarda 40 kişi")
	assert_eq(at_night, 0, "Gece pazar boş")
	assert_between(float(kitchen), 12.0, 32.0, "Akşam aşında Mutfak'ta (%d)" % kitchen)
	# Aynı tohum aynı kalabalığı verir.
	var again := Schedule.new()
	again.setup(Schedule.load_data(), _clock)
	for i in market:
		assert_eq(again.crowd_pose(i, 720.0)["xz"], _schedule.crowd_pose(i, 720.0)["xz"])


func test_story_day_specials() -> void:
	assert_false(_schedule.present_on("eskam", DAY_II), "Eskam Gün II'de yok")
	assert_true(_schedule.present_on("eskam", DAY_III))
	assert_false(bool(_schedule.plan("eskam", GameClock.abs_of(DAY_II, 720.0))["visible"]))
	var envoy := _schedule.plan("eskam", GameClock.abs_of(DAY_III, 720.0))
	assert_true(bool(envoy["visible"]), "Gün III 12:00 Eskam Ulu Ocak'ta")
	assert_true((envoy["pos"] as Vector2).distance_to(Vector2(3.0, -6.5)) < 0.01)
	var hunt := _schedule.plan("farnak", GameClock.abs_of(DAY_III, 900.0))
	assert_eq(hunt["job"], "away", "Gün III 15:00 Farnak avda")
	var wrestle := _schedule.plan("uldin", GameClock.abs_of(DAY_III, 735.0))
	assert_true((wrestle["pos"] as Vector2).distance_to(Vector2(-270.0, -60.0)) < 0.01, "Gün III 12:15 Uldın güreşte")
	assert_true(bool(_schedule.plan("nandu", GameClock.abs_of(DAY_II, 720.0))["visible"]), "Nandu Gün II pazarda")
	assert_false(bool(_schedule.plan("nandu", GameClock.abs_of(1045, 720.0))["visible"]), "Nandu Gün V'te yok")
	assert_false(_schedule.present_on("sak", 1045), "Sak Gün IV gecesinden sonra yok")
	# Genel gün (Serbest Gez'in günü, deneme haritası): özelsiz.
	assert_eq(Schedule.story_day(GameClock.ROAM_DAY), 0)
	assert_false(_schedule.present_on("eskam", GameClock.ROAM_DAY))


func test_session_steps_the_schedule() -> void:
	var session := Session.new()
	assert_true(session.add_system(&"schedule", _schedule, &"schedule"), "Session'ın 7. adımına girer")
	assert_eq(session.get_system(&"schedule"), _schedule)
	session.free()


func _crowd_of(group: String) -> Array[int]:
	var out: Array[int] = []
	for i in _schedule.crowd.size():
		if str(_schedule.crowd[i]["group"]) == group:
			out.append(i)
	return out
