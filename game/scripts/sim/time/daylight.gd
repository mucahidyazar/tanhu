class_name Daylight
extends RefCounted
## Güneş, ay, evre, ışık anahtarı, ışık kaynağı, ışık düzeyi ve gece sınıfı (saf): prototipin src/game/daylight.js'inden birebir
## taşınan hesap (K20, K67; time.md §3–§5, §12.3; d2/core.md §1.8; godot.md §3.5). Açılar derecedir; dakika yerel güneş saatinin
## gün dakikasıdır (0..1440; 720 öğle). Saat dilimi ve zaman denklemi yoktur. Fikstür: tests/fixtures/time_core.json
## (tools/proto_fixtures/time.mjs), sınama tests/unit/test_daylight.gd.
##
## Yön: x doğu, y yukarı, z güney (−z kuzey). Godot dünyasında da öyledir: menü kamerası kuzeye (−Z) bakar,
## azimut kuzeyden doğuya artar (0 kuzey, 90 doğu, 270 batı); World.direction_from_angles ile aynı kural.
##
## Örnek (sample) bir sözlüktür: {x, y, z, el, az}; ayda ek olarak illum (0..1). x, y, z kaynağa doğru birim yöndür.
## Gün bilgisi (day_info) {lat, dec, sunrise, sunset, civil_dawn, civil_dusk, nautical_dawn, nautical_dusk, dawn_at, dusk_at,
## phases: [[id, başı, sonu] × 6]} sözlüğüdür; Gece evresi gece yarısını aşar ([dusk_at, dawn_at]).
##   var dec := Daylight.solar_dec(269)                     # 27 Eylül: −2,12°
##   var sun := Daylight.sun_at(39.0, dec, 363.0)           # 06:03, Ordos: el −0,75°, az 92,1°
##   var moon := Daylight.moon_at(39.0, dec, 363.0, 14.91)  # dolunay batıda, ufukta
##   var info := Daylight.day_info(47.35, Daylight.camp_dec(100))   # ana kamp, 11 Nisan: doğuş 05:22, batış 18:38
##   var s := Daylight.sky_at(Daylight.sky_keys(info, 820.0, Daylight.MENU_MINUTE), 886.18)   # 4,3: ikindi→akşam 0,3
##   light.basis = Basis.looking_at(-Daylight.dir_of(sun), Vector3.UP)
##
## Önsöz yalnız sabit örneği kullanır (data/cine/birth_light.json, SkyRig). Serbest Gez'in ışığı LightStops'tan gelir (time.md §5).

const DAY := 1440.0
const NOON := 720.0
## Sinodik ay (gün).
const SYNODIC := 29.530588
## Gölge düşüren güneşin en küçük yüksekliği (derece; time.md §5.1, godot.md §4.9): ışık yönü bunun altına inmez.
const SHADOW_EL := 15.0

## Ufuk açıları (derece): kırılmalı doğuş-batış, sivil ve denizci alaca.
const H_RISE := -0.833
const H_CIVIL := -6.0
const H_NAUTICAL := -12.0
## Evre sınırları (time.md §4): Sabah 10:30'da biter, Öğle 13:30'da.
const NOON_FROM := 630.0
const NOON_TO := 810.0
## Işık anahtarları (time.md §5.2): öğle düzlüğü 11:00–12:30; varsayılan ikindi batış − 3 sa, 13:30–15:30 arasında.
const KEY_NOON_FROM := 660.0
const KEY_NOON_TO := 750.0
const GOLDEN_MIN := 810.0
const GOLDEN_MAX := 930.0
## Menü anahtarının ışık konumu: ikindi→akşam 0,3 (prototipin menü karesi).
const MENU_S := 4.3
## Işık kaynağı (time.md §5.1): gölge düşüren ay ≥20°; gök yönü az 160°, yükseklik 55°; ay 5°→10° arası karışır.
const MOON_EL := 20.0
const SKY_AZ := 160.0
const SKY_EL := 55.0
const MOON_FADE_FROM := 5.0
const MOON_FADE_TO := 10.0
const K_DUSK := 0.35
const K_NIGHT := 0.55
const K_MOON := 0.45
const DIP := 0.8
## Güneşin ışık düzeyi kırık doğrusu (d2/core.md §1.8): (−12°, 0,05) – (−6°, 0,35) – (−0,833°, 0,60) – (6°, 1).
const SUN_LEVEL := [[-12.0, 0.05], [-6.0, 0.35], [-0.833, 0.6], [6.0, 1.0]]
const MOON_FLOOR := 0.05
const MOON_GAIN := 0.3
const MOON_FULL_EL := 30.0
const DAY_LEVEL := 0.5
const DIM_LEVEL := 0.25

