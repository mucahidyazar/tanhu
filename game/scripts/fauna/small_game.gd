class_name SmallGame
extends Procedural3D
## Kodla çizilen küçük av (fauna.md §10; story.md §5): tarla kuşu, keklik, karga, tarbagan, kum faresi; Kışlak'ta tavşan (mode «run»: zikzak
## kaçar, ine girmez; act-1-p2). Ağ FaunaMesh'ten, kanat, gagalama,
## koşu ve dikilme köşe gölgelendiricisindedir (shaders/small_game.gdshader); düğüm yalnız yer değiştirir. Boştayken _process yoktur:
## SmallGameField tek yerden sürer (SmallGameField.advance), hareket etmeyen hayvan kare başına iş yapmaz.
##
## Yay için arayüz (ok küttür, kan yoktur; vurulan düşer, çocuk alır):
##   grup "targets" (GROUP)   vurulabilen hayvanlar: oyun buradan bulur; vurulan gruptan çıkar, "fallen_game"e (FALLEN_GROUP) girer.
##   hit(point: Vector3) -> bool   ok buraya değdi (dünya noktası): düşer. Vurulabilir değilse false (saklanmış, düşmüş, alınmış).
##   hit_center() -> Vector3, hit_radius   vuruş denemesinin küresi (metre; dünya).
##   is_hittable() -> bool, is_down() -> bool, collected (alındı mı?), kind_id
##   collect() -> Dictionary  düşmüş hayvanı çocuk alır: görünmez olur; döner: {kind: id, yield: {eşya: adet}} (düşmemişse boş).
##   startle(from: Vector3)   ıska yakına düştü, hayvan ürker (kaçar; ıska bedavadır).
## Sinyaller: fell(target) düşüp yere değdi; picked_up(target) alındı; alarmed(target) kaçmaya başladı (tarbagan ıslığı buradan çalar).

signal fell(target: SmallGame)
signal picked_up(target: SmallGame)
signal alarmed(target: SmallGame)
## İç: hareket başladı, sürücü kare başına ilerletsin (SmallGameField).
signal woke(target: SmallGame)

enum State { FORAGE, WALK, FLIGHT, RUN, HIDDEN, FALLING, DOWN, COLLECTED }

const SHADER := preload("res://shaders/small_game.gdshader")
const GROUP := &"targets"
const FALLEN_GROUP := &"fallen_game"
## Yerçekimi (m/sn²), düşerken dönüş hızı (rad/sn).
const GRAVITY := 9.8
const FALL_ROLL_SPEED := 7.0
## Küt vuruşta sıçrama (m/sn) ve yana itme (m/sn).
const KNOCK_UP := 1.6
const KNOCK_SIDE := 1.1
## Pozun (fly, run, rear) geçiş hızı (1/sn).
const POSE_RATE := 5.0

var kind_id := ""
var kind: FaunaKind
var state := State.FORAGE
## Alındı mı?
var collected := false
## Vuruş küresinin yarıçapı ve merkezinin yerden yüksekliği (metre; dünya).
var hit_radius := 0.35
var body_height := 0.1
## Ev lekeleri Vector3(x, z, yarıçap): otladığı kısa otlu yerler; kuş bunlar arasında uçar.
var patches: Array[Vector3] = []
## İn ağızları (mode "burrow").
var holes := PackedVector2Array()
## Yükseklik yüzü.
var shape: TerrainShape
var rng := RandomNumberGenerator.new()
## Sürücünün saati (saniye; SmallGameField yazar).
var clock_time := 0.0

var _mode := "fly"
var _mesh: Mesh
var _material: Material
var _visual: MeshInstance3D
var _seed := 0.0
var _pose := Vector3.ZERO
var _pose_target := Vector3.ZERO
var _home := 0
var _from := Vector3.ZERO
var _goal := Vector3.ZERO
var _t := 0.0
var _duration := 0.0
var _speed := 1.0
var _arc := 0.0
var _hop := 0.0
var _hide_at_goal := false
var _next_think := 0.0
var _resume_at := 0.0
var _vel := Vector3.ZERO
var _roll := 0.0
var _roll_sign := 1.0
var _idle_range := Vector2(2.0, 5.0)
## Zikzak kaçışın noktaları ve sıradaki bacak (mode «run»).
var _zig := PackedVector2Array()
var _zig_i := 0


