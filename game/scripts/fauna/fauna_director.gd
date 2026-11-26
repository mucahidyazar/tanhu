class_name FaunaDirector
extends RefCounted
## Hayvanların yönetmeni (fauna.md §10, survival.md §4.3–§4.9; K65; Yol Haritası animals): saf, 4 Hz. İç haritanın bütün hayvan işi
## buradadır: yaban ve kamp hayvanlarının ajanları (sürü, algı, kaçış), açık otlağın sürüleri (PastureFlock: ayrılma, hizalanma,
## toplanma, kurttan kaçış) ve sınırlar (ajan ≤24, T0 ≤8, kuş ≤64; K65). Düğüm kurmaz, ağaca dokunmaz: görünüm FaunaLayer'dadır
## (Animal T0, AgentCrowd T1, HerdField sürü), oturumun 8. adımı (Session «fauna») step(dt)'yi çağırır; aradaki kareleri görünüm
## ara değerler. tests/unit/test_fauna_director.gd kareler çizmeden sınar.
##
## Ajan durumları (survival.md §4.9: graze, alert, flee, attack, dead): GRAZE otlar ya da koklar, WALK grubun yerine yürür, ALERT durur ve
## tehdide bakar, FLEE kaçar (v = sürek + (tepe − sürek) × max(0, 1 − t / T); fauna.md §4.1), RETURN grubun yerine döner, REST yatar (köpek
## gece, kurt ve otçul dinlenir), ATTACK saldırır (vurulan yaban domuzu), DOWN vuruldu, yerde.
## Davranış türün temper'idir (data/fauna/kinds.json): graze, stop_look (ceylan: kaçar, durur, bakar), cliff (yaban keçisi: kaçış yamacına,
## leash'ten öteye gitmez), cover (maral: örtüye), charge (yaban domuzu: vurulunca saldırır), predator (kurt: gece; ateşten ve kamptan
## çekinir), sly (tilki: fark etmez gibi yapar), camp_dog (köpek: kampta dolaşır, gece yatar, kurda havlar).
## Algı (survival.md §4.4): görüş ve duyma; alacada görüş ×0,8, duyma ×1,2; gece görüş ×0,6 (tilki ve kurt ×1), duyma ×1,3; R_eff = min(R,
## 0,6 × görüş); rüzgârla koku (rüzgâraltından ×0,5, üstünden ×2: türün smell'i 2 iken tam çarpan); çömelme ×0,6; Pay Bırak ×0,9, Kurt Postu ×0,8.
## Gruplar evrenin etkinliğiyle doğar (survival.md §4.3: ağırlık / 3 olasılık; gün ve evre başına tohumlu zar), oyuncu yakınsa sahnededir
## (ACTIVE_RANGE); bütçe dolarsa en yakın gruplar kalır. Ana kampa ve Kışlak'ın yerleşimine yırtıcı ve yaban hayvanı girmez (K3, K65).
## Olaylar events'e yazılır (her tikte silinir):
##   {"type": &"voice", "kind": tür, "role": &"call" | &"alarm" | &"warn" | &"grunt" | &"fear" | &"calm", "at": Vector2, "agent": sıra}
##   {"type": &"flee", "agent", "kind"}   {"type": &"down", "agent", "kind"}   {"type": &"attack", "agent", "kind", "damage", "at"}
##   {"type": &"spawn" | &"despawn", "group": kimlik}
##
##   var director := FaunaDirector.new()
##   director.setup(MapLayers.read("res://data/maps/kislak/fauna.json"))
##   director.set_player(Vector2(p.x, p.z), Vector2(v.x, v.z), 1.0)
##   director.set_time(clock.phase(), clock.minute, clock.day_n)
##   director.step(delta)                        # 4 Hz'de tick()
##   for i in director.active_agents(): ...      # pos, prev, facing, speed, state, head

enum State { GRAZE, WALK, ALERT, FLEE, RETURN, REST, ATTACK, DOWN }

## Benzetim adımı (sn): 4 Hz.
const TICK := 0.25
## Bütçe (K65, fauna.md §10; iç harita): hayvan ajanı, iskeletli T0, kuş.
const MAX_AGENTS := 24
const MAX_T0 := 8
const MAX_BIRDS := 64
## Grup oyuncuya grubun yarıçapı + ACTIVE_RANGE içindeyse sahnededir; RELEASE_MARGIN ötesinde bırakılır (histerezis).
const ACTIVE_RANGE := 230.0
const RELEASE_MARGIN := 40.0
## Sürü bu uzaklıkta her tik, ötesinde dört tikte bir adım atar.
const FLOCK_NEAR := 420.0
## Durup bakma süresi (sn).
const ALERT_S := Vector2(1.2, 2.8)
## Fark eden hayvan tehdit bu payın içine girince kaçar; kaçan bu katına açılınca durur.
const FLEE_RATIO := 0.65
const CALM_RATIO := 1.6
## Tilki fark etmez gibi yapar: bu payın içine dek yürümeyi sürdürür (survival.md §4.1).
const SLY_RATIO := 0.4
## Otlama ve yürüme (sn ve m).
const IDLE_RANGE := Vector2(3.0, 10.0)
const WANDER_SHARE := 0.45
## Saldırı: en uzun süre (sn) ve değme uzaklığı (m).
const ATTACK_S := 4.0
const ATTACK_REACH := 1.4
## Kurt: oyuncudan bu uzaklıkta çekilir; sürüye en çok bu kadar sokulur (m).
const WOLF_SHY := 22.0
const WOLF_STANDOFF := 28.0
## Köpek: kurt kampın bu kadar yakınındaysa havlar; gece yatma saati (22:30).
const DOG_WARN := 160.0
const DOG_SLEEP_FROM := 1350.0
## Kampın varsayılan yarıçapı (m): yaban hayvanı ve yırtıcı girmez.
const CAMP_RADIUS := 150.0
## Ateşten çekinme (m; fauna.md §6: orta evrede 8, büyükte 12).
const FIRE_FEAR := 12.0
## Haritanın sınırı (act1.md §4).
const BOUNDS := Rect2(-450.0, -760.0, 1400.0, 1050.0)
## Oyuncunun gürültüsü: durur, yürür, koşar, binekte.
const NOISE_STILL := 0.4
const NOISE_WALK := 1.0
const NOISE_RUN := 1.5
const NOISE_RIDE := 1.8
const CROUCH_K := 0.6
## Grup içi ayrılma (m).
const SPACING := 1.6

