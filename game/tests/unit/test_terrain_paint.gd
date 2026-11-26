extends TestCase
## İç haritanın saf yardımcıları (act-1-p2; Yol Haritası terrain-chunks, winter-camp-terrain, navigation, grass-streaming): TerrainPaint'in
## işlemleri (bölge düzlemi ve eğimi, yar yalnız keser, ırmak buzu düzdür, düz yerler merkezin yüksekliğinde, yolun eğimi sınırlı, yeniden
## örnekleme), yönlü uzaklık ve süperelips, yapı kaydının yarıçapı ve engeli, MapSpec'in rot → pusula çevirisi ve biçimli bölgeleri,
## MapEdge'in dört kutusu, nöbet ateşinin saati ve yarıçapı (16:30–07:40; Yakacak), Kızıl Kazık hattının yol boşlukları, akan çimenin
## kuralları (bahar ve kar altı), MapSky'nin geliştirme saati ve MapNav'ın ajan profilleri (companions.md §5.3). Sahnesizdir.


func _paint(rect: Rect2) -> TerrainPaint:
	var p := TerrainPaint.new()
	p.setup(rect, 1.0)
	return p


func test_region_sets_a_tilted_plane_and_blends_at_the_edge() -> void:
	var p := _paint(Rect2(-100.0, -100.0, 200.0, 200.0))
	p.apply({"op": "base", "height": 5.0})
	p.apply({"op": "region", "center": [0, 0], "size": [80, 80], "shape": "box", "height": 0.0, "blend": 20.0, "warp": {"amplitude": 0.0},
		"tilt": {"toward": 0.0, "deg": -3.0, "origin": [0, 0]}})
	assert_almost(p.height_at(0.0, 0.0), 0.0, 1e-4, "Düzlemin kökü")
	assert_almost(p.height_at(0.0, -30.0), -30.0 * tan(deg_to_rad(3.0)), 1e-3, "Kuzeye −3°: kuzeyde alçak")
	assert_almost(p.height_at(0.0, 30.0), 30.0 * tan(deg_to_rad(3.0)), 1e-3, "Güneyde yüksek")
	assert_almost(p.height_at(90.0, 90.0), 5.0, 1e-4, "Bölgenin dışı taban")
	var edge := p.height_at(40.0, 0.0)
	assert_between(edge, 1.5, 3.5, "Sınırda %50 karışım (blend sınırın iki yanına)")


func test_bluff_only_cuts_and_channel_ice_is_flat() -> void:
	var p := _paint(Rect2(-100.0, -100.0, 200.0, 200.0))
	p.apply({"op": "base", "height": 0.0})
	p.apply({"op": "bluff", "points": [[-80, 0], [80, 0]], "low_toward": 0.0, "top": -5.0, "low": -14.0, "drop": 9.0, "reach": 60.0, "end_fade": 10.0})
	assert_almost(p.height_at(0.0, 10.0), 0.0, 1e-4, "Yarın yüksek yanı (güney) değişmez")
	assert_almost(p.height_at(0.0, -20.0), -14.0, 0.05, "Yar dibi −14")
	assert_true(p.height_at(0.0, -4.0) < -5.0 and p.height_at(0.0, -4.0) > -14.0, "Düşüş 9 m'de")
	assert_almost(p.height_at(0.0, -90.0), 0.0, 0.05, "Erişimin ötesinde araziye döner")
	var q := _paint(Rect2(-100.0, -100.0, 200.0, 200.0))
	q.apply({"op": "base", "height": 0.0})
	q.apply({"op": "channel", "points": [[-100, 0, -18.0, 40], [100, 0, -18.0, 40]], "bank": 20.0})
	for x in [-60.0, 0.0, 60.0]:
		assert_almost(q.height_at(x, 0.0), -18.0, 1e-4, "Yatak düz (buz)")
		assert_almost(q.height_at(x, 10.0), -18.0, 1e-4)
	assert_true(q.sample(q.ice, 0.0, 0.0) > 0.99, "Yatakta buz")
	assert_almost(q.sample(q.ice, 0.0, 60.0), 0.0, 1e-4, "Kıyının ötesinde buz yok")
	assert_almost(q.height_at(0.0, 60.0), 0.0, 1e-4, "Kıyının ötesi arazi")


