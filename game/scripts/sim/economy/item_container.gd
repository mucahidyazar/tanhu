class_name ItemContainer
extends RefCounted
## Bütün kaplar tek sınıftır (saf; economy.md §4.5–§4.6, d2/core.md §5.6, K24): Heybe, Terki, kızak, araba, sandık, Menzil Ambarı,
## Zula, yerleşimin ambarları, şantiye yığını, yer yığını, kese ve el konan çuval. Sınır onda bir Yük tamsayısıdır (cap10; UNLIMITED
## sınırsız), yuva yalnız Heybe ve Zula'dadır, kabul süzgeci kimlik ya da 'tag:x' listesidir. Çiğ et ve balık gün anahtarıyla iki parçada
## tutulur: edinildiği günden sonraki ikinci şafakta Bozuk Et olur (on_dawn). Kap olay yaymaz: sahibi (Inventory) yayar. Prototipin
## game/container.js'inin Godot'su; kuralları ve sınamaları aynıdır (tests/unit/test_item_container.gd).
##   var chest := ItemContainer.make("chest")             # 60 Yük, her şeyi alır (data/economy/containers.json)
##   chest.can_take("stone", 20)                          # 12: sınırın aldığı en çok adet
##   chest.add("meat", 2, 1043)                           # {added, rest}; gün anahtarı verilmezse kabın günü (son şafak)
##   ItemContainer.transfer(pack, chest, "tag:wood", 5)   # {moved, rest, items}: sığmayan kalır
##   ItemContainer.transfer_all(pack, chest, null, func(id): return ItemCatalog.matches(id, "tag:bulk"))   # Sırtı Boşalt

const RULES_PATH := "res://data/economy/containers.json"
## Sınırsız sınır ve «hepsi» adedi.
const UNLIMITED := -1
const ALL := -1
## «Gün verilmedi» (gün anahtarı eksi de olabilir: Çocukluk'un takvimi dayN < 0).
const NO_DAY := -(1 << 62)
## Bozulma: edinildiği günden sonraki ikinci şafak (24–48 oyun saati).
const SPOIL_AFTER := 2
## Sınırsızın «boş yeri» ve «hepsi»nin sayısı.
const HUGE := 1 << 60

static var _rules: Dictionary = {}

var id := ""
var kind := "ground_pile"
var owner := ""
var hidden := false
var slots := 0
## Kabul süzgeci (boş: hepsi).
var accept := PackedStringArray()
## Gün anahtarı verilmeden eklenen çiğ yiyeceğin günü: son şafak.
var day := 0
## Her değişimde artar: önbellek ve arayüz izler.
var rev := 0

var _cap10 := UNLIMITED
var _cap_source: Callable
var _n: Dictionary = {}
var _days: Dictionary = {}
var _load_rev := -1
var _load10 := 0


func _init(p_id := "", p_kind := "ground_pile", p_cap10 := UNLIMITED, p_slots := 0, p_accept := PackedStringArray(), p_hidden := false) -> void:
	kind = p_kind
	id = p_id if not p_id.is_empty() else p_kind
	_cap10 = p_cap10
	slots = maxi(0, p_slots)
	accept = p_accept
	hidden = p_hidden


## data/economy/containers.json (önbellekli).
static func rules() -> Dictionary:
	if _rules.is_empty():
		var path := RULES_PATH
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
		if not parsed is Dictionary:
			push_error("[kap] kurallar okunamadı: %s" % path)
			parsed = {"kinds": {}, "carry": {}}
		_rules = parsed
	return _rules


static func reset_rules() -> void:
	_rules = {}


## Türün satırı ({} bilinmeyen tür).
static func kind_row(p_kind: String) -> Dictionary:
	var k: Variant = (rules().get("kinds", {}) as Dictionary).get(p_kind)
	return k if k is Dictionary else {}


## Türün adı (Heybe, Terki, Sandık...).
static func kind_name(p_kind: String, lang := "tr") -> String:
	return ItemCatalog._pick(kind_row(p_kind).get("name"), lang, p_kind)


