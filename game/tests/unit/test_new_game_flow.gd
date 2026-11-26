extends TestCase
## Yeni Oyun'un akışı (K99; K36, K37, K61, K67, K98; story.md §5–§6, docs-app story/childhood):
##   - Sıra data/story/new_game.json'dan: Önsöz → Çocukluk → Köprü 1 → oluşturucu → Yola Çıkış → Köprü 2 → son kart; I. Perde dosyası
##     gelene dek atlanır, hazır olunca son kart düşer; takvim atlamaları (−5.600, −41, 1, 1.041) yalnız ileri gider.
##   - Çocukluk'un verisi eksiksiz: dört adım, satırlar iki dilde ve tasarımdaki gibi, kişilerin modelleri ve dünyanın işaretleri var.
##   - Bütün akış ana sahnede: Yeni Oyun → Önsöz (atla) → Çocukluk (adımlar doğrudan sürülür: oyuncu hedefe konur, E ile biner ve alır,
##     kuş vurulur) → «Beni gördü.»yle donan kare Köprü 1'in parşömenine çapraz geçer → oluşturucu → Yola Çıkış (oluşturulan Mete; yay, avlu,
##     at, batı yolunda eşiğe sürüş; ayrıntısı test_departure.gd'de) → Köprü 2 (Kışlak'ın dünyası sürerken yüklenir; dosyası yoksa sessizce geçilir) → son kart
##     → açılış ekranı. Kampa inilmez, kayıt yazılmaz; takvim 22 Eylül MÖ 228 → 15 Aralık MÖ 213 → 26 Ocak MÖ 212 → 2 Aralık MÖ 210.
##   - «Çocukluğu geç» (K100'ün dili): Çocukluk'u bir kez bitiren oyuncuya başında sunulur; kısa Esc duraklatma, basılı Esc Köprü 1'dir.
##   - Çocukluk'ta duraklatma kitabının KAYDET'i kapalı ve açıklamalı; Ana Menü kayıt yazmadan akışı bırakır.
##   - Altyazının video bandı 16:10'da videonun 16:9 dikdörtgenine göredir.

const MAIN_SCENE := "res://scenes/main.tscn"
const CINE_TIMELINE := "res://data/cine/test_timeline.json"
const ORDOS := "res://scenes/maps/childhood_ordos.tscn"
## I. Perde'nin dünyası (Köprü 2'nin kancası) ve kancanın sınamasında onun yerine yüklenen küçük sahne.
const KISLAK := "res://scenes/maps/kislak.tscn"
const FAKE_WORLD := "res://scenes/fauna/rideable_sheep.tscn"
const TempDir := preload("res://tests/support/temp_dir.gd")
## Sınamada sinema ve sayımın hızı.
const CINE_SPEED := 24.0
const COUNT_SPEED := 8.0
const MARKERS: Array[String] = ["child_start", "lan_stand", "pen_gate", "pen_inside", "old_sheep", "fast_sheep", "race_start", "race_stone",
	"meadow", "children_at_line", "count_point", "counter"]

var _dir := ""
var _quit := false
var _warm: Array = []
## Akış boyunca her kare: kampa inildi mi, kayıt yazıldı mı?
var _camp_play := false
var _saved := false


func before_each() -> void:
	MenuStyle.muted = true
	Engine.time_scale = 1.0
	CineVideo.enabled = false
	_dir = TempDir.fresh("yeni_oyun")
	_camp_play = false
	_saved = false
	_quit = false


func after_each() -> void:
	Engine.time_scale = 1.0
	CineVideo.enabled = true
	get_tree().paused = false
	for action in CineHost.SKIP_ACTIONS:
		if InputMap.has_action(action):
			Input.action_release(action)
	_press_escape(false)
	TempDir.wipe(_dir)


# --- Sıra ------------------------------------------------------------------------------------------------

func test_order_follows_k99_and_skips_what_is_not_built() -> void:
	var flow := NewGameFlow.load_default()
	flow.start()
	assert_eq(flow.plan_ids(), PackedStringArray(["prologue", "childhood", "bridge_1", "creator", "depart", "bridge_2", "end_card"]),
		"Önsöz → Çocukluk → Köprü 1 → oluşturucu → Yola Çıkış → Köprü 2 → son kart (I. Perde yok)")
	assert_eq(str(flow.stage("depart")["kind"]), "scene", "Yola Çıkış oynanan küçük sahnedir")
	assert_eq(str(flow.stage("depart")["path"]), DepartScene.SCENE_PATH)
	assert_false(flow.stage("act_1").is_empty(), "I. Perde sırada yerini tutar")
	assert_eq(flow.stage("end_card").get("unless"), "act_1", "I. Perde gelince son kart düşer")
	assert_eq(str(flow.stage("act_1")["world"]), "res://scenes/maps/kislak.tscn", "I. Perde'nin dünyası Kışlak")
	assert_eq(str(flow.stage("bridge_2")["preload"]), "act_1", "Kışlak Köprü 2 sürerken yüklenir")
	assert_eq(int(flow.stage("bridge_1")["jump"]["day_n"]), -41, "Köprü 1 takvimi Yola Çıkış'a götürür (15 Aralık MÖ 213)")
	assert_eq(int(DepartScene.load_data()["day_n"]), -41, "Yola Çıkış 15 Aralık MÖ 213")
	var b2 := NewGameFlow.jumps(flow.stage("bridge_2"))
	assert_eq(b2.size(), 2, "Köprü 2'nin iki atlaması")
	if b2.size() == 2:
		assert_eq([int(b2[0]["day_n"]), str(b2[0]["at"])], [1, "tie"], "Çan bağlanınca rehineliğin 1. günü (26 Ocak MÖ 212)")
		assert_eq(int(b2[1]["day_n"]), 1041, "Köprü 2 takvimi I. Perde'nin Gün I'ine götürür (2 Aralık MÖ 210)")
	assert_false(is_nan(CineTimeline.from_path("res://data/cine/bridge_2.json").time_of("tie")), "Çizelgede çan olayı")
	assert_eq(NewGameFlow.jumps(flow.stage("bridge_1")).size(), 1, "Tek atlama (jump)")
	# Günlerin yazılı tarihi oyunun takvimiyle aynı (GameCalendar; saat sistemi gelince yolculuğun saati bu günleri okur).
	var calendar_path := "res://scripts/sim/time/game_calendar.gd"
	var calendar: Script = load(calendar_path) if ResourceLoader.exists(calendar_path) else null
	if calendar and calendar.has_method(&"format_tr"):
		assert_eq(calendar.call(&"format_tr", -5600), "22 Eylül MÖ 228", "Çocukluk'un günü")
		assert_eq(calendar.call(&"format_tr", -41), str(flow.stage("bridge_1")["jump"]["date"]["tr"]), "Köprü 1'in atlaması")
		assert_eq(str(flow.stage("depart")["date"]["tr"]).begins_with(str(calendar.call(&"format_tr", -41))), true, "Yola Çıkış'ın kartı")
		for jump in b2:
			assert_eq(calendar.call(&"format_tr", int(jump["day_n"])), str(jump["date"]["tr"]), "Köprü 2'nin atlaması %s" % jump["day_n"])
	assert_eq(NewGameFlow.advance(null, -5600), -5600, "Takvimin ilk günü")
	assert_eq(NewGameFlow.advance(-41, -5600), -41, "Takvim geri gitmez (K67)")
	assert_eq(NewGameFlow.advance(1, 1041), 1041, "İleri gider")
	assert_eq(int(ChildhoodScene.load_data()["day_n"]), -5600, "Çocukluk 22 Eylül MÖ 228")
	assert_eq(flow.plan("creator"), [flow.stage("creator"), flow.stage("depart"), flow.stage("bridge_2"), flow.stage("end_card")], "Oluşturucudan başlayan akış")
	assert_eq(flow.plan("", PackedStringArray(["prologue", "creator"])).size(), 2, "only ile yalnız o aşamalar")
	# Aşamalar sırayla verilir, sonra boş.
	var seen := PackedStringArray()
	var s := flow.next()
	while not s.is_empty():
		seen.append(str(s["id"]))
		assert_eq(flow.current_id(), str(s["id"]))
		s = flow.next()
	assert_eq(seen, flow.plan_ids())
	# I. Perde oynatılabilir olunca (burada bir sinema dosyasıyla benzetilir) son kart düşer; dosyası olmayan sahne atlanır.
	var fake := NewGameFlow.from_data({"stages": [
		{"id": "creator", "kind": "creator"},
		{"id": "depart", "kind": "scene", "path": "res://data/story/depart/yok.json"},
		{"id": "act_1", "kind": "cine", "path": "res://data/cine/bridge_2.json"},
		{"id": "end_card", "kind": "card", "unless": "act_1"},
	]})
	fake.start()
	assert_eq(fake.plan_ids(), PackedStringArray(["creator", "act_1"]), "Hazır I. Perde son kartı düşürür")
	assert_eq(NewGameFlow.text({"tr": "Çan", "en": "Bell"}, "en"), "Bell")
	assert_eq(NewGameFlow.text({"tr": "Çan"}, "en"), "Çan", "Dilde yoksa TR")


