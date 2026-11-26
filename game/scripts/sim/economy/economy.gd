class_name Economy
extends RefCounted
## Ekonominin dünya tarafı ve kayıt v2'nin «economy» bloğu (saf; economy.md §12, godot.md §3.4; SaveBlocks.OWNERS «economy»): haritaların
## düğüm kayıtları (NodeStore; harita kimliğiyle), tezgâhlar (Workshop; kimlikle) ve tezgâhların sandıkları (ItemContainer), ilk kez
## yapılan tarifler (Progression «recipe» bir kez sayar; burada Defter'in bilgisidir), sayaçlar. Kişisel kaplar Inventory'nin «inventory»
## bloğundadır; yerleşim ve ordugâh ambarları, Kâhya'nın tezgâhları yerleşimin bloklarıdır (settlement.md §16) ve gelince oraya geçer.
##
## Harita bellekte değilken (kamp, başka iç harita) düğüm durumu bloğun içinde taşınır, harita kurulunca okunur (attach_store); şafakta
## taşınan durumun günlük kısmı düşer (kalıcı bitler ve kısmi stok kalır). Tezgâhın saati oyunun saatidir: step(dt) oturumun saatinden
## geçen oyun dakikasını tezgâhlara verir (Session'ın «sites» adımı; saat yoksa sürücü tick_workshops'ı kendisi çağırır).
##   var eco := Economy.new()
##   eco.register(session.blocks)                         # «economy» bloğu (sıra 41, ≤6 KB)
##   eco.attach_store("testmap", store)                   # kayıttaki durumu okur
##   eco.attach_workshop(ws, chest)                       # tezgâh ve sandığı (havuz)
##   eco.tick_workshops(minutes, {"lit": "day", "weather": fx})

signal workshop_done(workshop_id: String, done: Array)
signal changed

const BLOCK := "economy"
const BLOCK_V := 1
const BLOCK_ORDER := 41
const MAX_BYTES := 6144

## Harita kimliği → NodeStore; tezgâh kimliği → Workshop; tezgâh kimliği → sandık (ItemContainer).
var stores: Dictionary = {}
var workshops: Dictionary = {}
var chests: Dictionary = {}
## Tarif → kaç kez yapıldı (ilk kez XP'si ve Defter).
var crafted: Dictionary = {}
var stats := {"strikes": 0, "clean": 0, "felled": 0, "gathered": 0, "made": 0}
## Oturumun saati (verilirse step ondan sürer) ve son okunan mutlak dakika.
var clock: GameClock
## Tezgâhların ortamı: () -> {lit, dark, weather, window} (sürücü verir).
var env: Callable

## Tan'daki yenilenmenin tür katsayısı: (kind_id) -> k (NodeStore.on_dawn; hava verince: mantar yağmurdan sonra ×2, kuruda ×0,5).
## Boşken her tür ×1.
var renew_k: Callable
## Tan'da yenilenmeyi durduran yolculuk bayrağı (prototipin Son Gece'si: kampı bırakış gecesinden sonra düğümler dönmez, economy.md §3.2).
var stop_flag := "a1_last_night"

var _carry_nodes: Dictionary = {}
var _carry_ws: Dictionary = {}
var _carry_chests: Dictionary = {}
var _last_abs := NAN
var _session_ref: WeakRef


# --- Bağlama -------------------------------------------------------------------------------------------------------------

## Haritanın düğüm kaydı kuruldu: kayıtta taşınan durumu okur (nodesV uymazsa yalnız kalıcı bitler).
func attach_store(map_id: String, store: NodeStore) -> void:
	stores[map_id] = store
	if _carry_nodes.has(map_id):
		var d: Dictionary = _carry_nodes[map_id]
		store.from_dict(d, int(d.get("nodesV", NodeStore.data().get("nodesV", 1))) == int(NodeStore.data().get("nodesV", 1)))
		_carry_nodes.erase(map_id)


## Harita bırakılıyor: durumu bloğun içinde taşınır.
func detach_store(map_id: String) -> void:
	var store: NodeStore = stores.get(map_id)
	if store:
		var d := store.to_dict()
		d["nodesV"] = int(NodeStore.data().get("nodesV", 1))
		_carry_nodes[map_id] = d
	stores.erase(map_id)


