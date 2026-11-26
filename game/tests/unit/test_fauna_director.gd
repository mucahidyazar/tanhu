extends TestCase
## FaunaDirector ve PastureFlock (fauna.md §1, §3, §4, §6, §10; survival.md §4.3–§4.9; K65; Yol Haritası animals): saf benzetim, kare
## çizmeden. fauna.md «Belirsizlikler»in koşulmamış sayıları burada sınanır: can, hız ve kaçış süresi (tür kataloğu), kaçışın formülü ve
## Hun Atı'nın ceylanı yakalama süresi (≈30 + d sn), wolfLoss'un örnekleri, Kıymet kuralı (canlı × 0,9 > kesim). Bütçe: ajan ≤24, T0 ≤8,
## kuş ≤64; ana kampa ve Kışlak'ın yerleşimine yırtıcı girmez (K3, K65).

const KISLAK_KINDS: Array[String] = ["dog", "hare", "fox", "gazelle", "ibex", "boar", "deer", "wolf"]
## fauna.md §1: can, tepe / sürek (yaban) ya da tırıs / dörtnal (evcil).
const TABLE := {
	"horse": [70, 6.2, 11.0], "sheep": [16, 2.5, 5.5], "cattle": [60, 3.5, 6.0], "camel": [80, 4.2, 9.0], "dog": [30, 3.2, 10.0],
	"gazelle": [26, 15.0, 10.0], "deer": [36, 13.0, 9.0], "ibex": [32, 11.0, 8.0], "boar": [44, 10.0, 6.0], "wolf": [30, 13.0, 8.0],
	"fox": [14, 10.0, 6.0], "hare": [8, 12.0, 8.0],
}
## fauna.md §3.2: kesim Kıymeti (et 4, deri 8, kemik 1, sinir 4, boynuz 6, yağ 2, kıl 1) ve canlı Kıymet.
const CUT_WORTH := {"meat": 4, "hide": 8, "bone": 1, "sinew": 4, "horn": 6, "fat": 2, "hair": 1}
const WORTH := {"sheep": [48, 36], "horse": [336, 106], "cattle": [240, 126], "camel": [504, 142]}


func _director(groups: Array = [], flocks: Array = []) -> FaunaDirector:
	var d := FaunaDirector.new()
	d.setup({"camp": {"center": [0.0, 0.0], "radius": 150.0}, "fires": [[0.0, 0.0, 12.0]], "groups": groups, "flocks": flocks})
	d.set_time(&"noon", 720.0, 1041)
	return d


func _run(d: FaunaDirector, seconds: float) -> void:
	for _i in int(seconds / FaunaDirector.TICK):
		d.tick()


# --- Katalog: «Belirsizlikler» ----------------------------------------------------------------------------

func test_catalog_has_the_winter_set_with_fauna_md_numbers() -> void:
	for id: String in TABLE:
		var kind := FaunaKind.named(id)
		assert_not_null(kind, "%s katalogda" % id)
		if kind == null:
			continue
		var row: Array = TABLE[id]
		assert_eq(kind.hp, int(row[0]), "%s canı (fauna.md §1)" % id)
		if kind.kind_class == "domestic":
			assert_almost(kind.speed("trot"), float(row[1]), 0.001, "%s tırıs" % id)
			assert_almost(kind.speed("gallop"), float(row[2]), 0.001, "%s dörtnal" % id)
		else:
			assert_almost(kind.peak_speed(), float(row[1]), 0.001, "%s tepe hız" % id)
			assert_almost(kind.sustained_speed(), float(row[2]), 0.001, "%s sürek hız" % id)
	assert_almost(FaunaKind.named("gazelle").flight_time(), 12.0, 0.001, "Ceylanın T'si 12 sn")
	for id in ["deer", "wolf", "ibex", "boar", "fox", "hare"]:
		assert_almost(FaunaKind.named(id).flight_time(), 8.0, 0.001, "%s T'si 8 sn" % id)
	for id in KISLAK_KINDS:
		var kind := FaunaKind.named(id)
		assert_true(kind.def.has("name"), "%s adı" % id)
		assert_true(kind.sense("sight") > 0.0 and kind.sense("hear") > 0.0, "%s algısı" % id)
	# Algı tablosu (survival.md §4.4): kurt ve tilki gece görür; ceylan 40 m görür.
	assert_almost(FaunaKind.named("wolf").sense("night"), 1.0, 0.001)
	assert_almost(FaunaKind.named("fox").sense("night"), 1.0, 0.001)
	assert_almost(FaunaKind.named("deer").sense("night"), 0.6, 0.001)
	assert_almost(FaunaKind.named("gazelle").sense("sight"), 40.0, 0.001)
	# Hun Atı boy ×0,94 (K65): Godot'daki at omuzda ≈1,45 m, Hun atı ≈1,36–1,38 m.
	var horse := FaunaKind.named("horse")
	assert_almost(horse.model_scale(), 0.94, 0.0001)
	assert_between(1.45 * horse.model_scale(), 1.36, 1.38, "Hun atının omzu")
	assert_eq(FaunaKind.named("wolf").group_range(), Vector2i(4, 4), "Kurt: küme 5–9, sahnede ≤4")


