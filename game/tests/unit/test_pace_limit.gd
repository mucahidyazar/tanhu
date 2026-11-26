extends TestCase
## Kişilerin hız sınırı (E20, 2026-11-08: «insanlar çok hızlı hareket ediyorlar, maksimum benim koşma hızım kadar hareket etsinler»; PaceLimit):
##   - Sınır oyuncunun koşusudur: çocukta 3,6 m/sn (PlayerController.CHILD_RUN_SPEED), yetişkinde 4,6 m/sn (run_speed'in varsayılanı).
##   - Ölçü (PaceLimit.Probe) yürüyüşü doğru ölçer, ışınlanmayı yakalar, gizlenen kişinin yerini hız saymaz.
##   - Sahnelerin verisindeki her kişi hızı sınırın içindedir: Çocukluk'ta çocuğun, Yola Çıkış'ta yetişkinin koşusu; Teoman'ın atlıları kıvrımın
##     dışında da (RiderColumn.stretch) çocuğun koşusunu aşmaz.
##   - StoryMover verilen hızı aşmaz; atlı düzeni limit_speeds'le bütün üyeleriyle sınırda kalır (eski hızlar 3,6 / 4,4 aşardı).
##   - Kalabalık saatin görünür akışında ışınlanmaz, koşmaz: planın gerisinde kendi hızının 1,5 katıyla yetişir (CrowdPlan.chase, CrowdCards).
##   - Serbest Gez'in ateş başındakileri oturur, yerinden kıpırdamaz.

const LAYOUT := "res://data/maps/childhood_ordos/layout.json"
const NPC_SCENE := preload("res://scenes/world/camp_npcs.tscn")
const ATLAS := "res://assets/crowd/dailin_cards.json"
const STEP := 1.0 / 60.0


# --- Sınır ve ölçü (saf) ----------------------------------------------------------------------------------------

func test_caps_are_the_players_runs() -> void:
	assert_almost(PaceLimit.CHILD_RUN, PlayerController.CHILD_RUN_SPEED, 1e-6, "Çocuğun koşusu")
	var player := PlayerController.new()
	assert_almost(PaceLimit.ADULT_RUN, player.run_speed, 1e-6, "Yetişkinin koşusu (run_speed'in varsayılanı)")
	assert_almost(PaceLimit.run_cap(player), player.run_speed, 1e-6, "Oyuncunun o anki koşusu")
	player.run_speed = PlayerController.CHILD_RUN_SPEED
	assert_almost(PaceLimit.run_cap(player), 3.6, 1e-6, "Çocuk kipinde çocuğun koşusu")
	player.free()
	assert_almost(PaceLimit.run_cap(null), PaceLimit.ADULT_RUN, 1e-6, "Oyuncu yoksa yetişkininki")
	assert_almost(PaceLimit.limit(4.4, 3.6), 3.6, 1e-6, "Sınırın üstü sınıra iner")
	assert_almost(PaceLimit.limit(2.9, 3.6), 2.9, 1e-6, "Altı aynı kalır")
	assert_almost(PaceLimit.limit(-1.0, 3.6), 0.0, 1e-6)
	assert_eq(PaceLimit.over({"a": 3.6, "b": 3.62, "c": 3.7}, 3.6), PackedStringArray(["c"]), "Pay (0,03) içinde aşmak sayılmaz")


func test_probe_measures_walks_and_catches_teleports() -> void:
	var probe := PaceLimit.Probe.new()
	var t := 0.0
	var at := Vector3.ZERO
	for i in 300:
		probe.sample("walker", at, t)
		at += Vector3(1.5, 0.0, 0.0) * STEP
		t += STEP
	assert_almost(probe.peak("walker"), 1.5, 0.02, "Yürüyüş ölçülür")
	# Işınlanma: tek karede 6 m.
	probe.sample("jumper", Vector3.ZERO, 0.0)
	probe.sample("jumper", Vector3(6.0, 0.0, 0.0), STEP)
	probe.sample("jumper", Vector3(6.0, 0.0, 0.0), 0.25)
	assert_true(probe.peak("jumper") > 20.0, "Işınlanma hız sayılır (%.1f m/sn)" % probe.peak("jumper"))
	# Gizlenen kişi başka yerde görünür: unutulur, hız sayılmaz.
	probe.sample("hidden", Vector3.ZERO, 0.0)
	probe.forget("hidden")
	probe.sample("hidden", Vector3(40.0, 0.0, 0.0), 0.3)
	probe.sample("hidden", Vector3(40.5, 0.0, 0.0), 0.6)
	assert_almost(probe.peak("hidden"), 0.5 / 0.3, 0.01, "Görünmezken alınan yer sayılmaz")
	assert_eq(probe.worst()[0], "jumper")
	assert_eq(probe.over(3.6), PackedStringArray(["jumper"]))
	assert_true(probe.report(3.6).contains("aşan: jumper"), "Günlük satırı aşanı yazar")
	var pts := PackedVector3Array([Vector3.ZERO, Vector3(0.5, 0.0, 0.0), Vector3(1.0, 0.0, 0.0)])
	var times := PackedFloat64Array([0.0, 0.25, 0.5])
	assert_almost(PaceLimit.peak_speed(pts, times), 2.0, 1e-6, "Saf ölçü")