## Kurulum (ağaca eklenmeden önce): tür, paylaşılan ağ ve malzeme, ev lekeleri, inler, yüzey, tohum.
func configure(p_kind: FaunaKind, mesh: Mesh, material: Material, p_patches: Array[Vector3], p_holes: PackedVector2Array, p_shape: TerrainShape, seed_value: int) -> void:
	kind = p_kind
	kind_id = p_kind.id
	_mesh = mesh
	_material = material
	patches = p_patches
	holes = p_holes
	shape = p_shape
	rng.seed = seed_value
	_seed = rng.randf()
	_mode = str(kind.game_value("mode", "fly"))
	hit_radius = float(kind.game_value("hit_radius", 0.35))
	body_height = float(kind.game_value("body_height", 0.1))
	var idle: Array = kind.game_value("idle", [2.0, 5.0])
	_idle_range = Vector2(float(idle[0]), float(idle[1]))
	_hop = float(kind.game_value("hop", 0.0))
	_home = rng.randi() % maxi(patches.size(), 1)
	_next_think = rng.randf_range(0.0, _idle_range.y)
	var p := _point_in_patch(_home)
	position = Vector3(p.x, _ground(p), p.y)
	rotation.y = rng.randf() * TAU


func _ready() -> void:
	add_to_group(GROUP)
	super._ready()


func _build() -> void:
	_visual = add_mesh(_mesh, _material)
	_visual.name = "Body"
	_visual.scale = Vector3.ONE * kind.draw_scale
	_visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_apply_pose()


# --- Yay arayüzü -------------------------------------------------------------------------------------

## Vurulabilir mi (görünür, ayakta ya da uçarken)?
func is_hittable() -> bool:
	return state <= State.RUN and visible


func is_down() -> bool:
	return state == State.DOWN


## Vuruş küresinin merkezi (dünya).
func hit_center() -> Vector3:
	return global_position + Vector3(0.0, body_height, 0.0)


## Ok değdi: hayvan küt düşer (yerdeyken sıçrayıp yan yatar, uçarken süzülmeden iner). Döner: vuruş sayıldı mı?
func hit(point: Vector3) -> bool:
	if not is_hittable():
		return false
	var away := global_position - point
	away.y = 0.0
	away = away.normalized() if away.length_squared() > 0.0001 else Vector3.RIGHT
	_vel = away * KNOCK_SIDE + Vector3(0.0, KNOCK_UP if state != State.FLIGHT else 0.2, 0.0)
	_roll_sign = 1.0 if away.dot(global_basis.x) >= 0.0 else -1.0
	_set_state(State.FALLING)
	_pose_target = Vector3(0.3 if _mode == "fly" else 0.0, 0.0, 0.0)
	remove_from_group(GROUP)
	add_to_group(FALLEN_GROUP)
	_activate()
	return true


## Düşmüş hayvanı çocuk alır. Döner: {kind, yield}; düşmemişse ya da alınmışsa boş.
func collect() -> Dictionary:
	if state != State.DOWN:
		return {}
	collected = true
	state = State.COLLECTED
	visible = false
	remove_from_group(FALLEN_GROUP)
	picked_up.emit(self)
	return {"kind": kind_id, "yield": (kind.def.get("yield", {}) as Dictionary).duplicate()}


## Yakında bir şey oldu (ıska, oyuncu): hayvan kaçar. Kuş başka lekeye uçar, kemirgen inine koşar.
func startle(from: Vector3) -> void:
	if state > State.WALK:
		return
	if _mode == "burrow" and not holes.is_empty():
		_run_to_hole()
	elif _mode == "run":
		_run_away(from)
	else:
		_fly_away(from)
	alarmed.emit(self)


# --- Davranış (SmallGameField sürer) -----------------------------------------------------------------

## Tehdit kaçış uzaklığında mı? (saf değil, konuma bakar)
func threatened_by(threat: Vector3) -> bool:
	if state > State.WALK:
		return false
	var scare := float(kind.game_value("scare_radius", 4.0))
	var off := Vector2(threat.x - global_position.x, threat.z - global_position.z)
	return off.length_squared() < scare * scare


## Düşük sıklıkta karar (5 Hz): bekleyen hayvan yürür ya da dikilir; saklanan hayvan zamanı gelince çıkar.
func think(now: float, threat: Vector3, has_threat: bool) -> void:
	match state:
		State.HIDDEN:
			if now >= _resume_at and (not has_threat or not _near_hole_threat(threat)):
				_emerge()
		State.FORAGE:
			if now < _next_think:
				return
			_next_think = now + rng.randf_range(_idle_range.x, _idle_range.y)
			var sentinel := float(kind.game_value("sentinel", 0.0))
			if sentinel > 0.0 and rng.randf() < sentinel:
				_pose_target.z = 1.0 if _pose_target.z < 0.5 else 0.0
				_activate()
			else:
				_pose_target.z = 0.0
				_walk_a_little()


