class_name ItemCatalog
extends RefCounted
## Eşya kataloğu (saf, statik; economy.md §2, §4.2; progression.md §6–§7; godot.md §3 «Envanter ve ekonomi»): data/economy/items.json
## bir kez okunur. Satırın alanları dosyanın doc'undadır; burada okuma, etiket eşleme, İnce İş eki, yığının Yük'ü ve Heybe sekmesi.
##   ItemCatalog.row("wood_pine")            # {} bilinmeyen kimlikte; "hun_bow+" (İnce İş) taban satırı verir
##   ItemCatalog.matches("wood_larch", "tag:wood")   # true: etiket satırdan okunur, ad öneki değildir
##   ItemCatalog.stack_load10("arrow_bone", 11)      # 6: ceil(11 × 5 / 10), onda bir Yük
##   ItemCatalog.tab_of("stone")             # "back": araç → tools, görevlik → keepsakes, sırt yükü → back, yiyecek/ot/av → food, kalan craft
## Kimlik «x+» İnce İş'tir: yalnız fine işaretli teçhizatta geçerlidir; düz kimlik İnce İş'i de kapsar («hun_bow+» bir «hun_bow»dur),
## «x+» istenirse yalnız İnce İş tutar.

const PATH := "res://data/economy/items.json"
const TAG := "tag:"
const FINE_SUFFIX := "+"
## İnce İş'in gizli Kıymet çarpanı (economy.md §2.10).
const FINE_WORTH := 1.5
## Heybe sekmeleri (economy.md §4.2) ve kademeler (§2.7).
const TABS: Array[String] = ["back", "food", "craft", "tools", "keepsakes"]
const TIERS: Array[String] = ["raw", "proc", "part", "fin", "bundle"]
## Bozulan çiğ yiyeceğin döndüğü eşya (Bozuk Et; yalnız köpeğe verilir).
const SPOILED := "spoiled"
## İnce İş adının eki.
const FINE_NAME := {"tr": "%s · İnce İş", "en": "%s · Fine Work"}

static var _data: Dictionary = {}
static var _items: Dictionary = {}
static var _path := PATH


## Dosyanın tamamı (önbellekli). Okunamazsa boş katalog (hata bir kez yazılır).
static func data() -> Dictionary:
	if _data.is_empty():
		_data = _read(_path)
		_items = _data.get("items", {}) if _data.get("items") is Dictionary else {}
	return _data


## Önbelleği boşaltır; path verilirse sonraki okuma o dosyadan (sınama).
static func reset_cache(path := PATH) -> void:
	_data = {}
	_items = {}
	_path = path


static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("[items] katalog yok: %s" % path)
		return {"items": {}}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("[items] katalog okunamadı: %s" % path)
		return {"items": {}}
	return parsed


## Bütün kimlikler (dosyadaki sırayla).
static func ids() -> PackedStringArray:
	data()
	return PackedStringArray(_items.keys())


static func is_fine(id: String) -> bool:
	return id.length() > 1 and id.ends_with(FINE_SUFFIX)


## "hun_bow+" → "hun_bow".
static func base_id(id: String) -> String:
	return id.substr(0, id.length() - 1) if is_fine(id) else id


## Satır ({} bilinmeyen kimlikte ya da İnce İş yapılamayan eşyanın «+» kimliğinde). Satır paylaşılır: değiştirilmez.
static func row(id: String) -> Dictionary:
	data()
	var r: Variant = _items.get(base_id(id))
	if not r is Dictionary:
		return {}
	if is_fine(id) and not bool((r as Dictionary).get("fine", false)):
		return {}
	return r


static func has(id: String) -> bool:
	return not row(id).is_empty()


## Görünen ad (lang "tr" ya da "en"); İnce İş: «Hun Yayı · İnce İş». Bilinmeyen kimlik kendisidir.
static func name_of(id: String, lang := "tr") -> String:
	var r := row(id)
	if r.is_empty():
		return id
	var n := _pick(r.get("name"), lang, id)
	return str(FINE_NAME.get(lang, FINE_NAME["tr"])) % n if is_fine(id) else n


## Çekmecenin yazısı (satırda yoksa boş: arayüz alanlardan kurar).
static func text_of(id: String, lang := "tr") -> String:
	return _pick(row(id).get("text"), lang, "")


## {tr, en} sözlüğünden dilin dizgesi (yoksa Türkçesi, o da yoksa fallback).
static func _pick(v: Variant, lang: String, fallback: String) -> String:
	if v is Dictionary:
		var d := v as Dictionary
		return str(d.get(lang, d.get("tr", fallback)))
	return fallback if v == null else str(v)


## Sekme, kademe, yuva ve etiket adları (labels: tabs, tiers, slots, tags).
static func label(group: String, key: String, lang := "tr") -> String:
	var g: Variant = (data().get("labels", {}) as Dictionary).get(group, {})
	return _pick((g as Dictionary).get(key) if g is Dictionary else null, lang, key)


static func w10(id: String) -> int:
	return int(row(id).get("w10", 0))


static func per(id: String) -> int:
	return maxi(1, int(row(id).get("per", 1)))


