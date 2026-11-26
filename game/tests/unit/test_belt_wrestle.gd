extends TestCase
## Kuşak güreşi (BeltWrestle, BeltWrestleHud; Önsöz «Güreş», K110): eğilişin yüklenişten ≈0,4 sn önce görünmesi, karşı yöne basan oyuncunun
## dengede kalması, fazla yüklenmenin ≈0,5 sn'lik penceresi ve E'nin atışı, uca varan dengenin düşüşü ve «Bir daha!», kuşağı bırakmak,
## belirlenimcilik ve HUD'un çubuğu.

const DT := 1.0 / 60.0


## Benzetimi bot ya da verilen elle saniyelerce sürer; olayları toplar.
func _run(w: BeltWrestle, seconds: float, hand: Callable) -> PackedStringArray:
	var all := PackedStringArray()
	var frames := int(seconds / DT)
	for i in frames:
		var input: Dictionary = hand.call(w)
		all.append_array(w.step(DT, float(input.get("lean", 0.0)), bool(input.get("throw", false))))
		if w.is_over():
			break
	return all


func test_envelope_rises_holds_and_falls() -> void:
	assert_almost(BeltWrestle.envelope(0.0), 0.0)
	assert_almost(BeltWrestle.envelope(1.0), 0.0)
	assert_almost(BeltWrestle.envelope(0.5), 1.0)
	assert_true(BeltWrestle.envelope(0.1) < BeltWrestle.envelope(0.2), "yükseliş")
	assert_true(BeltWrestle.envelope(0.95) < BeltWrestle.envelope(0.8), "sönüş")


func test_grip_comes_first_then_a_telegraphed_bout() -> void:
	var w := BeltWrestle.new(7)
	w.start()
	assert_eq(w.phase, BeltWrestle.GRIP)
	var events := _run(w, 1.0, func(_w: BeltWrestle) -> Dictionary: return {})
	assert_false(events.has("bout"), "tutunurken yükleniş yok")
	events = _run(w, 3.0, func(_w: BeltWrestle) -> Dictionary: return {})
	assert_true(events.has("grip") and events.has("telegraph") and events.has("bout"), "tutunma → eğiliş → yükleniş: %s" % [events])
	assert_true(events.find("telegraph") < events.find("bout"))


func test_lean_shows_the_direction_about_0_4_s_before_the_force() -> void:
	var w := BeltWrestle.new(11)
	w.start()
	var lean_since := -1.0
	var checked := 0
	for i in int(30.0 / DT):
		var ev := w.step(DT, 0.0)
		if ev.has("telegraph"):
			lean_since = w.clock
		if ev.has("bout"):
			var lead := w.clock - lean_since
			assert_between(lead, 0.38, 0.42, "eğiliş yüklenişten ≈0,4 sn önce: %.3f" % lead)
			checked += 1
		# Eğilişin işareti gelecek kuvvetin işaretidir.
		if w.phase == BeltWrestle.TELEGRAPH and w.phase_t > 0.1:
			assert_eq(signf(w.lean()), float(w.next_dir), "eğiliş yüklenişin yönünde")
		if w.phase == BeltWrestle.BOUT and absf(w.force) > 0.1:
			assert_eq(signf(w.force), float(w.next_dir), "kuvvet eğilişin yönünde")
		if w.phase == BeltWrestle.FALLEN or checked >= 3:
			break
	assert_true(checked >= 1, "en az bir yükleniş görüldü")


func test_without_input_the_child_falls_and_boru_calls_again() -> void:
	var w := BeltWrestle.new(3)
	w.start()
	var events := _run(w, 40.0, func(_w: BeltWrestle) -> Dictionary: return {"lean": 0.0})
	assert_true(events.has("fall"), "karşılanmayan yükleniş düşürür")
	assert_true(events.has("again"), "Börü «Bir daha!» der")
	assert_true(events.has("regrip") and events.has("restart"), "yeniden tutunup başlarlar")
	assert_true(w.tries >= 2, "deneme sayısı artar: %d" % w.tries)
	assert_false(w.is_over(), "düşüş maçı bitirmez")


func test_the_fall_keeps_the_child_down_then_resets_the_balance() -> void:
	var w := BeltWrestle.new(5)
	w.start()
	var guard := 0
	while w.phase != BeltWrestle.FALLEN and guard < 6000:
		w.step(DT, 0.0)
		guard += 1
	assert_eq(w.phase, BeltWrestle.FALLEN)
	assert_between(absf(w.balance), 0.99, 1.0, "uca varmıştır")
	var down := 0.0
	while w.phase == BeltWrestle.FALLEN:
		w.step(DT, 0.0, true)
		down += DT
	assert_between(down, float(w.cfg["fall_s"]) - 0.05, float(w.cfg["fall_s"]) + 0.05, "yerde kalış")
	while w.phase == BeltWrestle.REGRIP:
		w.step(DT, 0.0)
	assert_eq(w.phase, BeltWrestle.GRIP)
	assert_almost(w.balance, 0.0, 0.0001, "yeni maç ortadan başlar")


