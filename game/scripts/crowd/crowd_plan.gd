class_name CrowdPlan
extends RefCounted
## Dailin kalabalığının planı (saf; story.md §5 «uzaktaki sayım kalabalığı», army.md §7.1 T3 kart; CrowdCards çizer): kim nerede durur,
## nereden ve ne zaman gelir. Düzen layout.json "childhood.crowd"tadır: öbekler (dikdörtgen ya da daire; kaç kişi, kime bakar, nereden gelir),
## açık tutulacak yollar (keep_clear: atlıların yolu, sürünün rotası, çocukların yeri) ve toplanma saatleri. Kişinin hâli yalnız oyunun
## dakikasından çıkar (pose_at): erken gelenler (early payı) baştan yerindedir; ötekiler gather.from–gather.to arasında bir dakikada yerine
## varır, kendi hızıyla (walk_speed, oyunun olağan saatinde; 1 oyun dk 2,5 sn) çıkış noktasından (origins: yurtlar, dünyanın kıyısı; via:
## dolanma noktaları) yürüyerek gelir. Saat görünür biçimde hızlanınca (GameClock.begin_lapse) plan da o hızla akar; kişi ise planın gerisinde
## kalır ve kendi hızının HURRY katıyla, en çok oyuncunun koşusuyla yetişir (chase; E20, PaceLimit): kalabalık ışınlanmaz, koşmaz. Yola çıkan
## kişi saat dursa da (bloklayan söz) kendi hızıyla yürür, varınca durur. Gerçek yolu CrowdCards tutar.
## Yerleşim tohumludur (seed): aynı düzen aynı kalabalığı verir; kişiler birbirine min_gap'ten, engellere (blockers: Vector3(x, z, yarıçap))
## yarıçapları kadar yaklaşmaz.
##   var plan := CrowdPlan.build(layout["childhood"]["crowd"], blockers)
##   var pose := CrowdPlan.pose_at(plan[i], minute)     # {xz, yaw, state, walked, presence}
##   CrowdPlan.counts(plan, 660.0)                      # {standing, walking, absent}
##   walked = CrowdPlan.chase(walked, CrowdPlan.planned_walked(p, minute), p["length"], CrowdPlan.own_speed(p), 3.6, CrowdPlan.HURRY, delta)
##
## Günlük program (I. Perde'nin kalabalığı; Yol Haritası npc-schedules, crowd-tiers; Schedule kurar, npcs.json «groups»): öbeğin her kişisi
## gün içinde duraklardan geçer (program): durak {varış ya da çıkış saati aralığı, yer (halka, daire, dikdörtgen, öbek ortası, ev kapısı, yer
## kimliği), duruş (ayakta, oturur, iş, içeride), pay (share: durağa uğrayan kişilerin oranı)}; durakların arası yürüyüştür (yerine vaktinde
## varır ya da «depart» saatinde çıkar). Esir Yolu'nun kolu (route) iki sıra, sıra arası row_gap_m, şeritten lane_m: önde ve arkada iki
## nöbetçi (escort). program_pose(kişi, gün dakikası) kişinin o anki hâlidir (saf, döngüsel gün).
## Kademe (army.md §7.1, godot.md §4.5): tier_px kişinin ekrandaki boyudur (2,75 × H / (2 d tan(fov/2)); Godot'nun görüş açısı ve pencerenin
## yüksekliğiyle), select_tiers eşiklerle (T0 ≥80 px, T1 ve T2 ≥28 px; ±%15 gecikme payı), tavanlarla (T0 adlı önce, T1 en yakın 96, T2 300,
## T3 12.000) ve kare başına takas sınırıyla kademeleri seçer.
##   var people := CrowdPlan.program(groups["market"], places, routes, 1.4)
##   var pose := CrowdPlan.program_pose(people[i], 640.0)   # {xz, yaw, state, moving, presence, leg}
##   var tiers := CrowdPlan.select_tiers(px, visible, priority, can_full, current, [3, 96, 300, 12000], 8, false)

enum State { ABSENT, WALK, STAND, SIT, WORK }

## Kademeler (CrowdField çizer): T0 tam kişi (CharacterAvatar), T1 kukla, T2 kaba kukla, T3 kart; NONE yok (içeride, gelmedi).
const T0 := 0
const T1 := 1
const T2 := 2
const T3 := 3
const NONE := 255
## Kademe eşikleri (px; army.md §7.1: tam kişi ≥80, kukla ≥28, altı kart) ve gecikme payı.
const T0_PX := 80.0
const PUPPET_PX := 28.0
const HYSTERESIS := 0.15
## Ekran boyunun ölçüsü (m): army.md §7.1'in formülü atlı kişinin boyuyla kurulmuştur (eşikler bu ölçüyle px'tir).
const PX_HEIGHT_M := 2.75
## Programın varsayılanları: yerleşim denemesi, kişiler arası en küçük aralık (m), bakışın sapması (derece), ev kapısının yana kayması (m).
const PROGRAM_TRIES := 40
const PROGRAM_GAP := 1.0
const PROGRAM_SPREAD_DEG := 24.0
const HOME_SPREAD := 1.2
## Şeridin yolun uçlarında sönme boyu ve yönünü veren kirişin yarısı (m).
const LANE_FADE_M := 4.0
const LANE_CHORD_M := 2.5
## Kolun ve öbeğin sırası: bir sıranın çıkış farkı (oyun dk) sıra aralığından ve yürüyüş hızından çıkar.
const DAY_MIN := 1440.0

