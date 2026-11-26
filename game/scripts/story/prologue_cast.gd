class_name PrologueCast
extends Node3D
## Önsöz'ün kişileri ve hayvanları (E21, K110; docs/design/d3/e21-prologue-api.md §2): Göl Obası'nın ocak halkı (Ana, Baba, Ağabey, Ozan),
## ustalar (Oktar, Erka, Dengiz: Önsöz'ün günlerinde camp3 kurulmaz, obada kendi işlerindedir) ve Kayın Obası'nın halkı (Saruk Ebe, Künay,
## Tonga, Börü ve obanın kişileri). Her kişi CineActor'dur (kimliği assets/characters/<id>/; kendi modeli yoksa meta.json'un yer tutucusu,
## yeniden boyanmış var olan ağ, K89) ve StoryMover'la yürür. İş, kütüphanenin klibidir (CharacterAvatar.play_job: work anahtarı ya da kısa
## adı); iş sürerken yürütücü işlemez (klibi ezmesin). Kişi oyuncunun ardından gelebilir (follow_player: Börü'nün eşlikçiliği). Sahnenin
## cast'ı her sahnede yeniden uygulanır: anılmayan kişi gizlenir, yeni kişi karelere bölünerek kurulur. Hayvanlar: obaların köpeği (dog.glb,
## kendi klipleriyle) ve at bağının atları (Horse; binilmez: Önsöz'de binek grubundan çıkar).
## Hız sınırı (K105): hiçbir kişi oyuncunun en yüksek koşusunu aşmaz (PrologueDays.pace).

## İşin kısa adları → kütüphanenin klip anahtarı (data/clip_library.json).
const WORKS := {
	"milk": "crouch_pick_place_f", "felt": "ground_mend", "mend": "ground_mend", "kopuz": "sit", "carve": "ground_mend",
	"sit": "sit", "stand": "", "sweep": "stand_fruit_basket_f", "basket": "stand_fruit_basket_f", "kurut": "crouch_fruit_basket_f",
	"pick": "bend_over_pick_up_m", "play": "", "drink": "stand_and_drink", "warm": "ground_warm_hands", "kneel": "ground_kneel_heels",
	"lie": "sleep_normally", "toss": "toss_and_turn", "doze": "sit_doze_off", "clap": "sitting_clap", "talk": "stand_and_chat",
	"wave": "wave_one_hand", "cheer": "big_wave_hello", "hug_knees": "ground_hug_knees", "eat": "ground_eat_bowl",
	"pull": "pull_radish", "lean_back": "ground_lean_back",
}
## Kişi kimliği → model kimliği (assets/characters/<model>/). Önsöz'ün yeni kişileri kendi klasörlerindeki yer tutucuyla gelir.
const MODELS := {
	"mother": "mother", "father": "father", "older_brother": "older_brother", "bard": "elder",
	"oktar": "oktar", "erka": "erka", "dengiz": "dengiz",
	"saruk": "saruk", "kunay": "kunay", "tonga": "tonga", "boru": "boru",
	"birch_woman": "birch_woman", "birch_man": "birch_man", "birch_elder": "birch_elder",
}
const DOG_SCENE := "res://assets/animals/dog/dog.glb"
## Ardından gelişin payları: oyuncudan bu uzaklıkta durur (m), yolu bu aralıkla yeniler (sn).
const FOLLOW_REPATH := 0.25

