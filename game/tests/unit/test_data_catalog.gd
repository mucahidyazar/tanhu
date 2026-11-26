extends TestCase
## Veri kataloğu ve veri şeması (Catalog; godot.md §2, §8.3; Yol Haritası data-catalog). Prototipin check-data aracının karşılığı:
##   - data/**/*.json'un hepsi ayrıştırılır; Catalog ilk çağrıda okur, önbellekten verir; tablo (id'li dizi ya da kimlikle anahtarlı
##     sözlük) ve kayıt bulur; bozuk ya da eksik dosya null ve nedeniyle döner (geçici klasörde kurulan sahte katalog).
##   - Kimlikler her tabloda tekil ve snake_case; başvurular çözülür (REFS): seslendirme satırı → konuşmacı ve ses dosyası, sinema →
##     satır, segment ve sahne, sahne → satır, konuşmacı ve oyuncu, yay → ok, pelerin ve kılık, zorluk, ansiklopedinin bölümü, grubu ve
##     soy bağları; Yeni Oyun'un oynanan aşamalarının dosyaları vardır.
##   - Destan Kitabı'nın koşulları (if, unlock) koşul dilinde okunur ve yalnız bilinen işaretleri anar (yanlış yazılan işaret kaydı
##     hiç açmaz).
##   - Oyuncu dizgeleri: data/i18n/strings.csv (keys, tr, en) tekil, iki dili dolu, yer tutucuları aynı; koddaki her tr("KEY") ve
##     Catalog.text("KEY") anahtarı vardır; verideki satır içi çift dil ({tr, en}; X ile X_en; X_tr ile X_en) iki dili doludur.
##     Geliştirme verisi (DEV_DATA) oyuncu dizgesi değildir.
##   - d2 modelleri (econ, labour, settlement, weather) okunur; oyunun verisi modelle çelişmez: türlerin adı ve verimi, verimlerin
##     eşya kimlikleri. Bilinen ayrılıklar (MODEL_GAPS) nedeniyle yazılır; kapanınca sınama listeden çıkarılmasını ister.

const TempDir := preload("res://tests/support/temp_dir.gd")

