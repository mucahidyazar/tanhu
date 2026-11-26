class_name WeatherSim
extends RefCounted
## Havanın yürütücüsü (saf; weather.md §2, §5–§8, §12; godot.md §3.1 adım 3): saat → planlayıcı, karışım, kilit, yön, bora, fırtına önü,
## kara sağanak, fırtına hücresi (şimşek, yıldırım, gecikmeli gök gürültüsü), dolu, ıslaklık, kar örtüsü ve kabuk, fx, işaretler ve ses
## verisi. Prototipin src/game/weather.js WeatherSystem'inin sahnesiz hâlidir: düğüm, ağaç, girdi ve duvar saati okumaz; oyuncunun yeri,
## kameranın yönü, zorluk, gece ve aday uzun nesneler Ctx ile verilir. Görünüm WeatherView'dur (scripts/systems/weather_view.gd).
##
## Session'ın 3. adımıdır (GameClock ve GameCalendar'dan sonra). Saat sınırını sahibi verir: GameClock.hour_passed → on_hour(h),
## GameClock.skipped → skip(from_h, to_h, long, sleep). Kayıt v2'nin weather bloğu to_dict() / from_dict()'tir (weather.md §12.7).
##   var sim := WeatherSim.new()
##   sim.setup("tanhu_camp", {}, hour_abs, day_n, seed)
##   sim.begin_roam()                      # kayıtta hava yoksa: 0,5 sa açık, sonra planlayıcı (§6.3)
##   sim.step(dt, hour_abs, ctx)           # her kare
##   sim.p, sim.fx, sim.flash_k            # okuyanlar

## Tür değişti: {from, to, sev}.
signal changed(info: Dictionary)
## Cephe HUD kanalını açtı (cephe başına bir kez): {type, in_h}.
signal front(info: Dictionary)
## Yıldırım indi (≤1,5 km): {x, z, target, kind, d, near, effect}.
signal strike(info: Dictionary)
## Gök gürültüsü geldi (d / 343 sn sonra): {d, x, z, band}.
signal thunder(info: Dictionary)
## Dolu sağanağı başladı: {size, minutes, x, z}.
signal hail(info: Dictionary)
## Kar Kabuğu başladı ya da bitti: {zone, on}.
signal crust_changed(info: Dictionary)
## Göl boğası böğürdü (weather.md §10.2, K35): göllü dünyada gök gürültülü fırtına ya da fırtına (gale) cephesinden ≤1 sa önce, cephe
## başına bir kez: {type, in_h}. Sesi okuyan çalar (far_rain kanalı, uzak).
signal lake_bull(info: Dictionary)

const S_PER_H := WeatherPlanner.S_PER_H
## Menüye dönüşte kimliğe, menüden inişte kayıttakine karışım (sn; §5.8, §9.12).
const TO_MENU_S := 1.7
const FROM_MENU_S := 2.4
## İşaret ve ses verisi 4 Hz.
const SLOW_S := 0.25
const SAID_MAX := 16
## Gök gürültüsü ≤1 km: at ürker, müzik iner.
const NEAR_M := 1000.0
## Hedef oyuncunun 40 m içindeyse 1,5 sn önce static_hum ve halka (§8.7).
const WARN_M := 40.0
const WARN_S := 1.5
## Oyuna dokunan iniş (aday seçimi, olay) bu uzaklığa dek.
const STRIKE_GAME_M := 1500.0
## Göl boğasının cepheleri (§10.2: GGF ve fırtına).
const LAKE_BULL_FRONTS := ["thunderstorm", "gale"]
## calm: oyuncunun 30 m çevresinde rüzgâr 0 (§6.1).
const CALM_R := 30.0
const THUNDER_POOL := 16
const DIFF_K := {"story": 1.5, "normal": 1.0, "hard": 0.75}
const GRACE_H := {"story": 1.5, "normal": 1.0, "hard": 1.0}
## Bölüm başında yön = hâkim ± 40° (§4.4); cephe hazırlığında yön 30–60° döner (§7.1 wind_shift).
const PREVAILING_JITTER := 40.0
const SHIFT_DEG := Vector2(30.0, 60.0)
const SALT_GUST := 0x6057
const SALT_FLASH := 0xf1a5
const SALT_SHIFT := 0x5e1f
const SALT_HAIL := 0x4a11
const SALT_SCRIPT := 0x51a5

## Sahibin her kare verdiği bağlam (yeniden kullanılır).
class Ctx:
	extends RefCounted
	var player_x := 0.0
	var player_y := 0.0
	var player_z := 0.0
	## Kameranın yatay bakışı (birim; x doğu, z güney).
	var cam_fwd_x := 0.0
	var cam_fwd_z := -1.0
	## Serbest Gez (Çocuk): tasarlanmış düşüş kadraja, Çocuğun 25 m'si boş, yapıya inmez.
	var child_mode := true
	var has_hp := false
	var mounted := false
	## Oyuncunun yerindeki barınak 0..1 (oda, yapı).
	var shelter := 0.0
	var ridge := 0.0
	var difficulty := "normal"
	var night := false
	var moon_up := false
	## Takvim günü (mevsim ve kar örtüsünün güneşi).
	var day_n := 0
	## Aday uzun nesneler (§8.7): [{id, kind, x, z, h, lone?}].
	var tall_things: Array = []
	## Oyun mu (play) yoksa Serbest Gez mi (roam)? Yolculuk bloğu ve yakın düşüş olasılığı.
	var play := false
	var bow_carried := false


