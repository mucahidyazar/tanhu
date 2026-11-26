class_name GameClock
extends RefCounted
## Oyunun saati (K20, K67; time.md §0 Z1, Z2, Z15, Z20, §1, §4, §6, §7.4, §12.2; godot.md §3.5): tek takvim. Durum mutlak gün
## (day_n: rehinenin günü, Gün I 1.041, Çocukluk −5.600, Serbest Gez 1.171) ve gün dakikasıdır (0..1440, yerel güneş saati); takvim
## gece yarısı artar (GameCalendar okur). 1 oyun günü 1.440 oyun dk = 3.600 gerçek sn: 1 oyun dk 2,5 gerçek sn, 1 gerçek sn 0,4 oyun dk.
## Hız ayarı yoktur: oran yalnız 0 (durma nedenleri ve bekleyişler), çağıranın dt ölçeği (Engine.time_scale) ya da Yol Akışı k'dır
## (rate). Saat yalnız ileri gider: skip, skip_to ve set_to adı konmuş atlamadır, geri yazım yok sayılır; ikinci sayaç tutulmaz (K67).
## Prototipin src/game/world-clock.js'inin taşınmasıdır (aynı olay sırası; tests/fixtures/time_core.json).
##
## Saftır: düğüm, ağaç, girdi ve duvar saati okumaz. Çağıran her kare step(dt) verir; dt kare başına en çok MAX_FRAME_S'dir (takılma ve
## sekme dönüşü saati sıçratmaz). Dakika Kahan düzeltmesiyle birikir: 3.600 sn'lik kare toplamından sonra dakika 1e−9 içinde aynıdır.
## Durma nedenleri sayılır (time.md §6.2): dialogue (bloklayan söz), cine (sinema), modal, map, pause (duraklatma kitabı; ağaç da
## durur), frozen (Donuk Kamp), dev. Biri açıkken saat akmaz.
##
## Yer (set_place): enlem ve sapma payı (ana kampta Daylight.CAMP_DEC_OFFSET, K67). Yer verilince günün güneş saatleri ve evreleri
## Daylight.day_info'dan gelir (sapma o günün tarihinden: Daylight.solar_dec(doy) + pay) ve evre olayları yayılır; yer yoksa (Çocukluk'un
## sahnesi bugün böyle kurar) yalnız saat başı ve gece yarısı olayları vardır, evre "" döner.
##
## Olaylar (d2/core.md §1.7; aynı dakikada sıra: gece yarısı ve saat başı, sonra şafak ya da akşam, sonra evre):
##   hour_passed {day_n, hour, abs, skipping}       saat başı
##   day_changed {day_n, abs, skipping}             gece yarısı (takvim günü arttı)
##   dawn {day_n, abs, skipping}                    Tan evresinin başı (sivil şafak − 30 dk): yeni gün, hikâye günü, tarih kartı
##   dusk {day_n, abs, skipping}                    Gece evresinin başı (sivil alaca + 30 dk)
##   phase_changed {day_n, phase, prev, slice, prev_slice, skipping}
##   hold_changed {id, on, at}                      bekleyiş tuttu ya da salındı
##   summoned {beat, at}                            vakit çağrısı (bekletmez)
##   skipped {from, to, minutes, reason, sleep, long, days, dawns, hours, lapse}   atlama ya da görünür akış bitti
## 24 saatten uzun atlamada sınır olayı yoktur, yalnız skipped (long true); sistemler kapalı biçimde tümler (time.md §7.4).
##
## Bekleyiş (time.md §6.3): yalnız dawn_line, ice_story, home_golden. Saat bekleyişin anına varınca durur; until koşulu tutunca ya da
## release ile salınır. Görünür akış (lapse; §7.2): saat verilen gerçek saniyede hedef dakikaya sabit hızla ilerler (Bekle'nin hızlı
## akışı, Çocukluk'ta sayımın vakti); akış sürerken olağan oran işlemez, durma nedenleri akışı da durdurur, bekleyiş akışı bitirir.
##
## Hedefler (next, at, hold): evre kimliği (başlangıcı), "hh:mm", gün dakikası sayısı ya da çapa: sunrise, sunset, civil_dawn,
## civil_dusk, nautical_dawn, nautical_dusk, dawn_at, dusk_at (prototipin civilDawn yazımı da okunur); ardından isteğe bağlı ±dk
## ("civil_dawn-30", "sunrise+30"). next şimdiden sonraki ya da şimdiki ilk anı verir (bugün ya da yarın); at o günün anını verir.
##   var clock := GameClock.new(1171, Daylight.MENU_MINUTE)          # Serbest Gez: 11 Nisan MÖ 209 14:46,2
##   clock.set_place(Daylight.CAMP_LAT, Daylight.CAMP_DEC_OFFSET)    # ana kamp: evreler ve güneş
##   clock.step(delta)                                               # her kare (2,5 sn = 1 oyun dk)
##   clock.phase()                                                   # &"golden" (İkindi)
##   clock.skip(clock.next(&"dawn") - clock.abs_minute(), &"wait")  # Tan ağarana dek: dawn ve skipped yayılır
##   clock.pause(&"dialogue", true)                                  # bloklayan söz: saat durur
##   clock.begin_lapse(GameClock.abs_of(-5600, 660.0), 4.0, &"beat") # 4 sn'de 11:00'e görünür akış

