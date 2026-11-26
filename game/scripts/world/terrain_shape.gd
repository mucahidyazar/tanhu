class_name TerrainShape
extends RefCounted
## Arazinin saf (yan etkisiz) yükseklik fonksiyonu.
##
## Aynı seed her zaman aynı araziyi üretir. Arazi meshi, ağaç/çimen dağıtımı ve
## serbest gezinti kamerası (yerde yürüme) hep bu sınıfa sorar; bu yüzden
## birim testleriyle doğrudan sınanabilir (bkz. tests/unit/test_terrain_shape.gd).
##
## Koordinatlar (metre): kamp ateşi (0, 0, 0). Vadi ve göl -Z yönünde uzanır.

## Göl/nehir su seviyesi.
const WATER_LEVEL := -36.0
## Nehir çevresindeki vadi tabanı yüksekliği.
const VALLEY_FLOOR := -32.0
## Kampın tamamen düz kaldığı yarıçap.
const CAMP_FLAT_RADIUS := 14.0
## Sağdaki kayalık sırtın merkezi (x, z).
const CLIFF_CENTER := Vector2(58.0, -52.0)
## Kamp düzleminde (y = 0) tutulan ek alanlar: Vector4(x, z, düz yarıçap, geçiş genişliği).
## Ahır kampın sağ arkasında, çayırın üstünde durur (4. referansta kadrajın sağ üstü); altı ve çevresi
## (atlar, bayrak, heybeler) düz kalmalı ki modeller havada ya da gömülü durmasın. Çayırın hafif
## dalgaları ahırın altında sönsün diye uzun bir geçiş (12 m) bırakılır.
const FLAT_PADS: Array[Vector4] = [
	Vector4(14.0, -14.2, 5.0, 12.0),
]

## Platonun kenarı: kamp merkezinden bakılan her yönde inişin başladığı uzaklık ve inişin uzunluğu
## (metre): Vector2(iniş_başlangıcı, iniş_uzunluğu). Yönler -180°'den başlayıp 15° arayla dizilir; açı kuzeyden
## (-Z, vadi) saat yönünde ölçülür: 0 = kuzey, 90 = doğu (+X), ±180 = güney (menü kamerasının arkası).
## 4. referansta (assets/_reference/menu_camp.png) kampın arkasındaki çayır kamp düzleminde sürer: yurtların
## arkasında ~25–28 m'ye, sağda ahırın ve R10 kayasının arkasına (~40 m) kadar; doğuda çayır ahırın
## arkasındaki tepeye karışır. İniş ondan sonra başlar ve orman şeridini taşır (bkz. forest_density).
const PLATEAU_EDGE: Array[Vector2] = [
	Vector2(64.0, 60.0), Vector2(62.0, 60.0), Vector2(58.0, 62.0), Vector2(50.0, 66.0), # -180 … -135 (güney, güneybatı)
	Vector2(42.0, 70.0), Vector2(35.0, 74.0), Vector2(30.0, 76.0), Vector2(26.0, 76.0), # -120 … -75 (batı)
	Vector2(24.0, 76.0), Vector2(24.0, 76.0), Vector2(25.0, 76.0), Vector2(26.0, 76.0), # -60 … -15 (kuzeybatı)
	Vector2(28.0, 76.0), Vector2(35.0, 74.0), Vector2(50.0, 70.0), Vector2(60.0, 66.0), # 0 … 45 (kuzey, kuzeydoğu)
	Vector2(66.0, 62.0), Vector2(68.0, 60.0), Vector2(68.0, 60.0), Vector2(68.0, 60.0), # 60 … 105 (doğu)
	Vector2(68.0, 60.0), Vector2(66.0, 60.0), Vector2(66.0, 60.0), Vector2(65.0, 60.0), # 120 … 165 (güneydoğu)
]
## PLATEAU_EDGE noktaları arasındaki açı (derece).
const PLATEAU_EDGE_STEP := 15.0
## Platonun kenarını doğal göstermek için kenar uzaklığına eklenen gürültünün genliği (metre).
const PLATEAU_WARP := 4.0
## Çayırın ardındaki orman şeridi: inişin üst kısmında her yönde vardır; bu açı aralığında (derece, 0 = kuzey)
## inişin altındaki vadi tabanında da BAND_REACH metreye kadar sürer. 4. referansta çayırla göl arasında
## kadrajın sol yarısından ortasına uzanan koyu ormandır.
const BAND_SECTOR := Vector2(-60.0, 25.0)
const BAND_REACH := 240.0

