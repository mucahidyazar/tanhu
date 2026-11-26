class_name RideableHorse
extends Rideable
## Binilen at (kampın iki atı; fauna.md §2.1, §10; Mount satırı «horse»). Model iskeletlidir (tools/blender/quadruped_rig.py, tarif quadruped_horse.json;
## assets/animals/<id>/<id>.glb): klipler idle, graze, walk, trot, gallop; ölçüleri <id>.json (sırt noktası, kliplerin adım boyu ve faz tablosu). Yerel +Z başın
## baktığı yöndür, düğümün yeri toynakların zeminidir.
##
## Binilmezken bekler, ara ara başını indirip otlar (yemliğin samanı). Binilince sürücü drive(hız, delta) çağırır: hız WALK_TOP'un altında adım,
## GALLOP_FROM'un üstünde dörtnal, arada tırıs (geçişte küçük kayma payı); klip kendi adım boyuna göre hızlanır (ayak yerde kaymaz), en çok CLIP_RATE katı.
## Toynak vuruşları klibin faz tablosundan çıkar (bacağın basış evresi; <id>.json clips.<klip>.phases): her vuruşta RideEffects toz kaldırır, iz bırakır ve
## toynak sesini çalar (dörtnalda tam, tırısta az, adımda yalnız ses). Yele ve kuyruğun dalgası kliptedir; dörtnalda kuyruk kalkar, yele dalgalanır.
##
## Sıçrama (2026-11-08; binici Boşluk'a basınca PlayerController.jump → leap): Mount.jump_plan hıza göre planlar (durarak kısa ve alçak, tırısta ve dörtnalda
## ileri doğru uzun). Evreler: hazırlık (PREP; durarak at toplanır, arka bacaklar iter; koşarak klip ön bacaklar kalkmışken başlar), havada (AIR; gövde
## kodla yay çizer: Body düğümü kalkar, düğüm yerde kalır, binici oturma noktasıyla kalkar), iniş (LAND; önce ön toynaklar, sonra arka). Bacakların
## hareketi modelin jump klibidir (tools/blender/quadruped_rig.py pose_jump; evreleri <id>.json clips.jump.times): klip her evrede o evrenin süresine göre
## hızlanır ya da yavaşlar. Kalkışta arka toynaklar, inişte her toynak toz kaldırır, iz bırakır, ses çıkarır (RideEffects: leap, land). Koşarak inince
## yürüyüş klibine karışır, durarak sıçrayınca toparlanır (hareket varsa arka inişten hemen sonra yürür). Modelsizde aynı saat ve yay işler (klipsiz).
##   var horse := RideableHorse.new(); horse.model_path = "res://assets/animals/horse_brown/horse_brown.glb"; add_child(horse)
##   horse.leap(speed)    # sürücü her adımda drive(hız, delta) çağırır; leap_phase(), leap_lift(), leap_ground_speed()

## Rol → modelin klip adında aranan parçalar.
const CLIP_NAMES := {&"idle": ["idle"], &"graze": ["graze", "eat"], &"walk": ["walk"], &"trot": ["trot"], &"gallop": ["gallop"], &"jump": ["jump"]}
const ROLE_JUMP := &"jump"
## Sıçrama klibinin evreleri (sn) ve boyu, basan toynağın klipteki geri kayma hızı (m/sn): modelin <id>.json clips.jump'ı yoksa bunlar
## (tools/blender/quadruped_horse.json'daki tarifin sayıları).
const LEAP_TIMES := {"lift": 0.18, "run_start": 0.24, "takeoff": 0.38, "touchdown": 0.88, "hind_down": 1.02}
const LEAP_LENGTH := 1.4
const LEAP_GROUND := 2.0
## Bacakların klipteki kalkış ve iniş anı (sn): öncü sağ ön önce iner, sol ön lead sonra; arka çift arka inişin çevresinde.
const LEAP_LEGS := {"FrontR": [0.18, 0.88], "FrontL": [0.15, 0.91], "HindL": [0.38, 1.005], "HindR": [0.389, 1.035]}
## Sıçrama klibine giriş (durarak, koşarak) ve klipten yürüyüşe çıkış geçişi (sn).
const LEAP_BLEND_IN := 0.2
const LEAP_RUN_BLEND_IN := 0.1
const LEAP_BLEND_OUT := 0.25
## Durarak sıçrayınca arka inişten bu kadar sonra (klip sn) hareket varsa (hız LEAP_MOVE_SPEED'in üstü) yürüyüşe karışılır; yoksa toparlanma biter.
const LEAP_MOVE_EXIT := 0.08
const LEAP_MOVE_SPEED := 0.4
## Klipler arası geçişin hızları (m/sn) ve kayma payı: adım → tırıs, tırıs → dörtnal.
const WALK_TOP := 2.6
const GALLOP_FROM := 6.2
const GAIT_HYSTERESIS := 0.3
## Bir yürüyüş klibinin doğal hızına göre oynatılabildiği katlar.
const CLIP_RATE := Vector2(0.5, 1.6)
## Klipler arası çapraz geçiş (sn) ve bekleme ile otlama arasında.
const GAIT_BLEND := 0.3
const IDLE_BLEND := 0.6
## Binilmezken bekleme ve otlama sürelerinin aralığı (sn).
const IDLE_WAIT := Vector2(7.0, 14.0)
const IDLE_GRAZE := Vector2(6.0, 12.0)
## Bu hızın altında toynak izi ve sesi yoktur (m/sn).
const STRIKE_MIN_SPEED := 0.3
## Toynak kemikleri (bacak adı → kemik).
const HOOVES := {"FrontL": "FrontHoofL", "FrontR": "FrontHoofR", "HindL": "HindHoofL", "HindR": "HindHoofR"}

