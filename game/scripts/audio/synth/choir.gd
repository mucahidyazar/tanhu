class_name SynthChoir
extends RefCounted
## Koro (audio.md §2 «Koro»; prototipin instruments/choir.js'i): perde başına altı testere (yayılmış akort, her seste
## ayrı yavaş titreşim), erkek korosunun «a» ve «o» biçimlendiricileri arasında yavaş gidiş geliş, nefesle kabarış.
## Koro gök içindir: yalnız `tengri` ve `dawn` (K59, #53); Önsöz'de tek çalışı gök panosundadır. Kuru ve monodur,
## geniş yankı Music yolundadır (Reverb). Görünmez: skor rengi.
## Önsöz'ün korosu açık beşlidir: yalnız D ve A perdeleri (audio.md §3 `tengri`: «Koro (açık beşli D–A)»).
##
## params: notes (MIDI listesi; yoksa OPEN_FIFTH), tempo, bars, rate (22050: içerik 3 kHz altında), arc (0..1 kesirler:
## [giriş biter, çıkış başlar]; koro dosyanın içinde bir kez kabarır ve söner), loop, fold (sn), gain_db; raw (sınama:
## biçimlendiricisiz kaynak).
## Döngülü dosyada (düz katman) baş ve son sessizdir ve kuyruk başa katlanır: döngü noktası duyulmaz.

const VOICES := 6
## Seslerin yayılması (sent): -7,5 … +7,5 ve ±1 rastgele.
const SPREAD_CENTS := 3.0
## Açık beşli: D3, A3, D4 (yalnız D ve A).
const OPEN_FIFTH: Array[int] = [50, 57, 62]
## İzin verilen perde sınıfları (D = 2, A = 9).
const PITCH_CLASSES: Array[int] = [2, 9]
## Ünlüler: [Hz, Q, kazanç].
const VOWELS := {
	"a": [[700.0, 5.0, 1.0], [1150.0, 6.0, 0.6], [2600.0, 8.0, 0.24]],
	"o": [[450.0, 5.0, 1.0], [800.0, 6.0, 0.5], [2600.0, 8.0, 0.14]],
}
## Ünlünün gidiş gelişi (döngüde periyot sayısı) ve nefes kabarması.
const VOWEL_CYCLES := 2.0
const BREATH_CYCLES := 3.0
const CHOIR_RMS := 0.12


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := int(params.get("rate", 22050))
	var bpm := float(params.get("tempo", 48.0))
	var bars := maxi(int(params.get("bars", 12)), 1)
	var loop_n := SynthSequencer.bar_samples(bpm, bars, sr)
	var loop := bool(params.get("loop", true))
	var fade_n := int(float(params.get("fold", 1.0)) * sr) if loop else 0
	var n := loop_n + fade_n
	var arc: Array = params["arc"] if params.get("arc") is Array else [0.12, 0.86]
	var src := SynthDsp.zeros(n)
	for midi: int in notes(params):
		_add_part(src, sr, midi, rng)
	if bool(params.get("raw", false)):
		# Sınama: biçimlendiricisiz kaynak (perdeler ölçülsün diye), kabarışla.
		for i in n:
			src[i] *= arc_gain(float(i % loop_n), float(arc[0]) * loop_n, float(arc[1]) * loop_n, float(loop_n))
		return src
	var noise := SynthDsp.white(n, rng)
	for i in n:
		src[i] += noise[i] * 0.02
	var vowel_a := SynthDsp.zeros(n)
	var vowel_o := SynthDsp.zeros(n)
	for f: Array in VOWELS["a"]:
		SynthDsp.add_band(src, vowel_a, sr, f[0], f[1], f[2])
	for f: Array in VOWELS["o"]:
		SynthDsp.add_band(src, vowel_o, sr, f[0], f[1], f[2])
	var out := SynthDsp.zeros(n)
	var a0 := float(arc[0]) * loop_n
	var a1 := float(arc[1]) * loop_n
	for i in n:
		var u := float(i % loop_n) / float(loop_n)
		var mix := 0.5 + 0.5 * cos(TAU * VOWEL_CYCLES * u)
		var breath := 1.0 + 0.08 * sin(TAU * BREATH_CYCLES * u)
		out[i] = (vowel_a[i] * mix + vowel_o[i] * (1.0 - mix)) * breath * arc_gain(float(i % loop_n), a0, a1, float(loop_n))
	SynthDsp.biquad_in_place(out, SynthDsp.biquad_coeffs("highpass", 90.0, 0.7, sr))
	var result := SynthDsp.fold_loop(out, loop_n, fade_n, true) if loop else out
	var r := SynthDsp.rms(result)
	if r > 0.0:
		SynthDsp.scale_in_place(result, CHOIR_RMS / r * SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return result


## Korunun perdeleri (MIDI): params.notes ya da açık beşli.
static func notes(params: Dictionary) -> Array[int]:
	var out: Array[int] = []
	if params.get("notes") is Array:
		for m: Variant in params["notes"]:
			out.append(int(m))
	else:
		out = OPEN_FIFTH.duplicate()
	return out


## Perdeler yalnız D ve A mı?
static func is_open_fifth(midi_notes: Array[int]) -> bool:
	for m in midi_notes:
		if not PITCH_CLASSES.has(posmod(m, 12)):
			return false
	return not midi_notes.is_empty()


## Kabarış: girişte a0'a dek yükseltilmiş kosinüsle açılır, a1'den dosyanın sonuna dek söner (döngüde baş ve son sessiz).
static func arc_gain(i: float, a0: float, a1: float, loop_n: float) -> float:
	if i < a0:
		return 0.5 - 0.5 * cos(PI * i / maxf(a0, 1.0))
	if i > a1:
		return 0.5 + 0.5 * cos(PI * clampf((i - a1) / maxf(loop_n - a1, 1.0), 0.0, 1.0))
	return 1.0


## Bir perde: altı testere; her ses kendi akort payı, titreşimi (4,6–5,6 Hz, gecikmeli) ve yavaş gezinmesiyle.
static func _add_part(out: PackedFloat32Array, sr: int, midi: int, rng: RandomNumberGenerator) -> void:
	var n := out.size()
	var hz := SynthDsp.midi_hz(float(midi))
	for v in VOICES:
		var spread := (float(v) - (VOICES - 1) * 0.5) * SPREAD_CENTS + (rng.randf() - 0.5) * 2.0
		var rate := 4.6 + rng.randf()
		var depth := 6.0 + rng.randf() * 8.0
		var phase := rng.randf() * TAU
		var drift := rng.randf() * TAU
		var freq := SynthDsp.control(n, sr, func(t: float) -> float:
			return hz * pow(2.0, (spread + depth * minf(1.0, t / 1.2) * sin(TAU * rate * t + phase)
					+ 4.0 * sin(TAU * 0.17 * t + drift)) / 1200.0), 32)
		SynthDsp.add_saw(out, sr, freq, 1.0 / VOICES, rng.randf())
