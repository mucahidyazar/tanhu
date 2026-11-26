class_name FlockLamb
extends FlockStep
## «Çobanlık» 8: balçıktaki kuzu ve tilki (tür «flock_lamb»). Eksik kuzunun izi sazlığa gider (yön: balçık); yaklaşınca Yançi «Sazlıkta!
## Balçığa saplanmış!» der: kuzu sazın dibinde balçığa gömülü, meleyerek çırpınır. Az ötede tilki bekler: Luhun «Tilki! Kuzuyu bekliyor!»
## Yanına atılan ok (ok tilkiye değmez: hedef değildir) ya da üstüne koşmak (UZAKTA olsa da yaklaşınca) kaçırır: Luhun «Kaçtı!» (tilki vurulmaz,
## kan yok). Kuzu E basılı tutularak çekilir (Pull_Radish; pull_s sn, bırakınca gevşer), çıkan kuzu kucakta taşınır; sürüye varınca bırakılır,
## Mete «Kırk.» der. Sıra serbesttir (önce çekmek de olur), ceza yoktur. Veri: mud, fox, fox_scare_m, arrow_scare_m, found_near, pull_s,
## lines {found, fox, gone, forty}, deliver_m. Kuzu çıkınca Luhun sürüyü sazlığa doğru getirir (meet: buluşma yeri; sürücü yalnız Luhun'dur,
## kucağında kuzuyla gelen çocuktan sürü kaçmaz): kuzu sürüye yarı yolda katılır.

const PULL_CLIP := "pull_radish"
const BLEAT_EVERY := Vector2(2.2, 4.0)

var _lamb_mi: MultiMeshInstance3D
var _fox: StoryFox
var _found := false
var _fox_said := false
var _fox_gone := false
var _pulling := false
var _pull := 0.0
var _free := false
var _delivered := false
var _bleat_left := 1.0
var _t := 0.0
var _linked := false
var _pull_anim_left := 0.0
var _meeting := false


func start() -> void:
	phase = "trail"
	var mud := point(step.get("mud", "lake_mud"))
	_build_lamb(mud)
	_fox = StoryFox.new()
	_fox.name = "Fox"
	_fox.ground = scene._shape()
	scene._root.add_child(_fox)
	_fox.place(point(step.get("fox", "lake_fox")), mud)
	_fox.fled.connect(_on_fox_fled)
	for id: String in ["luhun_child", "yanchi_child"]:
		var m := mover(id)
		if m:
			m.go([mud + Vector3(-6.0 if id == "luhun_child" else -4.0, 0.0, 5.0 if id == "luhun_child" else 7.0)], pace(2.6))
	set_drivers([])
	var a := atmos()
	if a:
		a.music_layers({"kopuz": -80.0, "kaval": -80.0}, 3.0)
	_link_arrows()


func _link_arrows() -> void:
	if _linked:
		return
	var archer := player().archer()
	if archer and archer.field:
		_linked = true
		archer.field.arrow_landed.connect(_on_arrow_landed)


func _on_arrow_landed(at_point: Vector3) -> void:
	if is_instance_valid(_fox) and _fox.is_waiting() and flat(at_point, _fox.global_position) <= float(step.get("arrow_scare_m", 6.0)):
		_fox.scare(at_point)


func _on_fox_fled() -> void:
	if _fox_gone:
		return
	_fox_gone = true
	if is_instance_valid(_fox):
		sfx("sfx_fox_bark", _fox.global_position, -2.0)
	say(str((step.get("lines", {}) as Dictionary).get("gone", "fox_gone")))
	_update_objective()


func tick(delta: float) -> void:
	_t += delta
	tick_followers(delta)
	_link_arrows()
	var mud := point(step.get("mud", "lake_mud"))
	var lines: Dictionary = step.get("lines", {})
	if not _found and near(mud, float(step.get("found_near", 11.0))):
		_found = true
		phase = "found"
		var wait := say(str(lines.get("found", "lamb_found")))
		at(clock + maxf(wait, 0.8), func() -> void:
			if not _fox_gone and is_instance_valid(_fox) and _fox.is_waiting():
				_fox_said = true
				say(str(lines.get("fox", "fox")))
				E21Shots.shot(scene, "flock_lamb", 0.8))
		_update_objective()
	# Üstüne koşan çocuk tilkiyi kaçırır.
	if is_instance_valid(_fox) and _fox.is_waiting() and _found and near(_fox.global_position, float(step.get("fox_scare_m", 7.0))):
		_fox.scare(player().global_position)
	_tick_lamb(delta, mud)
	_tick_pull(delta)
	if _meeting and not _delivered:
		_tick_meeting()
	if _free and not _delivered:
		var h := herd()
		if h and near(h.flock_center(), float(step.get("deliver_m", 6.0))):
			_deliver()


