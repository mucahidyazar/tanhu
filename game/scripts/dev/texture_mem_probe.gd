extends SceneTree
## Geliştirme aracı: ana sahneyi (gece kampı) pencereli açar, birkaç saniye bekler, doku belleğini
## (Performance.RENDER_TEXTURE_MEM_USED) ve sahnedeki 3B malzemelerin dokularını yazar, sonra kapanır.
## Başsız sürücü doku belleğini ölçmez (0 yazar): ölçüm pencereli, kısa bir koşudur.
##
## Kullanım (proje klasöründe, normal bir terminalden; pencere açar, kendini kapatır):
##   source tools/_godot_lock.sh; godot_import_locked
##   "$GODOT" --path . --resolution 1920x1080 -s res://scripts/dev/texture_mem_probe.gd -- \
##       --probe-frames=360 [--state=play] [--window=1920x1080] [--probe-out=/tam/yol/sonuc.json] \
##       [--settings-file=/tam/yol/ayar.cfg] [--probe-shot=/tam/yol/kare.png] [--probe-still]
## Argümanlar:
##   --probe-frames=360   kaç kare sonra ölçülür (360 kare ≈ 6 sn; dünya ilk açılışta birkaç saniyede kurulur)
##   --window=WxH         pencereyi bu piksel boyutuna getirir (ölçüm pencere boyundaki çizim hedeflerini de sayar)
##   --probe-out=yol      sonucu ayrıca JSON olarak yazar
##   --probe-shot=yol     ölçüm karesinin ekran görüntüsünü PNG olarak yazar
##   --probe-still        menü kamerasının salınımını ve fare paralaksını kapatır: kadraj farenin yerine bağlı
##                        kalmaz, iki koşunun kareleri karşılaştırılabilir (doku önce / sonra)
##   --probe-pose=x,y,z,yaw,pitch   menü kamerasını bu konuma ve açıya koyar (derece; tools/capture.sh --pose gibi)
##   --probe-hide-ui      arayüzü gizler
## Ana sahnenin geliştirme argümanları (--state=play, --at=x,z, --settings-file=...) olduğu gibi geçer;
## komut satırında "--" sonrası argüman olduğu için koşu oyuncunun kaydına ve ayarına yazmaz.
## Bütçe (godot.md §7.2): kampta doku belleği ≤256 MiB; başvuru penceresi 1920×1080 (çizim hedefleri pencereyle büyür).

