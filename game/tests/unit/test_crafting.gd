extends TestCase
## Zanaat (Yol Haritası crafting; economy.md §6; godot.md §3 «Zanaat», §8.2): tarif ve tezgâh tabloları modelle (d2/econ-model.json; tools/
## export_recipes.py) ve prototiple aynı, her başvuru çözülür; tarif çözümü (girdi, İnce İş ustası, eksikler, el işi, birim süresi, tezgâhın
## tarifleri) ve tezgâhın saati (Workshop.tick: eff(W), gece sınıfı, açık tezgâhta hava, bekleme yuvası ve kurutma, usta, malzeme, gece
## vardiyası, meşale, İnce İş, defter payı ve Aşçı, dolu yuva, uzun adım, NPC el işi ve dolu kap, iade ve kayıt) prototipin fikstürüyle
## (tests/fixtures/crafting.json; tools/proto_fixtures/crafting.mjs) aynı; gerçek kaplarla (ItemContainer, Inventory) uçtan uca; ilk kez yapılan
## tarif Progression'ın «recipe» kaynağından bir kez +20 XP.

const ProtoFixture := preload("res://tests/support/proto_fixture.gd")
const MODEL_PATH := "../docs/design/d2/econ-model.json"
## Modelin sahip olduğu alanlar (tools/export_recipes.py RECIPE_FIELDS; «fine», İnce İş'in eki Godot'nundur, model yazmaz).
const MODEL_RECIPE_FIELDS := ["station", "who", "role", "in", "out", "hold", "wh", "cure", "act", "a1", "skill", "seasons"]

var _fx: Dictionary = {}
var _model: Dictionary = {}


func before_each() -> void:
	if _fx.is_empty():
		_fx = ProtoFixture.load_fixture("crafting")
	if _model.is_empty():
		var path := ProjectSettings.globalize_path("res://").path_join(MODEL_PATH).simplify_path()
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		_model = parsed if parsed is Dictionary else {}


## Sınırsız kap (prototipin Box'u); cap 0 dolu kap.
static func _box(contents: Dictionary, cap: Variant = null) -> ItemContainer:
	var c := ItemContainer.new("box", "store_yurt", ItemContainer.UNLIMITED)
	for id: String in contents:
		c.add(id, int(contents[id]))
	if cap is float or cap is int:
		c.set_cap10(int(cap))
	return c


static func _list(c: ItemContainer) -> Array:
	var out: Array = c.list()
	out.sort_custom(func(p: Dictionary, q: Dictionary) -> bool: return str(p["id"]) < str(q["id"]))
	return out


static func _opts(o: Variant) -> Dictionary:
	var d: Dictionary = (o as Dictionary).duplicate(true) if o is Dictionary else {}
	var out := {}
	for k: String in d:
		match k:
			"crewW":
				out["crew_w"] = d[k]
			"weather":
				out["weather"] = {"type": "clear", "dryK": 1.0} if d[k] is String and d[k] == "CLEAR" else ({"type": "rain", "dryK": 0.0} if d[k] is String and d[k] == "RAIN" else d[k])
			_:
				out[k] = d[k]
	return out


## Prototipin runWorkshop'u: aynı işlemler, aynı çıktı biçimi.
static func _run_workshop(sc: Dictionary) -> Dictionary:
	var ws := Workshop.new({"id": str(sc.get("id", "")), "station": str(sc["station"])})
	var cap: Variant = sc.get("cap")
	var pool := _box(sc.get("pool", {}), 0 if (cap is float or cap is int) and float(cap) == 0.0 else null)
	var trace: Array = []
	for op: Dictionary in sc["ops"]:
		if op.has("order"):
			var a: Array = op["order"]
			trace.append(["order", ws.order(str(a[0]), int(a[1]) if a.size() > 1 else 1, a[2] if a.size() > 2 else {})])
		elif op.has("tick"):
			var t: Array = op["tick"]
			var o := _opts(t[1] if t.size() > 1 else {})
			o["pool"] = pool
			var r := ws.tick(float(t[0]), o)
			var q: Array = []
			for e: Dictionary in ws.queue:
				q.append([e["recipe"], e["n"], e["wm"], e["have"], e["ready"]])
			var cv: Array = []
			for e: Dictionary in ws.cures:
				cv.append([e["recipe"], e["left"], e["paused"]])
			trace.append(["tick", {"done": r["done"], "used": r["used"], "wait": r["wait"], "night_min": r["night_min"], "torches": r["torches"]}, q, cv,
				ws.cure_wait])
		elif op.has("add"):
			trace.append(["add", int(pool.add(str(op["add"][0]), int(op["add"][1]))["added"])])
		elif op.has("cancel"):
			trace.append(["cancel", ws.cancel(int(op["cancel"]))])
		elif op.has("crew"):
			ws.crew = op["crew"]
		elif op.has("cap"):
			pool.set_cap10(ItemContainer.UNLIMITED if op["cap"] is String or op["cap"] == null else int(op["cap"]))
		elif op.has("set_wm"):
			(ws.queue[int(op["set_wm"][0])] as Dictionary)["wm"] = float(op["set_wm"][1])
	var outbox: Array = []
	for e: Dictionary in ws.outbox:
		outbox.append([e["id"], e["n"]])
	return {"trace": trace, "pool": _list(pool), "json": ws.to_dict(), "outbox": outbox}


