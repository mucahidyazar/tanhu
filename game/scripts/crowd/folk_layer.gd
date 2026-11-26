class_name FolkLayer
extends Node3D
## Bir iç haritanın kişi katmanı (Yol Haritası folk-generator, npc-schedules, crowd-tiers; act1.md §3–§5; Kışlak: data/maps/kislak/
## folk.json, map.json «layers» «folk»; MapLayers kurar, düğüm «Layers/Folk»dur): kişi programı (Schedule; data/story/act_1/npcs.json),
## adlı tam kişiler (T0, CharacterAvatar; ≤16), kalabalık (CrowdField: T1, T2, T3) ve yakındaki kalabalık kişisinin tam kişi yuvası.
##
## Saat: oturum kuruluysa onunki (Session; program oturumun 7. adımıdır, «schedule»), değilse katmanın kendi saati (local_clock: deneme
## haritası ve sınamalar; Gün II 10:30). Yol: haritanın navigasyonu (MapNav.path; A'nın yüzü) eşlenince programın yürüyüşleri navmesh
## yolundan gelir, o zamana dek düz çizgi. Geliştirme: --folk-clock=HH:MM ve --folk-day=N saati o ana ileri alır (kareler), --folk-tier=1|2|3
## bütün kalabalığı bir kademeye koyar, --folk-off katmanı kurmaz (bütçenin payı).
##
## Tam kişiler: tier «full» olan adlılar (Amaga, Farnak, Nanay, Ardokşa, Kantu, Mene, Palak, Atşo, Hereka, Kujul, Uldın, Berik; Gün III'te
## Eskam) kendi modelleriyle ya da Folk'un görünüşüyle (Uldın, Berik). Programın yerine yürür: plan yürürken kendi hızıyla, gerideyse 1,5
## katıyla, en çok oyuncunun koşusuyla (K105, PaceLimit.run_cap); 60 m ötesinde ve kadraj dışında yer sıçrar. İş klibi programın işinden
## (talk, work, craft, sleep; ClipVariety.pick, durumuyla), oturuş sit; yurtta ve haritanın dışında görünmez. Kadraj dışında ve uzakta
## (C3_RANGE) avatarın işleyişi durur (iskelet güncellenmez; godot.md §7.2'nin C3'ü).
## Kalabalık: öbekler (pazar, Çukur, Esir Yolu'nun kolu ve iki nöbetçisi) ve kalabalık kademesindeki kişiler (Omarg, Sak, Opia, Nandu, Yuan,
## yapı erleri, on iki nöbetçi) CrowdField'dedir; görünüşleri Folk'tan (rol: kasabalı, esir, nöbetçi). Kalabalığın kişisi kadrajda ≥80 px
## olunca tam kişi yuvasına geçer (yuva sayısı 16 − tam kişi kadrosu; adlı önce, sonra nöbetçi): yuvanın avatarı aynı modeldeyse yalnız
## boyanır (model yeniden yüklenmez).
##   MapLayers kurar; elle: var layer := FolkLayer.new(); layer.setup(world, MapLayers.read(path)); world.add_child(layer)

signal built

const CaptureTool := preload("res://scripts/dev/capture.gd")
const LAYER_ID := "folk"
## Bütçe izleyicisi (Performance.add_custom_monitor; budget_probe okur).
const MONITOR := &"Tanhu/Kişiler ms"
## İzleyicinin okuduğu katman (son kurulan).
static var _active: FolkLayer
const NPCS_PATH := "res://data/story/act_1/npcs.json"
## Tam kişi tavanı (act1.md §15, godot.md §7.2: T0 ≤16).
const T0_CAP := 16
## Katmanın kendi saati (oturum yoksa): Gün II 10:30.
const LOCAL_DAY := 1042
const LOCAL_MINUTE := 630.0
## Kadraj dışında bu uzaklıktan ötedeki tam kişinin işleyişi durur (m).
const C3_RANGE := 70.0
## Bir karede kurulan tam kişi (model sahnesi yüklenmişse; klip aktarımı kişi başına 4–40 ms).
const PEOPLE_PER_FRAME := 2
## Navmesh eşlenince kare başına yolu yenilenen kişi ve yolun ucunun hedefe en çok uzaklığı (m).
const NAV_REFRESH_PER_FRAME := 3
const NAV_SLACK := 2.0
## Tek seferlik iş klibinin (iş, el işi) arası (sn).
const WORK_REST := Vector2(3.0, 8.0)
## Yere varmış sayılan uzaklık (m) ve dönüş hızı (rad/sn).
const ARRIVE_EPS := 0.04
const TURN_RATE := 3.0
## Arabanın sürücüsü (Travel.driver yoksa): araba iş başındayken (oturumun «travel» hizmeti, on_duty) arabadadır, katman onu gizler
## (travel.md §5.3 madde 6: program konumu sefer boyunca iptal edilir; tek Kantu).
const CART_DRIVER := "kantu"

