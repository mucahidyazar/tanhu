class_name Schedule
extends RefCounted
## Kişilerin günlük programı (Yol Haritası npc-schedules; act1.md §5, time.md §9.4; godot.md §3.1: Session'ın 7. adımı «schedule»).
## Veri data/story/act_1/npcs.json'dadır: yerler (act1.md §4'ün koordinatları), yollar (Esir Yolu, Kantu'nun çevrimi), kişilerin vakit
## blokları [başlangıç, bitiş, yer, iş] (hikâye gününe göre özel bloklar «special», kişinin günleri «days»), gece nöbeti (watch: dokuz
## ateşin nöbetçisi ve gündüzün üç nöbeti) ve kalabalık öbekleri (groups: pazar, Çukur, Esir Yolu'nun kolu; CrowdPlan.program).
##
## Saftır: düğüm ve çizim yoktur; saat GameClock'tur (oturumunki ya da katmanınki). Plan yalnız oyunun dakikasından çıkar (plan(id, dk)):
## kişi bloğunun yerindedir; bir sonraki bloğa yürüme süresi kadar önce çıkar ve yerine vaktinde varır (walk_speed 1,4 m/sn = oyun
## dakikasında 3,5 m; yol path_provider'dan, yoksa düz çizgi; blok «route» taşıyorsa o yolun düğümlerinden); «depart» bloğu başında çıkar
## (esir kolu). Yürüyüş bloktan uzun sürerse kişi geç varır, sonraki bloğun yeri de kayar (kalmadan yürür). İşler: stand, talk, work,
## craft, sit, sleep, carry (iki yer arasında gidip gelir), inside (yurtta, görünmez), away (haritada değil), cart (Kantu'nun arabası).
## Gece hâli 19:30'da, gündüz 06:40'ta başlar (K20): day_state_changed yayılır. Görünüşü kademe kademe çizmek (tam kişi ve kalabalık),
## plana yürüyerek yetişmek (K105, PaceLimit) ve 60 m ötesinde kadraj dışında sıçrama görünüm katmanınındır (FolkLayer, CrowdField).
##
##   var schedule := Schedule.new()
##   schedule.setup(Schedule.load_data(), clock)           # clock: GameClock
##   session.add_system(&"schedule", schedule, &"schedule")  # ya da her kare schedule.step(delta)
##   schedule.state_of("farnak")                             # {pos: Vector2, yaw, job, place, moving, speed, visible, kind}
##   schedule.plan("farnak", GameClock.abs_of(1042, 640.0))  # aynı sözlük, verilen anda (saf)
##   schedule.crowd_pose(i, 640.0)                           # kalabalığın i. kişisi (CrowdPlan.program_pose)

signal day_state_changed(state: StringName)

const DATA_PATH := "res://data/story/act_1/npcs.json"
const DAY_MIN := 1440.0
## Hikâye günlerinin mutlak günleri (Gün I 1.041 … Gün VI 1.046; time.md §9.2). Bunların dışı genel gündür (0).
const STORY_FIRST_DAY := 1041
const STORY_LAST_DAY := 1046
## İşler.
const JOBS: Array[String] = ["stand", "talk", "work", "craft", "sit", "sleep", "carry", "inside", "away", "cart"]
## Görünmeyen işler (yerine varınca).
const HIDDEN_JOBS: Array[String] = ["inside", "away", "cart"]
const DAY := &"day"
const NIGHT := &"night"
## Taşıma işinde uçlarda bekleme (oyun dk).
const CARRY_PAUSE := 1.0
## Yere bakış: kişi bloğun yerinde Ulu Ocak'a bakar (bu uzaklıktan yakınsa dışarı); nöbetçi ateşten dışarı.
const CENTER := Vector2.ZERO

