class_name E21Shots
extends RefCounted
## Geliştirme: Önsöz'ün son dört görevinin inceleme kareleri (Ö2; docs/media/review/e21_<görev>_*.jpg). Komut satırında
## --e21-shots=<klasör> varsa adımlar anlamlı anlarda (kuzu kucakta, şildenin ateşi, güreşin penceresi, ateşin evreleri) kareyi JPEG yazar;
## yoksa hiçbir şey yapmaz. Kare bir sonraki çizimden sonra alınır (görüntü güncel). Pencerede koşulur (başsızda görüntü yok).
##   E21Shots.shot(node, "lambs_carry")    # <klasör>/e21_lambs_carry.jpg

static var _dir := ""
static var _read := false
static var _taken: Dictionary = {}


static func folder() -> String:
	if not _read:
		_read = true
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--e21-shots="):
				_dir = a.substr(12)
	return _dir


## Geliştirme günlüğü (--autoplay ya da --e21-shots ile): «[e21] kuzular: 2/4 yurtta».
static func log(msg: String) -> void:
	var args := OS.get_cmdline_user_args()
	if args.has("--autoplay") or not E21Shots.folder().is_empty() or args.has("--e21-log"):
		print("[e21] %.1f sn · %s" % [Time.get_ticks_msec() / 1000.0, msg])


static func enabled() -> bool:
	return not E21Shots.folder().is_empty() and DisplayServer.get_name() != "headless"


## Kareyi bir kez yazar (aynı ad ikinci kez yazılmaz); delay sn sonra.
static func shot(node: Node, shot_name: String, delay: float = 0.0) -> void:
	if not E21Shots.enabled() or node == null or not node.is_inside_tree() or _taken.has(shot_name):
		return
	_taken[shot_name] = true
	var tree := node.get_tree()
	if delay > 0.0:
		await tree.create_timer(delay).timeout
	await RenderingServer.frame_post_draw
	var vp := tree.root.get_viewport()
	var img := vp.get_texture().get_image()
	if img == null:
		return
	if img.get_width() > 1920:
		img.resize(1920, int(round(1920.0 * float(img.get_height()) / float(img.get_width()))), Image.INTERPOLATE_LANCZOS)
	DirAccess.make_dir_recursive_absolute(E21Shots.folder())
	var path := E21Shots.folder().path_join("e21_%s.jpg" % shot_name)
	var err := img.save_jpg(path, 0.88)
	# Karenin bütçesi (godot.md §7.2; budget_probe'un okuduğu sayaçlar): görünür ve gölge geçişinin üçgeni ve çizimi.
	var vis_tri := vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)
	var sh_tri := vp.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)
	var vis_dc := vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
	var sh_dc := vp.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)
	print("[e21-shots] %s hata=%d üçgen=%.3fM gölge=%.3fM çizim=%d/%d fps=%.0f" % [path, err, vis_tri / 1e6, sh_tri / 1e6, vis_dc, sh_dc,
		Engine.get_frames_per_second()])
