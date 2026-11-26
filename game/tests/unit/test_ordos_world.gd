extends TestCase
## childhood_ordos (scenes/maps/childhood_ordos.tscn; OrdosWorld, OrdosGround, HearthEmbers): Önsöz'ün doğumunun
## dünyası (godot.md §3.6, §4.3; story.md §4).
##
## Dünya dosya başına bir kez, oyundaki gibi kurulur: ResourceLoader.load_threaded_request → THREAD_LOAD_LOADED →
## örnekleme (süresi ölçülür) → ağaca ekleme → iş parçacığı işleri ve kare bütçeli kurulum → is_ready(). Kurulum
## sürerken konsola yazılan her hata testi düşürür (koşucunun günlükçüsü). Son sahne testi dünyayı bırakır ve düğüm ve
## önbellek sızıntısını sınar. Doğumun bozkırı (kademe, maskeli zemin, kaya, çalı, çakıl, ot) dünyayla kurulur; Çocukluk'a özgü
## olanlar (ağıl, sürü, küçük av, yarış taşı ve yolu, sayım hattının bezleri, kampın eşyaları, izler) yoktur.

const SCENE := "res://scenes/maps/childhood_ordos.tscn"
const LAYOUT := "res://data/maps/childhood_ordos/layout.json"
const USAGE := "res://assets/_free/usage.jsonl"
const BATCH := "G1-ordos-ve-isik"
## Kurulumun en uzun bekleyişi (saniye).
const READY_TIMEOUT := 90.0
## Bir kare (60 FPS), milisaniye: örnekleme takılması en çok bir kare (godot.md §3.6, plan birth-world).
const FRAME_MS := 1000.0 / 60.0
## Titremenin sınırları (Campfire.flicker).
const FLICKER_LOW := 0.72
const FLICKER_HIGH := 1.18
## İç harita bütçesi (K63; godot.md §7.2): görünür çizim ≤900, gölge çizimi ≤500.
const VISIBLE_DRAWS := 900
const SHADOW_DRAWS := 500
## Yönlü ışığın gölge bölümü (SunLight: PARALLEL_2_SPLITS) ve noktasal ışığın küp yüzü sayısı.
const SHADOW_SPLITS := 2
const OMNI_FACES := 6
## Ücretsiz varlıkların düğümleri: yol → FREE_ASSETS.json kimliği (bozkırın zemini üç dokuyu metre ölçeğinde okur: işareti dizidir, kaydı
## withered_grass'ındır).
const FREE_NODES := {
	"Ground/Terrain": "withered_grass",
	"Ground/Trampled": "dry_ground_rocks",
	"Places/LanYurt/Floor": "dirt",
	"Places/LanYurt/Hearth/Ash": "burned_ground_01",
	"WorldEnvironment": "qwantani_sunrise_puresky",
}

var _world: OrdosWorld
## Yükleme ölçüleri: status, load_frames, instantiate_ms, add_ms, ready_at_add, ready_frames.
var _load := {}
## Dünya kurulmadan önceki düğüm ve öksüz düğüm sayısı (sızıntı sınaması).
var _baseline_nodes := -1
var _baseline_orphans := -1


# --- Kurulum ve yükleme ------------------------------------------------------------------------------

func test_scene_builds_without_errors() -> void:
	var world := await _get_world()
	assert_not_null(world, "Dünya kurulmalı")
	if world:
		assert_true(world.is_ready(), "Dünya %.0f sn içinde hazır olmalı" % READY_TIMEOUT)
		for path in ["WorldEnvironment", "SunLight", "SkyRig", "Ground/Terrain", "Ground/Trampled", "Ground/Grass",
				"River", "Places/LanYurt", "Places/TeomanOtag", "Places/LanYurt/Hearth", "Places/CountingLine/Stakes",
				"Places/CountingLine/Rope", "Markers/Cradle", "Markers/Burial", "Markers/Counter", "Cameras/InsideHearth"]:
			assert_not_null(world.get_node_or_null(NodePath(path)), "Eksik düğüm: %s" % path)


func test_loads_in_the_background_and_records_instantiation() -> void:
	var world := await _get_world()
	if world == null:
		return
	assert_eq(int(_load.get("status", -1)), ResourceLoader.THREAD_LOAD_LOADED, "Arka plan yüklemesi THREAD_LOAD_LOADED'a varmalı")
	assert_true(int(_load.get("load_frames", 0)) >= 1, "Yükleme kare kare sorulmalı (load_threaded_get_status)")
	assert_true(_load.has("instantiate_ms"), "Örnekleme süresi kaydedilmeli")
	var inst := float(_load.get("instantiate_ms", INF))
	var add := float(_load.get("add_ms", INF))
	print("    [ordos] soğuk kurulum: yükleme %d kare; örnekleme %.2f ms, ağaca ekleme %.2f ms; en uzun kare %.2f ms (%d kare), hazır %.0f ms; iş parçacığı %s; adımlar %s"
		% [_load["load_frames"], inst, add, world.build_stats["max_frame_ms"], world.build_stats["frames"], world.build_stats["ready_ms"],
			world.build_stats["jobs_ms"], world.build_stats["steps"]])
	assert_true(inst + add <= FRAME_MS, "Örnekleme ve ağaca ekleme bir kareyi aşmamalı (%.2f ms)" % (inst + add))
	# Kare takılması: oyunda kamp önce kurulduğundan ortak betikler ve önbellekler ısınmıştır; ölçü ısınmış ikinci
	# kurulumda alınır. Aynı makinede koşan başka işlerin sıçramasını ayıklamak için en çok üç kurulumun en iyisi.
	var best := INF
	for attempt in 3:
		var stats := await _build_extra_world()
		if stats.is_empty():
			fail("Ek dünya kurulamadı")
			return
		print("    [ordos] ılık kurulum %d: örnekleme+ekleme %.2f ms, en uzun kare %.2f ms (%d kare), hazır %.0f ms"
			% [attempt + 1, float(stats["add_ms"]), float(stats["max_frame_ms"]), int(stats["frames"]), float(stats["ready_ms"])])
		best = minf(best, maxf(float(stats["max_frame_ms"]), float(stats["add_ms"])))
		if best <= FRAME_MS:
			break
	assert_true(best <= FRAME_MS, "Kurulumun her karesi bir kareyi aşmamalı (en iyi kurulumda en uzun %.2f ms)" % best)


