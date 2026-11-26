class_name VoLines
extends RefCounted
## Seslendirme satırlarının kataloğu: `data/vo_lines.json` (K61; godot.md §3.3, audio.md §5).
##
## Satır alanları: `id`, `act` (sayı; int() ile okunur), `kind` (`song` şarkı, `sub` şarkının altyazı dizesi,
## `line` okunan satır), `speaker` (`speakers` tablosundaki kişi), `tier` (K61'in dilimi A–D), `scene`
## (Önsöz'de `camp`, `myth`, `birth`; köprüde null; oynanan sahnelerde `childhood`, `depart`, Serbest Gez'in kampında `camp_tour`:
## E20/7, SceneVoice), `text` {`en` söylenen, `tr` altyazı}, `est` (tasarımın tahmini,
## saniye; değişmez), `seconds` (dosya yokken `est`, dosya gelince gerçek süre), `file` ve `timing` (ses ve
## sözcük zamanı dosyası ya da null), `voice`, `model`, `stability`, `similarity_boost`, `fx` (ses zinciri,
## ör. `erlik`), `take` (çekim; tohum ondan kayar) ve `take_hash` (dosyayı üreten girdilerin karması).
## İsteğe bağlı: `use` (köprünün Yol Haritası maddesi), `of` + `window` (altyazı dizesinin şarkısı ve şarkı
## içi saniyeleri), `voice_pending` (ses seçimi bekleyen kişi; satır geçici sesle okunur), `voice_name` (`voice`
## kişinin `speakers` sesinden başkaysa adı), `node` (yapı kuralının düğümü), `gain_db` (oyunun satıra uyguladığı kazanç, dB: dosyanın
## ölçülen yüksekliğini −18 LUFS'a getirir (K78), en çok +6 / −10 dB, gerçek tepe −1 dBFS'u aşmaz; dosya yeniden okunursa yeniden ölçülür;
## SceneVoice play_line'ın volume_db'sine verir). `dirs` perde başına dosya klasörüdür;
## `locks` perde başına metin kilididir. Okuma satırın `voice`'unu kullanır; `speakers` tablosu kişinin varsayılan sesini
## yazar. Ayrışabilirler: Hereka'nın Önsöz satırı 39 yaşın sesidir (Heather Faith), tablo yaşlı Hereka'nındır (Lea; K95).
##
## Yer tutucu (K89): dosyası olmayan satır altyazıyla `seconds` süresince akar; `audio_path` boş döner.
## Ses yolları kodda yazılmaz, veriden gelir (test_audio_budget kodda geçen her ses yolunu sayar).
##   VoLines.seconds("act0.myth.3")         # dosya yokken tahmin, dosya gelince gerçek süre
##   VoLines.audio_path("act0.bard.song")   # çalınabilir ses dosyası ya da ""
##   VoLines.sub_lines("act0.bard.song")    # şarkının iki dizesi, şarkı içi saniyeleriyle
## Üretim aracı `tools/elevenlabs_audio.sh` aynı veriyi okur ve yazar; kilit ve çekim karmasını aynı
## kuralla hesaplar (lock_hash, take_hash).