func test_childhood_data_is_complete_and_says_the_design_lines() -> void:
	var d := ChildhoodScene.load_data()
	assert_eq(ChildhoodScene.validate(d), PackedStringArray(), "Veri sorunsuz")
	assert_eq(ChildhoodScene.step_ids(d), PackedStringArray(["wake", "ride", "hunt", "count"]), "Dört adım sırayla")
	var lines: Dictionary = d["lines"]
	var want := {
		"wake": "Kalk, bugün sayım var. Koyunları ağıldan sen çıkaracaksın.",
		"race": "Yaşlısı senin, hızlısı benim.",
		"yanchi_bird": "O benim. Sayarken unutma.",
		"luhun_mouse": "Yavrusu var.",
		"count_child": "Bir çocuk.",
		"mete_catch": "İki kuş, bir fare.",
		"mete_catch_spared": "İki kuş.",
		"count_answer": "Onları da sayarım. Yenen de sayılır.",
		"saw_me": "Beni gördü.",
	}
	for id: String in want:
		assert_eq(str((lines[id] as Dictionary)["tr"]), want[id], "%s tasarımdaki gibi" % id)
		assert_false(str((lines[id] as Dictionary)["en"]).is_empty(), "%s İngilizcesi" % id)
	assert_eq(str((lines["saw_me"] as Dictionary)["en"]), "He saw me.")
	for id: String in (d["actors"] as Dictionary):
		assert_true(StandIn.has_model(id), "%s modeli hazır" % id)
	assert_true(StandIn.has_model(ChildLook.PERSON_METE), "Küçük Mete'nin modeli")
	var layout := OrdosWorld.load_layout(OrdosWorld.LAYOUT_PATH)
	var markers: Dictionary = (layout.get("childhood", {}) as Dictionary).get("markers", {})
	var world_markers: Dictionary = layout.get("markers", {})
	for id in MARKERS:
		assert_true(markers.has(id) or world_markers.has(id), "%s işareti dünyada" % id)
	# Söz süresi okunur: en az 2 sn, uzun satır daha uzun.
	assert_almost(StoryHud.line_seconds("Bir çocuk."), StoryHud.MIN_LINE, 0.001)
	assert_true(StoryHud.line_seconds(str((lines["wake"] as Dictionary)["tr"])) > 3.5)


func test_subtitle_band_follows_the_video_rect_on_16_10() -> void:
	assert_almost(SubtitleBar.video_band_lift(Vector2(1920, 1080)), 0.0, 0.001, "16:9'da bant yok")
	assert_almost(SubtitleBar.video_band_lift(Vector2(1920, 1200)), 60.0, 0.001, "16:10'da videonun altında 60 px pencere bandı")
	assert_almost(SubtitleBar.video_band_lift(Vector2(1728, 1080)), 54.0, 0.001, "1728 × 1080'de 54 px")
	# Pencerede: 1920 × 1200 tuvalde kutunun alt kenarı videonun alt kenarının 16 px (ölçekle) üstünde.
	var view := SubViewport.new()
	view.size = Vector2i(1920, 1200)
	add_child(view)
	var bar := SubtitleBar.new()
	view.add_child(bar)
	await wait_frames(2)
	var box: Control = bar.get_node(^"Box")
	var k := UIKit.ui_k()
	bar.video_band = true
	await wait_frames(1)
	var video := CineVideo.fit_rect(Vector2(1920, 1200))
	assert_almost(box.get_global_rect().end.y, video.end.y - SubtitleBar.VIDEO_MARGIN * k, 0.5, "Kutu videonun koyu bandında (pencerenin bandında değil)")
	assert_true(box.get_global_rect().end.y <= video.end.y, "Kutu videonun içinde")
	bar.video_band = false
	await wait_frames(1)
	assert_almost(box.get_global_rect().end.y, 1200.0 - SubtitleBar.BOTTOM_MARGIN * k, 0.5, "Video bitince eski yerine")
	bar.base_margin = StoryHud.SUBTITLE_MARGIN
	await wait_frames(1)
	assert_almost(box.get_global_rect().end.y, 1200.0 - StoryHud.SUBTITLE_MARGIN * k, 0.5, "Oynanan sahnede ipucunun üstünde")
	view.queue_free()


