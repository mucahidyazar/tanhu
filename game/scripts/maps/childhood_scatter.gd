class_name ChildhoodScatter
extends RefCounted
## Çocukluk'un kaya öbekleri ve çalıları (saf; K98: yukarıdan boş kalmasın; layout.json "childhood.scatter", "childhood.ground"): iş parçacığında dağıtılır, ağları ve
## MultiMesh tamponları ana iş parçacığına hazır gelir. Kaya: öbekler, kademe yüzleri ve tepeler; yontulmuş ikosfer (atw_rock). Çalı: pelin (gümüşümsü küme) ve karagan (kuru dal);
## dere kıyısında ve kaya dibinde sık. Hiçbiri ağılda, izde, yurtların dibinde, sürünün yolunda, avın lekesinde ve sayım hattında durmaz. Büyük kayalar çarpışır (solid).

## MultiMesh örnek boyları (sayı).
const ROCK_FLOATS := 12
const SHRUB_FLOATS := 16
## Kaya biçimleri: [ölçek x, y, z] (yontulmuş ikosferin yönü): yuvarlak, yassı, dik, uzun.
const ROCK_SHAPES: Array[Vector3] = [Vector3(1.0, 0.72, 0.9), Vector3(1.0, 0.42, 0.84), Vector3(0.72, 1.0, 0.66), Vector3(1.0, 0.56, 0.62)]
const SAGE_LIGHT := Color(0.63, 0.61, 0.45, 1.0)
const SAGE_DARK := Color(0.41, 0.39, 0.28, 1.0)
const KARAGAN_BARK := Color(0.34, 0.26, 0.2, 1.0)
const KARAGAN_LEAF := Color(0.54, 0.5, 0.26, 1.0)
## E21: ılgın (Tamarix): gümüşümsü yeşil yaprak, güzün pembe salkım, kızıl kahve dal.
const TAMARISK_LEAF := Color(0.47, 0.53, 0.41, 1.0)
const TAMARISK_PLUME := Color(0.78, 0.55, 0.6, 1.0)
const TAMARISK_BARK := Color(0.4, 0.22, 0.17, 1.0)