## Ana kamp (K67, time.md §5.5): Orhun yukarısı 47,35°K; sapma tarihten gelir, açılış dakikasının güneşi prototipin menü vektörüne
## eşit kalsın diye sabit pay eklenir (iğnelenen +7,4223° eksi solar_dec(100) +7,4350°). Güneş yüksekliğinde en çok ≈0,01°.
const CAMP_LAT := 47.35
const CAMP_DEC_OFFSET := -0.0127
## Serbest Gez'in açılış günü (11 Nisan, doy 100) ve dakikası (14:46,2): s 4,3, ışık prototipin ikindi menüsüdür.
const CAMP_DOY := 100
const MENU_MINUTE := 886.18
## Ana kampın ikindi anahtarı (13:40; time.md §5.2 «Spec: kamp 13:40»).
const CAMP_GOLDEN := 820.0
## Prototipin menü karesinin güneşi (normalize edilmemiş; time.md §5.5). Godot'nun menüsü gece kampıdır (K76): bu vektör Ev'in
## (home) ve Serbest Gez'in ilk ikindi ışığıdır.
const MENU_SUN := Vector3(-0.66, 0.6, 0.46)

## Evreler gün sırasıyla (day_info.phases), ışık durakları s sırasıyla (s ∈ [0, 6), 6 ≡ 0).
const PHASES: Array[StringName] = [&"dawn", &"morning", &"noon", &"golden", &"dusk", &"night"]
const STOPS: Array[StringName] = [&"night", &"dawn", &"morning", &"noon", &"golden", &"dusk"]
## Eski dört dilim evrelerin birleşimidir (koşul dili slice:, kayıt kartı).
const SLICE_OF := {&"dawn": &"morning", &"morning": &"morning", &"noon": &"noon", &"golden": &"evening", &"dusk": &"evening", &"night": &"night"}


## Güneşin sapması (derece): −23,44 · cos(2π(doy + 10) / 365); doy 0 = 1 Ocak.
static func solar_dec(doy: float) -> float:
	return -23.44 * cos(TAU * (doy + 10.0) / 365.0)


## Ana kampın sapması (K67): o günün sapması artı açılış payı.
static func camp_dec(doy: float) -> float:
	return solar_dec(doy) + CAMP_DEC_OFFSET


## Güneş: enlem ve sapma (derece), gün dakikası → {x, y, z, el, az}.
static func sun_at(lat: float, dec: float, minute: float) -> Dictionary:
	return place(lat, dec, (minute - NOON) / 4.0)


## Oyun içi ay modeli (time.md §5.1): güneşin saat açısından 360°·age/29,53 geride, sapması δ_güneş·cos(2π·age/29,53).
## age: ayın yaşı (gün; 0 yeni ay, 14,765 dolunay). Sonuç {x, y, z, el, az, illum}.
static func moon_at(lat: float, dec: float, minute: float, age: float) -> Dictionary:
	var k := age / SYNODIC
	var out := place(lat, dec * cos(TAU * k), (minute - NOON) / 4.0 - 360.0 * k)
	out["illum"] = (1.0 - cos(TAU * k)) / 2.0
	return out


## Saat açısı (derece, öğleden batıya artı) → {x, y, z, el, az}: x doğu, y yukarı, z güney; az kuzeyden saat yönünde.
static func place(lat: float, dec: float, ha: float) -> Dictionary:
	var sp := sin(deg_to_rad(lat))
	var cp := cos(deg_to_rad(lat))
	var sd := sin(deg_to_rad(dec))
	var cd := cos(deg_to_rad(dec))
	var h := deg_to_rad(ha)
	var east := -cd * sin(h)
	var north := sd * cp - cd * sp * cos(h)
	var up := sd * sp + cd * cp * cos(h)
	var az := rad_to_deg(atan2(east, north))
	return {
		"x": east,
		"y": up,
		"z": -north,
		"el": rad_to_deg(asin(clampf(up, -1.0, 1.0))),
		"az": az + 360.0 if az < 0.0 else az,
	}


## Örneğin yönü (kaynağa doğru birim vektör).
static func dir_of(sample: Dictionary) -> Vector3:
	return Vector3(float(sample.get("x", 0.0)), float(sample.get("y", 0.0)), float(sample.get("z", 0.0)))


