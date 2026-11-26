extends TestCase
## Keçe aplike panolar (Yol Haritası myth-panels; story.md §3 satır 1–6, godot.md §3.6):
##   - FeltShapes: her şekil üreticisi kapalı, kendini kesmeyen, saat yönünün tersindeki dış hat verir ve üçgenlenir.
##   - FeltPanel: her katmana bir ağ ve felt_panel malzemesi kurar; dikiş şeridinin UV'si dolu (yay uzunluğu ve 0 → 1);
##     panolarda kullanılan her şeklin iç halkası dış hattın içinde kalır ve kendini kesmez; kancalar (belirme, yol,
##     yörünge, parıltı) saate göre uygulanır; warp gerçek saati yazılan saate çevirir.
##   - myth_panels.json: altı pano, her panoda en az bir katman, gpt-image-2 istemi, satırlar ve müzik durumu.
##   - prologue_myth.tscn: altı pano düğümü, panel_1–panel_6 canlandırmaları, ember_node; on_shot segment
##     çizelgesindeki bütün pano çekimlerini tanır; restore iz bırakmaz; sahne hata yazmadan kurulur (günlükçü).
##   - Keçe dokusu (Fabric034, CC0) içe aktarılmış ve işaretli; pano dokularının belleği ≤20 MiB.
## Sahne kendi dünyası olan bir SubViewport'ta kurulur (CineHost'un overlay'i gibi): sınamanın dünyasına dokunmaz.
## Keçe yolu sınanır (K93): CineVideo.enabled kapalıdır, gerçek video dosyası geldiğinde de bu sınamalar keçeyi kurar; video kipi test_cine_video.gd'de.

const SCENE := "res://scenes/cine/prologue_myth.tscn"
const SEGMENT := "res://data/cine/prologue_myth.json"
const SHADER := "res://shaders/felt_panel.gdshader"
## Pano dokularının bellek tavanı (plan: ≤20 MiB).
const TEXTURE_CAP := 20 * 1024 * 1024

var _trash: Array[Node] = []


func before_each() -> void:
	Engine.time_scale = 1.0
	CineVideo.enabled = false


func after_each() -> void:
	for node in _trash:
		if is_instance_valid(node):
			node.queue_free()
	_trash.clear()
	CineVideo.enabled = true
	Engine.time_scale = 1.0


# --- FeltShapes ----------------------------------------------------------------------------------

func test_every_shape_is_closed_simple_and_triangulates() -> void:
	var sizes := [{}, {"size": 0.4}, {"size": 2.0}]
	for kind in FeltShapes.KINDS:
		for p: Dictionary in sizes:
			var outlines := FeltShapes.make(kind, p)
			assert_false(outlines.is_empty(), "%s dış hat vermeli" % kind)
			for outline in outlines:
				_assert_simple(outline, "%s %s" % [kind, p])
	assert_true(FeltShapes.make("yok_boyle_bir_sekil").is_empty(), "Bilinmeyen şekil boş döner")
	assert_eq(FeltShapes.make("ring").size(), 2, "Çember iki yaydır (iki keçe parçası dikişle birleşir)")


func test_stitch_width_follows_the_thinnest_part() -> void:
	assert_almost(FeltShapes.recommended_stitch("rect", {"w": 5.2, "h": 2.8}), FeltShapes.STITCH, 0.0001, "Geniş parçada istenen genişlik")
	assert_true(FeltShapes.recommended_stitch("tree9", {"size": 1.3}) < 0.012, "İnce dallı ağaçta dar şerit")
	assert_true(FeltShapes.recommended_stitch("bridge", {"t": 0.022}) <= 0.022 * 0.35 + 0.0001, "Köprünün kılı")
	assert_true(FeltShapes.recommended_stitch("bridge", {"t": 0.001}) >= FeltShapes.STITCH_MIN, "En dar şerit STITCH_MIN")