## Kare başına yalnız hareket eden hayvanda çağrılır. Döner: hâlâ hareketli mi?
func advance(delta: float) -> bool:
	var moving := false
	match state:
		State.WALK, State.RUN:
			moving = _advance_ground(delta)
		State.FLIGHT:
			moving = _advance_flight(delta)
		State.FALLING:
			moving = _advance_fall(delta)
	var pose_done := _pose.is_equal_approx(_pose_target)
	if not pose_done:
		_pose = _pose.move_toward(_pose_target, POSE_RATE * delta)
		_apply_pose()
	return moving or not pose_done


func _activate() -> void:
	woke.emit(self)


func _set_state(next: State) -> void:
	state = next


func _walk_a_little() -> void:
	var p := _point_in_patch(_home)
	_begin_ground(p, kind.speed("walk", 0.8) * rng.randf_range(0.8, 1.1), false)
	_set_state(State.WALK)
	_pose_target.y = 0.5 if _mode == "burrow" else 0.0


func _run_to_hole() -> void:
	var here := Vector2(global_position.x, global_position.z)
	var best := holes[0]
	for h in holes:
		if h.distance_squared_to(here) < best.distance_squared_to(here):
			best = h
	_begin_ground(best, kind.speed("flee", 3.0), true)
	_set_state(State.RUN)
	_pose_target = Vector3(0.0, 1.0, 0.0)


## Tavşan zikzak kaçar (fauna.md §1; mode «run»): tehditten uzağa, yönü her bacakta ±35° dönen kırık bir yol; ilk bacaklar tepe hızla, sonra
## sürek hızla; sonunda olduğu yerde otlar (ine girmez). Bacak sayısı game.zigzag, yolun boyu game.run_distance.
func _run_away(from: Vector3) -> void:
	var here := Vector2(global_position.x, global_position.z)
	var away := here - Vector2(from.x, from.z)
	away = away.normalized() if away.length_squared() > 0.0001 else Vector2.from_angle(rng.randf() * TAU)
	var legs := maxi(int(kind.game_value("zigzag", 4)), 1)
	var span: Array = kind.game_value("run_distance", [24.0, 36.0])
	var total := rng.randf_range(float(span[0]), float(span[1]))
	_zig = PackedVector2Array()
	var at := here
	for k in legs:
		var turn := deg_to_rad(35.0) * (1.0 if k % 2 == 0 else -1.0) * rng.randf_range(0.6, 1.0)
		at += away.rotated(turn) * (total / float(legs))
		_zig.append(at)
	_zig_i = 0
	_next_leg()


func _next_leg() -> void:
	if _zig_i >= _zig.size():
		return
	var fast := _zig_i < maxi(_zig.size() / 2, 1)
	var spd := kind.speed("flee", 8.0) if fast else kind.speed("sustained", kind.speed("flee", 8.0) * 0.7)
	_begin_ground(_zig[_zig_i], spd * rng.randf_range(0.9, 1.05), false)
	_zig_i += 1
	_set_state(State.RUN)
	_pose_target = Vector3(0.0, 1.0, 0.0)


func _begin_ground(target: Vector2, speed: float, hide_there: bool) -> void:
	_from = global_position
	_goal = Vector3(target.x, _ground(target), target.y)
	_speed = maxf(speed, 0.05)
	_t = 0.0
	_duration = maxf(Vector2(_goal.x - _from.x, _goal.z - _from.z).length() / _speed, 0.05)
	_hide_at_goal = hide_there
	_face(_goal - _from)
	_activate()


func _advance_ground(delta: float) -> bool:
	_t = minf(_t + delta / _duration, 1.0)
	var p := _from.lerp(_goal, _t)
	var hop := 0.0
	if _hop > 0.0 and state == State.WALK:
		hop = absf(sin(_t * _duration * 9.0)) * _hop
	elif _mode == "run" and state == State.RUN:
		# Tavşanın sıçrayışı: koşuda gövde adımla kalkar.
		hop = absf(sin(_t * _duration * 11.0)) * 0.09
	global_position = Vector3(p.x, p.y + hop, p.z)
	if _t < 1.0:
		return true
	if _mode == "run" and state == State.RUN and _zig_i < _zig.size():
		_next_leg()
		return true
	if _hide_at_goal:
		visible = false
		_set_state(State.HIDDEN)
		var hide_for: Array = kind.game_value("hide", [5.0, 10.0])
		_resume_at = clock_time + rng.randf_range(float(hide_for[0]), float(hide_for[1]))
		_pose_target = Vector3.ZERO
		_pose = Vector3.ZERO
		_apply_pose()
		return false
	_set_state(State.FORAGE)
	_pose_target.y = 0.0
	return false


