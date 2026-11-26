extends TestCase
## Toplama (Yol Haritası gathering; economy.md §3; godot.md §3 «Toplama», §8.2): tür tablosu (data/economy/node_kinds.json) prototiple ve eşya
## kataloğuyla aynı; NodeStore'un yerleşimi, parça dizini, hakları, şafağı, uzak alımı ve kaydı prototiple bit bit aynı (I. Perde'nin
## 3.270 kaydı, altın karma); Gather'ın saf hesapları (vuruş süresi, Tam Vuruş penceresi ve yargısı, araç kademesi) ve durum makinesinin
## senaryoları (vuruş, tutuş, +1 birikimi, stamina, yer yığını, sıralı verim, ikinci eylem, gece gürültüsü, koşullu ve etkili düğüm)
## prototipin fikstürüyle (tests/fixtures/gathering.json; tools/proto_fixtures/gathering.mjs) aynı; gerçek Inventory ile verim önce Heybe'ye,
## sığmayan yer yığınına; Tam Vuruş becerisi Progression'dan, toplama XP vermez; «economy» kayıt bloğu gidiş dönüşü.

const ProtoFixture := preload("res://tests/support/proto_fixture.gd")
const DT := 0.02

var _fx: Dictionary = {}


func before_each() -> void:
	if _fx.is_empty():
		_fx = ProtoFixture.load_fixture("gathering")


## Prototipin sahte heybesi: adet sınırı (cap), sığmayan yer yığınına (pile.1).
class FakeBag:
	extends RefCounted
	var cap := 100
	var tools: Array = []
	var items := {}

	func has_tool(id: String) -> bool:
		return tools.has(id)

	func count(id: String) -> int:
		return int(items.get(id, 0)) + (1 if tools.has(id) else 0)

	func receive(id: String, n: int, _src := "", opts := {}) -> Dictionary:
		var used := 0
		for k: String in items:
			used += int(items[k])
		var added := maxi(0, mini(n, cap - used))
		if added > 0:
			items[id] = int(items.get(id, 0)) + added
		var to := {"pack": added} if added > 0 else {}
		if n - added > 0 and opts.get("spill_at") is Vector3:
			to["pile.1"] = n - added
		return {"added": n, "rest": 0, "to": to}


class FakeStamina:
	extends RefCounted
	var stamina := 100.0
	var stamina_max := 100.0


## Prototipin bed'i: aynı adımlar, aynı girdiler; çıktı fikstürün senaryo çıktısının biçimindedir.
func _run_scenario(sc: Dictionary) -> Dictionary:
	var store := NodeStore.new(sc.get("nodes", []))
	var bag := FakeBag.new()
	bag.cap = int(sc.get("cap", 100))
	bag.tools = sc.get("tools", [])
	var sta := FakeStamina.new()
	var g := Gather.new(store, bag)
	g.stamina = sta
	var mods: Dictionary = sc.get("mods", {})
	g.mods = func() -> Dictionary: return mods
	g.foot = int(sc.get("foot", 3))
	var dark := bool(sc.get("dark", false))
	g.dark = func() -> bool: return dark
	g.assist = str(sc.get("assist", "off"))
	g.diff_k = _strike_ring(str(sc.get("diff", "normal")))
	g.first_ring = not bool(sc.get("seen", true))
	var cond: Dictionary = sc.get("cond", {})
	g.cond = func(expr: String) -> bool: return Cond.holds(expr, Cond.DictCtx.new(cond))
	var yk := float(sc.get("yieldK", 1.0))
	g.yield_k = func(_k: String) -> float: return yk
	var out := {"hits": [], "yields": [], "depleted": [], "noise": [], "rings": [], "judged": [], "axes": [], "ledger": [], "toasts": 0}
	g.struck.connect(func(i: int, _info: Dictionary) -> void: (out["hits"] as Array).append(i))
	g.yielded.connect(func(_i: int, item: String, n: int, info: Dictionary) -> void:
		(out["yields"] as Array).append([item, n, info["kind"], info["piled"], info["clean"]]))
	g.depleted.connect(func(i: int, _k: String, _info: Dictionary) -> void: (out["depleted"] as Array).append(i))
	g.noise_made.connect(func(_at: Vector2, r: float) -> void: (out["noise"] as Array).append(r))
	g.swing_started.connect(func(info: Dictionary) -> void:
		if info["ring"]:
			(out["rings"] as Array).append([info["T"], info["window"], info["gold"]]))
	g.ring_judged.connect(func(c: bool, _auto: bool) -> void: (out["judged"] as Array).append(c))
	# Prototipte yalnız yer yığını bildirim yazar (araçsız istem bildirim değil, ui_deny sesidir).
	g.refused.connect(func(r: String, _t: String) -> void:
		if r == "pile":
			out["toasts"] = int(out["toasts"]) + 1)
	g.apply_fx = func(list: Variant, _src: String) -> void:
		for fx: Array in list:
			match str(fx[0]):
				"axis":
					(out["axes"] as Array).append([fx[1], fx[2]])
				"ledger":
					(out["ledger"] as Array).append([fx[1], fx[2]])
				"toast":
					out["toasts"] = int(out["toasts"]) + 1
	for step: Dictionary in sc.get("steps", []):
		if step.has("act"):
			var i := int(step.get("i", 0))
			match str(step["act"]):
				"tap":
					if not (g.state == Gather.State.SWING and g.index == i):
						g.begin(i, false)
				"start":
					g.begin(i, true)
				"complete":
					if g.state == Gather.State.HOLD and g.index == i:
						g.finish_hold()
				"cancel":
					if g.index == i:
						g.cancel()
			continue
		if step.has("dawn"):
			store.on_dawn(int(step["dawn"]))
			continue
		if step.has("restock"):
			store.restock(int(step["restock"][0]), int(step["restock"][1]))
			continue
		if step.has("sta"):
			sta.stamina = float(step["sta"])
			continue
		var axis: Array = step.get("axis", [0, 0])
		var moved := float(axis[0]) != 0.0 or float(axis[1]) != 0.0
		var presses: Array = step.get("press", [])
		var n := roundi(float(step["run"]) / DT)
		for k in n:
			var t := g.t
			var pressed := false
			for at: Variant in presses:
				if absf(t - float(at)) < DT / 2.0:
					pressed = true
			# Prototipin «driven» tutuşunu E'yi süren InteractDriver bitirir: burada E basılı sayılır.
			var held := bool(step.get("held", false)) or (g.state == Gather.State.HOLD and g.driven)
			g.step(DT, pressed, held, moved)
	var items := {}
	var keys: Array = bag.items.keys()
	keys.sort()
	for k: String in keys:
		items[k] = bag.items[k]
	out["items"] = items
	out["stamina"] = sta.stamina
	out["state"] = "idle" if g.state == Gather.State.IDLE else ("swing" if g.state == Gather.State.SWING else "hold")
	out["charges"] = Array(store.charges)
	out["flags"] = Array(store.flags)
	var sh: Array = []
	for i in store.count:
		sh.append(store.hits_of(i))
	out["store_hits"] = sh
	return out


