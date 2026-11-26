class_name TravelLayer
extends Node3D
## İç haritanın Menzil ağı, Yol Kemikleri ve Kantu'nun arabası (Yol Haritası roads-relays; travel.md §3–§8, §11; act1.md §4 «Yol ağı», «Yol
## Kemikleri», «Menzil», §9.4). map.json «layers» → data/maps/<id>/travel.json («script» bu dosya); MapLayers kurar, setup(world, def) çağrılır.
## Yol ağının geometrisi haritanın yol dosyasındandır (def.roads → roads.json: düğümler, kenarlar, hız sınırları; sahibi arazidir); duraklar,
## direkler, kapılar ve araba bu katmanındır. Durum Travel'dadır (kayıt v2 «travel» bloğu; oturum varsa bağlanınca kaydolur, bırakınca kaydı
## taşınır).
##
## Oyuncu (yaya ya da at sırtında) bir durağın 15 m'sine girince durak bulunur; bağlı Yol Kemiği onarılmışsa bağlanır (+10 XP). Yol Kemiği:
## E basılı 20 sn (1 kemik + 1 ip ya da 4 taş); onarılan direk uğuldar, durağı bağlar. Menzil Direği: E vurur (araba çağrılır: ≤160 m yolda
## yakınsa sürerek gelir, değilse durağa giren bir dalda kadraj dışından doğar ve ≤20 sn'de gelir), E basılı Menzil Ambarı'nı açar. Araba
## gelince 40 sn bekler; arka ağzına (≤2,6 m) E: biniş (0,62 sn), Yol Kartı açılır. Yolu İzle: araba yolu gerçekten sürer (yolda en çok
## oyuncunun koşusu, K105: 4,6 m/sn; karda 4,0; sınır bölgelerinde 3,2), saat kendi akışıyla yürür; E basılı 3 sn (0,25 sn ölü bölge, 2,4 sn'den
## önce bırakmak iptal) ya da karttan Yolu Kısalt: kararır, araba hedefe 18 m kalaya yolun üstünde taşınır, saat kalan doğal süre kadar atlar,
## açılır, son 18 m görünür sürülür (ışınlanma yok). Varışta iniş (0,56 sn), yük Ambar durağında teslim, oto kayıt («alight»); kalkışta oto
## kayıt («depart», ücretten önce; ride kayda girer: yükleme kalkış durağına koyar). Yolda kısa E ya da Esc: araba 1,5 sn'de durur, inilir,
## araba Menzil'e döner. Yolcunun kamerası 40°, 32 m (act1.md §4 «açılıştaki araba çekimi»; K98).
## Geliştirme: --travel=link (bütün durakları bağlar), --travel=call (araba en yakın durakta bekler), --travel=board (çağır ve bin),
## --travel=ride:<durak>, --travel=shorten:<durak>.

enum Cart { PARKED, CALLED, WAITING, BOARDING, CARD, CRUISE, SKIP, ARRIVE, ALIGHT, STOPPING, LEAVING }

const PROCESS_PRIORITY := 5
## Durağın direğinde E: bu süreden uzun basılı tutuş Menzil Ambarı'nı açar.
const STASH_HOLD_S := 0.6
## Yolcunun kamerası (K98; act1.md §4: araba çekimi 40°, 32 m).
const CART_PITCH := 40.0
const CART_DISTANCE := 32.0
## Arabanın kaybolduğu uzaklık (oyuncudan; kadraj dışıyken).
const VANISH_M := 45.0
## Kalkıştaki dönüş: yön farkı bundan büyükse at dingilin çevresinde döner (m: yay yarıçapı koşum uzaklığıdır).
const TURN_IN_PLACE := deg_to_rad(65.0)
const CaptureTool := preload("res://scripts/dev/capture.gd")

var world: Node3D
var def: Dictionary = {}
var graph: RoadGraph
var travel: Travel
var cart: RoadCart
var posts: RelayPosts
var lang := "tr"

var main: Node
var player: PlayerController
var hud: GameplayHud
var camera: FollowCamera
var session: Session

## Arabanın durumu ve durduğu (beklediği) durak.
var state: Cart = Cart.PARKED
var cart_station := ""
## Süren sürüş: {points, cum, length, s, speed, to, purpose: call | trip | leave, stop: bool}.
var drive: Dictionary = {}
## Süren sefer: {from, to, mode}.
var trip: Dictionary = {}
## Son Yolu Kısalt: {from_m, to_m, seconds (atlanan doğal süre), minutes (oyun dk), left_m (kalan, görünür yol)}.
var last_skip: Dictionary = {}

var _attached := false
var _time := 0.0
var _wait_left := 0.0
var _recall_at := -INF
var _card: RoadCard
var _card_layer: CanvasLayer
var _e: Dictionary = {}
var _repair: Dictionary = {}
## Yolcunun oturağı (CartSeat; binişten inişe).
var seat: CartSeat
var _skip: Dictionary = {}
var _pairs: Array = []
var _sent: Array = []
var _base_pairs: Array = []
var _emitting := false
var _mine_shown := false
var _cargo_open := false
var _stable_horse: Rideable
var _dev: PackedStringArray = PackedStringArray()
var _dev_done := false


## MapLayers çağırır (ağaca eklemeden önce): harita ve katmanın sözlüğü; yol ağı burada kurulur (oturum gerekmez).
func setup(p_world: Node3D, p_def: Dictionary) -> void:
	world = p_world
	def = p_def
	var roads := MapLayers.read(str(def.get("roads", "")))
	graph = RoadGraph.from_def(def.get("graph", {}), roads)


func _ready() -> void:
	process_priority = PROCESS_PRIORITY
	if graph == null:
		graph = RoadGraph.from_def(def.get("graph", {}), MapLayers.read(str(def.get("roads", ""))))
	travel = Travel.new()
	travel.define(def)
	posts = RelayPosts.new()
	posts.name = "Posts"
	posts.hum_m = float(Travel.rule("bone.hum_m", 120.0))
	add_child(posts)
	_build_posts()
	var cdef: Dictionary = def.get("cart", {})
	if not cdef.is_empty():
		cart = RoadCart.new()
		cart.name = "Cart"
		cart.horse_mount = str(cdef.get("horse_mount", "yakwe"))
		cart.horse_model = str(cdef.get("horse_model", RoadCart.HORSE_MODEL))
		cart.driver_model = str(cdef.get("driver", "kantu"))
		cart.effects = bool(cdef.get("effects", true))
		add_child(cart)
		_park_at(str(cdef.get("park", "")))
	var args: Dictionary = CaptureTool.parse_args(OS.get_cmdline_user_args())
	if args.has("travel"):
		_dev = PackedStringArray(str(args["travel"]).split(",", false))


func _exit_tree() -> void:
	_detach()


# --- Kurulum -----------------------------------------------------------------------------------------------------------

func _ground() -> Object:
	return world.call(&"get_terrain_shape") if world and world.has_method(&"get_terrain_shape") else null


func _on_ground(p: Vector2) -> Vector3:
	var g := _ground()
	return Vector3(p.x, float(g.call(&"height_at", p.x, p.y)) if g else 0.0, p.y)


func _station(id: String) -> Dictionary:
	return travel.defs.get(id, {}) if travel else {}


func station_ids() -> Array:
	return travel.defs.keys() if travel else []


func _vec(v: Variant) -> Vector2:
	return RoadGraph.vec2(v)


func _stop_of(id: String) -> Vector2:
	var s := _station(id)
	if s.has("stop"):
		return _vec(s["stop"])
	return graph.nodes.get(str(s.get("node", "")), _vec(s.get("at", [0.0, 0.0])))


