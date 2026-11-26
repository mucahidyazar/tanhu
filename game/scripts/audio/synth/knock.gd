class_name SynthKnock
extends RefCounted
## Tahta tokmak `post_knock` (travel.md §14 «Ses»: «Tahta tokmak: 180 Hz sönümlü sinüs + kısa gürültü»; audio.md §4 komşu ekleri): Menzil
## Direği'nin ucunda iple asılı tokmak direğe vurur (RelayPosts.knock; oyuncu direğe E basınca). Her vuruş üç katmandır: direğin gövdesi
## (180 Hz çevresinde, ilk 30 ms'de %8 inen sönümlü sinüs, ≈90 ms), tahtanın iki tepesi (≈540 ve ≈1.180 Hz, kısa sönümlü) ve değmenin
## kısa gürültüsü (2,2 kHz çevresinde bant, ≈6 ms). Tokmak iki kez vurur (tok-tok; ikincisi biraz kısık ve tiz); kuru, yansımasız (dış mekân).
## Bağlı direğin kemik uğultusu ayrı sestir (bone_hum; MapSoundscape).
## params: hits ([[sn, kuvvet], ...]; yoksa HITS), body_hz (180), body_s (0,09), seconds (0,6), rate (22050), gain_db.

## Vuruşlar: [başlangıç sn, kuvvet].
const HITS := [[0.02, 1.0], [0.23, 0.78]]
## Tahtanın tepeleri: [Hz, sönüm sn, kazanç].
const MODES := [[540.0, 0.035, 0.45], [1180.0, 0.018, 0.28]]
const CONTACT_HZ := 2200.0
const CONTACT_S := 0.006
const LEVEL := 0.6


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := int(params.get("rate", 22050))
	var n := int(float(params.get("seconds", 0.6)) * sr)
	var hits: Array = params["hits"] if params.get("hits") is Array else HITS
	var body_hz := float(params.get("body_hz", 180.0))
	var body_s := float(params.get("body_s", 0.09))
	var out := SynthDsp.zeros(n)
	for i in hits.size():
		var row: Array = hits[i]
		# İkinci vuruş tokmağın geri sekmesidir: biraz tiz ve kısa.
		var pitch := 1.0 + 0.04 * float(i) + (rng.randf() - 0.5) * 0.02
		_add_hit(out, sr, float(row[0]), float(row[1]), body_hz * pitch, body_s * (1.0 - 0.15 * float(i)), rng)
	SynthDsp.highpass1_in_place(out, 60.0, sr)
	SynthDsp.fade_edges(out, 0, int(0.03 * sr))
	var peak := SynthDsp.peak(out)
	if peak > 0.0:
		SynthDsp.scale_in_place(out, LEVEL / peak * SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return out


## Bir vuruş: gövdenin sönümlü sinüsü (perdesi ilk 30 ms'de %8 iner), tahtanın tepeleri ve değmenin kısa bant gürültüsü.
static func _add_hit(out: PackedFloat32Array, sr: int, at: float, vel: float, hz: float, decay: float, rng: RandomNumberGenerator) -> void:
	var start := int(at * sr)
	var length := mini(int(maxf(decay * 6.0, 0.08) * sr), out.size() - start)
	if length <= 0:
		return
	var phase := rng.randf() * TAU
	var phases := PackedFloat32Array()
	for m in MODES.size():
		phases.append(rng.randf() * TAU)
	for i in length:
		var t := float(i) / sr
		var attack := clampf(t / 0.0012, 0.0, 1.0)
		phase += TAU * hz * lerpf(1.0, 0.92, clampf(t / 0.03, 0.0, 1.0)) / sr
		var s := sin(phase) * exp(-t / decay)
		for m in MODES.size():
			var mode: Array = MODES[m]
			s += sin(TAU * float(mode[0]) * t + phases[m]) * exp(-t / float(mode[1])) * float(mode[2])
		out[start + i] += s * attack * vel
	var contact_n := mini(int(CONTACT_S * 5.0 * sr), out.size() - start)
	var noise := SynthDsp.white(contact_n, rng)
	var band := SynthDsp.zeros(contact_n)
	SynthDsp.add_band(noise, band, sr, CONTACT_HZ * (0.9 + 0.2 * rng.randf()), 1.2, 1.0)
	for i in contact_n:
		var t := float(i) / sr
		out[start + i] += band[i] * 1.6 * exp(-t / CONTACT_S) * vel
