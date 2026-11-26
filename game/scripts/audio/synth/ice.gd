class_name SynthIce
extends RefCounted
## Buzun inlemesi `ice_groan` (audio.md §4 «Ortam döngüleri», «Ortamın saati»: Kışlak'ta Tan ve Gece; act1.md §4 Buz Kolu: «buz inler, sis»): donan
## ırmağın uzaktan duyulan sesleri. Döngüde üç olay: buzda yayılan gerilimin «piyuv»u (dağılan cıvıltı: tizden pese hızla kayan, gecikmeli
## kısmiler), alçak inilti (55–80 Hz testere, 250 Hz alçak geçiren, kabarıp söner) ve kısa çatırtı; altta çok hafif alçak uğultu. Olaylar
## döngünün içindedir, taban uğultusu periyodik ve katlanmıştır: döngü noktası duyulmaz. Ortam döngüsü: 22,05 kHz mono QOA.
## params: seconds (döngü), fold (sn), events ([[sn, "pew" | "groan" | "crack", kuvvet], ...]; yoksa EVENTS), rate (22050), gain_db.

const EVENTS := [[2.6, "pew", 0.9], [6.0, "groan", 0.8], [11.2, "crack", 0.6], [12.0, "pew", 0.55], [15.5, "groan", 0.6]]
const PEAK := 0.55


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := int(params.get("rate", 22050))
	var loop_n := int(float(params.get("seconds", 20.0)) * sr)
	var fade_n := int(float(params.get("fold", 2.0)) * sr)
	var n := loop_n + fade_n
	var base := SynthDsp.zeros(n)
	SynthDsp.add_band(SynthDsp.pink(n, rng), base, sr, 70.0, 0.8, 1.0)
	var swell := SynthDsp.periodic(SynthDsp.anchors(5, 0.4, 1.0, rng), n, loop_n)
	for i in n:
		base[i] *= 0.05 * swell[i]
	var looped := SynthDsp.fold_loop(base, loop_n, fade_n, true)
	var events: Array = params["events"] if params.get("events") is Array else EVENTS
	for e: Variant in events:
		var row: Array = e
		var at := int(float(row[0]) * sr)
		match str(row[1]):
			"pew":
				_pew(looped, sr, at, float(row[2]), rng)
			"groan":
				_groan(looped, sr, at, float(row[2]), rng)
			"crack":
				_crack(looped, sr, at, float(row[2]), rng)
	SynthDsp.highpass1_in_place(looped, 30.0, sr)
	var peak := SynthDsp.peak(looped)
	if peak > 0.0:
		SynthDsp.scale_in_place(looped, PEAK / peak * SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return looped


## Dağılan cıvıltı: buzda yayılan dalganın yüksek frekansı önce gelir; üç kısmi biraz geç ve kısık.
static func _pew(out: PackedFloat32Array, sr: int, at: int, vel: float, rng: RandomNumberGenerator) -> void:
	for k in 3:
		var delay := int((0.015 * k + rng.randf() * 0.01) * sr)
		var length := mini(int(0.7 * sr), out.size() - at - delay)
		if length <= 0:
			continue
		var ph := 0.0
		var f_hi := 2400.0 * (1.0 - 0.12 * k)
		var f_lo := 320.0 * (1.0 + 0.1 * k)
		for i in length:
			var t := float(i) / sr
			var hz := f_lo + (f_hi - f_lo) * exp(-t / 0.09)
			ph += hz / sr
			out[at + delay + i] += sin(TAU * ph) * exp(-t / 0.22) * vel * (0.5 / (1.0 + k))


## Alçak inilti: kabarıp sönen alçak testere, buzun gövdesi.
static func _groan(out: PackedFloat32Array, sr: int, at: int, vel: float, rng: RandomNumberGenerator) -> void:
	var length := mini(int(1.8 * sr), out.size() - at)
	if length <= 0:
		return
	var freq := SynthDsp.control(length, sr, func(t: float) -> float: return 78.0 - 20.0 * smoothstep(0.0, 1.6, t) + 3.0 * sin(TAU * 1.3 * t))
	var tone := SynthDsp.zeros(length)
	SynthDsp.add_saw(tone, sr, freq, 1.0, rng.randf())
	var lp := SynthDsp.biquad_coeffs("lowpass", 250.0, 0.9, sr)
	SynthDsp.biquad_in_place(tone, lp)
	for i in length:
		var t := float(i) / sr
		var env := smoothstep(0.0, 0.5, t) * exp(-maxf(t - 0.5, 0.0) / 0.45)
		out[at + i] += tone[i] * env * vel * 0.6


## Kısa çatırtı: bant geçiren gürültü patlaması ve iki küçük yankı.
static func _crack(out: PackedFloat32Array, sr: int, at: int, vel: float, rng: RandomNumberGenerator) -> void:
	var length := mini(int(0.25 * sr), out.size() - at)
	if length <= 0:
		return
	var burst := SynthDsp.zeros(length)
	for i in length:
		burst[i] = (rng.randf() * 2.0 - 1.0) * exp(-float(i) / (0.02 * sr))
	var band := SynthDsp.zeros(length)
	SynthDsp.add_band(burst, band, sr, 1500.0, 1.0, 1.0)
	SynthDsp.mix_into(out, band, at, vel * 0.7)
	SynthDsp.mix_into(out, band, at + int(0.06 * sr), vel * 0.25)
	SynthDsp.mix_into(out, band, at + int(0.13 * sr), vel * 0.12)
