class_name FireState
extends RefCounted
## Bir kamp ateşi (saf; survival.md §2, K35, K45; weather.md §8.5; godot.md §3 «Ateş ve av»): yakıt, evre, sönme, çukur, küllenme ve
## Ocağa Pay. Görünüşü FireView'dir (scripts/camp/fire_view.gd); kümesi FireSet, sahibi Survival'dır. Kurallar data/survival/fire.json.
##
## Yakıt gerçek saniyedir, en çok 720 (fuel_max_s). Ateş yakıtını oyun dakikası × 2,5 ile yer (advance'in fuel_s'i): olağan akışta bu
## gerçek saniyedir, atlamada atlanan dakikadır, saat durunca ateş de durur. Tüketim çarpanı: taş halkası üçte iki (stone_burn) × havanın
## çarpanı (WeatherFx: taşlı fire_ring, taşsız fire_k) × Ocağa Pay'ın günü (share_fuel_k). Taşsız ateş, havanın fire_out_s'i varken
## (fırtına, tipi, toz 40 sn; sağanak, dolu 60 sn) o kadar saniye açıkta kalınca söner. Evre yakıttan okunur: Kor <60, Küçük <240,
## Orta <480, Büyük. Sönen ateş çukurdur (pit): ışık ve duman yok; kalkışı FireSet'in işidir (24 oyun saati, 30 m erteleme). Küle Yatır
## yalnız Kor'da (bank): ışık 0, yakıt durur, köz ertesi doğuştan 1 oyun saati sonrasına dek yaşar, sonra olağan çukurdur ve çukurun 24
## saati o andan sayılır. Eski Ocak (old) taşlıdır, çukuru kalıcıdır.
##   var f := FireState.new()
##   f.light(Vector2(8, 0), "testmap", true, 720.0, now)   # taş halkalı, dolu
##   f.advance(150.0, now + 60.0, fx, day)                 # bir oyun saati
##   f.stage()                                             # &"blaze" | &"steady" | &"small" | &"embers" | &""
##   f.add_fuel(180.0)                                     # {added, full}
##   f.bank(until_abs)                                     # Kor'da Küle Yatır

## Evre değişti (görünüm), durum değişti (lit, banked, pit; reason: fuel, weather, doused, banked, bank_end, lit, woke, relit).
signal stage_changed(stage: StringName)
signal state_changed(state: StringName, reason: StringName)

const DATA_PATH := "res://data/survival/fire.json"
const LIT := &"lit"
const BANKED := &"banked"
const PIT := &"pit"
const STATES: Array[StringName] = [LIT, BANKED, PIT]
const EPS := 1e-9

static var _rules: Dictionary = {}

## Zonda tekil kimlik (FireSet verir), zon (harita kimliği) ve yer (x, z; metre).
var id := ""
var zone := ""
var x := 0.0
var z := 0.0
## Yakıt (sn) ve taş halkası.
var fuel := 0.0
var stones := false
var state: StringName = PIT
## Sönüşün ya da küllenmenin anı (mutlak oyun dakikası; day_n × 1.440 + dk). Yanarken NAN.
var out_at := NAN
## Küllenmiş közün öleceği an (mutlak dk; NAN değilse).
var bank_until := NAN
## Eski Ocak: haritanın taş halkası ve kalıcı çukuru (sayıya girmez, silinmez).
var old := false
## Yerleşimin ocağı (deneme haritasının ortasındaki ateş; görünüşü sahnenin kendi ateşidir): halk besler, yakıtı azalmaz; oyuncu
## beslemez, söndürmez, küle yatırmaz; kayda girmez (katman her girişte kurar). Başında pişirilir ve dinlenilir. Eski Ocak gibi
## sayıya girmez ve silinmez (old da doğrudur).
var hearth := false
## Kuruluş anı (mutlak dk): zonda en eskisi silinir.
var born := 0.0
## Ocağa Pay'ın verildiği gün (day_n; −1 yok).
var share_day := -1
## Taşsız ateşin söndüren havada geçirdiği süre (sn).
var exposure := 0.0

