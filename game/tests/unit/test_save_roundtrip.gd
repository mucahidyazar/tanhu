extends TestCase
## Kayıt → yükle turu (Yol Haritası save-v2, inventory, levels-skills, session-core; godot.md §3.4): oturumun blokları (map, saat,
## ilerleme, envanter; Serbest Gez'de hava) kayda dolu yazılır ve yeni bir oturuma aynen geri okunur. Saf sınamalar oturumu ağaçsız
## kurar; sahne sınamaları gerçek ana sahnede oto kaydın (Ana Menü, kapı) ve Devam Et'in turunu yürür: deneme haritasındaki kayıt
## haritaya, kaydedilen yere döner; Serbest Gez'in kaydı saatini, havasını ve envanterini taşır. Oyuncunun v1 kaydı göçle okunmaya
## devam eder; bozuk envanter bloğu kaydı boş yuva yapar. Bağlar: Tan'da bozulma, uzun atlamada şafak sayısı, sentenced'ta el koyma ve
## mq_errands'ta iade, perde geçişi ilerlemeye, hikâyede takvim günü saatle aynı yönde. Kayıtlar geçici klasördedir.

const TempDir := preload("res://tests/support/temp_dir.gd")
const MAIN_SCENE := "res://scenes/main.tscn"
const V1_FIXTURE := "res://tests/fixtures/save_v1_roam.json"

var _dir := ""
var _nodes: Array[Node] = []


func before_each() -> void:
	MenuStyle.muted = true
	_dir = TempDir.fresh("kayit_turu")


func after_each() -> void:
	get_tree().paused = false
	for n in _nodes:
		if is_instance_valid(n):
			n.queue_free()
	_nodes.clear()
	TempDir.wipe(_dir)


func _session(journey: Journey, mode: StringName = Session.MODE_ROAM) -> Session:
	var s := Session.new()
	s.auto_tick = false
	assert_eq(s.setup(journey, mode), "", "Oturum kurulmalı")
	return s


# --- Saf tur ---------------------------------------------------------------------------------------------------------

func test_every_session_block_round_trips() -> void:
	var saves := SaveSystem.new(_dir)
	var j := Journey.new(saves)
	var s := _session(j)
	# Kayıtsız oturum: başlangıç donanımı ve kökenin ilerlemesi.
	assert_eq(s.inventory.equipped("body"), "hostage_coat", "Bloğu olmayan envanter: Kışlak Kaftanı")
	assert_eq(s.inventory.equipped("cape"), "cape_hostage", "Kışlak Pelerini")
	assert_eq(s.inventory.count("notch_stick"), 1, "Çentik Çubuğu heybede")
	assert_eq(s.progression.level, 1)
	# Oyun: odun ve et heybeye, sandığa taş, yere yığın; XP; saat ilerler; oyuncu deneme haritasında.
	s.inventory.add("wood_pine", 2, "gather")
	s.inventory.add("meat", 3, "hunt")
	s.inventory.chest.add("stone", 2)
	s.inventory.drop("wood_pine", 1, Vector3(3.0, 0.2, -4.0))
	s.progression.add_xp(300, "test")
	s.clock.skip(95.0, &"wait")
	s.map_source = func() -> Dictionary: return {"id": "testmap", "pos": [12.5, 0.4, -7.25], "yaw": 1.25}
	var inv_before := s.inventory.to_dict()
	var prog_before := s.progression.to_dict()
	var clock_before := s.clock.abs_minute()
	assert_true(j.save_manual(2), "Elle kayıt")
	var rec := saves.slot_info(2)
	var blocks: Dictionary = rec.get("blocks", {})
	for b in ["map", "clock", "progression", "inventory"]:
		assert_true(blocks.has(b), "Kayıtta %s bloğu" % b)
		assert_true(int((blocks.get(b, {}) as Dictionary).get("v", 0)) >= 1, "%s bloğunun sürümü" % b)
	assert_eq(str(blocks["map"]["id"]), "testmap", "map bloğu dünyanın kimliği")
	assert_eq(blocks["map"]["pos"], [12.5, 0.4, -7.25], "map bloğu oyuncunun yeri")
	assert_true(SaveData.is_record(rec), "Kayıt okunabilir")
	s.free()
	# Yükle: yeni yolculuk, yeni oturum.
	var j2 := Journey.new(saves)
	assert_true(j2.apply_record(rec))
	var s2 := _session(j2)
	assert_eq(_json(s2.inventory.to_dict()), _json(inv_before), "Envanter aynen geri gelir (heybe, kuşam, sandık, yer yığını, gün)")
	assert_eq(_json(s2.progression.to_dict()), _json(prog_before), "İlerleme aynen geri gelir")
	assert_eq(s2.progression.level, 2, "300 XP: seviye 2 (eşik 250)")
	assert_almost(s2.clock.abs_minute(), clock_before, 1e-6, "Saat kaydedildiği dakikada")
	var place := s2.saved_place()
	assert_eq(str(place.get("id", "")), "testmap", "Kaydın yeri: deneme haritası")
	assert_vec_almost(place["pos"], Vector3(12.5, 0.4, -7.25), 1e-6)
	assert_almost(float(place["yaw"]), 1.25, 1e-9)
	assert_eq(j2.map, "testmap", "Yolculuğun dünyası blokla gelir")
	assert_true(s2.clock.has_place(), "Saatin yeri haritanın enlemi (evreler)")
	assert_almost(s2.clock.lat, 44.0, 1e-9, "Deneme haritası 44°K (light.json)")
	assert_eq(s2.inventory.piles().size(), 1, "Yer yığını kayıtta")
	assert_eq(s2.inventory.chest.amount("stone"), 2, "Sandık kayıtta")
	# İkinci tur: okunan oturumun yazdığı kayıt da aynı.
	assert_true(j2.save_manual(3))
	var again: Dictionary = saves.slot_info(3)["blocks"]
	for b in ["clock", "progression", "inventory"]:
		assert_eq(_json(_strip(again[b])), _json(_strip(blocks[b])), "%s bloğu iki turda aynı" % b)
	s2.free()