var planner: WeatherPlanner
var wet := WetState.new()
var pack := SnowPack.new()
var cfg: Dictionary = {}
var zone := ""
var climate := ""
## Takvimin mevsimi ve planlayıcının satırı (kampta camp_*).
var season := ""
var row_season := ""
var seed := 1
## Yıldırım beklemesi: "zon:yapı" → hourAbs.
var struck: Dictionary = {}
## Söylenmiş işaretler (≤16).
var said: Array = []
var frozen := false
var calm_on := false
## Hava saati (gerçek sn; freeze durdurur).
var wt := 0.0
## Geliştirici: rüzgâr ve yön zorla (NAN: yok).
var dev_wind := NAN
var dev_from := NAN
## Karışmış parametre vektörü (WeatherData.P_*), yerinde.
var p := PackedFloat64Array()
var fx := WeatherFx.new()
var mix := WeatherPlanner.Mix.new()
var signs := WeatherSigns.State.new()
## Şimşek nabzı 0..1 ve yönü (oyuncudan, x doğu, z güney).
var flash_k := 0.0
var flash_dir := Vector2(0.0, -1.0)
## Kara sağanağın ışık çarpanı.
var light_k := 1.0
## Görünümün çizeceği şeritler (son 8; id artan sıra): {x, z, d, strokes, at (wt), near, id}. Görünüm son gördüğü id'den sonrakileri okur.
var bolts: Array[Dictionary] = []
var bolt_serial := 0
## Gök kubbesinde açıklık (Gök Açılır): {dir, radius, seconds, at} ya da boş.
var gap: Dictionary = {}
## Menüden inişte 0 → 1 (2,4 sn); menüye dönüşte 1 → 0 (1,7 sn). Görünüm kimlikle karıştırır.
var enter_k := 1.0
var leaving := false
## Kimlikte mi (menü, sinema, oluşturucu, Ev)?
var identity_on := true
## Ses verisi (§3.5, §10.4): {beds: [{id, gain, lp}], wind_k, wind_swap, quiet, birds, camp_day, music, drip}.
var audio: Dictionary = {}
## Son adımın süresi (ms; bütçe).
var last_ms := 0.0

var _type := 0
var _a := 0
var _b := 0
var _k := 1.0
var _last_type := -1
var _last_h := NAN
var _slow := 0.0
var _quiet_until := -INF
var _had_world := false
var _dir_from := 300.0
var _shift := 0.0
var _shift_sign := 1.0
var _flow := Vector2(0.871, 0.49)
var _gseg: WeatherSegment
var _grng := WeatherRng.new(1)
var _g_start := 0.0
var _g_end := -1.0
var _g_next := 0.0
var _gust := 0.0
var _cell_key := NAN
var _events: Array[WeatherStorm.Event] = []
var _ei := 0
var _pi := 0
var _cell_structs := 0
var _flash_t := -1.0
var _flash_p := 0.0
var _flash_n := 1
var _flash_cloud := false
var _flash_gaps := PackedFloat64Array([0.0, 0.1, 0.2, 0.3])
var _flash_peaks := PackedFloat64Array([1.0, 0.8, 0.7, 0.6])
var _tm_at := -INF
var _thunders: Array[Dictionary] = []
var _hail_seg: WeatherSegment
var _hail := {"size": "small", "minutes": 0}
var _scripted: Array[Dictionary] = []
var _pin: Dictionary = {}
var _pin_until := 0.0
var _front_t0 := NAN
var _bull_t0 := NAN
var _frac := PackedFloat64Array()
var _fo := WeatherFx.Opts.new()
var _po := SnowPack.Opts.new()
var _bow_wet: Dictionary = {}
var _sub: Dictionary = {}
var _i_clear := 0
var _i_hail := 0
var _ctx := Ctx.new()
var _ready := false
## fx.front'un yeniden kullanılan sözlükleri (kare başına ayırma yok).
var _front_d := {"type": "", "in_h": 0.0}
var _hail_white := 0.0
var _no_front := {}


func _init() -> void:
	p.resize(WeatherData.P_COUNT)
	WeatherFx.blend(WeatherData.params_of(WeatherData.index_of(&"clear")), WeatherData.params_of(WeatherData.index_of(&"clear")), 1.0, p)
	_frac.resize(WeatherData.count())
	_i_clear = WeatherData.index_of(&"clear")
	_i_hail = WeatherData.index_of(&"hail")
	_bow_wet = WeatherData.section("bow_wet")
	_sub = WeatherData.section("sub")
	for i in THUNDER_POOL:
		_thunders.append({"live": false, "at": 0.0, "d": 0.0, "x": 0.0, "z": 0.0})
	fx.identity()
	audio = _identity_audio()


# --- Kurulum ---------------------------------------------------------------------------------------------------------

## Dünya: zonun ayarı (spec yazılmışsa o kazanır), takvimin mevsimi, sabit çapalı plan. had_world ise varış lütfu (§5.7).
func setup(p_zone: String, spec: Dictionary, hour_abs: float, day_n: int, p_seed: int, difficulty: String = "normal") -> WeatherSim:
	zone = p_zone
	cfg = WeatherData.zone_config(p_zone, spec)
	climate = str(cfg["climate"])
	seed = p_seed & WeatherRng.MASK
	season = String(GameCalendar.season(day_n))
	row_season = WeatherData.season_row(cfg, season)
	wet.accumulate = WeatherData.accumulates(cfg, season)
	planner = _make_planner()
	planner.start(hour_abs)
	if _had_world:
		planner.arrive(hour_abs, float(GRACE_H.get(difficulty, 1.0)))
		_quiet_until = hour_abs + 0.5
	_had_world = true
	_last_h = hour_abs
	_last_type = -1
	_cell_key = NAN
	_gseg = null
	_hail_seg = null
	for th in _thunders:
		th["live"] = false
	_ready = true
	return self


## Kayıtta hava yoksa ilk Serbest Gez (§6.3): roam_first 0,5 sa açık, sonra planlayıcı; ıslaklık ve kar örtüsü sıfır.
func begin_roam(hour_abs: float) -> void:
	if planner == null:
		return
	planner.start(hour_abs)
	planner.lock("roam_first", {"type": "clear", "until": hour_abs + 0.5, "blend": 0.0, "after": "resume", "at": hour_abs})
	wet.reset()
	pack.reset()
	_last_h = hour_abs


func ready() -> bool:
	return _ready and planner != null


func _make_planner() -> WeatherPlanner:
	return WeatherPlanner.new({"climate": climate, "season": row_season, "exclude": _exclude(), "seed": seed, "zone": zone,
		"dur": cfg.get("dur", {})})


## camp3'ün ocağı yanana dek (§6.3) sev ≥3 türler dışlanır; spec ve zon dışlamaları her zaman. Ocak sahibin structure_done'ıdır:
## yapı sistemi yoksa (kampta camp3 henüz kurulmuyor) korunacak an yoktur, tablo açıktır.
var structure_done: Callable


func _exclude() -> PackedStringArray:
	var out := PackedStringArray(cfg.get("exclude", PackedStringArray()))
	var qh := str(cfg.get("quiet_heavy", ""))
	if not qh.is_empty() and not _ctx.play and structure_done.is_valid() and not bool(structure_done.call(qh)):
		for i in WeatherData.count():
			var id := String(WeatherData.id_of(i))
			if WeatherData.sev[i] >= 3 and not out.has(id):
				out.append(id)
	return out