func test_panel_layers_have_clean_inner_rings() -> void:
	var count := 0
	var flat: Array[String] = []
	for panel: Dictionary in FeltPanel.panel_defs():
		for layer: Dictionary in panel.get("layers", []):
			var kind := str(layer.get("shape", ""))
			if kind == FeltPanel.PIVOT:
				continue
			var p: Dictionary = layer.get("p", {})
			var outlines := FeltShapes.make(kind, p)
			if bool(layer.get("mirror", false)):
				outlines = FeltPanel.mirrored(outlines)
			var stitch := FeltShapes.recommended_stitch(kind, p, float(FeltPanel.data().get("stitch", FeltShapes.STITCH)))
			for outline in outlines:
				var where := "%s/%s" % [panel.get("id", "?"), layer.get("id", "?")]
				_assert_simple(outline, where)
				count += 1
				var inner := FeltPanel.inner_ring(outline, stitch)
				if inner.is_empty():
					flat.append(where)
					continue
				assert_false(FeltShapes.self_intersects(inner), "%s: iç halka kendini kesmemeli" % where)
				assert_false(Geometry2D.triangulate_polygon(inner).is_empty(), "%s: iç halka üçgenlenmeli" % where)
				var outside := 0
				for q in inner:
					if not Geometry2D.is_point_in_polygon(q, outline):
						outside += 1
				assert_eq(outside, 0, "%s: iç halka dış hattın içinde kalmalı" % where)
	assert_true(count > 60, "Panoların bütün katmanları denetlendi (%d)" % count)
	# Şeritsiz (düz) kalan parça yalnız çok küçük olanlardır: Yedi Karakçı'nın yıldızları gibi.
	assert_true(flat.size() <= 10, "Dikiş şeridi panoların hemen her parçasında var; şeritsiz: %s" % [flat])


# --- FeltPanel -----------------------------------------------------------------------------------

func test_felt_panel_builds_a_mesh_and_the_felt_material_for_every_layer() -> void:
	var shader := load(SHADER) as Shader
	for i in FeltPanel.panel_defs().size():
		var panel := FeltPanel.new()
		panel.panel_index = i + 1
		var box := _world_box()
		box.add_child(panel)
		var def: Dictionary = FeltPanel.panel_defs()[i]
		var expected := 0
		for layer: Dictionary in def.get("layers", []):
			if str(layer.get("shape", "")) != FeltPanel.PIVOT:
				expected += 1
		var meshes := panel.meshes()
		assert_eq(meshes.size(), expected, "%s: her katmana bir ağ" % def.get("id"))
		for mi in meshes:
			assert_not_null(mi.mesh, "%s: ağ kurulmalı" % mi.name)
			var mat := mi.material_override as ShaderMaterial
			assert_true(mat != null and mat.shader == shader, "%s: felt_panel malzemesi" % mi.name)
			if FeltPanel.uses_free_texture():
				assert_eq(mi.get_meta(&"free_asset", ""), FeltPanel.FREE_ASSET, "%s: ücretsiz keçe dokusu işaretli (K89)" % mi.name)


func test_stitch_band_uvs_run_along_the_edge() -> void:
	var outline := FeltShapes.make("stone", {"r": 0.4, "seed": 3})[0]
	var mesh := FeltPanel.build_mesh([outline], 0.03)
	assert_not_null(mesh)
	var arrays := mesh.surface_get_arrays(0)
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var uv2s: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV2]
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	assert_eq(uvs.size(), verts.size(), "Her köşenin UV'si var")
	assert_eq(uv2s.size(), verts.size(), "Her köşenin UV2'si (yerel m) var")
	var perimeter := 0.0
	for i in outline.size():
		perimeter += outline[i].distance_to(outline[(i + 1) % outline.size()])
	var max_x := 0.0
	var outer := 0
	var inner := 0
	for i in uvs.size():
		max_x = maxf(max_x, uvs[i].x)
		if is_zero_approx(uvs[i].y):
			outer += 1
			assert_almost(verts[i].z, 0.0, 0.0001, "Şeridin dış kenarı keçenin altında (z = 0)")
		elif is_equal_approx(uvs[i].y, 1.0):
			inner += 1
	assert_almost(max_x, perimeter, 0.001, "Şeridin UV.x'i dış hat boyunca yay uzunluğudur")
	assert_eq(outer, outline.size() + 1, "Dış halka (ilk köşe sonda yinelenir: dikiş sıfıra dönmez)")
	assert_true(inner > outline.size(), "İç halka ve dolgu UV.y = 1")
	# Ön yüz kameraya (+z) bakar: Godot'da saat yönündeki üçgen; dolgunun normalleri +z.
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var a := verts[indices[0]]
	var b := verts[indices[1]]
	var c := verts[indices[2]]
	assert_true((b - a).cross(c - a).z < 0.0, "Üçgenler kameradan bakınca saat yönünde")