func test_is_ready_only_after_the_worker_jobs() -> void:
	var world := await _get_world()
	if world == null:
		return
	assert_false(bool(_load.get("ready_at_add", true)), "Ağaca eklendiği an hazır olmamalı: ağır üretim iş parçacığında sürer")
	assert_true(int(world.build_stats["frames"]) > 1, "Kurulum karelere bölünmeli")
	var jobs: Dictionary = world.build_stats["jobs_ms"]
	for kind in ["bake", "ground", "grass", "scatter"]:
		assert_true(jobs.has(kind), "%s işi WorkerThreadPool'da koşmalı" % kind)
	var terrain := world.get_node_or_null(^"Ground/Terrain") as MeshInstance3D
	assert_true(terrain != null and terrain.mesh != null and terrain.mesh.get_surface_count() == 1, "Zemin ağı kurulmalı")
	var tufts := 0
	for mmi in world.find_children("Grass_*", "MultiMeshInstance3D", true, false):
		tufts += (mmi as MultiMeshInstance3D).multimesh.instance_count
	assert_true(tufts > 4000, "Sarı ot kurulmalı (%d tutam)" % tufts)


# --- Yerler -----------------------------------------------------------------------------------------

func test_yurt_doors_face_east() -> void:
	# Kapı doğuya (+X) bakar (story.md §4; layout'ta bütün kapılar doğu).
	var world := await _get_world()
	if world == null:
		return
	for id in ["lan_yurt", "teoman_otag"]:
		var yurt := world.place(id) as Yurt
		assert_not_null(yurt, "%s kurulmalı" % id)
		if yurt:
			var door := yurt.global_basis.z.normalized()
			assert_vec_almost(door, Vector3.RIGHT, 0.001, "%s kapısı doğuya bakmalı" % id)
			assert_almost(yurt.global_position.y, world.ground.height_at(yurt.global_position.x, yurt.global_position.z), 0.001, "%s zemine oturmalı" % id)
	assert_true(world.place("lan_yurt") is OrdosWorld.BirthYurt, "Lan Hatun'un yurdu doğum yurdu olmalı (içi gerçek)")
	assert_true(world.place("teoman_otag").radius > world.place("lan_yurt").radius, "Otağ büyük yurttur")
	var door := world.marker("lan_door")
	assert_true(door.x > world.place("lan_yurt").global_position.x, "Kapının işareti yurdun doğusunda")


func test_birth_yurt_has_a_real_interior() -> void:
	# İç: kerege, keçe, kase, toprak taban; sahte kapı parıltısı ve kapı dibindeki küçük ocak yok, içeriyi köz aydınlatır.
	var world := await _get_world()
	if world == null:
		return
	var yurt := world.place("lan_yurt")
	for part in ["Floor", "FeltTor", "FeltBed", "FeltSouth", "Bowl", "DoorSpill", "Hearth"]:
		assert_not_null(yurt.get_node_or_null(NodePath(part)), "Doğum yurdunda %s olmalı" % part)
	assert_null(yurt.get_node_or_null(^"DoorGlow"), "Sahte kapı parıltısı olmamalı: içi gerçek")
	assert_null(yurt.get_node_or_null(^"InteriorLight"), "İçeriyi köz ışığı aydınlatır, ayrı iç ışık yok")
	assert_eq(yurt.find_children("HearthFlame*", "", false, false).size(), 0, "Kapı dibinde küçük ocak olmamalı")
	if (yurt as Yurt).uses_model():
		var lining := yurt.get_node_or_null(^"Lining")
		assert_not_null(lining, "Meshy yurdunun içi kerege astarlı olmalı")
		if lining:
			var wall := lining.get_node_or_null(^"Wall") as MeshInstance3D
			assert_true(wall and (wall.material_override as ShaderMaterial).shader.resource_path == "res://shaders/kerege.gdshader", "Duvar astarı kerege")


func test_hearth_sits_inside_the_yurt_and_its_embers_flicker() -> void:
	var world := await _get_world()
	if world == null:
		return
	var yurt := world.place("lan_yurt") as Yurt
	var hearth := world.hearth()
	assert_not_null(hearth, "Ocak kurulmalı")
	if hearth == null or yurt == null:
		return
	var off := Vector2(hearth.global_position.x - yurt.global_position.x, hearth.global_position.z - yurt.global_position.z)
	assert_true(off.length() < yurt.radius * 0.3, "Ocak yurdun ortasında olmalı (%.2f m)" % off.length())
	for stone in HearthEmbers.STONE_NAMES:
		assert_not_null(hearth.get_node_or_null(NodePath(stone)), "Üç ocak taşı: %s" % stone)
	var door_stone := hearth.door_stone_position() - hearth.global_position
	assert_true(door_stone.x > 0.2, "Eşik taşı kapıya (doğuya) bakar")
	var light := hearth.get_node_or_null(^"EmberLight") as OmniLight3D
	assert_not_null(light, "Köz ışığı (OmniLight3D) kurulmalı")
	if light:
		assert_true(light.shadow_enabled, "Köz ışığı gölgeli (kişilerin gölgesi keregeye düşer)")
		assert_true(light.omni_range < yurt.radius * 2.0, "Köz ışığı yurdun içinde kalır")
	# Saf titreme sınırı ve sahnedeki ışığın titremesi.
	for i in 6000:
		assert_between(HearthEmbers.ember_flicker(float(i) * 0.0173, 11.0), FLICKER_LOW, FLICKER_HIGH, "Titreme sınırı (t = %d)" % i)
		if failures.size() > 0:
			break
	var lowest := INF
	var highest := -INF
	for i in 8:
		await get_tree().create_timer(0.06).timeout
		lowest = minf(lowest, hearth.flicker_factor())
		highest = maxf(highest, hearth.flicker_factor())
	assert_between(lowest, FLICKER_LOW, FLICKER_HIGH, "Köz ışığının en düşüğü")
	assert_between(highest, FLICKER_LOW, FLICKER_HIGH, "Köz ışığının en yükseği")
	assert_true(highest - lowest > 0.005, "Köz ışığı titremeli (%.3f – %.3f)" % [lowest, highest])


