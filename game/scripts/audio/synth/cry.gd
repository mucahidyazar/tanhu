class_name SynthCry
extends RefCounted
## Yeni doğanın ilk ağlaması `newborn_cry` (story.md §3 satır 7d, audio.md §4 «Önsöz ekleri»; Yol Haritası birth-scene):
## kaynak-süzgeç sentezi. Önce kodla basılır, kulakla sınanır (K61); inandırıcı değilse ücretsiz kayıt (newborn_cry,
## Wikimedia Commons, CC0) tarifin kaynağı olur, o da olmazsa ElevenLabs efekt ucundan tek dosya, kredi önce sorulur.
##
## Yeni doğanın ağlaması solukla ayrılan ağlama birimleridir («ıngaa»): her birim 0,5–1,4 sn, temel perde birimin içinde
## kemer çizer (≈430 Hz'den ≈560 Hz'e çıkar, iner), titrer (jitter, 9 Hz tremor), en güçlü birimde kısa bir tiz kırılma
## (hiperfonasyon, ×1,9) vardır. Kaynak bant sınırlı testere ve soluk gürültüsüdür; ağız açılıp kapandıkça birinci
## biçimlendirici süpürülür («w-aa»): F1 650 → 1.100 → 850 Hz, F2 ≈1,9 kHz, F3 ≈3,3 kHz, F4 ≈5 kHz (bebeğin kısa ses
## yolu; tayf ücretsiz kaydın 1,3–2 kHz bandına göre ayarlandı).
## Birimler arasında kısa, hırıltılı soluk alış; başta ilk soluğun «hıh»ı. İlk ağlama güçlenerek gelir. Ses yurdun
## içinden, kapıdan duyulur: keçe tizi yutar (alçak geçiren), erken yansımalar kısa ve kısıktır.
## params: units ([[başlangıç sn, tür ("gasp", "cry", "in"), süre, kuvvet], ...]; yoksa UNITS), seconds, rate (32000),
## base_hz, distance (0..1), gain_db.

