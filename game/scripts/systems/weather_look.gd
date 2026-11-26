class_name WeatherLook
extends RefCounted
## Havanın görünüş hesabı (saf; weather.md §3.4, §9.2, §9.6, §9.8, §9.9; godot.md §4.9): karışmış parametre vektörü ve fx'ten SkyRig'in
## hava girdisi (ışık, ortam, pozlama, gölge, sis, gök katmanı, şimşek; ışığın tek yazıcısı SkyRig'dir), zemin ve rüzgâr genel
## tekdüzenleri ve ekran yağışının yönü. Görünümün kimlikle karışımı k'dır (0 kimlik: menü karesi; 1 tam hava): her çarpan 1'e, her
## katman 0'a k ile süzülür. WeatherView her kare okur; sınama sahnesiz koşar.

## Kampın taban sis uzağı (m; weather.md §3.4 «Neden bu sayılar»): türün sis çarpanı buna uygulanır.
const BASE_FOG_FAR := 1400.0
## Sis uzağının kamera tabanı: kamera uzaklığı + 50 m (§3.4).
const CAMERA_FOG_PAD := 50.0
## Şimşeğin ışık payı (§9.6: yere ≤2 km A 1,6, B 3; SkyRig flash_energy).
const FLASH_ENERGY := 3.0
## Gölge bu güneş çarpanının altında kapanır (kapalı gök, tipi: «gölge yok denecek kadar»).
const SHADOW_OFF_SUN_K := 0.35
## Kar örtüsünün görünüşü: örtü (snowpack) bu değerde zemini tam örter; taze kar payı.
const COVER_FULL := 0.18
const FRESH_COVER := 0.75


## Sisin yoğunluğu (üstel sis; Godot'nun Environment.fog_density): türün sis uzağında (§3.4: kampın 1400 m'lik tabanı × fog_far_k,
## Tipi ve Kara Boran mutlak 140 m; kamera tabanı kamera uzaklığı + 50 m) sis %95'tir (yoğunluk 3 / uzak). Örneğin kendi yoğunluğundan
## türün yoğunluğuna, uzağın kısalma payıyla (1 − fog_far_k; mutlak uzakta 1) geçilir: açık ve bulutlu havada örneğin sisi aynen kalır.
static func fog_density(base: float, p: PackedFloat64Array, cam_dist: float) -> float:
	var far := maxf(WeatherFx.fog_far_of(BASE_FOG_FAR, p), cam_dist + CAMERA_FOG_PAD)
	var t := 1.0 if p[WeatherData.P_FOG_FAR_ABS] > 0.0 else clampf(1.0 - p[WeatherData.P_FOG_FAR_K], 0.0, 1.0)
	return maxf(base, lerpf(base, 3.0 / maxf(far, 1.0), t))


