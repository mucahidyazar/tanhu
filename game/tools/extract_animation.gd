extends SceneTree
## Bir GLB içindeki animasyonu ayrı bir .res dosyasına çıkarır (modelin kendisini projede tutmadan
## ek animasyon kullanabilmek için).
## Kullanım: Godot --headless --path . -s res://tools/extract_animation.gd -- <kaynak.glb> <hedef.res> [ad]
## Kaynak res:// yolu ya da proje dışındaki (ör. içe aktarılmayan assets/_meshy_raw) mutlak bir dosya yolu olabilir.

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		print("Kullanım: -- <kaynak.glb> <hedef.res> [ad]")
		quit(1)
		return
	var root := _load_scene(args[0])
	if root == null:
		print("Yüklenemedi: ", args[0])
		quit(1)
		return
	var players := root.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		print("AnimationPlayer yok: ", args[0])
		quit(1)
		return
	var player := players[0] as AnimationPlayer
	for anim_name in player.get_animation_list():
		if anim_name.to_lower() == "reset":
			continue
		var anim := player.get_animation(anim_name).duplicate(true) as Animation
		if args.size() > 2:
			anim.resource_name = args[2]
		var err := ResourceSaver.save(anim, args[1])
		print("[extract] ", anim_name, " -> ", args[1], " uzunluk=", anim.length, " iz=", anim.get_track_count(), " hata=", err)
		break
	root.free()
	quit(0)


## res:// yolları normal yüklenir; mutlak yollar (içe aktarılmamış GLB) çalışma anında glTF olarak okunur.
func _load_scene(path: String) -> Node:
	if path.begins_with("res://"):
		var scene := load(path) as PackedScene
		return scene.instantiate() if scene else null
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path, state) != OK:
		return null
	return doc.generate_scene(state)
