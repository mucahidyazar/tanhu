class_name WeatherData
extends RefCounted
## Havanın tabloları (saf, önbellekli; godot.md §1 madde 4, §2): data/weather/types.json (17 tür ve Kara Boran: parametre vektörü,
## etki sayıları, ses verisi; alt olaylar, cephe, işaret, kar örtüsü ve kabuk), climates.json (paylar, gün içi eğriler, hâkim rüzgâr,
## dünya → iklim, zon ayarı) ve weights.json (ayarlı ağırlıklar; tools/weather_calibrate.gd yazar, weather.md §5.6). İlk çağrıda okunur;
## testler reload() ile tazeler. Sıcak döngüler tür kimliği yerine sıra numarası (TYPE_IDS'teki yeri) kullanır.
##
## Parametre vektörü (weather.md §3.3) PackedFloat64Array'dir: P_* sırası. vis INF sınırsız görüştür. Ton ve sis rengi vektörün
## sonundadır (P_TONE_R.., P_TINT_R.., P_HAS_TINT).
##   var p := WeatherData.params_of(WeatherData.index_of(&"rain"))
##   p[WeatherData.P_WIND]                       # 4.0
##   WeatherData.row(&"orkhon", &"camp_spring")  # payların satırı

const TYPES_PATH := "res://data/weather/types.json"
const CLIMATES_PATH := "res://data/weather/climates.json"
const WEIGHTS_PATH := "res://data/weather/weights.json"

const GROUP_DRY := 0
const GROUP_GREY := 1
const GROUP_WET := 2
const GROUP_STORM := 3
const GROUPS := {"dry": GROUP_DRY, "grey": GROUP_GREY, "wet": GROUP_WET, "storm": GROUP_STORM}

const STRIKE_NONE := 0
const STRIKE_WET := 1
const STRIKE_DRY := 2

## Parametre vektörünün sırası (prototipin PARAM_KEYS'i; karışım bu sırayla yürür).
const PARAM_KEYS: Array[String] = [
	"cloud", "cover", "cover_sky", "shadow_k", "cloud_speed_k", "dark", "sun_k", "hemi_k", "exp_k", "fog_near_k", "fog_far_k",
	"fog_mix", "sat", "con", "rain", "snow", "hail", "dust", "points", "splashes", "wind", "gust", "vis", "mask", "wet_ground",
	"wet_felt", "snow_rate", "storm", "fog_far_abs",
]
const P_CLOUD := 0
const P_COVER := 1
const P_COVER_SKY := 2
const P_SHADOW_K := 3
const P_CLOUD_SPEED_K := 4
const P_DARK := 5
const P_SUN_K := 6
const P_HEMI_K := 7
const P_EXP_K := 8
const P_FOG_NEAR_K := 9
const P_FOG_FAR_K := 10
const P_FOG_MIX := 11
const P_SAT := 12
const P_CON := 13
const P_RAIN := 14
const P_SNOW := 15
const P_HAIL := 16
const P_DUST := 17
const P_POINTS := 18
const P_SPLASHES := 19
const P_WIND := 20
const P_GUST := 21
const P_VIS := 22
const P_MASK := 23
const P_WET_GROUND := 24
const P_WET_FELT := 25
const P_SNOW_RATE := 26
const P_STORM := 27
const P_FOG_FAR_ABS := 28
const P_TONE_R := 29
const P_TONE_G := 30
const P_TONE_B := 31
const P_TINT_R := 32
const P_TINT_G := 33
const P_TINT_B := 34
const P_HAS_TINT := 35
const P_COUNT := 36

## Etki satırı (weather.md §8.1; prototipin effects()): F_* sırası. NAN «yok» demektir (track_snow_k, track_abs).
const FX_KEYS: Array[String] = ["track_k", "track_snow_k", "track_abs", "scent_k", "scent_dir", "fire_k", "fire_out_s", "fire_ring",
	"douse", "dry_k", "cart_k", "fatigue_k", "cone_k"]
const F_TRACK_K := 0
const F_TRACK_SNOW_K := 1
const F_TRACK_ABS := 2
const F_SCENT_K := 3
const F_SCENT_DIR := 4
const F_FIRE_K := 5
const F_FIRE_OUT_S := 6
const F_FIRE_RING := 7
const F_DOUSE := 8
const F_DRY_K := 9
const F_CART_K := 10
const F_FATIGUE_K := 11
const F_CONE_K := 12
const F_COUNT := 13

