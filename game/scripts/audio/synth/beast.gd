class_name SynthBeast
extends RefCounted
## Hayvan sesi (audio.md §4 «Hayvan sesleri», ses-tasarimi.md §7.1–§7.2; K61, K65; Yol Haritası fauna-sound-bank): kaynak-süzgeç sentezi.
## Memeli ve kuş sesi gırtlak (ya da şırınks) kaynağı + ağız ve burun biçimlendiricileridir: kaynak bant sınırlı testere ya da üçgen, temel
## perde eğrisi (üstel ara değer), titreşim ve sapma (iki yavaş LFO, sent), soluk gürültüsü, hırıltı (genlik kıpırtısı: devenin gurultusu,
## domuzun hırıltısı), titrek (koyunun 13 Hz'i); biçimlendiriciler sabit ya da zamanla kayan (ağzın açılışı: «möö»); at kişnemesinde ikinci
## bağımsız kaynak G0 (Briefer 2015: F0 ≈300–500 Hz, G0 1,2–1,9 kHz), havlama ve hırlamada gürültü patlaması. Prototipin sfx.js k.voiced'ının
## taşınmasıdır (aynı alan adları: f0, amp, formants, vib, vib_rate, breath, jitter). Dış mekân: kuru basılır, uzaklığı oyunun 3B sesi verir.
##
## params (tarif; data/audio/bake/fauna_*.json):
##   seconds (dosyanın boyu), rate (16000 deve/sığır/eşek, 22050 çoğu, 32000 kuş ve tarbagan ıslığı), gain_db, highpass, lowpass (Hz),
##   calls: [{t (sn), f0: [[sn, Hz], ...], amp: [[sn, 0..1], ...], type ("saw" | "tri" | "noise"), formants: [[Hz, Q, kazanç], ...],
##            sweep: [[sn, çarpan], ...] (biçimlendiricilerin zamanla kayması), vib (sent), vib_rate (Hz), jitter (sent), breath (0..1),
##            growl (0..1), growl_rate (Hz), trem (0..1), trem_rate (Hz), g0: [[sn, Hz], ...], g0_gain, burst (0..1: gürültü patlaması),
##            burst_hz, burst_q, gain}]
## Aynı tohum aynı örnekleri verir.

