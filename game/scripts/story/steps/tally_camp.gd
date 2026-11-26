class_name TallyCamp
extends Node3D
## Ebe Obası'nın sabahı (Çocukluk, 21 Eylül MÖ 228; K110, story.md §5 «İki yeni gün», docs/design/d3/e21-atmosphere.md «Ebenin Çetelesi»): obanın
## kişileri işindedir, Ç1'in kurduğu yurtların (Hereka'nınki açık) ve ocağın arasında. Hereka'nın yurdunun önünde kurut seren kadın (keçe sergi,
## üstünde ak kurut topakları) ve kuruyan ot demetleri (iki kazık arasında ip), at bağlayan adam (bağlama direği ve doru at), tayıyla kısrağın
## yanında bir adam (bu yılın tayı: «bizim tay da sayılsın»), ocağın yanında aşık oynayan iki çocuk (diz çökmüş, aralarında aşık kemikleri).
## Yetişkinler Folk'tur (kodla kişi: crowd_hun_man / crowd_hun_woman, halkın renkleri), çocuklar var olan çocuk modellerinin yeniden boyanmış
## hâli (StandIn renk çarpanı); hepsi kütüphanenin iş kliplerini sırayla oynar. Köpekler TallyDogs'un (görgü) görünüşüdür: türün modeli
## (data/fauna/kinds.json «dog»), hızına göre yürür ya da tırıs atar, havlaması sfx_dogs_guard (ChildhoodAtmos), tutulunca sfx_dog_settle.
## Kurulum karelere bölünür (build_some: kare başına bir iş): sabah Lan Hatun'un yurdunda konuşulurken kurulur, yolda takılma olmaz.
##   var camp := TallyCamp.new(); root.add_child(camp)
##   camp.setup(scene, step["camp"])
##   while not camp.build_some(): await process_frame   # ya da adımın tick'inde
##   camp.tick(delta, player_pos, player_speed)
##   camp.person("curd_woman")  # {avatar, at, yaw, reply, told, ...}

signal built

const DOG_KIND := "dog"
const HORSE_DIR := "res://assets/animals/%s/%s.glb"
## İş klibinin değişme aralığı (sn).
const JOB_EVERY := Vector2(4.0, 7.0)
## Köpek havlamasının en kısa arası (sn; iki köpek birlikte; örnek 2 sn'liktir) ve hırlamanın (fauna bankası) düzeyi.
const BARK_GAP := 1.7
const BARK_DB := -1.0
const GROWL_DB := -9.0
## Kişinin konuşurken oyuncuya dönüşü (sn).
const TURN_S := 0.45

var scene: ChildhoodScene
var shape: RefCounted
var def: Dictionary = {}
## Köpeklerin görgüsü (saf) ve görünüşleri.
var dogs: TallyDogs
var hounds: Array[Hound] = []
## Kişiler: kimlik → {avatar, look, at, yaw, jobs, job_i, job_left, reply, told, speaker}.
var people: Dictionary = {}
var horses: Array[Steed] = []

var _tasks: Array[Callable] = []
var _built := false
var _allocator := ClipVariety.Allocator.new()
var _rng := RandomNumberGenerator.new()
var _bark_left := 0.0
var _turns: Dictionary = {}
var _diorama_on := false


func _exit_tree() -> void:
	end_diorama()
	# Kişilerin kendi malzemeleri ağlarından önce çıkar: aynı ağı taşıyan iki kişi aynı karede silinirken çizim sunucusu silinmiş malzemenin örnek
	# parametrelerini okumasın («Parameter "material" is null»; CharacterAvatar._release_materials'ın notu).
	# Köpeklerin boyalı kopyaları da (iki köpek aynı ağı taşır).
	CharacterAvatar._release_materials(self)


## Sahnenin obası (Story düğümünün altında; create ise yoksa kurulur, günün verisinin camp'ıyla). Gün bitince sahneyle gider.
static func of(p_scene: ChildhoodScene, create: bool = false) -> TallyCamp:
	if p_scene == null or p_scene.world == null:
		return null
	var root := BoneView.story_root(p_scene)
	if root == null:
		return null
	var camp := root.get_node_or_null(^"EbeCamp") as TallyCamp
	if camp == null and create:
		camp = TallyCamp.new()
		camp.name = "EbeCamp"
		root.add_child(camp)
		camp.setup(p_scene, p_scene.data.get("camp", {}))
	return camp


