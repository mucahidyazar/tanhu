class_name BoneRules
extends RefCounted
## «Ak Kemik»in kuralları (saf; Çocukluk, 20 Eylül MÖ 228 akşamı; K110, story.md §5 «İki yeni gün»; Kazakların «aksüyek»i): üç çocuk
## (Mete, Yançi, Luhun) ay ışığında ak kemiği arar. Atan kemiği bağlama direğinin önünden ağılın ötesindeki çayıra fırlatır (25–45 m, her
## elde başka yere); bulan direğe koşar, ötekiler kovalar; taşıyana 1 m'den yaklaşan yakalar ve kemiği alır, o koşar, yakalanan 2 sn durur.
## Direğe varan eli kazanır; üç el; kazanan sonraki eli atar. Ceza yoktur: oyuncu hep yenilse de oyun üç elde biter. Görünüş ve kişiler
## bone_play.gd'dedir; çocukların aklı BoneBrain'dedir (bone_brain.gd). Konumlar düzlemdir: Vector2(x, z).
##   var r := BoneRules.new(["mete_child", "yanchi_child", "luhun_child"], post_xz, "luhun_child")
##   r.begin_hand()                 # atan: ilk elde verilen, sonra son elin kazananı
##   r.land(at)                     # kemik yere düştü: arama başlar
##   r.step(dt, {"mete_child": p0, "yanchi_child": p1, "luhun_child": p2})
##   for e in r.take_events(): ...  # {type: found | tagged | won | hand | landed | done, by, from, at, hand}
##   r.finish_hand()                # kazananın sözünden sonra: sonraki el ya da DONE

## Oyuncunun kimliği (Mete; sahnenin kişisi değil, PlayerController'dır).
const PLAYER := "mete_child"
## El sayısı.
const HANDS := 3
## Yakalama (m): taşıyana bu kadar yaklaşan kemiği alır. Bulma (m): kemiğe bu kadar yaklaşan alır. Direğe varış (m).
const TAG_RADIUS := 1.0
const PICK_RADIUS := 0.8
const POST_RADIUS := 1.4
## Yakalanan bu kadar durur (sn); kemiği yeni alan bu kadar yakalanmaz (sn: hemen geri alınmasın; bulan da bu payla kalkar).
const FREEZE_S := 2.0
const IMMUNE_S := 1.0
const FOUND_IMMUNE_S := 0.6
## Atışın uzaklığı (m) ve oyuncunun E'yi basılı tutup tam güce vardığı süre (sn).
const THROW_RANGE := Vector2(25.0, 45.0)
const HOLD_FULL_S := 1.4
## İki düşüş arası en az (m): her elde başka yer.
const LANDING_GAP := 12.0

enum Phase { IDLE, THROW, SEARCH, CARRY, WON, DONE }

var runners := PackedStringArray()
## Direğin yeri (düzlem).
var post := Vector2.ZERO
var hands := HANDS
## O anki el (0'dan; begin_hand artırır).
var hand := -1
var thrower := ""
var first_thrower := ""
var phase := Phase.IDLE
## Kemiğin yeri: yerdeyken düştüğü yer, taşınırken taşıyanın yeri; atılırken INF.
var bone := Vector2.INF
var carrier := ""
## Ellerin kazananları ve ilk bulanları (sırayla).
var winners := PackedStringArray()
var finders := PackedStringArray()
## Bu elde kemik kaç kez el değiştirdi.
var tags := 0
## Yakalanan → kalan duruş (sn).
var frozen: Dictionary = {}
## Kemiği yeni alanın yakalanmazlığı (sn).
var immune := 0.0
## Ellerin düşüş yerleri.
var landings := PackedVector2Array()
## Ayarlar (sahnenin verisi yazabilir).
var tag_radius := TAG_RADIUS
var pick_radius := PICK_RADIUS
var post_radius := POST_RADIUS
var freeze_s := FREEZE_S
## Bu elin arama ve taşıma süreleri (sn; günlük ve sınama).
var search_s := 0.0
var carry_s := 0.0

var _events: Array[Dictionary] = []


func _init(p_runners: PackedStringArray = PackedStringArray([PLAYER, "yanchi_child", "luhun_child"]), p_post: Vector2 = Vector2.ZERO,
		p_first: String = "luhun_child") -> void:
	runners = p_runners
	post = p_post
	first_thrower = p_first


