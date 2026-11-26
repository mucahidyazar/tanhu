extends TestCase
## «Çobanlık» ve Çocukluk'un günleri (E21, K110; story.md §5 «İki yeni gün»; docs/design/d3/e21-childhood-api.md):
##   - Günlerin sırası (ChildhoodDays): dört gün, adımı içeren gün, «gün:adım», sıradaki gün; «Çobanlık»ın verisi sorunsuz, sözleri e21-lines.json'un.
##   - Kamışlı Göl (OrdosGround): ağılın ≈350 m doğusunda, seviye bütün yüzlerde aynı; kumlu sığ kıyı, bel, yüzme, en derin bölge; ak taş yüzme
##     derinliğinde; kıyının dışında su yok. Ebe Obası ağılın ≈350 m kuzeyinde; bütün işaretler yürünür alanda.
##   - Yüzme bantları (ChildSwim): sığda yavaş yürüme, belde daha yavaş ve koşu yok, derinde yüzme (yay, binme, zıplama yok, E dalış), en derinde
##     akıntı geri iter.
##   - Sürünün sürülmesi (HerdSim DRIVEN): sürücü arkadayken sürü yolda ilerler ve hedefe varır, sürücüsüz otlar; sapan sürücü önüne geçince döner;
##     iki taşın arasından geçen koyun bir kez sayılır (balçıktaki kuzu sayılmaz: 39); eve dönüşte ağıla girerken sayılır, hepsi girince all_in.
##   - Işık: sabahtan geceye örnekler sıralı; sayım günü (08:40–11:00) bugünkü iki örnek arasında; akşamüstü dolunay doğuda.

const LAYOUT := "res://data/maps/childhood_ordos/layout.json"
const FLOCK := "res://data/story/childhood_days/day1_flock.json"
const DT := 1.0 / 60.0


class FlatShape:
	extends TerrainShape
	var level := 0.0

	func height_at(_x: float, _z: float) -> float:
		return level


## Sahte su: x'e göre derinleşen göl (x m'de derinlik x × 0,1; x > 20 en derin bölge).
class FakeWater:
	extends RefCounted

	func water_at(x: float, _z: float) -> Dictionary:
		return {"level": 0.0, "depth": maxf(x * 0.1, 0.0), "inside": x > 0.0, "inset": x, "deep": x > 20.0}


var _trash: Array[Node] = []


func after_each() -> void:
	for node in _trash:
		if is_instance_valid(node):
			node.queue_free()
	_trash.clear()


# --- Günler ------------------------------------------------------------------------------------------------

func test_days_play_in_order_and_resolve_steps() -> void:
	var days := ChildhoodDays.load_default()
	assert_eq(days.all_ids(), PackedStringArray(["day1_flock", "day1_bone", "day2_tally", "count"]), "Dört gün sırayla")
	assert_true(days.ids().has("day1_flock") and days.ids().has("count"), "Çobanlık ve sayım günü oynanır")
	assert_eq(days.resolve("", "count"), {"day": "count", "step": "count"}, "Sayım gününün adımı sayım gününü açar")
	assert_eq(days.resolve("", "wake"), {"day": "count", "step": "wake"}, "Bugünkü uyanış sayım günüdür")
	assert_eq(days.resolve("", "day1_flock:flock_lake"), {"day": "day1_flock", "step": "flock_lake"}, "gün:adım")
	assert_eq(str(days.resolve("", "")["day"]), "day1_flock", "Baştan: Çobanlık")
	assert_eq(str(days.resolve("day1_flock", "flock_noon")["step"]), "flock_noon")
	assert_false(days.carded("day1_bone"), "Ak Kemik aynı akşamdır: kart yok")
	assert_true(days.carded("day2_tally"))
	if days.ids().has("day1_bone"):
		assert_eq(days.next_of("day1_flock"), "day1_bone", "Çobanlık'tan sonra Ak Kemik")
	assert_eq(days.next_of("count"), "", "Sayım günü sondur")


