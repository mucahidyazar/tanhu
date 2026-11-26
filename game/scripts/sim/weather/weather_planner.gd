class_name WeatherPlanner
extends RefCounted
## Hava planlayıcısı (saf; weather.md §5, H4, H24; godot.md §3, §8.2): yarı Markov seçim + cephe dizgesi (hazırlık, tepe, çözülme) +
## gün içi eğri, tohumlu ve belirlenimli. Zincir sabit çapadan kurulur: floor(hourAbs / 24) × 24 − 24'te «clear» ile başlar ve olaysız
## ileri sarılır; kayıt, yükleme ve 24 saat içinde dönüş aynı havayı verir. Plan en az 12 sa ileridedir (işaretler ve gök okuma
## geleceği bilir). Hikâye kilidi planlayıcıyı durdurur (§6.1); kilit kalkınca kilidin türünden devam eder.
##
## Prototipin src/game/weather-core.js Planner'ından bit bit taşınır (K29): RNG çekim sırası, q() yuvarlaması (0,05 sa) ve kayan
## nokta işlem sırası aynıdır; sınama tests/fixtures/weather_core.json'la tür ve sınırları tam eşit karşılaştırır. Ağırlıklar
## (hedef pay → ayarlı ağırlık, §5.6) data/weather/weights.json'dan gelir; anahtar yoksa calibrate() koşar (yavaş, uyarır).
##   var p := WeatherPlanner.new({"climate": "orkhon", "season": "camp_spring", "seed": seed, "zone": "tanhu_camp"})
##   p.start(hour_abs)
##   p.advance(hour_abs)          # saat sınırında: kuyruğu doldurur, geçen bölümü atar
##   var mix := p.at(hour_abs)    # karışan iki bölüm ve oran

const S_PER_H := 150.0
const HORIZON_H := 12.0
const SAVE_SEGMENTS := 10
const Q := 20.0
const CAL_ROUNDS: Array[int] = [800, 800, 800, 800, 2000, 2000, 2000, 2000]
const CAL_AVG := 4
const CAL_SEED := 0x5eed
const SALT_RESUME := 0x51ed

## Hikâye kilidi (weather.md §6.1).
class Lock:
	extends RefCounted
	var id := ""
	var type := 0
	var params: Dictionary = {}
	## [{k, type?, params?}]
	var keys: Array = []
	var blend := 6.0
	var blend_in := NAN
	var until := INF
	var pin_fx: Dictionary = {}
	var signs := false
	var after := "resume"
	var k := 0.0
	var t0 := 0.0
	var seg: WeatherSegment
	var from: WeatherSegment


## Şimdiki karışım: a ve b bölümdür, k 0..1 (sine-in-out); kilit varsa lock.
class Mix:
	extends RefCounted
	var a: WeatherSegment
	var b: WeatherSegment
	var k := 1.0
	var seg: WeatherSegment
	var lock: Lock


## Varış lütfu (weather.md §5.7): zinciri değiştirmez, at() kaplar.
class Arrival:
	extends RefCounted
	var at := 0.0
	var until := 0.0
	var sub: WeatherSegment


static var _idle: WeatherSegment
static var _cal_cache: Dictionary = {}

var climate := ""
var season := ""
var row: Dictionary = {}
var exclude := PackedStringArray()
var seed := 0
var zone := ""
var zone_hash := 0
var target: Dictionary = {}
var weights: Dictionary = {}
## plan[0] şimdiki bölüm.
var plan: Array[WeatherSegment] = []
## Geçen bölüm (karışım).
var prev: WeatherSegment
## Yığın: son açılan kazanır.
var locks: Array[Lock] = []
var now := -INF
var arrival: Arrival

var _dur: Dictionary = {}
var _dur_opt: Dictionary = {}
var _rng := WeatherRng.new(1)
var _w := PackedFloat64Array()
var _wbase := PackedFloat64Array()
var _mean := PackedFloat64Array()
var _curve: Array[PackedFloat64Array] = []
var _excluded := PackedByteArray()
var _showery := 0.0
var _p_hail := 0.0
var _fronts: Dictionary = {}
var _heavy_prep := PackedFloat64Array([0.75, 1.0])
var _hail_burst: Dictionary = {}
var _gust_front_blend := 6.0
var _n := 0
var _i_clear := 0
var _i_cloud := 1
var _i_overcast := 2
var _i_fog := 3
var _i_snow := 0
var _i_heavy := 0
var _i_thunder := 0
var _i_dry_storm := 0
var _i_hail := 0
var _i_downpour := 0
var _i_kara := 0
var _i_blizzard := 0
var _blizzard_from := PackedByteArray()


