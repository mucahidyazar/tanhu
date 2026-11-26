class_name RoamTime
extends Node
## Serbest Gez'in saati ve ışığı (K20, K67, K76; time.md §2, §5.5, §8.1, §11, §13; godot.md §3.5, §4.9; Yol Haritası clock-calendar,
## roam-calendar, sun-light). Serbest Gez oyunla aynı takvimi okur: tek saat GameClock'tur (ayrı sayaç ve ayrı ay yoktur), 1 oyun günü
## 60 gerçek dakika. Kayıtlı saat yoksa 11 Nisan MÖ 209 (day_n 1.171) 14:46,2'de (886,18) ana kampta açılır; eski kaydın günü göçer
## (GameClock.load_dict: {day, minute} → 1.171 + day). Godot'nun menüsü gece kampıdır (K76): açılış gece menüsünden 2,4 sn süzülmeyle
## gelir (SkyRig.fade_from_identity); menü, Yeni Oyun ve Önsöz gece ışığında kalır, bu düğüm onlarda çalışmaz. Menüye dönüşte ışık uçuş
## boyunca (1,7 sn) kimliğe döner ve kimlik bit bit geri yazılır (SkyRig.release): menü karesi değişmez.
##
## Saat 4 Hz örnek üretir (LightStops.sample: güneş ve ay, ışık durağı, gece renk ayarı, kampın ateşi, köyü ve ateş böcekleri; görünür
## akışta her kare) ve SkyRig'e verir: ışığın tek yazıcısı odur. Serbest Gez'de tarih olayı işlenmez (perde, Kronik, takvim olayı yok);
## Tan'da 2 sn yalnız tarih yazılır («12 Nisan MÖ 209», date_card). Mevsim görünüşü (data/time/calendar.json roam.looks): 15 Mayıs'tan
## yaz (baharın görünüşü), 23 Ağustos'tan güz tonu (gündüz renk ayarına karışır), 16 Kasım'dan kış (kar örtüsünün hedefi: season_look()
## «snow»; hava ajanının SnowPack'i okur). Güze 134, kışa 219 gerçek saat vardır.
##
## Ağaç duraklatılınca (duraklatma kitabı, harita) bu düğüm de durur: saat akmaz (time.md §6.1). Session (çekirdek) gelince saati o adım
## attırır: use_clock(session.clock, false) ile bu düğüm yalnız örnek üretir.
##
## Kayıt (godot.md §3.4, kayıt v2): clock bloğu {v, day_n, minute, holds}. Oturum (Session) kuruluysa saat ve bloğu onundur
## (Journey.live_blocks; begin'e oturumun saati verilir, bu düğüm adım attırmaz). Oturum yokken saat kaydın bloklarına yazılır
## (Journey.blocks.clock, store_into): Journey.to_record onları kayda koyar, yüklenen kaydın bloğu oradan okunur (saved_block).
##
## Geliştirme (Godot ... -- ): --clock=HH:MM ve --day=N açılışın saatini, --light=<durak> durağın ölçüm dakikasını (light_stops.json
## probe) seçer; --no-fade süzülmeyi atlar, --freeze-clock saati o dakikada durdurur (ölçüm kareleri).
##   var roam := RoamTime.new()
##   add_child(roam)
##   roam.date_card.connect(cine.card)
##   roam.begin(world, RoamTime.saved_block(journey))   # Serbest Gez: kayıttan ya da 11 Nisan 14:46,2'den, 2,4 sn süzülme
##   roam.begin(world, null, -1.0, session.clock)        # oturum kuruluysa: onun saati (adım attırmaz)
##   roam.store_into(journey)                            # kaydetmeden önce (oturum yokken)
##   await roam.end(1.7)                                 # menüye dönüş

## Tan'da tarih kartı (metin, saniye): main.gd CineHost.card'a bağlar.
signal date_card(text: String, seconds: float)
## Mevsimin görünüşü değişti: {season, grade_autumn, snow}.
signal look_changed(look: Dictionary)

const CALENDAR_PATH := "res://data/time/calendar.json"
const SKY_RIG_NAME := "SkyRig"

## Süren saat (begin kurar; use_clock dışarıdan verir).
var clock: GameClock
## Kampın ışık yazıcısı (attach kurar ya da bulur).
var rig: SkyRig
var running := false

var _table: Dictionary = {}
var _config: Dictionary = {}
var _place: Dictionary = {}
var _world: Node
var _owns_step := true
var _acc := 0.0
var _look: Dictionary = {}


func _init() -> void:
	_config = RoamTime.load_config()
	_table = LightStops.load_table()


