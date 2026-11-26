class_name SiteRules
extends RefCounted
## Elle kurulan şantiyelerin kuralları (saf; data/structures/sites.json): camp3 (Göl Obası'nın üçüncü yurdu; structures.md §10.2, §11.6,
## K83) ve Kışlak'ın Yeni Yurdu (act1.md §9.3, structures.md §14). SiteState'i kurar; ekip, öğün, iş penceresi, ayak işleri, Ambar
## gönderimleri, hikâye kapıları ve «Aile bekler» zamanlanmış olaylardır (SiteState.add_event). Olayların işleyicileri yalnız kendilerine
## verilen şantiyeyi değiştirir: kestirim (SiteState.eta) kopya üstünde aynı olayları koşar, gerçek durumu bozmaz.
##
## «Aile bekler» (K83): kurulum gecesi 23:00'te (check) aşama ≥4 (min_stage; uuk bitmiş) ise aile ilk dumana dek ateş başındadır
## (opts.family_wait = true); değilse aile yatar (false), y_ocak 05:00'ten (ember_at) önce başlamaz. 05:00'te ocak yanmadıysa Ana közü
## getirir (köz yığında: y_ocak 6 İD). Köz ember_life_min (180) oyun dk sonra söner: y_ocak o vakte dek başlamadıysa ekip közü kendi alır
## (tasarım boşluğu kararı; «Gece dinlenilsin» satırı belgedeki gibi ertesi 14:17'de biter).
##   var site := SiteRules.camp3(894.0)                 # 14:54'te başlar (ustalar indi)
##   site.child["joined"] = true                        # Çocuk ustalara katıldı
##   site.advance(start + 900.0)

const CAMP3 := "camp3"
const KISLAK := "kislak_new_yurt"


## camp3'ün şantiyesi: start_min'de başlar (ustaların inişi). opts: rest (Gece dinlenilsin), child {joined, water, logs, ember},
## weather (tür kimliği; varsayılan açık hava), family (false: aile kuralı kurulmaz).
static func camp3(start_min: float, opts: Dictionary = {}) -> SiteState:
	var spec := SiteState.site_spec(CAMP3)
	var site := SiteState.create(str(spec.get("kind", "yurt")), str(spec.get("size", "m")), spec.get("labour", {}))
	site.id = CAMP3
	site.opts["stock_free"] = true
	site.env["fed"] = float((spec.get("labour", {}) as Dictionary).get("fed", 1.0))
	site.env["weather"] = str(opts.get("weather", "clear"))
	site.crew = (spec.get("crew", []) as Array).duplicate(true)
	site.set_errands(spec.get("errands", {}))
	var ch: Dictionary = opts.get("child", {})
	for key: String in ch:
		site.child[key] = ch[key]
	if int(site.child.get("ember", 0)) > 0:
		site.ember = true
	if bool(opts.get("rest", false)):
		site.rest_window = (spec.get("rest_window", ["06:00", "22:00"]) as Array).duplicate()
	if bool(opts.get("family", true)):
		SiteRules.install_family(site, spec.get("family", {}), start_min)
	site.start(start_min)
	return site


## «Aile bekler» olayları (K83): kurulum gecesinin 23:00 denetimi ve 05:00 közü, közün sönüşü.
static func install_family(site: SiteState, fam: Dictionary, start_min: float) -> void:
	var day0 := floorf(start_min / 1440.0) * 1440.0
	var check := day0 + SiteState.day_min(fam.get("check", "23:00"))
	if check <= start_min:
		check += 1440.0
	var dawn := floorf(check / 1440.0) * 1440.0 + SiteState.day_min(fam.get("ember_at", "05:00"))
	if dawn <= check:
		dawn += 1440.0
	var life := float(fam.get("ember_life_min", 180.0))
	var min_stage := int(fam.get("min_stage", 4))
	site.opts["family_check_at"] = check
	site.opts["family_dawn_at"] = dawn
	site.add_event(check, SiteRules._family_check.bind(min_stage, dawn), "family")
	site.add_event(dawn, SiteRules._family_ember, "family")
	site.add_event(dawn + life, SiteRules._ember_out, "family")


static func _family_check(site: SiteState, _at: float, min_stage: int, dawn: float) -> void:
	var wait := site.stage >= min_stage
	site.opts["family_wait"] = wait
	if not wait and not site.is_done():
		site.gates["y_ocak"] = dawn


## 05:00: ocak yanmadıysa Ana közü getirir (köz yığında).
static func _family_ember(site: SiteState, _at: float) -> void:
	if not site.log.has("y_ocak"):
		site.ember = true
		site.opts["ember_by"] = "mother"


