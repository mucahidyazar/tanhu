extends SceneTree
## Dailin kalabalığının kart atlası (T3 kart kademesi; army.md §7.1, §7.4; godot.md §4.5; story.md §5 «uzaktaki sayım kalabalığı kart
## kademesindedir»): kalabalık modellerinden (crowd_hun_man, crowd_hun_woman, crowd_hun_rider) pişirilir, 0 kredi. Her kişi 8 yönden
## (45°'de bir; 0 = kamera önde), oyun kamerasının eğiminde (40°) dik izdüşümle çizilir; kareler: bekleme ve 4 yürüyüş evresi. İki atlas:
##   dailin_cards.png         renk ve alfa (yalnız ortam ışığıyla: karakterin dokusu, mürekkebi ve ince konturu; ışık oyunda verilir)
##   dailin_cards_normal.png  görüş uzayı normali (r, g, b = n × 0,5 + 0,5): kartın gölgelendiricisi karakterlerin cel ışığını bununla verir
##   dailin_cards.json        ızgara, hücre ölçüsü (piksel ve metre), ayağın yeri, yönler, kareler, yürüyüş adımının boyu
## Hücre index = varyant × (yön × kare) + kare × yön + yön; satır satır cols sütun. Her hücre önce iki kat büyük çizilir, alfayla
## ağırlıklı küçültülür (kenar yumuşak, koyu hale yok); saydam piksellerin rengi komşudan doldurulur (mip kenarı kararmaz). İçe aktarma
## VRAM sıkıştırmalı ve mipli (BC7; .import), oyunun öteki dokuları gibi.
## Çalıştırma (pencere gerekir, kum havuzu dışında; araç kendini kapatır):
##   /Applications/Godot.app/Contents/MacOS/Godot --path . --resolution 640x360 -s res://tools/bake_crowd_cards.gd

const OUT_DIR := "res://assets/crowd/"
const OUT_NAME := "dailin_cards"
const VARIANTS: Array[String] = ["crowd_hun_man", "crowd_hun_woman", "crowd_hun_rider"]
const DIRS := 8
## Kareler: bekleme, sonra yürüyüş klibinin dört evresi.
const FRAMES: Array[String] = ["idle", "walk0", "walk1", "walk2", "walk3"]
const CELL := Vector2i(128, 256)
const SUPER := 2
const COLS := 16
## Hücrenin dünya ölçüsü (m; en, boy) ve ayağın hücredeki yeri (alttan oran).
const CELL_M := Vector2(1.1, 2.2)
const PIVOT := 0.18
## Kameranın eğimi (derece; oyunun takip kamerası 38–44°).
const ELEVATION := 40.0
## Pişirmenin yürüme hızı (m/sn; kalabalığın yürüyüşü).
const WALK_SPEED := 1.3
## Konturun en ince kalınlığı (piksel; pişirme çözünürlüğünde): küçültülünce ince, koyu bir kenar kalır.
const OUTLINE_MIN_PX := 4.0

const NORMAL_CODE := """
shader_type spatial;
render_mode unshaded, cull_back;
vec3 to_linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}
void fragment() {
	// Görüş uzayı normali; çıktı sRGB'ye çevrileceği için önce doğrusala alınır: dosyada tam n × 0,5 + 0,5 kalır.
	ALBEDO = to_linear(normalize(NORMAL) * 0.5 + 0.5);
}
"""