func test_markers_sit_on_the_ground_where_the_layout_puts_them() -> void:
	var world := await _get_world()
	if world == null:
		return
	var layout := OrdosWorld.load_layout(LAYOUT)
	var markers: Dictionary = layout["markers"]
	for id in ["counter", "cradle", "burial", "line_north", "line_south"]:
		assert_true(markers.has(id), "layout'ta %s işareti olmalı" % id)
	for id: String in markers:
		var at: Array = markers[id]
		var p := world.marker(id)
		assert_almost(p.x, float(at[0]), 0.0001, "%s x layout'taki yerde" % id)
		assert_almost(p.z, float(at[1]), 0.0001, "%s z layout'taki yerde" % id)
		assert_almost(p.y, world.ground.height_at(p.x, p.z), 0.0001, "%s zemine oturmalı" % id)
	# Sayım hattı: kazıklar from'dan to'ya, zeminde.
	var line: Dictionary = layout["counting_line"]
	var stakes := world.counting_line_stakes()
	assert_eq(stakes.size(), int(line["stakes"]), "Kazık sayısı")
	var a := Vector2(float(line["from"][0]), float(line["from"][1]))
	var b := Vector2(float(line["to"][0]), float(line["to"][1]))
	for s in stakes:
		var q := Vector2(s.x, s.z)
		assert_true(Geometry2D.get_closest_point_to_segment(q, a, b).distance_to(q) < 0.001, "Kazık hattın üstünde")
		assert_almost(s.y, world.ground.height_at(s.x, s.z), 0.0001, "Kazık zemine oturmalı")
	# Beşik ve gömü yeri yurdun dışında, yurda yakın ve otsuz (çiğnenmiş) toprakta.
	var yurt := world.place("lan_yurt") as Yurt
	for id in ["cradle", "burial"]:
		var p := world.marker(id)
		var d := Vector2(p.x - yurt.global_position.x, p.z - yurt.global_position.z).length()
		assert_between(d, yurt.radius + 0.4, yurt.radius + 3.0, "%s yurdun yanında" % id)
		assert_true(world.ground.trampled_weight(Vector2(p.x, p.z)) > 0.5, "%s otsuz toprakta" % id)
	var counter := world.marker("counter")
	var door := world.marker("lan_door")
	assert_between(Vector2(counter.x - door.x, counter.z - door.z).length(), 15.0, 45.0, "Hereka kapıdan sayım hattına seslenebilir")


func test_ground_height_is_finite_and_shaped() -> void:
	var world := await _get_world()
	if world == null:
		return
	var g := world.ground
	var bad := 0
	for ix in range(-81, 82):
		for iz in range(-81, 82):
			var x := float(ix) * 37.0 + 0.3
			var z := float(iz) * 37.0 - 0.7
			var h := g.height_at(x, z)
			if not is_finite(h) or not g.normal_at(x, z).is_finite():
				bad += 1
	assert_eq(bad, 0, "height_at ve normal_at her yerde sonlu olmalı")
	assert_true(is_finite(g.height_at(0.0, 0.0)) and is_finite(g.height_at(1.0e5, -1.0e5)), "Uzakta da sonlu")
	# Harita içi alçak dalgalıdır; yurtların altı düzdür.
	var lo := INF
	var hi := -INF
	for ix in range(-55, 56, 5):
		for iz in range(-40, 41, 5):
			var h := g.height_at(float(ix) * 2.0, float(iz) * 2.0)
			lo = minf(lo, h)
			hi = maxf(hi, h)
	assert_true(hi - lo < 3.0, "Harita içi alçak dalgalı (%.2f m fark)" % (hi - lo))
	for id in ["lan_yurt", "teoman_otag"]:
		var yurt := world.place(id) as Yurt
		var c := Vector2(yurt.global_position.x, yurt.global_position.z)
		var spread := 0.0
		for k in 24:
			var p := c + Vector2.from_angle(TAU * float(k) / 24.0) * yurt.radius
			spread = maxf(spread, absf(g.height_at(p.x, p.y) - yurt.global_position.y))
		assert_true(spread < 0.01, "%s düz yerde durmalı (%.3f m)" % [id, spread])
	assert_true(g.height_at(g.river_x, 0.0) < g.water_level, "Irmağın ortası suyun altında")
	assert_true(g.height_at(g.river_x + g.river_width, 0.0) > g.water_level, "Irmağın kıyısı suyun üstünde")