## Yerleşim ve ağlar (saf; iş parçacığında): spec Çocukluk'un yüzüyle birleşik düzen (ground_relief). Döner:
##   rocks: [{arrays (ağ), buffer}], shrubs: [{arrays, buffer}], solid: Array[Vector3] (x, z, yarıçap), counts: {rocks, shrubs}.
static func build(spec: Dictionary) -> Dictionary:
	var shape := OrdosGround.new(spec)
	var d: Dictionary = spec.get("childhood", {})
	var scatter: Dictionary = d.get("scatter", {})
	var ground_def: Dictionary = d.get("ground", {})
	var mask: Dictionary = spec.get("ground_mask", {})
	var rng := RandomNumberGenerator.new()
	rng.seed = int(scatter.get("seed", 730))
	var keep_out := keep_outs(spec)
	var route := PackedVector2Array()
	for p: Array in ((d.get("herd", {}) as Dictionary).get("line", {}) as Dictionary).get("route", []):
		route.append(OrdosGround._vec2(p))
	var meadow: Dictionary = (d.get("herd", {}) as Dictionary).get("meadow", {})
	var meadow_center := OrdosGround._vec2(meadow.get("center", [0.0, 0.0]))
	var meadow_radius := float(meadow.get("radius", 0.0))
	var placer := _Placer.new()
	placer.rng = rng
	placer.shape = shape
	placer.keep_out = keep_out
	placer.route = route
	placer.meadow_center = meadow_center
	placer.meadow_radius = meadow_radius
	placer.solid_from = float(scatter.get("solid_from", 0.55))
	for _s in ROCK_SHAPES:
		placer.buffers.append(PackedFloat32Array())
	# Öbekler.
	for row: Array in scatter.get("rock_clusters", []):
		var center := Vector2(float(row[0]), float(row[1]))
		for _i in int(row[3]):
			var p := center + Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * float(row[2])
			# Büyük taşlar öbeğin ortasında.
			var near := 1.0 - p.distance_to(center) / maxf(float(row[2]), 0.01)
			var size := lerpf(float(row[4]), float(row[5]), pow(rng.randf(), 1.6) * (0.45 + near * 0.55))
			placer.add(p, size, rng.randf() < 0.35, rng.randf() * TAU)
	# Kademe yüzleri: yüzün boyunca yassı taşlar (yukarıdan tabaka gibi okunur).
	for s: Dictionary in ground_def.get("scarps", []):
		var line := ChildhoodGround.Line.new(s.get("points", []), s)
		var along := 0.0
		var width := float(s.get("width", 3.0))
		var height := float(s.get("height", 2.0))
		while along < line.total:
			along += rng.randf_range(1.0, 2.8)
			var at := _point_along(line, along)
			var dir: Vector2 = at[1]
			var side := Vector2(-dir.y, dir.x)
			var p: Vector2 = at[0] + side * rng.randf_range(-width * 0.7, width * 0.7)
			var size := rng.randf_range(0.28, 0.65) * (0.7 + height * 0.3)
			if rng.randf() < 0.1:
				size *= 1.7
			if rng.randf() < 0.72:
				placer.add(p, size, true, atan2(dir.x, dir.y) + rng.randf_range(-0.5, 0.5))
	# Tepelerin sırtı.
	for row: Array in ground_def.get("hills", []):
		var center := Vector2(float(row[0]), float(row[1]))
		var r := float(row[2])
		for _i in int(r * 1.4):
			var p := center + Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * r * 0.62
			placer.add(p, rng.randf_range(0.25, 0.8) * (0.7 + float(row[3]) * 0.25), rng.randf() < 0.5, rng.randf() * TAU)
	# Çakıl taşları: otun arasında küçük, seyrek taşlar (yukarıdan zemine ayrıntı verir).
	var pebble_def: Dictionary = scatter.get("pebbles", {})
	var pebble_center := OrdosGround._vec2((d.get("grass", {}) as Dictionary).get("center", [0.0, 0.0]))
	for _i in int(pebble_def.get("count", 0)):
		var p := pebble_center + Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * float(pebble_def.get("radius", 80.0))
		placer.add_pebble(p, rng.randf_range(0.08, 0.22), rng.randf() * TAU)
	# Çalılar.
	var shrub_def: Dictionary = scatter.get("shrubs", {})
	var count := int(shrub_def.get("count", 300))
	var radius := float(shrub_def.get("radius", 90.0))
	var center_all := OrdosGround._vec2((d.get("grass", {}) as Dictionary).get("center", [0.0, 0.0]))
	var anchors := PackedVector2Array()
	for row: Array in scatter.get("rock_clusters", []):
		anchors.append(Vector2(float(row[0]), float(row[1])))
	for g: Dictionary in ground_def.get("gullies", []):
		var line := ChildhoodGround.Line.new(g.get("points", []), g)
		var along := 0.0
		while along < line.total:
			along += 5.0
			var at := _point_along(line, along)
			var dir: Vector2 = at[1]
			var offset := (float(g.get("width", 3.0)) * 0.5 + float(g.get("bank", 3.0))) * (1.0 if int(along / 5.0) % 2 == 0 else -1.0)
			anchors.append(at[0] + Vector2(-dir.y, dir.x) * offset)
	var sage := PackedFloat32Array()
	var karagan := PackedFloat32Array()
	var placed := 0
	var cluster_share := float(shrub_def.get("cluster_share", 0.55))
	for _i in count * 3:
		if placed >= count:
			break
		var p: Vector2
		if rng.randf() < cluster_share and not anchors.is_empty():
			var a := anchors[rng.randi() % anchors.size()]
			p = a + Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * 5.0
		else:
			p = center_all + Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * radius
		var size := rng.randf_range(0.7, 1.45)
		if _blocked(p, size * 0.6, keep_out, shape, route):
			continue
		if not mask.is_empty():
			var m := ChildhoodGround.mask_at(mask, p.x, p.y)
			if m.y > 0.4 or (m.z > 0.75 and rng.randf() < 0.5):
				continue
		var yaw := rng.randf() * TAU
		var y := shape.height_at(p.x, p.y) - 0.03
		var cs := cos(yaw) * size
		var sn := sin(yaw) * size
		var row := PackedFloat32Array([cs, 0.0, sn, p.x, 0.0, size, 0.0, y, -sn, 0.0, cs, p.y, rng.randf(), rng.randf(), 0.0, 0.0])
		if rng.randf() < 0.3:
			karagan.append_array(row)
		else:
			sage.append_array(row)
		placed += 1
	# E21 (K110): Kamışlı Göl'ün ve Ebe Obası'nın yolları kendi tohumuyla (bugünkü yerleşim değişmez: doğumun kayası ve çalısı yerinde kalır):
	# kaya öbekleri, kademe yüzleri ve tepeler (*_e21), yollar boyunca çalı (shrubs.zones), kuruyan derenin kıyısında çalı, gölün önünde ılgın kuşağı.
	var e21_shrubs := {}
	# Doğumun dağıtımında (spec "e21_scatter": false; OrdosWorld.birth_spec) E21'inki yok.
	var tamarisk := PackedFloat32Array()
	if bool(spec.get("e21_scatter", true)):
		tamarisk = _scatter_e21(spec, shape, placer, e21_shrubs, int(scatter.get("seed", 730)) + 2100)
	var rock_rows: Array[Dictionary] = []
	for k in ROCK_SHAPES.size():
		var buffer: PackedFloat32Array = placer.buffers[k]
		if not buffer.is_empty():
			rock_rows.append({"arrays": rock_arrays(int(scatter.get("seed", 730)) + k * 11, ROCK_SHAPES[k]), "buffer": buffer})
	var keys: Array = placer.region_buffers.keys()
	keys.sort()
	for key: Vector2i in keys:
		rock_rows.append({"arrays": rock_arrays(int(scatter.get("seed", 730)) + key.y * 11, ROCK_SHAPES[key.y]), "buffer": placer.region_buffers[key], "region": key.x})
	if not placer.pebbles.is_empty():
		rock_rows.append({"arrays": rock_arrays(int(scatter.get("seed", 730)) + 97, Vector3(1.0, 0.55, 0.85), 1), "buffer": placer.pebbles, "pebbles": true})
	var shrub_rows: Array = [{"arrays": sage_arrays(), "buffer": sage}, {"arrays": karagan_arrays(), "buffer": karagan}]
	var shrub_keys: Array = e21_shrubs.keys()
	shrub_keys.sort()
	for key: Vector2i in shrub_keys:
		shrub_rows.append({"arrays": sage_arrays() if key.y == 0 else karagan_arrays(), "buffer": e21_shrubs[key], "region": key.x})
	if not tamarisk.is_empty():
		shrub_rows.append({"arrays": tamarisk_arrays(), "buffer": tamarisk, "region": 0})
	return {
		"rocks": rock_rows,
		"shrubs": shrub_rows,
		"solid": placer.solid,
		"counts": {"rocks": placer.rocks, "shrubs": _rows_count(shrub_rows)},
	}


