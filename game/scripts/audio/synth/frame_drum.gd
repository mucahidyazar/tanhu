class_name SynthFrameDrum
extends RefCounted
## Çerçeve davul (audio.md §2: perde düşümlü sinüs 110 → 70 Hz + gürültü tokadı; kenar vuruşu daha kısa): I. Perde'nin gündüz müziğinde «hafif
## çerçeve davul» (winter_day; K59). Deri vuruşu (low) gövdede, kenar vuruşu (rim) parmak ucuyla, tiz ve kısadır. Dış mekân: kuru.
## params: hits ([[onaltılık konumu, "low" | "rim", kuvvet], ...]; yoksa HITS), tempo, bars, rate (44100), gain_db.

## 6/8'de iki ölçünün yürüyüşü: ölçü başında deri, ikinci vuruşta hafif deri, araya kenar.
const HITS := [[0, "low", 0.8], [6, "low", 0.45], [9, "rim", 0.3], [12, "low", 0.65], [18, "low", 0.4], [21, "rim", 0.35]]
const LOW := {"from": 110.0, "to": 70.0, "glide": 0.12, "decay": 0.32, "slap_hz": 1200.0, "slap": 0.35}
const RIM := {"from": 240.0, "to": 200.0, "glide": 0.03, "decay": 0.07, "slap_hz": 3200.0, "slap": 0.6}
const LEVEL := 0.42


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := int(params.get("rate", SynthDsp.RATE))
	var bpm := float(params.get("tempo", 72.0))
	var bars := maxi(int(params.get("bars", SynthSequencer.PHRASE_BARS)), 1)
	var n := SynthSequencer.bar_samples(bpm, bars, sr)
	var s16 := SynthSequencer.sixteenth(bpm)
	var out := SynthDsp.zeros(n)
	var hits: Array = params["hits"] if params.get("hits") is Array else HITS
	for h: Variant in hits:
		var row: Array = h
		var dt := (rng.randf() * 2.0 - 1.0) * SynthSequencer.HUMANIZE_TIME
		var at := int(maxf(float(row[0]) * s16 + dt, 0.0) * sr)
		var vel := float(row[2]) * (1.0 + (rng.randf() * 2.0 - 1.0) * SynthSequencer.HUMANIZE_VEL)
		_hit(out, sr, at, RIM if str(row[1]) == "rim" else LOW, vel, rng)
	SynthDsp.fade_edges(out, 0, int(0.01 * sr))
	SynthDsp.scale_in_place(out, LEVEL * SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return out


static func _hit(out: PackedFloat32Array, sr: int, at: int, spec: Dictionary, vel: float, rng: RandomNumberGenerator) -> void:
	var decay := float(spec["decay"])
	var length := mini(int((decay * 5.0) * sr), out.size() - at)
	if length <= 0:
		return
	var f0 := float(spec["from"])
	var f1 := float(spec["to"])
	var glide := float(spec["glide"])
	var ph := 0.0
	var noise := SynthDsp.white(length, rng)
	var slap := SynthDsp.zeros(length)
	for i in length:
		slap[i] = noise[i] * exp(-float(i) / (0.012 * sr))
	var band := SynthDsp.zeros(length)
	SynthDsp.add_band(slap, band, sr, float(spec["slap_hz"]), 1.2, float(spec["slap"]))
	for i in length:
		var t := float(i) / sr
		var hz := f1 + (f0 - f1) * exp(-t / maxf(glide, 0.001))
		ph += hz / sr
		out[at + i] += (sin(TAU * ph) * exp(-t / decay) + band[i]) * vel