## Model dosyası (boşsa model kurulmaz; at görünmez ama binilebilir kalır: sınamalar).
@export var model_path := ""
## Toynak izi, toz ve ses (kapalıyken hiçbiri kurulmaz: menünün dondurulmuş karesi, sınamalar).
@export var effects_enabled := true

var _clips := {}
var _role: StringName = &""
var _speed := 0.0
var _want_graze := false
var _idle_timer := 0.0
var _rng := RandomNumberGenerator.new()
## Oynayan yürüyüş klibinin evresi (0..1; önceki karede) ve bacakların basış evreleri.
var _last_phase := -1.0
var _hooves := {}
var _effects: RideEffects
## Sayılan toynak vuruşları (sınama okur).
var strikes := 0
## Sıçrama: evre, plan (Mount.jump_plan ve klibin evreleri), evrenin saati (sn), klibin mantıksal saati (sn) ve şimdiki hızı, gövdenin kalkışı (m),
## iniş vuruşu yapılan bacaklar.
var _leap_phase: LeapPhase = LeapPhase.NONE
var _leap: Dictionary = {}
var _leap_t := 0.0
var _leap_clip := 0.0
var _leap_rate := 1.0
var _leap_lift := 0.0
var _leap_hit := {}
## Sıçrayışların sayısı (sınama okur).
var leaps := 0


func _init() -> void:
	mount_id = "horse"


func _ready() -> void:
	add_to_group(GROUP)
	mount = Mount.new(mount_id)
	_rng.seed = StableSeed.of(self, 6211)
	_idle_timer = _rng.randf_range(IDLE_WAIT.x * 0.3, IDLE_WAIT.y)
	_make_body()
	if not model_path.is_empty() and ResourceLoader.exists(model_path):
		meta = Rideable.read_meta(model_path)
		if _load_model(model_path, "HorseModel", 0.35):
			_clips = Rideable.clips_by_role(_anim.get_animation_list(), CLIP_NAMES)
			for role: StringName in _clips:
				# Sıçrama bir kez oynar, ötekiler döngülüdür.
				_anim.get_animation(_clips[role]).loop_mode = Animation.LOOP_NONE if role == ROLE_JUMP else Animation.LOOP_LINEAR
			for leg: String in HOOVES:
				var bone := _skeleton.find_bone(HOOVES[leg]) if _skeleton else -1
				if bone >= 0:
					_hooves[leg] = bone
	if _model == null:
		meta = {}
	_make_seat(mount.seat())
	if effects_enabled and not Engine.is_editor_hint():
		_effects = RideEffects.new()
		_effects.name = "RideEffects"
		add_child(_effects)
	_play_role(&"idle", 0.0)
	if _anim and _clips.has(&"idle"):
		# İki at aynı anda nefes almasın: klip kişiye bağlı bir yerinden başlar.
		_anim.seek(_anim.get_animation(_clips[&"idle"]).length * _rng.randf(), true)
	# İç haritanın atı zeminini kendisi bulur (toynak IK'sı); kampın ve menünün atı klibin pozunda kalır.
	_find_map_ground.call_deferred()


