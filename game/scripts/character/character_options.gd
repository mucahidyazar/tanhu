class_name CharacterOptions
extends RefCounted
## Karakter oluşturucudaki tüm seçeneklerin kataloğu (saf veri, yan etkisiz, test edilebilir).
##
## Renk listelerinde 0. eleman her zaman "Doğal"dır: modelin kendi dokusundaki renk korunur (pelerin boyası
## dışında: boyanın "doğal"ı yoktur, ilk boya Göl Mavisi'dir). Saç modelleri vücut tipine göre değişir; her saç
## modeli ayrı bir Meshy karakter modelidir (res://assets/characters/<model>/<model>.glb).
##
## «Yola Hazırlan» (K36, K58): görünüşün ardından yolun üç satırı gelir: köken, zorluk ve pelerin boyası. Listeleri
## data/character/ altındadır (origins.json, difficulty.json, capes.json) ve kayda kimlikle yazılır (ID_FIELDS).
## Pelerin rengi tek yerden gelir: cape_tint(eşya, boya) (capeTint, story.md §7.4); oluşturucunun önizlemesi ve
## oyundaki Mete aynı kılığı (START_OUTFIT, START_CAPE) aynı malzemeyle giyer (CharacterAvatar).

## UI'daki satırların sırası ve başlıkları.
const FIELDS: Array[StringName] = [&"body_type", &"skin", &"hairstyle", &"hair_color", &"beard", &"moustache", &"eyes", &"eye_color",
	&"origin", &"difficulty", &"cape_dye"]
const FIELD_LABELS := {
	&"body_type": "VÜCUT TİPİ",
	&"skin": "TEN",
	&"hairstyle": "SAÇ MODELİ",
	&"hair_color": "SAÇ RENGİ",
	&"beard": "SAKAL",
	&"moustache": "BIYIK",
	&"eyes": "GÖZLER",
	&"eye_color": "GÖZ RENGİ",
	&"origin": "KÖKEN",
	&"difficulty": "ZORLUK",
	&"cape_dye": "BOYA",
}
## Renk örneği (swatch) olarak gösterilen alanlar.
const COLOR_FIELDS: Array[StringName] = [&"skin", &"hair_color", &"eye_color", &"cape_dye"]
## Renk örneği yuvarlak boncuk değil kumaş parçası olarak çizilen alanlar (pelerin boyası).
const FABRIC_FIELDS: Array[StringName] = [&"cape_dye"]
## Yolun satırları: görünüşten bir ayraçla ayrılır (ilk alanın üstünde). Kayda kimlikle yazılır.
const JOURNEY_FIELDS: Array[StringName] = [&"origin", &"difficulty", &"cape_dye"]
## Kayıtta indeks değil kimlikle (ör. "normal", "lake_blue") yazılan alanlar: liste sırası değişse de kayıt doğru okunur.
const ID_FIELDS: Array[StringName] = [&"origin", &"difficulty", &"cape_dye"]
## Değerin altında açıklama satırı olan alanlar (kökenin sözü ve etkisi, zorluğun sözü).
const DETAIL_FIELDS: Array[StringName] = [&"origin", &"difficulty"]
## Açıklaması iki satır olan alanlar: kökenin sözü üstte, etkisi altta (value_detail).
const TWO_LINE_DETAIL_FIELDS: Array[StringName] = [&"origin"]

const BODY_TYPES: Array[String] = ["Tip 1", "Tip 2"]

## Vücut tipine göre saç modelleri: görünen ad + model kimliği.
## Modeller Mete / kamp stilinde Meshy ile üretildi (tools/asset_plan.json): Tip 1 = Mete, Tip 2 = kadın kahraman.
const HAIRSTYLES := {
	0: [{"name": "Topuz ve örgü", "model": "mete"}],
	1: [{"name": "Örgülü", "model": "hero_f"}],
}

const NATURAL := "Doğal"

