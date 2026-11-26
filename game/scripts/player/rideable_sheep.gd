class_name RideableSheep
extends Rideable
## Binilen koyun (Çocukluk; story.md §5, fauna.md §2.1, plan bovid_s). Yerel +Z başın baktığı yöndür; düğümün yeri ayakların zeminidir. Sırtındaki oturma noktası
## (Body/Seat) sırtın yünüdür: modelin ölçüsünden (<model>.json saddle_y, saddle_z), model yoksa Mount satırının seat'inden. Binilince PlayerController onu izler,
## binicinin kalçası bunun binicinin oturuş yüksekliği kadar üstündedir.
##
## assets/animals/sheep/sheep.glb (iskeletli model; tools/blender/quadruped_rig.py) varsa o gösterilir: klipleri rollere eşlenir (CLIP_NAMES: idle, graze, walk, trot, gallop;
## bulunamayan rol en yakın klibe düşer), yürüyüş klipleri adım boyuna göre hızlanır (ayak kaymaz; adım boyu <model>.json'un klip satırından, yoksa Mount'tan). Yavaşta
## yürüme klibi, WALK_TOP'tan hızlıda tırıs klibi oynar: ikisi de doğal hızının CLIP_RATE katları içinde kalır. Malzemesi karakterlerin yumuşak toon'udur, binici gövde kemiğini izler.
## Model yoksa ya da klipsizse sürünün çizimi durur (K89; FaunaMesh'in koyunu, HerdField'ın gölgelendiricisi, tek örnekli MultiMesh): yürüyüş, otlama, soluk ve kuyruk köşede, evre ve
## genlik buradan yazılır. seed_value görünüşü seçer (yün tonu, yüz boyası, koçta boynuz; herd_field.gdshader).
##
## Binilmezken kendi kendine bekler ve ara ara otlar (_process). Binilince sürücü drive(hız, delta) çağırır; otlama durumu Mount'tan okunur.
## Binek yüzü (grup, Mount, place, oturma noktası, modelin ölçüsü, toynakların yere basması) atla ortaktır: Rideable, RideableHooves.
##   var sheep: RideableSheep = load("res://scenes/fauna/rideable_sheep.tscn").instantiate()
##   sheep.set_ridden(true); sheep.drive(speed, delta); sheep.place(pos, yaw, pitch)
##   sheep.seat_transform()                # binicinin kalçasının dünya dönüşümü

const MODEL_PATH := "res://assets/animals/sheep/sheep.glb"
## Rol → modelin klip adında aranan parçalar (sırayla). Modelin «run» klibi tırıstır (2,5 m/sn, adım 1,19 m); dörtnal klibi yoksa o hızlanır (en çok CLIP_RATE.y kat).
const CLIP_NAMES := {&"idle": ["idle", "stand"], &"graze": ["graze", "eat"], &"walk": ["walk"], &"trot": ["trot", "run", "walk"], &"gallop": ["gallop", "run", "flee", "trot"]}
## Yürüme klibinden tırısa geçilen hız (m/sn; arada küçük bir kayma payı var: geçiş yalnız hızlanırken ve yavaşlarken görünür).
const WALK_TOP := 1.7
const WALK_HYSTERESIS := 0.15
## Bir yürüyüş klibinin doğal hızına göre oynatılabildiği katlar: dışına çıkınca ayak kayar ya da adım telaşlanır.
const CLIP_RATE := Vector2(0.8, 1.23)
## Otlamanın geçiş hızı (1/sn) ve dörtnalın gövdeye kattığı inip çıkış (m), öne arkaya sallanış (radyan).
const GRAZE_RATE := 1.6
const GALLOP_BOB := 0.04
const GALLOP_ROCK := 0.05
## Gölgelendiricinin gövde adımı (herd_field.gdshader: amp · sin(2π·evre·2) · 0,022): binici de aynı inip çıkar.
const SHADER_BOB := 0.022
const SHADER_SWAY := 0.012
## Binilmezken bekleme ve otlama sürelerinin aralığı (sn).
const IDLE_WAIT := Vector2(3.0, 7.0)
const IDLE_GRAZE := Vector2(5.0, 11.0)
## Örnek verisinin yeri ve boş genişlik: gövde kesilmesin.
const CULL_MARGIN := 1.0

