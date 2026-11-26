class_name CineHost
extends Node
## Sinemanın sahnedeki konağı (main.tscn'de Main'in çocuğu; godot.md §3.6, §4.1): bir diziyi ya da tek bir
## segment dosyasını oynatır. Saati CineRunner tutar, çizelgeyi CineTimeline çözer; konak olayları uygular:
##   - Segment sahnesi (CineScene): view "main" ise ana 3B dünyada (konağın çocuğu); "overlay" ise kendi
##     dünyası olan bir SubViewport'ta (own_world_3d), katman 0'da: boyalı süzgecin (1) ve perdenin (UI, 5)
##     altında. Opak overlay sürerken ana 3B çizilmez (önceden çizilen bir dünya yoksa). Video oynatan sahne
##     (K93; CineVideo) use_video_layer ile katmanını süzgecin üstüne alır: video süzgeçten geçmez, altındaki 3B geçer. Opak
##     videonun altında ana 3B de boşa çizilmez: örneklenen dünya yalnız VIDEO_PREDRAW_FRAMES kare önceden çizilir (gölgelendiriciler
##     geçişten önce derlenir), sönme başlayınca açılır; ana görünümde oynayan sahne cover_main_3d ile aynısını ister.
##   - Dünya: "camp" kamp dünyasıdır. release_camp onu gizler, sürecini durdurur, ses kaynaklarını ve AudioManager'ın
##     gece çayırını susturur, WorldEnvironment'ını yeni dünyaya bırakır; restore_camp anlık görüntüyü geri yazar (act-1-p1'in
##     WorldHost'u gelince bırakma ona geçer). Yolu verilen dünya preload_world ile arka planda yüklenir
##     (durum her kare sorulur), instantiate_world ile örneklenip eklenir (show_world: ilk karesi opak
##     katmanın altında önceden çizilir); segment başlarken dünyası hazır değilse (is_ready) sinema saati
##     bekler. Dizi bitince örneklenen dünya bırakılır, kamp geri gelir.
##   - Perde (UI/Fade; yoksa konağın kendi perdesi), kart (Cinzel, alt üçte bir), altyazı (SubtitleBar,
##     katman 6), ses (CineAudio → AudioManager).
##   - Şarkı sürerken sinema saati şarkının çalış konumuna kilitlenir (>50 ms sapma düzeltilir).
##   - Basılı Esc (pause) ya da oyun kolu B (ui_cancel) ≥0,6 sn atlar (sağ altta ilerleme halkası): 0,5 sn
##     kararma, ses durur, sahnelerin restore()'u, bekleyen yüklemeler bırakılır, finished(true).
##   - Sinema sürerken saat durur: clock_hold_changed(true) … (false). GameClock (act-1-p1) gelince "cine"
##     nedeniyle bağlanır; bugün yalnız journey.play_time'ın CINE durumunda artmamasıdır (main.gd).
## Bitişte perde karadır (dizi kararmadan biterse 0,5 sn'de kararır): sonraki ekran kara perdeden açılır.
##
##   var skipped: bool = await cine.play("res://data/cine/prologue.json")
##   cine.play("res://data/cine/test_timeline.json", 6.5)    # 6,5 sn'ye sessizce ileri sarar (--cine-at)

signal finished(skipped: bool)
signal clock_hold_changed(on: bool)
signal segment_started(seg_id: String)

## Önsöz oynadı ya da atlandı: oluşturucu onayında yolculuğa yazılır (journey.reset işaretleri siler).
const PROLOGUE_FLAG := "onsoz"
## Atlamak için basılı tutma süresi ve atlamanın kararması (saniye).
const SKIP_HOLD := 0.6
const SKIP_FADE := 0.5
## Dizi kararmadan biterse perdenin kararma süresi.
const END_FADE := 0.5
## Şarkının çalış konumuyla sinema saati arasında düzeltilen en küçük fark (saniye).
const LOCK_TOLERANCE := 0.05
## Overlay segmentinin katmanı (boyalı süzgeç 1'de; video CineVideo.LAYER'da) ve konağın arayüz katmanı (perde 5'te).
const VIEW_LAYER := 0
const UI_LAYER := 6
const FADE_LAYER := 5
const CARD_FADE := 0.6
const CARD_FONT_SIZE := 40
## Video kipinde örneklenen dünyanın opak videonun altında önceden çizildiği kare (hazır olduktan sonra).
const VIDEO_PREDRAW_FRAMES := 30
## Atlama eylemleri: Esc ve oyun kolunun Start'ı (pause), Esc ve oyun kolunun B'si (ui_cancel).
const SKIP_ACTIONS: Array[StringName] = [&"pause", &"ui_cancel"]