## Azimut ve yükseklikten (derece) kaynağa doğru birim yön (prototipin toward'ı).
static func toward(az: float, el: float) -> Vector3:
	var ce := cos(deg_to_rad(el))
	return Vector3(sin(deg_to_rad(az)) * ce, sin(deg_to_rad(el)), -cos(deg_to_rad(az)) * ce)


## Işığın geldiği yön (gündüz kuralı, prototipin lightSource'u): güneşin azimutunda, yüksekliği en az min_el.
## Ufka yakın ya da altındaki güneş sahneyi alttan aydınlatmaz; gölgeyi ≥15° yükseklikteki ışık düşürür.
static func light_dir(sample: Dictionary, min_el: float = SHADOW_EL) -> Vector3:
	return toward(float(sample.get("az", 0.0)), maxf(float(sample.get("el", 0.0)), min_el))


## Ufuk kırılması (derece; Sæmundsson): geometrik yükseklikteki gök cismi bu kadar yukarıda görünür. Prototipte
## yoktur; yalnız gökte çizilen disk ve ışıltı için kullanılır (06:03'te güneş geometrik −0,75°, görünen −0,15°).
static func refraction(el: float) -> float:
	var h := clampf(el, -1.5, 90.0)
	var arcmin := 1.02 / tan(deg_to_rad(h + 10.3 / (h + 5.11)))
	return maxf(arcmin, 0.0) / 60.0


## Kırılmayla görünen yön (az aynı, yükseklik refraction kadar yukarıda).
static func apparent_dir(sample: Dictionary) -> Vector3:
	var el := float(sample.get("el", 0.0))
	return toward(float(sample.get("az", 0.0)), el + refraction(el))


# --- Gün bilgisi ve evreler (time.md §3, §4) --------------------------------------------------------------------

## Gün içindeki dakika olduğu gibi geçer; dışındaki [0, 1440)'a sarılır (886,18 kalan işlemiyle kaymasın).
static func wrap_minute(minute: float) -> float:
	return minute if minute >= 0.0 and minute < DAY else fposmod(minute, DAY)