signal hour_passed(info: Dictionary)
signal day_changed(info: Dictionary)
signal dawn(info: Dictionary)
signal dusk(info: Dictionary)
signal phase_changed(info: Dictionary)
signal hold_changed(info: Dictionary)
signal summoned(info: Dictionary)
signal skipped(info: Dictionary)

const SEC_PER_MIN := 2.5
const MIN_PER_SEC := 0.4
const DAY_MIN := 1440
## Kare başına en çok duvar süresi (sn; time.md §1).
const MAX_FRAME_S := 0.25
## Bu uzunluğun ötesindeki atlama uzundur (oyun dk): sınır olayı yayılmaz.
const LONG_SKIP_MIN := 1440.0
## Görünür akışın bitiş payı (sn ve oyun dk).
const LAPSE_EPS := 0.000001
## Durma nedenleri (time.md §6.2; Godot'da sayılır).
const REASONS: Array[StringName] = [&"dialogue", &"cine", &"modal", &"map", &"pause", &"frozen", &"dev"]
## Bekleyişler (time.md §6.3).
const HOLD_IDS: Array[StringName] = [&"dawn_line", &"ice_story", &"home_golden"]
## Atlamanın nedenleri (time.md §7.4); öteki bir ad da geçer, olduğu gibi yazılır.
const SKIP_REASONS: Array[StringName] = [&"sleep", &"wait", &"rest", &"work", &"travel", &"cine", &"gate", &"chronicle", &"dev", &"beat"]
## Eski Serbest Gez kaydının günü (time.md §13: clock.day 0'dan sayardı): day_n = ROAM_DAY + day.
const ROAM_DAY := 1171
## Çapalar ve day_info anahtarları.
const ANCHORS := {
	"sunrise": "sunrise", "sunset": "sunset", "civil_dawn": "civil_dawn", "civilDawn": "civil_dawn", "civil_dusk": "civil_dusk",
	"civilDusk": "civil_dusk", "nautical_dawn": "nautical_dawn", "nauticalDawn": "nautical_dawn", "nautical_dusk": "nautical_dusk",
	"nauticalDusk": "nautical_dusk", "dawn_at": "dawn_at", "dawnAt": "dawn_at", "dusk_at": "dusk_at", "duskAt": "dusk_at",
}
## Gün verilmeyen bekleyiş (sıradaki an).
const NO_DAY := -2147483648

const _K_HOUR := 0
const _K_PHASE := 1

## Mutlak gün (rehinenin günü; negatif: rehinelikten önce).
var day_n := 0
## Gün dakikası [0, 1440).
var minute := 0.0
## Yol Akışı k (1–4; travel.md §6.4). Başka bir şey yazmaz.
var rate := 1.0
## Yerin enlemi (derece; NAN: yer yok) ve sapma payı (ana kampta −0,0127°).
var lat := NAN
var dec_offset := 0.0
## Ayın dolunay anı (mutlak gün; time.md §2).
var moon_epoch := GameCalendar.MOON_EPOCH

