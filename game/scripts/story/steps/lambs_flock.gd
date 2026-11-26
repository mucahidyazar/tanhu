class_name LambFlock
extends RefCounted
## «Kuzular»ın kuzuları (saf; Önsöz, 9 Nisan sabahı; K110; story.md §3 «Göl Obası'nda üç gün»): tipi gecesi açıkta doğan dört kuzu obanın
## yamacında, her biri anasının yanındadır. Kuzu meler (konumlu ses, ≈30 m'den duyulur, HEAR_M), anası çağırır; kardaki iz yurdun ağılından
## ana koyuna gider (track). Kuzu kucağa alınır (E; taşıyan yalnız yürür, CARRY_MODS), anası ardından gelir (follow_point). Yurdun kapısında
## (home) Ana sayar: «Bir», «İki», «Üç». Dördüncü kuzu dere tarafındadır (last) ve donmuştur (frozen): Ana «Bu donmuş.» der, kuzu ocağın
## yanına konur (hearth), ağzına ilk süt damlatılır (DRIPS kez E), kuzu kıpırdar, meler (warmed), Ana «Dört. Hepsi sağ.» der.
## Ceza yoktur: kuzu düşmez, kaçmaz; geç bulunan kuzu yalnız söz sırasını değiştirir. Görünüşü LambsView'dur (lambs_view.gd), adımı
## lambs_gather.gd sürer.
##   var f := LambFlock.new(layout)                # {home, hearth, lambs: [{at, ewe, frozen}], seed}
##   f.tick(dt, player_pos)                        # meleme olayları: [{lamb, kind: "bleat" | "call", at, db}]
##   f.pick_up(i); f.deliver(); f.lay_by_hearth(); f.drip()

## Meleme duyulan en uzak yer (m) ve yakında meleme düzeyi (dB; uzaklıkla doğrusal söner).
const HEAR_M := 30.0
const NEAR_DB := 0.0
const FAR_DB := -26.0
## Melemenin aralığı (sn): kayıp kuzu sık meler, donmuş kuzu seyrek ve kısık; ana koyun arada çağırır.
const BLEAT_EVERY := Vector2(2.6, 4.8)
const FROZEN_EVERY := Vector2(5.0, 8.0)
const FROZEN_DB := -8.0
const EWE_EVERY := Vector2(6.0, 10.0)
## Kucağa alma ve bırakma erimi (m), yurdun kapısının ve ocağın erimi.
const PICK_REACH := 1.5
const HOME_REACH := 2.6
const HEARTH_REACH := 1.6
## Taşırken yürüyüş (PlayerController.move_mods): koşu ve zıplama yok, hız ×0,85.
const CARRY_MODS := {"speed_k": 0.85, "can_run": false, "can_jump": false}
## Ana koyunun taşıyanın ardındaki uzaklığı (m) ve yürüyüşü (m/sn; K105: oyuncunun yürüyüşünü aşmaz).
const FOLLOW_GAP := 1.7
const EWE_SPEED := 1.25
## Kardaki izin adım aralığı (m) ve kıvrımı (m).
const TRACK_STEP := 0.9
const TRACK_WIGGLE := 1.6
## Donmuş kuzunun ağzına damlatılan süt.
const DRIPS := 3

## Kuzunun durumu: lost (yamaçta), carried (kucakta), home (yurtta sayıldı), by_hearth (ocağın yanında), warmed (ısındı).
const LOST := &"lost"
const CARRIED := &"carried"
const HOME := &"home"
const BY_HEARTH := &"by_hearth"
const WARMED := &"warmed"

var home := Vector3.ZERO
var hearth := Vector3.ZERO
## Yurda getirilen anaların ve kuzuların durduğu yer (kapının yanı; yoksa kapı).
var pen := Vector3.INF
## [{at, ewe, frozen, state, ewe_at}] (at kuzunun yeri; ewe_at anasının şimdiki yeri).
var lambs: Array[Dictionary] = []
var carrying := -1
## Sayılan kuzu (yurtta; donmuş kuzu ısınınca sayılır).
var counted := 0
var drips := 0
var clock := 0.0

var _rng := RandomNumberGenerator.new()
var _next_bleat := PackedFloat32Array()
var _next_call := PackedFloat32Array()


func _init(layout: Dictionary = {}) -> void:
	_rng.seed = int(layout.get("seed", 90409))
	home = LambFlock.vec(layout.get("home"), Vector3.ZERO)
	hearth = LambFlock.vec(layout.get("hearth"), home)
	pen = LambFlock.vec(layout.get("pen"), home + Vector3(1.4, 0.0, 1.2))
	for e: Variant in layout.get("lambs", []):
		var d: Dictionary = e
		var at := LambFlock.vec(d.get("at"), Vector3.ZERO)
		var ewe := LambFlock.vec(d.get("ewe"), at + Vector3(0.9, 0.0, 0.3))
		lambs.append({"at": at, "ewe": ewe, "ewe_at": ewe, "frozen": bool(d.get("frozen", false)), "state": LOST})
	_next_bleat.resize(lambs.size())
	_next_call.resize(lambs.size())
	for i in lambs.size():
		_next_bleat[i] = _rng.randf_range(0.3, 2.0)
		_next_call[i] = _rng.randf_range(2.0, 5.0)