## Yerleşimde deneme sayısı (kişi başına) ve kişinin görünmeye başladığı yürüyüş (m; ilk metrelerde belirerek gelir).
const TRIES := 40
const FADE_IN_M := 2.5
## Oyun dakikasında yürüyüşün metre çarpanı (1 oyun dk = 2,5 gerçek sn).
const SEC_PER_MIN := 2.5
## Planın gerisinde kalan kişinin yetişme hızı: kendi hızının katı (E20; en çok oyuncunun koşusu). Kartın yürüyüş karesi yolundan çıkar:
## 1,5 kat ayağı kaydırmaz, sıkça adımlanan bir yürüyüştür.
const HURRY := 1.5


## Plan (saf): kişi listesi. Her kişi {group, spot: Vector2, yaw, variant, scale, shade, early, from, to (oyun dk), path: PackedVector2Array,
## length (m), seed (0..1)}.
static func build(spec: Dictionary, blockers: Array[Vector3] = []) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = int(spec.get("seed", 228))
	var gather: Dictionary = spec.get("gather", {})
	var from := GameClock.parse_hhmm(gather.get("from", "09:50"))
	var to := GameClock.parse_hhmm(gather.get("to", "10:55"))
	var early := float(gather.get("early", 0.2))
	var speed: Array = spec.get("walk_speed", [1.1, 1.45])
	var scale: Array = spec.get("scale", [0.95, 1.05])
	var gap := float(spec.get("min_gap", 0.95))
	var weights: Array = spec.get("variants", [1.0])
	var clear: Array = spec.get("keep_clear", [])
	var groups: Array = spec.get("groups", [])
	var placed := PackedVector2Array()
	for g in groups.size():
		var group: Dictionary = groups[g]
		var want := int(group.get("count", 0))
		for n in want:
			var spot := Vector2.INF
			for attempt in TRIES:
				var p := _sample(group, rng)
				if _blocked(p, blockers, clear) or _crowded(p, placed, gap):
					continue
				spot = p
				break
			if spot == Vector2.INF:
				continue
			placed.append(spot)
			var face := _vec2(group.get("face", [spot.x, spot.y - 1.0]))
			var spread := deg_to_rad(float(group.get("face_spread_deg", 22.0)))
			var to_face := face - spot
			var yaw := atan2(to_face.x, to_face.y) + rng.randf_range(-spread, spread)
			var is_early := rng.randf() < float(group.get("early", early))
			var path := _path_to(group, spot, rng)
			var length := polyline_length(path)
			var v := rng.randf_range(float(speed[0]), float(speed[1]))
			var arrive := lerpf(from, to, rng.randf())
			var walk_min := length / maxf(v * SEC_PER_MIN, 0.01)
			out.append({
				"group": str(group.get("id", str(g))),
				"spot": spot,
				"yaw": yaw,
				"variant": _pick(weights, rng.randf()),
				"scale": rng.randf_range(float(scale[0]), float(scale[1])),
				"shade": rng.randf(),
				"early": is_early,
				"from": arrive - walk_min,
				"to": arrive,
				"path": path,
				"length": length,
				"seed": rng.randf(),
			})
	return out


## Kişinin o dakikadaki hâli (saf): {xz, yaw, state, walked (m; yürüyüşte), presence (0..1; belirerek gelir)}.
static func pose_at(p: Dictionary, minute: float) -> Dictionary:
	var spot: Vector2 = p["spot"]
	if bool(p.get("early", false)) or minute >= float(p["to"]):
		return {"xz": spot, "yaw": float(p["yaw"]), "state": State.STAND, "walked": 0.0, "presence": 1.0}
	if minute <= float(p["from"]):
		return {"xz": spot, "yaw": float(p["yaw"]), "state": State.ABSENT, "walked": 0.0, "presence": 0.0}
	var t := clampf((minute - float(p["from"])) / maxf(float(p["to"]) - float(p["from"]), 0.0001), 0.0, 1.0)
	var length := float(p["length"])
	var walked := t * length
	var at := point_on(p["path"], walked)
	return {"xz": at["xz"], "yaw": float(at["yaw"]), "state": State.WALK, "walked": walked, "presence": clampf(walked / FADE_IN_M, 0.0, 1.0)}


## Kişinin kendi yürüyüş hızı (saf; m/sn): planın yolu ve süresi (oyunun olağan saatinde 1 oyun dk = 2,5 sn).
static func own_speed(p: Dictionary) -> float:
	var span := (float(p["to"]) - float(p["from"])) * SEC_PER_MIN
	return float(p["length"]) / span if span > 0.0001 else 0.0


## Planın o dakikada yürünmüş saydığı yol (saf; m): erken gelen ve varan yolun sonunda, çıkmayan 0.
static func planned_walked(p: Dictionary, minute: float) -> float:
	var length := float(p["length"])
	if bool(p.get("early", false)) or minute >= float(p["to"]):
		return length
	if minute <= float(p["from"]):
		return 0.0
	return clampf((minute - float(p["from"])) / maxf(float(p["to"]) - float(p["from"]), 0.0001), 0.0, 1.0) * length


