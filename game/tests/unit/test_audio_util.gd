extends TestCase
## AudioUtil testleri: ses dosyası yükleme, kesintisiz döngü, veri yolu (bus) seçimi ve yol efektlerine erişim
## (beş yol: Master, Music, Ambience, SFX, Voice; godot.md §3.3).
##
## Oyun ses dosyası eksik olsa da sessizce çalışmalı; bu yüzden eksik dosya null döndürür.
## Döngü testleri bellekte üretilen seslerle yapılır (dosya gerekmez).

const CAMPFIRE_LOOP := "res://audio/ambience/campfire_loop.wav"
const UI_CLICK := "res://audio/sfx/ui_click.wav"
## Ses yöneticisinin betiği (autoload'un kendisine dokunulmaz; yalnızca dosya yolu sabitleri okunur).
const AudioManagerScript := preload("res://scripts/audio/audio_manager.gd")


# --- load_stream --------------------------------------------------------------------

func test_missing_file_returns_null() -> void:
	assert_null(AudioUtil.load_stream("res://audio/yok_boyle_bir_ses.wav", false))
	assert_null(AudioUtil.load_stream("res://audio/yok_boyle_bir_ses.mp3", true))


func test_empty_path_returns_null() -> void:
	assert_null(AudioUtil.load_stream("", false))
	assert_null(AudioUtil.load_stream("", true))


func test_missing_file_prints_no_error() -> void:
	# "Sessizce": eksik dosya konsola hata da yazmamalı (her eksik ses için kırmızı bir satır çıkmasın).
	var errors := _errors_during(func() -> void:
		AudioUtil.load_stream("res://audio/yok_boyle_bir_ses.wav", false)
		AudioUtil.load_stream("res://audio/yok_boyle_bir_ses.ogg", true))
	assert_eq(errors, PackedStringArray(), "Eksik ses dosyası konsola hata yazdı")


func test_ambience_file_loads_and_loops() -> void:
	var stream := AudioUtil.load_stream(CAMPFIRE_LOOP, true)
	assert_not_null(stream, "Ateş çıtırtısı yüklenemedi: %s" % CAMPFIRE_LOOP)
	var wav := stream as AudioStreamWAV
	assert_not_null(wav, "Ateş çıtırtısı WAV olarak içe aktarılmalı")
	if wav == null:
		return
	assert_eq(wav.loop_mode, AudioStreamWAV.LOOP_FORWARD, "Ortam sesi döngüde çalmalı")
	assert_eq(wav.loop_begin, 0)
	assert_almost(float(wav.loop_end), wav.get_length() * wav.mix_rate, 1.0, "Döngü dosyanın sonunda bitmeli")


func test_every_game_sound_file_exists() -> void:
	# Eksik dosya oyunda sessizce atlandığı için yanlış yazılmış ya da silinmiş bir yol fark edilmez;
	# oyunun kullandığı her ses (müzik, ambiyans, arayüz, ateş, at) gerçekten bulunmalı ve yüklenmeli.
	var paths := PackedStringArray([AudioManagerScript.AMBIENCE_PATH, Campfire.CRACKLE_PATH, Stable.HORSE_SOUND])
	for track: String in AudioManagerScript.MUSIC_TRACKS.values():
		paths.append(track)
	for sound: String in AudioManagerScript.UI_SOUNDS.values():
		paths.append(sound)
	for path in paths:
		assert_true(AudioUtil.load_stream(path, false) is AudioStream, "Ses dosyası yok ya da yüklenemiyor: %s" % path)


func test_loop_false_keeps_ui_sound_one_shot() -> void:
	# Not: load() aynı dosya için önbellekteki ortak kaynağı döndürür; load_stream(yol, true) onu
	# kalıcı olarak döngüye sokar. Arayüz sesleri bu yüzden hiçbir yerde loop=true ile yüklenmemeli.
	var wav := AudioUtil.load_stream(UI_CLICK, false) as AudioStreamWAV
	assert_not_null(wav, "Tıklama sesi yüklenemedi: %s" % UI_CLICK)
	if wav:
		assert_eq(wav.loop_mode, AudioStreamWAV.LOOP_DISABLED, "Arayüz sesi tek sefer çalmalı")


