class_name SiteState
extends RefCounted
## Bir şantiyenin durumu (godot.md §3 «Emek ve aşamalı yapı», §3.1 adım 5; structures.md §2.4, §2.5, §11.6, §11.8; K21, K50, K52, K83):
## saftır, düğüm ve saat okumaz. Yapının adımlarını (Labour.steps_of; boyun emek payıyla), işlenen emeği, aşamayı, can havuzlarını, hasarı,
## yanığı ve yırtığı tutar; zamanı çağıran verir (mutlak oyun dakikası). Görünüm (StagedStructure) yalnız okur: stage, stage_t, damage,
## burn, tear örnek tekdüzenlerine gider.
##
## Emek olay güdümlüdür: oran (Labour.build_rate) iki olay arasında sabittir; olaylar adımın bitişi, ekip üyesinin gelişi ya da ayrılışı
## (öğün, iş penceresi, ayak işi seferi, «Gece dinlenilsin»), adım kapısı (hikâye ya da aile kuralı) ve zamanlanmış olaylardır
## (add_event: Ambar gönderimi, 23:00 denetimi, Ana'nın közü). Böylece kare kare ilerleme ile tek seferde atlama (uyku, Bekle, çalışma,
## dünyaya dönüş) aynı sonucu verir (structures.md §2.5: 600 dk tek adım = 600 × 1 dk, ±1e−6 İD).
##
## Aşama: stage en son biten aşamadır (−1: daha zemin bitmedi; 0–7 act1.md'nin numaraları), stage_t sıradaki aşamanın emek payında
## gelinen orandır (0..1). Can havuzları aşama başınadır (Küçük 216, Hane 420, Otağ 843; data/structures/structures.json sizes.pools); hasar
## en üstteki ayakta havuzdan düşer, havuz biterse aşama geri düşer ve artan hasar sonrakine geçer (LIFO, structures.md §5.4); aşama 0
## yıkılmaz. Düşen aşamanın adımları yeniden kurulur (onarım: payın 0,8'i, yanık birimde ×1,25; Labour.repair_work kuralı).
##
## Ekip üyeleri Labour'un biçimindedir ({id, role, w, crafts}) ve şu alanları da taşıyabilir: meals [[gün dk, süre], …] (öğün: ekipte
## sayılmaz), shift [başı, sonu] (iş penceresi; gece yarısını aşabilir), away [[başı, sonu], …] (mutlak dakika; seferler). Çocuk
## (role child, w 0,5) yalnız child.joined ve child.active iken, adımın yardım fiili varken ve adım child: false değilken sayılır (K52).
##   var site := SiteState.create("yurt", "m", {"raw": false, "torch_free": true})
##   site.crew = [{"id": "oktar", "role": "usta", "w": 1.0}, ...]
##   site.start(894.0)                  # emek bu dakikadan işler
##   site.advance(clock.abs_minute())   # her kare ya da atlamadan sonra
##   site.stage, site.stage_t           # görünüm için

signal step_finished(step_id: String, at_min: float)
signal stage_changed(stage: int, previous: int)
signal finished(at_min: float)
signal fell(stage: int, cause: String)

const STRUCTURES_PATH := "res://data/structures/structures.json"
const SITES_PATH := "res://data/structures/sites.json"
const STAGE_COUNT := 8
const NO_STAGE := -1
## Yırtığın tavanı (sıkı kayıt; structures.md §11.8).
const TEARS_MAX := 8
## Canın nicemi (structures.md §11.8: 0,5 adımla).
const HP_QUANTUM := 0.5
## Olay döngüsünün bir advance çağrısındaki tavanı (bozuk veride sonsuz döngü olmasın).
const MAX_EVENTS := 4096
const EPS := 1e-9
## Yardım fiilleri (K52; Çocuk yalnız bunlarla ekipte sayılır). Ayak işleri (help_water, help_log, help_ember) ekip saymaz.
const HELP_VERBS: Array[String] = ["help_tamp", "help_carry", "help_hold", "help_tie", "help_heave", "help_pull"]
## Boy → türün emek satırı (data/structures/structures.json: defs.yurt, settlement.yurt_small, settlement.otag).
const SIZE_KIND := {"s": "yurt_small", "m": "yurt", "l": "otag"}
## Yurt gövdeli türler (boy, millet, düzen taşır; K51).
const YURT_KINDS: Array[String] = ["yurt", "yurt_small", "otag", "beg_otag", "store_yurt", "envoy_yurt", "healer_yurt", "cmd_yurt",
	"armoury", "fletchery", "supply_depot"]