# --- Tablolar ------------------------------------------------------------------------------------------------------------

func test_recipes_and_stations_are_the_model() -> void:
	assert_false(_model.is_empty(), "Model okunur")
	var model_recipes: Dictionary = _model.get("recipes", {})
	var n := 0
	for id: String in model_recipes:
		if id.begins_with("_"):
			continue
		n += 1
		var m: Dictionary = model_recipes[id]
		var r := Craft.recipe(id)
		assert_false(r.is_empty(), "Modelin tarifi oyunda: %s" % id)
		for f: String in MODEL_RECIPE_FIELDS:
			assert_eq(r.get(f), m.get(f), "%s.%s modelle aynı" % [id, f])
	assert_eq(n, 87, "Modelin 87 tarifi")
	var a1 := 0
	for id: String in Craft.recipes():
		if not model_recipes.has(id):
			a1 += 1
			assert_eq(str(Craft.recipe(id).get("source", "")), "a1", "%s: modelde olmayan tarif I. Perde'nin el tarifidir (§6.2)" % id)
			assert_null(Craft.recipe(id).get("wh"), "%s tezgâh sırası almaz" % id)
	assert_eq(a1, 8, "I. Perde'nin sekiz el tarifi")
	var model_stations: Dictionary = _model.get("stations", {})
	var ids: Array = []
	for id: String in model_stations:
		if id.begins_with("_"):
			continue
		ids.append(id)
		var s := Craft.station(id)
		for f: String in ["crewMax", "slots", "act", "structure", "open"]:
			assert_eq(s.get(f), (model_stations[id] as Dictionary).get(f), "%s.%s modelle aynı" % [id, f])
		assert_eq(Craft.station_name(id, "tr"), str(model_stations[id]["tr"]))
		assert_eq(Craft.station_name(id, "en"), str(model_stations[id]["en"]))
	assert_eq(ids.size(), 11, "On bir tezgâh")
	assert_eq(Craft.stations().keys().size(), 11)
	var dry: Array = []
	for id: String in Craft.stations():
		if Craft.station(id).get("dry", false):
			dry.append(id)
	dry.sort()
	assert_eq(dry, ["drying_rack", "felt_yard", "tannery"], "Açık hava beklemesi yalnız sırık, Sepi Yeri ve keçe kurutma (§6.7 kural 4)")
	for id: String in _model.get("masters", {}):
		if not id.begins_with("_"):
			assert_false(Craft.role(id).is_empty(), "Zanaatçı: %s" % id)