func _tick_lamb(delta: float, mud: Vector3) -> void:
	if _lamb_mi == null:
		return
	var mm := _lamb_mi.multimesh
	var s := 0.72
	var xf: Transform3D
	var amp := 0.0
	if _free:
		# Kucakta: göğsün önünde, yan yatık.
		var p := player()
		var fwd := p.forward_vector()
		var at_point := p.global_position + fwd * 0.32 + Vector3.UP * 0.62
		xf = Transform3D(Basis(Vector3.UP, p.get_facing_yaw() + PI * 0.5) * Basis(Vector3.BACK, 0.25).scaled(Vector3.ONE * s * 0.85), at_point)
	else:
		var rock := sin(_t * 7.0) * 0.1
		xf = Transform3D(Basis(Vector3.UP, 1.2) * Basis(Vector3.FORWARD, rock).scaled(Vector3.ONE * s), mud + Vector3(0.0, -0.22 + _pull * 0.18, 0.0))
		amp = 0.55
		_bleat_left -= delta
		if _bleat_left <= 0.0:
			_bleat_left = randf_range(BLEAT_EVERY.x, BLEAT_EVERY.y)
			sfx("sfx_lamb_bleat", mud, -3.0)
	mm.set_instance_transform(0, xf)
	mm.set_instance_custom_data(0, Color(fposmod(_t * 2.2, 1.0), amp, 0.0, 0.37))


func _tick_pull(delta: float) -> void:
	if _free:
		return
	if _pulling:
		if is_holding() and near(point(step.get("mud", "lake_mud")), float(step.get("pull_reach", 2.0))):
			_pull += delta / float(step.get("pull_s", 2.4))
			_pull_anim_left -= delta
			if _pull_anim_left <= 0.0:
				_pull_anim_left = 1.8
				player().get_avatar().play_job(PULL_CLIP)
				sfx("sfx_mud_pull", point(step.get("mud", "lake_mud")), -2.0)
		else:
			_release_pull()
		if _pull >= 1.0:
			_free_lamb()
	else:
		_pull = maxf(_pull - delta * 0.3, 0.0)


func interaction() -> Dictionary:
	if _free or _pulling or not near(point(step.get("mud", "lake_mud")), float(step.get("pull_reach", 2.0))):
		return {}
	return {"key": "E", "label": "Çek (basılı)", "run": _begin_pull}


func _begin_pull() -> void:
	_pulling = true
	phase = "pull"
	var p := player()
	p.set_active(false)
	p.carry(true)
	var to := point(step.get("mud", "lake_mud")) - p.global_position
	p.get_avatar().rotation.y = atan2(to.x, to.z)
	_pull_anim_left = 0.0


func _release_pull() -> void:
	_pulling = false
	phase = "found"
	var p := player()
	p.carry(false)
	p.get_avatar().set_locomotion(0.0)
	p.spawn_at(p.global_position, p.get_avatar().rotation.y)
	p.set_active(true)


func _free_lamb() -> void:
	_free = true
	_release_pull()
	phase = "carry"
	state()["carrying"] = true
	sfx("sfx_lamb_bleat", player().global_position, 0.0)
	_update_objective()
	# Luhun sürüyü buluşma yerine getirir.
	var h := herd()
	if h:
		var meet := point(step.get("meet", [322.0, -2.0]))
		var from := h.flock_center()
		h.drive_along(PackedVector2Array([Vector2(from.x, from.z), Vector2(meet.x, meet.z)]), 6.0)
		_meeting = true


## Buluşma: sürücü yalnız Luhun (sürünün gerisinde, buluşmaya göre); kucaktaki kuzuyla gelen çocuk sürüyü kaçırmaz.
func _tick_meeting() -> void:
	var h := herd()
	var luhun := actor("luhun_child")
	if h == null or luhun == null:
		return
	h.set_drivers([luhun] as Array[Node3D], PackedFloat32Array([DRIVER_KID + 2.0]))
	var c := h.flock_center()
	var fwd := h.sim.path_tangent(Vector2(c.x, c.z))
	var goal := c - Vector3(fwd.x, 0.0, fwd.y) * (h.sim.flock_spread() + 2.5)
	escort("luhun_child", Vector3(goal.x, scene._ground_y(goal.x, goal.z), goal.z), 3.0)