## Tezgâh ve sandığı (havuzu): kayıttaki kuyruğu ve sandığın içeriğini okur.
func attach_workshop(ws: Workshop, chest: ItemContainer = null) -> void:
	workshops[ws.id] = ws
	if _carry_ws.has(ws.id):
		ws.from_dict(_carry_ws[ws.id])
		_carry_ws.erase(ws.id)
	if chest:
		chests[ws.id] = chest
		if _carry_chests.has(ws.id):
			chest.from_dict(_carry_chests[ws.id])
			_carry_chests.erase(ws.id)


func detach_workshop(ws_id: String) -> void:
	var ws: Workshop = workshops.get(ws_id)
	if ws:
		_carry_ws[ws_id] = ws.to_dict()
	var chest: ItemContainer = chests.get(ws_id)
	if chest:
		_carry_chests[ws_id] = chest.to_dict()
	workshops.erase(ws_id)
	chests.erase(ws_id)


## Şafak (oturumun dawn olayı): bütün kayıtlar yenilenir; bellekte olmayan haritanın günlük durumu düşer.
func on_dawn(day: int, renew_k := Callable()) -> void:
	for map_id: String in stores:
		(stores[map_id] as NodeStore).on_dawn(day, renew_k)
	for map_id: String in _carry_nodes:
		(_carry_nodes[map_id] as Dictionary)["day"] = []
	changed.emit()


## Oturumun Tan'ına bağlanır (bir kez; Session.dawn → on_dawn(day_n, renew_k)). Yolculukta stop_flag varsa Tan bir şey yenilemez.
func bind_session(s: Object) -> void:
	if s == null or not s.has_signal(&"dawn"):
		return
	_session_ref = weakref(s)
	if not s.is_connected(&"dawn", _on_session_dawn):
		s.connect(&"dawn", _on_session_dawn)


func _on_session_dawn(info: Dictionary) -> void:
	var s: Object = _session_ref.get_ref() if _session_ref else null
	var journey: Variant = s.get(&"journey") if s else null
	if journey is Journey and not stop_flag.is_empty() and (journey as Journey).has_flag(stop_flag):
		return
	on_dawn(int(info.get("day_n", 0)), renew_k)


## Tarif yapıldı: → ilk kez mi (Progression «recipe» XP'sini çağıran verir).
func note_crafted(recipe_id: String, n := 1) -> bool:
	var first := not crafted.has(recipe_id)
	crafted[recipe_id] = int(crafted.get(recipe_id, 0)) + n
	stats["made"] = int(stats.get("made", 0)) + n
	changed.emit()
	return first


func count_stat(key: String, n := 1) -> void:
	stats[key] = int(stats.get(key, 0)) + n


# --- Saat ----------------------------------------------------------------------------------------------------------------

## Oturumun adımı (Session «sites»): saatten geçen oyun dakikası tezgâhlara. Saat yoksa bir şey yapmaz.
func step(_dt: float) -> void:
	if clock == null:
		return
	var now := clock.abs_minute()
	if is_nan(_last_abs) or now < _last_abs:
		_last_abs = now
		return
	var minutes := now - _last_abs
	_last_abs = now
	if minutes > 0.0:
		tick_workshops(minutes, env.call() if env.is_valid() else {})


## Tezgâhlara game_min oyun dakikası: her tezgâh kendi sandığından alır, sandığına koyar. Biten iş workshop_done ile yayılır.
func tick_workshops(game_min: float, opts := {}) -> void:
	for ws_id: String in workshops:
		var ws: Workshop = workshops[ws_id]
		if ws.queue.is_empty() and ws.cures.is_empty() and ws.outbox.is_empty():
			continue
		var o := opts.duplicate()
		o["pool"] = chests.get(ws_id)
		var res := ws.tick(game_min, o)
		if not (res["done"] as Array).is_empty():
			for e: Dictionary in res["done"]:
				note_crafted(str(e["recipe"]), 0)
			workshop_done.emit(ws_id, res["done"])


## Saatin okunan yerini sıfırlar (yeni saat, dünya değişimi).
func reset_clock_mark() -> void:
	_last_abs = NAN


# --- Kayıt ---------------------------------------------------------------------------------------------------------------