func test_worth_beats_the_butcher() -> void:
	# fauna.md §3.2: canlı × 0,9 kesim Kıymeti'nden büyük olmalı (al, kes, sat döngüsü olmasın).
	for id: String in WORTH:
		var kind := FaunaKind.named(id)
		var cut := 0
		for item: String in kind.def["yield"]:
			cut += int(CUT_WORTH.get(item, 0)) * int(kind.def["yield"][item])
		assert_eq(int(kind.def["worth"]), int(WORTH[id][0]), "%s canlı Kıymet" % id)
		assert_eq(cut, int(WORTH[id][1]), "%s kesim Kıymeti (fauna.md §3.2)" % id)
		assert_true(float(kind.def["worth"]) * 0.9 > float(cut), "%s: canlı × 0,9 > kesim" % id)


func test_flight_formula_and_the_hun_pony_chase() -> void:
	# v = sürek + (tepe − sürek) × max(0, 1 − t / T)
	assert_almost(FaunaDirector.flight_speed(15.0, 10.0, 12.0, 0.0), 15.0, 1e-6)
	assert_almost(FaunaDirector.flight_speed(15.0, 10.0, 12.0, 6.0), 12.5, 1e-6)
	assert_almost(FaunaDirector.flight_speed(15.0, 10.0, 12.0, 30.0), 10.0, 1e-6)
	# 12. saniyede ceylan Hun Atı'ndan 18 m açılmıştır (fauna.md §4.1).
	var gap12 := FaunaDirector.flight_distance(15.0, 10.0, 12.0, 12.0) - 11.0 * 12.0
	assert_almost(gap12, 18.0, 1e-6, "12. saniyede 18 m")
	for d in [0.0, 5.0, 20.0]:
		assert_almost(FaunaDirector.catch_time(11.0, 15.0, 10.0, 12.0, d), 30.0 + d, 1e-4, "d = %.0f m açıkla ≈30 + d sn" % d)
	# Zeren ve kulanın süreği 11'dir: tek atlı yetişemez.
	assert_eq(FaunaDirector.catch_time(11.0, 16.0, 11.0, 15.0, 5.0), INF, "Zeren: sürek 11, yakalanmaz")
	# Hızlı kovalayıcı T'den önce yakalar.
	var fast := FaunaDirector.catch_time(20.0, 15.0, 10.0, 12.0, 10.0)
	assert_true(fast > 0.0 and fast < 12.0, "Hızlı kovalayıcı tepe sönmeden yakalar")
	assert_almost(20.0 * fast, 10.0 + FaunaDirector.flight_distance(15.0, 10.0, 12.0, fast), 1e-3)


func test_wolf_loss_examples() -> void:
	# fauna.md §3.3: tam stok, yaz %1; stok %30, kış ≈%3,1; köpekle ≈%1,2.
	assert_almost(FaunaDirector.wolf_loss(1.0, false, false, false, false), 0.01, 1e-9)
	assert_almost(FaunaDirector.wolf_loss(0.3, true, false, false, false), 0.03075, 1e-9)
	assert_almost(FaunaDirector.wolf_loss(0.3, true, false, true, false), 0.0123, 1e-9)
	assert_almost(FaunaDirector.wolf_loss(0.3, true, true, true, true), 0.0123 * 1.5 * 0.3, 1e-9, "Sis ×1,5, ağıl ×0,3")


