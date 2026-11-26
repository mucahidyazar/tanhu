class_name DepartScene
extends Node
## Yola Çıkış (mq0_depart; K6, K37, K58, K61, K67, K98, K99; story.md §6, docs-app story/childhood «Yola Çıkış»): 15 Aralık MÖ 213, şafaktan
## önce, Tanhu Kampı. Oyuncu oluşturucuda yaptığı 20 yaşındaki Mete'dir (main.gd: PlayerController.use_profile). Veri
## data/story/departure/scene.json'dadır; dünya depart_yurt'tur (DepartWorld). Adımlar dosyadaki sırayla akar, kind'ı buradaki işleyicidir:
##   hang      yurt: oyuncu beşiğe yürür, E (accept) ile kendi yayını küçüğün yanına asar: Mete eğilir, yay elinden kemere geçer (CineBow;
##             DepartWorld.hang_transform); Yançi «Yay burada kalır, ben gererim. Sen git, sayılmaya.» der.
##   farewell  avlu: Huyan Hatun kapısında el sallar, Gutu kucağında; oyuncu Eskam'a varınca durur, Eskam «Evladım, yol uzun. Ben her kış
##             gelirim.» der ve arabasına yürür; kamera Teoman'ın kapalı kapısına kayar, uzak karede dört saniye durur, oyuncuya döner.
##   mount     at: Mete'nin atı binilir olur (DepartWorld.lock_horse); oyuncu yaklaşınca Lan Hatun dizginleri uzatır, «Kırk iki gün yol.»;
##             E ile ata biner (PlayerController). Sonra atı kendisi sürer (E20, 2026-11-08: «at ile biraz yol almalıydı»): kamptan batıya
##             giden yolda, kampın son yurtlarının ve çitin ötesindeki eşiğe dek (adımın ride'ı: amaç «Batı yoluna sür», HUD'un yönü eşik;
##             uyuyan kampta at dörtnala kalkmaz, Shift tırıstır: mount_traits). Eşikte girdi bırakılır, at adımla yürür; kamera arkada
##             kalan kampa döner (look_back: uzak kare, K98), perde kararır, finished(sonuç) yayılır. Atından inen oyuncuya amaç «Atına bin».
## Sözler seslidir (E20/7; K61): SceneVoice (voice) satırı vo_lines.json'daki vo_prefix + anahtar kimliğiyle çalar, altyazı sesin süresi kadar durur,
## sözü bekleyen evreler (Eskam'ın sözü) sesin bitişini bekler, konuşulurken gelen söz sıraya girer (dosyası yoksa altyazıyla akar, K89). Adımın söz
## kancaları: intro_line (Yançi «Şşş. Yeni uyudu.», Eskam «Gel evladım»), leave_lines (yurdun kapısından çıkınca Huyan Hatun), reply_lines (dizginde
## Mete'nin cevabı ve Lan Hatun), ride.intro_line (binişten 2 sn sonra avludan Eskam: «Sen sür evladım, araba ardından yetişir.»). Teoman'ın kapısındaki dört saniye bilerek sözsüzdür. Kamera K98 kadrajındadır: takip kamerası 28 m; kapı bakışında odak kapıya kayar, uzak kare. Yurdun
## çatısı oyuncu içerideyken kalkar (DepartWorld.HomeYurt). Kişiler CineActor'dır: kendi Meshy modeli yoksa StandIn yer tutucusu
## kendiliğinden çıkar (actor_root sınamada sahte klasör verir). Oyun içi HUD bu nesneyi ChildhoodScene gibi okur: hud_quest() ve
## hud_target(oyuncunun_yeri). Kayıt yoktur: bitince yolculuğa yalnız işaret yazdırır (main.gd, finished'ın flags'i).
##   var scene := DepartScene.new()
##   scene.setup(world, player, follow_camera, $UI, $UI/Fade, hud, $UI/Fade)
##   add_child(scene); await scene.prepare(); scene.begin()          # begin("yard"): o adımdan (geliştirme, sınama)
##   var result: Dictionary = await scene.finished                     # {flags, bow_hung, mounted}
##   scene.stop()                                                      # her durumda: yazılar, engeller, kamera, sesler geri

signal prepared
signal step_started(step_id: String)
signal said(line_id: String)
signal finished(result: Dictionary)

const SCENE_PATH := "res://data/story/departure/scene.json"
## Kişilerin dünyadaki düğümü.
const ROOT_NAME := "Story"
## Kişilerin ısıtılan klipleri.
const ACTOR_ROLES: Array[StringName] = [&"idle", &"walk"]
## Duran kişinin oyuncuya engel yarıçapı (m).
const SOLID_RADIUS := 0.32
## Söz araları ve oyuncunun dönüşü (sn).
const LINE_GAP := 0.4
const TURN_SECONDS := 0.5
## Asışın evreleri (hang_seconds'ın payı): eğilme biter, yay elden kemere geçer, doğrulma başlar.
const HANG_BEND := 0.38
const HANG_MOVE := 0.62
const HANG_RISE := 0.72
## Eskam'ın arabasına yürüyüşü (m/sn) ve kapı bakışı biterken oyuncuya dönüş.
const ESKAM_WALK := 1.0
## Kucaktaki çocuğun taşıyana göre yeri (taşıyanın yerel uzayı: +x sol, +z ön; y kemiğin yüksekliğine eklenir) ve dönüşü (derece).
const CARRY_OFFSET := Vector3(0.2, -0.32, 0.16)
const CARRY_YAW_DEG := 28.0
const CARRY_BONES: Array[String] = ["Spine01", "Spine", "Hips"]
## El sallamanın en düşük ve en yüksek etkisi.
const WAVE_RANGE := Vector2(0.72, 1.0)
## Sürüşün sonunda arkada kalan kampa bakış (K98 uzak kare; verisi adımın ride.look_back'i): eğim (derece), uzaklık (m), geçiş (sn), kameranın
## dönüş yumuşaklığı (FollowCamera.rotate_sharpness; küçük = yavaş), odağın kampa doğru en çok kayışı (m) ve izleme keskinliği.
const LOOK_BACK_PITCH := 38.0
const LOOK_BACK_DISTANCE := 40.0
const LOOK_BACK_BLEND := 2.0
const LOOK_BACK_TURN := 1.5
const LOOK_BACK_SHIFT := 6.0
const LOOK_BACK_SHARPNESS := 2.0
## Eşiğin yanal yarı genişliği (m): yolun iki yanında bu kadar içinde eşik geçilmiş sayılır.
const THRESHOLD_HALF_WIDTH := 30.0
## İç ortam seslerinin yoklama aralığı (sn).
const INSIDE_TICK := 0.25

