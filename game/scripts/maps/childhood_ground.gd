class_name ChildhoodGround
extends RefCounted
## Çocukluk'un yukarıdan okunan zemini (saf; K98: kadraj 38°, 22–40 m; layout.json "childhood.ground"): yer kademesi, tepecik, kuru dere ve hafif dalgayı bir yükseklik
## ızgarasına, toprak, kum, çakıl ve koyu otluğu bir maskeye pişirir. Düğüm kurmaz: WorkerThreadPool'da koşar. Yükseklik ızgarası OrdosGround'un "ground_relief"idir
## (yalnız Çocukluk'un yüzü okur; doğumun yüzü değişmez), maske zeminin gölgelendiricisine (childhood_ground.gdshader), otun sıklığına ve kaya, çalı dağıtımına gider.
##
## Yurtların, sayım hattının çevresi sakindir (quiet): orada yükselti sıfırdır, doğumun düğümleri aynı yerde durur. Ağıl düz yerdir (childhood.flats).
##
## Maske RGBA8, metre başına bir örnek: R açık toprak, G kum (dere yatağı, çorak), B çakıl (kademe yüzü, tepe, kaya öbeği), A koyu otluk (dere kıyısı, yüzün dibi, lekeler).
## Doğum aynı otlaktır (MÖ 234 ile MÖ 228): aynı yükselti, aynı kum, çakıl ve koyu otluk; doğumun maskesinde (mask_birth) Çocukluk'un izleri (ağıla, çayıra,
## yarış yolu) ve onlara bağlı patikalar yoktur, doğumun çiğnenmiş toprağının kenarı ve kendi patikaları (birth_tracks) vardır.
## Izgara satır bantlarıyla da pişer (bake_rows, join_rows: iş parçacığı başına bir bant): sonuç tek parçalı pişirmeyle aynıdır.

const BLOCK := 8
## Bir yükselti ya da maske ızgarasının yapısı: {data, origin: Vector2, step, w, h}.


## Bir polilinin ön hesabı.
class Line:
	extends RefCounted
	var points := PackedVector2Array()
	var cumulative := PackedFloat32Array()
	var total := 0.0
	var box := Rect2()
	var def: Dictionary = {}

	func _init(raw: Array, p_def: Dictionary = {}) -> void:
		def = p_def
		for p: Variant in raw:
			points.append(OrdosGround._vec2(p))
		cumulative.resize(points.size())
		box = Rect2(points[0], Vector2.ZERO)
		for i in points.size():
			box = box.expand(points[i])
			if i > 0:
				total += points[i].distance_to(points[i - 1])
			cumulative[i] = total

	## En yakın nokta: Vector3(uzaklık, boyunca, işaretli yan; sol +, sağ −).
	func nearest(p: Vector2) -> Vector3:
		var best := INF
		var along := 0.0
		var side := 1.0
		for i in points.size() - 1:
			var a := points[i]
			var ab := points[i + 1] - a
			var len2 := ab.length_squared()
			var t := clampf((p - a).dot(ab) / maxf(len2, 0.0001), 0.0, 1.0)
			var q := a + ab * t
			var d := p.distance_squared_to(q)
			if d < best:
				best = d
				along = cumulative[i] + sqrt(len2) * t
				side = signf(ab.x * (p.y - a.y) - ab.y * (p.x - a.x))
		return Vector3(sqrt(best), along, side if side != 0.0 else 1.0)


## Yükselti ve maskeyi pişirir: {relief: ızgara, mask: ızgara}; birth true ise doğumun maskesi de (mask_birth). Bölüm yoksa boş.
## E21 (K110): extended true ise Çocukluk'un geniş ızgarası (ground.area_e21: göle ve Ebe Obası'na dek; ChildhoodSite pişirir), değilse doğumun
## ve kampın ızgarası (ground.area; OrdosWorld doğumla birlikte pişirir).
static func bake(layout: Dictionary, birth: bool = false, extended: bool = false) -> Dictionary:
	var g := grid(layout, extended)
	if g.is_empty():
		return {}
	return join_rows(g, [bake_rows(layout, 0, int(g["h"]), birth, extended)], birth)


## Izgaranın ölçüsü (saf): {origin: Vector2, step, w, h}. Bölüm yoksa boş.
static func grid(layout: Dictionary, extended: bool = false) -> Dictionary:
	var def: Dictionary = (layout.get("childhood", {}) as Dictionary).get("ground", {})
	if def.is_empty():
		return {}
	var area: Dictionary = def.get("area_e21", {}) if extended and def.has("area_e21") else def.get("area", {})
	var origin := OrdosGround._vec2(area.get("min", [-120.0, -120.0]))
	var far_corner := OrdosGround._vec2(area.get("max", [120.0, 120.0]))
	var step := float(def.get("step", 1.0))
	return {"origin": origin, "step": step, "w": int((far_corner.x - origin.x) / step) + 1, "h": int((far_corner.y - origin.y) / step) + 1}