## Bağlam: main.gd bağlar; cine_preview kendisi kurar. Sahnelere ctx olarak gider.
var main_node: Node
## Kamp dünyası ("camp" segmentinin dünyası; release_camp / restore_camp).
var world: Node3D
var menu_camera: Camera3D
## Perde (UI/Fade); boşsa konak kendi perdesini kurar.
var fade_rect: ColorRect
var audio: CineAudio
## Sinema hızı (--cine-speed): saat bu oranla akar, perde ve kart geçişleri bu oranla kısalır.
var speed := 1.0
## Şarkı sürerken saat şarkıya kilitlensin mi (hız ve Engine.time_scale 1 iken)?
var lock_to_song := true
## Opak overlay sürerken ana 3B kapatılsın mı?
var disable_3d_under_overlay := true
## Yükleme durumunu soran işlev: (yol) → ResourceLoader.ThreadLoadStatus. Boşsa ResourceLoader (sınama verir).
var load_status_func: Callable
## Bekleyen yüklemelerin durumu kaç kez soruldu (her kare her bekleyen için bir kez).
var load_polls := 0
## Örneklenen dünyaların örnekleme süresi (milisaniye; yol → süre).
var instantiate_ms: Dictionary = {}
## Saat kilidinin düzeltme sayısı.
var lock_corrections := 0

var runner := CineRunner.new()
var subtitles: SubtitleBar

var _playing := false
var _skipping := false
var _finishing := false
var _skip_hold := 0.0
## Açık segmentler: kimlik → {node, layer, seg, opaque}.
var _scenes: Dictionary = {}
## Yükleme: istenip bekleyen (yol → true), yüklenen (yol → Resource), yüklenince örneklenecek dünya,
## yüklenemeyen yol ve örneklenen dünyalar (yol → Node).
var _pending: Dictionary = {}
var _loaded: Dictionary = {}
var _want_world: Dictionary = {}
var _failed: Dictionary = {}
var _worlds: Dictionary = {}
## release_camp'in anlık görüntüsü (boşsa kamp yerinde).
var _camp: Dictionary = {}
## Dünyası hazır olmayan segmentin bekleyen girişi: {ev, path}.
var _waiting: Dictionary = {}
var _seek_target := -1.0
## Ana 3B'nin konaktan önceki disable_3d'si (-1: konak dokunmadı).
var _3d_saved := -1
## Video kipinde: dünyanın önceden çizilmesinin kalan karesi ve ana görünümü örten video (cover_main_3d).
var _predraw_left := 0
var _video_cover := false
var _lines := PackedStringArray()
var _ui: CanvasLayer
var _own_fade: ColorRect
var _card_box: Control
var _card: Label
var _ring: _SkipRing
var _fade_tween: Tween
var _card_tween: Tween
var _overlay_tweens: Array[Tween] = []


func _ready() -> void:
	if audio == null:
		audio = CineAudio.new(CineAudio.autoload())
	_build_ui()
	set_process(false)


func _exit_tree() -> void:
	# Sinema sürerken silinen konak (ör. sınamanın sonunda Main) ana 3B'yi kapalı bırakmasın.
	_restore_main_3d()


# --- Oynatma ---------------------------------------------------------------------------------------

## Diziyi ya da segmenti oynatır (dosya yolu, Dictionary ya da CineTimeline); at > 0 ise oraya sessizce
## ileri sarar. Döner: finished sinyali (await edilebilir; atlandıysa true). Açılamayan dizi bir sonraki
## karede finished(true) yayar. Oynarken yeni istek yok sayılır.
func play(source: Variant, at: float = 0.0) -> Signal:
	if _playing:
		push_warning("[cine] zaten oynuyor; yeni istek yok sayıldı")
		return finished
	runner = CineRunner.new()
	if not runner.load(source):
		push_warning("[cine] dizi açılamadı: %s %s" % [source, runner.timeline.validate()])
		_emit_finished.call_deferred(true)
		return finished
	for problem in runner.timeline.validate():
		push_warning("[cine] %s: %s" % [runner.timeline.id, problem])
	runner.fired.connect(_on_fired)
	runner.finished.connect(_on_runner_finished)
	_playing = true
	_skipping = false
	_finishing = false
	_skip_hold = 0.0
	_waiting = {}
	_seek_target = -1.0
	_predraw_left = 0
	_video_cover = false
	lock_corrections = 0
	_lines = runner.timeline.line_ids()
	subtitles.lang = SubtitleBar.ui_lang()
	subtitles.film_frame = true
	subtitles.set_windows(_subtitle_windows())
	audio.request_lines(_lines)
	_request_scenes()
	set_process(true)
	clock_hold_changed.emit(true)
	if at > 0.0:
		_seek(at)
	return finished


func is_playing() -> bool:
	return _playing


func is_skipping() -> bool:
	return _skipping


