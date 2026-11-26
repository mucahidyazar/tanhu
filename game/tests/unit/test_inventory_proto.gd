extends TestCase
## Envanterin prototip fikstürü (godot.md §8.2, K29): tests/fixtures/inventory.json'u tools/proto_fixtures/inventory.mjs prototipin
## container.js, items.js ve inventory.js'inden yazar (çalıştırıcı: node tools/proto_fixtures.mjs --only=inventory); burada aynı
## işlemler ItemContainer ve Inventory üstünde koşar (ProtoFixture.run_cases). Sayılar 1e-9, tamsayı ve kimlik tam eşit. Değişen kural
## fikstüre girmez (bkz. aracın başı). Hata ekleme: bir beklenen değer bozulunca durum düşer.

const ProtoFixture := preload("res://tests/support/proto_fixture.gd")

var _fx: Dictionary = {}


func before_each() -> void:
	if _fx.is_empty():
		_fx = ProtoFixture.load_fixture("inventory")


func _handlers() -> Dictionary:
	return {
		"stack_load10": func(a: Array) -> Variant: return ItemCatalog.stack_load10(str(a[0]), int(a[1])),
		"tab_of": func(a: Array) -> Variant: return [ItemCatalog.tab_of(str(a[0])), ItemCatalog.uses_slot(str(a[0]))],
		"matches": func(a: Array) -> Variant: return ItemCatalog.matches(str(a[0]), str(a[1])),
		"container_ops": func(d: Dictionary) -> Variant: return _container_ops(d),
		"inventory_ops": func(d: Dictionary) -> Variant: return _inventory_ops(d),
	}


func test_fixture_is_there() -> void:
	assert_false(_fx.is_empty(), "tests/fixtures/inventory.json")
	assert_eq(str(_fx.get("meta", {}).get("tool", "")), "tools/proto_fixtures/inventory.mjs", "Üreticisi alan düzeninde")
	assert_eq(ProtoFixture.count_cases(_fx, "container_ops"), 6, "Altı kap senaryosu")
	assert_eq(ProtoFixture.count_cases(_fx, "inventory_ops"), 10, "On heybe senaryosu")


func test_item_rules_match_the_prototype() -> void:
	var n := ProtoFixture.run_cases(self, _fx, _handlers(), PackedStringArray(["stack_load10", "tab_of", "matches"]))
	assert_true(n >= 25, "Eşya durumları (%d)" % n)


func test_containers_match_the_prototype() -> void:
	assert_eq(ProtoFixture.run_cases(self, _fx, _handlers(), PackedStringArray(["container_ops"])), 6)


func test_inventory_matches_the_prototype() -> void:
	assert_eq(ProtoFixture.run_cases(self, _fx, _handlers(), PackedStringArray(["inventory_ops"])), 10)


func test_a_broken_expectation_is_caught() -> void:
	# Hata ekleme denemesi: tek bir beklenen değer bozulunca o durum düşer.
	var broken: Dictionary = _fx.duplicate(true)
	for c: Dictionary in broken.get("cases", []):
		if c["id"] == "inventory/speed":
			(c["out"] as Array)[5] = 0.86
	var sink := _Sink.new()
	ProtoFixture.run_cases(sink, broken, _handlers(), PackedStringArray(["inventory_ops"]))
	assert_eq(sink.failures.size(), 1, "Yarı yükte hız 0,85: bozulan 0,86 yakalanır (%s)" % [sink.failures])


class _Sink:
	extends RefCounted
	var failures: Array[String] = []

	func fail(message: String) -> void:
		failures.append(message)


func _container_ops(d: Dictionary) -> Array:
	var boxes := {}
	for box_name: Variant in d["boxes"]:
		var def: Dictionary = d["boxes"][box_name]
		var opts := {}
		if def.has("cap10"):
			opts["cap10"] = int(def["cap10"])
		if def.has("accept"):
			opts["accept"] = def["accept"]
		boxes[box_name] = ItemContainer.make(str(def["kind"]), opts)
	var out: Array = []
	for op: Array in d["ops"]:
		out.append(_container_op(boxes, op))
	return out


func _container_op(boxes: Dictionary, op: Array) -> Variant:
	var kind := str(op[0])
	var c: ItemContainer = boxes[op[1]]
	match kind:
		"add":
			return c.add(str(op[2]), int(op[3]))
		"add_over":
			return c.add(str(op[2]), int(op[3]), ItemContainer.NO_DAY, true)
		"add_day":
			return c.add(str(op[2]), int(op[3]), int(op[4]))
		"can_take":
			return c.can_take(str(op[2]), int(op[3]))
		"free10":
			return c.free10()
		"load10":
			return c.load10()
		"slots_used":
			return c.slots_used()
		"count":
			return c.count(str(op[2]))
		"list":
			return c.list()
		"days_of":
			return c.days_of(str(op[2]))
		"remove":
			return c.remove(str(op[2]), int(op[3]))
		"on_dawn":
			return c.on_dawn(int(op[2]), bool(op[3]))
		"to_json":
			# Godot eklenme sırasını da yazar (order; prototipte yok): fazladan anahtar karşılaştırmada serbesttir.
			return c.to_dict()
		"transfer":
			return ItemContainer.transfer(c, boxes[op[2]], str(op[3]), int(op[4]))
		"transfer_unpack":
			return ItemContainer.transfer(c, boxes[op[2]], str(op[3]), int(op[4]), false, Callable(), true)
		"transfer_all":
			var opts: Variant = op[4] if op.size() > 4 else null
			var tag := str((opts as Dictionary).get("filter_tag", "")) if opts is Dictionary else ""
			var filter := Callable() if tag.is_empty() else func(item_id: String) -> bool: return ItemCatalog.matches(item_id, tag)
			return ItemContainer.transfer_all(c, boxes[op[2]], op[3], filter)
	fail("bilinmeyen kap işlemi: %s" % kind)
	return null