## Izgaranın satır bantları (saf): count banda bölünmüş [başlangıç, bitiş) satırlar; her bant BLOCK katından başlar (bloklar bölünmez).
static func row_bands(g: Dictionary, count: int) -> Array[Vector2i]:
	var h := int(g.get("h", 0))
	var blocks := ceili(float(h) / float(BLOCK))
	var out: Array[Vector2i] = []
	var n := clampi(count, 1, maxi(blocks, 1))
	for k in n:
		var a := (blocks * k / n) * BLOCK
		var b := mini((blocks * (k + 1) / n) * BLOCK, h)
		if b > a:
			out.append(Vector2i(a, b))
	return out


## Bantların sonuçlarını sırayla birleştirir: bake'in biçimi ({relief, mask} ve birth ise mask_birth).
static func join_rows(g: Dictionary, parts: Array, birth: bool = false) -> Dictionary:
	var relief := PackedFloat32Array()
	var mask := PackedByteArray()
	var mask_birth := PackedByteArray()
	for part: Dictionary in parts:
		relief.append_array(part["relief"])
		mask.append_array(part["mask"])
		if birth:
			mask_birth.append_array(part["mask_birth"])
	var out := {
		"relief": {"data": relief, "origin": g["origin"], "step": g["step"], "w": g["w"], "h": g["h"]},
		"mask": {"data": mask, "origin": g["origin"], "step": g["step"], "w": g["w"], "h": g["h"]},
	}
	if birth:
		out["mask_birth"] = {"data": mask_birth, "origin": g["origin"], "step": g["step"], "w": g["w"], "h": g["h"]}
	return out