var map_world: Node3D
var data: Dictionary = {}
var schedule: Schedule
var session: Session
var clock: GameClock
var field: CrowdField
var allocator := ClipVariety.Allocator.new()
## Tam kişiler: kimlik → {avatar, xz, yaw, look, job, key, rest, hidden}.
var people: Dictionary = {}
## Kalabalığın kişileri: [{kind: "group" | "person", ref: kalabalığın sırası ya da kişinin kimliği, look}].
var members: Array[Dictionary] = []
## Tam kişi yuvaları: [{avatar, member, model}].
var slots: Array[Dictionary] = []
var player: Node3D
## Sıçrama kuralının merkezi (oyuncu; yoksa kamera).
var focus := Vector3.INF
## Tam kişilerin ölçülen en yüksek hızı (m/sn).
var peak_speed := 0.0
## Kurulumun süresi (ms; bütçe) ve karedeki işin ortalaması (ms; GDScript payı: «Tanhu/Kişiler ms» izleyicisi).
var build_ms := 0.0
var process_ms := 0.0

var _built := false
var _ready_flag := false
## Haritanın navigasyonu (MapNav; A'nın yüzü): eşlenince programın yürüyüşleri navmesh yolundan (kişi kişi yenilenir).
var _nav: MapNav
var _nav_synced := false
var _nav_refresh: PackedStringArray = PackedStringArray()
var _local_clock := false
## Kurulmayı bekleyen tam kişiler (modeli arka planda yüklenir; kare başına PEOPLE_PER_FRAME kişi kurulur), açık arka plan istekleri ve
## alınan model sahneleri (yol → PackedScene).
var _pending: PackedStringArray = PackedStringArray()
var _requested: PackedStringArray = PackedStringArray()
var _scenes: Dictionary = {}
var _shape: RefCounted
var _rng := RandomNumberGenerator.new()
var _slot_tick := 0.0
## Menzil ağının durumu (sınama; yoksa oturumun «travel» hizmeti).
var travel_override: Travel


## MapLayers'ın kurulumu (ağaca eklenmeden önce): dünya ve katmanın dosyası.
func setup(world: Node3D, def: Dictionary) -> void:
	map_world = world
	data = def


func _ready() -> void:
	process_priority = 5
	_rng.seed = 7311
	if map_world == null:
		var n := get_parent()
		while n and not n is MapWorld:
			n = n.get_parent()
		map_world = n as Node3D
	if map_world is MapWorld and not (map_world as MapWorld).is_ready():
		(map_world as MapWorld).world_ready.connect(_build, CONNECT_ONE_SHOT)
	else:
		_build.call_deferred()


func _exit_tree() -> void:
	# İzleyici katmanla gider, önce (çıkışta betiği bırakılmış bir işleve çağrı kalmasın; aşağıdaki işler yarıda kalsa da).
	if _active == self:
		_active = null
		if Performance.has_custom_monitor(MONITOR):
			Performance.remove_custom_monitor(MONITOR)
	if session and is_instance_valid(session) and session.get_system(&"schedule") == schedule:
		session.remove_system(&"schedule")
	_collect_requests()
	ClipVariety.release_sources()
	# Geliştirme koşularında (argümanlı) kısa özet: kurulum ve karedeki iş (bütçe raporu için).
	if _built and not OS.get_cmdline_user_args().is_empty():
		print("[folk] kurulum %.1f ms, kare %.3f ms; tam kişi %d, yuva %d, kalabalık %d" % [build_ms, process_ms, people.size(), slots.size(),
			members.size()])


