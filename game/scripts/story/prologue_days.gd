class_name PrologueDays
extends Node
## Önsöz'ün oynanan üç günü (E21, K110; story.md §3 «Göl Obası'nda üç gün»; docs/design/d3/e21-prologue-api.md): Yeni Oyun Göl Obası'nda
## 8–10 Nisan MÖ 209'la açılır, oyuncu ozanın dinleyicisi Çocuk'tur. Sıra data/story/prologue_days.json'dadır: her gün sahne dosyalarını
## (görevleri) sırayla oynatır; her sahnenin adımları dosyadaki sırayla akar, her adımın kind'ı ayrı bir betiktir (PrologueSteps.KINDS;
## PrologueStep'ten türer). Kamp dünyası menünün dünyasıdır: koşucu günler boyunca onun ışığını (SkyRig), havasını (kendi CampWeather'ı),
## yürünür alanını ve ateş başı halkını devralır, sonunda bit bit geri verir (menü karesi değişmez).
##
## Akış: begin(gün, görev, adım) kara perdede çağrılır. Günün başında kart («8 Nisan MÖ 209 · Göl Obası», TR ve EN) ve kayıt noktası
## (day_started → main.gd flow_save_point), sonra sahne kurulur (saat, hava, kişiler, oyuncunun yeri, yataklar, müzik) ve perde açılır. Gün
## içinde sahneler arası perde kararır, saat sahnenin başına atlar (görevler arası saat kararmayla atlar; geri gitmez). Gün «sleep» (yatağa E)
## ya da «night_end» adımıyla biter: sıradaki günün kartı. Son günün sonu «cinema» adımıdır (to_cinema): kamera 1,6 sn'de menü kadrajına
## döner, ateş başı halkı menüdeki yerinde oturur, finished({ending: "cinema"}) yayılır, main.gd bugünkü Önsöz sinemasını 0'dan oynatır.
## Esc basılı tutmak Önsöz'ü (günler ve sinema) atlar: main.gd skip() çağırır, finished({ending: "skipped"}).
##
## Söz (K61, K78): satırlar data/story/prologue_days/lines.json'dadır (docs/design/d3/e21-lines.json'un kopyası; tools/sync_prologue_lines.py),
## kimlikleri tamdır (act0.milk.wake). SceneVoice satırı vo_lines.json'daki kimlikle çalar; sesi yoksa altyazı metnin uzunluğundan süreyle akar.
## Saat (GameClock, K67): 2,5 sn = 1 oyun dk; bloklayan söz saati durdurur (dialogue). Işık saati izler: kampın ışık durakları (LightStops,
## «camp»), 4 Hz örnek (kendi RoamTime'ı, saati adımlamaz). Ses: PrologueSound (yataklar, tek seferlik sesler, müzik). Kayıt koşucunun
## değildir: main.gd günün başında yazar (flags'teki onsoz_* işaretleriyle).
##   var days := PrologueDays.new()
##   days.setup({main, world, player, camera, menu_camera, ui, fade, game_hud})
##   add_child(days); await days.prepare(); days.begin(0, "storm")
##   var result: Dictionary = await days.finished       # {ending: "cinema" | "skipped" | "end", flags, results}

signal prepared
signal day_started(day_index: int, day_id: String)
signal scene_started(scene_id: String)
signal step_started(step_id: String)
signal said(line_id: String)
signal finished(result: Dictionary)

const ORDER_PATH := "res://data/story/prologue_days.json"
const LINES_PATH := "res://data/story/prologue_days/lines.json"
## Kişilerin ve eşyaların dünyadaki kökü (koşucu durunca silinir).
const ROOT_NAME := "Prologue"
## Günün kartı (sn) ve kartın kara perdede en az kalışı (sn).
const CARD_SECONDS := 4.4
const CARD_MIN := 2.4
## Sahneler arası kararma ve açılma (sn).
const SCENE_FADE_OUT := 0.8
const SCENE_FADE_IN := 0.9
## Işığın ve havanın yazılma aralığı (sn).
const LIGHT_TICK := 0.25
## Söz sırasında satırlar arası boşluk (sn).
const LINE_GAP := 0.45
## Ateş başı halkının düğümü (kamp dünyasında).
const CAMP_NPCS := ^"Camp/CampNpcs"
## Sinemaya geçişte kameranın menü kadrajına dönüşü ve ışığın, havanın kimliğe süzülüşü (sn; K110).
const CINEMA_RETURN_S := 1.6
## Hava kilidinin kimliği.
const WEATHER_LOCK := "prologue"
## Kar örtüsünün görünüşü (0..1) → SnowPack.snowpack (1 ≈ 40 cm): görünüş WeatherLook.COVER_FULL'da tamdır; tam örtü ≈11 cm'dir.
const SNOW_PACK_PER_COVER := WeatherLook.COVER_FULL * 1.6

var order: Dictionary = {}
## Satırlar (kimlik → {speaker, tr, en}) ve konuşanlar.
var lines: Dictionary = {}
var speakers: Dictionary = {}
## Süren sahnenin verisi.
var scene: Dictionary = {}
var lang := "tr"

# Bağlam (setup)
var main: Node
var world: Node3D
var player: PlayerController
var camera: FollowCamera
var menu_camera: Camera3D
var ui_parent: Node
var fade_rect: ColorRect
var game_hud: GameplayHud
## Günün kartı: func(metin, sn) (CineHost.card).
var card_func: Callable
## Oyunun durumu: func(oynanıyor: bool) (main.gd State.PLAYING ya da BUSY).
var state_func: Callable