var id := ""
var kind := "yurt"
var size := "m"
## Kurulum sırasıyla adımlar: {id, stage, work, slots, felt, tall, lattice, child, workIfEmber, help, cost}.
var steps: Array = []
## Sıradaki adımın dizini (steps.size() ise yapı bitti) ve o adımda işlenen emek (İD).
var step := 0
var wm := 0.0
var stage := NO_STAGE
## Aşama başına can: en çok (pools) ve şimdiki (hp).
var pools := PackedFloat64Array()
var hp := PackedFloat64Array()
## Yanık (0..1, kömürleşme), yırtık sayısı (≤8), yanma süresi (oyun dk; yanarken > 0).
var burn := 0.0
var tears := 0
var burning := 0.0
## Ekip, Çocuk ve yığın.
var crew: Array = []
var child := {"joined": false, "active": true, "water": 0, "logs": 0, "ember": 0}
var stock := {}
## Köz yığında mı (y_ocak workIfEmber; help_ember ya da Ana'nın közü).
var ember := false
## Adım kapıları: adım kimliği → mutlak dakika (o ana dek başlamaz) ya da true (kapalı; hikâye kapısı «story»).
var gates := {}
## Adım başına ekip değişimi: adım kimliği → üye dizisi (Kışlak'ın tündüğü altı el, ocağı Atşo).
var step_crew := {}
## Ortam: weather (tür kimliği), night (lit, day, dim, dark), fed (K_tok iğnesi), speed, mods (beceri).
var env := {"weather": "clear", "night": "lit", "fed": 1.0, "speed": 1.0}
## Seçenekler: raw (ham teslim; I. Perde false), torch_free (meşale bedava: gece ×1), rest (Gece dinlenilsin; [başı, sonu] gün dk).
var opts := {"raw": false, "torch_free": true}
var rest_window: Array = []
## Ayak işleri: ad → {step, need, trip_min, who, done}.
var errands := {}
## Zaman: emeğin başladığı, en son işlendiği ve bittiği an (mutlak dk; NAN yok).
var started_at := NAN
var last_min := NAN
var finished_at := NAN
## Adımın bittiği an (kimlik → mutlak dk) ve katkı (İD: player, npc).
var log := {}
var contrib := {"player": 0.0, "npc": 0.0}
## Şimdiki oran ve durdurma nedeni (Labour.build_rate'in info'su; arayüz okur).
var rate := 0.0
var wait_reason: Variant = null
## Düşen aşamanın adımları onarımdır (pay ×0,8): adım kimliği → çarpan.
var rework := {}

var _events: Array = []
var _crew_info := {}
var _members_buf: Array = []


# --- Kurulum ----------------------------------------------------------------------------------------

## Türün ve boyun şantiyesi: adımlar Labour.steps_of'tan (yurt gövdelide boyun satırı: Küçük ×0,4, Otağ ×2,5), can havuzları
## sizes.pools'tan (yurt dışı türlerde adımların aşama sayısı kadar eşit havuz), maliyetler sites.json costs'tan. opts: raw, torch_free.
static func create(p_kind: String, p_size: String = "m", p_opts: Dictionary = {}) -> SiteState:
	var s := SiteState.new()
	s.kind = p_kind
	s.size = p_size if SIZE_KIND.has(p_size) else "m"
	s.opts.merge(p_opts, true)
	var src_kind := SiteState.labour_kind(p_kind, s.size)
	s.steps = Labour.steps_of(src_kind)
	var costs: Dictionary = (SiteState.sites_data().get("costs", {}) as Dictionary).get("yurt" if SiteState.is_yurt(p_kind) else p_kind, {})
	for st: Dictionary in s.steps:
		if not st.has("cost"):
			st["cost"] = (costs.get(str(st.get("id", "")), {}) as Dictionary).duplicate()
	if p_kind == "store_yurt" or p_kind == "armoury" or p_kind == "fletchery" or p_kind == "supply_depot":
		# Settlement satırı adımları zaten türetir (drop, add).
		pass
	s.pools = SiteState.pools_for(p_kind, s.size, s.steps)
	s.hp = s.pools.duplicate()
	return s


## Türün emek satırı: yurt gövdelide boyun satırı (s yurt_small, l otag), öteki türler kendisi.
static func labour_kind(p_kind: String, p_size: String) -> String:
	if p_kind == "yurt" or p_kind == "yurt_small" or p_kind == "otag" or p_kind == "beg_otag":
		return str(SIZE_KIND.get(p_size, "yurt"))
	return p_kind


static func is_yurt(p_kind: String) -> bool:
	return YURT_KINDS.has(p_kind)