## Izgaranın [row_from, row_to) satırlarını pişirir (saf; iş parçacığında, row_from BLOCK katı): {relief, mask} ve birth ise mask_birth
## (yalnız bu satırların dizileri; join_rows birleştirir).
static func bake_rows(layout: Dictionary, row_from: int, row_to: int, birth: bool = false, extended: bool = false) -> Dictionary:
	var child: Dictionary = layout.get("childhood", {})
	var def: Dictionary = child.get("ground", {})
	var gr := grid(layout, extended)
	var origin: Vector2 = gr["origin"]
	var step: float = gr["step"]
	var w: int = gr["w"]
	var h: int = mini(int(gr["h"]), row_to)
	var far_corner := origin + Vector2(float(w - 1), float(int(gr["h"]) - 1)) * step
	var rows := maxi(h - row_from, 0)
	var relief := PackedFloat32Array()
	relief.resize(w * rows)
	var mask := PackedByteArray()
	mask.resize(w * rows * 4)
	var mask_b := PackedByteArray()
	if birth:
		mask_b.resize(w * rows * 4)
	var seed_value := int(def.get("seed", 613))
	var undulation: Dictionary = def.get("undulation", {})
	var wave := OrdosGround._noise(seed_value, 1.0 / maxf(float(undulation.get("wavelength", 13.0)), 1.0), 2)
	var wave_amp := float(undulation.get("amplitude", 0.3))
	var warp := OrdosGround._noise(seed_value + 3, 0.06, 2)
	var bare_big := OrdosGround._noise(seed_value + 5, 0.045, 3)
	var bare_small := OrdosGround._noise(seed_value + 7, 0.2, 2)
	var lush_noise := OrdosGround._noise(seed_value + 11, 0.07, 3)
	var pale_noise := OrdosGround._noise(seed_value + 13, 0.16, 2)
	# E21: Kamışlı Göl'ün ve Ebe Obası'nın yolları için eklenenler (*_e21) yükseltide ve maskede bugünkülerle birlikte okunur.
	var scarps: Array[Line] = []
	for s: Dictionary in (def.get("scarps", []) as Array) + (def.get("scarps_e21", []) as Array):
		scarps.append(Line.new(s.get("points", []), s))
	var gullies: Array[Line] = []
	for g: Dictionary in (def.get("gullies", []) as Array) + (def.get("gullies_e21", []) as Array):
		gullies.append(Line.new(g.get("points", []), g))
	var tracks: Array[Line] = []
	for t: Variant in def.get("tracks", []):
		# E21: iz ya da {points, width} (geniş yol: göle ve obaya giden).
		if t is Dictionary:
			tracks.append(Line.new((t as Dictionary).get("points", []), t))
		else:
			tracks.append(Line.new(t))
	# Doğumun patikaları ve çiğnenmiş toprağı (Çocukluk'un izleri yok).
	var birth_tracks: Array[Line] = []
	var birth_paths: OrdosGround = null
	if birth:
		for t: Array in def.get("birth_tracks", []):
			birth_tracks.append(Line.new(t))
		birth_paths = OrdosGround.new(layout)
	var hills: Array = (def.get("hills", []) as Array) + (def.get("hills_e21", []) as Array)
	var pans: Array = def.get("pale_pans", [])
	var clusters: Array = ((child.get("scatter", {}) as Dictionary).get("rock_clusters", []) as Array) + ((child.get("scatter", {}) as Dictionary).get("rock_clusters_e21", []) as Array)
	var quiet_circles := quiet_zones(layout)
	var line_def: Dictionary = layout.get("counting_line", {})
	var line_a := OrdosGround._vec2(line_def.get("from", [0.0, 0.0]))
	var line_b := OrdosGround._vec2(line_def.get("to", [0.0, 0.0]))
	var quiet: Dictionary = def.get("quiet", {})
	var line_margin := float(quiet.get("line_margin", 5.0))
	var line_fade := float(quiet.get("line_fade", 8.0))
	var path_shape := OrdosGround.new(ChildhoodSite.merged_spec(layout))
	var edge_size := 18.0
	# E21: gölün yüzü (yalnız orta çizgi ve kıyı ölçüsü) ve balçık lekeleri [x, z, yarıçap].
	var lake_shape: OrdosGround = path_shape if path_shape.lake_half_width > 0.0 else null
	var lake_muds: Array = (((child.get("lake_site", {}) as Dictionary).get("mud", {}) as Dictionary).get("patches", []) as Array)

	for bj in range(row_from, h, BLOCK):
		for bi in range(0, w, BLOCK):
			var block := Rect2(origin + Vector2(float(bi), float(bj)) * step, Vector2.ONE * float(BLOCK) * step)
			var near_scarps := _filter(scarps, block, 34.0)
			var near_gullies := _filter(gullies, block, 12.0)
			var near_tracks := _filter(tracks, block, 3.0)
			var near_hills := _filter_circles(hills, block)
			var near_pans := _filter_circles(pans, block, 1.0, 5.0)
			var near_clusters := _filter_circles(clusters, block, 1.8, 3.0)
			var near_trails := path_shape.trampled_distance(block.get_center()) < 3.2 + float(BLOCK) * step
			var near_birth_tracks := _filter(birth_tracks, block, 3.0)
			var near_birth_trails := birth and birth_paths.trampled_distance(block.get_center()) < 3.2 + float(BLOCK) * step
			for j in range(bj, mini(bj + BLOCK, h)):
				for i in range(bi, mini(bi + BLOCK, w)):
					var p := origin + Vector2(float(i), float(j)) * step
					# Sakinlik: yurtların ve hattın çevresinde yükselti yok; alanın kenarında sıfıra iner.
					var calm := 1.0
					for c in quiet_circles:
						var d := p.distance_to(Vector2(c.x, c.y)) - c.z
						if d < c.w:
							calm = minf(calm, smoothstep(0.0, c.w, d))
					var to_line := Geometry2D.get_closest_point_to_segment(p, line_a, line_b).distance_to(p) - line_margin
					if to_line < line_fade:
						calm = minf(calm, smoothstep(0.0, line_fade, to_line))
					var edge := minf(minf(p.x - origin.x, far_corner.x - p.x), minf(p.y - origin.y, far_corner.y - p.y))
					var fade := smoothstep(0.0, edge_size, edge)
					var wobble := warp.get_noise_2dv(p)
					var rise := wave.get_noise_2dv(p) * wave_amp
					var gravel := 0.0
					var lush := 0.0
					var pale := 0.0
					# Kademeler: yüz dik, sırt uzun; uçları incelir.
					for line in near_scarps:
						var q := line.nearest(p)
						var s: float = q.x * q.z * float(line.def.get("side", 1.0)) + wobble * 2.4
						var width := float(line.def.get("width", 3.0))
						var back := float(line.def.get("back", 20.0))
						var taper := smoothstep(0.0, 9.0, minf(q.y, line.total - q.y))
						var up := smoothstep(-width * 0.5, width * 0.5, s) * (1.0 - smoothstep(width * 0.5, back, s))
						rise += float(line.def.get("height", 2.0)) * up * taper
						var face := (1.0 - smoothstep(0.0, width * 0.55, absf(s))) * taper * 0.85
						gravel = maxf(gravel, face)
						if s < -width * 0.5:
							lush = maxf(lush, (1.0 - smoothstep(width * 0.5, width * 0.5 + 7.0, -s)) * 0.85 * taper)
					# Tepecikler.
					for row: Array in near_hills:
						var center := Vector2(float(row[0]), float(row[1]))
						var r := float(row[2])
						var d2 := p.distance_squared_to(center)
						if d2 < r * r:
							var t := 1.0 - sqrt(d2) / r
							rise += float(row[3]) * smoothstep(0.0, 0.75, t + wobble * 0.08)
							gravel = maxf(gravel, smoothstep(0.55, 0.9, t) * 0.6)
					# Kuru dere: taban kum, kıyıda çakıl ve koyu ot.
					for line in near_gullies:
						var q := line.nearest(p)
						var d: float = q.x + wobble * 1.1
						var half := float(line.def.get("width", 3.0)) * 0.5
						var bank := float(line.def.get("bank", 3.0))
						rise -= float(line.def.get("depth", 1.0)) * (1.0 - smoothstep(half, half + bank, d))
						pale = maxf(pale, 1.0 - smoothstep(half - 0.6, half + 0.3, d))
						gravel = maxf(gravel, (1.0 - smoothstep(0.0, 0.9, absf(d - (half + bank * 0.4)))) * 0.4)
						lush = maxf(lush, (1.0 - smoothstep(0.0, 2.8, absf(d - (half + bank + 1.0)))) * 0.9)
					var local := (j - row_from) * w + i
					relief[local] = rise * calm * fade
					# Maske.
					var bare := smoothstep(0.2, 0.5, bare_big.get_noise_2dv(p) * 0.75 + bare_small.get_noise_2dv(p) * 0.35)
					lush = maxf(lush, smoothstep(0.08, 0.42, lush_noise.get_noise_2dv(p)) * 0.8)
					for row: Array in near_pans:
						var d := p.distance_to(Vector2(float(row[0]), float(row[1])))
						pale = maxf(pale, 1.0 - smoothstep(float(row[2]) * 0.6, float(row[2]), d + pale_noise.get_noise_2dv(p) * 4.0))
					for row: Array in near_clusters:
						var d := p.distance_to(Vector2(float(row[0]), float(row[1])))
						gravel = maxf(gravel, (1.0 - smoothstep(float(row[2]) * 0.35, float(row[2]) * 1.15, d + wobble * 1.6)) * 0.75)
					# E21: Kamışlı Göl: kıyıda ve suyun altında kum, kıyının ardında koyu otluk, sazın dibinde balçık (açık toprak, kum yok).
					if lake_shape and lake_shape.lake_box.has_point(p):
						var ld := lake_shape.lake_distance(p.x, p.y) - lake_shape.lake_half_width + wobble * 1.4
						if ld < 3.0:
							pale = maxf(pale, 1.0 - smoothstep(0.0, 3.0, ld))
							gravel *= smoothstep(-2.0, 3.0, ld)
						lush = maxf(lush, (1.0 - smoothstep(4.0, 14.0, absf(ld - 9.0))) * 0.85)
						for row: Array in lake_muds:
							var md := p.distance_to(Vector2(float(row[0]), float(row[1]))) + wobble * 1.2
							if md < float(row[2]) * 1.6:
								var k := 1.0 - smoothstep(float(row[2]) * 0.6, float(row[2]) * 1.6, md)
								bare = maxf(bare, k)
								pale *= 1.0 - k
					# Doğumun maskesi buradan ayrılır: patikalar ve çiğnenmiş toprağın kenarı doğumunkilerdir.
					var bare_b := bare
					var lush_b := lush
					for line in near_tracks:
						var q := line.nearest(p)
						var half_w := float(line.def.get("width", 1.0)) * 0.5
						bare = maxf(bare, (1.0 - smoothstep(half_w - 0.25, half_w + 0.5, q.x + wobble * 0.4)) * 0.8)
					# Çiğnenmiş izin çevresinde ot ezik: toprak üst katmana karışır.
					if near_trails:
						var trampled := path_shape.trampled_distance(p)
						if trampled < 3.2:
							bare = maxf(bare, (1.0 - smoothstep(-0.5, 3.0, trampled)) * 0.85)
							lush *= smoothstep(0.0, 3.0, trampled)
					lush *= 1.0 - gravel * 0.7
					var k := local * 4
					mask[k] = int(clampf(bare, 0.0, 1.0) * 255.0)
					mask[k + 1] = int(clampf(pale, 0.0, 1.0) * 255.0)
					mask[k + 2] = int(clampf(gravel, 0.0, 1.0) * 255.0)
					mask[k + 3] = int(clampf(lush, 0.0, 1.0) * 255.0)
					if birth:
						for line in near_birth_tracks:
							var q := line.nearest(p)
							bare_b = maxf(bare_b, (1.0 - smoothstep(0.25, 1.0, q.x + wobble * 0.4)) * 0.8)
						if near_birth_trails:
							var trampled_b := birth_paths.trampled_distance(p)
							if trampled_b < 3.2:
								bare_b = maxf(bare_b, (1.0 - smoothstep(-0.5, 3.0, trampled_b)) * 0.85)
								lush_b *= smoothstep(0.0, 3.0, trampled_b)
						lush_b *= 1.0 - gravel * 0.7
						mask_b[k] = int(clampf(bare_b, 0.0, 1.0) * 255.0)
						mask_b[k + 1] = mask[k + 1]
						mask_b[k + 2] = mask[k + 2]
						mask_b[k + 3] = int(clampf(lush_b, 0.0, 1.0) * 255.0)
	var out := {"relief": relief, "mask": mask}
	if birth:
		out["mask_birth"] = mask_b
	return out


