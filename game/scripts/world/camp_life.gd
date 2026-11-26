class_name CampLife
extends Node
## Serbest Gez'in kamp günü (time.md §8.2, §8.3; structures.md §10.2, §11.6; K50, K52, K83, K106; Yol Haritası roam-camp-life): Göl Obası'nda
## (menünün kampı) camp3'ü Oktar, Erka ve Dengiz kurar, ocak halkı saat programıyla ateş başında durur ya da yatar. Emek SiteState'tedir
## (SiteRules.camp3; K50 eğrisi: yardımsız ilk duman 05:48 şafakta, bütün yardımla 03:43 gece): bu düğüm onu oturumun saatiyle ilerletir
## (Session'ın 5. adımı «sites»; oturum yoksa kendi _process'i), görünümü kurar, Çocuğun yardımını alır ve sözleri söyletir.
##
## Görünüm yalnız Serbest Gez'dedir (menüde bu düğüm çalışmaz, menü karesi değişmez): Camp/Camp3 altında StagedYurt (Hane, hun, Otacı Düzeni,
## hero; aşama şantiyeden), malzeme yığını (adımlar bittikçe azalır), iki meşale direği (batıştan ilk dumana dek) ve üç usta (StandIn yer
## tutucuları). Usta adımın klibiyle yurdun çevresindeki yuvasındadır; öğünde yığının başında aşını yer; Dengiz eksik kova ve kütük için
## sefere gider (yolu zamana bağlıdır: atlamada da yerindedir); ocak kapıyı beklerken ustalar kapıda uyuklar. Ustalar Serbest Gez açıldıktan
## 20 gerçek sn (8 oyun dk) sonra kuzeydeki usta girişinden iner; saat 06:00–22:00 dışındaysa ertesi 06:00'da. Yurdun ve yığının altındaki
## çayır tutamları gizlenir; end() hepsini kaldırır ve tutamları geri koyar.
##
## Ocak halkı (CampNpcs: Ozan, Ana, Baba, Ağabey; Çocuk oyuncudur): ateş saatlerinde yerindedir (time.md §8.2), dışında yatar ya da kamptan
## çıkar. Görünüş yalnız kadraj dışındayken (sınır küresi + 1 m kesik koninin dışında) ya da saat atlarken değişir: figür gözün önünde
## kaybolmaz. camp3'ün kurulduğu gece Ozan, Ana ve Baba 23:00'e dek ateş başındadır (Ağabey 22:30'da yatar); 23:00'te aşama ≥4 ise ilk
## dumana dek beklerler (K83, SiteRules.install_family). İş yerindeki ikizler (Baba'nın kütüğü, Ana'nın keçesi) sonraki işe kalır.
##
## Çocuğun yardımı (K52): yığında ya da bir ustanın 4 m yakınında E «Ustalara Katıl (yarım el)»; katılan Çocuk adımın fiilinin klibini oynar
## ve yerinden ayrılmadıkça 0,5 eldir (kapı keçesi ve ocak çocuk işi değildir); hareket girdisi ekipten çıkarır. Ayak işleri: kovadan su
## (zemin adımından önce, 2), odunluktan kütük (uuk'tan önce, 4), ateşten köz (aşama 6'dan ocağa dek); yığında E bırakır.
##
## Kayıt: yolculuğun «sites» bloğu (godot.md §3.4; SiteState.validate_save_block): zones.tanhu_camp.sites.camp3 SiteState.to_dict'tir, ek
## alanlar fam (aile kuralının kararı) ve told (kart söylendi mi); başlamamış şantiye {pending, start, child}. Öteki zonlar olduğu gibi taşınır.
## Oturum kuruluysa blok onun kaydındadır (register_block), değilse journey.blocks'a yazılır (store_into; CampWeather'ın yolu).
##
## Geliştirme: --camp3-from=HH:MM şantiye o saatte başlamış sayılır (bugün; şimdiden sonraysa dün) ve şimdiye dek işlenir; --camp3-stage=N
## aşama en az N olur; --camp3-join Çocuk baştan katılmış sayılır (yalnız emek).
##   var life := CampLife.new()
##   add_child(life)
##   life.begin(world, player, journey, ui_parent, below, camp_weather)
##   life.store_into(journey)        # kaydetmeden önce
##   life.end(1.7)                   # menüye dönüş (kamera uçuşu bitince kalkar)

signal site_done(at_min: float)

const SITE_ID := "camp3"
const ZONE := "tanhu_camp"
const BLOCK := "sites"
const BLOCK_V := 1
const BLOCK_ORDER := 76
const ROOT_NAME := "Camp3"
## Erimler (m, yatay).
const JOIN_REACH := 4.0
const LEAVE_MOVE := 0.7
const DROP_REACH := 2.8
const BUCKET_REACH := 1.8
const WOOD_REACH := 2.4
const FIRE_REACH := 3.2
const PLACE_REACH := 10.0
## Ustanın yürüyüşü (m/sn), varışın süresi (oyun dk), bitişteki sevinç ve ayrılış (oyun dk).
const WALK_MPS := 1.25
const ARRIVE_MIN := 4.0
const CHEER_MIN := 3.0
const LEAVE_MIN := 5.0
## Meşalenin söndüğü an (gün dk; şafak) ve batışın yedeği (saat yeri bilmezse; structures.md §10.2: 18:38).
const DAWN_DM := 330.0
const SUNSET_DM := 1118.0
const UPDATE_S := 0.25
## Kampın düğümleri (scenes/world/world.tscn).
const BUCKET := ^"Camp/Bucket"
const WOODPILE := ^"Camp/WoodPile"
const FIRE := ^"Camp/Campfire"
const NPCS := ^"Camp/CampNpcs"
const MEADOW := ^"Meadow"
## Yığından kampın içine yol (yurtların, odunluğun ve sandığın arasından; ölçüldü).
const CAMP_WAY: Array[Vector2] = [Vector2(0.3, -10.6), Vector2(0.9, -6.2)]
## Ocak halkının ateş saatleri (gün dk; time.md §8.2): [başı, sonu] pencereleri.
const FOLK_HOURS := {
	"Elder": [[540.0, 1350.0]], "Mother": [[300.0, 480.0], [660.0, 1350.0]], "Father": [[720.0, 1350.0]], "OlderBrother": [[720.0, 1350.0]],
}
## camp3 gecesi 23:00'e (ve beklerse ilk dumana) dek kalanlar (K83).
const FOLK_WAIT: Array[String] = ["Elder", "Mother", "Father"]
## Ustaların adımdaki yuvası: [açı°, yarıçap m] × (Oktar, Erka, Dengiz); açı kapıdan (yurdun +Z'si) saat yönüne.
const SLOTS := {
	"y_site": [[-35.0, 1.6], [150.0, 1.8], [60.0, 2.2]], "y_bosaga": [[-25.0, 2.6], [25.0, 2.6], [0.0, 4.4]],
	"y_kerege": [[-60.0, 4.0], [120.0, 4.0], [40.0, 4.0]], "y_bag": [[-100.0, 4.0], [80.0, 4.0], [170.0, 4.1]],
	"y_tunduk": [[-90.0, 1.0], [90.0, 1.0], [180.0, 1.2]], "y_uuk": [[-60.0, 2.3], [70.0, 2.3], [180.0, 2.4]],
	"y_liner": [[-80.0, 4.0], [100.0, 4.0], [10.0, 4.3]], "y_tuurduk": [[-120.0, 4.0], [60.0, 4.0], [180.0, 4.1]],
	"y_uzuk": [[-150.0, 4.3], [30.0, 4.3], [100.0, 4.4]], "y_kolan": [[-45.0, 4.0], [135.0, 4.0], [-135.0, 4.0]],
	"y_esik": [[-20.0, 4.0], [20.0, 4.0], [45.0, 4.6]], "y_sirdak": [[-120.0, 1.8], [120.0, 1.8], [180.0, 1.6]],
	"y_ocak": [[-30.0, 1.6], [0.0, 0.9], [35.0, 1.7]],
}
## Ustaların adımdaki klibi (ClipLibrary anahtarı; kişilerin iş öbeği ve yer oturuşları).
const STEP_CLIPS := {
	"y_site": "crouch_pick_place_f", "y_bosaga": "bend_over_pick_up_m", "y_kerege": "stand_fruit_basket_f", "y_bag": "stand_fruit_basket_f",
	"y_tunduk": "pull_radish", "y_uuk": "stand_fruit_basket_f", "y_liner": "crouch_pick_place_f", "y_tuurduk": "pull_radish",
	"y_uzuk": "pull_radish", "y_kolan": "pull_radish", "y_esik": "ground_mend", "y_sirdak": "crouch_pick_place_f", "y_ocak": "ground_warm_hands",
}
## Çocuğun fiilinin klibi (K52; structures.md §11.6).
const HELP_CLIPS := {
	"help_tamp": "crouch_pick_place_f", "help_carry": "collect_object", "help_hold": "stand_fruit_basket_f", "help_tie": "stand_fruit_basket_f",
	"help_heave": "pull_radish", "help_pull": "pull_radish",
}
const MEAL_CLIP := "ground_eat_bowl"
const WAIT_CLIP := "ground_doze"
const CHEER_CLIP := "big_wave_hello"
const CARRY_CLIPS := {"water": "carry_water_bucket_walk", "logs": "carry_heavy_object_walk"}
## Malzeme yığınının parçaları: adım kimliği → [renk anahtarı, parça sayısı]; adım bitince parçası yığından kalkar.
const STOCK_PARTS := {
	"y_bosaga": ["wood", 2], "y_kerege": ["wood", 4], "y_tunduk": ["crown", 1], "y_uuk": ["wood", 6], "y_liner": ["reed", 2],
	"y_tuurduk": ["felt", 3], "y_uzuk": ["felt", 2], "y_kolan": ["rope", 2], "y_sirdak": ["rug", 1],
}
const STOCK_COLORS := {
	"wood": Color(0.47, 0.3, 0.17), "crown": Color(0.36, 0.23, 0.13), "reed": Color(0.78, 0.68, 0.42), "felt": Color(0.92, 0.86, 0.72),
	"rope": Color(0.62, 0.52, 0.36), "rug": Color(0.62, 0.2, 0.15),
}

