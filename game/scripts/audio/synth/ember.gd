class_name SynthEmber
extends RefCounted
## Doğum yurdunun içi (story.md §3 satır 7a, audio.md §4 «Ortam döngüleri»): iki ortam döngüsü, 22,05 kHz mono QOA,
## bütün dosya döner (audio-import kuralı). Ücretsiz kayıtlar (K89, E7.5; assets/_free/sound/, CC0) varsa onlardan kurulur;
## yoksa aynı reçete kodla sentezlenir (sınama ve yedek).
##   "ember" (ember_crackle): ocağın közü. Ücretsiz çıtırtı kaydının (fire_crackling, OpenGameArt) tek atımları ayıklanır
##       (eşiği aşan tepeler, ±25 ms) ve döngüye seyrek, rastgele kuvvetle serpilir: kısa kayıt tekrar ediyormuş gibi
##       duyulmaz. Altında közün alçak hışırtısı (pembe gürültü, 900 Hz alçak geçiren, yavaş gezinir).
##   "yurt" (yurt_inside): yurdun içi. Ocağın ateşi (fireplace_loop: 2,6 kHz alçak geçiren, köze inmiş ateşin
##       yumuşak uğultusu) ve keçe duvarın ardındaki rüzgâr (wind_loop: 450 Hz alçak geçiren, keçe tizi yutar).
## Gezinme eğrileri periyodiktir, kuyruk başa eşit güçte katlanır (SynthDsp.fold_loop): döngü noktası duyulmaz.
## params: role ("ember", "yurt"), seconds, fold, rate (22050), grains (çıtırtı kaydı), fire, wind (kayıt yolları, proje
## köküne göre), fire_db, wind_db, density (çıtırtı/sn), rms, gain_db.

const FFMPEG := "ffmpeg"
## Közün hışırtısı ve çıtırtı yoğunluğu (sn başına).
const BED_HZ := 900.0
const DENSITY := 3.2
## Yurdun içi: ateşin ve keçenin süzgeçleri (Hz).
const FIRE_LP := 2600.0
const FELT_LP := 450.0
const EMBER_RMS := 0.05
const YURT_RMS := 0.07
## Çıtırtı ayıklama: eşik (tepenin oranı), tanecik yarı genişliği (sn), en çok tanecik.
const GRAIN_THRESHOLD := 0.35
const GRAIN_HALF := 0.025
const MAX_GRAINS := 40


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	if str(params.get("role", "ember")) == "yurt":
		return yurt(params, rng)
	return ember(params, rng)