func test_flats_hold_the_centre_and_roads_limit_grade() -> void:
	var p := _paint(Rect2(-60.0, -60.0, 120.0, 120.0))
	p.apply({"op": "base", "height": 0.0})
	p.apply({"op": "region", "center": [0, 0], "size": [200, 200], "shape": "box", "height": 0.0, "blend": 1.0, "warp": {"amplitude": 0.0},
		"tilt": {"toward": 90.0, "deg": 10.0, "origin": [0, 0]}})
	p.apply_flat({"at": Vector2(20.0, 0.0), "flat": Vector2(5.0, 4.0), "trample": 5.0, "melt": Vector2.ZERO})
	var c := 20.0 * tan(deg_to_rad(10.0))
	for d in [0.0, 3.0, 4.9]:
		assert_almost(p.height_at(20.0 + d, 0.0), c, 0.02, "Düz yer merkezin yüksekliğinde (%.1f m)" % d)
	assert_true(p.sample(p.trample, 20.0, 0.0) > 0.99, "Ezik yer")
	assert_true(p.sample(p.calm, 20.0, 0.0) > 0.99, "Gürültü bastırılır")
	# Yolun eğimi: 1 m'de 0,5 m'lik basamak 8°'ye sınırlanır.
	var hs := PackedFloat32Array([0.0, 0.0, 0.0, 5.0, 5.0, 5.0])
	var limited := TerrainPaint.limit_grade(hs, 2.0 * tan(deg_to_rad(8.0)))
	for i in range(1, limited.size()):
		assert_true(absf(limited[i] - limited[i - 1]) <= 2.0 * tan(deg_to_rad(8.0)) + 1e-5, "Ardışık fark sınırda")
	var line := TerrainPaint.resample(PackedVector2Array([Vector2.ZERO, Vector2(10.0, 0.0)]), 2.0)
	assert_eq(line.size(), 6, "10 m 2 m'de: iki uç dahil 6 örnek")
	assert_almost(line[line.size() - 1].x, 10.0, 1e-5)


func test_shapes_and_record_radii() -> void:
	assert_vec_almost(Vector3(TerrainPaint.compass_dir(0.0).x, 0.0, TerrainPaint.compass_dir(0.0).y), Vector3(0.0, 0.0, -1.0), 1e-6, "0° kuzey −Z")
	assert_vec_almost(Vector3(TerrainPaint.compass_dir(90.0).x, 0.0, TerrainPaint.compass_dir(90.0).y), Vector3(1.0, 0.0, 0.0), 1e-6, "90° doğu")
	assert_almost(TerrainPaint.superellipse_sd(Vector2(10.0, 0.0), Vector2(10.0, 5.0), 2.0), 0.0, 1e-4, "Elipsin kenarı")
	assert_true(TerrainPaint.superellipse_sd(Vector2.ZERO, Vector2(10.0, 5.0), 4.0) < 0.0, "İçeride eksi")
	assert_almost(TerrainPaint.yurt_radius({"size": "m"}), 3.4, 1e-6, "Hane Yurdu")
	assert_almost(TerrainPaint.yurt_radius({"size": "s"}), 2.4, 1e-6, "Küçük Yurt ×0,7")
	assert_almost(TerrainPaint.yurt_radius({"size": "l"}), 4.8, 1e-6, "Otağ ×1,4")
	assert_almost(TerrainPaint.yurt_radius({"radius": 3.6, "size": "s"}), 3.6, 1e-6, "Kaydın yarıçapı önce gelir")
	assert_almost(TerrainPaint.obstacle_radius({"kind": "hearth"}), 0.0, 1e-6, "Yurt içindeki ocak engel değil")
	assert_true(TerrainPaint.obstacle_radius({"kind": "hearth", "outdoor": true}) > 0.0, "Açık havadaki ocak engel")
	assert_true(TerrainPaint.obstacle_radius({"kind": "landmark", "type": "deer_stone"}) > 0.0)
	assert_almost(TerrainPaint.obstacle_radius({"kind": "landmark", "type": "ford"}), 0.0, 1e-6, "Geçit engel değil")