static func _monitor_ms() -> float:
	return _active.process_ms if _active and is_instance_valid(_active) else 0.0


## Kuruldu mu (program, kalabalık ve bütün tam kişiler)?
func is_built() -> bool:
	return _built and _pending.is_empty()


func _build() -> void:
	if _built:
		return
	# Geliştirme: --folk-off katmanı kurmaz (bütçe ölçümünde katmanın payı: açık ve kapalı iki koşu).
	if CaptureTool.parse_args(OS.get_cmdline_user_args()).has("folk-off"):
		return
	var started := Time.get_ticks_usec()
	if map_world and map_world.has_method(&"get_terrain_shape"):
		_shape = map_world.call(&"get_terrain_shape")
	if _shape == null and map_world and map_world.get(&"ground") is RefCounted:
		_shape = map_world.get(&"ground")
	schedule = Schedule.new()
	schedule.setup(Schedule.load_data(str(data.get("npcs", NPCS_PATH))))
	_nav = MapNav.of(map_world)
	if _nav:
		schedule.path_provider = _nav_path
	_bind_clock()
	_dev_clock()
	schedule.step(0.0)
	var roster := _queue_people()
	# Yuva sayısı: 16 − kadro; katmanın verisi daha azını isteyebilir (t0_slots; bütçe ve sınama).
	var free_slots := T0_CAP - roster
	if data.has("t0_slots"):
		free_slots = mini(free_slots, int(data["t0_slots"]))
	_build_crowd(free_slots)
	_built = true
	build_ms = (Time.get_ticks_usec() - started) / 1000.0
	if not Performance.has_custom_monitor(MONITOR):
		# Lambda değil, betiğin durağan işlevi: betik bırakılınca «orphaned lambda» kalmaz (çağrı geçersizleşir, çökmez).
		Performance.add_custom_monitor(MONITOR, Callable(FolkLayer, &"_monitor_ms"))
	_active = self
	_build_some_people()


## Saat: oturumunki (program oturumun 7. adımına girer) ya da katmanınki.
func _bind_clock() -> void:
	var main := map_world.get_parent() if map_world else null
	session = main.get_node_or_null(^"Session") as Session if main else null
	if session and session.clock:
		clock = session.clock
		schedule.clock = clock
		if session.get_system(&"schedule") == null:
			session.add_system(&"schedule", schedule, &"schedule")
		if not session.clock_replaced.is_connected(_on_clock_replaced):
			session.clock_replaced.connect(_on_clock_replaced)
		_local_clock = false
	else:
		var local: Dictionary = data.get("local_clock", {})
		clock = GameClock.new(int(local.get("day", LOCAL_DAY)), GameClock.parse_hhmm(local.get("time", GameClock.hhmm(LOCAL_MINUTE))))
		schedule.clock = clock
		_local_clock = true
	var p: Variant = main.get(&"player") if main else null
	player = p as Node3D if p is Node3D else null


func _on_clock_replaced(c: GameClock) -> void:
	clock = c
	if schedule:
		schedule.clock = c
	if field:
		field.snap()


## Geliştirme: --folk-clock=HH:MM (--folk-day=N) saati o ana ileri alır (geri gitmez: geçmişse ertesi gün).
func _dev_clock() -> void:
	var args := CaptureTool.parse_args(OS.get_cmdline_user_args())
	if not args.has("folk-clock"):
		return
	var m := GameClock.parse_hhmm(str(args["folk-clock"]))
	if m < 0.0:
		return
	var day := int(args.get("folk-day", clock.day_n))
	var target := GameClock.abs_of(day, m)
	while target <= clock.abs_minute():
		target += 1440.0
	clock.set_to(target, &"dev")


# --- Tam kişiler ----------------------------------------------------------------------------------------------------------