func _strike_ring(diff_id: String) -> float:
	for lv: Dictionary in Catalog.data("character/difficulty").get("levels", []):
		if str(lv.get("id", "")) == diff_id:
			return float(lv.get("strikeRing", 1.0))
	return 1.0


static func _strip(row: Variant) -> Variant:
	if row is Dictionary:
		var d: Dictionary = (row as Dictionary).duplicate(true)
		d.erase("clip")
		for k: String in d.keys():
			d[k] = _strip(d[k])
		return d
	if row is Array:
		var out: Array = []
		for v: Variant in row:
			out.append(_strip(v))
		return out
	return row


# --- Tablo -------------------------------------------------------------------------------------------------------------

func test_fixture_exists_and_comes_from_its_generator() -> void:
	assert_false(_fx.is_empty(), "tests/fixtures/gathering.json")
	if _fx.is_empty():
		return
	assert_eq(str(_fx["meta"]["tool"]), "tools/proto_fixtures/gathering.mjs")
	assert_true(ProtoFixture.count_cases(_fx, "scenario") >= 25, "Durum makinesinin senaryoları")


func test_kind_table_matches_the_prototype() -> void:
	var c: Dictionary = _fx.get("constants", {})
	var kinds := NodeStore.kind_table()
	var proto_ids: Array = c.get("kind_ids", [])
	var ids := Array(NodeStore.ids())
	assert_eq(ids.slice(0, proto_ids.size()), proto_ids, "Tür sırası prototipinkiyle aynı (sıra kimliktir)")
	assert_eq(ids.slice(proto_ids.size()), ["node_woad"], "Prototipten sonra yalnız K58'in çivit otu sona eklendi")
	for id: String in proto_ids:
		var diffs := ProtoFixture.compare(_strip(kinds[id]), c["kinds"][id], 0.0)
		assert_true(diffs.is_empty(), "%s prototipinkiyle aynı: %s" % [id, diffs])
		var back := ProtoFixture.compare(c["kinds"][id], _strip(kinds[id]), 0.0)
		assert_true(back.is_empty(), "%s'te prototipte olmayan alan yok: %s" % [id, back])
	var tools: Dictionary = NodeStore.data()["tools"]
	for tool_id: String in c["tools"]:
		var proto_tool: Dictionary = (c["tools"][tool_id] as Dictionary).duplicate()
		var name: Dictionary = proto_tool.get("name", {})
		proto_tool.erase("name")
		assert_true(ProtoFixture.compare(tools.get(tool_id, {}), proto_tool, 0.0).is_empty(), "Araç %s (§3.3)" % tool_id)
		# Eşya kataloğu demir bıçağı hikâyenin adıyla yazar («Kendi Bıçağın», sq_iron_tooth); öteki araçların adı prototipinkidir.
		if tool_id != "knife_iron":
			assert_eq([ItemCatalog.name_of(tool_id, "tr"), ItemCatalog.name_of(tool_id, "en")], [name.get("tr"), name.get("en")], "%s'in adı eşya kataloğunda" % tool_id)
	assert_eq(tools.size(), (c["tools"] as Dictionary).size())
	var g: Dictionary = NodeStore.constants()
	assert_true(ProtoFixture.compare(g, c["gather"], 0.0).is_empty(), "GATHER sabitleri")
	assert_eq(float(g["reach"]), 2.1, "GATHER_REACH 2,1 m (MOUNT_REACH ile aynı)")
	assert_true(ProtoFixture.compare(NodeStore.data()["child"], c["child"], 0.0).is_empty(), "Çocuğun sınırları")
	assert_true(ProtoFixture.compare(NodeStore.placement("hexi_winter"), c["act1_nodes"], 0.0).is_empty(), "I. Perde yerleşimi (§3.5)")
	assert_true(ProtoFixture.compare(NodeStore.placement("tanhu_camp"), c["camp_nodes"], 0.0).is_empty(), "Ana kampın kütüğü")
	assert_eq(int(NodeStore.data()["nodesV"]), int(c["nodes_v"]))
	assert_eq(NodeStore.data()["dynamicKinds"], c["dynamic"])


