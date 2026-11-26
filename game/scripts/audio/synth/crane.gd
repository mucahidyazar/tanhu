class_name SynthCrane
extends RefCounted
## Turna `crane_call` (audio.md §4 «Önsöz ekleri»: doğumda güneye geçen turnalar; dar biçimlendirici ≈1 kHz, sert atak,
## çatlak; sürü 8–12 çalış, gökte hareketli kaynak). İki rol:
##   "recording" (oyunun dosyası): ücretsiz kaydın (crane_call_1 Grus_grus, crane_call_2 Gervės; Wikimedia Commons, CC0)
##       bir kesiti ffmpeg ile okunur (SynthEmber.load_source), rüzgârın gümbürtüsü yüksek geçirenle, kayıttaki sabit tonlu
##       çizgiler (Grus_grus'ta ≈3,9 ve 7,8 kHz) çentik ve alçak geçirenle temizlenir, kenarlar yumuşar, düzey çekilir.
##   "flock" (kodla basılan karşılaştırma adayı): kaynak-süzgeç sentezi. Her çağrı «krru»dur: temel perde ≈420–520 Hz
##       (hafif yükselir), perdenin yarısında alt harmonik ve titreme («çatlak»), dar biçimlendirici FORMANT_HZ'de (Q 8),
##       geniş ikincisi 2,1 kHz'de; atak 4 ms'de sert, sönüş ≈0,12 sn. Sürü iki sesle sıralı 8–12 çağrıdır, uzaklıkla
##       kısılır ve tizi söner.
## params: role ("flock" varsayılan, "recording"), file (proje köküne göre), start, seconds, highpass, lowpass, notches
## ([Hz, ...]), rms (hedef düzey), calls (sürünün çağrı sayısı), distance (0..1), rate (22050), gain_db.

## Turnanın dar biçimlendiricisi (Hz) ve genişliği (Q); ikinci, geniş biçimlendirici.
const FORMANT_HZ := 1000.0
const FORMANT_Q := 8.0
const SECOND := [2100.0, 5.0, 0.35]
const LOW := [520.0, 4.0, 0.2]
## Çağrının temel perde aralığı (Hz) ve süresi (sn).
const F0_RANGE := Vector2(420.0, 520.0)
const CALL_S := 0.3
## Alt harmoniğin («çatlak») payı.
const CRACK := 0.3
const LEVEL := 0.45
const RECORDING_RMS := 0.08


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	if str(params.get("role", "flock")) == "recording":
		return recording(params)
	return flock(params, rng)