func _post_of(id: String) -> Vector2:
	var s := _station(id)
	return _vec(s.get("post", s.get("at", [0.0, 0.0])))


## Durağın adı (oyuncunun dili).
func station_name(id: String) -> String:
	var n: Variant = _station(id).get("name", id)
	return str((n as Dictionary).get(lang, (n as Dictionary).get("tr", id))) if n is Dictionary else str(n)


func _build_posts() -> void:
	var list: Array = []
	for id: String in travel.defs:
		var s := travel.defs[id] as Dictionary
		if not s.has("post"):
			continue
		var p := _post_of(id)
		var toward := _stop_of(id) - p
		list.append({"id": id, "at": _on_ground(p), "yaw": atan2(toward.x, toward.y)})
	posts.set_posts(list)
	_refresh_bones()


func _refresh_bones() -> void:
	var list: Array = []
	for id: String in travel.bone_defs:
		var at := bone_point(id)
		var near := graph.nearest_edge(at)
		var h := 0.0
		if not str(near["edge"]).is_empty():
			var e: Dictionary = graph.edges[near["edge"]]
			h = RoadGraph.heading_at(e["points"], e["cum"], float(near["s"])) + PI * 0.5
		list.append({"id": id, "at": _on_ground(at), "yaw": h, "repaired": travel.is_repaired(id)})
	posts.set_bones(list)


## Yol Kemiğinin direğinin yeri (x, z): tablonun noktası yolun orta çizgisindeyse direk yolun side metre soluna konur (arabanın yolunu kesmez).
func bone_point(id: String) -> Vector2:
	var b: Dictionary = travel.bone_defs.get(id, {})
	var at := _vec(b.get("at", [0.0, 0.0]))
	var side := float(b.get("side", 0.0))
	if absf(side) < 0.01:
		return at
	var near := graph.nearest_edge(at)
	if str(near["edge"]).is_empty() or float(near["d"]) > 2.0:
		return at
	var e: Dictionary = graph.edges[near["edge"]]
	var h := RoadGraph.heading_at(e["points"], e["cum"], float(near["s"]))
	return (near["point"] as Vector2) - CartMotion.right(h) * side


# --- Bağlanma (SurvivalLayer ile aynı kural) ------------------------------------------------------------------------------

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
	return (h as GameplayHud).is_shown() or (p as PlayerController).carried


func _attach() -> void:
	player = main.get("player")
	hud = main.get("gameplay_hud")
	camera = main.get("follow_camera") as FollowCamera
	var s: Variant = main.get("session")
	session = s if s is Session and is_instance_valid(s) else null
	lang = SubtitleBar.ui_lang()
	travel.linked.connect(_on_linked)
	travel.station_changed.connect(_on_station_changed)
	if session:
		travel.register_block(session.blocks)
		session.add_service("travel", travel)
	# Kaydın arabası bu haritanın durağındaysa oraya; sefer ortasında yazılmış kayıt kalkış durağına koyar (ücret alınmamıştır).
	if not travel.cart_at.is_empty() and travel.defs.has(travel.cart_at):
		_park_at(travel.cart_at)
	if travel.ride is Dictionary:
		var from := str((travel.ride as Dictionary).get("from", ""))
		travel.ride = null
		if travel.defs.has(from):
			var at := _post_of(from) + (_stop_of(from) - _post_of(from)) * 0.5
			player.spawn_at(_on_ground(at), player.get_facing_yaw())
	_hook_soundscape()
	_refresh_bones()
	if not player.prompt_changed.is_connected(_on_player_prompt):
		player.prompt_changed.connect(_on_player_prompt)
	_base_pairs = player.prompt_pairs() if player.is_active() else []
	_attached = true


## Haritanın ses profili Yol Kemikleri'nin bone_hum'unu kendisi çalıyorsa (MapSoundscape, emitters «bone_hum»; Kışlak) hangi direğin onarıldığını
## ondan okur (repaired), direklerin kendi uğultusu kapanır; profil yoksa (deneme haritası) uğultuyu RelayPosts çalar.
func _hook_soundscape() -> void:
	var scape: MapSoundscape = null
	if is_instance_valid(world):
		scape = world.get_node_or_null(^"Soundscape") as MapSoundscape
	var owns_hum := false
	if scape:
		for e: Variant in scape.profile.get("emitters", []):
			if e is Dictionary and str((e as Dictionary).get("id", "")) == "bone_hum":
				owns_hum = true
	if owns_hum:
		scape.repaired = travel.is_repaired
	posts.set_own_hum(not owns_hum)


func _detach() -> void:
	if not _attached:
		return
	_attached = false
	if is_instance_valid(player) and player.carried:
		_finish_alight(true)
	_close_card()
	_set_fade(0.0)
	if is_instance_valid(hud):
		hud.show_hold("", 0.0)
	if travel and travel.linked.is_connected(_on_linked):
		travel.linked.disconnect(_on_linked)
		travel.station_changed.disconnect(_on_station_changed)
	if session and is_instance_valid(session):
		session.blocks.unregister(Travel.BLOCK)
		session.block_autosave(&"travel", false)
	if is_instance_valid(player) and player.prompt_changed.is_connected(_on_player_prompt):
		player.prompt_changed.disconnect(_on_player_prompt)
		player.prompt_changed.emit(player.prompt_pairs() if player.is_active() else [])


# --- Kare --------------------------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	_time += delta
	if not _attached:
		if _live():
			_attach()
		if not _attached:
			_step_cart(delta)
			return
	if not is_instance_valid(player) or not is_instance_valid(hud):
		_detach()
		return
	var host: Variant = main.get("world_host") if is_instance_valid(main) else null
	if host is WorldHost and (host as WorldHost).map_world != world:
		_detach()
		return
	if not _dev.is_empty() and not _dev_done:
		_dev_done = true
		_run_dev.call_deferred()
	if not player.carried:
		_discover()
	_step_cart(delta)
	_step_holds(delta)
	_push_prompt()
	if camera and (_e_has_job() or player.carried):
		camera.hold_turn_right = true


func _xz() -> Vector2:
	return Vector2(player.global_position.x, player.global_position.z) if is_instance_valid(player) else Vector2.INF


func _flag(key: String) -> Variant:
	if key == "act1_day":
		return act1_day()
	var j: Variant = main.get("journey") if main and is_instance_valid(main) else null
	if j is Journey:
		return (j as Journey).get_flag(key)
	return null


## I. Perde'nin günü (Gün I = 1; oturumun saatinden). Saat yoksa 1.
func act1_day() -> int:
	if session and session.clock:
		return session.clock.day_n - Session.STORY_DAY + 1
	return 1


func _minute() -> float:
	return session.clock.minute if session and session.clock else 600.0


## Bulma (travel.md §4.3): yolcu değilken (yaya ya da at sırtında) 15 m; bölge açıkken hidden durak duyulur (rumoured).
func _discover() -> void:
	var at := _xz()
	var find_m := float(Travel.rule("station.find_m", 15.0))
	for id: String in travel.defs:
		var row: Dictionary = travel.defs[id]
		var open := Travel.region_open(row, _flag)
		if open and travel.state_of(id) == "hidden" and bool(Travel.rule("station.rumour_on_region", true)):
			travel.rumour(id)
		var d := at.distance_to(_vec(row.get("at", [0.0, 0.0])))
		if d <= find_m:
			travel.on_near(id, d, {"region_open": open})


