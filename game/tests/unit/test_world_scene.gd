extends TestCase
## Dünya sahnesi duman testi ve dünya betiklerinin saf yardımcıları.
##
## res://scenes/world/world.tscn pencere açmadan (headless) kurulur; kurulum konsola hata yazmamalı,
## temel düğümler oluşmalı, üretilen içerik boş olmamalı ve serbest gezinti için engeller toplanabilmeli.
## Sahne kurulumu birkaç saniye sürdüğü için bu dosyadaki sahne testleri aynı dünya örneğini paylaşır.
## Ateş başı Göl Obası'nın ocağıdır (K37, K106; Mete yok, Ağabey yer tutucusu); Önsöz'ün geri çekilme yolu dünyadaki çamlara,
## kayalara ve zemine karşı sınanır (MenuCamera.path_clearance).

const WORLD_SCENE := "res://scenes/world/world.tscn"
## Sahnede bulunması gereken düğümler.
const KEY_NODES: Array[NodePath] = [
	^"WorldEnvironment", ^"MoonLight", ^"Terrain", ^"Mountains", ^"Water", ^"Forest", ^"RockField",
	^"VillageLights", ^"Camp", ^"Camp/Campfire", ^"Camp/YurtLeft", ^"Camp/YurtRight", ^"Camp/Stable",
	^"Camp/CampNpcs", ^"Meadow", ^"PathNetwork",
]
## Kamp nesnelerinin zemine oturduğu kabul edilen en büyük yükseklik farkı (metre).
const GROUND_TOLERANCE := 0.15
## Ateşin başında oturan karakter sayısı (1. referans görüntüdeki gibi) ve ateşe uzaklıkları (metre).
const CAMPFIRE_NPCS := 5
const NPC_MIN_DISTANCE := 1.5
const NPC_MAX_DISTANCE := 4.0

var _world: World
## Dünya kurulurken konsola yazılan hata iletileri (bkz. _get_world).
var _build_errors := PackedStringArray()


# --- Sahne kurulumu -----------------------------------------------------------------
# Not: Her düğüm _require() ile alınır. Eksikse test önce başarısız sayılır, sonra durur;
# böylece null bir düğüme erişip sessizce yarıda kesilmez.

func test_scene_builds_without_errors() -> void:
	# Duman testi: sahne kurulurken hiçbir betik ya da motor hatası yazılmamalı (ör. eksik dosya,
	# null düğüm ya da yarıda kalan bir dağıtıcı). Koşucu bu hataları kendisi yakalamaz.
	var world := await _get_world()
	if world == null:
		return
	assert_true(_build_errors.is_empty(), "Dünya kurulurken %d hata yazıldı: %s" % [_build_errors.size(), _build_errors.slice(0, 3)])


func test_scene_builds_key_nodes() -> void:
	var world := await _get_world()
	if world == null:
		return
	for path in KEY_NODES:
		assert_not_null(world.get_node_or_null(path), "Eksik düğüm: %s" % path)
	assert_true(world.get_node_or_null(^"Terrain") is Terrain, "Terrain betiği bağlı olmalı")
	assert_true(world.get_node_or_null(^"Mountains") is Mountains, "Mountains betiği bağlı olmalı")
	assert_true(world.get_node_or_null(^"Water") is Water, "Water betiği bağlı olmalı")
	assert_true(world.get_node_or_null(^"Meadow") is Meadow, "Meadow betiği bağlı olmalı")
	assert_true(world.get_node_or_null(^"Camp/Campfire") is Campfire, "Campfire betiği bağlı olmalı")
	assert_true(world.get_node_or_null(^"Camp/YurtLeft") is Yurt, "YurtLeft bir Yurt olmalı")


func test_generated_content_is_not_empty() -> void:
	var world := await _get_world()
	if world == null:
		return
	var terrain_mesh := _require(^"Terrain/TerrainMesh") as MeshInstance3D
	if terrain_mesh:
		assert_true(terrain_mesh.mesh != null and terrain_mesh.mesh.get_surface_count() == 1, "Arazi meshi boş")
	_require(^"Mountains/MountainMesh")
	var water := _require(^"Water/WaterMesh") as Node3D
	if water:
		assert_almost(water.global_position.y, TerrainShape.WATER_LEVEL, 0.0001, "Su yüzeyi su seviyesinde olmalı")
	_require(^"Camp/Campfire/FireLight")
	var counts := {^"Meadow": 1000, ^"Forest": 100, ^"RockField": 10}
	for path in counts:
		var node := _require(path)
		if node:
			var instances := _multimesh_instances(node)
			assert_true(instances > int(counts[path]), "%s neredeyse boş (%d örnek)" % [path, instances])
	var yurt := _require(^"Camp/YurtLeft")
	if yurt:
		assert_true(yurt.get_child_count() > 0, "Yurt parçaları kurulmalı")


