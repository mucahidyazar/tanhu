class_name Travel
extends RefCounted
## Menzil ağının durumu ve kuralları (saf; travel.md §4.2–§4.3, §7–§8, §11; act1.md §4 «Yol Kemikleri», «Menzil», §9.4; Yol Haritası
## roads-relays). Kayıt v2'nin «travel» bloğunun sahibidir (SaveBlocks.OWNERS): durakların durumu (hidden → rumoured → found → linked;
## hidden yazılmaz), onarılmış Yol Kemikleri, arabanın son durağı, ücret sayacı, yol sohbeti ve süren seferin kaydı (ride: yalnız
## kalkışta yazılan kayıtta; yükleme kalkış durağına koyar, ücret alınmamıştır). Ağaca dokunmaz; TravelLayer dünyadaki yüzüdür.
##
## Bulma ve açılma (§4.3): durak bölgesi açıkken (regions hizmeti ya da «rank» bayrağı ≥ durağın rütbesi) oyuncu yolcu değilken (yaya ya da at
## sırtında) durağın 15 m'sine girerse found olur; found ve varsa bağlı Yol Kemiği onarılmışsa linked olur (+10 XP, «waystation», bir kez).
## Yol Kemiği onarımı (act1.md §4): 1 kemik + 1 ip ya da 4 taş, 20 sn tırmanış; onarılan direk Menzil bağlar ve Tipide kayıt noktasıdır.
## Kilitler (§8) sıralıdır, ilk eşleşen döner (allowed); bağlam sözlüğü çağıranındır (bayraklar, saat, hava, yük, ücret).
##   var travel := Travel.new()
##   travel.define(layer_def)                                 # durakların ve direklerin tanımı (haritanın katmanı)
##   travel.on_near("way_fold", 12.0, {"region_open": true})   # found oldu mu
##   travel.repair_bone("RB04")                               # {ok, linked: [..]}
##   travel.allowed({"flags": journey_flags, "minute": 600.0, ...})   # {ok, code, text}
##   travel.register_block(session.blocks)

signal station_changed(id: String, state: String)
signal bone_repaired(id: String)
## Durak bağlandı (XP ve ses dinleyicinin işidir).
signal linked(id: String)

const BLOCK := "travel"
const SAVE_V := 1
const RULES_PATH := "res://data/travel/rules.json"
## Durumlar, sırasıyla (progression.md §10.1 ile aynı adlar).
const STATES: Array[String] = ["hidden", "rumoured", "found", "linked"]
const MAX_BYTES := 4096

static var _rules: Dictionary = {}

## Durak kimliği → durum (hidden yazılmaz).
var stations: Dictionary = {}
## Onarılmış Yol Kemikleri (kimlik → onarıldığı mutlak oyun dakikası; sıra = onarım sırası).
var bones: Dictionary = {}
## Arabanın son durduğu durak ve oyuncunun son indiği durak (menü kartı «place»).
var cart_at := ""
var last_stop := ""
## Atlas yolları (II. Perde; ek): kimlik → durum. Açılan bağlar (bone_throat>atlas_tanhu_camp).
var routes: Dictionary = {}
var open_edges: Array = []
## Ücret ve sohbet: sefer sayısı (ağda ilk sefer parasız), duyulan yol sohbeti satırları, yolcu görevleri.
var trips := 0
var gossip: Array = []
var fares: Dictionary = {}
var narrated: Array = []
## Süren seferin kaydı ({from, to, mode}) ya da null: kalkışta (DEPART) yazılır, inişte silinir.
var ride: Variant = null
## Kantu arabada iş başında mı (araba çağrıldı, bekliyor, seferde ya da dönüyor; TravelLayer her kare yazar, kayda girmez). Kişi programı
## bu sürede Kantu'nun yerini iptal eder (travel.md §5.3 madde 6): kişileri kuran katman Kantu'yu gizler (oturumun «travel» hizmeti).
var on_duty := false
## Arabanın sürücüsünün kişi kimliği (katmanın «cart.driver»ı; define yazar, kayda girmez): kişi katmanı on_duty'de onu gizler.
var driver := ""
## Durakların ve direklerin tanımı (define): kimlik → satır. Kayda girmez.
var defs: Dictionary = {}
var bone_defs: Dictionary = {}