func refresh_exclude() -> void:
	if planner:
		planner.set_exclude(_exclude(), planner.now)


# --- Kare ----------------------------------------------------------------------------------------------------------

## Bir kare: dt gerçek sn (saat durunca da görünüm devinir; hava saati yalnız freeze ile durur), hour_abs oyun saati.
func step(dt: float, hour_abs: float, ctx: Ctx = null) -> void:
	if not ready():
		return
	var t0 := Time.get_ticks_usec()
	if ctx:
		_ctx = ctx
	var h := hour_abs
	var dt_h := 0.0 if is_nan(_last_h) else h - _last_h
	if dt_h > 0.5:
		# Atlama olaysız geldiyse: analitik ilerleme.
		_advance_skip(_last_h, h, false, false)
		dt_h = 0.0
	elif not (dt_h > 0.0):
		dt_h = 0.0
	_last_h = h
	if not frozen:
		wt += dt
	if leaving:
		enter_k = maxf(0.0, enter_k - dt / TO_MENU_S)
	elif enter_k < 1.0:
		enter_k = minf(1.0, enter_k + dt / FROM_MENU_S)
	_season_check(h)
	planner.advance(h)
	planner.at(h, mix)
	_a = mix.a.type
	_b = planner.lock_type(mix.lock) if mix.lock else mix.b.type
	_k = mix.k
	_type = _b if _k >= 0.5 else _a
	var dry := bool(planner.row.get("dry", false))
	WeatherFx.blend(WeatherData.params_of(_a, dry), WeatherData.params_of(_b, dry), _k, p)
	var lock := mix.lock
	if lock:
		WeatherFx.apply_lock(lock, p)
	if not is_nan(dev_wind):
		p[WeatherData.P_WIND] = dev_wind
	if not _pin.is_empty() and wt < _pin_until:
		for key: String in _pin:
			var i := WeatherData.PARAM_KEYS.find(key)
			if i >= 0:
				p[i] = float(_pin[key])
	var seg := mix.seg
	_direction(lock)
	_gust_tick(seg, h)
	_gust_front(seg, h)
	_squall(lock, h)
	_storm_tick(seg, h)
	_thunder_tick()
	var i := _scripted.size() - 1
	while i >= 0:
		if wt >= float(_scripted[i]["at"]):
			var e: WeatherStorm.Event = _scripted[i]["e"]
			_scripted.remove_at(i)
			_fire(e)
		i -= 1
	_hail_tick(seg, h)
	wet.step(dt_h, p, _ctx.night, season == "summer", 1 if WeatherData.accumulates(cfg, season) else 0)
	var bow_rate := float(_bow_wet.get(String(WeatherData.id_of(_type)), 0.0))
	wet.step_bow(dt, bow_rate, _ctx.bow_carried, false, _ctx.shelter >= 0.5, false)
	_write_fx(h, lock)
	# Dolu beyazlığı (§9.8): dolu sürerken saatte +4 birikir, sonra 0,5 sa'te erir.
	_hail_white = clampf(_hail_white + (4.0 if _type == _i_hail else -2.0) * dt_h, 0.0, 1.0)
	fx.hail_white = _hail_white
	if _type != _last_type:
		var from := _last_type
		_last_type = _type
		if from >= 0:
			changed.emit({"from": WeatherData.id_of(from), "to": WeatherData.id_of(_type), "sev": WeatherData.sev[_type]})
	_slow -= dt
	if _slow <= 0.0:
		_slow = SLOW_S
		_write_signs(h, lock)
		_write_audio(h)
	last_ms = (Time.get_ticks_usec() - t0) / 1000.0


func _write_fx(h: float, lock: WeatherPlanner.Lock) -> void:
	var o := _fo
	o.a = _a
	o.b = _b
	o.k = _k
	o.type = _type
	if signs.has_front:
		_front_d["type"] = signs.front_type
		_front_d["in_h"] = signs.front_in_h
		o.front = _front_d
	else:
		o.front = _no_front
	o.dir_x = _flow.x
	o.dir_z = _flow.y
	o.gust = _gust
	flash_k = _flash_value()
	o.flash_k = flash_k
	o.thunder_mask = WeatherFx.thunder_mask_at(wt - _tm_at)
	o.calm = calm_on
	o.pin = lock.pin_fx if lock else {}
	o.night = _ctx.night
	o.moon_up = _ctx.moon_up
	o.accumulate = WeatherData.accumulates(cfg, season)
	o.snow_felt = float(cfg.get("snow_felt", 0.5))
	o.fog_vis = INF
	o.pack = pack
	o.hail = _hail if _type == _i_hail else {}
	o.strike_risk = _phase_risk(h) if (not is_nan(_cell_key) and WeatherData.strike[_type] != WeatherData.STRIKE_NONE) else 0.0
	o.snow_ground = o.accumulate and (wet.snow > 0.3 or pack.snowpack > 0.1)
	fx.write(p, wet, o)
	if lock:
		var sf := WeatherFx.lock_value(lock, "snow_fresh")
		if not is_nan(sf):
			fx.snow_fresh = sf


## Kimliğe döner (menü, Yeni Oyun, oluşturucu, Ev; §9.12): fade > 0 ise görünüm o sürede karışır.
func to_identity(fade: float = TO_MENU_S) -> void:
	identity_on = true
	leaving = fade > 0.0
	if fade <= 0.0:
		enter_k = 0.0
	fx.identity()
	audio = _identity_audio()
	signs.clear()
	_gust = 0.0
	_flash_t = -1.0
	flash_k = 0.0
	bolts.clear()
	for th in _thunders:
		th["live"] = false


## Menüden oyuna iniş: görünüm kimlikten kayıttakine 2,4 sn'de karışır.
func from_identity(instant: bool = false) -> void:
	identity_on = false
	leaving = false
	enter_k = 1.0 if instant else 0.0


# --- Kilit yüzü (§6.1) ---------------------------------------------------------------------------------------------

func lock(id: String, opts: Dictionary) -> WeatherPlanner.Lock:
	if planner == null:
		return null
	var o := opts.duplicate()
	o["at"] = planner.now
	return planner.lock(id, o)


func release(id: String, blend: float = 6.0) -> bool:
	return planner.release(id, blend, planner.now) if planner else false


func locked(id: String) -> bool:
	return planner != null and planner.has_lock(id)


