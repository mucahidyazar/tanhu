extends TestCase
## Önsöz'ün kamp sahnesi «Kamp ve şarkı» (PrologueCamp, scenes/cine/prologue_camp.tscn; çizelgesi
## data/cine/prologue_camp.json; K68, story.md §3 satır 0a–0d, godot.md §3.6; Yol Haritası prologue-camp-scene):
##   - Çizelge (CineTimeline, satırın gerçek seconds'ıyla): WIDE'a 6,0'da varış, şarkı kamera durunca 6,0'da,
##     dizelerin altyazı pencereleri (0:09,9–0:14,7 ve 0:19,5–0:24,3), dron şarkının son 4,6 sn'sinde söner,
##     kol kaydın zarfına ve ızgarasına bağlı (8,3'te başlar, avuç son vuruşta, 28,64'te), 32,9 alçak sessizlik / 35,9 kararma /
##     37,9 kara / 38,9 son (3+2+1), camp_bard 2 sn.
##   - Sahne kablajı (world.tscn + MenuCamera + sahte ses hedefi, Engine.time_scale ile hızlı): kamera 6 sn'de WIDE,
##     yıldız %35 (0,84), ay ve gölün ay parıltısı yok, kopuz 4,2–5,3'te kalkar, Çocuk ozana döner, kol vuruşa bağlı;
##     bitince ya da atlanınca gök, su, sis, kamera, Çocuk'un bakışı ve kopuz setup'taki hâline döner (menüye dönüş
##     karesinin başsız güvencesi). Pencereli karşılaştırma tests/refs ile araçla yapılır (docs/testler.md).
## Dünya dosya başına bir kez kurulur; son test onu bırakır.

const TempDir := preload("res://tests/support/temp_dir.gd")
const SEGMENT := "res://data/cine/prologue_camp.json"
const WORLD_SCENE := "res://scenes/world/world.tscn"
const MAIN_SCENE := "res://scenes/main.tscn"
const SONG := "act0.bard.song"
## Sinemanın hızlandırıldığı oran (Engine.time_scale: kamera, kopuz ve yıldız geçişleri de aynı oranla akar).
const SPEED := 8.0
## Kolun çekim 3104'teki yeri (şarkının başından, sn): vuruş ızgarasının ilk duyulur vuruşa (2,31; kopuz 3,9 sn'de yükselerek
## girer) ve son vuruşa (22,62; avuç, plan «one palm slap») en yakın noktaları; el orada telleri geçer, sıçramaz.
const STRUM_AT := 2.3
const MUTE_AT := 22.64
## Şarkı çekimlerinin ölçüsü (tools/song/song_measure.mjs yazar).
const SONG_MEASURE := "res://tools/song/k75_measure.json"

var _world: World
var _hosts: Array[CineHost] = []
var _trash: Array[Node] = []


func before_each() -> void:
	Engine.time_scale = 1.0
	InputSetup.ensure_actions()


func after_each() -> void:
	Engine.time_scale = 1.0
	for host in _hosts:
		if is_instance_valid(host):
			host.stop()
			host.queue_free()
	_hosts.clear()
	for node in _trash:
		if is_instance_valid(node):
			node.queue_free()
	_trash.clear()
	get_viewport().disable_3d = false


# --- Çizelge -------------------------------------------------------------------------------------

