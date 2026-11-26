class_name SurvivalLayer
extends Node3D
## Deneme haritasının ateş ve av katmanı (Yol Haritası fire-hunting, hunger-wounds; map.json «layers» → data/maps/testmap/survival.json;
## MapLayers kurar). Survival'ın (scripts/sim/survival/) dünyadaki ve HUD'daki yüzü: Mete ateş kurar, besler, pişirir, avını yüzer; Tokluk
## ve yara HUD'dadır; yara sınırı dolunca Umay Eşiği oynar.
##
## Girdi (survival.md §2.3, §2.5, §3, §4.6; K35, K45):
##   Y     ateşin ya da çukurun 3 m içinde 1 yakıt (basılı 0,8 sn sonra 0,5 sn'de bir); küllenmiş közü uyandırır; çukuru ve Eski Ocak'ı yakar
##         (1 odun ya da 2 tezek, kavsız); uzakta yer seçimi: ayak önünde halka (altın geçerli, kızıl geçersiz, neden yazar), yine Y kurar
##         (dizme, taş, yakma: 5–7 sn, Mete diz çöker; yürürse iş bırakılır, malzeme gitmez), Esc vazgeçer
##   E     yanan ateşin yanında tarif çemberi (CookWheel; oyun durmaz); pişerken Tam Vuruş; pişen yemeği hemen ye (yıldız geçer); yerde düşmüş
##         avda basılı 2 sn Yüz (verim verim Heybe'ye)
##   F     basılı: Küçük, Orta, Büyük evrede 1 sn Söndür (Dolu Tulum), Kor'da 2 sn Küle Yatır
## E'nin işi varken kamera E ile dönmez (FollowCamera.hold_turn_right). İpuçları HUD'un şeridindedir: oyuncunun kendi ipuçlarına eklenir.
##
## Oturum: Main'in Session'ı varsa Survival onun adım 4'üne bağlanır (hikâye kipinde «survival» bloğuyla; Serbest Gez kaydına yazmaz);
## yoksa (geliştirme) yerel bir saat yalnız bu ziyaret için yürür. Envanter HUD'un heybesidir (GameplayHud.bag.inventory). HUD'un Tokluk ve
## yara göstergesi HudNeeds'tir (portrenin çocuğu). Geliştirme ve kare: --survival=place|fire|stages|wheel|cook|old|skin|hungry|fall|wake|rest|rest_ring|hearth.

## Yer seçiminin ayak önündeki uzaklığı (m), önizleme halkasının boyu, oturma uzaklığı (ateşin merkezinden), yüzme erimi.
const PLACE_AHEAD := 2.2
const PREVIEW_SIZE := 2.0
const SIT_DIST := 1.3
const SKIN_REACH := 1.4
## Tam Vuruş halkasının boyu (m).
const COOK_RING_SIZE := 2.8
## Kararlı ipucu: yer seçiminde neden yazısının en sık yinelenmesi (sn).
const REASON_EVERY := 2.5
const PROCESS_PRIORITY := 5
## Düşüş'ten uyanınca başucundaki ok-yay: beşiğin yayının modeli, en uzun kenarı (m; Önsöz'deki beşik yayı 0,46 m) ve Umay'ın altın
## titreşimi (lekenin boyu m, en parlak örtüsü, nabız sayısı).
## E ateş başında: bu süreden kısa bırakılan dokunuş tarif çemberini açar; WaitWheel.REST_HOLD_S (3 sn) basılı tutuş Bekle tekerini Dinlen
## kipinde açar (survival.md §2.2: «E değişmez: dokunuş tarif çemberini, 3 sn basılı tutuş Dinlen'i açar»). Arası bırakılırsa bir şey olmaz.
const E_TAP_S := 0.4
const BEDSIDE_BOW_MODEL := "cradle_bow"
const BEDSIDE_BOW_LENGTH := 0.5
const UMAY_GLOW_SIZE := 1.9
const UMAY_GLOW_ALPHA := 0.6
const UMAY_GLOW_PULSES := 4

var world: Node3D
var def: Dictionary = {}
var survival: Survival
var zone := "testmap"

var main: Node
var player: PlayerController
var hud: GameplayHud
var camera: FollowCamera
var session: Session

var _attached := false
## Ateş başında E'nin tutuşu: {t: sn, fire: FireState} (boş: tutuş yok).
var _e_hold: Dictionary = {}
var _kit_given := false
var _local_clock: GameClock
var _views: Dictionary = {}
var _old_views: Dictionary = {}
var _old_display: Dictionary = {}
var _snare_field: SmallGameField
var _needs_hud: HudNeeds
var _wheel_layer: CanvasLayer
var _wheel: CookWheel
var _wheel_fire: FireState
var _umay: UmayThreshold
var _bedside: Node3D
var _base_pairs: Array = []
var _sent_pairs: Array = []
var _emitting := false
var _base_run := -1.0
var _placing := false
var _place_xz := Vector2.INF
var _place_plan: Dictionary = {}
var _preview: MeshInstance3D
var _reason_left := 0.0
var _last_reason := ""
var _work: Dictionary = {}
var _work_ring: MeshInstance3D
var _y_held := false
var _y_left := 0.0
var _cook_ring: MeshInstance3D
var _cook_flash := 0.0
var _falling := false
var _hp_queue: Array = []
var _dev: Dictionary = {}
var _dev_done := false
## Kare aracı (DevCapture, --capture): geliştirme sırası bitene dek görüntüyü bekletir.
var _cap: Node


const CaptureTool := preload("res://scripts/dev/capture.gd")


## MapLayers çağırır (ağaca eklemeden önce): harita ve katmanın sözlüğü.
func setup(p_world: Node3D, p_def: Dictionary) -> void:
	world = p_world
	def = p_def
	zone = str(def.get("zone", "testmap"))


func _ready() -> void:
	process_priority = PROCESS_PRIORITY
	_build_old_hearths()
	_build_snares()
	var args: Dictionary = CaptureTool.parse_args(OS.get_cmdline_user_args())
	if args.has("survival"):
		_dev = {"steps": str(args["survival"]).split(",", false)}
		var cap := get_node_or_null(^"/root/DevCapture")
		if cap and cap.has_method(&"hold_capture"):
			cap.call(&"hold_capture")
			_cap = cap


func _exit_tree() -> void:
	_release_capture()
	_detach()


func _release_capture() -> void:
	if _cap and is_instance_valid(_cap):
		_cap.call(&"release_capture")
	_cap = null


# --- Bağlanma ---------------------------------------------------------------------------------------------

## Ana sahne (Main): dünyanın atası (WorldHost'un sahibi), yoksa oyunun sahnesi. Sınamada ana sahne sınamanın çocuğudur.
func _find_main() -> Node:
	var n: Node = get_parent()
	while n:
		if "player" in n and "gameplay_hud" in n:
			return n
		n = n.get_parent()
	var tree := get_tree()
	var scene := tree.current_scene if tree else null
	if scene and "player" in scene and "gameplay_hud" in scene:
		return scene
	return null