## Kişinin gerçek yolu bir adımda (saf; E20 hız sınırı): planın gerisinde kalan kişi (saat görünür biçimde akarken) kendi hızının hurry katıyla,
## en çok cap ile yetişir; yola çıkan kişi plan dursa da (saat durunca) kendi hızıyla yürür, yolun sonunda durur. Işınlanmaz, geri gitmez,
## yola çıkmayan yerinde kalır. walked: şimdiye dek yürüdüğü (m), planned: planın yolu (planned_walked), own: kendi hızı (m/sn).
static func chase(walked: float, planned: float, length: float, own: float, cap: float, hurry: float, delta: float) -> float:
	if delta <= 0.0 or walked >= length:
		return minf(walked, length)
	if walked <= 0.0 and planned <= 0.0:
		return 0.0
	var v := own * (hurry if planned > walked + own * delta else 1.0)
	return minf(walked + clampf(v, 0.0, maxf(cap, 0.0)) * delta, length)


## Planın o dakikadaki sayıları (saf).
static func counts(plan: Array, minute: float) -> Dictionary:
	var out := {"standing": 0, "walking": 0, "absent": 0}
	for p: Dictionary in plan:
		match int(pose_at(p, minute)["state"]):
			State.STAND:
				out["standing"] += 1
			State.WALK:
				out["walking"] += 1
			_:
				out["absent"] += 1
	return out


## Yerlerin zemin yüksekliği (saf; iş parçacığında çağrılabilir: shape yalnız okunur).
static func heights(plan: Array, shape: RefCounted) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(plan.size())
	for i in plan.size():
		var spot: Vector2 = plan[i]["spot"]
		out[i] = float(shape.call(&"height_at", spot.x, spot.y)) if shape else 0.0
	return out


## Bütün kişilerin yollarıyla kapladığı kutu (saf): kart gölgelendiricide büyür, kutu boyu ve payı kapsar.
static func bounds(plan: Array, shape: RefCounted) -> AABB:
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	for p: Dictionary in plan:
		for q: Vector2 in (p["path"] as PackedVector2Array):
			var y := float(shape.call(&"height_at", q.x, q.y)) if shape else 0.0
			lo = lo.min(Vector3(q.x, y, q.y))
			hi = hi.max(Vector3(q.x, y, q.y))
	if lo.x == INF:
		return AABB(Vector3(-1, -1, -1), Vector3(2, 2, 2))
	var pad := 3.5
	return AABB(lo - Vector3(pad, pad, pad), hi - lo + Vector3(pad, pad + 3.0, pad) * 2.0)


## Çoklu çizginin uzunluğu (saf).
static func polyline_length(path: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, path.size()):
		total += path[i - 1].distance_to(path[i])
	return total


## Çoklu çizgide d metredeki nokta ve yön (saf): {xz, yaw}.
static func point_on(path: PackedVector2Array, d: float) -> Dictionary:
	if path.size() < 2:
		return {"xz": path[0] if path.size() == 1 else Vector2.ZERO, "yaw": 0.0}
	var left := maxf(d, 0.0)
	for i in range(1, path.size()):
		var seg := path[i] - path[i - 1]
		var l := seg.length()
		if left <= l or i == path.size() - 1:
			var dir := seg / maxf(l, 0.0001)
			return {"xz": path[i - 1] + dir * minf(left, l), "yaw": atan2(dir.x, dir.y)}
		left -= l
	return {"xz": path[path.size() - 1], "yaw": 0.0}


## Yol: çıkış noktalarından biri (yana origin_spread kadar kayık), varsa dolanma noktaları, yer.
static func _path_to(group: Dictionary, spot: Vector2, rng: RandomNumberGenerator) -> PackedVector2Array:
	var origins: Array = group.get("origins", [])
	var path := PackedVector2Array()
	if origins.is_empty():
		path.append(spot)
		path.append(spot)
		return path
	var o: Variant = origins[rng.randi_range(0, origins.size() - 1)]
	var at := _vec2((o as Dictionary).get("at", [0.0, 0.0]) if o is Dictionary else o)
	var spread := float(group.get("origin_spread", 4.0))
	var dir := (spot - at).normalized()
	at += Vector2(-dir.y, dir.x) * rng.randf_range(-spread, spread)
	path.append(at)
	if o is Dictionary:
		for v: Variant in (o as Dictionary).get("via", []):
			path.append(_vec2(v) + Vector2(rng.randf_range(-1.5, 1.5), rng.randf_range(-1.5, 1.5)))
	path.append(spot)
	return path


## Öbeğin içinde bir nokta: rect {center, size, yaw_deg} ya da disc {center, radius}.
static func _sample(group: Dictionary, rng: RandomNumberGenerator) -> Vector2:
	if group.get("disc") is Dictionary:
		var disc: Dictionary = group["disc"]
		var r := float(disc.get("radius", 4.0)) * sqrt(rng.randf())
		return _vec2(disc.get("center", [0.0, 0.0])) + Vector2.from_angle(rng.randf() * TAU) * r
	var rect: Dictionary = group.get("rect", {})
	var size := _vec2(rect.get("size", [4.0, 4.0]))
	var local := Vector2(rng.randf_range(-0.5, 0.5) * size.x, rng.randf_range(-0.5, 0.5) * size.y)
	return _vec2(rect.get("center", [0.0, 0.0])) + local.rotated(-deg_to_rad(float(rect.get("yaw_deg", 0.0))))


static func _blocked(p: Vector2, blockers: Array[Vector3], clear: Array) -> bool:
	for b in blockers:
		if p.distance_to(Vector2(b.x, b.y)) < b.z:
			return true
	for c: Variant in clear:
		var d: Dictionary = c
		var a := _vec2(d.get("a", [0.0, 0.0]))
		var e := _vec2(d.get("b", d.get("a", [0.0, 0.0])))
		if _segment_distance(p, a, e) < float(d.get("r", 2.0)):
			return true
	return false