# --- Sahnelerin verisi (saf) -------------------------------------------------------------------------------------

func test_scene_data_speeds_stay_under_the_players_run() -> void:
	var childhood := ChildhoodScene.load_data()
	var found := PaceLimit.data_speeds(childhood)
	assert_true(found.size() >= 8, "Çocukluk'un kişi hızları bulundu (%d)" % found.size())
	for row: Array in found:
		assert_true(float(row[1]) <= PaceLimit.CHILD_RUN + 1e-6, "Çocukluk %s = %.2f m/sn ≤ çocuğun koşusu" % [row[0], float(row[1])])
	for row: Array in found:
		assert_false(str(row[0]).contains("lapse"), "Saatin akışı kişi hızı değildir (%s)" % row[0])
	var departure := DepartScene.load_data()
	for row: Array in PaceLimit.data_speeds(departure):
		assert_true(float(row[1]) <= PaceLimit.ADULT_RUN + 1e-6, "Yola Çıkış %s = %.2f m/sn ≤ yetişkinin koşusu" % [row[0], float(row[1])])
	assert_true(DepartScene.ESKAM_WALK <= PaceLimit.ADULT_RUN, "Eskam arabasına yürür")
	# Atlılar: kıvrımın dışındaki bey liderden hızlıdır; verinin hızları onunla da sınırda kalır.
	var column := _data_column(childhood)
	var k := column.stretch(0.25)
	assert_true(k > 1.0 and k < 1.3, "Kıvrımda dıştaki bey liderden hızlı (oran %.3f)" % k)
	var speeds: Dictionary = _procession(childhood)["speeds"]
	for gait: String in speeds:
		assert_true(float(speeds[gait]) * k <= PaceLimit.CHILD_RUN + PaceLimit.TOLERANCE,
			"Atlıların %s hızı en hızlı beyle %.2f m/sn ≤ 3,6" % [gait, float(speeds[gait]) * k])
	assert_eq(RideableHorse.role_for(float(speeds["approach"]), &"trot"), &"trot", "Atlılar yine tırısla gelir")
	assert_eq(RideableHorse.role_for(float(speeds["leave"]), &"trot"), &"trot", "Tırısla gider")


# --- Yürütme (saf) ------------------------------------------------------------------------------------------------

func test_story_mover_keeps_its_pace() -> void:
	var actor := CineActor.new()
	actor.build_on_ready = false
	add_child(actor)
	var mover := StoryMover.new(actor, null)
	mover.place(Vector3.ZERO, 0.0)
	mover.go([Vector3(0, 0, 12), Vector3(9, 0, 20), Vector3(9, 0, 40)], PaceLimit.limit(2.9, PaceLimit.CHILD_RUN))
	var probe := PaceLimit.Probe.new()
	var t := 0.0
	var top := 0.0
	var prev := actor.position
	for i in 1200:
		mover.tick(STEP)
		t += STEP
		top = maxf(top, Vector2(actor.position.x - prev.x, actor.position.z - prev.z).length() / STEP)
		prev = actor.position
		probe.sample("yanchi", actor.position, t)
	assert_true(mover.arrived(), "Yolun sonuna vardı")
	assert_true(top <= 2.9 + 1e-3, "Kare kare de verilen hızı aşmaz (%.3f m/sn)" % top)
	assert_true(probe.peak("yanchi") > 2.5, "Hızına çıkar (%.2f)" % probe.peak("yanchi"))
	actor.queue_free()
	await wait_frames(1)


