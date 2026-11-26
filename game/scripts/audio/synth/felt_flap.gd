class_name SynthFeltFlap
extends RefCounted
## Keçe hışırtısı `felt_flap` (audio.md §4 «Yapı» ve «Önsöz ekleri»: keçe panonun hışırtısı; prototipin
## sfx/structure.js felt_flap'i): çırpınan kalın kumaş. Alçak geçirenden geçmiş gürültü patlaması 15–20 Hz'lik çırpıntıyla
## dalgalanır, sonunda alçak bir tok (70 → 50 Hz). Mit sinemasında pano geçişlerinde çalar.
## params: seconds (0,6), flutter (Hz; yoksa 15–20 arası tohumla), rate (22050), gain_db.

const LEVEL := 0.45


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := int(params.get("rate", 22050))
	var n := int(float(params.get("seconds", 0.6)) * sr)
	var flutter := float(params.get("flutter", 15.0 + rng.randf() * 5.0))
	var noise := SynthDsp.white(n, rng)
	# Hışırtının bandı kumaş açılırken yükselir: 500 Hz'den 1.100 Hz'e, sonra iner.
	var body := SynthDsp.zeros(n)
	var curve := SynthDsp.zeros(int(ceil(float(n) / 32.0)) + 1)
	for k in curve.size():
		var t := float(k * 32) / sr
		curve[k] = 500.0 + 600.0 * sin(PI * clampf(t / 0.35, 0.0, 1.0))
	SynthDsp.add_sweep(noise, body, sr, curve, 32, 0.8, 1.0)
	SynthDsp.lowpass1_in_place(body, 1800.0, sr)
	var out := SynthDsp.zeros(n)
	for i in n:
		var t := float(i) / sr
		var env := clampf(t / 0.02, 0.0, 1.0) * (1.0 if t < 0.12 else exp(-(t - 0.12) / 0.11))
		var flap := 0.55 + 0.45 * sin(TAU * flutter * t)
		var thud := sin(TAU * lerpf(70.0, 50.0, clampf(t / 0.08, 0.0, 1.0)) * t) * exp(-t / 0.05) * 0.25
		out[i] = body[i] * env * flap + thud
	SynthDsp.fade_edges(out, 0, int(0.04 * sr))
	var peak := SynthDsp.peak(out)
	if peak > 0.0:
		SynthDsp.scale_in_place(out, LEVEL / peak * SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return out