static func _crowded(p: Vector2, placed: PackedVector2Array, gap: float) -> bool:
	for q in placed:
		if p.distance_squared_to(q) < gap * gap:
			return true
	return false


static func _segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.000001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


static func _pick(weights: Array, u: float) -> int:
	var total := 0.0
	for w: Variant in weights:
		total += float(w)
	var acc := 0.0
	for i in weights.size():
		acc += float(weights[i]) / maxf(total, 0.0001)
		if u <= acc:
			return i
	return weights.size() - 1


static func _vec2(v: Variant) -> Vector2:
	if v is Vector2:
		return v
	if v is Array and (v as Array).size() >= 2:
		return Vector2(float(v[0]), float(v[1]))
	return Vector2.ZERO


# --- Günlük program (I. Perde'nin kalabalığı) ----------------------------------------------------------------------------

## Öbeğin programı (saf): kişiler ve durakları. spec: npcs.json «groups»un kaydı {id, count, role, seed, homes, stops | route...};
## places: yer kimliği → Vector2; routes: yol kimliği → PackedVector2Array; walk_speed (m/sn). Kişi: {group, index, role, seed (görünüşün
## tohumu, Folk.make), home, lane (m), stops: [{spot, yaw, pose (State), depart, arrive (gün dakikası), path, length}]}.
static func program(spec: Dictionary, places: Dictionary = {}, routes: Dictionary = {}, walk_speed: float = 1.4) -> Array[Dictionary]:
	if spec.has("route"):
		return CrowdPlan._program_column(spec, places, routes, walk_speed)
	var out: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = int(spec.get("seed", 1))
	var gid := str(spec.get("id", "group"))
	var count := int(spec.get("count", 0))
	var homes: Array = spec.get("homes", [[0.0, 0.0]])
	var stop_specs: Array = spec.get("stops", [])
	var gap := float(spec.get("min_gap", PROGRAM_GAP))
	var clear: Array = spec.get("keep_clear", [])
	var blockers: Array[Vector3] = []
	for b: Variant in spec.get("blockers", []):
		if b is Array and (b as Array).size() >= 3:
			blockers.append(Vector3(float(b[0]), float(b[1]), float(b[2])))
	var mpm := walk_speed * SEC_PER_MIN
	# Durak başına öbek ortaları ve yerleşmiş noktalar (aralık durak içinde aranır).
	var clusters: Array = []
	var placed: Array = []
	for s in stop_specs.size():
		var sspec: Dictionary = stop_specs[s]
		var centers := PackedVector2Array()
		var shape: Variant = sspec.get("spot")
		var n_clusters := int(shape.get("clusters", 0)) if shape is Dictionary else 0
		for c in n_clusters:
			var p := Vector2.INF
			for attempt in PROGRAM_TRIES:
				var q := CrowdPlan._sample_shape(shape, rng)
				if _blocked(q, blockers, clear) or _crowded(q, centers, float(shape.get("cluster_radius", 1.6)) * 2.4):
					continue
				p = q
				break
			if p != Vector2.INF:
				centers.append(p)
		clusters.append(centers)
		placed.append(PackedVector2Array())
	for i in count:
		var home_v: Variant = homes[i % homes.size()]
		var home := CrowdPlan._vec2(home_v)
		var side := home.normalized().orthogonal() if home.length() > 0.01 else Vector2.RIGHT
		home += side * rng.randf_range(-HOME_SPREAD, HOME_SPREAD)
		var stops: Array[Dictionary] = []
		var first_spot := Vector2.INF
		var first_yaw := 0.0
		for s in stop_specs.size():
			var sspec: Dictionary = stop_specs[s]
			if rng.randf() >= float(sspec.get("share", 1.0)):
				continue
			var shape: Variant = sspec.get("spot", "home")
			var spot := Vector2.INF
			var face := Vector2.INF
			var centers: PackedVector2Array = clusters[s]
			if str(shape) == "home":
				spot = home
			elif str(shape) == "first":
				spot = first_spot if first_spot != Vector2.INF else home
			elif shape is Dictionary:
				var center := Vector2.INF if centers.is_empty() else centers[i % centers.size()]
				var radius := float((shape as Dictionary).get("cluster_radius", 1.6))
				var taken: PackedVector2Array = placed[s]
				for attempt in PROGRAM_TRIES:
					var q := center + Vector2.from_angle(rng.randf() * TAU) * radius * sqrt(rng.randf()) if center != Vector2.INF \
						else CrowdPlan._sample_shape(shape, rng)
					if _blocked(q, blockers, clear) or _crowded(q, taken, gap):
						continue
					spot = q
					break
				if spot == Vector2.INF:
					spot = center if center != Vector2.INF else CrowdPlan._sample_shape(shape, rng)
				taken.append(spot)
				placed[s] = taken
				face = center if center != Vector2.INF else CrowdPlan._shape_center(shape)
			else:
				spot = CrowdPlan._place(shape, places)
			if sspec.has("face"):
				face = CrowdPlan._place(sspec["face"], places)
			var yaw := 0.0
			if face != Vector2.INF and face.distance_to(spot) > 0.2:
				yaw = atan2(face.x - spot.x, face.y - spot.y) + deg_to_rad(rng.randf_range(-PROGRAM_SPREAD_DEG, PROGRAM_SPREAD_DEG))
			else:
				yaw = first_yaw if str(shape) == "first" else rng.randf() * TAU
			var pose := CrowdPlan.pose_of(str(sspec.get("pose", "stand")))
			if pose == State.SIT and rng.randf() < float(sspec.get("stand_share", 0.0)):
				pose = State.STAND
			if first_spot == Vector2.INF:
				first_spot = spot
				first_yaw = yaw
			var stop := {"spot": spot, "yaw": yaw, "pose": pose, "arrive": -1.0, "depart": -1.0}
			if sspec.has("arrive"):
				stop["arrive"] = CrowdPlan._time_in(sspec["arrive"], rng)
			else:
				stop["depart"] = CrowdPlan._time_in(sspec.get("depart", "12:00"), rng)
			stops.append(stop)
		CrowdPlan._link_stops(stops, mpm)
		out.append({"group": gid, "index": i, "role": str(spec.get("role", "townsfolk")), "seed": "%s:%d" % [gid, i],
			"home": home, "lane": 0.0, "stops": stops})
	return out