## Türün tablosundan kap. opts: id, cap (Yük) ya da cap10, slots, accept (kimlik ya da 'tag:x' dizisi), owner, hidden.
## Tablonun sınırı null ise (Heybe, Terki, şantiye) opts'un sınırı, o da yoksa sınırsız.
static func make(p_kind: String, opts := {}) -> ItemContainer:
	var k := kind_row(p_kind)
	var cap10 := UNLIMITED
	if opts.has("cap10"):
		cap10 = int(opts["cap10"])
	elif opts.has("cap"):
		cap10 = cap_to_cap10(opts["cap"])
	elif k.get("cap") != null:
		cap10 = cap_to_cap10(k["cap"])
	var acc := PackedStringArray()
	var src: Variant = opts.get("accept", k.get("accept"))
	if src is Array or src is PackedStringArray:
		for ref: Variant in src:
			acc.append(str(ref))
	var c := ItemContainer.new(str(opts.get("id", p_kind)), p_kind, cap10, int(opts.get("slots", k.get("slots", 0))), acc,
		bool(opts.get("hidden", k.get("hidden", false))))
	c.owner = str(opts.get("owner", ""))
	return c


## Yük → onda bir (−1 ve null sınırsız).
static func cap_to_cap10(v: Variant) -> int:
	if v == null or not (v is int or v is float) or float(v) < 0.0:
		return UNLIMITED
	return roundi(float(v) * 10.0)


# --- Sınır ve Yük ------------------------------------------------------------------------------------------------

## Sınır onda bir Yük (UNLIMITED sınırsız). Sahibi verirse (Heybe: loadMax değişir) her okumada ondan.
func cap10() -> int:
	if _cap_source.is_valid():
		return maxi(0, int(_cap_source.call()))
	return _cap10 if _cap10 < 0 else maxi(0, _cap10)


func set_cap10(v: int) -> void:
	_cap10 = v
	_cap_source = Callable()
	rev += 1


## Sınırı sahibi verir (çağrılabilir: () -> int, onda bir Yük).
func set_cap_source(source: Callable) -> void:
	_cap_source = source
	rev += 1


func is_unlimited() -> bool:
	return cap10() < 0


## Yük birimiyle sınır (INF sınırsız).
func cap() -> float:
	var c := cap10()
	return INF if c < 0 else c / 10.0


## İçeriğin Yük'ü, onda bir (içerik değişmedikçe yeniden toplanmaz).
func load10() -> int:
	if _load_rev != rev:
		var sum := 0
		for item_id: String in _n:
			sum += ItemCatalog.stack_load10(item_id, int(_n[item_id]))
		_load10 = sum
		_load_rev = rev
	return _load10


func load_amount() -> float:
	return load10() / 10.0


func free10() -> int:
	var c := cap10()
	return HUGE if c < 0 else maxi(0, c - load10())


func size() -> int:
	return _n.size()


func is_empty() -> bool:
	return _n.is_empty()


## ref'e uyanların toplamı (kimlik ya da 'tag:x'; düz kimlik İnce İş'i de sayar).
func count(ref: String) -> int:
	var sum := 0
	for item_id: String in _n:
		if ItemCatalog.matches(item_id, ref):
			sum += int(_n[item_id])
	return sum


## Yalnız bu kimliğin adedi (İnce İş ve etiket eşleri sayılmaz).
func amount(item_id: String) -> int:
	return int(_n.get(item_id, 0))


func has(ref: String, n := 1) -> bool:
	return count(ref) >= n


## [{id, n}] ekleme sırasıyla.
func list() -> Array:
	var out: Array = []
	for item_id: String in _n:
		out.append({"id": item_id, "n": int(_n[item_id])})
	return out


## Bozulan kimliğin gün parçaları [[gün, adet], …] (kopya, eskiden yeniye).
func days_of(item_id: String) -> Array:
	var out: Array = []
	for part: Array in _days.get(item_id, []):
		out.append([int(part[0]), int(part[1])])
	return out


