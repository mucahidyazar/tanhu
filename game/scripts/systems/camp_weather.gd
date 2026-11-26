class_name CampWeather
extends Node
## Serbest Gez kampının havası (K22, K67; weather.md §4.1, §5.8, §6.3, §9.12; godot.md §3.1 adım 3, §4.9; Yol Haritası weather): hava
## oyunun saatiyle akar. Saat Serbest Gez'in saatidir (RoamTime.clock; oturum kuruluysa Session.clock, ikisi de yoksa kendi GameClock'u
## 11 Nisan MÖ 209 14:46,2'den). Mevsimi takvim verir, satırı kamp seçer (camp_spring, camp_summer, camp_autumn, camp_winter); kar
## yalnız kışın tutar. Işığın tek yazıcısı SkyRig'dir (RoamTime kurar): görünüm ona hava girdisini verir. Menü, Yeni Oyun, Önsöz,
## sinema ve oluşturucu bu düğümü çalıştırmaz (hava kimliktir); menüye dönüşte görünüm 1,7 sn'de kimliğe döner, menü karesi değişmez.
## Ana kampta Mete yoktur, Çocuk yürür (K37): yıldırım Çocuğun 25 m'sine ve kampın yapılarına inmez, tasarlanmış düşüş kadraja.
##
## Kayıt: yolculuğun weather bloğu (WeatherSim.to_dict; weather.md §12.7). Oturum (Session) kendi blok kaydını kuruyorsa blok orada
## kayıtlıdır (register_block), değilse journey.blocks["weather"]'a yazılır (store_into; RoamTime'ın saatiyle aynı yol).
##
## Geliştirme (Godot ... -- ): --weather=<tür> türü zorlar (dev kilidi; tür §3.1 kimliği), --weather-instant karışımı ve menüden inişi
## atlar, --weather-pack=0..1 kar örtüsü, --weather-hail=0..1 zemindeki dolu beyazlığı, --weather-fresh=0..1 taze kar, --weather-wet=0..1 zemin ıslaklığı, --weather-strike[=SN]
## SN (4) sn sonra kadrajın ortasına yakın yıldırım (geliştirme; --weather-strike-every=SN ile yinelenir: kararlı karede şerit görünür),
## --weather-strike-age=SN görüntüyü (DevCapture) ilk yıldırımın yaşı SN'ye varıp şimşek sönene dek bekletir (şerit karanlık fırtınada
## görünür; en geç şerit sönmeden alınır), --weather-alpha=0.65 ekran yağışının katman alfası (W16'nın tek seçeneği), --weather-seed=N.
##   var cw := CampWeather.new()
##   add_child(cw)
##   cw.begin(world, roam_time, player, journey)
##   cw.store_into(journey)       # kaydetmeden önce
##   cw.end(1.7)                  # menüye dönüş

const ZONE := "tanhu_camp"
const BLOCK := "weather"

var sim: WeatherSim
var view: WeatherView
var world: Node3D
var player: Node3D
var roam: Node
var running := false
## Oturum (Session) adım attırıyorsa true: _process adım atmaz.
var stepped_by_session := false
## Kuyruktaki geliştirici yıldırımı (sn; eksi yok).
var _strike_in := -1.0
## Geliştirme: ilk yıldırımın inişi (sim.wt; eksi inmedi) ve görüntünün bekletilip bekletilmediği (--weather-strike-age).
var _struck_at := -1.0
var _capture_held := false
var _clock: GameClock
var _own_clock: GameClock
var _ctx := WeatherSim.Ctx.new()
var _dev: Dictionary = {}
var _tall: Array = []


func _init() -> void:
	name = "CampWeather"
	process_priority = 2


## Serbest Gez başlar: hava kayıttaki bloktan (yoksa 0,5 sa açıkla, §6.3), menüden inişte görünüm 2,4 sn'de kimlikten süzülür. instant:
## perde kapalıyken (kayıttan yükleme) karışım beklenmez.
func begin(p_world: Node3D, p_roam: Node, p_player: Node3D, journey: Object = null, instant: bool = false) -> void:
	world = p_world
	roam = p_roam
	player = p_player
	_dev = _dev_args()
	_clock = _resolve_clock()
	var h := _clock.abs_minute() / 60.0
	var block: Variant = saved_block(journey)
	var seed := int(_dev.get("seed", _seed_of(journey)))
	if sim == null or not sim.ready():
		sim = WeatherSim.new()
		sim.lake_bull.connect(_on_lake_bull)
	sim.structure_done = func(_id: String) -> bool: return true
	_fill_ctx()
	sim.setup(ZONE, {}, h, _clock.day_n, seed, _ctx.difficulty)
	if block is Dictionary and str((block as Dictionary).get("zone", ZONE)) == ZONE and sim.from_dict(block, h):
		pass
	else:
		sim.begin_roam(h)
	sim.from_identity(instant or _dev.has("instant"))
	_apply_dev()
	_connect_clock()
	if view == null or not is_instance_valid(view):
		view = WeatherView.new()
		add_child(view)
	view.bind(sim, world, player)
	if _dev.has("alpha"):
		view.layer_alpha = float(_dev["alpha"])
	if _dev.has("debug"):
		view.debug_points = true
	_tall = _collect_tall(world)
	running = true