## SkyRig.set_weather'ın sözlüğü (bkz. SkyRig «HAVA GİRDİSİ»). cam_dist: kameranın odağa uzaklığı (sis tabanı); flash 0..1; light_k kara
## sağanağın ışık çarpanı; flash_dir oyuncudan (x, z); base_fog saatin örneğinin sis yoğunluğu.
static func sky_rig_params(p: PackedFloat64Array, k: float, flash: float, light_k: float, cam_dist: float, flash_dir: Vector2,
		base_fog: float = 0.00045) -> Dictionary:
	var kk := clampf(k, 0.0, 1.0)
	var sun_k := lerpf(1.0, p[WeatherData.P_SUN_K] * light_k, kk)
	var base := maxf(base_fog, 1e-6)
	var far := maxf(WeatherFx.fog_far_of(BASE_FOG_FAR, p), cam_dist + CAMERA_FOG_PAD)
	var fog_mul := lerpf(1.0, fog_density(base, p, cam_dist) / base, kk)
	var out := {
		"light_mul": sun_k,
		"ambient_mul": lerpf(1.0, p[WeatherData.P_HEMI_K] * lerpf(1.0, light_k, 0.5), kk),
		"exposure_mul": lerpf(1.0, p[WeatherData.P_EXP_K], kk),
		"fog_density_mul": fog_mul,
		"volumetric_mul": lerpf(1.0, clampf(sqrt(BASE_FOG_FAR / maxf(far, 1.0)), 1.0, 4.0), kk),
		"flash": clampf(flash * kk, 0.0, 1.0),
		"flash_energy": FLASH_ENERGY,
		"sky": {
			"weather_cover": p[WeatherData.P_COVER_SKY] * kk,
			"weather_dark": p[WeatherData.P_DARK] * kk,
			"weather_flash": clampf(flash * kk, 0.0, 1.0),
			"weather_flash_dir": Vector3(flash_dir.x, 0.25, flash_dir.y).normalized() if flash_dir != Vector2.ZERO else Vector3(0.0, 0.25, -1.0),
			"weather_dust": p[WeatherData.P_DUST] * kk,
		},
		"sky_mul": {
			"star_brightness": lerpf(1.0, 1.0 - p[WeatherData.P_CLOUD] * 0.95, kk),
			"moon_energy": lerpf(1.0, 1.0 - p[WeatherData.P_CLOUD] * 0.8, kk),
			"sun_glow_strength": lerpf(1.0, 1.0 - p[WeatherData.P_CLOUD] * 0.85, kk),
		},
	}
	if p[WeatherData.P_HAS_TINT] > 0.5 and p[WeatherData.P_FOG_MIX] > 0.0:
		out["fog_color"] = Color(p[WeatherData.P_TINT_R], p[WeatherData.P_TINT_G], p[WeatherData.P_TINT_B])
		out["fog_color_mix"] = p[WeatherData.P_FOG_MIX] * kk
	if kk > 0.5 and sun_k < SHADOW_OFF_SUN_K:
		out["shadow"] = false
	return out


## Derece (weather.md §3.4 «Doygunluk ×, karşıtlık ×, ton»): {sat, con, tone (Color)}; kimlikte 1, 1, beyaz.
static func grade(p: PackedFloat64Array, k: float) -> Dictionary:
	var kk := clampf(k, 0.0, 1.0)
	return {
		"sat": lerpf(1.0, p[WeatherData.P_SAT], kk),
		"con": lerpf(1.0, p[WeatherData.P_CON], kk),
		"tone": Color(lerpf(1.0, p[WeatherData.P_TONE_R], kk), lerpf(1.0, p[WeatherData.P_TONE_G], kk), lerpf(1.0, p[WeatherData.P_TONE_B], kk)),
	}


static func grade_is_identity(g: Dictionary) -> bool:
	var t: Color = g["tone"]
	return absf(float(g["sat"]) - 1.0) < 1e-4 and absf(float(g["con"]) - 1.0) < 1e-4 and absf(t.r - 1.0) < 1e-4 and absf(t.g - 1.0) < 1e-4 \
		and absf(t.b - 1.0) < 1e-4


## Zemin genel tekdüzeni weather_ground (§9.8; shaders/include/weather_ground.gdshaderinc): x zemin ıslaklığı, y kar örtüsü (taze kar ve
## SnowPack; kar tutmayan mevsimde 0), z birikinti, w dolu beyazlığı.
static func ground(fx: WeatherFx, k: float, accumulate: bool) -> Vector4:
	var kk := clampf(k, 0.0, 1.0)
	var cover := 0.0
	if accumulate:
		cover = clampf(maxf(fx.snowpack / COVER_FULL, fx.snow_fresh * FRESH_COVER), 0.0, 1.0)
	return Vector4(fx.wet_ground, cover, fx.puddle, fx.hail_white) * kk


