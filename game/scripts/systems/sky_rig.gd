class_name SkyRig
extends Node
## Işığın tek yazıcısı (godot.md §1 madde 9, §4.9; time.md §5; K20, K58, K67, K76): DirectionalLight3D'yi, WorldEnvironment'ı (ortam,
## sis, pozlama, renk ayarı LUT'u) ve gök gölgelendiricisinin (shaders/sky.gdshader) tekdüzenlerini bir ÖRNEKTEN yazar; kampta suyun
## renklerini ve parıltısını, ateşin, köyün ve ateş böceklerinin payını da (props). Başka hiçbir düğüm bunlara ışık için dokunmaz.
##
## Üç besleme vardır:
##   - Saat (ROAM, PLAY): GameClock 4 Hz örnek üretir (LightStops.sample), feed_clock(sample) ile verir.
##   - Sabit örnek (sinema, godot.md §3.6): set_fixed_sample(sample). Sabitken saat beslemesi yok sayılır (son saat örneği saklanır);
##     clear_fixed_sample() sabiti bırakır, saklanan saat örneği varsa hemen uygulanır. Önsöz'ün doğumu yalnız bunu kullanır
##     (data/cine/birth_light.json: içeride 05:50, dışarıda 06:03), Çocukluk ve Yola Çıkış da kendi dünyalarında.
##   - Hava (weather.md; K22): set_weather(params) saatin örneğinin üstüne çarpanlar ve ezmeler koyar (aşağıda «HAVA GİRDİSİ»).
##
## KİMLİK (menü karesi; K20, K76; time.md §5.5). Kampın dünyası menünün dünyasıdır: menü, Yeni Oyun ve Önsöz gece ışığında kalır, saati
## okumaz. Serbest Gez başlarken take_over() menünün yazdığı her değeri (ışık, ortam, sis, renk ayarı, gök ve su tekdüzenleri, props)
## saklar ve saat beslemesine açılır; fade_from_identity(2,4) açılışın süzülmesidir (sineInOut; yön küresel aradeğerle; yön farkı 30°'yi
## aşarsa ortada ışık katsayısı 0,4'e iner). release(1,7) uçuş boyunca kimliğe süzülür, sonunda saklanan değerleri bit bit geri yazar ve
## bırakır: menü karesi değişmez. Kimliği olmayan dünyada (Çocukluk, Yola Çıkış, sınama) bunlar çağrılmaz; yol bugünküyle aynıdır.
##
## ÖRNEK (Dictionary; JSON'da yönler [x, y, z], renkler [r, g, b] ya da "#rrggbb"):
##   sun_dir, moon_dir      kaynağa doğru birim yön. Yazılmazsa enlem, gün ve dakikadan Daylight hesaplar:
##                          lat, doy (ya da dec), minute, moon_age (ay yaşı, gün).
##   light_dir              ışığın geldiği yön; yazılmazsa güneşin azimutunda, yüksekliği en az 15° (Daylight.light_dir).
##   light_color, light_energy, light_shadow (bool)
##   ambient_color, ambient_energy, ambient_sky (gökten gelen pay, 0..1), exposure, sky_energy, saturation, contrast (renk ayarı)
##   sky {zenith, mid, horizon, ground, sun_glow_color, sun_glow_strength, star_brightness, ...}: gök tekdüzenleri;
##                          kısa adlar *_color'a gider, öteki anahtarlar tekdüzenin kendi adıdır. Doku tekdüzenine
##                          (ambient_panorama) dosya yolu yazılır; preloaded'daki kaynak önbellekten gelir.
##   fog {color, density, sky_affect, aerial_perspective, height, height_density}
##   volumetric {density, albedo}: hacimli sis (Environment.volumetric_fog_*)
##   water {deep_color, shallow_color, reflection_horizon, reflection_zenith, glint_color, glint_energy}: glint_paths'in malzemeleri
##   glint                  su parıltısının yönü: "sun" ya da "moon" (yazılmazsa güneş ufkun 2° altından yukarıdaysa güneş).
##   grade_night            gece renk ayarının payı (0..1; ColorGrade.world_night, öteki pay ColorGrade.world): durak geçişi LUT
##                          karışımıdır (godot.md §4.9). grade_autumn güz tonunun gündüz payına karışımıdır (Serbest Gez'in güzü).
##                          Yalnız kimlik alınmış dünyada yazılır (kimliğin LUT'u yoksa, ör. --no-grade, hiç yazılmaz).
##   props {anahtar: pay}   take_over(props)'un düğüm özelliklerine kimliğin değeri × pay yazılır (kampta fire, village, motes).
## Gök diski ve ışıltısı güneşin kırılmayla görünen yönündedir (Daylight.apparent_dir); ışık ve parıltı geometrik yöndedir.
##
## HAVA GİRDİSİ (set_weather; hava ajanının çarpanı, yalnız saatin örneğine): {
##   light_mul      güneş ya da ay ışığının gücü × (bulut, yağış; 1)
##   ambient_mul    ortamın gücü × (1)
##   exposure_mul   pozlama × (1)
##   shadow         false: gölge kapalı (kapalı gök, tipi); yazılmazsa örneğinki
##   fog_density_mul, fog_color (Color), fog_color_mix (0..1): sis
##   volumetric_mul hacimli sisin yoğunluğu × (1)
##   sky {tekdüzen: değer}     gök tekdüzenlerini ezer (ör. cloud_coverage, cloud_opacity)
##   sky_mul {tekdüzen: k}     sayı tekdüzenlerini çarpar (ör. star_brightness, moon_energy, sun_glow_strength)
##   flash, flash_color, flash_energy   şimşek (0..1): ışık ve ortam bu an kadar parlar (flash_energy, varsayılan 3)
## } Değer verilmeyen alan etkisizdir; clear_weather() kimliğe (etkisiz) döner. Şimşek her kare yazılabilir: yazım ayırmasız ve ucuzdur.
##
##   var samples := SkyRig.load_samples("res://data/cine/birth_light.json")
##   rig.set_fixed_sample(samples["inside"])
##   rig.take_over({"fire": {"node": campfire, "property": "light_energy"}})   # Serbest Gez (RoamTime kurar)
##   rig.feed_clock(LightStops.sample(table, "camp", 1171, 886.18))
##   rig.fade_from_identity(2.4)
##   await rig.release(1.7)                                                    # menüye dönüş: kimlik bit bit

