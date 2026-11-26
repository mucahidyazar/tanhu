extends TestCase
## Deneme haritasının toplama ve zanaat katmanı (Yol Haritası gathering, crafting; GatherLayer, GatherField, StrikeRing, ToolSwing, Workbench,
## HudCraftScreen): map.json «layers» «gathering» satırı katmanı kurar (MapLayers; «Layers/Gathering»); 36 düğüm haritanın zemininde, yapıların,
## ocağın, patikaların ve tezgâhların dışında; tür başına bir MultiMesh; engel daireleri; iki tezgâh. Gerçek ana sahnede Mete E ile toplar
## (istem «E Biç», tutuşun klibi, halka; vuruşta ToolSwing ve Tam Vuruş halkası; çam devrilir, kütük kalır), verim Heybe'ye ya da terkiye ya
## da yer yığınına; tezgâhta el işi (Kujul'la demir külçe), sipariş (Bosağa), Malzemeyi Bırak, Bitene Dek Bekle (saat iş kadar hızlı akar)
## ve Hepsini Al: çıktı envantere. Sayfa oyunu durdurur, Esc kapatır.

const MAIN_SCENE := "res://scenes/main.tscn"
const MAP_SCENE := "res://scenes/maps/testmap.tscn"
const TempDir := preload("res://tests/support/temp_dir.gd")

var _dir := ""


func before_each() -> void:
	MenuStyle.muted = true
	_dir = TempDir.fresh("toplama_katmani")


func after_each() -> void:
	get_tree().paused = false
	if InputMap.has_action(&"accept"):
		Input.action_release(&"accept")
	TempDir.wipe(_dir)


func _new_main() -> Node:
	var main = load(MAIN_SCENE).instantiate()
	main.quit_handler = func() -> void: pass
	main.saves = SaveSystem.new(_dir)
	main.prologue_path = ""
	add_child(main)
	return main


func _wait_until(condition: Callable, timeout: float) -> void:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame


static func _layer(map: Node) -> GatherLayer:
	return map.get_node_or_null(^"Layers/Gathering") as GatherLayer if map else null


static func _first(store: NodeStore, kind: String) -> int:
	for i in store.count:
		if store.kind_of(i) == kind and store.available(i):
			return i
	return -1


## Mete'yi düğümün yanına koyar (erimin içinde, düğüme dönük).
static func _stand_by(player: PlayerController, store: NodeStore, i: int) -> void:
	var at := store.position_of(i)
	var r := float(store.row_of(i).get("r", 0.4))
	var from := at + Vector3(0.0, 0.0, r + 0.9)
	player.spawn_at(from, atan2(at.x - from.x, at.z - from.z))


# --- Kurulum (yalnız harita) ---------------------------------------------------------------------------------------------------

