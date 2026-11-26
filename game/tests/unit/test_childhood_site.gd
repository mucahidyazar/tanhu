extends TestCase
## Çocukluk'un oynanış yerleri (ChildhoodSite, OrdosWorld'ün Çocukluk yüzü; story.md §5; Yol Haritası childhood-world): düzenin ölçüleri, doğumun görmemesi,
## kare bütçeli kurulum, ağıl ve kapı çarpışması, yürünür alan, kamera sınırı, ışık, çizim üst sınırı ve bırakınca sızıntı olmaması. Childhood düğümü dünya
## kurulurken yoktur: doğum Çocukluk'a özgü olanları görmez. Bozkırın kendisi (yükselti, kaya, çalı) aynı otlaktır: doğum da görür, Çocukluk'unkiyle aynıdır.

const SCENE := "res://scenes/maps/childhood_ordos.tscn"
const LAYOUT := "res://data/maps/childhood_ordos/layout.json"
const READY_TIMEOUT := 90.0
const FRAME_MS := 1000.0 / 60.0
## İç harita bütçesi (K63; godot.md §7.2) ve yönlü ışığın gölge bölümü.
const VISIBLE_DRAWS := 900
const SHADOW_DRAWS := 500
const SHADOW_SPLITS := 2
## Oyuncunun çarpışma yarıçapı (PlayerController).
const BODY := 0.3
const WALK_STEP := 0.05

var _world: OrdosWorld
var _baseline_nodes := -1
var _baseline_orphans := -1


# --- Düzen (saf) ------------------------------------------------------------------------------------

func test_distances_follow_the_story() -> void:
	# story.md §5: yurttan ağıla 40 m yürüyüş, taşa 40 m yarış.
	var layout := OrdosWorld.load_layout(LAYOUT)
	var d: Dictionary = layout["childhood"]
	assert_almost(ChildhoodSite.race_length(d), 40.0, 1.0, "Yarış yolu 40 m")
	var race: Array = d["race"]["path"]
	var stone := OrdosGround._vec2(d["stone"]["at"])
	assert_true(OrdosGround._vec2(race[race.size() - 1]).distance_to(stone) < 1.0, "Yol taşta biter")
	var door := OrdosGround._vec2(layout["markers"]["lan_door"])
	var gate := OrdosGround._vec2(d["markers"]["pen_gate"])
	var home: Array = d["paths"]["home"]["points"]
	var walk := door.distance_to(OrdosGround._vec2(home[0])) + ChildhoodSite.polyline_length(home) + OrdosGround._vec2(home[home.size() - 1]).distance_to(gate)
	assert_almost(walk, 40.0, 2.5, "Yurdun kapısından ağıla ≈40 m iz (%.1f m)" % walk)
	assert_almost(float(d["pen"]["gate_az"]), 90.0, 0.001, "Ağılın kapısı da doğuya bakar")
	assert_eq(int(d["herd"]["count"]), 40, "40 koyun")
	var line: Dictionary = d["herd"]["line"]
	var count_point := OrdosGround._vec2(line["route"][int(line["count_at"])])
	assert_true(count_point.distance_to(OrdosGround._vec2(layout["markers"]["counter"])) < 5.0, "Sayım noktası sayıcının önünde")


func test_everything_stands_inside_the_walk_area() -> void:
	var layout := OrdosWorld.load_layout(LAYOUT)
	var d: Dictionary = layout["childhood"]
	var center := OrdosGround._vec2(d["walk_area"]["center"])
	var radius := float(d["walk_area"]["radius"])
	var half := OrdosGround._vec2(layout["size"]) * 0.5
	assert_true(absf(center.x) + radius <= half.x and absf(center.y) + radius <= half.y, "Yürünür alan haritanın içinde")
	# E21 (K110): yürünür alan kampın dairesi ve göle, Ebe Obası'na giden ek dairelerdir (walk_area.extra).
	for id: String in d["markers"]:
		assert_true(ChildhoodSite.in_walk_area(layout, OrdosGround._vec2(d["markers"][id]), 2.0), "%s yürünür alanda" % id)
	var pen := OrdosGround._vec2(d["pen"]["at"])
	assert_true(pen.distance_to(center) + float(d["pen"]["radius"]) <= radius, "Ağıl yürünür alanda")
	for group: Dictionary in d["game"]["groups"]:
		for p: Array in group["patches"]:
			assert_true(Vector2(float(p[0]), float(p[1])).distance_to(center) + float(p[2]) <= radius, "%s lekesi yürünür alanda" % group["kind"])
	var meadow: Dictionary = d["herd"]["meadow"]
	assert_true(OrdosGround._vec2(meadow["center"]).distance_to(center) + float(meadow["radius"]) <= radius, "Çayır yürünür alanda")
	# Ağıl ve çayır yurtlardan, sayım ipinden ve birbirinden ayrıdır.
	for id: String in layout["places"]:
		var place: Dictionary = layout["places"][id]
		var at := OrdosGround._vec2(place["at"])
		assert_true(at.distance_to(pen) > float(d["pen"]["radius"]) + float(place["radius"]) + 2.0, "%s ağıldan ayrı" % id)
		assert_true(at.distance_to(OrdosGround._vec2(meadow["center"])) > float(meadow["radius"]) + float(place["radius"]), "%s çayırdan ayrı" % id)
	var a := OrdosGround._vec2(layout["counting_line"]["from"])
	var b := OrdosGround._vec2(layout["counting_line"]["to"])
	var mid := OrdosGround._vec2(meadow["center"])
	assert_true(Geometry2D.get_closest_point_to_segment(mid, a, b).distance_to(mid) > float(meadow["radius"]) + 2.0, "Çayır ipten ayrı")


