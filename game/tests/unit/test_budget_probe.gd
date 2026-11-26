extends TestCase
## Bütçe ölçüm sahnesinin (scenes/dev/budget_probe.tscn, scripts/dev/budget_probe.gd) saf hesapları ve bütçe
## verisi (data/budgets.json, data/budget_baseline.json). Ölçümün kendisi pencerelidir (tools/capture.sh ile; bkz.
## docs/testler.md «Bütçe ölçümü»); burada pozların kuralı (godot.md §7.4: 5 nokta × 4 yön × 3 uzaklık, eğim
## bandının iki ucu), kameranın kadrajı, istatistik, çimenin payı ve bütçe tablosunun makine kopyası sınanır.

const Probe := preload("res://scripts/dev/budget_probe.gd")
const BUDGETS_PATH := "res://data/budgets.json"
const BASELINE_PATH := "res://data/budget_baseline.json"
## Ölçümün sınadığı alanlar (tools/check_budget.py METRICS ile aynı).
const CHECKED_FIELDS: Array[String] = ["frame_ms", "script_ms", "draw_calls_visible", "draw_calls_shadow",
	"triangles_visible", "triangles_shadow", "texture_mib", "video_mib"]


## world.tscn'deki yerler: ateş, ahır, iki yurt; oyun alanı merkezde 38 m.
func _points() -> Dictionary:
	return Probe.camp_points(JourneyFlags.DEFAULT_FIRE, JourneyFlags.DEFAULT_STABLE, Vector2(-6.18, -4.31),
		Vector2(6.64, -7.26), Vector2.ZERO, 38.0)


func test_pose_set_follows_design() -> void:
	# 5 nokta × 4 yön × 3 uzaklık, her biri varsayılan eğimde ve bandın iki ucunda: 180 çimenli poz; çimenin
	# payı için 27 m'deki varsayılan eğimli 20 pozun çimensiz eşi.
	var poses := Probe.build_poses(_points())
	assert_eq(poses.size(), 200)
	var ids := {}
	var combos := {}
	var grass := 0
	for pose in poses:
		ids[pose["id"]] = true
		if pose["grass"]:
			grass += 1
			combos["%s|%s|%s|%s" % [pose["point"], pose["distance"], pose["yaw"], pose["pitch_mode"]]] = true
		else:
			assert_eq(float(pose["distance"]), FollowCamera.DEFAULT_DISTANCE, "Çimensiz eş varsayılan uzaklıktadır: %s" % pose["id"])
			assert_eq(str(pose["pitch_mode"]), "default", "Çimensiz eş varsayılan eğimdedir: %s" % pose["id"])
			assert_true(str(pose["id"]).ends_with("/nograss"))
	assert_eq(ids.size(), poses.size(), "Poz kimlikleri tekil olmalı")
	# Çimensiz eş çimenli pozun hemen ardından ölçülür: uzun koşuda yük ve ısı kayar, fark ancak yan yana anlamlıdır.
	for i in poses.size():
		if not poses[i]["grass"]:
			assert_eq(str(poses[i - 1]["id"]) + "/nograss", str(poses[i]["id"]), "%s eşinin hemen ardından gelmeli" % poses[i]["id"])
	assert_eq(grass, 180)
	assert_eq(combos.size(), 180, "Her nokta, uzaklık, yön ve eğim birleşimi bir kez ölçülmeli")
	for point in ["fire", "stable", "yurts", "lake_slope", "edge"]:
		for distance in [14.0, 28.0, 40.0]:
			for yaw in [0.0, 90.0, 180.0, 270.0]:
				for mode in ["default", "low", "high"]:
					assert_true(combos.has("%s|%s|%s|%s" % [point, distance, yaw, mode]), "%s %s m %s° %s eksik" % [point, distance, yaw, mode])