## Bir hayvan grubu (fauna.json «groups»): yeri, sürü boyu, evreleri; sahnedeyken ajanları slots'tadır.
class Group:
	extends RefCounted
	var id := ""
	var kind: FaunaKind
	var home := Vector2.ZERO
	var radius := 40.0
	var count := Vector2i(1, 1)
	## Grubun o anki yeri ve gezindiği hedef.
	var spot := Vector2.ZERO
	var goal := Vector2.ZERO
	var goal_left := 0.0
	## Kaçış yamacı ve uzaklık sınırı (cliff), örtü (cover), kampın ocakları (camp_dog), gece sokulma noktaları (predator).
	var leash := Vector2.INF
	var leash_radius := 350.0
	var cover := Vector2.INF
	var spots := PackedVector2Array()
	var prowl := PackedVector2Array()
	var present := true
	## Evreden bağımsız hep var (geliştirme dizisi, hikâye sahnesi); free: kampın ve ateşin yasağı işlemez (yalnız geliştirme dizisi).
	var always := false
	var free := false
	var active := false
	var leaving := false
	var slots := PackedInt32Array()
	var seed := 1
	var rng := RandomNumberGenerator.new()
	## Bugün vurulan (sonraki şafakta geri gelir; survival.md §4.7).
	var taken := 0

## Ajanlar (yapı dizileri; MAX_AGENTS yuva).
var used := PackedByteArray()
var kinds: Array[FaunaKind] = []
var group_of := PackedInt32Array()
var pos := PackedVector2Array()
var prev := PackedVector2Array()
var vel := PackedVector2Array()
var facing := PackedVector2Array()
var goal := PackedVector2Array()
var speed := PackedFloat32Array()
var state := PackedByteArray()
var timer := PackedFloat32Array()
var flee_t := PackedFloat32Array()
var flee_from := PackedVector2Array()
var hp := PackedFloat32Array()
## Başın yeri: 0 yukarı, 1 yerde (otlama), 0,5 dinlenme.
var head := PackedFloat32Array()

var groups: Array[Group] = []
var flocks: Array[PastureFlock] = []
var flock_ids := PackedStringArray()

## Dünyanın girdileri.
var player := Vector2.INF
var player_vel := Vector2.ZERO
var player_noise := NOISE_WALK
var crouching := false
var phase: StringName = &"noon"
var minute := 720.0
var day := 0
var vis := INF
var wind := 0.0
## Rüzgârın akış yönü (birim; x doğu, z güney: WeatherFx.dir_x, dir_z).
var wind_dir := Vector2(0.871, 0.49)
var camp := Vector2.ZERO
var camp_radius := CAMP_RADIUS
## Ateşler Vector3(x, z, yarıçap) ve engeller Vector3(x, z, yarıçap).
var fires: Array[Vector3] = []
var obstacles: Array[Vector3] = []
var bounds := BOUNDS
## Algı çarpanları: Pay Bırak ×0,9, Kurt Postu ×0,8 (survival.md §4.4, §4.7).
var share_k := 1.0
var pelt_k := 1.0
## Ajan bütçesi (MAX_AGENTS eksi küçük av memelileri: FaunaLayer yazar) ve sayılan kuşlar.
var agent_cap := MAX_AGENTS
var birds := 0

var clock := 0.0
var events: Array[Dictionary] = []
var _accum := 0.0
var _presence_key := ""
var _flock_tick := 0


func _init() -> void:
	used.resize(MAX_AGENTS)
	kinds.resize(MAX_AGENTS)
	group_of.resize(MAX_AGENTS)
	group_of.fill(-1)
	pos.resize(MAX_AGENTS)
	prev.resize(MAX_AGENTS)
	vel.resize(MAX_AGENTS)
	facing.resize(MAX_AGENTS)
	goal.resize(MAX_AGENTS)
	speed.resize(MAX_AGENTS)
	state.resize(MAX_AGENTS)
	timer.resize(MAX_AGENTS)
	flee_t.resize(MAX_AGENTS)
	flee_from.resize(MAX_AGENTS)
	hp.resize(MAX_AGENTS)
	head.resize(MAX_AGENTS)


# --- Kurulum -------------------------------------------------------------------------------------------

## Katmanın sözlüğü (data/maps/<harita>/fauna.json): camp, fires, groups, flocks. Bilinmeyen tür bir uyarıyla atlanır.
func setup(def: Dictionary) -> void:
	var c: Variant = def.get("camp", {})
	if c is Dictionary:
		camp = _vec2((c as Dictionary).get("center", [0.0, 0.0]))
		camp_radius = float((c as Dictionary).get("radius", CAMP_RADIUS))
	for f: Variant in def.get("fires", []):
		if f is Array and (f as Array).size() >= 2:
			fires.append(Vector3(float(f[0]), float(f[1]), float(f[2]) if (f as Array).size() > 2 else FIRE_FEAR))
	var b: Variant = def.get("bounds")
	if b is Array and (b as Array).size() == 4:
		bounds = Rect2(float(b[0]), float(b[1]), float(b[2]) - float(b[0]), float(b[3]) - float(b[1]))
	var table := FaunaKind.table()
	for g: Variant in def.get("groups", []):
		if g is Dictionary:
			add_group(g, table)
	for f: Variant in def.get("flocks", []):
		if f is Dictionary:
			add_flock(f, table)


