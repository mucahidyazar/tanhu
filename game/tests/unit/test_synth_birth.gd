extends TestCase
## Doğumun kodla sesleri (Yol Haritası birth-scene; audio.md §3 «Motif ve kip», §4 «Önsöz ekleri», «Ortam döngüleri»):
##   - İlk ağlamanın (newborn_cry, scripts/audio/synth/cry.gd) temel perdesi 350–600 Hz'dir (tarifte ve sesin kendisinde).
##   - Turna çağrısının (crane_call, crane.gd) dar biçimlendiricisi ≈1 kHz'dir; kodla basılan sürünün ve ücretsiz
##     kayıtlardan basılan dosyaların enerjisi 0,8–1,2 kHz bandında toplanır.
##   - Motifin bütünü (motif.gd): D↗A kayışı ve A G F D düşüşü; F yalnız fiskede; aynı anda en çok üç tel.
##   - Aynı tohum aynı örnekleri verir, başka tohum başkasını.
##   - Basılan dosyalar tariflerine uyar; yurt_inside ve ember_crackle ortam döngüsü kuralına uyar (22,05 kHz mono QOA,
##     ileri döngü, döngü noktasında sıçrama yok), ordos bankası geçerlidir.
## Başsız sürücüde ses sahtedir: sesin son onayı kullanıcının kulağındadır (Karar Bekleyenler).

const RECIPE_DIR := "res://data/audio/bake"
const WAV_DIR := "res://audio/gen/_wav"
const BANK := "ordos"
## Tarif dosyası → basılan kimlik (dosya adı kimlikten farklı olabilir: birth_* tarifleri).
const RECIPES := {
	"birth_drone": "birth_drone", "birth_note": "birth_note", "birth_motif": "birth_motif",
	"childhood_drone": "childhood_drone", "childhood_kopuz_a": "childhood_kopuz_a", "childhood_kopuz_b": "childhood_kopuz_b",
	"childhood_kaval_a": "childhood_kaval_a", "childhood_rest": "childhood_rest", "newborn_cry": "newborn_cry",
	"crane_call": "crane_call", "birth_crane_call_v1": "crane_call_v1", "notch": "notch", "ember_crackle": "ember_crackle",
	"yurt_inside": "yurt_inside", "birth_sheep": "sheep", "birth_lamb": "lamb", "birth_horse": "horse_neigh",
}
const TARGETS := {"music": "res://audio/gen/%s.ogg", "sfx": "res://audio/sfx/gen/%s.wav", "ambience": "res://audio/ambience/gen/%s.wav"}
const LOOPS: Array[String] = ["yurt_inside", "ember_crackle"]


func before_each() -> void:
	Engine.time_scale = 1.0


func after_each() -> void:
	Engine.time_scale = 1.0


# --- Ağlama -------------------------------------------------------------------------------------------

func test_cry_pitch_is_350_to_600_hz() -> void:
	# Tarifin eğrisi: kemerin dibi ve tepesi aralıkta (jitter ve tremor dahil).
	for u: float in [0.0, 0.25, 0.5, 0.75, 1.0]:
		for jitter: float in [-0.02, 0.02]:
			var f := SynthCry.pitch_at(u, 1.0, SynthCry.BASE_HZ, jitter)
			assert_between(f, 350.0, 600.0, "Perde eğrisi aralıkta (u %.2f, jitter %.2f): %.1f Hz" % [u, jitter, f])
	# Sesin kendisi: seslendirilen karelerin özilinti perdesi.
	var sr := 32000
	var pcm := SynthCry.render({"rate": sr, "seconds": 6.5}, SynthDsp.make_rng(2344))
	# Yalnız ağlama birimleri ölçülür (soluk alışın ince cıyaklaması ağlamanın perdesi değildir).
	var f0s := PackedFloat32Array()
	for u: Array in SynthCry.UNITS:
		if str(u[1]) == "cry":
			var from := int((float(u[0]) + 0.05) * sr)
			var to := int((float(u[0]) + float(u[2]) - 0.05) * sr)
			f0s.append_array(_voiced_pitches(pcm.slice(from, to), sr))
	assert_true(f0s.size() > 30, "Ağlamanın seslendirilen kareleri ölçülür (%d)" % f0s.size())
	f0s.sort()
	var median := f0s[f0s.size() / 2]
	assert_between(median, 350.0, 600.0, "Ağlamanın perdesinin ortancası 350–600 Hz: %.1f" % median)
	var p10 := f0s[int(f0s.size() * 0.1)]
	var p90 := f0s[int(f0s.size() * 0.9)]
	assert_between(p10, 330.0, 600.0, "Alt onda bir (%.1f Hz)" % p10)
	assert_between(p90, 350.0, 650.0, "Üst onda bir (%.1f Hz; hiperfonasyon kısa)" % p90)