## Yeni el: atan verilmezse ilk elde ilk atan, sonra son elin kazananı. Kemik atanın elindedir (THROW).
func begin_hand(p_thrower: String = "") -> void:
	hand += 1
	if not p_thrower.is_empty():
		thrower = p_thrower
	elif not winners.is_empty():
		thrower = winners[winners.size() - 1]
	else:
		thrower = first_thrower
	phase = Phase.THROW
	bone = Vector2.INF
	carrier = ""
	tags = 0
	frozen.clear()
	immune = 0.0
	search_s = 0.0
	carry_s = 0.0
	_events.append({"type": "hand", "hand": hand, "thrower": thrower})


## Kemik yere düştü: arama başlar.
func land(at: Vector2) -> void:
	if phase != Phase.THROW:
		return
	bone = at
	landings.append(at)
	phase = Phase.SEARCH
	_events.append({"type": "landed", "at": at, "hand": hand})


## Bir adım: duruşlar ve yakalanmazlık azalır; aramada kemiğe en yakın (pick_radius içinde, durmayan) alır; taşırken direğe varan kazanır,
## yoksa taşıyana tag_radius'tan yaklaşan (en yakını) kemiği alır, taşıyan freeze_s durur. positions: kimlik → düzlem konumu.
func step(dt: float, positions: Dictionary) -> void:
	for id: Variant in frozen.keys():
		frozen[id] = float(frozen[id]) - dt
		if float(frozen[id]) <= 0.0:
			frozen.erase(id)
	immune = maxf(immune - dt, 0.0)
	match phase:
		Phase.SEARCH:
			search_s += dt
			_step_search(positions)
		Phase.CARRY:
			carry_s += dt
			_step_carry(positions)


func _step_search(positions: Dictionary) -> void:
	var best := ""
	var best_d := pick_radius
	for id in runners:
		if is_frozen(id) or not positions.has(id):
			continue
		var d := (positions[id] as Vector2).distance_to(bone)
		if d <= best_d:
			best_d = d
			best = id
	if best.is_empty():
		return
	carrier = best
	phase = Phase.CARRY
	immune = FOUND_IMMUNE_S
	if finders.size() <= hand:
		finders.append(best)
	_events.append({"type": "found", "by": best, "at": bone, "hand": hand})


func _step_carry(positions: Dictionary) -> void:
	var at: Vector2 = positions.get(carrier, bone)
	bone = at
	if at.distance_to(post) <= post_radius:
		phase = Phase.WON
		winners.append(carrier)
		_events.append({"type": "won", "by": carrier, "hand": hand, "at": at})
		return
	if immune > 0.0:
		return
	var tagger := ""
	var best_d := tag_radius
	for id in runners:
		if id == carrier or is_frozen(id) or not positions.has(id):
			continue
		var d := (positions[id] as Vector2).distance_to(at)
		if d <= best_d:
			best_d = d
			tagger = id
	if tagger.is_empty():
		return
	frozen[carrier] = freeze_s
	_events.append({"type": "tagged", "by": tagger, "from": carrier, "at": at, "hand": hand})
	carrier = tagger
	tags += 1
	immune = IMMUNE_S


## Kazananın sözünden sonra: son el değilse kazanan sonraki eli atar, son else DONE.
func finish_hand() -> void:
	if phase != Phase.WON:
		return
	if is_last_hand():
		phase = Phase.DONE
		_events.append({"type": "done", "hand": hand})
		return
	begin_hand(winners[winners.size() - 1])


func is_last_hand() -> bool:
	return hand >= hands - 1


func is_frozen(id: String) -> bool:
	return frozen.has(id)


## Kalan duruş (sn; durmuyorsa 0).
func frozen_left(id: String) -> float:
	return float(frozen.get(id, 0.0))


func is_done() -> bool:
	return phase == Phase.DONE


## Mete'nin kazandığı el sayısı.
func player_wins() -> int:
	return winners.count(PLAYER)


## Biriken olaylar (alınınca silinir).
func take_events() -> Array[Dictionary]:
	var out := _events
	_events = []
	return out


static func phase_name(p: int) -> String:
	return ["idle", "throw", "search", "carry", "won", "done"][clampi(p, 0, 5)]