## Doğumun bozkırı (MÖ 234 ile MÖ 228 aynı otlak; K98'in uzak ve yüksek kadrajından okunur): kademe, tepe, dere, maskeli zemin, kaya, çalı,
## çakıl ve ot dünyayla kurulur; yükselti doğumun yerlerini oynatmaz; kaya ve çalı Çocukluk'unkilerle aynı yerdedir; çiğnenmiş toprak maskede
## dokulu açık topraktır, Çocukluk'un izleri (yarış yolu) maskede yoktur. Çocukluk'a özgü olanlar (ağıl, sürü, binilen koyunlar, küçük av,
## yarış taşı, sayım hattının bezleri, kampın eşyaları) doğumun dünyasında yoktur.
func test_birth_sees_the_steppe_but_nothing_of_the_childhood() -> void:
	var world := await _get_world()
	if world == null:
		return
	var steppe := world.steppe
	assert_not_null(steppe, "Bozkırın yüzü pişer")
	if steppe == null:
		return
	assert_eq(world.get_terrain_shape(), steppe, "Görünen zeminin yüzü bozkırınki")
	var layout := OrdosWorld.load_layout(LAYOUT)
	# Yükselti doğumun yerlerini oynatmaz: yurtların çevresi, işaretler, kazıklar.
	var spots: Array[Vector2] = []
	for id: String in layout["places"]:
		var at := OrdosGround._vec2(layout["places"][id]["at"])
		spots.append(at)
		for k in 12:
			spots.append(at + Vector2.from_angle(TAU * float(k) / 12.0) * (float(layout["places"][id]["radius"]) + 1.5))
	for id: String in layout["markers"]:
		spots.append(OrdosGround._vec2(layout["markers"][id]))
	for s in world.counting_line_stakes():
		spots.append(Vector2(s.x, s.z))
	for p in spots:
		assert_almost(steppe.height_at(p.x, p.y), world.ground.height_at(p.x, p.y), 0.005, "Doğumun yeri oynamaz (%s)" % p)
	var hill: Array = layout["childhood"]["ground"]["hills"][1]
	assert_true(steppe.height_at(float(hill[0]), float(hill[1])) - world.ground.height_at(float(hill[0]), float(hill[1])) > 1.5, "Tepe yükselir")
	var gully := OrdosGround._vec2(layout["childhood"]["ground"]["gullies"][0]["points"][3])
	assert_true(steppe.height_at(gully.x, gully.y) - world.ground.height_at(gully.x, gully.y) < -0.3, "Dere çukurdur")
	# Zemin: bozkırın maskeli gölgelendiricisi; üst katmanın ağı yok, çiğnenmiş toprak maskede açık topraktır, ot orada çıkmaz.
	var terrain := world.get_node(^"Ground/Terrain") as MeshInstance3D
	var mat := terrain.material_override as ShaderMaterial
	assert_eq(mat.shader, OrdosWorld.STEPPE_SHADER, "Bozkırın gölgelendiricisi")
	assert_true(mat.get_shader_parameter(&"mask_tex") is Texture2D, "Zeminin maskesi")
	var layer := world.get_node(^"Ground/Trampled") as MeshInstance3D
	assert_eq(layer.mesh.get_surface_count(), 0, "Üst katman çizilmez")
	assert_eq(int((layer.material_override as ShaderMaterial).get_shader_parameter(&"trampled_circle_count")), 6, "Katmanın bölgeleri doğumun")
	var birth_mask: Dictionary = world.baked.get("mask_birth", {})
	var child_mask: Dictionary = world.baked.get("mask", {})
	assert_false(birth_mask.is_empty(), "Doğumun maskesi pişer")
	if birth_mask.is_empty():
		return
	for c: Array in layout["trampled"]["circles"]:
		assert_true(ChildhoodGround.mask_at(birth_mask, float(c[0]), float(c[1])).x > 0.8, "Çiğnenmiş toprak açık toprak (%s)" % [c])
	var race: Array = layout["childhood"]["race"]["path"]
	var birth_bare := 0.0
	var child_bare := 0.0
	var samples := 0
	for i in range(1, race.size()):
		for k in 10:
			var q := OrdosGround._vec2(race[i - 1]).lerp(OrdosGround._vec2(race[i]), (float(k) + 0.5) / 10.0)
			birth_bare += ChildhoodGround.mask_at(birth_mask, q.x, q.y).x
			child_bare += ChildhoodGround.mask_at(child_mask, q.x, q.y).x
			samples += 1
	assert_true(birth_bare / samples < child_bare / samples - 0.2, "Yarış yolu doğumun maskesinde yok (%.2f, Çocukluk %.2f)" % [birth_bare / samples, child_bare / samples])
	# Kaya ve çalı: Çocukluk'unkilerle aynı yerde, aynı biçimde (aynı otlak).
	assert_true(int(world.scatter_counts.get("rocks", 0)) > 150, "Kaya öbekleri (%d)" % int(world.scatter_counts.get("rocks", 0)))
	assert_true(int(world.scatter_counts.get("shrubs", 0)) > 200, "Çalı (%d)" % int(world.scatter_counts.get("shrubs", 0)))
	# E21 (K110): göle ve Ebe Obası'na giden yolların kayası ve çalısı (bölgeli satırlar) yalnız Çocukluk'tadır; kampınkiler aynı yerde.
	var site_scatter := ChildhoodScatter.build(ChildhoodSite.baked_spec(layout, ChildhoodGround.bake(layout)))
	var expected: Array = []
	for row: Dictionary in site_scatter["rocks"]:
		if not row.has("region"):
			expected.append(row["buffer"])
	for row: Dictionary in site_scatter["shrubs"]:
		if not row.has("region") and not (row["buffer"] as PackedFloat32Array).is_empty():
			expected.append(row["buffer"])
	var got: Array = []
	for group in ["Ground/Rocks", "Ground/Shrubs"]:
		for mmi in world.get_node(NodePath(group)).get_children():
			got.append((mmi as MultiMeshInstance3D).multimesh.buffer)
	assert_eq(got.size(), expected.size(), "Kaya ve çalının MultiMesh'leri Çocukluk'unkilerle aynı")
	for i in mini(got.size(), expected.size()):
		assert_true(got[i] == expected[i], "%d. MultiMesh Çocukluk'unkiyle aynı yerde" % i)
	var tufts := 0
	for mmi in world.get_node(^"Ground/Grass").get_children():
		var b: PackedFloat32Array = (mmi as MultiMeshInstance3D).multimesh.buffer
		tufts += b.size() / OrdosWorld.FLOATS_PER_TUFT
		# Her yedinci tutam sınanır.
		for i in range(0, b.size(), OrdosWorld.FLOATS_PER_TUFT * 7):
			assert_true(steppe.trampled_weight(Vector2(b[i + 3], b[i + 11])) < 0.999, "Ot çiğnenmiş toprakta yok")
			assert_almost(b[i + 7], steppe.height_at(b[i + 3], b[i + 11]) - 0.02, 0.0001, "Ot bozkırın yüzüne oturur")
		if failures.size() > 3:
			return
	assert_true(tufts > 8000, "Ot kurulur (%d tutam)" % tufts)
	# Çocukluk'a özgü düğümler yok.
	assert_null(world.get_node_or_null(^"Childhood"), "Çocukluk'un düğümü yok")
	assert_eq(get_tree().get_nodes_in_group(SmallGame.GROUP).size(), 0, "Küçük av yok")
	const CHILDHOOD_ONLY: Array[String] = ["ChildhoodSite", "HerdField", "SmallGameField", "SmallGame", "CampProp", "RideableSheep"]
	const CHILDHOOD_NAMES: Array[String] = ["Pen", "Stone", "Marks", "Cairns", "Flags", "Herd", "SmallGame", "Props"]
	for node in world.find_children("*", "", true, false):
		var script := node.get_script() as Script
		var global := String(script.get_global_name()) if script else ""
		assert_false(CHILDHOOD_ONLY.has(global), "Doğumda Çocukluk'a özgü düğüm: %s (%s)" % [world.get_path_to(node), global])
		assert_false(CHILDHOOD_NAMES.has(String(node.name)), "Doğumda Çocukluk'a özgü düğüm: %s" % world.get_path_to(node))