var world: Node3D
var player: Node3D
var journey: Object
var weather: CampWeather
var spec: Dictionary = {}
var site: SiteState
## Başlamamış şantiye (ustalar inmedi): {start, child}.
var pending: Dictionary = {}
var root: Node3D
var yurt: StagedYurt
var running := false
## Oturum adım attırıyorsa true (_process adım atmaz).
var stepped_by_session := false
## Çocuğun durumu: katıldı mı, katıldığı yer, taşıdığı (water, logs, ember ya da boş).
var joined := false
var carry := ""
## Kart ve aile satırı söylendi mi; aile kuralının kararı (kayıtta fam).
var told := false
## Ustalar: kimlik → {avatar, pos, goal, path, walking, clip}.
var builders: Dictionary = {}
## Altyazı (kendi StoryHud'ı) ve bildirim (MenuToast; main.gd verir), kart (CineHost.card).
var hud: StoryHud
var toast: Object
var card: Callable
var lang := "tr"
## Söylenenler (bir kez): anahtar → true.
var said: Dictionary = {}

var _clock: GameClock
var _own_clock: GameClock
var _session: Node
var _tick := 0.0
var _hud_clock := 0.0
var _snap := true
var _join_at := Vector3.ZERO
var _join_step := ""
var _near_site := false
var _rain_said := false
var _other_zones: Dictionary = {}
var _hidden_grass: Array = []
var _folk_hidden: Dictionary = {}
var _end_serial := 0
var _dev: Dictionary = {}
var _stock_key := ""
var _torches: Array[Node3D] = []
var _last_stage := -2
var _held_roles: Dictionary = {}


func _init() -> void:
	name = "CampLife"
	process_priority = 2


# --- Yaşam döngüsü -----------------------------------------------------------------------------------------------

## Serbest Gez başlar: şantiye kayıttan (yoksa ustalar 8 oyun dk sonra iner), görünüm kurulur, oturum varsa blok ve adım ona bağlanır.
## ui_parent ve below altyazının katmanıdır (CampVoice gibi); p_weather verilirse camp3'ün ocağı havanın sert türlerini tutar (§6.3).
func begin(p_world: Node3D, p_player: Node3D, p_journey: Object = null, ui_parent: Node = null, below: Node = null,
		p_weather: CampWeather = null, p_session: Node = null) -> void:
	_end_serial += 1
	if running:
		_teardown()
	world = p_world
	player = p_player
	journey = p_journey
	weather = p_weather
	_session = p_session
	lang = SubtitleBar.ui_lang()
	spec = SiteState.site_spec(SITE_ID)
	_dev = _dev_args()
	_clock = _resolve_clock()
	_connect_clock()
	site = null
	pending = {}
	told = false
	joined = false
	carry = ""
	said.clear()
	_rain_said = false
	var block: Variant = CampLife.saved_block(journey)
	if not (block is Dictionary and load_block(block)):
		_fresh_site()
	_apply_dev_site()
	if hud == null and ui_parent:
		hud = StoryHud.new()
		hud.name = "CampLifeHud"
		hud.show_box = false
		ui_parent.add_child(hud)
		if below and below.get_parent() == ui_parent:
			ui_parent.move_child(hud, below.get_index())
	_build_view()
	_bind_weather()
	if _session and is_instance_valid(_session):
		var blocks: Variant = _session.get(&"blocks")
		if blocks is SaveBlocks:
			register_block(blocks)
		if _session.has_method(&"get_system") and _session.call(&"get_system", &"camp_life") == null:
			_session.call(&"add_system", &"sites", session_step, &"camp_life")
		stepped_by_session = true
	else:
		stepped_by_session = false
	running = true
	_snap = true
	_update(0.0)


## Menüye dönüş ya da haritaya geçiş: görünüm seconds sn sonra (kamera uçuşu bitince) kalkar, çayır ve halk menüdeki hâline döner. Şantiyenin
## durumu kalır (store_into ve oturumun kaydı onu yazar).
func end(seconds: float = 0.0) -> void:
	running = false
	_leave_crew(false)
	if _session and is_instance_valid(_session) and _session.has_method(&"remove_system"):
		_session.call(&"remove_system", &"camp_life")
	stepped_by_session = false
	if hud:
		hud.clear()
	_end_serial += 1
	var serial := _end_serial
	if seconds > 0.0 and is_inside_tree():
		await get_tree().create_timer(seconds).timeout
		if serial != _end_serial:
			return
	_teardown()


func is_running() -> bool:
	return running


## camp3 bitti mi (WeatherSim.structure_done: ocak yanana dek sert hava yok). Başka yapı sorulursa true.
func structure_done(id: String) -> bool:
	if id != SITE_ID:
		return true
	return site != null and site.is_done()


func _process(delta: float) -> void:
	if not running:
		return
	if stepped_by_session and _session and is_instance_valid(_session) and _session.is_inside_tree():
		_move_builders(delta)
		return
	stepped_by_session = false
	session_step(delta)
	_move_builders(delta)


## Bir kare (Session'ın 5. adımı «sites»): emek saate dek işler, ustaların ve halkın durumu seçilir, Çocuğun yardımı izlenir.
func session_step(delta: float) -> void:
	if not running:
		return
	if world == null or not is_instance_valid(world) or not world.is_inside_tree():
		# Kamp bırakıldı (iç haritaya geçiş; WorldHost kampı bellekte tutar): görünüm kalkar, kamp menüdeki hâline döner, şantiye durumu kalır.
		running = false
		_teardown()
		return
	var c := _resolve_clock()
	if c != _clock:
		_clock = c
		_connect_clock()
	if _clock == _own_clock:
		_own_clock.step(delta)
	_update(delta)


