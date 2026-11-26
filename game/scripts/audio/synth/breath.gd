class_name SynthBreath
extends RefCounted
## Nefes `breath` (story.md §3 pano 6 ve §4: «Keçe, nefes, tek tel»; prototipin sfx/foot.js breath_out'u): doğum
## yurdunda alınan ve verilen soluk. Soluk alış dar bantta yükselir (≈1,2 → 1,6 kHz), veriş daha alçakta (900 → 600 Hz)
## iner; ikisinin üstünde ince hava (3 kHz üstü). Söz yoktur.
## params: inhale (true), seconds (1,7), rate (22050), gain_db.

const LEVEL := 0.35


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := int(params.get("rate", 22050))
	var n := int(float(params.get("seconds", 1.7)) * sr)
	var inhale := bool(params.get("inhale", true))
	var noise := SynthDsp.white(n, rng)
	var curve := SynthDsp.zeros(int(ceil(float(n) / 32.0)) + 1)
	# Soluk alış 0–0,55 sn, veriş 0,7–1,6 sn (alış yoksa veriş baştan).
	var ex0 := 0.7 if inhale else 0.05
	for k in curve.size():
		var t := float(k * 32) / sr
		if inhale and t < 0.6:
			curve[k] = 1200.0 + 400.0 * clampf(t / 0.55, 0.0, 1.0)
		else:
			curve[k] = 900.0 - 300.0 * clampf((t - ex0) / 0.8, 0.0, 1.0)
	var voiced := SynthDsp.zeros(n)
	SynthDsp.add_sweep(noise, voiced, sr, curve, 32, 0.9, 1.0)
	var air := SynthDsp.zeros(n)
	SynthDsp.add_biquad(noise, air, SynthDsp.biquad_coeffs("highpass", 3000.0, 0.7, sr), 0.3)
	var out := SynthDsp.zeros(n)
	for i in n:
		var t := float(i) / sr
		var e := 0.0
		if inhale and t < 0.62:
			e = 0.55 * clampf(t / 0.3, 0.0, 1.0) * clampf((0.62 - t) / 0.12, 0.0, 1.0)
		if t >= ex0:
			var u := t - ex0
			e = maxf(e, clampf(u / 0.08, 0.0, 1.0) * (1.0 if u < 0.15 else exp(-(u - 0.15) / 0.28)))
		out[i] = (voiced[i] + air[i]) * e
	SynthDsp.lowpass1_in_place(out, 6000.0, sr)
	SynthDsp.fade_edges(out, int(0.01 * sr), int(0.05 * sr))
	var peak := SynthDsp.peak(out)
	if peak > 0.0:
		SynthDsp.scale_in_place(out, LEVEL / peak * SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return out