## Oyuncuya görünmeyen geliştirme ve araç verisi (çift dil denetimine girmez).
const DEV_DATA: Array[String] = [
	"clip_library", "clip_library_measure", "rig_calibration", "budget_baseline", "budgets", "garment_weights", "audio/bake/",
	"cine/test_timeline",
]
## Kimlik tabloları: dosya → listeler.
const TABLES := {
	"kisiler": ["people", "chapters", "groups"], "mitler": ["myths", "chapters"], "destan": ["verses"], "taslar": ["stones"],
	"vo_lines": ["lines", "speakers"], "fauna/kinds": ["kinds"], "fauna/mounts": ["mounts"], "combat/weapons": ["bows", "arrows"],
	"character/capes": ["dyes", "capes", "outfits"], "character/origins": ["origins"], "character/difficulty": ["levels"],
	"story/new_game": ["stages"], "story/childhood/scene": ["steps", "lines", "speakers", "actors"],
	"story/departure/scene": ["steps", "lines", "speakers", "actors"],
}
## Başvurular: [dosya (sonda * klasörün dosyaları), yol (Catalog.values_at), hedef]. Hedef «dosya#liste» (| ile birden çok),
## «self#liste» aynı dosyanın listesi, «@file» res:// yolu dosyadır (null ya da boş geçer).
const REFS := [
	["vo_lines", "lines[].speaker", "vo_lines#speakers"],
	["vo_lines", "lines[].file", "@file"],
	["vo_lines", "lines[].timing", "@file"],
	["cine/*", "events[].line", "vo_lines#lines"],
	["cine/*", "segments[].file", "@file"],
	["cine/*", "scene", "@file"],
	["story/childhood/scene", "lines.*.speaker", "self#speakers"],
	["story/departure/scene", "lines.*.speaker", "self#speakers"],
	["story/childhood/scene", "steps[]..line", "self#lines"],
	["story/departure/scene", "steps[]..line", "self#lines"],
	["story/childhood/scene", "steps[]..race_line", "self#lines"],
	["story/childhood/scene", "steps[]..actor", "self#actors"],
	["story/departure/scene", "steps[]..actor", "self#actors"],
	["combat/weapons", "bows.*.arrow", "combat/weapons#arrows"],
	["character/capes", "start.cape", "character/capes#capes"],
	["character/capes", "start.outfit", "character/capes#outfits"],
	["character/difficulty", "default", "character/difficulty#levels"],
	["kisiler", "people[].section", "kisiler#chapters"],
	["mitler", "myths[].section", "mitler#chapters"],
	["kisiler", "people[].game_group", "kisiler#groups"],
	["kisiler", "people[].lineage.up[].id", "kisiler#people|mitler#myths"],
	["kisiler", "people[].lineage.down[].id", "kisiler#people|mitler#myths"],
	["kisiler", "people[].lineage.side[].id", "kisiler#people|mitler#myths"],
	["mitler", "myths[].lineage.up[].id", "kisiler#people|mitler#myths"],
	["mitler", "myths[].lineage.down[].id", "kisiler#people|mitler#myths"],
]
## Modelin dosyaları (proje klasörünün yanındaki docs/design/d2) ve beklenen üst anahtarları.
const MODELS := {
	"econ-model": ["meta", "items", "herds", "hunts", "recipes", "structures"], "labour-model": ["version", "law", "defs"],
	"settlement-model": ["meta", "tiers", "buildings"], "weather-model": ["meta", "snowpack", "byClimate", "zones"],
}
const MODEL_DIR := "../docs/design/d2"
## Oyunun verisiyle modelin bilinen ayrılıkları: «tür.alan»: neden. Alan belgesi (fauna.md) modelin üstündedir; model düzelince satır silinir.
## 2026-11-08 (fire-hunting): boşaldı. Av veriminin sahibi fauna.md §1'dir (K65; K31: d2/ taslaktır): karga ve keklik 1 tüy (oyunun verisi
## zaten 1; econ-model hunts'ın 2'si ana oturumca 1'e iner), tarbaganın tabanı 1 iç yağı, güzün +1'i kinds.json yield_season'dadır.
const MODEL_GAPS := {}

var _dirs: Array[String] = []


func after_each() -> void:
	for d in _dirs:
		TempDir.wipe(d)
	_dirs.clear()
	Catalog.reset()


# --- Okuma ve önbellek --------------------------------------------------------------------------------------

func test_every_data_file_parses() -> void:
	var cat := Catalog.new()
	var n := cat.load_all()
	var expected := _json_files("res://data", "")
	assert_eq(n, expected.size(), "Bütün .json dosyaları okunmalı")
	assert_true(n >= 50, "Veri dosyası sayısı: %d" % n)
	assert_eq(cat.errors(), {}, "Bozuk veri dosyası olmamalı")
	for rel in expected:
		assert_true(cat.has_file(rel), "Okunmalı: %s" % rel)


func test_catalog_reads_once_and_finds_records() -> void:
	var kinds: Variant = Catalog.data("fauna/kinds")
	assert_true(kinds is Dictionary, "Dosya ilk çağrıda okunur")
	assert_true(is_same(kinds, Catalog.data("fauna/kinds.json")), "Önbellekten aynı nesne (uzantılı yol da okunur)")
	assert_true(is_same(kinds, Catalog.data("res://data/fauna/kinds.json")))
	var sheep := Catalog.lookup("fauna/kinds", "kinds", "sheep")
	assert_eq(Catalog.pick(sheep.get("name"), "tr"), "Koyun")
	assert_eq(Catalog.pick(sheep.get("name"), "en"), "Sheep")
	assert_eq(Catalog.lookup("fauna/kinds", "kinds", "dragon"), {}, "Olmayan kayıt boş")
	var bows := Catalog.table_of("combat/weapons", "bows")
	assert_true(bows.has("toy_bow"), "Kimlikle anahtarlı sözlük tablosu")
	var people := Catalog.shared().table("kisiler", "people")
	assert_true(people.has("older_brother") and people.has("mother"), "id'li dizi tablosu")
	assert_null(Catalog.data("yok/boyle_dosya"), "Olmayan dosya null")
	assert_true(Catalog.shared().error("yok/boyle_dosya").contains("dosya yok"))