var _c := 0.0
var _paused := {}
var _lapsing := false
var _lapse_to := 0.0
var _lapse_from := 0.0
var _lapse_left := 0.0
var _lapse_reason: StringName = &""
## Bekleyişler: {id, at (mutlak dk), d, m, until (Callable), note, on}.
var _holds: Array[Dictionary] = []
var _phase: StringName = &""
var _slice: StringName = &""
var _edge_day := 0
var _edge_min := 0.0
## İki gözlü gün bilgisi önbelleği (bugün ve yarın).
var _ia := NO_DAY
var _ia_info: Dictionary = {}
var _ib := NO_DAY
var _ib_info: Dictionary = {}


func _init(p_day_n: int = 0, p_minute: float = 0.0) -> void:
	_set_dm(p_day_n, maxf(p_minute, 0.0))
	_resync()


## Mutlak dakika (day_n × 1440 + dakika; 64 bitlik kayan nokta).
func abs_minute() -> float:
	return float(day_n) * DAY_MIN + minute


## Günün ve dakikanın mutlak dakikası (saf).
static func abs_of(p_day_n: int, p_minute: float) -> float:
	return float(p_day_n) * DAY_MIN + p_minute


## Gün saati (0..24, kesirli).
func hour() -> float:
	return minute / 60.0


## «08:40» biçiminde saat (dakika aşağı yuvarlanır).
func text() -> String:
	return GameClock.hhmm(minute)


## «hh:mm» → gün dakikası (saf; sayı verilirse olduğu gibi). Okunamazsa -1.
static func parse_hhmm(value: Variant) -> float:
	if value is float or value is int:
		return float(value)
	var parts := str(value).strip_edges().split(":")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return -1.0
	var h := int(parts[0])
	var m := int(parts[1])
	if h < 0 or h > 23 or m < 0 or m > 59:
		return -1.0
	return float(h * 60 + m)


## Gün dakikası → «hh:mm» (saf; dakika aşağı yuvarlanır).
static func hhmm(p_minute: float) -> String:
	var m := posmod(floori(p_minute + 0.000001), DAY_MIN)
	return "%02d:%02d" % [floori(m / 60.0), m % 60]


# --- Yer ve gün ışığı -------------------------------------------------------------------------------------

## Saatin yeri: enlem ve sapma payı (derece). Evreler, şafak ve akşam bundan sonra yayılır; konum değişmez, olay yayılmaz.
func set_place(p_lat: float, p_dec_offset: float = 0.0) -> void:
	lat = p_lat
	dec_offset = p_dec_offset
	_ia = NO_DAY
	_ib = NO_DAY
	_resync()


func clear_place() -> void:
	set_place(NAN, 0.0)


func has_place() -> bool:
	return is_finite(lat)


## Günün sapması (derece): o günün tarihinden, yerin payıyla.
func dec_at(p_day_n: int) -> float:
	return Daylight.solar_dec(float(GameCalendar.doy(p_day_n))) + dec_offset


## Bugünün gün bilgisi (Daylight.day_info; yer yoksa boş).
func info() -> Dictionary:
	return info_at(day_n)


## Günün bilgisi (önbellekli; yer yoksa boş).
func info_at(p_day_n: int) -> Dictionary:
	if not has_place():
		return {}
	if p_day_n == _ia:
		return _ia_info
	if p_day_n == _ib:
		return _ib_info
	var d := Daylight.day_info(lat, dec_at(p_day_n))
	_ib = _ia
	_ib_info = _ia_info
	_ia = p_day_n
	_ia_info = d
	return d


## Şimdiki evre (dawn, morning, noon, golden, dusk, night; yer yoksa "").
func phase() -> StringName:
	return _phase


## Şimdiki eski dilim (morning, noon, evening, night; yer yoksa "").
func slice() -> StringName:
	return _slice


## Güneş −0,833°'nin altında mı: doğuştan önce ya da batıştan sonra (yer yoksa false).
func below_horizon() -> bool:
	var i := info()
	return not i.is_empty() and (minute < float(i["sunrise"]) or minute >= float(i["sunset"]))


## Güneş −6°'nin altında mı: sivil şafaktan önce ya da sivil alacadan sonra (yer yoksa false).
func dark() -> bool:
	var i := info()
	return not i.is_empty() and (minute < float(i["civil_dawn"]) or minute >= float(i["civil_dusk"]))


## Şimdinin ay yaşı (gün).
func moon_age() -> float:
	return GameCalendar.moon_age(abs_minute(), moon_epoch)


