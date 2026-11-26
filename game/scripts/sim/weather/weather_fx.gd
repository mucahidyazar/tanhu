class_name WeatherFx
extends RefCounted
## Havanın fiziksel yüzü (saf; weather.md §8, §12.5, H17): bütün okuyanlar bu tek nesneyi okur, her kare yerinde yazılır. Hava yalnız
## fiziksel değeri verir (rüzgâr, görüş, bulut, ıslaklık, çamur, kar örtüsü, kabuk, araba, kurutma, dolu, şimşek); her tepki tablosunun
## tek sahibi vardır. Ayrıca karışım (blend: iki tür vektörünün yumuşaması, §5.8), kilidin alanları (lock_value, apply_lock) ve okuyan
## yardımcıları (hear_k, fog_factor, thunder_mask, scent_dir_k, spread_wet, wind_gain, flow_of). Prototipin weather-core.js fx
## bölümünden birebir.

var type: StringName = &"clear"
var sev := 0
## Yaklaşan cephe {type, in_h} ya da boş.
var front: Dictionary = {}
var wind := 0.0
var gust := 0.0
## Akış yönü (birim; x doğu, z güney). Menünün U.uWindDir'i (0,8; 0,45) ile aynı yönde.
var dir_x := 0.871
var dir_z := 0.49
var cloud := 0.0
var vis := INF
var fog_k := INF
var mask := 0.0
var thunder_mask := 0.0
var hear_k := 1.0
var flash_k := 0.0
var track_k := 1.0
## Tipide iz ömrü mutlak sn (NAN: yok).
var track_abs := NAN
var scent_k := 1.0
var calm := false
var fire_k := 1.0
var fire_out_s := 0.0
var fire_ring := 1.0
var douse := 0.0
var dry_k := 1.0
var wet_ground := 0.0
var wet_felt := 0.0
var mud := 0.0
var puddle := 0.0
var snow_fresh := 0.0
var wet_bow := 0.0
var cart_k := 1.0
var rough_k := 1.0
var cart_lock := false
var snowpack := 0.0
var deep_snow := false
var crust := false
var gale_damage := false
## Dolu {size, minutes} ya da boş.
var hail: Dictionary = {}
## Zemindeki dolu beyazlığı 0..1 (§9.8 HAIL_WHITE: dolu sürerken birikir, 0,5 sa'te erir; WeatherSim yazar).
var hail_white := 0.0
var strike_risk := 0.0
var moon_seen := false
var blizzard := false
var fatigue_k := 1.0
var cone_k := 1.0
var snow_felt := 1.0
## Etkin pinFx (okuyan kendi sayısını korur) ya da boş.
var pin: Dictionary = {}


## fx_for'un seçenekleri (yeniden kullanılır; prototipin _fxOpts'u).
class Opts:
	extends RefCounted
	var a := 0
	var b := 0
	var k := 1.0
	var type := -1
	var front: Dictionary = {}
	var dir_x := 0.871
	var dir_z := 0.49
	var gust := 0.0
	var flash_k := 0.0
	var thunder_mask := 0.0
	var calm := false
	var pin: Dictionary = {}
	var night := false
	var moon_up := false
	var accumulate := true
	var snow_felt := 0.5
	var fog_vis := INF
	var pack: SnowPack
	var hail: Dictionary = {}
	var strike_risk := 0.0
	var snow_ground := false


## Menünün kimliği (açık, kuru): okuyanlar menüde ne okursa bugünkü sayıdır.
func identity() -> WeatherFx:
	type = &"clear"
	sev = 0
	front = {}
	wind = 0.0
	gust = 0.0
	dir_x = 0.871
	dir_z = 0.49
	cloud = 0.0
	vis = INF
	fog_k = INF
	mask = 0.0
	thunder_mask = 0.0
	hear_k = 1.0
	flash_k = 0.0
	track_k = 1.0
	track_abs = NAN
	scent_k = 1.0
	calm = false
	fire_k = 1.0
	fire_out_s = 0.0
	fire_ring = 1.0
	douse = 0.0
	dry_k = 1.0
	wet_ground = 0.0
	wet_felt = 0.0
	mud = 0.0
	puddle = 0.0
	snow_fresh = 0.0
	wet_bow = 0.0
	cart_k = 1.0
	rough_k = 1.0
	cart_lock = false
	snowpack = 0.0
	deep_snow = false
	crust = false
	gale_damage = false
	hail = {}
	hail_white = 0.0
	strike_risk = 0.0
	moon_seen = false
	blizzard = false
	fatigue_k = 1.0
	cone_k = 1.0
	snow_felt = 1.0
	pin = {}
	return self