static var _loaded := false
static var _types: Dictionary = {}
static var _climates: Dictionary = {}
static var _weights: Dictionary = {}
static var type_ids := PackedStringArray()
static var type_names: Array[StringName] = []
static var _index: Dictionary = {}
static var sev := PackedInt32Array()
static var group := PackedInt32Array()
static var wet := PackedByteArray()
static var dur_lo := PackedFloat64Array()
static var dur_hi := PackedFloat64Array()
static var has_dur := PackedByteArray()
static var _params: Array[PackedFloat64Array] = []
static var _params_dry: Array[PackedFloat64Array] = []
static var _fx: Array[PackedFloat64Array] = []
static var cart_lock := PackedByteArray()
static var strike := PackedInt32Array()
static var _audio: Array[Dictionary] = []
static var _curves: Dictionary = {}
static var _curve_of: Array[PackedFloat64Array] = []
static var cols := PackedStringArray()


## Tabloları dosyadan yeniden okur (testler ve araç).
static func reload() -> void:
	_loaded = false
	_ensure()


static func _ensure() -> void:
	if _loaded:
		return
	_loaded = true
	_types = _read(TYPES_PATH)
	_climates = _read(CLIMATES_PATH)
	_weights = _read(WEIGHTS_PATH) if FileAccess.file_exists(WEIGHTS_PATH) else {}
	_build_types()
	_build_curves()