## Grup ekler (saf). Döner: grup (tür katalogda yoksa null).
func add_group(def: Dictionary, table: Dictionary = {}) -> Group:
	var rows := table if not table.is_empty() else FaunaKind.table()
	var kind_id := str(def.get("kind", ""))
	if not rows.has(kind_id):
		push_warning("[fauna] grubun türü katalogda yok: %s" % kind_id)
		return null
	var g := Group.new()
	g.id = str(def.get("id", "%s_%d" % [kind_id, groups.size()]))
	g.kind = FaunaKind.from_def(kind_id, rows[kind_id])
	g.home = _vec2(def.get("home", def.get("center", [0.0, 0.0])))
	g.radius = float(def.get("radius", 40.0))
	var range_k := g.kind.group_range()
	var n: Variant = def.get("count", [range_k.x, range_k.y])
	if n is Array and (n as Array).size() >= 2:
		g.count = Vector2i(int(n[0]), int(n[1]))
	else:
		g.count = Vector2i(int(n), int(n))
	# Sahnede türün en çoğu (kurt 4) aşılmaz.
	var cap := int(g.kind.def.get("scene", g.count.y))
	g.count = Vector2i(clampi(g.count.x, 1, cap), clampi(g.count.y, 1, cap))
	g.spot = g.home
	g.goal = g.home
	if def.get("leash") is Array:
		g.leash = _vec2(def["leash"])
		g.leash_radius = float(def.get("leash_radius", g.kind.def.get("leash", 350.0)))
	if def.get("cover") is Array:
		g.cover = _vec2(def["cover"])
	for s: Variant in def.get("spots", []):
		g.spots.append(_vec2(s))
	for s: Variant in def.get("prowl", []):
		g.prowl.append(_vec2(s))
	g.always = bool(def.get("always", false))
	g.free = bool(def.get("free", false))
	g.seed = int(def.get("seed", 100 + groups.size() * 37))
	g.rng.seed = g.seed
	groups.append(g)
	return g


## Açık otlağın sürüsünü ekler (saf). Döner: sürü (tür katalogda yoksa null).
func add_flock(def: Dictionary, table: Dictionary = {}) -> PastureFlock:
	var rows := table if not table.is_empty() else FaunaKind.table()
	var kind_id := str(def.get("kind", ""))
	if not rows.has(kind_id):
		push_warning("[fauna] sürünün türü katalogda yok: %s" % kind_id)
		return null
	var kind := FaunaKind.from_def(kind_id, rows[kind_id])
	var scaled := def.duplicate()
	var flock := PastureFlock.new(scaled, kind)
	# Hun Atı boy ×0,94 (K65): gövde elipsi türün ölçeğiyle küçülür.
	flock.half_length *= kind.model_scale()
	flock.half_width *= kind.model_scale()
	flocks.append(flock)
	flock_ids.append(str(def.get("id", "%s_flock_%d" % [kind_id, flocks.size()])))
	return flock


func flock(id: String) -> PastureFlock:
	var i := flock_ids.find(id)
	return flocks[i] if i >= 0 else null


func group(id: String) -> Group:
	for g in groups:
		if g.id == id:
			return g
	return null


# --- Girdiler ----------------------------------------------------------------------------------------------

## Oyuncu (düzlemde): yer, hız, gürültü (NOISE_*), çömelme. Yer INF ise tehdit yok.
func set_player(p: Vector2, v: Vector2 = Vector2.ZERO, noise: float = NOISE_WALK, crouch: bool = false) -> void:
	player = p
	player_vel = v
	player_noise = noise
	crouching = crouch


## Saat: evre (GameClock.phase; boşsa dakikadan), gün dakikası, mutlak gün.
func set_time(p_phase: StringName, p_minute: float, p_day: int = 0) -> void:
	phase = p_phase if p_phase != &"" else phase_of(p_minute)
	minute = p_minute
	day = p_day


## Hava: görüş (m), rüzgâr (m/sn) ve akış yönü (WeatherFx.dir_x, dir_z).
func set_weather(p_vis: float, p_wind: float, p_dir: Vector2 = Vector2(0.871, 0.49)) -> void:
	vis = p_vis
	wind = p_wind
	if p_dir.length_squared() > 0.0001:
		wind_dir = p_dir.normalized()


# --- Adım ---------------------------------------------------------------------------------------------------

## Kare: 4 Hz'de tick (kare başına en çok 4). Döner: atılan tik sayısı.
func step(dt: float) -> int:
	_accum += maxf(dt, 0.0)
	var n := 0
	while _accum >= TICK and n < 4:
		_accum -= TICK
		tick()
		n += 1
	if _accum >= TICK:
		_accum = 0.0
	return n


## Ara değerin payı (0..1): son tikten bu yana geçen sürenin TICK'e oranı.
func alpha() -> float:
	return clampf(_accum / TICK, 0.0, 1.0)


func tick() -> void:
	clock += TICK
	events.clear()
	_update_presence()
	_update_activation()
	for i in MAX_AGENTS:
		if used[i] == 1:
			prev[i] = pos[i]
	for g in groups:
		if g.active:
			_step_group(g)
	for i in MAX_AGENTS:
		if used[i] == 1:
			_step_agent(i)
	_separate()
	_step_flocks()


# --- Gruplar: doğma, sahneye girme, bırakma --------------------------------------------------------------------

