class_name MountStable
extends RefCounted
## Yolculuğun binekleri (saf; progression.md §6.4, §13.2 «mounts», fauna.md §2.1, K65): her bineğin Bağ'ı (0–100), at staminası, adı ve at
## eşyası (eyer, gem, toynak, çul); hangisinin binildiği (active) ve yedek at (spare). Kayıt v2'nin «mounts» bloğudur (register_block). Bineğin
## anahtarı Rideable.mount_key()'dir («<satır>@<düğüm>»: horse@doru; terkinin anahtarıyla aynı, Inventory.saddlebags) ya da tasarımın kimliği
## (yakwe, offering_stallion).
##
## Bağ'ın kaynakları (progression.md §6.4): Yem Bağı +5 (günde en çok 3), ad koymak +10 (bir kez), Ahır'da tımar (E 4 sn) +2 (günde 1), ant
## +10 (bir kez; act1.md §8.8 oath_stallion); görev ve etki dilinin payı «effect»tir (sınırsız). Kazanç beceri çarpanıyla (mods.bondGain;
## downwind ×1,25) çarpılır. Bağ ≥40 atlı avı açar (II), ≥70 at gök gürültüsüne aldırmaz (weather.md §8.9). Köken payı (Ahır Yamağı +10)
## bineğin ilk girişinde verilir (entry'nin start_bond'u).
##
## At eşyası (data/economy/items.json mount_slots): yuvaya yalnız o yuvanın eşyası girer. Etkisi gear_effects'tedir: eyer (saddled; yoksa
## çıplak binme, stamina ×1,3 hızlı biter), gem (turnMul: Kemik Gem ×1,04), yular (mountTime −1 sn), toynak sargısı (iceGrip), çul
## (horseStaMul). Üzengi yoktur (K58, K65): dönem dışıdır, eşya listesinde de yoktur.
##
##   var stable := MountStable.new()
##   stable.entry("horse@doru", "horse", 10.0)        # yoksa kurar (satırın varsayılan eşyasıyla), köken payı
##   stable.add_bond("horse@doru", "fodder", day)     # {gained, bond, reason}
##   mount.set_condition(stable.condition("horse@doru", inventory.mount_mods("horse@doru")))
##   stable.register_block(session.blocks)            # kayıt v2 «mounts»

signal changed

## Kayıt bloğunun adı ve sürümü.
const BLOCK := "mounts"
const SAVE_V := 1
## Bağ kaynakları: {miktar, günde en çok (0 sınırsız, -1 bir kez)} (progression.md §6.4; act1.md §8.8).
const BOND_SOURCES := {
	"fodder": {"amount": 5.0, "per_day": 3},
	"name": {"amount": 10.0, "per_day": -1},
	"groom": {"amount": 2.0, "per_day": 1},
	"oath": {"amount": 10.0, "per_day": -1},
}
## Bağ eşikleri (fauna.md §2.1): atlı av ve gök gürültüsüne aldırmamak.
const BOND_HUNT := 40.0
const BOND_THUNDER := 70.0
## At eşyasının yuvaları (items.json mount_slots ile aynı).
const SLOTS: Array[String] = ["saddle", "bridle", "hoof", "blanket"]
## Kökenlerin dosyası (Bağ payı: bond).
const ORIGINS_PATH := "res://data/character/origins.json"

## Binilen ve yedek bineğin anahtarı ("" yok).
var active := ""
var spare := ""
## Bağ kazancının beceri çarpanı (mods.bondGain).
var bond_gain_k := 1.0

## anahtar → {kind, name, owned, bond, sta, gear: {yuva: eşya}, fed: {day, n}, groomed, once: [kaynak]}
var _list: Dictionary = {}

static var _origin_bonds: Dictionary = {}


## Bineğin kaydı (yoksa kurulur: satırın varsayılan eşyası, start_bond kadar Bağ, tam stamina). kind: Mount satırı (boşsa anahtarın @'ten
## önceki parçası).
func entry(key: String, kind := "", start_bond := 0.0) -> Dictionary:
	if key.is_empty():
		return {}
	if not _list.has(key):
		var row_kind := kind if not kind.is_empty() else key.get_slice("@", 0)
		var gear := {}
		for slot in SLOTS:
			gear[slot] = null
		var defaults: Variant = Mount.row_of(row_kind).get("gear", {})
		if defaults is Dictionary:
			for slot: String in defaults:
				if gear.has(slot) and MountStable.fits(slot, str(defaults[slot])):
					gear[slot] = str(defaults[slot])
		_list[key] = {"kind": row_kind, "name": null, "owned": false, "bond": clampf(start_bond, 0.0, 100.0), "sta": 1.0, "gear": gear,
			"fed": {"day": -1, "n": 0}, "groomed": -1, "once": []}
		changed.emit()
	return _list[key]


