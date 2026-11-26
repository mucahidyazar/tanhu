class_name SynthHujia
extends RefCounted
## Hucia (audio.md §2): geniz sesli çift dilli kamış, Hun ezgi sesi. Testere + iki biçimlendirici (≈1,1 ve 2,6 kHz),
## atakta 30–60 sent alttan kayış, nefes gürültüsü. Aralık D4–A5. Kulakla düzelir (Karar Bekleyenler).
## Kampta «ara sıra hucia cümlesi»dir: Playlist'te boş cümle kopyalarının arasında seyrek çalar.
## params: phrase ("a", "b") ya da rows ([[onaltılık konumu, uzunluğu, nota, kuvvet], ...]), tempo, bars, rate, gain_db.

const PHRASES := {
	"a": [[0, 8, "A4", 0.9], [8, 4, "C5", 0.75], [12, 6, "A4", 0.85], [18, 6, "G4", 0.8]],
	"b": [[0, 10, "D5", 0.9], [10, 2, "C5", 0.7], [12, 12, "A4", 0.85]],
}
## Biçimlendiriciler: [Hz, Q, kazanç]; geniz rengini ikisi verir.
const FORMANTS := [[1100.0, 3.0, 1.0], [2600.0, 4.0, 0.6]]
const DRY := 0.12
const ATTACK_S := 0.04
const RELEASE_S := 0.12
const BREATH := 0.06
const LEVEL := 0.35


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := int(params.get("rate", SynthDsp.RATE))
	var bpm := float(params.get("tempo", 52.0))
	var bars := maxi(int(params.get("bars", SynthSequencer.PHRASE_BARS)), 1)
	var n := SynthSequencer.bar_samples(bpm, bars, sr)
	var rows: Array = params["rows"] if params.get("rows") is Array else PHRASES.get(str(params.get("phrase", "a")), PHRASES["a"])
	var src := SynthDsp.zeros(n)
	for e: Variant in SynthSequencer.line(rows, bpm, rng, bool(params.get("humanize", true))):
		var d: Dictionary = e
		_add_note(src, sr, d, rng)
	var out := src.duplicate()
	SynthDsp.scale_in_place(out, DRY)
	for f: Array in FORMANTS:
		SynthDsp.add_band(src, out, sr, f[0], f[1], f[2])
	SynthDsp.lowpass1_in_place(out, 6000.0, sr)
	SynthDsp.fade_edges(out, 0, int(0.01 * sr))
	SynthDsp.scale_in_place(out, LEVEL * SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return out


## Nota: testere, alttan kayış (−30…−60 sent, 70 ms), 0,3 sn'den sonra hafif titreşim; nefes gürültüsü atakta güçlü.
static func _add_note(out: PackedFloat32Array, sr: int, d: Dictionary, rng: RandomNumberGenerator) -> void:
	var start := int(float(d["t"]) * sr)
	# Nota, sönüşü cümlenin içinde bitecek kadar sürer: Playlist cümleleri uç uca biner, sınırda ses kesilmez.
	var dur := minf(float(d["dur"]), float(out.size() - start) / sr - RELEASE_S)
	var length := mini(int((dur + RELEASE_S) * sr), out.size() - start)
	if length <= 0 or dur <= 0.0:
		return
	var hz := SynthDsp.midi_hz(float(d["midi"]))
	var scoop := -30.0 - 30.0 * rng.randf()
	var rate := 4.8 + 0.6 * rng.randf()
	var vib_phase := rng.randf() * TAU
	var freq := SynthDsp.control(length, sr, func(t: float) -> float:
		var depth := 8.0 * clampf((t - 0.3) / 0.5, 0.0, 1.0)
		return hz * pow(2.0, (scoop * exp(-t / 0.035) + depth * sin(TAU * rate * t + vib_phase)) / 1200.0))
	var env := SynthDsp.control(length, sr, func(t: float) -> float:
		var rise := 1.0 - exp(-t / (ATTACK_S * 0.4))
		var fall := clampf(1.0 - (t - dur) / RELEASE_S, 0.0, 1.0) if t > dur else 1.0
		return rise * fall)
	var note := SynthDsp.zeros(length)
	SynthDsp.add_saw(note, sr, freq, 1.0, rng.randf())
	var noise := SynthDsp.white(length, rng)
	var vel := float(d["vel"])
	for i in length:
		var t := float(i) / sr
		out[start + i] += (note[i] + noise[i] * BREATH * (1.0 + 3.0 * exp(-t / 0.05))) * env[i] * vel