## Tam kişileri sıraya koyar: modelleri arka planda istenir (ResourceLoader.load_threaded_request), kişi modeli yüklenince kurulur.
## Döner: kadronun sayısı (≤ T0_CAP).
func _queue_people() -> int:
	var holder := Node3D.new()
	holder.name = "People"
	add_child(holder)
	_pending = PackedStringArray()
	var models := {}
	for id in schedule.people_ids:
		var rec: Dictionary = schedule.people[id]
		if str(rec.get("tier", "")) != "full" or _pending.size() >= T0_CAP:
			continue
		_pending.append(id)
		models[str(Folk.person(str(rec.get("look", id))).get("model", ""))] = true
	for look: Dictionary in [Folk.make("x", {"body": "male"}), Folk.make("x", {"body": "female"}), Folk.make("x", {"role": "guard"})]:
		models[str(look.get("model", ""))] = true
	# Başsızda (sınamalar) istek açılmaz: modeller kurulurken yüklenir (sahte çizicide iş parçacığındaki doku kurulumu hata yazıyor).
	var threaded := DisplayServer.get_name() != "headless"
	for model: Variant in models:
		var path := CharacterOptions.model_path(str(model))
		if threaded and not str(model).is_empty() and ResourceLoader.exists(path) \
				and ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			ResourceLoader.load_threaded_request(path, "", false)
			_requested.append(path)
	return _pending.size()


## Arka plan isteklerinin sonuçları alınır (istek açık kalmasın; yuvaların kalabalık modelleri bellekte kalır).
func _collect_requests() -> void:
	for path in _requested:
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS or status == ResourceLoader.THREAD_LOAD_LOADED:
			_scenes[path] = ResourceLoader.load_threaded_get(path)
	_requested = PackedStringArray()


## Modeli yüklenmiş en çok PEOPLE_PER_FRAME kişiyi kurar; sıra boşalınca klip kaynakları bırakılır, built yayılır.
func _build_some_people() -> void:
	var made := 0
	while not _pending.is_empty() and made < PEOPLE_PER_FRAME:
		var id := _pending[0]
		var rec: Dictionary = schedule.people[id]
		var model := str(Folk.person(str(rec.get("look", id))).get("model", ""))
		var path := CharacterOptions.model_path(model)
		if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			return
		_pending.remove_at(0)
		_make_person(id)
		made += 1
	if _pending.is_empty() and not _ready_flag:
		_ready_flag = true
		_collect_requests()
		ClipVariety.release_sources()
		built.emit()


## Tam kişiyi kurar: görünüşü (Folk.person), dağıtıcıya kaydı, programın yerinde; rollerin ve işlerin klipleri şimdi kurulur (kare içinde
## aktarım olmasın).
func _make_person(id: String) -> void:
	var holder := get_node(^"People")
	var rec: Dictionary = schedule.people[id]
	var look := Folk.person(str(rec.get("look", id)))
	look["id"] = id
	var avatar := CharacterAvatar.new()
	avatar.name = id.to_pascal_case()
	avatar.start_pose = &"idle"
	Folk.prepare(avatar, look, allocator)
	var st := schedule.state_of(id)
	var xz: Vector2 = st.get("pos", Vector2.ZERO)
	holder.add_child(avatar)
	avatar.global_position = Vector3(xz.x, _height(xz), xz.y)
	avatar.rotation.y = float(st.get("yaw", 0.0))
	avatar.warm_variety()
	people[id] = {"avatar": avatar, "xz": xz, "yaw": float(st.get("yaw", 0.0)), "look": look, "job": "", "key": "",
		"rest": 0.0, "hidden": false, "snap": true}
	for job in ["talk", "work", "craft", "sleep"]:
		var key := _job_key(id, job, look)
		if not key.is_empty() and avatar.get_skeleton():
			ClipVariety.library().clip_for(str(look.get("model", id)), key, avatar.get_skeleton())