func test_collect_obstacles_returns_camp_circles() -> void:
	var world := await _get_world()
	if world == null:
		return
	var obstacles := world.collect_obstacles()
	assert_false(obstacles.is_empty(), "Serbest gezinti için engel bulunamadı")
	var invalid := 0
	for c in obstacles:
		if c.z <= 0.0 or not c.is_finite():
			invalid += 1
	assert_eq(invalid, 0, "Engel yarıçapı pozitif ve sonlu olmalı")
	# Daireler nesnelerin GERÇEK konumunda aranır; yarıçapın tam değeri nesnenin kendi testinde sınanır
	# (bkz. test_campfire.gd), burada yalnızca nesneyi örtecek kadar büyük olması beklenir.
	var fire := _require(^"Camp/Campfire") as Node3D
	if fire:
		assert_true(_has_circle_at(obstacles, fire.global_position, 0.5), "Kamp ateşi engel olmalı")
	var yurt := _require(^"Camp/YurtLeft") as Yurt
	var camp := _require(^"Camp")
	if yurt == null or camp == null:
		return
	assert_true(_has_circle_at(obstacles, yurt.global_position, yurt.radius), "Sol yurt, duvarını örten bir engel olmalı")
	# Üzerinden geçilebilen eşyalar (ör. bardaklar, blocks_movement = false) engel listesine girmez.
	var walkable := 0
	for node in _authored_nodes(camp):
		var prop := node as CampProp
		if prop == null or prop.blocks_movement:
			continue
		walkable += 1
		var q := prop.global_position
		for c in obstacles:
			assert_false(Vector2(c.x - q.x, c.y - q.z).length() < 0.01, "%s engel listesinde olmamalı" % prop.name)
	assert_true(walkable > 0, "Sahnede üzerinden geçilebilen en az bir eşya (bardak) olmalı")


func test_meadow_blockers_include_rugs() -> void:
	# Çimen halıların altında da çıkmamalı: çayır engelleri = gezinti engelleri + halılar.
	var world := await _get_world()
	if world == null:
		return
	var covers := 0
	for node in get_tree().get_nodes_in_group(Rug.GROUND_COVER_GROUP):
		if node.has_method("get_cover_circles"):
			covers += (node.get_cover_circles() as Array).size()
	assert_true(covers > 0, "Sahnede en az bir halı olmalı")
	var blockers := Meadow.collect_blockers(get_tree())
	# Çayır nesnelerin kapladığı yerden (get_obstacle_circles) çıkmaz; çarpışma ayrı olabilir (ahırın içine girilir: yalnız direkleri çarpışır).
	var footprints := 0
	for node in get_tree().get_nodes_in_group(World.OBSTACLE_GROUP):
		if node.has_method("get_obstacle_circles"):
			footprints += (node.get_obstacle_circles() as Array).size()
	assert_eq(blockers.size(), footprints + covers, "Halılar çayır engeline eklenmeli")


func test_terrain_shape_is_shared_with_terrain() -> void:
	var world := await _get_world()
	if world == null:
		return
	var terrain := _require(^"Terrain") as Terrain
	if terrain == null:
		return
	assert_not_null(terrain.shape, "Arazi biçimi kurulmalı")
	assert_true(world.get_terrain_shape() == terrain.shape, "World ve Terrain aynı TerrainShape'i kullanmalı")
	assert_eq(world.get_terrain_shape().seed_value, terrain.seed_value)


