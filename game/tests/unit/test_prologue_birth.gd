extends TestCase
## Önsöz'ün doğum sahnesi (Yol Haritası birth-scene ve hereka-model; story.md §3 satır 7a–8, §4; audio.md §3; godot.md
## §3.6; K68, K89): data/cine/prologue_birth.json, scenes/cine/prologue_birth.tscn (PrologueBirth), CineActor, CineBow,
## CraneFlock, pano 8 (FeltPanel, data/cine/birth_panel.json).
##   - Tahmini satır süreleriyle çizelge (±0,1 sn; aşağıdaki saniyeler eski saatledir, mit uzadığı için MYTH_SHIFT eklenir): doğum 2:50,4–3:36,9, geçiş 3:36,9–3:46,9; 12. satır anlatıcının
##     (3:01,4), Hereka'nın sözü 3:20,0 (hereka; dosyasız altyazı 1 sn), tek kara sessizlik 2,5 sn (3:15,8), ilk ağlama
##     3:18,3, çentik 3:22,0, motif 3:22,5, kart 3:23,0–3:27,0; satır uzayınca sonraki işaretler aynı payla kayar.
##   - Sahne: bütün çekim adları tanınır; içeride 05:50, dışarıda 06:03 sabit ışık örneği, restore bırakır; kişiler kendi
##     Meshy modelleriyle (Teoman, Lan Hatun, sayıcı, 39 yaşındaki Hereka), kendi modeli olmayanlar meta.json'un yer
##     tutucusuyla kurulur (iki Lan kadını: Hun kadınının ağı; kimlik ve düğüm yolu sabit, renk çarpanı yalnız o kişiye,
##     ölçek); sahte glb'de kişinin kendi kimliği; yer tutucunun başlığı metre ölçüsünde; CineBow açıyı uygular, restore sıfırlar;
##     turnalar güneye geçer; gölge ocak taşında durur; pano 8 FeltPanel ile kurulur; ücretsiz varlıklar işaretlidir; sahnenin
##     gösterdiği modeller yükleme listesinde. Oturanların köşeleri döşeğe, ocağa ve astara girmez; Lan Hatun'un eli astara değer.
##   - Eşyalar (E7.6): beşik Meshy modeliyle (uzun ekseni doğu–batı, CRADLE_SIZE'a sığar, tabanı zeminde); kemerdeki yay, sadak
##     ve ipler ondan ayrıldı (cradle_bow): 7e'de ellerden asılı yerine yürür, asılı yeri özgün yeridir; kundak beşikte yatık
##     (≈0,5 m, baş yastıkta, yüz yukarı). Model yoksa (MeshyProp.models_enabled kapalı) kodla çizim ve ücretsiz dokuları.
##   - 7e: Hereka çekim boyunca yerinde durur, kesmede sıçrar; kesmede poz karışmaz; yay gerçek el kemikleriyle gider; hang_bow
##     olayı canlandırmayla eş.
##   - Segment CineHost'ta childhood_ordos dünyasıyla baştan sona oynar (sahte ses hedefiyle, hızlandırılmış), iz bırakmaz.
##   - Kadraj kuralı (K98): her kamera anahtarı konusundan ≥12 m, ay karesi dışında eğim ≥30° ve ufuk yok; 7a 16–20 m, 7b güneş
##     28–34 m, ay ≥40 m (ufuk ve dolunay karede), 7c–7d kapıya ve sayıcıya ≈40 m, 7e 24–28 m, panel_8'de yakınlaşma yok, beşik ortada;
##     7a'da yurdun dış kabuğu ve çatı astarı gizli, duvar astarının dış yüzü çizilmez, sonra hepsi geri gelir; turnaların V'si ve
##     gölgesi beşiğin karesinde.
## Görüntünün ve sesin son onayı kullanıcınındır (göz ve kulak; Karar Bekleyenler).
## Keçe yolu sınanır (K93): CineVideo.enabled kapalıdır, gerçek video dosyası geldiğinde de bu sınamalar keçeyi kurar; video kipi test_cine_video.gd'de.

const SEGMENT := "res://data/cine/prologue_birth.json"
const MYTH := "res://data/cine/prologue_myth.json"
## Mit sineması 131,0 sn'den 163,3 sn'ye uzadı (E13); doğumun göreli zamanları aynıdır.
const MYTH_SHIFT := 32.3
const SCENE := "res://scenes/cine/prologue_birth.tscn"
const WORLD := "res://scenes/maps/childhood_ordos.tscn"
const LIGHT := "res://data/cine/birth_light.json"
const USAGE := "res://assets/_free/usage.jsonl"
const BATCH := "G2-dogum-sahnesi"
const BANK := "ordos"
## Kampın segmenti (story.md §3 satır 0a–0d): Yeni Oyun'dan mit sinemasına 39,4 sn.
const CAMP_LENGTH := 39.4
const TOLERANCE := 0.1
const ACTORS := {"Hereka": "hereka_young", "LanHatun": "lan_hatun", "Teoman": "teoman", "Counter": "counter",
	"LanWomanA": "lan_woman_a", "LanWomanB": "lan_woman_b"}
## Kendi Meshy modeliyle oynayan kişiler (E7.6, E7.9). İki Lan kadınının kendi modeli planlı değildir: Hun kadınının ağı.
const OWN_MODELS: Array[String] = ["hereka_young", "lan_hatun", "teoman", "counter"]
const LAN_WOMEN: Array[String] = ["lan_woman_a", "lan_woman_b"]
const LAN_STAND_IN := "crowd_hun_woman"
const READY_TIMEOUT := 90.0
const TempDir := preload("res://tests/support/temp_dir.gd")
const BOW_RECORD := "res://assets/props/cradle_bow/split.json"
## Beşiğin döşek yüzü (cradle.glb'nin model uzayında, ölçüldü).
const BED_MODEL_Y := -0.075
## Yurdun döşeği (ordos_world.gd FeltBed; yurdun yerel uzayında), astarın yarıçapı (yurdun yarıçapı × LINING_RATIO) ve ücretsiz
## ocağın yarıçapı (1,45 m × FIRE_PIT_SCALE / 2). Oturan kişinin en çok BED_MARGIN girmesine izin vardır: giysinin kıvrımı.
const BED_MIN := Vector3(0.825, 0.0, -1.225)
const BED_MAX := Vector3(1.775, 0.142, 0.625)
const BED_MARGIN := 0.04
const LINING_R := 0.76 * 3.1
const HEARTH_R := 0.616
## Kodla çizimin ücretsiz varlıkları: düğüm → kimlik (model varken bu düğümler kurulmaz).
const DRAWN_MARKS := {"Props/Cradle/Frame": "wood_table_worn", "Props/Cradle/Bedding": "curly_teddy_natural",
	"Props/Cradle/Straps": "leather007", "Props/Swaddle": "fabric044", "Props/CradleBow/Bow": "composite_bow"}

var _trash: Array[Node] = []
var _dirs: PackedStringArray = []


func before_each() -> void:
	Engine.time_scale = 1.0
	MeshyProp.models_enabled = true
	CineVideo.enabled = false


func after_each() -> void:
	MeshyProp.models_enabled = true
	CineVideo.enabled = true
	for node in _trash:
		if is_instance_valid(node):
			if node is CineHost:
				(node as CineHost).stop()
			if node is PrologueBirth:
				(node as PrologueBirth).restore()
			node.queue_free()
	_trash.clear()
	for dir in _dirs:
		_wipe_tree(dir)
	_dirs.clear()
	CineActor.clear_cache()
	Engine.time_scale = 1.0
	get_viewport().disable_3d = false


# --- Zaman çizelgesi ---------------------------------------------------------------------------------

func test_schedule_with_estimates() -> void:
	var seq := _sequence(_est())
	assert_eq(seq.validate(), PackedStringArray(), "Çizelge sorunsuz çözülmeli")
	var seg := seq.segment("birth")
	assert_almost(float(seg["start"]), 170.4 + MYTH_SHIFT, TOLERANCE, "Doğum mit bitince başlar")
	assert_almost(float(seg["end"]), 226.9 + MYTH_SHIFT, TOLERANCE, "Geçiş 56,5 sn sonra biter")
	assert_eq(str(seg["view"]), "main", "Doğum ana 3B'de")
	assert_eq(str(seg["world"]), WORLD, "childhood_ordos dünyasında")
	assert_almost(float(seg["crossfade_in"]), 1.5, 0.001, "Keçe közden gerçek köze 1,5 sn çakışma")
	assert_almost(float(seg["enter"]), 168.9 + MYTH_SHIFT, TOLERANCE, "Sahne doğumdan 1,5 sn önce kurulur (çakışmanın başı)")
	var marks := {"7a": 170.4, "7b": 180.4, "act0.birth.12": 181.4, "7c": 195.8, "silence": 195.8, "7d": 198.3,
		"newborn_cry": 198.3, "act0.birth.hereka": 200.0, "notch": 202.0, "motif": 202.5, "card": 203.0, "7e": 208.9,
		"panel_8": 216.9}
	for mark: String in marks:
		assert_almost(seq.time_of("birth:" + mark), float(marks[mark]) + MYTH_SHIFT, TOLERANCE, "%s story.md §3'teki saniyede" % mark)
	assert_almost(seq.time_of("birth:panel_8") - seq.time_of("birth:7a"), 46.5, TOLERANCE, "Doğum 46,5 sn (2:50,4–3:36,9)")
	assert_almost(float(seg["end"]) - seq.time_of("birth:panel_8"), 10.0, TOLERANCE, "Geçiş 10 sn")
	var card := seq.find("card", "birth")
	assert_almost(float(card["end"]), 207.0 + MYTH_SHIFT, TOLERANCE, "Kart 4 sn")


func test_lines_speakers_and_the_single_black_silence() -> void:
	var seq := _sequence(_est())
	var lines := seq.line_events()
	var ids: Array[String] = []
	for ev in lines:
		if str(ev["segment"]) == "birth":
			ids.append(str(ev["line"]))
	assert_eq(ids, ["act0.birth.12", "act0.birth.hereka"] as Array[String], "12. satır ve Hereka'nın sözü")
	assert_eq(VoLines.speaker("act0.birth.12"), "narrator", "12. satır anlatıcının")
	assert_eq(VoLines.speaker("act0.birth.hereka"), "hereka", "Doğumda konuşan tek kişi Hereka")
	assert_eq(str((VoLines.line("act0.birth.hereka").get("text", {}) as Dictionary).get("en", "")), "One more.")
	assert_eq(VoLines.subtitle("act0.birth.hereka", "tr"), "Bir eklendi.", "Altyazı")
	var hereka := seq.find("act0.birth.hereka", "birth")
	assert_almost(float(hereka["duration"]), 1.0, 0.01, "Hereka'nın sözü (tahmin) 1 sn: dosyasız altyazı 1 sn akar")
	var windows := SubtitleBar.line_windows("act0.birth.hereka", float(hereka["t"]), 1.0, "tr")
	assert_false(windows.is_empty(), "Hereka'nın sözü altyazıyla akar")
	var silences := seq.events_of("black_silence")
	assert_eq(silences.size(), 1, "Önsöz'ün tek kara sessizliği")
	if silences.size() == 1:
		assert_almost(float(silences[0]["dur"]), 2.5, 0.001, "2,5 sn")
		assert_almost(float(silences[0]["t"]), 195.8 + MYTH_SHIFT, TOLERANCE, "7c'de")
	# Kara sessizlikte söz ve efekt yok; ağlama sessizlik biter bitmez.
	for ev in seq.events:
		var t := float(ev["t"])
		var type := str(ev["type"])
		if t > 195.8 + MYTH_SHIFT + 0.001 and t < 198.3 + MYTH_SHIFT - 0.001:
			assert_false(type in ["line", "sfx", "cue", "song"], "Kara sessizlikte ses olayı yok: %s@%.2f" % [type, t])
	var cry := seq.find("newborn_cry", "birth")
	assert_eq(str(cry.get("type", "")), "sfx", "İlk ağlama efekttir (newborn_cry)")


func test_card_reads_the_birth_date() -> void:
	var seq := _sequence(_est())
	var card := seq.find("card", "birth")
	var text: Dictionary = card.get("text", {})
	var light := CineTimeline.read_json(LIGHT)
	var date: Dictionary = light.get("date", {})
	assert_eq(str(text.get("tr", "")), "%s · %s" % [date.get("tr", ""), date.get("place_tr", "")], "Kart «27 Eylül MÖ 234 · Ordos»")
	assert_eq(str(text.get("en", "")), "%s · %s" % [date.get("en", ""), date.get("place_en", "")])
	assert_almost(float(card["dur"]), 4.0, 0.001)


