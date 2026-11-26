class_name BoneBrain
extends RefCounted
## «Ak Kemik»te Yançi'nin ve Luhun'un aklı (saf; bone_rules.gd'nin kuralıyla): her kare çocuğun istediği yer, hız ve kip. Arama: kemiğin
## düştüğü yere doğru, kişinin yanında (Yançi solda, Luhun sağda) giderek daralan bir sapmayla koşar, yakına varınca bakınarak yürür,
## görüşüne (5 m: kemik yakında ışıldar) girince kemiğe atılır; iki çocuk birbirinden ayrılır. Taşıma: direğe koşar; biri peşindeyse
## yana kaçar ve 2 sn'de bir kısa duraksar (kolaylık: Mete de yakalayabilsin); peşinde Mete varsa Mete'nin koşusunun altında koşar.
## Kovalama: çocuğu kovalayan onun peşine düşer, Mete'yi kovalayan önünü keser (direğe giden yolun üstüne). Hız sınırı (K105, PaceLimit):
## hiçbir istek oyuncunun en yüksek koşusunu (cap; çocukta 3,6 m/sn) aşmaz. Ceza yoktur: kurallar oyunu her durumda üç elde bitirir.
##   var brain := BoneBrain.new(PaceLimit.run_cap(player))
##   brain.begin_hand(rules, seed)
##   var w := brain.want("luhun_child", rules, positions, dt)   # {to: Vector2, speed: float, mode: String, face: Vector2}

## Çocukların huyu (m/sn, m, sn): search (koşarak arama), look (bakınarak yürüme), carry (kemikle koşu), chase (çocuğu kovalama),
## chase_player (Mete'yi kovalama), walk (direğe dönüş), sight (kemiği gördüğü uzaklık), guess (aramanın başındaki sapma), find_s (sapmanın
## kapandığı süre: oyuncu hiç aramasa da el biter), side (−1 sol, +1 sağ).
const DEFAULT_TRAITS := {
	"yanchi_child": {"search": 2.3, "look": 1.15, "carry": 2.9, "chase": 3.05, "chase_player": 3.25, "walk": 1.4, "sight": 5.0,
		"guess": 9.0, "find_s": 24.0, "side": -1.0},
	"luhun_child": {"search": 2.6, "look": 1.3, "carry": 3.0, "chase": 3.15, "chase_player": 3.35, "walk": 1.45, "sight": 5.5,
		"guess": 7.5, "find_s": 19.0, "side": 1.0},
}
## Kovalanan çocuk: peşindeki bu kadar yakınsa (m) kovalanıyor sayılır; PAUSE_EVERY sn kovalanınca PAUSE_S sn duraksar (PAUSE_SPEED'le
## arkasına bakar); JINK_WITHIN'den yakın kovalanınca JINK_M yana kaçar; Mete peşindeyse Mete'nin koşusundan en az PLAYER_MARGIN yavaş.
const CHASED_WITHIN := 7.0
const PAUSE_EVERY := 2.0
const PAUSE_S := 0.45
const PAUSE_SPEED := 0.55
const JINK_WITHIN := 3.5
const JINK_M := 2.2
const PLAYER_MARGIN := 0.6
## Aramada: guess noktasına bu kadar yaklaşınca bakınarak yürür (m); bakınmanın çemberi (m) ve dönüşü (rad/sn); iki çocuğun ayrılığı (m).
const NEAR_GUESS := 3.0
const WANDER_R := 2.6
const WANDER_RATE := 0.9
const SEPARATE_M := 3.2
## Mete'yi kovalayan önünü keser: Mete'nin direğe giden yolunda bu kadar ileriyi (m) hedefler.
const LEAD_M := 3.0

var cap := PaceLimit.CHILD_RUN
var traits: Dictionary = {}
## Çocukların direğin yanındaki yeri (atış ve el arası): kimlik → düzlem konumu (sahne yazar).
var spots: Dictionary = {}

var _t := 0.0
var _throw_dir := Vector2(1.0, 0.0)
var _chased: Dictionary = {}
var _pause: Dictionary = {}
var _jink: Dictionary = {}
var _wander: Dictionary = {}
var _rng := RandomNumberGenerator.new()