var _stage: StringName = &""


# --- Kurallar ---------------------------------------------------------------------------------------------

## data/survival/fire.json (bir kez okunur).
static func rules() -> Dictionary:
	if _rules.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH)) if FileAccess.file_exists(DATA_PATH) else null
		_rules = parsed if parsed is Dictionary else {}
	return _rules


static func reset_cache() -> void:
	_rules = {}


static func rule(key: String, def: Variant = null) -> Variant:
	return rules().get(key, def)


static func fuel_max() -> float:
	return float(rule("fuel_max_s", 720.0))


## Bir oyun dakikasının yakıt saniyesi (2,5).
static func minute_s() -> float:
	return float(rule("game_minute_s", 2.5))


## Evre satırları, from'a göre artan.
static func stages() -> Array:
	var out: Array = (rule("stages", []) as Array).duplicate()
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.get("from", 0.0)) < float(b.get("from", 0.0)))
	return out


## Yakıtın evresi (saf): yanmayan ateşin evresi yoktur.
static func stage_of(p_fuel: float) -> StringName:
	var out: StringName = &""
	for row: Dictionary in stages():
		var from := float(row.get("from", 0.0))
		if (p_fuel > from + EPS) if bool(row.get("above", false)) else (p_fuel >= from - EPS):
			out = StringName(str(row.get("id", "")))
	return out


static func stage_row_of(stage_id: StringName) -> Dictionary:
	for row: Dictionary in stages():
		if StringName(str(row.get("id", ""))) == stage_id:
			return row
	return {}


## Yakıt türleri, Yük verimi sırasıyla: [{id, refs, seconds, name}].
static func fuels() -> Array:
	return rule("fuels", []) as Array


static func fuel_row(fuel_id: String) -> Dictionary:
	for row: Dictionary in fuels():
		if str(row.get("id", "")) == fuel_id:
			return row
	return {}


static func fuel_seconds(fuel_id: String) -> float:
	return float(fuel_row(fuel_id).get("seconds", 0.0))


## Oyuncunun metni (fire.json «text»).
static func text(key: String, lang := "tr", args: Dictionary = {}) -> String:
	var t: Variant = (rule("text", {}) as Dictionary).get(key)
	var s := Catalog.pick(t, lang) if t != null else key
	for k: String in args:
		s = s.replace("{%s}" % k, str(args[k]))
	return s


## Havanın tüketim çarpanı (saf). fx: WeatherFx ya da {fire_k, fire_ring, fire_out_s} (null: açık hava ×1).
static func weather_k(p_stones: bool, fx: Variant) -> float:
	if fx == null:
		return 1.0
	if p_stones:
		return maxf(_fx(fx, "fire_ring", 1.0), 0.0)
	return 1.0 if _fx(fx, "fire_out_s", 0.0) > 0.0 else maxf(_fx(fx, "fire_k", 1.0), 0.0)


## Taşsız ateşi söndüren havanın süresi (sn; 0 söndürmez).
static func weather_out_s(p_stones: bool, fx: Variant) -> float:
	return 0.0 if p_stones or fx == null else _fx(fx, "fire_out_s", 0.0)


static func _fx(fx: Variant, key: String, def: float) -> float:
	var v: Variant = (fx as Dictionary).get(key, def) if fx is Dictionary else (fx as Object).get(key) if fx is Object else def
	return float(v) if (v is float or v is int) else def


# --- Durum ----------------------------------------------------------------------------------------------

## Yakar: yeni ateş, yeniden yakılan çukur ya da Eski Ocak. fuel en çok fuel_max'tır.
func light(at: Vector2, p_zone: String, p_stones: bool, p_fuel: float, now_abs: float) -> void:
	x = at.x
	z = at.y
	zone = p_zone
	stones = p_stones or old
	born = now_abs
	_relight(p_fuel, &"lit")


## Çukuru (ya da Eski Ocak'ı) yeniden yakar: kav istemez (yakıcıyı çağıran denetler).
func relight(p_fuel: float) -> void:
	_relight(p_fuel, &"relit")


