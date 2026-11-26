extends TestCase
## Kayıt v2 (godot.md §3.4, d2/core.md §6.2; Yol Haritası save-v2): SaveData, SaveBlocks, SaveSystem ve Journey. Geçici klasörde çalışır;
## oyuncunun kayıtlarına dokunulmaz.
##   - v2 kaydı: version 2, mode, act, map, seed ve bloklar; her blok kendi v'sini taşır; yazılıp okununca aynısı gelir.
##   - Blok sürümü ve göç zinciri (1 → 2 → 3), daha yeni sürüm okunmaz, eksik göç adımı veriyi olduğu gibi bırakır; kayıtta olmayan blok
##     varsayılanına döner; sahibi olmayan blok taşınır ve sonradan kaydeden sistem onu okur; bırakılan sistemin son hâli kalır.
##   - Bozuk blok boş yuva sayılır (yapı, sürüm, ad, saat bloğunun içeriği, daha yeni kayıt sürümü); sahibin denetimi tutmazsa hiçbir
##     blok okunmaz (kısmi yükleme yok).
##   - v1 göçü: oyuncunun bugünkü Serbest Gez kaydının biçimi (tests/fixtures/save_v1_roam.json) okunur: mode roam, map camp, act 0,
##     bloklar boş, tohum kayıttan (aynı kayıt aynı tohum); dosya değişmez. Destan açılışlarındaki eski kişi kimlikleri (ana, baba, cocuk,
##     ozan, ak_at, mete) bir kez çevrilir; yer ve olay işaretleri (cocuk_gezinti, ozan_dinledi) olduğu gibi kalır.
##   - Oto kayıt nedeni kayda yazılır; oto kayıt duraklatmanın karesi yoksa son küçük resmi korur, yeni yolculuğun ilki korumaz.
## Uydurma bloklar «test_» adlıdır: gerçek sahibi olan adlar (weather, party ...) sahibinin durağan denetiminden geçer (SaveBlocks.OWNERS).

const TempDir := preload("res://tests/support/temp_dir.gd")
const V1_FIXTURE := "res://tests/fixtures/save_v1_roam.json"

var dir := ""
var saves: SaveSystem


func before_each() -> void:
	dir = TempDir.fresh("kayit_v2")
	saves = SaveSystem.new(dir)


func after_each() -> void:
	TempDir.wipe(dir)


# --- v2 kaydı ---------------------------------------------------------------------------------------------------

func test_v2_record_round_trip() -> void:
	var j := Journey.new(saves)
	j.mode = SaveData.MODE_STORY
	j.act = 1
	j.map = "kislak"
	j.journey_seed = 123456
	var clock := GameClock.new(1041, 640.0)
	var weather := {"seed": 7, "plan": ["clear", "snow"]}
	var reg := SaveBlocks.new()
	reg.register("clock", 1, clock.to_dict, func(_d: Dictionary) -> void: pass)
	reg.register("test_weather", 3, func() -> Dictionary: return weather, func(_d: Dictionary) -> void: pass)
	j.live_blocks = reg
	assert_true(j.save_manual(2))
	var info := saves.slot_info(2)
	assert_eq(int(info["version"]), SaveData.VERSION, "Kayıt v2")
	var data := SaveData.parse(info)
	assert_eq(data["mode"], "story")
	assert_eq(data["act"], 1)
	assert_eq(data["map"], "kislak")
	assert_eq(data["seed"], 123456)
	var blocks: Dictionary = data["blocks"]
	assert_eq(int(blocks["clock"]["v"]), 1, "Blok kendi sürümünü taşır")
	assert_eq(int(blocks["clock"]["day_n"]), 1041)
	assert_almost(float(blocks["clock"]["minute"]), 640.0, 1e-9)
	assert_eq(int(blocks["test_weather"]["v"]), 3)
	assert_eq(blocks["test_weather"]["plan"], ["clear", "snow"])
	var other := Journey.new(saves)
	assert_true(other.apply_record(info))
	assert_eq(other.mode, "story")
	assert_eq(other.act, 1)
	assert_eq(other.map, "kislak")
	assert_eq(other.journey_seed, 123456, "Tohum kayıttan gelir")
	assert_eq(int(other.blocks["test_weather"]["v"]), 3, "Kaydın blokları yolculukta bekler (oturum okur)")
	var read := {}
	var back := SaveBlocks.new()
	back.register("clock", 1, func() -> Dictionary: return {}, func(d: Dictionary) -> void: read["clock"] = d)
	back.register("test_weather", 3, func() -> Dictionary: return {}, func(d: Dictionary) -> void: read["test_weather"] = d)
	assert_eq(back.apply(other.blocks), "", "Bloklar okunur")
	assert_eq(int(read["clock"]["day_n"]), 1041)
	assert_eq(read["test_weather"]["seed"], 7.0, "JSON sayıları kayan noktadır")