func progress(id: String, k: float) -> void:
	if planner:
		planner.progress(id, k)


## Kısa iğne (gerçek sn): {wind: 0} gibi (Gök Açılır).
func pin(params: Dictionary, seconds: float) -> void:
	_pin = params
	_pin_until = wt + maxf(seconds, 0.0)


## Yağış ve rüzgâr saati durur (Donuk Kamp).
func freeze(on: bool) -> void:
	frozen = on


func calm(on: bool) -> void:
	calm_on = on


## Senaryolu şimşek: nabız; yön oyuncudan (x, z).
func flash(power: float = 1.0, dir_xz: Vector2 = Vector2.ZERO) -> void:
	_start_flash(clampf(power, 0.0, 1.0), false, 1 + (WeatherRng.hash32(seed, floori(wt * 1000.0), SALT_SCRIPT) % 3))
	if dir_xz != Vector2.ZERO:
		flash_dir = dir_xz


## Senaryolu yıldırım: [x, z] ya da "near" (kadrajda, Çocuktan 30–70 m). telegraph: hedef 40 m içindeyse 1,5 sn uyarı. strokes: dönüş
## vuruşu (§9.6: 1–4; senaryolu iniş 3).
func strike_at(x: float, z: float, telegraph: bool = true, strokes: int = 3) -> void:
	var e := WeatherStorm.Event.new()
	e.ground = true
	e.strokes = clampi(strokes, 1, 4)
	e.near = true
	e.u = 0.5
	e.v = 0.5
	e.wx = x
	e.wz = z
	if telegraph and _dist(x - _ctx.player_x, z - _ctx.player_z) <= WARN_M:
		_warn(e)
		_scripted.append({"at": wt + WARN_S, "e": e})
	else:
		_fire(e)


## Geliştirme (W16 karesi): kadrajın ortasına yakın senaryolu yıldırım (6 m ileride, 11 m yanda): gövde üst kenardan ekranın ortasına
## iner. Oyunun tasarlanmış düşüşü değildir (o Çocuktan ≥25 m'dir); karede şeridi göstermek içindir. strokes 1: nabız tek vuruştur,
## şimşek 0,19 sn'de söner, şerit 0,35 sn görünür (karanlık fırtınada şerit karesi).
func strike_dev_frame(strokes: int = 3) -> void:
	var l := maxf(sqrt(_ctx.cam_fwd_x * _ctx.cam_fwd_x + _ctx.cam_fwd_z * _ctx.cam_fwd_z), 1e-6)
	var fx := _ctx.cam_fwd_x / l
	var fz := _ctx.cam_fwd_z / l
	strike_at(_ctx.player_x + fx * 6.0 - fz * 11.0, _ctx.player_z + fz * 6.0 + fx * 11.0, false, strokes)


func strike_near() -> void:
	var r := WeatherRng.unit(seed, floori(wt * 1000.0), 0x5ea7)
	var pt := WeatherStorm.near_point_frame(_ctx.player_x, _ctx.player_z, _ctx.cam_fwd_x, _ctx.cam_fwd_z, 0.5, r)
	strike_at(pt[0], pt[1], false)


## Kubbede açıklık (Gök Açılır, Kara Boran yıldızı).
func open_gap(dir_xz: Vector2, radius: float, seconds: float) -> void:
	gap = {"dir": dir_xz, "radius": radius, "seconds": seconds, "at": wt}


## Geliştirici ve sınama: zemindeki dolu beyazlığı (0..1).
func set_hail_white(v: float) -> void:
	_hail_white = clampf(v, 0.0, 1.0)


## Geliştirici ve sınama: türü zorla (dev kilidi; hold false ise türün ortalama süresinde kalkar).
func force(type: String, hold: bool = true, blend: float = 6.0) -> bool:
	if not WeatherData.has_type(type) or planner == null:
		return false
	var i := WeatherData.index_of(type)
	var until: Variant = null if hold else planner.now + (WeatherData.dur_lo[i] + WeatherData.dur_hi[i]) / 2.0
	return lock("dev", {"type": type, "blend": blend, "until": until, "after": "resume"}) != null


# --- Okuyanların yüzü -----------------------------------------------------------------------------------------------

## m/sn vektör (x doğu, z güney): anlık bora dahil, barınak ve sükûnet uygulanmış.
func wind_at(x: float, z: float, shelter: float = 0.0) -> Vector2:
	var speed := (fx.wind + fx.gust) * (1.0 - clampf(shelter, 0.0, 1.0))
	if calm_on and _dist(x - _ctx.player_x, z - _ctx.player_z) <= CALM_R:
		speed = 0.0
	return Vector2(fx.dir_x * speed, fx.dir_z * speed)


## Şimdiki tür (karışımın baskın ucu).
func type_id() -> StringName:
	return WeatherData.id_of(_type)


func type_index() -> int:
	return _type


## Karışan iki tür ve oran.
func blend_state() -> Vector3i:
	return Vector3i(_a, _b, int(_k * 1000.0))


## [{type, at, sev}]: HUD ve gök okuma.
func next_events(hours: float = 6.0) -> Array[Dictionary]:
	return planner.next_events(hours) if planner else []


## Gök okuma satırı (§7.5): {key, type, noun, at, end}.
func sky_read(hours: float = 6.0) -> Dictionary:
	var r := WeatherSigns.sky_read(planner.plan if planner else [] as Array[WeatherSegment], planner.now if planner else 0.0, hours)
	if r["kind"] == "none":
		return {"key": "weather.read.none", "type": "", "at": 0.0, "end": 0.0}
	return {"key": "weather.read.two" if r["kind"] == "two" else "weather.read.one", "type": r["type"], "noun": "weather.noun.%s" % r["type"], "at": r["at"], "end": r["end"]}


# --- Saat sınırları --------------------------------------------------------------------------------------------------

## Saat başı (§5.9): h geçilen saat sınırı (hourAbs tam sayı). Kar örtüsü ve kabuk geçen saatin türleriyle ilerler.
func on_hour(h: float) -> void:
	if not ready():
		return
	_pack_hour(h - 1.0, false)
	if not str(cfg.get("quiet_heavy", "")).is_empty():
		refresh_exclude()


## Atlama (§2, time.md §7.4): planlayıcı ileri, ıslaklık analitik, kar örtüsü saat saat; uzun atlamada olay yayılmaz.
func skip(from_h: float, to_h: float, long: bool = false, sleep: bool = false) -> Dictionary:
	if not ready() or not (to_h > from_h):
		return {}
	var r := _advance_skip(from_h, to_h, long, sleep)
	_last_h = to_h
	return r