func test_kind_rows_are_well_formed_and_agree_with_the_item_catalog() -> void:
	var clips: Dictionary = NodeStore.data()["clips"]
	for id: String in NodeStore.kind_table():
		var row: Dictionary = NodeStore.kind_row(id)
		for key in ["name", "prompt"]:
			assert_false(Catalog.pick(row.get(key), "tr").is_empty() or Catalog.pick(row.get(key), "en").is_empty(), "%s.%s TR ve EN" % [id, key])
		assert_true(str(row.get("action", "")) in ["strike", "hold"], "%s.action" % id)
		assert_true(str(row.get("renew", "")) in ["perm", "dawn", "none"], "%s.renew" % id)
		for st: Variant in [row, row.get("then"), row.get("alt")]:
			if not st is Dictionary:
				continue
			for y: Dictionary in (st as Dictionary).get("yield", []):
				assert_true(ItemCatalog.has(str(y["item"])), "%s verimi «%s» eşya kataloğunda" % [id, y["item"]])
			for s: Variant in (st as Dictionary).get("seqItems", []) if (st as Dictionary).get("seqItems") is Array else []:
				assert_true(ItemCatalog.has(str(s)), "%s sıralı verimi «%s»" % [id, s])
			for key in ["tool", "fixed", "toolAlt"]:
				var tool_id: Variant = (st as Dictionary).get(key)
				if tool_id != null:
					assert_true(ItemCatalog.has(str(tool_id)), "%s.%s «%s» eşya kataloğunda" % [id, key, tool_id])
					assert_false(NodeStore.tool_row(str(tool_id)).is_empty(), "%s.%s araç tablosunda" % [id, key])
		if row.has("clip"):
			assert_true(clips.has(str(row["clip"])), "%s klibi tanımlı" % id)
	for key: String in clips:
		assert_false(ClipVariety.library().clip(str(clips[key])).is_empty(), "Tutuşun klibi kütüphanede: %s" % clips[key])
	# Eşya kataloğunun araç satırındaki vuruş sayıları (tool.hits) kademe kuralıyla aynı.
	for tool_id: String in NodeStore.data()["tools"]:
		var hits: Dictionary = (ItemCatalog.tool_of(tool_id).get("hits", {}) as Dictionary)
		for kind_id: String in hits:
			var row := NodeStore.kind_row(kind_id)
			var st: Dictionary = row["then"] if row.get("then") is Dictionary and str((row["then"] as Dictionary).get("action", "")) == "strike" else row
			assert_eq(Gather.strike_hits(st, tool_id), int(hits[kind_id]), "%s ile %s: eşya kataloğu ve kademe kuralı" % [tool_id, kind_id])
	for key: String in ["need_tool", "pile_left", "clean", "gain"]:
		assert_false(NodeStore.message(key, "en") == key, "İleti: %s" % key)


# --- Sayı yardımcıları ve yerleşim ---------------------------------------------------------------------------------------

func test_hash_noise_rng_and_base64_match_the_prototype() -> void:
	var n := ProtoFixture.run_cases(self, _fx, {
		"hash32": func(a: Array) -> Variant: return NodeStore.hash32(int(a[0]), int(a[1])),
		"noise2": func(a: Array) -> Variant: return NodeStore.noise2(float(a[0]), float(a[1])),
		"fbm2": func(a: Array) -> Variant: return NodeStore.fbm2(float(a[0]), float(a[1]), int(a[2])),
		"rng": func(a: Array) -> Variant:
			var r := WeatherRng.new(int(a[0]))
			var out: Array = []
			for k in int(a[1]):
				out.append(r.next())
			return out,
		"base64": func(a: Array) -> Variant: return NodeStore.to_base64(PackedByteArray(a[0])),
	}, PackedStringArray(["hash32", "noise2", "fbm2", "rng", "base64"]))
	assert_true(n >= 25, "Sayı yardımcılarının durumları: %d" % n)
	assert_eq(Array(NodeStore.from_base64("AQIDBA==", 4)), [1, 2, 3, 4])
	assert_eq(Array(NodeStore.from_base64(42, 3)), [0, 0, 0], "Yazı olmayan perm sıfırdır")