func test_the_horizon_keeps_the_sun_and_the_moon_in_sight() -> void:
	# 06:03'te güneş doğuda ufukta (görünen −0,15°), dolunay batıda +2,15°: doğu ufku güneşi, batı tepeleri ayı
	# örtmemeli. Kamera yurdun yanında, göz hizasında.
	var world := await _get_world()
	if world == null:
		return
	var g := world.ground
	var eye := Vector3(1.0, g.height_at(1.0, -6.0) + 1.6, -6.0)
	var west := _horizon_angle(g, eye, 260.0, 282.0)
	var east := _horizon_angle(g, eye, 86.0, 98.0)
	assert_true(west < 1.5, "Batı ufku ayın 1,5° altında kalmalı (%.2f°)" % west)
	assert_true(east < 0.1, "Doğu ufku güneşin diskini örtmemeli (%.2f°)" % east)
	# Bozkırın kademesi ve tepeleri de batıda ayı örtmez (7b'nin ay karesi batıya bakar; güneş hiçbir karede yoktur, doğudaki kademe
	# yalnız göz hizasındaki bakışta ufkun üstündedir).
	if world.steppe:
		var steppe_eye := Vector3(eye.x, world.steppe.height_at(eye.x, eye.z) + 1.6, eye.z)
		var steppe_west := _horizon_angle(world.steppe, steppe_eye, 260.0, 282.0)
		assert_true(steppe_west < 1.5, "Bozkırın batı ufku ayın 1,5° altında kalmalı (%.2f°)" % steppe_west)


func test_camera_points_are_clear_of_the_yurts() -> void:
	# Çekim önerileri geometrinin içinde kalmasın: «inside_*» doğum yurdunun astarının içinde, ötekiler bütün
	# yurtların dışında ve zeminin üstünde.
	var world := await _get_world()
	if world == null:
		return
	var layout := OrdosWorld.load_layout(LAYOUT)
	var cameras: Dictionary = layout["cameras"]
	assert_true(cameras.size() >= 6, "Kamera noktaları yazılmalı")
	for id: String in cameras:
		var point := world.camera_point(id)
		assert_false(point.is_empty(), "%s kamera noktası kurulmalı" % id)
		if point.is_empty():
			continue
		var pos := (point["transform"] as Transform3D).origin
		var target := Vector3(float(cameras[id]["look_at"][0]), float(cameras[id]["look_at"][1]), float(cameras[id]["look_at"][2]))
		assert_vec_almost(-(point["transform"] as Transform3D).basis.z, (target - pos).normalized(), 0.001, "%s hedefine bakmalı" % id)
		assert_true(pos.y > world.ground.height_at(pos.x, pos.z) + 0.3, "%s zeminin üstünde" % id)
		assert_between(float(point["fov"]), 20.0, 80.0, "%s görüş açısı" % id)
		for place_id: String in layout["places"]:
			var yurt := world.place(place_id) as Yurt
			var d := Vector2(pos.x - yurt.global_position.x, pos.z - yurt.global_position.z).length()
			if id.begins_with("inside") and place_id == "lan_yurt":
				assert_true(d < yurt.radius * OrdosWorld.BirthYurt.LINING_RATIO - 0.2, "%s doğum yurdunun içinde (%.2f m)" % [id, d])
			else:
				assert_true(d > yurt.radius + 0.3, "%s, %s'in dışında olmalı (%.2f m)" % [id, place_id, d])