var data: Dictionary = {}
## Sol üstteki sade amaç bloğu (StoryHud) görünsün mü? Oyun içi HUD'un görev kartı onun yerine geçince main.gd kapatır.
var objective_box := true
var world: DepartWorld
var player: PlayerController
var camera: FollowCamera
var game_hud: GameHud
var fade_rect: ColorRect
var hud: StoryHud
var lang := "tr"
## Kişilerin klasörü (StandIn; sınama sahte bir klasörle yer tutucuyu sınar).
var actor_root := StandIn.ROOT
## Sahnenin ve adımın saati (sn).
var clock := 0.0
var step_clock := 0.0
var said_lines := PackedStringArray()
var actors: Dictionary = {}
var bow_hung := false
var mounted := false
## Sahnenin sözü (SceneVoice; E20/7): ses ve sıra.
var voice: SceneVoice

var _ui_parent: Node
var _below: Node
var _root: Node3D
var _focus: Node3D
var _index := -1
var _step: Dictionary = {}
var _phase := ""
var _queue: Array = []
var _running := false
var _stopped := false
var _done := false
var _saved_obstacles: Array[Vector3] = []
var _tweens: Array[Tween] = []
var _movers: Dictionary = {}
var _carried: Dictionary = {}
var _waving: Array[String] = []
var _prompting := false
var _turn_from := 0.0
var _turn_to := 0.0
var _turn_t := 1.0
var _hang_gesture: CineBow
var _hand_from := Transform3D.IDENTITY
var _phase_left := 0.0
var _inside_left := 0.0
var _inside := -1
var _ride_input := Vector2.ZERO
var _camera_distance := 0.0
var _wave_rate := 1.7
## Sürüş: binişten eşiğe süre (sn) ve yol (m) (otomatik oynatma ve sınama okur); oyuncu atta mı (amaç değişince).
var ride_seconds := 0.0
var ride_distance := 0.0
var _ride_last := Vector3.INF
var _ride_on_horse := true
## Sürüşte değiştirilip sahne durunca geri alınanlar: oyuncunun alanı, atın satırı, kameranın ön ayarı ve dönüş yumuşaklığı.
var _saved_area: Array = []
var _saved_traits: Dictionary = {}
var _look_preset: CameraPreset
var _saved_turn := -1.0
var _look_toward := Vector3.INF
## Avluda yurdun kapısından çıkınca söylenenler (leave_lines) söylendi mi?
var _leave_said := false


## Bağlam: dünya (DepartWorld), oyuncu, takip kamerası, yazıların konacağı düğüm ve onun altında kalacağı düğüm (perde), hareket ipucunun
## paneli, kara perde. Ağaca eklenmeden önce çağrılır.
func setup(p_world: DepartWorld, p_player: PlayerController, p_camera: FollowCamera, ui_parent: Node, below: Node = null,
		p_game_hud: GameHud = null, p_fade: ColorRect = null) -> void:
	world = p_world
	player = p_player
	camera = p_camera
	_ui_parent = ui_parent
	_below = below
	game_hud = p_game_hud
	fade_rect = p_fade
	if data.is_empty():
		data = load_data()
	lang = SubtitleBar.ui_lang()
	voice = SceneVoice.new()
	voice.prefix = str(data.get("vo_prefix", ""))
	voice.gap = LINE_GAP
	voice.show = _show_line
	voice.text_seconds = func(key: String) -> float: return StoryHud.line_seconds("%s: %s" % [_speaker_name(key), line_text(key)])
	voice.pan_of = _pan_of


# --- Veri ------------------------------------------------------------------------------------------------

