class_name CineTimeline
extends RefCounted
## Sinema zaman çizelgesi (saf): segment ve dizi dosyalarını (data/cine/*.json) mutlak zamanlı, sıralı bir
## olay listesine çözer (godot.md §3.6, K68; prototipin src/story/schema.js parseCineTime ve
## src/game/cine.js resolveCine kalıbı). Düğüm kurmaz, ses çalmaz: CineRunner olayları yayar, CineHost uygular.
##
## SEGMENT bir sahnenin çizelgesidir; zamanları segmentin başından sayılır:
##   {"id": "camp", "scene": "res://scenes/cine/prologue_camp.tscn", "world": "camp", "view": "main",
##    "length": "act0.bard.song_end+6.05",
##    "events": [
##      {"t": 0, "type": "music", "bank": "camp", "state": "camp_bard", "fade": 2},
##      {"id": "song", "t": 6.0, "type": "song", "line": "act0.bard.song"},
##      {"t": "song_end+0.05", "type": "low_silence", "fade": 1}]}
##   scene: kökü CineScene olan sahne (.tscn; testte Script ya da PackedScene de olur) ya da null.
##   world: "camp" (kamp dünyası), "none" ya da dünyanın sahne yolu (res://...).
##   view: "main" (ana 3B) ya da "overlay" (kendi dünyası olan SubViewport, boyalı süzgecin altında).
##   length: sayı ya da çapa; yazılmazsa olayların en geç bitişi.
## DİZİ segmentleri art arda zincirler (segmentin başı öncekinin length'idir) ve kendi olaylarını segment
## çapalarıyla yazar:
##   {"id": "prologue", "end": "creator", "target": {"total": 225, "tolerance": 15},
##    "segments": [{"file": "res://data/cine/prologue_camp.json"},
##                 {"file": "res://data/cine/prologue_myth.json", "view": "overlay"},
##                 {"file": "res://data/cine/prologue_birth.json", "world": "res://scenes/maps/childhood_ordos.tscn",
##                  "preload_at": "myth", "instantiate_at": "myth:panel_6", "crossfade_in": 1.5}],
##    "events": [{"t": "camp_end-1.0", "type": "release_camp"}]}
##   Segment girdisinin alanları (file dışında) dosyanınkini ezer; dosyasız girdi segmentin kendisidir.
##   crossfade_in: segment başından bu kadar önce kurulur, önceki overlay o sürede söner.
##   preload_at / instantiate_at: segmentin dünyası (yol) o anda istenir / örneklenir. Tek segment dosyası
##   da dizi gibi oynar.
##
## ZAMAN (t, length, *_at): sayı (saniye, ≥ 0) ya da «çapa[_end][±sn]» dizgesi:
##   "song+6"               kimliği (id) song olan olayın başlangıcından 6 sn sonra
##   "act0.myth.3_end+8.3"  satırın bitişinden 8,3 sn sonra (line ve song olayının satır kimliği de çapadır)
##   "7b+1.0"               çekimin (shot) adı da çapadır
##   "end-1"                segmentin sonundan 1 sn önce (length bu çapayı kullanamaz)
##   Dizide: "myth" segmentin başı, "myth_end" sonu, "myth:panel_6" segmentin içindeki çapa.
## Olayın süresi: dur yazılıysa o; line ve song'da satırın süresi (VoLines.seconds: dosya varsa gerçek süre,
## yoksa tahmin); öbürlerinde 0. Satır uzarsa ona bağlı olaylar, segmentin sonu ve sonraki segmentler aynı
## payla kayar. Aynı andaki olaylar yazıldıkları sırayla yayılır. Kimlik "_end" ile bitmemelidir.
## line ve song'un t'si sesin başladığı andır: AudioManager ana sözü kısmadan 0,15 sn sonra başlattığı için
## (K78) çizelge her satıra o kadar önce bir iç _voice olayı ekler; ses isteği oradan gider (CineAudio.lead_time).
##
## OLAY TÜRLERİ (type; CineHost uygular, segmentin sahnesi ayrıca on_event ile duyar; başka tür yalnız
## sahneye gider):
##   shot {name}                         sahnenin on_shot(name, ev)'i (kamera, AnimationPlayer)
##   line {line, pan?, fx?, opts?}       AudioManager.play_line; altyazı; süre satırın seconds'ı
##   song {line}                         AudioManager.play_song; dizelerin altyazısı; saat şarkıya kilitlenir
##   music {state, bank?, fade?}         set_music_bank(bank, state, fade) ya da set_music_state(state)
##   layer {layer, db, dur?}             set_layer_db(layer, db, dur)
##   ambience {id, db, dur?}             set_ambience_layer(id, db, dur)
##   low_silence {on?, fade?}            low_silence(on, fade)
##   black_silence {dur}                 black_silence(dur)
##   sfx {id, at?, opts?}                play_sfx(id, opts)
##   stop_line {fade?}                   stop_line(fade)
##   fade {to, dur}                      perde (UI/Fade) dur sn'de to'ya
##   card {text{tr, en} | tr, en, dur}   alt üçte bir kart (Cinzel)
##   crossfade {dur}                     overlay katmanı söner, ana 3B görünür
##   preload {path} / instantiate {path} dünyanın arka planda yüklenmesi / örneklenip eklenmesi
##   release_camp / restore_camp         kamp dünyası gizlenir, durur, susar / geri gelir
##
##   var timeline := CineTimeline.from_path("res://data/cine/test_timeline.json")
##   timeline.validate()                 # eksik çapa, döngü, bozuk zaman, bilinmeyen satır...
##   timeline.time_of("camp:song_end")   # mutlak saniye (NAN: bilinmiyor)

