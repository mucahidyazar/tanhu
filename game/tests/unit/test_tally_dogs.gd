extends TestCase
## Ebe Obası'nın köpekleri ve bozkırın görgüsü (saf; TallyDogs; K110, story.md §5 «İki yeni gün», K105):
##   - Oyuncu uzaktayken köpekler yatar; obaya yaklaşınca kalkar, havlar, oyuncunun önüne geçip yolu keser (oyuncu ile oba arasında).
##   - Isırmaz, değmez: oyuncuya hiçbir an MIN_GAP'ten yaklaşmaz; oyuncu üstlerine yürürse geriler ama bekleme çemberinde kalır, oyuncu
##     seslenmeden obaya giremez (fence).
##   - Seslenmek yalnız oyuncu durmuşken ve köpeklere yakınken işler; seslenince köpekler hırlar, ev sahibi gelir; tutunca yanına gider, susar.
##   - Köpeğin koşusu oyuncunun koşusunu aşmaz; oyuncu yanlara koşsa da köpekler önünde kalır.

const CENTER := Vector2(16.0, -324.0)
const CALL := Vector2(22.0, -294.0)
const HOMES := [Vector2(22.0, -307.0), Vector2(20.5, -306.0)]
const STEP := 1.0 / 30.0


func _dogs() -> TallyDogs:
	var d := TallyDogs.new(CENTER, HOMES, PaceLimit.CHILD_RUN)
	d.guard_r = CENTER.distance_to(CALL) - TallyDogs.BLOCK_GAP - 0.6
	d.alert_at = CENTER.distance_to(CALL) + 4.5
	return d


## Oyuncunun obanın engeliyle bir adımı (PlayerController.resolve_circles gibi: gövdenin yarıçapı 0,28).
static func _resolve(p: Vector2, fence: Vector3, body: float = 0.28) -> Vector2:
	if fence == Vector3.ZERO:
		return p
	var c := Vector2(fence.x, fence.y)
	var need := fence.z + body
	var d := p.distance_to(c)
	return c + (p - c) / d * need if d < need and d > 0.001 else p


func test_dogs_rest_until_the_player_comes_near_then_block_the_road() -> void:
	var d := _dogs()
	var player := CENTER + Vector2(6.0, 80.0)
	for i in 60:
		d.step(STEP, player, 1.5)
	assert_eq(d.state, TallyDogs.State.REST, "Uzakta köpekler yatar")
	assert_true(d.take_events().is_empty(), "Havlamaz")
	# Oyuncu yoldan obaya yürür (1,5 m/sn).
	var barks := 0
	var t := 0.0
	while player.distance_to(CENTER) > d.fence_radius() + 0.4 and t < 60.0:
		var to := (CENTER - player).normalized()
		player = _resolve(player + to * 1.5 * STEP, d.fence())
		d.step(STEP, player, 1.5)
		for e: Dictionary in d.take_events():
			if e["type"] == "bark":
				barks += 1
		t += STEP
	assert_true(d.blocks(), "Yolu keser")
	assert_true(barks >= 3, "Havlar (%d)" % barks)
	# Köpekler oyuncu ile obanın arasında, oyuncunun önündedir.
	for i in d.dog_count():
		var to_dog := d.pos[i] - player
		var to_camp := CENTER - player
		assert_true(to_dog.dot(to_camp) > 0.0, "Köpek %d oyuncunun önünde" % i)
		assert_true(d.pos[i].distance_to(CENTER) < player.distance_to(CENTER), "Köpek %d obaya oyuncudan yakın" % i)
	assert_true(d.closest >= TallyDogs.MIN_GAP - 0.01, "Hiç değmez (en yakın %.2f m)" % d.closest)


