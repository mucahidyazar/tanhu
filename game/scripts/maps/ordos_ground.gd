class_name OrdosGround
extends TerrainShape
## childhood_ordos'un yüzü (saf; godot.md §4.4 «tek yükseklik yüzü»): height_at(x, z) ve normal_at(x, z), çiğnenmiş
## toprak bölgeleri ve zemin ağının dizileri. Düğüm kurmaz, ağaca dokunmaz: WorkerThreadPool'da kendi örneğiyle
## çalışır (FastNoiseLite örnek başınadır, iş parçacıkları paylaşmaz). TerrainShape'tir: oyuncu, kamera ve ok (PlayerController,
## FollowCamera terrain_shape) kampın yüzü gibi sorar.
##
## Biçim data/maps/childhood_ordos/layout.json'dadır ("ground", "flats", "trampled"):
##  - Haritanın içi (≈220 × 160 m) alçak dalgalı güz otlağıdır (near_amplitude, ≈40 m dalga boyu).
##  - Yurtların, otağın ve sayım hattının altı düzdür: flats kapsüllerdir (a, b, yarıçap, kenar), uçlarındaki doğal
##    yükseklik arasında doğrusal; daire a = b'dir.
##  - spec "ground_relief" verilince (ChildhoodGround) kademe, tepecik ve kuru dere eklenir: doğumun bozkırı (OrdosWorld.steppe) ve Çocukluk'un
##    yüzü aynı yükseltiyi okur. Düzenin yalın yüzü (OrdosWorld.ground: yurtların, kazıkların, işaretlerin yeri) bunları bilmez; yükselti o
##    yerlerin çevresinde sıfırdır (ChildhoodGround quiet).
##  - Doğuya doğru Sarı Irmak'ın vadisine alçak bir iniş vardır (east_drop); ırmak vadinin içinde kıvrılan bir
##    yataktır, suyu water_level'dadır. Ufukta dar bir su şeridi olarak görünür.
##  - Batıda, kuzeyde ve güneyde alçak tepe siluetleri (hills); doğu açıktır: güneş ufukta görünür. Batı tepeleri
##    kamptan ≤1°'dir, 06:03'te batıda 2,1° yüksekteki dolunayı örtmez (data/cine/birth_light.json).
## Ağ dikdörtgen bir ızgaradır: harita içinde cell (2 m) aralıklı, dışında growth oranıyla büyüyen adımlarla far'a
## (3 km) dek; dikiş ve örtüşme yoktur.

## Ağın dizileri (Mesh.ARRAY_* düzeninde) ve ızgara çizgileri.
const ARRAY_LINES_X := "lines_x"
const ARRAY_LINES_Z := "lines_z"
## Düzende tohum yazılmamışsa zeminin tohumu.
const DEFAULT_SEED := 2341
## Gölün kıyısının su çizgisindeki payı (m): kıyı suyun bu kadar üstünden başlar.
const LAKE_LIP := 0.06