func test_camp_objects_stand_on_the_ground() -> void:
	# Kamp nesneleri y = 0'a konur; altlarındaki zemin de ~0 olmalı ki havada ya da gömülü kalmasınlar.
	var world := await _get_world()
	if world == null:
		return
	var camp := _require(^"Camp")
	if camp == null:
		return
	var shape := world.get_terrain_shape()
	var floating: Array[String] = []
	var checked := 0
	for node in _authored_nodes(camp):
		# Yalnızca yerde duran nesneler: kodla çizilen kamp nesneleri ve 3B karakterler.
		# (Elle eklenen bir ışık ya da işaret noktası havada durabilir; onlar denetlenmez. Karakterin elindeki ya da
		# kucağındaki eşya, ör. ozanın kopuzu, karakterle birlikte durur: o da denetlenmez.)
		if not (node is Procedural3D or node is CharacterAvatar) or node.get_parent() is CharacterAvatar:
			continue
		var p := node.global_position
		var gap := absf(p.y - shape.height_at(p.x, p.z))
		checked += 1
		if gap > GROUND_TOLERANCE:
			floating.append("%s (%.2f m)" % [node.name, gap])
	assert_true(checked > 10, "Kampta denetlenecek nesne bulunamadı")
	assert_true(floating.is_empty(), "Zemine oturmayan kamp nesneleri: %s" % [floating])


func test_moon_and_light_directions_are_applied() -> void:
	var world := await _get_world()
	if world == null:
		return
	var env_node := _require(^"WorldEnvironment") as WorldEnvironment
	var sky_material: ShaderMaterial = null
	if env_node and env_node.environment and env_node.environment.sky:
		sky_material = env_node.environment.sky.sky_material as ShaderMaterial
	assert_not_null(sky_material, "Gökyüzü ShaderMaterial kullanmalı")
	if sky_material:
		var moon: Variant = sky_material.get_shader_parameter("moon_direction")
		assert_true(moon is Vector3, "World gökyüzüne moon_direction atamalı (değer: %s)" % [moon])
		if moon is Vector3:
			assert_vec_almost(moon, World.direction_from_angles(world.moon_azimuth, world.moon_elevation), 0.0001, "Gökyüzündeki ay World açılarıyla uyuşmalı")
	var light := _require(^"MoonLight") as DirectionalLight3D
	if light:
		var travel := -light.global_transform.basis.z
		var expected := -World.direction_from_angles(world.light_azimuth, world.light_elevation)
		assert_vec_almost(travel, expected, 0.0001, "Ay ışığı light_azimuth/light_elevation yönünden gelmeli")
		assert_true(travel.y < 0.0, "Ay ışığı yukarıdan aşağı vurmalı")


func test_dirt_spots_reach_the_terrain() -> void:
	# Araziye elle verilen lekeler (dirt_spots) ve her yurdun kapı önündeki ezik toprak gider.
	var world := await _get_world()
	if world == null:
		return
	var terrain := _require(^"Terrain") as Terrain
	if terrain == null:
		return
	var expected := world.ground_dirt_spots()
	assert_eq(terrain.dirt_spots, expected, "Kamp toprağı lekeleri araziye iletilmeli")
	assert_eq(expected.size(), world.dirt_spots.size() + World.yurt_door_spots(get_tree()).size(), "Yurt kapılarının lekeleri eklenmeli")
	assert_not_null(terrain.material, "Arazi malzemesi kurulmalı")
	if terrain.material:
		assert_eq(terrain.material.get_shader_parameter("dirt_spot_count"), expected.size(), "Leke sayısı shader'a iletilmeli")


func test_yurt_steps_stand_on_bare_trampled_ground() -> void:
	# 4. referanstaki gibi kapı basamakları çıplak, ezik toprakta durur: kapının önünde bir toprak lekesi vardır
	# ve basamakların üstünde çimen çıkmaz. (Leke halı gibi "ground_cover" değildir: ahır yolu oradan başlar.)
	var world := await _get_world()
	var meadow := _require(^"Meadow") as Meadow
	if world == null or meadow == null:
		return
	var blockers := Meadow.collect_blockers(get_tree())
	var spots := world.ground_dirt_spots()
	for path in [^"Camp/YurtLeft", ^"Camp/YurtRight"]:
		var yurt := _require(path) as Yurt
		if yurt == null:
			continue
		var dir := Vector2(yurt.global_basis.z.x, yurt.global_basis.z.z).normalized()
		var base := Vector2(yurt.global_position.x, yurt.global_position.z)
		for k in [1.03, 1.12, 1.22]:
			var step: Vector2 = base + dir * yurt.radius * k
			assert_almost(meadow.grass_density(step, blockers), 0.0, 0.0001, "%s: basamakta (%.2f r) çimen çıkmamalı" % [yurt.name, k])
			var on_dirt := false
			for s in spots:
				if Vector2(s.x, s.y).distance_to(step) < s.z * 0.5:
					on_dirt = true
			assert_true(on_dirt, "%s: basamak (%.2f r) toprak lekesinin üstünde olmalı" % [yurt.name, k])


