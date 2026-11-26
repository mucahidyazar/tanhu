extends Node3D
## Stil laboratuvarı: tek bir karakteri referans görüntüyle (After the Wind karakter ekranı)
## aynı kadraj ve ışıkta gösterir; shader ayarlarını ölçerek karşılaştırmak için kullanılır.
## Argümanlar: --model=mete --frame=3.0 (bekleme klibinin dondurulacağı saniye) --pose=x,y,z,yaw,pitch

func _ready() -> void:
	var capture := get_node_or_null(^"/root/DevCapture")
	if capture:
		capture.pose_requested.connect(func(pos: Vector3, yaw: float, pitch: float) -> void:
			var cam := get_viewport().get_camera_3d()
			if cam:
				cam.global_transform = Transform3D(Basis.from_euler(Vector3(deg_to_rad(pitch), deg_to_rad(yaw), 0.0)), pos))
	var args := preload("res://scripts/dev/capture.gd").parse_args(OS.get_cmdline_user_args())
	if not args.has("no-grade"):
		ColorGrade.new().apply_to(($WorldEnvironment as WorldEnvironment).environment)
	var avatar := CharacterAvatar.new()
	avatar.model_override = str(args.get("model", "mete"))
	add_child(avatar)
	await get_tree().process_frame
	var players := avatar.find_children("*", "AnimationPlayer", true, false)
	if not players.is_empty():
		var anim := players[0] as AnimationPlayer
		anim.seek(float(args.get("frame", 3.0)), true)
		anim.pause()