## Evre ya da gün değişince her grubun bulunuşu yeniden atılır (tohumlu: aynı gün ve evrede aynı sonuç).
func _update_presence() -> void:
	var key := "%d/%s" % [day, phase]
	if key == _presence_key:
		return
	_presence_key = key
	if phase == &"dawn":
		for g in groups:
			g.taken = 0
	for g in groups:
		var was := g.present
		g.present = g.always or is_present(g.kind, phase, _roll(g))
		if was and not g.present and g.active:
			g.leaving = true
			for i in g.slots:
				if state[i] != State.DOWN and state[i] != State.FLEE:
					_set_return(i, _leave_point(g))


## Grubun bu evrede bulunup bulunmadığı (saf): ağırlık / 3 olasılık (survival.md §4.3), kışın uykudaki tür yok (tarbagan).
static func is_present(kind: FaunaKind, p_phase: StringName, roll: float, season: StringName = &"winter") -> bool:
	if season == &"winter" and bool(kind.def.get("winter_sleep", false)):
		return false
	var w := kind.activity(p_phase)
	return roll < float(w) / 3.0


func _roll(g: Group) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([g.seed, day, String(phase)])
	return rng.randf()


func _update_activation() -> void:
	var has_player := player.is_finite()
	# Bırakma: uzaklaşan, ayrılan ve görünmeyen grup.
	for g in groups:
		if not g.active:
			continue
		var d := _player_distance(g.spot) if has_player else INF
		var gone := not has_player or d > g.radius + ACTIVE_RANGE + RELEASE_MARGIN
		if g.leaving and has_player:
			# Ayrılan grup oyuncudan uzaklaşınca ya da görünmez olunca biter.
			var far := true
			for i in g.slots:
				if pos[i].distance_to(player) < 70.0 and state[i] != State.DOWN:
					far = false
			gone = gone or far
		if gone:
			_deactivate(g)
	if not has_player:
		return
	# Sahneye girme: en yakın gruplar önce, bütçe yettiğince.
	var waiting: Array[Group] = []
	for g in groups:
		if not g.active and g.present and _player_distance(g.spot) <= g.radius + ACTIVE_RANGE:
			waiting.append(g)
	waiting.sort_custom(func(a: Group, b: Group) -> bool: return _player_distance(a.spot) < _player_distance(b.spot))
	for g in waiting:
		var n := g.count.x if g.count.x == g.count.y else g.rng.randi_range(g.count.x, g.count.y)
		n = maxi(n - g.taken, 0)
		if n == 0 or free_slots() < n:
			continue
		_activate(g, n)


func _activate(g: Group, n: int) -> void:
	g.active = true
	g.leaving = false
	g.slots = PackedInt32Array()
	var points := HerdSim.scatter_points(g.spot, minf(g.radius * 0.35, 4.0 + float(n) * 1.6), n, g.rng, SPACING * 1.5)
	for k in n:
		var i := _free_slot()
		if i < 0:
			break
		used[i] = 1
		kinds[i] = g.kind
		group_of[i] = groups.find(g)
		pos[i] = points[k] if g.free else _keep_out(points[k], g.kind)
		prev[i] = pos[i]
		vel[i] = Vector2.ZERO
		facing[i] = Vector2.from_angle(g.rng.randf() * TAU)
		goal[i] = pos[i]
		speed[i] = 0.0
		hp[i] = float(g.kind.hp)
		flee_t[i] = 0.0
		flee_from[i] = pos[i]
		_rest_or_graze(i, g)
		timer[i] = g.rng.randf_range(0.0, IDLE_RANGE.y)
		g.slots.append(i)
	events.append({"type": &"spawn", "group": g.id})


func _deactivate(g: Group) -> void:
	for i in g.slots:
		if state[i] == State.DOWN:
			g.taken += 1
		used[i] = 0
		kinds[i] = null
		group_of[i] = -1
	g.slots = PackedInt32Array()
	g.active = false
	g.leaving = false
	events.append({"type": &"despawn", "group": g.id})


func free_slots() -> int:
	var n := 0
	for i in MAX_AGENTS:
		if used[i] == 1:
			n += 1
	return maxi(agent_cap - n, 0)


func _free_slot() -> int:
	if free_slots() <= 0:
		return -1
	for i in MAX_AGENTS:
		if used[i] == 0:
			return i
	return -1


## Sahnedeki ajanların yuvaları.
func active_agents() -> PackedInt32Array:
	var out := PackedInt32Array()
	for i in MAX_AGENTS:
		if used[i] == 1:
			out.append(i)
	return out


func agent_count() -> int:
	return MAX_AGENTS - (used.count(0))


func agent_kind(i: int) -> String:
	return kinds[i].id if used[i] == 1 and kinds[i] else ""


func agent_group(i: int) -> Group:
	return groups[group_of[i]] if used[i] == 1 and group_of[i] >= 0 else null


## Ajanın ara değerli yeri (düzlem).
func agent_position(i: int, a: float = -1.0) -> Vector2:
	var k := alpha() if a < 0.0 else a
	return prev[i].lerp(pos[i], k)


# --- Grup davranışı -----------------------------------------------------------------------------------------------

## Grubun yeri ağır ağır gezinir (otlak, orman); yırtıcı gece sokulma noktalarına gider; köpek ocaklar arasında dolaşır.
func _step_group(g: Group) -> void:
	g.goal_left -= TICK
	var temper := g.kind.temper()
	if g.goal_left <= 0.0 or g.spot.distance_to(g.goal) < 2.0:
		g.goal_left = g.rng.randf_range(30.0, 80.0)
		if temper == "predator" and not g.prowl.is_empty() and _is_night_phase():
			g.goal = g.prowl[g.rng.randi() % g.prowl.size()]
		elif temper == "camp_dog" and not g.spots.is_empty():
			g.goal = g.spots[g.rng.randi() % g.spots.size()]
		else:
			g.goal = g.home + Vector2.from_angle(g.rng.randf() * TAU) * sqrt(g.rng.randf()) * g.radius * 0.7
		if not g.free:
			g.goal = _keep_out(g.goal, g.kind)
	var drift := 0.0 if g.free else (0.35 if temper == "predator" else (0.6 if temper == "camp_dog" else 0.15))
	g.spot = g.spot.move_toward(g.goal, drift * TICK)
	if temper == "cliff" and g.leash.is_finite():
		g.spot = g.leash + (g.spot - g.leash).limit_length(g.leash_radius)