const SEGMENT_END := "end"
const SEPARATOR := ":"
const WORLD_CAMP := "camp"
const WORLD_NONE := "none"
const VIEW_MAIN := "main"
const VIEW_OVERLAY := "overlay"
const VIEWS: Array[String] = [VIEW_MAIN, VIEW_OVERLAY]
## Konağın kendi uyguladığı türler ve zorunlu alanları; başka tür yalnız sahnenin on_event'ine gider.
const REQUIRED := {
	"shot": ["name"], "line": ["line"], "song": ["line"], "music": ["state"], "layer": ["layer", "db"],
	"ambience": ["id", "db"], "low_silence": [], "black_silence": ["dur"], "sfx": ["id"], "stop_line": [],
	"fade": ["to", "dur"], "card": ["dur"], "crossfade": ["dur"], "preload": ["path"],
	"instantiate": ["path"], "release_camp": [], "restore_camp": [],
}
## Süresini satırın seconds'ından alan türler.
const LINE_TYPES: Array[String] = ["line", "song"]
## Çizelgenin kendi eklediği iç olaylar: segmentin kurulması ve kapanması, satırın ses isteği (sahneye gitmez).
const ENTER := "_enter"
const EXIT := "_exit"
const VOICE := "_voice"
## Kayan nokta toplamlarında "aynı an" payı (saniye).
const EPSILON := 0.000001

const _TIME_PATTERN := "^([A-Za-z0-9][A-Za-z0-9_.:]*?)(_end)?([+-]\\d+(?:\\.\\d+)?)?$"

static var _regex: RegEx

## Dizinin kimliği (tek segmentte segmentinki).
var id := ""
## Okunan dosya (varsa).
var source := ""
## Mutlak zamanla sıralı olaylar. Her olay kaynağın kopyasıdır ve şunları taşır: t (mutlak başlangıç),
## end (mutlak bitiş), duration, local_t (segment içi), segment (kimlik; dizinin olayında ""), type, id,
## spec (yazılan t), order (aynı anın sırası).
var events: Array[Dictionary] = []
## Segmentler sırayla: id, index, file, scene, world, view, start, end, length, enter (kurulma anı),
## crossfade_in, title.
var segments: Array[Dictionary] = []
## Kurarken bulunan sorunlar (validate döndürür).
var problems := PackedStringArray()
## Dizinin bitiş hedefi (ör. "creator") ve süre hedefi ({total, tolerance}).
var end_target := ""
var target: Dictionary = {}
## Dizi bitince örneklenen dünya bırakılmasın mı (Çocukluk gelince)?
var keep_world := false

var _seconds: Callable
var _resolvers: Dictionary = {}
var _total := 0.0


# --- Kurulum ---------------------------------------------------------------------------------------