## Bir kişi: CineActor, yürütücü, işi ve durumu.
class Person extends RefCounted:
	var id := ""
	var actor: CineActor
	var mover: StoryMover
	var cast: PrologueCast
	var job := ""
	var walking := false
	var follow_gap := -1.0
	var after_work := ""
	var after_face := Vector3.INF
	## Yol dönüp dolaşsın mı (oynayan çocuk, devriye)?
	var loop_path: Array = []
	var loop_speed := 1.2
	var _repath := 0.0

	func position() -> Vector3:
		return actor.global_position if actor and actor.is_inside_tree() else Vector3.ZERO

	func is_walking() -> bool:
		return walking

	func set_present(on: bool) -> void:
		if actor == null:
			return
		actor.visible = on
		actor.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED

	func is_present() -> bool:
		return actor != null and actor.visible

	## Yerine koyar (face'e döner; INF ise yönü kalır).
	func place(at: Vector3, face: Vector3 = Vector3.INF) -> void:
		walking = false
		follow_gap = -1.0
		var yaw := actor.rotation.y
		if face != Vector3.INF:
			var y := CampNpcs.facing_yaw(at, face)
			if not is_nan(y):
				yaw = y
		mover.place(at, yaw)

	## Yürür (yolun noktaları), varınca işe başlar ve face'e döner.
	func walk(path: Array, speed: float, work_after: String = "", face: Vector3 = Vector3.INF) -> void:
		job = ""
		follow_gap = -1.0
		walking = true
		# Tek seferlik yürüyüş: önceki sahnenin döngüsü (loop) sürmez; döngüyü _apply_def yürüyüşten sonra yeniden kurar.
		loop_path = []
		after_work = work_after
		after_face = face
		mover.go(path, cast.pace(speed))

	## İş (klip anahtarı ya da kısa ad; "" ayakta durur).
	func work(key: String) -> void:
		walking = false
		var clip := str(PrologueCast.WORKS.get(key, key))
		job = clip
		if actor.avatar == null:
			return
		if clip.is_empty():
			actor.avatar.set_locomotion(0.0)
		elif not actor.avatar.play_job(clip):
			job = ""
			actor.avatar.set_locomotion(0.0)

	func face_point(p: Vector3) -> void:
		if p == Vector3.INF:
			return
		if job.is_empty():
			mover.face(p)
		else:
			actor.face(p)

	## Oyuncunun ardından gelir (gap m geride).
	func follow_player(gap: float = 1.6) -> void:
		job = ""
		walking = false
		follow_gap = gap
		_repath = 0.0
		var p := cast.days.player if cast and cast.days else null
		if p and Vector2(p.global_position.x - position().x, p.global_position.z - position().z).length() > 12.0:
			place(p.global_position - p.forward_vector() * gap, p.global_position)
			follow_gap = gap

	func stop_follow() -> void:
		follow_gap = -1.0
		mover.stop()

	func tick(delta: float) -> void:
		if actor == null or not actor.visible:
			return
		if follow_gap >= 0.0:
			_tick_follow(delta)
			mover.tick(delta)
			return
		if not job.is_empty() and not walking:
			return
		mover.tick(delta)
		if walking and mover.arrived():
			if not loop_path.is_empty():
				mover.go(loop_path, cast.pace(loop_speed))
				return
			walking = false
			if after_face != Vector3.INF:
				mover.face(after_face)
			if not after_work.is_empty():
				work(after_work)

	func _tick_follow(delta: float) -> void:
		_repath -= delta
		if _repath > 0.0:
			return
		_repath = PrologueCast.FOLLOW_REPATH
		var p := cast.days.player
		if p == null:
			return
		var me := position()
		var target := p.global_position - p.forward_vector() * follow_gap
		var d := Vector2(target.x - me.x, target.z - me.z).length()
		var to_player := Vector2(p.global_position.x - me.x, p.global_position.z - me.z).length()
		if to_player <= follow_gap + 0.35 or d < 0.4:
			mover.stop(p.global_position)
			return
		# Geride kalınca koşar (oyuncunun koşusunu aşmadan).
		var speed := clampf(p.get_speed() + (0.6 if to_player > follow_gap + 2.5 else 0.15), 1.1, 3.4)
		mover.go([target], cast.pace(speed))


var days: PrologueDays
var people: Dictionary = {}
var animals: Dictionary = {}
var _allocator: ClipVariety.Allocator
var _stripped_mounts: Array[Node] = []


func _ready() -> void:
	_strip_mounts()