var center := Vector2.ZERO
var half_size := Vector2(110.0, 80.0)
var cell := 2.0
var far := 3000.0
var growth := 1.18
var near_amplitude := 0.5
var near_wavelength := 40.0
var east_drop := 12.0
var east_drop_from := 80.0
var east_drop_to := 620.0
var hill_amplitude := 14.0
var hill_from := 140.0
var hill_to := 1100.0
var river_x := 680.0
var river_meander := 45.0
var river_wavelength := 1900.0
var river_width := 70.0
var river_bank := 45.0
var river_depth := 2.6
var water_level := -13.6
## Düz yerler: Dictionary {a: Vector2, b: Vector2, r: float, blend: float, ha: float, hb: float}.
var flats: Array[Dictionary] = []
## Çiğnenmiş toprak: daireler Vector3(x, z, yarıçap) ve izler Vector4(ax, az, bx, bz) + yarı genişlik.
var trampled_circles: Array[Vector3] = []
var trampled_trails: Array[Vector4] = []
var trail_half_widths := PackedFloat32Array()
## Çiğnenmiş toprağın kenar yumuşaklığı (metre).
var trampled_soft := 1.2
## E21 (K110): ağın sık ızgarasının dikdörtgeni (dünya; "ground.dense": min, max). Boşsa merkezin çevresinde ±half_size (bugünkü gibi).
## Yalnız Çocukluk'un yüzündedir (layout "childhood.ground.dense"; ChildhoodSite.merged_spec ekler): doğumun bozkırı bugünkü ızgaradır.
var dense_min := Vector2.INF
var dense_max := Vector2.INF
## Sık ızgaranın seyrek aralıkları Vector3(alt, üst, hücre) eksen başına (dünya; "dense.x_coarse", "dense.z_coarse": [alt, üst, hücre]): kamp
## ile göl, kamp ile oba arasındaki yolda hücre büyür (kenarlar sık ızgaranın çizgisidir; dikiş yok).
var dense_coarse_x: Array[Vector3] = []
var dense_coarse_z: Array[Vector3] = []
## Normaller ızgaranın komşularından mı (E21: Çocukluk'un geniş ağı; köşe başına bir yükseklik): değilse normal_at (köşe başına beş).
var grid_normals := false
## E21: Kamışlı Göl (layout "childhood.lake"): Sarı Irmak'ın eski yatağı, orta çizgi boyunca oyuk; su seviyesi sabittir (lake_level).
var lake_points := PackedVector2Array()
var lake_cumulative := PackedFloat32Array()
var lake_half_width := 0.0
var lake_bank := 10.0
var lake_blend := 24.0
var lake_rise := 0.55
var lake_depth := 2.3
var lake_level := NAN
var lake_box := Rect2()
## Gölün sığdan derine bantları (kıyıdan içeri metre → derinlik metre): kumlu sığ kıyı, bel, yüzme, derin orta.
var lake_profile: Array[Vector2] = [Vector2(0.0, 0.05), Vector2(6.0, 0.4), Vector2(10.0, 0.8), Vector2(16.0, 1.6)]

var _near: FastNoiseLite
var _near_detail: FastNoiseLite
var _far_hills: FastNoiseLite
## Bozkırın yükseltisi (ChildhoodGround; yalnız spec'te "ground_relief" varsa): metre başına ızgara, düzenin yalın yüzünde boştur.
var _relief := PackedFloat32Array()
var _relief_origin := Vector2.ZERO
var _relief_step := 1.0
var _relief_w := 0
var _relief_h := 0


## spec: layout.json'un sözlüğü (ya da boş: varsayılanlar).
func _init(spec: Dictionary = {}) -> void:
	super()
	var g: Dictionary = spec.get("ground", {})
	seed_value = int(g.get("seed", (spec.get("seeds", {}) as Dictionary).get("ground", DEFAULT_SEED)))
	center = _vec2(spec.get("center", [0.0, 0.0]))
	half_size = _vec2(spec.get("size", [220.0, 160.0])) * 0.5
	cell = float(g.get("cell", cell))
	far = float(g.get("far", far))
	growth = float(g.get("growth", growth))
	near_amplitude = float(g.get("near_amplitude", near_amplitude))
	near_wavelength = float(g.get("near_wavelength", near_wavelength))
	east_drop = float(g.get("east_drop", east_drop))
	east_drop_from = float(g.get("east_drop_from", east_drop_from))
	east_drop_to = float(g.get("east_drop_to", east_drop_to))
	hill_amplitude = float(g.get("hill_amplitude", hill_amplitude))
	hill_from = float(g.get("hill_from", hill_from))
	hill_to = float(g.get("hill_to", hill_to))
	var river: Dictionary = spec.get("river", {})
	river_x = float(river.get("x", river_x))
	river_meander = float(river.get("meander", river_meander))
	river_wavelength = float(river.get("wavelength", river_wavelength))
	river_width = float(river.get("width", river_width))
	river_bank = float(river.get("bank", river_bank))
	river_depth = float(river.get("depth", river_depth))
	water_level = float(river.get("water_level", water_level))
	_near = _noise(seed_value, 1.0 / maxf(near_wavelength, 1.0), 2)
	_near_detail = _noise(seed_value + 11, 0.11, 2)
	_far_hills = _noise(seed_value + 23, 0.0016, 3)
	# E21: göl düz yerlerden önce (düz yerin uçları gölün yüzünü okur).
	_init_lake(spec.get("lake", {}))
	var relief: Dictionary = spec.get("ground_relief", {})
	if not relief.is_empty():
		_relief = relief["data"]
		_relief_origin = relief["origin"]
		_relief_step = relief["step"]
		_relief_w = relief["w"]
		_relief_h = relief["h"]
	for f: Dictionary in spec.get("flats", []):
		var a := _vec2(f.get("a", f.get("at", [0.0, 0.0])))
		var b := _vec2(f.get("b", f.get("at", [0.0, 0.0])))
		flats.append({"a": a, "b": b, "r": float(f.get("r", 3.0)), "blend": float(f.get("blend", 2.0)),
			"ha": natural_height_at(a.x, a.y), "hb": natural_height_at(b.x, b.y)})
	var trampled: Dictionary = spec.get("trampled", {})
	trampled_soft = float(trampled.get("soft", trampled_soft))
	for c: Array in trampled.get("circles", []):
		trampled_circles.append(Vector3(float(c[0]), float(c[1]), float(c[2])))
	for t: Array in trampled.get("trails", []):
		trampled_trails.append(Vector4(float(t[0]), float(t[1]), float(t[2]), float(t[3])))
		trail_half_widths.append(float(t[4]) * 0.5)
	var dense: Dictionary = g.get("dense", {})
	if not dense.is_empty():
		dense_min = _vec2(dense.get("min", [-half_size.x, -half_size.y]))
		dense_max = _vec2(dense.get("max", [half_size.x, half_size.y]))
		for row: Variant in dense.get("x_coarse", []):
			dense_coarse_x.append(Vector3(float(row[0]), float(row[1]), float(row[2])))
		for row: Variant in dense.get("z_coarse", []):
			dense_coarse_z.append(Vector3(float(row[0]), float(row[1]), float(row[2])))
	grid_normals = bool(g.get("grid_normals", false))


