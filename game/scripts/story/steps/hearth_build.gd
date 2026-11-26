extends PrologueStep
## «Ocak»ın ateşi (hearth_build; Önsöz, 10 Nisan akşamı; K110; story.md §3; e21-atmosphere.md «Ocak»): menü ateşinin yerinde tipinin çatlattığı ocak
## (HearthCold). Çocuk odunu ocağın yanına bırakır (E), Ağabey heybeyi yere koyar; taşlar heybeden tek tek alınır (E) ve üçgen dizilir (E): ozan
## «Üç taş. Hep üç.», «Neden üç, biliyor musun? Bu gece anlatacağım.» Üç parça odun ocağa konur (E), ozan iki taşı verir («Al. Ak taşı kara taşa
## vur.»): Çocuk ocağın başına çöker, her E bir vuruştur (kıvılcım, sfx_flint_strike); ilk vuruştan 3–5 sn sonra kav tutuşur (HearthFire, K108;
## sfx_tinder_catch), Ana «Tuttu. Besle onu.» Ateş kalan üç odunla beslenir (E): her evrede ışığın yarıçapı genişler (≈2, 4, 7, 10 m), alev ve
## duman büyür; ışığa giren kişi menüdeki yerine yürür ve oturur (Ana 4 m'de, Baba 7 m'de «Işık bize de yetişti.», Ağabey 10 m'de). Ateş en büyük
## evreye varınca ozan «Şimdi oldu.» der ve kopuzu kaldırır, Ana «Gel, yanıma otur.»; Çocuk Ana'nın yanındaki yerine oturur (E). O anda ateş
## harlar ve menünün ateşine oturur (HearthFire.settle, 1,6 sn; kıvılcım patlaması altında kurulan ateş Camp/Campfire'a döner, duman söner),
## müzik kalmaz; sonra koşucunun sinemaya geçişi (days.to_cinema: kamera 1,6 sn'de menü kadrajına, sinema 0a'dan).
## Saat: ikindi altınından mavi saate (CLOCK_STEPS; ilk yıldızlar), ateşin yatakları evreyle (amb_fire_small → amb_fire_medium → menünün
## campfire_loop'u).

const LAY_REACH := 1.9
const SACK_REACH := 1.6
const STRIKE_GAP := 0.45
const STRIKE_CLIP := "ground_kneel_heels"
const SIT_REACH := 1.3
const CARRY_MODS := {"speed_k": 0.8, "can_run": false, "can_jump": false}
## Işığa giren kişi: [kimlik, CampNpcs düğümü, ışığı bekleme yeri (ateşe göre: açı derece, uzaklık m), söz].
const FAMILY := [
	["mother", "Mother", 214.0, 3.3, "", "warm"],
	["father", "Father", 300.0, 5.6, "act0.hearth.grow", "felt"],
	["older_brother", "OlderBrother", 120.0, 8.6, "", "stand"],
]
## Ateşin yatakları evreyle (0: tutuşma ve küçük, 2: orta; 3. evre menü ateşinin kendi çıtırtısıdır).
const FIRE_BEDS := ["amb_fire_small", "amb_fire_small", "amb_fire_medium"]
## Saatin görünür akışı: [olay, saat, sn].
const CLOCK_STEPS := {"start": ["18:35", 24.0], "lit": ["19:20", 36.0]}
## Harlamanın kıvılcımı ve oturuşun ışığı.
const FLARE_SPARKS := 46

var hc: HearthCold

var _gap := 0.0
var _sack: Node3D
var _pile: Node3D
var _wood_left := 0
var _carrying_stone := false
var _entered := {}
var _fire_bed_id := ""
var _overlay: OmniLight3D
var _smoke: MeshInstance3D
var _sat := false
var _bot_wait := 0.0


func line_keys() -> Array:
	return ["act0.hearth.three", "act0.hearth.why_three", "act0.hearth.strike", "act0.hearth.lit", "act0.hearth.grow",
		"act0.hearth.full", "act0.hearth.sit"]