func _on_station_changed(id: String, st: String) -> void:
	if not _attached:
		return
	if st == "found":
		_toast(Travel.text("station.found_toast", lang, {"ad": station_name(id), "name": station_name(id)}) +
			("" if travel.bone_ready(id) else " · " + Travel.text("station.found", lang)))


func _on_linked(id: String) -> void:
	_toast(Travel.text("station.linked_toast", lang, {"ad": station_name(id), "name": station_name(id)}))
	MenuStyle.play_ui(self, &"toast")
	if session and session.progression:
		session.progression.award("waystation", {"key": id})


func _toast(text: String, kind := "info") -> void:
	if is_instance_valid(hud) and hud.toast and is_instance_valid(hud.toast):
		hud.toast.show_text(text, kind)


# --- Odak ve ipucu -----------------------------------------------------------------------------------------------------

## Oyuncunun erimindeki durak direği ("" yok).
func post_in_reach() -> String:
	var at := _xz()
	var reach := float(Travel.rule("cart.reach_post", 2.1))
	var best := ""
	var best_d := INF
	for id: String in travel.defs:
		if not (travel.defs[id] as Dictionary).has("post"):
			continue
		var d := at.distance_to(_post_of(id))
		if d <= reach and d < best_d:
			best = id
			best_d = d
	return best


## Erimdeki onarılmamış Yol Kemiği ("" yok).
func bone_in_reach() -> String:
	var at := _xz()
	var reach := float(Travel.rule("bone.reach", 2.1))
	var best := ""
	var best_d := INF
	for id: String in travel.bone_defs:
		if travel.is_repaired(id):
			continue
		var d := at.distance_to(bone_point(id))
		if d <= reach and d < best_d:
			best = id
			best_d = d
	return best


## Bekleyen arabanın arka ağzı erimde mi?
func tail_in_reach() -> bool:
	if cart == null or state != Cart.WAITING:
		return false
	var t := cart.tail_center()
	return _xz().distance_to(Vector2(t.x, t.z)) <= float(Travel.rule("cart.reach_tail", 2.6))


func _on_foot() -> bool:
	return player.is_active() and not player.carried and player.get_stance() == PlayerController.Stance.FOOT and not player.is_aiming()


func my_pairs() -> Array:
	if not _attached or not is_instance_valid(player):
		return []
	if player.carried:
		match state:
			Cart.CRUISE:
				return [["E basılı", Travel.text("mode.shorten", lang)], ["E", Travel.text("cart.leave", lang)]]
		return []
	if not _repair.is_empty():
		return []
	if _on_foot() and tail_in_reach():
		return [["E", Travel.text("cart.board", lang)]]
	if _on_foot():
		var b := bone_in_reach()
		if not b.is_empty():
			var label := Travel.text("bone.repair", lang)
			if Travel.bone_cost(_inv()).is_empty():
				label += " · " + Travel.text("bone.needs", lang)
			return [["E basılı", label]]
	var post := post_in_reach()
	if not post.is_empty() and (player.is_active() and not player.carried):
		var out: Array = [["E", Travel.text("post.strike", lang)]]
		if travel.is_linked(post):
			out.append(["E basılı", Travel.text("post.stash", lang)])
		return out
	return []


func _e_has_job() -> bool:
	return not my_pairs().is_empty() or not _e.is_empty() or not _repair.is_empty()


func _on_player_prompt(pairs: Array) -> void:
	if _emitting:
		return
	# Öteki katmanın (ateş) bizim şeridimizi yeniden yayması yankıdır; oyuncunun yeni şeridi tabandır.
	if _mine_shown and pairs == _sent:
		return
	_base_pairs = pairs.duplicate()
	if _mine_shown:
		_sent = []


## Şerit: bizim işimiz varken bizimkiler önde, oyuncunun öteki tuşları ardında (aynı tuşun ikinci işi yazılmaz); işimiz bitince oyuncunun
## şeridi bir kez geri gelir.
func _push_prompt() -> void:
	var mine := my_pairs()
	if mine.is_empty():
		if _mine_shown:
			_mine_shown = false
			_sent = []
			_emit_pairs(_base_pairs)
		return
	var merged: Array = mine.duplicate()
	for p: Array in _base_pairs:
		var dup := false
		for q: Array in mine:
			if str(q[0]).begins_with(str(p[0])) or str(p[0]).begins_with(str(q[0])):
				dup = true
		if not dup:
			merged.append(p)
	if merged == _sent:
		return
	_sent = merged
	_mine_shown = true
	_emit_pairs(merged)


func _emit_pairs(pairs: Array) -> void:
	_emitting = true
	player.prompt_changed.emit(pairs)
	_emitting = false


# --- Girdi -------------------------------------------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not _attached or not is_instance_valid(player) or _card != null or _cargo_open:
		return
	if hud and hud.is_screen_open():
		return
	if event is InputEventKey and (event as InputEventKey).echo:
		return
	if player.carried:
		if event.is_action_pressed(&"accept"):
			if state == Cart.CRUISE:
				_e = {"kind": "ride", "t": 0.0}
			_handled()
		elif event.is_action_released(&"accept"):
			_release_ride_hold()
			_handled()
		elif event.is_action_pressed(&"pause"):
			if state == Cart.CRUISE:
				_get_off()
			_handled()
		return
	if event.is_action_pressed(&"accept"):
		if not _on_foot() and not (player.is_riding() and not post_in_reach().is_empty()):
			return
		if _on_foot() and tail_in_reach():
			board()
			_handled()
			return
		var b := bone_in_reach() if _on_foot() else ""
		if not b.is_empty():
			if not begin_repair(b):
				_toast(Travel.text("bone.needs", lang), "warn")
			_handled()
			return
		var post := post_in_reach()
		if not post.is_empty():
			_e = {"kind": "post", "t": 0.0, "station": post}
			_handled()
	elif event.is_action_released(&"accept"):
		if str(_e.get("kind", "")) == "post":
			var post := str(_e.get("station", ""))
			_e = {}
			strike(post)
			_handled()
		elif not _repair.is_empty():
			_repair = {}
			hud.show_hold("", 0.0)
			_handled()


func _handled() -> void:
	if is_inside_tree():
		get_viewport().set_input_as_handled()


func _step_holds(delta: float) -> void:
	var held := InputMap.has_action(&"accept") and Input.is_action_pressed(&"accept")
	match str(_e.get("kind", "")):
		"post":
			_e["t"] = float(_e["t"]) + delta
			if not held and not _e.is_empty():
				var post := str(_e["station"])
				_e = {}
				strike(post)
			elif float(_e.get("t", 0.0)) >= STASH_HOLD_S:
				var post := str(_e["station"])
				_e = {}
				open_stash(post)
		"ride":
			_e["t"] = float(_e["t"]) + delta
			var dead := float(Travel.rule("cart.skip.dead_s", 0.25))
			var hold_s := float(Travel.rule("cart.skip.hold_s", 3.0))
			var t := float(_e["t"]) - dead
			if not held:
				_release_ride_hold()
			elif t > 0.0 and state == Cart.CRUISE:
				hud.show_hold(Travel.text("hold.skip", lang), t / hold_s)
				_set_fade(clampf(t / hold_s, 0.0, 1.0))
				if t >= hold_s:
					_e = {}
					hud.show_hold("", 0.0)
					_skip = {"t": hold_s, "auto": true}
					state = Cart.SKIP
	if not _repair.is_empty():
		_step_repair(delta, held)