func _update(delta: float) -> void:
	var now := _now()
	_hud_clock += delta
	if hud:
		hud.tick(_hud_clock)
	_start_if_due(now)
	if site:
		_track_child(now)
		# Emek olay güdümlüdür (aradaki süre tek parça işlenir, sonuç aynıdır): saatin 0,05 oyun dk'sında bir (≈8 Hz) ilerletmek yeter.
		if now - site.last_min >= 0.05 or _snap or (_tick - delta) <= 0.0:
			if weather and weather.sim and weather.sim.ready():
				site.env["weather"] = String(weather.sim.type_id())
			site.advance(now)
	_tick -= delta
	if _tick > 0.0 and not _snap:
		return
	_tick = UPDATE_S
	_sync_view(now)
	_plan_builders(now)
	_sync_folk(now)
	_check_lines(now)
	_snap = false


# --- Saat ----------------------------------------------------------------------------------------------------------

func _now() -> float:
	return _clock.abs_minute() if _clock else 0.0


## Saatin kaynağı: oturum, Serbest Gez'in saati (CampWeather'ın bulduğu), yoksa kendi saati.
func _resolve_clock() -> GameClock:
	if _session and is_instance_valid(_session):
		var sc: Variant = _session.get(&"clock")
		if sc is GameClock:
			return sc
	var parent := get_parent()
	var session := parent.get_node_or_null(^"Session") if parent else null
	var sc2: Variant = session.get(&"clock") if session else null
	if sc2 is GameClock:
		return sc2
	var roam := parent.get_node_or_null(^"RoamTime") if parent else null
	var rc: Variant = roam.get(&"clock") if roam else null
	if rc is GameClock:
		return rc
	if _own_clock == null:
		_own_clock = GameClock.new(GameClock.ROAM_DAY, Daylight.MENU_MINUTE)
		_own_clock.set_place(Daylight.CAMP_LAT, Daylight.CAMP_DEC_OFFSET)
	return _own_clock


## Sınama ve geliştirme: saati dışarıdan verir.
func use_clock(c: GameClock) -> void:
	_clock = c
	_own_clock = c
	_connect_clock()


func _connect_clock() -> void:
	if _clock and not _clock.skipped.is_connected(_on_skipped):
		_clock.skipped.connect(_on_skipped)


## Atlama (Bekle, uyku, çalışma): görünüm ve halk yeni saate oturur (perde altında ya da akan saatte).
func _on_skipped(_info: Dictionary) -> void:
	_snap = true


# --- Şantiye -------------------------------------------------------------------------------------------------------

## İlk iniş: ustalar 20 gerçek sn sonra iner (06:00–22:00 dışında ertesi 06:00).
func _fresh_site() -> void:
	var now := _now()
	var arr: Dictionary = spec.get("arrival", {})
	var delay := float(arr.get("delay_real_s", 20.0)) / Labour.real_s_per_min()
	var win: Array = arr.get("window", ["06:00", "22:00"])
	var at := now + delay
	var dm := fposmod(at, 1440.0)
	var a := SiteState.day_min(win[0])
	var b := SiteState.day_min(win[1])
	if dm < a:
		at = floorf(at / 1440.0) * 1440.0 + a
	elif dm >= b:
		at = floorf(at / 1440.0) * 1440.0 + 1440.0 + a
	pending = {"start": at, "child": {"water": 0, "logs": 0, "ember": 0}}


func _start_if_due(now: float) -> void:
	if site != null or pending.is_empty() or now < float(pending["start"]):
		return
	var ch: Dictionary = (pending.get("child", {}) as Dictionary).duplicate()
	ch["joined"] = joined
	site = SiteRules.camp3(float(pending["start"]), {"child": ch})
	pending = {}
	_connect_site()


func _connect_site() -> void:
	if site == null:
		return
	if not site.step_finished.is_connected(_on_step_finished):
		site.step_finished.connect(_on_step_finished)
	if not site.finished.is_connected(_on_finished):
		site.finished.connect(_on_finished)
	if yurt and is_instance_valid(yurt):
		yurt.bind_site(site)


func _on_step_finished(step_id: String, at: float) -> void:
	var next := site.current_id() if site else ""
	# Atlamada (uyku, Bekle) geçmişte biten adımın sözü söylenmez: uyanınca söz yağmuru olmasın (bitişin kartı ve ailenin satırı söylenir).
	var quiet := _now() - at > 2.0
	if next == "y_uuk" and int(site.child.get("logs", 0)) < 4:
		_say_key("logs", quiet)
	elif not next.is_empty():
		_say_key(next, quiet)
	if step_id == "y_uuk" or next == "y_ocak":
		_snap = true


func _on_finished(at: float) -> void:
	site_done.emit(at)
	if weather and weather.sim:
		weather.sim.refresh_exclude()


## Kalan sürenin kestirimi (oyun dk; bilinmiyorsa eksi).
func eta_min() -> float:
	if site == null:
		return -1.0 if pending.is_empty() else float(pending["start"]) - _now() + 870.0
	var e := site.eta()
	return e - _now() if is_finite(e) else -1.0


# --- Kayıt ---------------------------------------------------------------------------------------------------------

## Yolculuğun kayıtlı «sites» bloğu (yoksa null): oturumun kaydında, kaydın bloklarında ya da bekleyen bloklarda.
static func saved_block(p_journey: Object) -> Variant:
	if p_journey == null:
		return null
	var live: Variant = p_journey.get("live_blocks")
	if live is SaveBlocks and (live as SaveBlocks).has_block(BLOCK):
		return (live as SaveBlocks).collect().get(BLOCK)
	for field: StringName in [&"blocks", &"pending_blocks"]:
		var d: Variant = p_journey.get(field)
		if d is Dictionary and (d as Dictionary).get(BLOCK) is Dictionary:
			return (d as Dictionary)[BLOCK]
	return null


## Blok (zones.tanhu_camp.sites.camp3; öteki zonlar taşınır).
func to_block() -> Dictionary:
	var zones := _other_zones.duplicate(true)
	var entry: Dictionary = {}
	if site:
		entry = site.to_dict()
		entry["fam"] = {"wait": site.opts.get("family_wait"), "ember_by": str(site.opts.get("ember_by", "")),
			"gate": site.gates.get("y_ocak")}
		entry["told"] = told
	elif not pending.is_empty():
		entry = {"v": 2, "pending": true, "start": float(pending["start"]), "child": (pending.get("child", {}) as Dictionary).duplicate()}
	var zone: Dictionary = (zones.get(ZONE, {}) as Dictionary).duplicate(true)
	var list: Dictionary = (zone.get("sites", {}) as Dictionary).duplicate(true)
	if entry.is_empty():
		list.erase(SITE_ID)
	else:
		list[SITE_ID] = entry
	zone["sites"] = list
	zones[ZONE] = zone
	return {"zones": zones}


## Bloğu okur: camp3 kayıttaki yerinden kurulur (aile kuralının olayları yeniden kurulur, kayıttan önceki olaylar atılır). → okundu mu.
func load_block(d: Dictionary) -> bool:
	if not SiteState.validate_save_block(d).is_empty():
		return false
	var zones: Dictionary = (d.get("zones", {}) as Dictionary).duplicate(true)
	var zone: Dictionary = zones.get(ZONE, {})
	var entry: Variant = (zone.get("sites", {}) as Dictionary).get(SITE_ID)
	_other_zones = zones
	if not entry is Dictionary:
		return false
	var e: Dictionary = entry
	if bool(e.get("pending", false)):
		site = null
		var ch: Dictionary = e.get("child", {}) if e.get("child") is Dictionary else {}
		pending = {"start": float(e.get("start", _now())), "child": {"water": clampi(int(ch.get("water", 0)), 0, 2),
			"logs": clampi(int(ch.get("logs", 0)), 0, 4), "ember": clampi(int(ch.get("ember", 0)), 0, 1)}}
		return true
	if not (e.get("start") is float or e.get("start") is int):
		return false
	var s := SiteRules.camp3(float(e["start"]), {})
	if not s.from_dict(e):
		return false
	s.drop_events_until(s.last_min)
	var fam: Variant = e.get("fam", {})
	if fam is Dictionary:
		var f := fam as Dictionary
		if f.get("wait") is bool:
			s.opts["family_wait"] = bool(f["wait"])
		if not str(f.get("ember_by", "")).is_empty():
			s.opts["ember_by"] = str(f["ember_by"])
		if f.get("gate") is float or f.get("gate") is int:
			s.gates["y_ocak"] = float(f["gate"])
	if site and site.step_finished.is_connected(_on_step_finished):
		site.step_finished.disconnect(_on_step_finished)
		site.finished.disconnect(_on_finished)
	site = s
	pending = {}
	told = bool(e.get("told", s.is_done()))
	joined = false
	_connect_site()
	return true


