class_name SynthJaw
extends RefCounted
## Ağız kopuzu (audio.md §2: darbe dizisi, biçimlendirici süpürmesi; Mete'nin çalgısı, I. Perde; K59, K60): dil parmakla çekilir, titreşimi ağız
## boşluğunun biçimlendiricisinden geçer; çalan, ağzını açıp kapayarak kökün üstsesleri arasında ezgi çizer. winter_night'ta «tek tük ağız kopuzu»:
## cümlede iki üç çekiş ve aralarında sessizlik. Kök E2 (82,4 Hz; kerbez akordunun kökü), dar (Q≈9) bant geçiren 4.–10. üstsesler arasında gezinir.
## params: plucks ([[onaltılık konumu, [üstses, üstses, ...], kuvvet], ...]; yoksa PLUCKS), root (MIDI; 40 = E2), tempo, bars, rate (44100),
## gain_db.

## Cümle: iki ölçüde üç çekiş; her çekişte biçimlendirici üstsesten üstsese kayar.
const PLUCKS := [[0, [6, 8, 6], 0.75], [9, [5, 6], 0.55], [15, [8, 10, 9, 8], 0.7]]
const DUTY := 0.12
const RING := 1.4
const Q := 9.0
const DRY := 0.08
const LEVEL := 0.34


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := int(params.get("rate", SynthDsp.RATE))
	var bpm := float(params.get("tempo", 58.0))
	var bars := maxi(int(params.get("bars", SynthSequencer.PHRASE_BARS)), 1)
	var n := SynthSequencer.bar_samples(bpm, bars, sr)
	var s16 := SynthSequencer.sixteenth(bpm)
	var root := SynthDsp.midi_hz(float(params.get("root", 40)))
	var plucks: Array = params["plucks"] if params.get("plucks") is Array else PLUCKS
	var out := SynthDsp.zeros(n)
	for p: Variant in plucks:
		var row: Array = p
		var at := int(float(row[0]) * s16 * sr)
		var length := mini(int(RING * sr), n - at)
		if length <= 0:
			continue
		var harmonics: Array = row[1]
		var vel := float(row[2])
		# Darbe dizisi: dar darbe, çekişte sert, sonra söner.
		var src := SynthDsp.zeros(length)
		var ph := rng.randf()
		for i in length:
			var t := float(i) / sr
			ph += root * (1.0 + 0.002 * sin(TAU * 5.0 * t)) / sr
			ph -= floorf(ph)
			src[i] = ((1.0 if ph < DUTY else 0.0) - DUTY) * exp(-t / 0.55) * (1.0 + 2.0 * exp(-t / 0.01))
		# Ağız: biçimlendirici üstsesler arasında kayar (her basamağa eşit pay, 60 ms geçiş).
		var step_n := float(length) / float(maxi(harmonics.size(), 1))
		var curve := SynthDsp.zeros(int(ceil(float(length) / 16.0)) + 1)
		for b in curve.size():
			var k := clampi(int(float(b * 16) / step_n), 0, harmonics.size() - 1)
			var into := fmod(float(b * 16), step_n) / sr
			var from_h := float(harmonics[maxi(k - 1, 0)])
			var to_h := float(harmonics[k])
			curve[b] = root * lerpf(from_h, to_h, clampf(into / 0.06, 0.0, 1.0))
		var shaped := SynthDsp.zeros(length)
		SynthDsp.add_sweep(src, shaped, sr, curve, 16, Q, 1.0)
		for i in length:
			shaped[i] += src[i] * DRY
		SynthDsp.mix_into(out, shaped, at, vel)
	SynthDsp.lowpass1_in_place(out, 5000.0, sr)
	SynthDsp.fade_edges(out, 0, int(0.03 * sr))
	var peak := SynthDsp.peak(out)
	if peak > 0.0:
		SynthDsp.scale_in_place(out, LEVEL / peak * SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return out