func test_flock_day_data_is_complete() -> void:
	var d := ChildhoodScene.load_data(FLOCK)
	assert_eq(ChildhoodScene.validate(d), PackedStringArray(), "Veri sorunsuz")
	assert_eq(int(d["day_n"]), -5602, "20 Eylül MÖ 228")
	assert_eq(GameCalendar.format_tr(int(d["day_n"])), "20 Eylül MÖ 228")
	assert_eq(str((d["date"] as Dictionary)["tr"]), "20 Eylül MÖ 228 · Ordos", "Günün kartı")
	assert_eq(str((d["date"] as Dictionary)["en"]), "20 September 228 BC · Ordos")
	var kinds := PackedStringArray()
	for s: Dictionary in d["steps"]:
		assert_true(ChildhoodSteps.has(str(s["kind"]), s), "%s kayıtlı" % s["kind"])
		kinds.append(str(s["kind"]))
	assert_eq(kinds, PackedStringArray(["flock_wake", "flock_gate", "flock_drive", "flock_lake", "flock_stone", "flock_noon", "flock_count",
		"flock_lamb", "flock_home"]), "Çobanlık'ın dokuz adımı")
	# Sözler e21-lines.json'un (metne elle dokunulmaz) ve her adımın andığı satır dosyadadır.
	var lines: Dictionary = d["lines"]
	for key in ["wake", "back", "go", "stray_1", "stray_2", "lake", "swim_dare", "swim_deep", "stone_dare", "stone_got", "noon_1", "noon_4",
			"count_gate", "count_38", "count_39", "missing", "lamb_found", "fox", "fox_gone", "forty", "home_call", "home_count"]:
		assert_true(lines.has(key), "Söz: %s" % key)
	assert_eq(str((lines["home_count"] as Dictionary)["tr"]), "Kırk çıktı, kırk döndü.")
	var lines_path := ProjectSettings.globalize_path("res://").path_join("../docs/design/d3/e21-lines.json").simplify_path()
	if FileAccess.file_exists(lines_path):
		var src: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(lines_path))
		for l: Dictionary in src["lines"]:
			var id := str(l["id"])
			if id.begins_with("act0.flock."):
				var key := id.trim_prefix("act0.flock.")
				assert_true(lines.has(key), "e21-lines.json'un sözü günün dosyasında: %s" % key)
				if lines.has(key):
					assert_eq(str(lines[key]["tr"]), str(l["tr"]), "Metin aynı: %s" % key)
	for s: Dictionary in d["steps"]:
		var h := ChildhoodSteps.make(str(s["kind"]), null, s)
		for key: Variant in h.line_keys():
			assert_true(lines.has(str(key)), "%s: satır var: %s" % [s["id"], key])


func test_count_day_is_unchanged() -> void:
	var d := ChildhoodScene.load_data()
	assert_eq(ChildhoodScene.step_ids(d), PackedStringArray(["wake", "ride", "hunt", "count"]))
	assert_eq(int(d["day_n"]), -5600)
	assert_eq(str((d["clock"] as Dictionary)["start"]), "08:40")


# --- Kamışlı Göl ve Ebe Obası ------------------------------------------------------------------------------------