func test_act1_placement_matches_the_prototype_bit_for_bit() -> void:
	var t0 := Time.get_ticks_usec()
	var store := NodeStore.new(NodeStore.placement("hexi_winter"))
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	print("[gathering] I. Perde yerleşimi: %d kayıt, %.0f ms" % [store.count, ms])
	var n := ProtoFixture.run_cases(self, _fx, {
		"placement": func(_a: Array) -> Variant:
			var h := 0
			for i in store.count:
				h = (h * 31 + NodeStore.js_round(store.x[i] * 10.0) * 7 + NodeStore.js_round(store.z[i] * 10.0)) % 1000000007
			var sample: Array = []
			for i: int in [0, 1, 2, 3, 100, 419, 420, 500, 1319, 1320, 1400, 1700, 2000, 2500, 3000, 3261, 3262, 3269]:
				sample.append([i, store.kind_of(i), store.x[i], store.z[i], store.yaw[i], store.scale[i], store.tone[i]])
			var queries: Array = []
			for bx: Array in [[380, -40, 480, 60], [-400, -600, -100, -300], [0, 0, 1, 1], [-60, -200, 160, -140]]:
				var got := Array(store.query(bx[0], bx[1], bx[2], bx[3]))
				got.sort()
				var sum := 0
				for i: int in got:
					sum = (sum * 33 + i) % 1000000007
				queries.append([bx, got.size(), got.slice(0, 12), sum])
			return {"count": store.count, "by_kind": store.count_by_kind(), "hash": h, "sample": sample, "cx0": store.cx0, "cz0": store.cz0,
				"cw": store.cw, "ch": store.ch, "chunk_start": Array(store.chunk_start), "queries": queries},
		"placement_seed": func(a: Array) -> Variant:
			var s1 := NodeStore.new(NodeStore.placement(str(a[0])), {"seed": int(a[1])})
			var out: Array = []
			for i: Variant in a[2]:
				out.append([s1.x[int(i)], s1.z[int(i)], s1.tone[int(i)]])
			return out,
		"placement_reject": func(a: Array) -> Variant:
			var b: Array = a[0]
			var rj := NodeStore.new([{"id": "r", "kind": "node_reed", "at": [0, 0], "r": 12, "n": 30}, {"id": "p", "kind": "node_pine", "at": [20, 0], "r": 6, "n": 8}],
				{"seed": int(a[1]), "reject": func(px: float, pz: float, _k: String) -> bool: return px >= b[0] and px <= b[2] and pz >= b[1] and pz <= b[3]})
			var out: Array = []
			for i in rj.count:
				out.append([rj.x[i], rj.z[i]])
			return out,
	}, PackedStringArray(["placement", "placement_seed", "placement_reject"]))
	assert_eq(n, 3, "Yerleşimin üç durumu")
	assert_eq(store.count, 3270, "economy.md §3.5: 3.270 kayıt (dinamikler hariç)")
	assert_true(ms < 2000.0, "Yerleşim kurulumu ≤2 sn (%.0f ms)" % ms)