func test_every_seat_is_on_a_rug() -> void:
	# Halılar küçük ve koyudur ama ateş başındaki herkes (ve Ağabey'in yanındaki yay) bir halının üstünde oturur.
	var world := await _get_world()
	var npcs := _require(^"Camp/CampNpcs")
	if world == null or npcs == null:
		return
	var rugs: Array[Rug] = []
	for node in get_tree().get_nodes_in_group(Rug.GROUND_COVER_GROUP):
		if node is Rug and is_ancestor_of(node):
			rugs.append(node)
	assert_eq(rugs.size(), 2, "Ateşin iki yanında birer halı olmalı")
	var seats: Array[Node3D] = []
	for child in npcs.get_children():
		if child is CharacterAvatar:
			seats.append(child)
	var bow := npcs.get_node_or_null(^"OlderBrother/Bow") as Node3D
	if bow:
		seats.append(bow)
	for seat in seats:
		var on_rug := false
		for rug in rugs:
			var local := rug.global_transform.affine_inverse() * seat.global_position
			if absf(local.x) <= rug.size.x * 0.5 - 0.1 and absf(local.z) <= rug.size.y * 0.5 - 0.1:
				on_rug = true
		assert_true(on_rug, "%s bir halının üstünde olmalı" % seat.name)
	for rug in rugs:
		assert_true(rug.size.x * rug.size.y < 3.5, "%s küçük olmalı (%.1f m²)" % [rug.name, rug.size.x * rug.size.y])


func test_grass_is_short_and_flowery_around_the_boulders() -> void:
	# Ön plandaki kayalar (4. referans) kısa çimenin ve çiçeklerin arasında durur: kayanın dibindeki çimen,
	# aynı noktada engel etkisi kapatılınca ölçülen boyun belirgin biçimde altında kalır, çiçek olasılığı artar.
	var world := await _get_world()
	var meadow := _require(^"Meadow") as Meadow
	var rocks := _require(^"RockField") as RockField
	if world == null or meadow == null or rocks == null:
		return
	var blockers := Meadow.collect_blockers(get_tree())
	var none: Array[Vector3] = []
	for i in [0, 1, 2, 5, 11]:
		var r := rocks.hero_rocks[i]
		var radius := rocks.hero_radius(i) * RockField.HERO_OBSTACLE_SCALE
		var p := Vector2(r.x, r.y) + Vector2(0.0, 1.0) * (radius + 0.3)
		var with_rock := meadow.grass_height(p)
		var saved := meadow._blocker_grid
		meadow._blocker_grid = {}
		var without_rock := meadow.grass_height(p)
		meadow._blocker_grid = saved
		assert_true(with_rock < without_rock * 0.75, "R%d dibindeki çimen kısa olmalı (%.2f / %.2f)" % [i + 1, with_rock, without_rock])
		assert_true(meadow.flower_weight(p, blockers) >= meadow.flower_weight(p, none), "R%d dibinde çiçek çok olmalı" % [i + 1])


func test_campfire_npcs_sit_around_the_fire_and_face_it() -> void:
	# Menü sahnesinin kalbi: ateşin başında beş karakter oturur; ateşin içinde değil, çevresinde
	# ve yüzleri ateşe dönük. (Meshy modeli yoksa yedek chibi karakter çıkar; bu da kabul edilir.)
	var world := await _get_world()
	if world == null:
		return
	var fire := _require(^"Camp/Campfire") as Node3D
	var npcs := _require(^"Camp/CampNpcs")
	if fire == null or npcs == null:
		return
	var avatars: Array[CharacterAvatar] = []
	for child in npcs.get_children():
		if child is CharacterAvatar:
			avatars.append(child)
	assert_eq(avatars.size(), CAMPFIRE_NPCS, "Ateşin başında beş karakter olmalı")
	var f := fire.global_position
	for avatar in avatars:
		var d := Vector2(avatar.global_position.x - f.x, avatar.global_position.z - f.z).length()
		assert_between(d, NPC_MIN_DISTANCE, NPC_MAX_DISTANCE, "%s ateşin çevresinde oturmalı (uzaklık)" % avatar.name)
		assert_true(avatar.auto_face, "%s ateşe dönmeli (auto_face açık olmalı)" % avatar.name)
		assert_vec_almost(avatar.face_point, f, 0.01, "%s yüzünü ateşe çevirmeli" % avatar.name)
		assert_false(avatar.model_id.is_empty(), "%s için bir model seçilmeli" % avatar.name)


