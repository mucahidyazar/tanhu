extends SceneTree
## Elle tarif edilen haritanın yüksekliğini ve zemin boyasını dosyaya yazar (godot.md §4.4; act1.md §4; Yol Haritası winter-camp-terrain):
## map.json «ground.relief», roads.json ve yapı kayıtları TerrainPaint'le boyanır; sonuç ground.height_file (R32F EXR, 1 m), mask_file (RGBA8
## PNG, 2 m: R kar, G toprak, B yol, A Kar Kabuğu) ve cover_file (RGBA8 PNG, 4 m: R buz, G kaya, B saz, A orman) olur. Dosyalar içe
## aktarılmaz (importer skip): MapBaker onları doğrudan okur, tools/bake_map.gd parçaları onlardan pişirir. Dosya elle değişirse
## (yükseklik boyası) parçaların imzası eskir.
##
##   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s res://tools/paint_height.gd -- --map=kislak
##   ... -- --map=kislak --preview=/mutlak/yol/kislak_relief.png   (gölgeli kabartma, 5 m eş yükselti, yollar ve yapılar)
##   ... -- --map=kislak --probe   (act1.md §4'ün yüksekliklerini denetim noktalarında yazar)

## act1.md §4'ün yükseklikleri: [ad, x, z, beklenen, pay].
const PROBES := [
	["Ulu Ocak", 0.0, 0.0, 0.0, 0.3], ["Adak Ağılı", -80.0, 190.0, 42.0, 3.0], ["Geyik Taşları", -100.0, 135.0, 34.0, 3.0],
	["Yar kenarı", 8.0, -93.0, -5.0, 1.5], ["Yar dibi", -20.0, -110.0, -14.0, 2.0], ["Buz Kolu (Geçit)", 140.0, -155.0, -18.0, 0.6],
	["Ak Otlak güney", 170.0, -235.0, -14.0, 4.0], ["Ak Otlak kuzey", 170.0, -450.0, 4.0, 4.0], ["Büyük Kurgan (tepe)", 478.0, -318.0, 6.0, 2.0],
	["Yukarı Ağıllar", 440.0, -475.0, 22.0, 2.0], ["Kemik Boğazı", 550.0, -640.0, 48.0, 3.0], ["Şafak Sırtı", 600.0, -725.0, 60.0, 4.0],
	["Çukur", 92.0, 165.0, -6.0, 1.5], ["Demir Diş", -310.0, -100.0, 8.0, 2.0], ["Demir Diş duvarı", -350.0, -175.0, 40.0, 6.0],
	["Ayna Göl", -290.0, -500.0, -8.0, 0.5], ["Rehine Yurdu", -48.0, 58.0, 2.5, 4.0], ["Kesim Yeri", 430.0, 10.0, 20.0, 10.0],
]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var map_id := "kislak"
	var preview := ""
	var probe := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="):
			map_id = arg.substr(6)
		elif arg.begins_with("--preview="):
			preview = arg.substr(10)
		elif arg == "--probe":
			probe = true
	var spec := MapSpec.find(map_id)
	if spec == null or not MapBaker.is_painted(spec):
		push_error("[paint_height] elle tarif edilen harita değil: %s" % map_id)
		quit(1)
		return
	var t0 := Time.get_ticks_msec()
	var paint := TerrainPaint.paint(spec)
	var t1 := Time.get_ticks_msec()
	var g := spec.ground
	var failed := 0
	failed += _write_exr(paint.height_image(), str(g.get("height_file", "")))
	failed += _write_png(paint.mask_image(float(g.get("mask_cell", 2.0))), str(g.get("mask_file", "")))
	failed += _write_png(paint.cover_image(float(g.get("cover_cell", 4.0))), str(g.get("cover_file", "")))
	print("[paint_height] %s boyandı: %d × %d örnek, %d işlem, %.1f sn (yazım %.1f sn)" % [map_id, paint.width, paint.depth, paint.op_count,
		(t1 - t0) / 1000.0, (Time.get_ticks_msec() - t1) / 1000.0])
	if probe:
		for row: Array in PROBES:
			var h := paint.height_at(float(row[1]), float(row[2]))
			var ok := absf(h - float(row[3])) <= float(row[4])
			print("  %s %-22s (%5.0f, %5.0f): %6.2f m (beklenen %5.1f ±%.1f)" % ["✓" if ok else "✗", row[0], row[1], row[2], h, row[3], row[4]])
	if not preview.is_empty():
		_write_preview(paint, spec, preview)
	quit(1 if failed > 0 else 0)