func test_tables_match_the_prototype() -> void:
	var c: Dictionary = _fx.get("constants", {})
	var proto_recipes: Dictionary = c.get("recipes", {})
	assert_true(proto_recipes.size() >= 80)
	for id: String in proto_recipes:
		var p: Dictionary = proto_recipes[id]
		var r := Craft.recipe(id)
		assert_false(r.is_empty(), "Prototipin tarifi oyunda: %s" % id)
		for f: String in ["station", "who", "in", "out", "act", "skill", "seasons", "fine"]:
			# Ocak Bilgisi sargıyı açar (economy.md §3.4 «hearth_craft: rc_bandage»): prototipin tablosu beceriyi yazmıyordu.
			if id == "rc_bandage" and f == "skill":
				assert_eq(r.get(f), "hearth_craft")
				continue
			assert_true(ProtoFixture.compare(r.get(f), p.get(f), 0.0).is_empty(), "%s.%s prototipinkiyle aynı (%s ≠ %s)" % [id, f, r.get(f), p.get(f)])
		assert_eq(r.get("hold"), p.get("hold"), "%s.hold" % id)
		assert_eq(r.get("wh"), p.get("wh"), "%s.wh" % id)
		assert_eq(float(r.get("cure", 0.0)), float(p.get("cure", 0.0)), "%s.cure" % id)
		assert_eq(r.get("role"), p.get("role"), "%s.role" % id)
	for id: String in c.get("stations", {}):
		var p: Dictionary = c["stations"][id]
		var s := Craft.station(id)
		assert_eq([s.get("crewMax"), s.get("slots"), bool(s.get("open", false)), bool(s.get("dry", false))], [p["crewMax"], p["slots"], p["open"], p["dry"]], "Tezgâh %s" % id)
	for id: String in c.get("roles", {}):
		var p: Dictionary = c["roles"][id]
		var r := Craft.role(id)
		assert_eq([Craft.role_name(id, "tr"), Craft.role_name(id, "en"), r.get("station"), r.get("craft"), r.get("tier")], [p["tr"], p["en"], p["station"], p["craft"], p["tier"]], "Rol %s" % id)
	assert_eq(Craft.role("cr_cook").get("speedFor"), c["roles"]["cr_cook"]["speedFor"])
	assert_eq(float(Craft.role("cr_cook").get("speedK")), 1.25)
	assert_eq(Craft.station_role("felt_yard"), "cr_felter")
	assert_eq(Craft.station_role("tannery"), "cr_tanner")
	assert_eq(Craft.station_role("smithy"), "cr_smith", "Adlı usta (Kujul) İnce İş'in ustası değildir")
	assert_null(Craft.station_role("hand"))
	assert_eq(Craft.torch_dark_min(), float(c["craft_labour"]["torchDarkMin"]), "Meşale 4 karanlık saat (labour.json)")
	assert_eq(Craft.fine_k(), float(c["craft_labour"]["fineK"]))
	assert_eq(Craft.recipe_xp(), int(c["craft_labour"]["recipeXp"]), "İlk tarif +20 XP (progression.json recipe)")
	for t: String in c.get("dry_by_type", {}):
		assert_eq(Craft.dry_by_type(t), float(c["dry_by_type"][t]), "Kurutma çarpanı %s" % t)


func test_every_recipe_resolves() -> void:
	for id: String in Craft.recipes():
		var r := Craft.recipe(id)
		assert_false(Craft.station(str(r.get("station", ""))).is_empty(), "%s.station" % id)
		var rr: Variant = r.get("role")
		for role: Variant in (rr if rr is Array else ([rr] if rr != null else [])):
			assert_false(Craft.role(str(role)).is_empty(), "%s.role %s" % [id, role])
		assert_eq(str(r.get("who", "")) == "master", rr != null, "%s: usta işi rol ister" % id)
		for ref: String in (r.get("in", {}) as Dictionary):
			if ref.begins_with("tag:"):
				var has := false
				for item_id: String in ItemCatalog.ids():
					if ItemCatalog.matches(item_id, ref):
						has = true
						break
				assert_true(has, "%s girdisi %s'in eşyası var" % [id, ref])
			else:
				assert_true(ItemCatalog.has(ref), "%s girdisi %s eşya kataloğunda" % [id, ref])
		for out_id: String in (r.get("out", {}) as Dictionary):
			assert_true(out_id.begins_with("@") or ItemCatalog.has(out_id), "%s çıktısı %s eşya kataloğunda" % [id, out_id])
		if Craft.is_hand(r) and str(r.get("who", "")) == "hand" and id != "rc_meal":
			assert_true(float(r["hold"]) <= 8.0, "%s el işi ≤8 sn (%s)" % [id, r["hold"]])
		assert_true(Craft.is_hand(r) or Craft.is_queued(r), "%s elde ya da tezgâhta yapılır" % id)
		if r.get("fine") is Dictionary:
			for out_id: String in (r["out"] as Dictionary):
				assert_true(ItemCatalog.has("%s+" % out_id), "%s: İnce İş çıktısı %s+ eşya kataloğunda" % [id, out_id])
			assert_not_null(Craft.fine_role(id), "%s'in İnce İş ustası" % id)
	assert_true(Craft.recipe("rc_meal")["hold"] == 15.0, "Aş'ın tutuşu pişirme oturuşudur (15 sn)")
	for key: String in ["make", "wait_materials", "need_master", "take_missing", "store_materials", "take_all", "work_until_done"]:
		assert_ne(Craft.message(key, "en"), key, "İleti: %s" % key)
	assert_eq(Craft.message("wait_materials", "tr", {"list": "2 Bakır Cevheri"}), "Malzeme bekliyor: 2 Bakır Cevheri")
	assert_eq(Craft.ref_name("tag:wood", "tr"), "Odun")
	assert_eq(Craft.recipe_name("rc_copper_bit", "en"), "Copper Piece")