func test_cry_breathes_between_units() -> void:
	# Birimlerin arasında soluk: ağlama birimlerinin ortası soluk alışlardan güçlüdür.
	var sr := 32000
	var pcm := SynthCry.render({"rate": sr, "seconds": 6.5}, SynthDsp.make_rng(5))
	var cries := 0.0
	var breaths := 0.0
	for u: Array in SynthCry.UNITS:
		var mid := float(u[0]) + float(u[2]) * 0.5
		var r := SynthDsp.rms(pcm, int((mid - 0.05) * sr), int((mid + 0.05) * sr))
		if str(u[1]) == "cry":
			cries = maxf(cries, r)
		elif str(u[1]) == "in":
			breaths = maxf(breaths, r)
	assert_true(cries > breaths * 2.0, "Ağlama soluktan güçlü (ağlama %.3f, soluk %.3f)" % [cries, breaths])


# --- Turna --------------------------------------------------------------------------------------------

func test_crane_formant_is_near_1_khz() -> void:
	assert_almost(SynthCrane.FORMANT_HZ, 1000.0, 120.0, "Dar biçimlendirici ≈1 kHz (audio.md §4)")
	assert_true(SynthCrane.FORMANT_Q >= 6.0, "Biçimlendirici dardır (Q %.1f)" % SynthCrane.FORMANT_Q)
	var sr := 22050
	var pcm := SynthCrane.render({"role": "flock", "rate": sr, "seconds": 5.5, "calls": 10}, SynthDsp.make_rng(2347))
	var near := _band_energy(pcm, sr, 800.0, 1200.0)
	for band: Vector2 in [Vector2(300.0, 700.0), Vector2(1300.0, 2000.0), Vector2(2000.0, 4000.0)]:
		var other := _band_energy(pcm, sr, band.x, band.y)
		assert_true(near > other, "Kodla turna: 0,8–1,2 kHz bandı (%.4f) %d–%d Hz bandından (%.4f) güçlü" % [near, band.x, band.y, other])
	# Sürü 8–12 çağrıdır (audio.md §4): çağrılar klibin içinde, sıralı ve ayrık.
	var calls := SynthCrane.schedule({"seconds": 5.5, "calls": 10}, SynthDsp.make_rng(2347))
	assert_between(float(calls.size()), 8.0, 12.0, "Kodla sürü 8–12 çağrı: %d" % calls.size())
	for i in calls.size():
		var c: Array = calls[i]
		assert_between(float(c[0]), 0.0, 5.5 - SynthCrane.CALL_S, "Çağrı klibin içinde (%.2f)" % float(c[0]))
		assert_between(float(c[1]), SynthCrane.F0_RANGE.x, SynthCrane.F0_RANGE.y * 1.07, "Temel perde")
		if i > 0:
			assert_true(float(c[0]) > float((calls[i - 1] as Array)[0]), "Çağrılar sıralı")
	assert_true(_onsets(pcm, sr) >= 5, "Çağrılar seste ayrı ayrı duyulur (%d tepe)" % _onsets(pcm, sr))
	var recipe := _recipe("birth_crane_code")
	assert_between(float(recipe.get("calls", 0)), 8.0, 12.0, "Kodla sürünün tarifi 8–12 çağrı")


func test_baked_crane_calls_peak_near_1_khz() -> void:
	# Oyunun dosyaları ücretsiz kayıtlardandır (crane_call_2, crane_call_1); enerjileri de ≈1 kHz'de toplanır.
	for id in ["crane_call", "crane_call_v1"]:
		var pcm := _wav_pcm(id)
		assert_false(pcm.is_empty(), "%s ara WAV'ı" % id)
		if pcm.is_empty():
			continue
		var near := _band_energy(pcm, 22050, 800.0, 1200.0)
		var low := _band_energy(pcm, 22050, 300.0, 700.0)
		var high := _band_energy(pcm, 22050, 4000.0, 8000.0)
		assert_true(near > low and near > high, "%s: 0,8–1,2 kHz (%.4f) > 300–700 (%.4f), 4–8 kHz (%.4f)" % [id, near, low, high])
	var recipe := _recipe("crane_call")
	assert_eq(str(recipe.get("role", "")), "recording", "Oyunun turnası ücretsiz kayıttır")
	assert_true(str(recipe.get("file", "")).begins_with("assets/_free/sound/crane_call_2/"), "crane_call ← crane_call_2")
	assert_true(str(_recipe("birth_crane_call_v1").get("file", "")).begins_with("assets/_free/sound/crane_call_1/"), "crane_call_v1 ← crane_call_1")


