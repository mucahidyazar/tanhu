extends TestCase
## Yol ağı (RoadGraph, saf; travel.md §4.1, §4.4, §16 T1; Yol Haritası roads-relays): Kışlak'ın yol dosyası (data/maps/kislak/roads.json,
## arazinin) ve katmanın kapıları (data/maps/kislak/travel.json) ile kurulan ağın kenar uzunlukları, ana hatlar, durak arası metre ve doğal
## saniye (Dijkstra, sınır bölgeleri hariç: tablonun kuralı), köprü kapısı, arabaya kapalı yollar; çizginin yardımcıları.

const ROADS := "res://data/maps/kislak/roads.json"
const LAYER := "res://data/maps/kislak/travel.json"
## travel.md §4.1 (m).
const EDGES := {
	"e01": 100.3, "e02": 118.2, "e03": 118.0, "e04": 127.3, "e05": 194.5, "e06": 198.3, "e07": 180.1, "e08": 197.8, "e09": 86.0,
	"e10": 155.2, "e11": 175.3, "e12": 372.2, "e13": 161.2, "e14": 170.2, "e15": 120.8, "e16": 85.4, "e17": 103.0, "e18": 63.0,
	"e19": 116.1, "e20": 50.6, "e21": 193.2, "e22": 345.4, "e23": 172.6,
}
## travel.md §4.1'in düğümleri (x, z).
const DESIGN_NODES := {
	"n_hearth": Vector2(0, 0), "n_ramp": Vector2(40, -92), "n_ford": Vector2(140, -155), "n_fold": Vector2(210, -250), "n_fork": Vector2(300, -340),
	"n_ufolds": Vector2(440, -475), "n_throat": Vector2(550, -640), "n_reeds": Vector2(320, -148), "n_bridge": Vector2(500, -230),
	"n_kurgan": Vector2(450, -300), "n_camp": Vector2(58, 22), "n_cut": Vector2(430, 10), "n_kiln": Vector2(590, 30), "n_wfork": Vector2(-160, -40),
	"n_forge": Vector2(-270, -90), "n_gallery": Vector2(-300, -170), "n_hgate": Vector2(60, 125), "n_wreeds": Vector2(-50, -190),
	"n_salt": Vector2(-180, -510), "n_warm": Vector2(-350, -540), "n_pier": Vector2(345, -192),
}


func _graph(open_bridge := true) -> RoadGraph:
	var layer := MapLayers.read(LAYER)
	var g := RoadGraph.from_def(layer.get("graph", {}), MapLayers.read(ROADS))
	return g


func _flags(bridge: int, day: int) -> Dictionary:
	return {"bridge_stage": bridge, "act1_day": day}


func test_edges_match_the_design_lengths() -> void:
	if not FileAccess.file_exists(ROADS):
		print("    atlandı: %s yok" % ROADS)
		return
	var g := _graph()
	# Arazinin düğümü tasarımın yerinden kaydıysa (n_gallery (−300, −164); act1.md (−300, −170)) o kenar tasarımla değil, arazinin çizgisiyle
	# sınanır ve satırı yazılır: geometri arazinindir.
	var moved: Array = []
	for id: String in DESIGN_NODES:
		if g.nodes.has(id) and (g.nodes[id] as Vector2).distance_to(DESIGN_NODES[id]) > 0.5:
			moved.append(id)
	for id: String in EDGES:
		assert_true(g.edges.has(id), "Kenar %s" % id)
		if not g.edges.has(id):
			continue
		var e: Dictionary = g.edges[id]
		if moved.has(str(e["a"])) or moved.has(str(e["b"])):
			print("    not: %s arazinin düğümüyle %.1f m (tasarım %.1f m; kayan düğüm %s)" % [id, g.edge_length(id), float(EDGES[id]), moved])
			continue
		var want := float(EDGES[id])
		assert_almost(g.edge_length(id), want, want * 0.005 + 0.05, "%s uzunluğu ±%%0,5 (%.1f m)" % [id, g.edge_length(id)])
	# Arabaya kapalı yollar ağa girmez (travel.md §4.1).
	for e: Dictionary in g.edges.values():
		assert_false(str(e["road"]) in ["road_column", "path_goat", "path_ledges"], "Arabaya kapalı yol: %s" % e["road"])
	# Ana hatlar (T1): Kış Yolu 857, Doğu Hattı 619, Kızak Yolu 533, Batı Yolu 376 (kayan düğümün hattı yazılır).
	var lines := {"road_winter": 857.0, "road_east": 619.0, "road_sled": 533.0, "road_west": 376.0}
	for road: String in lines:
		var total := 0.0
		var touched := false
		for e: Dictionary in g.edges.values():
			if str(e["road"]) == road and not (road == "road_east" and str(e["id"]) == "e11"):
				total += float(e["length"])
				touched = touched or moved.has(str(e["a"])) or moved.has(str(e["b"]))
		if touched:
			print("    not: %s %.1f m (tasarım %.0f m)" % [road, total, float(lines[road])])
			continue
		assert_almost(total, float(lines[road]), float(lines[road]) * 0.005, "%s %.1f m" % [road, total])