# --- Prototipin fikstürü ------------------------------------------------------------------------------------------------------

func test_pure_helpers_match_the_prototype() -> void:
	var n := ProtoFixture.run_cases(self, _fx, {
		"crew_eff": func(a: Array) -> Variant: return Labour.eff(float(a[0])),
		"unit_minutes": func(a: Array) -> Variant: return Craft.unit_minutes(str(a[0]), float(a[1]), bool(a[2])),
		"inputs_of": func(a: Array) -> Variant: return Craft.inputs_of(str(a[0]), bool(a[1])),
		"fine_role": func(a: Array) -> Variant: return Craft.fine_role(str(a[0])),
		"can_craft": func(a: Array) -> Variant:
			var o: Dictionary = (a[2] as Dictionary).duplicate()
			o["inv"] = _box(a[1])
			if o.has("role"):
				o["roles"] = o["role"]
			return Craft.can_craft(str(a[0]), o),
		"craft_hand": func(a: Array) -> Variant:
			var box := _box(a[1])
			var o: Dictionary = a[2]
			return {"out": Craft.craft_hand(str(a[0]), box, o), "pool": _list(box)},
		"recipes_at": func(a: Array) -> Variant:
			var common: Array = a[1]
			var out: Array = Array(Craft.recipes_at(str(a[0]))).filter(func(id: String) -> bool: return common.has(id))
			out.sort()
			return out,
	}, PackedStringArray(["crew_eff", "unit_minutes", "inputs_of", "fine_role", "can_craft", "craft_hand", "recipes_at"]))
	assert_true(n >= 45, "Saf durum sayısı: %d" % n)


func test_workshop_matches_the_prototype() -> void:
	var n := ProtoFixture.run_cases(self, _fx, {
		"workshop": func(a: Array) -> Variant: return _run_workshop(a[0]),
		"long_step": func(a: Array) -> Variant:
			var ws := Workshop.new({"station": "felt_yard"})
			var pool := _box({"wool": 36})
			ws.order("rc_felt_batch", 3)
			var step := float(a[0])
			var t := 0.0
			while t < 1800.0:
				ws.tick(step, {"crew_w": 4.0, "weather": {"type": "clear", "dryK": 1.0}, "pool": pool})
				t += step
			var left: Array = []
			for cv: Dictionary in ws.cures:
				left.append(cv["left"])
			return [pool.count("felt"), ws.queue.size(), left],
		"workshop_json": func(a: Array) -> Variant:
			var saved: Dictionary = a[0]
			var junk := Workshop.new({"station": "tannery"}).from_dict({"q": [["rc_gone", 1, 0, 0]], "cures": [["rc_gone", 2]]})
			return {"back": Workshop.new({"id": "tannery_1", "station": "tannery"}).from_dict(saved).to_dict(), "junk": junk.to_dict()},
	}, PackedStringArray(["workshop", "long_step", "workshop_json"]))
	assert_true(n >= 20, "Tezgâh senaryoları: %d" % n)


func test_workshop_reads_the_labour_law() -> void:
	# Keçe Avlusu emeği yağmurda ×0,7 (keçe adımı), Sepi Yeri genel çarpan, Ağaç Atölyesi çatılı (labour.json weather).
	var weather: Dictionary = Labour.data().get("weather", {})
	for type_id: String in weather:
		if not weather[type_id] is Dictionary:
			continue
		var w: Dictionary = weather[type_id]
		var felt := Workshop.new({"station": "felt_yard"})
		felt.order("rc_felt_batch")
		var r := felt.tick(1.0, {"crew_w": 4.0, "pool": _box({"wool": 12}), "weather": {"type": type_id, "dryK": 1.0}})
		assert_almost(float(r["used"]), Labour.eff(4.0) * float(w.get("felt", w.get("k", 1.0))), 1e-9, "Keçe Avlusu: %s" % type_id)
		var shop := Workshop.new({"station": "wood_shop"})
		shop.order("rc_uuk_set")
		assert_almost(float(shop.tick(1.0, {"crew_w": 3.0, "pool": _box({"wood_pine": 12}), "weather": {"type": type_id, "dryK": 1.0}})["used"]), Labour.eff(3.0), 1e-9,
			"Çatılı atölye havadan bağımsız: %s" % type_id)
	for cls: String in ["lit", "day", "dim", "dark"]:
		var ws := Workshop.new({"station": "wood_shop"})
		ws.order("rc_uuk_set")
		assert_almost(float(ws.tick(1.0, {"crew_w": 2.0, "pool": _box({"wood_pine": 12}), "lit": cls})["used"]), Labour.eff(2.0) * Labour.night_k(cls), 1e-9, "Gece sınıfı %s" % cls)
	assert_almost(Labour.eff(4.0), 3.439, 1e-9, "4 elle eff 3,439")


