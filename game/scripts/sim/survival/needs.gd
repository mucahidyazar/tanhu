class_name Needs
extends RefCounted
## Tokluk / Fullness (saf; economy.md §5.1–§5.3, §5.6; time.md §10.5; godot.md §3 «Ateş ve av»): oyun dakikasıyla (K20) uyanıkken
## −5 / oyun saati × zorluğun foodK'si, ateş başında dinlenirken ×0,5, uykuda ×0,25, Son Gece ×1,2. Üşüme yoktur (K1): tek ihtiyaç
## Tokluk'tur. Açlık öldürmez ve oyunu durdurmaz: Umay Eşiği yalnız Can bitince gelir (Wounds). Serbest Gez'de Tokluk yoktur (enabled
## false: update bir şey yapmaz). Prototipin src/game/needs.js'inin taşınmasıdır, altın değerlerle sınanır (tests/fixtures/needs.json;
## birikimli benzetim 1e-6).
##   var n := Needs.new({"diff": "normal"})
##   n.update(60.0)                      # bir oyun saati uyanık: −5
##   n.update(480.0, {"sleep": true})   # 8 saat uyku: −10
##   n.eat("meal", 3)                    # Aş ★3: +46 (35 × 1,3, yuvarlanır)
##   n.band()                            # "sated" | "ok" | "hungry" | "spent"
##   n.effects()                         # bandın çarpanları (staRegen, run, hpRegen, runCost, windExempt)

## Bant değişti (yüklemede yayılmaz).
signal band_changed(band: String)
## Tokluk değişti (HUD).
signal changed

const DATA_PATH := "res://data/survival/needs.json"
const EPS := 1e-9
## Ateş başında hemen yenen yemeğin yıldızı (survival.md §3): ★1 ×0,75, ★2 ×1, ★3 ×1,3; Heybe'ye giren yemek olağandır (★2).
const QUALITY_K := {1: 0.75, 2: 1.0, 3: 1.3}

static var _data: Dictionary = {}

## Eşya tablosu: Callable(id) → satır ya da {id: satır}; verilmezse ItemCatalog (data/economy/items.json; food: {fullness, buff}).
var items: Variant = null
## Zorluk: kimlik ("story", "normal", "hard"), satır ({fullness | foodK}) ya da onu döndüren Callable.
var diff: Variant = "normal"
## Beceri değeri: Callable(anahtar, varsayılan) → sayı (Progression.mod; mealFull ×1,5 Ocak Bilgisi, fullnessDecay ×0,85 Kurutma Sırığı).
var mod: Callable
## Son Gece kilidi açık mı: Callable() → bool.
var last_night: Callable
## Serbest Gez'de Tokluk yoktur.
var enabled := true
var fullness := 60.0

var _band := "ok"


## opts: items, diff, mod, last_night, enabled, fullness (anahtar adları prototipinkilerdir).
func _init(opts: Dictionary = {}) -> void:
	items = opts.get("items", null)
	diff = opts.get("diff", "normal")
	if opts.get("mod") is Callable:
		mod = opts["mod"]
	if opts.get("last_night") is Callable:
		last_night = opts["last_night"]
	enabled = bool(opts.get("enabled", true))
	fullness = _clamp(float(opts.get("fullness", start_value())))
	_band = Needs.band_of(fullness)


# --- Tablo ------------------------------------------------------------------------------------------

static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)) if FileAccess.file_exists(DATA_PATH) else null
		_data = parsed if parsed is Dictionary else {}
	return _data


static func reset_cache() -> void:
	_data = {}


## Tokluk tablosunun değeri (data/survival/needs.json «fullness»; yoksa prototipin FULLNESS'i).
static func value(key: String) -> float:
	var defaults := {"max": 100.0, "start": 60.0, "per_hour": 5.0, "rest": 0.5, "sleep": 0.25, "last_night": 1.2, "sated": 75.0, "hungry": 25.0}
	var row: Variant = data().get("fullness", {})
	return float((row as Dictionary).get(key, defaults.get(key, 0.0))) if row is Dictionary else float(defaults.get(key, 0.0))


static func start_value() -> float:
	return value("start")


## Bant (§5.3): «spent» 0, «hungry» <25, «sated» ≥75, «ok» arası.
static func band_of(p_fullness: float) -> String:
	if not (p_fullness > EPS):
		return "spent"
	if p_fullness < value("hungry"):
		return "hungry"
	return "sated" if p_fullness >= value("sated") else "ok"


## Bandın çarpanları (needs.json «bands»; ad alanı düşer): staRegen dolum, run koşu hızı, hpRegen Can dolumu, runCost koşu gideri,
## windExempt (Soluk bu değerde ve üstünde aç dolum cezası yok).
static func band_effects(band_id: String) -> Dictionary:
	var bands: Variant = data().get("bands", {})
	var row: Variant = (bands as Dictionary).get(band_id, {}) if bands is Dictionary else {}
	var out := {}
	if row is Dictionary:
		for k: Variant in row:
			if str(k) != "name":
				out[str(k)] = row[k]
	return out


## Bandın adı («Tok», «Aç», «Bitkin»; orta bandın adı yoktur).
static func band_name(band_id: String, lang := "tr") -> String:
	var bands: Variant = data().get("bands", {})
	var row: Variant = (bands as Dictionary).get(band_id, {}) if bands is Dictionary else {}
	return Catalog.pick((row as Dictionary).get("name", ""), lang) if row is Dictionary and (row as Dictionary).has("name") else ""