## Kuralların dosyası (önbellekli; sınama reset_cache ile bırakır).
static func rules() -> Dictionary:
	if _rules.is_empty() and FileAccess.file_exists(RULES_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(RULES_PATH))
		_rules = parsed if parsed is Dictionary else {}
	return _rules


static func reset_cache() -> void:
	_rules = {}


## Kuralın değeri: «cart.skip.hold_s» gibi noktalı yol (yoksa fallback).
static func rule(path: String, fallback: Variant = null) -> Variant:
	var at: Variant = Travel.rules()
	for part in path.split("."):
		if not at is Dictionary or not (at as Dictionary).has(part):
			return fallback
		at = (at as Dictionary)[part]
	return at


## Oyuncu dizgesi (rules.json text; {ad}/{name} gibi yer tutucular args'tan).
static func text(key: String, lang := "tr", args: Dictionary = {}) -> String:
	var row: Variant = (Travel.rules().get("text", {}) as Dictionary).get(key)
	var s := key
	if row is Dictionary:
		s = str((row as Dictionary).get(lang, (row as Dictionary).get("tr", key)))
	for k: String in args:
		s = s.replace("{%s}" % k, str(args[k]))
	return s


## Durakların ve direklerin tanımı (haritanın katmanı: stations, bones). Durumlar korunur (başka haritanın durakları da).
func define(def: Dictionary) -> void:
	for s: Variant in def.get("stations", []):
		if s is Dictionary and (s as Dictionary).has("id"):
			defs[str(s["id"])] = (s as Dictionary).duplicate(true)
	for b: Variant in def.get("bones", []):
		if b is Dictionary and (b as Dictionary).has("id"):
			bone_defs[str(b["id"])] = (b as Dictionary).duplicate(true)
	var cart: Variant = def.get("cart")
	if cart is Dictionary and not (cart as Dictionary).is_empty():
		driver = str((cart as Dictionary).get("driver", "kantu"))


# --- Duraklar ----------------------------------------------------------------------------------------------------------

## Durağın durumu (tanımsız ya da yazılmamışsa hidden).
func state_of(id: String) -> String:
	return str(stations.get(id, "hidden"))


static func rank_of(state: String) -> int:
	return maxi(STATES.find(state), 0)


func is_linked(id: String) -> bool:
	return state_of(id) == "linked"


## Durağın durumunu yazar (Effects «station» op'u; hizmet adı travel). Yalnız ileri gider (force geriye de yazar); linked'e doğrudan
## geçiş bağlı direği beklemez (hikâye açar). Döner: değişti mi.
func set_station(id: String, state: String, force := false) -> bool:
	if not STATES.has(state):
		push_warning("[travel] bilinmeyen durak durumu: %s → %s" % [id, state])
		return false
	var before := state_of(id)
	if before == state or (not force and Travel.rank_of(state) < Travel.rank_of(before)):
		return false
	if state == "hidden":
		stations.erase(id)
	else:
		stations[id] = state
	station_changed.emit(id, state)
	if state == "linked":
		linked.emit(id)
	return true


## Atlas yolu (Effects «route» op'u; II. Perde'nin atlası okur).
func set_route(id: String, state: String) -> bool:
	if str(routes.get(id, "hidden")) == state:
		return false
	if state == "hidden":
		routes.erase(id)
	else:
		routes[id] = state
	return true


## Duyuldu (bölge açıldı, Bakış, Kantu adını anar): hidden ise rumoured.
func rumour(id: String) -> bool:
	return state_of(id) == "hidden" and set_station(id, "rumoured")


## Oyuncu durağın yakınında (yaya ya da at sırtında; yolcuyken çağrılmaz): ctx.region_open ise d ≤ find_m'de found olur, bağlı direk
## onarılmışsa hemen linked. Döner: durum değişti mi.
func on_near(id: String, d: float, ctx: Dictionary = {}) -> bool:
	if not defs.has(id) or d > float(Travel.rule("station.find_m", 15.0)):
		return false
	# Bölge kapalıyken bulunmaz (§4.3 «Bölge açık + ... ≤15 m»); duyulması bölgenin açılışınındır (rumour).
	if not bool(ctx.get("region_open", true)):
		return false
	var changed := false
	if Travel.rank_of(state_of(id)) < Travel.rank_of("found"):
		changed = set_station(id, "found")
	if state_of(id) == "found" and bone_ready(id):
		changed = set_station(id, "linked") or changed
	return changed


