class_name GatherLayer
extends Node3D
## Bir iç haritanın toplama ve zanaat katmanı (Yol Haritası gathering, crafting; economy.md §3, §6): haritanın map.json'undaki «layers»
## sözlüğünün «gathering» satırı katmanın veri dosyasını gösterir (deneme haritası: data/maps/testmap/gathering.json; MapLayers kurar,
## düğüm «Layers/Gathering»dır): düğüm kümeleri (NodeStore'un spec'i), tezgâhlar (istasyon, yerleşik eller ve ustalar, sandığın ilk içeriği),
## deneme takımı (Mete'ye verilen araçlar). Dünya hazır olunca kurulur (world_ready): kayıt (NodeStore), görünüş (GatherField: tür başına bir
## MultiMesh), Tam Vuruş halkası (StrikeRing), tezgâhlar (Workbench, Workshop ve sandığı).
##
## Oynanış (Mete haritadayken): erimdeki (2,1 m, GATHER_REACH) düğüm ya da tezgâh istemde «E Kes», «E Biç», «E Demirci Ocağı» olarak
## görünür; öncelik bineğindir (PlayerController'ın kendi istemi doluysa katman sözünü kesmez, E'yi almaz). E ile iş başlar: vuruşta
## halka temasa ortalanır, pencerede yeni basış Tam Vuruş'tur; E basılı kaldıkça vuruş sürer; tutuşta E basılı tutulur, bırakınca sıfırlanır.
## Hareket işi keser. Pozlar: vuruşta ToolSwing (iki el sapta, balta ya da kazma), tutuşta kütüphanenin klibi (pull_radish, collect_object,
## bend_over_pick_up_m; PlayerController.work_role). Verim Heybe'ye (Inventory.receive): sığmayan yakındaki atın terkisine, sonra düğümün
## dibinde yer yığınına (GroundPile). Tezgâhta E zanaat sayfasını açar (HudCraftScreen).
##
## Saat: oturum (Session) kuruluysa onun saati ve «sites» adımı (Economy kendi bloğunu yazar: economy), değilse katmanın kendi saati
## (11 Nisan MÖ 209 14:46,2'den; sınamalar). Stamina HUD'un Vitals'ıdır (bedel tavana oranlı, vuruş boyunca dolum yok).

signal built
## Tezgâhın işi bitti (sınama ve arayüz): tezgâh kimliği, biten [{id, n, recipe, fine}].
signal crafted(bench_id: String, done: Array)

const LAYER_ID := "gathering"
const ROLE_SWING := &"work_swing"
const ROLES := {"pull": &"work_pull", "collect": &"work_collect", "lift": &"work_lift"}
## Tezgâhın erimi (kenarından, m) ve yürüyüşü kesen hız (m/sn).
const BENCH_REACH := 1.2
const MOVE_CUT := 0.3
## Halka tutuşta da ilerlemeyi gösterir: bandın yarıçapı.
const HOLD_BAND := 0.035
const LAPSE_S := 3.0
## Bitene Dek Bekle'nin akış zinciri: gece işi yavaşlatır (karanlık sınıfı ×0,4), tahmin şimdiki ışıkla yapılır; akış bitip iş sürüyorsa
## kalan yeniden ölçülür ve akış uzar (en çok bu kadar kez; malzeme ya da usta beklemesinde durur), iş bitince akış hemen kesilir.
const LAPSE_CHAIN := 6
## Katmanın kendi saatinin açılışı (oturum yoksa; K76: 11 Nisan MÖ 209 14:46,2).
const LOCAL_MINUTE := 886.18

var map_world: MapWorld
var data: Dictionary = {}
var store: NodeStore
var field: GatherField
var ring: StrikeRing
var gather: Gather
var economy: Economy
## Oturum (yoksa null) ve tezgâhların saati (oturumunki ya da katmanınki).
var session: Session
var clock: GameClock
## Tezgâh kimliği → {node: Workbench, ws: Workshop, chest: ItemContainer, row}.
var benches: Dictionary = {}
var player: PlayerController
var hud: GameplayHud
var progression: Progression
## Odak: {kind: "node", index} ya da {kind: "bench", id}; boş yok.
var focus: Dictionary = {}
## Mete tezgâhta birlikte çalışıyor (tezgâh kimliği → true).
var helping: Dictionary = {}

var _built := false
var _local_clock := false
var _pairs: Array = []
var _skip_press := false
var _swing: ToolSwing
var _tool: MeshInstance3D
var _tool_meshes: Dictionary = {}
var _clips_model := "x"
var _screen: HudCraftScreen
var _screen_layer: CanvasLayer
var _ring_seen := false
var _lapse_bench := ""
var _lapse_active := ""
var _lapse_chain := 0
var _lapse_to := 0.0
var _watched_clock: GameClock
var _kit_given := false
var _bind_left := 0.0
var _demo := ""
var _demo_running := false
## İnceleme karesinde işin saati durur (halka ve vuruşun evresi o anda kalır).
var _demo_hold := false


## MapLayers'ın kurulumu (ağaca eklenmeden önce): dünya ve katmanın dosyası.
func setup(world: Node3D, def: Dictionary) -> void:
	map_world = world as MapWorld
	data = def