const SKIN_TONES: Array[Color] = [
	Color(0, 0, 0, 0),
	Color(1.0, 0.9, 0.83), Color(0.98, 0.82, 0.7), Color(0.93, 0.74, 0.6), Color(0.85, 0.64, 0.48),
	Color(0.74, 0.53, 0.38), Color(0.62, 0.43, 0.3), Color(0.49, 0.33, 0.23), Color(0.36, 0.24, 0.17),
	Color(0.92, 0.86, 0.8),
]
const SKIN_NAMES: Array[String] = [NATURAL, "Süt", "Şeftali", "Bal", "Buğday", "Bronz", "Kestane", "Kahve", "Koyu", "Ay ışığı"]

const HAIR_COLORS: Array[Color] = [
	Color(0, 0, 0, 0),
	Color(0.08, 0.07, 0.08), Color(0.27, 0.16, 0.1), Color(0.5, 0.18, 0.12), Color(0.8, 0.42, 0.18),
	Color(0.86, 0.68, 0.38), Color(0.62, 0.62, 0.64), Color(0.94, 0.93, 0.9), Color(0.33, 0.52, 0.32),
	Color(0.42, 0.3, 0.62), Color(0.35, 0.55, 0.85),
]
const HAIR_NAMES: Array[String] = [NATURAL, "Siyah", "Kahverengi", "Kızıl", "Bakır", "Sarı", "Gri", "Beyaz", "Yeşil", "Mor", "Mavi"]

const EYE_COLORS: Array[Color] = [
	Color(0, 0, 0, 0),
	Color(0.24, 0.14, 0.08), Color(0.62, 0.42, 0.14), Color(0.38, 0.42, 0.2), Color(0.12, 0.5, 0.42),
	Color(0.2, 0.42, 0.78), Color(0.42, 0.5, 0.6), Color(0.45, 0.3, 0.65), Color(0.7, 0.16, 0.16),
]
const EYE_COLOR_NAMES: Array[String] = [NATURAL, "Koyu kahve", "Kehribar", "Zeytin", "Turkuaz", "Mavi", "Gri", "Mor", "Kırmızı"]

const BEARDS: Array[String] = ["Yok", "Kısa", "Gür", "Uzun"]
const MOUSTACHES: Array[String] = ["Yok", "İnce", "Gür", "Uzun"]
const EYE_STYLES: Array[String] = [NATURAL, "Yuvarlak", "Badem", "Uykulu"]

## Gerçekçi (Meshy) modellerde yüze çizili özellikler: sakal, bıyık ve göz biçimi modelin dokusundadır,
## ayrıca değiştirilemez. Kodla çizilen yedek (chibi) karakterde hepsi ayarlanabilir.
const PAINTED_FIELDS: Array[StringName] = [&"beard", &"moustache", &"eyes"]
## Ayarlanamayan satırda değer yerine yazan metin.
const PAINTED_TEXT := "Modelde çizili"
## Boya satırı, kılık maskesi olmayan (pelerinsiz) modelde ayarlanamaz: değer yerine bu yazar.
const NO_CAPE_TEXT := "Bu kılıkta pelerin yok"
## Zorluğun açıklamasına eklenen not: kadraj dışı tehdidin kenar oku her zorlukta açıktır (K39; act1.md §13).
const EDGE_ARROW_NOTE := "Tehdit oku her zorlukta açık"

## Veri dosyaları (data/character/).
const DATA_DIR := "res://data/character/"
const CAPES_FILE := "capes"
const ORIGINS_FILE := "origins"
const DIFFICULTY_FILE := "difficulty"

## Okunan veri dosyaları (ad → sözlük); bir kez okunur.
static var _data_cache := {}