## fx'i yazar (§8): p karışmış vektör, wet ıslaklık; o.a, o.b, o.k karışan türler (tür sayıları için; fire_out_s ve cart_lock baskın
## türden).
func write(p: PackedFloat64Array, wet: WetState, o: Opts) -> WeatherFx:
	var a := o.a
	var b := o.b
	var k := o.k
	var t := o.type if o.type >= 0 else (b if k >= 0.5 else a)
	var ra := WeatherData.fx_of(a)
	var rb := WeatherData.fx_of(b)
	var fa := rb if k >= 0.5 else ra
	var dom := b if k >= 0.5 else a
	type = WeatherData.id_of(t)
	sev = WeatherData.sev[t]
	front = o.front
	wind = p[WeatherData.P_WIND]
	gust = o.gust
	dir_x = o.dir_x
	dir_z = o.dir_z
	cloud = p[WeatherData.P_CLOUD]
	vis = minf(p[WeatherData.P_VIS], o.fog_vis)
	fog_k = vis
	mask = p[WeatherData.P_MASK]
	thunder_mask = o.thunder_mask
	flash_k = o.flash_k
	var tka := ra[WeatherData.F_TRACK_SNOW_K] if o.snow_ground and not is_nan(ra[WeatherData.F_TRACK_SNOW_K]) else ra[WeatherData.F_TRACK_K]
	var tkb := rb[WeatherData.F_TRACK_SNOW_K] if o.snow_ground and not is_nan(rb[WeatherData.F_TRACK_SNOW_K]) else rb[WeatherData.F_TRACK_K]
	track_k = lerpf(tka, tkb, k)
	track_abs = fa[WeatherData.F_TRACK_ABS]
	scent_k = lerpf(ra[WeatherData.F_SCENT_K], rb[WeatherData.F_SCENT_K], k)
	calm = o.calm
	fire_out_s = fa[WeatherData.F_FIRE_OUT_S]
	var fka := 1.0 if ra[WeatherData.F_FIRE_OUT_S] > 0.0 else ra[WeatherData.F_FIRE_K]
	var fkb := 1.0 if rb[WeatherData.F_FIRE_OUT_S] > 0.0 else rb[WeatherData.F_FIRE_K]
	fire_k = 1.0 if fire_out_s > 0.0 else lerpf(fka, fkb, k)
	fire_ring = lerpf(ra[WeatherData.F_FIRE_RING], rb[WeatherData.F_FIRE_RING], k)
	douse = lerpf(ra[WeatherData.F_DOUSE], rb[WeatherData.F_DOUSE], k)
	dry_k = lerpf(ra[WeatherData.F_DRY_K], rb[WeatherData.F_DRY_K], k)
	wet_ground = wet.ground
	wet_felt = wet.felt
	mud = wet.mud
	puddle = wet.puddle()
	snow_fresh = wet.snow
	wet_bow = wet.bow
	cart_k = (1.0 - 0.25 * wet.mud) * (1.0 - 0.15 * wet.snow) * lerpf(ra[WeatherData.F_CART_K], rb[WeatherData.F_CART_K], k)
	rough_k = (1.0 + 0.4 * wet.mud) * (1.3 if WeatherData.group[t] == WeatherData.GROUP_STORM else 1.0)
	cart_lock = WeatherData.cart_lock[dom] == 1
	var pk := o.pack
	snowpack = pk.snowpack if pk else 0.0
	deep_snow = pk.deep if pk else false
	crust = pk.crust > 0 if pk else false
	gale_damage = wind >= 16.0 or wind + gust > 20.0
	hail = o.hail if type == &"hail" else {}
	strike_risk = o.strike_risk
	moon_seen = o.night and o.moon_up and cloud < 0.6 and not WeatherData.wet[t] and type != &"fog"
	blizzard = type == &"blizzard" or type == &"kara_boran"
	fatigue_k = lerpf(ra[WeatherData.F_FATIGUE_K], rb[WeatherData.F_FATIGUE_K], k) * (1.0 + 0.3 * wet.mud)
	cone_k = lerpf(ra[WeatherData.F_CONE_K], rb[WeatherData.F_CONE_K], k)
	snow_felt = 1.0 if not o.accumulate else (0.2 if wet.snow > 0.5 else o.snow_felt)
	pin = o.pin
	# pinFx (§6.1): kalibre sahnenin sayıları; okuyan kendi sayısını korur.
	if not pin.is_empty():
		if pin.get("mask") is float or pin.get("mask") is int:
			mask = float(pin["mask"])
		if pin.get("track_k") is float or pin.get("track_k") is int:
			track_k = float(pin["track_k"])
		if pin.has("track_abs"):
			track_abs = float(pin["track_abs"]) if pin["track_abs"] != null else NAN
		if pin.get("douse") is float or pin.get("douse") is int:
			douse = float(pin["douse"])
		if pin.get("felt") is float or pin.get("felt") is int:
			wet_felt = float(pin["felt"])
		if pin.get("snow_felt") is float or pin.get("snow_felt") is int:
			snow_felt = float(pin["snow_felt"])
		if pin.get("fire_out_s") is float or pin.get("fire_out_s") is int:
			fire_out_s = float(pin["fire_out_s"])
		if pin.get("fog_stealth") is bool and not bool(pin["fog_stealth"]):
			fog_k = INF
	hear_k = 1.0 / (1.0 + mask + thunder_mask)
	return self


