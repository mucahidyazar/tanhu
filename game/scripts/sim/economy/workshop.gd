class_name Workshop
extends RefCounted
## Bir tezgâhın sipariş kuyruğu ve bekleme yuvaları (saf; economy.md §6.7, §6.13; godot.md §3 «Zanaat»). Prototipin game/craft.js
## Workshop'unun Godot'su; sayılar ve adım kuralı aynıdır (tests/fixtures/crafting.json). Tezgâh işi oyun saatiyle akar, oyuncuyu bekletmez:
## sürücü (yerleşim ya da deneme haritasının katmanı) geçen oyun dakikasını tick'e verir; uykuda ve atlamada da akar.
##
## Kurallar: sipariş «Yap» (adet); girdi birim başlarken havuzdan ayrılır, eksikse «Malzeme bekliyor»; usta işi ustasız başlamaz («Usta
## gerek»), Çırak usta değildir; eller tezgâhın el sınırıyla kırpılır, oran eff(W) × K_gece × K_hava (Labour.station_rate; açık hava tezgâhı
## havanın çarpanını alır, Keçe Avlusu keçe adımınınkini); üretim penceresi dışında yalnız gece vardiyası çalışır; ışıklı atölye karanlığın
## her 4 oyun saatinde 1 meşale yakar, meşalesiz ışıksız sayılır (×0,4). Bekleme yuvası el istemez; açık hava yuvası havanın kurutma
## çarpanıyla ilerler, çisenti, yağmur ve sağanakta durur («Yağmurda kurumaz»). Emeği biten birim yuva bekler, yuva açıldığı anda girer.
## İnce İş usta ister, emek ×1,5, çıktı 'id+'. Sığmayan çıktı outbox'ta bekler. Aşçı toplu yemeği ×1,25 hızla yapar.
## queue: [{recipe, n, fine, night, wm, have, ready}] (wm: süren birimin İD'si). cures: [{recipe, left, fine, paused}] (left: oyun dk).
##   var ws := Workshop.new({"station": "wood_shop"})
##   ws.order("rc_uuk_set", 1)
##   var res := ws.tick(60.0, {"crew_w": 3.0, "pool": chest, "lit": "day", "weather": {"type": "clear", "dryK": 1.0}})
##   res     # {done: [{id, n, recipe, fine}], used (İD), wait, night_min, torches}

const F_FINE := 1
const F_NIGHT := 2
const F_HAVE := 4
const F_READY := 8
const EPS := 1e-9
const BLOCK_V := 1

var id := ""
var station := ""
var slots := 0
var crew_max := 1.0
## Kayıt ve sürücü için: yerin kimliği ve dünya noktası (çıktı en yakın kaba).
var place := ""
var at := Vector3.ZERO
var queue: Array = []
var cures: Array = []
## Kabın almadığı çıktı: [{id, n}]; yer açılınca konur.
var outbox: Array = []
## Ekip: ağırlık (W) ve Usta derecesindeki roller (Kâhya ya da sürücü yazar).
var crew := {"W": 0.0, "roles": []}
## Son tick'in bekleme nedeni ({reason, missing?, role?} ya da boş) ve yuvanın yağmur durağı ("rain" ya da "").
var wait: Dictionary = {}
var cure_wait := ""
## Yanan meşalenin kalan oyun dakikası.
var torch_left := 0.0


## opts: station (şart), id, slots, crew_max, place, at.
func _init(opts := {}) -> void:
	station = str(opts.get("station", ""))
	var st := Craft.station(station)
	if st.is_empty():
		push_error("[craft] bilinmeyen tezgâh: %s" % station)
	id = str(opts.get("id", station))
	slots = int(opts.get("slots", st.get("slots", 0)))
	crew_max = float(opts.get("crew_max", st.get("crewMax", 1)))
	place = str(opts.get("place", ""))
	at = opts.get("at", Vector3.ZERO)


## Bu tezgâhın sırasına girer mi: işçi emeği olan, bu tezgâhın ya da el işi (NPC el işi, §6.7 kural 7) ya da Kazan Ocağı'nda ocak işi.
func accepts(recipe_id: String) -> bool:
	var r := Craft.recipe(recipe_id)
	if r.is_empty() or not Craft.is_queued(r):
		return false
	var s := str(r.get("station", ""))
	return s == station or s == "hand" or (s == "hearth" and station == "kitchen")