# --- Yükseklik ----------------------------------------------------------------------------------

## Zeminin yüksekliği (metre): doğal biçim, düz yerler uygulanmış. Parçanın oranı burada hesaplanır (_segment_t'nin aynısı): örnek başına
## düz yer sayısı kadar yöntem çağrısı iş parçacıklarını ObjectDB'nin ortak kilidinde bekletiyordu.
func height_at(x: float, z: float) -> float:
	var h := natural_height_at(x, z)
	var p := Vector2(x, z)
	for f in flats:
		var a: Vector2 = f["a"]
		var b: Vector2 = f["b"]
		var ab := b - a
		var len2 := ab.length_squared()
		var t := 0.0 if len2 < 1e-9 else clampf((p - a).dot(ab) / len2, 0.0, 1.0)
		var d := p.distance_to(a.lerp(b, t))
		var r: float = f["r"]
		var w := 1.0 - smoothstep(r, r + float(f["blend"]), d)
		if w > 0.0:
			h = lerpf(h, lerpf(float(f["ha"]), float(f["hb"]), t), w)
	return h


## Düz yerler uygulanmadan doğal yükseklik (metre). Yükselti ve ırmağın uzaklığı burada hesaplanır (relief_at ve river_offset'in aynısı):
## arazinin her köşesinde beş kez sorulur, yöntem çağrısı iş parçacıklarını bekletir (height_at gibi).
func natural_height_at(x: float, z: float) -> float:
	var h := _near.get_noise_2d(x, z) * near_amplitude + _near_detail.get_noise_2d(x, z) * near_amplitude * 0.25
	if _relief_w > 0:
		var fx := (x - _relief_origin.x) / _relief_step
		var fz := (z - _relief_origin.y) / _relief_step
		var ri := floori(fx)
		var rj := floori(fz)
		if not (ri < 0 or rj < 0 or ri >= _relief_w - 1 or rj >= _relief_h - 1):
			var tx := fx - float(ri)
			var tz := fz - float(rj)
			var k := rj * _relief_w + ri
			h += lerpf(lerpf(_relief[k], _relief[k + 1], tx), lerpf(_relief[k + _relief_w], _relief[k + _relief_w + 1], tx), tz)
	# Doğuya, Sarı Irmak'ın vadisine iniş.
	h -= east_drop * smoothstep(east_drop_from, east_drop_to, x - center.x)
	# Alçak tepeler: batıda, kuzeyde, güneyde; doğu açık.
	var rel := Vector2(x, z) - center
	var d := rel.length()
	if d > hill_from:
		var east := rel.x / maxf(d, 1.0)
		var w := smoothstep(hill_from, hill_to, d) * (1.0 - smoothstep(0.1, 0.6, east))
		var n := _far_hills.get_noise_2d(x, z) * 0.5 + 0.5
		h += hill_amplitude * w * n * n
	# Irmak yatağı: ortası suyun river_depth altında, su kıyısında (inner) su seviyesinde; kıyıdan river_bank
	# boyunca doğal yüzeye çıkar. Su, yüzeyin water_level altında kaldığı yerde görünür (genişliği river_width).
	var off := absf(x - (center.x + river_x + sin(z * TAU / maxf(river_wavelength, 1.0)) * river_meander))
	var inner := river_width * 0.5
	if off < inner:
		h = minf(h, water_level - river_depth * (1.0 - smoothstep(0.0, inner, off)))
	elif off < inner + river_bank:
		h = minf(h, lerpf(water_level, h, smoothstep(inner, inner + river_bank, off)))
	if lake_half_width > 0.0 and lake_box.has_point(Vector2(x, z)):
		h = _lake_height(x, z, h)
	return h


