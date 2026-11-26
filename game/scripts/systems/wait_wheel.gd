class_name WaitWheel
extends Node
## Bekle, Uyu, Dinlen ve Çalış tekeri (K20, K45; time.md §6.2, §7.1–§7.4, §11; survival.md §2.7, §7.4; Yol Haritası wait-sleep). Main'in
## çocuğudur; oturum (Session) kuruluyken açılır. Satırları WaitPlan kurar, yüzü HudWaitWheel'dir (HUD'un dili; kendi CanvasLayer'ında,
## perdenin üstünde: uzun atlamada kavis kara perdenin üstünde döner).
##   T            Bekle tekeri; döşekte Uyu, şantiyede Çalış, ateş başında Dinlen kipinde açılır (WorldSpots).
##   E (döşek)    «Uyu»: teker uyku kipinde (yalnız döşekte; time.md §7.1).
##   E basılı 3 sn (ateş başı)   «Dinlen»: teker ateş başı kipinde (survival.md §2.7); kısa basış ateşindir.
## Teker açıkken saat durur («modal»; time.md §6.2) ve oyuncu durur. Seçilen satır adı konmuş bir atlamadır, saati ve takvimi yalnız ileri
## yürütür: ≤3 sa bekleme, dinlenme ve çalışma görünür akıştır (GameClock.begin_lapse, 1,8 sn: ekran %60 kararır, gök hızlı akar, sonda
## 0,25 sn kara dalış, 0,5 sn açılış), uzun bekleme ve uyku karartma altında tek atlamadır (GameClock.skip: 0,6 sn karartma, kavis 1,6 sn'de
## döner, 0,8 sn açılış, uyanışta «Gün III, tan» ya da «12 Nisan MÖ 209, tan»). Atlamanın sonu Session.skipped'tir: hava, envanterin
## bozulması, Tan kartı ve oto kayıt (uyku; ≥1 sa bekleme ve çalışma; dinlenme) oradan işler. 24 saatten uzun atlama tek skipped'tir
## (GameClock; teker en çok 15 sa atlattığı için onu kurmaz).
## Bedene etkisi: her atlamada Stamina dolar (dinlenmede hemen), uykuda Can dolar. Tokluk ve Yara Needs'indir (scripts/sim/survival/; başka
## iş): Session.skipped'in nedeni (wait, work: ×1; rest: ×0,5; sleep: ×0,25) ve süresiyle işler; teker Tokluk'u «needs» hizmetinden ya
## da HUD'un Vitals'ından okur (fullness), Tokluk <25'te Çalış kapalıdır. Yasaklar: binilen at yürürken «Atı durdur.»; öteki yasaklar
## (tehlike 30 m, nöbetçi, su, Ay Saati, baskın, Kara Boran, boss, vakit) deny_sources'tan gelir. Kesinti: interrupt(yazı) görünür akışı o
## dakikada bırakır (vakit bekleyişi GameClock'ta kendisi keser).

signal opened(mode: StringName)
## Teker atlamasız kapandı.
signal closed
## Atlama başladı (satır) ve bitti (Session.skipped'in bilgisi; kesilen akışta da).
signal started(row: Dictionary)
signal finished(info: Dictionary)

const LAYER := 6
## Ateş başında Dinlen için E'nin basılı kalacağı süre (sn; survival.md §2.7).
const REST_HOLD_S := 3.0
## Binekte bekleyişi yasaklayan hız (m/sn): at yürüyorsa «Atı durdur.».
const MOVING_SPEED := 0.3
## Satırları açan ses ve uyanışın sesi (dosya yoksa yedeği; time.md §7.2).
const SFX_LAPSE: Array[StringName] = [&"wait_lapse", &"whoosh"]
const SFX_WAKE: Array[StringName] = [&"wake", &"breath"]
const PAUSE_OWNER := &"wait_wheel"