func test_missing_blocks_start_fresh_and_v1_save_still_loads() -> void:
	var saves := SaveSystem.new(_dir)
	var text := FileAccess.get_file_as_string(V1_FIXTURE)
	var f := FileAccess.open(saves.slot_path(SaveSystem.AUTO_SLOT), FileAccess.WRITE)
	f.store_string(text)
	f.close()
	var info := saves.slot_info(SaveSystem.AUTO_SLOT)
	assert_false(info.is_empty(), "Oyuncunun v1 kaydı okunur")
	var j := Journey.new(saves)
	assert_true(j.apply_record(info))
	var s := _session(j)
	assert_eq(s.saved_place(), {}, "v1 kaydında map bloğu yok: kampa, kaydın yerine inilir")
	assert_eq(j.map, "camp")
	assert_eq(s.clock.day_n, GameClock.ROAM_DAY, "Saat bloğu yok: 11 Nisan MÖ 209")
	assert_eq(s.inventory.equipped("body"), "hostage_coat", "Envanter bloğu yok: başlangıç donanımı")
	assert_eq(s.progression.level, 1, "İlerleme bloğu yok: köken, seviye 1")
	assert_eq(FileAccess.get_file_as_string(saves.slot_path(SaveSystem.AUTO_SLOT)), text, "Oyuncunun dosyası okunurken değişmez")
	s.free()


func test_corrupt_inventory_block_is_an_empty_slot() -> void:
	var saves := SaveSystem.new(_dir)
	var j := Journey.new(saves)
	var s := _session(j)
	assert_true(j.save_manual(1))
	s.free()
	var rec := saves.slot_info(1)
	var bad := rec.duplicate(true)
	bad["blocks"]["inventory"] = "bozuk"
	assert_false(SaveData.is_record(bad), "Sözlük olmayan envanter bloğu: kayıt boş yuva sayılır")
	var bad2 := rec.duplicate(true)
	bad2["blocks"]["inventory"]["v"] = 99
	var j2 := Journey.new(saves)
	assert_true(j2.apply_record(bad2))
	var s2 := Session.new()
	var err := s2.setup(j2, Session.MODE_ROAM)
	assert_true(err.contains("inventory"), "Okunamayan envanter bloğu kurulumu düşürür (kısmi yükleme yok): %s" % err)
	s2.free()
	var bad3 := rec.duplicate(true)
	bad3["blocks"]["map"] = {"v": 1, "id": "testmap", "pos": [1.0, "x", 2.0]}
	var j3 := Journey.new(saves)
	assert_true(j3.apply_record(bad3))
	var s3 := Session.new()
	assert_true(s3.setup(j3, Session.MODE_ROAM).contains("map"), "Bozuk map bloğu da okunmaz")
	s3.free()