func test_lake_is_east_of_the_pen_with_its_bands() -> void:
	var layout := OrdosWorld.load_layout(LAYOUT)
	var d: Dictionary = layout["childhood"]
	var pen := OrdosGround._vec2(d["pen"]["at"])
	var m: Dictionary = d["markers"]
	var lake := OrdosGround._vec2(m["lake_center"])
	assert_between(lake.x - pen.x, 320.0, 380.0, "Göl ağılın ≈350 m doğusunda (%.0f m)" % (lake.x - pen.x))
	assert_true(absf(lake.y - pen.y) < 30.0, "Doğuda (kuzey-güney farkı küçük)")
	var ebe := OrdosGround._vec2(m["ebe_center"])
	assert_between(pen.y - ebe.y, 320.0, 380.0, "Ebe Obası ağılın ≈350 m kuzeyinde (%.0f m)" % (pen.y - ebe.y))
	# Göl Çocukluk'un yüzündedir (childhood.lake; merged_spec ekler); doğumun bozkırında yoktur.
	var plain := OrdosGround.new(ChildhoodSite.merged_spec(layout))
	var baked := ChildhoodSite.baked_spec(layout, {})
	var site_ground := OrdosGround.new(baked)
	assert_true(plain.lake_half_width > 0.0, "Çocukluk'un yüzünde göl var")
	assert_almost(plain.lake_level, site_ground.lake_level, 1e-6, "Su seviyesi Çocukluk'un yüzlerinde aynı")
	assert_eq(OrdosGround.new(OrdosWorld.steppe_spec(layout, {})).lake_half_width, 0.0, "Doğumun bozkırında göl yok")
	assert_eq(OrdosGround.new(layout).lake_half_width, 0.0, "Düzenin yalın yüzünde göl yok")
	var band := func(id: String) -> int:
		var p := OrdosGround._vec2(m[id])
		return ChildSwim.band_of(plain.lake_level - plain.height_at(p.x, p.y))
	assert_eq(band.call("lake_beach"), ChildSwim.Band.DRY, "Kumlu kıyı kuru")
	assert_eq(band.call("lake_shallow"), ChildSwim.Band.SHALLOW, "Sığ: dizden aşağı")
	assert_eq(band.call("lake_wade"), ChildSwim.Band.WADE, "Bel")
	assert_eq(band.call("lake_swim"), ChildSwim.Band.SWIM, "Yüzme")
	var core := float(layout["childhood"]["lake"]["deep_core"])
	var deepest := OrdosGround._vec2(m["lake_deepest"])
	assert_true(plain.lake_distance(deepest.x, deepest.y) < core, "En derin bölge orta çizgide")
	var stone := OrdosGround._vec2(m["white_stone"])
	assert_eq(band.call("white_stone"), ChildSwim.Band.SWIM, "Ak taş yüzme derinliğinde (dalışla alınır)")
	assert_true(plain.lake_distance(stone.x, stone.y) > core + 1.0, "Ak taş en derin bölgenin dışında")
	# Kıyının dışında su yok, kıyı sürekli (basamak yok).
	for row: Array in [[300.0, 25.0], [334.0, 52.0], [332.0, -43.0]]:
		assert_true(plain.height_at(float(row[0]), float(row[1])) > plain.lake_level, "Kuru yer suyun üstünde (%s)" % [row])
	var e := plain.lake_half_width
	var a := plain.lake_points[2]
	var edge_out := plain.height_at(a.x - e - 0.02, a.y)
	var edge_in := plain.height_at(a.x - e + 0.02, a.y)
	assert_true(absf(edge_out - edge_in) < 0.12, "Kıyıda basamak yok (%.3f)" % absf(edge_out - edge_in))
	var mud := OrdosGround._vec2(m["lake_mud"])
	assert_true(absf(plain.lake_level - plain.height_at(mud.x, mud.y)) < 0.5, "Balçık kıyının dibinde")


