class_name FireSet
extends RefCounted
## Ateşler ve çukurlar (saf; survival.md §2.1, §2.4, §2.8; K45): zon başına en çok 6 ateş ve çukur (Eski Ocak sayılmaz; yenisi önce en eski
## çukuru, çukur yoksa en eski ateşi siler), yer seçimi (düz, su ve buz değil, yapıya ve başka ateşe ≥6 m), çukurun kalkışı (sönüşten 24
## oyun saati; oyuncu 30 m içindeyse ertelenir; 24 saatten uzun atlama hepsini kaldırır) ve kaydın «fires» dizisi. Sahibi Survival'dır.
##   var set := FireSet.new()
##   set.can_place(Vector2(8, 0), probe)         # "" ya da neden (slope, water, near_structure, near_fire)
##   var f := set.add(Vector2(8, 0), "testmap", true, 720.0, now)
##   set.near(player_xz, 3.0, "testmap")           # 3 m içindeki ateş ya da çukur (yoksa null)
##   set.advance(fuel_s, now, fx, day)             # [{fire, out, reason, at}]
##   set.prune(now, player_xz, "testmap")          # kalkan çukurlar

signal added(fire: FireState)
signal removed(fire: FireState)

var fires: Array[FireState] = []
var _serial := 0


## Ateşi kümeye ekler (yanan): zonun sınırı aşılırsa en eskisi gider. old: Eski Ocak (kimliği haritanın kaydıdır; sayıya girmez).
func add(at: Vector2, zone: String, stones: bool, fuel: float, now_abs: float, old := false, fire_id := "") -> FireState:
	var f := FireState.new()
	f.old = old
	_serial += 1
	f.id = fire_id if not fire_id.is_empty() else "fire_%d" % _serial
	f.light(at, zone, stones, fuel, now_abs)
	if not old:
		_make_room(zone)
	fires.append(f)
	added.emit(f)
	return f


## Yerleşimin ocağını ekler (FireState.hearth: yanar, yakıtı durur, taş halkalı, kayda girmez; aynı kimlik varsa onu döndürür).
## fuel evreyi verir (Orta: 360 sn).
func add_hearth(at: Vector2, zone: String, fire_id: String, fuel := 360.0) -> FireState:
	var have := by_id(fire_id)
	if have:
		return have
	var f := FireState.new()
	f.old = true
	f.hearth = true
	f.id = fire_id
	f.light(at, zone, true, fuel, 0.0)
	fires.append(f)
	added.emit(f)
	return f


## Kimlikle ateş (yoksa null).
func by_id(fire_id: String) -> FireState:
	for f in fires:
		if f.id == fire_id:
			return f
	return null


## Noktaya radius içindeki en yakın ateş ya da çukur (zon verilirse yalnız o zonun; yoksa null).
func near(at: Vector2, radius: float, zone := "") -> FireState:
	var best: FireState = null
	var best_d := INF
	for f in fires:
		if not zone.is_empty() and f.zone != zone:
			continue
		var d := at.distance_to(f.xz())
		if d <= radius and d < best_d:
			best = f
			best_d = d
	return best


## Zonun ateş ve çukur sayısı (Eski Ocak hariç).
func count(zone: String) -> int:
	var n := 0
	for f in fires:
		if f.zone == zone and not f.old:
			n += 1
	return n


## Yer seçimi (saf): "" geçerli, değilse neden. probe: normal (Callable(x, z) → Vector3), water (Callable(x, z) → bool), indoor (bool),
## structures ([Vector3(x, z, yarıçap)]: yapılar, kenarlarından 6 m), obstacles ([Vector3(x, z, açıklık)]: eşya, kaya, ağaç; yapı
## sayılmaz, yalnız üstüne kurulmaz), olds ([Vector2]: Eski Ocak'lar ve haritanın ocağı da ateş sayılır), zone.
func can_place(at: Vector2, probe: Dictionary = {}) -> String:
	var place: Dictionary = FireState.rule("place", {})
	var normal: Variant = probe.get("normal")
	if normal is Callable and (normal as Callable).is_valid():
		var n: Vector3 = (normal as Callable).call(at.x, at.y)
		if n.normalized().y < float(place.get("min_normal_y", 0.9)) - 1e-6:
			return "slope"
	# Yapı içinde ateş kurulmaz: orada ocak vardır.
	if bool(probe.get("indoor", false)):
		return "near_structure"
	var water: Variant = probe.get("water")
	if water is Callable and (water as Callable).is_valid() and bool((water as Callable).call(at.x, at.y)):
		return "water"
	var gap := float(place.get("structure_gap_m", 6.0))
	for s: Variant in probe.get("structures", []):
		if s is Vector3 and at.distance_to(Vector2(s.x, s.y)) < gap + float(s.z):
			return "near_structure"
	for o: Variant in probe.get("obstacles", []):
		if o is Vector3 and at.distance_to(Vector2(o.x, o.y)) < float(o.z):
			return "near_structure"
	var fire_gap := float(place.get("fire_gap_m", 6.0))
	var zone := str(probe.get("zone", ""))
	for f in fires:
		if (zone.is_empty() or f.zone == zone) and at.distance_to(f.xz()) < fire_gap:
			return "near_fire"
	for o: Variant in probe.get("olds", []):
		if o is Vector2 and at.distance_to(o) < fire_gap:
			return "near_fire"
	return ""