# --- Bağlar ---------------------------------------------------------------------------------------------------------

func test_dawn_spoils_and_long_skip_counts_dawns() -> void:
	var j := Journey.new(SaveSystem.new(_dir))
	var s := _session(j)
	s.inventory.add("meat", 2, "hunt")
	var spoiled: Array = []
	s.inventory.item_spoiled.connect(func(_c: String, id: String, n: int) -> void: spoiled.append([id, n]))
	s.clock.skip(s.clock.next(&"dawn") - s.clock.abs_minute() + 1.0, &"wait")
	assert_eq(spoiled, [], "İlk şafakta çiğ et durur")
	s.clock.skip(s.clock.next(&"dawn") - s.clock.abs_minute() + 1.0, &"sleep", true)
	assert_eq(spoiled, [["meat", 2]], "İkinci şafakta bozulur (atlamanın içindeki Tan)")
	s.inventory.add("meat", 1, "hunt")
	var day := s.inventory.day
	s.clock.skip(GameClock.DAY_MIN * 3.0, &"dev")
	assert_eq(s.inventory.day, day + 3, "Uzun atlama (sınır olayı yok): şafak sayısı kadar ileri")
	assert_eq(spoiled.back(), ["meat", 1], "Uzun atlamada da bozulur")
	s.free()


func test_flags_act_and_quests_reach_progression_and_inventory() -> void:
	var j := Journey.new(SaveSystem.new(_dir))
	var s := _session(j)
	s.inventory.add("wood_pine", 1, "gather")
	j.set_flag("sentenced")
	assert_false(s.inventory.seized.is_empty(), "sentenced: el koyma (Session bayrağı envantere iletir)")
	assert_eq(s.inventory.count("wood_pine"), 0, "Odun çuvalda")
	s.quest_done("mq_errands")
	assert_true(s.inventory.seized.is_empty(), "mq_errands bitince çuval geri gelir")
	assert_eq(s.inventory.count("wood_pine"), 1)
	s.set_act(2)
	assert_eq(s.progression.act, 2, "Perde geçişi ilerlemenin tavanını açar")
	assert_eq(j.act, 2)
	assert_eq(s.services().get("progress"), s.progression, "«progress» etki hizmeti Progression")
	assert_eq(s.services().get("inventory"), s.inventory, "«inventory» etki hizmeti Inventory")
	assert_eq(s.apply_effects([["give", "stone", 2]], "test"), PackedStringArray(), "give op'u envantere")
	assert_true(s.holds("item:stone:2 && level>=1 && !item:stone:3"), "Koşul kaynakları: item: (adetle), level")
	s.free()


func test_grip_and_carry_pack_set_the_load_limit() -> void:
	var j := Journey.new(SaveSystem.new(_dir))
	var s := _session(j)
	assert_almost(s.inventory.capacity(), CarryLoad.cap_of(float(s.progression.stats["grip"]), false, s.inventory.gear_load()), 1e-6,
		"Sınır ilerlemenin Bilek'inden")
	s.progression.stats["grip"] = 6
	s.progression.changed.emit()
	assert_almost(s.inventory.grip, 6.0, 1e-9, "Bilek envantere yazılır")
	s.free()


