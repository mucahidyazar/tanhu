class_name Labour
extends RefCounted
## Emek yasası (K21, K50; structures.md §2.4, d2/labour-model.json v3): saf ve durumsuz hesaplar (godot.md §3 «Emek ve aşamalı yapı»).
##
## Birim iş dakikasıdır (İD): bir işçinin bir oyun dakikasında yaptığı iş; 60 İD = 1 İS, 1.440 İD = 1 İG = tek işçiyle 60 gerçek dk.
## İki eğri vardır:
##   inşaat eğrisi (K50) kurma, söküm, onarım ve şantiyede ham malın emeği:  k(W) = W (W < 1), (4/3)^(min(W, 8) − 1) (W ≥ 1);
##     bir yapının süresi T(n) = taban × 0,75^(min(n, 8) − 1) gerçek dk (taban = tek el İD / 24). Katsayı yapının bütün adımlarında
##     aynıdır (adım payı ekip büyüyünce değişmez), bu yüzden Hane Yurdu 1–8 elle 60 / 45 / 33,75 / 25,3 / 19,0 / 14,2 / 10,7 / 8,0 dk.
##   tezgâh eğrisi (K21, değişmedi) tezgâh ve el tarifi:  eff(W) = min(W, 10 · (1 − 0,9^W)).
## W, yapının el tavanına (crewMax: Küçük Yurt 6, Hane Yurdu 8, Otağ 12) dek en ağır üyelerin ağırlık toplamıdır: usta, el ve Mete 1,
## çırak 0,75, yaşlı ve Çocuk 0,5, adlı büyük usta ≤1,25 (karışık ekipte n ağırlık toplamıdır, K50); Çocuk child: false adımında
## sayılmaz. Adımın oranı (İD / oyun dk) = k(W) × K_usta × K_beceri × K_gece × K_hava × K_tok × hız.
## Sayılar data/structures/labour.json (yasa, hava tablosu) ve data/structures/structures.json'dadır (yapıların adımları); ikisi de
## d2/labour-model.json v3'ün kopyasıdır. Şantiyenin durumu (SiteState) bu sınıfı okur; şantiyeyi yalnız o yazar (godot.md §1 madde 9).
##   Labour.k_build(3.0)                                 # 1,7778
##   Labour.build_minutes("yurt", 3.0)                   # 33,75 gerçek dk
##   Labour.crew_minutes("yurt", ekip, {"night": "day"}) # oyun dk (adım adım; Çocuk eşikte ve ocakta sayılmaz)
##   Labour.eff(3.0)                                     # 2,71 (tezgâh)

const LAW_PATH := "res://data/structures/labour.json"
const STRUCTURES_PATH := "res://data/structures/structures.json"
const EPS := 1e-9

## Okunan veri: yasa ve yapılar (bir kez okunur; testler reset_cache ile yeniler).
static var _law: Dictionary = {}
static var _structures: Dictionary = {}
## Hava tepkisi önbelleği: tür → 8 sonuç (felt | tall | lattice bitleri); dönen sözlük paylaşılır, değiştirilmez.
static var _wx_cache: Dictionary = {}
## Ekip seçiminin ağırlık tamponu (azalan sırayla; çağrılar arasında yeniden kullanılır, kare başına ayırma yok).
static var _ws := PackedFloat64Array()


# ---------- Veri ----------

## Yasanın tamamı (data/structures/labour.json).
static func data() -> Dictionary:
	if _law.is_empty():
		_law = Labour._read(LAW_PATH)
	return _law


## Yasa bölümü («law»).
static func law() -> Dictionary:
	return data().get("law", {})


## Yapı tabloları (data/structures/structures.json: sizes, defs, settlement).
static func structures() -> Dictionary:
	if _structures.is_empty():
		_structures = Labour._read(STRUCTURES_PATH)
	return _structures


static func reset_cache() -> void:
	_law = {}
	_structures = {}
	_wx_cache = {}


static func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	push_error("Labour: %s okunamadı" % path)
	return {}


static func _num(d: Dictionary, key: String, fallback: float) -> float:
	var v: Variant = d.get(key, fallback)
	return float(v) if v is float or v is int else fallback


## Bir oyun dakikası kaç gerçek saniye (2,5) ve bir günde kaç oyun dakikası (1.440).
static func real_s_per_min() -> float:
	return Labour._num(law(), "realSecPerGameMin", 2.5)


static func day_min() -> float:
	return Labour._num(law(), "dayGameMin", 1440.0)