## Zorluğun Tokluk çarpanı (difficulty.json «fullness»; prototipte foodK).
static func food_k(p_diff: Variant) -> float:
	var v: Variant = (p_diff as Callable).call() if p_diff is Callable else p_diff
	var row: Dictionary = {}
	if v is Dictionary:
		row = v
	else:
		row = Needs.difficulty_row(str(v) if v != null else "normal")
	return float(row.get("foodK", row.get("fullness", 1.0)))


## Zorluk satırı (data/character/difficulty.json; bilinmeyen kimlik Normal).
static func difficulty_row(id: String) -> Dictionary:
	var levels: Variant = Catalog.data("character/difficulty")
	var normal := {}
	if levels is Dictionary:
		for row: Variant in (levels as Dictionary).get("levels", []):
			if row is Dictionary:
				if str((row as Dictionary).get("id", "")) == id:
					return row
				if str((row as Dictionary).get("id", "")) == "normal":
					normal = row
	if normal.is_empty():
		return {"id": "normal", "fullness": 1.0, "woundLimit": 3, "fallCost": 1}
	return normal


# --- Durum ------------------------------------------------------------------------------------------

## Oyun dakikası başına Tokluk kaybı. opts: sleep, rest, last_night (yoksa last_night Callable'ı).
func rate(opts: Dictionary = {}) -> float:
	var last: bool = bool(opts["last_night"]) if opts.get("last_night") != null else (last_night.is_valid() and bool(last_night.call()))
	var k := value("sleep") if bool(opts.get("sleep", false)) else (value("rest") if bool(opts.get("rest", false)) else (value("last_night") if last else 1.0))
	return (value("per_hour") / 60.0) * k * Needs.food_k(diff) * _mod("fullnessDecay", 1.0)


## dt_min: geçen oyun dakikası (kare, saat ya da atlama; çalışma atlaması uyanık orandır). Kapalıyken ve sıfırdayken bir şey yapmaz.
func update(dt_min: float, opts: Dictionary = {}) -> float:
	if not enabled or not (dt_min > 0.0) or fullness <= 0.0:
		return fullness
	_store(fullness - dt_min * rate(opts))
	return fullness


## Yemek: kazanılan Tokluk (tavanla kırpılmış). Aş'ı Ocak Bilgisi ×1,5 doyurur (mealFull); quality ateş başında hemen yenince.
## share: Ocağa Pay'la pişen yemek (Tokluk ×0,9; survival.md §2.5). Süreli etkiler pişirmenin ve oyuncunun işidir.
func eat(item_id: String, quality: int = 2, share: bool = false) -> float:
	var id := ItemCatalog.base_id(item_id) if not item_id.is_empty() else item_id
	var full := Needs.fullness_of(id, items)
	if not (full > 0.0):
		return 0.0
	var k := float(QUALITY_K.get(quality, 1.0)) * (_mod("mealFull", 1.0) if id == "meal" else 1.0)
	if share:
		k *= Needs.share_k()
	return add(float(Needs.js_round(full * k)))


## Ocağa Pay'ın Tokluk çarpanı (recipes.json share_fullness_k; 0,9).
static func share_k() -> float:
	var r: Variant = Catalog.data("survival/recipes")
	return float((r as Dictionary).get("share_fullness_k", 0.9)) if r is Dictionary else 0.9


## Eşyanın Tokluk'u (satırın food.fullness'ı; yoksa 0).
static func fullness_of(item_id: String, table: Variant = null) -> float:
	var row: Variant = null
	if table is Callable:
		row = (table as Callable).call(item_id)
	elif table is Dictionary:
		row = (table as Dictionary).get(item_id)
	else:
		row = ItemCatalog.row(item_id)
	if not row is Dictionary:
		return 0.0
	var food: Variant = (row as Dictionary).get("food")
	if not food is Dictionary:
		return 0.0
	var f: Variant = (food as Dictionary).get("fullness")
	return float(f) if (f is float or f is int) else 0.0


## Doğrudan Tokluk (Umay Eşiği'nin uyanışı, görev): gerçek değişim.
func add(n: float) -> float:
	if not is_finite(n) or n == 0.0:
		return 0.0
	var prev := fullness
	_store(prev + n)
	return fullness - prev


## Yalnız Tokluk vardır.
func band() -> String:
	return _band


func effects() -> Dictionary:
	return Needs.band_effects(_band)


## 0..1 (HUD).
func ratio() -> float:
	return clampf(fullness / maxf(value("max"), EPS), 0.0, 1.0)


## Kayıt (survival bloğunun «needs» alanı): {fullness} iki ondalık.
func to_dict() -> Dictionary:
	return {"fullness": Needs.js_round(fullness * 100.0) / 100.0}


## Yüklemede olay yayılmaz.
func from_dict(d: Variant) -> void:
	var f: Variant = (d as Dictionary).get("fullness") if d is Dictionary else null
	fullness = _clamp(float(f) if (f is float or f is int) and is_finite(float(f)) else start_value())
	_band = Needs.band_of(fullness)
	changed.emit()


## JavaScript'in Math.round'u (yarım yukarı: −2,5 → −2), prototiple bit bit aynı yuvarlama için.
static func js_round(v: float) -> float:
	return floorf(v + 0.5)


func _mod(key: String, def: float) -> float:
	if mod.is_valid():
		var v: Variant = mod.call(key, def)
		if (v is float or v is int) and is_finite(float(v)):
			return float(v)
	return def


func _clamp(v: float) -> float:
	return clampf(v, 0.0, value("max"))


func _store(v: float) -> void:
	fullness = _clamp(Needs.js_round(v * 1e6) / 1e6)
	changed.emit()
	var b := Needs.band_of(fullness)
	if b == _band:
		return
	_band = b
	band_changed.emit(b)