func _init(p_cap: float = PaceLimit.CHILD_RUN, p_traits: Dictionary = {}) -> void:
	cap = p_cap
	traits = DEFAULT_TRAITS.duplicate(true)
	for id: Variant in p_traits:
		var row: Dictionary = (traits.get(id, {}) as Dictionary).duplicate()
		row.merge(p_traits[id], true)
		traits[id] = row


## Yeni elin aklı: aramanın saati sıfırlanır, bakınmanın yönü tohumdan.
func begin_hand(rules: BoneRules, seed_value: int = 0) -> void:
	_t = 0.0
	_chased.clear()
	_pause.clear()
	_jink.clear()
	_wander.clear()
	_rng.seed = seed_value
	for id: Variant in traits:
		_wander[id] = _rng.randf() * TAU
		_jink[id] = 1.0 if _rng.randf() < 0.5 else -1.0
	if rules and rules.bone != Vector2.INF:
		_throw_dir = (rules.bone - rules.post).normalized()


## Kemik düştü: atışın yönü (sapmanın yanı) ve aramanın saati.
func landed(rules: BoneRules) -> void:
	_t = 0.0
	if rules.bone != Vector2.INF and rules.bone.distance_to(rules.post) > 0.01:
		_throw_dir = (rules.bone - rules.post).normalized()


func trait_of(id: String, key: String, fallback: float = 0.0) -> float:
	return float((traits.get(id, {}) as Dictionary).get(key, fallback))


## Çocuğun bu karedeki isteği: {to (düzlem), speed (m/sn, ≤ cap), mode (wait, throw, search, look, dash, carry, pause, chase, frozen,
## gather, cheer), face (bakacağı yer; INF: gidişine)}. positions: kimlik → düzlem konumu (oyuncu dahil).
func want(id: String, rules: BoneRules, positions: Dictionary, dt: float) -> Dictionary:
	var here: Vector2 = positions.get(id, rules.post)
	if rules.is_frozen(id):
		return _out(here, 0.0, "frozen", rules.bone)
	match rules.phase:
		BoneRules.Phase.SEARCH:
			return _search(id, rules, positions, here, dt)
		BoneRules.Phase.CARRY:
			if rules.carrier == id:
				return _carry(id, rules, positions, here, dt)
			return _chase(id, rules, positions, here)
		BoneRules.Phase.WON:
			if rules.carrier == id:
				return _out(here, 0.0, "cheer", Vector2.INF)
			return _out(_spot(id, rules), trait_of(id, "walk", 1.4), "gather", rules.post)
		BoneRules.Phase.THROW:
			if rules.thrower == id:
				return _out(rules.post, trait_of(id, "walk", 1.4), "throw", rules.post + _throw_dir * 10.0)
			return _out(_spot(id, rules), trait_of(id, "walk", 1.4), "wait", rules.post + _throw_dir * 10.0)
	return _out(_spot(id, rules), trait_of(id, "walk", 1.4), "gather", rules.post)


## Aramanın saati (sn; want'ın her çağrısı değil, sahnenin karesi ilerletir).
func tick(dt: float) -> void:
	_t += dt


func search_time() -> float:
	return _t


## Sapmanın büyüklüğü (saf): guess'ten find_s'de sıfıra iner.
static func guess_scale(t: float, find_s: float) -> float:
	return clampf(1.0 - t / maxf(find_s, 0.01), 0.0, 1.0)