func _ready() -> void:
	process_priority = 5
	if map_world == null:
		# Elle eklenen katman: dünya üstlerden bulunur, dosyası haritanın «layers» satırından okunur.
		var n := get_parent()
		while n and not n is MapWorld:
			n = n.get_parent()
		map_world = n as MapWorld
	if map_world == null:
		return
	if map_world.is_ready():
		_build()
	else:
		map_world.world_ready.connect(_build, CONNECT_ONE_SHOT)


func _exit_tree() -> void:
	_close_screen()
	if economy and map_world and map_world.spec:
		economy.detach_store(map_world.spec.id)
		for id: String in benches:
			economy.detach_workshop((benches[id]["ws"] as Workshop).id)
	if player and is_instance_valid(player):
		player.work_role = &""
	if is_instance_valid(_swing):
		_swing.queue_free()


# --- Kurulum -----------------------------------------------------------------------------------------------------------------

## Haritanın toplama katmanının dosyası (MapSpec.layers «gathering»); yoksa boş.
static func layer_data(map_id: String) -> Dictionary:
	var spec := MapSpec.find(map_id)
	return MapLayers.read(str(spec.layers.get(LAYER_ID, ""))) if spec else {}


func _build() -> void:
	if _built or map_world == null or map_world.spec == null:
		return
	if data.is_empty():
		data = GatherLayer.layer_data(map_world.spec.id)
	if data.is_empty():
		return
	var ground := map_world.ground
	store = NodeStore.new(data.get("nodes", []), {"seed": int(data.get("seed", 0)),
		"height_at": func(x: float, z: float) -> float: return ground.height_at(x, z) if ground else 0.0,
		"reject": _reject})
	field = GatherField.new()
	field.name = "Nodes"
	add_child(field)
	field.setup(store)
	ring = StrikeRing.new()
	add_child(ring)
	for row: Dictionary in data.get("benches", []):
		_add_bench(row)
	gather = Gather.new(store, null)
	gather.dark = func() -> bool: return clock != null and clock.dark()
	gather.cond = func(expr: String) -> bool: return session.holds(expr) if session else Cond.holds(expr, Cond.DictCtx.new({}))
	gather.apply_fx = func(list: Variant, src: String) -> void:
		if session:
			session.apply_effects(list, src)
	gather.spill_at = _spill_at
	gather.mount_key = func() -> String: return hud.bag.transfer_key() if hud else ""
	gather.swing_started.connect(_on_swing_started)
	gather.ring_judged.connect(_on_ring_judged)
	gather.struck.connect(_on_struck)
	gather.hold_started.connect(_on_hold_started)
	gather.yielded.connect(_on_yielded)
	gather.depleted.connect(_on_depleted)
	gather.refused.connect(func(_r: String, text: String) -> void: _toast(text, "warn"))
	gather.stopped.connect(_on_stopped)
	_bind_economy()
	_built = true
	built.emit()
	_dev_demo_start()


func _add_bench(row: Dictionary) -> void:
	var id := str(row.get("id", ""))
	var st := str(row.get("station", ""))
	if id.is_empty() or Craft.station(st).is_empty():
		return
	var at: Vector2 = MapSpec.vec2(row.get("at", [0.0, 0.0]))
	var node := Workbench.new()
	node.name = id.to_pascal_case()
	node.station = st
	node.bench_id = id
	add_child(node)
	node.place(map_world.on_ground(at), DepartWorld.yaw_of(float(row.get("facing", 0.0))))
	var ws := Workshop.new({"id": id, "station": st, "at": node.position})
	ws.crew = {"W": float(row.get("crew", 0.0)), "roles": (row.get("masters", []) as Array).duplicate()}
	var chest := ItemContainer.make("chest", {"id": "bench.%s" % id, "owner": "world"})
	var start: Dictionary = row.get("chest", {})
	for item: String in start:
		chest.add(item, int(start[item]))
	benches[id] = {"node": node, "ws": ws, "chest": chest, "row": row}


## Yerleşimin reddi (economy.md §3.5): yapıların ve tezgâhların ayak izi, ocağın 9 m'si, patikanın 3 m'si.
func _reject(x: float, z: float, _kind: String) -> bool:
	var p := Vector2(x, z)
	for s: Dictionary in map_world.spec.structures:
		var at: Vector2 = s["at"]
		var r := 9.0 if str(s.get("kind", "")) == "campfire" else float(s.get("radius", s.get("size", 1.5))) + 1.2
		if p.distance_to(at) < r:
			return true
	for b: Dictionary in data.get("benches", []):
		if p.distance_to(MapSpec.vec2(b.get("at", [0.0, 0.0]))) < 3.0:
			return true
	for path: Dictionary in (map_world.spec.ground.get("paths", []) as Array):
		var pts: Array = path.get("points", [])
		for k in range(pts.size() - 1):
			var a := MapSpec.vec2(pts[k])
			var b := MapSpec.vec2(pts[k + 1])
			if Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p) < float(path.get("width", 2.0)) * 0.5 + 3.0:
				return true
	return false


