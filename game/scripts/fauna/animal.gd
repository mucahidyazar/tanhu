class_name Animal
extends Node3D
## T0 hayvan (fauna.md §10; varlik-hatti.md öneri 5'in AnimalAvatar kalıbı; K65): türün iskeletli Meshy modeli (Skeleton3D; AnimationPlayer'da
## idle, graze, walk, trot, gallop; tools/blender/quadruped_rig.py) FaunaDirector'un bir ajanını izler. Klip durumla ve hızla seçilir, klibin
## hızı ayağın kaymasın diye adımın hızına oranlanır (kliplerin hızı assets/animals/<id>/<id>.json'dadır, f = v / L). Yer tutucu tür (K89:
## tilki kurdun ağıyla ×0,45, yaban keçisi ceylanın ağıyla ×1,2) aynı ağı ölçek ve renk çarpanıyla taşır; Meshy modeli gelince yalnız
## kinds.json'un model.id'si değişir. Modelsiz tür (yaban domuzu) kodla çizilir: tek örnekli MultiMesh, sürü gölgelendiricisi.
## Ekran dışında AnimationPlayer durur (VisibleOnScreenEnabler3D). FaunaLayer kurar ve bırakır: T0 en çok 8'dir (K65).
## Ok sözleşmesi «targets» grubundadır (ArrowField; SmallGame ile aynı adlar): hit(point), hit_center(), hit_radius, is_hittable(), startle(from),
## is_down(), kind_id; vuruş FaunaDirector.hit'e gider (can, kaçış, yaban domuzunun saldırısı).
##   var a := Animal.new()
##   a.bind(director, slot, scene, world.ground)   # ağaca eklemeden önce
##   add_child(a)

const GROUP := &"targets"
## Okun varsayılan hasarı (ödünç yay ve sapanın sayısı Combat'a gelene dek; survival.md §4.5).
const HIT_DAMAGE := 15.0
const BLEND_S := 0.25
const TURN_SHARPNESS := 8.0
## Klip hızının oynayabileceği aralık (ayak kaymasın, canlandırma bozulmasın).
const SPEED_SCALE := Vector2(0.55, 1.9)

var director: FaunaDirector
var slot := -1
var kind: FaunaKind
var kind_id := ""
var ground: TerrainShape
var hit_radius := 0.5

var _model: Node3D
var _player: AnimationPlayer
var _clip := ""
var _clips: Dictionary = {}
var _yaw := 0.0
var _drawn: MultiMeshInstance3D
var _drawn_mm: MultiMesh
var _phase := 0.0
var _graze := 0.0
var _down_k := 0.0


## Kurulum (ağaca eklenmeden önce): yönetmen, ajanın yuvası, türün modeli (yoksa kodla çizilir), yükseklik yüzü.
func bind(p_director: FaunaDirector, p_slot: int, scene: PackedScene, shape: TerrainShape) -> void:
	director = p_director
	slot = p_slot
	kind = director.kinds[slot]
	kind_id = kind.id
	ground = shape
	name = "Animal_%s_%d" % [kind_id.to_pascal_case(), slot]
	hit_radius = clampf(kind.length * kind.model_scale() * 0.32, 0.25, 0.9)
	var s := kind.model_scale()
	if scene:
		_model = scene.instantiate() as Node3D
		_model.scale = Vector3.ONE * s
		add_child(_model)
		_player = _find_player(_model)
		_tint(_model, kind.tint())
		_clips = _clip_table()
		_model.add_child(_enabler())
	else:
		_build_drawn()
	_yaw = atan2(director.facing[slot].x, director.facing[slot].y)
	_follow(0.0, true)


func _ready() -> void:
	add_to_group(GROUP)
	if _player:
		_play("idle", 1.0)


# --- Ok sözleşmesi -------------------------------------------------------------------------------------------

func is_hittable() -> bool:
	return _alive() and director.state[slot] != FaunaDirector.State.DOWN and visible


func is_down() -> bool:
	return _alive() and director.state[slot] == FaunaDirector.State.DOWN