## «Yap / Make» → kuyruktaki sıra ya da -1. night: gece vardiyası (pencere dışında da çalışır; hanenin Gönül'ü −0,2, meşale).
func order(recipe_id: String, n := 1, opts := {}) -> int:
	if not accepts(recipe_id) or n < 1:
		return -1
	var fine := bool(opts.get("fine", false))
	if fine and not Craft.recipe(recipe_id).get("fine") is Dictionary:
		return -1
	queue.append({"recipe": recipe_id, "n": n, "fine": fine, "night": bool(opts.get("night", false)), "wm": 0.0, "have": false, "ready": false})
	return queue.size() - 1


## Sipariş kalkar; ayrılmış girdi (süren birim) iade listesi olarak döner, çağıran ambara geri koyar.
func cancel(i: int) -> Array:
	if i < 0 or i >= queue.size():
		return []
	var o: Dictionary = queue[i]
	queue.remove_at(i)
	return Craft.inputs_of(o["recipe"], o["fine"]) if o["have"] and not o["ready"] else []


## Bir birimin emeği (İD).
func _need(o: Dictionary) -> float:
	return float(Craft.recipe(o["recipe"]).get("wh", 0.0)) * 60.0 * (Craft.fine_k() if o["fine"] else 1.0)


## game_min oyun dakikası işler. opts: crew_w (verilmezse crew.W; el sınırıyla kırpılır), lit ("lit" | "day" | "dim" | "dark" ya da bool),
## weather ({type, dryK} ya da tür kimliği), pool (havuz), day (bozulan çıktının günü), window (üretim penceresi açık; dışında yalnız gece
## vardiyası), dark (güneş −6°'nin altında: ışıklı atölye meşale yakar), roles (verilmezse crew.roles).
## → {done: [{id, n, recipe, fine}], used (İD), wait, night_min, torches}.
func tick(game_min: float, opts := {}) -> Dictionary:
	var res := {"done": [], "used": 0.0, "wait": {}, "night_min": 0.0, "torches": 0}
	if not (game_min > 0.0):
		return res
	var st := Craft.station(station)
	var crew_roles: Variant = opts.get("roles", crew.get("roles", []))
	var pool: Variant = opts.get("pool")
	var day: Variant = opts.get("day")
	var window := bool(opts.get("window", true))
	_flush(pool, day)
	var crew_w: Variant = opts.get("crew_w")
	var w := minf(maxf(0.0, float(crew_w) if crew_w != null else float(crew.get("W", 0.0))), crew_max)
	var lit: Variant = opts.get("lit", "day")
	var dark := bool(opts.get("dark", false))
	var cls := str(lit) if lit is String or lit is StringName else ("lit" if lit else ("dark" if dark else "day"))
	var weather: Variant = opts.get("weather")
	var type_id: Variant = weather if weather is String or weather is StringName else ((weather as Dictionary).get("type") if weather is Dictionary else null)
	var wx_k := 1.0
	if st.get("open", false):
		wx_k = float(Labour.weather_k({"felt": true} if station == "felt_yard" else {}, type_id if type_id != null else "clear")["k"])
	# Bekleme yuvası el istemez, uykuda ve atlamada da akar; açık hava yuvası havanın kurutma çarpanıyla, yağışta durur.
	var fx_dry: float = float((weather as Dictionary)["dryK"]) if weather is Dictionary and Craft._num((weather as Dictionary).get("dryK")) else Craft.dry_by_type(type_id)
	var dry_k := maxf(0.0, fx_dry) if st.get("dry", false) else 1.0
	for cv: Dictionary in cures:
		cv["paused"] = dry_k <= 0.0
	# Emek ve yuvalar aynı adımla ilerler: adım bir birimin emeği, meşalenin sönmesi ya da bir yuvanın açılmasıyla biter; açılan yuvaya emeği
	# bitmiş birim o anda girer.
	var m := game_min
	var guard := 0
	while m > EPS and guard < 8192:
		guard += 1
		var cure_span := _cure_span(dry_k)
		var o: Dictionary = _next(window, pool, crew_roles, res)
		var r := Craft.recipe(o["recipe"]) if not o.is_empty() else {}
		var cap_w := 0.0
		if not r.is_empty():
			cap_w = w if str(r.get("station", "")) == station else minf(w, float(Craft.station(str(r.get("station", ""))).get("crewMax", 1)))
		var rate := 0.0
		var torch_span := INF
		if not o.is_empty() and cap_w <= 0.0:
			if (res["wait"] as Dictionary).is_empty():
				res["wait"] = {"reason": "crew"}
		elif not o.is_empty():
			# Işıklı atölye karanlıkta meşale yakar; meşale yoksa ışıksız sayılır.
			var night := cls
			if cls == "lit" and dark:
				if torch_left <= EPS and Craft.pool_take(pool, "torch", 1) > 0:
					torch_left += Craft.torch_dark_min()
					res["torches"] = int(res["torches"]) + 1
				if torch_left > EPS:
					torch_span = torch_left
				else:
					night = "dark"
			var cook: Dictionary = Craft.role("cr_cook")
			var speed := float(cook.get("speedK", 1.0)) if Craft.has_role(crew_roles, "cr_cook") and (cook.get("speedFor", []) as Array).has(o["recipe"]) else 1.0
			rate = Labour.station_rate(cap_w, night, wx_k, speed)
			if rate <= 0.0 and (res["wait"] as Dictionary).is_empty():
				res["wait"] = {"reason": "weather"}
		var need := _need(o) if rate > 0.0 else 0.0
		var labour_span := maxf(0.0, need - float(o["wm"])) / rate if rate > 0.0 else INF
		var span := minf(minf(m, labour_span), minf(torch_span, cure_span))
		if span == INF:
			break
		if rate > 0.0:
			o["wm"] = float(o["wm"]) + span * rate
			res["used"] = float(res["used"]) + span * rate
			if torch_span != INF:
				torch_left = maxf(0.0, torch_left - span)
			if not window:
				res["night_min"] = float(res["night_min"]) + span
		m -= span
		_advance_cures(span, dry_k, pool, day, res)
		if rate > 0.0 and float(o["wm"]) >= need - EPS:
			_finish_labour(o, pool, day, res)
	wait = res["wait"]
	cure_wait = "rain" if st.get("dry", false) and dry_k <= 0.0 and not cures.is_empty() else ""
	return res