func test_spec_reads_rot_bounds_and_shaped_regions() -> void:
	assert_almost(MapSpec.facing_of_rot(0.0), 180.0, 1e-6, "rot 0: kapı +Z (güney)")
	assert_almost(MapSpec.facing_of_rot(PI * 0.5), 90.0, 1e-6, "rot π/2: doğu")
	assert_almost(MapSpec.facing_of_rot(PI), 0.0, 1e-6, "rot π: kuzey")
	assert_almost(MapSpec.facing_of_rot(2.36), 180.0 - rad_to_deg(2.36), 1e-6, "Rehine Yurdu: kuzeydoğu")
	var spec := MapSpec.from_dict({"id": "t", "bounds": {"min": [-450, -760], "max": [950, 290]}, "structures": [{"kind": "yurt", "id": "y", "at": [1, 2], "rot": PI}],
		"regions": [{"id": "a", "center": [0, 0], "size": [200, 180]}, {"id": "b", "center": [0, 0], "size": [20, 20]},
			{"id": "river", "points": [[-100, 50], [100, 50]], "width": 20}]})
	assert_eq(spec.rect(), Rect2(-450.0, -760.0, 1400.0, 1050.0), "bounds dikdörtgendir")
	assert_eq(spec.size, Vector2(1400.0, 1050.0), "size bounds'tan")
	assert_almost(float(spec.structures[0]["facing"]), 0.0, 1e-6, "rot → facing")
	assert_eq(str(spec.region_at(Vector2(5.0, 5.0)).get("id", "")), "b", "İç içe bölgede küçüğü")
	assert_eq(str(spec.region_at(Vector2(60.0, 30.0)).get("id", "")), "a")
	assert_eq(str(spec.region_at(Vector2(0.0, 55.0)).get("id", "")), "river", "Şerit bölge (ırmak)")
	assert_true(spec.region_at(Vector2(500.0, 500.0)).is_empty())
	assert_eq(spec.raw.get("id"), "t", "Ham tarif okunur")


func test_map_edge_boxes_hold_the_rectangle() -> void:
	var r := Rect2(-450.0, -760.0, 1400.0, 1050.0)
	var boxes := MapEdge.boxes_for(r, 6.0)
	assert_eq(boxes.size(), 4)
	var inside := Vector2(0.0, 0.0)
	for b in boxes:
		assert_false(b.contains(inside), "İçerisi açık")
		assert_eq(b.push_out(inside, 0.4), inside)
	# Kenarın ötesine itilen nokta kutunun yüzünde durur: kenardan 6 m içeride.
	var out := Vector2(-449.0, 0.0)
	for b in boxes:
		out = b.push_out(out, 0.4)
	assert_true(out.x >= -444.0 - 0.001, "Batı kenarının 6 m içi (%.2f)" % out.x)


func test_watch_fires_follow_the_clock_and_fuel() -> void:
	assert_almost(WatchFires.lit_at(12.0 * 60.0), 0.0, 1e-6, "Öğlede sönük")
	assert_almost(WatchFires.lit_at(16.0 * 60.0 + 29.0), 0.0, 1e-6, "16:29 sönük")
	assert_almost(WatchFires.lit_at(16.0 * 60.0 + 40.0), 1.0, 1e-6, "16:40 yanık")
	assert_almost(WatchFires.lit_at(23.0 * 60.0), 1.0, 1e-6, "Gece yanık")
	assert_almost(WatchFires.lit_at(3.0 * 60.0), 1.0, 1e-6, "Gece yarısından sonra yanık")
	assert_almost(WatchFires.lit_at(7.0 * 60.0 + 39.0), 1.0, 1e-6, "07:39 yanık")
	assert_almost(WatchFires.lit_at(7.0 * 60.0 + 50.0), 0.0, 1e-6, "07:50 sönük")
	assert_almost(WatchFires.radius_for(0.6), 6.0, 1e-6, "≤%60 Yakacak 6 m")
	assert_almost(WatchFires.radius_for(0.3), 6.0, 1e-6)
	assert_almost(WatchFires.radius_for(1.0), 12.0, 1e-6, "≥%100 12 m")


func test_red_stakes_leave_gaps_for_roads() -> void:
	var square := PackedVector2Array([Vector2(-20, -20), Vector2(20, -20), Vector2(20, 20), Vector2(-20, 20)])
	var all := RedStakes.stake_points(square, 4.0, [], 2.5)
	assert_eq(all.size(), 40, "160 m çevre 4 m'de: 40 kazık")
	var road := [{"points": [[0, -60], [0, 60]], "width": 4.0}]
	var gapped := RedStakes.stake_points(square, 4.0, road, 2.5)
	assert_true(gapped.size() < all.size(), "Yol hattı keser")
	for p in gapped:
		assert_true(absf(p.x) > 4.5 - 0.001 or absf(p.z) < 19.0, "Boşlukta kazık yok")
	var stakes := RedStakes.new()
	stakes.outline = square
	assert_true(stakes.inside(Vector2.ZERO))
	assert_true(stakes.crossed(Vector2.ZERO, Vector2(30.0, 0.0)), "Hat geçildi")
	assert_false(stakes.crossed(Vector2.ZERO, Vector2(5.0, 0.0)))
	stakes.free()