## Sinema saati (saniye, dizinin başından).
func time() -> float:
	return runner.time


## Olayın başından bu yana geçen sinema süresi: ileri sarmada sarmanın vardığı saate dek (≥ 0).
func elapsed_since(ev: Dictionary) -> float:
	return runner.elapsed_since(ev)


func timeline() -> CineTimeline:
	return runner.timeline


## Atlama basışının doluluğu (0..1; sağ alttaki halka).
func skip_progress() -> float:
	return clampf(_skip_hold / SKIP_HOLD, 0.0, 1.0)


## Sinemayı atlar: 0,5 sn kararma, ses durur, sahnelerin restore()'u, örneklenen dünya bırakılır, kamp
## geri gelir, bekleyen yüklemeler bırakılır; finished(true).
func skip() -> void:
	if not _playing or _skipping or _finishing:
		return
	_skipping = true
	_skip_hold = 0.0
	_ring.progress = 0.0
	runner.skip()
	audio.stop_all(SKIP_FADE)
	subtitles.clear()
	_hide_card()
	await fade(1.0, SKIP_FADE)
	_finish(true)


## Kararmadan hemen durdurur (önizlemenin yeniden oynatması, çıkış): her şey geri yazılır; finished(true).
func stop() -> void:
	if not _playing:
		return
	runner.skip()
	audio.stop_all(0.0)
	_finish(true)


# --- Perde, kart, overlay -----------------------------------------------------------------------------

## Perdeyi (UI/Fade ya da konağın kendi perdesi) sec sn'de alpha'ya götürür. Döner: geçişin finished'ı.
func fade(alpha: float, sec: float) -> Signal:
	var rect := _fade_rect()
	_kill_fade()
	_fade_tween = create_tween()
	_fade_tween.tween_property(rect, ^"color:a", clampf(alpha, 0.0, 1.0), maxf(sec, 0.0))
	return _fade_tween.finished


## Perdenin şimdiki örtüsü (0 açık, 1 kara).
func fade_alpha() -> float:
	return _fade_rect().color.a


## Opak overlay katmanları sec sn'de söner: altındaki ana 3B (önceden çizilen dünya) görünür.
func crossfade(sec: float) -> void:
	for entry: Dictionary in _scenes.values():
		var layer := entry.get("layer") as CanvasLayer
		if layer == null or not bool(entry.get("opaque", false)):
			continue
		entry["opaque"] = false
		var tween := create_tween()
		tween.tween_property(layer.get_node(^"View"), ^"modulate:a", 0.0, maxf(sec, 0.0) / _rate())
		_overlay_tweens.append(tween)
	_update_main_3d()


## Alt üçte bir kart (Cinzel): sec sn görünür; girişte ve çıkışta yumuşakça.
func card(text: String, sec: float) -> void:
	if _card_tween and _card_tween.is_valid():
		_card_tween.kill()
	_card.text = text
	_card_box.visible = true
	_card_box.modulate.a = 0.0
	var edge := minf(CARD_FADE, sec * 0.5)
	_card_tween = create_tween()
	_card_tween.tween_property(_card_box, ^"modulate:a", 1.0, edge)
	_card_tween.tween_interval(maxf(sec - edge * 2.0, 0.0))
	_card_tween.tween_property(_card_box, ^"modulate:a", 0.0, edge)
	_card_tween.tween_callback(_hide_card)


func card_text() -> String:
	return _card.text if _card_box.visible else ""


# --- Dünya ----------------------------------------------------------------------------------------

## Kamp dünyasını bırakır: gizlenir, süreci durur, ses kaynakları susar, WorldEnvironment'ı yeni dünyaya
## yer açar. Anlık görüntü restore_camp ile geri yazılır.
func release_camp() -> void:
	if not is_instance_valid(world) or not _camp.is_empty():
		return
	var players: Array = []
	for type in ["AudioStreamPlayer", "AudioStreamPlayer2D", "AudioStreamPlayer3D"]:
		for player in world.find_children("*", type, true, false):
			players.append([player, bool(player.get(&"stream_paused"))])
			player.set(&"stream_paused", true)
	var envs: Array = []
	for env: WorldEnvironment in world.find_children("*", "WorldEnvironment", true, false):
		envs.append([env, env.environment])
		env.environment = null
	_camp = {"visible": world.visible, "process_mode": world.process_mode, "players": players, "envs": envs}
	world.visible = false
	world.process_mode = Node.PROCESS_MODE_DISABLED
	if audio:
		audio.call_target(&"suspend_meadow", [true])