## Köz söner: y_ocak başlamadıysa (sıradaki adım ondan önceyse) köz gider; Çocuğun getirdiği köz de aynı kurala uyar.
static func _ember_out(site: SiteState, _at: float) -> void:
	if site.log.has("y_ocak"):
		return
	var idx := site.steps.size() - 1
	for i in site.steps.size():
		if str((site.steps[i] as Dictionary).get("id", "")) == "y_ocak":
			idx = i
	if site.step < idx:
		site.ember = false
		site.child["ember"] = 0


## Ailenin ilk dumanı ateş başında görüp görmeyeceği (satır seçimi: lines.night ya da lines.dawn). Denetim yapılmadıysa null.
static func family_saw_smoke(site: SiteState) -> Variant:
	return site.opts.get("family_wait")


## Kışlak'ın Yeni Yurdu: day1_min Gün I'in gece yarısı (mutlak dk), start_min y_site'ın başı (Gün I ≈14:00, mq_first_tally'nin altı taşı ve
## Ardokşa'nın demiri yığında). Ambar «yalnız eksiği» gönderir: gönderim anında o aşamanın adımlarının yığında olmayanı eklenir.
static func kislak_new_yurt(day1_min: float, start_min: float, opts: Dictionary = {}) -> SiteState:
	var spec := SiteState.site_spec(KISLAK)
	var site := SiteState.create(str(spec.get("kind", "yurt")), str(spec.get("size", "m")), spec.get("labour", {}))
	site.id = KISLAK
	site.opts["stock_free"] = false
	site.crew = (spec.get("crew", []) as Array).duplicate(true)
	site.stock = (opts.get("stock", {"stone": 6.0, "iron_bar": 1.0}) as Dictionary).duplicate()
	for d: Dictionary in spec.get("deliveries", []):
		var at := day1_min + float(int(d.get("day", 1)) - 1) * 1440.0 + SiteState.day_min(d.get("at", "09:00"))
		site.add_event(at, SiteRules._deliver_missing.bind(int(d.get("stage", 0))), "ambar")
	var gates: Dictionary = spec.get("gates", {})
	for sid: String in gates:
		var g: Dictionary = gates[sid]
		var at := day1_min + float(int(g.get("day", 1)) - 1) * 1440.0 + SiteState.day_min(g.get("at", "08:00"))
		site.gates[sid] = at
		var c: Variant = g.get("crew")
		if c is int or c is float:
			var hands: Array = []
			for i in int(c):
				hands.append({"id": "scene_%d" % i, "role": "hand", "w": 1.0})
			site.step_crew[sid] = hands
		elif c is Array:
			site.step_crew[sid] = (c as Array).duplicate(true)
		# Kapının anında adımın malzemesi sahnenindir (tündük, köz).
		site.add_event(at, SiteRules._scene_supply.bind(sid, bool(g.get("ember", false))), "story")
	site.start(start_min)
	return site


static func _deliver_missing(site: SiteState, _at: float, stage_n: int) -> void:
	for i in site.steps.size():
		var st: Dictionary = site.steps[i]
		if int(st.get("stage", 0)) != stage_n or i < site.step or bool(st.get("_paid", false)):
			continue
		var cost: Dictionary = st.get("cost", {})
		for item: String in cost:
			if item == "ember":
				continue
			var need := float(cost[item])
			# Yığındaki aynı malı önceki adımlar da isteyebilir: o aşamanın toplam eksiği gönderilir.
			var want := need + SiteRules._reserved(site, item, i)
			var have := float(site.stock.get(item, 0.0))
			if have + SiteState.EPS < want:
				site.deliver(item, want - have, "npc")


## i'den önceki, henüz ödenmemiş adımların aynı maldan isteği.
static func _reserved(site: SiteState, item: String, before: int) -> float:
	var t := 0.0
	for j in range(site.step, before):
		var st: Dictionary = site.steps[j]
		if not bool(st.get("_paid", false)):
			t += float((st.get("cost", {}) as Dictionary).get(item, 0.0))
	return t


static func _scene_supply(site: SiteState, _at: float, sid: String, with_ember: bool) -> void:
	for st: Dictionary in site.steps:
		if str(st.get("id", "")) != sid:
			continue
		var cost: Dictionary = st.get("cost", {})
		for item: String in cost:
			if item != "ember" and float(site.stock.get(item, 0.0)) < float(cost[item]):
				site.deliver(item, float(cost[item]) - float(site.stock.get(item, 0.0)), "npc")
	if with_ember:
		site.ember = true