func _advance_skip(from_h: float, to_h: float, long: bool, sleep: bool) -> Dictionary:
	var worst := -1
	var h := from_h
	var crust_before := pack.crust > 0
	var night_p := PackedFloat64Array()
	while h < to_h - 1e-9:
		var nxt := minf(to_h, floorf(h) + 1.0)
		planner.advance(h)
		var m := planner.at(h + (nxt - h) * 0.5)
		var t := planner.lock_type(m.lock) if m.lock else m.b.type
		var hd := WeatherPlanner.hod(h)
		wet.skip(nxt - h, WeatherData.params_of(t), hd < 5.5 or hd >= 19.0, season == "summer", 1 if WeatherData.accumulates(cfg, season) else 0)
		if worst < 0 or WeatherData.sev[t] > WeatherData.sev[worst]:
			worst = t
		if absf(nxt - roundf(nxt)) < 1e-9:
			_pack_hour(roundf(nxt) - 1.0, true)
		h = nxt
	planner.advance(to_h)
	_cell_key = NAN
	for th in _thunders:
		th["live"] = false
	var out := {"worst": WeatherData.id_of(worst) if worst >= 0 else &"", "sleep": sleep}
	if not long and crust_before != (pack.crust > 0):
		crust_changed.emit({"zone": zone, "on": pack.crust > 0})
	return out


## Yüklü zonun kar örtüsü ve kabuğu (kar tutmayan mevsimde yok).
func _pack_hour(h: float, skipping: bool) -> void:
	if not WeatherData.accumulates(cfg, season):
		return
	var top := planner.top_lock()
	if top:
		_frac.fill(0.0)
		_frac[planner.lock_type(top)] = 1.0
	else:
		SnowPack.type_hours(planner.plan, h, h + 1.0, _frac, planner.prev)
	var was := pack.crust > 0
	_po.season = StringName(season)
	_po.lat = float(cfg.get("lat", 45.0))
	_po.dec = Daylight.solar_dec(float(GameCalendar.doy(_ctx.day_n)))
	_po.seed = seed
	_po.zone_hash = WeatherRng.str_hash(zone)
	pack.hour(h, _frac, _po)
	if not skipping and was != (pack.crust > 0):
		crust_changed.emit({"zone": zone, "on": pack.crust > 0})


func _season_check(h: float) -> void:
	var s := String(GameCalendar.season(_ctx.day_n))
	if s == season:
		return
	var prev := season
	season = s
	var rs := WeatherData.season_row(cfg, s)
	wet.accumulate = WeatherData.accumulates(cfg, s)
	if rs != row_season:
		row_season = rs
		planner.set_row(climate, rs, h)
	# Kar örtüsü yaz ve güz başında 0 (§5.9).
	if not prev.is_empty() and (s == "summer" or s == "autumn"):
		pack.reset()


# --- İç: yön, bora, fırtına önü, kara sağanak -------------------------------------------------------------------------

## Yön (§4.4): hâkim ± 40° (bölüm tohumu); yazın güneydoğu yeli, fırtınalar ve toz kendi yönünden; cepheden 1 sa önce 30–60° döner.
func _direction(lock: WeatherPlanner.Lock) -> void:
	var wind_row: Dictionary = planner.row.get("wind", {"dir": 290})
	var from: float
	if lock:
		var v := WeatherFx.lock_value(lock, "dir_from")
		from = v if not is_nan(v) else float(wind_row.get("dir", 290))
	else:
		from = _angle_lerp(_dir_of(wind_row, mix.a, _a), _dir_of(wind_row, mix.b, _b), _k)
	from += _shift * _shift_sign
	if not is_nan(dev_from):
		from = dev_from
	_dir_from = from
	_flow = WeatherFx.flow_of(from)


func _dir_of(wind_row: Dictionary, seg: WeatherSegment, t: int) -> float:
	var base := float(wind_row.get("dir", 290))
	if seg == null:
		return base
	var u := float((seg.seed >> 8) & 0xffff) / 65536.0
	if wind_row.has("alt") and float((seg.seed >> 4) & 0xff) / 256.0 < float(wind_row.get("alt_p", 0.0)):
		base = float(wind_row["alt"])
	var id := String(WeatherData.id_of(t))
	if wind_row.has("storm") and (id == "thunderstorm" or id == "dry_storm" or id == "hail"):
		base = float(wind_row["storm"])
	if wind_row.has("dust") and id == "dust_storm":
		base = float(wind_row["dust"])
	return base + (u * 2.0 - 1.0) * PREVAILING_JITTER


static func _angle_lerp(a: float, b: float, k: float) -> float:
	return a + (fmod(fmod(b - a, 360.0) + 540.0, 360.0) - 180.0) * k


## Bora (§3.2): türün içinde 20–60 sn'de bir 3–6 sn, rüzgâr ×1,6; kardan önce (gust_rise) 20–30 sn'de bir. Çizelge bölüm tohumundan,
## hava saati saniyesiyle: yükleme aynı borayı verir.
func _gust_tick(seg: WeatherSegment, h: float) -> void:
	var g: Dictionary = _sub.get("gust", {})
	var rise := signs.entry("gust_rise") != null
	var inside := String(WeatherData.id_of(_type)) in (g.get("in", []) as Array)
	if seg == null or (not inside and not rise):
		_gust = 0.0
		_gseg = null
		return
	var s := (h - seg.t0) * S_PER_H
	var every: Array = g.get("rise", [20, 30]) if rise else g.get("every", [20, 60])
	var dur: Array = g.get("dur", [3, 6])
	if _gseg != seg:
		_gseg = seg
		_grng.reseed(WeatherRng.hash32(seg.seed, SALT_GUST, 0, 0))
		_g_next = _grng.span(float(every[0]), float(every[1])) * 0.5
		_g_end = -1.0
	var guard := 0
	while _g_next <= s and guard < 512:
		guard += 1
		_g_start = _g_next
		_g_end = _g_start + _grng.span(float(dur[0]), float(dur[1]))
		_g_next = _g_start + _grng.span(float(every[0]), float(every[1]))
	var env := sin(PI * (s - _g_start) / (_g_end - _g_start)) if (s >= _g_start and s <= _g_end) else 0.0
	_gust = p[WeatherData.P_WIND] * (float(g.get("k", 1.6)) - 1.0) * env * (0.6 if rise and not inside else 1.0)


