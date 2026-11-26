extends SceneTree
## Geliştirme aracı: Meshy yurt modelinin iç ölçülerini çıkarır ve res://assets/structures/yurt/yurt_fit.json
## dosyasına yazar (YurtInterior otağın içini bu ölçülerle kabuğa oturtur; Yurt kapı aralığını ve duvarın
## çarpışma dairesini buradan alır).
##
## Yurt verilen yarıçapla kurulur (kapı yüksekliği için dikey uzatma dahil), modelin köşe noktaları yurdun yerel
## uzayında taranır. Ölçüler oranla yazılır: yarıçaplar yurdun yarıçapına (radius), yükseklikler modelin boyuna
## bölünür; böylece başka yarıçaplı ya da farklı uzatılmış yurtlarda da geçerlidir.
##   - inner: her açı (5°) ve yükseklik diliminde duvarın iç yüzü (köşelerin alt yüzdeliği; ip ve düğüm gibi
##     içe taşan küçük parçalar sayılmaz). Kapı açıklığındaki dilimler -1'dir.
##   - roof: duvarın çatıya döndüğü yerden taca kadar çatının iç yüzü (açılara göre ortalama).
##   - door: kapı aralığının ortası ve yarı genişliği (derece; +Z = 0, +X yönü artı), eşik ve üst kenar.
##   - circle: duvarın iç yüzüne en iyi oturan daire (çarpışma duvarı bununla kurulur).
##   - crown: tacın (tündük) alt kenarı ve yarıçapı.
##
## Kullanım: Godot --headless --path . -s res://tools/measure_yurt.gd -- [yarıçap=3.35] [--print]

const OUT_PATH := "res://assets/structures/yurt/yurt_fit.json"
const ANGLE_STEP := 5.0
const WALL_LEVELS := 12
const ROOF_LEVELS := 10
## Duvarın iç yüzü sayılan yüzdelik (en içteki köşelerin bu oranı atlanır).
const INNER_PERCENTILE := 0.06


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var radius := 3.35
	for a in args:
		if a.is_valid_float():
			radius = float(a)
	var yurt := Yurt.new()
	yurt.radius = radius
	yurt.has_smoke = false
	yurt.build_interior = false
	root.add_child(yurt)
	for i in 4:
		await process_frame
	var model := yurt.get_node_or_null(^"YurtModel") as MeshyProp
	if model == null or not model.has_model():
		print("[yurt] model yok")
		quit(1)
		return
	var points := _points(yurt, model)
	var height := model.get_model_aabb().end.y
	var door := _door(points, radius)
	var wall_top := _wall_top(points, radius, height)
	var fit := {
		"source_radius": radius,
		"model_height": snappedf(height, 0.001),
		"angle_step": ANGLE_STEP,
		"wall_top": snappedf(wall_top / height, 0.0001),
		"door": door,
		"inner": _inner(points, radius, height, wall_top, door),
		"roof": _roof(points, radius, height, wall_top),
		"crown": _crown(points, radius, height),
	}
	fit["circle"] = _circle(fit["inner"], radius)
	var f := FileAccess.open(OUT_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(fit, "\t"))
	f.close()
	print("[yurt] yazıldı: %s (köşe: %d, boy: %.2f m, duvarın üstü: %.2f m)" % [OUT_PATH, points.size(), height, wall_top])
	if args.has("--print"):
		print(JSON.stringify(fit, "  "))
	quit(0)


## Modelin bütün köşeleri, yurdun yerel uzayında.
func _points(yurt: Node3D, model: MeshyProp) -> PackedVector3Array:
	var points := PackedVector3Array()
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var to_yurt := yurt.global_transform.affine_inverse() * mi.global_transform
		for s in mi.mesh.get_surface_count():
			var verts: PackedVector3Array = mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
			for v in verts:
				points.append(to_yurt * v)
	return points


