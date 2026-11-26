class_name Cooking
extends RefCounted
## Ateş başında pişirme (saf; survival.md §3, economy.md §5.2, §5.5; weather.md §8.5). Tarif ve istasyon data/survival/recipes.json'dadır,
## Tokluk ve süreli etki çıktının items.json food satırındadır. İstasyon ateşin evresinden gelir: şiş ve kazan Küçük, Orta ve Büyük
## evrede, kor yalnız Kor evresinde; kazan taş halkası ve küçük kazan (pot) ya da Eski Ocak ister. Süre: tarifin saniyesi × evrenin
## cook_k'si (Küçük ×1,2, Orta ×1, Büyük ×0,8) × havanın çarpanı (+ kazanda Dolu Tulum yoksa 5 sn). Şiş ve kor zamanlıdır (Tam Vuruş):
## halka süre dolunca kapanır, pencerede basış ★3, geç basış ★1, çok geç (ya da hiç) Yanık; Kor evresinde kalite güvenlidir (yanmaz,
## ★1 kalır); Büyük evrede şiş %30 hızlı yanar. Kazan zamanlama istemez: ★2, Ocak Bilgisi ★3. Toz fırtınası kaliteyi bir yıldız düşürür.
##   var j := Cooking.Job.make("spit_meat", {"meat": 1}, 12.0, true, false, 1.0)
##   j.tick(12.1)          # süre doldu: halka kapanıyor (-2: sürüyor)
##   j.press()             # 3 (★3), 1, 0 (Yanık) ya da -1 (henüz pişmedi)

const DATA_PATH := "res://data/survival/recipes.json"
## Yanık (Tokluk +5) ve kalite kodları.
const BURNT := "burnt"
const Q_BURNT := 0
const Q_EARLY := -1
const Q_PENDING := -2

static var _data: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)) if FileAccess.file_exists(DATA_PATH) else null
		_data = parsed if parsed is Dictionary else {}
	return _data


static func reset_cache() -> void:
	_data = {}


static func recipes() -> Array:
	return data().get("recipes", []) as Array


static func recipe(recipe_id: String) -> Dictionary:
	for r: Dictionary in recipes():
		if str(r.get("id", "")) == recipe_id:
			return r
	return {}


## Başta bilinen tarifler.
static func start_known() -> PackedStringArray:
	var out := PackedStringArray()
	for r: Dictionary in recipes():
		if bool(r.get("start", false)):
			out.append(str(r["id"]))
	return out


## Ateşin istasyonu mu (rack ve skin_bag değildir)?
static func is_fire_station(station: String) -> bool:
	var row: Variant = (data().get("stations", {}) as Dictionary).get(station)
	return row is Dictionary and bool((row as Dictionary).get("fire", false))


static func station_name(station: String, lang := "tr") -> String:
	var row: Variant = (data().get("stations", {}) as Dictionary).get(station)
	return Catalog.pick((row as Dictionary).get("name", station), lang) if row is Dictionary else station


## Ateşte o an kullanılabilen istasyonlar (saf): evrenin cook listesi; kazan taş halkası ve küçük kazan ya da Eski Ocak ister.
static func stations_for(fire: FireState, has_pot: bool) -> PackedStringArray:
	var out := PackedStringArray()
	if fire == null or not fire.is_lit():
		return out
	for s: Variant in fire.stage_row().get("cook", []):
		var station := str(s)
		if station == "cauldron" and not (fire.stones and (has_pot or fire.old)):
			continue
		out.append(station)
	return out


## Havanın istasyon çarpanı (saf): o havada pişmiyorsa −1.
static func weather_k(station: String, weather_type: String) -> float:
	var row: Variant = (data().get("weather_cook", {}) as Dictionary).get(weather_type)
	if not row is Dictionary:
		return 1.0
	var r := row as Dictionary
	for key: String in [station, "all"]:
		if not r.has(key):
			continue
		var v: Variant = r[key]
		if v is String and str(v) == "none":
			return -1.0
		if key == station:
			# İstasyonun kendi satırı "all"un yerine geçer (yağmurda kor ×1,5, öteki ×1,2).
			return float(v)
	return float(r.get("all", 1.0)) if (r.get("all") is float or r.get("all") is int) else 1.0


## Havanın kalite düşüşü (toz fırtınası: 1).
static func quality_drop(weather_type: String) -> int:
	var row: Variant = (data().get("weather_cook", {}) as Dictionary).get(weather_type)
	return int((row as Dictionary).get("quality_drop", 0)) if row is Dictionary else 0


## Tarifin girdisi: ilk tutan seçenek ({ref: adet}); counter: Callable(ref) → adet (Inventory.count). Hiçbiri tutmazsa boş.
static func pick_inputs(rec: Dictionary, counter: Callable) -> Dictionary:
	var options: Array = [rec.get("in", {})]
	options.append_array(rec.get("alt", []))
	for opt: Variant in options:
		if not opt is Dictionary:
			continue
		var ok := true
		for ref: String in opt:
			if int(counter.call(ref)) < int(opt[ref]):
				ok = false
				break
		if ok:
			return (opt as Dictionary).duplicate()
	return {}


## Ana girdinin eksikleri: {ref: eksik adet}.
static func missing(rec: Dictionary, counter: Callable) -> Dictionary:
	var out := {}
	var main: Dictionary = rec.get("in", {})
	for ref: String in main:
		var lack := int(main[ref]) - int(counter.call(ref))
		if lack > 0:
			out[ref] = lack
	return out