## Bu harita oynanıyor mu (oyuncu yetişkin, HUD açık, dünya şimdiki dünya)?
func _live() -> bool:
	if main == null or not is_instance_valid(main):
		main = _find_main()
	if main == null:
		return false
	var p: Variant = main.get("player")
	var h: Variant = main.get("gameplay_hud")
	if not p is PlayerController or not h is GameplayHud or (p as PlayerController).is_child():
		return false
	var host: Variant = main.get("world_host")
	if host is WorldHost and (host as WorldHost).map_world != world:
		return false
	return (h as GameplayHud).is_shown()


func _attach() -> void:
	player = main.get("player")
	hud = main.get("gameplay_hud")
	camera = main.get("follow_camera") as FollowCamera
	var s: Variant = main.get("session")
	session = s if s is Session and is_instance_valid(s) else null
	var diff := "normal"
	var prof: Variant = main.get("profile")
	if prof is CharacterProfile:
		diff = (prof as CharacterProfile).difficulty_id()
	survival = Survival.new({"difficulty": diff, "zone": zone, "mode": "story"})
	survival.lang = SubtitleBar.ui_lang()
	var bag_hud := hud
	survival.inventory_source = func() -> Inventory: return bag_hud.bag.inventory if is_instance_valid(bag_hud) else null
	if session:
		survival.bind_session(session, {"save": session.mode == Session.MODE_STORY})
	else:
		# Oturum yoksa (geliştirme) saat yalnız bu ziyaret için: kayda girmez (K67'nin tek takvimi oturumundur).
		_local_clock = GameClock.new(GameClock.ROAM_DAY, Daylight.MENU_MINUTE)
		_local_clock.set_place(44.0)
		survival.set_clock(_local_clock)
	_add_hearths()
	survival.message.connect(_on_message)
	survival.fire_added.connect(_on_fire_added)
	survival.fire_removed.connect(_on_fire_removed)
	survival.fire_changed.connect(_on_fire_changed)
	survival.cook_finished.connect(_on_cook_finished)
	survival.cook_cancelled.connect(_on_cook_cancelled)
	survival.fell.connect(_on_fell)
	survival.stamina_gained.connect(_on_stamina_gained)
	survival.hp_gained.connect(_on_hp_gained)
	for f in survival.fires.fires:
		_on_fire_added(f)
	_give_kit()
	_needs_hud = HudNeeds.new()
	_needs_hud.survival = survival
	hud.portrait.add_child(_needs_hud)
	if not player.prompt_changed.is_connected(_on_player_prompt):
		player.prompt_changed.connect(_on_player_prompt)
	_base_pairs = player.prompt_pairs() if player.is_active() else []
	_base_run = player.run_speed
	if _snare_field:
		_snare_field.set_threat(player)
	var ww := _wait_wheel()
	if ww and not ww.rest_sources.has(_rest_here):
		ww.rest_sources.append(_rest_here)
	_attached = true


func _detach() -> void:
	if not _attached:
		return
	_attached = false
	var ww := _wait_wheel()
	if ww:
		ww.rest_sources.erase(_rest_here)
	if not _e_hold.is_empty():
		_e_hold = {}
		_show_hold(0.0)
	_close_wheel()
	_cancel_place()
	_end_work(false)
	if survival:
		if survival.job:
			survival.cancel_cook()
		survival.unbind_session()
	if is_instance_valid(_needs_hud):
		_needs_hud.queue_free()
	_needs_hud = null
	if is_instance_valid(player):
		if player.prompt_changed.is_connected(_on_player_prompt):
			player.prompt_changed.disconnect(_on_player_prompt)
		if _base_run > 0.0:
			player.run_speed = _base_run
		player.prompt_changed.emit(_base_pairs)
	if is_instance_valid(hud):
		hud.vitals.regen_k = 1.0
		hud.vitals.drain_k = 1.0
		hud.vitals.stamina_max = Vitals.STAMINA_MAX
	if is_instance_valid(_umay):
		_umay.queue_free()


## Deneme takımı yalnız yeni yolculukta verilir (oturumun envanteri kayıttan gelmediyse: Session.fresh("inventory"); kayıttan dönen
## heybeye ikinci kez eklenmez). Heybe'ye hafif kısmı (≈10 Yük: Bilek 3'te bile yarının altında, koşu ve zıplama açık), yedek yakıt ve
## erzak Doru'nun terkisine (saddlebags: {mount, items}; at haritada yoksa yedek verilmez).
func _give_kit() -> void:
	if _kit_given:
		return
	_kit_given = true
	if session and not session.fresh("inventory"):
		return
	var inv := survival.inv()
	if inv == null:
		return
	var kit: Dictionary = def.get("kit", {})
	for id: String in kit:
		if ItemCatalog.has(id):
			inv.add(id, int(kit[id]), "kit", true)
	var eq: Dictionary = def.get("equip", {})
	for slot: String in eq:
		inv.add(str(eq[slot]), 1, "kit", true)
		inv.equip(slot, str(eq[slot]))
	var sb: Dictionary = def.get("saddlebags", {})
	var bag := _saddlebags_of(str(sb.get("mount", "")))
	if bag:
		var items: Dictionary = sb.get("items", {})
		for id: String in items:
			if ItemCatalog.has(id):
				bag.add(id, int(items[id]), inv.day)


## Haritadaki bir atın terkisi (MapWorld.horse kimliğiyle; anahtar Rideable.mount_key: «horse@Doru»). Yoksa null.
func _saddlebags_of(horse_id: String) -> ItemContainer:
	var inv := survival.inv() if survival else null
	if inv == null or horse_id.is_empty() or world == null or not world.has_method(&"horse"):
		return null
	var ride: Variant = world.call(&"horse", horse_id)
	if not ride is Rideable or not is_instance_valid(ride):
		return null
	return inv.saddlebags((ride as Rideable).mount_key())


## Yerleşimin ocakları: haritanın ocak kayıtları (MapSpec «campfire») Survival'da yanan, yakıtı durmuş ateştir (FireState.hearth): başında
## pişirilir ve dinlenilir; beslenmez, söndürülmez, kayda girmez.
func _add_hearths() -> void:
	var spec: Variant = world.get("spec") if world else null
	if not spec is MapSpec:
		return
	for rec: Dictionary in (spec as MapSpec).structures:
		if str(rec.get("kind", "")) == "campfire":
			survival.fires.add_hearth(rec["at"], zone, "hearth_%s" % str(rec.get("id", "campfire")))


# --- Kare ----------------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if not _attached:
		if _live():
			_attach()
			if not _dev.is_empty() and not _dev_done:
				_dev_done = true
				_run_dev.call_deferred()
		return
	if not is_instance_valid(player) or not is_instance_valid(hud):
		_detach()
		return
	var host: Variant = main.get("world_host") if is_instance_valid(main) else null
	if host is WorldHost and (host as WorldHost).map_world != world:
		_detach()
		return
	var p := player.global_position
	survival.player_xz = Vector2(p.x, p.z)
	if _local_clock and not get_tree().paused:
		_local_clock.step(delta)
		survival.step(delta)
	_update_vitals(delta)
	_update_views()
	_update_work(delta)
	_update_feed_hold(delta)
	_update_e_hold(delta)
	_update_cooking(delta)
	_update_placement(delta)
	_push_prompt()
	if camera and _e_has_job():
		camera.hold_turn_right = true