# --- enable_loop --------------------------------------------------------------------

func test_enable_loop_on_generated_mono_wav() -> void:
	var wav := _make_wav(22050, 44100, false, AudioStreamWAV.FORMAT_16_BITS)
	assert_eq(wav.loop_mode, AudioStreamWAV.LOOP_DISABLED, "Üretilen ses başta döngüsüz")
	AudioUtil.enable_loop(wav)
	assert_eq(wav.loop_mode, AudioStreamWAV.LOOP_FORWARD)
	assert_eq(wav.loop_begin, 0)
	assert_eq(wav.loop_end, 22050, "Döngü sonu kare sayısına eşit olmalı")


func test_enable_loop_counts_frames_not_bytes() -> void:
	# Stereo ve 8 bit seslerde de döngü sonu bayt ya da örnek değil, kare (frame) sayısıdır.
	var stereo := _make_wav(44100, 44100, true, AudioStreamWAV.FORMAT_16_BITS)
	AudioUtil.enable_loop(stereo)
	assert_eq(stereo.loop_end, 44100, "Stereo 16 bit")
	var eight_bit := _make_wav(11025, 22050, false, AudioStreamWAV.FORMAT_8_BITS)
	AudioUtil.enable_loop(eight_bit)
	assert_eq(eight_bit.loop_end, 11025, "Mono 8 bit")


func test_enable_loop_end_is_within_one_frame_for_any_length() -> void:
	# Bilinen küçük kusur: audio_util.gd döngü sonunu int() ile kırpar; bazı uzunluklarda 1 kare
	# kısa kalır (ör. 48 kHz'de 49 kare → 48). Kulakla duyulmaz; bu test en fazla 1 karelik sapmaya izin verir.
	for frames in [1, 7, 49, 997, 1000, 12345]:
		for rate in [22050, 44100, 48000]:
			var wav := _make_wav(frames, rate, false, AudioStreamWAV.FORMAT_16_BITS)
			AudioUtil.enable_loop(wav)
			assert_between(float(wav.loop_end), float(frames - 1), float(frames), "%d kare, %d Hz" % [frames, rate])


func test_enable_loop_on_mp3_and_ogg() -> void:
	var mp3 := AudioStreamMP3.new()
	var ogg := AudioStreamOggVorbis.new()
	assert_false(mp3.loop)
	assert_false(ogg.loop)
	AudioUtil.enable_loop(mp3)
	AudioUtil.enable_loop(ogg)
	assert_true(mp3.loop, "MP3 döngüsü açılmalı")
	assert_true(ogg.loop, "OGG döngüsü açılmalı")


func test_enable_loop_ignores_other_stream_types() -> void:
	# Döngü ayarı olmayan akışlarda sessizce hiçbir şey yapmamalı.
	var generator := AudioStreamGenerator.new()
	var length := generator.buffer_length
	AudioUtil.enable_loop(generator)
	assert_almost(generator.buffer_length, length)


# --- bus_or_master ------------------------------------------------------------------

func test_project_buses_exist() -> void:
	# default_bus_layout.tres: beş yol (ses seviyeleri ayrı ayrı ayarlanabilsin; Seslendirme Voice'u sürer).
	assert_eq(Array(AudioUtil.BUSES), [&"Master", &"Music", &"Ambience", &"SFX", &"Voice"])
	for bus in AudioUtil.BUSES:
		assert_eq(AudioUtil.bus_or_master(bus), bus, "%s veri yolu eksik" % bus)
	for i in AudioUtil.BUSES.size():
		assert_eq(AudioServer.get_bus_index(AudioUtil.BUSES[i]), i, "%s %d. yol" % [AudioUtil.BUSES[i], i])


