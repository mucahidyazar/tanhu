class_name SnowPack
extends RefCounted
## Kar örtüsü ve Kar Kabuğu (saf; zon durumu, kayıtta; weather.md §5.9, H22; d2/core.md §3.6; d2/weather-model.json v2). Sıcaklık
## modellenmez (K1): örtü yağışın ve güneşin sırasıdır, kabuk sıra kuralıdır.
##   snowpack ∈ [0, 1] (1 ≈ 40 cm), saatte bir: + kar 0,035 · yoğun kar 0,09 · tipi ve Kara Boran 0,05 · sulu kar 0,01;
##   − yağışsız her saat 0,004, güneş >15° ve tür açık ya da bulutluysa ek 0,03; bahar ×3.
##   Derin kar: 06:00'da snowpack ≥0,6. Kabuk: derin kar ve [o gün (06–20) ≥1 sa sulu kar ya da son 24 sa'te yoğun kar ya da tipi
##   bitmiş ve 10:00–15:00 tümüyle açık (tohumlu %12)] ve ardından açık gece (20–06 arası ≥6 sa açık ya da bulutlu) → şafakta kabuk,
##   5–10 gün (tohumlu); örtü <0,3 ya da bahar erken bitirir; kabuk sürerken yenisi oluşmaz.
## hour() saat başında, geçen saatin tür payıyla çağrılır (frac[i] sa, WeatherData sırasıyla). Prototipin SnowPack'inden birebir.
## winter_stats() W26'dır: gerçek planlayıcıyla sabit tohumlu 150 kış.

const SALT_GLAZE := 0x91a2e
const SALT_CRUST := 0xc2057
## W26'nın sabit tohumu (d2/weather-model.json: 2048377054).
const W26_SEED := 0x7a17c0de

## hour() seçenekleri (yeniden kullanılır): mevsim, enlem, sapma (güneş terimi), sabit yükseklik (NAN değilse), tohum, zon özeti.
class Opts:
	extends RefCounted
	var season: StringName = &"winter"
	var lat := 45.0
	var dec := 0.0
	var fixed_el := NAN
	var seed := 0
	var zone_hash := 0


static var _tables_ready := false
static var _gain := PackedFloat64Array()
static var _precip := PackedByteArray()
static var _settle := 0.004
static var _sun_extra := 0.03
static var _sun_min_el := 15.0
static var _spring_k := 3.0
static var _deep_at := 0.6
static var _read_hour := 6
static var _sleet_hours := 1.0
static var _day_from := 6
static var _day_to := 20
static var _noon_from := 10
static var _noon_to := 15
static var _glaze_p := 0.12
static var _night_from := 20
static var _night_to := 6
static var _night_hours := 6.0
static var _days_lo := 5
static var _days_hi := 10
static var _end_below := 0.3
static var _i_clear := 0
static var _i_cloud := 1
static var _i_sleet := 0
static var _i_heavy := 0
static var _i_bliz := 0

var snowpack := 0.0
## Kalan gün; 0 yok.
var crust := 0
var deep := false
var sleet_h := 0.0
var glaze := false
var noon_clear := true
var night_clear := 0.0
var last_heavy_end := -INF
## Son hour(): 1 kabuk oluştu, −1 bitti.
var event := 0
var formed := 0


