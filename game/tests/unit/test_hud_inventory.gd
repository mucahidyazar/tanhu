extends TestCase
## Envanter ekranının gerçek envanterle işleyişi (HudInventoryScreen, HudBag, HudTransferPanel, GroundPile): on kuşam yuvası, heybenin
## sekmeleri ve kaydırma, çekmecenin işleri (Kuşan, Çıkar, Taşı, Bırak), yakındaki atın terkisi ve aktarma sekmesi, kabul süzgeci
## ve hızlı düğmeler, yere bırakılan yığının E ile geri alınması.

var _nodes: Array = []


func before_each() -> void:
	InputSetup.ensure_actions()


func after_each() -> void:
	for n: Variant in _nodes:
		if is_instance_valid(n):
			(n as Node).queue_free()
	_nodes.clear()
	get_tree().paused = false


func _keep(n: Node) -> Node:
	add_child(n)
	_nodes.append(n)
	return n


## Oyuncu yerine düz bir düğüm ve yakınında kampın doru atı (Mount satırı horse: terki 50).
func _world_with_horse(at := Vector3(4.0, 0.0, 0.0)) -> Dictionary:
	var world := _keep(Node3D.new()) as Node3D
	var player := Node3D.new()
	player.name = "Player"
	world.add_child(player)
	var owner := Node3D.new()
	owner.name = "HorseBrown"
	world.add_child(owner)
	var ride := Rideable.new()
	ride.name = "Ride"
	ride.mount_id = "horse"
	owner.add_child(ride)
	owner.position = at
	ride.add_to_group(Rideable.GROUP)
	return {"world": world, "player": player, "ride": ride}


func _screen(bag: HudBag) -> HudInventoryScreen:
	var inv := HudInventoryScreen.new()
	inv.bag = bag
	inv.person = ChildLook.PERSON_CHILD
	_keep(inv)
	return inv


func test_ten_design_slots_and_bag_tabs_fit_the_cards() -> void:
	assert_eq(HudInventoryScreen.EQUIP_SLOTS.keys().size(), 10, "progression.md §6.1'in on yuvası")
	for slot: Variant in ItemCatalog.slots():
		assert_true(HudInventoryScreen.EQUIP_SLOTS.has(slot), "Ekranda yuva: %s" % slot)
	var a := HudInventoryScreen.equip_rect("head")
	var b := HudInventoryScreen.equip_rect("neck")
	assert_almost(b.position.y - a.end.y, 12.0, 0.001, "Kuşam yuvalarının arası 12 px")
	var bag := HudBag.new()
	bag.reset(true)
	var inv := _screen(bag)
	await wait_frames(1)
	var rects := inv.bag_tab_rects()
	assert_eq(rects.size(), HudBag.TABS.size())
	var title_end := HudInventoryScreen.RIGHT_BOX.position.x + 30.0 + UIKit.font("Cinzel", 700, 4).get_string_size("HEYBE", HORIZONTAL_ALIGNMENT_LEFT, -1, 21).x
	for i in rects.size():
		var r: Rect2 = rects[i]
		assert_true(HudInventoryScreen.RIGHT_BOX.encloses(r), "Sekme kartta: %s" % HudBag.TABS[i])
		assert_true(r.position.x > title_end + 8.0, "Sekme başlığa değmez: %s" % HudBag.TABS[i])
		if i > 0:
			assert_true(r.position.x >= (rects[i - 1] as Rect2).end.x, "Sekmeler üst üste binmez")
	assert_eq(inv.top_tabs().size(), 1, "Yakında binek yokken tek sekme")


func test_tabs_filter_and_the_grid_scrolls() -> void:
	var bag := HudBag.new()
	bag.reset(false)
	var inv: Inventory = bag.inventory
	inv.cap_source = func() -> float: return 500.0
	inv.add("stone", 2)
	inv.add("meal", 25)
	inv.add("rope", 3)
	inv.add("axe_bronze")
	inv.add("notch_stick")
	var screen := _screen(bag)
	await wait_frames(1)
	var ids := func() -> Array: return screen.grid_entries().map(func(e: Dictionary) -> String: return "%s:%d" % [e["id"], e["count"]])
	assert_eq(ids.call(), ["stone:2", "meal:10", "meal:10", "meal:5", "rope:3", "notch_stick:1", "axe_bronze:1"], "Bir hücre bir yığın; araç sonda")
	screen._set_bag_tab("food")
	assert_eq(ids.call(), ["meal:10", "meal:10", "meal:5"], "Erzak sekmesi")
	screen._set_bag_tab("back")
	assert_eq(ids.call(), ["stone:2"], "Sırt sekmesi")
	screen._set_bag_tab("tools")
	assert_eq(ids.call(), ["axe_bronze:1"], "Araç sekmesi")
	screen._set_bag_tab("all")
	inv.add("felt", 200)
	assert_true(screen.grid_entries().size() > HudInventoryScreen.COLS * HudInventoryScreen.ROWS, "Dört satırdan fazlası")
	assert_true(screen.scroll_grid(1), "Tekerlek bir satır kaydırır")
	screen._content_gui_input(_motion(HudInventoryScreen.cell_rect(0).get_center()))
	assert_eq(str(screen.shown_entry().get("id", "")), str(screen.grid_entries()[HudInventoryScreen.COLS]["id"]), "İlk görünen hücre ikinci satırın yığını")
	assert_true(screen._content_input(_action(&"ui_focus_next")), "Sekme tuşu heybenin sekmesini değiştirir")
	assert_eq(screen.bag_tab, "back")