func test_story_calendar_walks_with_the_clock() -> void:
	var j := Journey.new(SaveSystem.new(_dir))
	j.reset()
	j.set_flag(NewGameFlow.DAY_FLAG, 1041)
	var s := _session(j, Session.MODE_STORY)
	assert_eq(s.clock.day_n, 1041)
	assert_almost(s.clock.minute, Session.STORY_MINUTE, 1e-9, "Hikâye 10:00'da açılır")
	s.clock.skip(GameClock.DAY_MIN - s.clock.minute + 30.0, &"sleep", true)
	assert_eq(int(j.get_flag(NewGameFlow.DAY_FLAG)), 1042, "Gece yarısı takvim günü ilerler")
	s.clock.skip(GameClock.DAY_MIN * 2.5, &"dev")
	assert_eq(int(j.get_flag(NewGameFlow.DAY_FLAG)), s.clock.day_n, "Uzun atlama: takvim saatin gününde")
	s.free()


# --- Ana sahne ------------------------------------------------------------------------------------------------------

func test_testmap_autosave_and_continue_return_to_the_map() -> void:
	var main = _new_main()
	await wait_frames(3)
	main.menu.finish_intro()
	await wait_frames(1)
	await main._dev_testmap({})
	assert_eq(main.state, main.State.PLAYING)
	var s: Session = main.session
	assert_not_null(s, "Deneme haritasında oturum var")
	if s == null:
		await _end(main)
		return
	assert_eq(main.gameplay_hud.bag.inventory, s.inventory, "HUD'un heybesi oturumun envanteri")
	assert_eq(main.gameplay_hud.vitals.progression, s.progression, "Seviye ve XP ilerlemeden")
	assert_eq(s.inventory.equipped("body"), "hostage_coat", "Yetişkin başlangıç donanımıyla")
	# Haritanın katmanları (ateş ve av, toplama) kendi deneme takımlarını verir: takım sandığa konur (heybe boşalır), sınama onlarda
	# olmayan eşyayla yürür.
	await _wait_until(func() -> bool: return main.gameplay_hud.is_shown(), 4.0)
	await wait_frames(10)
	s.inventory.move_all(s.inventory.pack, s.inventory.chest, null, Callable(), true)
	var rope_before: int = s.inventory.count("rope")
	var stone_before: int = s.inventory.chest.amount("stone")
	assert_eq(int(s.inventory.add("rope", 2, "gather")["added"]), 2, "İp heybeye")
	s.inventory.chest.add("stone", 1)
	s.progression.add_xp(300, "test")
	assert_eq(main.gameplay_hud.vitals.level, 2, "HUD'un rozeti gerçek seviyeyi okur")
	var spot := Vector3(18.0, 0.0, 26.0)
	main.player.spawn_at(spot, 0.6)
	var at: Vector3 = main.player.global_position
	var minute: float = s.clock.abs_minute()
	await _open_pause(main)
	assert_eq(main.pause_menu.save_note, "", "Haritada KAYDET açık")
	(main.pause_menu.get_menu() as GameMenu)._on_general("main")
	await _wait_until(func() -> bool: return main.state == main.State.MENU, 12.0)
	var auto: Dictionary = main.saves.slot_info(SaveSystem.AUTO_SLOT)
	assert_eq(str(auto.get("reason", "")), "to_menu")
	var blocks: Dictionary = auto.get("blocks", {})
	for b in ["map", "clock", "progression", "inventory"]:
		assert_true(blocks.has(b), "Oto kayıtta %s bloğu dolu" % b)
	assert_eq(str((blocks.get("map", {}) as Dictionary).get("id", "")), "testmap")
	assert_null(main.session, "Menüde oturum yok")
	main.menu.continue_requested.emit()
	await _wait_until(func() -> bool: return main.state == main.State.PLAYING, 15.0)
	assert_eq(main.state, main.State.PLAYING, "Devam Et")
	assert_true(main._map_world is MapWorld, "Kayıt haritaya döndü")
	assert_true(_flat(main.player.global_position, at) < 0.3, "Kaydedilen yerde (%s ~ %s)" % [main.player.global_position, at])
	assert_almost(main.player.get_facing_yaw(), 0.6, 0.01, "Kaydedilen yöne bakar")
	assert_false(main.player.is_child(), "Oluşturulan Mete")
	var s2: Session = main.session
	assert_not_null(s2)
	if s2:
		assert_eq(s2.inventory.count("rope"), rope_before + 2, "Heybe kayıttan")
		assert_eq(s2.inventory.chest.amount("stone"), stone_before + 1, "Sandık kayıttan")
		assert_eq(s2.progression.level, 2, "Seviye kayıttan")
		assert_eq(main.gameplay_hud.bag.inventory, s2.inventory, "HUD yeni oturumun envanterini okur")
		assert_eq(main.gameplay_hud.vitals.level, 2, "Rozet kayıttaki seviyeyi gösterir")
		assert_true(absf(s2.clock.abs_minute() - minute) < 1.0, "Saat kayıttan")
	await _end(main)