func test_layer_builds_from_the_map_layers_line() -> void:
	MapSpec.forget_cache()
	var spec := MapSpec.find(MapSpec.TESTMAP)
	assert_eq(str(spec.layers.get("gathering", "")), "res://data/maps/testmap/gathering.json", "map.json «layers» «gathering»")
	var world := (load(MAP_SCENE) as PackedScene).instantiate() as MapWorld
	world.spec = spec
	add_child(world)
	await _wait_until(func() -> bool: return world.is_ready(), 20.0)
	var layer := _layer(world)
	assert_not_null(layer, "Layers/Gathering kuruldu")
	if layer == null:
		world.queue_free()
		return
	await _wait_until(func() -> bool: return layer.store != null, 5.0)
	var expect := 0
	for e: Dictionary in layer.data["nodes"]:
		expect += int(e.get("n", 1))
	assert_eq(layer.store.count, expect, "Spec'in bütün düğümleri")
	assert_eq(expect, 36)
	var kinds := layer.store.count_by_kind()
	for k: String in ["node_pine", "node_boulder", "node_reed", "node_dung", "node_vein_iron", "node_vein_copper", "node_hay", "node_wormwood"]:
		assert_true(kinds.has(k), "Beş iş bir arada: %s" % k)
	for i in layer.store.count:
		var p := layer.store.position_of(i)
		assert_almost(p.y, world.ground.height_at(p.x, p.z), 0.01, "%s zeminde" % layer.store.kind_of(i))
		assert_true(Vector2(p.x, p.z).distance_to(Vector2(0.0, -4.0)) >= 9.0, "Ocağın 9 m'si dışında")
		assert_true(Vector2(p.x, p.z).distance_to(spec.play_center) < spec.play_radius - 10.0, "Yürünür alanda")
	assert_eq(layer.field.layers.size(), kinds.size() + 1, "Tür başına bir MultiMesh ve kütükler")
	var mm_total := 0
	for k: String in kinds:
		mm_total += (layer.field.layers[k] as MultiMeshInstance3D).multimesh.instance_count
	assert_eq(mm_total, 36, "Her düğüm bir örnek")
	assert_eq(layer.field.visible_counts().get("node_pine", 0), 6, "Altı çam ayakta")
	var circles := layer.field.get_obstacle_circles()
	assert_true(circles.size() >= 6 + 2 + 3 + 3, "Çam, ardıç, kaya ve damar engeldir: %d" % circles.size())
	assert_true(world.collect_obstacles().size() >= circles.size() + 2, "Dünyanın engellerinde düğümler ve tezgâhlar")
	assert_eq(layer.benches.size(), 2, "Demirci Ocağı ve Ağaç Atölyesi")
	for id: String in layer.benches:
		var b: Dictionary = layer.benches[id]
		assert_true((b["node"] as Workbench).is_inside_tree())
		assert_not_null(b["ws"])
	assert_eq((layer.benches["bench_smithy"]["chest"] as ItemContainer).count("charcoal"), 2, "Sandığın ilk içeriği")
	world.queue_free()
	await wait_frames(2)


# --- Oynanış (gerçek ana sahne) --------------------------------------------------------------------------------------------------

func test_mete_gathers_holds_and_strikes_on_the_testmap() -> void:
	var main = _new_main()
	await wait_frames(3)
	main.menu.finish_intro()
	await wait_frames(1)
	await main._dev_testmap({"no-hud-map": true})
	assert_eq(main.state, main.State.PLAYING)
	var layer := _layer(main._map_world)
	assert_not_null(layer, "Katman")
	if layer == null:
		main.queue_free()
		return
	var inv: Inventory = main.gameplay_hud.bag.inventory
	await _wait_until(func() -> bool: return layer.gather != null and layer.gather.inventory != null and inv.has_tool("pick_bronze"), 5.0)
	var player: PlayerController = main.player
	assert_true(inv.has_tool("axe_bronze") and inv.has_tool("pick_bronze"), "Deneme takımı: tunç balta ve kazma")
	# Saz: E ile istem «E Biç», tutuşta klip ve halka; bırakmadan 2 sn → 2 saz.
	var reed := _first(layer.store, "node_reed")
	_stand_by(player, layer.store, reed)
	var pairs: Array = []
	player.prompt_changed.connect(func(p: Array) -> void: pairs = p.duplicate())
	await wait_frames(4)
	assert_eq(layer.focus.get("index", -1), reed, "Saz odakta")
	assert_eq(main.gameplay_hud.action_prompt.pairs[0], ["E", "Biç"], "HUD istemi (ateş katmanı kendi tuşunu ekler)")
	var reed_before := inv.count("reed") + _piled(inv, "reed") + _bagged(inv, "reed")
	var ev := InputEventAction.new()
	ev.action = &"accept"
	ev.pressed = true
	Input.action_press(&"accept")
	Input.parse_input_event(ev)
	await wait_frames(3)
	assert_eq(layer.gather.state, Gather.State.HOLD, "E tutuşu başlattı")
	assert_false(player.is_riding(), "E bineğe binmedi")
	assert_eq(player.work_role, &"work_pull", "Tutuşun klibi (pull_radish)")
	assert_true(layer.ring.visible, "Tutuşun halkası")
	await get_tree().create_timer(2.3).timeout
	Input.action_release(&"accept")
	await wait_frames(2)
	assert_eq(inv.count("reed") + _piled(inv, "reed") + _bagged(inv, "reed") - reed_before, 2, "2 saz (Heybe, terki ya da yığın)")
	assert_eq(layer.store.charges[reed], 2, "Sazın hakkı 3 → 2")
	assert_eq(player.work_role, &"", "İş bitti, poz bırakıldı")
	# Bırakınca sıfırlanır: ceza yok.
	layer.begin_gather(reed)
	Input.action_press(&"accept")
	await get_tree().create_timer(0.5).timeout
	Input.action_release(&"accept")
	await wait_frames(3)
	assert_eq(layer.gather.state, Gather.State.IDLE, "Bırakınca tutuş kesildi")
	assert_eq(layer.store.charges[reed], 2, "Ceza yok, hak aynı")
	# Çam: E basılı tutuldukça 5 vuruş; ToolSwing, halka; devrilir, kütük kalır, engel kalkar.
	var pine := _first(layer.store, "node_pine")
	_stand_by(player, layer.store, pine)
	await wait_frames(3)
	var circles_before := layer.field.get_obstacle_circles().size()
	var wood_before := inv.count("wood_pine") + _piled(inv, "wood_pine") + _bagged(inv, "wood_pine")
	assert_true(layer.begin_gather(pine), "Çamda iş başladı")
	Input.action_press(&"accept")
	await wait_frames(3)
	assert_eq(layer.gather.state, Gather.State.SWING, "Vuruş")
	assert_eq(player.work_role, &"work_swing")
	assert_true(layer._swing != null and layer._swing.amount > 0.5, "ToolSwing üst bedeni kurar")
	assert_true(layer._tool != null and layer._tool.visible, "Balta elde")
	assert_true(layer.ring.visible, "Tam Vuruş halkası")
	await _wait_until(func() -> bool: return not layer.store.available(pine), 12.0)
	Input.action_release(&"accept")
	await wait_frames(4)
	assert_false(layer.store.available(pine), "Çam kesildi")
	assert_eq(layer.store.flags[pine] & NodeStore.F_PERM, NodeStore.F_PERM, "Kalıcı (kayda geçer)")
	assert_eq(inv.count("wood_pine") + _piled(inv, "wood_pine") + _bagged(inv, "wood_pine") - wood_before, 3, "3 odun")
	assert_eq(layer.field.get_obstacle_circles().size(), circles_before - 1, "Devrilen çam engel değil")
	assert_true(layer.economy.stats["felled"] >= 1)
	main.queue_free()
	await wait_frames(2)


