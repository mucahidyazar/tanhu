extends TestCase
## Voice veri yolu ve konuşmada kısma (K78; audio.md §1 «Konuşmada kısma», godot.md §3.3): yol düzeni
## (default_bus_layout.tres), DuckTable'ın 22 durumu ve zarfı, AudioManager'ın play_line / play_song / stop_line'ı,
## ana sözde Amplify ve EQ, sistem sözünde yan zincirli kompresör, kara ve alçak sessizlik, satırların arka planda
## yüklenmesi.
## Başsız sürücüde ses sahtedir: kısma yol efektlerinin değeri olarak sınanır; kompresörün eşiği ve oranı, kısmanın
## son ayarı kullanıcının kulağındadır (Karar Bekleyenler). Zaman Engine.time_scale ile hızlanır (tween'ler ve
## zamanlayıcılar ölçeklenir); her testten sonra 1'e döner. Her test kendi AudioManager örneğini kurar; yolların
## efektleri ortaktır, after_each onları başlangıç hâline döndürür.

const AudioManagerScript := preload("res://scripts/audio/audio_manager.gd")
## Dosyasız satır: şarkının ilk dizesinin altyazısı (ayrıca okunmaz, file null); seconds kadar altyazıyla akar.
const SILENT_LINE := "act0.bard.1"
## Dosyalı Erlik satırı (fx erlik).
const ERLIK_LINE := "act0.myth.5"
const SONG := "act0.bard.song"
const FAST := 8.0
const EPS := 0.05

var audio: Node


func before_each() -> void:
	audio = AudioManagerScript.new()
	add_child(audio)


func after_each() -> void:
	Engine.time_scale = 1.0
	if is_instance_valid(audio):
		audio.stop_all()
		audio.reset_buses()
		audio.free()
	MusicBank.clear_cache()


# --- Yol düzeni ------------------------------------------------------------------------------

func test_buses_and_voice_is_last_and_goes_to_master() -> void:
	assert_eq(AudioServer.bus_count, AudioUtil.BUSES.size(), "Master, Music, Ambience, SFX, Voice")
	for i in AudioUtil.BUSES.size():
		assert_eq(AudioServer.get_bus_name(i), String(AudioUtil.BUSES[i]), "%d. yol" % i)
	var voice := AudioServer.get_bus_index(&"Voice")
	assert_eq(voice, AudioServer.bus_count - 1, "Voice en büyük indeks: yan zincir o karede hazır (yollar büyükten küçüğe işlenir)")
	for bus: StringName in [&"Music", &"Ambience", &"SFX", &"Voice"]:
		assert_eq(AudioServer.get_bus_send(AudioServer.get_bus_index(bus)), &"Master", "%s Master'a gider" % bus)


func test_music_ambience_and_sfx_start_with_amplify() -> void:
	for bus: StringName in [&"Music", &"Ambience", &"SFX"]:
		var idx := AudioServer.get_bus_index(bus)
		var amp := AudioServer.get_bus_effect(idx, 0) as AudioEffectAmplify
		assert_not_null(amp, "%s yolunun 0. efekti Amplify (kısma ve kara sessizlik)" % bus)
		if amp:
			assert_almost(amp.volume_db, 0.0, 0.001, "%s Amplify başta 0 dB" % bus)
			assert_true(AudioServer.is_bus_effect_enabled(idx, 0))


func test_music_chain_eq_compressor_reverb() -> void:
	var idx := AudioServer.get_bus_index(&"Music")
	var eq := AudioServer.get_bus_effect(idx, 1) as AudioEffectEQ10
	assert_not_null(eq, "Music 1. efekt EQ10 (2 kHz bandı konuşmada iner)")
	if eq:
		for band in eq.get_band_count():
			assert_almost(eq.get_band_gain_db(band), 0.0, 0.001, "Music EQ10 düz başlar (bant %d)" % band)
	_assert_sidechain(&"Music", 2)
	var reverb := AudioServer.get_bus_effect(idx, 3) as AudioEffectReverb
	assert_not_null(reverb, "Music 3. efekt Reverb (kuru müziğin ve koronun yankısı)")
	if reverb:
		assert_almost(reverb.wet, 0.12, 0.001, "ıslak ≈0,12")