func test_trampled_grass_and_dirt_follow_the_fire() -> void:
	# Ateş taşınırsa ezik çimenin merkezi (Meadow.trample_center) ve ateşin oturduğu toprak lekesi de
	# onunla gitmeli; yoksa ateşin dibinde gür çimen, boş bir yerde de ezik bir halka kalır.
	# Referanstaki gibi leke küçüktür: çimen halılara kadar gelir; leke patikanın başına bağlanır.
	var world := await _get_world()
	if world == null:
		return
	var fire := _require(^"Camp/Campfire") as Node3D
	var meadow := _require(^"Meadow") as Meadow
	var net := _require(^"PathNetwork") as PathNetwork
	if fire == null or meadow == null:
		return
	var f := Vector2(fire.global_position.x, fire.global_position.z)
	assert_true(meadow.trample_center.distance_to(f) < 0.3, "Ezik çimenin merkezi (%s) ateşte (%s) olmalı" % [meadow.trample_center, f])
	var on_dirt := false
	for spot in world.dirt_spots:
		# Taş halkası (~1 m) bütünüyle lekenin içinde kalmalı; leke halıların dışına taşmayacak kadar küçük.
		if Vector2(spot.x, spot.y).distance_to(f) + 1.0 <= spot.z:
			on_dirt = true
			assert_true(spot.z <= 2.6, "Ateşin toprağı küçük olmalı (yarıçap %.1f m)" % spot.z)
	assert_true(on_dirt, "Ateş, taş halkası bütünüyle içinde kalacak şekilde bir toprak lekesinin üstünde durmalı")
	if net and not net.paths.is_empty():
		# Ateşten çıkan patikanın başı ateşin toprağıyla birleşir (aradaki çimen ezik ya da seyrek).
		var start := net.paths[0][0]
		var joined := false
		for spot in world.dirt_spots:
			if Vector2(spot.x, spot.y).distance_to(start) < spot.z * 0.8:
				joined = true
		assert_true(joined, "Patikanın başı (%s) bir toprak lekesine bağlanmalı" % start)


func test_night_color_grade_is_applied() -> void:
	# AtW malzemeleri gündüz renkleriyle ayarlıdır; World onları gece renk ayarıyla (LUT) maviye çeker.
	var world := await _get_world()
	if world == null:
		return
	var env_node := _require(^"WorldEnvironment") as WorldEnvironment
	if env_node == null:
		return
	var env := env_node.environment
	assert_not_null(env, "Ortam (Environment) tanımlı olmalı")
	if env:
		assert_true(env.adjustment_enabled, "Renk ayarı açık olmalı")
		assert_true(env.adjustment_color_correction is Texture3D, "Gece renk ayarı (3B LUT) bağlanmalı")


func test_hearth_is_teomans_and_the_bard_holds_a_kopuz() -> void:
	# Ana kamp Göl Obası'dır (K37, K106): Ana, Çocuk, Baba, Ağabey ve Ozan; Mete yoktur. Yay Ağabey'in yanında,
	# kopuz ozanın kucağında; Ağabey kendi Meshy modeliyle oturur (E7.6).
	var world := await _get_world()
	var npcs := _require(^"Camp/CampNpcs") as CampNpcs
	if world == null or npcs == null:
		return
	var persons := PackedStringArray()
	for avatar in npcs.get_avatars():
		persons.append(CampNpcs.person_id(avatar))
		assert_ne(avatar.model_id, "mete", "%s Mete'nin modelini kullanmamalı" % avatar.name)
	persons.sort()
	assert_eq(persons, PackedStringArray(["child", "elder", "father", "mother", "older_brother"]), "Ocak halkı")
	assert_eq(npcs.get_avatar_for_person("older_brother").model_id, "older_brother", "Ağabey kendi modeliyle")
	var brother := npcs.get_node_or_null(^"OlderBrother") as Node3D
	var bow := npcs.get_node_or_null(^"OlderBrother/Bow") as Node3D
	if brother and bow:
		assert_true(_xz(bow.global_position).distance_to(_xz(brother.global_position)) < 1.0, "Yay Ağabey'in yanında")
	var kopuz := npcs.get_kopuz()
	assert_not_null(kopuz, "Ozanın kucağında kopuz olmalı")
	if kopuz:
		assert_true(kopuz.is_drawn() or kopuz.has_model(), "Kopuz çizilmeli ya da modeli gösterilmeli")
		assert_true(npcs.get_bard().is_ancestor_of(kopuz))


