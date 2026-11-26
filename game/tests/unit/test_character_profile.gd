extends TestCase
## CharacterProfile ve CharacterOptions testleri.

var test_path := ""


func before_each() -> void:
	test_path = writable_path("test_character_profile.json")


func after_each() -> void:
	if FileAccess.file_exists(test_path):
		DirAccess.remove_absolute(test_path)


## user:// yazılabilir değilse (ör. kum havuzu) sistemin geçici klasörünü kullanır.
static func writable_path(file_name: String) -> String:
	var probe := FileAccess.open("user://.write_probe", FileAccess.WRITE)
	if probe:
		probe.close()
		DirAccess.remove_absolute("user://.write_probe")
		return "user://" + file_name
	var tmp := OS.get_environment("TMPDIR")
	return (tmp if not tmp.is_empty() else "/tmp").path_join(file_name)


func test_every_field_has_a_label_and_options() -> void:
	for field in CharacterOptions.FIELDS:
		assert_true(CharacterOptions.FIELD_LABELS.has(field), "Etiket eksik: %s" % field)
		assert_true(CharacterOptions.count(field, 0) > 0, "Seçenek yok: %s" % field)
		assert_ne(CharacterOptions.value_name(field, 0, 0), "", "Ad boş: %s" % field)


func test_color_fields_start_with_natural() -> void:
	for field in CharacterOptions.COLOR_FIELDS:
		if field in CharacterOptions.FABRIC_FIELDS:
			# Pelerin boyasının «Doğal»ı yoktur (K58): ilk boya Göl Mavisi'dir (test_cape_dye.gd).
			assert_eq(CharacterOptions.color_for(field, 0).a, 1.0, "%s için 0. seçenek bir boya olmalı" % field)
			continue
		assert_eq(CharacterOptions.color_for(field, 0).a, 0.0, "%s için 0. seçenek 'Doğal' olmalı" % field)
		assert_eq(CharacterOptions.value_name(field, 0), CharacterOptions.NATURAL)
		assert_true(CharacterOptions.color_for(field, 1).a > 0.0)


func test_cycle_wraps_around() -> void:
	var p := CharacterProfile.new()
	p.cycle(&"skin", -1)
	assert_eq(p.skin, CharacterOptions.count(&"skin") - 1, "Geri ok ilk seçenekten sona sarmalı")
	p.cycle(&"skin", 1)
	assert_eq(p.skin, 0)


func test_body_type_changes_model_and_keeps_hairstyle_valid() -> void:
	var p := CharacterProfile.new()
	# Tip 1 = Mete, Tip 2 = kadın kahraman (bkz. CharacterOptions.HAIRSTYLES).
	assert_eq(p.model_id(), "mete")
	p.set_value(&"body_type", 1)
	assert_true(p.hairstyle < CharacterOptions.count(&"hairstyle", 1))
	assert_eq(p.model_id(), "hero_f")
	# Tek seçenekli saç modelinde ileri/geri gezinme geçerli dizinde kalır.
	p.cycle(&"hairstyle", 1)
	assert_eq(p.hairstyle, 0)
	assert_eq(p.model_id(), "hero_f")


func test_dict_roundtrip_and_copy() -> void:
	var p := CharacterProfile.new()
	p.set_value(&"body_type", 1)
	p.set_value(&"hair_color", 4)
	p.set_value(&"eye_color", 3)
	var q := CharacterProfile.from_dict(p.to_dict())
	assert_true(p.equals(q))
	var c := p.copy()
	c.cycle(&"beard", 1)
	assert_false(p.equals(c), "Kopya bağımsız olmalı")


## K104: K104'ten önceki kayıtların köken kimlikleri (origin_load, origin_listener, origin_stable) yenisine göçer; profil yeniden
## yazılınca yeni kimlik yazılır. Dosyadan okunan eski profil de göçer.
func test_old_origin_ids_migrate() -> void:
	var pairs := {"origin_load": "origin_riders", "origin_listener": "origin_tent", "origin_stable": "origin_herds"}
	for old: String in pairs:
		var p := CharacterProfile.from_dict({"body_type": 0, "origin": old, "difficulty": "hard"})
		assert_eq(p.origin_id(), pairs[old], "%s → %s" % [old, pairs[old]])
		assert_eq(p.to_dict()["origin"], pairs[old])
		assert_eq(p.difficulty_id(), "hard", "Göç öteki alanlara dokunmaz")
	var f := FileAccess.open(test_path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"body_type": 0, "skin": 3, "origin": "origin_stable"}))
	f.close()
	var loaded := CharacterProfile.load_or_default(test_path)
	assert_eq(loaded.origin_id(), "origin_herds", "Diskteki eski profil de göçer")
	assert_eq(loaded.skin, 3)
	assert_eq(CharacterProfile.from_dict({"origin": "origin_herds"}).origin_id(), "origin_herds", "Yeni kimlik olduğu gibi")


func test_save_and_load() -> void:
	var p := CharacterProfile.new()
	p.set_value(&"moustache", 2)
	assert_eq(p.save(test_path), OK)
	assert_true(CharacterProfile.has_saved(test_path))
	assert_true(CharacterProfile.load_or_default(test_path).equals(p))


func test_load_missing_returns_default() -> void:
	assert_true(CharacterProfile.load_or_default("user://yok_boyle_dosya.json").equals(CharacterProfile.new()))


func test_clip_mapping_by_name_and_order() -> void:
	var by_name := CharacterAvatar.map_clips(PackedStringArray(["Armature|Idle", "Casual_Walk_inplace", "run_fast_3_inplace"]), [])
	assert_eq(by_name.get(&"idle"), "Armature|Idle")
	assert_eq(by_name.get(&"walk"), "Casual_Walk_inplace")
	assert_eq(by_name.get(&"run"), "run_fast_3_inplace")
	var by_order := CharacterAvatar.map_clips(PackedStringArray(["clip0", "clip1"]), ["idle", "sit"])
	assert_eq(by_order.get(&"idle"), "clip0")
	assert_eq(by_order.get(&"sit"), "clip1")


func test_avatar_fallback_builds_without_meshy_model() -> void:
	var avatar := CharacterAvatar.new()
	avatar.use_meshy_models = false
	add_child(avatar)
	await wait_frames(2)
	assert_false(avatar.has_meshy_model())
	avatar.set_locomotion(2.0)
	var p := CharacterProfile.new()
	p.set_value(&"body_type", 1)
	avatar.apply_profile(p)
	await wait_frames(1)
	assert_eq(avatar.model_id, p.model_id())
	avatar.queue_free()