func test_the_player_cannot_walk_in_without_calling_and_is_never_touched() -> void:
	var d := _dogs()
	var player := CALL + Vector2(0.0, 2.0)
	# Oyuncu durmadan obaya doğru itmeye çalışır, sonra yana koşar, yine iter.
	var t := 0.0
	var closest_to_camp := INF
	while t < 25.0:
		var to := (CENTER - player).normalized()
		if t > 8.0 and t < 14.0:
			to = Vector2(-to.y, to.x)
		var speed := 3.6 if t > 8.0 else 1.5
		player = _resolve(player + to * speed * STEP, d.fence())
		d.step(STEP, player, speed)
		closest_to_camp = minf(closest_to_camp, player.distance_to(CENTER))
		t += STEP
	assert_true(d.blocks(), "Seslenmeden yol açılmaz")
	assert_true(closest_to_camp >= d.fence_radius() - 0.05, "Obaya giremez (%.1f m, çember %.1f m)" % [closest_to_camp, d.fence_radius()])
	assert_true(d.closest >= TallyDogs.MIN_GAP - 0.01, "Isırmaz, değmez (en yakın %.2f m)" % d.closest)
	assert_true(d.peak_speed <= PaceLimit.CHILD_RUN + PaceLimit.TOLERANCE, "Köpek oyuncunun koşusunu aşmaz (%.2f m/sn)" % d.peak_speed)
	# Yana koşan oyuncunun önünde kalır: köpeklerin ortası oyuncu ile oba doğrusunda.
	var mid := (d.pos[0] + d.pos[1]) * 0.5
	var ang := absf(angle_difference((mid - CENTER).angle(), (player - CENTER).angle()))
	assert_true(rad_to_deg(ang) < 12.0, "Köpekler oyuncunun önünde kalır (%.1f°)" % rad_to_deg(ang))


func test_calling_needs_a_stop_then_the_keeper_holds_the_dogs() -> void:
	var d := _dogs()
	var player := CALL
	for i in roundi(4.0 / STEP):
		d.step(STEP, player, 0.0)
	assert_true(d.blocks())
	assert_false(d.can_call(player, 1.5), "Yürürken seslenilmez (görgü: önce durulur)")
	assert_true(d.needs_stop(player, 1.5), "İpucu: dur ve seslen")
	assert_false(d.can_call(CENTER + Vector2(0.0, 80.0), 0.0), "Uzaktan seslenilmez")
	assert_true(d.can_call(player, 0.0), "Durunca seslenilir")
	assert_true(d.call_out(), "«Köpeğinizi tutun!»")
	assert_eq(d.state, TallyDogs.State.CALLED)
	assert_false(d.can_call(player, 0.0), "Bir kez seslenilir")
	assert_true(d.blocks(), "Ev sahibi gelene dek köpekler yerinde")
	d.take_events()
	var growls := 0
	var barks := 0
	for i in roundi(5.0 / STEP):
		d.step(STEP, player, 0.0)
		for e: Dictionary in d.take_events():
			growls += 1 if e["type"] == "growl" else 0
			barks += 1 if e["type"] == "bark" else 0
	assert_true(growls >= 2 and barks == 0, "Seslenince havlama hırlamaya döner (%d hırlama)" % growls)
	# Hereka kapıdan gelir, köpekleri tutar.
	var hereka := CENTER + Vector2(4.0, 20.0)
	d.hold(hereka)
	assert_false(d.blocks(), "Tutulunca yol açılır")
	assert_eq(d.fence(), Vector3.ZERO, "Engel kalkar")
	var settle := d.take_events().filter(func(e: Dictionary) -> bool: return e["type"] == "settle")
	assert_eq(settle.size(), 1, "Bir kez sakinleşir")
	for i in roundi(8.0 / STEP):
		d.step(STEP, player, 0.0)
	for i in d.dog_count():
		assert_true(d.pos[i].distance_to(hereka) < 1.6, "Köpek %d Hereka'nın yanında" % i)
	assert_true(d.take_events().is_empty(), "Tutulan köpek susar")
	d.calm()
	for i in roundi(30.0 / STEP):
		d.step(STEP, CENTER + Vector2(30.0, 0.0), 1.5)
	for i in d.dog_count():
		assert_true(d.pos[i].distance_to(d.homes[i]) < 0.5, "Konuşmadan sonra yatağına döner")


func test_dogs_never_outrun_the_player_on_a_slower_cap() -> void:
	var d := TallyDogs.new(CENTER, HOMES, 2.2)
	d.guard_r = 24.0
	d.alert_at = 35.0
	var player := CENTER + Vector2(0.0, 30.0)
	for i in roundi(10.0 / STEP):
		player = player.rotated(0.0) + Vector2(cos(i * 0.05), 0.0) * 2.2 * STEP
		d.step(STEP, player, 2.2)
	assert_true(d.peak_speed <= 2.2 + PaceLimit.TOLERANCE, "Sınır 2,2: köpek %.2f m/sn" % d.peak_speed)
