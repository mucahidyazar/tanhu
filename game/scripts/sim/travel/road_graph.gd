class_name RoadGraph
extends RefCounted
## İç haritanın araba yolu ağı (saf; travel.md §4.1, §4.4, §12 «Road, Network»; Yol Haritası roads-relays): düğümler (yol üstündeki adlı
## noktalar), kenarlar (iki düğüm arası yol parçası: yolu, zemini, eni, kapısı) ve her kenarın çoklu çizgisi (yay uzunluğu tablosuyla).
## Ağaca dokunmaz; TravelLayer kurar, Travel ve araba okur, sınama doğrudan kurar.
##
## Kenarın çizgisi: haritanın yol geometrisi (data/maps/<id>/roads.json; arazinin sahibi düzleştirir ve boyar) verilmişse kenarın yolu
## o çizginin iki düğüm arasındaki parçasıdır (düğümler çizgiye izdüşürülür); yoksa düğümden ara noktalardan (via) düğüme düz çizgi
## (travel.md §4.1'in uzunlukları bu düz çizgiyle hesaplanmıştır). Yol bulma süredir (Dijkstra; §4.4 «Yol bulma sürede Dijkstra'dır»):
## kenarın süresi çizgi boyunca zemin hızı ve hız sınırı bölgeleriyle (caps) toplanır. Kapalı kenar (kapı: bayrak ≥ değer, ya da açıklık
## çağrısı) yolda sayılmaz.
##   var g := RoadGraph.from_def(def, roads)                 # def: {nodes, edges, caps}; roads: roads.json'un sözlüğü (boş olabilir)
##   var r := g.route("n_camp", "n_fold", speeds, open)       # {ok, nodes, edges: [[id, ters mi]], length, seconds, points}
##   RoadGraph.point_at(r["points"], r["cum"], 120.0)         # yolun 120. metresi

## Örnekleme adımı (m): sürenin ve hız sınırının toplandığı aralık.
const SAMPLE_M := 1.0
## Zemin hızlarının varsayılanı (m/sn; travel.md §4.4 «Doğal süre: yol 6,4, kar 4,0»).
const SPEEDS := {"road": 6.4, "snow": 4.0, "deep": 2.4}

## Düğüm kimliği → Vector2 (x, z).
var nodes: Dictionary = {}
## Kenar kimliği → {id, road, a, b, ground, width, gate, points: PackedVector2Array, cum: PackedFloat32Array, length}.
var edges: Dictionary = {}
## Düğüm → [kenar kimlikleri].
var adjacency: Dictionary = {}
## Hız sınırı bölgeleri: [{id, at: Vector2, r, speed, after: {flag, gte, speed}}].
var caps: Array = []


## Tariften kurar. def: {nodes: {id: [x, z]}, edges: [{id, road, a, b, via, ground, width, gate}], caps: [...], gates: {kenar: kapı}};
## roads: haritanın yol dosyası (roads.json: {nodes, roads: [{id, points}], edges: [{id, road, a, b, via, surface, width}], speed_caps}).
## def'te olmayan düğüm, kenar ve sınır roads'tan alınır (yolun geometrisi ve kenar tablosu arazinin sahibinindir); def.gates kenarın
## kapısını yazar (ör. e06 Gün VI'ya dek kapalı, e09 köprü aşaması ≥5).
static func from_def(def: Dictionary, roads: Dictionary = {}) -> RoadGraph:
	var g := RoadGraph.new()
	for src: Variant in [roads.get("nodes", {}), def.get("nodes", {})]:
		if src is Dictionary:
			for id: Variant in src:
				g.nodes[str(id)] = RoadGraph.vec2(src[id])
	var lines := RoadGraph.road_lines(roads)
	var cart_roads := {}
	var raw_roads: Variant = roads.get("roads", [])
	if raw_roads is Array:
		for r: Variant in raw_roads:
			if r is Dictionary:
				cart_roads[str(r.get("id", ""))] = bool((r as Dictionary).get("cart", true))
	var edge_list: Variant = def.get("edges", [])
	if not edge_list is Array or (edge_list as Array).is_empty():
		edge_list = roads.get("edges", [])
	var gates: Dictionary = def.get("gates", {}) if def.get("gates") is Dictionary else {}
	for e: Variant in edge_list:
		if not e is Dictionary:
			continue
		var row := (e as Dictionary).duplicate(true)
		# Arabaya kapalı yolun kenarı ağa girmez (road_column, path_goat, path_ledges; roads.json cart false).
		if not bool(cart_roads.get(str(row.get("road", "")), true)):
			continue
		if not row.has("ground"):
			row["ground"] = "snow" if str(row.get("surface", "road")) in ["snow", "deep"] else "road"
		if gates.has(str(row.get("id", ""))):
			row["gate"] = gates[str(row["id"])]
		g.add_edge(row, lines)
	var cap_list: Variant = def.get("caps", null)
	if not cap_list is Array:
		cap_list = roads.get("speed_caps", [])
	for c: Variant in cap_list:
		if c is Dictionary:
			g.caps.append(RoadGraph.normalize_cap(c, def.get("cap_after", {})))
	return g