func test_pullback_path_keeps_clear_of_pines_rocks_and_ground() -> void:
	# Önsöz'ün geri çekilmesi (MenuCamera.fly_to(WIDE, 6 sn)): yol 0–6 sn boyunca 0,1 sn adımla çam taçlarına (ağaç
	# boyu ve taç yarıçapı ölçekten, TreeKit konisi), kayalara ve zemine ≥1,6 m pay bırakır (godot.md §3.6).
	var world := await _get_world()
	var forest := _require(^"Forest") as Forest
	var rocks := _require(^"RockField") as RockField
	if world == null or forest == null or rocks == null:
		return
	var shape := world.get_terrain_shape()
	var samples := MenuCamera.pullback_samples(_menu_transform(), 0.1)
	assert_eq(samples.size(), 61)
	var trees: Array[Vector4] = []
	for t in forest.get_planted_trees():
		trees.append(Vector4(t.x, t.y, t.z, shape.height_at(t.x, t.y)))
	assert_true(trees.size() > 20, "Kamp ve küme çamları sayılmalı")
	# Kayalar küre: kahraman kayalar boylarıyla (en büyük kenar), kaya kümelerinin taşları taban yarıçapının iki katı.
	var stones: Array[Vector4] = []
	for r in rocks.hero_rocks:
		stones.append(Vector4(r.x, shape.height_at(r.x, r.y) + r.z * 0.5, r.y, r.z * 0.75))
	for c in rocks.get_obstacle_circles():
		stones.append(Vector4(c.x, shape.height_at(c.x, c.y) + c.z, c.y, c.z * 2.0))
	var clearance := MenuCamera.path_clearance(samples, trees, stones, shape.height_at)
	assert_true(clearance >= 1.6, "Geri çekilme yolu çam, kaya ve zemine ≥1,6 m pay bırakmalı (%.2f m)" % clearance)
	# Vadi ormanının ağaçları (MultiMesh) yolun çevresinde yoktur: orman yoğunluğu yolun 6 m çevresinde sıfır
	# (en uzun vadi çamının tacı 1,3 × 2,8 m ≈ 3,6 m + 1,6 m pay).
	var dense := 0
	for q in samples:
		for dx in [-6.0, -3.0, 0.0, 3.0, 6.0]:
			for dz in [-6.0, -3.0, 0.0, 3.0, 6.0]:
				var p := Vector2(q.x + dx, q.z + dz)
				if p.length() >= forest.camp_clearing and shape.forest_density(p.x, p.y) > 0.0:
					dense += 1
	assert_eq(dense, 0, "Vadi ormanı geri çekilme yoluna yaklaşmamalı")


## Paylaşılan dünyayı serbest bırakır (sahne testlerinin sonuncusu olarak tanımlıdır;
## sıra değişse bile sonraki testler dünyayı yeniden kurar).
func test_world_frees_cleanly() -> void:
	var world := await _get_world()
	if world == null:
		return
	world.queue_free()
	_world = null
	await _settle_audio()
	assert_false(is_instance_valid(world), "Dünya silinmeli")
	var leftovers := 0
	for group in [World.OBSTACLE_GROUP, Rug.GROUND_COVER_GROUP]:
		for node in get_tree().get_nodes_in_group(group):
			if is_ancestor_of(node):
				leftovers += 1
	assert_eq(leftovers, 0, "Silinen dünyadan engel ya da halı kaydı kalmamalı")


# --- Saf yardımcılar (sahne gerektirmez) ----------------------------------------------