func test_ambience_compressor_listens_to_voice() -> void:
	_assert_sidechain(&"Ambience", 1)


func test_voice_chain_panner_and_erlik_eq() -> void:
	var idx := AudioServer.get_bus_index(&"Voice")
	var panner := AudioServer.get_bus_effect(idx, 0) as AudioEffectPanner
	assert_not_null(panner, "Voice 0. efekt Panner (şarkının ≤%10 kayması)")
	if panner:
		assert_almost(panner.pan, 0.0)
	var eq := AudioServer.get_bus_effect(idx, 1) as AudioEffectEQ10
	assert_not_null(eq, "Voice 1. efekt EQ10 (Erlik satırları)")
	if eq:
		assert_false(AudioServer.is_bus_effect_enabled(idx, 1), "Erlik EQ'su varsayılan kapalı")
		for band in eq.get_band_count():
			var want := DuckTable.ERLIK_LOW_DB if band < DuckTable.ERLIK_LOW_BANDS else 0.0
			assert_almost(eq.get_band_gain_db(band), want, 0.001, "Erlik EQ bant %d (800 Hz altı +2 dB)" % band)


# --- DuckTable ---------------------------------------------------------------------------------

func test_duck_table_maps_the_22_states_to_four_kinds() -> void:
	assert_eq(DuckTable.STATES.size(), 22, "audio.md §3'ün 22 durumu")
	var expected := {
		DuckTable.NARRATIVE: [&"narration", &"myth", &"camp_bard", &"tengri", &"erlik", &"dawn", &"home", &"creator"],
		DuckTable.EVERYDAY: [&"camp", &"camp_night", &"hold", &"hold_night", &"winter_day", &"winter_evening",
			&"winter_night", &"road_leg", &"childhood"],
		DuckTable.TENSION: [&"tension", &"muster", &"court"],
		DuckTable.RAID: [&"raid", &"chase"],
	}
	for kind: StringName in expected:
		var got := DuckTable.states_of(kind)
		assert_eq(got.size(), (expected[kind] as Array).size(), "%s durum sayısı" % kind)
		for state: StringName in expected[kind]:
			assert_eq(DuckTable.kind_of(state), kind, "%s → %s" % [state, kind])
	assert_eq(DuckTable.levels(&"myth"), Vector2(-3, -3), "anlatı ve sinema −3 / −3")
	assert_eq(DuckTable.levels(&"camp"), Vector2(-6, -3), "gündelik −6 / −3")
	assert_eq(DuckTable.levels(&"court"), Vector2(-6, -6), "gerilim ve toplanma −6 / −6")
	assert_eq(DuckTable.levels(&"raid"), Vector2(-9, -6), "baskın ve kovalamaca −9 / −6")
	assert_eq(DuckTable.levels(&""), DuckTable.levels(&"camp"), "durum yoksa menünün durumu (camp)")
	assert_eq(DuckTable.EQ_BAND, 6, "EQ10'un 6. bandı 2 kHz")
	assert_almost(DuckTable.EQ_DB, -3.0)


func test_envelope_starts_before_the_line_and_returns_after() -> void:
	var start := 1.0
	var end := 3.0
	assert_almost(DuckTable.envelope(start - 0.2, start, end), 0.0, 0.0001, "satırdan 0,15 sn öncesine dek kısma yok")
	assert_almost(DuckTable.envelope(start - DuckTable.PREROLL, start, end), 0.0, 0.0001, "iniş satırdan 0,15 sn önce başlar")
	assert_almost(DuckTable.envelope(start, start, end), 0.5, 0.0001, "satır başında inişin yarısı")
	assert_almost(DuckTable.envelope(start - DuckTable.PREROLL + DuckTable.ATTACK, start, end), 1.0, 0.0001, "0,3 sn'de hedefte")
	assert_almost(DuckTable.envelope(2.9, start, end), 1.0, 0.0001, "satır boyunca hedefte")
	assert_almost(DuckTable.envelope(end + 0.5, start, end), 0.5, 0.0001, "dönüş 1,0 sn: yarısında yarı")
	assert_almost(DuckTable.envelope(end + DuckTable.RELEASE, start, end), 0.0, 0.0001, "bitişten 1,0 sn sonra 0 dB")
	# Kısa satır: iniş bitmeden satır biterse dönüş o anki derinlikten başlar.
	assert_almost(DuckTable.envelope(1.0, 1.0, 1.0), 0.5, 0.0001)
	assert_almost(DuckTable.envelope(1.5, 1.0, 1.0), 0.25, 0.0001)