func slots_used() -> int:
	var used := 0
	for item_id: String in _n:
		if ItemCatalog.uses_slot(item_id):
			used += ItemCatalog.ceil_div(int(_n[item_id]), ItemCatalog.stack(item_id))
	return used


## Boş yuva (yuvasız kapta HUGE).
func slots_free() -> int:
	return maxi(0, slots - slots_used()) if slots > 0 else HUGE


## Kabul süzgeci bu kimliği alır mı (bilinmeyen kimliği hiçbir kap almaz)?
func accepts(item_id: String) -> bool:
	if not ItemCatalog.has(item_id):
		return false
	if accept.is_empty():
		return true
	for ref in accept:
		if ItemCatalog.matches(item_id, ref):
			return true
	return false


## Alınabilecek en çok adet: kabul, Yük (onda bir) ve yuva (yalnız yuvalı kapta).
func can_take(item_id: String, n: int) -> int:
	if n <= 0 or not accepts(item_id):
		return 0
	var most := n
	var cur := int(_n.get(item_id, 0))
	var c := cap10()
	var w := ItemCatalog.w10(item_id)
	if c >= 0 and w > 0:
		var budget := c - (load10() - ItemCatalog.stack_load10(item_id, cur))
		most = mini(most, maxi(0, _floor_div(budget * ItemCatalog.per(item_id), w) - cur))
	if slots > 0 and ItemCatalog.uses_slot(item_id):
		var st := ItemCatalog.stack(item_id)
		var others := slots_used() - ItemCatalog.ceil_div(cur, st)
		most = mini(most, maxi(0, (slots - others) * st - cur))
	return most


## Ekler: {added, rest}. Çiğ et ve balık p_day ile (verilmezse kabın günü) tutulur. allow_over Yük ve yuva sınırını geçer, kabul
## süzgecini geçmez.
func add(item_id: String, n: int, p_day := NO_DAY, allow_over := false) -> Dictionary:
	if n <= 0:
		return {"added": 0, "rest": 0}
	if not accepts(item_id):
		return {"added": 0, "rest": n}
	var k := n if allow_over else can_take(item_id, n)
	if k > 0:
		_put(item_id, k, [], p_day if p_day != NO_DAY else day)
	return {"added": k, "rest": n - k}


## Çıkarır: gerçekten çıkan [{id, n}]. Etiket kabul eder: önce aynı kimlik, sonra İnce İş ve etiket eşleri; çiğde önce eski gün.
func remove(ref: String, n := 1) -> Array:
	var out: Array = []
	var left := n
	for item_id: String in _order(ref):
		if left <= 0:
			break
		var k := mini(left, int(_n.get(item_id, 0)))
		if k <= 0:
			continue
		_take(item_id, k)
		out.append({"id": item_id, "n": k})
		left -= k
	return out


## Şafak: edinildiği günden sonraki ikinci şafağı gören çiğ et ve balık Bozuk Et olur. Dönüş: bozulan [{id, n}]. perish_fish false
## (kış dünyası) balığı donuk tutar: parçaları bugüne toplanır, yaşlanmaz (K1: dünya kuralı, soğuk mekaniği değil).
func on_dawn(p_day: int, perish_fish := true) -> Array:
	day = p_day
	var spoiled: Array = []
	for item_id: String in _days.keys():
		var parts: Array = _days[item_id]
		if not perish_fish and ItemCatalog.perish_of(item_id) == "fish":
			var total := 0
			for part: Array in parts:
				total += int(part[1])
			_days[item_id] = [[p_day, total]]
			continue
		var k := 0
		while not parts.is_empty() and int(parts[0][0]) <= p_day - SPOIL_AFTER:
			k += int(parts.pop_front()[1])
		if k > 0:
			spoiled.append({"id": item_id, "n": k})
	for s: Dictionary in spoiled:
		_drop(str(s["id"]), int(s["n"]))
		_n[ItemCatalog.SPOILED] = int(_n.get(ItemCatalog.SPOILED, 0)) + int(s["n"])
	if not spoiled.is_empty():
		rev += 1
	return spoiled


