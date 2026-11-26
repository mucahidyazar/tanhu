extends Node
## Geliştirme sahnesi (çayır modülü): ana sahneyi açar ve kampın arkasındaki çayırın (orman, kayalar) kare
## hızına etkisini ölçmek için komut satırına göre onları değiştirir. tools/capture.sh ile:
##   tools/capture.sh /tmp/x.png 480 --scene=res://scenes/dev/meadow_perf.tscn --window=3200x1800 --hide-ui [bayraklar]
##   --meadow-old-forest   çamları bu turdan önceki yerleşimle kur (kamp çamları, kümeler, vadi kaması)
##   --meadow-old-rocks    kahraman kayaları bu turdan önceki boyutlarıyla kur
##   --meadow-no-valley    vadi ormanını (MultiMesh ladinler) gizle
##   --meadow-no-pines     kamp ve küme çamlarını gizle
##   --meadow-no-rocks     bütün kayaları gizle

const CaptureTool := preload("res://scripts/dev/capture.gd")
const MAIN_SCENE := preload("res://scenes/main.tscn")
## Ölçümden önce beklenen ve ölçülen kare sayısı (yakalama 480. karede olur; ölçüm ondan önce biter).
const WARMUP_FRAMES := 220
const MEASURE_FRAMES := 200

## Bu turdan önceki değerler (karşılaştırma için).
const OLD_CAMP_TREES: Array[Vector4] = [
	Vector4(-5.3, 6.0, 0.35, 1.0), Vector4(-4.3, 6.6, 0.28, 13.0), Vector4(-7.0, 5.2, 0.38, 14.0),
	Vector4(-7.6, 3.9, 0.36, 2.0), Vector4(-10.71, -1.06, 0.42, 3.0), Vector4(-12.4, -3.4, 0.48, 4.0),
	Vector4(-16.65, -13.83, 0.78, 5.0), Vector4(-11.03, -21.86, 0.95, 6.0), Vector4(11.3, 0.8, 0.38, 7.0),
	Vector4(7.0, 3.85, 0.42, 8.0), Vector4(6.2, 3.6, 0.32, 15.0), Vector4(7.6, 2.9, 0.46, 16.0),
	Vector4(8.6, 6.4, 0.5, 9.0), Vector4(8.13, -27.65, 1.05, 10.0), Vector4(-1.9, 6.6, 0.26, 11.0),
	Vector4(0.35, 7.1, 0.22, 12.0),
]
const OLD_GROVES: Array[Vector4] = [
	Vector4(-15.0, 2.0, 4.0, 6.0), Vector4(-9.5, 9.5, 4.0, 5.0), Vector4(-20.5, -10.0, 5.0, 8.0),
	Vector4(-23.0, -20.0, 6.0, 9.0), Vector4(-13.5, -24.0, 4.0, 4.0), Vector4(18.5, -27.0, 7.0, 10.0),
	Vector4(22.0, -14.0, 6.0, 9.0), Vector4(15.5, -4.5, 3.5, 5.0), Vector4(10.4, 2.8, 2.8, 4.0),
	Vector4(12.0, 7.5, 4.5, 6.0),
]
## hero_rocks dizisindeki sırayla eski boyutlar (yeni eklenen kayalar için -1: gizlenir).
const OLD_ROCK_SIZES := [2.6, 2.25, 2.6, 2.05, 1.05, 1.15, 1.9, 2.3, 2.5, 2.6, 1.8, 1.9, 0.85, 0.9, 1.3, 1.0, 1.4, 1.0, -1.0]


func _ready() -> void:
	var args := CaptureTool.parse_args(OS.get_cmdline_user_args())
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	# Orman ve kayalar kurulumlarını bir kare erteler; ondan sonra değiştir.
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var forest := main.get_node_or_null(^"World/Forest") as Forest
	var rocks := main.get_node_or_null(^"World/RockField") as RockField
	if forest and args.has("meadow-old-forest"):
		_use_old_forest(forest)
	if rocks and args.has("meadow-old-rocks"):
		_use_old_rocks(rocks)
	if forest and args.has("meadow-no-valley"):
		for node in forest.find_children("Trees_*", "MultiMeshInstance3D", true, false):
			(node as Node3D).visible = false
	if forest and args.has("meadow-no-pines"):
		var pines := forest.get_node_or_null(^"Pines") as Node3D
		if pines:
			pines.visible = false
	if rocks and args.has("meadow-no-rocks"):
		rocks.visible = false
	print("[meadow_perf] ayarlar: %s" % [args.keys()])
	_measure_render_time()


## Görüntünün GPU ve CPU çizim süresini ölçer (ısınmadan sonra MEASURE_FRAMES karenin ortalaması, ms).
## Kare hızından daha güvenilirdir: aynı anda çalışan başka işlemlerin CPU yükünden az etkilenir.
func _measure_render_time() -> void:
	var rid := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	for i in WARMUP_FRAMES:
		await get_tree().process_frame
	var gpu := 0.0
	var cpu := 0.0
	for i in MEASURE_FRAMES:
		await get_tree().process_frame
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(rid)
		cpu += RenderingServer.viewport_get_measured_render_time_cpu(rid)
	print("[meadow_perf] gpu=%.2f ms cpu=%.2f ms" % [gpu / float(MEASURE_FRAMES), cpu / float(MEASURE_FRAMES)])


func _use_old_forest(forest: Forest) -> void:
	forest.camp_trees = OLD_CAMP_TREES
	forest.groves = OLD_GROVES
	forest.grove_heights_near = Vector2(4.0, 7.5)
	forest.grove_heights_far = Vector2(7.0, 12.0)
	forest.camp_clearing = 34.0
	forest.view_clearing = Vector4(30.0, 330.0, 40.0, 0.3)
	forest.rebuild()


func _use_old_rocks(rocks: RockField) -> void:
	var old: Array[Vector4] = []
	for i in rocks.hero_rocks.size():
		var r := rocks.hero_rocks[i]
		var size: float = OLD_ROCK_SIZES[i] if i < OLD_ROCK_SIZES.size() else -1.0
		if size > 0.0:
			old.append(Vector4(r.x, r.y, size, r.w))
	rocks.hero_rocks = old
	rocks.rebuild()