## Mutlak dakikanın güneşi (yer yoksa boş).
func sun_at_abs(abs_min: float) -> Dictionary:
	if not has_place():
		return {}
	var d := floori(abs_min / DAY_MIN)
	return Daylight.sun_at(lat, dec_at(d), abs_min - float(d) * DAY_MIN)


## Mutlak dakikanın ayı (yer yoksa boş).
func moon_at_abs(abs_min: float) -> Dictionary:
	if not has_place():
		return {}
	var d := floori(abs_min / DAY_MIN)
	return Daylight.moon_at(lat, dec_at(d), abs_min - float(d) * DAY_MIN, GameCalendar.moon_age(abs_min, moon_epoch))


## Işık düzeyi (0..1; d2/core.md §1.8): güneş ve ay, bulut yalnız ay terimini keser. Yer yoksa 1.
func light_level_at(abs_min: float, cloud: float = 0.0) -> float:
	if not has_place():
		return 1.0
	var sun := sun_at_abs(abs_min)
	var moon := moon_at_abs(abs_min)
	return Daylight.light_level(float(sun["el"]), float(moon["el"]), float(moon["illum"]), cloud)


## Gece sınıfı (lit, day, dim, dark): emek, hava, ordu ve hayvan okur.
func night_class_at(abs_min: float, cloud: float = 0.0, lit_pool: bool = false) -> StringName:
	return Daylight.night_class(light_level_at(abs_min, cloud), lit_pool)


# --- Durma ------------------------------------------------------------------------------------------------

## Durma nedenini açar ya da kapatır (REASONS'tan biri; başkası da sayılır).
func pause(reason: StringName, on: bool) -> void:
	if on:
		_paused[reason] = true
	else:
		_paused.erase(reason)


func is_paused() -> bool:
	return not _paused.is_empty()


func is_paused_by(reason: StringName) -> bool:
	return _paused.has(reason)


## Açık durma nedenleri (sıralı).
func paused_reasons() -> PackedStringArray:
	var out := PackedStringArray()
	for r: StringName in _paused:
		out.append(String(r))
	out.sort()
	return out


# --- Bekleyiş ---------------------------------------------------------------------------------------------

## Bekleyiş kurar (yalnız HOLD_IDS). at: mutlak dakika ya da hedef ("05:45", "dawn_at", evre); p_day verilirse hedef o günün anıdır,
## verilmezse sıradaki an. Geçmiş at şimdi tutar. until: koşul; doğru dönünce saat salınır (varışta zaten doğruysa durmaz).
## Döner: kuruldu mu?
func hold(id: StringName, at: Variant, p_day: int = NO_DAY, until: Callable = Callable(), note: String = "") -> bool:
	if not HOLD_IDS.has(id):
		push_warning("[clock] bekleyiş %s yok: yalnız %s" % [id, ", ".join(HOLD_IDS)])
		return false
	var point := _hold_point(at, p_day)
	if point.is_empty():
		push_warning("[clock] bekleyiş %s: okunamayan an %s" % [id, str(at)])
		return false
	if has_hold(id):
		release(id)
	var d := int(point[0])
	var m := float(point[1])
	if float(d - day_n) * DAY_MIN + (m - minute) <= 0.000001:
		d = day_n
		m = minute
	var h := {"id": id, "at": GameClock.abs_of(d, m), "d": d, "m": m, "until": until, "note": note, "on": false}
	_holds.append(h)
	if d == day_n and m == minute:
		_arrive(h)
	return true


func release(id: StringName) -> bool:
	for i in _holds.size():
		if _holds[i]["id"] == id:
			var h: Dictionary = _holds[i]
			_holds.remove_at(i)
			if h["on"]:
				hold_changed.emit({"id": id, "on": false, "at": h["at"]})
			return true
	return false


func has_hold(id: StringName) -> bool:
	for h in _holds:
		if h["id"] == id:
			return true
	return false


## Bekleyişler: [{id, at, note, on}].
func holds() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for h in _holds:
		out.append({"id": h["id"], "at": h["at"], "note": h["note"], "on": h["on"]})
	return out


## Saat bir bekleyişte tutuluyor mu (until koşulu tutanlar salınır)?
func is_held() -> bool:
	return _still_held()


## Vakit çağrısı (summoned); bekletmez.
func summon(beat_id: StringName, at: float = NAN) -> void:
	summoned.emit({"beat": beat_id, "at": abs_minute() if is_nan(at) else at})