## Sakin daireler (saf): Vector4(x, z, yarıçap, geçiş): yurtlar.
static func quiet_zones(layout: Dictionary) -> Array[Vector4]:
	var quiet: Dictionary = ((layout.get("childhood", {}) as Dictionary).get("ground", {}) as Dictionary).get("quiet", {})
	var margin := float(quiet.get("place_margin", 7.0))
	var fade := float(quiet.get("place_fade", 10.0))
	var out: Array[Vector4] = []
	var places: Dictionary = layout.get("places", {})
	for id: String in places:
		var place: Dictionary = places[id]
		var at := OrdosGround._vec2(place.get("at", [0.0, 0.0]))
		out.append(Vector4(at.x, at.y, float(place.get("radius", 3.0)) + margin, fade))
	# E21: Ebe Obası'nın yurtları ve sayım taşları (quiet.extra: [x, z, yarıçap, geçiş]).
	for row: Variant in quiet.get("extra", []):
		var r: Array = row
		out.append(Vector4(float(r[0]), float(r[1]), float(r[2]), float(r[3]) if r.size() > 3 else fade))
	return out


## Maskenin bir noktası (saf; en yakın örnek): Vector4(toprak, kum, çakıl, koyu ot), 0..1. Alanın dışı sıfırdır.
static func mask_at(mask: Dictionary, x: float, z: float) -> Vector4:
	var origin: Vector2 = mask["origin"]
	var step: float = mask["step"]
	var i := int((x - origin.x) / step + 0.5)
	var j := int((z - origin.y) / step + 0.5)
	var w: int = mask["w"]
	var h: int = mask["h"]
	if i < 0 or j < 0 or i >= w or j >= h:
		return Vector4.ZERO
	var data: PackedByteArray = mask["data"]
	var k := (j * w + i) * 4
	return Vector4(float(data[k]), float(data[k + 1]), float(data[k + 2]), float(data[k + 3])) / 255.0


