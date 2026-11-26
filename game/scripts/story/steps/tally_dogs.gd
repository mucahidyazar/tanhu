class_name TallyDogs
extends RefCounted
## Ebe Obası'nın iki köpeği ve bozkırın görgüsü (saf; K110 «yurda yaklaşırken köpeği tutturmak bozkır görgüsüdür», story.md §5 «İki yeni
## gün»): obaya yaklaşan yabancıyı köpek karşılar; gelen durur ve «Köpeğinizi tutun!» diye seslenir, ev sahibi çıkıp köpeği tutar, ancak
## öyle girilir. Köpekler ısırmaz, değmez: oyuncunun önünde, obayla arasında, en az MIN_GAP uzakta durur ve havlar; oyuncu yürüdükçe
## önüne geçer (obanın çevresindeki bekleme çemberinde, oyuncu ile oba arasındaki doğruda), oyuncu üstlerine yürürse havlar ve biraz
## geriler ama yolu açmaz (sahne bekleme çemberini oyuncunun engeli yapar: fence). Seslenmek yalnız oyuncu durmuşken ve köpeklere yakınken
## işler (can_call); seslenince Hereka gelir, tutunca (hold) köpekler onun yanına gider, susar; konuşmadan sonra (calm) yatar.
## Hız sınırı (K105): köpeğin koşusu oyuncunun en yüksek koşusunu aşmaz (cap). Konumlar düzlemdir: Vector2(x, z).
##   var dogs := TallyDogs.new(camp_xz, [home_a, home_b], PaceLimit.run_cap(player))
##   dogs.step(dt, player_xz, player_speed)    # her kare
##   dogs.can_call(player_xz, player_speed)    # E ipucu: «Seslen»
##   dogs.call_out()                           # «Köpeğinizi tutun!»
##   dogs.hold(hereka_xz); dogs.calm()
##   for e in dogs.take_events(): ...          # {type: bark | growl | settle, dog, at}

enum State { REST, ALERT, BLOCK, CALLED, HELD, CALM }

## Oyuncu obanın merkezine bu kadar yaklaşınca (m) köpekler kalkar ve havlar.
const ALERT_AT := 25.0
## Bekleme çemberi (m; obanın merkezinden): köpekler burada yolu keser; seslenmeden oyuncu bunun içine giremez (fence).
const GUARD_R := 16.5
## Oyuncuya en çok bu kadar yaklaşırlar (m; ısırmaz, değmez) ve önünde bu uzaklıkta dururlar (m).
const MIN_GAP := 2.0
const BLOCK_GAP := 3.2
## Oyuncu üstlerine yürürse bekleme çemberinden en çok bu kadar içeri gerilerler (m).
const YIELD_M := 3.0
## İki köpeğin yan aralığı (m).
const SPREAD := 1.7
## Havlama aralığı (sn; BLOCK'ta, oyuncu yürürken daha sık) ve seslenince hırlama aralığı.
const BARK_EVERY := Vector2(0.9, 1.7)
const BARK_MOVING_K := 0.65
const GROWL_EVERY := Vector2(1.6, 2.6)
## Oyuncu bu hızın altındaysa durmuş sayılır (m/sn) ve seslenme köpeklere bu kadar yakından işler (m).
const STILL_SPEED := 0.45
const CALL_WITHIN := 11.0
## Köpeğin yürüyüşü ve tırısı (m/sn; data/fauna/kinds.json «dog»: walk 1,0, trot 3,2); ivmesi (m/sn²).
const WALK := 1.0
const TROT := 3.2
const ACCEL := 7.0
## Tutulunca Hereka'nın yanındaki yerleri (m) ve sakinleşince yatakları.
const HELD_SIDE := 0.9

var camp := Vector2.ZERO
var homes: Array[Vector2] = []
var pos: Array[Vector2] = []
var vel: Array[Vector2] = []
var state := State.REST
var cap := PaceLimit.CHILD_RUN
## Hereka'nın yeri (tutunca).
var keeper := Vector2.INF
## Bekleme çemberi ve uyanma uzaklığı (sahnenin verisi yazabilir).
var guard_r := GUARD_R
var alert_at := ALERT_AT
## Ölçü: köpeklerin oyuncuya en yakın geldiği (m) ve en yüksek hızı (m/sn).
var closest := INF
var peak_speed := 0.0

var _bark_left: Array[float] = []
var _events: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()
var _player := Vector2.INF
var _player_speed := 0.0


