extends TestCase
## Koro gök içindir (K59, #53; audio.md §2 «Koro», §3): koro yalnız `tengri` ve `dawn` kliplerinde çalar; Önsöz'de
## tek çalışı mit sinemasının gök panosundadır (Yol Haritası myth-audio; story.md §3 satır 4).
##   - Bütün bankaların verisi (data/audio/banks/*.json): choir_ katmanı izin listesi dışında yoksa geçer.
##   - Kurulan AudioStreamInteractive'lerin klipleri gezilir: choir_ dosyası (düz katman ya da Playlist'in cümlesi)
##     izin listesi dışındaki klipte bulunursa düşer.
##   - İzin dışı koro katmanı bankada kurulmaz ve hata yazılır (problems() da yazar).
##   - Önsöz'ün çizelgesinde koroya giden müzik işareti tektir ve gök panosundadır.
##   - AudioManager mit sineması boyunca koroyu bir kez sayar (perde 0).

const AudioManagerScript := preload("res://scripts/audio/audio_manager.gd")
const ALLOWED: Array[StringName] = [&"tengri", &"dawn"]
const PROLOGUE := "res://data/cine/prologue.json"
const CINE_DIR := "res://data/cine"

var audio: Node


func after_each() -> void:
	Engine.time_scale = 1.0
	if is_instance_valid(audio):
		audio.stop_all()
		audio.reset_buses()
		audio.free()
	audio = null
	MusicBank.clear_cache()


func test_allow_list_is_the_sky() -> void:
	assert_eq(MusicBank.CHOIR_CLIPS, ALLOWED, "Koronun izin listesi: tengri ve dawn (K59)")
	assert_eq(MusicBank.CHOIR_PREFIX, "choir_")


func test_bank_data_puts_choir_only_in_the_sky() -> void:
	var found := 0
	for id in MusicBank.bank_ids():
		var def := MusicBank.load_def(id)
		for clip_def: Variant in MusicBank.clips(def):
			if not clip_def is Dictionary:
				continue
			var clip_name := StringName(str(clip_def.get("name", "")))
			for layer: Variant in MusicBank.layers(clip_def):
				if layer is Dictionary and MusicBank.is_choir(layer):
					found += 1
					assert_true(ALLOWED.has(clip_name), "%s/%s: koro yalnız tengri ve dawn kliplerinde (K59)" % [id, clip_name])
	assert_true(found >= 1, "Önsöz'ün korosu bir bankada (prologue_myth/tengri)")


func test_built_streams_carry_choir_only_in_the_sky() -> void:
	var seen := 0
	for id in MusicBank.bank_ids():
		var stream := MusicBank.build(MusicBank.load_def(id))
		assert_not_null(stream, "%s bankası kurulur" % id)
		if stream == null:
			continue
		for i in stream.clip_count:
			var clip_name := stream.get_clip_name(i)
			var sync := stream.get_clip_stream(i) as AudioStreamSynchronized
			if sync == null:
				continue
			for k in sync.stream_count:
				for file in _files_of(sync.get_sync_stream(k)):
					if file.get_file().begins_with(MusicBank.CHOIR_PREFIX):
						seen += 1
						assert_true(ALLOWED.has(clip_name), "%s/%s: kurulan klipte koro (%s) izin dışı" % [id, clip_name, file])
	assert_true(seen >= 1, "Kurulan bankalarda koro katmanı bulundu (gök panosu)")


func test_bank_refuses_a_choir_outside_the_sky() -> void:
	var def := {"id": "deneme", "version": 1, "clips": [
		{"name": "myth", "tempo": 48, "layers": [
			{"name": "drone", "file": "tengri_drone"},
			{"name": "choir_tengri", "file": "choir_tengri"}]},
		{"name": "tengri", "tempo": 48, "layers": [
			{"name": "drone", "file": "tengri_drone"},
			{"name": "choir_tengri", "file": "choir_tengri"}]}]}
	var problems := "; ".join(MusicBank.problems(def))
	assert_true(problems.contains("myth/choir_tengri") and problems.contains("koro"), "problems() izin dışı koroyu yazar: %s" % problems)
	assert_false(problems.contains("tengri/choir_tengri"), "tengri'de koro serbest")
	expect_errors(["koro"])
	var stream := MusicBank.build(def)
	var myth := stream.get_clip_stream(0) as AudioStreamSynchronized
	var tengri := stream.get_clip_stream(1) as AudioStreamSynchronized
	assert_null(myth.get_sync_stream(1), "İzin dışı klipte koro kurulmaz")
	assert_not_null(tengri.get_sync_stream(1), "Gök klibinde kurulur")


func test_prologue_has_a_single_choir_cue_in_the_sky_panel() -> void:
	var timelines: Array[CineTimeline] = []
	if FileAccess.file_exists(PROLOGUE):
		timelines.append(CineTimeline.from_path(PROLOGUE))
	else:
		for file in DirAccess.get_files_at(CINE_DIR):
			if file.begins_with("prologue_") and file.get_extension() == "json":
				timelines.append(CineTimeline.from_path(CINE_DIR.path_join(file)))
	assert_false(timelines.is_empty(), "Önsöz'ün çizelgesi bulundu")
	var cues: Array[Dictionary] = []
	for timeline in timelines:
		var bank := ""
		for ev in timeline.events_of("music"):
			if ev.get("bank") is String:
				bank = str(ev["bank"])
			var clip := MusicBank.clip(MusicBank.load_def(bank), StringName(str(ev["state"])))
			for layer: Variant in MusicBank.layers(clip):
				if layer is Dictionary and MusicBank.is_choir(layer):
					cues.append(ev)
					break
	assert_eq(cues.size(), 1, "Önsöz'de koro işareti tek (#53)")
	if cues.size() == 1:
		assert_eq(str(cues[0]["state"]), "tengri", "Koro gök panosunda")
		assert_eq(str(cues[0]["segment"]), "myth", "Mit sinemasında")


func test_audio_manager_counts_one_choir_play_through_the_myth() -> void:
	audio = AudioManagerScript.new()
	add_child(audio)
	var before: int = audio.choir_plays(0)
	assert_true(audio.set_music_bank("prologue_myth", &"myth", 0.0), "Mit sinemasının bankası")
	for state: StringName in [&"erlik", &"tengri", &"myth"]:
		assert_true(audio.set_music_state(state), "%s klibi" % state)
	assert_eq(audio.choir_plays(0) - before, 1, "Önsöz'ün korosu bir kez sayılır (perde 0)")
	# Oynatıcılar durur; ses sunucusu çalış kayıtlarını birkaç karede bırakır (çıkışta «hâlâ kullanımda» yazılmasın).
	audio.stop_all()
	await get_tree().create_timer(0.3, true, false, true).timeout
	await wait_frames(3)


## Akışın dosyaları: düz Ogg'un yolu ya da Playlist'in cümlelerinin yolları.
static func _files_of(stream: AudioStream) -> PackedStringArray:
	var out := PackedStringArray()
	if stream == null:
		return out
	if stream is AudioStreamPlaylist:
		var list := stream as AudioStreamPlaylist
		for i in list.stream_count:
			var entry := list.get_list_stream(i)
			if entry and not out.has(entry.resource_path):
				out.append(entry.resource_path)
	elif not stream.resource_path.is_empty():
		out.append(stream.resource_path)
	return out