func start() -> void:
	hc = HearthCold.ensure(days)
	hc.view.cracked = true
	_wood_left = 0
	_place_family()
	phase = "drop" if bool(days.results.get("wood_carried", false)) else "stones"
	if phase == "stones":
		_make_pile(6)
	_make_sack()
	var c: Array = CLOCK_STEPS["start"]
	clock_to(c[0], float(c[1]))
	_refresh()


func cleanup() -> void:
	HearthProps.release_player_job(player())
	carry("")
	walk_mods({})
	_set_fire_bed("")


func tick(delta: float) -> void:
	HearthProps.release_if_moving(player())
	_gap = maxf(_gap - delta, 0.0)
	_bot_wait = maxf(_bot_wait - delta, 0.0)
	if hc == null:
		return
	if hc.fire.lit:
		_check_light()
	if _overlay and is_instance_valid(_overlay):
		var now := hc.fire.light_now()
		_overlay.omni_range = maxf(float(now["range"]), 0.5)
		_overlay.light_energy = maxf(float(now["energy"]) - HearthFire.MENU_ENERGY, 0.0) * Campfire.flicker(clock, 1.3)


func target(_from: Vector3) -> Vector3:
	match phase:
		"drop", "lay", "strike", "feed":
			return _fire()
		"stones":
			return _sack.global_position if not _carrying_stone and is_instance_valid(_sack) else _fire()
		"sit":
			return days.seat_point("Child")
	return Vector3.INF


func interaction() -> Dictionary:
	if _gap > 0.0 or hc == null:
		return {}
	match phase:
		"drop":
			if near(_fire(), LAY_REACH + 0.6):
				return {"key": "E", "label": text({"tr": "Odunu bırak", "en": "Put the wood down"}), "run": _drop_wood}
		"stones":
			if _carrying_stone:
				if near(_fire(), LAY_REACH):
					return {"key": "E", "label": text({"tr": "Taşı diz", "en": "Set the stone"}), "run": _set_stone}
			elif is_instance_valid(_sack) and near(_sack.global_position, SACK_REACH):
				return {"key": "E", "label": text({"tr": "Taşı al", "en": "Take a stone"}), "run": _take_stone}
		"lay":
			if near(_fire(), LAY_REACH):
				return {"key": "E", "label": text({"tr": "Odunu koy", "en": "Lay the wood"}), "run": _lay_wood}
		"strike":
			if near(_fire(), LAY_REACH):
				return {"key": "E", "label": text({"tr": "Ak taşı kara taşa vur", "en": "Strike white on black"}), "run": _strike}
		"feed":
			if near(_fire(), LAY_REACH + 0.4) and _wood_left > 0 and hc.fire.grown():
				return {"key": "E", "label": text({"tr": "Ateşi besle", "en": "Feed the fire"}), "run": _feed}
		"sit":
			if near(days.seat_point("Child"), SIT_REACH):
				return {"key": "E", "label": text({"tr": "Otur", "en": "Sit down"}), "run": _sit}
	return {}


func _drop_wood() -> void:
	_gap = 0.5
	HearthProps.release(days.root() if days.root() else world(), "HeldWood")
	carry("")
	walk_mods({})
	_make_pile(6)
	sfx("sfx_stone_set", _fire(), -8.0)
	phase = "stones"
	_refresh()


func _take_stone() -> void:
	_gap = 0.5
	_carrying_stone = true
	carry("stone")
	walk_mods(CARRY_MODS)
	_refresh()


