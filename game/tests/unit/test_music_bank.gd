extends TestCase
## Müzik motoru (K59, K61; audio.md §3 «Godot'da müzik», godot.md §3.3): MusicBank'ın kurduğu AudioStreamInteractive
## (klip adı durum kimliği; klip AudioStreamSynchronized; 0. katman vuruş bilgili düz Ogg; cümle katmanları shuffle'lı,
## fade_time 0 Playlist; geçiş NEXT_BAR + FADE_CROSS), koro kuralı (K59: yalnız tengri ve dawn), perde rengi
## (MusicColor, data/music/act_0.tres), AudioManager'ın müzik API'si (set_music_bank, set_music_state,
## set_layer_db) ve araçla basılan dosyalar (tools/bake_music.sh: audio/gen/, audio/ambience/gen/).
## Başsız sürücüde ses sahtedir: geçişler ve katman sesleri yapı ve değer olarak sınanır; kodla basılan kamp
## müziğinin ve rüzgârın son onayı kullanıcının kulağındadır (Karar Bekleyenler).

const AudioManagerScript := preload("res://scripts/audio/audio_manager.gd")
const CAMP := "camp"
const CAMP_CLIPS := ["camp", "camp_night", "camp_bard"]
const WAV_DIR := "res://audio/gen/_wav"
const FAST := 8.0

var audio: Node


func after_each() -> void:
	Engine.time_scale = 1.0
	if is_instance_valid(audio):
		audio.stop_all()
		audio.reset_buses()
		audio.free()
	audio = null
	MusicBank.clear_cache()


# --- Banka verisi ve kurulum -----------------------------------------------------------------

func test_every_bank_is_valid() -> void:
	var ids := MusicBank.bank_ids()
	assert_true(ids.has(CAMP), "kamp bankası data/audio/banks/camp.json'da")
	for id in ids:
		var problems := MusicBank.problems(MusicBank.load_def(id))
		assert_eq(problems, PackedStringArray(), "%s bankası: %s" % [id, "; ".join(problems)])


func test_camp_bank_clips_are_music_states() -> void:
	var def := MusicBank.load_def(CAMP)
	assert_eq(Array(MusicBank.clip_names(def)), CAMP_CLIPS, "klip adı müzik durumunun kimliğidir")
	for name: String in CAMP_CLIPS:
		assert_true(DuckTable.STATES.has(StringName(name)), "%s audio.md §3'ün durumlarından" % name)
	assert_eq(MusicBank.menu_source(def), "elevenlabs", "kulak onayına dek menü ElevenLabs parçasını çalar")
	var stream := MusicBank.build(def)
	assert_not_null(stream)
	if stream == null:
		return
	assert_eq(stream.clip_count, CAMP_CLIPS.size())
	for i in CAMP_CLIPS.size():
		assert_eq(String(stream.get_clip_name(i)), CAMP_CLIPS[i])
		assert_true(stream.get_clip_stream(i) is AudioStreamSynchronized, "%s bir AudioStreamSynchronized" % CAMP_CLIPS[i])


func test_layer_zero_is_a_beat_aware_ogg() -> void:
	var def := MusicBank.load_def(CAMP)
	var stream := MusicBank.build(def)
	for i in stream.clip_count:
		var sync := stream.get_clip_stream(i) as AudioStreamSynchronized
		var tempo := float(MusicBank.clip(def, stream.get_clip_name(i)).get("tempo", 0.0))
		var drone := sync.get_sync_stream(0) as AudioStreamOggVorbis
		assert_not_null(drone, "%s: 0. katman düz Ogg (dron)" % stream.get_clip_name(i))
		if drone == null:
			continue
		assert_true(drone.bpm > 0.0, "bpm > 0")
		assert_almost(drone.bpm, tempo, 0.001, "bpm klibin temposu (noktalı dörtlük)")
		assert_eq(drone.bar_beats, 2, "6/8: bar_beats 2")
		assert_true(drone.beat_count > 0 and drone.beat_count % 2 == 0, "beat_count tam ölçü")
		assert_true(drone.loop, "dron döner")
		assert_almost(drone.get_length(), drone.beat_count * 60.0 / drone.bpm, 0.01, "dosya tam vuruş sayısı kadardır")