func test_consume_dawn_save_and_apply_taken_match_the_prototype() -> void:
	var n := ProtoFixture.run_cases(self, _fx, {
		"consume_dawn": func(a: Array) -> Variant:
			var st := NodeStore.new(NodeStore.placement("hexi_winter"))
			var ix: Dictionary = a[0]
			var pine := int(ix["pine"])
			var reed := int(ix["reed"])
			var juniper := int(ix["juniper"])
			var boulder := int(ix["boulder"])
			var woodpile := int(ix["woodpile"])
			var log: Array = [["consume", pine, st.consume(pine)]]
			for k in 3:
				log.append(["consume", reed, st.consume(reed)])
			for k in 3:
				log.append(["consume", juniper, st.consume(juniper)])
			log.append(["hit", juniper, st.add_hit(juniper)])
			log.append(["hit", juniper, st.add_hit(juniper)])
			st.consume(boulder)
			st.consume(boulder)
			for k in 16:
				st.consume(woodpile)
			var before := st.to_dict()
			var dawn1 := st.on_dawn(1042)
			var after := st.to_dict()
			for k in 4:
				log.append(["consume", juniper, st.consume(juniper)])
			st.on_dawn(1043)
			var states: Array = []
			for i: int in [pine, reed, juniper, boulder, woodpile]:
				states.append([st.charges[i], st.flags[i], st.available(i)])
			return {"log": log, "before": before, "renewed": dawn1["renewed"], "after": after, "final": st.to_dict(), "states": states},
		"dawn_weather": func(a: Array) -> Variant:
			var f := NodeStore.new(NodeStore.placement("hexi_winter"))
			var ids: Array[int] = []
			for i in f.count:
				if f.kind_of(i) == "node_mushroom":
					ids.append(i)
			var renew := func(wet: bool) -> Callable:
				return func(k: String) -> float: return (2.0 if wet else 0.5) if (NodeStore.kind_row(k).get("weather", {}) as Dictionary).has("wet") else 1.0
			f.on_dawn(int(a[0]), renew.call(false))
			var dry: Array = []
			for i in ids:
				dry.append(1 if f.available(i) else 0)
			f.on_dawn(int(a[1]), renew.call(true))
			var wet: Array = []
			for i in ids:
				wet.append(f.charges[i])
			return {"dry": dry, "wet": wet},
		"save": func(_a: Array) -> Variant:
			var sv := NodeStore.new(NodeStore.placement("hexi_winter"))
			var pines: Array[int] = []
			for i in sv.count:
				if sv.kind_of(i) == "node_pine" and pines.size() < 40:
					pines.append(i)
			for i in pines:
				sv.consume(i)
			var sb := func(k: String) -> int:
				for i in sv.count:
					if sv.kind_of(i) == k:
						return i
				return -1
			sv.consume(sb.call("node_boulder"))
			sv.consume(sb.call("node_reed"))
			for k in 3:
				sv.consume(sb.call("node_juniper"))
			sv.add_hit(sb.call("node_juniper"))
			sv.add_hit(int(sb.call("node_reed")) + 7)
			sv.next_seq(sb.call("node_kitchen_scraps"))
			sv.next_seq(sb.call("node_kitchen_scraps"))
			sv.mark_struck(int(sb.call("node_pine")) + 500)
			var saved := sv.to_dict()
			# Kayıt JSON'dan döner (sayılar float okunur).
			var back := NodeStore.new(NodeStore.placement("hexi_winter"))
			back.from_dict(JSON.parse_string(JSON.stringify(saved)))
			assert_eq(back.to_dict(), saved, "Kayıt gidiş dönüşü aynı")
			var stale := NodeStore.new(NodeStore.placement("hexi_winter"))
			stale.from_dict(saved, false)
			var broken := NodeStore.new(NodeStore.placement("hexi_winter"))
			broken.from_dict({"perm": 42, "part": "x", "day": [[-1, 2], ["a"]], "piles": [{"x": "n"}]})
			return {"saved": saved, "stale": stale.to_dict(), "broken": broken.to_dict()},
		"apply_taken": func(_a: Array) -> Variant:
			var at := NodeStore.new(NodeStore.placement("hexi_winter"))
			var taken := at.apply_taken("a1_cut_yard", 100)
			var once := at.to_dict()
			at.apply_taken("a1_cut_yard", 100)
			var again := at.to_dict()
			var order := Array(at.order_of("a1_cut_yard"))
			var sum := 0
			for i: int in order:
				sum = (sum * 31 + i) % 1000000007
			var reeds := NodeStore.new(NodeStore.placement("hexi_winter"))
			reeds.apply_taken("a1_west_reeds", 30)
			var willow := NodeStore.new(NodeStore.placement("hexi_winter"))
			willow.apply_taken("a1_ford_willow", 3)
			var wo := willow.order_of("a1_ford_willow")
			var mixed := NodeStore.new(NodeStore.placement("hexi_winter"))
			return {"taken": taken, "perm_once": once["perm"], "same_again": once["perm"] == again["perm"], "order_head": order.slice(0, 30),
				"order_len": order.size(), "order_sum": sum, "reed_order": Array(reeds.order_of("a1_west_reeds").slice(0, 12)),
				"reed_json": reeds.to_dict()["day"], "willow": [wo[0], willow.flags[wo[0]], wo[1], willow.flags[wo[1]], willow.charges[wo[1]]],
				"unknown": mixed.apply_taken("no_such_cluster", 5), "by_kind": Array(mixed.order_of("a1_slope", "node_pine").slice(0, 8))},
	}, PackedStringArray(["consume_dawn", "dawn_weather", "save", "apply_taken"]))
	assert_eq(n, 4)


func test_nearest_and_query_use_the_chunk_index() -> void:
	var store := NodeStore.new([{"id": "r", "kind": "node_reed", "at": [10, 10], "r": 3, "n": 6}, {"id": "p", "kind": "node_pine", "at": [150, 40]},
		{"id": "b", "kind": "node_boulder", "at": [-120, -80]}])
	assert_eq(store.count, 8)
	assert_true(store.cw >= 3 and store.ch >= 2, "Parçalar 100 m: %d × %d" % [store.cw, store.ch])
	assert_eq(store.query(140.0, 30.0, 160.0, 50.0).size(), 1, "Kutudaki çam")
	var near := store.nearest(150.0, 41.0, 2.1)
	assert_eq(store.kind_of(near), "node_pine", "En yakın işlenebilir düğüm")
	store.consume(near)
	assert_eq(store.nearest(150.0, 41.0, 2.1), -1, "Kesilen çam sunulmaz")
	assert_eq(store.nearest(-119.0, -80.0, 1.2), 7, "Kayanın yarıçapı erişime katılır (r 0,9)")


