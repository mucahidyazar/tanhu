class_name TallyDogsStep
extends ChildhoodStep
## Ebe Obası'na yürüyüş ve köpek görgüsü (adım türü tally_dogs; K110 «yurda yaklaşırken köpeği tutturmak bozkır görgüsüdür»): kuruyan dere
## boyunca kuzeye. Obaya yaklaşınca iki köpek kalkar, havlar, yolun önüne geçer (TallyDogs; ısırmaz, değmez; seslenmeden obaya girilmez:
## bekleme çemberi oyuncunun engelidir). Oyuncu durur ve E ile seslenir: «Köpeğinizi tutun!»; Hereka yurdundan çıkar, köpeklerin yanına gelir,
## onları tutar (köpekler yanına gider, susar): «Tuttum, gel. Kimin oğlusun sen?». Adım Hereka'nın sözü başlayınca biter (tally_visit).
## Veri: goal (yol), keeper (Hereka'nın kimliği), keeper_speed, hold_clip, lines {dogs, held}, objectives {walk, stop, stop_hint}.

const KEEPER := "hereka_young"

var _camp: TallyCamp
var _fence := Vector3.ZERO
var _called := false
var _held := false
var _held_left := -1.0
var _dogs_t := 0.0
var _diag_t := 0.0


func start() -> void:
	phase = "walk"
	_camp = TallyCamp.of(scene, true)


func tick(delta: float) -> void:
	if _camp == null:
		return
	if not _camp.is_built():
		_camp.build_some()
		return
	var p := player()
	_camp.tick(delta, p.global_position, p.get_speed())
	var dogs := _camp.dogs
	if dogs == null:
		return
	_sync_fence(dogs.fence())
	var obj: Dictionary = step.get("objectives", {})
	match phase:
		"walk":
			if dogs.blocks():
				phase = "dogs"
				set_objective(obj.get("stop", {"tr": "Dur ve seslen", "en": "Stop and call out"}))
				set_hint(obj.get("stop_hint", {}))
		"dogs":
			_dogs_t += delta
			if _dogs_t > 0.8 and dogs.state == TallyDogs.State.BLOCK and dogs.nearest_distance(Vector2(p.global_position.x, p.global_position.z)) < 7.0:
				BoneView.shoot(scene, "e21_tally_dogs")
		"keeper":
			var keeper := mover(str(step.get("keeper", KEEPER)))
			if keeper and flat(keeper.position(), p.global_position) < 9.0:
				BoneView.shoot(scene, "e21_tally_keeper")
			if keeper and keeper.arrived():
				_hold_dogs()
		"held":
			_held_left -= delta
			if _held_left <= 0.0:
				done()


func target(_from: Vector3) -> Vector3:
	return point(step.get("goal", "ebe_call")) if phase == "walk" else Vector3.INF


## Oyuncunun E'si: köpekler yolu keserken, durmuşken ve yakınken «Köpeğinizi tutun!».
func interaction() -> Dictionary:
	if _called or _camp == null or _camp.dogs == null:
		return {}
	var p := player()
	if not _camp.dogs.can_call(Vector2(p.global_position.x, p.global_position.z), p.get_speed()):
		return {}
	var labels: Dictionary = step.get("labels", {})
	return {"key": "E", "label": text(labels.get("call", {"tr": "Seslen", "en": "Call out"})), "run": _call_out}


func preset() -> void:
	var camp := TallyCamp.of(scene, true)
	if camp:
		camp.build_all()
		if camp.dogs:
			camp.dogs.call_out()
			camp.dogs.hold(_flat(point(step.get("keeper_at", "hereka_door"))))
			camp.dogs.calm()
	TallyErrand.give_curd(scene.inventory)
	var keeper := mover(str(step.get("keeper", KEEPER)))
	if keeper:
		keeper.place(point(step.get("keeper_at", "hereka_door")), 0.0)
	if player():
		player().spawn_at(point(step.get("goal", "ebe_call")), PI)


func cleanup() -> void:
	_sync_fence(Vector3.ZERO)