## Zaman: bütün ateşler (fuel_s yakıt saniyesi, now_abs adımın sonu). Döner: sönenler [{fire, reason, at}].
func advance(fuel_s: float, now_abs: float, fx: Variant = null, day: int = -1) -> Array:
	var out: Array = []
	for f in fires:
		var ev := f.advance(fuel_s, now_abs, fx, day)
		if not ev.is_empty():
			out.append({"fire": f, "reason": ev["reason"], "at": ev["at"]})
	return out


## Kalkma vakti gelen çukurlar kalkar: sönüşten 24 oyun saati sonra; oyuncu 30 m içindeyse (aynı zonda) ertelenir; Eski Ocak kalmaz,
## yanmaz ama silinmez. Döner: kalkanlar.
func prune(now_abs: float, player_xz: Vector2 = Vector2.INF, player_zone := "") -> Array[FireState]:
	var hold := float(FireState.rule("pit_hold_m", 30.0))
	var gone: Array[FireState] = []
	for f in fires.duplicate():
		if f.state != FireState.PIT or f.old:
			continue
		if now_abs < f.pit_expires_at():
			continue
		if player_xz.is_finite() and (player_zone.is_empty() or player_zone == f.zone) and player_xz.distance_to(f.xz()) <= hold:
			continue
		_remove(f)
		gone.append(f)
	return gone


## 24 oyun saatinden uzun atlama (atlas yolculuğu, Akan Kronik): bütün çukurlar kalkar (Eski Ocak kalır, sönmüş olarak).
func on_long_skip() -> Array[FireState]:
	var gone: Array[FireState] = []
	for f in fires.duplicate():
		if f.state == FireState.PIT and not f.old:
			_remove(f)
			gone.append(f)
	return gone


func remove(f: FireState) -> void:
	if fires.has(f):
		_remove(f)


func clear() -> void:
	for f in fires.duplicate():
		_remove(f)
	_serial = 0


## survival.fires (yerleşimin ocağı kayda girmez: katman kurar).
func to_array() -> Array:
	var out: Array = []
	for f in fires:
		if not f.hearth:
			out.append(f.to_dict())
	return out


## Diziyi okur: bozuk satır düşer, kimliksiz satıra kimlik verilir; yerleşimin ocakları kalır. Döner: okunan sayı.
func from_array(list: Variant) -> int:
	var hearths: Array[FireState] = []
	for f in fires:
		if f.hearth:
			hearths.append(f)
	clear()
	for f in hearths:
		fires.append(f)
		added.emit(f)
	var n := 0
	for row: Variant in (list if list is Array else []):
		var f := FireState.from_dict(row)
		if f == null:
			continue
		_serial += 1
		if f.id.is_empty() or by_id(f.id) != null:
			f.id = "fire_%d" % _serial
		else:
			var tail := f.id.trim_prefix("fire_")
			if tail.is_valid_int():
				_serial = maxi(_serial, int(tail))
		fires.append(f)
		added.emit(f)
		n += 1
	return n


## Zon sınırı (6): yer açılana dek önce en eski çukur, çukur yoksa en eski ateş gider. Eski Ocak sayılmaz, silinmez.
func _make_room(zone: String) -> void:
	var limit := int(FireState.rule("zone_max", 6))
	while count(zone) >= limit:
		var victim: FireState = null
		for pass_pit: bool in [true, false]:
			for f in fires:
				if f.zone != zone or f.old or (pass_pit and f.state != FireState.PIT):
					continue
				if victim == null or f.born < victim.born:
					victim = f
			if victim:
				break
		if victim == null:
			return
		_remove(victim)


func _remove(f: FireState) -> void:
	fires.erase(f)
	removed.emit(f)
