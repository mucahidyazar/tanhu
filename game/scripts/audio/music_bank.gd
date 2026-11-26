class_name MusicBank
extends RefCounted
## Dünyanın müzik bankası (K59, K61; audio.md §3 «Godot'da müzik», godot.md §3.3): `data/audio/banks/<bank>.json`'dan
## bir `AudioStreamInteractive` kurar. Klip adı müzik durumunun kimliğidir (`camp`, `camp_bard` …); her klip bir
## `AudioStreamSynchronized`'dır, katmanları araçla basılmış Ogg'lardır (`tools/bake_music.gd`, `audio/gen/`).
##
## Banka verisi:
##   {"id": "camp", "version": 1, "menu_source": "elevenlabs",
##    "transition": {"from": "next_bar", "to": "start", "fade": "cross", "beats": 2},
##    "transitions": [{"from_clip": "camp", "to_clip": "camp_night", "beats": 4}],
##    "clips": [{"name": "camp", "tempo": 52, "layers": [
##        {"name": "drone", "file": "camp_drone", "db": 0},
##        {"name": "kopuz", "group": "lead", "db": -3, "phrases": [
##            {"file": "camp_kopuz_a", "copies": 4}, {"file": "camp_rest", "copies": 1, "rest": true}]}]}]}
## - 0. katman vuruş bilgili düz Ogg'dur (dron; `bpm`, `beat_count`, `bar_beats` 2): Synchronized ölçü bilgisini
##   ondan alır, `NEXT_BAR` geçişi bu yüzden ölçü sınırında olur. Cümle katmanları ondan sonra gelir.
## - Cümle katmanı bir `AudioStreamPlaylist`'tir: ağırlık kopya sayısıdır (A ×4, A' ×2, B ×2, boş ×1), `shuffle`
##   açık, `fade_time` 0; cümleler ölçü sınırında uç uca biner (Playlist vuruş bilgili Ogg'u `beat_count`
##   vuruşta değiştirir).
## - Koro gök içindir (K59): `choir_` katmanı yalnız `tengri` ve `dawn` kliplerinde kurulur; başka klipte kurulmaz
##   ve hata yazılır (test_music_choir.gd bütün bankaları bununla gezer).
## - Ses yolları kodda yazılmaz, kimlikten kurulur (test_audio_budget kodda geçen her ses yolunu sayar).
## - `menu_source`: menünün müziği; `elevenlabs` bugünkü menü parçası, `baked` bankanın `camp` klibi (kulak onayından
##   sonra; Karar Bekleyenler).

const BANK_DIR := "res://data/audio/banks"
## Araçla basılan müziğin klasörü; dosya yolu kimlik + OGG_EXT.
const GEN_DIR := "res://audio/gen"
const OGG_EXT := ".ogg"
const VERSION := 1
## 6/8: bpm noktalı dörtlüğün temposudur, ölçü iki vuruştur (52'de 2,308 sn).
const BAR_BEATS := 2
const SILENT_DB := -80.0
## Koro katmanının öneki ve izinli klipleri (K59).
const CHOIR_PREFIX := "choir_"
const CHOIR_CLIPS: Array[StringName] = [&"tengri", &"dawn"]
const MENU_SOURCES: Array[String] = ["elevenlabs", "baked"]
const GROUPS: Array[String] = ["", "lead", "add", "drum"]
## Geçiş adları → AudioStreamInteractive sabitleri.
const FROM_TIMES := {
	"immediate": AudioStreamInteractive.TRANSITION_FROM_TIME_IMMEDIATE,
	"next_beat": AudioStreamInteractive.TRANSITION_FROM_TIME_NEXT_BEAT,
	"next_bar": AudioStreamInteractive.TRANSITION_FROM_TIME_NEXT_BAR,
	"end": AudioStreamInteractive.TRANSITION_FROM_TIME_END,
}
const TO_TIMES := {
	"same": AudioStreamInteractive.TRANSITION_TO_TIME_SAME_POSITION,
	"start": AudioStreamInteractive.TRANSITION_TO_TIME_START,
}
const FADES := {
	"none": AudioStreamInteractive.FADE_DISABLED,
	"in": AudioStreamInteractive.FADE_IN,
	"out": AudioStreamInteractive.FADE_OUT,
	"cross": AudioStreamInteractive.FADE_CROSS,
	"auto": AudioStreamInteractive.FADE_AUTOMATIC,
}
## Gündelik ↔ gündelik geçiş: ölçü sınırında, çapraz, 2 vuruş (52'de ≈2,3 sn; audio.md §3).
const DEFAULT_TRANSITION := {"from": "next_bar", "to": "start", "fade": "cross", "beats": 2.0}