## Ocağın közü: çıtırtı tanecikleri + alçak hışırtı; döngü.
static func ember(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := int(params.get("rate", 22050))
	var loop_n := int(float(params.get("seconds", 12.0)) * sr)
	var fade_n := int(float(params.get("fold", 0.5)) * sr)
	var n := loop_n + fade_n
	var out := SynthDsp.zeros(n)
	# Hışırtı: pembe gürültü, alçak geçiren, kazancı 12 noktada gezinir.
	var bed := SynthDsp.pink(n, rng)
	SynthDsp.biquad_in_place(bed, SynthDsp.biquad_coeffs("lowpass", BED_HZ, 0.7, sr))
	var bed_gain := SynthDsp.periodic(SynthDsp.anchors(12, 0.35, 1.0, rng), n, loop_n)
	for i in n:
		out[i] = bed[i] * bed_gain[i] * 0.5
	var grains := _grains(str(params.get("grains", "")), sr)
	var density := float(params.get("density", DENSITY))
	# Çıtırtılar katlama bölgesinin (fold) ardından başlar, döngünün sonundan önce biter: katlamada yarım tanecik kalmaz.
	var t := float(fade_n) / sr + rng.randf() * 0.2
	var end := float(loop_n) / sr - 0.05
	while t < end:
		var vel := 0.25 + 0.75 * pow(rng.randf(), 2.0)
		if grains.is_empty():
			_add_crackle(out, sr, t, vel, rng)
		else:
			var g: PackedFloat32Array = grains[rng.randi() % grains.size()]
			SynthDsp.mix_into(out, g, int(t * sr), vel)
		t += -log(maxf(rng.randf(), 0.001)) / density
	var looped := SynthDsp.fold_loop(out, loop_n, fade_n, true)
	_level(looped, float(params.get("rms", EMBER_RMS)), float(params.get("gain_db", 0.0)))
	return looped


## Yurdun içi: ocağın ateşi ve keçenin ardındaki rüzgâr; döngü.
static func yurt(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := int(params.get("rate", 22050))
	var seconds := float(params.get("seconds", 16.0))
	var fold := float(params.get("fold", 2.0))
	var loop_n := int(seconds * sr)
	var fade_n := int(fold * sr)
	var n := loop_n + fade_n
	var fire := load_source(str(params.get("fire", "")), float(params.get("fire_start", 2.0)), seconds + fold, sr)
	if fire.size() < n:
		fire = _synth_fire(n, sr, rng)
	else:
		fire.resize(n)
	SynthDsp.biquad_in_place(fire, SynthDsp.biquad_coeffs("lowpass", FIRE_LP, 0.707, sr))
	var wind := load_source(str(params.get("wind", "")), float(params.get("wind_start", 6.0)), seconds + fold, sr)
	if wind.size() < n:
		wind = _synth_wind(n, sr, loop_n, rng)
	else:
		wind.resize(n)
	SynthDsp.biquad_in_place(wind, SynthDsp.biquad_coeffs("lowpass", FELT_LP, 0.707, sr))
	SynthDsp.biquad_in_place(wind, SynthDsp.biquad_coeffs("lowpass", FELT_LP * 1.4, 0.707, sr))
	_level(fire, 1.0, 0.0)
	_level(wind, 1.0, 0.0)
	var fire_k := SynthDsp.db_to_gain(float(params.get("fire_db", -3.0)))
	var wind_k := SynthDsp.db_to_gain(float(params.get("wind_db", -8.0)))
	var out := SynthDsp.zeros(n)
	for i in n:
		out[i] = fire[i] * fire_k + wind[i] * wind_k
	SynthDsp.highpass1_in_place(out, 40.0, sr)
	var looped := SynthDsp.fold_loop(out, loop_n, fade_n, true)
	_level(looped, float(params.get("rms", YURT_RMS)), float(params.get("gain_db", 0.0)))
	return looped


## Ücretsiz kaydı ffmpeg ile mono, `rate` hızında, [start, start + seconds) aralığında okur (proje köküne göre yol ya da
## mutlak yol). Dosya ya da ffmpeg yoksa boş döner (çağıran sentezle sürer). Yalnız basma aracında çağrılır.
static func load_source(path: String, start: float, seconds: float, rate: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	if path.is_empty():
		return out
	var src := path if path.is_absolute_path() else ProjectSettings.globalize_path("res://").path_join(path)
	if not FileAccess.file_exists(src):
		push_warning("SynthEmber: kayıt yok: %s" % src)
		return out
	var tmp_dir := OS.get_environment("TMPDIR")
	if tmp_dir.is_empty() or not DirAccess.dir_exists_absolute(tmp_dir):
		tmp_dir = OS.get_temp_dir()
	var tmp := tmp_dir.path_join("synth_src_%d.wav" % Time.get_ticks_usec())
	var ff := ["-y", "-v", "error", "-ss", str(maxf(start, 0.0)), "-i", src]
	if seconds > 0.0:
		ff.append_array(["-t", str(seconds)])
	ff.append_array(["-ac", "1", "-ar", str(rate), "-c:a", "pcm_s16le", tmp])
	var log: Array = []
	if OS.execute(FFMPEG, PackedStringArray(ff), log, true) != 0:
		push_warning("SynthEmber: ffmpeg okuyamadı: %s" % src)
		return out
	var wav := AudioStreamWAV.load_from_file(tmp)
	DirAccess.remove_absolute(tmp)
	if wav == null or wav.format != AudioStreamWAV.FORMAT_16_BITS:
		return out
	var data := wav.data
	out.resize(data.size() / 2)
	for i in out.size():
		out[i] = data.decode_s16(i * 2) / 32768.0
	return out


## Çıtırtı kaydının tek atımları: eşiği aşan tepelerin çevresi (±GRAIN_HALF), kenarları yumuşatılmış.
static func _grains(path: String, sr: int) -> Array[PackedFloat32Array]:
	var out: Array[PackedFloat32Array] = []
	var pcm := load_source(path, 0.0, 0.0, sr)
	if pcm.is_empty():
		return out
	SynthDsp.highpass1_in_place(pcm, 300.0, sr)
	var top := SynthDsp.peak(pcm)
	if top <= 0.0:
		return out
	var half := int(GRAIN_HALF * sr)
	var i := half
	while i < pcm.size() - half and out.size() < MAX_GRAINS:
		if absf(pcm[i]) >= top * GRAIN_THRESHOLD:
			var g := pcm.slice(i - half / 3, i + half)
			SynthDsp.fade_edges(g, int(0.002 * sr), half / 2)
			SynthDsp.scale_in_place(g, 1.0 / top)
			out.append(g)
			i += half * 2
		else:
			i += 1
	return out


## Kayıt yokken çıtırtı: kısa sönümlü gürültü darbesi, rastgele tepe (1,5–5 kHz).
static func _add_crackle(out: PackedFloat32Array, sr: int, at: float, vel: float, rng: RandomNumberGenerator) -> void:
	var start := int(at * sr)
	var length := mini(int(0.03 * sr), out.size() - start)
	if length <= 0:
		return
	var noise := SynthDsp.white(length, rng)
	var band := SynthDsp.zeros(length)
	SynthDsp.add_band(noise, band, sr, 1500.0 + 3500.0 * rng.randf(), 2.5, 1.0)
	for i in length:
		out[start + i] += band[i] * exp(-float(i) / sr / 0.004) * vel * 1.6


## Kayıt yokken ateş: pembe gürültü (1,5 kHz alçak geçiren) ve seyrek çıtırtı.
static func _synth_fire(n: int, sr: int, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var fire := SynthDsp.pink(n, rng)
	SynthDsp.biquad_in_place(fire, SynthDsp.biquad_coeffs("lowpass", 1500.0, 0.7, sr))
	var t := 0.1
	while t < float(n) / sr - 0.05:
		_add_crackle(fire, sr, t, 0.3 + 0.5 * rng.randf(), rng)
		t += 0.15 + rng.randf() * 0.6
	return fire


## Kayıt yokken rüzgâr: pembe gürültü, kazancı yavaş gezinir (döngüye periyodik).
static func _synth_wind(n: int, sr: int, loop_n: int, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var wind := SynthDsp.pink(n, rng)
	var gain := SynthDsp.periodic(SynthDsp.anchors(6, 0.3, 1.0, rng), n, loop_n)
	for i in n:
		wind[i] *= gain[i]
	return wind


## RMS'i hedefe çeker; taşan tepe yoksa dokunmaz.
static func _level(buf: PackedFloat32Array, target_rms: float, gain_db: float) -> void:
	var r := SynthDsp.rms(buf)
	if r > 0.0:
		SynthDsp.scale_in_place(buf, target_rms / r * SynthDsp.db_to_gain(gain_db))
