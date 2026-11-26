class_name FaunaLayer
extends Node3D
## İç haritanın hayvan katmanı (map.json «layers» → data/maps/<harita>/fauna.json; MapLayers kurar; Yol Haritası animals, fauna-first-species,
## fauna-sound-bank; fauna.md §10, survival.md §4.9; K3, K65, K89, K98). Kışlak'ta: Ak Otlak'ın 60 atı ve 200 koyunu (PastureFlock + HerdField),
## çevrenin develeri ve sığırları; köpek, tilki, ceylan, yaban keçisi, yaban domuzu, maral ve kurt (FaunaDirector'un ajanları; kurtlar gece Kurt
## İnleri'nde); tavşan, karga ve keklik (SmallGameField: kodla çizilir, sapan ve oyuncak yayın hedefi); gökte kartal (SkyEagle; yalnız gölge ve ses);
## hayvan sesleri (FaunaVoices). FaunaDirector 4 Hz'de döner: oturum varsa onun 8. adımında (Session «fauna»), yoksa bu düğümün karesinde.
## Bütçe (K65): hayvan ajanı ≤24 (tavşanlar dahil), T0 ≤8 (iskeletli, en yakın ya da ekranda en büyük), kuş ≤64. Kademe ekran pikseliyle
## seçilir: T0 ≥80 px ya da boş T0 yuvası varken ≥40 px; geri kalan AgentCrowd'un T1'idir (fauna.md §10).
## Ateşler (Ulu Ocak 12 m, ocaklar ve nöbet ateşleri 8 m) ve yerleşim (winter_camp bölgesi) haritanın kayıtlarından okunur: yırtıcı ve yaban
## hayvanı girmez (K3, K65).
## Geliştirme ve kare (kayıt yazılmaz): --fauna=dawn|noon|dusk|night (yönetmenin saatini bu evreye kurar, oturumun saatine dokunmaz),
## --fauna-near=<grup>[:<m>] (grubu --at'in o kadar kuzeyine taşır; 24 m), --fauna-calm (algı ×0,25: hayvan kareden kaçmaz),
## --fauna-lineup (her türden bir hayvan --at'in kuzeyinde bir sırada, evreden bağımsız; silüet ve tür karesi).

const PROCESS_PRIORITY := 2
## Kademe eşikleri (ekran pikseli; sanat-animasyon.md §5): T0 ≥80, T1 ≥40; T0'dan düşüş 32'nin altında (histerezis).
const T0_PX := 80.0
const T1_PX := 40.0
const T0_KEEP_PX := 32.0
## Ateşlerin yarıçapı (m; fauna.md §6: orta evrede 8, büyükte 12).
const FIRE_GREAT := 12.0
const FIRE_SMALL := 8.0
## Yerleşimin yasak dairesine bölgenin yarıçapına eklenen pay (m).
const CAMP_MARGIN := 15.0
## Küçük av hayvanları kare başına bu kadar eklenir (kurulumun kare bütçesi).
const ADD_PER_FRAME := 8

var world: Node3D
var def: Dictionary = {}
var director: FaunaDirector
var herds: Array[HerdField] = []
var crowds: Dictionary = {}
var game: SmallGameField
var skies: Array[SkyEagle] = []
var voices: FaunaVoices
var ground: TerrainShape

var main: Node
var player: Node3D
var session: Session

var _t0: Dictionary = {}
var _scenes: Dictionary = {}
var _requests: Dictionary = {}
var _local_clock: GameClock
var _stepped := false
var _seen_clock := -1.0
var _phase_key := ""
var _dev: Dictionary = {}
var _pending_small := true
var _last_minute := -1.0


## MapLayers çağırır (ağaca eklemeden önce): harita ve katmanın sözlüğü.
func setup(p_world: Node3D, p_def: Dictionary) -> void:
	world = p_world
	def = p_def