func test_music_states_and_the_long_note() -> void:
	var seq := _sequence(_est())
	var states: Array[String] = []
	var times: Array[float] = []
	for ev in seq.events_of("music"):
		if str(ev["segment"]) != "birth":
			continue
		assert_eq(str(ev.get("bank", "")), BANK, "Doğumun bankası ordos")
		states.append(str(ev["state"]))
		times.append(float(ev["t"]))
	assert_eq(states, ["birth", "birth_motif", "childhood"] as Array[String], "Doğum → motif → Çocukluk")
	assert_almost(times[0], 170.4 + MYTH_SHIFT, TOLERANCE)
	assert_almost(times[1], 202.5 + MYTH_SHIFT, TOLERANCE, "Motifin bütünü çentikten sonra kopuzla")
	assert_almost(times[2], 216.9 + MYTH_SHIFT, TOLERANCE, "childhood geçişte")
	var line_end := seq.time_of("birth:act0.birth.12_end")
	var note_up := {}
	var note_down := {}
	var drone_out := {}
	for ev in seq.events_of("layer"):
		if str(ev["layer"]) == "note" and float(ev["db"]) > -80.0:
			note_up = ev
		elif str(ev["layer"]) == "note":
			note_down = ev
		elif str(ev["layer"]) == "drone" and float(ev["db"]) <= -80.0:
			drone_out = ev
	assert_almost(float(note_up.get("t", -1.0)), line_end, 0.001, "Tek uzun nota satırın ardından")
	assert_almost(float(note_down.get("end", -1.0)) - line_end, 5.0, 0.001, "Nota 5 sn'de söner")
	assert_almost(float(note_down.get("end", -1.0)), seq.time_of("birth:silence"), 0.001, "Nota kara sessizliğe dek söner")
	assert_true(float(drone_out.get("t", -1.0)) >= seq.time_of("birth:silence"), "Dron kara sessizlikte iner (ağlama dronsuz)")
	var bank := MusicBank.load_def(BANK)
	assert_eq(MusicBank.problems(bank), PackedStringArray(), "ordos bankası geçerli")


func test_longer_line_shifts_later_marks() -> void:
	var base := CineTimeline.from_path(SEGMENT, _est())
	var longer := CineTimeline.from_path(SEGMENT, func(id: String) -> float:
		return VoLines.est(id) + (2.0 if id == "act0.birth.12" else 0.0))
	for mark in ["7a", "7b", "act0.birth.12"]:
		assert_almost(longer.time_of("birth:" + mark) - base.time_of("birth:" + mark), 0.0, 0.0001, "%s satırdan önce: kaymaz" % mark)
	for mark in ["7c", "silence", "7d", "newborn_cry", "notch", "motif", "card", "7e", "panel_8"]:
		assert_almost(longer.time_of("birth:" + mark) - base.time_of("birth:" + mark), 2.0, 0.0001, "%s 2 sn kayar" % mark)
	assert_almost(longer.total() - base.total(), 2.0, 0.0001, "Segment de aynı payla uzar")
	var real := CineTimeline.from_path(SEGMENT)
	var shift := VoLines.seconds("act0.birth.12") - VoLines.est("act0.birth.12")
	assert_almost(real.time_of("birth:7c") - base.time_of("birth:7c"), shift, 0.0001, "Gerçek dosyayla 7c kayar")


# --- Sahne -------------------------------------------------------------------------------------------

func test_scene_knows_every_shot() -> void:
	var scene := await _scene()
	var timeline := CineTimeline.from_path(SEGMENT)
	var names: Array[String] = []
	for ev in timeline.events_of("shot"):
		names.append(str(ev["name"]))
	assert_eq(names, PrologueBirth.SHOTS, "Çizelgenin çekimleri sahnenin çekimleri")
	for name in names:
		assert_true(scene.player.has_animation(StringName(name)), "%s çekimi tanınır" % name)
		assert_true(float(scene.shot_lengths[name]) > 0.5, "%s çekiminin süresi var" % name)
	assert_almost(float(scene.shot_starts["7b"]), 10.0, 0.001, "7b segmentin 10. saniyesinde")
	assert_almost(float(scene.shot_lengths["panel_8"]), 10.0, 0.001, "Geçiş 10 sn")
	assert_true(scene.camera.is_current(), "Sahnenin kamerası etkin")
	assert_eq(PrologueBirth.SHOTS.size(), 6)


func test_inside_and_outside_samples() -> void:
	var fake := FakeWorld.new()
	add_child(fake)
	_trash.append(fake)
	var scene := await _scene(fake)
	var rig := fake.rig
	assert_true(rig.is_fixed(), "Sahne kurulunca ışık sabit örnekten gelir")
	assert_eq(str(rig.current_sample().get("id", "")), "inside", "Kurulumda (çakışmanın altında) içerisi")
	assert_almost(float(rig.current_sample().get("minute", 0.0)), 350.0, 0.001, "İçeride 05:50")
	for shot: String in PrologueBirth.SHOTS:
		scene.on_shot(shot, {"t": 0.0})
		var want := "inside" if shot == "7a" else "outside"
		assert_eq(str(rig.current_sample().get("id", "")), want, "%s: %s örneği" % [shot, want])
		if want == "outside":
			assert_almost(float(rig.current_sample().get("minute", 0.0)), 363.0, 0.001, "%s: dışarıda 06:03" % shot)
			var sun: Vector3 = rig.current_sample()["sun_dir"]
			var moon: Vector3 = rig.current_sample()["moon_dir"]
			assert_true(sun.x > 0.9, "Doğuda güneş (%s)" % sun)
			assert_true(moon.x < -0.9, "Batıda dolunay (%s)" % moon)
	scene.restore()
	assert_false(rig.is_fixed(), "restore sabit örneği bırakır")


func test_actors_show_their_own_model_or_the_stand_in() -> void:
	var scene := await _scene()
	for id in OWN_MODELS:
		assert_true(StandIn.has_model(id), "%s kendi modeliyle oynar" % id)
	assert_true(StandIn.has_model(LAN_STAND_IN), "Lan kadınlarının gösterdiği model")
	for id in LAN_WOMEN:
		assert_false(StandIn.has_model(id), "%s: kendi modeli planlı değil" % id)
		assert_eq(StandIn.resolve(id)["model"], LAN_STAND_IN, "%s: Hun kadınının ağı" % id)
	for node_name: String in ACTORS:
		var actor := scene.get_node_or_null(NodePath("Actors/" + node_name)) as CineActor
		assert_not_null(actor, "Actors/%s düğümü" % node_name)
		if actor == null:
			continue
		var id: String = ACTORS[node_name]
		assert_eq(actor.person_id(), id, "%s kimliği sabit" % node_name)
		assert_true(actor.is_built(), "%s kuruldu" % node_name)
		var meta := StandIn.meta(id)
		assert_eq(str(meta.get("node_path", "")), "scenes/cine/prologue_birth.tscn:Actors/%s" % node_name, "%s düğüm yolu meta.json'da" % id)
		assert_eq(str(actor.avatar.get_meta(StandIn.PERSON_META, "")), id, "Avatar kişinin kimliğini taşır")
		assert_true(actor.avatar.has_meshy_model(), "%s: Meshy modeli yüklendi" % id)
		var want_tint := Color.WHITE
		if StandIn.has_model(id):
			assert_false(actor.is_stand_in(), "%s: kendi modeli varken yer tutucu yok" % id)
			assert_eq(actor.model_id(), id, "%s: kendi modeli" % id)
			assert_almost(actor.avatar.model_scale, 1.0, 0.0001, "%s: kendi boyunda" % id)
			assert_null(actor.headwear, "%s: kendi modelinde yer tutucu başlığı yok" % id)
		else:
			var record: Dictionary = meta.get("stand_in", {})
			want_tint = StandIn.parse_tint(record.get("tint"))
			assert_true(actor.is_stand_in(), "%s yer tutucu" % id)
			assert_eq(actor.model_id(), str(record.get("model", "")), "%s: meta.json'un yer tutucusu" % id)
			assert_almost(actor.avatar.model_scale, float(record.get("scale", 1.0)), 0.0001, "%s ölçeği" % id)
			assert_null(actor.headwear, "%s: modelin kendi keçe başlığı: kodla baş örtüsü başı top gibi örter" % id)
		var materials := actor.own_materials()
		assert_false(materials.is_empty(), "%s: kişiye özel malzemeler" % id)
		for mat in materials:
			var base: Color = mat.get_meta(StandIn.BASE_TINT_META, Color.WHITE)
			assert_true((mat.get_shader_parameter("albedo_tint") as Color).is_equal_approx(base * want_tint), "%s: renk çarpanı" % id)
	# İki Lan kadını aynı ağı gösterir: renk çarpanı ve ölçekle ayrılırlar.
	var tints: Array[Color] = []
	for id in LAN_WOMEN:
		tints.append(StandIn.resolve(id)["tint"])
	assert_ne(tints[0], tints[1], "İki kadının renk çarpanı ayrı")
	# Ayakta duranların bekleme klibi kendi modellerindedir (character_fit_tool.gd bağışçıdan aktarır).
	for node_name in ["Teoman", "Counter", "Hereka"]:
		var a := scene.actor(node_name)
		assert_true(a.avatar.available_roles().has(&"idle"), "%s ayakta durabilir (bekleme klibi)" % node_name)


func test_actors_take_their_assigned_clips() -> void:
	# Çeşitlilik (ClipVariety): sahnenin kişileri tek dağıtıcıya sahnedeki sırayla kaydolur; iki Lan kadını aynı ağı gösterir, ayrı oturur.
	var scene := await _scene()
	var woman_a := scene.actor("LanWomanA")
	var woman_b := scene.actor("LanWomanB")
	assert_eq(woman_a.model_id(), woman_b.model_id(), "İki kadın aynı ağı gösterir")
	var seat_a := woman_a.avatar.variety_key(&"sit")
	var seat_b := woman_b.avatar.variety_key(&"sit")
	assert_false(seat_a.is_empty())
	assert_ne(seat_a, seat_b, "Lan kadınları farklı oturur")
	assert_eq(woman_a.avatar.get_animation_player().assigned_animation, ClipVariety.clip_name(seat_a), "Klibi oynar")
	assert_eq(woman_b.avatar.get_animation_player().assigned_animation, ClipVariety.clip_name(seat_b), "Klibi oynar")
	assert_eq(seat_b, PrologueBirth.SEAT_PICKS["LanWomanB"], "İkinci kadının oturuşunu sahne seçer")
	assert_eq(seat_b, "ground_one_knee", "İkinci kadın tek dizini diker")
	assert_true(ClipVariety.library().seat_gap_for(woman_a.model_id(), seat_a) <= ClipVariety.MAX_SEAT_GAP, "Lan kadını zeminde oturur: kalça boşluğu sınırın altında")
	var lan := scene.actor("LanHatun")
	assert_eq(lan.avatar.variety_key(&"sit"), "", "Lan Hatun'un oturuşu kendi klibinde: kolu keregeye o pozda uzanır")
	assert_eq(scene.actor("Hereka").avatar.variety_key(&"sit"), "ground_kneel_heels", "Ebe topukları üstünde diz çöker")
	var teoman := scene.actor("Teoman")
	assert_eq(teoman.avatar.variety_key(&"idle"), "idle_11", "Gururlu duruş")
	assert_eq(teoman.avatar.variety_key(&"walk"), "proud_strut", "Gururlu yürüyüş")
	var lib := ClipVariety.library()
	var seats := {}
	var idles := {}
	for a in scene.actors():
		assert_false(a.avatar.auto_fidget, "%s: sinemada ara hareket yok" % a.name)
		var allocator: ClipVariety.Allocator = a.avatar.variety_allocator
		assert_true(allocator == scene.actors()[0].avatar.variety_allocator, "Tek dağıtıcı")
		if PrologueBirth.INSIDE_ACTORS.has(String(a.name)):
			seats[allocator.key_for(a.person_id(), "sit_ground")] = true
		idles[allocator.key_for(a.person_id(), "idle_loop")] = true
	assert_eq(seats.size(), PrologueBirth.INSIDE_ACTORS.size(), "Yurtta oturan dört kişi dört ayrı oturuş: %s" % [seats.keys()])
	assert_eq(idles.size(), scene.actors().size(), "Altı kişi altı ayrı bekleme: %s" % [idles.keys()])
	# Yürüyen iki kişinin yürüyüşü çekimin hızına yetişir: ayaklar yerde kaymaz.
	for node_name in ["Teoman", "Hereka"]:
		var a := scene.actor(node_name)
		var rate := a.walk_speed / a.avatar.clip_speed(&"walk")
		assert_between(rate, CharacterAvatar.WALK_RATE_RANGE.x, CharacterAvatar.WALK_RATE_RANGE.y, "%s yürüyüşü %.2f m/sn'ye yetişir" % [node_name, a.walk_speed])
	assert_true(lib.variants_in("sit_ground").has(seat_a))


