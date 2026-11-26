class_name Session
extends Node
## Oturum (godot.md §3.1; Yol Haritası session-core): bir yolculuğun saf sistemlerini tutar ve her kare sabit sırayla adım attırır.
## Main'in çocuğudur: Serbest Gez'de ve kayıttan yüklemede kurulur (I. Perde gelince Yeni Oyun'da da), menüye dönüşte silinir;
## dünya değişiminden sağ çıkar (dünya WorldHost'tadır, oturum Main'de). Yeni autoload değildir (§1 madde 7).
##
## Sistem sırası (STEPS; her kare, _process'te ya da sınamada tick(dt)):
##    1 clock       GameClock (oturumun saati; duvar süresiyle birikir, kare başına en çok 0,25 sn; K20, K67)
##    2 calendar    GameCalendar
##    3 weather     WeatherPlanner, WetState, SnowPack
##    4 needs       Needs (Tokluk, Yara)
##    5 sites       SiteState (emek)
##    6 settlement  Settlement: yalnız saat başında (üyenin on_hour(info)'su, o karede geçilen her saat için; atlamanın saatleri skipping)
##    7 schedule    Schedule (kişiler)
##    8 fauna       FaunaDirector
##    9 stealth     Stealth
##   10 combat      Combat, Projectiles
##   11 quests      Quests; ardından sıradaki etkiler (queue_effects) uygulanır
##  11b party       PartyManager, Approval (yoldaşlar, K70: onay olayları etkilerin sonucunu okur; iş, yara ve ayrılık saat başındadır)
##   12 audio       Ses durumu
## Üye saf bir nesnedir (step(dt); saat başı adımında on_hour(info)) ya da Callable: add_system(adım, nesne, kimlik). Görünüm düğümleri
## (SkyRig, WeatherView, SiteView, CrowdField) sonra çalışır: oturumun process_priority'si 1'dir (PlayerController 0'dan sonra,
## FollowController 5 ve FollowCamera 10'dan önce).
##
## Saatin durma nedenleri (time.md §6.2): dialogue, cine, modal, map, pause (GameClock.REASONS'tan herhangi biri; frozen, dev de).
## set_pause(neden, açık, sahip): neden, onu tutan bir sahip kaldıkça açıktır (iki pencere aynı nedeni tutabilir); pause_changed yayılır.
## Ağacın duraklatılması (duraklatma kitabı, Envanter: get_tree().paused) oturumu da durdurur ve «pause» nedenini kendiliğinden tutar;
## sinema bind_cine ile «cine» nedenine bağlanır (CineHost.clock_hold_changed).
##
## Sinyaller: saatin olayları olduğu gibi aktarılır (hour_passed, day_changed, dawn, dusk, phase_changed, hold_changed, summoned,
## skipped; GameClock'ta varsa), pause_changed, autosave_requested(reason), event(name, payload) (etkilerin emit op'u), act_changed.
##
## Oto kayıt (godot.md §3.4, d2/core.md §6.2): request_autosave(neden, bilgi). Nedenler AUTOSAVE_REASONS; zorunlular (AUTOSAVE_FORCED)
## engele ve araya bakmaz; region ve caravan son oto kayıttan ≥60 sn sonra, wait ve work ≥1 oyun saatinde yazılır; sinema ve
## block_autosave'in sahipleri (boss fazı, sürüş) öteki nedenleri bekletmez, düşürür. Saatin atlaması (wait, work, sleep, rest) ve
## hikâye kipinde Tan kendiliğinden ister; pencere kapanırken pagehide. Oturum yalnız sinyal yayar, yazmayı Main yapar (SaveSystem 0).
##
## Kayıt (SaveBlocks): oturum kendi bloklarını kaydeder, öteki sistemler kendi bloklarını session.blocks.register ile ekler; setup'tan
## sonra kaydeden sistem kayıttaki bloğunu o an okur (SaveBlocks taşıdığını verir). setup yolculuğun kayıtlı bloklarını (Journey.blocks)
## okur ve kaydı yolculuğa bağlar (Journey.live_blocks); kapanırken blokların son hâli Journey.blocks'a geçer. Serbest Gez'in ışığı
## (RoamTime) oturumun saatini kullanır (main.gd _begin_roam_time: begin(..., session.clock)): saati oturum adım attırır ve kaydeder,
## RoamTime yalnız örnek üretir. Kamp havası (CampWeather) kendi weather bloğunu ve 3. adımdaki yerini main.gd'de alır.
## Oturumun blokları (okunma sırasıyla):
##   map          {v, id, pos [x, y, z], yaw}: dünyanın kimliği ve oyuncunun yeri (map_source yazar; okunan map_block'ta durur, Main oraya
##                indirir). Kayıtta yoksa (v1, eski v2) boştur: oyuncu kampta, kaydın yerinde belirir.
##   clock        GameClock.to_dict (godot.md §3.5).
##   progression  Progression.to_dict (progression.md §13.2 «player»); yoksa reset_player(profilin kökeni).
##   inventory    Inventory.to_dict (economy.md §12); yoksa yetişkin beden ve I. Perde'nin başlangıç donanımı (act1_start). Bozuk blok
##                (sözlük değil) okunamaz: kayıt boş yuva sayılır.
## Bağlar: envanter her Tan'da on_dawn(gün), uzun atlamada on_long_skip(şafak), bayrakta on_flag (sentenced: el koyma), dünya değişince
## set_world (main.gd); ilerleme bayrakta on_flag_set, perde geçişinde act_change, görev bitince on_quest_done; ilerlemenin Bilek'i ve
## Sırt Yükü envanterin sınırına yazılır. Etki hizmetleri «inventory» ve «progress»; koşul kaynakları level, stat., skill: ve item:.
## Hikâye kipinde takvim günü (NewGameFlow.DAY_FLAG) saatle aynı yönde yürür: gece yarısında ve uzun atlamada saatin gününe ilerler.
##
##   var session := Session.new()
##   var err := session.setup(journey, Session.MODE_ROAM)    # "" ise hazır
##   main.add_child(session)
##   session.add_system(&"weather", planner, &"weather_planner")
##   session.set_pause(&"dialogue", true, &"dialogue_box")
##   session.autosave_requested.connect(func(reason: StringName) -> void: journey.save_auto(reason))