## Model dosyası (yoksa sürünün çizimi; sınamalar başka bir sahne verir).
@export var model_path := MODEL_PATH
## Görünüşün tohumu (0..1; herd_field.gdshader): yün tonu, yüz boyası (0,27 sıcak yün, koyu yüz; 0,2 sarımsı yüz), 0,16'dan küçüğü boynuzlu koç.
@export_range(0.0, 1.0) var seed_value := 0.27

## Sürü ağı (kopyalar paylaşır).
static var _herd_mesh: ArrayMesh

var _instance: MultiMeshInstance3D
var _clips := {}
var _clip_playing: StringName = &""
var _phase := 0.0
var _amp := 0.0
var _speed := 0.0
var _gallop_k := 0.0
var _graze := 0.0
var _want_graze := false
var _idle_timer := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group(GROUP)
	mount = Mount.new(mount_id)
	_rng.seed = StableSeed.of(self, 4177)
	_idle_timer = _rng.randf_range(IDLE_WAIT.x, IDLE_WAIT.y)
	_build()
	_animate(0.0, 0.0)
	_find_map_ground.call_deferred()


func _process(delta: float) -> void:
	if ridden:
		return
	_idle_timer -= delta
	if _idle_timer <= 0.0:
		_want_graze = not _want_graze
		var span := IDLE_GRAZE if _want_graze else IDLE_WAIT
		_idle_timer = _rng.randf_range(span.x, span.y)
	_animate(0.0, delta)


## Binildi / inildi.
func set_ridden(on: bool) -> void:
	super(on)
	_want_graze = false
	_speed = 0.0
	_idle_timer = _rng.randf_range(IDLE_WAIT.x, IDLE_WAIT.y)


## Binilirken bir adım: hız m/sn; otlama durumu Mount'tan.
func drive(speed: float, delta: float) -> void:
	_want_graze = mount != null and mount.is_grazing()
	_animate(speed, delta)


## Oturma noktasının (sırtın yünü) dünya dönüşümü (ön yüz yerel +Z): gövdeyle birlikte iner kalkar. Binici kalçasını bunun yukarısına koyar.
## İskeletli modelde gövde kemiğini izler (Rideable); çizimde gölgelendiricinin adımıyla iner kalkar.
func seat_transform() -> Transform3D:
	if _skeleton and _seat_bone >= 0:
		return super()
	var at := _seat.global_transform if _seat and _seat.is_inside_tree() else global_transform
	var step := _amp * (1.0 - _gallop_k)
	at.origin += at.basis.y * step * sin(TAU * _phase * 2.0) * SHADER_BOB + at.basis.x * step * sin(TAU * _phase) * SHADER_SWAY
	return at


## Otlarken baş ne kadar indi (0..1)?
func graze_amount() -> float:
	return _graze


## Şu an oynayan modelin klibi (çizimde boş).
func model_clip() -> StringName:
	return _clip_playing


## Yürüyüş evresi (0..1) ve salınım genliği (sınama okur).
func gait_phase() -> float:
	return _phase


func gait_amplitude() -> float:
	return _amp


## Çizimin örnek verisi: Color(evre, genlik, otlama, tohum); modelde beyaz.
func instance_data() -> Color:
	var mm := _instance.multimesh if _instance else null
	return mm.get_instance_custom_data(0) if mm else Color.WHITE


# --- Canlandırma ------------------------------------------------------------------------------------

func _animate(speed: float, delta: float) -> void:
	_speed = speed
	if mount and delta > 0.0:
		var stride := mount.stride_at(speed)
		_phase = fposmod(_phase + speed * delta / maxf(stride, 0.1), 1.0)
		_amp = move_toward(_amp, HerdField.swing_amplitude(speed, stride), delta * 3.0)
		var trot := maxf(mount.trot_speed(), 0.1)
		_gallop_k = move_toward(_gallop_k, clampf(inverse_lerp(trot, mount.gallop_speed(), speed), 0.0, 1.0), delta * 3.0)
		_graze = move_toward(_graze, 1.0 if _want_graze else 0.0, delta * GRAZE_RATE)
	if _anim:
		_animate_model()
		# Toynaklar (zemin verildiyse; RideableHooves): gövde basan toynaklarla iner kalkar.
		_update_body(delta)
	elif _instance:
		_body.position.y = absf(sin(TAU * _phase)) * GALLOP_BOB * _gallop_k
		_body.rotation.x = sin(TAU * _phase) * GALLOP_ROCK * _gallop_k
		_instance.multimesh.set_instance_custom_data(0, Color(_phase, _amp, _graze, seed_value))