func test_pitch_modes_cover_band_ends() -> void:
	# Varsayılan eğim uzaklığa bağlıdır (takip kamerası, K98: 28 m'de 38°; yaklaşınca yatıklaşmaz, yakın plan yok; en uzakta 6° dik);
	# bandın uçları 15° ve 60°'dir (godot.md §5.1).
	assert_almost(Probe.pitch_for("default", FollowCamera.DEFAULT_DISTANCE), FollowCamera.DEFAULT_PITCH_DEG)
	assert_almost(Probe.pitch_for("default", Probe.MIN_DISTANCE), FollowCamera.DEFAULT_PITCH_DEG)
	assert_almost(Probe.pitch_for("default", Probe.MAX_DISTANCE), FollowCamera.DEFAULT_PITCH_DEG + 6.0)
	assert_almost(Probe.pitch_for("low", 28.0), 15.0)
	assert_almost(Probe.pitch_for("high", 14.0), 60.0)
	assert_eq(Probe.PITCH_BAND, Vector2(15.0, 60.0))


func test_probe_constants_match_follow_camera() -> void:
	# Ölçüm takip kamerasının kadrajını kurar: yakınlaştırma sınırları, eğim payı, bakış yüksekliği ve zemin payı
	# FollowCamera'nınkiyle aynı olmalı (ayar değişirse ölçüm başka kadrajı ölçer).
	var follow := FollowCamera.new()
	assert_almost(follow.min_distance, Probe.MIN_DISTANCE)
	assert_almost(follow.max_distance, Probe.MAX_DISTANCE)
	assert_almost(follow.zoom_tilt_deg, Probe.ZOOM_TILT)
	assert_almost(follow.look_height, Probe.LOOK_HEIGHT)
	assert_almost(follow.ground_clearance, Probe.GROUND_CLEARANCE)
	assert_almost(follow.distance, FollowCamera.DEFAULT_DISTANCE)
	follow.free()


func test_camp_points() -> void:
	var points := _points()
	assert_eq(points.size(), 5)
	assert_eq(points["fire"], JourneyFlags.DEFAULT_FIRE)
	assert_eq(points["stable"], JourneyFlags.DEFAULT_STABLE)
	assert_true((points["yurts"] as Vector2).is_equal_approx(Vector2(0.23, -5.785)), "Yurtların arası iki yurdun ortasıdır")
	# Göle bakan yamaç: Destan Kitabı'nın «Göle Bakan Yamaç» işaretinin konduğu yerde (JourneyFlags).
	var lake: Vector2 = points["lake_slope"]
	assert_true(JourneyFlags.overlooks_lake(lake, JourneyFlags.DEFAULT_FIRE), "Yamaç noktası göle bakmalı: %s" % lake)
	assert_almost(lake.length(), JourneyFlags.LAKE_VIEW_DISTANCE + Probe.LAKE_MARGIN)
	# Oyun alanının kenarı: kenarın 2 m içi, gölün karşısında (güney, +Z).
	var edge: Vector2 = points["edge"]
	assert_almost(edge.length(), 38.0 - Probe.EDGE_MARGIN)
	assert_true(edge.y > 30.0 and absf(edge.x) < 0.001, "Kenar noktası güneyde olmalı: %s" % edge)


func test_camera_frames_each_pose_above_ground() -> void:
	# Her pozda kamera odağa (noktanın 0,7 m üstü) bakar, zeminin en az 1,2 m üstündedir ve gömülmediyse odağa pozun
	# uzaklığındadır; 0° açıda kamera noktanın güneyindedir (kuzeye bakar).
	var shape := TerrainShape.new()
	var lifted := 0
	for pose in Probe.build_poses(_points()):
		var xform := Probe.camera_transform(shape, pose)
		var x := float(pose["x"])
		var z := float(pose["z"])
		var focus := Vector3(x, shape.height_at(x, z) + Probe.LOOK_HEIGHT, z)
		var forward := -xform.basis.z
		var to_focus := (focus - xform.origin).normalized()
		assert_true(forward.dot(to_focus) > 0.999, "%s: kamera odağa bakmalı" % pose["id"])
		var ground := shape.height_at(xform.origin.x, xform.origin.z)
		assert_true(xform.origin.y >= ground + Probe.GROUND_CLEARANCE - 0.001, "%s: kamera zemine gömülmemeli" % pose["id"])
		var distance := xform.origin.distance_to(focus)
		if absf(distance - float(pose["distance"])) > 0.01:
			lifted += 1
			assert_almost(xform.origin.y, ground + Probe.GROUND_CLEARANCE, 0.001, "%s: yalnız zemin payı kadar kaldırılır" % pose["id"])
		if float(pose["yaw"]) == 0.0:
			assert_true(xform.origin.z > focus.z, "%s: 0° açıda kamera güneydedir" % pose["id"])
	assert_true(lifted < 20, "Pozların çoğu takip kamerasının kadrajında kalmalı (kaldırılan %d)" % lifted)