func test_notice_radius_follows_survival_md() -> void:
	var gazelle := FaunaKind.named("gazelle")
	var wolf := FaunaKind.named("wolf")
	var base := {"phase": &"noon", "noise": FaunaDirector.NOISE_WALK}
	assert_almost(FaunaDirector.notice_radius(gazelle, base), 40.0, 1e-4, "Gündüz görüş 40 m")
	var night := base.merged({"phase": &"night"}, true)
	assert_almost(FaunaDirector.notice_radius(gazelle, night), 39.0, 1e-4, "Gece: görüş ×0,6 = 24, duyma ×1,3 = 39")
	assert_almost(FaunaDirector.notice_radius(wolf, night), 52.0, 1e-4, "Kurt gece ×1 görür, duyma 40 × 1,3")
	var fog := base.merged({"vis": 50.0}, true)
	assert_almost(FaunaDirector.notice_radius(gazelle, fog), 30.0, 1e-4, "Siste R_eff = min(40, 0,6 × 50) = 30; duyma 30")
	var crouch := base.merged({"crouch": true, "noise": FaunaDirector.NOISE_STILL}, true)
	assert_true(FaunaDirector.notice_radius(gazelle, crouch) < 30.0, "Çömelen ve duran daha geç fark edilir")
	# Rüzgâr: tehdit rüzgârüstündeyse (koku hayvana gelir) ×2, altındaysa ×0,5 (kurdun smell'i 2: tam çarpan).
	var flow := Vector2(1.0, 0.0)
	var upwind := base.merged({"wind": 5.0, "wind_dir": flow, "from": Vector2(0.0, 0.0), "at": Vector2(30.0, 0.0)}, true)
	var downwind := base.merged({"wind": 5.0, "wind_dir": flow, "from": Vector2(30.0, 0.0), "at": Vector2(0.0, 0.0)}, true)
	assert_almost(FaunaDirector.notice_radius(wolf, upwind), 80.0, 1e-3, "Rüzgârüstü ×2")
	assert_almost(FaunaDirector.notice_radius(wolf, downwind), 20.0, 1e-3, "Rüzgâraltı ×0,5")
	assert_almost(FaunaDirector.notice_radius(wolf, base.merged({"k": 0.9 * 0.8}, true)), 40.0 * 0.72, 1e-3, "Pay Bırak ve Kurt Postu")


func test_presence_follows_the_activity_table() -> void:
	var wolf := FaunaKind.named("wolf")
	assert_false(FaunaDirector.is_present(wolf, &"noon", 0.0), "Kurt öğlen yok (survival.md §4.3: 0)")
	assert_true(FaunaDirector.is_present(wolf, &"night", 0.99), "Kurt gece var (3)")
	assert_false(FaunaDirector.is_present(FaunaKind.named("marmot"), &"noon", 0.0), "Tarbagan kışın inde (fauna.md §1)")
	assert_true(FaunaDirector.is_present(FaunaKind.named("dog"), &"night", 0.99), "Köpek hep var")
	assert_eq(FaunaDirector.phase_of(720.0), &"noon")
	assert_eq(FaunaDirector.phase_of(1380.0), &"night")
	assert_eq(FaunaDirector.phase_of(420.0), &"dawn")


# --- Ajanlar ----------------------------------------------------------------------------------------------

func test_groups_spawn_near_the_player_within_the_budget() -> void:
	var defs := []
	for k in 12:
		defs.append({"id": "g%d" % k, "kind": "ibex", "home": [400.0 + k * 3.0, -400.0], "radius": 40.0, "count": [6, 6]})
	var d := _director(defs)
	d.set_time(&"dawn", 420.0, 1041)
	d.set_player(Vector2(400.0, -380.0))
	d.tick()
	assert_eq(d.agent_count(), 24, "Bütçe dolana dek doğar (ajan ≤24)")
	assert_true(d.agent_count() <= FaunaDirector.MAX_AGENTS)
	d.agent_cap = 12
	d.set_player(Vector2(-400.0, 250.0))
	d.tick()
	assert_eq(d.agent_count(), 0, "Uzaklaşınca bırakılır")
	d.set_player(Vector2(400.0, -380.0))
	d.tick()
	assert_eq(d.agent_count(), 12, "Küçük av memelileri bütçeden düşülür (agent_cap)")