## Alan bu karakterde ayarlanabilir mi? painted = yüzü dokusuna çizili bir model (Meshy) gösteriliyor; has_cape = modelde
## boyanabilir pelerin var (kılık maskesi). Boya satırı pelerini olmayan modelde (ör. kadın kahraman) kilitlidir.
static func is_adjustable(field: StringName, painted: bool, has_cape: bool = true) -> bool:
	if field == &"cape_dye":
		return has_cape
	return not (painted and field in PAINTED_FIELDS)


## Kilitli satırın değer yerine yazdığı metin.
static func locked_text(field: StringName) -> String:
	return NO_CAPE_TEXT if field == &"cape_dye" else PAINTED_TEXT


## Kilitliyken gizlenen satır mı? Yüze çizili özellikler (sakal, bıyık, göz biçimi) bilgi taşımaz, yer kaplamasın; pelerinsiz
## kılıkta boya satırı görünür kalır, çünkü seçim yolculuğa yazılır.
static func hides_when_locked(field: StringName) -> bool:
	return field in PAINTED_FIELDS


## Alanın kaç seçeneği var? (Saç modeli sayısı vücut tipine bağlıdır.)
static func count(field: StringName, body_type: int = 0) -> int:
	match field:
		&"body_type":
			return BODY_TYPES.size()
		&"hairstyle":
			return (HAIRSTYLES.get(clampi(body_type, 0, BODY_TYPES.size() - 1), []) as Array).size()
		&"skin":
			return SKIN_TONES.size()
		&"hair_color":
			return HAIR_COLORS.size()
		&"eye_color":
			return EYE_COLORS.size()
		&"beard":
			return BEARDS.size()
		&"moustache":
			return MOUSTACHES.size()
		&"eyes":
			return EYE_STYLES.size()
		&"origin", &"difficulty", &"cape_dye":
			return CharacterOptions._list(field).size()
	return 0


## Seçeneğin görünen adı (UI'da oklar arasındaki metin).
static func value_name(field: StringName, index: int, body_type: int = 0) -> String:
	var n := count(field, body_type)
	if n == 0:
		return ""
	var i := wrapi(index, 0, n)
	match field:
		&"body_type":
			return BODY_TYPES[i]
		&"hairstyle":
			return HAIRSTYLES[clampi(body_type, 0, BODY_TYPES.size() - 1)][i]["name"]
		&"skin":
			return SKIN_NAMES[i]
		&"hair_color":
			return HAIR_NAMES[i]
		&"eye_color":
			return EYE_COLOR_NAMES[i]
		&"beard":
			return BEARDS[i]
		&"moustache":
			return MOUSTACHES[i]
		&"eyes":
			return EYE_STYLES[i]
		&"origin", &"difficulty", &"cape_dye":
			return str((CharacterOptions._list(field)[i] as Dictionary).get("name", ""))
	return ""


## Değerin altındaki açıklama: kökenin sözü ve alt satırda etkisi («Tanhu'nun yılkısını yaylaya sürerek büyüdün; atlar seni
## tanır.» / «Ayak +1, Bağ +10»; K104'ün sözleri tek satıra tam boyda sığmıyordu), zorluğun sözü ve kenar okunun her zorlukta açık
## olduğu (tek satır). Açıklaması olmayan alanda "".
static func value_detail(field: StringName, index: int) -> String:
	if not field in DETAIL_FIELDS or count(field) == 0:
		return ""
	var item: Dictionary = CharacterOptions._list(field)[wrapi(index, 0, count(field))]
	match field:
		&"origin":
			return "%s\n%s" % [str(item.get("line", "")), str(item.get("effect", ""))]
		&"difficulty":
			var line := str(item.get("line", ""))
			return "%s  ·  %s" % [line, EDGE_ARROW_NOTE] if bool(item.get("edgeArrow", true)) else line
	return ""


## Kimlikle kaydedilen alanda seçeneğin kimliği (ör. "origin_herds", "hard", "violet"); öteki alanlarda "".
static func value_id(field: StringName, index: int) -> String:
	if not field in ID_FIELDS or count(field) == 0:
		return ""
	return str((CharacterOptions._list(field)[wrapi(index, 0, count(field))] as Dictionary).get("id", ""))