# --- Kamışlı Göl (E21, K110) --------------------------------------------------------------------------------

func _init_lake(def: Dictionary) -> void:
	var pts: Array = def.get("line", [])
	if pts.size() < 2:
		return
	lake_points = PackedVector2Array()
	for p: Variant in pts:
		lake_points.append(_vec2(p))
	lake_cumulative = PackedFloat32Array([0.0])
	for i in range(1, lake_points.size()):
		lake_cumulative.append(lake_cumulative[i - 1] + lake_points[i].distance_to(lake_points[i - 1]))
	lake_half_width = float(def.get("half_width", 24.0))
	lake_bank = float(def.get("bank", 10.0))
	lake_blend = float(def.get("blend", 24.0))
	lake_rise = float(def.get("rise", 0.55))
	lake_depth = float(def.get("depth", 2.3))
	if def.get("profile") is Array:
		lake_profile.clear()
		for row: Variant in def["profile"]:
			lake_profile.append(_vec2(row))
	lake_box = Rect2(lake_points[0], Vector2.ZERO)
	for p in lake_points:
		lake_box = lake_box.expand(p)
	lake_box = lake_box.grow(lake_half_width + lake_bank + lake_blend + 1.0)
	# Su seviyesi yükseltisiz yüzden (gürültü, doğuya iniş, tepeler): doğumun, Çocukluk'un ve düzenin yalın yüzü aynı seviyeyi bulur.
	var ref := _vec2(def.get("level_at", [lake_points[0].x - lake_half_width, lake_points[0].y]))
	lake_level = float(def["level"]) if def.has("level") else base_height_at(ref.x, ref.y) - float(def.get("level_drop", 0.25))


## Yükseltisiz, düz yersiz doğal yükseklik (saf): yakın gürültü, doğuya iniş ve uzak tepeler. Gölün seviyesinin dayanağı.
func base_height_at(x: float, z: float) -> float:
	var h := _near.get_noise_2d(x, z) * near_amplitude + _near_detail.get_noise_2d(x, z) * near_amplitude * 0.25
	h -= east_drop * smoothstep(east_drop_from, east_drop_to, x - center.x)
	var rel := Vector2(x, z) - center
	var d := rel.length()
	if d > hill_from:
		var east := rel.x / maxf(d, 1.0)
		var w := smoothstep(hill_from, hill_to, d) * (1.0 - smoothstep(0.1, 0.6, east))
		var n := _far_hills.get_noise_2d(x, z) * 0.5 + 0.5
		h += hill_amplitude * w * n * n
	return h


## Noktanın gölün orta çizgisine uzaklığı (m; göl yoksa çok büyük).
func lake_distance(x: float, z: float) -> float:
	if lake_points.size() < 2:
		return 1.0e6
	var p := Vector2(x, z)
	var best := INF
	for i in lake_points.size() - 1:
		var a := lake_points[i]
		var b := lake_points[i + 1]
		best = minf(best, p.distance_squared_to(a.lerp(b, _segment_t(p, a, b))))
	return sqrt(best)


## Kıyıdan içeri s metrede gölün derinliği (saf; bantlar lake_profile, ortada lake_depth).
func lake_depth_at_inset(s: float) -> float:
	if s <= 0.0:
		return 0.0
	var prev := lake_profile[0]
	for row in lake_profile:
		if s <= row.x:
			return lerpf(prev.y, row.y, (s - prev.x) / maxf(row.x - prev.x, 0.001)) if row.x > prev.x else row.y
		prev = row
	var last := lake_profile[lake_profile.size() - 1]
	return lerpf(last.y, lake_depth, clampf((s - last.x) / maxf(lake_half_width - last.x, 0.001), 0.0, 1.0))