static func stack(id: String) -> int:
	return maxi(1, int(row(id).get("stack", 1)))


static func tier(id: String) -> String:
	return str(row(id).get("tier", "fin"))


static func act(id: String) -> int:
	return int(row(id).get("act", 1))


static func tags(id: String) -> Array:
	var t: Variant = row(id).get("tags", [])
	return t if t is Array else []


static func has_tag(id: String, tag: String) -> bool:
	return tags(id).has(tag)


## Kuşam yuvası ("" yoksa): slots ya da mount_slots'tan biri.
static func slot_of(id: String) -> String:
	var s: Variant = row(id).get("slot")
	return str(s) if s != null else ""


static func tool_of(id: String) -> Dictionary:
	var t: Variant = row(id).get("tool")
	return t if t is Dictionary else {}


static func is_tool_item(id: String) -> bool:
	return not tool_of(id).is_empty()


## Görevlik eşya (tag:key; Hatıra sekmesi: satılmaz, atılmaz, el konmaz). Çığırtkan gibi takılan görevlik eşya da sayılır.
static func is_keepsake(id: String) -> bool:
	return has_tag(id, "key")


## Giyimin etkisi (gear: derive() okur); yoksa {}.
static func gear_of(id: String) -> Dictionary:
	var g: Variant = row(id).get("gear")
	return g if g is Dictionary else {}


## Bozulan çiğ yiyeceğin türü: "meat", "fish" ya da "".
static func perish_of(id: String) -> String:
	var p: Variant = row(id).get("perish")
	return str(p) if p != null else ""


## Bohçanın içeriği ({} bohça değilse).
static func bundle_of(id: String) -> Dictionary:
	var b: Variant = row(id).get("bundle")
	return b if b is Dictionary else {}


static func ration_of(id: String) -> float:
	return float(row(id).get("ration", 0.0))


static func fuel_of(id: String) -> float:
	return float(row(id).get("fuel", 0.0))


## Gizli Kıymet (oyuncuya hiç çıkmaz); İnce İş ×1,5. Kıymeti olmayan (teçhizat, görevlik) -1.
static func worth_of(id: String) -> float:
	var w: Variant = row(id).get("worth")
	if w == null or not (w is float or w is int):
		return -1.0
	return float(w) * (FINE_WORTH if is_fine(id) else 1.0)


## Atlas simgesi ("" yoksa: arayüz kodla çizer).
static func icon_of(id: String) -> String:
	var i: Variant = row(id).get("icon")
	return str(i) if i != null else ""


## ref: kimlik ("wood_pine") ya da etiket ("tag:wood"). Düz kimlik İnce İş'i de kapsar; "x+" yalnız İnce İş'i.
static func matches(id: String, ref: String) -> bool:
	if id.is_empty() or ref.is_empty():
		return false
	if ref.begins_with(TAG):
		return has(id) and has_tag(id, ref.substr(TAG.length()))
	if id == ref:
		return true
	return not is_fine(ref) and is_fine(id) and base_id(id) == ref


## Yığının Yük'ü, onda bir: ceil(n × w10 / per) (ok 10 adet 5, 11 adet 6; kütük 3 adet 120).
static func stack_load10(id: String, n: int) -> int:
	var r := row(id)
	if r.is_empty() or n <= 0:
		return 0
	var w := int(r.get("w10", 0))
	var p := maxi(1, int(r.get("per", 1)))
	return ceil_div(n * w, p)


## Pozitif bölmenin tavanı (tamsayı).
static func ceil_div(a: int, b: int) -> int:
	if b <= 0:
		return 0
	return (a + b - 1) / b if a >= 0 else -((-a) / b)


## Heybe sekmesi: araç → tools, görevlik → keepsakes, sırt yükü (tag:bulk) → back, yiyecek, ot ve av → food, kalan craft. Giyim
## (yuvası olan) Zanaat'tadır ve yuva tutar. Bilinmeyen kimlik "".
static func tab_of(id: String) -> String:
	var r := row(id)
	if r.is_empty():
		return ""
	if r.get("tool") is Dictionary:
		return "tools"
	var t := tags(id)
	if t.has("key"):
		return "keepsakes"
	if t.has("bulk"):
		return "back"
	if t.has("food") or t.has("herb") or t.has("game"):
		return "food"
	return "craft"


## Erzak ve Zanaat Heybe'nin ortak yuvalarını tutar; sırt yükü, araç ve görevlik eşya tutmaz.
static func uses_slot(id: String) -> bool:
	var tab := tab_of(id)
	return tab == "food" or tab == "craft"


## Mete'nin kuşam yuvaları (progression.md §6.1) ve binek yuvaları.
static func slots() -> Array:
	var s: Variant = data().get("slots", [])
	return s if s is Array else []


static func mount_slots() -> Array:
	var s: Variant = data().get("mount_slots", [])
	return s if s is Array else []


## Başlangıç donanımı: {equip: {yuva: kimlik}, pack: {kimlik: adet}} ({} yoksa).
static func kit(kit_name: String) -> Dictionary:
	var k: Variant = (data().get("kits", {}) as Dictionary).get(kit_name)
	return k if k is Dictionary else {}