# --- Ana söz: Amplify, EQ, kompresörler ---------------------------------------------------
# Başsız koşuda kare süresi düzgün değildir (ilk karenin adımı büyük olabilir): sınamalar zamanı değil, kısmanın
# vardığı değerleri bekler (_until, gerçek zamanla sınırlı). İnişin ve dönüşün süreleri DuckTable.envelope'ta,
# sesin inişin ortasında başlaması test_voice_starts_in_the_middle_of_the_duck'ta sınanır.

func test_line_without_file_ducks_by_state_and_returns_seconds() -> void:
	Engine.time_scale = FAST
	var started := watch_signal(audio.line_started)
	var finished := watch_signal(audio.line_finished)
	var seconds: float = audio.play_line(SILENT_LINE, {"state": &"myth"})
	assert_almost(seconds, VoLines.seconds(SILENT_LINE), 0.001, "dosyasız satır vo_lines.json'un seconds'ını döndürür")
	assert_false(AudioUtil.is_effect_enabled(&"Music", "AudioEffectCompressor"), "ana sözde Music kompresörü kapalı")
	assert_false(AudioUtil.is_effect_enabled(&"Ambience", "AudioEffectCompressor"), "ana sözde Ambience kompresörü kapalı")
	assert_eq(started.count, 0, "ses hemen başlamaz")
	assert_true(await _until(func() -> bool: return started.count == 1 and _ducked(-3.0, -3.0)), "satır başlar, kısma iner")
	assert_almost(audio.amp_db(&"Music"), -3.0, EPS, "myth anlatı türü: müzik −3 dB")
	assert_almost(audio.amp_db(&"Ambience"), -3.0, EPS, "myth anlatı türü: ortam −3 dB")
	assert_true(await _until(func() -> bool: return _music_eq_band() <= DuckTable.EQ_DB + EPS), "EQ bandı iner")
	assert_almost(_music_eq_band(), DuckTable.EQ_DB, EPS, "konuşma boyunca Music EQ10 2 kHz −3 dB")
	assert_eq(audio.current_line(), SILENT_LINE)
	assert_eq(finished.count, 0, "satır sürerken bitmedi")
	assert_true(await _until(func() -> bool: return finished.count == 1), "line_finished yayılır")
	assert_eq(audio.current_line(), "")
	assert_true(await _until(func() -> bool: return _released()), "kısma, EQ ve kompresörler döner")
	assert_almost(audio.amp_db(&"Music"), 0.0, EPS, "bitişten 1,0 sn sonra müzik 0 dB")
	assert_almost(audio.amp_db(&"Ambience"), 0.0, EPS, "bitişten 1,0 sn sonra ortam 0 dB")
	assert_almost(_music_eq_band(), 0.0, EPS, "EQ bandı döner")
	assert_true(AudioUtil.is_effect_enabled(&"Music", "AudioEffectCompressor"), "kompresörler satırdan sonra açılır")
	assert_true(AudioUtil.is_effect_enabled(&"Ambience", "AudioEffectCompressor"))


## Gerçek zamanda (time_scale 1): iniş satırdan 0,15 sn önce başlar ve 0,3 sn sürer, yani ses inişin ortasında girer;
## kısma sesle aynı anda başlasaydı ses 0 dB'de, inişten sonra başlasaydı hedefte girerdi.
func test_voice_starts_in_the_middle_of_the_duck() -> void:
	await wait_frames(2)
	var amp_at_start := [1.0]
	audio.line_started.connect(func(_id: String) -> void: amp_at_start[0] = audio.amp_db(&"Music"))
	audio.play_line(SILENT_LINE, {"state": &"myth"})
	await _until(func() -> bool: return audio.amp_db(&"Music") <= -3.0 + 0.01 and float(amp_at_start[0]) < 0.5, 2.0)
	assert_almost(float(amp_at_start[0]), -1.5, 0.9, "ses inişin ortasında başlar (iniş −3 dB'e 0,3 sn; ses 0,15 sn sonra)")
	audio.stop_line(0.0)