func _relight(p_fuel: float, reason: StringName) -> void:
	fuel = clampf(p_fuel, 0.0, fuel_max())
	exposure = 0.0
	out_at = NAN
	bank_until = NAN
	_set_state(LIT, reason)
	_refresh_stage()


func is_lit() -> bool:
	return state == LIT


func is_banked() -> bool:
	return state == BANKED


func is_pit() -> bool:
	return state == PIT


## Evre (yalnız yanarken).
func stage() -> StringName:
	return _stage if state == LIT else &""


func stage_row() -> Dictionary:
	return FireState.stage_row_of(stage())


## Işığın yarıçapı (m): küllenmiş köz ve çukur 0.
func light_m() -> float:
	return float(stage_row().get("light_m", 0.0)) if state == LIT else 0.0


## Kalan yanma (sn, havasız): yakıt / tüketim.
func burn_left(fx: Variant = null, day: int = -1) -> float:
	return fuel / maxf(burn_rate(fx, day), EPS) if state == LIT else 0.0


## Yakıt saniyesi başına tüketim (saf hesap): taş × hava × Ocağa Pay.
func burn_rate(fx: Variant = null, day: int = -1) -> float:
	var k := float(rule("stone_burn", 2.0 / 3.0)) if stones else 1.0
	k *= FireState.weather_k(stones, fx)
	if day >= 0 and share_day == day:
		k *= float(rule("share_fuel_k", 0.9))
	return k


## Zaman ilerler. fuel_s: geçen yakıt saniyesi (oyun dakikası × 2,5); now_abs: şimdiki mutlak dakika (adımın sonu); fx: hava (null açık);
## day: bugünün day_n'i (Ocağa Pay). Döner: olaylar {out: bool, reason, at} (sönmediyse boş).
func advance(fuel_s: float, now_abs: float, fx: Variant = null, day: int = -1) -> Dictionary:
	if fuel_s <= 0.0 or hearth:
		return {}
	match state:
		LIT:
			var rate := burn_rate(fx, day)
			var out_s := FireState.weather_out_s(stones, fx)
			var need_s := fuel / maxf(rate, EPS)
			var reason: StringName = &""
			var spent_s := fuel_s
			if out_s > 0.0 and exposure + fuel_s >= out_s and out_s - exposure < need_s:
				# Hava yakıttan önce söndürür.
				spent_s = maxf(out_s - exposure, 0.0)
				reason = &"weather"
			elif fuel_s >= need_s:
				spent_s = need_s
				reason = &"fuel"
			if out_s > 0.0:
				exposure += spent_s
			else:
				exposure = 0.0
			fuel = maxf(fuel - spent_s * rate, 0.0)
			if reason != &"":
				# Sönen ateşin kalanı (ıslanan ya da biten yakıt) çukurda sayılmaz: yeniden yakmak yeni yakıt ister.
				fuel = 0.0
				out_at = now_abs - (fuel_s - spent_s) / minute_s()
				_set_state(PIT, reason)
				_refresh_stage()
				return {"out": true, "reason": reason, "at": out_at}
			_refresh_stage()
		BANKED:
			if is_finite(bank_until) and now_abs >= bank_until - EPS:
				out_at = bank_until
				bank_until = NAN
				_set_state(PIT, &"bank_end")
				return {"out": true, "reason": &"bank_end", "at": out_at}
	return {}


## Yakıt ekler: yalnız sığan kısmı sayılır (malzemeyi çağıran düşer). Doluysa bir şey eklenmez (full). Döner: {added, full}.
func add_fuel(seconds: float) -> Dictionary:
	if state != LIT or hearth:
		return {"added": 0.0, "full": hearth}
	var room := fuel_max() - fuel
	if room <= EPS:
		return {"added": 0.0, "full": true}
	var fit := clampf(seconds, 0.0, room)
	fuel += fit
	_refresh_stage()
	return {"added": fit, "full": false}


## Ateş dolu mu (Y «Ateş dolu.» yazar, malzeme gitmez)?
func is_full() -> bool:
	return state == LIT and fuel >= fuel_max() - EPS