## Kurulum (ağaca eklendikten sonra): işler kuyruğa girer, build_some kurar.
func setup(p_scene: ChildhoodScene, p_def: Dictionary) -> void:
	scene = p_scene
	def = p_def
	name = "EbeCamp"
	shape = scene.world.call(&"get_terrain_shape") if scene and scene.world and scene.world.has_method(&"get_terrain_shape") else null
	_rng.seed = int(def.get("seed", 2101))
	if def.get("herbs") is Dictionary:
		_tasks.append(_build_herbs.bind(def["herbs"]))
	if def.get("curd_mat") is Dictionary:
		_tasks.append(_build_curd_mat.bind(def["curd_mat"]))
	if def.get("knucklebones") is Dictionary:
		_tasks.append(_build_knucklebones.bind(def["knucklebones"]))
	for p: Variant in def.get("posts", []):
		_tasks.append(_build_post.bind(p))
	for h: Variant in def.get("horses", []):
		_tasks.append(_build_horse.bind(h))
	for p: Variant in def.get("people", []):
		_tasks.append(_build_person.bind(p))
	for k: Variant in def.get("kids", []):
		_tasks.append(_build_kid.bind(k))
	_tasks.append(_build_dogs.bind(def.get("dogs", {})))


## Kuyruktan bir iş kurar; hepsi bittiyse true (built bir kez yayılır).
func build_some() -> bool:
	if _built:
		return true
	if not _tasks.is_empty():
		var task: Callable = _tasks.pop_front()
		task.call()
	if _tasks.is_empty():
		_built = true
		ClipVariety.release_sources()
		built.emit()
	return _built


func is_built() -> bool:
	return _built


## Hepsini şimdi kurar (sınama, --step ile ileriden açılış).
func build_all() -> void:
	while not build_some():
		pass


func person(id: String) -> Dictionary:
	return people.get(id, {})


## Hereka'nın yurdu: oyuncu içerideyken çatısız diorama (K98; OrdosWorld.set_yurt_diorama), çıkınca eski hâli. Döner: içeride mi.
func update_diorama(player_at: Vector3) -> bool:
	var d: Dictionary = def.get("diorama", {})
	if d.is_empty() or scene == null or scene.world == null or not scene.world.has_method(&"set_yurt_diorama"):
		return false
	var center := scene.point(d.get("at", d.get("yurt", "hereka_yurt")))
	if center == Vector3.INF or player_at == Vector3.INF:
		return false
	var dist := Vector2(player_at.x - center.x, player_at.z - center.z).length()
	var r := float(d.get("radius", 3.4))
	var inside := dist <= r if not _diorama_on else dist <= r + 0.8
	if inside != _diorama_on:
		_diorama_on = inside
		scene.world.call(&"set_yurt_diorama", str(d.get("yurt", "hereka_yurt")), inside)
	return inside


## Diorama kapanır (adımın ya da günün sonunda).
func end_diorama() -> void:
	if _diorama_on and scene and scene.world and scene.world.has_method(&"set_yurt_diorama"):
		scene.world.call(&"set_yurt_diorama", str((def.get("diorama", {}) as Dictionary).get("yurt", "hereka_yurt")), false)
	_diorama_on = false


