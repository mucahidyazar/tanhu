extends TestCase
## Renk derecelendirmesi (ColorGrade): film aşaması ve gündüzden geceye (gece) aşaması.


func test_world_night_keeps_fire_colors() -> void:
	var grade := ColorGrade.world_night()
	for hex in ["f79f2d", "e67410", "c01818"]:
		var c := Color(hex)
		var out := grade.apply(c)
		assert_true(_distance(out, c) < 0.01, "Ateş/sıcak renk korunmalı: #%s -> #%s" % [hex, out.to_html(false)])


func test_world_night_keeps_bright_whites() -> void:
	var grade := ColorGrade.world_night()
	for hex in ["ffffff", "f3efe7", "f0e4d0"]:
		var c := Color(hex)
		assert_true(_distance(grade.apply(c), c) < 0.02, "Ay/yıldız/krem gibi parlak renkler korunmalı: #%s" % hex)


func test_world_night_turns_bright_grass_into_dark_olive() -> void:
	# Ölçülen çift (renk ayarı kapalı ham görüntü → 4. referans): #556a17 → #41492a.
	var grade := ColorGrade.world_night()
	var grass := Color("556a17")
	var out := grade.apply(grass)
	assert_true(out.s < grass.s * 0.75, "Gece çimeni daha az doygun olmalı")
	assert_true(out.v < grass.v, "Gece çimeni daha koyu olmalı")
	assert_true(_distance(out, Color("41492a")) < 0.04, "Gece çimeni referans rengine yakın olmalı: #%s" % out.to_html(false))


func test_world_night_keeps_blues_and_reds_rich() -> void:
	var grade := ColorGrade.world_night()
	var lake := grade.apply(Color("335383"))
	assert_true(lake.b > lake.r + 0.1, "Göl mavisi mavi kalmalı")
	var cape := grade.apply(Color("a8302a"))
	assert_true(cape.r > cape.g + 0.25, "Kırmızı pelerin kırmızı kalmalı")


func test_world_night_never_turns_creams_purple() -> void:
	var grade := ColorGrade.world_night()
	# Kremden griye hiçbir ara renk mora (kırmızı + mavi > yeşil) kaymamalı.
	for i in 11:
		var c := Color("a89a80").lerp(Color("6a6a6a"), float(i) / 10.0)
		var out := grade.apply(c)
		assert_false(out.r > out.g + 0.02 and out.b > out.g + 0.02, "Mor kayma: #%s -> #%s" % [c.to_html(false), out.to_html(false)])


func test_night_stage_is_off_by_default() -> void:
	var grade := ColorGrade.creator()
	assert_false(grade.night, "Karakter oluşturucu görünümünde gece aşaması kapalı olmalı")
	var c := Color(0.3, 0.6, 0.1)
	assert_true(_distance(grade.apply(c), grade._apply_film(c)) < 0.0001)


func test_lut_has_expected_size() -> void:
	var grade := ColorGrade.world_night()
	grade.size = 8
	var lut := grade.build_lut()
	assert_eq(lut.get_width(), 8)
	assert_eq(lut.get_depth(), 8)


static func _distance(a: Color, b: Color) -> float:
	return Vector3(a.r - b.r, a.g - b.g, a.b - b.b).length()