func test_timeline_follows_the_table() -> void:
	var tl := CineTimeline.from_path(SEGMENT)
	assert_eq(tl.validate(), PackedStringArray(), "Çizelgede sorun olmamalı")
	assert_eq(tl.segments.size(), 1)
	var seg := tl.segment("camp")
	assert_eq(seg.get("world"), CineTimeline.WORLD_CAMP, "Kamp dünyasında")
	assert_eq(seg.get("view"), CineTimeline.VIEW_MAIN, "Ana kamerayla")
	assert_eq(seg.get("scene"), "res://scenes/cine/prologue_camp.tscn")
	var song := VoLines.seconds(SONG)
	assert_almost(song, 26.85, 0.05, "Çekim 3104")
	# Geri çekilme 0–6 sn; kamera 6,0'da durur, şarkı o anda başlar.
	var pullback := tl.find("pullback")
	assert_eq(pullback.get("type"), "shot")
	assert_almost(float(pullback["t"]), 0.0, 0.0001)
	assert_almost(float(pullback["duration"]), MenuCamera.PULLBACK_TIME, 0.0001)
	assert_almost(tl.time_of("hold"), 6.0, 0.0001, "WIDE'a 6,0'da varılır")
	assert_almost(tl.time_of("song"), 6.0, 0.0001, "Şarkı kamera durunca başlar")
	assert_almost(tl.time_of(SONG), 6.0, 0.0001)
	var voice := _first(tl, CineTimeline.VOICE)
	assert_almost(float(voice.get("t", -1.0)), 6.0 - CineAudio.PREROLL, 0.0001, "Şarkının sesi kısmadan 0,15 sn önce istenir")
	# Yıldızlar 4,0–6,0 (%35), kopuz 4,2'de 1,1 sn'de kalkar.
	var stars := tl.find("stars")
	assert_almost(float(stars["t"]), 4.0, 0.0001)
	assert_almost(float(stars["duration"]), 2.0, 0.0001)
	assert_almost(float(stars["share"]), 0.35, 0.0001)
	var raise := tl.find("raise")
	assert_almost(float(raise["t"]), 4.2, 0.0001)
	assert_almost(float(raise["end"]), 5.3, 0.0001)
	# Şarkının sonu ve sonrası: dron son 4,6 sn'de söner, avuç son vuruşta, 3 + 2 + 1.
	var song_end := tl.time_of("song_end")
	assert_almost(song_end, 6.0 + song, 0.0001)
	assert_almost(song_end, 32.85, 0.1)
	var drone := tl.find("drone_out")
	assert_eq(drone.get("type"), "layer")
	assert_eq(drone.get("layer"), "drone")
	assert_almost(float(drone["t"]), song_end - 4.6, 0.0001, "Dron şarkının son 4,6 sn'sinde söner")
	assert_almost(float(drone["t"]), 28.25, 0.1)
	assert_almost(float(drone["duration"]), 4.6, 0.0001)
	assert_true(float(drone["db"]) <= -60.0, "Dron susar")
	# Kol sessizde vurmaz: ilk duyulur vuruştan son vuruşa dek çalar, şarkının başına ve sonuna değil, kaydın zarfına bağlı.
	assert_almost(tl.time_of("strum"), 6.0 + STRUM_AT, 0.0001, "Kol ilk duyulur vuruşta başlar")
	assert_almost(tl.time_of("mute"), 6.0 + MUTE_AT, 0.0001, "Avuç son vuruşta")
	assert_true(tl.time_of("mute") < song_end - 4.0, "Son vuruştan sonra dosyanın 4,2 sn'si sönen kuyruktur")
	for at: float in [STRUM_AT, MUTE_AT]:
		assert_true(absf(sin(TAU * KopuzPlay.STROKE_HZ * (at - KopuzPlay.STROKE_ANCHOR))) < 0.05,
				"%.2f vuruşun sıfır geçişi: el sıçramaz (çekim değiştiyse yeniden ölçün)" % at)
	var grid := _selected_grid()
	assert_almost(STRUM_AT, float(grid.get("anchor", NAN)), 0.01, "Kol ölçünün ilk ızgara noktasında başlar")
	assert_almost(MUTE_AT, float(grid.get("lastGrid", NAN)), 0.01, "Avuç ölçünün son ızgara noktasında")
	assert_true(absf(MUTE_AT - float(grid.get("last", NAN))) < 0.035, "Avuç kaydın son vuruşunda")
	var silence := tl.find("silence")
	assert_eq(silence.get("type"), "low_silence")
	assert_almost(float(silence["t"]), 32.9, 0.1, "Alçak sessizlik 32,9")
	var out := tl.find("out")
	assert_eq(out.get("type"), "fade")
	assert_almost(float(out["to"]), 1.0, 0.0001)
	assert_almost(float(out["t"]), 35.9, 0.1, "Kararma 35,9")
	var black := tl.find("black")
	assert_almost(float(black["t"]), 37.9, 0.1, "Kara 37,9")
	assert_almost(tl.total(), 38.9, 0.1, "Son 38,9")
	assert_almost(tl.total(), song_end + 6.05, 0.0001)
	assert_almost(float(out["t"]) - float(silence["t"]), 3.0, 0.0001, "3 sn alçak sessizlik")
	assert_almost(float(black["t"]) - float(out["t"]), 2.0, 0.0001, "2 sn kararma")
	assert_almost(tl.total() - float(black["t"]), 1.0, 0.0001, "1 sn kara")
	# Menü müziği 2 sn'de camp_bard dronuna; rüzgâr 0–6 sn'de yükselir.
	var music := _first(tl, "music")
	assert_almost(float(music["t"]), 0.0, 0.0001)
	assert_eq([music.get("bank"), music.get("state"), float(music.get("fade", 0.0))], ["camp", "camp_bard", 2.0])
	var wind := tl.find("wind_steppe")
	assert_eq(wind.get("type"), "ambience")
	assert_almost(float(wind["duration"]), 6.0, 0.0001)
	assert_true(float(wind["db"]) > PrologueCamp.SILENT_DB + 30.0, "Rüzgâr duyulur")


