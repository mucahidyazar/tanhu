extends TestCase
## Oluşturucu «Yola Hazırlan» (K36; story.md §6; Yol Haritası creator-prepare): başlık ve alt yazı (Mete 20 yaşında), görünüşün
## ardından yolun satırları (köken, zorluk, pelerin boyası), açıklama satırları, kumaş örnekleri, Meshy modelinde gizlenen yüz
## satırları ve parşömenin boyu; köken, zorluk ve boyanın profile, kayda (v1'in profil bloğu) ve yolculuğa girip geri gelmesi.

const CREATOR_SCENE := preload("res://scenes/ui/character_creator.tscn")
const TempDir := preload("res://tests/support/temp_dir.gd")

var creator: CharacterCreator
var dir := ""


func before_each() -> void:
	InputSetup.ensure_actions()
	CreatorTurntable.preload_enabled = false
	creator = CREATOR_SCENE.instantiate() as CharacterCreator
	add_child(creator)
	creator.open(CharacterProfile.new())


func after_each() -> void:
	if is_instance_valid(creator):
		creator.queue_free()
	creator = null
	CreatorTurntable.preload_enabled = true
	if dir != "":
		TempDir.wipe(dir)
		dir = ""


# --- Ekran ----------------------------------------------------------------------------------------

func test_title_and_subtitle_name_the_moment() -> void:
	assert_eq((creator.get_node(^"%Title") as Label).text, "YOLA HAZIRLAN")
	var subtitle := (creator.get_node(^"%Subtitle") as Label).text
	assert_true(subtitle.contains("Mete"), "Alt yazı Mete'yi anar")
	assert_true(subtitle.contains("20 yaşında"), "Mete 20 yaşındadır")
	assert_true(subtitle.contains("MÖ 213"), "Panoların son yılı: MÖ 213")


func test_journey_rows_follow_the_appearance() -> void:
	var rows := creator.get_rows()
	var eye := CharacterOptions.FIELDS.find(&"eye_color")
	assert_eq(CharacterOptions.FIELDS.slice(eye + 1), [&"origin", &"difficulty", &"cape_dye"], "Görünüşün ardından köken, zorluk, boya")
	assert_eq(creator.get_row(&"origin").get_label_text(), "KÖKEN")
	assert_eq(creator.get_row(&"difficulty").get_label_text(), "ZORLUK")
	assert_eq(creator.get_row(&"cape_dye").get_label_text(), "BOYA")
	assert_true(CreatorRow.starts_section(&"origin"), "Yolun ilk satırının üstünde ayraç var")
	assert_false(CreatorRow.starts_section(&"difficulty"))
	assert_almost(creator.get_row(&"origin").custom_minimum_size.y,
		CreatorRow.LINE_HEIGHT + CreatorRow.DETAIL_HEIGHT + CreatorRow.DETAIL_LINE_HEIGHT + CreatorRow.SECTION_GAP, 0.01,
		"Ayraç ve iki satırlık açıklama (söz, etki) satırın boyuna girer")
	assert_almost(creator.get_row(&"difficulty").custom_minimum_size.y, CreatorRow.LINE_HEIGHT + CreatorRow.DETAIL_HEIGHT, 0.01,
		"Zorluğun açıklaması tek satır")
	for row in rows:
		assert_true(row.adjustable or row.field in CharacterOptions.PAINTED_FIELDS, "Mete'de yalnız yüze çizililer kilitli: %s" % row.field)


func test_origin_row_shows_line_and_effect() -> void:
	# K104: kökenler veliahdın nasıl yetiştiğini anlatır; söz üstte, etkisi altta (iki satır, tam boyda).
	var row := creator.get_row(&"origin")
	assert_eq(row.get_value_text(), "Zırhlı Atlılar Arasında", "Varsayılan köken ilk köken")
	assert_eq(row.get_detail_text(), "Tanhu'nun zırhlı atlılarıyla yay gererek büyüdün.\nBilek +1")
	creator.change(&"origin", -1)
	assert_eq(creator.get_profile().origin_id(), "origin_herds", "Geri ok sondan başa sarar")
	assert_eq(row.get_value_text(), "Yılkı Beyi")
	assert_eq(row.get_detail_text(), "Tanhu'nun yılkısını yaylaya sürerek büyüdün; atlar seni tanır.\nAyak +1, Bağ +10")
	creator.change(&"origin", -1)
	assert_eq(row.get_value_text(), "Otağda Yetişen")
	assert_eq(row.get_detail_text(), "Babanın otağında elçileri ve beyleri dinleyerek büyüdün.\nSöz +1")
	# Her kökenin sözü açıklamanın genişliğine tam boyda sığar (tek satırda en uzunu 12 px'e küçülüyordu).
	for i in CharacterOptions.count(&"origin"):
		creator.get_profile().set_value(&"origin", i)
		row.refresh(creator.get_profile())
		assert_eq(row.get_detail_label().get_theme_font_size(&"font_size"), CreatorRow.DETAIL_FONT_SIZE,
			"Tam boy: %s" % row.get_value_text())