func test_raid_ducks_music_nine_and_ambience_six() -> void:
	Engine.time_scale = FAST
	audio.play_line(SILENT_LINE, {"state": &"raid"})
	assert_true(await _until(func() -> bool: return _ducked(-9.0, -6.0)), "baskın kısması")
	assert_almost(audio.amp_db(&"Music"), -9.0, EPS, "baskın: müzik −9 dB")
	assert_almost(audio.amp_db(&"Ambience"), -6.0, EPS, "baskın: ortam −6 dB")
	audio.stop_line(0.0)


func test_duck_follows_the_playing_music_state() -> void:
	Engine.time_scale = FAST
	assert_true(audio.set_music_bank("camp", &"camp_bard", 0.05), "kamp bankası kurulmalı")
	audio.play_line(SILENT_LINE)
	assert_true(await _until(func() -> bool: return _ducked(-3.0, -3.0)), "camp_bard anlatı türüdür (−3 / −3)")
	audio.stop_line(0.0)
	assert_true(await _until(func() -> bool: return _released()), "kısma döner")
	assert_true(audio.set_music_state(&"camp"))
	audio.play_line(SILENT_LINE)
	assert_true(await _until(func() -> bool: return _ducked(-6.0, -3.0)), "camp gündeliktir")
	assert_almost(audio.amp_db(&"Music"), -6.0, EPS, "camp gündeliktir: müzik −6")
	assert_almost(audio.amp_db(&"Ambience"), -3.0, EPS, "camp gündeliktir: ortam −3")
	audio.stop_line(0.0)
	await _settle()


func test_system_speech_keeps_the_sidechain_compressors() -> void:
	Engine.time_scale = FAST
	audio.play_line(SILENT_LINE, {"tier": "C", "state": &"raid"})
	assert_true(await _until(func() -> bool: return _music_eq_band() <= DuckTable.EQ_DB + EPS), "anlaşılırlık EQ'su her sözde")
	assert_almost(audio.amp_db(&"Music"), 0.0, 0.001, "C diliminde Amplify inmez: kısma yan zincirdedir")
	assert_almost(audio.amp_db(&"Ambience"), 0.0, 0.001)
	assert_true(AudioUtil.is_effect_enabled(&"Music", "AudioEffectCompressor"), "C diliminde kompresörler açık")
	assert_true(AudioUtil.is_effect_enabled(&"Ambience", "AudioEffectCompressor"))
	audio.stop_line(0.0)


func test_erlik_line_is_lower_with_low_eq_and_returns() -> void:
	Engine.time_scale = FAST
	# Zincir Erlik'in kendi sesi içindir (I. Perde, Kall); Önsöz'de ozan okur, satırları zincir taşımaz: burada çağrıyla sınanır.
	audio.play_line(ERLIK_LINE, {"fx": "erlik"})
	assert_almost(_voice_player().volume_db, DuckTable.ERLIK_LINE_DB, 0.001, "Erlik satırında anlatıcı −3 dB")
	assert_true(AudioUtil.is_effect_enabled(&"Voice", "AudioEffectEQ10"), "Voice EQ10 (800 Hz altı +2 dB) açık")
	audio.stop_line(0.0)
	assert_true(await _until(func() -> bool: return not AudioUtil.is_effect_enabled(&"Voice", "AudioEffectEQ10")),
			"satırdan sonra Erlik EQ'su kapanır")
	audio.play_line(SILENT_LINE)
	assert_almost(_voice_player().volume_db, 0.0, 0.001, "düz satırda anlatıcı 0 dB")
	assert_false(AudioUtil.is_effect_enabled(&"Voice", "AudioEffectEQ10"))
	audio.play_line(SILENT_LINE, {"db": -4.0})
	assert_almost(_voice_player().volume_db, -4.0, 0.001, "çizelgenin db'si (CineAudio) satırın sesidir")
	audio.stop_line(0.0)
	await _settle()