func _write_exr(img: Image, path: String) -> int:
	if path.is_empty():
		return 0
	_skip_import(path)
	var err := img.save_exr(ProjectSettings.globalize_path(path), true)
	if err != OK:
		push_error("[paint_height] %s yazılamadı: %s" % [path, error_string(err)])
		return 1
	print("[paint_height] %s: %.2f MB" % [path, FileAccess.get_file_as_bytes(path).size() / 1048576.0])
	return 0


func _write_png(img: Image, path: String) -> int:
	if path.is_empty():
		return 0
	_skip_import(path)
	var err := img.save_png(ProjectSettings.globalize_path(path))
	if err != OK:
		push_error("[paint_height] %s yazılamadı: %s" % [path, error_string(err)])
		return 1
	print("[paint_height] %s: %d × %d, %.2f MB" % [path, img.get_width(), img.get_height(), FileAccess.get_file_as_bytes(path).size() / 1048576.0])
	return 0


## Dosya içe aktarılmasın (importer skip: Godot onu doku yapmaz, dışa aktarımda yoktur; MapBaker doğrudan okur).
func _skip_import(path: String) -> void:
	var meta := path + ".import"
	if FileAccess.file_exists(meta):
		return
	var f := FileAccess.open(meta, FileAccess.WRITE)
	if f:
		f.store_string("[remap]\n\nimporter=\"skip\"\n")
		f.close()


## Önizleme (1 px = 1 m): yükseklik renkleri, kuzeybatıdan gölge, 5 m'lik eş yükselti, buz, yollar ve yapılar.
func _write_preview(paint: TerrainPaint, spec: MapSpec, path: String) -> void:
	var w := paint.width
	var d := paint.depth
	var img := Image.create(w, d, false, Image.FORMAT_RGB8)
	var light := Vector3(-0.6, 0.75, -0.5).normalized()
	for iz in d:
		for ix in w:
			var i := iz * w + ix
			var h := paint.heights[i]
			var hx := paint.heights[iz * w + mini(ix + 1, w - 1)] - paint.heights[iz * w + maxi(ix - 1, 0)]
			var hz := paint.heights[mini(iz + 1, d - 1) * w + ix] - paint.heights[maxi(iz - 1, 0) * w + ix]
			var n := Vector3(-hx, 2.0, -hz).normalized()
			var shade := clampf(n.dot(light) * 0.8 + 0.35, 0.15, 1.2)
			var t := clampf((h + 20.0) / 100.0, 0.0, 1.0)
			var col := Color(0.38, 0.5, 0.62).lerp(Color(0.92, 0.9, 0.84), smoothstep(0.0, 0.35, t)).lerp(Color(0.62, 0.52, 0.42), smoothstep(0.35, 1.0, t))
			col = col * shade
			if paint.ice[i] > 0.5:
				col = col.lerp(Color(0.55, 0.72, 0.9), 0.6)
			if paint.road[i] > 0.4:
				col = col.lerp(Color(0.35, 0.22, 0.12), 0.75)
			if paint.trample[i] > 0.5:
				col = col.lerp(Color(0.5, 0.35, 0.25), 0.4)
			if paint.forest[i] > 0.5:
				col = col.lerp(Color(0.2, 0.3, 0.22), 0.35)
			var band := fposmod(h, 5.0)
			if band < 0.18 or band > 4.82:
				col = col.darkened(0.25)
			img.set_pixel(ix, iz, Color(clampf(col.r, 0, 1), clampf(col.g, 0, 1), clampf(col.b, 0, 1)))
	for s: Dictionary in spec.structures:
		var at: Vector2 = s["at"]
		var px := int(roundf((at.x - paint.rect.position.x) / paint.cell))
		var pz := int(roundf((at.y - paint.rect.position.y) / paint.cell))
		var r := 3 if str(s.get("kind", "")) == "yurt" else 1
		var c := Color(0.85, 0.1, 0.1) if str(s.get("kind", "")) in ["watch_fire", "great_hearth"] else Color(0.1, 0.1, 0.1)
		for oz in range(-r, r + 1):
			for ox in range(-r, r + 1):
				if px + ox >= 0 and px + ox < w and pz + oz >= 0 and pz + oz < d:
					img.set_pixel(px + ox, pz + oz, c)
	var err := img.save_png(path)
	print("[paint_height] önizleme %s (%s)" % [path, error_string(err)])