## Aşama başına can (structures.md §2.3): yurtta boyun havuzları; öteki türde progression.md'nin toplamı bilinmiyorsa aşama başına 20.
static func pools_for(p_kind: String, p_size: String, p_steps: Array) -> PackedFloat64Array:
	var out := PackedFloat64Array()
	out.resize(STAGE_COUNT)
	if SiteState.is_yurt(p_kind):
		var sizes: Dictionary = (Labour.structures().get("sizes", {}) as Dictionary)
		var row: Dictionary = sizes.get(p_size, sizes.get("m", {}))
		var list: Array = row.get("pools", [0, 40, 60, 50, 80, 40, 120, 30])
		for i in mini(list.size(), STAGE_COUNT):
			out[i] = float(list[i])
		return out
	var top := 0
	for st: Dictionary in p_steps:
		top = maxi(top, int(st.get("stage", 0)))
	for i in range(1, mini(top + 1, STAGE_COUNT)):
		out[i] = 20.0
	return out


## data/structures/sites.json (bir kez okunur).
static var _sites: Dictionary = {}


static func sites_data() -> Dictionary:
	if _sites.is_empty() and FileAccess.file_exists(SITES_PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SITES_PATH))
		_sites = parsed if parsed is Dictionary else {}
	return _sites


static func site_spec(site_id: String) -> Dictionary:
	return (SiteState.sites_data().get("sites", {}) as Dictionary).get(site_id, {})


static func reset_cache() -> void:
	_sites = {}


## «hh:mm» ya da sayı → gün dakikası (saf).
static func day_min(v: Variant) -> float:
	return Labour.day_minute(v)


## Emek bu dakikadan işler (bir kez; sonraki çağrı yok sayılır).
func start(at_min: float) -> void:
	if not is_nan(started_at):
		return
	started_at = at_min
	last_min = at_min
	_begin_step(at_min)


func is_started() -> bool:
	return not is_nan(started_at)


func is_done() -> bool:
	return step >= steps.size()


# --- Okuma -------------------------------------------------------------------------------------------

## Adımın aşaması.
func stage_of(i: int) -> int:
	return int((steps[i] as Dictionary).get("stage", 0)) if i >= 0 and i < steps.size() else STAGE_COUNT - 1


## Sıradaki adım ({} bitince).
func current_step() -> Dictionary:
	return steps[step] if step < steps.size() else {}


func current_id() -> String:
	return str(current_step().get("id", ""))


## Adımın işi (İD): payı, köz yığındaysa workIfEmber, onarımsa ×rework, ham teslimse rawWork (I. Perde'de yok).
func work_of(i: int) -> float:
	if i < 0 or i >= steps.size():
		return 0.0
	var st: Dictionary = steps[i]
	var w := Labour.step_work(st, {"raw": bool(opts.get("raw", false)), "ember": ember})
	return w * float(rework.get(str(st.get("id", "")), 1.0))


## Yapının bütün işi (İD; şimdiki köz durumuyla).
func total_work() -> float:
	var t := 0.0
	for i in steps.size():
		t += work_of(i)
	return t


## Sıradaki aşamada gelinen oran (0..1): aşamanın adımlarının biten emeği / aşamanın emeği.
func stage_progress() -> float:
	if is_done():
		return 1.0
	var target := stage + 1
	var total := 0.0
	var done := 0.0
	for i in steps.size():
		if stage_of(i) != target:
			continue
		var w := work_of(i)
		total += w
		if i < step:
			done += w
		elif i == step:
			done += minf(wm, w)
	return clampf(done / total, 0.0, 1.0) if total > EPS else 0.0


## Görünüm tekdüzeni: stage_t (sıradaki aşamanın oranı).
var stage_t: float:
	get:
		return stage_progress()


## Üst havuzun eksik payı (0..1; görünümün hasar tekdüzeni).
var damage: float:
	get:
		if stage < 1:
			return 0.0
		var top := float(pools[stage])
		return clampf(1.0 - float(hp[stage]) / top, 0.0, 1.0) if top > EPS else 0.0


## Yırtık oranı (0..1; görünümün tear tekdüzeni).
var tear: float:
	get:
		return clampf(float(tears) / float(TEARS_MAX), 0.0, 1.0)


## Toplam can ve yapının en çok canı.
func hp_total() -> float:
	var t := 0.0
	for i in hp.size():
		t += float(hp[i])
	return t


func hp_max() -> float:
	var t := 0.0
	for i in pools.size():
		t += float(pools[i])
	return t


# --- Ekip ----------------------------------------------------------------------------------------------

