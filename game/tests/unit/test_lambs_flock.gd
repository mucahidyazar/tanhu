extends TestCase
## «Kuzular»ın kuzuları (LambFlock; Önsöz, K110): konumlu meleme ≈30 m'den duyulur, kardaki iz anaya gider, kuzu kucağa alınır (yalnız
## yürüme), anası ardından gelir, yurtta sayılır; donmuş kuzu ocağın yanına konur ve üç damla sütle ısınır.

const LAYOUT := {
	"seed": 7,
	"home": [0.0, 0.0],
	"hearth": [-1.5, 0.5],
	"lambs": [
		{"at": [12.0, 8.0], "ewe": [12.8, 8.4]},
		{"at": [-18.0, 14.0], "ewe": [-18.6, 13.2]},
		{"at": [22.0, -10.0], "ewe": [22.9, -10.4]},
		{"at": [-30.0, -26.0], "ewe": [-30.8, -26.5], "frozen": true},
	],
}


func test_bleat_is_heard_within_thirty_meters() -> void:
	assert_almost(LambFlock.bleat_db(0.0), LambFlock.NEAR_DB)
	assert_true(LambFlock.bleat_db(15.0) < LambFlock.bleat_db(5.0), "uzakta kısık")
	assert_true(LambFlock.bleat_db(29.9) > -INF)
	assert_eq(LambFlock.bleat_db(30.5), -INF, "30 m'nin ötesinde duyulmaz")
	assert_true(LambFlock.audible(Vector3.ZERO, Vector3(20.0, 0.0, 20.0)))
	assert_false(LambFlock.audible(Vector3.ZERO, Vector3(25.0, 0.0, 25.0)))


func test_bleats_come_only_from_lambs_in_earshot() -> void:
	var f := LambFlock.new(LAYOUT)
	var heard := {}
	for i in int(30.0 / 0.1):
		for e: Dictionary in f.tick(0.1, Vector3(12.0, 0.0, 0.0)):
			if e["kind"] == "bleat":
				heard[int(e["lamb"])] = true
				assert_true(float(e["db"]) > -INF)
	assert_true(heard.has(0), "yakındaki kuzu duyulur")
	assert_true(heard.has(2), "22 m'deki kuzu duyulur")
	assert_false(heard.has(3), "50 m'deki donmuş kuzu buradan duyulmaz")


func test_frozen_lamb_bleats_weaker_and_rarer() -> void:
	var f := LambFlock.new(LAYOUT)
	var frozen_n := 0
	var other_n := 0
	var frozen_db := 0.0
	for i in int(120.0 / 0.1):
		for e: Dictionary in f.tick(0.1, Vector3(-24.0, 0.0, -6.0)):
			if e["kind"] != "bleat":
				continue
			if int(e["lamb"]) == 3:
				frozen_n += 1
				frozen_db = float(e["db"])
			elif int(e["lamb"]) == 1:
				other_n += 1
	assert_true(frozen_n > 0, "donmuş kuzu da meler (Biri daha meliyor)")
	assert_true(frozen_n < other_n, "seyrek: %d < %d" % [frozen_n, other_n])
	assert_true(frozen_db < LambFlock.NEAR_DB, "kısık")


func test_track_leads_from_the_fold_to_the_ewe() -> void:
	var from := Vector3(0.0, 0.0, 0.0)
	var to := Vector3(12.8, 0.0, 8.4)
	var t := LambFlock.track(from, to, 3)
	assert_true(t.size() >= 10, "iz adım adım: %d" % t.size())
	var first: Vector3 = t[0]["at"]
	var last: Vector3 = t[t.size() - 1]["at"]
	assert_true(first.distance_to(from) < 2.0, "iz obadan çıkar")
	assert_true(last.distance_to(to) < 2.0, "iz anada biter")
	for k in range(1, t.size()):
		assert_true((t[k]["at"] as Vector3).distance_to(t[k - 1]["at"]) < 2.5, "iz kopmaz")
	var again := LambFlock.track(from, to, 3)
	assert_eq((again[4]["at"] as Vector3), (t[4]["at"] as Vector3), "belirlenimci")


func test_carry_walk_only_and_the_ewe_follows() -> void:
	assert_false(bool(LambFlock.CARRY_MODS["can_run"]), "kuzuyla koşulmaz")
	assert_false(bool(LambFlock.CARRY_MODS["can_jump"]))
	var f := LambFlock.new(LAYOUT)
	assert_eq(f.lamb_in_reach(Vector3(20.0, 0.0, 20.0)), -1)
	var i := f.lamb_in_reach(Vector3(11.4, 0.0, 7.6))
	assert_eq(i, 0)
	assert_true(f.pick_up(i))
	assert_false(f.pick_up(1), "iki kuzu birden taşınmaz")
	assert_eq(f.lamb_in_reach(Vector3(-18.0, 0.0, 14.0)), -1, "kucak doluyken başka kuzu alınmaz")
	# Oyuncu yurda yürür: ana ardından gelir, hızı oyuncunun yürüyüşünü aşmaz (K105).
	var p := Vector3(11.4, 0.0, 7.6)
	var fwd := (Vector3.ZERO - p).normalized()
	var prev: Vector3 = f.lambs[0]["ewe_at"]
	for k in 200:
		p = p.move_toward(Vector3.ZERO, 1.2 * 0.05)
		f.tick(0.05, p, fwd)
		var now: Vector3 = f.lambs[0]["ewe_at"]
		assert_true(now.distance_to(prev) <= LambFlock.EWE_SPEED * 0.05 + 0.0001, "ana yavaş yürür")
		prev = now
	assert_true(prev.distance_to(p) < LambFlock.FOLLOW_GAP + 1.2, "ana kuzunun ardında: %.2f m" % prev.distance_to(p))


func test_count_one_two_three_then_the_frozen_lamb_by_the_hearth() -> void:
	var f := LambFlock.new(LAYOUT)
	for i in 3:
		f.pick_up(i)
		assert_true(f.near_home(Vector3(1.0, 0.0, 1.0)))
		var r := f.deliver()
		assert_true(r["ok"])
		assert_false(r["frozen"])
		assert_eq(int(r["count"]), i + 1, "Ana sayar")
	assert_eq(f.remaining_lost(), 1, "biri daha meliyor")
	assert_false(f.all_home())
	f.pick_up(3)
	assert_true(f.carried_is_frozen())
	var r4 := f.deliver()
	assert_true(r4["frozen"], "donmuş kuzu sayılmaz, ocağa gider")
	assert_eq(int(r4["count"]), 3)
	assert_eq(f.target(Vector3.ZERO, true), f.hearth, "hedef ocak")
	assert_true(f.lay_by_hearth())
	for k in LambFlock.DRIPS - 1:
		var d := f.drip()
		assert_true(d["ok"])
		assert_false(d["warmed"])
	var last := f.drip()
	assert_true(last["warmed"], "üç damlada ısınır")
	assert_eq(f.counted, 4, "Dört. Hepsi sağ.")
	assert_true(f.all_home())
	assert_false(f.drip()["ok"], "ısınan kuzuya damla gerekmez")