signal pause_changed(reason: StringName, on: bool)
signal autosave_requested(reason: StringName)
signal event(event_name: StringName, payload: Variant)
signal act_changed(act: int)
signal clock_replaced(clock: GameClock)
signal hour_passed(info: Dictionary)
signal day_changed(info: Dictionary)
signal dawn(info: Dictionary)
signal dusk(info: Dictionary)
signal phase_changed(info: Dictionary)
signal hold_changed(info: Dictionary)
signal summoned(info: Dictionary)
signal skipped(info: Dictionary)

const STEPS: Array[StringName] = [
	&"clock", &"calendar", &"weather", &"needs", &"sites", &"settlement", &"schedule", &"fauna", &"stealth", &"combat",
	&"quests", &"party", &"audio",
]
## Adımın tasarımdaki numarası (godot.md §3.1).
const STEP_LABELS := {
	&"clock": "1", &"calendar": "2", &"weather": "3", &"needs": "4", &"sites": "5", &"settlement": "6", &"schedule": "7",
	&"fauna": "8", &"stealth": "9", &"combat": "10", &"quests": "11", &"party": "11b", &"audio": "12",
}
## Adımın sistemleri (godot.md §3.1, §3.7).
const STEP_SYSTEMS := {
	&"clock": "GameClock", &"calendar": "GameCalendar", &"weather": "WeatherPlanner, WetState, SnowPack",
	&"needs": "Needs (Tokluk, Yara)", &"sites": "SiteState (emek)", &"settlement": "Settlement (yalnız saat başında)",
	&"schedule": "Schedule (kişiler)", &"fauna": "FaunaDirector", &"stealth": "Stealth", &"combat": "Combat, Projectiles",
	&"quests": "Quests, Effects", &"party": "PartyManager, Approval", &"audio": "Ses durumu",
}
## Yalnız saat başında adım atan adımlar.
const HOURLY: Array[StringName] = [&"settlement"]
const MODE_ROAM := &"roam"
const MODE_STORY := &"story"
## Saatin durma nedenleri (godot.md §3.1).
const PAUSE_REASONS: Array[StringName] = [&"dialogue", &"cine", &"modal", &"map", &"pause"]
## Oto kayıt nedenleri (d2/core.md §6.2).
const AUTOSAVE_REASONS: Array[StringName] = [
	&"dawn", &"sleep", &"wait", &"work", &"quest_done", &"level_spend", &"region", &"act", &"world", &"fire", &"rest",
	&"depart", &"alight", &"pagehide", &"to_menu", &"tier", &"caravan", &"court_path",
]
const AUTOSAVE_FORCED: Array[StringName] = [&"act", &"world", &"depart", &"alight", &"pagehide", &"to_menu", &"court_path"]
## Son oto kayıttan en az AUTOSAVE_GAP_S sonra yazılanlar.
const AUTOSAVE_SPACED: Array[StringName] = [&"region", &"caravan"]
## En az AUTOSAVE_MIN_MINUTES oyun dakikası süren atlamada yazılanlar.
const AUTOSAVE_TIMED: Array[StringName] = [&"wait", &"work"]
const AUTOSAVE_GAP_S := 60.0
const AUTOSAVE_MIN_MINUTES := 60.0
## Saatin atlama nedeni → oto kayıt nedeni (uyku bilgisi «sleep»).
const SKIP_AUTOSAVE := {&"wait": &"wait", &"work": &"work", &"sleep": &"sleep", &"rest": &"rest"}
const PROCESS_PRIORITY := 1
## Hikâye kipinde saat bloğu yoksa açılış günü (Gün I; NewGameFlow.DAY_FLAG yazılmışsa o) ve dakikası (10:00: Köprü 2'nin bitişi,
## Kantu'nun giriş seferinin başı; time.md §6.4).
const STORY_DAY := 1041
const STORY_MINUTE := 600.0
## Haritanın açılış saati (kayıtlı saat yokken; kipten bağımsız): deneme haritası K76'nın açılış saatindedir (11 Nisan MÖ 209 14:46,2;
## ışığının örneği «afternoon» bu andır; I. Perde'nin son günü). Kimlik → [day_n, dakika].
const MAP_START := {"testmap": [GameClock.ROAM_DAY, Daylight.MENU_MINUTE]}
## map bloğunun sürümü.
const MAP_BLOCK_V := 1
## Envanterin bloğu yokken yetişkinin başlangıç donanımı (items.json kits).
const START_KIT := "act1_start"
## Ambar'dan el konan çuvalın geri alındığı görev (economy.md §4.4, progression.md §6.1).
const SEIZED_RETURN_QUEST := "mq_errands"
## Kampın dışındaki dünyaların enlemi: haritanın ışık dosyasındaki lat (data/maps/<id>/light.json). Kimlik → {lat, dec_offset}.
static var _places: Dictionary = {}

