extends TestCase
## Kodla kopuz (K60; audio.md §2 «Kopuz kuralı», «Kopuz sentezi», §3 «Motif ve kip», «`motor` rolü»; kopuz.md öneri
## 7–9): SynthSequencer'ın vuruş dizisi ve SynthKopuz'un Karplus-Strong teli. Beklenen değerler tasarımın tablolarından
## okunur (prototipin fikstürüne girmez: kopuz bu turda değişen kuraldır, godot.md §3.2 madde 8).
## Kodla kopuz şarkının ölçülerini de tutar (K75; audio.md §2 «Kabul»): 1,28 kHz üstü enerji ≥%8, 2–6 kHz sönümü
## ≥4 dB / 100 ms, vuruş ≥2,0 / sn. Kulakla onayı kullanıcınındır (Karar Bekleyenler).

const SR := 44100
## Sınamada her vuruş sayılsın: cümle sonu gövde vuruşu ve slap kapalı.
const PLAIN := {"tempo": 52.0, "density": 1.0, "phrase_end": false}
const CONTROL_WAV := "res://audio/gen/_wav/kopuz_control_d.wav"


# --- motor rolü ------------------------------------------------------------------------------

func test_motor_table_follows_the_design() -> void:
	var want := [[0, "down", 1.0], [2, "up", 0.55], [4, "flick", 0.7], [6, "down", 0.85], [8, "up", 0.5], [10, "flick", 0.65]]
	assert_eq(SynthSequencer.MOTOR.size(), 6, "12 onaltılığın 0, 2, 4, 6, 8, 10. konumları")
	for i in want.size():
		var row: Array = SynthSequencer.MOTOR[i]
		assert_eq(int(row[0]), int(want[i][0]), "konum")
		assert_eq(str(row[1]), str(want[i][1]), "vuruş")
		assert_almost(float(row[2]), float(want[i][2]), 0.0001, "kuvvet")
	assert_almost(SynthSequencer.bar_seconds(52.0), 2.3077, 0.0005, "6/8, noktalı dörtlük 52: ölçü 2,308 sn")
	assert_almost(SynthSequencer.RING, 1.2, 0.0001, "RING 1,2 sn")


func test_density_one_at_52_strikes_2_6_per_second() -> void:
	var seq := SynthSequencer.motor(PLAIN.merged({"bars": 4}, true), SynthDsp.make_rng(1))
	assert_almost(SynthSequencer.strokes_per_second(seq), 2.6, 0.05, "52'de yoğunluk 1 → 2,6 vuruş/sn")
	assert_eq(seq["strokes"].size(), 24, "dört ölçüde 24 vuruş")


func test_density_is_the_ratio_of_played_strokes() -> void:
	for density in [0.55, 0.3, 0.2]:
		var seq := SynthSequencer.motor(PLAIN.merged({"bars": 60, "density": density}, true), SynthDsp.make_rng(7))
		var ratio := float(seq["strokes"].size()) / (60.0 * SynthSequencer.STROKES_PER_BAR)
		assert_almost(ratio, density, 0.06, "yoğunluk %.2f çalınan vuruşun oranıdır" % density)
	var none := SynthSequencer.motor(PLAIN.merged({"bars": 4, "density": 0.0}, true), SynthDsp.make_rng(7))
	assert_eq(none["strokes"].size(), 0, "yoğunluk 0 (camp_bard): kopuz çalmaz")


func test_sparse_playing_keeps_the_motif_notes() -> void:
	# Seyrek çalışta süs düşer, motifin notaları kalır (camp 0,55; camp_night 0,3): A G F D her cümlede duyulur.
	for seed in range(1, 21):
		var seq := SynthSequencer.motor({"tempo": 52.0, "bars": 2, "density": 0.55, "phrase": "A", "phrase_end": false},
				SynthDsp.make_rng(seed))
		var count: int = seq["strokes"].size()
		assert_between(float(count), 6.0, 7.0, "tohum %d: 12 vuruşun %%55'i (%d)" % [seed, count])
		var pitches := {}
		for note: Dictionary in seq["notes"]:
			pitches[int(note["midi"])] = true
		for midi in [69, 67, 65, 62]:
			assert_true(pitches.has(midi), "tohum %d: motifin %d notası çalar" % [seed, midi])


