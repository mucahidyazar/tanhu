class_name SynthKaval
extends RefCounted
## Kaval (audio.md §2; prototipin instruments/kaval.js'i): sinüs ve zayıf ikinci, üçüncü harmonik (içi boş kamış),
## harmonik çevresinde dar bant ve geniş hava gürültüsü, atakta «çuf», nefes zarfı, 0,4 sn'den sonra titreşim.
## camp_night'ta 40–70 sn'de bir kısa cümle: Playlist'te çok sayıda boş cümle kopyasının arasında çalar; motifin
## düşüşü A G F D gecede bir kez bu cümlededir.
## params: phrase ("motif", "call") ya da rows, tempo, bars, variant ("tone", "breath": gecede daha çok nefes), rate,
## gain_db.

const PHRASES := {
	"motif": [[0, 6, "A5", 0.85], [6, 6, "G5", 0.8], [12, 3, "F5", 0.78], [15, 9, "D5", 0.9]],
	"call": [[0, 9, "D5", 0.85], [9, 3, "E5", 0.7], [12, 12, "A4", 0.8]],
}
const RELEASE_S := 0.15
const LEVEL := 0.4


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := int(params.get("rate", SynthDsp.RATE))
	var bpm := float(params.get("tempo", 46.0))
	var bars := maxi(int(params.get("bars", SynthSequencer.PHRASE_BARS)), 1)
	var n := SynthSequencer.bar_samples(bpm, bars, sr)
	var rows: Array = params["rows"] if params.get("rows") is Array else PHRASES.get(str(params.get("phrase", "motif")), PHRASES["motif"])
	var airy := 2.4 if str(params.get("variant", "breath")) == "breath" else 1.0
	var out := SynthDsp.zeros(n)
	for e: Variant in SynthSequencer.line(rows, bpm, rng, bool(params.get("humanize", true))):
		_add_note(out, sr, e, airy, rng)
	SynthDsp.fade_edges(out, 0, int(0.01 * sr))
	SynthDsp.scale_in_place(out, LEVEL * SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return out


static func _add_note(out: PackedFloat32Array, sr: int, d: Dictionary, airy: float, rng: RandomNumberGenerator) -> void:
	var start := int(float(d["t"]) * sr)
	# Nota, sönüşü cümlenin içinde bitecek kadar sürer: Playlist cümleleri uç uca biner, sınırda ses kesilmez.
	var dur := minf(float(d["dur"]), float(out.size() - start) / sr - RELEASE_S)
	var length := mini(int((dur + RELEASE_S) * sr), out.size() - start)
	if length <= 0 or dur <= 0.0:
		return
	var hz := SynthDsp.midi_hz(float(d["midi"]))
	var rate := 4.8 + rng.randf() * 0.5
	var vib_phase := rng.randf() * TAU
	var wander := rng.randf() * TAU
	# Perde atakta aşağıdan süzülür, 0,4 sn'den sonra titrer; zarf yumuşak çıkış ve solukla dalgalanır.
	var freq := SynthDsp.control(length, sr, func(t: float) -> float:
		var depth := 10.0 * clampf((t - 0.4) / 0.6, 0.0, 1.0)
		return hz * pow(2.0, (depth * sin(TAU * rate * t + vib_phase) + 3.0 * sin(TAU * 0.23 * t + wander) - 18.0 * exp(-t / 0.05)) / 1200.0))
	var env := SynthDsp.control(length, sr, func(t: float) -> float:
		var fall := clampf(1.0 - (t - dur) / RELEASE_S, 0.0, 1.0) if t > dur else 1.0
		return (1.0 - exp(-t / 0.06)) * (1.0 + 0.05 * sin(TAU * 0.7 * t + wander)) * fall)
	var tone := SynthDsp.zeros(length)
	var ph := 0.0
	for i in length:
		ph += freq[i] / sr
		if ph >= 1.0:
			ph -= 1.0
		var s := sin(TAU * ph)
		var c := cos(TAU * ph)
		tone[i] = (s + 0.12 * 2.0 * s * c + 0.07 * (3.0 * s - 4.0 * s * s * s)) * env[i]
	var noise := SynthDsp.white(length, rng)
	var breath := SynthDsp.zeros(length)
	SynthDsp.add_band(noise, breath, sr, hz * 2.0, 3.0, 0.5)
	SynthDsp.add_band(noise, breath, sr, 3000.0, 0.7, 0.25)
	var vel := float(d["vel"])
	for i in length:
		var t := float(i) / sr
		var chiff := 0.18 * exp(-t / 0.025)
		out[start + i] += (tone[i] * 0.8 + breath[i] * (0.07 * airy * env[i] + chiff)) * vel