func test_percentile_and_summary() -> void:
	var values := PackedFloat64Array()
	for i in range(100, 0, -1):
		values.append(float(i))
	assert_almost(Probe.percentile(values, 0.95), 95.0, 0.0001, "En yakın sıra: 100 değerin %95'i 95. değerdir")
	assert_almost(Probe.percentile(values, 1.0), 100.0)
	assert_almost(Probe.percentile(PackedFloat64Array([7.0]), 0.95), 7.0)
	assert_almost(Probe.percentile(PackedFloat64Array(), 0.95), 0.0)
	var stats := Probe.summarize(values)
	assert_almost(float(stats["mean"]), 50.5)
	assert_almost(float(stats["p95"]), 95.0)
	assert_almost(float(stats["max"]), 100.0)
	assert_eq(Probe.summarize(PackedFloat64Array()), {"mean": 0.0, "p95": 0.0, "max": 0.0})
	assert_almost(float(Probe.summarize(PackedFloat64Array([1.0, 2.0]), 0.1)["mean"]), 1.5)


func test_grass_share_compares_twins() -> void:
	# Çimenin payı: çimenli poz − çimensiz eşi; eşi olmayan çimensiz poz sayılmaz.
	var poses := [
		_row("fire/27m/yaw0/default", true, 10.0, 300.0),
		_row("fire/27m/yaw0/default/nograss", false, 9.0, 250.0),
		_row("edge/27m/yaw0/default", true, 12.0, 280.0),
		_row("edge/27m/yaw0/default/nograss", false, 11.5, 270.0),
		_row("stable/27m/yaw0/default/nograss", false, 5.0, 100.0),
	]
	var share := Probe.grass_share(poses)
	assert_eq(share["pairs"], 2)
	assert_almost(float(share["frame_ms"]["mean"]), 0.75)
	assert_almost(float(share["frame_ms"]["max"]), 1.0)
	assert_almost(float(share["draw_calls_visible"]["mean"]), 30.0)
	assert_almost(float(share["draw_calls_visible"]["max"]), 50.0)
	assert_eq(str(share["draw_calls_visible"]["stat"]), "max", "Çizimde pozun en büyük değeri karşılaştırılır")


func test_output_path_and_filter() -> void:
	assert_eq(Probe.output_path({"probe-out": "/tmp/a.json", "capture": "/tmp/b.png"}), "/tmp/a.json", "--probe-out önce gelir")
	assert_eq(Probe.output_path({"capture": "/tmp/olcum/budget.png"}), "/tmp/olcum/budget.json", "JSON görüntünün yanına yazılır")
	assert_eq(Probe.output_path({"probe-out": true}), "", "Değersiz --probe-out yol değildir")
	assert_eq(Probe.output_path({}), "")
	assert_true(Probe.wanted("fire/27m/yaw0/default", ""))
	assert_true(Probe.wanted("fire/27m/yaw0/default", "true"), "Değersiz süzgeç her pozu geçirir")
	assert_true(Probe.wanted("fire/27m/yaw0/default", "/27m/"))
	assert_false(Probe.wanted("menu", "/27m/"))


func test_mesh_triangles() -> void:
	assert_eq(Probe.mesh_triangles(null), 0)
	var box := BoxMesh.new()
	assert_eq(Probe.mesh_triangles(box), 12, "Bölünmemiş kutu 12 üçgendir")
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3.RIGHT, Vector3.UP, Vector3.ONE])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 1, 2, 1, 3, 2])
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	assert_eq(Probe.mesh_triangles(mesh), 2, "Dizinli ağda üçgen = dizin / 3")