func test_hooks_follow_the_panel_clock_and_warp() -> void:
	var panel := FeltPanel.new()
	panel.panel = {"id": "deneme", "layers": [
		{"id": "a", "shape": "circle", "p": {"r": 0.2}, "pos": [0, 0], "z": 0.1,
			"anim": [{"type": "appear", "t0": 1.0, "t1": 2.0}, {"type": "move", "keys": [[2.0, 0.0, 0.0], [4.0, 1.0, 0.5]]}]},
		{"id": "b", "shape": "horse", "p": {"size": 0.4}, "z": 0.2,
			"anim": [{"type": "orbit", "center": [0, 1], "radius": [1.0, 0.5], "period": 8.0, "phase": 0.0, "t0": 0.0, "face": true}]},
		{"id": "c", "shape": "circle", "z": 0.3, "emission": 0.5, "anim": [{"type": "glow", "keys": [[0.0, 0.5], [2.0, 3.0]]}]},
		{"id": "p", "shape": "pivot", "pos": [1, 1], "anim": [{"type": "rotate", "keys": [[0, 0], [10, 90]]}]},
		{"id": "q", "parent": "p", "shape": "star", "pos": [0.5, 0], "z": 0.0}]}
	_world_box().add_child(panel)
	panel.anim_time = 0.5
	assert_false(panel.layer_node("a").visible, "Belirmeden önce görünmez")
	panel.anim_time = 3.0
	var a := panel.layer_node("a")
	assert_true(a.visible)
	assert_vec_almost(a.position, Vector3(0.5, 0.25, 0.1), 0.001, "Yolun ortası (yumuşak ara değer)")
	panel.anim_time = 2.0
	var b := panel.layer_node("b")
	assert_vec_almost(b.position, Vector3(0.0, 1.5, 0.2), 0.001, "Yörüngenin çeyreği (8 sn'de bir tur)")
	assert_almost(panel.layer_node("c").get_instance_shader_parameter(&"emission"), 3.0, 0.001, "Parıltı anahtarı")
	panel.anim_time = 10.0
	var q := panel.layer_node("q")
	assert_vec_almost(q.global_position - panel.global_position, Vector3(1.0, 1.5, 0.05), 0.001, "Dönme noktasının çocuğu onunla döner")
	# Warp: gerçek 0–10 sn, yazılan 0–5 sn (satır uzadı): gerçek 6 sn yazılan 3 sn'dir.
	panel.warp = [[0.0, 0.0], [10.0, 5.0], [12.0, 7.0]]
	assert_almost(panel.written_time(6.0), 3.0, 0.0001)
	assert_almost(panel.written_time(13.0), 8.0, 0.0001, "Uçtan sonra eğim 1")
	assert_almost(panel.real_time(3.0), 6.0, 0.0001, "Ters eşleme")
	assert_almost(panel.real_time(panel.written_time(11.0)), 11.0, 0.0001)


func test_image_panel_switches_the_base_to_the_texture() -> void:
	# gpt-image-2 görseli gelince (bugün kota dolu): zemin görseli taşır, kodla şekiller kurulmaz, köz kalır.
	var def: Dictionary = (FeltPanel.panel_defs()[5] as Dictionary).duplicate(true)
	def["image"] = FeltPanel.FELT_ALBEDO
	var panel := FeltPanel.new()
	panel.panel = def
	_world_box().add_child(panel)
	assert_true(panel.has_image())
	var ids: Array[String] = []
	for layer_id: String in panel.layers:
		ids.append(layer_id)
	assert_eq(ids, ["base", "ember"] as Array[String], "Görselli panoda zemin ve köz kalır")
	var mat := panel.layer_node("base").material_override as ShaderMaterial
	assert_true(bool(mat.get_shader_parameter(&"use_albedo_texture")), "Zemin görseli taşır")
	assert_ne(mat, FeltPanel.felt_material(), "Görselli zeminin kendi malzemesi (öbür panolar etkilenmez)")
	assert_ne(FeltPanel.felt_material().get_shader_parameter(&"use_albedo_texture"), true, "Ortak keçe malzemesi değişmez")
	def["image_only"] = false
	var both := FeltPanel.new()
	both.panel = def
	_world_box().add_child(both)
	assert_true(both.layers.size() > 2, "image_only false: görsel zeminde, şekiller üstünde")