signal sample_applied(sample: Dictionary)
## Kimlik geri yazıldı (release bitti).
signal released

## Gök tekdüzenlerinin kısa adları.
const SKY_ALIASES := {"zenith": "zenith_color", "mid": "mid_color", "horizon": "horizon_color", "ground": "ground_color"}
## Ortam ve sis anahtarları → Environment özellikleri.
const ENV_KEYS := {
	"ambient_color": "ambient_light_color", "ambient_energy": "ambient_light_energy",
	"ambient_sky": "ambient_light_sky_contribution", "exposure": "tonemap_exposure",
	"sky_energy": "background_energy_multiplier", "saturation": "adjustment_saturation", "contrast": "adjustment_contrast",
}
const FOG_KEYS := {
	"color": "fog_light_color", "density": "fog_density", "sky_affect": "fog_sky_affect",
	"aerial_perspective": "fog_aerial_perspective", "height": "fog_height", "height_density": "fog_height_density",
}
const VOLUMETRIC_KEYS := {"density": "volumetric_fog_density", "albedo": "volumetric_fog_albedo"}
## Su parıltısının güneşe geçtiği en düşük güneş yüksekliği (derece).
const GLINT_SUN_EL := -2.0
## Kimliğin sakladığı Environment özellikleri (yazılan her şey).
const ENV_SNAPSHOT: Array[String] = [
	"ambient_light_color", "ambient_light_energy", "ambient_light_sky_contribution", "tonemap_exposure", "background_energy_multiplier",
	"fog_light_color", "fog_density", "fog_sky_affect", "fog_aerial_perspective", "fog_height", "fog_height_density",
	"volumetric_fog_density", "volumetric_fog_albedo", "adjustment_enabled", "adjustment_color_correction", "adjustment_saturation",
	"adjustment_contrast",
]
## Açılış süzülmesinin varsayılanları (K76, time.md §5.5): yön farkı bu açıyı aşarsa ortada ışık katsayısı bu değere iner.
const FADE_DIP_ANGLE := 30.0
const FADE_DIP_K := 0.4
## LUT'un boyu (ColorGrade.size ile aynı) ve karışımın yeniden yazıldığı en küçük pay farkı.
const LUT_SIZE := 32
const LUT_STEP := 1.0 / 255.0

## Güneş ya da ay ışığı.
@export var light_path: NodePath = ^"../SunLight"
@export var environment_path: NodePath = ^"../WorldEnvironment"
## Güneş ya da ay parıltısını yansıtan su yüzeyleri (water.gdshader'ın moon_direction'ı parıltının yönüdür; water örneğinin renkleri de).
@export var glint_paths: Array[NodePath] = []
## Açılışta (sabit olmadan) uygulanan örnek: dosya ve kimlik. Dosya boşsa dokunulmaz.
@export_file("*.json") var initial_samples := ""
@export var initial_sample := ""
## Örneklerin dosya yoluyla andığı kaynaklar (panoramalar): sahneyle birlikte (arka planda) yüklenir, örnek
## uygulanırken diske gidilmez.
@export var preloaded: Array[Resource] = []

var _fixed: Dictionary = {}
var _clock: Dictionary = {}
var _current: Dictionary = {}
## Gök gölgelendiricisinin tekdüzen adları (bilinmeyen anahtar uyarılır).
var _sky_uniforms: Dictionary = {}
## Kimlik (take_over): {light, env, sky, water: [{mat, params}], props: [{node, property, value, key}], sample}; boşsa kimlik yok.
var _identity: Dictionary = {}
var _taken := false
var _weather: Dictionary = {}
## Süzülme: {from (örnek), to ("clock" ya da örnek), t, seconds, dip, release}.
var _fade: Dictionary = {}
## Karışık LUT ve son yazılan paylar.
var _lut: ImageTexture3D
var _lut_night := -1.0
var _lut_autumn := -1.0

## Ortak taban LUT görüntüleri (bir kez, iş parçacığında): gündüz (ColorGrade.world), gece (world_night), güz. Her biri iki biçimde:
## full (alfa 1) ve half (alfa 0,5; blend_rect'in kaynağı). Görüntüler RGBAF'tır, LUT dokusuna RGB8 olarak yazılır.
static var _grade_task := -1
static var _grade_images: Dictionary = {}
static var _day_lut: ImageTexture3D


func _ready() -> void:
	set_process(false)
	if initial_samples.is_empty() or initial_sample.is_empty():
		return
	var samples := load_samples(initial_samples)
	if samples.has(initial_sample):
		_apply(samples[initial_sample])
	else:
		push_warning("[sky_rig] %s içinde %s örneği yok" % [initial_samples, initial_sample])


func _exit_tree() -> void:
	# Kimlik alınmışken dünya ağaçtan çıkarsa (dünya değişimi, sahnenin silinmesi) değerler geri yazılır: kampın ortamı ve gök malzemesi
	# sahnenin alt kaynaklarıdır, aynı sahnenin sonraki örnekleri onları paylaşır.
	if _taken:
		_restore_identity()
		_taken = false
	if _grade_task >= 0:
		SkyRig.grades_ready(true)


