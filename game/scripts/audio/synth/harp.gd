class_name SynthHarp
extends RefCounted
## Yüeçi arpı (audio.md §2 «Arp»: Karplus-Strong, 1,2 sn; I. Perde'nin ezgi sesi, K59; ses-tasarimi.md §12): telin ortasına yakın parmakla çekilir
## (çekme konumu 0,18–0,28, darbe yumuşak), teller serbest çınlar (T60 orta telde ≈1,2 sn; aynı telde yeni nota eskisini keser), küçük bir
## ses kutusu (180, 420, 950 Hz) ve açık üst süzgeç (8 kHz). Kopuz kuralı arpta da geçerlidir (K60): Batı akoru yok, üçlü basılmaz; ezgi tek
## seslidir, yalnız açık beşli ve oktav birlikte çalar. I. Perde'de motifin düşüşü D'ye varmaz: A G F (K59).
## params: rows ([[onaltılık konumu, uzunluğu, nota, kuvvet], ...]; aynı konumdaki iki satır birlikte çalar), phrase (hazır cümle), tempo, bars,
## rate (44100), gain_db.

## Hazır cümleler (E Frigyen; iki ölçü, 24 onaltılık).
const PHRASES := {
	"fall": [[0, 3, "E4", 0.8], [3, 3, "G4", 0.7], [6, 6, "A4", 0.85], [12, 4, "A4", 0.72], [16, 4, "G4", 0.7], [20, 4, "F4", 0.82]],
	"low": [[0, 3, "B3", 0.7], [3, 3, "C4", 0.64], [6, 3, "E4", 0.75], [9, 3, "F4", 0.7], [12, 6, "E4", 0.8], [18, 6, "B3", 0.62]],
	"open": [[0, 2, "E3", 0.62], [2, 2, "B3", 0.55], [4, 2, "E4", 0.6], [6, 6, "F4", 0.7], [12, 2, "E3", 0.55], [14, 2, "B3", 0.5], [16, 2, "E4", 0.55], [18, 6, "D4", 0.64]],
}
const T60_MID := 1.2
const MID_HZ := 246.94
const T60_EXP := 0.4
const PLUCK := Vector2(0.18, 0.28)
const SOFT := 0.32
## Ses kutusu: [Hz, Q, kazanç].
const BODY := [[180.0, 3.0, 0.45], [420.0, 3.0, 0.4], [950.0, 2.0, 0.3]]
const DRY := 0.7
const TOP_HZ := 8000.0
const RELEASE_S := 0.03
const LEVEL := 0.32


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := int(params.get("rate", SynthDsp.RATE))
	var bpm := float(params.get("tempo", 72.0))
	var bars := maxi(int(params.get("bars", SynthSequencer.PHRASE_BARS)), 1)
	var n := SynthSequencer.bar_samples(bpm, bars, sr)
	var rows: Array = params["rows"] if params.get("rows") is Array else PHRASES.get(str(params.get("phrase", "fall")), PHRASES["fall"])
	var strings := SynthDsp.zeros(n)
	var notes := SynthSequencer.line(rows, bpm, rng, bool(params.get("humanize", true)))
	for k in notes.size():
		var d: Dictionary = notes[k]
		var start := int(float(d["t"]) * sr)
		var midi := int(d["midi"])
		# Tel aynı perdeyi yeniden çalınca susar; öteki teller çınlamayı sürdürür. Cümle sonunda her tel susar.
		var end := n
		for j in range(k + 1, notes.size()):
			if int((notes[j] as Dictionary)["midi"]) == midi:
				end = int(float((notes[j] as Dictionary)["t"]) * sr)
				break
		var hz := SynthDsp.midi_hz(midi)
		var t60 := T60_MID * pow(MID_HZ / hz, T60_EXP)
		var length := mini(end - start, n - start)
		if length <= 0:
			continue
		var buf := SynthKopuz.pluck(hz, length, sr, rng.randf_range(PLUCK.x, PLUCK.y), t60, SOFT, rng)
		SynthDsp.release(buf, maxi(length - int(RELEASE_S * sr), 0), int(RELEASE_S * sr))
		SynthDsp.scale_in_place(buf, float(d["vel"]))
		SynthDsp.mix_into(strings, buf, start)
	var out := strings.duplicate()
	SynthDsp.scale_in_place(out, DRY)
	for b: Array in BODY:
		SynthDsp.add_band(strings, out, sr, b[0], b[1], b[2])
	SynthDsp.lowpass1_in_place(out, TOP_HZ, sr)
	SynthDsp.fade_edges(out, 0, int(0.02 * sr))
	SynthDsp.scale_in_place(out, LEVEL * SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return out
