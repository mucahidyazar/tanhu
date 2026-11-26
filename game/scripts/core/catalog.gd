class_name Catalog
extends RefCounted
## Veri kataloğu (godot.md §2, §8.3; Yol Haritası data-catalog): data/**/*.json ilk çağrıda okunur ve önbelleğe girer; oyuncu dizgeleri
## data/i18n/strings.csv'dedir (sütunlar keys, tr, en; Godot'nun çeviri CSV biçimi). Autoload değildir: paylaşılan örnek
## (Catalog.shared()) ilk çağrıda kurulur; sınamalar kendi örneklerini başka bir kökle kurar (Catalog.new("res://tests/fixtures/x")).
## Var olan okuyucular (DestanKitabi, NewGameFlow, ChildhoodScene, CineTimeline, Weapons, Mount...) kendi dosyalarını okumayı sürdürür;
## Catalog'a geçmeleri zorunlu değildir, aynı dosyayı Catalog'dan da okuyabilirler.
##
## Dosya yolu data/'ya görelidir ve uzantısızdır ("fauna/kinds"; "fauna/kinds.json" ve "res://data/fauna/kinds.json" de okunur).
## Kayıt tablosu bir dosyanın bir listesidir: id'li sözlüklerin dizisi ([{id, ...}]) ya da kimlikle anahtarlanmış sözlük ({sheep: {...}};
## «_» ile başlayan anahtar not sayılır).
##   Catalog.data("fauna/kinds")                         # ayrıştırılmış JSON (Dictionary ya da Array); yoksa ya da bozuksa null
##   Catalog.lookup("fauna/kinds", "kinds", "sheep")     # kayıt; yoksa {}
##   Catalog.text("SAVE_LOAD_FAILED")                    # «Bu kayıt açılamadı.» (dil Catalog.language; anahtar yoksa anahtar)
##   Catalog.pick({"tr": "Koyun", "en": "Sheep"}, "en")  # «Sheep» (veride satır içi çift dil)
##   Catalog.install_translations("tr")                  # tr("KEY") için çeviriler TranslationServer'a (dil verilirse yerel de)
##
## strings.csv içe aktarılmaz (data/i18n/strings.csv.import: importer="keep"): dosya dışa aktarımda olduğu gibi kalır, çeviriler
## çalışırken ondan kurulur; proje ayarına çeviri dosyası yazmak gerekmez. Ayarlar'dan dil değişimi release-p2'dedir.

const ROOT := "res://data"
const STRINGS_PATH := "res://data/i18n/strings.csv"
## Oyuncu dizgelerinin dilleri (CSV'nin sütun sırası: keys, tr, en).
const LANGS: Array[String] = ["tr", "en"]
const STRINGS_HEADER: Array[String] = ["keys", "tr", "en"]

## Paylaşılan örnek (ilk çağrıda).
static var _shared: Catalog
## Catalog.text'in varsayılan dili ("tr" ya da "en"; arayüz bugün Türkçedir).
static var language := "tr"
## install_translations'ın kurduğu çeviriler (yeniden kurulunca eskisi kalkar).
static var _installed: Array[Translation] = []

## Kök klasör (res://data ya da sınamanın klasörü).
var root := ROOT
## Dizge dosyası (strings.csv).
var strings_path := STRINGS_PATH

## Dosya → ayrıştırılmış değer (okunamayan dosyanın değeri null'dır, nedeni _errors'ta).
var _files: Dictionary = {}
var _errors: Dictionary = {}
## "dosya#liste" → {id: kayıt}.
var _tables: Dictionary = {}
var _scanned := false
var _strings: Dictionary = {}
var _string_errors := PackedStringArray()
var _strings_read := false


func _init(p_root: String = ROOT, p_strings_path: String = STRINGS_PATH) -> void:
	root = p_root.trim_suffix("/")
	strings_path = p_strings_path


# --- Paylaşılan örnek ----------------------------------------------------------------------------------------

static func shared() -> Catalog:
	if _shared == null:
		_shared = Catalog.new()
	return _shared


## Paylaşılan örneği bırakır (sınamalar veri dosyasını değiştirince; sonraki çağrı yeniden okur).
static func reset() -> void:
	_shared = null


static func data(rel: String) -> Variant:
	return shared().read(rel)


static func lookup(rel: String, list_key: String, id: String) -> Dictionary:
	return shared().record(rel, list_key, id)


static func table_of(rel: String, list_key: String) -> Dictionary:
	return shared().table(rel, list_key)


## Oyuncu dizgesi: anahtarın verilen (boşsa Catalog.language) dildeki metni; o dilde yoksa Türkçesi, hiç yoksa anahtarın kendisi.
static func text(key: String, lang: String = "") -> String:
	return shared().translate(key, lang)