func test_rider_column_keeps_every_rider_under_the_child_run() -> void:
	var childhood := ChildhoodScene.load_data()
	var proc := _procession(childhood)
	# Sahnenin hızlarıyla ve limit_speeds'le: bütün üyeler sınırda.
	var column := _data_column(childhood)
	var speeds: Dictionary = proc["speeds"]
	column.approach = float(speeds["approach"])
	column.pass_speed = float(speeds["pass"])
	column.leave = float(speeds["leave"])
	column.accel = float(proc["accel"])
	column.limit_speeds(PaceLimit.CHILD_RUN)
	var peaks := _run_column(column)
	for id: String in peaks:
		assert_true(float(peaks[id]) <= PaceLimit.CHILD_RUN + PaceLimit.TOLERANCE, "Atlı %s en çok %.2f m/sn ≤ 3,6" % [id, float(peaks[id])])
	# Eski hızlar (tırıs 3,6, gidiş 4,4) sınırı aşardı: ölçü bunu yakalar.
	var old := _data_column(childhood)
	old.approach = 3.6
	old.leave = 4.4
	var old_peaks := _run_column(old)
	assert_false(PaceLimit.over(old_peaks, PaceLimit.CHILD_RUN).is_empty(), "Eski hızlarla atlılar çocuğun koşusunu aşar")
	# Sınır daha düşükse (oyuncunun koşusu) üç hız onunla iner.
	var slow := _data_column(childhood)
	var k := slow.limit_speeds(2.0)
	assert_almost(slow.approach * k, 2.0, 1e-4)
	assert_almost(slow.leave * k, 2.0, 1e-4)
	assert_true(slow.pass_speed <= 2.0 / k + 1e-6)


# --- Kalabalık -------------------------------------------------------------------------------------------------

func test_crowd_catches_up_without_running() -> void:
	# Saf: planın gerisindeki kişi kendi hızının 1,5 katıyla yetişir, sınırı aşmaz, yolun sonunda durur; çıkmayan yerinde kalır; saat dursa da
	# yola çıkan yürür.
	assert_almost(CrowdPlan.chase(0.0, 30.0, 50.0, 1.2, 3.6, CrowdPlan.HURRY, 1.0), 1.8, 1e-6, "Gerideyken 1,5 kat")
	assert_almost(CrowdPlan.chase(0.0, 30.0, 50.0, 3.0, 3.6, CrowdPlan.HURRY, 1.0), 3.6, 1e-6, "En çok oyuncunun koşusu")
	assert_almost(CrowdPlan.chase(10.0, 10.0, 50.0, 1.2, 3.6, CrowdPlan.HURRY, 1.0), 11.2, 1e-6, "Saat dursa da kendi hızıyla yürür")
	assert_almost(CrowdPlan.chase(49.5, 50.0, 50.0, 1.2, 3.6, CrowdPlan.HURRY, 1.0), 50.0, 1e-6, "Yolun sonunda durur")
	assert_almost(CrowdPlan.chase(0.0, 0.0, 50.0, 1.2, 3.6, CrowdPlan.HURRY, 1.0), 0.0, 1e-6, "Yola çıkmayan yerinde")
	var layout := OrdosWorld.load_layout(LAYOUT)
	var plan := CrowdPlan.build(layout["childhood"]["crowd"], ChildhoodSite.crowd_blockers(layout))
	for p: Dictionary in plan:
		if not bool(p["early"]):
			assert_true(CrowdPlan.own_speed(p) * CrowdPlan.HURRY <= PaceLimit.CHILD_RUN, "Kişinin yetişmesi koşu değil (%.2f m/sn)" % (CrowdPlan.own_speed(p) * CrowdPlan.HURRY))
			break
	# Kartlar: 10:00'da oturur; saat bir anda 11:00'e (görünür akışın en hızlısı) atlar: kimse ışınlanmaz, yürüyenler yetişir.
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ATLAS))
	var crowd := CrowdCards.new()
	crowd.setup(plan, null, meta, load("res://assets/crowd/dailin_cards.png"), load("res://assets/crowd/dailin_cards_normal.png"))
	add_child(crowd)
	crowd.set_minute(600.0)
	crowd._process(STEP)
	var standing_before := int(crowd.counts()["standing"])
	assert_eq(crowd.counts(), crowd.planned_counts(), "İlk yazışta herkes planın yerinde")
	crowd.peak_speed = 0.0
	crowd.set_minute(660.0)
	for i in 30:
		crowd._process(1.0 / 30.0)
	assert_eq(int(crowd.planned_counts()["standing"]), plan.size(), "Planda 11:00'de herkes yerinde")
	assert_true(int(crowd.counts()["walking"]) > 0, "Görünen kalabalık yürüyerek gelir (ışınlanmaz)")
	assert_eq(int(crowd.counts()["absent"]), 0, "Yola çıkması gereken herkes yolda")
	assert_true(crowd.peak_speed <= PaceLimit.CHILD_RUN + 1e-4, "Kalabalık koşmaz (en çok %.2f m/sn)" % crowd.peak_speed)
	assert_true(crowd.peak_speed > 1.0, "Yetişmek için hızlanır (%.2f m/sn)" % crowd.peak_speed)
	for i in 900:
		crowd._process(0.1)
	assert_eq(int(crowd.counts()["standing"]), plan.size(), "Sonunda herkes yerinde")
	assert_true(int(crowd.counts()["standing"]) > standing_before)
	assert_true(crowd.peak_speed <= PaceLimit.CHILD_RUN + 1e-4)
	# snap(): atlanan adımdan başlayan sahne (saat ileri kurulur) kimseyi yürütmez.
	var again := CrowdCards.new()
	again.setup(plan, null, meta, load("res://assets/crowd/dailin_cards.png"), load("res://assets/crowd/dailin_cards_normal.png"))
	add_child(again)
	again.set_minute(520.0)
	again._process(STEP)
	again.set_minute(640.0)
	again.snap()
	again._process(STEP)
	assert_eq(again.counts(), again.planned_counts(), "snap: herkes planın yerine oturur")
	assert_almost(again.peak_speed, 0.0, 1e-6, "Oturmak hız sayılmaz")
	crowd.queue_free()
	again.queue_free()
	await wait_frames(1)