func test_assignment_does_not_change_between_builds() -> void:
	var read := func(scene: PrologueBirth) -> Dictionary:
		var out := {}
		for a in scene.actors():
			for role in [&"idle", &"walk", &"sit"]:
				out["%s/%s" % [a.name, role]] = a.avatar.variety_key(role)
		return out
	var first: Dictionary = read.call(await _scene())
	var second: Dictionary = read.call(await _scene())
	assert_eq(first, second, "Aynı kişi aynı çeşitleri alır")


func test_shots_need_no_retarget_inside_a_frame() -> void:
	# Aktarım kurulumda ve kesmelerde yapılır (IDLE_AT, ensure_idle): çekimlerin içinde klip kurulmaz.
	var scene := await _scene()
	var lib := ClipVariety.library()
	var built := lib._clip_cache.size()
	for shot: String in PrologueBirth.SHOTS:
		scene.on_shot(shot, {"t": 0.0})
		var length := float(scene.shot_lengths[shot])
		for i in 8:
			scene.player.seek(length * i / 7.0, true)
	assert_eq(lib._clip_cache.size(), built, "Bütün çekimler boyunca yeni klip kurulmadı")
	assert_true(scene.actor("Counter").avatar.available_roles().has(&"walk"), "Sayıcının yürüyüşü atanır")
	assert_false(scene.actor("Counter").avatar._built_keys.has(&"walk"), "Hiç yürümediği için kurulmaz: kesme boşuna uzamaz")
	assert_true(scene.actor("Teoman").avatar._built_keys.has(&"walk") and scene.actor("Hereka").avatar._built_keys.has(&"walk"), "Yürüyecekler ısıtılır")


func test_prologue_hereka_is_the_young_model_and_the_old_one_stays_apart() -> void:
	# Önsöz'ün oyuncusu 39 yaşındaki ebedir (E7.9); yaşlı Hereka I. ve IV. Perde'nin temel ağıdır. Konuşmacı kimliği tektir.
	assert_eq(PrologueBirth.ACTORS["Hereka"], "hereka_young", "Sahnenin oyuncusu genç Hereka")
	var young := StandIn.meta("hereka_young")
	var elder := StandIn.meta("hereka")
	assert_eq(int(young.get("age", 0)), 39, "Önsöz'de (MÖ 234) 39 yaşında")
	assert_eq(int(elder.get("age", 0)), 63, "I. Perde'de (MÖ 210) 63 yaşında")
	assert_true(young.has("stand_in"), "Önsöz'ün yer tutucu kaydı genç Hereka'ya taşındı")
	assert_false(elder.has("stand_in"), "Yaşlı Hereka'nın yer tutucusu yok")
	assert_false(elder.has("node_path"), "Yaşlı Hereka Önsöz'ün sahnesinde değil")
	assert_true(str(young.get("concept_image", "")).ends_with("hereka_young.png"), "Kendi konseptinden")
	assert_eq(VoLines.speaker("act0.birth.hereka"), "hereka", "Seslendirme konuşmacı kimliği değişmez")


func test_tint_reaches_only_that_actor() -> void:
	var scene := await _scene()
	var hereka := scene.actor("Hereka")
	var other := CharacterAvatar.new()
	other.model_override = hereka.model_id()
	add_child(other)
	_trash.append(other)
	await wait_frames(1)
	var before: Array[Color] = []
	for mat in StandIn.own_materials(other):
		before.append(mat.get_shader_parameter("albedo_tint"))
	StandIn.apply(hereka.avatar, Color(0.3, 0.5, 0.7), 0.98)
	var after: Array[Color] = []
	for mat in StandIn.own_materials(other):
		after.append(mat.get_shader_parameter("albedo_tint"))
	assert_eq(after, before, "Aynı modeli gösteren başka avatarın malzemeleri değişmez")
	for mat in hereka.own_materials():
		assert_false(StandIn.own_materials(other).has(mat), "Malzemeler paylaşılmaz")


func test_fake_glb_selects_the_own_identity() -> void:
	var root := TempDir.fresh("cine_actor_glb")
	_dirs.append(root)
	_write(root.path_join("hereka/meta.json"), JSON.stringify({"stand_in": {"model": "mother", "tint": "#a8826a", "scale": 0.98}}))
	var a := CineActor.new()
	a.character_id = "hereka"
	a.build_on_ready = false
	a.root = root
	add_child(a)
	_trash.append(a)
	a.build()
	assert_eq(a.model_id(), "mother", "glb yokken yer tutucu")
	assert_true(a.is_stand_in())
	a.queue_free()
	_trash.erase(a)
	_write(root.path_join("hereka/hereka.glb"), "glTF")
	var b := CineActor.new()
	b.character_id = "hereka"
	b.build_on_ready = false
	b.root = root
	add_child(b)
	_trash.append(b)
	b.build()
	assert_eq(b.model_id(), "hereka", "glb gelince kişinin kendi modeli (meshy-final)")
	assert_false(b.is_stand_in())
	assert_eq(b.person_id(), "hereka", "Kimlik aynı")
	assert_null(b.headwear, "Kendi modelinde yer tutucu başlığı yok")


func test_stand_in_hat_is_measured_in_metres() -> void:
	# Meshy iskeleti modelin içinde 0,01 ölçeklidir, başlık kemiğe bağlıdır: ölçüler metre kalsın diye pivot çevirir.
	var root := TempDir.fresh("cine_actor_hat")
	_dirs.append(root)
	_write(root.path_join("hereka/meta.json"), JSON.stringify({"stand_in": {"model": "mother", "tint": "#ffffff", "scale": 1.0,
		"headwear": {"shape": "kerchief", "color": "#d6c9ae", "radius": 0.11, "height": 0.09, "drop": 0.06}}}))
	var a := CineActor.new()
	a.character_id = "hereka"
	a.build_on_ready = false
	a.root = root
	add_child(a)
	_trash.append(a)
	a.build()
	assert_true(a.is_stand_in())
	assert_not_null(a.headwear, "Yer tutucunun başlığı")
	if a.headwear == null:
		return
	var skeleton := a.avatar.get_skeleton()
	assert_almost(CineActor.skeleton_unit(skeleton, a.avatar.get_model_node()), 0.01, 0.0001, "İskeletin model ölçeği")
	await wait_frames(2)
	var pivot := a.headwear.get_node(^"Hat") as Node3D
	assert_almost(pivot.global_transform.basis.get_scale().y, 1.0, 0.001, "Başlık metre ölçüsünde")
	var cover := pivot.get_node(^"Cover") as MeshInstance3D
	var diameter := cover.mesh.get_aabb().size.x * cover.global_transform.basis.get_scale().x
	assert_true(diameter >= 0.18, "Örtünün çapı en az 18 cm: %.1f cm" % (diameter * 100.0))
	var top := skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("head_end")).origin
	assert_true(pivot.global_position.distance_to(top) < 0.15, "Başın tepesinde: %s / %s" % [pivot.global_position, top])


func test_scene_preloads_the_models_it_shows() -> void:
	# Yükleme listesi sahneyle arka planda gelir: gösterilen her model listede, kullanılmayan (kodla çizim yedeği) yok.
	var scene := await _scene()
	var listed := {}
	for res in scene.preloaded:
		listed[res.resource_path] = true
	for a in scene.actors():
		assert_true(listed.has(StandIn.model_path(a.model_id())), "%s: %s yükleme listesinde" % [a.name, a.model_id()])
	for id in [PrologueBirth.CRADLE_MODEL, PrologueBirth.BOW_MODEL, PrologueBirth.SWADDLE_MODEL]:
		assert_true(listed.has(MeshyProp.model_path(PrologueBirth.PROP_FOLDER, id)), "%s yükleme listesinde" % id)
	for id in ["wood_table_worn", "curly_teddy_natural", "leather007", "fabric044"]:
		assert_false(listed.has(PrologueBirth.FREE_TEXTURES[id]), "%s yalnız kodla çizimin yedeği: listede değil" % id)
	assert_false(listed.has(PrologueBirth.FREE_MODELS["composite_bow"]), "composite_bow yalnız kodla çizimin yedeği")
	for path: String in listed:
		assert_true(ResourceLoader.exists(path), "%s dosyası var" % path)


func test_lan_hatun_hand_reaches_the_lining() -> void:
	# 7a'nın «keregeyi tutan el»i: elin en uzak köşesi astara ≤2 cm; astarın içinden de çıkmaz.
	var scene := await _scene()
	var lan := scene.actor("LanHatun")
	var inverse := scene._yurt_transform().affine_inverse()
	scene.on_shot("7a", {"t": 0.0})
	for t: float in [0.0, 4.0, 8.0]:
		scene.player.seek(t, true)
		scene.player.pause()
		var skin := await _skinned(lan)
		var reach := 0.0
		for i in skin.points.size():
			# Parmak köşeleri kendi kemiklerindedir (K92): el, bilek kemiği ve parmaklar.
			if skin.bones[i] == "RightHand" or (skin.bones[i].begins_with("Right") and HandGrip.is_finger_bone(skin.bones[i])):
				var p: Vector3 = inverse * skin.points[i]
				reach = maxf(reach, Vector2(p.x, p.z).length())
		assert_between(reach, LINING_R - 0.02, LINING_R + 0.02, "t=%.1f: elin astara uzaklığı %.3f m" % [t, LINING_R - reach])
	# Diorama (K98, kesme yok): el çekim boyunca kadrajda ve başın yanında görünür (uzaktan, yukarıdan).
	for t: float in [1.0, 5.0, float(scene.shot_lengths["7a"]) - 0.05]:
		scene.player.seek(t, true)
		scene.player.pause()
		var hand := await _hands_mid(lan, "RightHand")
		var head := await _hands_mid(lan, "Head")
		assert_true(scene.camera.is_position_in_frustum(hand), "t=%.1f: el kadrajda: %s" % [t, hand])
		var apart := rad_to_deg((hand - scene.camera.global_position).angle_to(head - scene.camera.global_position))
		assert_true(apart > 1.0, "t=%.1f: el başın yanında görünür: %.2f°" % [t, apart])


func test_seated_people_stay_out_of_the_bedding() -> void:
	# Yerde oturan kişilerin köşeleri döşeğe, ocağa ve astara girmez (oturuş çeşidiyle birlikte ölçülür: çeşit değişirse yer de değişir).
	var scene := await _scene()
	var inverse := scene._yurt_transform().affine_inverse()
	scene.on_shot("7a", {"t": 0.0})
	scene.player.seek(5.0, true)
	scene.player.pause()
	for node_name in ["Hereka", "LanWomanA"]:
		var skin := await _skinned(scene.actor(node_name))
		var deepest := 0.0
		var far := 0.0
		var near := INF
		for world_point: Vector3 in skin.points:
			var p: Vector3 = inverse * world_point
			var r := Vector2(p.x, p.z).length()
			far = maxf(far, r)
			near = minf(near, r)
			if p.y < BED_MAX.y and p.x > BED_MIN.x and p.x < BED_MAX.x and p.z > BED_MIN.z and p.z < BED_MAX.z:
				deepest = maxf(deepest, minf(minf(p.x - BED_MIN.x, BED_MAX.x - p.x), minf(p.z - BED_MIN.z, BED_MAX.z - p.z)))
		assert_true(deepest <= BED_MARGIN, "%s döşeğe en çok %.0f cm girer: %.1f cm" % [node_name, BED_MARGIN * 100.0, deepest * 100.0])
		assert_true(far <= LINING_R, "%s astarın içinde: %.3f m" % [node_name, far])
		assert_true(near >= HEARTH_R, "%s ocağa girmez: %.3f m" % [node_name, near])
	# Döşeğin üstünde oturanların döşeği aşan bacağı katlanmış keçenin üstündedir: 7a'nın kamerası orayı görür, havada kalmaz.
	var fold := AABB(PrologueBirth.BED_FOLD_AT - PrologueBirth.BED_FOLD_SIZE * 0.5, PrologueBirth.BED_FOLD_SIZE)
	assert_almost(fold.position.x, BED_MAX.x, 0.001, "Keçe döşeğin kenarında başlar")
	assert_almost(fold.end.y, BED_MAX.y, 0.005, "Döşekle aynı yükseklikte")
	for node_name in ["LanHatun", "LanWomanB"]:
		var skin := await _skinned(scene.actor(node_name))
		for world_point: Vector3 in skin.points:
			var p: Vector3 = inverse * world_point
			if p.y < 0.3 and p.x > BED_MAX.x and p.z < BED_MAX.z:
				assert_true(p.x <= fold.end.x and p.z >= fold.position.z and p.z <= fold.end.z, "%s: bacak keçenin üstünde: %s" % [node_name, p])
				if p.x > fold.end.x or p.z < fold.position.z or p.z > fold.end.z:
					break
	var fold_node := scene.get_node(^"Props/Kitchen/BedFold") as MeshInstance3D
	assert_vec_almost(inverse * fold_node.global_position, PrologueBirth.BED_FOLD_AT, 0.001, "Keçe yurdun yerel uzayında yerinde")
	# İkinci kadın tek dizini diker: bacakları öne uzanır, Lan Hatun'un bedenine girmez, döşekten taşıp havada kalmaz.
	var woman := await _skinned(scene.actor("LanWomanB"))
	var lan_skin := await _skinned(scene.actor("LanHatun"))
	var near := INF
	for a in range(0, woman.points.size(), 3):
		for b in range(0, lan_skin.points.size(), 7):
			if woman.points[a].distance_squared_to(lan_skin.points[b]) < near:
				near = woman.points[a].distance_squared_to(lan_skin.points[b])
	assert_true(sqrt(near) >= 0.02, "İkinci kadın Lan Hatun'a girmez: %.3f m" % sqrt(near))
	for world_point: Vector3 in woman.points:
		var p: Vector3 = inverse * world_point
		if p.y < 0.3:
			assert_true(p.x >= BED_MIN.x and p.x <= BED_MAX.x and p.z >= BED_MIN.z and p.z <= BED_MAX.z, "İkinci kadının alt bedeni döşekte: %s" % p)
			if p.x < BED_MIN.x or p.x > BED_MAX.x or p.z < BED_MIN.z or p.z > BED_MAX.z:
				break