## Sahnenin cast'ını uygular: anılan kişiler kurulur (yoksa) ve yerlerine konur, anılmayanlar gizlenir. Kişi başına bir kare.
func apply(defs: Dictionary) -> void:
	for id: String in people:
		if not defs.has(id):
			(people[id] as Person).set_present(false)
	for id: String in defs:
		var def: Dictionary = defs[id] if defs[id] is Dictionary else {}
		if id.begins_with("dog") or id.begins_with("horse"):
			_apply_animal(id, def)
			continue
		var p := person(id)
		if p == null:
			p = _make(id)
			await get_tree().process_frame
			if not is_inside_tree():
				return
		_apply_def(p, def)


func _apply_def(p: Person, def: Dictionary) -> void:
	if bool(def.get("hidden", false)):
		# Gizlenen kişinin yürüyüşü ve döngüsü de biter (sonraki sahnede «Tipi»nin Börü'sü gibi yeniden yürütülür).
		p.loop_path = []
		p.walking = false
		p.follow_gap = -1.0
		p.set_present(false)
		return
	p.set_present(true)
	var at := days.point(def.get("at", "")) if def.has("at") else p.position()
	var face := days.point(def.get("face", "")) if def.has("face") else Vector3.INF
	if at == Vector3.INF:
		at = days.player.global_position + Vector3(2, 0, 2)
	p.place(at, face)
	p.loop_path = []
	if def.has("walk"):
		p.walk(days.points(def["walk"]), float(def.get("speed", 1.2)), str(def.get("work", "")), face)
		if bool(def.get("loop", false)):
			p.loop_path = days.points(def["walk"])
			p.loop_speed = float(def.get("speed", 1.2))
	else:
		p.work(str(def.get("work", "stand")))
		if face != Vector3.INF:
			p.face_point(face)


func _make(id: String) -> Person:
	var a := CineActor.new()
	a.name = id.to_pascal_case()
	a.character_id = str(MODELS.get(id, id))
	a.build_on_ready = false
	add_child(a)
	a.build()
	a.ensure_idle([&"idle", &"walk", &"run"])
	var p := Person.new()
	p.id = id
	p.actor = a
	p.cast = self
	p.mover = StoryMover.new(a, days.world.call(&"get_terrain_shape") if days.world.has_method(&"get_terrain_shape") else null)
	people[id] = p
	return p


func person(id: String) -> Person:
	return people.get(id) as Person


## Her kare: kişilerin yürütücüleri ve hayvanlar.
func tick(delta: float) -> void:
	for id: String in people:
		(people[id] as Person).tick(delta)
	for id: String in animals:
		var a: Dictionary = animals[id]
		_tick_animal(a, delta)


## Konuşan kişi (söz başlarken): yürümüyorsa ve işi ayakta değilse dinleyene döner.
func talking(id: String, _seconds: float) -> void:
	var p := person(id)
	if p == null or not p.is_present() or p.walking or days.player == null:
		return
	if p.job.is_empty():
		p.face_point(days.player.global_position)


func hide_all() -> void:
	for id: String in people:
		(people[id] as Person).set_present(false)
	for id: String in animals:
		var node: Node3D = (animals[id] as Dictionary)["node"]
		if is_instance_valid(node):
			node.visible = false


func clear() -> void:
	for id: String in people:
		var p: Person = people[id]
		if is_instance_valid(p.actor):
			p.actor.queue_free()
	people.clear()
	for id: String in animals:
		var node: Node3D = (animals[id] as Dictionary)["node"]
		if is_instance_valid(node):
			node.queue_free()
	animals.clear()
	_restore_mounts()


func _exit_tree() -> void:
	_restore_mounts()


## Hız oyuncunun koşusunun altında (K105).
func pace(speed: float) -> float:
	return days.pace(speed) if days else speed


# --- Hayvanlar -------------------------------------------------------------------------------------------------