# --- Motif --------------------------------------------------------------------------------------------

func test_motif_rises_d_to_a_and_falls_a_g_f_d() -> void:
	var melody := SynthMotif.melody()
	assert_eq(melody.size(), 5, "Kayış ve dört notalık düşüş")
	var first: Array = melody[0]
	assert_eq(int(first[2]), 50, "Yükseliş D3'ten başlar (kayış)")
	assert_eq(int(first[1]), 57, "Yükseliş A3'e varır (D↗A, 3/2)")
	var fall: Array[int] = []
	for i in range(1, melody.size()):
		fall.append(int((melody[i] as Array)[1]))
	assert_eq(fall, [57, 55, 53, 50] as Array[int], "Düşüş A G F D (alt konum)")
	for i in range(1, melody.size()):
		assert_true(float((melody[i] as Array)[0]) > float((melody[i - 1] as Array)[0]), "Notalar sırayla")
	var seq := SynthMotif.sequence()
	for note: Variant in seq["notes"]:
		var n: Dictionary = note
		if SynthSequencer.is_third("d_dorian", int(n["midi"])):
			assert_eq(str(n["stroke"]), "flick", "F (üçüncü derece) yalnız tek tel fiskesi (K60)")
	assert_true(SynthSequencer.max_simultaneous(seq["notes"]) <= 3, "Aynı anda en çok üç tel")
	# Sesin kendisi: kayışın başı D3, sonu A3 perdesinde.
	var sr := 44100
	var pcm := SynthMotif.render({"rate": sr, "bars": 4}, SynthDsp.make_rng(3))
	assert_eq(pcm.size(), SynthSequencer.bar_samples(52.0, 4, sr), "Dosya tam ölçüdür")
	var tail := SynthDsp.rms(pcm, int(7.0 * sr), int(9.0 * sr))
	assert_true(tail < 0.002, "Motiften sonra sessiz (%.4f): motif bir kez çalar" % tail)


# --- Tohum --------------------------------------------------------------------------------------------

func test_same_seed_gives_the_same_samples() -> void:
	var cases := [
		["cry", {"rate": 16000, "seconds": 1.5, "units": [[0.0, "gasp", 0.2, 0.5], [0.3, "cry", 0.8, 1.0]]}],
		["crane", {"role": "flock", "rate": 16000, "seconds": 1.5, "calls": 3}],
		["notch", {"rate": 16000}],
		["ember", {"role": "ember", "rate": 16000, "seconds": 2.0, "fold": 0.3}],
		["ember", {"role": "yurt", "rate": 16000, "seconds": 2.0, "fold": 0.3}],
		["motif", {"rate": 16000, "bars": 3}],
	]
	for c: Array in cases:
		var script := load("res://scripts/audio/synth/%s.gd" % c[0]) as GDScript
		var a: PackedFloat32Array = script.call("render", c[1], SynthDsp.make_rng(77))
		var b: PackedFloat32Array = script.call("render", c[1], SynthDsp.make_rng(77))
		var other: PackedFloat32Array = script.call("render", c[1], SynthDsp.make_rng(78))
		assert_true(a.size() > 0 and SynthDsp.peak(a) > 0.0, "%s ses üretir" % c[0])
		assert_true(a == b, "%s: aynı tohum aynı örnekler" % c[0])
		if c[0] != "motif":
			assert_false(a == other, "%s: başka tohum başka örnekler" % c[0])
		assert_true(SynthDsp.peak(a) <= 1.0, "%s taşmaz" % c[0])


# --- Basılan dosyalar ---------------------------------------------------------------------------------

