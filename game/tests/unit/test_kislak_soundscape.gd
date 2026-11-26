extends TestCase
## Kışlak'ın sesi (Yol Haritası kislak-ambience, fauna-sound-bank; audio.md §3, §4; act1.md §14; K59, K61, K65): gündelik müziğin saati
## (winter_day, winter_evening, winter_night), bankanın kuralları (E Frigyen, kerbez; kopuz yok, koro yok; arp ezgide), perdenin rengi
## act_1.tres, ortam döngülerinin içe aktarması ve dikişi, döngülerin kazancı (rüzgâr gündüz 0,6, gece 0,45; buz Tan ve Gece'de, buza
## yakın), Yol Kemikleri'nin 3B uğultusu, hayvan ses bankası (tür başına 2–3 çeşit, hızlar 16 / 22,05 / 32 kHz, bütün banka ≈0,4 MB,
## kümeler tampon paylaşır, horse_snort.wav horse_calm'ın ilk üyesi).

const PROFILE := "kislak"
const BANK := "kislak"
const WAV_DIR := "res://audio/gen/_wav"
const LOOPS: Array[String] = ["wind_winter", "snow_drift", "ice_groan", "bone_hum", "blizzard", "wind_gale"]
## Kümenin örnekleme hızı (audio.md §4: deve, sığır, eşek 16 kHz; kuş ve tarbagan ıslığı 32 kHz; öteki 22,05 kHz).
const FakeMain := preload("res://tests/support/fauna_fake_main.gd")
const RATES := {"cattle_low": 16000, "camel_groan": 16000, "donkey_bray": 16000, "crow": 32000, "eagle_call": 32000, "marmot_whistle": 32000}

var audio: Node
var _trash: Array[Node] = []


func after_each() -> void:
	for n in _trash:
		if is_instance_valid(n):
			n.free()
	_trash.clear()
	if audio and is_instance_valid(audio):
		audio.call(&"stop_all")
		audio.call(&"reset_buses")


func test_daily_state_follows_the_clock() -> void:
	var states: Dictionary = MapSoundscape.load_profile(PROFILE)["states"]
	assert_eq(MapSoundscape.daily_state(&"morning", 540.0, states), &"winter_day", "Sabah")
	assert_eq(MapSoundscape.daily_state(&"noon", 720.0, states), &"winter_day", "Öğle")
	assert_eq(MapSoundscape.daily_state(&"golden", 900.0, states), &"winter_day", "İkindi")
	assert_eq(MapSoundscape.daily_state(&"dawn", 420.0, states), &"winter_evening", "Tan: winter_evening")
	assert_eq(MapSoundscape.daily_state(&"dusk", 1040.0, states), &"winter_evening", "Akşam")
	assert_eq(MapSoundscape.daily_state(&"night", 1300.0, states), &"winter_evening", "Gece 22:30'a dek kazan başı")
	assert_eq(MapSoundscape.daily_state(&"night", 1360.0, states), &"winter_night", "22:30'dan sonra")
	assert_eq(MapSoundscape.daily_state(&"night", 200.0, states), &"winter_night", "Gece yarısından Tan'a")
	assert_eq(MapSoundscape.daily_state(&"", 720.0, states), &"winter_day", "Evre yoksa dakikadan")


func test_bank_is_the_act_one_winter_music() -> void:
	MusicBank.clear_cache()
	var def := MusicBank.load_def(BANK)
	assert_false(def.is_empty(), "Kışlak bankası var")
	assert_eq(MusicBank.problems(def), PackedStringArray(), "Banka kurala uyar")
	assert_eq(MusicBank.clip_names(def), PackedStringArray(["winter_day", "winter_evening", "winter_night"]))
	var tempos := {"winter_day": 72.0, "winter_evening": 58.0, "winter_night": 58.0}
	for clip: Dictionary in MusicBank.clips(def):
		var name := str(clip["name"])
		assert_almost(float(clip["tempo"]), float(tempos[name]), 0.001, "%s temposu (iş 72, dinlenme 58; audio.md §3)" % name)
		assert_eq(str(clip.get("mode", "")), "e_phrygian", "%s E Frigyen" % name)
		for layer: Dictionary in MusicBank.layers(clip):
			assert_false(str(layer.get("name", "")).begins_with("kopuz"), "%s: kopuz kaçış gecesine dek müzikte yok (K59)" % name)
			assert_false(MusicBank.is_choir(layer), "%s: koro yalnız gökte (K59)" % name)
	for id in MusicBank.files(def):
		var recipe := _recipe(id)
		assert_false(recipe.is_empty(), "%s: tarifi var" % id)
		var ogg := load(MusicBank.stream_path(id)) as AudioStreamOggVorbis
		assert_not_null(ogg, "%s içe aktarılmış" % id)
		if ogg == null or recipe.is_empty():
			continue
		assert_almost(ogg.bpm, float(recipe["tempo"]), 0.001, "%s bpm" % id)
		assert_eq(ogg.beat_count, int(recipe["bars"]) * 2, "%s beat_count = bars × 2" % id)
		assert_almost(ogg.get_length(), SynthSequencer.bar_seconds(float(recipe["tempo"])) * int(recipe["bars"]), 0.002, "%s tam ölçü" % id)
		if recipe.has("mode"):
			assert_eq(str(recipe["mode"]), "e_phrygian", "%s kipi" % id)
	var stream := MusicBank.build(def, load("res://data/music/act_1.tres") as MusicColor)
	assert_not_null(stream, "AudioStreamInteractive kurulur")