## Gölün yatağı ve kıyısı (sürekli): içeride yatak (seviye − derinlik; doğal yüzeyden bağımsız oyuk), kıyı payında (bank) sudan yavaşça
## yükselen kıyı (lake_rise), geçiş payında (blend) doğal yüzeye karışma. Doğal yüzey doğuda seviyenin altındaysa kıyı oraya yavaşça iner
## (eski yatağın sırtı): suyun kenarında basamak ve uçurum yoktur.
func _lake_height(x: float, z: float, h: float) -> float:
	var d := lake_distance(x, z)
	var e := lake_half_width
	if d < e:
		return lake_level - lake_depth_at_inset(e - d)
	var shore := lake_level + LAKE_LIP
	if d < e + lake_bank:
		return shore + lake_rise * smoothstep(0.0, 1.0, (d - e) / lake_bank)
	if d < e + lake_bank + lake_blend:
		return lerpf(shore + lake_rise, h, smoothstep(0.0, 1.0, (d - e - lake_bank) / lake_blend))
	return h


## Suyun yüzü (x, z): {level, depth (su yüzünden zemine; kuru yerde ≤ 0), inside (gölün kıyı çizgisinin içinde mi), inset (kıyıdan içeri m)}.
func water_at(x: float, z: float) -> Dictionary:
	if lake_half_width <= 0.0 or not lake_box.has_point(Vector2(x, z)):
		return {"level": NAN, "depth": 0.0, "inside": false, "inset": -1.0e6}
	var d := lake_distance(x, z)
	var depth := lake_level - height_at(x, z)
	return {"level": lake_level, "depth": depth, "inside": d < lake_half_width, "inset": lake_half_width - d}


## Çocukluk'un yükseltisi (metre; çift doğrusal; ızgaranın dışı ve doğumun yüzünde 0).
func relief_at(x: float, z: float) -> float:
	var fx := (x - _relief_origin.x) / _relief_step
	var fz := (z - _relief_origin.y) / _relief_step
	var i := floori(fx)
	var j := floori(fz)
	if i < 0 or j < 0 or i >= _relief_w - 1 or j >= _relief_h - 1:
		return 0.0
	var tx := fx - float(i)
	var tz := fz - float(j)
	var k := j * _relief_w + i
	return lerpf(lerpf(_relief[k], _relief[k + 1], tx), lerpf(_relief[k + _relief_w], _relief[k + _relief_w + 1], tx), tz)


## Yüzeyin normali (merkezî farklar).
func normal_at(x: float, z: float, eps: float = 0.5) -> Vector3:
	var dx := height_at(x - eps, z) - height_at(x + eps, z)
	var dz := height_at(x, z - eps) - height_at(x, z + eps)
	return Vector3(dx, 2.0 * eps, dz).normalized()


## Irmağın orta çizgisine yatay işaretli uzaklık (metre; doğu artı).
func river_offset(x: float, z: float) -> float:
	return x - (center.x + river_x + sin(z * TAU / maxf(river_wavelength, 1.0)) * river_meander)


func is_underwater(x: float, z: float) -> bool:
	return height_at(x, z) < water_level


## Nokta harita içinde mi (≈220 × 160 m)?
func in_map(x: float, z: float) -> bool:
	return absf(x - center.x) <= half_size.x and absf(z - center.y) <= half_size.y


# --- Çiğnenmiş toprak -----------------------------------------------------------------------------

## Çiğnenmiş toprağın ağırlığı (0..1): avlu, kapı önleri ve izler. Kenar trampled_soft içinde yumuşar. Gölgelendirici
## aynı daireleri ve izleri gürültülü kenarla çizer (ground_uniforms).
func trampled_weight(p: Vector2) -> float:
	return 1.0 - smoothstep(-trampled_soft, trampled_soft, trampled_distance(p))


## Çiğnenmiş toprağın kenarına işaretli uzaklık (metre; içeride eksi; bölge yoksa çok büyük).
func trampled_distance(p: Vector2) -> float:
	var best := 1.0e6
	for c in trampled_circles:
		best = minf(best, p.distance_to(Vector2(c.x, c.y)) - c.z)
	for i in trampled_trails.size():
		var s := trampled_trails[i]
		var a := Vector2(s.x, s.y)
		var b := Vector2(s.z, s.w)
		best = minf(best, p.distance_to(a.lerp(b, _segment_t(p, a, b))) - trail_half_widths[i])
	return best