## Yönlü ışık (yoksa null).
func sun_light() -> DirectionalLight3D:
	return get_node_or_null(light_path) as DirectionalLight3D


# --- Besleme ----------------------------------------------------------------------------------------

## Sinemanın sabit örneği: hemen yazılır, kaldırılana dek saat örnekleri yok sayılır.
func set_fixed_sample(sample: Dictionary) -> void:
	_fixed = resolve(sample)
	_apply(_fixed)


## Sabit örneği bırakır. Sabitken bir saat örneği geldiyse o hemen yazılır; gelmediyse ışık olduğu gibi kalır.
func clear_fixed_sample() -> void:
	if _fixed.is_empty():
		return
	_fixed = {}
	if not _clock.is_empty():
		_apply(_compose(_clock))


func is_fixed() -> bool:
	return not _fixed.is_empty()


## Saatin örneği (GameClock, LightStops). Sabitken yazılmaz, saklanır; süzülürken süzülmenin hedefidir. Döner: yazıldı mı?
func feed_clock(sample: Dictionary) -> bool:
	_clock = resolve(sample)
	if is_fixed():
		return false
	if is_fading():
		return true
	_apply(_compose(_clock))
	return true


## Son saat örneği (çözülmüş; yoksa boş).
func clock_sample() -> Dictionary:
	return _clock


## Son yazılan örnek (çözülmüş; yoksa boş).
func current_sample() -> Dictionary:
	return _current


## Son örneği yeniden yazar (dünyaya sonradan eklenen düğümler için: ör. kurulumu biten su yüzeyinin parıltısı).
func refresh() -> void:
	if not _current.is_empty():
		_apply(_current)


## Örneği dosyadan sabitler: data/cine/*.json ve kimlik. Döner: bulundu mu?
func fix_from(path: String, id: String) -> bool:
	var samples := load_samples(path)
	if not samples.has(id):
		push_warning("[sky_rig] %s içinde %s örneği yok" % [path, id])
		return false
	set_fixed_sample(samples[id])
	return true


# --- Hava girdisi -------------------------------------------------------------------------------------

## Havanın çarpanları ve ezmeleri (bkz. sınıf belgesi «HAVA GİRDİSİ»): saatin örneğinin üstüne yazılır, hemen uygulanır.
func set_weather(params: Dictionary) -> void:
	_weather = params.duplicate(true)
	if not is_fixed() and not is_fading() and not _clock.is_empty():
		_apply(_compose(_clock))


func clear_weather() -> void:
	set_weather({})


func weather() -> Dictionary:
	return _weather


## Örneğe havayı uygular (saf değil: _weather'ı okur). Hava yoksa örneğin kendisi.
func _compose(sample: Dictionary) -> Dictionary:
	if _weather.is_empty() or sample.is_empty():
		return sample
	return SkyRig.apply_weather(sample, _weather)


## Havanın örnek üstündeki etkisi (saf; bkz. «HAVA GİRDİSİ»).
static func apply_weather(sample: Dictionary, w: Dictionary) -> Dictionary:
	var s := sample.duplicate(true)
	var flash := clampf(float(w.get("flash", 0.0)), 0.0, 1.0)
	var flash_energy := float(w.get("flash_energy", 3.0))
	s["light_energy"] = float(s.get("light_energy", 1.0)) * float(w.get("light_mul", 1.0)) + flash * flash_energy
	s["ambient_energy"] = float(s.get("ambient_energy", 1.0)) * float(w.get("ambient_mul", 1.0)) + flash * flash_energy * 0.25
	if s.has("exposure") or w.has("exposure_mul"):
		s["exposure"] = float(s.get("exposure", 1.0)) * float(w.get("exposure_mul", 1.0))
	if flash > 0.0:
		var fc := to_color(w.get("flash_color", Color(0.86, 0.9, 1.0)))
		s["light_color"] = to_color(s.get("light_color", Color.WHITE)).lerp(fc, flash)
	if w.has("shadow"):
		s["light_shadow"] = bool(w["shadow"])
	if s.get("fog") is Dictionary and (w.has("fog_density_mul") or w.has("fog_color")):
		var fog: Dictionary = s["fog"]
		fog["density"] = float(fog.get("density", 0.0)) * float(w.get("fog_density_mul", 1.0))
		if w.has("fog_color"):
			fog["color"] = to_color(fog.get("color", Color.WHITE)).lerp(to_color(w["fog_color"]), clampf(float(w.get("fog_color_mix", 1.0)), 0.0, 1.0))
	if s.get("volumetric") is Dictionary and w.has("volumetric_mul"):
		var vol: Dictionary = s["volumetric"]
		vol["density"] = float(vol.get("density", 0.0)) * float(w["volumetric_mul"])
	if w.get("sky") is Dictionary or w.get("sky_mul") is Dictionary:
		var sky: Dictionary = s.get("sky", {})
		for key: String in w.get("sky_mul", {}):
			if sky.get(key) is float or sky.get(key) is int:
				sky[key] = float(sky[key]) * float(w["sky_mul"][key])
		for key: String in w.get("sky", {}):
			sky[key] = w["sky"][key]
		s["sky"] = sky
	return s


# --- Kimlik ve süzülme (Serbest Gez; K76) ------------------------------------------------------------