## Nehrin z ekseni boyunca kontrol noktaları: Vector3(z, merkez_x, yarı_genişlik).
## z küçüldükçe (uzaklaştıkça) nehir sağa kıvrılıp dağlara doğru gider.
const RIVER_POINTS: Array[Vector3] = [
	Vector3(-140.0, -175.0, 0.0),
	Vector3(-250.0, -125.0, 22.0),
	Vector3(-370.0, -75.0, 55.0),
	Vector3(-500.0, -25.0, 150.0),
	Vector3(-660.0, 15.0, 185.0),
	Vector3(-830.0, 75.0, 115.0),
	Vector3(-1030.0, 140.0, 50.0),
	Vector3(-1280.0, 210.0, 40.0),
	Vector3(-1580.0, 260.0, 65.0),
	Vector3(-1980.0, 300.0, 85.0),
	Vector3(-2600.0, 330.0, 60.0),
]

## Göldeki adacıklar: Vector4(x, z, yarıçap, su üstündeki yükseklik).
const ISLANDS: Array[Vector4] = [
	Vector4(10.0, -650.0, 62.0, 9.0),
	Vector4(-45.0, -545.0, 24.0, 4.0),
	Vector4(95.0, -770.0, 34.0, 6.0),
]

## Uzakta, solda ayrı göller: Vector4(x, z, yarıçap, derinlik).
const SIDE_LAKES: Array[Vector4] = [
	Vector4(-390.0, -1260.0, 190.0, 7.0),
]

var seed_value: int

var _hills: FastNoiseLite
var _detail: FastNoiseLite
var _ridge: FastNoiseLite
var _warp: FastNoiseLite
var _forest: FastNoiseLite


func _init(p_seed: int = 1207) -> void:
	seed_value = p_seed
	_hills = _make_noise(p_seed, 0.0042, 4, FastNoiseLite.FRACTAL_FBM)
	_detail = _make_noise(p_seed + 11, 0.045, 3, FastNoiseLite.FRACTAL_FBM)
	_ridge = _make_noise(p_seed + 23, 0.018, 4, FastNoiseLite.FRACTAL_RIDGED)
	_warp = _make_noise(p_seed + 37, 0.02, 2, FastNoiseLite.FRACTAL_FBM)
	_forest = _make_noise(p_seed + 53, 0.0065, 3, FastNoiseLite.FRACTAL_FBM)


## Verilen (x, z) noktasındaki zemin yüksekliği: doğal arazi, ek düz alanlarda (FLAT_PADS) yumuşak
## bir geçişle kamp düzlemine (y = 0) çekilir.
func height_at(x: float, z: float) -> float:
	var h := natural_height_at(x, z)
	var pad := flat_pad_weight(x, z)
	return h if pad <= 0.0 else lerpf(h, 0.0, pad)


## Ek düz alanlar uygulanmadan önceki doğal yükseklik (testler düz alanın etkisini bununla ölçer).
func natural_height_at(x: float, z: float) -> float:
	var river := river_at(z)
	var dx := absf(x - river.x)

	# 1) Vadi tabanı, yumuşak tepeler ve vadinin yan duvarları.
	var hills := _hills.get_noise_2d(x, z) * 0.5 + 0.5
	var hill_amplitude := lerpf(6.0, 42.0, smoothstep(60.0, 420.0, dx))
	var walls := smoothstep(150.0, 900.0, dx) * 150.0
	var h := VALLEY_FLOOR + hills * hill_amplitude + walls

	# 2) Kampın kurulduğu plato: vadiye bakan geniş bir tepe.
	var plateau := plateau_mask(x, z)
	if plateau > 0.0:
		h = lerpf(h, _camp_height(x, z), plateau)

	# 3) Sağ taraftaki kayalık sırt.
	h += _cliff_height(x, z)

	# 4) Göl, nehir ve adacıklar.
	return _carve_water(x, z, h, river, dx)


## Sonlu farklarla yüzey normali (eğim kontrolü ve hizalama için).
func normal_at(x: float, z: float, eps: float = 0.5) -> Vector3:
	var hl := height_at(x - eps, z)
	var hr := height_at(x + eps, z)
	var hd := height_at(x, z - eps)
	var hu := height_at(x, z + eps)
	return Vector3(hl - hr, 2.0 * eps, hd - hu).normalized()


## Nokta su altında mı?
func is_underwater(x: float, z: float) -> bool:
	return height_at(x, z) < WATER_LEVEL