## Yolda E bırakıldı: ölü bölgede kısa basış inmedir; 2,4 sn'den önce bırakılan Kısalt iptaldir, sonra bırakılan kendiliğinden biter.
func _release_ride_hold() -> void:
	if str(_e.get("kind", "")) != "ride":
		return
	var t := float(_e["t"])
	_e = {}
	hud.show_hold("", 0.0)
	var dead := float(Travel.rule("cart.skip.dead_s", 0.25))
	if t < dead:
		_get_off()
		return
	if t - dead >= float(Travel.rule("cart.skip.cancel_before_s", 2.4)) and state == Cart.CRUISE:
		_skip = {"t": t - dead, "auto": true}
		state = Cart.SKIP
		return
	_fade_back()


# --- Yol Kemiği --------------------------------------------------------------------------------------------------------

## Onarımı başlatır (E basılı 20 sn; bedeli varsa). Döner: başladı mı.
func begin_repair(bone: String) -> bool:
	var cost := Travel.bone_cost(_inv())
	if cost.is_empty():
		return false
	_repair = {"bone": bone, "t": 0.0, "T": float(Travel.rule("bone.repair_s", 20.0)), "from": player.global_position, "cost": cost}
	var to := bone_point(bone) - _xz()
	if to.length() > 0.05:
		player.spawn_at(player.global_position, atan2(to.x, to.y))
	return true


func _step_repair(delta: float, held: bool) -> void:
	if not held or player.global_position.distance_to(_repair["from"]) > 0.35:
		_repair = {}
		hud.show_hold("", 0.0)
		return
	_repair["t"] = float(_repair["t"]) + delta
	hud.show_hold(Travel.text("bone.repair", lang), float(_repair["t"]) / float(_repair["T"]))
	if float(_repair["t"]) >= float(_repair["T"]):
		finish_repair(str(_repair["bone"]), _repair["cost"])
		_repair = {}
		hud.show_hold("", 0.0)


## Onarımı bitirir: bedel heybeden düşer, direk öter, bağlı durak bağlanır.
func finish_repair(bone: String, cost: Dictionary = {}) -> Dictionary:
	var inv := _inv()
	var pay := cost if not cost.is_empty() else Travel.bone_cost(inv)
	if pay.is_empty() and inv:
		return {"ok": false, "linked": []}
	if inv:
		for item: String in pay:
			inv.remove(item, int(pay[item]))
	var res := travel.repair_bone(bone, session.clock.abs_minute() if session and session.clock else _time)
	posts.set_repaired(bone, true)
	_toast(Travel.text("bone.repaired", lang, {"id": bone}))
	return res


func _inv() -> Inventory:
	if session and session.inventory:
		return session.inventory
	if is_instance_valid(hud) and hud.bag and hud.bag.inventory:
		return hud.bag.inventory
	return null


# --- Direk ve çağırma (travel.md §5.3) ---------------------------------------------------------------------------------

## Kilitlerin bağlamı (travel.md §8): bayraklar, saat, hava, arabanın yükü, ücret.
func lock_context(to := "", for_trip := false) -> Dictionary:
	var inv := _inv()
	var weather_lock := false
	var cw: Variant = main.get("_camp_weather") if main and is_instance_valid(main) else null
	if cw and cw.get("sim") and cw.sim.get("fx"):
		weather_lock = bool(cw.sim.fx.cart_lock)
	var ctx := {
		"flags": _flag, "minute": _minute(), "requires_flag": str(def.get("requires_flag", "")), "cart_lock": weather_lock,
		"cargo": inv.cart.load10() / 10.0 if inv else 0.0, "skip_fare": not for_trip, "free": travel.fare_free(_flag),
		"can_pay": not Travel.fare_item(inv).is_empty() if inv else true,
	}
	if not to.is_empty():
		ctx["region_open"] = Travel.region_open(_station(to), _flag)
		var g: Variant = _station(to).get("guarantor", "")
		ctx["guarantor"] = str((g as Dictionary).get(lang, (g as Dictionary).get("tr", ""))) if g is Dictionary else str(g)
	return ctx


## Direğe vurur: kilit yoksa araba çağrılır. Döner: çağrıldı mı.
func strike(station_id: String) -> bool:
	if station_id.is_empty() or not travel.defs.has(station_id):
		return false
	posts.knock(_on_ground(_post_of(station_id)))
	if not travel.is_linked(station_id):
		var st := travel.state_of(station_id)
		_toast(Travel.text("station.found", lang) if st == "found" else Travel.text("station.rumoured", lang), "warn")
		return false
	if player.is_riding() and player.ride_key().begins_with("yakwe@"):
		_toast(Travel.text("kantu.yakwe", lang), "warn")
		return false
	var lock := Travel.allowed(lock_context(), lang)
	if not bool(lock["ok"]):
		_toast(str(lock["text"]), "warn")
		MenuStyle.play_ui(self, &"deny")
		return false
	if state == Cart.WAITING and cart_station == station_id:
		_wait_left = float(Travel.rule("cart.wait_s", 40.0))
		return true
	if state != Cart.PARKED and state != Cart.LEAVING:
		return false
	if _time < _recall_at:
		_toast(Travel.text("kantu.recall", lang), "warn")
		return false
	summon(station_id)
	_toast(Travel.text("kantu.coming", lang))
	return true


## Arabayı durağa getirir: yakınsa (≤ drive_near_m yolda ya da kadrajda) sürerek, değilse durağa giren bir dalda kadraj dışından doğarak.
func summon(station_id: String) -> void:
	if cart == null:
		return
	if cart_station == station_id and state == Cart.PARKED:
		_arrive_waiting(station_id)
		return
	var near_m := float(Travel.rule("cart.drive_near_m", 160.0))
	var path := _path_to(station_id)
	if not path.is_empty() and (float(path["length"]) <= near_m or _cart_on_screen()):
		_begin_drive(path, "call", station_id)
		state = Cart.CALLED
		return
	var spawn := _spawn_point(station_id)
	cart.visible = true
	cart.place_axle(spawn["hitch"] - CartMotion.forward(float(spawn["heading"])) * RoadCart.HITCH_L, float(spawn["heading"]), _ground())
	_begin_drive(_finish_path(spawn["approach"], station_id), "call", station_id)
	state = Cart.CALLED


## Çağırmanın doğuş yeri (travel.md §5.3): durağın düğümüne giren dallarda 20 m'den (hız × 20 sn) m'ye, kadraj dışındaki ilk nokta; hiçbiri
## yoksa en uzağı. Döner: {hitch: Vector2, heading, approach: PackedVector2Array (doğuştan düğüme)}.
func _spawn_point(station_id: String) -> Dictionary:
	var node := str(_station(station_id).get("node", ""))
	var top := float(_speeds().get("road", 4.6))
	var far := float(Travel.rule("cart.summon_s", 20.0)) * top
	var cands := graph.approach_points(node, float(Travel.rule("cart.summon_min_m", 20.0)), far, 4.0, Callable(), _flag)
	cands.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["d"]) < float(b["d"]))
	var pick: Dictionary = {}
	for c: Dictionary in cands:
		if not _on_screen(_on_ground(c["point"])):
			pick = c
			break
	if pick.is_empty() and not cands.is_empty():
		pick = cands.back()
	if pick.is_empty():
		var p := _stop_of(station_id) + Vector2(0.0, far)
		return {"hitch": p, "heading": PI, "approach": PackedVector2Array([p, graph.nodes.get(node, _stop_of(station_id))])}
	var e: Dictionary = graph.edges[pick["edge"]]
	var pts: PackedVector2Array = e["points"]
	var cum: PackedFloat32Array = e["cum"]
	var at_start := str(e["a"]) == node
	var approach := PackedVector2Array()
	var s := float(pick["s"])
	# Doğuştan düğüme: kenarın o parçası (yön düğüme doğru).
	var step := 2.0
	if at_start:
		var k := s
		while k > 0.0:
			approach.append(RoadGraph.point_at(pts, cum, k))
			k -= step
		approach.append(pts[0])
	else:
		var k := s
		var length := float(e["length"])
		while k < length:
			approach.append(RoadGraph.point_at(pts, cum, k))
			k += step
		approach.append(pts[pts.size() - 1])
	return {"hitch": approach[0], "heading": float(pick["heading"]), "approach": approach}