var session: Session
## Tekerin açılabileceği an (Main: oynanıyor, oturum var, kayıt açık).
var live_check: Callable
## Dünyanın yerleri: () -> WorldSpots.
var spots_source: Callable
## Ek yasaklar: () -> String (boş: yasak yok).
var deny_sources: Array[Callable] = []
## Ek ateş başları: (xz: Vector2) -> bool. Dünyanın yerlerinde (spots.json) olmayan, oyuncunun yaktığı ateşler (SurvivalLayer); T orada
## da Dinlen açar (survival.md §2.7).
var rest_sources: Array[Callable] = []
var hud: GameplayHud
var player: PlayerController
var fade: ColorRect
var toast: MenuToast
var ui: HudWaitWheel
## Hareketi Azalt (time.md §7.2): görünür akış yerine doğrudan karartma.
var reduced_motion := false

var _layer: CanvasLayer
var _mode: StringName = &"wait"
var _rows: Array[Dictionary] = []
var _running := false
var _serial := 0
var _hold := 0.0
var _holding := false
var _last: Dictionary = {}
var _caught: Dictionary = {}
## Teker açıkken gizlenen bildirim (başlığın üstüne binmesin) ve önceki görünürlüğü (-1: dokunulmadı).
var _toast_was := -1


func _init() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE


func setup(_host: Node, p_hud: GameplayHud, p_player: PlayerController, p_fade: ColorRect, p_toast: MenuToast) -> void:
	hud = p_hud
	player = p_player
	fade = p_fade
	toast = p_toast
	_layer = CanvasLayer.new()
	_layer.name = "WaitLayer"
	_layer.layer = LAYER
	add_child(_layer)
	ui = HudWaitWheel.new()
	_layer.add_child(ui)
	ui.chosen.connect(choose)
	ui.cancelled.connect(close)


func _unhandled_input(event: InputEvent) -> void:
	if not InputMap.has_action(&"wait") or not event.is_action_pressed(&"wait") or event.is_echo():
		return
	if can_open():
		open()
		get_viewport().set_input_as_handled()


# --- Açma ve kapama --------------------------------------------------------------------------------------------------

## Teker açılabilir mi: oynanıyor, oturum var, oyuncu etkin, teker kapalı ve akış yok.
func can_open() -> bool:
	if _running or is_open() or session == null or not is_instance_valid(session) or session.clock == null:
		return false
	if live_check.is_valid() and not bool(live_check.call()):
		return false
	return player != null and player.is_active()


func is_open() -> bool:
	return ui != null and ui.is_open()


func is_running() -> bool:
	return _running


## Açık tekerin kipi ve satırları (sınama).
func mode() -> StringName:
	return _mode


func rows() -> Array[Dictionary]:
	return _rows


## Bağlamın kipi: döşekte uyku, şantiyede çalışma, ateş başında dinlenme, yoksa bekleme (binekte hep bekleme).
func context_mode() -> StringName:
	if player == null or player.is_riding():
		return &"wait"
	var xz := _player_xz()
	var spots := _spots()
	if spots != null:
		if not spots.nearest("beds", xz).is_empty():
			return &"sleep"
		if not spots.nearest("sites", xz).is_empty():
			return &"work"
		if not spots.nearest("fires", xz).is_empty():
			return &"rest"
	for c: Callable in rest_sources:
		if c.is_valid() and bool(c.call(xz)):
			return &"rest"
	return &"wait"


## Tekeri açar (kip boşsa bağlamın kipi): saat durur, oyuncu durur. Döner: açıldı mı.
func open(mode: StringName = &"") -> bool:
	if not can_open():
		return false
	_cancel_hold()
	_mode = mode if mode != &"" else context_mode()
	if not WaitPlan.MODES.has(_mode):
		_mode = &"wait"
	var clock := session.clock
	_rows = WaitPlan.rows(_mode, clock, _context())
	session.set_pause(&"modal", true, PAUSE_OWNER)
	var lang := SubtitleBar.ui_lang()
	ui.lang = lang
	ui.open(_rows, _mode, clock, WaitPlan.title(_mode, lang), _sub_text(clock, lang))
	_hide_toast(true)
	MenuStyle.play_ui(ui, &"page_turn", -14.0)
	opened.emit(_mode)
	return true