## Ekonomi: oturum kuruluysa onunki (Session «sites» adımı, «economy» bloğu, «economy» hizmeti), değilse katmanınki ve kendi saati.
func _bind_economy() -> void:
	var s := _find_session()
	if economy and s == session:
		return
	if economy and map_world and map_world.spec:
		economy.detach_store(map_world.spec.id)
		for id: String in benches:
			economy.detach_workshop(id)
	session = s
	if session:
		var existing: Variant = session.get_system(&"economy")
		economy = existing as Economy if existing is Economy else null
		if economy == null:
			economy = Economy.new()
			session.add_system(&"sites", economy, &"economy")
			economy.register(session.blocks)
			session.add_service("economy", economy)
			economy.bind_session(session)
		economy.clock = session.clock
		clock = session.clock
		_local_clock = false
	else:
		economy = Economy.new()
		clock = GameClock.new(GameClock.ROAM_DAY, LOCAL_MINUTE)
		economy.clock = clock
		_local_clock = true
	economy.reset_clock_mark()
	economy.env = _workshop_env
	economy.attach_store(map_world.spec.id, store)
	for id: String in benches:
		economy.attach_workshop(benches[id]["ws"], benches[id]["chest"])
	if not economy.workshop_done.is_connected(_on_workshop_done):
		economy.workshop_done.connect(_on_workshop_done)


func _find_session() -> Session:
	var main := map_world.get_parent() if map_world else null
	return main.get_node_or_null(^"Session") as Session if main else null


## Tezgâhların ortamı: gece sınıfı (saatin ışığı; atölye ışıklı sayılır) ve hava (oturumun havası yoksa açık).
func _workshop_env() -> Dictionary:
	var env := {"lit": "lit", "dark": clock != null and clock.dark(), "weather": {"type": "clear", "dryK": 1.0}, "window": true}
	for id: String in benches:
		var b: Dictionary = benches[id]
		var ws: Workshop = b["ws"]
		ws.crew["W"] = bench_crew(id)
	return env


# --- Bağlama -----------------------------------------------------------------------------------------------------------------

## Oyuncu, HUD ve ilerleme (Main'in alanlarından; Main yoksa katman yalnız görünüştür).
func _bind() -> void:
	var main := map_world.get_parent()
	if main == null:
		return
	var p: Variant = main.get(&"player")
	player = p as PlayerController if p is PlayerController else null
	var h: Variant = main.get(&"gameplay_hud")
	hud = h as GameplayHud if h is GameplayHud else null
	if session:
		# Oturumun ilerlemesi (Session.progression; HUD'un seviyesi ve XP'si de bunu okur), yoksa Effects'in «progress» hizmeti.
		var svc: Variant = session.progression if session.progression else session.services().get("progress")
		progression = svc as Progression if svc is Progression else progression
	if progression == null:
		progression = Progression.new()
	var inv: Inventory = hud.bag.inventory if hud else null
	if gather.inventory != inv:
		gather.inventory = inv
		_kit_given = false
	gather.stamina = hud.vitals if hud else null
	gather.mods = progression.mods
	gather.award = progression.award
	var derived := progression.derived()
	gather.strike_mul = float(derived.get("strikeMul", 1.0))
	gather.foot = int(progression.stats.get("foot", 3))
	gather.lang = SubtitleBar.ui_lang()
	gather.diff_k = _strike_ring()
	if session and session.journey:
		_ring_seen = bool(session.journey.flags.get("_seen.strike_ring", _ring_seen))


## Deneme takımı oyun başlayınca verilir (HUD görünür: begin_body Heybe'yi boşalttıktan sonra); bir kez.
func _give_kit() -> void:
	if _kit_given or hud == null or not hud.is_shown() or not gather.inventory is Inventory:
		return
	var inv: Inventory = gather.inventory
	for tool_id: Variant in data.get("kit", []):
		if not inv.has_tool(str(tool_id)):
			inv.add(str(tool_id), 1, "kit")
	_kit_given = true


func _strike_ring() -> float:
	var main := map_world.get_parent()
	var prof: Variant = main.get(&"profile") if main else null
	var diff := (prof as CharacterProfile).difficulty_id() if prof is CharacterProfile else "normal"
	for lv: Dictionary in Catalog.data("character/difficulty").get("levels", []):
		if str(lv.get("id", "")) == diff:
			return float(lv.get("strikeRing", 1.0))
	return 1.0


## Oyuncu bu haritada mı (zemini bu haritanınki) ve oynuyor mu?
func _player_here() -> bool:
	return player != null and is_instance_valid(player) and player.is_inside_tree() and player.is_active() and player.terrain_shape == map_world.ground