func _fly_away(from: Vector3) -> void:
	_home = _farthest_patch(from)
	var p := _point_in_patch(_home)
	_begin_flight(p)


func _begin_flight(target: Vector2) -> void:
	_from = global_position
	_goal = Vector3(target.x, _ground(target), target.y)
	_speed = kind.speed("flight", 7.0) * rng.randf_range(0.92, 1.1)
	_duration = maxf(_from.distance_to(_goal) / _speed, 0.6)
	_arc = float(kind.game_value("flight_height", 3.0)) * rng.randf_range(0.85, 1.15)
	_t = 0.0
	_set_state(State.FLIGHT)
	_pose_target = Vector3(1.0, 0.0, 0.0)
	_face(_goal - _from)
	_activate()


func _advance_flight(delta: float) -> bool:
	_t = minf(_t + delta / _duration, 1.0)
	var p := _from.lerp(_goal, _t)
	# Hızlı yükselir, süzülerek iner.
	var rise := pow(sin(_t * PI), 0.75) * _arc
	global_position = Vector3(p.x, p.y + rise, p.z)
	if _t >= 0.88:
		_pose_target.x = 0.0
	if _t < 1.0:
		return true
	_set_state(State.FORAGE)
	_next_think = clock_time + rng.randf_range(_idle_range.x, _idle_range.y)
	return false


func _advance_fall(delta: float) -> bool:
	_vel.y -= GRAVITY * delta
	var p := global_position + _vel * delta
	var floor_y := _ground(Vector2(p.x, p.z))
	_roll = minf(_roll + FALL_ROLL_SPEED * delta, PI * 0.5)
	_apply_roll()
	if p.y > floor_y:
		global_position = p
		return true
	global_position = Vector3(p.x, floor_y, p.z)
	if _roll < PI * 0.5 - 0.001:
		_vel = Vector3.ZERO
		return true
	_set_state(State.DOWN)
	_pose_target.x = 0.0
	fell.emit(self)
	return false


## Yan yatış: gövde kendi merkezi çevresinde döner, yana yatınca yere oturur (body_height'ın bir kısmı inmiş).
func _apply_roll() -> void:
	var r := _roll_sign * _roll
	var basis := Basis(Vector3.FORWARD, r)
	var c := Vector3(0.0, body_height, 0.0)
	var settled := _roll / (PI * 0.5)
	var sink := body_height * 0.55 * settled
	_visual.transform = Transform3D(basis.scaled(Vector3.ONE * kind.draw_scale), c - basis * c - Vector3(0.0, sink, 0.0))


func _emerge() -> void:
	visible = true
	_set_state(State.FORAGE)
	_home = rng.randi() % maxi(patches.size(), 1)
	_next_think = clock_time + rng.randf_range(0.2, 1.2)
	# Çıkınca etrafına bakar.
	if float(kind.game_value("sentinel", 0.0)) > 0.0:
		_pose_target.z = 1.0
		_activate()


func _near_hole_threat(threat: Vector3) -> bool:
	var scare := float(kind.game_value("scare_radius", 4.0))
	var off := Vector2(threat.x - global_position.x, threat.z - global_position.z)
	return off.length_squared() < scare * scare


func _farthest_patch(from: Vector3) -> int:
	var best := _home
	var best_d := -1.0
	for i in patches.size():
		var c := patches[i]
		var d := Vector2(c.x - from.x, c.y - from.z).length_squared() * rng.randf_range(0.6, 1.0)
		if d > best_d:
			best_d = d
			best = i
	return best


func _point_in_patch(index: int) -> Vector2:
	if patches.is_empty():
		return Vector2(position.x, position.z)
	var c := patches[clampi(index, 0, patches.size() - 1)]
	var r := sqrt(rng.randf()) * c.z * 0.82
	return Vector2(c.x, c.y) + Vector2.from_angle(rng.randf() * TAU) * r


func _ground(p: Vector2) -> float:
	return shape.height_at(p.x, p.y) if shape else 0.0


func _face(dir: Vector3) -> void:
	if Vector2(dir.x, dir.z).length_squared() > 0.0001:
		rotation.y = atan2(dir.x, dir.z)


func _apply_pose() -> void:
	if _visual:
		_visual.set_instance_shader_parameter(&"pose", Vector4(_pose.x, _pose.y, _pose.z, _seed))