const CaptureTool := preload("res://scripts/dev/capture.gd")
const MAIN_SCENE := "res://scenes/main.tscn"
const MIB := 1048576.0
const DEFAULT_FRAMES := 360
## Raporda tek tek yazılan en büyük doku sayısı.
const LIST_LIMIT := 40
## VRAM sıkıştırmalı biçimler: masaüstünde S3TC (BC1, BC3), RGTC (BC4, BC5), BPTC (BC6H, BC7); mobilde ETC2, ASTC.
const COMPRESSED_FORMATS: Array[int] = [
	Image.FORMAT_DXT1, Image.FORMAT_DXT3, Image.FORMAT_DXT5, Image.FORMAT_RGTC_R, Image.FORMAT_RGTC_RG,
	Image.FORMAT_BPTC_RGBA, Image.FORMAT_BPTC_RGBF, Image.FORMAT_BPTC_RGBFU, Image.FORMAT_ETC,
	Image.FORMAT_ETC2_R11, Image.FORMAT_ETC2_R11S, Image.FORMAT_ETC2_RG11, Image.FORMAT_ETC2_RG11S,
	Image.FORMAT_ETC2_RGB8, Image.FORMAT_ETC2_RGBA8, Image.FORMAT_ETC2_RGB8A1, Image.FORMAT_ETC2_RA_AS_RG,
	Image.FORMAT_DXT5_RA_AS_RG, Image.FORMAT_ASTC_4x4, Image.FORMAT_ASTC_4x4_HDR, Image.FORMAT_ASTC_8x8,
	Image.FORMAT_ASTC_8x8_HDR,
]
## Ekran kartında piksel başına bayt. RGB8 kartta RGBA8 olarak durur (RenderingDevice üç kanallı biçim açmaz).
const BYTES_PER_PIXEL := {
	Image.FORMAT_L8: 1.0, Image.FORMAT_LA8: 2.0, Image.FORMAT_R8: 1.0, Image.FORMAT_RG8: 2.0,
	Image.FORMAT_RGB8: 4.0, Image.FORMAT_RGBA8: 4.0, Image.FORMAT_RGBA4444: 2.0, Image.FORMAT_RGB565: 2.0,
	Image.FORMAT_RF: 4.0, Image.FORMAT_RGF: 8.0, Image.FORMAT_RGBF: 16.0, Image.FORMAT_RGBAF: 16.0,
	Image.FORMAT_RH: 2.0, Image.FORMAT_RGH: 4.0, Image.FORMAT_RGBH: 8.0, Image.FORMAT_RGBAH: 8.0,
	Image.FORMAT_DXT1: 0.5, Image.FORMAT_DXT3: 1.0, Image.FORMAT_DXT5: 1.0, Image.FORMAT_RGTC_R: 0.5,
	Image.FORMAT_RGTC_RG: 1.0, Image.FORMAT_BPTC_RGBA: 1.0, Image.FORMAT_BPTC_RGBF: 1.0,
	Image.FORMAT_BPTC_RGBFU: 1.0, Image.FORMAT_ETC2_RGB8: 0.5, Image.FORMAT_ETC2_RGBA8: 1.0,
	Image.FORMAT_ASTC_4x4: 1.0, Image.FORMAT_ASTC_8x8: 0.25,
}
## Raporda biçimlerin kısa adları.
const FORMAT_NAMES := {
	Image.FORMAT_L8: "L8", Image.FORMAT_LA8: "LA8", Image.FORMAT_R8: "R8", Image.FORMAT_RG8: "RG8",
	Image.FORMAT_RGB8: "RGB8", Image.FORMAT_RGBA8: "RGBA8", Image.FORMAT_RGBAH: "RGBAH", Image.FORMAT_RGBAF: "RGBAF",
	Image.FORMAT_DXT1: "BC1", Image.FORMAT_DXT3: "BC2", Image.FORMAT_DXT5: "BC3", Image.FORMAT_RGTC_R: "BC4",
	Image.FORMAT_RGTC_RG: "BC5", Image.FORMAT_BPTC_RGBA: "BC7", Image.FORMAT_BPTC_RGBF: "BC6H",
	Image.FORMAT_BPTC_RGBFU: "BC6H-U", Image.FORMAT_ETC2_RGB8: "ETC2", Image.FORMAT_ETC2_RGBA8: "ETC2A",
	Image.FORMAT_ASTC_4x4: "ASTC4", Image.FORMAT_ASTC_8x8: "ASTC8",
}

var _args := {}


func _initialize() -> void:
	_args = CaptureTool.parse_args(OS.get_cmdline_user_args())
	if _args.has("window"):
		var size := str(_args["window"]).split("x")
		if size.size() == 2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(Vector2i(int(size[0]), int(size[1])))
	change_scene_to_file(MAIN_SCENE)
	_run.call_deferred()


func _run() -> void:
	var frames := maxi(2, int(_args.get("probe-frames", DEFAULT_FRAMES)))
	# Ana sahne değişimi kare sonunda tamamlanır; kamera ve arayüz istekleri sahne kurulunca uygulanır.
	await process_frame
	await process_frame
	_apply_view_args()
	for i in frames - 2:
		await process_frame
	# Başsız sürücü kare çizmez, frame_post_draw hiç gelmez.
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var shot := str(_args.get("probe-shot", ""))
		if shot != "" and shot != "true":
			var err := root.get_texture().get_image().save_png(shot)
			print("[texmem] kare: %s hata=%d" % [shot, err])
	var report := measure()
	for line in report_lines(report):
		print(line)
	var out := str(_args.get("probe-out", ""))
	if out != "" and out != "true":
		var file := FileAccess.open(out, FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(report, "\t"))
		else:
			print("[texmem] JSON yazılamadı: %s" % out)
	quit()