## Üye t anında şantiyede mi: öğünde, iş penceresinin dışında, seferde ya da «Gece dinlenilsin» penceresinin dışındaysa değil.
func present(m: Dictionary, t: float) -> bool:
	var dm := fposmod(t, 1440.0)
	for meal: Variant in m.get("meals", []):
		if meal is Array and (meal as Array).size() >= 2:
			var a := SiteState.day_min(meal[0])
			if SiteState._in_window(dm, a, a + float(meal[1])):
				return false
	var shift: Variant = m.get("shift")
	if shift is Array and (shift as Array).size() >= 2:
		if not SiteState._in_window(dm, SiteState.day_min(shift[0]), SiteState.day_min(shift[1])):
			return false
	for span: Variant in m.get("away", []):
		if span is Array and (span as Array).size() >= 2 and t >= float(span[0]) - EPS and t < float(span[1]) - EPS:
			return false
	if rest_window.size() >= 2 and not SiteState._in_window(dm, SiteState.day_min(rest_window[0]), SiteState.day_min(rest_window[1])):
		return false
	return true


## Gün dakikası pencerede mi ([a, b); gece yarısını aşabilir).
static func _in_window(dm: float, a: float, b: float) -> bool:
	var aa := fposmod(a, 1440.0)
	var bb := fposmod(b, 1440.0)
	if absf(b - a) >= 1440.0 - EPS:
		return true
	if aa <= bb:
		return dm >= aa - EPS and dm < bb - EPS
	return dm >= aa - EPS or dm < bb - EPS


## Çocuk bu adımda ekipte sayılır mı (K52: yardım fiili, child: false değil, katılmış ve fiili yapıyor)?
func child_counts(st: Dictionary) -> bool:
	if not bool(child.get("joined", false)) or not bool(child.get("active", true)):
		return false
	if st.get("child", true) == false:
		return false
	for h: Variant in st.get("help", []):
		if HELP_VERBS.has(str(h)):
			return true
	return false


## t anında adımda çalışan ekip (Labour'un biçiminde; tampon paylaşılır).
func members_at(t: float, i: int = -1) -> Array:
	var idx := step if i < 0 else i
	_members_buf.clear()
	var st: Dictionary = steps[idx] if idx < steps.size() else {}
	var list: Array = step_crew.get(str(st.get("id", "")), crew)
	for m: Variant in list:
		if m is Dictionary and str((m as Dictionary).get("role", "")) != "child" and present(m, t):
			_members_buf.append(m)
	if child_counts(st):
		_members_buf.append({"id": "child", "role": "child", "w": 0.5})
	return _members_buf


## Adımın t anındaki oranı (İD / oyun dk) ve nedeni (wait_reason'a yazılır).
func rate_at(t: float, i: int = -1) -> float:
	var idx := step if i < 0 else i
	if idx >= steps.size():
		wait_reason = null
		return 0.0
	var st: Dictionary = steps[idx]
	var gate: Variant = gates.get(str(st.get("id", "")))
	if gate is bool and gate:
		wait_reason = "story"
		return 0.0
	if (gate is float or gate is int) and t < float(gate) - EPS:
		wait_reason = "story"
		return 0.0
	if not _has_cost(st):
		wait_reason = "material"
		return 0.0
	var members := members_at(t, idx)
	var lk := SiteState.labour_kind(kind, size)
	var pick := {"max": Labour.crew_max(lk), "child": st.get("child", true), "rawRole": st.get("rawRole")}
	Labour.crew_on(pick, members, st.get("craft", Labour._craft_of_kind(lk)), _crew_info)
	var e := env.duplicate()
	e["kind"] = "repair" if rework.has(str(st.get("id", ""))) else "build"
	e["raw"] = bool(opts.get("raw", false))
	e["coef_max"] = Labour.coef_max_of(SiteState.labour_kind(kind, size))
	if bool(opts.get("torch_free", false)) and str(e.get("night", "lit")) != "day":
		e["night"] = "lit"
	var info := {}
	var r := Labour.build_rate(st, _crew_info, e, info)
	wait_reason = info.get("reason")
	return r


## Adımın malzemesi yığında mı (cost; boş cost her zaman hazır). Yığın sözlüğü boşsa ve stock_free açıksa hazır sayılır.
func _has_cost(st: Dictionary) -> bool:
	if bool(opts.get("stock_free", true)) and stock.is_empty():
		return true
	if bool(st.get("_paid", false)):
		return true
	var cost: Dictionary = st.get("cost", {})
	for item: String in cost:
		if item == "ember":
			continue
		if float(stock.get(item, 0.0)) + EPS < float(cost[item]):
			return false
	return true


