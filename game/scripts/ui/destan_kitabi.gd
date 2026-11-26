class_name DestanKitabi
extends RefCounted
## Destan Kitabı (Tanhu 2'nin kitabı, Tanhu 1'in görünümüyle): yolculuğun açtıklarını bir kitap gibi
## okutan dört bölüm (godot.md §3.8; K35, K85, K86):
##   Destan     ozanın gece kampı üstüne dizeleri (data/destan.json)
##   Gök ve Yer tanrılar, ruhlar, töre ve «Doğum» (data/mitler.json; sitenin «Tanrılar ve Ruhlar» bölümü)
##   Kişiler    sitenin öteki beş bölümünün kişileri ve ana kampın iki atı (data/kisiler.json)
##   Taşlar     kampın taşları ve yerleri (data/taslar.json)
## «Gök ve Yer» ile Kişiler sitenin ansiklopedisinden gelir (tools/import_encyclopedia.py yazar) ve
## ansiklopedi düzeninde açılır (EncyclopediaPage); Destan ve Taşlar DestanKitabiPage'dedir.
## Her kayıt bir koşulla açılır (JourneyFlags.holds); ilk dize ve ocak halkı baştan açıktır. Oyunda süren
## yolculuğun işaretleri, açılış ekranında son kaydın işaretleri okunur.
## Görünümü GameMenu'nün "book" kipidir ya da oyun içi menü.

const TITLE := "Destan Kitabı"
const CHAPTERS: Array[String] = ["destan", "gok_yer", "kisiler", "taslar"]
const CHAPTER_TITLES := {"destan": "Destan", "gok_yer": "Gök ve Yer", "kisiler": "Kişiler", "taslar": "Taşlar"}
const DATA_PATHS := {
	"destan": "res://data/destan.json",
	"gok_yer": "res://data/mitler.json",
	"kisiler": "res://data/kisiler.json",
	"taslar": "res://data/taslar.json",
}
## Bölümün veri dosyasındaki listesinin adı.
const ENTRY_KEYS := {"destan": "verses", "gok_yer": "myths", "kisiler": "people", "taslar": "stones"}
## Ansiklopedi düzenindeki kitap sayfaları (EncyclopediaPage) ve açtıkları site bölümleri, sekme sırasıyla.
const ENCYCLOPEDIA_CHAPTERS: Array[String] = ["gok_yer", "kisiler"]
const SECTIONS: Array[String] = ["gods", "mete", "huns", "neighbors", "han", "companions"]
const SECTION_PAGES := {
	"gods": "gok_yer",
	"mete": "kisiler", "huns": "kisiler", "neighbors": "kisiler", "han": "kisiler", "companions": "kisiler",
}
## Bölüm sekmesinin simgesi (GameMenu.draw_glyph); veri dosyasının «icon»u yoksa.
const SECTION_GLYPHS := {"gods": "sun", "mete": "bow", "huns": "yurt", "neighbors": "horse", "han": "tower", "companions": "people"}
## Çağ rozetleri (K35): Hun çağı Çin yıllıkları, Göktürk ve Uygur tanıkları, geç derlemeler, oyunun seçimi.
const BADGES: Array[String] = ["Yıllıktan", "Taştan", "Ozan der", "Bizim"]
const EMPTY_TEXT := "Bu sayfalar henüz boş. Yolculuk ilerledikçe dolacak."
const SAGA_SUB := "Ozanın dilinden"
## Aramada eşlenen harfler: Türkçe büyük ve küçük harf (Godot'nun to_lower'ı dile bakmaz: I → i olur, İ ayrı
## kalır) ve şapkalı, noktalı harfler; sitenin katlamasıyla aynı (docs-app/src/lib/text.ts fold).
const FOLD := {
	"İ": "i", "I": "i", "ı": "i", "Ş": "s", "ş": "s", "Ğ": "g", "ğ": "g", "Ç": "c", "ç": "c",
	"Ö": "o", "ö": "o", "Ü": "u", "ü": "u", "â": "a", "Â": "a", "î": "i", "Î": "i", "û": "u", "Û": "u",
	"é": "e", "É": "e", "è": "e", "à": "a", "á": "a", "ā": "a", "ē": "e", "ī": "i", "ō": "o", "ū": "u",
	"ñ": "n", "ä": "a", "ë": "e", "ï": "i",
}

static var _cache: Dictionary = {}
static var _index: Dictionary = {}