## Pişme süresi (sn; saf): tarif × evre × hava (+ suyu yoksa kazanda water_extra_s). Pişmiyorsa −1.
static func seconds_for(rec: Dictionary, stage_row: Dictionary, weather_type: String, has_water: bool) -> float:
	var station := str(rec.get("station", ""))
	var wk := Cooking.weather_k(station, weather_type)
	if wk < 0.0:
		return -1.0
	var t := float(rec.get("seconds", 0.0)) * float(stage_row.get("cook_k", 1.0)) * wk
	if bool(rec.get("water", false)) and not has_water:
		t += float(data().get("water_extra_s", 5.0))
	return t


## Şişin yanma hızı (Büyük evrede ×1,3; yalnız şiş).
static func burn_k(station: String, stage_row: Dictionary) -> float:
	return float(stage_row.get("spit_burn_k", 1.0)) if station == "spit" else 1.0


## Zamanlı pişirmenin hükmü (saf). t: geçen, T: halkanın kapandığı an. Döner: 3 (★3), 1 (★1), 0 (Yanık), −1 (henüz pişmedi).
## safe: Kor'un güvenli kalitesi (yanmaz: çok geç de ★1).
static func judge(t: float, T: float, burn: float = 1.0, safe: bool = false) -> int:
	var half := float(data().get("perfect_s", 0.5)) * 0.5
	var late := float(data().get("late_s", 2.5)) / maxf(burn, 0.01)
	if t < T - half - 1e-9:
		return Q_EARLY
	if t <= T + half + 1e-9:
		return 3
	if t <= T + half + late + 1e-9 or safe:
		return 1
	return Q_BURNT


## Halkanın kendiliğinden kapandığı an (basılmazsa Yanık ya da güvenli ★1): T + pencere yarısı + geç payı.
static func burn_at(T: float, burn: float = 1.0) -> float:
	return T + float(data().get("perfect_s", 0.5)) * 0.5 + float(data().get("late_s", 2.5)) / maxf(burn, 0.01)


## Kalitenin etki çarpanı (★1 ×0,75, ★2 ×1, ★3 ×1,3).
static func quality_k(quality: int) -> float:
	return float((data().get("quality_k", {}) as Dictionary).get(str(quality), 1.0))


## Yıldız yazısı.
static func stars(quality: int) -> String:
	return "★".repeat(clampi(quality, 0, 3)) if quality > 0 else ""


static func text(key: String, lang := "tr", args: Dictionary = {}) -> String:
	var t: Variant = (data().get("text", {}) as Dictionary).get(key)
	var s := Catalog.pick(t, lang) if t != null else key
	for k: String in args:
		s = s.replace("{%s}" % k, str(args[k]))
	return s


## Bir pişirme işi (ateş başında oturan Mete): girdi alındı, süre işler; zamanlıda halka kapanınca basış beklenir.
class Job:
	extends RefCounted

	var recipe_id := ""
	## Çıktı (Yanık'ta «burnt»).
	var out := ""
	## Alınan girdi (yarıda bırakılınca geri döner).
	var inputs: Dictionary = {}
	var T := 1.0
	var t := 0.0
	var timed := false
	var safe := false
	var burn := 1.0
	## Ocağa Pay'la mı (Tokluk ×0,9; ateşin günü).
	var share := false
	var fire_id := ""
	## Hüküm: −2 sürüyor, 0 Yanık, 1–3 yıldız.
	var quality := Cooking.Q_PENDING
	## Kazanda Ocak Bilgisi (★3) ve havanın kalite düşüşü.
	var bonus := 0
	var drop := 0

	static func make(p_recipe: String, p_inputs: Dictionary, p_T: float, p_timed: bool, p_safe: bool, p_burn: float) -> Job:
		var j := Job.new()
		j.recipe_id = p_recipe
		j.out = p_recipe
		j.inputs = p_inputs.duplicate()
		j.T = maxf(p_T, 0.01)
		j.timed = p_timed
		j.safe = p_safe
		j.burn = p_burn
		return j

	func is_done() -> bool:
		return quality != Cooking.Q_PENDING

	## 0..1 (halkanın kapanışı).
	func progress() -> float:
		return clampf(t / T, 0.0, 1.0)

	## Halka açık mı (zamanlı ve süre doldu)?
	func ring_open() -> bool:
		return timed and not is_done() and t >= T - float(Cooking.data().get("perfect_s", 0.5)) * 0.5

	## Zaman ilerler (sn). Döner: bu adımda hükme varıldıysa kalite, yoksa −2.
	func tick(sec: float) -> int:
		if is_done() or sec <= 0.0:
			return Cooking.Q_PENDING
		t += sec
		if not timed:
			if t >= T:
				return _resolve(2 + bonus)
			return Cooking.Q_PENDING
		if t > Cooking.burn_at(T, burn) + 1e-9:
			return _resolve(1 if safe else Cooking.Q_BURNT)
		return Cooking.Q_PENDING

	## Basış (E): zamanlıda hüküm (erken basış −1 döner, iş sürer). Zamansızda bir şey yapmaz (−2).
	func press() -> int:
		if is_done() or not timed:
			return Cooking.Q_PENDING
		var q := Cooking.judge(t, T, burn, safe)
		if q == Cooking.Q_EARLY:
			return q
		return _resolve(q)

	func _resolve(q: int) -> int:
		var final := q
		if q > 0:
			final = clampi(q - drop, 1, 3)
		quality = final
		if final == Cooking.Q_BURNT:
			out = Cooking.BURNT
		return final