func _update_vitals(delta: float) -> void:
	var v := hud.vitals
	var eff := survival.needs.effects()
	var buff := survival.buff_block()
	v.regen_k = float(eff.get("staRegen", 1.0)) * float(buff.get("staRegen", 1.0))
	v.drain_k = float(eff.get("runCost", 1.0))
	var wfx := survival.wounds.effects()
	v.stamina_max = maxf(Vitals.STAMINA_MAX + float(wfx["sta"]) + float(buff.get("sta", 0.0)), 16.0)
	if v.stamina > v.stamina_max:
		v.stamina = v.stamina_max
	if _base_run > 0.0:
		player.run_speed = _base_run * float(eff.get("run", 1.0)) * float(wfx["run"]) * float(buff.get("runMul", 1.0))
	# Kemik Suyu: Can +30, 60 sn'de.
	for h: Dictionary in _hp_queue:
		var step := float(h["rate"]) * delta
		h["left"] = float(h["left"]) - step
		v.damage(-step)
	_hp_queue = _hp_queue.filter(func(h: Dictionary) -> bool: return float(h["left"]) > 0.0)
	# Can 0: Yara +1, Can %50 (sınır dolarsa Umay Eşiği: fell).
	if v.hp <= 0.0 and not _falling:
		if not survival.on_hp_zero():
			v.hp = v.hp_max * Wounds.hp_after_zero()
			v.changed.emit()
			_on_message(Catalog.pick((Needs.data().get("text", {}) as Dictionary).get("wound", ""), survival.lang), "warn")


func _update_views() -> void:
	var ring_m := float(FireState.rule("ring_m", 6.0))
	for id: String in _views:
		var view: FireView = _views[id]
		if is_instance_valid(view) and view.fire:
			view.show_ring = survival.player_xz.distance_to(view.fire.xz()) <= ring_m


# --- Girdi --------------------------------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not _attached or _falling or not player.is_active():
		return
	if event is InputEventKey and (event as InputEventKey).echo:
		return
	if _wheel and is_instance_valid(_wheel):
		if event.is_action_pressed(&"accept") or event.is_action_pressed(&"pause"):
			_close_wheel()
			_handled()
		return
	if _placing and event.is_action_pressed(&"pause"):
		_cancel_place()
		_handled()
		return
	if event.is_action_pressed(&"fire"):
		_on_y_pressed()
		_handled()
	elif event.is_action_released(&"fire"):
		_y_held = false
	elif event.is_action_pressed(&"sling"):
		if _on_f_pressed():
			_handled()
	elif event.is_action_released(&"sling"):
		if _work.get("kind", "") in ["douse", "bank"] and not bool(_work.get("done", false)):
			_end_work(false)
	elif event.is_action_pressed(&"accept"):
		if _on_e_pressed():
			_handled()
	elif event.is_action_released(&"accept"):
		if not _e_hold.is_empty():
			_on_e_released()
		elif str(_work.get("kind", "")) == "skin" and not bool(_work.get("done", false)):
			_end_work(false)


func _handled() -> void:
	if is_inside_tree():
		get_viewport().set_input_as_handled()


## Y: yakında besler (ya da yakar), uzakta yer seçer; yer seçimindeyse kurar.
func _on_y_pressed() -> void:
	if not _work.is_empty():
		return
	if _placing:
		_try_build()
		return
	var t := _near_target()
	if t.is_empty():
		_begin_place()
		return
	if t.get("fire") is FireState and (t["fire"] as FireState).hearth:
		# Yerleşimin ocağını halk besler: Y yalnız bunu söyler.
		_on_message(FireState.text("hearth", survival.lang), "info")
		return
	_feed_target(t)
	_y_held = true
	_y_left = float((FireState.rule("feed", {}) as Dictionary).get("tap_s", 0.8))


func _feed_target(t: Dictionary) -> void:
	if str(t["kind"]) == "old":
		survival.light_old(str(t["id"]), t["at"])
		return
	survival.feed(t["fire"])


func _update_feed_hold(delta: float) -> void:
	if not _y_held:
		return
	if not Input.is_action_pressed(&"fire"):
		_y_held = false
		return
	_y_left -= delta
	if _y_left > 0.0:
		return
	_y_left = float((FireState.rule("feed", {}) as Dictionary).get("hold_every_s", 0.5))
	var t := _near_target()
	if t.is_empty() or str(t["kind"]) != "lit" or (t["fire"] as FireState).is_full():
		_y_held = false
		return
	_feed_target(t)


## F basılı: Söndür (1 sn) ya da Kor'da Küle Yatır (2 sn). Döner: işi var mı.
func _on_f_pressed() -> bool:
	var t := _near_target()
	if t.is_empty() or str(t["kind"]) != "lit":
		return false
	var f: FireState = t["fire"]
	var job := Survival.f_job(f)
	if job.is_empty():
		return false
	if job == "douse" and survival.inv() and survival.inv().count("waterskin") <= 0:
		_on_message(FireState.text("douse_needs", survival.lang), "warn")
		return true
	_begin_work({"kind": job, "T": 2.0 if job == "bank" else 1.0, "fire": f, "at": Vector3(f.x, _ground(f.xz()), f.z)})
	return true


## E: Tam Vuruş, hemen ye, yüz, tarif çemberi. Döner: işi var mı.
func _on_e_pressed() -> bool:
	if survival.job != null:
		survival.cook_press()
		return true
	var t := _near_target()
	var lit := not t.is_empty() and str(t["kind"]) == "lit"
	if not survival.fresh.is_empty() and lit:
		survival.eat_fresh()
		return true
	var carcass := _carcass_in_reach()
	if carcass:
		var skin_t := float(survival.mod_of("skinT", 1.0))
		_begin_work({"kind": "skin", "T": Hunt.skin_seconds(skin_t), "target": carcass, "at": carcass.global_position})
		return true
	if lit and (player.is_seated() or not player.has_interaction()):
		# Dokunuş tarif çemberi, 3 sn basılı tutuş Dinlen: hüküm bırakışta (_on_e_released) ya da süre dolunca (_update_e_hold).
		_e_hold = {"t": 0.0, "fire": t["fire"]}
		return true
	return false


## E bırakıldı: kısa dokunuşsa tarif çemberi açılır; Dinlen'e giden tutuş yarıda bırakıldıysa bir şey olmaz.
func _on_e_released() -> void:
	if _e_hold.is_empty():
		return
	var hold := _e_hold
	_e_hold = {}
	_show_hold(0.0)
	var f: FireState = hold.get("fire")
	if float(hold.get("t", 0.0)) < E_TAP_S and f and f.is_lit() and survival.fires.fires.has(f):
		_open_wheel(f)


## Tutuş sürer: E_TAP_S'den sonra HUD'un halkası dolar, 3 sn'de Bekle tekeri Dinlen kipinde açılır. E bırakılmışsa (odak kaybı) bırakış sayılır.
func _update_e_hold(delta: float) -> void:
	if _e_hold.is_empty():
		return
	if not Input.is_action_pressed(&"accept"):
		_on_e_released()
		return
	if _near_target().get("fire") != _e_hold.get("fire"):
		# Ateşin başından ayrıldı: tutuş biter.
		_e_hold = {}
		_show_hold(0.0)
		return
	var t := float(_e_hold.get("t", 0.0)) + delta
	_e_hold["t"] = t
	if t >= E_TAP_S:
		_show_hold(t / WaitWheel.REST_HOLD_S)
	if t >= WaitWheel.REST_HOLD_S:
		_e_hold = {}
		_show_hold(0.0)
		_open_rest()