## Maskenin dokusu (ana iş parçacığında).
static func mask_texture(mask: Dictionary) -> ImageTexture:
	var image := Image.create_from_data(int(mask["w"]), int(mask["h"]), false, Image.FORMAT_RGBA8, mask["data"])
	return ImageTexture.create_from_image(image)


## Gölgelendiricinin maske dikdörtgeni: (x0, z0, 1/en, 1/boy).
static func mask_rect(mask: Dictionary) -> Vector4:
	var origin: Vector2 = mask["origin"]
	var step: float = mask["step"]
	return Vector4(origin.x, origin.y, 1.0 / (float(mask["w"]) * step), 1.0 / (float(mask["h"]) * step))


## Bloğa etki eden daireler: satır [x, z, yarıçap, ...]; etki yarıçapı = yarıçap × scale + extra.
static func _filter_circles(rows: Array, block: Rect2, scale: float = 1.0, extra: float = 0.0) -> Array:
	var out := []
	for row: Array in rows:
		var center := Vector2(float(row[0]), float(row[1]))
		var reach := float(row[2]) * scale + extra
		var nearest := center.clamp(block.position, block.end)
		if nearest.distance_squared_to(center) < reach * reach:
			out.append(row)
	return out


static func _filter(lines: Array[Line], block: Rect2, reach: float) -> Array[Line]:
	var out: Array[Line] = []
	var grown := block.grow(reach)
	for line in lines:
		if grown.intersects(line.box):
			out.append(line)
	return out