# --- Gerçek kaplar ------------------------------------------------------------------------------------------------------------

func test_real_containers_end_to_end() -> void:
	var store := ItemContainer.make("store_yurt", {"id": "store_yurt_1"})
	store.add("wool", 12)
	var ws := Workshop.new({"station": "felt_yard"})
	ws.order("rc_felt_batch")
	ws.tick(122.2, {"crew_w": 4.0, "weather": {"type": "clear", "dryK": 1.0}, "pool": store})
	assert_eq(store.count("wool"), 0, "Girdi birim başlarken ayrıldı")
	ws.tick(360.0, {"crew_w": 0.0, "weather": {"type": "clear", "dryK": 1.0}, "pool": store})
	assert_eq(store.count("felt"), 6, "6 saat kurudu: 6 keçe")
	# El işi Heybe'de etiketi çözer: tag:wood_light söğüdü alır.
	var inv := Inventory.new()
	inv.add("wood_willow", 1)
	inv.add("reed", 3)
	assert_true(Craft.can_craft("rc_shafts", {"inv": inv})["ok"])
	assert_eq(Craft.craft_hand("rc_shafts", inv)["out"], [{"id": "arrow_shaft", "n": 15}])
	assert_eq(inv.count("arrow_shaft"), 15)
	var p := Progression.new()
	var made := Craft.craft_hand("rc_rope", inv, {"first": true})
	assert_eq(made, {"out": [{"id": "rope", "n": 1}], "xp": 20})
	assert_eq(p.award("recipe", {"key": "rc_rope"}), 20, "İlk ip +20 XP")
	assert_eq(p.award("recipe", {"key": "rc_rope"}), 0, "Aynı tarif ikinci kez XP vermez")
	assert_eq([inv.count("reed"), inv.count("rope")], [0, 1])
	# Tezgâh işi oyuncunun Heybe'sinden değil tezgâhın kabından alır; eksikleri Eksikleri Al (take_missing) Heybe'ye getirir.
	var chest := ItemContainer.make("chest", {"id": "bench"})
	chest.add("reed", 6)
	var need := Craft.inputs_of("rc_rope")
	var moved := inv.take_missing(chest, need)
	assert_eq(inv.count("reed"), 3, "Eksikler Heybe'ye: %s" % [moved])
	assert_eq(chest.count("reed"), 3)
	assert_true(Craft.can_craft("rc_rope", {"inv": inv})["ok"])
	var missing := Craft.can_craft("rc_door_frame", {"inv": chest, "station": "wood_shop"})
	assert_false(missing["ok"])
	assert_eq(Craft.missing_text(missing["missing"], "tr"), "Malzeme bekliyor: 3 Odun, 1 Demir Külçe")
	assert_eq(Craft.wait_text({"reason": "master", "role": "cr_carpenter"}, "en"), "A master is needed: Carpenter")
	assert_eq(Craft.missing_text(Craft.can_craft("rc_kerege_set", {"inv": chest, "station": "wood_shop"})["missing"], "tr"), "Usta gerek: Dülger")


func test_remaining_minutes_and_status() -> void:
	var ws := Workshop.new({"station": "smithy"})
	ws.order("rc_heads_iron", 2)
	assert_almost(ws.remaining_minutes(1.0), 600.0, 1e-9, "İki birim 5 İS: tek elle 600 oyun dakikası")
	assert_almost(ws.remaining_minutes(3.0), 600.0 / Labour.eff(3.0), 1e-9)
	var pool := _box({"iron_bar": 2, "charcoal": 2})
	ws.tick(150.0, {"crew_w": 1.0, "pool": pool})
	var st := ws.status()
	assert_almost(float(st["queue"][0]["progress"]), 0.5, 1e-9, "Yarısı")
	assert_almost(ws.remaining_minutes(1.0), 450.0, 1e-9)
	var copper := Workshop.new({"station": "smithy"})
	assert_eq(copper.order("rc_copper_bit", 1), 0, "Bakır parça tezgâhın sırasına da girer (1 İS)")
	assert_eq(copper.order("rc_shears", 1), -1, "Kujul'un makası tezgâh sırası almaz (Mete'nin tutuşu)")