## Her kare: kişilerin işleri ve oyuncuya dönüşleri, köpeklerin görgüsü ve görünüşü, havlama, yurdun dioraması.
func tick(delta: float, player_at: Vector3, player_speed: float) -> void:
	update_diorama(player_at)
	for id: String in people:
		var p: Dictionary = people[id]
		if _turns.has(id):
			var tr: Array = _turns[id]
			tr[2] = minf(float(tr[2]) + delta / TURN_S, 1.0)
			(p["avatar"] as Node3D).rotation.y = lerp_angle(float(tr[0]), float(tr[1]), smoothstep(0.0, 1.0, float(tr[2])))
			if float(tr[2]) >= 1.0:
				_turns.erase(id)
		var jobs: Array = p.get("jobs", [])
		if jobs.size() < 2 or bool(p.get("paused", false)):
			continue
		p["job_left"] = float(p["job_left"]) - delta
		if float(p["job_left"]) <= 0.0:
			p["job_i"] = (int(p["job_i"]) + 1) % jobs.size()
			p["job_left"] = _rng.randf_range(JOB_EVERY.x, JOB_EVERY.y)
			_play_job(p, str(jobs[int(p["job_i"])]))
	if dogs:
		dogs.step(delta, Vector2(player_at.x, player_at.z) if player_at != Vector3.INF else Vector2.INF, player_speed)
		for i in hounds.size():
			hounds[i].drive(_ground(dogs.pos[i]), dogs.speed_of(i), dogs.look_of(i), delta)
		_bark_left -= delta
		for e: Dictionary in dogs.take_events():
			var at := _ground(e["at"]) + Vector3.UP * 0.5
			match str(e["type"]):
				"bark":
					if _bark_left <= 0.0:
						_bark_left = BARK_GAP
						_sfx(str(def.get("bark_sfx", "sfx_dogs_guard")), at, BARK_DB)
				"growl":
					var audio := get_node_or_null(^"/root/AudioManager")
					if audio and audio.has_method(&"play_sfx"):
						audio.call(&"play_sfx", StringName(str(def.get("growl_sfx", "fauna/dog_warn_1"))), {"at": at, "db": GROWL_DB, "pitch": _rng.randf_range(0.9, 1.0)})
				"settle":
					_sfx(str(def.get("settle_sfx", "sfx_dog_settle")), at, -3.0)


## Kişi oyuncuya döner (konuşma) ve işini bırakır (paused); release ile işine döner.
func face_player(id: String, at: Vector3) -> void:
	var p: Dictionary = people.get(id, {})
	if p.is_empty():
		return
	var avatar: Node3D = p["avatar"]
	var yaw := CampNpcs.facing_yaw(avatar.global_position, at)
	if is_nan(yaw):
		return
	p["paused"] = true
	_turns[id] = [avatar.rotation.y, yaw, 0.0]
	var talk := str(p.get("talk", "stand_and_chat"))
	if not talk.is_empty():
		_play_job(p, talk)


func release(id: String) -> void:
	var p: Dictionary = people.get(id, {})
	if p.is_empty():
		return
	p["paused"] = false
	_turns[id] = [(p["avatar"] as Node3D).rotation.y, float(p["yaw"]), 0.0]
	var jobs: Array = p.get("jobs", [])
	if not jobs.is_empty():
		_play_job(p, str(jobs[int(p["job_i"]) % jobs.size()]))


## Haber verilmemiş, oyuncuya en yakın kişi (yoksa ""), within m içinde.
func nearest_untold(from: Vector3, within: float) -> String:
	var best := ""
	var best_d := within
	for id: String in people:
		var p: Dictionary = people[id]
		if bool(p.get("told", false)) or str(p.get("reply", "")).is_empty():
			continue
		var d := Vector2(from.x - (p["at"] as Vector3).x, from.z - (p["at"] as Vector3).z).length()
		if d <= best_d:
			best_d = d
			best = id
	return best


func told_count() -> int:
	var n := 0
	for id: String in people:
		if bool((people[id] as Dictionary).get("told", false)):
			n += 1
	return n


func news_count() -> int:
	var n := 0
	for id: String in people:
		if not str((people[id] as Dictionary).get("reply", "")).is_empty():
			n += 1
	return n


# --- Kurulum ---------------------------------------------------------------------------------------------------

func _build_person(p: Variant) -> void:
	var d: Dictionary = p
	var id := str(d.get("id", "ebe_%d" % people.size()))
	var opts := {"role": str(d.get("role", "townsfolk")), "body": str(d.get("body", "female")), "people": str(d.get("people", "hun"))}
	if d.has("age"):
		opts["age"] = int(d["age"])
	for key: String in ["coat", "trim", "hat"]:
		if d.has(key):
			opts[key] = d[key]
	var look := Folk.make("ebe:%s" % id, opts)
	look["id"] = id
	var avatar := CharacterAvatar.new()
	avatar.name = id.to_pascal_case()
	avatar.start_pose = &"idle"
	Folk.prepare(avatar, look, _allocator)
	add_child(avatar)
	_place_person(id, avatar, d, look)


## Obanın çocuğu: var olan çocuk modeli (luhun_child, yanchi_child), renk çarpanıyla başka bir çocuk.
func _build_kid(k: Variant) -> void:
	var d: Dictionary = k
	var id := str(d.get("id", "ebe_kid_%d" % people.size()))
	var avatar := CharacterAvatar.new()
	avatar.name = id.to_pascal_case()
	avatar.model_override = str(d.get("model", "luhun_child"))
	avatar.start_pose = &"idle"
	avatar.variety_person = id
	avatar.set_meta(StandIn.PERSON_META, id)
	add_child(avatar)
	StandIn.apply(avatar, StandIn.parse_tint(d.get("tint", "#d8c0a8")), float(d.get("scale", 0.96)))
	_place_person(id, avatar, d, {"id": id, "model": avatar.model_override})