func test_zones_fit_the_ground_shader() -> void:
	var layout := OrdosWorld.load_layout(LAYOUT)
	var merged := ChildhoodSite.merged_spec(layout)
	assert_true((merged["trampled"]["circles"] as Array).size() <= OrdosWorld.MAX_CIRCLES, "Daireler gölgelendiricinin dizisine sığar")
	assert_true((merged["trampled"]["trails"] as Array).size() <= OrdosWorld.MAX_TRAILS, "İzler gölgelendiricinin dizisine sığar")
	assert_eq((merged["flats"] as Array).slice(0, (layout["flats"] as Array).size()), layout["flats"], "Doğumun düz yerleri aynı, Çocukluk'unkiler eklenir")
	assert_eq((layout["trampled"]["circles"] as Array).size(), 6, "Doğumun çiğnenmiş toprağı değişmez")
	assert_eq((layout["trampled"]["trails"] as Array).size(), 5, "Doğumun izleri değişmez")
	var base := OrdosGround.new(layout)
	var with_zones := OrdosGround.new(merged)
	for p: Vector2 in [Vector2(0.0, 0.0), Vector2(-40.0, 60.0), Vector2(30.0, -5.0)]:
		assert_almost(base.height_at(p.x, p.y), with_zones.height_at(p.x, p.y), 0.00001, "Düz yerin dışında yükseklik aynı (%s)" % p)


func test_grass_avoids_the_pen_and_the_patches() -> void:
	var layout := OrdosWorld.load_layout(LAYOUT)
	var spec := ChildhoodSite.merged_spec(layout)
	var g: Dictionary = (layout["childhood"]["grass"] as Dictionary).duplicate()
	g["count"] = 4000
	spec["grass"] = g
	var blockers := ChildhoodSite.grass_blockers(layout)
	var buffers := OrdosWorld.grass_buffers(spec, blockers)
	var pen := OrdosGround._vec2(layout["childhood"]["pen"]["at"])
	var radius := float(layout["childhood"]["pen"]["radius"])
	var total := 0
	for key: Vector3i in buffers:
		var a: PackedFloat32Array = buffers[key]
		for i in range(0, a.size(), OrdosWorld.FLOATS_PER_TUFT):
			total += 1
			var p := Vector2(a[i + 3], a[i + 11])
			assert_true(p.distance_to(pen) > radius, "Ot ağılda yok (%s)" % p)
			assert_false(Scatter.is_blocked(p.x, p.y, blockers), "Ot lekede yok (%s)" % p)
		if failures.size() > 3:
			return
	assert_true(total > 1000, "Çayır otlu (%d)" % total)


func test_relief_keeps_birth_places_and_makes_steps() -> void:
	# Çocukluk'un yükseltisi doğumun düğümlerini oynatmaz (yurtlar, sayım kazıkları, işaretler); kademe, tepe ve dere gerçekten yükselti verir.
	var layout := OrdosWorld.load_layout(LAYOUT)
	var baked := ChildhoodGround.bake(layout)
	assert_false(baked.is_empty(), "Pişer")
	var base := OrdosGround.new(layout)
	var child := OrdosGround.new(ChildhoodSite.baked_spec(layout, baked))
	var spots: Array[Vector2] = []
	for id: String in layout["places"]:
		var at := OrdosGround._vec2(layout["places"][id]["at"])
		var r := float(layout["places"][id]["radius"])
		for k in 8:
			spots.append(at + Vector2.from_angle(TAU * float(k) / 8.0) * r)
		spots.append(at)
	for id: String in layout["markers"]:
		spots.append(OrdosGround._vec2(layout["markers"][id]))
	var a := OrdosGround._vec2(layout["counting_line"]["from"])
	var b := OrdosGround._vec2(layout["counting_line"]["to"])
	for k in 11:
		spots.append(a.lerp(b, float(k) / 10.0))
	for p in spots:
		assert_almost(child.height_at(p.x, p.y), base.height_at(p.x, p.y), 0.01, "Doğumun yeri oynamaz (%s)" % p)
	# Kademe: yüzün iki yanında ≥1 m fark (doğudaki büyük kademe).
	var scarp: Dictionary = layout["childhood"]["ground"]["scarps"][0]
	var line := ChildhoodGround.Line.new(scarp["points"], scarp)
	var mid: Array = ChildhoodScatter._point_along(line, line.total * 0.5)
	var dir: Vector2 = mid[1]
	var side := Vector2(-dir.y, dir.x)
	var hi := child.height_at(mid[0].x + side.x * 5.0, mid[0].y + side.y * 5.0)
	var lo := child.height_at(mid[0].x - side.x * 5.0, mid[0].y - side.y * 5.0)
	assert_true(absf(hi - lo) >= 1.0, "Kademe yükselti verir (%.2f m)" % absf(hi - lo))
	# Tepe ve dere.
	var hill: Array = layout["childhood"]["ground"]["hills"][1]
	assert_true(child.height_at(float(hill[0]), float(hill[1])) - base.height_at(float(hill[0]), float(hill[1])) > 1.5, "Tepe yükselir")
	var gully: Dictionary = layout["childhood"]["ground"]["gullies"][0]
	var g := OrdosGround._vec2(gully["points"][3])
	assert_true(child.height_at(g.x, g.y) - base.height_at(g.x, g.y) < -0.3, "Dere çukurdur")
	# Maske: derenin tabanı kum, kademenin yüzü çakıl.
	var m := ChildhoodGround.mask_at(baked["mask"], g.x, g.y)
	assert_true(m.y > 0.5, "Dere tabanı kum (%s)" % m)
	var gravel := 0.0
	for k in 13:
		var q: Vector2 = mid[0] + side * (float(k) * 0.5 - 3.0)
		gravel = maxf(gravel, ChildhoodGround.mask_at(baked["mask"], q.x, q.y).z)
	assert_true(gravel > 0.3, "Kademenin yüzü çakıl (%.2f)" % gravel)