## Kimliğin indeksi (yoksa -1). Seçeneğin eski kimliği de (veri dosyasındaki former_ids) o seçeneği bulur: K104'ten önceki
## kayıttaki "origin_stable" bugünkü "origin_herds"tir; kayıt yeniden yazılınca yeni kimlikle yazılır (value_id).
static func index_of_id(field: StringName, id: String) -> int:
	var list := CharacterOptions._list(field)
	for i in list.size():
		if str((list[i] as Dictionary).get("id", "")) == id:
			return i
	for i in list.size():
		var former: Variant = (list[i] as Dictionary).get("former_ids", [])
		if former is Array and (former as Array).has(id):
			return i
	return -1


## Alanın varsayılan indeksi: zorlukta veri dosyasının "default"u (Normal), öteki alanlarda 0 (ilk köken, Göl Mavisi).
static func default_index(field: StringName) -> int:
	if field == &"difficulty":
		return maxi(index_of_id(field, str(data(DIFFICULTY_FILE).get("default", ""))), 0)
	return 0


## Renk alanının renk listesi (renk alanı değilse boş).
static func colors(field: StringName) -> Array[Color]:
	match field:
		&"skin":
			return SKIN_TONES
		&"hair_color":
			return HAIR_COLORS
		&"eye_color":
			return EYE_COLORS
		&"cape_dye":
			var out: Array[Color] = []
			for dye: Dictionary in dyes():
				out.append(Color.html(str(dye.get("color", "#000000"))))
			return out
	return []


## Seçilen renk; "Doğal" (0) ise alfa = 0 olan renk döner — bu "değiştirme" anlamına gelir.
static func color_for(field: StringName, index: int) -> Color:
	var list := colors(field)
	if list.is_empty():
		return Color(0, 0, 0, 0)
	return list[wrapi(index, 0, list.size())]


## Vücut tipi + saç modeli → Meshy model kimliği.
static func model_for(body_type: int, hairstyle: int) -> String:
	var list: Array = HAIRSTYLES.get(clampi(body_type, 0, BODY_TYPES.size() - 1), [])
	if list.is_empty():
		return ""
	return list[wrapi(hairstyle, 0, list.size())]["model"]


## Modelin GLB yolu.
static func model_path(model_id: String) -> String:
	return "res://assets/characters/%s/%s.glb" % [model_id, model_id]


# --- Pelerin ve kılık (K58) -------------------------------------------------------

## Pelerin rengi: tek yer (capeTint(eşya, boya); story.md §7.4). Boyanabilir pelerin (Kışlak Pelerini, Boyalı Pelerin)
## seçilen boyayı taşır (listede olmayan boya varsayılana, Göl Mavisi'ne düşer); boyanmayan pelerin kendi rengindedir
## (Kızıl Pelerin #a8321f). Pelerin yoksa ya da tanınmıyorsa alfa 0 döner: modelin kendi pelerin rengi kalır.
static func cape_tint(item: StringName, dye: int) -> Color:
	var def: Variant = (data(CAPES_FILE).get("capes", {}) as Dictionary).get(String(item))
	if not def is Dictionary:
		return Color(0, 0, 0, 0)
	if bool((def as Dictionary).get("dye", false)):
		var list := colors(&"cape_dye")
		if list.is_empty():
			return Color(0, 0, 0, 0)
		return list[dye if dye >= 0 and dye < list.size() else default_index(&"cape_dye")]
	var hex := str((def as Dictionary).get("color", ""))
	return Color.html(hex) if Color.html_is_valid(hex) else Color(0, 0, 0, 0)