## Bloğu yolculuğa yazar (kaydetmeden önce): oturumun kaydı bloğu tutuyorsa bir şey yazılmaz.
func store_into(p_journey: Object) -> void:
	if p_journey == null or (site == null and pending.is_empty()):
		return
	var live: Variant = p_journey.get("live_blocks")
	if live is SaveBlocks and (live as SaveBlocks).has_block(BLOCK):
		return
	var d: Variant = p_journey.get(&"blocks")
	if d is Dictionary:
		(d as Dictionary)[BLOCK] = to_block()


## Oturumun blok kaydına bağlanır (Session.blocks; kayıt v2).
func register_block(blocks: SaveBlocks) -> void:
	if blocks == null:
		return
	blocks.register(BLOCK, BLOCK_V, to_block, func(d: Dictionary) -> bool: return load_block(d),
		{"check": SiteState.validate_save_block, "order": BLOCK_ORDER, "max_bytes": 20 * 1024})


# --- Görünüm -------------------------------------------------------------------------------------------------------

func _camp() -> Node3D:
	return world.get_node_or_null(^"Camp") as Node3D if world and is_instance_valid(world) else null


func _ground() -> Object:
	return world.call(&"get_terrain_shape") if world and is_instance_valid(world) and world.has_method(&"get_terrain_shape") else null


func _ground_y(xz: Vector2) -> float:
	var g := _ground()
	return float(g.call(&"height_at", xz.x, xz.y)) if g else 0.0


func _site_xz() -> Vector2:
	var at: Array = spec.get("at", [4.0, -18.0])
	return Vector2(float(at[0]), float(at[1]))


func _stock_xz() -> Vector2:
	var at: Array = spec.get("stock_at", [0.8, -13.0])
	return Vector2(float(at[0]), float(at[1]))


func _entry_xz() -> Vector2:
	var at: Array = spec.get("entry", [2.0, -29.0])
	return Vector2(float(at[0]), float(at[1]))


func _node_xz(path: NodePath, fallback: Vector2) -> Vector2:
	var n := world.get_node_or_null(path) as Node3D if world and is_instance_valid(world) else null
	return Vector2(n.global_position.x, n.global_position.z) if n else fallback


func _build_view() -> void:
	var camp := _camp()
	if camp == null:
		return
	var old := camp.get_node_or_null(NodePath(ROOT_NAME))
	if old:
		camp.remove_child(old)
		old.queue_free()
	root = Node3D.new()
	root.name = ROOT_NAME
	camp.add_child(root)
	var sxz := _site_xz()
	yurt = StagedYurt.new()
	yurt.name = "Yurt"
	yurt.configure({"size": str(spec.get("size", "m")), "style": str(spec.get("style", "hun")), "layout": str(spec.get("layout", "otaci")),
		"preset": str(spec.get("preset", "hero")), "open": true})
	yurt.ground = _ground()
	yurt.stage = -1
	root.add_child(yurt)
	yurt.global_position = Vector3(sxz.x, _ground_y(sxz), sxz.y)
	yurt.rotation.y = float(spec.get("rot", 0.0))
	if site:
		yurt.bind_site(site)
	else:
		yurt.set_stage(-1, 0.0, false)
	_build_torches()
	_rebuild_stock(true)
	for m: Dictionary in spec.get("crew", []):
		_make_builder(m)
	_hide_grass()
	_refresh_obstacles()


func _teardown() -> void:
	_leave_crew(false)
	_restore_grass()
	_restore_folk()
	if root and is_instance_valid(root):
		root.get_parent().remove_child(root)
		root.queue_free()
	root = null
	yurt = null
	builders.clear()
	_torches.clear()
	_stock_key = ""
	_held_roles.clear()
	_refresh_obstacles()


func _refresh_obstacles() -> void:
	if player and is_instance_valid(player) and player.has_method(&"refresh_obstacles"):
		player.call_deferred(&"refresh_obstacles")


func _sync_view(now: float) -> void:
	if root == null or not is_instance_valid(root):
		return
	var stage := site.stage if site else -1
	if stage != _last_stage:
		_last_stage = stage
		_refresh_obstacles()
	_rebuild_stock(false)
	var dm := fposmod(now, 1440.0)
	var night := (_clock.below_horizon() if _clock and _clock.has_place() else (dm >= SUNSET_DM or dm < DAWN_DM))
	var started := site != null
	var burning := started and night and (not site.is_done() or now < site.finished_at + 20.0)
	if burning and not said.has("dusk") and not site.is_done():
		_say_key("dusk")
	for t in _torches:
		t.visible = burning


## Meşale direkleri (bedava ışık, structures.md §10.2): kapının iki yanında, gölgesiz ışık.
func _build_torches() -> void:
	_torches.clear()
	var rot := float(spec.get("rot", 0.0))
	var sxz := _site_xz()
	var pole_mat := Style.toon(Style.WOOD_DARK, {"brush_strength": 0.2})
	var flame_mat := StandardMaterial3D.new()
	flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame_mat.albedo_color = Color(1.0, 0.62, 0.2)
	flame_mat.emission_enabled = true
	flame_mat.emission = Color(1.0, 0.5, 0.15)
	flame_mat.emission_energy_multiplier = 2.4
	for side: float in [-1.0, 1.0]:
		var local := Vector2(side * 2.6, 4.9)
		var w := sxz + local.rotated(-rot)
		var t := Node3D.new()
		t.name = "Torch%s" % ("L" if side < 0.0 else "R")
		root.add_child(t)
		t.global_position = Vector3(w.x, _ground_y(w), w.y)
		var pole := MeshInstance3D.new()
		pole.mesh = Procedural3D.cylinder(0.035, 0.05, 1.9, 6)
		pole.material_override = pole_mat
		pole.position = Vector3(0.0, 0.95, 0.0)
		t.add_child(pole)
		var flame := MeshInstance3D.new()
		flame.mesh = Procedural3D.cylinder(0.0, 0.11, 0.34, 6)
		flame.material_override = flame_mat
		flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		flame.position = Vector3(0.0, 2.05, 0.0)
		t.add_child(flame)
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.66, 0.36)
		light.light_energy = 1.4
		light.omni_range = 8.5
		light.shadow_enabled = false
		light.position = Vector3(0.0, 2.2, 0.0)
		t.add_child(light)
		t.visible = false
		_torches.append(t)


## Malzeme yığını: kalan adımların parçaları (kütük, tündük, saz, keçe, ip, şırdak); adım bitince parçası kalkar. Görünüm yalnız sıradaki
## adım değişince kurulur.
func _rebuild_stock(force: bool) -> void:
	if root == null:
		return
	var from := site.step if site else 0
	var key := "%d" % from
	if key == _stock_key and not force:
		return
	_stock_key = key
	var old := root.get_node_or_null(^"Stock")
	if old:
		root.remove_child(old)
		old.queue_free()
	var pile := Node3D.new()
	pile.name = "Stock"
	root.add_child(pile)
	var sxz := _stock_xz()
	pile.global_position = Vector3(sxz.x, _ground_y(sxz), sxz.y)
	pile.rotation.y = float(spec.get("stock_rot", 0.0))
	var tools := {}
	var steps: Array = site.steps if site else SiteState.create("yurt", "m").steps
	var slot := 0
	for i in range(from, steps.size()):
		var sid := str((steps[i] as Dictionary).get("id", ""))
		if not STOCK_PARTS.has(sid):
			continue
		var part: Array = STOCK_PARTS[sid]
		var ck := str(part[0])
		if not tools.has(ck):
			var st := SurfaceTool.new()
			tools[ck] = st
		for k in int(part[1]):
			CampLife._stock_piece(tools[ck] as SurfaceTool, ck, slot, k)
			slot += 1
	for ck: String in tools:
		var st: SurfaceTool = tools[ck]
		var mi := MeshInstance3D.new()
		mi.name = ck.capitalize()
		mi.mesh = st.commit()
		mi.material_override = Style.toon(STOCK_COLORS[ck], {"brush_strength": 0.25})
		pile.add_child(mi)