func test_record_merges_stored_and_live_blocks() -> void:
	var j := Journey.new(saves)
	j.blocks = {"test_party": {"v": 1, "members": ["ku"]}, "clock": {"v": 1, "day_n": 1, "minute": 0.0}}
	var clock := GameClock.new(1171, 900.0)
	var reg := SaveBlocks.new()
	reg.register("clock", 1, clock.to_dict, func(_d: Dictionary) -> void: pass)
	j.live_blocks = reg
	var blocks := j.collect_blocks()
	assert_eq(int(blocks["clock"]["day_n"]), 1171, "Oturumun bloğu kaydınkini ezer")
	assert_eq(blocks["test_party"]["members"], ["ku"], "Oturumu olmayan sistemin bloğu taşınır")
	j.live_blocks = null
	assert_eq(int(j.collect_blocks()["clock"]["day_n"]), 1, "Oturum yokken kaydın blokları")


func test_block_versions_and_migration_chain() -> void:
	var got := []
	var m1 := func(d: Dictionary) -> Dictionary:
		d["wet"] = 0.0
		return d
	var m2 := func(d: Dictionary) -> Dictionary:
		d["crust"] = d.get("wet", -1.0)
		return d
	var reg := SaveBlocks.new()
	reg.register("test_weather", 3, func() -> Dictionary: return {}, func(d: Dictionary) -> void: got.append(d), {"migrate": {1: m1, 2: m2}})
	assert_eq(reg.apply({"test_weather": {"v": 1, "seed": 4}}), "")
	assert_eq(got.size(), 1)
	assert_eq(int(got[0]["v"]), 3, "Göçten sonra güncel sürüm")
	assert_almost(float(got[0]["crust"]), 0.0, 1e-12, "1 → 2 → 3 sırayla")
	got.clear()
	assert_eq(reg.apply({"test_weather": {"v": 2, "seed": 4}}), "")
	assert_almost(float(got[0]["crust"]), -1.0, 1e-12, "v2 yalnız 2 → 3'ten geçer")
	got.clear()
	var err := reg.apply({"test_weather": {"v": 4, "seed": 4}})
	assert_true(err.contains("v4"), "Daha yeni sürüm okunmaz: %s" % err)
	assert_eq(got.size(), 0, "Hiçbir şey okunmadı")
	var gap := SaveBlocks.new()
	var kept := []
	gap.register("test_sites", 2, func() -> Dictionary: return {}, func(d: Dictionary) -> void: kept.append(d))
	assert_eq(gap.apply({"test_sites": {"v": 1, "pads": [1, 2]}}), "", "Eksik göç adımı yüklemeyi durdurmaz (uyarı)")
	assert_eq(kept[0]["pads"], [1, 2], "Veri olduğu gibi")
	assert_eq(int(kept[0]["v"]), 2)


func test_missing_unknown_and_late_blocks() -> void:
	var resets := []
	var reg := SaveBlocks.new()
	reg.register("clock", 1, func() -> Dictionary: return {"day_n": 5, "minute": 1.0}, func(_d: Dictionary) -> void: pass,
		{"reset": func() -> void: resets.append("clock")})
	assert_eq(reg.apply({"test_party": {"v": 1, "members": ["ku"]}}), "")
	assert_eq(resets, ["clock"], "Kayıtta olmayan blok varsayılanına döner")
	assert_eq(reg.carried().keys(), ["test_party"], "Sahibi olmayan blok taşınır")
	var out := reg.collect()
	assert_eq(out["test_party"]["members"], ["ku"], "Taşınan blok sonraki kayda yazılır")
	assert_eq(int(out["clock"]["v"]), 1, "Yazılan bloğa sürüm eklenir")
	var late := []
	reg.register("test_party", 1, func() -> Dictionary: return {"members": late.duplicate()}, func(d: Dictionary) -> void: late.append_array(d["members"]))
	assert_eq(late, ["ku"], "Sonradan kaydeden sistem taşınan bloğunu okur")
	assert_false(reg.carried().has("test_party"))
	late.append("berik")
	reg.unregister("test_party")
	assert_eq(reg.carried()["test_party"]["members"], ["ku", "berik"], "Bırakılan sistemin son hâli kalır")
	assert_true(reg.collect().has("test_party"))