func _place_person(id: String, avatar: CharacterAvatar, d: Dictionary, look: Dictionary) -> void:
	var at := _ground(_vec(d.get("at", [0.0, 0.0])))
	var face := _ground(_vec(d.get("face", d.get("at", [0.0, 1.0]))))
	var yaw := CampNpcs.facing_yaw(at, face)
	avatar.global_position = at
	avatar.rotation.y = 0.0 if is_nan(yaw) else yaw
	var jobs: Array = d.get("jobs", [])
	var rec := {"avatar": avatar, "look": look, "at": at, "yaw": avatar.rotation.y, "jobs": jobs, "job_i": 0,
		"job_left": _rng.randf_range(JOB_EVERY.x, JOB_EVERY.y), "reply": str(d.get("reply", "")), "told": false,
		"speaker": str(d.get("speaker", "")), "talk": str(d.get("talk", "stand_and_chat")), "paused": false}
	people[id] = rec
	avatar.warm_variety([&"idle"])
	if not jobs.is_empty():
		_play_job(rec, str(jobs[0]))


func _play_job(p: Dictionary, key: String) -> void:
	var avatar: CharacterAvatar = p["avatar"]
	if avatar == null or not is_instance_valid(avatar):
		return
	if key == "idle" or not avatar.play_job(key):
		avatar.set_locomotion(0.0)


func _build_dogs(d: Dictionary) -> void:
	var center := _flat(scene.point(d.get("center", "ebe_center")))
	var call := _flat(scene.point(d.get("call", "ebe_call")))
	var home := _flat(scene.point(d.get("home", "ebe_dogs")))
	var homes := [home, home + Vector2(-1.4, 0.8)]
	var cap := PaceLimit.run_cap(scene.player) if scene and scene.player else PaceLimit.CHILD_RUN
	dogs = TallyDogs.new(center, homes, cap, int(d.get("seed", 21)))
	dogs.guard_r = center.distance_to(call) - TallyDogs.BLOCK_GAP - float(d.get("guard_pad", 0.6))
	dogs.alert_at = center.distance_to(call) + float(d.get("alert_pad", 4.5))
	var kind := FaunaKind.named(DOG_KIND)
	var path := kind.model_path() if kind else ""
	var scene_res: PackedScene = load(path) as PackedScene if not path.is_empty() and ResourceLoader.exists(path) else null
	var tints: Array = d.get("tints", ["#b8a07c", "#6a5a4c"])
	for i in dogs.dog_count():
		var h := Hound.new()
		h.name = "Dog%d" % i
		add_child(h)
		h.build(scene_res, kind, StandIn.parse_tint(tints[i % tints.size()]) if not tints.is_empty() else Color.WHITE)
		h.drive(_ground(dogs.pos[i]), 0.0, Vector2.INF, 0.0)
		hounds.append(h)


func _build_horse(h: Variant) -> void:
	var d: Dictionary = h
	var model := str(d.get("model", "horse_brown"))
	var path := HORSE_DIR % [model, model]
	if not ResourceLoader.exists(path):
		return
	var steed := Steed.new()
	steed.name = "Horse%d" % horses.size()
	add_child(steed)
	steed.build(load(path) as PackedScene, float(d.get("scale", 1.0)), str(d.get("clip", "graze")), float(d.get("speed", 1.0)))
	var at := _ground(_vec(d.get("at", [0.0, 0.0])))
	steed.global_position = at
	steed.rotation.y = deg_to_rad(float(d.get("yaw", 0.0)))
	horses.append(steed)