func _pay(st: Dictionary) -> void:
	if bool(st.get("_paid", false)):
		return
	var cost: Dictionary = st.get("cost", {})
	if not stock.is_empty() or not bool(opts.get("stock_free", true)):
		for item: String in cost:
			if item == "ember":
				continue
			stock[item] = maxf(0.0, float(stock.get(item, 0.0)) - float(cost[item]))
	st["_paid"] = true


## Yığına malzeme (teslim; who "player" ya da "npc").
func deliver(item: String, n: float, who: String = "npc") -> void:
	stock[item] = float(stock.get(item, 0.0)) + n
	if who == "player":
		child["delivered"] = int(child.get("delivered", 0)) + int(n)


# --- Olaylar ---------------------------------------------------------------------------------------------

## Zamanlanmış olay: at_min'e varınca fn(site, at_min) çağrılır (advance onu o anda durdurur). Aynı anın olayları ekleniş sırasıyla.
func add_event(at_min: float, fn: Callable, tag: String = "") -> void:
	_events.append({"at": at_min, "fn": fn, "tag": tag})
	_events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["at"]) < float(b["at"]))


func has_event(tag: String) -> bool:
	for e: Dictionary in _events:
		if str(e["tag"]) == tag:
			return true
	return false


func clear_events(tag: String = "") -> void:
	if tag.is_empty():
		_events.clear()
		return
	_events = _events.filter(func(e: Dictionary) -> bool: return str(e["tag"]) != tag)


## Kayıttan dönüşte: t anına dek olan zamanlanmış olaylar atılır (kayıttan önce çalıştılar, sonuçları kayıttadır; yeniden çalışırsa
## 23:00 denetimi o anki aşamayla yanlış karar verirdi).
func drop_events_until(t: float) -> void:
	_events = _events.filter(func(e: Dictionary) -> bool: return float(e["at"]) > t + EPS)


## t'den sonraki ilk olay anı: ekibin gelişi ya da gidişi, kapının açılışı, zamanlanmış olay. Yoksa INF.
func next_boundary(t: float) -> float:
	var best := INF
	var day0 := floorf(t / 1440.0) * 1440.0
	var lists: Array = [crew]
	for list: Variant in step_crew.values():
		lists.append(list)
	for list: Array in lists:
		for m: Variant in list:
			if not m is Dictionary:
				continue
			var md: Dictionary = m
			for meal: Variant in md.get("meals", []):
				if meal is Array and (meal as Array).size() >= 2:
					var a := SiteState.day_min(meal[0])
					best = minf(best, SiteState._next_daily(t, day0, a))
					best = minf(best, SiteState._next_daily(t, day0, a + float(meal[1])))
			var shift: Variant = md.get("shift")
			if shift is Array and (shift as Array).size() >= 2:
				best = minf(best, SiteState._next_daily(t, day0, SiteState.day_min(shift[0])))
				best = minf(best, SiteState._next_daily(t, day0, SiteState.day_min(shift[1])))
			for span: Variant in md.get("away", []):
				if span is Array and (span as Array).size() >= 2:
					for edge in [float(span[0]), float(span[1])]:
						if edge > t + EPS:
							best = minf(best, edge)
	if rest_window.size() >= 2:
		best = minf(best, SiteState._next_daily(t, day0, SiteState.day_min(rest_window[0])))
		best = minf(best, SiteState._next_daily(t, day0, SiteState.day_min(rest_window[1])))
	if step < steps.size():
		var gate: Variant = gates.get(current_id())
		if (gate is float or gate is int) and float(gate) > t + EPS:
			best = minf(best, float(gate))
	for e: Dictionary in _events:
		if float(e["at"]) > t + EPS:
			best = minf(best, float(e["at"]))
			break
	return best


static func _next_daily(t: float, day0: float, dm: float) -> float:
	var x := day0 + fposmod(dm, 1440.0)
	while x <= t + EPS:
		x += 1440.0
	return x


# --- İlerleme ----------------------------------------------------------------------------------------------

## Emeği to_min'e dek işler (olay güdümlü). Olayların anında zamanlanmış olaylar çalışır, adım ve aşama olayları yayılır. Dönüş: işlenen
## emek (İD). Başlamamış ya da bitmiş şantiyede yalnız zaman ve olaylar ilerler.
func advance(to_min: float) -> float:
	if is_nan(last_min):
		return 0.0
	var worked := 0.0
	var guard := 0
	while last_min < to_min - EPS and guard < MAX_EVENTS:
		guard += 1
		_fire_events(last_min)
		var t := last_min
		var r := rate_at(t) if not is_done() else 0.0
		rate = r
		var nxt := minf(next_boundary(t), to_min)
		if r > 0.0:
			_pay(steps[step])
			var left := work_of(step) - wm
			var t_fin := t + left / r
			if t_fin <= nxt + EPS:
				worked += left
				_credit(left)
				last_min = t_fin
				_finish_step(t_fin)
				continue
			var add := r * (nxt - t)
			wm += add
			worked += add
			_credit(add)
		last_min = nxt
	_fire_events(last_min)
	if not is_done():
		rate = rate_at(last_min)
	return worked