func test_baked_files_match_their_recipes() -> void:
	for file: String in RECIPES:
		var id: String = RECIPES[file]
		var recipe := _recipe(file)
		assert_false(recipe.is_empty(), "%s: tarifi data/audio/bake/%s.json" % [id, file])
		assert_eq(str(recipe.get("id", "")), id, "%s.json'un kimliği %s" % [file, id])
		var kind := str(recipe.get("kind", ""))
		if not TARGETS.has(kind):
			fail("%s: tür %s" % [id, kind])
			continue
		var path := str(TARGETS[kind]) % id
		assert_true(ResourceLoader.exists(path), "%s içe aktarılmış (%s)" % [id, path])
		var cfg := ConfigFile.new()
		assert_eq(cfg.load(path + ".import"), OK, "%s.import" % path)
		if kind == "music":
			var ogg := load(path) as AudioStreamOggVorbis
			assert_not_null(ogg)
			if ogg == null:
				continue
			assert_almost(ogg.bpm, float(recipe["tempo"]), 0.001, "%s bpm tarifin temposu" % id)
			assert_eq(ogg.beat_count, int(recipe["bars"]) * 2, "%s tam ölçü" % id)
			assert_eq(ogg.bar_beats, 2, "%s 6/8" % id)
			assert_eq(ogg.loop, bool(recipe.get("loop", false)), "%s döngüsü tarifteki gibi" % id)
		else:
			assert_eq(cfg.get_value("params", "compress/mode"), 2, "%s QOA" % id)
			assert_eq(cfg.get_value("params", "force/mono"), true, "%s mono" % id)
	assert_eq(str(_recipe("newborn_cry").get("source", "")), "code", "İlk ağlama önce kodla basılır (K61; ana oturumun kararı)")
	var free := _recipe("birth_cry_free")
	assert_eq(str(free.get("kind", "")), "wav", "Ücretsiz ağlama karşılaştırma adayıdır, oyuna girmez")
	assert_true(str(free.get("source", "")).begins_with("free:"), "Adayın kaynağı ücretsiz kayıt")


func test_ambience_loops_follow_the_rule() -> void:
	for id in LOOPS:
		var path := "res://audio/ambience/gen/%s.wav" % id
		var cfg := ConfigFile.new()
		assert_eq(cfg.load(path + ".import"), OK, "%s içe aktarılmış" % id)
		assert_eq(cfg.get_value("params", "force/mono"), true, "%s mono" % id)
		assert_eq(cfg.get_value("params", "force/max_rate"), true, "%s hız sınırı" % id)
		assert_eq(cfg.get_value("params", "force/max_rate_hz"), 22050, "%s 22,05 kHz" % id)
		assert_eq(cfg.get_value("params", "compress/mode"), 2, "%s QOA" % id)
		assert_eq(cfg.get_value("params", "edit/loop_mode"), 2, "%s ileri döngü" % id)
		assert_eq(cfg.get_value("params", "edit/loop_end"), -1, "%s bütün dosya döner" % id)
		var pcm := _wav_pcm(id)
		assert_false(pcm.is_empty(), "%s ara WAV'ı" % id)
		if pcm.is_empty():
			continue
		var steps := PackedFloat32Array()
		for i in range(1, pcm.size()):
			steps.append(absf(pcm[i] - pcm[i - 1]))
		steps.sort()
		var p999 := steps[int(steps.size() * 0.999)]
		var seam := absf(pcm[0] - pcm[pcm.size() - 1])
		assert_true(seam <= p999, "%s: döngü noktasındaki sıçrama (%.4f) içerideki %%99,9'luk adımı (%.4f) aşmaz" % [id, seam, p999])
		var head := SynthDsp.rms(pcm, 0, int(0.5 * 22050))
		var tail := SynthDsp.rms(pcm, pcm.size() - int(0.5 * 22050), pcm.size())
		assert_almost(SynthDsp.gain_to_db(head), SynthDsp.gain_to_db(tail), 6.0, "%s: baş ve son yakın düzeyde" % id)