func test_controls_know_the_child_actions() -> void:
	var text := GameHud.format_hints(GameHud.CHILD_HINTS)
	for part in ["E: Bin · in · al", "Shift: Koş · dürt", "Sağ tık: Nişan", "Sol tık: Bırak", "Orta tuş: Kamera"]:
		assert_true(text.contains(part), "HUD: %s" % part)
	var rows := PackedStringArray()
	for g: Array in ControlsPage.GROUPS:
		for row: Array in g[1]:
			rows.append("%s=%s" % [row[0], ",".join(PackedStringArray(row[2]))])
	for want in ["Koyuna bin / in · yerden al=E", "Nişan al (basılı tut)=Sağ tık", "Oku bırak=Sol tık", "Kamerayı sürükle=Orta tuş"]:
		assert_true(rows.has(want), "Tuşlar sayfası: %s" % want)
	var uses := ControlsPage.key_uses()
	var e_uses: Array = []
	for u: Array in uses.get("E", []):
		e_uses.append(u[0])
	assert_true(e_uses.has("Bin · in · al"), "Klavyede E bin, in, al")


# --- Bütün akış ----------------------------------------------------------------------------------------------

func test_new_game_plays_the_whole_story_to_the_title() -> void:
	var main := await _new_main(CINE_TIMELINE)
	main.cine_speed = CINE_SPEED
	main.flow_card_hold = 0.4
	var seen := SeenSettings.new()
	main.settings = seen
	main.remember_childhood = true
	var probe := func() -> void:
		if main.state == main.State.PLAYING and main._story_world() == null:
			_camp_play = true
		if main.saves.has_any_save():
			_saved = true
	get_tree().process_frame.connect(probe)
	main.menu.start_requested.emit()
	assert_eq(main.state, main.State.CINE, "Yeni Oyun Önsöz'ü oynatır")
	assert_eq(main.flow_stage_id(), "prologue")
	await _wait_until(func() -> bool: return main.cine.time() > 0.2, 5.0)
	# Önsöz atlanır (basılı Esc).
	_press_escape(true)
	await _wait_until(func() -> bool: return main.flow_stage_id() == "childhood", 8.0)
	_press_escape(false)
	assert_eq(main.flow_stage_id(), "childhood", "Önsöz'den sonra Çocukluk")
	await _wait_until(func() -> bool: return main.cine.card_text() != "", 5.0)
	assert_eq(main.cine.card_text(), "22 Eylül MÖ 228 · Ordos", "Kara perdede tarih kartı")
	assert_true(main.journey.has_flag(CineHost.PROLOGUE_FLAG), "Atlanan Önsöz'ün işareti yeni yolculukta")
	assert_eq(int(main.journey.flags.get(NewGameFlow.DAY_FLAG, 0)), -5600, "Takvim 22 Eylül MÖ 228")
	await _wait_until(func() -> bool: return main.state == main.State.PLAYING, 90.0)
	assert_eq(main.state, main.State.PLAYING, "Çocukluk oynanır")
	var scene: ChildhoodScene = main._childhood_scene
	assert_not_null(scene, "Çocukluk'un sahnesi")
	if scene == null:
		get_tree().process_frame.disconnect(probe)
		await _free_main(main)
		return
	var ordos: OrdosWorld = main._childhood_world
	var site := ordos.childhood()
	# Söylenenler sahne silindikten sonra da okunur.
	var said: Array[String] = []
	scene.said.connect(func(id: String) -> void: said.append(id))
	said.append_array(Array(scene.said_lines))
	assert_false(main.world.visible, "Kamp bırakıldı")
	assert_eq(main.player.person_id(), ChildLook.PERSON_METE, "Küçük Mete")
	assert_true(main.follow_camera.is_active() and main.follow_camera.target == main.player, "K98 takip kamerası")
	assert_almost(main.follow_camera.get_target_distance(), FollowCamera.CHILD_DISTANCE, 0.01, "22 m: yakın plan yok")
	assert_eq(scene.actors.size(), 5, "Lan Hatun, Luhun, Yançi, sayıcı, Teoman")

	# 1) Uyanış: Mete kapının önünde oturur, Lan Hatun'un sözü altyazıda, amaç «Ağıla git», kapı kapalı.
	assert_eq(scene.current_step_id(), "wake")
	assert_true(main.player.is_seated(), "Uyanış: oturuyor")
	assert_false(site.gate_is_open(), "Ağılın kapısı kapalı")
	assert_eq(scene.hud.objective_text(), "Ağıla git")
	assert_eq(scene.hud.title_text(), "KOYUN SIRTINDA")
	# Oyun içi HUD: küçük Mete'nin portresi, görev kartı sahnenin adımını gösterir, yönü ağılın kapısıdır (sade amaç bloğu kapalı).
	var ghud: GameplayHud = main.gameplay_hud
	await wait_frames(2)
	assert_true(ghud.is_shown(), "Çocukluk'ta HUD açık")
	assert_eq(ghud.portrait.person, ChildLook.PERSON_METE, "Küçük Mete'nin portresi")
	ghud._poll_quest()
	assert_eq(ghud.quest_card.title, "Koyun Sırtında")
	assert_eq(ghud.quest_card.objective, "Ağıla git", "Görev kartı sahnenin adımında")
	assert_false(scene.hud.show_box, "Sade amaç bloğunun yerini kart aldı")
	assert_vec_almost(ghud.pointer.target, ordos.marker("pen_gate"), 0.01, "Görevin yönü ağılın kapısı")
	assert_not_null(ghud.map, "Ordos'un haritası")
	assert_eq(ghud.map.key, "ordos")
	await _wait_until(func() -> bool: return scene.said_lines.has("wake"), 5.0)
	assert_eq(scene.hud.subtitles.current_text(), "Lan Hatun: Kalk, bugün sayım var. Koyunları ağıldan sen çıkaracaksın.", "Çocukların ve ananın sözü altyazı")
	assert_true(main.hud.get_hint_text().contains("WASD"), "Tek ipucu: yürü, koş, kamera")
	await _assert_pause_blocks_saving(main)
	main.player.spawn_at(ordos.marker("pen_gate"), 0.0)
	await _wait_until(func() -> bool: return scene.current_step_id() == "ride", 3.0)

	# 2) Binme: kapı açılır, sürü salınır, Luhun hızlı koyunun sırtında; yaşlı koyuna E ile binilir, yarış taşa.
	assert_eq(scene.current_step_id(), "ride", "Ağılın kapısında binme adımı")
	assert_true(site.gate_is_open(), "Kapı açıldı")
	assert_eq(site.herd.phase(), HerdSim.Phase.LEAVING, "Sürü salındı")
	var luhun: StoryMover = scene.movers["luhun_child"]
	assert_true(luhun.is_seated(), "Luhun hızlı koyunun sırtında")
	assert_true((scene.sheep["fast_sheep"] as RideableSheep).ridden)
	var old: RideableSheep = scene.sheep["old_sheep"]
	main.player.spawn_at(old.global_position + Vector3(0.0, 0.0, 0.85), PI)
	assert_eq(main.player.mount_in_reach(), old, "Yaşlı koyun erimde")
	assert_true(main.player.interact(), "E biner")
	await _wait_until(func() -> bool: return main.player.is_riding(), 3.0)
	assert_true(main.player.is_riding())
	await wait_frames(2)
	assert_eq(scene.hud.objective_text(), "Luhun'la taşa yarış", "Binince yarış")
	await _wait_until(func() -> bool: return said.has("race"), 6.0)
	assert_true(said.has("race"), "Luhun: «Yaşlısı senin, hızlısı benim.»")
	main.player.spawn_at(ordos.marker("race_start"), PI * 0.5)
	await _wait_until(func() -> bool: return scene.current_phase() == "race", 3.0)
	assert_eq(scene.current_phase(), "race", "Yarış başladı")
	await wait_frames(20)
	assert_true(luhun.is_moving(), "Luhun taşa sürer")
	main.player.spawn_at(ordos.marker("race_stone") + Vector3(-1.5, 0.0, 0.0), 0.0)
	await _wait_until(func() -> bool: return scene.current_step_id() == "hunt", 3.0)

	# 3) Nişan: Yançi ilk kuşu önce vurur ve alır; fareye yaklaşınca Luhun konuşur; Mete iki kuş alır, fareyi vurmaz.
	assert_eq(scene.current_step_id(), "hunt")
	assert_eq(scene.hud.objective_text(), "İki tarla kuşu vur ve al (0/2)")
	main.player.spawn_at(Vector3(41.0, 0.0, 22.0), 0.0)
	Engine.time_scale = 4.0
	await _wait_until(func() -> bool: return scene.said_lines.has("yanchi_bird"), 20.0)
	Engine.time_scale = 1.0
	assert_true(scene.said_lines.has("yanchi_bird"), "Yançi: «O benim. Sayarken unutma.»")
	var hers: SmallGame = scene.get("_yanchi_bird")
	assert_not_null(hers, "Yançi'nin kuşu")
	if hers:
		assert_false(hers.is_in_group(SmallGame.FALLEN_GROUP), "Yançi'nin kuşunu Mete alamaz")
	var gerbil: SmallGame = site.game.of_kind("gerbil")[0]
	main.player.spawn_at(gerbil.global_position + Vector3(4.0, 0.0, 0.0), -PI * 0.5)
	# Söz sıradadır (E20/7): Yançi'nin sözü sürüyorsa Luhun onun bitişini bekler.
	await _wait_until(func() -> bool: return scene.said_lines.has("luhun_mouse"), 8.0)
	assert_true(scene.said_lines.has("luhun_mouse"), "Luhun: «Yavrusu var.»")
	for i in 2:
		var lark := _free_lark(scene, site)
		assert_not_null(lark, "Vurulacak bir kuş")
		if lark == null:
			break
		assert_true(lark.hit(lark.hit_center()), "Ok kuşa değer")
		await _wait_until(func() -> bool: return lark.is_down(), 5.0)
		main.player.spawn_at(lark.global_position + Vector3(0.7, 0.0, 0.0), -PI * 0.5)
		assert_not_null(main.player.pickup_in_reach(), "Düşen kuş erimde")
		assert_true(main.player.interact(), "E alır")
		await _wait_until(func() -> bool: return int(scene.catch["lark"]) == i + 1, 4.0)
		assert_eq(int(scene.catch["lark"]), i + 1, "Alınan kuş sayılır")
	await _wait_until(func() -> bool: return scene.current_step_id() == "count", 3.0)

	# 4) Sayım: sürü hattan geçer, çocuklar hatta; söz sırası; Teoman'ın bakışı uzak karedir; «Beni gördü.» → kara perde.
	assert_eq(scene.current_step_id(), "count", "İki kuştan sonra sayım")
	assert_eq(site.herd.phase(), HerdSim.Phase.DRIVING, "Sürü hattan geçiriliyor")
	assert_vec_almost(scene.hud_target(), ordos.marker("children_at_line"), 0.01, "Sayımda yön hattaki yer")
	assert_eq(main.gameplay_hud.bag.count("lark"), 2, "Alınan iki kuş heybede")
	main.player.spawn_at(ordos.marker("children_at_line"), PI)
	Engine.time_scale = COUNT_SPEED
	await _wait_until(func() -> bool: return scene.current_phase() == "gaze" or not scene.is_running(), 60.0)
	assert_eq(scene.current_phase(), "gaze", "Teoman bakıyor")
	assert_false(main.player.is_active(), "Söz sırasında oyuncu durur")
	assert_true((scene.actors["teoman"] as CineActor).visible, "Teoman hattın ucunda")
	assert_ne(main.follow_camera.target, main.player, "Odak Mete ile Teoman'ın ortası")
	assert_true(main.follow_camera.get_target_distance() >= FollowCamera.CHILD_DISTANCE, "Bakış uzak kare: yaklaşılmaz")
	var order := PackedStringArray()
	for id in said:
		if id in ["count_child", "mete_catch", "mete_catch_spared", "count_answer", "saw_me"]:
			order.append(id)
	assert_eq(order, PackedStringArray(["count_child", "mete_catch_spared", "count_answer"]), "Sayıcı, Mete («İki kuş.»), sayıcı")
	await _wait_until(func() -> bool: return said.has("saw_me"), 20.0)
	assert_true(said.has("saw_me"), "Mete: «Beni gördü.»")
	# «Beni gördü.»: görüntü donar, kararmaz; donmuş kare Köprü 1'in baş perdesidir ve parşömene çapraz geçer.
	await _wait_until(func() -> bool: return scene.current_phase() in ["fade", "black", "done"] or not is_instance_valid(scene), 20.0)
	assert_almost(main.fade.color.a, 0.0, 0.01, "Donan karede kara perde inmez")
	await _wait_until(func() -> bool: return main.flow_stage_id() == "bridge_1", 30.0)
	Engine.time_scale = 1.0
	assert_not_null(main._still_curtain, "Donmuş kare perdede")
	if main._still_curtain:
		assert_eq(main.cine.fade_rect, main._still_curtain, "Köprü 1'in baş perdesi donmuş kare")
		assert_not_null(main._still_curtain.still_texture(), "Karenin görüntüsü (başsızda kara)")
	await _wait_until(func() -> bool: return main._still_curtain == null, 10.0)
	assert_null(main._still_curtain, "Açılış bitince kare bırakılır")
	assert_eq(main.cine.fade_rect, main.fade, "Sinemanın perdesi yine UI/Fade")
	assert_true(main.journey.has_flag("mq0_sheep"), "Çocukluk bitti işareti")
	assert_true(main.journey.has_flag("child_spared"), "Fareyi vurmadı: child_spared")
	assert_true(seen.childhood_done, "İlk bitiş ayara yazılır: sonraki Yeni Oyun'da «Çocukluğu geç»")

	# Köprü 1 → oluşturucu → Köprü 2 → son kart → açılış ekranı.
	assert_eq(main.state, main.State.CINE, "Köprü 1 oynar")
	assert_null(main._childhood_world, "Çocukluk'un dünyası bırakıldı")
	assert_null(main._childhood_scene, "Sahne bırakıldı")
	assert_eq(main.player.process_mode, Node.PROCESS_MODE_INHERIT, "Donma kalktı")
	await _wait_until(func() -> bool: return main.state == main.State.CREATOR, 30.0)
	assert_eq(main.state, main.State.CREATOR, "Köprü 1'den sonra oluşturucu")
	assert_eq(int(main.journey.flags.get(NewGameFlow.DAY_FLAG, 0)), -41, "Takvim Yola Çıkış'ın günü")
	assert_true(main.world.visible, "Kamp perdenin arkasında yerinde (oluşturucu örter)")
	var chosen := CharacterProfile.new()
	chosen.set_value(&"skin", 3)
	main.creator.accepted.emit(chosen)
	await _wait_until(func() -> bool: return main.flow_stage_id() == "depart", 6.0)
	assert_eq(main.flow_stage_id(), "depart", "Oluşturucudan sonra Yola Çıkış")
	await _wait_until(func() -> bool: return main.state == main.State.PLAYING, 60.0)
	await _play_departure_quickly(main, chosen)
	assert_eq(main.flow_stage_id(), "bridge_2", "Yola Çıkış'tan sonra Köprü 2")
	assert_true(main.journey.has_flag("mq0_depart"), "Yola Çıkış bitti işareti")
	assert_false(main.player.visible, "Oluşturulan Mete kampa inmez")
	# Kışlak'ın yüklenmesi (I. Perde'nin dünyası): dosyası gelince Köprü 2 sürerken arka planda yüklenir; yoksa kanca sessizce geçer.
	if ResourceLoader.exists(KISLAK):
		assert_true(main.preloaded_worlds().has(KISLAK), "Kışlak Köprü 2 sürerken yükleniyor")
	else:
		assert_eq(main.preloaded_worlds().size(), 0, "Kışlak'ın dosyası yok: kanca sessizce geçer")
	await _wait_until(func() -> bool: return main.flow_stage_id() == "end_card", 30.0)
	assert_eq(int(main.journey.flags.get(NewGameFlow.DAY_FLAG, 0)), 1041, "Takvim I. Perde'nin Gün I'i")
	assert_eq(PackedInt32Array(main.day_history), PackedInt32Array([-5600, -41, 1, 1041]),
		"Takvim 22 Eylül MÖ 228 → 15 Aralık MÖ 213 → 26 Ocak MÖ 212 → 2 Aralık MÖ 210")
	for i in range(1, main.day_history.size()):
		assert_true(main.day_history[i] > main.day_history[i - 1], "Takvim geri gitmez (K67)")
	await _wait_until(func() -> bool: return main._flow_card != null, 5.0)
	if main._flow_card:
		assert_eq((main._flow_card.get_node(^"Box/Title") as Label).text, "I. Perde: Çan", "Son kart")
		assert_eq((main._flow_card.get_node(^"Box/Line") as Label).text, "Yapım aşamasında.")
	await _wait_until(func() -> bool: return main.state == main.State.MENU, 15.0)
	get_tree().process_frame.disconnect(probe)
	assert_eq(main.state, main.State.MENU, "Son karttan açılış ekranına")
	assert_true(main.menu.visible)
	assert_false(main.is_new_game_running(), "Akış bitti")
	assert_true(main.menu_camera.current, "Menü kamerası")
	assert_false(main.player.visible, "Oyuncu yok")
	assert_false(main.follow_camera.is_active())
	assert_almost(main.fade.color.a, 0.0, 0.01, "Perde kalktı")
	assert_false(main.get_viewport().disable_3d)
	assert_false(_camp_play, "Akışta kampa hiç inilmedi")
	assert_false(_saved, "Akışta kayıt yazılmadı")
	assert_eq(DirAccess.get_files_at(_dir).size(), 0, "Kayıt klasörü boş")
	assert_false(main.journey.has_flag(JourneyFlags.FIRST_ROAM), "Serbest gezinti işareti yok")
	assert_true(main.journey.profile.equals(chosen), "Seçilen karakter yolculukta")
	await _free_main(main)
	seen.queue_free()