## Kişinin o gün dakikasındaki hâli (saf; gün döngüseldir): {xz, yaw, state (State), moving, presence (0..1; evden çıkarken ve eve
## girerken ilk ve son FADE_IN_M metrede), leg (durak), walked (m)}.
static func program_pose(p: Dictionary, minute: float) -> Dictionary:
	var stops: Array = p.get("stops", [])
	if stops.is_empty():
		var home := CrowdPlan._vec2(p.get("home", Vector2.ZERO))
		return {"xz": home, "yaw": 0.0, "state": State.ABSENT, "moving": false, "presence": 0.0, "leg": -1, "walked": 0.0}
	var m := fposmod(minute, DAY_MIN)
	var n := stops.size()
	for k in n:
		var s: Dictionary = stops[k]
		var prev: Dictionary = stops[(k - 1 + n) % n]
		var walk := float(s["arrive"]) - float(s["depart"])
		var rel := fposmod(m - float(s["depart"]), DAY_MIN)
		if walk > 0.0001 and rel < walk:
			var length := float(s["length"])
			var walked := rel / walk * length
			var on := CrowdPlan.point_on(s["path"], walked)
			var xz: Vector2 = on["xz"]
			var lane := float(p.get("lane", 0.0))
			if absf(lane) > 0.0001:
				# Şerit yolun uçlarında söner: kişi durağına tam varır, duraktan tam çıkar. Yön kirişten (önünde ve arkasında
				# LANE_CHORD_M): köşede yana kayma sıçramaz.
				var fade := clampf(walked / LANE_FADE_M, 0.0, 1.0) * clampf((length - walked) / LANE_FADE_M, 0.0, 1.0)
				var ahead: Vector2 = CrowdPlan.point_on(s["path"], minf(walked + LANE_CHORD_M, length))["xz"]
				var behind: Vector2 = CrowdPlan.point_on(s["path"], maxf(walked - LANE_CHORD_M, 0.0))["xz"]
				var chord := ahead - behind
				var heading := atan2(chord.x, chord.y) if chord.length_squared() > 0.0001 else float(on["yaw"])
				xz += CrowdPlan._lane_offset(heading, lane * fade)
			var presence := 1.0
			if int(prev["pose"]) == State.ABSENT:
				presence = minf(presence, clampf(walked / FADE_IN_M, 0.0, 1.0))
			if int(s["pose"]) == State.ABSENT:
				presence = minf(presence, clampf((length - walked) / FADE_IN_M, 0.0, 1.0))
			return {"xz": xz, "yaw": float(on["yaw"]), "state": State.WALK, "moving": true, "presence": presence, "leg": k,
				"walked": walked}
	# Durakta: varışından sonraki durağın çıkışına dek.
	var best := 0
	var best_rel := INF
	for k in n:
		var rel := fposmod(m - float(stops[k]["arrive"]), DAY_MIN)
		if rel < best_rel:
			best_rel = rel
			best = k
	var at: Dictionary = stops[best]
	var state := int(at["pose"])
	return {"xz": at["spot"], "yaw": float(at["yaw"]), "state": state, "moving": false, "presence": 0.0 if state == State.ABSENT else 1.0,
		"leg": best, "walked": 0.0}


## Duruşun adı → State (saf): stand, sit, work, inside (görünmez); bilinmeyen ayakta.
static func pose_of(name: String) -> State:
	match name:
		"sit":
			return State.SIT
		"work":
			return State.WORK
		"inside", "away", "absent":
			return State.ABSENT
		_:
			return State.STAND


## Kişinin ekrandaki boyu (px; saf; army.md §7.1): 2,75 × H / (2 d tan(fov/2)); fov dikey görüş açısı (derece), H pencerenin yüksekliği.
## Godot'da K98 kadrajıyla (1920×1080, 36°) 4.570 / d: 57,1 m'de 80 px, 163 m'de 28 px.
static func tier_px(distance: float, fov_deg: float, height_px: float) -> float:
	return PX_HEIGHT_M * height_px / (2.0 * maxf(distance, 0.01) * tan(deg_to_rad(fov_deg) * 0.5))


