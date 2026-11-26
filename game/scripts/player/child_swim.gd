class_name ChildSwim
extends Node
## Çocukta yüzme (E21, K110; story.md §5 «Çobanlık»; docs/design/d3/e21-childhood-api.md §8): PlayerController'ın çocuğunun parçası
## (ChildArcher gibi). Suyun yüzünü dünya verir (water_source: func(x, z) -> {level, depth, inside, inset, deep}; OrdosWorld.water_at).
## Bantlar (suyun derinliği ayağın yerinde; çocuğun boyu ≈1,1 m):
##   DRY      kuru
##   SHALLOW  dizden aşağı (< KNEE): yavaş yürüme (SHALLOW_K), adımda sıçrantı ve küçük halka (sfx_wade)
##   WADE     belden aşağı (< WAIST): daha yavaş (WADE_K), koşu yok
##   SWIM     belden derin: yüzme (SWIM_SPEED, yavaş), baş suyun üstünde (gövde yüzer: avatar suyun yüzüne göre kalkar), kol vuruşu kodla
##            (SwimPose; yer tutucu: Swim_Idle 568 ve Swim_Forward 569 onayla gelir), yüzerken halkalar ve şıpırtı (amb_child_swim)
## En derin bölgeye (deep) girilmez: akıntı yumuşakça kıyıya doğru iter (external_drift), ilk girişte pushed_back yayılır.
## Derinde E 1,5 sn'lik dalıştır (dive): gövde batar, su yüzü saydamlaşır (dip görünür; ChildhoodLake.reveal), dalışın ortasında erimdeki
## ak taş alınır (lake.take_stone), dived(bulundu mu) yayılır; çıkışta sfx_dive_up ve halka. Yüzerken koşu, binme, yay ve zıplama yoktur
## (PlayerController sorar: blocks_run, blocks_mount, blocks_bow, blocks_jump). Sudan çıkınca WET_S saniye ıslak görünüş (koyu ton: avatarın
## albedo_tint'i, yavaşça kurur).

signal band_changed(band: int)
signal pushed_back
signal dive_started
signal dived(found: bool)

enum Band { DRY, SHALLOW, WADE, SWIM }

const KNEE := 0.3
const WAIST := 0.58
const SHALLOW_K := 0.72
const WADE_K := 0.5
const SWIM_SPEED := 0.95
## Yüzerken kalçanın suyun altında kaldığı derinlik (m): baş ve omuz üstte.
const FLOAT_DEPTH := 0.42
const DIVE_S := 1.5
const DIVE_SINK := 0.85
const DIVE_COOLDOWN := 0.6
## Akıntının itişi (m/sn) ve ıslaklığın süresi (sn), koyuluğu.
const CURRENT := 1.15
const WET_S := 25.0
const WET_TINT := 0.62
## Sıçrantı ve halka aralığı (sn; hızla sıklaşır).
const SPLASH_EVERY := 0.55

var controller: PlayerController
var water_source: Callable
## Dünya (gölün kıyısını kurulunca alır: world.childhood().lake).
var world: Node3D
## Gölün kıyısı (halkalar, saydamlık, ak taş; yoksa null).
var lake: ChildhoodLake
## Ses (atmos; yoksa sessiz): sfx(kimlik, yer), yatak bayrağı.
var atmos: ChildhoodAtmos
var band := Band.DRY
var depth := 0.0
var level := NAN
var in_deep := false
var diving := false
## Islaklık (0..1; sudan çıkınca 1'den söner).
var wet := 0.0
## Dalışta alınan ak taş (bir kez).
var found_stone := false

var _pose: SwimPose
var _lift := 0.0
var _dive_t := 0.0
var _dive_cool := 0.0
var _dive_checked := false
var _splash_t := 0.0
var _swim_ring_t := 0.0
var _tints: Dictionary = {}
var _pushed := false


func setup(p_controller: PlayerController, p_water: Callable) -> void:
	controller = p_controller
	water_source = p_water