## Oyun dakikasından gerçek dakikaya.
static func real_minutes(game_min: float) -> float:
	return game_min * real_s_per_min() / 60.0


# ---------- Eğriler ----------

## İnşaat eğrisinin katsayısı (K50): W < 1 doğrusal, W ≥ 1'de her yeni el süreyi %25 kısaltır, katsayı coef_max'ta (8) durur.
static func k_build(w: float, coef_max: float = -1.0) -> float:
	if not (w > 0.0):
		return 0.0
	if w < 1.0:
		return w
	var b: Dictionary = law().get("build", {})
	var cm := coef_max if coef_max > 0.0 else Labour._num(b, "coefMax", 8.0)
	return 1.0 / pow(Labour._num(b, "base", 0.75), minf(w, cm) - 1.0)


## T(n) = taban × 0,75^(min(n, 8) − 1): yapının n ellik (ağırlık toplamı) ekiple süresi; taban tek el süresidir (aynı birimde döner).
static func t_of(base: float, n: float, coef_max: float = -1.0) -> float:
	var k := Labour.k_build(n, coef_max)
	return base / k if k > 0.0 else INF


## Tezgâh eğrisi (K21; tezgâh ve el tarifi): W ≤ 1'de doğrusal, sonra 10 · (1 − 0,9^W).
static func eff(w: float) -> float:
	if not (w > 0.0):
		return 0.0
	var b := Labour._num(law(), "effBase", 0.9)
	return minf(w, (1.0 - pow(b, w)) / (1.0 - b))


## Şantiyenin bir günde işlediği emek (İS): k(W) × 24 (gece emri, ışıklı; el başına 24 İS elin zamanıdır, ilerleme değildir).
static func site_day(w: float, coef_max: float = -1.0) -> float:
	return Labour.k_build(w, coef_max) * Labour._num(law().get("dayCapacity", {}), "build", 24.0)


## El başına verim k(n) / n: yurtta 8 el 0,94, 3–4 el 0,59 (K80).
static func per_hand(n: float, coef_max: float = -1.0) -> float:
	return Labour.k_build(n, coef_max) / n if n > 0.0 else 0.0


# ---------- Ekip ----------

## Üyenin ağırlığı: verilen w ya da rolünün ağırlığı (bilinmeyen rol 1); 0 ile adlı büyük usta tavanı (1,25) arasında.
static func weight_of(m: Dictionary) -> float:
	var roles: Dictionary = law().get("roles", {})
	var w := 1.0
	var given: Variant = m.get("w")
	if (given is float or given is int) and is_finite(float(given)):
		w = float(given)
	else:
		var r: Variant = roles.get(str(m.get("role", "")))
		if r is float or r is int:
			w = float(r)
	return minf(maxf(w, 0.0), Labour._num(roles, "namedMasterMax", 1.25))


## Ekonominin zanaatçı rolü → emek zanaatı (economy.md §6.8): cr_carpenter, cr_cartwright, cr_bowyer → wood; cr_smith, cr_earth →
## earth; yazılmayan cr_ rolü home; zanaatın kendisi (home, wood, earth) olduğu gibi döner.
static func craft_of(c: String) -> String:
	var table: Dictionary = law().get("craftOf", {})
	if table.has(c):
		return str(table[c])
	return "home" if c.begins_with("cr_") else c


static func _has_craft(m: Dictionary, craft: String) -> bool:
	var list: Variant = m.get("crafts")
	if not list is Array:
		return false
	for c: Variant in list:
		if Labour.craft_of(str(c)) == craft:
			return true
	return false


static func _master_in(m: Dictionary, craft: String) -> bool:
	var rule := str((law().get("roleUsta", {}) as Dictionary).get(str(m.get("role", "")), "home"))
	if rule == "none":
		return false
	if craft == "home":
		return true
	return rule == "own" and Labour._has_craft(m, craft)


## Üye yapının zanaatında usta sayılır mı: her yetişkin home ustasıdır, usta ve yaşlı kendi zanaatında; craft dizi ise biri yeter.
static func is_master(m: Dictionary, craft: Variant = "home") -> bool:
	if craft is Array:
		for c: Variant in craft:
			if Labour._master_in(m, str(c)):
				return true
		return false
	return Labour._master_in(m, str(craft))