func test_phrase_layers_are_shuffled_playlists_without_fade() -> void:
	var def := MusicBank.load_def(CAMP)
	var stream := MusicBank.build(def)
	var camp := stream.get_clip_stream(MusicBank.clip_index(def, &"camp")) as AudioStreamSynchronized
	var table := MusicBank.layer_table(def)
	assert_eq(table[&"camp"], {&"drone": 0, &"kopuz": 1, &"hujia": 2}, "katman adı → indeks")
	var kopuz := camp.get_sync_stream(1) as AudioStreamPlaylist
	assert_not_null(kopuz, "kopuz katmanı bir Playlist")
	if kopuz == null:
		return
	assert_true(kopuz.shuffle, "shuffle açık")
	assert_almost(kopuz.fade_time, 0.0, 0.0001, "fade_time 0: cümleler ölçü sınırında uç uca")
	assert_true(kopuz.loop)
	assert_eq(kopuz.stream_count, 4 + 2 + 2 + 1, "ağırlık kopya sayısıdır: A ×4, A' ×2, B ×2, boş ×1")
	var counts := {}
	for i in kopuz.stream_count:
		var ogg := kopuz.get_list_stream(i) as AudioStreamOggVorbis
		assert_not_null(ogg)
		if ogg == null:
			continue
		var file := ogg.resource_path.get_file().get_basename()
		counts[file] = int(counts.get(file, 0)) + 1
		assert_almost(ogg.bpm, 52.0, 0.001, "cümle vuruş bilgilidir: Playlist beat_count vuruşta değiştirir")
		assert_eq(ogg.beat_count, 4, "cümle iki ölçü")
		assert_false(ogg.loop, "cümle dönmez")
	assert_eq(counts, {"camp_kopuz_a": 4, "camp_kopuz_a2": 2, "camp_kopuz_b": 2, "camp_rest": 1})


func test_transitions_wait_for_the_bar_and_crossfade() -> void:
	var def := MusicBank.load_def(CAMP)
	var stream := MusicBank.build(def)
	var any := AudioStreamInteractive.CLIP_ANY
	assert_true(stream.has_transition(any, any), "varsayılan geçiş")
	assert_eq(stream.get_transition_from_time(any, any), AudioStreamInteractive.TRANSITION_FROM_TIME_NEXT_BAR, "ölçü sınırında")
	assert_eq(stream.get_transition_to_time(any, any), AudioStreamInteractive.TRANSITION_TO_TIME_START)
	assert_eq(stream.get_transition_fade_mode(any, any), AudioStreamInteractive.FADE_CROSS, "çapraz geçiş")
	assert_between(stream.get_transition_fade_beats(any, any), 2.0, 4.0, "2–4 vuruş")
	var camp := MusicBank.clip_index(def, &"camp")
	var night := MusicBank.clip_index(def, &"camp_night")
	assert_true(stream.has_transition(camp, night))
	assert_almost(stream.get_transition_fade_beats(camp, night), 4.0, 0.001, "gündelik ↔ gündelik 4 vuruş")