## Rüzgâr genel tekdüzeni weather_wind (§9.9): xy akış yönü (birim), z bükülme çarpanı windK = sqrt(max(rüzgâr, 0,3) / 3) (3 m/sn'de 1,
## 16'da 2,31), w bora payı. Kimlikte (k 0) z 0'dır: çim kendi tekdüzenini kullanır (menü karesi değişmez).
static func wind(fx: WeatherFx, k: float) -> Vector4:
	var kk := clampf(k, 0.0, 1.0)
	if kk <= 0.0:
		return Vector4.ZERO
	var wk := WeatherFx.wind_k(fx.wind + 0.5 * fx.gust)
	return Vector4(fx.dir_x, fx.dir_z, lerpf(1.0, wk, kk), clampf(fx.gust / maxf(fx.wind, 0.5), 0.0, 1.0) * kk)


## Yağışın 3B düşüş vektörü (m/sn; weather.md §9.4): kar 1,2 + rüzgâr × 0,6; yoğun kar ve tipi 1,6, tipide yatay 14; dolu 14; sulu kar
## 4; toz yatay rüzgâr × 1. Döner: [kar, dolu, toz] düşüşleri.
static func falls(p: PackedFloat64Array, fx: WeatherFx) -> Array[Vector3]:
	var w := Vector2(fx.dir_x, fx.dir_z) * (fx.wind + fx.gust)
	var snow := p[WeatherData.P_SNOW]
	var rain := p[WeatherData.P_RAIN]
	var wet := rain / maxf(rain + snow, 1e-6) if snow > 0.0 else 0.0
	var down := lerpf(1.2, 1.6, clampf((snow - 0.5) / 0.5, 0.0, 1.0))
	down = lerpf(down, 4.0, wet)
	var side := 1.17 if fx.blizzard else 0.6
	var snow_fall := Vector3(w.x * side, -down, w.y * side)
	var hail_fall := Vector3(w.x * 0.3, -14.0, w.y * 0.3)
	var dust_fall := Vector3(w.x, -0.3, w.y)
	return [snow_fall, hail_fall, dust_fall]


## Ekran yağışının katman hızları (UV/sn; §9.3): yağmur 2,4 / 1,6 / 1; kar 0,12 / 0,08 / 0,05; dolu 3; toz yatay 1,2. Karışık yağışta
## yoğunluğun ağırlıklı ortalaması.
static func layer_speeds(precip: Vector4) -> Vector3:
	var r := Vector3(2.4, 1.6, 1.0)
	var s := Vector3(0.12, 0.08, 0.05)
	var h := Vector3(3.0, 2.2, 1.5)
	var d := Vector3(1.2, 0.8, 0.5)
	var tot := precip.x + precip.y + precip.z + precip.w
	if tot <= 0.0:
		return r
	return (r * precip.x + s * precip.y + h * precip.z + d * precip.w) / tot


## Ekran yağışının rengi (§9.3 uPrecipCol: ışık düzeninden): yağmur gri-mavi çizgi, kar ve dolu açık (sahne kararsa da arka plandan açık
## kalır), toz okr; türlerin payıyla karışır. lit ışık düzeninin rengi (ortam + güneş payı); Kara Boran'da kar griye iner.
static func precip_color(precip: Vector4, lit: Color, dark_snow: bool = false) -> Color:
	var lum := lit.r * 0.3 + lit.g * 0.59 + lit.b * 0.11
	# Yağmur çizgisi göğün gri-mavisini taşır: koyu çimende açık, açık keçede koyu okunur (taban 0,55).
	var rain := Color(0.74, 0.8, 0.88) * clampf(lum * 1.6, 0.55, 1.0)
	var snow := Color(0.93, 0.95, 1.0) * clampf(lum * 1.6, 0.55, 1.0) * (0.78 if dark_snow else 1.0)
	var hail := Color(1.0, 1.0, 1.0) * clampf(lum * 1.6, 0.6, 1.0)
	var dust := Color(0.78, 0.62, 0.42) * clampf(lum * 1.4, 0.4, 1.0)
	var tot := precip.x + precip.y + precip.z + precip.w
	if tot <= 0.0:
		return rain
	var c := (rain * precip.x + snow * precip.y + hail * precip.z + dust * precip.w) / tot
	return Color(c.r, c.g, c.b, 1.0)
