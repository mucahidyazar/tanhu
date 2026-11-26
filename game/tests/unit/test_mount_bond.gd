extends TestCase
## Bağ'ın oyundaki tetikleri (StableLayer; Yol Haritası mount-bond-actions; progression.md §6.4, fauna.md §2.1, act1.md §8.8): ahırda atın
## başında yem (Yem Bağı, +5, günde en çok 3; sınırda yem gitmez), tımar (+2, günde 1), ad koyma (+10, bir kez; sabit adlı ata konmaz), ant
## (+10, bir kez, bayrağı yazılır), Yem Bağı yapma (2 ot → 1), yular tak ve çıkar. Yularla binmenin süresi: başı çıplak atı yeleden tutmak
## 1 sn × (1 − Bağ/100), yular ve gem kaldırır (MountStable.take_seconds; PlayerController'ın binişinde ölçülür).

const DT := 1.0 / 60.0
const BROWN := "res://assets/animals/horse_brown/horse_brown.glb"


class FlatShape:
	extends TerrainShape

	func height_at(_x: float, _z: float) -> float:
		return 0.0


var _trash: Array[Node] = []


func before_each() -> void:
	Mount.reset_cache()


func after_each() -> void:
	for node in _trash:
		if is_instance_valid(node):
			node.queue_free()
	_trash.clear()


func test_take_seconds_rule() -> void:
	assert_almost(MountStable.take_seconds(1.0, 0.0, ""), 1.0, 0.0001, "Çıplak baş, Bağ 0: 1 sn")
	assert_almost(MountStable.take_seconds(1.0, 50.0, ""), 0.5, 0.0001, "Bağ 50: yarısı")
	assert_almost(MountStable.take_seconds(1.0, 100.0, ""), 0.0, 0.0001, "Bağ 100: hemen")
	assert_almost(MountStable.take_seconds(1.0, 0.0, "halter", -1.0), 0.0, 0.0001, "Yular: −1 sn")
	assert_almost(MountStable.take_seconds(1.0, 0.0, "bridle_bone"), 0.0, 0.0001, "Gemli at dizginle tutulur")
	assert_almost(MountStable.take_seconds(0.0, 0.0, ""), 0.0, 0.0001, "Satırında tutma yok (koyun)")
	assert_almost(Mount.new("horse").value("catch_s"), 1.0, 0.0001, "Atın satırı (mounts.json catch_s)")
	assert_almost(Mount.new("offering_stallion").value("catch_s"), 1.0, 0.0001, "Aygır satırı kalıtır")


func test_halter_shortens_mounting_a_bare_headed_horse() -> void:
	var bare := await _mount_seconds("")
	var haltered := await _mount_seconds("halter")
	assert_true(bare - haltered >= 0.95 and bare - haltered <= 1.05, "Yular binişi 1 sn kısaltır (%.2f → %.2f sn)" % [bare, haltered])