## En erken açılacak yuvanın süresi (oyun dk); yuva yoksa ya da kurumuyorsa INF.
func _cure_span(dry_k: float) -> float:
	if not (dry_k > 0.0):
		return INF
	var best := INF
	for cv: Dictionary in cures:
		best = minf(best, maxf(0.0, float(cv["left"])) / dry_k)
	return best


func _advance_cures(span: float, dry_k: float, pool: Variant, day: Variant, res: Dictionary) -> void:
	var i := 0
	while i < cures.size():
		var cv: Dictionary = cures[i]
		cv["left"] = float(cv["left"]) - span * dry_k
		if float(cv["left"]) <= EPS:
			cures.remove_at(i)
			_output(cv["recipe"], cv["fine"], pool, day, res)
		else:
			i += 1


## Sıradaki işlenebilir sipariş (boş: yok); işlenemeyenin nedeni res.wait'e (ilk neden) yazılır. Emeği bitmiş ve yuvası açılan birim burada
## yuvaya geçer.
func _next(window: bool, pool: Variant, p_roles: Variant, res: Dictionary) -> Dictionary:
	var i := 0
	while i < queue.size():
		var o: Dictionary = queue[i]
		var r := Craft.recipe(o["recipe"])
		if o["ready"]:
			if cures.size() < slots:
				_to_cure(o, r)
				i = 0
				continue
			if (res["wait"] as Dictionary).is_empty():
				res["wait"] = {"reason": "slot"}
			i += 1
			continue
		var why := _blocked(o, r, window, pool, p_roles)
		if not why.is_empty():
			if (res["wait"] as Dictionary).is_empty():
				res["wait"] = why
			i += 1
			continue
		return o
	return {}