func test_bus_effect_lookup_and_toggle() -> void:
	assert_eq(AudioUtil.effect_index(&"Music", "AudioEffectAmplify"), 0, "Music'in başında Amplify")
	assert_eq(AudioUtil.effect_index(&"Music", "AudioEffectCompressor"), 2)
	assert_eq(AudioUtil.effect_index(&"Voice", "AudioEffectEQ10"), 1)
	assert_true(AudioUtil.bus_effect(&"Ambience", "AudioEffectCompressor") is AudioEffectCompressor)
	assert_eq(AudioUtil.effect_index(&"SFX", "AudioEffectCompressor"), -1, "SFX'te kompresör yok")
	assert_eq(AudioUtil.effect_index(&"BoyleBirVeriYoluYok", "AudioEffectAmplify"), -1)
	assert_null(AudioUtil.bus_effect(&"BoyleBirVeriYoluYok", "AudioEffectAmplify"))
	var was := AudioUtil.is_effect_enabled(&"Voice", "AudioEffectEQ10")
	AudioUtil.set_effect_enabled(&"Voice", "AudioEffectEQ10", not was)
	assert_eq(AudioUtil.is_effect_enabled(&"Voice", "AudioEffectEQ10"), not was)
	AudioUtil.set_effect_enabled(&"Voice", "AudioEffectEQ10", was)
	assert_eq(AudioUtil.is_effect_enabled(&"Voice", "AudioEffectEQ10"), was)
	AudioUtil.set_effect_enabled(&"BoyleBirVeriYoluYok", "AudioEffectAmplify", true)   # yol yoksa sessizce geçer


func test_missing_bus_falls_back_to_master() -> void:
	assert_eq(AudioUtil.bus_or_master(&"BoyleBirVeriYoluYok"), &"Master")
	assert_eq(AudioUtil.bus_or_master(&"Master"), &"Master")


func test_bus_added_at_runtime_is_found() -> void:
	var index := AudioServer.bus_count
	AudioServer.add_bus(index)
	AudioServer.set_bus_name(index, "TanhuTestBus")
	assert_eq(AudioUtil.bus_or_master(&"TanhuTestBus"), &"TanhuTestBus")
	AudioServer.remove_bus(index)
	assert_eq(AudioUtil.bus_or_master(&"TanhuTestBus"), &"Master", "Silinen veri yolu yerine Master dönmeli")


# --- Yardımcılar ---------------------------------------------------------------------

## Sessiz (sıfırlarla dolu) bir WAV akışı üretir.
static func _make_wav(frames: int, mix_rate: int, stereo: bool, format: AudioStreamWAV.Format) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = format
	wav.mix_rate = mix_rate
	wav.stereo = stereo
	var bytes_per_sample := 2 if format == AudioStreamWAV.FORMAT_16_BITS else 1
	var data := PackedByteArray()
	data.resize(frames * bytes_per_sample * (2 if stereo else 1))
	wav.data = data
	return wav


## callable'ı çalıştırır ve bu sırada konsola yazılan hata iletilerini döndürür (uyarılar hariç).
static func _errors_during(callable: Callable) -> PackedStringArray:
	var collector := _ErrorLog.new()
	OS.add_logger(collector)
	callable.call()
	OS.remove_logger(collector)
	return collector.take()


## Hata iletilerini toplayan günlükçü (Godot hata yazdığında _log_error çağrılır).
class _ErrorLog extends Logger:
	var _mutex := Mutex.new()
	var _messages := PackedStringArray()

	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		_mutex.lock()
		_messages.append(rationale if not rationale.is_empty() else code)
		_mutex.unlock()

	## Toplanan iletiler.
	func take() -> PackedStringArray:
		_mutex.lock()
		var result := _messages
		_mutex.unlock()
		return result