func test_cine_host_loads_the_world_during_the_myth_without_a_wait() -> void:
	# Önsöz'ün kuruluşu (godot.md §3.6; prologue.json'un biçimi): mit (overlay) başlarken dünya arka planda istenir,
	# pano 6'da örneklenir ve kurulur; doğum segmenti başladığında dünya hazırdır, sinema saati beklemez.
	var host := CineHost.new()
	host.audio = CineAudio.new(RefCounted.new())
	host.speed = 1.5
	add_child(host)
	var held := [false]
	var at_birth := {}
	host.segment_started.connect(func(seg_id: String) -> void:
		if seg_id == "birth":
			var node := host.world_node(SCENE)
			at_birth["time"] = host.time()
			at_birth["ready"] = node != null and bool(node.call(&"is_ready")))
	host.play({"id": "seq", "segments": [
		{"id": "myth", "world": "none", "view": "overlay", "length": 3.0, "events": [{"id": "panel_6", "t": 1.0, "type": "event"}]},
		{"id": "birth", "world": SCENE, "length": 0.5, "preload_at": "myth", "instantiate_at": "myth:panel_6",
			"events": [{"t": 0.0, "type": "event", "id": "go"}]}]})
	await wait_frames(2)
	assert_ne(host.load_state(SCENE), ResourceLoader.THREAD_LOAD_INVALID_RESOURCE, "Dünya mit başında arka planda istenmeli")
	assert_null(host.world_node(SCENE), "Pano 6'dan önce örneklenmemeli")
	var deadline := Time.get_ticks_msec() + 20000
	while not at_birth.has("time") and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
		held[0] = held[0] or host.runner.held
		if host.time() >= 2.4 and not at_birth.has("checked"):
			at_birth["checked"] = true
			var early := host.world_node(SCENE)
			assert_true(early is OrdosWorld and (early as OrdosWorld).is_ready(), "Dünya doğumdan önce (pano 6'dan sonra) hazır olmalı")
			assert_true(host.instantiate_ms.has(SCENE), "Örnekleme süresi kaydedilmeli")
			if host.instantiate_ms.has(SCENE):
				assert_true(float(host.instantiate_ms[SCENE]) <= FRAME_MS, "Örnekleme bir kareyi aşmamalı (%.2f ms)" % float(host.instantiate_ms[SCENE]))
	assert_true(at_birth.has("time"), "Doğum segmenti başlamalı")
	assert_true(bool(at_birth.get("ready", false)), "Geçişte dünya hazır: yükleme yok")
	assert_false(held[0], "Sinema saati dünyayı beklememeli")
	var finished := watch_signal(host.finished)
	deadline = Time.get_ticks_msec() + 10000
	while not finished.fired and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	assert_eq(finished.last_args, [false], "Dizi sonuna dek oynamalı")
	assert_null(host.world_node(SCENE), "Dizi bitince örneklenen dünya bırakılır")
	host.queue_free()
	await wait_frames(3)


# --- Işık ve ücretsiz varlıklar --------------------------------------------------------------------

func test_sky_rig_starts_with_the_inside_dawn_sample() -> void:
	var world := await _get_world()
	if world == null:
		return
	var rig := world.get_sky_rig()
	assert_not_null(rig, "Dünyanın SkyRig'i olmalı")
	if rig == null:
		return
	assert_eq(str(rig.current_sample().get("id", "")), "inside", "Açılışta 05:50 (içeride) örneği")
	assert_false(rig.is_fixed(), "Açılış örneği sabit değildir; sinema sabitler")
	var light := world.get_node(^"SunLight") as DirectionalLight3D
	assert_almost(light.light_energy, float(rig.current_sample()["light_energy"]), 1e-6, "Işığı SkyRig yazar")
	var river := world.get_node_or_null(^"River") as MeshInstance3D
	var glint: Variant = (river.material_override as ShaderMaterial).get_shader_parameter("moon_direction") if river else null
	assert_true(glint is Vector3, "Kurulum bitince suyun parıltısı yazılmalı")
	assert_true(rig.fix_from("res://data/cine/birth_light.json", "outside"), "06:03 örneği sabitlenebilmeli")
	assert_true(rig.is_fixed())
	rig.clear_fixed_sample()


func test_free_assets_are_moved_marked_and_recorded() -> void:
	var world := await _get_world()
	if world == null:
		return
	var usage := _usage_lines()
	for path: String in FREE_NODES:
		var id: String = FREE_NODES[path]
		var node := world.get_node_or_null(NodePath(path))
		assert_not_null(node, "Ücretsiz varlığın düğümü: %s" % path)
		if node == null:
			continue
		var mark: Variant = node.get_meta(&"free_asset", "")
		assert_true(str(mark) == id or (mark is Array and (mark as Array).has(id)), "%s free_asset meta verisi (%s)" % [path, mark])
		var texture := _texture_of(node)
		assert_not_null(texture, "%s ücretsiz dokuyu kullanmalı" % path)
		if texture:
			assert_true(texture.resource_path.begins_with("res://assets/_free/") and texture.resource_path.contains("/%s/" % id),
				"%s dokusu assets/_free/<tür>/%s/ altında (%s)" % [path, id, texture.resource_path])
		var line := "scenes/maps/childhood_ordos.tscn:%s" % path
		var found := false
		for entry: Dictionary in usage:
			if str(entry.get("id")) == id and str(entry.get("usedIn")) == line and str(entry.get("batch")) == BATCH:
				found = true
		assert_true(found, "usage.jsonl'de %s → %s satırı olmalı" % [id, line])
	for id in FREE_NODES.values():
		assert_false(DirAccess.dir_exists_absolute("res://assets/_free/_staging/polyhaven/%s" % id), "%s _staging'den taşınmalı" % id)


func test_draw_budget_upper_bound() -> void:
	# Başsız sürücü çizmez: sınır, kırpma olmadan çizilebilecek her yüzey sayılarak üstten sınanır (görünür ≤900,
	# gölge ≤500; K63). Gerçek ölçüm kamera noktalarında budget_probe ile pencereli yapılır.
	var world := await _get_world()
	if world == null:
		return
	var visible := 0
	var shadow := 0
	var hearth := world.hearth()
	var hearth_reach := hearth.light_range if hearth else 0.0
	for node in world.find_children("*", "GeometryInstance3D", true, false):
		var gi := node as GeometryInstance3D
		if not gi.is_visible_in_tree():
			continue
		var surfaces := _surface_count(gi)
		visible += surfaces
		if gi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			shadow += surfaces * SHADOW_SPLITS
			if hearth and gi.global_position.distance_to(hearth.global_position) < hearth_reach + 3.0:
				shadow += surfaces * OMNI_FACES
	print("    [ordos] çizim üst sınırı: görünür %d, gölge %d" % [visible, shadow])
	assert_true(visible <= VISIBLE_DRAWS, "Görünür çizim üst sınırı ≤%d (%d)" % [VISIBLE_DRAWS, visible])
	assert_true(shadow <= SHADOW_DRAWS, "Gölge çizimi üst sınırı ≤%d (%d)" % [SHADOW_DRAWS, shadow])