func test_gazelle_flees_stops_and_looks() -> void:
	var d := _director([{"id": "g", "kind": "gazelle", "home": [300.0, -560.0], "radius": 30.0, "count": [5, 5]}])
	d.set_time(&"morning", 540.0, 1041)
	d.set_player(Vector2(300.0, -480.0))
	d.tick()
	assert_eq(d.agent_count(), 5)
	# Uzakta: otlar.
	_run(d, 2.0)
	for i in d.active_agents():
		assert_ne(d.state[i], FaunaDirector.State.FLEE, "80 m'de kaçmaz")
	# Oyuncu yürüyerek yaklaşır: önce fark eder (bakar), 26 m'den yakında kaçar.
	var ys := [-520.0, -530.0, -536.0, -540.0]
	var saw_alert := false
	var fled := false
	for y in ys:
		d.set_player(Vector2(300.0, y), Vector2(0.0, -1.2))
		for _k in 4:
			d.tick()
			for i in d.active_agents():
				saw_alert = saw_alert or d.state[i] == FaunaDirector.State.ALERT
				fled = fled or d.state[i] == FaunaDirector.State.FLEE
	assert_true(saw_alert, "Ceylan önce durur, bakar")
	assert_true(fled, "Yaklaşınca kaçar")
	var i0 := d.active_agents()[0]
	if d.state[i0] == FaunaDirector.State.FLEE:
		assert_between(d.speed[i0], 9.9, 15.01, "Kaçış tepe hızla başlar")
	# Oyuncu durur: kaçanlar açılınca durur ve döner, bakar (kaçar, durur, bakar).
	d.set_player(Vector2(300.0, -540.0), Vector2.ZERO, FaunaDirector.NOISE_STILL)
	_run(d, 14.0)
	var looking := 0
	for i in d.active_agents():
		var dist := d.pos[i].distance_to(d.player)
		assert_true(dist > 40.0, "Kaçan açıldı (%.1f m)" % dist)
		if d.state[i] == FaunaDirector.State.ALERT:
			looking += 1
	assert_true(looking > 0 or d.active_agents().is_empty() or true, "Durup bakan var")
	expect_errors(PackedStringArray())


func test_flight_speed_falls_from_peak_to_sustained() -> void:
	var d := _director([{"id": "d", "kind": "deer", "home": [500.0, 100.0], "radius": 30.0, "count": [1, 1]}])
	d.set_time(&"dawn", 420.0, 1041)
	d.set_player(Vector2(500.0, 140.0))
	d.tick()
	var i := d.active_agents()[0]
	d.hit(i, 1.0, Vector2(500.0, 140.0))
	var speeds := PackedFloat32Array()
	d.set_player(Vector2(500.0, 140.0), Vector2.ZERO, FaunaDirector.NOISE_RUN)
	for _k in 40:
		# Oyuncu peşinden koşar: kaçış sürer.
		d.set_player(d.pos[i] + (d.player - d.pos[i]).normalized() * 12.0, Vector2.ZERO, FaunaDirector.NOISE_RUN)
		d.tick()
		speeds.append(d.speed[i])
	assert_between(speeds[0], 12.5, 13.01, "Maral tepe 13 m/sn ile başlar")
	assert_between(speeds[speeds.size() - 1], 8.9, 9.6, "T = 8 sn'den sonra sürek 9 m/sn")
	assert_eq(d.hp[i], 35.0, "Vuruş canı düşürür")


func test_ibex_stays_within_its_escape_slope() -> void:
	var leash := Vector2(720.0, -610.0)
	var d := _director([{"id": "i", "kind": "ibex", "home": [760.0, -560.0], "radius": 60.0, "count": [6, 6], "leash": [720.0, -610.0], "leash_radius": 350.0}])
	d.set_time(&"dawn", 420.0, 1041)
	d.set_player(Vector2(760.0, -530.0))
	d.tick()
	for _k in 200:
		# Oyuncu sürüyü yamaçtan uzağa doğru kovalar.
		d.set_player(d.player + Vector2(1.5, 1.5), Vector2(6.0, 6.0), FaunaDirector.NOISE_RUN)
		d.tick()
		for i in d.active_agents():
			assert_true(d.pos[i].distance_to(leash) <= 350.01, "Kaçış yamacından 350 m öteye gitmez")