## --state=prologue --cine-at=201.5 (doğum ajanının bildirdiği): ileri sarma doğumun girişiyle ilk çekimi (7a, 202,4 sn) arasındaki çakışmaya
## düşer; dünya hazır olana dek saat tutulur, sonra 7a oynar (ilk karesinde donmaz), 7b'ye geçilir. Akış main.gd'nin geliştirme yolundan.
func test_prologue_seek_into_the_birth_start_keeps_playing() -> void:
	var main := await _new_main(main_prologue())
	main.new_game_only = PackedStringArray(["prologue"])
	var seen := SeenSettings.new()
	main.settings = seen
	var tl := CineTimeline.from_path(main_prologue())
	var start := float(tl.segment("birth")["start"])
	var enter := float(tl.segment("birth")["enter"])
	var seek_at := 201.5
	assert_true(seek_at > enter and seek_at < start, "İleri sarma doğumun girişiyle 7a arasında (%.2f < %.2f < %.2f)" % [enter, seek_at, start])
	main._dev_prologue(main_prologue(), {"cine-at": str(seek_at)})
	assert_eq(main.flow_stage_id(), "prologue", "Önsöz akışın içinde oynar")
	await _wait_until(func() -> bool: return main.cine.time() > start + 1.0, 90.0)
	assert_true(main.cine.time() > start + 1.0, "Saat doğumun başını geçer (%.2f)" % main.cine.time())
	var birth: Node = main.cine.scene_node("birth")
	assert_not_null(birth, "Doğum sahnesi kurulu")
	var anim := birth.get(&"player") as AnimationPlayer if birth else null
	assert_not_null(anim, "Doğumun canlandırması")
	if anim:
		assert_eq(String(anim.current_animation), "7a", "7a oynuyor")
		assert_true(anim.is_playing(), "7a durmuyor")
		var p0 := anim.current_animation_position
		await get_tree().create_timer(0.6).timeout
		assert_true(anim.current_animation_position > p0 + 0.3, "7a ilerliyor: %.2f → %.2f" % [p0, anim.current_animation_position])
	# 7b'ye de geçilir (hızlanarak), sonra atlanır: akış açılış ekranına döner.
	main.cine.speed = 6.0
	await _wait_until(func() -> bool: return anim != null and is_instance_valid(anim) and String(anim.current_animation) == "7b", 20.0)
	if anim and is_instance_valid(anim):
		assert_eq(String(anim.current_animation), "7b", "7a'dan sonra 7b")
	main.cine.skip()
	await _wait_until(func() -> bool: return main.state == main.State.MENU, 15.0)
	assert_eq(main.state, main.State.MENU, "Önsöz'den sonra (yalnız Önsöz) açılış ekranı")
	await _free_main(main)
	seen.queue_free()