func test_cine_bow_applies_the_angle_and_restore_resets() -> void:
	var scene := await _scene()
	var teoman := scene.actor("Teoman")
	var skeleton := teoman.avatar.get_skeleton()
	assert_not_null(skeleton)
	if skeleton == null:
		return
	assert_not_null(teoman.bow, "Teoman'ın iskeletinde CineBow")
	var head := skeleton.find_bone("Head")
	var poses := {}
	var record := func() -> void: poses["head"] = skeleton.get_bone_global_pose(head).basis.y.normalized()
	skeleton.skeleton_updated.connect(record)
	teoman.avatar.get_animation_player().pause()
	teoman.bow_amount = 0.0
	await wait_frames(3)
	var rest: Vector3 = poses.get("head", Vector3.ZERO)
	teoman.bow_amount = 1.0
	await wait_frames(3)
	var bowed: Vector3 = poses.get("head", Vector3.ZERO)
	skeleton.skeleton_updated.disconnect(record)
	assert_almost(teoman.bow.applied_deg, CineBow.BOW_DEG, 0.01, "Omurgaya giden toplam açı")
	var angle := rad_to_deg(rest.angle_to(bowed))
	assert_almost(angle, CineBow.BOW_DEG, 2.0, "Baş eğilişin açısı kadar döner (%.1f°)" % angle)
	var axes := CineBow.character_axes(skeleton)
	assert_true(bowed.dot(axes.z) > rest.dot(axes.z), "Öne eğilir (karakterin önü)")
	scene.restore()
	assert_almost(teoman.bow_amount, 0.0, 0.0001, "restore eğilişi sıfırlar")
	assert_almost(teoman.bow.amount, 0.0, 0.0001)


func test_cranes_fly_south_in_a_v() -> void:
	var scene := await _scene()
	var cranes := scene.cranes
	assert_between(float(cranes.count), 8.0, 12.0, "8–12 kuşluk sürü")
	assert_eq(cranes.birds.size(), cranes.count)
	assert_true(cranes.heading().z > 0.95, "Turnalar güneye geçer (%s)" % cranes.heading())
	assert_true(cranes.end_point.z > cranes.start_point.z)
	var spots := CraneFlock.formation(cranes.count, cranes.spacing, cranes.arm_angle_deg)
	for i in range(1, spots.size()):
		assert_true(spots[i].z < 0.0, "V'nin kolları öncünün ardında")
	assert_eq(cranes.calls.size(), 2, "İki ses kaynağı sürüyle birlikte gökte yürür (hareketli kaynak)")
	assert_eq(str(cranes.calls[0].get_meta(&"free_asset", "")), "crane_call_2")
	assert_eq(str(cranes.calls[1].get_meta(&"free_asset", "")), "crane_call_1")
	scene.on_shot("7e", {"t": 0.0})
	scene.player.seek(scene.player.current_animation_length, true)
	var end_z := cranes.global_position.z
	scene.on_shot("7d", {"t": 0.0})
	var start_z := cranes.global_position.z
	assert_true(end_z > start_z + 100.0, "7d'den 7e'nin sonuna güneye yürür (%.0f → %.0f)" % [start_z, end_z])
	assert_true(cranes.visible, "7d'de turnalar gökte")
	cranes.set_sounding(true)
	cranes.play_call()
	cranes.play_call()
	assert_eq(cranes.played.size(), 2)
	assert_ne(cranes.played[0][1], cranes.played[1][1], "Çağrılar iki kayıt arasında sıralanır")
	cranes.set_sounding(false)


func test_shadow_stops_at_the_door_stone() -> void:
	var scene := await _scene()
	scene.on_shot("7a", {"t": 0.0})
	scene.player.seek(PrologueBirth.SHADOW_FROM - 0.5, true)
	var yurt: Vector3 = scene.spots["ember"]
	var early := scene.current_shadow_tip()
	assert_true(Vector2(early.x - yurt.x, early.z - yurt.z).length() > 2.6, "Gölge önce kapının dışında (%.2f m)" % Vector2(early.x - yurt.x, early.z - yurt.z).length())
	scene.player.seek(scene.player.current_animation_length, true)
	var tip := scene.current_shadow_tip()
	var stone := scene.door_stone()
	assert_true(Vector2(tip.x - stone.x, tip.z - stone.z).length() < 0.15, "Gölgenin ucu eşik taşında durur (%s / %s)" % [tip, stone])
	var card := scene.get_node("Props/ShadowCard") as MeshInstance3D
	assert_eq(card.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY, "Kart yalnız gölge verir")
	assert_true((scene.get_node("Props/DoorLight") as SpotLight3D).shadow_enabled, "Kapı ışığı gölgeli")
	assert_eq(PrologueBirth.shadow_tip(Vector3(0, 2, 0), Vector3(1, 1, 0), 0.0), Vector3(2, 0, 0), "shadow_tip (saf)")


func test_panel_8_is_a_felt_panel() -> void:
	var scene := await _scene()
	var panel := scene.panel
	assert_true(panel is FeltPanel, "Pano 8 FeltPanel")
	assert_eq(str(panel.panel.get("id", "")), "panel_8")
	assert_eq(str(panel.panel.get("catalog", "")), "fx_panel_sheep_child", "Varlıklar kataloğunun kimliği")
	for layer_id in ["bow", "sheep", "child", "child_head"]:
		assert_not_null(panel.layer_node(layer_id), "Pano 8'in katmanı: %s" % layer_id)
	assert_true(panel.meshes().size() > 15, "Keçe parçaları (%d)" % panel.meshes().size())
	assert_eq(scene.panel_layer.layer, CineHost.VIEW_LAYER, "Boyalı süzgecin altında (katman 0)")
	var vp := scene.panel_layer.get_node("View/Viewport") as SubViewport
	assert_true(vp.own_world_3d, "Kendi dünyası")
	assert_false(scene.panel_layer.visible, "panel_8'den önce gizli")
	scene.on_shot("panel_8", {"t": 0.0})
	assert_true(scene.panel_layer.visible, "panel_8'de görünür")
	scene.player.seek(scene.player.current_animation_length, true)
	assert_almost((scene.panel_layer.get_node("View") as Control).modulate.a, 1.0, 0.01, "Pano açılır")
	assert_almost(panel.anim_time, float(scene.shot_lengths["panel_8"]), 0.05, "Panonun saati çekimle yürür")