## Kamp dünyasını bıraktığı hâline döndürür (görünürlük, süreç, ses kaynakları, ortam).
func restore_camp() -> void:
	if _camp.is_empty():
		return
	var snap := _camp
	_camp = {}
	if audio:
		audio.call_target(&"suspend_meadow", [false])
	if not is_instance_valid(world):
		return
	world.process_mode = snap["process_mode"]
	world.visible = snap["visible"]
	for pair: Array in snap["envs"]:
		if is_instance_valid(pair[0]):
			(pair[0] as WorldEnvironment).environment = pair[1]
	for pair: Array in snap["players"]:
		if is_instance_valid(pair[0]):
			(pair[0] as Node).set(&"stream_paused", pair[1])


func is_camp_released() -> bool:
	return not _camp.is_empty()


## Dünyayı (ya da sahneyi) arka planda yükletir (load_threaded_request); durum her kare sorulur.
func preload_world(path: String) -> void:
	_request(path)


## Yüklemenin durumu: bekliyor (IN_PROGRESS), yüklendi (LOADED), yok ya da bozuk (FAILED / INVALID).
func load_state(path: String) -> int:
	if _worlds.has(path) or _loaded.has(path):
		return ResourceLoader.THREAD_LOAD_LOADED
	if _pending.has(path):
		return ResourceLoader.THREAD_LOAD_IN_PROGRESS
	return ResourceLoader.THREAD_LOAD_FAILED if _failed.has(path) else ResourceLoader.THREAD_LOAD_INVALID_RESOURCE


func is_loading() -> bool:
	return not _pending.is_empty()


## Dünyayı örnekler ve ekler (show_world). Yükleme sürüyorsa yüklenince örneklenir (null döner); yüklenmesi
## istenmemişse eşzamanlı yüklenir. Örnekleme süresi instantiate_ms'e yazılır.
func instantiate_world(path: String) -> Node:
	if _worlds.has(path):
		return _worlds[path]
	if _pending.has(path):
		_want_world[path] = true
		return null
	var res: Resource = _loaded.get(path)
	_loaded.erase(path)
	if res == null and ResourceLoader.exists(path):
		res = ResourceLoader.load(path)
	var scene := res as PackedScene
	if scene == null:
		push_warning("[cine] dünya örneklenemedi: %s" % path)
		_failed[path] = true
		return null
	var started := Time.get_ticks_usec()
	var node := scene.instantiate()
	instantiate_ms[path] = (Time.get_ticks_usec() - started) / 1000.0
	show_world(node, path)
	return node


## Dünyayı ana sahneye ekler (Main'in, yoksa konağın çocuğu). İlk karesi opak katmanın (overlay ya da perde)
## altında çizilir: gölgelendiriciler geçişten önce derlenir.
func show_world(node: Node, key: String = "") -> void:
	var parent: Node = main_node if is_instance_valid(main_node) else self
	if node.get_parent() == null:
		parent.add_child(node)
	_worlds[key if not key.is_empty() else str(node.get_path())] = node
	_predraw_left = VIDEO_PREDRAW_FRAMES
	_update_main_3d()


## Örneklenen dünya (yol → düğüm; yoksa null).
func world_node(path: String) -> Node:
	return _worlds.get(path)


## Segmentin sahnesi (açık değilse null).
func scene_node(seg_id: String) -> Node:
	var entry: Dictionary = _scenes.get(seg_id, {})
	return entry.get("node")


## Overlay segmentinin SubViewport'u (açık değilse null).
func overlay_viewport(seg_id: String) -> SubViewport:
	var layer := (_scenes.get(seg_id, {}) as Dictionary).get("layer") as CanvasLayer
	return layer.get_node(^"View/Viewport") as SubViewport if layer else null


## Overlay segmenti video oynatıyor (K93): katmanı CineVideo.LAYER'a geçer, 3B'si çizilmez. Sahne setup'ında çağırır. Sönme
## (crossfade) ve kapanma overlay'in kendisini sürer, değişmez.
func use_video_layer(seg_id: String) -> void:
	var layer := (_scenes.get(seg_id, {}) as Dictionary).get("layer") as CanvasLayer
	if layer == null:
		return
	layer.layer = CineVideo.LAYER
	(layer.get_node(^"View/Viewport") as SubViewport).disable_3d = true
	(_scenes[seg_id] as Dictionary)["video"] = true
	_update_main_3d()


## Video ana görünümün üstünde opak durur (doğumun son 10 sn'si): altındaki 3B çizilmez. Sahne restore'da kapatır.
func cover_main_3d(on: bool) -> void:
	_video_cover = on
	_update_main_3d()


