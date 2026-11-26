class_name SynthLakeBull
extends RefCounted
## Göl boğası `lake_bull` (weather.md §10.2, K35, mitoloji.md öneri 13): göllü dünyada (ana kamp) gök gürültülü fırtınadan ya da
## fırtına cephesinden bir saat önce gölün üstünden gelen uzak, alçak böğürtü. 70–110 Hz arasında gezinen testere (yükselir, tepede
## durur, iner) ve aynı zarfla soluyan gürültü; boğazın «u» rengi 220 Hz'de dar bir bant; alçak geçiren 400 Hz (iki kat, uzak);
## gölün karşı kıyısından tek yansıma (0,34 sn) ve uzun yankı (Schroeder: dört tarak, iki tümgeçiren; T60 ≈ 2,4 sn). Yankı kuru
## sesten güçlüdür (tarakların kazancı): ses uzaktan, yankının içinden gelir. Söz yoktur; kulak onayı kullanıcınındır.
## params: seconds (3), rate (22050), seed, gain_db.

const LEVEL := 0.5
## Böğürtünün zamanları (sn): başlangıç, yükselişin sonu, iniş başı, sonu.
const T_ON := 0.12
const T_RISE := 0.45
const T_FALL := 1.25
const T_OFF := 1.95
## Yankı: tarak gecikmeleri (sn), tümgeçirenler (sn), T60 (sn), sönüm süzgeci (Hz).
const COMBS := [0.0297, 0.0371, 0.0411, 0.0437]
const ALLPASSES := [0.0050, 0.0017]
const T60 := 2.4
const DAMP_HZ := 900.0


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := int(params.get("rate", 22050))
	var n := int(float(params.get("seconds", 3.0)) * sr)
	# Perde: 82 → 108 Hz (yükseliş), tepede ±3 Hz gezinme, 72 Hz'e iniş.
	var wander := SynthDsp.anchors(8, -3.0, 3.0, rng)
	var freq := SynthDsp.control(n, sr, func(t: float) -> float:
		var base := 82.0
		if t < T_RISE:
			base = lerpf(82.0, 108.0, smoothstep(T_ON, T_RISE, t))
		elif t < T_FALL:
			base = 108.0 - 6.0 * (t - T_RISE) / (T_FALL - T_RISE)
		else:
			base = lerpf(102.0, 72.0, smoothstep(T_FALL, T_OFF, t))
		var k := clampf(t / T_OFF, 0.0, 1.0) * float(wander.size() - 1)
		var i := mini(int(k), wander.size() - 2)
		return clampf(base + lerpf(wander[i], wander[i + 1], k - float(i)), 70.0, 110.0))
	var voice := SynthDsp.zeros(n)
	SynthDsp.add_saw(voice, sr, freq, 0.6)
	var noise := SynthDsp.pink(n, rng)
	SynthDsp.add_band(noise, voice, sr, 160.0, 0.9, 0.9)
	# Boğazın rengi: «u» biçimlendiricisi.
	var throat := SynthDsp.zeros(n)
	SynthDsp.add_band(voice, throat, sr, 220.0, 2.5, 0.8)
	var env := SynthDsp.control(n, sr, func(t: float) -> float:
		if t < T_ON:
			return 0.0
		if t < T_RISE:
			return smoothstep(T_ON, T_RISE, t)
		if t < T_FALL:
			return 1.0 - 0.15 * (t - T_RISE) / (T_FALL - T_RISE)
		return 0.85 * exp(-(t - T_FALL) / 0.22) if t < T_OFF + 0.6 else 0.0)
	var dry := SynthDsp.zeros(n)
	for i in n:
		dry[i] = (voice[i] + throat[i]) * env[i]
	var lp := SynthDsp.biquad_coeffs("lowpass", 400.0, 0.707, sr)
	SynthDsp.biquad_in_place(dry, lp)
	SynthDsp.biquad_in_place(dry, lp)
	SynthDsp.highpass1_in_place(dry, 40.0, sr)
	# Karşı kıyının yansıması, sonra yankı.
	var src := dry.duplicate()
	SynthDsp.mix_into(src, dry, int(0.34 * sr), 0.45)
	var wet := _reverb(src, sr)
	var out := SynthDsp.zeros(n)
	for i in n:
		out[i] = 0.5 * src[i] + 0.5 * wet[i]
	SynthDsp.lowpass1_in_place(out, 1200.0, sr)
	SynthDsp.fade_edges(out, int(0.01 * sr), int(0.4 * sr))
	var peak := SynthDsp.peak(out)
	if peak > 0.0:
		SynthDsp.scale_in_place(out, LEVEL / peak * SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return out


## Schroeder yankısı: dört paralel sönümlü tarak, ardından iki tümgeçiren.
static func _reverb(x: PackedFloat32Array, sr: int) -> PackedFloat32Array:
	var n := x.size()
	var sum := SynthDsp.zeros(n)
	var damp := 1.0 - exp(-TAU * DAMP_HZ / float(sr))
	for d_s: float in COMBS:
		var d := int(d_s * sr)
		var g := pow(10.0, -3.0 * d_s / T60)
		var y := SynthDsp.zeros(n)
		var lp := 0.0
		for i in n:
			var fb := 0.0
			if i >= d:
				lp += damp * (y[i - d] - lp)
				fb = lp
			y[i] = x[i] + g * fb
		for i in n:
			sum[i] += y[i] * 0.25
	for d_s: float in ALLPASSES:
		var d := int(d_s * sr)
		var g := 0.7
		var y := SynthDsp.zeros(n)
		for i in n:
			var xd := sum[i - d] if i >= d else 0.0
			var yd := y[i - d] if i >= d else 0.0
			y[i] = -g * sum[i] + xd + g * yd
		sum = y
	return sum