## Fırtına önü (§3.2): hücrenin ilk 0,1 sa'i (15 sn) rüzgâr 16 m/sn, yön 45° döner.
func _gust_front(seg: WeatherSegment, h: float) -> void:
	if seg == null or not seg.has_cell or seg.t0 != seg.cell0:
		return
	var id := String(seg.type_id())
	if id != "thunderstorm" and id != "dry_storm":
		return
	var gf: Dictionary = _sub.get("gust_front", {})
	var age := h - seg.t0
	if age < 0.0 or age > float(gf.get("hours", 0.1)):
		return
	p[WeatherData.P_WIND] = maxf(p[WeatherData.P_WIND], float(gf.get("wind", 16.0)))
	_dir_from += float(gf.get("turn_deg", 45.0))
	_flow = WeatherFx.flow_of(_dir_from)


## Kara sağanak (§3.2): kilidin squalls sayısı kadar, 25 sn, aralarında ≥40 sn; görüş 20 m, rüzgâr +6, ışık ×0,6. Kör rüzgâr görüş 15 m.
func _squall(lock: WeatherPlanner.Lock, h: float) -> void:
	light_k = 1.0
	if lock == null or String(WeatherData.id_of(lock.type)) != "kara_boran":
		return
	var sq: Dictionary = _sub.get("squall", {})
	var n_v := WeatherFx.lock_value(lock, "squalls")
	var n := 0 if is_nan(n_v) else int(n_v)
	var s := (h - lock.t0) * S_PER_H
	var span := float(sq.get("s", 25))
	for i in n:
		var at := 30.0 + i * (span + float(sq.get("gap", 40)) + 10.0)
		if s >= at and s < at + span:
			p[WeatherData.P_VIS] = minf(p[WeatherData.P_VIS], float(sq.get("vis", 20)))
			p[WeatherData.P_WIND] += float(sq.get("wind", 6))
			light_k = float(sq.get("light", 0.6))
	var wo := WeatherFx.lock_value(lock, "whiteout")
	if not is_nan(wo) and wo > 0.0:
		p[WeatherData.P_VIS] = minf(p[WeatherData.P_VIS], float((_sub.get("whiteout", {}) as Dictionary).get("vis", 15)))


# --- İç: fırtına hücresi, yıldırım, gök gürültüsü, şimşek nabzı ---------------------------------------------------------

func _phase_risk(h: float) -> float:
	var seg := mix.seg
	if _events.is_empty() or seg == null or not seg.has_cell:
		return 0.0
	var u := (h - seg.cell0) / maxf(1e-6, seg.cell1 - seg.cell0)
	return 1.0 if (u >= 0.25 and u < 0.75) else 0.4


## Fırtına hücresi (§8.7): şimşekler hücre tohumundan; yere inenlerin hedefi 1,5 sn önce seçilir (uyarı), sonra iner.
func _storm_tick(seg: WeatherSegment, h: float) -> void:
	if seg == null or not seg.has_cell:
		_cell_key = NAN
		return
	if WeatherData.strike[_type] == WeatherData.STRIKE_NONE:
		return
	if _cell_key != seg.cell0:
		_cell_key = seg.cell0
		_cell_structs = 0
		var near := 0.6 if not _ctx.play else (0.25 if _ctx.shelter < 0.5 else 0.0)
		var rate := p[WeatherData.P_STORM] if p[WeatherData.P_STORM] > 0.0 else 1.0
		WeatherStorm.storm_events(seg.cell0, seg.cell1, seed, WeatherRng.str_hash(zone), _flow.x, _flow.y, near, rate, _events)
		var s0 := (h - seg.cell0) * S_PER_H
		var i := 0
		while i < _events.size() and _events[i].t < s0 - 0.5:
			i += 1
		_ei = i
		_pi = i
	var s := (h - seg.cell0) * S_PER_H
	while _pi < _events.size() and _events[_pi].t <= s + WARN_S:
		var e := _events[_pi]
		_pi += 1
		if e.ground:
			_prepare(e)
	while _ei < _events.size() and _events[_ei].t <= s:
		var e := _events[_ei]
		_ei += 1
		if e.ground:
			_fire(e)
		else:
			_cloud_flash(e)


## Yere inen şimşeğin yeri ve hedefi (§8.7): tasarlanmış düşüş kadraja (Serbest Gez) ya da oyuncunun 0–45 m'sine (oyun); doğal düşüş
## hücreden. Çocuğun 25 m'si boş kalır; aday uzun olandır; hedef 40 m içindeyse 1,5 sn önce uyarı.
func _prepare(e: WeatherStorm.Event) -> void:
	var gx := _ctx.player_x
	var gz := _ctx.player_z
	var child := _ctx.child_mode or not _ctx.play
	var px := 0.0
	var pz := 0.0
	if e.near and child:
		var pt := WeatherStorm.near_point_frame(gx, gz, _ctx.cam_fwd_x, _ctx.cam_fwd_z, e.u, e.v)
		px = pt[0]
		pz = pt[1]
	elif e.near:
		var r := 45.0 * sqrt(e.v)
		var th := e.u * PI * 2.0
		px = gx + cos(th) * r
		pz = gz + sin(th) * r
	else:
		px = gx + e.x
		pz = gz + e.z
	if child:
		var dx := px - gx
		var dz := pz - gz
		var d0 := _dist(dx, dz)
		if d0 < 25.0:
			var sc := (25.0 + 5.0) / maxf(1e-3, d0)
			px = gx + dx * sc
			pz = gz + dz * sc
	e.wx = px
	e.wz = pz
	e.target = {}
	e.d = _dist(px - gx, pz - gz)
	if e.d <= STRIKE_GAME_M:
		var cands: Array = []
		for c: Variant in _ctx.tall_things:
			# Serbest Gez'de kampın yapılarına inmez: yalnız ağaç ve direk (§8.7).
			if c is Dictionary and (not child or str(c.get("kind", "")) in ["tree", "pole"]):
				cands.append(c)
		var rules := {"child": {"x": gx, "z": gz} if child else {}, "difficulty": _ctx.difficulty, "now": planner.now,
			"struck": _struck_for(), "structures": _cell_structs == 0 if WeatherData.pack_zones().has(zone) else true}
		if not child and _ctx.has_hp:
			rules["player"] = {"x": gx, "z": gz, "mounted": _ctx.mounted, "open": _ctx.shelter < 0.5, "ridge": _ctx.ridge}
		var target := WeatherStorm.strike_pick(cands, px, pz, rules)
		if not target.is_empty():
			e.target = target
			if target.get("kind") != "player":
				e.wx = float(target["x"])
				e.wz = float(target["z"])
			else:
				e.wx = gx
				e.wz = gz
			e.d = _dist(e.wx - gx, e.wz - gz)
	e.warned = false
	if e.d <= WARN_M:
		_warn(e)


