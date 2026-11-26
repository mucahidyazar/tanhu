extends SceneTree
## Yan yana karşılaştırma karesi (docs/media/review/atlas_*.jpg): her satırda iki görüntü (prototip ve Godot), altlarında yazı.
## Pencerede çalışır (çizim gerekir; kum havuzu dışında):
##   Godot --path . -s res://tools/atlas/compose_review.gd -- --out=/mutlak/yol.jpg --row="a.png|Prototip …|b.png|Godot …" [--row=…]
## Hücre 960 × 540'tır (1920 × 1080 karelerin yarısı); boş görüntü yolu ("-") gri hücre bırakır.

const CELL := Vector2i(960, 540)


func _init() -> void:
	var out := ""
	var rows: Array = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--row="):
			rows.append(a.substr(6).split("|"))
	if out.is_empty() or rows.is_empty():
		push_error("compose_review: --out ve en az bir --row gerekli")
		quit(1)
		return
	var vp := SubViewport.new()
	vp.size = Vector2i(CELL.x * 2, CELL.y * rows.size())
	vp.transparent_bg = false
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.06, 0.05)
	bg.size = Vector2(vp.size)
	vp.add_child(bg)
	for r in rows.size():
		var row: PackedStringArray = rows[r]
		for c in 2:
			var path := row[c * 2] if row.size() > c * 2 else "-"
			var caption := row[c * 2 + 1] if row.size() > c * 2 + 1 else ""
			var at := Vector2(c * CELL.x, r * CELL.y)
			if path != "-" and FileAccess.file_exists(path):
				var img := Image.load_from_file(path)
				img.resize(CELL.x, CELL.y, Image.INTERPOLATE_LANCZOS)
				var tr := TextureRect.new()
				tr.texture = ImageTexture.create_from_image(img)
				tr.position = at
				tr.size = Vector2(CELL)
				vp.add_child(tr)
			if not caption.is_empty():
				var font: Font = load("res://assets/fonts/Alegreya.ttf")
				var l := Label.new()
				l.text = caption
				l.add_theme_font_override("font", font)
				l.add_theme_font_size_override("font_size", 25)
				l.add_theme_color_override("font_color", Color("#f3e6c8"))
				var sb := StyleBoxFlat.new()
				sb.bg_color = Color(0.1, 0.05, 0.04, 0.82)
				sb.set_content_margin_all(8)
				sb.content_margin_left = 14
				sb.content_margin_right = 14
				l.add_theme_stylebox_override("normal", sb)
				l.position = at + Vector2(14.0, CELL.y - 58.0)
				vp.add_child(l)
		# Hücrelerin arası.
		var line := ColorRect.new()
		line.color = Color(0.08, 0.06, 0.05)
		line.position = Vector2(CELL.x - 2, r * CELL.y)
		line.size = Vector2(4, CELL.y)
		vp.add_child(line)
	for i in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	var shot := vp.get_texture().get_image()
	var err := shot.save_jpg(out, 0.88)
	print("[compose] %s %s hata=%d" % [out, shot.get_size(), err])
	quit(0 if err == OK else 1)