## Açı (derece): +Z = 0, +X yönü artı.
static func _angle(p: Vector3) -> float:
	return rad_to_deg(atan2(p.x, p.z))


static func _percentile(values: Array[float], q: float) -> float:
	if values.is_empty():
		return -1.0
	values.sort()
	return values[clampi(int(floor(values.size() * q)), 0, values.size() - 1)]


## Kapı: 0,3–1,9 m arasında duvar yarıçapındaki köşelerin +Z'nin iki yanındaki en yakın açıları, eşik ve üst kenar.
func _door(points: PackedVector3Array, radius: float) -> Dictionary:
	var left := -30.0
	var right := 30.0
	for p in points:
		if p.y < 0.3 or p.y > 1.9:
			continue
		var r := Vector2(p.x, p.z).length()
		if r < radius * 0.83 or r > radius * 1.06:
			continue
		var a := _angle(p)
		if a < 0.0 and a > left:
			left = a
		if a > 0.0 and a < right:
			right = a
	var mid := (left + right) * 0.5
	var lintel := 99.0
	var sill := 0.0
	for p in points:
		var r := Vector2(p.x, p.z).length()
		if r < radius * 0.8 or r > radius * 1.1:
			continue
		var a := _angle(p)
		if absf(a - mid) < 3.0 and p.y > 1.5:
			lintel = minf(lintel, p.y)
		if absf(a - mid) < 4.0 and p.y < 0.4:
			sill = maxf(sill, p.y)
	return {"center_deg": snappedf(mid, 0.01), "half_width_deg": snappedf((right - left) * 0.5, 0.01), "sill": snappedf(sill, 0.001), "top": snappedf(lintel, 0.001)}


## Duvarın çatıya döndüğü yükseklik: duvarın ortanca yarıçapı 1,2 m'deki değerin %94'ünün altına indiği ilk yer.
func _wall_top(points: PackedVector3Array, radius: float, height: float) -> float:
	var ref := _median_radius(points, 1.1, 1.3)
	var y := 1.6
	while y < height * 0.8:
		if _median_radius(points, y, y + 0.05) < ref * 0.94:
			return y
		y += 0.05
	return height * 0.56


func _median_radius(points: PackedVector3Array, y0: float, y1: float) -> float:
	var radii: Array[float] = []
	for p in points:
		if p.y >= y0 and p.y < y1 and absf(_angle(p)) > 40.0:
			radii.append(Vector2(p.x, p.z).length())
	return _percentile(radii, 0.5)


## Duvarın iç yüzü: [yükseklik seviyesi][açı dilimi] → yarıçap / radius (kapıda -1). Boş dilimler komşulardan doldurulur.
func _inner(points: PackedVector3Array, radius: float, height: float, wall_top: float, door: Dictionary) -> Array:
	var bins := int(360.0 / ANGLE_STEP)
	var levels := []
	var door_from := float(door["center_deg"]) - float(door["half_width_deg"])
	var door_to := float(door["center_deg"]) + float(door["half_width_deg"])
	for li in WALL_LEVELS + 1:
		var y := wall_top * float(li) / float(WALL_LEVELS)
		var buckets := []
		for b in bins:
			buckets.append([] as Array[float])
		for p in points:
			if absf(p.y - y) > 0.08:
				continue
			var r := Vector2(p.x, p.z).length()
			if r < radius * 0.7 or r > radius * 1.1:
				continue
			var b := int(floor(fposmod(_angle(p) + 180.0, 360.0) / ANGLE_STEP)) % bins
			(buckets[b] as Array[float]).append(r)
		var row := []
		for b in bins:
			var a0 := -180.0 + b * ANGLE_STEP
			var a1 := a0 + ANGLE_STEP
			if a1 > door_from and a0 < door_to and y < float(door["top"]):
				row.append(-1.0)
				continue
			var v := _percentile(buckets[b], INNER_PERCENTILE)
			row.append(v / radius if v > 0.0 else 0.0)
		_fill_gaps(row)
		levels.append(row.map(func(v: float) -> float: return snappedf(v, 0.0001)))
	return levels


