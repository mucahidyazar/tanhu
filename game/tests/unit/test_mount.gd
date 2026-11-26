extends TestCase
## Mount (saf; data/fauna/mounts.json): binek satırı, hız, otlama, dürtme, biniş erimi, inilen nokta. Atın satırı I. Perde'de aynı şekille gelecek: burada elle verilen satırla sınanır.

const DT := 1.0 / 60.0
## I. Perde'nin atı (fauna.md §2.1, Adak Aygırı): satırda otlama yok.
const HORSE_ROW := {"tr": "At", "en": "Horse", "base": 12.0, "trot": 6.4, "stamina": 1.0, "load": 50.0, "fall_damage": true, "reach": 2.0}


func before_each() -> void:
	Mount.reset_cache()


func test_sheep_row_carries_the_design_numbers() -> void:
	assert_true(Mount.ids().has("sheep"), "Koyun satırı var")
	var mount := Mount.new("sheep")
	assert_almost(mount.trot_speed(), 2.5, 0.0001, "Tırıs (fauna.md §2.1)")
	assert_almost(mount.gallop_speed(), 3.0, 0.0001, "Koşu tuşu: hızlı tırıs (dörtnal klibi yok)")
	assert_almost(mount.walk_speed(), 1.1, 0.0001, "Adım (modelin yürüme klibi)")
	assert_true(mount.gallop_speed() / mount.trot_speed() <= RideableSheep.CLIP_RATE.y, "Tırıs klibi en çok 1,23 kat hızlanır")
	assert_almost(mount.value("load"), 0.0, 0.0001, "Yük 0")
	assert_false(bool(mount.spec.get("fall_damage", true)), "Düşüş hasarsız")
	assert_almost(mount.value("graze_every"), 10.0, 0.0001, "On saniyede bir otlar")
	assert_almost(mount.stride_at(2.5), 1.19, 0.0001, "Tırıs adımı (bovid_s)")
	assert_almost(mount.stride_at(3.0), 1.19, 0.0001, "Hızlı tırıs aynı klibin adımı")
	assert_almost(mount.stride_at(1.1), 0.86, 0.0001, "Yürüme adımı")
	assert_between(mount.stride_at(1.8), 0.86, 1.19, "Arada geçişli")
	assert_false(mount.seat().is_empty(), "Oturma ölçüleri")


func test_sheep_seat_equals_the_model_measure() -> void:
	# Oturma noktası modelin ölçüsünden okunur; satırdaki yedek ona eşit kalmalı (model yokken aynı yere oturulsun).
	var seat := Mount.new("sheep").seat()
	var meta := RideableSheep.read_meta(RideableSheep.MODEL_PATH)
	if meta.is_empty():
		assert_true(true, "Model ölçüsü yok: satır geçer")
		return
	assert_almost(float(seat["saddle_y"]), float(meta["saddle_y"]), 0.002, "Satırın sırt yüksekliği modelinki")
	assert_almost(float(seat["saddle_z"]), float(meta["saddle_z"]), 0.002, "Satırın sırt noktası modelinki")
	assert_vec_almost(RideableSheep.saddle_point(meta, {}), Vector3(0.0, float(meta["saddle_y"]), float(meta["saddle_z"])), 0.0001)
	assert_vec_almost(RideableSheep.saddle_point({}, {"saddle_y": 0.5, "saddle_z": 0.1}), Vector3(0.0, 0.5, 0.1), 0.0001, "Ölçü yoksa satır")


func test_no_input_stands_input_trots_sprint_gallops() -> void:
	var mount := Mount.new("sheep")
	mount.start_ride()
	assert_almost(mount.step(DT, false, false, false), 0.0, 0.0001, "Girişsiz durur")
	assert_eq(mount.gait, Mount.Gait.STAND)
	assert_almost(mount.step(DT, true, false, false), 2.5, 0.0001, "Giriş tırıs")
	assert_eq(mount.gait, Mount.Gait.TROT)
	assert_almost(mount.step(DT, true, true, true), 3.0, 0.0001, "Koşu tuşu dörtnal (koyunda hızlı tırıs)")
	assert_eq(mount.gait, Mount.Gait.GALLOP)