## t anına dek olan zamanlanmış olayları çalıştırır.
func _fire_events(t: float) -> void:
	var guard := 0
	while not _events.is_empty() and float((_events[0] as Dictionary)["at"]) <= t + EPS and guard < 64:
		guard += 1
		var e: Dictionary = _events.pop_front()
		var fn: Callable = e["fn"]
		if fn.is_valid():
			fn.call(self, float(e["at"]))


func _credit(add: float) -> void:
	contrib["npc"] = float(contrib.get("npc", 0.0)) + add


func _finish_step(t: float) -> void:
	var st: Dictionary = steps[step]
	var sid := str(st.get("id", ""))
	log[sid] = t
	rework.erase(sid)
	var prev_stage := stage
	step += 1
	wm = 0.0
	# Aşama: adımları bitmiş en yüksek aşama (aşamalar sırayla biter).
	var s_now := stage
	for k in range(maxi(stage + 1, 0), STAGE_COUNT):
		var all_done := true
		var any := false
		for i in steps.size():
			if stage_of(i) == k:
				any = true
				if i >= step:
					all_done = false
		if any and all_done:
			s_now = k
		elif any:
			break
	step_finished.emit(sid, t)
	if s_now != prev_stage:
		stage = s_now
		stage_changed.emit(stage, prev_stage)
	if is_done():
		finished_at = t
		finished.emit(t)
	else:
		_begin_step(t)


## Adım başlarken: malzeme ödenir, ayak işlerinin seferleri kurulur (eksik birim × sefer; çırak o sürede ekipte sayılmaz).
func _begin_step(t: float) -> void:
	if step >= steps.size():
		return
	var st: Dictionary = steps[step]
	var sid := str(st.get("id", ""))
	if _has_cost(st):
		_pay(st)
	for key: String in errands:
		var e: Dictionary = errands[key]
		if str(e.get("step", "")) != sid or bool(e.get("done", false)):
			continue
		e["done"] = true
		var have := int(child.get(key, 0))
		var missing := maxi(int(e.get("need", 0)) - have, 0)
		if missing <= 0 or not e.has("who"):
			continue
		var trip := float(e.get("trip_min", 0.0)) * float(missing)
		for m: Variant in crew:
			if m is Dictionary and str((m as Dictionary).get("id", "")) == str(e["who"]):
				var away: Array = (m as Dictionary).get("away", [])
				away.append([t, t + trip])
				(m as Dictionary)["away"] = away
		e["trip_from"] = t
		e["trip_to"] = t + trip


## Ayak işleri: ad → {step, need, trip_real_s, who} (sites.json errands biçimi; sefer gerçek sn'den oyun dk'ya).
func set_errands(table: Dictionary) -> void:
	errands.clear()
	for key: String in table:
		var e: Dictionary = (table[key] as Dictionary).duplicate(true)
		e["trip_min"] = float(e.get("trip_real_s", 0.0)) / Labour.real_s_per_min()
		errands[key] = e


## Çocuğun ayak işi (help_water, help_log, help_ember): sayaç artar; köz gelirse y_ocak workIfEmber olur.
func child_errand(kind_id: String, n: int = 1) -> void:
	match kind_id:
		"water", "help_water":
			child["water"] = mini(int(child.get("water", 0)) + n, 2)
		"logs", "help_log":
			child["logs"] = mini(int(child.get("logs", 0)) + n, 4)
		"ember", "help_ember":
			child["ember"] = 1
			ember = true


# --- Kestirim ----------------------------------------------------------------------------------------------

## Bitişin kestirimi (mutlak dk; olaylarla, kopya üstünde): şimdiki ekip, kapılar ve zamanlanmış olaylarla benzetilir. Bitmezse INF.
## horizon: en çok kaç oyun dakikası bakılır (varsayılan 3 gün).
func eta(horizon: float = 4320.0) -> float:
	if is_done():
		return finished_at
	if is_nan(last_min):
		return INF
	var copy := duplicate_state()
	copy._events = _events.duplicate()
	copy.advance(last_min + horizon)
	return copy.finished_at if copy.is_done() else INF