## Yığının bir parçası: yerel uzayda (yığının merkezi, 3 × 2,4 m) yatık silindirler; slot sırası yığını kenardan doldurur.
static func _stock_piece(st: SurfaceTool, ck: String, slot: int, k: int) -> void:
	var row := slot % 6
	var layer := slot / 6
	var x := -1.15 + float(row) * 0.46
	var z := -0.7 + float(layer % 3) * 0.7
	var y := float(layer / 3) * 0.16
	var mesh: Mesh
	var xf := Transform3D.IDENTITY
	match ck:
		"wood":
			mesh = Procedural3D.cylinder(0.06, 0.07, 2.2, 6)
			xf = Transform3D(Basis(Vector3.BACK, PI * 0.5).rotated(Vector3.UP, 0.08 * float(k)), Vector3(0.0, 0.07 + y + 0.13 * float(k % 2), z))
		"crown":
			mesh = Procedural3D.cylinder(0.62, 0.62, 0.16, 12)
			xf = Transform3D(Basis(Vector3.RIGHT, 0.5), Vector3(1.0, 0.45, 0.85))
		"reed":
			mesh = Procedural3D.cylinder(0.2, 0.2, 1.4, 8)
			xf = Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(x, 0.2, 0.95 + 0.1 * float(k)))
		"felt", "rug":
			mesh = Procedural3D.cylinder(0.24, 0.24, 1.5, 10)
			xf = Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-1.0 + 0.52 * float(k) + (0.0 if ck == "felt" else 1.6), 0.24, -0.15))
		_:
			mesh = Procedural3D.cylinder(0.22, 0.22, 0.12, 10)
			xf = Transform3D(Basis.IDENTITY, Vector3(1.2 - 0.5 * float(k), 0.06, 0.4))
	st.append_from(mesh, 0, xf)


# --- Ustalar -------------------------------------------------------------------------------------------------------

func _make_builder(m: Dictionary) -> void:
	var id := str(m.get("id", ""))
	var r := StandIn.resolve(id)
	var a := CharacterAvatar.new()
	a.name = id.capitalize()
	a.model_override = str(r.get("model", ""))
	a.set_meta(StandIn.PERSON_META, str(r.get("id", id)))
	a.visible = false
	root.add_child(a)
	var tint: Color = r.get("tint", Color.WHITE)
	var sc := float(r.get("scale", 1.0))
	StandIn.apply(a, tint, sc)
	a.model_changed.connect(func(_mid: String) -> void: StandIn.apply(a, tint, sc))
	builders[id] = {"avatar": a, "pos": _entry_xz(), "goal": {}, "path": [], "clip": "", "index": builders.size()}


## Ustaların hedefi her 0,25 sn'de seçilir (şantiyenin durumundan, saf): gizli, varış, iş, öğün, sefer, bekleme, sevinç, ayrılış.
func _plan_builders(now: float) -> void:
	for id: String in builders:
		var b: Dictionary = builders[id]
		var goal := builder_goal(id, now)
		b["goal"] = goal
		var kind := str(goal.get("kind", "hidden"))
		var a: CharacterAvatar = b["avatar"]
		if kind == "hidden":
			a.visible = false
			b["path"] = []
			continue
		if goal.has("pos_at"):
			# Zamana bağlı yol (varış, sefer, ayrılış): yer saatten okunur.
			b["path"] = []
			a.visible = true
			continue
		var at: Vector2 = goal["at"]
		if _snap or not a.visible:
			b["pos"] = at
			b["path"] = []
			b["y_at"] = Vector2.INF
		elif (b["pos"] as Vector2).distance_to(at) > 0.3 and ((b["path"] as Array).is_empty() or ((b["path"] as Array).back() as Vector2).distance_to(at) > 0.3):
			b["path"] = route(b["pos"], at)
		a.visible = true


## Ustanın t anındaki hedefi: {kind, at (Vector2), face (Vector2), clip} ya da zamana bağlı yolda {kind, pos_at, speed, clip}.
func builder_goal(id: String, now: float) -> Dictionary:
	var idx := int((builders.get(id, {}) as Dictionary).get("index", 0))
	if site == null:
		if pending.is_empty():
			return {"kind": "hidden"}
		var t0 := float(pending["start"]) - ARRIVE_MIN
		if now < t0:
			return {"kind": "hidden"}
		var first := slot_xz("y_site", idx)
		var path := route(_entry_xz(), first)
		var f := clampf((now - t0) / ARRIVE_MIN, 0.0, 1.0)
		if f >= 1.0:
			return {"kind": "wait", "at": first, "face": _site_xz(), "clip": ""}
		return {"kind": "arrive", "pos_at": CampLife.along(path, f), "speed": CampLife.length_of(path) / (ARRIVE_MIN * Labour.real_s_per_min()),
			"clip": ""}
	if site.is_done():
		return _goal_after_done(id, idx, now)
	var m := _member(id)
	var sid := site.current_id()
	for e_key: String in site.errands:
		var e: Dictionary = site.errands[e_key]
		if str(e.get("who", "")) == id and e.has("trip_from") and now >= float(e["trip_from"]) and now < float(e["trip_to"]):
			return _trip_goal(e_key, e, idx, now)
	if not site.present(m, now):
		if _in_meal(m, now):
			return {"kind": "meal", "at": _meal_xz(idx), "face": _stock_xz(), "clip": MEAL_CLIP}
		return {"kind": "hidden"}
	var at := slot_xz(sid, idx)
	var face := _site_xz() if not (sid == "y_ocak" and idx == 1) else _site_xz() + Vector2(0.0, 0.25).rotated(-float(spec.get("rot", 0.0)))
	if site.rate <= 0.0:
		var reason := str(site.wait_reason) if site.wait_reason != null else ""
		if reason == "story" or reason == "weather" or reason == "storm":
			var door := slot_xz("y_esik", idx)
			return {"kind": "wait", "at": door, "face": _site_xz(), "clip": WAIT_CLIP if reason == "story" else ""}
	return {"kind": "work", "at": at, "face": face, "clip": str(STEP_CLIPS.get(sid, ""))}


func _goal_after_done(id: String, idx: int, now: float) -> Dictionary:
	var done := site.finished_at
	var door := slot_xz("y_esik", idx)
	if now < done + CHEER_MIN:
		return {"kind": "cheer", "at": door, "face": _site_xz(), "clip": CHEER_CLIP}
	if id == "erka":
		# Erka Otacı Yurdu'nda yaşar (time.md §8.3): şafakta kapıda ot kurutur, öğünlerde kapısında yer; kalan saatler içeridedir.
		var dm := fposmod(now, 1440.0)
		var sit := slot_xz("y_esik", 0).lerp(slot_xz("y_esik", 1), 0.5)
		if dm >= 330.0 and dm < 390.0:
			return {"kind": "work", "at": sit, "face": sit + (sit - _site_xz()), "clip": "crouch_pick_place_f"}
		if (dm >= 720.0 and dm < 750.0) or (dm >= 1110.0 and dm < 1140.0):
			return {"kind": "meal", "at": sit, "face": sit + (sit - _site_xz()), "clip": MEAL_CLIP}
		return {"kind": "hidden"} if now >= done + CHEER_MIN + 1.0 else {"kind": "wait", "at": sit, "face": _site_xz(), "clip": ""}
	var t := (now - done - CHEER_MIN) / LEAVE_MIN
	if t >= 1.0:
		return {"kind": "hidden"}
	var path := route(door, _entry_xz())
	return {"kind": "leave", "pos_at": CampLife.along(path, t), "speed": CampLife.length_of(path) / (LEAVE_MIN * Labour.real_s_per_min()), "clip": ""}