func test_full_stroke_has_three_strings_and_open_intervals() -> void:
	var seq := SynthSequencer.motor(PLAIN.merged({"bars": 2, "phrase": "A"}, true), SynthDsp.make_rng(3))
	var by_time := _strokes_with_notes(seq)
	var downs := 0
	for entry: Dictionary in by_time:
		if str(entry["stroke"]) != "down":
			continue
		downs += 1
		var notes: Array = entry["notes"]
		assert_eq(notes.size(), 3, "tam vuruş üç tel")
		var lanes := notes.map(func(n: Dictionary) -> int: return int(n["lane"]))
		assert_eq(lanes, [0, 1, 2], "down alttan üste: 3. tel, orta, 1. tel")
		assert_almost(float(notes[2]["t"]) - float(notes[0]["t"]), 2.0 * SynthSequencer.STRUM_GAP, 0.0001, "teller arası 9 ms tarama")
		assert_eq(int(notes[0]["midi"]), 50, "3. tel açık D3 (kambarkan)")
		assert_eq(int(notes[2]["midi"]), 50, "1. tel açık D3 (kambarkan)")
	assert_eq(downs, 4, "iki ölçüde dört tam vuruş")


func test_never_more_than_three_pitches_at_once() -> void:
	for position in ["upper", "lower"]:
		for phrase in ["A", "A2", "B", "open"]:
			var seq := SynthSequencer.motor({"tempo": 52.0, "bars": 8, "density": 0.8, "phrase": phrase, "position": position},
					SynthDsp.make_rng(11))
			assert_true(SynthSequencer.max_simultaneous(seq["notes"]) <= 3,
					"%s/%s: aynı anda en çok üç tel (aynı telde yeni nota eskisini keser)" % [position, phrase])


func test_no_third_on_full_or_up_strokes_only_flicks() -> void:
	var flick_f := 0
	for position in ["upper", "lower"]:
		for phrase in ["A", "A2", "B"]:
			var seq := SynthSequencer.motor(PLAIN.merged({"bars": 2, "phrase": phrase, "position": position}, true), SynthDsp.make_rng(5))
			for note: Dictionary in seq["notes"]:
				var stroke := str(note["stroke"])
				var is_f := posmod(int(note["midi"]), 12) == 5
				if stroke == "down" or stroke == "up":
					assert_false(is_f, "%s/%s: tam ve yukarı vuruşta F yok (D–F–A oluşmaz)" % [position, phrase])
				elif is_f:
					flick_f += 1
	assert_true(flick_f > 0, "F yalnız tek tel fiskesiyle çalar (motifin düşüşünde)")
	# Kerbezde (E Frigyen) üçüncü derece G'dir.
	var e := SynthSequencer.motor(PLAIN.merged({"bars": 2, "phrase": "A", "mode": "e_phrygian"}, true), SynthDsp.make_rng(5))
	for note: Dictionary in e["notes"]:
		if str(note["stroke"]) == "down":
			assert_ne(posmod(int(note["midi"]), 12), 7, "E Frigyen'de tam vuruşta G yok")


