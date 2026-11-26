class_name AgentCrowd
extends Node3D
## Ajanların uzak kademesi (T1; fauna.md §10 «Sürü», godot.md §4.5): tür başına tek MultiMeshInstance3D, iskelet yok. FaunaDirector'un o türden
## ajanlarını ara değerli yerleriyle çizer; T0'a yükselen (Animal) burada gizlenir (hide_slot). Ağ türün uzak ağıdır (assets/animals/<id>/<id>_far.glb,
## ≤1.800 üçgen; FaunaMesh.from_model köşe rengine çevirir, eklemleri kinds.json «herd»ün oranlarından); yer tutucu türde (tilki, yaban keçisi) ölçek
## ve renk çarpanı kinds.json «model»dendir; modelsiz türde (yaban domuzu) FaunaMesh'in kodla çizdiği ağdır. Adım, otlama ve kuyruk
## herd_field.gdshader'dadır (INSTANCE_CUSTOM: evre, genlik, otlama, tohum). Ağ arka planda yüklenir; gelene dek tür görünmez (modelsizse hemen).
##   var crowd := AgentCrowd.new()
##   crowd.setup(director, FaunaKind.named("gazelle"), world.ground)
##   crowd.hide_slot(i, true)     # T0'a geçti

const SHADER := preload("res://shaders/herd_field.gdshader")
const FLOATS := 16
## Kırpma kutusunun yarı boyu (m): bütün harita (düğüm kökte; tampon her kare yazılır).
const CULL_HALF := Vector3(1000.0, 120.0, 1000.0)
const TURN_SHARPNESS := 7.0
const SPEED_RATE := 6.0
const GRAZE_RATE := 1.6

var director: FaunaDirector
var kind: FaunaKind
var ground: TerrainShape
var instance: MultiMeshInstance3D

var _mm: MultiMesh
var _material: ShaderMaterial
var _buffer := PackedFloat32Array()
var _hidden := PackedByteArray()
var _yaw := PackedFloat32Array()
var _phase := PackedFloat32Array()
var _speed := PackedFloat32Array()
var _graze := PackedFloat32Array()
var _seed := PackedFloat32Array()
var _ready_mesh := false
var _model_path := ""
var _model_state := 0
var _job: _MeshJob
var _strides := Vector3(0.8, 1.2, 2.0)
var _speeds := Vector3(1.0, 3.0, 9.0)
var _leg := 0.4
var _scale := 1.0


## İş parçacığında uzak ağın sürü ağına çevrilmesi.
class _MeshJob:
	extends RefCounted
	var surface: Array = []
	var image: Image
	var length := 1.0
	var ratios: Dictionary = {}
	var result: Dictionary = {}
	var task_id := -1
	var waited := false

	func run() -> void:
		if image and image.is_compressed():
			image.decompress()
		result = FaunaMesh.from_model(surface, length, 1800, image, ratios)


## Kurulum (ağaca eklenmeden önce).
func setup(p_director: FaunaDirector, p_kind: FaunaKind, shape: TerrainShape) -> void:
	director = p_director
	kind = p_kind
	ground = shape
	name = "Crowd_%s" % kind.id.to_pascal_case()
	_scale = kind.model_scale()
	_strides = Vector3(kind.stride("walk", 0.8), kind.stride("trot", 1.2), kind.stride("gallop", 2.0))
	_speeds = Vector3(kind.speed("walk", 1.0), kind.speed("trot", 3.0), maxf(kind.speed("gallop", kind.peak_speed()), kind.speed("trot", 3.0) + 0.5))
	var n := FaunaDirector.MAX_AGENTS
	_buffer.resize(n * FLOATS)
	_hidden.resize(n)
	_yaw.resize(n)
	_phase.resize(n)
	_speed.resize(n)
	_graze.resize(n)
	_seed.resize(n)
	for i in n:
		_seed[i] = fposmod(float(i) * 0.6180339 + float(hash(kind.id) % 97) / 97.0, 1.0)
		_phase[i] = _seed[i]
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_custom_data = true
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	instance = MultiMeshInstance3D.new()
	instance.name = "T1"
	instance.multimesh = _mm
	instance.material_override = _material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	instance.custom_aabb = AABB(-CULL_HALF, CULL_HALF * 2.0)
	add_child(instance)
	_apply_look()
	var drawn := kind.drawn()
	if not drawn.is_empty():
		_adopt(FaunaMesh.arrays(drawn), FaunaMesh.herd_params(drawn))
	else:
		_model_path = kind.far_model_path()
		if _model_path.is_empty() or not ResourceLoader.exists(_model_path):
			_model_path = kind.model_path()


