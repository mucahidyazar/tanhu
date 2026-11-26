class_name SynthSequencer
extends RefCounted
## 6/8 ızgarası, kip ve akort tabloları ve kopuzun `motor` rolü (K59, K60; audio.md §3 «Motif ve kip», «`motor` rolü»;
## kopuz.md öneri 7 ve 9). Saf: olay listesi üretir, ses üretmez (SynthKopuz, SynthHujia, SynthKaval çalar).
##
## Ölçü 12 onaltılıktır; tempo noktalı dörtlüktür (bar_beats 2): 52'de ölçü 2,308 sn, sekizlik 0,385 sn. Cümle iki
## ölçüdür. `motor` her sekizlikte vurur:
##   konum   0         2        4             6         8        10
##   vuruş   down 3 tel up 2 tel flick ezgi   down 3 tel up 2 tel flick ezgi
##   kuvvet  1,0       0,55     0,7           0,85      0,5      0,65
## Şeritler tellerdir (0: 3. tel, 1: orta tel, 2: 1. tel): aynı telde yeni nota eskisini keser, çalan tel en çok üçtür.
## Kopuz kuralı (K60): Batı akoru yok, üçlü basılmaz. Tam vuruşta ve yukarı vuruşta dronun kökünün üçüncü derecesi
## (D Dorian'da F) çalınmaz, o tel açık çalar; üçüncü derece yalnız tek tel fiskesidir: D–F–A oluşmaz.
## `density` çalınan vuruşun oranıdır: cümlede round(density × vuruş) vuruş çalar. Önce ölçü başları, sonra ezginin
## yeni notası gelen vuruşlar (seyrek çalışta süs düşer, motif notaları kalır: A G F D bozulmaz), sonra ötekiler.
## Cümle sonunda p 0,3 gövde vuruşu, p 0,15 avuçla boğma (`slap`) ve ardından bir sekizlik sessizlik. Zaman ±8 ms,
## kuvvet ±%12 insanîleştirilir.

const BAR_16 := 12
const BAR_BEATS := 2
const PHRASE_BARS := 2
## [onaltılık konumu, vuruş, kuvvet]
const MOTOR := [[0, "down", 1.0], [2, "up", 0.55], [4, "flick", 0.7], [6, "down", 0.85], [8, "up", 0.5], [10, "flick", 0.65]]
const STROKES_PER_BAR := 6
## Vuruşun telleri, çalınış sırasıyla (down alttan üste, up üstten alta; flick ezgi telinde).
const STROKE_LANES := {"down": [0, 1, 2], "up": [2, 1], "mute": [0, 1, 2]}
const HUMANIZE_TIME := 0.008
const HUMANIZE_VEL := 0.12
## Telin en uzun çınlaması (sn): sonra parmak susturur.
const RING := 1.2
## Teller arası tarama (sn).
const STRUM_GAP := 0.009
const TAP_P := 0.3
const SLAP_P := 0.15

## Komuz akortları (MIDI; 3. / orta / 1. tel).
const TUNINGS := {
	"kambarkan": [50, 57, 50],
	"kerbez": [52, 57, 52],
	"ters": [50, 57, 55],
}
## Kipler: kök perde sınıfı, basamaklar, akort ve tam vuruşta çalınmayan üçüncü derece (perde sınıfı).
const MODES := {
	"d_dorian": {"root": 2, "steps": [0, 2, 3, 5, 7, 9, 10], "tuning": "kambarkan", "third": 5},
	"e_phrygian": {"root": 4, "steps": [0, 1, 3, 5, 7, 8, 10], "tuning": "kerbez", "third": 7},
	"major_pent": {"root": 5, "steps": [0, 2, 4, 7, 9], "tuning": "ters", "third": 9},
}