func main_prologue() -> String:
	return "res://data/cine/prologue.json"


func test_main_menu_from_the_childhood_leaves_without_a_save() -> void:
	SaveSystem.new(_dir).write(2, SaveData.build(CharacterProfile.new(), Vector3(2, 0, 2), 0.0, {"ahir_ziyaret": true}, 60.0, 1, "ocak"))
	var before := FileAccess.get_file_as_string(SaveSystem.new(_dir).slot_path(2))
	var main := await _new_main("")
	main.new_game_from = "childhood"
	main.childhood_step = "count"
	main.menu.start_requested.emit()
	await _wait_until(func() -> bool: return main.state == main.State.PLAYING, 90.0)
	var scene: ChildhoodScene = main._childhood_scene
	assert_not_null(scene)
	if scene:
		assert_eq(scene.current_step_id(), "count", "--step ile sayımdan")
		assert_eq(int(scene.catch["lark"]), 2, "Atlanan avda iki kuş sayılır")
		assert_eq(main.childhood_step, "count")
	await _open_pause(main)
	var book: GameMenu = main.pause_menu.get_menu()
	var general := book.get_page() as GeneralPage
	assert_not_null(general)
	if general:
		assert_true(general.get_button("save").disabled, "Çocukluk'ta KAYDET kapalı")
		assert_eq((general.find_child("Place", true, false) as Label).text, main.CHILDHOOD_PLACE, "Kartta Ordos")
	book._on_general("main")
	await _wait_until(func() -> bool: return main.state == main.State.MENU, 10.0)
	assert_eq(main.state, main.State.MENU, "Ana Menü")
	assert_null(main._childhood_world, "Dünya bırakıldı")
	assert_null(main._childhood_scene, "Sahne bırakıldı")
	assert_false(main.is_new_game_running(), "Akış bırakıldı")
	assert_null(main.get_node_or_null(^"UI/StoryHud"), "Sahnenin yazıları kalktı")
	assert_eq(main.follow_camera.target, main.player)
	assert_false(main.saves.has_save(SaveSystem.AUTO_SLOT), "Oto kayıt yazılmadı")
	assert_eq(FileAccess.get_file_as_string(main.saves.slot_path(2)), before, "Eski kayıt bozulmadı")
	assert_true(main.world.visible, "Kamp geri geldi")
	# Bırakılan akıştan sonra yeni bir Yeni Oyun yine çalışır (oluşturucudan; Geri Al açılış ekranına döner).
	main.new_game_from = "creator"
	main.menu.start_requested.emit()
	await _wait_until(func() -> bool: return main.state == main.State.CREATOR, 10.0)
	assert_eq(main.state, main.State.CREATOR)
	main.creator.cancelled.emit()
	await _wait_until(func() -> bool: return main.state == main.State.MENU, 10.0)
	assert_eq(main.state, main.State.MENU, "Geri Al açılış ekranına")
	assert_false(main.is_new_game_running())
	await _free_main(main)