func test_choir_only_in_tengri_and_dawn() -> void:
	var def := {"id": "test", "version": 1, "clips": [
		{"name": "camp", "tempo": 52, "layers": [
			{"name": "drone", "file": "camp_drone"},
			{"name": "choir_sky", "file": "choir_tengri"}]},
		{"name": "tengri", "tempo": 52, "layers": [
			{"name": "drone", "file": "camp_drone"},
			{"name": "choir_sky", "file": "choir_tengri"}]}]}
	assert_false(MusicBank.choir_allowed(&"camp"))
	assert_true(MusicBank.choir_allowed(&"tengri") and MusicBank.choir_allowed(&"dawn"), "koro gök içindir (K59)")
	var problems := MusicBank.problems(def)
	assert_true(Array(problems).any(func(p: String) -> bool: return p.begins_with("camp/choir_sky") and p.contains("koro")),
			"problems() izin dışı koroyu yazar: %s" % "; ".join(problems))
	assert_false(Array(problems).any(func(p: String) -> bool: return p.begins_with("tengri/choir_sky") and p.contains("koro")),
			"tengri'de koro serbest")
	expect_errors(["koro"])
	var stream := MusicBank.build(def)
	var camp := stream.get_clip_stream(0) as AudioStreamSynchronized
	assert_null(camp.get_sync_stream(1), "izin dışı klipte koro katmanı kurulmaz")
	assert_not_null(camp.get_sync_stream(0), "dron kurulur")


func test_problems_catch_a_broken_bank() -> void:
	var def := {"id": "bozuk", "version": 1, "menu_source": "radyo", "transition": {"from": "yarin"}, "clips": [
		{"name": "camp", "tempo": 52, "layers": [
			{"name": "kopuz", "phrases": [{"file": "camp_kopuz_a", "copies": 1}]},
			{"name": "drone", "file": "boyle_bir_dosya_yok"}]}]}
	var text := "; ".join(MusicBank.problems(def))
	assert_true(text.contains("menu_source"), "bilinmeyen menü kaynağı")
	assert_true(text.contains("yarin"), "bilinmeyen geçiş")
	assert_true(text.contains("0. katman"), "0. katman düz Ogg olmalı")
	assert_true(text.contains("boyle_bir_dosya_yok"), "eksik dosya")


func test_act_0_color_sets_lead_add_and_rest_copies() -> void:
	var color := AudioManagerScript.load_music_color(0)
	assert_not_null(color, "data/music/act_0.tres bir MusicColor")
	if color == null:
		return
	assert_eq(color.act, 0)
	assert_eq(color.lead, &"kopuz", "Önsöz'ün ezgisi ozanın kopuzu")
	assert_eq(color.motif_clip, &"birth", "motifin bütünü doğumda bir kez")
	assert_eq(color.rest_copies, 1)
	var def := MusicBank.load_def(CAMP)
	var camp_index := MusicBank.clip_index(def, &"camp")
	var with_color := MusicBank.build(def, color).get_clip_stream(camp_index) as AudioStreamSynchronized
	assert_eq((with_color.get_sync_stream(1) as AudioStreamPlaylist).stream_count, 9, "act_0: boş cümle bir kopya")
	assert_almost(with_color.get_sync_stream_volume(2), -7.0, 0.001, "hucia act_0'ın eklediği renktir")
	var other := MusicColor.new()
	other.lead = &"harp"
	other.rest_copies = 3
	var colored := MusicBank.build(def, other).get_clip_stream(camp_index) as AudioStreamSynchronized
	assert_eq((colored.get_sync_stream(1) as AudioStreamPlaylist).stream_count, 11, "rest_copies ezgi katmanının boş kopyasıdır")
	assert_almost(colored.get_sync_stream_volume(1), MusicColor.SILENT_DB, 0.001, "ezgiyi başka çalgı taşıyınca kopuz susar")
	assert_almost(colored.get_sync_stream_volume(2), MusicColor.SILENT_DB, 0.001, "listede olmayan renk susar")
	assert_almost(colored.get_sync_stream_volume(0), -6.0, 0.001, "öbeksiz dron perde renginden etkilenmez")


# --- AudioManager'ın müzik API'si ------------------------------------------------------------

