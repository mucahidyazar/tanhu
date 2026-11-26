extends TestCase
## Vitals testleri: can ve takat (HUD'un sol üstü), koşunun ve duruşun takate etkisi, durum yuvaları, seviye ve deneyim.

const CHILD_WALK := 1.5
const CHILD_RUN := 3.6


func test_starts_full_at_level_one() -> void:
	var v := Vitals.new()
	assert_eq(v.hp, 100.0, "Can bugün 100/100")
	assert_eq(v.hp_max, 100.0)
	assert_eq(v.stamina, v.stamina_max, "Takat dolu başlar")
	assert_eq(v.level, 1, "Seviye başlangıçta 1")
	assert_eq(v.xp, 0, "Deneyim başlangıçta 0")
	assert_almost(v.xp_ratio(), 0.0)
	assert_eq(HudPortrait.value_text(v.hp, v.hp_max), "100 / 100")
	assert_eq(HudPortrait.value_text(64.4, 80.0), "64 / 80", "Yuvarlanmış sayılar")


func test_classifies_speed_between_walk_and_run() -> void:
	assert_eq(Vitals.classify(CHILD_RUN, false, CHILD_WALK, CHILD_RUN), "run", "Koşu hızı koşudur")
	assert_eq(Vitals.classify(2.6, false, CHILD_WALK, CHILD_RUN), "run", "Yürüyüşle koşunun ortasının üstü koşu")
	assert_eq(Vitals.classify(CHILD_WALK, false, CHILD_WALK, CHILD_RUN), "walk")
	assert_eq(Vitals.classify(0.0, false, CHILD_WALK, CHILD_RUN), "still")
	assert_eq(Vitals.classify(4.0, true, CHILD_WALK, CHILD_RUN), "ride", "Binekte koyun koşar, binici dinlenir")


func test_running_drains_and_resting_refills_after_a_delay() -> void:
	var v := Vitals.new()
	v.tick(1.0, CHILD_RUN, false, CHILD_WALK, CHILD_RUN)
	assert_almost(v.stamina, v.stamina_max - Vitals.DRAIN, 0.001, "Koşarken takat azalır")
	var after_run := v.stamina
	v.tick(Vitals.REGEN_DELAY * 0.5, 0.0, false, CHILD_WALK, CHILD_RUN)
	assert_almost(v.stamina, after_run, 0.001, "Koşudan hemen sonra dolmaz (bekleme)")
	v.tick(Vitals.REGEN_DELAY * 0.5, 0.0, false, CHILD_WALK, CHILD_RUN)
	var rested := v.stamina
	v.tick(1.0, 0.0, false, CHILD_WALK, CHILD_RUN)
	assert_almost(v.stamina, minf(rested + Vitals.REGEN_REST, v.stamina_max), 0.001, "Dururken hızlı dolar")
	for i in 40:
		v.tick(1.0, 0.0, false, CHILD_WALK, CHILD_RUN)
	assert_eq(v.stamina, v.stamina_max, "Dolunca sınırda durur")


func test_walking_refills_slower_than_standing() -> void:
	assert_true(Vitals.regen_rate("walk") < Vitals.regen_rate("still"))
	assert_true(Vitals.regen_rate("ride") > 0.0)
	assert_eq(Vitals.regen_rate("run"), 0.0)


func test_stamina_never_drops_below_zero_and_shows_tired() -> void:
	var v := Vitals.new()
	for i in 30:
		v.tick(1.0, CHILD_RUN, false, CHILD_WALK, CHILD_RUN)
	assert_eq(v.stamina, 0.0, "Takat sıfırın altına inmez")
	assert_eq(v.statuses(), PackedStringArray(["tired"]), "Biten takat: yorgun")


func test_statuses_follow_running_and_resting() -> void:
	var v := Vitals.new()
	assert_eq(v.statuses(), PackedStringArray(), "Dinç ve dururken yuvalar boş")
	v.tick(2.0, CHILD_RUN, false, CHILD_WALK, CHILD_RUN)
	assert_eq(v.statuses(), PackedStringArray(["run"]), "Koşarken çizme")
	v.tick(Vitals.REGEN_DELAY + 0.1, 0.0, false, CHILD_WALK, CHILD_RUN)
	assert_eq(v.statuses(), PackedStringArray(["rest"]), "Soluklanırken ot")


func test_xp_levels_up_with_growing_thresholds() -> void:
	var v := Vitals.new()
	var watcher := watch_signal(v.changed)
	v.add_xp(Vitals.XP_PER_LEVEL - 1)
	assert_eq(v.level, 1)
	v.add_xp(1)
	assert_eq(v.level, 2, "Eşikte seviye atlar")
	assert_eq(v.xp, 0)
	assert_eq(v.xp_next(), 2 * Vitals.XP_PER_LEVEL, "Eşik seviyeyle büyür")
	assert_true(watcher.count > 0, "Değişince haber verir")
	v.reset()
	assert_eq(v.level, 1)
	assert_eq(v.stamina, v.stamina_max)