func test_motif_falls_a_g_f_d_in_both_positions() -> void:
	for position: String in ["upper", "lower"]:
		var seq := SynthSequencer.motor(PLAIN.merged({"bars": 2, "phrase": "A", "position": position}, true), SynthDsp.make_rng(2))
		var line := PackedInt32Array()
		for note: Dictionary in seq["notes"]:
			var midi := int(note["midi"])
			var stroke := str(note["stroke"])
			var melodic := stroke == "flick" or int(note["lane"]) == SynthSequencer.melody_lane(position, midi, SynthSequencer.tuning("d_dorian"))
			if melodic and (stroke == "flick" or not SynthSequencer.is_third("d_dorian", midi)) and (line.is_empty() or line[-1] != midi):
				line.append(midi)
		var want := [69, 67, 65, 62] if position == "upper" else [57, 55, 53, 50]
		var names := ", ".join(Array(line).map(func(m: int) -> String: return str(m)))
		assert_true(_contains_in_order(line, want), "%s konum: düşüş A G F D (%s) — ezgi %s" % [position, str(want), names])


func test_melody_glides_from_below_and_humanizes() -> void:
	var seq := SynthSequencer.motor(PLAIN.merged({"bars": 2, "phrase": "A"}, true), SynthDsp.make_rng(9))
	var glides := 0
	for note: Dictionary in seq["notes"]:
		var cents := float(note["glide"])
		if cents != 0.0:
			glides += 1
			assert_between(cents, -60.0, -30.0, "ezgi notası −30…−60 sentten kayar")
			assert_between(float(note["glide_s"]), 0.04, 0.07, "kayma 40–70 ms")
	assert_true(glides > 0, "ezgi notası değişince kayma var")
	var s16 := SynthSequencer.sixteenth(52.0)
	for stroke: Dictionary in seq["strokes"]:
		var grid := roundf(float(stroke["t"]) / (2.0 * s16)) * 2.0 * s16
		assert_true(absf(float(stroke["t"]) - grid) <= SynthSequencer.HUMANIZE_TIME + 0.0001, "zaman ±8 ms")


# --- Tel ve tını ----------------------------------------------------------------------------

func test_d3_rings_for_1_5_seconds() -> void:
	var note := SynthKopuz.render({"role": "note", "midi": 50, "seconds": 3.0, "stroke": "flick", "rate": SR}, SynthDsp.make_rng(4))
	var t60 := SynthDsp.t60(SynthDsp.band_limit(note, SR, 110.0, 190.0), SR)
	assert_almost(t60, 1.5, 0.2, "D3'te temel T60 1,5 sn")
	var high := SynthKopuz.render({"role": "note", "midi": 69, "seconds": 3.0, "stroke": "flick", "rate": SR}, SynthDsp.make_rng(4))
	var t60_a4 := SynthDsp.t60(SynthDsp.band_limit(high, SR, 380.0, 500.0), SR)
	assert_true(t60_a4 > 0.0 and t60_a4 < t60, "ince tel kısa titreşir (üs 0,35): A4 %.2f sn < D3 %.2f sn" % [t60_a4, t60])
	var mute := SynthKopuz.render({"role": "note", "midi": 50, "seconds": 1.0, "stroke": "mute", "rate": SR}, SynthDsp.make_rng(4))
	var t60_mute := SynthDsp.t60(SynthDsp.band_limit(mute, SR, 110.0, 190.0), SR)
	assert_true(t60_mute > 0.0 and t60_mute < 0.3, "avuçla bastırılmış tel çabuk söner (%.2f sn)" % t60_mute)


func test_same_seed_gives_the_same_samples() -> void:
	var params := {"tempo": 52.0, "bars": 2, "density": 0.55, "phrase": "A2", "seed": 5212, "rate": SR}
	var a := SynthKopuz.render(params, SynthDsp.make_rng(5212))
	var b := SynthKopuz.render(params, SynthDsp.make_rng(5212))
	assert_eq(a.size(), SynthSequencer.bar_samples(52.0, 2, SR), "cümle tam iki ölçüdür")
	assert_true(a == b, "aynı tohum aynı örnekler")
	var c := SynthKopuz.render(params, SynthDsp.make_rng(5213))
	assert_false(a == c, "başka tohum başka çalış")


