extends TestCase
## Oyuncak yayın hesabı (saf): Projectiles (analitik yay, havuz, çarpışma), BowDraw (germe, bırakma, yayılma), Weapons (data/combat/weapons.json; progression.md §7.2).

const DT := 1.0 / 60.0


func _flat(_x: float, _z: float) -> float:
	return 0.0


func _wall(_x: float, _z: float) -> float:
	return 0.5


# --- Veri --------------------------------------------------------------------------------------------

func test_toy_bow_row_is_the_design_table() -> void:
	Weapons.reset_cache()
	var bow := Weapons.bow("toy_bow")
	assert_almost(float(bow["dmg"]), 1.0, 0.0001, "Hasar 1")
	assert_eq(int(bow["pull"]), 0, "Bilek okumaz")
	assert_almost(float(bow["draw"]), 0.4, 0.0001, "Çekiş 0,4 sn")
	assert_almost(float(bow["spread"]), 6.0, 0.0001, "Yayılma 6°")
	assert_almost(float(bow["range"]), 14.0, 0.0001, "Menzil 14 m")
	assert_almost(float(bow["sta"]), 1.0, 0.0001)
	assert_almost(float(bow["load"]), 0.3, 0.0001)
	var arrow := Weapons.arrow_of("toy_bow")
	assert_eq(str(arrow["tag"]), "toy_arrow")
	assert_true(bool(arrow["blunt"]), "Küt ok")
	assert_almost(float(arrow["drift"]), 0.25, 0.0001, "Rüzgâr katsayısı (weather.md §8.8)")
	assert_true(Weapons.bow("yok").is_empty())


# --- Yörünge -----------------------------------------------------------------------------------------

func test_path_lands_on_the_target_with_the_arc_height() -> void:
	var from := Vector3(1.0, 0.8, 2.0)
	var to := Vector3(9.0, 0.2, 8.0)
	var path := Projectiles.solve(from, to, 22.0, 0.06)
	var time: float = path["time"]
	assert_almost(time, from.distance_to(to) / 22.0, 0.0001, "Süre = uzaklık / hız")
	assert_vec_almost(Projectiles.point_at(from, path["velocity"], path["gravity"], time), to, 0.0001, "Tam hedefe iner")
	assert_vec_almost(Projectiles.point_at(from, path["velocity"], path["gravity"], 0.0), from, 0.0001)
	var mid := Projectiles.point_at(from, path["velocity"], path["gravity"], time * 0.5)
	var chord := from.lerp(to, 0.5)
	assert_almost(mid.y - chord.y, 0.06 * Vector2(to.x - from.x, to.z - from.z).length(), 0.0001, "Tepe kirişin arc × yatay uzaklık üstünde")
	assert_almost(mid.x, chord.x, 0.0001, "Yatayda düz gider")


func test_closest_shot_does_not_divide_by_zero_and_flat_path_has_no_gravity() -> void:
	var same := Projectiles.solve(Vector3.ONE, Vector3.ONE, 22.0, 0.06)
	assert_almost(float(same["time"]), 0.05, 0.0001, "Üst üste nokta: en kısa süre")
	var flat := Projectiles.solve(Vector3.ZERO, Vector3(10.0, 0.0, 0.0), 20.0, 0.0)
	assert_almost(float(flat["gravity"]), 0.0, 0.0001)
	assert_vec_almost(flat["velocity"], Vector3(20.0, 0.0, 0.0), 0.0001)


func test_wind_drifts_the_landing_and_predict_agrees() -> void:
	var pool := Projectiles.new()
	var from := Vector3(0.0, 1.0, 0.0)
	var to := Vector3(10.0, 0.0, 0.0)
	var drift := 0.25
	var wind := Vector2(0.0, 2.0)
	var landing := Projectiles.predict(from, to, 22.0, wind * drift)
	pool.fire(from, to, {"speed": 22.0, "arc": 0.06, "blunt": true, "wind": wind, "drift": drift})
	var events: Array[Dictionary] = []
	for i in 120:
		events.append_array(pool.step(DT, _flat))
	assert_eq(events.size(), 1, "Bir kez iner")
	var point: Vector3 = events[0]["point"]
	assert_almost(point.x, landing.x, 0.2, "Rüzgârda iniş halkanın gösterdiği yer (x)")
	assert_almost(point.z, landing.z, 0.08, "Rüzgârda iniş halkanın gösterdiği yer (z)")
	assert_true(landing.z > 0.0, "Rüzgâr yana iter")