## Paylaşılan dünyayı bırakır (sahne testlerinin sonuncusu): düğüm, öksüz düğüm, iş parçacığı ve önbellek sızıntısı yok.
func test_freeing_leaves_no_nodes_or_cached_resources() -> void:
	var world := await _get_world()
	if world == null:
		return
	var free_paths: Array[String] = []
	for path: String in FREE_NODES:
		var texture := _texture_of(world.get_node(NodePath(path)))
		if texture:
			free_paths.append(texture.resource_path)
	var groups := []
	for node in get_tree().get_nodes_in_group(World.OBSTACLE_GROUP):
		if world.is_ancestor_of(node):
			groups.append(node)
	assert_false(groups.is_empty(), "Yurtlar engel grubunda olmalı")
	world.queue_free()
	_world = null
	world = null
	groups.clear()
	await get_tree().create_timer(0.3).timeout
	await wait_frames(3)
	var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	assert_true(nodes <= _baseline_nodes, "Dünya bırakılınca düğüm sayısı başa dönmeli (%d → %d)" % [_baseline_nodes, nodes])
	assert_eq(get_child_count(), 0, "Sınamanın altında düğüm kalmamalı")
	assert_true(orphans <= _baseline_orphans, "Öksüz düğüm kalmamalı (%d → %d)" % [_baseline_orphans, orphans])
	assert_false(ResourceLoader.has_cached(SCENE), "Sahne önbellekte kalmamalı")
	for path in free_paths:
		assert_false(ResourceLoader.has_cached(path), "%s önbellekte kalmamalı" % path)
	var leftovers := 0
	for node in get_tree().get_nodes_in_group(World.OBSTACLE_GROUP):
		if is_ancestor_of(node):
			leftovers += 1
	assert_eq(leftovers, 0, "Bırakılan dünyadan engel kaydı kalmamalı")


# --- Saf yardımcılar (sahne gerektirmez) ----------------------------------------------------------

func test_axis_lines_are_fine_inside_and_coarse_outside() -> void:
	var lines := OrdosGround.axis_lines(110.0, 2.0, 3000.0, 1.18)
	assert_almost(lines[0], -3000.0, 0.01, "Izgara 3 km'ye uzanır")
	assert_almost(lines[lines.size() - 1], 3000.0, 0.01)
	for i in range(1, lines.size()):
		assert_true(lines[i] > lines[i - 1], "Çizgiler artan ve tekrarsız")
		var mid := (lines[i] + lines[i - 1]) * 0.5
		if absf(mid) < 110.0:
			assert_almost(lines[i] - lines[i - 1], 2.0, 0.0001, "Harita içinde 2 m ızgara")
	assert_true(lines.size() < 200, "Dış halka seyrek (%d çizgi)" % lines.size())


func test_grid_triangles_face_up() -> void:
	# Godot'da ön yüz yukarıdan bakınca saat yönündedir: (b − a) × (c − a)'nın y'si eksi olmalı.
	var indices := OrdosGround.grid_indices(3, 3)
	var verts := PackedVector3Array()
	for j in 3:
		for i in 3:
			verts.append(Vector3(float(i), 0.0, float(j)))
	assert_eq(indices.size(), 2 * 2 * 6)
	for k in range(0, indices.size(), 3):
		var a := verts[indices[k]]
		var n := (verts[indices[k + 1]] - a).cross(verts[indices[k + 2]] - a)
		assert_true(n.y < 0.0, "Üçgen %d yukarıdan görünür (ön yüz)" % (k / 3))


func test_door_basis_turns_the_door_to_the_compass() -> void:
	assert_vec_almost(OrdosWorld.door_basis(90.0) * Vector3.BACK, Vector3.RIGHT, 1e-6, "90 = doğu (+X)")
	assert_vec_almost(OrdosWorld.door_basis(0.0) * Vector3.BACK, Vector3.FORWARD, 1e-6, "0 = kuzey (−Z)")
	assert_vec_almost(OrdosWorld.door_basis(180.0) * Vector3.BACK, Vector3.BACK, 1e-6, "180 = güney (+Z)")


func test_grass_avoids_yurts_and_trampled_ground_and_is_deterministic() -> void:
	var spec := OrdosWorld.load_layout(LAYOUT)
	(spec["grass"] as Dictionary)["count"] = 2500
	var blockers := OrdosWorld.grass_blockers(spec)
	var first := OrdosWorld.grass_buffers(spec, blockers)
	var second := OrdosWorld.grass_buffers(spec, blockers)
	assert_eq(first.keys().size(), second.keys().size(), "Aynı tohum aynı parçalar")
	var ground := OrdosGround.new(spec)
	var total := 0
	for key: Vector3i in first:
		var a: PackedFloat32Array = first[key]
		assert_eq(a, second[key] as PackedFloat32Array, "Aynı tohum aynı otlar (%s)" % key)
		for i in range(0, a.size(), OrdosWorld.FLOATS_PER_TUFT):
			total += 1
			var p := Vector2(a[i + 3], a[i + 11])
			assert_false(Scatter.is_blocked(p.x, p.y, blockers), "Ot yurdun altında olmamalı (%s)" % p)
			assert_true(ground.trampled_weight(p) < 0.999, "Ot çiğnenmiş toprağın ortasında olmamalı (%s)" % p)
			assert_almost(a[i + 7], ground.height_at(p.x, p.y) - 0.02, 0.0001, "Ot zemine oturur")
		if failures.size() > 3:
			break
	assert_true(total > 500, "Ot üretilmeli (%d)" % total)