# --- Toplama --------------------------------------------------------------------------------------------------------------

func test_strike_math_matches_the_prototype() -> void:
	var n := ProtoFixture.run_cases(self, _fx, {
		"strike_t": func(a: Array) -> Variant: return Gather.strike_t(float(a[0]), float(a[1]), bool(a[2])),
		"ring_window": func(a: Array) -> Variant: return Gather.ring_window(a[0], float(a[1]), str(a[2])),
		"ring_judge": func(a: Array) -> Variant: return Gather.ring_judge(float(a[0]), float(a[1]), float(a[2])),
		"strike_hits": func(_a: Array) -> Variant:
			var out := {}
			for id: String in NodeStore.kind_table():
				var row := NodeStore.kind_row(id)
				for st: Variant in [row, row.get("then"), row.get("alt")]:
					if not st is Dictionary or str((st as Dictionary).get("action", "")) != "strike":
						continue
					for tool: String in ["", "axe_bronze", "axe_iron", "pick_bronze", "pick_iron", "knife_iron", "site_axe", "site_wedge"]:
						out["%s%s|%s" % [id, ".then" if st == row.get("then") else "", tool]] = Gather.strike_hits(st, tool)
			return out,
	}, PackedStringArray(["strike_t", "ring_window", "ring_judge", "strike_hits"]))
	assert_true(n >= 20)
	assert_eq(Gather.ring_window(null, _strike_ring("hard")), 0.18 * 0.8, "Zor: pencere ×0,8 (difficulty.json strikeRing)")


func test_gather_scenarios_match_the_prototype() -> void:
	var n := ProtoFixture.run_cases(self, _fx, {"scenario": func(a: Array) -> Variant: return _run_scenario(a[0])}, PackedStringArray(["scenario"]))
	assert_true(n >= 25, "Senaryo sayısı: %d" % n)


func test_offer_texts_and_tools() -> void:
	var store := NodeStore.new([{"kind": "node_pine", "at": [1, 0]}, {"kind": "node_ice_hole", "at": [0, 1]}, {"kind": "node_bone_pile", "at": [2, 2]}])
	var bag := FakeBag.new()
	var g := Gather.new(store, bag)
	var o := g.offer(0)
	assert_eq(str(o["label"]), "Kes")
	assert_false(o["enabled"], "Baltasız istem kapalı")
	assert_eq(str(o["deny"]), "Önce Tunç Balta gerek")
	g.lang = "en"
	assert_eq(str(g.offer(0)["deny"]), "You need Bronze Axe")
	g.lang = "tr"
	var denied := watch_signal(g.refused)
	assert_false(g.begin(0), "Araç yoksa iş başlamaz")
	assert_eq(denied.count, 1)
	assert_eq(str(g.offer(1)["label"]), "Buz Kes", "Ağ yoksa buz deliği buz keser")
	bag.tools = ["net"]
	assert_eq(str(g.offer(1)["label"]), "Ağ At", "Ağ varsa önce Ağ At")
	assert_true(g.offer(2).is_empty(), "Hereka izni yoksa Çukur Kemikleri sunulmaz")
	g.cond = func(expr: String) -> bool: return Cond.holds(expr, Cond.DictCtx.new({"ties.hereka": 1}))
	assert_eq(str(g.offer(2)["label"]), "Al")
	g.riding = true
	assert_true(g.offer(0).is_empty(), "Atlıyken çam sunulmaz (K46: yalnız eğilip alınanlar)")
	var mounted := NodeStore.new([{"kind": "node_dung", "at": [0, 0]}])
	var gm := Gather.new(mounted, bag)
	gm.riding = true
	assert_almost(float(gm.offer(0)["hold"]), 3.0, 1e-9, "At üstünde tutuş ×1,5")
	gm.mods = func() -> Dictionary: return {"rideGather": true}
	assert_almost(float(gm.offer(0)["hold"]), 2.0, 1e-9, "Dizle Sürme ile ×1")