func test_set_music_bank_and_state() -> void:
	audio = _manager()
	assert_eq(audio.current_music_state(), &"", "başta banka çalmıyor")
	assert_true(audio.set_music_bank(CAMP, &"camp_bard", 0.1), "kamp bankası camp_bard ile başlar")
	assert_eq(audio.current_music_state(), &"camp_bard")
	assert_eq(audio.current_music_bank(), CAMP)
	var player: AudioStreamPlayer = audio.bank_player()
	assert_true(player.playing, "bankanın oynatıcısı çalar")
	assert_eq(player.bus, &"Music")
	assert_true(player.stream is AudioStreamInteractive)
	assert_eq((player.stream as AudioStreamInteractive).initial_clip, 2, "başlangıç klibi istenen durum")
	assert_true(audio.set_music_state(&"camp"), "aynı dünyada klip değişir")
	assert_eq(audio.current_music_state(), &"camp")
	assert_false(audio.set_music_state(&"tengri"), "bankada olmayan durum")
	assert_eq(audio.current_music_state(), &"camp", "durum değişmez")
	assert_false(audio.set_music_bank("boyle_bir_banka_yok", &"camp"), "olmayan banka sessizce false")
	assert_true(audio.set_music_bank(CAMP, &"camp_night"), "çalan bankada set_music_bank durumu değiştirir")
	assert_eq(audio.current_music_state(), &"camp_night")
	audio.stop_music_bank(0.0)
	assert_eq(audio.current_music_state(), &"")
	await _settle()


func test_set_layer_db_walks_the_sync_volume() -> void:
	Engine.time_scale = FAST
	audio = _manager()
	assert_true(audio.set_music_bank(CAMP, &"camp_bard", 0.1))
	var sync: AudioStreamSynchronized = audio.music_clip_stream(&"camp_bard")
	assert_almost(sync.get_sync_stream_volume(0), -4.0, 0.001, "dron bankanın sesiyle başlar")
	assert_true(audio.set_layer_db(&"drone", -40.0, 4.6), "dron şarkının çıkışında 4,6 sn'de söner (camp_bard)")
	assert_true(await _until(func() -> bool: return sync.get_sync_stream_volume(0) < -4.5), "katman sesi yürümeye başlar")
	var mid := sync.get_sync_stream_volume(0)
	assert_true(mid > -40.0, "küçük adımlarla yürür, sıçramaz: %.1f dB" % mid)
	assert_true(await _until(func() -> bool: return sync.get_sync_stream_volume(0) <= -40.0 + 0.01), "hedefe varır")
	assert_almost(sync.get_sync_stream_volume(0), -40.0, 0.01, "tween get_sync_stream_volume'a ulaşır")
	assert_almost(audio.layer_db(&"drone"), -40.0, 0.01)
	assert_false(audio.set_layer_db(&"koro", -6.0, 1.0), "klipte olmayan katman")
	await _settle()


func test_bank_to_bank_crossfades_on_two_players() -> void:
	audio = _manager()
	assert_true(audio.set_music_bank(CAMP, &"camp_bard", 0.1))
	var first: AudioStreamPlayer = audio.bank_player()
	# İkinci dünya bankası (ör. mit sineması): kamp dosyalarıyla kurulan deneme bankası, veri önbelleğe konur.
	MusicBank._defs["deneme"] = {"id": "deneme", "version": 1, "clips": [
		{"name": "myth", "tempo": 52, "layers": [{"name": "drone", "file": "camp_drone", "db": -3.0}]}]}
	assert_true(audio.set_music_bank("deneme", &"myth", 1.0), "bankadan bankaya geçiş")
	var second: AudioStreamPlayer = audio.bank_player()
	assert_ne(second, first, "yeni banka öbür oynatıcıda başlar")
	assert_true(second.playing and first.playing, "eskisi sönerken yenisi çalar (çapraz geçiş)")
	assert_eq(audio.current_music_bank(), "deneme")
	assert_eq(audio.current_music_state(), &"myth")
	await _settle()