func test_song_pans_at_most_ten_percent_and_ducks_as_narration() -> void:
	Engine.time_scale = FAST
	var seconds: float = audio.play_song(SONG, {"pan": 0.5, "state": &"raid"})
	assert_almost(seconds, VoLines.seconds(SONG), 0.1, "şarkının süresi dosyasınınki")
	var panner := AudioUtil.bus_effect(&"Voice", "AudioEffectPanner") as AudioEffectPanner
	assert_almost(panner.pan, 0.1, 0.0001, "şarkı ozanın yönüne en çok %10 kayar")
	assert_true(await _until(func() -> bool: return _ducked(-3.0, -3.0) and audio.song_position(SONG) >= 0.0),
			"şarkıda kısma anlatı türünde (−3 / −3), ses başlar")
	assert_true(audio.song_position(SONG) >= 0.0, "çalan şarkının konumu okunur (sinema saati şarkıya kilitlenir)")
	assert_almost(audio.song_position("act0.myth.3"), -1.0, 0.0001, "çalmayan satırın konumu -1")
	audio.stop_line(0.0)
	assert_true(await _until(func() -> bool: return is_zero_approx(panner.pan)), "şarkıdan sonra Panner ortaya döner")
	await _settle()


func test_stop_line_finishes_and_releases() -> void:
	Engine.time_scale = FAST
	var finished := watch_signal(audio.line_finished)
	audio.play_line(SILENT_LINE, {"state": &"camp"})
	assert_true(await _until(func() -> bool: return _ducked(-6.0, -3.0)), "kısma iner")
	audio.stop_line(0.1)
	assert_eq(finished.count, 1, "stop_line line_finished yayar")
	assert_eq(audio.current_line(), "")
	assert_true(await _until(func() -> bool: return _released()), "kısma 1,0 sn'de döner")
	audio.stop_line()
	assert_eq(finished.count, 1, "satır yokken stop_line bir şey yapmaz")


func test_new_line_interrupts_the_playing_one() -> void:
	Engine.time_scale = FAST
	var finished := watch_signal(audio.line_finished)
	audio.play_line(SILENT_LINE, {"state": &"camp"})
	audio.play_line("act0.bard.2", {"state": &"raid"})
	assert_eq(finished.count, 1, "yeni satır çalanı susturur (line_finished)")
	assert_eq(audio.current_line(), "act0.bard.2")
	assert_true(await _until(func() -> bool: return _ducked(-9.0, -6.0)), "kısma yeni satırın durumuna iner")
	audio.stop_line(0.0)


func test_voice_stream_plays_as_main_speech() -> void:
	Engine.time_scale = FAST
	var stream := load(VoLines.audio_path("act0.narr.1")) as AudioStream
	assert_not_null(stream, "anlatıcının köprü satırı yüklenmeli")
	if stream == null:
		return
	var seconds: float = audio.play_voice_stream(stream, {"id": "ency.test", "state": &"camp"})
	assert_almost(seconds, stream.get_length(), 0.001, "süre sesin boyu")
	assert_false(AudioUtil.is_effect_enabled(&"Music", "AudioEffectCompressor"), "tanıtım ana sözdür (K86)")
	assert_eq(_voice_player().bus, &"Voice", "tanıtım Voice yolunda")
	assert_true(await _until(func() -> bool: return _ducked(-6.0, -3.0)), "tanıtım kısar")
	audio.stop_line(0.0)
	assert_almost(audio.play_voice_stream(null), 0.0, 0.0001, "ses yoksa 0")
	await _settle()


# --- Sessizlik (K59) ----------------------------------------------------------------------

func test_black_silence_is_minus_60_and_leaves_master_alone() -> void:
	Engine.time_scale = FAST
	var master := AudioServer.get_bus_index(&"Master")
	var master_db := AudioServer.get_bus_volume_db(master)
	var master_effects := AudioServer.get_bus_effect_count(master)
	var tween: Tween = audio.black_silence(2.0)
	assert_true(await _until(func() -> bool: return audio.amp_db(&"SFX") <= AudioManagerScript.BLACK_SILENCE_DB + EPS),
			"kara sessizliğe iner")
	for bus: StringName in [&"Music", &"Ambience", &"SFX"]:
		assert_almost(audio.amp_db(bus), AudioManagerScript.BLACK_SILENCE_DB, EPS, "%s kara sessizlikte −60 dB (dijital sıfır yok)" % bus)
	assert_almost(AudioServer.get_bus_volume_db(master), master_db, 0.0001, "Master'a dokunulmaz")
	assert_eq(AudioServer.get_bus_effect_count(master), master_effects)
	await tween.finished
	for bus: StringName in [&"Music", &"Ambience", &"SFX"]:
		assert_almost(audio.amp_db(bus), 0.0, EPS, "%s sessizlikten sonra döner" % bus)