# --- Karışım (saf) ----------------------------------------------------------------------------------------------------

## İki tür vektörünün karışımı (§5.8), ayırmasız: out yerinde (P_COUNT boyunda). vis tersiyle (sönüm katsayısı) karışır; mutlak sis uzağı
## yalnız iki uçta da varsa karışır, tekinde varsa baskın uçtan.
static func blend(pa: PackedFloat64Array, pb: PackedFloat64Array, k: float, out: PackedFloat64Array) -> PackedFloat64Array:
	if out.size() != WeatherData.P_COUNT:
		out.resize(WeatherData.P_COUNT)
	for i in WeatherData.P_FOG_FAR_ABS:
		if i == WeatherData.P_VIS:
			continue
		out[i] = pa[i] + (pb[i] - pa[i]) * k
	var fa := pa[WeatherData.P_FOG_FAR_ABS]
	var fb := pb[WeatherData.P_FOG_FAR_ABS]
	out[WeatherData.P_FOG_FAR_ABS] = fa + (fb - fa) * k if fa > 0.0 and fb > 0.0 else (fb if k >= 0.5 else fa)
	var ia := 1.0 / pa[WeatherData.P_VIS]
	var ib := 1.0 / pb[WeatherData.P_VIS]
	var iv := ia + (ib - ia) * k
	out[WeatherData.P_VIS] = 1.0 / iv if iv > 0.0 else INF
	var has_a := pa[WeatherData.P_HAS_TINT] > 0.5
	var has_b := pb[WeatherData.P_HAS_TINT] > 0.5
	for c in 3:
		out[WeatherData.P_TONE_R + c] = pa[WeatherData.P_TONE_R + c] + (pb[WeatherData.P_TONE_R + c] - pa[WeatherData.P_TONE_R + c]) * k
		var ta := pa[WeatherData.P_TINT_R + c] if has_a else pb[WeatherData.P_TINT_R + c]
		var tb := pb[WeatherData.P_TINT_R + c] if has_b else pa[WeatherData.P_TINT_R + c]
		out[WeatherData.P_TINT_R + c] = ta + (tb - ta) * k if (has_a or has_b) else 1.0
	out[WeatherData.P_HAS_TINT] = 1.0 if (has_a or has_b) else 0.0
	return out