func test_every_marker_is_walkable_and_the_camera_holds_the_reaches() -> void:
	var layout := OrdosWorld.load_layout(LAYOUT)
	var d: Dictionary = layout["childhood"]
	for id: String in d["markers"]:
		assert_true(ChildhoodSite.in_walk_area(layout, OrdosGround._vec2(d["markers"][id]), 1.0), "%s yürünür alanda" % id)
	var bounds := ChildhoodSite.bounds_rect(d)
	for id in ["lake_center", "ebe_center", "lake_mud", "hereka_door"]:
		assert_true(bounds.has_point(OrdosGround._vec2(d["markers"][id])), "%s kameranın sınırında" % id)
	# Yürünür alanın birleşimi kampı göle ve obaya bağlar (yol boyunca kopukluk yok).
	var path: Array = []
	for t: Variant in d["ground"]["tracks"]:
		if t is Dictionary:
			path.append(t["points"])
	assert_true(path.size() >= 2, "Göle ve obaya giden yollar")
	for pts: Array in path:
		for i in range(1, pts.size()):
			var p0 := OrdosGround._vec2(pts[i - 1])
			var p1 := OrdosGround._vec2(pts[i])
			for k in 6:
				assert_true(ChildhoodSite.in_walk_area(layout, p0.lerp(p1, float(k) / 5.0)), "Yol yürünür alanda (%s)" % p0.lerp(p1, float(k) / 5.0))
	assert_eq(ChildhoodReaches.ebe_records(layout).size(), 3, "Ebe Obası'nın üç yurdu")
	assert_eq(ChildhoodReaches.ebe_walls(layout).size(), 1, "Hereka'nın yurdu açık (kapıdan girilir)")


# --- Yüzme -------------------------------------------------------------------------------------------------

func test_swim_bands_slow_the_child_and_block_run_ride_bow_jump() -> void:
	assert_eq(ChildSwim.band_of(0.0), ChildSwim.Band.DRY)
	assert_eq(ChildSwim.band_of(0.2), ChildSwim.Band.SHALLOW)
	assert_eq(ChildSwim.band_of(0.45), ChildSwim.Band.WADE)
	assert_eq(ChildSwim.band_of(0.9), ChildSwim.Band.SWIM)
	var player := await _make_child()
	var water := FakeWater.new()
	var swim := ChildSwim.new()
	swim.setup(player, Callable(water, &"water_at"))
	player.add_child(swim)
	player.swim = swim
	swim.set_process(false)
	var speeds := {}
	for row: Array in [[-5.0, "dry"], [2.0, "shallow"], [4.5, "wade"], [12.0, "swim"]]:
		player.spawn_at(Vector3(float(row[0]), 0.0, 0.0), 0.0)
		swim._process(DT)
		for i in 90:
			# W kuzeye (−z) yürütür: sahte suyun derinliği yalnız x'e bağlıdır, bant değişmez.
			player.step(DT, Vector2(0.0, 1.0), true, 0.0)
			swim._process(DT)
		speeds[row[1]] = player.get_speed()
	assert_almost(float(speeds["dry"]), player.run_speed, 0.05, "Kuruda koşar")
	assert_true(float(speeds["shallow"]) < player.run_speed * 0.8, "Sığda yavaş (%.2f)" % speeds["shallow"])
	assert_true(float(speeds["wade"]) <= player.walk_speed * ChildSwim.WADE_K + 0.05, "Belde koşu yok, daha yavaş (%.2f)" % speeds["wade"])
	assert_almost(float(speeds["swim"]), ChildSwim.SWIM_SPEED, 0.08, "Yüzme yavaş (%.2f)" % speeds["swim"])
	assert_true(swim.is_swimming())
	assert_false(player.jump(), "Yüzerken zıplanmaz")
	assert_false(player.begin_aim(), "Yüzerken yay yok")
	assert_null(player.mount_in_reach(), "Yüzerken binilmez")
	assert_true(swim.can_dive(), "Derinde E dalış")
	assert_eq(player.prompt_pairs(), [["E", "Dal"]], "İpucu: dal")
	assert_true(player.interact(), "E dalar")
	assert_true(swim.diving)
	for i in int(ChildSwim.DIVE_S / DT) + 4:
		swim._process(DT)
	assert_false(swim.diving, "Dalış 1,5 sn sürer")
	# En derin bölge: akıntı geri iter (sürüklenme kıyıya doğru, eksi x).
	player.spawn_at(Vector3(24.0, 0.0, 0.0), 0.0)
	var pushed := [false]
	swim.pushed_back.connect(func() -> void: pushed[0] = true)
	swim._process(DT)
	assert_true(pushed[0], "En derinde akıntı uyarır")
	# Sahte suyun eğimi yok (shape OrdosGround değil): sürüklenme yönü ölçülemez; yalnız sinyal sınanır.
	# Sudan çıkınca ıslak görünüş.
	player.spawn_at(Vector3(-5.0, 0.0, 0.0), 0.0)
	swim._process(DT)
	assert_true(swim.wet > 0.9, "Sudan çıkınca ıslak")
	for i in int(ChildSwim.WET_S / 0.25) + 2:
		swim._process(0.25)
	assert_almost(swim.wet, 0.0, 0.01, "Kurur")
	swim.dry_now()


