extends TestCase
## Parametrik yurt (yurt-variants; K51; structures.md §3.5, §3.6, §13.5, §17 kabul 16, 25; godot.md §4.6, §6.7): üç boy kök ölçektir
## (yatay ×0,7 / ×1 / ×1,4), millet yalnız görünüşü değiştirir (sayılar boydan), düzenler takma adlarıyla açılır, hazır ayarların
## üçgen bütçesi tutar (winter ≤34k, iç ≤12k, Küçük ev ≤6k, closed ≤3k, dome ≤96), ağ paylaşılır, aşama kiti kipleri köşededir.

func before_each() -> void:
	YurtStyle.forget()
	YurtGeometry.forget()
	YurtLayouts.forget()


func test_styles_and_sizes() -> void:
	for id in ["hun", "yuezhi", "usun", "saka", "tunghu", "dingling", "loufan", "baiyang", "ciang", "han"]:
		assert_true(YurtStyle.has(id), "Millet %s" % id)
	assert_eq(YurtStyle.find("yok").id, "hun", "Bilinmeyen Hun")
	assert_almost(YurtStyle.size_scale("s").x, 0.7, 1e-6)
	assert_almost(YurtStyle.size_scale("m").x, 1.0, 1e-6)
	assert_almost(YurtStyle.size_scale("l").x, 1.4, 1e-6)
	var hun := YurtStyle.find("hun")
	var yz := YurtStyle.find("yuezhi")
	assert_almost(yz.wall_height() / hun.wall_height(), 1.1, 1e-6, "Yüeçi duvarı ×1,1")
	assert_almost(yz.roof_height() / hun.roof_height(), 1.2, 1e-6, "Yüeçi çatısı ×1,2")
	assert_true(hun.door_size().y >= 1.95, "Hane kapısı Mete'nin boyunu geçer: %.2f" % hun.door_size().y)
	var d := YurtGeometry.dims(hun, "l")
	assert_almost(float(d["radius"]), 3.3 * 1.4, 1e-6, "Otağ yarıçapı ×1,4")
	assert_true((d["door"] as Vector2).y > 2.2, "Otağ kapısı")
	assert_almost(YurtStyle.find("hun").default_rot(), PI - deg_to_rad(120.0), 1e-6, "Hun kapısı 120° (gündoğusu)")


func test_numbers_come_from_size_only() -> void:
	for size in ["s", "m", "l"]:
		var works := {}
		for style in ["hun", "yuezhi", "tunghu"]:
			var site := SiteState.create("yurt", size)
			works[style] = [site.total_work(), site.hp_max()]
		assert_eq(works["hun"], works["yuezhi"], "Boy %s: millet sayı değiştirmez" % size)
		assert_eq(works["hun"], works["tunghu"])


func test_layout_aliases() -> void:
	assert_eq(YurtLayouts.resolve("feast"), "han")
	assert_eq(YurtLayouts.resolve("council"), "otag")
	assert_eq(YurtLayouts.resolve("yok"), "ev")
	for key in ["ev", "konuk", "ambar", "otag", "han", "silah", "otaci", "bolmeli"]:
		assert_true(YurtLayouts.keys().has(key), "Düzen %s" % key)
	var rec := StructureKit.normalize({"kind": "yurt", "id": "a", "at": [0, 0], "design": "bolmeli"})
	assert_eq(str(rec["layout"]), "bolmeli", "Eski design alanı layout okunur")
	var def := StructureKit.normalize({"kind": "yurt", "id": "b", "at": [0, 0], "rot": 0.0})
	assert_eq([def["size"], def["style"], def["layout"]], ["m", "hun", "ev"], "Eksik alan m, hun ve türün düzeni")
	assert_eq(str(StructureKit.normalize({"kind": "healer_yurt", "id": "c", "at": [0, 0], "rot": 0.0})["layout"]), "otaci")