## opts: climate, season, exclude (dizi), seed, zone, dur ({tür: [lo, hi]}), weights ({tür: ağırlık}; verilmezse gömülü ya da ayar).
func _init(opts: Dictionary = {}) -> void:
	_n = WeatherData.count()
	_i_clear = WeatherData.index_of(&"clear")
	_i_cloud = WeatherData.index_of(&"cloud")
	_i_overcast = WeatherData.index_of(&"overcast")
	_i_fog = WeatherData.index_of(&"fog")
	_i_snow = WeatherData.index_of(&"snow")
	_i_heavy = WeatherData.index_of(&"heavy_snow")
	_i_thunder = WeatherData.index_of(&"thunderstorm")
	_i_dry_storm = WeatherData.index_of(&"dry_storm")
	_i_hail = WeatherData.index_of(&"hail")
	_i_downpour = WeatherData.index_of(&"downpour")
	_i_kara = WeatherData.index_of(&"kara_boran")
	_i_blizzard = WeatherData.index_of(&"blizzard")
	_blizzard_from.resize(_n)
	for id: StringName in [&"snow", &"heavy_snow", &"gale", &"overcast", &"cloud", &"clear"]:
		_blizzard_from[WeatherData.index_of(id)] = 1
	var fr: Dictionary = WeatherData.section("fronts")
	for id: String in fr:
		_fronts[WeatherData.index_of(id)] = fr[id]
	var hp: Variant = WeatherData.section("heavy_prep")
	if hp is Array and (hp as Array).size() == 2:
		_heavy_prep = PackedFloat64Array([float(hp[0]), float(hp[1])])
	var sub: Dictionary = WeatherData.section("sub")
	_hail_burst = sub.get("hail_burst", {})
	_gust_front_blend = float((sub.get("gust_front", {}) as Dictionary).get("blend_s", 6.0))
	_w.resize(_n)
	_wbase.resize(_n)
	_mean.resize(_n)
	_excluded.resize(_n)
	_curve.resize(_n)
	climate = str(opts.get("climate", "orkhon"))
	season = str(opts.get("season", "spring"))
	exclude = PackedStringArray(opts.get("exclude", []))
	seed = int(opts.get("seed", 1)) & WeatherRng.MASK
	zone = str(opts.get("zone", ""))
	zone_hash = WeatherRng.str_hash(zone)
	_dur_opt = opts.get("dur", {}) if opts.get("dur") is Dictionary else {}
	_set_row(climate, season)
	if opts.get("weights") is Dictionary and not (opts["weights"] as Dictionary).is_empty():
		_set_weights(opts["weights"])
	else:
		_set_weights(weights_for(climate, season, exclude, _dur_opt))


func _set_row(p_climate: String, p_season: String) -> void:
	row = WeatherData.row(p_climate, p_season)
	if row.is_empty():
		push_error("[weather] bilinmeyen iklim satırı %s:%s" % [p_climate, p_season])
	_showery = float(row.get("showery", 0.0))
	_p_hail = float(row.get("p_hail", 0.0))
	_dur = {}
	var rd: Dictionary = row.get("dur", {})
	for id: String in rd:
		_dur[WeatherData.index_of(id)] = PackedFloat64Array([float(rd[id][0]), float(rd[id][1])])
	for id: String in _dur_opt:
		_dur[WeatherData.index_of(id)] = PackedFloat64Array([float(_dur_opt[id][0]), float(_dur_opt[id][1])])
	for i in _n:
		var d := dur_of(i)
		_mean[i] = (d[0] + d[1]) / 2.0
		_curve[i] = WeatherData.curve_of(i)
	target = WeatherData.target_shares(p_climate, p_season, exclude)
	_set_excluded()


func _set_excluded() -> void:
	_excluded.fill(0)
	for id in exclude:
		var i := WeatherData.index_of(id)
		if i >= 0:
			_excluded[i] = 1


func _set_weights(w: Dictionary) -> void:
	weights = w
	_wbase.fill(0.0)
	for id: String in w:
		var i := WeatherData.index_of(id)
		if i >= 0:
			_wbase[i] = float(w[id])


## Tür süresi [lo, hi] (sa): iklim satırının ya da zonun farkı, yoksa türün.
func dur_of(i: int) -> PackedFloat64Array:
	if _dur.has(i):
		return _dur[i]
	return PackedFloat64Array([WeatherData.dur_lo[i], WeatherData.dur_hi[i]]) if WeatherData.has_dur[i] else PackedFloat64Array([1.0, 1.0])


# --- Zincir ---------------------------------------------------------------------------------------------------------

## Sabit çapa (§5.5): floor(hourAbs / 24) × 24 − 24'te «clear», olaysız ileri sarılır.
func start(hour_abs: float) -> WeatherPlanner:
	var anchor := floorf(hour_abs / 24.0) * 24.0 - 24.0
	_rng.reseed(WeatherRng.hash32(seed, zone_hash, floori(anchor * 4.0)))
	var d := dur_of(_i_clear)
	var seg := WeatherSegment.make(_i_clear, anchor, q(anchor + maxf(1.0 / Q, _rng.span(d[0], d[1]))), WeatherSegment.SRC_SIM)
	seg.seed = _seg_seed(anchor)
	plan = [seg]
	prev = null
	locks.clear()
	advance(hour_abs)
	return self


## Saat sınırında kuyruğu doldurur, geçen bölümü atar (§5.1). Kilit sürerken bölüm eklenmez (§5.4).
func advance(hour_abs: float) -> WeatherPlanner:
	now = hour_abs
	if arrival and hour_abs > arrival.until + 1.0:
		arrival = null
	var i := locks.size() - 1
	while i >= 0:
		if i < locks.size():
			var l := locks[i]
			if hour_abs >= l.until:
				_release_at(i, l.until, l.blend)
		i -= 1
	if not locks.is_empty():
		return self
	if plan.is_empty():
		return start(hour_abs)
	while plan[plan.size() - 1].t1 < hour_abs + HORIZON_H:
		_append()
	while plan.size() > 1 and plan[0].t1 <= hour_abs:
		prev = plan.pop_front()
	return self