## İki MultiMesh tamponu aynı yerde mi (yükseklik, yani dönüşümün y'si dışında aynı)?
static func _same_place(a: PackedFloat32Array, b: PackedFloat32Array, stride: int) -> bool:
	if a.size() != b.size():
		return false
	for k in a.size():
		if k % stride == 7:
			continue
		if absf(a[k] - b[k]) > 0.0001:
			return false
	return true


func test_k98_frame_holds_the_places() -> void:
	# K98: eğim 38°, görüş 36°, 40 m; frame_center odağında kuzeye bakışta yurt, ağıl, yarış yolu, taş ve sayım hattı aynı karede.
	var layout := OrdosWorld.load_layout(LAYOUT)
	var d: Dictionary = layout["childhood"]
	var focus2 := OrdosGround._vec2(d["markers"]["frame_center"])
	var focus := Vector3(focus2.x, 0.7, focus2.y)
	var xform := FollowCamera.compute_transform(focus, 0.0, 38.0, 40.0)
	var inv := xform.affine_inverse()
	var tan_v := tan(deg_to_rad(18.0))
	var tan_h := tan_v * 16.0 / 9.0
	var pen := OrdosGround._vec2(d["pen"]["at"])
	var points := {
		"lan_yurt": OrdosGround._vec2(layout["places"]["lan_yurt"]["at"]),
		"pen_west": pen + Vector2(-float(d["pen"]["radius"]), 0.0),
		"pen_south": pen + Vector2(0.0, float(d["pen"]["radius"])),
		"race_start": OrdosGround._vec2(d["race"]["path"][0]),
		"stone": OrdosGround._vec2(d["stone"]["at"]),
		"line_north": OrdosGround._vec2(layout["counting_line"]["from"]),
		"line_south": OrdosGround._vec2(layout["counting_line"]["to"]),
	}
	for id: String in points:
		var p: Vector2 = points[id]
		var c := inv * Vector3(p.x, 0.0, p.y)
		assert_true(c.z < 0.0, "%s kameranın önünde" % id)
		assert_true(absf(c.x / -c.z) <= tan_h and absf(c.y / -c.z) <= tan_v, "%s 40 m kadrajda (%.2f, %.2f)" % [id, c.x / -c.z, c.y / -c.z])


func test_clamp_to_bounds() -> void:
	var bounds := Rect2(-10.0, -10.0, 20.0, 20.0)
	var focus := Vector3(0.0, 1.0, 0.0)
	var inside := FollowCamera.compute_transform(focus, 0.0, 23.35, 5.0)
	assert_eq(OrdosWorld.clamp_to_bounds(inside, focus, bounds), inside, "Sınırın içinde değişmez")
	var outside := FollowCamera.compute_transform(Vector3(0.0, 1.0, 9.0), 0.0, 23.35, 27.0)
	var clamped := OrdosWorld.clamp_to_bounds(outside, Vector3(0.0, 1.0, 9.0), bounds)
	assert_true(bounds.has_point(Vector2(clamped.origin.x, clamped.origin.z)) or is_equal_approx(clamped.origin.z, 10.0), "Kutuda kalır")
	assert_almost(clamped.origin.y, outside.origin.y, 0.0001, "Yükseklik değişmez")
	assert_true((-clamped.basis.z).dot((Vector3(0.0, 1.0, 9.0) - clamped.origin).normalized()) > 0.999, "Odağa bakar")


func test_default_camera_never_touches_the_bounds() -> void:
	# Varsayılan 27 m kadrajda sınır görünmez; en uzak 40 m kadrajda kenarda içeri çekilir, odak kadrajda kalır.
	var layout := OrdosWorld.load_layout(LAYOUT)
	var d: Dictionary = layout["childhood"]
	var bounds := ChildhoodSite.bounds_rect(d)
	var center := OrdosGround._vec2(d["walk_area"]["center"])
	var radius := float(d["walk_area"]["radius"])
	for k in 72:
		var edge := center + Vector2.from_angle(TAU * float(k) / 72.0) * radius
		var focus := Vector3(edge.x, 0.7, edge.y)
		for yaw_k in 24:
			var yaw := TAU * float(yaw_k) / 24.0
			var near := FollowCamera.compute_transform(focus, yaw, FollowCamera.DEFAULT_PITCH_DEG, FollowCamera.DEFAULT_DISTANCE)
			assert_eq(OrdosWorld.clamp_to_bounds(near, focus, bounds), near, "27 m kadraj sınıra değmez (%s, %d°)" % [edge, yaw_k * 15])
			var far := FollowCamera.compute_transform(focus, yaw, FollowCamera.DEFAULT_PITCH_DEG + 6.0, 40.0)
			var clamped := OrdosWorld.clamp_to_bounds(far, focus, bounds)
			assert_true(clamped.origin.x >= bounds.position.x - 0.001 and clamped.origin.x <= bounds.end.x + 0.001, "x sınırda")
			assert_true(clamped.origin.z >= bounds.position.y - 0.001 and clamped.origin.z <= bounds.end.y + 0.001, "z sınırda")
		if failures.size() > 2:
			return