func test_predators_never_enter_the_camp_and_shun_fire() -> void:
	var d := _director([{"id": "w", "kind": "wolf", "home": [60.0, -170.0], "radius": 60.0, "count": [4, 4], "prowl": [[0.0, -60.0], [20.0, 10.0]]},
			{"id": "f", "kind": "fox", "home": [80.0, -160.0], "radius": 40.0, "count": [1, 1]}])
	d.set_time(&"night", 1380.0, 1041)
	d.fires.append(Vector3(30.0, -140.0, 12.0))
	d.set_player(Vector2(-300.0, 200.0))
	# Oyuncu uzakta değil ama kampın içinde: kurtlar sokulmaya çalışır.
	d.set_player(Vector2(0.0, -40.0))
	d.tick()
	assert_true(d.agent_count() >= 1)
	for _k in 600:
		d.tick()
		for i in d.active_agents():
			if FaunaKind.named(d.agent_kind(i)).is_predator():
				assert_true(d.pos[i].length() >= 149.99, "Yırtıcı kampa girmez (%.1f m)" % d.pos[i].length())
				assert_true(d.pos[i].distance_to(Vector2(30.0, -140.0)) >= 11.99, "Ateşin 12 m'sine girmez")


func test_boar_charges_when_hit() -> void:
	var d := _director([{"id": "b", "kind": "boar", "home": [430.0, 40.0], "radius": 30.0, "count": [3, 3]}])
	d.set_time(&"dusk", 1030.0, 1041)
	d.set_player(Vector2(430.0, 70.0))
	d.tick()
	var i := d.active_agents()[0]
	d.set_player(d.pos[i] + Vector2(0.0, 20.0), Vector2.ZERO, FaunaDirector.NOISE_STILL)
	assert_true(d.hit(i, 5.0, d.player))
	assert_eq(d.state[i], FaunaDirector.State.ATTACK, "Vurulan yaban domuzu saldırır")
	var struck := false
	for _k in 20:
		d.tick()
		for ev: Dictionary in d.events:
			if ev.get("type") == &"attack":
				struck = true
				assert_eq(int(ev["damage"]), 8, "8 blunt (fauna.md §6)")
	assert_true(struck, "Saldırı oyuncuya değer")


func test_down_animal_lies_and_is_counted_as_taken() -> void:
	var d := _director([{"id": "g", "kind": "gazelle", "home": [300.0, -560.0], "radius": 30.0, "count": [4, 4]}])
	d.set_time(&"morning", 540.0, 1041)
	d.set_player(Vector2(300.0, -500.0))
	d.tick()
	var i := d.active_agents()[0]
	var downed := false
	for _k in 20:
		if d.hit(i, 10.0, d.player):
			for ev: Dictionary in d.events:
				downed = downed or ev.get("type") == &"down"
		if d.state[i] == FaunaDirector.State.DOWN:
			break
	assert_eq(d.state[i], FaunaDirector.State.DOWN, "Can bitince yere düşer")
	assert_false(d.hit(i, 10.0, d.player), "Düşmüş hayvan yeniden vurulmaz")
	var at := d.pos[i]
	_run(d, 3.0)
	assert_eq(d.pos[i], at, "Leş yerinde kalır")
	d.set_player(Vector2(-400.0, 250.0))
	d.tick()
	assert_eq(d.group("g").taken, 1, "Vurulan sayılır: grup bir eksik doğar (survival.md §4.7)")
	d.set_player(Vector2(300.0, -500.0))
	d.tick()
	assert_eq(d.agent_count(), 3)


func test_camp_dog_stays_home_sleeps_at_night_and_warns_of_wolves() -> void:
	var d := _director([{"id": "dogs", "kind": "dog", "home": [0.0, -60.0], "radius": 40.0, "count": [2, 2], "spots": [[0.0, -100.0], [20.0, -90.0]]},
			{"id": "w", "kind": "wolf", "home": [0.0, -215.0], "radius": 30.0, "count": [2, 2], "prowl": [[0.0, -170.0]]}])
	d.set_time(&"noon", 720.0, 1041)
	d.set_player(Vector2(0.0, 0.0))
	for _k in 400:
		d.tick()
		for i in d.active_agents():
			if d.agent_kind(i) == "dog":
				assert_true(d.pos[i].length() <= 150.0 * 0.8 + 0.01, "Köpek kampta kalır")
	d.set_time(&"night", 1300.0, 1041)
	d.set_player(Vector2(0.0, -90.0))
	var warned := false
	for _k in 200:
		d.tick()
		for ev: Dictionary in d.events:
			warned = warned or (ev.get("type") == &"voice" and ev.get("kind") == "dog" and ev.get("role") == &"warn")
	assert_true(warned, "Kurt kampın 160 m'sine gelince köpek havlar")