# --- Kare ----------------------------------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if not _built:
		return
	_bind_left -= delta
	if _bind_left <= 0.0:
		_bind_left = 0.5
		_bind_economy()
		_bind()
	if _local_clock and clock:
		clock.step(delta)
		economy.step(delta)
	if is_instance_valid(_screen):
		return
	_give_kit()
	if not _demo.is_empty() and not _demo_running and _player_here() and hud and hud.is_shown():
		_dev_demo_run()
	var here := _player_here()
	if not here:
		if gather.is_busy():
			gather.cancel()
		_set_focus({})
		_send_pairs([])
		return
	var has_e := InputMap.has_action(&"accept")
	var pressed := has_e and Input.is_action_just_pressed(&"accept") and not _skip_press
	_skip_press = false
	var held := has_e and Input.is_action_pressed(&"accept")
	if gather.is_busy():
		var moved := player.get_speed() > MOVE_CUT or player.is_riding() or player.is_jumping() or InputSetup.move_vector() != Vector2.ZERO
		if not _demo_hold:
			gather.step(delta, pressed, held, moved)
		_follow_work()
		if gather.state == Gather.State.SWING and hud:
			# Vuruş boyunca stamina dolmaz (economy.md §3.1: restT = 0); Vitals'ın dolma beklemesi her kare yeniden başlar.
			hud.vitals.set(&"_since_run", 0.0)
	_update_focus()
	_update_prompt()
	if player.camera is FollowCamera and (not focus.is_empty() or gather.is_busy()):
		(player.camera as FollowCamera).hold_turn_right = true


func _unhandled_input(event: InputEvent) -> void:
	if not _built or not InputMap.has_action(&"accept") or not event.is_action_pressed(&"accept") or event.is_echo() or not _player_here():
		return
	if is_instance_valid(_screen):
		return
	if gather.is_busy():
		# Süren vuruşta yeni basış halkanındır (_process okur); bineğe binmesin.
		get_viewport().set_input_as_handled()
		return
	if focus.is_empty() or not player.prompt_pairs().is_empty():
		return
	if str(focus["kind"]) == "bench":
		open_bench(str(focus["id"]))
		get_viewport().set_input_as_handled()
		return
	var i := int(focus["index"])
	if begin_gather(i):
		_skip_press = true
	get_viewport().set_input_as_handled()


## Düğümde işi başlatır (E; sınama da çağırır): Mete düğüme döner, işin pozu hazırlanır. → başladı mı.
func begin_gather(i: int) -> bool:
	if gather == null or not _player_here():
		return false
	gather.first_ring = not _ring_seen
	_prepare_clips()
	var to := store.position_of(i) - player.global_position
	if Vector2(to.x, to.z).length() > 0.05:
		player.spawn_at(player.global_position, atan2(to.x, to.z))
	return gather.begin(i, true)


func _update_focus() -> void:
	if gather.is_busy():
		return
	var want := {}
	var ok := not player.is_riding() and not player.is_jumping() and not player.is_seated() and not player.is_aiming() and player.mount_in_reach() == null
	if ok:
		var p := player.global_position
		var best_d := INF
		for id: String in benches:
			var d := (benches[id]["node"] as Workbench).distance_to(p)
			if d <= BENCH_REACH and d < best_d:
				best_d = d
				want = {"kind": "bench", "id": id}
		if want.is_empty():
			var reach := float(NodeStore.constants().get("reach", 2.1))
			var i := store.nearest(p.x, p.z, reach, func(n: int) -> bool: return not gather.offer(n).is_empty())
			if i >= 0:
				want = {"kind": "node", "index": i}
	_set_focus(want)


func _set_focus(f: Dictionary) -> void:
	focus = f


## İstem: oyuncunun kendi istemi boşsa (binek önce gelir) katmanın istemi; değişince PlayerController.prompt_changed ile (HUD ve ipucu paneli).
func _update_prompt() -> void:
	var own := player.prompt_pairs()
	if not own.is_empty():
		_pairs = own
		return
	var want: Array = []
	var lg := SubtitleBar.ui_lang()
	if gather.is_busy():
		if gather.state == Gather.State.SWING:
			want = [["E", NodeStore.message("clean", lg)]]
		else:
			var o := gather.offer(gather.index)
			want = [["E", str(o.get("label", ""))]] if not o.is_empty() else []
	elif not focus.is_empty():
		if str(focus["kind"]) == "bench":
			want = [["E", Craft.station_name(str(benches[focus["id"]]["row"]["station"]), lg)]]
		else:
			var o := gather.offer(int(focus["index"]))
			if not o.is_empty():
				var label := str(o["label"])
				want = [["E", label if o["enabled"] else "%s · %s" % [label, o["deny"]]]]
	_send_pairs(want)


func _send_pairs(pairs: Array) -> void:
	if pairs == _pairs:
		return
	_pairs = pairs
	if player and is_instance_valid(player):
		player.prompt_changed.emit(pairs)


# --- İşin görünüşü -----------------------------------------------------------------------------------------------------------

## İşin klipleri (kütüphaneden, kişinin bedenine aktarılmış): tutuşun üç klibi ve vuruşun dayanağı. Bir kez (model değişince yeniden).
func _prepare_clips() -> void:
	var avatar := player.get_avatar()
	if avatar == null or avatar.get_skeleton() == null or _clips_model == avatar.model_id:
		return
	_clips_model = avatar.model_id
	var clips: Dictionary = NodeStore.data().get("clips", {})
	for key: String in ROLES:
		player.call(&"_add_held_clip", ROLES[key], str(clips.get(key, "")))
	player.call(&"_add_held_clip", ROLE_SWING, str(clips.get("swing", "idle_3")))
	ClipVariety.release_sources()