## İşlenemezlik nedeni ya da boş; girdi siparişin birimi başlarken havuzdan ayrılır (economy.md §6.7 kural 3).
func _blocked(o: Dictionary, r: Dictionary, window: bool, pool: Variant, p_roles: Variant) -> Dictionary:
	if not window and not o["night"]:
		return {"reason": "rest"}
	if str(r.get("who", "")) == "master" and not Craft.has_role(p_roles, r.get("role")):
		return {"reason": "master", "role": r.get("role")}
	if o["fine"] and not Craft.has_role(p_roles, Craft.fine_role(r)):
		return {"reason": "master", "role": Craft.fine_role(r)}
	if o["have"]:
		return {}
	var inputs := Craft.inputs_of(r, o["fine"])
	var missing: Array = []
	for e: Dictionary in inputs:
		var have := Craft.pool_count(pool, str(e["id"]))
		if have < int(e["n"]):
			missing.append({"id": e["id"], "n": int(e["n"]) - have})
	if not missing.is_empty():
		return {"reason": "material", "missing": missing}
	for e: Dictionary in inputs:
		Craft.pool_take(pool, str(e["id"]), int(e["n"]))
	o["have"] = true
	return {}


func _finish_labour(o: Dictionary, pool: Variant, day: Variant, res: Dictionary) -> void:
	var r := Craft.recipe(o["recipe"])
	if float(r.get("cure", 0.0)) > 0.0:
		if cures.size() < slots:
			_to_cure(o, r)
		else:
			o["ready"] = true
		return
	_output(o["recipe"], o["fine"], pool, day, res)
	_unit_done(o)


func _to_cure(o: Dictionary, r: Dictionary) -> void:
	cures.append({"recipe": o["recipe"], "left": float(r.get("cure", 0.0)) * 60.0, "fine": o["fine"], "paused": false})
	_unit_done(o)


func _unit_done(o: Dictionary) -> void:
	o["n"] = int(o["n"]) - 1
	o["wm"] = 0.0
	o["have"] = false
	o["ready"] = false
	if int(o["n"]) <= 0:
		queue.erase(o)


## Çıktı havuza; '@ration' defter payıdır, yalnız sonuçta döner. Sığmayan çıktı outbox'ta bekler.
func _output(recipe_id: String, fine: bool, pool: Variant, day: Variant, res: Dictionary) -> void:
	var outs: Dictionary = Craft.recipe(recipe_id).get("out", {})
	for item: String in outs:
		var ledger := item.begins_with("@")
		var out_id := "%s+" % item if fine and not ledger else item
		var q := int(outs[item])
		(res["done"] as Array).append({"id": out_id, "n": q, "recipe": recipe_id, "fine": fine})
		if ledger:
			continue
		var added := Craft.pool_put(pool, out_id, q, day)
		if added < q:
			outbox.append({"id": out_id, "n": q - added})


func _flush(pool: Variant, day: Variant) -> void:
	var i := 0
	while i < outbox.size():
		var e: Dictionary = outbox[i]
		e["n"] = int(e["n"]) - Craft.pool_put(pool, str(e["id"]), int(e["n"]), day)
		if int(e["n"]) <= 0:
			outbox.remove_at(i)
		else:
			i += 1


## Süren işin kalan oyun dakikası bu eller ve ışıkla (yuvalar dahil; malzeme ve usta beklemesi sayılmaz). Kuyruk boşsa 0.
func remaining_minutes(w := -1.0, night := "day", wx_k := 1.0) -> float:
	var hands := minf(crew_max, w if w >= 0.0 else float(crew.get("W", 0.0)))
	var rate := Labour.station_rate(hands, night, wx_k)
	var total := 0.0
	for o: Dictionary in queue:
		var need := _need(o)
		var per := need / rate if rate > 0.0 else INF
		total += maxf(0.0, need - float(o["wm"])) / rate if rate > 0.0 else INF
		total += per * maxi(0, int(o["n"]) - 1)
		var cure := float(Craft.recipe(o["recipe"]).get("cure", 0.0)) * 60.0
		if cure > 0.0:
			total += cure
	var longest := 0.0
	for cv: Dictionary in cures:
		longest = maxf(longest, float(cv["left"]))
	return maxf(total, longest)