## Küle Yatır (yalnız Kor): ışık ve duman yok, yakıt durur; until_abs ertesi doğuş + 1 oyun saati. Döner: yapıldı mı.
func bank(until_abs: float, now_abs: float) -> bool:
	if hearth or state != LIT or stage() != &"embers":
		return false
	bank_until = until_abs
	out_at = now_abs
	_set_state(BANKED, &"banked")
	return true


## Közü uyandırır (Y): 1 yakıt kav ve yakıcı istemeden yakar.
func wake(seconds: float) -> bool:
	if state != BANKED:
		return false
	fuel = clampf(fuel + seconds, 0.0, fuel_max())
	bank_until = NAN
	out_at = NAN
	exposure = 0.0
	_set_state(LIT, &"woke")
	_refresh_stage()
	return true


## Söndürür (F basılı 1 sn; Küçük, Orta, Büyük; su ya da karı çağıran denetler): çukur kalır, ıslanan yakıt gider.
func douse(now_abs: float) -> bool:
	if hearth or state != LIT or stage() == &"embers":
		return false
	fuel = 0.0
	out_at = now_abs
	exposure = 0.0
	_set_state(PIT, &"doused")
	_refresh_stage()
	return true


## Ocağa Pay verilebilir mi (ateş başına günde bir)?
func can_share(day: int) -> bool:
	return state == LIT and share_day != day


func give_share(day: int) -> bool:
	if not can_share(day):
		return false
	share_day = day
	return true


## Çukurun kalkma anı (mutlak dk; Eski Ocak ve yanan ateşte INF).
func pit_expires_at() -> float:
	if old or state != PIT or not is_finite(out_at):
		return INF
	return out_at + float(rule("pit_life_min", 1440.0))


func xz() -> Vector2:
	return Vector2(x, z)


# --- Kayıt ----------------------------------------------------------------------------------------------

## survival.fires'ın satırı (survival.md §2.8): {zone, x, z, fuel, stones, state, out_at} ve id, old, until, share, born, exposure.
func to_dict() -> Dictionary:
	return {"id": id, "zone": zone, "x": x, "z": z, "fuel": fuel, "stones": stones, "state": String(state),
		"out_at": out_at if is_finite(out_at) else null, "until": bank_until if is_finite(bank_until) else null, "old": old,
		"share": share_day, "born": born, "exposure": exposure}


## Satırdan ateş (bozuksa null).
static func from_dict(d: Variant) -> FireState:
	if not d is Dictionary:
		return null
	var o := d as Dictionary
	var st := StringName(str(o.get("state", "")))
	if not STATES.has(st) or not _num(o.get("x")) or not _num(o.get("z")):
		return null
	var f := FireState.new()
	f.id = str(o.get("id", ""))
	f.zone = str(o.get("zone", ""))
	f.x = float(o["x"])
	f.z = float(o["z"])
	f.fuel = clampf(float(o.get("fuel", 0.0)) if _num(o.get("fuel")) else 0.0, 0.0, fuel_max())
	f.stones = bool(o.get("stones", false))
	f.old = bool(o.get("old", false))
	f.state = st
	f.out_at = float(o["out_at"]) if _num(o.get("out_at")) else NAN
	f.bank_until = float(o["until"]) if _num(o.get("until")) else NAN
	f.share_day = int(o["share"]) if _num(o.get("share")) else -1
	f.born = float(o["born"]) if _num(o.get("born")) else 0.0
	f.exposure = float(o["exposure"]) if _num(o.get("exposure")) else 0.0
	f._stage = FireState.stage_of(f.fuel) if st == LIT else &""
	return f


static func _num(v: Variant) -> bool:
	return (v is float or v is int) and is_finite(float(v))


func _set_state(next: StringName, reason: StringName) -> void:
	var was := state
	state = next
	if was != next or reason == &"relit" or reason == &"lit":
		state_changed.emit(next, reason)


func _refresh_stage() -> void:
	var s := FireState.stage_of(fuel) if state == LIT else &""
	if s == _stage:
		return
	_stage = s
	stage_changed.emit(s)