# --- Akış -------------------------------------------------------------------------------------------------

## Bir kare: dt gerçek saniye (çağıranın dt ölçeğiyle), en çok MAX_FRAME_S. Döner: ilerleyen oyun dakikası.
func step(dt: float) -> float:
	var wall := clampf(dt, 0.0, MAX_FRAME_S)
	if wall <= 0.0 or is_paused() or _still_held():
		return 0.0
	if is_lapsing():
		return _step_lapse(wall)
	return _advance(wall * MIN_PER_SEC * maxf(rate, 0.0), false)


## Görünür akışı başlatır: saat seconds gerçek saniyede to_abs mutlak dakikasına sabit hızla varır. Hedef geride ya da şimdiyse false.
## seconds ≤ 0 ise hemen atlar.
func begin_lapse(to_abs: float, seconds: float, reason: StringName = &"wait") -> bool:
	if to_abs <= abs_minute() + 0.000001:
		return false
	_lapsing = true
	_lapse_from = abs_minute()
	_lapse_to = to_abs
	_lapse_left = maxf(seconds, 0.0)
	_lapse_reason = reason
	if _lapse_left <= 0.0:
		_advance(_lapse_to - abs_minute(), true)
		_finish_lapse()
	return true


func is_lapsing() -> bool:
	return _lapsing


## Akışın kalan gerçek süresi (sn; akış yoksa 0).
func lapse_left() -> float:
	return _lapse_left if is_lapsing() else 0.0


## Akışın hedefi (mutlak dakika; akış yoksa NAN).
func lapse_target() -> float:
	return _lapse_to if _lapsing else NAN


## Akışı olduğu yerde bırakır (saat geri gitmez; skipped yayılır).
func end_lapse() -> void:
	if is_lapsing():
		_finish_lapse()


## İleri atlama (oyun dk; time.md §7.4): ≤24 sa sınır olaylarıyla (skipping), daha uzunu tek skipped (long). İlk bekleyişte durur,
## bekleyişteyken ilerlemez. Döner: info (ilerlemediyse boş).
func skip(minutes: float, reason: StringName = &"wait", sleep: bool = false) -> Dictionary:
	if minutes <= 0.0 or _still_held():
		return {}
	var to_min := minute + minutes
	var k := floori(to_min / DAY_MIN)
	return _skip_to(day_n + k, to_min - float(k) * DAY_MIN, reason, sleep)


## Güne ve dakikaya atlar (yalnız ileri; geride ya da şimdiyse yok sayılır, boş döner). Tarih kapısı «gate», köprü «cine» (K33, K67).
func skip_to(p_day_n: int, p_minute: float, reason: StringName = &"gate") -> Dictionary:
	var k := floori(p_minute / DAY_MIN)
	var d := p_day_n + k
	var m := p_minute - float(k) * DAY_MIN
	if d < day_n or (d == day_n and m <= minute) or _still_held():
		return {}
	return _skip_to(d, m, reason, false)


## Mutlak dakikaya atlar (yalnız ileri; geri yazım uyarıyla yok sayılır, boş döner).
func set_to(abs_min: float, reason: StringName = &"dev") -> Dictionary:
	if not is_finite(abs_min):
		return {}
	if abs_min < abs_minute() - 0.000001:
		push_warning("[clock] set_to geri gidemez: %.4f < %.4f" % [abs_min, abs_minute()])
		return {}
	var d := floori(abs_min / DAY_MIN)
	return skip_to(d, abs_min - float(d) * DAY_MIN, reason)


## Hedefin şimdiki ya da sonraki ilk anı (mutlak dk; bilinmeyen hedef ya da yer gereken hedefte yer yoksa NAN).
func next(target: Variant) -> float:
	for k in 3:
		var at_m := _target_minute(target, day_n + k)
		if is_nan(at_m):
			return NAN
		if k > 0 or at_m >= minute:
			return GameClock.abs_of(day_n + k, at_m)
	return NAN


## Hedefin o takvim günündeki anı (mutlak dk; ileri ya da geri olabilir).
func at(target: Variant, p_day_n: int = NO_DAY) -> float:
	var d := day_n if p_day_n == NO_DAY else p_day_n
	var m := _target_minute(target, d)
	return NAN if is_nan(m) else GameClock.abs_of(d, m)


# --- Kayıt ----------------------------------------------------------------------------------------------