## Dengiz'in seferi (su: kova; kütük: odunluk): her birim yığından kaynağa gidiş ve dönüştür; yer seferin anından okunur.
func _trip_goal(e_key: String, e: Dictionary, _idx: int, now: float) -> Dictionary:
	var unit := maxf(float(e.get("trip_min", 1.0)), 0.01)
	var k := (now - float(e["trip_from"])) / unit
	var f := k - floorf(k)
	var src := _node_xz(BUCKET, Vector2(4.89, -0.3)) if e_key == "water" else _node_xz(WOODPILE, Vector2(2.46, -10.3)) + Vector2(-0.9, -0.6)
	var way: Array[Vector2] = [_stock_xz() + Vector2(-0.6, 1.6)]
	if e_key == "water":
		way.append_array(CAMP_WAY)
	way.append(src)
	var length := CampLife.length_of(way)
	# Yürüyüş yürüme hızıyladır (en çok seferin %45'i bir yön); kalan süre kaynaktadır (kütük yakındadır: Dengiz orada kütüğü seçer, bağlar).
	var unit_s := unit * Labour.real_s_per_min()
	var walk_s := minf(length / WALK_MPS, unit_s * 0.45)
	var go := walk_s / unit_s
	var speed := length / maxf(walk_s, 0.01)
	if f < go:
		return {"kind": "trip", "pos_at": CampLife.along(way, f / go), "speed": speed, "clip": ""}
	if f < 1.0 - go:
		return {"kind": "trip", "pos_at": src, "speed": 0.0, "clip": "collect_object", "face": src}
	var back := way.duplicate()
	back.reverse()
	return {"kind": "trip", "pos_at": CampLife.along(back, (f - (1.0 - go)) / go), "speed": speed, "clip": str(CARRY_CLIPS.get(e_key, ""))}


func _member(id: String) -> Dictionary:
	for m: Variant in site.crew:
		if m is Dictionary and str((m as Dictionary).get("id", "")) == id:
			return m
	return {}


func _in_meal(m: Dictionary, now: float) -> bool:
	var dm := fposmod(now, 1440.0)
	for meal: Variant in m.get("meals", []):
		if meal is Array and (meal as Array).size() >= 2:
			var a := SiteState.day_min(meal[0])
			if SiteState._in_window(dm, a, a + float(meal[1])):
				return true
	return false


func _meal_xz(idx: int) -> Vector2:
	return _stock_xz() + Vector2(-1.2 + 1.2 * float(idx), 1.9).rotated(-float(spec.get("stock_rot", 0.0)))


## Adımın yuvası (dünya xz): yurdun yerel kutbundan (kapı +Z).
func slot_xz(step_id: String, idx: int) -> Vector2:
	var list: Array = SLOTS.get(step_id, SLOTS["y_kerege"])
	var s: Array = list[clampi(idx, 0, list.size() - 1)]
	return _polar(deg_to_rad(float(s[0])), float(s[1]))


func _polar(angle: float, r: float) -> Vector2:
	var rot := float(spec.get("rot", 0.0))
	return _site_xz() + Vector2(sin(rot + angle), cos(rot + angle)) * r


## İki nokta arasındaki yol (dünya xz): duvar kalktıysa (aşama ≥2) dışarıdaki iki nokta yurdu yay üstünden dolanır, içeri ve dışarı kapıdan
## geçilir; duvar yokken düz.
func route(a: Vector2, b: Vector2) -> Array[Vector2]:
	var out: Array[Vector2] = [a]
	var c := _site_xz()
	var wall := float(yurt.dims.get("radius", 3.3)) if yurt and is_instance_valid(yurt) else 3.3
	var up := site != null and site.stage >= 2
	var ra := a.distance_to(c)
	var rb := b.distance_to(c)
	if not up or (ra < wall and rb < wall):
		out.append(b)
		return out
	var rot := float(spec.get("rot", 0.0))
	var ang := func(p: Vector2) -> float: return wrapf(atan2(p.x - c.x, p.y - c.y) - rot, -PI, PI)
	var outer := wall + 0.8
	var from_angle: float = ang.call(a)
	var to_angle: float = ang.call(b)
	if ra < wall:
		out.append(_polar(0.0, wall - 0.6))
		out.append(_polar(0.0, outer))
		from_angle = 0.0
	if rb < wall:
		to_angle = 0.0
	var d := wrapf(to_angle - from_angle, -PI, PI)
	var n := int(ceil(absf(d) / deg_to_rad(30.0)))
	for i in range(1, n):
		out.append(_polar(from_angle + d * float(i) / float(n), maxf(outer, minf(ra, rb) if ra >= wall and rb >= wall else outer)))
	if rb < wall:
		out.append(_polar(0.0, outer))
		out.append(_polar(0.0, wall - 0.6))
	out.append(b)
	return out


static func length_of(path: Array) -> float:
	var t := 0.0
	for i in range(1, path.size()):
		t += (path[i - 1] as Vector2).distance_to(path[i])
	return t


## Yolun f oranındaki noktası (0..1).
static func along(path: Array, f: float) -> Vector2:
	if path.is_empty():
		return Vector2.ZERO
	var total := CampLife.length_of(path)
	var left := clampf(f, 0.0, 1.0) * total
	for i in range(1, path.size()):
		var seg := (path[i - 1] as Vector2).distance_to(path[i])
		if left <= seg or i == path.size() - 1:
			return (path[i - 1] as Vector2).lerp(path[i], clampf(left / maxf(seg, 1e-6), 0.0, 1.0))
		left -= seg
	return path.back()


## Her kare: yürüyen usta yolunda ilerler, varınca yüzü hedefe döner, klibi oynar.
func _move_builders(delta: float) -> void:
	for id: String in builders:
		var b: Dictionary = builders[id]
		var a: CharacterAvatar = b["avatar"]
		var goal: Dictionary = b["goal"]
		if not a.visible or goal.is_empty():
			continue
		var pos: Vector2 = b["pos"]
		var face := Vector2.INF
		var moving := 0.0
		if goal.has("pos_at"):
			var np: Vector2 = goal["pos_at"]
			if np.distance_to(pos) > 0.01:
				face = np + (np - pos).normalized()
			pos = np
			moving = float(goal.get("speed", 0.0))
			if goal.has("face"):
				face = goal["face"]
		else:
			var path: Array = b["path"]
			if not path.is_empty():
				var step := WALK_MPS * delta
				while step > 0.0 and not path.is_empty():
					var nxt: Vector2 = path[0]
					var d := pos.distance_to(nxt)
					if d <= step:
						pos = nxt
						step -= d
						path.pop_front()
					else:
						face = nxt
						pos = pos.move_toward(nxt, step)
						step = 0.0
				moving = WALK_MPS if not path.is_empty() else 0.0
			if path.is_empty():
				face = goal.get("face", Vector2.INF)
		b["pos"] = pos
		# Yer ve yön yalnız değişince yazılır (iskeletin dönüşümü her yazımda yayılır); zeminin yüksekliği yer değişince okunur.
		var last_xz: Vector2 = b.get("y_at", Vector2.INF)
		if last_xz.distance_squared_to(pos) > 0.0004:
			b["y_at"] = pos
			b["y"] = _ground_y(pos)
			a.global_position = Vector3(pos.x, float(b["y"]), pos.y)
		if face != Vector2.INF and face.distance_to(pos) > 0.05:
			var want := atan2(face.x - pos.x, face.y - pos.y)
			var cur := float(b.get("yaw", want))
			var yaw := want if moving > 0.0 or _snap else lerp_angle(cur, want, 1.0 - exp(-8.0 * delta))
			if not b.has("yaw") or absf(angle_difference(cur, yaw)) > 0.0005:
				b["yaw"] = yaw
				a.rotation.y = yaw
		var clip := str(goal.get("clip", "")) if moving <= 0.01 or goal.has("pos_at") else ""
		if moving > 0.01 and not (goal.has("pos_at") and not clip.is_empty()):
			var rate := maxf(moving, 0.6)
			if str(b["clip"]) != "walk" or absf(float(b.get("rate", 0.0)) - rate) > 0.05:
				b["clip"] = "walk"
				b["rate"] = rate
				a.play_walk(rate)
		elif not clip.is_empty():
			if str(b["clip"]) != clip:
				if a.play_job(clip):
					b["clip"] = clip
				else:
					# Model daha yüklenmedi (ya da klip kurulamadı): bekleme, sonraki karede yeniden denenir.
					a.set_locomotion(0.0)
		elif str(b["clip"]) != "idle":
			b["clip"] = "idle"
			a.set_locomotion(0.0)