func test_owner_check_failure_reads_nothing() -> void:
	var read := []
	var reg := SaveBlocks.new()
	reg.register("clock", 1, func() -> Dictionary: return {}, func(d: Dictionary) -> void: read.append(["clock", d]), {"order": 10})
	reg.register("test_party", 1, func() -> Dictionary: return {}, func(d: Dictionary) -> void: read.append(["test_party", d]),
		{"check": func(d: Dictionary) -> String: return "" if d.get("members") is Array else "members dizi değil"})
	var err := reg.apply({"clock": {"v": 1, "day_n": 3, "minute": 2.0}, "test_party": {"v": 1, "members": "ku"}})
	assert_true(err.contains("members dizi değil"), err)
	assert_eq(read.size(), 0, "Biri tutmazsa hiçbiri okunmaz (kısmi yükleme yok)")
	assert_eq(reg.apply({"clock": {"v": 1, "day_n": 3, "minute": 2.0}, "test_party": {"v": 1, "members": []}}), "")
	assert_eq(read.size(), 2)
	assert_eq(read[0][0], "clock", "Okunma sırası order'a göre")


# --- Bozuk blok, bozuk kayıt -------------------------------------------------------------------------------------

func test_corrupt_block_is_an_empty_slot() -> void:
	var good := _v2_record({"clock": {"v": 1, "day_n": 1171, "minute": 886.18, "holds": []}})
	var cases := {
		"blocks sözlük değil": "x",
		"blok sözlük değil": {"clock": [1, 2]},
		"sürümsüz blok": {"weather": {"seed": 1}},
		"sıfır sürüm": {"weather": {"v": 0}},
		"metin sürüm": {"weather": {"v": "1"}},
		"kesirli sürüm": {"weather": {"v": 1.5}},
		"büyük harfli ad": {"Weather": {"v": 1}},
		"saatin dakikası": {"clock": {"v": 1, "day_n": 1171, "minute": 5000.0}},
		"saatin günü": {"clock": {"v": 1, "day_n": "dün", "minute": 10.0}},
		"saatin bekleyişleri": {"clock": {"v": 1, "day_n": 1, "minute": 1.0, "holds": "yok"}},
	}
	var slot := 1
	for label: String in cases:
		var rec := good.duplicate(true)
		rec["blocks"] = cases[label]
		_write_raw(slot, JSON.stringify(rec))
		assert_eq(saves.slot_info(slot), {}, "Bozuk blok boş yuva: %s" % label)
		assert_false(saves.has_save(slot), label)
		slot += 1
		if slot > SaveSystem.SLOTS:
			break
	assert_eq(saves.latest_slot(), -1, "Bozuk kayıt en son kayıt sayılmaz")
	saves.write(SaveSystem.AUTO_SLOT, good)
	assert_eq(saves.latest_slot(), SaveSystem.AUTO_SLOT, "Sağlam kayıt okunur")
	var newer := good.duplicate(true)
	newer["version"] = SaveData.VERSION + 1
	assert_false(SaveData.is_record(newer), "Daha yeni sürümün kaydı okunmaz")
	assert_false(SaveData.is_record({"version": "2", "profile": {}}), "Metin sürüm")
	assert_true(SaveData.is_record({"version": 1, "profile": {}}), "Yalın v1 kaydı okunur")
	assert_true(SaveData.is_record({"version": 2.0, "profile": {}, "blocks": {}}), "JSON'un kayan sürümü")
	var j := Journey.new(saves)
	var bad := good.duplicate(true)
	bad["blocks"] = {"clock": {"v": 1, "day_n": 1, "minute": -3.0}}
	assert_false(j.apply_record(bad), "Bozuk bloklu kayıt yolculuğa yüklenmez")


func test_envelope_fields_fall_back_safely() -> void:
	var rec := _v2_record({})
	rec["mode"] = "uçuş"
	rec["act"] = -3
	rec["map"] = 42
	rec["seed"] = "tohum"
	var data := SaveData.parse(rec)
	assert_eq(data["mode"], "roam", "Bilinmeyen kip Serbest Gez sayılır")
	assert_eq(data["act"], 0)
	assert_eq(data["map"], "camp")
	assert_eq(data["seed"], 0)
	var j := Journey.new(saves)
	assert_true(j.apply_record(rec))
	assert_ne(j.journey_seed, 0, "Tohumu olmayan kayıt yeni tohum alır")