func test_mirror_keeps_the_front_face() -> void:
	var outlines := FeltPanel.mirrored(FeltShapes.make("horse"))
	assert_true(FeltShapes.signed_area(outlines[0]) > 0.0, "Aynalanan dış hat yine saat yönünün tersinde")
	assert_true(outlines[0][0].x < 0.4, "x ekseninde çevrildi")


func test_felt_shader_parses_and_reads_time_from_world_time() -> void:
	var shader := load(SHADER) as Shader
	# Başsız sürücü gölgelendiriciyi derlemez ama ayrıştırır: tekdüzen listesi istenince hata varsa SHADER ERROR yazılır.
	var names: Array[String] = []
	for u: Dictionary in shader.get_shader_uniform_list(true):
		names.append(str(u["name"]))
	for wanted in ["use_textures", "felt_albedo", "felt_normal", "felt_scale", "use_albedo_texture", "albedo_texture",
			"stitch_period", "border_color", "panel_spacing", "light_wrap"]:
		assert_true(names.has(wanted), "felt_panel.gdshader tekdüzeni: %s" % wanted)
	var code := shader.code
	assert_false(code.contains("TIME"), "Zaman tn_time()'dan okunur (world_time; kararlı kare)")
	assert_true(code.contains("tn_time()"))
	assert_false(FileAccess.get_file_as_string("res://shaders/felt.gdshader").contains("instance uniform"), "Yurdun keçesine dokunulmadı")


# --- Veri ------------------------------------------------------------------------------------------

func test_myth_panels_data_has_six_panels_and_prompts() -> void:
	var defs := FeltPanel.panel_defs()
	assert_eq(defs.size(), 6, "Altı pano (story.md §3 satır 1–6)")
	var bank := MusicBank.load_def("prologue_myth")
	for i in defs.size():
		var def: Dictionary = defs[i]
		assert_eq(def.get("id"), "panel_%d" % (i + 1))
		assert_true((def.get("layers", []) as Array).size() >= 1, "%s: en az bir katman" % def["id"])
		var prompt := str(def.get("prompt", ""))
		assert_true(prompt.length() > 200 and prompt.containsn("felt"), "%s: gpt-image-2 istemi yazılı" % def["id"])
		assert_true(MusicBank.clip_index(bank, StringName(str(def.get("state", "")))) != -1, "%s: müzik durumu bankada" % def["id"])
		for line_id: Variant in def.get("lines", []):
			assert_true(VoLines.has_line(str(line_id)), "%s: satır %s" % [def["id"], line_id])
		var image: Variant = def.get("image")
		assert_true(image == null or ResourceLoader.exists(str(image)), "%s: görsel yoksa null" % def["id"])
		assert_true(str(def.get("catalog", "")).begins_with("fx_panel_"), "%s: Varlıklar kataloğundaki kimliği (görselin adı)" % def["id"])
	var lines: Array = []
	for def: Dictionary in defs:
		lines.append_array(def.get("lines", []))
	var want: Array = []
	for n in range(3, 26):
		want.append("act0.myth.%d" % n)
	assert_eq(lines, want, "Panoların satırları 3–25, sırayla")
	assert_eq(str(defs[5].get("ember", "")), "ember", "Son panonun közü")
	# Panoların içeriği story.md §3'ün satırlarıdır.
	assert_eq(_shape_count(defs[0], "goose"), 2, "Pano 1: iki kara kaz")
	assert_true(_shape_count(defs[0], "wave_band") >= 3, "Pano 1: yalnız su")
	assert_eq(_shape_count(defs[1], "stone"), 1, "Pano 2: sudan çıkan taş")
	assert_eq(_shape_count(defs[2], "tree9"), 1, "Pano 3: dokuz dallı ağaç")
	assert_eq(_shape_count(defs[2], "human"), 9, "Pano 3: dokuz insan")
	assert_eq(_shape_count(defs[2], "shadow"), 1, "Pano 3: yüzü olmayan karanlık biçim")
	assert_eq(_shape_count(defs[3], "horse"), 2, "Pano 4: Kök Boz At ve Ak Boz At")
	assert_eq(_shape_count(defs[3], "star"), 7, "Pano 4: Yedi Karakçı")
	assert_eq(_shape_count(defs[3], "stake"), 1, "Pano 4: tündükte dönmeyen nokta (Demir Kazık)")
	assert_true(_shape_count(defs[4], "river") == 1 and _shape_count(defs[4], "bridge") == 1, "Pano 5: ırmak (Doymadım) ve at kılından köprü")
	assert_eq(_shape_count(defs[4], "spark"), 1, "Pano 5: kıvılcım")
	assert_eq(_shape_count(defs[5], "yurt"), 2, "Pano 6: doğum yurdu (dış ve iç)")
	assert_eq(_shape_count(defs[5], "bundle"), 1, "Pano 6: eşin bohçası (yalnız keçe yedeğinde; söz söylemez)")
	var hearth := 0
	for layer: Dictionary in defs[4]["layers"]:
		if str(layer["id"]).begins_with("hearth_"):
			hearth += 1
	assert_eq(hearth, 3, "Pano 5: üç ocak taşı")
	var pts := FeltShapes.tree9()
	assert_true(pts.size() > 60, "Ağacın dış hattı dokuz dalı ve yaprak öbeklerini taşır")