func _ready() -> void:
	if _ready_mesh or _model_path.is_empty() or not MeshyProp.models_enabled or not ResourceLoader.exists(_model_path):
		return
	# Başsızda eşzamanlı (FaunaMesh.background_loads: boş çizicinin kimlikleri iş parçacığına karşı korunmuyor).
	if not FaunaMesh.background_loads():
		_start_job(load(_model_path) as PackedScene)
	elif ResourceLoader.load_threaded_request(_model_path, "", false) == OK:
		_model_state = 1


func _exit_tree() -> void:
	if _job and _job.task_id >= 0 and not _job.waited:
		WorkerThreadPool.wait_for_task_completion(_job.task_id)
		_job.waited = true
	if _model_state == 1:
		var status := ResourceLoader.load_threaded_get_status(_model_path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS or status == ResourceLoader.THREAD_LOAD_LOADED:
			ResourceLoader.load_threaded_get(_model_path)
		_model_state = 0


## Yuva T0'a geçti (Animal çiziyor): burada gizlenir.
func hide_slot(i: int, hidden: bool) -> void:
	if i >= 0 and i < _hidden.size():
		_hidden[i] = 1 if hidden else 0


## Ağ hazır mı (sınama, bütçe)?
func is_ready_mesh() -> bool:
	return _ready_mesh


## Görünen örnek sayısı.
func drawn_count() -> int:
	return _mm.visible_instance_count if _mm and _mm.visible_instance_count >= 0 else 0


func mesh_triangles() -> int:
	var mesh := _mm.mesh as ArrayMesh if _mm else null
	if mesh == null or mesh.get_surface_count() == 0:
		return 0
	return mesh.surface_get_array_index_len(0) / 3


func _process(delta: float) -> void:
	_poll_model()
	if not _ready_mesh or director == null:
		return
	_write(delta)


func _write(delta: float) -> void:
	var a := director.alpha()
	var turn := 1.0 - exp(-TURN_SHARPNESS * delta)
	var k := 0
	var shown := 0
	for i in FaunaDirector.MAX_AGENTS:
		var ki := director.kinds[i]
		if director.used[i] == 0 or ki == null or ki.id != kind.id:
			continue
		if _hidden[i] == 1:
			continue
		var p := director.prev[i].lerp(director.pos[i], a)
		var f := director.facing[i]
		var target_yaw := atan2(f.x, f.y)
		_yaw[i] = lerp_angle(_yaw[i], target_yaw, turn)
		var sp := move_toward(_speed[i], director.speed[i], SPEED_RATE * delta)
		_speed[i] = sp
		var stride := _stride_for(sp)
		if sp > 0.01:
			_phase[i] = fposmod(_phase[i] + sp / stride * delta, 1.0)
		var down := director.state[i] == FaunaDirector.State.DOWN
		_graze[i] = move_toward(_graze[i], director.head[i], GRAZE_RATE * delta)
		var s := _scale_of(i)
		var yaw := _yaw[i]
		var basis := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * s)
		if down:
			basis = Basis(Vector3.UP, yaw) * Basis(Vector3.BACK, PI * 0.5) * Basis.from_scale(Vector3.ONE * s)
		var y := ground.height_at(p.x, p.y) if ground else 0.0
		if down:
			y += kind.length * 0.12
		_buffer[k] = basis.x.x
		_buffer[k + 1] = basis.y.x
		_buffer[k + 2] = basis.z.x
		_buffer[k + 3] = p.x
		_buffer[k + 4] = basis.x.y
		_buffer[k + 5] = basis.y.y
		_buffer[k + 6] = basis.z.y
		_buffer[k + 7] = y
		_buffer[k + 8] = basis.x.z
		_buffer[k + 9] = basis.y.z
		_buffer[k + 10] = basis.z.z
		_buffer[k + 11] = p.y
		_buffer[k + 12] = _phase[i]
		_buffer[k + 13] = 0.0 if down else HerdField.swing_amplitude(sp, stride, _leg)
		_buffer[k + 14] = _graze[i]
		_buffer[k + 15] = _seed[i]
		k += FLOATS
		shown += 1
	if _mm.instance_count != FaunaDirector.MAX_AGENTS:
		_mm.instance_count = FaunaDirector.MAX_AGENTS
	# Görünmeyen örnekler tamponun sonundadır: yalnız ilk «shown» örnek çizilir.
	_mm.buffer = _buffer
	_mm.visible_instance_count = shown