func test_catalog_with_its_own_root() -> void:
	var dir := TempDir.fresh("katalog")
	_dirs.append(dir)
	DirAccess.make_dir_recursive_absolute(dir.path_join("sub"))
	# Metin elle yazılır: JSON.stringify anahtarları sıralar, dosyanın sırası okunmalı.
	_write(dir.path_join("items.json"), '{"items": {"meal": {"tr": "Yemek"}, "_note": "not", "felt": {"tr": "Keçe"}}}')
	_write(dir.path_join("sub/list.json"), '{"rows": [{"id": "a"}, {"id": "b"}, {"x": 1}, {"id": "a"}]}')
	_write(dir.path_join("broken.json"), "{ bu json değil")
	_write(dir.path_join("notes.txt"), "json değil, taranmaz")
	var cat := Catalog.new(dir)
	assert_eq(cat.load_all(), 3, "Yalnız .json dosyaları, alt klasör dahil")
	assert_eq(cat.files(), PackedStringArray(["broken", "items", "sub/list"]))
	assert_null(cat.read("broken"))
	assert_true(cat.error("broken").contains("bozuk"), "Bozuk dosyanın nedeni: %s" % cat.error("broken"))
	assert_eq(cat.ids("items", "items"), PackedStringArray(["meal", "felt"]), "«_» ile başlayan anahtar not sayılır")
	assert_eq(cat.ids("sub/list", "rows"), PackedStringArray(["a", "b", "a"]), "Satırlar sırayla (tekillik sınaması okur)")
	assert_eq(cat.table("sub/list", "rows").size(), 2)
	_write(dir.path_join("items.json"), JSON.stringify({"items": {}}))
	assert_eq(cat.ids("items", "items").size(), 2, "Önbellek: dosya yeniden okunmaz")
	cat.clear()
	assert_eq(cat.ids("items", "items").size(), 0, "clear sonrası yeniden okunur")
	assert_eq(Catalog.values_at({"a": [{"b": 1}, {"b": 2}], "c": {"x": {"d": 3}, "_n": {"d": 4}}}, "a[].b"), [1, 2])
	assert_eq(Catalog.values_at({"c": {"x": {"d": 3}, "_n": {"d": 4}}}, "c.*.d"), [3], "«*» notları atlar")
	assert_eq(Catalog.values_at({"s": [{"k": {"line": "x", "deep": [{"line": "y"}]}}]}, "s[]..line"), ["x", "y"], "«..» iç içe arar")


# --- Kimlik ve başvuru ----------------------------------------------------------------------------------------

func test_ids_are_unique_and_snake_case() -> void:
	var cat := Catalog.shared()
	for rel: String in TABLES:
		assert_true(cat.has_file(rel), "Tablo dosyası okunmalı: %s" % rel)
		for list_key: String in TABLES[rel]:
			var ids := cat.ids(rel, list_key)
			assert_false(ids.is_empty(), "%s#%s boş olmamalı" % [rel, list_key])
			var seen := {}
			for id in ids:
				assert_false(seen.has(id), "%s#%s: «%s» iki kez" % [rel, list_key, id])
				seen[id] = true
				assert_true(_is_id(id), "%s#%s: «%s» kimliği snake_case olmalı (nokta: alt kimlik)" % [rel, list_key, id])