## Hız sınırı bölgesinin satırı (saf): {at, r, speed, after}; roads.json biçimi de okunur ({radius, max: sayı ya da [önce, sonra]}).
## İki değerli sınırda sonraki değer after.speed'dir, kapısı cap_after[kimlik]'ten (ör. buz: {flag: act1_day, gte: 3}).
static func normalize_cap(c: Dictionary, cap_after: Variant = {}) -> Dictionary:
	var cap := c.duplicate(true)
	cap["at"] = RoadGraph.vec2(cap.get("at", [0.0, 0.0]))
	if not cap.has("r"):
		cap["r"] = float(cap.get("radius", 0.0))
	var mx: Variant = cap.get("max")
	if not cap.has("speed") and mx != null:
		if mx is Array and (mx as Array).size() >= 2:
			cap["speed"] = float(mx[0])
			var gate: Dictionary = (cap_after as Dictionary).get(str(cap.get("id", "")), {}) if cap_after is Dictionary else {}
			if not gate.is_empty():
				cap["after"] = {"flag": str(gate.get("flag", "")), "gte": float(gate.get("gte", 1.0)), "speed": float(mx[1])}
		else:
			cap["speed"] = float(mx)
	return cap


## [x, z] ya da Vector2 → Vector2 (bozuksa sıfır).
static func vec2(v: Variant) -> Vector2:
	if v is Vector2:
		return v
	if v is Array and (v as Array).size() >= 2:
		return Vector2(float(v[0]), float(v[1]))
	return Vector2.ZERO


## Yol geometrisinin sözlüğünden kimlik → çoklu çizgi. İki biçim okunur: {roads: [{id, points|pts}]} ve {roads: {id: {points}|[[x,z]...]}}.
static func road_lines(roads: Dictionary) -> Dictionary:
	var out := {}
	var raw: Variant = roads.get("roads", {})
	if raw is Array:
		for r: Variant in raw:
			if r is Dictionary and (r as Dictionary).has("id"):
				out[str(r["id"])] = RoadGraph._points_of(r)
	elif raw is Dictionary:
		for id: Variant in raw:
			out[str(id)] = RoadGraph._points_of(raw[id])
	for id: Variant in out.keys():
		if (out[id] as PackedVector2Array).size() < 2:
			out.erase(id)
	return out


static func _points_of(r: Variant) -> PackedVector2Array:
	var list: Variant = r
	if r is Dictionary:
		list = (r as Dictionary).get("points", (r as Dictionary).get("pts", []))
	var out := PackedVector2Array()
	if list is Array:
		for p: Variant in list:
			out.append(RoadGraph.vec2(p))
	return out


## Kenarı ekler (çizgisi hesaplanır). lines: yol kimliği → çoklu çizgi (yoksa düz çizgi).
func add_edge(e: Dictionary, lines: Dictionary = {}) -> void:
	var id := str(e.get("id", ""))
	var a := str(e.get("a", ""))
	var b := str(e.get("b", ""))
	if id.is_empty() or not nodes.has(a) or not nodes.has(b):
		push_warning("[road_graph] kenar kurulamadı (düğüm yok): %s" % id)
		return
	var pa: Vector2 = nodes[a]
	var pb: Vector2 = nodes[b]
	var pts := PackedVector2Array()
	var line: PackedVector2Array = lines.get(str(e.get("road", "")), PackedVector2Array())
	if line.size() >= 2 and (e.get("via", []) as Array).is_empty():
		pts = RoadGraph.subpath(line, pa, pb)
	if pts.size() < 2:
		pts.append(pa)
		for v: Variant in e.get("via", []):
			pts.append(RoadGraph.vec2(v))
		pts.append(pb)
	var row := {
		"id": id, "road": str(e.get("road", "")), "a": a, "b": b, "ground": str(e.get("ground", "road")),
		"width": float(e.get("width", 3.0)), "gate": e.get("gate", {}) if e.get("gate") is Dictionary else {},
		"points": pts, "cum": RoadGraph.cumulative(pts),
	}
	row["length"] = float((row["cum"] as PackedFloat32Array)[pts.size() - 1])
	edges[id] = row
	for n in [a, b]:
		var list: Array = adjacency.get(n, [])
		list.append(id)
		adjacency[n] = list