func _deliver() -> void:
	_delivered = true
	_meeting = false
	clear_drivers()
	phase = "done"
	state()["carrying"] = false
	var h := herd()
	var lamb := int(state().get("lamb", -1))
	if h and lamb >= 0:
		var p := player().global_position + player().forward_vector() * 1.0
		h.put_back(lamb, p)
	if _lamb_mi:
		_lamb_mi.visible = false
	var wait := say(str((step.get("lines", {}) as Dictionary).get("forty", "forty")))
	at(clock + maxf(wait, 0.8) + 0.4, done)


func _update_objective() -> void:
	if _free:
		set_objective(step.get("carry_objective"))
		set_hint(step.get("carry_hint"))
	elif _found:
		set_objective(step.get("pull_objective"))
		set_hint(step.get("fox_hint") if not _fox_gone else step.get("pull_hint"))


## Kuzunun görüntüsü: sürünün ağı ve malzemesiyle tek örnek (balçıkta çırpınır, kucakta durur).
func _build_lamb(mud: Vector3) -> void:
	var h := herd()
	if h == null or h.instance == null:
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = h.instance.multimesh.mesh
	mm.instance_count = 1
	_lamb_mi = MultiMeshInstance3D.new()
	_lamb_mi.name = "StuckLamb"
	_lamb_mi.multimesh = mm
	_lamb_mi.material_override = h.instance.material_override
	_lamb_mi.custom_aabb = AABB(Vector3(-600.0, -60.0, -600.0), Vector3(1200.0, 160.0, 1200.0))
	scene._root.add_child(_lamb_mi)
	_tick_lamb(0.0, mud)


func target(_from: Vector3) -> Vector3:
	if _free:
		var h := herd()
		return h.flock_center() if h else Vector3.INF
	return point(step.get("mud", "lake_mud"))


func cleanup() -> void:
	if _pulling:
		_release_pull()
	var archer := player().archer() if is_instance_valid(player()) else null
	if archer and archer.field and archer.field.arrow_landed.is_connected(_on_arrow_landed):
		archer.field.arrow_landed.disconnect(_on_arrow_landed)
	if is_instance_valid(_fox):
		_fox.queue_free()
	if is_instance_valid(_lamb_mi):
		_lamb_mi.queue_free()
	if not _delivered:
		# Adım yarıda kaldıysa kuzu sürüye döner (sayı kırk kalsın).
		var h := herd()
		var lamb := int(state().get("lamb", -1))
		if h and lamb >= 0 and h.sim.hidden[lamb] == 1:
			h.put_back(lamb, h.flock_center())


func preset() -> void:
	var h := herd()
	var lamb := int(state().get("lamb", -1))
	if h and lamb >= 0 and h.sim.hidden[lamb] == 1:
		h.put_back(lamb, h.flock_center())
	player().spawn_at(point("count_after") + Vector3(4.0, 0.0, 3.0), -PI * 0.5)


func autoplay(bot: Node, _delta: float) -> void:
	var mud := point(step.get("mud", "lake_mud"))
	match phase:
		"trail", "found":
			# Önce tilkiyi kaçırır (üstüne yürür), sonra kuzuyu çeker.
			if is_instance_valid(_fox) and _fox.is_waiting() and _found:
				bot.call(&"follow", [_fox.global_position], "fox", true, 2.0)
				return
			# Tilkiyi kaçırdıktan sonra (ya da balçığın yakınındayken) doğrudan balçığa; yolun başına dönmez.
			var route: Array = [mud] if _fox_gone or near(mud, 30.0) else ["count_gate", mud]
			if bool(bot.call(&"follow", route, "mud_%s" % str(_fox_gone), true, 1.2)):
				var d := interaction()
				if not d.is_empty():
					bot.call(&"hold", true)
					(d["run"] as Callable).call()
		"pull":
			bot.call(&"hold", true)
		"carry":
			bot.call(&"hold", false)
			var h := herd()
			if h:
				bot.call(&"follow", [h.flock_center()], "deliver_%d" % int(_t / 4.0), false, 3.0)
		_:
			bot.call(&"hold", false)
			bot.call(&"halt")


func line_keys() -> Array:
	return (step.get("lines", {}) as Dictionary).values()