func test_file_lengths_match_the_geometry() -> void:
	# roads.json'un yazılı uzunlukları (yolun «length»ı, kenarın «m»i) çizgisinin gerçek uzunluğudur: düğüm ya da nokta taşınınca dosyanın
	# sayısı da yenilenir (2026-11-09: n_gallery (−300, −164)'te iken e16 79,8 m, Batı Yolu 370,8 m idi, dosya 85,4 ve 376 yazıyordu).
	if not FileAccess.file_exists(ROADS):
		return
	var roads := MapLayers.read(ROADS)
	var lines := RoadGraph.road_lines(roads)
	for r: Dictionary in roads.get("roads", []):
		var pts: PackedVector2Array = lines.get(str(r["id"]), PackedVector2Array())
		var real := float(RoadGraph.cumulative(pts)[pts.size() - 1]) if pts.size() >= 2 else 0.0
		assert_almost(float(r.get("length", -1.0)), real, 0.15, "%s length = çizgisi (%.1f m)" % [r["id"], real])
	var g := RoadGraph.from_def({}, roads)
	for e: Dictionary in roads.get("edges", []):
		if not g.edges.has(str(e["id"])):
			continue
		assert_almost(float(e.get("m", -1.0)), g.edge_length(str(e["id"])), 0.15, "%s m = çizgisi (%.1f m)" % [e["id"], g.edge_length(str(e["id"]))])


func test_station_table_by_dijkstra() -> void:
	if not FileAccess.file_exists(ROADS):
		return
	var g := _graph()
	g.caps = []
	var speeds := {"road": 6.4, "snow": 4.0}
	var flags := _flags(5, 6)
	# travel.md §4.4: [düğüm, düğüm, m, sn] (sınır bölgeleri hariç).
	var table := [
		["n_camp", "n_fold", 352.0, 55.0], ["n_camp", "n_cut", 372.0, 58.0], ["n_camp", "n_forge", 354.0, 55.0],
		["n_camp", "n_pier", 465.0, 73.0], ["n_camp", "n_kurgan", 635.0, 99.0], ["n_camp", "n_ufolds", 674.0, 105.0],
		["n_camp", "n_salt", 773.0, 171.0], ["n_fold", "n_kurgan", 283.0, 44.0], ["n_kurgan", "n_ufolds", 175.0, 27.0],
		["n_pier", "n_kurgan", 334.0, 52.0], ["n_cut", "n_salt", 1145.0, 229.0],
	]
	for row: Array in table:
		var r := g.route(str(row[0]), str(row[1]), speeds, INF, flags)
		assert_true(bool(r["ok"]), "%s → %s yolu var" % [row[0], row[1]])
		assert_almost(float(r["length"]), float(row[2]), 1.5, "%s → %s %.1f m" % [row[0], row[1], float(r["length"])])
		assert_almost(float(r["seconds"]), float(row[3]), 1.5, "%s → %s %.1f sn" % [row[0], row[1], float(r["seconds"])])
	# Köprü aşaması <5: e09 kapalı, İskele → Kurgan 631 m / 99 sn (§4.4).
	var closed := g.route("n_pier", "n_kurgan", speeds, INF, _flags(0, 6))
	assert_almost(float(closed["length"]), 631.0, 1.5, "Köprüsüz İskele → Kurgan %.1f m" % float(closed["length"]))
	assert_almost(float(closed["seconds"]), 99.0, 1.5, "Köprüsüz %.1f sn" % float(closed["seconds"]))
	# Boğaz Gün VI'ya dek kapalı (e06).
	assert_false(bool(g.route("n_ufolds", "n_throat", speeds, INF, _flags(5, 5))["ok"]), "Gün V'te Boğaz yolu kapalı")
	assert_true(bool(g.route("n_ufolds", "n_throat", speeds, INF, _flags(5, 6))["ok"]), "Gün VI'da açık")