static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("[weather] veri dosyası yok: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("[weather] veri dosyası bozuk: %s" % path)
		return {}
	return parsed


static func _build_types() -> void:
	type_ids = PackedStringArray()
	type_names.clear()
	_index.clear()
	sev = PackedInt32Array()
	group = PackedInt32Array()
	wet = PackedByteArray()
	dur_lo = PackedFloat64Array()
	dur_hi = PackedFloat64Array()
	has_dur = PackedByteArray()
	_params.clear()
	_params_dry.clear()
	_fx.clear()
	cart_lock = PackedByteArray()
	strike = PackedInt32Array()
	_audio.clear()
	var defaults: Dictionary = _types.get("defaults", {})
	var dp: Dictionary = defaults.get("params", {})
	var dfx: Dictionary = defaults.get("fx", {})
	var daud: Dictionary = defaults.get("audio", {})
	var all: Dictionary = _types.get("types", {})
	var dry_dust: Dictionary = _types.get("dry_dust", {})
	for id: String in _types.get("order", []):
		var t: Dictionary = all.get(id, {})
		var i := type_ids.size()
		type_ids.append(id)
		type_names.append(StringName(id))
		_index[id] = i
		_index[StringName(id)] = i
		sev.append(int(t.get("sev", 0)))
		group.append(int(GROUPS.get(str(t.get("group", "dry")), GROUP_DRY)))
		wet.append(1 if bool(t.get("wet", false)) else 0)
		var d: Variant = t.get("dur")
		has_dur.append(1 if d is Array else 0)
		dur_lo.append(float(d[0]) if d is Array else 1.0)
		dur_hi.append(float(d[1]) if d is Array else 1.0)
		var p := _vector(dp, t.get("params", {}))
		_params.append(p)
		if dry_dust.has(id):
			var merged: Dictionary = (t.get("params", {}) as Dictionary).duplicate()
			merged.merge(dry_dust[id], true)
			_params_dry.append(_vector(dp, merged))
		else:
			_params_dry.append(p)
		var fx := PackedFloat64Array()
		fx.resize(F_COUNT)
		var tfx: Dictionary = t.get("fx", {})
		for k in F_COUNT:
			var key := FX_KEYS[k]
			var v: Variant = tfx.get(key, dfx.get(key))
			fx[k] = NAN if v == null else float(v)
		_fx.append(fx)
		cart_lock.append(1 if bool(tfx.get("cart_lock", dfx.get("cart_lock", false))) else 0)
		var st: Variant = tfx.get("strike", null)
		strike.append(STRIKE_WET if st == "wet" else STRIKE_DRY if st == "dry" else STRIKE_NONE)
		var aud: Dictionary = daud.duplicate(true)
		aud.merge(t.get("audio", {}), true)
		_audio.append(aud)


## Tür vektörü: varsayılan + türün alanları.
static func _vector(defaults: Dictionary, over: Dictionary) -> PackedFloat64Array:
	var p := PackedFloat64Array()
	p.resize(P_COUNT)
	for k in PARAM_KEYS.size():
		var key := PARAM_KEYS[k]
		var v: Variant = over.get(key, defaults.get(key))
		if key == "vis":
			p[k] = INF if v == null else float(v)
		else:
			p[k] = 0.0 if v == null else float(v)
	var tone: Array = over.get("tone", defaults.get("tone", [1, 1, 1]))
	p[P_TONE_R] = float(tone[0])
	p[P_TONE_G] = float(tone[1])
	p[P_TONE_B] = float(tone[2])
	var tint: Variant = over.get("fog_tint", null)
	if tint is String and (tint as String).length() >= 7:
		var hex := tint as String
		p[P_TINT_R] = float(hex.substr(1, 2).hex_to_int()) / 255.0
		p[P_TINT_G] = float(hex.substr(3, 2).hex_to_int()) / 255.0
		p[P_TINT_B] = float(hex.substr(5, 2).hex_to_int()) / 255.0
		p[P_HAS_TINT] = 1.0
	else:
		p[P_TINT_R] = 1.0
		p[P_TINT_G] = 1.0
		p[P_TINT_B] = 1.0
		p[P_HAS_TINT] = 0.0
	return p


static func _build_curves() -> void:
	_curves.clear()
	var spans: Dictionary = _climates.get("curves", {})
	for name: String in spans:
		var out := PackedFloat64Array()
		out.resize(24)
		out.fill(1.0)
		for span: Array in spans[name]:
			for h in range(int(span[0]), int(span[1]) + 1):
				out[h] = float(span[2])
		var total := 0.0
		for h in 24:
			total += out[h]
		var mean := total / 24.0
		for h in 24:
			out[h] = out[h] / mean
		_curves[name] = out
	_curve_of.clear()
	var of: Dictionary = _climates.get("curve_of", {})
	for id in type_ids:
		_curve_of.append(_curves.get(str(of.get(id, "flat")), _curves.get("flat", PackedFloat64Array())))
	cols = PackedStringArray(_climates.get("cols", []))


# --- Türler ---------------------------------------------------------------------------------------------------------

static func count() -> int:
	_ensure()
	return type_ids.size()


## Tür kimlikleri (sıra numarasıyla).
static func ids() -> PackedStringArray:
	_ensure()
	return type_ids


## Tür kimliğinin sıra numarası (yoksa −1).
static func index_of(id: Variant) -> int:
	_ensure()
	return int(_index.get(id, -1))


static func id_of(index: int) -> StringName:
	_ensure()
	return type_names[index] if index >= 0 and index < type_names.size() else &""


static func has_type(id: Variant) -> bool:
	return index_of(id) >= 0


## Türün parametre vektörü (paylaşılır: yazılmaz). dry: kuru iklimde rüzgâr ve fırtına toz kaldırır (weather.md §3.4).
static func params_of(index: int, dry: bool = false) -> PackedFloat64Array:
	_ensure()
	return _params_dry[index] if dry else _params[index]


## Türün etki satırı (F_*; paylaşılır).
static func fx_of(index: int) -> PackedFloat64Array:
	_ensure()
	return _fx[index]


## Türün ses verisi (weather.md §3.5; paylaşılır).
static func audio_of(index: int) -> Dictionary:
	_ensure()
	return _audio[index]


## Türün tablo satırı (types.json'daki biçim).
static func type_def(id: Variant) -> Dictionary:
	_ensure()
	return (_types.get("types", {}) as Dictionary).get(str(id), {})


## types.json'un bir bölümü (sub, fronts, signs, snowpack, crust, sign_line, say, say_kind, wake, heavy_prep, bow_wet, dry_dust).
static func section(name: String) -> Variant:
	_ensure()
	return _types.get(name)


## Gün içi eğri (24 saat, ortalaması 1).
static func curve(name: String) -> PackedFloat64Array:
	_ensure()
	return _curves.get(name, PackedFloat64Array())


static func curve_of(index: int) -> PackedFloat64Array:
	_ensure()
	return _curve_of[index]


static func type_name_tr(id: Variant) -> String:
	return str(type_def(id).get("tr", id))


static func type_name_en(id: Variant) -> String:
	return str(type_def(id).get("en", id))


# --- İklimler -------------------------------------------------------------------------------------------------------

static func climate_ids() -> PackedStringArray:
	_ensure()
	return PackedStringArray((_climates.get("rows", {}) as Dictionary).keys())


static func seasons_of(climate: String) -> PackedStringArray:
	_ensure()
	return PackedStringArray(((_climates.get("rows", {}) as Dictionary).get(climate, {}) as Dictionary).keys())


## İklim satırı (yoksa boş): share (cols sırasıyla dizi), p_hail, wind, showery, dry, dur.
static func row(climate: String, season: String) -> Dictionary:
	_ensure()
	return ((_climates.get("rows", {}) as Dictionary).get(climate, {}) as Dictionary).get(season, {})


static func has_row(climate: String, season: String) -> bool:
	return not row(climate, season).is_empty()


## İklimin temsilî enlemi (kar örtüsünün güneş terimi; weather.md §5.9).
static func climate_lat(climate: String) -> float:
	_ensure()
	return float((_climates.get("climate_lat", {}) as Dictionary).get(climate, 45.0))


static func zone_climate(zone: String) -> String:
	_ensure()
	return str((_climates.get("zone_climate", {}) as Dictionary).get(zone, ""))


static func pack_zones() -> PackedStringArray:
	_ensure()
	return PackedStringArray(_climates.get("pack_zones", []))


## Hedef paylar (weather.md §5.4): exclude türleri 0, kalan 100'e ölçeklenir. Sıra cols'undur (toplamın kayan nokta sırası prototiple
## aynı kalsın). Döner: {tür: yüzde}.
static func target_shares(climate: String, season: String, exclude: PackedStringArray = PackedStringArray()) -> Dictionary:
	var r := row(climate, season)
	if r.is_empty():
		push_error("[weather] bilinmeyen iklim satırı %s:%s" % [climate, season])
		return {}
	var share: Array = r.get("share", [])
	var out := {}
	var tot := 0.0
	for i in mini(share.size(), cols.size()):
		var id := cols[i]
		var v := float(share[i])
		if exclude.has(id) or not (v > 0.0):
			continue
		out[id] = v
		tot += v
	for id: String in out:
		out[id] = float(out[id]) * 100.0 / tot
	return out


## Ayar anahtarı: iklim:mevsim:sıralı dışlama (weights.json'un anahtarı).
static func weight_key(climate: String, season: String, exclude: PackedStringArray) -> String:
	var ex := exclude.duplicate()
	ex.sort()
	return "%s:%s:%s" % [climate, season, ",".join(ex)]


## Gömülü ayarlı ağırlık (yoksa boş): {tür: ağırlık}.
static func embedded_weights(climate: String, season: String, exclude: PackedStringArray) -> Dictionary:
	_ensure()
	return (_weights.get("weights", {}) as Dictionary).get(weight_key(climate, season, exclude), {})


static func weights_table() -> Dictionary:
	_ensure()
	return _weights


## Zonun hava ayarı (weather.md §4.1, §12.3; prototipin zoneWeather'ı): spec > zones > zone_climate (takvim mevsimiyle) > orkhon.
## Döner: {climate, season ("calendar" ya da sabit satır), season_rows, exclude, accumulate (mevsim listesi ya da true), snow_felt,
## dur, lat, quiet_heavy, lake}.
static func zone_config(zone: String, spec: Dictionary = {}) -> Dictionary:
	_ensure()
	var base: Dictionary = (_climates.get("zones", {}) as Dictionary).get(zone, {})
	var climate := str(spec.get("climate", base.get("climate", zone_climate(zone))))
	if climate.is_empty():
		climate = "orkhon"
	var acc: Variant = spec.get("accumulate_snow", base.get("accumulate_snow", true))
	return {
		"zone": zone,
		"climate": climate,
		"season": str(spec.get("season", base.get("season", "calendar"))),
		"season_rows": spec.get("season_rows", base.get("season_rows", {})),
		"exclude": PackedStringArray(spec.get("exclude", base.get("exclude", []))),
		"accumulate": acc,
		"snow_felt": float(spec.get("snow_felt", base.get("snow_felt", 1.0 if acc is bool and not acc else 0.5))),
		"dur": spec.get("dur", base.get("dur", {})),
		"lat": float(spec.get("lat", base.get("lat", climate_lat(climate)))),
		"quiet_heavy": str(spec.get("quiet_heavy", base.get("quiet_heavy", ""))),
		"lake": bool(spec.get("lake", base.get("lake", false))),
	}


## Kar o mevsimde tutar mı (zon ayarının accumulate'ı: true, false ya da mevsim listesi; K67: kampta yalnız kış)?
static func accumulates(config: Dictionary, season: String) -> bool:
	var acc: Variant = config.get("accumulate", true)
	if acc is bool:
		return acc
	if acc is Array or acc is PackedStringArray:
		return season in acc
	return true


## Zonun o mevsimdeki satırı: kampın satırları (season_rows) ya da mevsimin kendisi; sabit mevsimli zonda o satır.
static func season_row(config: Dictionary, calendar_season: String) -> String:
	var fixed := str(config.get("season", "calendar"))
	if fixed != "calendar":
		return fixed
	var rows: Dictionary = config.get("season_rows", {})
	return str(rows.get(calendar_season, calendar_season))