## Pelerin boyanabilir mi (boyayı taşır mı)?
static func cape_is_dyed(item: StringName) -> bool:
	var def: Variant = (data(CAPES_FILE).get("capes", {}) as Dictionary).get(String(item))
	return def is Dictionary and bool((def as Dictionary).get("dye", false))


## Kılığın bölge renkleri: {"plate", "tunic", "trim": Color}; tanımlı olmayan bölge (ya da bilinmeyen kılık) alfa 0'dır,
## modelin kendi rengi kalır. Kılığın pelerin rengi yoktur: pelerin yalnız cape_tint'ten gelir.
static func outfit_colors(outfit: StringName) -> Dictionary:
	var def: Variant = (data(CAPES_FILE).get("outfits", {}) as Dictionary).get(String(outfit))
	var out := {}
	for region in ["plate", "tunic", "trim"]:
		var hex := str((def as Dictionary).get(region, "")) if def is Dictionary else ""
		out[region] = Color.html(hex) if Color.html_is_valid(hex) else Color(0, 0, 0, 0)
	return out


## Eşyanın (pelerin ya da kılık) görünen adı (yoksa "").
static func item_name(item: StringName) -> String:
	var all := data(CAPES_FILE)
	for group in ["capes", "outfits"]:
		var def: Variant = (all.get(group, {}) as Dictionary).get(String(item))
		if def is Dictionary:
			return str((def as Dictionary).get("name", ""))
	return ""


## Oyuncunun başlangıç kılığı ve peleri (Kışlak Kaftanı, Kışlak Pelerini): oluşturucunun önizlemesi de oyundaki Mete de bunu giyer.
static func start_outfit() -> StringName:
	return StringName(str((data(CAPES_FILE).get("start", {}) as Dictionary).get("outfit", "")))


static func start_cape() -> StringName:
	return StringName(str((data(CAPES_FILE).get("start", {}) as Dictionary).get("cape", "")))


## Kalabalık giysisinin rengi kurala uyuyor mu? Soğuk bant (OKLCH ton 190–300°, doygunluk ≥0,05; capes.json cold_band)
## kalabalıkta yasaktır, adlı kişide serbesttir: Mete kalabalıkta pelerininden seçilir (K58).
static func crowd_garment_allowed(color: Color) -> bool:
	return not in_cold_band(color)


## Renk soğuk bantta mı?
static func in_cold_band(color: Color) -> bool:
	var band: Dictionary = data(CAPES_FILE).get("cold_band", {})
	return OkColor.in_band(color, float(band.get("hue_min", 190.0)), float(band.get("hue_max", 300.0)), float(band.get("chroma_min", 0.05)))


## Pelerin boyaları (capes.json "dyes": id, name, name_en, color), oluşturucunun sırasıyla.
static func dyes() -> Array:
	return data(CAPES_FILE).get("dyes", [])


## Kökenler (origins.json "origins").
static func origins() -> Array:
	return data(ORIGINS_FILE).get("origins", [])


## Zorluk düzeyleri (difficulty.json "levels").
static func difficulties() -> Array:
	return data(DIFFICULTY_FILE).get("levels", [])


## Zorluk düzeyinin tablosu (kimlikle; yoksa boş sözlük).
static func difficulty_level(id: String) -> Dictionary:
	var i := index_of_id(&"difficulty", id)
	return difficulties()[i] if i >= 0 else {}


## data/character/<ad>.json (bir kez okunur; okunamazsa boş sözlük ve hata).
static func data(file_name: String) -> Dictionary:
	if _data_cache.has(file_name):
		return _data_cache[file_name]
	var path := DATA_DIR + file_name + ".json"
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if not parsed is Dictionary:
		push_error("[character_options] okunamadı: %s" % path)
		parsed = {}
	_data_cache[file_name] = parsed
	return parsed


static func _list(field: StringName) -> Array:
	match field:
		&"origin":
			return origins()
		&"difficulty":
			return difficulties()
		&"cape_dye":
			return dyes()
	return []
