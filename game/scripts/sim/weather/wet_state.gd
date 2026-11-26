class_name WetState
extends RefCounted
## Islaklık, çamur ve taze kar (saf; weather.md §5.9, H10, W8): zemin, keçe, çamur, birikinti, taze kar ve kiriş. Oyun saatiyle tümleşir;
## kapalı biçim: x(t) = x∞ + (x0 − x∞)·e^(−kt). Artı oran 1'e, eksi 0'a doğru gider; gece kurutan her oran ×0,12/0,35. Adım adım
## ile tek atlama aynı sonucu verir (uyku ve atlama analitik çözülür). Prototipin weather-core.js WetState'inden birebir.
##   var wet := WetState.new(true)
##   wet.step(dt_h, params, night)        # params: WeatherData.params_of(...) ya da karışmış vektör
##   wet.puddle()

const NIGHT_DRY := 0.12 / 0.35
## Çamurun zemini izleme hızı (sa⁻¹).
const MUD_K := 0.5

## Kar tutar mı (kampta yalnız kış; K67).
var accumulate := true
var ground := 0.0
var felt := 0.0
var mud := 0.0
var snow := 0.0
var bow := 0.0


func _init(p_accumulate: bool = true) -> void:
	accumulate = p_accumulate


func puddle() -> float:
	return maxf(0.0, ground - 0.6) / 0.4


static func rate_of(r: float, night: bool) -> float:
	if r > 0.0:
		return r
	if r < 0.0:
		return -r * (NIGHT_DRY if night else 1.0)
	return 0.0


## dt_h oyun saati. acc: −1 kendi ayarı, 0 tutmaz, 1 tutar. summer: yazın taze kar −1 sa⁻¹ erir.
func step(dt_h: float, p: PackedFloat64Array, night: bool = false, summer: bool = false, acc: int = -1) -> WetState:
	if not (dt_h > 0.0):
		return self
	var holds := accumulate if acc < 0 else acc == 1
	var rg := p[WeatherData.P_WET_GROUND]
	var rf := p[WeatherData.P_WET_FELT]
	var snow_rate := p[WeatherData.P_SNOW_RATE]
	# Kar tutmayan yerde serpinti zemini ve keçeyi ıslatır (zemin +0,2, keçe +0,3 sa⁻¹), örtü bırakmaz (§5.9).
	if not holds and snow_rate > 0.0:
		var m := minf(1.0, snow_rate / 0.5)
		rg += 0.2 * m
		rf += 0.3 * m
	var kg := rate_of(rg, night)
	var tg := 1.0 if rg > 0.0 else 0.0
	var g0 := ground
	var eg := exp(-kg * dt_h)
	ground = clampf(tg + (g0 - tg) * eg if kg > 0.0 else g0, 0.0, 1.0)
	var kf := rate_of(rf, night)
	var tf := 1.0 if rf > 0.0 else 0.0
	felt = clampf(tf + (felt - tf) * exp(-kf * dt_h) if kf > 0.0 else felt, 0.0, 1.0)
	# Çamur zemini gecikmeli izler: dm/dt = 0,5 (g − m), g üstel.
	var c := MUD_K
	var m0 := mud
	var m: float
	if not (kg > 0.0):
		m = g0 + (m0 - g0) * exp(-c * dt_h)
	else:
		var dd := g0 - tg
		if absf(kg - c) < 1e-9:
			m = tg + (m0 - tg) * exp(-c * dt_h) + c * dd * dt_h * exp(-c * dt_h)
		else:
			var a := (c * dd) / (c - kg)
			m = tg + a * eg + (m0 - tg - a) * exp(-c * dt_h)
	mud = clampf(m, 0.0, 1.0)
	# Taze kar: yağarken türün hızıyla 1'e; dinince −0,25 sa⁻¹, yazın −1, yağmurda ×2.
	if holds and snow_rate > 0.0:
		snow = 1.0 + (snow - 1.0) * exp(-snow_rate * dt_h)
	elif snow > 0.0:
		snow *= exp(-(1.0 if summer else 0.25) * (2.0 if p[WeatherData.P_RAIN] > 0.1 else 1.0) * dt_h)
	snow = clampf(snow, 0.0, 1.0)
	return self


## Atlama: analitik; kısa adımlarla tümlemenin aynısı.
func skip(hours: float, p: PackedFloat64Array, night: bool = false, summer: bool = false, acc: int = -1) -> WetState:
	return step(hours, p, night, summer, acc)


## Kiriş ıslaklığı gerçek saniyeyle (§8.8): yay taşınırken ıslanır (gorytos ×0,5); ateşin 4 m'sinde, barınakta ya da kuru havada kurur.
func step_bow(dt_s: float, rate: float, carried: bool, gorytos: bool = false, sheltered: bool = false, near_fire: bool = false) -> float:
	if not (dt_s > 0.0):
		return bow
	if carried and rate > 0.0 and not sheltered and not near_fire:
		bow = clampf(bow + rate * (0.5 if gorytos else 1.0) * dt_s, 0.0, 1.0)
	elif bow > 0.0:
		var dry := 1.0 / 20.0 if near_fire else 1.0 / 90.0 if sheltered else 0.0 if rate > 0.0 else 1.0 / 240.0
		bow = clampf(bow - dry * dt_s, 0.0, 1.0)
	return bow


## Kayıt (weather.md §12.7): [ground, felt, mud, puddle, snow, bow], üç basamak.
func to_array() -> Array:
	return [_r3(ground), _r3(felt), _r3(mud), _r3(puddle()), _r3(snow), _r3(bow)]


func from_array(a: Variant) -> WetState:
	var arr: Array = a if a is Array else []
	ground = _num01(arr, 0)
	felt = _num01(arr, 1)
	mud = _num01(arr, 2)
	snow = _num01(arr, 4)
	bow = _num01(arr, 5)
	return self


func reset() -> void:
	ground = 0.0
	felt = 0.0
	mud = 0.0
	snow = 0.0
	bow = 0.0


static func _r3(x: float) -> float:
	return WeatherRng.js_round(x * 1000.0) / 1000.0


static func _num01(arr: Array, i: int) -> float:
	if i >= arr.size() or not (arr[i] is float or arr[i] is int):
		return 0.0
	return clampf(float(arr[i]), 0.0, 1.0)