## clock bloğu (godot.md §3.4, §3.5): {v, day_n, minute, holds}; until kaydedilmez, sahibi yüklemede yeniden kurar.
func to_dict() -> Dictionary:
	var hs: Array = []
	for h in _holds:
		hs.append({"id": String(h["id"]), "at": h["at"], "note": h["note"]})
	return {"v": 1, "day_n": day_n, "minute": minute, "holds": hs}


## Bloktan saat (göç dahil, bkz. load_dict).
static func from_dict(d: Dictionary) -> GameClock:
	var clock := GameClock.new()
	clock.load_dict(d)
	return clock


## Bloğu bu saate yazar (yer, durma nedenleri ve sinyaller kalır; olay yaymaz). Göç (time.md §13): prototipin «dayN» yazımı okunur;
## eski Serbest Gez kaydının {day, minute}'i day_n = 1.171 + day olur. Döner: blok okunabildi mi?
func load_dict(d: Dictionary) -> bool:
	var dn: Variant = d.get("day_n", d.get("dayN", null))
	if dn == null and (d.get("day") is int or d.get("day") is float):
		dn = ROAM_DAY + int(d["day"])
	if not (dn is int or dn is float):
		return false
	var m: Variant = d.get("minute", 0.0)
	_set_dm(int(dn), clampf(float(m), 0.0, DAY_MIN - 0.000001) if (m is int or m is float) else 0.0)
	_holds.clear()
	var rows: Variant = d.get("holds", [])
	if rows is Array:
		for row: Variant in rows:
			if not row is Dictionary or not HOLD_IDS.has(StringName(str((row as Dictionary).get("id", "")))):
				continue
			var at_v: Variant = (row as Dictionary).get("at")
			if not (at_v is int or at_v is float):
				continue
			var id := StringName(str(row["id"]))
			if has_hold(id):
				continue
			var hd := floori(float(at_v) / DAY_MIN)
			var hm := float(at_v) - float(hd) * DAY_MIN
			var ahead := hd > day_n or (hd == day_n and hm > minute)
			if not ahead:
				hd = day_n
				hm = minute
			_holds.append({"id": id, "at": GameClock.abs_of(hd, hm), "d": hd, "m": hm, "until": Callable(),
				"note": str((row as Dictionary).get("note", "")), "on": not ahead})
	_resync()
	return true


# --- İç -----------------------------------------------------------------------------------------------------

## Atlamanın tek yolu: hedef gün ve dakika (gün içinde).
func _skip_to(to_day: int, to_min: float, reason: StringName, sleep: bool) -> Dictionary:
	var from_day := day_n
	var from_min := minute
	var from := abs_minute()
	var h := _hold_in(from_day, from_min, to_day, to_min)
	if not h.is_empty():
		to_day = int(h["d"])
		to_min = float(h["m"])
	var span := float(to_day - from_day) * DAY_MIN + (to_min - from_min)
	if span <= 0.0:
		return {}
	var long := span > LONG_SKIP_MIN
	var dawns := _count_dawns(from_day, from_min, to_day, to_min)
	_place(to_day, to_min)
	if long:
		_resync()
	else:
		_cross(from_day, from_min, true)
	if not h.is_empty():
		_arrive(h)
	var days := to_day - from_day
	var info := {"from": from, "to": abs_minute(), "minutes": span, "reason": reason, "sleep": sleep, "long": long, "days": days,
		"dawns": dawns, "hours": days * 24 + floori(to_min / 60.0) - floori(from_min / 60.0), "lapse": false}
	skipped.emit(info)
	return info


func _step_lapse(wall: float) -> float:
	var left := _lapse_to - abs_minute()
	# Kayan nokta payı: kalan süre bir mikrosaniyenin altına inince akış biter (kare toplamı tam denk gelmeyebilir).
	if left <= LAPSE_EPS or wall >= _lapse_left - LAPSE_EPS:
		var moved := _advance(maxf(left, 0.0), true)
		_finish_lapse()
		return moved
	var share := wall / _lapse_left
	_lapse_left -= wall
	var moved := _advance(left * share, true)
	if is_held():
		# Bekleyiş akışı bitirir: saat bekleyişin anında kalır.
		_finish_lapse()
	elif _lapse_left <= LAPSE_EPS:
		_advance(maxf(_lapse_to - abs_minute(), 0.0), true)
		_finish_lapse()
	return moved