func _init(p_camp: Vector2 = Vector2.ZERO, p_homes: Array = [], p_cap: float = PaceLimit.CHILD_RUN, seed_value: int = 21) -> void:
	camp = p_camp
	cap = p_cap
	_rng.seed = seed_value
	for h: Variant in p_homes:
		homes.append(h as Vector2)
	if homes.is_empty():
		homes = [camp + Vector2(2.0, 1.0), camp + Vector2(-2.0, 1.0)]
	for h in homes:
		pos.append(h)
		vel.append(Vector2.ZERO)
		_bark_left.append(_rng.randf_range(0.1, 0.5))


func dog_count() -> int:
	return pos.size()


## Bir adım: durum (oyuncunun uzaklığıyla), hedef yerler, yürüyüş (ivme ve hız sınırı), havlama olayları.
func step(dt: float, player: Vector2, player_speed: float = 0.0) -> void:
	_player = player
	_player_speed = player_speed
	if state == State.REST and player.distance_to(camp) <= alert_at:
		state = State.ALERT
		for i in pos.size():
			_bark_left[i] = _rng.randf_range(0.0, 0.25)
	if state == State.ALERT and _all_near(targets(player), 1.2):
		state = State.BLOCK
	var goals := targets(player)
	for i in pos.size():
		var speed := _speed_for(i, goals[i])
		var want := goals[i] - pos[i]
		var desired := want.normalized() * minf(speed, want.length() / maxf(dt, 0.001)) if want.length() > 0.05 else Vector2.ZERO
		vel[i] = vel[i].move_toward(desired, ACCEL * dt)
		var next := pos[i] + vel[i] * dt
		# Isırmaz, değmez: oyuncuya MIN_GAP'ten yaklaşmaz (tutulup sakinleşince de oyuncunun yolunda durmaz).
		if player != Vector2.INF and next.distance_to(player) < MIN_GAP:
			var away := (next - player).normalized() if next.distance_to(player) > 0.001 else (pos[i] - player).normalized()
			next = player + away * MIN_GAP
		if dt > 0.0:
			peak_speed = maxf(peak_speed, pos[i].distance_to(next) / dt)
		pos[i] = next
		if player != Vector2.INF:
			closest = minf(closest, pos[i].distance_to(player))
	_tick_voice(dt)


## Köpeklerin hedefleri (saf değil: duruma ve oyuncuya göre): REST yatak; ALERT ve BLOCK oyuncunun önünde, bekleme çemberinde, oyuncu ile
## obanın arasındaki doğruda (iki köpek yan yana); CALLED aynı yerde (ev sahibini bekler); HELD Hereka'nın iki yanı; CALM yatak.
func targets(player: Vector2) -> Array[Vector2]:
	var out: Array[Vector2] = []
	match state:
		State.ALERT, State.BLOCK, State.CALLED:
			var front := block_point(player)
			var dir := (player - camp).normalized() if player.distance_to(camp) > 0.01 else Vector2(0.0, 1.0)
			var side := Vector2(-dir.y, dir.x)
			for i in pos.size():
				var lane := (float(i) - float(pos.size() - 1) * 0.5) * SPREAD
				out.append(front + side * lane)
		State.HELD:
			var k := keeper if keeper != Vector2.INF else camp
			var face := (player - k).normalized() if player != Vector2.INF and player.distance_to(k) > 0.01 else Vector2(0.0, 1.0)
			var side := Vector2(-face.y, face.x)
			for i in pos.size():
				out.append(k + side * HELD_SIDE * (1.0 if i % 2 == 0 else -1.0) + face * 0.4)
		_:
			for i in pos.size():
				out.append(homes[i % homes.size()])
	return out


## Oyuncunun önündeki bekleme yeri (saf): obanın merkezinden oyuncuya doğru bekleme çemberinde; oyuncu çembere yaklaştıkça köpekler en çok
## YIELD_M geriler, oyuncuyla aralarında en az BLOCK_GAP kalır.
func block_point(player: Vector2) -> Vector2:
	var dir := (player - camp).normalized() if player.distance_to(camp) > 0.01 else Vector2(0.0, 1.0)
	var player_r := player.distance_to(camp)
	var r := clampf(player_r - BLOCK_GAP, guard_r - YIELD_M, guard_r)
	return camp + dir * r


## Oyuncunun engeli (Vector3(x, z, r); PlayerController gövdenin yarıçapını ekler): köpekler yolu keserken (ALERT, BLOCK, CALLED) oyuncu
## en içteki bekleme yerinin MIN_GAP dışında durur; tutulunca kalkar (boş).
func fence(body_radius: float = 0.3) -> Vector3:
	if state in [State.ALERT, State.BLOCK, State.CALLED]:
		return Vector3(camp.x, camp.y, fence_radius() - body_radius)
	return Vector3.ZERO