## Çoklu çizginin iki noktası arasındaki parçası (saf): iki nokta çizgiye izdüşürülür, aradaki köşeler alınır; uçlar noktaların
## kendisidir (çizgiden uzaksa izdüşüm noktasıyla bağlanır). Sıra pa'dan pb'ye.
static func subpath(line: PackedVector2Array, pa: Vector2, pb: Vector2) -> PackedVector2Array:
	var cum := RoadGraph.cumulative(line)
	var sa := RoadGraph.project(line, cum, pa)
	var sb := RoadGraph.project(line, cum, pb)
	var from := float(sa["s"])
	var to := float(sb["s"])
	var out := PackedVector2Array()
	out.append(pa)
	if (sa["point"] as Vector2).distance_to(pa) > 0.05:
		out.append(sa["point"])
	if from <= to:
		for i in line.size():
			if cum[i] > from + 0.001 and cum[i] < to - 0.001:
				out.append(line[i])
	else:
		for i in range(line.size() - 1, -1, -1):
			if cum[i] < from - 0.001 and cum[i] > to + 0.001:
				out.append(line[i])
	if (sb["point"] as Vector2).distance_to(pb) > 0.05:
		out.append(sb["point"])
	out.append(pb)
	return out


## Birikimli uzunluk tablosu (saf): her köşenin çizginin başından uzaklığı.
static func cumulative(points: PackedVector2Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(points.size())
	var total := 0.0
	for i in points.size():
		if i > 0:
			total += points[i].distance_to(points[i - 1])
		out[i] = total
	return out


## Noktanın çizgiye izdüşümü (saf): {s (çizginin başından m), point, d (uzaklık), seg}.
static func project(points: PackedVector2Array, cum: PackedFloat32Array, p: Vector2) -> Dictionary:
	var best := {"s": 0.0, "point": points[0] if not points.is_empty() else p, "d": INF, "seg": 0}
	for i in range(1, points.size()):
		var a := points[i - 1]
		var b := points[i]
		var ab := b - a
		var len_sq := ab.length_squared()
		var t := clampf((p - a).dot(ab) / len_sq, 0.0, 1.0) if len_sq > 0.000001 else 0.0
		var q := a + ab * t
		var d := q.distance_to(p)
		if d < float(best["d"]):
			best = {"s": cum[i - 1] + sqrt(len_sq) * t, "point": q, "d": d, "seg": i - 1}
	return best


## Çizginin s. metresindeki nokta (saf; s uçlara kırpılır).
static func point_at(points: PackedVector2Array, cum: PackedFloat32Array, s: float) -> Vector2:
	var n := points.size()
	if n == 0:
		return Vector2.ZERO
	if n == 1 or s <= 0.0:
		return points[0]
	if s >= cum[n - 1]:
		return points[n - 1]
	var i := RoadGraph._segment_at(cum, s)
	var span := cum[i + 1] - cum[i]
	return points[i].lerp(points[i + 1], (s - cum[i]) / span if span > 0.000001 else 0.0)


## Çizginin s. metresindeki yön (radyan; atan2(dx, dz): 0 güney +Z, π/2 doğu; Horse.root ve travel.md'nin kuralı).
static func heading_at(points: PackedVector2Array, cum: PackedFloat32Array, s: float) -> float:
	var n := points.size()
	if n < 2:
		return 0.0
	var i := RoadGraph._segment_at(cum, clampf(s, 0.0, cum[n - 1]))
	var d := points[i + 1] - points[i]
	return atan2(d.x, d.y)


static func _segment_at(cum: PackedFloat32Array, s: float) -> int:
	var lo := 0
	var hi := cum.size() - 2
	while lo < hi:
		var mid := (lo + hi + 1) / 2
		if cum[mid] <= s:
			lo = mid
		else:
			hi = mid - 1
	return clampi(lo, 0, maxi(cum.size() - 2, 0))


## Kenarın uzunluğu (m; yoksa -1).
func edge_length(id: String) -> float:
	return float((edges.get(id, {}) as Dictionary).get("length", -1.0))


## Kenar kapısı açık mı (saf): kapı yoksa açık; {flag, gte} bayrağın sayısı ≥ değer (flags: ad → değer çağrısı ya da sözlük).
static func gate_open(gate: Dictionary, flags: Variant) -> bool:
	if gate.is_empty():
		return true
	var flag := str(gate.get("flag", ""))
	if flag.is_empty():
		return true
	var v: Variant = null
	if flags is Callable and (flags as Callable).is_valid():
		v = (flags as Callable).call(flag)
	elif flags is Dictionary:
		v = (flags as Dictionary).get(flag)
	var num := float(v) if v is float or v is int else (1.0 if v == true else 0.0)
	return num >= float(gate.get("gte", 1.0))


## Noktadaki hız sınırı (m/sn; sınır yoksa INF). flags: bölgenin «after» kuralı için (ör. buz: Gün III'ten ≤4,0).
func cap_at(p: Vector2, flags: Variant = null) -> float:
	var best := INF
	for c: Dictionary in caps:
		if p.distance_to(c["at"]) > float(c.get("r", 0.0)):
			continue
		var speed := float(c.get("speed", INF))
		var after: Variant = c.get("after")
		if after is Dictionary and RoadGraph.gate_open(after, flags):
			speed = float((after as Dictionary).get("speed", speed))
		best = minf(best, speed)
	return best


## Kenarın süresi (sn): çizgi boyunca SAMPLE_M adımla zemin hızı ve hız sınırı (speeds: zemin → m/sn; cap: hızın tavanı, K105).
func edge_seconds(id: String, speeds: Dictionary = SPEEDS, cap := INF, flags: Variant = null) -> float:
	var e: Dictionary = edges.get(id, {})
	if e.is_empty():
		return INF
	return seconds_along(e["points"], e["cum"], float(speeds.get(str(e["ground"]), speeds.get("road", 6.4))), cap, flags)


## Çizgi boyunca süre (sn; saf olmayan tek yanı caps): ground_speed sabit, sınır bölgelerinde ve cap'te kesilir.
func seconds_along(points: PackedVector2Array, cum: PackedFloat32Array, ground_speed: float, cap := INF, flags: Variant = null) -> float:
	var length := float(cum[cum.size() - 1]) if cum.size() > 0 else 0.0
	if length <= 0.0:
		return 0.0
	var steps := maxi(1, ceili(length / SAMPLE_M))
	var ds := length / float(steps)
	var total := 0.0
	for k in steps:
		var p := RoadGraph.point_at(points, cum, (float(k) + 0.5) * ds)
		var v := minf(minf(ground_speed, cap), cap_at(p, flags))
		total += ds / maxf(v, 0.05)
	return total


## Kenar açık mı: kapısı (bayraklar) ve isteğe bağlı açıklık çağrısı (kenar kimliği → bool; ör. arabanın aşaması, hikâye kilidi).
func edge_open(id: String, flags: Variant = null, open: Callable = Callable()) -> bool:
	var e: Dictionary = edges.get(id, {})
	if e.is_empty():
		return false
	if not RoadGraph.gate_open(e.get("gate", {}), flags):
		return false
	return not open.is_valid() or bool(open.call(id))


## Süreye göre en kısa yol (Dijkstra). Döner: {ok, nodes: [..], edges: [[kimlik, ters mi], ...], length, seconds, points, cum}.
## a == b ise boş yol (ok, uzunluk 0).
func route(a: String, b: String, speeds: Dictionary = SPEEDS, cap := INF, flags: Variant = null, open: Callable = Callable()) -> Dictionary:
	var fail := {"ok": false, "nodes": [], "edges": [], "length": 0.0, "seconds": 0.0, "points": PackedVector2Array(), "cum": PackedFloat32Array()}
	if not nodes.has(a) or not nodes.has(b):
		return fail
	if a == b:
		var pts := PackedVector2Array([nodes[a]])
		return {"ok": true, "nodes": [a], "edges": [], "length": 0.0, "seconds": 0.0, "points": pts, "cum": PackedFloat32Array([0.0])}
	var dist := {a: 0.0}
	var prev := {}
	var done := {}
	var cost := {}
	while true:
		var u := ""
		var best := INF
		for n: String in dist:
			if not done.has(n) and float(dist[n]) < best:
				best = float(dist[n])
				u = n
		if u.is_empty() or u == b:
			break
		done[u] = true
		for eid: String in adjacency.get(u, []):
			if not edge_open(eid, flags, open):
				continue
			var e: Dictionary = edges[eid]
			var v := str(e["b"]) if str(e["a"]) == u else str(e["a"])
			if done.has(v):
				continue
			if not cost.has(eid):
				cost[eid] = edge_seconds(eid, speeds, cap, flags)
			var nd := best + float(cost[eid])
			if nd < float(dist.get(v, INF)):
				dist[v] = nd
				prev[v] = [u, eid]
	if not dist.has(b):
		return fail
	var path_nodes: Array = [b]
	var path_edges: Array = []
	var cur := b
	while cur != a:
		var step: Array = prev[cur]
		var eid := str(step[1])
		var e: Dictionary = edges[eid]
		# Kenar a'dan b'ye yazılmıştır; yolda b'den a'ya gidiliyorsa terstir.
		path_edges.push_front([eid, str(e["a"]) != str(step[0])])
		cur = str(step[0])
		path_nodes.push_front(cur)
	var points := route_points(path_edges)
	var cum := RoadGraph.cumulative(points)
	return {"ok": true, "nodes": path_nodes, "edges": path_edges, "length": float(cum[cum.size() - 1]), "seconds": float(dist[b]), "points": points,
		"cum": cum}


## Kenar dizisinin birleşik çizgisi (ortak düğümler bir kez).
func route_points(path_edges: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for step: Array in path_edges:
		var e: Dictionary = edges.get(str(step[0]), {})
		if e.is_empty():
			continue
		var pts: PackedVector2Array = (e["points"] as PackedVector2Array).duplicate()
		if bool(step[1]):
			pts.reverse()
		for i in pts.size():
			if i == 0 and not out.is_empty() and out[out.size() - 1].distance_to(pts[0]) < 0.01:
				continue
			out.append(pts[i])
	return out


## Yolun süresi (sn): her kenar kendi zemini ve sınırlarıyla (route'un seconds'ı ile aynı; durak arası tablolar için).
func route_seconds(path_edges: Array, speeds: Dictionary = SPEEDS, cap := INF, flags: Variant = null) -> float:
	var total := 0.0
	for step: Array in path_edges:
		total += edge_seconds(str(step[0]), speeds, cap, flags)
	return total


## Yolun s. metresindeki kenarın zemini (yol, kar; route'un edges'iyle aynı sırada yürür).
func ground_at(path_edges: Array, s: float) -> String:
	var walked := 0.0
	for step: Array in path_edges:
		var e: Dictionary = edges.get(str(step[0]), {})
		if e.is_empty():
			continue
		walked += float(e["length"])
		if s <= walked + 0.001:
			return str(e["ground"])
	return str((edges.get(str((path_edges.back() as Array)[0]), {}) as Dictionary).get("ground", "road")) if not path_edges.is_empty() else "road"


## Noktaya en yakın kenar ve yeri: {edge, s, point, d} (kenar yoksa edge "").
func nearest_edge(p: Vector2) -> Dictionary:
	var best := {"edge": "", "s": 0.0, "point": p, "d": INF}
	for id: String in edges:
		var e: Dictionary = edges[id]
		var hit := RoadGraph.project(e["points"], e["cum"], p)
		if float(hit["d"]) < float(best["d"]):
			best = {"edge": id, "s": hit["s"], "point": hit["point"], "d": hit["d"]}
	return best


## Düğüme bağlanan kenarlar boyunca düğümden geriye from_m–to_m metre arasındaki noktalar (saf olmayan: kenarlar): çağırma (travel.md §5.3
## «düğüme giren dallarda 20 m'den 128 m'ye geri yürü»). Döner: [{edge, s (kenarın başından), point, heading (düğüme doğru)}], dal dal, step aralıkla.
func approach_points(node: String, from_m: float, to_m: float, step := 4.0, open: Callable = Callable(), flags: Variant = null) -> Array:
	var out: Array = []
	for eid: String in adjacency.get(node, []):
		if not edge_open(eid, flags, open):
			continue
		var e: Dictionary = edges[eid]
		var pts: PackedVector2Array = e["points"]
		var cum: PackedFloat32Array = e["cum"]
		var length := float(e["length"])
		var at_start := str(e["a"]) == node
		var d := from_m
		while d <= minf(to_m, length) + 0.001:
			var s := d if at_start else length - d
			var p := RoadGraph.point_at(pts, cum, s)
			var toward := RoadGraph.point_at(pts, cum, s - 0.5 if at_start else s + 0.5)
			out.append({"edge": eid, "s": s, "d": d, "point": p, "heading": atan2(toward.x - p.x, toward.y - p.y)})
			d += step
	return out