## Şimdiki karışım (§5.8): out yeniden kullanılır.
func at(hour_abs: float, out: Mix = null) -> Mix:
	if out == null:
		out = Mix.new()
	var lock: Lock = locks[locks.size() - 1] if not locks.is_empty() else null
	if lock:
		out.a = lock.from
		out.b = lock.seg
		var bl := lock.blend if is_nan(lock.blend_in) else lock.blend_in
		out.k = ease_k(((hour_abs - lock.t0) * S_PER_H) / maxf(0.01, bl))
		out.seg = lock.seg
		out.lock = lock
		return out
	if plan.is_empty():
		var idle := idle_segment()
		out.a = idle
		out.b = idle
		out.seg = idle
		out.k = 1.0
		out.lock = null
		return out
	var i := 0
	while i < plan.size() - 1 and plan[i].t1 <= hour_abs:
		i += 1
	var seg := plan[i]
	var p_prev: WeatherSegment = plan[i - 1] if i > 0 else prev
	var cur := seg
	var from := seg.t0
	# Varış lütfu kaplamadır (§5.7): varıştan sonraki 1 sa'te (Hikâye 1,5) başlayan sev ≥3 bölüm başlamaz; yerine önündeki hafif bölüm
	# (ya da varışta zaten süren fırtına) kalır, lütuf bitince karışarak girer. Zincir değişmez.
	var ar := arrival
	if ar and p_prev and p_prev.t0 > ar.at and p_prev.t0 < ar.until and WeatherData.sev[p_prev.type] >= 3:
		p_prev = ar.sub
	if ar and hour_abs < ar.until and (WeatherData.sev[seg.type] < 3 or seg.t0 <= ar.at):
		ar.sub = seg
	if ar and seg.t0 > ar.at and seg.t0 < ar.until and WeatherData.sev[seg.type] >= 3:
		var sub: WeatherSegment = null
		var j := i - 1
		while j >= 0:
			if WeatherData.sev[plan[j].type] < 3 or plan[j].t0 <= ar.at:
				sub = plan[j]
				break
			j -= 1
		if sub == null:
			sub = ar.sub if ar.sub else (prev if prev else seg)
		if hour_abs < ar.until:
			cur = sub
			p_prev = null
		else:
			p_prev = sub
			from = ar.until
	var s := (hour_abs - from) * S_PER_H
	var bs := blend_s_of(p_prev, cur) if p_prev else 0.0
	if p_prev and s < bs:
		out.a = p_prev
		out.b = cur
		out.k = ease_k(s / bs)
	else:
		out.a = cur
		out.b = cur
		out.k = 1.0
	out.seg = cur
	out.lock = null
	return out


## Bölüm sınırının karışım süresi, sn (§5.8): kuru↔kuru 40, kuru↔gri 30, ıslaklık başı 20, ıslaktan çözülmeye 60, fırtına önü 6.
func blend_s_of(a: WeatherSegment, b: WeatherSegment) -> float:
	if not is_nan(b.blend_s):
		return b.blend_s
	if b.has_cell and b.t0 == b.cell0 and (b.type == _i_thunder or b.type == _i_dry_storm):
		return _gust_front_blend
	var wa := WeatherData.wet[a.type] == 1
	var wb := WeatherData.wet[b.type] == 1
	if not wa and wb:
		return 20.0
	if wa and not wb:
		return 60.0
	if WeatherData.group[a.type] == WeatherData.GROUP_DRY and WeatherData.group[b.type] == WeatherData.GROUP_DRY:
		return 40.0
	return 30.0


# --- Kilit ------------------------------------------------------------------------------------------------------------

## Hikâye kilidi (§6.1): yığın; aynı kimlik yeniden açılırsa eskisinin yerini alır. opts: type (zorunlu), params, keys, blend (6),
## until (hourAbs; yoksa release'e dek), pin_fx, signs, after ("resume", "clear" ya da tür), at (şimdi).
func lock(id: String, opts: Dictionary) -> Lock:
	var ti := WeatherData.index_of(str(opts.get("type", "")))
	if ti < 0:
		push_error("[weather] bilinmeyen hava türü «%s»" % str(opts.get("type", "")))
		return null
	var at_h := float(opts.get("at", now))
	var old := _lock_index(id)
	if old >= 0:
		locks.remove_at(old)
	var cur := at(at_h)
	var from := cur.b if cur.k >= 0.5 else cur.a
	var until_v: Variant = opts.get("until")
	var until := float(until_v) if until_v is float or until_v is int else INF
	var seg := WeatherSegment.make(ti, at_h, until, WeatherSegment.SRC_STORY)
	# Hikâye fırtınası da şimşek hücresi taşır (açık uçluysa 2 sa'lik hücre).
	if ti == _i_thunder or ti == _i_dry_storm:
		seg.has_cell = true
		seg.cell0 = at_h
		seg.cell1 = until if until < INF else at_h + 2.0
	var l := Lock.new()
	l.id = id
	l.type = ti
	l.params = opts.get("params", {}) if opts.get("params") is Dictionary else {}
	l.keys = opts.get("keys", []) if opts.get("keys") is Array else []
	l.blend = float(opts.get("blend", 6.0))
	l.until = until
	l.pin_fx = opts.get("pin_fx", {}) if opts.get("pin_fx") is Dictionary else {}
	l.signs = bool(opts.get("signs", false))
	l.after = str(opts.get("after", "resume"))
	l.t0 = at_h
	l.seg = seg
	l.from = from
	locks.append(l)
	return l