func _arrive_waiting(station_id: String) -> void:
	cart_station = station_id
	travel.cart_at = station_id
	state = Cart.WAITING
	_wait_left = float(Travel.rule("cart.wait_s", 40.0))
	drive = {}
	if _attached:
		_toast(Travel.text("kantu.arrive", lang))


# --- Yol ---------------------------------------------------------------------------------------------------------------

## Arabanın zemin hızları (K105: oyuncunun en yüksek koşusu tavandır).
func _speeds() -> Dictionary:
	var cap := INF
	if bool(Travel.rule("cart.pace_cap", true)):
		cap = PaceLimit.run_cap(player) if is_instance_valid(player) else PaceLimit.ADULT_RUN
	return Travel.cart_speeds(cap)


func _cap() -> float:
	return float(_speeds().get("road", 4.6))


## Noktadaki hızın tavanı (zemin ve sınır bölgesi).
func _top_speed_at(p: Vector2) -> float:
	var near := graph.nearest_edge(p)
	var ground := "road"
	if not str(near["edge"]).is_empty() and float(near["d"]) < 8.0:
		ground = str((graph.edges[near["edge"]] as Dictionary)["ground"])
	var speeds := _speeds()
	return minf(float(speeds.get(ground, speeds.get("road", 4.6))), graph.cap_at(p, _flag))


## Arabanın şu anki yerinden durağa sürüş çizgisi (koşumun yolu): yerinden kalkış (gerekirse dingilin çevresinde dönüş), ağın yolu, durağa
## yanaşma ve dingilin durakta durması için koşum kadar uzatma. Yol yoksa boş.
func _path_to(station_id: String) -> Dictionary:
	if cart == null:
		return {}
	var to_node := str(_station(station_id).get("node", ""))
	var from_node := _nearest_node(cart.axle_xz())
	if from_node.is_empty() or to_node.is_empty():
		return {}
	var r := graph.route(from_node, to_node, _speeds(), INF, _flag)
	if not bool(r["ok"]):
		return {}
	var pts: PackedVector2Array = r["points"]
	return _finish_path(_lead_in(pts), station_id)


