extends Node
## Geliştirme sahnesi (kaya ve ağaç modülü): asıl ana sahneyi (menü kadrajıyla) açar; komut satırından
## dünyanın bazı parçaları gizlenebilir ya da Meshy modelleri kapatılabilir (fps ve görünüm karşılaştırması).
##
## Komut satırı (tools/capture.sh ... --scene=res://scenes/dev/nature_lab.tscn):
##   --hide=Forest,RockField   World altındaki bu düğümler gizlenir (virgülle ayrılır)
##   --hide-children=Forest/Trees_*,Forest/Trees_*_-1,RockField/HeroRock*
##                             World altındaki düğümün adı bu kalıba (* ve ? jokerli) uyan çocukları gizlenir
##                             (kurulumdan sonra; ör. yalnızca vadi ormanı, yalnızca uzak vadi ağaçları ya da
##                             yalnızca kahraman kayalar)
##   --no-shadows=Forest/Pines,RockField
##                             bu düğümlerin altındaki bütün meshler gölge düşürmez (gölge maliyetini ölçmek için)
##   --lod-bias=Forest/Pines:0.25,RockField:0.5
##                             bu düğümlerin altındaki bütün meshlerin LOD eğilimi (düşük = daha sade düzey)
##   --fallback                Meshy modelleri yerine kodla çizilen yedek görünümler
##   --foliage=ad=değer,...    çam malzemelerinin shader parametrelerini kurulumdan sonra değiştirir
##   --valley=ad=değer,...     yalnızca vadi ormanının (Forest/Trees_*) malzemesinin shader parametreleri
##   --rocks=ad=değer,...      kaya malzemelerinin (kahraman, serpiştirilmiş, vadi) shader parametreleri
##                             (vec3/renk değeri noktalı virgülle: tip_tint=0.9;1.0;1.05)
##   --profile                 300. kareden sonra ortalama kare süresini her 100 karede yazar (fps'ten daha ince
##                             ölçü; kare sayısı 400'den büyük olmalı)
##   --pose=x,y,z,yaw,pitch  --fov=derece  --hide-ui   ana sahnedeki gibi

const CaptureTool := preload("res://scripts/dev/capture.gd")
const MAIN_SCENE := preload("res://scenes/main.tscn")
## Forest ve RockField kurulumu ertelenir; çocuklar bu kadar kare sonra gizlenir.
const HIDE_AFTER_FRAMES := 10
## Ölçüm, sahne ısındıktan (gölgeler, gölgelendirici derlemeleri) sonra başlar.
const PROFILE_FROM_FRAME := 300

var _time_total := 0.0
var _time_frames := 0
var _frame := 0
var _profiling := false


func _ready() -> void:
	var args := CaptureTool.parse_args(OS.get_cmdline_user_args())
	if args.has("fallback"):
		MeshyProp.models_enabled = false
	var main := MAIN_SCENE.instantiate()
	add_child(main)
	if args.has("hide"):
		for node_name in str(args["hide"]).split(",", false):
			var node := main.get_node_or_null(NodePath("World/" + node_name)) as Node3D
			if node:
				node.visible = false
	if args.has("hide-children"):
		_hide_children_later(main, str(args["hide-children"]).split(",", false))
	if args.has("lod-bias"):
		_set_lod_bias_later(main, str(args["lod-bias"]).split(",", false))
	if args.has("no-shadows"):
		_disable_shadows_later(main, str(args["no-shadows"]).split(",", false))
	if args.has("foliage"):
		_set_params_later(main, "Forest", str(args["foliage"]))
	if args.has("valley"):
		_set_params_later(main, "Forest", str(args["valley"]), "Trees_*")
	if args.has("rocks"):
		_set_params_later(main, "RockField", str(args["rocks"]))
	_profiling = args.has("profile")


func _process(delta: float) -> void:
	if not _profiling:
		return
	_frame += 1
	if _frame < PROFILE_FROM_FRAME:
		return
	_time_total += delta
	_time_frames += 1
	if _time_frames % 100 == 0:
		print("[nature_lab] ortalama kare süresi %.2f ms (%d kare)" % [_time_total * 1000.0 / float(_time_frames), _time_frames])


