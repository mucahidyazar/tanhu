class_name SynthFireCatch
extends RefCounted
## Ateşin tutuşması `fire_catch` (audio.md §4 «Yapı» ve «Önsöz ekleri»; prototipin sfx/structure.js fire_catch'i):
## önce taşın taşa vuruşu ve kıvılcımın tıkı, sonra yükselen hava (alçak geçiren 300 → 3.000 Hz süpürülür), sıklaşan
## çıtırtı ve alçak uğultu. Mit sinemasında 2:21,7'de, 1,5 sn'lik alçak sessizliğin ardından ilk ateşin sesidir.
## Ücretsiz aday (OpenGameArt «Catching Fire», CC0; büyü efektinden türedi) kulakla karşılaştırılır.
## params: strike (true: başta taş vuruşu), seconds (1,6), rate (32000: tiz atak), gain_db.

const LEVEL := 0.5


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := int(params.get("rate", 32000))
	var n := int(float(params.get("seconds", 1.6)) * sr)
	var out := SynthDsp.zeros(n)
	var t0 := 0.0
	if bool(params.get("strike", true)):
		_add_strike(out, sr, rng)
		t0 = 0.08
	# Yükselen hava: gürültü, kesimi 0,4 sn'de 300'den 3.000 Hz'e açılır, 0,2 sn tutar, 0,6 sn'de söner.
	var noise := SynthDsp.white(n, rng)
	var air := SynthDsp.zeros(n)
	var curve := SynthDsp.zeros(int(ceil(float(n) / 32.0)) + 1)
	for k in curve.size():
		var t := float(k * 32) / sr - t0
		curve[k] = 300.0 * pow(10.0, clampf(t / 0.4, 0.0, 1.0))
	SynthDsp.add_sweep(noise, air, sr, curve, 32, 0.7, 1.0)
	# Alçak uğultu: 250 Hz altı.
	var rumble := SynthDsp.biquad(SynthDsp.white(n, rng), SynthDsp.biquad_coeffs("lowpass", 250.0, 0.7, sr))
	# Çıtırtı: sıklaşan kısa tıklar (saniyede 6'dan ≈30'a), 1,2 kHz üstü.
	var crackle := SynthDsp.zeros(n)
	var t := t0 + 0.05
	while t < float(n) / sr - 0.05:
		var at := int(t * sr)
		var click_n := int(0.002 * sr)
		var amp := 0.5 + 0.5 * rng.randf()
		for j in mini(click_n, n - at):
			crackle[at + j] += (rng.randf() * 2.0 - 1.0) * amp * (1.0 - float(j) / click_n)
		var rate := 6.0 * (1.0 + 4.0 * clampf((t - t0) / 1.2, 0.0, 1.0))
		t += (0.4 + rng.randf() * 1.2) / rate
	SynthDsp.highpass1_in_place(crackle, 1200.0, sr)
	for i in n:
		var u := float(i) / sr - t0
		var e_air := 0.0
		if u > 0.0:
			e_air = clampf(u / 0.4, 0.0, 1.0) * (1.0 if u < 0.6 else exp(-(u - 0.6) / 0.3))
		var e_rum := 0.0
		if u > 0.2:
			e_rum = clampf((u - 0.2) / 0.6, 0.0, 1.0) * (1.0 if u < 0.8 else exp(-(u - 0.8) / 0.35))
		out[i] += air[i] * e_air * 0.8 + rumble[i] * e_rum * 1.6 + crackle[i] * 0.6
	SynthDsp.fade_edges(out, 0, int(0.1 * sr))
	var peak := SynthDsp.peak(out)
	if peak > 0.0:
		SynthDsp.scale_in_place(out, LEVEL / peak * SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return out


## Ak taşın kara taşa vuruşu: taş tıkı (≈800 Hz sönümlü, 40 ms) ve kıvılcımın tiz çatırtısı (3 kHz bant, 8 ms).
static func _add_strike(out: PackedFloat32Array, sr: int, rng: RandomNumberGenerator) -> void:
	var length := mini(int(0.08 * sr), out.size())
	var spark := SynthDsp.zeros(length)
	for i in length:
		spark[i] = (rng.randf() * 2.0 - 1.0) * exp(-float(i) / sr / 0.004)
	var hiss := SynthDsp.zeros(length)
	SynthDsp.add_band(spark, hiss, sr, 3200.0, 1.5, 1.0)
	for i in length:
		var t := float(i) / sr
		out[i] += sin(TAU * 820.0 * t) * exp(-t / 0.012) * 0.6 + hiss[i] * 1.4