## Zemin gölgelendiricisinin bölge tekdüzenleri (dizi boyları gölgelendiricinin MAX_* sabitleriyle aynı).
func ground_uniforms(max_circles: int = 12, max_trails: int = 12) -> Dictionary:
	var circles: Array[Vector4] = []
	for c in trampled_circles.slice(0, max_circles):
		circles.append(Vector4(c.x, c.y, c.z, 0.0))
	var count_c := circles.size()
	while circles.size() < max_circles:
		circles.append(Vector4.ZERO)
	var trails: Array[Vector4] = []
	trails.assign(trampled_trails.slice(0, max_trails))
	var widths := trail_half_widths.slice(0, max_trails)
	var count_t := trails.size()
	while trails.size() < max_trails:
		trails.append(Vector4.ZERO)
		widths.append(0.0)
	return {
		"trampled_circles": circles, "trampled_circle_count": count_c,
		"trampled_trails": trails, "trampled_trail_widths": widths, "trampled_trail_count": count_t,
		"trampled_soft": trampled_soft,
	}


# --- Ağ ---------------------------------------------------------------------------------------

## Izgara çizgileri (saf): [-far, far] aralığında, ±half içinde cell_size aralıklı, dışında her adım bir öncekinin
## growth katı. Sıralı ve tekrarsız.
static func axis_lines(half: float, cell_size: float, far_m: float, growth_rate: float) -> PackedFloat32Array:
	var n := maxi(roundi(half / cell_size), 1)
	var inner_half := float(n) * cell_size
	var outer := PackedFloat32Array()
	var step := cell_size
	var p := inner_half
	while p < far_m - 0.001:
		step *= maxf(growth_rate, 1.01)
		p = minf(p + step, far_m)
		outer.append(p)
	var lines := PackedFloat32Array()
	for i in range(outer.size() - 1, -1, -1):
		lines.append(-outer[i])
	for i in range(-n, n + 1):
		lines.append(float(i) * cell_size)
	lines.append_array(outer)
	return lines


## Zemin ağının dizileri (iş parçacığında): Mesh.ARRAY_VERTEX, ARRAY_NORMAL, ARRAY_INDEX; ayrıca ızgara çizgileri.
func build_arrays() -> Dictionary:
	return join_rows([build_rows(0, row_count())])


## Izgaranın satır sayısı (z çizgileri).
func row_count() -> int:
	return _zs().size()


## Izgaranın x ve z çizgileri (dünya ekseninde merkeze göre): dense verilmişse o dikdörtgen sık, yoksa ±half_size (E21).
func _xs() -> PackedFloat32Array:
	if dense_min.is_finite():
		return thin_lines(axis_lines_range(dense_min.x - center.x, dense_max.x - center.x, cell, far, growth), dense_coarse_x, center.x)
	return axis_lines(half_size.x, cell, far, growth)


func _zs() -> PackedFloat32Array:
	if dense_min.is_finite():
		return thin_lines(axis_lines_range(dense_min.y - center.y, dense_max.y - center.y, cell, far, growth), dense_coarse_z, center.y)
	return axis_lines(half_size.y, cell, far, growth)


## Seyrek aralıklarda sık çizgileri seyreltir (saf; E21): aralığın (dünya) içindeki çizgiden yalnız aralığın altından hücrenin katında olanlar
## kalır; aralığın uçları kalır. origin çizgilerin dünyadaki sıfırıdır.
static func thin_lines(lines: PackedFloat32Array, spans: Array[Vector3], origin: float) -> PackedFloat32Array:
	if spans.is_empty():
		return lines
	var out := PackedFloat32Array()
	for p in lines:
		var w := p + origin
		var keep := true
		for span in spans:
			if w > span.x + 0.001 and w < span.y - 0.001:
				var k := (w - span.x) / maxf(span.z, 0.001)
				keep = absf(k - roundf(k)) < 0.001
				break
		if keep:
			out.append(p)
	return out


## Izgara çizgileri (saf; E21): [lo, hi] aralığında cell_size aralıklı (uçlar hücreye yuvarlanır), dışında her adım bir öncekinin growth katı,
## iki yanda far'a dek. Sıralı ve tekrarsız.
static func axis_lines_range(lo: float, hi: float, cell_size: float, far_m: float, growth_rate: float) -> PackedFloat32Array:
	var a := floorf(lo / cell_size)
	var b := ceilf(hi / cell_size)
	var lines := PackedFloat32Array()
	var low := PackedFloat32Array()
	var step := cell_size
	var p := a * cell_size
	while p > -far_m + 0.001:
		step *= maxf(growth_rate, 1.01)
		p = maxf(p - step, -far_m)
		low.append(p)
	for i in range(low.size() - 1, -1, -1):
		lines.append(low[i])
	for i in range(int(a), int(b) + 1):
		lines.append(float(i) * cell_size)
	step = cell_size
	p = b * cell_size
	while p < far_m - 0.001:
		step *= maxf(growth_rate, 1.01)
		p = minf(p + step, far_m)
		lines.append(p)
	return lines