## Kalkışın çizgisi: koşum bugünkü yerinden yolun çizgisine katılır. Arabanın yönü yolun yönünden TURN_IN_PLACE'ten çok ayrıksa önce at
## dingilin çevresinde yay çizer (dingil yerinde kalır), sonra yola girer.
func _lead_in(route_pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	var hitch := cart.hitch
	var axle := cart.axle_xz()
	var cum := RoadGraph.cumulative(route_pts)
	var total := float(cum[cum.size() - 1]) if cum.size() > 0 else 0.0
	# Yolun koşuma en yakın yeri ve oradaki yön.
	var proj := RoadGraph.project(route_pts, cum, hitch)
	var join_s := minf(float(proj["s"]) + 10.0, total)
	var h_route := RoadGraph.heading_at(route_pts, cum, minf(float(proj["s"]), maxf(total - 0.1, 0.0)))
	var turn := angle_difference(cart.heading, h_route)
	var start_h := cart.heading
	out.append(hitch)
	if absf(turn) > TURN_IN_PLACE:
		var steps := maxi(4, ceili(absf(turn) / deg_to_rad(12.0)))
		for i in range(1, steps + 1):
			var a := cart.heading + turn * float(i) / float(steps)
			out.append(axle + CartMotion.forward(a) * RoadCart.HITCH_L)
		start_h = h_route
	# Hermite: bugünkü (ya da dönüşten sonraki) koşumdan yolun join_s noktasına.
	var p0 := out[out.size() - 1]
	var p1 := RoadGraph.point_at(route_pts, cum, join_s)
	var h1 := RoadGraph.heading_at(route_pts, cum, minf(join_s, maxf(total - 0.1, 0.0)))
	var k := p0.distance_to(p1)
	var t0 := CartMotion.forward(start_h) * k
	var t1 := CartMotion.forward(h1) * k
	for i in range(1, 9):
		var t := float(i) / 8.0
		var t2 := t * t
		var t3 := t2 * t
		out.append(p0 * (2.0 * t3 - 3.0 * t2 + 1.0) + t0 * (t3 - 2.0 * t2 + t) + p1 * (-2.0 * t3 + 3.0 * t2) + t1 * (t3 - t2))
	for i in route_pts.size():
		if cum[i] > join_s + 0.5:
			out.append(route_pts[i])
	if total > join_s + 0.01:
		var last := route_pts[route_pts.size() - 1]
		if out[out.size() - 1].distance_to(last) > 0.05:
			out.append(last)
	return out


## Çizginin sonu: durağın düğümünde biten çizgi durağın dingil noktasına yanaşır (son 12 m'de yana kayar) ve koşum kadar uzar (dingil
## durakta durur). Döner: {points, cum, length}.
func _finish_path(points: PackedVector2Array, station_id: String) -> Dictionary:
	# Köşeler yayla açılır (travel.md §3.5: en küçük yarıçap 6 m), sonra 2 m'de bir köşe.
	var pts := CartMotion.densify(CartMotion.fillet(points, 6.0), 2.0)
	if pts.size() >= 2:
		var node_p := pts[pts.size() - 1]
		var cum := RoadGraph.cumulative(pts)
		var h_end := RoadGraph.heading_at(pts, cum, float(cum[cum.size() - 1]) - 0.05)
		var side := (_stop_of(station_id) - node_p).dot(CartMotion.right(h_end))
		var along := (_stop_of(station_id) - node_p).dot(CartMotion.forward(h_end))
		pts = CartMotion.pull_over(pts, side, 12.0, true)
		# Dingilin durağı: yol boyunca kayma (along) ve koşumun önü.
		pts = CartMotion.extend(pts, maxf(RoadCart.HITCH_L + along, 0.5))
	var c := RoadGraph.cumulative(pts)
	return {"points": pts, "cum": c, "length": float(c[c.size() - 1]) if c.size() > 0 else 0.0}


func _nearest_node(p: Vector2) -> String:
	var best := ""
	var best_d := INF
	for id: String in graph.nodes:
		if not graph.adjacency.has(id):
			continue
		var d := p.distance_to(graph.nodes[id])
		if d < best_d:
			best = id
			best_d = d
	return best


func _begin_drive(path: Dictionary, purpose: String, to := "") -> void:
	drive = path.duplicate()
	drive["s"] = 0.0
	drive["speed"] = 0.0
	drive["purpose"] = purpose
	drive["to"] = to
	# Kalkışta koşum çizginin başındadır.
	if cart and not (path["points"] as PackedVector2Array).is_empty():
		var hitch_p: Vector2 = (path["points"] as PackedVector2Array)[0]
		if hitch_p.distance_to(cart.hitch) > 0.5:
			var h := RoadGraph.heading_at(path["points"], path["cum"], 0.5)
			cart.place_axle(hitch_p - CartMotion.forward(h) * RoadCart.HITCH_L, h, _ground())


## Sürüşün adımı. Döner: çizginin sonuna varıp durdu mu.
func _drive_step(delta: float, stop_now := false) -> bool:
	if drive.is_empty() or cart == null:
		return true
	var pts: PackedVector2Array = drive["points"]
	var cum: PackedFloat32Array = drive["cum"]
	var length := float(drive["length"])
	var s := float(drive["s"])
	var here := RoadGraph.point_at(pts, cum, s)
	var top := _top_speed_at(here)
	var decel := float(Travel.rule("cart.decel", 2.4))
	var goal := 0.0 if stop_now else CartMotion.target_speed(length - s, top, decel)
	var v := float(drive["speed"])
	var rate := float(Travel.rule("cart.accel", 1.4)) if goal > v else decel * (1.6 if stop_now else 1.0)
	v = move_toward(v, goal, rate * delta)
	s = minf(s + v * delta, length)
	drive["s"] = s
	drive["speed"] = v
	cart.place_hitch(RoadGraph.point_at(pts, cum, s), RoadGraph.heading_at(pts, cum, s), _ground(), v, delta)
	return (s >= length - 0.02 or stop_now) and v < 0.03


func remaining_m() -> float:
	return float(drive.get("length", 0.0)) - float(drive.get("s", 0.0)) if not drive.is_empty() else 0.0


## Kalan yolun doğal süresi (sn; saatin atlaması için): from_s'den to_s'ye 1 m adımla zemin hızı ve sınırlar.
func seconds_between(from_s: float, to_s: float) -> float:
	if drive.is_empty() or to_s <= from_s:
		return 0.0
	var pts: PackedVector2Array = drive["points"]
	var cum: PackedFloat32Array = drive["cum"]
	var total := 0.0
	var s := from_s
	while s < to_s:
		var ds := minf(1.0, to_s - s)
		total += ds / maxf(_top_speed_at(RoadGraph.point_at(pts, cum, s + ds * 0.5)), 0.05)
		s += ds
	return total


## Yakve tektir (travel.md §3.7): araba seferdeyken (park durağında değilken) ahırdaki Yakve görünmez ve binilmez. cart.stable_horse
## bineğin anahtarıdır (yakwe@Yakwe); oyuncu sırtındaysa dokunulmaz.
func _sync_stable_horse() -> void:
	var key := str((def.get("cart", {}) as Dictionary).get("stable_horse", ""))
	if key.is_empty() or world == null:
		return
	if _stable_horse == null or not is_instance_valid(_stable_horse):
		_stable_horse = null
		for node in world.find_children("*", "RideableHorse", true, false):
			if (node as Rideable).mount_key() == key:
				_stable_horse = node
				break
		if _stable_horse == null:
			return
	if _stable_horse.ridden:
		return
	var park := str((def.get("cart", {}) as Dictionary).get("park", ""))
	var home := state == Cart.PARKED and cart_station == park
	if _stable_horse.visible != home:
		_stable_horse.visible = home
		if home and not _stable_horse.is_in_group(Rideable.GROUP):
			_stable_horse.add_to_group(Rideable.GROUP)
		elif not home and _stable_horse.is_in_group(Rideable.GROUP):
			_stable_horse.remove_from_group(Rideable.GROUP)


## Sürücü Kantu arabada görünür mü: araba iş başındayken hep (kişileri kuran katman o sürede Kantu'yu gizler: travel.on_duty); dururken
## kişi programı Kantu'yu biliyorsa (Schedule «kantu», oturumun 7. sistemi) programın işine göre: «cart» işinde (10:30–13:23, Kantu'nun
## çevrimi; act1.md §5, travel.md §5.2) kişi arabadadır, program onu gizler, araba durakta dururken sürücü yerinde görünür; öteki işlerde
## (Menzil'de durur, gece barınağında) program yürütür, arabada görünmez: iki Kantu olmasın. Program yoksa (deneme haritası) uyumuyorsa görünür.
func _driver_shown() -> bool:
	if state != Cart.PARKED:
		return true
	var id := str((def.get("cart", {}) as Dictionary).get("driver", "kantu"))
	var sched: Schedule = null
	if session and is_instance_valid(session):
		sched = session.get_system(&"schedule") as Schedule
	if sched and sched.people.has(id):
		return str(sched.state_of(id).get("job", "")) == "cart"
	return not Travel.kantu_asleep(_minute())


func _step_cart(delta: float) -> void:
	if cart == null:
		return
	_sync_stable_horse()
	travel.on_duty = state != Cart.PARKED
	if is_instance_valid(cart.driver):
		cart.set_driver_visible(_driver_shown())
	match state:
		Cart.PARKED, Cart.CARD:
			cart.idle(delta)
			if state == Cart.CARD:
				_place_seated()
		Cart.CALLED:
			if _drive_step(delta):
				var to := str(drive.get("to", ""))
				_arrive_waiting(to if not to.is_empty() else _nearest_station(cart.axle_xz()))
		Cart.WAITING:
			cart.idle(delta)
			_wait_left -= delta
			var far := _attached and _xz().distance_to(cart.axle_xz()) > float(Travel.rule("cart.leave_m", 60.0))
			if _wait_left <= 0.0 or far:
				if _attached and not far:
					_toast(Travel.text("kantu.leave", lang))
				_leave()
		Cart.BOARDING, Cart.ALIGHT:
			cart.idle(delta)
			_seat_step(delta)
		Cart.CRUISE:
			_drive_step(delta)
			_place_seated()
			if remaining_m() <= float(Travel.rule("cart.arrive_m", 18.0)):
				state = Cart.ARRIVE
		Cart.SKIP:
			_drive_step(delta)
			_place_seated()
			_skip_step(delta)
		Cart.ARRIVE:
			var done := _drive_step(delta)
			_place_seated()
			if done:
				_begin_alight()
		Cart.STOPPING:
			var stopped := _drive_step(delta, true)
			_place_seated()
			if stopped:
				_begin_alight()
		Cart.LEAVING:
			var arrived := _drive_step(delta)
			var gone := not _cart_on_screen() and (not _attached or _xz().distance_to(cart.axle_xz()) > VANISH_M)
			if arrived or gone:
				_park_at(str((def.get("cart", {}) as Dictionary).get("park", cart_station)))


func _nearest_station(p: Vector2) -> String:
	var best := ""
	var best_d := INF
	for id: String in travel.defs:
		var d := p.distance_to(_stop_of(id))
		if d < best_d:
			best = id
			best_d = d
	return best


## Arabayı durağa koyar (görünmeden; park): dingil durağın noktasında, yön düğümden çıkan ilk kenar boyunca.
func _park_at(station_id: String) -> void:
	if cart == null or not travel.defs.has(station_id):
		return
	var node := str(_station(station_id).get("node", ""))
	var h := 0.0
	var edges: Array = graph.adjacency.get(node, [])
	if not edges.is_empty():
		var e: Dictionary = graph.edges[edges[0]]
		var pts: PackedVector2Array = e["points"]
		var cum: PackedFloat32Array = e["cum"]
		h = RoadGraph.heading_at(pts, cum, 0.5) if str(e["a"]) == node else RoadGraph.heading_at(pts, cum, float(e["length"]) - 0.5) + PI
	var face: Variant = _station(station_id).get("cart_heading")
	if face is float or face is int:
		h = deg_to_rad(float(face))
	cart.place_axle(_stop_of(station_id), wrapf(h, -PI, PI), _ground())
	cart_station = station_id
	travel.cart_at = station_id
	state = Cart.PARKED
	drive = {}


## Bekleme bitti: araba park durağına döner (yolda kadraj dışına çıkınca yerine konur); yeni çağrı recall_s sonra. Park durağında duruyorsa
## yerinde kalır.
func _leave() -> void:
	_recall_at = _time + float(Travel.rule("cart.recall_s", 30.0))
	var park := str((def.get("cart", {}) as Dictionary).get("park", ""))
	if park.is_empty() or (park == cart_station and cart.axle_xz().distance_to(_stop_of(park)) < 2.0):
		state = Cart.PARKED
		drive = {}
		return
	var path := _path_to(park)
	if path.is_empty():
		_park_at(park)
		return
	_begin_drive(path, "leave", park)
	state = Cart.LEAVING


func _on_screen(p: Vector3) -> bool:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam == null:
		return false
	return cam.is_position_in_frustum(p) or cam.is_position_in_frustum(p + Vector3(0.0, 2.3, 0.0))


func _cart_on_screen() -> bool:
	if cart == null or not cart.visible:
		return false
	var a := cart.global_position
	return _on_screen(a) or _on_screen(Vector3(cart.hitch.x, a.y, cart.hitch.y))


# --- Biniş, sefer, iniş ------------------------------------------------------------------------------------------------

## Arabaya biner (0,62 sn; travel.md §6.1 BOARD): oyuncu taşınan oturuşa geçer (CartSeat), Yol Kartı açılır.
func board() -> bool:
	if cart == null or state != Cart.WAITING or not is_instance_valid(player):
		return false
	seat = CartSeat.new(player, cart, "S1", _ground())
	if not seat.begin_board(float(Travel.rule("cart.board_s", 0.62))):
		return false
	state = Cart.BOARDING
	if camera:
		camera.apply_preset(CameraPreset.make(&"cart", CART_PITCH, CART_DISTANCE, "start"))
	return true


func _place_seated() -> void:
	if seat and seat.is_seated():
		seat.place()


func _seat_step(delta: float) -> void:
	if seat == null:
		return
	var was := seat.phase
	seat.step(delta)
	if was == "up" and seat.is_seated():
		_open_card()
	elif was == "down" and seat.phase == "":
		_finish_alight(false)


func _open_card() -> void:
	state = Cart.CARD
	_close_card()
	_card_layer = CanvasLayer.new()
	_card_layer.name = "RoadCardLayer"
	_card_layer.layer = 40
	add_child(_card_layer)
	_card = RoadCard.new()
	_card.setup(card_rows(), station_name(cart_station), lang)
	var inv := _inv()
	if inv:
		_card.cargo = inv.cart.load10() / 10.0
		_card.cargo_cap = inv.cart.cap10() / 10.0
	_card.chosen.connect(_on_card_chosen)
	_card.closed.connect(_on_card_closed)
	_card_layer.add_child(_card)
	_hold_clock(true)


func _close_card() -> void:
	if is_instance_valid(_card_layer):
		_card_layer.queue_free()
	_card_layer = null
	_card = null
	_hold_clock(false)


## Yol Kartı açıkken saat durur, dünya kıpırdar (modal; WaitWheel gibi Session.set_pause, sahibi road_card).
func _hold_clock(on: bool) -> void:
	if session and is_instance_valid(session):
		session.set_pause(&"modal", on, &"road_card")


## Yol Kartı'nın satırları: tanımlı duraklar (bulunduysa), bağlılar süreye göre; kapalılar nedeniyle.
func card_rows() -> Array:
	var rows: Array = []
	var fare := Travel.text("fare.free", lang) if travel.fare_free(_flag) else Travel.text("fare.pay", lang, {"n": 1, "mal": _fare_name(), "item": _fare_name()})
	for id: String in travel.defs:
		if id == cart_station:
			continue
		var st := travel.state_of(id)
		if st == "hidden":
			continue
		var row := {"id": id, "name": station_name(id), "state": st, "enabled": false, "meters": 0.0, "seconds": 0.0, "fare": fare, "reason": ""}
		var r := graph.route(str(_station(cart_station).get("node", "")), str(_station(id).get("node", "")), _speeds(), INF, _flag)
		if bool(r["ok"]):
			row["meters"] = float(r["length"])
			row["seconds"] = float(r["seconds"])
		if st != "linked":
			row["reason"] = Travel.text("station.rumoured" if st == "rumoured" else "station.found", lang)
		elif not bool(r["ok"]):
			row["reason"] = str(Travel.allowed({"route_closed": true}, lang)["text"])
		else:
			var lock := Travel.allowed(lock_context(id, true), lang)
			row["enabled"] = bool(lock["ok"])
			row["reason"] = str(lock["text"])
		rows.append(row)
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if bool(a["enabled"]) != bool(b["enabled"]):
			return bool(a["enabled"])
		return float(a["seconds"]) < float(b["seconds"]))
	return rows