## Bekle tekeri ateş başı kipinde (Main'in WaitWheel'i; survival.md §2.7 Dinlen). Döner: açıldı mı.
func _open_rest() -> bool:
	var ww := _wait_wheel()
	return ww.open(&"rest") if ww else false


## Main'in Bekle tekeri (yoksa null).
func _wait_wheel() -> WaitWheel:
	var ww: Variant = main.get("wait_wheel") if is_instance_valid(main) else null
	return ww as WaitWheel if ww is WaitWheel and is_instance_valid(ww) else null


## Bekle tekerinin ateş başı kaynağı: noktanın 3 m içinde yanan bir ateş var mı (T orada Dinlen açar)?
func _rest_here(xz: Vector2) -> bool:
	if survival == null or not xz.is_finite():
		return false
	var f := survival.fire_near(xz)
	return f != null and f.is_lit()


## Bekle tekeri var mı (Dinlen ipucu)?
func _can_rest() -> bool:
	var ww: Variant = main.get("wait_wheel") if is_instance_valid(main) else null
	return ww is WaitWheel and is_instance_valid(ww) and (ww as WaitWheel).can_open()


## HUD'un tutuş halkası (WaitWheel ile aynı yüz: «Dinlen»); 0 siler.
func _show_hold(p: float) -> void:
	if not is_instance_valid(hud):
		return
	if p <= 0.0:
		hud.show_hold("", 0.0)
	else:
		hud.show_hold(WaitPlan.title(&"rest", survival.lang if survival else "tr"), p)


## E'nin bu karede işi var mı (kamera E ile dönmesin)?
func _e_has_job() -> bool:
	if survival.job != null or (_wheel and is_instance_valid(_wheel)) or not _work.is_empty():
		return true
	var t := _near_target()
	if not t.is_empty() and str(t["kind"]) == "lit":
		return true
	return _carcass_in_reach() != null


# --- Hedefler -------------------------------------------------------------------------------------------------

## 3 m içindeki ateş ya da çukur: {kind: lit | banked | pit | old, fire, id, at}; yoksa boş.
func _near_target() -> Dictionary:
	if survival == null or not survival.player_xz.is_finite():
		return {}
	var near_m := float(FireState.rule("near_m", 3.0))
	var f := survival.fire_near(survival.player_xz, near_m)
	if f:
		return {"kind": String(f.state), "fire": f}
	for h: Dictionary in def.get("old_hearths", []):
		var at := MapSpec.vec2(h.get("at", [0.0, 0.0]))
		if survival.fires.by_id(str(h["id"])) == null and survival.player_xz.distance_to(at) <= near_m:
			return {"kind": "old", "id": str(h["id"]), "at": at}
	return {}


func _carcass_in_reach() -> Node3D:
	if player == null or not player.is_inside_tree():
		return null
	var at := Vector2(player.global_position.x, player.global_position.z)
	var best: Node3D = null
	var best_d := SKIN_REACH
	for node in get_tree().get_nodes_in_group(PlayerController.FALLEN_GROUP):
		if not SurvivalLayer.is_carcass(node):
			continue
		var d := at.distance_to(Vector2((node as Node3D).global_position.x, (node as Node3D).global_position.z))
		if d <= best_d:
			best = node
			best_d = d
	return best


## Yüzülecek leş mi: «fallen_game» grubunda başkaları da durur (yer yığını GroundPile: E «Aç»; hedef kuklası), leş yalnız düşmüş av
## hayvanıdır (SmallGame, türü bilinen). Grup değil, tür sınanır.
static func is_carcass(node: Variant) -> bool:
	if not node is SmallGame or not is_instance_valid(node):
		return false
	var game := node as SmallGame
	return game.is_inside_tree() and game.kind != null and not game.kind_id.is_empty() and game.is_down()


# --- Yer seçimi ve kurma ---------------------------------------------------------------------------------------

func _begin_place() -> void:
	_placing = true
	_last_reason = ""
	_reason_left = 0.0
	if _preview == null or not is_instance_valid(_preview):
		_preview = FireView.make_ring(PREVIEW_SIZE)
		_preview.name = "PlacePreview"
		(_preview.material_override as ShaderMaterial).set_shader_parameter(&"width", 0.09)
		add_child(_preview)
	_update_placement(0.0)


func _cancel_place() -> void:
	_placing = false
	if _preview and is_instance_valid(_preview):
		_preview.queue_free()
	_preview = null


func _update_placement(delta: float) -> void:
	if not _placing:
		return
	if player.is_riding():
		_cancel_place()
		return
	var fwd := player.forward_vector()
	var p := player.global_position + Vector3(fwd.x, 0.0, fwd.z).normalized() * PLACE_AHEAD
	_place_xz = Vector2(p.x, p.z)
	_place_plan = survival.build_plan(_place_xz, _probe())
	var ok := bool(_place_plan.get("ok", false))
	_preview.global_position = Vector3(p.x, _ground(_place_xz) + 0.06, p.z)
	var mat := _preview.material_override as ShaderMaterial
	mat.set_shader_parameter(&"color", Color(1.0, 0.78, 0.36, 0.95) if ok else Color(0.92, 0.2, 0.14, 0.95))
	mat.set_shader_parameter(&"fill", 1.0)
	_reason_left -= delta
	var reason := "" if ok else str(_place_plan.get("text", ""))
	if not reason.is_empty() and (reason != _last_reason or _reason_left <= 0.0):
		_reason_left = REASON_EVERY
		_on_message(reason, "warn")
	_last_reason = reason


func _try_build() -> void:
	_update_placement(0.0)
	if not bool(_place_plan.get("ok", false)):
		_on_message(str(_place_plan.get("text", "")), "warn")
		return
	var at := _place_xz
	var plan := _place_plan.duplicate()
	_cancel_place()
	_sit_facing(at)
	_begin_work({"kind": "build", "T": float(plan.get("seconds", 5.0)), "plan": plan, "xz": at, "at": Vector3(at.x, _ground(at), at.y)})


## Yer seçiminin yoklaması: zeminin eğimi, su, yapılar (yurtlar, eşyalar, kayalar, çamlar), ateşler (haritanın ocağı ve Eski Ocak'lar).
func _probe() -> Dictionary:
	var shape: Variant = world.call(&"get_terrain_shape") if world and world.has_method(&"get_terrain_shape") else null
	var out := {}
	if shape:
		out["normal"] = func(x: float, z: float) -> Vector3: return shape.normal_at(x, z)
		out["water"] = func(x: float, z: float) -> bool: return bool(shape.is_underwater(x, z))
	var structures: Array = []
	var obstacles: Array = []
	var olds: Array = []
	var gaps := {}
	for g: Dictionary in def.get("structures_gap", []):
		gaps[str(g["id"])] = float(g.get("radius", 0.5))
	var spec: Variant = world.get("spec") if world else null
	if spec is MapSpec:
		for rec: Dictionary in (spec as MapSpec).structures:
			var at: Vector2 = rec["at"]
			match str(rec.get("kind", "")):
				"yurt":
					structures.append(Vector3(at.x, at.y, float(rec.get("radius", 3.2))))
				"campfire":
					olds.append(at)
				"prop", "banner":
					# Eşya yapı değildir: yalnız üstüne kurulmaz (eşyanın yarıçapı ve ateşin taş halkası kadar açıklık).
					obstacles.append(Vector3(at.x, at.y, float(gaps.get(str(rec.get("id", "")), 0.5)) + 1.0))
				"rock", "tree":
					obstacles.append(Vector3(at.x, at.y, float(rec.get("size", 2.0)) * (0.15 if str(rec["kind"]) == "tree" else 0.45) + 1.0))
	out["obstacles"] = obstacles
	for h: Dictionary in def.get("old_hearths", []):
		if survival.fires.by_id(str(h["id"])) == null:
			olds.append(MapSpec.vec2(h.get("at", [0.0, 0.0])))
	out["structures"] = structures
	out["olds"] = olds
	var key := hud.bag.transfer_key() if is_instance_valid(hud) and hud.bag else ""
	var i := survival.inv()
	if not key.is_empty() and i:
		var bag := i.saddlebags(key)
		if bag:
			out["saddlebags"] = bag
	return out