func _inventory_ops(d: Dictionary) -> Array:
	var setup: Dictionary = d["setup"]
	var inv := Inventory.new(Inventory.BODY_ADULT, int(setup.get("day", 0)))
	var cap := float(setup["cap"])
	inv.cap_source = func() -> float: return cap
	# Prototipin slowFrom 0,5'i Sırt Yükü becerisidir (sınırı burada cap_source verir).
	inv.carry_pack = float(setup.get("slowFrom", 0.0)) > 0.0
	var out: Array = []
	for op: Array in d["ops"]:
		out.append(_inventory_op(inv, op))
	return out


func _inventory_op(inv: Inventory, op: Array) -> Variant:
	var kind := str(op[0])
	match kind:
		"capacity":
			return inv.capacity()
		"load":
			return inv.load_amount()
		"loadFrac":
			return inv.load_frac()
		"speedK":
			return inv.speed_k()
		"canRun":
			return inv.can_run()
		"canJump":
			return inv.can_jump()
		"add":
			return inv.add(str(op[1]), int(op[2]))
		"add_over":
			return inv.add(str(op[1]), int(op[2]), "", true)
		"add_mount":
			var r := inv.receive(str(op[1]), int(op[2]), "", {"mount": str(op[3])})
			return {"added": r["added"], "rest": r["rest"]}
		"remove":
			return inv.remove(str(op[1]), int(op[2]))
		"count":
			return inv.count(str(op[1]))
		"has":
			return inv.has(str(op[1]))
		"has_tool":
			return inv.has_tool(str(op[1]))
		"tab":
			return inv.tab(str(op[1]))
		"slotsUsed":
			return inv.pack.slots_used()
		"slotsFree":
			return inv.pack.slots_free()
		"pack_count":
			return inv.pack.count(str(op[1]))
		"pack_days":
			return inv.pack.days_of(str(op[1]))
		"pack_list_sorted":
			var ids: Array = inv.pack.list().map(func(it: Dictionary) -> String: return str(it["id"]))
			ids.sort()
			return ids
		"equip":
			return inv.equip(str(op[1]), str(op[2]))
		"unequip":
			return _null_if_empty(inv.unequip(str(op[1])))
		"equipped":
			return _null_if_empty(inv.equipped(str(op[1])))
		"equipment":
			var eq_out := {}
			var eq := inv.equipment()
			for slot: Variant in eq:
				eq_out[slot] = _null_if_empty(str(eq[slot]))
			return eq_out
		"gear":
			var g := inv.gear_block()
			return {"dr": g["dr"], "statBonus": g["statBonus"], "load": g["load"], "noise": g["noise"], "visMul": g["visMul"],
				"snowSpeed": g["snowSpeed"], "trackMul": g["trackMul"], "quiverCap": g["quiverCap"], "bow": _null_if_empty(str(g["bow"]))}
		"quiverCap":
			return inv.quiver_cap()
		"fillQuiver":
			return inv.fill_quiver()
		"spendArrow":
			return inv.spend_arrow(str(op[1]))
		"arrows":
			return inv.arrows.duplicate()
		"sled_add":
			return inv.sled.add(str(op[1]), int(op[2]))
		"sledOn":
			inv.sled_on = bool(op[1])
			return null
		"bag_cap":
			return inv.saddlebags(str(op[1])).cap()
		"bag_count":
			return inv.saddlebags(str(op[1])).count(str(op[2]))
		"bag_load":
			return inv.saddlebags(str(op[1])).load_amount()
		"bag_add":
			return inv.saddlebags(str(op[1])).add(str(op[2]), int(op[3]))
		"chest_add":
			return inv.chest.add(str(op[1]), int(op[2]))
		"chest_add_day":
			return inv.chest.add(str(op[1]), int(op[2]), inv.day)
		"chest_empty":
			return inv.chest.is_empty()
		"stash_add":
			return inv.stash(str(op[1])).add(str(op[2]), int(op[3]))
		"cache_add":
			return inv.cache.add(str(op[2]), int(op[3]), str(op[1]))
		"cache_count":
			return inv.cache.count(str(op[1]))
		"seize":
			var r := inv.seize()
			var items: Array = (r["items"] as Array).duplicate()
			items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return str(a["id"]) < str(b["id"]))
			var tools: Array = (r["tools"] as Array).duplicate()
			tools.sort()
			return {"items": items, "tools": tools, "equip": r["equip"], "arrows": inv.seized["arrows"]}
		"restoreSeized":
			var r := inv.restore_seized()
			var tools: Array = (r["tools"] as Array).duplicate()
			tools.sort()
			return {"items": (r["items"] as Array).size(), "tools": tools, "equip": r["equip"]}
		"onDawn":
			return inv.on_dawn(int(op[1]))
		"longSkip":
			return inv.on_long_skip(int(op[1]))
		"day":
			return inv.day
	fail("bilinmeyen heybe işlemi: %s" % kind)
	return null


static func _null_if_empty(s: String) -> Variant:
	return null if s.is_empty() else s