func _step_agent(i: int) -> void:
	var g := agent_group(i)
	if g == null:
		return
	var kind := kinds[i]
	var temper := kind.temper()
	var p := pos[i]
	var desired := Vector2.ZERO
	var head_to := head[i]
	match state[i]:
		State.GRAZE:
			head_to = 0.35 if kind.is_predator() or temper == "camp_dog" else 1.0
			timer[i] -= TICK
			if timer[i] <= 0.0:
				_wander(i, g)
			_sense(i, g)
		State.WALK, State.RETURN:
			head_to = 0.0
			var to_goal := goal[i] - p
			var d := to_goal.length()
			var pace := kind.speed("walk", 1.0) * (1.5 if state[i] == State.RETURN else 1.0)
			if d < 0.6:
				_rest_or_graze(i, g)
			else:
				desired = to_goal / d * pace
			_sense(i, g)
		State.ALERT when temper == "camp_dog":
			head_to = 0.0
			timer[i] -= TICK
			if timer[i] <= 0.0:
				_rest_or_graze(i, g)
				_dog_watch(i, g)
		State.ALERT:
			head_to = 0.0
			timer[i] -= TICK
			if player.is_finite() and player.distance_squared_to(p) > 0.01:
				facing[i] = facing[i].slerp((player - p).normalized(), 0.6).normalized()
			var threat := _threat_distance(i)
			var notice := _notice(i, g)
			if threat < notice * FLEE_RATIO or (_approaching(i) and threat < notice * 0.85):
				_flee(i, player, true)
			elif timer[i] <= 0.0:
				if threat > notice:
					_rest_or_graze(i, g)
				else:
					timer[i] = g.rng.randf_range(ALERT_S.x, ALERT_S.y)
		State.FLEE:
			head_to = 0.0
			desired = _flee_velocity(i, g)
		State.REST:
			head_to = 0.5
			timer[i] -= TICK
			if timer[i] <= 0.0:
				_rest_or_graze(i, g)
			_sense(i, g)
		State.ATTACK:
			head_to = 0.0
			flee_t[i] += TICK
			if not player.is_finite() or flee_t[i] > ATTACK_S:
				_flee(i, player if player.is_finite() else p, false)
			else:
				var to_p := player - p
				var dist := to_p.length()
				if dist <= ATTACK_REACH:
					events.append({"type": &"attack", "agent": i, "kind": kind.id, "damage": int(kind.def.get("damage", 8)), "at": p})
					_flee(i, player, false)
				else:
					desired = to_p / dist * kind.peak_speed()
		State.DOWN:
			head_to = 0.0
	head[i] = move_toward(head[i], head_to, TICK * 2.0)
	if desired.length_squared() > 0.0025:
		facing[i] = facing[i].slerp(desired.normalized(), 0.55).normalized()
	vel[i] = desired
	speed[i] = desired.length()
	if state[i] != State.DOWN:
		pos[i] = _resolve(i, p + desired * TICK)


## Otlayan ajan grubun yerine yakın küçük bir yer değiştirir.
func _wander(i: int, g: Group) -> void:
	var kind := kinds[i]
	var temper := kind.temper()
	var around := g.spot
	var reach := g.radius * WANDER_SHARE
	if temper == "camp_dog":
		reach = 18.0
	elif kind.is_predator():
		reach = 14.0
	var target := around + Vector2.from_angle(g.rng.randf() * TAU) * sqrt(g.rng.randf()) * reach
	if g.free:
		# Geliştirme dizisi: yerinde durur, yan döner (silüet karesi).
		state[i] = State.GRAZE
		timer[i] = 30.0
		facing[i] = Vector2.RIGHT
		return
	goal[i] = _keep_out(target, kind)
	state[i] = State.WALK
	timer[i] = 0.0


## Gece kampın köpeği yatar, dinlenme saatinde otçul yatar; öteki otlar.
func _rest_or_graze(i: int, g: Group) -> void:
	var temper := kinds[i].temper()
	if temper == "camp_dog" and (minute >= DOG_SLEEP_FROM or minute < 330.0):
		state[i] = State.REST
		timer[i] = g.rng.randf_range(40.0, 120.0)
		return
	state[i] = State.GRAZE
	timer[i] = g.rng.randf_range(IDLE_RANGE.x, IDLE_RANGE.y)


func _set_return(i: int, target: Vector2) -> void:
	var g := agent_group(i)
	goal[i] = target if g and g.free else _keep_out(target, kinds[i])
	state[i] = State.RETURN


func _leave_point(g: Group) -> Vector2:
	if g.cover.is_finite():
		return g.cover
	if g.leash.is_finite():
		return g.leash
	return g.home


# --- Algı ve kaçış ---------------------------------------------------------------------------------------------