func test_difficulty_has_three_levels_and_the_edge_arrow_stays_on() -> void:
	var row := creator.get_row(&"difficulty")
	assert_eq(creator.get_profile().difficulty_id(), "normal", "Varsayılan zorluk Normal")
	assert_eq(row.get_value_text(), "Normal")
	assert_true(row.get_detail_text().begins_with("Bozkır adildir."))
	var names := []
	for i in CharacterOptions.count(&"difficulty"):
		names.append(CharacterOptions.value_name(&"difficulty", i))
		assert_true(CharacterOptions.value_detail(&"difficulty", i).contains(CharacterOptions.EDGE_ARROW_NOTE),
			"%s: tehdit oku her zorlukta açık" % names[-1])
	assert_eq(names, ["Hikâye", "Normal", "Zor"])
	creator.change(&"difficulty", 1)
	assert_eq(row.get_value_text(), "Zor")
	assert_true(row.get_detail_text().begins_with("Bozkır seni tanımaz."))
	creator.change(&"difficulty", 1)
	assert_eq(row.get_value_text(), "Hikâye", "Zor'dan sonra başa sarar")
	assert_true(row.get_detail_text().begins_with("Destanı dinlemek isteyenler için."))


func test_dye_row_shows_fabric_samples_and_the_dye_name() -> void:
	var row := creator.get_row(&"cape_dye")
	var swatches := row.get_swatches()
	assert_not_null(swatches)
	assert_true(swatches.fabric, "Boya kumaş örnekleriyle gösterilir")
	assert_eq(swatches.colors, CharacterOptions.colors(&"cape_dye"))
	assert_eq(row.get_value_text(), "Göl Mavisi")
	creator.select_color(&"cape_dye", 4)
	assert_eq(creator.get_profile().cape_dye_id(), "violet")
	assert_eq(row.get_value_text(), "Menekşe")
	assert_eq(swatches.selected, 4)
	for field in [&"skin", &"hair_color", &"eye_color"]:
		assert_false(creator.get_row(field).get_swatches().fabric, "Ten, saç ve göz boncuktur: %s" % field)


func test_painted_rows_are_hidden_on_the_meshy_model() -> void:
	for field in CharacterOptions.PAINTED_FIELDS:
		var row := creator.get_row(field)
		assert_false(row.adjustable)
		assert_false(row.visible, "Yüze çizili özelliğin satırı Meshy modelinde gizli: %s" % field)
	creator.get_avatar().use_meshy_models = false
	creator.open(CharacterProfile.new())
	for field in CharacterOptions.PAINTED_FIELDS:
		assert_true(creator.get_row(field).visible, "Chibi yedeğinde ayarlanabilir, görünür: %s" % field)


func test_panel_grows_to_hold_rows_and_buttons() -> void:
	var panel := creator.get_node(^"%Panel") as Control
	var rows_box := creator.get_node(^"%Rows") as Control
	var accept := creator.get_node(^"%AcceptButton") as Control
	var visible_height := 0.0
	for row in creator.get_rows():
		if row.visible:
			visible_height += row.custom_minimum_size.y
	assert_almost(rows_box.offset_bottom - rows_box.offset_top, visible_height, 0.5, "Satırların alanı görünen satırlar kadar")
	assert_true(accept.offset_top >= rows_box.offset_bottom, "Düğmeler satırların altında")
	assert_almost(panel.offset_bottom - panel.offset_top, accept.offset_bottom + CharacterCreator.PANEL_BOTTOM_PAD, 0.5)
	var meshy_height := panel.offset_bottom - panel.offset_top
	var bottom := panel.offset_bottom
	creator.get_avatar().use_meshy_models = false
	creator.open(CharacterProfile.new())
	assert_true(panel.offset_bottom - panel.offset_top > meshy_height, "Chibi'de yüz satırları görünür, parşömen uzar")
	assert_eq(panel.offset_bottom, bottom, "Parşömenin alt kenarı yerinde kalır")
	assert_eq(panel.pivot_offset, Vector2(-panel.offset_left, -panel.offset_top), "Ölçek çapası yeni boya göre")