func test_act_one_color_leads_with_the_harp() -> void:
	var color := load("res://data/music/act_1.tres") as MusicColor
	assert_not_null(color)
	assert_eq(color.act, 1)
	assert_eq(color.lead, &"harp", "Ezgiyi Yüeçi arpı taşır")
	assert_eq(color.layer_db(&"kopuz", "lead"), MusicColor.SILENT_DB, "Kopuz susar (K59)")
	assert_eq(color.layer_db(&"harp", "lead"), 0.0)
	for name in [&"hujia", &"kaval", &"jaw"]:
		assert_eq(color.layer_db(name, "add"), 0.0, "%s perdenin rengi" % name)


func test_ambience_loops_are_seamless_mono_22k() -> void:
	for id in LOOPS:
		var path := "res://audio/ambience/gen/%s.wav" % id
		var cfg := ConfigFile.new()
		assert_eq(cfg.load(path + ".import"), OK, "%s içe aktarılmış" % id)
		assert_eq(cfg.get_value("params", "force/mono"), true, "%s mono" % id)
		assert_eq(cfg.get_value("params", "force/max_rate_hz"), 22050, "%s 22,05 kHz" % id)
		assert_eq(cfg.get_value("params", "compress/mode"), 2, "%s QOA" % id)
		assert_eq(cfg.get_value("params", "edit/loop_mode"), 2, "%s ileri döngü" % id)
		var wav := AudioStreamWAV.load_from_file(ProjectSettings.globalize_path(WAV_DIR.path_join(id + ".wav")))
		assert_not_null(wav, "%s ara WAV'ı" % id)
		if wav == null:
			continue
		var pcm := _pcm(wav)
		var steps := PackedFloat32Array()
		for i in range(1, pcm.size()):
			steps.append(absf(pcm[i] - pcm[i - 1]))
		steps.sort()
		var p999 := steps[int(steps.size() * 0.999)]
		assert_true(absf(pcm[0] - pcm[pcm.size() - 1]) <= p999, "%s: döngü noktası duyulmaz" % id)


func test_bed_gains_follow_the_time_wind_and_ice() -> void:
	var beds: Array = MapSoundscape.load_profile(PROFILE)["beds"]
	var wind: Dictionary = beds[0]
	var ice: Dictionary = beds[2]
	assert_almost(MapSoundscape.bed_gain(wind, {"phase": &"noon"}), 0.6, 1e-6, "Rüzgâr gündüz 0,6 (audio.md §4)")
	assert_almost(MapSoundscape.bed_gain(wind, {"phase": &"night"}), 0.45, 1e-6, "Gece 0,45")
	assert_almost(MapSoundscape.bed_gain(wind, {"phase": &"noon", "wind_k": 1.4}), 0.84, 1e-6, "× windK")
	assert_almost(MapSoundscape.bed_gain(wind, {"phase": &"noon", "base_wind": 0.0}), 0.0, 1e-6, "Tipide taban rüzgâr söner")
	assert_eq(MapSoundscape.bed_gain(ice, {"phase": &"noon", "at": Vector2(140.0, -155.0)}), 0.0, "Buz öğlen inlemez")
	assert_true(MapSoundscape.bed_gain(ice, {"phase": &"night", "at": Vector2(140.0, -150.0)}) > 0.5, "Gece, Buz Geçidi'nde")
	assert_eq(MapSoundscape.bed_gain(ice, {"phase": &"night", "at": Vector2(0.0, 200.0)}), 0.0, "Buzdan uzakta sessiz")
	assert_almost(MapSoundscape.gain_db(-10.0, 1.0), -10.0, 1e-6)
	assert_eq(MapSoundscape.gain_db(-10.0, 0.0), MapSoundscape.SILENT_DB)