## «Çocukluğu geç» (K100'ün dili): Çocukluk'u bir kez bitiren oyuncuya Çocukluk başında «Çocukluğu geç: Esc basılı tut» sunulur. Esc'in kısa
## basışı yine duraklatmadır; basılı tutuluşu Köprü 1'e atlar (karadan açılır), yolculuğa «mq0_sheep» ve «child_skipped» yazılır. Çocukluk'u
## bitirmemiş oyuncuya sunulmaz.
func test_second_childhood_offers_the_skip_and_held_esc_skips_it() -> void:
	var main := await _new_main("")
	var fresh := SeenSettings.new()
	main.settings = fresh
	main.new_game_from = "childhood"
	main.new_game_only = PackedStringArray(["childhood"])
	main.menu.start_requested.emit()
	await _wait_until(func() -> bool: return main.state == main.State.PLAYING, 90.0)
	assert_false(main.childhood_skip_offered(), "İlk Çocukluk'ta geç yok")
	assert_true(main._skip_offer == null or not main._skip_offer.visible, "Teklif görünmez")
	main.player.pause_requested.emit()
	await _wait_until(func() -> bool: return main.pause_menu.is_open(), 3.0)
	main.pause_menu.get_menu()._on_general("main")
	await _wait_until(func() -> bool: return main.state == main.State.MENU, 10.0)
	fresh.queue_free()

	var seen := SeenSettings.new()
	seen.childhood_done = true
	main.settings = seen
	main.cine_speed = CINE_SPEED
	main.new_game_only = PackedStringArray(["childhood", "bridge_1"])
	main.menu.start_requested.emit()
	await _wait_until(func() -> bool: return main.state == main.State.PLAYING, 90.0)
	assert_true(main.childhood_skip_offered(), "Çocukluk'u bitiren oyuncuya geç sunulur")
	var offer: Control = main._skip_offer
	assert_not_null(offer, "Teklif kuruldu")
	await wait_frames(30)
	if offer:
		assert_true(offer.visible and offer.modulate.a > 0.5, "Çocukluk başında görünür")
		assert_eq((offer.get_node(^"Text") as Label).text, "Çocukluğu geç: Esc basılı tut")
	# Kısa basış duraklatmadır (bırakınca kitap açılır).
	_press_escape(true)
	await wait_frames(3)
	assert_false(main.pause_menu.is_open(), "Esc basılıyken henüz duraklatma yok")
	_press_escape(false)
	await _wait_until(func() -> bool: return main.pause_menu.is_open(), 3.0)
	assert_true(main.pause_menu.is_open(), "Kısa basış duraklatma kitabını açar")
	main.pause_menu.get_menu().close()
	await _wait_until(func() -> bool: return main.state == main.State.PLAYING, 3.0)
	assert_eq(main.state, main.State.PLAYING)
	# Kapanan kitap aynı karede silinmez (queue_free): Esc'i bir sonraki karelerde yeniden basılır.
	await wait_frames(3)
	# Basılı Esc: halka dolar, Çocukluk atlanır.
	_press_escape(true)
	await _wait_until(func() -> bool: return main._skip_hold > 0.2, 3.0)
	if offer:
		assert_true(offer.visible and offer.progress > 0.0, "Basılıyken halka dolar")
	await _wait_until(func() -> bool: return main.flow_stage_id() == "bridge_1", 5.0)
	_press_escape(false)
	assert_eq(main.flow_stage_id(), "bridge_1", "Basılı Esc Köprü 1'e atlar")
	assert_false(main.pause_menu.is_open(), "Atlarken duraklatma açılmaz")
	assert_true(main.journey.has_flag("mq0_sheep"), "Çocukluk geçildi: mq0_sheep")
	assert_true(main.journey.has_flag(main.CHILDHOOD_SKIPPED_FLAG), "child_skipped")
	assert_false(main.journey.has_flag("child_spared"), "Seçim yapılmadı")
	assert_null(main._childhood_world, "Dünya bırakıldı")
	assert_null(main._still_curtain, "Geçilen Çocukluk'tan Köprü 1 karadan açılır")
	if offer:
		assert_false(offer.visible, "Teklif çekildi")
	await _wait_until(func() -> bool: return main.state == main.State.MENU, 30.0)
	assert_eq(main.state, main.State.MENU)
	await _free_main(main)
	seen.queue_free()


