extends TestCase
## Kalabalık kademeleri (CrowdField, CrowdPuppet, CrowdCards'ın paletli kartı, CrowdPlan.tier_px ve select_tiers; Yol Haritası crowd-tiers;
## army.md §7.1–§7.4, godot.md §4.5):
##   - ekran pikseli army.md §7.1'in formülüdür, Godot'nun görüş açısıyla: 1920×1080, 36°'de 4.570 / d (57,1 m'de 80 px, 163 m'de 28 px);
##   - kademe seçimi: T0 ≥80 px ve adlı önce (yuva sayısı kadar), T1 en yakın 96 (kadrajdakiler önce), T1 dolunca T2, altı T3; ±%15
##     gecikme payı; kare başına ≤8 takas (önce boşaltan inişler), görünmeyen takas sayılmaz;
##   - kukla: T1 ≤1.200 üçgen, T2 ≤360; üçgenler Godot'nun ön yüz sırasında; parça kimliği ve paletin yuvası köşede; örneğin CUSTOM'u
##     evre, yürüyüş, palet sırası, başlık ve varlıktır;
##   - kart atlası: 8 yön × 8 kare × üç başlık, hücre 32×64 px; açılışta pişer (başsızda pişmez, kademe seçimi sürer);
##   - alan: kişi plana yürüyerek yetişir (en çok yürüyüşün 1,5 katı, ≤ oyuncunun koşusu; K105); 60 m ötesinde ve kadraj dışında sıçrar;
##     yürüyüş evresi yürünen yoldan; tamponlar yalnız dolu yuvaları çizer, T1'in gölgesi en yakın 24'ündür.
##   - Dailin'in kart kademesi (CrowdCards, CrowdPlan.build) değişmez: sınamaları test_childhood_scene ve test_pace_limit'tedir.

var _trash: Array[Node] = []


func after_each() -> void:
	for node in _trash:
		if is_instance_valid(node):
			node.queue_free()
	_trash.clear()


func test_tier_px_formula() -> void:
	assert_almost(CrowdPlan.tier_px(28.0, 36.0, 1080.0), 163.2, 0.2, "28 m: 163 px")
	assert_almost(CrowdPlan.tier_px(57.12, 36.0, 1080.0), 80.0, 0.1, "57,1 m: 80 px (T0 eşiği)")
	assert_almost(CrowdPlan.tier_px(163.2, 36.0, 1080.0), 28.0, 0.1, "163 m: 28 px (T1 ve T2 eşiği)")
	# Prototipin satırı (H 1209, 38°): 4828 / d.
	assert_almost(CrowdPlan.tier_px(33.0, 38.0, 1209.0), 146.3, 0.3, "Prototip: 33 m 146 px")


func test_select_tiers_thresholds_caps_and_priority() -> void:
	var n := 140
	var px := PackedFloat32Array()
	var visible := PackedByteArray()
	var prio := PackedInt32Array()
	var full := PackedByteArray()
	var cur := PackedByteArray()
	var present := PackedByteArray()
	for i in n:
		# 0–9: yakın (≥80 px), 10–129: kukla bandı, 130–139: uzak.
		px.append(150.0 - i * 0.5 if i < 10 else (60.0 - (i - 10) * 0.2 if i < 130 else 12.0))
		visible.append(1)
		prio.append(2 if i == 9 else 0)
		full.append(1)
		cur.append(CrowdPlan.NONE)
		present.append(1)
	var tiers := CrowdPlan.select_tiers(px, visible, prio, full, cur, present, [3, 96, 300, 12000], 8, true)
	var count := [0, 0, 0, 0]
	for i in n:
		count[tiers[i]] += 1
	assert_eq(count[CrowdPlan.T0], 3, "T0 yuva sayısı kadar")
	assert_eq(tiers[9], CrowdPlan.T0, "Adlı önce: en uzak yakın olsa da")
	assert_eq(tiers[0], CrowdPlan.T0)
	assert_eq(tiers[1], CrowdPlan.T0)
	assert_eq(count[CrowdPlan.T1], 96, "T1 en yakın 96")
	assert_eq(count[CrowdPlan.T2], 127 - 96, "T1 dolunca T2")
	assert_eq(count[CrowdPlan.T3], 10, "Uzak kart")
	assert_eq(tiers[129], CrowdPlan.T2, "Bandın en uzağı T2'de")
	# Gecikme payı: kademedeki kişi eşiğin altına %15'e dek kalır, yeni giren %15 üstünü ister.
	var one := func(p: float, c: int) -> int:
		return CrowdPlan.select_tiers(PackedFloat32Array([p]), PackedByteArray([1]), PackedInt32Array([0]), PackedByteArray([1]),
			PackedByteArray([c]), PackedByteArray([1]), [1, 96, 300, 12000], 8, false)[0]
	assert_eq(one.call(72.0, CrowdPlan.T0), CrowdPlan.T0, "T0'da kalır (80 × 0,85 = 68)")
	assert_eq(one.call(85.0, CrowdPlan.T1), CrowdPlan.T1, "T0'a girmek için 92 px")
	assert_eq(one.call(93.0, CrowdPlan.T1), CrowdPlan.T0)
	assert_eq(one.call(25.0, CrowdPlan.T1), CrowdPlan.T1, "Kuklada kalır (28 × 0,85 = 23,8)")
	assert_eq(one.call(30.0, CrowdPlan.T3), CrowdPlan.T3, "Kuklaya girmek için 32,2 px")
	assert_eq(one.call(33.0, CrowdPlan.T3), CrowdPlan.T1)
	# Kadrajdakiler T1'i önce alır.
	var vis2 := PackedByteArray([0, 1])
	var t2 := CrowdPlan.select_tiers(PackedFloat32Array([100.0, 50.0]), vis2, PackedInt32Array([0, 0]), PackedByteArray([0, 0]),
		PackedByteArray([CrowdPlan.NONE, CrowdPlan.NONE]), PackedByteArray([1, 1]), [0, 1, 300, 12000], 8, true)
	assert_eq(t2[1], CrowdPlan.T1, "Kadrajdaki T1'de")
	assert_eq(t2[0], CrowdPlan.T2, "Kadraj dışındaki T2'de")