## 0 olan (köşesiz) dilimleri en yakın dolu komşuların ortalamasıyla doldurur (kapı dilimleri -1 kalır).
static func _fill_gaps(row: Array) -> void:
	var n := row.size()
	for i in n:
		if float(row[i]) != 0.0:
			continue
		var sum := 0.0
		var count := 0
		for k in range(1, n):
			for j in [i - k, i + k]:
				var v := float(row[posmod(j, n)])
				if v > 0.0:
					sum += v
					count += 1
			if count > 0:
				break
		row[i] = sum / count if count > 0 else 0.9


## Çatının iç yüzü: duvarın üstünden taca kadar seviyelerde açılara göre iç yarıçap (oran) ve yükseklik (oran).
func _roof(points: PackedVector3Array, radius: float, height: float, wall_top: float) -> Array:
	var out := []
	var top := height * 0.9
	for li in ROOF_LEVELS + 1:
		var y := lerpf(wall_top, top, float(li) / float(ROOF_LEVELS))
		var radii: Array[float] = []
		for p in points:
			if absf(p.y - y) < 0.06 and absf(_angle(p)) > 20.0:
				radii.append(Vector2(p.x, p.z).length())
		var r := _percentile(radii, 0.1)
		out.append([snappedf(y / height, 0.0001), snappedf(maxf(r, 0.0) / radius, 0.0001)])
	return out


## Tacın alt kenarı (oran) ve yarıçapı (oran): boyun son %12'sindeki köşelerin yarıçap ortancası.
func _crown(points: PackedVector3Array, radius: float, height: float) -> Dictionary:
	var radii: Array[float] = []
	var lowest := height
	for p in points:
		if p.y > height * 0.88:
			radii.append(Vector2(p.x, p.z).length())
			lowest = minf(lowest, p.y)
	return {"y": snappedf(lowest / height, 0.0001), "r": snappedf(_percentile(radii, 0.5) / radius, 0.0001)}


## Duvarın iç yüzüne (0,1–0,6 boy aralığındaki seviyeler, kapı hariç) en küçük karelerle oturtulan daire (oran).
static func _circle(inner: Array, radius: float) -> Dictionary:
	var pts: Array[Vector2] = []
	var bins: int = (inner[0] as Array).size()
	for li in range(1, inner.size() - 1):
		var row: Array = inner[li]
		for b in bins:
			var v := float(row[b])
			if v <= 0.0:
				continue
			var a := deg_to_rad(-180.0 + (b + 0.5) * ANGLE_STEP)
			pts.append(Vector2(sin(a), cos(a)) * v)
	# Kasa yöntemi: x² + y² + D x + E y + F = 0 doğrusal en küçük kareler.
	var sxx := 0.0; var sxy := 0.0; var syy := 0.0; var sx := 0.0; var sy := 0.0
	var sxz := 0.0; var syz := 0.0; var sz := 0.0
	var n := float(pts.size())
	for p in pts:
		var z := p.x * p.x + p.y * p.y
		sxx += p.x * p.x; sxy += p.x * p.y; syy += p.y * p.y; sx += p.x; sy += p.y
		sxz += p.x * z; syz += p.y * z; sz += z
	var m := Basis(Vector3(sxx, sxy, sx), Vector3(sxy, syy, sy), Vector3(sx, sy, n))
	var sol := m.inverse() * Vector3(-sxz, -syz, -sz)
	var c := Vector2(-sol.x * 0.5, -sol.y * 0.5)
	var r := sqrt(maxf(c.length_squared() - sol.z, 0.0))
	return {"x": snappedf(c.x, 0.0001), "z": snappedf(c.y, 0.0001), "r": snappedf(r, 0.0001)}