## Kademeler (saf): px kişinin ekrandaki boyu, visible kadrajda mı (1/0), priority tam kişi sırası (büyük önce: adlı 2, nöbetçi 1, öbür 0),
## can_full tam kişi olabilir mi (1/0; modeli var, yetişkin), current şimdiki kademe (T0…T3, NONE), present var mı (1/0; içerideki ve
## gelmemiş NONE). caps: [T0, T1, T2, T3] tavanları. Eşikler gecikme paylıdır: kademede kalan eşiğin ×(1 − HYSTERESIS)'ına dek kalır, yeni
## giren ×(1 + HYSTERESIS)'ını ister. Seçim en yakından: T0 adlı önce; T1 kadrajdakiler önce, yakından; T1 dolunca T2; altı ve taşanı T3.
## Takas: snap değilse en çok max_swaps kişi kademe değiştirir (önce boşaltan inişler, sonra yakından çıkışlar); boş yer yoksa kişi
## kademesinde bekler. Kaybolan (present 0) takas sayılmaz.
static func select_tiers(px: PackedFloat32Array, visible: PackedByteArray, priority: PackedInt32Array, can_full: PackedByteArray,
		current: PackedByteArray, present: PackedByteArray, caps: Array, max_swaps: int = 8, snap: bool = false) -> PackedByteArray:
	var n := px.size()
	var want := PackedByteArray()
	want.resize(n)
	var band := PackedByteArray()
	band.resize(n)
	var t0_list: Array[int] = []
	var puppet_list: Array[int] = []
	for i in n:
		want[i] = NONE
		if present[i] == 0:
			band[i] = NONE
			continue
		var cur := current[i] if i < current.size() else NONE
		var full_px := T0_PX * ((1.0 - HYSTERESIS) if cur == T0 else (1.0 + HYSTERESIS))
		var puppet_px := PUPPET_PX * ((1.0 - HYSTERESIS) if cur == T1 or cur == T2 or cur == T0 else (1.0 + HYSTERESIS))
		if can_full[i] == 1 and px[i] >= full_px:
			band[i] = T0
			t0_list.append(i)
		elif px[i] >= puppet_px:
			band[i] = T1
			puppet_list.append(i)
		else:
			band[i] = T3
	# T0: adlı önce, sonra yakından; tavanın dışı kukla bandına iner.
	t0_list.sort_custom(func(a: int, b: int) -> bool:
		if priority[a] != priority[b]:
			return priority[a] > priority[b]
		return px[a] > px[b])
	var cap0 := int(caps[0]) if caps.size() > 0 else 0
	for k in t0_list.size():
		var i := t0_list[k]
		if k < cap0:
			want[i] = T0
		else:
			puppet_list.append(i)
	puppet_list.sort_custom(func(a: int, b: int) -> bool:
		if visible[a] != visible[b]:
			return visible[a] > visible[b]
		return px[a] > px[b])
	var cap1 := int(caps[1]) if caps.size() > 1 else 0
	var cap2 := int(caps[2]) if caps.size() > 2 else 0
	for k in puppet_list.size():
		var i := puppet_list[k]
		if k < cap1:
			want[i] = T1
		elif k < cap1 + cap2:
			want[i] = T2
		else:
			want[i] = T3
	var cap3 := int(caps[3]) if caps.size() > 3 else 12000
	var t3 := 0
	for i in n:
		if band[i] == T3 or want[i] == T3:
			if want[i] == NONE:
				want[i] = T3
			if want[i] == T3:
				t3 += 1
				if t3 > cap3:
					want[i] = NONE
	if snap or current.size() != n:
		return want
	# Takas sınırı: önce kademeden çıkanlar (yer açar), sonra yakından girenler; tavan ve takas sayısı korunur.
	var out := current.duplicate()
	var counts := [0, 0, 0, 0]
	for i in n:
		if present[i] == 0:
			out[i] = NONE
		elif out[i] != NONE:
			counts[out[i]] += 1
	var downs: Array[int] = []
	var ups: Array[int] = []
	for i in n:
		if out[i] == want[i] or present[i] == 0:
			continue
		if out[i] != NONE and (want[i] == NONE or want[i] > out[i]):
			downs.append(i)
		else:
			ups.append(i)
	downs.sort_custom(func(a: int, b: int) -> bool: return px[a] < px[b])
	ups.sort_custom(func(a: int, b: int) -> bool: return px[a] > px[b])
	var swaps := 0
	var capv := [cap0, cap1, cap2, cap3]
	for i in downs + ups:
		var to := want[i]
		var appearing := out[i] == NONE
		if not appearing and swaps >= max_swaps:
			continue
		if to != NONE and counts[to] >= capv[to]:
			continue
		if out[i] != NONE:
			counts[out[i]] -= 1
		if to != NONE:
			counts[to] += 1
		out[i] = to
		if not appearing:
			swaps += 1
	return out