func test_blend_samples_moves_the_sun() -> void:
	var samples := SkyRig.load_samples(OrdosWorld.CHILDHOOD_LIGHT)
	var a: Dictionary = samples["morning"]
	var b: Dictionary = samples["late"]
	assert_almost(float((a["sun"] as Dictionary)["el"]), 29.9, 1.0, "08:40'ta güneş ≈30°")
	assert_almost(float((a["sun"] as Dictionary)["az"]), 118.0, 2.0, "08:40'ta güneş doğu güneydoğuda")
	assert_true(float((b["sun"] as Dictionary)["el"]) > 45.0, "11:00'de güneş yüksek")
	var mid := OrdosWorld.blend_samples(a, b, 0.5)
	assert_almost(float(mid["minute"]), 590.0, 0.001, "Dakika ortada")
	assert_almost(float(mid["light_energy"]), (float(a["light_energy"]) + float(b["light_energy"])) * 0.5, 0.001, "Enerji ortada")
	assert_true(float((mid["sun"] as Dictionary)["el"]) > float((a["sun"] as Dictionary)["el"]), "Güneş yükselir")
	assert_true(mid["light_color"] is Color, "Renk çözülür")
	assert_true((mid["sky"] as Dictionary)["zenith"] is Color, "Gök rengi çözülür")


# --- Dünya ------------------------------------------------------------------------------------------

func test_birth_never_sees_the_childhood() -> void:
	var world := await _get_world()
	if world == null:
		return
	assert_null(world.get_node_or_null(^"Childhood"), "Doğumda Çocukluk düğümü yok")
	assert_null(world.childhood())
	assert_false(world.is_childhood_ready())
	assert_false(world.is_childhood_mode())
	assert_eq(get_tree().get_nodes_in_group(SmallGame.GROUP).size(), 0, "Doğumda hedef yok")
	var grass := world.get_node(^"Ground/Grass") as Node3D
	assert_true(grass.visible, "Doğumun otu görünür")
	var layer := world.get_node(^"Ground/Trampled") as MeshInstance3D
	var mat := layer.material_override as ShaderMaterial
	assert_eq(int(mat.get_shader_parameter(&"trampled_circle_count")), 6, "Doğumun çiğnenmiş toprağı")
	for path in ["Ground/Terrain", "Ground/Rocks", "Ground/Shrubs"]:
		assert_true((world.get_node(NodePath(path)) as Node3D).visible, "Doğumun bozkırı görünür: %s" % path)
	assert_eq(str(world.get_sky_rig().current_sample().get("id", "")), "inside", "Doğumun ışığı")