static var _defs: Dictionary = {}


# --- Veri ---------------------------------------------------------------------------------

static func path_of(bank: String) -> String:
	return BANK_DIR.path_join(bank + ".json")


## Bankanın verisi (önbellekli); dosya yoksa ya da bozuksa boş sözlük.
static func load_def(bank: String) -> Dictionary:
	if _defs.has(bank):
		return _defs[bank]
	var def: Dictionary = {}
	var path := path_of(bank)
	if FileAccess.file_exists(path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			def = parsed
	_defs[bank] = def
	return def


static func clear_cache() -> void:
	_defs.clear()


## Projedeki bankaların kimlikleri (data/audio/banks/*.json).
static func bank_ids() -> PackedStringArray:
	var ids := PackedStringArray()
	if DirAccess.dir_exists_absolute(BANK_DIR):
		for file in DirAccess.get_files_at(BANK_DIR):
			if file.get_extension() == "json":
				ids.append(file.get_basename())
	ids.sort()
	return ids


static func clips(def: Dictionary) -> Array:
	var list: Variant = def.get("clips", [])
	return list if list is Array else []


static func clip_names(def: Dictionary) -> PackedStringArray:
	var names := PackedStringArray()
	for clip: Variant in clips(def):
		if clip is Dictionary:
			names.append(str(clip.get("name", "")))
	return names


static func clip_index(def: Dictionary, clip_name: StringName) -> int:
	return clip_names(def).find(String(clip_name))


static func clip(def: Dictionary, clip_name: StringName) -> Dictionary:
	var i := clip_index(def, clip_name)
	return clips(def)[i] if i != -1 else {}


static func layers(clip_def: Dictionary) -> Array:
	var list: Variant = clip_def.get("layers", [])
	return list if list is Array else []


static func layer_names(def: Dictionary, clip_name: StringName) -> PackedStringArray:
	var names := PackedStringArray()
	for layer: Variant in layers(clip(def, clip_name)):
		if layer is Dictionary:
			names.append(str(layer.get("name", "")))
	return names


## Katman adı → Synchronized'daki sırası (klipte yoksa -1).
static func layer_index(def: Dictionary, clip_name: StringName, layer_name: StringName) -> int:
	return layer_names(def, clip_name).find(String(layer_name))


## Klip → {katman adı: sıra} tablosu.
static func layer_table(def: Dictionary) -> Dictionary:
	var table := {}
	for name in clip_names(def):
		var row := {}
		var names := layer_names(def, StringName(name))
		for i in names.size():
			row[StringName(names[i])] = i
		table[StringName(name)] = row
	return table


## Katmanın dosya kimlikleri (düz katmanda bir, cümle katmanında cümle başına bir; tekrarsız).
static func layer_files(layer: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	if layer.get("file") is String:
		out.append(layer["file"])
	for phrase: Variant in _phrases(layer):
		var id := str((phrase as Dictionary).get("file", ""))
		if not id.is_empty() and not out.has(id):
			out.append(id)
	return out


## Bankanın bütün dosya kimlikleri (tekrarsız, sıralı).
static func files(def: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	for clip_def: Variant in clips(def):
		if not clip_def is Dictionary:
			continue
		for layer: Variant in layers(clip_def):
			if layer is Dictionary:
				for id in layer_files(layer):
					if not out.has(id):
						out.append(id)
	out.sort()
	return out


## Dosya kimliğinin Ogg yolu (audio/gen/<kimlik>.ogg).
static func stream_path(file_id: String) -> String:
	return GEN_DIR.path_join(file_id + OGG_EXT)


## Menünün müziği nereden çalar: "elevenlabs" (bugünkü parça) ya da "baked" (bankanın camp klibi).
static func menu_source(def: Dictionary) -> String:
	var source := str(def.get("menu_source", "elevenlabs"))
	return source if MENU_SOURCES.has(source) else "elevenlabs"


## Katman koro mu (adı ya da dosyası choir_ ile başlar)?
static func is_choir(layer: Dictionary) -> bool:
	if str(layer.get("name", "")).begins_with(CHOIR_PREFIX):
		return true
	for id in layer_files(layer):
		if id.begins_with(CHOIR_PREFIX):
			return true
	return false


## Koro bu klipte kurulabilir mi (K59: yalnız tengri ve dawn)?
static func choir_allowed(clip_name: StringName) -> bool:
	return CHOIR_CLIPS.has(clip_name)


# --- Denetim ------------------------------------------------------------------------------

## Bankanın kural ihlalleri (boşsa geçerli): şema, klip ve katman adlarının tekilliği, 0. katmanın düz Ogg
## olması, koro kuralı, dosyaların varlığı ve vuruş bilgisi (bpm klibin temposuna eşit, bar_beats 2, düz
## katmanda beat_count tam ölçü ve döngü açık, cümlede döngü kapalı).
static func problems(def: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	if not _is_number(def.get("version")) or int(def["version"]) != VERSION:
		out.append("version %d olmalı" % VERSION)
	if not MENU_SOURCES.has(str(def.get("menu_source", "elevenlabs"))):
		out.append("menu_source %s olmalı" % "/".join(MENU_SOURCES))
	if def.has("transitions") and not def["transitions"] is Array:
		out.append("transitions liste olmalı")
	for t: Variant in [def.get("transition", {})] + _transitions(def):
		if t is Dictionary:
			out.append_array(_transition_problems(t))
	var names := {}
	for clip_def: Variant in clips(def):
		if not clip_def is Dictionary:
			out.append("klip sözlük değil: %s" % str(clip_def))
			continue
		var name := str(clip_def.get("name", ""))
		if name.is_empty() or names.has(name):
			out.append("klip adı boş ya da iki kez geçiyor: «%s»" % name)
		names[name] = true
		out.append_array(_clip_problems(clip_def))
	if names.is_empty():
		out.append("klip yok")
	return out


static func _clip_problems(clip_def: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	var name := str(clip_def.get("name", ""))
	var tempo := float(clip_def.get("tempo", 0.0)) if _is_number(clip_def.get("tempo")) else 0.0
	if tempo <= 0.0:
		out.append("%s: tempo artı bir sayı olmalı" % name)
	var list := layers(clip_def)
	if list.is_empty():
		out.append("%s: katman yok" % name)
		return out
	if list.size() > AudioStreamSynchronized.MAX_STREAMS:
		out.append("%s: en çok %d katman" % [name, AudioStreamSynchronized.MAX_STREAMS])
	var seen := {}
	for i in list.size():
		var layer: Variant = list[i]
		if not layer is Dictionary:
			out.append("%s: katman sözlük değil" % name)
			continue
		var lname := str(layer.get("name", ""))
		if lname.is_empty() or seen.has(lname):
			out.append("%s: katman adı boş ya da iki kez geçiyor: «%s»" % [name, lname])
		seen[lname] = true
		var plain: bool = layer.get("file") is String
		var phrased := not _phrases(layer).is_empty()
		if plain == phrased:
			out.append("%s/%s: katman ya tek dosya (file) ya cümle listesi (phrases) taşır" % [name, lname])
		if i == 0 and not plain:
			out.append("%s: 0. katman vuruş bilgili düz Ogg olmalı (dron); cümle katmanı ondan sonra gelir" % name)
		if not GROUPS.has(str(layer.get("group", ""))):
			out.append("%s/%s: group %s olmalı" % [name, lname, "/".join(GROUPS)])
		if is_choir(layer) and not choir_allowed(StringName(name)):
			out.append("%s/%s: koro yalnız %s kliplerinde (K59)" % [name, lname, ", ".join(CHOIR_CLIPS)])
		var copies := 0
		for phrase: Variant in _phrases(layer):
			var c: Variant = (phrase as Dictionary).get("copies", 1)
			if not _is_number(c) or int(c) < 0:
				out.append("%s/%s: copies sıfır ya da artı tam sayı olmalı" % [name, lname])
			else:
				copies += int(c)
		if phrased and (copies <= 0 or copies > AudioStreamPlaylist.MAX_STREAMS):
			out.append("%s/%s: cümle kopyası 1–%d olmalı (%d)" % [name, lname, AudioStreamPlaylist.MAX_STREAMS, copies])
		for id in layer_files(layer):
			out.append_array(_file_problems("%s/%s" % [name, lname], id, tempo, plain))
	return out


static func _file_problems(where: String, id: String, tempo: float, plain: bool) -> PackedStringArray:
	var out := PackedStringArray()
	var path := stream_path(id)
	if not ResourceLoader.exists(path):
		out.append("%s: %s yok ya da içe aktarılmamış" % [where, path])
		return out
	var ogg := load(path) as AudioStreamOggVorbis
	if ogg == null:
		out.append("%s: %s Ogg Vorbis değil" % [where, path])
		return out
	if not is_equal_approx(ogg.bpm, tempo):
		out.append("%s: %s bpm %.2f, klibin temposu %.2f" % [where, id, ogg.bpm, tempo])
	if ogg.bar_beats != BAR_BEATS:
		out.append("%s: %s bar_beats %d olmalı (6/8)" % [where, id, BAR_BEATS])
	if ogg.beat_count <= 0 or ogg.beat_count % BAR_BEATS != 0:
		out.append("%s: %s beat_count tam ölçü olmalı (%d)" % [where, id, ogg.beat_count])
	if plain != ogg.loop:
		out.append("%s: %s döngüsü %s olmalı" % [where, id, "açık (düz katman)" if plain else "kapalı (cümle)"])
	return out


static func _transition_problems(t: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	for pair: Array in [["from", FROM_TIMES], ["to", TO_TIMES], ["fade", FADES]]:
		if t.has(pair[0]) and not (pair[1] as Dictionary).has(str(t[pair[0]])):
			out.append("geçiş %s: «%s» bilinmiyor" % [pair[0], str(t[pair[0]])])
	if t.has("beats") and (not _is_number(t["beats"]) or float(t["beats"]) <= 0.0):
		out.append("geçiş beats artı bir sayı olmalı")
	return out


# --- Kurulum ------------------------------------------------------------------------------

## Bankayı kurar: klip başına bir Synchronized, cümle katmanı başına bir Playlist; geçişler NEXT_BAR + FADE_CROSS.
## color verilirse perde rengi uygulanır (MusicColor: lead / add / drum öbekleri, boş cümle kopyası). Koro kuralına
## uymayan katman kurulmaz ve hata yazılır; eksik dosya sessizce atlanır (oyun sessiz de çalışır; problems() yakalar).
static func build(def: Dictionary, color: MusicColor = null) -> AudioStreamInteractive:
	var list := clips(def)
	if list.is_empty():
		return null
	var stream := AudioStreamInteractive.new()
	stream.clip_count = list.size()
	for i in list.size():
		var clip_def: Dictionary = list[i] if list[i] is Dictionary else {}
		stream.set_clip_name(i, StringName(str(clip_def.get("name", "clip_%d" % i))))
		stream.set_clip_stream(i, build_clip(clip_def, color))
	var base: Dictionary = DEFAULT_TRANSITION.merged(def.get("transition", {}) if def.get("transition") is Dictionary else {}, true)
	_add_transition(stream, AudioStreamInteractive.CLIP_ANY, AudioStreamInteractive.CLIP_ANY, base)
	for t: Variant in _transitions(def):
		if not t is Dictionary:
			continue
		var from := clip_index(def, StringName(str(t.get("from_clip", ""))))
		var to := clip_index(def, StringName(str(t.get("to_clip", ""))))
		if from == -1 and str(t.get("from_clip", "")) != "*":
			continue
		if to == -1 and str(t.get("to_clip", "")) != "*":
			continue
		_add_transition(stream, from, to, base.merged(t, true))
	return stream


## Tek klip: katmanlar sırayla Synchronized'a girer; katmanın sesi `db` + perde renginin payı.
static func build_clip(clip_def: Dictionary, color: MusicColor = null) -> AudioStreamSynchronized:
	var sync := AudioStreamSynchronized.new()
	var list := layers(clip_def)
	var clip_name := StringName(str(clip_def.get("name", "")))
	sync.stream_count = mini(list.size(), AudioStreamSynchronized.MAX_STREAMS)
	for i in sync.stream_count:
		var layer: Dictionary = list[i] if list[i] is Dictionary else {}
		if is_choir(layer) and not choir_allowed(clip_name):
			push_error("MusicBank: «%s» klibinde koro katmanı «%s» kurulmadı: koro yalnız %s kliplerinde (K59)"
					% [clip_name, str(layer.get("name", "")), ", ".join(CHOIR_CLIPS)])
			continue
		var layer_stream := _layer_stream(layer, color)
		if layer_stream == null:
			continue
		sync.set_sync_stream(i, layer_stream)
		sync.set_sync_stream_volume(i, layer_volume(layer, color))
	return sync


## Katmanın kurulacağı ses (dB): bankanın `db`'si + perde renginin payı; en az SILENT_DB.
static func layer_volume(layer: Dictionary, color: MusicColor = null) -> float:
	var db := float(layer.get("db", 0.0)) if _is_number(layer.get("db")) else 0.0
	if color:
		db += color.layer_db(StringName(str(layer.get("name", ""))), str(layer.get("group", "")))
	return maxf(db, SILENT_DB)


static func _layer_stream(layer: Dictionary, color: MusicColor) -> AudioStream:
	if layer.get("file") is String:
		return _ogg(str(layer["file"]))
	var phrases := _phrases(layer)
	if phrases.is_empty():
		return null
	var group := str(layer.get("group", ""))
	var entries: Array[AudioStream] = []
	for phrase: Variant in phrases:
		var p: Dictionary = phrase
		var ogg := _ogg(str(p.get("file", "")))
		if ogg == null:
			continue
		var copies := int(p.get("copies", 1)) if _is_number(p.get("copies")) else 1
		if bool(p.get("rest", false)) and color:
			copies = color.rest_count(group, copies)
		for c in maxi(copies, 0):
			if entries.size() < AudioStreamPlaylist.MAX_STREAMS:
				entries.append(ogg)
	if entries.is_empty():
		return null
	var playlist := AudioStreamPlaylist.new()
	playlist.shuffle = true
	playlist.loop = true
	playlist.fade_time = 0.0
	playlist.stream_count = entries.size()
	for i in entries.size():
		playlist.set_list_stream(i, entries[i])
	return playlist


static func _ogg(id: String) -> AudioStreamOggVorbis:
	var path := stream_path(id)
	if id.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStreamOggVorbis


static func _add_transition(stream: AudioStreamInteractive, from: int, to: int, t: Dictionary) -> void:
	stream.add_transition(from, to,
			FROM_TIMES.get(str(t.get("from", "next_bar")), AudioStreamInteractive.TRANSITION_FROM_TIME_NEXT_BAR),
			TO_TIMES.get(str(t.get("to", "start")), AudioStreamInteractive.TRANSITION_TO_TIME_START),
			FADES.get(str(t.get("fade", "cross")), AudioStreamInteractive.FADE_CROSS),
			float(t.get("beats", 2.0)))


static func _transitions(def: Dictionary) -> Array:
	var list: Variant = def.get("transitions", [])
	return list if list is Array else []


static func _phrases(layer: Dictionary) -> Array:
	var list: Variant = layer.get("phrases", [])
	var out: Array = []
	if list is Array:
		for p: Variant in list:
			if p is Dictionary:
				out.append(p)
	return out


static func _is_number(value: Variant) -> bool:
	return value is float or value is int