func test_myth_probe_measures_each_panel_at_its_third_second() -> void:
	assert_eq(Probe.PROBES["myth"], "interior", "Mit videosunun maliyeti iç harita satırında okunur (K93)")
	var timeline := CineTimeline.from_path(Probe.BIRTH_SEQUENCE)
	var poses := Probe.myth_poses(timeline)
	assert_eq(poses.map(func(p: Dictionary) -> String: return p["id"]),
		["myth/panel_1", "myth/panel_2", "myth/panel_3", "myth/panel_4", "myth/panel_5", "myth/panel_6"], "Altı pano, sırayla")
	for i in poses.size():
		var start := timeline.time_of("myth:panel_%d" % (i + 1))
		assert_almost(float(poses[i]["at"]), start + 3.0, 0.011, "%s: çekimin 3. saniyesi" % poses[i]["id"])
		var next := timeline.time_of("myth:panel_%d" % (i + 2)) if i + 1 < poses.size() else timeline.time_of("myth_end")
		assert_true(float(poses[i]["at"]) + float(Probe.MEASURE_FRAMES) / 60.0 < next, "%s: 180 kare panonun içinde kalır" % poses[i]["id"])
		assert_eq(str(poses[i]["point"]), "myth")
	assert_true(Probe.wanted("myth/panel_3", "/panel_3") and not Probe.wanted("myth/panel_1", "/panel_3"), "--probe-only panoyu süzer")
	assert_true(Probe.myth_poses(CineTimeline.from_dict({"id": "boş", "segments": [{"id": "myth", "length": 1.0, "events": []}]})).is_empty(),
		"Dizide bulunmayan pano atlanır")


func test_birth_probe_measures_inside_each_shot() -> void:
	assert_eq(Probe.PROBES["birth"], "interior", "childhood_ordos bir iç haritadır (K63)")
	var timeline := CineTimeline.from_path(Probe.BIRTH_SEQUENCE)
	var poses := Probe.birth_poses(timeline)
	assert_eq(poses.map(func(p: Dictionary) -> String: return p["id"]), ["birth/7a", "birth/7b", "birth/7d", "birth/7e"], "Dört çekim, sırayla")
	# 180 kare en kötü sınırda (28 ms) ≈5 sn sürer: ölçüm çekimin içinde kalmalı, sonraki kesmeye taşmamalı.
	var next_cuts := ["birth:7b", "birth:7c", "birth:7e", "birth:panel_8"]
	for i in poses.size():
		var room: float = timeline.time_of(next_cuts[i]) - float(poses[i]["at"])
		assert_true(room >= 5.0, "%s: kesmeye %.2f sn kalır" % [poses[i]["id"], room])
	assert_true(Probe.wanted("birth/7e", "/7e") and not Probe.wanted("birth/7a", "/7e"), "--probe-only çekimi süzer")


func test_childhood_probe_measures_gameplay_framing() -> void:
	assert_eq(Probe.PROBES["childhood"], "interior", "childhood_ordos bir iç haritadır (K63)")
	var layout := OrdosWorld.load_layout(OrdosWorld.LAYOUT_PATH)
	var points := Probe.childhood_points(layout)
	assert_eq(points.size(), Probe.CHILDHOOD_POINTS.size(), "Her noktanın düzende işareti var")
	var poses := Probe.childhood_poses(points)
	# E21 (K110): kampın sekiz noktasına Kamışlı Göl (kıyı, sazlık, sayım taşları), göle giden yol ve Ebe Obası eklendi.
	assert_eq(poses.size(), points.size() * 9, "%d nokta × (4 yön × 22 ve 40 m + 14 m); sayımda çocukların yeri de" % points.size())
	var ids := {}
	var shape := OrdosGround.new(ChildhoodSite.merged_spec(layout))
	for pose in poses:
		ids[pose["id"]] = true
		assert_almost(float(pose["pitch"]), 38.0, 0.001, "K98: eğim 38°")
		assert_true(float(pose["distance"]) in [14.0, 22.0, 40.0], "K98: 14–40 m")
		assert_true(str(pose["herd"]) in ["pen", "leaving", "meadow", "line", "water", "way"], "%s sürünün durumu" % pose["id"])
		assert_true(ChildhoodSite.in_walk_area(layout, Vector2(float(pose["x"]), float(pose["z"]))), "%s yürünür alanda" % pose["id"])
		var xform := Probe.camera_transform(shape, pose)
		assert_true(xform.origin.y >= shape.height_at(xform.origin.x, xform.origin.z) + Probe.GROUND_CLEARANCE - 0.001, "%s zemine gömülmez" % pose["id"])
	assert_eq(ids.size(), poses.size(), "Poz kimlikleri tekil")
	assert_true(Probe.wanted("pen/27m/yaw0/default", "pen/27m"), "--probe-only noktayı süzer")