# Koşucunun parçaları
var places: PrologueWorld
var cast: PrologueCast
var sound: PrologueSound
var voice: SceneVoice
var hud: StoryHud
var clock: GameClock
var weather: CampWeather
## Görevlerin sonuçları (milk: full / spilt ...) ve yolculuğa yazılacak işaretler (onsoz_*).
var results: Dictionary = {}
var flags: Dictionary = {}
## Sahnenin saati (sn; altyazı ve söz) ve adımın saati.
var scene_clock := 0.0
var step_clock := 0.0
## Söylenen satırlar (sınama).
var said_lines := PackedStringArray()
## Geliştirme ve sınama: verilen gün, görev ve adım (begin).
var start_day := 0
var start_quest := ""
var start_step := ""
## Geliştirme (--at=x,z[,yön], --clock=HH:MM): ilk sahnede oyuncunun yeri ve saat (kareler).
var dev_at := Vector3.INF
var dev_yaw := NAN
var dev_clock := ""

var _root: Node3D
var _light: RoamTime
var _light_left := 0.0
var _day_i := -1
var _scene_i := -1
var _step_i := -1
var _step: PrologueStep
var _queue: Array = []
var _running := false
var _stopped := false
var _busy := false
var _done := false
var _ending := ""
var _saved_interaction: Callable
var _saved_bow_prompt := true
var _saved_extra: Array[Vector3] = []
var _saved_obstacles: Array[Vector3] = []
var _npcs_hidden := false
var _snow_target := -1.0
var _mist := 0.0
var _weather_type := "clear"
var _weather_params: Dictionary = {}
## Aynı türde değer geçişi (_ramp_weather): {t, s}.
var _ramp: Dictionary = {}
var _carried: Node3D
var _carried_id := ""
## Günün istenen sözleri (gün bitince bırakılır).
var _day_lines := PackedStringArray()


## Bağlam: {main, world, player, camera, menu_camera, ui, fade, game_hud, card, state}. Ağaca eklenmeden önce çağrılır.
func setup(ctx: Dictionary) -> void:
	main = ctx.get("main")
	world = ctx.get("world")
	player = ctx.get("player")
	camera = ctx.get("camera")
	menu_camera = ctx.get("menu_camera")
	ui_parent = ctx.get("ui")
	fade_rect = ctx.get("fade")
	game_hud = ctx.get("game_hud")
	card_func = ctx.get("card", Callable())
	state_func = ctx.get("state", Callable())
	lang = SubtitleBar.ui_lang()
	if order.is_empty():
		order = load_order()
	_load_lines()
	voice = SceneVoice.new()
	voice.prefix = ""
	voice.gap = LINE_GAP
	voice.show = _show_line
	voice.text_seconds = func(key: String) -> float: return StoryHud.line_seconds(line_text(key))


# --- Saf yardımcılar (sınama) -------------------------------------------------------------------------------

## Günlerin sırası (okunamazsa boş).
static func load_order(path: String = ORDER_PATH) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if not parsed is Dictionary:
		push_warning("[prologue] gün sırası okunamadı: %s" % path)
		return {}
	return parsed


## Sahnenin verisi (dosya yoksa ya da boşsa boş).
static func load_scene(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}
	var text := FileAccess.get_file_as_string(path).strip_edges()
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}


## Günler (sırasıyla).
static func days_of(o: Dictionary) -> Array:
	return o.get("days", []) if o.get("days") is Array else []


## Günün sahne yolları.
static func scene_paths(o: Dictionary, day_index: int) -> PackedStringArray:
	var days := PrologueDays.days_of(o)
	if day_index < 0 or day_index >= days.size():
		return PackedStringArray()
	return PackedStringArray((days[day_index] as Dictionary).get("scenes", []))


## Sahne kimliği (dosyadaki id; yoksa dosya adının «dayN_» sonrası).
static func scene_id_of(path: String) -> String:
	var d := PrologueDays.load_scene(path)
	if d.has("id"):
		return str(d["id"])
	var base := path.get_file().get_basename()
	var cut := base.find("_")
	return base.substr(cut + 1) if cut >= 0 else base