## Ham payın ustası (rawRole: rol ya da rol dizisi, biri yeter); çırak ve Çocuk usta işi yapamaz.
static func _holds_role(m: Dictionary, role: Variant) -> bool:
	var role_id := str(m.get("role", ""))
	var crafts: Variant = m.get("crafts")
	if role_id == "apprentice" or role_id == "child" or not crafts is Array:
		return false
	if role is Array:
		for r: Variant in role:
			if (crafts as Array).has(r):
				return true
		return false
	return (crafts as Array).has(role)


## Ekip: el sınırına (step.max, yoksa siteHeadMax) dek en ağır üyeler W'yi ve baş sayısını verir; önder, usta, Mete ve ham payın
## ustası adıma girebilen bütün ekipten okunur (step.child false ise Çocuk sayılmaz). craft verilmezse step.craft, o da yoksa home.
## → {heads, W, lead, usta, mete, raw}; out verilirse ona yazılır (kare başına ayırma yok).
static func crew_on(step: Dictionary, members: Array, craft: Variant = null, out: Dictionary = {}) -> Dictionary:
	var c: Variant = craft if craft != null else step.get("craft", "home")
	var role: Variant = step.get("rawRole")
	var no_child: bool = step.get("child", true) == false
	var lead_w := Labour._num(law(), "leadMinWeight", 0.75)
	var lead := false
	var usta := false
	var mete := false
	var raw := role == null
	var n := 0
	if _ws.size() < members.size():
		_ws.resize(members.size())
	for item: Variant in members:
		if not item is Dictionary:
			continue
		var m: Dictionary = item
		if no_child and str(m.get("role", "")) == "child":
			continue
		var w := Labour.weight_of(m)
		if not (w > 0.0):
			continue
		var master := Labour.is_master(m, c)
		if master:
			usta = true
		if master or w >= lead_w:
			lead = true
		if str(m.get("role", "")) == "mete":
			mete = true
		if not raw and Labour._holds_role(m, role):
			raw = true
		var j := n
		n += 1
		while j > 0 and _ws[j - 1] < w:
			_ws[j] = _ws[j - 1]
			j -= 1
		_ws[j] = w
	var limit_v: Variant = step.get("max")
	var limit := float(limit_v) if (limit_v is float or limit_v is int) and is_finite(float(limit_v)) else Labour._num(law(), "siteHeadMax", 8.0)
	var heads := minf(float(n), maxf(0.0, limit))
	var total := 0.0
	var i := 0
	while float(i) < heads:
		total += _ws[i]
		i += 1
	out["heads"] = heads
	out["W"] = total
	out["lead"] = lead
	out["usta"] = usta
	out["mete"] = mete
	out["raw"] = raw
	return out


# ---------- Çarpanlar ----------

## K_gece: daylight.nightClass sınıfı (lit ve day 1, dim 0,7, dark 0,4); bilinmeyen sınıf gündüzdür.
static func night_k(cls: Variant) -> float:
	var classes: Dictionary = (law().get("night", {}) as Dictionary).get("classes", {})
	var key := str(cls) if cls is String or cls is StringName else "day"
	return Labour._num(classes, key if classes.has(key) else "day", 1.0)


## K_tok: bağlı defterin Yiyecek çizgisi (%) ≥35 → 1, <35 → 0,85, <15 → 0,7; fed sayıysa iğnedir (Kışlak 1).
static func fed_k(food: Variant, fed: Variant = null) -> float:
	if fed is float or fed is int:
		return float(fed)
	if not (food is float or food is int) or not is_finite(float(food)):
		return 1.0
	var f: Dictionary = law().get("fed", {})
	var v := float(food)
	if v < Labour._num(f, "hungryBelow", 15.0):
		return Labour._num(f, "hungry", 0.7)
	if v < Labour._num(f, "lowBelow", 35.0):
		return Labour._num(f, "low", 0.85)
	return Labour._num(f, "ok", 1.0)


## K_hava ve durak (d2/core.md §2.8): adımın bayrakları (felt keçe, tall uzun iş, lattice kerege) ve hava türü →
## {k, hold: null | "felt" | "tall" | "all", reason: null | "storm" | "felt_rain" | "felt_wind" | "lightning"}. Yazılmayan tür açık
## havadır. Durak "all" ustaları sığınağa gönderir; "felt" ve "tall" yalnız o adımı bekletir. Dönen sözlük paylaşılır, değiştirme.
static func weather_k(step: Dictionary, type_id: Variant = "clear") -> Dictionary:
	var table: Dictionary = data().get("weather", {})
	# Tablonun tür olmayan anahtarı (resumeAfterGameHours) tür sayılmaz.
	var id := str(type_id) if (type_id is String or type_id is StringName) and table.get(str(type_id)) is Dictionary else "clear"
	var bits := (1 if step.get("felt", false) else 0) | (2 if step.get("tall", false) else 0) | (4 if step.get("lattice", false) else 0)
	if not _wx_cache.has(id):
		var row: Array = []
		row.resize(8)
		_wx_cache[id] = row
	var cached: Array = _wx_cache[id]
	if cached[bits] == null:
		cached[bits] = Labour._weather_of(table[id], id, bits)
	return cached[bits]