func test_bench_crafts_by_hand_and_by_order_into_the_pack() -> void:
	var main = _new_main()
	await wait_frames(3)
	main.menu.finish_intro()
	await wait_frames(1)
	await main._dev_testmap({"no-hud-map": true})
	var layer := _layer(main._map_world)
	assert_not_null(layer)
	if layer == null:
		main.queue_free()
		return
	await _wait_until(func() -> bool: return layer.gather != null and layer.gather.inventory != null, 3.0)
	var player: PlayerController = main.player
	var inv: Inventory = main.gameplay_hud.bag.inventory
	# Heybe boşalsın (ateş ve av katmanının deneme takımı 20,2 Yük; katman takımını HUD görününce verir): araçlar kalır.
	await _wait_until(func() -> bool: return inv.count("branch") > 0, 3.0)
	inv.pack.clear()
	inv.add("ore_iron", 4, "test")
	# Demirci Ocağı: Kujul'la demir külçe (el işi, 6 sn tutuş).
	var smithy: Workbench = layer.benches["bench_smithy"]["node"]
	player.spawn_at(smithy.global_position + Vector3(0.0, 0.0, 2.0), PI)
	await wait_frames(4)
	assert_eq(str(layer.focus.get("id", "")), "bench_smithy", "Tezgâh odakta")
	assert_eq(main.gameplay_hud.action_prompt.pairs[0], ["E", "Demirci Ocağı"])
	assert_true(layer.open_bench("bench_smithy"), "Sayfa açılır")
	assert_true(get_tree().paused, "Oyun durur")
	var screen := layer.screen()
	assert_not_null(screen)
	screen.select("rc_iron_bar")
	assert_true(screen.is_hand("rc_iron_bar"), "Demir külçe Mete'nin el işi (Kujul'un körüğü)")
	assert_true(screen.check("rc_iron_bar")["ok"], "Kujul tezgâhta, 4 cevher Heybe'de")
	assert_true(screen.make(), "Yapıldı")
	assert_eq(inv.count("iron_bar"), 1, "Demir külçe envanterde")
	assert_eq(inv.count("ore_iron"), 0)
	assert_true(layer.economy.crafted.has("rc_iron_bar"), "İlk kez yapıldı")
	screen.close()
	await wait_frames(2)
	assert_false(get_tree().paused, "Sayfa kapanınca oyun sürer")
	# Ağaç Atölyesi: Bosağa siparişi (3 odun + 1 külçe; 6 iş saati), malzeme sandığa, Bitene Dek Bekle, Hepsini Al.
	assert_eq(inv.add("wood_pine", 3, "test")["added"], 3, "Üç odun Heybe'de (12 Yük)")
	var shop: Workbench = layer.benches["bench_wood"]["node"]
	player.spawn_at(shop.global_position + Vector3(2.0, 0.0, 0.0), -PI * 0.5)
	await wait_frames(3)
	assert_true(layer.open_bench("bench_wood"))
	screen = layer.screen()
	screen.select("rc_door_frame")
	assert_false(screen.is_hand("rc_door_frame"), "Bosağa parça: tezgâhın işi")
	screen.do_button("store")
	var chest: ItemContainer = layer.benches["bench_wood"]["chest"]
	assert_eq([chest.count("tag:wood"), chest.count("iron_bar")], [3, 1], "Malzeme sandıkta")
	assert_true(screen.make(), "Sipariş verildi")
	var ws: Workshop = layer.benches["bench_wood"]["ws"]
	assert_eq(ws.queue.size(), 1)
	var minutes := ws.remaining_minutes()
	assert_almost(minutes, 360.0, 0.5, "6 iş saati tek elle 6 oyun saati")
	screen.do_button("help")
	assert_almost(ws.remaining_minutes(2.0), 360.0 / Labour.eff(2.0), 0.5, "Mete birlikte çalışınca eff(2) = 1,9")
	var start_abs := layer.clock.abs_minute()
	assert_true(screen.do_button("wait"), "Bitene Dek Bekle")
	await wait_frames(2)
	assert_false(get_tree().paused)
	await _wait_until(func() -> bool: return chest.count("door_frame") > 0, 10.0)
	assert_eq(chest.count("door_frame"), 1, "Bosağa sandıkta")
	assert_true(layer.clock.abs_minute() - start_abs >= 180.0, "Saat iş kadar aktı (%.0f dk)" % (layer.clock.abs_minute() - start_abs))
	assert_true(layer.open_bench("bench_wood"))
	layer.screen().do_button("take_all")
	assert_eq(inv.count("door_frame"), 1, "Bosağa envanterde")
	layer.screen().close()
	await wait_frames(2)
	main.queue_free()
	await wait_frames(2)


