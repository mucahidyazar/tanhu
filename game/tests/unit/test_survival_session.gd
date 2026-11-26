extends TestCase
## Hayatta kalmanın oturuma bağlanması (godot.md §3.1 adım 4, §3.4 «survival»; time.md §7.4, §10.2, §10.5): Survival adım 4'ün (needs)
## üyesidir, «survival» bloğunu kaydeder ve kayıt gidiş dönüşünde aynı kalır; saat akınca Tokluk −5 / oyun saati, ateş oyun dakikası
## × 2,5 yakıt yer; uyku atlaması Tokluk'u ×0,25 düşürür ve ≥4 saatte yaraları kapatır, ateş başı dinlenme ×0,5 ve ≥2 saatte bir yara;
## görünür akış (Bekle'nin hızlı akışı) sonunda bir kez işlenir; 24 saatten uzun atlama çukurları kaldırır; şafakta bozulma.

const TempDir := preload("res://tests/support/temp_dir.gd")

var _dir := ""


func before_each() -> void:
	_dir = TempDir.fresh("hayatta_kalma")


func after_each() -> void:
	TempDir.wipe(_dir)


func _session(mode: StringName = Session.MODE_STORY) -> Session:
	var s := Session.new()
	s.auto_tick = false
	assert_eq(s.setup(Journey.new(SaveSystem.new(_dir)), mode), "", "Oturum kurulmalı")
	return s


## Saati sec gerçek saniye kadar oturumla yürütür (0,25 sn'lik karelerle).
func _run(s: Session, sec: float) -> void:
	var left := sec
	while left > 1e-9:
		var dt := minf(0.25, left)
		s.tick(dt)
		left -= dt


func test_binds_into_step_four_and_registers_the_block() -> void:
	var s := _session()
	var sv := Survival.new({"difficulty": "normal"})
	assert_true(sv.bind_session(s))
	assert_eq(s.members(&"needs"), [&"survival"] as Array[StringName], "Adım 4: Needs (Tokluk, Yara)")
	assert_true(s.blocks.has_block("survival"), "Kayıt v2'nin survival bloğu")
	assert_eq(sv.clock, s.clock, "Oturumun saati")
	var roam := _session(Session.MODE_ROAM)
	var sv2 := Survival.new()
	sv2.bind_session(roam, {"save": false})
	assert_false(roam.blocks.has_block("survival"), "Deneme haritası bloğu Serbest Gez kaydına yazmaz")
	sv2.unbind_session()
	assert_eq(roam.members(&"needs").size(), 0, "Ayrılınca adımdan çıkar")
	s.free()
	roam.free()


func test_clock_drives_fullness_and_fuel() -> void:
	var s := _session()
	var sv := Survival.new()
	sv.bind_session(s)
	var f := sv.fires.add(Vector2.ZERO, sv.zone, false, 720.0, s.clock.abs_minute())
	_run(s, 150.0)
	sv.flush_needs()
	# Tokluk her güncellemede 1e-6'ya yuvarlanır (prototip): dakikalık işlemede saatte en çok ≈3e-5 birikir.
	assert_almost(sv.needs.fullness, 55.0, 1e-4, "Bir oyun saati (150 sn) −5")
	assert_almost(f.fuel, 570.0, 1e-6, "Ateş 150 sn yaktı")
	s.set_pause(&"dialogue", true)
	_run(s, 30.0)
	sv.flush_needs()
	assert_almost(sv.needs.fullness, 55.0, 1e-4, "Saat durunca Tokluk durur")
	assert_almost(f.fuel, 570.0, 1e-6, "Saat durunca ateş de durur")
	s.free()