## Adım boyu hızla: yürüyüşten tırısa, tırıstan dörtnala doğrusal (fauna.md §10 yürüyüş tablosu).
func _stride_for(v: float) -> float:
	if v <= _speeds.y:
		return lerpf(_strides.x, _strides.y, clampf((v - _speeds.x) / maxf(_speeds.y - _speeds.x, 0.01), 0.0, 1.0))
	return lerpf(_strides.y, _strides.z, clampf((v - _speeds.y) / maxf(_speeds.z - _speeds.y, 0.01), 0.0, 1.0))


## Ajanın boy çarpanı: türün ölçeğinin ±%6'sı (aynı sürünün hayvanları aynı boyda değildir).
func _scale_of(i: int) -> float:
	return 0.94 + 0.12 * _seed[i]


func _apply_look() -> void:
	var look := kind.herd_look()
	if look.has("graze"):
		_material.set_shader_parameter(&"graze_angle", float(look["graze"]))
	_material.set_shader_parameter(&"ram_share", 0.0)
	_material.set_shader_parameter(&"dark_share", 0.0)
	var tint := kind.tint()
	_material.set_shader_parameter(&"wool_warm", tint)
	_material.set_shader_parameter(&"wool_cool", tint.darkened(0.06))
	_material.set_shader_parameter(&"curl_strength", 0.2 if kind.drawn() == "boar" else 0.04)


func _poll_model() -> void:
	match _model_state:
		1:
			var status := ResourceLoader.load_threaded_get_status(_model_path)
			if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				return
			_model_state = 0
			if status != ResourceLoader.THREAD_LOAD_LOADED:
				push_warning("[fauna] uzak ağ yüklenemedi: %s" % _model_path)
				return
			_start_job(ResourceLoader.load_threaded_get(_model_path) as PackedScene)
		2:
			if not WorkerThreadPool.is_task_completed(_job.task_id):
				return
			WorkerThreadPool.wait_for_task_completion(_job.task_id)
			_job.waited = true
			_model_state = 0
			if _job.result.is_empty():
				push_warning("[fauna] uzak ağ okunamadı: %s" % _model_path)
			else:
				_adopt(_job.result, {"hip_height": float(_job.result["hip"]), "neck_pivot": _job.result["neck"], "tail_pivot": _job.result["tail"]})
			_job = null


func _start_job(scene: PackedScene) -> void:
	if scene == null:
		return
	var root := scene.instantiate()
	var found: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D:
		found.push_front(root)
	var mi := found[0] as MeshInstance3D if not found.is_empty() else null
	if mi == null or mi.mesh == null:
		root.free()
		return
	_job = _MeshJob.new()
	_job.surface = mi.mesh.surface_get_arrays(0)
	_job.image = FaunaMesh.model_image(mi.mesh)
	_job.length = kind.model_length() * _scale
	_job.ratios = kind.herd_look()
	root.free()
	_job.task_id = WorkerThreadPool.add_task(_job.run, true, "fauna crowd mesh")
	_model_state = 2


func _adopt(data: Dictionary, params: Dictionary) -> void:
	if data.is_empty():
		return
	_mm.mesh = FaunaMesh.make_mesh(data)
	for key: String in params:
		_material.set_shader_parameter(key, params[key])
	if params.has("hip_height"):
		_leg = float(params["hip_height"])
	_mm.instance_count = FaunaDirector.MAX_AGENTS
	_mm.visible_instance_count = 0
	_ready_mesh = true