func release(id: String, blend: float = 6.0, at_h: float = NAN) -> bool:
	var i := _lock_index(id)
	if i < 0:
		return false
	_release_at(i, now if is_nan(at_h) else at_h, blend)
	return true


func progress(id: String, k: float) -> Lock:
	var i := _lock_index(id)
	if i < 0:
		return null
	locks[i].k = clampf(k, 0.0, 1.0)
	return locks[i]


func has_lock(id: String) -> bool:
	return _lock_index(id) >= 0


func top_lock() -> Lock:
	return locks[locks.size() - 1] if not locks.is_empty() else null


## Kilidin anahtarlara göre türü (§6.1 keys): k'ye dek son type'lı anahtar.
func lock_type(l: Lock) -> int:
	var t := l.type
	for key: Variant in l.keys:
		if key is Dictionary and (key as Dictionary).has("type") and float(key.get("k", 0.0)) <= l.k:
			var ki := WeatherData.index_of(str(key["type"]))
			if ki >= 0:
				t = ki
	return t


func _lock_index(id: String) -> int:
	for i in locks.size():
		if locks[i].id == id:
			return i
	return -1


# --- Satır ve dışlama --------------------------------------------------------------------------------------------------

## Dışlanan türler değişince (camp3 ocağı, §6.3): şimdiki bölüm kalır, sonrası yeni ağırlıkla yeniden kurulur. Döner: değişti mi?
func set_exclude(p_exclude: PackedStringArray, hour_abs: float = NAN) -> bool:
	if p_exclude.size() == exclude.size():
		var same := true
		for x in p_exclude:
			if not exclude.has(x):
				same = false
				break
		if same:
			return false
	exclude = p_exclude.duplicate()
	target = WeatherData.target_shares(climate, season, exclude)
	_set_excluded()
	_set_weights(weights_for(climate, season, exclude, _dur_opt))
	_cut_after(now if is_nan(hour_abs) else hour_abs)
	return true


## Mevsim ya da iklim değişince (takvim, K67): şimdiki cephe grubu kalır, sonrası yeni satırla kurulur. Döner: değişti mi?
func set_row(p_climate: String, p_season: String, hour_abs: float = NAN) -> bool:
	if p_climate == climate and p_season == season:
		return false
	if not WeatherData.has_row(p_climate, p_season):
		push_error("[weather] bilinmeyen iklim satırı %s:%s" % [p_climate, p_season])
		return false
	climate = p_climate
	season = p_season
	_set_row(climate, season)
	_set_weights(weights_for(climate, season, exclude, _dur_opt))
	_cut_after(now if is_nan(hour_abs) else hour_abs)
	return true


## Varış lütfu (§5.7): zinciri değiştirmez, at() kaplar.
func arrive(hour_abs: float, grace_h: float = 1.0) -> void:
	arrival = Arrival.new()
	arrival.at = hour_abs
	arrival.until = hour_abs + grace_h
	var cur := at(hour_abs)
	arrival.sub = null if cur.lock else cur.seg


## ≤ hourAbs + hours aralığındaki bölümler (HUD, gök okuma): [{type, at, sev, src}].
func next_events(hours: float) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var l := top_lock()
	if l:
		out.append({"type": WeatherData.id_of(lock_type(l)), "at": now, "sev": WeatherData.sev[l.type], "src": "story"})
		return out
	for s in plan:
		if s.t0 > now + hours:
			break
		if not out.is_empty() and out[out.size() - 1]["type"] == s.type_id():
			continue
		out.append({"type": s.type_id(), "at": maxf(s.t0, now), "sev": WeatherData.sev[s.type], "src": s.src_name()})
	return out


# --- Kayıt ------------------------------------------------------------------------------------------------------------

## {plan: [≤10 bölüm], locks: [...]} (weather.md §12.7). Kayıt grubu bölmez: yarım kalan cephe grubu atılır, yüklemede aynı kuraldan
## yeniden kurulur.
func to_dict() -> Dictionary:
	var keep: Array[WeatherSegment] = []
	for i in mini(plan.size(), SAVE_SEGMENTS):
		keep.append(plan[i])
	while keep.size() > 1 and keep[keep.size() - 1].g:
		keep.pop_back()
	var out_plan: Array = []
	for s in keep:
		out_plan.append(s.to_dict())
	var out_locks: Array = []
	for l in locks:
		var o := {"id": l.id, "type": String(WeatherData.id_of(l.type)), "k": WeatherRng.js_round(l.k * 1000.0) / 1000.0, "t0": l.t0, "after": l.after, "blend": l.blend}
		if l.until < INF:
			o["until"] = l.until
		if not l.params.is_empty():
			o["params"] = l.params
		if not l.keys.is_empty():
			o["keys"] = l.keys
		if not l.pin_fx.is_empty():
			o["pinFx"] = l.pin_fx
		if l.signs:
			o["signs"] = true
		out_locks.append(o)
	return {"plan": out_plan, "locks": out_locks}