func test_segment_sphere() -> void:
	assert_almost(Projectiles.segment_sphere(Vector3(-2.0, 0.0, 0.0), Vector3(2.0, 0.0, 0.0), Vector3.ZERO, 1.0), 0.25, 0.0001, "İlk değdiği oran")
	assert_almost(Projectiles.segment_sphere(Vector3(0.2, 0.0, 0.0), Vector3(3.0, 0.0, 0.0), Vector3.ZERO, 1.0), 0.0, 0.0001, "İçinden başlayan: 0")
	assert_almost(Projectiles.segment_sphere(Vector3(-2.0, 2.0, 0.0), Vector3(2.0, 2.0, 0.0), Vector3.ZERO, 1.0), -1.0, 0.0001, "Geçmez")
	assert_almost(Projectiles.segment_sphere(Vector3(2.0, 0.0, 0.0), Vector3(5.0, 0.0, 0.0), Vector3.ZERO, 1.0), -1.0, 0.0001, "Uzaklaşan geçmez")
	assert_almost(Projectiles.segment_sphere(Vector3(-2.0, 0.0, 0.0), Vector3(-1.5, 0.0, 0.0), Vector3.ZERO, 1.0), -1.0, 0.0001, "Kesit kısa kalır")


# --- Havuz -------------------------------------------------------------------------------------------

func test_blunt_arrow_lies_on_the_ground_and_fades_away() -> void:
	var pool := Projectiles.new()
	pool.fire(Vector3(0.0, 1.0, 0.0), Vector3(8.0, 0.5, 0.0), {"speed": 22.0, "arc": 0.06, "blunt": true})
	assert_eq(pool.flying_count(), 1)
	var events: Array[Dictionary] = []
	for i in 180:
		events.append_array(pool.step(DT, _wall))
	assert_eq(events.size(), 1, "Tek iniş olayı")
	assert_eq(str(events[0]["type"]), Projectiles.EVENT_GROUND)
	assert_eq(pool.resting_count(), 1, "Yerde yatar")
	var rest: Vector3 = pool.shots[0].rest_at
	assert_almost(rest.y, 0.5 + Projectiles.REST_LIFT, 0.001, "Zeminin üstünde")
	assert_almost(absf(pool.shots[0].direction().y), 0.04, 0.01, "Saplanmaz, yatay yatar")
	assert_almost(pool.transforms()[0].basis.get_scale().x, 1.0, 0.001, "Tam boy")
	for i in int((Projectiles.GROUND_S - Projectiles.FADE_S * 0.5 - 3.0) / DT):
		pool.step(DT, _wall)
	var fading := pool.transforms()[0].basis.get_scale().x
	assert_between(fading, 0.05, 0.95, "Son iki saniyede küçülür")
	for i in int(Projectiles.GROUND_S / DT):
		pool.step(DT, _wall)
	assert_eq(pool.shots.size(), 0, "Sonra silinir")


func test_sharp_arrow_sticks_in_the_ground() -> void:
	var pool := Projectiles.new()
	pool.fire(Vector3(0.0, 1.0, 0.0), Vector3(8.0, 0.0, 0.0), {"speed": 38.0, "arc": 0.06, "blunt": false})
	for i in 120:
		pool.step(DT, _flat)
	assert_eq(pool.resting_count(), 1)
	assert_true(pool.shots[0].rest_at.y < 0.0, "Gömülür")
	assert_true(pool.shots[0].direction().y < -0.05, "Eğik durur")


func test_arrow_hits_the_first_target_on_its_path_and_blunt_bounces() -> void:
	var pool := Projectiles.new()
	var near := {"id": "yakın", "center": Vector3(4.0, 0.8, 0.0), "radius": 0.3}
	var far := {"id": "uzak", "center": Vector3(7.0, 0.5, 0.0), "radius": 0.3}
	pool.fire(Vector3(0.0, 0.8, 0.0), Vector3(9.0, 0.0, 0.0), {"speed": 22.0, "arc": 0.02, "blunt": true, "info": {"tag": "toy_arrow"}})
	var hits: Array[Dictionary] = []
	for i in 180:
		for event in pool.step(DT, _flat, [far, near]):
			if event["type"] == Projectiles.EVENT_HIT:
				hits.append(event)
	assert_eq(hits.size(), 1, "Küt ok bir kez vurur, sekince bir daha vurmaz")
	if hits.size() == 1:
		assert_eq(hits[0]["target"], "yakın", "Yoldaki ilk hedef")
		assert_eq(str((hits[0]["info"] as Dictionary)["tag"]), "toy_arrow")
		assert_true((hits[0]["point"] as Vector3).distance_to(near["center"]) < 0.45, "Vuruş noktası kürenin üstünde")
	assert_eq(pool.resting_count(), 1, "Seken ok yere iner, yatar")


func test_sharp_arrow_is_removed_on_hit() -> void:
	var pool := Projectiles.new()
	pool.fire(Vector3(0.0, 0.8, 0.0), Vector3(9.0, 0.0, 0.0), {"speed": 38.0, "arc": 0.0, "blunt": false})
	var hit := 0
	for i in 60:
		for event in pool.step(DT, _flat, [{"id": 1, "center": Vector3(4.0, 0.45, 0.0), "radius": 0.4}]):
			if event["type"] == Projectiles.EVENT_HIT:
				hit += 1
	assert_eq(hit, 1)
	assert_eq(pool.shots.size(), 0)


func test_fast_arrow_does_not_skip_a_thin_target_on_a_long_frame() -> void:
	var pool := Projectiles.new()
	pool.fire(Vector3.ZERO, Vector3(14.0, 0.0, 0.0), {"speed": 60.0, "arc": 0.0, "blunt": true})
	var events := pool.step(0.2, Callable(), [{"id": "ince", "center": Vector3(7.0, 0.0, 0.0), "radius": 0.05}])
	assert_eq(events.size(), 1, "Uzun karede alt adımlarla bakılır")