static func _weather_of(r: Dictionary, id: String, bits: int) -> Dictionary:
	var holds: Array = r.get("hold", [])
	if holds.has("all"):
		return {"k": 0.0, "hold": "all", "reason": "storm"}
	if bits & 1 and holds.has("felt"):
		return {"k": 0.0, "hold": "felt", "reason": "felt_wind" if id == "gale" else "felt_rain"}
	if bits & 2 and holds.has("tall"):
		return {"k": 0.0, "hold": "tall", "reason": "lightning"}
	var k := float(r.get("k", 1.0))
	if bits & 1 and r.has("felt"):
		k = float(r["felt"])
	elif bits & 4 and r.has("lattice"):
		k = float(r["lattice"])
	return {"k": k, "hold": null, "reason": null}


## K_beceri: Mete ekipteyken kurulum ×1/buildTime (quick_raise), onarım ×1/repairTime (repair); Progression.mods() değerleri.
static func skill_k(crew: Dictionary, mods: Variant, kind: String) -> float:
	if not crew.get("mete", false) or not mods is Dictionary:
		return 1.0
	var v: Variant = null
	if kind == "build":
		v = (mods as Dictionary).get("buildTime")
	elif kind == "repair" or kind == "stitch":
		v = (mods as Dictionary).get("repairTime")
	return 1.0 / float(v) if (v is float or v is int) and float(v) > 0.0 else 1.0


static func _gated(gates: Variant, step: Dictionary) -> bool:
	if gates == null or step.is_empty():
		return false
	var id: Variant = step.get("id")
	if gates is Array or gates is PackedStringArray:
		return id in gates
	if gates is Dictionary:
		return (gates as Dictionary).get(id, false) == true
	return false


## Adımın oranı (İD / oyun dk), inşaat eğrisiyle (K50): k(W) × K_usta × K_beceri × K_gece × K_hava × K_tok × hız.
## env: {kind ("build" | "dismantle" | "repair" | "stitch"), night, weather, food, fed, speed, mods, raw, hold, gates, coef_max}.
## Önder kuralı: ağırlığı ≥0,75 ya da usta sayılan yoksa 0 (yırtık dikmek hariç); usta kuralı (×0,7) kurulum ve sökümdedir.
## info verilirse {reason, hold, why, k} yazılır: reason durduran neden (env.hold, "storm", "weather", "master", "crew", "story") ya da
## işlerken "dark" (ay ışığı ve karanlık) | null.
static func build_rate(step: Dictionary, crew: Dictionary, env: Dictionary = {}, info: Variant = null) -> float:
	var kind := str(env.get("kind", "build"))
	var wx := Labour.weather_k(step, env.get("weather"))
	var reason: Variant = null
	var rate := 0.0
	var hold: Variant = env.get("hold")
	if hold != null:
		reason = hold
	elif wx["hold"] != null or not (float(wx["k"]) > 0.0):
		reason = "storm" if wx["hold"] == "all" else "weather"
	elif env.get("raw", false) and float(step.get("rawWork", 0.0)) > 0.0 and not crew.get("raw", true):
		reason = "master"
	elif not (float(crew.get("heads", 0.0)) > 0.0) or (not crew.get("lead", false) and kind != "stitch"):
		reason = "crew"
	elif Labour._gated(env.get("gates"), step):
		reason = "story"
	else:
		var k_usta := 1.0 if crew.get("usta", false) or kind == "repair" or kind == "stitch" else Labour._num(law(), "noUstaK", 0.7)
		var k_night := Labour.night_k(env.get("night"))
		var speed_v: Variant = env.get("speed", 1.0)
		var speed := float(speed_v) if (speed_v is float or speed_v is int) and float(speed_v) >= 0.0 else 1.0
		var coef_max := float(env.get("coef_max", -1.0))
		rate = Labour.k_build(float(crew.get("W", 0.0)), coef_max) * k_usta * Labour.skill_k(crew, env.get("mods"), kind) * k_night \
			* float(wx["k"]) * Labour.fed_k(env.get("food"), env.get("fed")) * speed
		if k_night < 1.0:
			reason = "dark"
	if info is Dictionary:
		info["reason"] = reason
		info["hold"] = wx["hold"]
		info["why"] = wx["reason"]
		info["k"] = wx["k"]
	return rate


