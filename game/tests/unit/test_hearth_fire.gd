extends TestCase
## «Ocak»ın ateşi (HearthFire, HearthView; Önsöz, K110, K108): üç taşın üçgeni, odun, ak taşla kara taşın vuruşu ve 3–5 sn'de tutuşma,
## odunla evre evre büyüme, ışığın yarıçapının eğrisi (≈2, 4, 7, 10 m), alevin ve dumanın büyümesi, harlamanın menü ateşine oturuşu.

const DT := 1.0 / 60.0


func _ready_fire(seed_value: int = 1) -> HearthFire:
	var f := HearthFire.new(seed_value)
	for i in 3:
		f.place_stone()
	f.lay_wood()
	return f


## Ateşi tutuşana dek vurur (her 0,6 sn'de bir); tutuşma anını döndürür.
func _kindle(f: HearthFire) -> float:
	var t := 0.0
	var next := 0.0
	while not f.lit and t < 20.0:
		if t >= next:
			f.strike(t)
			next += 0.6
		f.tick(DT)
		t += DT
	return t


func test_three_stones_in_a_triangle() -> void:
	var f := HearthFire.new()
	assert_false(f.stones_done())
	assert_eq(f.place_stone(), 0)
	assert_eq(f.place_stone(), 1)
	assert_eq(f.place_stone(), 2)
	assert_eq(f.place_stone(), -1, "dördüncü taş yok: hep üç")
	assert_true(f.stones_done())
	var a := HearthFire.stone_offset(0)
	var b := HearthFire.stone_offset(1)
	var c := HearthFire.stone_offset(2)
	for p: Vector3 in [a, b, c]:
		assert_almost(Vector2(p.x, p.z).length(), HearthFire.STONE_RADIUS, 0.001, "taş merkezden eşit uzakta")
	assert_almost(a.distance_to(b), b.distance_to(c), 0.001, "eşkenar üçgen")
	assert_almost(b.distance_to(c), c.distance_to(a), 0.001)


func test_wood_only_after_the_stones_and_no_strike_before_the_wood() -> void:
	var f := HearthFire.new()
	assert_eq(f.lay_wood(), 0, "taşsız odun konmaz")
	for i in 3:
		f.place_stone()
	assert_false(f.ready_to_strike(), "odunsuz vurulmaz")
	assert_false(bool(f.strike(0.0)["spark"]))
	f.lay_wood()
	assert_true(f.ready_to_strike())


func test_tinder_catches_within_three_to_five_seconds_of_striking() -> void:
	for s in [1, 2, 3, 4, 5, 9, 17]:
		var f := _ready_fire(s)
		assert_between(f.kindle_s, 3.0, 5.0, "tutuşma süresi (K108)")
		var t := _kindle(f)
		assert_true(f.lit, "vuran tutuşturur (tohum %d)" % s)
		assert_between(t, 3.0, 5.7, "ilk vuruştan tutuşmaya (tohum %d): %.2f sn" % [s, t])
		assert_eq(f.stage, 0, "kav tutuştu: ilk evre")


func test_a_single_strike_does_not_light_and_the_tinder_cools() -> void:
	var f := _ready_fire(3)
	assert_true(bool(f.strike(0.0)["spark"]))
	assert_false(f.lit)
	assert_true(f.smolder > 0.0, "kav tüter")
	# Uzun bekleme: kav söner, tutuşma baştan sayılır (ceza yok).
	for i in int(5.0 / DT):
		f.tick(DT)
	assert_almost(f.smolder, 0.0, 0.0001)
	assert_eq(f.first_strike, -1.0)
	assert_false(bool(f.strike(10.0)["caught"]), "yeniden sayılır")


func test_feeding_grows_the_fire_stage_by_stage() -> void:
	var f := _ready_fire(2)
	_kindle(f)
	assert_false(f.is_full())
	for want in [1, 2, 3]:
		assert_true(f.feed(), "besler")
		assert_eq(f.stage, want)
	assert_true(f.is_full())
	assert_false(f.feed(), "büyükten büyüğü yok")
	assert_true(f.flare > 0.9, "büyük evrede harlar")