func test_references_resolve() -> void:
	var cat := Catalog.shared()
	cat.load_all()
	var checked := 0
	for rule: Array in REFS:
		var files := _rule_files(cat, str(rule[0]))
		assert_false(files.is_empty(), "Kuralın dosyası yok: %s" % rule[0])
		for rel in files:
			for v: Variant in Catalog.values_at(cat.read(rel), str(rule[1])):
				if v == null or str(v).is_empty():
					continue
				checked += 1
				assert_true(_resolves(cat, rel, str(rule[2]), str(v)), "%s %s → «%s» %s'te yok" % [rel, rule[1], v, rule[2]])
	assert_true(checked >= 150, "Çözülen başvuru sayısı: %d" % checked)


func test_new_game_stages_resolve() -> void:
	var stages: Array = Catalog.shared().read("story/new_game").get("stages", [])
	assert_false(stages.is_empty())
	for stage: Dictionary in stages:
		var kind := str(stage.get("kind", ""))
		match kind:
			"cine", "scene":
				assert_true(FileAccess.file_exists(str(stage.get("path", ""))), "%s aşamasının dosyası: %s" % [stage["id"], stage.get("path")])
			"childhood":
				assert_true(FileAccess.file_exists(str(stage.get("scene", ""))), "Çocukluk'un sahnesi")
			"card":
				for k in ["title", "line"]:
					assert_eq(_bilingual_error(stage.get(k)), "", "%s.%s iki dilli" % [stage["id"], k])
			"act", "prologue", "creator":
				pass
			_:
				fail("Bilinmeyen aşama türü: %s" % kind)


func test_book_conditions_read_and_name_known_flags() -> void:
	var known := _known_flags()
	var conds := 0
	for chapter in DestanKitabi.CHAPTERS:
		for e: Variant in DestanKitabi.all_entries(chapter):
			for k in ["if", "unlock"]:
				if not (e is Dictionary and (e as Dictionary).has(k)):
					continue
				var cond := str(e[k])
				conds += 1
				assert_eq(Cond.error_of(cond), "", "%s/%s koşulu okunmalı: «%s»" % [chapter, e.get("id"), cond])
				for atom in Cond.atoms(cond):
					assert_true(known.has(atom), "%s/%s bilinmeyen işaret «%s» (yazım hatası mı?)" % [chapter, e.get("id"), atom])
	assert_true(conds > 100, "Sınanan koşul: %d" % conds)


# --- Oyuncu dizgeleri ------------------------------------------------------------------------------------------

func test_strings_csv_has_both_languages() -> void:
	var cat := Catalog.shared()
	var strings := cat.strings()
	assert_eq(cat.string_errors(), PackedStringArray(), "strings.csv sağlam olmalı")
	assert_true(strings.size() >= 10, "Anahtar sayısı: %d" % strings.size())
	var header := FileAccess.get_file_as_string(Catalog.STRINGS_PATH).split("\n")[0].strip_edges()
	assert_eq(header, "keys,tr,en", "Godot'nun çeviri CSV başlığı")
	for key: String in strings:
		assert_true(_is_key(key), "Anahtar BÜYÜK_HARF: %s" % key)
		var e: Dictionary = strings[key]
		for lang in Catalog.LANGS:
			assert_false(str(e.get(lang, "")).strip_edges().is_empty(), "%s: %s boş" % [key, lang])
		assert_eq(_placeholders(str(e["tr"])), _placeholders(str(e["en"])), "%s: yer tutucular iki dilde aynı" % key)
	for id: String in JourneyFlags.PLACE_NAMES:
		assert_eq(Catalog.text("PLACE_" + id.to_upper(), "tr"), str(JourneyFlags.PLACE_NAMES[id]), "Yer adı JourneyFlags'le aynı: %s" % id)
	assert_eq(Catalog.text("SAVE_CAMP_NAME", "tr"), SaveData.CAMP_NAME)
	var import_cfg := FileAccess.get_file_as_string(Catalog.STRINGS_PATH + ".import")
	assert_true(import_cfg.contains("importer=\"keep\""), "strings.csv içe aktarılmaz, olduğu gibi dışa aktarılır")