func test_stable_feed_groom_name_oath_and_halter() -> void:
	var setup := await _stable_layer()
	var layer: StableLayer = setup["layer"]
	var key: String = setup["key"]
	var inv: Inventory = layer.inventory_override
	var ms := layer.stable()
	var start := ms.bond(key)
	assert_true(layer.in_stable(key), "At ahırda")
	assert_eq(layer.horse_at_head(), key, "Oyuncu atın başında")
	assert_eq(str(layer.e_job(key)["kind"]), "feed")
	assert_false(bool(layer.e_job(key)["ok"]), "Yem Bağı yok")
	# Yem Bağı yap: 2 ot → 1 Yem Bağı.
	inv.add("hay", 2, "test", true)
	assert_eq(str(layer.e_job(key)["kind"]), "craft", "İki otla Yem Bağı yapılır")
	assert_true(layer.craft_fodder())
	assert_eq(inv.count("fodder"), 1)
	assert_eq(inv.count("hay"), 0)
	# Yem: +5, günde en çok 3; sınırda yem gitmez.
	inv.add("fodder", 3, "test", true)
	for i in 3:
		var r := layer.feed(key)
		assert_almost(float(r["gained"]), 5.0, 0.001, "Yem %d: Bağ +5" % (i + 1))
	assert_almost(ms.bond(key), start + 15.0, 0.001)
	var capped := layer.feed(key)
	assert_eq(str(capped["reason"]), "day_cap", "Günde üçten fazla yem yok")
	assert_eq(inv.count("fodder"), 1, "Sınırda yem gitmez")
	layer.day_override = 2
	assert_almost(float(layer.feed(key)["gained"]), 5.0, 0.001, "Ertesi gün yine yer")
	# Tımar: +2, günde 1.
	assert_almost(float(layer.groom(key)["gained"]), 2.0, 0.001, "Tımar +2")
	assert_eq(str(layer.groom(key)["reason"]), "day_cap", "Günde bir tımar")
	# Ad: +10, bir kez. Öneriler çift dilli satırlardır ({tr, en}), arayüzün dilinde gelir.
	assert_true(layer.can_name(key))
	assert_eq(str(layer.f_job(key)["kind"]), "name", "F: Ad Koy")
	layer.def["names"] = (JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/kislak/stable.json")) as Dictionary)["names"]
	var tr_names := layer.name_suggestions(key)
	assert_true(tr_names.size() >= 5 and tr_names.has("Yağız"), "Türkçe öneriler: %s" % [tr_names])
	layer.lang = "en"
	assert_true(layer.name_suggestions(key).has("Yagiz"), "İngilizce öneriler")
	layer.lang = "tr"
	assert_almost(float(layer.name_horse(key, "  Kula  ")["gained"]), 10.0, 0.001, "Ad koymak +10")
	assert_eq(layer.horse_name(key), "Kula", "Adın temizi")
	assert_false(layer.can_name(key), "Ad bir kez konur")
	# Ant: +10, bir kez, bayrak.
	assert_eq(str(layer.f_job(key)["kind"]), "oath", "F: Ant İç")
	assert_almost(float(layer.swear(key)["gained"]), 10.0, 0.001, "Ant +10")
	assert_eq(str(layer.swear(key)["reason"]), "once", "Ant bir kez")
	assert_almost(ms.bond(key), start + 42.0, 0.001, "15 + 5 + 2 + 10 + 10")
	# Yular: tak (heybeden), çıkar (heybeye).
	inv.add("halter", 1, "test", true)
	assert_eq(str(layer.f_job(key)["kind"]), "halter_on", "F: Yular Tak (başı çıplak at)")
	assert_eq(layer.toggle_halter(key), "halter")
	assert_eq(inv.count("halter"), 0, "Yular atta")
	assert_almost(float(ms.gear_effects(key)["mount_time"]), -1.0, 0.001, "Yuların etkisi")
	assert_eq(str(layer.f_job(key)["kind"]), "halter_off")
	assert_eq(layer.toggle_halter(key), "")
	assert_eq(inv.count("halter"), 1, "Yular heybeye döndü")
	# Sabit adlı ata (Yakve) ad konmaz.
	(layer.horses[key]["row"] as Dictionary)["name"] = {"tr": "Yakve", "en": "Yakwe"}
	ms._list[key]["name"] = null
	assert_false(layer.can_name(key), "Sabit adlı ata ad konmaz")
	assert_eq(layer.horse_name(key), "Yakve")


## Ahırın katmanı: oyuncu (yetişkin Mete), ahırın kurduğu bir at (başı çıplak, eyersiz), oyuncu atın başında.
func _stable_layer() -> Dictionary:
	var world := Node3D.new()
	add_child(world)
	_trash.append(world)
	var player := PlayerController.new()
	player.terrain_shape = FlatShape.new()
	player.start_active = false
	player.add_child(CharacterAvatar.new())
	add_child(player)
	_trash.append(player)
	player.set_process(false)
	await wait_frames(1)
	player.use_profile(CharacterProfile.new())
	player.set_active(true)
	var layer := StableLayer.new()
	layer.setup(world, {"stables": [{"id": "s", "at": [0, 0], "radius": 10.0, "horses": [
		{"id": "h1", "node": "StableHorse1", "mount": "horse", "model": "horse_brown", "at": [0, 0], "facing": 180.0,
			"gear": {"saddle": null, "bridle": null}, "oath": "oath_stallion"}]}]})
	world.add_child(layer)
	await wait_frames(2)
	layer.player = player
	layer.inventory_override = Inventory.new()
	layer.day_override = 1
	layer._attached = true
	var key := "horse@StableHorse1"
	assert_true(layer.horses.has(key), "Ahırın atı kuruldu")
	layer._ensure_entry(key)
	assert_eq(layer.stable().gear_of(key, "bridle"), "", "Ahırdaki at başı çıplak")
	assert_eq(layer.stable().gear_of(key, "saddle"), "", "ve eyersiz")
	var node: Rideable = layer.horses[key]["node"]
	var head := StableLayer.head_point(node)
	var yaw := node.global_rotation.y
	player.spawn_at(Vector3(head.x, 0.0, head.y) + Vector3(sin(yaw), 0.0, cos(yaw)) * 0.6, yaw + PI)
	return {"layer": layer, "key": key, "player": player}


## Başı çıplak (ya da yularlı) ata binişin süresi (sn; MOUNTING kipinde geçen).
func _mount_seconds(bridle: String) -> float:
	var horse := RideableHorse.new()
	horse.model_path = BROWN
	horse.effects_enabled = false
	add_child(horse)
	_trash.append(horse)
	horse.place(Vector3.ZERO, 0.0)
	var player := PlayerController.new()
	player.terrain_shape = FlatShape.new()
	player.start_active = false
	player.add_child(CharacterAvatar.new())
	add_child(player)
	_trash.append(player)
	player.set_process(false)
	await wait_frames(1)
	player.obstacles = []
	player.use_profile(CharacterProfile.new())
	player.set_active(true)
	var ms := MountStable.new()
	player.mount_stable = ms
	var key := horse.mount_key()
	ms.entry(key, "horse", 0.0)
	ms.set_gear(key, {"bridle": bridle if not bridle.is_empty() else null})
	player.spawn_at(Vector3(1.3, 0.0, 0.3), -PI * 0.5)
	assert_true(player.interact(), "E biner")
	var seconds := 0.0
	while player.get_stance() == PlayerController.Stance.MOUNTING and seconds < 6.0:
		player.step(DT, Vector2.ZERO, false, 0.0)
		seconds += DT
	assert_true(player.is_riding(), "Bindi")
	horse.queue_free()
	player.queue_free()
	return seconds