## E21'in dağıtımı (saf; kendi tohumu): kaya (rock_clusters_e21, scarps_e21, hills_e21), çalı (shrubs.zones [x, z, r, adet], gullies_e21'in kıyısı) ve
## ılgın (lake_site.tamarisks: çizgi boyunca kuşak, yolun geçtiği aralıklar boş). Suda, yolda ve yasak yerde bir şey durmaz. Döner: ılgının tamponu.
static func _scatter_e21(spec: Dictionary, shape: OrdosGround, placer: _Placer, shrubs: Dictionary, seed_value: int) -> PackedFloat32Array:
	var d: Dictionary = spec.get("childhood", {})
	var scatter: Dictionary = d.get("scatter", {})
	var ground_def: Dictionary = d.get("ground", {})
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var base_rng := placer.rng
	placer.rng = rng
	placer.e21 = true
	var tracks: Array[ChildhoodGround.Line] = []
	for t: Variant in ground_def.get("tracks", []):
		if t is Dictionary:
			tracks.append(ChildhoodGround.Line.new((t as Dictionary).get("points", []), t))
	placer.tracks = tracks
	for row: Array in scatter.get("rock_clusters_e21", []):
		var center := Vector2(float(row[0]), float(row[1]))
		for _i in int(row[3]):
			var p := center + Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * float(row[2])
			var near := 1.0 - p.distance_to(center) / maxf(float(row[2]), 0.01)
			placer.add(p, lerpf(float(row[4]), float(row[5]), pow(rng.randf(), 1.6) * (0.45 + near * 0.55)), rng.randf() < 0.35, rng.randf() * TAU)
	for sd: Dictionary in ground_def.get("scarps_e21", []):
		var line := ChildhoodGround.Line.new(sd.get("points", []), sd)
		var along := 0.0
		var width := float(sd.get("width", 3.0))
		var height := float(sd.get("height", 2.0))
		while along < line.total:
			along += rng.randf_range(1.2, 3.2)
			var at := _point_along(line, along)
			var dir: Vector2 = at[1]
			var p: Vector2 = at[0] + Vector2(-dir.y, dir.x) * rng.randf_range(-width * 0.7, width * 0.7)
			if rng.randf() < 0.7:
				placer.add(p, rng.randf_range(0.28, 0.65) * (0.7 + height * 0.3), true, atan2(dir.x, dir.y) + rng.randf_range(-0.5, 0.5))
	for row: Array in ground_def.get("hills_e21", []):
		var center := Vector2(float(row[0]), float(row[1]))
		var r := float(row[2])
		for _i in int(r * 1.2):
			var p := center + Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * r * 0.62
			placer.add(p, rng.randf_range(0.25, 0.8) * (0.7 + float(row[3]) * 0.25), rng.randf() < 0.5, rng.randf() * TAU)
	# Çalı: yollar boyunca ve kuruyan derenin kıyısında.
	var anchors := PackedVector2Array()
	for g: Dictionary in ground_def.get("gullies_e21", []):
		var line := ChildhoodGround.Line.new(g.get("points", []), g)
		var along := 0.0
		while along < line.total:
			along += 6.0
			var at := _point_along(line, along)
			var dir: Vector2 = at[1]
			var off := (float(g.get("width", 3.0)) * 0.5 + float(g.get("bank", 3.0))) * (1.0 if int(along / 6.0) % 2 == 0 else -1.0)
			anchors.append(at[0] + Vector2(-dir.y, dir.x) * off)
	var spots: Array[Vector3] = []
	for row: Array in (scatter.get("shrubs", {}) as Dictionary).get("zones", []):
		for _i in int(row[3]):
			spots.append(Vector3(float(row[0]), float(row[1]), float(row[2])))
	for a in anchors:
		spots.append(Vector3(a.x, a.y, 4.0))
	for c in spots:
		var p := Vector2(c.x, c.y) + Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * c.z
		var size := rng.randf_range(0.7, 1.45)
		if placer.blocked_e21(p, size * 0.6):
			continue
		var row := _shrub_row(p, size, rng.randf() * TAU, shape, rng)
		var key := Vector2i(region_of(p), 1 if rng.randf() < 0.32 else 0)
		var buffer: PackedFloat32Array = shrubs.get(key, PackedFloat32Array())
		shrubs.erase(key)
		buffer.append_array(row)
		shrubs[key] = buffer
	# Ilgın kuşağı (gölün önünde): çizginin iki yanına width/2, aralıklarda yok.
	var tam: Dictionary = (d.get("lake_site", {}) as Dictionary).get("tamarisks", {})
	var out := PackedFloat32Array()
	if not tam.is_empty():
		var line := ChildhoodGround.Line.new(tam.get("line", []))
		var gaps: Array = tam.get("gaps", [])
		var size_range := OrdosGround._vec2(tam.get("size", [1.4, 2.6]))
		var trng := RandomNumberGenerator.new()
		trng.seed = int(tam.get("seed", 616))
		for _i in int(tam.get("count", 60)) * 3:
			if out.size() / SHRUB_FLOATS >= int(tam.get("count", 60)):
				break
			var at := _point_along(line, trng.randf() * line.total)
			var dir: Vector2 = at[1]
			var p: Vector2 = at[0] + Vector2(-dir.y, dir.x) * trng.randf_range(-0.5, 0.5) * float(tam.get("width", 16.0))
			var in_gap := false
			for g: Array in gaps:
				if p.distance_to(Vector2(float(g[0]), float(g[1]))) < float(g[2]):
					in_gap = true
					break
			var size := trng.randf_range(size_range.x, size_range.y)
			if in_gap or placer.blocked_e21(p, size * 0.4):
				continue
			out.append_array(_shrub_row(p, size, trng.randf() * TAU, shape, trng))
	placer.rng = base_rng
	placer.e21 = false
	return out