## Bütün sahnelerin kimlikleri sırasıyla (gün sırasıyla).
static func scene_ids(o: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	for i in PrologueDays.days_of(o).size():
		for p: String in PrologueDays.scene_paths(o, i):
			out.append(PrologueDays.scene_id_of(p))
	return out


## Geliştirme argümanı → {day_index, scene_index} (saf). day: 1..N (0 ya da boşsa görevin günü), quest: sahne kimliği ya da dosya adının
## sonu («storm», «day1_storm»). Bilinmiyorsa ilk gün, ilk sahne.
static func resolve(o: Dictionary, day: int = 0, quest: String = "") -> Dictionary:
	var days := PrologueDays.days_of(o)
	if days.is_empty():
		return {"day_index": 0, "scene_index": 0}
	var di := clampi(day - 1, 0, days.size() - 1) if day > 0 else -1
	if not quest.is_empty():
		for i in days.size():
			if di >= 0 and i != di:
				continue
			var paths := PrologueDays.scene_paths(o, i)
			for j in paths.size():
				var base := paths[j].get_file().get_basename()
				if base == quest or base.ends_with("_" + quest) or PrologueDays.scene_id_of(paths[j]) == quest:
					return {"day_index": i, "scene_index": j}
	return {"day_index": maxi(di, 0), "scene_index": 0}


## Günün kartı (TR ya da EN).
static func date_text(o: Dictionary, day_index: int, p_lang: String = "tr") -> String:
	var days := PrologueDays.days_of(o)
	if day_index < 0 or day_index >= days.size():
		return ""
	return NewGameFlow.text((days[day_index] as Dictionary).get("date"), p_lang)


## Günün kimliği (day1 …).
static func day_id_of(o: Dictionary, day_index: int) -> String:
	var days := PrologueDays.days_of(o)
	if day_index < 0 or day_index >= days.size():
		return ""
	return str((days[day_index] as Dictionary).get("id", "day%d" % (day_index + 1)))


## Günün sözleri (saf): günün öneklerindeki (prologue_days.json günün «lines»'ı) bütün satırlar ve sahnelerinin andığı satırlar. Ses havuzu
## gün başınadır: koşucu günün başında yalnız bunları ister, gün bitince bırakır.
static func day_line_ids(o: Dictionary, day_index: int, all_lines: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	var days := PrologueDays.days_of(o)
	if day_index < 0 or day_index >= days.size():
		return out
	var prefixes: Array = (days[day_index] as Dictionary).get("lines", [])
	for id: String in all_lines:
		for pre: Variant in prefixes:
			if id.begins_with(str(pre)) and not out.has(id):
				out.append(id)
	for path: String in PrologueDays.scene_paths(o, day_index):
		for id: String in PrologueSteps.line_refs(PrologueDays.load_scene(path)):
			if all_lines.has(id) and not out.has(id):
				out.append(id)
	return out


## Günün dizini (kimlikten; yoksa -1).
static func day_index_of(o: Dictionary, day_id: String) -> int:
	var days := PrologueDays.days_of(o)
	for i in days.size():
		if str((days[i] as Dictionary).get("id", "")) == day_id:
			return i
	return -1


# --- Kurulum ------------------------------------------------------------------------------------------------

## Dünyayı (Kayın Obası, yol, dere, kazıklar), kişileri ve yazıları kurar; perde kapalıyken. Bitince prepared.
func prepare() -> void:
	if world == null or player == null:
		push_warning("[prologue] bağlam yok")
		prepared.emit()
		return
	_root = Node3D.new()
	_root.name = ROOT_NAME
	world.add_child(_root)
	hud = StoryHud.new()
	hud.show_box = false
	ui_parent.add_child(hud)
	if fade_rect and fade_rect.get_parent() == ui_parent:
		ui_parent.move_child(hud, fade_rect.get_index())
	places = PrologueWorld.new()
	places.name = "PrologueWorld"
	places.world = world
	places.player = player
	_root.add_child(places)
	await places.build()
	if _stopped:
		return
	sound = PrologueSound.new()
	sound.name = "PrologueSound"
	sound.listener_source = func() -> Vector3: return player.global_position if is_instance_valid(player) else Vector3.ZERO
	add_child(sound)
	cast = PrologueCast.new()
	cast.name = "PrologueCast"
	cast.days = self
	_root.add_child(cast)
	_light = RoamTime.new()
	_light.name = "PrologueLight"
	add_child(_light)
	weather = CampWeather.new()
	weather.name = "PrologueWeather"
	add_child(weather)
	_saved_extra = player.play_area_extra.duplicate()
	_saved_obstacles = player.extra_obstacles.duplicate()
	# Önsöz'de yay ipucu çıkmaz (sırık, köz kabı, kuzu elde; Çocukluk'un bow_prompt'u gibi). Yay yine gerilebilir, yük taşınırken değil.
	_saved_bow_prompt = player.bow_prompt
	player.bow_prompt = false
	player.play_area_extra = places.walk_circles()
	player.extra_obstacles.append_array(places.obstacles())
	player.refresh_obstacles()
	_hide_camp_npcs(true)
	prepared.emit()


# --- Akış ---------------------------------------------------------------------------------------------------

## Önsöz'ün günlerini başlatır (kara perdede): day_index 0..N-1, quest sahne kimliği ("" ilk sahne), step adım kimliği ("" ilk adım).
func begin(day_index: int = 0, quest: String = "", step_id: String = "") -> void:
	start_day = day_index
	start_quest = quest
	start_step = step_id
	_running = true
	if voice:
		voice.audio = get_node_or_null(^"/root/AudioManager")
	_saved_interaction = player.interaction_source
	player.interaction_source = interaction
	var at := {"day_index": day_index, "scene_index": 0}
	if not quest.is_empty():
		at = PrologueDays.resolve(order, day_index + 1, quest)
	_start_day(int(at["day_index"]), int(at["scene_index"]), step_id)


func is_running() -> bool:
	return _running


func day_index() -> int:
	return _day_i


func day_id() -> String:
	return PrologueDays.day_id_of(order, _day_i)


func scene_id() -> String:
	return str(scene.get("id", ""))


func current_step_id() -> String:
	return str(_step.step.get("id", "")) if _step else ""


func current_step() -> PrologueStep:
	return _step


func current_phase() -> String:
	return _step.phase if _step else ""


## Perde ya da sahne geçişi sürüyor mu (adımlar işlemez)?
func is_busy() -> bool:
	return _busy


func _start_day(di: int, si: int, step_id: String) -> void:
	var days := PrologueDays.days_of(order)
	if di >= days.size():
		_finish("end")
		return
	_day_i = di
	_busy = true
	_set_playing(false)
	var day: Dictionary = days[di]
	var shown := Time.get_ticks_msec()
	_request_day_lines(di)
	var date := PrologueDays.date_text(order, di, lang)
	if card_func.is_valid() and not date.is_empty():
		card_func.call(date, CARD_SECONDS)
	# Yeni günün saati: günün ilk sahnesinin başı (sahne kurarken yazılır).
	clock = null
	day_started.emit(di, PrologueDays.day_id_of(order, di))
	var paths := PrologueDays.scene_paths(order, di)
	if paths.is_empty():
		_start_day(di + 1, 0, "")
		return
	await _setup_scene(maxi(si, 0), step_id, int(day.get("day_n", GameCalendar.HOME_DAY - 3 + di)))
	if _stopped:
		return
	while (Time.get_ticks_msec() - shown) / 1000.0 < CARD_MIN and not date.is_empty():
		await get_tree().process_frame
		if _stopped:
			return
	await _fade(0.0, SCENE_FADE_IN)
	if _stopped:
		return
	_busy = false
	_set_playing(true)


## Sahneyi kurar (perde karayken): saat, hava, kişiler, oyuncu, yataklar, müzik; adımları başlatır. Sahne boşsa sıradakine geçer.
func _setup_scene(si: int, step_id: String, day_n: int) -> void:
	var paths := PrologueDays.scene_paths(order, _day_i)
	while si < paths.size():
		var data := PrologueDays.load_scene(paths[si])
		if not data.is_empty() and not (data.get("steps", []) as Array).is_empty():
			break
		si += 1
	if si >= paths.size():
		_end_day_now()
		return
	_scene_i = si
	scene = PrologueDays.load_scene(paths[si])
	# Sahnenin saati tekdüze akar (sözün ve altyazının saati; sahneler arasında sıfırlanmaz).
	said_lines = PackedStringArray()
	_stop_step()
	_apply_clock(day_n)
	_apply_light()
	_apply_weather(scene.get("weather", {}), true)
	places.set_family_yurt(str(scene.get("family_yurt", "open")) == "open")
	await cast.apply(scene.get("cast", {}))
	if _stopped:
		return
	_place_player(scene.get("player", {}))
	if sound:
		sound.apply_scene(scene, places)
	if hud:
		hud.set_title(text_of(scene.get("title")))
	if game_hud and game_hud.get_parent():
		pass
	scene_started.emit(scene_id())
	var ids := step_ids(scene)
	var start := maxi(ids.find(step_id), 0) if not step_id.is_empty() else 0
	if start > 0:
		_preset_to(start)
	if dev_at != Vector3.INF:
		player.spawn_at(point([dev_at.x, dev_at.z]), dev_yaw if is_finite(dev_yaw) else player.get_facing_yaw())
		dev_at = Vector3.INF
		if camera:
			camera.snap_to_target()
	if not dev_clock.is_empty():
		set_time(dev_clock)
		dev_clock = ""
	_start_step(start)


## Gün içinde sıradaki sahne: perde kararır, saat atlar, sahne kurulur, perde açılır.
func next_scene() -> void:
	if _busy or _stopped:
		return
	var paths := PrologueDays.scene_paths(order, _day_i)
	if _scene_i + 1 >= paths.size():
		end_day()
		return
	_busy = true
	_set_playing(false)
	await _fade(1.0, SCENE_FADE_OUT)
	if _stopped:
		return
	var day: Dictionary = PrologueDays.days_of(order)[_day_i]
	await _setup_scene(_scene_i + 1, "", int(day.get("day_n", 1168)))
	if _stopped or _done:
		return
	await _fade(0.0, SCENE_FADE_IN)
	if _stopped:
		return
	_busy = false
	_set_playing(true)


## Gün biter (uyku ya da gecenin sonu): perde kararır (zaten karaysa beklenmez), sıradaki günün kartı.
func end_day() -> void:
	if _stopped or _done:
		return
	_busy = true
	_set_playing(false)
	if fade_rect and fade_rect.color.a < 0.999:
		await _fade(1.0, SCENE_FADE_OUT)
	if _stopped:
		return
	_end_day_now()


func _end_day_now() -> void:
	_stop_step()
	if voice:
		voice.stop()
	if hud:
		hud.clear()
	_start_day(_day_i + 1, 0, "")


func _process(delta: float) -> void:
	if not _running or _stopped:
		return
	scene_clock += delta
	if voice:
		voice.tick(scene_clock)
	if hud:
		hud.tick(scene_clock)
	if clock:
		clock.pause(&"dialogue", voice != null and _blocking_line())
		clock.step(delta)
	_tick_light(delta)
	_tick_weather_extras()
	if cast:
		cast.tick(delta)
	if is_instance_valid(_carried) and is_instance_valid(player) and player.is_aiming():
		player.release_aim()
	if _busy or _step == null:
		return
	step_clock += delta
	_step.clock = step_clock
	_tick_queue()
	if _step and not _step.is_done():
		_step.tick(delta)


# --- Adımlar ------------------------------------------------------------------------------------------------

## Sahnenin adım kimlikleri (saf).
static func step_ids(d: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	for s: Variant in d.get("steps", []):
		if s is Dictionary:
			out.append(str((s as Dictionary).get("id", "")))
	return out


func _start_step(i: int) -> void:
	var steps: Array = scene.get("steps", [])
	if i >= steps.size():
		next_scene()
		return
	_step_i = i
	var data: Dictionary = steps[i]
	step_clock = 0.0
	_queue.clear()
	var kind := str(data.get("kind", ""))
	var handler := PrologueSteps.make(kind, self, data)
	if handler == null:
		push_warning("[prologue] bilinmeyen adım türü: %s (%s)" % [kind, data.get("id", "")])
		handler = PrologueSteps.make("wait", self, {"id": str(data.get("id", "")), "kind": "wait", "seconds": 0.1})
	_step = handler
	if hud:
		hud.set_objective(text_of(data.get("objective")))
		hud.set_hint(text_of(data.get("hint")))
	for s: Variant in data.get("say", []):
		var e: Dictionary = s if s is Dictionary else {"line": str(s), "at": 0.0}
		at(float(e.get("at", 0.0)), func() -> void: say(str(e.get("line", ""))))
	step_started.emit(str(data.get("id", "")))
	_step.start()


## Adım bitti (PrologueStep.done): sıradaki adım ya da sahne.
func step_done(handler: PrologueStep) -> void:
	if handler != _step or _stopped:
		return
	var data := handler.step
	for s: Variant in data.get("on_done", []):
		var e: Dictionary = s if s is Dictionary else {"line": str(s)}
		say(str(e.get("line", "")))
	_stop_step()
	call_deferred(&"_advance", _step_i + 1)


func _advance(i: int) -> void:
	if _stopped or _done or _busy:
		return
	_start_step(i)


func _stop_step() -> void:
	if _step:
		_step.stop()
	_step = null
	_queue.clear()


## Atlanan adımların dünyası (geliştirme --step, sınama): her atlanan adımın preset()'i sırayla.
func _preset_to(start: int) -> void:
	var steps: Array = scene.get("steps", [])
	for i in mini(start, steps.size()):
		var h := PrologueSteps.make(str((steps[i] as Dictionary).get("kind", "")), self, steps[i])
		if h:
			h.preset()


## Adımın saatinde t saniyede fn (adım bitince kuyruk boşalır).
func at(t: float, fn: Callable) -> void:
	_queue.append([t, fn])


func _tick_queue() -> void:
	var i := 0
	while i < _queue.size():
		if step_clock >= float(_queue[i][0]):
			var fn: Callable = _queue[i][1]
			_queue.remove_at(i)
			if fn.is_valid():
				fn.call()
		else:
			i += 1


# --- Söz ----------------------------------------------------------------------------------------------------

func _load_lines() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(LINES_PATH)) if FileAccess.file_exists(LINES_PATH) else null
	if not parsed is Dictionary:
		push_warning("[prologue] satırlar okunamadı: %s" % LINES_PATH)
		return
	speakers = (parsed as Dictionary).get("speakers", {})
	lines = {}
	for l: Variant in (parsed as Dictionary).get("lines", []):
		if l is Dictionary and (l as Dictionary).has("id"):
			lines[str(l["id"])] = l


## Satırı söyler (tam kimlik). Döner: sözün bitişine kalan süre (sn; sırada bekleme de içinde). Bilinmeyen satır 0.
func say(line_id: String, ok: Callable = Callable(), optional := false) -> float:
	if voice == null or line_id.is_empty() or not lines.has(line_id):
		if not line_id.is_empty() and not lines.has(line_id):
			push_warning("[prologue] satır yok: %s" % line_id)
		return 0.0
	return voice.say(line_id, ok, optional)


## Satırın süresi (sn): sesliyse sesin, değilse altyazının.
func line_seconds(line_id: String) -> float:
	return voice.length(line_id) if voice else StoryHud.line_seconds(line_text(line_id))


func line_text(line_id: String) -> String:
	return text_of(lines.get(line_id))


func speaker_of(line_id: String) -> String:
	return str((lines.get(line_id, {}) as Dictionary).get("speaker", ""))


## Konuşanın kimliği → kişinin kimliği (obanın halkı: folk_woman → birch_woman; öteki kimlikler aynıdır).
const SPEAKER_CAST := {"folk_woman": "birch_woman", "folk_man": "birch_man"}


func cast_id_of(speaker: String) -> String:
	return str(SPEAKER_CAST.get(speaker, speaker))


func _show_line(line_id: String, seconds: float) -> void:
	var line: Dictionary = lines.get(line_id, {})
	var who := str(line.get("speaker", ""))
	if hud:
		hud.say(text_of(speakers.get(who)), text_of(line), seconds, scene_clock)
	said_lines.append(line_id)
	if cast:
		cast.talking(cast_id_of(who), seconds)
	said.emit(line_id)


## Söz konuşuluyor ya da sırada mı (bloklayan sözde saat durur)?
func _blocking_line() -> bool:
	return voice != null and not voice.is_free()


# --- HUD'un görevi --------------------------------------------------------------------------------------------

## Oyun içi HUD'un görevi (GameplayHud): başlık, amaç, ayrıntı, adımlar.
func hud_quest() -> Dictionary:
	var steps: Array = []
	var all: Array = scene.get("steps", [])
	for i in all.size():
		var s: Dictionary = all[i]
		var obj := text_of(s.get("objective"))
		if obj.is_empty():
			continue
		steps.append({"id": str(s.get("id", "")), "text": obj, "state": "done" if i < _step_i else ("current" if i == _step_i else "todo")})
	return {
		"id": "mq0_prologue_" + scene_id(), "title": text_of(scene.get("title")),
		"objective": hud.objective_text() if hud else "", "detail": hud.hint_text() if hud else "",
		"steps": steps, "done": _done,
	}


## Görevin o anki hedefi (HUD'un yönü).
func hud_target(from: Vector3 = Vector3.INF) -> Vector3:
	if _busy or _step == null:
		return Vector3.INF
	return _step.target(from if from != Vector3.INF else player.global_position)


func set_objective(text: String) -> void:
	if hud:
		hud.set_objective(text)


func set_hint(text: String) -> void:
	if hud:
		hud.set_hint(text)


## Oyuncunun E'si (PlayerController.interaction_source): süren adımın işi.
func interaction() -> Dictionary:
	if _busy or _step == null or not _running:
		return {}
	return _step.interaction()


# --- Saat ve ışık ---------------------------------------------------------------------------------------------

func _apply_clock(day_n: int) -> void:
	var c: Dictionary = scene.get("clock", {})
	var m := GameClock.parse_hhmm(c.get("start", "06:30"))
	if m < 0.0:
		m = 390.0
	var spm := float(c.get("seconds_per_minute", GameClock.SEC_PER_MIN))
	if clock == null or clock.day_n != day_n:
		clock = GameClock.new(day_n, m)
		var place := LightStops.place(LightStops.load_table(), "camp")
		clock.set_place(float(place.get("lat", Daylight.CAMP_LAT)), float(place.get("dec_offset", Daylight.CAMP_DEC_OFFSET)))
	elif m > clock.minute:
		clock.skip_to(day_n, m, &"beat")
	clock.rate = GameClock.SEC_PER_MIN / maxf(spm, 0.05)
	if _light:
		_light.use_clock(clock, false)


func _apply_light() -> void:
	if _light == null or world == null:
		return
	if _light.rig == null or not is_instance_valid(_light.rig):
		var rig := _light.attach(world)
		if rig and not rig.is_taken():
			rig.take_over(_light.prop_targets(world))
	_light.running = true
	_light.feed()


func _tick_light(delta: float) -> void:
	if _light == null or not _light.running:
		return
	_light_left -= delta
	if _light_left > 0.0 and not (clock and clock.is_lapsing()):
		return
	_light_left = LIGHT_TICK
	_light.feed()


## Gün dakikası (saat yoksa sahnenin başı).
func minute() -> float:
	return clock.minute if clock else GameClock.parse_hhmm((scene.get("clock", {}) as Dictionary).get("start", "06:30"))


## Saati anında verilen saate getirir (geri gitmez).
func set_time(when: Variant) -> void:
	var m := GameClock.parse_hhmm(when) if when is String else float(when)
	if clock and m > clock.minute:
		clock.skip_to(clock.day_n, m, &"beat")
		_light_left = 0.0


## Saat görünür biçimde dakikaya akar (seconds saniyede; geri gitmez).
func lapse_to(when: Variant, seconds: float) -> void:
	var m := GameClock.parse_hhmm(when) if when is String else float(when)
	if clock == null or m <= clock.minute + 0.001:
		return
	clock.begin_lapse(GameClock.abs_of(clock.day_n, m), maxf(seconds, 0.1), &"beat")


func pause_clock(reason: StringName, on: bool) -> void:
	if clock:
		clock.pause(reason, on)


# --- Hava -----------------------------------------------------------------------------------------------------

## Sahnenin havası: {type, snow, mist, params} (instant: perde karayken).
func _apply_weather(w: Dictionary, instant: bool) -> void:
	if weather == null or world == null:
		return
	if not weather.is_running():
		weather.begin(world, self, player, null, true)
		if weather.sim:
			# Önsöz'ün baharında da kar tutar (tipi gecesi ve karlı sabah; K110): bu düğümün havasında birikim açıktır.
			weather.sim.cfg["accumulate"] = true
	_mist = clampf(float(w.get("mist", 0.0)), 0.0, 1.0)
	set_weather(str(w.get("type", "clear")), 0.0 if instant else float(w.get("blend", 6.0)), w.get("params", {}))
	# Kar örtüsü sahnede verilmezse kalır (tipinin karı ertesi sabaha: Ö2'nin «Kuzular»ı).
	if w.has("snow"):
		set_snow(float(w["snow"]), 0.0)


## Havayı zorlar: tür (hava tablosunun kimliği), karışım (sn), ezilen değerler ({vis, wind, gust, dir_from, ...}). Sabah sisi (set_mist)
## açık türün üstüne yazılır.
func set_weather(type: String, blend: float = 6.0, params: Variant = {}) -> void:
	var same := type == _weather_type and weather != null and weather.sim != null and weather.sim.locked(WEATHER_LOCK)
	var before := _weather_params.duplicate()
	_weather_type = type
	_weather_params = (params as Dictionary).duplicate() if params is Dictionary else {}
	if same and blend > 0.0:
		_ramp_weather(before, blend)
		return
	_ramp = {}
	_lock_weather(blend)


## Aynı türde değerlerin değişimi (tipinin hafiflemesi gibi): kilit yeniden kurulunca değerler sıçramasın diye anahtarlıdır (k 0: önceki,
## k 1: yeni değerler) ve k gerçek saniyeyle ilerler (WeatherPlanner.progress). İki uçta da aynı anahtarlar olur (eksik değer havanın
## o anki değeridir).
func _ramp_weather(before: Dictionary, seconds: float) -> void:
	var to := _weather_params.duplicate()
	var from := before.duplicate()
	for key: String in to:
		if not from.has(key):
			var i := WeatherData.PARAM_KEYS.find(key)
			from[key] = weather.sim.p[i] if i >= 0 else to[key]
	for key: String in from:
		if not to.has(key):
			to[key] = from[key]
	weather.sim.lock(WEATHER_LOCK, {"type": _weather_type, "blend": 0.0, "params": to,
		"keys": [{"k": 0.0, "params": from}, {"k": 1.0, "params": to}]})
	weather.sim.progress(WEATHER_LOCK, 0.0)
	_ramp = {"t": 0.0, "s": maxf(seconds, 0.01)}


func _lock_weather(blend: float) -> void:
	if weather == null or weather.sim == null:
		return
	var p := _weather_params.duplicate()
	if _mist > 0.001 and _weather_type in ["clear", "cloud", "overcast"]:
		# Vadide yer yer sis: uzak sis koyulaşır, görüş kısalır (sisin türü değil, açık sabahın pusu).
		p.merge({"vis": lerpf(2500.0, 260.0, _mist), "fog_far_k": lerpf(1.0, 0.32, _mist), "fog_mix": lerpf(0.0, 0.5, _mist),
			"wind": lerpf(2.0, 0.6, _mist)}, false)
	weather.sim.lock(WEATHER_LOCK, {"type": _weather_type, "blend": maxf(blend, 0.0), "params": p})


## Kar örtüsü (0..1); seconds > 0 ise o sürede.
func set_snow(k: float, seconds: float = 0.0) -> void:
	_snow_target = clampf(k, 0.0, 1.0)
	if weather and weather.sim:
		if seconds <= 0.0:
			weather.sim.pack.reset(_snow_target * SNOW_PACK_PER_COVER)
	if places:
		places.set_snow(_snow_target, seconds)


## Sabah sisi (0..1): uzak sis koyulaşır (vadide yer yer sis).
func set_mist(k: float, blend: float = 0.0) -> void:
	_mist = clampf(k, 0.0, 1.0)
	_lock_weather(blend)


func _tick_weather_extras() -> void:
	if weather == null or weather.sim == null:
		return
	if not _ramp.is_empty():
		_ramp["t"] = float(_ramp["t"]) + get_process_delta_time()
		var k := clampf(float(_ramp["t"]) / float(_ramp["s"]), 0.0, 1.0)
		weather.sim.progress(WEATHER_LOCK, k)
		if k >= 1.0:
			_ramp = {}
	# Kar örtüsü baharda erimesin: hedef verildiyse örtü o düzeyde tutulur (Ö2'nin sabahı eritmeyi set_snow ile kendi yürütür).
	if _snow_target >= 0.0 and absf(weather.sim.pack.snowpack - _snow_target * SNOW_PACK_PER_COVER) > 0.004:
		weather.sim.pack.reset(_snow_target * SNOW_PACK_PER_COVER)


## Rüzgâr (m/sn vektör, x doğu, z güney): kayaların ve yurtların ardında kesilir.
func wind_at(p: Vector3) -> Vector2:
	if weather == null or weather.sim == null:
		return Vector2.ZERO
	return weather.sim.wind_at(p.x, p.z, shelter_at(p))


## Barınak (0..1): kayaların, yurtların ve ormanın rüzgâr ardı.
func shelter_at(p: Vector3) -> float:
	if places == null or weather == null or weather.sim == null:
		return 0.0
	return places.shelter_at(p, Vector2(weather.sim.fx.dir_x, weather.sim.fx.dir_z))


# --- Perde, oyuncu, eşya ---------------------------------------------------------------------------------------

func _fade(alpha: float, seconds: float) -> void:
	if fade_rect == null:
		return
	var t := create_tween()
	t.tween_property(fade_rect, "color:a", alpha, seconds).set_trans(Tween.TRANS_SINE)
	await t.finished


## Perdeyi verilen alfaya getirir (adımların kararması).
func fade(alpha: float, seconds: float) -> void:
	await _fade(alpha, seconds)


func _set_playing(on: bool) -> void:
	if state_func.is_valid():
		state_func.call(on)
	if is_instance_valid(player):
		player.set_active(on)


## Oyuncuyu sahnenin yerine koyar: {at, pose (stand, sleep, sit), yaw_deg}.
func _place_player(p: Dictionary) -> void:
	var at_point := point(p.get("at", "gol_family_door"))
	if at_point == Vector3.INF:
		at_point = point("gol_family_door")
	var yaw := deg_to_rad(float(p.get("yaw_deg", 180.0)))
	if p.has("face"):
		var f := point(p["face"])
		if f != Vector3.INF:
			var y := CampNpcs.facing_yaw(at_point, f)
			if not is_nan(y):
				yaw = y
	player.spawn_at(at_point, yaw)
	player.visible = true
	match str(p.get("pose", "stand")):
		"sleep":
			player.sit_at(Transform3D(Basis(Vector3.UP, yaw), at_point))
			var av := player.get_avatar()
			if av and not av.play_job("sleep_normally"):
				av.play_pose(&"sit")
		"sit":
			player.sit_at(Transform3D(Basis(Vector3.UP, yaw), at_point))
	if camera:
		camera.target = player
		camera.snap_to_target()


## Oyuncunun elindeki eşya (PrologueProps.make: ember_pot, milk_yoke, ...); "" bırakır.
func carry(item_id: String) -> Node3D:
	if is_instance_valid(_carried):
		_carried.queue_free()
	_carried = null
	_carried_id = item_id
	if item_id.is_empty():
		return null
	_carried = PrologueProps.make(item_id)
	if _carried == null:
		return null
	_carried.name = "Carried_" + item_id
	_root.add_child(_carried)
	if _carried.has_method(&"attach_to"):
		_carried.call(&"attach_to", player)
	return _carried


func carried() -> Node3D:
	return _carried if is_instance_valid(_carried) else null


func carried_id() -> String:
	return _carried_id if is_instance_valid(_carried) else ""


## Çocuğun yerinde oynadığı iş klibi (kütüphane anahtarı; PlayerController.work_role): durduğu sürece oynar, yürüyünce yürüyüş döner. "" bırakır.
const WORK_ROLE := &"prologue_work"


func player_work(clip_key: String) -> bool:
	if not is_instance_valid(player):
		return false
	if clip_key.is_empty():
		player.work_role = &""
		return true
	var av := player.get_avatar()
	var sk := av.get_skeleton() if av else null
	if sk == null:
		return false
	var anim := ClipVariety.library().clip_for(av.model_id, clip_key, sk)
	if anim == null:
		return false
	av.set_role_clip(WORK_ROLE, anim)
	player.work_role = WORK_ROLE
	return true


## Yükün yürüyüşe etkisi (PlayerController.move_mods: speed_k, can_run, can_jump); boş sözlük kaldırır.
func walk_mods(mods: Dictionary) -> void:
	if is_instance_valid(player):
		# Kopya: sabit sözlük (PrologueStep.HOLD_MODS) salt okunurdur.
		player.move_mods = mods.duplicate()


# --- Yer -------------------------------------------------------------------------------------------------------

## Yer: işaret kimliği (PrologueWorld.marker) ya da [x, z]; zemine oturur. Bilinmiyorsa Vector3.INF.
func point(spec: Variant) -> Vector3:
	if spec is String:
		return places.marker(spec) if places else Vector3.INF
	if spec is Array and (spec as Array).size() >= 2:
		var x := float(spec[0])
		var z := float(spec[1])
		return Vector3(x, ground_y(x, z), z)
	if spec is Vector3:
		return spec
	return Vector3.INF


func points(list: Variant) -> Array:
	var out: Array = []
	if list is Array:
		for p: Variant in list:
			var v := point(p)
			if v != Vector3.INF:
				out.append(v)
	return out


func ground_y(x: float, z: float) -> float:
	var shape: Variant = world.call(&"get_terrain_shape") if world and world.has_method(&"get_terrain_shape") else null
	return float((shape as Object).call(&"height_at", x, z)) if shape is Object else 0.0


func near(p: Vector3, radius: float) -> bool:
	if p == Vector3.INF or not is_instance_valid(player):
		return false
	return Vector2(player.global_position.x - p.x, player.global_position.z - p.z).length() <= radius


## Ateş başı halkının oturuş yeri (CampNpcs düğüm adı: Mother, Father, OlderBrother, Elder, Child): menüdeki yer.
func seat_point(node_name: String) -> Vector3:
	var npcs := world.get_node_or_null(CAMP_NPCS) as Node3D if world else null
	var n := npcs.get_node_or_null(NodePath(node_name)) as Node3D if npcs else null
	return n.global_position if n else Vector3.INF


func root() -> Node3D:
	return _root


# --- Ses -------------------------------------------------------------------------------------------------------

func sfx(id: String, at_point: Variant = null, db: float = 0.0, pitch: float = 1.0) -> void:
	if sound:
		sound.sfx(id, at_point if at_point is Vector3 else Vector3.INF, db, pitch)


func bed(id: String, on: bool, db: float = 0.0, seconds: float = 2.5) -> void:
	if sound:
		sound.bed(id, on, db, seconds)


func music(id: String, seconds: float = 3.0) -> void:
	if sound:
		sound.music(id, seconds)


# --- Atlama, sinema, durma -------------------------------------------------------------------------------------

## Esc basılı tutuldu (main.gd): Önsöz atlanır (günler ve sinema).
func skip() -> void:
	if _done or _stopped:
		return
	_busy = true
	_set_playing(false)
	await _fade(1.0, CineHost.SKIP_FADE)
	_finish("skipped")


## Sinemaya geçiş (K110; «Ocak»ın sonu): HUD söner, oyuncu durur, ateş başı halkı menüdeki yerinde oturur, kamera 1,6 sn'de menü kadrajına
## döner, ışık ve hava menünün kimliğine süzülür; sonra finished({ending: "cinema"}): main.gd Önsöz sinemasını 0'dan oynatır.
func to_cinema() -> void:
	if _done or _stopped:
		return
	_busy = true
	_set_playing(false)
	_stop_step()
	if voice:
		voice.stop()
	if hud:
		hud.clear()
	if game_hud:
		game_hud.set_quest_source(null)
		game_hud.hide_now()
	if is_instance_valid(player):
		player.set_active(false)
	# Ateş başı halkı menüdeki yerinde: koşucunun kişileri gizlenir, oyuncunun Çocuğu kalkar, kamptaki Çocuk oturur.
	if cast:
		cast.hide_all()
	carry("")
	places.set_family_yurt(false)
	_hide_camp_npcs(false)
	if sound:
		sound.stop_all(CINEMA_RETURN_S)
	var cam: Camera3D = camera.camera if camera else null
	if menu_camera and cam:
		menu_camera.global_transform = cam.global_transform
		menu_camera.keep_aspect = Camera3D.KEEP_HEIGHT
		menu_camera.fov = cam.fov
		menu_camera.make_current()
	if camera:
		camera.set_active(false)
	if _light and _light.running:
		_light.end(CINEMA_RETURN_S)
	if weather and weather.is_running():
		weather.end(CINEMA_RETURN_S)
	player.visible = false
	if menu_camera and menu_camera.has_method(&"return_to_menu"):
		await menu_camera.call(&"return_to_menu", CINEMA_RETURN_S)
	else:
		await get_tree().create_timer(CINEMA_RETURN_S).timeout
	_finish("cinema")


## Günün sözleri istenir (önceki günün sözleri bırakılır).
func _request_day_lines(di: int) -> void:
	_release_day_lines()
	_day_lines = PrologueDays.day_line_ids(order, di, lines)
	var am := get_node_or_null(^"/root/AudioManager")
	if am and am.has_method(&"request_lines"):
		am.call(&"request_lines", _day_lines)


func _release_day_lines() -> void:
	if _day_lines.is_empty():
		return
	var am := get_node_or_null(^"/root/AudioManager")
	if am and am.has_method(&"release_lines"):
		am.call(&"release_lines", _day_lines)
	_day_lines = PackedStringArray()


## Günün istenen sözleri (sınama).
func day_lines() -> PackedStringArray:
	return _day_lines


func _finish(ending: String) -> void:
	if _done:
		return
	_done = true
	_release_day_lines()
	_ending = ending
	_running = false
	finished.emit({"ending": ending, "flags": flags.duplicate(), "results": results.duplicate()})


## Sonuç bilgisi (sınama).
func ending() -> String:
	return _ending


## Durdurur ve bıraktığı her şeyi geri alır (bitişte de, yarıda bırakılınca da): dünya, kişiler, ışık, hava, ses, yürünür alan.
func stop() -> void:
	if _stopped:
		return
	_stopped = true
	_running = false
	_stop_step()
	if voice:
		voice.stop()
	_release_day_lines()
	if is_instance_valid(player):
		player.play_area_extra = _saved_extra.duplicate()
		player.extra_obstacles = _saved_obstacles.duplicate()
		player.external_drift = Vector3.ZERO
		player.move_mods = {}
		player.work_role = &""
		player.bow_prompt = _saved_bow_prompt
		if _saved_interaction.is_valid():
			player.interaction_source = _saved_interaction
		player.refresh_obstacles()
	carry("")
	if cast:
		cast.clear()
	if places:
		places.teardown()
	if sound:
		sound.stop_all(0.6)
	if _light and _light.running:
		_light.end(0.0)
	if weather:
		weather.end(0.0)
	_hide_camp_npcs(false)
	if is_instance_valid(hud):
		hud.clear()
		hud.queue_free()
	hud = null
	if is_instance_valid(_root):
		_root.queue_free()
	_root = null


func _exit_tree() -> void:
	stop()


func _hide_camp_npcs(on: bool) -> void:
	var npcs := world.get_node_or_null(CAMP_NPCS) as Node3D if is_instance_valid(world) else null
	if npcs == null or _npcs_hidden == on:
		return
	_npcs_hidden = on
	npcs.visible = not on
	npcs.process_mode = Node.PROCESS_MODE_DISABLED if on else Node.PROCESS_MODE_INHERIT


# --- Yardımcılar ------------------------------------------------------------------------------------------------

## Dilin metni: {tr, en} sözlüğü (dilde yoksa TR) ya da düz yazı.
func text_of(entry: Variant) -> String:
	if entry is Dictionary:
		var d: Dictionary = entry
		return str(d.get(lang, d.get("tr", "")))
	return str(entry) if entry != null else ""


## Kişilerin hız sınırı (K105): oyuncunun en yüksek koşusu.
func speed_cap() -> float:
	return PaceLimit.run_cap(player)


func pace(speed: float) -> float:
	return PaceLimit.limit(speed, speed_cap())


## Yolculuğa yazılacak işaret (günün başındaki kayıtta ve Önsöz'ün sonunda).
func flag(key: String, value: Variant = true) -> void:
	flags[key] = value