static func _tables() -> void:
	if _tables_ready:
		return
	_tables_ready = true
	var n := WeatherData.count()
	_gain.resize(n)
	_precip.resize(n)
	var sp: Dictionary = WeatherData.section("snowpack")
	var cr: Dictionary = WeatherData.section("crust")
	var gain: Dictionary = sp.get("gain", {})
	for i in n:
		_gain[i] = float(gain.get(String(WeatherData.id_of(i)), 0.0))
		_precip[i] = WeatherData.wet[i]
	_settle = float(sp.get("settle", 0.004))
	_sun_extra = float(sp.get("sun_extra", 0.03))
	_sun_min_el = float(sp.get("sun_min_el", 15.0))
	_spring_k = float(sp.get("spring_k", 3.0))
	_deep_at = float(sp.get("deep_at", 0.6))
	_read_hour = int(sp.get("read_hour", 6))
	_sleet_hours = float(cr.get("sleet_hours", 1.0))
	_day_from = int(cr.get("day_from", 6))
	_day_to = int(cr.get("day_to", 20))
	_noon_from = int(cr.get("noon", [10, 15])[0])
	_noon_to = int(cr.get("noon", [10, 15])[1])
	_glaze_p = float(cr.get("glaze_p", 0.12))
	_night_from = int(cr.get("night", [20, 6])[0])
	_night_to = int(cr.get("night", [20, 6])[1])
	_night_hours = float(cr.get("night_hours", 6.0))
	_days_lo = int(cr.get("days", [5, 10])[0])
	_days_hi = int(cr.get("days", [5, 10])[1])
	_end_below = float(cr.get("end_below", 0.3))
	_i_clear = WeatherData.index_of(&"clear")
	_i_cloud = WeatherData.index_of(&"cloud")
	_i_sleet = WeatherData.index_of(&"sleet")
	_i_heavy = WeatherData.index_of(&"heavy_snow")
	_i_bliz = WeatherData.index_of(&"blizzard")


func _init() -> void:
	_tables()
	reset()


func reset(p_snowpack: float = 0.0) -> SnowPack:
	_tables()
	snowpack = p_snowpack
	crust = 0
	deep = p_snowpack >= _deep_at
	sleet_h = 0.0
	glaze = false
	noon_clear = true
	night_clear = 0.0
	last_heavy_end = -INF
	event = 0
	formed = 0
	return self


static func deep_at() -> float:
	_tables()
	return _deep_at


## h: geçen saatin başı (hourAbs, tam sayı); frac: o saatte türlerin süresi.
func hour(h: float, frac: PackedFloat64Array, o: Opts) -> SnowPack:
	event = 0
	var hd := int(WeatherRng.js_round(WeatherPlanner.hod(h)))
	var gain := 0.0
	var dry := 0.0
	for i in frac.size():
		var f := frac[i]
		if not (f > 0.0):
			continue
		gain += f * _gain[i]
		if not _precip[i]:
			dry += f
	var sunny := frac[_i_clear] + frac[_i_cloud]
	var loss := dry * _settle
	if sunny > 0.0 and sun_el(o, h + 0.5) > _sun_min_el:
		loss += sunny * _sun_extra
	if o.season == &"spring":
		loss *= _spring_k
	snowpack = clampf(snowpack + gain - loss, 0.0, 1.0)
	# Kabuk sıra kaydı: gündüz sulu kar, öğle açıklığı, gece açıklığı, son yoğun kar.
	if hd >= _day_from and hd < _day_to:
		sleet_h += frac[_i_sleet]
	if hd >= _night_from or hd < _night_to:
		night_clear += sunny
	if frac[_i_heavy] + frac[_i_bliz] > 0.0:
		last_heavy_end = h + 1.0
	if hd >= _noon_from and hd < _noon_to and frac[_i_clear] < 1.0 - 1e-9:
		noon_clear = false
	if hd == _noon_to - 1 and deep and noon_clear and last_heavy_end > h + 1.0 - 24.0:
		if WeatherRng.unit(o.seed, o.zone_hash, floori(h / 24.0), SALT_GLAZE) < _glaze_p:
			glaze = true
	# Kabuk erken biter: örtü <0,3 ya da bahar (§5.9).
	if crust > 0 and (snowpack < _end_below or o.season == &"spring"):
		crust = 0
		event = -1
	# 06:00: dünün sırası şafakta kabuğa döner; sonra bugünün derin karı okunur (saatin sonu 06:00 ise bu saat 05:00'tir).
	if hd == _read_hour - 1:
		_dawn(h + 1.0, o)
	return self


func _dawn(h: float, o: Opts) -> void:
	if crust > 0:
		crust -= 1
		if crust == 0:
			event = -1
	elif deep and (sleet_h >= _sleet_hours or glaze) and night_clear >= _night_hours and snowpack >= _end_below and o.season != &"spring":
		var r := WeatherRng.unit(o.seed, o.zone_hash, floori(h / 24.0), SALT_CRUST)
		crust = _days_lo + floori(r * float(_days_hi - _days_lo + 1))
		formed += 1
		event = 1
	deep = snowpack >= _deep_at
	sleet_h = 0.0
	glaze = false
	noon_clear = true
	night_clear = 0.0


