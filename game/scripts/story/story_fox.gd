class_name StoryFox
extends Node3D
## Sahnenin tilkisi (E21, K110; «Çobanlık»: «Tilki! Kuzuyu bekliyor!»): türün yer tutucu modeli (kinds.json fox: kurdun iskeletli ağı ×0,45,
## turuncu boya), FaunaDirector'suz tek hayvan. Bekler (sinsice dolanır, kuzuya bakar, arada koklar), ürkünce (yakına düşen ok ya da üstüne
## koşan çocuk) döner, havlar ve dörtnal kaçar; uzakta söner. Vurulmaz: hedef grubunda değildir (ok içinden geçer, kan yok).
##   var fox := StoryFox.new(); fox.ground = shape; add_child(fox); fox.place(at, look_at)
##   fox.scare(from)        # kaçar (bir kez); fled yayılır

signal fled

const KIND := "fox"
const FLEE_SPEED := 4.2
const PACE_SPEED := 0.45
const FADE_AFTER := 34.0

var ground: Object
var state := "wait"
var watch_point := Vector3.INF

var _model: Node3D
var _anim: AnimationPlayer
var _clip := ""
var _speed := 0.0
var _goal := Vector3.INF
var _home := Vector3.ZERO
var _t := 0.0
var _run := 0.0
var _flee_dir := Vector3.ZERO
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 911
	var kind := FaunaKind.named(KIND)
	var model: Dictionary = kind.def.get("model", {}) if kind else {}
	var id := str(model.get("id", "wolf"))
	var path := "res://assets/%s/%s/%s.glb" % [str(model.get("folder", "animals")), id, id]
	var scale_k := float(model.get("scale", 0.45))
	if ResourceLoader.exists(path):
		_model = (load(path) as PackedScene).instantiate() as Node3D
		_model.scale = Vector3.ONE * scale_k
		add_child(_model)
		_anim = _find_player(_model)
		var tint := Color(str(model.get("tint", "#d98a4e")))
		for node in _model.find_children("*", "MeshInstance3D", true, false):
			var mi := node as MeshInstance3D
			for s in mi.mesh.get_surface_count() if mi.mesh else 0:
				var mat := mi.get_active_material(s) as BaseMaterial3D
				if mat:
					var copy := mat.duplicate() as BaseMaterial3D
					copy.albedo_color = copy.albedo_color * tint
					mi.set_surface_override_material(s, copy)
	_play("idle", 1.0)


## Yerine koyar ve neye bakacağını verir.
func place(at: Vector3, look_point: Vector3) -> void:
	_home = at
	watch_point = look_point
	global_position = _ground(at)
	_face(look_point, 1.0)
	_goal = Vector3.INF
	state = "wait"
	visible = true


## Ürker: from'dan uzağa dörtnal kaçar (bir kez).
func scare(from: Vector3) -> void:
	if state != "wait":
		return
	state = "flee"
	var away := global_position - from
	away.y = 0.0
	_flee_dir = away.normalized() if away.length() > 0.1 else Vector3.LEFT
	_run = 0.0
	fled.emit()


func is_waiting() -> bool:
	return state == "wait"


func _process(delta: float) -> void:
	_t += delta
	match state:
		"wait":
			# Sinsice dolanır: evinin çevresinde kısa yürüyüşler, kuzuya bakar, arada koklar (graze).
			if _goal == Vector3.INF or Vector2(global_position.x - _goal.x, global_position.z - _goal.z).length() < 0.2:
				if _rng.randf() < delta * 0.5:
					var a := _rng.randf() * TAU
					_goal = _home + Vector3(cos(a), 0.0, sin(a)) * _rng.randf_range(0.6, 2.4)
				else:
					_speed = move_toward(_speed, 0.0, delta * 2.0)
					if watch_point != Vector3.INF:
						_face(watch_point, delta * 3.0)
					_play("graze" if fmod(_t, 9.0) < 2.5 else "idle", 1.0)
					return
			var to := _goal - global_position
			to.y = 0.0
			_speed = move_toward(_speed, PACE_SPEED, delta * 1.5)
			var step := to.normalized() * minf(_speed * delta, to.length())
			global_position = _ground(global_position + step)
			_face(global_position + to, delta * 4.0)
			_play("walk", _speed / maxf(1.2 * _model_scale(), 0.1))
		"flee":
			_run += delta
			_speed = move_toward(_speed, FLEE_SPEED, delta * 6.0)
			global_position = _ground(global_position + _flee_dir * _speed * delta)
			_face(global_position + _flee_dir, delta * 8.0)
			_play("gallop", _speed / maxf(9.0 * _model_scale(), 0.1))
			if _run * FLEE_SPEED > FADE_AFTER:
				state = "gone"
				visible = false


func _face(target: Vector3, k: float) -> void:
	var to := target - global_position
	if Vector2(to.x, to.z).length() < 0.01:
		return
	rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), clampf(k, 0.0, 1.0))


func _ground(p: Vector3) -> Vector3:
	if ground and ground.has_method(&"height_at"):
		return Vector3(p.x, float(ground.call(&"height_at", p.x, p.z)), p.z)
	return p


func _model_scale() -> float:
	return _model.scale.x if _model else 0.45


func _play(clip: String, scale: float) -> void:
	if _anim == null:
		return
	if not _anim.has_animation(clip):
		clip = "idle" if _anim.has_animation("idle") else ""
		if clip.is_empty():
			return
	if clip != _clip or not _anim.is_playing():
		_anim.play(clip, 0.25)
		_clip = clip
	_anim.speed_scale = clampf(scale, 0.4, 2.2)


static func _find_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root
	for child in root.get_children():
		var hit := _find_player(child)
		if hit:
			return hit
	return null