## Tezgâhın oranı (İD / oyun dk; economy.md §6.7): eff(W) × K_gece × K_hava × hız. Tezgâhın kuyruğu ve meşalesi Workshop'undur.
static func station_rate(w: float, night: Variant = "day", weather_k_value: float = 1.0, speed: float = 1.0) -> float:
	return Labour.eff(w) * Labour.night_k(night) * weather_k_value * speed


# ---------- Yapılar ----------

## Yapının adımları (kurulum sırasıyla): defs'in adımları ya da settlement satırının türettikleri (same türünün sırası ve bayrakları;
## work dizisi payı ezer, drop çıkar, add sona eklenir, stepSlots görünen eli ezer). Bilinmeyen tür boş. Dönen dizi kopyadır.
static func steps_of(kind: String) -> Array:
	var s := structures()
	var defs: Dictionary = s.get("defs", {})
	if defs.has(kind) and (defs[kind] as Dictionary).has("steps"):
		return ((defs[kind] as Dictionary)["steps"] as Array).duplicate(true)
	var row: Variant = (s.get("settlement", {}) as Dictionary).get(kind)
	if not row is Dictionary:
		return []
	var r: Dictionary = row
	var base: Array = []
	if r.has("same"):
		base = Labour.steps_of(str(r["same"]))
	var drop: Array = r.get("drop", [])
	var src: Array = base.filter(func(st: Dictionary) -> bool: return not drop.has(st.get("id")))
	var work: Variant = r.get("work")
	var n := (work as Array).size() if work is Array else src.size()
	var out: Array = []
	for i in n:
		var st: Dictionary = (src[i] as Dictionary).duplicate(true) if i < src.size() else {"id": "s%d" % i, "stage": i, "work": 0.0, "slots": 1}
		if work is Array:
			st["work"] = float((work as Array)[i])
		var slots: Dictionary = r.get("stepSlots", {})
		var key_i := str(i)
		if slots.has(key_i):
			st["slots"] = slots[key_i]
		elif slots.has(str(st.get("id", ""))):
			st["slots"] = slots[str(st["id"])]
		out.append(st)
	if r.get("add") is Dictionary:
		out.append((r["add"] as Dictionary).duplicate(true))
	return out


## Yapının el tavanı (baş): defs crewMax ya da settlement max; uzunluk başına el alan yapıda (crewPer) üst sınırdır. Yoksa siteHeadMax.
static func crew_max(kind: String) -> float:
	var s := structures()
	var d: Variant = (s.get("defs", {}) as Dictionary).get(kind, (s.get("settlement", {}) as Dictionary).get(kind))
	if d is Dictionary:
		for key: String in ["crewMax", "max"]:
			var v: Variant = (d as Dictionary).get(key)
			if v is float or v is int:
				return float(v)
	return Labour._num(law(), "siteHeadMax", 8.0)


## Katsayının tavanı: satırda coefMax varsa o (Otağ 8), yoksa yasanınki.
static func coef_max_of(kind: String) -> float:
	var s := structures()
	var d: Variant = (s.get("settlement", {}) as Dictionary).get(kind, (s.get("defs", {}) as Dictionary).get(kind))
	if d is Dictionary and ((d as Dictionary).get("coefMax") is float or (d as Dictionary).get("coefMax") is int):
		return float((d as Dictionary)["coefMax"])
	return Labour._num(law().get("build", {}), "coefMax", 8.0)


## Adımın işi (İD): kurulumda payı (köz yığındaysa workIfEmber) ve ham teslimde rawWork; sökümde payın 0,35'i.
## opts: {kind: "build" | "dismantle", raw: bool ya da {adım: true}, ember: bool}.
static func step_work(step: Dictionary, opts: Dictionary = {}) -> float:
	var work := float(step.get("work", 0.0))
	if str(opts.get("kind", "build")) == "dismantle":
		return work * Labour._num(law(), "dismantle", 0.35)
	if opts.get("ember", false) and (step.get("workIfEmber") is float or step.get("workIfEmber") is int):
		work = float(step["workIfEmber"])
	if Labour._is_raw(step, opts.get("raw", false)):
		work += float(step.get("rawWork", 0.0))
	return work


