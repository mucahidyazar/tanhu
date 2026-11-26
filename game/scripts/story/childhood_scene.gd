class_name ChildhoodScene
extends Node
## Çocukluk «Koyun Sırtında» (mq0_sheep; K36, K37, K67, K98, K99; story.md §5, docs-app story/childhood): beş yaşındaki Mete Ordos'ta
## koyuna biner, oyuncak yayla iki tarla kuşu (isterse bir fare) vurur ve sayıma girer. Veri data/story/childhood/scene.json'dadır;
## adımlar dosyadaki sırayla akar, her adımın kind'ı burada bir işleyicidir. Görev ve diyalog sistemleri (act-1-p3) gelince adımlar
## onların hedeflerine, satırlar diyalog verisine taşınır; o güne dek bu küçük yönetici yeter.
##   reach  wake:  Lan Hatun kapıda konuşur; amaç «Ağıla git»; ağıla yaklaşınca Luhun seslenir; hedefe varınca biter.
##   race   ride:  kapı açılır, sürü salınır; kapıdan en uzaktaki birkaç koyun ağılda kalır, çocuk arkalarından yürüyerek çıkarır
##                 («Koyunları ağıldan sen çıkaracaksın.»; HerdSim.release hold). Yaşlı koyuna E ile binilir (binince geride kalanlar ardından
##                 çıkar), Shift dürter; yaşlı koyun yavaştır ve sık otlar (mount_traits). Luhun hızlı koyunla taşa yarışır (NPC binici:
##                 StoryMover, Rideable.place/drive/seat_transform); taşta E ile inilir («bin, sür, in»), inince biter.
##   hunt   hunt:  çayırda tarla kuşları ve isteğe bağlı fare; sağ tuş nişan, sol tuş bırak, E alır. Yançi ilk kuşu önce vurur (kuşu
##                 onundur, oyuncu alamaz); fareye yaklaşınca Luhun «Yavrusu var.» der; 90 sn'de Yançi bir kuşu gösterir (yerde halka).
##   count  count: sürü hattan geçirilir (ChildhoodSite.drive_herd, HerdField.count_finished), çocuklar hatta koşar; Dailin'in kalabalığı
##                 hattın çevresinde toplanır (ChildhoodSite kart kademesi, saatle). Oyuncu hatta varınca saat sayımın vaktine (beat) görünür
##                 akışla yetişir. Vakit gelip sürü sayılınca söz sırası: sayıcı Luhun'u ve Yançi'yi çentikle sayar, Mete'ye «Bir çocuk.»,
##                 Mete av sayar, sayıcı cevaplar. Söz sürerken Teoman ve beyleri ata binmiş hâlde hattın güney ucundan gelir (RiderColumn),
##                 Mete'nin önünden geçerken adıma iner, Teoman dört saniye bakar (durmaz), atlılar tırısla geçip gider; Mete «Beni gördü.»
##                 der; görüntü durur, kara perde iner, finished(sonuç) yayılır.
## Ceza yoktur. Kamera K98 kadrajında kalır (22 m); atlılar yaklaşırken odak Mete ile Teoman'ın ortasına kayar ve kamera 26 m'ye açılır:
## uzak kare (yakın plan yok).
##
## Söz (E20/7; K61, K78): satırlar seslidir. SceneVoice (voice) satırı vo_lines.json'daki vo_prefix + anahtar kimliğiyle çalar; altyazı sesin süresi
## kadar durur, söz sırası (exchange) ve sözü bekleyen evreler sesin bitişini bekler, konuşulurken gelen söz sıraya girer (dosyası yoksa altyazıyla
## akar, K89). Adımın söz kancaları verinin approach_line, herd_line, herd_last_line, mount_line, finish_lines, dismount_line, show_target.line,
## spare.shot, pick_lines ve wait_lines alanlarıdır; tepki sözleri (barks; K61 C) yaşlı koyun otlarken (graze), ıskada (miss), vuruşta (hit) ve
## kuş ürkünce (flush) Yançi ile Luhun'dan gelir: aynı rol aynı olayda ≥45 sn arayla, konuşulurken düşer.
## Hız sınırı (E20; PaceLimit): hiçbir kişi küçük Mete'nin koşusunu (speed_cap, 3,6 m/sn) aşmaz: verinin hızları pace() ile sınırlanır, atlı
## düzeni kıvrımın dışındaki beyle birlikte sınırda kalır (RiderColumn.limit_speeds), kalabalık saatin görünür akışında yürüyerek yetişir
## (CrowdCards.speed_cap; atlanan adımdan başlarken snap).
##
## Saat (GameClock; time.md §6, K67): 22 Eylül MÖ 228 (day_n −5.600) 08:40'ta açılır, 2,5 sn = 1 oyun dk akar. Bloklayan söz (söz sırası:
## dialogue) ve atlıların geçişi (cine) saati durdurur; duraklatma kitabı ağacı durdurur, saat de durur. Işık saati izler
## (OrdosWorld.set_childhood_time 4 Hz, görünür akışta her kare), kalabalık da (aynı çağrı). Sayımın vakti (count.beat, 11:00): çocukların
## sayımı saat vakte varmadan başlamaz. Oyuncu hatta vardığında saat gerideyse saat görünür biçimde akar (GameClock.begin_lapse): sürü henüz
## sayılıyorsa akış sürünün kalan sayım süresine yayılır (HerdField.count_eta; en az lapse_min_s, en çok lapse_max_s), sürü sayıldıysa ya da
## akıştan önce sayılırsa kalan akış lapse_speed oyun dk/sn hızla kapanır (en çok lapse_final_s). Saat vakti geçmişse akış yoktur. Böylece
## sayım ≈11:00'de biter: hızlı oyuncuda kalabalık toplanırken güneş görünür biçimde ilerler, yavaş oyuncuda saat 11:00'i geçer (geri gitmez).
## Kayıt yoktur: sahne yolculuğa yalnız bittiğinde işaret yazdırır (main.gd, finished'ın flags'i).
##   var scene := ChildhoodScene.new()
##   scene.setup(ordos, player, follow_camera, {"old_sheep": a, "fast_sheep": b}, $UI, $UI/Fade, hud, $UI/Fade)
##   add_child(scene); await scene.prepare(); scene.begin()        # begin("count"): o adımdan (geliştirme, sınama)
##   var result: Dictionary = await scene.finished                    # {larks, gerbils, mouse_hit, spared, flags}
##   scene.stop()                                                     # her durumda: yazılar, engeller, kamera, süreçler geri

signal prepared
signal step_started(step_id: String)
signal said(line_id: String)
signal finished(result: Dictionary)
## E21 (K110): günün sahnesi başladı (day_id; main.gd kayıt noktasına bağlar).
signal day_started(day_id: String)

const SCENE_PATH := "res://data/story/childhood/scene.json"
## Kişilerin dünyadaki düğümü (dünyayla birlikte donar ve silinir).
const ROOT_NAME := "Story"
## Atlıların düğümü (Story'nin altında).
const RIDERS_NAME := "Riders"
## Işığın dünyaya yazılma aralığı (sn; görünür akışta her kare).
const CLOCK_TICK := 0.25
## Saatin açıldığı dakika (veri yoksa) ve sayımın vakti.
const CLOCK_START := 520.0
const BEAT_MINUTE := 660.0
## Görünür akışın varsayılanları: en kısa ve en uzun süre (sn), sürü sayıldıktan sonraki hız (oyun dk/sn) ve en uzun süresi.
const LAPSE_MIN_S := 1.5
const LAPSE_MAX_S := 60.0
const LAPSE_SPEED := 12.0
const LAPSE_FINAL_S := 6.0
## Duran kişinin oyuncuya engel yarıçapı (m).
const SOLID_RADIUS := 0.32
## Kişilerin ısıtılan klipleri (koşan çocuklar koşu klibiyle).
const ACTOR_ROLES: Array[StringName] = [&"idle", &"walk", &"run"]
## Atların modelleri (assets/animals/<id>/<id>.glb).
const HORSE_DIR := "res://assets/animals/%s/%s.glb"
## Yançi'nin okunun hızı, çıkış yüksekliği (m) ve ıskada zorla düşürmeden önceki bekleme (sn).
const NPC_ARROW_SPEED := 17.0
const NPC_LAUNCH_UP := 0.62
const SHOT_TIMEOUT := 1.4
## Kuşu almadan önce durma (sn) ve kuşun yanına varış payı (m).
const PICK_PAUSE := 0.6
const PICK_GAP := 0.45
## Gösterilen hedefin halkası (m) ve rengi.
const RING_RADIUS := 0.6
const RING_COLOR := Color(1.0, 0.86, 0.52, 0.75)
## Söz sırasında satırlar arası boşluk ve oyuncunun dönüşü (sn).
const LINE_GAP := 0.45
const TURN_SECONDS := 0.5
## Odağın izleme keskinliği, Mete'den en çok kayışı (m) ve atlılar bu uzaklığa girince odağın kaymaya başlaması (m).
const FOCUS_SHARPNESS := 2.4
const FOCUS_MAX_SHIFT := 8.5
const FOCUS_FROM := 30.0
## Bakışın açılıp kapanışı (sn), «Beni gördü.»den kararmaya dek (sn), kara perdede bekleme (sn).
const LOOK_IN := 0.6
const LOOK_OUT := 0.9
const END_HOLD := 0.9
const BLACK_HOLD := 0.4

var data: Dictionary = {}
## Sol üstteki sade amaç bloğu (StoryHud) görünsün mü? Oyun içi HUD'un görev kartı onun yerine geçince main.gd kapatır.
var objective_box := true
var world: Node3D
var site: ChildhoodSite
var player: PlayerController
var camera: FollowCamera
## Hareket ipucunun paneli (sol alt; GameHud) ve kara perde (UI/Fade).
var game_hud: GameHud
var fade_rect: ColorRect
var hud: StoryHud
var lang := "tr"
## Sahnenin saati (gerçek sn; altyazı) ve adımın saati.
var clock := 0.0
var step_clock := 0.0
## Oyunun saati (22 Eylül MÖ 228; begin'de kurulur).
var game_clock: GameClock
var said_lines := PackedStringArray()
var actors: Dictionary = {}
var movers: Dictionary = {}
## Binilen iki koyun: kimlik (old_sheep, fast_sheep) → RideableSheep (main.gd kurar).
var sheep: Dictionary = {}
## Sahnenin kendi atları: kişi kimliği (teoman, bey_*) → RideableHorse.
var horses: Dictionary = {}
## Teoman'ın beyleri: [{id, actor, mover}] (actors'ta değildir).
var escort: Array[Dictionary] = []
## Atlı düzeni (sayımda kurulur; yoksa null).
var column: RiderColumn
## Mete'nin aldığı av (tür → adet) ve fareye ok değdi mi?
var catch := {"lark": 0, "gerbil": 0}
var mouse_hit := false
## Bakışın sürdüğü gerçek süre (sn; sınama okur) ve başladığı saat.
var gaze_seconds := 0.0
## Sahnenin sözü (SceneVoice; E20/7): ses, sıra ve tepki sözleri.
var voice: SceneVoice
# E21 (K110; docs/design/d3/e21-childhood-api.md): Çocukluk'un günleri ve adım türlerinin kaydı (ChildhoodSteps). Günün kimliği, sıradaki gün
# (bitişte result.next_day; main.gd açar), bitişte yazılacak ek işaretler, görünür kara perde (uyku; main.gd'nin UI/Fade'i), sesin yatakları.
var day_id := ""
var next_day := ""
var extra_flags := PackedStringArray()
var screen_fade: ColorRect
var atmos: ChildhoodAtmos
## E21 (Ç2): oyuncunun heybesi (main.gd verir: GameplayHud.bag.inventory): Çetele'nin kurutu ve çetelesi, sayım gününün count_stick'i.
var inventory: Inventory
var _seq_pre := -1
var _handler: ChildhoodStep
var _held := {}
## E21: botun E'yi basılı tutması (ChildhoodStep.is_holding) ve oyuncunun önceki E kaynağı (adımın E'si önündedir).
var auto_hold := false
var _saved_interaction: Callable
var _requested_lines := PackedStringArray()