func _ensure_swing() -> void:
	var avatar := player.get_avatar()
	var skeleton := avatar.get_skeleton() if avatar else null
	if skeleton == null:
		return
	if not is_instance_valid(_tool):
		_tool = MeshInstance3D.new()
		_tool.name = "Tool"
		_tool.material_override = Style.toon(Color.WHITE, {"use_vertex_color": true})
		_tool.visible = false
		add_child(_tool)
	if not is_instance_valid(_swing) or _swing.get_skeleton() != skeleton:
		if is_instance_valid(_swing):
			_swing.queue_free()
		_swing = ToolSwing.attach(skeleton, _tool, avatar.model_scale)


func _on_swing_started(info: Dictionary) -> void:
	var i := int(info["index"])
	var at := store.position_of(i)
	if bool(info["ring"]):
		ring.start(at, float(info["T"]), float(info["window"]), bool(info["gold"]), float(info["contact_k"]))
		if not _ring_seen:
			_ring_seen = true
			if session and session.journey:
				session.journey.flags["_seen.strike_ring"] = true
	else:
		ring.stop()
	if player == null:
		return
	player.work_role = ROLE_SWING
	_ensure_swing()
	var cls := str(info["cls"])
	var tool_kind := "pick" if cls == "pick" else "axe"
	if not _tool_meshes.has(tool_kind):
		_tool_meshes[tool_kind] = GatherMeshes.tool_mesh(tool_kind)
	if is_instance_valid(_tool):
		_tool.mesh = _tool_meshes[tool_kind]
	if is_instance_valid(_swing):
		var row := store.row_of(i)
		_swing.kind = "pick" if cls == "pick" else "chop"
		_swing.target = at + Vector3(0.0, 1.0 if row.get("tree", false) else 0.45, 0.0)
		_swing.amount = 1.0
		_swing.phase = 0.0


func _on_hold_started(info: Dictionary) -> void:
	ring.start(store.position_of(int(info["index"])), 1.0, 0.0, false, 1.0)
	if player:
		player.work_role = ROLES.get(str(info.get("clip", "collect")), &"work_collect")
	if is_instance_valid(_swing):
		_swing.amount = 0.0


## Kare: halkanın saati, vuruşun evresi, tutuşun ilerlemesi (halka bandı doldurur).
func _follow_work() -> void:
	if gather.state == Gather.State.SWING:
		ring.set_time(gather.t)
		if is_instance_valid(_swing):
			_swing.phase = gather.t / maxf(gather.T, 0.001)
	elif gather.state == Gather.State.HOLD:
		ring.set_time(gather.hold_k())


func _on_ring_judged(clean: bool, _auto: bool) -> void:
	ring.resolve(clean)
	if clean and economy:
		economy.count_stat("clean")


func _on_struck(i: int, info: Dictionary) -> void:
	field.strike(i, str(info.get("cls", "axe")))
	if economy:
		economy.count_stat("strikes")


func _on_yielded(i: int, item_id: String, n: int, _info: Dictionary) -> void:
	var lg := SubtitleBar.ui_lang()
	field.gain(i, NodeStore.message("gain", lg, {"n": n, "item": ItemCatalog.name_of(item_id, lg)}))
	if economy:
		economy.count_stat("gathered", n)


func _on_depleted(i: int, _kind_id: String, info: Dictionary) -> void:
	if bool(info.get("tree", false)):
		var away := store.position_of(i) - (player.global_position if player else Vector3.ZERO)
		field.fell(i, away)
		if economy:
			economy.count_stat("felled")
	if player and is_instance_valid(player):
		player.refresh_obstacles()


func _on_stopped() -> void:
	ring.stop()
	if player and is_instance_valid(player):
		player.work_role = &""
	if is_instance_valid(_swing):
		_swing.amount = 0.0


## Sığmayan verimin yeri: düğümün dibinde, oyuncuya doğru (economy.md §3.1 «Yük»).
func _spill_at(i: int) -> Vector3:
	var at := store.position_of(i)
	if player == null:
		return at
	var d := player.global_position - at
	d.y = 0.0
	var r := float(store.row_of(i).get("r", 0.4)) + 0.5
	var p := at + (d.normalized() * r if d.length() > 0.01 else Vector3(r, 0.0, 0.0))
	return Vector3(p.x, map_world.ground.height_at(p.x, p.z) if map_world.ground else at.y, p.z)


func _toast(text: String, kind := "info") -> void:
	if hud and hud.toast and is_instance_valid(hud.toast):
		hud.toast.show_text(text, kind)


# --- Tezgâh ----------------------------------------------------------------------------------------------------------------------

## Tezgâhın elleri (W): haritanın yazdığı ekip ve Birlikte Çalış açıkken tezgâhın başındaki Mete (Defter'in ≈süresi de bunu okur).
func bench_crew(id: String) -> float:
	if not benches.has(id):
		return 0.0
	var row: Dictionary = benches[id]["row"]
	return float(row.get("crew", 0.0)) + (1.0 if helping.get(id, false) and _near_bench(id) else 0.0)


func _near_bench(id: String) -> bool:
	return player != null and is_instance_valid(player) and benches.has(id) and (benches[id]["node"] as Workbench).distance_to(player.global_position) <= BENCH_REACH + 1.0