func test_pullback_never_nears_the_bard() -> void:
	# K68 ve K98: kamera ozana yaklaşmaz. Menü kadrajından (ateşe 26,4 m, 38°) WIDE'a (40 m, 9°) ozana uzaklık hiç azalmaz,
	# ozan bütün yol boyunca karededir; yolun ilk anahtarı K98'in kuralındadır (eğim ≥30°, ateşe ≥25 m).
	var bard := _bard_position()
	var menu := _menu_transform()
	assert_true(rad_to_deg(asin(menu.basis.z.y)) >= 30.0, "Menü kadrajı yüksek açılı")
	assert_true(menu.origin.length() >= 25.0, "Menü kadrajı ateşe ≥25 m")
	var last := 0.0
	for i in 61:
		var t := float(i) * 0.1
		var pose := MenuCamera.pullback_pose(menu, t)
		var d := pose.origin.distance_to(bard)
		assert_true(d >= last - 0.0001, "t=%.1f: ozana uzaklık azalmaz (%.2f → %.2f m)" % [t, last, d])
		last = d
		var vfov := lerpf(MenuCamera.MENU_FOV, MenuCamera.WIDE_FOV, MenuCamera.ease_in_out(t / MenuCamera.PULLBACK_TIME))
		var y := MenuCamera.screen_y(pose, vfov, bard)
		assert_between(y, 0.05, 0.95, "t=%.1f: ozan karede (%.2f)" % [t, y])
	assert_true(last >= 38.0, "WIDE'da ozan ≥38 m uzakta (%.1f m)" % last)


func test_song_subtitles_and_pan() -> void:
	var tl := CineTimeline.from_path(SEGMENT)
	var song := tl.find("song")
	var windows := SubtitleBar.line_windows(SONG, float(song["t"]), float(song["duration"]), "tr")
	assert_eq(windows.size(), 2, "Şarkının iki dizesi")
	if windows.size() == 2:
		assert_almost(float(windows[0]["t0"]), 9.92, 0.05, "1. dize 0:09,9")
		assert_almost(float(windows[0]["t1"]) - SubtitleBar.TAIL, 14.7, 0.05, "1. dize 0:14,7'de biter")
		assert_almost(float(windows[1]["t0"]), 19.5, 0.05, "2. dize 0:19,5")
		assert_almost(float(windows[1]["t1"]) - SubtitleBar.TAIL, 24.32, 0.05, "2. dize 0:24,3'te biter")
	# Şarkı 2B'dir, ozanın yönüne en çok %10 kayar: WIDE'da ozan karenin ortasının sağındadır.
	var pan := float(song.get("pan", 0.0))
	assert_between(pan, 0.01, 0.1, "Ozanın yönüne ≤%10")
	var bard := _bard_position()
	var local := MenuCamera.wide_transform().affine_inverse() * bard
	var half_width := tan(deg_to_rad(MenuCamera.WIDE_FOV) * 0.5) * 16.0 / 9.0
	var bard_x := (local.x / -local.z) / half_width
	assert_almost(pan, bard_x, 0.03, "Kayma ozanın karedeki yerine uyar (%.3f)" % bard_x)


# --- Sahne kablajı --------------------------------------------------------------------------------

