extends Node
## Geliştirme sahnesi (zemin modülü): ana sahneyi açar ve çayırın (çimen, çiçek), dumanın kare hızına etkisini
## ölçmek için komut satırına göre onları gizler. tools/capture.sh ... --scene=res://scenes/dev/ground_perf.tscn ile:
##   --ground-nograss    çimen tutamlarını gizle
##   --ground-noflowers  çiçekleri gizle
##   --ground-nosmoke    yurt dumanını gizle
## Ayrıca çimen ve çiçek örneklerinin ve üçgenlerinin sayısını yazar.

const CaptureTool := preload("res://scripts/dev/capture.gd")
const MAIN_SCENE := preload("res://scenes/main.tscn")


func _ready() -> void:
	var args := CaptureTool.parse_args(OS.get_cmdline_user_args())
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	# Çayır kurulumu bir sonraki kareye ertelenir; birkaç kare bekle.
	for i in 6:
		await get_tree().process_frame
	var meadow := main.get_node_or_null(^"World/Meadow") as Meadow
	if meadow == null:
		print("[ground_perf] Meadow yok")
		return
	var stats := {"grass": Vector2i.ZERO, "flowers": Vector2i.ZERO}
	var draws := {"grass": 0, "flowers": 0}
	for node in meadow.find_children("*", "MultiMeshInstance3D", false, false):
		var mmi := node as MultiMeshInstance3D
		var key := "grass" if mmi.name.begins_with("Grass") else "flowers"
		var mm := mmi.multimesh
		var tris := _triangles(mm.mesh) * mm.instance_count
		stats[key] += Vector2i(mm.instance_count, tris)
		draws[key] += 1
		if key == "grass" and args.has("ground-nograss"):
			mmi.visible = false
		if key == "flowers" and args.has("ground-noflowers"):
			mmi.visible = false
	if args.has("ground-nosmoke"):
		for smoke in main.find_children("Smoke", "", true, false):
			(smoke as Node3D).visible = false
	print("[ground_perf] çimen örnek/üçgen: %s (%d MultiMesh), çiçek örnek/üçgen: %s (%d MultiMesh), ayarlar: %s" % [stats["grass"], draws["grass"], stats["flowers"], draws["flowers"], args.keys()])
	await _measure_render_time(240, 180)


## warmup kare bekler, sonra frames kare boyunca ortalama kare süresini yazar (ms). Dikey eşitleme (vsync)
## kapatılır: açıkken kare hızı ekranın yenileme hızının alt katlarına (ör. 120 / 3 = 40) takılır ve küçük
## maliyet farkları görünmez.
func _measure_render_time(warmup: int, frames: int) -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	for i in warmup:
		await get_tree().process_frame
	var start := Time.get_ticks_usec()
	for i in frames:
		await get_tree().process_frame
	var ms := float(Time.get_ticks_usec() - start) / 1000.0 / float(frames)
	print("[ground_perf] kare_ms=%.2f (vsync kapalı, %.1f fps)" % [ms, 1000.0 / ms])


static func _triangles(mesh: Mesh) -> int:
	var total := 0
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		total += indices.size() / 3 if not indices.is_empty() else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return total