func _struck_for() -> Dictionary:
	var out := {}
	var pre := zone + ":"
	for key: String in struck:
		if key.begins_with(pre):
			out[key.substr(pre.length())] = struck[key]
	return out


func _warn(e: WeatherStorm.Event) -> void:
	if e.warned:
		return
	e.warned = true


## İniş: olay (etkiler okuyanındır), şimşek nabzı, şerit; gök gürültüsü d / 343 sn sonra.
func _fire(e: WeatherStorm.Event) -> void:
	if is_nan(e.wx):
		_prepare(e)
	var d := _dist(e.wx - _ctx.player_x, e.wz - _ctx.player_z)
	_start_flash(1.0 if d <= 2000.0 else 0.3, false, e.strokes)
	flash_dir = Vector2(e.wx - _ctx.player_x, e.wz - _ctx.player_z)
	if d <= STRIKE_GAME_M:
		var target := e.target
		var eff := WeatherStorm.strike_effect(target if not target.is_empty() else {"kind": "ground"}, fx.wet_felt, String(fx.type) == "dry_storm", _ctx.difficulty)
		var kind := str(target.get("kind", "ground"))
		if kind in ["structure", "tower", "pole"]:
			struck["%s:%s" % [zone, str(target.get("key", target.get("id", "")))]] = planner.now
			if kind != "pole":
				_cell_structs += 1
		strike.emit({"x": e.wx, "z": e.wz, "target": target.get("id"), "kind": kind, "d": d, "near": e.near, "effect": eff})
	bolt_serial += 1
	bolts.append({"x": e.wx, "z": e.wz, "d": d, "strokes": e.strokes, "at": wt, "near": e.near, "id": bolt_serial})
	if bolts.size() > 8:
		bolts.pop_front()
	_queue_thunder(d, e.wx, e.wz)


func _cloud_flash(e: WeatherStorm.Event) -> void:
	var d := _dist(e.x, e.z)
	_start_flash(0.6 if d <= 2000.0 else 0.3, true, e.strokes)
	flash_dir = Vector2(e.x, e.z)
	_queue_thunder(d, _ctx.player_x + e.x, _ctx.player_z + e.z)


func _queue_thunder(d: float, x: float, z: float) -> void:
	if d > WeatherStorm.HEAR_M:
		return
	for th in _thunders:
		if not th["live"]:
			th["live"] = true
			th["at"] = wt + WeatherStorm.thunder_delay(d)
			th["d"] = d
			th["x"] = x
			th["z"] = z
			return


func _thunder_tick() -> void:
	for th in _thunders:
		if not th["live"] or wt < float(th["at"]):
			continue
		th["live"] = false
		var d := float(th["d"])
		var band := WeatherStorm.thunder_band(d)
		if band.is_empty():
			continue
		if d <= WeatherStorm.MASK_M:
			_tm_at = wt
		thunder.emit({"d": d, "x": th["x"], "z": th["z"], "band": band})


func _start_flash(power: float, cloud: bool, strokes: int) -> void:
	_flash_t = wt
	_flash_p = power
	_flash_cloud = cloud
	_flash_n = clampi(strokes, 1, 4)
	var t := 0.0
	for i in 4:
		var r := WeatherRng.unit(seed, floori(wt * 1000.0), i, SALT_FLASH)
		_flash_gaps[i] = t
		_flash_peaks[i] = 1.0 if i == 0 else 0.6 + 0.3 * r
		t += 0.07 + 0.07 * r


## Nabız (§9.6): yere inen ilk vuruş 8 ms yükselir, 60 ms söner, sonrakiler 70–140 ms arayla; bulut içi 150 ms; ≥0,25 sn ifşa.
func _flash_value() -> float:
	if _flash_t < 0.0:
		return 0.0
	var tau := wt - _flash_t
	if tau > 1.0:
		_flash_t = -1.0
		return 0.0
	var f := 0.0
	var decay := 0.15 if _flash_cloud else 0.06
	for i in _flash_n:
		var u := tau - _flash_gaps[i]
		if u < 0.0:
			continue
		var peak := 0.5 if _flash_cloud else _flash_peaks[i]
		var v := (peak * u) / 0.008 if u < 0.008 else peak * exp(-(u - 0.008) / decay)
		if v > f:
			f = v
	f *= _flash_p
	if tau < 0.25 and _flash_p >= 0.5:
		f = maxf(f, 0.01)
	return 0.0 if f < 0.005 else f


## Dolu sağanağı (§8.6): {size, minutes}; %30'u iri (bölüm tohumundan).
func _hail_tick(seg: WeatherSegment, h: float) -> void:
	if _type != _i_hail or seg == null or seg.type != _i_hail:
		if _type != _i_hail:
			_hail_seg = null
		return
	if _hail_seg == seg:
		return
	_hail_seg = seg
	var large := WeatherRng.unit(seg.seed, SALT_HAIL, 0, 0) < float((_sub.get("hail_burst", {}) as Dictionary).get("large", 0.3))
	_hail = {"size": "large" if large else "small", "minutes": int(roundf((seg.t1 - seg.t0) * 60.0))}
	hail.emit({"size": _hail["size"], "minutes": _hail["minutes"], "x": _ctx.player_x, "z": _ctx.player_z})


# --- İç: işaretler ve ses -----------------------------------------------------------------------------------------------

