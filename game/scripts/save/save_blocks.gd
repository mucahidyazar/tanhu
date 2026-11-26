class_name SaveBlocks
extends RefCounted
## Kayıt v2'nin blokları (godot.md §3.4, d2/core.md §6.2; Yol Haritası save-v2): her blok bir sistemindir, kendi sürümünü (v) taşır ve
## sahibinin to_dict / from_dict'iyle (ya da load_dict) yazılır. Session bir tane tutar (session.blocks); süren yolculuk onu
## Journey.live_blocks'ta tutar ve kayda yazar (Journey.collect_blocks). Sistem kendi bloğunu kaydeder:
##
##   session.blocks.register("weather", 1, planner.to_dict, planner.load_dict, {
##       "reset": planner.reset,                        # kayıtta blok yoksa (yeni yolculuk, v1 kaydı)
##       "migrate": {1: func(d: Dictionary) -> Dictionary: ...},   # n → n+1 (eksikse veri olduğu gibi kalır, uyarı yazılır)
##       "check": func(d: Dictionary) -> String: ...,   # "" geçer; yükleme öncesi derin denetim
##       "order": 78, "max_bytes": 1024})               # okunma sırası (artan; eşitte kayıt sırası), tavan (aşım uyarıdır)
##   record["blocks"] = blocks.collect()               # {ad: {v, ...}}; kayıtlı olmayan ama kayıtta okunan bloklar da taşınır
##   var err := blocks.apply(record["blocks"])         # önce hepsi göçer ve denetlenir, sonra okunur: hata varsa hiçbiri okunmaz
## apply'dan sonra kaydedilen blok (oturum kurulduktan sonra gelen sistem) kayıtta taşınan bloğunu kayıt anında okur (göç ve denetimle);
## okuyamazsa hata yazılır ve varsayılanına döner.
##
## Bozuk blok boş yuva sayılır (godot.md §3.4): yarım kurulmuş dünya boş yuvadan kötüdür, kısmi yükleme yapılmaz. Menü kayıtları
## listelerken sistemler kurulu değildir: check_blocks yapıyı (sözlük, ad, v) ve sahibinin durağan denetimini (OWNERS'taki sınıfın
## static func validate_save_block(d: Dictionary) -> String'i; yoksa yerleşik denetim, bugün yalnız clock) okur. Derin denetim
## yüklemede apply'ın «check»idir; apply hata dönerse oturum bırakılır ve kayıt «Bu kayıt açılamadı.» olur.

## Yolculuk kaydının tavanı (bayt; d2/core.md §6.2). Aşım kaydı engellemez, uyarıdır: ilerleme kaybı tavan aşımından kötüdür.
const JOURNEY_MAX_BYTES := 96 * 1024
## Blokların tavanları (bayt; d2/core.md §6.2, godot.md §3.4, fauna.md §10).
const MAX_BYTES := {
	"sites": 20 * 1024, "settlement": 14 * 1024, "party": 6 * 1024, "camps": 4 * 1024, "weather": 1024, "fauna": 614,
}
## Blokların planlanan sahipleri (godot.md §3.4, §3 «Sistem haritası»): durağan denetim bu sınıfın validate_save_block'unu arar. Sahip
## kendi bloğunu yazarken adı burada değilse ya da başka sınıfsa bu satır düzeltilir; sınıf henüz yoksa yalnız yapı denetlenir.
const OWNERS := {
	"clock": "GameClock", "calendar": "GameCalendar", "weather": "WeatherPlanner", "inventory": "Inventory", "economy": "Economy",
	"sites": "SiteState", "settlement": "Settlement", "camps": "Camps", "army": "Squad", "quests": "Quests",
	"progression": "Progression", "survival": "Survival", "fauna": "FaunaDirector", "travel": "Travel", "party": "PartyManager",
	"mounts": "MountStable",
}
## Durağan denetim yöntemi.
const VALIDATE_METHOD := &"validate_save_block"
const DEFAULT_ORDER := 50

