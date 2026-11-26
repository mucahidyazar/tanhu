class_name SynthBell
extends RefCounted
## Rehinenin ayak çanı `bell_step` (audio.md §2 «Çan»: bronz FM, 3 kısmi; §4 «Ayak»): küçük tunç çan, tokmağı bir kez vurur. Köprü 2'de bileğe
## bağlanırken ve adımda duyulur; I. Perde'nin açılışı ve ayak sesi aynı dosyayı kullanır (perde pitch ile oynar).
## Kısmiler sinüs FM'dir (taşıyıcı : çarpan oranı uyumsuz, metal renk), parlaklık çabuk söner, gövde kalır; vuruş kısa bir gürültü darbesidir.
## Dış mekân: yansıma yok.
## params: hz (ana perde), seconds, rate (32000: tiz atak), gain_db.

const BASE_HZ := 1180.0
## Kısmiler: [taşıyıcı oranı, kazanç, sönüm sn, FM indeksi, indeksin sönümü sn].
const PARTIALS := [[1.0, 1.0, 0.42, 1.4, 0.05], [2.76, 0.42, 0.2, 0.9, 0.03], [5.4, 0.2, 0.09, 0.5, 0.02]]
## FM çarpanının taşıyıcıya oranı.
const FM_RATIO := 1.41
const STRIKE_S := 0.0025
const LEVEL := 0.6


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := int(params.get("rate", 32000))
	var n := int(float(params.get("seconds", 1.2)) * sr)
	var base := float(params.get("hz", BASE_HZ))
	var out := SynthDsp.zeros(n)
	for p: Variant in PARTIALS:
		var row: Array = p
		_add_partial(out, sr, base * float(row[0]), float(row[1]), float(row[2]), float(row[3]), float(row[4]), rng.randf() * TAU)
	var strike := int(STRIKE_S * 6.0 * sr)
	for i in mini(strike, n):
		out[i] += (rng.randf() * 2.0 - 1.0) * exp(-float(i) / (STRIKE_S * sr)) * 0.5
	SynthDsp.highpass1_in_place(out, 300.0, sr)
	SynthDsp.fade_edges(out, 0, int(0.08 * sr))
	var peak := SynthDsp.peak(out)
	if peak > 0.0:
		SynthDsp.scale_in_place(out, LEVEL / peak * SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return out


## Tek kısmi: indeksi hızla sönen FM (vuruşta parlak, sonra saf), genliği üstel sönümlü.
static func _add_partial(out: PackedFloat32Array, sr: int, hz: float, gain: float, decay: float, index: float, index_decay: float, phase: float) -> void:
	var mod_hz := hz * FM_RATIO
	for i in out.size():
		var t := float(i) / sr
		var mod := sin(TAU * mod_hz * t) * index * exp(-t / index_decay)
		out[i] += sin(TAU * hz * t + mod + phase) * gain * exp(-t / decay)