func _process(delta: float) -> void:
	if ridden:
		return
	_update_body(delta)
	if _leap_phase != LeapPhase.NONE:
		# Binicisiz sıçrayış (sürücüsü yok): yerinde biter.
		_advance_leap(0.0, delta)
		return
	_idle_timer -= delta
	if _idle_timer <= 0.0:
		_want_graze = not _want_graze and _clips.has(&"graze")
		var span := IDLE_GRAZE if _want_graze else IDLE_WAIT
		_idle_timer = _rng.randf_range(span.x, span.y)
	_animate(0.0, delta)


## Binildi / inildi: otlamadan kalkar; süren sıçrama biter.
func set_ridden(on: bool) -> void:
	super(on)
	cancel_leap()
	_want_graze = false
	_speed = 0.0
	_idle_timer = _rng.randf_range(IDLE_WAIT.x, IDLE_WAIT.y)


## Binilirken bir adım: hız m/sn. Sıçrarken sıçramanın saati ilerler (klip, yay, iniş vuruşları). Gövdenin toynaklarla inişi de bu adımdadır
## (binici aynı karede oturma noktasıyla iner).
func drive(speed: float, delta: float) -> void:
	_want_graze = false
	if _leap_phase != LeapPhase.NONE:
		_advance_leap(speed, delta)
		_update_body(delta)
		return
	_animate(speed, delta)
	_update_body(delta)


# --- Sıçrama -----------------------------------------------------------------------------------------

func can_leap() -> bool:
	return mount != null and mount.can_jump()


## Sıçrar (bkz. başlık): speed sıçrayıştaki hız (m/sn) planı seçer. Zaten sıçrıyorsa ya da satırın sıçraması yoksa false.
func leap(speed: float) -> bool:
	if not can_leap() or _leap_phase != LeapPhase.NONE:
		return false
	_leap = mount.jump_plan(speed)
	var row: Dictionary = (meta.get("clips", {}) as Dictionary).get("jump", {}) if _clips.has(ROLE_JUMP) else {}
	var times: Dictionary = LEAP_TIMES.duplicate()
	times.merge(row.get("times", {}), true)
	_leap["times"] = times
	_leap["length"] = float(row.get("length_s", LEAP_LENGTH))
	_leap["ground"] = float(row.get("ground_mps", LEAP_GROUND))
	_leap["legs"] = row.get("legs", LEAP_LEGS)
	var running: bool = _leap["running"]
	var start := float(times["run_start"]) if running else 0.0
	_leap_phase = LeapPhase.PREP
	_leap_t = 0.0
	_leap_clip = start
	_leap_rate = (float(times["takeoff"]) - start) / maxf(float(_leap["prep_s"]), 0.01)
	_leap_lift = 0.0
	_leap_hit.clear()
	_speed = speed
	leaps += 1
	_role = ROLE_JUMP
	_last_phase = -1.0
	if _anim and _clips.has(ROLE_JUMP):
		_anim.play(_clips[ROLE_JUMP], LEAP_RUN_BLEND_IN if running else LEAP_BLEND_IN)
		_anim.seek(start, true)
		_anim.speed_scale = _leap_rate
	return true


func is_leaping() -> bool:
	return _leap_phase != LeapPhase.NONE


func is_airborne() -> bool:
	return _leap_phase == LeapPhase.AIR


func leap_phase() -> LeapPhase:
	return _leap_phase


func leap_lift() -> float:
	return _leap_lift


## Sürmekte olan sıçramanın planı (Mount.jump_plan; times, length, ground; sıçramıyorken boş).
func leap_plan() -> Dictionary:
	return _leap if _leap_phase != LeapPhase.NONE else {}


## Basan toynakların klipte geri kayma hızı (m/sn): toplanmada ve toparlanmada 0 (toynak yerinde), itişte ve ön inişte ground × klibin hızı, havada -1.
## Durarak sıçrayan atı süren bununla gider: ayak yerde kaymaz.
func leap_ground_speed() -> float:
	if _leap_phase == LeapPhase.NONE or _leap_phase == LeapPhase.AIR:
		return -1.0
	var times: Dictionary = _leap["times"]
	if _leap_phase == LeapPhase.PREP:
		return float(_leap["ground"]) * _leap_rate if _leap_clip >= float(times["lift"]) else 0.0
	return float(_leap["ground"]) * _leap_rate if _leap_clip < float(times["hind_down"]) else 0.0


func cancel_leap() -> void:
	if _leap_phase == LeapPhase.NONE:
		return
	_leap_phase = LeapPhase.NONE
	_set_lift(0.0)
	_role = &""
	_animate(_speed, 0.0)