# --- Sürü -------------------------------------------------------------------------------------------------

func test_driven_flock_reaches_the_lake_and_idles_without_a_driver() -> void:
	var sim := _sim()
	sim.place_on_meadow(Vector2(36.0, 30.0), 8.0)
	var path := _path(["flock_gather", "flock_way_1", "flock_way_2", "flock_way_3", "lake_view"])
	sim.drive_along(path, 12.0)
	# Sürücüsüz: sürü yerinde otlar.
	var start := sim.flock_center()
	for i in 80:
		sim.step()
	assert_true(sim.flock_center().distance_to(start) < 4.0, "Sürücüsüz sürü yolda ilerlemez")
	var arrived := false
	var fastest := 0.0
	var ticks := 0
	while ticks < 1600 and not arrived:
		_drive_from_behind(sim)
		sim.step()
		ticks += 1
		for i in sim.count:
			fastest = maxf(fastest, sim.vel[i].length())
		for ev: Dictionary in sim.events:
			if ev["type"] == &"arrived":
				arrived = true
	assert_true(arrived, "Arkadan sürülen sürü göle varır")
	var seconds := float(ticks) * HerdSim.TICK
	assert_between(seconds, 60.0, 160.0, "≈260 m yol 1–2,5 dakikada (%.0f sn)" % seconds)
	assert_true(fastest <= sim.drive_max + PlayerController.CHILD_RUN_SPEED * 0.4, "Koyun koşmaz, tırısta kalır (%.2f m/sn)" % fastest)
	assert_true(sim.flock_spread() < 16.0, "Sürü dağılmaz (%.1f m)" % sim.flock_spread())


func test_strays_turn_back_when_headed_off() -> void:
	var sim := _sim()
	sim.place_on_meadow(Vector2(120.0, 28.0), 7.0)
	sim.drive_along(_path(["flock_way_1", "flock_way_2", "flock_way_3"]), 10.0)
	var gone := sim.stray(1.0, 3, 26.0)
	assert_eq(gone.size(), 3, "Üç koyun sağa sapar")
	var c0 := sim.flock_center()
	for i in 60:
		sim.step()
	for i in gone:
		assert_true(sim.pos[i].distance_to(sim.flock_center()) > c0.distance_to(sim.flock_center()) + 6.0, "Sapan uzaklaşır")
	var back := 0
	for t in 600:
		var strays := sim.stray_positions()
		if strays.is_empty():
			break
		var s := strays[0]
		var c := sim.flock_center()
		var out := (s - c).normalized()
		# Çocuk sapanın dışına geçer (önüne).
		sim.drivers = [Vector3(s.x + out.x * 3.0, s.y + out.y * 3.0, 7.5)]
		sim.step()
		for ev: Dictionary in sim.events:
			if ev["type"] == &"stray_back":
				back += 1
	assert_eq(back, 3, "Önüne geçilen sapan sürüye döner")
	assert_eq(sim.stray_count(), 0)