func _fare_name() -> String:
	var item := Travel.fare_item(_inv())
	if item.is_empty():
		item = "meal"
	if item.begins_with("tag:"):
		return "odun" if lang != "en" else "log"
	return ItemCatalog.name_of(item, lang)


func _on_card_chosen(id: String, mode: String) -> void:
	if mode == "cargo":
		_open_cargo()
		return
	depart(id, mode)


func _on_card_closed() -> void:
	_close_card()
	_begin_alight()


## Yük Bindir (travel.md §7.1): heybeden araba kabına (40 Yük) Envanter'in aktarma sekmesinde; kapanınca kart döner.
func _open_cargo() -> void:
	var inv := _inv()
	if inv == null or hud == null:
		return
	_close_card()
	_cargo_open = true
	var title := "ARABA · KANTU" if lang != "en" else "CART · KANTU"
	if not hud.screen_closed.is_connected(_on_cargo_closed):
		hud.screen_closed.connect(_on_cargo_closed, CONNECT_ONE_SHOT)
	if not hud.open_container(inv.cart, title):
		_cargo_open = false
		_open_card()


func _on_cargo_closed(_kind: String) -> void:
	_cargo_open = false
	if state == Cart.CARD and is_instance_valid(player) and player.carried:
		_open_card()


## Kalkış (travel.md §6.1 DEPART): kilit, kayıt (ücretten önce; ride yazılır), ücret, sürüş. mode: watch | shorten. Döner: kalktı mı.
func depart(to: String, mode := "watch") -> bool:
	if state != Cart.CARD or not travel.is_linked(to) or to == cart_station:
		return false
	var lock := Travel.allowed(lock_context(to, true), lang)
	if not bool(lock["ok"]):
		_toast(str(lock["text"]) if str(lock["code"]) != "no_fare" else Travel.text("kantu.nofare", lang), "warn")
		MenuStyle.play_ui(self, &"deny")
		return false
	var path := _path_to(to)
	if path.is_empty():
		return false
	trip = {"from": cart_station, "to": to, "mode": mode}
	travel.ride = trip.duplicate()
	if session:
		session.request_autosave(&"depart")
		session.block_autosave(&"travel", true)
	var paid := travel.pay_fare(_inv(), _flag)
	_toast(Travel.text("fare.free", lang) if bool(paid["free"]) else Travel.text("fare.pay", lang, {"n": 1, "mal": _fare_name(), "item": _fare_name()}))
	_close_card()
	_begin_drive(path, "trip", to)
	state = Cart.CRUISE
	if mode == "shorten":
		_skip = {"t": 0.0, "auto": true}
		state = Cart.SKIP
	return true