## Sahip sınıfının betiği ve denetimi var mı (önbellek): sınıf adı → Script ya da null.
static var _owner_scripts: Dictionary = {}

## ad → {name, v, write, read, reset, check, migrate, order, max_bytes, seq}
var _defs: Dictionary = {}
var _order: Array[String] = []
var _seq := 0
## Kayıtta okunan ama bu oturumda sahibi olmayan bloklar: sonraki kayda olduğu gibi yazılır (sistem gelince okur).
var _carry: Dictionary = {}


# --- Kayıt ----------------------------------------------------------------------------------------------

## Bloğu kaydeder. write: () -> Dictionary; read: (Dictionary) -> bool ya da void (false dönerse okunamadı). Aynı ad yeniden
## kaydedilirse sonuncusu geçer (uyarı). Kayıttan taşınan aynı adda blok varsa hemen okunur (bkz. üstte). Döner: kaydedildi mi?
func register(name: String, version: int, write: Callable, read: Callable, opts: Dictionary = {}) -> bool:
	if not is_block_name(name):
		push_error("[save] geçersiz blok adı «%s» (küçük harf, rakam, alt çizgi)" % name)
		return false
	if version < 1:
		push_error("[save] %s: sürüm 1 ya da büyük olmalı (%d)" % [name, version])
		return false
	if not write.is_valid() or not read.is_valid():
		push_error("[save] %s: write ve read geçerli Callable olmalı" % name)
		return false
	var prev: Dictionary = _defs.get(name, {})
	if not prev.is_empty():
		push_warning("[save] %s bloğu yeniden kaydedildi, sonuncusu geçer" % name)
	var migrate: Variant = opts.get("migrate", {})
	_defs[name] = {
		"name": name, "v": version, "write": write, "read": read,
		"reset": opts.get("reset", Callable()), "check": opts.get("check", Callable()),
		"migrate": migrate if migrate is Dictionary else {},
		"order": int(opts.get("order", DEFAULT_ORDER)),
		"max_bytes": int(opts.get("max_bytes", MAX_BYTES.get(name, 0))),
		"seq": int(prev.get("seq", _seq)),
	}
	if prev.is_empty():
		_seq += 1
	_sort()
	if _carry.has(name):
		var raw: Variant = _carry[name]
		_carry.erase(name)
		var res: Variant = _prepare(_defs[name], raw)
		if res is String:
			push_error("[save] %s (geç kayıt): %s; blok varsayılanına döner" % [name, res])
			if (_defs[name]["reset"] as Callable).is_valid():
				(_defs[name]["reset"] as Callable).call()
		else:
			var ok: Variant = read.call(res)
			if ok is bool and not ok:
				push_error("[save] %s bloğu (geç kayıt) okunamadı" % name)
	return true


## Bloğun kaydını kaldırır; son hâli taşınan bloklara geçer (sistem bırakılsa da kayıtta kalır, yeniden kaydedilince okunur).
func unregister(name: String) -> void:
	if not _defs.has(name):
		return
	var d: Variant = (_defs[name]["write"] as Callable).call() if (_defs[name]["write"] as Callable).is_valid() else null
	if d is Dictionary:
		var block := (d as Dictionary).duplicate(true)
		block["v"] = int(_defs[name]["v"])
		_carry[name] = block
	_defs.erase(name)
	_sort()


func has_block(name: String) -> bool:
	return _defs.has(name)


## Kayıtlı bloklar, okunma sırasıyla.
func names() -> PackedStringArray:
	return PackedStringArray(_order)


## Kayıtlı bloğun sürümü (yoksa 0).
func version_of(name: String) -> int:
	return int((_defs.get(name, {}) as Dictionary).get("v", 0))


## Sahibi olmayan, kayıttan taşınan bloklar (salt okunur kopya).
func carried() -> Dictionary:
	return _carry.duplicate(true)


