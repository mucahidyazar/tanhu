extends TestCase
## Mit sinemasının kodla sesleri (Yol Haritası myth-audio; audio.md §2 «Kıl kobuz», «Boğaz dronu», «Koro», §3 `myth`,
## `erlik`, `tengri`, §4 «Önsöz ekleri»):
##   - Koro yalnız D ve A perdelerini söyler (açık beşli D–A; tarifte ve sesin kendisinde).
##   - Kıl kobuzun atağı 0,25 sn'dir; iki testere ±4 sent, titreşim 5,2 Hz ±12 sent.
##   - Kargıra kayışı A'dan D'ye iner (perde eğrisinde ve sesin kendisinde); Erlik'in sıgıtı kipte kalır.
##   - Aynı tohum aynı örnekleri verir, başka tohum başkasını.
##   - Basılan dosyalar tariflerine uyar; water_reed ortam döngüsü kuralına uyar (22,05 kHz mono QOA, ileri döngü,
##     döngü noktasında sıçrama yok).
## Başsız sürücüde ses sahtedir: sesin son onayı kullanıcının kulağındadır (Karar Bekleyenler).

const RECIPE_DIR := "res://data/audio/bake"
const WAV_DIR := "res://audio/gen/_wav"
const MY_RECIPES: Array[String] = ["myth_kopuz_a", "myth_kopuz_b", "myth_answer_a", "myth_answer_b", "erlik_drone",
	"erlik_kobuz_a", "erlik_kobuz_b", "erlik_slide", "erlik_kopuz", "erlik_answer", "tengri_drone", "choir_tengri",
	"tengri_kobuz_a", "tengri_kobuz_b", "tengri_hujia_a", "tengri_hujia_b", "tengri_rest", "goose_honk", "felt_flap",
	"fire_catch", "breath", "water_reed"]
const TARGETS := {"music": "res://audio/gen/%s.ogg", "sfx": "res://audio/sfx/gen/%s.wav", "ambience": "res://audio/ambience/gen/%s.wav"}


func before_each() -> void:
	Engine.time_scale = 1.0


func after_each() -> void:
	Engine.time_scale = 1.0


# --- Koro -------------------------------------------------------------------------------------------

func test_choir_sings_only_d_and_a() -> void:
	assert_true(SynthChoir.is_open_fifth(SynthChoir.notes({})), "Varsayılan koro açık beşli")
	var recipe := _recipe("choir_tengri")
	assert_true(SynthChoir.is_open_fifth(SynthChoir.notes(recipe)), "Tarifteki perdeler yalnız D ve A: %s" % [recipe.get("notes")])
	assert_false(SynthChoir.is_open_fifth([50, 53, 57] as Array[int]), "Üçlü (F) açık beşli değildir")
	# Sesin kendisi: biçimlendiricisiz kaynakta enerji D3, A3, D4'te; kipin öbür perdelerinde (F, G, C) yok.
	var sr := 22050
	var pcm := SynthChoir.render({"tempo": 48.0, "bars": 1, "rate": sr, "loop": false, "raw": true, "arc": [0.15, 0.85]},
			SynthDsp.make_rng(11))
	var mid := pcm.slice(int(0.6 * sr), int(1.9 * sr))
	var chord := INF
	for midi in [50, 57, 62]:
		chord = minf(chord, _goertzel(mid, sr, SynthDsp.midi_hz(midi)))
	var other := 0.0
	for midi in [53, 55, 60, 65, 67, 72]:
		other = maxf(other, _goertzel(mid, sr, SynthDsp.midi_hz(midi)))
	assert_true(chord > other * 10.0, "Koronun perdeleri D ve A: akor %.4f, öbür perdeler en çok %.4f" % [chord, other])


# --- Kıl kobuz --------------------------------------------------------------------------------------