func test_free_assets_are_marked_and_logged() -> void:
	var scene := await _scene()
	var marks := {"Props/Hearth/FirePit": "stone_fire_pit", "Props/Hearth/Stone0": "moon_rock_02",
		"Props/Kitchen/BowlLarge": "wooden_bowl_01", "Props/Kitchen/BowlSmall": "wooden_bowl_02",
		"Props/Kitchen/Plate": "carved_wooden_plate", "Props/Kitchen/Spoon": "wooden_spoon",
		"Props/Mound": "dirt", "Props/TallyStick": "rough_wood", "Cranes/Call": "crane_call_2", "Cranes/CallAlt": "crane_call_1",
		"PanelLayer/View/Viewport/Stage/Panel8": "fabric034", "Sounds/EmberCrackle": "fire_crackling",
		"Sounds/YurtFire": "fireplace_loop", "Sounds/YurtWind": "wind_loop", "Sounds/Sheep": "sheep_baa",
		"Sounds/Lamb": "lamb_baa", "Sounds/Horse": "horse_whinny"}
	var usage := _usage()
	for path: String in marks:
		var node := scene.get_node_or_null(NodePath(path))
		assert_not_null(node, "%s düğümü" % path)
		if node == null:
			continue
		assert_eq(str(node.get_meta(&"free_asset", "")), marks[path], "%s free_asset" % path)
		var used := "scenes/cine/prologue_birth.tscn:%s" % path
		var found := false
		for row: Dictionary in usage:
			if str(row.get("id", "")) == marks[path] and str(row.get("usedIn", "")) == used and str(row.get("batch", "")) == BATCH:
				found = true
		assert_true(found, "usage.jsonl'da %s → %s" % [marks[path], used])
	for path in ["Props/Hearth/FirePit", "Props/Kitchen/BowlLarge"]:
		var asset: String = marks[path]
		assert_true(FileAccess.file_exists("res://assets/_free/model/%s/%s_1k.gltf" % [asset, asset]), "%s _staging'den taşındı" % asset)
	# Ses kaynakları oyuna içe aktarılmaz (bake_music işler): .import'ları skip.
	for src in ["sound/crane_call_1/Grus_grus.ogg", "sound/crane_call_2/Gerves.ogg", "sound/fire_crackling/fire-1.wav",
			"sound/fireplace_loop/fire.wav", "sound/wind_loop/wind1.wav", "sound/lamb_baa/Baa.ogg", "sound/horse_whinny/Whinny.ogg"]:
		var cfg := ConfigFile.new()
		assert_eq(cfg.load("res://assets/_free/%s.import" % src), OK, "%s taşındı" % src)
		assert_eq(str(cfg.get_value("remap", "importer", "")), "skip", "%s içe aktarılmaz (kaynak)" % src)
	var bowl := scene.get_node("Props/Kitchen/BowlLarge") as Node3D
	var tris := 0
	for mi: MeshInstance3D in bowl.find_children("*", "MeshInstance3D", true, false):
		for s in mi.mesh.get_surface_count():
			tris += (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	assert_true(tris <= 8000, "wooden_bowl_01 eşya bütçesinde (≤8k üçgen; sadeleştirildi): %d" % tris)


# --- Eşyalar: beşik, yay, kundak ---------------------------------------------------------------------

func test_cradle_model_replaces_the_drawing() -> void:
	var scene := await _scene()
	var cradle := scene.get_node("Props/Cradle") as Node3D
	var model := cradle.get_node_or_null(^"Model") as MeshyProp
	assert_not_null(model, "Props/Cradle/Model: assets/props/cradle/cradle.glb")
	if model == null:
		return
	assert_true(model.has_model(), "Beşiğin modeli gösterilmeli")
	for drawn in ["Frame", "Bedding", "Straps"]:
		assert_null(cradle.get_node_or_null(NodePath(drawn)), "Model varken kod %s çizmez" % drawn)
	assert_vec_almost(cradle.global_position, scene.spots["Cradle"], 0.001, "Beşik işaretin yerinde")
	var box := model.get_model_aabb()
	assert_almost(box.position.y, 0.0, 0.001, "Tabanı zeminde")
	assert_true(box.size.x <= PrologueBirth.CRADLE_SIZE.x + 0.001, "Boyu CRADLE_SIZE'a sığar (%.3f m)" % box.size.x)
	assert_true(box.size.z <= PrologueBirth.CRADLE_SIZE.z + 0.001, "Derinliği CRADLE_SIZE'a sığar (%.3f m)" % box.size.z)
	assert_true(box.size.x > box.size.z * 1.8, "Uzun ekseni doğu–batı (X): %s" % box.size)
	assert_almost(box.get_center().x, 0.0, 0.001, "Yatayda ortada")
	assert_almost(box.get_center().z, 0.0, 0.001, "Yatayda ortada")
	assert_almost((scene.spots["ArchTop"] as Vector3).y - cradle.global_position.y, box.end.y, 0.001, "Kemerin tepesi modelden ölçülür")


func test_cradle_body_has_no_bow_left_and_the_bow_part_has_only_the_bow() -> void:
	# Yay parçasının kutusu (cradle_bow/split.json): kesimin kaydı ve GLB'lerin kendisi aynı şeyi söyler.
	var record: Variant = JSON.parse_string(FileAccess.get_file_as_string(BOW_RECORD))
	assert_true(record is Dictionary, "Kesimin kaydı okunmalı: %s" % BOW_RECORD)
	if not record is Dictionary:
		return
	var part_box := PrologueBirth.model_bounds(MeshyProp.model_path(PrologueBirth.PROP_FOLDER, PrologueBirth.BOW_MODEL))
	var body_box := PrologueBirth.model_bounds(MeshyProp.model_path(PrologueBirth.PROP_FOLDER, PrologueBirth.CRADLE_MODEL))
	var inside: Dictionary = record["inside"]
	var outside: Dictionary = record["outside"]
	assert_eq(int(inside["connected_groups"]), 1, "Parça tek küme: başıboş üçgen yok")
	assert_eq(int(outside["connected_groups"]), 1, "Gövde tek küme")
	assert_vec_almost(part_box.get_center(), _vec(inside["center"]), 0.0001, "Parçanın ortası kayıttaki gibi")
	assert_vec_almost(part_box.get_center(), PrologueBirth.BOW_SPOT, 0.0001, "BOW_SPOT parçanın ortası")
	assert_vec_almost(body_box.get_center(), _vec(outside["center"]), 0.0001, "Gövdenin ortası kayıttaki gibi")
	assert_true(body_box.encloses(part_box), "Parça gövdenin sınır kutusunun içinde: aynı model uzayı")
	assert_eq(_triangles(PrologueBirth.BOW_MODEL), int(inside["triangles"]), "Parçanın üçgenleri")
	assert_eq(_triangles(PrologueBirth.CRADLE_MODEL), int(outside["triangles"]), "Gövdenin üçgenleri")
	# Yayın kabzası ve sadak kemerin altında, döşeğin üstünde boşlukta asılıdır: gövdede orada üçgen kalmaz.
	for region: AABB in [AABB(Vector3(-0.4, 0.33, -0.3), Vector3(0.45, 0.18, 0.6)), AABB(Vector3(0.14, 0.13, -0.3), Vector3(0.14, 0.3, 0.2))]:
		assert_eq(_faces_in(PrologueBirth.CRADLE_MODEL, region), 0, "Gövdede yay ve sadak kalmaz: %s" % region)
		assert_true(_faces_in(PrologueBirth.BOW_MODEL, region) > 100, "Parça orada: %s" % region)


func test_cradle_bow_is_the_cut_part_and_hangs_at_its_original_place() -> void:
	var scene := await _scene()
	var cradle := scene.get_node("Props/Cradle/Model") as MeshyProp
	var bow := scene.get_node("Props/CradleBow") as Node3D
	var part := bow.get_node_or_null(^"Model") as MeshyProp
	assert_not_null(part, "Props/CradleBow/Model: assets/props/cradle_bow/cradle_bow.glb")
	if part == null:
		return
	assert_true(part.has_model(), "Yayın görüntüsü beşikten ayrılan parça")
	assert_null(bow.get_node_or_null(^"Bow"), "Model varken kod yay çizmez")
	assert_almost(part.get_model_scale(), cradle.get_model_scale(), 0.0001, "Parça gövdeyle aynı ölçekte")
	# Asılı yerinde parçanın her noktası gövdedeki özgün yerine düşer (ikisi aynı model uzayında).
	scene.on_shot("panel_8", {"t": 0.0})
	assert_vec_almost(bow.position, scene.spots["BowHung"]["pos"], 0.001, "panel_8'de yay asılı")
	for p: Vector3 in [PrologueBirth.BOW_SPOT, Vector3(-0.3, 0.4, 0.1), Vector3(0.2, 0.2, -0.2), Vector3(-0.12, 0.66, -0.05)]:
		assert_vec_almost(part.global_transform * part.model_to_local(p), cradle.global_transform * cradle.model_to_local(p), 0.001,
				"%s özgün yerinde" % p)
	# 7e: yay ellerden kemerin kuzeyine, oradan asılı yerine yürür; beşiğin kesmesinden önce görünmez.
	scene.on_shot("7e", {"t": 0.0})
	var cut := minf(3.4, float(scene.shot_lengths["7e"]) * 0.42)
	assert_false(bow.visible, "7e'nin başında yay henüz elde değil")
	scene.player.seek(cut - 0.01, true)
	assert_false(bow.visible, "Gömüde yay görünmez")
	scene.player.seek(cut + 0.01, true)
	assert_true(bow.visible, "Beşiğin kesmesinde yay elinde")
	assert_vec_almost(bow.position, scene.spots["BowHands"]["pos"], 0.001, "Önce ellerde")
	scene.player.seek(cut + PrologueBirth.BOW_APPROACH_AT, true)
	assert_vec_almost(bow.position, scene.spots["BowApproach"]["pos"], 0.001, "Kemerin kuzeyinde")
	assert_true(bow.position.z < cradle.global_position.z - 0.2, "Kemerin içinden geçmez")
	scene.player.seek(cut + PrologueBirth.BOW_HUNG_AT, true)
	assert_vec_almost(bow.position, scene.spots["BowHung"]["pos"], 0.001, "Asılı yerine varır")
	scene.player.seek(scene.player.current_animation_length, true)
	assert_vec_almost(bow.position, scene.spots["BowHung"]["pos"], 0.001, "Asılı kalır")


func test_hereka_stays_put_and_jumps_with_the_camera() -> void:
	var scene := await _scene()
	var hereka := scene.actor("Hereka")
	var length := float(scene.shot_lengths["7e"])
	var cut := minf(3.4, length * 0.42)
	var burial: Dictionary = scene.spots["HerekaBurial"]
	var cradle: Dictionary = scene.spots["HerekaCradle"]
	scene.on_shot("7e", {"t": 0.0})
	for t: float in [0.0, 0.5, 1.5, cut - 0.05, cut - 0.0002]:
		scene.player.seek(t, true)
		assert_true(hereka.global_position.distance_to(burial["pos"]) < 0.05, "t=%.3f: Hereka gömüde kalır (%s)" % [t, hereka.global_position])
		assert_almost(hereka.rotation.y, float(burial["yaw"]), 0.001, "t=%.3f: yönü değişmez" % t)
		assert_eq(hereka.pose, &"sit", "Gömüde diz çöker")
	assert_true(scene.camera.global_position.distance_to(scene.spots["burial_end_cam"]) < 0.05, "Kesmeden önce kamera gömünün karesinde")
	for t: float in [cut + 0.002, cut + 1.0, length - 0.05, length]:
		scene.player.seek(t, true)
		assert_true(hereka.global_position.distance_to(cradle["pos"]) < 0.05, "t=%.3f: Hereka beşiğin başında kalır (%s)" % [t, hereka.global_position])
		assert_almost(hereka.rotation.y, float(cradle["yaw"]), 0.001, "t=%.3f: yönü değişmez" % t)
		assert_eq(hereka.pose, &"sit", "Beşiğin başında diz çöker")
	scene.player.seek(cut + 0.002, true)
	assert_true(scene.camera.global_position.distance_to(scene.spots["cradle_cam"]) < 0.05, "Kesmeden sonra kamera beşiğin karesinde")
	# Göğe bakış yok (K98): Hereka 7e'nin sonuna dek ve panel_8'de beşiğin başında kalır, kamera aynı karede durur.
	scene.player.seek(length, true)
	var end_cam := scene.camera.global_position
	scene.on_shot("panel_8", {"t": 0.0})
	for t: float in [0.0, 1.0, float(scene.shot_lengths["panel_8"])]:
		scene.player.seek(t, true)
		assert_true(hereka.global_position.distance_to(cradle["pos"]) < 0.05, "panel_8 t=%.1f: Hereka beşiğin başında" % t)
		assert_eq(hereka.pose, &"sit")
		assert_vec_almost(scene.camera.global_position, end_cam, 0.001, "panel_8 t=%.1f: kamera 7e'nin son karesinde durur" % t)


func test_bow_travels_in_the_real_hands() -> void:
	# Gerçek el kemikleri (diz çökmüş Hereka'nın; jest ve eğiliş uygulanmış): yay görününce ellerin arasında, asılınca önlerinde.
	# El kemiği bilektir: parmak uçları ≈15 cm ileride, yayın kenarı ortasından ≈11 cm geride; 27 cm'de parmaklar yaya değer.
	var scene := await _scene()
	var hereka := scene.actor("Hereka")
	var bow := scene.get_node("Props/CradleBow") as Node3D
	var cut := minf(3.4, float(scene.shot_lengths["7e"]) * 0.42)
	scene.on_shot("7e", {"t": 0.0})
	for t: float in [cut + 0.01, cut + PrologueBirth.BOW_LIFT_AT, cut + PrologueBirth.BOW_APPROACH_AT, cut + PrologueBirth.BOW_HUNG_AT,
			cut + PrologueBirth.HANDS_DOWN_AT]:
		scene.player.seek(t, true)
		scene.player.pause()
		assert_true(bow.visible, "t=%.2f: yay görünür" % t)
		var hands := await _hands_mid(hereka)
		var gap := hands.distance_to(bow.position)
		assert_true(gap <= 0.27, "t=%.2f: eller yaya %.0f cm (eller %s, yay %s)" % [t, gap * 100.0, hands, bow.position])
	# Dizler beşiğin kuzey yüzünde durur: giysinin eteği en çok birkaç santim girer (kamera güneyden bakar, beşiğin ardında kalır).
	var box := (scene.get_node("Props/Cradle/Model") as MeshyProp).get_model_aabb()
	var inverse := (scene.get_node("Props/Cradle") as Node3D).global_transform.affine_inverse()
	var skin := await _skinned(hereka)
	var deepest := 0.0
	for world_point: Vector3 in skin.points:
		var p: Vector3 = inverse * world_point
		if p.y < 0.2 and absf(p.x) < box.size.x * 0.5 and p.z < box.position.z + box.size.z * 0.5:
			deepest = maxf(deepest, p.z - box.position.z)
	assert_true(deepest <= 0.045, "Dizler beşiğe en çok 4,5 cm girer: %.1f cm" % (deepest * 100.0))


func test_bow_and_mound_events_match_the_animation() -> void:
	var timeline := CineTimeline.from_path(SEGMENT, _est())
	var start := timeline.time_of("birth:7e")
	var length := timeline.time_of("birth:panel_8") - start
	var cut := minf(3.4, length * 0.42)
	var hang := timeline.find("hang_bow", "birth")
	assert_almost(float(hang["t"]) - start, cut + PrologueBirth.BOW_LIFT_AT, 0.01, "hang_bow yay kalkarken başlar")
	assert_almost(float(hang["end"]) - start, cut + PrologueBirth.BOW_HUNG_AT, 0.01, "hang_bow yay asılınca biter")
	var mound := timeline.find("mound", "birth")
	assert_almost(float(mound["t"]) - start, 0.6, 0.01, "Tümsek 0,6'da büyümeye başlar")
	assert_almost(float(mound["end"]) - start, 3.0, 0.01, "Tümsek 3,0'da tamam")


func test_shot_start_shows_the_new_pose_at_once() -> void:
	# Çekimin başı kesmedir: klip karışımı (CharacterAvatar.BLEND_TIME) ekranda görünmez.
	var scene := await _scene()
	var hereka := scene.actor("Hereka")
	scene.on_shot("7d", {"t": 2.0})
	var standing := (await _hands_mid(hereka, "Head")).y
	assert_true(standing > 1.2, "7d'de ayakta (baş %.2f m)" % standing)
	scene.on_shot("7e", {"t": 0.0})
	var kneeling := (await _hands_mid(hereka, "Head")).y
	assert_true(kneeling < 1.0, "7e'nin ilk karelerinde diz çökmüş (baş %.2f m)" % kneeling)


func test_hanging_and_lying_props_have_no_ground_shade() -> void:
	# Malzemenin zemin koyulaşması modelin tabanını zemin sayar: asılı yayda ve yatık kundakta yanlış yere düşerdi.
	var scene := await _scene()
	for path in ["Props/CradleBow/Model", "Props/Swaddle/Model"]:
		var materials := (scene.get_node(NodePath(path)) as MeshyProp).get_materials()
		assert_false(materials.is_empty(), "%s malzemesi" % path)
		for mat in materials:
			assert_almost(float(mat.get_shader_parameter("base_shade_strength")), 0.0, 0.0001, "%s: zemin koyulaşması kapalı" % path)
	for mat in (scene.get_node(^"Props/Cradle/Model") as MeshyProp).get_materials():
		assert_null(mat.get_shader_parameter("base_shade_strength"), "Zemindeki beşikte varsayılan kalır")


func test_swaddle_lies_in_the_cradle_face_up() -> void:
	var scene := await _scene()
	var swaddle := scene.get_node("Props/Swaddle") as Node3D
	var model := swaddle.get_node_or_null(^"Model") as MeshyProp
	assert_not_null(model, "Props/Swaddle/Model: assets/props/swaddled_baby/swaddled_baby.glb")
	if model == null:
		return
	assert_true(model.has_model(), "Kundağın modeli gösterilmeli")
	assert_null(swaddle.get_node_or_null(^"Wrap"), "Model varken kod kundak çizmez")
	assert_between(model.get_model_aabb().size.y, 0.45, 0.52, "Boyu ≈0,5 m")
	# Modelde baş +Y, yüz +Z: yatınca baş batıya (yastık), yüz yukarı; uzun ekseni beşikle aynı.
	var head := model.global_basis.y.normalized()
	var face := model.global_basis.z.normalized()
	assert_true(head.dot(Vector3.LEFT) > 0.98, "Baş batıda, uzun ekseni beşikle aynı: %s" % head)
	assert_true(face.dot(Vector3.UP) > 0.98, "Yüz yukarı: %s" % face)
	assert_true(head.y > 0.0, "Baş ayaklardan yüksekte (yastıkta)")
	# Sınır kutusu beşiğin içinde: ortası düğümün yerinde, döşeğin üstünde, kemerin ve yay parçasının altında.
	var box := model.global_transform * model.get_model_aabb()
	assert_vec_almost(box.get_center(), swaddle.global_position, 0.01, "Kundağın ortası düğümün yerinde")
	var cradle := scene.get_node("Props/Cradle/Model") as MeshyProp
	var outer := cradle.global_transform * cradle.get_model_aabb()
	assert_true(outer.encloses(box), "Kundak beşiğin içinde: %s / %s" % [box, outer])
	# Döşeğin yüzü model uzayında y ≈ −0,075'tir.
	var bed := (cradle.global_transform * cradle.model_to_local(Vector3(0.0, BED_MODEL_Y, 0.0))).y
	assert_between(box.position.y, bed - 0.04, bed + 0.01, "Döşeğe oturur (%.3f, döşek %.3f)" % [box.position.y, bed])
	assert_true(box.size.x > box.size.y * 2.0 and box.size.x > box.size.z * 2.0, "Yatık: uzun kenar X (%s)" % box.size)
	# Kundak beşikle birlikte görünür: 7d'ye dek gizli, 7e ve sonrasında beşikte.
	scene.on_shot("7d", {"t": 0.0})
	assert_false(swaddle.visible, "7d'de bebek henüz beşikte değil")
	scene.on_shot("7e", {"t": 0.0})
	assert_true(swaddle.visible, "7e'de kundak beşikte")


func test_swaddle_lay_is_pure_and_keeps_the_center() -> void:
	var lay := PrologueBirth.swaddle_lay(0.5)
	assert_vec_almost(lay * Vector3(0.0, 0.25, 0.0), Vector3.ZERO, 0.0001, "Ortası düğümün yerinde")
	assert_true(lay.basis.y.dot(Vector3.LEFT) > 0.99, "Baş batıda")
	assert_true(lay.basis.z.dot(Vector3.UP) > 0.99, "Yüz yukarı")
	assert_almost(lay.basis.determinant(), 1.0, 0.0001, "Dönme: ayna yok")


func test_without_models_the_cradle_is_drawn_with_free_textures() -> void:
	MeshyProp.models_enabled = false
	var scene := await _scene()
	for path in ["Props/Cradle/Model", "Props/Swaddle/Model", "Props/CradleBow/Model"]:
		assert_null(scene.get_node_or_null(NodePath(path)), "%s: model yokken kurulmaz" % path)
	assert_not_null(scene.get_node_or_null(^"Props/Cradle/Frame/Arch"), "Kodla kemer")
	assert_not_null(scene.get_node_or_null(^"Props/Swaddle/Wrap"), "Kodla kundak")
	assert_not_null(scene.get_node_or_null(^"Props/CradleBow/Arrow"), "Kodla ok")
	# Kodla yay kemerin 0,2 m altında asılı (modelsiz yerler: eski davranış).
	var arch: Vector3 = scene.spots["ArchTop"]
	assert_vec_almost(scene.spots["BowHung"]["pos"], arch + Vector3(0.0, -0.2, 0.0), 0.001)
	assert_false(scene.spots.has("BowApproach"), "Kodla yay doğrudan ellerden asılır")
	var usage := _usage()
	for path: String in DRAWN_MARKS:
		var node := scene.get_node_or_null(NodePath(path))
		assert_not_null(node, "%s düğümü" % path)
		if node == null:
			continue
		assert_eq(str(node.get_meta(&"free_asset", "")), DRAWN_MARKS[path], "%s free_asset" % path)
		var used := "scenes/cine/prologue_birth.tscn:%s" % path
		var logged := false
		for row: Dictionary in usage:
			if str(row.get("id", "")) == DRAWN_MARKS[path] and str(row.get("usedIn", "")) == used:
				logged = true
		assert_true(logged, "usage.jsonl'da %s → %s" % [DRAWN_MARKS[path], used])


# --- Oynatma ---------------------------------------------------------------------------------------

func test_segment_plays_through_the_host_in_the_world() -> void:
	var fake := FakeAudio.new()
	var host := CineHost.new()
	host.audio = CineAudio.new(fake)
	add_child(host)
	_trash.append(host)
	host.speed = 12.0
	var seen := {}
	host.segment_started.connect(func(seg_id: String) -> void:
		var node := host.scene_node(seg_id)
		seen["is_birth"] = node is PrologueBirth
		seen["ref"] = weakref(node)
		seen["world"] = host.world_node(WORLD) != null)
	var cards := {}
	var fired: Array[String] = []
	var watcher := watch_signal(host.finished)
	host.play(SEGMENT)
	host.runner.fired.connect(func(ev: Dictionary, _seeking: bool) -> void:
		fired.append(str(ev["type"]))
		if str(ev["type"]) == "card":
			cards["text"] = host.card_text())
	await _wait_until(func() -> bool: return watcher.fired, READY_TIMEOUT)
	assert_eq(watcher.last_args, [false], "Segment sonuna dek oynamalı")
	assert_true(bool(seen.get("is_birth", false)), "Segmentin sahnesi prologue_birth.tscn")
	assert_true(bool(seen.get("world", false)), "childhood_ordos dünyası örneklendi")
	var states: Array[String] = []
	for call: Array in fake.calls:
		if call[0] == "set_music_bank":
			assert_eq(call[1], BANK)
			states.append(str(call[2]))
	assert_eq(states, ["birth", "birth_motif", "childhood"] as Array[String])
	var lines: Array[String] = []
	for call: Array in fake.calls:
		if call[0] == "play_line":
			lines.append(str(call[1]))
	assert_eq(lines, ["act0.birth.12", "act0.birth.hereka"] as Array[String], "12. satır ve Hereka")
	assert_eq(fake.count("black_silence"), 1, "Tek kara sessizlik")
	var sfx := {}
	for call: Array in fake.calls:
		if call[0] == "play_sfx":
			sfx[call[1]] = int(sfx.get(call[1], 0)) + 1
	for id in ["newborn_cry", "notch", "breath", "sheep", "horse_neigh", "felt_flap"]:
		assert_true(int(sfx.get(id, 0)) >= 1, "%s çalar" % id)
	var beds := {}
	for call: Array in fake.calls:
		if call[0] == "set_ambience_layer":
			beds[call[1]] = call[2]
	for bed in ["yurt_inside", "ember_crackle", "wind_steppe"]:
		assert_true(beds.has(bed), "%s ortam döngüsü" % bed)
		assert_almost(float(beds.get(bed, 0.0)), -80.0, 0.001, "%s dizi bitince susar" % bed)
	assert_eq(str(cards.get("text", "")).contains("27 Eylül MÖ 234"), true, "Kart gösterildi: %s" % cards.get("text", ""))
	for type in ["cranes", "door_shadow", "mound", "hang_bow"]:
		assert_true(fired.has(type), "%s olayı sahneye gider" % type)
	assert_null(host.world_node(WORLD), "Dizi bitince dünya bırakılır")
	await wait_frames(1)
	var ref: WeakRef = seen.get("ref")
	assert_true(ref != null and ref.get_ref() == null, "Sahne silindi")
	assert_false(get_viewport().disable_3d, "Ana 3B yeniden çizilir")


# --- Yardımcılar ---------------------------------------------------------------------------------

func _sequence(seconds: Callable) -> CineTimeline:
	return CineTimeline.from_dict({"id": "prologue", "segments": [
		{"id": "camp", "world": "none", "length": CAMP_LENGTH, "events": []},
		{"file": MYTH},
		{"file": SEGMENT}]}, seconds)


func _est() -> Callable:
	return func(id: String) -> float: return VoLines.est(id)


## Sahneyi kurar (konaksız; world verilirse ctx'in dünyası), bütün kişileri kurar.
func _scene(world: Node3D = null) -> PrologueBirth:
	var scene := (load(SCENE) as PackedScene).instantiate() as PrologueBirth
	add_child(scene)
	_trash.append(scene)
	scene.setup({"world": world} if world else {})
	scene.build_all()
	await wait_frames(1)
	return scene


## Kemiklerin (varsayılan: iki elin) ortası dünya uzayında, düzeltmeler (CineBow) uygulanmış pozda: iskeletin güncellemesinde okunur.
func _hands_mid(a: CineActor, bone: String = "") -> Vector3:
	var skeleton := a.avatar.get_skeleton()
	var out := {}
	var at := func(bone_name: String) -> Vector3:
		return skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(bone_name)).origin
	var read := func() -> void:
		out["mid"] = at.call(bone) if not bone.is_empty() else (at.call("LeftHand") + at.call("RightHand")) * 0.5
	skeleton.skeleton_updated.connect(read)
	await wait_frames(3)
	skeleton.skeleton_updated.disconnect(read)
	return out.get("mid", Vector3.INF)