func test_free_roam_autosave_carries_weather_and_round_trips() -> void:
	var main = _new_main()
	await wait_frames(3)
	main.menu.free_roam_requested.emit()
	await _wait_until(func() -> bool: return main.state == main.State.PLAYING, 10.0)
	var s: Session = main.session
	assert_not_null(s)
	if s == null:
		await _end(main)
		return
	assert_not_null(s.get_system(&"camp_weather"), "Kamp havası oturumun 3. adımı")
	assert_true(main._camp_weather.stepped_by_session, "Hava oturumla adım atar")
	assert_true(s.blocks.has_block("weather"), "weather bloğu oturumun kaydında")
	assert_true(main.player.is_child(), "Serbest Gez'de Çocuk (K37)")
	assert_eq(s.inventory.body, Inventory.BODY_CHILD, "Çocuğun bedeni (kayıtsız beden)")
	await wait_frames(5)
	var weather_before: Dictionary = main._camp_weather.sim.to_dict()
	await _open_pause(main)
	(main.pause_menu.get_menu() as GameMenu)._on_general("main")
	await _wait_until(func() -> bool: return main.state == main.State.MENU, 12.0)
	assert_false(main._camp_weather.stepped_by_session, "Oturum kapanınca hava kendi adımına döner")
	var blocks: Dictionary = main.saves.slot_info(SaveSystem.AUTO_SLOT).get("blocks", {})
	for b in ["map", "clock", "weather", "progression", "inventory"]:
		assert_true(blocks.has(b), "Serbest Gez'in oto kaydında %s" % b)
	assert_eq(str((blocks.get("map", {}) as Dictionary).get("id", "")), "camp")
	assert_eq(str(blocks["weather"].get("zone", "")), str(weather_before.get("zone", "")), "Hava bloğu kampın")
	main.menu.continue_requested.emit()
	await _wait_until(func() -> bool: return main.state == main.State.PLAYING, 12.0)
	assert_null(main._map_world, "Kamp kaydı kampa döner")
	assert_true(main.player.is_child())
	if main.session:
		assert_true(main.session.blocks.has_block("weather"), "Yüklenen oturumda da hava bloğu")
	await _end(main)


# --- Yardımcılar ----------------------------------------------------------------------------------------------------

func _new_main() -> Node:
	var main = load(MAIN_SCENE).instantiate()
	main.quit_handler = func() -> void: pass
	main.saves = SaveSystem.new(_dir)
	main.prologue_path = ""
	add_child(main)
	_nodes.append(main)
	return main


func _end(main: Node) -> void:
	main.queue_free()
	var audio := get_node_or_null(^"/root/AudioManager")
	if audio:
		for p in audio.get_children():
			if p is AudioStreamPlayer:
				(p as AudioStreamPlayer).stop()
				(p as AudioStreamPlayer).stream = null
	await get_tree().create_timer(0.25).timeout


func _open_pause(main: Node) -> void:
	main.player.pause_requested.emit()
	await _wait_until(func() -> bool: return main.pause_menu.is_open(), 4.0)
	await wait_frames(2)


func _wait_until(cond: Callable, seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while not cond.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame


static func _json(d: Variant) -> String:
	return JSON.stringify(d, "", true)


static func _strip(d: Dictionary) -> Dictionary:
	var out := d.duplicate(true)
	out.erase("v")
	return out


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