func _ready() -> void:
	process_priority = PROCESS_PRIORITY
	ground = _ground_of(world)
	_dev = _dev_args()
	director = FaunaDirector.new()
	# Oturum (saat) kurulumda okunur: sürüler saatin yerinde doğar (gece ağılda, gündüz otlakta).
	_resolve_main()
	var d := def.duplicate(true)
	if _dev.has("lineup"):
		d["groups"] = (d.get("groups", []) as Array) + _lineup_groups()
	if not d.has("camp"):
		d["camp"] = _camp_from_map()
	if not d.has("bounds"):
		var b := _bounds_from_map()
		if not b.is_empty():
			d["bounds"] = b
	director.setup(d)
	director.fires.append_array(_fires_from_map())
	if world and world.has_method(&"collect_obstacles"):
		director.obstacles = world.call(&"collect_obstacles")
	_build_flocks()
	_build_crowds()
	_build_small_game()
	_build_skies()
	voices = FaunaVoices.new()
	voices.setup(def.get("voices", []), director, ground)
	voices.game_field = game
	voices.skies = skies
	add_child(voices)
	for sky in skies:
		sky.called.connect(func(at: Vector3) -> void: voices.play("eagle", &"call", at))
	_apply_dev_near()
	if _dev.has("calm"):
		director.share_k = 0.25
	_bind_player()


func _exit_tree() -> void:
	_detach()
	# Süren arka plan yüklemesi de beklenip alınır (HerdField gibi): yükleyicide öksüz kalırsa çıkışta sızar.
	for path: String in _requests.keys():
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS or status == ResourceLoader.THREAD_LOAD_LOADED:
			ResourceLoader.load_threaded_get(path)
	_requests.clear()
	FaunaBank.shared().release()


func _process(delta: float) -> void:
	_resolve_main()
	if _pending_small and game:
		_pending_small = game.add_pending(ADD_PER_FRAME)
	_feed_inputs()
	_check_skip()
	if not _stepped:
		director.step(delta)
	if director.clock != _seen_clock:
		_seen_clock = director.clock
		_after_tick()
	_poll_scenes()
	_assign_tiers()


# --- Oturum ve girdiler ----------------------------------------------------------------------------------------

## Saatin atlaması (Bekle, Uyu, sinema; ≥30 oyun dk): sürüler yeni saatin yerine anında konur, yürüyerek gitmez.
func _check_skip() -> void:
	var m := director.minute
	if _last_minute >= 0.0:
		var jump := fposmod(m - _last_minute, 1440.0)
		if jump > 30.0 and jump < 1410.0:
			for h in herds:
				h.flock.set_time(m)
				h.flock.place_now()
				h.snap()
	_last_minute = m


func _resolve_main() -> void:
	if main and is_instance_valid(main):
		return
	main = _find_main()
	if main == null:
		return
	var p: Variant = main.get("player")
	player = p if p is Node3D else null
	var s: Variant = main.get("session")
	session = s if s is Session and is_instance_valid(s) else null
	if session and not _stepped and session.add_system(&"fauna", Callable(self, &"_session_step"), &"fauna"):
		_stepped = true
	_bind_player()


## Oyuncu küçük avın tehdidi ve hayvan seslerinin dinleyicisidir.
func _bind_player() -> void:
	if game and player:
		game.set_threat(player)
	if voices:
		voices.listener = player
	# Geliştirme dizisinin karesi: takip kamerası K98 bandının yakın ucunda (16 m).
	if _dev.has("lineup") and main and is_instance_valid(main):
		var cam: Variant = main.get("follow_camera") if "follow_camera" in main else null
		if cam is Object and (cam as Object).has_method(&"set_start_distance"):
			(cam as Object).call(&"set_start_distance", 16.0)


func _detach() -> void:
	if _stepped and session and is_instance_valid(session):
		session.remove_system(&"fauna")
	_stepped = false


## Oturumun 8. adımı (Session «fauna»): girdiler, 4 Hz tik.
func _session_step(dt: float) -> void:
	_feed_inputs()
	director.step(dt)


func _feed_inputs() -> void:
	if player and is_instance_valid(player) and player.is_inside_tree():
		var p := player.global_position
		var v: Vector3 = player.get("velocity") if "velocity" in player else Vector3.ZERO
		var spd := Vector2(v.x, v.z).length()
		var riding := player.has_method(&"is_riding") and bool(player.call(&"is_riding"))
		var noise := FaunaDirector.NOISE_RIDE if riding else (FaunaDirector.NOISE_STILL if spd < 0.3 else (FaunaDirector.NOISE_WALK if spd < 3.5 else FaunaDirector.NOISE_RUN))
		director.set_player(Vector2(p.x, p.z), Vector2(v.x, v.z), noise)
	var clock := _clock()
	var phase := clock.phase() if clock else &""
	var minute := clock.minute if clock else 720.0
	if _dev.has("phase"):
		minute = float(_dev["minute"])
		phase = FaunaDirector.phase_of(minute)
	director.set_time(phase, minute, clock.day_n if clock else 1041)
	_feed_weather()
	if voices:
		voices.minute = director.minute
		voices.phase = director.phase