## Sahnenin verisi (okunamazsa boş).
static func load_data(path: String = SCENE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("[depart] sahne verisi yok: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func step_ids(d: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	for s: Variant in d.get("steps", []):
		if s is Dictionary:
			out.append(str((s as Dictionary).get("id", "")))
	return out


## Verinin sorunları (saf): adımların türü, satırların iki dili ve konuşanı, kişilerin kimliği.
static func validate(d: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	var lines: Dictionary = d.get("lines", {})
	var speakers: Dictionary = d.get("speakers", {})
	for id: String in lines:
		var line: Dictionary = lines[id]
		for key in ["tr", "en"]:
			if str(line.get(key, "")).is_empty():
				out.append("%s satırının %s metni yok" % [id, key])
		if not speakers.has(str(line.get("speaker", ""))):
			out.append("%s satırının konuşanı yok" % id)
	for s: Variant in d.get("steps", []):
		var step: Dictionary = s
		if not ["hang", "farewell", "mount"].has(str(step.get("kind", ""))):
			out.append("%s adımının türü bilinmiyor" % step.get("id", "?"))
		if step.has("line") and not lines.has(str(step["line"])):
			out.append("%s adımının satırı yok: %s" % [step.get("id", "?"), step["line"]])
		# Söz kancaları (E20/7): intro_line, leave_lines, reply_lines bilinen satırları anar.
		var hooks: Array = []
		if step.get("intro_line") is Dictionary:
			hooks.append(step["intro_line"])
		for key in ["leave_lines", "reply_lines"]:
			if step.get(key) is Array:
				hooks.append_array(step[key])
		if step.get("ride") is Dictionary and (step["ride"] as Dictionary).get("intro_line") is Dictionary:
			hooks.append((step["ride"] as Dictionary)["intro_line"])
		for h: Variant in hooks:
			if not h is Dictionary or not lines.has(str((h as Dictionary).get("line", ""))):
				out.append("%s adımının söz kancasının satırı yok: %s" % [step.get("id", "?"), str(h)])
		var ride: Variant = step.get("ride")
		if ride is Dictionary:
			# Sürüş (E20): amaçlar iki dilde, yolun işaretleri ve arkaya bakışın süresi.
			for key in ["objective", "hint", "remount_objective"]:
				var entry: Variant = (ride as Dictionary).get(key)
				if not entry is Dictionary or str((entry as Dictionary).get("tr", "")).is_empty() or str((entry as Dictionary).get("en", "")).is_empty():
					out.append("%s adımının sürüşünde %s iki dilde olmalı" % [step.get("id", "?"), key])
			for key in ["gate", "threshold", "toward"]:
				if str((ride as Dictionary).get(key, "")).is_empty():
					out.append("%s adımının sürüşünde %s yok" % [step.get("id", "?"), key])
			if float(((ride as Dictionary).get("look_back", {}) as Dictionary).get("seconds", 0.0)) <= 0.0:
				out.append("%s adımının sürüşünde arkaya bakışın süresi yok" % step.get("id", "?"))
	var actor_defs: Dictionary = d.get("actors", {})
	for id: String in actor_defs:
		var carrier := str((actor_defs[id] as Dictionary).get("carried_by", ""))
		if not carrier.is_empty() and not actor_defs.has(carrier):
			out.append("%s kişisini taşıyan yok: %s" % [id, carrier])
	return out


## Sahnenin görevi verisinden (saf; Görevler sayfasında bitmiş görev olarak da): index o anki adımdır (adım sayısı ya da ötesi: bitti).
static func quest_of(d: Dictionary, index: int, p_lang: String = "tr") -> Dictionary:
	var steps: Array = []
	var all: Array = d.get("steps", [])
	for i in all.size():
		var s: Dictionary = all[i]
		steps.append({"id": str(s.get("id", "")), "text": _text_in(s.get("objective"), p_lang),
			"state": "done" if i < index else ("current" if i == index else "todo")})
	var cur: Dictionary = all[index] if index >= 0 and index < all.size() else {}
	return {
		"id": str(d.get("id", "mq0_depart")), "title": _text_in(d.get("title"), p_lang), "objective": _text_in(cur.get("objective"), p_lang),
		"detail": _text_in(cur.get("hint"), p_lang), "steps": steps, "done": index >= all.size(),
	}


static func _text_in(entry: Variant, p_lang: String) -> String:
	if entry is Dictionary:
		return str((entry as Dictionary).get(p_lang, (entry as Dictionary).get("tr", "")))
	return str(entry) if entry != null else ""


func text_of(entry: Variant) -> String:
	return DepartScene._text_in(entry, lang)


## Satırın metni (konuşansız).
func line_text(line_id: String) -> String:
	return text_of((data.get("lines", {}) as Dictionary).get(line_id, {}))


# --- Kurulum -----------------------------------------------------------------------------------------------

## Kişileri ve yazıları kurar (kişi başına bir kare; perde kapalıyken). Bitince prepared.
func prepare() -> void:
	if world == null or player == null:
		push_warning("[depart] bağlam yok")
		prepared.emit()
		return
	_root = Node3D.new()
	_root.name = ROOT_NAME
	world.add_child(_root)
	hud = StoryHud.new()
	hud.show_box = objective_box
	_ui_parent.add_child(hud)
	if _below and _below.get_parent() == _ui_parent:
		_ui_parent.move_child(hud, _below.get_index())
	_focus = Node3D.new()
	_focus.name = "CameraFocus"
	_root.add_child(_focus)
	_saved_obstacles = player.extra_obstacles.duplicate()
	var defs: Dictionary = data.get("actors", {})
	for id: String in defs:
		var def: Dictionary = defs[id]
		var a := CineActor.new()
		a.name = id.to_pascal_case()
		a.character_id = id
		a.build_on_ready = false
		if str(def.get("pose", "")) == "sit":
			a.pose = &"sit"
		if def.get("reach") is Array:
			a.reach_turns = def["reach"]
		if def.get("reach_grips") is Dictionary:
			for side: String in def["reach_grips"]:
				a.reach_grips[StringName(side)] = float(def["reach_grips"][side])
		if def.get("gesture") is Array:
			a.gesture_turns = def["gesture"]
		_root.add_child(a)
		actors[id] = a
	for id: String in defs:
		await get_tree().process_frame
		if _stopped:
			return
		_build_actor(id, defs[id])
	player.refresh_obstacles()
	prepared.emit()


func _build_actor(id: String, def: Dictionary) -> void:
	var a: CineActor = actors[id]
	a.build(actor_root)
	a.ensure_idle(ACTOR_ROLES)
	var carrier := str(def.get("carried_by", ""))
	if not carrier.is_empty():
		_carried[id] = carrier
		return
	var at := point(def.get("start"))
	if at == Vector3.INF:
		at = player.global_position
	a.global_position = at
	var face_at := point(def.get("face"))
	if face_at != Vector3.INF:
		a.face(face_at)
	if bool(def.get("solid", false)):
		player.extra_obstacles.append(Vector3(at.x, at.z, SOLID_RADIUS))
	if not str(def.get("carry", "")).is_empty():
		# Çocuğu taşıyan kol: taşırken hep bükülü (reach).
		a.reach_amount = 1.0


# --- Akış --------------------------------------------------------------------------------------------------

## Sahneyi başlatır (step_id boşsa ilk adımdan). Atlanan adımların dünyası kurulur: yay asılı, oyuncu önceki adımın hedefinde.
func begin(step_id: String = "") -> void:
	var ids := step_ids(data)
	if ids.is_empty():
		push_warning("[depart] adım yok")
		return
	var start := maxi(ids.find(step_id), 0) if not step_id.is_empty() else 0
	_running = true
	if voice:
		voice.audio = get_node_or_null(^"/root/AudioManager")
	_start_audio()
	hud.set_title(text_of(data.get("title")))
	world.snow_follow = player
	_preset(start)
	_start_step(start)


func is_running() -> bool:
	return _running


func current_step_id() -> String:
	return str(_step.get("id", ""))


func current_phase() -> String:
	return _phase


## Sonuç: yazılacak işaretler, yay asıldı mı, ata binildi mi.
func result() -> Dictionary:
	var flags: Dictionary = data.get("flags", {})
	return {"flags": PackedStringArray([str(flags.get("done", "mq0_depart"))]), "bow_hung": bow_hung, "mounted": mounted}


## Oyun içi HUD'un görevi (GameplayHud: görev kartı ve Görevler sayfası; ChildhoodScene.hud_quest gibi): başlık, o anki amaç ve ayrıntı,
## adımlar. Söz sırasında amaç boştur.
func hud_quest() -> Dictionary:
	var out := quest_of(data, _index, lang)
	out["objective"] = hud.objective_text() if hud else str(out.get("objective", ""))
	out["detail"] = hud.hint_text() if hud else str(out.get("detail", ""))
	out["done"] = _done
	return out


## Görevin o anki hedefi (HUD'un yön işaretleri; dünya, yoksa Vector3.INF): yurtta beşik, avluda Eskam'ın yanı, atta at; sürüşte yolun eşiği
## (atından inen oyuncuya at). Söz sırasında, kapı bakışında ve eşikten sonra yoktur.
func hud_target(_from: Vector3 = Vector3.INF) -> Vector3:
	if not _running or _step.is_empty():
		return Vector3.INF
	match str(_step.get("kind", "")):
		"hang":
			if _phase == "approach":
				return point(_step.get("target"))
		"farewell":
			if _phase == "go":
				return point(_step.get("target"))
		"mount":
			if _phase in ["go", "wait_mount"] and not player.is_riding():
				return point(_step.get("target"))
			if _phase in ["mounted", "ride"]:
				if not player.is_riding() and world.horse:
					return world.horse.global_position
				return point(_ride_def().get("threshold", "road_end"))
	return Vector3.INF


## Beşiğin önünde mi, E yayı asar mı?
func can_hang() -> bool:
	if not _running or str(_step.get("kind", "")) != "hang" or _phase != "approach":
		return false
	if not player.is_active() or player.get_stance() != PlayerController.Stance.FOOT:
		return false
	var spot := point(_step.get("spot"))
	return spot != Vector3.INF and _flat(player.global_position, spot) <= float(_step.get("reach", 1.3))


## E: beşiğin önündeyse yayı asar (tuşsuz sürüş ve sınama da bunu çağırır). Bir iş yaptıysa true.
func interact() -> bool:
	if not can_hang():
		return false
	_begin_hang()
	return true


## Durdurur ve bıraktığı her şeyi geri alır (bitişte de, yarıda bırakılınca da): yazılar, engeller, kamera, oyuncunun eli, ses.
func stop() -> void:
	if _stopped:
		return
	_stopped = true
	_running = false
	if voice:
		voice.stop()
	for t in _tweens:
		if t and t.is_valid():
			t.kill()
	_tweens.clear()
	_set_prompt(false)
	if is_instance_valid(_hang_gesture):
		_hang_gesture.get_parent().remove_child(_hang_gesture)
		_hang_gesture.queue_free()
	_hang_gesture = null
	if is_instance_valid(player):
		player.auto_move = Vector2.ZERO
		player.auto_sprint = false
		player.extra_obstacles = _saved_obstacles.duplicate()
		player.refresh_obstacles()
		if not _saved_area.is_empty():
			player.play_area_center = _saved_area[0]
			player.play_area_radius = _saved_area[1]
			player.play_area_soft_edge = _saved_area[2]
	_saved_area = []
	var traited: Variant = _saved_traits.get("ride")
	if is_instance_valid(traited) and (traited as Rideable).get_mount():
		(traited as Rideable).get_mount().spec = _saved_traits["spec"]
	_saved_traits = {}
	if is_instance_valid(camera):
		if _look_preset != null and camera.get_preset_id() == _look_preset.id:
			camera.clear_preset(true)
		if _saved_turn >= 0.0:
			camera.rotate_sharpness = _saved_turn
	_look_preset = null
	_saved_turn = -1.0
	if is_instance_valid(camera) and is_instance_valid(player) and camera.target != player:
		camera.target = player
	if is_instance_valid(hud):
		hud.clear()
		hud.queue_free()
	hud = null
	for id: String in (data.get("ambience", {}) as Dictionary):
		_audio(&"set_ambience_layer", [StringName(id), -80.0, 1.0])
	for id: String in (data.get("inside_ambience", {}) as Dictionary):
		_audio(&"set_ambience_layer", [StringName(id), -80.0, 1.0])
	if is_instance_valid(world):
		world.snow_follow = null
	if is_instance_valid(_root):
		_root.queue_free()
	_root = null
	actors.clear()
	_movers.clear()


func _exit_tree() -> void:
	stop()


func _process(delta: float) -> void:
	if not _running:
		return
	clock += delta
	step_clock += delta
	if voice:
		voice.tick(clock)
	_tick_queue()
	_tick_turn(delta)
	for m: StoryMover in _movers.values():
		m.tick(delta)
	_tick_carried()
	_tick_wave()
	_tick_inside(delta)
	match str(_step.get("kind", "")):
		"hang":
			_tick_hang(delta)
		"farewell":
			_tick_farewell(delta)
		"mount":
			_tick_mount(delta)
	if hud:
		hud.tick(clock)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"accept") and can_hang():
		_begin_hang()
		get_viewport().set_input_as_handled()


func _start_step(i: int) -> void:
	var steps: Array = data.get("steps", [])
	_index = i
	_step = steps[i]
	step_clock = 0.0
	_phase = ""
	hud.set_objective(text_of(_step.get("objective")))
	hud.set_hint(text_of(_step.get("hint")))
	match str(_step.get("kind", "")):
		"hang":
			_phase = "approach"
			world.lock_horse(true)
		"farewell":
			_phase = "go"
			_leave_said = false
			_start_wave(_step.get("wave", {}))
		"mount":
			_phase = "go"
			world.lock_horse(false)
			_apply_ride_traits()
			player.refresh_obstacles()
	_queue_intro()
	step_started.emit(current_step_id())


## Adımın açılış sözü (intro_line): after sn sonra, adımın ilk evresi sürüyorsa (Yançi beşiğin başında, Eskam arabasının yanında).
func _queue_intro() -> void:
	var intro: Dictionary = _step.get("intro_line", {})
	if intro.is_empty():
		return
	var phase := _phase
	var index := _index
	_at(clock + float(intro.get("after", 1.0)), func() -> void:
		if _index == index and _phase == phase:
			_say(str(intro.get("line", ""))))


func _next_step() -> void:
	var steps: Array = data.get("steps", [])
	if _index + 1 < steps.size():
		_start_step(_index + 1)


## Atlanan adımların dünyası (geliştirme --step, sınama): yay asılı, oyuncu önceki adımın hedefinde ayakta, kişiler yerinde.
func _preset(start: int) -> void:
	var steps: Array = data.get("steps", [])
	if start <= 0:
		var p: Dictionary = data.get("player", {})
		var at := point(p.get("start"))
		var face := point(p.get("face"))
		if at != Vector3.INF:
			player.spawn_at(at, _yaw_to(at, face, player.get_facing_yaw()))
		if world.home:
			world.home.snap_cut(1.0)
		return
	_show_hung_bow()
	if world.home:
		world.home.snap_cut(0.0)
	var prev: Dictionary = steps[start - 1]
	var at := point("door_out") if str(prev.get("kind", "")) == "hang" else point(prev.get("target"))
	var next_target := point((steps[start] as Dictionary).get("target"))
	player.spawn_at(at, _yaw_to(at, next_target, player.get_facing_yaw()))
	if start >= 2:
		_start_wave((steps[1] as Dictionary).get("wave", {}))
		var eskam: CineActor = actors.get("eskam")
		if eskam:
			eskam.global_position = point("eskam_seat")
			eskam.face(point("courtyard"))


# --- Yurt: yay ---------------------------------------------------------------------------------------------

func _tick_hang(delta: float) -> void:
	if _phase == "approach":
		_set_prompt(can_hang())
	if (_prompting or _phase in ["hang", "after"]) and is_instance_valid(camera):
		# E'nin işi var (ya da iş sürüyor): kamera E ile dönmez. Oyuncu her kare kendi değerini yazar, sahne ondan sonra, kamera en
		# son işlenir (FollowCamera.process_priority).
		camera.hold_turn_right = true
	match _phase:
		"hang":
			_phase_left -= delta
			_tick_bow()
			if _phase_left <= 0.0:
				_end_hang()
		"after":
			_phase_left -= delta
			if _phase_left <= 0.0:
				player.set_active(true)
				_next_step()


## Asış: oyuncu durur, beşiğe döner, eğilir; yay elinden kemere geçer; doğrulur. Yançi oyuncuya döner.
func _begin_hang() -> void:
	_set_prompt(false)
	_phase = "hang"
	var hs := float(_step.get("hang_seconds", 2.4))
	_phase_left = hs
	player.set_active(false)
	var cradle_at := point(_step.get("target"))
	_turn_player(cradle_at)
	var skeleton := player.get_avatar().get_skeleton()
	if skeleton:
		_hang_gesture = CineBow.new()
		_hang_gesture.name = "HangBow"
		_hang_gesture.turns = _step.get("gesture", [])
		skeleton.add_child(_hang_gesture)
		var t := _tween()
		t.tween_property(_hang_gesture, ^"amount", 1.0, hs * HANG_BEND).set_trans(Tween.TRANS_SINE)
		t.tween_interval(hs * (HANG_RISE - HANG_BEND))
		t.tween_property(_hang_gesture, ^"amount", 0.0, hs * (1.0 - HANG_RISE)).set_trans(Tween.TRANS_SINE)
	var yanchi: CineActor = actors.get("yanchi")
	if yanchi:
		yanchi.face(player.global_position)
	if world.mete_bow:
		world.mete_bow.visible = true
		world.mete_bow.global_transform = _hand_transform()


## Yay: eğilme bitene dek elde, sonra kemere kayar, orada kalır.
func _tick_bow() -> void:
	if world.mete_bow == null:
		return
	var hs := float(_step.get("hang_seconds", 2.4))
	var t := 1.0 - _phase_left / maxf(hs, 0.01)
	if t < HANG_BEND:
		_hand_from = _hand_transform()
		world.mete_bow.global_transform = _hand_from
	elif t < HANG_MOVE:
		var k := smoothstep(HANG_BEND, HANG_MOVE, t)
		world.mete_bow.global_transform = _hand_from.interpolate_with(world.hang_transform(), k)
	else:
		world.mete_bow.global_transform = world.hang_transform()


func _end_hang() -> void:
	_show_hung_bow()
	if is_instance_valid(_hang_gesture):
		_hang_gesture.get_parent().remove_child(_hang_gesture)
		_hang_gesture.queue_free()
	_hang_gesture = null
	_phase = "after"
	_phase_left = float(_step.get("hold_after", 1.2))
	_at(clock + float(_step.get("line_after", 0.3)), _say.bind(str(_step.get("line", ""))))
	hud.set_objective("")
	hud.set_hint("")


func _show_hung_bow() -> void:
	bow_hung = true
	if world and world.mete_bow:
		world.mete_bow.visible = true
		world.mete_bow.global_transform = world.hang_transform()


## Oyuncunun sağ elinin yanındaki yay dönüşümü (kemik yoksa göğsünün önü): yay dik, elde.
func _hand_transform() -> Transform3D:
	var skeleton := player.get_avatar().get_skeleton()
	var at := player.global_position + Vector3(0.0, 1.0, 0.0) + player.forward_vector() * 0.3
	if skeleton:
		var bone := skeleton.find_bone("RightHand")
		if bone >= 0:
			at = (skeleton.global_transform * skeleton.get_bone_global_pose(bone)).origin
	return Transform3D(Basis(Vector3.UP, player.get_facing_yaw()), at)


# --- Avlu: Eskam, Huyan Hatun, kapı -------------------------------------------------------------------------

func _tick_farewell(delta: float) -> void:
	match _phase:
		"go":
			_tick_leave_lines()
			if _flat(player.global_position, point(_step.get("target"))) <= float(_step.get("radius", 2.4)) and player.get_stance() == PlayerController.Stance.FOOT:
				_begin_farewell()
		"talk":
			_phase_left -= delta
			if _phase_left <= 0.0:
				_begin_door()
		"door_pan", "door_hold":
			_phase_left -= delta
			if _phase_left <= 0.0:
				if _phase == "door_pan":
					_phase = "door_hold"
					_phase_left = float((_step.get("door", {}) as Dictionary).get("seconds", 4.0))
				else:
					_end_door()
		"door_back":
			_phase_left -= delta
			if _phase_left <= 0.0:
				camera.target = player
				player.set_active(true)
				_next_step()


## Yurdun kapısından çıkınca (leave_lines'ın ilk girdisinin near işareti, radius m) Huyan Hatun kendi kapısından seslenir: sözler sırayla, bir kez.
func _tick_leave_lines() -> void:
	var lines: Array = _step.get("leave_lines", [])
	if _leave_said or lines.is_empty() or not lines[0] is Dictionary:
		return
	var first: Dictionary = lines[0]
	var at := point(first.get("near", "door_out"))
	if at == Vector3.INF or _flat(player.global_position, at) > float(first.get("radius", 2.0)):
		return
	_leave_said = true
	for entry: Variant in lines:
		if entry is Dictionary:
			_say(str((entry as Dictionary).get("line", "")))


## Söz: oyuncu durur, Eskam'a döner; Eskam oyuncuya döner ve konuşur.
func _begin_farewell() -> void:
	_phase = "talk"
	player.set_active(false)
	hud.set_objective("")
	hud.set_hint("")
	var eskam: CineActor = actors.get("eskam")
	if eskam:
		eskam.face(player.global_position)
		_turn_player(eskam.global_position)
	var seconds := _say(str(_step.get("line", "")))
	_phase_left = maxf(seconds, TURN_SECONDS) + LINE_GAP


## Kapı: odak Teoman'ın kapısına kayar, kamera uzak kareye açılır, dört saniye durur. Eskam arabasına yürür.
func _begin_door() -> void:
	var door: Dictionary = _step.get("door", {})
	_phase = "door_pan"
	_phase_left = float(door.get("pan", 1.6))
	var eskam: CineActor = actors.get("eskam")
	if eskam and point("eskam_seat") != Vector3.INF:
		var mover := StoryMover.new(eskam, world.get_terrain_shape())
		_movers["eskam"] = mover
		# Kişi oyuncunun koşusunu aşmaz (E20; PaceLimit).
		mover.go([point("eskam_seat")], PaceLimit.limit(ESKAM_WALK, PaceLimit.run_cap(player)))
	if camera and _focus:
		_focus.global_position = player.global_position
		camera.target = _focus
		var tw := _tween()
		tw.tween_property(_focus, ^"global_position", point(door.get("focus", "door_focus")), _phase_left).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_camera_distance = camera.get_target_distance()
		camera.zoom_by(float(door.get("camera_distance", 30.0)) - _camera_distance)


func _end_door() -> void:
	var door: Dictionary = _step.get("door", {})
	_phase = "door_back"
	_phase_left = float(door.get("back", 1.3))
	if camera and _focus:
		var tw := _tween()
		tw.tween_property(_focus, ^"global_position", player.global_position, _phase_left).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		camera.zoom_by(_camera_distance - camera.get_target_distance())


## El sallama başlar: taşıyan ve kucaktaki çocuk.
func _start_wave(wave: Dictionary) -> void:
	_wave_rate = float(wave.get("rate", _wave_rate))
	for key in ["actor", "carried"]:
		var id := str(wave.get(key, ""))
		if not id.is_empty() and actors.has(id) and not _waving.has(id):
			_waving.append(id)


func _tick_wave() -> void:
	if _waving.is_empty():
		return
	for i in _waving.size():
		var a: CineActor = actors.get(_waving[i])
		if a:
			var s := 0.5 + 0.5 * sin(clock * TAU * _wave_rate * 0.5 + float(i) * 1.3)
			a.gesture_amount = lerpf(WAVE_RANGE.x, WAVE_RANGE.y, s)


## Kucaktaki çocuk taşıyanın gövde kemiğiyle gider: yer kemikten, yön taşıyanın kendi yönünden.
func _tick_carried() -> void:
	for id: String in _carried:
		var child: CineActor = actors.get(id)
		var carrier: CineActor = actors.get(_carried[id])
		if child == null or carrier == null:
			continue
		var y := carrier.global_position.y + 0.95
		var skeleton := carrier.avatar.get_skeleton() if carrier.avatar else null
		if skeleton:
			for bone_name in CARRY_BONES:
				var bone := skeleton.find_bone(bone_name)
				if bone >= 0:
					y = (skeleton.global_transform * skeleton.get_bone_global_pose(bone)).origin.y
					break
		var base := Transform3D(Basis(Vector3.UP, carrier.global_rotation.y), Vector3(carrier.global_position.x, y, carrier.global_position.z))
		child.global_transform = base * Transform3D(Basis(Vector3.UP, deg_to_rad(CARRY_YAW_DEG)), CARRY_OFFSET)


# --- At ---------------------------------------------------------------------------------------------------

func _tick_mount(delta: float) -> void:
	match _phase:
		"go":
			var horse := world.horse
			if horse and _flat(player.global_position, horse.global_position) <= float(_step.get("meet", 4.0)):
				_begin_reins()
		"wait_mount":
			if player.is_riding():
				mounted = true
				_phase = "mounted"
				_phase_left = float((_step.get("ride", {}) as Dictionary).get("after", 0.5))
				hud.set_objective("")
				hud.set_hint("")
				_offer_reins(false)
		"mounted":
			_track_ride(delta)
			_phase_left -= delta
			if _phase_left <= 0.0:
				_begin_ride()
		"ride":
			_track_ride(delta)
			_watch_rider()
			_tick_ride_objective()
			if player.is_riding() and _past_threshold():
				_begin_look_back()
		"look_back", "fade":
			_watch_rider()
			player.auto_move = _ride_dir_input(_ride_def().get("toward", "road_far"))
			player.auto_sprint = false
			_update_look_focus(delta)
			_phase_left -= delta
			if _phase_left <= 0.0:
				if _phase == "look_back":
					_begin_fade()
				else:
					_phase = "black"
					_phase_left = float(_ride_def().get("black", 0.4))
		"black":
			_phase_left -= delta
			if _phase_left <= 0.0:
				_phase = "done"
				player.auto_move = Vector2.ZERO
				_finish()


## Lan Hatun dizginleri uzatır ve konuşur; ardından Mete'nin cevabı ve Lan Hatun'un son sözü sırayla (reply_lines). Oyuncu E ile biner
## (PlayerController): biniş sözü beklemez, sözler binerken de sürer.
func _begin_reins() -> void:
	_phase = "wait_mount"
	_offer_reins(true)
	_say(str(_step.get("line", "")))
	for entry: Variant in _step.get("reply_lines", []):
		if entry is Dictionary:
			_say(str((entry as Dictionary).get("line", "")))


func _offer_reins(on: bool) -> void:
	var lan: CineActor = actors.get("lan_hatun")
	if lan == null:
		return
	if on:
		lan.face(player.global_position)
	_tween_prop(lan, ^"reach_amount", 1.0 if on else 0.0, 0.6)


## Adımın sürüşü (verinin ride'ı; yoksa boş).
func _ride_def() -> Dictionary:
	return _step.get("ride", {}) if str(_step.get("kind", "")) == "mount" else {}


## Binince oyuncu atı kendisi sürer (E20): amaç ve ipucu yolu gösterir, oyuncunun alanı yolu da kapsar (ride.area), rüzgâr yükselir.
func _begin_ride() -> void:
	var ride := _ride_def()
	_phase = "ride"
	_ride_on_horse = player.is_riding()
	_set_ride_objective(_ride_on_horse)
	var area: Dictionary = ride.get("area", {})
	if not area.is_empty() and _saved_area.is_empty():
		_saved_area = [player.play_area_center, player.play_area_radius, player.play_area_soft_edge]
		player.play_area_center = OrdosGround._vec2(area.get("center", [0.0, 0.0]))
		player.play_area_radius = float(area.get("radius", player.play_area_radius))
		player.play_area_soft_edge = float(area.get("soft_edge", player.play_area_soft_edge))
	_audio(&"set_ambience_layer", [&"wind_steppe", float(ride.get("wind_db", -15.0)), 6.0])
	_queue_ride_line()


## Sürüşün sözü (ride.intro_line): binişten after sn sonra, oyuncu hâlâ atta ve sürüş sürüyorsa söylenir (Eskam avludan: araba ardından gelir).
func _queue_ride_line() -> void:
	var entry: Variant = _ride_def().get("intro_line")
	if not entry is Dictionary:
		return
	var index := _index
	_at(clock + float((entry as Dictionary).get("after", 2.0)), func() -> void:
		if _index == index and _phase == "ride" and player.is_riding():
			_say(str((entry as Dictionary).get("line", ""))))


## Uyuyan kampta at dörtnala kalkmaz (adımın ride.mount_traits'i; Shift tırıstır): yalnız bu atın satırı (kopya) değişir, sahne durunca geri
## alınır (ChildhoodScene._apply_mount_traits gibi).
func _apply_ride_traits() -> void:
	var traits: Dictionary = _ride_def().get("mount_traits", {})
	var horse: Rideable = world.horse if world else null
	if traits.is_empty() or horse == null or horse.get_mount() == null or not _saved_traits.is_empty():
		return
	var mount := horse.get_mount()
	_saved_traits = {"ride": horse, "spec": mount.spec}
	var spec := mount.spec.duplicate(true)
	for key: String in traits:
		spec[key] = traits[key]
	mount.spec = spec


## Sürüşün amacı: atta «Batı yoluna sür», atından inince «Atına bin».
func _set_ride_objective(on_horse: bool) -> void:
	var ride := _ride_def()
	hud.set_objective(text_of(ride.get("objective" if on_horse else "remount_objective")))
	hud.set_hint(text_of(ride.get("hint" if on_horse else "remount_hint")))


func _tick_ride_objective() -> void:
	var on := player.is_riding()
	if on != _ride_on_horse and player.get_stance() in [PlayerController.Stance.RIDING, PlayerController.Stance.FOOT]:
		_ride_on_horse = on
		_set_ride_objective(on)


## Binişten eşiğe süre ve yol (otomatik oynatmanın günlüğü, sınama).
func _track_ride(delta: float) -> void:
	ride_seconds += delta
	var at := player.global_position
	if _ride_last != Vector3.INF:
		ride_distance += Vector2(at.x - _ride_last.x, at.z - _ride_last.z).length()
	_ride_last = at


## Lan Hatun ve Eskam giden atlıya bakar (yerlerinden kıpırdamadan döner; yürütülen kişi yumuşakça).
func _watch_rider() -> void:
	for id in ["lan_hatun", "eskam"]:
		if _movers.has(id):
			(_movers[id] as StoryMover).face(player.global_position)
		elif actors.get(id):
			(actors[id] as CineActor).face(player.global_position)


## Oyuncu yolun eşiğini geçti mi (ride.gate → ride.threshold doğrultusunda eşiğin ötesinde, yolun iki yanında THRESHOLD_HALF_WIDTH içinde)?
func _past_threshold() -> bool:
	var ride := _ride_def()
	var gate := point(ride.get("gate", "road_gate"))
	var end := point(ride.get("threshold", "road_end"))
	if gate == Vector3.INF or end == Vector3.INF:
		return false
	var at := player.global_position
	return DepartScene.past_threshold(Vector2(at.x, at.z), Vector2(gate.x, gate.z), Vector2(end.x, end.z), THRESHOLD_HALF_WIDTH)


## Eşik (saf): nokta, kapıdan eşiğe giden doğrultuda eşiğin ötesinde ve doğrultunun iki yanında half_width içinde mi?
static func past_threshold(at: Vector2, gate: Vector2, end: Vector2, half_width: float) -> bool:
	var dir := end - gate
	if dir.length_squared() < 0.0001:
		return at.distance_to(end) <= half_width
	dir = dir.normalized()
	var rel := at - end
	return rel.dot(dir) >= 0.0 and absf(rel.cross(dir)) <= half_width


## Eşikte: girdi bırakılır, at adımla yolda yürür; kamera arkada kalan kampa döner, uzak kare (K98: 38°, 40 m; ride.look_back).
func _begin_look_back() -> void:
	var look: Dictionary = _ride_def().get("look_back", {})
	_phase = "look_back"
	_phase_left = float(look.get("seconds", 4.0))
	player.set_active(false)
	player.auto_sprint = false
	player.auto_move = _ride_dir_input(_ride_def().get("toward", "road_far"))
	hud.set_objective("")
	hud.set_hint("")
	_look_toward = point(look.get("toward", "camp_view"))
	if camera and _focus and _look_toward != Vector3.INF:
		_focus.global_position = player.global_position
		camera.target = _focus
		_look_preset = CameraPreset.make(&"depart_look_back", float(look.get("pitch", LOOK_BACK_PITCH)),
			float(look.get("camera_distance", LOOK_BACK_DISTANCE)), "fixed", 0.0, true)
		_look_preset.blend = float(look.get("blend", LOOK_BACK_BLEND))
		camera.apply_preset(_look_preset)
		if _saved_turn < 0.0:
			_saved_turn = camera.rotate_sharpness
		camera.rotate_sharpness = float(look.get("turn", LOOK_BACK_TURN))
		camera.set_yaw(DepartScene.look_back_yaw(player.global_position, _look_toward, deg_to_rad(float(look.get("yaw_offset_deg", 0.0)))))
	_audio(&"set_ambience_layer", [&"wind_steppe", float(_ride_def().get("wind_db", -15.0)) + 2.0, 3.0])


## Arkaya bakışın açısı (saf; FollowCamera.compute_transform'un kuralı): kamera binicinin kampa göre öte yanında, kampa bakar; offset (radyan)
## kareyi yana çevirir.
static func look_back_yaw(rider: Vector3, toward: Vector3, offset := 0.0) -> float:
	var d := Vector2(rider.x - toward.x, rider.z - toward.z)
	if d.length_squared() < 0.0001:
		return offset
	return wrapf(atan2(d.x, d.y) + offset, -PI, PI)


## Odak binici ile arkada kalan kampın arasında, binicinin LOOK_BACK_SHIFT metre içinde (binici karede kalır).
func _update_look_focus(delta: float) -> void:
	if _focus == null or _look_toward == Vector3.INF or camera == null or camera.target != _focus:
		return
	var shift := float((_ride_def().get("look_back", {}) as Dictionary).get("focus_shift", LOOK_BACK_SHIFT))
	var want := RiderColumn.midpoint_focus(player.global_position, _look_toward, shift)
	_focus.global_position = _focus.global_position.lerp(want, 1.0 - exp(-LOOK_BACK_SHARPNESS * delta))


## Perde kararır (ride.fade sn); at yürümeyi sürdürür.
func _begin_fade() -> void:
	var ride := _ride_def()
	_phase = "fade"
	_phase_left = float(ride.get("fade", 3.0))
	if fade_rect:
		var t := _tween()
		t.tween_property(fade_rect, ^"color:a", 1.0, _phase_left).set_trans(Tween.TRANS_SINE)


## Yolun yönünün (to: işaret ya da nokta) kameraya göre girdisi (W ekranda yukarı; ChildhoodAutoplay._steer_dir gibi).
func _ride_dir_input(to_spec: Variant = "road_far") -> Vector2:
	var to := point(to_spec)
	if to == Vector3.INF:
		return Vector2.ZERO
	var dir := Vector2(to.x - player.global_position.x, to.z - player.global_position.z).normalized()
	var cy := player.camera_yaw()
	var forward := Vector2(-sin(cy), -cos(cy))
	var right := Vector2(cos(cy), -sin(cy))
	return Vector2(dir.dot(right), dir.dot(forward)).limit_length(1.0)


func _finish() -> void:
	if _done:
		return
	_done = true
	_running = false
	player.auto_move = Vector2.ZERO
	finished.emit(result())


# --- Söz, ses, yardımcılar -----------------------------------------------------------------------------------

## Satırı söyler (SceneVoice): sesi varsa Voice yolunda çalar, altyazı sesin süresi kadar durur; konuşulurken gelen söz sıraya girer.
## Döner: sözün bitişine kalan süre (sn; sıradaysa bekleme de içinde).
func _say(line_id: String) -> float:
	if voice == null or not (data.get("lines", {}) as Dictionary).has(line_id):
		return 0.0
	return voice.say(line_id)


## Söz başlar (SceneVoice.show): konuşanın adıyla altyazı, söylenenler, said.
func _show_line(line_id: String, seconds: float) -> void:
	if hud:
		hud.say(_speaker_name(line_id), line_text(line_id), seconds, clock)
	said_lines.append(line_id)
	said.emit(line_id)


## Satırı söyleyenin şimdiki dildeki adı.
func _speaker_name(line_id: String) -> String:
	var line: Dictionary = (data.get("lines", {}) as Dictionary).get(line_id, {})
	return text_of((data.get("speakers", {}) as Dictionary).get(str(line.get("speaker", "")), {}))


## Konuşanın ekrandaki yeri (−0,3..0,3; uzak kare, K98): kişi kameranın sağındaysa ses biraz sağdan gelir; Mete ortada.
func _pan_of(line_id: String) -> float:
	var line: Dictionary = (data.get("lines", {}) as Dictionary).get(line_id, {})
	var a: CineActor = actors.get(str(line.get("speaker", "")))
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if a == null or not is_instance_valid(a) or cam == null or cam.is_position_behind(a.global_position):
		return 0.0
	var size := get_viewport().get_visible_rect().size
	if size.x <= 0.0:
		return 0.0
	return clampf((cam.unproject_position(a.global_position).x / size.x - 0.5) * 0.6, -0.3, 0.3)


func _at(t: float, fn: Callable) -> void:
	_queue.append([t, fn])


func _tick_queue() -> void:
	var due: Array = []
	for item: Array in _queue:
		if float(item[0]) <= clock:
			due.append(item)
	for item: Array in due:
		_queue.erase(item)
		(item[1] as Callable).call()


func _start_audio() -> void:
	var music: Dictionary = data.get("music", {})
	if not music.is_empty():
		_audio(&"set_music_bank", [str(music.get("bank", "")), StringName(str(music.get("state", ""))), float(music.get("fade", 2.0))])
	var ambience: Dictionary = data.get("ambience", {})
	for id: String in ambience:
		_audio(&"set_ambience_layer", [StringName(id), float(ambience[id]), 2.0])


## Yurdun içindeyken iç sesler (keçenin uğultusu, köz) açılır, dışarıda söner.
func _tick_inside(delta: float) -> void:
	_inside_left -= delta
	if _inside_left > 0.0 or world == null or world.home == null:
		return
	_inside_left = INSIDE_TICK
	var c := world.home.global_position
	var inside := 1 if _flat(player.global_position, c) < world.home.radius * 0.9 else 0
	if inside == _inside:
		return
	_inside = inside
	var layers: Dictionary = data.get("inside_ambience", {})
	for id: String in layers:
		_audio(&"set_ambience_layer", [StringName(id), float(layers[id]) if inside == 1 else -80.0, 1.2])


func _audio(method: StringName, args: Array) -> void:
	var audio := get_node_or_null(^"/root/AudioManager")
	if audio and audio.has_method(method):
		audio.callv(method, args)


## E ipucu (oyuncunun ipucu panelinde ve HUD'un şeridinde; PlayerController.prompt_changed).
func _set_prompt(on: bool) -> void:
	if on == _prompting or not is_instance_valid(player):
		return
	_prompting = on
	if on:
		player.prompt_changed.emit([["E", text_of(_step.get("prompt", {"tr": "Yayı as", "en": "Hang the bow"}))]])
	else:
		player.prompt_changed.emit(player.prompt_pairs() if player.is_active() else [])


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


func _tween() -> Tween:
	var t := create_tween()
	_tweens.append(t)
	return t


func _tween_prop(obj: Object, prop: NodePath, value: Variant, sec: float) -> void:
	var t := _tween()
	t.tween_property(obj, prop, value, sec).set_trans(Tween.TRANS_SINE)


## Yer: işaret kimliği (DepartWorld.marker) ya da [x, z]; bulunamazsa Vector3.INF.
func point(spec: Variant) -> Vector3:
	if spec is String:
		return world.marker(spec) if world else Vector3.INF
	if spec is Array and (spec as Array).size() >= 2:
		var x := float(spec[0])
		var z := float(spec[1])
		return Vector3(x, world.get_terrain_shape().height_at(x, z) if world else 0.0, z)
	return Vector3.INF


static func _yaw_to(from: Vector3, to: Vector3, fallback: float) -> float:
	if to == Vector3.INF:
		return fallback
	var yaw := CampNpcs.facing_yaw(from, to)
	return fallback if is_nan(yaw) else yaw


static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