## Süren yolculuk (işaretler, kip, perde, dünya, tohum).
var journey: Journey
var mode: StringName = MODE_ROAM
## Oturumun saati (adım 1).
var clock: GameClock
## Blok kaydı (kayıt v2).
var blocks := SaveBlocks.new()
## Oyuncunun envanteri ve ilerlemesi (kayıt v2'nin inventory ve progression blokları): setup kurar ve kayıttan okur, Main HUD'a verir
## (gameplay_hud.bag.set_inventory, vitals.bind_progression).
var inventory: Inventory
var progression: Progression
## map bloğunun yazarı (Main): () -> {id, pos: [x, y, z], yaw}. Boşsa ya da boş sözlük dönerse son okunan blok yazılır.
var map_source: Callable
## Kayıttan okunan map bloğu ({id, pos, yaw}; kayıtta yoksa boş). Main oyuncuyu buraya indirir (saved_place).
var map_block: Dictionary = {}
## Kayıtta olmayıp varsayılanından kurulan oturum blokları (blok adı → true): yeni yolculuk ya da eski kayıt (fresh).
var _fresh: Dictionary = {}
## _process kendi adım atsın mı (sınama kapatıp tick'i kendisi çağırır).
var auto_tick := true
## Bozuk etki hata mı yazsın (geliştirme) yoksa uyarı mı (dışa aktarılmış oyun).
var dev := OS.is_debug_build()

## adım → [{id, system, call}]
var _members: Dictionary = {}
## kimlik → adım
var _ids: Dictionary = {}
## neden → {sahip: true}
var _pauses: Dictionary = {}
var _autosave_blocks: Dictionary = {}
var _last_autosave := -INF
## Oturumun süresi (sn; tick toplamı, duraklatmada akmaz) ve kare sayısı.
var _time := 0.0
var _frames := 0
## Bu karede geçilen saat başları (saat başı adımına).
var _hours: Array[Dictionary] = []
var _effect_queue: Array = []
var _services: Dictionary = {}
var _cond_names: Dictionary = {}
var _cond_prefixes: Dictionary = {}
var _cond_prefix_order: PackedStringArray = PackedStringArray()
var _ctx: _Ctx
var _cine: Object
var _prune := false
var _setup_done := false
var _failed := false


func _init() -> void:
	process_priority = PROCESS_PRIORITY
	process_mode = Node.PROCESS_MODE_PAUSABLE
	for step in STEPS:
		_members[step] = []
	_ctx = _Ctx.new(self)


## Oturumu yolculuğa kurar: kip (boşsa yolculuğunki), saatin varsayılanı, çekirdek bloklar; yolculuğun kayıtlı blokları (Journey.blocks:
## son yüklenen kayıt) okunur, oturumun blok kaydı yolculuğa bağlanır (Journey.live_blocks). Döner: hata ya da "" (hata varsa oturum
## yolculuğa bağlanmaz, varsayılanlarıyla kalır; çağıran bırakır: kısmi yükleme yok).
func setup(p_journey: Journey, p_mode: StringName = &"") -> String:
	journey = p_journey if p_journey != null else Journey.new(SaveSystem.new("user://", false))
	mode = p_mode if p_mode != &"" else StringName(journey.mode)
	if mode != MODE_ROAM and mode != MODE_STORY:
		mode = MODE_ROAM
	journey.mode = String(mode)
	if journey.map.is_empty():
		journey.map = SaveData.DEFAULT_MAP if mode == MODE_ROAM else ""
	set_clock(_default_clock())
	if not blocks.has_block("clock"):
		_register_core_blocks()
	_services = {
		"flags": journey, "clock": clock, "cond": _ctx, "bus": self, "session": self, "dev": dev,
		"inventory": inventory, "progress": progression,
	}
	_setup_done = true
	var err := blocks.apply(journey.blocks)
	if not err.is_empty():
		_failed = true
		return err
	journey.live_blocks = blocks
	if not journey.flag_set.is_connected(_on_flag_set):
		journey.flag_set.connect(_on_flag_set)
	_sync_carry()
	return ""


## Kurulum kaydı okuyamadı mı (setup hata döndü)?
func failed() -> bool:
	return _failed


func _ready() -> void:
	if not _setup_done:
		setup(journey)
	if get_tree().paused and not can_process():
		set_pause(&"pause", true, &"tree")


func _exit_tree() -> void:
	_detach()


## Oturum yolculuktan ayrılır: blokların son hâli yolculukta kalır (Serbest Gez'e yeniden girilirse saat sürer); kayıt yazılmaz. Kurulumu
## bozulan oturum yolculuğa bağlanmamıştır, bir şey yazmaz.
func _detach() -> void:
	if journey and journey.flag_set.is_connected(_on_flag_set):
		journey.flag_set.disconnect(_on_flag_set)
	if journey and journey.live_blocks == blocks:
		journey.blocks.merge(blocks.collect(), true)
		journey.live_blocks = null