const LEVEL := 0.62
const CONTROL_BLOCK := 16
const DRY := 0.06


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := int(params.get("rate", 22050))
	var n := int(float(params.get("seconds", 1.0)) * sr)
	var out := SynthDsp.zeros(n)
	for c: Variant in params.get("calls", []):
		if c is Dictionary:
			_add_call(out, sr, c, rng)
	var hp := float(params.get("highpass", 60.0))
	if hp > 0.0:
		SynthDsp.biquad_in_place(out, SynthDsp.biquad_coeffs("highpass", hp, 0.7, sr))
	var lp := float(params.get("lowpass", 0.0))
	if lp > 0.0:
		SynthDsp.biquad_in_place(out, SynthDsp.biquad_coeffs("lowpass", minf(lp, sr * 0.45), 0.7, sr))
	SynthDsp.fade_edges(out, int(0.003 * sr), int(0.04 * sr))
	var peak := SynthDsp.peak(out)
	if peak > 0.0:
		SynthDsp.scale_in_place(out, LEVEL / peak * SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return out


## Tek çağrı: kaynak (perde eğrisi, titreşim, sapma; testere ya da üçgen), soluk ve patlama gürültüsü, hırıltı ve titrek, zarf; biçimlendirici
## bankası (sabit ya da kayan); G0 ayrı ince bileşendir.
static func _add_call(out: PackedFloat32Array, sr: int, c: Dictionary, rng: RandomNumberGenerator) -> void:
	var t0 := float(c.get("t", 0.0))
	var amp_pts: Array = c.get("amp", [[0.0, 0.0], [0.05, 1.0], [0.4, 0.0]])
	var length_s := float((amp_pts[amp_pts.size() - 1] as Array)[0]) + 0.03
	var start := int(t0 * sr)
	var length := mini(int(length_s * sr), out.size() - start)
	if length <= 0:
		return
	var f0_pts: Array = c.get("f0", [[0.0, 300.0]])
	var vib := float(c.get("vib", 0.0))
	var vib_rate := float(c.get("vib_rate", 5.5))
	var jitter := float(c.get("jitter", 6.0))
	var j1 := 11.3 + rng.randf() * 4.0
	var j2 := 5.1 + rng.randf() * 2.0
	var ph1 := rng.randf() * TAU
	var ph2 := rng.randf() * TAU
	var freq := SynthDsp.control(length, sr, func(t: float) -> float:
		var cents := vib * sin(TAU * vib_rate * t) + jitter * sin(TAU * j1 * t + ph1) + jitter * 0.7 * (absf(fmod(j2 * t + ph2, 1.0) * 4.0 - 2.0) - 1.0)
		return minf(curve_exp(f0_pts, t) * pow(2.0, cents / 1200.0), sr * 0.45), CONTROL_BLOCK)
	var env := SynthDsp.control(length, sr, func(t: float) -> float: return curve_lin(amp_pts, t), CONTROL_BLOCK)
	var src := SynthDsp.zeros(length)
	var type := str(c.get("type", "saw"))
	if type == "tri":
		var ph := rng.randf()
		for i in length:
			ph += freq[i] / sr
			ph -= floorf(ph)
			src[i] = 1.0 - 4.0 * absf(ph - 0.5)
	elif type == "saw":
		SynthDsp.add_saw(src, sr, freq, 1.0, rng.randf())
	var noise := SynthDsp.white(length, rng)
	var breath := float(c.get("breath", 0.15))
	var growl := float(c.get("growl", 0.0))
	var growl_rate := float(c.get("growl_rate", 24.0))
	var trem := float(c.get("trem", 0.0))
	var trem_rate := float(c.get("trem_rate", 13.0))
	var gph := rng.randf() * TAU
	for i in length:
		var t := float(i) / sr
		var k := 1.0
		if growl > 0.0:
			# Gurultu: kıpırtının hızı da kıpırdar (düz bir titrek gibi duyulmasın).
			var rate := growl_rate * (1.0 + 0.18 * sin(TAU * 1.7 * t + gph))
			k *= 1.0 - growl * (0.5 + 0.5 * sin(TAU * rate * t + gph))
		if trem > 0.0:
			k *= 1.0 - trem * (0.5 + 0.5 * sin(TAU * trem_rate * t))
		src[i] = (src[i] * (1.0 if type != "noise" else 0.0) + noise[i] * breath) * env[i] * k
	var shaped := SynthDsp.zeros(length)
	var formants: Array = c.get("formants", [[800.0, 4.0, 1.0]])
	var sweep: Array = c.get("sweep", [])
	for f: Variant in formants:
		var row: Array = f
		if sweep.is_empty():
			SynthDsp.add_band(src, shaped, sr, float(row[0]), float(row[1]), float(row[2]))
		else:
			var base := float(row[0])
			var curve := SynthDsp.zeros(int(ceil(float(length) / CONTROL_BLOCK)) + 1)
			for b in curve.size():
				curve[b] = minf(base * curve_lin(sweep, float(b * CONTROL_BLOCK) / sr), sr * 0.45)
			SynthDsp.add_sweep(src, shaped, sr, curve, CONTROL_BLOCK, float(row[1]), float(row[2]))
	for i in length:
		shaped[i] += src[i] * DRY
	# Patlama: havlamanın ve hırlamanın gürültülü başı (bant geçiren, hızlı sönüm).
	var burst := float(c.get("burst", 0.0))
	if burst > 0.0:
		var bn := SynthDsp.zeros(length)
		var bhz := float(c.get("burst_hz", 1200.0))
		for i in length:
			bn[i] = noise[i] * exp(-float(i) / (0.035 * sr)) * env[i]
		SynthDsp.add_band(bn, shaped, sr, bhz, float(c.get("burst_q", 1.2)), burst)
	# İkinci kaynak (at kişnemesinin G0'ı): ince, kendi eğrisiyle; birinci kaynağın zarfını izler.
	var g0: Array = c.get("g0", [])
	if not g0.is_empty():
		var gg := float(c.get("g0_gain", 0.2))
		var gph2 := rng.randf()
		var gfreq := SynthDsp.control(length, sr, func(t: float) -> float:
			return minf(curve_exp(g0, t) * pow(2.0, (vib * 0.6 * sin(TAU * vib_rate * 1.1 * t + 0.7)) / 1200.0), sr * 0.45), CONTROL_BLOCK)
		for i in length:
			gph2 += gfreq[i] / sr
			gph2 -= floorf(gph2)
			var s := sin(TAU * gph2)
			shaped[i] += (s + 0.25 * sin(TAU * gph2 * 2.0)) * env[i] * gg
	SynthDsp.mix_into(out, shaped, start, float(c.get("gain", 1.0)))


## Noktalar arası üstel ara değer (perde): [[sn, Hz], ...]; ilk noktadan önce ilk, sondan sonra son değer.
static func curve_exp(points: Array, t: float) -> float:
	if points.is_empty():
		return 0.0
	var first: Array = points[0]
	if t <= float(first[0]) or points.size() == 1:
		return float(first[1])
	for k in range(1, points.size()):
		var b: Array = points[k]
		if t <= float(b[0]):
			var a: Array = points[k - 1]
			var u := (t - float(a[0])) / maxf(float(b[0]) - float(a[0]), 1e-6)
			return float(a[1]) * pow(float(b[1]) / maxf(float(a[1]), 1e-6), u)
	return float((points[points.size() - 1] as Array)[1])


## Noktalar arası doğrusal ara değer (zarf, kayma çarpanı).
static func curve_lin(points: Array, t: float) -> float:
	if points.is_empty():
		return 0.0
	var first: Array = points[0]
	if t <= float(first[0]) or points.size() == 1:
		return float(first[1])
	for k in range(1, points.size()):
		var b: Array = points[k]
		if t <= float(b[0]):
			var a: Array = points[k - 1]
			var u := (t - float(a[0])) / maxf(float(b[0]) - float(a[0]), 1e-6)
			return lerpf(float(a[1]), float(b[1]), u)
	return float((points[points.size() - 1] as Array)[1])
