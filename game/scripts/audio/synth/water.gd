class_name SynthWater
extends RefCounted
## Sazlık su döngüsü `water_reed` (audio.md §4 «Ortam döngüleri»; prototipin ambience.js water_reed'i): kıyıya vuran
## dalgacık (700 Hz alçak geçirenli gürültü, kazancı yavaş gezinir), tek tük kabarcık (400–600 Hz'den 900–1.200 Hz'e
## 30 ms'lik çırpı) ve saz hışırtısı (3,2 kHz bant, gezinen kazanç). Mit sinemasının ilk panosunda «önce su vardı».
## Ortam döngüsüdür: 22,05 kHz mono, QOA içe aktarılır, bütün dosya döner (audio-import kuralı). Gezinme eğrileri
## periyodiktir, kabarcıklar döngünün ortasındadır, kuyruk başa eşit güçte katlanır: döngü noktası duyulmaz.
## params: seconds (döngü, 16), fold (sn), rate (22050), gain_db.

const LAP_HZ := 700.0
const REED_HZ := 3200.0
const WATER_RMS := 0.1
const CONTROL_BLOCK := 32


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := int(params.get("rate", 22050))
	var loop_n := int(float(params.get("seconds", 16.0)) * sr)
	var fade_n := int(float(params.get("fold", 2.0)) * sr)
	var n := loop_n + fade_n
	var out := SynthDsp.zeros(n)
	# Dalgacık: alçak geçirenli gürültü, kazancı 24 noktada 0,1–1 arasında gezinir.
	var lap := SynthDsp.biquad(SynthDsp.white(n, rng), SynthDsp.biquad_coeffs("lowpass", LAP_HZ, 0.7, sr))
	var lap_gain := SynthDsp.periodic(SynthDsp.anchors(24, 0.1, 1.0, rng), n, loop_n)
	# Saz: 3,2 kHz bant, kazancı 8 noktada 0,05–0,3.
	var reed := SynthDsp.zeros(n)
	SynthDsp.add_band(SynthDsp.white(n, rng), reed, sr, REED_HZ, 0.8, 1.0)
	var reed_gain := SynthDsp.periodic(SynthDsp.anchors(8, 0.05, 0.3, rng), n, loop_n)
	for i in n:
		out[i] = lap[i] * lap_gain[i] + reed[i] * reed_gain[i]
	# Kabarcıklar: 0,4–1,8 sn arayla, döngünün kenarlarından uzakta (katlama bölgesinde kabarcık yok).
	var fold_s := float(fade_n) / sr
	var loop_s := float(loop_n) / sr
	var t := fold_s + rng.randf()
	while t < loop_s - 0.3:
		_add_bubble(out, sr, t, 400.0 + rng.randf() * 200.0, 900.0 + rng.randf() * 300.0, rng)
		t += 0.4 + rng.randf() * 1.4
	var looped := SynthDsp.fold_loop(out, loop_n, fade_n, true)
	var r := SynthDsp.rms(looped)
	if r > 0.0:
		SynthDsp.scale_in_place(looped, WATER_RMS / r * SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return looped


## Kabarcık: 30 ms'de yükselen sinüs çırpısı, 2 ms'de açılır, 30 ms'de söner.
static func _add_bubble(out: PackedFloat32Array, sr: int, at: float, f0: float, f1: float, rng: RandomNumberGenerator) -> void:
	var start := int(at * sr)
	var length := mini(int(0.07 * sr), out.size() - start)
	var ph := rng.randf()
	var amp := 0.12 + rng.randf() * 0.06
	for i in length:
		var u := float(i) / sr
		var hz := f0 + (f1 - f0) * clampf(u / 0.03, 0.0, 1.0)
		ph += hz / sr
		var env := clampf(u / 0.002, 0.0, 1.0) * exp(-u / 0.03)
		out[start + i] += sin(TAU * ph) * env * amp