# --- İşler (kurma, söndürme, Küle Yatır, yüzme) ---------------------------------------------------------------

func _begin_work(w: Dictionary) -> void:
	_end_work(false)
	_work = w
	_work["t"] = 0.0
	_work["from"] = player.global_position
	_work_ring = FireView.make_ring(1.8 if str(w["kind"]) != "skin" else 1.4)
	_work_ring.name = "WorkRing"
	var mat := _work_ring.material_override as ShaderMaterial
	mat.set_shader_parameter(&"color", Color(1.0, 0.85, 0.5, 0.95))
	mat.set_shader_parameter(&"fill", 0.0)
	mat.set_shader_parameter(&"radius", 0.7)
	add_child(_work_ring)
	var at: Vector3 = w.get("at", player.global_position)
	_work_ring.global_position = at + Vector3(0.0, 0.08, 0.0)


func _update_work(delta: float) -> void:
	if _work.is_empty():
		return
	var kind := str(_work["kind"])
	# Yürüyünce iş bırakılır (kurmada oturuştan kalkınca): malzeme gitmez.
	var moved := player.global_position.distance_to(_work["from"]) > 0.35
	if (kind == "build" and not player.is_seated()) or (kind != "build" and moved):
		_end_work(false)
		return
	_work["t"] = float(_work["t"]) + delta
	var k := clampf(float(_work["t"]) / maxf(float(_work["T"]), 0.01), 0.0, 1.0)
	if _work_ring and is_instance_valid(_work_ring):
		(_work_ring.material_override as ShaderMaterial).set_shader_parameter(&"fill", k)
	if k >= 1.0:
		_end_work(true)


func _end_work(done: bool) -> void:
	if _work.is_empty():
		return
	var w := _work
	_work = {}
	if _work_ring and is_instance_valid(_work_ring):
		_work_ring.queue_free()
	_work_ring = null
	if not done:
		return
	match str(w["kind"]):
		"build":
			survival.build(w["xz"], w["plan"])
		"douse":
			survival.douse(w["fire"])
		"bank":
			survival.bank(w["fire"])
		"skin":
			var target: Node3D = w["target"]
			if is_instance_valid(target) and ArrowField.is_target_down(target):
				var res: Variant = target.call(&"collect")
				var kind := str((res as Dictionary).get("kind", "")) if res is Dictionary else ""
				if not kind.is_empty():
					survival.skin(kind, target.global_position, {"clean": bool(target.get_meta(&"clean", false))})


# --- Pişirme ----------------------------------------------------------------------------------------------------

func _open_wheel(f: FireState) -> void:
	_close_wheel()
	_wheel_fire = f
	_wheel_layer = CanvasLayer.new()
	_wheel_layer.name = "CookWheelLayer"
	_wheel_layer.layer = 40
	add_child(_wheel_layer)
	_wheel = CookWheel.new()
	_wheel.setup(survival, f)
	_wheel.chosen.connect(_on_recipe_chosen)
	_wheel.closed.connect(_close_wheel)
	_wheel_layer.add_child(_wheel)


func _close_wheel() -> void:
	if _wheel_layer and is_instance_valid(_wheel_layer):
		_wheel_layer.queue_free()
	_wheel_layer = null
	_wheel = null


func _on_recipe_chosen(recipe_id: String, share: bool) -> void:
	var f := _wheel_fire
	_close_wheel()
	_start_cook(recipe_id, f, share)


## Pişirmeye başlar: Mete ateşe dönük oturur, ateşin üstünde Tam Vuruş halkası (kazanda ilerleme yayı) açılır.
func _start_cook(recipe_id: String, f: FireState, share: bool) -> void:
	if f == null:
		return
	var r := survival.start_cook(recipe_id, f, share)
	if not bool(r.get("ok", false)):
		return
	if not player.is_seated():
		_sit_facing(f.xz())
	_make_cook_ring(f)
	_set_cooking_look(f, str(Cooking.recipe(recipe_id).get("station", "")))


func _make_cook_ring(f: FireState) -> void:
	_free_cook_ring()
	var timed := survival.job != null and survival.job.timed
	_cook_ring = FireView.make_ring(COOK_RING_SIZE, 1 if timed else 0)
	_cook_ring.name = "CookRing"
	var mat := _cook_ring.material_override as ShaderMaterial
	mat.set_shader_parameter(&"color", Color(1.0, 0.8, 0.4, 1.0))
	if timed:
		# Bant: pencerenin süresince dış halkanın yolunun yarısı (prototipin strike-ring.js'i).
		var j := survival.job
		var half := float(Cooking.data().get("perfect_s", 0.5)) * 0.5
		mat.set_shader_parameter(&"band", clampf(0.12 * half / maxf(j.T, 0.5) * 6.0, 0.02, 0.09))
	add_child(_cook_ring)
	_cook_ring.global_position = Vector3(f.x, _ground(f.xz()) + 0.1, f.z)


func _free_cook_ring() -> void:
	if _cook_ring and is_instance_valid(_cook_ring):
		_cook_ring.queue_free()
	_cook_ring = null
	_cook_flash = 0.0


func _update_cooking(delta: float) -> void:
	if survival.job != null:
		if not player.is_seated():
			survival.cancel_cook()
			return
		if _cook_ring and is_instance_valid(_cook_ring):
			var mat := _cook_ring.material_override as ShaderMaterial
			var j := survival.job
			if j.timed:
				mat.set_shader_parameter(&"k", j.t / maxf(j.T, 0.01))
			else:
				mat.set_shader_parameter(&"fill", j.progress())
	elif _cook_ring and is_instance_valid(_cook_ring):
		_cook_flash -= delta
		(_cook_ring.material_override as ShaderMaterial).set_shader_parameter(&"flash", maxf(_cook_flash / 0.4, 0.0))
		if _cook_flash <= 0.0:
			_free_cook_ring()


## Ateşin üstündeki pişirme (şiş, kazan, kor); "" kaldırır.
func _set_cooking_look(f: FireState, station: String) -> void:
	var view: Variant = _views.get(f.id) if f else null
	if view is FireView and is_instance_valid(view):
		(view as FireView).set_cooking(station)


