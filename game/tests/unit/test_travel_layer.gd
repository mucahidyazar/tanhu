extends TestCase
## Menzil ağı oyunda (TravelLayer; Yol Haritası roads-relays; travel.md §4–§8, act1.md §9.4): gerçek ana sahnede deneme haritası (--state=testmap
## yolu; data/maps/testmap/travel.json). Katman kurulur (üç durak, üç direk, iki Yol Kemiği, Kantu'nun arabası Deneme Menzili'nde), oturuma
## bağlanır («travel» bloğu). Bulma (15 m) ve bağlanma (+10 XP), Yol Kemiği onarımı (bedel heybeden), direğe vuruş (araba durakta bekler),
## biniş ve Yol Kartı, Yolu Kısalt (saat kalan doğal süre kadar atlar, araba ve oyuncu yolun ucuna varır: ışınlanma yok, son 18 m sürülür),
## iniş, ücret (ilk sefer parasız, sonra 1 Aş), Yolu İzle (araba yolu gerçekten sürer, hız oyuncunun koşusunu aşmaz: K105), yolda inme, yük
## teslimi, gece kilidi, kayıt bloğu.

const MAIN_SCENE := "res://scenes/main.tscn"
const TempDir := preload("res://tests/support/temp_dir.gd")
const DT := 1.0 / 30.0

var _dir := ""


func before_each() -> void:
	MenuStyle.muted = true
	_dir = TempDir.fresh("menzil_agi")


func after_each() -> void:
	get_tree().paused = false
	TempDir.wipe(_dir)


func _new_main() -> Node:
	var main = load(MAIN_SCENE).instantiate()
	main.quit_handler = func() -> void: pass
	main.saves = SaveSystem.new(_dir)
	main.prologue_path = ""
	add_child(main)
	return main


func _layer(main: Node) -> TravelLayer:
	var map: MapWorld = main._map_world
	return map.get_node_or_null(^"Layers/Travel") as TravelLayer if map else null


## Arabanın adımı (katmanın karesi dışında, belirlenimci): sürüş biter ya da süre dolar.
func _drive(layer: TravelLayer, until: Callable, seconds: float) -> float:
	var t := 0.0
	while not until.call() and t < seconds:
		layer._step_cart(DT)
		t += DT
	return t