# --- Serbest Gez -------------------------------------------------------------------------------------------------

func test_free_roam_hearth_people_stay_seated() -> void:
	var npcs := NPC_SCENE.instantiate() as CampNpcs
	for avatar in npcs.get_avatars():
		avatar.use_meshy_models = false
	add_child(npcs)
	await wait_frames(2)
	var start := {}
	for avatar in npcs.get_avatars():
		start[avatar.name] = avatar.global_position
	assert_eq(start.size(), 5, "Ateş başında beş kişi")
	await wait_frames(30)
	for avatar in npcs.get_avatars():
		assert_vec_almost(avatar.global_position, start[avatar.name], 1e-5, "%s yerinden kıpırdamaz" % avatar.name)
	npcs.queue_free()
	await wait_frames(1)


# --- Yardımcılar ---------------------------------------------------------------------------------------------------

func _procession(d: Dictionary) -> Dictionary:
	for s: Dictionary in d["steps"]:
		if s.has("procession"):
			return s["procession"]
	return {}


## Verinin yolu ve düzeniyle atlı düzeni (üyeler düğümsüz: yerleri member_pose'dan).
func _data_column(d: Dictionary) -> RiderColumn:
	var proc := _procession(d)
	var pts := PackedVector2Array()
	for p: Array in proc["path"]:
		pts.append(Vector2(float(p[0]), float(p[1])))
	var column := RiderColumn.new(pts)
	column.add(null, Vector2.ZERO)
	for e: Dictionary in proc["escort"]:
		column.add(null, Vector2(float(e["slot"][0]), float(e["slot"][1])))
	return column


## Düzeni sahnedeki gibi sürer (yaklaşma, geçiş, dört saniye, bırakma, gidiş) ve üyelerin en yüksek hızını ölçer.
func _run_column(column: RiderColumn) -> Dictionary:
	var child := Vector2(26.4, -14.5)
	column.pass_at = column.closest_offset(child) - 2.5
	column.start(maxf(column.start_offset_for(10.0), 0.0))
	var probe := PaceLimit.Probe.new()
	var t := 0.0
	var gaze := 0.0
	while not column.finished() and t < 120.0:
		column.tick(STEP)
		t += STEP
		if column.at_pass() and not column.released:
			gaze += STEP
			if gaze >= 4.0:
				column.release()
		for i in column.size():
			var xz: Vector2 = column.member_pose(i)["xz"]
			probe.sample("atli_%d" % i, Vector3(xz.x, 0.0, xz.y), t)
	return probe.peaks