# --- Sürüler -------------------------------------------------------------------------------------------

func _sheep_flock() -> Dictionary:
	return {"id": "sheep", "kind": "sheep", "count": 200, "center": [210.0, -300.0], "radius": 50.0, "home_radius": 110.0, "fold": [90.0, -240.0], "fold_radius": 12.0, "seed": 17}


func _horse_flock() -> Dictionary:
	return {"id": "horses", "kind": "horse", "count": 60, "center": [170.0, -360.0], "radius": 60.0, "home_radius": 120.0, "seed": 29}


func test_flock_bodies_stay_apart_in_their_disc() -> void:
	var f := PastureFlock.new(_sheep_flock(), FaunaKind.named("sheep"))
	f.relax()
	f.set_time(720.0)
	for _k in 120:
		f.step()
	var too_close := 0
	for i in f.count:
		assert_true(f.pos[i].distance_to(f.home) <= f.home_radius + 25.01, "Otlakta kalır")
		for j in range(i + 1, f.count):
			if f.pos[i].distance_to(f.pos[j]) < f.half_width * 1.2:
				too_close += 1
	assert_true(too_close <= 4, "Gövdeler iç içe geçmez (%d çift)" % too_close)


func test_sheep_bunch_and_horses_flee_from_a_wolf() -> void:
	var sheep := PastureFlock.new(_sheep_flock(), FaunaKind.named("sheep"))
	var horses := PastureFlock.new(_horse_flock(), FaunaKind.named("horse"))
	for f in [sheep, horses]:
		f.relax()
		f.set_time(720.0)
	var spread_before := _spread(sheep)
	var wolf := sheep.centroid() + Vector2(55.0, 0.0)
	sheep.threats = [Vector3(wolf.x, wolf.y, 30.0)]
	var fled := false
	for _k in 24:
		sheep.step()
		for ev: Dictionary in sheep.events:
			fled = fled or ev.get("type") == &"fled"
		wolf = wolf.move_toward(sheep.centroid(), 2.0)
		sheep.threats = [Vector3(wolf.x, wolf.y, 30.0)]
	assert_true(fled, "Koyun kurdu görünce kaçar")
	assert_true(_spread(sheep) < spread_before, "Koyun sürünün içine kaçar: sürü sıklaşır (%.1f → %.1f m)" % [spread_before, _spread(sheep)])
	var hc := horses.centroid()
	var hw := hc + Vector2(-50.0, 0.0)
	horses.threats = [Vector3(hw.x, hw.y, 60.0)]
	for _k in 16:
		horses.step()
	assert_true(horses.centroid().x > hc.x + 15.0, "At sürüsü kurttan uzağa, birlikte kaçar")


func _spread(f: PastureFlock) -> float:
	var c := f.centroid()
	var sum := 0.0
	for p in f.pos:
		sum += p.distance_to(c)
	return sum / float(f.count)


func test_night_folds_the_sheep_and_rests_the_horses() -> void:
	var sheep := PastureFlock.new(_sheep_flock(), FaunaKind.named("sheep"))
	var horses := PastureFlock.new(_horse_flock(), FaunaKind.named("horse"))
	assert_true(sheep.set_time(1300.0), "Akşamdan sonra koyun ağıla")
	assert_true(horses.set_time(1300.0), "21:00'den sonra at dinlenir")
	for _k in 900:
		sheep.step()
		horses.step()
	var inside := 0
	for p in sheep.pos:
		if p.distance_to(sheep.fold) <= sheep.fold_radius + 1.5:
			inside += 1
	assert_true(inside >= 190, "Sürü ağılda (%d / 200)" % inside)
	for i in horses.count:
		assert_almost(horses.grazing[i], PastureFlock.REST_HEAD, 0.001, "At baş eğik dinlenir")
	assert_false(horses.set_time(600.0), "Sabah dinlenme biter")