## Bütün gün anahtarlarını kaydırır (sahibi gün sayacını ilk gerçek şafakla eşlerken).
func shift_days(delta: int) -> void:
	if delta == 0:
		return
	day += delta
	for item_id: String in _days:
		for part: Array in _days[item_id]:
			part[0] = int(part[0]) + delta
	rev += 1


func clear() -> void:
	_n.clear()
	_days.clear()
	rev += 1


# --- Kayıt -------------------------------------------------------------------------------------------------------

## {items: {id: n}, order?: [id, …], perish?: {id: [[gün, n], …]}, day?}: kap yalnız içeriğini yazar; türü ve sınırı sahibinden gelir.
## order eklenme sırasıdır (JSON.stringify sözlüğün anahtarlarını sıralar; ızgara edinme sırasını korusun diye).
func to_dict() -> Dictionary:
	var items := {}
	for item_id: String in _n:
		items[item_id] = int(_n[item_id])
	var out := {"items": items}
	if _n.size() > 1:
		out["order"] = _n.keys()
	if not _days.is_empty():
		var perish := {}
		for item_id: String in _days:
			perish[item_id] = days_of(item_id)
		out["perish"] = perish
	if day != 0:
		out["day"] = day
	return out


## o: to_dict biçimi ya da düz {id: n}. Gün parçası olmayan çiğ yiyecek p_day (yoksa kabın günü) ile başlar; parçaların toplamı
## adedi geçemez. Bilinmeyen kimlik bir uyarıyla, geçersiz adet sessizce düşer. Sınır ve yuva denetlenmez: kayıttaki içerik olduğu gibi döner.
func from_dict(o: Variant, p_day := NO_DAY) -> ItemContainer:
	_n.clear()
	_days.clear()
	var structured: bool = o is Dictionary and (o as Dictionary).get("items") is Dictionary
	if structured and _is_number((o as Dictionary).get("day")):
		day = int((o as Dictionary)["day"])
	elif p_day != NO_DAY:
		day = p_day
	var items: Dictionary = (o as Dictionary)["items"] if structured else (o if o is Dictionary else {})
	var perish: Dictionary = (o as Dictionary)["perish"] if structured and (o as Dictionary).get("perish") is Dictionary else {}
	var dropped := PackedStringArray()
	# Kaydedilen eklenme sırası önce, sırada olmayan (elle yazılmış ya da eski kayıt) sonra.
	var keys: Array = []
	var order: Variant = (o as Dictionary).get("order") if structured else null
	for k: Variant in (order if order is Array else []):
		if items.has(str(k)) and not keys.has(str(k)):
			keys.append(str(k))
	for k: Variant in items:
		if not keys.has(str(k)):
			keys.append(str(k))
	for raw_id: Variant in keys:
		var item_id := str(raw_id)
		var raw: Variant = items[raw_id]
		if not ItemCatalog.has(item_id):
			dropped.append(item_id)
			continue
		if not _is_number(raw) or int(raw) <= 0:
			continue
		var n := int(raw)
		_n[item_id] = n
		if ItemCatalog.perish_of(item_id).is_empty():
			continue
		var parts: Array = []
		var have := 0
		var src: Variant = perish.get(item_id, [])
		for part: Variant in (src if src is Array else []):
			if not part is Array or (part as Array).size() < 2 or not _is_number(part[0]) or not _is_number(part[1]):
				continue
			var take := mini(int(part[1]), n - have)
			if take <= 0:
				continue
			_merge(parts, int(part[0]), take)
			have += take
		if have < n:
			_merge(parts, p_day if p_day != NO_DAY else day, n - have)
		_days[item_id] = parts
	if not dropped.is_empty():
		push_warning("[kap] %s: bilinmeyen eşya düştü: %s" % [id, ", ".join(dropped)])
	rev += 1
	return self