func test_every_code_key_exists() -> void:
	var cat := Catalog.shared()
	var used := {}
	var re := RegEx.create_from_string("(?:\\btr|Catalog\\.text)\\(\\s*&?\"([A-Z][A-Z0-9_]*)\"")
	for path in _gd_files("res://scripts"):
		for line in FileAccess.get_file_as_string(path).split("\n"):
			# Belge yorumundaki örnek (tr("KEY")) anahtar değildir.
			if line.strip_edges().begins_with("#"):
				continue
			for m in re.search_all(line):
				used[m.get_string(1)] = path
	for key: String in used:
		assert_true(cat.has_string(key), "%s: «%s» strings.csv'de yok" % [used[key], key])
	cat.load_all()
	for rel in cat.files():
		for pair: Array in _key_fields(cat.read(rel), rel):
			assert_true(cat.has_string(str(pair[1])), "%s %s: «%s» strings.csv'de yok" % [rel, pair[0], pair[1]])


func test_inline_bilingual_strings_have_both() -> void:
	var cat := Catalog.shared()
	cat.load_all()
	var checked := 0
	for rel in cat.files():
		if _is_dev(rel):
			continue
		var problems: Array = []
		checked += _check_bilingual(cat.read(rel), rel, problems)
		for p: String in problems.slice(0, 5):
			fail(p)
	assert_true(checked >= 150, "Sınanan çift dilli dizge: %d" % checked)


func test_text_pick_and_translations() -> void:
	assert_eq(Catalog.text("SAVE_LOAD_FAILED", "tr"), "Bu kayıt açılamadı.")
	assert_eq(Catalog.text("SAVE_LOAD_FAILED", "en"), "This save could not be opened.")
	assert_eq(Catalog.text("SAVE_LOAD_FAILED"), "Bu kayıt açılamadı.", "Varsayılan dil Türkçe")
	assert_eq(Catalog.text("NO_SUCH_KEY"), "NO_SUCH_KEY", "Olmayan anahtar kendisi")
	assert_eq(Catalog.pick({"tr": "Koyun", "en": ""}, "en"), "Koyun", "Boş dil Türkçeye düşer")
	assert_eq(Catalog.pick("düz", "en"), "düz")
	assert_eq(Catalog.pick(null), "")
	var before := TranslationServer.get_locale()
	assert_eq(Catalog.install_translations("en"), 2)
	assert_eq(tr("CLOCK_SUMMON"), "They are calling for you.", "tr(KEY) çalışır")
	TranslationServer.set_locale("tr")
	assert_eq(tr("CLOCK_SUMMON"), "Seni çağırıyorlar.")
	Catalog.uninstall_translations()
	TranslationServer.set_locale(before)
	assert_eq(tr("CLOCK_SUMMON"), "CLOCK_SUMMON", "Kaldırılınca anahtar döner")


# --- Modeller --------------------------------------------------------------------------------------------------