# --- Kare ------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	_poll_loads()
	if not _playing:
		if _pending.is_empty():
			set_process(false)
		return
	_tick_predraw()
	_update_skip(delta)
	if _skipping or _finishing:
		return
	if not _waiting.is_empty():
		_try_open_waiting()
	if not runner.held and not runner.done:
		if _seek_target >= 0.0:
			_seek(_seek_target)
		else:
			var dt := minf(delta, CineRunner.MAX_STEP) * maxf(speed, 0.0)
			while dt > 0.0 and not runner.done and not runner.held:
				var part := minf(dt, CineRunner.MAX_STEP)
				runner.step(part)
				dt -= part
			_lock_to_song()
	if _playing and not _skipping:
		subtitles.show_at(runner.time)


func _input(event: InputEvent) -> void:
	if not _playing:
		return
	for action in SKIP_ACTIONS:
		if InputMap.has_action(action) and event.is_action(action):
			# Esc sinemada yalnız atlamadır: duraklatmaya ve menülere gitmez.
			get_viewport().set_input_as_handled()
			return


## Basılı tutma süresini sayar; SKIP_HOLD'a varınca atlar.
func _update_skip(delta: float) -> void:
	if _skipping or _finishing:
		_ring.progress = 0.0
		return
	_skip_hold = _skip_hold + delta if _skip_pressed() else 0.0
	_ring.progress = skip_progress()
	if _skip_hold >= SKIP_HOLD:
		skip()


static func _skip_pressed() -> bool:
	for action in SKIP_ACTIONS:
		if InputMap.has_action(action) and Input.is_action_pressed(action):
			return true
	return false


func _seek(t: float) -> void:
	_seek_target = t
	runner.seek(t)
	if not runner.held:
		_seek_target = -1.0
	subtitles.show_at(runner.time)


## Şarkı sürerken saati şarkının çalış konumuna eşler (yalnız gerçek hızda: hızlandırılmış sınama ve
## önizleme kilitlenmez).
func _lock_to_song() -> void:
	if not lock_to_song or not is_equal_approx(speed, 1.0) or not is_equal_approx(Engine.time_scale, 1.0):
		return
	for ev in runner.active("song"):
		var position := audio.song_position(str(ev.get("line", "")))
		if position < 0.0:
			continue
		var wanted := float(ev["t"]) + position
		if absf(wanted - runner.time) > LOCK_TOLERANCE:
			runner.sync_to(wanted)
			lock_corrections += 1
		return


# --- Olaylar ---------------------------------------------------------------------------------------

func _on_fired(ev: Dictionary, seeking: bool) -> void:
	var type := str(ev["type"])
	if type == CineTimeline.ENTER:
		_enter_segment(ev)
		return
	if type == CineTimeline.EXIT:
		_close_scene(str(ev["segment"]))
		_update_main_3d()
		return
	if type == CineTimeline.VOICE:
		# Satırın ve şarkının sesi PREROLL önce istenir: ses çizelgedeki anında başlar.
		audio.handle(ev["cue"], seeking)
		return
	var scene := _scene_of(ev)
	if type == "shot":
		if scene and scene.has_method(&"on_shot"):
			_mark_seeking(scene, seeking)
			scene.call(&"on_shot", str(ev.get("name", "")), ev)
		return
	match type:
		"fade":
			_fade_event(ev)
		"card":
			_card_event(ev)
		"crossfade":
			crossfade(float(ev.get("dur", 0.0)))
		"preload":
			preload_world(str(ev.get("path", "")))
		"instantiate":
			instantiate_world(str(ev.get("path", "")))
		"release_camp":
			release_camp()
		"restore_camp":
			restore_camp()
		_:
			if CineAudio.handles(type) and not CineTimeline.LINE_TYPES.has(type):
				audio.handle(ev, seeking)
	if scene and scene.has_method(&"on_event"):
		_mark_seeking(scene, seeking)
		scene.call(&"on_event", ev)


func _on_runner_finished(was_skipped: bool) -> void:
	if was_skipped or _skipping or _finishing or not _playing:
		return
	_finishing = true
	audio.stop_all(END_FADE)
	if fade_alpha() < 0.999:
		await fade(1.0, END_FADE)
	_finish(false)


func _emit_finished(was_skipped: bool) -> void:
	finished.emit(was_skipped)


## Sona varınca ya da atlanınca: sahneler geri yazılır ve silinir, dünya bırakılır, kamp geri gelir.
## Bir kez çalışır (atlamanın kararması sürerken stop() çağrılsa da).
func _finish(was_skipped: bool) -> void:
	if not _playing:
		return
	# Süren perde geçişi kalmasın: sonraki ekran perdeyi kendisi yönetir.
	_kill_fade()
	_waiting = {}
	_seek_target = -1.0
	var ids: Array = _scenes.keys()
	ids.reverse()
	for seg_id: String in ids:
		_close_scene(seg_id)
	var keep := runner.timeline != null and runner.timeline.keep_world
	for path: String in _worlds.keys():
		var node: Node = _worlds[path]
		if is_instance_valid(node) and not keep:
			node.queue_free()
	_worlds.clear()
	_want_world.clear()
	# Bekleyen yüklemeler bırakılır: yüklenince alınıp atılır (_poll_loads), yüklenenler tutulmaz.
	_loaded.clear()
	restore_camp()
	for tween in _overlay_tweens:
		if tween.is_valid():
			tween.kill()
	_overlay_tweens.clear()
	_predraw_left = 0
	_video_cover = false
	_restore_main_3d()
	audio.release_lines(_lines)
	subtitles.clear()
	_hide_card()
	_ring.progress = 0.0
	_playing = false
	_skipping = false
	_finishing = false
	clock_hold_changed.emit(false)
	finished.emit(was_skipped)