func test_rope_hangs_between_its_points() -> void:
	var points := PackedVector3Array([Vector3(0.0, 1.0, 0.0), Vector3(0.0, 1.0, 3.0)])
	var mesh := OrdosWorld.rope_mesh(points, 0.12, 0.012)
	var arrays := mesh.surface_get_arrays(0)
	var lowest := INF
	for v: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
		lowest = minf(lowest, v.y)
	assert_between(lowest, 1.0 - 0.12 - 0.02, 1.0 - 0.12 + 0.02, "İp ortada sag kadar sarkar")


# --- Yardımcılar ------------------------------------------------------------------------------------

## Paylaşılan dünya: ilk çağrıda oyundaki gibi arka planda yüklenir, örneklenir, eklenir; hazır olana dek beklenir.
func _get_world() -> OrdosWorld:
	if is_instance_valid(_world) and _world.is_ready():
		return _world
	if not is_instance_valid(_world):
		_baseline_nodes = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		_baseline_orphans = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
		var err := ResourceLoader.load_threaded_request(SCENE, "", true)
		if err != OK:
			fail("load_threaded_request başlamadı (%d)" % err)
			return null
		var frames := 0
		var status := ResourceLoader.load_threaded_get_status(SCENE)
		while status == ResourceLoader.THREAD_LOAD_IN_PROGRESS and frames < 6000:
			await get_tree().process_frame
			frames += 1
			status = ResourceLoader.load_threaded_get_status(SCENE)
		_load["status"] = status
		_load["load_frames"] = frames
		if status != ResourceLoader.THREAD_LOAD_LOADED:
			fail("Sahne arka planda yüklenemedi (durum %d)" % status)
			return null
		var scene := ResourceLoader.load_threaded_get(SCENE) as PackedScene
		var started := Time.get_ticks_usec()
		var node := scene.instantiate() as OrdosWorld
		_load["instantiate_ms"] = (Time.get_ticks_usec() - started) / 1000.0
		if node == null:
			fail("Sahnenin kökü OrdosWorld olmalı")
			return null
		started = Time.get_ticks_usec()
		add_child(node)
		_load["add_ms"] = (Time.get_ticks_usec() - started) / 1000.0
		_load["ready_at_add"] = node.is_ready()
		_world = node
	var waited := 0
	var deadline := Time.get_ticks_msec() + int(READY_TIMEOUT * 1000.0)
	while is_instance_valid(_world) and not _world.is_ready() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
		waited += 1
	_load["ready_frames"] = waited
	return _world if is_instance_valid(_world) and _world.is_ready() else null


## Paylaşılan dünyanın yanında ikinci bir dünya kurar (ısınmış önbellekle), hazır olunca ölçüleriyle bırakır.
func _build_extra_world() -> Dictionary:
	var scene := load(SCENE) as PackedScene
	var started := Time.get_ticks_usec()
	var extra := scene.instantiate() as OrdosWorld
	add_child(extra)
	var add_ms := (Time.get_ticks_usec() - started) / 1000.0
	var deadline := Time.get_ticks_msec() + int(READY_TIMEOUT * 1000.0)
	while not extra.is_ready() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	var stats := {}
	if extra.is_ready():
		stats = extra.build_stats.duplicate(true)
		stats["add_ms"] = add_ms
	extra.queue_free()
	await wait_frames(2)
	return stats


## Gözden verilen azimut aralığında (derece) arazinin ufuk yüksekliği (derece; en büyük).
static func _horizon_angle(g: OrdosGround, eye: Vector3, az_from: float, az_to: float) -> float:
	var best := -90.0
	var az := az_from
	while az <= az_to:
		var dir := Vector2(sin(deg_to_rad(az)), -cos(deg_to_rad(az)))
		var d := 20.0
		while d < g.far:
			var p := Vector2(eye.x, eye.z) + dir * d
			best = maxf(best, rad_to_deg(atan2(g.height_at(p.x, p.y) - eye.y, d)))
			d *= 1.08
		az += 2.0
	return best


static func _surface_count(gi: GeometryInstance3D) -> int:
	if gi is MeshInstance3D:
		var mesh := (gi as MeshInstance3D).mesh
		return mesh.get_surface_count() if mesh else 0
	if gi is MultiMeshInstance3D:
		var mm := (gi as MultiMeshInstance3D).multimesh
		return mm.mesh.get_surface_count() if mm and mm.mesh and mm.instance_count > 0 else 0
	return 1


## Düğümün kullandığı ücretsiz doku: ortamın gök panoraması, malzemenin mottle_tex'i ya da bozkırın zemininin grass_tex'i.
static func _texture_of(node: Node) -> Texture2D:
	if node is WorldEnvironment:
		var env := (node as WorldEnvironment).environment
		var mat := env.sky.sky_material as ShaderMaterial if env and env.sky else null
		return mat.get_shader_parameter("ambient_panorama") as Texture2D if mat else null
	if node is GeometryInstance3D:
		var mat := (node as GeometryInstance3D).material_override as ShaderMaterial
		if mat == null:
			return null
		var tex := mat.get_shader_parameter("mottle_tex") as Texture2D
		return tex if tex else mat.get_shader_parameter("grass_tex") as Texture2D
	return null


static func _usage_lines() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not FileAccess.file_exists(USAGE):
		return out
	for line in FileAccess.get_file_as_string(USAGE).split("\n", false):
		var parsed: Variant = JSON.parse_string(line)
		if parsed is Dictionary:
			out.append(parsed)
	return out
