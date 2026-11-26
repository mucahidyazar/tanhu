class_name BoneCall
extends ChildhoodStep
## «Ak Kemik»in çağrısı (adım türü bone_call; Çocukluk, 20 Eylül MÖ 228 akşamı, dolunay doğarken; K110, story.md §5 «İki yeni gün»): sürü
## ağıla girmiş, obada akşam: ocakların dumanı, kapıdan sızan ateş ışığı, ağılda sağım, ovada Dailin'e gelen boyların ateşleri (BoneView).
## Yançi çağırır («Ay doğuyor! Ak kemik oynayalım!»), Mete aya bakar («Babam şimdi aya eğiliyor.»), Lan Hatun kapısından uyarır, çocuklar
## bağlama direğine koşar; oyuncu direğe varınca Luhun kuralı söyler, adım biter (bone_play başlar). Müzik susar (gece yalnız ortam:
## amb_moon_night, cırcır böcekleri; music_quiet), kemik ve direk kurulur.
## Veri (day1_bone.json): post, field, spots {kişi: yer}, run_speed, near (direğe varış, m), lines {moon, watch, rules}, fires [[x, z], ...],
## milker {actor, clip, face}, watcher {actor, face}, music_quiet.

const NEAR := 4.0
const RUN_SPEED := 3.0

var _view: BoneView
var _rules_said := false
var _rules_left := -1.0
var _laughed := false


func start() -> void:
	phase = "gather"
	_view = BonePlay.view_of(scene, true)
	if _view and _view.fire_count() == 0:
		_view.add_fires(points(step.get("fires", [])))
		_view.add_door_glows(points(step.get("door_glows", [])))
	if bool(step.get("music_quiet", false)) and scene.atmos:
		scene.atmos.music_quiet(true, 4.0)
	var lines: Dictionary = step.get("lines", {})
	# Mete aya bakar, Lan Hatun kapısından uyarır (çağrıdan sonra sırayla).
	at(float(step.get("moon_at", 3.6)), func() -> void: say(str(lines.get("moon", "moon"))))
	at(float(step.get("watch_at", 5.0)), func() -> void: say(str(lines.get("watch", "lan_watch"))))
	_send_children()
	_pose_life()


func tick(delta: float) -> void:
	if _view:
		_view.tick(delta, player().global_position if player() else Vector3.INF)
	if clock > 4.5:
		BoneView.shoot(scene, "e21_bone_evening")
	if not _laughed and clock > 1.6 and scene.atmos:
		_laughed = true
		var luhun := mover("luhun_child")
		if luhun:
			scene.atmos.sfx("sfx_kids_laugh", luhun.position(), -6.0)
	var post := point(step.get("post", "bone_post"))
	if not _rules_said and near(post, float(step.get("near", NEAR))) and clock > float(step.get("rules_after", 6.0)):
		_rules_said = true
		phase = "rules"
		var luhun_m := mover("luhun_child")
		if luhun_m:
			luhun_m.face(player().global_position)
		_rules_left = say(str((step.get("lines", {}) as Dictionary).get("rules", "rules"))) + 0.4
	if _rules_said:
		_rules_left -= delta
		if _rules_left <= 0.0 and (scene.voice == null or scene.voice.is_free()):
			done()


func target(_from: Vector3) -> Vector3:
	return point(step.get("post", "bone_post"))


func preset() -> void:
	var spots: Dictionary = step.get("spots", {})
	for id: String in spots:
		var m := mover(id)
		if m:
			m.place(point(spots[id]), 0.0)
			m.face(point(step.get("field", "bone_field")))
	var post := point(step.get("post", "bone_post"))
	if player() and post != Vector3.INF:
		player().spawn_at(post + Vector3(-1.4, 0.0, 0.6), deg_to_rad(90.0))
	_pose_life()


func cleanup() -> void:
	pass


func autoplay(bot: Node, _delta: float) -> void:
	BoneView.diag_step(self)
	var post := point(step.get("post", "bone_post"))
	if _rules_said or near(post, float(step.get("near", NEAR)) * 0.6):
		bot.call(&"halt")
		return
	bot.call(&"follow", [post], "bone_call", true)


static func check(p_step: Dictionary, data: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	var lines: Dictionary = data.get("lines", {})
	for key: String in ["moon", "watch", "rules"]:
		var line := str((p_step.get("lines", {}) as Dictionary).get(key, ""))
		if line.is_empty() or not lines.has(line):
			out.append("%s: satır yok: %s" % [p_step.get("id", ""), key])
	if not p_step.has("post") or not p_step.has("field"):
		out.append("%s: post ve field gerekli" % p_step.get("id", ""))
	return out


func line_keys() -> Array:
	return (step.get("lines", {}) as Dictionary).values()


## Çocuklar direğin yanındaki yerlerine koşar (gülüşerek).
func _send_children() -> void:
	var spots: Dictionary = step.get("spots", {})
	for id: String in spots:
		var m := mover(id)
		if m:
			m.go([point(spots[id])], pace(float(step.get("run_speed", RUN_SPEED))))


## Obanın akşamı: ağılda sağan kadın (diz çökmüş), kapısında bakan Lan Hatun.
func _pose_life() -> void:
	var milker: Dictionary = step.get("milker", {})
	if not milker.is_empty():
		var id := str(milker.get("actor", ""))
		var m := mover(id)
		if m and milker.has("face"):
			var yaw := CampNpcs.facing_yaw(m.position(), point(milker["face"]))
			m.place(m.position(), 0.0 if is_nan(yaw) else yaw)
		pose(id, str(milker.get("clip", "ground_kneel_heels")))
	var watcher: Dictionary = step.get("watcher", {})
	if not watcher.is_empty():
		var w := mover(str(watcher.get("actor", "lan_hatun")))
		if w:
			w.face(point(watcher.get("face", "bone_post")))