static func _is_raw(step: Dictionary, raw: Variant) -> bool:
	if not (float(step.get("rawWork", 0.0)) > 0.0):
		return false
	if raw is bool:
		return raw
	return raw is Dictionary and (raw as Dictionary).get(step.get("id"), false) == true


## Yapının toplam işi (İD): adımların işinin toplamı (opts step_work'ünkidir).
static func structure_work(kind: String, opts: Dictionary = {}) -> float:
	var total := 0.0
	for st: Dictionary in Labour.steps_of(kind):
		total += Labour.step_work(st, opts)
	return total


## Bütün yapı tek katsayıyla, W ağırlıklı ekiple kaç gerçek dakikada kurulur (sökülür): yapının işi / k(W) / 24 (K50; usta var,
## gündüz, açık hava, Çocuksuz). Hane Yurdu 1–8 el: 60 / 45 / 33,75 / 25,3 / 19,0 / 14,2 / 10,7 / 8,0; Otağ 12 elle 20,0.
static func build_minutes(kind: String, w: float, opts: Dictionary = {}) -> float:
	var k := Labour.k_build(w, Labour.coef_max_of(kind))
	if not (k > 0.0):
		return INF
	return Labour.real_minutes(Labour.structure_work(kind, opts) / k)


## Ekiple adım adım bitiş süresi (oyun dk): her adımda ekip yapının el tavanıyla seçilir (Çocuk child: false adımında sayılmaz, ham
## payın ustası rawRole'dan), oran build_rate'tir. Sökümde adımlar tersten ve payın 0,35'i. Bir adım ilerleyemiyorsa INF.
## env build_rate'inkidir; opts step_work'ünkidir. Saf emektir: öğün, yürüyüş, malzeme ve hava değişimi SiteState'indir.
static func crew_minutes(kind: String, members: Array, env: Dictionary = {}, opts: Dictionary = {}) -> float:
	var steps := Labour.steps_of(kind)
	if steps.is_empty():
		return INF
	var dismantle := str(opts.get("kind", env.get("kind", "build"))) == "dismantle"
	if dismantle:
		steps.reverse()
	var e := env.duplicate()
	e["kind"] = "dismantle" if dismantle else str(env.get("kind", "build"))
	e["coef_max"] = Labour.coef_max_of(kind)
	var cap := Labour.crew_max(kind)
	var craft: Variant = Labour._craft_of_kind(kind)
	var o := opts.duplicate()
	o["kind"] = "dismantle" if dismantle else "build"
	var crew := {}
	var total := 0.0
	for st: Dictionary in steps:
		var pick := {"max": cap, "child": st.get("child", true), "rawRole": st.get("rawRole")}
		Labour.crew_on(pick, members, st.get("craft", craft), crew)
		e["raw"] = Labour._is_raw(st, o.get("raw", false)) and not dismantle
		var rate := Labour.build_rate(st, crew, e)
		if not (rate > 0.0):
			return INF
		total += Labour.step_work(st, o) / rate
	return total


static func _craft_of_kind(kind: String) -> Variant:
	var s := structures()
	var d: Variant = (s.get("defs", {}) as Dictionary).get(kind, (s.get("settlement", {}) as Dictionary).get(kind))
	if d is Dictionary:
		return (d as Dictionary).get("craft", "home")
	return "home"


# ---------- Onarım ----------

## Onarım emeği, İD (structures.md §7; K50: pay tek el emeğidir, emek inşaat eğrisiyle işler): birimin emeği adım payı × birim canı /
## adım canı. "raise" düşmüş birim × 0,8; "patch" canı eksik birim × (1 − can / en çok) × 0,6; yanık birim ikisinde de × 1,25;
## "rerun" birimsiz yeniden koşan adım (y_sirdak, y_ocak) × 0,8; "stitch" bir yırtık 4 İD. opts: {unit_hp, hp, burnt}.
## repair becerisi emeği değil oranı değiştirir (build_rate, kind "repair": Mete ekipteyken ×1/repairTime).
static func repair_work(step: Dictionary, kind: String = "raise", opts: Dictionary = {}) -> float:
	var r: Dictionary = law().get("repair", {})
	if kind == "stitch":
		return Labour._num(r, "tearStitch", 4.0)
	var work := float(step.get("work", 0.0))
	if kind == "rerun":
		return work * Labour._num(r, "rerun", 0.8)
	var unit_hp: Variant = opts.get("unit_hp")
	var step_hp := float(step.get("hp", 0.0))
	var max_hp := float(unit_hp) if unit_hp != null else step_hp
	var unit := work * float(unit_hp) / step_hp if step_hp > 0.0 and unit_hp != null else work
	var burn := Labour._num(r, "burnt", 1.25) if opts.get("burnt", false) else 1.0
	if kind == "patch":
		var left := clampf(float(opts.get("hp", 0.0)) / max_hp, 0.0, 1.0) if max_hp > 0.0 else 0.0
		return unit * (1.0 - left) * Labour._num(r, "patch", 0.6) * burn
	return unit * Labour._num(r, "raise", 0.8) * burn


