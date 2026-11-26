class_name AudioUtil
extends RefCounted
## Ses dosyası yükleme ve veri yolu (bus) yardımcıları (autoload'a bağımlı değildir; her yerden çağrılabilir).

## default_bus_layout.tres'in yolları, indeks sırasıyla. Voice en büyük indekstir: AudioServer yolları büyük
## indeksten küçüğe işler, Music ve Ambience'ın yan zincirli kompresörü Voice'u o karede hazır bulur (godot.md §3.3).
const BUSES: Array[StringName] = [&"Master", &"Music", &"Ambience", &"SFX", &"Voice"]


## Dosyayı yükler; loop=true ise türüne uygun şekilde döngüyü açar. Dosya yoksa null döner.
static func load_stream(path: String, loop: bool) -> AudioStream:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var stream := load(path) as AudioStream
	if stream and loop:
		enable_loop(stream)
	return stream


## MP3 / OGG / WAV akışlarında kesintisiz döngüyü açar.
static func enable_loop(stream: AudioStream) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length() * wav.mix_rate)


## Veri yolu (bus) varsa onu, yoksa Master'ı döndürür.
static func bus_or_master(bus: StringName) -> StringName:
	return bus if AudioServer.get_bus_index(bus) != -1 else &"Master"


## Yoldaki ilk `type` sınıfı efektin sırası (ör. "AudioEffectAmplify"); yol ya da efekt yoksa -1.
## EQ10 aranırken "AudioEffectEQ10" verilir (is_class alt sınıfı da tutar).
static func effect_index(bus: StringName, type: String) -> int:
	var idx := AudioServer.get_bus_index(bus)
	if idx == -1:
		return -1
	for i in AudioServer.get_bus_effect_count(idx):
		var effect := AudioServer.get_bus_effect(idx, i)
		if effect and effect.is_class(type):
			return i
	return -1


## Yoldaki ilk `type` sınıfı efekt (yoksa null).
static func bus_effect(bus: StringName, type: String) -> AudioEffect:
	var i := effect_index(bus, type)
	return AudioServer.get_bus_effect(AudioServer.get_bus_index(bus), i) if i != -1 else null


## Efekti açar ya da kapatır (yol ya da efekt yoksa bir şey yapmaz).
static func set_effect_enabled(bus: StringName, type: String, on: bool) -> void:
	var i := effect_index(bus, type)
	if i != -1:
		AudioServer.set_bus_effect_enabled(AudioServer.get_bus_index(bus), i, on)


## Efekt açık mı? (yol ya da efekt yoksa false)
static func is_effect_enabled(bus: StringName, type: String) -> bool:
	var i := effect_index(bus, type)
	return i != -1 and AudioServer.is_bus_effect_enabled(AudioServer.get_bus_index(bus), i)