func test_triangle_budgets() -> void:
	for style in ["hun", "yuezhi"]:
		var st := YurtStyle.find(style)
		var winter := StagedMesh.triangles_of(YurtGeometry.mesh(st, "m", "winter"))
		var closed := StagedMesh.triangles_of(YurtGeometry.mesh(st, "m", "closed"))
		var dome := StagedMesh.triangles_of(YurtGeometry.mesh(st, "m", "dome"))
		var hero := StagedMesh.triangles_of(YurtGeometry.mesh(st, "m", "hero"))
		print("[yurt] %s winter %d closed %d dome %d hero %d" % [style, winter, closed, dome, hero])
		assert_true(winter <= 22000, "%s winter kit ≤22k (iç ≤12k ile ≤34k): %d" % [style, winter])
		assert_true(closed <= 3000, "%s closed ≤3k: %d" % [style, closed])
		assert_true(dome <= 96, "%s dome ≤96: %d" % [style, dome])
		assert_true(hero <= 60000, "%s hero ≤60k: %d" % [style, hero])
	for key in YurtLayouts.keys():
		var w := StagedMesh.triangles_of(YurtLayouts.mesh(key, "m", "winter"))
		var h := StagedMesh.triangles_of(YurtLayouts.mesh(key, "m", "hero"))
		print("[layout] %s winter %d hero %d" % [key, w, h])
		assert_true(w <= 12000, "%s winter iç ≤12k: %d" % [key, w])
		assert_true(h <= 30000, "%s hero iç: %d" % [key, h])
	var small := StagedMesh.triangles_of(YurtLayouts.mesh("ev", "s", "winter"))
	assert_true(small <= 6000, "Küçük ev ≤6k: %d" % small)
	assert_true(StagedMesh.triangles_of(YurtGeometry.mesh(YurtStyle.find("yuezhi"), "s", "winter")) <= 28000, "Küçük winter ≤28k")


func test_mesh_is_shared_and_staged() -> void:
	var st := YurtStyle.find("yuezhi")
	assert_eq(YurtGeometry.mesh(st, "m", "winter"), YurtGeometry.mesh(st, "m", "winter"), "Önbellek: aynı ağ")
	var m := YurtGeometry.mesh(st, "m", "winter")
	var stages := {}
	for s in m.get_surface_count():
		var arr := m.surface_get_arrays(s)
		var c0: PackedFloat32Array = arr[Mesh.ARRAY_CUSTOM0]
		for i in range(0, c0.size(), 4):
			stages[int(c0[i])] = true
	for n in 8:
		assert_true(stages.has(n), "Aşama %d'nin parçası var" % n)
	assert_eq(StagedMesh.surface_kinds(m).size(), 2, "İki yüzey: kalın ve ince")


func test_wing_order() -> void:
	assert_eq(YurtGeometry.wing_order(6), [0, 5, 1, 4, 2, 3], "Hane: k0, k5, k1, k4, k2, k3")
	assert_eq(YurtGeometry.wing_order(4), [0, 3, 1, 2], "Küçük: k0, k3, k1, k2")
	assert_eq(YurtGeometry.wing_order(8), [0, 7, 1, 6, 2, 5, 3, 4], "Otağ: kapıdan iki yana")


func test_yurt_node_scales_and_counter_scales() -> void:
	var y := StagedYurt.new()
	y.configure({"size": "l", "style": "hun", "layout": "otag", "preset": "winter", "open": true})
	add_child(y)
	await wait_frames(1)
	assert_almost(y.scale.x, 1.4, 1e-6, "Kök ölçeği")
	assert_not_null(y.interior, "Açık yurtta iç düzen")
	assert_almost(y.interior.scale.x * y.scale.x, 1.0, 1e-6, "İç ×1 kalır (ters ölçek)")
	y.set_stage(1)
	assert_eq(y.get_obstacle_walls().size(), 0, "Kerege yokken halka duvar yok")
	y.set_stage(7)
	assert_eq(y.get_obstacle_walls().size(), 1, "Açık yurt halka duvardır")
	assert_true(y.get_obstacle_boxes().size() >= 3, "İçeride eşya kutuları")
	var c := StagedYurt.new()
	c.configure({"size": "m", "style": "yuezhi", "preset": "closed", "open": false})
	add_child(c)
	await wait_frames(1)
	assert_null(c.interior, "Kapalı yurtta iç yok")
	assert_eq(c.get_obstacle_circles().size(), 1, "Kapalı yurt dairedir")
	y.queue_free()
	c.queue_free()
	await wait_frames(1)