func test_probe_scene_runs_probe_script() -> void:
	# Sahne örneklenmez (ölçümü başlatır ve oyunu kapatır); kaydı okunur.
	var packed := load("res://scenes/dev/budget_probe.tscn") as PackedScene
	assert_not_null(packed)
	if packed == null:
		return
	var state := packed.get_state()
	var script: Variant = null
	for j in state.get_node_property_count(0):
		if state.get_node_property_name(0, j) == &"script":
			script = state.get_node_property_value(0, j)
	assert_true(script is Script and (script as Script).resource_path == "res://scripts/dev/budget_probe.gd",
		"Kök düğüm ölçüm betiğini taşımalı")


func test_budgets_json_matches_design() -> void:
	# data/budgets.json godot.md §7.2'nin makine kopyasıdır (K63); tools/check_budget.py bunu okur.
	var budgets := _json(BUDGETS_PATH)
	if budgets.is_empty():
		return
	assert_almost(float(budgets.get("tolerance", 0.0)), 0.03, 0.0001, "%3'e dek uyarı, üstü hata")
	var rows: Dictionary = budgets.get("rows", {})
	assert_eq(rows.keys().size(), 3)
	var camp: Dictionary = rows.get("camp", {})
	var expected := {
		"frame_ms_target": 16.7, "frame_ms_limit": 33.0, "script_ms": 3.0, "draw_calls_visible": 800.0,
		"draw_calls_shadow": 600.0, "triangles_visible": 3500000.0, "triangles_shadow": 2500000.0,
		"texture_mib": 256.0, "video_mib": 1024.0, "audio_mib": 26.0, "load_s": 2.0,
	}
	for key: String in expected:
		assert_almost(float(camp.get(key, -1.0)), float(expected[key]), 0.0001, "camp.%s" % key)
	for row_name in ["interior", "crowd"]:
		var row: Dictionary = rows.get(row_name, {})
		for key: String in expected:
			assert_true(row.has(key), "%s.%s eksik" % [row_name, key])
	assert_almost(float(rows["interior"]["frame_ms_limit"]), 28.0)
	assert_almost(float(rows["crowd"]["frame_ms_target"]), 20.0)
	assert_almost(float(rows["crowd"]["draw_calls_visible"]), 1000.0)
	var scene: Dictionary = budgets.get("scene", {})
	assert_almost(float(scene.get("positional_lights_shadowed", 0.0)), 4.0)
	assert_almost(float(scene.get("positional_lights", 0.0)), 32.0)
	assert_almost(float(scene.get("audio_players", 0.0)), 40.0)
	var reference: Dictionary = budgets.get("reference", {})
	assert_eq(str(reference.get("window", "")), "1920x1080")
	assert_almost(float(reference.get("warmup_frames", 0.0)), float(Probe.WARMUP_FRAMES))
	assert_almost(float(reference.get("measure_frames", 0.0)), float(Probe.MEASURE_FRAMES))