func test_drawer_equips_and_unequips() -> void:
	var bag := HudBag.new()
	bag.reset(false)
	bag.inventory.add("felt_boots", 1)
	bag.inventory.add("lark", 1)
	var screen := _screen(bag)
	await wait_frames(1)
	screen._content_gui_input(_click(HudInventoryScreen.cell_rect(0).get_center()))
	assert_eq(str(screen.selected_entry().get("id", "")), "felt_boots")
	assert_true(screen.action_enabled("use"), "Çizme kuşanılabilir")
	assert_eq(HudInventoryScreen.button_label(0, screen.selected_entry()), "Kuşan")
	assert_false(screen.action_enabled("move"), "Aktarma kabı yokken Taşı sönük")
	assert_false(screen.action_enabled("drop"), "Dünya yokken Bırak sönük")
	assert_true(screen.do_action("use"), "Kuşanır")
	assert_eq(bag.inventory.equipped("feet"), "felt_boots")
	assert_eq(screen.selected_kind, "equip", "Seçim kuşam yuvasına geçer")
	assert_eq(screen.selected_slot, "feet")
	assert_eq(HudInventoryScreen.button_label(0, screen.selected_entry()), "Çıkar")
	assert_true(screen.do_action("use"), "Çıkarır")
	assert_eq(bag.inventory.equipped("feet"), "")
	assert_eq(str(screen.selected_entry().get("id", "")), "felt_boots", "Çıkan eşya ızgarada seçili")
	screen._content_gui_input(_click(HudInventoryScreen.cell_rect(0).get_center()))
	assert_eq(str(screen.selected_entry().get("id", "")), "lark")
	assert_false(screen.action_enabled("use"), "Tarla kuşunun bugün kullanımı yok (Tokluk gelince)")
	screen.clear_selection()
	screen._content_gui_input(_motion(HudInventoryScreen.equip_rect("head").get_center()))
	assert_true(screen.drawer_visible(), "Boş kuşam yuvasının üstünde yuvanın adı")
	assert_true(screen.shown_entry().is_empty(), "Boş yuvada eşya yok")


func test_nearby_horse_opens_the_transfer_tab() -> void:
	var w := _world_with_horse()
	var bag := HudBag.new()
	bag.player = w["player"]
	bag.reset(true)
	bag.add("lark", 2)
	bag.add("gerbil", 1)
	var t := bag.transfer_target()
	assert_false(t.is_empty(), "15 m içindeki atın terkisi")
	assert_eq(str(t["title"]), "TERKİ · DORU", "Kampın doru atı")
	assert_almost((t["container"] as ItemContainer).cap(), 50.0, 1e-9, "Terki binek Yük'ü")
	var screen := _screen(bag)
	await wait_frames(1)
	assert_eq(screen.top_tabs().size(), 2, "İkinci sekme: TERKİ")
	screen._content_gui_input(_click(HudInventoryScreen.cell_rect(0).get_center()))
	assert_true(screen.action_enabled("move"), "Taşı açık")
	assert_true(screen.do_action("move"), "Seçili yığın terkiye")
	assert_eq((t["container"] as ItemContainer).count("lark"), 2)
	assert_true(screen.status_text().contains("→"), "Sonucun yazısı: %s" % screen.status_text())
	assert_true(screen._content_input(_action(&"camera_right")), "E sekme değiştirir")
	assert_eq(screen.page, "transfer")
	assert_false(screen.character_view().visible, "Aktarmada 3B görsel gizli")
	var panel := screen.transfer_panel()
	assert_not_null(panel)
	assert_eq(panel.cells("left").map(func(c: Dictionary) -> String: return str(c["id"])), ["lark"], "Solda terki")
	assert_eq(panel.move_cell("left", 0), 2, "Tık yığını heybeye geri taşır")
	assert_eq(bag.count("lark"), 2)
	assert_eq(panel.move_cell("right", 0, true), 1, "Shift bir tane taşır")
	assert_true(screen._content_input(_action(&"camera_left")), "Q geri döner")
	assert_eq(screen.page, "bag")
	w["ride"].position = Vector3(40.0, 0.0, 0.0)
	assert_true(bag.transfer_target().is_empty(), "15 m'den uzak at terki vermez")