func test_light_radius_curve_two_four_seven_ten() -> void:
	assert_almost(HearthFire.light_radius(-1.0), 0.0)
	assert_almost(HearthFire.light_radius(0.0), 2.0)
	assert_almost(HearthFire.light_radius(1.0), 4.0)
	assert_almost(HearthFire.light_radius(2.0), 7.0)
	assert_almost(HearthFire.light_radius(3.0), 10.0)
	assert_almost(HearthFire.light_radius(1.5), 5.5, 0.001, "evreler arası doğrusal")
	var prev := -1.0
	for i in 31:
		var sf := float(i) * 0.1
		var r := HearthFire.light_radius(sf)
		assert_true(r >= prev, "yarıçap küçülmez")
		prev = r
		assert_true(HearthFire.flame_scale(sf) <= 1.0001, "alev menü ateşinden büyük olmaz")
	assert_almost(HearthFire.flame_scale(3.0), 1.0, 0.0001, "büyük evrenin alevi menü ateşinin alevi")
	assert_true(HearthFire.smoke_size(3.0).y > HearthFire.smoke_size(0.0).y, "duman büyür")
	assert_true(HearthFire.spark_count(3.0) > HearthFire.spark_count(0.0), "kıvılcım çoğalır")


func test_view_grows_smoothly_toward_the_stage() -> void:
	var f := _ready_fire(4)
	_kindle(f)
	f.feed()
	var r0 := float(f.light_now()["range"])
	for i in int(0.5 / DT):
		f.tick(DT)
	var r_mid := float(f.light_now()["range"])
	assert_true(r_mid > r0 and r_mid < 4.0, "ışık evreye yumuşakça yetişir: %.2f" % r_mid)
	for i in int(HearthFire.GROW_S / DT) + 5:
		f.tick(DT)
	assert_true(f.grown())
	assert_almost(float(f.light_now()["range"]), 4.0, 0.01)


func test_full_fire_settles_to_the_menu_campfire() -> void:
	var f := _ready_fire(5)
	_kindle(f)
	for i in 3:
		f.feed()
	for i in int(6.0 / DT):
		f.tick(DT)
	assert_almost(float(f.light_now()["range"]), 10.0, 0.01, "harlanan ateş 10 m")
	f.begin_settle()
	for i in int((HearthFire.SETTLE_S + 0.1) / DT):
		f.tick(DT)
	var now := f.light_now()
	assert_almost(float(now["range"]), HearthFire.MENU_RANGE, 0.001, "oturan ateş menünün menzili")
	assert_almost(float(now["energy"]), HearthFire.MENU_ENERGY, 0.001, "oturan ateş menünün enerjisi")
	# Menünün ateşi sahnede bu ölçüdedir (world.tscn Camp/Campfire).
	var world: Node3D = load("res://scenes/world/world.tscn").instantiate(PackedScene.GEN_EDIT_STATE_DISABLED)
	var camp_fire := world.get_node(^"Camp/Campfire")
	assert_almost(float(camp_fire.get(&"light_range")), HearthFire.MENU_RANGE, 0.001)
	assert_almost(float(camp_fire.get(&"light_energy")), HearthFire.MENU_ENERGY, 0.001)
	world.free()


func test_hearth_view_shows_stones_wood_and_a_growing_light() -> void:
	var f := HearthFire.new(6)
	var v := HearthView.new()
	v.bind(f)
	add_child(v)
	await wait_frames(2)
	var look := v.look()
	assert_eq(int(look["stones"]), 0)
	assert_eq(int(look["cracked"]), 6, "üç çatlak taş, ikişer parça")
	assert_false(bool(look["lit"]))
	f.place_stone()
	f.place_stone()
	f.place_stone()
	f.lay_wood()
	await wait_frames(3)
	look = v.look()
	assert_eq(int(look["stones"]), 3)
	assert_eq(int(look["logs"]), 3)
	_kindle(f)
	await wait_frames(3)
	look = v.look()
	assert_true(bool(look["lit"]))
	assert_between(float(look["light_range"]), 1.9, 2.1)
	f.feed()
	for i in int((HearthFire.GROW_S + 0.2) / DT):
		f.tick(DT)
	await wait_frames(3)
	look = v.look()
	assert_between(float(look["light_range"]), 3.9, 4.1, "ışık ikinci evrede 4 m")
	assert_true(bool(look["smoke"]))
	assert_eq(int(look["logs"]), 4, "beslenen odun görünür")
	v.burst()
	v.queue_free()