func test_coded_kopuz_meets_the_song_measures() -> void:
	var rng := SynthDsp.make_rng(3106)
	var seq := SynthSequencer.motor({"tempo": 52.0, "bars": 2, "density": 1.0, "phrase": "A", "position": "lower"}, rng)
	var pcm := SynthKopuz.render_sequence(seq, SR, rng)
	var onsets := PackedFloat32Array()
	for stroke: Dictionary in seq["strokes"]:
		onsets.append(float(stroke["t"]))
	assert_true(SynthSequencer.strokes_per_second(seq) >= 2.0, "vuruş ≥2,0 / sn")
	var hf := SynthDsp.hf_share(pcm, SR)
	assert_true(hf >= 0.08, "1,28 kHz üstü enerji ≥%%8 (tırnak ve tel sesi): %%%.1f" % (hf * 100.0))
	var decay := SynthDsp.band_decay(pcm, SR, onsets)
	assert_true(decay >= 4.0, "2–6 kHz sönümü ≥4 dB / 100 ms: %.1f" % decay)
	assert_between(SynthDsp.peak(pcm), 0.1, 0.98, "taşma yok, sessiz değil")


func test_phrase_ends_silent_at_the_bar_line() -> void:
	# Playlist cümleleri fade_time 0 ile uç uca biner: çınlayan tel ve nefesli sınırda susmuş olmalı (tık, kesik yok).
	var phrases := {
		"kopuz": SynthKopuz.render({"tempo": 52.0, "bars": 2, "density": 1.0, "phrase": "B", "rate": SR}, SynthDsp.make_rng(8)),
		"hucia": SynthHujia.render({"tempo": 52.0, "bars": 2, "phrase": "a", "rate": SR}, SynthDsp.make_rng(8)),
		"kaval": SynthKaval.render({"tempo": 46.0, "bars": 2, "phrase": "motif", "rate": SR}, SynthDsp.make_rng(8)),
	}
	for name: String in phrases:
		var pcm: PackedFloat32Array = phrases[name]
		assert_eq(pcm.size(), SynthSequencer.bar_samples(52.0 if name != "kaval" else 46.0, 2, SR), "%s cümlesi tam iki ölçü" % name)
		var tail := SynthDsp.rms(pcm, pcm.size() - 64, pcm.size())
		assert_true(tail < 0.002, "%s: cümlenin son örnekleri sessiz (%.4f)" % [name, tail])
		assert_true(SynthDsp.rms(pcm) > 0.005, "%s cümlesi sessiz değil" % name)


func test_control_kopuz_for_the_song_measure_is_baked() -> void:
	assert_true(FileAccess.file_exists(CONTROL_WAV), "şarkı ölçüsünün denetim kopuzu basılmış olmalı (tools/bake_music.sh)")
	var wav := AudioStreamWAV.load_from_file(ProjectSettings.globalize_path(CONTROL_WAV))
	assert_not_null(wav)
	if wav:
		assert_false(wav.stereo, "mono")
		assert_eq(wav.mix_rate, SR, "44,1 kHz")
		assert_almost(wav.get_length(), SynthSequencer.bar_seconds(52.0) * 12, 0.01, "12 ölçü ≈27,7 sn (şarkının planı)")


# --- Yardımcılar -------------------------------------------------------------------------

## Vuruşlar ve o vuruşun notaları (aynı vuruşun telleri 0–18 ms içinde).
static func _strokes_with_notes(seq: Dictionary) -> Array:
	var out: Array = []
	for stroke: Dictionary in seq["strokes"]:
		var t := float(stroke["t"])
		var notes: Array = []
		for note: Dictionary in seq["notes"]:
			var dt := float(note["t"]) - t
			if dt >= -0.0001 and dt < 0.02:
				notes.append(note)
		out.append({"stroke": stroke["stroke"], "notes": notes})
	return out


static func _contains_in_order(line: PackedInt32Array, want: Array) -> bool:
	var k := 0
	for m in line:
		if k < want.size() and m == int(want[k]):
			k += 1
	return k == want.size()