func test_waystations_bones_cart_and_a_shortened_trip() -> void:
	var main = _new_main()
	await wait_frames(3)
	main.menu.finish_intro()
	await wait_frames(1)
	await main._dev_testmap({})
	assert_eq(main.state, main.State.PLAYING)
	var layer := _layer(main)
	assert_not_null(layer, "Menzil katmanı haritada")
	if layer == null:
		main.queue_free()
		return
	await _wait_until(func() -> bool: return layer._attached, 5.0)
	assert_true(layer._attached, "Oturuma bağlandı")
	layer.set_process(false)
	var s: Session = main.session
	var player: PlayerController = main.player
	assert_true(s.blocks.has_block("travel"), "Kayıt v2'nin travel bloğu")
	assert_eq(layer.posts.posts.size(), 3, "Üç Menzil Direği")
	assert_eq(layer.posts.bones.size(), 2, "İki Yol Kemiği")
	assert_eq(layer.cart_station, "way_tm_yard", "Araba Deneme Menzili'nde")
	assert_true(layer.cart.axle_xz().distance_to(Vector2(56.0, 9.7)) < 0.2, "Dingil durağın noktasında")
	# Bulma: 15 m'de bulunur; direksiz durak bağlanır, +10 XP.
	var xp_before: int = s.progression.xp
	player.spawn_at(Vector3(52.0, 0.0, 22.0), 0.0)
	layer._discover()
	assert_eq(layer.travel.state_of("way_tm_yard"), "linked", "Deneme Menzili bağlandı")
	assert_eq(s.progression.xp - xp_before, 10, "Menzil +10 XP (waystation)")
	# Doğu Durağı bulunur ama direği kırık; Yol Kemiği onarılınca bağlanır (bedel: 1 kemik + 1 ip).
	player.spawn_at(Vector3(136.0, 0.0, 14.0), 0.0)
	layer._discover()
	assert_eq(layer.travel.state_of("way_tm_east"), "found", "Doğu Durağı bulundu, direği kırık")
	var inv: Inventory = s.inventory
	inv.add("bone", 1, "test", true)
	inv.add("rope", 1, "test", true)
	var bone_at := layer.bone_point("RB_TM1")
	player.spawn_at(Vector3(bone_at.x, 0.0, bone_at.y + 1.2), PI)
	assert_eq(layer.bone_in_reach(), "RB_TM1", "Yol Kemiği erimde")
	assert_true(layer.begin_repair("RB_TM1"), "Onarım başlar (E basılı 20 sn)")
	layer._repair = {}
	var res := layer.finish_repair("RB_TM1")
	assert_true(bool(res["ok"]))
	assert_eq(inv.count("bone"), 0, "Kemik heybeden düştü")
	assert_eq(inv.count("rope"), 0, "İp heybeden düştü")
	assert_eq(layer.travel.state_of("way_tm_east"), "linked", "Doğu Durağı bağlandı")
	# Gece kilidi: Kantu uyur.
	var day: int = s.clock.day_n
	s.clock.set_to(GameClock.abs_of(day + 1, 22.0 * 60.0), &"dev")
	assert_false(layer.strike("way_tm_yard"), "Gece direğe vurmak arabayı getirmez")
	s.clock.set_to(GameClock.abs_of(day + 2, 9.0 * 60.0), &"dev")
	# Direğe vuruş: araba zaten durakta, bekler; biniş; Yol Kartı.
	player.spawn_at(Vector3(56.0, 0.0, 16.0), PI)
	assert_true(layer.strike("way_tm_yard"), "Direğe vurunca araba bekler")
	assert_eq(layer.state, TravelLayer.Cart.WAITING)
	var tail := layer.cart.tail_point("S1", layer._ground())
	player.spawn_at(tail, layer.cart.heading + PI)
	assert_true(layer.tail_in_reach(), "Arabanın ardı erimde (≤2,6 m)")
	assert_true(layer.board(), "Biner")
	_drive(layer, func() -> bool: return layer.state == TravelLayer.Cart.CARD, 3.0)
	assert_eq(layer.state, TravelLayer.Cart.CARD, "Yol Kartı açık")
	assert_true(s.is_paused_by(&"modal") and s.clock.is_paused_by(&"modal"), "Kart açıkken saat durur")
	assert_true(player.carried, "Oyuncu arabada")
	var rows := layer.card_rows()
	var east: Dictionary = {}
	for r: Dictionary in rows:
		if str(r["id"]) == "way_tm_east":
			east = r
	assert_true(bool(east.get("enabled", false)), "Doğu Durağı kartta açık")
	assert_almost(float(east.get("meters", 0.0)), 84.2, 1.0, "Deneme Menzili → Doğu Durağı (%.1f m)" % float(east.get("meters", 0.0)))
	# Yolu Kısalt: saat kalan doğal süre kadar atlar, araba yolun ucuna varır (son 18 m sürülür).
	var minute_before: float = s.clock.abs_minute()
	inv.add("meal", 2, "test", true)
	assert_true(layer.depart("way_tm_east", "shorten"), "Kalkış (Yolu Kısalt)")
	assert_false(s.is_paused_by(&"modal"), "Kalkışta saat yürür")
	assert_eq(layer.travel.trips, 1, "İlk sefer")
	assert_eq(inv.count("meal"), 2, "Ağda ilk sefer parasız")
	_drive(layer, func() -> bool: return layer.state == TravelLayer.Cart.ARRIVE, 6.0)
	assert_eq(layer.state, TravelLayer.Cart.ARRIVE, "Kararmadan sonra varış")
	assert_almost(float(layer.last_skip.get("left_m", 0.0)), 18.0, 0.5, "Kararmada hedefe 18 m kalaya taşındı (%.1f m)" % float(layer.last_skip.get("left_m", 0.0)))
	var skipped: float = s.clock.abs_minute() - minute_before
	var jumped := float(layer.last_skip.get("minutes", 0.0))
	assert_true(jumped > 0.0, "Saat kalan doğal süre kadar atladı (%.1f oyun dk)" % jumped)
	assert_almost(jumped, Travel.clock_minutes(float(layer.last_skip["seconds"])), 0.001, "Doğal süre × 0,4")
	assert_true(float(layer.last_skip["seconds"]) >= (float(layer.last_skip["to_m"]) - float(layer.last_skip["from_m"])) / PaceLimit.ADULT_RUN - 0.01,
		"Atlanan süre en çok koşu hızındaki süredir")
	assert_true(skipped >= jumped - 0.01, "Saat atlamanın kadar ileri gitti (%.3f / %.3f dk)" % [skipped, jumped])
	_drive(layer, func() -> bool: return layer.state == TravelLayer.Cart.WAITING, 20.0)
	assert_eq(layer.state, TravelLayer.Cart.WAITING, "İnildi, araba bekler")
	assert_false(player.carried, "Oyuncu yerde")
	assert_true(player.is_active())
	assert_eq(layer.travel.last_stop, "way_tm_east")
	assert_true(layer.cart.axle_xz().distance_to(Vector2(140.0, 4.4)) < 2.0, "Araba Doğu Durağı'nda (%.2f m)" % layer.cart.axle_xz().distance_to(Vector2(140.0, 4.4)))
	var blk: Dictionary = s.blocks.collect().get("travel", {})
	assert_eq(blk.get("lastStop"), "way_tm_east", "Kayıt bloğu iniş durağını taşır")
	assert_eq(blk.get("ride"), null, "İnince ride yok")
	# Yolu İzle: araba yolu sürer, hız oyuncunun koşusunu aşmaz (K105); ikinci sefer 1 Aş; yük Ambar durağında teslim.
	inv.add("wood_pine", 2, "test", true)
	inv.move(inv.pack, inv.cart, "wood_pine", 2, true)
	assert_eq(inv.cart.count("wood_pine"), 2, "Yük Bindir: araba kabında 2 odun")
	tail = layer.cart.tail_point("S1", layer._ground())
	player.spawn_at(tail, layer.cart.heading + PI)
	assert_true(layer.board())
	_drive(layer, func() -> bool: return layer.state == TravelLayer.Cart.CARD, 3.0)
	assert_true(layer.depart("way_tm_yard", "watch"), "Kalkış (Yolu İzle)")
	assert_eq(inv.count("meal"), 1, "Ücret 1 Aş")
	var fastest := 0.0
	var probe := PaceLimit.Probe.new()
	var t := 0.0
	while layer.state != TravelLayer.Cart.WAITING and t < 60.0:
		layer._step_cart(DT)
		t += DT
		fastest = maxf(fastest, float(layer.drive.get("speed", 0.0)))
		probe.sample("cart", layer.cart.global_position, t)
	assert_eq(layer.state, TravelLayer.Cart.WAITING, "Yolu İzle bitti (%.1f sn)" % t)
	assert_true(fastest <= PaceLimit.ADULT_RUN + 0.01, "Araba oyuncunun koşusunu aşmaz (%.2f m/sn)" % fastest)
	assert_true(probe.peak("cart") <= PaceLimit.ADULT_RUN + PaceLimit.TOLERANCE + 0.05, "Ölçülen en yüksek hız %.2f m/sn" % probe.peak("cart"))
	assert_true(t > 84.0 / PaceLimit.ADULT_RUN, "Yol gerçekten sürüldü (%.1f sn)" % t)
	assert_eq(inv.cart.count("wood_pine"), 0, "Yük indi")
	assert_eq(inv.stash("way_tm_yard").count("wood_pine"), 2, "Ambar durağında teslim (Menzil Ambarı)")
	# Yolda inme: araba 1,5 sn'de durur, inilir, araba Menzil'e döner.
	tail = layer.cart.tail_point("S1", layer._ground())
	player.spawn_at(tail, layer.cart.heading + PI)
	assert_true(layer.board())
	_drive(layer, func() -> bool: return layer.state == TravelLayer.Cart.CARD, 3.0)
	assert_true(layer.depart("way_tm_east", "watch"))
	_drive(layer, func() -> bool: return layer.remaining_m() < float(layer.drive["length"]) - 25.0, 20.0)
	layer._get_off()
	assert_eq(layer.state, TravelLayer.Cart.STOPPING)
	var stop_t := _drive(layer, func() -> bool: return layer.state == TravelLayer.Cart.ALIGHT, 4.0)
	assert_true(stop_t <= 2.0, "Araba ≈1,5 sn'de durur (%.2f sn)" % stop_t)
	_drive(layer, func() -> bool: return not player.carried, 2.0)
	assert_false(player.carried, "Yolda inildi")
	assert_ne(layer.travel.last_stop, "way_tm_east", "Yolda inilen yer durak değildir")
	assert_true(layer.state == TravelLayer.Cart.LEAVING or layer.state == TravelLayer.Cart.PARKED, "Araba Menzil'e döner")
	main.queue_free()
	await wait_frames(2)


func _wait_until(condition: Callable, timeout: float) -> void:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