func test_countering_keeps_the_balance_and_the_window_throws_boru() -> void:
	for seed_value in [1, 2, 3, 4, 5, 6]:
		var w := BeltWrestle.new(seed_value)
		w.start()
		var worst := 0.0
		var won := false
		for i in int(90.0 / DT):
			var input := BeltWrestle.bot_input(w)
			var ev := w.step(DT, float(input["lean"]), bool(input["throw"]))
			worst = maxf(worst, absf(w.balance))
			if ev.has("won"):
				won = true
				break
		assert_true(won, "karşı yöne basan oyuncu atar (tohum %d)" % seed_value)
		assert_true(worst < 1.0, "denge uca varmaz (tohum %d, en kötü %.2f)" % [seed_value, worst])
		assert_eq(w.falls, 0)
		assert_true(w.result()["won"])
		assert_true(w.windows >= 1)


func test_window_lasts_about_half_a_second_and_late_e_whiffs() -> void:
	var w := BeltWrestle.new(9)
	w.start()
	# Pencereye dek botla oyna, pencerede basma.
	var guard := 0
	while w.phase != BeltWrestle.WINDOW and guard < int(120.0 / DT):
		var input := BeltWrestle.bot_input(w)
		w.step(DT, float(input["lean"]), false)
		guard += 1
	assert_eq(w.phase, BeltWrestle.WINDOW, "pencere açıldı")
	var open := 0.0
	while w.phase == BeltWrestle.WINDOW:
		w.step(DT, 0.0, false)
		open += DT
	assert_between(open, 0.48, 0.52, "pencere ≈0,5 sn")
	# Pencere kapandıktan sonra E boşa gider, kazandırmaz.
	var before := w.whiffs
	var ev := w.step(DT, 0.0, true)
	assert_false(ev.has("won"))
	assert_true(w.whiffs == before + 1 or w.phase == BeltWrestle.FALLEN, "geç E boşa gider")
	assert_false(w.is_over())


func test_letting_go_of_the_belt_ends_the_match_without_a_win() -> void:
	var w := BeltWrestle.new(4)
	w.start()
	_run(w, 2.0, func(_w: BeltWrestle) -> Dictionary: return {})
	var ev := w.give_up()
	assert_true(ev.has("gave_up"))
	assert_true(w.is_over())
	var r := w.result()
	assert_false(r["won"])
	assert_true(r["gave_up"])
	assert_eq(w.step(DT, 1.0, true).size(), 0, "biten maç adım atmaz")


func test_same_seed_same_bouts() -> void:
	var a := BeltWrestle.new(42)
	var b := BeltWrestle.new(42)
	a.start()
	b.start()
	for i in int(20.0 / DT):
		a.step(DT, 0.2)
		b.step(DT, 0.2)
	assert_eq(a.phase, b.phase)
	assert_almost(a.balance, b.balance, 1e-9)
	assert_eq(a.tries, b.tries)


func test_tired_boru_after_two_falls() -> void:
	# Ceza yok (K110): iki düşüşten sonra Börü'nün itişi assist_k ile azalır.
	var w := BeltWrestle.new(8)
	w.start()
	w.tries = 3
	w.force = 1.0
	w.phase = BeltWrestle.BOUT
	var before := w.balance
	w._integrate(0.1, 0.0)
	var tired := w.balance - before
	var fresh := BeltWrestle.new(8)
	fresh.start()
	fresh.force = 1.0
	fresh._integrate(0.1, 0.0)
	assert_true(tired < fresh.balance, "yorgun Börü daha az iter")


func test_hud_marker_and_prompt() -> void:
	assert_almost(BeltWrestleHud.marker_x(0.0), 0.5)
	assert_almost(BeltWrestleHud.marker_x(1.0), 0.0, 0.001, "itilen Çocuk sola kayar")
	assert_almost(BeltWrestleHud.marker_x(-1.0), 1.0)
	var w := BeltWrestle.new(1)
	w.start()
	var hud := BeltWrestleHud.new()
	add_child(hud)
	hud.bind(w)
	await wait_frames(1)
	assert_true(hud.prompt_text().contains("Dengede kal"), hud.prompt_text())
	assert_true(hud.prompt_text().contains("Kuşağı bırak"))
	w.give_up()
	hud.refresh()
	assert_eq(hud.prompt_text(), "", "biten maçta ipucu yok")
	hud.queue_free()


func test_camera_shows_the_child_left_and_boru_right() -> void:
	for axis: Vector3 in [Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-0.6, 0, 0.8), Vector3(0.3, 0, -0.95)]:
		var yaw := BeltWrestle.camera_yaw_for_axis(axis)
		var xf := FollowCamera.compute_transform(Vector3.ZERO, yaw, 38.0, 22.0)
		var right := xf.basis.x
		assert_almost(Vector2(right.x, right.z).normalized().dot(Vector2(axis.x, axis.z).normalized()), 1.0, 0.001,
			"kameranın sağı eksen (%s)" % axis)


func test_pressing_toward_boru_on_screen_leans_forward() -> void:
	var axis := Vector3(-0.6, 0.0, 0.8)
	var yaw := BeltWrestle.camera_yaw_for_axis(axis)
	# Kamera yandan bakarken D (sağ) Börü'ye doğrudur, A ondan geri.
	assert_almost(BeltWrestle.lean_from_input(Vector2(1.0, 0.0), yaw, axis), 1.0, 0.001)
	assert_almost(BeltWrestle.lean_from_input(Vector2(-1.0, 0.0), yaw, axis), -1.0, 0.001)
	assert_almost(BeltWrestle.lean_from_input(Vector2(0.0, 1.0), yaw, axis), 0.0, 0.001, "W eksene dik: eğiliş yok")
	assert_almost(BeltWrestle.lean_from_input(Vector2.ZERO, yaw, axis), 0.0)
