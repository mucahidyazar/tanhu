class_name PrologueTracks
extends MultiMeshInstance3D
## Karda iz (E21, K110; «Tipi»): yürüyenin ardında küçük, koyu ayak izleri. İz adım boyunda (step_m) sol ve sağ sırayla bırakılır, tipi onu
## fill_s'de doldurur (rengin alfası yaşla söner). En çok MAX iz; en eskisi yeniden kullanılır. Tek çizim (MultiMesh, örnek rengi).
##   var tracks := PrologueTracks.new(); root.add_child(tracks)
##   tracks.walker(player, 0.46, 0.09)       # izleyen: adım boyu, yan pay
##   tracks.tick(delta)                       # her kare

const MAX := 320
const FILL_S := 75.0
const ALPHA := 0.5

var fill_s := FILL_S
var _walkers: Array[Dictionary] = []
var _ages := PackedFloat32Array()
var _next := 0
var _ground: Callable
var _fade_left := 0.0


func _init() -> void:
	name = "SnowTracks"
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var quad := QuadMesh.new()
	quad.size = Vector2(0.1, 0.17)
	quad.orientation = PlaneMesh.FACE_Y
	mm.mesh = quad
	mm.instance_count = MAX
	mm.visible_instance_count = 0
	multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(1, 1, 1, 1)
	material_override = mat
	_ages.resize(MAX)
	_ages.fill(INF)


## Zeminin yüksekliği: func(x, z) -> y.
func set_ground(fn: Callable) -> void:
	_ground = fn


## İz bırakan (oyuncu, Börü): adım boyu (m) ve ayakların yan payı (m).
func walker(node: Node3D, step_m: float = 0.46, side_m: float = 0.09) -> void:
	_walkers.append({"node": node, "step": step_m, "side": side_m, "last": Vector3.INF, "left": true})


func tick(delta: float) -> void:
	for w: Dictionary in _walkers:
		var n: Node3D = w["node"]
		if not is_instance_valid(n) or not n.is_visible_in_tree():
			continue
		var p := n.global_position
		var last: Vector3 = w["last"]
		if last == Vector3.INF:
			w["last"] = p
			continue
		var d := Vector2(p.x - last.x, p.z - last.z)
		if d.length() < float(w["step"]):
			continue
		var dir := d.normalized()
		var side := Vector2(-dir.y, dir.x) * float(w["side"]) * (1.0 if bool(w["left"]) else -1.0)
		_print(Vector2(p.x, p.z) + side, atan2(dir.x, dir.y))
		w["left"] = not bool(w["left"])
		w["last"] = p
	# Yaşlanma: alfa 0,5 sn'de bir yazılır.
	_fade_left -= delta
	if _fade_left > 0.0:
		for i in MAX:
			_ages[i] += delta
		return
	_fade_left = 0.5
	for i in MAX:
		_ages[i] += delta
		if _ages[i] == INF:
			continue
		var a := ALPHA * (1.0 - clampf(_ages[i] / fill_s, 0.0, 1.0))
		multimesh.set_instance_color(i, Color(0.42, 0.45, 0.52, a))


func _print(at: Vector2, yaw: float) -> void:
	var i := _next
	_next = (_next + 1) % MAX
	var y := float(_ground.call(at.x, at.y)) + 0.025 if _ground.is_valid() else 0.025
	multimesh.set_instance_transform(i, Transform3D(Basis(Vector3.UP, yaw), Vector3(at.x, y, at.y)))
	multimesh.set_instance_color(i, Color(0.42, 0.45, 0.52, ALPHA))
	_ages[i] = 0.0
	multimesh.visible_instance_count = maxi(multimesh.visible_instance_count, i + 1)


## Bırakılan iz sayısı (sınama).
func count() -> int:
	var n := 0
	for a in _ages:
		if a != INF:
			n += 1
	return n