## Algı (survival.md §4.4): tehdit fark edilirse ALERT ya da hemen FLEE; köpek kurda havlar; kurt oyuncudan çekilir.
func _sense(i: int, g: Group) -> void:
	if g.free:
		return
	var kind := kinds[i]
	var temper := kind.temper()
	if temper == "camp_dog":
		_dog_watch(i, g)
		return
	if not player.is_finite() or temper == "domestic":
		return
	var d := _threat_distance(i)
	var notice := _notice(i, g)
	if d >= notice:
		return
	if temper == "predator":
		if d < WOLF_SHY or d < notice * FLEE_RATIO:
			_flee(i, player, true)
		return
	if temper == "sly" and d > notice * SLY_RATIO:
		# Tilki fark etmez gibi yapar: yürümeyi sürdürür.
		return
	if d < notice * FLEE_RATIO or temper == "sly":
		_flee(i, player, true)
	elif state[i] != State.ALERT:
		state[i] = State.ALERT
		timer[i] = g.rng.randf_range(ALERT_S.x, ALERT_S.y)
		if temper == "stop_look":
			events.append({"type": &"voice", "kind": kind.id, "role": &"alarm", "at": pos[i], "agent": i})


## Kampın köpeği: kurt yakına gelince kalkar, kurda bakıp havlar (fauna.md §5.1; ses FaunaVoices'ta seyrekleşir). Oyuncudan kaçmaz.
func _dog_watch(i: int, g: Group) -> void:
	var w := nearest_wolf(pos[i])
	if w.x < 0 or w.y >= DOG_WARN:
		return
	facing[i] = (pos[int(w.x)] - pos[i]).normalized()
	if state[i] != State.ALERT:
		state[i] = State.ALERT
		timer[i] = g.rng.randf_range(2.0, 4.0)
		events.append({"type": &"voice", "kind": kinds[i].id, "role": &"warn", "at": pos[i], "agent": i})


## Kaçış başlar: yön tehditten uzağa; grubun alarm yarıçapındakiler de kaçar (hizalanma).
func _flee(i: int, from: Vector2, spread: bool) -> void:
	if state[i] == State.DOWN:
		return
	var was := state[i]
	state[i] = State.FLEE
	flee_t[i] = 0.0
	flee_from[i] = from
	if was != State.FLEE:
		events.append({"type": &"flee", "agent": i, "kind": kinds[i].id})
		events.append({"type": &"voice", "kind": kinds[i].id, "role": &"alarm", "at": pos[i], "agent": i})
	if not spread:
		return
	var g := agent_group(i)
	if g == null:
		return
	var alarm := kinds[i].sense("alarm", 30.0)
	for j in g.slots:
		if j != i and state[j] != State.FLEE and state[j] != State.DOWN and pos[j].distance_to(pos[i]) <= alarm:
			state[j] = State.FLEE
			flee_t[j] = 0.0
			flee_from[j] = from
			events.append({"type": &"flee", "agent": j, "kind": kinds[j].id})


func _flee_velocity(i: int, g: Group) -> Vector2:
	var kind := kinds[i]
	var temper := kind.temper()
	flee_t[i] += TICK
	var p := pos[i]
	var from := flee_from[i]
	var away := (p - from).normalized() if p.distance_squared_to(from) > 0.01 else facing[i]
	var dir := away
	match temper:
		"cliff":
			# Kaçış yamacına: yamacın yönüyle kaçış yönü karışır; leash'in dışına çıkılmaz.
			if g.leash.is_finite():
				var to_l := g.leash - p
				if to_l.length() > 4.0:
					dir = (away * 0.45 + to_l.normalized() * 0.75).normalized()
		"cover":
			if g.cover.is_finite():
				var to_c := g.cover - p
				if to_c.length() > 4.0:
					dir = (away * 0.6 + to_c.normalized() * 0.6).normalized()
	# Grubun ortalama kaçış yönü (birlikte kaçarlar).
	var mean := Vector2.ZERO
	for j in g.slots:
		if j != i and state[j] == State.FLEE:
			mean += vel[j]
	if mean.length_squared() > 0.01:
		dir = (dir * 0.7 + mean.normalized() * 0.3).normalized()
	var spd := flight_speed(kind.peak_speed(), kind.sustained_speed(), kind.flight_time(), flee_t[i])
	# Durulma: tehditten yeterince açıldı.
	var d := p.distance_to(player) if player.is_finite() else INF
	var notice := _notice(i, g)
	if d > notice * CALM_RATIO and flee_t[i] > 2.0:
		g.spot = g.spot.lerp(p, 0.5)
		if temper == "stop_look":
			state[i] = State.ALERT
			timer[i] = g.rng.randf_range(2.0, 4.0)
		elif temper == "cover" and g.cover.is_finite():
			_set_return(i, g.cover)
		else:
			_rest_or_graze(i, g)
		return Vector2.ZERO
	return dir * spd


## Türün o anki algı yarıçapı (m): bu ajanın yerinden, oyuncuya göre.
func _notice(i: int, _g: Group) -> float:
	return notice_radius(kinds[i], {
		"phase": phase, "vis": vis, "wind": wind, "wind_dir": wind_dir, "from": player, "at": pos[i],
		"noise": player_noise, "crouch": crouching, "k": share_k * pelt_k,
	})


## Algı yarıçapı (saf; survival.md §4.4). ctx: phase, vis (m), wind (m/sn), wind_dir (akış yönü), from (tehdit), at (hayvan), noise
## (NOISE_*), crouch, k (Pay Bırak ve Kurt Postu çarpanı).
static func notice_radius(kind: FaunaKind, ctx: Dictionary) -> float:
	var sight := kind.sense("sight", 20.0)
	var hear := kind.sense("hear", 20.0)
	var smell := kind.sense("smell", 0.0)
	var p: StringName = ctx.get("phase", &"noon")
	if p == &"dawn" or p == &"dusk":
		sight *= 0.8
		hear *= 1.2
	elif p == &"night":
		sight *= kind.sense("night", FaunaKind.NIGHT_SIGHT)
		hear *= 1.3
	var v := float(ctx.get("vis", INF))
	if v < INF:
		sight = minf(sight, 0.6 * v)
	if bool(ctx.get("crouch", false)):
		sight *= CROUCH_K
	hear *= float(ctx.get("noise", NOISE_WALK)) * (CROUCH_K if bool(ctx.get("crouch", false)) else 1.0)
	var r := maxf(sight, hear)
	var w := float(ctx.get("wind", 0.0))
	var from: Vector2 = ctx.get("from", Vector2.INF)
	var at: Vector2 = ctx.get("at", Vector2.INF)
	if smell > 0.0 and w >= 1.0 and from.is_finite() and at.is_finite() and from.distance_squared_to(at) > 0.01:
		# Rüzgâr tehditten hayvana doğru esiyorsa (tehdit rüzgârüstünde) koku gelir.
		var flow: Vector2 = ctx.get("wind_dir", Vector2(0.871, 0.49))
		var upwind := (at - from).normalized().dot(flow.normalized()) > 0.0
		r *= pow(WeatherFx.scent_dir_k(w, upwind), clampf(smell, 0.0, 2.0) / 2.0)
	return r * float(ctx.get("k", 1.0))