## Durumun derin kopyası (olaylar ve sinyaller hariç).
func duplicate_state() -> SiteState:
	var c := SiteState.new()
	c.id = id
	c.kind = kind
	c.size = size
	c.steps = steps.duplicate(true)
	c.step = step
	c.wm = wm
	c.stage = stage
	c.pools = pools.duplicate()
	c.hp = hp.duplicate()
	c.burn = burn
	c.tears = tears
	c.crew = crew.duplicate(true)
	c.child = child.duplicate(true)
	c.stock = stock.duplicate(true)
	c.ember = ember
	c.gates = gates.duplicate(true)
	c.step_crew = step_crew.duplicate(true)
	c.env = env.duplicate(true)
	c.opts = opts.duplicate(true)
	c.rest_window = rest_window.duplicate()
	c.errands = errands.duplicate(true)
	c.started_at = started_at
	c.last_min = last_min
	c.finished_at = finished_at
	c.log = log.duplicate()
	c.rework = rework.duplicate()
	return c


# --- Hasar ve onarım ------------------------------------------------------------------------------------

## Hasar (can): en üstteki ayakta havuzdan düşer; havuz biterse aşama geri düşer, artan sonrakine geçer (aşama 0 yıkılmaz). Düşen aşamaların
## adımları onarım olarak yeniden kurulur (pay ×0,8; yanık ×1,25). Dönüş: düşülen aşama sayısı.
func hit(amount: float, cause: String = "hit") -> int:
	var left := maxf(amount, 0.0)
	var drops := 0
	while left > EPS and stage >= 1:
		var cur := float(hp[stage])
		if left < cur - EPS:
			hp[stage] = snappedf(cur - left, HP_QUANTUM)
			left = 0.0
			break
		left -= cur
		hp[stage] = 0.0
		_fall_to(stage - 1, cause)
		drops += 1
	return drops


## Senaryolu düşüş (setStage): aşama n'ye iner; üstteki havuzlar boşalır.
func set_stage(n: int, cause: String = "story") -> void:
	var target := clampi(n, NO_STAGE, STAGE_COUNT - 1)
	while stage > target and stage >= 1:
		hp[stage] = 0.0
		_fall_to(stage - 1, cause)
	if target > stage:
		ensure_stage(target)


## Emniyet (ensureStage): aşama en az n olur; araya giren adımlar bitmiş sayılır.
func ensure_stage(n: int) -> void:
	var target := clampi(n, NO_STAGE, STAGE_COUNT - 1)
	var t := last_min if not is_nan(last_min) else 0.0
	while not is_done() and stage < target:
		_finish_step(t)
	for k in range(0, maxi(stage + 1, 0)):
		hp[k] = pools[k]


func _fall_to(s: int, cause: String) -> void:
	var prev := stage
	stage = s
	var burnt := cause == "fire" or burn > 0.25
	for i in steps.size():
		if stage_of(i) > s:
			var sid := str((steps[i] as Dictionary).get("id", ""))
			(steps[i] as Dictionary)["_paid"] = true
			log.erase(sid)
			rework[sid] = Labour._num(Labour.law().get("repair", {}), "raise", 0.8) * (Labour._num(Labour.law().get("repair", {}), "burnt", 1.25) if burnt else 1.0)
	var first := steps.size()
	for i in steps.size():
		if stage_of(i) > s:
			first = i
			break
	step = first
	wm = 0.0
	finished_at = NAN
	for k in range(s + 1, STAGE_COUNT):
		hp[k] = pools[k]
	stage_changed.emit(stage, prev)
	fell.emit(stage, cause)


## Yırtık (senaryo ya da kılıç): sayaç ≤8.
func add_tear(n: int = 1) -> void:
	tears = clampi(tears + n, 0, TEARS_MAX)


## Yanık: kömürleşme biriktirir (0..1).
func add_burn(k: float) -> void:
	burn = clampf(burn + k, 0.0, 1.0)


# --- Kayıt ----------------------------------------------------------------------------------------------

## Sıkı kayıt (structures.md §11.8; v 2): aşama, adım ve adım içi oran, can (0,5 nicem), yanık, yırtık (≤8), katkı, Çocuğun ayak işleri,
## köz, zaman. Boy, millet ve düzen yapının kaydındadır (K51); eksik alan varsayılana düşer.
func to_dict() -> Dictionary:
	var hp_out: Array = []
	for i in hp.size():
		hp_out.append(snappedf(float(hp[i]), HP_QUANTUM))
	var w := work_of(step)
	return {
		"v": 2, "id": id, "kind": kind, "size": size, "stage": stage, "step": step,
		"step_t": snappedf(wm / w, 0.0001) if w > EPS and step < steps.size() else 0.0,
		"hp": hp_out, "burn": snappedf(burn, 0.001), "cut": tears,
		"contrib": {"player": snappedf(float(contrib.get("player", 0.0)), 0.01), "npc": snappedf(float(contrib.get("npc", 0.0)), 0.01)},
		"child": {"joined": bool(child.get("joined", false)), "logs": int(child.get("logs", 0)), "ember": int(child.get("ember", 0)),
			"water": int(child.get("water", 0))},
		"ember": ember, "start": started_at if not is_nan(started_at) else null,
		"last": last_min if not is_nan(last_min) else null, "done_at": finished_at if not is_nan(finished_at) else null,
		"rework": rework.duplicate(), "errands": _errand_flags(),
	}