func _update_people(delta: float, cam: Camera3D) -> void:
	var cap := minf(schedule.walk_speed * schedule.hurry, PaceLimit.run_cap(player) if player else PaceLimit.ADULT_RUN)
	for id: String in people:
		var p: Dictionary = people[id]
		var avatar: CharacterAvatar = p["avatar"]
		var st := schedule.state_of(id)
		if st.is_empty():
			continue
		# Sürücü arabadaysa (iş başında ya da programın «cart» işinde) burada görünmez: yeri arabanındır, çevrimin yerine yürümez; araba
		# bırakınca planının yerinde belirir (yetişmek için yürümez).
		if on_cart(id) or str(st.get("job", "")) == "cart":
			if not bool(p["hidden"]):
				p["hidden"] = true
				avatar.visible = false
				avatar.process_mode = Node.PROCESS_MODE_DISABLED
			p["snap"] = true
			continue
		var target: Vector2 = st["pos"]
		var here: Vector2 = p["xz"]
		var dist := here.distance_to(target)
		var moved := 0.0
		var heading := Vector2.ZERO
		if bool(p["snap"]) or (not bool(st["visible"]) and not bool(st["moving"]) and bool(p["hidden"])):
			here = target
		elif dist > ARRIVE_EPS:
			if _far_and_hidden(here, target, cam):
				here = target
			else:
				heading = (target - here) / dist
				moved = minf(dist, cap * delta)
				here += heading * moved
		p["snap"] = false
		var speed := moved / delta if delta > 0.0 else 0.0
		if moved > 0.0:
			peak_speed = maxf(peak_speed, speed)
		var arrived := here.distance_to(target) <= ARRIVE_EPS
		var hidden := arrived and not bool(st["visible"])
		p["xz"] = here
		if hidden != bool(p["hidden"]):
			p["hidden"] = hidden
			avatar.visible = not hidden
		var y := _height(here)
		var at := Vector3(here.x, y, here.y)
		var near := focus == Vector3.INF or Vector2(focus.x, focus.z).distance_to(here) <= C3_RANGE
		var in_frame := cam == null or cam.is_position_in_frustum(at + Vector3.UP)
		var live := not hidden and (near or in_frame)
		avatar.process_mode = Node.PROCESS_MODE_INHERIT if live else Node.PROCESS_MODE_DISABLED
		if hidden:
			continue
		avatar.global_position = at
		var yaw := float(p["yaw"])
		var want := atan2(heading.x, heading.y) if moved > 0.0005 else float(st["yaw"])
		yaw += clampf(angle_difference(yaw, want), -TURN_RATE * delta, TURN_RATE * delta)
		p["yaw"] = yaw
		avatar.rotation.y = yaw
		if not live:
			continue
		if moved > 0.0001 or (bool(st["moving"]) and not arrived):
			_set_job(p, avatar, "", "")
			avatar.set_locomotion(maxf(speed, schedule.walk_speed * 0.6))
		else:
			_play_job(id, p, avatar, str(st["job"]), delta)


## Kişi arabanın sürücüsü ve araba iş başında mı (çağrıldı, bekliyor, seferde ya da dönüyor: Travel.on_duty)? O sürede sürücü arabada
## görünür (TravelLayer); programın «cart» işi zaten gizlidir (Schedule.HIDDEN_JOBS).
func on_cart(id: String) -> bool:
	var t: Travel = travel_override
	if t == null and session and is_instance_valid(session):
		var svc: Variant = session.services().get("travel")
		t = svc as Travel if svc is Travel else null
	if t == null or not t.on_duty:
		return false
	return id == (t.driver if not t.driver.is_empty() else CART_DRIVER)


## Programın işi → avatarın klibi (talk, work, craft, sleep: kütüphaneden; sit: oturuş; stand ve öbürü: bekleme).
func _play_job(id: String, p: Dictionary, avatar: CharacterAvatar, job: String, delta: float) -> void:
	match job:
		"sit":
			if str(p["job"]) != job:
				_set_job(p, avatar, job, "")
				avatar.play_pose(&"sit")
		"talk", "sleep", "craft", "work":
			if str(p["job"]) != job:
				var key := _job_key(id, job, p["look"])
				_set_job(p, avatar, job, key)
				if key.is_empty() or not avatar.play_job(key):
					if job == "craft" or job == "sleep":
						avatar.play_pose(&"sit")
					else:
						avatar.set_locomotion(0.0)
				p["rest"] = _rng.randf_range(WORK_REST.x, WORK_REST.y)
			elif job == "work" or job == "craft":
				_repeat_job(p, avatar, delta)
		_:
			if str(p["job"]) != "stand":
				_set_job(p, avatar, "stand", "")
				avatar.set_locomotion(0.0)