var _ui_parent: Node
var _below: Node
var _root: Node3D
var _riders_root: Node3D
var _arrows: ArrowField
var _ring: MeshInstance3D
var _focus: Node3D
var _index := -1
var _step: Dictionary = {}
var _phase := ""
var _queue: Array = []
var _running := false
var _stopped := false
var _done := false
var _clock_left := 0.0
var _saved_obstacles: Array[Vector3] = []
var _saved_player_process := Node.PROCESS_MODE_INHERIT
var _saved_world_process := Node.PROCESS_MODE_INHERIT
var _frozen := false
var _connections: Array = []
var _tweens: Array[Tween] = []
var _herd_counted := false
# Av adımı
var _yanchi_state := ""
var _yanchi_bird: SmallGame
var _shot_clock := 0.0
var _pick_left := 0.0
var _spare_said := false
var _shown: SmallGame
var _pointing := false
# Sayım adımı
var _seq_i := -1
var _seq_left := 0.0
var _turn_from := 0.0
var _turn_to := 0.0
var _turn_t := 1.0
var _gaze_left := 0.0
var _end_left := 0.0
var _camera_distance := 0.0
var _beat_started := false
var _focus_on := false
var _column_driven := {}
var _saved_traits := {}
# Söz kancaları (adım başında sıfırlanır)
var _approach_said := false
var _herd_last_since := -1.0
var _herd_last_said := false
var _rival_racing := false
var _rival_first := false
var _race_said := false
var _was_grazing := false
var _player_hits := 0
var _mouse_shot_said := false
var _wait_said := false


## Bağlam: dünya (OrdosWorld), oyuncu, takip kamerası, binilen koyunlar, yazıların konacağı düğüm ve onun altında kalacağı düğüm (perde),
## hareket ipucunun paneli, kara perde. Ağaca eklenmeden önce çağrılır.
func setup(p_world: Node3D, p_player: PlayerController, p_camera: FollowCamera, p_sheep: Dictionary, ui_parent: Node,
		below: Node = null, p_game_hud: GameHud = null, p_fade: ColorRect = null) -> void:
	world = p_world
	player = p_player
	camera = p_camera
	sheep = p_sheep
	_ui_parent = ui_parent
	_below = below
	game_hud = p_game_hud
	fade_rect = p_fade
	site = world.call(&"childhood") as ChildhoodSite if world and world.has_method(&"childhood") else null
	if data.is_empty():
		data = load_data()
	lang = SubtitleBar.ui_lang()
	voice = SceneVoice.new()
	voice.prefix = str(data.get("vo_prefix", ""))
	voice.gap = LINE_GAP
	voice.cooldown = float((data.get("barks", {}) as Dictionary).get("cooldown", SceneVoice.COOLDOWN))
	voice.show = _show_line
	voice.text_seconds = func(key: String) -> float: return StoryHud.line_seconds(line_text(key))
	voice.pan_of = _pan_of


