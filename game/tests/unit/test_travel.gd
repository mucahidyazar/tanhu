extends TestCase
## Menzil ağının durumu (Travel, saf; travel.md §4.3, §7.1, §8, §11; act1.md §4 «Yol Kemikleri», «Menzil»; Yol Haritası roads-relays): bulma
## (15 m, bölge açık), bağlanma (bağlı Yol Kemiği), onarımın bedeli (1 kemik + 1 ip ya da 4 taş), kilitlerin sırası, ücret (ağda ilk sefer ve
## ties.kantu ≥5 parasız; 1 Aş ya da 1 odun), sefer saati (doğal süre × 0,4 oyun dk), kayıt bloğu (gidiş-dönüş, denetim, SaveBlocks).

const DEF := {
	"stations": [
		{"id": "way_a", "at": [0, 0], "node": "n_a", "bone": "", "region": "r0", "rank": 0},
		{"id": "way_b", "at": [100, 0], "node": "n_b", "bone": "RB1", "region": "r1", "rank": 1},
	],
	"bones": [{"id": "RB1", "at": [90, 3]}],
}


func before_each() -> void:
	Travel.reset_cache()


func _travel() -> Travel:
	var t := Travel.new()
	t.define(DEF)
	return t


func test_find_and_link_follow_the_three_conditions() -> void:
	var t := _travel()
	var seen: Array = []
	t.station_changed.connect(func(id: String, st: String) -> void: seen.append("%s:%s" % [id, st]))
	var links := watch_signal(t.linked)
	assert_eq(t.state_of("way_a"), "hidden")
	assert_false(t.on_near("way_a", 16.0, {"region_open": true}), "15 m'den uzakta bulunmaz")
	assert_true(t.on_near("way_a", 14.0, {"region_open": true}), "15 m'de bulunur")
	assert_eq(t.state_of("way_a"), "linked", "Direksiz durak bulununca bağlanır")
	assert_eq(links.count, 1)
	# Bölge kapalıyken bulunmaz; açılınca bulunur, direk onarılınca bağlanır.
	assert_false(t.on_near("way_b", 5.0, {"region_open": false}))
	assert_eq(t.state_of("way_b"), "hidden")
	assert_true(t.on_near("way_b", 5.0, {"region_open": true}))
	assert_eq(t.state_of("way_b"), "found", "Direği kırık: bulundu")
	assert_false(t.bone_ready("way_b"))
	var res := t.repair_bone("RB1", 600.0)
	assert_true(bool(res["ok"]))
	assert_eq(res["linked"], ["way_b"], "Onarım bağlı durağı bağlar")
	assert_eq(t.state_of("way_b"), "linked")
	assert_false(bool(t.repair_bone("RB1")["ok"]), "İkinci onarım yok")
	assert_eq(t.last_repaired_bone(), "RB1", "Tipide kayıt noktası: son onarılan direk")
	assert_eq(links.count, 2)
	# Durum yalnız ileri gider (force geri yazar).
	assert_false(t.set_station("way_b", "rumoured"))
	assert_true(t.set_station("way_b", "rumoured", true))
	assert_eq(seen[0], "way_a:found")


func test_region_open_reads_rank_and_dev_flags() -> void:
	var st := {"region": "pale_pasture", "rank": 1}
	assert_true(Travel.region_open({"rank": 0}, {}), "Rütbe 0 hep açık")
	assert_false(Travel.region_open(st, {}))
	assert_true(Travel.region_open(st, {"rank": 1}))
	assert_true(Travel.region_open(st, {"rank_3": true}), "Geliştirme bayrağı rank_N")
	assert_true(Travel.region_open(st, {"region.pale_pasture": true}))


func test_bone_cost_options() -> void:
	var inv := Inventory.new()
	assert_true(Travel.bone_cost(inv).is_empty(), "Malzeme yok")
	inv.add("bone", 1, "test", true)
	assert_true(Travel.bone_cost(inv).is_empty(), "Kemik tek başına yetmez")
	inv.add("rope", 1, "test", true)
	assert_eq(Travel.bone_cost(inv), {"bone": 1, "rope": 1}, "1 kemik + 1 ip")
	var inv2 := Inventory.new()
	inv2.add("stone", 4, "test", true)
	assert_eq(Travel.bone_cost(inv2), {"stone": 4}, "ya da 4 taş")
	assert_almost(float(Travel.rule("bone.repair_s")), 20.0, 0.001, "20 sn tırmanış")
	assert_almost(float(Travel.rule("bone.hum_m")), 120.0, 0.001, "120 m'den duyulur")