func test_grass_rules_for_spring_and_snow() -> void:
	assert_almost(GrassField.meadow_weight(Vector4.ZERO), 0.75, 1e-6, "Açık otluk")
	assert_true(GrassField.meadow_weight(Vector4(1.0, 0.0, 0.0, 0.0)) < 0.05, "Patikada yok")
	# Kar altı: buzda, kayada ve ezik yerin ortasında yok; kıyıda ve sazlıkta var; açık karda çok seyrek.
	assert_almost(GrassField.dry_weight(Vector4(1.0, 0.0, 0.0, 0.0), Vector4(1.0, 0.0, 0.0, 0.0), 0.0), 0.0, 1e-6, "Buzda yok")
	assert_almost(GrassField.dry_weight(Vector4(1.0, 0.0, 0.0, 0.0), Vector4(0.0, 1.0, 0.0, 0.0), 0.0), 0.0, 1e-6, "Kayada yok")
	assert_true(GrassField.dry_weight(Vector4(1.0, 1.0, 0.0, 0.0), Vector4.ZERO, 0.0) < 0.05, "Ezik yerin ortasında yok")
	assert_true(GrassField.dry_weight(Vector4(1.0, 0.35, 0.0, 0.0), Vector4.ZERO, 0.0) > 0.4, "Ezik yerin kıyısında var")
	assert_true(GrassField.dry_weight(Vector4(1.0, 0.0, 0.0, 0.0), Vector4(0.0, 0.0, 0.9, 0.0), 0.0) > 0.8, "Sazlıkta sap")
	var open := GrassField.dry_weight(Vector4(1.0, 0.0, 0.0, 0.0), Vector4.ZERO, 0.0)
	assert_between(open, 0.01, 0.05, "Açık karda çok seyrek")
	assert_true(GrassField.dry_weight(Vector4(1.0, 0.0, 0.0, 1.0), Vector4.ZERO, 0.0) < open, "Kabukta daha seyrek")


func test_agent_profiles_follow_companions() -> void:
	var walker := MapNav.profile(MapNav.WALKER)
	assert_almost(float(walker["radius"]), 0.45, 1e-6, "Yaya 0,45 m")
	assert_almost(float(walker["neighbor_distance"]), 6.0, 1e-6)
	assert_eq(int(walker["max_neighbors"]), 6)
	assert_almost(float(walker["time_horizon_agents"]), 0.8, 1e-6)
	assert_almost(float(walker["time_horizon_obstacles"]), 0.4, 1e-6)
	assert_almost(float(walker["path_max_distance"]), 2.0, 1e-6)
	var rider := MapNav.profile(MapNav.RIDER)
	assert_almost(float(rider["radius"]), 1.1, 1e-6, "Atlı 1,1 m")
	assert_almost(float(rider["neighbor_distance"]), 12.0, 1e-6)
	assert_almost(float(rider["path_max_distance"]), 4.0, 1e-6)
	assert_false(bool(MapNav.profile(MapNav.ANIMAL_SMALL)["avoidance"]), "Hayvanda kaçınma kapalı (açık bozkır)")
	var agent := NavigationAgent3D.new()
	MapNav.setup_agent(agent, MapNav.RIDER, MapNav.PRIORITY_METE)
	assert_almost(agent.radius, 1.1, 1e-6)
	assert_almost(agent.avoidance_priority, 1.0, 1e-6, "Mete'nin önceliği 1,0")
	assert_true(agent.avoidance_enabled)
	agent.free()
	assert_almost(MapNav.TARGET_HZ, 4.0, 1e-6, "Hedef 4 Hz'de yenilenir")


func test_map_sky_dev_time_reads_the_probe_table() -> void:
	var path := "res://data/maps/kislak/light.json"
	assert_true(MapSky.has_stops(path), "Kışlak'ın ışık dosyası altı duraklı tablo")
	assert_false(MapSky.has_stops("res://data/maps/testmap/light.json"), "Deneme haritasınınki değil")
	var noon := MapSky.dev_time(path, {"light": "noon"})
	assert_eq(int(noon.x), 1041, "Gün I")
	assert_almost(noon.y, 705.0, 1e-6, "Öğle 11:45")
	var clamp := MapSky.dev_time(path, {"light": "clamp_am"})
	assert_almost(clamp.y, 510.0, 1e-6, "Gölge kıstırması 08:30")
	var clock := MapSky.dev_time(path, {"clock": "21:30", "day": "1043"})
	assert_eq(int(clock.x), 1043)
	assert_almost(clock.y, 1290.0, 1e-6)
	assert_eq(MapSky.dev_time(path, {}), Vector2(-1.0, -1.0), "İstenmediyse yok")