func test_kobuz_attack_is_a_quarter_second() -> void:
	assert_almost(SynthKobuz.ATTACK_S, 0.25, 0.0001, "Atak 0,25 sn (audio.md §2)")
	assert_almost(SynthKobuz.envelope(0.0, 1.0), 0.0, 0.0001)
	assert_almost(SynthKobuz.envelope(0.125, 1.0), 0.5, 0.0001, "Atağın ortasında yarı")
	assert_almost(SynthKobuz.envelope(0.25, 1.0), 1.0, 0.0001, "0,25 sn'de tam")
	assert_almost(SynthKobuz.DETUNE_CENTS, 4.0, 0.0001, "İki testere ±4 sent")
	assert_almost(SynthKobuz.VIBRATO_HZ, 5.2, 0.0001)
	assert_almost(SynthKobuz.VIBRATO_CENTS, 12.0, 0.0001)
	var sr := 44100
	# Atak vuruşmasız ölçülür: iki testere ±4 sent ≈1 Hz'de vuruşur (koro gibi kabarır), düzeyi oynatır.
	var pcm := SynthKobuz.render_note(57, 1.2, "bow", sr, SynthDsp.make_rng(3), 0.0)
	var win := int(0.01 * sr)
	var plateau := SynthDsp.rms(pcm, int(0.4 * sr), int(0.8 * sr))
	var t90 := -1.0
	var i := 0
	while i + win < pcm.size():
		if SynthDsp.rms(pcm, i, i + win) >= 0.9 * plateau:
			t90 = float(i) / sr
			break
		i += win
	assert_between(t90, 0.15, 0.3, "Yay 0,25 sn'de oturur (%%90'a %.3f sn'de varır)" % t90)
	assert_true(SynthDsp.rms(pcm, int(0.04 * sr), int(0.05 * sr)) < 0.5 * plateau, "Atağın başı yumuşak")
	var scrape := SynthKobuz.render_note(52, 1.0, "scrape", sr, SynthDsp.make_rng(3))
	assert_true(SynthDsp.rms(scrape) > 0.0, "Erlik'in sürtünen yayı da çalar")
	# İki testere ±4 sent: düzey vuruşmayla oynar; akort payı yokken düz kalır.
	var beating := SynthKobuz.render_note(57, 1.2, "bow", sr, SynthDsp.make_rng(3))
	assert_true(_swing(beating, sr) > 1.25, "±4 sent vuruşur (düzey %%%.0f oynar)" % ((_swing(beating, sr) - 1.0) * 100.0))
	assert_true(_swing(pcm, sr) < 1.12, "Akort payı yokken düzey düz")


# --- Kargıra ----------------------------------------------------------------------------------------

func test_kargyraa_slide_falls_from_a_to_d() -> void:
	var sr := 22050.0
	var n := SynthSequencer.bar_samples(52.0, 2, int(sr))
	var curve := SynthThroat.slide_curve({}, sr, n)
	assert_almost(curve[0], SynthDsp.midi_hz(45), 0.01, "Kayış A2'de başlar")
	assert_almost(curve[n - 1], SynthDsp.midi_hz(38), 0.01, "D2'de biter")
	for k in range(1, n):
		assert_true(curve[k] <= curve[k - 1] + 1e-4, "Perde hiç yükselmez (A↘D)")
		if curve[k] > curve[k - 1] + 1e-4:
			break
	# Sesin kendisi (periyot ikilenmesi kapalı): başta A, sonda D.
	var times := SynthThroat.slide_times()
	var pcm := SynthThroat.render({"role": "slide", "growl": 0.0, "tempo": 52.0, "bars": 2, "rate": int(sr)}, SynthDsp.make_rng(5))
	var start := _pitch(pcm, int(sr), float(times["hold_from"]) + 0.15, 0.12)
	var end := _pitch(pcm, int(sr), float(times["glide_to"]) + 0.1, 0.12)
	assert_almost(start, SynthDsp.midi_hz(45), SynthDsp.midi_hz(45) * 0.03, "Başta A2 (%.1f Hz)" % start)
	assert_almost(end, SynthDsp.midi_hz(38), SynthDsp.midi_hz(38) * 0.03, "Sonda D2 (%.1f Hz)" % end)


