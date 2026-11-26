extends Node3D
## Geliştirme sahnesi: dünya + Meshy NPC'leri + menü kamerası (eski chibi NPC'ler gizlenir).
## Kadraj denemeleri için --pose=x,y,z,yaw,pitch ve --fov=derece argümanlarını kabul eder.

@onready var _camera := $Camera as Camera3D


func _ready() -> void:
	# Yakalama aracının sinyalleri ilk karede (call_deferred) gelir; beklemeden bağlan.
	var capture := get_node_or_null(^"/root/DevCapture")
	if capture:
		capture.pose_requested.connect(_on_pose_requested)
		capture.fov_requested.connect(_on_fov_requested)
	await get_tree().process_frame
	for node in find_children("*", "ChibiCharacter", true, false):
		if node.get_parent().name == "Camp":
			node.queue_free()


func _on_pose_requested(pos: Vector3, yaw_deg: float, pitch_deg: float) -> void:
	var xform := Transform3D(Basis.from_euler(Vector3(deg_to_rad(pitch_deg), deg_to_rad(yaw_deg), 0.0)), pos)
	if _camera is MenuCamera:
		(_camera as MenuCamera).menu_transform = xform
	_camera.global_transform = xform


func _on_fov_requested(fov_deg: float) -> void:
	if _camera is MenuCamera:
		(_camera as MenuCamera).design_fov = fov_deg
	else:
		_camera.fov = fov_deg
