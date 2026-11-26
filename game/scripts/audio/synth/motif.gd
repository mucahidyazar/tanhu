class_name SynthMotif
extends RefCounted
## Motifin bütünü kopuzla (audio.md §3 «Motif ve kip»; story.md §3 satır 7d): yükseliş D↗A ve düşüş A G F D. Oyunda
## bütün motifin ilk çalışı doğumdadır (Önsöz 3:22,5); perdelerde parçalanır, oyunda ilk kez III'te bütünlenir (K59).
## Yükseliş ıslıklı okun 3/2'lik kayışıdır: orta tel A3'e basılıp D3'ten kaydırılır (SynthDsp.glide, −700 sent,
## 0,55 sn). Düşüş alt konumda (sözün oktavı): A3 orta tel açık, G3 ve F3 1. telde (+5, +3), D3 açık; F yalnız tek tel
## fiskesidir, tam vuruşta üçlü basılmaz (K60). Aynı anda en çok üç tel. Kopuzun tel modeli ve gövdesi B'nindir
## (SynthKopuz.render_sequence). Motif dosyanın başındadır, ardı sessizdir: dosya bankada düz katmandır (döngü açık,
## tam ölçü), motif bir kez çalar, klip motiften önce değişir.
## params: tempo (52), bars (dosyanın ölçü sayısı), start (motifin dosyadaki başı, sn), length (motifin süresi, sn),
## rate (44100), gain_db.

## Motifin notaları: [sn, tel (0: 3. tel, 1: orta, 2: 1. tel), MIDI, vuruş, kuvvet, kayış (sent, eksi: alttan)].
## Tam vuruşlar (down) teller arası 9 ms taramayla üç telde çalar: biri ezgi, ötekiler açık.
const NOTES := [
	[0.0, 0, 50, "down", 0.6, 0.0],
	[0.03, 1, 57, "flick", 1.0, -700.0],
	[1.54, -1, 57, "down", 0.9, 0.0],
	[1.92, 2, 55, "flick", 0.85, 0.0],
	[2.31, 2, 53, "flick", 0.8, 0.0],
	[2.69, -1, 50, "down", 0.95, 0.0],
]
## Kambarkan akordu (D3 / A3 / D3) ve tam vuruşta ezginin teli: A3 orta telde, D3 1. telde.
const OPEN: Array[int] = [50, 57, 50]
const SLIDE_S := 0.55
## Bir telin en uzun çınlaması (sn): sonraki nota ya da motifin sonu keser.
const MAX_RING := 2.0
const LENGTH := 6.0


static func render(params: Dictionary, rng: RandomNumberGenerator) -> PackedFloat32Array:
	var sr := int(params.get("rate", SynthDsp.RATE))
	var bpm := float(params.get("tempo", 52.0))
	var bars := maxi(int(params.get("bars", 10)), 1)
	var n := SynthSequencer.bar_samples(bpm, bars, sr)
	var seq := sequence(float(params.get("length", LENGTH)))
	var motif := SynthKopuz.render_sequence(seq, sr, rng)
	var out := SynthDsp.zeros(n)
	SynthDsp.mix_into(out, motif, int(float(params.get("start", 0.0)) * sr))
	SynthDsp.scale_in_place(out, SynthDsp.db_to_gain(float(params.get("gain_db", 0.0))))
	return out


## Motifin olay listesi (SynthKopuz.render_sequence'in biçimi): {length, notes [{t, dur, lane, midi, vel, stroke, glide,
## glide_s}], taps []}. Tam vuruş üç teli tarar; aynı teldeki sonraki nota öncekini keser.
static func sequence(length: float = LENGTH) -> Dictionary:
	var notes: Array = []
	for row: Array in NOTES:
		var t := float(row[0])
		var lane := int(row[1])
		var midi := int(row[2])
		var stroke := str(row[3])
		var vel := float(row[4])
		if lane >= 0:
			notes.append(_note(t, lane, midi, vel, stroke, float(row[5])))
			continue
		# Tam vuruş: alttan üste üç tel; ezgi notası kendi telinde, öteki teller açık.
		var melody_lane := 1 if midi == OPEN[1] else 2
		for i in 3:
			var pitch := midi if i == melody_lane else OPEN[i]
			notes.append(_note(t + i * SynthSequencer.STRUM_GAP, i, pitch, vel * (1.0 if i == 0 else 0.92), stroke, 0.0))
	for i in notes.size():
		var note: Dictionary = notes[i]
		var end := minf(float(note["t"]) + MAX_RING, length)
		for j in range(i + 1, notes.size()):
			var other: Dictionary = notes[j]
			if int(other["lane"]) == int(note["lane"]) and float(other["t"]) > float(note["t"]):
				end = minf(end, float(other["t"]))
				break
		note["dur"] = maxf(end - float(note["t"]), 0.0)
	return {"length": length, "strokes": [], "notes": notes, "taps": []}


## Motifin ezgisi (saf, sınama için): [[sn, MIDI, kayışın başladığı MIDI ya da -1], ...]: D↗A, A, G, F, D.
static func melody() -> Array:
	var out: Array = []
	for row: Array in NOTES:
		var lane := int(row[1])
		var midi := int(row[2])
		if lane == 0 and str(row[3]) == "down" and float(row[5]) == 0.0 and float(row[0]) == 0.0:
			continue
		var from := midi + int(round(float(row[5]) / 100.0)) if float(row[5]) != 0.0 else -1
		out.append([float(row[0]), midi, from])
	return out


static func _note(t: float, lane: int, midi: int, vel: float, stroke: String, glide: float) -> Dictionary:
	return {"t": t, "dur": 0.0, "lane": lane, "midi": midi, "vel": vel, "stroke": stroke, "glide": glide,
		"glide_s": SLIDE_S if glide != 0.0 else 0.0}