## Verideki satır içi çift dil ({tr, en}) ya da düz metin: istenen dil, yoksa Türkçe (NewGameFlow.text ile aynı kural).
static func pick(value: Variant, lang: String = "") -> String:
	var l := lang if not lang.is_empty() else language
	if value is Dictionary:
		var d := value as Dictionary
		var v: Variant = d.get(l)
		if (v is String or v is StringName) and not String(v).is_empty():
			return String(v)
		return str(d.get("tr", ""))
	return str(value) if value != null else ""


## Varsayılan dili değiştirir ("tr" ya da "en"; başkası Türkçe sayılır).
static func set_language(lang: String) -> void:
	language = lang if LANGS.has(lang) else "tr"


## tr("KEY") için strings.csv'den Translation kurar ve TranslationServer'a ekler (öncekileri kaldırır). locale verilirse yerel de olur.
## Döner: kurulan dil sayısı.
static func install_translations(locale: String = "") -> int:
	uninstall_translations()
	var table := shared().strings()
	for lang in LANGS:
		var t := Translation.new()
		t.locale = lang
		for key: String in table:
			var msg := str((table[key] as Dictionary).get(lang, ""))
			if not msg.is_empty():
				t.add_message(StringName(key), StringName(msg))
		TranslationServer.add_translation(t)
		_installed.append(t)
	if not locale.is_empty():
		TranslationServer.set_locale(locale)
	return _installed.size()


## install_translations'ın kurduklarını kaldırır (yerel değişmez).
static func uninstall_translations() -> void:
	for t in _installed:
		TranslationServer.remove_translation(t)
	_installed.clear()


# --- Dosyalar ------------------------------------------------------------------------------------------------

## Dosyanın ayrıştırılmış değeri (önbellekli; ilk çağrıda okunur). Yoksa ya da bozuksa null (nedeni error()).
func read(rel: String) -> Variant:
	var key := normalize(rel)
	if _files.has(key):
		return _files[key]
	var value: Variant = null
	var path := root.path_join(key + ".json")
	if not FileAccess.file_exists(path):
		_errors[key] = "dosya yok: %s" % path
	else:
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(path)) != OK:
			_errors[key] = "%s: JSON %d. satırda bozuk (%s)" % [path, json.get_error_line(), json.get_error_message()]
		else:
			value = json.data
	_files[key] = value
	return value


## Dosya var ve okunabiliyor mu?
func has_file(rel: String) -> bool:
	return read(rel) != null


## Dosyanın okunamama nedeni ("" okunduysa ya da hiç istenmediyse).
func error(rel: String) -> String:
	return str(_errors.get(normalize(rel), ""))


## Kökün altındaki bütün .json dosyalarını okur. Döner: dosya sayısı.
func load_all() -> int:
	if not _scanned:
		_scanned = true
		for rel in _scan(root, ""):
			read(rel)
	return files().size()


## Okunan (ya da load_all'la taranan) dosyalar, sıralı.
func files() -> PackedStringArray:
	var out := PackedStringArray()
	for k: String in _files:
		out.append(k)
	out.sort()
	return out


## Okunamayan dosyalar: {dosya: neden}.
func errors() -> Dictionary:
	return _errors.duplicate()


## "fauna/kinds.json", "res://data/fauna/kinds.json" → "fauna/kinds".
func normalize(rel: String) -> String:
	var r := rel.strip_edges()
	var prefix := root + "/"
	if r.begins_with(prefix):
		r = r.substr(prefix.length())
	elif r.begins_with(ROOT + "/"):
		r = r.substr(ROOT.length() + 1)
	return r.trim_suffix(".json")


## Önbelleği boşaltır (dosyalar ve dizgeler yeniden okunur).
func clear() -> void:
	_files.clear()
	_errors.clear()
	_tables.clear()
	_scanned = false
	_strings.clear()
	_string_errors.clear()
	_strings_read = false


# --- Kayıt tabloları -----------------------------------------------------------------------------------------

## Dosyanın listesinin kayıtları: {id: kayıt} (önbellekli). Liste id'li sözlüklerin dizisi ya da kimlikle anahtarlanmış sözlüktür; id'si
## olmayan eleman ve «_» ile başlayan anahtar atlanır. list_key boşsa dosyanın kendisi listedir.
func table(rel: String, list_key: String = "") -> Dictionary:
	var key := "%s#%s" % [normalize(rel), list_key]
	if _tables.has(key):
		return _tables[key]
	var out := {}
	for row in rows(rel, list_key):
		out[str(row[0])] = row[1]
	_tables[key] = out
	return out


## Listenin kayıtları sırayla: [[id, kayıt], ...] (aynı id iki kez gelebilir: tekillik sınaması bunu okur).
func rows(rel: String, list_key: String = "") -> Array:
	var out: Array = []
	var d: Variant = read(rel)
	var list: Variant = d
	if not list_key.is_empty():
		list = (d as Dictionary).get(list_key) if d is Dictionary else null
	if list is Array:
		for e: Variant in list:
			if e is Dictionary and (e as Dictionary).has("id"):
				out.append([str(e["id"]), e])
	elif list is Dictionary:
		for k: Variant in list:
			var v: Variant = list[k]
			if str(k).begins_with("_") or not v is Dictionary:
				continue
			out.append([str(k), v])
	return out