func _threat_distance(i: int) -> float:
	return pos[i].distance_to(player) if player.is_finite() else INF


## Tehdit bu ajana yaklaşıyor mu (oyuncunun hızı ajana dönük)?
func _approaching(i: int) -> bool:
	if not player.is_finite() or player_vel.length_squared() < 0.25:
		return false
	return player_vel.dot(pos[i] - player) > 0.0


# --- Vuruş, ürkme --------------------------------------------------------------------------------------------

## Ok ya da taş değdi (ArrowField'in hedef sözleşmesi Animal'dan buraya gelir). Döner: vuruş sayıldı mı?
func hit(i: int, damage: float, from: Vector2) -> bool:
	if i < 0 or i >= MAX_AGENTS or used[i] == 0 or state[i] == State.DOWN:
		return false
	hp[i] -= maxf(damage, 0.0)
	if hp[i] <= 0.0:
		state[i] = State.DOWN
		vel[i] = Vector2.ZERO
		speed[i] = 0.0
		events.append({"type": &"down", "agent": i, "kind": kinds[i].id})
		_flee_group_from(i, from)
		return true
	if kinds[i].temper() == "charge":
		state[i] = State.ATTACK
		flee_t[i] = 0.0
		events.append({"type": &"voice", "kind": kinds[i].id, "role": &"grunt", "at": pos[i], "agent": i})
	else:
		_flee(i, from, true)
	return true


## Iska yakına düştü: hayvan ürker.
func startle(i: int, from: Vector2) -> void:
	if used[i] == 1 and state[i] != State.DOWN and kinds[i].temper() != "camp_dog":
		_flee(i, from, true)


func _flee_group_from(i: int, from: Vector2) -> void:
	var g := agent_group(i)
	if g == null:
		return
	for j in g.slots:
		if j != i and state[j] != State.DOWN:
			_flee(j, from, false)


# --- Ayrılma, sınırlar -------------------------------------------------------------------------------------------

## Grup içi ayrılma: aynı gruptan iki ajan iç içe geçmez.
func _separate() -> void:
	for g in groups:
		if not g.active:
			continue
		var n := g.slots.size()
		for a in n:
			var i := g.slots[a]
			for b in range(a + 1, n):
				var j := g.slots[b]
				var delta := pos[j] - pos[i]
				var reach := (kinds[i].length + kinds[j].length) * 0.5 * maxf(kinds[i].model_scale(), 0.5)
				var ds := delta.length_squared()
				if ds < reach * reach and ds > 0.000001:
					var dist := sqrt(ds)
					var push := delta / dist * (reach - dist) * 0.5
					if state[i] != State.DOWN:
						pos[i] -= push
					if state[j] != State.DOWN:
						pos[j] += push


## Yeni yer: engeller, kampın ve ateşlerin yasağı, haritanın sınırı, kaçış yamacının uzaklık sınırı.
func _resolve(i: int, to: Vector2) -> Vector2:
	var kind := kinds[i]
	var gg := agent_group(i)
	var p := to if gg and gg.free else _keep_out(to, kind)
	var r := kind.length * 0.3
	for c in obstacles:
		var center := Vector2(c.x, c.y)
		var min_dist := c.z + r
		var off := p - center
		var ds := off.length_squared()
		if ds < min_dist * min_dist:
			var dist := sqrt(ds)
			p = center + (off / dist if dist > 0.0001 else Vector2.RIGHT) * min_dist
	var g := agent_group(i)
	if g and kind.temper() == "cliff" and g.leash.is_finite():
		p = g.leash + (p - g.leash).limit_length(g.leash_radius)
	return p


## Türün giremeyeceği yerden dışarı (saf değil, girdileri okur): yaban hayvanı kampa girmez, yırtıcı ateşe yaklaşmaz; köpek kampta kalır.
func _keep_out(p: Vector2, kind: FaunaKind) -> Vector2:
	var out := Vector2(clampf(p.x, bounds.position.x + 2.0, bounds.end.x - 2.0), clampf(p.y, bounds.position.y + 2.0, bounds.end.y - 2.0))
	var temper := kind.temper() if kind else ""
	if temper == "camp_dog":
		return camp + (out - camp).limit_length(camp_radius * 0.8)
	if kind and kind.kind_class != "domestic":
		var off := out - camp
		if off.length() < camp_radius:
			out = camp + (off.normalized() if off.length_squared() > 0.0001 else Vector2.UP) * camp_radius
	if kind and kind.is_predator():
		for f in fires:
			var fc := Vector2(f.x, f.y)
			var fo := out - fc
			if fo.length() < f.z:
				out = fc + (fo.normalized() if fo.length_squared() > 0.0001 else Vector2.RIGHT) * f.z
	return out


# --- Sürüler ---------------------------------------------------------------------------------------------------