# --- Ocak halkı ----------------------------------------------------------------------------------------------------

func _npcs() -> CampNpcs:
	return world.get_node_or_null(NPCS) as CampNpcs if world and is_instance_valid(world) else null


## Kişi t anında ateş başında mı (time.md §8.2; camp3 gecesi K83)?
func folk_at_fire(person: String, now: float) -> bool:
	var dm := fposmod(now, 1440.0)
	if site and not told and FOLK_WAIT.has(person):
		var check := float(site.opts.get("family_check_at", NAN))
		if is_finite(check):
			if now >= check - 30.0 and now < check:
				return true
			if now >= check and bool(site.opts.get("family_wait", false)) and (not site.is_done() or now < site.finished_at + 4.0):
				return true
	for w: Array in FOLK_HOURS.get(person, []):
		if SiteState._in_window(dm, float(w[0]), float(w[1])):
			return true
	return false


## Halkın görünüşü: istenen durum kadraj dışında ya da atlamada uygulanır (figür gözün önünde kaybolmaz).
func _sync_folk(now: float) -> void:
	var npcs := _npcs()
	if npcs == null:
		return
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	for person: String in FOLK_HOURS:
		var a := npcs.get_node_or_null(NodePath(person)) as Node3D
		if a == null:
			continue
		var want := folk_at_fire(person, now)
		if a.visible == want:
			continue
		if _snap or cam == null or CampLife.outside_view(cam, a.global_position + Vector3(0.0, 0.8, 0.0), 2.0):
			a.visible = want
			if want:
				_folk_hidden.erase(person)
			else:
				_folk_hidden[person] = true


## Halk menüdeki hâline döner (CampNpcs gizlenen modeli yeniden uygular).
func _restore_folk() -> void:
	var npcs := _npcs()
	_folk_hidden.clear()
	if npcs:
		npcs.set_hidden_model(npcs.hidden_model)


## Nokta (sınır küresi r) kameranın kesik konisinin dışında mı?
static func outside_view(cam: Camera3D, p: Vector3, r: float) -> bool:
	for pl: Plane in cam.get_frustum():
		if pl.distance_to(p) > r:
			return true
	return false


# --- Çocuğun yardımı -----------------------------------------------------------------------------------------------

func _child_ok() -> bool:
	return player and is_instance_valid(player) and player.is_inside_tree() and (not player.has_method(&"is_child") or bool(player.call(&"is_child")))


func _player_xz() -> Vector2:
	return Vector2(player.global_position.x, player.global_position.z) if player and is_instance_valid(player) else Vector2.INF


## Oyuncunun E'si (main.gd _interaction zincirinin başı): katıl, ayak işi al ya da bırak. Yoksa boş.
func interaction() -> Dictionary:
	if not running or not _child_ok():
		return {}
	var p := _player_xz()
	var lines: Dictionary = spec.get("lines", {})
	if not carry.is_empty():
		if p.distance_to(_stock_xz()) <= DROP_REACH:
			return {"key": "E", "label": _text(lines.get("%s_drop" % ("log" if carry == "logs" else carry))), "run": drop_carry}
		return {}
	var counts := _child_counts()
	if _errand_open("water") and int(counts.get("water", 0)) < 2 and p.distance_to(_node_xz(BUCKET, Vector2(4.89, -0.3))) <= BUCKET_REACH:
		return {"key": "E", "label": _text(lines.get("water_take")).replace("{n}", str(int(counts.get("water", 0)))), "run": take_carry.bind("water")}
	var wood_d := p.distance_to(_node_xz(WOODPILE, Vector2(2.46, -10.3)))
	# Odunluk yığına 3,4 m'dir: ikisinin arasında yakın olanın istemi çıkar (yığında «Ustalara Katıl»).
	if _errand_open("logs") and int(counts.get("logs", 0)) < 4 and wood_d <= WOOD_REACH and wood_d < p.distance_to(_stock_xz()):
		return {"key": "E", "label": _text(lines.get("log_take")).replace("{n}", str(int(counts.get("logs", 0)))), "run": take_carry.bind("logs")}
	if _errand_open("ember") and p.distance_to(_node_xz(FIRE, Vector2.ZERO)) <= FIRE_REACH:
		return {"key": "E", "label": _text(lines.get("ember_take")), "run": take_carry.bind("ember")}
	if site and not site.is_done() and not joined and _near_crew(p):
		return {"key": "E", "label": _text(lines.get("join")), "run": join}
	return {}


func _child_counts() -> Dictionary:
	return site.child if site else (pending.get("child", {}) as Dictionary)


## Ayak işi açık mı: su zemin adımı başlamadan, kütük uuk başlamadan, köz aşama 6'dan ocak başlayana dek (köz yığında değilse).
func _errand_open(kind_id: String) -> bool:
	if site == null:
		return kind_id == "water" and not pending.is_empty()
	if site.is_done():
		return false
	match kind_id:
		"water":
			return false
		"logs":
			return not bool((site.errands.get("logs", {}) as Dictionary).get("done", false))
		"ember":
			return not site.ember and site.stage >= 6 and not site.log.has("y_ocak")
	return false


func _near_crew(p: Vector2) -> bool:
	if p.distance_to(_stock_xz()) <= JOIN_REACH:
		return true
	for id: String in builders:
		var b: Dictionary = builders[id]
		if (b["avatar"] as Node3D).visible and (b["pos"] as Vector2).distance_to(p) <= JOIN_REACH:
			return true
	return false


func take_carry(kind_id: String) -> void:
	carry = kind_id
	_toast(_text((spec.get("lines", {}) as Dictionary).get("carry")))


func drop_carry() -> void:
	var k := carry
	carry = ""
	if k.is_empty():
		return
	if site:
		site.child_errand(k)
	else:
		var ch: Dictionary = pending.get("child", {})
		ch[k] = mini(int(ch.get(k, 0)) + 1, 2 if k == "water" else (4 if k == "logs" else 1))
		pending["child"] = ch
	if k == "water":
		_say_key("water")


## Çocuk ustalara katılır (yarım el): adımın fiilini oynar, yerinden ayrılınca çıkar.
func join() -> void:
	if site == null or site.is_done() or joined:
		return
	joined = true
	site.child["joined"] = true
	site.child["active"] = true
	_join_at = player.global_position
	_join_step = ""
	var c := _site_xz()
	if player.has_method(&"spawn_at"):
		player.call(&"spawn_at", player.global_position, atan2(c.x - _join_at.x, c.y - _join_at.z))
		_join_at = player.global_position
	_say_key("join")


## Ekipten çıkar (hareket girdisi; say: bildirim).
func _leave_crew(say: bool) -> void:
	if not joined:
		return
	joined = false
	if site:
		site.child["joined"] = false
	if player and is_instance_valid(player) and &"work_role" in player:
		player.set(&"work_role", &"")
	if say:
		_toast(_text((spec.get("lines", {}) as Dictionary).get("left")))


## Katılan Çocuk: hareket girdisi ya da yerinden ayrılış ekipten çıkarır; adımın fiili oyuncunun iş pozudur (work_role).
func _track_child(_now: float) -> void:
	if not joined:
		return
	if not _child_ok() or site.is_done():
		_leave_crew(false)
		return
	var moved := Vector2(player.global_position.x - _join_at.x, player.global_position.z - _join_at.z).length() > LEAVE_MOVE
	if moved or (InputMap.has_action(&"move_forward") and InputSetup.move_vector() != Vector2.ZERO):
		_leave_crew(true)
		return
	var st := site.current_step()
	var sid := str(st.get("id", ""))
	if sid == _join_step:
		return
	_join_step = sid
	var verb := ""
	for h: Variant in st.get("help", []):
		if HELP_CLIPS.has(str(h)):
			verb = str(h)
	if st.get("child", true) == false or verb.is_empty():
		player.set(&"work_role", &"")
		_toast(_text((spec.get("lines", {}) as Dictionary).get("no_child")))
		return
	var role := StringName("camp_%s" % verb)
	if not _held_roles.has(role) and player.has_method(&"_add_held_clip"):
		_held_roles[role] = bool(player.call(&"_add_held_clip", role, str(HELP_CLIPS[verb])))
	if bool(_held_roles.get(role, false)):
		player.set(&"work_role", role)