## Kişinin ağı dünya uzayında, o anki pozda (CPU'da deri giydirilir, düzeltmeler dahil): points ve her köşenin en ağır kemiği (bones).
func _skinned(a: CineActor) -> SkinnedPoints:
	var out := SkinnedPoints.new()
	var skeleton := a.avatar.get_skeleton()
	var mi := a.avatar.get_model_node().find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	var read := func() -> void:
		if out.points.is_empty():
			out.fill(skeleton, mi)
	skeleton.skeleton_updated.connect(read)
	await wait_frames(3)
	skeleton.skeleton_updated.disconnect(read)
	return out


## Kamera planında t'yi kapsayan aralığın başı (kesme aralıkları atlanır; bulunamazsa boş). Kesmeden sonraki anahtar canlandırmada
## CUT_EPS sonradır: kesmenin anı önceki aralığa, CUT_EPS sonrası sonraki aralığa düşer.
static func _plan_segment(plan: Array, t: float) -> Dictionary:
	for i in plan.size() - 1:
		var a: Dictionary = plan[i]
		var b: Dictionary = plan[i + 1]
		if float(b["t"]) - float(a["t"]) < 0.0001:
			continue
		if t >= float(a["t"]) - 0.00001 and t <= float(b["t"]) + 0.00001:
			return a
	return {}


## Plandaki kesme sayısı (aynı anın iki anahtarı).
static func _cuts(plan: Array) -> int:
	var n := 0
	for i in range(1, plan.size()):
		if absf(float(plan[i]["t"]) - float(plan[i - 1]["t"])) < 0.0001:
			n += 1
	return n


## Noktanın karede soldan oranı (16:9; dikey görüş vfov_deg).
static func _screen_x(xform: Transform3D, vfov_deg: float, point: Vector3) -> float:
	var local := xform.affine_inverse() * point
	return 0.5 + (local.x / -local.z) / (tan(deg_to_rad(vfov_deg) * 0.5) * 16.0 / 9.0) * 0.5


## Dizideki üç sayı.
static func _vec(values: Array) -> Vector3:
	return Vector3(float(values[0]), float(values[1]), float(values[2]))