func test_scene_plays_the_camp_and_restores_everything() -> void:
	var world := await _get_world()
	if world == null:
		return
	var camera := _menu_camera()
	var fake := FakeAudio.new()
	var host := _new_host(fake, world, camera)
	var npcs := world.get_node(^"Camp/CampNpcs") as CampNpcs
	var sky := PrologueCamp.sky_material(world)
	var water := PrologueCamp.water_material(world)
	assert_not_null(sky, "Kampın gök malzemesi")
	assert_not_null(water, "Gölün malzemesi")
	var before := _state(world, camera)
	var kopuz := npcs.get_kopuz()
	var child := npcs.get_node(^"Child") as CharacterAvatar
	var watcher := watch_signal(host.finished)
	Engine.time_scale = SPEED
	host.play(SEGMENT)
	await _until(host, 0.3)
	var scene := host.scene_node("camp") as PrologueCamp
	assert_not_null(scene, "Kamp sahnesi kurulmalı")
	if scene == null:
		return
	assert_eq(fake.find("set_music_bank").slice(1), ["camp", "camp_bard", 2.0], "Menü müziği 2 sn'de camp_bard dronuna")
	assert_eq(fake.find("set_ambience_layer").slice(1, 2), ["wind_steppe"], "Rüzgâr katmanı başlar")
	assert_almost(float(sky.get_shader_parameter("moon_glow_strength")), 0.0, 0.0001, "Ay çizilmez")
	assert_true(float(sky.get_shader_parameter("moon_radius")) < 0.001)
	assert_eq(sky.get_shader_parameter("moon_glow_color"), Color(0.0, 0.0, 0.0))
	var moon_dir: Vector3 = sky.get_shader_parameter("moon_direction")
	assert_true(moon_dir.y < -0.2, "Ay ufkun altında: bulutlar ayın yerinde parlamaz (%s)" % moon_dir)
	assert_true(MenuCamera.screen_y(MenuCamera.wide_transform(), MenuCamera.WIDE_FOV, MenuCamera.WIDE_ORIGIN + moon_dir * 1000.0) > 1.0 \
		or is_nan(MenuCamera.screen_y(MenuCamera.wide_transform(), MenuCamera.WIDE_FOV, MenuCamera.WIDE_ORIGIN + moon_dir * 1000.0)),
		"Ayın yönü WIDE karesinin dışında")
	assert_almost(float(water.get_shader_parameter("glint_energy")), 0.0, 0.0001, "Ay yokken gölde ay parıltısı yok")
	assert_almost(float(sky.get_shader_parameter("star_brightness")), 0.0, 0.0001, "Yıldızlar 4,0'a dek kapalı")
	assert_true(camera.is_flying(), "Kamera geri çekiliyor")
	var play := scene.play
	assert_not_null(play, "Ozanın kolları KopuzPlay'e bağlanmalı")
	if play == null:
		return
	assert_true(play.get_parent() is Skeleton3D, "KopuzPlay ozanın iskeletinde")
	await _until(host, 4.1)
	assert_almost(play.lift_weight, 0.0, 0.0001, "4,2'den önce kopuz kucakta")
	await _until(host, 5.45)
	assert_almost(play.lift_weight, 1.0, 0.0001, "5,3'te kopuz kalkmış")
	assert_true(kopuz.transform.is_equal_approx(kopuz.play_transform), "Çalış pozu")
	await _until(host, 6.3)
	var wide := MenuCamera.wide_transform()
	assert_vec_almost(camera.global_transform.origin, wide.origin, 0.07, "Kamera 6 sn'de WIDE'da")
	assert_true(camera.global_transform.basis.is_equal_approx(wide.basis), "WIDE'ın yönü")
	assert_true(camera.has_drift_base and camera.drifting, "WIDE'da nefes alır (drift_base)")
	assert_false(camera.is_flying())
	var size := get_viewport().get_visible_rect().size
	var fit := MenuCamera.fit_fov(MenuCamera.WIDE_FOV, camera.design_aspect, size.x / size.y)
	assert_almost(camera.fov, float(fit["fov"]), 0.01, "Görüş açısı WIDE'ınki (bu ekran oranında)")
	var full := PrologueCamp.shader_default(sky.shader, "star_brightness")
	assert_almost(full, 2.4, 0.0001, "Yıldız katmanının tam parlaklığı (sky.gdshader varsayılanı)")
	assert_almost(float(sky.get_shader_parameter("star_brightness")), 0.84, 0.001, "Yıldızlar %35")
	var song_call := fake.find("play_song")
	assert_eq(song_call.slice(1, 2), [SONG], "Şarkı çalar")
	if song_call.size() > 2:
		assert_almost(float((song_call[2] as Dictionary).get("pan", 0.0)), 0.08, 0.0001, "Şarkı ozanın yönüne kayar")
	assert_false(play.strumming, "Girişin sessiz payında kol vurmaz")
	assert_almost(play.swing(), 0.0, 0.0001, "El tellerde durur")
	assert_almost(play.song_time, host.time() - 6.0, 0.1, "Vuruşun saati şarkının saati")
	await _until(host, 8.0)
	assert_vec_almost(child.face_point, npcs.get_bard().global_position, 0.01, "Çocuk ozana döner")
	await _until(host, 6.0 + STRUM_AT + 0.2)
	assert_true(play.strumming, "Kol ilk duyulur vuruşta vuruşa bağlanır")
	assert_almost(play.song_time, host.time() - 6.0, 0.1, "Vuruşun saati şarkının saati")
	await _until(host, 26.0)
	assert_false(play.muted, "Son vuruşa dek çalar")
	await _until(host, 6.0 + MUTE_AT + 0.2)
	assert_eq(fake.find("set_layer_db").slice(1), ["drone", -80.0, 4.6], "Dron şarkının son 4,6 sn'sinde söner")
	assert_true(play.muted, "Avuç son vuruşu susturur")
	assert_almost(play.swing(), 0.0, 0.0001)
	await _until(host, 33.1)
	assert_eq(fake.find("low_silence").slice(1, 2), [true], "Alçak sessizlik")
	await _wait_until(func() -> bool: return watcher.fired, 20.0)
	Engine.time_scale = 1.0
	assert_eq(watcher.last_args, [false], "Kamp segmenti sonuna dek oynar")
	assert_almost(host.fade_alpha(), 1.0, 0.001, "Kara perdeyle biter")
	_assert_restored(before, _state(world, camera))
	assert_false(is_instance_valid(play) and play.is_inside_tree(), "KopuzPlay kalkmalı")
	var wind_calls := fake.all("set_ambience_layer")
	assert_eq((wind_calls.back() as Array).slice(1), ["wind_steppe", PrologueCamp.SILENT_DB, PrologueCamp.WIND_OUT],
		"Tek segment bitince rüzgâr söner")