func test_collect_obstacles_outside_tree_is_empty() -> void:
	# Hata veren bir fonksiyon da boş dizi döndürür; bu yüzden hata yazılmadığı ayrıca denetlenir.
	var world := World.new()
	var collector := _ErrorLog.new()
	OS.add_logger(collector)
	var obstacles := world.collect_obstacles()
	var blockers := Meadow.collect_blockers(null)
	OS.remove_logger(collector)
	world.free()
	assert_true(obstacles.is_empty(), "Ağaçta olmayan dünya engel döndürmemeli")
	assert_true(blockers.is_empty(), "Ağaç yoksa çayır engeli de yok")
	assert_eq(collector.take(), PackedStringArray(), "Ağaç dışında çağrılınca hata yazılmamalı")


func test_direction_from_angles() -> void:
	assert_vec_almost(World.direction_from_angles(0.0, 0.0), Vector3(0.0, 0.0, -1.0), 0.0001, "0° = menü kamerasının baktığı yön (-Z)")
	assert_vec_almost(World.direction_from_angles(90.0, 0.0), Vector3(1.0, 0.0, 0.0), 0.0001, "90° = sağ (+X)")
	assert_vec_almost(World.direction_from_angles(-90.0, 0.0), Vector3(-1.0, 0.0, 0.0), 0.0001, "-90° = sol (-X)")
	assert_vec_almost(World.direction_from_angles(33.0, 90.0), Vector3.UP, 0.0001, "90° yükseklik = tepe")
	for az in [-170.0, -45.0, 24.0, 140.0]:
		for el in [5.0, 14.0, 50.0]:
			var d := World.direction_from_angles(az, el)
			assert_almost(d.length(), 1.0, 0.0001, "Yön birim vektör olmalı")
			assert_almost(d.y, sin(deg_to_rad(el)), 0.0001, "y bileşeni yüksekliğe eşit olmalı")


func test_forest_spot_rules() -> void:
	# Ağaç yalnızca su üstündeki, çok dik olmayan zemine dikilir.
	assert_true(Forest.is_good_spot(_flat(0.0), Vector2(10.0, 10.0)), "Düz kuru zemin uygun")
	assert_false(Forest.is_good_spot(_flat(TerrainShape.WATER_LEVEL), Vector2.ZERO), "Su altı uygun değil")
	assert_false(Forest.is_good_spot(_flat(TerrainShape.WATER_LEVEL + 1.0), Vector2.ZERO), "Kıyı şeridi (su + 1,2 m altı) uygun değil")
	assert_false(Forest.is_good_spot(_SlopeShape.new(), Vector2.ZERO), "Dik yamaç uygun değil")
	var real := TerrainShape.new()
	assert_true(Forest.is_good_spot(real, Vector2.ZERO), "Kamp zemini ağaç için uygun bir yer")
	assert_false(Forest.is_good_spot(real, Vector2(-30.0, -600.0)), "Göl ortası uygun değil")


func test_village_lights_find_the_shore() -> void:
	var shape := _ChannelShape.new()
	assert_eq(VillageLights.find_shore(shape, -500.0, 1.0), Vector2(130.0, -500.0), "Sağ kıyı")
	assert_eq(VillageLights.find_shore(shape, -500.0, -1.0), Vector2(70.0, -500.0), "Sol kıyı")
	assert_eq(VillageLights.find_shore(_flat(TerrainShape.WATER_LEVEL - 5.0), -500.0, 1.0), Vector2.INF, "Kıyı yoksa INF")
	var real := TerrainShape.new()
	var shore := VillageLights.find_shore(real, -420.0, 1.0)
	assert_ne(shore, Vector2.INF, "Gerçek gölde kıyı bulunmalı (z = -420)")
	if shore != Vector2.INF:
		assert_true(real.height_at(shore.x, shore.y) > TerrainShape.WATER_LEVEL + 1.0, "Bulunan nokta kuru olmalı")


# --- Yardımcılar ---------------------------------------------------------------------

## Dünyayı ilk çağrıda kurar ve dosyanın testleri arasında paylaşır. Kurulum sırasında konsola
## yazılan hatalar _build_errors'a kaydedilir.
## (test_world_frees_cleanly onu siler; o test çalışmazsa dünya test düğümüyle birlikte gider.)
func _get_world() -> World:
	if _world == null:
		var packed := load(WORLD_SCENE) as PackedScene
		assert_not_null(packed, "Sahne yüklenemedi: %s" % WORLD_SCENE)
		if packed == null:
			return null
		var collector := _ErrorLog.new()
		OS.add_logger(collector)
		var root := packed.instantiate()
		_world = root as World
		if _world:
			add_child(_world)
			# Meadow ve RockField kurulumu bir sonraki kareye ertelenir.
			await wait_frames(3)
		OS.remove_logger(collector)
		_build_errors = collector.take()
		if _world == null:
			fail("Sahnenin kökü World olmalı")
			if root:
				root.free()
	return _world