## Tek seferlik iş klibi bitince bir süre bekleme, sonra yeniden.
func _repeat_job(p: Dictionary, avatar: CharacterAvatar, delta: float) -> void:
	var anim := avatar.get_animation_player()
	var key := str(p["key"])
	if anim == null or key.is_empty():
		return
	if avatar.get_current_role() == CharacterAvatar.JOB_ROLE and anim.is_playing():
		return
	p["rest"] = float(p["rest"]) - delta
	if avatar.get_current_role() == CharacterAvatar.JOB_ROLE:
		avatar.set_locomotion(0.0)
	if float(p["rest"]) <= 0.0:
		p["rest"] = _rng.randf_range(WORK_REST.x, WORK_REST.y)
		avatar.play_job(key)


func _set_job(p: Dictionary, _avatar: CharacterAvatar, job: String, key: String) -> void:
	p["job"] = job
	p["key"] = key


## İşin klibi (ClipVariety.pick, durumuyla: konuşma talk ve listen, iş chore, el işi yerde chore, uyku night): kişiye belirlenimci.
func _job_key(id: String, job: String, look: Dictionary) -> String:
	var groups := {"talk": ["talk", ["talk", "listen"]], "work": ["work", ["chore"]], "craft": ["sit_ground", ["chore"]],
		"sleep": ["sleep", ["night"]]}
	if not groups.has(job):
		return ""
	var g: Array = groups[job]
	var profile := Folk.variety_profile(look)
	var options := {"situations": g[1], "model": str(look.get("model", id))}
	var key := ClipVariety.pick(id, str(g[0]), profile, [], options)
	if job == "talk" and key.is_empty():
		key = ClipVariety.pick(id, "idle_loop", profile, [], {"situations": ["listen"], "model": options["model"]})
	return key


# --- Kalabalık -------------------------------------------------------------------------------------------------------------

func _build_crowd(t0_slots: int) -> void:
	var looks: Array = []
	members.clear()
	for i in schedule.crowd.size():
		var c: Dictionary = schedule.crowd[i]
		var look := Folk.make("kislak:%s" % str(c["seed"]), {"role": str(c.get("role", "townsfolk"))})
		members.append({"kind": "group", "ref": i, "look": look})
		looks.append(look)
	for id in schedule.people_ids:
		var rec: Dictionary = schedule.people[id]
		if str(rec.get("tier", "")) != "crowd":
			continue
		var look_id := str(rec.get("look", id))
		var look := Folk.make(look_id, {"role": str(rec["role"])}) if rec.has("role") else Folk.person(look_id)
		members.append({"kind": "person", "ref": id, "look": look, "named": rec.has("name") and not rec.has("role")})
		looks.append(look)
	field = CrowdField.new()
	field.name = "Crowd"
	field.walk_speed = schedule.walk_speed
	field.hurry = schedule.hurry
	field.snap_m = schedule.snap_m
	field.t0_slots = maxi(t0_slots, 0)
	field.setup(looks, _shape)
	for i in members.size():
		if bool(members[i].get("named", false)):
			field.priority[i] = 2
	field.set_process(false)
	# Geliştirme: --folk-tier=1|2|3 bütün kalabalığı o kademeye koyar (kademelerin kareleri).
	var args := CaptureTool.parse_args(OS.get_cmdline_user_args())
	if args.has("folk-tier") and str(args["folk-tier"]).is_valid_int():
		field.force_tier = clampi(int(str(args["folk-tier"])), CrowdPlan.T1, CrowdPlan.T3)
	add_child(field)
	_feed_crowd()
	field.snap()


func _feed_crowd() -> void:
	var minute := clock.minute
	for i in members.size():
		var m: Dictionary = members[i]
		if str(m["kind"]) == "group":
			var pose := schedule.crowd_pose(int(m["ref"]), minute)
			field.set_plan(i, pose["xz"], float(pose["yaw"]), int(pose["state"]), float(pose["presence"]))
		else:
			var st := schedule.state_of(str(m["ref"]))
			var state := CrowdPlan.State.ABSENT
			var presence := 0.0
			if bool(st.get("visible", false)) or bool(st.get("moving", false)):
				presence = 1.0
				state = CrowdPlan.State.WALK if bool(st["moving"]) else _pose_of_job(str(st["job"]))
			field.set_plan(i, st.get("pos", Vector2.ZERO), float(st.get("yaw", 0.0)), state, presence)


