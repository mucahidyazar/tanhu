extends Node3D
## Geliştirme aracı: bir modelin animasyon klibini farklı zamanlarda dondurup yan yana gösterir.
## Kullanım: tools/capture.sh out.png 30 --scene=res://scenes/dev/clip_inspector.tscn --model=father --clip=sit --steps=5

func _ready() -> void:
	var args := preload("res://scripts/dev/capture.gd").parse_args(OS.get_cmdline_user_args())
	var model := str(args.get("model", "father"))
	var role := StringName(str(args.get("clip", "sit")))
	var steps := int(args.get("steps", 5))
	var cam := $Camera as Camera3D
	var capture := get_node_or_null(^"/root/DevCapture")
	if capture:
		capture.pose_requested.connect(func(p: Vector3, yaw: float, pitch: float) -> void:
			cam.global_position = p
			cam.rotation = Vector3(deg_to_rad(pitch), deg_to_rad(yaw), 0.0))
	for i in steps:
		var avatar := CharacterAvatar.new()
		avatar.model_override = model
		avatar.position = Vector3((i - (steps - 1) * 0.5) * 1.3, 0.0, 0.0)
		if args.has("side"):
			avatar.rotation_degrees.y = 90.0
		add_child(avatar)
		var players := avatar.find_children("*", "AnimationPlayer", true, false)
		if players.is_empty():
			continue
		var anim := players[0] as AnimationPlayer
		if i == 0:
			for n in anim.get_animation_list():
				print("[clip] ", n, " len=", anim.get_animation(n).length, " tracks=", anim.get_animation(n).get_track_count())
		var clips := CharacterAvatar.map_clips(anim.get_animation_list(), [])
		if not clips.has(role):
			continue
		anim.play(clips[role])
		var length := anim.get_animation(clips[role]).length
		anim.seek(length * float(i) / float(maxi(steps - 1, 1)), true)
		anim.pause()
