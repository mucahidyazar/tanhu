class_name SynthSnow
extends RefCounted
## Savrulan kar döngüsü `snow_drift` (audio.md §4 «Ortam döngüleri», act1.md §14: Kışlak'ın «kar»ı): rüzgârın kaldırdığı kar tanelerinin kabuğa
## sürtünmesi: kabaran tiz tıslama (2,5–7 kHz, gezinen bant), bora kabardıkça sıklaşan ince kristal tıkırtıları (yüksek geçiren) ve çok hafif
## alçak gövde. Bora zarfı periyodiktir, kuyruk başa eşit güçte katlanır: döngü noktası duyulmaz. Ortam döngüsü: 22,05 kHz mono QOA. Kazancı
## havanın karı ve rüzgârı verir (MapSoundscape).
## params: seconds (döngü), fold (sn), rate (22050), gain_db.

const HISS_SWEEP := Vector2(2500.0, 6500.0)
const TICK_RATE := 34.0
const RMS := 0.1
const CONTROL_BLOCK := 32


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := int(params.get("rate", 22050))
	var loop_n := int(float(params.get("seconds", 16.0)) * sr)
	var fade_n := int(float(params.get("fold", 2.0)) * sr)
	var n := loop_n + fade_n
	var gust := SynthDsp.periodic(SynthDsp.anchors(8, 0.25, 1.0, rng), n, loop_n)
	var hz := SynthDsp.periodic(SynthDsp.anchors(7, HISS_SWEEP.x, HISS_SWEEP.y, rng), n, loop_n)
	var hiss := SynthDsp.zeros(n)
	SynthDsp.add_sweep(SynthDsp.pink(n, rng), hiss, sr, SynthDsp.decimate(hz, CONTROL_BLOCK), CONTROL_BLOCK, 0.9, 1.0)
	var out := SynthDsp.zeros(n)
	for i in n:
		out[i] = hiss[i] * gust[i] * gust[i]
	# Kristal tıkırtıları: boranın karesiyle sıklaşır.
	var ticks := SynthDsp.zeros(n)
	var p := TICK_RATE / sr
	for i in n:
		if rng.randf() < p * gust[i] * gust[i] * 1.6:
			var amp := rng.randf_range(0.2, 1.0)
			for k in mini(int(0.004 * sr), n - i):
				ticks[i + k] += (rng.randf() * 2.0 - 1.0) * amp * exp(-float(k) / (0.0008 * sr))
	SynthDsp.highpass1_in_place(ticks, 4000.0, sr)
	for i in n:
		out[i] += ticks[i] * 0.35
	var body := SynthDsp.zeros(n)
	SynthDsp.add_band(SynthDsp.pink(n, rng), body, sr, 320.0, 0.7, 1.0)
	for i in n:
		out[i] += body[i] * 0.08 * gust[i]
	var looped := SynthDsp.fold_loop(out, loop_n, fade_n, true)
	var r := SynthDsp.rms(looped)
	if r > 0.0:
		SynthDsp.scale_in_place(looped, RMS / r * SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return looped