func test_flight_times_out_without_ground_and_the_pool_recycles_the_oldest() -> void:
	var pool := Projectiles.new()
	pool.fire(Vector3.ZERO, Vector3(5.0, 5.0, 0.0), {"speed": 22.0, "arc": 0.0})
	for i in int(Projectiles.MAX_FLIGHT / DT) + 2:
		pool.step(DT)
	assert_eq(pool.shots.size(), 0, "Süresi dolan ok silinir")
	var ids: Array[int] = []
	for i in Projectiles.CAPACITY + 5:
		ids.append(pool.fire(Vector3.ZERO, Vector3(5.0, 0.0, 0.0), {"speed": 22.0, "arc": 0.0}))
	assert_eq(pool.shots.size(), Projectiles.CAPACITY, "Havuz sınırı")
	var alive: Array[int] = []
	for shot in pool.shots:
		alive.append(shot.id)
	assert_false(alive.has(ids[0]), "En eski geri alındı")
	assert_true(alive.has(ids[ids.size() - 1]), "Yeni ok uçuyor")
	pool.clear()
	assert_eq(pool.shots.size(), 0)


# --- Germe -------------------------------------------------------------------------------------------

func _spec() -> Dictionary:
	return Weapons.bow("toy_bow")


func test_quick_click_draws_to_the_minimum_then_looses() -> void:
	var draw := BowDraw.new(_spec())
	assert_true(draw.begin())
	assert_false(draw.begin(), "İkinci germe yok")
	draw.release()
	var fired := false
	var seconds := 0.0
	while not fired and seconds < 1.0:
		fired = draw.tick(DT)
		seconds += DT
	assert_true(fired, "Kısa tıklama da atar")
	assert_almost(seconds, 0.2 * 0.4, DT * 1.5, "min_draw × çekiş süresi")
	assert_almost(draw.loosed_k, 0.2, 0.05, "Az gerilmiş")
	assert_false(draw.is_drawing())
	assert_true(BowDraw.reach_k(draw.loosed_k) < 0.7, "Az gerilen kısa düşer")
	assert_true(BowDraw.speed_k(draw.loosed_k) < 0.75)
	assert_false(draw.begin(), "Bekleme süresi")
	for i in 12:
		draw.tick(DT)
	assert_true(draw.begin(), "Bekleme bitince gerilir")


func test_spread_narrows_while_drawing_and_steady_holding() -> void:
	var draw := BowDraw.new(_spec())
	draw.begin()
	var loose_spread := draw.spread_deg()
	assert_almost(loose_spread, 6.0 * BowDraw.SLACK_SPREAD, 0.001, "Gevşekken geniş")
	for i in int(0.4 / DT) + 1:
		draw.tick(DT)
	assert_almost(draw.draw_k(), 1.0, 0.0001, "Çekiş 0,4 sn'de tam")
	assert_almost(draw.spread_deg(), 6.0, 0.2, "Tam gerilince tablodaki yayılma")
	for i in int(1.0 / DT) + 1:
		draw.tick(DT)
	assert_almost(draw.spread_deg(), 3.0, 0.1, "Tutuş süresi isabeti artırır: yarıya iner")
	assert_true(BowDraw.reach_k(1.0) == 1.0 and BowDraw.speed_k(1.0) == 1.0)


func test_arm_tires_and_looses_by_itself() -> void:
	var draw := BowDraw.new(_spec())
	draw.begin()
	var fired := false
	var seconds := 0.0
	while not fired and seconds < 10.0:
		fired = draw.tick(DT)
		seconds += DT
	assert_true(fired, "Kol yorulunca bırakır")
	assert_almost(seconds, 6.0, DT * 2.0, "hold_max")
	assert_almost(draw.loosed_k, 1.0, 0.0001)


func test_cancel_looses_nothing_and_scatter_stays_in_the_cone() -> void:
	var draw := BowDraw.new(_spec())
	draw.begin()
	draw.cancel()
	assert_false(draw.tick(DT), "İptal ok atmaz")
	var from := Vector3(0.0, 1.0, 0.0)
	var to := Vector3(10.0, 1.0, 0.0)
	var limit := 10.0 * tan(deg_to_rad(6.0) * 0.5)
	for k in 8:
		var hit := BowDraw.scatter(from, to, 6.0, float(k) / 7.0, float(k) * 0.13)
		assert_true(hit.distance_to(to) <= limit + 0.001, "Koni içinde")
		assert_almost((hit - to).dot(Vector3.RIGHT), 0.0, 0.0001, "Atışa dik düzlemde")
	assert_vec_almost(BowDraw.scatter(from, to, 6.0, 0.0, 0.3), to, 0.0001, "u = 0: tam hedef")
	assert_vec_almost(BowDraw.scatter(from, from, 6.0, 1.0, 0.3), from, 0.0001, "Uzaklık yoksa kaymaz")