static func _is_number(v: Variant) -> bool:
	return v is int or v is float


# --- Aktarma -----------------------------------------------------------------------------------------------------

## Birden çok kimliği birlikte alabilir mi: kabul, toplam Yük ve yuva (bohça açılırken bütün parçalar sığmalı).
static func can_take_all(c: ItemContainer, parts: Dictionary) -> bool:
	var need10 := 0
	var need_slots := 0
	for raw_id: Variant in parts:
		var item_id := str(raw_id)
		var n := int(parts[raw_id])
		if not c.accepts(item_id):
			return false
		var cur := int(c._n.get(item_id, 0))
		need10 += ItemCatalog.stack_load10(item_id, cur + n) - ItemCatalog.stack_load10(item_id, cur)
		if c.slots > 0 and ItemCatalog.uses_slot(item_id):
			var st := ItemCatalog.stack(item_id)
			need_slots += ItemCatalog.ceil_div(cur + n, st) - ItemCatalog.ceil_div(cur, st)
	if not c.is_unlimited() and need10 > c.free10():
		return false
	return c.slots == 0 or need_slots <= c.slots_free()


## ref'e uyanları sığdığı kadar taşır: {moved, rest, items: [{id, n, unpacked?}]}. Çiğ yiyecek gün parçalarıyla gider. n ALL (−1)
## hepsidir. allow_over sınırı geçer; filter (id) -> bool; unpack bohçayı hedefte açar (şantiye yığını: yurt_kit 8 kimlik, 19 parça),
## bütün parçaları sığmayan bohça taşınmaz.
static func transfer(from: ItemContainer, to: ItemContainer, ref: String, n := ALL, allow_over := false, filter := Callable(),
		unpack := false) -> Dictionary:
	var all := n < 0
	var want := HUGE if all else n
	var items: Array = []
	var moved := 0
	if from == null or to == null or from == to or want <= 0:
		return {"moved": 0, "rest": 0 if all else maxi(0, want), "items": items}
	var left := want
	for item_id: String in from._order(ref):
		if left <= 0:
			break
		if filter.is_valid() and not bool(filter.call(item_id)):
			continue
		var have := int(from._n.get(item_id, 0))
		var parts := ItemCatalog.bundle_of(item_id) if unpack else {}
		if not parts.is_empty():
			var most := mini(have, left)
			var k := 0
			while k < most and _bundle_fits(to, parts, allow_over):
				from._take(item_id, 1)
				for p: Variant in parts:
					to._put(str(p), int(parts[p]), [], to.day)
				k += 1
			if k > 0:
				items.append({"id": item_id, "n": k, "unpacked": true})
				moved += k
				left -= k
			continue
		if not to.accepts(item_id):
			continue
		var k := mini(have, left)
		if not allow_over:
			k = mini(k, to.can_take(item_id, k))
		if k <= 0:
			continue
		to._put(item_id, k, from._take(item_id, k), from.day)
		items.append({"id": item_id, "n": k})
		moved += k
		left -= k
	return {"moved": moved, "rest": 0 if all else want - moved, "items": items}


static func _bundle_fits(to: ItemContainer, parts: Dictionary, allow_over: bool) -> bool:
	if not allow_over:
		return can_take_all(to, parts)
	if to.accept.is_empty():
		return true
	for p: Variant in parts:
		if not to.accepts(str(p)):
			return false
	return true