## Kayıttan: hour_abs verilmezse kaydın saati (at), o da yoksa son saat. Plan bozuksa ya da 48 sa'ten eskiyse sabit çapadan kurulur.
func from_dict(o: Dictionary, hour_abs: float = NAN) -> WeatherPlanner:
	var h := hour_abs
	if is_nan(h):
		var a: Variant = o.get("at")
		h = float(a) if (a is float or a is int) else (now if now > -INF else 0.0)
	var loaded: Array[WeatherSegment] = []
	for so: Variant in o.get("plan", []) if o.get("plan") is Array else []:
		var s := WeatherSegment.from_dict(so)
		if s:
			s.seed = _seg_seed(s.t0)
			loaded.append(s)
	var ok := not loaded.is_empty()
	for i in range(1, loaded.size()):
		if not ok:
			break
		ok = loaded[i].t0 == loaded[i - 1].t1 and loaded[i].t1 > loaded[i].t0
	locks.clear()
	prev = null
	if not ok or loaded[loaded.size() - 1].t1 <= h - 48.0:
		start(h)
	else:
		plan = loaded
		while plan.size() > 1 and plan[0].t1 <= h:
			prev = plan.pop_front()
	for lo: Variant in o.get("locks", []) if o.get("locks") is Array else []:
		if not lo is Dictionary or not (lo as Dictionary).get("id") is String or not WeatherData.has_type(str(lo.get("type", ""))):
			continue
		var d: Dictionary = lo
		var t0v: Variant = d.get("t0")
		var l := lock(str(d["id"]), {"type": d["type"], "params": d.get("params", {}), "keys": d.get("keys", []), "blend": 0.0,
			"until": d.get("until"), "pin_fx": d.get("pinFx", {}), "signs": bool(d.get("signs", false)), "after": str(d.get("after", "resume")),
			"at": float(t0v) if (t0v is float or t0v is int) else h})
		if l:
			var kv: Variant = d.get("k")
			l.k = clampf(float(kv) if (kv is float or kv is int) else 0.0, 0.0, 1.0)
			var bv: Variant = d.get("blend")
			l.blend = float(bv) if (bv is float or bv is int) else 6.0
	now = h
	if locks.is_empty():
		advance(h)
	return self


## Kayıt v2'nin weather bloğunun durağan denetimi (SaveBlocks.OWNERS → WeatherPlanner; godot.md §3.4, weather.md §12.7): {v, seed, zone,
## at, plan: [{type, t0, t1, src}], wet: [≤6 sayı], packs, locks}. Döner: "" geçer, yoksa ilk hata. Bilinmeyen tür ya da sırası bozuk
## plan hata değildir (yüklemede sabit çapadan yeniden kurulur); yapı bozuksa blok boş yuva sayılır.
static func validate_save_block(d: Dictionary) -> String:
	var v: Variant = d.get("v")
	if not (v is int or v is float) or int(v) < 1:
		return "weather.v yok"
	for key: String in ["seed", "at"]:
		if d.has(key) and not (d[key] is int or d[key] is float):
			return "weather.%s sayı değil" % key
	if d.has("plan") and not d["plan"] is Array:
		return "weather.plan dizi değil"
	for seg: Variant in d.get("plan", []):
		if not seg is Dictionary or not (seg as Dictionary).get("type") is String:
			return "weather.plan bölümü bozuk"
		var a: Variant = (seg as Dictionary).get("t0")
		var b: Variant = (seg as Dictionary).get("t1")
		if not (a is int or a is float) or not (b is int or b is float):
			return "weather.plan bölümünün sınırı yok"
	if d.has("wet"):
		if not d["wet"] is Array or (d["wet"] as Array).size() > 6:
			return "weather.wet bozuk"
		for x: Variant in d["wet"]:
			if not (x is int or x is float):
				return "weather.wet sayı değil"
	for key: String in ["packs", "struck"]:
		if d.has(key) and not d[key] is Dictionary:
			return "weather.%s sözlük değil" % key
	for key: String in ["locks", "said"]:
		if d.has(key) and not d[key] is Array:
			return "weather.%s dizi değil" % key
	return ""


# --- İç --------------------------------------------------------------------------------------------------------------

func _seg_seed(t0: float) -> int:
	return WeatherRng.hash32(seed, zone_hash, floori(t0 * 4.0))


func _push(seg: WeatherSegment) -> WeatherSegment:
	seg.seed = _seg_seed(seg.t0)
	plan.append(seg)
	return seg


func _cut_after(hour_abs: float) -> void:
	if not locks.is_empty() or plan.is_empty():
		return
	var i := 0
	while i < plan.size() - 1 and plan[i].t1 <= hour_abs:
		i += 1
	# Grup bölünmez: şimdiki bölümün grubunun sonuna dek kalır.
	while i < plan.size() - 1 and plan[i].g:
		i += 1
	plan.resize(i + 1)
	advance(hour_abs)


func _release_at(i: int, at_h: float, blend: float) -> void:
	var l := locks[i]
	locks.remove_at(i)
	if not locks.is_empty():
		if i == locks.size():
			var top := locks[locks.size() - 1]
			top.from = l.seg
			top.t0 = at_h
			top.blend_in = blend
		return
	_resume(l, at_h, blend)