## Durağın bağlı direği yok ya da onarılmış mı?
func bone_ready(id: String) -> bool:
	var bone := str((defs.get(id, {}) as Dictionary).get("bone", ""))
	return bone.is_empty() or bones.has(bone)


## found olup direği onarılan durakları bağlar. Döner: bağlananlar.
func refresh_links() -> Array:
	var out: Array = []
	for id: String in defs:
		if state_of(id) == "found" and bone_ready(id) and set_station(id, "linked"):
			out.append(id)
	return out


## Bağlı duraklar (tanımlı olanlar, tanım sırasıyla).
func linked_ids() -> Array:
	var out: Array = []
	for id: String in defs:
		if is_linked(id):
			out.append(id)
	return out


## Bölge açık mı (saf): regions hizmeti (is_open) varsa o, yoksa «rank» bayrağı ≥ durağın rütbesi ya da «region.<id>» bayrağı.
static func region_open(station: Dictionary, flags: Variant, regions: Object = null) -> bool:
	var region := str(station.get("region", ""))
	if regions and regions.has_method(&"is_open"):
		return bool(regions.call(&"is_open", region))
	var need := int(station.get("rank", 0))
	if need <= 0:
		return true
	var rank: Variant = Travel._flag(flags, "rank")
	if (rank is float or rank is int) and int(rank) >= need:
		return true
	# Geliştirme bayrağı «rank_N» (--flags yalnız doğru yazar): N ≥ rütbe.
	for r in range(need, 7):
		if Travel._flag(flags, "rank_%d" % r) == true:
			return true
	return Travel._flag(flags, "region.%s" % region) == true


## Bayrağın değeri doğru mu (saf): null, false, 0 ve boş metin yanlıştır.
static func truthy(v: Variant) -> bool:
	if v == null:
		return false
	if v is bool:
		return v
	if v is int or v is float:
		return float(v) != 0.0
	if v is String or v is StringName:
		return not str(v).is_empty()
	return true


static func _flag(flags: Variant, key: String) -> Variant:
	if flags is Callable and (flags as Callable).is_valid():
		return (flags as Callable).call(key)
	if flags is Dictionary:
		return (flags as Dictionary).get(key)
	if flags is Object and (flags as Object).has_method(&"get_flag"):
		return (flags as Object).call(&"get_flag", key)
	return null


# --- Yol Kemikleri -----------------------------------------------------------------------------------------------------

func is_repaired(id: String) -> bool:
	return bones.has(id)


## Onarımın bedeli (saf olmayan: envanteri okur): costs'tan ilk karşılanabilen ({id: n}); hiçbiri yoksa boş.
static func bone_cost(inv: Object) -> Dictionary:
	for c: Variant in Travel.rule("bone.costs", []):
		if not c is Dictionary:
			continue
		var ok := true
		for item: String in c:
			if inv == null or not bool(inv.call(&"has", item, int(c[item]))):
				ok = false
				break
		if ok:
			var out := {}
			for item: String in c:
				out[item] = int(c[item])
			return out
	return {}


## Direği onarır (bedel çağıranın işidir: bone_cost ile alınır). at: oyun dakikası (sıra). Döner: {ok, linked: [bağlanan duraklar]}.
func repair_bone(id: String, at := 0.0) -> Dictionary:
	if id.is_empty() or bones.has(id):
		return {"ok": false, "linked": []}
	bones[id] = at
	bone_repaired.emit(id)
	return {"ok": true, "linked": refresh_links()}


## Onarılmış direklerin kimlikleri (onarım sırasıyla; Tipide kayıt noktası: kovalamaca son onarılanı okur).
func repaired_bones() -> Array:
	var ids: Array = bones.keys()
	ids.sort_custom(func(a: String, b: String) -> bool: return float(bones[a]) < float(bones[b]))
	return ids


func last_repaired_bone() -> String:
	var ids := repaired_bones()
	return str(ids.back()) if not ids.is_empty() else ""


# --- Kilitler ve ücret (§7–§8) -----------------------------------------------------------------------------------------

## Kantu uyuyor mu (21:00–07:30; K20)? minute: günün oyun dakikası.
static func kantu_asleep(minute: float) -> bool:
	var from := GameClock.parse_hhmm(Travel.rule("kantu.sleep_from", "21:00"))
	var to := GameClock.parse_hhmm(Travel.rule("kantu.sleep_to", "07:30"))
	var m := fposmod(minute, 1440.0)
	return m >= from or m < to


