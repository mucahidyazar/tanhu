class_name SynthNotch
extends RefCounted
## Sayımın tıkı `notch` (audio.md §3 «Perde rengi», §4: «sayıcının çentiği notch'tur»): sayıcı bıçakla tahta çubuğa
## çentik atar (Önsöz 3:22,0). Sayılan sayan olur (K32): I. Perde'de çentik ölçüyü tutar, VI'da her baş bir tıktır.
## Çentik iki kesiktir: önce bıçağın ağzı tahtaya vurur (kuru, kısa tık: 1,9 ve 3,4 kHz tepeleri, 750 Hz tahta gövdesi),
## sonra bıçak lifleri sıyırır (2–5 kHz bant gürültüsü, ≈70 ms); ikinci kesik ilkinden biraz kısıktır, sonunda küçük bir
## yonga düşer. Dış mekân: yansıma yok, kuru.
## params: cuts ([[sn, kuvvet], ...]; yoksa CUTS), seconds, rate (32000: tiz atak), gain_db.

## Kesikler: [başlangıç sn, kuvvet].
const CUTS := [[0.03, 1.0], [0.26, 0.82]]
## Tahtanın tepeleri: [Hz, sönüm sn, kazanç].
const MODES := [[1900.0, 0.018, 1.0], [3400.0, 0.01, 0.55], [750.0, 0.03, 0.6]]
const SCRAPE_HZ := 3200.0
const SCRAPE_S := 0.07
const LEVEL := 0.55


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := int(params.get("rate", 32000))
	var n := int(float(params.get("seconds", 0.6)) * sr)
	var cuts: Array = params["cuts"] if params.get("cuts") is Array else CUTS
	var out := SynthDsp.zeros(n)
	for c: Variant in cuts:
		var row: Array = c
		_add_cut(out, sr, float(row[0]), float(row[1]), rng)
	# Yonga: son kesikten sonra küçük, yumuşak bir tık.
	var last: Array = cuts[cuts.size() - 1] if not cuts.is_empty() else [0.0, 1.0]
	_add_tick(out, sr, float(last[0]) + 0.12, 0.18, 1.4, rng)
	SynthDsp.highpass1_in_place(out, 180.0, sr)
	SynthDsp.fade_edges(out, 0, int(0.03 * sr))
	var peak := SynthDsp.peak(out)
	if peak > 0.0:
		SynthDsp.scale_in_place(out, LEVEL / peak * SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return out


## Kesik: bıçağın tahtaya vuruşu (tık) ve lifleri sıyırması (bant gürültüsü, yükselip sönen).
static func _add_cut(out: PackedFloat32Array, sr: int, at: float, vel: float, rng: RandomNumberGenerator) -> void:
	_add_tick(out, sr, at, vel, 1.0, rng)
	var start := int((at + 0.006) * sr)
	var length := mini(int(SCRAPE_S * sr), out.size() - start)
	if length <= 0:
		return
	var noise := SynthDsp.white(length, rng)
	var band := SynthDsp.zeros(length)
	SynthDsp.add_band(noise, band, sr, SCRAPE_HZ * (0.9 + 0.2 * rng.randf()), 1.6, 1.0)
	for i in length:
		var u := float(i) / length
		var env := sin(PI * u) * (1.0 - 0.5 * u)
		# Lif lif: sıyırmanın içinde hızlı küçük takılmalar.
		var grain := 0.6 + 0.4 * absf(sin(TAU * 140.0 * float(i) / sr + rng.randf() * 0.3))
		out[start + i] += band[i] * env * grain * 0.5 * vel


## Tık: tahtanın tepelerinde sönümlü sinüsler ve kısa gürültü darbesi; pitch tepeleri kaydırır (yonga daha tizdir).
static func _add_tick(out: PackedFloat32Array, sr: int, at: float, vel: float, pitch: float, rng: RandomNumberGenerator) -> void:
	var start := int(at * sr)
	var length := mini(int(0.06 * sr), out.size() - start)
	if length <= 0:
		return
	var phases := PackedFloat32Array()
	for m in MODES.size():
		phases.append(rng.randf() * TAU)
	for i in length:
		var t := float(i) / sr
		var s := 0.0
		for m in MODES.size():
			var mode: Array = MODES[m]
			s += sin(TAU * float(mode[0]) * pitch * t + phases[m]) * exp(-t / float(mode[1])) * float(mode[2])
		s += (rng.randf() * 2.0 - 1.0) * exp(-t / 0.0015) * 0.8
		out[start + i] += s * vel