func test_select_tiers_swap_limit() -> void:
	var n := 30
	var px := PackedFloat32Array()
	var cur := PackedByteArray()
	var ones := PackedByteArray()
	var zeros := PackedInt32Array()
	var nofull := PackedByteArray()
	for i in n:
		px.append(60.0)
		cur.append(CrowdPlan.T3)
		ones.append(1)
		zeros.append(0)
		nofull.append(0)
	var out := CrowdPlan.select_tiers(px, ones, zeros, nofull, cur, ones, [0, 96, 300, 12000], 8, false)
	var changed := 0
	for i in n:
		if out[i] != cur[i]:
			changed += 1
	assert_eq(changed, 8, "Kare başına en çok 8 takas")
	# Yeni beliren takas sayılmaz.
	var fresh := PackedByteArray()
	for i in n:
		fresh.append(CrowdPlan.NONE)
	var appeared := CrowdPlan.select_tiers(px, ones, zeros, nofull, fresh, ones, [0, 96, 300, 12000], 8, false)
	for i in n:
		assert_eq(appeared[i], CrowdPlan.T1, "Beliren kişi kademesini hemen alır")
	# Yok olan (içeride) NONE olur.
	var gone := ones.duplicate()
	gone[0] = 0
	assert_eq(CrowdPlan.select_tiers(px, ones, zeros, nofull, appeared, gone, [0, 96, 300, 12000], 8, false)[0], CrowdPlan.NONE)


func test_puppet_meshes_and_shader() -> void:
	var t1 := CrowdPuppet.mesh(CrowdPuppet.DETAIL_T1)
	var t2 := CrowdPuppet.mesh(CrowdPuppet.DETAIL_T2)
	assert_between(float(CrowdPuppet.triangles(t1)), 400.0, float(CrowdPuppet.T1_MAX_TRIANGLES), "T1 ≤1.200 üçgen")
	assert_between(float(CrowdPuppet.triangles(t2)), 150.0, float(CrowdPuppet.T2_MAX_TRIANGLES), "T2 ≤360 üçgen")
	for m: ArrayMesh in [t1, t2]:
		var arrays := m.surface_get_arrays(0)
		var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var nrm: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var col: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var wrong := 0
		for t in range(0, idx.size(), 3):
			var g := (v[idx[t + 1]] - v[idx[t]]).cross(v[idx[t + 2]] - v[idx[t]])
			if g.length_squared() > 1e-12 and g.dot(nrm[idx[t]] + nrm[idx[t + 1]] + nrm[idx[t + 2]]) > 0.0:
				wrong += 1
		assert_eq(wrong, 0, "Üçgenler Godot'nun ön yüz sırasında (saat yönü)")
		var parts := {}
		var slots := {}
		for c in col:
			parts[int(round(c.g * 16.0))] = true
			slots[int(round(c.r * 8.0))] = true
		for part in [CrowdPuppet.PART_BODY, CrowdPuppet.PART_THIGH_L, CrowdPuppet.PART_SHIN_R, CrowdPuppet.PART_ARM_L, CrowdPuppet.PART_HEAD]:
			assert_true(parts.has(part), "Parça %d köşede" % part)
		for slot in [Folk.SLOT_COAT, Folk.SLOT_TRIM, Folk.SLOT_SKIN, Folk.SLOT_HAIR, Folk.SLOT_BOOTS]:
			assert_true(slots.has(slot), "Paletin yuvası %d köşede" % slot)
		var box := m.get_aabb()
		assert_between(box.end.y, 1.6, 1.95, "Kuklanın boyu")
		assert_almost(box.position.y, 0.0, 0.01, "Ayak zeminde")
	var t1_parts := {}
	for c in (t1.surface_get_arrays(0)[Mesh.ARRAY_COLOR] as PackedColorArray):
		t1_parts[int(round(c.g * 16.0))] = true
	for hat in [CrowdPuppet.PART_HAT_CAP, CrowdPuppet.PART_HAT_FUR, CrowdPuppet.PART_HAT_BAND]:
		assert_true(t1_parts.has(hat), "T1'de üç başlık (tek çizim)")
	for kind in ["", "mask", "normal"]:
		var shader := CrowdPuppet.shader(kind)
		assert_true(shader.code.contains("INSTANCE_CUSTOM"), "Canlandırma köşe gölgelendiricisinde")
		assert_false(shader.code.contains("HIP_Y_"), "Ölçüler koda yazıldı")
	assert_true(CrowdPuppet.shader("mask").code.contains("#define BAKE_MASK"))
	# CUSTOM: evre, yürüyüş, palet sırası, başlık × 2 + varlık.
	var c := CrowdPuppet.custom(1.25, 0.8, 17, 2, 0.5)
	assert_almost(c.r, 0.25, 1e-6)
	assert_almost(c.g, 0.8, 1e-6)
	assert_almost(c.b, 17.0, 1e-6)
	assert_almost(floor(c.a * 0.5), 2.0, 1e-6, "Başlık")
	assert_almost(c.a - 4.0, 0.5, 1e-6, "Varlık")