func _on_cook_finished(j: Cooking.Job) -> void:
	_set_cooking_look(survival.fires.by_id(j.fire_id), "")
	if _cook_ring and is_instance_valid(_cook_ring):
		var mat := _cook_ring.material_override as ShaderMaterial
		mat.set_shader_parameter(&"mode", 1)
		mat.set_shader_parameter(&"k", 1.0)
		mat.set_shader_parameter(&"hit", 1.0 if j.quality >= 3 else 0.0)
		_cook_flash = 0.4


func _on_cook_cancelled(j: Cooking.Job) -> void:
	_free_cook_ring()
	_set_cooking_look(survival.fires.by_id(j.fire_id), "")


## Oyuncuyu ateşe (ya da yere) dönük oturtur: ateşin merkezinden SIT_DIST uzakta, durduğu yanda.
func _sit_facing(target: Vector2) -> void:
	var p := Vector2(player.global_position.x, player.global_position.z)
	var away := (p - target)
	away = away.normalized() if away.length() > 0.05 else Vector2(0.0, 1.0)
	var spot := target + away * SIT_DIST
	var dir := (target - spot).normalized()
	var yaw := atan2(dir.x, dir.y)
	var at := Vector3(spot.x, _ground(spot), spot.y)
	player.sit_at(Transform3D(Basis(Vector3.UP, yaw), at))


# --- Ateşlerin görünüşü ---------------------------------------------------------------------------------------

func _on_fire_added(f: FireState) -> void:
	# Yerleşimin ocağını sahnenin kendi ateşi çizer (Campfire): görünüş ve engel onundur.
	if f.hearth or (_views.has(f.id) and is_instance_valid(_views[f.id])):
		return
	var view := FireView.new()
	view.name = "Fire_%s" % f.id.to_pascal_case()
	view.position = Vector3(f.x, _ground(f.xz()), f.z)
	view.fire = f
	add_child(view)
	view.bind(f)
	view.add_to_group(World.OBSTACLE_GROUP)
	_views[f.id] = view
	if f.old and _old_views.has(f.id):
		(_old_views[f.id] as Node3D).visible = false
		(_old_views[f.id] as Node3D).remove_from_group(World.OBSTACLE_GROUP)
	_refresh_obstacles()


func _on_fire_removed(f: FireState) -> void:
	var view: Variant = _views.get(f.id)
	_views.erase(f.id)
	if view is Node and is_instance_valid(view):
		(view as Node).queue_free()
	if _old_views.has(f.id):
		(_old_views[f.id] as Node3D).visible = true
		(_old_views[f.id] as Node3D).add_to_group(World.OBSTACLE_GROUP)
	_refresh_obstacles.call_deferred()


## Oyuncu ateşin içinden geçmez: engel daireleri yeniden toplanır (ateş eklenince ve kalkınca).
func _refresh_obstacles() -> void:
	if _attached and is_instance_valid(player) and player.is_inside_tree():
		player.refresh_obstacles()


func _on_fire_changed(f: FireState) -> void:
	var view: Variant = _views.get(f.id)
	if view is FireView and is_instance_valid(view):
		(view as FireView).refresh()


## Eski Ocak'lar: 6 taşlık halka ve kalıcı çukur (yanmamışken haritanın görünüşü; yakılınca yerini ateşin görünüşü alır).
func _build_old_hearths() -> void:
	for h: Dictionary in def.get("old_hearths", []):
		var at := MapSpec.vec2(h.get("at", [0.0, 0.0]))
		var shown := FireState.new()
		shown.id = str(h["id"])
		shown.old = true
		shown.stones = true
		shown.state = FireState.PIT
		shown.x = at.x
		shown.z = at.y
		var view := FireView.new()
		view.name = "OldHearth_%s" % shown.id.to_pascal_case()
		view.fire = shown
		view.position = Vector3(at.x, _ground(at), at.y)
		add_child(view)
		view.add_to_group(World.OBSTACLE_GROUP)
		_old_display[shown.id] = shown
		_old_views[shown.id] = view


## Kapanlar: kazık, ilmek ve sabah düşmüş av (SmallGameField'in tek hayvanı, yere çökmüş).
func _build_snares() -> void:
	var groups: Array = []
	for s: Dictionary in def.get("snares", []):
		var at := MapSpec.vec2(s.get("at", [0.0, 0.0]))
		_add_snare_mesh(at, float(s.get("facing", 0.0)))
		groups.append({"kind": str(s.get("kind", "marmot")), "count": 1, "patches": [[at.x, at.y, 0.2]], "holes": []})
	if groups.is_empty() or world == null or world.get("ground") == null:
		return
	_snare_field = SmallGameField.new()
	_snare_field.name = "SnareCatch"
	_snare_field.setup({"seed": 77, "groups": groups}, world.get("ground"))
	add_child(_snare_field)
	_down_snared.call_deferred()


func _down_snared() -> void:
	if _snare_field == null or not is_instance_valid(_snare_field):
		return
	for a: SmallGame in _snare_field.animals():
		if a.is_inside_tree() and a.is_hittable():
			a.hit(a.global_position + Vector3(0.2, 0.0, 0.1))


func _add_snare_mesh(at: Vector2, facing: float) -> void:
	var holder := Node3D.new()
	holder.name = "Snare"
	holder.position = Vector3(at.x, _ground(at), at.y)
	holder.rotation.y = deg_to_rad(facing)
	add_child(holder)
	var wood := Style.toon(Style.WOOD_DARK, {"brush_strength": 0.2})
	var stake := MeshInstance3D.new()
	stake.mesh = Procedural3D.cylinder(0.025, 0.035, 0.42, 8)
	stake.material_override = wood
	stake.position = Vector3(0.0, 0.21, -0.35)
	holder.add_child(stake)
	var loop := MeshInstance3D.new()
	loop.mesh = Procedural3D.torus(0.13, 0.15)
	loop.material_override = Style.toon(Color(0.72, 0.62, 0.44))
	loop.position = Vector3(0.0, 0.04, -0.12)
	holder.add_child(loop)


func _ground(p: Vector2) -> float:
	if world and world.has_method(&"on_ground"):
		return (world.call(&"on_ground", p) as Vector3).y
	return 0.0


# --- İpucu, bildirim -----------------------------------------------------------------------------------------

func _on_message(text: String, kind: String) -> void:
	if text.is_empty() or not is_instance_valid(hud):
		return
	if hud.toast and is_instance_valid(hud.toast):
		hud.toast.show_text(text, "warn" if kind == "warn" else "info")


func _on_player_prompt(pairs: Array) -> void:
	if _emitting:
		return
	_base_pairs = pairs.duplicate()
	_sent_pairs = []
	_push_prompt()