func test_duck_and_silence_add_up_on_the_same_amplify() -> void:
	Engine.time_scale = FAST
	audio.black_silence(4.0)
	audio.play_line(SILENT_LINE, {"state": &"raid"})
	assert_true(await _until(func() -> bool: return _ducked(-69.0, -66.0)), "kısma ve sessizlik toplanır")
	assert_almost(audio.amp_db(&"Music"), -69.0, EPS, "Amplify = kısma (−9) + kara sessizlik (−60)")
	assert_almost(audio.amp_db(&"Ambience"), -66.0, EPS, "Amplify = kısma (−6) + kara sessizlik (−60)")
	assert_almost(audio.amp_db(&"SFX"), -60.0, EPS, "SFX yalnız sessizlikle iner")
	assert_almost(audio.amp_component("duck", &"Music"), -9.0, EPS)
	assert_almost(audio.amp_component("black", &"Music"), -60.0, EPS)
	audio.stop_line(0.0)


func test_low_silence_mutes_music_and_lowers_wind_to_minus_40() -> void:
	Engine.time_scale = FAST
	assert_true(audio.set_ambience_layer(AudioManagerScript.WIND_LAYER, -12.0, 0.0), "wind_steppe ortam katmanı olmalı (audio/ambience/gen)")
	audio.low_silence(true, 0.5)
	assert_true(audio.is_low_silence())
	var wind := audio.get_node(NodePath("Layer_%s" % AudioManagerScript.WIND_LAYER)) as AudioStreamPlayer
	assert_true(await _until(func() -> bool: return (audio.amp_db(&"Music") <= AudioManagerScript.SILENT_DB + EPS
			and wind.volume_db <= AudioManagerScript.LOW_SILENCE_WIND_DB + EPS)), "müzik söner, rüzgâr iner")
	assert_almost(audio.ambience_layer_db(AudioManagerScript.WIND_LAYER), AudioManagerScript.LOW_SILENCE_WIND_DB, 0.001, "rüzgâr −40 dB")
	assert_almost(wind.volume_db, AudioManagerScript.LOW_SILENCE_WIND_DB, EPS)
	assert_true(wind.playing, "rüzgâr susmaz")
	assert_almost(audio.amp_db(&"Ambience"), 0.0, 0.001, "Ambience yolu kısılmaz: ateş çıtırtısı kalır")
	audio.low_silence(false, 0.5)
	assert_true(await _until(func() -> bool: return audio.amp_db(&"Music") >= -EPS and wind.volume_db >= -12.0 - EPS),
			"müzik ve rüzgâr geri gelir")
	assert_almost(audio.ambience_layer_db(AudioManagerScript.WIND_LAYER), -12.0, 0.001, "rüzgâr önceki düzeyine döner")
	await _settle()


func test_ambience_layer_and_missing_files_are_silent() -> void:
	assert_false(audio.set_ambience_layer(&"boyle_bir_ortam_yok", -6.0, 0.0), "dosyası olmayan katman sessizce false")
	assert_null(audio.play_sfx(&"boyle_bir_efekt_yok"), "dosyası olmayan efekt sessizce null")
	assert_eq(audio.sfx_variants(&"horse_snort"), PackedStringArray(["res://audio/sfx/horse_snort.wav"]), "elle konan efekt bulunur")
	var player: Node = audio.play_sfx(&"horse_snort", {"at": Vector3(1, 0, 2), "volume_db": -6.0})
	assert_true(player is AudioStreamPlayer3D, "at verilen efekt 3B havuzdan çalar")
	if player:
		assert_eq((player as AudioStreamPlayer3D).bus, &"SFX")
		assert_almost((player as AudioStreamPlayer3D).volume_db, -6.0, 0.001)
	var flat: Node = audio.play_sfx(&"horse_snort", {"db": -3.0})
	assert_true(flat is AudioStreamPlayer, "konumsuz efekt 2B")
	if flat:
		assert_almost((flat as AudioStreamPlayer).volume_db, -3.0, 0.001, "çizelgenin db'si efektin sesidir")
	await _settle()