func test_prepare_builds_hidden_and_mode_shows() -> void:
	var world := await _get_world()
	if world == null:
		return
	var rig := world.get_sky_rig()
	var terrain_mat := (world.get_node(^"Ground/Terrain") as MeshInstance3D).material_override as ShaderMaterial
	var birth_mask: Variant = terrain_mat.get_shader_parameter(&"mask_tex")
	var layer_mat := (world.get_node(^"Ground/Trampled") as MeshInstance3D).material_override as ShaderMaterial
	var ember := world.hearth().get_node(^"EmberLight") as OmniLight3D
	var spill := world.place("lan_yurt").get_node(^"DoorSpill") as Light3D
	var sun := world.get_node(^"SunLight") as DirectionalLight3D
	var sun_angular := sun.light_angular_distance
	assert_true(ember.shadow_enabled and spill.visible, "Doğumun ışıkları açık")
	var ready := watch_signal(world.childhood_ready)
	var site := world.prepare_childhood()
	assert_not_null(site, "prepare_childhood kurmaya başlar")
	if site == null:
		return
	assert_eq(world.prepare_childhood(), site, "İkinci çağrı aynı site")
	assert_false(site.visible, "Hazırlanırken gizli")
	var deadline := Time.get_ticks_msec() + int(READY_TIMEOUT * 1000.0)
	while not world.is_childhood_ready() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	assert_true(world.is_childhood_ready(), "Kurulum biter")
	assert_true(ready.fired, "childhood_ready yayılır")
	print("    [childhood] kurulum: en uzun kare %.2f ms (%d kare), hazır %.0f ms; iş parçacığı %s; adımlar %s" % [site.build_stats["max_frame_ms"], site.build_stats["frames"], site.build_stats["ready_ms"], site.build_stats["jobs_ms"], site.build_stats["steps"]])
	assert_false(site.visible, "Mod açılmadan görünmez")
	assert_eq(site.process_mode, Node.PROCESS_MODE_DISABLED, "Gizliyken sürü ve av koşmaz")
	assert_true((world.get_node(^"Ground/Grass") as Node3D).visible, "Doğumun otu hâlâ görünür")
	assert_eq(str(rig.current_sample().get("id", "")), "inside", "Işık değişmez")
	assert_eq(world.get_terrain_shape(), world.steppe, "Mod açılmadan yüz doğumun bozkırı")
	# Aç.
	world.set_childhood_mode(true)
	assert_true(world.is_childhood_mode())
	assert_true(site.visible, "Mod açılınca görünür")
	for path in ["Terrain", "Trampled", "Grass", "Rocks", "Shrubs", "Props/TripodPot", "Props/WoodPile", "Pen/Fence", "Pen/Wattle", "Pen/Gate/Leaf", "Pen/Gate/LeafWattle", "Stone", "Marks/Cairns", "Marks/Flags", "Herd/Sheep", "SmallGame/Burrows"]:
		assert_not_null(site.get_node_or_null(NodePath(path)), "Eksik düğüm: %s" % path)
	assert_false((world.get_node(^"Ground/Grass") as Node3D).visible, "Doğumun otu yerini verir")
	assert_false((world.get_node(^"Ground/Trampled") as Node3D).visible, "Doğumun toprağı yerini verir")
	assert_false((world.get_node(^"Ground/Terrain") as Node3D).visible, "Doğumun zemini yerini verir")
	assert_false((world.get_node(^"Ground/Rocks") as Node3D).visible, "Doğumun kayası yerini verir")
	assert_false((world.get_node(^"Ground/Shrubs") as Node3D).visible, "Doğumun çalısı yerini verir")
	assert_eq(world.get_terrain_shape(), site.ground, "Oyuncunun yüzü Çocukluk'un yüzü")
	assert_eq(int(layer_mat.get_shader_parameter(&"trampled_circle_count")), 6, "Doğumun zeminine dokunulmaz")
	assert_eq(terrain_mat.get_shader_parameter(&"mask_tex"), birth_mask, "Doğumun zemininin maskesi aynı")
	# Aynı otlak: Çocukluk'un yüzü bozkırınkiyle aynı yükseklikte, kaya ve çalı aynı yerde. E21 (K110): Çocukluk'un yükseltisi göle ve obaya
	# dek pişer; doğumun ızgarasının kenarında (18 m) doğumunki sıfıra iner, Çocukluk'unki inmez: kaya ve çalı aynı yerde (x, z, yön, boy),
	# yüksekliği kendi zeminindedir. Göle ve obaya giden yolların satırları (e21_region) yalnız Çocukluk'tadır.
	for p: Vector2 in [Vector2(66.0, -18.0), Vector2(40.0, -6.0), Vector2(-40.0, -10.0), Vector2(20.0, 40.0), Vector2(4.8, 2.7)]:
		assert_almost(site.ground.height_at(p.x, p.y), world.steppe.height_at(p.x, p.y), 0.00001, "Çocukluk'un yüzü bozkırınkiyle aynı (%s)" % p)
	for group in ["Rocks", "Shrubs"]:
		var mine: Array[Node] = []
		for node in site.get_node(NodePath(group)).get_children():
			if not node.has_meta(&"e21_region"):
				mine.append(node)
		var birth := world.get_node(NodePath("Ground/" + group)).get_children()
		assert_eq(mine.size(), birth.size(), "%s: aynı MultiMesh'ler" % group)
		var stride := ChildhoodScatter.ROCK_FLOATS if group == "Rocks" else ChildhoodScatter.SHRUB_FLOATS
		for i in mini(mine.size(), birth.size()):
			var a := (mine[i] as MultiMeshInstance3D).multimesh.buffer
			var b := (birth[i] as MultiMeshInstance3D).multimesh.buffer
			assert_true(_same_place(a, b, stride), "%s/%d aynı yerde" % [group, i])
	assert_true(int(site.scatter_counts.get("rocks", 0)) > 150, "Kaya öbekleri (%d)" % int(site.scatter_counts.get("rocks", 0)))
	assert_true(int(site.scatter_counts.get("shrubs", 0)) > 200, "Çalı (%d)" % int(site.scatter_counts.get("shrubs", 0)))
	assert_eq(str(rig.current_sample().get("id", "")), "morning", "08:40'ın ışığı")
	assert_almost(sun.light_energy, float(rig.current_sample()["light_energy"]), 1e-5, "Işığı SkyRig yazar")
	assert_false(ember.shadow_enabled, "Gündüz közün gölgesi kapalı")
	assert_false(spill.visible, "Gündüz kapı ışığı kapalı")
	assert_true(get_tree().get_nodes_in_group(SmallGame.GROUP).size() >= 20, "Hedefler «targets» grubunda")
	# Kapat: doğumun görüntüsüne tam dönüş.
	world.set_childhood_mode(false)
	assert_false(site.visible)
	assert_eq(site.process_mode, Node.PROCESS_MODE_DISABLED)
	assert_true((world.get_node(^"Ground/Grass") as Node3D).visible, "Ot geri gelir")
	assert_true((world.get_node(^"Ground/Trampled") as Node3D).visible, "Toprak geri gelir")
	assert_true((world.get_node(^"Ground/Terrain") as Node3D).visible, "Zemin geri gelir")
	assert_true((world.get_node(^"Ground/Rocks") as Node3D).visible and (world.get_node(^"Ground/Shrubs") as Node3D).visible, "Kaya ve çalı geri gelir")
	assert_eq(world.get_terrain_shape(), world.steppe, "Yüz doğumun bozkırı")
	assert_eq(str(rig.current_sample().get("id", "")), "inside", "Doğumun ışığı geri gelir")
	assert_true(ember.shadow_enabled and spill.visible, "Yurdun ışıkları geri gelir")
	assert_almost(sun.light_angular_distance, sun_angular, 1e-5, "Gölgenin yumuşaklığı geri gelir")
	world.set_childhood_mode(true)