func _advance_leap(speed: float, delta: float) -> void:
	_speed = speed
	if delta <= 0.0:
		return
	var times: Dictionary = _leap["times"]
	_leap_t += delta
	_leap_clip += delta * _leap_rate
	match _leap_phase:
		LeapPhase.PREP:
			if _leap_clip >= float(times["takeoff"]):
				_take_off()
		LeapPhase.AIR:
			var air := float(_leap["air_s"])
			var k := clampf(_leap_t / air, 0.0, 1.0)
			# Yerçekimli yay: kalkışta yukarı hızla, tepede durur, inişte aynı hızla.
			_set_lift(4.0 * float(_leap["height"]) * k * (1.0 - k))
			if k >= 1.0:
				_touch_down()
		LeapPhase.LAND:
			var legs: Dictionary = _leap["legs"]
			var last_down := 0.0
			for leg: String in legs:
				var down := float((legs[leg] as Array)[1])
				last_down = maxf(last_down, down)
				if not _leap_hit.has(leg) and _leap_clip >= down:
					_leap_hit[leg] = true
					_leap_strike(leg, &"land")
			var after := _leap_clip - float(times["hind_down"])
			var done := _leap_clip >= float(_leap["length"])
			if bool(_leap["running"]):
				# Koşarak: son toynak da basınca yürüyüşe karışılır.
				done = done or _leap_clip >= last_down
			elif after >= LEAP_MOVE_EXIT and speed > LEAP_MOVE_SPEED:
				done = true
			if done:
				_end_leap(speed)


## Arka toynaklar yerden kalkar: havanın saati başlar, klip havanın süresine göre oynar, kalkış tozu.
func _take_off() -> void:
	var times: Dictionary = _leap["times"]
	_leap_phase = LeapPhase.AIR
	_leap_t = 0.0
	_leap_clip = float(times["takeoff"])
	_leap_rate = (float(times["touchdown"]) - _leap_clip) / float(_leap["air_s"])
	_sync_leap_clip()
	_leap_strike("HindL", &"leap")
	_leap_strike("HindR", &"leap")


## Ön toynak yere değer: gövde yerde, klip inişin hızıyla.
func _touch_down() -> void:
	_leap_phase = LeapPhase.LAND
	_leap_t = 0.0
	_set_lift(0.0)
	_leap_clip = float((_leap["times"] as Dictionary)["touchdown"])
	_leap_rate = float(_leap["land_rate"])
	_sync_leap_clip()


## Sıçrama biter: yürüyüşe (ya da beklemeye) geçişle karışılır.
func _end_leap(speed: float) -> void:
	_leap_phase = LeapPhase.NONE
	_set_lift(0.0)
	_role = &""
	_speed = speed
	var edges := gait_edges()
	var role := RideableHorse.role_for(speed, &"", edges.x, edges.y)
	_play_role(role, LEAP_BLEND_OUT)
	_animate(speed, 0.0)


## Klibi mantıksal saate oturtur ve hızını evreninkine çeker.
func _sync_leap_clip() -> void:
	if _anim and _clips.has(ROLE_JUMP) and _anim.assigned_animation == _clips[ROLE_JUMP]:
		_anim.seek(_leap_clip, true)
		_anim.speed_scale = _leap_rate


func _set_lift(lift: float) -> void:
	_leap_lift = lift
	_update_body(0.0)


## Sıçramanın toynak vuruşu (kalkış: leap, iniş: land): hızdan bağımsız toz, iz ve ses.
func _leap_strike(leg: String, kind: StringName) -> void:
	strikes += 1
	if _effects == null:
		return
	var at := global_position
	if _skeleton and _hooves.has(leg):
		at = _skeleton.global_transform * _skeleton.get_bone_global_pose(int(_hooves[leg])).origin
	var heading := global_basis.z
	_effects.hoof_strike(Vector3(at.x, global_position.y, at.z), Vector3(heading.x, 0.0, heading.z).normalized(), maxf(_speed, 2.0), kind, leg.begins_with("Front"))


## Oynayan rol (idle, graze, walk, trot, gallop; modelsizde hızdan).
func gait_role() -> StringName:
	return _role


## Toz, iz ve sesin düğümü (kurulmadıysa null).
func effects() -> RideEffects:
	return _effects


## Hızın yürüyüş rolü (saf): adım, tırıs, dörtnal; current oynayan rol (kayma payı için). Eşikler satırın walk_top ve gallop_from'u (yoksa WALK_TOP,
## GALLOP_FROM; I. Perde'nin bineklerinde tırıs daha hızlıdır).
static func role_for(speed: float, current: StringName, p_walk_top := WALK_TOP, p_gallop_from := GALLOP_FROM) -> StringName:
	if speed < 0.05:
		return &"idle"
	var walk_top := p_walk_top + (GAIT_HYSTERESIS if current == &"walk" else -GAIT_HYSTERESIS)
	if speed < walk_top:
		return &"walk"
	var gallop_from := p_gallop_from - (GAIT_HYSTERESIS if current == &"gallop" else -GAIT_HYSTERESIS)
	return &"gallop" if speed >= gallop_from else &"trot"