# --- Satırların yüklenmesi (K59) ----------------------------------------------------------

func test_lines_are_requested_in_the_background_and_released() -> void:
	var ids := PackedStringArray(["act0.myth.3", "act0.myth.4", SILENT_LINE])
	audio.request_lines(ids)
	var deadline := Time.get_ticks_msec() + 5000
	while (audio.is_line_pending("act0.myth.3") or audio.is_line_pending("act0.myth.4")) and Time.get_ticks_msec() < deadline:
		await wait_frames(1)
	assert_not_null(audio.line_stream("act0.myth.3"), "istenen satır yüklenir")
	assert_null(audio.line_stream(SILENT_LINE), "dosyasız satırın sesi yok (altyazıyla akar)")
	audio.release_lines()
	assert_eq(audio._requests.size(), 0, "bırakılan satırların isteği kalmaz")
	assert_eq(audio._streams.size(), 0, "bırakılan satırların sesi tutulmaz")
	await wait_frames(2)


# --- Yardımcılar -------------------------------------------------------------------------

func _assert_sidechain(bus: StringName, index: int) -> void:
	var comp := AudioServer.get_bus_effect(AudioServer.get_bus_index(bus), index) as AudioEffectCompressor
	assert_not_null(comp, "%s %d. efekt Compressor" % [bus, index])
	if comp == null:
		return
	assert_eq(comp.sidechain, &"Voice", "%s kompresörü Voice'u dinler (çığlık ve sistem sözü)" % bus)
	assert_almost(comp.threshold, -24.0, 0.001, "eşik −24 dB (kulakla ayarlanacak)")
	assert_almost(comp.ratio, 3.0, 0.001, "oran 3")
	assert_almost(comp.attack_us, 10000.0, 0.001, "saldırı 10 ms")
	assert_almost(comp.release_ms, 300.0, 0.001, "bırakma 300 ms")


func _music_eq_band() -> float:
	var eq := AudioUtil.bus_effect(&"Music", "AudioEffectEQ10") as AudioEffectEQ
	return eq.get_band_gain_db(DuckTable.EQ_BAND) if eq else 0.0


func _voice_player() -> AudioStreamPlayer:
	return audio.get_node(^"VoicePlayer") as AudioStreamPlayer


## Koşul doğru olana dek kare kare bekler; `timeout` gerçek saniye geçerse vazgeçer. Koşulun son değerini döndürür.
func _until(condition: Callable, timeout: float = 3.0) -> bool:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while not condition.call():
		if Time.get_ticks_msec() > deadline:
			return false
		await wait_frames(1)
	return true


## Music ve Ambience'ın Amplify'ı hedefte mi?
func _ducked(music_db: float, ambience_db: float) -> bool:
	return absf(audio.amp_db(&"Music") - music_db) <= EPS and absf(audio.amp_db(&"Ambience") - ambience_db) <= EPS


## Kısma, EQ ve kompresörler başlangıç hâlinde mi (satırdan sonraki dönüş bitti mi)?
func _released() -> bool:
	return absf(audio.amp_db(&"Music")) <= EPS and absf(audio.amp_db(&"Ambience")) <= EPS \
			and absf(_music_eq_band()) <= EPS and AudioUtil.is_effect_enabled(&"Music", "AudioEffectCompressor") \
			and AudioUtil.is_effect_enabled(&"Ambience", "AudioEffectCompressor")

## Oynatıcıları durdurur ve ses sunucusuna çalış kayıtlarını boşaltması için zaman tanır (gerçek zaman; koşu
## burada biterse çıkışta «sızıntı» yazılmasın).
func _settle() -> void:
	audio.stop_all()
	await get_tree().create_timer(0.3, true, false, true).timeout