func test_count_gate_counts_each_sheep_once_and_the_lamb_is_missing() -> void:
	var layout := OrdosWorld.load_layout(LAYOUT)
	var m: Dictionary = layout["childhood"]["markers"]
	var sim := _sim()
	sim.place_on_meadow(OrdosGround._vec2(m["lake_graze"]), 10.0)
	var lamb := sim.smallest()
	sim.take_out(lamb)
	assert_eq(sim.visible_count(), 39, "Kuzu sazlıkta: 39")
	var a := OrdosGround._vec2(m["count_stone_a"])
	var b := OrdosGround._vec2(m["count_stone_b"])
	var dir := (b - a).normalized()
	sim.drive_along(_path(["lake_graze", [330.0, 31.0], "count_gate", "count_after"]), 5.0)
	sim.corridor = 3.0
	sim.count_through(a - dir * 2.2, b + dir * 2.2)
	var counted := {}
	for t in 1200:
		_drive_from_behind(sim)
		sim.step()
		for ev: Dictionary in sim.events:
			if ev["type"] == &"gate_counted":
				assert_false(counted.has(ev["index"]), "Koyun bir kez sayılır")
				counted[ev["index"]] = true
		if sim.gate_tally >= 39:
			break
	assert_eq(sim.gate_tally, 39, "Otuz dokuz (biri eksik)")
	assert_false(counted.has(lamb), "Balçıktaki kuzu sayılmaz")
	sim.put_back(lamb, sim.flock_center())
	assert_eq(sim.visible_count(), 40, "Kuzu döner: kırk")


func test_flock_stops_at_the_path_end_and_the_counter_counts_the_rest() -> void:
	# Sürücü arkadan itmeyi sürdürse de sürü yolun sonunu geçip gitmez (yolun sonundaki koyun ileri itilmez); taşların dışından geçen ya da
	# geride kalan koyunu sayıcı sayar (count_gate_one), sayım hep biter.
	var layout := OrdosWorld.load_layout(LAYOUT)
	var m: Dictionary = layout["childhood"]["markers"]
	var sim := _sim()
	sim.place_on_meadow(OrdosGround._vec2(m["lake_graze"]), 10.0)
	var a := OrdosGround._vec2(m["count_stone_a"])
	var b := OrdosGround._vec2(m["count_stone_b"])
	var dir := (b - a).normalized()
	var goal := OrdosGround._vec2(m["count_after"])
	sim.drive_along(_path(["lake_graze", [330.0, 31.0], "count_gate", "count_after"]), 5.0)
	sim.corridor = 3.0
	sim.count_through(a - dir * 2.2, b + dir * 2.2)
	var arrived := false
	for t in 1600:
		_drive_from_behind(sim)
		sim.step()
		for ev: Dictionary in sim.events:
			arrived = arrived or ev["type"] == &"arrived"
		if arrived:
			break
	assert_true(arrived, "Sürü yolun sonuna varır")
	# Varınca sürücü bırakır (FlockCount): sürü yolun sonunda durur, otlar; ileri itilmez.
	sim.drivers = []
	for t in 240:
		sim.step()
	var c := sim.flock_center()
	assert_true(c.distance_to(goal) < 16.0, "Sürü yolun sonunda durur (%.1f m)" % c.distance_to(goal))
	assert_true(c.x > goal.x - 16.0, "Batıya, kampa doğru sürüklenmez (x %.1f)" % c.x)
	var guard := 0
	while sim.gate_left() > 0 and guard < 60:
		assert_true(sim.count_gate_one() >= 0, "Geride kalan sayılır")
		guard += 1
	assert_eq(sim.gate_tally, sim.visible_count(), "Sayım biter: hepsi sayıldı")
	assert_eq(sim.count_gate_one(), -1, "Sayılacak kalmadı")