## Menüye dönüş: görünüm seconds sn'de kimliğe döner, sonra durur (genel tekdüzenler 0, SkyRig'in hava girdisi boş).
func end(seconds: float = WeatherSim.TO_MENU_S) -> void:
	if sim == null:
		running = false
		return
	sim.to_identity(seconds)
	running = false
	if seconds <= 0.0 and view:
		view.update(0.0)


func is_running() -> bool:
	return running


func _process(delta: float) -> void:
	if not stepped_by_session:
		session_step(delta)


## Bir kare (Session'ın 3. adımı da bunu çağırabilir: session.add_system(&"weather", camp_weather.session_step, &"weather") ve
## stepped_by_session = true; oturum kendi saatini attırır, bu düğüm saati okur).
func session_step(delta: float) -> void:
	if sim == null or not sim.ready():
		return
	if not running:
		# Menüye dönüş: kimliğe karışım sürer (saat okunmaz).
		if sim.enter_k > 0.0:
			sim.step(delta, _last_h(), _ctx)
		return
	var c := _resolve_clock()
	if c != _clock:
		_clock = c
		_connect_clock()
	if _clock == _own_clock:
		_own_clock.step(delta)
	_fill_ctx()
	var h := _clock.abs_minute() / 60.0
	sim.step(delta, h, _ctx)
	if _strike_in >= 0.0:
		_strike_in -= delta
		if _strike_in < 0.0:
			sim.strike_dev_frame(1 if _capture_held else 3)
			if _struck_at < 0.0:
				_struck_at = sim.wt
			if _dev.has("strike_every"):
				_strike_in = float(_dev["strike_every"])
	if _capture_held and _struck_at >= 0.0:
		# Şimşeğin nabzı (tek vuruş, 60 ms sönüm) şeritten kısadır: görüntü nabız sönünce, en geç şerit sönmeden alınır.
		var age := sim.wt - _struck_at
		if (age >= float(_dev["strike_age"]) and sim.flash_k <= 0.05) or age >= WeatherView.BOLT_LIFE - 0.05:
			_capture_held = false
			get_node(^"/root/DevCapture").call(&"release_capture")


func _last_h() -> float:
	return _clock.abs_minute() / 60.0 if _clock else 0.0


## Saatin kaynağı: oturum, Serbest Gez'in saati, yoksa kendi saati.
func _resolve_clock() -> GameClock:
	var session := get_parent().get_node_or_null(^"Session") if get_parent() else null
	var sc: Variant = session.get(&"clock") if session else null
	if sc is GameClock:
		return sc
	var rc: Variant = roam.get(&"clock") if roam and is_instance_valid(roam) else null
	if rc is GameClock:
		return rc
	if _own_clock == null:
		_own_clock = GameClock.new(GameClock.ROAM_DAY, Daylight.MENU_MINUTE)
		_own_clock.set_place(Daylight.CAMP_LAT, Daylight.CAMP_DEC_OFFSET)
	return _own_clock


func _connect_clock() -> void:
	if _clock == null:
		return
	if not _clock.hour_passed.is_connected(_on_hour):
		_clock.hour_passed.connect(_on_hour)
	if not _clock.skipped.is_connected(_on_skipped):
		_clock.skipped.connect(_on_skipped)


func _on_hour(info: Dictionary) -> void:
	if bool(info.get("skipping", false)) or sim == null:
		return
	sim.on_hour(float(info.get("abs", 0.0)) / 60.0)


func _on_skipped(info: Dictionary) -> void:
	if sim == null:
		return
	sim.skip(float(info.get("from", 0.0)) / 60.0, float(info.get("to", 0.0)) / 60.0, bool(info.get("long", false)), str(info.get("reason", "")) == "sleep")


func _fill_ctx() -> void:
	var c := _ctx
	if player and is_instance_valid(player) and player.is_inside_tree():
		var p := player.global_position
		c.player_x = p.x
		c.player_y = p.y
		c.player_z = p.z
		c.child_mode = not player.has_method(&"is_child") or bool(player.call(&"is_child"))
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam:
		var f := -cam.global_transform.basis.z
		f.y = 0.0
		if f.length_squared() > 1e-6:
			f = f.normalized()
			c.cam_fwd_x = f.x
			c.cam_fwd_z = f.z
	c.play = false
	c.difficulty = "normal"
	c.tall_things = _tall
	if _clock:
		c.day_n = _clock.day_n
		if _clock.has_method(&"below_horizon"):
			c.night = bool(_clock.call(&"below_horizon"))
		else:
			var hd := _clock.minute / 60.0
			c.night = hd < 5.5 or hd >= 19.0
		if _clock.has_method(&"moon_at_abs"):
			var m: Variant = _clock.call(&"moon_at_abs", _clock.abs_minute())
			c.moon_up = m is Dictionary and float((m as Dictionary).get("el", -90.0)) > 0.0