func test_menu_plays_the_elevenlabs_track_until_approved() -> void:
	audio = _manager()
	audio.play_music(&"menu", 0.1)
	var music := audio.get_node(^"MusicPlayer") as AudioStreamPlayer
	assert_true(music.playing, "menü ElevenLabs parçasını çalar (menu_source elevenlabs)")
	assert_false(audio.bank_player().playing)
	assert_true(audio.set_music_bank(CAMP, &"camp_bard", 2.0), "Yeni Oyun: menü parçasından camp_bard'a 2 sn")
	assert_true(audio.bank_player().playing)
	music.stop()
	await _settle()


# --- Basılan dosyalar ----------------------------------------------------------------------------

func test_baked_files_match_their_recipes() -> void:
	for id in MusicBank.files(MusicBank.load_def(CAMP)):
		var recipe := _recipe(id)
		assert_false(recipe.is_empty(), "%s: tarifi data/audio/bake/%s.json" % [id, id])
		var ogg := load(MusicBank.stream_path(id)) as AudioStreamOggVorbis
		assert_not_null(ogg, "%s içe aktarılmış" % id)
		if ogg == null or recipe.is_empty():
			continue
		assert_almost(ogg.bpm, float(recipe["tempo"]), 0.001, "%s bpm tarifin temposu" % id)
		assert_eq(ogg.beat_count, int(recipe["bars"]) * 2, "%s beat_count = bars × 2" % id)
		assert_eq(ogg.loop, bool(recipe.get("loop", false)), "%s döngüsü tarifteki gibi" % id)
		assert_almost(ogg.get_length(), SynthSequencer.bar_seconds(float(recipe["tempo"])) * int(recipe["bars"]), 0.002,
				"%s tam ölçüdür" % id)


func test_camp_music_is_small() -> void:
	var total := 0
	for id in MusicBank.files(MusicBank.load_def(CAMP)):
		total += FileAccess.get_file_as_bytes(MusicBank.stream_path(id)).size()
	assert_true(total < 2 * 1024 * 1024, "kamp bankası müzik havuzunun (16 MiB) küçük bir payı: %.2f MiB" % (total / 1048576.0))


func test_drone_and_wind_loops_have_no_seam() -> void:
	for pair: Array in [["camp_drone", 22050], ["camp_night_drone", 22050], ["wind_steppe", 22050]]:
		var path := ProjectSettings.globalize_path(WAV_DIR.path_join(str(pair[0]) + ".wav"))
		var wav := AudioStreamWAV.load_from_file(path)
		assert_not_null(wav, "%s ara WAV'ı" % pair[0])
		if wav == null:
			continue
		assert_eq(wav.mix_rate, int(pair[1]))
		var pcm := _pcm(wav)
		var steps := PackedFloat32Array()
		for i in range(1, pcm.size()):
			steps.append(absf(pcm[i] - pcm[i - 1]))
		steps.sort()
		var p999 := steps[int(steps.size() * 0.999)]
		var seam := absf(pcm[0] - pcm[pcm.size() - 1])
		assert_true(seam <= p999, "%s: döngü noktasındaki sıçrama (%.4f) dosyanın içindeki %%99,9'luk adımı (%.4f) aşmaz" % [pair[0], seam, p999])
		var head := SynthDsp.rms(pcm, 0, int(0.25 * wav.mix_rate))
		var tail := SynthDsp.rms(pcm, pcm.size() - int(0.25 * wav.mix_rate), pcm.size())
		assert_almost(SynthDsp.gain_to_db(head), SynthDsp.gain_to_db(tail), 3.0, "%s: baş ve son aynı düzeyde" % pair[0])


func test_wind_steppe_is_an_ambience_loop() -> void:
	var path := "res://audio/ambience/gen/wind_steppe.wav"
	var cfg := ConfigFile.new()
	assert_eq(cfg.load(path + ".import"), OK, "wind_steppe içe aktarılmış")
	assert_eq(cfg.get_value("params", "force/mono"), true)
	assert_eq(cfg.get_value("params", "force/max_rate_hz"), 22050)
	assert_eq(cfg.get_value("params", "compress/mode"), 2, "QOA")
	assert_eq(cfg.get_value("params", "edit/loop_mode"), 2, "ileri döngü")
	audio = _manager()
	assert_true(audio.set_ambience_layer(&"wind_steppe", -12.0, 0.0), "AudioManager rüzgâr katmanını kimlikten bulur")
	assert_almost(audio.ambience_layer_db(&"wind_steppe"), -12.0, 0.001)
	await _settle()