## Bölümün başlığı ("Destan", "Gök ve Yer", "Kişiler", "Taşlar").
static func chapter_title(chapter: String) -> String:
	return str(CHAPTER_TITLES.get(chapter, chapter))


## Bölümün verisi (önbellekli). Dosya yoksa ya da bozuksa boş sözlük.
static func data(chapter: String) -> Dictionary:
	if _cache.has(chapter):
		return _cache[chapter]
	var path := str(DATA_PATHS.get(chapter, ""))
	var parsed: Variant = null
	if path != "" and FileAccess.file_exists(path):
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(path)) == OK:
			parsed = json.data
	var d: Dictionary = parsed if parsed is Dictionary else {}
	_cache[chapter] = d
	return d


## Önbelleği boşaltır (testler veri dosyasını değiştirince).
static func clear_cache() -> void:
	_cache.clear()
	_index.clear()


## Bölümün ham kayıtları (açık ya da kapalı).
static func all_entries(chapter: String) -> Array:
	var d := data(chapter)
	var list: Variant = d.get(str(ENTRY_KEYS.get(chapter, "")), [])
	return list if list is Array else []


## Bölümdeki kayıt sayısı.
static func total(chapter: String) -> int:
	return all_entries(chapter).size()


## Kitap sayfası ansiklopedi düzeninde mi («Gök ve Yer», Kişiler)?
static func is_encyclopedia(chapter: String) -> bool:
	return chapter in ENCYCLOPEDIA_CHAPTERS


## Ansiklopedi sayfasının açtığı site bölümleri, sekme sırasıyla.
static func sections_of(chapter: String) -> Array[String]:
	var out: Array[String] = []
	for s in SECTIONS:
		if SECTION_PAGES[s] == chapter:
			out.append(s)
	return out


## Site bölümünün tanımı: {id, title, icon, summary} (veri dosyasından; yoksa kimliği ve simgesi).
static func section_info(section: String) -> Dictionary:
	var chapter := str(SECTION_PAGES.get(section, ""))
	for c: Variant in data(chapter).get("chapters", []):
		if c is Dictionary and str(c.get("id", "")) == section:
			var info: Dictionary = (c as Dictionary).duplicate()
			if str(info.get("icon", "")).is_empty():
				info["icon"] = SECTION_GLYPHS.get(section, "")
			return info
	return {"id": section, "title": section, "icon": SECTION_GLYPHS.get(section, ""), "summary": ""}