## Nehrin verilen z'deki merkezi ve yarı genişliği: Vector2(merkez_x, yarı_genişlik).
func river_at(z: float) -> Vector2:
	var pts := RIVER_POINTS
	var n := pts.size()
	if z >= pts[0].x:
		return Vector2(pts[0].y, 0.0)
	if z <= pts[n - 1].x:
		return Vector2(pts[n - 1].y, pts[n - 1].z)
	for i in n - 1:
		var a := pts[i]
		var b := pts[i + 1]
		if z <= a.x and z >= b.x:
			var t := (a.x - z) / (a.x - b.x)
			var p0 := pts[maxi(i - 1, 0)]
			var p3 := pts[mini(i + 2, n - 1)]
			var center := _catmull_rom(p0.y, a.y, b.y, p3.y, t)
			var width := lerpf(a.z, b.z, smoothstep(0.0, 1.0, t))
			return Vector2(center, maxf(width, 0.0))
	return Vector2(pts[0].y, 0.0)


## Kamp platosunun etkisi: 1 = tamamen plato (çayır), 0 = vadi. Kenar yöne göre PLATEAU_EDGE'den okunur.
func plateau_mask(x: float, z: float) -> float:
	var edge := plateau_edge(rad_to_deg(atan2(x, -z)))
	var r := sqrt(x * x + z * z) + _warp.get_noise_2d(x, z) * PLATEAU_WARP
	return descent_profile(r - edge.x, edge.y)


## Verilen yöndeki (derece; 0 = kuzey, 90 = doğu) plato kenarı: Vector2(iniş_başlangıcı, iniş_uzunluğu).
## PLATEAU_EDGE noktaları arasında döngüsel Catmull-Rom ile yumuşakça geçer (saf fonksiyon).
static func plateau_edge(angle_deg: float) -> Vector2:
	var n := PLATEAU_EDGE.size()
	var f := wrapf(angle_deg + 180.0, 0.0, 360.0) / PLATEAU_EDGE_STEP
	var i := floori(f)
	var t := f - float(i)
	var p0 := PLATEAU_EDGE[posmod(i - 1, n)]
	var p1 := PLATEAU_EDGE[posmod(i, n)]
	var p2 := PLATEAU_EDGE[posmod(i + 1, n)]
	var p3 := PLATEAU_EDGE[posmod(i + 2, n)]
	return Vector2(_catmull_rom(p0.x, p1.x, p2.x, p3.x, t), _catmull_rom(p0.y, p1.y, p2.y, p3.y, t))


## İnişin biçimi (saf fonksiyon): kenardan s metre ötede platonun kalan etkisi (1 = plato, 0 = vadi).
## Kenarda kısa, yumuşak bir omuzla başlar, hemen dikleşir (en dik yeri inişin ~beşte biri ötesindedir)
## ve vadiye doğru yatışır. Böylece menü kamerasından çayırın kenarının ardındaki yamaç görünmez; yamaçtaki
## ormanın yalnızca tepeleri koyu bir şerit gibi çayırın üstünde belirir.
static func descent_profile(s: float, length: float) -> float:
	if s <= 0.0:
		return 1.0
	if s >= length:
		return 0.0
	var t := s / length
	var w := t * (2.0 - t)
	return 1.0 - w * w * (3.0 - 2.0 * w)


## Ek düz alanların (FLAT_PADS) etkisi (0..1): 1 = zemin tamamen kamp düzleminde.
func flat_pad_weight(x: float, z: float) -> float:
	var weight := 0.0
	for pad in FLAT_PADS:
		var d := Vector2(x - pad.x, z - pad.y).length()
		weight = maxf(weight, 1.0 - smoothstep(pad.z, pad.z + pad.w, d))
	return weight


## Ağaç yoğunluğu (0..1). Ağaç dağıtıcısı ve arazi rengi aynı fonksiyonu kullanır.
## Platonun üstü (kampın arkasındaki çayır) vadi ormanından boştur; oradaki çam öbeklerini Forest elle
## kurar. İnişin üst kısmı sık bir orman şerididir (4. referansta çayırın ardındaki koyu orman); vadide
## ormanlık lekeler gürültüden gelir.
func forest_density(x: float, z: float) -> float:
	return _forest_density(x, z, plateau_mask(x, z))


## Kayalık sırt maskesi (0..1); arazi shader'ında taş rengi için kullanılır.
func cliff_mask(x: float, z: float) -> float:
	return clampf(_cliff_height(x, z) / 14.0, 0.0, 1.0)


## Arazi köşe rengi: r = orman, g = çayır canlılığı, b = kayalık.
func vertex_tint(x: float, z: float) -> Color:
	var plateau := plateau_mask(x, z)
	return Color(_forest_density(x, z, plateau) * 0.8, plateau, cliff_mask(x, z), 1.0)