func test_sheep_stops_to_graze_every_ten_seconds_and_only_a_prod_moves_it() -> void:
	var mount := Mount.new("sheep")
	mount.start_ride()
	var t := 0.0
	while t < 9.9:
		assert_true(mount.step(DT, true, false, false) > 0.0, "On saniye dolmadan yürür (%.2f)" % t)
		t += DT
	for i in 12:
		mount.step(DT, true, false, false)
	assert_true(mount.is_grazing(), "On saniyede durur ve otlar")
	assert_almost(mount.step(DT, true, false, false), 0.0, 0.0001, "Otlarken giriş yürütmez")
	assert_almost(mount.step(DT, true, true, false), 0.0, 0.0001, "Basılı kalan koşu tuşu dürtme sayılmaz")
	assert_almost(mount.step(DT, true, true, true), 3.0, 0.0001, "Yeni basış dürter: yürür (tuş basılıysa hızlı tırıs)")
	assert_false(mount.is_grazing())
	assert_almost(mount.graze_clock, DT, 0.001, "Saat dürtmeyle sıfırlanır")
	t = 0.0
	while t < 9.5:
		mount.step(DT, true, false, false)
		t += DT
	assert_false(mount.is_grazing(), "Yeni on saniye başladı")


func test_grazing_also_comes_while_standing_and_ride_start_resets() -> void:
	var mount := Mount.new("sheep")
	mount.start_ride()
	for i in int(10.1 / DT):
		mount.step(DT, false, false, false)
	assert_true(mount.is_grazing(), "Durana da otlama gelir")
	mount.start_ride()
	assert_false(mount.is_grazing(), "Binilince kalkar")
	assert_almost(mount.graze_clock, 0.0, 0.0001)


func test_a_horse_row_has_the_same_shape_without_grazing() -> void:
	var horse := Mount.new("offering_stallion", HORSE_ROW)
	horse.start_ride()
	assert_almost(horse.trot_speed(), 6.4, 0.0001)
	assert_almost(horse.gallop_speed(), 12.0, 0.0001)
	assert_almost(horse.value("load"), 50.0, 0.0001)
	assert_almost(horse.value("reach"), 2.0, 0.0001, "Satırın değeri")
	assert_almost(horse.value("accel"), float(Mount.DEFAULTS["accel"]), 0.0001, "Yazılmayan ayar varsayılan")
	assert_almost(horse.stride_at(6.4), 1.0, 0.0001, "Adım boyu yazılmamışsa 1 m")
	for i in int(60.0 / DT):
		horse.step(DT, true, true, false)
	assert_false(horse.is_grazing(), "Satırda graze_every yoksa binek otlamaz")
	assert_almost(horse.step(DT, true, false, false), 6.4, 0.0001)


func test_reach_and_nearest() -> void:
	assert_true(Mount.in_reach(Vector2.ZERO, Vector2(1.0, 0.0), 1.35))
	assert_false(Mount.in_reach(Vector2.ZERO, Vector2(2.0, 0.0), 1.35))
	var spots: Array[Vector2] = [Vector2(3.0, 0.0), Vector2(0.9, 0.0), Vector2(0.0, 1.2)]
	assert_eq(Mount.nearest_in_reach(Vector2.ZERO, spots, 1.35), 1, "En yakın")
	assert_eq(Mount.nearest_in_reach(Vector2(10.0, 10.0), spots, 1.35), -1, "Erimde yok")


func test_dismount_spot_prefers_the_left_side_then_right_then_behind() -> void:
	# Ön yüz +Z (yaw 0): sol +X.
	var center := Vector2(5.0, 5.0)
	assert_eq(Mount.dismount_spot(center, 0.0, 1.0), Vector2(6.0, 5.0), "Önce sol")
	var left_closed := func(spot: Vector2) -> bool: return spot.x > 5.5
	assert_eq(Mount.dismount_spot(center, 0.0, 1.0, left_closed), Vector2(4.0, 5.0), "Sol kapalıysa sağ")
	var sides_closed := func(spot: Vector2) -> bool: return absf(spot.x - 5.0) > 0.5
	assert_eq(Mount.dismount_spot(center, 0.0, 1.0, sides_closed), Vector2(5.0, 4.0), "İkisi kapalıysa arkası")
	var all_closed := func(_spot: Vector2) -> bool: return true
	assert_eq(Mount.dismount_spot(center, 0.0, 1.0, all_closed), Vector2(6.0, 5.0), "Hepsi kapalıysa yine sol")
	# Yaw 90°: ön +X, sol -Z.
	var turned := Mount.dismount_spot(Vector2.ZERO, PI * 0.5, 1.0)
	assert_almost(turned.x, 0.0, 0.0001)
	assert_almost(turned.y, -1.0, 0.0001)