func hit_center() -> Vector3:
	return global_position + Vector3(0.0, kind.shoulder * kind.model_scale() * 0.7 if kind.shoulder > 0.0 else 0.3, 0.0)


## Ok değdi: yönetmenin canına işler (kaçar, düşer ya da yaban domuzu saldırır). Döner: vuruş sayıldı mı?
func hit(point: Vector3, damage: float = HIT_DAMAGE) -> bool:
	if not is_hittable():
		return false
	return director.hit(slot, damage, Vector2(point.x, point.z) if _alive() else Vector2.ZERO)


## Iska yakına düştü: hayvan ürker.
func startle(from: Vector3) -> void:
	if _alive():
		director.startle(slot, Vector2(from.x, from.z))


# --- Kare ---------------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if not _alive():
		return
	_follow(delta, false)
	if _player:
		_animate()
	elif _drawn:
		_write_drawn(delta)


## Ajanın ara değerli yeri, yönü ve zeminin yüksekliği; düşen hayvan yan yatar.
func _follow(delta: float, snap: bool) -> void:
	var p := director.agent_position(slot)
	var f := director.facing[slot]
	var target := atan2(f.x, f.y)
	_yaw = target if snap else lerp_angle(_yaw, target, 1.0 - exp(-TURN_SHARPNESS * delta))
	var y := ground.height_at(p.x, p.y) if ground else 0.0
	var down := director.state[slot] == FaunaDirector.State.DOWN
	_down_k = 1.0 if snap and down else move_toward(_down_k, 1.0 if down else 0.0, delta * 2.5)
	position = Vector3(p.x, y + kind.length * kind.model_scale() * 0.1 * _down_k, p.y)
	basis = Basis(Vector3.UP, _yaw) * Basis(Vector3.BACK, _down_k * PI * 0.5)


## Klip: durum ve hız (dururken idle ya da graze; yürüme, tırıs, dörtnal hızla); klip hızı v / klibin hızı.
func _animate() -> void:
	var st := director.state[slot]
	if st == FaunaDirector.State.DOWN:
		if _player.is_playing():
			_player.pause()
		return
	var v := director.speed[slot]
	var clip := "idle"
	var scale := 1.0
	if v < 0.2:
		clip = "graze" if director.head[slot] > 0.7 and _clips.has("graze") else "idle"
		scale = 0.6 if st == FaunaDirector.State.REST else 1.0
	else:
		var walk := _clip_speed("walk")
		var trot := _clip_speed("trot")
		var gallop := _clip_speed("gallop")
		if v < (walk + trot) * 0.5 or not _clips.has("trot"):
			clip = "walk"
			scale = v / walk
		elif v < (trot + gallop) * 0.5 or not _clips.has("gallop"):
			clip = "trot"
			scale = v / trot
		else:
			clip = "gallop"
			scale = v / gallop
	_play(clip, clampf(scale, SPEED_SCALE.x, SPEED_SCALE.y))


func _play(clip: String, scale: float) -> void:
	if _player == null:
		return
	if not _player.has_animation(clip):
		clip = "idle" if _player.has_animation("idle") else ""
		if clip.is_empty():
			return
	if clip != _clip or not _player.is_playing():
		_player.play(clip, BLEND_S)
		_clip = clip
	_player.speed_scale = scale


## Klibin yer hızı (m/sn): modelin klibinden, türün ölçeğiyle.
func _clip_speed(clip: String) -> float:
	var row: Dictionary = _clips.get(clip, {})
	return maxf(float(row.get("speed_mps", kind.speed(clip, 1.0))) * kind.model_scale(), 0.1)


func _alive() -> bool:
	return director != null and slot >= 0 and director.used[slot] == 1 and director.kinds[slot] == kind


# --- Kurulum yardımcıları ---------------------------------------------------------------------------------------

func _find_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root
	for child in root.get_children():
		var hit_player := _find_player(child)
		if hit_player:
			return hit_player
	return null


## Modelin klip tablosu (assets/animals/<id>/<id>.json clips).
func _clip_table() -> Dictionary:
	var model: Dictionary = kind.def.get("model", {})
	var id := str(model.get("id", kind_id))
	var path := "res://assets/%s/%s/%s.json" % [str(model.get("folder", "animals")), id, id]
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return (parsed as Dictionary).get("clips", {}) if parsed is Dictionary else {}