## Ağlama birimleri: [başlangıç sn, tür, süre sn, kuvvet]. İlk soluk, kısa bir ağlama, sonra güçlenen üç ağlama.
const UNITS := [
	[0.0, "gasp", 0.22, 0.5],
	[0.3, "cry", 0.55, 0.55],
	[0.95, "in", 0.24, 0.6],
	[1.28, "cry", 1.05, 0.8],
	[2.42, "in", 0.3, 0.75],
	[2.82, "cry", 1.38, 1.0],
	[4.29, "in", 0.28, 0.8],
	[4.66, "cry", 1.22, 0.92],
	[5.98, "in", 0.24, 0.6],
]
## Temel perdenin tabanı ve birimin içindeki kemerin yüksekliği (oran): ≈430 → ≈560 Hz.
const BASE_HZ := 430.0
const ARCH := 0.3
## Hiperfonasyon: en güçlü birimde kısa tiz kırılma (perde ×1,9).
const HYPER_RATIO := 1.9
const HYPER_S := 0.11
## Biçimlendiriciler: F1 süpürülür (açılış, açık, kapanış Hz), F2–F4 sabit bantlar [Hz, Q, kazanç].
const F1_SWEEP := [650.0, 1100.0, 850.0]
const F1_Q := 4.0
const FORMANTS := [[1900.0, 4.0, 0.75], [3300.0, 6.0, 0.35], [5000.0, 7.0, 0.15]]
## Soluk gürültüsünün payı (birimin başında ve sonunda güçlü).
const BREATH := 0.07
const LEVEL := 0.6


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := int(params.get("rate", 32000))
	var units: Array = params["units"] if params.get("units") is Array else UNITS
	var seconds := float(params.get("seconds", 6.5))
	var n := int(seconds * sr)
	var base := float(params.get("base_hz", BASE_HZ))
	var voice := SynthDsp.zeros(n)
	var f1_curve := SynthDsp.zeros(int(ceil(float(n) / 32.0)) + 1)
	f1_curve.fill(F1_SWEEP[0])
	var strongest := _strongest(units)
	for i in units.size():
		var u: Array = units[i]
		match str(u[1]):
			"cry":
				_add_cry(voice, f1_curve, sr, float(u[0]), float(u[2]), float(u[3]), base * (0.96 + 0.08 * rng.randf()),
						i == strongest, rng)
			"gasp":
				_add_breath(voice, sr, float(u[0]), float(u[2]), float(u[3]), true, rng)
			"in":
				_add_breath(voice, sr, float(u[0]), float(u[2]), float(u[3]), false, rng)
	var out := SynthDsp.zeros(n)
	SynthDsp.add_sweep(voice, out, sr, f1_curve, 32, F1_Q, 1.0)
	for f: Array in FORMANTS:
		SynthDsp.add_band(voice, out, sr, f[0], f[1], f[2])
	for i in n:
		out[i] += voice[i] * 0.06
	# Yurdun içinden: keçe tizi yutar, yakın duvarların kısa yansımaları.
	var distance := clampf(float(params.get("distance", 0.5)), 0.0, 1.0)
	SynthDsp.lowpass1_in_place(out, lerpf(9000.0, 4200.0, distance), sr)
	var room := SynthDsp.zeros(n)
	for r: Array in [[0.007, 0.36], [0.013, 0.26], [0.021, 0.16], [0.034, 0.08]]:
		SynthDsp.mix_into(room, out, int(float(r[0]) * sr), float(r[1]) * (0.5 + distance))
	for i in n:
		out[i] += room[i]
	SynthDsp.highpass1_in_place(out, 120.0, sr)
	SynthDsp.fade_edges(out, int(0.004 * sr), int(0.08 * sr))
	var peak := SynthDsp.peak(out)
	if peak > 0.0:
		SynthDsp.scale_in_place(out, LEVEL / peak * SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return out


## Birimin temel perde eğrisi (saf; Hz, sn başına `block` örnekte bir değer değil, örnek başına): kemer + tremor + jitter.
## Sınama perdenin 350–600 Hz aralığında kaldığını buradan ve sesin kendisinden ölçer.
static func pitch_at(t: float, duration: float, hz: float, jitter: float) -> float:
	var u := clampf(t / maxf(duration, 0.01), 0.0, 1.0)
	var arch := pow(sin(PI * u), 0.7)
	var tremor := 0.015 * sin(TAU * 9.0 * t)
	return hz * (1.0 + ARCH * arch * (0.85 + 0.15 * u) + tremor + jitter)


## Birimlerin en güçlüsünün sırası (hiperfonasyon orada).
static func _strongest(units: Array) -> int:
	var best := -1
	var best_v := -1.0
	for i in units.size():
		var u: Array = units[i]
		if str(u[1]) == "cry" and float(u[3]) > best_v:
			best_v = float(u[3])
			best = i
	return best


## Ağlama birimi: perde eğrisiyle testere, soluk gürültüsü, zarf; F1 eğrisine ağzın açılıp kapanması yazılır.
static func _add_cry(out: PackedFloat32Array, f1_curve: PackedFloat32Array, sr: int, at: float, duration: float, vel: float,
		hz: float, hyper: bool, rng: RandomNumberGenerator) -> void:
	var start := int(at * sr)
	var length := mini(int((duration + 0.1) * sr), out.size() - start)
	if length <= 0:
		return
	# Jitter: yavaş rastgele yürüyüş (±%2), 25 ms'de bir yeni hedef.
	var walk := PackedFloat32Array()
	var steps := int(ceil(duration / 0.025)) + 2
	var j := 0.0
	for k in steps:
		j = clampf(j + (rng.randf() - 0.5) * 0.012, -0.02, 0.02)
		walk.append(j)
	var hyper_at := duration * (0.45 + 0.2 * rng.randf())
	var freq := SynthDsp.control(length, sr, func(t: float) -> float:
		var k := clampi(int(t / 0.025), 0, walk.size() - 1)
		var f := SynthCry.pitch_at(t, duration, hz, walk[k])
		if hyper and absf(t - hyper_at) < HYPER_S * 0.5:
			f *= lerpf(1.0, HYPER_RATIO, smoothstep(0.0, 0.25, 1.0 - absf(t - hyper_at) / (HYPER_S * 0.5)))
		return f)
	var tone := SynthDsp.zeros(length)
	SynthDsp.add_saw(tone, sr, freq, 1.0, rng.randf())
	# Sesin eğimi: testere biraz yumuşar (bebeğin sıkışık, parlak sesi kalır).
	SynthDsp.lowpass1_in_place(tone, 3800.0, sr)
	var noise := SynthDsp.white(length, rng)
	var amp_phase := rng.randf() * TAU
	for i in length:
		var t := float(i) / sr
		var attack := clampf(t / 0.035, 0.0, 1.0)
		var release := clampf((duration - t) / 0.09, 0.0, 1.0)
		var env := attack * release * (1.0 + 0.06 * sin(TAU * 10.0 * t + amp_phase))
		var breath := BREATH * (1.0 + 4.0 * exp(-t / 0.05) + 3.0 * exp(-maxf(duration - t, 0.0) / 0.06))
		out[start + i] += (tone[i] + noise[i] * breath) * env * vel
	# Ağız: «w» kapalı başlar, açılır, sona doğru biraz kapanır.
	var c0 := start / 32
	var c1 := mini((start + length) / 32, f1_curve.size() - 1)
	for c in range(c0, c1 + 1):
		var u := clampf(float(c * 32 - start) / (duration * sr), 0.0, 1.0)
		var open := smoothstep(0.0, 0.22, u)
		var close := smoothstep(0.7, 1.0, u)
		f1_curve[c] = lerpf(lerpf(F1_SWEEP[0], F1_SWEEP[1], open), F1_SWEEP[2], close)


## Soluk: içe çekiş (hırıltılı, 1,5–4 kHz) ya da ilk soluğun «hıh»ı (kısa, kuvvetli, ardından ince bir cıyaklama).
static func _add_breath(out: PackedFloat32Array, sr: int, at: float, duration: float, vel: float, gasp: bool,
		rng: RandomNumberGenerator) -> void:
	var start := int(at * sr)
	var length := mini(int(duration * sr), out.size() - start)
	if length <= 0:
		return
	var noise := SynthDsp.white(length, rng)
	var band := SynthDsp.zeros(length)
	SynthDsp.add_band(noise, band, sr, 2400.0 if gasp else 3000.0, 1.2, 1.0)
	var squeak_hz := 820.0 + 160.0 * rng.randf()
	var ph := rng.randf()
	for i in length:
		var t := float(i) / sr
		var u := t / duration
		var env := sin(PI * clampf(u, 0.0, 1.0))
		if gasp:
			env = clampf(t / 0.01, 0.0, 1.0) * exp(-t / (duration * 0.4))
		ph += squeak_hz * (1.0 + 0.1 * u) / sr
		var squeak := sin(TAU * ph) * 0.12 * env * (1.0 if gasp else 0.4)
		out[start + i] += (band[i] * 0.55 * env + squeak) * vel