## Köpek (dog*) ya da at (horse*): {at, face, walk: [yer], speed, clip}.
func _apply_animal(id: String, def: Dictionary) -> void:
	var a: Dictionary = animals.get(id, {})
	if a.is_empty():
		var node: Node3D
		if id.begins_with("dog"):
			var scene := load(DOG_SCENE) as PackedScene if ResourceLoader.exists(DOG_SCENE) else null
			node = scene.instantiate() as Node3D if scene else Node3D.new()
		else:
			var horse := Horse.new()
			horse.coat_color = Color(def.get("coat", "#7a4a2a")) if def.get("coat") is String else Color(0.46, 0.27, 0.15)
			horse.blanket_color = Color(0.32, 0.2, 0.14)
			node = horse
		node.name = id.to_pascal_case()
		add_child(node)
		a = {"node": node, "path": [], "speed": 0.0, "anim": _find_anim(node), "clip": ""}
		animals[id] = a
		if not id.begins_with("dog"):
			_strip_mounts.call_deferred()
	var n: Node3D = a["node"]
	if bool(def.get("hidden", false)):
		n.visible = false
		return
	n.visible = true
	var at := days.point(def.get("at", ""))
	if at != Vector3.INF:
		n.global_position = at
	var face := days.point(def.get("face", "")) if def.has("face") else Vector3.INF
	if face != Vector3.INF:
		n.rotation.y = atan2(face.x - n.global_position.x, face.z - n.global_position.z)
	a["path"] = days.points(def.get("walk", []))
	a["speed"] = float(def.get("speed", 1.0))
	_play_animal(a, str(def.get("clip", "idle")))


func _find_anim(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for c in node.get_children():
		var f := _find_anim(c)
		if f:
			return f
	return null


func _play_animal(a: Dictionary, clip: String) -> void:
	var anim: AnimationPlayer = a.get("anim")
	if anim == null or str(a.get("clip", "")) == clip:
		return
	for name_try in [clip, clip.capitalize(), "idle"]:
		if anim.has_animation(name_try):
			anim.play(name_try, 0.3)
			a["clip"] = clip
			return


func _tick_animal(a: Dictionary, delta: float) -> void:
	var n: Node3D = a["node"]
	if not is_instance_valid(n) or not n.visible:
		return
	var path: Array = a["path"]
	if path.is_empty():
		return
	var next: Vector3 = path[0]
	var to := Vector2(next.x - n.global_position.x, next.z - n.global_position.z)
	if to.length() < 0.3:
		path.remove_at(0)
		if path.is_empty():
			_play_animal(a, "idle")
		return
	var speed := pace(float(a["speed"]))
	var step := to.normalized() * minf(speed * delta, to.length())
	var p := n.global_position + Vector3(step.x, 0.0, step.y)
	p.y = days.ground_y(p.x, p.z)
	n.global_position = p
	n.rotation.y = lerp_angle(n.rotation.y, atan2(to.x, to.y), 1.0 - exp(-6.0 * delta))
	_play_animal(a, "walk" if speed < 2.0 else "trot")


## Köpeği bir yola sürer (köpek* kimliği).
func animal_walk(id: String, path: Array, speed: float) -> void:
	var a: Dictionary = animals.get(id, {})
	if a.is_empty():
		return
	a["path"] = path
	a["speed"] = speed


func animal(id: String) -> Node3D:
	return (animals.get(id, {}) as Dictionary).get("node") as Node3D


# --- Binekler --------------------------------------------------------------------------------------------------

## Önsöz'ün günlerinde binilmez: kampın ve obanın atları binek grubundan çıkar (dönüşte geri girer).
func _strip_mounts() -> void:
	if not is_inside_tree():
		return
	for n in get_tree().get_nodes_in_group(Rideable.GROUP):
		if not _stripped_mounts.has(n):
			n.remove_from_group(Rideable.GROUP)
			_stripped_mounts.append(n)


func _restore_mounts() -> void:
	for n in _stripped_mounts:
		if is_instance_valid(n) and not n.is_queued_for_deletion() and not n.is_in_group(Rideable.GROUP):
			n.add_to_group(Rideable.GROUP)
	_stripped_mounts.clear()