static func _pose_of_job(job: String) -> int:
	match job:
		"work":
			return CrowdPlan.State.WORK
		"sit", "sleep", "craft":
			return CrowdPlan.State.SIT
		"inside", "away", "cart":
			return CrowdPlan.State.ABSENT
		_:
			return CrowdPlan.State.STAND


## Tam kişi yuvaları (4 Hz): T0'a geçen kalabalık kişisi bir yuvanın avatarını alır (aynı modeldeyse yalnız boya; değilse model değişir),
## T0'dan çıkanın yuvası boşalır. Her kare yuvanın avatarı kişinin yerinde, hızına ve duruşuna göre oynar.
func _update_slots(delta: float) -> void:
	_slot_tick -= delta
	if _slot_tick <= 0.0:
		_slot_tick = CrowdField.TIER_PERIOD
		for s: Dictionary in slots:
			var m := int(s["member"])
			if m >= 0 and field.tier_of(m) != CrowdPlan.T0:
				s["member"] = -1
				(s["avatar"] as CharacterAvatar).visible = false
				(s["avatar"] as CharacterAvatar).process_mode = Node.PROCESS_MODE_DISABLED
		for i in members.size():
			if field.tier_of(i) != CrowdPlan.T0 or _slot_of(i) >= 0:
				continue
			_assign_slot(i)
	for s: Dictionary in slots:
		var m := int(s["member"])
		if m < 0:
			continue
		var avatar: CharacterAvatar = s["avatar"]
		avatar.global_position = field.position_of(m)
		avatar.rotation.y = field.yaw_of(m)
		match field.state_of(m):
			CrowdPlan.State.WALK:
				avatar.set_locomotion(maxf(field.speed_of(m), schedule.walk_speed * 0.6))
			CrowdPlan.State.SIT:
				if avatar.get_current_role() != &"sit":
					avatar.play_pose(&"sit")
			_:
				if avatar.get_current_role() != &"idle":
					avatar.set_locomotion(0.0)


func _slot_of(member: int) -> int:
	for k in slots.size():
		if int(slots[k]["member"]) == member:
			return k
	return -1


func _assign_slot(member: int) -> void:
	var look: Dictionary = members[member]["look"]
	var model := str(look.get("model", ""))
	if model.is_empty():
		return
	var pick := -1
	for k in slots.size():
		if int(slots[k]["member"]) < 0 and str(slots[k]["model"]) == model:
			pick = k
			break
	if pick < 0:
		for k in slots.size():
			if int(slots[k]["member"]) < 0:
				pick = k
				break
	if pick < 0:
		if slots.size() >= field.t0_slots:
			return
		var avatar := CharacterAvatar.new()
		avatar.name = "Slot%d" % slots.size()
		var slot_look := look.duplicate()
		slot_look["id"] = "folk_slot_%d" % slots.size()
		Folk.prepare(avatar, slot_look, allocator)
		get_node(^"People").add_child(avatar)
		slots.append({"avatar": avatar, "member": member, "model": model})
		pick = slots.size() - 1
	var s: Dictionary = slots[pick]
	var av: CharacterAvatar = s["avatar"]
	if str(s["model"]) != model:
		Folk.prepare(av, Dictionary(look).merged({"id": av.variety_person}, true))
		s["model"] = model
	Folk.repaint(av, look)
	s["member"] = member
	av.visible = true
	av.process_mode = Node.PROCESS_MODE_INHERIT
	# Rollerin klipleri şimdi kurulur, aktarımın kaynak sahneleri bırakılır (kaynak sahne bellekte kalmasın).
	av.warm_variety()
	ClipVariety.release_sources()


# --- Kare ------------------------------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if not _built:
		return
	var started := Time.get_ticks_usec()
	_step(delta)
	process_ms = lerpf(process_ms, (Time.get_ticks_usec() - started) / 1000.0, 0.05)