## Güneşin yüksekliği (derece) hourAbs'ta: sabitse o, değilse enlem ve sapmadan (Daylight.sun_at'in el'i, sözlüksüz).
static func sun_el(o: Opts, h: float) -> float:
	if not is_nan(o.fixed_el):
		return o.fixed_el
	var minute := WeatherPlanner.hod(h) * 60.0
	var ha := deg_to_rad((minute - 720.0) / 4.0)
	var sp := sin(deg_to_rad(o.lat))
	var cp := cos(deg_to_rad(o.lat))
	var sd := sin(deg_to_rad(o.dec))
	var cd := cos(deg_to_rad(o.dec))
	var up := sd * sp + cd * cp * cos(ha)
	return rad_to_deg(asin(clampf(up, -1.0, 1.0)))


func to_dict() -> Dictionary:
	return {"snowpack": WeatherRng.js_round(snowpack * 1000.0) / 1000.0, "crust": crust}


func from_dict(o: Variant) -> SnowPack:
	var d: Dictionary = o if o is Dictionary else {}
	var sv: Variant = d.get("snowpack")
	reset(clampf(float(sv) if (sv is float or sv is int) else 0.0, 0.0, 1.0))
	var cv: Variant = d.get("crust")
	crust = maxi(0, int(WeatherRng.js_round(float(cv)))) if (cv is float or cv is int) else 0
	return self


## Plandan [h0, h1) aralığındaki türlerin süresi (sa) frac'a (WeatherData sırasıyla).
static func type_hours(plan: Array[WeatherSegment], h0: float, h1: float, frac: PackedFloat64Array, prev: WeatherSegment = null) -> PackedFloat64Array:
	frac.fill(0.0)
	if prev and prev.t1 > h0:
		frac[prev.type] += minf(prev.t1, h1) - maxf(prev.t0, h0)
	for s in plan:
		if s.t0 >= h1:
			break
		var ov := minf(s.t1, h1) - maxf(s.t0, h0)
		if ov > 0.0:
			frac[s.type] += ov
	return frac


## W26 (weather.md §5.9, §15): gerçek planlayıcıyla kışlar: derin kar günü payı, kış başına kabuk, kabuklu gün payı. Kış 16 Kasım'da
## (doy 319) sıfır örtüyle açılır, 120 gün sürer; güneş iklimin enleminde gerçek sapmayla. opts: winters (150), seed (W26_SEED),
## exclude, lat, zone (iklim), days (120).
static func winter_stats(climate: String, opts: Dictionary = {}) -> Dictionary:
	_tables()
	var winters := int(opts.get("winters", 150))
	var p_seed := int(opts.get("seed", W26_SEED))
	var ex := PackedStringArray(opts.get("exclude", []))
	var p_zone := str(opts.get("zone", climate))
	var days := int(opts.get("days", 120))
	var p := WeatherPlanner.new({"climate": climate, "season": "winter", "exclude": ex, "seed": p_seed, "zone": p_zone})
	var pack := SnowPack.new()
	var frac := PackedFloat64Array()
	frac.resize(WeatherData.count())
	var o := Opts.new()
	o.season = &"winter"
	o.lat = float(opts.get("lat", WeatherData.climate_lat(climate)))
	o.seed = p_seed
	o.zone_hash = WeatherRng.str_hash(p_zone)
	var deep_days := 0
	var crust_days := 0
	var total := 0
	var formed_n := 0
	p.start(0.0)
	for w in winters:
		formed_n += pack.formed
		pack.reset()
		var h0 := w * days * 24
		for d in days:
			o.dec = Daylight.solar_dec(float((319 + d) % 365))
			for k in 24:
				var h := float(h0 + d * 24 + k)
				p.advance(h)
				type_hours(p.plan, h, h + 1.0, frac)
				pack.hour(h, frac, o)
				if k == _read_hour - 1:
					total += 1
					if pack.deep:
						deep_days += 1
					if pack.crust > 0:
						crust_days += 1
	formed_n += pack.formed
	return {"deep_snow_share": float(deep_days) / float(total), "crust_per_winter": float(formed_n) / float(winters),
		"crust_day_share": float(crust_days) / float(total), "winters": winters, "days": total}