## --probe-still, --probe-pose ve --probe-hide-ui: menü kamerası ve arayüz (ana sahne kurulduktan sonra).
func _apply_view_args() -> void:
	var main := current_scene
	if main == null:
		return
	var camera := main.get_node_or_null(^"MenuCamera") as MenuCamera
	if camera and _args.has("probe-still"):
		camera.parallax_degrees = 0.0
		camera.drift_amount = 0.0
	if camera and _args.has("probe-pose"):
		var p := str(_args["probe-pose"]).split(",")
		if p.size() >= 5:
			var basis := Basis.from_euler(Vector3(deg_to_rad(float(p[4])), deg_to_rad(float(p[3])), 0.0))
			var xform := Transform3D(basis, Vector3(float(p[0]), float(p[1]), float(p[2])))
			camera.menu_transform = xform
			camera.global_transform = xform
	if _args.has("probe-hide-ui"):
		var ui := main.get_node_or_null(^"UI")
		if ui:
			ui.set("visible", false)


## O anki ölçüm: bellek sayaçları, aygıt ve sahnedeki 3B malzeme dokuları.
func measure() -> Dictionary:
	var textures := {}
	collect_textures(root, textures)
	var rows: Array = textures.values()
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["bytes"] > b["bytes"])
	var version: Dictionary = Engine.get_version_info()
	return {
		"state": str(_args.get("state", "menu")),
		"frames": int(_args.get("probe-frames", DEFAULT_FRAMES)),
		"headless": DisplayServer.get_name() == "headless",
		"window": _size_text(Vector2(DisplayServer.window_get_size())),
		"viewport": _size_text(root.get_visible_rect().size),
		"adapter": RenderingServer.get_video_adapter_name(),
		"driver": RenderingServer.get_current_rendering_driver_name(),
		"method": RenderingServer.get_current_rendering_method(),
		"godot": str(version.get("string", "")),
		"texture_mem_mib": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / MIB,
		"buffer_mem_mib": Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / MIB,
		"video_mem_mib": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / MIB,
		"material_textures": rows,
	}


## Raporun konsol satırları.
static func report_lines(report: Dictionary) -> PackedStringArray:
	var lines := PackedStringArray()
	lines.append("[texmem] durum=%s kare=%d pencere=%s görüntü=%s sürücü=%s/%s aygıt=%s %s" % [
		report["state"], report["frames"], report["window"], report["viewport"], report["driver"],
		report["method"], report["adapter"], report["godot"]])
	if report["headless"]:
		lines.append("[texmem] UYARI: başsız sürücü doku belleğini ölçmez; pencereli çalıştırın.")
	lines.append("[texmem] RENDER_TEXTURE_MEM_USED=%.1f MiB RENDER_BUFFER_MEM_USED=%.1f MiB RENDER_VIDEO_MEM_USED=%.1f MiB" % [
		report["texture_mem_mib"], report["buffer_mem_mib"], report["video_mem_mib"]])
	var rows: Array = report["material_textures"]
	var asset_count := 0
	var compressed := 0
	var asset_mib := 0.0
	var all_mib := 0.0
	for row in rows:
		all_mib += float(row["bytes"]) / MIB
		if str(row["path"]).begins_with("res://assets/"):
			asset_count += 1
			asset_mib += float(row["bytes"]) / MIB
			if row["compressed"]:
				compressed += 1
	lines.append("[texmem] 3B malzeme dokusu: %d (tahmini %.1f MiB); assets/ altında %d doku (tahmini %.1f MiB): VRAM sıkıştırmalı %d, kayıpsız %d" % [
		rows.size(), all_mib, asset_count, asset_mib, compressed, asset_count - compressed])
	for i in mini(rows.size(), LIST_LIMIT):
		var row: Dictionary = rows[i]
		lines.append("[texmem]   %7.2f MiB  %s %s mip%d  %s" % [float(row["bytes"]) / MIB, row["size"], row["format"],
			row["mip_levels"], row["path"]])
	return lines