## Segmentin girişi: dünyası (yol) hazır değilse saat bekler, hazır olunca sahne kurulur.
func _enter_segment(ev: Dictionary) -> void:
	var seg := runner.timeline.segment(str(ev["segment"]))
	if seg.is_empty():
		return
	var kind := str(seg["world"])
	if kind.begins_with("res://") and not _world_ready(kind):
		_waiting = {"ev": ev, "path": kind}
		runner.hold()
		return
	_open_segment(seg)


func _try_open_waiting() -> void:
	var path := str(_waiting["path"])
	if not _failed.has(path) and not _world_ready(path):
		return
	var ev: Dictionary = _waiting["ev"]
	_waiting = {}
	_open_segment(runner.timeline.segment(str(ev["segment"])))
	runner.resume()


## Dünya örneklendi ve hazır mı? Örneklenmemişse örnekletir (yükleme sürüyorsa yüklenince).
func _world_ready(path: String) -> bool:
	var node: Node = _worlds.get(path)
	if node == null and not _failed.has(path):
		node = instantiate_world(path)
	if node == null:
		return false
	return not node.has_method(&"is_ready") or bool(node.call(&"is_ready"))


func _open_segment(seg: Dictionary) -> void:
	var seg_id := str(seg["id"])
	var kind := str(seg["world"])
	var seg_world: Node = null
	if kind == CineTimeline.WORLD_CAMP:
		restore_camp()
		seg_world = world
	elif kind.begins_with("res://"):
		# Kendi dünyası olan segment kampın üstüne açılmaz: dizide kamp çoktan bırakılmıştır, tek başına oynatılan segmentte
		# (--cine, önizleme) burada bırakılır; bitişte konak geri getirir.
		release_camp()
		seg_world = _worlds.get(kind)
	var node := _instantiate_scene(seg["scene"])
	var layer: CanvasLayer = null
	if str(seg["view"]) == CineTimeline.VIEW_OVERLAY:
		layer = _make_overlay(seg_id)
		if node:
			layer.get_node(^"View/Viewport").add_child(node)
	elif node:
		add_child(node)
	_scenes[seg_id] = {"node": node, "layer": layer, "seg": seg, "opaque": layer != null}
	if node and node.has_method(&"setup"):
		node.call(&"setup", _context(seg, seg_world))
	var cross := float(seg["crossfade_in"]) / _rate()
	if cross > 0.0:
		if layer:
			var view := layer.get_node(^"View") as Control
			view.modulate.a = 0.0
			var tween := create_tween()
			tween.tween_property(view, ^"modulate:a", 1.0, cross)
			_overlay_tweens.append(tween)
		else:
			crossfade(float(seg["crossfade_in"]))
	_update_main_3d()
	segment_started.emit(seg_id)


func _close_scene(seg_id: String) -> void:
	var entry: Dictionary = _scenes.get(seg_id, {})
	if entry.is_empty():
		return
	_scenes.erase(seg_id)
	var node: Node = entry.get("node")
	if is_instance_valid(node):
		if node.has_method(&"restore"):
			node.call(&"restore")
		node.queue_free()
	var layer: CanvasLayer = entry.get("layer")
	if is_instance_valid(layer):
		layer.queue_free()


func _context(seg: Dictionary, seg_world: Node) -> Dictionary:
	return {"main": main_node, "world": seg_world, "camp": world, "menu_camera": menu_camera,
		"fade": _fade_rect(), "audio": audio, "host": self, "segment": seg}


func _scene_of(ev: Dictionary) -> Node:
	var entry: Dictionary = _scenes.get(str(ev.get("segment", "")), {})
	var node: Node = entry.get("node")
	return node if is_instance_valid(node) else null


static func _mark_seeking(scene: Node, seeking: bool) -> void:
	if &"seeking" in scene:
		scene.set(&"seeking", seeking)