func _ready() -> void:
	# Renk ayarının taban görüntüleri menüde boşken iş parçacığında hazırlanır (≈0,1 sn): açılışın süzülmesi beklemez.
	SkyRig.prepare_grades()


func _exit_tree() -> void:
	SkyRig.finish_grades()


## calendar.json'un roam bölümü (yoksa boş).
static func load_config(path: String = CALENDAR_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("[roam_time] dosya yok: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return {}
	return ((parsed as Dictionary).get("roam", {}) as Dictionary)


## Açılışın günü ve dakikası (kayıtlı saat yokken): 11 Nisan MÖ 209, 14:46,2.
func start_day() -> int:
	return int(_config.get("day_n", GameCalendar.HOME_DAY))


func start_minute() -> float:
	return float(_config.get("minute", Daylight.MENU_MINUTE))


## Bloktan saat (göç dahil): blok yoksa açılış (11 Nisan 14:46,2); mood > 0,75 olan eski kayıtta 18:38 (time.md §13). Yer ana kamptır.
func clock_from(block: Variant, mood: float = NAN) -> GameClock:
	var c := GameClock.new(start_day(), start_minute())
	if block is Dictionary and not c.load_dict(block):
		c = GameClock.new(start_day(), start_minute())
	elif not block is Dictionary and is_finite(mood):
		var migrate: Dictionary = _config.get("migrate", {})
		if mood > float(migrate.get("mood_dusk", 0.75)):
			c = GameClock.new(start_day(), float(migrate.get("dusk_minute", 1118.0)))
	var p := place()
	c.set_place(float(p.get("lat", Daylight.CAMP_LAT)), float(p.get("dec_offset", Daylight.CAMP_DEC_OFFSET)))
	return c


## Ana kampın yeri (light_stops.json places).
func place() -> Dictionary:
	if _place.is_empty():
		_place = LightStops.place(_table, str(_config.get("place", "camp")))
	return _place


# --- Bağlanma ------------------------------------------------------------------------------------------

## Dünyaya bağlanır: SkyRig'i bulur ya da kurar (ışık, ortam ve su yolları light_stops.json'dan) ve döndürür.
func attach(world: Node) -> SkyRig:
	if world == null:
		return null
	if _world == world and is_instance_valid(rig):
		return rig
	_world = world
	rig = world.get_node_or_null(NodePath(SKY_RIG_NAME)) as SkyRig
	if rig == null:
		var nodes: Dictionary = place().get("nodes", {})
		rig = SkyRig.new()
		rig.name = SKY_RIG_NAME
		rig.light_path = NodePath("../" + str(nodes.get("light", "MoonLight")))
		rig.environment_path = NodePath("../" + str(nodes.get("environment", "WorldEnvironment")))
		var glints: Array[NodePath] = []
		for path: Variant in nodes.get("water", []):
			glints.append(NodePath("../" + str(path)))
		rig.glint_paths = glints
		world.add_child(rig)
	return rig


## Kampın ışığa bağlı düğüm özellikleri (light_stops.json places.camp.props) → SkyRig.take_over'ın biçimi.
func prop_targets(world: Node) -> Dictionary:
	var out := {}
	var defs: Dictionary = place().get("props", {})
	for key: String in defs:
		if not defs[key] is Dictionary:
			continue
		var path := str(defs[key].get("path", ""))
		var node := SkyRig.find_target(world, path)
		if node:
			out[key] = {"node": node, "property": str(defs[key].get("property", "")), "root": world, "path": path}
	return out


# --- Oturum -------------------------------------------------------------------------------------------

## Serbest Gez başlar: saat bloktan (yoksa açılıştan), ışık kimlikten fade_seconds'ta süzülür (eksi: calendar.json'unki, 2,4 sn; 0: hemen).
## external: oturumun (Session) saati; verilirse o okunur, adım attırılmaz (blok yok sayılır: oturum kendi bloğunu okur).
## Süren bir oturumda yeniden çağrılırsa (duraklatmadan yükleme) saat değişir, kimlik korunur.
func begin(world: Node, block: Variant = null, fade_seconds: float = -1.0, external: GameClock = null) -> void:
	var dev := _dev_overrides()
	if external:
		clock = external
		_owns_step = false
		if not clock.has_place():
			var p0 := place()
			clock.set_place(float(p0.get("lat", Daylight.CAMP_LAT)), float(p0.get("dec_offset", Daylight.CAMP_DEC_OFFSET)))
	else:
		clock = clock_from(block)
		_owns_step = true
	if dev.has("abs"):
		var target := float(dev["abs"])
		var d := floori(target / GameClock.DAY_MIN)
		if external:
			clock.load_dict({"day_n": d, "minute": target - float(d) * GameClock.DAY_MIN})
		else:
			clock = GameClock.new(d, target - float(d) * GameClock.DAY_MIN)
			var p := place()
			clock.set_place(float(p.get("lat", Daylight.CAMP_LAT)), float(p.get("dec_offset", Daylight.CAMP_DEC_OFFSET)))
	_connect_clock()
	if attach(world) == null:
		push_warning("[roam_time] dünya yok: Serbest Gez'in ışığı yazılmaz")
		running = true
		return
	var was_taken := rig.is_taken()
	rig.take_over(prop_targets(world))
	_update_look(true)
	running = true
	_acc = 0.0
	feed()
	var seconds := float(_config.get("fade_seconds", 2.4)) if fade_seconds < 0.0 else fade_seconds
	if dev.has("no_fade"):
		seconds = 0.0
	if not was_taken and seconds > 0.0:
		rig.fade_from_identity(seconds, float(_config.get("fade_dip_angle", SkyRig.FADE_DIP_ANGLE)), float(_config.get("fade_dip_k", SkyRig.FADE_DIP_K)))
	if dev.has("freeze_clock") and is_inside_tree():
		# Ölçüm kareleri (K58): saat durağın dakikasında durur (geliştirme nedeni; oturumun nedenlerine karışmaz). 1,5 sn sonra durur
		# (≈0,6 oyun dk): havanın geliştirme kilidi (--weather=clear) zamanla karışır, saat hemen durursa kilit hiç oturmaz.
		var frozen := clock
		get_tree().create_timer(1.5).timeout.connect(func() -> void: frozen.pause(&"dev", true))


## Saati dışarıdan verir (Session): owns_step false ise bu düğüm adım attırmaz, yalnız örnek üretir.
func use_clock(external: GameClock, owns_step: bool = false) -> void:
	clock = external
	_owns_step = owns_step
	_connect_clock()


## Serbest Gez biter: saat durur, ışık seconds sn'de kimliğe döner (eksi: calendar.json'unki, 1,7 sn). await ile beklenebilir.
func end(seconds: float = -1.0) -> void:
	running = false
	if rig == null or not is_instance_valid(rig):
		return
	var s := float(_config.get("return_seconds", 1.7)) if seconds < 0.0 else seconds
	_look = {}
	await rig.release(s)


func is_running() -> bool:
	return running


func _process(delta: float) -> void:
	if not running or clock == null:
		return
	if _owns_step:
		clock.step(delta)
	_acc -= delta
	if _acc <= 0.0 or clock.is_lapsing():
		_acc = 1.0 / maxf(float(_config.get("sample_hz", 4.0)), 0.5)
		_update_look(false)
		feed()


## Saatin şimdiki örneğini SkyRig'e verir.
func feed() -> void:
	if rig and is_instance_valid(rig) and clock:
		rig.feed_clock(sample_now())


## Şimdinin ışık örneği (LightStops.sample ve mevsimin görünüşü).
func sample_now() -> Dictionary:
	if clock == null:
		return {}
	var s := LightStops.sample(_table, place(), clock.day_n, clock.minute)
	if s.is_empty():
		return s
	s["grade_autumn"] = float(_look.get("grade_autumn", 0.0))
	s["look"] = _look.duplicate()
	return s


# --- Mevsim görünüşü -------------------------------------------------------------------------------------

## Mevsimin görünüşü: {season, grade_autumn (güz tonunun payı), snow (kar örtüsünün hedefi)}. Mevsim başında blend_days gün içinde
## önceki mevsimin görünüşünden süzülür.
func season_look() -> Dictionary:
	return _look.duplicate()


## Günün ve dakikanın görünüşü (saf hesap; calendar.json looks).
func look_at(day_n: int, minute: float) -> Dictionary:
	var looks: Dictionary = _config.get("looks", {})
	var season := GameCalendar.season(day_n)
	var cur: Dictionary = looks.get(String(season), {})
	# Mevsimin başladığı gün: geriye doğru ilk farklı mevsimden sonraki gün.
	var start := day_n
	while GameCalendar.season(start - 1) == season and day_n - start < GameCalendar.YEAR_DAYS:
		start -= 1
	var prev: Dictionary = looks.get(String(GameCalendar.season(start - 1)), cur)
	var days := maxf(float(looks.get("blend_days", 3.0)), 0.001)
	var f := clampf((float(day_n - start) + minute / GameClock.DAY_MIN) / days, 0.0, 1.0)
	return {
		"season": season,
		"grade_autumn": lerpf(float(prev.get("grade_autumn", 0.0)), float(cur.get("grade_autumn", 0.0)), f),
		"snow": lerpf(float(prev.get("snow", 0.0)), float(cur.get("snow", 0.0)), f),
	}


func _update_look(force: bool) -> void:
	if clock == null:
		return
	var look := look_at(clock.day_n, clock.minute)
	var changed: bool = force or _look.is_empty() or look["season"] != _look.get("season") \
		or absf(float(look["grade_autumn"]) - float(_look.get("grade_autumn", 0.0))) > 0.002 \
		or absf(float(look["snow"]) - float(_look.get("snow", 0.0))) > 0.002
	_look = look
	if changed:
		look_changed.emit(look.duplicate())


# --- Tan kartı ------------------------------------------------------------------------------------------

func _connect_clock() -> void:
	if clock == null:
		return
	if not clock.dawn.is_connected(_on_dawn):
		clock.dawn.connect(_on_dawn)
	if not clock.skipped.is_connected(_on_skipped):
		clock.skipped.connect(_on_skipped)


## Tan'da 2 sn yalnız tarih (time.md §8.1, §11): gün sayısı yazılmaz, sayım rehinenindir.
func _on_dawn(info: Dictionary) -> void:
	if bool(info.get("skipping", false)) or not running:
		return
	_show_date(int(info.get("day_n", clock.day_n)))


## Atlama bir şafağı geçtiyse kart atlamanın sonunda bir kez.
func _on_skipped(info: Dictionary) -> void:
	if running and int(info.get("dawns", 0)) > 0:
		_show_date(clock.day_n)


func _show_date(day_n: int) -> void:
	date_card.emit(GameCalendar.format(day_n, SubtitleBar.ui_lang()), float(_config.get("dawn_card_seconds", 2.0)))


# --- Kayıt köprüsü --------------------------------------------------------------------------------------

## Yolculuğun kayıtlı saat bloğu (yoksa null): oturum kuruluysa onun clock bloğu (Journey.live_blocks), değilse kaydın blokları
## (Journey.blocks: son yüklenen kaydınki ya da kapanan oturumun son hâli).
static func saved_block(journey: Object) -> Variant:
	if journey == null:
		return null
	for key in ["live_blocks", "blocks"]:
		var v: Variant = journey.get(key)
		if v is SaveBlocks and (v as SaveBlocks).has_block("clock"):
			return (v as SaveBlocks).collect().get("clock")
		if v is Dictionary and (v as Dictionary).get("clock") is Dictionary:
			return (v as Dictionary)["clock"]
	return null


## Saati yolculuğa yazar (kaydetmeden önce; yalnız Serbest Gez sürerken): oturum kuruluysa saat onundur, bir şey yazılmaz (oturum kendi
## bloğunu kaydeder); değilse kaydın bloklarına (Journey.blocks.clock), Journey.to_record kayda koyar.
func store_into(journey: Object) -> void:
	if journey == null or clock == null or not running:
		return
	for key in ["live_blocks", "blocks"]:
		var v: Variant = journey.get(key)
		if v is SaveBlocks and (v as SaveBlocks).has_block("clock"):
			return
	var blocks: Variant = journey.get("blocks")
	if blocks is Dictionary:
		(blocks as Dictionary)["clock"] = clock.to_dict()


# --- Geliştirme --------------------------------------------------------------------------------------------

## --clock=HH:MM, --day=N, --light=<durak>, --no-fade (yalnız komut satırında verildiyse).
func _dev_overrides() -> Dictionary:
	var args := {}
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--"):
			continue
		var body := arg.substr(2)
		var eq := body.find("=")
		args[body if eq < 0 else body.substr(0, eq)] = true if eq < 0 else body.substr(eq + 1)
	var out := {}
	if args.has("no-fade"):
		out["no_fade"] = true
	if args.has("freeze-clock"):
		out["freeze_clock"] = true
	var day := start_day()
	var minute := NAN
	if args.has("light"):
		var id := StringName(str(args["light"]))
		minute = LightStops.probe_minute(_table, id)
		day = LightStops.probe_day(_table)
		if is_nan(minute):
			push_warning("[roam_time] --light: durak yok: %s" % id)
	if args.has("clock"):
		var m := GameClock.parse_hhmm(str(args["clock"]))
		if m >= 0.0:
			minute = m
	if args.has("day") and str(args["day"]).is_valid_int():
		day = int(str(args["day"]))
		if is_nan(minute):
			minute = start_minute()
	if is_finite(minute):
		out["abs"] = GameClock.abs_of(day, minute)
	return out