## Tezgâhın sayfasını açar (oyun durur; Esc kapatır). → açıldı mı.
func open_bench(id: String) -> bool:
	if not benches.has(id) or (is_instance_valid(_screen)):
		return false
	_send_pairs([])
	var s := HudCraftScreen.new()
	s.layer = self
	s.bench_id = id
	if not is_instance_valid(_screen_layer):
		_screen_layer = CanvasLayer.new()
		_screen_layer.name = "CraftScreens"
		_screen_layer.layer = 100
		_screen_layer.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_screen_layer)
	_screen = s
	s.closed.connect(_on_screen_closed.bind(s))
	_screen_layer.add_child(s)
	if is_inside_tree():
		get_tree().paused = true
	return true


func _on_screen_closed(s: HudCraftScreen) -> void:
	if _screen != s:
		return
	_screen = null
	if is_inside_tree():
		get_tree().paused = false
	var lapse := _lapse_bench
	_lapse_bench = ""
	if not lapse.is_empty():
		_start_lapse(lapse)


func _close_screen() -> void:
	if is_instance_valid(_screen):
		_screen.close()


func screen() -> HudCraftScreen:
	return _screen if is_instance_valid(_screen) else null


func bench(id: String) -> Dictionary:
	return benches.get(id, {})


## Tezgâhta hazır olan ustalar (Usta derecesi) ve tezgâh kimliği (can_craft'ın station ve roles'ü).
func bench_roles(id: String) -> Array:
	return ((benches.get(id, {}) as Dictionary).get("row", {}) as Dictionary).get("masters", [])


## Öğrenilmiş beceriler (can_craft'ın skills'i).
func skills() -> Callable:
	var p := progression
	return func(skill_id: String) -> bool: return p != null and p.learned.has(skill_id)


## El işi bitti: girdi Heybe'den, çıktı Heybe'ye; ilk kez +20 XP (Progression «recipe»). → {out, xp} ya da boş.
func craft_hand(id: String, recipe_id: String) -> Dictionary:
	var inv: Inventory = gather.inventory as Inventory if gather and gather.inventory is Inventory else null
	if inv == null or not benches.has(id):
		return {}
	var check := Craft.can_craft(recipe_id, {"inv": inv, "station": str(benches[id]["row"]["station"]), "roles": bench_roles(id), "skills": skills()})
	if not check["ok"]:
		return {}
	var day: Variant = clock.day_n if clock else null
	var res := Craft.craft_hand(recipe_id, inv, {"first": not economy.crafted.has(recipe_id), "day": day})
	if res.is_empty():
		return {}
	economy.note_crafted(recipe_id)
	var xp := progression.award("recipe", {"key": recipe_id}) if progression else 0
	res["xp"] = xp
	return res


## Tezgâhın sırasına sipariş (girdi tezgâhın sandığından). → sıra ya da -1.
func order(id: String, recipe_id: String, n := 1) -> int:
	if not benches.has(id):
		return -1
	return (benches[id]["ws"] as Workshop).order(recipe_id, n)


## Malzemeyi Bırak: seçili tarifin n biriminin eksik girdisi Heybe'den tezgâhın sandığına (economy.md §13 econ.store_materials).
func store_materials(id: String, recipe_id: String, n := 1) -> Array:
	var inv: Inventory = gather.inventory as Inventory if gather and gather.inventory is Inventory else null
	if inv == null or not benches.has(id):
		return []
	var chest: ItemContainer = benches[id]["chest"]
	var moved: Array = []
	for e: Dictionary in Craft.inputs_of(recipe_id):
		var lack := int(e["n"]) * n - chest.count(str(e["id"]))
		if lack > 0:
			var r := inv.deliver_to(chest, str(e["id"]), lack)
			moved.append_array(r.get("items", []))
	return moved


## Eksikleri Al: seçili el tarifinin eksik girdisi sandıktan Heybe'ye (Inventory.take_missing).
func take_missing(id: String, recipe_id: String, n := 1) -> Dictionary:
	var inv: Inventory = gather.inventory as Inventory if gather and gather.inventory is Inventory else null
	if inv == null or not benches.has(id):
		return {}
	var need: Array = []
	for e: Dictionary in Craft.inputs_of(recipe_id):
		need.append({"id": e["id"], "n": int(e["n"]) * n})
	return inv.take_missing(benches[id]["chest"], need)


## Hepsini Al: sandığın bütün içeriği Heybe'ye (sığdığı kadar).
func take_all(id: String) -> Dictionary:
	var inv: Inventory = gather.inventory as Inventory if gather and gather.inventory is Inventory else null
	if inv == null or not benches.has(id):
		return {}
	return inv.take_all(benches[id]["chest"])


## Bitene Dek Bekle: sayfa kapanınca saat tezgâhın kalan işi kadar hızlı akar (GameClock.begin_lapse «work», ≈3 sn); oturumsuz katmanın
## saatinde de aynı. → kalan oyun dakikası (iş yoksa 0).
func wait_until_done(id: String) -> float:
	if not benches.has(id):
		return 0.0
	var ws: Workshop = benches[id]["ws"]
	_workshop_env()
	var minutes := ws.remaining_minutes()
	if minutes <= 0.0 or not is_finite(minutes):
		return 0.0
	_lapse_bench = id
	_lapse_chain = 0
	_close_screen()
	return minutes