const DATA_PATH := "res://data/vo_lines.json"
const VERSION := 1
const KINDS: Array[String] = ["song", "sub", "line"]
## K61'in dilimleri: A hep, B düğüm, C havuz, D yazı.
const TIERS: Array[String] = ["A", "B", "C", "D"]
## Seslendirilen dilimler (D yazıdır: ses almaz).
const VOICED_TIERS: Array[String] = ["A", "B", "C"]
## Metin kilidi olmadan üretilmeyen dilimler (K61).
const LOCKED_TIERS: Array[String] = ["A", "B"]
## Okuma satırlarının modelleri ve `eleven_v3`'ün kabul ettiği kararlılıklar (K17).
const TTS_MODELS: Array[String] = ["eleven_v3"]
const STABILITY_STEPS: Array[float] = [0.0, 0.5, 1.0]
## Satırın ses zincirleri (audio.md §5: Erlik ve Tengri).
const FX_CHAINS: Array[String] = ["erlik", "tengri"]
## Dosyası ve süresi olmayan satırın okuma hızı: Eldrin'in çekimleri saniyede ≈12 karakter okur.
const CHARS_PER_SECOND := 12.0
## Dosya süresi ile `seconds` arasındaki en büyük fark (saniye).
const SECONDS_TOLERANCE := 0.05
## Çekim karmasının kaynağı ve ayar sırası: prototipin tools/voices.mjs karmasıyla aynıdır
## (sha1 [kaynak, ses, model, ayar, metin], ilk 12 onaltılık hane).
const TAKE_SOURCE := "elevenlabs"
const SETTING_KEYS: Array[String] = ["stability", "similarity_boost"]

static var _data: Dictionary = {}
static var _loaded := false
static var _by_id: Dictionary = {}
static var _timings: Dictionary = {}