## Havanın görüşü ve rüzgârı (oturumun hava adımında WeatherSim varsa); yoksa Kışlak'ın kış rüzgârı (3 m/sn, kuzeybatıdan).
func _feed_weather() -> void:
	var sim := _weather_sim()
	if sim and sim.fx:
		director.set_weather(sim.fx.vis, sim.fx.wind, Vector2(sim.fx.dir_x, sim.fx.dir_z))
	else:
		director.set_weather(INF, 3.0, Vector2(0.6, 0.8))


func _weather_sim() -> WeatherSim:
	if session == null:
		return null
	for id: StringName in [&"weather", &"map_weather", &"kislak_weather"]:
		var s: Variant = session.get_system(id)
		if s is WeatherSim:
			return s
		if s is Object and "sim" in (s as Object) and (s as Object).get("sim") is WeatherSim:
			return (s as Object).get("sim")
		if s is Callable and (s as Callable).get_object() and "sim" in (s as Callable).get_object():
			var o: Variant = (s as Callable).get_object().get("sim")
			if o is WeatherSim:
				return o
	return null


func _clock() -> GameClock:
	if session and session.clock:
		return session.clock
	if _local_clock == null:
		# Oturum yoksa (geliştirme) saat yalnız bu ziyaret için: kayda girmez (K67).
		_local_clock = GameClock.new(1041, 720.0)
	return _local_clock


# --- Tik sonrası: sesler, küçük av ve kartalın evresi -----------------------------------------------------------------

func _after_tick() -> void:
	voices.on_events(director.events)
	for ev: Dictionary in director.events:
		if ev.get("type") == &"spawn":
			var g := director.group(str(ev["group"]))
			if g:
				_request_scene(g.kind)
	var key := "%d/%s" % [director.day, director.phase]
	if key != _phase_key:
		_phase_key = key
		_apply_presence()


## Küçük avın ve kartalın evresi (survival.md §4.3: ağırlık / 3 olasılık; tohumlu, gün ve evre başına).
func _apply_presence() -> void:
	if game:
		var k := 0
		for a in game.animals():
			if a.kind == null:
				continue
			var rng := RandomNumberGenerator.new()
			rng.seed = hash([k, director.day, String(director.phase)])
			var here := FaunaDirector.is_present(a.kind, director.phase, rng.randf())
			# Yalnız yerde duran ya da yürüyen hayvan kaybolur ya da belirir; uçan, koşan, saklanan, düşen ve alınan dokunulmaz.
			if a.state == SmallGame.State.FORAGE or a.state == SmallGame.State.WALK:
				a.visible = here
			k += 1
	var eagle := FaunaKind.named("eagle")
	for sky in skies:
		sky.flying = eagle == null or eagle.activity(director.phase) > 0


# --- Kademe: T0 (Animal) ve T1 (AgentCrowd) -------------------------------------------------------------------

func _assign_tiers() -> void:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	var want: Array = []
	for i in director.active_agents():
		var kind := director.kinds[i]
		if kind == null or not _has_t0(kind):
			continue
		var px := _pixels(i, kind, cam)
		var keep := _t0.has(i) and px >= T0_KEEP_PX
		if px >= T1_PX or keep:
			want.append([px + (1000.0 if px >= T0_PX or keep else 0.0), i])
	want.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var chosen := {}
	for row: Array in want:
		if chosen.size() >= FaunaDirector.MAX_T0:
			break
		chosen[int(row[1])] = true
	# Bırakılanlar.
	for i: int in _t0.keys():
		var a: Animal = _t0[i]
		if not chosen.has(i) or not is_instance_valid(a) or not a._alive():
			if is_instance_valid(a):
				a.queue_free()
			_t0.erase(i)
			var c: AgentCrowd = crowds.get(director.agent_kind(i))
			if c:
				c.hide_slot(i, false)
	# Yükselenler (karede en çok iki: örnekleme kareyi kesmesin).
	var made := 0
	for i: int in chosen:
		if _t0.has(i) or made >= 2:
			continue
		var kind := director.kinds[i]
		var scene: PackedScene = _scenes.get(kind.id)
		var a := Animal.new()
		a.bind(director, i, scene, ground)
		add_child(a)
		_t0[i] = a
		var c: AgentCrowd = crowds.get(kind.id)
		if c:
			c.hide_slot(i, true)
		made += 1
	# Boşalan yuvaların gizleme bayrağı temizlenir.
	for kid: String in crowds:
		var crowd: AgentCrowd = crowds[kid]
		for i in FaunaDirector.MAX_AGENTS:
			if not _t0.has(i):
				crowd.hide_slot(i, false)