func _process(delta: float) -> void:
	if controller == null or not controller.is_inside_tree():
		return
	var avatar := controller.get_avatar()
	if not water_source.is_valid() or controller.get_stance() != PlayerController.Stance.FOOT or controller.carried:
		_set_band(Band.DRY if controller.get_stance() != PlayerController.Stance.FOOT else band)
		_apply_lift(avatar, 0.0, delta)
		return
	var at := controller.global_position
	if lake == null and world and world.has_method(&"childhood"):
		var site: Variant = world.call(&"childhood")
		if site is ChildhoodSite and is_instance_valid((site as ChildhoodSite).lake):
			lake = (site as ChildhoodSite).lake
			lake.set_player(controller)
	var w: Dictionary = water_source.call(at.x, at.z)
	level = float(w.get("level", NAN))
	depth = float(w.get("depth", 0.0)) if not is_nan(level) else 0.0
	_set_band(band_of(depth))
	_tick_deep(bool(w.get("deep", false)), at)
	_tick_dive(delta, at)
	var lift := 0.0
	if band == Band.SWIM:
		lift = maxf(depth - FLOAT_DEPTH - _hips(avatar), 0.0)
		if diving:
			lift -= DIVE_SINK * sin(clampf(_dive_t / DIVE_S, 0.0, 1.0) * PI)
	_apply_lift(avatar, lift, delta)
	_tick_pose(delta)
	_tick_splash(delta, at)
	_tick_wet(delta)


# --- Yüz (PlayerController sorar) -------------------------------------------------------------------------

## Derinliğin bandı (saf).
static func band_of(water_depth: float) -> Band:
	if water_depth <= 0.03:
		return Band.DRY
	if water_depth < KNEE:
		return Band.SHALLOW
	if water_depth < WAIST:
		return Band.WADE
	return Band.SWIM


## Yürüyüşün hız çarpanı (sığ ve belde yavaş; yüzerken yüzmenin hızı yürüyüşe oranla).
func speed_k() -> float:
	match band:
		Band.SHALLOW:
			return SHALLOW_K
		Band.WADE:
			return WADE_K
		Band.SWIM:
			return SWIM_SPEED / maxf(controller.walk_speed, 0.1) if controller else 0.6
	return 1.0


func in_water() -> bool:
	return band != Band.DRY


func is_swimming() -> bool:
	return band == Band.SWIM


func blocks_run() -> bool:
	return band >= Band.WADE


func blocks_mount() -> bool:
	return band >= Band.WADE


func blocks_bow() -> bool:
	return band >= Band.WADE


func blocks_jump() -> bool:
	return band != Band.DRY


## E dalış mı (yüzerken, dalış sürmüyorken)?
func can_dive() -> bool:
	return band == Band.SWIM and not diving and _dive_cool <= 0.0


## Dalış başlar (1,5 sn): gövde batar, dip görünür, ortasında erimdeki ak taş alınır.
func dive() -> bool:
	if not can_dive():
		return false
	diving = true
	_dive_t = 0.0
	_dive_checked = false
	if lake:
		lake.reveal(true)
		lake.ring(controller.global_position, 1.3, 1.0)
	dive_started.emit()
	return true


## Ak taş dalış anında alınabilir mi (sınama ve ipucu)?
func stone_in_reach() -> bool:
	return lake != null and lake.stone_in_reach(controller.global_position)


# --- İç ----------------------------------------------------------------------------------------------------

func _set_band(b: Band) -> void:
	if b == band:
		return
	var was := band
	band = b
	if atmos:
		atmos.set_flag("swimming", b == Band.SWIM)
	if b == Band.DRY and was != Band.DRY:
		wet = 1.0
	if b != Band.DRY and was == Band.DRY and atmos:
		atmos.sfx("sfx_wade", controller.global_position, -4.0)
	if b != Band.SWIM:
		diving = false
	band_changed.emit(int(b))


func _tick_deep(deep: bool, at: Vector3) -> void:
	in_deep = deep and band == Band.SWIM
	if not in_deep:
		if controller.external_drift != Vector3.ZERO and _pushed:
			controller.external_drift = Vector3.ZERO
		_pushed = false
		return
	# Akıntı: gölün orta çizgisinden dışarı doğru (kıyıya), yumuşak.
	var shape := controller.terrain_shape as OrdosGround
	var out := Vector2.ZERO
	if shape:
		var e := 0.4
		out = Vector2(shape.lake_distance(at.x + e, at.z) - shape.lake_distance(at.x - e, at.z),
			shape.lake_distance(at.x, at.z + e) - shape.lake_distance(at.x, at.z - e)).normalized()
	controller.external_drift = Vector3(out.x, 0.0, out.y) * CURRENT
	if not _pushed:
		_pushed = true
		pushed_back.emit()