func test_container_refuses_and_quick_buttons() -> void:
	var bag := HudBag.new()
	bag.reset(false)
	var inv: Inventory = bag.inventory
	inv.add("stone", 2)
	inv.add("rope", 2)
	inv.add("meal", 3)
	var screen := _screen(bag)
	await wait_frames(1)
	var granary := ItemContainer.make("granary")
	screen.open_container(granary, "TAHIL AMBARI")
	var panel := screen.transfer_panel()
	assert_eq(screen.page, "transfer")
	assert_false(panel.accepted("right", "rope"), "Tahıl ambarı ip almaz")
	assert_eq(panel.move_cell("right", 1), 0, "Almayan kaba gitmez")
	assert_eq(panel.status(), HudBag.message("refuses"), "«Bu kap bunu almaz»")
	assert_eq(panel.quick("store_food"), 3, "Yiyeceği Bırak")
	assert_eq(granary.count("meal"), 3)
	assert_eq(panel.quick("unload_back"), 0, "Ambar taş almaz: Sırtı Boşalt bir şey taşımaz")
	assert_eq(panel.quick("take_all"), 3, "Hepsini Al")
	assert_eq(inv.pack.count("meal"), 3)
	var chest := ItemContainer.make("chest")
	screen.open_container(chest, "SANDIK")
	panel = screen.transfer_panel()
	assert_eq(panel.quick("unload_back"), 2, "Sırtı Boşalt: taşlar sandığa")
	assert_eq(chest.count("stone"), 2)
	var full := ItemContainer.make("stash", {"cap": 0.5})
	screen.open_container(full, "MENZİL")
	panel = screen.transfer_panel()
	assert_eq(panel.move_cell("right", 0), 1, "Sığdığı kadar (0,5 Yük: bir ip)")
	assert_true(panel.status().contains(HudBag.message("store_full")), "Kalanın uyarısı: %s" % panel.status())


func test_drop_makes_a_ground_pile_that_e_takes_back() -> void:
	var w := _world_with_horse(Vector3(60.0, 0.0, 0.0))
	var bag := HudBag.new()
	bag.player = w["player"]
	bag.reset(true)
	bag.add("lark", 2)
	var screen := _screen(bag)
	await wait_frames(1)
	screen._content_gui_input(_click(HudInventoryScreen.cell_rect(0).get_center()))
	assert_true(screen.action_enabled("drop"), "Bırak açık")
	assert_true(screen.do_action("drop"))
	assert_eq(bag.count("lark"), 0)
	var piles := bag.pile_nodes()
	assert_eq(piles.size(), 1, "Yere bir torba iner")
	var pile := piles[0] as GroundPile
	assert_true(pile.is_in_group(PlayerController.FALLEN_GROUP) and pile.is_down(), "Yerdeki hedef sözleşmesi (E Al)")
	assert_true(pile.global_position.distance_to((w["player"] as Node3D).global_position) < 1.0, "Oyuncunun önünde")
	bag.on_collected(pile, pile.collect())
	assert_eq(bag.count("lark"), 2, "E ile geri")
	await wait_frames(2)
	assert_false(is_instance_valid(pile), "Boşalan yığın kalkar")
	screen._content_gui_input(_click(HudInventoryScreen.equip_rect("bow").get_center()))
	assert_eq(str(screen.selected_entry().get("id", "")), "toy_bow")
	assert_false(screen.action_enabled("drop"), "Çocuğun yayı bırakılmaz (kits.child.locked)")
	assert_false(screen.action_enabled("use"), "Çocuğun yayı çıkarılmaz")
	assert_eq(bag.inventory.unequip("bow"), "", "Model de çıkarmaz")
	assert_null(bag.inventory.drop("toy_bow", 1, Vector3.ZERO), "Model de bırakmaz")
	bag.inventory.add("notch_stick", 1)
	var keep := bag.entry("notch_stick", 1)
	assert_false((keep["actions"] as Array).has("drop"), "Hatıra atılmaz")


func test_collected_game_overflows_to_the_ground_when_the_child_is_full() -> void:
	var w := _world_with_horse(Vector3(60.0, 0.0, 0.0))
	var bag := HudBag.new()
	bag.player = w["player"]
	bag.reset(true)
	bag.inventory.add("wood_pine", 1)
	bag.inventory.add("lark", 3)
	bag.on_collected(null, {"kind": "marmot", "yield": {}})
	assert_eq(bag.count("marmot"), 0, "Kütük ve üç kuşla tarbagan sığmaz (4,6 + 1,5 > 6)")
	assert_eq(bag.pile_nodes().size(), 1, "Ayağının dibine yığılır")
	bag.on_collected(null, {"kind": "dummy"})
	assert_eq(bag.inventory.pack.size(), 2, "Eşya olmayan hedef heybeye girmez")
	# Kayıttan dönüş: yığın blokta durur, düğümü yeniden kurulur.
	var block := bag.inventory.to_dict()
	var again := HudBag.new()
	again.player = w["player"]
	assert_true(again.inventory.from_dict(JSON.parse_string(JSON.stringify(block))))
	again.spawn_piles()
	assert_eq(again.pile_nodes().size(), 1, "Kayıttan dönen yığının düğümü")
	assert_eq(int(((again.pile_nodes()[0] as GroundPile).pile as ItemContainer).count("marmot")), 1)