## Kampın yıldırım adayları (weather.md §8.7): yalnız ağaç ve direk; Serbest Gez'de yapılara inmez. Bugün kampta aday kaydı yoktur
## (flora kurulumda doldurur): boş liste düşüşü kadraja seçilen noktaya bırakır.
static func _collect_tall(_w: Node) -> Array:
	return []


static func _seed_of(journey: Object) -> int:
	var s: Variant = journey.get("journey_seed") if journey else null
	return int(s) & WeatherRng.MASK if (s is int or s is float) and int(s) != 0 else 0x7a17c0de


## Göl boğası (weather.md §10.2): far_rain kanalında, rüzgârın geldiği yanda 30 m'de bir kez (audio/sfx/gen/lake_bull.wav; kodla
## basılır: tools/bake_music.sh --only=lake_bull).
func _on_lake_bull(_info: Dictionary) -> void:
	var am := get_node_or_null(^"/root/AudioManager")
	if am == null or player == null or not is_instance_valid(player) or not running:
		return
	var up := -Vector3(sim.fx.dir_x, 0.0, sim.fx.dir_z)
	am.call(&"play_sfx", &"lake_bull", {"at": player.global_position + up * 30.0})


# --- Kayıt ------------------------------------------------------------------------------------------------------------

## Yolculuğun kayıtlı hava bloğu (yoksa null): oturumun kaydında, kaydın bloklarında ya da bekleyen bloklarda.
static func saved_block(journey: Object) -> Variant:
	if journey == null:
		return null
	var live: Variant = journey.get("live_blocks")
	if live is SaveBlocks and (live as SaveBlocks).has_block(BLOCK):
		return (live as SaveBlocks).collect().get(BLOCK)
	for field: StringName in [&"blocks", &"pending_blocks"]:
		var d: Variant = journey.get(field)
		if d is Dictionary and (d as Dictionary).get(BLOCK) is Dictionary:
			return (d as Dictionary)[BLOCK]
	return null


## Bloğu yolculuğa yazar (kaydetmeden önce): oturumun kaydı bloğu tutuyorsa bir şey yazılmaz.
func store_into(journey: Object) -> void:
	if journey == null or sim == null or not sim.ready():
		return
	var live: Variant = journey.get("live_blocks")
	if live is SaveBlocks and (live as SaveBlocks).has_block(BLOCK):
		return
	var d: Variant = journey.get(&"blocks")
	if d is Dictionary:
		(d as Dictionary)[BLOCK] = sim.to_dict()


## Oturumun blok kaydına bağlanır (Session.blocks; kayıt v2): yazma sim.to_dict, okuma sim.from_dict.
func register_block(blocks: SaveBlocks) -> void:
	if blocks == null or sim == null:
		return
	blocks.register(BLOCK, 1, sim.to_dict, func(d: Dictionary) -> bool: return sim.from_dict(d, _last_h()),
		{"check": WeatherPlanner.validate_save_block, "order": 78, "max_bytes": 1024})


# --- Geliştirme -------------------------------------------------------------------------------------------------------

func _dev_args() -> Dictionary:
	var out := {}
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--weather"):
			continue
		var body := arg.substr(2)
		var eq := body.find("=")
		var key := body if eq < 0 else body.substr(0, eq)
		var val: Variant = true if eq < 0 else body.substr(eq + 1)
		match key:
			"weather":
				out["type"] = str(val)
			"weather-instant":
				out["instant"] = true
			"weather-pack", "weather-fresh", "weather-wet", "weather-alpha", "weather-hail":
				out[key.substr(8)] = float(str(val).replace(",", "."))
			"weather-strike":
				out["strike"] = 4.0 if val is bool else float(str(val).replace(",", "."))
			"weather-strike-every":
				out["strike_every"] = float(str(val).replace(",", "."))
			"weather-strike-age":
				out["strike_age"] = float(str(val).replace(",", "."))
			"weather-seed":
				out["seed"] = int(str(val))
			"weather-debug":
				out["debug"] = true
	return out


func _apply_dev() -> void:
	if _dev.has("type"):
		if not sim.force(str(_dev["type"]), true, 0.0 if _dev.has("instant") else 6.0):
			push_warning("[camp_weather] --weather: bilinmeyen tür %s" % str(_dev["type"]))
	if _dev.has("pack"):
		sim.pack.reset(clampf(float(_dev["pack"]), 0.0, 1.0))
	if _dev.has("fresh"):
		sim.wet.snow = clampf(float(_dev["fresh"]), 0.0, 1.0)
	if _dev.has("wet"):
		sim.wet.ground = clampf(float(_dev["wet"]), 0.0, 1.0)
		sim.wet.mud = sim.wet.ground * 0.8
	if _dev.has("hail"):
		sim.set_hail_white(float(_dev["hail"]))
	if _dev.has("strike"):
		_strike_in = float(_dev["strike"])
		var cap := get_node_or_null(^"/root/DevCapture")
		if _dev.has("strike_age") and not _capture_held and cap and cap.has_method(&"hold_capture"):
			cap.call(&"hold_capture")
			_capture_held = true