func test_baseline_is_complete() -> void:
	# Kampın taban ölçümü (data/budget_baseline.json) bütün pozlarla ve varsayılan ayarlarla alınmış olmalı:
	# menü karesi, 180 poz ve çimenin payı için 21 çimensiz eş; her sınanan pozda check_budget.py'nin alanları.
	var baseline := _json(BASELINE_PATH)
	if baseline.is_empty():
		return
	assert_eq(str(baseline.get("probe", "")), "camp")
	assert_eq(str(baseline.get("row", "")), "camp")
	var settings: Dictionary = baseline.get("settings", {})
	assert_almost(float(settings.get("warmup", 0.0)), float(Probe.WARMUP_FRAMES))
	assert_almost(float(settings.get("frames", 0.0)), float(Probe.MEASURE_FRAMES))
	assert_eq(str(settings.get("only", "x")), "", "Taban ölçümü süzgeçsiz alınır")
	var poses: Array = baseline.get("poses", [])
	assert_eq(poses.size(), 202, "Menü karesi ve çimensiz eşi + 200 poz")
	var ids := {}
	for pose: Dictionary in poses:
		ids[pose.get("id")] = true
		if not bool(pose.get("grass", true)):
			continue
		for field in CHECKED_FIELDS:
			assert_true(pose.has(field), "%s: %s eksik" % [pose.get("id"), field])
		# Doku belleği malzeme dokularının boyudur: motorun sarabilen sayacı (≈1,8e19 bayt) buraya girmemeli.
		assert_between(float(pose.get("texture_mib", -1.0)), 1.0, 4096.0, "%s: doku belleği" % pose.get("id"))
	for pose in Probe.build_poses(_points()):
		assert_true(ids.has(pose["id"]), "Tabanda %s yok" % pose["id"])
	assert_true(ids.has("menu") and ids.has("menu/nograss"), "Menü karesi ve çimensiz eşi ölçülmeli")
	var share: Dictionary = baseline.get("grass_share", {})
	assert_eq(int(share.get("pairs", 0)), 21, "Çimenin payı 21 eşten (menü + 20 poz) yazılır")
	var phases: Dictionary = baseline.get("textures", {}).get("phases", {})
	assert_true(phases.has("menu") and phases.has("play"), "Doku tahmini menüde ve Serbest Gez'de yazılmalı")


func test_texture_counter_wrap_is_rejected() -> void:
	# Motorun işaretsiz doku sayacı eksiye düşünce ≈1,8e19 bayt okunur: rapora boş yazılır, bütçeye girmez.
	assert_almost(float(Probe.counter_mib(134.0 * Probe.MIB)), 134.0)
	assert_null(Probe.counter_mib(17592186043658.1 * Probe.MIB), "Sarmış sayaç geçersizdir")
	assert_null(Probe.counter_mib(-1.0))
	assert_almost(float(Probe.counter_mib(0.0)), 0.0)


func _row(id: String, grass: bool, frame_ms: float, draws: float) -> Dictionary:
	return {
		"id": id, "grass": grass, "frame_ms": {"mean": frame_ms, "p95": frame_ms, "max": frame_ms},
		"draw_calls_visible": {"mean": draws, "p95": draws, "max": draws},
	}


func _json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		fail("%s yok" % path)
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		fail("%s okunamadı" % path)
		return {}
	return data


## Yola Çıkış takımı (--probe=depart): depart_yurt bir iç haritadır; 6 nokta × (4 yön × 28 ve 40 m + 14 m), eğim 38° (K98), noktalar yürünür alanda.
func test_depart_probe_measures_gameplay_framing() -> void:
	assert_eq(Probe.PROBES["depart"], "interior", "depart_yurt bir iç haritadır (K63)")
	var layout := DepartWorld.load_layout()
	var shape := OrdosGround.new(layout)
	var area: Dictionary = layout["walk_area"]
	var center := OrdosGround._vec2(area["center"])
	var points := {}
	for id in Probe.DEPART_POINTS:
		var at: Variant = (layout["markers"] as Dictionary).get(id)
		if at == null:
			# Yurdun yerli işareti (inside): yurdun ortası.
			at = (layout["places"] as Dictionary)["yanchi_yurt"]["at"]
		points[id] = OrdosGround._vec2(at)
	var poses := Probe.depart_poses(points)
	assert_eq(poses.size(), 54, "6 nokta × (4 yön × 28 ve 40 m + 14 m)")
	var ids := {}
	for pose in poses:
		ids[pose["id"]] = true
		assert_almost(float(pose["pitch"]), 38.0, 0.001, "K98: eğim 38°")
		assert_true(float(pose["distance"]) in [14.0, 28.0, 40.0], "K98: 14–40 m")
		assert_true(Vector2(float(pose["x"]), float(pose["z"])).distance_to(center) <= float(area["radius"]), "%s yürünür alanda" % pose["id"])
		var xform := Probe.camera_transform(shape, pose)
		assert_true(xform.origin.y >= shape.height_at(xform.origin.x, xform.origin.z) + Probe.GROUND_CLEARANCE - 0.001, "%s zemine gömülmez" % pose["id"])
	assert_eq(ids.size(), poses.size(), "Poz kimlikleri tekil")
