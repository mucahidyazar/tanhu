class_name FaunaBank
extends RefCounted
## Hayvan ses bankası (audio.md §4 «Hayvan sesleri», ses-tasarimi.md §7.5; Yol Haritası fauna-sound-bank): data/audio/fauna_bank.json'u okur,
## türün rolünü kümeye bağlar ve her küme için bir AudioStreamRandomizer kurar (çeşitler eşit ağırlıklı, PLAYBACK_RANDOM_NO_REPEATS,
## random_pitch 1,06, random_volume_offset_db 2). Türetilmiş ses aynı Randomizer'ı oynatıcının pitch_scale'iyle çalar (kuzu = koyun × 1,35).
## Dosyalar kodla basılmıştır (tools/bake_music.sh; audio/sfx/gen/fauna/); dosyası olmayan küme sessizdir (K59: oyun sessiz de akar).
## Ses yolları kodda yazılmaz, veriden kurulur (test_audio_budget kodda geçen her ses yolunu sayar).
##   var bank := FaunaBank.shared()
##   var pick := bank.pick("gazelle", &"alarm")   # {cluster: "deer_bark", pitch: 1.5, db, unit, max}
##   player.stream = bank.stream(pick["cluster"])

const PATH := "res://data/audio/fauna_bank.json"
const DIR := "res://audio/sfx/gen/fauna"
const WAV_EXT := ".wav"
const RANDOM_PITCH := 1.06
const RANDOM_DB := 2.0

static var _shared: FaunaBank

var def: Dictionary = {}
var _streams: Dictionary = {}


static func shared() -> FaunaBank:
	if _shared == null:
		_shared = FaunaBank.new()
	return _shared


func _init(path: String = PATH) -> void:
	if FileAccess.file_exists(path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		def = parsed if parsed is Dictionary else {}


func clusters() -> Dictionary:
	var c: Variant = def.get("clusters", {})
	return c if c is Dictionary else {}


func rules() -> Dictionary:
	var r: Variant = def.get("rules", {})
	return r if r is Dictionary else {}


## Türün rolü için küme ve oynatma ayarı: {cluster, pitch, db, unit, max}; rol yoksa call; tür yoksa boş.
func pick(species: String, role: StringName) -> Dictionary:
	var sp: Variant = (def.get("species", {}) as Dictionary).get(species)
	if not sp is Dictionary:
		return {}
	var cid := str((sp as Dictionary).get(String(role), (sp as Dictionary).get("call", "")))
	if cid.is_empty() or not clusters().has(cid):
		return {}
	var c: Dictionary = clusters()[cid]
	return {"cluster": cid, "pitch": float((sp as Dictionary).get("pitch", 1.0)), "db": float(c.get("db", -6.0)),
		"unit": float(c.get("unit", 12.0)), "max": float(c.get("max", 200.0))}


## Kümenin dosya yolları (kimlik audio/sfx/gen/fauna/<kimlik>.wav'dır; res:// ile başlayan olduğu gibi).
func files(cluster: String) -> PackedStringArray:
	var out := PackedStringArray()
	var c: Variant = clusters().get(cluster)
	if not c is Dictionary:
		return out
	for f: Variant in (c as Dictionary).get("files", []):
		var s := str(f)
		out.append(s if s.begins_with("res://") else DIR.path_join(s + WAV_EXT))
	return out


## Bankanın bütün dosyaları (tekrarsız).
func all_files() -> PackedStringArray:
	var out := PackedStringArray()
	for cid: String in clusters():
		for f in files(cid):
			if not out.has(f):
				out.append(f)
	out.sort()
	return out


## Kümenin Randomizer'ı (önbellekli; dosyası olmayan çeşit atlanır, hiçbiri yoksa null).
func stream(cluster: String) -> AudioStreamRandomizer:
	if _streams.has(cluster):
		return _streams[cluster]
	var r := AudioStreamRandomizer.new()
	r.playback_mode = AudioStreamRandomizer.PLAYBACK_RANDOM_NO_REPEATS
	r.random_pitch = RANDOM_PITCH
	r.random_volume_offset_db = RANDOM_DB
	for path in files(cluster):
		if ResourceLoader.exists(path):
			var s := load(path) as AudioStream
			if s:
				r.add_stream(-1, s, 1.0)
	var out: AudioStreamRandomizer = r if r.streams_count > 0 else null
	_streams[cluster] = out
	return out


## Kurulmuş Randomizer'ları bırakır (dünya değişimi).
func release() -> void:
	_streams.clear()