var data: Dictionary = {}
var clock: GameClock
## Yerler (kimlik → Vector2) ve yollar (kimlik → PackedVector2Array).
var places: Dictionary = {}
var routes: Dictionary = {}
## Kişiler (kimlik → kayıt: {id, tier, look, blocks, special, days, post?}); sıra sabittir (people_ids).
var people: Dictionary = {}
var people_ids: PackedStringArray = PackedStringArray()
## Kalabalığın kişileri (CrowdPlan.program; öbeklerin sırasıyla).
var crowd: Array[Dictionary] = []
## Yürüyüş hızı (m/sn), yetişme katı, sıçrama uzaklığı (m).
var walk_speed := 1.4
var hurry := 1.5
var snap_m := 60.0
var day_from := 400.0
var night_from := 1170.0
## Yol isteği (A'nın navigasyonu gelince): func(from: Vector2, to: Vector2) -> PackedVector2Array; boşsa düz çizgi.
var path_provider: Callable
## Gündüz mü gece mi (son adımdaki).
var day_state: StringName = &""

## kişi → {gün: zaman çizelgesi}; kişi → son durum.
var _timelines: Dictionary = {}
var _states: Dictionary = {}


## Veri dosyası (saf okuma; yoksa ya da bozuksa boş).
static func load_data(path: String = DATA_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## Hikâye günü (1–6; Gün I = day_n 1.041); başka gün 0 (genel gün).
static func story_day(day_n: int) -> int:
	return day_n - STORY_FIRST_DAY + 1 if day_n >= STORY_FIRST_DAY and day_n <= STORY_LAST_DAY else 0


## Gün dakikasında bölgenin hâli (saf; K20): 06:40–19:30 gündüz, öbürü gece.
static func day_state_at(minute: float, p_day_from: float = 400.0, p_night_from: float = 1170.0) -> StringName:
	var m := fposmod(minute, DAY_MIN)
	return DAY if m >= p_day_from and m < p_night_from else NIGHT


## Kurulum: veri ve saat. Kişiler, nöbetçiler ve kalabalık kurulur (kalabalığın yerleşimi tohumludur).
func setup(p_data: Dictionary, p_clock: GameClock = null) -> void:
	data = p_data
	clock = p_clock
	walk_speed = float(data.get("walk_speed", 1.4))
	hurry = float(data.get("hurry", 1.5))
	snap_m = float(data.get("snap_m", 60.0))
	day_from = GameClock.parse_hhmm(data.get("day_from", "06:40"))
	night_from = GameClock.parse_hhmm(data.get("night_from", "19:30"))
	places.clear()
	var raw_places: Dictionary = data.get("places", {})
	for id: Variant in raw_places:
		places[str(id)] = Schedule.vec2(raw_places[id])
	routes.clear()
	var raw_routes: Dictionary = data.get("routes", {})
	for id: Variant in raw_routes:
		var pts := PackedVector2Array()
		for node: Variant in raw_routes[id]:
			pts.append(place(node))
		routes[str(id)] = pts
	people.clear()
	people_ids = PackedStringArray()
	var raw_people: Dictionary = data.get("people", {})
	for id: Variant in raw_people:
		var rec: Dictionary = (raw_people[id] as Dictionary).duplicate()
		rec["id"] = str(id)
		rec["look"] = str(rec.get("look", id))
		_add_person(rec)
	_add_watch(data.get("watch", {}))
	crowd = []
	var groups: Dictionary = data.get("groups", {})
	for gid: Variant in groups:
		var spec: Dictionary = (groups[gid] as Dictionary).duplicate()
		spec["id"] = str(gid)
		crowd.append_array(CrowdPlan.program(spec, places, routes, walk_speed))
	_timelines.clear()
	_states.clear()
	day_state = &""


## Yerin noktası: kimlik, [x, z] ya da Vector2 (bilinmeyen kimlik (0, 0)).
func place(value: Variant) -> Vector2:
	if value is String or value is StringName:
		return places.get(str(value), Vector2.ZERO)
	return Schedule.vec2(value)


## Oturumun adımı (her kare): saatin dakikasında herkesin planı; gündüz ve gece hâlinin değişimi.
func step(_dt: float) -> void:
	if clock == null:
		return
	var now := clock.abs_minute()
	for id in people_ids:
		_states[id] = plan(id, now)
	var state := Schedule.day_state_at(clock.minute, day_from, night_from)
	if state != day_state:
		day_state = state
		day_state_changed.emit(state)


## Kişinin son adımdaki durumu (adım atılmadıysa şimdiki plan).
func state_of(id: String) -> Dictionary:
	if _states.has(id):
		return _states[id]
	return plan(id, clock.abs_minute()) if clock else {}


## Kişinin o andaki planı (saf; mutlak oyun dakikası): {id, pos (Vector2), yaw, job, place, moving, speed (oyun dakikasında m),
## visible, kind ("stay", "walk", "absent"), until (bu hâlin bitişi, mutlak dk)}.
func plan(id: String, abs_min: float) -> Dictionary:
	var rec: Dictionary = people.get(id, {})
	if rec.is_empty():
		return {}
	var day := int(floor(abs_min / DAY_MIN))
	var tl := _timeline(id, day)
	if tl.is_empty() or abs_min < float(tl[0]["t0"]):
		tl = _timeline(id, day - 1)
	for seg: Dictionary in tl:
		if abs_min >= float(seg["t0"]) and abs_min < float(seg["t1"]):
			return _eval(id, seg, abs_min)
	# Çizelgenin dışı (veri boşluğu): son bilinen yerde.
	if not tl.is_empty():
		return _eval(id, tl[tl.size() - 1], float(tl[tl.size() - 1]["t1"]) - 0.0001)
	return {"id": id, "pos": Vector2.ZERO, "yaw": 0.0, "job": "away", "place": "", "moving": false, "speed": 0.0, "visible": false,
		"kind": "absent", "until": abs_min + DAY_MIN}


## Çizelgeleri unutur (yol değişince: navmesh hazır olunca, yeni yapı): kişi verilirse yalnız onunki, yoksa herkesinki. Sonraki plan yeniden
## kurar (yürüyüşün yolu ve süresi yeni yoldan).
func invalidate(id: String = "") -> void:
	if id.is_empty():
		_timelines.clear()
		_states.clear()
	else:
		_timelines.erase(id)


## Kalabalığın i. kişisinin o gün dakikasındaki hâli (CrowdPlan.program_pose).
func crowd_pose(i: int, minute: float) -> Dictionary:
	return CrowdPlan.program_pose(crowd[i], minute) if i >= 0 and i < crowd.size() else {}


## Kişi o gün var mı (kişinin «days»ı; genel gün 0)?
func present_on(id: String, day_n: int) -> bool:
	var rec: Dictionary = people.get(id, {})
	if rec.is_empty():
		return false
	var days: Variant = rec.get("days")
	if not days is Array:
		return true
	return (days as Array).has(Schedule.story_day(day_n)) or (days as Array).has(float(Schedule.story_day(day_n)))


## Bir oyun dakikasında yürünen yol (m; olağan saatte 1 oyun dk = 2,5 sn).
func metres_per_minute() -> float:
	return walk_speed * GameClock.SEC_PER_MIN


## Verinin denetimi (saf; sınama): bloklar günü boşluksuz örter (gün başı ile ertesi günün başı arasında), yerler ve yollar vardır, işler
## bilinir, yürüyüşler bloğuna sığar (sığmayan bildirilir). Döner: sorunlar.
func validate() -> PackedStringArray:
	var out := PackedStringArray()
	for id in people_ids:
		var rec: Dictionary = people[id]
		var variants := {"0": rec.get("blocks", [])}
		var special: Dictionary = rec.get("special", {})
		for k: Variant in special:
			variants[str(k)] = special[k]
		for key: Variant in variants:
			var blocks := _blocks_abs(variants[key], 0)
			if blocks.is_empty():
				out.append("%s (%s): blok yok" % [id, key])
				continue
			var total := 0.0
			for i in blocks.size():
				var b: Dictionary = blocks[i]
				total += float(b["to"]) - float(b["from"])
				if i > 0 and absf(float(blocks[i - 1]["to"]) - float(b["from"])) > 0.01:
					out.append("%s (%s): %s bloğu öncekine bitişik değil" % [id, key, GameClock.hhmm(float(b["from"]))])
				if not JOBS.has(str(b["job"])):
					out.append("%s (%s): bilinmeyen iş %s" % [id, key, b["job"]])
				var at: Variant = b["at"]
				if (at is String) and str(at) != "@post" and not places.has(str(at)):
					out.append("%s (%s): bilinmeyen yer %s" % [id, key, at])
				if not str(b.get("route", "")).is_empty() and not routes.has(str(b["route"])):
					out.append("%s (%s): bilinmeyen yol %s" % [id, key, b["route"]])
				if str(b["job"]) == "carry" and not places.has(str(b.get("with", ""))):
					out.append("%s (%s): taşımanın ikinci yeri yok" % [id, key])
			if absf(total - DAY_MIN) > 0.01:
				out.append("%s (%s): bloklar %.1f dk örtüyor (1.440 olmalı)" % [id, key, total])
			if absf(float(blocks[blocks.size() - 1]["to"]) - float(blocks[0]["from"]) - DAY_MIN) > 0.01:
				out.append("%s (%s): son blok ertesi günün ilk bloğuna bitişik değil" % [id, key])
	return out


# --- Kişiler ----------------------------------------------------------------------------------------------------------------

func _add_person(rec: Dictionary) -> void:
	var id := str(rec["id"])
	people[id] = rec
	people_ids.append(id)


## Gece nöbeti: dokuz ateşin nöbetçisi (gece yerinde, gündüz Nöbet Yurdu'nda) ve gündüzün üç nöbeti.
func _add_watch(watch: Dictionary) -> void:
	if watch.is_empty():
		return
	var offset := float(watch.get("post_offset", 2.2))
	for post: Dictionary in watch.get("posts", []):
		var fire := Schedule.vec2(post.get("fire", [0.0, 0.0]))
		var out_dir := (fire - CENTER).normalized() if fire.length() > 0.01 else Vector2.UP
		var at := fire + out_dir * offset
		var id := "guard_%s" % str(post.get("id", ""))
		_add_person({"id": id, "tier": "crowd", "role": str(watch.get("role", "guard")), "look": "kislak:guard:%s" % str(post.get("guard", id)),
			"blocks": watch.get("night", []), "post": at, "post_yaw": atan2(out_dir.x, out_dir.y), "watch_fire": fire})
	for post: Dictionary in watch.get("day_posts", []):
		var at := place(post.get("at", [0.0, 0.0]))
		var out_dir := (at - CENTER).normalized() if at.length() > 0.01 else Vector2.UP
		var id := "guard_%s" % str(post.get("id", ""))
		_add_person({"id": id, "tier": "crowd", "role": str(watch.get("role", "guard")), "look": "kislak:guard:%s" % id,
			"blocks": watch.get("day", []), "post": at, "post_yaw": atan2(out_dir.x, out_dir.y)})


# --- Zaman çizelgesi ------------------------------------------------------------------------------------------------------

## Kişinin o günkü blokları (hikâye gününün özeli ya da genel; kişinin günü değilse boş).
func _day_blocks(id: String, day: int) -> Array:
	var rec: Dictionary = people[id]
	if not present_on(id, day):
		return []
	var special: Dictionary = rec.get("special", {})
	var key := str(Schedule.story_day(day))
	return special.get(key, rec.get("blocks", []))


## Blokları mutlak dakikaya çevirir: {from, to, at, job, route, depart, with}; gece yarısını geçen blok ertesi güne taşar.
func _blocks_abs(blocks: Array, day: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var base := float(day) * DAY_MIN
	var prev_to := -INF
	for raw: Variant in blocks:
		var b: Dictionary = {}
		if raw is Array:
			var a: Array = raw
			b = {"from": a[0], "to": a[1], "at": a[2], "job": a[3] if a.size() > 3 else "stand"}
		elif raw is Dictionary:
			b = (raw as Dictionary).duplicate()
		else:
			continue
		var f := GameClock.parse_hhmm(b.get("from", "00:00"))
		var t := GameClock.parse_hhmm(b.get("to", "00:00"))
		var from := base + f
		while from < prev_to - 0.001:
			from += DAY_MIN
		var to := base + t
		while to <= from:
			to += DAY_MIN
		b["from"] = from
		b["to"] = to
		b["job"] = str(b.get("job", "stand"))
		prev_to = to
		out.append(b)
	return out


## O günün çizelgesi (önbellekli): [{t0, t1, kind: stay|walk|absent, at, path, length, job, place, yaw, with}], gün başından
## ertesi günün başına.
func _timeline(id: String, day: int) -> Array:
	var per: Dictionary = _timelines.get(id, {})
	if per.has(day):
		return per[day]
	var blocks := _blocks_abs(_day_blocks(id, day), day)
	var segs: Array = []
	if blocks.is_empty():
		var start := float(day) * DAY_MIN + day_from
		segs.append({"t0": start, "t1": start + DAY_MIN, "kind": "absent", "at": Vector2.ZERO, "job": "away", "place": "", "yaw": 0.0})
	else:
		var next_blocks := _blocks_abs(_day_blocks(id, day + 1), day + 1)
		var day_end := float(blocks[0]["from"]) + DAY_MIN
		var next_first: Dictionary = next_blocks[0] if not next_blocks.is_empty() else {}
		var t := float(blocks[0]["from"])
		for i in blocks.size():
			var b: Dictionary = blocks[i]
			var nb: Dictionary = blocks[i + 1] if i + 1 < blocks.size() else next_first
			var here := _at(id, b)
			var stay := {"kind": "stay", "at": here, "job": str(b["job"]), "place": str(b["at"]), "yaw": _face(id, b, here),
				"with": place(b.get("with", "")) if b.has("with") else Vector2.INF, "route": str(b.get("route", "")),
				"from": float(b["from"]), "to": float(b["to"])}
			if nb.is_empty():
				# Ertesi gün kişi yok: günün sonuna dek bloğunda.
				stay["t0"] = t
				stay["t1"] = maxf(day_end, t + 0.001)
				segs.append(stay)
				break
			var there := _at(id, nb)
			# «cart» bloğunun route'u bloğun içindeki çevrimdir (_eval), oraya varışın yolu değil: kişi çevrime yürüyerek gitmez.
			var path := _path(here, there, "" if str(nb["job"]) == "cart" else str(nb.get("route", "")))
			var length := CrowdPlan.polyline_length(path)
			var walk := length / maxf(metres_per_minute(), 0.01) if length > 0.05 else 0.0
			var nb_from := float(nb["from"]) if i + 1 < blocks.size() else day_end
			var depart := nb_from if bool(nb.get("depart", false)) else maxf(t, nb_from - walk)
			if depart > t + 0.0001:
				stay["t0"] = t
				stay["t1"] = depart
				segs.append(stay)
			if walk > 0.0:
				segs.append({"t0": depart, "t1": depart + walk, "kind": "walk", "path": path, "length": length, "job": str(nb["job"]),
					"place": str(nb["at"]), "at": there, "yaw": _face(id, nb, there)})
			t = depart + walk
		# Gün başının eksiği (geç varış ertesi günün başını aşarsa): çizelge ertesi günün başında kesilir.
		if not segs.is_empty() and float(segs[segs.size() - 1]["t1"]) < day_end:
			segs[segs.size() - 1]["t1"] = day_end
	per[day] = segs
	_timelines[id] = per
	# Eski günler bırakılır (oyun ileri gider).
	for d: Variant in per.keys():
		if int(d) < day - 2:
			per.erase(d)
	return segs


## Bloğun yeri: nöbetçinin «@post»u kendi yeri, öbürü yer kimliği ya da [x, z].
func _at(id: String, b: Dictionary) -> Vector2:
	var at: Variant = b.get("at", "")
	if str(at) == "@post":
		return (people[id] as Dictionary).get("post", Vector2.ZERO)
	return place(at)


## Bloğun bakışı: nöbet yerinde dışarı, verilen «face»e, öbür yerde Ulu Ocak'a (çok yakınsa dışarı).
func _face(id: String, b: Dictionary, here: Vector2) -> float:
	if str(b.get("at", "")) == "@post":
		return float((people[id] as Dictionary).get("post_yaw", 0.0))
	if b.has("face"):
		var f := place(b["face"])
		return atan2(f.x - here.x, f.y - here.y)
	var to_c := CENTER - here
	if to_c.length() < 3.0:
		to_c = here - CENTER if here.length() > 0.01 else Vector2(0.0, 1.0)
	return atan2(to_c.x, to_c.y)


## İki yer arasındaki yol: «route» verilmişse o yolun düğümleri (yakın ucundan), yoksa path_provider ya da düz çizgi.
func _path(from: Vector2, to: Vector2, route: String) -> PackedVector2Array:
	var path := PackedVector2Array([from])
	if not route.is_empty() and routes.has(route):
		var nodes: PackedVector2Array = routes[route]
		if not nodes.is_empty() and from.distance_squared_to(nodes[0]) > from.distance_squared_to(nodes[nodes.size() - 1]):
			nodes = nodes.duplicate()
			nodes.reverse()
		for p in nodes:
			if p.distance_squared_to(path[path.size() - 1]) > 0.01:
				path.append(p)
		if to.distance_squared_to(path[path.size() - 1]) > 0.01:
			path.append(to)
		return path
	if path_provider.is_valid():
		var got: Variant = path_provider.call(from, to)
		if got is PackedVector2Array and (got as PackedVector2Array).size() >= 2:
			return got
	path.append(to)
	return path


## Parçanın o andaki değeri.
func _eval(id: String, seg: Dictionary, abs_min: float) -> Dictionary:
	var kind := str(seg["kind"])
	var job := str(seg.get("job", "stand"))
	var out := {"id": id, "job": job, "place": str(seg.get("place", "")), "kind": kind, "until": float(seg["t1"]), "moving": false,
		"speed": 0.0, "yaw": float(seg.get("yaw", 0.0)), "pos": seg.get("at", Vector2.ZERO), "visible": true}
	match kind:
		"absent":
			out["visible"] = false
		"walk":
			var span := maxf(float(seg["t1"]) - float(seg["t0"]), 0.0001)
			var walked := clampf((abs_min - float(seg["t0"])) / span, 0.0, 1.0) * float(seg["length"])
			var on := CrowdPlan.point_on(seg["path"], walked)
			out["pos"] = on["xz"]
			out["yaw"] = on["yaw"]
			out["moving"] = true
			out["speed"] = metres_per_minute()
			out["walked"] = walked
		"stay":
			if job == "carry" and (seg.get("with", Vector2.INF) as Vector2) != Vector2.INF:
				_carry(out, seg, abs_min)
			elif job == "cart" and routes.has(str(seg.get("route", ""))):
				# Kantu'nun çevrimi: kişi arabadadır (araba E'nindir), yeri çevrimin üstündedir; görünmez.
				var loop: PackedVector2Array = routes[str(seg["route"])]
				var frac := clampf((abs_min - float(seg["from"])) / maxf(float(seg["to"]) - float(seg["from"]), 0.001), 0.0, 1.0)
				var on := CrowdPlan.point_on(loop, frac * CrowdPlan.polyline_length(loop))
				out["pos"] = on["xz"]
				out["yaw"] = on["yaw"]
				out["visible"] = false
			elif HIDDEN_JOBS.has(job):
				out["visible"] = false
	return out


## Taşıma: bloğun yeri ile «with» arasında gidip gelir, uçlarda CARRY_PAUSE dakika bekler. Son tam gidiş-dönüşten sonra kalan sürede
## bloğun yerinde bekler: taşıma bloğun yerinde başlar ve biter (sonraki yürüyüş oradan çıkar, konum sıçramaz).
func _carry(out: Dictionary, seg: Dictionary, abs_min: float) -> void:
	var a: Vector2 = seg["at"]
	var b: Vector2 = seg["with"]
	var length := a.distance_to(b)
	var leg := length / maxf(metres_per_minute(), 0.01)
	var cycle := 2.0 * (leg + CARRY_PAUSE)
	var elapsed := abs_min - float(seg["t0"])
	var full := floorf((float(seg["t1"]) - float(seg["t0"])) / cycle) * cycle
	if elapsed >= full:
		return
	var t := fposmod(elapsed, cycle)
	var from := a
	var to := b
	if t >= leg + CARRY_PAUSE:
		t -= leg + CARRY_PAUSE
		from = b
		to = a
	if t < leg:
		var dir := (to - from) / maxf(length, 0.0001)
		out["pos"] = from + dir * metres_per_minute() * t
		out["yaw"] = atan2(dir.x, dir.y)
		out["moving"] = true
		out["speed"] = metres_per_minute()
	else:
		out["pos"] = to
		out["yaw"] = atan2(from.x - to.x, from.y - to.y)


static func vec2(v: Variant) -> Vector2:
	if v is Vector2:
		return v
	if v is Array and (v as Array).size() >= 2:
		return Vector2(float(v[0]), float(v[1]))
	return Vector2.ZERO