func test_erlik_drone_stays_in_e_phrygian() -> void:
	var recipe := _recipe("erlik_drone")
	assert_eq(int(recipe.get("root", 0)), 40, "Kargıra dronu E2'de (E Frigyen)")
	assert_eq(str(recipe.get("mode", "")), "e_phrygian")
	for h: int in SynthThroat.KARGYRAA_SYGYT:
		var midi := 40.0 + 12.0 * log(float(h)) / log(2.0)
		assert_true(SynthSequencer.in_mode("e_phrygian", roundi(midi)), "Sıgıtın %d. harmoniği kipte" % h)


# --- Tohum --------------------------------------------------------------------------------------------

func test_same_seed_gives_the_same_samples() -> void:
	var cases := [
		["choir", {"tempo": 48.0, "bars": 1, "rate": 22050, "loop": false}],
		["kobuz", {"phrase": "tengri_a", "tempo": 48.0, "bars": 2, "rate": 22050}],
		["kobuz", {"phrase": "erlik_a", "variant": "scrape", "tempo": 52.0, "bars": 2, "rate": 22050}],
		["throat", {"role": "kargyraa", "root": 40, "tempo": 52.0, "bars": 1, "rate": 22050, "fold": 0.5}],
		["throat", {"role": "slide", "tempo": 52.0, "bars": 2, "rate": 22050}],
		["goose", {"rate": 22050}],
		["felt_flap", {"rate": 22050}],
		["fire_catch", {"rate": 22050}],
		["breath", {"rate": 22050}],
		["water", {"seconds": 3.0, "fold": 0.5, "rate": 22050}],
	]
	for c: Array in cases:
		var script := load("res://scripts/audio/synth/%s.gd" % c[0]) as GDScript
		var a: PackedFloat32Array = script.call("render", c[1], SynthDsp.make_rng(77))
		var b: PackedFloat32Array = script.call("render", c[1], SynthDsp.make_rng(77))
		var other: PackedFloat32Array = script.call("render", c[1], SynthDsp.make_rng(78))
		assert_true(a.size() > 0 and SynthDsp.peak(a) > 0.0, "%s ses üretir" % c[0])
		assert_true(a == b, "%s: aynı tohum aynı örnekler" % c[0])
		assert_false(a == other, "%s: başka tohum başka örnekler" % c[0])
		assert_true(SynthDsp.peak(a) <= 1.0, "%s taşmaz" % c[0])


# --- Basılan dosyalar ---------------------------------------------------------------------------------

func test_baked_files_match_their_recipes() -> void:
	for id in MY_RECIPES:
		var recipe := _recipe(id)
		assert_false(recipe.is_empty(), "%s: tarifi data/audio/bake/%s.json" % [id, id])
		var kind := str(recipe.get("kind", ""))
		assert_true(TARGETS.has(kind), "%s: tür %s" % [id, kind])
		if not TARGETS.has(kind):
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
	var goose := _recipe("goose_honk")
	assert_true(str(goose.get("source", "")).begins_with("free:assets/_free/sound/geese_distant/"),
			"Uzak kaz ücretsiz kayıttan (geese_distant, kamu malı); kodla basılan karşılaştırma adayı")
	assert_eq(str(goose.get("instrument", "")), "goose", "Kodla basılan aday tarifte durur (--source=code)")