func test_soundscape_opens_the_winter_bank_and_beds() -> void:
	audio = get_node_or_null(^"/root/AudioManager")
	assert_not_null(audio, "AudioManager autoload")
	if audio == null:
		return
	var main: Node3D = FakeMain.new()
	add_child(main)
	_trash.append(main)
	var world := Node3D.new()
	main.add_child(world)
	var player := Node3D.new()
	main.add_child(player)
	main.set("player", player)
	player.position = Vector3(40.0, 0.0, -90.0)
	var scape := MapSoundscape.build(world, PROFILE)
	assert_not_null(scape, "Profil kurulur")
	assert_null(MapSoundscape.build(world, "steppe_day"), "Profili olmayan harita sessizdir (deneme haritası)")
	scape._local_clock = GameClock.new(1041, 720.0)
	scape._process(1.0)
	assert_eq(str(audio.call(&"current_music_bank")), BANK, "Kışlak bankası çalar")
	assert_eq(audio.call(&"current_music_state"), &"winter_day", "Öğlen winter_day")
	var color: MusicColor = audio.call(&"music_color")
	assert_eq(color.act if color else -1, 1, "Perdenin rengi act_1")
	var levels := scape.bed_levels()
	assert_true(levels.has("wind_winter") and float(levels["wind_winter"]) > -30.0, "Kış rüzgârı çalar")
	assert_eq(scape.emitter_positions().size(), 2, "En yakın iki Yol Kemiği çalar (RB01, RB02)")
	# Akşam 22:40: winter_night.
	scape._local_clock = GameClock.new(1041, 1360.0)
	scape._process(1.0)
	assert_eq(audio.call(&"current_music_state"), &"winter_night", "22:30'dan sonra winter_night")
	scape.free()
	assert_eq(str(audio.call(&"current_music_bank")), "", "Bırakılınca bankası susar")
	var back: MusicColor = audio.call(&"music_color")
	assert_ne(back.act if back else -1, 1, "Önceki perde rengi geri gelir")
	# Banka ve döngüler hemen bırakılır; ses sunucusu çalış kayıtlarını bir karışımda boşaltır, koşunun sonunda «resources still in
	# use» kalmaz (after_each beklemez).
	audio.call(&"stop_all")
	await get_tree().create_timer(0.3, true, false, true).timeout


# --- Hayvan ses bankası -----------------------------------------------------------------------------------------

func test_fauna_bank_files_rates_and_size() -> void:
	var bank := FaunaBank.new()
	var total := 0
	for cid: String in bank.clusters():
		var files := bank.files(cid)
		var code := 0
		for f in files:
			assert_true(ResourceLoader.exists(f), "%s: %s içe aktarılmış" % [cid, f])
			if not f.begins_with(FaunaBank.DIR):
				continue
			code += 1
			var cfg := ConfigFile.new()
			assert_eq(cfg.load(f + ".import"), OK)
			assert_eq(cfg.get_value("params", "force/mono"), true, "%s mono" % f)
			assert_eq(cfg.get_value("params", "compress/mode"), 2, "%s QOA" % f)
			assert_eq(int(cfg.get_value("params", "force/max_rate_hz")), int(RATES.get(cid, 22050)), "%s hızı (audio.md §4)" % f)
			var dest: Array = cfg.get_value("deps", "dest_files", [])
			for d: String in dest:
				total += FileAccess.open(d, FileAccess.READ).get_length() if FileAccess.file_exists(d) else 0
		assert_between(float(code), 2.0, 3.0, "%s: kodla basılmış 2–3 çeşit" % cid)
	print("    hayvan ses bankası: %.3f MB" % (total / 1e6))
	assert_between(total / 1e6, 0.25, 0.6, "Bütün banka ≈0,4 MB")
	assert_eq(bank.files("horse_calm")[0], "res://audio/sfx/horse_snort.wav", "Bugünkü ahır sesi calm'ın ilk üyesi")


func test_fauna_bank_shares_buffers_by_pitch() -> void:
	var bank := FaunaBank.new()
	assert_eq(bank.pick("lamb", &"call")["cluster"], "sheep")
	assert_almost(float(bank.pick("lamb", &"call")["pitch"]), 1.35, 1e-6, "Kuzu = koyun × 1,35")
	for sp in ["gazelle", "dzeren", "saiga"]:
		assert_eq(bank.pick(sp, &"alarm")["cluster"], "deer_bark", "%s maralın deer_bark'ını paylaşır" % sp)
		assert_true(float(bank.pick(sp, &"alarm")["pitch"]) > 1.0)
	assert_eq(bank.pick("horse", &"fear")["cluster"], "horse_fear")
	assert_eq(bank.pick("horse", &"calm")["cluster"], "horse_calm")
	for sp in ["dog", "fox", "gazelle", "ibex", "boar", "deer", "wolf", "horse", "sheep", "camel", "cattle", "crow", "eagle"]:
		assert_false(bank.pick(sp, &"call").is_empty() and bank.pick(sp, &"alarm").is_empty() and bank.pick(sp, &"howl").is_empty(), "%s'in sesi var" % sp)
	var r := bank.stream("wolf_howl")
	assert_not_null(r, "Randomizer kurulur")
	if r:
		assert_eq(r.streams_count, 3)
		assert_eq(r.playback_mode, AudioStreamRandomizer.PLAYBACK_RANDOM_NO_REPEATS)
		assert_almost(r.random_pitch, 1.06, 1e-6)


func _recipe(id: String) -> Dictionary:
	var path := "res://data/audio/bake/%s.json" % id
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _pcm(wav: AudioStreamWAV) -> PackedFloat32Array:
	var data := wav.data
	var out := PackedFloat32Array()
	out.resize(data.size() / 2)
	for i in out.size():
		out[i] = data.decode_s16(i * 2) / 32768.0
	return out