# --- Sözler --------------------------------------------------------------------------------------------------------

func _text(v: Variant) -> String:
	if v is Dictionary:
		return str((v as Dictionary).get(lang, (v as Dictionary).get("tr", "")))
	return str(v) if v != null else ""


## Ustanın sözü (sites.json say; bir kez, oyuncu 30 m'deyse). Altyazıdır: seslendirme sonra (vo_lines).
func _say_key(key: String, quiet: bool = false) -> void:
	if said.has(key):
		return
	var row: Variant = (spec.get("say", {}) as Dictionary).get(key)
	if not row is Array or (row as Array).size() < 2:
		return
	said[key] = true
	var p := _player_xz()
	if quiet:
		return
	if p == Vector2.INF or p.distance_to(_site_xz()) > 30.0:
		return
	var who := str(row[0])
	_say(_crew_name(who), _text(row[1]))


func _say(speaker: String, text: String) -> void:
	if hud == null or text.is_empty():
		return
	hud.say(speaker, text, StoryHud.line_seconds(text), _hud_clock)


func _crew_name(id: String) -> String:
	for m: Dictionary in spec.get("crew", []):
		if str(m.get("id", "")) == id:
			return _text(m.get("name"))
	return id.capitalize()


func _toast(text: String) -> void:
	if toast and is_instance_valid(toast) and toast.has_method(&"show_text") and not text.is_empty():
		toast.call(&"show_text", text, "info")


## Saatin sözleri: ekibin kalan süresi (yurda 10 m girişte), gece, yağmur, «Ocak tanla yakılacak», bitişin kartı ve ailenin satırı.
func _check_lines(now: float) -> void:
	if site == null:
		return
	var lines: Dictionary = spec.get("lines", {})
	var p := _player_xz()
	var near := p != Vector2.INF and p.distance_to(_site_xz()) <= PLACE_REACH
	if near and not _near_site and not site.is_done():
		_toast(crew_text(now))
	_near_site = near
	if not site.is_done():
		if fposmod(now, 1440.0) >= 1380.0 and site.log.has("y_tunduk"):
			_say_key("night")
		if str(site.wait_reason) == "weather":
			if not _rain_said:
				_rain_said = true
				said.erase("rain")
				_say_key("rain")
		else:
			_rain_said = false
		var check := float(site.opts.get("family_check_at", NAN))
		if is_finite(check) and now >= check and site.opts.get("family_wait") == false and not said.has("hearth_dawn"):
			said["hearth_dawn"] = true
			_toast(_text(lines.get("hearth_dawn")))
		return
	if told:
		return
	told = true
	_say_key("done")
	if card.is_valid():
		card.call(_text(lines.get("done_card")), 3.2)
	var saw: Variant = SiteRules.family_saw_smoke(site)
	var key := "dawn" if saw == false else "night"
	var mother := _text(((spec.get("speakers", {}) as Dictionary).get("mother", {})))
	var t := get_tree().create_timer(4.0) if is_inside_tree() else null
	if t:
		t.timeout.connect(func() -> void: _say(mother, _text(lines.get(key))))
	else:
		_say(mother, _text(lines.get(key)))


## «Yeni Yurt · Kerege — Ekip: 3 el · ≈3 saat» (Çocuk katıldıysa «+ sen»).
func crew_text(now: float) -> String:
	var lines: Dictionary = spec.get("lines", {})
	var n := 0
	for m: Variant in site.members_at(now):
		if str((m as Dictionary).get("role", "")) != "child":
			n += 1
	var left := eta_min()
	var hours := int(round(left / 60.0)) if left > 0.0 else 0
	var h := _text(lines.get("hour")) if hours <= 1 else _text(lines.get("hours")).replace("{n}", str(hours))
	var crew := _text(lines.get("crew_you" if joined else "crew")).replace("{n}", str(n)).replace("{h}", h)
	var step_name := _text(((spec.get("step_names", {}) as Dictionary).get(site.current_id(), {})))
	return "%s · %s — %s" % [_text(spec.get("name")), step_name, crew]


# --- Çayır ---------------------------------------------------------------------------------------------------------

## Yurdun (r 4,3) ve yığının (r 2,2) altındaki çayır ve çiçek örnekleri sıfır ölçeğe iner; end() geri koyar (menü karesi değişmez).
func _hide_grass() -> void:
	_restore_grass()
	var meadow := world.get_node_or_null(MEADOW) if world and is_instance_valid(world) else null
	if meadow == null:
		return
	var circles: Array[Vector3] = [Vector3(_site_xz().x, _site_xz().y, 4.3), Vector3(_stock_xz().x, _stock_xz().y, 2.2)]
	for mmi: MultiMeshInstance3D in meadow.find_children("*", "MultiMeshInstance3D", true, false):
		var mm := mmi.multimesh
		if mm == null:
			continue
		# Kare süzgeci: Meadow'un kareleri «Önek_x_z_model» adlıdır (Scatter.chunk_key, kare chunk_size m); adı tutmayan kare tek tek sınanır.
		var parts := String(mmi.name).split("_")
		if parts.size() == 4 and parts[1].is_valid_int() and parts[2].is_valid_int():
			var cs := float(meadow.get(&"chunk_size")) if meadow.get(&"chunk_size") != null else 12.0
			var x0 := float(int(parts[1])) * cs - 1.0
			var z0 := float(int(parts[2])) * cs - 1.0
			var hit := false
			for c in circles:
				if c.x + c.z >= x0 and c.x - c.z <= x0 + cs + 2.0 and c.y + c.z >= z0 and c.y - c.z <= z0 + cs + 2.0:
					hit = true
			if not hit:
				continue
		var gx := mmi.global_transform
		for i in mm.instance_count:
			var t := mm.get_instance_transform(i)
			var w := gx * t.origin
			for c in circles:
				if Vector2(w.x - c.x, w.z - c.y).length_squared() <= c.z * c.z:
					_hidden_grass.append([mm, i, t])
					mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * 0.0001), t.origin))
					break


## Gizlenen çayır örneği sayısı (sınama).
func hidden_grass_count() -> int:
	return _hidden_grass.size()


func _restore_grass() -> void:
	for e: Array in _hidden_grass:
		var mm: MultiMesh = e[0]
		if is_instance_valid(mm):
			mm.set_instance_transform(int(e[1]), e[2])
	_hidden_grass.clear()


# --- Hava ve geliştirme --------------------------------------------------------------------------------------------

func _bind_weather() -> void:
	if weather and weather.sim:
		weather.sim.structure_done = structure_done
		weather.sim.refresh_exclude()


func _dev_args() -> Dictionary:
	var out := {}
	for arg in OS.get_cmdline_user_args():
		if not arg.begins_with("--camp3"):
			continue
		var eq := arg.find("=")
		out[arg.substr(2, eq - 2) if eq > 0 else arg.substr(2)] = arg.substr(eq + 1) if eq > 0 else "true"
	return out


func _apply_dev_site() -> void:
	if _dev.is_empty():
		return
	var now := _now()
	if _dev.has("camp3-from"):
		var dm := GameClock.parse_hhmm(str(_dev["camp3-from"]))
		if dm >= 0.0:
			var start := floorf(now / 1440.0) * 1440.0 + dm
			if start > now:
				start -= 1440.0
			site = SiteRules.camp3(start, {"child": {"joined": _dev.has("camp3-join")}})
			pending = {}
			told = false
			_connect_site()
			site.advance(now)
	if _dev.has("camp3-stage") and str(_dev["camp3-stage"]).is_valid_int():
		if site == null:
			site = SiteRules.camp3(now - 1.0, {})
			pending = {}
			_connect_site()
		site.ensure_stage(int(str(_dev["camp3-stage"])))
		site.advance(now)