## Kimliği saklar ve saat beslemesine açılır. props: {anahtar: {node: Node, property: String|NodePath}}: örneğin props[anahtar] payı
## kimliğin değeri × pay olarak yazılır. Zaten alınmışsa yalnız props eklenir.
func take_over(props: Dictionary = {}) -> void:
	SkyRig.prepare_grades()
	if not _taken:
		_identity = _capture_identity()
		_taken = true
	for key: String in props:
		var def: Dictionary = props[key]
		var node := def.get("node") as Node
		if node == null:
			continue
		var prop := NodePath(str(def.get("property", "")))
		var list: Array = _identity.get("props", [])
		var known := false
		for row: Dictionary in list:
			if row["key"] == key and row["property"] == prop:
				known = true
		if not known:
			# Düğüm sonradan değişebilir (yakalama aracı parçacıkları yeni kopyayla değiştirir): kök ve yol da saklanır, yeniden bulunur.
			list.append({"key": key, "node": node, "property": prop, "value": node.get_indexed(prop),
				"root": def.get("root"), "path": str(def.get("path", ""))})
		_identity["props"] = list


func is_taken() -> bool:
	return _taken


## Kimliğin örnek biçimi (süzülmenin bir ucu): ışık, ortam, sis, gök, su ve props (pay 1); gece renk ayarı payı 1.
func identity_sample() -> Dictionary:
	return _identity.get("sample", {})


## Açılışın süzülmesi (K76): kimlikten saatin son örneğine seconds sn'de (sineInOut). Yön farkı dip_angle'ı aşarsa ortada ışık katsayısı
## dip_k'ye iner. Saat örneği süzülme boyunca hedeftir (feed_clock sürer).
func fade_from_identity(seconds: float, dip_angle: float = FADE_DIP_ANGLE, dip_k: float = FADE_DIP_K) -> void:
	if not _taken:
		take_over()
	_start_fade(identity_sample(), &"clock", seconds, dip_angle, dip_k, false)


## Kimliğe döner: seconds sn'de süzülür (0: hemen), sonunda kimliği bit bit geri yazar, bırakır ve released yayar. Kimlik yoksa
## hemen döner. await ile beklenebilir.
func release(seconds: float = 0.0) -> void:
	if not _taken:
		return
	if seconds <= 0.0 or _current.is_empty():
		_fade = {}
		_finish_release()
		return
	_start_fade(_current, &"identity", seconds, FADE_DIP_ANGLE, FADE_DIP_K, true)
	if is_fading():
		await released


func is_fading() -> bool:
	return not _fade.is_empty()


## Süzülmenin ilerlemesi (0..1; süzülme yoksa 1).
func fade_progress() -> float:
	return clampf(float(_fade.get("t", 1.0)), 0.0, 1.0) if is_fading() else 1.0


func _start_fade(from: Dictionary, to: Variant, seconds: float, dip_angle: float, dip_k: float, is_release: bool) -> void:
	_fade = {"from": from, "to": to, "t": 0.0, "seconds": maxf(seconds, 0.0), "dip_angle": dip_angle, "dip_k": dip_k, "release": is_release}
	if seconds <= 0.0:
		_end_fade()
		return
	set_process(true)
	_step_fade(0.0)


func _process(delta: float) -> void:
	if is_fading():
		_step_fade(delta)
	else:
		set_process(false)


func _step_fade(delta: float) -> void:
	var seconds := float(_fade["seconds"])
	_fade["t"] = minf(float(_fade["t"]) + delta / maxf(seconds, 0.000001), 1.0)
	var target := _fade_target()
	if float(_fade["t"]) >= 1.0 or target.is_empty():
		_end_fade()
		return
	var e := sine_in_out(float(_fade["t"]))
	_apply(SkyRig.blend_samples(_fade["from"], target, e, float(_fade["dip_angle"]), float(_fade["dip_k"])))


func _fade_target() -> Dictionary:
	var to: Variant = _fade.get("to")
	if to is Dictionary:
		return to
	if to == &"identity":
		return identity_sample()
	return _compose(_clock)


func _end_fade() -> void:
	var is_release := bool(_fade.get("release", false))
	var target := _fade_target()
	_fade = {}
	set_process(false)
	if is_release:
		_finish_release()
	elif not target.is_empty() and not is_fixed():
		_apply(target)


func _finish_release() -> void:
	_restore_identity()
	_taken = false
	_identity = {}
	_clock = {}
	_current = {}
	_lut_night = -1.0
	_lut_autumn = -1.0
	released.emit()


## sineInOut (0..1 → 0..1).
static func sine_in_out(t: float) -> float:
	return 0.5 - 0.5 * cos(PI * clampf(t, 0.0, 1.0))


## İki çözülmüş örneğin karışımı (saf): sayılar ve renkler doğrusal, yönler küresel aradeğerle, iç sözlükler özyinelemeli; b'de olmayan
## anahtar a'nınkidir. Işığın yön farkı dip_angle'ı aşarsa ışığın gücü ortada dip_k katına iner (1 − (1 − dip_k)·sin(πt)).
static func blend_samples(a: Dictionary, b: Dictionary, t: float, dip_angle: float = FADE_DIP_ANGLE, dip_k: float = FADE_DIP_K) -> Dictionary:
	var out := {}
	for key: String in b:
		if key in ["sun", "moon", "dec", "doy", "lat", "minute", "moon_age", "id"]:
			continue
		var y: Variant = b[key]
		var x: Variant = a.get(key, y)
		if key.ends_with("_dir") and x is Vector3 and y is Vector3:
			out[key] = Daylight.slerp_dir((x as Vector3).normalized(), (y as Vector3).normalized(), t)
		else:
			out[key] = _blend_any(x, y, t)
	for key: String in a:
		if not out.has(key) and not key in ["sun", "moon", "dec", "doy", "lat", "minute", "moon_age", "id"]:
			out[key] = a[key]
	if a.get("light_dir") is Vector3 and b.get("light_dir") is Vector3 and out.has("light_energy"):
		var angle := rad_to_deg((a["light_dir"] as Vector3).angle_to(b["light_dir"]))
		if angle > dip_angle:
			out["light_energy"] = float(out["light_energy"]) * (1.0 - (1.0 - dip_k) * sin(PI * t))
	if out.has("sun_dir"):
		out["sun"] = _sample_of(out["sun_dir"])
	if out.has("moon_dir"):
		out["moon"] = _sample_of(out["moon_dir"])
	return out