func test_felt_texture_is_imported_small_and_marked() -> void:
	assert_true(FeltPanel.uses_free_texture(), "Fabric034 içe aktarılmış: malzeme keçe dokusunu kullanır")
	var total := 0
	for path in [FeltPanel.FELT_ALBEDO, FeltPanel.FELT_NORMAL]:
		var cfg := ConfigFile.new()
		assert_eq(cfg.load(path + ".import"), OK, "%s.import" % path)
		assert_eq(cfg.get_value("params", "compress/mode"), 2, "%s VRAM sıkıştırmalı" % path)
		assert_eq(cfg.get_value("params", "process/size_limit"), 1024, "%s 1K" % path)
		assert_eq(cfg.get_value("params", "mipmaps/generate"), true)
		for file: String in cfg.get_value("deps", "dest_files", []):
			total += FileAccess.get_file_as_bytes(file).size()
	var normal := ConfigFile.new()
	normal.load(FeltPanel.FELT_NORMAL + ".import")
	assert_eq(normal.get_value("params", "compress/normal_map"), 1, "Normal haritası BC5 (RGTC)")
	assert_true(total > 0 and total <= TEXTURE_CAP, "Pano dokuları %.2f MiB (tavan 20 MiB)" % (total / 1048576.0))


# --- Sahne -----------------------------------------------------------------------------------------

func test_scene_has_six_panels_animations_and_ember() -> void:
	var scene := _scene()
	scene.setup({})
	assert_eq(scene.panel_nodes().size(), 6, "Altı pano düğümü")
	for i in 6:
		var panel := scene.panel_node(i + 1)
		assert_almost(panel.position.x, 6.0 * i, 0.001, "Pano %d şeritte x = %d × 6 m" % [i + 1, i])
		assert_true(scene.player.has_animation(StringName("panel_%d" % (i + 1))), "panel_%d canlandırması" % (i + 1))
		var anim := scene.player.get_animation(StringName("panel_%d" % (i + 1)))
		assert_almost(anim.length, scene.panel_lengths[i], 0.001, "Canlandırma panonun süresi kadar")
	assert_not_null(scene.ember_node, "ember_node")
	assert_true(scene.ember_node.is_inside_tree() and scene.panel_node(6).is_ancestor_of(scene.ember_node), "Köz son panoda")
	var band := scene.get_node(^"Strip/Band") as MeshInstance3D
	assert_not_null(band.mesh, "Uzun keçe şerit")
	assert_eq(band.get_instance_shader_parameter(&"pattern"), 1, "Şeridin bordür süsü")
	assert_eq(scene.get_node(^"GooseHonk").get_meta(&"free_asset", ""), PrologueMyth.GOOSE_FREE_ASSET, "Ücretsiz kaz kaydı işaretli")
	var env := (scene.get_node(^"WorldEnvironment") as WorldEnvironment).environment
	assert_false(env.fog_enabled, "Sis yok")
	assert_true(env.glow_enabled, "Köz ve kıvılcım parlar")
	var lights := scene.find_children("*", "DirectionalLight3D", true, false)
	assert_eq(lights.size(), 2, "İki ışık")