func _set_stone() -> void:
	_gap = 0.6
	_carrying_stone = false
	carry("")
	walk_mods({})
	var i := hc.fire.place_stone()
	var spot := _fire() + HearthFire.stone_offset(maxi(i, 0))
	sfx("sfx_stone_set", spot)
	_kneel()
	if hc.fire.stones_done():
		hc.view.cracked = true
		if is_instance_valid(_sack):
			_sack.queue_free()
		phase = "talk"
		set_objective({})
		set_hint({})
		E21Shots.shot(player(), "hearth_stones", 0.6)
		var t := say_seq(["act0.hearth.three", "act0.hearth.why_three"])
		at(clock + maxf(t, 1.0) + 0.3, func() -> void:
			phase = "lay"
			_refresh())
	else:
		_refresh()


func _lay_wood() -> void:
	_gap = 0.6
	hc.fire.lay_wood(HearthFire.LAY_PIECES)
	_wood_left = 6 - HearthFire.LAY_PIECES
	_update_pile()
	_kneel()
	phase = "talk"
	set_objective({})
	var t := say("act0.hearth.strike")
	at(clock + maxf(t, 0.8) + 0.2, func() -> void:
		phase = "strike"
		_refresh())


func _strike() -> void:
	_gap = STRIKE_GAP
	_kneel()
	var r := hc.fire.strike(days.scene_clock)
	if bool(r.get("spark", false)):
		hc.view.burst(1.0)
		sfx("sfx_flint_strike", _fire() + Vector3(0.0, 0.3, 0.0))
	if bool(r.get("caught", false)):
		_on_lit()


func _on_lit() -> void:
	E21Shots.log("ocak: kav tutuştu (%d vuruş)" % hc.fire.strikes)
	phase = "feed"
	E21Shots.shot(player(), "hearth_kindle", 0.5)
	sfx("sfx_tinder_catch", _fire() + Vector3(0.0, 0.3, 0.0))
	_set_fire_bed(FIRE_BEDS[0])
	music("")
	var c: Array = CLOCK_STEPS["lit"]
	clock_to(c[0], float(c[1]))
	var mother := person("mother")
	if mother:
		mother.face_point(_fire())
	say("act0.hearth.lit")
	result("hearth", "lit")
	_refresh()


func _feed() -> void:
	_gap = 0.7
	_wood_left -= 1
	_update_pile()
	_kneel()
	if not hc.fire.feed():
		return
	var s := hc.fire.stage
	E21Shots.log("ocak: evre %d, ışık %.0f m" % [s, HearthFire.RADII[s]])
	hc.view.burst(0.6 + 0.3 * float(s))
	E21Shots.shot(player(), "hearth_stage%d" % s, HearthFire.GROW_S + 0.3)
	if s < FIRE_BEDS.size():
		_set_fire_bed(FIRE_BEDS[s])
	if hc.fire.is_full():
		_on_full()
	_refresh()


func _on_full() -> void:
	phase = "full"
	set_objective({})
	set_hint({})
	# Harlama: kıvılcım patlaması; kurulan ateş menünün ateşine döner, fazla ışık ve duman oturuşta söner.
	_swap_to_menu_fire()
	var bard := person("bard")
	at(clock + 1.6, func() -> void:
		if bard:
			bard.work("kopuz")
			bard.face_point(_fire())
		var t := say("act0.hearth.full")
		at(clock + t + 0.4, func() -> void:
			var s := say("act0.hearth.sit")
			at(clock + s * 0.5, func() -> void:
				phase = "sit"
				set_objective({"tr": "Ana'nın yanına otur", "en": "Sit down by Mother"})
				set_hint({}))))


func _sit() -> void:
	if _sat:
		return
	_sat = true
	phase = "settle"
	var seat := days.seat_point("Child")
	var npcs := world().get_node_or_null(PrologueDays.CAMP_NPCS) as Node3D
	var child_node := npcs.get_node_or_null(^"Child") as Node3D if npcs else null
	var yaw := child_node.global_rotation.y if child_node else player().get_facing_yaw()
	HearthProps.release_player_job(player())
	player().set_active(false)
	player().sit_at(Transform3D(Basis(Vector3.UP, yaw), seat))
	result("hearth", "full")
	flag("onsoz_ocak", true)
	hc.fire.begin_settle()
	if _smoke:
		var tw := _smoke.create_tween()
		tw.tween_method(func(v: float) -> void:
			if is_instance_valid(_smoke):
				(_smoke.material_override as ShaderMaterial).set_shader_parameter(&"opacity", v), 0.6, 0.0, HearthFire.SETTLE_S)
	at(clock + HearthFire.SETTLE_S + 0.05, _to_cinema)