func test_skip_mid_pullback_restores_the_menu_frame() -> void:
	var world := await _get_world()
	if world == null:
		return
	var camera := _menu_camera()
	var fake := FakeAudio.new()
	var host := _new_host(fake, world, camera)
	var before := _state(world, camera)
	var watcher := watch_signal(host.finished)
	Engine.time_scale = SPEED
	host.play(SEGMENT)
	# Kamera yolun ortasında, yıldızlar açılırken, kopuz kalkarken atlanır.
	await _until(host, 4.7)
	var scene := host.scene_node("camp") as PrologueCamp
	assert_true(camera.is_flying(), "Atlarken kamera uçuyor")
	assert_true(scene != null and scene.play != null and scene.play.lift_weight > 0.0, "Kopuz kalkıyor")
	host.skip()
	await _wait_until(func() -> bool: return watcher.fired, 10.0)
	Engine.time_scale = 1.0
	assert_eq(watcher.last_args, [true], "Atlandı")
	assert_false(camera.is_flying(), "Atlanınca uçuş durur")
	_assert_restored(before, _state(world, camera))
	assert_true(fake.all("set_ambience_layer").size() >= 2, "Atlanınca rüzgâr söner")


func test_seek_to_the_song_builds_the_wide_frame() -> void:
	# --cine-at=6.5 (ekran görüntüsü): ileri sarınca kamera WIDE'da, yıldızlar %35, kopuz kalkmış, şarkı sessiz.
	var world := await _get_world()
	if world == null:
		return
	var camera := _menu_camera()
	var fake := FakeAudio.new()
	var host := _new_host(fake, world, camera)
	var before := _state(world, camera)
	var sky := PrologueCamp.sky_material(world)
	host.play(SEGMENT, 6.5)
	var scene := host.scene_node("camp") as PrologueCamp
	assert_not_null(scene)
	assert_vec_almost(camera.global_transform.origin, MenuCamera.WIDE_ORIGIN, 0.001, "İleri sarınca WIDE")
	assert_almost(float(sky.get_shader_parameter("star_brightness")), 0.84, 0.001)
	if scene and scene.play:
		assert_almost(scene.play.lift_weight, 1.0, 0.0001)
		assert_false(scene.play.strumming, "Girişin sessiz payında kol henüz vurmaz")
	assert_eq(fake.count("play_song"), 0, "İleri sarmada şarkı çalmaz")
	host.stop()
	_assert_restored(before, _state(world, camera))