## Bu işaretlerle açık olan kayıtlar, kitaptaki sırayla. Her kaydın ortak alanları {id, group, title, sub,
## text}; «Gök ve Yer» ve Kişiler kayıtlarında ayrıca ansiklopedi alanları (bkz. encyclopedia_entry).
static func entries(chapter: String, flags: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match chapter:
		"destan":
			for v in all_entries(chapter):
				if v is Dictionary and JourneyFlags.holds(flags, str(v.get("if", ""))):
					out.append({"id": str(v.get("id", "")), "group": "", "title": str(v.get("title", "")),
						"sub": SAGA_SUB, "text": str(v.get("text", ""))})
		"gok_yer", "kisiler":
			for p in all_entries(chapter):
				if p is Dictionary and is_unlocked(str(p.get("unlock", "")), flags):
					out.append(encyclopedia_entry(chapter, p))
		"taslar":
			for s in all_entries(chapter):
				if s is Dictionary and is_unlocked(str(s.get("unlock", "")), flags):
					out.append({"id": str(s.get("id", "")), "group": str(s.get("group", "")),
						"title": str(s.get("name", "")), "sub": "", "text": str(s.get("text", ""))})
	return out


## Ansiklopedi kaydının kitaptaki biçimi: ortak alanlar (title = ad, sub = san, text = ilk bölümün metni)
## ve chapter (kitap sayfası), section (site bölümü), kind, era, era_note, alt_names, acts, sections [{title, text}],
## facts [{label, value}], lineage {up, down, side: [{id, label}], note}, source_note, intro {en, tr},
## intro_audio (res:// yolu ya da boş), speaks, voice_pending, model (Godot model kimliği ya da boş),
## images {art, portrait, pose, thumb} (res:// yolu ya da boş), badges (çağ rozetleri), game_group.
static func encyclopedia_entry(chapter: String, p: Dictionary) -> Dictionary:
	var sections: Array = p.get("sections", []) if p.get("sections") is Array else []
	var first := ""
	if not sections.is_empty() and sections[0] is Dictionary:
		first = str(sections[0].get("text", ""))
	var images := {"art": "", "portrait": "", "pose": "", "thumb": ""}
	if p.get("images") is Dictionary:
		for k: String in images:
			images[k] = str((p["images"] as Dictionary).get(k, ""))
	var game_group := str(p.get("game_group", ""))
	for g: Variant in data(chapter).get("groups", []):
		if g is Dictionary and str(g.get("id", "")) == game_group:
			game_group = str(g.get("name", game_group))
	return {
		"id": str(p.get("id", "")),
		"chapter": chapter,
		"section": str(p.get("section", "")),
		"group": str(p.get("group", "")),
		"title": str(p.get("name", "")),
		"sub": str(p.get("epithet", "")),
		"text": first,
		"kind": str(p.get("kind", "")),
		"era": str(p.get("era", "")),
		"era_note": str(p.get("era_note", "")),
		"alt_names": p.get("alt_names", []) if p.get("alt_names") is Array else [],
		"acts": p.get("acts", []) if p.get("acts") is Array else [],
		"sections": sections,
		"facts": p.get("facts", []) if p.get("facts") is Array else [],
		"lineage": p.get("lineage", {}) if p.get("lineage") is Dictionary else {},
		"source_note": str(p.get("source_note", "")),
		"intro": p.get("intro", {}) if p.get("intro") is Dictionary else {},
		"intro_audio": str(p.get("intro_audio", "")),
		"speaks": p.get("speaks", true) != false,
		"voice_pending": p.get("voice_pending", false) == true,
		"model": str(p.get("model", "")),
		"images": images,
		"badges": p.get("badges", []) if p.get("badges") is Array else [],
		"game_group": game_group,
	}


## Ansiklopedi kaydı kimliğiyle (açık ya da kapalı; yoksa boş): {chapter, record}. Soy bağları bununla çözülür.
static func find_record(id: String) -> Dictionary:
	if _index.is_empty():
		for chapter in ENCYCLOPEDIA_CHAPTERS:
			for p in all_entries(chapter):
				if p is Dictionary:
					_index[str(p.get("id", ""))] = {"chapter": chapter, "record": p}
	return _index.get(id, {})


## Kimliği verilen ansiklopedi kaydı bu işaretlerle açık mı?
static func is_record_unlocked(id: String, flags: Dictionary) -> bool:
	var found := find_record(id)
	return not found.is_empty() and is_unlocked(str((found["record"] as Dictionary).get("unlock", "")), flags)


## Kişi ya da taş açık mı? "*" her zaman, boş koşul hiçbir zaman (Tanhu 2'deki gibi).
static func is_unlocked(unlock: String, flags: Dictionary) -> bool:
	if unlock == "*":
		return true
	return unlock.strip_edges() != "" and JourneyFlags.holds(flags, unlock)


## Aramanın katlaması: Türkçe büyük ve küçük harf ayrılmaz (İ / i, I / ı elle eşlenir), şapka ve nokta düşer
## («Işık» → «isik», «Ülgen» → «ulgen»). Harf sayısı korunur.
static func fold(text: String) -> String:
	var out := ""
	for ch in text:
		out += str(FOLD.get(ch, ch))
	out = out.to_lower()
	var again := ""
	for ch in out:
		again += str(FOLD.get(ch, ch))
	return again


## Listede sorguya uyan kayıtlar (sırası korunur): ada (title), öteki adlara (alt_names) ve sana (sub)
## bakar; boş sorgu bütün listeyi döndürür.
static func search(query: String, list: Array) -> Array[Dictionary]:
	var q := fold(query.strip_edges())
	var out: Array[Dictionary] = []
	for e: Variant in list:
		if not e is Dictionary:
			continue
		if q.is_empty():
			out.append(e)
			continue
		var hay: Array = [str(e.get("title", "")), str(e.get("sub", ""))]
		if e.get("alt_names") is Array:
			hay.append_array(e["alt_names"])
		for s: Variant in hay:
			if fold(str(s)).contains(q):
				out.append(e)
				break
	return out


## Türkçe büyük harf: i → İ, ı → I (Godot'nun to_upper'ı i'yi I yapar).
static func upper_tr(text: String) -> String:
	return text.replace("i", "İ").replace("ı", "I").to_upper()


## Kitabı ebeveynin üstünde açar ("book" kipinde oyun menüsü) ve döndürür; kapanınca sahibi siler.
static func open(parent: Node, flags: Dictionary) -> GameMenu:
	var m := GameMenu.new()
	m.mode = "book"
	m.flags = flags
	parent.add_child(m)
	m.show_page(CHAPTERS[0])
	return m