## E21'in bölgesi (saf): 1 kuzey (obaya giden yol), 0 doğu (göle giden yol ve göl).
static func region_of(p: Vector2) -> int:
	return 1 if p.y < -90.0 and p.x < 120.0 else 0


static func _rows_count(rows: Array) -> int:
	var n := 0
	for row: Dictionary in rows:
		n += (row["buffer"] as PackedFloat32Array).size() / SHRUB_FLOATS
	return n


## Çalının MultiMesh satırı (dönüşüm + özel veri).
static func _shrub_row(p: Vector2, size: float, yaw: float, shape: OrdosGround, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var y := shape.height_at(p.x, p.y) - 0.03
	var cs := cos(yaw) * size
	var sn := sin(yaw) * size
	return PackedFloat32Array([cs, 0.0, sn, p.x, 0.0, size, 0.0, y, -sn, 0.0, cs, p.y, rng.randf(), rng.randf(), 0.0, 0.0])


## Ilgın (E21): ince dallar kökten yelpaze gibi açılır, uçlarda tüylü, pembe çiçekli salkımlar; gümüşümsü yeşil (ağ boyu ≈1 m; ölçek
## 1,4–2,6 m'ye büyütür).
static func tamarisk_arrays() -> Dictionary:
	var d := FaunaMesh.Draft.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 619
	for i in 11:
		var a := TAU * float(i) / 11.0 + rng.randf() * 0.4
		var lean := rng.randf_range(0.18, 0.42)
		var tip := Vector3(cos(a) * lean, rng.randf_range(0.72, 1.0), sin(a) * lean)
		var mid := tip * 0.5 + Vector3(rng.randf_range(-0.04, 0.04), 0.02, rng.randf_range(-0.04, 0.04))
		d.tube(PackedVector3Array([Vector3(cos(a) * 0.03, 0.0, sin(a) * 0.03), mid, tip]), PackedFloat32Array([0.02, 0.012, 0.004]), 3, TAMARISK_BARK, Vector4.ZERO)
		d.blob(tip, Vector3(0.12, 0.16, 0.12), Basis(Vector3.UP, a), 0, TAMARISK_PLUME if i % 3 == 0 else TAMARISK_LEAF, Vector4.ZERO)
		d.blob(mid + Vector3(0.0, 0.12, 0.0), Vector3(0.1, 0.12, 0.1), Basis(Vector3.UP, a + 1.0), 0, TAMARISK_LEAF.darkened(0.08), Vector4.ZERO)
	return d.arrays()


## Kaya yerleştirici: engel ve yasak yerlere bakar, biçim seçer, tampona yazar.
class _Placer:
	extends RefCounted
	var rng: RandomNumberGenerator
	var shape: OrdosGround
	var keep_out: Array[Vector3] = []
	var route := PackedVector2Array()
	var meadow_center := Vector2.ZERO
	var meadow_radius := 0.0
	var solid_from := 0.55
	var buffers: Array[PackedFloat32Array] = []
	var pebbles := PackedFloat32Array()
	var solid: Array[Vector3] = []
	var rocks := 0
	## E21: yolların çizgileri (bu yollarda kaya ve çalı durmaz) ve E21'in kayaları bölge başına ayrı tamponlarda (doğu: göle giden yol ve göl;
	## kuzey: obaya giden yol): MultiMesh'in kutusu kendi bölgesini tutar, kampın gölge basamaklarına girmez (K63).
	var tracks: Array[ChildhoodGround.Line] = []
	var e21 := false
	var region_buffers: Dictionary = {}

	## E21'in dağıtımında yasak yer: bugünkü yasaklar, su (göl), yollar.
	func blocked_e21(p: Vector2, size: float) -> bool:
		if ChildhoodScatter._blocked(p, size, keep_out, shape, route):
			return true
		if shape.lake_half_width > 0.0 and shape.lake_distance(p.x, p.y) < shape.lake_half_width + 1.5 + size:
			return true
		for line in tracks:
			if line.box.grow(4.0).has_point(p) and line.nearest(p).x < float(line.def.get("width", 1.0)) * 0.5 + size + 0.6:
				return true
		return false

	func add(p: Vector2, size: float, slab: bool, yaw: float) -> void:
		if ChildhoodScatter._blocked(p, size, keep_out, shape, route):
			return
		if not tracks.is_empty() and blocked_e21(p, size):
			return
		if size > 0.45 and p.distance_to(meadow_center) < meadow_radius:
			return
		var kind := (1 if rng.randf() < 0.6 else 3) if slab else rng.randi() % ROCK_SHAPES.size()
		var y := shape.height_at(p.x, p.y) - size * 0.12
		if e21:
			var key := Vector2i(ChildhoodScatter.region_of(p), kind)
			var rb: PackedFloat32Array = region_buffers.get(key, PackedFloat32Array())
			region_buffers.erase(key)
			ChildhoodScatter._append_rock(rb, p, y, size, yaw, rng)
			region_buffers[key] = rb
		else:
			var buffer := buffers[kind]
			ChildhoodScatter._append_rock(buffer, p, y, size, yaw, rng)
			buffers[kind] = buffer
		rocks += 1
		if size >= solid_from:
			solid.append(Vector3(p.x, p.y, size * 0.72))

	## Çakıl: seyrek ağ (80 üçgen), çarpışmaz; izden ve yasak yerlerden uzak.
	func add_pebble(p: Vector2, size: float, yaw: float) -> void:
		if ChildhoodScatter._blocked(p, size, keep_out, shape, route):
			return
		ChildhoodScatter._append_rock(pebbles, p, shape.height_at(p.x, p.y) - size * 0.2, size, yaw, rng)
		rocks += 1


## Uzak durulan yerler (saf): Vector3(x, z, yarıçap): yurtlar, ağıl, taş, avın lekeleri ve inler, sürünün diski dışındakiler.
static func keep_outs(spec: Dictionary) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for b in ChildhoodSite.grass_blockers(spec):
		out.append(Vector3(b.x, b.y, b.z + 1.0))
	var d: Dictionary = spec.get("childhood", {})
	var pen: Dictionary = d.get("pen", {})
	if not pen.is_empty():
		var at := OrdosGround._vec2(pen.get("at", [0.0, 0.0]))
		out.append(Vector3(at.x, at.y, float(pen.get("radius", 8.0)) + 2.0))
	return out


## Rock ağı (saf): yontulmuş ikosfer; UV.y yükseklik (atw_rock). Boy ≈1 birimdir, taban y≈0.
static func rock_arrays(seed_value: int, shape: Vector3, subdivisions: int = 2) -> Dictionary:
	var out := {"vertices": PackedVector3Array(), "normals": PackedVector3Array(), "uvs": PackedVector2Array(), "indices": PackedInt32Array()}
	ChildhoodSite._add_rock(out, Vector3(0.0, shape.y * 0.42, 0.0), shape * 0.5, Basis.IDENTITY, subdivisions, seed_value, 0.0, shape.y)
	return out


## Pelin: dibi koyu, tepesi gümüşümsü, yuvarlak küme (ağ boyu ≈1 m genişlik, 0,55 m yükseklik).
static func sage_arrays() -> Dictionary:
	var d := FaunaMesh.Draft.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	var paint := func(v: Vector3, _n: Vector3) -> Color:
		return SAGE_DARK.lerp(SAGE_LIGHT, clampf(v.y / 0.5, 0.0, 1.0))
	for i in 13:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * 0.4
		var y := 0.12 + (0.42 - r) * rng.randf_range(0.5, 0.85)
		var size := rng.randf_range(0.11, 0.2)
		d.blob(Vector3(cos(a) * r, y, sin(a) * r), Vector3(size, size * 0.85, size), Basis(Vector3.UP, a), 0, paint, Vector4.ZERO)
	return d.arrays()


## Karagan: kuru, dallı; ince dallar kökten açılır, uçlarda seyrek yaprak (ağ boyu ≈1,2 m genişlik, 0,9 m yükseklik).
static func karagan_arrays() -> Dictionary:
	var d := FaunaMesh.Draft.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 137
	for i in 9:
		var a := TAU * float(i) / 9.0 + rng.randf() * 0.5
		var lean := rng.randf_range(0.28, 0.6)
		var tip := Vector3(cos(a) * lean, rng.randf_range(0.55, 0.92), sin(a) * lean)
		var mid := tip * 0.55 + Vector3(rng.randf_range(-0.05, 0.05), 0.04, rng.randf_range(-0.05, 0.05))
		d.tube(PackedVector3Array([Vector3(cos(a) * 0.03, 0.0, sin(a) * 0.03), mid, tip]), PackedFloat32Array([0.022, 0.014, 0.005]), 3, KARAGAN_BARK, Vector4.ZERO)
		# Yan dal ve uçta seyrek yaprak öbeği.
		var side := mid + Vector3(cos(a + 1.2), 0.3, sin(a + 1.2)) * rng.randf_range(0.18, 0.3)
		d.tube(PackedVector3Array([mid, side]), PackedFloat32Array([0.01, 0.004]), 3, KARAGAN_BARK, Vector4.ZERO)
		d.blob(tip, Vector3(0.1, 0.07, 0.1), Basis.IDENTITY, 0, KARAGAN_LEAF, Vector4.ZERO)
		if i % 2 == 0:
			d.blob(side, Vector3(0.08, 0.055, 0.08), Basis.IDENTITY, 0, KARAGAN_LEAF.darkened(0.12), Vector4.ZERO)
	return d.arrays()


static func _blocked(p: Vector2, size: float, keep_out: Array[Vector3], shape: OrdosGround, route: PackedVector2Array) -> bool:
	for c in keep_out:
		var r := c.z + size
		if p.distance_squared_to(Vector2(c.x, c.y)) < r * r:
			return true
	if shape.trampled_distance(p) < size + 0.6:
		return true
	for i in route.size() - 1:
		if Geometry2D.get_closest_point_to_segment(p, route[i], route[i + 1]).distance_to(p) < size + 1.6:
			return true
	return false


## Polilinin boyunca nokta ve yön: [Vector2, Vector2].
static func _point_along(line: ChildhoodGround.Line, along: float) -> Array:
	var points := line.points
	for i in points.size() - 1:
		if along <= line.cumulative[i + 1] or i == points.size() - 2:
			var a := points[i]
			var b := points[i + 1]
			var seg := maxf(line.cumulative[i + 1] - line.cumulative[i], 0.001)
			return [a.lerp(b, clampf((along - line.cumulative[i]) / seg, 0.0, 1.0)), (b - a).normalized()]
	return [points[0], Vector2.RIGHT]


static func _append_rock(buffer: PackedFloat32Array, p: Vector2, y: float, size: float, yaw: float, rng: RandomNumberGenerator) -> void:
	var tilt := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, rng.randf_range(-0.14, 0.14)) * Basis(Vector3.FORWARD, rng.randf_range(-0.14, 0.14))
	var b := tilt.scaled(Vector3.ONE * size * rng.randf_range(1.6, 2.1))
	buffer.append_array(PackedFloat32Array([b.x.x, b.y.x, b.z.x, p.x, b.x.y, b.y.y, b.z.y, y, b.x.z, b.y.z, b.z.z, p.y]))