func test_mode_before_world_ready_waits() -> void:
	# Dünya kurulurken istenirse kurulum bitince başlar ve görünür; hata yazmaz.
	var extra := (load(SCENE) as PackedScene).instantiate() as OrdosWorld
	add_child(extra)
	extra.set_childhood_mode(true)
	assert_false(extra.is_childhood_ready(), "Henüz hazır değil")
	var deadline := Time.get_ticks_msec() + int(READY_TIMEOUT * 1000.0)
	while not extra.is_childhood_ready() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	assert_true(extra.is_childhood_ready(), "Hazır olur")
	assert_true(extra.childhood().visible, "Görünür")
	assert_false((extra.get_node(^"Ground/Grass") as Node3D).visible, "Ot yerini verir")
	extra.queue_free()
	await wait_frames(2)


func test_building_keeps_the_frame_budget() -> void:
	# godot.md §4.3: ana iş parçacığında kare başına ≤4 ms dilim; en uzun kare bir kareyi aşmamalı. Isınmış ikinci kurulum, üçün en iyisi (başka işlerin sıçraması).
	var world := await _get_world()
	if world == null:
		return
	var best := INF
	for attempt in 3:
		var site := ChildhoodSite.new()
		site.visible = false
		world.add_child(site)
		site.start(world)
		var deadline := Time.get_ticks_msec() + int(READY_TIMEOUT * 1000.0)
		while not site.is_ready() and Time.get_ticks_msec() < deadline:
			await get_tree().process_frame
		assert_true(site.is_ready(), "Kurulum biter")
		print("    [childhood] ılık kurulum %d: en uzun kare %.2f ms (%d kare), hazır %.0f ms" % [attempt + 1, site.build_stats["max_frame_ms"], site.build_stats["frames"], site.build_stats["ready_ms"]])
		best = minf(best, float(site.build_stats["max_frame_ms"]))
		site.queue_free()
		await wait_frames(2)
		if best <= FRAME_MS:
			break
	assert_true(best <= FRAME_MS, "Kurulumun her karesi bir kareyi aşmamalı (%.2f ms)" % best)


func test_places_stand_on_the_ground() -> void:
	var world := await _ready_world()
	if world == null:
		return
	var layout := world.layout
	var d: Dictionary = layout["childhood"]
	var shape := world.get_terrain_shape()
	for id: String in d["markers"]:
		var at := OrdosGround._vec2(d["markers"][id])
		var p := world.marker(id)
		assert_almost(p.x, at.x, 0.0001, "%s x" % id)
		assert_almost(p.z, at.y, 0.0001, "%s z" % id)
		assert_almost(p.y, shape.height_at(at.x, at.y), 0.0001, "%s zemine oturur" % id)
	assert_eq(world.marker("cradle"), world.get_node(^"Markers/Cradle").global_position, "Doğumun işaretleri aynı")
	assert_eq(world.marker("yok"), Vector3.INF, "Bilinmeyen işaret")
	var site := world.childhood()
	# Kapı kanadı: kapalıyken öbür dikmeye uzanır.
	site.set_gate_open(false, true)
	var gate := site.get_node(^"Pen/Gate") as Node3D
	var pen: Dictionary = d["pen"]
	var dir := HerdSim.azimuth_vector(float(pen["gate_az"]))
	var center := OrdosGround._vec2(pen["at"])
	var width := float(pen["gate_width"])
	var radius := float(pen["radius"])
	var latch := gate.global_transform * Vector3(width - 0.14, 0.0, 0.0)
	var other := center + dir * radius * cos(asin(width * 0.5 / radius)) + Vector2(-dir.y, dir.x) * (width * 0.5)
	assert_true(Vector2(latch.x, latch.z).distance_to(other) < 0.2, "Kanat kapı aralığını örter (%.2f m)" % Vector2(latch.x, latch.z).distance_to(other))
	site.set_gate_open(true, true)
	var open_latch := gate.global_transform * Vector3(width - 0.14, 0.0, 0.0)
	assert_true((Vector2(open_latch.x, open_latch.z) - center).dot(dir) > radius, "Kanat dışarı açılır")
	site.set_gate_open(false, true)
	# Çit ve taş üçgen bütçesinde.
	var fence := site.get_node(^"Pen/Fence") as MeshInstance3D
	assert_true(Probe.mesh_triangles(fence.mesh) <= 6000, "Çit hafif (%d üçgen)" % Probe.mesh_triangles(fence.mesh))
	assert_true(Probe.mesh_triangles((site.get_node(^"Stone") as MeshInstance3D).mesh) <= 2000, "Taş hafif")
	# Kaya ve çalı izde, ağılda ve yurtların dibinde durmaz.
	var spec := ChildhoodSite.merged_spec(layout)
	var trail_shape := OrdosGround.new(spec)
	var pen_at := OrdosGround._vec2(pen["at"])
	for mmi in site.find_children("*", "MultiMeshInstance3D", true, false):
		if not (String(mmi.name).begins_with("Rocks") or String(mmi.name).begins_with("Shrubs")):
			continue
		var mm := (mmi as MultiMeshInstance3D).multimesh
		var stride := ChildhoodScatter.ROCK_FLOATS if String(mmi.name).begins_with("Rocks") else ChildhoodScatter.SHRUB_FLOATS
		var b: PackedFloat32Array = mm.buffer
		for k in range(0, b.size(), stride):
			var q := Vector2(b[k + 3], b[k + 11])
			assert_true(trail_shape.trampled_distance(q) > 0.0, "%s izde değil (%s)" % [mmi.name, q])
			assert_true(q.distance_to(pen_at) > radius + 1.0, "%s ağılda değil (%s)" % [mmi.name, q])
			if failures.size() > 3:
				return


