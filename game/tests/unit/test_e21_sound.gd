extends TestCase
## E21'in ses bağı (E21Sound; docs/design/d3/e21-atmosphere.md «Yollar ve kurallar»): kimlik önekinden klasör (amb_ döngü, sfx_ tek seferlik,
## mus_ müzik), çeşitler (_a, _b, _c), dosya yoksa yer tutucu, yatağın döngüsü ve konumlu ölçüsü.

const PLACEHOLDER := "res://audio/ambience/campfire_loop.wav"


func test_paths_follow_the_prefix() -> void:
	for p in E21Sound.paths("amb_snow_morning"):
		assert_true(p.begins_with(E21Sound.LOOP_DIR), p)
	for p in E21Sound.paths("sfx_lamb_bleat"):
		assert_true(p.begins_with(E21Sound.SFX_DIR), p)
	for p in E21Sound.paths("mus_shilde"):
		assert_true(p.begins_with(E21Sound.MUSIC_DIR) and p.ends_with(".mp3"), p)


func test_variants_and_plain_file_are_both_found() -> void:
	# Çeşitli kimlik (_a, _b) ve tek dosyalı kimlik aynı yoldan bulunur; hiçbiri yoksa liste boştur.
	var bleat := E21Sound.paths("sfx_lamb_bleat")
	if not bleat.is_empty():
		assert_true(bleat.size() >= 1)
		for p in bleat:
			assert_true(p.get_file().begins_with("sfx_lamb_bleat"), p)
	assert_eq(E21Sound.paths("sfx_e21_yok_boyle_bir_ses").size(), 0)
	assert_false(E21Sound.has_file("amb_e21_yok"))


func test_missing_file_falls_back_to_the_placeholder() -> void:
	var s := E21Sound.stream("amb_e21_yok", PLACEHOLDER, true)
	assert_not_null(s, "yer tutucu çalar")
	assert_null(E21Sound.stream("amb_e21_yok", "", false), "yer tutucusuz ses yok")


func test_variant_does_not_repeat_back_to_back() -> void:
	var list := E21Sound.paths("sfx_axe_chop")
	if list.size() < 2:
		return
	var last := ""
	for i in 12:
		E21Sound.stream("sfx_axe_chop")
		var now := str(E21Sound._last.get("sfx_axe_chop", ""))
		assert_ne(now, last, "aynı çeşit art arda çalmaz")
		last = now


func test_bed_is_a_quiet_positional_loop_until_faded_in() -> void:
	var bed := E21Sound.bed("amb_e21_yok", PLACEHOLDER, 30.0, -3.0)
	assert_not_null(bed)
	assert_almost(bed.max_distance, 30.0, 0.001, "yarıçapın ötesinde susar")
	assert_almost(bed.volume_db, E21Sound.SILENT_DB, 0.001, "sessiz başlar")
	assert_true(bool(bed.get_meta(&"placeholder")), "yer tutucu olduğu bilinir")
	add_child(bed)
	var tw := E21Sound.fade_in(bed, 0.05)
	assert_not_null(tw)
	assert_true(bed.playing)
	await tw.finished
	assert_almost(bed.volume_db, -3.0, 0.2, "kendi düzeyine karışır")
	bed.queue_free()


func test_one_shot_is_freed_after_playing() -> void:
	var holder := Node3D.new()
	add_child(holder)
	var p := E21Sound.one_shot(holder, "sfx_e21_yok", Vector3(1, 0, 2), {"placeholder": "res://audio/sfx/gen/lamb.wav", "max_m": 30.0})
	assert_not_null(p)
	assert_almost(p.max_distance, 30.0, 0.001)
	assert_true(p.playing)
	holder.queue_free()