## Oyuncunun merkezinin obanın merkezine en çok yaklaşabildiği uzaklık (m), köpekler yolu keserken.
func fence_radius() -> float:
	return guard_r - YIELD_M + MIN_GAP


## Köpekler yolu kesiyor mu (oyuncu seslenmeden giremez)?
func blocks() -> bool:
	return state in [State.ALERT, State.BLOCK, State.CALLED]


## Seslenebilir mi: köpekler yolu kesiyor, oyuncu durmuş ve köpeklere yakın (görgü: önce durulur, sonra seslenilir).
func can_call(player: Vector2, player_speed: float) -> bool:
	if not state in [State.ALERT, State.BLOCK]:
		return false
	if player_speed > STILL_SPEED:
		return false
	return nearest_distance(player) <= CALL_WITHIN


## Oyuncu yürürken köpeklerin önündeyse (ipucu: «Dur ve seslen»).
func needs_stop(player: Vector2, player_speed: float) -> bool:
	return state in [State.ALERT, State.BLOCK] and player_speed > STILL_SPEED and nearest_distance(player) <= CALL_WITHIN


## «Köpeğinizi tutun!»: kabul edildiyse CALLED (köpekler yerinde, hırlar; ev sahibi gelir). Döner: kabul edildi mi.
func call_out() -> bool:
	if not state in [State.ALERT, State.BLOCK]:
		return false
	state = State.CALLED
	for i in pos.size():
		_bark_left[i] = _rng.randf_range(GROWL_EVERY.x, GROWL_EVERY.y)
	return true


## Hereka köpekleri tuttu (at: Hereka'nın yeri): yanına giderler, susarlar (bir kez sakinleşme sesi).
func hold(at: Vector2) -> void:
	keeper = at
	if state != State.HELD:
		state = State.HELD
		_events.append({"type": "settle", "dog": 0, "at": pos[0]})


## Konuşma bitti: köpekler yataklarına döner, yatar.
func calm() -> void:
	state = State.CALM


func nearest_distance(player: Vector2) -> float:
	var best := INF
	for p in pos:
		best = minf(best, p.distance_to(player))
	return best


## Köpeğin şu anki hızı (m/sn; görünüşün klibi bundan).
func speed_of(i: int) -> float:
	return vel[i].length() if i >= 0 and i < vel.size() else 0.0


## Köpeğin baktığı yer: yolu keserken ve tutulurken oyuncu, giderken gidişi.
func look_of(i: int) -> Vector2:
	if state in [State.ALERT, State.BLOCK, State.CALLED, State.HELD] and _player != Vector2.INF and vel[i].length() < 1.2:
		return _player
	return pos[i] + vel[i] if vel[i].length() > 0.05 else Vector2.INF


func take_events() -> Array[Dictionary]:
	var out := _events
	_events = []
	return out


static func state_name(s: int) -> String:
	return ["rest", "alert", "block", "called", "held", "calm"][clampi(s, 0, 5)]


func _speed_for(i: int, goal: Vector2) -> float:
	var far := pos[i].distance_to(goal)
	var speed := WALK
	match state:
		State.ALERT, State.BLOCK, State.CALLED:
			speed = TROT if far > 0.8 else WALK
		State.HELD:
			speed = TROT * 0.7 if far > 2.0 else WALK
		_:
			speed = WALK
	return PaceLimit.limit(speed, cap)


func _all_near(goals: Array[Vector2], within: float) -> bool:
	for i in pos.size():
		if pos[i].distance_to(goals[i]) > within:
			return false
	return true


func _tick_voice(dt: float) -> void:
	if not state in [State.ALERT, State.BLOCK, State.CALLED]:
		return
	for i in pos.size():
		_bark_left[i] -= dt
		if _bark_left[i] > 0.0:
			continue
		if state == State.CALLED:
			_events.append({"type": "growl", "dog": i, "at": pos[i]})
			_bark_left[i] = _rng.randf_range(GROWL_EVERY.x, GROWL_EVERY.y)
		else:
			_events.append({"type": "bark", "dog": i, "at": pos[i]})
			var k := BARK_MOVING_K if _player_speed > STILL_SPEED else 1.0
			_bark_left[i] = _rng.randf_range(BARK_EVERY.x, BARK_EVERY.y) * k