func has(key: String) -> bool:
	return _list.has(key)


func keys() -> PackedStringArray:
	return PackedStringArray(_list.keys())


## Bağ (0..100; kaydı yoksa 0).
func bond(key: String) -> float:
	return float((_list.get(key, {}) as Dictionary).get("bond", 0.0))


## Bağ'ı doğrudan yazar (0..100; geliştirme ve görev sonucu).
func set_bond(key: String, value: float) -> void:
	var e := entry(key)
	if e.is_empty():
		return
	e["bond"] = clampf(value, 0.0, 100.0)
	changed.emit()


## Bağ kazancı: kaynak BOND_SOURCES'tan («effect» ise amount kadar, sınırsız). day: oyun günü (dayN; günlük sınır için). Döner: {gained,
## bond, reason} (reason "" ya da "day_cap", "once", "unknown", "full").
func add_bond(key: String, source: String, day := 0, amount := 0.0) -> Dictionary:
	var e := entry(key)
	if e.is_empty():
		return {"gained": 0.0, "bond": 0.0, "reason": "unknown"}
	var gain := amount
	if source != "effect":
		var rule: Variant = BOND_SOURCES.get(source)
		if not rule is Dictionary:
			return {"gained": 0.0, "bond": float(e["bond"]), "reason": "unknown"}
		gain = float(rule["amount"])
		var cap := int(rule["per_day"])
		if cap < 0 and (e["once"] as Array).has(source):
			return {"gained": 0.0, "bond": float(e["bond"]), "reason": "once"}
		if source == "fodder":
			var fed: Dictionary = e["fed"]
			if int(fed["day"]) == day and int(fed["n"]) >= cap:
				return {"gained": 0.0, "bond": float(e["bond"]), "reason": "day_cap"}
			fed["n"] = int(fed["n"]) + 1 if int(fed["day"]) == day else 1
			fed["day"] = day
		elif source == "groom":
			if int(e["groomed"]) == day:
				return {"gained": 0.0, "bond": float(e["bond"]), "reason": "day_cap"}
			e["groomed"] = day
		if cap < 0:
			(e["once"] as Array).append(source)
	var before := float(e["bond"])
	e["bond"] = clampf(before + gain * bond_gain_k, 0.0, 100.0)
	changed.emit()
	return {"gained": float(e["bond"]) - before, "bond": float(e["bond"]), "reason": "full" if is_equal_approx(before, 100.0) else ""}


## Ad koymak (+10 Bağ, bir kez; act1.md §8.8 stallion_name). Döner: add_bond'un sonucu.
func set_name(key: String, display_name: String) -> Dictionary:
	var e := entry(key)
	if e.is_empty():
		return {"gained": 0.0, "bond": 0.0, "reason": "unknown"}
	e["name"] = display_name
	return add_bond(key, "name")


func name_of(key: String) -> String:
	var n: Variant = (_list.get(key, {}) as Dictionary).get("name")
	return str(n) if n != null else ""


## At staminası (0..1; kaydı yoksa 1).
func stamina(key: String) -> float:
	return float((_list.get(key, {}) as Dictionary).get("sta", 1.0))


func set_stamina(key: String, value: float) -> void:
	var e: Dictionary = _list.get(key, {})
	if e.is_empty():
		return
	e["sta"] = clampf(value, 0.0, 1.0)


## Binilmeyen bineklerin soluğu: binilen (riding) dışındakiler dinlenir (Mount.rest_regen; Bağ'a göre).
func rest(delta: float, riding := "") -> void:
	if delta <= 0.0:
		return
	for key: String in _list:
		if key == riding:
			continue
		var e: Dictionary = _list[key]
		if float(e["sta"]) < 1.0:
			e["sta"] = minf(1.0, float(e["sta"]) + Mount.rest_regen(float(e["bond"])) * delta)


# --- At eşyası --------------------------------------------------------------------------------------------------

## Eşya bu yuvaya girer mi (items.json'da yuvası bu)?
static func fits(slot: String, item_id: String) -> bool:
	return not item_id.is_empty() and SLOTS.has(slot) and ItemCatalog.has(item_id) and ItemCatalog.slot_of(item_id) == slot


## Yuvadaki eşya ("" boş).
func gear_of(key: String, slot: String) -> String:
	var g: Variant = ((_list.get(key, {}) as Dictionary).get("gear", {}) as Dictionary).get(slot)
	return str(g) if g != null else ""