## Sözlükteki noktayı Vector3'e çevirir ([x, z] ya da [x, y, z] ya da Vector3; yoksa def).
static func vec(v: Variant, def: Vector3) -> Vector3:
	if v is Vector3:
		return v
	if v is Array:
		var a: Array = v
		if a.size() == 2:
			return Vector3(float(a[0]), 0.0, float(a[1]))
		if a.size() >= 3:
			return Vector3(float(a[0]), float(a[1]), float(a[2]))
	return def


## Melemenin duyulduğu düzey (dB; saf): HEAR_M'nin ötesinde duyulmaz (-INF).
static func bleat_db(distance: float, base_db: float = NEAR_DB) -> float:
	if distance > HEAR_M:
		return -INF
	return base_db + (FAR_DB - NEAR_DB) * clampf(distance / HEAR_M, 0.0, 1.0)


static func audible(from: Vector3, to: Vector3) -> bool:
	return Vector2(from.x - to.x, from.z - to.z).length() <= HEAR_M


## Kardaki iz (saf, belirlenimci): from'dan to'ya kıvrılan çift toynak izinin noktaları [{at, yaw}] (koyun gece obadan yamaca yürüdü).
static func track(from: Vector3, to: Vector3, seed_value: int = 1) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var flat := Vector2(to.x - from.x, to.z - from.z)
	var length := flat.length()
	if length < 0.5:
		return out
	var dir := flat / length
	var side := Vector2(-dir.y, dir.x)
	var n := int(floor(length / TRACK_STEP))
	var phase := float(seed_value % 97) * 0.37
	for k in range(1, n):
		var s := float(k) / float(n)
		# Kıvrım iki ucta söner: iz yurdun kapısından çıkar, koyunun ayağında biter.
		var wiggle := sin(s * PI * 2.2 + phase) * TRACK_WIGGLE * sin(s * PI)
		var p := Vector2(from.x, from.z) + dir * (length * s) + side * wiggle
		var ahead := Vector2(from.x, from.z) + dir * (length * minf(s + 0.02, 1.0)) + side * sin(minf(s + 0.02, 1.0) * PI * 2.2 + phase) * TRACK_WIGGLE * sin(minf(s + 0.02, 1.0) * PI)
		var heading := (ahead - p)
		var yaw := atan2(heading.x, heading.y) if heading.length() > 0.0001 else atan2(dir.x, dir.y)
		out.append({"at": Vector3(p.x, 0.0, p.y), "yaw": yaw})
	return out


func lamb_count() -> int:
	return lambs.size()


func state_of(i: int) -> StringName:
	return lambs[i]["state"] if i >= 0 and i < lambs.size() else &""


## Kucağa alınabilecek en yakın kuzu (yoksa -1).
func lamb_in_reach(at: Vector3) -> int:
	if carrying >= 0:
		return -1
	var best := -1
	var best_d := PICK_REACH
	for i in lambs.size():
		if lambs[i]["state"] != LOST:
			continue
		var d := _flat(lambs[i]["at"], at)
		if d <= best_d:
			best = i
			best_d = d
	return best


## Dördüncü kuzu (dere tarafındaki, donmuş) yalnız öbürleri yurda varınca belli olur: last() o mu?
func remaining_lost() -> int:
	var n := 0
	for l in lambs:
		if l["state"] == LOST:
			n += 1
	return n


func pick_up(i: int) -> bool:
	if carrying >= 0 or i < 0 or i >= lambs.size() or lambs[i]["state"] != LOST:
		return false
	carrying = i
	lambs[i]["state"] = CARRIED
	return true


func carried_is_frozen() -> bool:
	return carrying >= 0 and bool(lambs[carrying]["frozen"])


func near_home(at: Vector3) -> bool:
	return _flat(home, at) <= HOME_REACH


func near_hearth(at: Vector3) -> bool:
	return _flat(hearth, at) <= HEARTH_REACH


## Kucaktaki kuzuyu yurtta bırakır: {ok, lamb, count, frozen}. Donmuş kuzu sayılmaz (ocağa gider); öbürleri sayılır.
func deliver() -> Dictionary:
	if carrying < 0:
		return {"ok": false}
	var i := carrying
	if bool(lambs[i]["frozen"]):
		return {"ok": true, "lamb": i, "count": counted, "frozen": true}
	carrying = -1
	lambs[i]["state"] = HOME
	lambs[i]["at"] = home
	counted += 1
	return {"ok": true, "lamb": i, "count": counted, "frozen": false}