func autoplay(bot: Node, delta: float) -> void:
	_diag_t -= delta
	if _diag_t <= 0.0:
		_diag_t = 2.0
		var pl := player()
		var near_dog := _camp.dogs.nearest_distance(Vector2(pl.global_position.x, pl.global_position.z)) if _camp and _camp.dogs else -1.0
		BoneView.diag("tally_dogs %.1f · %s · köpek %s %.1f m · konum %s · duruş %d · etkin %s · hız %.2f" % [clock, phase,
			TallyDogs.state_name(_camp.dogs.state) if _camp and _camp.dogs else "-", near_dog, pl.global_position.snapped(Vector3.ONE * 0.1),
			pl.get_stance(), pl.is_active(), pl.get_speed()])
	match phase:
		"walk":
			bot.call(&"follow", points(step.get("route", ["dry_stream_south", "dry_stream_north", "ebe_call"])), "tally_walk", true)
		"dogs":
			# Görgü: köpeklerin önüne dek yürür (yolu kesen köpeklere birkaç adım), durur, sonra seslenir.
			var p := player()
			var dogs := _camp.dogs if _camp else null
			if dogs and not _called and dogs.nearest_distance(Vector2(p.global_position.x, p.global_position.z)) > float(step.get("bot_call_m", 4.6)):
				bot.call(&"follow", [point(step.get("goal", "ebe_call")) + (point("ebe_center") - point(step.get("goal", "ebe_call"))).normalized() * 3.0],
					"tally_dogs_near", false)
				return
			bot.call(&"halt")
			if not _called and p.get_speed() <= TallyDogs.STILL_SPEED and clock > 0.0:
				bot.call(&"interact")
		_:
			bot.call(&"halt")


static func check(p_step: Dictionary, data: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	var lines: Dictionary = data.get("lines", {})
	for key: String in ["dogs", "held"]:
		var line := str((p_step.get("lines", {}) as Dictionary).get(key, ""))
		if not lines.has(line):
			out.append("%s: satır yok: %s" % [p_step.get("id", ""), key])
	if not (data.get("actors", {}) as Dictionary).has(str(p_step.get("keeper", KEEPER))):
		out.append("%s: Hereka kişilerde yok" % p_step.get("id", ""))
	return out


func line_keys() -> Array:
	return (step.get("lines", {}) as Dictionary).values()


## «Köpeğinizi tutun!»: köpekler hırlar, Hereka kapıdan çıkıp köpeklerin yanına gelir.
func _call_out() -> void:
	if _called or not _camp.dogs.call_out():
		return
	_called = true
	phase = "keeper"
	set_objective(step.get("objectives", {}).get("wait", {"tr": "Bekle", "en": "Wait"}))
	set_hint({})
	say(str((step.get("lines", {}) as Dictionary).get("dogs", "dogs")))
	var keeper := mover(str(step.get("keeper", KEEPER)))
	if keeper:
		var dogs_mid := (_camp.dogs.pos[0] + _camp.dogs.pos[1]) * 0.5
		var p := _flat(player().global_position)
		var stand := dogs_mid + (p - dogs_mid).normalized() * 0.9
		var route := points(step.get("keeper_route", ["hereka_door"]))
		route.append(Vector3(stand.x, 0.0, stand.y))
		keeper.go(points_on_ground(route), pace(float(step.get("keeper_speed", 1.7))))


## Hereka köpekleri tutar: eğilir, köpekler yanına gelir ve susar; «Tuttum, gel.»
func _hold_dogs() -> void:
	if _held:
		return
	_held = true
	phase = "held"
	var keeper := mover(str(step.get("keeper", KEEPER)))
	var here := _flat(keeper.position()) if keeper else _flat(point("hereka_door"))
	_camp.dogs.hold(here)
	_sync_fence(Vector3.ZERO)
	if keeper and player():
		keeper.face(player().global_position)
	var clip := str(step.get("hold_clip", "crouch_pick_place_f"))
	if not clip.is_empty():
		pose(str(step.get("keeper", KEEPER)), clip)
		at(clock + 1.1, func() -> void: unpose(str(step.get("keeper", KEEPER))))
	var seconds := say(str((step.get("lines", {}) as Dictionary).get("held", "dogs_held")))
	_held_left = minf(seconds, 1.2)


## Bekleme çemberi oyuncunun engelidir (köpekler yolu keserken); değişince oyuncunun engelleri yenilenir.
func _sync_fence(want: Vector3) -> void:
	var p := player()
	if p == null or want == _fence:
		return
	if _fence != Vector3.ZERO:
		p.extra_obstacles.erase(_fence)
	_fence = want
	if _fence != Vector3.ZERO:
		p.extra_obstacles.append(_fence)
	p.refresh_obstacles()


func points_on_ground(list: Array) -> Array:
	var out: Array = []
	for v: Variant in list:
		var q := v as Vector3
		out.append(point([q.x, q.z]))
	return out


static func _flat(p: Vector3) -> Vector2:
	return Vector2(p.x, p.z)