## "Ebeveyn/kalıp" çiftlerindeki çocukları kurulumdan sonra gizler.
func _hide_children_later(main: Node, pairs: PackedStringArray) -> void:
	await _wait_for_build()
	for pair in pairs:
		# Son "/" ebeveyn yolunu kalıptan ayırır (ör. Forest/Pines/Pine1?).
		var cut := pair.rfind("/")
		if cut <= 0:
			continue
		var parent := main.get_node_or_null(NodePath("World/" + pair.substr(0, cut)))
		if parent == null:
			continue
		var pattern := pair.substr(cut + 1)
		var hidden := 0
		for child in parent.get_children():
			if child is Node3D and String(child.name).match(pattern):
				(child as Node3D).visible = false
				hidden += 1
		print("[nature_lab] %s: %d düğüm gizlendi" % [pair, hidden])


## World/<holder> altındaki (adı pattern'e uyan) düğümlerin ShaderMaterial'larına (material_override ve yüzey
## malzemeleri) parametre yazar.
func _set_params_later(main: Node, holder: String, spec: String, pattern: String = "*") -> void:
	await _wait_for_build()
	var root := main.get_node_or_null(NodePath("World/" + holder))
	if root == null:
		return
	var materials: Array[ShaderMaterial] = []
	for node in root.find_children(pattern, "GeometryInstance3D", true, false):
		var gi := node as GeometryInstance3D
		if gi.material_override is ShaderMaterial and not materials.has(gi.material_override):
			materials.append(gi.material_override as ShaderMaterial)
		if gi is MeshInstance3D and (gi as MeshInstance3D).mesh:
			var mi := gi as MeshInstance3D
			for k in mi.mesh.get_surface_count():
				var mat := mi.get_surface_override_material(k) as ShaderMaterial
				if mat and not materials.has(mat):
					materials.append(mat)
	for item in spec.split(",", false):
		var kv := item.split("=", false)
		if kv.size() != 2:
			continue
		var value: Variant = parse_value(kv[1])
		for mat in materials:
			if mat.shader and _has_uniform(mat.shader, kv[0]):
				_set_param(mat, kv[0], value)
	print("[nature_lab] %s: %d malzemeye %s yazıldı" % [holder, materials.size(), spec])


## Komut satırı değeri: "0.5" → float, "0.9;1.0;1.05" → Vector3 (saf fonksiyon).
static func parse_value(text: String) -> Variant:
	var parts := text.split(";", false)
	if parts.size() == 3:
		return Vector3(float(parts[0]), float(parts[1]), float(parts[2]))
	return float(text)


## Parametreyi yazar; malzemedeki değer renkse Vector3 renge çevrilir.
static func _set_param(mat: ShaderMaterial, param: String, value: Variant) -> void:
	if mat.get_shader_parameter(param) is Color and value is Vector3:
		var v: Vector3 = value
		mat.set_shader_parameter(param, Color(v.x, v.y, v.z))
	else:
		mat.set_shader_parameter(param, value)


static func _has_uniform(shader: Shader, uniform_name: String) -> bool:
	for u in shader.get_shader_uniform_list(true):
		if str(u["name"]) == uniform_name:
			return true
	return false


## World altındaki bu yollardaki düğümlerin bütün meshlerinde gölge düşürmeyi kapatır (kurulumdan sonra).
func _disable_shadows_later(main: Node, paths: PackedStringArray) -> void:
	await _wait_for_build()
	for path in paths:
		var root := main.get_node_or_null(NodePath("World/" + path))
		if root == null:
			continue
		var count := 0
		for node in root.find_children("*", "GeometryInstance3D", true, false):
			(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			count += 1
		print("[nature_lab] %s: %d meshin gölgesi kapatıldı" % [path, count])


## "Yol:eğilim" çiftlerindeki düğümlerin altındaki bütün meshlerin LOD eğilimini değiştirir (kurulumdan sonra).
func _set_lod_bias_later(main: Node, pairs: PackedStringArray) -> void:
	await _wait_for_build()
	for pair in pairs:
		var kv := pair.split(":", false)
		if kv.size() != 2:
			continue
		var root := main.get_node_or_null(NodePath("World/" + kv[0]))
		if root == null:
			continue
		var count := 0
		for node in root.find_children("*", "GeometryInstance3D", true, false):
			(node as GeometryInstance3D).lod_bias = float(kv[1])
			count += 1
		print("[nature_lab] %s: %d meshin LOD eğilimi %s" % [kv[0], count, kv[1]])


## Forest ve RockField kurulumu ertelendiği için birkaç kare bekler.
func _wait_for_build() -> void:
	for i in HIDE_AFTER_FRAMES:
		await get_tree().process_frame