func test_gather_with_the_real_inventory_spills_to_a_ground_pile() -> void:
	var inv := Inventory.new()
	inv.add("axe_bronze", 1, "kit")
	var store := NodeStore.new([{"kind": "node_pine", "at": [1, 0]}, {"kind": "node_pine", "at": [0, 1]}])
	var g := Gather.new(store, inv)
	g.spill_at = func(i: int) -> Vector3: return store.position_of(i) + Vector3(0.6, 0.0, 0.0)
	var got: Array = []
	g.yielded.connect(func(_i: int, item: String, n: int, info: Dictionary) -> void: got.append([item, n, info["piled"]]))
	var piles := watch_signal(inv.pile_changed)
	assert_true(g.begin(0, true))
	for k in roundi(5.3 / DT):
		g.step(DT, false, true, false)
	assert_eq(got, [["wood_pine", 3, 0]], "3 odun Heybe'ye (12 Yük, sınır 21)")
	assert_eq(inv.count("wood_pine"), 3)
	assert_eq(store.flags[0] & NodeStore.F_PERM, NodeStore.F_PERM, "Kesilen çam kalıcı")
	# İkinci ağaç: 24 Yük Heybe'ye sığmaz; 2 odun Heybe'ye girer (20 Yük), 1'i ağacın dibinde yer yığınına.
	got.clear()
	var texts: Array = []
	g.refused.connect(func(_r: String, t: String) -> void: texts.append(t))
	assert_true(g.begin(1, true))
	for k in roundi(5.3 / DT):
		g.step(DT, false, true, false)
	assert_eq(got, [["wood_pine", 3, 1]], "Sığmayan yer yığınına: %s" % [got])
	assert_eq(inv.count("wood_pine"), 5, "Heybede 5 odun (20 Yük)")
	assert_eq(inv.piles().size(), 1, "Bir yer yığını")
	assert_true(piles.count >= 1)
	assert_eq(texts, ["Yük dolu · Kalanı yerde"])
	var pile: ItemContainer = inv.piles()[0]
	assert_eq(pile.count("wood_pine"), 1)
	assert_true(inv.pile_position(pile).distance_to(store.position_of(1) + Vector3(0.6, 0.0, 0.0)) < 0.01, "Yığın düğümün dibinde")



func test_overflow_goes_to_the_nearby_horse_saddlebags_before_the_ground() -> void:
	var inv := Inventory.new()
	inv.add("axe_bronze", 1, "kit")
	inv.add("stone", 3, "dev")
	var store := NodeStore.new([{"kind": "node_pine", "at": [1, 0]}])
	var g := Gather.new(store, inv)
	g.spill_at = func(i: int) -> Vector3: return store.position_of(i)
	# Yakındaki at (sürücü HUD'un aktarma anahtarını verir): Heybe'ye sığmayan terkiye, terki 1 odunluk.
	g.mount_key = func() -> String: return "horse@Doru"
	inv.saddlebags("horse@Doru", 4.0)
	var got: Array = []
	g.yielded.connect(func(_i: int, item: String, n: int, info: Dictionary) -> void: got.append([item, n, info["piled"]]))
	assert_true(g.begin(0, true))
	for k in roundi(5.3 / DT):
		g.step(DT, false, true, false)
	var bag := inv.saddlebags("horse@Doru")
	assert_eq(inv.count("wood_pine"), 1, "Heybe'ye 1 odun (3 taş 15 Yük, odunla 19; sınır 21)")
	assert_eq(bag.count("wood_pine"), 1, "Sığmayanın biri atın terkisine")
	assert_eq(inv.piles().size(), 1, "Terkiye de sığmayan yer yığınına")
	assert_eq((inv.piles()[0] as ItemContainer).count("wood_pine"), 1)
	assert_eq(got, [["wood_pine", 3, 1]], "Verim 3; yığına 1: %s" % [got])

func test_clean_strike_skill_and_xp_come_from_progression() -> void:
	var p := Progression.new()
	p.reset_player("")
	assert_eq(p.award("gather", {"kind": "node_pine"}), 0, "Ham toplama XP vermez (progression.json xp.zero)")
	var store := NodeStore.new([{"kind": "node_pine", "at": [1, 0]}])
	var bag := FakeBag.new()
	bag.tools = ["axe_bronze"]
	var g := Gather.new(store, bag)
	g.mods = p.mods
	g.award = p.award
	var windows: Array = []
	g.swing_started.connect(func(info: Dictionary) -> void: windows.append(info["window"]))
	g.begin(0, false)
	assert_almost(float(windows[0]), 0.18, 1e-9, "Becerisiz pencere 0,18 sn")
	g.cancel()
	# Tam Vuruş'u Kujul öğretir (sq_iron_tooth), seviye 3 (tier 2).
	p.set_flag("quest:sq_iron_tooth.done", true)
	p.add_xp(800)
	p.skill_points = 3
	assert_true(p.learn("clean_strike"), "Tam Vuruş öğrenildi: %s" % p.skill_state("clean_strike"))
	windows.clear()
	store.clear_hits(0)
	g.begin(0, true)
	for k in roundi(5.3 / DT):
		var pressed := absf(g.t - 0.72) < DT / 2.0
		g.step(DT, pressed, true, false)
	assert_almost(float(windows[0]), 0.3, 1e-9, "clean_strike: pencere 0,30")
	assert_eq(int(bag.items.get("wood_pine", 0)), 4, "Temiz son vuruş +1 kesin (cleanBonus 1)")
	assert_eq(p.xp, 800, "Toplama XP vermedi")


# --- Kayıt bloğu ------------------------------------------------------------------------------------------------------------