## Yolda inme (travel.md §6.1): araba 1,5 sn'de durur, yola inilir, ücret dönmez, araba Menzil'e döner.
func _get_off() -> void:
	if state != Cart.CRUISE:
		return
	_e = {}
	hud.show_hold("", 0.0)
	state = Cart.STOPPING


# --- Yolu Kısalt (travel.md §6.5) --------------------------------------------------------------------------------------

func _skip_step(delta: float) -> void:
	var hold_s := float(Travel.rule("cart.skip.hold_s", 3.0))
	var open_s := float(Travel.rule("cart.skip.open_s", 0.6))
	if not _skip.has("done"):
		_skip["t"] = float(_skip["t"]) + delta
		_set_fade(clampf(float(_skip["t"]) / hold_s, 0.0, 1.0))
		if float(_skip["t"]) >= hold_s:
			_do_skip()
			_skip["done"] = true
			_skip["open"] = 0.0
		return
	_skip["open"] = float(_skip["open"]) + delta
	_set_fade(1.0 - clampf(float(_skip["open"]) / open_s, 0.0, 1.0))
	if float(_skip["open"]) >= open_s:
		_skip = {}
		_set_fade(0.0)
		state = Cart.ARRIVE


## Karartmada: araba hedefe arrive_m kalaya yolun üstünde taşınır (görünmeden), saat kalan doğal süre kadar atlar (travel.md §6.8).
func _do_skip() -> void:
	if drive.is_empty():
		return
	var length := float(drive["length"])
	var target := maxf(float(drive["s"]), length - float(Travel.rule("cart.arrive_m", 18.0)))
	var secs := seconds_between(float(drive["s"]), target)
	if session and session.clock and secs > 0.0:
		session.clock.skip(Travel.clock_minutes(secs), &"travel")
	last_skip = {"from_m": float(drive["s"]), "to_m": target, "seconds": secs, "minutes": Travel.clock_minutes(secs), "left_m": length - target}
	drive["s"] = target
	var pts: PackedVector2Array = drive["points"]
	var cum: PackedFloat32Array = drive["cum"]
	var hitch := RoadGraph.point_at(pts, cum, target)
	var h := RoadGraph.heading_at(pts, cum, maxf(target - RoadCart.HITCH_L * 0.5, 0.0))
	cart.place_axle(hitch - CartMotion.forward(h) * RoadCart.HITCH_L, h, _ground())
	cart.hitch = hitch
	drive["speed"] = minf(float(drive["speed"]), _top_speed_at(hitch))


func _fade_back() -> void:
	var fade: Variant = main.get("fade") if main and is_instance_valid(main) else null
	if fade is ColorRect and (fade as ColorRect).color.a > 0.0:
		var tw := create_tween()
		tw.tween_property(fade, "color:a", 0.0, 0.25)


func _set_fade(a: float) -> void:
	var fade: Variant = main.get("fade") if main and is_instance_valid(main) else null
	if fade is ColorRect:
		(fade as ColorRect).color.a = a


# --- İniş --------------------------------------------------------------------------------------------------------------

## İniş (0,56 sn; travel.md §6.1 ALIGHT): oturaktan arabanın arkasına, geriye bakarak.
func _begin_alight() -> void:
	if seat == null or not is_instance_valid(player) or not player.carried:
		return
	_close_card()
	seat.begin_alight(float(Travel.rule("cart.alight_s", 0.56)))
	state = Cart.ALIGHT


## İnişin sonu: oyuncu yerde, denetim açılır (CartSeat.finish); sefer kaydı kapanır (iniş durağı, yük teslimi, oto kayıt «alight»), araba
## bekler ya da döner. instant: geçişsiz (katman bırakılıyor).
func _finish_alight(instant: bool) -> void:
	if seat and seat.phase != "":
		seat.finish()
	seat = null
	if camera:
		camera.clear_preset()
	if is_instance_valid(hud):
		hud.show_hold("", 0.0)
	_set_fade(0.0)
	var had_trip := not trip.is_empty()
	var arrived := had_trip and remaining_m() < 1.0
	if arrived:
		travel.last_stop = str(trip["to"])
		cart_station = str(trip["to"])
		travel.cart_at = cart_station
		_deliver_cargo(cart_station)
	travel.ride = null
	trip = {}
	drive = {}
	if session and is_instance_valid(session):
		session.block_autosave(&"travel", false)
		if not instant:
			session.request_autosave(&"alight")
	if instant:
		_park_at(cart_station if travel.defs.has(cart_station) else str((def.get("cart", {}) as Dictionary).get("park", "")))
		return
	if arrived or not had_trip:
		# Varışta ya da kalkmadan inince araba durakta bekler.
		state = Cart.WAITING
		_wait_left = float(Travel.rule("cart.wait_s", 40.0))
	else:
		# Yolda inildi: araba bir durakta değildir, Menzil'e döner (travel.md §6.1 «Hedefsiz kalan araba way_camp'a döner»).
		cart_station = ""
		_leave()


## Varış durağı Ambar durağıysa (deliver) yük teslim edilir (envanterin «stores» kabı varsa oraya, yoksa durağın Menzil Ambarı'na).
func _deliver_cargo(station_id: String) -> void:
	var inv := _inv()
	if inv == null or inv.cart.list().is_empty():
		return
	var target := str(_station(station_id).get("deliver", ""))
	if target.is_empty():
		return
	var dest: Variant = inv.store(target)
	var into: ItemContainer = dest if dest is ItemContainer else inv.stash(station_id)
	var moved := inv.move_all(inv.cart, into)
	var parts := PackedStringArray()
	for it: Dictionary in moved.get("moved", []):
		parts.append("%s × %d" % [ItemCatalog.name_of(str(it["id"]), lang), int(it["n"])])
	if parts.is_empty():
		return
	_toast(Travel.text("cargo.delivered" if dest is ItemContainer else "cargo.stashed", lang, {"liste": ", ".join(parts), "list": ", ".join(parts)}))
	if session:
		session.event.emit(&"travel_delivered", {"station": station_id, "items": moved.get("moved", [])})


## Menzil Ambarı (economy.stash[id]): Envanter'in aktarma sekmesinde.
func open_stash(station_id: String) -> bool:
	var inv := _inv()
	if inv == null or hud == null or not travel.is_linked(station_id):
		return false
	return hud.open_container(inv.stash(station_id), "%s · %s" % [Travel.text("post.stash", lang).to_upper(), station_name(station_id).to_upper()])


# --- Geliştirme --------------------------------------------------------------------------------------------------------

## --travel=link,call,board,ride:<durak>,shorten:<durak>,wait:<sn>: sırayla.
func _run_dev() -> void:
	for step in _dev:
		var parts := step.split(":")
		match parts[0]:
			"link":
				for id: String in travel.defs:
					travel.set_station(id, "linked", true)
				for b: String in travel.bone_defs:
					travel.bones[b] = 0.0
				_refresh_bones()
			"call":
				var at := _nearest_station(_xz())
				_park_at(at)
				_arrive_waiting(at)
			"board":
				var near := _nearest_station(_xz())
				_park_at(near)
				_arrive_waiting(near)
				var t := cart.tail_point("S1", _ground())
				player.spawn_at(t, cart.heading + PI)
				await get_tree().process_frame
				board()
				while state != Cart.CARD:
					await get_tree().process_frame
			"ride", "shorten":
				while state != Cart.CARD:
					await get_tree().process_frame
				depart(parts[1] if parts.size() > 1 else "", "shorten" if parts[0] == "shorten" else "watch")
			"wait":
				await get_tree().create_timer(float(parts[1]) if parts.size() > 1 else 1.0).timeout