## Eşyayı yuvaya takar; eski eşya döner ("" yoksa). Yuvaya girmeyen eşya takılmaz (döner: "!"). Heybeden almak ve geri koymak çağıranındır.
func equip(key: String, slot: String, item_id: String) -> String:
	var e := entry(key)
	if e.is_empty() or not MountStable.fits(slot, item_id):
		return "!"
	var old := gear_of(key, slot)
	(e["gear"] as Dictionary)[slot] = item_id
	changed.emit()
	return old


## Yuvayı boşaltır; çıkan eşya döner ("" boştu).
func unequip(key: String, slot: String) -> String:
	var e: Dictionary = _list.get(key, {})
	if e.is_empty() or not SLOTS.has(slot):
		return ""
	var old := gear_of(key, slot)
	(e["gear"] as Dictionary)[slot] = null
	changed.emit()
	return old


## At eşyasının etkisi (saf): saddled (eyer var), turn_mul (gem), mount_time (yular, sn), ice_grip (sargı), stamina_mul (çul).
static func gear_effects_of(gear: Dictionary) -> Dictionary:
	var out := {"saddled": false, "turn_mul": 1.0, "mount_time": 0.0, "ice_grip": false, "stamina_mul": 1.0}
	for slot: String in gear:
		var item: Variant = gear[slot]
		if item == null or str(item).is_empty():
			continue
		var g := ItemCatalog.gear_of(str(item))
		if bool(g.get("saddled", false)):
			out["saddled"] = true
		out["turn_mul"] = float(out["turn_mul"]) * float(g.get("turnMul", 1.0))
		out["mount_time"] = float(out["mount_time"]) + float(g.get("mountTime", 0.0))
		if bool(g.get("iceGrip", false)):
			out["ice_grip"] = true
		out["stamina_mul"] = float(out["stamina_mul"]) * float(g.get("horseStaMul", 1.0))
	return out


func gear_effects(key: String) -> Dictionary:
	return MountStable.gear_effects_of((_list.get(key, {}) as Dictionary).get("gear", {}))


## Atı tutmanın süresi (saf; binişin yanaşmadan sonraki evresi, PlayerController.mount_take_seconds; Yol Haritası mount-bond-actions): başı çıplak
## at (bridle yuvası boş) yeleden tutulur ve sakinleşene dek bekler: catch_s × (1 − Bağ/100); başlıklı at (yular ya da gem) iple ya da dizginle
## hemen tutulur. Yuların «binme süresi −1 sn»si (items.json halter mountTime) bu çıplak başa göredir; mount_time yuvaların toplamıdır ve
## sürenin üstüne eklenir (en az 0).
static func take_seconds(catch_s: float, bond_value: float, bridle: String, mount_time := 0.0) -> float:
	if catch_s <= 0.0:
		return 0.0
	var base := catch_s * (1.0 - clampf(bond_value, 0.0, 100.0) / 100.0) if bridle.is_empty() else 0.0
	return maxf(0.0, base + mount_time)


## Bineğin yuvalarını verilen eşyayla kurar (ahırın atı: eyersiz, yularsız; null ya da "" boş). Yuvaya girmeyen eşya atlanır.
func set_gear(key: String, gear: Dictionary) -> void:
	var e := entry(key)
	if e.is_empty():
		return
	for slot: String in gear:
		if not SLOTS.has(slot):
			continue
		var item: Variant = gear[slot]
		(e["gear"] as Dictionary)[slot] = str(item) if item != null and MountStable.fits(slot, str(item)) else null
	changed.emit()


## Bugünkü yem sayısı ve tımar (ahırın ipucu): {fed, fed_max, groomed, named, oath}.
func care_of(key: String, day: int) -> Dictionary:
	var e: Dictionary = _list.get(key, {})
	var fed: Dictionary = e.get("fed", {"day": -1, "n": 0})
	return {
		"fed": int(fed.get("n", 0)) if int(fed.get("day", -1)) == day else 0, "fed_max": int(BOND_SOURCES["fodder"]["per_day"]),
		"groomed": int(e.get("groomed", -1)) == day, "named": e.get("name") is String and not str(e.get("name")).is_empty(),
		"oath": (e.get("once", []) as Array).has("oath"),
	}


## Binişin koşulu (Mount.set_condition): Bağ, eşya ve terki (load: Inventory.mount_mods; speed_k, can_gallop). mods: beceri çarpanları
## (gallop, horseDrain; Progression.mods).
func condition(key: String, load: Dictionary = {}, mods: Dictionary = {}) -> Dictionary:
	var fx := gear_effects(key)
	return {
		"bond": bond(key), "saddled": bool(fx["saddled"]), "turn_mul": float(fx["turn_mul"]), "stamina_mul": float(fx["stamina_mul"]),
		"load_k": float(load.get("speed_k", 1.0)), "can_gallop": bool(load.get("can_gallop", true)),
		"drain_mul": float(mods.get("horseDrain", 1.0)), "gallop_add": float(mods.get("gallop", 0.0)),
	}