## Tekeri atlamasız kapatır: saat sürer.
func close() -> void:
	if _running or ui == null or not ui.visible:
		return
	ui.close()
	_hide_toast(false)
	if session and is_instance_valid(session):
		session.set_pause(&"modal", false, PAUSE_OWNER)
	closed.emit()


## Her şeyi bırakır (oturum kapanıyor: menüye dönüş, yükleme): teker anında kapanır, süren akış o dakikada biter, perde açılır.
func cancel() -> void:
	_serial += 1
	_cancel_hold()
	var was := _running or (ui != null and ui.visible)
	_running = false
	if session and is_instance_valid(session):
		if session.clock and session.clock.is_lapsing():
			session.clock.end_lapse()
		session.set_pause(&"modal", false, PAUSE_OWNER)
	if ui:
		ui.close(true)
	_hide_toast(false)
	if was:
		closed.emit()


## Satırı seçer: atlama başlar (kapalı satır seçilmez). Döner: başladı mı.
func choose(index: int) -> bool:
	if _running or index < 0 or index >= _rows.size() or not bool(_rows[index].get("enabled", false)):
		return false
	_run(_rows[index])
	return true


## Görünür akışı o dakikada keser (tehlike, fırtına başı, akın uyarısı, görev olayı; time.md §7.3) ve nedenini yazar.
func interrupt(text: String = "") -> void:
	if not _running or session == null or session.clock == null:
		return
	if session.clock.is_lapsing():
		session.clock.end_lapse()
		if not text.is_empty() and toast:
			toast.show_text(text, "warn")


# --- Etkileşim (PlayerController.interaction_source) -----------------------------------------------------------------

## Oyuncunun E'si: döşekte «Uyu», ateş başında «Dinlen» (basılı tutulur). Yoksa boş.
func interaction() -> Dictionary:
	if _running or is_open() or session == null or not is_instance_valid(session) or player == null or player.is_riding():
		return {}
	if live_check.is_valid() and not bool(live_check.call()):
		return {}
	var spots := _spots()
	if spots == null:
		return {}
	var xz := _player_xz()
	var lang := SubtitleBar.ui_lang()
	if not spots.nearest("beds", xz).is_empty():
		return {"key": "E", "label": WaitPlan.title(&"sleep", lang), "run": func() -> void: open(&"sleep")}
	if not spots.nearest("sites", xz).is_empty():
		return {"key": "E", "label": WaitPlan.title(&"work", lang), "run": func() -> void: open(&"work")}
	var fire := spots.nearest("fires", xz)
	if not fire.is_empty() and fire.get("e", true) != false:
		var label := ("Basılı: %s" if lang != "en" else "Hold: %s") % WaitPlan.title(&"rest", lang)
		return {"key": "E", "label": label, "run": _begin_rest_hold}
	return {}


func _begin_rest_hold() -> void:
	_holding = true
	_hold = 0.0


func _cancel_hold() -> void:
	if _holding and hud:
		hud.show_hold("", 0.0)
	_holding = false
	_hold = 0.0


func _process(delta: float) -> void:
	if not _holding:
		return
	if not Input.is_action_pressed(&"accept") or _running or is_open():
		_cancel_hold()
		return
	_hold += delta
	if hud:
		hud.show_hold(WaitPlan.title(&"rest", SubtitleBar.ui_lang()), _hold / REST_HOLD_S)
	if _hold >= REST_HOLD_S:
		_cancel_hold()
		open(&"rest")


# --- Atlama ----------------------------------------------------------------------------------------------------------