## Katmanın ipuçları (HUD'un şeridine oyuncununkilerden sonra eklenir).
func my_pairs() -> Array:
	if not _attached or _falling or not player.is_active():
		return []
	if _wheel:
		return [["1–9", "Seç"], ["E", "Kapat"]]
	if _placing:
		return [["Y", "Kur"], ["Esc", "Vazgeç"]] if bool(_place_plan.get("ok", false)) else [["Esc", "Vazgeç"]]
	if not _work.is_empty():
		return []
	if survival.job != null:
		return [["E", "Al"]] if survival.job.ring_open() else []
	var out: Array = []
	var t := _near_target()
	if not t.is_empty():
		match str(t["kind"]):
			"lit":
				var f: FireState = t["fire"]
				if not survival.fresh.is_empty():
					out.append(["E", "Ye %s" % Cooking.stars(int(survival.fresh.get("quality", 2)))])
				elif player.is_seated() or not player.has_interaction():
					out.append(["E", "Pişir"])
					if _can_rest():
						out.append(["E basılı", WaitPlan.title(&"rest", survival.lang)])
				if not f.hearth:
					out.append(["Y", "Besle"])
					var fj := Survival.f_job(f)
					out.append(["F basılı", "Küle Yatır" if fj == "bank" else "Söndür"])
			"banked":
				out.append(["Y", "Közü uyandır"])
			"pit", "old":
				out.append(["Y", "Yak"])
		return out
	if _carcass_in_reach():
		return [["E basılı", "Yüz"]]
	if not player.is_riding() and survival.has_build_materials():
		out.append(["Y", "Ateş kur"])
	return out


func _push_prompt() -> void:
	if not _attached or not is_instance_valid(player):
		return
	var merged: Array = []
	var mine := my_pairs()
	var keys := {}
	for p: Array in mine:
		keys[str(p[0])] = true
	for p: Array in _base_pairs:
		# Oyuncunun E'si (Bin, İn, Kalk) bizimkinin önündedir; aynı tuşun ikinci işi şeritte yazılmaz.
		if keys.has(str(p[0])) and str(p[0]) != "E":
			continue
		merged.append(p)
	for p: Array in mine:
		var dup := false
		for q: Array in merged:
			if str(q[0]) == str(p[0]):
				dup = true
		if not dup:
			merged.append(p)
	if merged == _sent_pairs:
		return
	_sent_pairs = merged
	_emitting = true
	player.prompt_changed.emit(merged)
	_emitting = false


# --- Yemeğin anlık etkisi ------------------------------------------------------------------------------------

func _on_stamina_gained(amount: float) -> void:
	hud.vitals.stamina = minf(hud.vitals.stamina + amount, hud.vitals.stamina_max)
	hud.vitals.changed.emit()


func _on_hp_gained(amount: float, seconds: float) -> void:
	if seconds <= 0.0:
		hud.vitals.damage(-amount)
		return
	_hp_queue.append({"left": amount, "rate": amount / seconds})


# --- Umay Eşiği (progression.md §8.5) ---------------------------------------------------------------------------

func _on_fell(plan: Dictionary) -> void:
	if _falling:
		return
	_falling = true
	_play_fall.call_deferred(plan)


func _play_fall(plan: Dictionary) -> void:
	_close_wheel()
	_cancel_place()
	_end_work(false)
	player.set_active(false)
	_umay = UmayThreshold.new()
	_umay.name = "UmayThreshold"
	add_child(_umay)
	await _umay.dark(0.6)
	var result := survival.apply_fall()
	_wake_at_shelter()
	hud.vitals.hp = hud.vitals.hp_max
	hud.vitals.stamina = hud.vitals.stamina_max
	hud.vitals.changed.emit()
	if bool(plan.get("first", false)):
		await _umay.show_card(Catalog.pick(plan.get("card", "Umay."), survival.lang), 2.4)
	await _umay.dawn(1.8)
	if is_instance_valid(_umay):
		_umay.queue_free()
	_umay = null
	player.set_active(true)
	_falling = false
	var fall_text: Dictionary = Needs.data().get("fall", {})
	_on_message(Catalog.pick(fall_text.get("woke", ""), survival.lang), "info")
	for lost: Dictionary in result.get("lost", []):
		_on_message(Catalog.pick(fall_text.get("lost", ""), survival.lang).replace("{item}", ItemCatalog.name_of(str(lost["id"]), survival.lang)), "warn")


## Son barınakta uyanış: oturur, başucunda küçük ok ve yay (beşiğin yayının yankısı; K35).
func _wake_at_shelter() -> void:
	var shelters: Array = def.get("shelters", [])
	var sh: Dictionary = shelters[0] if not shelters.is_empty() else {"at": [0.0, 0.0], "facing": 0.0}
	var at := MapSpec.vec2(sh.get("at", [0.0, 0.0]))
	var yaw := DepartWorld.yaw_of(float(sh.get("facing", 0.0)))
	var pos := Vector3(at.x, _ground(at), at.y)
	player.spawn_at(pos, yaw)
	player.sit_at(Transform3D(Basis(Vector3.UP, yaw), pos))
	if camera:
		camera.snap_to_target()
	if _bedside and is_instance_valid(_bedside):
		_bedside.queue_free()
	_bedside = Node3D.new()
	_bedside.name = "UmayBow"
	add_child(_bedside)
	# Başucunda, oturan Mete'nin batı yanında (gölgesinin karşısı, uzak kadrajın gördüğü yan) yere yatık küçük ok-yay: beşiğin yayı
	# (cradle_bow: beşiğin ağından ayrılan yay ve sadak, varlık kataloğu; dosyası yoksa kodla çizilen oyuncak yay ve ok).
	var spot := Vector2(pos.x - 0.7, pos.z + 0.25)
	_bedside.global_position = Vector3(spot.x, _ground(spot) + 0.02, spot.y)
	if not _add_cradle_bow(_bedside, yaw):
		_bedside.scale = Vector3.ONE * 1.25
		var bow := ToyBowProp.new()
		bow.name = "Bow"
		_bedside.add_child(bow)
		bow.rotation = Vector3(-PI * 0.5, yaw + 0.6, 0.0)
		bow.show_arrow(false)
		var arrow := MeshInstance3D.new()
		arrow.name = "Arrow"
		arrow.mesh = ToyBowProp.arrow_mesh(0.48)
		arrow.material_override = Style.toon(Color(0.78, 0.66, 0.46))
		arrow.rotation = Vector3(-PI * 0.5, yaw - 0.4, 0.0)
		arrow.position = Vector3(0.08, 0.01, 0.1)
		_bedside.add_child(arrow)
	_umay_glow(_bedside)


## Beşiğin yayı (cradle_bow.glb) yere yatık: yay ve sadak, en uzun kenarı BEDSIDE_BOW_LENGTH. Model yoksa false.
func _add_cradle_bow(parent: Node3D, yaw: float) -> bool:
	if not MeshyProp.exists("props", BEDSIDE_BOW_MODEL):
		return false
	var prop := MeshyProp.new()
	prop.name = "Bow"
	prop.model_id = BEDSIDE_BOW_MODEL
	prop.folder = "props"
	prop.size_axis = MeshyProp.SizeAxis.LONGEST
	prop.target_size = BEDSIDE_BOW_LENGTH
	prop.cast_shadows = false
	parent.add_child(prop)
	if not prop.has_model():
		parent.remove_child(prop)
		prop.free()
		return false
	# Asılı parçanın dikey ekseni yere yatar; kalınlığının yarısı kadar kalkar ki toprağa gömülmesin.
	prop.rotation = Vector3(-PI * 0.5, 0.0, 0.0)
	prop.position.y = prop.get_model_aabb().size.z * 0.5
	parent.rotation.y = yaw + 0.6
	return true