func test_locks_are_ordered_and_texted() -> void:
	var ok := Travel.allowed({"minute": 600.0})
	assert_true(bool(ok["ok"]), "Gündüz, bayraksız: açık")
	assert_eq(Travel.allowed({"minute": 1300.0})["code"], "night", "21:00'den sonra Kantu uyur")
	assert_eq(Travel.allowed({"minute": 300.0})["code"], "night", "07:30'dan önce")
	assert_eq(Travel.allowed({"minute": 460.0})["code"], "", "07:40 açık")
	assert_eq(Travel.allowed({"minute": 600.0, "requires_flag": "tally_kantu", "flags": {}})["code"], "no_tally")
	assert_eq(Travel.allowed({"minute": 1300.0, "requires_flag": "tally_kantu", "flags": {}})["code"], "no_tally", "Teker kırığı gece kilidinden önce")
	assert_eq(Travel.allowed({"flags": {"sentenced": true}, "minute": 1300.0})["code"], "bound", "Bağlısın en öndeki kilitlerden")
	var region := Travel.allowed({"region_open": false, "guarantor": "Farnak'ın çetelesi"})
	assert_eq(region["code"], "region_locked")
	assert_true(str(region["text"]).contains("Farnak"), "Kefil satırda: %s" % region["text"])
	assert_eq(Travel.allowed({"cargo": 41.0})["code"], "overload", "Yük 40'ı aşınca Yakve çekmez")
	assert_eq(Travel.allowed({"can_pay": false})["code"], "no_fare")
	assert_eq(Travel.allowed({"can_pay": false, "free": true})["code"], "", "Parasız seferde ücret sorulmaz")
	assert_eq(Travel.allowed({"cart_lock": true, "cart_lock_hours": 2.4}, "en")["text"], "No cart leaves until the storm passes (about 3 hours).")
	assert_eq((Travel.rule("locks", []) as Array).size(), 16, "travel.md §8'in 16 kilidi")


func test_fare_first_trip_free_then_meal_or_wood() -> void:
	var t := _travel()
	var inv := Inventory.new()
	inv.add("meal", 1, "test", true)
	inv.add("wood_pine", 1, "test", true)
	assert_true(t.fare_free(), "Ağda ilk sefer parasız")
	var first := t.pay_fare(inv)
	assert_true(bool(first["free"]))
	assert_eq(inv.count("meal"), 1, "İlk seferde bir şey alınmaz")
	assert_false(t.fare_free())
	assert_eq(Travel.fare_item(inv), "meal", "Önce Aş")
	t.pay_fare(inv)
	assert_eq(inv.count("meal"), 0)
	assert_eq(Travel.fare_item(inv), "tag:wood", "Sonra odun")
	t.pay_fare(inv)
	assert_eq(inv.count("tag:wood"), 0)
	assert_eq(Travel.fare_item(inv), "", "Mal yok")
	assert_true(t.fare_free({"ties.kantu": 5}), "ties.kantu ≥5 parasız")


func test_clock_and_speed_rules() -> void:
	assert_almost(Travel.clock_minutes(55.0), 22.0, 0.001, "55 sn → 22 oyun dk (travel.md §6.8)")
	assert_almost(Travel.clock_minutes(229.0), 91.6, 0.001, "229 sn → 1 sa 32 dk")
	assert_true(Travel.kantu_asleep(GameClock.parse_hhmm("21:00")))
	assert_false(Travel.kantu_asleep(GameClock.parse_hhmm("07:30")))
	assert_almost(float(Travel.rule("cart.skip.hold_s")), 3.0, 0.001, "Yolu Kısalt 3 sn")
	assert_almost(float(Travel.rule("cart.skip.cancel_before_s")), 2.4, 0.001)


func test_save_block_round_trip_and_validation() -> void:
	var t := _travel()
	t.on_near("way_a", 1.0, {"region_open": true})
	t.on_near("way_b", 1.0, {"region_open": true})
	t.repair_bone("RB1", 812.5)
	t.cart_at = "way_b"
	t.last_stop = "way_b"
	t.trips = 3
	t.gossip = ["g_ford"]
	t.ride = {"from": "way_a", "to": "way_b", "mode": "watch"}
	var d := t.to_dict()
	assert_eq(Travel.validate_save_block(d), "")
	assert_false((d["net"]["nodes"] as Dictionary).has("way_c"), "hidden yazılmaz")
	var json := JSON.stringify(d)
	assert_true(json.length() < Travel.MAX_BYTES, "Blok küçük (%d bayt)" % json.length())
	var back := Travel.new()
	assert_true(back.from_dict(JSON.parse_string(json)))
	assert_eq(back.state_of("way_b"), "linked")
	assert_true(back.is_repaired("RB1"))
	assert_eq(back.cart_at, "way_b")
	assert_eq(back.trips, 3)
	assert_eq((back.ride as Dictionary)["to"], "way_b", "Sefer kaydı (kalkışta yazılan)")
	assert_ne(Travel.validate_save_block({"net": {"nodes": {"x": "bogus"}}}), "", "Bilinmeyen durum reddedilir")
	assert_ne(Travel.validate_save_block({"net": []}), "")
	# SaveBlocks: kayıt, sahibin durağan denetimi (OWNERS «travel»).
	var blocks := SaveBlocks.new()
	t.register_block(blocks)
	var collected := blocks.collect()
	assert_true(collected.has("travel"))
	assert_eq(SaveBlocks.OWNERS.get("travel"), "Travel", "Bloğun sahibi Travel")
	var fresh := Travel.new()
	var blocks2 := SaveBlocks.new()
	fresh.register_block(blocks2)
	assert_eq(blocks2.apply(collected), "", "Yükleme hatasız")
	assert_eq(fresh.state_of("way_a"), "linked")