## Dosyadan kurar (dizi ya da tek segment). seconds: satır kimliği → süre (boşsa VoLines.seconds).
static func from_path(path: String, seconds: Callable = Callable()) -> CineTimeline:
	var timeline := CineTimeline.new()
	timeline.source = path
	var def := read_json(path)
	if def.is_empty():
		timeline.problems.append("%s: okunamadı ya da boş" % path)
	timeline._build(def, seconds)
	return timeline


## Sözlükten kurar (dizi ya da tek segment).
static func from_dict(def: Dictionary, seconds: Callable = Callable()) -> CineTimeline:
	var timeline := CineTimeline.new()
	timeline._build(def, seconds)
	return timeline


## JSON sözlüğü; dosya yoksa ya da bozuksa boş.
static func read_json(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## Zamanı ayrıştırır: {"at": sn} | {"anchor": ad, "end": bool, "offset": sn} | {} (bozuk ya da eksi).
static func parse_time(spec: Variant) -> Dictionary:
	if spec is float or spec is int:
		return {"at": float(spec)} if float(spec) >= 0.0 else {}
	if not spec is String:
		return {}
	var text := (spec as String).strip_edges().replace(" ", "")
	if text.is_valid_float():
		var value := text.to_float()
		return {"at": value} if value >= 0.0 else {}
	if _regex == null:
		_regex = RegEx.create_from_string(_TIME_PATTERN)
	var m := _regex.search(text)
	if m == null:
		return {}
	var offset := m.get_string(3)
	return {"anchor": m.get_string(1), "end": not m.get_string(2).is_empty(),
		"offset": offset.to_float() if not offset.is_empty() else 0.0}


# --- Okuma -----------------------------------------------------------------------------------------

## Çizelgenin toplam süresi (son segmentin sonu).
func total() -> float:
	return _total


## En az bir segment kuruldu mu?
func ok() -> bool:
	return not segments.is_empty()


## Kurulumun bulduğu sorunlar: bozuk zaman, eksik çapa, zaman döngüsü, çift kimlik, bilinmeyen satır,
## eksik alan, olmayan dosya, çizelgenin sonundan sonraki olay.
func validate() -> PackedStringArray:
	return problems.duplicate()


func segment(seg_id: String) -> Dictionary:
	for seg in segments:
		if seg["id"] == seg_id:
			return seg
	return {}


## t anında süren segment ([start, end); sondaysa sonuncusu).
func segment_at(t: float) -> Dictionary:
	for seg in segments:
		if t < float(seg["end"]) - EPSILON:
			return seg
	return segments.back() if not segments.is_empty() else {}


## Türü verilen olaylar (zaman sırasıyla).
func events_of(type: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for ev in events:
		if ev["type"] == type:
			out.append(ev)
	return out


## Satır ve şarkı olayları (zaman sırasıyla).
func line_events() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for ev in events:
		if LINE_TYPES.has(str(ev["type"])):
			out.append(ev)
	return out


## Çizelgede geçen satır kimlikleri (bir kez, zaman sırasıyla).
func line_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for ev in line_events():
		var line_id := str(ev.get("line", ""))
		if not line_id.is_empty() and not out.has(line_id):
			out.append(line_id)
	return out


## Çapanın (id, satır, çekim adı) ilk olayı; seg_id verilirse yalnız o segmentte arar.
func find(anchor: String, seg_id: String = "") -> Dictionary:
	for ev in events:
		if str(ev["type"]).begins_with("_") or (not seg_id.is_empty() and ev["segment"] != seg_id):
			continue
		if ev["id"] == anchor or _Resolver.implicit_names(ev).has(anchor):
			return ev
	return {}


## Çapanın mutlak zamanı: "camp", "camp_end", "myth:panel_6", "song_end+0.5" (segment adı yoksa
## segmentlerde sırayla aranır) ya da sayı. Bilinmiyorsa NAN.
func time_of(ref: Variant) -> float:
	var p := parse_time(ref)
	if p.is_empty():
		return NAN
	if p.has("at"):
		return float(p["at"])
	var name: String = p["anchor"]
	var at_end: bool = p["end"]
	var base := _sequence_anchor(name, at_end)
	if is_nan(base):
		for seg in segments:
			var resolver: _Resolver = _resolvers.get(seg["id"])
			var local := resolver.anchor_time(name, at_end) if resolver else NAN
			if not is_nan(local):
				base = float(seg["start"]) + local
				break
	return base + float(p["offset"]) if not is_nan(base) else NAN


# --- Çözüm -----------------------------------------------------------------------------------------

func _build(def: Dictionary, seconds: Callable) -> void:
	# Yöntem çağrısı (lambda değil): lambda RefCounted self'i güçlü tutar, çizelge kendini bırakamazdı.
	_seconds = seconds if seconds.is_valid() else _vo_seconds
	var fallback_id := source.get_file().get_basename() if not source.is_empty() else "cine"
	id = str(def["id"]) if def.get("id") is String else fallback_id
	end_target = str(def["end"]) if def.get("end") is String else ""
	target = def["target"] if def.get("target") is Dictionary else {}
	keep_world = bool(def.get("keep_world", false))
	var entries: Array = []
	if def.has("segments"):
		if def["segments"] is Array:
			entries = def["segments"]
		else:
			problems.append("%s: segments liste olmalı" % id)
	elif not def.is_empty():
		entries = [{"_def": def}]
	var blocks: Array = []
	var cursor := 0.0
	for i in entries.size():
		var seg := _segment_from(entries[i], i)
		if seg.is_empty():
			continue
		var resolver := _Resolver.new()
		resolver.label = str(seg["id"])
		resolver.seconds = _seconds
		resolver.defs = _event_list(seg["events"], str(seg["id"]))
		resolver.solve(seg["length_spec"])
		problems.append_array(resolver.problems)
		_resolvers[seg["id"]] = resolver
		seg["start"] = cursor
		seg["length"] = resolver.length
		seg["end"] = cursor + resolver.length
		seg["enter"] = maxf(cursor - float(seg["crossfade_in"]), 0.0)
		cursor = float(seg["end"])
		segments.append(seg)
		blocks.append(_segment_events(seg, resolver))
	_total = cursor
	blocks.append(_sequence_events(def))
	var order := 0
	for block: Array in blocks:
		for ev: Dictionary in block:
			ev["order"] = order
			order += 1
			events.append(ev)
	events.sort_custom(_before)
	_check()


## Segment girdisini (dosya + ezen alanlar) segment kaydına çevirir.
func _segment_from(entry: Variant, index: int) -> Dictionary:
	if not entry is Dictionary:
		problems.append("%s: segments[%d] sözlük olmalı" % [id, index])
		return {}
	var e: Dictionary = entry
	var file := str(e["file"]) if e.get("file") is String else ""
	var def: Dictionary = e
	if e.get("_def") is Dictionary:
		def = e["_def"]
	elif not file.is_empty():
		def = read_json(file)
		if def.is_empty():
			problems.append("%s: segments[%d]: %s okunamadı" % [id, index, file])
	var merged := def.duplicate()
	for key: Variant in e:
		if not ["file", "_def", "events"].has(key):
			merged[key] = e[key]
	var fallback := file.get_file().get_basename() if not file.is_empty() else "segment_%d" % index
	var seg_id := str(merged["id"]) if merged.get("id") is String else fallback
	if not segment(seg_id).is_empty():
		problems.append("%s: segment kimliği iki kez: %s" % [id, seg_id])
	var crossfade: Variant = merged.get("crossfade_in", 0.0)
	return {
		"id": seg_id,
		"index": index,
		"file": file,
		"title": str(merged.get("title", "")),
		"scene": merged.get("scene"),
		"world": str(merged["world"]) if merged.get("world") is String else WORLD_NONE,
		"view": str(merged["view"]) if merged.get("view") is String else VIEW_MAIN,
		"crossfade_in": maxf(float(crossfade), 0.0) if (crossfade is float or crossfade is int) else 0.0,
		"preload_at": merged.get("preload_at"),
		"instantiate_at": merged.get("instantiate_at"),
		"length_spec": merged.get("length"),
		"events": merged.get("events", []),
	}


## Olay listesinin sözlük olanları (öbürleri sorun olarak yazılır).
func _event_list(raw: Variant, label: String) -> Array:
	var out: Array = []
	if raw == null:
		return out
	if not raw is Array:
		problems.append("%s: events liste olmalı" % label)
		return out
	for i in (raw as Array).size():
		var item: Variant = raw[i]
		if item is Dictionary:
			out.append(item)
		else:
			problems.append("%s: events[%d] sözlük olmalı" % [label, i])
	return out


## Segmentin olayları mutlak zamanla; başta kurulma (_enter), sonda kapanma (_exit) iç olayı.
func _segment_events(seg: Dictionary, resolver: _Resolver) -> Array:
	var start := float(seg["start"])
	var block: Array = [_internal(ENTER, str(seg["id"]), float(seg["enter"]), start)]
	for k in resolver.defs.size():
		var src: Dictionary = resolver.defs[k]
		var local := resolver.start_of(k)
		var duration := resolver.duration_of(k)
		if is_nan(local):
			local = 0.0
		var ev := src.duplicate(true)
		ev["spec"] = src.get("t")
		ev["type"] = str(src["type"]) if src.get("type") is String else "event"
		ev["id"] = str(src["id"]) if src.get("id") is String else ""
		ev["segment"] = str(seg["id"])
		ev["local_t"] = local
		ev["duration"] = duration
		ev["t"] = start + local
		ev["end"] = start + local + duration
		block.append(ev)
		_add_voice_cue(block, ev, start)
	block.append(_internal(EXIT, str(seg["id"]), float(seg["end"]), start))
	return block


## Dizinin kendi olayları (segment çapalarıyla) ve segment girdilerinin preload_at / instantiate_at'i.
func _sequence_events(def: Dictionary) -> Array:
	var defs: Array = _event_list(def.get("events"), id) if def.has("segments") else []
	for seg in segments:
		var world := str(seg["world"])
		for pair: Array in [["preload_at", "preload"], ["instantiate_at", "instantiate"]]:
			var at: Variant = seg[pair[0]]
			if at == null:
				continue
			if not world.begins_with("res://"):
				problems.append("%s: %s yalnız yolu verilen dünyada olur (world: %s)" % [seg["id"], pair[0], world])
				continue
			defs.append({"t": at, "type": pair[1], "path": world, "for": seg["id"]})
	var resolver := _Resolver.new()
	resolver.label = id
	resolver.seconds = _seconds
	resolver.defs = defs
	resolver.external = _sequence_anchor
	resolver.length = _total
	resolver.solve(_total)
	problems.append_array(resolver.problems)
	var block: Array = []
	for k in defs.size():
		var src: Dictionary = defs[k]
		var t := resolver.start_of(k)
		if is_nan(t):
			t = 0.0
		var duration := resolver.duration_of(k)
		var ev := src.duplicate(true)
		ev["spec"] = src.get("t")
		ev["type"] = str(src["type"]) if src.get("type") is String else "event"
		ev["id"] = str(src["id"]) if src.get("id") is String else ""
		ev["segment"] = ""
		ev["local_t"] = t
		ev["duration"] = duration
		ev["t"] = t
		ev["end"] = t + duration
		block.append(ev)
		_add_voice_cue(block, ev, 0.0)
	return block


## Dizi düzeyindeki çapa: "seg" (başı), "seg" + _end (sonu), "seg:çapa" (segmentin içinde). NAN: bilinmiyor.
func _sequence_anchor(name: String, at_end: bool) -> float:
	if name.contains(SEPARATOR):
		var seg_id := name.get_slice(SEPARATOR, 0)
		var seg := segment(seg_id)
		var resolver: _Resolver = _resolvers.get(seg_id)
		if seg.is_empty() or resolver == null:
			return NAN
		var local := resolver.anchor_time(name.substr(seg_id.length() + 1), at_end)
		return float(seg["start"]) + local if not is_nan(local) else NAN
	var whole := segment(name)
	if whole.is_empty():
		return NAN
	return float(whole["end"]) if at_end else float(whole["start"])


func _vo_seconds(line_id: String) -> float:
	return VoLines.seconds(line_id)


## Satırın ve şarkının ses isteği: sesin başlaması gereken andan lead_time kadar önce (cue: satırın olayı).
static func _add_voice_cue(block: Array, ev: Dictionary, start: float) -> void:
	if not LINE_TYPES.has(str(ev["type"])) or not ev.get("line") is String:
		return
	var t := maxf(float(ev["t"]) - CineAudio.lead_time(str(ev["line"])), 0.0)
	var cue := _internal(VOICE, str(ev["segment"]), t, start)
	cue["line"] = ev["line"]
	cue["cue"] = ev
	block.append(cue)


static func _internal(type: String, seg_id: String, t: float, start: float) -> Dictionary:
	return {"type": type, "id": "", "segment": seg_id, "t": t, "end": t, "duration": 0.0,
		"local_t": t - start, "spec": null}


func _before(a: Dictionary, b: Dictionary) -> bool:
	var ta := float(a["t"])
	var tb := float(b["t"])
	if ta < tb - EPSILON:
		return true
	if tb < ta - EPSILON:
		return false
	return int(a["order"]) < int(b["order"])


## Alan, dosya ve sınır denetimleri (zaman sorunları çözümde yazılır).
func _check() -> void:
	for seg in segments:
		var label := str(seg["id"])
		if not VIEWS.has(str(seg["view"])):
			problems.append("%s: view «%s» olamaz (%s)" % [label, seg["view"], ", ".join(VIEWS)])
		var world := str(seg["world"])
		if world != WORLD_CAMP and world != WORLD_NONE:
			if not world.begins_with("res://"):
				problems.append("%s: world camp, none ya da sahne yolu olmalı: «%s»" % [label, world])
			elif not ResourceLoader.exists(world):
				problems.append("%s: dünya sahnesi yok: %s" % [label, world])
		var scene: Variant = seg["scene"]
		if scene is String and not (scene as String).is_empty() and not ResourceLoader.exists(scene):
			problems.append("%s: sahne yok: %s" % [label, scene])
		elif scene != null and not scene is String and not scene is Script and not scene is PackedScene:
			problems.append("%s: scene yol, Script ya da PackedScene olmalı" % label)
	for ev in events:
		var type := str(ev["type"])
		if type.begins_with("_"):
			continue
		var where := "%s %s@%.3f" % [ev["segment"] if not str(ev["segment"]).is_empty() else id, type, float(ev["t"])]
		if REQUIRED.has(type):
			for key: String in REQUIRED[type]:
				if not ev.has(key):
					problems.append("%s: %s alanı yok" % [where, key])
			if type == "card" and not (ev.has("text") or ev.has("tr") or ev.has("en")):
				problems.append("%s: kartın metni (text ya da tr/en) yok" % where)
		if LINE_TYPES.has(type) and ev.get("line") is String and float(ev["duration"]) <= 0.0:
			problems.append("%s: «%s» satırının süresi yok (bilinmeyen satır?)" % [where, ev["line"]])
		if type in ["preload", "instantiate"] and ev.get("path") is String and not ResourceLoader.exists(ev["path"]):
			problems.append("%s: yüklenecek sahne yok: %s" % [where, ev["path"]])
		if float(ev["t"]) > _total + EPSILON:
			problems.append("%s: çizelgenin sonundan (%.3f) sonra" % [where, _total])


## Bir segmentin (ya da dizinin olaylarının) zamanlarını çözer: çapalar, süreler, "end" ve uzunluk.
class _Resolver:
	extends RefCounted

	## "end"e dayanan zaman, uzunluk bilinene dek ertelenir (ilk geçiş).
	const DEFER := -1.0e30

	var label := ""
	var defs: Array = []
	var seconds: Callable
	## Dışarıdaki çapa (ad, bitiş mi) → saniye; NAN bilinmiyor. Dizinin olayları segment çapalarını okur.
	var external: Callable
	var problems := PackedStringArray()
	var length := NAN
	var anchors: Dictionary = {}
	var _starts: Array = []
	var _visiting: Dictionary = {}
	var _end_allowed := true

	## Olayın kimliği dışındaki çapa adları: satırın kimliği (line, song), çekimin adı (shot).
	static func implicit_names(d: Dictionary) -> PackedStringArray:
		var out := PackedStringArray()
		var type := str(d.get("type", ""))
		if (type == "line" or type == "song") and d.get("line") is String:
			out.append(d["line"])
		elif type == "shot" and d.get("name") is String:
			out.append(d["name"])
		return out

	## Çözer: önce "end"e dayanmayanlar, sonra uzunluk (yazılmadıysa en geç bitiş), sonra kalanlar.
	func solve(length_spec: Variant) -> void:
		_starts.resize(defs.size())
		_starts.fill(null)
		_collect_anchors()
		for i in defs.size():
			start_of(i)
		if length_spec != null:
			_end_allowed = false
			var value := time_of(length_spec, "%s.length" % label)
			_end_allowed = true
			length = value if not is_nan(value) and value != DEFER else _latest_end()
		elif is_nan(length):
			length = _latest_end()
		for i in defs.size():
			if start_of(i) == DEFER:
				_starts[i] = NAN

	func start_of(i: int) -> float:
		if _starts[i] != null:
			return _starts[i]
		if _visiting.has(i):
			problems.append("%s: zaman döngüsü (%s)" % [label, _where(i)])
			return NAN
		var d: Dictionary = defs[i]
		if not d.has("t"):
			problems.append("%s: t yok" % _where(i))
			_starts[i] = NAN
			return NAN
		_visiting[i] = true
		var t := time_of(d["t"], _where(i))
		_visiting.erase(i)
		if t == DEFER:
			return DEFER
		_starts[i] = maxf(t, 0.0) if not is_nan(t) else NAN
		return _starts[i]

	func duration_of(i: int) -> float:
		var d: Dictionary = defs[i]
		var dur: Variant = d.get("dur")
		if (dur is float or dur is int) and float(dur) >= 0.0:
			return float(dur)
		var type := str(d.get("type", ""))
		if (type == "line" or type == "song") and d.get("line") is String and seconds.is_valid():
			return maxf(float(seconds.call(d["line"])), 0.0)
		return 0.0

	func end_of(i: int) -> float:
		var t := start_of(i)
		if t == DEFER or is_nan(t):
			return t
		return t + duration_of(i)

	## Çapanın segment içi zamanı (dizinin sorgusu için); bilinmiyorsa NAN.
	func anchor_time(name: String, at_end: bool) -> float:
		if name == CineTimeline.SEGMENT_END:
			return length
		if not anchors.has(name):
			return NAN
		var t := end_of(anchors[name]) if at_end else start_of(anchors[name])
		return t if t != DEFER else NAN

	func time_of(spec: Variant, where: String) -> float:
		var p := CineTimeline.parse_time(spec)
		if p.is_empty():
			problems.append("%s: bozuk zaman %s (sayı ya da «çapa[_end][±sn]»)" % [where, JSON.stringify(spec)])
			return NAN
		if p.has("at"):
			return float(p["at"])
		var name: String = p["anchor"]
		var at_end: bool = p["end"]
		var base := NAN
		if name == CineTimeline.SEGMENT_END and not anchors.has(name):
			if not _end_allowed:
				problems.append("%s: length segmentin sonuna (end) bağlanamaz" % where)
				return NAN
			if is_nan(length):
				return DEFER
			base = length
		elif anchors.has(name):
			base = end_of(anchors[name]) if at_end else start_of(anchors[name])
			if base == DEFER:
				return DEFER
			if is_nan(base):
				return NAN
		elif external.is_valid():
			base = float(external.call(name, at_end))
		if is_nan(base):
			if not anchors.has(name):
				problems.append("%s: bilinmeyen çapa «%s»" % [where, name])
			return NAN
		return base + float(p["offset"])

	func _collect_anchors() -> void:
		for i in defs.size():
			var key: Variant = (defs[i] as Dictionary).get("id")
			if key is String and not (key as String).is_empty():
				if anchors.has(key):
					problems.append("%s: kimlik iki kez: %s" % [label, key])
				else:
					anchors[key] = i
				if (key as String).ends_with("_end"):
					problems.append("%s: kimlik _end ile bitemez (bitiş çapasıyla karışır): %s" % [label, key])
		for i in defs.size():
			for key in implicit_names(defs[i]):
				if not anchors.has(key):
					anchors[key] = i

	func _latest_end() -> float:
		var latest := 0.0
		for i in defs.size():
			var t: Variant = _starts[i]
			if t == null or is_nan(t) or t == DEFER:
				continue
			latest = maxf(latest, float(t) + duration_of(i))
		return latest

	func _where(i: int) -> String:
		var d: Dictionary = defs[i]
		var name := str(d["id"]) if d.get("id") is String else str(d.get("type", "olay"))
		return "%s.events[%d] (%s)" % [label, i, name]