## Esir Yolu'nun kolu (saf; program'ın «route» kaydı): sabah çıkış (out.depart; sıra sıra), Demir Diş'te iş, akşam dönüş (back.depart),
## Çukur'da oturuş, gece barınakta; önde ve arkada iki nöbetçi (escort).
static func _program_column(spec: Dictionary, places: Dictionary, routes: Dictionary, walk_speed: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = int(spec.get("seed", 1))
	var gid := str(spec.get("id", "column"))
	var count := int(spec.get("count", 16))
	var rows := maxi(int(spec.get("rows", 2)), 1)
	var row_gap := float(spec.get("row_gap_m", 1.4))
	var lane_m := float(spec.get("lane_m", 0.65))
	var mpm := walk_speed * SEC_PER_MIN
	var row_dt := row_gap / maxf(mpm, 0.01)
	var route: PackedVector2Array = routes.get(str(spec.get("route", "")), PackedVector2Array())
	if route.size() < 2:
		return out
	var homes: Array = spec.get("homes", [[0.0, 0.0]])
	var home0 := CrowdPlan._vec2(homes[0])
	var out_spec: Dictionary = spec.get("out", {})
	var back_spec: Dictionary = spec.get("back", {})
	var t_out := GameClock.parse_hhmm(out_spec.get("depart", "07:00"))
	var t_back := GameClock.parse_hhmm(back_spec.get("depart", "17:00"))
	var night_sit: Array = spec.get("night_sit", ["19:20", "22:30"])
	var t_bed := GameClock.parse_hhmm(night_sit[1])
	# Toplanma: Çukur Kapısı'nın içinde, kapıdan Çukur'a doğru sıra sıra.
	var gate := route[0]
	var inner := CrowdPlan._place(out_spec.get("assemble", "hollow_inner_gate"), places) if places.has("hollow_inner_gate") else gate
	var back_dir := (home0 - inner).normalized() if home0.distance_to(inner) > 0.1 else Vector2.DOWN
	var work_specs: Array = spec.get("work_spots", [])
	var night_shape: Variant = spec.get("night_spot", {"disc": {"center": [home0.x, home0.y], "radius": 8.0}})
	var night_placed := PackedVector2Array()
	var work_placed := PackedVector2Array()
	for i in count:
		var row := i / rows
		var lane := (float(i % rows) - float(rows - 1) * 0.5) * lane_m * 2.0
		var assemble := inner + back_dir * (row_gap * (row + 1)) + CrowdPlan._lane_offset(atan2(-back_dir.x, -back_dir.y), lane)
		# İş yeri: payına göre (Galeri Ağzı, Bakır Damarı, Körük Ocağı).
		var u := rng.randf()
		var acc := 0.0
		var wspec: Dictionary = work_specs[0] if not work_specs.is_empty() else {"disc": {"center": [route[route.size() - 1].x, route[route.size() - 1].y], "radius": 4.0}}
		for w: Dictionary in work_specs:
			acc += float(w.get("share", 1.0))
			if u < acc:
				wspec = w
				break
		var work := CrowdPlan._free_spot(wspec, work_placed, 1.1, rng)
		work_placed.append(work)
		var night := CrowdPlan._free_spot(night_shape, night_placed, 1.1, rng)
		night_placed.append(night)
		var home := home0 + Vector2(rng.randf_range(-2.5, 2.5), rng.randf_range(-1.5, 1.5))
		var cut := CrowdPlan._nearest_index(route, work)
		var out_path := PackedVector2Array([assemble])
		for k in cut + 1:
			out_path.append(route[k])
		out_path.append(work)
		var back_path := PackedVector2Array([work])
		for k in range(cut, -1, -1):
			back_path.append(route[k])
		back_path.append(night)
		out_path = CrowdPlan._no_u_turns(out_path)
		back_path = CrowdPlan._no_u_turns(back_path)
		var stops: Array[Dictionary] = [
			{"spot": assemble, "yaw": atan2(-back_dir.x, -back_dir.y), "pose": State.STAND, "arrive": t_out - 6.0 - rng.randf() * 8.0, "depart": -1.0},
			{"spot": work, "yaw": rng.randf() * TAU, "pose": State.WORK, "depart": t_out + row * row_dt, "arrive": -1.0, "path": out_path},
			{"spot": night, "yaw": atan2(home0.x - night.x, home0.y - night.y), "pose": State.SIT, "depart": t_back + row * row_dt, "arrive": -1.0, "path": back_path},
			{"spot": home, "yaw": 0.0, "pose": State.ABSENT, "depart": t_bed + rng.randf() * 15.0, "arrive": -1.0},
		]
		CrowdPlan._link_stops(stops, mpm)
		out.append({"group": gid, "index": i, "role": str(spec.get("role", "captive")), "seed": "%s:%d" % [gid, i], "home": home,
			"lane": lane, "stops": stops})
	# Önde ve arkada iki nöbetçi: kapının dışında bekler, kolla yürür, Demir Diş'te nöbette, dönüşte kapıdan Nöbet Yurdu'na.
	var escort: Dictionary = spec.get("escort", {})
	var e_count := int(escort.get("count", 0))
	var e_posts: Array = escort.get("work_spots", [])
	var e_night := CrowdPlan._place(escort.get("night", "watch_yurt"), places)
	var last_row := (count - 1) / rows
	for e in e_count:
		var front := e == 0
		var wait := gate + (route[1] - gate).normalized() * (3.0 if front else -2.0) + Vector2(rng.randf_range(-0.8, 0.8), 0.0)
		var post := CrowdPlan._vec2(e_posts[e % e_posts.size()]) if not e_posts.is_empty() else route[route.size() - 1]
		var cut := CrowdPlan._nearest_index(route, post)
		var out_path := PackedVector2Array([wait])
		for k in range(1 if front else 0, cut + 1):
			out_path.append(route[k])
		out_path.append(post)
		var back_path := PackedVector2Array([post])
		for k in range(cut, -1, -1):
			back_path.append(route[k])
		back_path.append(gate + (route[1] - gate).normalized() * 2.0)
		var lead := -0.6 if front else (last_row + 1) * row_dt + 0.4
		var stops: Array[Dictionary] = [
			{"spot": wait, "yaw": atan2(route[1].x - gate.x, route[1].y - gate.y), "pose": State.STAND, "arrive": t_out - 12.0, "depart": -1.0},
			{"spot": post, "yaw": rng.randf() * TAU, "pose": State.STAND, "depart": t_out + lead, "arrive": -1.0, "path": out_path},
			{"spot": back_path[back_path.size() - 1], "yaw": 0.0, "pose": State.STAND, "depart": t_back + lead, "arrive": -1.0, "path": back_path},
			{"spot": e_night, "yaw": 0.0, "pose": State.ABSENT, "depart": GameClock.parse_hhmm(night_sit[0]) + 20.0 + rng.randf() * 10.0, "arrive": -1.0},
		]
		CrowdPlan._link_stops(stops, mpm)
		out.append({"group": gid + "_escort", "index": e, "role": str(escort.get("role", "guard")), "seed": "%s_escort:%d" % [gid, e],
			"home": e_night, "lane": 0.0, "stops": stops})
	return out


## Durakları bağlar: her durağın yolu önceki duraktan (döngüsel; yolu verilmemişse düz çizgi), uzunluğu, varış ya da çıkışı.
static func _link_stops(stops: Array, mpm: float) -> void:
	var n := stops.size()
	for k in n:
		var s: Dictionary = stops[k]
		var prev: Dictionary = stops[(k - 1 + n) % n]
		var path: PackedVector2Array = s.get("path", PackedVector2Array())
		if path.size() < 2:
			path = PackedVector2Array([prev["spot"], s["spot"]])
		s["path"] = path
		s["length"] = CrowdPlan.polyline_length(path)
		var walk := float(s["length"]) / maxf(mpm, 0.01)
		if float(s.get("arrive", -1.0)) >= 0.0:
			s["depart"] = fposmod(float(s["arrive"]) - walk, DAY_MIN)
		else:
			s["arrive"] = fposmod(float(s["depart"]) + walk, DAY_MIN)
		s["arrive"] = fposmod(float(s["arrive"]), DAY_MIN)
		s["depart"] = fposmod(float(s["depart"]), DAY_MIN)
		if walk < 0.0001:
			s["depart"] = s["arrive"]


## «hh:mm» ya da [en erken, en geç] → gün dakikası (aralıkta tohumlu).
static func _time_in(value: Variant, rng: RandomNumberGenerator) -> float:
	if value is Array and (value as Array).size() >= 2:
		var a := GameClock.parse_hhmm(value[0])
		var b := GameClock.parse_hhmm(value[1])
		if b < a:
			b += DAY_MIN
		return fposmod(lerpf(a, b, rng.randf()), DAY_MIN)
	return GameClock.parse_hhmm(value)


## Biçimden nokta: {ring {center, min, max}}, {disc {center, radius}} ya da {rect {center, size, yaw_deg}} (_sample).
static func _sample_shape(shape: Variant, rng: RandomNumberGenerator) -> Vector2:
	if not shape is Dictionary:
		return Vector2.ZERO
	var d: Dictionary = shape
	if d.get("ring") is Dictionary:
		var ring: Dictionary = d["ring"]
		var r0 := float(ring.get("min", 3.0))
		var r1 := float(ring.get("max", 8.0))
		var r := sqrt(lerpf(r0 * r0, r1 * r1, rng.randf()))
		return CrowdPlan._vec2(ring.get("center", [0.0, 0.0])) + Vector2.from_angle(rng.randf() * TAU) * r
	return _sample(d, rng)


static func _shape_center(shape: Variant) -> Vector2:
	if not shape is Dictionary:
		return Vector2.INF
	for k in ["ring", "disc", "rect"]:
		if (shape as Dictionary).get(k) is Dictionary:
			return CrowdPlan._vec2((shape as Dictionary)[k].get("center", [0.0, 0.0]))
	return Vector2.INF


## Boş bir nokta (biçimden; aralık gap, denemeler PROGRAM_TRIES).
static func _free_spot(shape: Variant, taken: PackedVector2Array, gap: float, rng: RandomNumberGenerator) -> Vector2:
	var p := CrowdPlan._sample_shape(shape, rng)
	for attempt in PROGRAM_TRIES:
		if not _crowded(p, taken, gap):
			return p
		p = CrowdPlan._sample_shape(shape, rng)
	return p


## Yerin noktası: kimlik (places), [x, z] ya da Vector2.
static func _place(value: Variant, places: Dictionary) -> Vector2:
	if value is String or value is StringName:
		return CrowdPlan._vec2(places.get(str(value), Vector2.ZERO))
	return CrowdPlan._vec2(value)


## Yolun noktaya en yakın düğümü.
static func _nearest_index(route: PackedVector2Array, p: Vector2) -> int:
	var best := 0
	var best_d := INF
	for k in route.size():
		var d := route[k].distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = k
	return best


## Yolun geri dönen köşeleri (önceki ve sonraki parçanın yönü ters: iş yeri düğümün ötesinde) atılır: kişi düğüme gidip dönmez, şeridi
## köşede sıçramaz.
static func _no_u_turns(path: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array(path)
	var k := 1
	while k < out.size() - 1:
		if (out[k] - out[k - 1]).dot(out[k + 1] - out[k]) < 0.0:
			out.remove_at(k)
			k = maxi(k - 1, 1)
		else:
			k += 1
	return out


## Yönün sağına lane metre (yaw: atan2(x, z); şeritteki kişinin yana kayması).
static func _lane_offset(yaw: float, lane: float) -> Vector2:
	return Vector2(cos(yaw), -sin(yaw)) * lane