func _to_cinema() -> void:
	E21Shots.log("ocak: menünün ateşi, sinemaya geçiş")
	E21Shots.shot(player(), "hearth_menu", 1.7)
	if is_instance_valid(_overlay):
		_overlay.queue_free()
	if is_instance_valid(_smoke):
		_smoke.queue_free()
	_set_fire_bed("")
	days.to_cinema()


## Kurulan ateş menünün ateşine döner: Camp/Campfire açılır (alev, ışık, kıvılcım, çıtırtı menünündür), kurulan ateşin yerine yalnız oturuşta
## sönen fazla ışık (_overlay: harlamanın 10 m'si) ve duman kalır. Döndüğü an kıvılcım patlaması taşların değişini örter.
func _swap_to_menu_fire() -> void:
	var at_p := _fire()
	var burst := Fx.embers(FLARE_SPARKS)
	burst.one_shot = true
	burst.explosiveness = 0.85
	(days.root() if days.root() else world()).add_child(burst)
	burst.global_position = at_p + Vector3(0.0, 0.4, 0.0)
	burst.emitting = true
	days.get_tree().create_timer(3.0).timeout.connect(burst.queue_free)
	var size := HearthFire.smoke_size(3.0)
	_smoke = Fx.smoke(size, Vector2(-0.45, -0.12))
	_smoke.name = "SettleSmoke"
	(days.root() if days.root() else world()).add_child(_smoke)
	_smoke.global_position = at_p + Vector3(0.0, 0.4, 0.0)
	_overlay = OmniLight3D.new()
	_overlay.name = "FlareLight"
	_overlay.light_color = HearthView.LIGHT_COLOR
	_overlay.omni_attenuation = 0.45
	_overlay.shadow_enabled = false
	(days.root() if days.root() else world()).add_child(_overlay)
	_overlay.global_position = at_p + Vector3(0.0, 0.65, 0.0)
	hc.light_menu_fire()
	# Menünün ateşinin kendi çıtırtısı (campfire_loop) açılır; kurulan ateşin yatağı söner.
	_set_fire_bed("")
	if is_instance_valid(_pile):
		_pile.queue_free()


## Işığa giren kişi menüdeki yerine yürür ve oturur.
func _check_light() -> void:
	var r := HearthFire.light_radius(hc.fire.stage_f)
	for row: Array in FAMILY:
		var id := str(row[0])
		if _entered.has(id):
			continue
		var p := person(id)
		if p == null:
			continue
		if flat(p.position(), _fire()) <= r - 0.2:
			_entered[id] = true
			var seat := days.seat_point(str(row[1]))
			if seat != Vector3.INF:
				p.walk([seat], pace(1.15), "sit", _fire())
			if not str(row[4]).is_empty():
				p.face_point(_fire())
				say(str(row[4]))


func _place_family() -> void:
	var fire := _fire()
	for row: Array in FAMILY:
		var p := person(str(row[0]))
		if p == null:
			continue
		var a := deg_to_rad(float(row[2]))
		var spot := point([fire.x + cos(a) * float(row[3]), fire.z + sin(a) * float(row[3])])
		p.stop_follow()
		# Işığı beklerken kendi işinde: Ana ellerini ısıtır, Baba keçe onarır, Ağabey ayakta.
		p.walk([spot], pace(1.3), str(row[5]), fire)
	var bard := person("bard")
	var seat := days.seat_point("Elder")
	if bard and seat != Vector3.INF:
		bard.place(seat, fire)
		bard.work("sit")