func test_models_parse_and_data_agrees() -> void:
	var models := {}
	for name: String in MODELS:
		var path := ProjectSettings.globalize_path("res://").path_join(MODEL_DIR).path_join(name + ".json").simplify_path()
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		assert_true(parsed is Dictionary, "Model okunmalı: %s" % path)
		if not parsed is Dictionary:
			return
		for k: String in MODELS[name]:
			assert_true((parsed as Dictionary).has(k), "%s: «%s» anahtarı" % [name, k])
		models[name] = parsed
	var econ: Dictionary = models["econ-model"]
	var items: Dictionary = econ["items"]
	var gaps_seen := {}
	for row in Catalog.shared().rows("fauna/kinds", "kinds"):
		var id := str(row[0])
		var kind: Dictionary = row[1]
		var yields: Dictionary = kind.get("yield", {})
		for item: String in yields:
			assert_true(items.has(item), "%s verimi «%s» modelin eşyası değil" % [id, item])
		for item: Variant in kind.get("products", []):
			assert_true(items.has(str(item)), "%s ürünü «%s» modelin eşyası değil" % [id, item])
		var herd: Variant = (econ["herds"] as Dictionary).get(id)
		if herd is Dictionary:
			assert_eq(Catalog.pick(kind.get("name"), "tr"), str(herd.get("tr")), "%s adı (TR) modelle aynı" % id)
			assert_eq(Catalog.pick(kind.get("name"), "en"), str(herd.get("en")), "%s adı (EN) modelle aynı" % id)
			_compare_yield(id, yields, herd.get("slaughter", {}), gaps_seen)
		var hunt: Variant = (econ["hunts"] as Dictionary).get(id)
		if hunt is Dictionary:
			_compare_yield(id, yields, hunt.get("yield", {}), gaps_seen)
	for gap: String in MODEL_GAPS:
		assert_true(gaps_seen.has(gap), "Bilinen ayrılık kapandı, MODEL_GAPS'tan sil: %s" % gap)


# --- Yardımcılar ------------------------------------------------------------------------------------------------

func _compare_yield(id: String, data: Dictionary, model: Variant, gaps_seen: Dictionary) -> void:
	if not model is Dictionary:
		return
	var keys := {}
	for k: String in data:
		keys[k] = true
	for k: String in model:
		keys[k] = true
	for k: String in keys:
		var a := float(data.get(k, 0))
		var b := float((model as Dictionary).get(k, 0))
		var gap := "%s.%s" % [id, k]
		if MODEL_GAPS.has(gap):
			if not is_equal_approx(a, b):
				gaps_seen[gap] = true
			continue
		assert_almost(a, b, 1e-9, "%s verimi modelle çelişiyor (oyun %s, model %s)" % [gap, a, b])


func _known_flags() -> Dictionary:
	var out := {}
	for f in JourneyFlags.ALL:
		out[f] = true
	for f in [CineHost.PROLOGUE_FLAG, NewGameFlow.DAY_FLAG]:
		out[f] = true
	# main.gd'nin işaret sabitleri kaynağından okunur (betiği yüklemek bütün arayüzü derler; bu sınama ona bağlı kalmasın).
	var re := RegEx.create_from_string("const\\s+[A-Z0-9_]+_FLAG\\s*:?=\\s*\"([A-Za-z0-9_]+)\"")
	for m in re.search_all(FileAccess.get_file_as_string("res://scripts/main.gd")):
		out[m.get_string(1)] = true
	for rel in ["story/childhood/scene", "story/departure/scene"]:
		var flags: Variant = Catalog.shared().read(rel).get("flags", {})
		if flags is Dictionary:
			for v: Variant in (flags as Dictionary).values():
				out[str(v)] = true
	return out


func _rule_files(cat: Catalog, pattern: String) -> PackedStringArray:
	if not pattern.ends_with("/*"):
		return PackedStringArray([pattern]) if cat.has_file(pattern) else PackedStringArray()
	var prefix := pattern.trim_suffix("*")
	var out := PackedStringArray()
	for rel in cat.files():
		if rel.begins_with(prefix) and not rel.substr(prefix.length()).contains("/") and not _is_dev(rel):
			out.append(rel)
	return out


func _resolves(cat: Catalog, rel: String, target: String, value: String) -> bool:
	if target == "@file":
		return FileAccess.file_exists(value) or ResourceLoader.exists(value)
	for t in target.split("|"):
		var parts := t.split("#")
		var file := rel if parts[0] == "self" else parts[0]
		if cat.table(file, parts[1]).has(value):
			return true
	return false