func _finish_lapse() -> void:
	var info := {"from": _lapse_from, "to": abs_minute(), "minutes": abs_minute() - _lapse_from, "reason": _lapse_reason, "sleep": false,
		"long": false, "days": floori(abs_minute() / DAY_MIN) - floori(_lapse_from / DAY_MIN), "dawns": 0, "hours": 0, "lapse": true}
	_lapsing = false
	_lapse_left = 0.0
	_lapse_reason = &""
	skipped.emit(info)


## İlerler (bekleyişte durur) ve geçilen sınırları sırayla yayar. Döner: ilerleyen dakika.
func _advance(minutes: float, skipping: bool) -> float:
	if minutes <= 0.0:
		return 0.0
	var from_day := day_n
	var from_min := minute
	_add(minutes)
	var h := _hold_in(from_day, from_min, day_n, minute)
	if not h.is_empty():
		_place(int(h["d"]), float(h["m"]))
	if _past(_edge_day, _edge_min):
		_cross(from_day, from_min, skipping)
	if not h.is_empty():
		_arrive(h)
	return float(day_n - from_day) * DAY_MIN + (minute - from_min)


## Dakika ekler (Kahan düzeltmeli), günü taşır (olay yaymaz).
func _add(minutes: float) -> void:
	var y := minutes - _c
	var t := minute + y
	_c = (t - minute) - y
	minute = t
	if minute >= DAY_MIN:
		var days := floori(minute / DAY_MIN)
		day_n += days
		minute -= float(days) * DAY_MIN
		if minute < 0.0:
			minute = 0.0


func _set_dm(d: int, m: float) -> void:
	var k := floori(m / DAY_MIN)
	day_n = d + k
	minute = m - float(k) * DAY_MIN
	_c = 0.0


func _place(d: int, m: float) -> void:
	day_n = d
	minute = m
	_c = 0.0


## Saat (d, m) noktasına vardı ya da geçti mi.
func _past(d: int, m: float) -> bool:
	return day_n > d or (day_n == d and minute >= m)


func _resync() -> void:
	var i := info()
	_phase = Daylight.phase_at(i, minute) if not i.is_empty() else &""
	_slice = Daylight.slice_of(_phase)
	_find_edge()


## Sıradaki saat başı ya da evre başı.
func _find_edge() -> void:
	var ed := day_n
	var em := float(floori(minute / 60.0) + 1) * 60.0
	if em >= DAY_MIN:
		ed = day_n + 1
		em = 0.0
	if has_place():
		var pd := day_n + 1
		var pm := float((info_at(day_n + 1)["phases"] as Array)[0][1])
		for row: Array in info_at(day_n)["phases"]:
			if float(row[1]) > minute:
				pd = day_n
				pm = float(row[1])
				break
		if pd < ed or (pd == ed and pm < em):
			ed = pd
			em = pm
	_edge_day = ed
	_edge_min = em


## (from, şimdi] aralığında geçilen sınırlar zaman sırasıyla; aynı dakikada saat başı önce, sonra evre (şafak ya da akşam, evre).
func _cross(from_day: int, from_min: float, skipping: bool) -> void:
	var to_day := day_n
	var to_min := minute
	var list: Array = []
	for d in range(from_day, to_day + 1):
		var lo := from_min if d == from_day else -1.0
		var hi := to_min if d == to_day else float(DAY_MIN)
		var h0 := 0 if lo < 0.0 else floori(lo / 60.0) + 1
		for h in range(h0, 24):
			if float(h) * 60.0 > hi:
				break
			list.append([d, float(h) * 60.0, _K_HOUR, h])
		if has_place():
			for row: Array in info_at(d)["phases"]:
				var start := float(row[1])
				if start > lo and start <= hi:
					list.append([d, start, _K_PHASE, row[0]])
	list.sort_custom(func(a: Array, b: Array) -> bool:
		if a[0] != b[0]:
			return a[0] < b[0]
		if a[1] != b[1]:
			return a[1] < b[1]
		return a[2] < b[2])
	for e: Array in list:
		var d := int(e[0])
		var at_abs := GameClock.abs_of(d, float(e[1]))
		if int(e[2]) == _K_HOUR:
			if int(e[3]) == 0:
				day_changed.emit({"day_n": d, "abs": at_abs, "skipping": skipping})
			hour_passed.emit({"day_n": d, "hour": int(e[3]), "abs": at_abs, "skipping": skipping})
			continue
		var value: StringName = e[3]
		var prev := _phase
		var prev_slice := _slice
		_phase = value
		_slice = Daylight.slice_of(value)
		if value == &"dawn":
			dawn.emit({"day_n": d, "abs": at_abs, "skipping": skipping})
		elif value == &"night":
			dusk.emit({"day_n": d, "abs": at_abs, "skipping": skipping})
		phase_changed.emit({"day_n": d, "phase": value, "prev": prev, "slice": _slice, "prev_slice": prev_slice, "skipping": skipping})
	_resync()