func test_seek_keeps_the_arm_on_the_recordings_envelope() -> void:
	# İleri sarınca kol: ilk duyulur vuruştan önce durur, son vuruşa dek çalar, sonra avuç tellerde (şarkı sessiz çalmaz).
	var world := await _get_world()
	if world == null:
		return
	var camera := _menu_camera()
	var before := _state(world, camera)
	for row: Array in [[6.0 + STRUM_AT - 0.2, false, false], [6.0 + STRUM_AT + 0.2, true, false],
			[6.0 + MUTE_AT - 0.2, true, false], [6.0 + MUTE_AT + 0.2, true, true]]:
		var host := _new_host(FakeAudio.new(), world, camera)
		host.play(SEGMENT, float(row[0]))
		var scene := host.scene_node("camp") as PrologueCamp
		assert_not_null(scene)
		if scene and scene.play:
			assert_eq(scene.play.strumming, row[1], "%.2f sn'de vuruş" % row[0])
			assert_eq(scene.play.muted, row[2], "%.2f sn'de avuç" % row[0])
		host.stop()
		_assert_restored(before, _state(world, camera))


func test_new_game_plays_the_camp_then_the_menu_frame_returns() -> void:
	# Yeni Oyun'dan 0:38,9'a: ana sahne (main.tscn, Önsöz'ü kamp segmenti) → kamp segmenti (Engine.time_scale ile
	# hızlı) → kara perdeden oluşturucu → vazgeç → menü: kamera menü kadrajında; gök, su, ateş başı ve kopuz Yeni
	# Oyun öncesiyle aynı (menüye dönüş karesinin başsız güvencesi). Kayıtlar geçici klasörde, ayar sahtedir.
	var dir := TempDir.fresh("onsoz_kamp")
	var main = load(MAIN_SCENE).instantiate()
	main.quit_handler = func() -> void: pass
	main.saves = SaveSystem.new(dir)
	main.prologue_path = SEGMENT
	# Önsöz'ün oynanan günleri (E21) bu dosyada değil: test_prologue_days.gd.
	main.prologue_days_path = ""
	# Yeni Oyun'un akışından yalnız Önsöz ve oluşturucu (K99).
	main.new_game_only = PackedStringArray(["prologue", "creator"])
	add_child(main)
	_trash.append(main)
	await wait_frames(3)
	main.menu.finish_intro()
	var fresh := NotSeenSettings.new()
	_trash.append(fresh)
	main.settings = fresh
	await wait_frames(1)
	var world: Node = main.world
	var camera: MenuCamera = main.menu_camera
	var before := _state(world, camera)
	Engine.time_scale = SPEED
	main.menu.start_requested.emit()
	await _wait_until(func() -> bool: return main.state == main.State.CINE, 5.0)
	assert_eq(main.state, main.State.CINE, "Yeni Oyun kamp segmentini oynatmalı")
	var host: CineHost = main.cine
	await _until(host, 6.3)
	assert_vec_almost(camera.global_transform.origin, MenuCamera.WIDE_ORIGIN, 0.07, "6 sn'de WIDE")
	assert_true(camera.current, "Ekrandaki kamera menü kamerası")
	var npcs := world.get_node(^"Camp/CampNpcs") as CampNpcs
	assert_true(npcs.get_kopuz().transform.is_equal_approx(npcs.get_kopuz().play_transform), "Kopuz çalış pozunda")
	await _wait_until(func() -> bool: return main.state == main.State.CREATOR, 20.0)
	Engine.time_scale = 1.0
	assert_eq(main.state, main.State.CREATOR, "Segment bitince oluşturucu açılır")
	assert_almost(host.time(), 38.9, 0.1, "Kamp segmenti 0:38,9'a dek oynar")
	main.creator.cancelled.emit()
	await _wait_until(func() -> bool: return main.state == main.State.MENU, 6.0)
	assert_eq(main.state, main.State.MENU, "Vazgeç menüye döner")
	var after := _state(world, camera)
	# Menüde kamera salınır (0,06 m): kadraj menu_transform çevresinde.
	assert_true((after["camera"] as Transform3D).origin.distance_to(camera.menu_transform.origin) < 0.07, "Menü kadrajı")
	after["camera"] = before["camera"]
	_assert_restored(before, after)
	main.get_viewport().disable_3d = false
	main.queue_free()
	var audio := get_node_or_null(^"/root/AudioManager")
	if audio:
		audio.stop_all()
		audio.reset_buses()
	await get_tree().create_timer(0.25).timeout
	TempDir.wipe(dir)