## Kilit kalkınca kilidin türünden devam eder (§5.4); after «clear» ya da tür kimliği o türle açar.
func _resume(l: Lock, at_h: float, blend: float) -> void:
	var type := lock_type(l)
	plan = []
	prev = WeatherSegment.make(type, l.t0, at_h, WeatherSegment.SRC_STORY)
	_rng.reseed(WeatherRng.hash32(seed, zone_hash, floori(at_h * 4.0), SALT_RESUME))
	var first := -1
	if l.after == "clear":
		first = _i_clear
	elif l.after != "resume" and WeatherData.has_type(l.after):
		first = WeatherData.index_of(l.after)
	if first >= 0:
		var d := dur_of(first)
		var t1 := maxf(q(at_h + _rng.span(d[0], d[1])), q(q(at_h) + 1.0 / Q))
		_push(WeatherSegment.make(first, at_h, t1, WeatherSegment.SRC_SIM)).blend_s = blend
	else:
		var g := WeatherData.group[type]
		var fr: Dictionary = _fronts.get(type, {})
		if (g == WeatherData.GROUP_WET or g == WeatherData.GROUP_STORM) and fr.has("clear"):
			var clear: Array = fr["clear"]
			var ctype := WeatherData.index_of(str(clear[0]))
			if fr.has("showery") and _rng.next() < _showery:
				ctype = WeatherData.index_of(str(fr["showery"]))
			var t1 := maxf(q(at_h + _rng.span(float(clear[1]), float(clear[2]))), q(q(at_h) + 1.0 / Q))
			_push(WeatherSegment.make(ctype, at_h, t1, WeatherSegment.SRC_CLEAR, WeatherSegment.FRONT_CLEAR, type)).blend_s = blend
		else:
			var j := _choose(type, at_h)
			var n0 := plan.size()
			_emit(type, j, at_h)
			if plan.size() > n0:
				plan[n0].blend_s = blend
	if now > -INF:
		while plan[plan.size() - 1].t1 < now + HORIZON_H:
			_append()


## Kuyruğun sonuna bir cephe grubu: [hazırlık?, hedef (fırtınada parçalı), çözülme?] (§5.2–§5.4).
func _append() -> void:
	var last: WeatherSegment = plan[plan.size() - 1] if not plan.is_empty() else prev
	var t := last.t1
	_rng.reseed(WeatherRng.hash32(seed, zone_hash, floori(t * 4.0)))
	var j := _choose(last.type, t)
	_emit(last.type, j, t)


## w(j) = W[j] × D[eğri(j)][saat] / ortalamaSüre(j), izinli değilse 0 (§5.2).
func _choose(c: int, t: float) -> int:
	var hour := floori(hod(t))
	var total := 0.0
	for i in _n:
		var wv := _wbase[i]
		if not (wv > 0.0) or not _allowed(c, i, t):
			_w[i] = 0.0
			continue
		_w[i] = (wv * _curve[i][hour]) / _mean[i]
		total += _w[i]
	if not (total > 0.0):
		return _i_cloud if c == _i_clear else _i_clear
	var r := _rng.next() * total
	var pick := -1
	for i in _n:
		if _w[i] <= 0.0:
			continue
		pick = i
		r -= _w[i]
		if r <= 0.0:
			break
	return pick


## §5.4: açık ve bulut kendini izleyebilir, ötekiler izlemez; dolu ve Kara Boran seçilmez; sis 21:00–09:59'da açık, bulut ya da
## kapalıdan; tipi kar, yoğun kar, fırtına, kapalı, bulut ya da açıktan.
func _allowed(c: int, j: int, t: float) -> bool:
	if j == _i_hail or j == _i_kara:
		return false
	if j == c and j != _i_clear and j != _i_cloud:
		return false
	if _excluded[j]:
		return false
	if j == _i_fog:
		if c != _i_clear and c != _i_cloud and c != _i_overcast:
			return false
		var h := hod(t)
		if not (h >= 21.0 or h < 10.0):
			return false
	if j == _i_blizzard and not _blizzard_from[c]:
		return false
	return true