func test_dye_is_locked_on_a_model_without_cape() -> void:
	creator.change(&"body_type", 1)
	var row := creator.get_row(&"cape_dye")
	assert_eq(creator.get_avatar().model_id, "hero_f")
	assert_false(row.adjustable, "Pelerinsiz kılıkta boya ayarlanamaz")
	assert_true(row.visible, "Boya satırı görünür kalır: seçim yolculuğa yazılır")
	assert_eq(row.get_value_text(), CharacterOptions.NO_CAPE_TEXT)
	var before := creator.get_profile().cape_dye
	creator.change(&"cape_dye", 1)
	assert_eq(creator.get_profile().cape_dye, before)
	creator.change(&"body_type", -1)
	assert_true(creator.get_row(&"cape_dye").adjustable, "Mete'de yeniden açılır")


func test_accept_carries_origin_difficulty_and_dye() -> void:
	creator.change(&"origin", 1)
	creator.change(&"difficulty", 1)
	creator.select_color(&"cape_dye", 4)
	var watcher := watch_signal(creator.accepted)
	creator.accept()
	var sent := watcher.last_args[0] as CharacterProfile
	assert_eq(sent.origin_id(), "origin_tent")
	assert_eq(sent.difficulty_id(), "hard")
	assert_eq(sent.cape_dye_id(), "violet")
	var d := sent.to_dict()
	assert_eq(d["origin"], "origin_tent", "Kayıtta kimlik yazılır")
	assert_eq(d["difficulty"], "hard")
	assert_eq(d["cape_dye"], "violet")


func test_undo_restores_journey_fields() -> void:
	creator.change(&"difficulty", -1)
	creator.change(&"cape_dye", 2)
	assert_true(creator.undo())
	assert_eq(creator.get_profile().cape_dye, 0)
	assert_eq(creator.get_focus_index(), CharacterOptions.FIELDS.find(&"cape_dye"), "Geri alınan satır odaklanır")
	assert_true(creator.undo())
	assert_eq(creator.get_profile().difficulty_id(), "normal")


# --- Profil, kayıt ve yolculuk ----------------------------------------------------------------------

func _journey_profile() -> CharacterProfile:
	var p := CharacterProfile.new()
	p.set_value(&"hair_color", 3)
	p.set_value(&"origin", CharacterOptions.index_of_id(&"origin", "origin_herds"))
	p.set_value(&"difficulty", CharacterOptions.index_of_id(&"difficulty", "hard"))
	p.set_value(&"cape_dye", CharacterOptions.index_of_id(&"cape_dye", "deep_indigo"))
	return p


func test_profile_fields_round_trip_through_the_save() -> void:
	var p := _journey_profile()
	var record := SaveData.build(p, Vector3(1.0, 0.0, 2.0), 0.5, {}, 12.0, 1, "ocak")
	var block: Dictionary = record["profile"]
	assert_eq(block["origin"], "origin_herds", "Köken kayıtta (v1'in profil bloğu)")
	assert_eq(block["difficulty"], "hard", "Zorluk kayıtta")
	assert_eq(block["cape_dye"], "deep_indigo", "Boya kayıtta")
	# Diske yazılıp okunmuş gibi: JSON'dan geçer.
	var parsed: Dictionary = JSON.parse_string(JSON.stringify(record))
	var back := SaveData.parse(parsed)["profile"] as CharacterProfile
	assert_true(back.equals(p), "Profil kayıttan aynen geri gelir")
	assert_eq(back.difficulty_id(), "hard")
	assert_eq(back.cape_color().to_html(false), "2b3f66", "Geri gelen boya Koyu Çivit")


func test_profile_fields_ride_along_with_the_journey() -> void:
	dir = TempDir.fresh("yola_hazirlan")
	var saves := SaveSystem.new(dir)
	var journey := Journey.new(saves, _journey_profile())
	assert_true(journey.save_manual(2))
	var other := Journey.new(saves)
	assert_eq(other.profile.difficulty_id(), "normal", "Yeni yolculuk varsayılanla başlar")
	assert_true(other.apply_record(saves.slot_info(2)))
	assert_eq(other.profile.origin_id(), "origin_herds")
	assert_eq(other.profile.difficulty_id(), "hard")
	assert_eq(other.profile.cape_dye_id(), "deep_indigo")
	journey.reset(CharacterProfile.new())
	assert_eq(journey.profile.difficulty_id(), "normal", "Yeni oyunun profili yolculuğa kopyalanır")


