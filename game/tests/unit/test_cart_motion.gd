extends TestCase
## Arabanın hareketinin saf hesabı (CartMotion; travel.md §3.5): römorkun yönü koşumu izler (düz yolda hizalanır, dönemeçte içe kaçar),
## dingil koşumun L gerisinde, eğim ve yatış, durağa yanaşma (yana kayma), köşe yayı (≥6 m), durma hızı.


func test_trailer_follows_the_hitch() -> void:
	# Düz yolda başlangıçta 60° ayrık araba koşumu izledikçe hizalanır.
	var theta := deg_to_rad(60.0)
	var hitch := Vector2.ZERO
	for i in 200:
		var next := hitch + Vector2(0.0, 0.1)
		theta = CartMotion.step_heading(theta, next - hitch, 2.85)
		hitch = next
	assert_almost(theta, 0.0, 0.01, "Düz yolda araba koşuma hizalanır (%.3f rad)" % theta)
	# Tek büyük adım (karartmada taşıma) da kararlıdır: yön aşmaz.
	var big := CartMotion.step_heading(deg_to_rad(80.0), Vector2(0.0, 100.0), 2.85)
	assert_almost(big, 0.0, 0.001, "Büyük adım")
	# 6 m yarıçaplı dönemeçte dingil koşumun yolunun içinden geçer (travel.md §3.5: 0,61 m içe kaçar).
	var r := 6.0
	var a := 0.0
	theta = PI * 0.5
	hitch = Vector2(0.0, r)
	var inner := 0.0
	for i in 600:
		a += 0.005
		var next := Vector2(sin(a) * r, cos(a) * r)
		theta = CartMotion.step_heading(theta, next - hitch, 2.7)
		hitch = next
		inner = maxf(inner, r - CartMotion.axle_of(hitch, theta, 2.7).length())
	assert_between(inner, 0.4, 0.8, "Dingil içe kaçar (%.2f m)" % inner)
	assert_vec_almost(_v3(CartMotion.axle_of(Vector2(0, 10), 0.0, 2.7)), Vector3(0, 0, 7.3), 0.0001, "Dingil koşumun L gerisinde")


func test_pitch_roll_and_spin() -> void:
	assert_almost(CartMotion.pitch_of(1.0, 0.0, 2.7), atan2(1.0, 2.7), 0.0001)
	assert_almost(CartMotion.roll_of(0.2, 0.0, 0.92), atan2(0.2, 1.84), 0.0001, "Sol teker yüksekse +")
	assert_almost(CartMotion.spin(0.0, 0.72 * PI, 0.72), PI, 0.0001, "Yarım tur")
	assert_vec_almost(_v3(CartMotion.right(0.0)), Vector3(-1, 0, 0), 0.0001, "Güneye bakanın sağı batı")
	assert_vec_almost(_v3(CartMotion.right(PI * 0.5)), Vector3(0, 0, 1), 0.0001, "Doğuya bakanın sağı güney")


func test_pull_over_fillet_and_stop() -> void:
	var line := PackedVector2Array([Vector2(0, 0), Vector2(0, 40)])
	var pulled := CartMotion.pull_over(line, 1.6, 12.0, true)
	assert_vec_almost(_v3(pulled[pulled.size() - 1]), Vector3(-1.6, 0, 40), 0.001, "Sonu 1,6 m sağda (güneye giden yolun sağı batı)")
	assert_vec_almost(_v3(pulled[0]), Vector3.ZERO, 0.001, "Başı yolda")
	var mid := RoadGraph.point_at(pulled, RoadGraph.cumulative(pulled), 20.0)
	assert_almost(mid.x, 0.0, 0.001, "Kayma son 12 m'de")
	var corner := CartMotion.fillet(PackedVector2Array([Vector2(0, 0), Vector2(0, 30), Vector2(30, 30)]), 6.0)
	var worst := INF
	for p in corner:
		worst = minf(worst, p.distance_to(Vector2(0, 30)))
	assert_between(worst, 1.0, 3.0, "Köşe yayla açılır (köşeye %.2f m)" % worst)
	assert_almost(CartMotion.target_speed(0.0, 4.6, 2.4), 0.0, 0.0001)
	assert_almost(CartMotion.target_speed(100.0, 4.6, 2.4), 4.6, 0.0001)
	assert_almost(CartMotion.target_speed(1.0, 4.6, 2.4), sqrt(4.8), 0.0001)
	var ext := CartMotion.extend(line, 2.85)
	assert_vec_almost(_v3(ext[ext.size() - 1]), Vector3(0, 0, 42.85), 0.0001)


func _v3(p: Vector2) -> Vector3:
	return Vector3(p.x, 0.0, p.y)