## Verideki «*_key» alanları (oyuncu dizgesinin anahtarı): [[yol, anahtar]].
func _key_fields(v: Variant, path: String) -> Array:
	var out: Array = []
	if v is Dictionary:
		for k: Variant in v:
			var val: Variant = v[k]
			if str(k).ends_with("_key") and val is String and _is_key(val):
				out.append(["%s.%s" % [path, k], val])
			out.append_array(_key_fields(val, "%s.%s" % [path, k]))
	elif v is Array:
		for i in (v as Array).size():
			out.append_array(_key_fields(v[i], "%s[%d]" % [path, i]))
	return out


## Çift dil denetimi: {tr, en} sözlüğü, X ile X_en, X_tr ile X_en. Döner: sınanan dizge sayısı; sorunlar problems'a.
func _check_bilingual(v: Variant, path: String, problems: Array) -> int:
	var n := 0
	if v is Dictionary:
		var d := v as Dictionary
		if d.has("tr") or d.has("en"):
			n += 1
			var e := _bilingual_error(d)
			if not e.is_empty():
				problems.append("%s: %s" % [path, e])
		for k: Variant in d:
			var key := str(k)
			if key.ends_with("_en"):
				n += 1
				var base := key.trim_suffix("_en")
				var tr_key := base if d.has(base) else base + "_tr"
				if not d.has(tr_key):
					problems.append("%s.%s: Türkçesi (%s ya da %s_tr) yok" % [path, key, base, base])
				elif not _filled(d[tr_key]) or not _filled(d[key]):
					problems.append("%s.%s: iki dilden biri boş" % [path, key])
			elif key.ends_with("_tr") and not d.has(key.trim_suffix("_tr") + "_en"):
				problems.append("%s.%s: İngilizcesi yok" % [path, key])
			n += _check_bilingual(d[k], "%s.%s" % [path, key], problems)
	elif v is Array:
		for i in (v as Array).size():
			n += _check_bilingual(v[i], "%s[%d]" % [path, i], problems)
	return n


func _bilingual_error(v: Variant) -> String:
	if not v is Dictionary:
		return "çift dilli sözlük değil"
	for lang in Catalog.LANGS:
		if not _filled((v as Dictionary).get(lang)):
			return "«%s» yok ya da boş" % lang
	return ""


func _filled(v: Variant) -> bool:
	return (v is String or v is StringName) and not String(v).strip_edges().is_empty()


func _placeholders(text: String) -> PackedStringArray:
	var out := PackedStringArray()
	var re := RegEx.create_from_string("\\{[a-z_]+\\}")
	for m in re.search_all(text):
		out.append(m.get_string())
	out.sort()
	return out


func _is_dev(rel: String) -> bool:
	for d in DEV_DATA:
		if rel == d or (d.ends_with("/") and rel.begins_with(d)):
			return true
	return false


func _is_id(id: String) -> bool:
	return RegEx.create_from_string("^[a-z0-9_]+(\\.[a-z0-9_]+)*$").search(id) != null


func _is_key(key: String) -> bool:
	return RegEx.create_from_string("^[A-Z][A-Z0-9_]*$").search(key) != null


func _json_files(dir: String, rel: String) -> PackedStringArray:
	var out := PackedStringArray()
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".json"):
			out.append(rel.path_join(f.trim_suffix(".json")) if not rel.is_empty() else f.trim_suffix(".json"))
	for sub in DirAccess.get_directories_at(dir):
		out.append_array(_json_files(dir.path_join(sub), rel.path_join(sub) if not rel.is_empty() else sub))
	return out


func _gd_files(dir: String) -> PackedStringArray:
	var out := PackedStringArray()
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for sub in DirAccess.get_directories_at(dir):
		out.append_array(_gd_files(dir.path_join(sub)))
	return out


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