## Açık otlağın sürüleri: kurtlar tehdit, oyuncu yol verilen nokta (dörtnalda tehdit); uzak sürü dört tikte bir.
func _step_flocks() -> void:
	_flock_tick += 1
	var wolves: Array[Vector2] = []
	for i in MAX_AGENTS:
		if used[i] == 1 and kinds[i].temper() == "predator" and state[i] != State.DOWN:
			wolves.append(pos[i])
	for f in flocks:
		var c := f.center
		var near := player.is_finite() and player.distance_to(c) <= FLOCK_NEAR
		if not near and _flock_tick % 4 != 0 and wolves.is_empty():
			continue
		var alarm := 60.0 if f.kind_id == "horse" else 30.0
		var t: Array[Vector3] = []
		for w in wolves:
			if w.distance_to(c) < f.radius + alarm * 2.0:
				t.append(Vector3(w.x, w.y, alarm))
		var a: Array[Vector3] = []
		if player.is_finite() and player.distance_to(c) < f.radius + 60.0:
			a.append(Vector3(player.x, player.y, 1.9))
			if player_vel.length() > 6.0:
				t.append(Vector3(player.x, player.y, 9.0))
		f.threats = t
		f.avoid = a
		f.set_time(minute)
		var was_fleeing := f.is_fleeing()
		f.step()
		for ev: Dictionary in f.events:
			if ev.get("type") == &"fled" and not was_fleeing:
				var role := &"fear" if f.kind_id == "horse" and not wolves.is_empty() else &"call"
				events.append({"type": &"voice", "kind": f.kind_id, "role": role, "at": f.pos[int(ev["index"])], "flock": flock_ids[flocks.find(f)]})
				break


## Noktaya en yakın kurt: Vector2(yuva, uzaklık); yoksa (-1, INF).
func nearest_wolf(p: Vector2) -> Vector2:
	var best := -1
	var best_d := INF
	for i in MAX_AGENTS:
		if used[i] == 1 and kinds[i].temper() == "predator" and state[i] != State.DOWN:
			var d := pos[i].distance_to(p)
			if d < best_d:
				best_d = d
				best = i
	return Vector2(best, best_d)


func _is_night_phase() -> bool:
	return phase == &"night" or phase == &"dusk" or phase == &"dawn"


func _player_distance(p: Vector2) -> float:
	return p.distance_to(player) if player.is_finite() else INF


# --- Saf formüller (fauna.md §3.3, §4.1; «Belirsizlikler»in sınaması) ------------------------------------------

## Kaçış hızı (m/sn): v = sürek + (tepe − sürek) × max(0, 1 − t / T) (fauna.md §4.1).
static func flight_speed(peak: float, sustained: float, t_fall: float, t: float) -> float:
	return sustained + (peak - sustained) * maxf(0.0, 1.0 - t / maxf(t_fall, 0.001))


## Kaçışın t saniyede aldığı yol (m): hızın integrali.
static func flight_distance(peak: float, sustained: float, t_fall: float, t: float) -> float:
	var tt := minf(t, t_fall)
	return sustained * t + (peak - sustained) * (tt - tt * tt / (2.0 * maxf(t_fall, 0.001)))


## Kovalayanın yakalama süresi (sn): sabit hızla gap m geriden kaçışı izleyen; yetişemezse INF (fauna.md §4.1: Hun Atı 11 m/sn,
## ceylan 15 / 10, T 12; d m açıkla ≈30 + d sn).
static func catch_time(chaser: float, peak: float, sustained: float, t_fall: float, gap: float) -> float:
	# T'den önce: chaser × t = gap + flight_distance(t) (ikinci derece); T'den sonra doğrusal.
	var a := (peak - sustained) / (2.0 * maxf(t_fall, 0.001))
	var b := chaser - peak
	var disc := b * b - 4.0 * a * (-gap)
	if a > 0.0 and disc >= 0.0:
		var t1 := (-b + sqrt(disc)) / (2.0 * a)
		var t0 := (-b - sqrt(disc)) / (2.0 * a)
		var roots: Array[float] = [minf(t0, t1), maxf(t0, t1)]
		for t in roots:
			if t > 1e-6 and t <= t_fall and chaser * t >= gap + flight_distance(peak, sustained, t_fall, t) - 1e-6:
				return t
	if chaser <= sustained:
		return INF
	var head := gap + flight_distance(peak, sustained, t_fall, t_fall) - chaser * t_fall
	return t_fall + maxf(head, 0.0) / (chaser - sustained)


## Kurt kaybı (fauna.md §3.3; K65): kapsanmayan sürü payına, günde.
static func wolf_loss(stock_ratio: float, winter: bool, fog: bool, dog: bool, pen: bool) -> float:
	return 0.01 * (1.0 + 1.5 * (1.0 - clampf(stock_ratio, 0.0, 1.0))) * (1.5 if winter else 1.0) * (1.5 if fog else 1.0) \
		* (0.4 if dog else 1.0) * (0.3 if pen else 1.0)


## Saatin evresi (saf; GameClock'un yeri yokken): Kışlak'ın Aralık günü (act1.md §4, §8.11; doğuş ≈07:14).
static func phase_of(p_minute: float) -> StringName:
	var m := fposmod(p_minute, 1440.0)
	if m >= 390.0 and m < 465.0:
		return &"dawn"
	if m >= 465.0 and m < 660.0:
		return &"morning"
	if m >= 660.0 and m < 840.0:
		return &"noon"
	if m >= 840.0 and m < 1005.0:
		return &"golden"
	if m >= 1005.0 and m < 1095.0:
		return &"dusk"
	return &"night"


static func _vec2(v: Variant) -> Vector2:
	if v is Array and (v as Array).size() >= 2:
		return Vector2(float(v[0]), float(v[1]))
	return v if v is Vector2 else Vector2.ZERO