# ---------- Taşıma ----------

static func _is_cart(c: Variant) -> bool:
	return (c is String and c == "cart") or (c is Dictionary and (c as Dictionary).get("cart", false) == true)


## Seferin yük tavanı: yetişkin 20, çırak 14, Çocuk 6 Yük, keçe araba 60; sayı ya da {cap} verilirse odur (Mete loadMax; carry_pack +8).
static func haul_cap(carrier: Variant = "adult") -> float:
	var h: Dictionary = law().get("haul", {})
	if carrier is float or carrier is int:
		return float(carrier)
	if Labour._is_cart(carrier):
		var felt := Labour._num(h.get("cart", {}), "capFelt", 60.0)
		return Labour._num(carrier, "cap", felt) if carrier is Dictionary else felt
	var caps: Dictionary = h.get("cap", {})
	if carrier is Dictionary:
		return Labour._num(carrier, "cap", Labour._num(caps, "adult", 20.0))
	match str(carrier):
		"apprentice":
			return Labour._num(caps, "apprentice", 14.0)
		"child":
			return Labour._num(caps, "child", 6.0)
	return Labour._num(caps, "adult", 20.0)


## Bir seferin gerçek saniyesi: yaya d / 1,9 + d / 1,4 + 8 (boş, dolu, alma ve bırakma); araba 2d / 6,8 + 30.
static func haul_trip(d: float, carrier: Variant = "adult") -> float:
	var x := d if d > 0.0 else 0.0
	var h: Dictionary = law().get("haul", {})
	if Labour._is_cart(carrier):
		var cart: Dictionary = h.get("cart", {})
		return 2.0 * x / Labour._num(cart, "speed", 6.8) + Labour._num(cart, "handleS", 30.0)
	return x / Labour._num(h, "vEmpty", 1.9) + x / Labour._num(h, "vLoaded", 1.4) + Labour._num(h, "handleS", 8.0)


## Sefer sayısı: ceil(yük / tavan); tavan 0 ise INF.
static func haul_trips(load: float, carrier: Variant = "adult") -> float:
	if not (load > 0.0):
		return 0.0
	var cap := Labour.haul_cap(carrier)
	return ceilf(load / cap - EPS) if cap > 0.0 else INF


## Taşımanın emeği, İD: sefer × sefer_sn / 2,5 (taşıma eğriden geçmez).
static func haul_work(load: float, d: float, carrier: Variant = "adult") -> float:
	var trips := Labour.haul_trips(load, carrier)
	return trips * Labour.haul_trip(d, carrier) / real_s_per_min() if trips > 0.0 else 0.0


# ---------- Günlük emek ----------

## «hh:mm» ya da gün dakikası → gün dakikası.
static func day_minute(v: Variant) -> float:
	if v is String:
		var s: String = v
		return float(s.substr(0, 2)) * 60.0 + float(s.substr(3, 2))
	return float(v)


## Yerin üretim ve «Gece dinlenilsin» penceresi (gün dakikası): ana kamp 06:00–22:00, Kışlak 07:00–23:00; yerleşim ve ordugâh bahar
## ve yazda 05:30–21:30, güz ve kışta 07:00–23:00.
static func rest_window(place: String, season: Variant = null) -> Array:
	var w: Dictionary = (law().get("night", {}) as Dictionary).get("restWindow", {})
	var key := place if place == "camp" or place == "kislak" else ("summer" if season == "spring" or season == "summer" else "winter")
	var pair: Array = w.get(key, ["06:00", "22:00"])
	return [Labour.day_minute(pair[0]), Labour.day_minute(pair[1])]