## Blokları yazar: {ad: {v, ...}}. Taşınan bloklar da girer. Tavanı aşan blok uyarı yazar (kayıt yine yazılır).
func collect() -> Dictionary:
	var out := {}
	for name: String in _carry:
		out[name] = (_carry[name] as Dictionary).duplicate(true)
	for name in _order:
		var def: Dictionary = _defs[name]
		var d: Variant = (def["write"] as Callable).call()
		if not d is Dictionary:
			push_error("[save] %s bloğu sözlük yazmadı (%s)" % [name, type_string(typeof(d))])
			continue
		var block := (d as Dictionary).duplicate(true)
		block["v"] = int(def["v"])
		var cap := int(def["max_bytes"])
		if cap > 0:
			var size := JSON.stringify(block).to_utf8_buffer().size()
			if size > cap:
				push_warning("[save] %s bloğu tavanı aşıyor: %d > %d bayt" % [name, size, cap])
		out[name] = block
	return out


## Kayıttaki blokları okur. Önce bütün kayıtlı blokların göçü ve denetimi yapılır; biri tutmazsa hiçbiri okunmaz. Kayıtta olmayan
## blok varsayılanına döner (reset); sahibi olmayan blok taşınır. Döner: hata ya da "".
func apply(blocks: Variant) -> String:
	var src: Dictionary = {}
	if blocks != null:
		if not blocks is Dictionary:
			return "bloklar sözlük değil"
		src = blocks
	var structural := check_blocks(src)
	if not structural.is_empty():
		return structural
	var prepared := {}
	for name in _order:
		if not src.has(name):
			continue
		var res: Variant = _prepare(_defs[name], src[name])
		if res is String:
			return res
		prepared[name] = res
	_carry.clear()
	for name: Variant in src:
		if not _defs.has(str(name)):
			_carry[str(name)] = (src[name] as Dictionary).duplicate(true)
	for name in _order:
		var def: Dictionary = _defs[name]
		if prepared.has(name):
			var ok: Variant = (def["read"] as Callable).call(prepared[name])
			if ok is bool and not ok:
				return "%s bloğu okunamadı" % name
		elif (def["reset"] as Callable).is_valid():
			(def["reset"] as Callable).call()
	return ""


## Bütün blokları varsayılanına döndürür (yeni yolculuk); taşınan bloklar düşer.
func reset_all() -> void:
	_carry.clear()
	for name in _order:
		var reset: Callable = _defs[name]["reset"]
		if reset.is_valid():
			reset.call()


# --- Durağan denetim (menü, SaveData.is_record) -----------------------------------------------------------

## Kayıttaki blokların yapı denetimi: sözlük, geçerli ad, tamsayı v ≥ 1, sahibin ya da yerleşik denetim. Döner: ilk hata ya da "".
static func check_blocks(blocks: Variant) -> String:
	if blocks == null:
		return ""
	if not blocks is Dictionary:
		return "blocks sözlük değil"
	for name: Variant in blocks:
		var e := check_block(str(name), blocks[name])
		if not e.is_empty():
			return e
	return ""


static func check_block(name: String, d: Variant) -> String:
	if not is_block_name(name):
		return "geçersiz blok adı «%s»" % name
	if not d is Dictionary:
		return "%s bloğu sözlük değil" % name
	var v: Variant = (d as Dictionary).get("v")
	if not _is_int_like(v) or int(v) < 1:
		return "%s bloğunun sürümü (v) yok ya da bozuk" % name
	var owner := _owner_script(name)
	if owner != null:
		var e: Variant = owner.call(VALIDATE_METHOD, d)
		if e is String and not (e as String).is_empty():
			return "%s: %s" % [name, e]
		if e is bool and not e:
			return "%s bloğu bozuk" % name
		return ""
	match name:
		"clock":
			var ce := check_clock(d)
			return "" if ce.is_empty() else "clock: %s" % ce
	return ""