func test_drag_and_shift_click_in_the_transfer_tab() -> void:
	var bag := HudBag.new()
	bag.reset(false)
	bag.inventory.add("rope", 3)
	bag.inventory.add("meal", 2)
	var screen := _screen(bag)
	await wait_frames(1)
	var chest := ItemContainer.make("chest")
	screen.open_container(chest, "SANDIK")
	var from := HudTransferPanel.cell_rect("right", 0).get_center()
	var to := HudTransferPanel.cell_rect("left", 7).get_center()
	screen._content_gui_input(_button(from, true))
	screen._content_gui_input(_motion(from + Vector2(24.0, 0.0)))
	screen._content_gui_input(_motion(to))
	screen._content_gui_input(_button(to, false))
	assert_eq(chest.count("rope"), 3, "Sürükleyip öbür kartta bırakmak yığını taşır")
	var meal := HudTransferPanel.cell_rect("right", 0).get_center()
	screen._content_gui_input(_button(meal, true))
	screen._content_gui_input(_button(meal, false, true))
	assert_eq(chest.count("meal"), 1, "Shift'li tık bir tane taşır")
	screen._content_gui_input(_button(HudTransferPanel.cell_rect("left", 0).get_center(), true, false, MOUSE_BUTTON_RIGHT))
	assert_eq(chest.count("rope"), 2, "Sağ tık bir tane geri alır")
	var dropped_on_self := HudTransferPanel.cell_rect("left", 1).get_center()
	screen._content_gui_input(_button(dropped_on_self, true))
	screen._content_gui_input(_motion(dropped_on_self + Vector2(30.0, 30.0)))
	screen._content_gui_input(_button(dropped_on_self + Vector2(30.0, 30.0), false))
	assert_eq(chest.count("meal"), 1, "Aynı kartta bırakılan sürükleme taşımaz")


func test_every_item_has_an_icon_that_draws() -> void:
	# Atlas simgesi olmayan her eşya kodla çizilir: bütün eşyalar ve yuvalar bir kez çizilir, motor hata yazmaz (çokgen bölünür).
	var sheet := IconSheet.new()
	sheet.size = Vector2(1600.0, 1600.0)
	_keep(sheet)
	sheet.queue_redraw()
	await wait_frames(2)
	assert_eq(sheet.drawn, ItemCatalog.ids().size(), "Bütün eşyalar çizildi")
	var kinds := {}
	for item_id in ItemCatalog.ids():
		kinds[HudItemIcon.glyph_of(item_id) if ItemCatalog.icon_of(item_id).is_empty() else "atlas"] = true
	assert_true(kinds.size() >= 25, "Simgeler ayırt edilir: %d tür" % kinds.size())
	assert_ne(HudItemIcon.glyph_of("rope"), HudItemIcon.glyph_of("felt"), "İp ve keçe ayrı işaret")
	assert_eq(HudItemIcon.glyph_of("wood_pine"), "log")
	assert_eq(HudItemIcon.glyph_of("hun_bow+"), "bow", "İnce İş taban satırın işaretiyle")


class IconSheet extends Control:
	var drawn := 0

	func _draw() -> void:
		drawn = 0
		var i := 0
		for item_id in ItemCatalog.ids():
			HudItemIcon.draw(self, item_id, Vector2(40.0 + (i % 20) * 76.0, 40.0 + (i / 20) * 76.0), 64.0)
			drawn += 1
			i += 1
		for slot: Variant in ItemCatalog.slots() + ItemCatalog.mount_slots():
			HudItemIcon.draw_slot(self, str(slot), Vector2(40.0 + (i % 20) * 76.0, 40.0 + (i / 20) * 76.0), 40.0, Color(1, 1, 1, 0.3))
			i += 1


func _motion(p: Vector2) -> InputEventMouseMotion:
	var e := InputEventMouseMotion.new()
	e.position = p
	return e


func _click(p: Vector2) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	e.position = p
	return e


func _button(p: Vector2, pressed: bool, shift := false, index := MOUSE_BUTTON_LEFT) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = index
	e.pressed = pressed
	e.position = p
	e.shift_pressed = shift
	return e


func _action(action: StringName) -> InputEventAction:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = true
	return e