## Işık düzeyinin güneş yüksekliği: güneş eğrisinin tersi (dayLevel 0,5 → −2,90°, dimLevel 0,25 → −8°).
static func _level_el(level: float) -> float:
	var curve: Array = (law().get("dayCapacity", {}) as Dictionary).get("sunCurve", [[6, 1], [-0.833, 0.6], [-6, 0.35], [-12, 0.05]])
	for i in range(1, curve.size()):
		var e0 := float(curve[i - 1][0])
		var l0 := float(curve[i - 1][1])
		var e1 := float(curve[i][0])
		var l1 := float(curve[i][1])
		if level <= l0 and level >= l1:
			return e0 + (level - l0) * (e1 - e0) / (l1 - l0)
	return 90.0 if level > float(curve[0][1]) else -90.0


## Güneşin el°'nin üstünde kaldığı yarım süre, öğleden iki yana oyun dk.
static func _half_above(lat: float, dec: float, el: float) -> float:
	var c := (sin(deg_to_rad(el)) - sin(deg_to_rad(lat)) * sin(deg_to_rad(dec))) / (cos(deg_to_rad(lat)) * cos(deg_to_rad(dec)))
	if c <= -1.0:
		return day_min() / 2.0
	if c >= 1.0:
		return 0.0
	return acos(c) / (2.0 * PI) * day_min()


static func _overlap(a: float, b: float, lo: float, hi: float) -> float:
	return maxf(0.0, minf(b, hi) - maxf(a, lo))


static func _window_overlap(a: float, b: float, lo: float, hi: float) -> float:
	if b > a:
		return Labour._overlap(a, b, lo, hi)
	return Labour._overlap(a, day_min(), lo, hi) + Labour._overlap(0.0, b, lo, hi)


## Bir işçinin günlük emeği, İS / gün (d2/core.md §2.5). job "herd" 24; "build" gece emri "work" (varsayılan) ile bütün gün, ışıklıysa
## 24, ışıksızsa her dakika gece sınıfıyla; "rest" emriyle ve öteki işlerde ("produce", ev işi) pencere (yoksa ana kamp 06:00–22:00),
## ışıklıysa (atölye) ×1. day_info: {lat, dec, window: [başı, sonu] (gün dakikası ya da «hh:mm»), class_at: Callable(gün dakikası) →
## gece sınıfı}; class_at verilirse (ay ve bulut dahil) dakika dakika okunur, yoksa güneş ışıksız akşamla çözülür.
static func day_capacity(job: String, day_info: Dictionary = {}, lit: bool = false, night_order: String = "work") -> float:
	var cap: Dictionary = law().get("dayCapacity", {})
	if job == "herd":
		return Labour._num(cap, "herding", 24.0)
	var given: Variant = day_info.get("window")
	var win: Array = [0.0, day_min()] if job == "build" and night_order != "rest" else (given if given is Array else Labour.rest_window("camp"))
	var a := Labour.day_minute(win[0])
	var b := Labour.day_minute(win[1])
	var length := b - a if b > a else day_min() - a + b
	if lit:
		return length / 60.0
	var class_at: Variant = day_info.get("class_at")
	if class_at is Callable and (class_at as Callable).is_valid():
		var sum := 0.0
		for i in int(ceilf(length)):
			sum += Labour.night_k((class_at as Callable).call(fmod(a + float(i) + 0.5, day_min())))
		return sum / 60.0
	var lat_v: Variant = day_info.get("lat")
	var dec_v: Variant = day_info.get("dec")
	if not (lat_v is float or lat_v is int) or not (dec_v is float or dec_v is int):
		return length / 60.0
	var lat := float(lat_v)
	var dec := float(dec_v)
	var night: Dictionary = law().get("night", {})
	var classes: Dictionary = night.get("classes", {})
	var noon := day_min() / 2.0
	var h_day := Labour._half_above(lat, dec, Labour._level_el(Labour._num(night, "dayLevel", 0.5)))
	var h_dim := Labour._half_above(lat, dec, Labour._level_el(Labour._num(night, "dimLevel", 0.25)))
	var in_day := Labour._window_overlap(a, b, noon - h_day, noon + h_day)
	var in_light := Labour._window_overlap(a, b, noon - h_dim, noon + h_dim)
	return (in_day * Labour._num(classes, "day", 1.0) + (in_light - in_day) * Labour._num(classes, "dim", 0.7) \
		+ (length - in_light) * Labour._num(classes, "dark", 0.4)) / 60.0