func _emit(c: int, j: int, t_start: float) -> void:
	var gc := WeatherData.group[c]
	var fr: Dictionary = _fronts.get(j, {})
	var grp: Array[WeatherSegment] = []
	var t := t_start
	var clear: Array = []
	var always := bool(fr.get("always", false))
	# Cephe (§5.3): kurudan ya da sisten ıslak ve fırtına hedefe hazırlık ve çözülme; tipi kardan gelmiyorsa kar hazırlığı zorunlu.
	if not fr.is_empty() and (gc == WeatherData.GROUP_DRY or c == _i_fog or (always and c != _i_snow and c != _i_heavy)):
		# Tipinin zorunlu kar hazırlığı kurudan ya da sisten geliyorsa önce karın kendi hazırlığı girer (W4).
		if always and (gc == WeatherData.GROUP_DRY or c == _i_fog):
			var wf: Dictionary = _fronts.get(WeatherData.index_of(str(fr["build"][0])), {})
			var wb: Array = wf["build"]
			var t1a := maxf(q(t + _rng.span(float(wb[1]), float(wb[2]))), q(q(t) + 1.0 / Q))
			var wtype := WeatherData.index_of(str(wb[0]))
			if wf.has("showery") and _rng.next() < _showery:
				wtype = WeatherData.index_of(str(wf["showery"]))
			grp.append(WeatherSegment.make(wtype, t, t1a, WeatherSegment.SRC_BUILD, WeatherSegment.FRONT_BUILD, j))
			t = t1a
		var build: Array = fr["build"]
		var btype := WeatherData.index_of(str(build[0]))
		if fr.has("showery") and _rng.next() < _showery:
			btype = WeatherData.index_of(str(fr["showery"]))
		var t1b := maxf(q(t + _rng.span(float(build[1]), float(build[2]))), q(q(t) + 1.0 / Q))
		grp.append(WeatherSegment.make(btype, t, t1b, WeatherSegment.SRC_BUILD, WeatherSegment.FRONT_BUILD, j))
		t = t1b
		clear = fr["clear"]
	elif WeatherData.sev[j] >= 3 and WeatherData.sev[c] < 3:
		# Islak türün içinden ağır bölüm: şu anki türün ağırlaşan göğü, 0,75–1 sa (§5.3, d2/core.md §3.4).
		var t1c := maxf(q(t + _rng.span(_heavy_prep[0], _heavy_prep[1])), q(q(t) + 1.0 / Q))
		grp.append(WeatherSegment.make(c, t, t1c, WeatherSegment.SRC_BUILD, WeatherSegment.FRONT_BUILD, j))
		t = t1c
	var dj := dur_of(j)
	var d := maxf(1.0 / Q, _rng.span(dj[0], dj[1]))
	if j == _i_fog:
		# Sis en geç 10:00'da dağılır (§4.3): bölüm kısaltılır.
		var day := floorf(t / 24.0) * 24.0
		var end := day + 10.0 if hod(t) < 10.0 else day + 34.0
		d = minf(d, end - t)
	if j == _i_thunder or j == _i_dry_storm:
		_storm(grp, j, t, d)
		t = grp[grp.size() - 1].t1
	else:
		var t1 := maxf(q(t + d), q(q(t) + 1.0 / Q))
		if j == _i_fog:
			t1 = minf(t1, floorf(t / 24.0) * 24.0 + (10.0 if hod(t) < 10.0 else 34.0))
		grp.append(WeatherSegment.make(j, t, t1, WeatherSegment.SRC_SIM))
		t = grp[grp.size() - 1].t1
	if not clear.is_empty():
		var ctype := WeatherData.index_of(str(clear[0]))
		if fr.has("showery") and _rng.next() < _showery:
			ctype = WeatherData.index_of(str(fr["showery"]))
		var t1d := maxf(q(t + _rng.span(float(clear[1]), float(clear[2]))), q(q(t) + 1.0 / Q))
		grp.append(WeatherSegment.make(ctype, t, t1d, WeatherSegment.SRC_CLEAR, WeatherSegment.FRONT_CLEAR, j))
	for i in grp.size():
		grp[i].g = 1 if i < grp.size() - 1 else 0
		_push(grp[i])


## Fırtına hücresi (§5.4): gök gürültülü fırtınanın %40'ına p_hail olasılıkla dolu sağanağı, yoksa %35 olasılıkla 0,5–1 sa sağanak
## girer; parçalar aynı hücrenin [t0, t1]'ini taşır.
func _storm(grp: Array[WeatherSegment], j: int, t: float, d: float) -> void:
	var ins := -1
	var ins_d := 0.0
	if j == _i_thunder:
		var hdur: Array = _hail_burst.get("dur", [0.15, 0.4])
		var pdur: Array = _hail_burst.get("downpour_dur", [0.5, 1.0])
		if _p_hail > 0.0 and not _excluded[_i_hail] and _rng.next() < _p_hail:
			ins = _i_hail
			ins_d = q(_rng.span(float(hdur[0]), float(hdur[1])))
		elif not _excluded[_i_downpour] and _rng.next() < float(_hail_burst.get("downpour", 0.35)):
			ins = _i_downpour
			ins_d = q(_rng.span(float(pdur[0]), float(pdur[1])))
	var end := maxf(q(t + d + ins_d), q(q(t) + (3.0 if ins >= 0 else 1.0) / Q))
	if ins < 0:
		var s := WeatherSegment.make(j, t, end, WeatherSegment.SRC_SIM)
		_cell(s, t, end)
		grp.append(s)
		return
	var a := maxf(q(t + d * float(_hail_burst.get("at", 0.4))), q(q(t) + 1.0 / Q))
	var b := minf(maxf(q(a + ins_d), q(a + 1.0 / Q)), q(end - 1.0 / Q))
	for part: Array in [[j, t, a], [ins, a, b], [j, b, end]]:
		var s := WeatherSegment.make(int(part[0]), float(part[1]), float(part[2]), WeatherSegment.SRC_SIM)
		_cell(s, t, end)
		grp.append(s)


static func _cell(s: WeatherSegment, a: float, b: float) -> void:
	s.has_cell = true
	s.cell0 = a
	s.cell1 = b


# --- Yardımcılar (saf) ----------------------------------------------------------------------------------------------

## Bölüm sınırları 0,05 sa'e oturur (3 oyun dk): kayıt kısa, gidiş dönüşte bit bit aynı.
static func q(x: float) -> float:
	return WeatherRng.js_round(x * Q) / Q


## Günün saati 0..24 (prototipin hod'u: aynı işlem sırası).
static func hod(h: float) -> float:
	return fmod(fmod(h, 24.0) + 24.0, 24.0)


## sine-in-out.
static func ease_k(u: float) -> float:
	return 0.5 - 0.5 * cos(PI * clampf(u, 0.0, 1.0))