func test_fence_and_gate_stop_the_player() -> void:
	var world := await _ready_world()
	if world == null:
		return
	var site := world.childhood()
	var d: Dictionary = world.layout["childhood"]
	var center := OrdosGround._vec2(d["pen"]["at"])
	var radius := float(d["pen"]["radius"])
	var dir := HerdSim.azimuth_vector(float(d["pen"]["gate_az"]))
	# Kapı kapalı: dışarıdan içeri giremez, içeriden çıkamaz.
	site.set_gate_open(false, true)
	var end := _walk(world, center + dir * (radius + 5.0), center)
	assert_true(end.distance_to(center) > radius, "Kapalı kapıdan girilmez (%.2f m)" % end.distance_to(center))
	end = _walk(world, center + dir * 2.0, center + dir * (radius + 5.0))
	assert_true(end.distance_to(center) < radius, "Kapalı kapıdan çıkılmaz (%.2f m)" % end.distance_to(center))
	# Kapı açık: girilir; çitin öbür yanından girilemez.
	site.set_gate_open(true, true)
	end = _walk(world, center + dir * (radius + 5.0), center + dir * 1.0)
	assert_true(end.distance_to(center + dir * 1.0) < 0.2, "Açık kapıdan girilir")
	end = _walk(world, center - dir * (radius + 5.0), center)
	assert_true(end.distance_to(center) > radius, "Çitten geçilmez (%.2f m)" % end.distance_to(center))
	end = _walk(world, center + dir * 1.0, center - dir * (radius + 5.0))
	assert_true(end.distance_to(center) < radius, "İçeriden de çitten geçilmez")
	site.set_gate_open(false, true)


func test_yurts_and_stone_stop_the_player() -> void:
	var world := await _ready_world()
	if world == null:
		return
	var layout := world.layout
	for id in ["teoman_otag", "kin_yurt_a"]:
		var at := OrdosGround._vec2(layout["places"][id]["at"])
		var r := float(layout["places"][id]["radius"])
		var end := _walk(world, at + Vector2(r + 5.0, 0.0), at)
		assert_true(end.distance_to(at) >= r, "%s içinden geçilmez (%.2f m)" % [id, end.distance_to(at)])
	var stone := OrdosGround._vec2(layout["childhood"]["stone"]["at"])
	var end := _walk(world, stone + Vector2(-4.0, 0.0), stone)
	assert_true(end.distance_to(stone) >= float(layout["childhood"]["stone"]["radius"]), "Taşın içinden geçilmez")
	# Lan Hatun'un yurdu: kapıdan çıkılır, duvardan çıkılmaz.
	var yurt := OrdosGround._vec2(layout["places"]["lan_yurt"]["at"])
	var door := HerdSim.azimuth_vector(float(layout["places"]["lan_yurt"]["door_az"]))
	end = _walk(world, yurt + door * 1.2, yurt + door * 6.0)
	assert_true(end.distance_to(yurt + door * 6.0) < 0.2, "Kapıdan çıkılır")
	end = _walk(world, yurt - door * 1.0, yurt - door * 7.0)
	assert_true(end.distance_to(yurt) < 3.1, "Duvardan çıkılmaz (%.2f m)" % end.distance_to(yurt))
	end = _walk(world, yurt + door * 6.0, yurt + door * 1.4)
	assert_true(end.distance_to(yurt + door * 1.4) < 0.2, "Kapıdan girilir")


func test_play_area_and_camera_bounds() -> void:
	var world := await _ready_world()
	if world == null:
		return
	var area := world.play_area()
	assert_almost(float(area["radius"]), float(world.layout["childhood"]["walk_area"]["radius"]), 0.001, "Yürünür alan")
	assert_true(area["center"] is Vector2)
	assert_almost(float(area["soft_edge"]), 3.0, 0.001)
	var bounds := world.camera_bounds()
	var focus := Vector3(50.0, 1.0, 60.0)
	var far := FollowCamera.compute_transform(focus, 0.0, 29.35, 40.0)
	var clamped := world.clamp_camera_transform(far, focus)
	assert_true(clamped.origin.z <= bounds.end.y + 0.001, "Kamera sınırda")


func test_herd_and_game_run_with_the_mode() -> void:
	var world := await _ready_world()
	if world == null:
		return
	var site := world.childhood()
	var herd := site.herd
	assert_eq(herd.count(), 40)
	assert_eq(herd.phase(), HerdSim.Phase.PEN, "Sürü ağılda başlar")
	assert_false(site.gate_is_open(), "Kapı kapalı başlar")
	assert_true(herd.is_processing(), "Mod açıkken sürü işler")
	site.release_herd()
	assert_true(site.gate_is_open(), "release_herd kapıyı açar")
	assert_eq(herd.phase(), HerdSim.Phase.LEAVING)
	await wait_frames(3)
	site.drive_herd()
	assert_eq(herd.phase(), HerdSim.Phase.DRIVING)
	site.reset_herd()
	assert_eq(herd.phase(), HerdSim.Phase.PEN)
	assert_false(site.gate_is_open(), "reset_herd kapıyı kapatır")
	# Oyuncuyla konuşan yüz: tehdit ve hedefler.
	var game := site.game
	assert_true(game.animals().size() >= 20, "Küçük av kurulur")
	var threat := Node3D.new()
	add_child(threat)
	game.set_threat(threat)
	var lark: SmallGame = game.of_kind("lark")[0]
	threat.global_position = lark.global_position
	for i in 16:
		await get_tree().process_frame
		if lark.state != SmallGame.State.FORAGE and lark.state != SmallGame.State.WALK:
			break
		await get_tree().create_timer(0.02).timeout
	assert_eq(lark.state, SmallGame.State.FLIGHT, "Tehditten uçar")
	game.set_threat(null)
	threat.queue_free()


