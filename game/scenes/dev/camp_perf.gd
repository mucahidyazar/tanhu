extends Node
## Geliştirme sahnesi (kamp modülü): ana sahneyi açar ve kamp modellerinin kare hızına etkisini ölçmek için
## komut satırına göre onları değiştirir. tools/capture.sh ... --scene=res://scenes/dev/camp_perf.tscn ile:
##   --camp-hide       kamp nesnelerinin Meshy modellerini gizle
##   --camp-noshadow   kamp modellerinin gölgesini kapat
##   --camp-single     kamp modellerini tek yüzlü çiz

const CaptureTool := preload("res://scripts/dev/capture.gd")
const MAIN_SCENE := preload("res://scenes/main.tscn")


func _ready() -> void:
	var args := CaptureTool.parse_args(OS.get_cmdline_user_args())
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var camp := main.get_node_or_null(^"World/Camp")
	if camp == null:
		return
	var count := 0
	for node in camp.find_children("*", "MeshyProp", true, false):
		var prop := node as MeshyProp
		count += 1
		if args.has("camp-hide"):
			prop.visible = false
		if args.has("camp-noshadow"):
			prop.cast_shadows = false
		if args.has("camp-single"):
			prop.double_sided = false
	print("[camp_perf] kamp modeli: %d, ayarlar: %s" % [count, args.keys()])