func _process(delta: float) -> void:
	if auto_tick:
		tick(delta)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PAUSED:
			set_pause(&"pause", true, &"tree")
		NOTIFICATION_UNPAUSED:
			set_pause(&"pause", false, &"tree")
		NOTIFICATION_WM_CLOSE_REQUEST:
			request_autosave(&"pagehide")
		NOTIFICATION_PREDELETE:
			# Ağaca hiç girmeden silinen oturum (sınama) yolculuğu silinmiş nesnenin bloklarıyla bırakmasın.
			_detach()


# --- Sistemler ------------------------------------------------------------------------------------------------

## Adıma üye ekler. system: step(dt)'si (saat başı adımında on_hour(info)'su) olan nesne ya da Callable. id boşsa adımdan ve sırasından
## kurulur. Döner: eklendi mi (bilinmeyen adım, yöntemi olmayan nesne ya da aynı kimlik hatadır).
func add_system(step: StringName, system: Variant, id: StringName = &"") -> bool:
	if not STEPS.has(step):
		push_error("[session] bilinmeyen adım «%s» (adımlar: %s)" % [step, ", ".join(PackedStringArray(STEPS))])
		return false
	var method := &"on_hour" if HOURLY.has(step) else &"step"
	var call: Callable
	if system is Callable:
		call = system
	elif system is Object and is_instance_valid(system) and (system as Object).has_method(method):
		call = Callable(system, method)
	else:
		push_error("[session] %s adımının üyesinde %s yok" % [step, method])
		return false
	var sid := id if id != &"" else StringName("%s_%d" % [step, (_members[step] as Array).size() + 1])
	if _ids.has(sid):
		push_error("[session] «%s» kimliği zaten var (%s adımında)" % [sid, _ids[sid]])
		return false
	(_members[step] as Array).append({"id": sid, "system": system, "call": call})
	_ids[sid] = step
	return true


func remove_system(id: StringName) -> bool:
	if not _ids.has(id):
		return false
	var step: StringName = _ids[id]
	_ids.erase(id)
	var list: Array = _members[step]
	for k in list.size():
		if list[k]["id"] == id:
			list.remove_at(k)
			break
	return true


## Kimliğiyle üye (yoksa null).
func get_system(id: StringName) -> Variant:
	if not _ids.has(id):
		return null
	for m: Dictionary in _members[_ids[id]]:
		if m["id"] == id:
			return m["system"]
	return null