func test_palette_image_and_card_layout() -> void:
	var looks := []
	for i in 70:
		looks.append(Folk.make("t:pal:%d" % i))
	var img := CrowdPuppet.palette_image(looks)
	assert_eq(img.get_width(), CrowdPuppet.PALETTE_COLS * CrowdPuppet.PALETTE_SLOTS)
	assert_eq(img.get_height(), 2, "70 görünüş iki satır")
	var pal := Folk.palette(looks[65])
	var px := img.get_pixel((65 % 64) * 8 + Folk.SLOT_COAT, 1)
	assert_almost(px.r, pal[Folk.SLOT_COAT].r, 0.01, "65. görünüşün giysisi")
	assert_eq(CrowdCards.puppet_atlas_size(), Vector2i(256, 1536), "8 yön × 24 satır, 32×64 px")
	assert_eq(CrowdCards.puppet_cell(0, 0), 0)
	assert_eq(CrowdCards.puppet_cell(1, 2), (8 + 2) * 8, "Başlık öbeği ve kare")
	assert_eq(CrowdCards.walk_frame(0.0), 0)
	assert_eq(CrowdCards.walk_frame(0.99), CrowdCards.PUPPET_WALK_FRAMES - 1)
	# Hücrelerin ayağı görüntü alanının içinde ve hücresinde.
	var size := Vector2(CrowdCards.puppet_atlas_size())
	var mpp := CrowdCards.PUPPET_CELL_M.y / CrowdCards.PUPPET_CELL.y
	for row in [0, 23]:
		for d in [0, 7]:
			var off := CrowdCards.puppet_cell_offset(d, row)
			assert_between(off.x / mpp + size.x * 0.5, d * 32.0, (d + 1) * 32.0, "Hücrenin sütunu")
			assert_between(size.y * 0.5 - off.y / mpp, row * 64.0, (row + 1) * 64.0, "Hücrenin satırı")
	var mat := CrowdCards.palette_card_material(ImageTexture.create_from_image(img), {})
	assert_eq(mat.shader, CrowdCards.palette_card_shader())
	assert_eq(mat.get_shader_parameter(&"grid"), Vector2(8, 24))