func test_on_shot_plays_every_panel_shot_of_the_segment() -> void:
	var scene := _scene()
	scene.setup({})
	var timeline := CineTimeline.from_path(SEGMENT)
	var shots: Array[String] = []
	for ev in timeline.events_of("shot"):
		shots.append(str(ev["name"]))
	assert_eq(shots, ["panel_1", "panel_2", "panel_3", "panel_4", "panel_5", "panel_6"] as Array[String], "Segmentin çekimleri")
	var cam_x := -1.0e9
	for ev in timeline.events_of("shot"):
		scene.on_shot(str(ev["name"]), ev)
		assert_eq(String(scene.player.current_animation), str(ev["name"]), "%s oynamalı" % ev["name"])
		scene.player.seek(scene.player.current_animation_length, true)
		assert_true(scene.camera.position.x > cam_x, "Kamera şeritte ilerler (%s)" % ev["name"])
		cam_x = scene.camera.position.x
	var last := scene.panel_node(6)
	assert_almost(last.anim_time, scene.panel_lengths[5], 0.01, "Son panonun saati sona vardı")
	assert_true(scene.ember_node.get_instance_shader_parameter(&"emission") > 2.5, "Son karede keçe köz parlar")
	scene.on_shot("wide", {})
	assert_eq(String(scene.player.assigned_animation), "panel_6", "Bilinmeyen çekim yok sayılır")


func test_camera_frames_each_panel_and_its_key_pieces() -> void:
	var scene := _scene()
	scene.setup({})
	for i in 6:
		var anim := StringName("panel_%d" % (i + 1))
		scene.player.play(anim)
		var length := scene.player.current_animation_length
		for k in 21:
			var t := length * k / 20.0
			scene.player.seek(minf(t, length - 0.001), true)
			var x := scene.camera.position.x
			if t >= PrologueMyth.TRANSIT:
				assert_between(x, 6.0 * i - 0.6, 6.0 * i + 0.6, "%s: kamera panoda kalır (t %.1f, x %.2f)" % [anim, t, x])
			else:
				assert_between(x, 6.0 * (i - 1) - 0.6, 6.0 * i + 0.6, "%s: geçiş iki pano arasında (t %.1f, x %.2f)" % [anim, t, x])
	# Anlatının ana parçaları anlatıldıkları anda kadrajda (yazılan saatle).
	var shots := [[1, 19.1, ["kayra", "kishi"]], [2, 6.94, ["kayra", "kishi", "stone"]], [3, 44.7, ["tree", "erlik", "light", "person_9"]],
		[4, 3.9, ["stake", "kok_boz", "ak_boz", "star_1", "star_7", "crown"]], [4, 6.15, ["earth", "man_4"]],
		[5, 16.64, ["erlik", "river", "bridge"]], [5, 31.26, ["white_stone", "black_stone", "spark"]], [5, 36.8, ["flame", "hearth_2"]],
		[6, 19.79, ["al_karisi", "hearth_1", "door"]], [6, 25.3, ["bundle"]], [6, 29.4, ["ember"]]]
	for shot: Array in shots:
		var panel := scene.panel_node(int(shot[0]))
		var anim := StringName("panel_%d" % shot[0])
		scene.player.play(anim)
		scene.player.seek(minf(panel.real_time(float(shot[1])), scene.player.current_animation_length - 0.001), true)
		for layer_id: String in shot[2]:
			var node := panel.layer_node(layer_id) as MeshInstance3D
			assert_true(node != null and node.is_visible_in_tree(), "%s: %s görünür" % [anim, layer_id])
			if node:
				assert_true(_on_screen(scene.camera, node) > 0.5, "%s: %s kadrajda (%.0f%%)" % [anim, layer_id, _on_screen(scene.camera, node) * 100.0])


