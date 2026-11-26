class_name SynthHoof
extends RefCounted
## Toynak vuruşu `hoof` (audio.md §4 «Hayvan»; kampın atı, RideEffects): bozkırın sıkışık toprağına basan nalsız toynak. Üç katman: kısa, alçak bir
## gümleme (toprağın tokluğu: 110–145 Hz'den %60'ına inen sinüs, ≈20 ms sönüm), kuru bir tok (toynağın duvarı: 700–1.200 Hz bant gürültüsü, ≈14 ms)
## ve savrulan toprak (3,6 kHz çevresinde bant gürültüsü, ≈35 ms, birkaç ms gecikmeli). Çeşit tohumdan: gümlemenin perdesi, tokun bandı ve toprağın payı değişir; oyunda
## AudioStreamRandomizer perdeyi ve yüksekliği ayrıca oynatır. Dış mekân: yansıma yok.
## params: seconds (0,26), rate (22050), thump_hz (yoksa tohumla 110–145), clop_hz (yoksa 700–1.200), dirt (0..1; yoksa 0,35–0,6), gain_db.
## Sıçramanın inişi (hoof_land_*, 2026-11-08; RideEffects): ağır gümleme için isteğe bağlı alanlar, verilmezse ses eskisiyle aynıdır (tohum aynı akar):
## decay_s gümlemenin sönümü (0,02), dirt_s toprağın sönümü (0,035), body_hz ve body_s gövdenin alçak sarsıntısı (0 = yok), body_gain, echo_s ve echo_gain
## ikinci toynağın aynı vuruşu (çift ön toynak; 0 = yok).

const LEVEL := 0.6


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := int(params.get("rate", 22050))
	var n := int(float(params.get("seconds", 0.26)) * sr)
	var thump_hz := float(params.get("thump_hz", 110.0 + rng.randf() * 35.0))
	var clop_hz := float(params.get("clop_hz", 700.0 + rng.randf() * 500.0))
	var dirt := float(params.get("dirt", 0.35 + rng.randf() * 0.25))
	var decay := float(params.get("decay_s", 0.02))
	var dirt_s := float(params.get("dirt_s", 0.035))
	var out := SynthDsp.zeros(n)
	# Gümleme: perdesi hızla iner, sönümü kısa.
	var phase := 0.0
	for i in n:
		var t := float(i) / sr
		var hz := lerpf(thump_hz, thump_hz * 0.6, clampf(t / 0.04, 0.0, 1.0))
		phase += TAU * hz / sr
		out[i] += sin(phase) * 0.8 * exp(-t / decay) * clampf(t / 0.0015, 0.0, 1.0)
	# Tok: kısa bant gürültüsü.
	var noise := SynthDsp.white(n, rng)
	var clop := SynthDsp.zeros(n)
	SynthDsp.add_band(noise, clop, sr, clop_hz, 1.4, 1.0)
	SynthDsp.add_band(noise, clop, sr, clop_hz * 1.9, 2.2, 0.45)
	for i in n:
		var t := float(i) / sr
		out[i] += clop[i] * 1.1 * exp(-t / 0.014) * clampf(t / 0.0008, 0.0, 1.0)
	# Toprak: gecikmeli, tiz, dağınık (birkaç küçük tane).
	var grit := SynthDsp.white(n, rng)
	var dust := SynthDsp.zeros(n)
	SynthDsp.add_band(grit, dust, sr, 3600.0, 0.7, 1.0)
	var delay := 0.004 + rng.randf() * 0.004
	for i in n:
		var t := float(i) / sr - delay
		if t < 0.0:
			continue
		var grains := 0.6 + 0.4 * sin(TAU * 37.0 * t + rng.randf() * 0.3)
		out[i] += dust[i] * dirt * 0.5 * exp(-t / dirt_s) * grains
	# İnişin ağırlığı: gövdenin alçak sarsıntısı (perdesi biraz iner) ve ikinci ön toynağın aynı vuruşu.
	var body_hz := float(params.get("body_hz", 0.0))
	if body_hz > 0.0:
		var body_s := float(params.get("body_s", 0.08))
		var body_gain := float(params.get("body_gain", 0.5))
		var body_phase := 0.0
		for i in n:
			var t := float(i) / sr
			body_phase += TAU * lerpf(body_hz, body_hz * 0.8, clampf(t / 0.12, 0.0, 1.0)) / sr
			out[i] += sin(body_phase) * body_gain * exp(-t / body_s) * clampf(t / 0.004, 0.0, 1.0)
	var echo := int(float(params.get("echo_s", 0.0)) * sr)
	if echo > 0:
		var first := out.duplicate()
		SynthDsp.mix_into(out, first.slice(0, n - echo), echo, float(params.get("echo_gain", 0.7)))
	SynthDsp.highpass1_in_place(out, 40.0, sr)
	SynthDsp.fade_edges(out, 0, int(0.03 * sr))
	var peak := SynthDsp.peak(out)
	if peak > 0.0:
		SynthDsp.scale_in_place(out, LEVEL / peak * SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return out
