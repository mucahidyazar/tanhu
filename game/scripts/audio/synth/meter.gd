class_name SynthMeter
extends RefCounted
## Çan ve çentik ölçüyü tutar (audio.md §3 «Perde rengi», act1.md §14: I. Perde'nin imzası; K32: sayılan sayan olur): iki ölçülük cümlede birinci
## ölçünün başında tunç çan (bell.gd, alçak perde; rehinenin ayak çanının akrabası), ikincinin başında sayıcının çentiği (notch.gd). winter_day'in
## ölçü katmanıdır; perdenin rengiyle değişmez (öbeksiz).
## params: bell_hz (520), bell_db, notch_db, tempo, bars, rate (32000), gain_db.


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := int(params.get("rate", 32000))
	var bpm := float(params.get("tempo", 72.0))
	var bars := maxi(int(params.get("bars", SynthSequencer.PHRASE_BARS)), 1)
	var n := SynthSequencer.bar_samples(bpm, bars, sr)
	var out := SynthDsp.zeros(n)
	var bar := SynthSequencer.bar_samples(bpm, 1, sr)
	var bell := SynthBell.render({"hz": float(params.get("bell_hz", 520.0)), "seconds": minf(2.0, float(n) / sr), "rate": sr}, rng)
	SynthDsp.release(bell, maxi(n - int(0.05 * sr), 0), int(0.04 * sr))
	SynthDsp.mix_into(out, bell, 0, SynthDsp.db_to_gain(float(params.get("bell_db", -4.0))))
	if bars >= 2:
		var notch := SynthNotch.render({"seconds": 0.6, "rate": sr}, rng)
		SynthDsp.mix_into(out, notch, bar, SynthDsp.db_to_gain(float(params.get("notch_db", -6.0))))
	SynthDsp.fade_edges(out, 0, int(0.02 * sr))
	SynthDsp.scale_in_place(out, SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return out