var _vp: SubViewport
var _camera: Camera3D
var _holder: Node3D
var _normal_mat: ShaderMaterial


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var rows := ceili(float(VARIANTS.size() * DIRS * FRAMES.size()) / COLS)
	var atlas_px := Vector2i(COLS * CELL.x, rows * CELL.y)
	var albedo := Image.create_empty(atlas_px.x, atlas_px.y, false, Image.FORMAT_RGBA8)
	var normal := Image.create_empty(atlas_px.x, atlas_px.y, false, Image.FORMAT_RGBA8)
	albedo.fill(Color(0.0, 0.0, 0.0, 0.0))
	normal.fill(Color(0.5, 0.5, 1.0, 0.0))
	_setup_stage()
	var cycles := {}
	for v in VARIANTS.size():
		var id := VARIANTS[v]
		var avatar := CharacterAvatar.new()
		avatar.model_override = id
		_holder.add_child(avatar)
		for i in 4:
			await process_frame
		if not avatar.has_meshy_model():
			push_error("[bake_crowd_cards] model yok: %s" % id)
			quit(1)
			return
		_thicken_outline(avatar)
		var anim := avatar.get_animation_player()
		avatar.play_walk(WALK_SPEED)
		avatar.snap_transition()
		var walk_clip := String(anim.current_animation)
		var walk_len := anim.get_animation(walk_clip).length if anim.has_animation(walk_clip) else 1.0
		cycles[id] = snappedf(avatar.clip_speed(&"walk") * walk_len, 0.001)
		for f in FRAMES.size():
			if FRAMES[f] == "idle":
				avatar.set_locomotion(0.0)
				avatar.snap_transition()
				anim.seek(0.35, true)
			else:
				avatar.play_walk(WALK_SPEED)
				avatar.snap_transition()
				anim.seek(walk_len * float(f - 1) / 4.0, true)
			anim.pause()
			for i in 2:
				await process_frame
			for d in DIRS:
				_place_camera(d)
				var index := (v * FRAMES.size() + f) * DIRS + d
				var cell := Vector2i(index % COLS, index / COLS) * CELL
				var color := await _capture(avatar, false)
				var normals := await _capture(avatar, true)
				albedo.blit_rect(_shrink(color, true), Rect2i(Vector2i.ZERO, CELL), cell)
				normal.blit_rect(_shrink(normals, false), Rect2i(Vector2i.ZERO, CELL), cell)
		avatar.queue_free()
		await process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	# Saydam piksellerin rengi komşu kişiden gelir: küçültülmüş (mip) düzeylerde kenar kararmaz.
	albedo.fix_alpha_edges()
	albedo.save_png(OUT_DIR + OUT_NAME + ".png")
	normal.save_png(OUT_DIR + OUT_NAME + "_normal.png")
	var meta := {
		"id": OUT_NAME,
		"doc": "Dailin kalabalığının kart atlası (tools/bake_crowd_cards.gd; CrowdCards okur). Hücre index = varyant × (yön × kare) + kare × yön + yön, satır satır cols sütun; yön 0 kamera önde, artan yön kamera kişinin soluna (atan2(x, z) artar). Hücre cell_m metre, ayak alttan pivot oranında; kamera eğimi elevation_deg. walk_cycle_m: yürüyüş klibinin bir döngüsünde alınan yol (m).",
		"variants": VARIANTS,
		"dirs": DIRS,
		"frames": FRAMES,
		"cell_px": [CELL.x, CELL.y],
		"cols": COLS,
		"rows": rows,
		"atlas_px": [atlas_px.x, atlas_px.y],
		"cell_m": [CELL_M.x, CELL_M.y],
		"pivot": PIVOT,
		"elevation_deg": ELEVATION,
		"walk_cycle_m": cycles,
	}
	var file := FileAccess.open(OUT_DIR + OUT_NAME + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(meta, "\t"))
	file.close()
	print("[bake_crowd_cards] %d hücre, atlas %dx%d → %s" % [VARIANTS.size() * DIRS * FRAMES.size(), atlas_px.x, atlas_px.y, OUT_DIR])
	quit(0)


## Sahne: saydam zeminli SubViewport, yalnız beyaz ortam ışığı (renk dokunun kendisi), dik izdüşümlü kamera.
func _setup_stage() -> void:
	_vp = SubViewport.new()
	_vp.size = CELL * SUPER
	_vp.transparent_bg = true
	_vp.own_world_3d = true
	_vp.msaa_3d = Viewport.MSAA_4X
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	root.add_child(_vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_camera.size = CELL_M.y
	_camera.near = 0.05
	_camera.far = 40.0
	_vp.add_child(_camera)
	_holder = Node3D.new()
	_vp.add_child(_holder)
	_normal_mat = ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = NORMAL_CODE
	_normal_mat.shader = shader


## Yön d: kamera kişinin önünden (d = 0) sola doğru 45°'lik adımlarla, ELEVATION eğimle; ayak hücrenin alttan PIVOT'unda.
func _place_camera(d: int) -> void:
	var az := TAU * float(d) / DIRS
	var el := deg_to_rad(ELEVATION)
	var look_y := (0.5 - PIVOT) * CELL_M.y / cos(el)
	var target := Vector3(0.0, look_y, 0.0)
	var dir := Vector3(sin(az) * cos(el), sin(el), cos(az) * cos(el))
	_camera.look_at_from_position(target + dir * 12.0, target, Vector3.UP)


func _capture(avatar: CharacterAvatar, normals: bool) -> Image:
	for node in avatar.find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).material_override = _normal_mat if normals else null
	_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	await process_frame
	return _vp.get_texture().get_image()


## İki kat büyük çizimi hücreye indirir: renkte alfayla ağırlıklı (premultiply → küçült → geri böl), normalde düz ortalama.
func _shrink(img: Image, premultiplied: bool) -> Image:
	var out := img.duplicate() as Image
	out.convert(Image.FORMAT_RGBA8)
	if premultiplied:
		out.premultiply_alpha()
	out.resize(CELL.x, CELL.y, Image.INTERPOLATE_TRILINEAR)
	if premultiplied:
		for y in out.get_height():
			for x in out.get_width():
				var c := out.get_pixel(x, y)
				if c.a > 0.0 and c.a < 1.0:
					out.set_pixel(x, y, Color(minf(c.r / c.a, 1.0), minf(c.g / c.a, 1.0), minf(c.b / c.a, 1.0), c.a))
	return out


## Konturun kalınlığı pişirme çözünürlüğüne göre (CharacterAvatar'ın kontur malzemesi, next_pass).
func _thicken_outline(avatar: CharacterAvatar) -> void:
	for node in avatar.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var mat := mi.get_surface_override_material(s) as ShaderMaterial
			if mat and mat.next_pass is ShaderMaterial:
				(mat.next_pass as ShaderMaterial).set_shader_parameter("min_pixels", OUTLINE_MIN_PX)