func _step(delta: float) -> void:
	if not _pending.is_empty():
		_build_some_people()
	_sync_nav()
	if _local_clock:
		clock.step(delta)
		schedule.step(delta)
	elif session == null or not is_instance_valid(session) or session.get_system(&"schedule") != schedule:
		schedule.step(delta)
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	focus = player.global_position if player and is_instance_valid(player) else (_camera_focus(cam) if cam else Vector3.INF)
	field.focus = focus
	field.speed_cap = PaceLimit.run_cap(player) if player else PaceLimit.ADULT_RUN
	_update_people(delta, cam)
	_feed_crowd()
	field.tick(delta)
	_update_slots(delta)


## Navmesh eşlenince programın çizelgeleri yenilenir: kare başına NAV_REFRESH_PER_FRAME kişi (yol isteği kişi başına birkaç tane; bir karede
## hepsi istenmez). Eşlenmeden önce yürüyüş düz çizgidir.
func _sync_nav() -> void:
	if _nav == null:
		return
	if not _nav_synced:
		if not is_instance_valid(_nav) or not _nav.is_ready():
			return
		_nav_synced = true
		_nav_refresh = schedule.people_ids.duplicate()
	var k := 0
	while not _nav_refresh.is_empty() and k < NAV_REFRESH_PER_FRAME:
		schedule.invalidate(_nav_refresh[0])
		_nav_refresh.remove_at(0)
		k += 1


## Programın yol isteği (Schedule.path_provider): navmesh yolu (MapNav.path; ucu hedefe NAV_SLACK'ten uzaksa ya da harita eşlenmediyse boş:
## program düz çizgiye düşer). Köşeler x, z düzlemine iner, uçlar bloğun yeridir.
func _nav_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	if not _nav_synced or _nav == null or not is_instance_valid(_nav):
		return PackedVector2Array()
	var p := _nav.path(Vector3(from.x, _height(from), from.y), Vector3(to.x, _height(to), to.y))
	if p.size() < 2 or Vector2(p[p.size() - 1].x, p[p.size() - 1].z).distance_to(to) > NAV_SLACK:
		return PackedVector2Array()
	var out := PackedVector2Array([from])
	for q in p:
		var v := Vector2(q.x, q.z)
		if v.distance_squared_to(out[out.size() - 1]) > 0.04:
			out.append(v)
	if out[out.size() - 1].distance_squared_to(to) > 0.0001:
		out.append(to)
	return out


## Kameranın baktığı yerin yaklaşığı (oyuncu yoksa): kameranın önünde, zemin hizasında.
func _camera_focus(cam: Camera3D) -> Vector3:
	var forward := -cam.global_transform.basis.z
	if forward.y < -0.05:
		var t := -cam.global_position.y / forward.y
		return cam.global_position + forward * t
	return cam.global_position


func _far_and_hidden(a: Vector2, b: Vector2, cam: Camera3D) -> bool:
	if focus == Vector3.INF:
		return false
	var f := Vector2(focus.x, focus.z)
	if a.distance_to(f) <= schedule.snap_m or b.distance_to(f) <= schedule.snap_m:
		return false
	if cam == null:
		return true
	for p: Vector2 in [a, b]:
		if cam.is_position_in_frustum(Vector3(p.x, _height(p) + 1.0, p.y)):
			return false
	return true


func _height(xz: Vector2) -> float:
	return float(_shape.call(&"height_at", xz.x, xz.y)) if _shape else 0.0


## Herkes bir sonraki karede planının yerine oturur (sahne atlanınca, saat uzun atlayınca: kimse yetişmek için yürümez).
func snap() -> void:
	for id: String in people:
		people[id]["snap"] = true
	if field:
		field.snap()


# --- Sınama ve bütçe -------------------------------------------------------------------------------------------------------

## Sayılar: tam kişi (görünen kadro ve dolu yuva), kalabalığın kademeleri.
func counts() -> Dictionary:
	var shown := 0
	for id: String in people:
		if not bool(people[id]["hidden"]):
			shown += 1
	var used := 0
	for s: Dictionary in slots:
		if int(s["member"]) >= 0:
			used += 1
	var out := {"full": shown, "slots": used, "t0": shown + used}
	if field:
		out.merge(field.counts())
	return out


## Tam kişinin avatarı (sınama).
func avatar_of(id: String) -> CharacterAvatar:
	return (people.get(id, {}) as Dictionary).get("avatar")