## Plan kurulmadan sorulursa: açık, karışımsız.
static func idle_segment() -> WeatherSegment:
	if _idle == null:
		_idle = WeatherSegment.make(WeatherData.index_of(&"clear"), -INF, INF, WeatherSegment.SRC_SIM)
	return _idle


# --- Paylar ve ayar (saf) ---------------------------------------------------------------------------------------------

## Satırın ayarlı ağırlığı: gömülü (weights.json) ya da önbellekte, yoksa calibrate (yavaş; uyarır).
static func weights_for(p_climate: String, p_season: String, p_exclude: PackedStringArray, dur: Dictionary = {}) -> Dictionary:
	if dur.is_empty():
		var w := WeatherData.embedded_weights(p_climate, p_season, p_exclude)
		if not w.is_empty():
			return w
	var key := WeatherData.weight_key(p_climate, p_season, p_exclude) + ":" + JSON.stringify(dur)
	if _cal_cache.has(key):
		return _cal_cache[key]
	push_warning("[weather] %s için gömülü ağırlık yok: ayar koşuyor (tools/weather_calibrate.gd)" % key)
	var target_w := WeatherData.target_shares(p_climate, p_season, p_exclude)
	var w2 := calibrate(target_w, p_climate, p_season, p_exclude, dur)
	_cal_cache[key] = w2
	return w2


## Planlayıcıyı kilitsiz koşar (§5.6): pay (%; dolu gök gürültülü fırtınaya sayılır), saatler (tür sırasıyla), günde bölüm sayısı.
static func simulate(p_climate: String, p_season: String, p_exclude: PackedStringArray, p_weights: Dictionary, days: int, p_seed: int,
		p_zone: String = "sim", dur: Dictionary = {}) -> Dictionary:
	var p := WeatherPlanner.new({"climate": p_climate, "season": p_season, "exclude": p_exclude, "seed": p_seed, "zone": p_zone,
		"weights": p_weights, "dur": dur})
	var from := 0.0
	var to := float(days) * 24.0
	p.start(from)
	var n_types := WeatherData.count()
	var hours := PackedFloat64Array()
	hours.resize(n_types)
	var seen := PackedByteArray()
	seen.resize(n_types)
	var order: Array[int] = []
	var n := 0
	while true:
		if p.plan.is_empty():
			p._append()
		var seg := p.plan[0]
		if seg.t0 >= to:
			break
		var ov := minf(seg.t1, to) - maxf(seg.t0, from)
		if ov > 0.0:
			if not seen[seg.type]:
				seen[seg.type] = 1
				order.append(seg.type)
			hours[seg.type] += ov
		if seg.t0 >= from:
			n += 1
		p.prev = p.plan.pop_front()
	var share := {}
	var out_hours := {}
	var i_hail := WeatherData.index_of(&"hail")
	var span := to - from
	for i in order:
		var id := String(WeatherData.id_of(i))
		out_hours[id] = hours[i]
		var sid := "thunderstorm" if i == i_hail else id
		share[sid] = float(share.get(sid, 0.0)) + (hours[i] * 100.0) / span
	return {"share": share, "hours": out_hours, "per_day": float(n) / float(days)}


## Hedeften en büyük sapma (puan) ve türü.
static func max_deviation(share: Dictionary, p_target: Dictionary) -> Dictionary:
	var worst := 0.0
	var at_id := ""
	var ids := {}
	for id: String in share:
		ids[id] = true
	for id: String in p_target:
		ids[id] = true
	for id: String in ids:
		var d := absf(float(share.get(id, 0.0)) - float(p_target.get(id, 0.0)))
		if d > worst:
			worst = d
			at_id = id
	return {"dev": worst, "at": at_id}


## Ayarlı ağırlık (§5.6): W ← hedef; tur başına pay ← benzet(W, gün), W[j] ← W[j] × (hedef[j] / pay[j])^0,8. Dört kısa tur (800 gün)
## yaklaştırır, dört uzun tur (2000 gün) inceltir; sonuç uzun turların log-ortalamasıdır. GDScript'te bir satır ≈1–3 sn sürer: oyun
## gömülü ağırlığı okur (weights.json), bu işlev araçtır (tools/weather_calibrate.gd) ve sınamanın doğrulamasıdır.
static func calibrate(p_target: Dictionary, p_climate: String, p_season: String, p_exclude: PackedStringArray, dur: Dictionary = {},
		rounds: Array[int] = CAL_ROUNDS, p_seed: int = CAL_SEED) -> Dictionary:
	var ids: Array = p_target.keys()
	var w := p_target.duplicate()
	var log_sum := {}
	for id: String in ids:
		log_sum[id] = 0.0
	var avg := mini(CAL_AVG, rounds.size())
	for r in rounds.size():
		var res := simulate(p_climate, p_season, p_exclude, w, rounds[r], p_seed + r, "sim", dur)
		var share: Dictionary = res["share"]
		var nxt := {}
		for id: String in ids:
			var s := float(share.get(id, 0.0))
			nxt[id] = float(w[id]) * pow(float(p_target[id]) / s, 0.8) if s > 0.0 else float(w[id]) * 2.0
		w = nxt
		if r >= rounds.size() - avg:
			for id: String in ids:
				log_sum[id] = float(log_sum[id]) + log(float(w[id]))
	var out := {}
	for id: String in ids:
		out[id] = exp(float(log_sum[id]) / float(avg))
	return out
