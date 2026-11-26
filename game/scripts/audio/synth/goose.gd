class_name SynthGoose
extends RefCounted
## Kaz (audio.md §4 «Önsöz ekleri» `goose_honk`: mit panosunda uzak kaz, kısa ve sık): kaynak-süzgeç sentezi. Geniz
## sesli bir ötüş iki hecedir («a-honk»): temel perde kısa sürede yükselip düşer (≈330 → 420 → 300 Hz), kaynak
## harmonikçe zengin testere ve hırıltı, geniz biçimlendiricileri (≈600, 1.150, 2.400 Hz). İki kaz sırayla öter (iki
## kara kaz: Kayra Han ile Kişi, story.md §3); uzaklık alçak geçiren, hafif yankı ve düşük düzeydir.
## Ücretsiz kayıt (Wikimedia, ABD Balık ve Yaban Hayatı, kamu malı: assets/_free/sound/geese_distant/) bununla kulakla
## karşılaştırılır (tarif data/audio/bake/goose_honk.json).
## params: calls ([[sn, ses (0 ya da 1), kuvvet], ...]; yoksa CALLS), seconds, distance (0..1), rate (22050), gain_db.

## Ötüşler: [başlangıç sn, kaz, kuvvet]. İki kaz: 0 Kayra (biraz alçak), 1 Kişi.
const CALLS := [[0.05, 0, 0.9], [0.42, 1, 0.75], [0.78, 0, 0.8], [1.3, 1, 0.65]]
## Kazların temel perdesi (Hz) ve tınısı.
const VOICE_HZ: Array[float] = [330.0, 372.0]
const HONK_S := 0.2
const FORMANTS := [[600.0, 4.0, 1.0], [1150.0, 5.0, 0.7], [2400.0, 6.0, 0.35]]
const LEVEL := 0.4


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := int(params.get("rate", 22050))
	var seconds := float(params.get("seconds", 2.0))
	var n := int(seconds * sr)
	var calls: Array = params["calls"] if params.get("calls") is Array else CALLS
	var src := SynthDsp.zeros(n)
	for c: Variant in calls:
		var row: Array = c
		_add_honk(src, sr, float(row[0]), VOICE_HZ[clampi(int(row[1]), 0, 1)] * (1.0 + (rng.randf() - 0.5) * 0.04),
				float(row[2]), rng)
	var out := SynthDsp.zeros(n)
	for f: Array in FORMANTS:
		SynthDsp.add_band(src, out, sr, f[0], f[1], f[2])
	for i in n:
		out[i] += src[i] * 0.05
	# Uzaklık: tiz söner, yerden yansıyan ikinci bir kopya (60 ms, −10 dB) sesi yayar.
	var distance := clampf(float(params.get("distance", 0.7)), 0.0, 1.0)
	SynthDsp.lowpass1_in_place(out, lerpf(5000.0, 2200.0, distance), sr)
	var echo := SynthDsp.zeros(n)
	SynthDsp.mix_into(echo, out, int(0.06 * sr), 0.32 * distance)
	SynthDsp.mix_into(echo, out, int(0.13 * sr), 0.16 * distance)
	for i in n:
		out[i] += echo[i]
	SynthDsp.fade_edges(out, int(0.005 * sr), int(0.05 * sr))
	var peak := SynthDsp.peak(out)
	if peak > 0.0:
		SynthDsp.scale_in_place(out, LEVEL / peak * SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return out


## Tek ötüş: perde iki hecelik eğriyle (yükselir, düşer), kaynak testere ve hırıltı; zarf sert başlar, kısa söner.
static func _add_honk(out: PackedFloat32Array, sr: int, at: float, hz: float, vel: float, rng: RandomNumberGenerator) -> void:
	var start := int(at * sr)
	var length := mini(int((HONK_S + 0.06) * sr), out.size() - start)
	if length <= 0:
		return
	var freq := SynthDsp.control(length, sr, func(t: float) -> float:
		var rise := 1.27 * sin(PI * clampf(t / (HONK_S * 0.55), 0.0, 1.0))
		var fall := 0.9 + 0.1 * (1.0 - clampf((t - HONK_S * 0.4) / (HONK_S * 0.6), 0.0, 1.0))
		return hz * maxf(rise, fall) * (1.0 + 0.02 * sin(TAU * 38.0 * t)))
	var tone := SynthDsp.zeros(length)
	SynthDsp.add_saw(tone, sr, freq, 1.0, rng.randf())
	var rasp := SynthDsp.white(length, rng)
	for i in length:
		var t := float(i) / sr
		var env := clampf(t / 0.012, 0.0, 1.0) * clampf(1.0 - (t - HONK_S) / 0.06, 0.0, 1.0)
		# Hece arası: ikinci hecenin başında kısa bir kırılma («a-honk»).
		var dip := 1.0 - 0.55 * exp(-pow((t - HONK_S * 0.28) / 0.012, 2.0))
		out[start + i] += (tone[i] * 0.8 + rasp[i] * 0.25 * (1.0 + 2.0 * exp(-t / 0.02))) * env * dip * vel