# --- İç yardımcılar ---------------------------------------------------------

## forest_density'nin gövdesi; plato maskesi önceden hesaplanmışsa yeniden hesaplanmaz.
func _forest_density(x: float, z: float, plateau: float) -> float:
	var n := _forest.get_noise_2d(x, z) * 0.5 + 0.5
	var patches := smoothstep(0.43, 0.6, n) * (1.0 - smoothstep(0.85, 0.98, plateau))
	var r := sqrt(x * x + z * z)
	# Orman şeridi: inişin üst kısmında her yönde; kuzeydeki açı aralığında vadi tabanına da iner
	# (öbek gürültüsüyle biraz seyrelir, tekdüze bir halı gibi görünmesin).
	var angle := rad_to_deg(atan2(x, -z))
	var sector := smoothstep(BAND_SECTOR.x, BAND_SECTOR.x + 15.0, angle) * (1.0 - smoothstep(BAND_SECTOR.y - 15.0, BAND_SECTOR.y, angle))
	var valley := sector * (1.0 - smoothstep(BAND_REACH - 60.0, BAND_REACH, r)) * lerpf(0.65, 1.0, n)
	var band := (1.0 - smoothstep(0.86, 0.97, plateau)) * maxf(smoothstep(0.12, 0.4, plateau), valley)
	return maxf(patches, band) * smoothstep(22.0, 30.0, r)


func _camp_height(x: float, z: float) -> float:
	var r := sqrt(x * x + z * z)
	var flat := smoothstep(CAMP_FLAT_RADIUS, CAMP_FLAT_RADIUS + 22.0, r)
	var undulation := _detail.get_noise_2d(x, z) * 0.8 + _hills.get_noise_2d(x * 3.0, z * 3.0) * 3.2
	return undulation * flat


func _cliff_height(x: float, z: float) -> float:
	var lx := x - CLIFF_CENTER.x
	var lz := z - CLIFF_CENTER.y
	# Sırtı 30 derece döndürülmüş bir elips olarak tanımla.
	var u := lx * 0.87 + lz * 0.5
	var v := -lx * 0.5 + lz * 0.87
	var g := exp(-(u * u) / (2.0 * 14.0 * 14.0) - (v * v) / (2.0 * 30.0 * 30.0))
	if g < 0.002:
		return 0.0
	# Kamp alanını asla yükseltme: kamp düz kalmalı. Sırt artık vadi tabanından değil kamp düzleminden yükselir;
	# ahırın doğusundaki eteği uçurum gibi dikleşmesin diye kamptan uzaklaştıkça yavaşça yükselir.
	var camp_guard := smoothstep(CAMP_FLAT_RADIUS + 8.0, CAMP_FLAT_RADIUS + 32.0, sqrt(x * x + z * z))
	var ridged := _ridge.get_noise_2d(x, z) * 0.5 + 0.5
	return g * camp_guard * (12.0 + ridged * 18.0)


func _carve_water(x: float, z: float, h: float, river: Vector2, dx: float) -> float:
	var result := h
	if river.y > 0.5:
		var t := dx / river.y
		if t < 1.8:
			var bed := WATER_LEVEL - 4.0 + 6.0 * smoothstep(0.0, 1.3, t)
			var m := 1.0 - smoothstep(1.0, 1.8, t)
			result = lerpf(result, minf(result, bed), m)
	for lake in SIDE_LAKES:
		var d := Vector2(x - lake.x, z - lake.y).length() / lake.z
		if d < 1.6:
			var bed := WATER_LEVEL - lake.w + (lake.w + 2.0) * smoothstep(0.0, 1.25, d)
			result = lerpf(result, minf(result, bed), 1.0 - smoothstep(1.0, 1.6, d))
	for island in ISLANDS:
		var d := Vector2(x - island.x, z - island.y).length() / island.z
		if d < 1.0:
			var bump := WATER_LEVEL - 2.0 + (island.w + 2.0) * (1.0 - d * d)
			bump += _detail.get_noise_2d(x * 0.5, z * 0.5) * 1.5
			result = maxf(result, bump)
	return result


static func _catmull_rom(p0: float, p1: float, p2: float, p3: float, t: float) -> float:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)


static func _make_noise(p_seed: int, frequency: float, octaves: int, fractal: FastNoiseLite.FractalType) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = p_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	noise.fractal_type = fractal
	noise.fractal_octaves = octaves
	return noise