func _search(id: String, rules: BoneRules, positions: Dictionary, here: Vector2, dt: float) -> Dictionary:
	var bone := rules.bone
	if here.distance_to(bone) <= trait_of(id, "sight", 5.0):
		return _out(bone, trait_of(id, "search", 2.4) * 1.15, "dash", bone)
	var side := Vector2(-_throw_dir.y, _throw_dir.x) * trait_of(id, "side", 1.0)
	var k := guess_scale(_t, trait_of(id, "find_s", 20.0))
	var guess := bone + side * trait_of(id, "guess", 8.0) * k + _throw_dir * trait_of(id, "guess", 8.0) * 0.35 * k
	var to := guess
	var speed := trait_of(id, "search", 2.4)
	var mode := "search"
	if here.distance_to(guess) <= NEAR_GUESS + WANDER_R * k:
		_wander[id] = float(_wander.get(id, 0.0)) + WANDER_RATE * dt
		to = guess + Vector2.from_angle(float(_wander[id])) * WANDER_R * maxf(k, 0.35)
		speed = trait_of(id, "look", 1.2)
		mode = "look"
	# İki çocuk birbirinden ayrılır (aynı yeri aramasınlar).
	for other: Variant in positions:
		if str(other) == id or str(other) == BoneRules.PLAYER:
			continue
		var p: Vector2 = positions[other]
		var d := here.distance_to(p)
		if d < SEPARATE_M and d > 0.001:
			to += (here - p) / d * (SEPARATE_M - d) * 1.5
	return _out(to, speed, mode, Vector2.INF)


func _carry(id: String, rules: BoneRules, positions: Dictionary, here: Vector2, dt: float) -> Dictionary:
	var to := rules.post
	var near_d := INF
	var near_id := ""
	for other: Variant in positions:
		if str(other) == id or rules.is_frozen(str(other)):
			continue
		var d := here.distance_to(positions[other] as Vector2)
		if d < near_d:
			near_d = d
			near_id = str(other)
	var chased := near_d <= CHASED_WITHIN
	var speed := trait_of(id, "carry", 2.9)
	var player_on := positions.has(BoneRules.PLAYER) and not rules.is_frozen(BoneRules.PLAYER) \
		and here.distance_to(positions[BoneRules.PLAYER] as Vector2) <= CHASED_WITHIN * 1.6
	if player_on:
		speed = minf(speed, cap - PLAYER_MARGIN)
	if chased:
		_chased[id] = float(_chased.get(id, 0.0)) + dt
	else:
		_chased[id] = 0.0
	var mode := "carry"
	if float(_pause.get(id, 0.0)) > 0.0:
		_pause[id] = float(_pause[id]) - dt
		speed = PAUSE_SPEED
		mode = "pause"
	elif chased and float(_chased[id]) >= PAUSE_EVERY:
		_chased[id] = 0.0
		_pause[id] = PAUSE_S
		_jink[id] = -float(_jink.get(id, 1.0))
		speed = PAUSE_SPEED
		mode = "pause"
	if near_d <= JINK_WITHIN and here.distance_to(rules.post) > JINK_M * 2.0:
		var ahead := (rules.post - here).normalized()
		to = here + ahead * 4.0 + Vector2(-ahead.y, ahead.x) * JINK_M * float(_jink.get(id, 1.0))
	return _out(to, speed, mode, (positions[near_id] as Vector2) if mode == "pause" and not near_id.is_empty() else Vector2.INF)


func _chase(id: String, rules: BoneRules, positions: Dictionary, here: Vector2) -> Dictionary:
	var target: Vector2 = positions.get(rules.carrier, rules.bone)
	if rules.carrier == BoneRules.PLAYER:
		# Mete'nin önünü keser: direğe giden yolunun biraz ilerisi.
		var lane := rules.post - target
		var lead := minf(LEAD_M, lane.length() * 0.5)
		var to := target + lane.normalized() * lead if lane.length() > 0.01 else target
		return _out(to, trait_of(id, "chase_player", 3.3), "chase", target)
	return _out(target, trait_of(id, "chase", 3.1), "chase", target)


func _spot(id: String, rules: BoneRules) -> Vector2:
	if spots.has(id):
		return spots[id]
	return rules.post + Vector2(-_throw_dir.y, _throw_dir.x) * 1.8 * trait_of(id, "side", 1.0) - _throw_dir * 1.2


func _out(to: Vector2, speed: float, mode: String, face: Vector2) -> Dictionary:
	return {"to": to, "speed": PaceLimit.limit(speed, cap), "mode": mode, "face": face}


## Düzlemde hedefe doğru bir adım (saf; sınamanın benzetimi ve sahnenin kişisi): hız m/sn, hedefi aşmaz.
static func step_toward(p: Vector2, to: Vector2, speed: float, dt: float) -> Vector2:
	var off := to - p
	var step := speed * dt
	return to if off.length() <= step else p + off.normalized() * step