## Uçtan uca (gathering → crafting): toplanan malzeme tezgâhta yapılır, Heybe'ye girer. Bakır damarı kazmayla (5 vuruş → 1 cevher) →
## Demirci Ocağı'nda bakır parça (el işi, girdi Heybe'den); çam baltayla (5 vuruş → 3 odun) → Ağaç Atölyesi'nde teker çifti siparişi
## (2 odun sandığa, 10 iş saati, Birlikte Çalış, Bitene Dek Bekle) → Hepsini Al → Heybe.
func test_gathered_materials_are_made_at_the_bench_into_the_pack() -> void:
	var main = _new_main()
	await wait_frames(3)
	main.menu.finish_intro()
	await wait_frames(1)
	await main._dev_testmap({"no-hud-map": true})
	var layer := _layer(main._map_world)
	assert_not_null(layer)
	if layer == null:
		main.queue_free()
		return
	var inv: Inventory = main.gameplay_hud.bag.inventory
	await _wait_until(func() -> bool: return layer.gather != null and layer.gather.inventory != null and inv.has_tool("pick_bronze"), 5.0)
	await _wait_until(func() -> bool: return inv.count("branch") > 0, 3.0)
	inv.pack.clear()
	var player: PlayerController = main.player
	# Bakır damarı: E basılı tutuldukça vuruş; 5 vuruşta 1 cevher.
	var vein := _first(layer.store, "node_vein_copper")
	_stand_by(player, layer.store, vein)
	await wait_frames(3)
	assert_true(layer.begin_gather(vein), "Damarda iş başladı")
	Input.action_press(&"accept")
	await _wait_until(func() -> bool: return inv.count("ore_copper") >= 1, 12.0)
	Input.action_release(&"accept")
	await wait_frames(3)
	assert_eq(inv.count("ore_copper"), 1, "Kazılan bakır cevheri Heybe'de")
	assert_eq(layer.store.charges[vein], 2, "Damarın hakkı 3 → 2")
	# Çam: 5 vuruşta devrilir, 3 odun Heybe'ye (cevherle 16 Yük, sınır 21).
	var pine := _first(layer.store, "node_pine")
	_stand_by(player, layer.store, pine)
	await wait_frames(3)
	assert_true(layer.begin_gather(pine), "Çamda iş başladı")
	Input.action_press(&"accept")
	await _wait_until(func() -> bool: return not layer.store.available(pine), 12.0)
	Input.action_release(&"accept")
	await wait_frames(3)
	assert_eq(inv.count("wood_pine"), 3, "Kesilen çamın 3 odunu Heybe'de")
	# Demirci Ocağı: bakır parça, Mete'nin el işi (girdi Heybe'den).
	var smithy: Workbench = layer.benches["bench_smithy"]["node"]
	player.spawn_at(smithy.global_position + Vector3(0.0, 0.0, 2.0), PI)
	await wait_frames(3)
	assert_true(layer.open_bench("bench_smithy"))
	var screen := layer.screen()
	screen.select("rc_copper_bit")
	assert_true(screen.is_hand("rc_copper_bit"))
	assert_true(screen.make(), "Bakır parça yapıldı")
	assert_eq([inv.count("ore_copper"), inv.count("copper_bit")], [0, 1], "Cevher gitti, bakır parça Heybe'de")
	screen.close()
	await wait_frames(2)
	# Ağaç Atölyesi: teker çifti siparişi (tezgâhın işi; girdi sandıktan).
	var shop: Workbench = layer.benches["bench_wood"]["node"]
	player.spawn_at(shop.global_position + Vector3(2.0, 0.0, 0.0), -PI * 0.5)
	await wait_frames(3)
	assert_true(layer.open_bench("bench_wood"))
	screen = layer.screen()
	screen.select("rc_wheel_pair")
	assert_false(screen.is_hand("rc_wheel_pair"), "Teker çifti tezgâhın işi")
	screen.do_button("store")
	var chest: ItemContainer = layer.benches["bench_wood"]["chest"]
	assert_eq(chest.count("tag:wood"), 2, "Siparişin 2 odunu sandıkta")
	assert_eq(inv.count("wood_pine"), 1, "Artan odun Heybe'de kaldı")
	assert_true(screen.make(), "Sipariş verildi")
	screen.do_button("help")
	assert_true(screen.do_button("wait"), "Bitene Dek Bekle")
	await _wait_until(func() -> bool: return chest.count("wheel_pair") > 0, 12.0)
	assert_eq(chest.count("wheel_pair"), 1, "Teker çifti sandıkta (iş akşama taştı: karanlıkta akış uzadı)")
	assert_eq(chest.count("tag:wood"), 0, "Odun işte harcandı")
	await wait_frames(2)
	assert_false(layer.clock.is_lapsing(), "İş bitince akış kesildi")
	assert_true(layer.open_bench("bench_wood"))
	layer.screen().do_button("take_all")
	assert_eq(inv.count("wheel_pair"), 1, "Teker çifti Heybe'de")
	layer.screen().close()
	await wait_frames(2)
	main.queue_free()
	await wait_frames(2)


## Yer yığınlarındaki adet.
static func _piled(inv: Inventory, id: String) -> int:
	var n := 0
	for p: ItemContainer in inv.piles():
		n += p.count(id)
	return n


## Terkilerdeki adet.
static func _bagged(inv: Inventory, id: String) -> int:
	var n := 0
	for key: String in inv.mount_ids():
		var bag := inv.saddlebags(key)
		if bag:
			n += bag.count(id)
	return n