func _write_signs(h: float, lock: WeatherPlanner.Lock) -> void:
	var diff_k := float(DIFF_K.get(_ctx.difficulty, 1.0))
	var lock_type := ""
	var lock_at := 0.0
	if lock and lock.signs and lock.until < INF:
		lock_type = lock.after if (lock.after != "resume" and WeatherData.has_type(lock.after)) else String(WeatherData.id_of(lock.type))
		lock_at = lock.until
	var empty: Array[WeatherSegment] = []
	WeatherSigns.signs_for(empty if lock else planner.plan, h, diff_k, zone == "hexi_winter", _quiet_until, planner.prev, lock_type, lock_at, signs)
	# Cepheden 1 sa önce yön 30–60° döner (§7.1 wind_shift).
	var ws := signs.entry("wind_shift")
	if ws:
		var r := WeatherRng.unit(seed, floori(ws.t0 * 4.0), SALT_SHIFT)
		_shift = (SHIFT_DEG.x + (SHIFT_DEG.y - SHIFT_DEG.x) * r) * clampf(1.0 - ws.in_h / diff_k, 0.0, 1.0)
		_shift_sign = -1.0 if r < 0.5 else 1.0
	else:
		_shift = 0.0
	if not signs.hud.is_empty() and signs.has_front and _front_t0 != signs.front_t0:
		_front_t0 = signs.front_t0
		front.emit({"type": signs.front_type, "in_h": signs.front_in_h})
	if bool(cfg.get("lake", false)) and signs.has_front and signs.front_type in LAKE_BULL_FRONTS and signs.front_in_h <= 1.0 \
			and _bull_t0 != signs.front_t0:
		_bull_t0 = signs.front_t0
		lake_bull.emit({"type": signs.front_type, "in_h": signs.front_in_h})


## weather.audio (§3.5, §10.4): veri; listeyi ses sahibi kurar (AudioManager). Tür satırlarının karışımı, rüzgâr çarpanı, uzak yağmur.
func _write_audio(h: float) -> void:
	var sa := WeatherData.audio_of(_a)
	var sb := WeatherData.audio_of(_b)
	var beds: Array = []
	_add_row(beds, sa, 1.0 - _k)
	_add_row(beds, sb, _k)
	var wind := fx.wind
	var wa := WeatherFx.wind_gain(wind) * float(sa.get("wind_mul", 1.0)) if str(sa.get("wind")) == "gain" else float(sa.get("wind", 1.0))
	var wb := WeatherFx.wind_gain(wind) * float(sb.get("wind_mul", 1.0)) if str(sb.get("wind")) == "gain" else float(sb.get("wind", 1.0))
	var dom := sb if _k >= 0.5 else sa
	var music := lerpf(float(sa.get("music", 0.0)), float(sb.get("music", 0.0)), _k)
	var seg := mix.seg
	if seg and seg.src == WeatherSegment.SRC_CLEAR and seg.front_type >= 0 and WeatherData.wet[seg.front_type]:
		music = maxf(music, 0.45 * clampf(1.0 - (h - seg.t0) / 0.5, 0.0, 1.0))
	var fr := signs.entry("far_rain")
	if fr:
		var k := clampf(1.0 - fr.in_h / maxf(1e-6, float(DIFF_K.get(_ctx.difficulty, 1.0))), 0.0, 1.0)
		beds.append({"id": "rain_light", "gain": 0.1 + 0.216 * k, "lp": 900, "at": "upwind"})
	audio = {"beds": beds, "wind_k": lerpf(wa, wb, _k), "wind_swap": bool(dom.get("swap", false)) or wind > 11.0,
		"quiet": lerpf(float(sa.get("quiet", 1.0)), float(sb.get("quiet", 1.0)), _k),
		"birds": lerpf(float(sa.get("birds", 1.0)), float(sb.get("birds", 1.0)), _k) * (0.0 if WeatherData.group[_type] == WeatherData.GROUP_STORM or signs.entry("herd") else 1.0),
		"camp_day": lerpf(float(sa.get("camp_day", 1.0)), float(sb.get("camp_day", 1.0)), _k), "music": music * enter_k, "drip": dom.get("drip")}


static func _add_row(beds: Array, row: Dictionary, w: float) -> void:
	if not (w > 0.0):
		return
	for b: Variant in row.get("beds", []):
		var id := str(b[0])
		var g := float(b[1]) * w
		if g <= 0.001:
			continue
		var found := false
		for e: Dictionary in beds:
			if e["id"] == id:
				e["gain"] = float(e["gain"]) + g
				found = true
				break
		if not found:
			beds.append({"id": id, "gain": g})


static func _identity_audio() -> Dictionary:
	return {"beds": [], "wind_k": 1.0, "wind_swap": false, "quiet": 1.0, "birds": 1.0, "camp_day": 1.0, "music": 0.0, "drip": null}


# --- Kayıt (weather.md §12.7; kayıt v2'nin weather bloğu) ---------------------------------------------------------------

func to_dict() -> Dictionary:
	var pl := planner.to_dict() if planner else {"plan": [], "locks": []}
	var packs := {}
	if WeatherData.accumulates(cfg, season) or pack.snowpack > 0.0:
		packs[zone] = pack.to_dict()
	var h := planner.now if planner else 0.0
	var st := {}
	for key: String in struck:
		if h - float(struck[key]) < 24.0:
			st[key] = WeatherRng.js_round(float(struck[key]) * 100.0) / 100.0
	return {"v": 1, "seed": seed, "zone": zone, "climate": climate, "season": season, "at": WeatherRng.js_round(h * 1000.0) / 1000.0,
		"plan": pl["plan"], "wet": wet.to_array(), "packs": packs, "locks": pl["locks"], "struck": st, "said": said.slice(-SAID_MAX)}


## Kayıttan (blok bozuksa false: çağıran taze plan kurar). Zon farklıysa plan sabit çapadan kurulur, kar örtüsü yine okunur.
func from_dict(o: Variant, hour_abs: float) -> bool:
	if not o is Dictionary or planner == null:
		return false
	var d: Dictionary = o
	var sv: Variant = d.get("seed")
	if sv is float or sv is int:
		seed = int(sv) & WeatherRng.MASK
	var packs: Dictionary = d.get("packs", {}) if d.get("packs") is Dictionary else {}
	if packs.has(zone):
		pack.from_dict(packs[zone])
	struck = (d.get("struck", {}) as Dictionary).duplicate() if d.get("struck") is Dictionary else {}
	said = (d.get("said", []) as Array).slice(-SAID_MAX) if d.get("said") is Array else []
	planner = _make_planner()
	if str(d.get("zone", zone)) != zone:
		planner.start(hour_abs)
		return true
	planner.from_dict(d, hour_abs)
	wet.from_array(d.get("wet", []))
	_last_h = hour_abs
	_cell_key = NAN
	return true


static func _dist(dx: float, dz: float) -> float:
	return sqrt(dx * dx + dz * dz)