## Verinin tamamı (önbellekli). Dosya yoksa ya da bozuksa boş sözlük.
static func data() -> Dictionary:
	if _loaded:
		return _data
	_loaded = true
	_data = {}
	_by_id = {}
	if FileAccess.file_exists(DATA_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		if parsed is Dictionary:
			_data = parsed
	for item: Variant in lines():
		if item is Dictionary:
			_by_id[str(item.get("id", ""))] = item
	return _data


## Önbelleği boşaltır (veri ya da zaman dosyası değişince).
static func clear_cache() -> void:
	_data = {}
	_loaded = false
	_by_id = {}
	_timings = {}


## Bütün satırlar, dosyadaki sırayla.
static func lines() -> Array:
	var list: Variant = data().get("lines", [])
	return list if list is Array else []


## Satır (yoksa boş sözlük).
static func line(id: String) -> Dictionary:
	data()
	return _by_id.get(id, {})


static func has_line(id: String) -> bool:
	return not line(id).is_empty()


## Kimliği öneki tutan satırlar, dosyadaki sırayla ("" hepsi).
static func ids(prefix: String = "") -> PackedStringArray:
	var out := PackedStringArray()
	for item: Variant in lines():
		if item is Dictionary:
			var id := str(item.get("id", ""))
			if id.begins_with(prefix):
				out.append(id)
	return out


## Tasarımın tahmini süresi (saniye); yoksa EN metinden 12 karakter/sn.
static func est(id: String) -> float:
	var l := line(id)
	var value: Variant = l.get("est")
	if _is_number(value) and float(value) > 0.0:
		return float(value)
	return chars(id) / CHARS_PER_SECOND


## Satırın süresi (saniye): dosya gelince gerçek süre, yoksa tahmin. Sinema çizelgesi bunu okur.
static func seconds(id: String) -> float:
	var value: Variant = line(id).get("seconds")
	if _is_number(value) and float(value) > 0.0:
		return float(value)
	return est(id)


## Söylenen İngilizce metnin karakter sayısı (konuşmada 1 karakter 1 kredi).
static func chars(id: String) -> int:
	return _text_of(line(id), "en").length()


static func speaker(id: String) -> String:
	return str(line(id).get("speaker", ""))


## Konuşanın altyazıdaki adı ("tr" ya da "en"); bilinmiyorsa kimliği.
static func speaker_name(id: String, lang: String = "tr") -> String:
	var who := speaker(id)
	var info: Variant = (data().get("speakers", {}) as Dictionary).get(who, {})
	if info is Dictionary and info.get("name") is Dictionary:
		var name := str((info["name"] as Dictionary).get(lang, ""))
		if not name.is_empty():
			return name
	return who


static func tier(id: String) -> String:
	return str(line(id).get("tier", ""))


## Oyunun satıra uyguladığı kazanç (dB; −18 LUFS'a getirir, K78); yoksa 0.
static func gain_db(id: String) -> float:
	var value: Variant = line(id).get("gain_db")
	return float(value) if _is_number(value) else 0.0


## Satırın ses zinciri (ör. "erlik"); yoksa "".
static func fx(id: String) -> String:
	var value: Variant = line(id).get("fx")
	return value if value is String else ""


## Altyazı metni: Türkçe arayüzde TR, İngilizcede EN (K61); istenen dil yoksa söylenen EN, o da yoksa TR.
static func subtitle(id: String, lang: String = "tr") -> String:
	var l := line(id)
	for key in [lang, "en", "tr"]:
		var text := _text_of(l, key)
		if not text.is_empty():
			return text
	return ""


## Veride yazılı ses dosyası ("" yoksa); dosyanın var olup olmadığına bakmaz.
static func declared_file(id: String) -> String:
	var value: Variant = line(id).get("file")
	return value if value is String else ""


## Çalınabilir ses dosyası: veride yazılı, yüklenebilir ve bugünkü metnin kaydı; değilse "" (satır
## altyazıyla akar, K89). Metni kayıttan sonra değişen satırın eski kaydı çalınmaz (K36: eski metinli
## kayıt kalkar); dosyası yeniden üretilene dek declared_file'da durur.
static func audio_path(id: String) -> String:
	var path := declared_file(id)
	if path.is_empty() or not ResourceLoader.exists(path) or is_stale(id):
		return ""
	return path


static func has_audio(id: String) -> bool:
	return not audio_path(id).is_empty()


## Üretim aracının bu satır için yazacağı ses dosyası: perdenin klasörü (`dirs`) ve kimlik.
static func target_path(id: String) -> String:
	var dir := str((data().get("dirs", {}) as Dictionary).get(str(int(line(id).get("act", -1))), ""))
	return "" if dir.is_empty() else dir.path_join(id + ".mp3")


## Sözcük zamanı dosyası (önbellekli): {id, take, seed, hash, model, seconds, words [{w, t0, t1}], ...};
## yoksa boş sözlük. Şarkınınkinde ayrıca `lines` (dizelerin penceresi), `pan_max` ve `beat` vardır.
static func timing(id: String) -> Dictionary:
	if _timings.has(id):
		return _timings[id]
	var result: Dictionary = {}
	var path: Variant = line(id).get("timing")
	if path is String and FileAccess.file_exists(path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			result = parsed
	_timings[id] = result
	return result


## Sözcükler ve zamanları ([{w, t0, t1}], saniye, dosyanın başından); zaman dosyası yoksa boş.
static func words(id: String) -> Array:
	var list: Variant = timing(id).get("words", [])
	return list if list is Array else []


## Şarkının altyazı dizeleri, şarkı içi saniyeleriyle: [{id, t0, t1, tr, en}], başlangıca göre sıralı.
static func sub_lines(song_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for item: Variant in lines():
		if not item is Dictionary or str(item.get("of", "")) != song_id:
			continue
		var window: Variant = item.get("window")
		if not window is Array or (window as Array).size() != 2:
			continue
		out.append({"id": str(item.get("id", "")), "t0": float(window[0]), "t1": float(window[1]),
			"tr": _text_of(item, "tr"), "en": _text_of(item, "en")})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["t0"] < b["t0"])
	return out


# --- Metin kilidi ve çekim karması -------------------------------------------------------

## Perdenin kilitlenen metni: perdenin A ve B satırları, kimliğe göre sıralı «kimlik<TAB>EN» satırları.
static func lock_text(act: int, source: Dictionary = {}) -> String:
	var d := source if not source.is_empty() else data()
	var rows: Array = []
	for item: Variant in d.get("lines", []):
		if item is Dictionary and _is_number(item.get("act")) and int(item["act"]) == act \
				and LOCKED_TIERS.has(str(item.get("tier", ""))):
			rows.append([str(item.get("id", "")), _text_of(item, "en")])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var parts := PackedStringArray()
	for row: Array in rows:
		parts.append("%s\t%s" % [row[0], row[1]])
	return "\n".join(parts)


## Kilidin karması: lock_text'in SHA-1'i (UTF-8, onaltılık). Araç aynı karmayı hesaplar.
static func lock_hash(act: int, source: Dictionary = {}) -> String:
	return lock_text(act, source).sha1_text()


## Perdenin metni kilitli mi: `locks[act].hash` bugünkü metnin karmasıyla aynı.
static func is_locked(act: int, source: Dictionary = {}) -> bool:
	var d := source if not source.is_empty() else data()
	var lock: Variant = (d.get("locks", {}) as Dictionary).get(str(act))
	return lock is Dictionary and str(lock.get("hash", "")) == lock_hash(act, d)


## Okuma satırının çekim karması: sha1 [kaynak, ses, model, {stability, similarity_boost}, EN metin],
## ilk 12 hane (prototipin tools/voices.mjs karmasıyla aynı). Sesi olmayan satırda "".
static func take_hash(item: Dictionary) -> String:
	var voice: Variant = item.get("voice")
	var model: Variant = item.get("model")
	if not voice is String or not model is String:
		return ""
	var settings := PackedStringArray()
	for key in SETTING_KEYS:
		var value: Variant = item.get(key)
		if _is_number(value):
			settings.append("%s:%s" % [JSON.stringify(key), _json_number(float(value))])
	var parts := PackedStringArray([JSON.stringify(TAKE_SOURCE), JSON.stringify(voice), JSON.stringify(model),
		"{%s}" % ",".join(settings), JSON.stringify(_text_of(item, "en"))])
	return ("[%s]" % ",".join(parts)).sha1_text().substr(0, 12)


## Dosyası eski girdilerden mi (okuma satırında metin, ses ya da ayar dosyadan sonra değişti mi)?
## Eskiyen dosya yer tutucu olarak çalar; araç onu bir sonraki üretimde yeniden okur.
static func is_stale(id: String) -> bool:
	var l := line(id)
	if str(l.get("kind", "")) != "line" or declared_file(id).is_empty():
		return false
	return str(l.get("take_hash", "")) != take_hash(l)


# --- Denetim -----------------------------------------------------------------------------

## Verinin kural ihlalleri (boşsa veri geçerli): şema, kimlik tekilliği, dilim, bilinen konuşmacı,
## yazılı dosya ve zaman yollarının varlığı, şarkının altyazı pencereleri, kilitli perdenin metni ve
## yapı kuralı. Sınama (test_vo_budget.gd) bunu gerçek veride ve bozulmuş kopyada çalıştırır.
static func problems(d: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	if not _is_number(d.get("version")) or int(d["version"]) != VERSION:
		out.append("version %d olmalı" % VERSION)
	var speakers: Dictionary = d.get("speakers") if d.get("speakers") is Dictionary else {}
	if speakers.is_empty():
		out.append("speakers tablosu yok")
	var dirs: Dictionary = d.get("dirs") if d.get("dirs") is Dictionary else {}
	if not d.get("lines") is Array:
		out.append("lines listesi yok")
		return out
	var all: Array = d["lines"]
	var songs := {}
	for item: Variant in all:
		if item is Dictionary and str(item.get("kind", "")) == "song":
			songs[str(item.get("id", ""))] = item
	var seen := {}
	for item: Variant in all:
		if not item is Dictionary:
			out.append("satır sözlük değil: %s" % str(item))
			continue
		var l: Dictionary = item
		var id := str(l.get("id", ""))
		if id.is_empty():
			out.append("kimliği olmayan satır: %s" % str(l))
			continue
		if seen.has(id):
			out.append("%s: kimlik iki kez geçiyor" % id)
		seen[id] = true
		_check_line(out, id, l, speakers, dirs, songs)
	out.append_array(_lock_problems(d))
	out.append_array(structure_problems(all))
	return out


## Yapı kuralı (K61): bir düğümde aynı konuşmacı sesliden sessize geçmez; düğüm ya bütün seslidir ya
## bütün yazı. Düğüm satırın `node` alanıdır; düğümü olmayan satır kurala girmez.
static func structure_problems(all: Array) -> PackedStringArray:
	var out := PackedStringArray()
	var groups := {}
	for item: Variant in all:
		if not item is Dictionary or not item.get("node") is String:
			continue
		var key := "%s · %s" % [item["node"], str(item.get("speaker", ""))]
		if not groups.has(key):
			groups[key] = {"voiced": [], "silent": []}
		var voiced := VOICED_TIERS.has(str(item.get("tier", "")))
		groups[key]["voiced" if voiced else "silent"].append(str(item.get("id", "")))
	for key: String in groups:
		var g: Dictionary = groups[key]
		if not (g["voiced"] as Array).is_empty() and not (g["silent"] as Array).is_empty():
			out.append("%s: aynı düğümde aynı konuşmacı sesliden sessize geçiyor (sesli %s, yazı %s)"
					% [key, ", ".join(PackedStringArray(g["voiced"])), ", ".join(PackedStringArray(g["silent"]))])
	return out


static func _check_line(out: PackedStringArray, id: String, l: Dictionary, speakers: Dictionary,
		dirs: Dictionary, songs: Dictionary) -> void:
	if not _is_number(l.get("act")) or float(l["act"]) != floorf(float(l["act"])) or float(l["act"]) < 0.0:
		out.append("%s: act sıfır ya da artı tam sayı olmalı" % id)
	var kind := str(l.get("kind", ""))
	if not KINDS.has(kind):
		out.append("%s: kind %s olmalı, «%s» yazıyor" % [id, "/".join(KINDS), kind])
	if not speakers.has(str(l.get("speaker", ""))):
		out.append("%s: konuşmacı «%s» speakers tablosunda yok" % [id, str(l.get("speaker", ""))])
	if not TIERS.has(str(l.get("tier", ""))):
		out.append("%s: tier A–D olmalı, «%s» yazıyor" % [id, str(l.get("tier", ""))])
	if not l.get("text") is Dictionary or _text_of(l, "en").strip_edges().is_empty() \
			or _text_of(l, "tr").strip_edges().is_empty():
		out.append("%s: text.en ve text.tr dolu olmalı" % id)
	for key in ["est", "seconds"]:
		if not _is_number(l.get(key)) or float(l[key]) <= 0.0:
			out.append("%s: %s artı bir sayı olmalı" % [id, key])
	for key in ["scene", "file", "timing", "voice", "model", "fx", "take_hash"]:
		if not l.has(key):
			out.append("%s: %s alanı yok (yoksa null yazılır)" % [id, key])
		elif l[key] != null and not l[key] is String:
			out.append("%s: %s metin ya da null olmalı" % [id, key])
	for key in ["stability", "similarity_boost"]:
		if not l.has(key):
			out.append("%s: %s alanı yok (yoksa null yazılır)" % [id, key])
		elif l[key] != null and not _is_number(l[key]):
			out.append("%s: %s sayı ya da null olmalı" % [id, key])
	if not _is_number(l.get("take")) or float(l["take"]) < 0.0 or float(l["take"]) != floorf(float(l["take"])):
		out.append("%s: take sıfır ya da artı tam sayı olmalı" % id)
	if l.has("voice_pending") and not l["voice_pending"] is bool:
		out.append("%s: voice_pending true ya da false olmalı" % id)
	if l.get("fx") is String and not FX_CHAINS.has(l["fx"]):
		out.append("%s: fx «%s» bilinen bir zincir değil (%s)" % [id, l["fx"], ", ".join(FX_CHAINS)])
	# Yazılı yollar var olmalı.
	if l.get("file") is String and not (FileAccess.file_exists(l["file"]) or ResourceLoader.exists(l["file"])):
		out.append("%s: ses dosyası yok: %s" % [id, l["file"]])
	if l.get("timing") is String:
		if not FileAccess.file_exists(l["timing"]):
			out.append("%s: zaman dosyası yok: %s" % [id, l["timing"]])
		elif not JSON.parse_string(FileAccess.get_file_as_string(l["timing"])) is Dictionary:
			out.append("%s: zaman dosyası JSON sözlüğü değil: %s" % [id, l["timing"]])
	match kind:
		"sub":
			_check_sub(out, id, l, songs)
		"line":
			if l.get("voice") is String:
				if not TTS_MODELS.has(str(l.get("model", ""))):
					out.append("%s: okuma satırının modeli %s olmalı" % [id, "/".join(TTS_MODELS)])
				if not _is_number(l.get("stability")) or not STABILITY_STEPS.has(float(l["stability"])):
					out.append("%s: eleven_v3 kararlılığı yalnız 0, 0,5 ya da 1 olabilir (K17)" % id)
				if not dirs.has(str(int(l.get("act", -1)) if _is_number(l.get("act")) else "")):
					out.append("%s: perdesinin dosya klasörü (dirs) yok" % id)
			if l.get("file") is String and not l.get("take_hash") is String:
				out.append("%s: dosyası olan okuma satırının take_hash'i yok" % id)


static func _check_sub(out: PackedStringArray, id: String, l: Dictionary, songs: Dictionary) -> void:
	var song_id := str(l.get("of", ""))
	if not songs.has(song_id):
		out.append("%s: altyazı dizesinin şarkısı (of) yok: «%s»" % [id, song_id])
		return
	if l.get("file") != null:
		out.append("%s: altyazı dizesi ayrıca okunmaz, file null olmalı" % id)
	var window: Variant = l.get("window")
	if not window is Array or (window as Array).size() != 2 or not _is_number(window[0]) or not _is_number(window[1]):
		out.append("%s: window [t0, t1] olmalı" % id)
		return
	var song_seconds := float((songs[song_id] as Dictionary).get("seconds", 0.0))
	var t0 := float(window[0])
	var t1 := float(window[1])
	if t0 < 0.0 or t1 <= t0 or t1 > song_seconds + SECONDS_TOLERANCE:
		out.append("%s: pencere %.3f–%.3f şarkının içinde değil (0–%.3f)" % [id, t0, t1, song_seconds])


static func _lock_problems(d: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	var locks: Variant = d.get("locks", {})
	if not locks is Dictionary:
		out.append("locks sözlük olmalı")
		return out
	for act_key: Variant in locks:
		var lock: Variant = locks[act_key]
		if not str(act_key).is_valid_int():
			out.append("kilit anahtarı perde numarası olmalı: «%s»" % str(act_key))
			continue
		if not lock is Dictionary or not lock.get("hash") is String or not lock.get("date") is String \
				or not lock.get("by") is String:
			out.append("perde %s kilidi {hash, date, by} olmalı" % str(act_key))
			continue
		var expected := lock_hash(int(str(act_key)), d)
		if lock["hash"] != expected:
			out.append("perde %s kilitli ama A/B metni kilidin karmasıyla tutmuyor (kilit %s, metin %s): metin kilitten sonra değişti"
					% [str(act_key), str(lock["hash"]).substr(0, 8), expected.substr(0, 8)])
	return out


static func _text_of(item: Dictionary, lang: String) -> String:
	var text: Variant = item.get("text")
	if text is Dictionary:
		var value: Variant = (text as Dictionary).get(lang)
		if value is String:
			return value
	return ""


static func _is_number(value: Variant) -> bool:
	return value is float or value is int


## JSON sayısı JavaScript'in yazdığı gibi: tam değer ondalıksız (1, 0), öbürü kısa biçimde (0.5, 0.8).
static func _json_number(value: float) -> String:
	if value == floorf(value) and absf(value) < 1e15:
		return str(int(value))
	return str(value)