func test_childhood_time_moves_the_light() -> void:
	var world := await _ready_world()
	if world == null:
		return
	var rig := world.get_sky_rig()
	var sun := world.get_node(^"SunLight") as DirectionalLight3D
	world.set_childhood_time(OrdosWorld.CHILDHOOD_END_MINUTE)
	var late_el := float((rig.current_sample()["sun"] as Dictionary)["el"])
	assert_true(late_el > 45.0, "11:00'de güneş yüksek (%.1f°)" % late_el)
	var late_y := -sun.global_basis.z.y
	world.set_childhood_time(OrdosWorld.CHILDHOOD_START_MINUTE)
	assert_true(float((rig.current_sample()["sun"] as Dictionary)["el"]) < late_el, "08:40'ta alçak")
	assert_true(-sun.global_basis.z.y > late_y, "Işık sabah daha yatık (ışığın yönü)")


func test_draw_budget_upper_bound() -> void:
	# Başsız sürücü çizmez: kırpma olmadan çizilebilecek her yüzey sayılır (görünür ≤900, gölge ≤500; K63). Gerçek ölçüm budget_probe'dadır.
	var world := await _ready_world()
	if world == null:
		return
	var visible := 0
	var shadow := 0
	for node in world.find_children("*", "GeometryInstance3D", true, false):
		var gi := node as GeometryInstance3D
		if not gi.is_visible_in_tree():
			continue
		var surfaces := _surface_count(gi)
		visible += surfaces
		if gi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			shadow += surfaces * SHADOW_SPLITS
	print("    [childhood] çizim üst sınırı: görünür %d, gölge %d" % [visible, shadow])
	assert_true(visible <= VISIBLE_DRAWS, "Görünür çizim üst sınırı ≤%d (%d)" % [VISIBLE_DRAWS, visible])
	assert_true(shadow <= SHADOW_DRAWS, "Gölge çizimi üst sınırı ≤%d (%d)" % [SHADOW_DRAWS, shadow])


## Paylaşılan dünyayı bırakır (sahne testlerinin sonuncusu): düğüm, öksüz düğüm ve hedef kalmaz.
func test_freeing_leaves_nothing_behind() -> void:
	var world := await _ready_world()
	if world == null:
		return
	world.queue_free()
	_world = null
	world = null
	await get_tree().create_timer(0.3).timeout
	await wait_frames(3)
	var nodes := int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var orphans := int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	assert_true(nodes <= _baseline_nodes, "Düğüm sayısı başa döner (%d → %d)" % [_baseline_nodes, nodes])
	assert_true(orphans <= _baseline_orphans, "Öksüz düğüm kalmaz (%d → %d)" % [_baseline_orphans, orphans])
	assert_eq(get_tree().get_nodes_in_group(SmallGame.GROUP).size(), 0, "Hedef kalmaz")
	assert_eq(get_tree().get_nodes_in_group(SmallGame.FALLEN_GROUP).size(), 0, "Düşen av kalmaz")
	assert_eq(get_child_count(), 0, "Sınamanın altında düğüm kalmaz")


# --- Yardımcılar ------------------------------------------------------------------------------------

const Probe := preload("res://scripts/dev/budget_probe.gd")


func _get_world() -> OrdosWorld:
	if is_instance_valid(_world):
		return _world
	_baseline_nodes = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	_baseline_orphans = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	var node := (load(SCENE) as PackedScene).instantiate() as OrdosWorld
	add_child(node)
	_world = node
	var deadline := Time.get_ticks_msec() + int(READY_TIMEOUT * 1000.0)
	while not _world.is_ready() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	return _world if _world.is_ready() else null


## Çocukluk'u açık, hazır dünya.
func _ready_world() -> OrdosWorld:
	var world := await _get_world()
	if world == null:
		return null
	world.set_childhood_mode(true)
	var deadline := Time.get_ticks_msec() + int(READY_TIMEOUT * 1000.0)
	while not world.is_childhood_ready() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	return world if world.is_childhood_ready() else null


## Yürüyüş: oyuncunun kurallarıyla (daireler, kutular, duvarlar en son; PlayerController.step) from'dan to'ya düz çizgide.
func _walk(world: OrdosWorld, from: Vector2, to: Vector2) -> Vector2:
	var circles := world.collect_obstacles()
	var walls := world.collect_walls()
	var boxes := world.collect_boxes()
	var p := from
	var count := int(from.distance_to(to) / WALK_STEP)
	var dir := (to - from).normalized()
	for _i in count:
		var next := p + dir * WALK_STEP
		for c in circles:
			var center := Vector2(c.x, c.y)
			var min_dist := c.z + BODY
			if next.distance_to(center) < min_dist:
				next = center + (next - center).normalized() * min_dist
		for b in boxes:
			next = b.push_out(next, BODY)
		for w in walls:
			next = w.resolve(p, next, BODY)
		p = next
	return p


static func _surface_count(gi: GeometryInstance3D) -> int:
	if gi is MeshInstance3D:
		var mesh := (gi as MeshInstance3D).mesh
		return mesh.get_surface_count() if mesh else 0
	if gi is MultiMeshInstance3D:
		var mm := (gi as MultiMeshInstance3D).multimesh
		return mm.mesh.get_surface_count() if mm and mm.mesh and mm.instance_count > 0 else 0
	return 1