## Kopuzun cümleleri: iki ölçünün 12 vuruşunun ezgi notası (sırayla 0, 2, 4, 6, 8, 10. onaltılıklar). Üst konum kamp
## ve yol müziğinindir (A4 G4 F4 D4: orta tel +12, +10, +8, +5); alt konum sözün oktavıdır (A3 orta tel açık, G3, F3,
## D3 dış telde). Motifin düşüşü A G F D (K59); F yalnız fiske vuruşundadır.
const PHRASES := {
	"upper": {
		"A": ["A4", "A4", "A4", "G4", "G4", "F4", "D4", "D4", "D4", "D4", "D4", "D4"],
		"A2": ["A4", "A4", "C5", "A4", "G4", "F4", "E4", "E4", "G4", "D4", "D4", "D4"],
		"B": ["D4", "D4", "E4", "G4", "G4", "A4", "A4", "A4", "G4", "E4", "E4", "D4"],
		"open": ["A3", "A3", "A3", "A3", "A3", "A3", "A3", "A3", "A3", "A3", "A3", "A3"],
	},
	"lower": {
		"A": ["A3", "A3", "A3", "G3", "G3", "F3", "D3", "D3", "D3", "D3", "D3", "D3"],
		"A2": ["A3", "A3", "C4", "A3", "G3", "F3", "E3", "E3", "G3", "D3", "D3", "D3"],
		"B": ["D3", "D3", "E3", "G3", "G3", "A3", "A3", "A3", "G3", "E3", "E3", "D3"],
		"open": ["A3", "A3", "A3", "A3", "A3", "A3", "A3", "A3", "A3", "A3", "A3", "A3"],
	},
}
const NOTE_PC := {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


# --- Zaman ve perde ------------------------------------------------------------------------

## Onaltılığın süresi (sn): noktalı dörtlük = 6 onaltılık.
static func sixteenth(bpm: float) -> float:
	return 60.0 / bpm / 6.0


static func bar_seconds(bpm: float) -> float:
	return sixteenth(bpm) * BAR_16


## Ölçülerin örnek sayısı (yuvarlanmış; vuruş bilgili Ogg'un döngüsüyle aynı uzunluk).
static func bar_samples(bpm: float, bars: int, rate: int) -> int:
	return int(round(bar_seconds(bpm) * bars * rate))


## "A4" → 69; "F#3", "Bb3" de okunur.
static func note_midi(name: String) -> int:
	var pc: int = NOTE_PC.get(name.substr(0, 1).to_upper(), 0)
	var rest := name.substr(1)
	if rest.begins_with("#"):
		pc += 1
		rest = rest.substr(1)
	elif rest.begins_with("b"):
		pc -= 1
		rest = rest.substr(1)
	return (int(rest) + 1) * 12 + pc


static func mode_def(mode: String) -> Dictionary:
	return MODES.get(mode, MODES["d_dorian"])


static func tuning(mode: String) -> Array:
	return TUNINGS[str(mode_def(mode)["tuning"])]


## Perde kipte mi?
static func in_mode(mode: String, midi: int) -> bool:
	var m := mode_def(mode)
	return (m["steps"] as Array).has(posmod(midi - int(m["root"]), 12))


## Tam vuruşta çalınmayan perde mi (kökün üçüncü derecesi)?
static func is_third(mode: String, midi: int) -> bool:
	return posmod(midi, 12) == int(mode_def(mode)["third"])


## Ezgi notası hangi telde: üst konumda orta tel; alt konumda orta telin açığı ve üstü orta telde, altı 1. telde.
static func melody_lane(position: String, midi: int, open: Array) -> int:
	if position == "lower" and midi < int(open[1]):
		return 2
	return 1


# --- motor ------------------------------------------------------------------------------------

## Kopuzun vuruş dizisi. params:
##   tempo (bpm, 52), bars (2; cümle sayısı bars / 2), density (1), mode ("d_dorian"), position ("upper"/"lower"),
##   phrase ("A", "A2", "B", "open") ya da phrases (cümle başına bir ad), melody (12 notalık özel liste), mute (yalnız
##   mute vuruşu: tension, erlik), phrase_end (cümle sonu gövde vuruşu ve slap; true), humanize (true).
## Dönüş: {length (sn), strokes [{t, stroke, vel}], notes [{t, dur, lane, midi, vel, stroke, glide, glide_s}],
##   taps [{t, kind ("tap"/"slap"), vel}]}; t cümle başından saniye.
static func motor(params: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var bpm := float(params.get("tempo", 52.0))
	var bars := maxi(int(params.get("bars", PHRASE_BARS)), 1)
	var density := clampf(float(params.get("density", 1.0)), 0.0, 1.0)
	var mode := str(params.get("mode", "d_dorian"))
	var position := str(params.get("position", "upper"))
	var mute := bool(params.get("mute", false))
	var human := bool(params.get("humanize", true))
	var phrase_end := bool(params.get("phrase_end", true))
	var open := tuning(mode)
	var s16 := sixteenth(bpm)
	var length := bar_seconds(bpm) * bars
	var strokes: Array = []
	var notes: Array = []
	var taps: Array = []
	var prev_melody := -1
	var phrase_count := int(ceil(float(bars) / PHRASE_BARS))
	for ph in phrase_count:
		var melody := _phrase_melody(params, ph, position)
		var last_bar := mini((ph + 1) * PHRASE_BARS, bars) - 1
		var slap := phrase_end and rng.randf() < SLAP_P
		var tap := phrase_end and not slap and rng.randf() < TAP_P
		var keep := _keep_set(melody, (last_bar - ph * PHRASE_BARS + 1) * STROKES_PER_BAR, density, rng)
		for b in range(ph * PHRASE_BARS, last_bar + 1):
			for k in STROKES_PER_BAR:
				var row: Array = MOTOR[k]
				var pos: int = row[0]
				var kind: String = "mute" if mute else str(row[1])
				var vel: float = row[2]
				var t := (b * BAR_16 + pos) * s16
				var dt := (rng.randf() * 2.0 - 1.0) * HUMANIZE_TIME if human else 0.0
				var dv := 1.0 + (rng.randf() * 2.0 - 1.0) * HUMANIZE_VEL if human else 1.0
				var slot := (b - ph * PHRASE_BARS) * STROKES_PER_BAR + k
				var play := keep.has(slot)
				var mel := note_midi(str(melody[slot % melody.size()]))
				var end_slot := b == last_bar and pos >= 8
				if end_slot and slap:
					if pos == 8:
						taps.append({"t": maxf(t + dt, 0.0), "kind": "slap", "vel": clampf(vel * dv, 0.05, 1.0)})
						strokes.append({"t": maxf(t + dt, 0.0), "stroke": "slap", "vel": clampf(vel * dv, 0.05, 1.0)})
					continue
				if end_slot and tap and pos == 10:
					taps.append({"t": maxf(t + dt, 0.0), "kind": "tap", "vel": clampf(vel * dv, 0.05, 1.0)})
					continue
				if not play:
					continue
				var at := maxf(t + dt, 0.0)
				var v := clampf(vel * dv, 0.05, 1.0)
				strokes.append({"t": at, "stroke": kind, "vel": v})
				var lane_m := melody_lane(position, mel, open)
				var glide := mel != prev_melody and kind != "mute"
				prev_melody = mel
				if kind == "flick":
					notes.append(_note(at, lane_m, mel, v, kind, glide, rng))
					continue
				var lanes: Array = STROKE_LANES[kind]
				for i in lanes.size():
					var lane: int = lanes[i]
					var midi: int = open[lane]
					var on_melody := lane == lane_m and not is_third(mode, mel)
					if on_melody:
						midi = mel
					notes.append(_note(at + i * STRUM_GAP, lane, midi, v * (1.0 if i == 0 else 0.92), kind,
							glide and on_melody, rng))
	_close_notes(notes, taps, length)
	return {"length": length, "strokes": strokes, "notes": notes, "taps": taps}


## Ezgi çizgisi (hucia, kaval): rows [[onaltılık konumu, onaltılık uzunluğu, nota adı, kuvvet], ...].
## Dönüş [{t, dur, midi, vel}]; zaman ±8 ms ve kuvvet ±%12 insanîleşir (humanize).
static func line(rows: Array, bpm: float, rng: RandomNumberGenerator, human: bool = true) -> Array:
	var s16 := sixteenth(bpm)
	var out: Array = []
	for row: Variant in rows:
		var r: Array = row
		var dt := (rng.randf() * 2.0 - 1.0) * HUMANIZE_TIME if human else 0.0
		var dv := 1.0 + (rng.randf() * 2.0 - 1.0) * HUMANIZE_VEL if human else 1.0
		out.append({"t": maxf(float(r[0]) * s16 + dt, 0.0), "dur": float(r[1]) * s16, "midi": note_midi(str(r[2])),
			"vel": clampf(float(r[3]) * dv, 0.05, 1.0)})
	return out


## Aynı anda çalan perdenin en büyük sayısı (notların [t, t + dur) aralıkları).
static func max_simultaneous(notes: Array) -> int:
	var edges: Array = []
	for n: Variant in notes:
		var d: Dictionary = n
		edges.append([float(d["t"]), 1])
		edges.append([float(d["t"]) + float(d["dur"]), -1])
	edges.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	var cur := 0
	var best := 0
	for e: Array in edges:
		cur += int(e[1])
		best = maxi(best, cur)
	return best


## Vuruşların saniyedeki sayısı (slap sayılmaz).
static func strokes_per_second(seq: Dictionary) -> float:
	var count := 0
	for s: Variant in seq["strokes"]:
		if str((s as Dictionary)["stroke"]) != "slap":
			count += 1
	return count / maxf(float(seq["length"]), 0.001)


## Cümlede çalan vuruşlar (sıra → true): round(density × count) vuruş; önce ölçü başları, sonra ezginin yeni notası
## gelen vuruşlar, sonra ötekiler (her öbek kendi içinde tohumla karışık). Kesirli pay tohumla yuvarlanır.
static func _keep_set(melody: Array, count: int, density: float, rng: RandomNumberGenerator) -> Dictionary:
	var exact := density * count
	var budget := int(floor(exact)) + (1 if rng.randf() < exact - floor(exact) else 0)
	var downbeats: Array = []
	var onsets: Array = []
	var rest: Array = []
	for k in count:
		if k % STROKES_PER_BAR == 0:
			downbeats.append(k)
		elif str(melody[k % melody.size()]) != str(melody[(k - 1) % melody.size()]):
			onsets.append(k)
		else:
			rest.append(k)
	var keep := {}
	for group: Array in [downbeats, onsets, rest]:
		_shuffle(group, rng)
		for k: int in group:
			if keep.size() >= budget:
				return keep
			keep[k] = true
	return keep


## Tohumlu karıştırma (Fisher–Yates; Array.shuffle genel RNG'yi kullanır).
static func _shuffle(list: Array, rng: RandomNumberGenerator) -> void:
	for i in range(list.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = list[i]
		list[i] = list[j]
		list[j] = tmp


static func _phrase_melody(params: Dictionary, index: int, position: String) -> Array:
	if params.get("melody") is Array and not (params["melody"] as Array).is_empty():
		return params["melody"]
	var table: Dictionary = PHRASES.get(position, PHRASES["upper"])
	var name := str(params.get("phrase", "A"))
	if params.get("phrases") is Array and not (params["phrases"] as Array).is_empty():
		var list: Array = params["phrases"]
		name = str(list[index % list.size()])
	return table.get(name, table["A"])


static func _note(t: float, lane: int, midi: int, vel: float, stroke: String, glide: bool, rng: RandomNumberGenerator) -> Dictionary:
	var cents := 0.0
	var seconds := 0.0
	if glide:
		cents = -30.0 - 30.0 * rng.randf()
		seconds = 0.04 + 0.03 * rng.randf()
	return {"t": t, "dur": RING, "lane": lane, "midi": midi, "vel": vel, "stroke": stroke, "glide": cents, "glide_s": seconds}


## Aynı teldeki sonraki nota (ya da slap) notayı keser; en çok RING çınlar; cümle sonunda biter.
static func _close_notes(notes: Array, taps: Array, length: float) -> void:
	var slaps := PackedFloat32Array()
	for tap: Variant in taps:
		if str((tap as Dictionary)["kind"]) == "slap":
			slaps.append(float(tap["t"]))
	for i in notes.size():
		var n: Dictionary = notes[i]
		var t := float(n["t"])
		var end := minf(t + RING, length)
		for j in range(i + 1, notes.size()):
			var o: Dictionary = notes[j]
			if int(o["lane"]) == int(n["lane"]) and float(o["t"]) > t:
				end = minf(end, float(o["t"]))
				break
		for s in slaps:
			if s > t:
				end = minf(end, s)
		n["dur"] = maxf(end - t, 0.0)