## Ücretsiz kaydın temizlenmiş kesiti; kayıt okunamazsa boş.
static func recording(params: Dictionary) -> PackedFloat32Array:
	var sr := int(params.get("rate", 22050))
	var pcm := SynthEmber.load_source(str(params.get("file", "")), float(params.get("start", 0.0)),
			float(params.get("seconds", 6.0)), sr)
	if pcm.is_empty():
		return pcm
	var hp := float(params.get("highpass", 320.0))
	if hp > 0.0:
		SynthDsp.biquad_in_place(pcm, SynthDsp.biquad_coeffs("highpass", hp, 0.707, sr))
		SynthDsp.biquad_in_place(pcm, SynthDsp.biquad_coeffs("highpass", hp, 0.707, sr))
	var notches: Variant = params.get("notches", [])
	for hz: Variant in (notches if notches is Array else []):
		# Dar çentik: bant geçirenin çıkarılması (Q 12), iki kez.
		for _k in 2:
			var band := SynthDsp.zeros(pcm.size())
			SynthDsp.add_band(pcm, band, sr, float(hz), 12.0, 1.0)
			for i in pcm.size():
				pcm[i] -= band[i]
	var lp := float(params.get("lowpass", 0.0))
	if lp > 0.0:
		SynthDsp.biquad_in_place(pcm, SynthDsp.biquad_coeffs("lowpass", lp, 0.707, sr))
		SynthDsp.biquad_in_place(pcm, SynthDsp.biquad_coeffs("lowpass", lp, 0.707, sr))
	SynthDsp.fade_edges(pcm, int(0.05 * sr), int(float(params.get("fade_out", 0.4)) * sr))
	var r := SynthDsp.rms(pcm)
	if r > 0.0:
		SynthDsp.scale_in_place(pcm, float(params.get("rms", RECORDING_RMS)) / r * SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return pcm


## Kodla basılan sürü: iki sesle sıralı çağrılar, uzaklıkla süzülür.
static func flock(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := int(params.get("rate", 22050))
	var seconds := float(params.get("seconds", 5.5))
	var n := int(seconds * sr)
	var src := SynthDsp.zeros(n)
	for c: Array in schedule(params, rng):
		_add_call(src, sr, float(c[0]), float(c[1]), float(c[2]), rng)
		# İkili çağrı («kr-ruu»): ara sıra hemen ardından kısa ikinci hece.
		if bool(c[3]):
			_add_call(src, sr, float(c[0]) + CALL_S * 0.72, float(c[1]) * 1.04, float(c[2]) * 0.7, rng)
	var out := SynthDsp.zeros(n)
	SynthDsp.add_band(src, out, sr, FORMANT_HZ, FORMANT_Q, 1.0)
	SynthDsp.add_band(src, out, sr, SECOND[0], SECOND[1], SECOND[2])
	SynthDsp.add_band(src, out, sr, LOW[0], LOW[1], LOW[2])
	var distance := clampf(float(params.get("distance", 0.6)), 0.0, 1.0)
	SynthDsp.lowpass1_in_place(out, lerpf(7000.0, 2600.0, distance), sr)
	# Gökten yere: uzak yansıma (90 ms, 170 ms).
	var echo := SynthDsp.zeros(n)
	SynthDsp.mix_into(echo, out, int(0.09 * sr), 0.25 * distance)
	SynthDsp.mix_into(echo, out, int(0.17 * sr), 0.12 * distance)
	for i in n:
		out[i] += echo[i]
	SynthDsp.fade_edges(out, int(0.003 * sr), int(0.1 * sr))
	var peak := SynthDsp.peak(out)
	if peak > 0.0:
		SynthDsp.scale_in_place(out, LEVEL / peak * SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return out


## Sürünün çağrıları (saf): [[sn, temel perde Hz, kuvvet, ikili mi], ...]; calls (8–12, varsayılan 10) çağrı
## seconds'a sıralı ve ayrık yayılır (iki ses sırayla; ikincisi %6 tiz).
static func schedule(params: Dictionary, rng: RandomNumberGenerator) -> Array:
	var seconds := float(params.get("seconds", 5.5))
	var count := clampi(int(params.get("calls", 10)), 1, 24)
	var span := maxf(seconds - CALL_S * 1.8 - 0.1, 0.5)
	var step := span / float(count)
	var out: Array = []
	for k in count:
		var voice := k % 2
		var t := 0.08 + step * (float(k) + 0.15 + 0.55 * rng.randf())
		var f0 := lerpf(F0_RANGE.x, F0_RANGE.y, 0.25 + 0.5 * rng.randf()) * (1.06 if voice == 1 else 1.0)
		var vel := 0.65 + 0.35 * rng.randf()
		out.append([t, f0, vel, rng.randf() < 0.45])
	return out


## Tek çağrı: testere ve yarı perdede alt harmonik (çatlak), titreme; atak 4 ms, kısa düzlük, ≈0,12 sn sönüş.
static func _add_call(out: PackedFloat32Array, sr: int, at: float, f0: float, vel: float, rng: RandomNumberGenerator) -> void:
	var start := int(at * sr)
	var length := mini(int((CALL_S + 0.15) * sr), out.size() - start)
	if length <= 0:
		return
	var jit := rng.randf() * TAU
	var freq := SynthDsp.control(length, sr, func(t: float) -> float:
		return f0 * (1.0 + 0.06 * clampf(t / CALL_S, 0.0, 1.0) + 0.012 * sin(TAU * 23.0 * t + jit)))
	var half := SynthDsp.control(length, sr, func(t: float) -> float:
		return f0 * 0.5 * (1.0 + 0.06 * clampf(t / CALL_S, 0.0, 1.0)))
	var tone := SynthDsp.zeros(length)
	SynthDsp.add_saw(tone, sr, freq, 1.0, rng.randf())
	SynthDsp.add_saw(tone, sr, half, CRACK, rng.randf())
	var noise := SynthDsp.white(length, rng)
	for i in length:
		var t := float(i) / sr
		var env := clampf(t / 0.004, 0.0, 1.0) * (1.0 if t < CALL_S * 0.55 else exp(-(t - CALL_S * 0.55) / 0.12))
		out[start + i] += (tone[i] + noise[i] * 0.15) * env * vel