## Seferin izni (§8): ilk eşleşen kilit. ctx: flags (bayrak okuyan), minute (günün dakikası), requires_flag (ağın bayrağı: tally_kantu),
## cart_lock (hava kilidi ve kalan saat: cart_lock_hours), combat, cart_broken, cargo (araba yükü, Yük), region_open (hedef), far (uzak yol),
## can_pay (ücret var mı; free ise sorulmaz), free (ücretsiz sefer), skip_fare (ücreti sorma: çağırma anı). Döner: {ok, code, text}.
static func allowed(ctx: Dictionary, lang := "tr") -> Dictionary:
	var flags: Variant = ctx.get("flags")
	var lock_flags: Dictionary = Travel.rule("lock_flags", {})
	for lock: Variant in Travel.rule("locks", []):
		var code := str((lock as Dictionary).get("code", ""))
		var hit := false
		match code:
			"pursuit", "bound", "last_night", "raid", "line_closed", "feast":
				for f: Variant in lock_flags.get(code, []):
					if Travel.truthy(Travel._flag(flags, str(f))):
						hit = true
			"combat":
				hit = bool(ctx.get("combat", false))
			"weather":
				hit = bool(ctx.get("cart_lock", false))
			"cart_broken":
				hit = bool(ctx.get("cart_broken", false))
			"no_tally":
				var need := str(ctx.get("requires_flag", ""))
				hit = not need.is_empty() and not Travel.truthy(Travel._flag(flags, need))
			"night":
				hit = ctx.has("minute") and Travel.kantu_asleep(float(ctx["minute"]))
			"region_locked":
				hit = ctx.has("region_open") and not bool(ctx["region_open"])
			"hostage_far":
				hit = bool(ctx.get("far", false)) and not Travel.truthy(Travel._flag(flags, "act1_done"))
			"story_route":
				hit = bool(ctx.get("route_closed", false))
			"overload":
				hit = float(ctx.get("cargo", 0.0)) > float(Travel.rule("cart.capacity", 40.0)) + 0.001
			"no_fare":
				hit = not bool(ctx.get("skip_fare", false)) and not bool(ctx.get("free", false)) and not bool(ctx.get("can_pay", true))
		if hit:
			var t := str((lock as Dictionary).get(lang, (lock as Dictionary).get("tr", code)))
			t = t.replace("{n}", str(int(ceil(float(ctx.get("cart_lock_hours", 1.0))))))
			t = t.replace("{kefil}", str(ctx.get("guarantor", "?"))).replace("{guarantor}", str(ctx.get("guarantor", "?")))
			return {"ok": false, "code": code, "text": t}
	return {"ok": true, "code": "", "text": ""}


## Sefer parasız mı (§7.1): ağda ilk sefer ya da ties.kantu ≥5 (ya da ctx.free: hikâye seferi).
func fare_free(flags: Variant = null) -> bool:
	if bool(Travel.rule("fare.first_free", true)) and trips == 0:
		return true
	var ties: Variant = Travel._flag(flags, str(Travel.rule("fare.ties_flag", "ties.kantu")))
	return (ties is float or ties is int) and float(ties) >= float(Travel.rule("fare.free_ties", 5))


## Ücretin malı (saf olmayan: envanteri okur): kuralın sırasıyla ilk bulunan («meal», «tag:wood»); yoksa "".
static func fare_item(inv: Object) -> String:
	for ref: Variant in Travel.rule("fare.items", ["meal", "tag:wood"]):
		if inv and bool(inv.call(&"has", str(ref), 1)):
			return str(ref)
	return ""


## Ücreti alır (parasız değilse): inv.remove(mal, 1). Döner: {paid: alınan mal ya da "", free}.
func pay_fare(inv: Object, flags: Variant = null) -> Dictionary:
	var free := fare_free(flags)
	trips += 1
	if free:
		return {"paid": "", "free": true}
	var item := Travel.fare_item(inv)
	if not item.is_empty():
		inv.call(&"remove", item, 1)
	return {"paid": item, "free": false}


## Seferin saati (oyun dk): doğal süre × clock_min_per_s (travel.md §6.8: sefer T1 × 0,4 oyun dk).
static func clock_minutes(natural_s: float) -> float:
	return maxf(natural_s, 0.0) * float(Travel.rule("cart.clock_min_per_s", 0.4))


