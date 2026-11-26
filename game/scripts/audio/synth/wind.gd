class_name SynthWind
extends RefCounted
## Bozkır rüzgârı döngüsü (audio.md §4 «Ortam döngüleri» wind_steppe; prototipin ambience.js'i): süzülmüş gürültü
## katmanları, gövde ve orta bant gezinir (bora), seyrek ıslık; 4 kHz alçak geçiren. Ortam döngüsüdür: 22,05 kHz
## mono, QOA içe aktarılır, bütün dosya döner (audio-import kuralı). Gezinme eğrileri periyodiktir, kuyruk başa
## eşit güçte katlanır: döngü noktası duyulmaz. Önsöz'de alçak sessizlikte −40 dB, kara sessizlikte −60 dB kuyruktur.
## params: seconds (döngü), fold (sn), rate (22050), gain_db, top_hz (alçak geçiren; 4.000), rms (düzey); bands (ya da eski adıyla layers) verilmezse
## STEPPE. Kışlak'ın döngüleri bands ile basılır (act-1-p2): wind_winter, blizzard, wind_gale ve Yol Kemiği'nin dar bantlı uğultusu bone_hum.

## Katmanlar: f (Hz), q, [f_lo, f_hi] (merkezin gezinmesi; yoksa sabit), [g_lo, g_hi] (kazancın gezinmesi),
## noktalar (gezinme noktası sayısı).
const STEPPE := [
	{"f": 380.0, "q": 0.6, "gain": [0.45, 1.0], "points": 7},
	{"f": 1100.0, "q": 1.4, "sweep": [800.0, 1500.0], "gain": [0.1, 0.5], "points": 9},
	{"f": 1800.0, "q": 9.0, "sweep": [1500.0, 2100.0], "gain": [0.0, 0.12], "points": 8},
]
const TOP_HZ := 4000.0
const WIND_RMS := 0.12
const CONTROL_BLOCK := 32


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := int(params.get("rate", 22050))
	var loop_n := int(float(params.get("seconds", 24.0)) * sr)
	var fade_n := int(float(params.get("fold", 2.0)) * sr)
	var n := loop_n + fade_n
	var layers: Array = params["bands"] if params.get("bands") is Array else (params["layers"] if params.get("layers") is Array else STEPPE)
	var out := SynthDsp.zeros(n)
	for layer: Variant in layers:
		var spec: Dictionary = layer
		var noise := SynthDsp.white(n, rng)
		var band := SynthDsp.zeros(n)
		var points := int(spec.get("points", 7))
		if spec.get("sweep") is Array:
			var sweep: Array = spec["sweep"]
			var hz := SynthDsp.periodic(SynthDsp.anchors(maxi(points - 2, 3), float(sweep[0]), float(sweep[1]), rng), n, loop_n)
			SynthDsp.add_sweep(noise, band, sr, SynthDsp.decimate(hz, CONTROL_BLOCK), CONTROL_BLOCK, float(spec["q"]), 1.0)
		else:
			SynthDsp.add_band(noise, band, sr, float(spec["f"]), float(spec["q"]), 1.0)
		var g: Array = spec["gain"]
		var gain := SynthDsp.periodic(SynthDsp.anchors(points, float(g[0]), float(g[1]), rng), n, loop_n)
		for i in n:
			out[i] += band[i] * gain[i]
	SynthDsp.biquad_in_place(out, SynthDsp.biquad_coeffs("lowpass", minf(float(params.get("top_hz", TOP_HZ)), sr * 0.45), 0.7, sr))
	var looped := SynthDsp.fold_loop(out, loop_n, fade_n, true)
	var r := SynthDsp.rms(looped)
	if r > 0.0:
		SynthDsp.scale_in_place(looped, float(params.get("rms", WIND_RMS)) / r * SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return looped