## Prototipin smooth'u: clamp((x − a) / (b − a)) üstünde t²(3 − 2t).
static func smooth(a: float, b: float, x: float) -> float:
	var t := clampf((x - a) / (b - a), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


## Güneşin h0 yüksekliğe indiği saat açısı (derece, 0..180); kutup gecesi ve gündüzü kıstırılır.
static func hour_angle(lat: float, dec: float, h0: float) -> float:
	var c := (sin(deg_to_rad(h0)) - sin(deg_to_rad(lat)) * sin(deg_to_rad(dec))) / (cos(deg_to_rad(lat)) * cos(deg_to_rad(dec)))
	return rad_to_deg(acos(clampf(c, -1.0, 1.0)))


## Bir günün güneş saatleri ve evreleri (dakika). Gece evresi gece yarısını aşar: [dusk_at, dawn_at].
static func day_info(lat: float, dec: float) -> Dictionary:
	var rise := hour_angle(lat, dec, H_RISE) * 4.0
	var civil := hour_angle(lat, dec, H_CIVIL) * 4.0
	var nautical := hour_angle(lat, dec, H_NAUTICAL) * 4.0
	var sunrise := NOON - rise
	var sunset := NOON + rise
	var civil_dawn := NOON - civil
	var civil_dusk := NOON + civil
	var dawn_at := civil_dawn - 30.0
	var dusk_at := civil_dusk + 30.0
	return {
		"lat": lat, "dec": dec, "sunrise": sunrise, "sunset": sunset, "civil_dawn": civil_dawn, "civil_dusk": civil_dusk,
		"nautical_dawn": NOON - nautical, "nautical_dusk": NOON + nautical, "dawn_at": dawn_at, "dusk_at": dusk_at,
		"phases": [
			[&"dawn", dawn_at, sunrise + 30.0],
			[&"morning", sunrise + 30.0, NOON_FROM],
			[&"noon", NOON_FROM, NOON_TO],
			[&"golden", NOON_TO, sunset - 60.0],
			[&"dusk", sunset - 60.0, dusk_at],
			[&"night", dusk_at, dawn_at],
		],
	}


## Dakikanın evresi (dawn, morning, noon, golden, dusk, night).
static func phase_at(info: Dictionary, minute: float) -> StringName:
	var m := wrap_minute(minute)
	var list: Array = info["phases"]
	for i in 5:
		var row: Array = list[i]
		if m >= float(row[1]) and m < float(row[2]):
			return row[0]
	return &"night"


## Evrenin eski dilimi (morning, noon, evening, night); bilinmeyen evre "".
static func slice_of(phase: StringName) -> StringName:
	return SLICE_OF.get(phase, &"")


## Evrenin başladığı dakika (day_info'dan; bilinmeyen evre NAN).
static func phase_start(info: Dictionary, phase: StringName) -> float:
	var i := PHASES.find(phase)
	return float((info["phases"] as Array)[i][1]) if i >= 0 else NAN


# --- Işık anahtarları (time.md §5.2) ---------------------------------------------------------------------------------

## Işık anahtarları → PackedFloat64Array [m0, s0, m1, s1, ...], dakikaya göre sıralı. golden verilmezse (NAN)
## clamp(batış − 180, 13:30, 15:30); menu (NAN değilse) yalnız ana kampın 14:46,2 anahtarıdır (s 4,3).
static func sky_keys(info: Dictionary, golden: float = NAN, menu: float = NAN) -> PackedFloat64Array:
	var sunset := float(info["sunset"])
	var gold := minf(golden if is_finite(golden) else clampf(sunset - 180.0, GOLDEN_MIN, GOLDEN_MAX), sunset - 1.0)
	var keys := PackedFloat64Array([
		float(info["civil_dawn"]) - 45.0, 0.0,
		float(info["sunrise"]) - 12.0, 1.0,
		float(info["sunrise"]) + 105.0, 2.0,
		KEY_NOON_FROM, 3.0,
		KEY_NOON_TO, 3.0,
		gold, 4.0,
	])
	if is_finite(menu):
		keys.append_array(PackedFloat64Array([menu, MENU_S]))
	keys.append_array(PackedFloat64Array([sunset, 5.0, float(info["civil_dusk"]) + 45.0, 6.0]))
	return keys


## Işık konumu s ∈ [0, 6): anahtarlar arasında doğrusal; gece anahtarından ertesi gecenin sonuna düzlük (0).
static func sky_at(keys: PackedFloat64Array, minute: float) -> float:
	var m := wrap_minute(minute)
	var n := keys.size() / 2
	if n == 0 or m < keys[0] or m >= keys[(n - 1) * 2]:
		return 0.0
	for i in range(1, n):
		var bm := keys[i * 2]
		if m >= bm:
			continue
		var am := keys[(i - 1) * 2]
		var a_s := keys[(i - 1) * 2 + 1]
		var b_s := keys[i * 2 + 1]
		var s := a_s + (b_s - a_s) * (m - am) / (bm - am)
		return s - 6.0 if s >= 6.0 else s
	return 0.0


## Anahtarın dakikası: s'e ilk varılan an (s 0 gecenin sonu; bulunmazsa NAN). Sınama ve ölçüm kareleri için.
static func key_minute(keys: PackedFloat64Array, s: float) -> float:
	for i in keys.size() / 2:
		if absf(keys[i * 2 + 1] - s) < 1e-9:
			return keys[i * 2]
	return NAN


# --- Işık kaynağı (time.md §5.1) -------------------------------------------------------------------------------------

## Birim vektörler arasında küresel karışım (prototipin slerp'i).
static func slerp_dir(a: Vector3, b: Vector3, t: float) -> Vector3:
	var dot := clampf(a.x * b.x + a.y * b.y + a.z * b.z, -1.0, 1.0)
	var th := acos(dot)
	var ka := 1.0 - t
	var kb := t
	if th > 1e-6:
		var s := sin(th)
		ka = sin((1.0 - t) * th) / s
		kb = sin(t * th) / s
	var v := a * ka + b * kb
	var length := v.length()
	return v / length if length > 0.0 else v


## Güneş 15°'nin altına inerken doğrudan ışık söner: 0° ve altında 0,35, 15° ve üstünde 1.
static func k_low(el: float) -> float:
	return K_DUSK + (1.0 - K_DUSK) * smooth(0.0, SHADOW_EL, el)


## Işık kaynağı → {x, y, z, k}: kaynağa doğru birim yön ve yoğunluk çarpanı. sun ve moon aynı dakikanın sun_at ve moon_at
## sonucudur. Gündüz güneş (gölge düşüren yükseklik ≥15°); akşam ve sabah penceresinde güneşle gece kaynağı arasında küresel
## karışım ve çukur; gecede ay (≥10°, yükseklik ≥20°) ya da gök yönü. Hesap 64 bitliktir (Vector3 32 bittir; fikstür 1e-9).
static func light_source(info: Dictionary, minute: float, sun: Dictionary, moon: Dictionary) -> Dictionary:
	var m := wrap_minute(minute)
	var night_end := float(info["civil_dawn"]) - 45.0
	var dawn_key := float(info["sunrise"]) - 12.0
	var sunset := float(info["sunset"])
	var night_start := float(info["civil_dusk"]) + 45.0
	if m >= dawn_key and m < sunset:
		var d := _toward64(float(sun["az"]), maxf(float(sun["el"]), SHADOW_EL))
		return {"x": d[0], "y": d[1], "z": d[2], "k": k_low(float(sun["el"]))}
	var w := smooth(MOON_FADE_FROM, MOON_FADE_TO, float(moon["el"]))
	var k_night := K_NIGHT + K_MOON * float(moon.get("illum", 0.0)) * w
	var night_side := _toward64(SKY_AZ, SKY_EL)
	if w > 0.0:
		night_side = _slerp64(night_side, _toward64(float(moon["az"]), maxf(float(moon["el"]), MOON_EL)), w)
	var u := -1.0
	if m >= sunset and m < night_start:
		u = (m - sunset) / (night_start - sunset)
	elif m >= night_end and m < dawn_key:
		u = 1.0 - (m - night_end) / (dawn_key - night_end)
	if u < 0.0:
		return {"x": night_side[0], "y": night_side[1], "z": night_side[2], "k": k_night}
	# u: 0 güneş tarafı, 1 gece tarafı; sabah penceresi aynı yolu ters yürür.
	var out := _slerp64(_toward64(float(sun["az"]), SHADOW_EL), night_side, u)
	return {"x": out[0], "y": out[1], "z": out[2], "k": (K_DUSK + (k_night - K_DUSK) * u) * (1.0 - DIP * sin(PI * u))}


## Işık kaynağının yönü (Vector3; light_source sonucundan).
static func source_dir(src: Dictionary) -> Vector3:
	return Vector3(float(src.get("x", 0.0)), float(src.get("y", 1.0)), float(src.get("z", 0.0)))


static func _toward64(az: float, el: float) -> PackedFloat64Array:
	var ce := cos(deg_to_rad(el))
	return PackedFloat64Array([sin(deg_to_rad(az)) * ce, sin(deg_to_rad(el)), -cos(deg_to_rad(az)) * ce])


static func _slerp64(a: PackedFloat64Array, b: PackedFloat64Array, t: float) -> PackedFloat64Array:
	var dot := clampf(a[0] * b[0] + a[1] * b[1] + a[2] * b[2], -1.0, 1.0)
	var th := acos(dot)
	var ka := 1.0 - t
	var kb := t
	if th > 1e-6:
		var s := sin(th)
		ka = sin((1.0 - t) * th) / s
		kb = sin(t * th) / s
	var x := a[0] * ka + b[0] * kb
	var y := a[1] * ka + b[1] * kb
	var z := a[2] * ka + b[2] * kb
	var length := sqrt(x * x + y * y + z * z)
	if length <= 0.0:
		length = 1.0
	return PackedFloat64Array([x / length, y / length, z / length])


# --- Işık düzeyi ve gece sınıfı (d2/core.md §1.8) ------------------------------------------------------------------

static func sun_level(el: float) -> float:
	if el >= float(SUN_LEVEL[3][0]):
		return 1.0
	if el <= float(SUN_LEVEL[0][0]):
		return float(SUN_LEVEL[0][1])
	for i in range(1, SUN_LEVEL.size()):
		var e1 := float(SUN_LEVEL[i][0])
		var l1 := float(SUN_LEVEL[i][1])
		if el > e1:
			continue
		var e0 := float(SUN_LEVEL[i - 1][0])
		var l0 := float(SUN_LEVEL[i - 1][1])
		return l0 + (l1 - l0) * (el - e0) / (e1 - e0)
	return 1.0


## → 0..1: max(güneş, ay); bulut yalnız ay terimini keser, gündüz sınıfı bulutla düşmez.
static func light_level(sun_el: float, moon_el: float, illum: float, cloud: float = 0.0) -> float:
	var moon := MOON_FLOOR
	if moon_el > 0.0:
		moon = MOON_FLOOR + MOON_GAIN * illum * smooth(0.0, MOON_FULL_EL, moon_el) * (1.0 - clampf(cloud, 0.0, 1.0))
	return maxf(sun_level(sun_el), moon)


## Gece sınıfı: ışık havuzu (ateş, meşale, fener) lit; sonra day (≥0,5), dim (≥0,25), dark. Emek, hava, ordu ve hayvan okur.
static func night_class(level: float, lit: bool = false) -> StringName:
	if lit:
		return &"lit"
	if level >= DAY_LEVEL:
		return &"day"
	return &"dim" if level >= DIM_LEVEL else &"dark"