## Umay'ın altın titreşimi (act1.md: Umay sözsüz, altın titreşim): ok-yayın altında yere yatık yumuşak bir ışık lekesi; uyanışla
## birkaç kez nabız atar, sonra söner. Işık değil, toplanan renktir (gölge ve ışık bütçesine girmez).
func _umay_glow(parent: Node3D) -> void:
	var quad := MeshInstance3D.new()
	quad.name = "UmayGlow"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2.ONE * UMAY_GLOW_SIZE
	quad.mesh = mesh
	var grad := Gradient.new()
	grad.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	grad.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.albedo_texture = tex
	mat.albedo_color = Color(UmayThreshold.GOLD_LIGHT, 0.0)
	quad.material_override = mat
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	quad.position = Vector3(0.0, 0.01, 0.0)
	parent.add_child(quad)
	var t := quad.create_tween()
	t.tween_property(mat, ^"albedo_color:a", UMAY_GLOW_ALPHA, 0.8)
	for i in UMAY_GLOW_PULSES:
		t.tween_property(mat, ^"albedo_color:a", UMAY_GLOW_ALPHA * 0.45, 0.7).set_trans(Tween.TRANS_SINE)
		t.tween_property(mat, ^"albedo_color:a", UMAY_GLOW_ALPHA, 0.7).set_trans(Tween.TRANS_SINE)
	t.tween_property(mat, ^"albedo_color:a", 0.0, 3.0).set_trans(Tween.TRANS_SINE)
	t.tween_callback(quad.queue_free)


# --- Geliştirme ve kare (--survival=...) --------------------------------------------------------------------------

func _run_dev() -> void:
	await get_tree().create_timer(0.4).timeout
	if not _attached:
		_release_capture()
		return
	for step: String in _dev.get("steps", []):
		await _dev_step(step.strip_edges())
	# Kare: sıra bitince görünüm otursun (ışık, halka, bildirim), sonra görüntü.
	await get_tree().create_timer(1.0).timeout
	_release_capture()


func _dev_step(step: String) -> void:
	var p := player.global_position
	var fwd := player.forward_vector()
	var ahead := Vector2(p.x + fwd.x * 3.0, p.z + fwd.z * 3.0)
	match step:
		"place":
			_begin_place()
		"place_bad":
			# Kare: yurdun dibinde yer seçimi kızarır, nedeni yazar.
			player.spawn_at((world.call(&"on_ground", Vector2(11.0, -6.5)) as Vector3), DepartWorld.yaw_of(45.0))
			await get_tree().create_timer(0.3).timeout
			_begin_place()
		"fire":
			var plan := survival.build_plan(ahead, _probe())
			if bool(plan.get("ok", false)):
				survival.build(ahead, plan)
		"stages":
			# Beş durum yan yana (kare): Büyük, Orta, Küçük, Kor, küllenmiş köz; Eski Ocak çukur kalır.
			var spots := [Vector2(-7.0, 9.0), Vector2(-3.5, 9.0), Vector2(0.0, 9.0), Vector2(3.5, 9.0), Vector2(7.0, 9.0)]
			var fuels := [700.0, 400.0, 150.0, 40.0, 40.0]
			for i in spots.size():
				var f := survival.fires.add(spots[i], zone, i % 2 == 0, fuels[i], survival.now_abs())
				f.advance(0.001, survival.now_abs())
				if i == 4:
					survival.bank(f)
		"wheel", "cook", "old":
			var f2: FireState = null
			if step == "old":
				var h: Dictionary = (def.get("old_hearths", []) as Array)[0]
				var at := MapSpec.vec2(h["at"])
				player.spawn_at(Vector3(at.x, _ground(at), at.y + 2.0), PI)
				f2 = survival.light_old(str(h["id"]), at).get("fire")
			else:
				var plan2 := survival.build_plan(ahead, _probe())
				f2 = survival.build(ahead, plan2) if bool(plan2.get("ok", false)) else survival.fire_near(ahead, 4.0)
			if f2 == null:
				return
			_sit_facing(f2.xz())
			await get_tree().create_timer(0.5).timeout
			if step == "wheel":
				_open_wheel(f2)
				await get_tree().create_timer(0.6).timeout
				if _wheel:
					# Fare Şiş Et'in üstünde: açıklama satırı da görünsün.
					_wheel._hover = (_wheel.slots().map(func(o: Dictionary) -> String: return str(o["id"]))).find("spit_meat")
					_wheel.queue_redraw()
			elif step == "old":
				_start_cook("meal", f2, true)
				await get_tree().create_timer(4.0).timeout
			else:
				_start_cook("spit_meat", f2, false)
				# Tam Vuruş: halka banda yaklaşırken (k ≈ 0,88).
				while survival.job != null and survival.job.t < survival.job.T * 0.88:
					await get_tree().process_frame
		"rest", "rest_ring":
			# Kare: ateş başında E basılı (Dinlen): halka yarıdayken ya da Bekle tekeri Dinlen kipinde açıkken.
			var plan3 := survival.build_plan(ahead, _probe())
			var f3 := survival.build(ahead, plan3) if bool(plan3.get("ok", false)) else survival.fire_near(ahead, 4.0)
			if f3 == null:
				return
			_sit_facing(f3.xz())
			await get_tree().create_timer(0.6).timeout
			Input.action_press(&"accept")
			_on_e_pressed()
			if step == "rest_ring":
				await get_tree().create_timer(0.8).timeout
			else:
				var ww: Variant = main.get("wait_wheel")
				var until := Time.get_ticks_msec() + 5000
				while Time.get_ticks_msec() < until and not (ww is WaitWheel and (ww as WaitWheel).is_open()):
					await get_tree().process_frame
				Input.action_release(&"accept")
		"hearth":
			# Kare: haritanın ocağında (yerleşimin ocağı) tarif çemberi.
			var hf: FireState = null
			for f4 in survival.fires.fires:
				if f4.hearth:
					hf = f4
			if hf == null:
				return
			player.spawn_at(Vector3(hf.x, _ground(Vector2(hf.x, hf.z + 2.2)), hf.z + 2.2), PI)
			await get_tree().create_timer(0.4).timeout
			_open_wheel(hf)
			await get_tree().create_timer(0.6).timeout
		"skin":
			var c := _snare_field.animals()[0] if _snare_field and not _snare_field.animals().is_empty() else null
			if c:
				player.spawn_at(c.global_position + Vector3(0.0, 0.0, 0.9), PI)
				await get_tree().create_timer(0.3).timeout
				_on_e_pressed()
				await get_tree().create_timer(Hunt.skin_seconds() + 0.6).timeout
		"bag":
			hud.open_page("bag")
			await get_tree().create_timer(0.8).timeout
		"hungry":
			survival.needs.fullness = 18.0
			survival.needs.update(0.01)
			survival.wounds.add(2)
		"fall":
			# Kare: ilk Düşüş kartı («Umay.») karanlıkta tam görünürken.
			survival.wounds.add(survival.wounds.limit())
			await get_tree().create_timer(0.6).timeout
		"wake":
			# Kare: uyanış (kartsız ikinci Düşüş), altın ışık söndükten sonra; başucunda küçük ok ve yay.
			survival.wounds.falls = 1
			survival.wounds.add(survival.wounds.limit())
			while _falling:
				await get_tree().process_frame
			await get_tree().create_timer(0.6).timeout