func test_restore_leaves_no_trace() -> void:
	var main_camera := get_viewport().get_camera_3d()
	var main_world := get_viewport().world_3d
	var main_env: Environment = main_world.environment if main_world else null
	var scene := _scene()
	scene.setup({})
	scene.on_shot("panel_3", {})
	scene.on_event({"type": "cue", "sfx": "felt_flap", "db": -12.0})
	scene.restore()
	assert_false(scene.player.is_playing(), "restore canlandırmayı durdurur")
	assert_true(scene.sounds.is_empty())
	assert_eq(get_viewport().get_camera_3d(), main_camera, "Ana görünümün kamerası değişmez")
	assert_eq(get_viewport().world_3d, main_world, "Ana dünya değişmez")
	assert_eq(main_world.environment if main_world else null, main_env, "Ana ortam değişmez")
	assert_eq(Engine.time_scale, 1.0)
	assert_eq(get_viewport().disable_3d, false)


func test_ember_screen_position_is_inside_the_view() -> void:
	var scene := _scene()
	scene.setup({})
	scene.on_shot("panel_6", {})
	scene.player.seek(scene.player.current_animation_length, true)
	var at := scene.ember_screen_position()
	assert_between(at.x, 0.2, 0.8, "Köz son karede ortaya yakın (x)")
	assert_between(at.y, 0.2, 0.9, "Köz son karede görünür (y)")


# --- Yardımcılar ---------------------------------------------------------------------------------

func _assert_simple(outline: PackedVector2Array, where: String) -> void:
	assert_true(outline.size() >= 3, "%s: en az üç köşe" % where)
	if outline.size() < 3:
		return
	assert_true(outline[0].distance_to(outline[outline.size() - 1]) > 1e-6, "%s: kapalı (son nokta ilkini yinelemez)" % where)
	assert_true(FeltShapes.signed_area(outline) > 0.0, "%s: saat yönünün tersinde, alanı artı" % where)
	assert_false(FeltShapes.self_intersects(outline), "%s: kendini kesmemeli" % where)
	var tris := Geometry2D.triangulate_polygon(outline)
	assert_eq(tris.size(), (outline.size() - 2) * 3, "%s: üçgenlenmeli" % where)


## Panodaki bir şekil türünün katman sayısı.
static func _shape_count(def: Dictionary, kind: String) -> int:
	var n := 0
	for layer: Dictionary in def.get("layers", []):
		if str(layer.get("shape", "")) == kind:
			n += 1
	return n


## Ağın kutusunun ekranda kalan payı (0..1).
static func _on_screen(camera: Camera3D, node: MeshInstance3D) -> float:
	var size := camera.get_viewport().get_visible_rect().size
	var aabb := node.get_aabb()
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for k in 8:
		var p := camera.unproject_position(node.global_transform * aabb.get_endpoint(k))
		lo = lo.min(p)
		hi = hi.max(p)
	var area := maxf((hi.x - lo.x) * (hi.y - lo.y), 1e-6)
	return Rect2(Vector2.ZERO, size).intersection(Rect2(lo, hi - lo)).get_area() / area


## Kendi dünyası olan bir SubViewport (CineHost'un overlay'i gibi): sahnenin kamerası ve ortamı orada kalır.
func _world_box() -> SubViewport:
	var box := SubViewport.new()
	box.own_world_3d = true
	box.size = Vector2i(320, 180)
	box.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(box)
	_trash.append(box)
	return box


func _scene() -> PrologueMyth:
	var scene := (load(SCENE) as PackedScene).instantiate() as PrologueMyth
	_world_box().add_child(scene)
	return scene