## Izgaranın [row_from, row_to) satırlarının köşeleri, normalleri ve üst köşesi bu satırlarda olan hücrelerin üçgenleri (iş parçacığı
## bandı; her bant kendi OrdosGround örneğiyle): {vertices, normals, indices}. join_rows bantları sırayla tek ağın dizilerine birleştirir:
## sonuç build_arrays'inkiyle aynıdır (üçgenler grid_indices'in sırasıyla).
func build_rows(row_from: int, row_to: int) -> Dictionary:
	var xs := _xs()
	var zs := _zs()
	var nx := xs.size()
	var nz := zs.size()
	var to := mini(row_to, nz)
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	vertices.resize(nx * maxi(to - row_from, 0))
	normals.resize(vertices.size())
	if grid_normals:
		_grid_rows(xs, zs, row_from, to, vertices, normals)
		return {"vertices": vertices, "normals": normals, "indices": grid_indices(nx, nz, row_from, mini(to, nz - 1))}
	for j in range(row_from, to):
		var z := zs[j] + center.y
		var dz := maxf(cell, (zs[mini(j + 1, nz - 1)] - zs[maxi(j - 1, 0)]) * 0.5)
		for i in nx:
			var x := xs[i] + center.x
			var dx := maxf(cell, (xs[mini(i + 1, nx - 1)] - xs[maxi(i - 1, 0)]) * 0.5)
			var k := (j - row_from) * nx + i
			vertices[k] = Vector3(x, height_at(x, z), z)
			normals[k] = normal_at(x, z, clampf(minf(dx, dz) * 0.5, 0.5, 40.0))
	return {"vertices": vertices, "normals": normals, "indices": grid_indices(nx, nz, row_from, mini(to, nz - 1))}


## Izgaranın komşularından normaller (E21): bandın satırlarının ve iki yanındaki birer satırın yüksekliği bir kez hesaplanır, normal merkezî
## farktır (ızgaranın kenarında tek yanlı). Bantların dikişinde iki yan aynı yükseklikleri okur: gölge kesintisiz.
func _grid_rows(xs: PackedFloat32Array, zs: PackedFloat32Array, row_from: int, to: int, vertices: PackedVector3Array, normals: PackedVector3Array) -> void:
	var nx := xs.size()
	var nz := zs.size()
	var j0 := maxi(row_from - 1, 0)
	var j1 := mini(to + 1, nz)
	var hs := PackedFloat32Array()
	hs.resize(nx * maxi(j1 - j0, 0))
	for j in range(j0, j1):
		var z := zs[j] + center.y
		var base := (j - j0) * nx
		for i in nx:
			hs[base + i] = height_at(xs[i] + center.x, z)
	for j in range(row_from, to):
		var z := zs[j] + center.y
		var jm := maxi(j - 1, 0)
		var jp := mini(j + 1, nz - 1)
		var span_z := maxf(zs[jp] - zs[jm], 0.001)
		var row := (j - j0) * nx
		var row_m := (jm - j0) * nx
		var row_p := (jp - j0) * nx
		for i in nx:
			var im := maxi(i - 1, 0)
			var ip := mini(i + 1, nx - 1)
			var k := (j - row_from) * nx + i
			vertices[k] = Vector3(xs[i] + center.x, hs[row + i], z)
			var dhx := (hs[row + ip] - hs[row + im]) / maxf(xs[ip] - xs[im], 0.001)
			var dhz := (hs[row_p + i] - hs[row_m + i]) / span_z
			normals[k] = Vector3(-dhx, 1.0, -dhz).normalized()


## Satır bandının kendi ağının dizileri (E21; Çocukluk'un zemini parça parça kurulur): [row_from, row_to] satırlarının köşeleri (sonraki bandın
## ilk satırı dahil: dikiş yok), bandın kendi numaralı üçgenleri.
func build_chunk(row_from: int, row_to: int) -> Dictionary:
	var nz := row_count()
	var last := mini(row_to + 1, nz)
	var part := build_rows(row_from, last)
	part["indices"] = grid_indices(_xs().size(), maxi(last - row_from, 0))
	return part