## Kilidin bir alanı (§6.1): keys k'ye göre doğrusal (alanı taşıyan iki anahtar arası), yoksa params. Döner: NAN yoksa.
static func lock_value(l: WeatherPlanner.Lock, key: String) -> float:
	if not l.keys.is_empty():
		var lo: Dictionary = {}
		var hi: Dictionary = {}
		for kk: Variant in l.keys:
			if not kk is Dictionary:
				continue
			var params: Variant = (kk as Dictionary).get("params")
			if not params is Dictionary or not (params as Dictionary).has(key):
				continue
			if float(kk.get("k", 0.0)) <= l.k:
				lo = kk
			elif hi.is_empty():
				hi = kk
		if not lo.is_empty() and not hi.is_empty():
			var lk := float(lo.get("k", 0.0))
			var hk := float(hi.get("k", 0.0))
			var lv := float(lo["params"][key])
			var hv := float(hi["params"][key])
			return lv + (hv - lv) * ((l.k - lk) / maxf(1e-9, hk - lk))
		if not lo.is_empty():
			return float(lo["params"][key])
		if not hi.is_empty():
			return float(hi["params"][key])
	var v: Variant = l.params.get(key)
	return float(v) if (v is float or v is int) else NAN


## Kilidin vektör alanlarını üstüne yazar.
static func apply_lock(l: WeatherPlanner.Lock, out: PackedFloat64Array) -> PackedFloat64Array:
	for i in WeatherData.PARAM_KEYS.size():
		var v := lock_value(l, WeatherData.PARAM_KEYS[i])
		if not is_nan(v):
			out[i] = v
	return out


## Çizim sisi (§3.4): taban × fog_far_k; Tipi ve Kara Boran mutlak 140 m (act1.md §10).
static func fog_far_of(base: float, p: PackedFloat64Array) -> float:
	return p[WeatherData.P_FOG_FAR_ABS] if p[WeatherData.P_FOG_FAR_ABS] > 0.0 else base * p[WeatherData.P_FOG_FAR_K]


# --- Okuyanların yardımcıları (saf; §8.2–§8.4, §3.5) -------------------------------------------------------------

static func hear_k_of(p_mask: float, thunder: float = 0.0) -> float:
	return 1.0 / (1.0 + p_mask + thunder)


## Algı hızının sis çarpanı: görüş ≥100 m'de 1, altında clamp(1 − 2d / vis; 0,25; 1).
static func fog_factor(p_vis: float, d: float) -> float:
	return 1.0 if p_vis >= 100.0 else clampf(1.0 - (2.0 * d) / p_vis, 0.25, 1.0)


## Gök gürültüsü maskesi: sesin gelişinden t sn sonra 3·e^(−t/1,2).
static func thunder_mask_at(t: float) -> float:
	return 3.0 * exp(-t / 1.2) if t >= 0.0 else 0.0


static func sense_k(p_vis: float) -> float:
	return clampf(p_vis / 120.0, 0.4, 1.0)


## Koku yön çarpanı (§8.4): rüzgâr ≥1 m/sn: rüzgâr üstü 2, altı 0,5; ≥12 m/sn 2,5 / 0,4; durgunda 1.
static func scent_dir_k(p_wind: float, upwind: bool) -> float:
	if p_wind < 1.0:
		return 1.0
	if p_wind >= 12.0:
		return 2.5 if upwind else 0.4
	return 2.0 if upwind else 0.5


## Sıçramanın ıslak çarpanı (§8.6): keçe, saz, kolan min(1 − 0,8 × keçe, kar); ahşap 1 − 0,4 × keçe; taş, metal 1.
static func spread_wet(mat: String, p_felt: float, p_snow_felt: float = 1.0) -> float:
	if mat == "felt" or mat == "reed" or mat == "bands":
		return minf(1.0 - 0.8 * p_felt, p_snow_felt)
	if mat == "wood" or mat == "lattice":
		return 1.0 - 0.4 * p_felt
	return 1.0


## Taban rüzgâr döngüsünün çarpanı (§3.5).
static func wind_gain(w: float) -> float:
	return clampf(0.45 + w / 8.0, 0.4, 1.6)


## Rüzgârın bükme çarpanı (§9.9): 3 m/sn'de 1, 9'da 1,73, 16'da 2,31.
static func wind_k(w: float) -> float:
	return sqrt(maxf(w, 0.3) / 3.0)


## Rüzgârın geldiği derece (kuzey 0, saat yönünde) → birim akış vektörü (x doğu, z güney).
static func flow_of(from_deg: float) -> Vector2:
	var b := deg_to_rad(from_deg + 180.0)
	return Vector2(sin(b), -cos(b))