## Modelin ağı (model uzayında).
static func _mesh_of(id: String) -> Mesh:
	var root := (load(MeshyProp.model_path(PrologueBirth.PROP_FOLDER, id)) as PackedScene).instantiate()
	var mesh: Mesh = (root.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh
	root.free()
	return mesh


static func _triangles(id: String) -> int:
	return _mesh_of(id).get_faces().size() / 3


## Modelin ağırlık merkezi kutuda olan üçgenleri.
static func _faces_in(id: String, region: AABB) -> int:
	var faces := _mesh_of(id).get_faces()
	var count := 0
	for i in range(0, faces.size(), 3):
		if region.has_point((faces[i] + faces[i + 1] + faces[i + 2]) / 3.0):
			count += 1
	return count


func _usage() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not FileAccess.file_exists(USAGE):
		return out
	for line in FileAccess.get_file_as_string(USAGE).split("\n", false):
		var parsed: Variant = JSON.parse_string(line)
		if parsed is Dictionary:
			out.append(parsed)
	return out


func _wait_until(condition: Callable, timeout: float) -> void:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame


func _write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)


func _wipe_tree(dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for sub in DirAccess.get_directories_at(dir):
		_wipe_tree(dir.path_join(sub))
	for file in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(file))
	DirAccess.remove_absolute(dir)



## Deri giydirilmiş köşeler (_skinned).
class SkinnedPoints:
	extends RefCounted

	var points := PackedVector3Array()
	var bones := PackedStringArray()

	func fill(skeleton: Skeleton3D, mi: MeshInstance3D) -> void:
		var arrays := mi.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bone_ids: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var stride := bone_ids.size() / verts.size()
		var matrices: Array[Transform3D] = []
		var names := PackedStringArray()
		var skin := mi.skin
		for i in skin.get_bind_count():
			var bone := skin.get_bind_bone(i)
			if bone < 0:
				bone = skeleton.find_bone(skin.get_bind_name(i))
			matrices.append(skeleton.global_transform * skeleton.get_bone_global_pose(bone) * skin.get_bind_pose(i))
			names.append(skeleton.get_bone_name(bone))
		points.resize(verts.size())
		bones.resize(verts.size())
		for v in verts.size():
			var base := v * stride
			var heaviest := 0
			var p := Vector3.ZERO
			for k in stride:
				var w := weights[base + k]
				if w > weights[base + heaviest]:
					heaviest = k
				if w > 0.0:
					p += (matrices[bone_ids[base + k]] * verts[v]) * w
			points[v] = p
			bones[v] = names[bone_ids[base + heaviest]]


## Işığın sahte dünyası: SkyRig, güneş ışığı ve ortam (sabit örneği yazar), yerler düzen dosyasından.
class FakeWorld:
	extends Node3D

	var rig: SkyRig
	## Lan Hatun'un yurdunun sahtesi (düzen dosyasının yerinde, kapı doğuda): dış kabuk, astarın çatısı ve kerege malzemeli duvarı.
	var with_yurt := false
	var yurt: Node3D

	func _ready() -> void:
		var light := DirectionalLight3D.new()
		light.name = "SunLight"
		add_child(light)
		var env := WorldEnvironment.new()
		env.name = "WorldEnvironment"
		env.environment = Environment.new()
		add_child(env)
		rig = SkyRig.new()
		rig.name = "SkyRig"
		add_child(rig)
		if with_yurt:
			yurt = Node3D.new()
			yurt.name = "LanYurt"
			yurt.transform = Transform3D(OrdosWorld.door_basis(90.0), Vector3.ZERO)
			add_child(yurt)
			var model := Node3D.new()
			model.name = "YurtModel"
			yurt.add_child(model)
			var smoke := MeshInstance3D.new()
			smoke.name = "Smoke"
			yurt.add_child(smoke)
			var lining := Node3D.new()
			lining.name = "Lining"
			yurt.add_child(lining)
			var roof := MeshInstance3D.new()
			roof.name = "Roof"
			lining.add_child(roof)
			var wall := MeshInstance3D.new()
			wall.name = "Wall"
			var mat := ShaderMaterial.new()
			mat.shader = load("res://shaders/kerege.gdshader")
			wall.material_override = mat
			lining.add_child(wall)

	func get_sky_rig() -> SkyRig:
		return rig

	func place(id: String) -> Node3D:
		return yurt if id == "lan_yurt" else null


## AudioManager'ın sözleşmesini taklit eder; çağrıları sırayla kaydeder.
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

	func play_song(id: String) -> void:
		calls.append(["play_song", id])

	func play_line(id: String, opts: Dictionary = {}) -> float:
		calls.append(["play_line", id, opts])
		return VoLines.seconds(id)

	func stop_line(fade: float = 0.3) -> void:
		calls.append(["stop_line", fade])

	func play_sfx(id: String, opts: Dictionary = {}) -> void:
		calls.append(["play_sfx", id, opts])

	func request_lines(ids: PackedStringArray) -> void:
		calls.append(["request_lines", ids])

	func release_lines(ids: PackedStringArray) -> void:
		calls.append(["release_lines", ids])

	func song_position(_id: String = "") -> float:
		return -1.0

	func names() -> PackedStringArray:
		var out := PackedStringArray()
		for call: Array in calls:
			out.append(call[0])
		return out

	func count(name: String) -> int:
		return Array(names()).count(name)


## 7a diorama gibi yukarıdan görünür (K98): yurdun dış kabuğu, çatı astarı ve tündüğün dumanı (çatı yokken havada asılı kalırdı) gizli, duvar
## astarının dış yüzü çizilmez (kerege.gdshader hide_back), kapı ışığının maskesi ve içerinin ılık dolgusu görünür, kapının dışındaki beşik
## (şafak öncesi ışıkta kara bir leke) görünmez; 7b ve sonrasında ve restore'da hepsi geri gelir.
func test_roof_hides_in_7a_and_comes_back() -> void:
	var fake := FakeWorld.new()
	fake.with_yurt = true
	add_child(fake)
	_trash.append(fake)
	var scene := await _scene(fake)
	var yurt := fake.place("lan_yurt")
	var model := yurt.get_node(^"YurtModel") as Node3D
	var roof := yurt.get_node(^"Lining/Roof") as Node3D
	var mat := (yurt.get_node(^"Lining/Wall") as GeometryInstance3D).material_override as ShaderMaterial
	var mask := scene.get_node(^"Props/DoorMask") as GeometryInstance3D
	var smoke := yurt.get_node(^"Smoke") as Node3D
	var cradle := scene.get_node(^"Props/Cradle") as Node3D
	var fill := scene.get_node(^"Props/InteriorFill") as OmniLight3D
	assert_false(fill.shadow_enabled, "İçerinin dolgusu gölgesiz")
	assert_true(fill.omni_range <= 3.1 * 1.1, "Dolgu yurdun içinde biter (%.1f m)" % fill.omni_range)
	assert_true(mat.shader.code.contains("uniform bool hide_back"), "kerege.gdshader dış yüzü gizleyebilir")
	assert_eq(mask.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY, "Kapının maskesi yalnız gölge verir")
	var check := func(inside: bool, label: String) -> void:
		assert_eq(scene.diorama, inside, "%s: diorama" % label)
		assert_eq(model.visible, not inside, "%s: dış kabuk" % label)
		assert_eq(roof.visible, not inside, "%s: çatı astarı" % label)
		assert_eq(bool(mat.get_shader_parameter(PrologueBirth.HIDE_BACK_PARAM)), inside, "%s: duvarın dış yüzü" % label)
		assert_eq(mask.visible, inside, "%s: kapının maskesi" % label)
		assert_eq(smoke.visible, not inside, "%s: tündüğün dumanı" % label)
		assert_eq(fill.visible, inside, "%s: içerinin dolgusu" % label)
		assert_eq(cradle.visible, not inside, "%s: beşik" % label)
	check.call(true, "kurulum (7a'nın ilk karesi)")
	for shot: String in ["7b", "7c", "7d", "7e", "panel_8"]:
		scene.on_shot(shot, {"t": 0.0})
		check.call(false, shot)
	scene.on_shot("7a", {"t": 0.0})
	check.call(true, "7a yeniden")
	scene.restore()
	assert_false(scene.diorama, "restore dioramayı kapatır")
	assert_true(model.visible and roof.visible and smoke.visible, "restore kabuğu, çatıyı ve dumanı geri getirir")
	assert_false(bool(mat.get_shader_parameter(PrologueBirth.HIDE_BACK_PARAM)), "restore duvarın dış yüzünü geri getirir")


## K98 (kullanıcının sözü; docs/media/review/kadraj_referans.webp): görev ve sinema çekimleri uzak ve yüksek açılıdır. Her kamera anahtarı
## (canlandırmanın her anahtarı) konusundan ≥12 m; ufuk istisnası (7b'nin ay karesi) dışında eğim ≥30°, ufuk karede değil, görüş 30–40°.
func test_every_camera_key_keeps_the_far_rule() -> void:
	var scene := await _scene()
	for shot: String in PrologueBirth.SHOTS:
		var plan: Array = scene.camera_plan.get(shot, [])
		assert_true(plan.size() >= 2, "%s: kamera planı" % shot)
		var anim := scene.player.get_animation(StringName(shot))
		var pos_track := anim.find_track(^"Camera:position", Animation.TYPE_VALUE)
		var rot_track := anim.find_track(^"Camera:quaternion", Animation.TYPE_VALUE)
		var fov_track := anim.find_track(^"Camera:fov", Animation.TYPE_VALUE)
		var checked := 0
		for k in anim.track_get_key_count(pos_track):
			var tk := anim.track_get_key_time(pos_track, k)
			var seg := _plan_segment(plan, tk)
			if seg.is_empty():
				continue
			checked += 1
			var pos: Vector3 = anim.track_get_key_value(pos_track, k)
			var basis := Basis(anim.value_track_interpolate(rot_track, tk) as Quaternion)
			var fov := float(anim.value_track_interpolate(fov_track, tk))
			var subject: Vector3 = seg["subject"]
			assert_true(pos.distance_to(subject) >= PrologueBirth.MIN_SUBJECT_DISTANCE,
				"%s t=%.2f: konuya %.1f m (≥%.0f)" % [shot, tk, pos.distance_to(subject), PrologueBirth.MIN_SUBJECT_DISTANCE])
			assert_between(fov, 30.0, 40.0, "%s t=%.2f: görüş" % [shot, tk])
			var xform := Transform3D(basis, pos)
			if bool(seg["horizon"]):
				continue
			var pitch := rad_to_deg(asin(basis.z.y))
			assert_true(pitch >= PrologueBirth.MIN_PITCH_DEG, "%s t=%.2f: eğim %.1f° (≥%.0f)" % [shot, tk, pitch, PrologueBirth.MIN_PITCH_DEG])
			assert_true(MenuCamera.horizon_y(xform, fov) < 0.0, "%s t=%.2f: ufuk karede değil" % [shot, tk])
		assert_true(checked >= 2, "%s: anahtarlar sınandı (%d)" % [shot, checked])