## Saat bloğunun yerleşik denetimi (GameClock.to_dict biçimi {v, day_n, minute, holds}; prototipin dayN'i ve eski Serbest Gez'in day'i
## da okunur, GameClock.load_dict gibi). Döner: hata ya da "".
static func check_clock(d: Dictionary) -> String:
	var dn: Variant = d.get("day_n", d.get("dayN", d.get("day", null)))
	if not _is_int_like(dn) or absf(float(dn)) > 1.0e7:
		return "gün (day_n) yok ya da bozuk"
	var m: Variant = d.get("minute", 0.0)
	if not (m is int or m is float) or not is_finite(float(m)) or float(m) < 0.0 or float(m) > 1440.0:
		return "dakika (minute) 0..1440 değil"
	if d.has("holds") and not d["holds"] is Array:
		return "bekleyişler (holds) dizi değil"
	return ""


## Blok adı kuralı: küçük harfle başlar; küçük harf, rakam, alt çizgi.
static func is_block_name(name: String) -> bool:
	if name.is_empty() or not (name[0] >= "a" and name[0] <= "z"):
		return false
	for ch in name:
		if not ((ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") or ch == "_"):
			return false
	return true


# --- İç -----------------------------------------------------------------------------------------------------

## Göç ve denetim (kopya üstünde). Döner: hazır sözlük ya da hata (String).
func _prepare(def: Dictionary, raw: Variant) -> Variant:
	var name := str(def["name"])
	var d := (raw as Dictionary).duplicate(true)
	var from := int(d.get("v", 1))
	var to := int(def["v"])
	if from > to:
		return "%s bloğu v%d, bu sürüm v%d'e dek okur" % [name, from, to]
	var steps: Dictionary = def["migrate"]
	for n in range(from, to):
		var step: Variant = steps.get(n)
		if step is Callable and (step as Callable).is_valid():
			var next: Variant = (step as Callable).call(d)
			if next is Dictionary:
				d = next
			elif next != null:
				return "%s bloğunun %d → %d göçü bozuk" % [name, n, n + 1]
		else:
			push_warning("[save] %s: migrate[%d] yok, veri olduğu gibi okunur" % [name, n])
	d["v"] = to
	var check: Callable = def["check"]
	if check.is_valid():
		var e: Variant = check.call(d)
		if e is String and not (e as String).is_empty():
			return "%s: %s" % [name, e]
		if e is bool and not e:
			return "%s bloğu bozuk" % name
	return d


func _sort() -> void:
	_order.clear()
	for name: String in _defs:
		_order.append(name)
	_order.sort_custom(func(a: String, b: String) -> bool:
		var da: Dictionary = _defs[a]
		var db: Dictionary = _defs[b]
		if int(da["order"]) != int(db["order"]):
			return int(da["order"]) < int(db["order"])
		return int(da["seq"]) < int(db["seq"]))


## Bloğun sahibi sınıfın betiği, durağan denetimi varsa (yoksa null; önbellekli).
static func _owner_script(name: String) -> Script:
	var cls := str(OWNERS.get(name, ""))
	if cls.is_empty():
		return null
	if _owner_scripts.has(cls):
		return _owner_scripts[cls]
	var found: Script = null
	for info: Dictionary in ProjectSettings.get_global_class_list():
		if str(info.get("class", "")) != cls:
			continue
		var script := load(str(info.get("path", ""))) as Script
		if script:
			for m: Dictionary in script.get_script_method_list():
				if StringName(str(m.get("name", ""))) == VALIDATE_METHOD and (int(m.get("flags", 0)) & METHOD_FLAG_STATIC) != 0:
					found = script
					break
		break
	_owner_scripts[cls] = found
	return found


static func _is_int_like(v: Variant) -> bool:
	if v is int:
		return true
	return v is float and is_finite(v) and float(v) == floorf(v)