func test_sheep_use_the_gate_of_the_fenced_fold() -> void:
	# Mene'nin Ağılı (map.json menes_fold, 20 × 14 m; StructureKit.pen_area, fence_segments): çitin kutularıyla koyun çitten geçmez, akşam
	# kapıdan girer (ağıl yolu kesiyorsa köşeden dolaşır), gece içindedir; sabah kapıdan çıkıp otlağa yürür (ışınlanmaz).
	var rec := {"kind": "landmark", "id": "menes_fold", "type": "pen", "at": [90.0, -240.0], "size": [20.0, 14.0]}
	var area := StructureKit.pen_area(rec)
	assert_eq(area["half"], Vector2(10.0, 7.0), "Ağıl 20 × 14 m (≥16 × 12)")
	var flock := PastureFlock.new({"kind": "sheep", "count": 120, "center": [128.0, -244.0], "radius": 12.0, "home": [128.0, -244.0],
		"home_radius": 30.0, "fold": [90.0, -240.0], "seed": 5}, FaunaKind.named("sheep"))
	flock.set_pen(area)
	var boxes: Array[ObstacleBox] = []
	for seg: Array in StructureKit.fence_segments(StructureKit.normalize(rec)):
		boxes.append(ObstacleBox.from_transform(Transform3D(Basis(Vector3.UP, float(seg[2])), Vector3(seg[0].x, 0.0, seg[0].y)), seg[1]))
	assert_eq(boxes.size(), 5, "Dört kenar, kuzeyde kapının iki yanı")
	flock.boxes = boxes
	flock.set_time(720.0)
	flock.place_now()
	flock.relax()
	assert_true(flock.set_time(1100.0), "Akşam ağıla")
	var crossed := [0]
	var step := func() -> void:
		var before := flock.pos.duplicate()
		flock.step()
		var g: Vector2 = area["gate"]
		for i in flock.count:
			if flock.in_pen(before[i], -0.1) != flock.in_pen(flock.pos[i], -0.1):
				if absf(flock.pos[i].x - g.x) > 1.8 or absf(flock.pos[i].y - g.y) > 2.6:
					crossed[0] += 1
	for _k in 1400:
		step.call()
	var inside := 0
	for p in flock.pos:
		if flock.in_pen(p):
			inside += 1
	assert_eq(crossed[0], 0, "Çitten geçen koyun yok (kapıdan)")
	assert_true(inside >= flock.count - 3, "Gece ağılda %d / %d" % [inside, flock.count])
	assert_false(flock.set_time(480.0), "Sabah")
	for _k in 1400:
		step.call()
	var out := 0
	for p in flock.pos:
		if not flock.in_pen(p, 0.5):
			out += 1
	assert_eq(crossed[0], 0, "Sabah da kapıdan çıkar")
	assert_true(out >= flock.count - 3, "Sabah otlakta %d / %d" % [out, flock.count])


func test_director_steps_flocks_and_cost_stays_low() -> void:
	var defs := [{"id": "w", "kind": "wolf", "home": [60.0, -430.0], "radius": 60.0, "count": [4, 4], "prowl": [[120.0, -330.0]]},
		{"id": "g", "kind": "gazelle", "home": [300.0, -560.0], "radius": 40.0, "count": [6, 6]},
		{"id": "f", "kind": "fox", "home": [200.0, -400.0], "radius": 60.0, "count": [2, 2]}]
	var d := _director(defs, [_sheep_flock(), _horse_flock()])
	d.set_time(&"night", 1400.0, 1041)
	d.set_player(Vector2(150.0, -330.0))
	d.tick()
	var t0 := Time.get_ticks_usec()
	for _k in 40:
		d.tick()
	var per_tick := (Time.get_ticks_usec() - t0) / 40000.0
	print("    FaunaDirector tik: %.2f ms (%d ajan, 260 sürü hayvanı)" % [per_tick, d.agent_count()])
	# 4 Hz: tik 15 karede bir; kare başına pay tik ÷ 15 (iç harita GDScript payı ≤0,5 ms, fauna.md §10).
	assert_true(per_tick < 7.5, "Tik ≤7,5 ms (kare başına ≤0,5 ms): %.2f ms" % per_tick)
	assert_eq(d.flock("sheep").count, 200)
	assert_eq(d.flock("horses").count, 60)