func _run(row: Dictionary) -> void:
	_serial += 1
	var serial := _serial
	_running = true
	var clock := session.clock
	var from := clock.abs_minute()
	var target := float(row["target"])
	var reason := StringName(str(row.get("reason", "wait")))
	var sleep := bool(row.get("sleep", false))
	ui.run_begin(row, from)
	started.emit(row)
	_play_sfx(SFX_LAPSE)
	if reason == &"rest":
		_refill(false)
	_caught = {}
	var catch := func(info: Dictionary) -> void: _caught = info
	session.skipped.connect(catch)
	var info: Dictionary = {}
	if WaitPlan.is_lapse(row) and not reduced_motion:
		# Görünür akış: saat kendi akışıyla 1,8 sn'de hedefe varır (modal kalkar; öteki durma nedenleri akışı da durdurur).
		session.set_pause(&"modal", false, PAUSE_OWNER)
		clock.begin_lapse(target, WaitPlan.LAPSE_SECONDS, reason)
		while is_instance_valid(clock) and clock.is_lapsing() and serial == _serial:
			await get_tree().process_frame
		if serial != _serial:
			_disconnect(catch)
			return
		session.set_pause(&"modal", true, PAUSE_OWNER)
		await _fade_to(1.0, WaitPlan.LAPSE_DIP)
		if serial != _serial:
			_disconnect(catch)
			return
		info = _caught
		_after(row, info)
		ui.run_end(0.05)
		await _fade_to(0.0, WaitPlan.LAPSE_OPEN)
	else:
		# Uzun bekleme ve uyku: karartma, kavis kara perdenin üstünde döner, sonra tek atlama.
		await _fade_to(1.0, WaitPlan.FADE_OUT)
		if serial != _serial:
			_disconnect(catch)
			return
		ui.turn_arc(WaitPlan.ARC_TURN)
		await get_tree().create_timer(WaitPlan.ARC_TURN).timeout
		if serial != _serial:
			_disconnect(catch)
			return
		info = clock.skip(target - clock.abs_minute(), reason, sleep)
		if info.is_empty():
			info = _caught
		_after(row, info)
		ui.run_end(0.3)
		await _fade_to(0.0, WaitPlan.FADE_IN)
		if serial != _serial:
			_disconnect(catch)
			return
		_hide_toast(false)
		_play_sfx(SFX_WAKE)
		# Serbest Gez'de atlama bir Tan'ı geçtiyse tarihi RoamTime'ın Tan kartı yazar (time.md §11): bildirim tekrarlanmaz.
		var dawn_card := session != null and is_instance_valid(session) and session.mode == Session.MODE_ROAM and int(info.get("dawns", 0)) > 0
		if toast and not dawn_card:
			toast.show_text(_woke_text(clock))
	_disconnect(catch)
	_running = false
	_hide_toast(false)
	if session and is_instance_valid(session):
		session.set_pause(&"modal", false, PAUSE_OWNER)
	_last = info
	finished.emit(info)


## Teker açıkken bildirim (MenuToast, üst orta) gizlenir: başlığın üstüne binmesin; kapanınca eski görünürlüğüne döner.
func _hide_toast(on: bool) -> void:
	if toast == null or not is_instance_valid(toast):
		return
	if on:
		if _toast_was < 0:
			_toast_was = 1 if toast.visible else 0
		toast.visible = false
	elif _toast_was >= 0:
		toast.visible = _toast_was == 1
		_toast_was = -1


## Atlamanın bedene etkisi: Stamina dolar; uykuda Can da dolar (time.md §7.4 «player»). Tokluk ve Yara Needs'indir (skipped).
func _after(row: Dictionary, _info: Dictionary) -> void:
	_refill(bool(row.get("sleep", false)))


func _refill(hp: bool) -> void:
	if hud == null or hud.vitals == null:
		return
	var v := hud.vitals
	v.stamina = v.stamina_max
	if hp:
		v.hp = v.hp_max
	v.changed.emit()


## Son atlamanın bilgisi (sınama).
func last_info() -> Dictionary:
	return _last


func _disconnect(c: Callable) -> void:
	if session and is_instance_valid(session) and session.skipped.is_connected(c):
		session.skipped.disconnect(c)


func _fade_to(alpha: float, seconds: float) -> void:
	if fade == null or not is_inside_tree():
		return
	var tween := create_tween()
	tween.tween_property(fade, ^"color:a", alpha, maxf(seconds, 0.01)).set_trans(Tween.TRANS_SINE)
	await tween.finished