## Satır bantlarını (build_rows, sırayla) tek ağın dizilerine birleştirir; ızgara çizgileri eklenir.
func join_rows(parts: Array) -> Dictionary:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for part: Dictionary in parts:
		vertices.append_array(part["vertices"])
		normals.append_array(part["normals"])
		indices.append_array(part["indices"])
	return {
		"vertices": vertices, "normals": normals, "indices": indices,
		ARRAY_LINES_X: _xs(), ARRAY_LINES_Z: _zs(),
	}


## Çiğnenmiş toprağın üst katmanının dizileri: zeminin harita içindeki 2 m ızgarasının çiğnenmiş bölgeye değen
## hücreleri, aynı köşeler ve aynı üçgen bölümüyle, lift kadar yukarıda (iki yüzey paraleldir, titreşmez). Kenar
## gölgelendiricide gürültüyle kesilir (discard).
func build_overlay_arrays(lift: float = 0.02) -> Dictionary:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var n_x := maxi(roundi(half_size.x / cell), 1)
	var n_z := maxi(roundi(half_size.y / cell), 1)
	var reach := trampled_soft * 2.0 + cell
	var index_of := {}
	for j in range(-n_z, n_z):
		for i in range(-n_x, n_x):
			var c := center + Vector2((float(i) + 0.5) * cell, (float(j) + 0.5) * cell)
			if trampled_distance(c) > reach:
				continue
			var ids := PackedInt32Array()
			for corner in [Vector2i(i, j), Vector2i(i + 1, j), Vector2i(i, j + 1), Vector2i(i + 1, j + 1)]:
				if not index_of.has(corner):
					var x := center.x + float(corner.x) * cell
					var z := center.y + float(corner.y) * cell
					index_of[corner] = vertices.size()
					vertices.append(Vector3(x, height_at(x, z) + lift, z))
					normals.append(normal_at(x, z, 0.5))
				ids.append(int(index_of[corner]))
			indices.append_array(PackedInt32Array([ids[0], ids[1], ids[2], ids[1], ids[3], ids[2]]))
	return {"vertices": vertices, "normals": normals, "indices": indices}


## Dikdörtgen ızgaranın üçgenleri (saf): her hücre (a, b, c) ve (b, d, c); yukarıdan bakınca saat yönünde (ön yüz). row_from ve row_to
## verilirse yalnız üst köşesi [row_from, row_to) satırlarında olan hücreler (köşe numaraları bütün ızgaranındır).
static func grid_indices(nx: int, nz: int, row_from: int = 0, row_to: int = -1) -> PackedInt32Array:
	var to := nz - 1 if row_to < 0 else mini(row_to, nz - 1)
	var indices := PackedInt32Array()
	indices.resize((nx - 1) * maxi(to - row_from, 0) * 6)
	var k := 0
	for j in range(row_from, to):
		for i in nx - 1:
			var a := j * nx + i
			var b := a + 1
			var c := a + nx
			var d := c + 1
			indices[k] = a
			indices[k + 1] = b
			indices[k + 2] = c
			indices[k + 3] = b
			indices[k + 4] = d
			indices[k + 5] = c
			k += 6
	return indices


## Dizilerden ağ (ana iş parçacığında çağrılır).
static func make_mesh(arrays: Dictionary) -> ArrayMesh:
	var surface := []
	surface.resize(Mesh.ARRAY_MAX)
	surface[Mesh.ARRAY_VERTEX] = arrays["vertices"]
	surface[Mesh.ARRAY_NORMAL] = arrays["normals"]
	surface[Mesh.ARRAY_INDEX] = arrays["indices"]
	var mesh := ArrayMesh.new()
	if (arrays["indices"] as PackedInt32Array).size() > 0:
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
	return mesh


# --- Yardımcılar ------------------------------------------------------------------------------

## p'nin [a, b] parçası üstündeki en yakın noktasının oranı (0..1).
static func _segment_t(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var len2 := ab.length_squared()
	return 0.0 if len2 < 1e-9 else clampf((p - a).dot(ab) / len2, 0.0, 1.0)


static func _vec2(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	if value is Array and (value as Array).size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO


static func _noise(p_seed: int, frequency: float, octaves: int) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = p_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.fractal_octaves = octaves
	return noise