func test_field_walks_to_plan_within_pace_and_snaps_far_away() -> void:
	var looks := []
	for i in 4:
		looks.append(Folk.make("t:field:%d" % i, {"role": "townsfolk", "body": "male"}))
	var field := CrowdField.new()
	field.setup(looks)
	field.set_process(false)
	add_child(field)
	_trash.append(field)
	field.focus = Vector3.ZERO
	field.height_px = 1080.0
	for i in 4:
		field.set_plan(i, Vector2(float(i) * 2.0, 5.0), 0.0, CrowdPlan.State.STAND, 1.0)
	field.tick(1.0 / 60.0)
	assert_eq(field.position_of(0), Vector3(0.0, 0.0, 5.0), "İlk yazışta planın yerinde")
	# Plan 30 m ileri sıçrar: kişi yürüyerek yetişir (en çok 1,4 × 1,5 = 2,1 m/sn).
	field.set_plan(0, Vector2(0.0, 35.0), 0.0, CrowdPlan.State.STAND, 1.0)
	for f in 120:
		field.tick(1.0 / 60.0)
	var walked := field.position_of(0).z - 5.0
	assert_almost(walked, 2.1 * 2.0, 0.05, "İki saniyede 4,2 m (yetişme 1,5 kat)")
	assert_true(field.peak_speed <= 1.4 * 1.5 + 0.01 and field.peak_speed <= PaceLimit.ADULT_RUN, "Hız oyuncunun koşusunu aşmaz")
	assert_eq(field.state_of(0), CrowdPlan.State.WALK, "Yetişen kişi yürür")
	assert_true(field.speed_of(0) > 2.0)
	# Uzakta ve kadraj dışında (kamera yok, odak uzakta) sıçrar.
	field.set_plan(1, Vector2(300.0, 300.0), 0.0, CrowdPlan.State.STAND, 1.0)
	field.focus = Vector3(-200.0, 0.0, -200.0)
	field.tick(1.0 / 60.0)
	assert_eq(field.position_of(1), Vector3(300.0, 0.0, 300.0), "60 m ötesinde sıçrar")
	# Yürüyüş evresi yürünen yoldan.
	field.focus = Vector3.ZERO
	var before := field.position_of(2)
	field.set_plan(2, Vector2(4.0, 5.0 + 1.0), 0.0, CrowdPlan.State.WALK, 1.0)
	field.tick(0.5)
	assert_true(field.position_of(2).distance_to(before) > 0.5, "Yürüdü")


func test_field_tiers_and_buffers_with_camera() -> void:
	var looks := []
	var n := 120
	for i in n:
		looks.append(Folk.make("t:tiers:%d" % i, {"role": "townsfolk"}))
	var cam := Camera3D.new()
	cam.fov = 36.0
	add_child(cam)
	_trash.append(cam)
	cam.look_at_from_position(Vector3(0.0, 17.2, 22.1), Vector3(0.0, 0.7, 0.0), Vector3.UP)
	var field := CrowdField.new()
	field.camera = cam
	field.height_px = 1080.0
	field.t0_slots = 2
	field.setup(looks)
	field.set_process(false)
	add_child(field)
	_trash.append(field)
	field.focus = Vector3.ZERO
	# Kişiler kameranın önünde, gittikçe uzakta: 0–9 yakın, sonra 60–400 m.
	for i in n:
		var d := float(i) * 0.6 if i < 10 else 60.0 + float(i - 10) * 3.2
		field.set_plan(i, Vector2(float(i % 5) - 2.0, -d), 0.0, CrowdPlan.State.STAND if i % 3 else CrowdPlan.State.WALK, 1.0)
	field.tick(1.0 / 60.0)
	var counts := field.counts()
	assert_eq(int(counts["T0"]), 2, "Tam kişi yuvaları dolu")
	assert_true(int(counts["T1"]) > 0 and int(counts["T1"]) <= CrowdField.CAP_T1)
	assert_true(int(counts["T3"]) > 0, "Uzakta kart")
	assert_eq(int(counts["T0"]) + int(counts["T1"]) + int(counts["T2"]) + int(counts["T3"]), n)
	var t1 := field.node_of(CrowdPlan.T1)
	assert_eq(t1.multimesh.visible_instance_count, int(counts["T1"]), "T1 yalnız dolu yuvaları çizer")
	assert_eq(field.node_of(CrowdPlan.T3).multimesh.visible_instance_count, int(counts["T3"]))
	assert_eq(t1.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "T1'in kendisi gölge düşürmez")
	var shadow := field.node_of("shadow")
	assert_eq(shadow.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY)
	assert_eq(shadow.multimesh.visible_instance_count, mini(int(counts["T1"]), CrowdField.SHADOW_NEAREST), "Gölge en yakın 24")
	assert_eq(field.node_of(CrowdPlan.T2).cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	# Bir T1 kişisinin CUSTOM'u: palet sırası kişinin sırasıdır.
	var some := -1
	for i in n:
		if field.tier_of(i) == CrowdPlan.T1:
			some = i
			break
	assert_true(some >= 0)
	var found := false
	for k in int(counts["T1"]):
		if field.slot_member(CrowdPlan.T1, k) == some:
			var c := field.slot_custom(CrowdPlan.T1, k)
			found = true
			assert_eq(int(round(c.b)), some, "Palet sırası kişinin sırası")
			assert_eq(int(floor(c.a * 0.5)), Folk.puppet_variant(looks[some]), "Başlık biçimi")
			assert_almost(c.a - floor(c.a * 0.5) * 2.0, 1.0, 1e-5, "Varlık tam")
	assert_true(found, "Kişi T1'in tamponunda")
	# Başsızda atlas pişmez; kademe seçimi sürer.
	if DisplayServer.get_name() == "headless":
		assert_false(field.has_card_atlas())