func register(blocks: SaveBlocks) -> bool:
	if blocks == null:
		return false
	return blocks.register(BLOCK, BLOCK_V, to_dict, from_dict, {"reset": reset, "check": Economy.validate_save_block, "order": BLOCK_ORDER,
		"max_bytes": MAX_BYTES})


## {v, nodesV, nodes: {harita: NodeStore.to_dict}, workshops: {kimlik: Workshop.to_dict}, chests: {kimlik: kap}, crafted, stats}.
func to_dict() -> Dictionary:
	var nodes := _carry_nodes.duplicate(true)
	for map_id: String in stores:
		var d := (stores[map_id] as NodeStore).to_dict()
		d["nodesV"] = int(NodeStore.data().get("nodesV", 1))
		nodes[map_id] = d
	var ws := _carry_ws.duplicate(true)
	for ws_id: String in workshops:
		ws[ws_id] = (workshops[ws_id] as Workshop).to_dict()
	var ch := _carry_chests.duplicate(true)
	for ws_id: String in chests:
		ch[ws_id] = (chests[ws_id] as ItemContainer).to_dict()
	return {"v": BLOCK_V, "nodesV": int(NodeStore.data().get("nodesV", 1)), "nodes": nodes, "workshops": ws, "chests": ch,
		"crafted": crafted.duplicate(), "stats": stats.duplicate()}


## Kayıttan: bellekteki kayıtlar hemen okunur, ötekiler bağlanınca. Döner: okundu mu.
func from_dict(d: Dictionary) -> bool:
	reset()
	var nodes: Dictionary = d.get("nodes", {}) if d.get("nodes") is Dictionary else {}
	for map_id: String in nodes:
		if nodes[map_id] is Dictionary:
			_carry_nodes[map_id] = (nodes[map_id] as Dictionary).duplicate(true)
	var ws: Dictionary = d.get("workshops", {}) if d.get("workshops") is Dictionary else {}
	for ws_id: String in ws:
		if ws[ws_id] is Dictionary:
			_carry_ws[ws_id] = (ws[ws_id] as Dictionary).duplicate(true)
	var ch: Dictionary = d.get("chests", {}) if d.get("chests") is Dictionary else {}
	for ws_id: String in ch:
		if ch[ws_id] is Dictionary:
			_carry_chests[ws_id] = (ch[ws_id] as Dictionary).duplicate(true)
	var made: Dictionary = d.get("crafted", {}) if d.get("crafted") is Dictionary else {}
	for rid: String in made:
		if Craft._num(made[rid]):
			crafted[rid] = int(made[rid])
	var st: Dictionary = d.get("stats", {}) if d.get("stats") is Dictionary else {}
	for k: String in st:
		if Craft._num(st[k]):
			stats[k] = int(st[k])
	for map_id: String in stores.keys():
		attach_store(map_id, stores[map_id])
	for ws_id: String in workshops.keys():
		attach_workshop(workshops[ws_id], chests.get(ws_id))
	changed.emit()
	return true


## Yeni yolculuk: bellekteki kayıtlar tazelenir, sandıklar boşalır, taşınanlar silinir.
func reset() -> void:
	_carry_nodes.clear()
	_carry_ws.clear()
	_carry_chests.clear()
	crafted.clear()
	stats = {"strikes": 0, "clean": 0, "felled": 0, "gathered": 0, "made": 0}
	for map_id: String in stores:
		(stores[map_id] as NodeStore).reset()
	for ws_id: String in workshops:
		(workshops[ws_id] as Workshop).from_dict({})
	for ws_id: String in chests:
		(chests[ws_id] as ItemContainer).clear()


## Durağan denetim (SaveBlocks.check_blocks: menü kayıtları listelerken sistemler kurulu değildir). "" geçer.
static func validate_save_block(d: Dictionary) -> String:
	for key: String in ["nodes", "workshops", "chests", "crafted", "stats"]:
		if d.has(key) and not d[key] is Dictionary:
			return "economy.%s sözlük değil" % key
	var nodes: Dictionary = d.get("nodes", {})
	for map_id: String in nodes:
		var n: Variant = nodes[map_id]
		if not n is Dictionary:
			return "economy.nodes.%s sözlük değil" % map_id
		if (n as Dictionary).has("perm") and not (n as Dictionary)["perm"] is String:
			return "economy.nodes.%s.perm yazı değil" % map_id
	return ""