static func _blend_any(x: Variant, y: Variant, t: float) -> Variant:
	if (x is float or x is int) and (y is float or y is int) and not (x is bool or y is bool):
		return lerpf(float(x), float(y), t)
	if x is Color and y is Color:
		return (x as Color).lerp(y, t)
	if x is Vector3 and y is Vector3:
		return (x as Vector3).lerp(y, t)
	if x is Dictionary and y is Dictionary:
		var out := {}
		for k: Variant in y:
			out[k] = _blend_any((x as Dictionary).get(k, y[k]), y[k], t)
		for k: Variant in x:
			if not out.has(k):
				out[k] = x[k]
		return out
	return x if t < 0.5 else y


func _capture_identity() -> Dictionary:
	var id := {"light": {}, "env": {}, "sky": {}, "water": [], "props": []}
	var light := sun_light()
	if light:
		id["light"] = {"basis": light.basis, "light_color": light.light_color, "light_energy": light.light_energy, "shadow_enabled": light.shadow_enabled}
	var env := environment()
	if env:
		for prop in ENV_SNAPSHOT:
			id["env"][prop] = env.get(prop)
	var mat := sky_material()
	if mat and mat.shader:
		for u in mat.shader.get_shader_uniform_list():
			var name := str(u["name"])
			id["sky"][name] = mat.get_shader_parameter(name)
	for m in _glint_materials():
		var params := {}
		if m.shader:
			for u in m.shader.get_shader_uniform_list():
				var name := str(u["name"])
				if int(u.get("type", 0)) != TYPE_OBJECT:
					params[name] = m.get_shader_parameter(name)
		id["water"].append({"mat": m, "params": params})
	id["sample"] = _identity_sample_of(id)
	return id


## Kimliğin örnek biçimi: değeri yazılmamış tekdüzende gölgelendiricinin varsayılanı.
func _identity_sample_of(id: Dictionary) -> Dictionary:
	var s := {}
	var light: Dictionary = id["light"]
	if not light.is_empty():
		s["light_dir"] = (light["basis"] as Basis).z.normalized()
		s["light_color"] = light["light_color"]
		s["light_energy"] = light["light_energy"]
		s["light_shadow"] = light["shadow_enabled"]
	var env: Dictionary = id["env"]
	if not env.is_empty():
		for key: String in ENV_KEYS:
			s[key] = env[ENV_KEYS[key]]
		var fog := {}
		for key: String in FOG_KEYS:
			fog[key] = env[FOG_KEYS[key]]
		s["fog"] = fog
		s["volumetric"] = {"density": env["volumetric_fog_density"], "albedo": env["volumetric_fog_albedo"]}
		s["grade_night"] = 1.0
		s["grade_autumn"] = 0.0
	var mat := sky_material()
	var sky := {}
	var short_of := {}
	for alias: String in SKY_ALIASES:
		short_of[SKY_ALIASES[alias]] = alias
	for name: String in id["sky"]:
		var v: Variant = id["sky"][name]
		if v == null and mat and mat.shader:
			v = RenderingServer.shader_get_parameter_default(mat.shader.get_rid(), name)
		if v is Object or v == null:
			continue
		# Kısa adla (zenith, mid...) saklanır: saatin örneğiyle aynı anahtar karışsın.
		sky[short_of.get(name, name)] = v
	s["sky"] = sky
	if sky.get("sun_direction") is Vector3:
		s["sun_dir"] = (sky["sun_direction"] as Vector3).normalized()
	if sky.get("moon_direction") is Vector3:
		s["moon_dir"] = (sky["moon_direction"] as Vector3).normalized()
	var water := {}
	for row: Dictionary in id["water"]:
		var m: ShaderMaterial = row["mat"]
		for name: String in row["params"]:
			var v: Variant = row["params"][name]
			if v == null and m.shader:
				v = RenderingServer.shader_get_parameter_default(m.shader.get_rid(), name)
			if v != null and not v is Object and not water.has(name):
				water[name] = v
		break
	water.erase("moon_direction")
	s["water"] = water
	var props := {}
	for row: Dictionary in id["props"]:
		props[row["key"]] = 1.0
	s["props"] = props
	return s


func _restore_identity() -> void:
	if _identity.is_empty():
		return
	var light := sun_light()
	var l: Dictionary = _identity.get("light", {})
	if light and not l.is_empty():
		light.basis = l["basis"]
		light.light_color = l["light_color"]
		light.light_energy = l["light_energy"]
		light.shadow_enabled = l["shadow_enabled"]
	var env := environment()
	if env:
		var e: Dictionary = _identity.get("env", {})
		for prop: String in e:
			env.set(prop, e[prop])
	var mat := sky_material()
	if mat:
		var sky: Dictionary = _identity.get("sky", {})
		for name: String in sky:
			mat.set_shader_parameter(name, sky[name])
	for row: Dictionary in _identity.get("water", []):
		var m: ShaderMaterial = row["mat"]
		if is_instance_valid(m):
			for name: String in row["params"]:
				m.set_shader_parameter(name, row["params"][name])
	for row: Dictionary in _identity.get("props", []):
		var node := _prop_node(row)
		if node:
			node.set_indexed(row["property"], row["value"])