## Tablonun kimlikleri, sırayla.
func ids(rel: String, list_key: String = "") -> PackedStringArray:
	var out := PackedStringArray()
	for row in rows(rel, list_key):
		out.append(str(row[0]))
	return out


## Kimliğiyle kayıt (yoksa {}).
func record(rel: String, list_key: String, id: String) -> Dictionary:
	var t := table(rel, list_key)
	return t.get(id, {})


# --- Oyuncu dizgeleri ---------------------------------------------------------------------------------------

## strings.csv: {anahtar: {tr, en}} (önbellekli). Bozuk satırlar string_errors'tadır; aynı anahtarın ikincisi yok sayılır.
func strings() -> Dictionary:
	if _strings_read:
		return _strings
	_strings_read = true
	var f := FileAccess.open(strings_path, FileAccess.READ)
	if f == null:
		_string_errors.append("dizge dosyası açılamadı: %s" % strings_path)
		return _strings
	var header := f.get_csv_line()
	var cols := PackedStringArray()
	for h in header:
		cols.append(h.strip_edges().to_lower())
	if cols.size() < STRINGS_HEADER.size() or cols[0] != "keys" or cols[1] != "tr" or cols[2] != "en":
		_string_errors.append("%s: başlık «keys,tr,en» olmalı, «%s»" % [strings_path, ",".join(header)])
		return _strings
	var line := 1
	while not f.eof_reached():
		var row := f.get_csv_line()
		line += 1
		if row.size() == 1 and row[0].strip_edges().is_empty():
			continue
		var key := row[0].strip_edges()
		if key.is_empty():
			continue
		if row.size() != cols.size():
			_string_errors.append("%s:%d «%s»: %d sütun (%d olmalı)" % [strings_path, line, key, row.size(), cols.size()])
			continue
		if _strings.has(key):
			_string_errors.append("%s:%d «%s» iki kez yazılmış" % [strings_path, line, key])
			continue
		var entry := {}
		for c in range(1, cols.size()):
			entry[cols[c]] = row[c]
		_strings[key] = entry
	return _strings


func string_errors() -> PackedStringArray:
	strings()
	return _string_errors


func has_string(key: String) -> bool:
	return strings().has(key)


## Anahtarın metni (bkz. Catalog.text).
func translate(key: String, lang: String = "") -> String:
	var entry: Variant = strings().get(key)
	if not entry is Dictionary:
		return key
	var l := lang if not lang.is_empty() else language
	var v := str((entry as Dictionary).get(l, ""))
	if v.is_empty():
		v = str((entry as Dictionary).get("tr", ""))
	return v if not v.is_empty() else key


## Yolun değerleri (şema sınaması, test_data_catalog.gd'nin REFS kuralları): «a.b» sözlük anahtarı, «x[]» dizinin her elemanı, «*»
## sözlüğün her değeri («_» ile başlayan anahtar hariç), «..ad» altındaki her yerde (iç içe) «ad» anahtarı.
##   Catalog.values_at(data, "lines[].speaker")    Catalog.values_at(data, "bows.*.arrow")    Catalog.values_at(data, "steps[]..line")
static func values_at(root: Variant, path: String) -> Array:
	var cur: Array = [root]
	var deep := false
	for part in path.split("."):
		if part.is_empty():
			deep = true
			continue
		var each := part.ends_with("[]")
		var name := part.trim_suffix("[]")
		var next: Array = []
		for v: Variant in cur:
			if deep:
				_collect_deep(v, name, next)
			elif name == "*":
				if v is Dictionary:
					for k: Variant in v:
						if not str(k).begins_with("_"):
							next.append(v[k])
			elif v is Dictionary and (v as Dictionary).has(name):
				next.append(v[name])
		deep = false
		if each:
			var flat: Array = []
			for v: Variant in next:
				if v is Array:
					flat.append_array(v)
			next = flat
		cur = next
	return cur


static func _collect_deep(v: Variant, name: String, out: Array) -> void:
	if v is Dictionary:
		for k: Variant in v:
			if str(k) == name:
				out.append(v[k])
			_collect_deep(v[k], name, out)
	elif v is Array:
		for e: Variant in v:
			_collect_deep(e, name, out)


# --- İç ---------------------------------------------------------------------------------------------------

func _scan(dir: String, rel: String) -> PackedStringArray:
	var out := PackedStringArray()
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".json"):
			out.append(rel.path_join(f.trim_suffix(".json")) if not rel.is_empty() else f.trim_suffix(".json"))
	for sub in DirAccess.get_directories_at(dir):
		if sub.begins_with("."):
			continue
		out.append_array(_scan(dir.path_join(sub), rel.path_join(sub) if not rel.is_empty() else sub))
	return out