func test_economy_block_round_trip_and_carry() -> void:
	var eco := Economy.new()
	var store := NodeStore.new([{"id": "r", "kind": "node_reed", "at": [0, 0], "r": 4, "n": 5}, {"id": "p", "kind": "node_pine", "at": [10, 0]}])
	eco.attach_store("testmap", store)
	store.consume(5)
	store.consume(0)
	store.add_hit(1)
	var ws := Workshop.new({"id": "wood_shop_1", "station": "wood_shop"})
	var chest := ItemContainer.make("chest", {"id": "bench_wood"})
	chest.add("wood_pine", 4)
	eco.attach_workshop(ws, chest)
	ws.order("rc_uuk_set", 1)
	eco.note_crafted("rc_rope")
	var blocks := SaveBlocks.new()
	assert_true(eco.register(blocks), "«economy» bloğu kaydedildi")
	var record: Dictionary = JSON.parse_string(JSON.stringify(blocks.collect()))
	var d: Dictionary = record["economy"]
	assert_eq(int(d["v"]), 1)
	assert_true(JSON.stringify(d).length() <= Economy.MAX_BYTES, "Blok ≤6 KB")
	assert_eq(Economy.validate_save_block(d), "")
	assert_ne(Economy.validate_save_block({"nodes": 3}), "", "Bozuk blok yakalanır")
	# Yeni oturum: blok okunur, harita kurulunca düğüm durumu ona geçer.
	var eco2 := Economy.new()
	var blocks2 := SaveBlocks.new()
	eco2.register(blocks2)
	assert_eq(blocks2.apply(record), "", "Kayıt okunur")
	var store2 := NodeStore.new([{"id": "r", "kind": "node_reed", "at": [0, 0], "r": 4, "n": 5}, {"id": "p", "kind": "node_pine", "at": [10, 0]}])
	eco2.attach_store("testmap", store2)
	assert_false(store2.available(5), "Kesilen çam kayıttan döndü")
	assert_eq(store2.charges[0], 2, "Saz hakkı kayıttan döndü")
	assert_eq(store2.hits_of(1), 1, "Vuruş ilerlemesi şafağa dek kalır")
	var ws2 := Workshop.new({"id": "wood_shop_1", "station": "wood_shop"})
	var chest2 := ItemContainer.make("chest", {"id": "bench_wood"})
	eco2.attach_workshop(ws2, chest2)
	assert_eq(ws2.queue.size(), 1, "Tezgâhın kuyruğu döndü")
	assert_eq(chest2.count("wood_pine"), 4, "Sandığın içeriği döndü")
	assert_true(eco2.crafted.has("rc_rope"))
	# Harita bırakılınca durum taşınır; şafakta taşınan günlük durum düşer, kalıcı bit kalır.
	eco2.detach_store("testmap")
	eco2.on_dawn(1172)
	var store3 := NodeStore.new([{"id": "r", "kind": "node_reed", "at": [0, 0], "r": 4, "n": 5}, {"id": "p", "kind": "node_pine", "at": [10, 0]}])
	eco2.attach_store("testmap", store3)
	assert_false(store3.available(5), "Kalıcı bit taşındı")
	assert_eq(store3.charges[0], 3, "Şafak geçti: saz yenilendi")
	assert_eq(store3.hits_of(1), 0, "Şafak geçti: vuruş ilerlemesi silindi")


## Oturumun Tan'ı gibi: dawn sinyali ve yolculuk (Session'ın yalnız bu iki yüzü).
class FakeSession:
	extends RefCounted
	signal dawn(info: Dictionary)
	var journey := Journey.new()


func test_session_dawn_renews_nodes_until_the_last_night() -> void:
	var eco := Economy.new()
	var store := NodeStore.new([{"id": "r", "kind": "node_reed", "at": [0, 0], "r": 4, "n": 5}])
	eco.attach_store("testmap", store)
	store.consume(0)
	var s := FakeSession.new()
	eco.bind_session(s)
	eco.bind_session(s)
	assert_eq(s.get_signal_connection_list(&"dawn").size(), 1, "Tan'a bir kez bağlanır")
	s.dawn.emit({"day_n": 12})
	assert_eq(store.charges[0], 3, "Oturumun Tan'ı sazı yeniler")
	# Son Gece'den sonra (yolculuk bayrağı) Tan bir şey yenilemez.
	store.consume(0)
	s.journey.set_flag(eco.stop_flag)
	s.dawn.emit({"day_n": 13})
	assert_eq(store.charges[0], 2, "Son Gece'den sonra düğüm dönmez")
	# Türün katsayısı (hava verir): k ≥ 1 hakkı çarpar.
	s.journey.flags.clear()
	eco.renew_k = func(kind_id: String) -> float: return 2.0 if kind_id == "node_reed" else 1.0
	s.dawn.emit({"day_n": 14})
	assert_eq(store.charges[0], 6, "Katsayı ×2: saz hakkı 3 × 2")