# --- v1 göçü ---------------------------------------------------------------------------------------------------

func test_players_v1_roam_save_migrates() -> void:
	var text := FileAccess.get_file_as_string(V1_FIXTURE)
	assert_false(text.is_empty(), "Fikstür okunmalı")
	_write_raw(SaveSystem.AUTO_SLOT, text)
	var info := saves.slot_info(SaveSystem.AUTO_SLOT)
	assert_false(info.is_empty(), "Oyuncunun v1 kaydı okunur")
	assert_eq(int(info["version"]), 2, "Okurken v2'ye göçer")
	assert_eq(info["mode"], "roam")
	assert_eq(int(info["act"]), 0)
	assert_eq(info["map"], "camp")
	assert_eq(info["blocks"], {}, "Bloklar varsayılan")
	assert_eq(int(info["migrated_from"]), 1)
	var seed_a := int(info["seed"])
	assert_ne(seed_a, 0)
	assert_eq(int(saves.slot_info(SaveSystem.AUTO_SLOT)["seed"]), seed_a, "Aynı kayıt aynı tohumu verir")
	assert_eq(seed_a, SaveData.legacy_seed(JSON.parse_string(text)), "Tohum kaydın tarihinden, zamanından ve sırasından")
	var moved := JSON.parse_string(text) as Dictionary
	moved["saved_at"] = "2026-11-08T05:22:15"
	assert_ne(SaveData.legacy_seed(moved), seed_a, "Başka kaydın tohumu başka")
	assert_eq(FileAccess.get_file_as_string(saves.slot_path(SaveSystem.AUTO_SLOT)), text, "Dosya değişmez (sonraki yazımda v2 olur)")
	var j := Journey.new(saves)
	assert_true(j.apply_record(info), "Yolculuk v1 kaydından kurulur")
	assert_eq(j.mode, "roam")
	assert_eq(j.map, "camp")
	assert_eq(j.blocks, {})
	assert_vec_almost(j.position, Vector3(6.71493244171143, -0.0216347873210907, -18.5266399383545), 1e-5)
	assert_almost(j.play_time, 50.1161330899471, 1e-6)
	for f in ["ahir_ziyaret", "ates_basi", "cocuk_gezinti", "gol_yamaci", "ilk_gezinti", "kaya_kumesi", "yosunlu_kaya"]:
		assert_true(j.has_flag(f), "İşaret kalır: %s" % f)
	assert_eq(SaveData.slot_title(info, SaveSystem.AUTO_SLOT), "Otomatik kayıt · Çayır", "Kartın başlığı aynı")
	assert_true(j.save_auto(&"to_menu"))
	var again := saves.slot_info(SaveSystem.AUTO_SLOT)
	assert_false(again.has("migrated_from"), "Yeniden yazılan kayıt v2'nin kendisidir")
	assert_eq(int(again["seed"]), seed_a, "Tohum yazımda korunur")
	var session := Session.new()
	assert_eq(session.setup(j), "", "Oturum v1 kaydının yolculuğuna kurulur")
	assert_eq(session.clock.day_n, GameClock.ROAM_DAY, "Bloksuz Serbest Gez 11 Nisan MÖ 209'da")
	assert_almost(session.clock.minute, Daylight.MENU_MINUTE, 1e-6, "14:46,2")
	session.free()


func test_person_ids_in_unlocks_migrate_once() -> void:
	var v1 := {"version": 1, "game": "tanhu3", "profile": {}, "saved_at": "2026-11-01T10:00:00", "save_no": 3, "flags": {
		"ana": true, "kisiler/ozan": true, "kisiler/ak_at": 1, "met": ["cocuk", "ana", "x"], "mete": true,
		"cocuk_gezinti": true, "ozan_dinledi": true, "ates_basi": true, "gok_yer/tengri": true,
	}}
	var flags: Dictionary = SaveData.parse(v1)["flags"]
	assert_eq(flags, {
		"mother": true, "kisiler/bard": true, "kisiler/akbulut": 1, "met": ["child", "mother", "x"], "older_brother": true,
		"cocuk_gezinti": true, "ozan_dinledi": true, "ates_basi": true, "gok_yer/tengri": true,
	}, "Eski kimlikler çevrilir, yer ve olay işaretleri kalır")
	var both := SaveData.migrate_person_ids({"ana": false, "mother": true, "baba": true, "father": false})
	assert_eq(both["mother"], true, "Yeni kimlik konmuşsa eskisi ezmez")
	assert_eq(both["father"], true, "Konmamış yeni kimliği eskisi doldurur")
	var v2 := _v2_record({})
	v2["flags"] = {"ana": true}
	assert_eq(SaveData.parse(v2)["flags"], {"ana": true}, "v2 kaydı yeniden göçmez (bir kez)")
	_write_raw(1, JSON.stringify(v1))
	var j := Journey.new(saves)
	assert_true(j.apply_record(saves.slot_info(1)))
	assert_true(j.has_flag("mother") and not j.flags.has("ana"), "Yüklenen yolculuk yeni kimliği taşır")