## Paylaşılan dünyayı bırakır (dosyanın son sahne testi).
func test_world_frees_cleanly() -> void:
	var world := await _get_world()
	if world == null:
		return
	world.queue_free()
	_world = null
	await get_tree().create_timer(0.2).timeout
	await wait_frames(2)
	assert_false(is_instance_valid(world), "Dünya silinmeli")


# --- Yardımcılar ---------------------------------------------------------------------------------

## Seçili çekimin vuruş ızgarası (k75_measure.json, info.strokeGrid; yoksa boş).
func _selected_grid() -> Dictionary:
	var take := int(VoLines.line(SONG).get("take", 0))
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SONG_MEASURE))
	if parsed is Dictionary:
		for row: Variant in (parsed as Dictionary).get("takes", []):
			if int((row as Dictionary).get("seed", 0)) == take:
				return row["info"]["strokeGrid"]
	return {}


func _get_world() -> World:
	if _world == null:
		var packed := load(WORLD_SCENE) as PackedScene
		_world = packed.instantiate() as World if packed else null
		if _world == null:
			fail("Dünya kurulamadı")
			return null
		add_child(_world)
		await wait_frames(3)
	return _world


## main.tscn'deki menü kamerası gibi bir MenuCamera (menü kadrajında, etkin).
func _menu_camera() -> MenuCamera:
	var camera := MenuCamera.new()
	camera.design_fov = MenuCamera.MENU_FOV
	camera.near = 0.05
	camera.far = 6000.0
	camera.menu_transform = _menu_transform()
	add_child(camera)
	camera.global_transform = camera.menu_transform
	camera.make_current()
	_trash.append(camera)
	return camera


func _new_host(fake: FakeAudio, world: Node3D, camera: Camera3D) -> CineHost:
	var host := CineHost.new()
	host.audio = CineAudio.new(fake)
	host.world = world
	host.menu_camera = camera
	add_child(host)
	_hosts.append(host)
	return host


## Menüye dönüş karesini belirleyen durum: gök ve su tekdüzenleri, sis, kamera, Çocuk'un bakışı, kopuz, ozanın
## iskeletindeki değiştiriciler.
func _state(world: Node, camera: MenuCamera) -> Dictionary:
	var sky := PrologueCamp.sky_material(world)
	var water := PrologueCamp.water_material(world)
	var env := (world.get_node(^"WorldEnvironment") as WorldEnvironment).environment
	var npcs := world.get_node(^"Camp/CampNpcs") as CampNpcs
	var skeleton := npcs.get_bard().get_skeleton()
	var modifiers := PackedStringArray()
	if skeleton:
		for child in skeleton.get_children():
			modifiers.append(child.name)
	var state := {
		"camera": camera.global_transform, "fov": camera.fov, "keep_aspect": camera.keep_aspect,
		"drifting": camera.drifting, "drift_base": camera.has_drift_base,
		"fog": env.fog_density, "volumetric_fog": env.volumetric_fog_density,
		"glint": water.get_shader_parameter("glint_energy"),
		"child_face": (npcs.get_node(^"Child") as CharacterAvatar).face_point,
		"kopuz": npcs.get_kopuz().transform,
		"modifiers": modifiers,
	}
	for param: String in ["star_brightness", "moon_radius", "moon_glow_strength", "moon_glow_color", "moon_direction"]:
		state["sky:" + param] = sky.get_shader_parameter(param)
	return state