## Kökenin Bağ payı (data/character/origins.json bond; Yılkı Beyi 10, ötekiler 0). Kökenin eski kimliği (former_ids; K104'ten önceki
## origin_stable) aynı payı verir.
static func origin_bond(origin_id: String) -> float:
	if _origin_bonds.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ORIGINS_PATH))
		var rows: Variant = (parsed as Dictionary).get("origins", []) if parsed is Dictionary else []
		for row: Variant in rows:
			if row is Dictionary:
				var bond := float((row as Dictionary).get("bond", 0.0))
				_origin_bonds[str((row as Dictionary).get("id", ""))] = bond
				var former: Variant = (row as Dictionary).get("former_ids", [])
				for old: Variant in (former if former is Array else []):
					_origin_bonds[str(old)] = bond
	return float(_origin_bonds.get(origin_id, 0.0))


# --- Kayıt v2 («mounts» bloğu; progression.md §13.2) ---------------------------------------------------------------

## Blok: {v, active, spare, list: {anahtar: {kind, name, owned, bond, sta, gear, fed, groomed, once}}}.
func to_dict() -> Dictionary:
	var list := {}
	for key: String in _list:
		list[key] = (_list[key] as Dictionary).duplicate(true)
	return {"v": SAVE_V, "active": active if not active.is_empty() else null, "spare": spare if not spare.is_empty() else null, "list": list}


## Bloğu okur (denetimden geçmiş olmalı: validate_save_block). Bilinmeyen eşya ve yuvası tutmayan eşya düşer; sayılar kırpılır.
func from_dict(d: Dictionary) -> bool:
	if not MountStable.validate_save_block(d).is_empty():
		return false
	reset()
	active = str(d.get("active")) if d.get("active") != null else ""
	spare = str(d.get("spare")) if d.get("spare") != null else ""
	var list: Dictionary = d.get("list", {})
	for key: String in list:
		var src: Dictionary = list[key]
		var gear := {}
		var gear_src: Dictionary = src.get("gear", {}) if src.get("gear") is Dictionary else {}
		for slot in SLOTS:
			var item: Variant = gear_src.get(slot)
			gear[slot] = str(item) if item != null and MountStable.fits(slot, str(item)) else null
		var fed: Dictionary = src.get("fed", {}) if src.get("fed") is Dictionary else {}
		_list[key] = {
			"kind": str(src.get("kind", key.get_slice("@", 0))), "name": src.get("name") if src.get("name") is String else null,
			"owned": bool(src.get("owned", false)), "bond": clampf(float(src.get("bond", 0.0)), 0.0, 100.0),
			"sta": clampf(float(src.get("sta", 1.0)), 0.0, 1.0), "gear": gear,
			"fed": {"day": int(fed.get("day", -1)), "n": int(fed.get("n", 0))}, "groomed": int(src.get("groomed", -1)),
			"once": (src.get("once", []) as Array).duplicate() if src.get("once") is Array else [],
		}
	changed.emit()
	return true


## Kayıtta blok yoksa (yeni yolculuk): binek yok.
func reset() -> void:
	_list.clear()
	active = ""
	spare = ""


## Bloğun durağan denetimi (SaveBlocks.OWNERS «mounts»; "" geçer).
static func validate_save_block(d: Dictionary) -> String:
	if not d.get("list", {}) is Dictionary:
		return "mounts.list sözlük değil"
	for key: Variant in d.get("list", {}):
		var e: Variant = (d["list"] as Dictionary)[key]
		if not e is Dictionary:
			return "mounts.list.%s sözlük değil" % str(key)
		for num in ["bond", "sta"]:
			var v: Variant = (e as Dictionary).get(num, 0.0)
			if not (v is float or v is int) or not is_finite(float(v)):
				return "mounts.list.%s.%s sayı değil" % [str(key), num]
	for slot_key in ["active", "spare"]:
		var v: Variant = d.get(slot_key)
		if v != null and not v is String:
			return "mounts.%s metin değil" % slot_key
	return ""


## Oturumun blok kaydına bağlanır (kayıt v2; sıra 46: envanter ve ekonomiden sonra, terki onundur).
func register_block(blocks: SaveBlocks) -> void:
	if blocks == null:
		return
	blocks.register(BLOCK, SAVE_V, to_dict, from_dict, {"reset": reset, "check": MountStable.validate_save_block, "order": 46, "max_bytes": 2048})