## «sites» bloğunun durağan denetimi (SaveBlocks.OWNERS; kayıt v2, godot.md §3.4): {v, zones: {zon: {sites: {kimlik: şantiye}}}}.
## Şantiye sözlüktür; step, stage ve start sayı (start null da olur). Boş dize geçer.
static func validate_save_block(d: Dictionary) -> String:
	var zones: Variant = d.get("zones", {})
	if not zones is Dictionary:
		return "sites.zones sözlük değil"
	for z: Variant in zones:
		var zone: Variant = (zones as Dictionary)[z]
		if not zone is Dictionary:
			return "sites.zones.%s sözlük değil" % str(z)
		var list: Variant = (zone as Dictionary).get("sites", {})
		if not list is Dictionary:
			return "sites.zones.%s.sites sözlük değil" % str(z)
		for sid: Variant in list:
			var s: Variant = (list as Dictionary)[sid]
			if not s is Dictionary:
				return "sites.%s.%s sözlük değil" % [str(z), str(sid)]
			for key: String in ["step", "stage", "start"]:
				var v: Variant = (s as Dictionary).get(key, 0)
				if v != null and not (v is int or v is float):
					return "sites.%s.%s.%s sayı değil" % [str(z), str(sid), key]
	return ""


func _errand_flags() -> Dictionary:
	var out := {}
	for key: String in errands:
		out[key] = bool((errands[key] as Dictionary).get("done", false))
	return out


## Kayıttan (to_dict biçimi): bozuk alan sessizce varsayılana düşer; adımın emeği adımın payından yeniden hesaplanır (K50). Dönüş: okundu mu.
func from_dict(d: Dictionary) -> bool:
	if d.is_empty():
		return false
	var s_step := clampi(int(d.get("step", 0)), 0, steps.size())
	step = s_step
	stage = clampi(int(d.get("stage", NO_STAGE)), NO_STAGE, STAGE_COUNT - 1)
	var rw: Variant = d.get("rework", {})
	rework = (rw as Dictionary).duplicate() if rw is Dictionary else {}
	ember = bool(d.get("ember", false))
	var ch: Variant = d.get("child", {})
	if ch is Dictionary:
		child["joined"] = bool((ch as Dictionary).get("joined", false))
		child["logs"] = clampi(int((ch as Dictionary).get("logs", 0)), 0, 4)
		child["ember"] = clampi(int((ch as Dictionary).get("ember", 0)), 0, 1)
		child["water"] = clampi(int((ch as Dictionary).get("water", 0)), 0, 2)
	wm = clampf(float(d.get("step_t", 0.0)), 0.0, 1.0) * work_of(step)
	var hp_in: Variant = d.get("hp", [])
	if hp_in is Array:
		for i in mini((hp_in as Array).size(), hp.size()):
			hp[i] = clampf(float(hp_in[i]), 0.0, float(pools[i]))
	burn = clampf(float(d.get("burn", 0.0)), 0.0, 1.0)
	tears = clampi(int(d.get("cut", 0)), 0, TEARS_MAX)
	var c: Variant = d.get("contrib", {})
	if c is Dictionary:
		contrib = {"player": float((c as Dictionary).get("player", 0.0)), "npc": float((c as Dictionary).get("npc", 0.0))}
	started_at = float(d["start"]) if d.get("start") is float or d.get("start") is int else NAN
	last_min = float(d["last"]) if d.get("last") is float or d.get("last") is int else started_at
	finished_at = float(d["done_at"]) if d.get("done_at") is float or d.get("done_at") is int else NAN
	var ef: Variant = d.get("errands", {})
	if ef is Dictionary:
		for key: String in errands:
			(errands[key] as Dictionary)["done"] = bool((ef as Dictionary).get(key, false))
	for i in mini(step, steps.size()):
		(steps[i] as Dictionary)["_paid"] = true
		log[str((steps[i] as Dictionary).get("id", ""))] = finished_at if not is_nan(finished_at) else last_min
	return true