## Ajanın ekrandaki boyu (piksel): boy × ekranın yüksekliği / (2 × uzaklık × tan(görüş / 2)). Kamera yoksa oyuncunun 28 m arkası.
func _pixels(i: int, kind: FaunaKind, cam: Camera3D) -> float:
	var p := director.pos[i]
	var y := ground.height_at(p.x, p.y) if ground else 0.0
	var at := Vector3(p.x, y, p.y)
	var height := maxf(kind.shoulder, kind.length * 0.5) * kind.model_scale() * 1.35
	var d := 28.0
	var fov := 36.0
	var vh := 1080.0
	if cam:
		d = maxf(cam.global_position.distance_to(at), 1.0)
		fov = cam.fov
		vh = float(get_viewport().get_visible_rect().size.y)
	elif player and is_instance_valid(player):
		d = player.global_position.distance_to(at) + 28.0
	return height * vh / (2.0 * d * tan(deg_to_rad(fov) * 0.5))


func _has_t0(kind: FaunaKind) -> bool:
	return _scenes.has(kind.id) or not kind.drawn().is_empty()


func t0_count() -> int:
	return _t0.size()


func t0_nodes() -> Array:
	return _t0.values()


func bird_count() -> int:
	var n := 0
	if game:
		for a in game.animals():
			if a.kind and a.kind.is_bird():
				n += 1
	for sky in skies:
		n += sky.bird_count()
	return n


func small_mammals() -> int:
	var n := 0
	if game:
		for a in game.animals():
			if a.kind and not a.kind.is_bird():
				n += 1
	return n


# --- Kurulum ------------------------------------------------------------------------------------------------------

func _build_flocks() -> void:
	for f: Variant in def.get("flocks", []):
		if not f is Dictionary:
			continue
		var flock := director.flock(str((f as Dictionary).get("id", "")))
		if flock == null:
			continue
		flock.obstacles = director.obstacles
		# Çitli ağıl (fauna.json «pen»: haritanın yapı kaydı; StructureKit.pen_area) ve sürünün yolundaki kutular (çit, duvar): koyun çitten
		# geçmez, kapıdan girer.
		_bind_pen(flock, str((f as Dictionary).get("pen", "")))
		flock.set_time(_clock().minute if _clock() else 720.0)
		flock.place_now()
		var herd := HerdField.new()
		herd.name = "Herd_%s" % str((f as Dictionary).get("id", flock.kind_id)).to_pascal_case()
		herd.process_priority = PROCESS_PRIORITY + 1
		herd.write_range = float((f as Dictionary).get("write_range", 320.0))
		var young: Array = (f as Dictionary).get("young", [HerdField.LAMB_SHARE, HerdField.LAMB_RANGE.x, HerdField.LAMB_RANGE.y])
		var drawn := FaunaKind.named(flock.kind_id).drawn() if FaunaKind.named(flock.kind_id) else ""
		herd.setup_flock(flock, ground, float(young[0]), Vector2(float(young[1]), float(young[2])), FaunaMesh.arrays(drawn) if not drawn.is_empty() else {})
		add_child(herd)
		herds.append(herd)


