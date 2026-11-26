extends TestCase
## Otağa girilebilmesinin çarpışma kuralları: kapılı dairesel duvar (RingWall) ve döndürülmüş kutu (ObstacleBox).
## Duvardan geçilmez, kapıdan geçilir; duvara yaslanınca kayılır; eşikte yana kayan pervaza dayanır; tek adımda
## duvarın öbür yanına atlanmaz. Kutunun kenarlarından ve köşelerinden itilir. Oyuncu denetleyicisiyle birlikte de
## sınanır (dışarıdan kapıya yürüyüp içeri girmek, duvara yürüyüp durmak).

const BODY := 0.35


func _wall() -> RingWall:
	return RingWall.new(Vector2(10.0, -4.0), 3.0, Vector2(0.0, 1.0), 0.42, 0.16)


func _outer(w: RingWall) -> float:
	return w.radius + w.thickness * 0.5 + BODY


func _inner(w: RingWall) -> float:
	return w.radius - w.thickness * 0.5 - BODY


func test_contains_and_passage_width() -> void:
	var w := _wall()
	assert_true(w.contains(w.center), "Merkez duvarın içinde")
	assert_false(w.contains(w.center + Vector2(3.5, 0.0)))
	assert_almost(w.passage_half_width(BODY), 0.07, 0.0001, "Koridor: kapının yarısı - beden yarıçapı")
	assert_almost(w.passage_half_width(1.0), 0.0, 0.0001, "Kapıdan geniş beden için koridor sıfıra iner")
	var odd := RingWall.new(Vector2.ZERO, 2.0, Vector2.ZERO)
	assert_eq(odd.door_dir, Vector2(0.0, 1.0), "Yönsüz kapı +Z'ye bakar")


func test_walking_into_the_wall_from_outside_slides_along_it() -> void:
	var w := _wall()
	var from := w.center + Vector2(-4.0, 0.0)
	var to := w.center + Vector2(-3.2, 0.1)
	var p := w.resolve(from, to, BODY)
	assert_almost(p.distance_to(w.center), _outer(w), 0.0001, "Dışarıdaki karakter duvarın dış yüzünde durur")
	assert_true(p.x < w.center.x, "Geldiği tarafta kalır")


func test_walking_into_the_wall_from_inside_stays_inside() -> void:
	var w := _wall()
	var from := w.center + Vector2(2.0, -1.0)
	var to := w.center + Vector2(2.6, -1.3)
	var p := w.resolve(from, to, BODY)
	assert_almost(p.distance_to(w.center), _inner(w), 0.0001, "İçerideki karakter duvarın iç yüzünde durur")


func test_door_passage_is_free_both_ways() -> void:
	var w := _wall()
	var outside := w.center + Vector2(0.03, 3.6)
	var threshold := w.center + Vector2(0.03, 3.0)
	var inside := w.center + Vector2(0.0, 2.4)
	assert_eq(w.resolve(outside, threshold, BODY), threshold, "Kapı aralığına girilir")
	assert_eq(w.resolve(threshold, inside, BODY), inside, "Eşikten içeri geçilir")
	assert_eq(w.resolve(inside, threshold, BODY), threshold, "İçeriden eşiğe gelinir")
	assert_eq(w.resolve(threshold, outside, BODY), outside, "Eşikten dışarı çıkılır")


func test_side_step_on_the_threshold_meets_the_door_post() -> void:
	var w := _wall()
	var threshold := w.center + Vector2(0.0, 3.0)
	var p := w.resolve(threshold, w.center + Vector2(0.4, 3.02), BODY)
	assert_almost(p.x - w.center.x, w.passage_half_width(BODY), 0.0001, "Yana kayan karakter pervaza dayanır")
	assert_almost(p.y - w.center.y, 3.02, 0.0001, "Kapı boyunca ilerlemesi korunur")


func test_a_long_step_cannot_jump_through_the_wall() -> void:
	var w := _wall()
	var from := w.center + Vector2(2.4, 0.0)
	var p := w.resolve(from, w.center + Vector2(3.8, 0.0), BODY)
	assert_almost(p.distance_to(w.center), _inner(w), 0.0001, "Tek adımda duvarın öbür yanına geçilmez")
	var back := w.resolve(w.center + Vector2(-3.8, 0.0), w.center + Vector2(-2.3, 0.0), BODY)
	assert_almost(back.distance_to(w.center), _outer(w), 0.0001, "Dışarıdan da")