func test_water_reed_is_an_ambience_loop() -> void:
	var path := "res://audio/ambience/gen/water_reed.wav"
	var cfg := ConfigFile.new()
	assert_eq(cfg.load(path + ".import"), OK, "water_reed içe aktarılmış")
	assert_eq(cfg.get_value("params", "force/mono"), true)
	assert_eq(cfg.get_value("params", "force/max_rate"), true)
	assert_eq(cfg.get_value("params", "force/max_rate_hz"), 22050)
	assert_eq(cfg.get_value("params", "compress/mode"), 2, "QOA")
	assert_eq(cfg.get_value("params", "edit/loop_mode"), 2, "ileri döngü")
	assert_eq(cfg.get_value("params", "edit/loop_end"), -1, "bütün dosya döner")
	var wav := AudioStreamWAV.load_from_file(ProjectSettings.globalize_path(WAV_DIR.path_join("water_reed.wav")))
	assert_not_null(wav, "ara WAV")
	if wav == null:
		return
	assert_eq(wav.mix_rate, 22050)
	var pcm := PackedFloat32Array()
	pcm.resize(wav.data.size() / 2)
	for i in pcm.size():
		pcm[i] = wav.data.decode_s16(i * 2) / 32768.0
	var steps := PackedFloat32Array()
	for i in range(1, pcm.size()):
		steps.append(absf(pcm[i] - pcm[i - 1]))
	steps.sort()
	var p999 := steps[int(steps.size() * 0.999)]
	var seam := absf(pcm[0] - pcm[pcm.size() - 1])
	assert_true(seam <= p999, "Döngü noktasındaki sıçrama (%.4f) içerideki %%99,9'luk adımı (%.4f) aşmaz" % [seam, p999])
	var head := SynthDsp.rms(pcm, 0, int(0.5 * wav.mix_rate))
	var tail := SynthDsp.rms(pcm, pcm.size() - int(0.5 * wav.mix_rate), pcm.size())
	assert_almost(SynthDsp.gain_to_db(head), SynthDsp.gain_to_db(tail), 3.0, "Baş ve son aynı düzeyde")


# --- Yardımcılar ---------------------------------------------------------------------------------

static func _recipe(id: String) -> Dictionary:
	var path := RECIPE_DIR.path_join(id + ".json")
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## 0,3–1,0 sn arasında 25 ms'lik RMS'in en büyüğünün en küçüğüne oranı.
static func _swing(pcm: PackedFloat32Array, sr: int) -> float:
	var lo := INF
	var hi := 0.0
	var t := 0.3
	while t < 1.0:
		var r := SynthDsp.rms(pcm, int(t * sr), int((t + 0.025) * sr))
		lo = minf(lo, r)
		hi = maxf(hi, r)
		t += 0.025
	return hi / maxf(lo, 1e-9)


## Goertzel: hz'deki gücün büyüklüğü (pencerenin uzunluğuyla bölünmüş).
static func _goertzel(buf: PackedFloat32Array, sr: int, hz: float) -> float:
	var w := TAU * hz / float(sr)
	var c := 2.0 * cos(w)
	var s1 := 0.0
	var s2 := 0.0
	for i in buf.size():
		var s0 := buf[i] + c * s1 - s2
		s2 = s1
		s1 = s0
	var power := s1 * s1 + s2 * s2 - c * s1 * s2
	return sqrt(maxf(power, 0.0)) / float(buf.size())


## Pencerede temel perde (Hz; 60–160 Hz arası öz ilinti). Alt katlara düşmemek için en büyük tepenin %85'ini aşan
## ilk gecikme seçilir.
static func _pitch(buf: PackedFloat32Array, sr: int, at: float, seconds: float) -> float:
	var start := int(at * sr)
	var n := int(seconds * sr)
	var lo := int(sr / 160.0)
	var hi := int(sr / 60.0)
	var scores := PackedFloat32Array()
	scores.resize(hi + 1)
	var best := 0.0
	for lag in range(lo, hi + 1):
		var s := 0.0
		for i in n:
			s += buf[start + i] * buf[start + i + lag]
		scores[lag] = s
		best = maxf(best, s)
	for lag in range(lo, hi + 1):
		if scores[lag] >= 0.85 * best and (lag == hi or scores[lag] >= scores[lag + 1]):
			return float(sr) / float(lag)
	return 0.0