func _tick_dive(delta: float, at: Vector3) -> void:
	_dive_cool = maxf(_dive_cool - delta, 0.0)
	if not diving:
		return
	_dive_t += delta
	if not _dive_checked and _dive_t >= DIVE_S * 0.5:
		_dive_checked = true
		if lake and not found_stone and lake.stone_in_reach(at):
			found_stone = lake.take_stone()
	if _dive_t >= DIVE_S:
		diving = false
		_dive_cool = DIVE_COOLDOWN
		if lake:
			lake.reveal(false)
			lake.ring(at, 1.6, 1.0)
		if atmos:
			atmos.sfx("sfx_dive_up", at, -2.0)
		dived.emit(found_stone and _dive_checked)


func _tick_pose(delta: float) -> void:
	var avatar := controller.get_avatar()
	var want := 1.0 if band == Band.SWIM else 0.0
	if _pose == null and want > 0.0:
		_pose = SwimPose.attach(avatar)
	if _pose:
		_pose.amount = move_toward(_pose.amount, want, delta * 2.5)
		_pose.speed = clampf(controller.get_speed() / SWIM_SPEED, 0.0, 1.0)
		_pose.dive = clampf(sin(clampf(_dive_t / DIVE_S, 0.0, 1.0) * PI) * 1.4, 0.0, 1.0) if diving else move_toward(_pose.dive, 0.0, delta * 3.0)


func _apply_lift(avatar: CharacterAvatar, lift: float, delta: float) -> void:
	if avatar == null:
		return
	var prev := _lift
	_lift = lerpf(_lift, lift, 1.0 - exp(-6.0 * delta)) if delta > 0.0 else lift
	if absf(_lift) < 0.002 and absf(lift) < 0.002:
		_lift = 0.0
	# Yerde (FOOT) avatarın düğümü denetleyicinin ayağındadır (y 0; klibin zemin payı modelin içindedir): kaldırma doğrudan yazılır.
	if _lift != 0.0 or prev != 0.0:
		avatar.position.y = _lift


func _tick_splash(delta: float, at: Vector3) -> void:
	if band == Band.DRY or lake == null:
		return
	var sp := controller.get_speed()
	if band == Band.SWIM:
		_swim_ring_t -= delta
		if _swim_ring_t <= 0.0:
			_swim_ring_t = 0.9 if sp > 0.2 else 1.8
			lake.ring(Vector3(at.x, level, at.z), 1.0 if sp > 0.2 else 0.7, 0.8)
		return
	if sp < 0.2:
		return
	_splash_t -= delta * (sp / maxf(controller.walk_speed, 0.1))
	if _splash_t <= 0.0:
		_splash_t = SPLASH_EVERY
		lake.ring(Vector3(at.x, level, at.z), 0.6 if band == Band.SHALLOW else 0.85, 0.7)
		if atmos:
			atmos.sfx("sfx_wade", at, -10.0 if band == Band.SHALLOW else -6.0, 0.08)


## Islak görünüş: avatarın malzemelerinin albedo_tint'i koyulaşır, WET_S'de kurur.
func _tick_wet(delta: float) -> void:
	var target := 1.0 if band >= Band.WADE else wet
	if band == Band.DRY:
		wet = maxf(wet - delta / WET_S, 0.0)
		target = wet
	else:
		wet = 1.0 if band >= Band.WADE else maxf(wet, 0.5)
	var avatar := controller.get_avatar()
	if avatar == null:
		return
	for mat in avatar.get_materials():
		if not _tints.has(mat):
			_tints[mat] = mat.get_shader_parameter(&"albedo_tint")
		var base: Variant = _tints[mat]
		var c: Color = base if base is Color else Color.WHITE
		var k := lerpf(1.0, WET_TINT, smoothstep(0.0, 1.0, target))
		mat.set_shader_parameter(&"albedo_tint", Color(c.r * k, c.g * k, c.b * k, c.a))


## Islaklığı bırakır (sahne bitince: renkler geri).
func dry_now() -> void:
	wet = 0.0
	band = Band.DRY
	var avatar := controller.get_avatar() if controller else null
	if avatar:
		for mat in avatar.get_materials():
			if _tints.has(mat):
				mat.set_shader_parameter(&"albedo_tint", _tints[mat])
		avatar.position.y = 0.0
	_lift = 0.0
	if _pose:
		_pose.amount = 0.0
	if controller and _pushed:
		controller.external_drift = Vector3.ZERO
	_pushed = false


func _hips(avatar: CharacterAvatar) -> float:
	return 0.5 * (avatar.model_scale if avatar else 1.0)