func test_speed_caps_and_pace_cap() -> void:
	if not FileAccess.file_exists(ROADS):
		return
	var g := _graph()
	# Ulu Ocak r 30 ≤3,2; Geçit Gün I–II ≤3,2, Gün III'ten buz ≤4,0.
	assert_almost(g.cap_at(Vector2(5.0, 5.0), _flags(0, 1)), 3.2, 0.001, "Ocağın çevresi")
	assert_almost(g.cap_at(Vector2(140.0, -150.0), _flags(0, 2)), 3.2, 0.001, "Geçit, su")
	assert_almost(g.cap_at(Vector2(140.0, -150.0), _flags(0, 3)), 4.0, 0.001, "Geçit, buz")
	assert_eq(g.cap_at(Vector2(300.0, 0.0), {}), INF, "Açık yolda sınır yok")
	# K105: araba oyuncunun koşusunu aşmaz (4,6); kar 4,0 kalır.
	var capped := Travel.cart_speeds(PaceLimit.ADULT_RUN)
	assert_almost(float(capped["road"]), 4.6, 0.001)
	assert_almost(float(capped["snow"]), 4.0, 0.001)
	var r := g.route("n_camp", "n_fold", capped, INF, _flags(5, 6))
	assert_true(float(r["seconds"]) > 352.0 / 4.6, "Sınırlı hızla daha uzun (%.1f sn)" % float(r["seconds"]))


func test_polyline_helpers() -> void:
	var pts := PackedVector2Array([Vector2(0, 0), Vector2(10, 0), Vector2(10, 10)])
	var cum := RoadGraph.cumulative(pts)
	assert_almost(cum[2], 20.0, 0.0001)
	assert_vec_almost(_v3(RoadGraph.point_at(pts, cum, 15.0)), Vector3(10, 0, 5), 0.0001, "15. metre")
	assert_almost(RoadGraph.heading_at(pts, cum, 5.0), PI * 0.5, 0.0001, "Doğuya (atan2(dx, dz))")
	assert_almost(RoadGraph.heading_at(pts, cum, 15.0), 0.0, 0.0001, "Güneye (+Z)")
	var hit := RoadGraph.project(pts, cum, Vector2(12, 4))
	assert_almost(float(hit["s"]), 14.0, 0.0001)
	assert_almost(float(hit["d"]), 2.0, 0.0001)
	var sub := RoadGraph.subpath(pts, Vector2(10, 8), Vector2(2, 0))
	assert_vec_almost(_v3(sub[0]), Vector3(10, 0, 8), 0.0001, "Ters yönde alt çizgi")
	assert_vec_almost(_v3(sub[sub.size() - 1]), Vector3(2, 0, 0), 0.0001)
	assert_almost(PathNetwork.polyline_length(sub), 16.0, 0.0001)
	assert_true(RoadGraph.gate_open({}, {}), "Kapısız kenar açık")
	assert_false(RoadGraph.gate_open({"flag": "bridge_stage", "gte": 5}, {"bridge_stage": 4}))
	assert_true(RoadGraph.gate_open({"flag": "bridge_stage", "gte": 5}, func(k: String) -> Variant: return 5 if k == "bridge_stage" else null))
	var cap := RoadGraph.normalize_cap({"id": "cap_ford", "at": [1, 2], "radius": 15, "max": [3.2, 4.0]}, {"cap_ford": {"flag": "d", "gte": 3}})
	assert_almost(float(cap["r"]), 15.0, 0.0001)
	assert_almost(float(cap["speed"]), 3.2, 0.0001)
	assert_almost(float(cap["after"]["speed"]), 4.0, 0.0001)


func test_approach_points_walk_back_along_incoming_branches() -> void:
	var g := RoadGraph.from_def({"nodes": {"a": [0, 0], "b": [100, 0], "c": [0, 50]},
		"edges": [{"id": "ab", "a": "a", "b": "b"}, {"id": "ca", "a": "c", "b": "a"}]})
	var pts := g.approach_points("a", 20.0, 40.0, 10.0)
	assert_eq(pts.size(), 3 + 3, "İki dal × üç nokta (20, 30, 40 m; c dalı 50 m)")
	for p: Dictionary in pts:
		var to_node := -(p["point"] as Vector2)
		assert_almost(angle_difference(float(p["heading"]), atan2(to_node.x, to_node.y)), 0.0, 0.001, "Yön düğüme doğru")
		assert_almost((p["point"] as Vector2).length(), float(p["d"]), 0.001)


func _v3(p: Vector2) -> Vector3:
	return Vector3(p.x, 0.0, p.y)