func test_rotated_door_and_spawn_inside_the_wall_band() -> void:
	var dir := Vector2(1.0, 1.0).normalized()
	var w := RingWall.new(Vector2.ZERO, 3.0, dir, 0.42, 0.16)
	var threshold := dir * 3.0
	assert_eq(w.resolve(threshold, dir * 2.0, BODY), dir * 2.0, "Döndürülmüş kapıdan da girilir")
	# Duvarın içine konmuş karakter (eski kayıt) bulunduğu tarafa itilir.
	var side := Vector2(-1.0, 1.0).normalized()
	var p := w.resolve(side * 2.95, side * 2.95, BODY)
	assert_almost(p.length(), _inner(w), 0.0001, "Duvarın içindeki nokta iç yüze itilir")


func test_box_pushes_out_from_sides_and_corners() -> void:
	var box := ObstacleBox.new(Vector2(2.0, 1.0), Vector2(1.0, 0.4), Vector2(1.0, 0.0))
	assert_eq(box.push_out(Vector2(2.0, 3.0), BODY), Vector2(2.0, 3.0), "Uzaktaki noktaya dokunulmaz")
	var side := box.push_out(Vector2(2.2, 1.5), BODY)
	assert_almost(side.y, 1.0 + 0.4 + BODY, 0.0001, "Uzun kenardan dışarı itilir")
	assert_almost(side.x, 2.2, 0.0001)
	var corner := box.push_out(Vector2(3.1, 1.5), BODY)
	assert_almost(corner.distance_to(Vector2(3.0, 1.4)), BODY, 0.0001, "Köşenin çevresinden yuvarlak itilir")
	var inner := box.push_out(Vector2(2.9, 1.1), BODY)
	assert_almost(inner.x, 2.0 + 1.0 + BODY, 0.0001, "İçerideki nokta en yakın kenardan çıkar")
	assert_true(box.contains(Vector2(2.5, 1.2)))
	assert_false(box.contains(Vector2(3.2, 1.0)))


func test_box_from_a_rotated_transform() -> void:
	var xform := Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(1.0, 0.0, 2.0))
	var box := ObstacleBox.from_transform(xform, Vector2(1.0, 0.25))
	# 90° dönen kutunun uzun kenarı dünya Z ekseni boyuncadır.
	assert_true(box.contains(Vector2(1.0, 2.9)), "Uzun eksen dünya Z boyunca")
	assert_false(box.contains(Vector2(1.9, 2.0)), "Kısa eksen dünya X boyunca")


func test_player_walks_in_through_the_door_but_not_through_the_wall() -> void:
	var w := RingWall.new(Vector2.ZERO, 3.0, Vector2(0.0, 1.0), 0.42, 0.16)
	var player := PlayerController.new()
	player.start_active = false
	player.walls = [w] as Array[RingWall]
	add_child(player)
	player.refresh_obstacles()
	# Kapının önünden (+Z) merkeze doğru yürü: kamera yaw = 0 iken ileri = -Z.
	player.spawn_at(Vector3(0.0, 0.0, 4.2), PI)
	for i in 120:
		player.step(1.0 / 30.0, Vector2(0.0, 1.0), false, 0.0)
	var p := Vector2(player.position.x, player.position.z)
	assert_true(w.contains(p), "Kapıdan içeri girilmeli (şu an %s)" % p)
	# Duvara (sağa, +X) yürü: içeride kalır.
	for i in 120:
		player.step(1.0 / 30.0, Vector2(1.0, 0.0), false, 0.0)
	p = Vector2(player.position.x, player.position.z)
	assert_true(p.length() <= w.radius - w.thickness * 0.5 - player.body_radius + 0.001, "Duvardan çıkılmamalı (%.3f)" % p.length())
	# Dışarıdan duvara yürüyen karakter içeri giremez.
	player.spawn_at(Vector3(-4.5, 0.0, 0.0), 0.0)
	for i in 120:
		player.step(1.0 / 30.0, Vector2(1.0, 0.0), false, 0.0)
	p = Vector2(player.position.x, player.position.z)
	assert_false(w.contains(p), "Duvardan içeri girilmemeli (%s)" % p)
	player.queue_free()