## Yer tutucunun renk çarpanı: dokulu malzemenin kopyasına albedo rengi (doku × renk).
func _tint(root: Node, color: Color) -> void:
	if color == Color.WHITE:
		return
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		for s in mi.mesh.get_surface_count() if mi.mesh else 0:
			var mat := mi.get_active_material(s) as BaseMaterial3D
			if mat:
				var copy := mat.duplicate() as BaseMaterial3D
				copy.albedo_color = copy.albedo_color * color
				mi.set_surface_override_material(s, copy)


## Ekran dışında AnimationPlayer durur (fauna.md §10).
func _enabler() -> VisibleOnScreenEnabler3D:
	var e := VisibleOnScreenEnabler3D.new()
	e.name = "OnScreen"
	var l := kind.length * kind.model_scale()
	e.aabb = AABB(Vector3(-l * 0.5, 0.0, -l * 0.6) / maxf(kind.model_scale(), 0.01), Vector3(l, l * 1.2, l * 1.2) / maxf(kind.model_scale(), 0.01))
	if _player:
		e.enable_node_path = e.get_path_to(_player) if e.is_inside_tree() else NodePath("../" + str(_model.get_path_to(_player)))
	return e


## Modelsiz tür: kodla çizilen ağ, tek örnekli MultiMesh (sürü gölgelendiricisi; INSTANCE_CUSTOM: evre, genlik, otlama, tohum).
func _build_drawn() -> void:
	var data := FaunaMesh.arrays(kind.drawn())
	if data.is_empty():
		return
	_drawn_mm = MultiMesh.new()
	_drawn_mm.transform_format = MultiMesh.TRANSFORM_3D
	_drawn_mm.use_custom_data = true
	_drawn_mm.mesh = FaunaMesh.make_mesh(data)
	_drawn_mm.instance_count = 1
	var mat := ShaderMaterial.new()
	mat.shader = AgentCrowd.SHADER
	for key: String in FaunaMesh.herd_params(kind.drawn()):
		mat.set_shader_parameter(key, FaunaMesh.herd_params(kind.drawn())[key])
	mat.set_shader_parameter(&"ram_share", 0.0)
	mat.set_shader_parameter(&"dark_share", 0.0)
	mat.set_shader_parameter(&"curl_strength", 0.2)
	mat.set_shader_parameter(&"wool_warm", Color.WHITE)
	mat.set_shader_parameter(&"wool_cool", Color(0.94, 0.94, 0.94))
	_drawn = MultiMeshInstance3D.new()
	_drawn.name = "Drawn"
	_drawn.multimesh = _drawn_mm
	_drawn.material_override = mat
	_drawn.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(_drawn)


func _write_drawn(delta: float) -> void:
	var v := director.speed[slot]
	var strides := Vector3(kind.stride("walk", 0.9), kind.stride("trot", 1.5), kind.stride("gallop", 2.6))
	var stride := lerpf(strides.x, strides.y, clampf((v - kind.speed("walk", 1.0)) / maxf(kind.speed("trot", 2.5) - kind.speed("walk", 1.0), 0.01), 0.0, 1.0))
	if v > kind.speed("trot", 2.5):
		stride = lerpf(strides.y, strides.z, clampf((v - kind.speed("trot", 2.5)) / maxf(kind.peak_speed() - kind.speed("trot", 2.5), 0.01), 0.0, 1.0))
	if v > 0.01:
		_phase = fposmod(_phase + v / stride * delta, 1.0)
	_graze = move_toward(_graze, director.head[slot], delta * 1.6)
	var down := director.state[slot] == FaunaDirector.State.DOWN
	var amp := 0.0 if down else HerdField.swing_amplitude(v, stride, FaunaMesh.BOAR_HIP)
	_drawn_mm.set_instance_transform(0, Transform3D.IDENTITY)
	_drawn_mm.set_instance_custom_data(0, Color(_phase, amp, _graze, float(slot) / float(FaunaDirector.MAX_AGENTS)))