## Çekim başına uzaklıklar (K98'in görevdeki sayıları): 7a 16–20 m (tek çekim, kesme yok), 7b güneş 28–34 m, ay ≥40 m ve ufukla dolunay
## karede, 7c–7d kapıya ve sayıcıya ≈40 m, 7e 24–28 m (tek kesme), panel_8'de kamera durur ve beşik ortadadır.
func test_shot_distances_follow_the_brief() -> void:
	var scene := await _scene()
	var plan: Dictionary = scene.camera_plan
	for key: Dictionary in plan["7a"]:
		assert_between((key["pos"] as Vector3).distance_to(scene.spots["ember"]), 16.0, 20.0, "7a: köze 16–20 m")
	assert_eq(_cuts(plan["7a"]), 0, "7a tek çekim, kesme yok")
	var teoman: Vector3 = scene.spots["TeomanEnd"]["pos"]
	var moon_dir: Vector3 = (scene.samples()["outside"] as Dictionary)["moon_dir"]
	var moons := 0
	for key: Dictionary in plan["7b"]:
		var d := (key["pos"] as Vector3).distance_to(teoman)
		if bool(key["horizon"]):
			moons += 1
			assert_true(d >= 40.0, "7b ay karesi: Teoman'a ≥40 m (%.1f)" % d)
			var xform := Transform3D(Basis.looking_at((key["look"] as Vector3) - (key["pos"] as Vector3), Vector3.UP), key["pos"])
			var horizon := MenuCamera.horizon_y(xform, float(key["fov"]))
			assert_between(horizon, 0.1, 0.5, "7b ay karesi: ufuk karede (%.2f)" % horizon)
			var moon_y := MenuCamera.screen_y(xform, float(key["fov"]), (key["pos"] as Vector3) + moon_dir * 1000.0)
			assert_between(moon_y, 0.05, horizon, "7b ay karesi: dolunay ufkun üstünde, karede (%.2f)" % moon_y)
		else:
			assert_between(d, 28.0, 34.0, "7b güneş: Teoman'a 28–34 m (%.1f)" % d)
	assert_eq(moons, 2, "7b'nin ikinci yarısı ay karesi")
	for shot in ["7c", "7d"]:
		for key: Dictionary in plan[shot]:
			for spot in ["HerekaDoorOut", "Counter"]:
				var d := (key["pos"] as Vector3).distance_to(scene.spots[spot]["pos"])
				assert_between(d, 36.0, 44.0, "%s: %s'a ≈40 m (%.1f)" % [shot, spot, d])
		assert_eq(_cuts(plan[shot]), 0, "%s: kesme yok" % shot)
	assert_vec_almost(plan["7c"][1]["pos"], plan["7d"][0]["pos"], 0.001, "7c'den 7d'ye aynı kare (kesme yok)")
	for key: Dictionary in plan["7e"]:
		assert_between((key["pos"] as Vector3).distance_to(key["subject"]), 24.0, 28.0, "7e: 24–28 m")
	assert_eq(_cuts(plan["7e"]), 1, "7e'de tek kesme (Hereka'nın yer değiştirmesi)")
	var panel: Array = plan["panel_8"]
	assert_vec_almost(panel[0]["pos"], panel[panel.size() - 1]["pos"], 0.0001, "panel_8: yakınlaşma yok, kamera durur")
	assert_vec_almost(panel[0]["pos"], plan["7e"][plan["7e"].size() - 1]["pos"], 0.0001, "panel_8 7e'nin son karesinden açılır")
	var cradle_x := Transform3D(Basis.looking_at((panel[0]["look"] as Vector3) - (panel[0]["pos"] as Vector3), Vector3.UP), panel[0]["pos"])
	var at := Vector2(_screen_x(cradle_x, float(panel[0]["fov"]), scene.spots["Cradle"]), MenuCamera.screen_y(cradle_x, float(panel[0]["fov"]), scene.spots["Cradle"]))
	assert_true(at.distance_to(Vector2(0.5, 0.5)) < 0.1, "panel_8: beşik karenin ortasına yakın %s" % at)
	# Kişi uzaktan okunur: ayakta kişi (1,7 m) uzak karede karenin ≥%5,5'i.
	var line: Dictionary = plan["7d"][0]
	var lx := Transform3D(Basis.looking_at((line["look"] as Vector3) - (line["pos"] as Vector3), Vector3.UP), line["pos"])
	for spot in ["HerekaDoorOut", "Counter"]:
		var p: Vector3 = scene.spots[spot]["pos"]
		var h := MenuCamera.screen_y(lx, float(line["fov"]), p) - MenuCamera.screen_y(lx, float(line["fov"]), p + Vector3(0.0, 1.7, 0.0))
		assert_true(h >= 0.055, "7d: %s karenin %.1f%%'i" % [spot, h * 100.0])


## Turnaların V'si 7e'de beşiğin karesinin içinden geçer, gölgeleri (alçak güneş) de karededir; kuşlar gölge verir.
func test_crane_v_and_its_shadow_cross_the_cradle_frame() -> void:
	var scene := await _scene()
	var cranes := scene.cranes
	assert_true(cranes.ground_shadows, "Turnaların zeminde gölge izi var")
	assert_eq(cranes.shadows.size(), cranes.birds.size(), "Her kuşa bir iz")
	assert_true(cranes.call_peak_db <= PrologueBirth.CRANE_PEAK_DB + 0.001, "Çağrı eski yolun en yüksek düzeyini aşmaz")
	for p: AudioStreamPlayer3D in cranes.calls:
		assert_almost(p.max_db, PrologueBirth.CRANE_PEAK_DB, 0.001, "%s en çok %.0f dB" % [p.name, PrologueBirth.CRANE_PEAK_DB])
		assert_almost(p.unit_size, PrologueBirth.CRANE_UNIT_SIZE, 0.001, "%s kısılmanın birim uzaklığı" % p.name)
	var light: Vector3 = ((scene.samples()["outside"] as Dictionary)["light_dir"] as Vector3).normalized()
	assert_true(cranes.shadow_dir.normalized().is_equal_approx(-light), "İz dışarının ışığının tersine düşer")
	scene.on_shot("7e", {"t": 0.0})
	var length := float(scene.shot_lengths["7e"])
	var seen := 0
	for t: float in [PrologueBirth.CRANE_PASS - 0.6, PrologueBirth.CRANE_PASS, PrologueBirth.CRANE_PASS + 0.6]:
		scene.player.seek(minf(t, length), true)
		var cam := scene.camera
		for i in cranes.birds.size():
			var p := cranes.birds[i].global_position
			var mark := cranes.shadows[i].global_position
			assert_vec_almost(mark, CraneFlock.shadow_point(p, cranes.shadow_dir.normalized(), cranes.ground_y), 0.001, "İz kuşun gölgesinin yerinde")
			assert_almost(mark.y, float(scene.spots["Cradle"].y), 0.001, "İz zeminde")
			if cam.is_position_in_frustum(p) and cam.is_position_in_frustum(mark):
				seen += 1
		assert_true(cranes.visible, "t=%.1f: turnalar görünür" % t)
	assert_true(seen >= 12, "V'nin kuşları ve gölgeleri beşiğin karesinde (%d kuş-an)" % seen)
	# Kuşlar yurdun ve kişilerin üstünden geçmez: V'nin başı beşiğin doğusundadır, gölgesi yurdun kendi gölgesine düşmez.
	var pass_point: Vector3 = scene.spots["crane_pass"]
	assert_true(pass_point.x > float(scene.spots["Cradle"].x) + 5.0, "V beşiğin doğusundan geçer")


## Gölgenin bedeli çekime göre: içeride yönlü ışık gölgesizdir, dışarıda içerideki kişiler gölge çizmez (K63).
func test_inside_light_sample_has_no_directional_shadow() -> void:
	var samples := SkyRig.load_samples(PrologueBirth.LIGHT_PATH)
	assert_false(bool((samples["inside"] as Dictionary).get("light_shadow", true)), "İçeride yönlü gölge basamakları çizilmez")
	assert_true(bool((samples["outside"] as Dictionary).get("light_shadow", false)), "Dışarıda gölge vardır")



## Doğumun bozkırı (MÖ 234 ile MÖ 228 aynı otlak) kadrajı örtmez (K98): kaya ve çalı kişilerin, beşiğin, gömünün ve sayım hattının yanında
## durmaz; her kamera anahtarından çekimin kişilerine bakış ne kayaya ne çalıya ne de kademeye değer; yükselti kişilerin yerini oynatmaz.
## Doğumun dünyasında Çocukluk'a özgü düğüm yoktur. 7a'da kaya ve çalı gölge vermez (yönlü gölge yok; köz ve kapı ışığının geçişine bütün
## harita girerdi), dışarıda verir, restore eski hâline döndürür.
func test_the_steppe_keeps_out_of_the_people_and_the_frames() -> void:
	var world := await _world()
	if world == null:
		return
	var casters: Array[GeometryInstance3D] = []
	var before := {}
	for path in ["Ground/Rocks", "Ground/Shrubs"]:
		for gi: Node in world.get_node(NodePath(path)).get_children():
			casters.append(gi as GeometryInstance3D)
			before[gi] = (gi as GeometryInstance3D).cast_shadow
	var scene := await _scene(world)
	for gi in casters:
		assert_eq(gi.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "7a: %s gölge vermez" % gi.name)
	scene.on_shot("7b", {"t": 0.0})
	for gi in casters:
		assert_eq(gi.cast_shadow, before[gi], "7b: %s gölgesi eski hâlinde" % gi.name)
	assert_true(casters.any(func(gi: GeometryInstance3D) -> bool: return gi.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF), "Dışarıda kayalar gölge verir")
	scene.on_shot("7a", {"t": 0.0})
	scene.restore()
	for gi in casters:
		assert_eq(gi.cast_shadow, before[gi], "restore: %s gölgesi eski hâlinde" % gi.name)
	var shape: OrdosGround = world.get_terrain_shape()
	assert_eq(shape, world.steppe, "Kişiler bozkırın yüzünde")
	assert_null(world.get_node_or_null(^"Childhood"), "Doğumda Çocukluk'un düğümü yok")
	# Kaya ve çalının küreleri: merkez (zeminden yükseltilmiş) ve yarıçap (MultiMesh örneğinin ölçeğinden).
	var blobs: Array[Vector4] = []
	for group in ["Ground/Rocks", "Ground/Shrubs"]:
		for mmi: Node in world.get_node(NodePath(group)).get_children():
			var mm := (mmi as MultiMeshInstance3D).multimesh
			for i in mm.instance_count:
				var t := mm.get_instance_transform(i)
				var k := t.basis.x.length()
				blobs.append(Vector4(t.origin.x, t.origin.y + k * 0.4, t.origin.z, k * 0.6))
	assert_true(blobs.size() > 400, "Kaya ve çalı kurulur (%d)" % blobs.size())
	var points := {}
	for id: String in ["HerekaDoorIn", "HerekaDoorOut", "HerekaBurial", "HerekaCradle", "TeomanStart", "TeomanEnd", "Counter"]:
		points[id] = (scene.spots[id] as Dictionary)["pos"]
	points["Cradle"] = scene.spots["Cradle"]
	points["Mound"] = scene.spots["Mound"]
	for id: String in points:
		var p: Vector3 = points[id]
		assert_almost(p.y, world.ground.height_at(p.x, p.z), 0.005, "%s: yükselti yerini oynatmaz" % id)
	var line: Dictionary = world.layout["counting_line"]
	var a := OrdosGround._vec2(line["from"])
	var b := OrdosGround._vec2(line["to"])
	for blob in blobs:
		var q := Vector2(blob.x, blob.z)
		for id: String in points:
			var p: Vector3 = points[id]
			assert_true(q.distance_to(Vector2(p.x, p.z)) > 1.0 + blob.w, "%s'in yanında kaya ya da çalı (%s)" % [id, q])
		assert_true(Geometry2D.get_closest_point_to_segment(q, a, b).distance_to(q) > 1.0 + blob.w, "Sayım hattında kaya ya da çalı (%s)" % q)
		if failures.size() > 4:
			return
	# Bakışlar: kameranın her anahtarından çekimin kişilerine (beline; beşiğe ve tümseğe üstüne) doğru.
	var targets := {"7b": ["TeomanStart", "TeomanEnd"], "7c": ["HerekaDoorOut", "Counter"], "7d": ["HerekaDoorIn", "HerekaDoorOut", "Counter"],
		"7e": ["HerekaBurial", "Mound", "HerekaCradle", "Cradle"], "panel_8": ["HerekaCradle", "Cradle"]}
	var checked := 0
	for shot: String in targets:
		for key: Dictionary in scene.camera_plan[shot]:
			var from: Vector3 = key["pos"]
			for id: String in targets[shot]:
				var to: Vector3 = (points[id] as Vector3) + Vector3(0.0, 0.3 if id in ["Cradle", "Mound"] else 0.8, 0.0)
				checked += 1
				for blob in blobs:
					var c := Vector3(blob.x, blob.y, blob.z)
					var near := Geometry3D.get_closest_point_to_segment(c, from, to)
					assert_true(near.distance_to(c) > blob.w, "%s t=%.1f: %s'e bakışı kaya ya da çalı örtüyor (%s)" % [shot, float(key["t"]), id, c])
				var length := from.distance_to(to)
				var steps := int(length / 0.5)
				for s in range(1, steps - 1):
					var p := from.lerp(to, float(s) / float(steps))
					assert_true(p.y > shape.height_at(p.x, p.z) + 0.05, "%s t=%.1f: %s'e bakışı zemin örtüyor (%s)" % [shot, float(key["t"]), id, p])
					if failures.size() > 4:
						return
	assert_true(checked > 20, "Bakışlar sınandı (%d)" % checked)


## Gerçek dünya (childhood_ordos): örneklenir, hazır olana dek beklenir; sınamanın sonunda bırakılır.
func _world() -> OrdosWorld:
	var world := (load(WORLD) as PackedScene).instantiate() as OrdosWorld
	add_child(world)
	_trash.append(world)
	await _wait_until(func() -> bool: return world.is_ready(), READY_TIMEOUT)
	if not world.is_ready():
		fail("Dünya hazır olmadı")
		return null
	return world