## Hereka'nın yurdunun önünde kuruyan ot demetleri: iki kazık, aralarında ip, ipte asılı demetler (sarımsı yeşil, kızıl).
func _build_herbs(d: Dictionary) -> void:
	var root := Node3D.new()
	root.name = "DryingHerbs"
	add_child(root)
	var at := _ground(_vec(d.get("at", [0.0, 0.0])))
	root.global_position = at
	root.rotation.y = deg_to_rad(float(d.get("yaw", 0.0)))
	var span := float(d.get("span", 2.4))
	var height := float(d.get("height", 1.45))
	var wood := _mat(Color(0.38, 0.29, 0.2))
	for side in [-1.0, 1.0]:
		var pole := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.03
		cyl.bottom_radius = 0.04
		cyl.height = height + 0.1
		cyl.radial_segments = 6
		pole.mesh = cyl
		pole.material_override = wood
		pole.position = Vector3(side * span * 0.5, (height + 0.1) * 0.5, 0.0)
		root.add_child(pole)
	var rope := MeshInstance3D.new()
	var line := CylinderMesh.new()
	line.top_radius = 0.008
	line.bottom_radius = 0.008
	line.height = span
	line.radial_segments = 4
	rope.mesh = line
	rope.material_override = _mat(Color(0.55, 0.48, 0.36))
	rope.rotation_degrees.z = 90.0
	rope.position.y = height
	root.add_child(rope)
	var colors := [Color(0.55, 0.58, 0.32), Color(0.62, 0.55, 0.3), Color(0.5, 0.42, 0.28), Color(0.6, 0.33, 0.24)]
	var count := int(d.get("count", 7))
	for i in count:
		var bundle := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.025
		cone.bottom_radius = 0.09 + 0.02 * float(i % 3)
		cone.height = 0.34 + 0.06 * float(i % 2)
		cone.radial_segments = 6
		bundle.mesh = cone
		bundle.material_override = _mat(colors[i % colors.size()])
		var x := lerpf(-span * 0.42, span * 0.42, float(i) / maxf(float(count - 1), 1.0))
		bundle.position = Vector3(x, height - cone.height * 0.5 - 0.02, 0.0)
		bundle.rotation_degrees = Vector3(180.0, float(i) * 37.0, 0.0)
		root.add_child(bundle)


## Kurut sergisi: keçe yaygı ve üstünde kuruyan ak kurut topakları (tek MultiMesh).
func _build_curd_mat(d: Dictionary) -> void:
	var root := Node3D.new()
	root.name = "CurdMat"
	add_child(root)
	var at := _ground(_vec(d.get("at", [0.0, 0.0])))
	root.global_position = at
	root.rotation.y = deg_to_rad(float(d.get("yaw", 0.0)))
	var size: Vector2 = _vec(d.get("size", [1.7, 1.1]))
	var felt := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(size.x, 0.03, size.y)
	felt.mesh = box
	felt.material_override = _mat(Color(0.74, 0.66, 0.52))
	felt.position.y = 0.02
	root.add_child(felt)
	var ball := SphereMesh.new()
	ball.radius = 0.035
	ball.height = 0.05
	ball.radial_segments = 6
	ball.rings = 3
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = ball
	var n := int(d.get("count", 48))
	mm.instance_count = n
	var rng := RandomNumberGenerator.new()
	rng.seed = 2103
	for i in n:
		var p := Vector3(rng.randf_range(-size.x * 0.42, size.x * 0.42), 0.05, rng.randf_range(-size.y * 0.4, size.y * 0.4))
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * rng.randf_range(0.8, 1.2)), p))
	var curd := MultiMeshInstance3D.new()
	curd.multimesh = mm
	curd.material_override = _mat(Color(0.93, 0.91, 0.84))
	curd.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(curd)


## Aşık: iki çocuğun arasında dört küçük aşık kemiği.
func _build_knucklebones(d: Dictionary) -> void:
	var at := _ground(_vec(d.get("at", [0.0, 0.0])))
	var bone_mat := _mat(Color(0.88, 0.85, 0.76))
	for i in 4:
		var k := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.05, 0.035, 0.035)
		k.mesh = b
		k.material_override = bone_mat
		k.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(k)
		k.global_position = at + Vector3(cos(i * 1.7) * 0.18, 0.02, sin(i * 1.7) * 0.15)
		k.rotation.y = float(i) * 0.9


## Bağlama direği (at bağlanır).
func _build_post(p: Variant) -> void:
	var at := _ground(_vec(p))
	var pole := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.06
	cyl.bottom_radius = 0.075
	cyl.height = 1.6
	cyl.radial_segments = 8
	pole.mesh = cyl
	pole.material_override = _mat(Color(0.36, 0.27, 0.19))
	add_child(pole)
	pole.global_position = at + Vector3.UP * 0.8