func _fade_event(ev: Dictionary) -> void:
	var to := clampf(float(ev.get("to", 1.0)), 0.0, 1.0)
	var dur := maxf(float(ev.get("dur", 0.0)), 0.0)
	var gone := runner.elapsed_since(ev)
	if dur <= 0.0 or gone >= dur:
		_kill_fade()
		_fade_rect().color.a = to
		return
	if gone > 0.0:
		var rect := _fade_rect()
		rect.color.a = lerpf(rect.color.a, to, gone / dur)
	fade(to, (dur - gone) / _rate())


func _card_event(ev: Dictionary) -> void:
	var dur := maxf(float(ev.get("dur", 0.0)), 0.0)
	var gone := runner.elapsed_since(ev)
	if gone >= dur:
		return
	card(_card_text(ev), (dur - gone) / _rate())


func _card_text(ev: Dictionary) -> String:
	var lang := subtitles.lang
	var text: Variant = ev.get("text")
	if text is String:
		return text
	var source: Dictionary = text if text is Dictionary else ev
	for key in [lang, "tr", "en"]:
		if source.get(key) is String and not str(source[key]).is_empty():
			return source[key]
	return ""


func _subtitle_windows() -> Array:
	var out: Array = []
	for ev in runner.timeline.line_events():
		if ev.get("subtitle", true) == false:
			continue
		out.append_array(SubtitleBar.line_windows(str(ev.get("line", "")), float(ev["t"]), float(ev["duration"]), subtitles.lang))
	return out


# --- Yükleme ---------------------------------------------------------------------------------------

## Segment sahnelerini arka planda istetir (kurulurken bekletmesin).
func _request_scenes() -> void:
	for seg in runner.timeline.segments:
		var scene: Variant = seg["scene"]
		if scene is String and not (scene as String).is_empty() and ResourceLoader.exists(scene):
			_request(scene)


func _request(path: String) -> bool:
	if path.is_empty() or _pending.has(path) or _loaded.has(path) or _worlds.has(path):
		return true
	if not ResourceLoader.exists(path):
		push_warning("[cine] yüklenecek dosya yok: %s" % path)
		_failed[path] = true
		return false
	var err := ResourceLoader.load_threaded_request(path, "", true)
	if err != OK:
		push_warning("[cine] arka plan yüklemesi başlamadı (%d): %s" % [err, path])
		_failed[path] = true
		return false
	_failed.erase(path)
	_pending[path] = true
	set_process(true)
	return true


## Bekleyen yüklemelerin durumunu sorar (her kare). Yüklenen kaynak sinema sürüyorsa tutulur, sinema bittiyse
## alınıp bırakılır (yükleme görevi kapanır).
func _poll_loads() -> void:
	for path: String in _pending.keys():
		load_polls += 1
		var status := _load_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			continue
		_pending.erase(path)
		if status != ResourceLoader.THREAD_LOAD_LOADED:
			push_warning("[cine] yüklenemedi: %s" % path)
			_failed[path] = true
			continue
		var res := ResourceLoader.load_threaded_get(path)
		if not _playing:
			continue
		_loaded[path] = res
		if _want_world.has(path):
			_want_world.erase(path)
			instantiate_world(path)


func _load_status(path: String) -> int:
	if load_status_func.is_valid():
		return int(load_status_func.call(path))
	return ResourceLoader.load_threaded_get_status(path)


## Segmentin sahnesini kurar: yol (.tscn; arka planda istenmişse oradan), PackedScene ya da Script.
func _instantiate_scene(scene: Variant) -> Node:
	if scene == null or (scene is String and (scene as String).is_empty()):
		return null
	var res: Variant = scene
	if scene is String:
		var path: String = scene
		if _loaded.has(path):
			res = _loaded[path]
			_loaded.erase(path)
		elif _pending.has(path):
			# Henüz yüklenmediyse bekler (sahne dosyaları küçüktür; dünyalar preload_world ile önceden gelir).
			res = ResourceLoader.load_threaded_get(path)
			_pending.erase(path)
		elif ResourceLoader.exists(path):
			res = ResourceLoader.load(path)
		else:
			res = null
	if res is PackedScene:
		return (res as PackedScene).instantiate()
	if res is Script:
		var made: Variant = (res as Script).new()
		if made is Node:
			return made
	push_warning("[cine] sahne kurulamadı: %s" % [scene])
	return null


# --- Görünüm ---------------------------------------------------------------------------------------

## Overlay segmentinin katmanı: CanvasLayer (0) > SubViewportContainer "View" > SubViewport "Viewport".
func _make_overlay(seg_id: String) -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.name = "View_%s" % seg_id.validate_node_name()
	layer.layer = VIEW_LAYER
	var box := SubViewportContainer.new()
	box.name = "View"
	box.stretch = true
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(box)
	var viewport := SubViewport.new()
	viewport.name = "Viewport"
	viewport.own_world_3d = true
	viewport.handle_input_locally = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	box.add_child(viewport)
	layer.add_child(box)
	add_child(layer)
	return layer


