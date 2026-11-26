class_name SynthKopuz
extends RefCounted
## Kopuz (K60; audio.md §2 «Kopuz sentezi», kopuz.md öneri 8): Karplus-Strong, nota başına bir tel; tam vuruşta üç tel
## (dış teller ±2 sent), teller arası 9 ms tarama (SynthSequencer.motor). Prototipin dombra.js'inden:
##   temel T60 D3'te 1,5 sn (üs 0,35), çekme konumu 0,08–0,13 (köprüye yakın), darbe yumuşaklığı down 0,10, up 0,42,
##   flick 0,05, mute 0,55; tırnak teması 2 ms ×0,30 (up'ta yok); gövde 210 Hz Q5 ×0,55, 480 Hz Q4 ×0,42,
##   1.150 Hz Q2,5 ×0,30; kuru pay 0,6, üst süzgeç 7,5 kHz; gövde vuruşu 210 Hz sinüs + 1,8 kHz bant ×0,35; slap
##   avuçla boğma; ezgi notasında −30…−60 sentten 40–70 ms kayma.
## 44,1 kHz'de kayıp süzgeci (0,25 0,5 0,25)'tir: 24 kHz'deki iki noktalı ortalamanın tiz sönümünü verir.
## «Üst kısmiler fazla parlak» çıkarsa (kulak onayı) TOP_HZ 6,2 kHz'e, 1.150 Hz tepesi ×0,2'ye iner.
##
## params (render): role "motor" (varsayılan; SynthSequencer.motor'un params'ı) ya da "note" (tek tel: midi, seconds,
## stroke, vel); rate (44100), gain_db.