## Donmuş kuzuyu ocağın yanına koyar.
func lay_by_hearth() -> bool:
	if carrying < 0 or not bool(lambs[carrying]["frozen"]):
		return false
	lambs[carrying]["state"] = BY_HEARTH
	lambs[carrying]["at"] = hearth
	carrying = -1
	drips = 0
	return true


func frozen_index() -> int:
	for i in lambs.size():
		if bool(lambs[i]["frozen"]):
			return i
	return -1


## Ağzına bir damla süt: DRIPS damlada kuzu ısınır, sayılır. {ok, drips, warmed}.
func drip() -> Dictionary:
	var i := frozen_index()
	if i < 0 or lambs[i]["state"] != BY_HEARTH:
		return {"ok": false, "drips": drips, "warmed": false}
	drips += 1
	var warmed := drips >= DRIPS
	if warmed:
		lambs[i]["state"] = WARMED
		counted += 1
	return {"ok": true, "drips": drips, "warmed": warmed}


func all_home() -> bool:
	for l in lambs:
		if not l["state"] in [HOME, WARMED]:
			return false
	return true


## Ana koyunun gideceği yer (saf): taşıyanın ardında FOLLOW_GAP; kuzusu yurttaysa yurdun yanındaki ağıl.
static func follow_point(carrier: Vector3, carrier_forward: Vector3) -> Vector3:
	var back := Vector3(-carrier_forward.x, 0.0, -carrier_forward.z)
	if back.length() < 0.001:
		back = Vector3(0.0, 0.0, 1.0)
	return carrier + back.normalized() * FOLLOW_GAP


## Bir kare: anaların yürüyüşü (taşıyanın ardından) ve meleme olayları. listener oyuncunun yeri (duyulmayan meleme olay değildir).
func tick(dt: float, listener: Vector3, carrier_forward: Vector3 = Vector3.FORWARD) -> Array[Dictionary]:
	clock += dt
	var events: Array[Dictionary] = []
	for i in lambs.size():
		var l: Dictionary = lambs[i]
		var state: StringName = l["state"]
		# Ana: kuzusu kucaktayken ardından gelir, yurttaysa kapının yanında durur.
		var goal: Vector3 = l["ewe"]
		if state == CARRIED:
			goal = LambFlock.follow_point(listener, carrier_forward)
		elif state in [HOME, BY_HEARTH, WARMED]:
			goal = pen + Vector3(0.9 * float(i % 2), 0.0, 0.9 * float(i / 2))
		var at: Vector3 = l["ewe_at"]
		var to := Vector3(goal.x - at.x, 0.0, goal.z - at.z)
		var step := EWE_SPEED * dt
		if to.length() > 0.3:
			l["ewe_at"] = at + to.normalized() * minf(step, to.length() - 0.3)
		# Meleme: kayıp kuzu ve ocaktaki kuzu meler; kucaktaki ara sıra.
		if state in [LOST, BY_HEARTH, CARRIED]:
			if clock >= _next_bleat[i]:
				var frozen := bool(l["frozen"]) and state != WARMED
				var span := FROZEN_EVERY if frozen else BLEAT_EVERY
				if state == CARRIED:
					span = BLEAT_EVERY * 2.0
				_next_bleat[i] = clock + _rng.randf_range(span.x, span.y)
				var src: Vector3 = l["at"] if state != CARRIED else listener
				var d := _flat(src, listener)
				if d <= HEAR_M:
					events.append({"lamb": i, "kind": "bleat", "at": src, "db": LambFlock.bleat_db(d, FROZEN_DB if frozen else NEAR_DB),
						"frozen": frozen})
		if state == LOST and clock >= _next_call[i]:
			_next_call[i] = clock + _rng.randf_range(EWE_EVERY.x, EWE_EVERY.y)
			var src2: Vector3 = l["ewe_at"]
			if _flat(src2, listener) <= HEAR_M * 1.3:
				events.append({"lamb": i, "kind": "call", "at": src2, "db": LambFlock.bleat_db(minf(_flat(src2, listener), HEAR_M), 2.0)})
	return events


## Bir sonraki hedef (HUD'un yönü; saf değil): kucakta kuzu varsa yurt (donmuşsa ve yurtta söylendiyse ocak), yoksa en yakın kayıp kuzu.
func target(from: Vector3, frozen_told: bool = false) -> Vector3:
	if carrying >= 0:
		return hearth if carried_is_frozen() and frozen_told else home
	var i := frozen_index()
	if i >= 0 and lambs[i]["state"] == BY_HEARTH:
		return hearth
	var best := Vector3.INF
	for l in lambs:
		if l["state"] != LOST:
			continue
		if best == Vector3.INF or _flat(l["at"], from) < _flat(best, from):
			best = l["at"]
	return best


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