## Arabanın zemin hızları (m/sn): kuralın hızları, cap (K105: oyuncunun en yüksek koşusu) ile kırpılır.
static func cart_speeds(cap := INF) -> Dictionary:
	var out := {}
	var raw: Dictionary = Travel.rule("cart.speed", RoadGraph.SPEEDS)
	for k: String in raw:
		out[k] = minf(float(raw[k]), cap)
	return out


# --- Kayıt v2 («travel» bloğu; travel.md §11) --------------------------------------------------------------------------

## Blok: {v, net: {nodes, edges, cartAt, routes}, rb: {id: dakika}, trips, fares, gossip, narrated, lastStop, ride}.
func to_dict() -> Dictionary:
	return {
		"v": SAVE_V,
		"net": {"nodes": stations.duplicate(), "edges": open_edges.duplicate(), "cartAt": cart_at if not cart_at.is_empty() else null,
			"routes": routes.duplicate()},
		"rb": bones.duplicate(), "trips": trips, "fares": fares.duplicate(true), "gossip": gossip.duplicate(), "narrated": narrated.duplicate(),
		"lastStop": last_stop if not last_stop.is_empty() else null, "ride": (ride as Dictionary).duplicate() if ride is Dictionary else null,
	}


func from_dict(d: Dictionary) -> bool:
	if not Travel.validate_save_block(d).is_empty():
		return false
	reset()
	var net: Dictionary = d.get("net", {})
	for id: Variant in net.get("nodes", {}):
		var st := str((net["nodes"] as Dictionary)[id])
		if STATES.has(st) and st != "hidden":
			stations[str(id)] = st
	open_edges = (net.get("edges", []) as Array).duplicate() if net.get("edges") is Array else []
	cart_at = str(net["cartAt"]) if net.get("cartAt") is String else ""
	routes = (net.get("routes", {}) as Dictionary).duplicate() if net.get("routes") is Dictionary else {}
	var rb: Variant = d.get("rb", {})
	if rb is Dictionary:
		for id: Variant in rb:
			bones[str(id)] = float(rb[id]) if (rb[id] is float or rb[id] is int) else 0.0
	elif rb is Array:
		for i in (rb as Array).size():
			bones[str(rb[i])] = float(i)
	trips = int(d.get("trips", 0))
	fares = (d.get("fares", {}) as Dictionary).duplicate(true) if d.get("fares") is Dictionary else {}
	gossip = (d.get("gossip", []) as Array).duplicate() if d.get("gossip") is Array else []
	narrated = (d.get("narrated", []) as Array).duplicate() if d.get("narrated") is Array else []
	last_stop = str(d["lastStop"]) if d.get("lastStop") is String else ""
	ride = (d["ride"] as Dictionary).duplicate() if d.get("ride") is Dictionary else null
	return true


## Kayıtta blok yoksa (yeni yolculuk): ağ boş (tanımlar kalır).
func reset() -> void:
	stations.clear()
	bones.clear()
	cart_at = ""
	last_stop = ""
	routes.clear()
	open_edges.clear()
	trips = 0
	gossip.clear()
	fares.clear()
	narrated.clear()
	ride = null


## Bloğun durağan denetimi (SaveBlocks.OWNERS «travel»; "" geçer).
static func validate_save_block(d: Dictionary) -> String:
	var net: Variant = d.get("net", {})
	if not net is Dictionary:
		return "travel.net sözlük değil"
	var nodes: Variant = (net as Dictionary).get("nodes", {})
	if not nodes is Dictionary:
		return "travel.net.nodes sözlük değil"
	for id: Variant in nodes:
		if not STATES.has(str((nodes as Dictionary)[id])):
			return "travel.net.nodes.%s durumu bilinmiyor" % str(id)
	var rb: Variant = d.get("rb", {})
	if not (rb is Dictionary or rb is Array):
		return "travel.rb sözlük değil"
	var ride_v: Variant = d.get("ride")
	if ride_v != null and not ride_v is Dictionary:
		return "travel.ride sözlük değil"
	return ""


## Oturumun blok kaydına bağlanır (kayıt v2; sıra 60: dünya ve envanterden sonra).
func register_block(blocks: SaveBlocks) -> void:
	if blocks == null:
		return
	blocks.register(BLOCK, SAVE_V, to_dict, from_dict, {"reset": reset, "check": Travel.validate_save_block, "order": 60, "max_bytes": MAX_BYTES})