## Hızlı düğmeler ve teslim: {moved: [{id, n}], rest: [{id, n}]}. list verilmezse kabın bütün içeriği (filter süzer); liste satırı
## {id: kimlik ya da 'tag:x', n} (Eksikleri Al). rest: taşınamayan kalan (listede istenenin eksiği, bütünde kapta kalan uygun eşya).
static func transfer_all(from: ItemContainer, to: ItemContainer, list: Variant = null, filter := Callable(), allow_over := false,
		unpack := false) -> Dictionary:
	var moved := {}
	var rest: Array = []
	var rows: Array = list if list is Array else (from.list() if from else [])
	for row: Variant in rows:
		if not row is Dictionary or str((row as Dictionary).get("id", "")).is_empty():
			continue
		var item_id := str(row["id"])
		if not list is Array and filter.is_valid() and not bool(filter.call(item_id)):
			continue
		var want := int(row.get("n", ALL)) if list is Array else ALL
		var r := transfer(from, to, item_id, want, allow_over, filter, unpack)
		for it: Dictionary in r["items"]:
			moved[it["id"]] = int(moved.get(it["id"], 0)) + int(it["n"])
		var left := int(r["rest"]) if list is Array else int(from._n.get(item_id, 0))
		if left > 0:
			rest.append({"id": item_id, "n": left})
	var out_moved: Array = []
	for k: Variant in moved:
		out_moved.append({"id": k, "n": moved[k]})
	return {"moved": out_moved, "rest": rest}


# --- İç: aktarma bunları kullanır, sınırı çağıran denetler -----------------------------------------------------------

## Kimlik sırası: ref düz kimlikse önce kendisi; sonra ekleme sırasıyla eşleşenler.
func _order(ref: String) -> Array:
	var ids: Array = []
	if _n.has(ref):
		ids.append(ref)
	for item_id: String in _n:
		if item_id != ref and ItemCatalog.matches(item_id, ref):
			ids.append(item_id)
	return ids


## parts: aktarılan gün parçaları ya da boş (tek gün p_day).
func _put(item_id: String, k: int, parts: Array, p_day: int) -> void:
	_n[item_id] = int(_n.get(item_id, 0)) + k
	if not ItemCatalog.perish_of(item_id).is_empty():
		var list: Array = _days.get(item_id, [])
		if not parts.is_empty():
			for part: Array in parts:
				_merge(list, int(part[0]), int(part[1]))
		else:
			_merge(list, p_day, k)
		_days[item_id] = list
	rev += 1


## Çıkan gün parçaları (önce eski; bozulmayan eşyada boş).
func _take(item_id: String, k: int) -> Array:
	var have := int(_n.get(item_id, 0))
	k = mini(k, have)
	if k <= 0:
		return []
	if have - k > 0:
		_n[item_id] = have - k
	else:
		_n.erase(item_id)
	rev += 1
	if not _days.has(item_id):
		return []
	var list: Array = _days[item_id]
	var taken: Array = []
	var left := k
	while left > 0 and not list.is_empty():
		var part: Array = list[0]
		var m := mini(left, int(part[1]))
		taken.append([int(part[0]), m])
		part[1] = int(part[1]) - m
		left -= m
		if int(part[1]) == 0:
			list.pop_front()
	if list.is_empty():
		_days.erase(item_id)
	return taken


## Bozulanı çıkarır (gün parçaları on_dawn'da ayrıldı).
func _drop(item_id: String, k: int) -> void:
	var have := int(_n.get(item_id, 0))
	if have - k > 0:
		_n[item_id] = have - k
	else:
		_n.erase(item_id)
	if _days.has(item_id) and (_days[item_id] as Array).is_empty():
		_days.erase(item_id)


## Gün parçalarını gün sırasıyla birleştirir: [[gün, adet], …] artan.
static func _merge(list: Array, p_day: int, n: int) -> void:
	for i in list.size():
		if int(list[i][0]) == p_day:
			list[i][1] = int(list[i][1]) + n
			return
		if int(list[i][0]) > p_day:
			list.insert(i, [p_day, n])
			return
	list.append([p_day, n])


## Tabana yuvarlayan tamsayı bölme (eksi pay da).
static func _floor_div(a: int, b: int) -> int:
	var q := a / b
	if (a % b != 0) and ((a < 0) != (b < 0)):
		q -= 1
	return q