const D3_HZ := 146.832
const T60_D3 := 1.5
const T60_EXP := 0.35
const PLUCK_MIN := 0.08
const PLUCK_MAX := 0.13
const SOFT := {"down": 0.10, "up": 0.42, "flick": 0.05, "mute": 0.55}
const NAIL_S := 0.002
const NAIL_GAIN := 0.30
## Gövde tepeleri: [Hz, Q, kazanç].
const BODY := [[210.0, 5.0, 0.55], [480.0, 4.0, 0.42], [1150.0, 2.5, 0.30]]
const DRY := 0.6
const TOP_HZ := 7500.0
## Avuçla bastırılmış tel (tension, erlik): kısa, boğuk.
const MUTE_T60 := 0.13
const MUTE_TOP_HZ := 2400.0
const MUTE_BODY_GAIN := 0.9
## Dış tellerin akort payı (sent): 3. tel −, 1. tel +.
const OUTER_DETUNE := 2.0
## Telin susturulması: aynı telde yeni nota gelince ve cümle sonunda.
const DAMP_S := 0.012
const END_DAMP_S := 0.03
## Çıkış düzeyi: tam vuruş ≈ −6 dBFS tepe.
const LEVEL := 0.3
## Gövde vuruşu ve slap süreleri (sn).
const TAP_S := 0.26
const SLAP_S := 0.12


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := int(params.get("rate", SynthDsp.RATE))
	var out: PackedFloat32Array
	if str(params.get("role", "motor")) == "note":
		out = render_note(int(params.get("midi", 50)), float(params.get("seconds", 2.0)), str(params.get("stroke", "flick")),
				float(params.get("vel", 1.0)), sr, rng)
	else:
		out = render_sequence(SynthSequencer.motor(params, rng), sr, rng)
	SynthDsp.scale_in_place(out, SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return out


## Olay listesini (SynthSequencer.motor) çalar: teller toplanır, gövde ve üst süzgeç bir kez uygulanır (doğrusal);
## bastırılmış teller ayrı, boğuk zincirden geçer; gövde vuruşları ve slap eklenir.
static func render_sequence(seq: Dictionary, sr: int, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(round(float(seq["length"]) * sr))
	var strings := SynthDsp.zeros(n)
	var muted := SynthDsp.zeros(n)
	var hits := SynthDsp.zeros(n)
	for note: Variant in seq["notes"]:
		var d: Dictionary = note
		var mute := str(d["stroke"]) == "mute"
		var start := int(float(d["t"]) * sr)
		var cut := int(float(d["dur"]) * sr)
		# Cümle sonunda biten tel sınırda susmuş olmalı; öbürü yeni notanın altında DAMP_S'de susar.
		var at_end := start + cut >= n - 1
		var damp := int((END_DAMP_S if at_end else DAMP_S) * sr)
		var length := mini(cut if at_end else cut + damp, n - start)
		if length <= 0:
			continue
		var buf := string_note(d, length, sr, rng)
		SynthDsp.release(buf, maxi(cut - damp, 0) if at_end else cut, damp)
		SynthDsp.mix_into(muted if mute else strings, buf, start)
	for tap: Variant in seq["taps"]:
		var d: Dictionary = tap
		SynthDsp.mix_into(hits, slap(float(d["vel"]), sr, rng) if str(d["kind"]) == "slap" else body_tap(float(d["vel"]), sr, rng),
				int(float(d["t"]) * sr))
	var out := body(strings, sr, TOP_HZ, float(BODY[0][2]))
	var muted_body := body(muted, sr, MUTE_TOP_HZ, MUTE_BODY_GAIN)
	for i in n:
		out[i] = (out[i] + muted_body[i] + hits[i]) * LEVEL
	return out


## Tek nota (T60 ve tını sınaması): bir tel, gövde ve üst süzgeçle.
static func render_note(midi: int, seconds: float, stroke: String, vel: float, sr: int, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(seconds * sr)
	var note := {"t": 0.0, "dur": seconds, "lane": 1, "midi": midi, "vel": vel, "stroke": stroke, "glide": 0.0, "glide_s": 0.0}
	var buf := string_note(note, n, sr, rng)
	var mute := stroke == "mute"
	var out := body(buf, sr, MUTE_TOP_HZ if mute else TOP_HZ, MUTE_BODY_GAIN if mute else float(BODY[0][2]))
	SynthDsp.scale_in_place(out, LEVEL)
	return out


## Bir telin titreşimi (gövdesiz): Karplus-Strong + tırnak teması + kayma. length örnek.
static func string_note(note: Dictionary, length: int, sr: int, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var stroke := str(note["stroke"])
	var midi := float(note["midi"])
	var lane := int(note["lane"])
	var detune := 0.0
	if stroke != "flick" and lane != 1:
		detune = -OUTER_DETUNE if lane == 0 else OUTER_DETUNE
	var hz := SynthDsp.midi_hz(midi) * SynthDsp.cents_ratio(detune)
	var mute := stroke == "mute"
	var t60 := MUTE_T60 if mute else T60_D3 * pow(D3_HZ / hz, T60_EXP)
	var soft: float = SOFT.get(stroke, 0.1)
	var pluck_pos := PLUCK_MIN + (PLUCK_MAX - PLUCK_MIN) * rng.randf()
	var vel := float(note["vel"])
	var buf := pluck(hz, length, sr, pluck_pos, t60, soft, rng)
	if stroke != "up":
		var nail := int(NAIL_S * sr)
		for i in mini(nail, length):
			buf[i] += (rng.randf() * 2.0 - 1.0) * NAIL_GAIN * (1.0 - float(i) / float(nail)) * (0.5 if mute else 1.0)
	var cents := float(note.get("glide", 0.0))
	if cents != 0.0:
		buf = SynthDsp.glide(buf, cents, float(note.get("glide_s", 0.05)), sr)
	SynthDsp.scale_in_place(buf, vel)
	return buf


## Karplus-Strong tel: süzülmüş gürültü darbesi gecikme hattına yüklenir; çekme konumu tarağı ilgili harmonikleri
## susturur; kayıp süzgeci (0,25 0,5 0,25) × periyot kazancı; kesir gecikme birinci derece tüm geçirenle.
static func pluck(hz: float, length: int, sr: int, pluck_pos: float, t60: float, soft: float, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var out := SynthDsp.zeros(length)
	var period := float(sr) / hz
	var loss_delay := 1.0
	var size := maxi(int(floor(period - loss_delay - 0.1)), 2)
	var frac := period - loss_delay - float(size)
	var c := (1.0 - frac) / (1.0 + frac)
	var rho := pow(10.0, -3.0 / (hz * t60))
	var line := SynthDsp.zeros(size)
	var lp := 0.0
	for i in size:
		lp += ((rng.randf() * 2.0 - 1.0) - lp) * (1.0 - soft)
		line[i] = lp
	var comb := maxi(1, int(round(pluck_pos * size)))
	for i in range(size - 1, comb - 1, -1):
		line[i] -= line[i - comb]
	var mean := 0.0
	for i in size:
		mean += line[i]
	mean /= size
	for i in size:
		line[i] -= mean
	var idx := 0
	var p1 := 0.0
	var p2 := 0.0
	var ap_x := 0.0
	var ap_y := 0.0
	for i in length:
		var x := line[idx]
		out[i] = x
		var lossy := rho * (0.25 * x + 0.5 * p1 + 0.25 * p2)
		p2 = p1
		p1 = x
		var y := c * lossy + ap_x - c * ap_y
		ap_x = lossy
		ap_y = y
		line[idx] = y
		idx += 1
		if idx == size:
			idx = 0
	return out


## Gövde: kuru pay + üç tepe; ardından tek kutuplu üst süzgeç. first_gain ilk tepenin (210 Hz) kazancıdır: açık telde
## 0,55, bastırılmış telde 0,9 (gövde boğuk tokluğu taşır).
static func body(strings: PackedFloat32Array, sr: int, top_hz: float, first_gain: float) -> PackedFloat32Array:
	var out := strings.duplicate()
	SynthDsp.scale_in_place(out, DRY)
	for i in BODY.size():
		var row: Array = BODY[i]
		SynthDsp.add_band(strings, out, sr, row[0], row[1], first_gain if i == 0 else float(row[2]))
	SynthDsp.lowpass1_in_place(out, top_hz, sr)
	return out


## Gövde vuruşu: 210 Hz sönümlü sinüs ve 1,8 kHz bant gürültüsü ×0,35.
static func body_tap(vel: float, sr: int, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(TAP_S * sr)
	var tone := SynthDsp.zeros(n)
	var noise := SynthDsp.zeros(n)
	for i in n:
		var t := float(i) / sr
		tone[i] = sin(TAU * 210.0 * t) * exp(-t / 0.045)
		noise[i] = (rng.randf() * 2.0 - 1.0) * exp(-t / 0.006)
	var out := tone.duplicate()
	SynthDsp.add_band(noise, out, sr, 1800.0, 1.2, 0.35)
	SynthDsp.scale_in_place(out, 0.8 * vel)
	return out


## Avuçla boğma (slap): avuç tellere ve göğse vurur, teller susar: kısa, boğuk, geniş bantlı tok ses.
static func slap(vel: float, sr: int, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var n := int(SLAP_S * sr)
	var out := SynthDsp.zeros(n)
	for i in n:
		var t := float(i) / sr
		out[i] = (rng.randf() * 2.0 - 1.0) * exp(-t / 0.012) * 0.6 + sin(TAU * 210.0 * t) * exp(-t / 0.03) * 0.5
	SynthDsp.lowpass1_in_place(out, 1500.0, sr)
	SynthDsp.scale_in_place(out, vel)
	return out