func _make_sack() -> void:
	_sack = (days.root() if days.root() else world()).find_child("FeltSack", true, false) as Node3D
	if _sack == null:
		_sack = HearthProps.sack_node()
		(days.root() if days.root() else world()).add_child(_sack)
	var spot := point([_fire().x - 1.9, _fire().z + 1.6])
	_sack.reparent(days.root() if days.root() else world(), false)
	_sack.global_position = spot
	_sack.scale = Vector3.ONE
	_sack.rotation = Vector3.ZERO


func _make_pile(pieces: int) -> void:
	if is_instance_valid(_pile):
		_pile.queue_free()
	_pile = HearthProps.bundle_node()
	_pile.name = "HearthWoodPile"
	(days.root() if days.root() else world()).add_child(_pile)
	_pile.global_position = point([_fire().x + 1.5, _fire().z + 1.2])
	_wood_left = pieces
	_update_pile()


## Yığında kalan odun (görünen parça sayısı).
func _update_pile() -> void:
	if not is_instance_valid(_pile):
		return
	var shown := 0
	for c in _pile.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh is CapsuleMesh:
			(c as MeshInstance3D).visible = shown < _wood_left
			shown += 1


## Ateşin yatağı evreyle (koşucunun sesi: konumlu, r/2'de tam, r'de sessiz; yataklar en çok 3). "" kapatır.
func _set_fire_bed(id: String) -> void:
	if id == _fire_bed_id or days.sound == null:
		return
	if not _fire_bed_id.is_empty():
		days.sound.bed(_fire_bed_id, false, 0.0, 2.0)
	_fire_bed_id = id
	if not id.is_empty():
		days.sound.bed(id, true, -3.0, 2.0, _fire(), 30.0)


func _kneel() -> void:
	var d := Vector3(_fire().x - player().global_position.x, 0.0, _fire().z - player().global_position.z)
	if d.length() > 0.05:
		player().spawn_at(player().global_position, atan2(d.x, d.z))
	if String(player().work_role) != "e21_" + STRIKE_CLIP:
		HearthProps.play_player(player(), STRIKE_CLIP)


func _refresh() -> void:
	match phase:
		"drop":
			set_objective({"tr": "Odunu ocağın yanına bırak", "en": "Put the wood down by the hearth"})
			set_hint({})
		"stones":
			set_objective({"tr": "Üç taşı ocağa diz", "en": "Set the three stones in the hearth"})
			set_detail("%d/3" % hc.fire.stones)
		"lay":
			set_objective({"tr": "Odunu ocağa koy", "en": "Lay the wood in the hearth"})
			set_hint({})
		"strike":
			set_objective({"tr": "Ak taşı kara taşa vur", "en": "Strike the white stone on the black"})
			set_hint({"tr": "E: her vuruş bir kıvılcım.", "en": "E: every strike is a spark."})
		"feed":
			set_objective({"tr": "Ateşi odunla besle", "en": "Feed the fire with wood"})
			set_detail("%d/%d" % [maxi(hc.fire.stage, 0), HearthFire.RADII.size() - 1])


func autoplay(bot: Node, _delta: float) -> void:
	if phase in ["talk", "full", "settle"] or _bot_wait > 0.0:
		bot.call(&"halt")
		return
	var act := interaction()
	if not act.is_empty():
		bot.call(&"halt")
		bot.call(&"press_e")
		_bot_wait = 0.75 if phase != "strike" else STRIKE_GAP + 0.15
		return
	var t := target(player().global_position)
	if t != Vector3.INF:
		bot.call(&"go_to", E21Bot.next_point(days, player().global_position, t), false)
	else:
		bot.call(&"halt")


func preset() -> void:
	pass


func _fire() -> Vector3:
	return point(step.get("hearth", "gol_fire"))