# --- Örnek ------------------------------------------------------------------------------------------

## Örnek dosyasını okur: {id → çözülmüş örnek}. Dosyanın kökündeki ortak alanlar (lat, doy, dec, date...) her
## örneğe karışır (örneğin kendi alanı önce gelir). Okunamazsa boş.
static func load_samples(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("[sky_rig] örnek dosyası yok: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or not (parsed as Dictionary).get("samples") is Dictionary:
		push_warning("[sky_rig] örnek dosyası bozuk: %s" % path)
		return {}
	var root: Dictionary = parsed
	var base := {}
	for key: String in root:
		if key != "samples":
			base[key] = root[key]
	var out := {}
	var samples: Dictionary = root["samples"]
	for id: String in samples:
		var merged: Dictionary = base.duplicate(true)
		merged.merge(samples[id], true)
		merged["id"] = id
		out[id] = resolve(merged)
	return out


## Örneği çözer (saf): yönleri ve renkleri türüne çevirir, eksik güneş, ay ve ışık yönünü Daylight'la hesaplar.
## Çözülmüş örnek yeniden çözülünce değişmez.
static func resolve(def: Dictionary) -> Dictionary:
	var s := def.duplicate(true)
	for key: String in s.keys():
		if key.ends_with("_dir"):
			s[key] = to_vector(s[key])
		elif key.ends_with("_color"):
			s[key] = to_color(s[key])
	for group: String in ["sky", "fog", "volumetric", "water"]:
		if s.get(group) is Dictionary:
			var part: Dictionary = s[group]
			for key: String in part.keys():
				if key.ends_with("_dir") or key.ends_with("_direction"):
					part[key] = to_vector(part[key])
				elif key.ends_with("color") or SKY_ALIASES.has(key) or key in ["albedo", "reflection_horizon", "reflection_zenith"]:
					part[key] = to_color(part[key])
	var has_time := s.has("lat") and s.has("minute") and (s.has("dec") or s.has("doy"))
	if has_time:
		var dec := float(s["dec"]) if s.has("dec") else Daylight.solar_dec(float(s["doy"]))
		s["dec"] = dec
		if not s.has("sun"):
			s["sun"] = Daylight.sun_at(float(s["lat"]), dec, float(s["minute"]))
		if not s.has("sun_dir"):
			s["sun_dir"] = Daylight.dir_of(s["sun"])
		if s.has("moon_age") and not s.has("moon"):
			s["moon"] = Daylight.moon_at(float(s["lat"]), dec, float(s["minute"]), float(s["moon_age"]))
		if s.has("moon") and not s.has("moon_dir"):
			s["moon_dir"] = Daylight.dir_of(s["moon"])
	if s.has("sun_dir") and not s.has("sun"):
		s["sun"] = _sample_of(s["sun_dir"])
	if s.has("sun") and not s.has("light_dir"):
		s["light_dir"] = Daylight.light_dir(s["sun"])
	return s


## Işığın yönünden düğümün dönüşümü (ışık kendi −Z'si boyunca ilerler, kaynağa bakan yön dir'dir).
static func light_basis(dir: Vector3) -> Basis:
	var d := dir.normalized()
	var up := Vector3.UP if absf(d.y) < 0.999 else Vector3.FORWARD
	return Basis.looking_at(-d, up)


static func to_vector(value: Variant) -> Vector3:
	if value is Vector3:
		return value
	if value is Array and (value as Array).size() >= 3:
		return Vector3(float(value[0]), float(value[1]), float(value[2])).normalized()
	return Vector3.ZERO


static func to_color(value: Variant) -> Color:
	if value is Color:
		return value
	if value is String:
		return Color.from_string(value, Color.WHITE)
	if value is Array and (value as Array).size() >= 3:
		var a: Array = value
		return Color(float(a[0]), float(a[1]), float(a[2]), float(a[3]) if a.size() > 3 else 1.0)
	return Color.WHITE


## Yönden {x, y, z, el, az} (az kuzeyden doğuya).
static func _sample_of(dir: Vector3) -> Dictionary:
	var d := dir.normalized()
	var az := rad_to_deg(atan2(d.x, -d.z))
	return {"x": d.x, "y": d.y, "z": d.z, "el": rad_to_deg(asin(clampf(d.y, -1.0, 1.0))), "az": az + 360.0 if az < 0.0 else az}


# --- Yazma ------------------------------------------------------------------------------------------

func _apply(sample: Dictionary) -> void:
	var s := resolve(sample)
	_write_light(s)
	_write_environment(s)
	_write_sky(s)
	_write_glint(s)
	_write_props(s)
	_current = s
	sample_applied.emit(s)


func _write_light(s: Dictionary) -> void:
	var light := get_node_or_null(light_path) as DirectionalLight3D
	if light == null:
		return
	if s.has("light_dir"):
		light.basis = light_basis(s["light_dir"])
	if s.has("light_color"):
		light.light_color = s["light_color"]
	if s.has("light_energy"):
		light.light_energy = maxf(float(s["light_energy"]), 0.0)
	if s.has("light_shadow"):
		light.shadow_enabled = bool(s["light_shadow"])


func _write_environment(s: Dictionary) -> void:
	var env := environment()
	if env == null:
		return
	for key: String in ENV_KEYS:
		if s.has(key):
			env.set(ENV_KEYS[key], s[key] if s[key] is Color else float(s[key]))
	var fog: Dictionary = s.get("fog", {})
	for key: String in fog:
		if FOG_KEYS.has(key):
			env.set(FOG_KEYS[key], fog[key] if fog[key] is Color else float(fog[key]))
	var vol: Dictionary = s.get("volumetric", {})
	for key: String in vol:
		if VOLUMETRIC_KEYS.has(key):
			env.set(VOLUMETRIC_KEYS[key], vol[key] if vol[key] is Color else float(vol[key]))
	if _taken and (s.has("grade_night") or s.has("grade_autumn")):
		var lut := _lut_for(float(s.get("grade_night", 0.0)), float(s.get("grade_autumn", 0.0)))
		if lut and env.adjustment_color_correction != lut:
			env.adjustment_color_correction = lut


func _write_sky(s: Dictionary) -> void:
	var mat := sky_material()
	if mat == null:
		return
	if s.has("sun"):
		mat.set_shader_parameter(&"sun_direction", Daylight.apparent_dir(s["sun"]))
	elif s.has("sun_dir"):
		mat.set_shader_parameter(&"sun_direction", s["sun_dir"])
	if s.has("moon_dir"):
		mat.set_shader_parameter(&"moon_direction", s["moon_dir"])
	var sky: Dictionary = s.get("sky", {})
	for key: String in sky:
		var uniform: String = SKY_ALIASES.get(key, key)
		if uniform in ["sun_direction", "moon_direction"] and (s.has("sun") or s.has("moon_dir")):
			continue
		if not _has_sky_uniform(mat, uniform):
			push_warning("[sky_rig] gök gölgelendiricisinde %s yok" % uniform)
			continue
		var value: Variant = sky[key]
		if value is String and (value as String).begins_with("res://"):
			value = _resource(value)
		mat.set_shader_parameter(uniform, value)


func _write_glint(s: Dictionary) -> void:
	if glint_paths.is_empty():
		return
	var dir := Vector3.ZERO
	var use_sun := str(s.get("glint", "")) == "sun"
	if not s.has("glint") and s.has("sun"):
		use_sun = float((s["sun"] as Dictionary).get("el", -90.0)) > GLINT_SUN_EL
	if use_sun and s.has("sun"):
		dir = Daylight.apparent_dir(s["sun"])
	elif s.has("moon_dir"):
		dir = s["moon_dir"]
	var water: Dictionary = s.get("water", {})
	for mat in _glint_materials():
		if dir != Vector3.ZERO:
			mat.set_shader_parameter(&"moon_direction", dir.normalized())
		for key: String in water:
			mat.set_shader_parameter(key, water[key])


func _write_props(s: Dictionary) -> void:
	if _identity.is_empty() or not s.get("props") is Dictionary:
		return
	var props: Dictionary = s["props"]
	for row: Dictionary in _identity.get("props", []):
		if not props.has(row["key"]):
			continue
		var node := _prop_node(row)
		if node == null:
			continue
		var base: Variant = row["value"]
		var k := float(props[row["key"]])
		if base is float or base is int:
			node.set_indexed(row["property"], float(base) * k)
		elif base is bool:
			node.set_indexed(row["property"], k > 0.01)


## props satırının düğümü: saklanan düğüm geçerliyse o, değilse kökten yolla yeniden bulunan (yoksa null).
func _prop_node(row: Dictionary) -> Node:
	var obj: Variant = row.get("node")
	if is_instance_valid(obj):
		return obj as Node
	var root: Variant = row.get("root")
	if not is_instance_valid(root) or str(row.get("path", "")).is_empty():
		return null
	var found := SkyRig.find_target(root as Node, str(row["path"]))
	row["node"] = found
	return found


## Yol çözümü: "Camp/Campfire" ya da son parçası {Sınıf} olan yol (o sınıftan ilk çocuk). Bulunmazsa null.
static func find_target(root: Node, path: String) -> Node:
	if root == null or path.is_empty():
		return null
	var node := root
	for part in path.split("/"):
		if node == null:
			return null
		if part.begins_with("{") and part.ends_with("}"):
			var cls := part.substr(1, part.length() - 2)
			var found: Node = null
			for child in node.get_children():
				if child.is_class(cls) and not child.is_queued_for_deletion():
					found = child
					break
			node = found
		else:
			node = node.get_node_or_null(NodePath(part))
	return node


func _glint_materials() -> Array[ShaderMaterial]:
	var out: Array[ShaderMaterial] = []
	for path in glint_paths:
		var mi := get_node_or_null(path) as GeometryInstance3D
		var mat := mi.material_override as ShaderMaterial if mi else null
		if mat:
			out.append(mat)
	return out


## Rig'in yazdığı ortam (yoksa null).
func environment() -> Environment:
	var node := get_node_or_null(environment_path) as WorldEnvironment
	return node.environment if node else null


## Gök gölgelendiricisinin malzemesi (yoksa null).
func sky_material() -> ShaderMaterial:
	var env := environment()
	if env == null or env.sky == null:
		return null
	return env.sky.sky_material as ShaderMaterial


func _has_sky_uniform(mat: ShaderMaterial, uniform: String) -> bool:
	if mat.shader == null:
		return false
	if _sky_uniforms.is_empty():
		for u in mat.shader.get_shader_uniform_list():
			_sky_uniforms[str(u["name"])] = true
	return _sky_uniforms.has(uniform)


## Dosya yolundaki kaynak: önce preloaded, sonra (önbellekteyse oradan) ResourceLoader.
func _resource(path: String) -> Resource:
	for res in preloaded:
		if res and res.resource_path == path:
			return res
	return load(path) if ResourceLoader.exists(path) else null


# --- Renk ayarının karışımı (godot.md §4.9: durak geçişi LUT karışımıdır) -------------------------------

## Taban görüntülerini iş parçacığında hazırlamaya başlar (bir kez; menüde boşken çağrılabilir). Hazırsa bir şey yapmaz.
static func prepare_grades() -> void:
	if not _grade_images.is_empty() or _grade_task >= 0:
		return
	_grade_task = WorkerThreadPool.add_task(_build_grade_images, false, "SkyRig LUT")


## Hazırlanan taban görüntülerinin işini bitirir (çıkışta iş parçacığı beklenir; hazırlanmıyorsa bir şey yapmaz).
static func finish_grades() -> void:
	if _grade_task >= 0:
		grades_ready(true)


## Taban görüntüleri hazır mı (hazırlanıyorsa bekler)?
static func grades_ready(wait: bool = true) -> bool:
	if _grade_images.is_empty() and _grade_task >= 0:
		if not wait and not WorkerThreadPool.is_task_completed(_grade_task):
			return false
		WorkerThreadPool.wait_for_task_completion(_grade_task)
		_grade_task = -1
	return not _grade_images.is_empty()


## Güz tonunun renk ayarı (Serbest Gez'in güzü; roam-calendar): gündüzün film görünümü, yeşil bandı sarı-zeytine kayar.
static func autumn_grade() -> ColorGrade:
	var grade := ColorGrade.world()
	grade.night = true
	grade.night_green_from = 60.0
	grade.night_green_shift = -26.0
	grade.night_green_dark_shift = -6.0
	grade.night_green_saturation = 0.82
	grade.night_green_value = 0.96
	grade.night_grey_amount = 0.0
	grade.night_general_saturation = 1.0
	grade.night_general_value = 1.0
	return grade


static func _build_grade_images() -> void:
	var grades := {"day": ColorGrade.world(), "night": ColorGrade.world_night(), "autumn": autumn_grade()}
	var out := {}
	for id: String in grades:
		var grade: ColorGrade = grades[id]
		var full: Array[Image] = []
		var half: Array[Image] = []
		for z in LUT_SIZE:
			var a := Image.create_empty(LUT_SIZE, LUT_SIZE, false, Image.FORMAT_RGBAF)
			var b := Image.create_empty(LUT_SIZE, LUT_SIZE, false, Image.FORMAT_RGBAF)
			for y in LUT_SIZE:
				for x in LUT_SIZE:
					var c := grade.apply(Color(float(x) / float(LUT_SIZE - 1), float(y) / float(LUT_SIZE - 1), float(z) / float(LUT_SIZE - 1)))
					a.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))
					b.set_pixel(x, y, Color(c.r, c.g, c.b, 0.5))
			full.append(a)
			half.append(b)
		out[id] = {"full": full, "half": half}
	_grade_images = out