## Kışlak'ın kancası: Köprü 2 sürerken preload'daki aşamanın dünyası arka planda yüklenir (burada I. Perde'nin dünyası küçük bir sahneyle
## benzetilir); alan olmazsa yükleme bitince bırakılır. Dosya yoksa sessizce geçilir (uyarı ya da hata yok).
func test_bridge_2_preloads_the_next_world_and_skips_silently_without_it() -> void:
	var main := await _new_main("")
	main.cine_speed = CINE_SPEED
	var real := NewGameFlow.load_default()
	var bridge: Dictionary = real.stage("bridge_2").duplicate(true)
	var card: Dictionary = real.stage("end_card").duplicate(true)
	main.new_game_data = {"stages": [bridge, {"id": "act_1", "kind": "act", "path": "res://data/story/act_1/yok.json", "world": "res://scenes/maps/yok.tscn"}, card]}
	main.flow_card_hold = 0.2
	main.menu.start_requested.emit()
	await _wait_until(func() -> bool: return main.flow_stage_id() == "bridge_2", 5.0)
	await wait_frames(5)
	assert_eq(main.preloaded_worlds().size(), 0, "Dünyanın dosyası yok: sessizce geçilir")
	await _wait_until(func() -> bool: return main.state == main.State.MENU, 30.0)
	assert_eq(PackedInt32Array(main.day_history), PackedInt32Array([1, 1041]), "Köprü 2'nin iki günü sırayla")
	main.new_game_data = {"stages": [bridge, {"id": "act_1", "kind": "act", "path": "res://data/story/act_1/yok.json", "world": FAKE_WORLD}, card]}
	main.menu.start_requested.emit()
	await _wait_until(func() -> bool: return main.flow_stage_id() == "bridge_2", 5.0)
	await _wait_until(func() -> bool: return main.preloaded_worlds().has(FAKE_WORLD), 3.0)
	assert_true(main.preloaded_worlds().has(FAKE_WORLD), "Dünya köprü sürerken arka planda yükleniyor")
	await _wait_until(func() -> bool: return main.flow_stage_id() == "end_card", 30.0)
	assert_eq(main.flow_stage_id(), "end_card", "I. Perde yok: son kart")
	await _wait_until(func() -> bool: return main.state == main.State.MENU, 30.0)
	assert_eq(main.preloaded_worlds().size(), 0, "Alan olmadı: yükleme bırakıldı")
	await wait_frames(10)
	await _free_main(main)


# --- Yardımcılar ---------------------------------------------------------------------------------------------