# --- Kampın gece çayırı ----------------------------------------------------------------------

## Mitin başı alçak sessizliği kaldırır; bırakılmış kampın cırcır böcekleri o an geri gelmemeli (mit panoları, Ordos'un şafağı).
func test_released_camp_keeps_the_meadow_silent() -> void:
	audio = _manager()
	audio.play_ambience(0.0)
	await _wait_tweens()
	var volume := func() -> float: return db_to_linear((audio.get(&"_ambience") as AudioStreamPlayer).volume_db)
	assert_almost(volume.call(), AudioManagerScript.AMBIENCE_VOLUME, 0.001, "Menüde çayır duyulur")
	audio.low_silence(true, 0.0)
	await _wait_tweens()
	assert_true(volume.call() < 0.001, "Alçak sessizlikte çayır susar")
	audio.suspend_meadow(true, 0.0)
	assert_true(audio.is_meadow_suspended())
	audio.low_silence(false, 0.0)
	await _wait_tweens()
	assert_true(volume.call() < 0.001, "Kamp bırakılmışken sessizliğin kalkması çayırı geri getirmez")
	audio.suspend_meadow(false, 0.0)
	await _wait_tweens()
	assert_almost(volume.call(), AudioManagerScript.AMBIENCE_VOLUME, 0.001, "Kamp geri gelince çayır duyulur")
	await _settle()


## Kamp, alçak sessizlik sürerken geri gelirse (atlama) çayır sessizliğin kalkışını bekler ve eski düzeyine döner.
func test_meadow_waits_for_the_low_silence_to_lift() -> void:
	audio = _manager()
	audio.play_ambience(0.0)
	await _wait_tweens()
	var volume := func() -> float: return db_to_linear((audio.get(&"_ambience") as AudioStreamPlayer).volume_db)
	audio.low_silence(true, 0.0)
	audio.suspend_meadow(true, 0.0)
	audio.suspend_meadow(false, 0.0)
	await _wait_tweens()
	assert_true(volume.call() < 0.001, "Sessizlik sürüyor")
	audio.low_silence(false, 0.0)
	await _wait_tweens()
	assert_almost(volume.call(), AudioManagerScript.AMBIENCE_VOLUME, 0.001, "Sessizlik kalkınca geri gelir")
	await _settle()


# --- Yardımcılar -------------------------------------------------------------------------

func _wait_tweens() -> void:
	await get_tree().create_timer(0.05, true, false, true).timeout


func _manager() -> Node:
	var m: Node = AudioManagerScript.new()
	add_child(m)
	return m


static func _recipe(id: String) -> Dictionary:
	var path := "res://data/audio/bake".path_join(id + ".json")
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func _pcm(wav: AudioStreamWAV) -> PackedFloat32Array:
	var data := wav.data
	var out := SynthDsp.zeros(data.size() / 2)
	for i in out.size():
		out[i] = data.decode_s16(i * 2) / 32768.0
	return out

## Koşul doğru olana dek kare kare bekler; `timeout` gerçek saniye geçerse vazgeçer. Koşulun son değerini döndürür.
func _until(condition: Callable, timeout: float = 3.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while not condition.call():
		if Time.get_ticks_msec() > deadline:
			return false
		await wait_frames(1)
	return true


## Oynatıcıları durdurur ve ses sunucusuna çalış kayıtlarını boşaltması için zaman tanır (gerçek zaman; koşu
## burada biterse çıkışta «sızıntı» yazılmasın).
func _settle() -> void:
	audio.stop_all()
	await get_tree().create_timer(0.3, true, false, true).timeout