## Sürünün çitli ağılı (haritanın yapı kaydı) ve çarpıştığı kutular: otlağın ve ağılın çevresindeki yapı kutuları (MapWorld.collect_boxes).
func _bind_pen(flock: PastureFlock, pen_id: String) -> void:
	var spec: MapSpec = world.get(&"spec") as MapSpec if world else null
	if spec and not pen_id.is_empty():
		var rec := spec.structure(pen_id)
		if not rec.is_empty():
			flock.set_pen(StructureKit.pen_area(rec))
	if world == null or not world.has_method(&"collect_boxes"):
		return
	var near: Array[ObstacleBox] = []
	for b: ObstacleBox in world.call(&"collect_boxes"):
		var reach := maxf(b.half.x, b.half.y)
		if b.center.distance_to(flock.home) <= flock.home_radius + 60.0 + reach \
				or (flock.fold.is_finite() and b.center.distance_to(flock.fold) <= flock.fold_radius + 40.0 + reach):
			near.append(b)
	flock.boxes = near


func _build_crowds() -> void:
	for g in director.groups:
		if crowds.has(g.kind.id):
			continue
		var c := AgentCrowd.new()
		c.setup(director, g.kind, ground)
		c.process_priority = PROCESS_PRIORITY + 1
		add_child(c)
		crowds[g.kind.id] = c


func _build_small_game() -> void:
	var sg: Variant = def.get("small_game")
	if not sg is Dictionary or ((sg as Dictionary).get("groups", []) as Array).is_empty():
		return
	game = SmallGameField.new()
	game.name = "SmallGame"
	game.auto_add = false
	game.setup(sg, ground)
	add_child(game)
	game.target_fell.connect(func(_t: SmallGame) -> void: pass)
	for a in game.animals():
		a.alarmed.connect(_on_small_alarmed)
	# Bütçe: tavşan ajandır (≤24), kuş sayılır (≤64; K65).
	director.agent_cap = maxi(FaunaDirector.MAX_AGENTS - small_mammals(), 0)
	director.birds = bird_count()
	if bird_count() > FaunaDirector.MAX_BIRDS:
		push_warning("[fauna] kuş sayısı %d, sınır %d" % [bird_count(), FaunaDirector.MAX_BIRDS])


func _build_skies() -> void:
	for s: Variant in def.get("sky", []):
		if not s is Dictionary:
			continue
		var sky := SkyEagle.new()
		sky.name = "Sky_%d" % skies.size()
		sky.setup(s, ground)
		add_child(sky)
		skies.append(sky)
	director.birds = bird_count()


func _on_small_alarmed(target: SmallGame) -> void:
	if voices and target and is_instance_valid(target):
		voices.play(target.kind_id, &"alarm", target.global_position)


## Türün T0 modeli arka planda istenir (grubu ilk kez sahneye girince).
func _request_scene(kind: FaunaKind) -> void:
	if _scenes.has(kind.id) or not kind.drawn().is_empty():
		return
	var path := kind.model_path()
	if path.is_empty() or not ResourceLoader.exists(path) or not MeshyProp.models_enabled:
		return
	for p: String in _requests:
		if p == path:
			(_requests[p] as Array).append(kind.id)
			return
	# Başsızda eşzamanlı (FaunaMesh.background_loads: boş çizicinin kimlikleri iş parçacığına karşı korunmuyor).
	if not FaunaMesh.background_loads():
		var scene := load(path) as PackedScene
		if scene:
			_scenes[kind.id] = scene
		else:
			push_warning("[fauna] model yüklenemedi: %s" % path)
		return
	if ResourceLoader.load_threaded_request(path, "", false) == OK:
		_requests[path] = [kind.id]


func _poll_scenes() -> void:
	for path: String in _requests.keys():
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			continue
		var ids: Array = _requests[path]
		_requests.erase(path)
		if status != ResourceLoader.THREAD_LOAD_LOADED:
			push_warning("[fauna] model yüklenemedi: %s" % path)
			continue
		var scene := ResourceLoader.load_threaded_get(path) as PackedScene
		for id: String in ids:
			_scenes[id] = scene


# --- Haritanın kayıtları ------------------------------------------------------------------------------------------

func _spec() -> MapSpec:
	var s: Variant = world.get("spec") if world else null
	return s if s is MapSpec else null


## Yerleşimin yasak dairesi: winter_camp bölgesi (yoksa Ulu Ocak'ın çevresi, 150 m).
func _camp_from_map() -> Dictionary:
	var spec := _spec()
	if spec:
		for r: Variant in spec.regions:
			if r is Dictionary and str((r as Dictionary).get("id", "")) == str(def.get("camp_region", "winter_camp")):
				return {"center": (r as Dictionary).get("center", [0.0, 0.0]), "radius": float((r as Dictionary).get("radius", 135.0)) + CAMP_MARGIN}
	return {"center": [0.0, 0.0], "radius": FaunaDirector.CAMP_RADIUS}