func _count_dawns(from_day: int, from_min: float, to_day: int, to_min: float) -> int:
	if not has_place():
		return 0
	var n := 0
	for d in range(from_day, to_day + 1):
		var at_m := float((info_at(d)["phases"] as Array)[0][1])
		var after := d > from_day or at_m > from_min
		var before := d < to_day or at_m <= to_min
		if after and before:
			n += 1
	return n


## (from, to] aralığına düşen en erken, henüz tutmamış bekleyiş (yoksa boş).
func _hold_in(from_day: int, from_min: float, to_day: int, to_min: float) -> Dictionary:
	var best: Dictionary = {}
	for h in _holds:
		if h["on"]:
			continue
		var hd := int(h["d"])
		var hm := float(h["m"])
		var after := hd > from_day or (hd == from_day and hm > from_min)
		var before := hd < to_day or (hd == to_day and hm <= to_min)
		if not after or not before:
			continue
		if best.is_empty() or hd < int(best["d"]) or (hd == int(best["d"]) and hm < float(best["m"])):
			best = h
	return best


func _arrive(h: Dictionary) -> void:
	var until: Callable = h["until"]
	if until.is_valid() and until.call() == true:
		_holds.erase(h)
		return
	h["on"] = true
	hold_changed.emit({"id": h["id"], "on": true, "at": h["at"]})


## Tutan bekleyişin until koşulu doğruysa salar; hâlâ tutan varsa true.
func _still_held() -> bool:
	var held := false
	for i in range(_holds.size() - 1, -1, -1):
		var h: Dictionary = _holds[i]
		if not h["on"]:
			continue
		var until: Callable = h["until"]
		if until.is_valid() and until.call() == true:
			release(h["id"])
		else:
			held = true
	return held


func _hold_point(at_v: Variant, p_day: int) -> Array:
	if at_v is float or at_v is int:
		if not is_finite(float(at_v)):
			return []
		var d := floori(float(at_v) / DAY_MIN)
		return [d, float(at_v) - float(d) * DAY_MIN]
	if p_day != NO_DAY:
		var m := _target_minute(at_v, p_day)
		return [] if is_nan(m) else [p_day, m]
	for k in 2:
		var m := _target_minute(at_v, day_n + k)
		if is_nan(m):
			return []
		if k > 0 or m >= minute:
			return [day_n + k, m]
	return []


## Hedefin o gündeki dakikası (NAN: okunamadı ya da yer gerekir ama yok).
func _target_minute(target: Variant, p_day: int) -> float:
	if target is float or target is int:
		return fposmod(float(target), DAY_MIN) if is_finite(float(target)) else NAN
	if not (target is String or target is StringName):
		return NAN
	var text := str(target).strip_edges()
	var phase_i := Daylight.PHASES.find(StringName(text))
	if phase_i >= 0:
		var i := info_at(p_day)
		return NAN if i.is_empty() else float((i["phases"] as Array)[phase_i][1])
	var clock := GameClock.parse_hhmm(text)
	if clock >= 0.0 and text.contains(":"):
		return clock
	var name := text
	var offset := 0.0
	for sign in ["+", "-", "−"]:
		var at_i := text.find(sign)
		if at_i > 0:
			name = text.substr(0, at_i).strip_edges()
			var number := text.substr(at_i + 1).strip_edges().replace(",", ".")
			if not number.is_valid_float():
				return NAN
			offset = number.to_float() * (1.0 if sign == "+" else -1.0)
			break
	if not ANCHORS.has(name):
		return NAN
	var info_d := info_at(p_day)
	return NAN if info_d.is_empty() else float(info_d[ANCHORS[name]]) + offset