## Defter ve arayüz için özet.
func status() -> Dictionary:
	var q: Array = []
	for o: Dictionary in queue:
		q.append({"recipe": o["recipe"], "n": o["n"], "fine": o["fine"], "night": o["night"], "progress": float(o["wm"]) / maxf(EPS, _need(o)),
			"ready": o["ready"], "have": o["have"]})
	var c: Array = []
	for cv: Dictionary in cures:
		c.append({"recipe": cv["recipe"], "hours": float(cv["left"]) / 60.0, "paused": cv["paused"], "fine": cv["fine"]})
	return {"queue": q, "cures": c, "wait": wait, "cure_wait": cure_wait, "outbox": outbox.duplicate(true)}


static func _round2(v: float) -> float:
	return roundf(v * 100.0) / 100.0


## Kayıt (settlement.workshops; d2/economy.md §16): q [tarif, adet, süren İS, bayrak], cures [tarif, kalan sa, İnce İş?], torch, out.
func to_dict() -> Dictionary:
	var q: Array = []
	for o: Dictionary in queue:
		var f := (F_FINE if o["fine"] else 0) | (F_NIGHT if o["night"] else 0) | (F_HAVE if o["have"] else 0) | (F_READY if o["ready"] else 0)
		q.append([o["recipe"], int(o["n"]), Workshop._round2(float(o["wm"]) / 60.0), f])
	var c: Array = []
	for cv: Dictionary in cures:
		c.append([cv["recipe"], Workshop._round2(float(cv["left"]) / 60.0), 1] if cv["fine"] else [cv["recipe"], Workshop._round2(float(cv["left"]) / 60.0)])
	var out := {"v": BLOCK_V, "station": station, "q": q, "cures": c}
	if torch_left > 0.0:
		out["torch"] = Workshop._round2(torch_left)
	if not outbox.is_empty():
		var ob: Array = []
		for e: Dictionary in outbox:
			ob.append([e["id"], int(e["n"])])
		out["out"] = ob
	return out


## Bilinmeyen tarif atılır: tablo değişse de kayıt açılır. Döner: kendisi.
func from_dict(o: Variant) -> Workshop:
	var d: Dictionary = o if o is Dictionary else {}
	queue = []
	for e: Variant in (d.get("q") if d.get("q") is Array else []):
		if not e is Array or (e as Array).size() < 2 or not Craft.has_recipe(str(e[0])) or not Craft._num(e[1]) or float(e[1]) < 1.0:
			continue
		var f := int(e[3]) if (e as Array).size() > 3 and Craft._num(e[3]) else 0
		var wh := float(e[2]) if (e as Array).size() > 2 and Craft._num(e[2]) else 0.0
		queue.append({"recipe": str(e[0]), "n": floori(float(e[1])), "wm": maxf(0.0, wh) * 60.0, "fine": (f & F_FINE) != 0,
			"night": (f & F_NIGHT) != 0, "have": (f & F_HAVE) != 0, "ready": (f & F_READY) != 0})
	cures = []
	for e: Variant in (d.get("cures") if d.get("cures") is Array else []):
		if not e is Array or (e as Array).is_empty() or not Craft.has_recipe(str(e[0])):
			continue
		var h := float(e[1]) if (e as Array).size() > 1 and Craft._num(e[1]) else 0.0
		cures.append({"recipe": str(e[0]), "left": maxf(0.0, h) * 60.0, "fine": (e as Array).size() > 2 and bool(e[2]), "paused": false})
	torch_left = maxf(0.0, float(d.get("torch", 0.0))) if Craft._num(d.get("torch")) else 0.0
	outbox = []
	for e: Variant in (d.get("out") if d.get("out") is Array else []):
		if e is Array and (e as Array).size() > 1 and Craft._num(e[1]) and int(e[1]) > 0:
			outbox.append({"id": str(e[0]), "n": int(e[1])})
	wait = {}
	cure_wait = ""
	return self