## main.tscn'deki MenuCamera'nın dönüşümü (menü kadrajı; geri çekilmenin başı).
static func _menu_transform() -> Transform3D:
	var state := (load("res://scenes/main.tscn") as PackedScene).get_state()
	for i in state.get_node_count():
		if state.get_node_name(i) != &"MenuCamera":
			continue
		for p in state.get_node_property_count(i):
			if state.get_node_property_name(i, p) == &"transform":
				return state.get_node_property_value(i, p)
	return Transform3D.IDENTITY


static func _xz(p: Vector3) -> Vector2:
	return Vector2(p.x, p.z)


## Paylaşılan dünyadan bir düğüm alır; yoksa testi başarısız sayar ve null döndürür.
func _require(path: NodePath) -> Node:
	var node: Node = null
	if _world:
		node = _world.get_node_or_null(path)
	if node == null:
		fail("Dünyada beklenen düğüm yok: %s" % path)
	return node


## Ses sunucusu durdurulan sesleri (ör. ateş çıtırtısı) kendi iş parçacığında kısa süre sonra bırakır;
## beklemeden çıkılırsa test süreci kapanırken "sızıntı" uyarısı yazılır.
func _settle_audio() -> void:
	await get_tree().create_timer(0.2).timeout
	await wait_frames(2)


## Sahneye elle eklenmiş Node3D'ler (betiklerin ürettiği parçalar hariç).
static func _authored_nodes(root: Node) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for child in root.get_children():
		if child.has_meta(&"generated"):
			continue
		if child is Node3D:
			result.append(child)
		result.append_array(_authored_nodes(child))
	return result


## Düğümün altındaki tüm MultiMesh örneklerinin toplamı.
static func _multimesh_instances(root: Node) -> int:
	var total := 0
	for node in root.find_children("*", "MultiMeshInstance3D", true, false):
		var mm := (node as MultiMeshInstance3D).multimesh
		if mm:
			total += mm.instance_count
	return total


## Merkezi p'nin (x, z) 1 cm yakınında olan ve yarıçapı en az min_radius olan bir engel dairesi var mı?
static func _has_circle_at(circles: Array[Vector3], p: Vector3, min_radius: float) -> bool:
	for c in circles:
		if Vector2(c.x - p.x, c.y - p.z).length() < 0.01 and c.z >= min_radius:
			return true
	return false


## Her yerde aynı yükseklikte düz zemin (test için sahte arazi).
static func _flat(level: float) -> TerrainShape:
	var shape := _FlatShape.new()
	shape.level = level
	return shape


class _FlatShape extends TerrainShape:
	var level := 0.0

	func height_at(_x: float, _z: float) -> float:
		return level


## x yönünde %200 eğimli yamaç.
class _SlopeShape extends TerrainShape:
	func height_at(x: float, _z: float) -> float:
		return x * 2.0


## x = 100 çevresinde 60 m genişliğinde bir su kanalı, iki yanı kuru.
class _ChannelShape extends TerrainShape:
	func river_at(_z: float) -> Vector2:
		return Vector2(100.0, 30.0)

	func height_at(x: float, _z: float) -> float:
		return TerrainShape.WATER_LEVEL - 5.0 if absf(x - 100.0) < 30.0 else TerrainShape.WATER_LEVEL + 3.0


## Hata iletilerini toplayan günlükçü (Godot hata yazdığında _log_error çağrılır; uyarılar hariç).
## Koşucu, test içindeki betik hatalarını başarısızlık saymadığı için "hata yazılmadı" sözü böyle sınanır.
class _ErrorLog extends Logger:
	var _mutex := Mutex.new()
	var _messages := PackedStringArray()

	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		_mutex.lock()
		_messages.append(rationale if not rationale.is_empty() else code)
		_mutex.unlock()

	## Toplanan iletiler.
	func take() -> PackedStringArray:
		_mutex.lock()
		var result := _messages
		_mutex.unlock()
		return result