func test_ordos_bank_is_valid() -> void:
	var def := MusicBank.load_def(BANK)
	assert_eq(MusicBank.problems(def), PackedStringArray(), "ordos bankası geçerli")
	assert_eq(Array(MusicBank.clip_names(def)), ["birth", "birth_motif", "childhood"], "Doğum, motif ve Çocukluk klipleri")
	var childhood := MusicBank.clip(def, &"childhood")
	assert_almost(float(childhood.get("tempo", 0)), 72.0, 0.001, "childhood 72 (audio.md §3)")
	assert_eq(str(childhood.get("mode", "")), "major_pent", "childhood majör pentatonik")
	assert_true(DuckTable.STATES.has(&"childhood"), "childhood 22 durumdan")
	var stream := MusicBank.build(def)
	assert_not_null(stream)
	if stream == null:
		return
	var birth := MusicBank.clip_index(def, &"birth")
	var motif := MusicBank.clip_index(def, &"birth_motif")
	assert_true(stream.has_transition(birth, motif), "Doğumdan motife özel geçiş")
	assert_eq(stream.get_transition_from_time(birth, motif), AudioStreamInteractive.TRANSITION_FROM_TIME_IMMEDIATE,
			"Motif ölçü beklemeden başlar (3:22,5)")
	assert_eq(stream.get_transition_to_time(birth, motif), AudioStreamInteractive.TRANSITION_TO_TIME_START, "Motif baştan")
	assert_almost(MusicBank.layer_volume(MusicBank.layers(MusicBank.clip(def, &"birth"))[1]), MusicBank.SILENT_DB, 0.001,
			"Tek uzun nota satır bitene dek susar")
	for layer: Variant in MusicBank.layers(childhood):
		assert_false(MusicBank.is_choir(layer as Dictionary), "Çocukluk'ta koro yok")


# --- Yardımcılar -----------------------------------------------------------------------------------

func _recipe(file: String) -> Dictionary:
	var path := RECIPE_DIR.path_join(file + ".json")
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _wav_pcm(id: String) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var wav := AudioStreamWAV.load_from_file(ProjectSettings.globalize_path(WAV_DIR.path_join(id + ".wav")))
	if wav == null or wav.format != AudioStreamWAV.FORMAT_16_BITS:
		return out
	out.resize(wav.data.size() / 2)
	for i in out.size():
		out[i] = wav.data.decode_s16(i * 2) / 32768.0
	return out


## 40 ms'lik karelerin perdesi: yanlı özilinti (gecikme büyüdükçe toplanan örnek azalır: periyodun katları periyodun
## kendisini geçemez), 250–1.200 Hz'de en büyük tepe, r ≥ 0,3 · r(0). Sessiz ya da perdesiz kare atlanır.
static func _voiced_pitches(pcm: PackedFloat32Array, sr: int) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var win := int(0.04 * sr)
	var lag_min := int(sr / 1200.0)
	var lag_max := int(sr / 250.0)
	var i := 0
	while i + win <= pcm.size():
		var frame := pcm.slice(i, i + win)
		var mean := 0.0
		for v in frame:
			mean += v
		mean /= win
		var r0 := 0.0
		for k in win:
			frame[k] -= mean
			r0 += frame[k] * frame[k]
		if sqrt(r0 / win) > 0.01:
			var best := -INF
			var best_lag := -1
			for lag in range(lag_min, lag_max):
				var r := 0.0
				for k in win - lag:
					r += frame[k] * frame[k + lag]
				if r > best:
					best = r
					best_lag = lag
			if best_lag > 0 and best >= 0.3 * r0:
				out.append(float(sr) / best_lag)
		i += win / 2
	return out


## Bandın ortalama gücü (Goertzel, 20 Hz arayla).
static func _band_energy(pcm: PackedFloat32Array, sr: int, lo: float, hi: float) -> float:
	var total := 0.0
	var count := 0
	var hz := lo
	var n := mini(pcm.size(), sr * 4)
	while hz <= hi:
		var w := TAU * hz / sr
		var c := 2.0 * cos(w)
		var s1 := 0.0
		var s2 := 0.0
		for i in n:
			var s0 := pcm[i] + c * s1 - s2
			s2 = s1
			s1 = s0
		total += (s1 * s1 + s2 * s2 - c * s1 * s2) / float(n)
		count += 1
		hz += 20.0
	return total / maxf(count, 1)


## Zarfın yükselen tepeleri (20 ms'lik RMS, eşiğin üstüne çıkış).
static func _onsets(pcm: PackedFloat32Array, sr: int) -> int:
	var win := int(0.02 * sr)
	var env := PackedFloat32Array()
	var i := 0
	while i + win < pcm.size():
		env.append(SynthDsp.rms(pcm, i, i + win))
		i += win
	var top := 0.0
	for v in env:
		top = maxf(top, v)
	var count := 0
	var above := false
	for v in env:
		if not above and v > top * 0.3:
			count += 1
			above = true
		elif above and v < top * 0.15:
			above = false
	return count
