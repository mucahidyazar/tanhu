class_name CharacterProfile
extends Resource
## Oyuncunun karakter oluşturucuda yaptığı seçimler (hangi saç, hangi renk, hangi köken...).
##
## Değerler CharacterOptions listelerindeki indekslerdir. Kayıt user:// altında JSON olarak tutulur;
## böylece "Devam Et" gibi özellikler son karakteri geri yükleyebilir. Profil yolculuğun kaydına da girer
## (SaveData'nın "profile" bloğu, kayıt v1): «Yola Hazırlan»ın köken, zorluk ve pelerin boyası orada kimlikle
## yazılır ("origin": "origin_riders", "difficulty": "normal", "cape_dye": "lake_blue"; CharacterOptions.ID_FIELDS),
## görünüşün alanları indeksle. Eski kayıtta olmayan alan varsayılanına düşer (zorlukta Normal); eski kimlik (K104'ten önceki
## kökenler: "origin_load", "origin_listener", "origin_stable") yenisine göçer (CharacterOptions.index_of_id, former_ids).

const SAVE_PATH := "user://tanhu_character.json"

@export var body_type := 0
@export var skin := 0
@export var hairstyle := 0
@export var hair_color := 0
@export var beard := 0
@export var moustache := 0
@export var eyes := 0
@export var eye_color := 0
## Köken (data/character/origins.json): yolculuğun başında statlara eklenir, değişmez.
@export var origin := 0
## Zorluk (data/character/difficulty.json): yolculuğa yazılır; varsayılan Normal.
@export var difficulty := 1
## Pelerin boyası (data/character/capes.json "dyes"): varsayılan Göl Mavisi.
@export var cape_dye := 0


func _init() -> void:
	origin = CharacterOptions.default_index(&"origin")
	difficulty = CharacterOptions.default_index(&"difficulty")
	cape_dye = CharacterOptions.default_index(&"cape_dye")


## Alanın değeri.
func get_value(field: StringName) -> int:
	return int(get(field))


## Alanı ayarlar; değer seçenek sayısına göre başa/sona sarılır.
## Vücut tipi değişince saç modeli yeni tipin listesine sığacak şekilde düzeltilir.
func set_value(field: StringName, value: int) -> void:
	if not field in CharacterOptions.FIELDS:
		push_warning("Bilinmeyen karakter alanı: %s" % field)
		return
	var n := CharacterOptions.count(field, body_type)
	if n <= 0:
		return
	set(field, wrapi(value, 0, n))
	if field == &"body_type":
		hairstyle = wrapi(hairstyle, 0, CharacterOptions.count(&"hairstyle", body_type))
	emit_changed()


## Alanı bir adım ileri (+1) ya da geri (-1) çevirir (UI'daki ◀ ▶ okları).
func cycle(field: StringName, step: int) -> void:
	set_value(field, get_value(field) + step)


## Bu profile ait Meshy model kimliği.
func model_id() -> String:
	return CharacterOptions.model_for(body_type, hairstyle)


## Kökenin kimliği (ör. "origin_riders").
func origin_id() -> String:
	return CharacterOptions.value_id(&"origin", origin)


## Zorluğun kimliği: "story", "normal" ya da "hard".
func difficulty_id() -> String:
	return CharacterOptions.value_id(&"difficulty", difficulty)


## Pelerin boyasının kimliği (ör. "lake_blue").
func cape_dye_id() -> String:
	return CharacterOptions.value_id(&"cape_dye", cape_dye)


## Bu profilin giydiği pelerinin rengi (varsayılan: başlangıç peleri, Kışlak Pelerini; CharacterOptions.cape_tint).
func cape_color(item: StringName = &"") -> Color:
	return CharacterOptions.cape_tint(item if item != &"" else CharacterOptions.start_cape(), cape_dye)


func to_dict() -> Dictionary:
	var d := {}
	for field in CharacterOptions.FIELDS:
		if field in CharacterOptions.ID_FIELDS:
			d[String(field)] = CharacterOptions.value_id(field, get_value(field))
		else:
			d[String(field)] = get_value(field)
	return d


static func from_dict(d: Dictionary) -> CharacterProfile:
	var p := CharacterProfile.new()
	# Önce vücut tipi: saç modeli sayısı ona bağlı.
	p.set_value(&"body_type", int(CharacterProfile._number(d.get("body_type", 0))))
	for field in CharacterOptions.FIELDS:
		if field == &"body_type":
			continue
		if field in CharacterOptions.ID_FIELDS:
			p.set_value(field, CharacterProfile._index_from(field, d.get(String(field))))
		else:
			p.set_value(field, int(CharacterProfile._number(d.get(String(field), 0))))
	return p


## Kimlikle kaydedilen alanın değerini indekse çevirir: kimlik (seçeneğin eski kimliği de, former_ids) ya da eski biçimde sayı;
## okunamazsa varsayılan.
static func _index_from(field: StringName, value: Variant) -> int:
	if value is String or value is StringName:
		var i := CharacterOptions.index_of_id(field, String(value))
		return i if i >= 0 else CharacterOptions.default_index(field)
	if (value is int or value is float) and int(value) >= 0 and int(value) < CharacterOptions.count(field):
		return int(value)
	return CharacterOptions.default_index(field)


static func _number(value: Variant) -> float:
	return float(value) if value is int or value is float else 0.0


## Bağımsız bir kopya (Geri Al geçmişi için).
func copy() -> CharacterProfile:
	return CharacterProfile.from_dict(to_dict())


func equals(other: CharacterProfile) -> bool:
	return other != null and to_dict() == other.to_dict()


## Profili diske yazar.
func save(path: String = SAVE_PATH) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(to_dict(), "\t"))
	return OK


## Kayıtlı profil var mı?
static func has_saved(path: String = SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)


## Kayıtlı profili yükler; yoksa ya da bozuksa varsayılan profili döndürür.
static func load_or_default(path: String = SAVE_PATH) -> CharacterProfile:
	if not FileAccess.file_exists(path):
		return CharacterProfile.new()
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data is Dictionary:
		return CharacterProfile.from_dict(data)
	return CharacterProfile.new()