## Sahnenin verisi (okunamazsa boş).
static func load_data(path: String = SCENE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("[childhood] sahne dosyası yok: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## Adımların kimlikleri, sırasıyla (saf).
static func step_ids(d: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	for s: Variant in d.get("steps", []):
		if s is Dictionary:
			out.append(str((s as Dictionary).get("id", "")))
	return out


## Verinin eksikleri (saf; sınama): adımın türü, satırın konuşanı, sözün dili, adımın andığı satır ve kişi, atlıların modeli ve atı, yolun noktaları.
static func validate(d: Dictionary) -> PackedStringArray:
	var problems := PackedStringArray()
	var lines: Dictionary = d.get("lines", {})
	var speakers: Dictionary = d.get("speakers", {})
	var actor_defs: Dictionary = d.get("actors", {})
	for id: String in lines:
		var line: Dictionary = lines[id]
		if not speakers.has(str(line.get("speaker", ""))):
			problems.append("%s: konuşan yok" % id)
		for l in ["tr", "en"]:
			if str(line.get(l, "")).strip_edges().is_empty():
				problems.append("%s: %s metni yok" % [id, l])
	for id: String in actor_defs:
		var horse := str((actor_defs[id] as Dictionary).get("horse", ""))
		if not horse.is_empty() and not ResourceLoader.exists(HORSE_DIR % [horse, horse]):
			problems.append("%s: at modeli yok: %s" % [id, horse])
	if GameClock.parse_hhmm((d.get("clock", {}) as Dictionary).get("start", "08:40")) < 0.0:
		problems.append("clock.start okunamıyor")
	var kinds := ["reach", "race", "hunt", "count"]
	for s: Variant in d.get("steps", []):
		var step: Dictionary = s
		var sid := str(step.get("id", ""))
		# E21: kayıtlı türler (ChildhoodSteps) kendi denetimini yapar.
		if ChildhoodSteps.has(str(step.get("kind", "")), step):
			problems.append_array(ChildhoodSteps.check(str(step.get("kind", "")), step, d))
		elif not kinds.has(str(step.get("kind", ""))):
			problems.append("%s: bilinmeyen tür %s" % [sid, step.get("kind")])
		for key in ["objective"]:
			if not step.get(key) is Dictionary or str((step[key] as Dictionary).get("tr", "")).is_empty() or str((step[key] as Dictionary).get("en", "")).is_empty():
				problems.append("%s: %s iki dilde olmalı" % [sid, key])
		for entry: Variant in _line_refs(step):
			if not lines.has(str(entry)):
				problems.append("%s: satır yok: %s" % [sid, entry])
		for entry: Variant in _actor_refs(step):
			if not actor_defs.has(str(entry)):
				problems.append("%s: kişi yok: %s" % [sid, entry])
		var beat: Variant = step.get("beat")
		if beat is Dictionary and GameClock.parse_hhmm((beat as Dictionary).get("at", "")) < 0.0:
			problems.append("%s: beat.at okunamıyor" % sid)
		var picks: Variant = step.get("pick_lines")
		if picks != null and not picks is Dictionary:
			problems.append("%s: pick_lines tür → satır listesi olmalı" % sid)
		var proc: Variant = step.get("procession")
		if proc is Dictionary:
			if ((proc as Dictionary).get("path", []) as Array).size() < 2:
				problems.append("%s: atlıların yolu en az iki nokta" % sid)
			for e: Variant in (proc as Dictionary).get("escort", []):
				var model := str((e as Dictionary).get("model", ""))
				var horse := str((e as Dictionary).get("horse", ""))
				if not StandIn.has_model(model):
					problems.append("%s: beyin modeli yok: %s" % [sid, model])
				if not ResourceLoader.exists(HORSE_DIR % [horse, horse]):
					problems.append("%s: beyin atı yok: %s" % [sid, horse])
	# Tepki sözleri (K61 C): her olayın çeşidi bilinen satır ve kişidir.
	var barks: Dictionary = d.get("barks", {})
	for event: String in barks:
		if not barks[event] is Array:
			continue
		for e: Variant in barks[event]:
			var entry: Dictionary = e
			if not lines.has(str(entry.get("line", ""))):
				problems.append("barks.%s: satır yok: %s" % [event, entry.get("line")])
			if not actor_defs.has(str(entry.get("by", ""))):
				problems.append("barks.%s: kişi yok: %s" % [event, entry.get("by")])
	return problems


## Adımın andığı satırlar (saf): her derinlikteki line, spared_line ve race_line (sözsüz sayım satır anmaz).
static func _line_refs(step: Dictionary) -> Array:
	var out: Array = []
	_collect_lines(step, out)
	return out


static func _collect_lines(v: Variant, out: Array) -> void:
	if v is Dictionary:
		for k: Variant in v:
			if str(k) in ["line", "spared_line", "race_line"] and (v[k] is String):
				out.append(v[k])
			else:
				_collect_lines(v[k], out)
	elif v is Array:
		for e: Variant in v:
			_collect_lines(e, out)


static func _actor_refs(step: Dictionary) -> Array:
	var out: Array = []
	for key in ["rival", "rival_spot", "first_shot", "spare", "show_target", "gaze", "counter"]:
		if step.get(key) is Dictionary:
			out.append((step[key] as Dictionary).get("actor", ""))
	for c: Variant in step.get("children", []):
		out.append((c as Dictionary).get("actor", ""))
	for e: Variant in step.get("exchange", []):
		for key in ["by", "face"]:
			if (e as Dictionary).has(key):
				out.append((e as Dictionary)[key])
	if step.get("procession") is Dictionary:
		out.append((step["procession"] as Dictionary).get("leader", ""))
	return out


# --- Kurulum -------------------------------------------------------------------------------------------

## Kişileri ve yazıları kurar: kişi başına bir kare (CineActor'ın kurulumu ağırdır), perde kapalıyken. Bitince prepared.
func prepare() -> void:
	if world == null or player == null:
		push_warning("[childhood] bağlam yok")
		prepared.emit()
		return
	# E21: günlerin sırasında açılan gün dünyayı kendi başına göre kurar (sürü, iki binek koyun, kapı).
	if not day_id.is_empty():
		_reset_day_world()
	_root = Node3D.new()
	_root.name = ROOT_NAME
	world.add_child(_root)
	hud = StoryHud.new()
	hud.show_box = objective_box
	_ui_parent.add_child(hud)
	if _below and _below.get_parent() == _ui_parent:
		_ui_parent.move_child(hud, _below.get_index())
	_arrows = ArrowField.new()
	_arrows.name = "NpcArrows"
	_root.add_child(_arrows)
	_arrows.ground = _ground_y
	_ring = _make_ring()
	_root.add_child(_ring)
	_focus = Node3D.new()
	_focus.name = "GazeFocus"
	_root.add_child(_focus)
	_saved_obstacles = player.extra_obstacles.duplicate()
	var defs: Dictionary = data.get("actors", {})
	for id: String in defs:
		var def: Dictionary = defs[id]
		var a := CineActor.new()
		a.name = id.to_pascal_case()
		a.character_id = id
		a.build_on_ready = false
		if def.get("gesture") is Array:
			a.gesture_turns = def["gesture"]
		_root.add_child(a)
		actors[id] = a
	for id: String in defs:
		await get_tree().process_frame
		if _stopped:
			return
		_build_actor(id, defs[id])
	await _build_escort()
	if _stopped:
		return
	# Duran kişiler (Lan Hatun, sayıcı) oyuncunun engelidir; sürü bütün kişilere yol verir (oyuncu ve binilen koyunlar main.gd'nin listesindedir).
	player.refresh_obstacles()
	if site and site.herd:
		var avoid: Array[Node3D] = [player]
		for s: Variant in sheep.values():
			if s is Node3D:
				avoid.append(s)
		for a: Variant in actors.values():
			avoid.append(a as Node3D)
		site.herd.set_avoid_nodes(avoid)
	prepared.emit()


## E21: günün başı (günlerin sırasında): oyuncu yere iner, iki binek koyun kendi işaretinde, sürü günün herd_start'ında (pen: ağılda, kapı
## kapalı; meadow: çayırda; keep: olduğu gibi).
func _reset_day_world() -> void:
	if player.get_stance() != PlayerController.Stance.FOOT:
		player.spawn_at(player.global_position, player.get_facing_yaw())
	for id: String in sheep:
		var s := sheep[id] as Rideable
		var at := point(id)
		if s and is_instance_valid(s) and at != Vector3.INF:
			s.set_ridden(false)
			s.place(at, PI * 0.5 + (0.4 if id == "old_sheep" else -0.4))
	if site and site.herd:
		match str(data.get("herd_start", "pen")):
			"pen":
				site.reset_herd()
			"meadow":
				site.skip_herd_to_meadow()


func _build_actor(id: String, def: Dictionary) -> void:
	var a: CineActor = actors[id]
	a.build()
	a.ensure_idle(ACTOR_ROLES)
	var at := point(def.get("start"))
	if at == Vector3.INF:
		at = player.global_position
	var mount_id := str(def.get("rides", ""))
	var ride: Rideable = sheep.get(mount_id) as Rideable if not mount_id.is_empty() else null
	if ride == null and def.has("horse"):
		ride = _make_horse(id, str(def["horse"]))
	var mover := StoryMover.new(a, _shape(), ride)
	movers[id] = mover
	var face_at := point(def.get("face"))
	var yaw := CampNpcs.facing_yaw(at, face_at) if face_at != Vector3.INF else a.rotation.y
	if is_nan(yaw):
		yaw = 0.0
	if ride:
		if ride is RideableHorse:
			ride.global_position = at
		mover.place(ride.global_position, yaw)
		mover.seat()
		if ride is RideableHorse:
			RiderShadow.attach(ride, a)
	else:
		mover.place(at, yaw)
	_set_present(id, not bool(def.get("hidden", false)))
	if bool(def.get("solid", false)):
		player.extra_obstacles.append(Vector3(at.x, at.z, SOLID_RADIUS))


## Sahnenin atı: iskeletli model, klipleri ve efektleri (RideableHorse). Binilebilirler grubundan çıkar: oyuncu Teoman'ın atına binemez,
## at oyuncunun engeli değildir (binilmiş sayılır).
func _make_horse(owner_id: String, model: String) -> RideableHorse:
	var path := HORSE_DIR % [model, model]
	if not ResourceLoader.exists(path):
		push_warning("[childhood] at modeli yok: %s" % path)
		return null
	var horse := RideableHorse.new()
	horse.name = "%sHorse" % owner_id.to_pascal_case()
	horse.model_path = path
	(_riders_root if _riders_root else _riders_parent()).add_child(horse)
	if horse.is_in_group(Rideable.GROUP):
		horse.remove_from_group(Rideable.GROUP)
	var fx := horse.effects()
	if fx:
		fx.terrain_shape = _shape()
	horses[owner_id] = horse
	return horse


func _riders_parent() -> Node3D:
	if _riders_root == null:
		_riders_root = Node3D.new()
		_riders_root.name = RIDERS_NAME
		_root.add_child(_riders_root)
	return _riders_root


## Teoman'ın beyleri (sayım adımının procession.escort'u): kişi başına bir kare, gizli ve durgun kurulur.
func _build_escort() -> void:
	var proc := _procession_def()
	var list: Array = proc.get("escort", [])
	for i in list.size():
		await get_tree().process_frame
		if _stopped:
			return
		var e: Dictionary = list[i]
		var id := "bey_%d" % i
		var a := CineActor.new()
		a.name = id.to_pascal_case()
		a.character_id = str(e.get("model", "crowd_hun_rider"))
		a.build_on_ready = false
		_riders_parent().add_child(a)
		a.build()
		if e.get("tint") is Array and (e["tint"] as Array).size() >= 3:
			var t: Array = e["tint"]
			StandIn.apply(a.avatar, Color(float(t[0]), float(t[1]), float(t[2])), 1.0)
		var ride := _make_horse(id, str(e.get("horse", "horse_brown")))
		var mover := StoryMover.new(a, _shape(), ride)
		var start := points(proc.get("path", []))
		var at: Vector3 = start[0] if not start.is_empty() else player.global_position
		if ride:
			ride.global_position = at
			mover.place(at, 0.0)
			mover.seat()
			RiderShadow.attach(ride, a)
		else:
			mover.place(at, 0.0)
		escort.append({"id": id, "actor": a, "mover": mover, "slot": e.get("slot", [0.0, 3.0])})
		_show_rider(mover, false)


func _procession_def() -> Dictionary:
	for s: Variant in data.get("steps", []):
		if (s as Dictionary).get("procession") is Dictionary:
			return (s as Dictionary)["procession"]
	return {}


## Kişiyi gösterir ya da gizler; gizliyken kişi ve atı işlemez (görünmeyen atlı boşuna canlanmasın).
func _set_present(id: String, on: bool) -> void:
	var a: CineActor = actors.get(id)
	if a:
		a.visible = on
		a.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	var horse: RideableHorse = horses.get(id)
	if horse:
		horse.visible = on
		horse.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED


func _show_rider(mover: StoryMover, on: bool) -> void:
	for node: Node3D in [mover.actor, mover.ride]:
		if node:
			node.visible = on
			node.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED


# --- Akış ------------------------------------------------------------------------------------------------

## Sahneyi başlatır (step_id boşsa ilk adımdan). Atlanan adımların dünyası kurulur: sürü çayırda, kişiler yerlerinde, saat o anda.
func begin(step_id: String = "") -> void:
	var ids := step_ids(data)
	if ids.is_empty():
		push_warning("[childhood] adım yok")
		return
	var start := maxi(ids.find(step_id), 0) if not step_id.is_empty() else 0
	_running = true
	if voice:
		voice.audio = get_node_or_null(^"/root/AudioManager")
	# E21: günün sözleri gün başında arka planda istenir, gün bitince bırakılır (seslendirme havuzu gün başınadır).
	_request_day_lines()
	_connect_signals()
	_start_audio()
	# Yayın ipucu nişan adımında gelir (ilk iki adımda yay işe yaramaz). E21: günün verisi bow_from ile seçer ("" baştan).
	var bow_from := str(data.get("bow_from", "hunt"))
	player.bow_prompt = bow_from.is_empty() or (ids.find(bow_from) >= 0 and start >= ids.find(bow_from))
	hud.set_title(text_of(data.get("title")))
	# E21: sesin yatakları (günün atmos'u; dosya yoksa yer tutucu).
	if not (data.get("atmos", {}) as Dictionary).is_empty():
		atmos = ChildhoodAtmos.new()
		atmos.name = "Atmos"
		add_child(atmos)
		atmos.setup(self, data.get("atmos", {}))
	# E21: Dailin sayım günü toplanır (kalabalık, hattın bayrakları); 20–21 Eylül'de ufukta yalnız dumanı ve ateşleri (dailin_gathered).
	if site:
		site.set_dailin_gathered(bool(data.get("dailin_gathered", day_id.is_empty() or day_id == "count")))
	# E21: adımın E'si oyuncunun E kaynağının önünde (yoksa önceki kaynak sorulur).
	_saved_interaction = player.interaction_source
	player.interaction_source = _step_interaction
	_preset(start)
	_write_light()
	_start_step(start)
	day_started.emit(day_id)


func is_running() -> bool:
	return _running


func current_step_id() -> String:
	return str(_step.get("id", ""))


func current_phase() -> String:
	return _handler.phase if _handler else _phase


## Kayıtlı türün süren adımı (E21; bugünkü dört türde null).
func step_handler() -> ChildhoodStep:
	return _handler


## Sonuç: alınan av, fareye değen ok, yazılacak işaretler. E21: spared yalnız verisinde olan günde (sayım günü); ek işaretler (extra_flags) ve
## sıradaki gün (next_day: main.gd aynı dünyada açar).
func result() -> Dictionary:
	var flags: Dictionary = data.get("flags", {})
	var out := PackedStringArray([str(flags.get("done", "mq0_sheep"))])
	if not mouse_hit and flags.has("spared"):
		out.append(str(flags.get("spared", "child_spared")))
	out.append_array(extra_flags)
	var res := {"larks": int(catch["lark"]), "gerbils": int(catch["gerbil"]), "mouse_hit": mouse_hit, "spared": not mouse_hit, "flags": out}
	if not next_day.is_empty():
		res["next_day"] = next_day
		res["day"] = day_id
	return res


## Oyun içi HUD'un görevi (GameplayHud: görev kartı ve Görevler sayfası): başlık, o anki amaç ve ayrıntı (StoryHud'daki gibi,
## adımın evresiyle: «Luhun'la taşa yarış», «(1/2)»), adımlar (biten, o anki, sonraki). Söz sırasında amaç boştur.
func hud_quest() -> Dictionary:
	var out := quest_of(data, _index, lang)
	out["objective"] = hud.objective_text() if hud else str(out.get("objective", ""))
	out["detail"] = hud.hint_text() if hud else str(out.get("detail", ""))
	out["done"] = _done
	return out


## Sahnenin görevi verisinden (saf; Serbest Gez'in Görevler sayfasında bitmiş görev olarak da): index o anki adımdır (adım sayısı
## ya da ötesi: hepsi bitti).
static func quest_of(d: Dictionary, index: int, p_lang: String = "tr") -> Dictionary:
	var steps: Array = []
	var all: Array = d.get("steps", [])
	for i in all.size():
		var s: Dictionary = all[i]
		steps.append({"id": str(s.get("id", "")), "text": _text_in(s.get("objective"), p_lang),
			"state": "done" if i < index else ("current" if i == index else "todo")})
	var cur: Dictionary = all[index] if index >= 0 and index < all.size() else {}
	return {
		"id": str(d.get("id", "mq0_sheep")), "title": _text_in(d.get("title"), p_lang), "objective": _text_in(cur.get("objective"), p_lang),
		"detail": _text_in(cur.get("hint"), p_lang), "steps": steps, "done": index >= all.size(),
	}


static func _text_in(entry: Variant, p_lang: String) -> String:
	if entry is Dictionary:
		return str((entry as Dictionary).get(p_lang, (entry as Dictionary).get("tr", "")))
	return str(entry) if entry != null else ""


## Görevin o anki hedefi (HUD'un yön işaretleri; dünya, yoksa Vector3.INF): uyanışta ağılın kapısı; binmede yaşlı koyun, binince
## yarışın taşı; avda yerdeki (Mete'nin vurduğu) kuş, yoksa en yakın vurulabilir tarla kuşu, o da yoksa çayır; sayımda çocukların
## hattaki yeri. Söz sırasında ve bitişte hedef yoktur.
func hud_target(from: Vector3 = Vector3.INF) -> Vector3:
	if not _running or _step.is_empty():
		return Vector3.INF
	var at := from if from != Vector3.INF else (player.global_position if is_instance_valid(player) else Vector3.ZERO)
	match str(_step.get("kind", "")):
		"reach":
			return point(_step.get("target"))
		"race":
			if _phase == "herd" and site and site.herd:
				var best := Vector3.INF
				for p in site.herd.held_positions():
					if best == Vector3.INF or _flat(p, at) < _flat(best, at):
						best = p
				if best != Vector3.INF:
					return best
			if _phase in ["herd", "mount"] and not player.is_riding():
				var ride: Node3D = sheep.get(str(_step.get("mount", "old_sheep"))) as Node3D
				if is_instance_valid(ride):
					return ride.global_position
			if _phase == "dismount":
				return Vector3.INF
			return point(_step.get("goal"))
		"hunt":
			var down := _nearest_fallen("lark", at)
			if down:
				return down.global_position
			var bird := _nearest_game("lark", at, 400.0, false)
			if bird:
				return bird.global_position
			return point("meadow")
		"count":
			if _phase in ["arrive", "wait", ""]:
				return point(_step.get("goal"))
		_:
			if _handler:
				return _handler.target(at)
	return Vector3.INF


## Yerde duran ve oyuncunun alabileceği en yakın hayvan (Yançi'ninki sayılmaz).
func _nearest_fallen(kind: String, from: Vector3) -> SmallGame:
	if site == null or site.game == null:
		return null
	var best: SmallGame = null
	var best_d := INF
	for a: SmallGame in site.game.of_kind(kind):
		if a == _yanchi_bird or not a.is_down() or not a.is_in_group(SmallGame.FALLEN_GROUP):
			continue
		var d := Vector2(a.global_position.x - from.x, a.global_position.z - from.z).length()
		if d < best_d:
			best_d = d
			best = a
	return best


## Oyunun gün dakikası (08:40 = 520; saat kurulmadıysa açılış dakikası).
func minute() -> float:
	return game_clock.minute if game_clock else clock_start()


## Saatin «hh:mm»si.
func clock_text() -> String:
	return GameClock.hhmm(minute())


## Saatin açıldığı gün dakikası (veriden; 08:40).
func clock_start() -> float:
	var m := GameClock.parse_hhmm((data.get("clock", {}) as Dictionary).get("start", "08:40"))
	return m if m >= 0.0 else CLOCK_START


## Sayımın vakti (gün dakikası; veride yoksa 11:00).
func beat_minute() -> float:
	var beat: Dictionary = _count_step().get("beat", {})
	var m := GameClock.parse_hhmm(beat.get("at", "11:00"))
	return m if m >= 0.0 else BEAT_MINUTE


func _count_step() -> Dictionary:
	for s: Variant in data.get("steps", []):
		if str((s as Dictionary).get("kind", "")) == "count":
			return s
	return {}


## Kişilerin hız sınırı (E20; PaceLimit): o an oyuncunun en yüksek koşusu (küçük Mete'nin koşusu, 3,6 m/sn). Yürüyen, koşan ve binekli
## her kişi (Luhun koyunda, Yançi, Teoman'ın atlıları, kalabalığın kartları) bunu aşmaz.
func speed_cap() -> float:
	return PaceLimit.run_cap(player)


## Verinin hızı sınırın içinde (m/sn).
func pace(speed: float) -> float:
	return PaceLimit.limit(speed, speed_cap())


## Durdurur ve bıraktığı her şeyi geri alır (bitişte de, yarıda bırakılınca da): yazılar, kişilerin engelleri, kamera, donma, ses.
func stop() -> void:
	if _stopped:
		return
	_stopped = true
	_running = false
	if _handler:
		_handler.stop()
		_handler = null
	for id: String in _held.keys():
		unpose_actor(id)
	if is_instance_valid(atmos):
		atmos.stop()
	if is_instance_valid(site) and not day_id.is_empty():
		site.set_dailin_gathered(true)
	if is_instance_valid(player) and player.interaction_source == Callable(self, &"_step_interaction"):
		player.interaction_source = _saved_interaction
	auto_hold = false
	if is_instance_valid(screen_fade) and screen_fade.has_meta(&"own"):
		screen_fade.queue_free()
		screen_fade = null
	if voice:
		voice.stop()
	_release_day_lines()
	for t in _tweens:
		if t and t.is_valid():
			t.kill()
	_tweens.clear()
	for c: Array in _connections:
		var sig: Signal = c[0]
		if is_instance_valid(sig.get_object()) and sig.is_connected(c[1]):
			sig.disconnect(c[1])
	_connections.clear()
	_unfreeze()
	if is_instance_valid(player):
		player.extra_obstacles = _saved_obstacles.duplicate()
		player.refresh_obstacles()
		player.bow_prompt = true
	if is_instance_valid(camera) and is_instance_valid(player) and camera.target != player:
		camera.target = player
		camera.zoom_by(FollowCamera.CHILD_DISTANCE - camera.get_target_distance())
	if is_instance_valid(hud):
		hud.clear()
		hud.queue_free()
	hud = null
	if site and is_instance_valid(site):
		site.watch_crowd(Vector3.INF)
	var traited: Variant = _saved_traits.get("ride")
	if is_instance_valid(traited) and (traited as Rideable).get_mount():
		(traited as Rideable).get_mount().spec = _saved_traits["spec"]
	_saved_traits = {}
	var ambience: Dictionary = data.get("ambience", {})
	for id: String in ambience:
		_audio(&"set_ambience_layer", [StringName(id), -80.0, 1.0])
	if is_instance_valid(_root):
		_root.queue_free()
	_root = null
	_riders_root = null
	movers.clear()
	actors.clear()
	horses.clear()
	escort.clear()
	column = null


func _exit_tree() -> void:
	stop()


func _process(delta: float) -> void:
	if not _running:
		return
	clock += delta
	step_clock += delta
	if game_clock:
		game_clock.step(delta)
	_tick_clock(delta)
	if voice:
		voice.tick(clock)
	_tick_queue()
	# Görüntü durunca kişiler de durur (dönüşleri sürmez). E21: tutulan kişi (hold_mover, pose_actor) dışarıdan sürülür.
	if not _frozen:
		for id: String in movers:
			if not _column_driven.has(id) and not _held.has(id):
				(movers[id] as StoryMover).tick(delta)
	match str(_step.get("kind", "")):
		"reach":
			_tick_reach()
		"race":
			_tick_race()
		"hunt":
			_tick_hunt(delta)
		"count":
			_tick_count(delta)
		_:
			if _handler and not _frozen:
				_handler.clock = step_clock
				_handler.tick(delta)
	_tick_ring()
	if hud:
		hud.tick(clock)


func _start_step(i: int) -> void:
	var steps: Array = data.get("steps", [])
	# E21: önceki kayıtlı türün temizliği (bir kez).
	if _handler:
		_handler.stop()
		_handler = null
	_index = i
	_step = steps[i]
	step_clock = 0.0
	_phase = ""
	_queue.clear()
	_approach_said = false
	_herd_last_since = -1.0
	_herd_last_said = false
	_rival_racing = false
	_rival_first = false
	_race_said = false
	_was_grazing = false
	_wait_said = false
	hud.set_objective(text_of(_step.get("objective")))
	hud.set_hint(text_of(_step.get("hint")))
	for s: Variant in _step.get("say", []):
		_at(float((s as Dictionary).get("at", 0.0)), _say.bind(str((s as Dictionary).get("line", ""))))
	match str(_step.get("kind", "")):
		"reach":
			_start_reach()
		"race":
			_start_race()
		"hunt":
			_start_hunt()
		"count":
			_start_count()
		_:
			# E21: kayıtlı tür (ChildhoodSteps; scripts/story/steps/<tür>.gd).
			_handler = ChildhoodSteps.make(str(_step.get("kind", "")), self, _step)
			if _handler:
				_handler.start()
			else:
				push_warning("[childhood] bilinmeyen adım türü: %s" % _step.get("kind"))
	step_started.emit(current_step_id())


func _next_step() -> void:
	var steps: Array = data.get("steps", [])
	if _index + 1 < steps.size():
		_start_step(_index + 1)
	elif _handler:
		# E21: kayıtlı türle biten gün (uyku ya da aynı akşamın devamı): sahne biter, main.gd sıradaki günü açar.
		_handler.stop()
		_finish()


## E21 (kayıtlı türlerin yüzü): sıradaki adım; söz; adımın saatinde iş; yakınlık; tepki sözü; kişinin pozu ve tutulması; görünür akış.
func next_step() -> void:
	_next_step()


## Görünür kara perde (uyku): main.gd'nin UI/Fade'i (screen_fade), yoksa sahnenin kendi perdesi (yazıların üstünde). Döner: tween.
func screen_fade_to(alpha: float, seconds: float) -> Tween:
	if screen_fade == null:
		screen_fade = ColorRect.new()
		screen_fade.set_meta(&"own", true)
		screen_fade.name = "DayCurtain"
		screen_fade.color = Color(0, 0, 0, 0)
		screen_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		screen_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
		if _ui_parent:
			_ui_parent.add_child(screen_fade)
	var t := _tween()
	t.tween_property(screen_fade, ^"color:a", alpha, maxf(seconds, 0.01)).set_trans(Tween.TRANS_SINE)
	return t


## Günün sözlerinin kimlikleri (vo_prefix + anahtar; sesi olmayan satırı AudioManager atlar).
func day_line_ids() -> PackedStringArray:
	var out := PackedStringArray()
	var prefix := str(data.get("vo_prefix", ""))
	for key: String in (data.get("lines", {}) as Dictionary):
		out.append(prefix + key)
	return out


func _request_day_lines() -> void:
	var audio := get_node_or_null(^"/root/AudioManager")
	if audio and audio.has_method(&"request_lines"):
		_requested_lines = day_line_ids()
		audio.call(&"request_lines", _requested_lines)


func _release_day_lines() -> void:
	if _requested_lines.is_empty():
		return
	var audio := get_node_or_null(^"/root/AudioManager") if is_inside_tree() else null
	if audio and audio.has_method(&"release_lines"):
		audio.call(&"release_lines", _requested_lines)
	_requested_lines = PackedStringArray()


## Oyuncunun E'si: adımın işi (ChildhoodStep.interaction), yoksa önceki kaynak.
func _step_interaction() -> Dictionary:
	if _running and _handler:
		var d := _handler.interaction()
		if not d.is_empty():
			return d
	return _saved_interaction.call() if _saved_interaction.is_valid() else {}


func say(line_key: String, ok: Callable = Callable(), optional := false) -> float:
	return _say(line_key, ok, optional)


func at(t: float, fn: Callable) -> void:
	_at(t, fn)


func near(at_point: Vector3, radius: float) -> bool:
	return _near(at_point, radius)


func bark(event: String) -> void:
	_bark(event)


## Kişinin StoryMover'ı sahnenin tikinden çıkar (dışarıdan sürülür) ya da geri girer.
func hold_mover(id: String, on: bool) -> void:
	if on:
		_held[id] = true
	else:
		_held.erase(id)


## Kişiye kütüphanenin klibi (CharacterAvatar.play_job: yatma, uyku, çekme, alkış); kişi tutulur. Kurulamazsa false.
func pose_actor(id: String, clip_key: String) -> bool:
	var a: CineActor = actors.get(id)
	if a == null or a.avatar == null:
		return false
	hold_mover(id, true)
	return a.avatar.play_job(clip_key)


func unpose_actor(id: String) -> void:
	hold_mover(id, false)
	var a: CineActor = actors.get(id)
	if a and is_instance_valid(a) and a.avatar:
		a.avatar.set_locomotion(0.0)


## Saat görünür biçimde dakikaya akar (seconds saniyede; geri gitmez).
func lapse_to(target_minute: float, seconds: float) -> void:
	if game_clock == null or target_minute <= game_clock.minute + 0.001:
		return
	game_clock.begin_lapse(GameClock.abs_of(game_clock.day_n, target_minute), maxf(seconds, 0.1), &"beat")


## Atlanan adımların dünyası (geliştirme --step, sınama): oyuncu önceki adımın hedefinde ayakta, sürü ve kişiler yerinde; saat adımın
## tasarımdaki başlangıcında (at sn: 08:40 + at / 2,5 oyun dk).
func _preset(start: int) -> void:
	var steps: Array = data.get("steps", [])
	clock = float((steps[start] as Dictionary).get("at", 0.0))
	game_clock = GameClock.new(int(data.get("day_n", -5600)), clock_start() + clock / GameClock.SEC_PER_MIN)
	# E21: adımın tasarımdaki saati (clock: hh:mm; görünür akışlı günlerde at'tan türemez).
	var step_minute := GameClock.parse_hhmm((steps[start] as Dictionary).get("clock", "")) if start > 0 else -1.0
	if step_minute >= 0.0:
		game_clock.minute = step_minute
	var p: Dictionary = data.get("player", {})
	var yaw := deg_to_rad(float(p.get("yaw_deg", 90.0)))
	if start == 0:
		var at := point(p.get("start", "child_start"))
		if at != Vector3.INF and bool(p.get("seated", false)):
			player.sit_at(Transform3D(Basis(Vector3.UP, yaw), at))
		return
	var prev: Dictionary = steps[start - 1]
	var stand := point(prev.get("goal", prev.get("target")))
	if stand != Vector3.INF:
		player.spawn_at(stand + Vector3(-1.2, 0.0, 0.8), yaw)
	# Saat ileri kuruldu: kalabalık planın yerine oturur (yetişmek için yürümez; kurulmadıysa ilk yazışında zaten oturur).
	if site and site.crowd:
		site.set_minute(minute())
		site.crowd.snap()
	for i in range(1, start + 1):
		var s: Dictionary = steps[i - 1]
		match str(s.get("kind", "")):
			"race":
				if site:
					site.skip_herd_to_meadow()
				var rival: Dictionary = s.get("rival", {})
				_place_actor(str(rival.get("actor", "")), point(rival.get("finish")), point(s.get("goal")))
			"hunt":
				var spot: Dictionary = s.get("rival_spot", {})
				_place_actor(str(spot.get("actor", "")), point(spot.get("at")), point(spot.get("face")))
				var need: Dictionary = s.get("need", {})
				for kind: String in need:
					catch[kind] = maxi(int(catch.get(kind, 0)), int(need[kind]))
				player.spawn_at(point(spot.get("at")) + Vector3(4.0, 0.0, -2.0), yaw)
			_:
				# E21: kayıtlı türün adım sonrası dünyası (sürü, kişiler, kapı, oyuncunun yeri).
				var h := ChildhoodSteps.make(str(s.get("kind", "")), self, s)
				if h:
					h.preset()


func _place_actor(id: String, at: Vector3, face_at: Vector3) -> void:
	var m: StoryMover = movers.get(id)
	if m == null or at == Vector3.INF:
		return
	var yaw := CampNpcs.facing_yaw(at, face_at) if face_at != Vector3.INF else 0.0
	m.place(at, 0.0 if is_nan(yaw) else yaw)


# --- reach: uyanış ----------------------------------------------------------------------------------------

func _start_reach() -> void:
	if _step.has("show_controls") and game_hud:
		_at(float(_step["show_controls"]), func() -> void:
			if is_instance_valid(game_hud):
				game_hud.show_hints())


func _tick_reach() -> void:
	var target := point(_step.get("target"))
	if _near(target, float(_step.get("radius", 3.0))):
		_next_step()
		return
	# Hedefe yaklaşırken seslenen (approach_line; Luhun ağıldan: «Çabuk! Kapıyı sen açacaksın.»), bir kez.
	var call: Dictionary = _step.get("approach_line", {})
	if not call.is_empty() and not _approach_said and _near(target, float(call.get("near", 12.0))):
		_approach_said = true
		_say(str(call.get("line", "")))


# --- race: binme ve yarış ---------------------------------------------------------------------------------

func _start_race() -> void:
	var hold := int(_step.get("stragglers", 0))
	if bool(_step.get("release_herd", false)) and site:
		site.release_herd(hold)
	_apply_mount_traits()
	if hold > 0 and site and site.herd and site.herd.held_count() > 0:
		# «Koyunları ağıldan sen çıkaracaksın.»: sürünün çoğu kendiliğinden çıkar, geride kalanları çocuk arkalarından yürüyerek çıkarır.
		_phase = "herd"
		hud.set_objective(text_of(_step.get("herd_objective")))
		hud.set_hint(text_of(_step.get("herd_hint")))
		# Luhun yolu söyler (herd_line): ipucunun sözlü hâli, evre sürüyorsa.
		var hl: Dictionary = _step.get("herd_line", {})
		if not hl.is_empty():
			_at(float(hl.get("after", 1.5)), func() -> void:
				if _phase == "herd":
					_say(str(hl.get("line", ""))))
	else:
		_phase = "mount"
		_queue_mount_line()


## Binmeden önce Luhun yarışa çağırır (mount_line): evre sürüyor ve oyuncu hâlâ yayaysa (binmeye başladıysa binişin sözü gelir).
func _queue_mount_line() -> void:
	var ml: Dictionary = _step.get("mount_line", {})
	if ml.is_empty():
		return
	_at(step_clock + float(ml.get("after", 0.5)), func() -> void:
		if _phase == "mount" and not player.is_riding() and player.get_stance() == PlayerController.Stance.FOOT:
			_say(str(ml.get("line", ""))))


## Ağılda tek koyun uzun süre kalınca Luhun söyler (herd_last_line), bir kez.
func _tick_herd_last() -> void:
	var hl: Dictionary = _step.get("herd_last_line", {})
	if hl.is_empty() or _herd_last_said or site == null or site.herd == null:
		return
	if site.herd.held_count() != 1:
		_herd_last_since = -1.0
		return
	if _herd_last_since < 0.0:
		_herd_last_since = step_clock
	elif step_clock - _herd_last_since >= float(hl.get("after", 8.0)):
		_herd_last_said = true
		_say(str(hl.get("line", "")))


## Yaşlı koyun otlamaya durunca tepki sözü (graze): yalnız binerken, durduğu an.
func _tick_graze() -> void:
	var ride := sheep.get(str(_step.get("mount", "old_sheep"))) as Rideable
	var mount := ride.get_mount() if ride and player.is_riding() else null
	var grazing := mount != null and mount.is_grazing()
	if grazing and not _was_grazing:
		_bark("graze")
	_was_grazing = grazing


## Taşa varınca yarışın sonucu (finish_lines): Luhun önce vardıysa «Yaşlısı yine de geldi.», değilse «Yaşlısı nasıl koştu öyle?»; bir kez.
func _say_race_result() -> void:
	if _race_said:
		return
	_race_said = true
	var fl: Dictionary = _step.get("finish_lines", {})
	var entry: Variant = fl.get("after_rival" if _rival_first else "before_rival")
	if entry is Dictionary:
		_say(str((entry as Dictionary).get("line", "")))


func _tick_race() -> void:
	var start := point(_step.get("start"))
	var goal := point(_step.get("goal"))
	var rival: Dictionary = _step.get("rival", {})
	var luhun: StoryMover = movers.get(str(rival.get("actor", "")))
	match _phase:
		"herd":
			_tick_herd_last()
			if player.is_riding():
				# Yaşlı koyun (sürünün başı) binicisiyle çıkar: geride kalanlar ardından gelir.
				if site and site.herd:
					site.herd.release_held()
				_begin_race_out(luhun, rival)
			elif site == null or site.herd == null or site.herd.held_count() == 0:
				_phase = "mount"
				hud.set_objective(text_of(_step.get("objective")))
				hud.set_hint(text_of(_step.get("hint")))
				_queue_mount_line()
		"mount":
			if player.is_riding():
				_begin_race_out(luhun, rival)
		"out":
			if _near(start, float(_step.get("start_radius", 6.0))) or _near(goal, 12.0):
				_phase = "race"
				if luhun:
					luhun.go(_rival_route(rival), pace(float(rival.get("speed", 2.6))))
					_rival_racing = true
		"dismount":
			# «Bin, sür, in» (story.md §5): taşta inilir.
			if not player.is_riding() and player.get_stance() == PlayerController.Stance.FOOT:
				_next_step()
			return
	if _phase in ["out", "race"]:
		_tick_graze()
		# Luhun taşa önce vardı: «Birinci benim!» (finish_lines.rival_first), bir kez.
		if _rival_racing and not _rival_first and not _race_said and luhun and luhun.arrived():
			_rival_first = true
			var first: Variant = (_step.get("finish_lines", {}) as Dictionary).get("rival_first")
			if first is Dictionary:
				_say(str((first as Dictionary).get("line", "")))
	if _near(goal, float(_step.get("radius", 3.0))):
		if luhun and _phase != "race":
			luhun.go(_rival_route(rival), pace(float(rival.get("speed", 2.6))))
			_rival_racing = true
		_say_race_result()
		if player.is_riding() and _step.has("dismount_objective"):
			_phase = "dismount"
			hud.set_objective(text_of(_step.get("dismount_objective")))
			hud.set_hint(text_of(_step.get("dismount_hint")))
			# Yançi çayırdan çağırır (dismount_line): sonucun sözünden sonra sırayla.
			_say(str((_step.get("dismount_line", {}) as Dictionary).get("line", "")))
			return
		_next_step()


## Binince yarış: amaç ve ipucu, Luhun'un sözü, Luhun ağıldan çıkar.
func _begin_race_out(luhun: StoryMover, rival: Dictionary) -> void:
	_phase = "out"
	hud.set_objective(text_of(_step.get("race_objective")))
	hud.set_hint(text_of(_step.get("race_hint")))
	if _step.has("race_line"):
		_say(str(_step["race_line"]))
	if luhun:
		luhun.go(points(rival.get("out", [])), pace(float(rival.get("out_speed", 1.6))))


## Yaşlı koyunun huyu (adımın mount_traits'i; story.md §5 «Yaşlısı senin, hızlısı benim»): yalnız bu koyunun binek satırı (kopya) değişir,
## sahne durunca eski satırı geri alır.
func _apply_mount_traits() -> void:
	var traits: Dictionary = _step.get("mount_traits", {})
	var ride := sheep.get(str(_step.get("mount", "old_sheep"))) as Rideable
	if traits.is_empty() or ride == null or ride.get_mount() == null or _saved_traits.has("ride"):
		return
	var mount := ride.get_mount()
	_saved_traits = {"ride": ride, "spec": mount.spec}
	var spec := mount.spec.duplicate(true)
	for key: String in traits:
		spec[key] = traits[key]
	mount.spec = spec


## Luhun'un yarış yolu: yarış yolunun ara noktaları, sonra taşın yanındaki bitişi (taşın kendisi engeldir, içinden geçilmez).
func _rival_route(rival: Dictionary) -> Array:
	var route := points(_race_path().slice(1, -1))
	route.append(point(rival.get("finish")))
	return route


func _race_path() -> Array:
	var layout: Variant = world.get(&"layout")
	if not layout is Dictionary:
		return []
	return (((layout as Dictionary).get("childhood", {}) as Dictionary).get("race", {}) as Dictionary).get("path", [])


# --- hunt: nişan ------------------------------------------------------------------------------------------

func _start_hunt() -> void:
	player.bow_prompt = true
	_update_hunt_objective()
	var spot: Dictionary = _step.get("rival_spot", {})
	var m: StoryMover = movers.get(str(spot.get("actor", "")))
	if m:
		m.go([point(spot.get("at"))], pace(float(spot.get("speed", 2.0))))
		m.face(point(spot.get("face")))
	_yanchi_state = "wait"
	_yanchi_bird = null
	_spare_said = false
	_shown = null
	_player_hits = 0
	_mouse_shot_said = false
	# Kuş ürkünce tepki sözü (flush).
	if site and site.game:
		for g: SmallGame in site.game.of_kind("lark"):
			_link(g.alarmed, _on_game_alarmed)


func _tick_hunt(delta: float) -> void:
	_tick_first_shot(delta)
	_tick_spare()
	_tick_show_target()
	if _hunt_done():
		_end_pointing()
		_next_step()


func _hunt_done() -> bool:
	var need: Dictionary = _step.get("need", {})
	for kind: String in need:
		if int(catch.get(kind, 0)) < int(need[kind]):
			return false
	return true


func _update_hunt_objective() -> void:
	var need: Dictionary = _step.get("need", {})
	var kind := str(need.keys()[0]) if not need.is_empty() else "lark"
	var want := int(need.get(kind, 0))
	hud.set_objective("%s (%d/%d)" % [text_of(_step.get("objective")), mini(int(catch.get(kind, 0)), want), want])


## Yançi ilk kuşu önce vurur: yakındaki yerdeki kuşa küt bir ok atar (ıskalarsa kuş yine düşer: söz ve sahne bozulmasın), kuşu alır.
func _tick_first_shot(delta: float) -> void:
	var fs: Dictionary = _step.get("first_shot", {})
	var m: StoryMover = movers.get(str(fs.get("actor", "")))
	var a: CineActor = actors.get(str(fs.get("actor", "")))
	if m == null or a == null or site == null or site.game == null:
		return
	match _yanchi_state:
		"wait":
			if step_clock < float(fs.get("after", 4.0)) or player.global_position.distance_to(m.position()) > float(fs.get("within", 28.0)):
				return
			var bird := _nearest_game(str(fs.get("kind", "lark")), m.position(), float(fs.get("reach", 12.0)), true)
			if bird == null:
				return
			_yanchi_bird = bird
			m.face(bird.global_position)
			var dir := (bird.global_position - m.position())
			dir.y = 0.0
			var from := m.position() + Vector3.UP * NPC_LAUNCH_UP + dir.normalized() * 0.3
			_arrows.fire(from, bird.hit_center(), {"speed": NPC_ARROW_SPEED, "arc": 0.06, "blunt": true, "drift": 0.0, "info": {"tag": "npc"}})
			_shot_clock = 0.0
			_yanchi_state = "flying"
		"flying":
			_shot_clock += delta
			if is_instance_valid(_yanchi_bird) and not _yanchi_bird.is_hittable():
				_bird_fell()
			elif _shot_clock >= SHOT_TIMEOUT:
				if is_instance_valid(_yanchi_bird) and _yanchi_bird.is_hittable():
					_yanchi_bird.hit(_yanchi_bird.hit_center())
					_reserve(_yanchi_bird)
					_bird_fell()
				else:
					_yanchi_state = "wait"
		"fall":
			if not is_instance_valid(_yanchi_bird) or _yanchi_bird.collected:
				_yanchi_state = "done"
			elif _yanchi_bird.is_down():
				var to := _yanchi_bird.global_position
				var side := m.position() - to
				side.y = 0.0
				m.go([to + side.normalized() * PICK_GAP], pace(float(fs.get("speed", 1.3))))
				_yanchi_state = "fetch"
		"fetch":
			if m.arrived():
				_pick_left = PICK_PAUSE
				m.face(_yanchi_bird.global_position)
				_yanchi_state = "pick"
		"pick":
			_pick_left -= delta
			if _pick_left <= 0.0:
				if is_instance_valid(_yanchi_bird) and _yanchi_bird.is_down():
					_yanchi_bird.collect()
				_yanchi_state = "done"


func _bird_fell() -> void:
	_reserve(_yanchi_bird)
	_yanchi_state = "fall"
	_say(str((_step.get("first_shot", {}) as Dictionary).get("line", "")))


## Yançi'nin kuşunu oyuncu alamaz: yerdeki hedeflerin grubundan çıkar (collect yine çalışır).
func _reserve(bird: SmallGame) -> void:
	if is_instance_valid(bird) and bird.is_in_group(SmallGame.FALLEN_GROUP):
		bird.remove_from_group(SmallGame.FALLEN_GROUP)


## Fareye yaklaşınca (ya da ona nişan alınınca) Luhun yayını indirir: «Yavrusu var.»
func _tick_spare() -> void:
	if _spare_said or site == null or site.game == null:
		return
	var sp: Dictionary = _step.get("spare", {})
	var kind := str(sp.get("kind", "gerbil"))
	var near := float(sp.get("near", 7.0))
	var seen: SmallGame = null
	var archer := player.archer()
	if archer and archer.is_drawing() and archer.aim_target is SmallGame and (archer.aim_target as SmallGame).kind_id == kind:
		seen = archer.aim_target
	if seen == null:
		seen = _nearest_game(kind, player.global_position, near, false)
	if seen == null:
		return
	_spare_said = true
	var m: StoryMover = movers.get(str(sp.get("actor", "")))
	if m:
		m.face(seen.global_position)
	_say(str(sp.get("line", "")))


## 90 sn'de Yançi bir kuşu gösterir: kolu kalkar, kuşun altında halka, ipucu satırı.
func _tick_show_target() -> void:
	var st: Dictionary = _step.get("show_target", {})
	if st.is_empty() or step_clock < float(st.get("after", 90.0)) or site == null or site.game == null:
		return
	if not is_instance_valid(_shown) or not _shown.is_hittable():
		_shown = _nearest_game("lark", player.global_position, 200.0, false)
	var a: CineActor = actors.get(str(st.get("actor", "")))
	var m: StoryMover = movers.get(str(st.get("actor", "")))
	if _shown == null:
		_end_pointing()
		return
	if not _pointing:
		_pointing = true
		hud.set_hint(text_of(st.get("hint")))
		# Yançi söyler (show_target.line): «Şurada! Kısa otun içinde.»
		_say(str(st.get("line", "")))
		if a:
			if st.get("gesture") is Array:
				a.gesture_turns = st["gesture"]
				if a.gesture:
					a.gesture.turns = st["gesture"]
			_tween_prop(a, ^"gesture_amount", 1.0, 0.35)
	if m and _yanchi_state in ["wait", "done"]:
		m.face(_shown.global_position)


## Yançi bir kuşu gösteriyor mu (sınama ve HUD)?
func is_pointing() -> bool:
	return _pointing


## Gösterilen kuş (yoksa null).
func shown_target() -> SmallGame:
	return _shown if is_instance_valid(_shown) else null


func _end_pointing() -> void:
	_shown = null
	if not _pointing:
		return
	_pointing = false
	var a: CineActor = actors.get(str((_step.get("show_target", {}) as Dictionary).get("actor", "")))
	if a:
		_tween_prop(a, ^"gesture_amount", 0.0, 0.3)


func _tick_ring() -> void:
	if _ring == null:
		return
	var on := is_instance_valid(_shown) and _shown.is_hittable()
	_ring.visible = on
	if on:
		var at := _shown.global_position
		_ring.global_transform = Transform3D(Basis.IDENTITY.scaled(Vector3(RING_RADIUS, 1.0, RING_RADIUS)), Vector3(at.x, _ground_y(at.x, at.z) + 0.05, at.z))


func _on_player_collected(_target: Node, res: Variant) -> void:
	if not res is Dictionary:
		return
	var kind := str((res as Dictionary).get("kind", ""))
	catch[kind] = int(catch.get(kind, 0)) + 1
	if str(_step.get("kind", "")) == "hunt":
		_update_hunt_objective()
		# Mete aldığını sayar (pick_lines): «Bir.», «İki.», «Bir fare.»
		var picks: Array = (_step.get("pick_lines", {}) as Dictionary).get(kind, [])
		var n := int(catch.get(kind, 0))
		if n >= 1 and n <= picks.size() and picks[n - 1] is Dictionary:
			_say(str((picks[n - 1] as Dictionary).get("line", "")))


func _on_player_hit(target: Node, _point: Vector3) -> void:
	if not target is SmallGame:
		return
	var game := target as SmallGame
	if game.kind_id == "gerbil":
		mouse_hit = true
		# «Yavrusu var.»dan sonra fareye değen ok: Luhun «Ama yavrusu vardı.» (spare.shot), bir kez.
		var shot: Dictionary = (_step.get("spare", {}) as Dictionary).get("shot", {})
		if _spare_said and not _mouse_shot_said and not shot.is_empty():
			_mouse_shot_said = true
			_at(step_clock + float(shot.get("after", 0.6)), _say.bind(str(shot.get("line", ""))))
	elif game.kind_id == "lark" and str(_step.get("kind", "")) == "hunt":
		_player_hits += 1
		_bark("hit")


## Oyuncunun oku hedefe değmeden yere indi (ıska): tepki sözü (miss).
func _on_player_arrow_landed(_point: Vector3) -> void:
	if str(_step.get("kind", "")) == "hunt":
		_bark("miss")


## Tarla kuşu ürktü: oyuncuya yakınsa tepki sözü (flush; Yançi'nin kuşu sayılmaz).
func _on_game_alarmed(target: SmallGame) -> void:
	if str(_step.get("kind", "")) != "hunt" or target == _yanchi_bird or not is_instance_valid(target):
		return
	if _flat(target.global_position, player.global_position) <= float(_step.get("flush_near", 10.0)):
		_bark("flush")


func _on_npc_hit(target: Node, _point: Vector3) -> void:
	if target is SmallGame:
		_yanchi_bird = target
		_reserve(_yanchi_bird)


# --- count: sayım ------------------------------------------------------------------------------------------

func _start_count() -> void:
	if bool(_step.get("drive_herd", false)) and site:
		site.drive_herd()
	_herd_counted = false
	_beat_started = false
	_wait_said = false
	for c: Variant in _step.get("children", []):
		var m: StoryMover = movers.get(str((c as Dictionary).get("actor", "")))
		if m:
			m.go(points((c as Dictionary).get("path", [])), pace(float((c as Dictionary).get("speed", 2.0))))
	_phase = "arrive"


func _tick_count(delta: float) -> void:
	var goal := point(_step.get("goal"))
	var radius := float(_step.get("radius", 2.8))
	_tick_turn(delta)
	_tick_column(delta)
	match _phase:
		"arrive":
			if _near(goal, radius):
				_phase = "wait"
				hud.set_objective(text_of(_step.get("wait_objective")))
				_start_wait_lines()
				_start_beat()
				_try_count()
		"wait":
			if not _near(goal, radius * 2.0):
				_phase = "arrive"
				hud.set_objective(text_of(_step.get("objective")))
			else:
				_try_count()
		"settle":
			# Söz sırası oyuncu yayayken ve önceki söz bitince başlar (atlıların zamanı bunu hesaba katar: _begin_exchange).
			if player.get_stance() == PlayerController.Stance.FOOT and (voice == null or voice.is_free()):
				_turn_player(_actor_pos(str((_step.get("counter", {}) as Dictionary).get("actor", "counter"))))
				_phase = "exchange"
				_seq_i = -1
				_seq_left = LINE_GAP
		"exchange":
			_seq_left -= delta
			if _seq_left <= 0.0:
				_next_exchange_line()
		"pass":
			if column == null or column.at_pass():
				_begin_gaze()
		"gaze":
			gaze_seconds += delta
			_gaze_left -= delta
			_face_children_to_leader()
			if _gaze_left <= 0.0:
				_end_gaze()
		"leave":
			_face_children_to_leader()
			_end_left -= delta
			if _end_left <= 0.0:
				# «Beni gördü.»: görüntü söz bitince durur (en az END_HOLD).
				var said_for := _say(str((_step.get("gaze", {}) as Dictionary).get("line", "")))
				_phase = "end"
				_end_left = maxf(END_HOLD, said_for)
		"end":
			_end_left -= delta
			if _end_left <= 0.0:
				_phase = "fade"
				_freeze()
				var sec := float(_step.get("freeze_fade", 1.4))
				if fade_rect:
					var t := _tween()
					t.tween_property(fade_rect, ^"color:a", 1.0, sec).set_trans(Tween.TRANS_SINE)
					t.tween_callback(func() -> void:
						_phase = "black"
						_end_left = BLACK_HOLD)
				else:
					_phase = "black"
					_end_left = sec
		"black":
			_end_left -= delta
			if _end_left <= 0.0:
				_phase = "done"
				_finish()


func _counted() -> bool:
	if _herd_counted:
		return true
	var herd := site.herd if site else null
	return herd == null or herd.phase() == HerdSim.Phase.COUNTED


## Sayım başlayabilir mi: sürü sayıldı, saat vakitte (görünür akış bitti)?
func _try_count() -> void:
	if not _counted():
		return
	if game_clock and game_clock.minute < beat_minute() - 0.001:
		# Sürü sayıldı ama saat geride: kalan akış hızla kapanır (ya da yeni başlar).
		var final_s := float((_step.get("beat", {}) as Dictionary).get("lapse_final_s", LAPSE_FINAL_S))
		if not game_clock.is_lapsing():
			_lapse_to_beat(_final_lapse_seconds())
		elif game_clock.lapse_left() > final_s:
			_lapse_to_beat(final_s)
		return
	if game_clock and game_clock.is_lapsing():
		return
	_begin_exchange()


## Oyuncu hatta vardı: saat vaktin gerisindeyse görünür akış sürünün kalan sayım süresine yayılır (kalabalık bu sırada toplanır).
func _start_beat() -> void:
	if _beat_started or game_clock == null:
		return
	_beat_started = true
	if game_clock.minute >= beat_minute() - 0.001:
		return
	if _counted():
		_lapse_to_beat(_final_lapse_seconds())
		return
	var beat: Dictionary = _step.get("beat", {})
	var eta := site.herd.count_eta() if site and site.herd else 0.0
	var seconds := clampf(eta, float(beat.get("lapse_min_s", LAPSE_MIN_S)), float(beat.get("lapse_max_s", LAPSE_MAX_S)))
	_lapse_to_beat(maxf(seconds, _final_lapse_seconds()))


## Sürü sayıldıktan sonra kalan akışın süresi: lapse_speed oyun dk/sn hızla, en az lapse_min_s, en çok lapse_final_s.
func _final_lapse_seconds() -> float:
	var beat: Dictionary = _step.get("beat", {})
	var gap := maxf(beat_minute() - minute(), 0.0)
	return clampf(gap / maxf(float(beat.get("lapse_speed", LAPSE_SPEED)), 0.1), float(beat.get("lapse_min_s", LAPSE_MIN_S)),
		float(beat.get("lapse_final_s", LAPSE_FINAL_S)))


func _lapse_to_beat(seconds: float) -> void:
	if game_clock == null:
		return
	game_clock.begin_lapse(GameClock.abs_of(game_clock.day_n, beat_minute()), seconds, &"beat")


## Söz sırası başlar: oyuncu durur (binekteyse iner), saat durur, Teoman ve beyleri hattın ucundan gelmeye başlar. Beklemenin isteğe bağlı sözleri
## düşer; çalan söz biterken söz sırası açılır, atlılar o payla geç kalkar.
func _begin_exchange() -> void:
	_phase = "settle"
	if game_clock:
		game_clock.end_lapse()
		game_clock.pause(&"dialogue", true)
	player.set_active(false)
	hud.set_objective("")
	hud.set_hint("")
	if player.is_riding():
		player.begin_dismount()
	var lead := 0.0
	if voice:
		voice.drop_optional()
		lead = voice.remaining()
	_start_procession(lead + _exchange_seconds() + 0.6)


## Söz sırasının beklenen süresi (sn): satırlar (sesliyse sesin süresi), sözsüz sayımlar ve aralar.
func _exchange_seconds() -> float:
	var total := LINE_GAP
	for e: Variant in _step.get("exchange", []):
		var entry: Dictionary = e
		if entry.has("line"):
			var line := str(entry["line"])
			if entry.has("spared_line") and int(catch.get("gerbil", 0)) <= 0:
				line = str(entry["spared_line"])
			total += line_seconds(line) + LINE_GAP
		else:
			total += float(entry.get("pause", 0.8))
		var pre := _exchange_before(entry, false)
		if not pre.is_empty():
			total += line_seconds(pre) + LINE_GAP
	return total


## E21 (Ç2, K110): söz sırası girdisinin önündeki koşullu söz (before: {line, by, if, item, take}). Koşul has_stick (has_item): item heybede
## (inventory). take: söz başlarken eşya heybeden düşer (sayım günü: Mete Hereka'nın çetelesini sayıcıya verir, «Bir çocuk.»tan önce
## «Hereka'nın çentikleri. Yedi.»). Döner: söylenecek anahtar ya da "" (koşul tutmuyor: bugünkü sıra aynen akar).
func _exchange_before(e: Dictionary, apply: bool) -> String:
	var pre: Variant = e.get("before")
	if not pre is Dictionary:
		return ""
	var item := str((pre as Dictionary).get("item", ""))
	if str((pre as Dictionary).get("if", "")) in ["has_stick", "has_item"] and (inventory == null or item.is_empty() or not inventory.has(item)):
		return ""
	if apply and bool((pre as Dictionary).get("take", false)) and inventory and not item.is_empty():
		inventory.remove(item, 1)
	return str((pre as Dictionary).get("line", ""))


func _next_exchange_line() -> void:
	var seq: Array = _step.get("exchange", [])
	_seq_i += 1
	if _seq_i >= seq.size():
		_begin_pass()
		return
	var e: Dictionary = seq[_seq_i]
	if _seq_pre != _seq_i:
		# E21: girdinin önündeki koşullu söz (before) önce; girdi sonra kendi sözüyle yeniden gelir.
		var pre := _exchange_before(e, true)
		if not pre.is_empty():
			_seq_pre = _seq_i
			_seq_i -= 1
			var pre_by := str((e["before"] as Dictionary).get("by", e.get("by", "")))
			if movers.has(pre_by):
				(movers[pre_by] as StoryMover).face(player.global_position)
			_seq_left = _say(pre) + LINE_GAP
			return
	var by := str(e.get("by", ""))
	var face_id := str(e.get("face", ""))
	if not by.is_empty() and movers.has(by):
		(movers[by] as StoryMover).face(_actor_pos(face_id) if movers.has(face_id) else player.global_position)
	if bool(e.get("notch", false)):
		_notch()
	if not e.has("line"):
		# Sözsüz sayım: sayıcı çocuğa döner, çentik atar.
		_seq_left = float(e.get("pause", 0.8))
		return
	var line := str(e.get("line", ""))
	if e.has("spared_line") and int(catch.get("gerbil", 0)) <= 0:
		line = str(e["spared_line"])
	_seq_left = _say(line) + LINE_GAP


## Atlılar yolda (sayım adımının procession'ı): Teoman önde, beyler düzeninde; söz sırası biterken geçiş noktasına varacak yerden başlar.
func _start_procession(seconds: float) -> void:
	if column != null:
		return
	var proc: Dictionary = _step.get("procession", {})
	# Söz sırası atlıların görünür gelişinden (approach_s) uzunsa atlılar gizli bekler, söz sırasının son approach_s saniyesinde yola çıkar:
	# hattın ucundan gelir, geçiş noktasına söz biterken varır (E20/7: sesli söz sırası uzadı).
	var approach := float(proc.get("approach_s", 0.0))
	if approach > 0.0 and seconds > approach + 0.05:
		_at(step_clock + seconds - approach, _start_procession.bind(approach))
		return
	var leader_id := str(proc.get("leader", (_step.get("gaze", {}) as Dictionary).get("actor", "teoman")))
	var lead: StoryMover = movers.get(leader_id)
	if lead == null or proc.is_empty():
		return
	var pts := PackedVector2Array()
	for p: Variant in proc.get("path", []):
		var at := point(p)
		if at != Vector3.INF:
			pts.append(Vector2(at.x, at.z))
	column = RiderColumn.new(pts, _shape())
	var speeds: Dictionary = proc.get("speeds", {})
	column.approach = float(speeds.get("approach", RiderColumn.APPROACH))
	column.pass_speed = float(speeds.get("pass", RiderColumn.PASS))
	column.leave = float(speeds.get("leave", RiderColumn.LEAVE))
	column.accel = float(proc.get("accel", RiderColumn.ACCEL))
	column.add(lead, Vector2.ZERO)
	_column_driven[leader_id] = true
	for e: Dictionary in escort:
		var slot: Array = e.get("slot", [0.0, 3.0])
		column.add(e["mover"], Vector2(float(slot[0]), float(slot[1])))
	# Atlı da oyuncudan hızlı gitmez (E20): kıvrımın dışındaki bey liderden hızlıdır, üç hız onunla birlikte sınırda kalır.
	column.limit_speeds(speed_cap())
	var child := player.global_position
	column.pass_at = column.closest_offset(Vector2(child.x, child.z)) - float(proc.get("lead", 2.5))
	column.start(maxf(column.start_offset_for(seconds), 0.0))
	_set_present(leader_id, true)
	for e: Dictionary in escort:
		_show_rider(e["mover"], true)
	# Sürü atlılara da yol verir (oyuncu, binilen koyunlar ve kişilerle birlikte).
	if site and site.herd:
		var avoid: Array[Node3D] = [player]
		for s: Variant in sheep.values():
			if s is Node3D:
				avoid.append(s)
		for a: Variant in actors.values():
			avoid.append(a as Node3D)
		for h: Variant in horses.values():
			avoid.append(h as Node3D)
		site.herd.set_avoid_nodes(avoid)


func _tick_column(delta: float) -> void:
	# Görüntü durunca atlılar ve odak da durur.
	if column == null or _frozen:
		return
	column.tick(delta)
	var lead := column.leader()
	if lead == null:
		return
	var at := lead.position()
	if site:
		site.watch_crowd(at)
	if not _focus_on and _phase in ["exchange", "pass", "gaze"] and _flat(at, player.global_position) <= float((_step.get("gaze", {}) as Dictionary).get("focus_from", FOCUS_FROM)):
		_start_focus()
	if _focus_on:
		_update_focus(at, delta)


## Atlılar yaklaşırken odak Mete ile Teoman'ın ortasına kayar (Mete karede kalır: en çok FOCUS_MAX_SHIFT), kamera 26 m'ye açılır: uzak kare (K98).
func _start_focus() -> void:
	if camera == null or _focus == null:
		return
	_focus_on = true
	_focus.global_position = player.global_position
	camera.target = _focus
	_camera_distance = float((_step.get("gaze", {}) as Dictionary).get("camera_distance", FollowCamera.CHILD_DISTANCE))
	camera.zoom_by(_camera_distance - camera.get_target_distance())


func _update_focus(leader_at: Vector3, delta: float) -> void:
	var want := RiderColumn.midpoint_focus(player.global_position, leader_at, FOCUS_MAX_SHIFT) if column else player.global_position
	_focus.global_position = _focus.global_position.lerp(want, 1.0 - exp(-FOCUS_SHARPNESS * delta))


## Söz sırası bitti: saat sinema gibi durur; atlılar geçiş noktasına varınca bakış başlar.
func _begin_pass() -> void:
	_phase = "pass"
	if game_clock:
		game_clock.pause(&"cine", true)
		game_clock.pause(&"dialogue", false)
	if column == null:
		_start_procession(0.0)
	if not _focus_on:
		_start_focus()


## Teoman'ın dört saniyelik bakışı: atlılar adımla geçer (durmaz), Teoman'ın omurgası ve başı Mete'ye döner, Mete ona döner.
func _begin_gaze() -> void:
	var gaze: Dictionary = _step.get("gaze", {})
	_gaze_left = float(gaze.get("seconds", 4.0))
	gaze_seconds = 0.0
	_phase = "gaze"
	if column:
		column.look = player.global_position + Vector3.UP * 0.9
		_tween_prop(column, ^"look_amount", 1.0, LOOK_IN)
	var lead_at := column.leader().position() if column and column.leader() else _actor_pos(str(gaze.get("actor", "teoman")))
	_turn_player(lead_at)
	if not _focus_on:
		_start_focus()


func _end_gaze() -> void:
	_phase = "leave"
	_end_left = float((_step.get("gaze", {}) as Dictionary).get("saw_me_after", 1.8))
	if column:
		column.release()
		_tween_prop(column, ^"look_amount", 0.0, LOOK_OUT)


## Çocuklar ve sayıcı Teoman'a döner (kalabalık da: ChildhoodSite.watch_crowd).
func _face_children_to_leader() -> void:
	if column == null or column.leader() == null:
		return
	var at := column.leader().position()
	for c: Variant in _step.get("children", []):
		var m: StoryMover = movers.get(str((c as Dictionary).get("actor", "")))
		if m:
			m.face(at)
	var counter: StoryMover = movers.get(str((_step.get("counter", {}) as Dictionary).get("actor", "counter")))
	if counter:
		counter.face(at)
	if _turn_t >= 1.0 and _phase == "leave":
		var yaw := CampNpcs.facing_yaw(player.global_position, at)
		if not is_nan(yaw) and absf(angle_difference(player.get_facing_yaw(), yaw)) > deg_to_rad(25.0):
			_turn_player(at)


func _on_sheep_counted(_index_: int, _tally: int) -> void:
	if str(_step.get("kind", "")) == "count" and _phase in ["arrive", "wait", ""]:
		_notch()


func _on_count_finished(_total: int) -> void:
	_herd_counted = true


## Sayıcının çentiği: kol kalkar iner, ince bir çentik sesi.
func _notch() -> void:
	var cdef: Dictionary = _step.get("counter", {})
	var a: CineActor = actors.get(str(cdef.get("actor", "counter")))
	if a:
		var t := _tween()
		t.tween_property(a, ^"gesture_amount", 1.0, 0.16)
		t.tween_property(a, ^"gesture_amount", 0.0, 0.3)
	var notch: Dictionary = cdef.get("notch", {})
	if not notch.is_empty():
		_audio(&"play_sfx", [StringName(str(notch.get("sfx", "notch"))), {"db": float(notch.get("db", -26.0)), "pitch": randf_range(0.96, 1.04)}])


func _turn_player(point_at: Vector3) -> void:
	var yaw := CampNpcs.facing_yaw(player.global_position, point_at)
	if is_nan(yaw):
		return
	_turn_from = player.get_facing_yaw()
	_turn_to = yaw
	_turn_t = 0.0


func _tick_turn(delta: float) -> void:
	if _turn_t >= 1.0:
		return
	_turn_t = minf(_turn_t + delta / TURN_SECONDS, 1.0)
	player.spawn_at(player.global_position, lerp_angle(_turn_from, _turn_to, smoothstep(0.0, 1.0, _turn_t)))


## «Beni gördü.»: görüntü durur (dünya ve oyuncu donar; kamera, yazı ve perde sürer).
func _freeze() -> void:
	if _frozen:
		return
	_frozen = true
	_saved_world_process = world.process_mode
	_saved_player_process = player.process_mode
	world.process_mode = Node.PROCESS_MODE_DISABLED
	player.process_mode = Node.PROCESS_MODE_DISABLED


func _unfreeze() -> void:
	if not _frozen:
		return
	_frozen = false
	if is_instance_valid(world):
		world.process_mode = _saved_world_process
	if is_instance_valid(player):
		player.process_mode = _saved_player_process


func _finish() -> void:
	if _done:
		return
	_done = true
	_running = false
	finished.emit(result())


# --- Söz, saat, ses -------------------------------------------------------------------------------------------

## Satırı söyler (SceneVoice): sesi varsa Voice yolunda çalar, altyazı sesin süresi kadar durur; konuşulurken gelen söz sıraya girer. ok söz
## başlarken sorulur (false: söz düşer); optional söz sırası başlarken bırakılır. Döner: sözün bitişine kalan süre (sn; sıradaysa bekleme de içinde).
func _say(line_id: String, ok: Callable = Callable(), optional := false) -> float:
	if voice == null or not (data.get("lines", {}) as Dictionary).has(line_id):
		return 0.0
	return voice.say(line_id, ok, optional)


## Söz başlar (SceneVoice.show): konuşanın adıyla altyazı, söylenenler, said.
func _show_line(line_id: String, seconds: float) -> void:
	var line: Dictionary = (data.get("lines", {}) as Dictionary).get(line_id, {})
	var text := text_of(line)
	var speaker := text_of((data.get("speakers", {}) as Dictionary).get(str(line.get("speaker", ""))))
	if hud:
		hud.say(speaker, text, seconds, clock)
	said_lines.append(line_id)
	said.emit(line_id)


## Satırın süresi (sn): sesliyse sesin bitişine dek (ana sözün payı dahil), değilse altyazının okuma süresi.
func line_seconds(line_id: String) -> float:
	return voice.length(line_id) if voice else StoryHud.line_seconds(line_text(line_id))


## Konuşanın ekrandaki yeri (−0,3..0,3): kişi kameranın sağındaysa ses biraz sağdan gelir (uzak kare, K98); Mete ve bilinmeyen ortada.
func _pan_of(line_id: String) -> float:
	var line: Dictionary = (data.get("lines", {}) as Dictionary).get(line_id, {})
	var m: StoryMover = movers.get(str(line.get("speaker", "")))
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if m == null or cam == null or cam.is_position_behind(m.position()):
		return 0.0
	var size := get_viewport().get_visible_rect().size
	if size.x <= 0.0:
		return 0.0
	return clampf((cam.unproject_position(m.position()).x / size.x - 0.5) * 0.6, -0.3, 0.3)


## Tepki sözü (K61 C; verinin barks'ı): olayın koşulu tutan çeşitleri arasından SceneVoice seçer; konuşulurken düşer.
func _bark(event: String) -> void:
	if voice == null:
		return
	var entries: Array = []
	for e: Variant in (data.get("barks", {}) as Dictionary).get(event, []):
		if e is Dictionary and _bark_allowed(str((e as Dictionary).get("when", ""))):
			entries.append(e)
	voice.bark(event, entries)


## Tepki sözünün koşulu: yanchi_shot (Yançi'nin kuşu düştü), first_hit (oyuncunun ilk vuruşu); boş koşul hep tutar.
func _bark_allowed(when: String) -> bool:
	match when:
		"":
			return true
		"yanchi_shot":
			return _yanchi_state in ["fall", "fetch", "pick", "done"]
		"first_hit":
			return _player_hits == 1
	return false


## Hatta varınca beklemenin sözleri (wait_lines): sırayla, bekleme sürüyorsa; optional olanlar söz sırası başlayınca düşer.
func _start_wait_lines() -> void:
	if _wait_said:
		return
	_wait_said = true
	for w: Variant in _step.get("wait_lines", []):
		var entry: Dictionary = w
		var cond := str(entry.get("if", ""))
		var ok := func() -> bool: return _phase == "wait" and _wait_condition(cond)
		_at(step_clock + float(entry.get("after", 0.0)), _say.bind(str(entry.get("line", "")), ok, bool(entry.get("optional", false))))


## Beklemenin sözünün koşulu: spared_seen (Luhun «Yavrusu var.» dedi, fare vurulmadı); boş koşul hep tutar.
func _wait_condition(cond: String) -> bool:
	match cond:
		"":
			return true
		"spared_seen":
			return _spare_said and not mouse_hit
	return false


## Satırın şimdiki dildeki metni (saf yardımcı).
func line_text(line_id: String) -> String:
	return text_of((data.get("lines", {}) as Dictionary).get(line_id))


func _at(t: float, fn: Callable) -> void:
	_queue.append([t, fn])


func _tick_queue() -> void:
	var i := 0
	while i < _queue.size():
		if step_clock >= float(_queue[i][0]):
			var fn: Callable = _queue[i][1]
			_queue.remove_at(i)
			fn.call()
		else:
			i += 1


## Işık ve kalabalık saati izler: kalabalık her kare (yürüyen kart takılmasın), ışık 4 Hz, görünür akışta her kare (gölge sıçramasın).
func _tick_clock(delta: float) -> void:
	if world and world.has_method(&"set_crowd_minute"):
		world.call(&"set_crowd_minute", minute())
	if site and site.crowd:
		# Kalabalık saatin görünür akışında yetişmek için koşmaz (E20): oyuncunun koşusu sınırdır.
		site.crowd.speed_cap = speed_cap()
	_clock_left -= delta
	if _clock_left > 0.0 and not (game_clock and game_clock.is_lapsing()):
		return
	_clock_left = CLOCK_TICK
	_write_light()


func _write_light() -> void:
	if world and world.has_method(&"set_childhood_time"):
		world.call(&"set_childhood_time", minute())


func _start_audio() -> void:
	var music: Dictionary = data.get("music", {})
	if not music.is_empty():
		_audio(&"set_music_bank", [str(music.get("bank", "")), StringName(str(music.get("state", ""))), float(music.get("fade", 2.0))])
	var ambience: Dictionary = data.get("ambience", {})
	for id: String in ambience:
		_audio(&"set_ambience_layer", [StringName(id), float(ambience[id]), 3.0])


func _audio(method: StringName, args: Array) -> void:
	var audio := get_node_or_null(^"/root/AudioManager")
	if audio and audio.has_method(method):
		audio.callv(method, args)


func _connect_signals() -> void:
	_link(player.target_collected, _on_player_collected)
	if player.archer() and player.archer().field:
		_link(player.archer().field.target_hit, _on_player_hit)
		_link(player.archer().field.arrow_landed, _on_player_arrow_landed)
	_link(_arrows.target_hit, _on_npc_hit)
	if site and site.herd:
		_link(site.herd.sheep_counted, _on_sheep_counted)
		_link(site.herd.count_finished, _on_count_finished)


func _link(sig: Signal, fn: Callable) -> void:
	if not sig.is_connected(fn):
		sig.connect(fn)
		_connections.append([sig, fn])


func _tween() -> Tween:
	var t := create_tween()
	_tweens.append(t)
	return t


func _tween_prop(obj: Object, prop: NodePath, value: Variant, sec: float) -> void:
	_tween().tween_property(obj, prop, value, sec).set_trans(Tween.TRANS_SINE)


# --- Yardımcılar --------------------------------------------------------------------------------------------

## Dilin metni: {tr, en} sözlüğü (dilde yoksa TR) ya da düz yazı.
func text_of(entry: Variant) -> String:
	if entry is Dictionary:
		var d: Dictionary = entry
		return str(d.get(lang, d.get("tr", "")))
	return str(entry) if entry != null else ""


## Yer: işaret kimliği (OrdosWorld.marker) ya da [x, z]; zemine oturur. Bilinmiyorsa Vector3.INF.
func point(spec: Variant) -> Vector3:
	if spec is String and world and world.has_method(&"marker"):
		var at: Variant = world.call(&"marker", spec)
		return at if at is Vector3 else Vector3.INF
	if spec is Array and (spec as Array).size() >= 2:
		var x := float(spec[0])
		var z := float(spec[1])
		return Vector3(x, _ground_y(x, z), z)
	if spec is Vector3:
		return spec
	return Vector3.INF


func points(list: Variant) -> Array:
	var out: Array = []
	if list is Array:
		for p: Variant in list:
			var at := point(p)
			if at != Vector3.INF:
				out.append(at)
	return out


func _actor_pos(id: String) -> Vector3:
	var m: StoryMover = movers.get(id)
	return m.position() if m else player.global_position


func _near(at: Vector3, radius: float) -> bool:
	if at == Vector3.INF:
		return false
	return Vector2(player.global_position.x - at.x, player.global_position.z - at.z).length() <= radius


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## Türün from'a en yakın vurulabilir hayvanı (on_ground: yalnız yerde, uçmayan); Yançi'nin kuşu sayılmaz.
func _nearest_game(kind: String, from: Vector3, max_distance: float, on_ground: bool) -> SmallGame:
	if site == null or site.game == null:
		return null
	var best: SmallGame = null
	var best_d := max_distance
	for a: SmallGame in site.game.of_kind(kind):
		if a == _yanchi_bird or not a.is_hittable() or (on_ground and a.state > SmallGame.State.WALK):
			continue
		var d := Vector2(a.global_position.x - from.x, a.global_position.z - from.z).length()
		if d <= best_d:
			best_d = d
			best = a
	return best


func _shape() -> RefCounted:
	return world.call(&"get_terrain_shape") if world and world.has_method(&"get_terrain_shape") else null


func _ground_y(x: float, z: float) -> float:
	var shape := _shape()
	return float(shape.call(&"height_at", x, z)) if shape else 0.0


func _make_ring() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "TargetRing"
	mi.top_level = true
	mi.visible = false
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.mesh = Procedural3D.torus(0.9, 1.0)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = RING_COLOR
	mat.no_depth_test = true
	mi.material_override = mat
	return mi
