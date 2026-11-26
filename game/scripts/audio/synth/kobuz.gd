class_name SynthKobuz
extends RefCounted
## Kıl kobuz (audio.md §2 «Kıl kobuz»; prototipin instruments/kobuz.js'i): iki testere osilatör (±4 sent), biçimlendirici
## bant geçirenler (650 Hz Q1,2 ve 1500 Hz Q2), kıl yayın nefes gürültüsü, gecikmeli titreşim (5,2 Hz, ±12 sent),
## notalar arası kayma; atak 0,25 sn. Kıl kobuz Mete'den en az 700 yıl sonradır: sahnede görünmez, skorda kalır
## (K60). Ana renk yalnız `tengri` ve `erlik`'tedir.
## Türler (variant): `bow` uzun yay; `scrape` Erlik'in yayı: köprü üstünde sürtünen tel, gürültü ve üst biçimlendirici
## güçlü, titreşim yarım.
## params: phrase (PHRASES'tan) ya da rows ([[onaltılık konumu, uzunluğu, nota, kuvvet], ...]), tempo, bars, variant,
## legato (true: bir notadan ötekine GLIDE_S'de kayar), humanize, rate (44100), gain_db.
## Cümleler Playlist'te uç uca biner: son nota cümlenin içinde söner.

const VIBRATO_HZ := 5.2
const VIBRATO_CENTS := 12.0
## Titreşim notanın başında yoktur: 0,35 sn'de başlar, 0,85 sn'de tam derinliğe varır.
const VIBRATO_FROM := 0.35
const VIBRATO_FULL := 0.85
## İki testerenin akort payı (sent).
const DETUNE_CENTS := 4.0
## Yayın atağı: yükseltilmiş kosinüsle tam 0,25 sn'de oturur.
const ATTACK_S := 0.25
const RELEASE_S := 0.18
## Notalar arası kayma (legato).
const GLIDE_S := 0.09
const LEVEL := 0.32
## Türler: biçimlendiriciler [Hz, Q, kazanç], kuru pay, gürültünün bandı ve düzeyi, titreşim çarpanı ve düzey payı
## (scrape'in biçimlendiricileri tizdedir, aynı yay basıncında ≈8 dB kısık çıkar; pay onu bow'un düzeyine getirir).
const VARIANTS := {
	"bow": {"formants": [[300.0, 1.5, 0.4], [650.0, 1.2, 1.0], [1500.0, 2.0, 0.55]], "dry": 0.16,
		"noise_hz": 2200.0, "noise": 0.05, "vib": 1.0, "grind": 0.0, "level": 1.0},
	"scrape": {"formants": [[1500.0, 2.0, 0.8], [3200.0, 4.0, 0.7], [650.0, 1.2, 0.3]], "dry": 0.04,
		"noise_hz": 3400.0, "noise": 0.22, "vib": 0.5, "grind": 0.4, "level": 2.6},
}
## Cümleler (iki ölçü = 24 onaltılık). erlik_*: E Frigyen, alçak, yarım ses inleyişi (E–F–E); tengri_*: F majör
## pentatonik, düşüş A G F D ve uzun gök notaları (motif perdenin biçimiyle, audio.md §3).
const PHRASES := {
	"erlik_a": [[0, 9, "E3", 0.8], [9, 3, "F3", 0.7], [12, 10, "E3", 0.78]],
	"erlik_b": [[0, 6, "G3", 0.7], [6, 6, "F3", 0.75], [12, 10, "E3", 0.82]],
	"tengri_a": [[0, 6, "A4", 0.8], [6, 6, "G4", 0.72], [12, 4, "F4", 0.75], [16, 6, "D4", 0.82]],
	"tengri_b": [[0, 12, "C5", 0.72], [12, 10, "A4", 0.8]],
}


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := int(params.get("rate", SynthDsp.RATE))
	var bpm := float(params.get("tempo", 52.0))
	var bars := maxi(int(params.get("bars", SynthSequencer.PHRASE_BARS)), 1)
	var n := SynthSequencer.bar_samples(bpm, bars, sr)
	var shape: Dictionary = VARIANTS.get(str(params.get("variant", "bow")), VARIANTS["bow"])
	var legato := bool(params.get("legato", true))
	var src := SynthDsp.zeros(n)
	var prev := -1.0
	for e: Variant in SynthSequencer.line(rows_of(params), bpm, rng, bool(params.get("humanize", true))):
		var d: Dictionary = e
		_add_note(src, sr, d, shape, prev if legato else -1.0, rng)
		prev = float(d["midi"])
	var out := src.duplicate()
	SynthDsp.scale_in_place(out, float(shape["dry"]))
	for f: Array in shape["formants"]:
		SynthDsp.add_band(src, out, sr, f[0], f[1], f[2])
	SynthDsp.lowpass1_in_place(out, 7000.0, sr)
	SynthDsp.fade_edges(out, 0, int(0.01 * sr))
	SynthDsp.scale_in_place(out, LEVEL * float(shape["level"]) * SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return out


## Tek nota (atak ve titreşim sınaması): bir yay, biçimlendiricilerle. detune: iki testerenin akort payı (sent; 0'da
## vuruşma olmaz, atak ölçülürken kullanılır).
static func render_note(midi: int, seconds: float, variant: String, sr: int, rng: RandomNumberGenerator,
		detune: float = DETUNE_CENTS) -> PackedFloat32Array:
	var n := int(seconds * sr)
	var shape: Dictionary = VARIANTS.get(variant, VARIANTS["bow"])
	var src := SynthDsp.zeros(n)
	_add_note(src, sr, {"t": 0.0, "dur": seconds - RELEASE_S, "midi": midi, "vel": 1.0}, shape, -1.0, rng, detune)
	var out := src.duplicate()
	SynthDsp.scale_in_place(out, float(shape["dry"]))
	for f: Array in shape["formants"]:
		SynthDsp.add_band(src, out, sr, f[0], f[1], f[2])
	SynthDsp.scale_in_place(out, LEVEL * float(shape["level"]))
	return out


## Cümlenin satırları: rows verilmişse onlar, yoksa PHRASES[phrase].
static func rows_of(params: Dictionary) -> Array:
	if params.get("rows") is Array:
		return params["rows"]
	return PHRASES.get(str(params.get("phrase", "erlik_a")), PHRASES["erlik_a"])


## Yayın zarfı (0..1): yükseltilmiş kosinüs atak (ATTACK_S'de 1), sonra oturan basınç; dur'dan sonra RELEASE_S'de söner.
static func envelope(t: float, dur: float) -> float:
	var rise := 0.5 - 0.5 * cos(PI * clampf(t / ATTACK_S, 0.0, 1.0))
	var fall := clampf(1.0 - (t - dur) / RELEASE_S, 0.0, 1.0) if t > dur else 1.0
	return rise * fall


## Nota: iki testere ±DETUNE_CENTS; perde önceki notadan GLIDE_S'de kayar (legato), titreşim gecikmeli; yayın
## sürtünmesi atakta güçlü gürültü (scrape'te 13 Hz'lik pürüzle).
static func _add_note(out: PackedFloat32Array, sr: int, d: Dictionary, shape: Dictionary, prev_midi: float,
		rng: RandomNumberGenerator, detune: float = DETUNE_CENTS) -> void:
	var start := int(float(d["t"]) * sr)
	# Nota, sönüşü cümlenin içinde bitecek kadar sürer: Playlist cümleleri uç uca biner, sınırda ses kesilmez.
	var dur := minf(float(d["dur"]), float(out.size() - start) / sr - RELEASE_S)
	var length := mini(int((dur + RELEASE_S) * sr), out.size() - start)
	if length <= 0 or dur <= 0.0:
		return
	var hz := SynthDsp.midi_hz(float(d["midi"]))
	var from_cents := (prev_midi - float(d["midi"])) * 100.0 if prev_midi > 0.0 else 0.0
	var rate := VIBRATO_HZ + (rng.randf() - 0.5) * 0.3
	var vib_phase := rng.randf() * TAU
	var drift := rng.randf() * TAU
	var vib := float(shape["vib"])
	var fa := SynthDsp.control(length, sr, func(t: float) -> float:
		var depth := VIBRATO_CENTS * vib * _smooth01(VIBRATO_FROM, VIBRATO_FULL, t)
		var glide := from_cents * (1.0 - clampf(t / GLIDE_S, 0.0, 1.0))
		return hz * pow(2.0, (depth * sin(TAU * rate * t + vib_phase) + 2.0 * sin(TAU * 0.31 * t + drift) + glide) / 1200.0))
	var fb := SynthDsp.zeros(length)
	var up := SynthDsp.cents_ratio(detune)
	var down := SynthDsp.cents_ratio(-detune)
	for i in length:
		fb[i] = fa[i] * down
		fa[i] *= up
	var env := SynthDsp.control(length, sr, func(t: float) -> float:
		return envelope(t, dur) * (1.0 + 0.06 * sin(TAU * 0.4 * t - 1.2)))
	var tone := SynthDsp.zeros(length)
	SynthDsp.add_saw(tone, sr, fa, 0.5, rng.randf())
	SynthDsp.add_saw(tone, sr, fb, 0.5, rng.randf())
	var hiss := SynthDsp.zeros(length)
	SynthDsp.add_band(SynthDsp.white(length, rng), hiss, sr, float(shape["noise_hz"]), 1.4, 1.0)
	var noise := float(shape["noise"])
	var grind := float(shape["grind"])
	var vel := float(d["vel"])
	for i in length:
		var t := float(i) / sr
		var scratch := noise * (1.0 + 4.0 * exp(-t / 0.05)) * (1.0 - grind + grind * sin(TAU * 13.0 * t))
		out[start + i] += (tone[i] + hiss[i] * scratch) * env[i] * vel


static func _smooth01(a: float, b: float, x: float) -> float:
	var t := clampf((x - a) / (b - a), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