func _start_lapse(id: String) -> void:
	if clock == null or not benches.has(id):
		return
	_watch_clock()
	var ws: Workshop = benches[id]["ws"]
	_workshop_env()
	var minutes := ws.remaining_minutes(-1.0, _night_class(id))
	if minutes <= 0.0 or not is_finite(minutes):
		_lapse_active = ""
		return
	_lapse_active = id
	_lapse_to = clock.abs_minute() + minutes + 0.5
	if not clock.begin_lapse(_lapse_to, LAPSE_S, &"work"):
		_lapse_active = ""
		clock.skip(minutes + 0.5, &"work")
		economy.step(0.0)


## Tezgâhın şimdiki ışık sınıfı (Workshop.tick'in kuralı): gündüz «day»; karanlıkta meşalesi yanan ya da sandığında meşale olan atölye
## «lit», yoksa «dark».
func _night_class(id: String) -> String:
	if clock == null or not clock.dark():
		return "day"
	var ws: Workshop = benches[id]["ws"]
	var chest: ItemContainer = benches[id]["chest"]
	return "lit" if ws.torch_left > 0.0 or chest.count("torch") > 0 else "dark"


func _watch_clock() -> void:
	if _watched_clock == clock:
		return
	if _watched_clock and _watched_clock.skipped.is_connected(_on_clock_skipped):
		_watched_clock.skipped.disconnect(_on_clock_skipped)
	_watched_clock = clock
	if clock and not clock.skipped.is_connected(_on_clock_skipped):
		clock.skipped.connect(_on_clock_skipped)


## Akış bitti: hedefe vardıysa (başka bir şey kesmediyse), tezgâhın işi sürüyorsa ve bekleme nedeni yoksa (gece yavaşlattı) akış kalan
## kadar uzar.
func _on_clock_skipped(info: Dictionary) -> void:
	if not bool(info.get("lapse", false)) or StringName(info.get("reason", &"")) != &"work" or _lapse_active.is_empty():
		return
	var id := _lapse_active
	_lapse_active = ""
	if not benches.has(id) or float(info.get("to", 0.0)) < _lapse_to - 0.01:
		_lapse_chain = 0
		return
	var ws: Workshop = benches[id]["ws"]
	if ws.queue.is_empty() and ws.cures.is_empty():
		_lapse_chain = 0
		return
	var st := ws.status()
	var waiting: Variant = st.get("wait", {})
	if (waiting is Dictionary and not (waiting as Dictionary).is_empty()) or _lapse_chain >= LAPSE_CHAIN:
		_lapse_chain = 0
		return
	_lapse_chain += 1
	_start_lapse(id)


func _on_workshop_done(id: String, done: Array) -> void:
	var lg := SubtitleBar.ui_lang()
	var names := PackedStringArray()
	for e: Dictionary in done:
		if not str(e["id"]).begins_with("@"):
			names.append("%d %s" % [int(e["n"]), ItemCatalog.name_of(str(e["id"]), lg)])
	if not names.is_empty() and not is_instance_valid(_screen):
		_toast(Craft.message("done", lg, {"item": ", ".join(names)}))
	crafted.emit(id, done)
	if is_instance_valid(_screen):
		_screen.queue_redraw_all()
	# Bitene Dek Bekle: iş bitti, akış burada kesilir (gece tahmini uzunsa saat boşa akmaz).
	if id == _lapse_active and clock and clock.is_lapsing():
		var ws: Workshop = benches[id]["ws"]
		if ws.queue.is_empty() and ws.cures.is_empty():
			clock.end_lapse()


# --- Geliştirme: inceleme kareleri (--gather-demo) ----------------------------------------------------------------------------------

## --gather-demo=pine|fell|ore|stone|reed|dung|pile|yard|smithy|order|done (deneme haritasında, tools/capture.sh ile): Mete düğümün ya da tezgâhın
## yanına konur, iş başlatılır ve görüntü (DevCapture) işin okunur anına dek bekletilir: halka kapanırken, çam devrilirken, tutuşun ortasında,
## sayfa açıkken, iş bittiğinde Heybe açıkken. Oyuncunun kaydına ve ayarına dokunmaz (geliştirme koşusunda kayıt yazılmaz: SaveSystem
## yazılamaz kurulur).
func _dev_demo_start() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--gather-demo="):
			_demo = arg.substr(14)
	if _demo.is_empty():
		return
	var cap := get_node_or_null(^"/root/DevCapture")
	if cap and cap.has_method(&"hold_capture"):
		cap.call(&"hold_capture")


func _dev_release() -> void:
	var cap := get_node_or_null(^"/root/DevCapture")
	if cap and cap.has_method(&"release_capture"):
		cap.call(&"release_capture")


func _dev_wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, true).timeout


## Mete düğümün güneydoğusunda, düğüme bakar; kamera arkasından ve biraz yandan (K98 kadrajı: 28 m, 38°).
func _dev_stand(i: int, side := Vector3(0.45, 0.0, 1.0)) -> void:
	var at := store.position_of(i)
	var r := float(store.row_of(i).get("r", 0.4))
	var from := at + side.normalized() * (r + 0.95)
	player.spawn_at(from, atan2(at.x - from.x, at.z - from.z))
	_dev_camera(player.get_facing_yaw() + _dev_yaw())