func _assert_restored(before: Dictionary, after: Dictionary) -> void:
	for key: String in before:
		var a: Variant = before[key]
		var b: Variant = after.get(key)
		if a is Transform3D:
			assert_true((a as Transform3D).is_equal_approx(b), "%s eski hâline dönmeli (%s ≠ %s)" % [key, a, b])
		elif a is Vector3:
			assert_vec_almost(b, a, 0.0001, "%s eski hâline dönmeli" % key)
		elif a is float:
			assert_almost(float(b), float(a), 0.0001, "%s eski hâline dönmeli" % key)
		else:
			assert_eq(b, a, "%s eski hâline dönmeli" % key)


## main.tscn'deki MenuCamera'nın dönüşümü (menü kadrajı).
static func _menu_transform() -> Transform3D:
	var state := (load(MAIN_SCENE) as PackedScene).get_state()
	for i in state.get_node_count():
		if state.get_node_name(i) != &"MenuCamera":
			continue
		for p in state.get_node_property_count(i):
			if state.get_node_property_name(i, p) == &"transform":
				return state.get_node_property_value(i, p)
	return Transform3D.IDENTITY


## Ozanın dünyadaki yeri (camp_npcs.tscn'den; kamp dünyada başlangıçtadır).
static func _bard_position() -> Vector3:
	var npcs := (load("res://scenes/world/camp_npcs.tscn") as PackedScene).instantiate() as Node3D
	var bard := npcs.get_node(^"Elder") as Node3D
	var p := bard.position
	npcs.free()
	return p


static func _first(tl: CineTimeline, type: String) -> Dictionary:
	var list := tl.events_of(type)
	return list[0] if not list.is_empty() else {}


## Sinema saati t'ye varana dek bekler (en çok 20 sn gerçek süre).
func _until(host: CineHost, t: float) -> void:
	await _wait_until(func() -> bool: return host.time() >= t or not host.is_playing(), 20.0)


func _wait_until(condition: Callable, timeout: float) -> void:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame


## AudioManager'ın sözleşmesini taklit eder; çağrıları sırayla kaydeder (test_cine.gd'deki gibi).
class FakeAudio:
	extends RefCounted

	var calls: Array = []

	func set_music_bank(bank: String, state: String, fade: float) -> void:
		calls.append(["set_music_bank", bank, state, fade])

	func set_music_state(state: String) -> void:
		calls.append(["set_music_state", state])

	func set_layer_db(layer: String, db: float, sec: float) -> void:
		calls.append(["set_layer_db", layer, db, sec])

	func set_ambience_layer(id: String, db: float, sec: float) -> void:
		calls.append(["set_ambience_layer", id, db, sec])

	func low_silence(on: bool, sec: float) -> void:
		calls.append(["low_silence", on, sec])

	func black_silence(sec: float) -> void:
		calls.append(["black_silence", sec])

	func play_song(id: String, opts: Dictionary = {}) -> void:
		calls.append(["play_song", id, opts])

	func play_line(id: String, opts: Dictionary = {}) -> float:
		calls.append(["play_line", id, opts])
		return VoLines.seconds(id)

	func stop_line(fade: float = 0.3) -> void:
		calls.append(["stop_line", fade])

	func request_lines(ids: PackedStringArray) -> void:
		calls.append(["request_lines", ids])

	func release_lines(ids: PackedStringArray) -> void:
		calls.append(["release_lines", ids])

	func song_position(_id: String = "") -> float:
		return -1.0

	func count(name: String) -> int:
		return all(name).size()

	func all(name: String) -> Array:
		var out := []
		for call: Array in calls:
			if call[0] == name:
				out.append(call)
		return out

	func find(name: String) -> Array:
		for call: Array in calls:
			if call[0] == name:
				return call
		return []


## Önsöz'ü görmemiş oyuncunun ayarı (GameSettings.prologue_seen / prologue_always; dosyaya yazılmaz).
class NotSeenSettings:
	extends Node

	var prologue_seen := false
	var prologue_always := false