func test_destan_unlocks_survive_migration() -> void:
	var v1: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(V1_FIXTURE))
	var before := _unlocked(v1["flags"])
	var after := _unlocked(SaveData.parse(v1)["flags"])
	assert_eq(after, before, "Oyuncunun kaydının açtığı kayıtlar göçten sonra aynı")
	for id in ["kisiler/akbulut", "kisiler/doru", "kisiler/mother", "kisiler/older_brother", "taslar/gol", "destan/gece_biterken"]:
		assert_true(after.has(id), "Açık kalmalı: %s" % id)


# --- Oto kayıt -------------------------------------------------------------------------------------------------

func test_autosave_reason_and_thumbnail() -> void:
	var j := Journey.new(saves)
	var frame := Image.create(64, 36, false, Image.FORMAT_RGB8)
	frame.fill(Color.ORANGE)
	j.pending_thumb = frame
	assert_true(j.save_auto(&"dawn"))
	assert_eq(str(saves.slot_info(SaveSystem.AUTO_SLOT)["reason"]), "dawn", "Oto kaydın nedeni yazılır")
	assert_true(FileAccess.file_exists(saves.thumb_path(SaveSystem.AUTO_SLOT)))
	j.pending_thumb = null
	assert_true(j.save_auto(&"wait"))
	assert_true(FileAccess.file_exists(saves.thumb_path(SaveSystem.AUTO_SLOT)), "Kare yoksa oto kayıt son küçük resmi korur")
	assert_true(j.save_manual(1))
	assert_false(saves.slot_info(1).has("reason"), "Elle kayıtta neden yok")
	assert_false(FileAccess.file_exists(saves.thumb_path(1)), "Elle kayıt başka anın resmini taşımaz")
	j.reset()
	assert_eq(j.mode, "story", "Yeni yolculuk hikâye kipinde")
	assert_eq(j.act, 0)
	assert_true(j.save_auto(&"act"))
	assert_false(FileAccess.file_exists(saves.thumb_path(SaveSystem.AUTO_SLOT)), "Yeni yolculuğun ilk oto kaydı eski resmi taşımaz")
	assert_eq(saves.slot_info(SaveSystem.AUTO_SLOT)["map"], "camp", "Dünyası yazılmamış yolculuk kampa düşer")


func test_new_journeys_get_fresh_seeds() -> void:
	var a := Journey.new(saves)
	var b := Journey.new(saves)
	assert_ne(a.journey_seed, 0)
	var first := a.journey_seed
	a.blocks = {"clock": {"v": 1, "day_n": 1, "minute": 0.0}}
	a.reset()
	assert_eq(a.blocks, {}, "Yeni yolculukta kaydın blokları düşer")
	assert_ne(a.journey_seed, 0)
	assert_true(a.journey_seed != first or b.journey_seed != first, "Tohum rastgele seçilir")
	assert_eq(SaveData.hash32("tanhu"), SaveData.hash32("tanhu"), "Özet kararlı")
	assert_eq(SaveData.hash32(""), 2166136261, "FNV-1a başlangıcı")
	assert_eq(SaveData.hash32("a"), 0xE40C292C, "FNV-1a 32 («a»)")


# --- Yardımcılar ------------------------------------------------------------------------------------------------

func _v2_record(blocks: Dictionary) -> Dictionary:
	var rec := SaveData.build(CharacterProfile.new(), Vector3(1, 0, 2), 0.5, {"ates_basi": true}, 60.0, 1, "ocak", "2026-11-08T09:00:00", 1000.0)
	rec["blocks"] = blocks
	return rec


func _write_raw(slot: int, text: String) -> void:
	var f := FileAccess.open(saves.slot_path(slot), FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _unlocked(flags: Dictionary) -> Dictionary:
	var out := {}
	for chapter in DestanKitabi.CHAPTERS:
		for e in DestanKitabi.entries(chapter, flags):
			out["%s/%s" % [chapter, e["id"]]] = true
	return out