func _dev_camera(yaw: float) -> void:
	var main := map_world.get_parent()
	var cam: Variant = main.get(&"follow_camera") if main else null
	if cam is FollowCamera:
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--gather-zoom="):
				(cam as FollowCamera).set_start_distance(float(arg.substr(14).replace(",", ".")))
		(cam as FollowCamera).set_yaw(yaw - PI, true)
		(cam as FollowCamera).snap_to_target()


## Türün en güneydeki işlenebilir düğümü: kamera kuzeye bakar, önünde başka düğüm kalmaz.
## Kare anı (vuruşun evresi, 0..1): --gather-phase=0.4 (varsayılan kaldırışın sonu).
func _dev_phase() -> float:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--gather-phase="):
			return clampf(float(arg.substr(15).replace(",", ".")), 0.0, 0.99)
	return 0.4


## Kameranın Mete'nin bakışına göre yanı (derece): --gather-yaw=28.
func _dev_yaw() -> float:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--gather-yaw="):
			return deg_to_rad(float(arg.substr(13).replace(",", ".")))
	return deg_to_rad(28.0)


func _dev_first(kind: String) -> int:
	var best := -1
	for i in store.count:
		if store.kind_of(i) == kind and store.available(i) and (best < 0 or store.z[i] > store.z[best]):
			best = i
	return best


func _dev_demo_run() -> void:
	_demo_running = true
	await _dev_wait(1.0)
	var inv: Inventory = gather.inventory as Inventory if gather.inventory is Inventory else null
	match _demo:
		"pine", "fell", "ore", "stone", "pile":
			var kind: String = {"pine": "node_pine", "fell": "node_pine", "pile": "node_pine", "ore": "node_vein_iron", "stone": "node_boulder"}[_demo]
			var i := _dev_first(kind)
			if _demo == "pile" and inv:
				# Heybe dolu (ateş ve av katmanının takımı 20,2 Yük): odun sığmaz, ağacın dibinde yer yığını olur.
				inv.add("stone", 4, "dev")
			_dev_stand(i)
			await _dev_wait(0.6)
			begin_gather(i)
			Input.action_press(&"accept")
			if _demo == "fell" or _demo == "pile":
				while store.available(i) and is_inside_tree():
					await get_tree().process_frame
				# Devrilmenin ortası (1,2 sn'nin 0,9'u: ağaç ~48° yatmış) ya da yığının kurulduğu an.
				await _dev_wait(0.9 if _demo == "fell" else 1.4)
			else:
				# Üçüncü vuruşun kaldırışının sonu: balta ya da kazma başın üstünde, halka banda yaklaşıyor.
				var swings := [0]
				gather.swing_started.connect(func(_info: Dictionary) -> void: swings[0] += 1)
				while is_inside_tree() and not (swings[0] >= 3 and gather.state == Gather.State.SWING and gather.t > gather.T * _dev_phase()):
					await get_tree().process_frame
				_demo_hold = true
				await _dev_wait(0.3)
			Input.action_release(&"accept")
		"reed", "dung":
			var i := _dev_first("node_reed" if _demo == "reed" else "node_dung")
			_dev_stand(i)
			await _dev_wait(0.6)
			begin_gather(i)
			Input.action_press(&"accept")
			while is_inside_tree() and gather.state == Gather.State.HOLD and gather.hold_k() < 0.62:
				await get_tree().process_frame
			_demo_hold = true
			await _dev_wait(0.3)
		"yard":
			player.spawn_at(map_world.on_ground(Vector2(14.0, 30.0)), deg_to_rad(200.0))
			_dev_camera(deg_to_rad(200.0))
			await _dev_wait(1.2)
		"smithy", "order", "done":
			if inv:
				# Heybe boşalır (ateş ve av katmanının takımı 20,2 Yük); araçlar kalır.
				inv.pack.clear()
				if _demo == "smithy":
					inv.add("ore_iron", 4, "dev")
				else:
					inv.add("wood_pine", 3, "dev")
			var bid := "bench_smithy" if _demo == "smithy" else "bench_wood"
			var node: Workbench = benches[bid]["node"]
			player.spawn_at(node.global_position + Vector3(0.0, 0.0, 2.1), PI)
			_dev_camera(PI)
			await _dev_wait(0.8)
			if _demo == "smithy":
				open_bench(bid)
				_screen.select("rc_iron_bar")
				await _dev_wait(0.3)
			else:
				inv.add("iron_bar", 1, "dev")
				open_bench(bid)
				var sc := _screen
				sc.select("rc_door_frame")
				sc.do_button("store")
				sc.make()
				sc.do_button("help")
				await _dev_wait(0.3)
				if _demo == "done":
					sc.do_button("wait")
					var chest: ItemContainer = benches[bid]["chest"]
					while is_inside_tree() and chest.count("door_frame") == 0:
						await get_tree().process_frame
					await _dev_wait(0.6)
					take_all(bid)
					hud.open_page("bag")
					await _dev_wait(0.8)
	_dev_release()