func _sfx(id: String, at: Vector3, db: float) -> void:
	if scene and scene.atmos and not id.is_empty():
		scene.atmos.sfx(id, at, db)


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.95
	return m


func _ground(p: Variant) -> Vector3:
	var v: Vector2 = p if p is Vector2 else _flat(p as Vector3)
	return Vector3(v.x, float(shape.call(&"height_at", v.x, v.y)) if shape else 0.0, v.y)


static func _flat(p: Vector3) -> Vector2:
	return Vector2(p.x, p.z)


static func _vec(v: Variant) -> Vector2:
	if v is Array and (v as Array).size() >= 2:
		return Vector2(float(v[0]), float(v[1]))
	if v is Vector2:
		return v
	return Vector2.ZERO


## Köpeğin görünüşü: türün iskeletli modeli, hızına göre idle / walk / trot (klibin hızı adıma oranlanır, Animal'ın kalıbı).
class Hound:
	extends Node3D

	var _player: AnimationPlayer
	var _clips: Dictionary = {}
	var _clip := ""
	var _scale := 1.0

	func build(res: PackedScene, kind: FaunaKind, tint: Color) -> void:
		if res == null:
			return
		var model := res.instantiate() as Node3D
		_scale = kind.model_scale() if kind else 1.0
		model.scale = Vector3.ONE * _scale
		add_child(model)
		_player = _find_player(model)
		_clips = (kind.def.get("speed", {}) as Dictionary).duplicate() if kind else {}
		if tint != Color.WHITE:
			_tint(model, tint)
		if _player:
			_play("idle", 1.0)

	## Yer, hız (m/sn), baktığı yer (düzlem; INF: gidişine) ve kare.
	func drive(at: Vector3, speed: float, look: Vector2, delta: float) -> void:
		var prev := global_position
		global_position = at
		var dir := Vector2(at.x - prev.x, at.z - prev.z)
		var yaw := rotation.y
		if look != Vector2.INF:
			var f := look - Vector2(at.x, at.z)
			if f.length() > 0.05:
				yaw = atan2(f.x, f.y)
		elif dir.length() > 0.002:
			yaw = atan2(dir.x, dir.y)
		rotation.y = lerp_angle(rotation.y, yaw, 1.0 - exp(-8.0 * delta)) if delta > 0.0 else yaw
		if _player == null:
			return
		var walk := float(_clips.get("walk", 1.0)) * _scale
		var trot := float(_clips.get("trot", 3.2)) * _scale
		if speed < 0.15:
			_play("idle", 1.0)
		elif speed < (walk + trot) * 0.5:
			_play("walk", clampf(speed / maxf(walk, 0.1), 0.55, 1.9))
		else:
			_play("trot", clampf(speed / maxf(trot, 0.1), 0.55, 1.9))

	func _play(clip: String, rate: float) -> void:
		if not _player.has_animation(clip):
			return
		if clip != _clip or not _player.is_playing():
			_player.play(clip, 0.25)
			_clip = clip
		_player.speed_scale = rate

	func _find_player(root: Node) -> AnimationPlayer:
		if root is AnimationPlayer:
			return root
		for c in root.get_children():
			var p := _find_player(c)
			if p:
				return p
		return null

	func _tint(root: Node, color: Color) -> void:
		if root is MeshInstance3D:
			var mi := root as MeshInstance3D
			for s in mi.get_surface_override_material_count():
				var base := mi.get_active_material(s)
				if base is StandardMaterial3D:
					var m := (base as StandardMaterial3D).duplicate() as StandardMaterial3D
					m.albedo_color = m.albedo_color * color
					mi.set_surface_override_material(s, m)
		for c in root.get_children():
			_tint(c, color)


## Obanın atı (bağlı ya da otlayan): iskeletli model, bir klip (graze, idle) döngüde.
class Steed:
	extends Node3D

	func build(res: PackedScene, p_scale: float, clip: String, rate: float) -> void:
		if res == null:
			return
		var model := res.instantiate() as Node3D
		model.scale = Vector3.ONE * p_scale
		add_child(model)
		var player := _find_player(model)
		if player and player.has_animation(clip):
			player.play(clip)
			player.speed_scale = rate
			player.seek(randf() * 2.0, true)

	func _find_player(root: Node) -> AnimationPlayer:
		if root is AnimationPlayer:
			return root
		for c in root.get_children():
			var p := _find_player(c)
			if p:
				return p
		return null