func test_old_records_and_bad_values_fall_back_to_defaults() -> void:
	var old := CharacterProfile.from_dict({"body_type": 0, "skin": 2, "hair_color": 1})
	assert_eq(old.origin_id(), "origin_riders", "Eski kayıtta köken yok: ilk köken")
	assert_eq(old.difficulty_id(), "normal", "Eski kayıtta zorluk yok: Normal")
	assert_eq(old.cape_dye_id(), "lake_blue", "Eski kayıtta boya yok: Göl Mavisi")
	assert_eq(old.skin, 2)
	var bad := CharacterProfile.from_dict({"origin": "origin_nope", "difficulty": 7, "cape_dye": ["x"]})
	assert_eq(bad.origin_id(), "origin_riders")
	assert_eq(bad.difficulty_id(), "normal", "Taşan sayı varsayılana düşer")
	assert_eq(bad.cape_dye_id(), "lake_blue")
	var by_index := CharacterProfile.from_dict({"difficulty": 0, "cape_dye": 4.0})
	assert_eq(by_index.difficulty_id(), "story", "Sayıyla yazılmış eski biçim de okunur")
	assert_eq(by_index.cape_dye_id(), "violet")


## K104: eski kayıttaki eski köken kimliği yenisine göçer (profil bloğu ve yolculuk); kayıt yeniden yazılınca yeni kimlik yazılır.
func test_old_origin_ids_migrate_in_the_save() -> void:
	var pairs := {"origin_load": "origin_riders", "origin_listener": "origin_tent", "origin_stable": "origin_herds"}
	for old: String in pairs:
		var record := SaveData.build(CharacterProfile.new(), Vector3.ZERO, 0.0, {}, 12.0, 1, "ocak")
		(record["profile"] as Dictionary)["origin"] = old
		var back := SaveData.parse(JSON.parse_string(JSON.stringify(record)))["profile"] as CharacterProfile
		assert_eq(back.origin_id(), pairs[old], "%s → %s" % [old, pairs[old]])
		assert_eq(back.to_dict()["origin"], pairs[old], "Yeniden yazılan kayıtta yeni kimlik")
	assert_eq(CharacterOptions.index_of_id(&"origin", "origin_stable"), CharacterOptions.index_of_id(&"origin", "origin_herds"))
	assert_eq(CharacterOptions.index_of_id(&"origin", "origin_nope"), -1, "Tanınmayan kimlik yine yok")


func test_difficulty_and_origin_data_follow_the_design() -> void:
	var expected := {
		"story": {"woundLimit": 5, "dmgTaken": 0.7, "perception": 0.7, "ledgerLoss": -6},
		"normal": {"woundLimit": 3, "dmgTaken": 1.0, "perception": 1.0, "ledgerLoss": -8},
		"hard": {"woundLimit": 2, "dmgTaken": 1.25, "perception": 1.3, "ledgerLoss": -10},
	}
	for id: String in expected:
		var level := CharacterOptions.difficulty_level(id)
		assert_false(level.is_empty(), "Zorluk düzeyi var: %s" % id)
		assert_true(bool(level.get("edgeArrow", false)), "%s: kenar oku açık (K39)" % id)
		for key: String in expected[id]:
			assert_almost(float(level.get(key, NAN)), float(expected[id][key]), 0.0001, "%s.%s (progression.md §12)" % [id, key])
	# progression.md §2.2 (K104): kimlik, ad, söz ve etki; sıra oluşturucunun sırasıdır.
	var origins := [
		["origin_riders", "Zırhlı Atlılar Arasında", "Among the Armored Riders", {"grip": 1.0}, 0],
		["origin_tent", "Otağda Yetişen", "Raised in the Royal Tent", {"word": 1.0}, 0],
		["origin_herds", "Yılkı Beyi", "Lord of the Herds", {"foot": 1.0}, 10],
	]
	assert_eq(CharacterOptions.count(&"origin"), origins.size(), "Üç köken")
	for i in origins.size():
		var o: Dictionary = CharacterOptions.origins()[i]
		var want: Array = origins[i]
		assert_eq([o["id"], o["name"], o["name_en"]], want.slice(0, 3), "Köken %d (progression.md §2.2)" % i)
		assert_eq(o["stats"], want[3], "Kökenin etkisi: %s" % o["id"])
		assert_eq(int(o.get("bond", 0)), want[4], "Kökenin At Bağı payı: %s" % o["id"])
		assert_false(str(o["line"]).contains("kış"), "Söz rehineliği anlatmaz (oluşturucu rehinelikten önce): %s" % o["id"])