## İki taban görüntüsünün karışımı (C++ yolu: adjust_bcs ve blend_rect; ≈0,7 ms): (1 − t)·a + t·b, alfa 1.
static func mix_grade_slices(a_full: Array[Image], b_half: Array[Image], t: float) -> Array[Image]:
	var out: Array[Image] = []
	var rect := Rect2i(0, 0, LUT_SIZE, LUT_SIZE)
	for z in a_full.size():
		var dst := a_full[z].duplicate() as Image
		dst.adjust_bcs(2.0 * (1.0 - t), 1.0, 1.0)
		var src := b_half[z].duplicate() as Image
		src.adjust_bcs(2.0 * t, 1.0, 1.0)
		dst.blend_rect(src, rect, Vector2i.ZERO)
		out.append(dst)
	return out


## Payların LUT'u: (1 − N)·((1 − A)·gündüz + A·güz) + N·gece. N 1 ise kimliğin (menünün) LUT'u; N 0 ve A 0 ise gündüzün LUT'u.
func _lut_for(night: float, autumn: float) -> Texture3D:
	var id_lut: Variant = (_identity.get("env", {}) as Dictionary).get("adjustment_color_correction")
	if not id_lut is Texture3D:
		return null
	night = clampf(night, 0.0, 1.0)
	autumn = clampf(autumn, 0.0, 1.0)
	if night >= 1.0 - LUT_STEP * 0.5:
		return id_lut
	if not grades_ready(false):
		# Taban görüntüleri hazırlanırken (ilk süzülmenin birkaç karesi) en yakın uç: gecenin payı yarıdan çoksa kimlik.
		return id_lut if night >= 0.5 else (_lut if _lut else id_lut)
	if night <= LUT_STEP * 0.5 and autumn <= LUT_STEP * 0.5:
		if _day_lut == null:
			_day_lut = _texture_of(_rgb8(_grade_images["day"]["full"]))
		return _day_lut
	if _lut and absf(night - _lut_night) < LUT_STEP and absf(autumn - _lut_autumn) < LUT_STEP:
		return _lut
	var day: Array[Image] = _grade_images["day"]["full"]
	if autumn > LUT_STEP * 0.5:
		day = mix_grade_slices(day, _grade_images["autumn"]["half"], autumn)
	var mixed := _rgb8(mix_grade_slices(day, _grade_images["night"]["half"], night))
	if _lut == null:
		_lut = _texture_of(mixed)
	else:
		_lut.update(mixed)
	_lut_night = night
	_lut_autumn = autumn
	return _lut


static func _rgb8(slices: Array[Image]) -> Array[Image]:
	var out: Array[Image] = []
	for img in slices:
		var c := img.duplicate() as Image
		c.convert(Image.FORMAT_RGB8)
		out.append(c)
	return out


static func _texture_of(slices: Array[Image]) -> ImageTexture3D:
	var tex := ImageTexture3D.new()
	tex.create(Image.FORMAT_RGB8, LUT_SIZE, LUT_SIZE, LUT_SIZE, false, slices)
	return tex