# --- Bağlam ----------------------------------------------------------------------------------------------------------

func _context() -> Dictionary:
	var spots := _spots()
	var site: Dictionary = spots.nearest("sites", _player_xz()) if spots else {}
	return {
		"lang": SubtitleBar.ui_lang(),
		"child": player != null and player.is_child(),
		"fullness": fullness(),
		"site_eta": float(site.get("eta", -1.0)),
		"deny": deny_text(),
	}


## Bağlamın yasağı (yoksa ""): binilen at yürüyorsa «Atı durdur.»; sonra deny_sources.
func deny_text() -> String:
	var lang := SubtitleBar.ui_lang()
	if player and player.is_riding() and player.get_speed() > MOVING_SPEED:
		return WaitPlan.text("deny.moving", lang)
	for src: Callable in deny_sources:
		if src.is_valid():
			var t: Variant = src.call()
			if t is String and not (t as String).is_empty():
				return t
	return ""


## Tokluk (0–100; bilinmiyorsa −1): oturumun «needs» hizmeti, adım 4'teki Survival'ın Needs'i ya da HUD'un Vitals'ı (fullness ya da
## satiety; alan ya da yöntem). Serbest Gez'de Tokluk yoktur (−1: Çalış kapanmaz).
func fullness() -> float:
	var sources: Array = []
	if session and is_instance_valid(session):
		sources.append(session.services().get("needs"))
		# Ateş ve av katmanının Survival'ı (adım 4, kimlik «survival»): Tokluk onun Needs'inde (fullness).
		var surv: Variant = session.get_system(&"survival")
		if surv is Object and is_instance_valid(surv) and &"needs" in (surv as Object):
			sources.append((surv as Object).get(&"needs"))
	if hud:
		sources.append(hud.vitals)
	for src: Variant in sources:
		if not src is Object or not is_instance_valid(src):
			continue
		for name: StringName in [&"fullness", &"satiety"]:
			if (src as Object).has_method(name):
				var v: Variant = (src as Object).call(name)
				if v is float or v is int:
					return float(v)
			elif name in (src as Object):
				var v2: Variant = (src as Object).get(name)
				if v2 is float or v2 is int:
					return float(v2)
	return -1.0


func _spots() -> WorldSpots:
	if not spots_source.is_valid():
		return null
	var s: Variant = spots_source.call()
	return s as WorldSpots if s is WorldSpots else null


func _player_xz() -> Vector2:
	if player == null:
		return Vector2.ZERO
	var p := player.global_position if player.is_inside_tree() else player.position
	return Vector2(p.x, p.z)


## Tekerin tarih satırı: «11 Nisan MÖ 209 · 14:46 · İkindi».
func _sub_text(clock: GameClock, lang: String) -> String:
	var parts := PackedStringArray([GameCalendar.format(clock.day_n, lang), clock.text()])
	var phase := WaitPlan.phase_name(clock.phase(), lang)
	if not phase.is_empty():
		parts.append(phase)
	return "  ·  ".join(parts)


## Uyanışın bildirimi: hikâyede perdenin günü (Gün I = perdenin ilk günü), Serbest Gez'de tarih.
func _woke_text(clock: GameClock) -> String:
	var story := session != null and is_instance_valid(session) and session.mode == Session.MODE_STORY
	var act := session.journey.act if story and session.journey else 0
	var first := int(GameCalendar.ACT_START.get(act, GameCalendar.ACT_START[1]))
	return WaitPlan.woke_text(clock, story and act >= 1, clock.day_n - first + 1, SubtitleBar.ui_lang())


func _play_sfx(ids: Array[StringName]) -> void:
	var am := get_node_or_null(^"/root/AudioManager")
	if am == null or not am.has_method(&"sfx_variants") or MenuStyle.muted:
		return
	for id: StringName in ids:
		if not (am.call(&"sfx_variants", id) as PackedStringArray).is_empty():
			am.call(&"play_sfx", id, {"volume_db": -8.0})
			return