## Yola Çıkış'ı hızla oynar (yay, avlu, at; ayrıntılı sınaması test_departure.gd'de): oluşturulan Mete, Görevler'de biten «Koyun Sırtında»,
## takvim 15 Aralık MÖ 213; adımlar oyuncuyu hedefe koyarak sürülür. Köprü 2 başlayınca döner.
func _play_departure_quickly(main: Node, chosen: CharacterProfile) -> void:
	var dep: DepartScene = main._depart_scene
	var world: DepartWorld = main._depart_world
	assert_not_null(dep, "Yola Çıkış'ın sahnesi")
	if dep == null or world == null:
		return
	assert_eq(main.state, main.State.PLAYING, "Yola Çıkış oynanır")
	assert_false(main.world.visible, "Ana kampa inilmez (K6)")
	assert_eq(int(main.journey.flags.get(NewGameFlow.DAY_FLAG, 0)), -41, "Takvim 15 Aralık MÖ 213")
	assert_false(main.player.is_child(), "Oluşturulan yetişkin Mete")
	assert_true(main.player.get_avatar().get_profile().equals(chosen), "Oluşturucunun görünüşüyle")
	var titles: Array = main.gameplay_hud.journal_quests().map(func(q: Dictionary) -> String: return "%s:%s" % [q["title"], q["done"]])
	assert_eq(titles, ["Yola Çıkış:false", "Koyun Sırtında:true"], "Görevler: Yola Çıkış sürüyor, Koyun Sırtında bitti")
	var said: Array[String] = []
	dep.said.connect(func(id: String) -> void: said.append(id))
	Engine.time_scale = 4.0
	main.player.spawn_at(world.marker("hang_spot"), CampNpcs.facing_yaw(world.marker("hang_spot"), world.marker("cradle")))
	await wait_frames(2)
	assert_true(dep.interact(), "Yay beşiğe asılır")
	await _wait_until(func() -> bool: return dep.current_step_id() == "yard", 10.0)
	main.player.spawn_at(world.marker("eskam_talk"), 0.0)
	await _wait_until(func() -> bool: return dep.current_step_id() == "horse", 20.0)
	assert_eq(dep.current_step_id(), "horse", "Eskam'ın sözü ve kapıdaki dört saniye")
	main.player.spawn_at(world.marker("mount_approach"), -PI * 0.5)
	await _wait_until(func() -> bool: return main.player.mount_in_reach() == world.horse, 3.0)
	assert_true(main.player.interact(), "E ile ata binilir")
	# Binince sahne kararmaz: oyuncu atı batı yolunda eşiğe sürer (E20; ayrıntısı test_departure.gd'de). Sınamada atlı çitin önüne konur.
	await _wait_until(func() -> bool: return dep.current_phase() == "ride", 10.0)
	assert_eq(dep.current_phase(), "ride", "Binince sürüş")
	assert_eq(main.flow_stage_id(), "depart", "Köprü 2 binince gelmez")
	main.player.global_position = world.marker("road_gate") + Vector3(6.0, 0.0, 0.0)
	await _wait_until(func() -> bool:
		if dep.current_phase() == "ride" and main.player.is_active():
			main.player.auto_move = _steer_input(main.player, world.marker("road_far"))
			main.player.auto_sprint = true
		return dep.current_phase() != "ride", 20.0)
	assert_eq(dep.current_phase(), "look_back", "Eşikte arkada kalan kampa bakış")
	await _wait_until(func() -> bool: return main.flow_stage_id() == "bridge_2", 20.0)
	Engine.time_scale = 1.0
	var design: Array[String] = []
	for id in said:
		if id in ["yanchi_bow", "eskam_road", "lan_days"]:
			design.append(id)
	assert_eq(design, ["yanchi_bow", "eskam_road", "lan_days"] as Array[String], "Yançi, Eskam, Lan Hatun (%s)" % [said])
	# Seslendirilen yeni sözler (E20/7): dizginde Mete cevap verir, Lan Hatun son sözü söyler; ikisi de sırayla, binerken de sürer.
	assert_true(said.find("mete_count") > said.find("lan_days"), "Mete: «Sayarım.» (%s)" % [said])
	assert_true(said.find("lan_home") > said.find("mete_count"), "Lan Hatun: «Dönüş yolunu da say.» (%s)" % [said])


## Dünya noktasına giden yönün kameraya göre girdisi (W ekranda yukarı; DepartAutoplay._steer gibi).
func _steer_input(player: PlayerController, to: Vector3) -> Vector2:
	var dir := Vector2(to.x - player.global_position.x, to.z - player.global_position.z).normalized()
	var cy := player.camera_yaw()
	var forward := Vector2(-sin(cy), -cos(cy))
	var right := Vector2(cos(cy), -sin(cy))
	return Vector2(dir.dot(right), dir.dot(forward)).limit_length(1.0)


func _new_main(prologue: String) -> Node:
	# childhood_ordos önceden yüklenir ve sınama boyunca tutulur (test_cine_prologue'un nedeni: ilk arka plan yüklemesi çıkışta
	# yükleme belirteçlerini bırakabilir).
	if _warm.is_empty():
		_warm.append(load(ORDOS))
	var main = load(MAIN_SCENE).instantiate()
	main.quit_handler = func() -> void: _quit = true
	main.saves = SaveSystem.new(_dir)
	main.prologue_path = prologue
	# Önsöz'ün oynanan günleri (E21) bu dosyada değil: test_prologue_days.gd.
	main.prologue_days_path = ""
	# Çocukluk'un yeni günleri (E21) de bu dosyada değil: test_childhood_flock.gd (burada yalnız sayım günü).
	main.childhood_days_path = ""
	add_child(main)
	await wait_frames(3)
	main.menu.finish_intro()
	await wait_frames(1)
	return main


func _free_main(main: Node) -> void:
	Engine.time_scale = 1.0
	main.get_viewport().disable_3d = false
	main.queue_free()
	var audio := get_node_or_null(^"/root/AudioManager")
	if audio:
		for p in audio.get_children():
			if p is AudioStreamPlayer:
				(p as AudioStreamPlayer).stop()
				(p as AudioStreamPlayer).stream = null
	await get_tree().create_timer(0.3).timeout


## Kuşlardan Yançi'ninki olmayan, vurulabilir ilki.
func _free_lark(scene: ChildhoodScene, site: ChildhoodSite) -> SmallGame:
	for a: SmallGame in site.game.of_kind("lark"):
		if a != scene.get("_yanchi_bird") and a.is_hittable():
			return a
	return null


func _assert_pause_blocks_saving(main: Node) -> void:
	await _open_pause(main)
	var book: GameMenu = main.pause_menu.get_menu()
	assert_false(book.can_save, "Çocukluk'ta kaydedilmez")
	var general := book.get_page() as GeneralPage
	if general:
		assert_true(general.get_button("save").disabled, "KAYDET kapalı")
		var note := general.find_child("SaveNote", true, false) as Label
		assert_not_null(note, "Nedeni yazılı")
		if note:
			assert_eq(note.text, main.CHILDHOOD_SAVE_NOTE)
	book.open_slots("save")
	await wait_frames(1)
	assert_false(book.has_overlay(), "F5 kayıt yuvalarını açmaz")
	book.close()
	await _wait_until(func() -> bool: return main.state == main.State.PLAYING, 3.0)
	assert_eq(main.state, main.State.PLAYING, "Devam")


func _open_pause(main: Node) -> void:
	main.player.pause_requested.emit()
	await _wait_until(func() -> bool: return main.pause_menu.is_open(), 3.0)
	await wait_frames(2)


func _press_escape(pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.physical_keycode = KEY_ESCAPE
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func _wait_until(condition: Callable, timeout: float) -> void:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame


## Önsöz'ü görülmemiş sayan sahte ayar (oyuncunun ayarına yazılmaz).
class SeenSettings:
	extends Node

	var prologue_seen := false
	var prologue_always := false
	var childhood_done := false
	var saves := 0

	func save_settings() -> bool:
		saves += 1
		return true