## Satırın klip eşikleri: [walk_top, gallop_from] (yoksa sabitler).
func gait_edges() -> Vector2:
	if mount == null:
		return Vector2(WALK_TOP, GALLOP_FROM)
	var walk_top := mount.value("walk_top")
	var gallop_from := mount.value("gallop_from")
	return Vector2(walk_top if walk_top > 0.0 else WALK_TOP, gallop_from if gallop_from > 0.0 else GALLOP_FROM)


## Klibin adım boyu (m): modelin ölçüsünden (<id>.json clips.<ad>.stride_m), yoksa Mount'un o hızdaki adımı.
func clip_stride(clip: StringName, speed: float) -> float:
	var row: Variant = (meta.get("clips", {}) as Dictionary).get(String(clip))
	if row is Dictionary and float((row as Dictionary).get("stride_m", 0.0)) > 0.0:
		return float(row["stride_m"])
	return mount.stride_at(speed) if mount else 1.0


## Klibin o hızdaki oynatma katı (1 = doğal hızı; sınırsız; sınama okur).
func clip_rate(clip: StringName, speed: float) -> float:
	if _anim == null or not _anim.has_animation(clip):
		return 0.0
	return speed / maxf(clip_stride(clip, speed), 0.1) * _anim.get_animation(clip).length


# --- Canlandırma ------------------------------------------------------------------------------------

func _animate(speed: float, delta: float) -> void:
	_speed = speed
	var edges := gait_edges()
	var role := role_for(speed, _role, edges.x, edges.y)
	if role == &"idle" and _want_graze:
		role = &"graze"
	if role != _role:
		var calm := (role == &"idle" or role == &"graze") and (_role == &"idle" or _role == &"graze")
		_play_role(role, IDLE_BLEND if calm else GAIT_BLEND)
	if _anim == null:
		return
	var moving := role == &"walk" or role == &"trot" or role == &"gallop"
	var clip: StringName = _clips.get(role, &"")
	_anim.speed_scale = clampf(clip_rate(clip, speed), CLIP_RATE.x, CLIP_RATE.y) if moving and not clip.is_empty() else 1.0
	if moving and delta > 0.0:
		_track_strikes(clip, role)
	else:
		_last_phase = -1.0


func _play_role(role: StringName, blend: float) -> void:
	_role = role
	_last_phase = -1.0
	if _anim == null:
		return
	var clip: StringName = _clips.get(role, _clips.get(&"idle", &""))
	if clip.is_empty():
		return
	_anim.play(clip, blend)


## Toynak vuruşları: oynayan klibin evresi bacağın basış evresini geçtiyse o toynak yere değdi.
func _track_strikes(clip: StringName, role: StringName) -> void:
	var anim := _anim.get_animation(clip)
	if anim == null or anim.length <= 0.0:
		return
	var phase := fposmod(_anim.current_animation_position / anim.length, 1.0)
	if _last_phase < 0.0:
		_last_phase = phase
		return
	var row: Dictionary = (meta.get("clips", {}) as Dictionary).get(String(clip), {})
	var phases: Dictionary = row.get("phases", {})
	for leg: String in phases:
		if RideableHorse.crossed(_last_phase, phase, float(phases[leg])):
			_strike(leg, role)
	_last_phase = phase


## Evre (0..1, döngülü) önceki ile şimdiki arasında at'i geçti mi (saf)?
static func crossed(previous: float, current: float, at: float) -> bool:
	if current >= previous:
		return at > previous and at <= current
	# Döngü başa sardı.
	return at > previous or at <= current


func _strike(leg: String, role: StringName) -> void:
	if _speed < STRIKE_MIN_SPEED:
		return
	strikes += 1
	if _effects == null:
		return
	var at := global_position
	if _skeleton and _hooves.has(leg):
		at = _skeleton.global_transform * _skeleton.get_bone_global_pose(int(_hooves[leg])).origin
	at.y = global_position.y
	var heading := global_basis.z
	_effects.hoof_strike(Vector3(at.x, global_position.y, at.z), Vector3(heading.x, 0.0, heading.z).normalized(), _speed, role, leg.begins_with("Front"))