func _bounds_from_map() -> Array:
	var spec := _spec()
	if spec == null:
		return []
	var raw: Variant = spec.get("bounds") if "bounds" in spec else null
	if raw is Rect2 and (raw as Rect2).size.x > 0.0:
		var r: Rect2 = raw
		return [r.position.x, r.position.y, r.end.x, r.end.y]
	return []


## Ateşler: Ulu Ocak (12 m), ocaklar ve nöbet ateşleri (8 m; fauna.md §6).
func _fires_from_map() -> Array[Vector3]:
	var out: Array[Vector3] = []
	var spec := _spec()
	if spec == null:
		return out
	for rec: Variant in spec.structures:
		if not rec is Dictionary:
			continue
		var kind := str((rec as Dictionary).get("kind", ""))
		var at: Variant = (rec as Dictionary).get("at")
		if not at is Array:
			continue
		if kind == "great_hearth":
			out.append(Vector3(float(at[0]), float(at[1]), FIRE_GREAT))
		elif kind == "watch_fire" or kind == "hearth" or kind == "campfire":
			out.append(Vector3(float(at[0]), float(at[1]), FIRE_SMALL))
	return out


static func _ground_of(w: Node) -> TerrainShape:
	if w == null:
		return null
	var g: Variant = w.get("ground") if "ground" in w else null
	if g is TerrainShape:
		return g
	if w.has_method(&"get_terrain_shape"):
		var t: Variant = w.call(&"get_terrain_shape")
		if t is TerrainShape:
			return t
	return null


func _find_main() -> Node:
	var n: Node = get_parent()
	while n:
		if "player" in n and "session" in n:
			return n
		n = n.get_parent()
	var tree := get_tree()
	var scene := tree.current_scene if tree else null
	if scene and "player" in scene and "session" in scene:
		return scene
	return null


# --- Geliştirme ------------------------------------------------------------------------------------------------

## --fauna=<evre ya da hh:mm>, --fauna-near=<grup kimliği>.
func _dev_args() -> Dictionary:
	var out := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--fauna="):
			var v := a.substr(8)
			var table := {"dawn": 420.0, "morning": 540.0, "noon": 720.0, "golden": 900.0, "dusk": 1040.0, "night": 1380.0}
			out["phase"] = v
			out["minute"] = float(table.get(v, GameClock.parse_hhmm(v) if v.contains(":") else 720.0))
		elif a.begins_with("--fauna-near="):
			var v := a.substr(13).split(":")
			out["near"] = v[0]
			out["near_m"] = float(v[1]) if v.size() > 1 else 24.0
		elif a == "--fauna-calm":
			out["calm"] = true
		elif a == "--fauna-lineup":
			out["lineup"] = true
	return out


static func _dev_at() -> Vector2:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--at="):
			var p := a.substr(5).split(",")
			if p.size() >= 2:
				return Vector2(float(p[0]), float(p[1]))
	return Vector2.ZERO


## Tür dizisi: --at'in 16 m kuzeyinde doğudan batıya, 5,5 m arayla (her tür bir ajan; hep var).
func _lineup_groups() -> Array:
	var at := _dev_at()
	var out: Array = []
	var kinds := ["dog", "fox", "wolf", "gazelle", "ibex", "boar", "deer"]
	for k in kinds.size():
		var x := at.x + (float(k) - float(kinds.size() - 1) * 0.5) * 3.0
		out.append({"id": "lineup_%s" % kinds[k], "kind": kinds[k], "home": [x, at.y - 5.0], "radius": 0.5, "count": [1, 1], "always": true, "free": true, "seed": 90 + k})
	return out


## Geliştirme: grubu oyuncunun belirdiği yerin 24 m kuzeyine taşır (kare için; kayıt yazılmaz).
func _apply_dev_near() -> void:
	if not _dev.has("near"):
		return
	var g := director.group(str(_dev["near"]))
	var spec := _spec()
	if g == null or spec == null:
		return
	var at := _dev_at()
	g.home = at + Vector2(0.0, -float(_dev.get("near_m", 24.0)))
	g.spot = g.home
	g.goal = g.home