# --- Atış (saf) -------------------------------------------------------------------------------------------------

## Oyuncunun atışının uzaklığı (m): E basılı tutuldukça THROW_RANGE'in altından üstüne (HOLD_FULL_S'de tam), fazlası tamdır.
static func throw_distance(hold_s: float, range_m: Vector2 = THROW_RANGE, full_s: float = HOLD_FULL_S) -> float:
	var t := clampf(hold_s / maxf(full_s, 0.01), 0.0, 1.0)
	return lerpf(range_m.x, range_m.y, smoothstep(0.0, 1.0, t))


## Atışın düştüğü yer (saf, tohumlu): from'dan dir yönünde (düzlem birim yön; ±spread radyan), d_range uzaklıkta; önceki düşüşlerden en az
## gap, engellerden (Vector3(x, z, r)) margin uzakta ve alanın (center, radius) içinde. Tries aday denenir; hiçbiri tutmazsa kuralları en az
## bozan seçilir (yine alanın içine itilir). Her elde başka yer: aynı tohum aynı yeri verir, önceki düşüşler aday kümesini değiştirir.
static func pick_landing(rng: RandomNumberGenerator, from: Vector2, dir: Vector2, spread: float, d_range: Vector2, previous: PackedVector2Array,
		obstacles: Array, area_center: Vector2, area_radius: float, gap: float = LANDING_GAP, margin: float = 1.5, tries: int = 40) -> Vector2:
	var base := dir.normalized() if dir.length_squared() > 0.000001 else Vector2(1.0, 0.0)
	var best := Vector2.INF
	var best_cost := INF
	for i in tries:
		var a := rng.randf_range(-spread, spread)
		var d := rng.randf_range(d_range.x, d_range.y)
		var p := from + base.rotated(a) * d
		var cost := landing_cost(p, previous, obstacles, area_center, area_radius, gap, margin)
		if cost <= 0.0:
			return p
		if cost < best_cost:
			best_cost = cost
			best = p
	return keep_inside(push_out(best, obstacles, margin), area_center, area_radius, margin)


## Adayın kuralları ne kadar bozduğu (saf; 0 = uyar): önceki düşüşe yakınlık, engelin içi, alanın dışı.
static func landing_cost(p: Vector2, previous: PackedVector2Array, obstacles: Array, area_center: Vector2, area_radius: float, gap: float,
		margin: float) -> float:
	var cost := 0.0
	for q in previous:
		cost += maxf(gap - p.distance_to(q), 0.0)
	for o: Variant in obstacles:
		var c := o as Vector3
		cost += maxf(c.z + margin - p.distance_to(Vector2(c.x, c.y)), 0.0) * 4.0
	if area_radius > 0.0:
		cost += maxf(p.distance_to(area_center) - (area_radius - margin), 0.0) * 4.0
	return cost


## Oyuncunun attığı kemiğin yeri (saf): bakış yönünde uzaklık kadar; engelin içine düşerse dışına itilir, alanın dışına düşerse içine çekilir.
static func aimed_landing(from: Vector2, facing: Vector2, distance: float, obstacles: Array, area_center: Vector2, area_radius: float,
		margin: float = 1.5) -> Vector2:
	var base := facing.normalized() if facing.length_squared() > 0.000001 else Vector2(1.0, 0.0)
	var p := from + base * distance
	return keep_inside(push_out(p, obstacles, margin), area_center, area_radius, margin)


## Engellerin (Vector3(x, z, r)) dışına iter (saf).
static func push_out(p: Vector2, obstacles: Array, margin: float = 1.5) -> Vector2:
	var out := p
	for _pass in 3:
		for o: Variant in obstacles:
			var c := o as Vector3
			var center := Vector2(c.x, c.y)
			var need := c.z + margin
			var d := out.distance_to(center)
			if d < need:
				var away := (out - center) / d if d > 0.0001 else Vector2(1.0, 0.0)
				out = center + away * need
	return out


## Alanın içine çeker (saf).
static func keep_inside(p: Vector2, center: Vector2, radius: float, margin: float = 1.5) -> Vector2:
	if radius <= 0.0:
		return p
	var limit := maxf(radius - margin, 0.0)
	var off := p - center
	return center + off.limit_length(limit) if off.length() > limit else p