func test_home_drive_pens_and_counts_all_forty() -> void:
	var sim := _sim()
	sim.place_on_meadow(Vector2(60.0, 30.0), 7.0)
	sim.drive_along(_path(["flock_way_1", [44.0, 30.0], [27.0, 26.0]]), 6.0)
	sim.home_to_pen()
	var all_in := false
	for t in 1600:
		_drive_from_behind(sim)
		sim.step()
		for ev: Dictionary in sim.events:
			if ev["type"] == &"all_in":
				all_in = true
		if all_in:
			break
	assert_true(all_in, "Hepsi ağıla girer")
	assert_eq(sim.pen_tally, 40, "Girerken sayılır: kırk")
	for t in 80:
		sim.step()
	sim.settle_in_pen()
	for t in 60:
		sim.step()
	var inside := 0
	for i in sim.count:
		if sim.pos[i].distance_to(sim.pen_center) < sim.pen_radius:
			inside += 1
	assert_true(inside >= 38, "Koyunlar ağılda (%d)" % inside)


# --- Işık ---------------------------------------------------------------------------------------------------

func test_light_runs_from_dew_to_moon_and_keeps_the_count_day() -> void:
	var samples := SkyRig.load_samples(OrdosWorld.CHILDHOOD_LIGHT)
	var minutes: Array = []
	for s: Dictionary in samples.values():
		minutes.append(float(s["minute"]))
	minutes.sort()
	assert_eq(minutes[0], 420.0, "Şafak çiyi 07:00")
	assert_eq(minutes[minutes.size() - 1], 1230.0, "Ay gecesi 20:30")
	var pair := OrdosWorld.sample_pair(samples, 590.0)
	assert_eq(str((pair[0] as Dictionary)["id"]), "morning", "Sayım günü: sabah ile geç sabah arası")
	assert_eq(str((pair[1] as Dictionary)["id"]), "late")
	assert_almost(float(pair[2]), 0.5, 0.001)
	var golden := OrdosWorld.blend_samples(samples["golden"], samples["sunset"], 0.5, 1025.0)
	var dusk: Dictionary = samples["dusk"]
	assert_true(float((golden["sun"] as Dictionary)["el"]) < 20.0, "İkindi: güneş alçak")
	assert_true(dusk.has("moon"), "Akşamüstü ay hesaplanır")
	if dusk.has("moon"):
		var moon: Dictionary = dusk["moon"]
		assert_true(float(moon["el"]) > 5.0, "18:25'te dolunay doğuda yükselmiş (%.1f°)" % float(moon["el"]))
		assert_between(float(moon["az"]), 70.0, 130.0, "Ay doğuda")


# --- Yardımcılar -------------------------------------------------------------------------------------------

func _sim() -> HerdSim:
	var layout := OrdosWorld.load_layout(LAYOUT)
	var sim := HerdSim.new(layout["childhood"], {"walk": 1.1, "trot": 2.5})
	sim.obstacles = ChildhoodSite.collision_circles(layout, true)
	return sim


func _path(ids: Array) -> PackedVector2Array:
	var m: Dictionary = OrdosWorld.load_layout(LAYOUT)["childhood"]["markers"]
	var out := PackedVector2Array()
	for id: Variant in ids:
		out.append(OrdosGround._vec2(m[id]) if id is String else OrdosGround._vec2(id))
	return out


## Çocuk en gerideki koyunun arkasında (botun yolu).
func _drive_from_behind(sim: HerdSim) -> void:
	var c := sim.flock_center()
	var fwd := sim.path_tangent(c)
	var rear := sim.rear_sheep(fwd) - fwd * 2.6
	sim.drivers = [Vector3(rear.x, rear.y, 7.5)]


func _make_child() -> PlayerController:
	var player := PlayerController.new()
	player.terrain_shape = FlatShape.new()
	player.start_active = false
	var avatar := CharacterAvatar.new()
	avatar.use_meshy_models = false
	player.add_child(avatar)
	add_child(player)
	_trash.append(player)
	player.set_process(false)
	await wait_frames(1)
	player.obstacles = []
	player.use_child(ChildLook.PERSON_METE)
	return player