## Düğüm ağacındaki 3B malzemelerin dokularını RID'e göre toplar (her doku bir kez sayılır).
static func collect_textures(node: Node, out: Dictionary) -> void:
	var materials: Array[Material] = []
	if node is GeometryInstance3D:
		var geometry := node as GeometryInstance3D
		materials.append(geometry.material_override)
		materials.append(geometry.material_overlay)
		var mesh: Mesh = null
		if node is MeshInstance3D:
			var instance := node as MeshInstance3D
			mesh = instance.mesh
			for i in instance.get_surface_override_material_count():
				materials.append(instance.get_surface_override_material(i))
		elif node is MultiMeshInstance3D:
			var multimesh := (node as MultiMeshInstance3D).multimesh
			mesh = multimesh.mesh if multimesh else null
		if mesh:
			for i in mesh.get_surface_count():
				materials.append(mesh.surface_get_material(i))
	for material in materials:
		_collect_material(material, out)
	for child in node.get_children():
		collect_textures(child, out)


static func _collect_material(material: Material, out: Dictionary) -> void:
	var depth := 0
	while material != null and depth < 8:
		if material is ShaderMaterial:
			var shader_material := material as ShaderMaterial
			if shader_material.shader:
				for uniform in shader_material.shader.get_shader_uniform_list():
					var value: Variant = shader_material.get_shader_parameter(uniform["name"])
					if value is Texture2D:
						_add_texture(value as Texture2D, out)
		elif material is BaseMaterial3D:
			for param in BaseMaterial3D.TEXTURE_MAX:
				var texture := (material as BaseMaterial3D).get_texture(param as BaseMaterial3D.TextureParam)
				if texture:
					_add_texture(texture, out)
		material = material.next_pass
		depth += 1


static func _add_texture(texture: Texture2D, out: Dictionary) -> void:
	var rid := texture.get_rid()
	if not rid.is_valid() or out.has(rid):
		return
	# Kodla üretilen dokular (NoiseTexture2D...) biçimlerini bildirmez: RenderingServer'daki doku sorulur.
	var format := texture.get_format()
	if format < 0 or format >= Image.FORMAT_MAX:
		format = RenderingServer.texture_get_format(rid)
	var levels := _mip_levels(texture)
	out[rid] = {
		"path": texture.resource_path if texture.resource_path != "" else "<%s>" % texture.get_class(),
		"size": "%dx%d" % [texture.get_width(), texture.get_height()],
		"format": FORMAT_NAMES.get(format, "biçim %d" % format),
		"compressed": format in COMPRESSED_FORMATS,
		"mip_levels": levels,
		"bytes": estimate_bytes(texture.get_width(), texture.get_height(), format, levels),
	}


## Dokunun ekran kartındaki mip düzeyi sayısı (taban dahil). CompressedTexture2D has_mipmaps()'ı bildirmez
## (içe aktarılmış dokuda da false döner): sayı RenderingDevice'taki dokudan okunur, yoksa Texture2D'den.
static func _mip_levels(texture: Texture2D) -> int:
	var device := RenderingServer.get_rendering_device()
	if device:
		var rd_texture := RenderingServer.texture_get_rd_texture(texture.get_rid())
		if rd_texture.is_valid():
			var rd_format := device.texture_get_format(rd_texture)
			if rd_format:
				return maxi(1, rd_format.mipmaps)
	return texture.get_mipmap_count() + 1 if texture.has_mipmaps() else 1


## Dokunun ekran kartındaki tahmini boyu (bayt): levels mip düzeyi (taban dahil); sıkıştırmalı biçimde 4×4 blok.
static func estimate_bytes(width: int, height: int, format: int, levels: int) -> float:
	var bpp: float = BYTES_PER_PIXEL.get(format, 4.0)
	var block := format in COMPRESSED_FORMATS
	var total := 0.0
	var w := maxi(1, width)
	var h := maxi(1, height)
	for level in maxi(1, levels):
		var bw := maxi(4, ceili(w / 4.0) * 4) if block else w
		var bh := maxi(4, ceili(h / 4.0) * 4) if block else h
		total += float(bw * bh) * bpp
		w = maxi(1, w >> 1)
		h = maxi(1, h >> 1)
	return total


static func _size_text(size: Vector2) -> String:
	return "%dx%d" % [int(size.x), int(size.y)]
