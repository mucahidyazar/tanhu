class_name Hunt
extends RefCounted
## Av verimi (saf; survival.md §4.6, §4.7; fauna.md §1, §4; economy.md §3.6; progression.md §1.3; K65; data/survival/hunt.json).
## Türün verimi data/fauna/kinds.json'dadır: yield taban (fauna.md §1), yield_season mevsimin eki (tarbagan güzde +1 iç yağı). Ekler:
## tek okta düşen avda +1 deri (veriminde hide ya da hide_small varsa), Avcı becerisi (huntYield) ve Kopuz Gecesi ilk kaleme +1.
## Yetişkin düşen hayvanı yüzer: eşya verim verim Heybe'ye girer (Inventory.receive, kaynak «hunt»; sığmayan önce yakındaki atın
## terkisine, sonra leşin yerine yer yığını olur). Yüzmek bıçak ister; bıçaksız yalnız küçük av. Çocuk hayvanı bütün alır; bütün av
## (items.json'un game satırı) düzülünce (dress) aynı verimi verir. Tür başına ilk av Progression «hunt» kaynağıdır (+40, once).
##   Hunt.yield_of("marmot", {"season": &"autumn"})           # {meat: 1, fat: 2, hide_small: 1}
##   Hunt.deliver(inv, {"meat": 1, "fat": 1}, leşin_yeri)     # {added: {meat: 1, fat: 1}, rest: {}}
##   Hunt.dress(inv, "lark", {"season": &"spring"})          # bütün tarla kuşu → 1 küçük et

const DATA_PATH := "res://data/survival/hunt.json"
const SRC := "hunt"

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)) if FileAccess.file_exists(DATA_PATH) else null
		_data = parsed if parsed is Dictionary else {}
	return _data


static func reset_cache() -> void:
	_data = {}


## Türün satırı (data/fauna/kinds.json; yoksa boş).
static func kind_row(kind_id: String) -> Dictionary:
	var kinds: Variant = Catalog.data("fauna/kinds")
	if kinds is Dictionary:
		var row: Variant = ((kinds as Dictionary).get("kinds", {}) as Dictionary).get(kind_id)
		if row is Dictionary:
			return row
	return {}


## Küçük av mı (bıçaksız yüzülür): canı small_hp ya da altı, ya da kuş.
static func is_small(kind_id: String) -> bool:
	var row := kind_row(kind_id)
	if row.is_empty():
		return false
	return str(row.get("class", "")) == "bird" or float(row.get("hp", 999.0)) <= float(data().get("small_hp", 8))


## Verim (saf). opts: season (StringName: winter, spring, summer, autumn), clean (tek okta düştü), hunter (Avcı becerisinin huntYield'i),
## kopuz (Kopuz Gecesi'nin ertesi gününün ilk büyük avı). Bilinmeyen tür boş.
static func yield_of(kind_id: String, opts: Dictionary = {}) -> Dictionary:
	var row := kind_row(kind_id)
	var base: Variant = row.get("yield", {})
	if not base is Dictionary:
		return {}
	var out := {}
	var order: Array = []
	for k: Variant in base:
		out[str(k)] = int(base[k])
		order.append(str(k))
	var season := str(opts.get("season", ""))
	var bonus: Variant = (row.get("yield_season", {}) as Dictionary).get(season) if row.get("yield_season") is Dictionary else null
	if bonus is Dictionary:
		for k: Variant in bonus:
			if not out.has(str(k)):
				order.append(str(k))
			out[str(k)] = int(out.get(str(k), 0)) + int(bonus[k])
	if bool(opts.get("clean", false)):
		var hide_id := "hide" if out.has("hide") else ("hide_small" if out.has("hide_small") else "")
		if not hide_id.is_empty():
			out[hide_id] = int(out[hide_id]) + int(data().get("clean_bonus", 1))
	var extra := int(opts.get("hunter", 0)) + (int(data().get("kopuz_bonus", 1)) if bool(opts.get("kopuz", false)) else 0)
	if extra > 0 and not order.is_empty():
		out[order[0]] = int(out[order[0]]) + extra
	return out


## Yüzmek için bıçak var mı (kuşanılan ya da Heybe'deki kesici)?
static func has_knife(inv: Inventory) -> bool:
	if inv == null:
		return false
	for ref: Variant in data().get("knife_refs", []):
		if inv.has(str(ref)):
			return true
	return false


## Yüzülebilir mi: "" evet, "need_knife" bıçak gerek (büyük av).
static func skin_block(kind_id: String, inv: Inventory) -> String:
	if Hunt.is_small(kind_id) or Hunt.has_knife(inv):
		return ""
	return "need_knife"


## Yüzme süresi (sn): skin_s × Avcı becerisinin skinT'si.
static func skin_seconds(skin_t: float = 1.0) -> float:
	return float(data().get("skin_s", 2.0)) * maxf(skin_t, 0.05)


## Verimi Heybe'ye verir (sıra verimin sırası): her eşya Inventory.receive(id, n, "hunt", {spill_at}) ile; sığmayan yakındaki atın
## terkisine, sonra at'taki yer yığınına. Döner: {added: {id: n}, rest: {id: n}}.
static func deliver(inv: Inventory, yields: Dictionary, at: Variant = null, src := SRC) -> Dictionary:
	var added := {}
	var rest := {}
	if inv == null:
		return {"added": added, "rest": yields.duplicate()}
	var opts := {}
	if at is Vector3:
		opts["spill_at"] = at
	for item_id: String in yields:
		var n := int(yields[item_id])
		if n <= 0 or not ItemCatalog.has(item_id):
			continue
		var r := inv.receive(item_id, n, src, opts)
		if int(r["added"]) > 0:
			added[item_id] = int(r["added"])
		if int(r["rest"]) > 0:
			rest[item_id] = int(r["rest"])
	return {"added": added, "rest": rest}


## Bütün avı (items.json game satırı: tarla kuşu, tarbagan...) düzer: Heybe'den bir tane düşer, verimi verim verim girer. Döner:
## {added, rest} ya da boş (o eşya yoksa ya da av değilse).
static func dress(inv: Inventory, item_id: String, opts: Dictionary = {}, at: Variant = null) -> Dictionary:
	var kind := str(ItemCatalog.row(item_id).get("game", ""))
	if inv == null or kind.is_empty() or inv.count(item_id) <= 0:
		return {}
	inv.remove(item_id, 1)
	return Hunt.deliver(inv, Hunt.yield_of(kind, opts), at)


## Verimin yazısı («Et ×1, İç Yağı ×1»).
static func items_text(items: Dictionary, lang := "tr") -> String:
	var parts := PackedStringArray()
	for item_id: String in items:
		parts.append("%s ×%d" % [ItemCatalog.name_of(item_id, lang), int(items[item_id])])
	return ", ".join(parts)


static func text(key: String, lang := "tr", args: Dictionary = {}) -> String:
	var t: Variant = (data().get("text", {}) as Dictionary).get(key)
	var s := Catalog.pick(t, lang) if t != null else key
	for k: String in args:
		s = s.replace("{%s}" % k, str(args[k]))
	return s