func _animate_model() -> void:
	var role := &"idle"
	if _want_graze:
		role = &"graze"
	elif _speed > 0.05 and mount:
		role = &"gallop" if _gallop_k > 0.5 else &"trot"
		if _clips.has(&"walk") and _clips[&"walk"] != _clips.get(&"trot"):
			var top := WALK_TOP + (WALK_HYSTERESIS if _clip_playing == _clips[&"walk"] else -WALK_HYSTERESIS)
			if _speed < top:
				role = &"walk"
	var clip: StringName = _clips.get(role, _clips.get(&"idle", &""))
	if clip.is_empty():
		return
	if clip != _clip_playing:
		_anim.play(clip, 0.25)
		_clip_playing = clip
	# Bir tur klibi bir adım boyu yol: ayak yerde kaymaz.
	var moving := role == &"walk" or role == &"trot" or role == &"gallop"
	_anim.speed_scale = clampf(_speed / maxf(clip_stride(clip, _speed), 0.1) * _anim.get_animation(clip).length, 0.3, 2.5) if moving else 1.0


## Klibin adım boyu (m): modelin ölçüsünden (<model>.json clips.<ad>.stride_m), yoksa Mount'un o hızdaki adımı.
func clip_stride(clip: StringName, speed: float) -> float:
	var row: Variant = (meta.get("clips", {}) as Dictionary).get(String(clip).get_slice("/", String(clip).get_slice_count("/") - 1))
	if row is Dictionary and float((row as Dictionary).get("stride_m", 0.0)) > 0.0:
		return float(row["stride_m"])
	return mount.stride_at(speed) if mount else 1.0


## Klibin o hızdaki oynatma katı (1 = doğal hızı; saf yardımcı, sınama okur).
func clip_rate(clip: StringName, speed: float) -> float:
	if _anim == null or not _anim.has_animation(clip):
		return 0.0
	return speed / maxf(clip_stride(clip, speed), 0.1) * _anim.get_animation(clip).length


# --- Kurulum ----------------------------------------------------------------------------------------

func _build() -> void:
	_make_body()
	if not model_path.is_empty() and ResourceLoader.exists(model_path):
		meta = Rideable.read_meta(model_path)
		_build_model()
	if _model == null:
		meta = {}
		_build_instance(RideableSheep.herd_mesh())
	_make_seat(mount.seat())


## Klipli modeli kurar; klipsizse kurmaz (sürünün çizimi kalır).
func _build_model() -> void:
	if _load_model(model_path, "SheepModel") == null:
		return
	_clips = RideableSheep.map_clips(_anim.get_animation_list())
	for clip: StringName in _clips.values():
		_anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR


## Tek örnekli MultiMesh: sürünün gölgelendiricisi örnek verisini INSTANCE_CUSTOM'dan okur.
func _build_instance(mesh: ArrayMesh) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = mesh
	mm.instance_count = 1
	mm.set_instance_transform(0, Transform3D.IDENTITY)
	var mat := ShaderMaterial.new()
	mat.shader = HerdField.SHADER
	_instance = MultiMeshInstance3D.new()
	_instance.name = "Sheep"
	_instance.multimesh = mm
	_instance.material_override = mat
	_instance.extra_cull_margin = CULL_MARGIN
	_body.add_child(_instance)


## Sürünün ağı (paylaşılır).
static func herd_mesh() -> ArrayMesh:
	if _herd_mesh == null:
		_herd_mesh = FaunaMesh.mesh_for("sheep")
	return _herd_mesh


## Klip adlarını rollere eşler (saf): CLIP_NAMES'in parçalarıyla, büyük küçük harf ayrımsız.
static func map_clips(names: PackedStringArray) -> Dictionary:
	return Rideable.clips_by_role(names, CLIP_NAMES)