func test_sleep_rest_and_lapse_skips() -> void:
	var s := _session()
	var sv := Survival.new({"difficulty": "story"})
	sv.bind_session(s)
	sv.needs.fullness = 80.0
	sv.wounds.add(3)
	var f := sv.fires.add(Vector2.ZERO, sv.zone, true, 720.0, s.clock.abs_minute())
	s.clock.skip(180.0, &"rest")
	assert_almost(sv.needs.fullness, 80.0 - 15.0 * 0.5 * 0.7, 1e-6, "Ateş başı dinlenme ×0,5 (Hikâye ×0,7)")
	assert_eq(sv.wounds.count, 2, "≥2 saat dinlenme, Tokluk ≥25: Yara −1")
	assert_almost(f.fuel, 720.0 - 180.0 * 2.5 * (2.0 / 3.0), 1e-6, "Atlamada ateş atlanan dakikayla yanar")
	s.clock.skip(480.0, &"sleep", true)
	assert_eq(sv.wounds.count, 0, "≥4 saat uyku bütün yaraları kapatır")
	assert_almost(sv.needs.fullness, 80.0 - 5.25 - 480.0 / 60.0 * 5.0 * 0.25 * 0.7, 1e-6, "Uyku ×0,25")
	assert_true(f.is_pit(), "Bakımsız ateş uykuda söner")
	var before := sv.needs.fullness
	assert_true(s.clock.begin_lapse(s.clock.abs_minute() + 60.0, 2.0, &"wait"))
	_run(s, 1.0)
	assert_almost(sv.needs.fullness, before, 1e-9, "Akış sürerken iş beklenir")
	_run(s, 1.0)
	assert_false(s.clock.is_lapsing())
	assert_almost(sv.needs.fullness, before - 5.0 * 0.7, 1e-6, "Akışın sonunda bir kez: 1 saat uyanık")
	s.clock.skip(1500.0, &"travel")
	assert_eq(sv.fires.fires.size(), 0, "24 saatten uzun atlama çukurları kaldırır")
	s.free()


func test_dawn_spoils_raw_food_through_the_session() -> void:
	var s := _session()
	s.clock.set_place(Daylight.CAMP_LAT, Daylight.CAMP_DEC_OFFSET)
	var inv := Inventory.new()
	var sv := Survival.new({"inventory": inv})
	sv.bind_session(s)
	inv.add("fish", 1)
	inv.add("meat", 1)
	for i in 2:
		s.clock.skip(s.clock.next(&"dawn") - s.clock.abs_minute() + 1.0, &"wait")
	assert_eq(inv.count("meat"), 0, "Çiğ et ikinci şafakta bozulur")
	assert_eq(inv.count("fish"), 0, "Balık da (kış dünyası değilse)")
	assert_eq(inv.count("spoiled"), 2, "Bozuk Et")
	s.free()


func test_save_block_round_trip_through_the_session() -> void:
	var s := _session()
	var sv := Survival.new({"difficulty": "normal"})
	sv.bind_session(s)
	sv.fires.add(Vector2(5.0, 6.0), sv.zone, true, 400.0, s.clock.abs_minute())
	sv.needs.fullness = 33.0
	sv.wounds.add(2)
	var blocks := s.blocks.collect()
	assert_true(blocks.has("survival"))
	assert_eq(int(blocks["survival"]["v"]), Survival.BLOCK_V)
	var text := JSON.stringify(blocks)
	var s2 := _session()
	var sv2 := Survival.new({"difficulty": "normal"})
	sv2.bind_session(s2)
	assert_eq(s2.blocks.apply(JSON.parse_string(text)), "", "Blok okunur")
	assert_eq(sv2.fires.fires.size(), 1)
	assert_true(sv2.fires.fires[0].stones)
	assert_almost(sv2.needs.fullness, 33.0, 1e-9)
	assert_eq(sv2.wounds.count, 2)
	assert_eq(SaveBlocks.OWNERS["survival"], "Survival", "Bloğun sahibi Survival")
	var bad := JSON.parse_string(text) as Dictionary
	bad["survival"]["fires"] = "bozuk"
	var s3 := _session()
	var sv3 := Survival.new()
	sv3.bind_session(s3)
	assert_ne(s3.blocks.apply(bad), "", "Bozuk blok kaydı açmaz (boş yuva)")
	s.free()
	s2.free()
	s3.free()