## Adımın üyelerinin kimlikleri, sırayla.
func members(step: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for m: Dictionary in _members.get(step, []):
		out.append(m["id"])
	return out


## Bir kare: adımlar sırayla. dt gerçek saniyedir (çağıranın dt ölçeğiyle); saat kendisi 0,25 sn'de kırpar.
func tick(dt: float) -> void:
	_time += maxf(dt, 0.0)
	_frames += 1
	for step: StringName in STEPS:
		if step == &"clock" and clock != null:
			clock.step(dt)
		var list: Array = _members[step]
		if not list.is_empty():
			if HOURLY.has(step):
				for info in _hours:
					for m: Dictionary in list:
						_invoke(m, info)
			else:
				for m: Dictionary in list:
					_invoke(m, dt)
		if step == &"quests":
			_flush_effects()
	_hours.clear()
	if _prune:
		_prune_dead()


## Oturumun süresi (sn; duraklatmada akmaz).
func elapsed() -> float:
	return _time


func frames() -> int:
	return _frames


# --- Saat ----------------------------------------------------------------------------------------------------

## Oturumun saatini değiştirir: sinyaller yeni saate bağlanır, açık durma nedenleri ona da yazılır. (Kayıttan okuma saati değiştirmez,
## aynı saate load_dict ile yazar.)
func set_clock(p_clock: GameClock) -> void:
	if clock == p_clock:
		return
	if clock != null:
		_wire_clock(clock, false)
	clock = p_clock
	if clock != null:
		_wire_clock(clock, true)
		for reason: StringName in _pauses:
			clock.pause(reason, true)
	if not _services.is_empty():
		_services["clock"] = clock
	clock_replaced.emit(clock)


## Saatin durma nedeni: sahibi (boşsa nedenin kendisi) tuttukça açıktır. Değişince pause_changed yayılır.
func set_pause(reason: StringName, on: bool, owner: StringName = &"") -> void:
	var key := owner if owner != &"" else reason
	var holders: Dictionary = _pauses.get(reason, {})
	var was := not holders.is_empty()
	if on:
		holders[key] = true
	else:
		holders.erase(key)
	if holders.is_empty():
		_pauses.erase(reason)
	else:
		_pauses[reason] = holders
	var now := not holders.is_empty()
	if was == now:
		return
	if clock != null:
		clock.pause(reason, now)
	pause_changed.emit(reason, now)


func is_paused_by(reason: StringName) -> bool:
	return _pauses.has(reason)


## Açık durma nedenleri (sıralı).
func pause_reasons() -> PackedStringArray:
	var out := PackedStringArray()
	for r: StringName in _pauses:
		out.append(String(r))
	out.sort()
	return out


## Nedeni tutan sahipler.
func pause_owners(reason: StringName) -> PackedStringArray:
	var out := PackedStringArray()
	for k: StringName in _pauses.get(reason, {}):
		out.append(String(k))
	return out


## Sinema konağını bağlar: sinema sürerken saat «cine» nedeniyle durur (CineHost.clock_hold_changed).
func bind_cine(host: Object) -> void:
	if _cine and is_instance_valid(_cine) and _cine.has_signal(&"clock_hold_changed"):
		var old: Signal = Signal(_cine, &"clock_hold_changed")
		if old.is_connected(_on_cine_hold):
			old.disconnect(_on_cine_hold)
	_cine = host
	if host == null or not host.has_signal(&"clock_hold_changed"):
		return
	(Signal(host, &"clock_hold_changed")).connect(_on_cine_hold)
	if host.has_method(&"is_playing") and bool(host.call(&"is_playing")):
		_on_cine_hold(true)


# --- Perde, dünya, tohum ---------------------------------------------------------------------------------------

## Perde geçişi: yolculuğa yazılır, ilerlemenin tavanları açılır (Progression.act_change; §15). Oto kaydı («act») çağıran ister.
func set_act(p_act: int) -> void:
	var a := maxi(p_act, 0)
	if journey.act == a:
		return
	journey.act = a
	if progression and a >= 1:
		progression.act_change(a)
	act_changed.emit(a)


## Dünya değişimi (WorldHost) yazar; kayıtta map olur. Saatin yeri o dünyanınkidir (evreler, şafak, akşam; place_for).
func set_map(map_id: String) -> void:
	journey.map = map_id
	var p := Session.place_for(map_id)
	if clock != null and not p.is_empty():
		clock.set_place(float(p["lat"]), float(p["dec_offset"]))


## Görev bitti (Quests gelince o çağırır): ilerleme usta koşullarını yeniden sınar, Ambar'dan geri alınan çuval heybeye döner
## (SEIZED_RETURN_QUEST), oto kayıt «quest_done» istenir.
func quest_done(quest_id: String) -> void:
	if progression:
		progression.on_quest_done(quest_id)
	if inventory and quest_id == SEIZED_RETURN_QUEST:
		inventory.restore_seized()
	request_autosave(&"quest_done")


## Kayıttan okunan yer: {id, pos (Vector3; yoksa Vector3.INF), yaw}; kayıtta map bloğu yoksa boş.
func saved_place() -> Dictionary:
	if map_block.is_empty():
		return {}
	var pos: Variant = map_block.get("pos")
	var at := Vector3.INF
	if pos is Array and (pos as Array).size() == 3:
		at = Vector3(float(pos[0]), float(pos[1]), float(pos[2]))
	return {"id": str(map_block.get("id", SaveData.DEFAULT_MAP)), "pos": at, "yaw": float(map_block.get("yaw", 0.0))}


## Blok kayıttan mı geldi, yoksa kayıtta olmadığı için varsayılanından mı kuruldu (map, clock, progression, inventory)? Yeni yolculuğa
## verilecek bir kez olan işler (deneme takımı, başlangıç bilgisi) buna bakar: kayıttan dönen heybeye ikinci kez eklenmez.
func fresh(block: String) -> bool:
	return bool(_fresh.get(block, false))


## Dünyanın envantere verilen kuralı (Inventory.set_world; saf): {id, kind, climate, perish}. Kış dünyasında balık donuktur: tarifin
## perish alanı (map.json «perish»: {"fish": false}) varsa o geçer.
static func world_rules(spec: Resource) -> Dictionary:
	if spec == null:
		return {}
	var out := {"id": str(spec.get(&"id")), "kind": str(spec.get(&"kind")), "climate": str(spec.get(&"climate"))}
	var perish: Variant = spec.get(&"perish") if &"perish" in spec else null
	if perish is Dictionary:
		out["perish"] = (perish as Dictionary).duplicate()
	return out


## Dünyanın yeri (saatin evreleri için): {lat, dec_offset}. Ana kamp K67'nin iğnesidir; öteki dünyaların enlemi kendi ışık dosyasından
## (data/maps/<id>/light.json lat); bulunamazsa boş (saatin yeri değişmez).
static func place_for(map_id: String) -> Dictionary:
	if map_id.is_empty():
		return {}
	if map_id == SaveData.DEFAULT_MAP:
		return {"lat": Daylight.CAMP_LAT, "dec_offset": Daylight.CAMP_DEC_OFFSET}
	if _places.has(map_id):
		return _places[map_id]
	var out := {}
	var spec := MapSpec.find(map_id)
	var path := spec.light if spec else ""
	if not path.is_empty() and FileAccess.file_exists(path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		var lat: Variant = (parsed as Dictionary).get("lat") if parsed is Dictionary else null
		if lat is float or lat is int:
			out = {"lat": float(lat), "dec_offset": 0.0}
	_places[map_id] = out
	return out


## Yolculuğun tohumundan bu akışın rastgele sayı üreteci (aynı yolculuk, aynı ad: aynı dizi; hava, olay zarları).
func rng_for(stream: String) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = SaveData.hash32("%d:%s" % [journey.journey_seed if journey else 0, stream])
	return rng


# --- Koşul ve etki ---------------------------------------------------------------------------------------------

## Oturumun koşul bağlamı (Cond.Ctx): önce kaydedilen kaynaklar (add_cond_source), sonra saatin ve yolculuğun adları (hour, minute, day_n,
## dark, phase:<evre>, slice:<dilim>, act, mode), en son yolculuğun işaretleri.
func cond_ctx() -> Cond.Ctx:
	return _ctx


func holds(expr: String) -> bool:
	return Cond.holds(expr, _ctx)


## Koşul kaynağı: ad ("trust") ya da önek ("quest:", "ties.", "item:"; «:» ya da «.» ile biter). source: (yol) -> Variant.
func add_cond_source(name_or_prefix: String, source: Callable) -> void:
	if name_or_prefix.ends_with(":") or name_or_prefix.ends_with("."):
		_cond_prefixes[name_or_prefix] = source
		var order := PackedStringArray(_cond_prefixes.keys())
		order.sort()
		order.reverse()
		_cond_prefix_order = order
	else:
		_cond_names[name_or_prefix] = source


## Etki hizmeti (Effects'in services sözlüğüne girer: inventory, progress, quests, dialogue, audio, ui, weather, structures ...).
func add_service(service_name: String, service: Object) -> void:
	_services[service_name] = service


func services() -> Dictionary:
	return _services


## Etkileri hemen uygular. Döner: hatalar.
func apply_effects(list: Variant, source: String = "") -> PackedStringArray:
	return Effects.apply(list, _services, source)


## Etkileri sıraya koyar: adım 11'de (Quests'ten sonra, yoldaşlardan önce) yazıldıkları sırayla uygulanır.
func queue_effects(list: Variant, source: String = "") -> void:
	_effect_queue.append([list, source])


## Etkilerin emit op'u.
func emit_event(event_name: StringName, payload: Variant = null) -> void:
	event.emit(event_name, payload)


# --- Oto kayıt ---------------------------------------------------------------------------------------------------

## Oto kayıt ister. info: minutes (wait, work), force. Döner: istek yayıldı mı (autosave_requested).
func request_autosave(reason: StringName, info: Dictionary = {}) -> bool:
	if not AUTOSAVE_REASONS.has(reason):
		push_error("[session] bilinmeyen oto kayıt nedeni «%s»" % reason)
		return false
	var forced := AUTOSAVE_FORCED.has(reason) or bool(info.get("force", false))
	if not forced:
		if autosave_blocked():
			return false
		if AUTOSAVE_TIMED.has(reason) and float(info.get("minutes", 0.0)) < AUTOSAVE_MIN_MINUTES - 1e-6:
			return false
		if AUTOSAVE_SPACED.has(reason) and _time - _last_autosave < AUTOSAVE_GAP_S:
			return false
	_last_autosave = _time
	autosave_requested.emit(reason)
	return true


## Oto kaydı bekletmeyen engel (boss fazı, sürüş ortası): sahibi tuttukça zorunlu olmayan nedenler düşer.
func block_autosave(owner: StringName, on: bool) -> void:
	if on:
		_autosave_blocks[owner] = true
	else:
		_autosave_blocks.erase(owner)


## Zorunlu olmayan oto kayıt şu an düşer mi (sinema ya da engel)?
func autosave_blocked() -> bool:
	return not _autosave_blocks.is_empty() or is_paused_by(&"cine")


# --- İç -----------------------------------------------------------------------------------------------------------

func _invoke(m: Dictionary, arg: Variant) -> void:
	var call: Callable = m["call"]
	if call.is_valid():
		call.call(arg)
	else:
		_prune = true


func _prune_dead() -> void:
	_prune = false
	for step: StringName in STEPS:
		var list: Array = _members[step]
		for k in range(list.size() - 1, -1, -1):
			if not (list[k]["call"] as Callable).is_valid():
				_ids.erase(list[k]["id"])
				list.remove_at(k)


func _flush_effects() -> void:
	if _effect_queue.is_empty():
		return
	var queue := _effect_queue
	_effect_queue = []
	for item: Array in queue:
		Effects.apply(item[0], _services, str(item[1]))


## Kipin açılış saati: Serbest Gez 11 Nisan MÖ 209 14:46,2; hikâye takvim günü (yoksa Gün I) 10:00; açılış saati olan haritada
## (MAP_START: deneme haritası) onunki. Yer dünyanınkidir (place_for): ana kamp, deneme haritası (44°K).
func _default_clock() -> GameClock:
	var c: GameClock
	if MAP_START.has(journey.map):
		var start: Array = MAP_START[journey.map]
		c = GameClock.new(int(start[0]), float(start[1]))
	elif mode == MODE_ROAM:
		c = GameClock.new(GameClock.ROAM_DAY, Daylight.MENU_MINUTE)
	else:
		var day: Variant = journey.flags.get(NewGameFlow.DAY_FLAG)
		c = GameClock.new(int(day) if (day is int or day is float) else STORY_DAY, STORY_MINUTE)
	var p := Session.place_for(journey.map)
	if not p.is_empty():
		c.set_place(float(p["lat"]), float(p["dec_offset"]))
	return c


func _register_core_blocks() -> void:
	if inventory == null:
		inventory = Inventory.new()
	if progression == null:
		progression = Progression.new()
		progression.context = _progression_path
		progression.changed.connect(_sync_carry)
	var v := int(clock.to_dict().get("v", 1)) if clock else 1
	blocks.register("map", MAP_BLOCK_V, _write_map, _read_map, {"reset": _reset_map, "check": Session.check_map_block, "order": 5})
	blocks.register("clock", v, _write_clock, _read_clock, {"reset": _reset_clock, "check": SaveBlocks.check_clock, "order": 10})
	blocks.register("progression", Progression.BLOCK_VERSION, progression.to_dict, _read_progression,
		{"reset": _reset_progression, "order": 20})
	blocks.register("inventory", Inventory.SAVE_V, inventory.to_dict, _read_inventory, {"reset": _reset_inventory, "order": 60})
	add_cond_source("level", progression.get_value)
	add_cond_source("stat.", progression.get_value)
	add_cond_source("skill:", progression.get_value)
	add_cond_source("item:", func(path: String) -> Variant: return inventory.count(path.substr(5)))


# --- Bloklar (map, progression, inventory) ----------------------------------------------------------------------

func _write_map() -> Dictionary:
	var d: Dictionary = map_source.call() if map_source.is_valid() else {}
	if d.is_empty():
		d = map_block.duplicate(true)
	if str(d.get("id", "")).is_empty():
		d["id"] = journey.map if journey and not journey.map.is_empty() else SaveData.DEFAULT_MAP
	return d


func _read_map(d: Dictionary) -> bool:
	_fresh["map"] = false
	map_block = {"id": str(d.get("id", SaveData.DEFAULT_MAP))}
	if d.get("pos") is Array:
		map_block["pos"] = (d["pos"] as Array).duplicate()
	if d.get("yaw") is float or d.get("yaw") is int:
		map_block["yaw"] = float(d["yaw"])
	journey.map = str(map_block["id"])
	var p := Session.place_for(journey.map)
	if not p.is_empty():
		clock.set_place(float(p["lat"]), float(p["dec_offset"]))
	return true


func _reset_map() -> void:
	_fresh["map"] = true
	map_block = {}


## map bloğunun denetimi (saf): kimlik boş olmayan yazı; yer varsa üç sonlu sayı, yön varsa sonlu sayı. Döner: hata ya da "".
static func check_map_block(d: Dictionary) -> String:
	var id: Variant = d.get("id")
	if not id is String or (id as String).is_empty():
		return "dünyanın kimliği (id) yok"
	var pos: Variant = d.get("pos")
	if pos != null:
		if not pos is Array or (pos as Array).size() != 3:
			return "yer (pos) üç sayı değil"
		for x: Variant in pos:
			if not (x is float or x is int) or not is_finite(float(x)):
				return "yer (pos) bozuk"
	var yaw: Variant = d.get("yaw")
	if yaw != null and (not (yaw is float or yaw is int) or not is_finite(float(yaw))):
		return "yön (yaw) bozuk"
	return ""


func _read_progression(d: Dictionary) -> bool:
	_fresh["progression"] = false
	progression.from_dict(d, maxi(journey.act, 1))
	return true


## Kayıtta ilerleme yoksa (yeni yolculuk, eski kayıt): profilin kökeniyle baştan (Progression.reset_player); perde yolculuğunkidir.
func _reset_progression() -> void:
	_fresh["progression"] = true
	progression.reset_player(journey.profile.origin_id() if journey and journey.profile else "")
	if journey and journey.act > 1:
		progression.act_change(journey.act)


func _read_inventory(d: Dictionary) -> bool:
	_fresh["inventory"] = false
	return inventory.from_dict(d)


## Kayıtta envanter yoksa: yetişkin beden ve I. Perde'nin başlangıç donanımı (Kışlak Kaftanı ve Pelerini, Çentik Çubuğu). Kayıtsız
## sahneler (Çocukluk, Serbest Gez'in Çocuğu, Yola Çıkış) bedeni GameplayHud.begin_body ile kendileri kurar.
func _reset_inventory() -> void:
	_fresh["inventory"] = true
	inventory.reset_body(Inventory.BODY_ADULT)
	inventory.apply_kit(START_KIT)
	inventory.set_day(clock.day_n if clock else 0)


## İlerlemenin bilmediği yollar (bayrak, görev, eksen, eşya) oturumun koşul bağlamından.
func _progression_path(path: String) -> Variant:
	return _ctx.get_value(path)


## İlerlemenin Bilek'i ve Sırt Yükü becerisi envanterin sınırıdır (economy.md §4.1: 12 + 3 × Bilek + Sırt Yükü).
func _sync_carry() -> void:
	if inventory == null or progression == null:
		return
	var grip: float = float(progression.stats.get("grip", inventory.grip))
	var pack_skill: bool = progression.learned.has("carry_pack")
	if is_equal_approx(grip, inventory.grip) and pack_skill == inventory.carry_pack:
		return
	inventory.grip = grip
	inventory.carry_pack = pack_skill
	inventory.changed.emit()


## Yolculuğa ilk kez konan bayrak (Journey.flag_set): ilerleme ve envanter dinler (sentenced: ustası tutmayan beceri yiter, el koyma).
func _on_flag_set(key: String) -> void:
	var value: Variant = journey.flags.get(key)
	if progression:
		progression.on_flag_set(key, value)
	if inventory:
		inventory.on_flag(key, Cond.truthy(value), false)


## Hikâye kipinde takvim günü saatin gününe ilerler (K67: yalnız ileri). day: olayın günü (verilmezse saatinki).
func _advance_calendar(day: int = GameClock.NO_DAY) -> void:
	if mode != MODE_STORY or clock == null or journey == null:
		return
	var now: Variant = journey.flags.get(NewGameFlow.DAY_FLAG)
	var next := NewGameFlow.advance(now, clock.day_n if day == GameClock.NO_DAY else day)
	if now == null or int(now) != next:
		journey.set_flag(NewGameFlow.DAY_FLAG, next)


func _write_clock() -> Dictionary:
	return clock.to_dict()


func _read_clock(d: Dictionary) -> bool:
	_fresh["clock"] = false
	if clock.has_method(&"load_dict"):
		return bool(clock.call(&"load_dict", d))
	set_clock(GameClock.from_dict(d))
	return true


## Kayıtta saat bloğu yoksa (yeni yolculuk, v1 kaydı): kipin varsayılanı (Serbest Gez 11 Nisan MÖ 209 14:46,2). Saatin yeri kalır.
func _reset_clock() -> void:
	_fresh["clock"] = true
	var d := _default_clock().to_dict()
	if clock.has_method(&"load_dict"):
		clock.call(&"load_dict", d)
	else:
		set_clock(GameClock.from_dict(d))


## Saatin sinyallerini oturuma bağlar ya da çözer (saatte olmayan sinyal atlanır: GameClock genişledikçe kendiliğinden bağlanır).
func _wire_clock(c: GameClock, on: bool) -> void:
	var pairs: Array = [
		[&"hour_passed", _on_hour], [&"skipped", _on_skipped], [&"day_changed", _on_day_changed], [&"dawn", _on_dawn],
		[&"dusk", _on_dusk], [&"phase_changed", _on_phase_changed], [&"hold_changed", _on_hold_changed], [&"summoned", _on_summoned],
	]
	for pair: Array in pairs:
		if not c.has_signal(pair[0]):
			continue
		var sig := Signal(c, pair[0])
		if on and not sig.is_connected(pair[1]):
			sig.connect(pair[1])
		elif not on and sig.is_connected(pair[1]):
			sig.disconnect(pair[1])


func _on_hour(info: Dictionary) -> void:
	_hours.append(info)
	hour_passed.emit(info)


## Atlama bitti: uzun atlamada (sınır olayı yok) envanter şafak sayısı kadar bozulur, takvim günü ilerler; sonra skipped yayılır ve
## atlamanın nedeni oto kayıt ister (uyku, ≥1 sa bekleme ve çalışma, dinlenme).
func _on_skipped(info: Dictionary) -> void:
	if bool(info.get("long", false)):
		if inventory:
			inventory.on_long_skip(int(info.get("dawns", 0)))
		_advance_calendar()
	skipped.emit(info)
	var reason := StringName(str(info.get("reason", "")))
	if bool(info.get("sleep", false)):
		reason = &"sleep"
	if SKIP_AUTOSAVE.has(reason):
		request_autosave(SKIP_AUTOSAVE[reason], {"minutes": float(info.get("minutes", 0.0))})


## Tan (atlamanın içinde de): envanterin şafağı (çiğ et ve balık ikinci şafakta bozulur); hikâye kipinde atlamasız Tan oto kayıttır.
func _on_dawn(info: Dictionary) -> void:
	if inventory:
		inventory.on_dawn(int(info.get("day_n", clock.day_n if clock else 0)))
	dawn.emit(info)
	if mode == MODE_STORY and not bool(info.get("skipping", false)):
		request_autosave(&"dawn")


func _on_day_changed(info: Dictionary) -> void:
	_advance_calendar(int(info.get("day_n", clock.day_n if clock else 0)))
	day_changed.emit(info)


func _on_dusk(info: Dictionary) -> void:
	dusk.emit(info)


func _on_phase_changed(info: Dictionary) -> void:
	phase_changed.emit(info)


func _on_hold_changed(info: Dictionary) -> void:
	hold_changed.emit(info)


func _on_summoned(info: Dictionary) -> void:
	summoned.emit(info)


func _on_cine_hold(on: bool) -> void:
	set_pause(&"cine", on, &"cine_host")


## Oturumun koşul bağlamı.
class _Ctx:
	extends Cond.Ctx

	var session: Session

	func _init(p_session: Session) -> void:
		session = p_session

	func get_value(path: String) -> Variant:
		if session == null or not is_instance_valid(session):
			return null
		var named: Variant = session._cond_names.get(path)
		if named is Callable:
			return (named as Callable).call(path)
		for prefix in session._cond_prefix_order:
			if path.begins_with(prefix):
				return (session._cond_prefixes[prefix] as Callable).call(path)
		var c := session.clock
		match path:
			"hour":
				return c.hour() if c else null
			"minute":
				return c.minute if c else null
			"day_n":
				return c.day_n if c else null
			"dark":
				return bool(c.call(&"dark")) if c and c.has_method(&"dark") else null
			"act":
				return session.journey.act if session.journey else 0
			"mode":
				return String(session.mode)
		if path.begins_with("phase:"):
			return c != null and c.has_method(&"phase") and String(c.call(&"phase")) == path.substr(6)
		if path.begins_with("slice:"):
			return c != null and c.has_method(&"slice") and String(c.call(&"slice")) == path.substr(6)
		return session.journey.flags.get(path) if session.journey else null