## Opak overlay ana 3B'yi örterken (önceden çizilen dünya yoksa ya da video kipinde önceden çizim bittiyse) ana 3B çizilmez; örtü
## kalkınca eski hâli.
func _update_main_3d() -> void:
	if not is_inside_tree():
		return
	var covered := false
	var video := false
	for entry: Dictionary in _scenes.values():
		if bool(entry.get("opaque", false)):
			covered = true
			video = video or bool(entry.get("video", false))
	var drawn := _worlds.is_empty() or (video and _predraw_left <= 0)
	var off := disable_3d_under_overlay and ((covered and drawn) or _video_cover)
	var viewport := get_viewport()
	if off:
		if _3d_saved < 0:
			_3d_saved = 1 if viewport.disable_3d else 0
		viewport.disable_3d = true
	else:
		_restore_main_3d()


## Dünyanın önceden çizilmesinin sayacı: dünyalar hazır olunca (kare bütçeli kurulum bitince) sayılır, bitince 3B yeniden değerlendirilir.
func _tick_predraw() -> void:
	if _predraw_left <= 0:
		return
	for node: Node in _worlds.values():
		if is_instance_valid(node) and node.has_method(&"is_ready") and not bool(node.call(&"is_ready")):
			return
	_predraw_left -= 1
	if _predraw_left == 0:
		_update_main_3d()


func _restore_main_3d() -> void:
	if _3d_saved >= 0 and is_inside_tree():
		get_viewport().disable_3d = _3d_saved == 1
	_3d_saved = -1


func _fade_rect() -> ColorRect:
	if is_instance_valid(fade_rect):
		return fade_rect
	if _own_fade == null:
		var layer := CanvasLayer.new()
		layer.name = "CineFade"
		layer.layer = FADE_LAYER
		add_child(layer)
		_own_fade = ColorRect.new()
		_own_fade.name = "Fade"
		UIKit.full_rect(_own_fade)
		_own_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_own_fade.color = Color(0, 0, 0, 0)
		layer.add_child(_own_fade)
	return _own_fade


func _kill_fade() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null


func _hide_card() -> void:
	if _card_tween and _card_tween.is_valid():
		_card_tween.kill()
	if _card_box:
		_card_box.visible = false
		_card.text = ""


func _rate() -> float:
	return maxf(speed, 0.001)


func _build_ui() -> void:
	subtitles = SubtitleBar.new()
	subtitles.name = "Subtitles"
	add_child(subtitles)
	_ui = CanvasLayer.new()
	_ui.name = "CineUI"
	_ui.layer = UI_LAYER
	add_child(_ui)
	# Kart: ekranın alt üçte birinde, ortada.
	_card_box = Control.new()
	_card_box.name = "Card"
	_card_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card_box.anchor_left = 0.5
	_card_box.anchor_right = 0.5
	_card_box.anchor_top = 2.0 / 3.0
	_card_box.anchor_bottom = 2.0 / 3.0
	_card_box.offset_left = -640.0
	_card_box.offset_right = 640.0
	_card_box.offset_top = -40.0
	_card_box.offset_bottom = 40.0
	_ui.add_child(_card_box)
	_card = UIKit.label("", CARD_FONT_SIZE, "Cinzel", 600, UIKit.PARCHMENT, 3)
	_card.name = "Text"
	UIKit.full_rect(_card)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_card_box.add_child(_card)
	_card_box.visible = false
	# Atlama halkası: sağ alt köşede.
	_ring = _SkipRing.new()
	_ring.name = "SkipRing"
	_ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring.anchor_left = 1.0
	_ring.anchor_right = 1.0
	_ring.anchor_top = 1.0
	_ring.anchor_bottom = 1.0
	_ring.offset_left = -104.0
	_ring.offset_right = -56.0
	_ring.offset_top = -104.0
	_ring.offset_bottom = -56.0
	_ui.add_child(_ring)
	UIKit.on_ui_scale_changed(_card_box, _layout_ui)
	_layout_ui()


func _layout_ui() -> void:
	var k := UIKit.film_k()
	UIKit.scale_at_anchor(_card_box, k)
	UIKit.scale_at_anchor(_ring, k)


## Sağ alttaki atlama halkası: basılı tutmanın doluluğu.
class _SkipRing:
	extends Control

	var progress := 0.0:
		set(value):
			progress = clampf(value, 0.0, 1.0)
			visible = progress > 0.0
			queue_redraw()

	func _ready() -> void:
		visible = false

	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.5 - 3.0
		draw_arc(center, radius, 0.0, TAU, 48, Color(UIKit.PARCHMENT, 0.25), 3.0, true)
		if progress > 0.0:
			draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 48, UIKit.GOLD, 4.0, true)
