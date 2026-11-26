extends PrologueStep
## «Kuzular»ın adımı (lambs_find; Önsöz, 9 Nisan sabahı, K110; story.md §3 «Göl Obası'nda üç gün»; e21-atmosphere.md «Kuzular»): tipi gecesi
## açıkta doğan dört kuzu obanın güney yamacında, her biri anasının yanında. Kuzular meler (konumlu, ≈30 m'den duyulur), analar çağırır,
## kardaki iz yurdun kapısından anaya gider. Kuzu E ile kucağa alınır (yalnız yürüme; days.carry("lamb")), anası ardından gelir; yurdun
## kapısında E ile Ana'ya verilir, Ana sayar («Bir», «İki», «Üç»). Üçüncüden sonra Ana dördüncüyü gösterir («Biri daha meliyor. Dere
## tarafında.»); o kuzu donmuştur: kapıda Ana «Bu donmuş.» der, kuzu yurdun ocağının yanına konur (E), ağzına üç damla ilk süt damlatılır
## (E), kuzu kıpırdar ve meler; Ana «Dört. Hepsi sağ.», ozan «Tipi gecesi doğan iyi yaşar.» der, adım biter.
## Çevrede yaşam: Ağabey ilk kuzudan sonra at bağından gelir («Atlar tamam. Kır kısrak da taylamış.»), ozan kapısında kopuzunu kurar; yanından
## geçen Çocuk'a «Kopuzun teli de üşüdü.» der (bir kez). Ana ilk kuzuya yaklaşınca seslenir: «Kucağına al, anası ardından gelir.»
## Ceza yoktur: kuzu kaçmaz, düşmez; geç bulunan kuzu yalnız sözün sırasıdır. Yerler adımın verisindedir (lambs: [{at, ewe, frozen}], home,
## hearth; işaret adı ya da [x, z]); yoksa places.json'un lamb_slope, lamb_slope_far, gol_family_door, gol_family_yurt'u.

const BLEAT_PLACEHOLDER := "res://audio/sfx/gen/lamb.wav"
const EWE_PLACEHOLDER := "res://audio/sfx/gen/sheep.wav"
## Ana'nın «Kucağına al» sözü: ilk kuzuya bu kadar yaklaşınca (m).
const CARRY_CALL_M := 7.0
## Ozanın sözü: yanından bu uzaklıkta geçince (m).
const BARD_NEAR_M := 8.5
## Süt damlatmanın klibi (diz çöküp eğilir) ve damlalar arası en az süre (sn).
const DRIP_CLIP := "ground_kneel_heels"
const DRIP_GAP := 0.7

var flock: LambFlock
var view: LambsView

var _said_carry := false
var _said_kopuz := false
var _said_brother := false
var _said_last := false
var _frozen_told := false
var _drip_left := 0.0
var _finale := false
var _root: Node3D
var _bot_wait := 0.0
var _bot_log := 0.0


static func check(p_step: Dictionary, _data: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	var lambs: Array = p_step.get("lambs", [])
	if lambs.size() != 4:
		out.append("%s: dört kuzu gerekir (%d)" % [p_step.get("id", "lambs"), lambs.size()])
	var frozen := 0
	for l: Variant in lambs:
		if (l as Dictionary).get("frozen", false):
			frozen += 1
	if frozen != 1:
		out.append("%s: bir donmuş kuzu gerekir" % p_step.get("id", "lambs"))
	return out


func line_keys() -> Array:
	return ["act0.lambs.carry", "act0.lambs.one", "act0.lambs.two", "act0.lambs.three", "act0.lambs.last", "act0.lambs.weak",
		"act0.lambs.four", "act0.lambs.bard", "act0.lambs.brother", "act0.lambs.kopuz"]


func start() -> void:
	flock = LambFlock.new(_layout())
	_root = Node3D.new()
	_root.name = "E21Lambs"
	(days.root() if days.root() else world()).add_child(_root)
	view = LambsView.new()
	view.flock = flock
	view.ground = func(x: float, z: float) -> float: return _ground_y(x, z)
	_root.add_child(view)
	view.build()
	view.carrier = null
	HearthCold.ensure(days)
	_start_life()
	phase = "find"
	_refresh_objective()
	E21Shots.shot(_root, "lambs_tracks", 4.0)


func cleanup() -> void:
	HearthProps.release_player_job(player())
	carry("")
	walk_mods({})
	if is_instance_valid(_root):
		_root.queue_free()
	_root = null


## Geliştirme --step ötesinden açılırken: kuzular yurtta.
func preset() -> void:
	pass


func tick(delta: float) -> void:
	if flock == null:
		return
	var p := player().global_position
	for e: Dictionary in flock.tick(delta, p, _player_forward()):
		var id := "sfx_lamb_bleat" if e["kind"] == "bleat" else "sfx_ewe_call"
		var ph := BLEAT_PLACEHOLDER if e["kind"] == "bleat" else EWE_PLACEHOLDER
		E21Sound.one_shot(_root, id, (e["at"] as Vector3) + Vector3(0.0, 0.5, 0.0), {"placeholder": ph, "max_m": LambFlock.HEAR_M,
			"db": float(e["db"]) * 0.35 + (-6.0 if e.get("frozen", false) else 0.0), "pitch_jitter": 0.06,
			"pitch": 1.25 if e["kind"] == "bleat" else 0.95})
	view.tick(delta)
	HearthProps.release_if_moving(player())
	_drip_left = maxf(_drip_left - delta, 0.0)
	# Ana ilk kuzuya yaklaşan Çocuk'a seslenir.
	if not _said_carry and flock.carrying < 0:
		for l in flock.lambs:
			if l["state"] == LambFlock.LOST and flat(l["at"], p) <= CARRY_CALL_M:
				_said_carry = true
				say("act0.lambs.carry")
				break
	# Ozan kapısında kopuzunu kurar: yanından geçene bir söz.
	if not _said_kopuz and flock.counted >= 1 and near(_bard_spot(), BARD_NEAR_M):
		_said_kopuz = true
		say("act0.lambs.kopuz")


func target(from: Vector3) -> Vector3:
	if flock == null or _finale:
		return Vector3.INF
	return flock.target(from, _frozen_told)


func interaction() -> Dictionary:
	if flock == null or _finale:
		return {}
	var p := player().global_position
	if flock.carrying < 0:
		var i := flock.lamb_in_reach(p)
		if i >= 0:
			return {"key": "E", "label": text({"tr": "Kucağına al", "en": "Pick up"}), "run": _pick.bind(i)}
		var fi := flock.frozen_index()
		if fi >= 0 and flock.state_of(fi) == LambFlock.BY_HEARTH and flock.near_hearth(p) and _drip_left <= 0.0:
			return {"key": "E", "label": text({"tr": "Süt damlat", "en": "Drip milk"}), "run": _drip}
		return {}
	if flock.carried_is_frozen() and _frozen_told:
		if flock.near_hearth(p):
			return {"key": "E", "label": text({"tr": "Ocağın yanına koy", "en": "Set it by the fire"}), "run": _lay}
		return {}
	if flock.near_home(p):
		return {"key": "E", "label": text({"tr": "Ana'ya ver", "en": "Give to Mother"}), "run": _deliver}
	return {}


func _pick(i: int) -> void:
	if not flock.pick_up(i):
		return
	# Kucaktaki kuzu: koşucunun eşyası (PrologueProps «lamb»); yoksa kuzunun kendi ağı çocuğun kollarında.
	view.carrier = null if carry("lamb") != null else player()
	E21Shots.log("kuzular: kuzu %d kucakta" % i)
	E21Shots.shot(_root, "lambs_carry", 2.0)
	walk_mods(LambFlock.CARRY_MODS)
	sfx("sfx_lamb_bleat", flock.lambs[i]["at"])
	_refresh_objective()


func _deliver() -> void:
	var r := flock.deliver()
	if not bool(r.get("ok", false)):
		return
	if bool(r.get("frozen", false)):
		# Donmuş kuzu: Ana söyler, Çocuk onu ocağa götürür (kucakta kalır).
		_frozen_told = true
		say("act0.lambs.weak")
		_refresh_objective()
		return
	carry("")
	walk_mods({})
	var n := int(r["count"])
	E21Shots.log("kuzular: %d/4 yurtta" % n)
	say(["act0.lambs.one", "act0.lambs.two", "act0.lambs.three"][clampi(n - 1, 0, 2)])
	if n == 1 and not _said_brother:
		_said_brother = true
		_brother_arrives()
	if flock.remaining_lost() == 1 and not _said_last:
		_said_last = true
		at(clock + 1.6, func() -> void: say("act0.lambs.last"))
	_refresh_objective()


func _lay() -> void:
	if not flock.lay_by_hearth():
		return
	E21Shots.shot(_root, "lambs_hearth", 1.2)
	carry("")
	walk_mods({})
	_refresh_objective()


func _drip() -> void:
	var r := flock.drip()
	if not bool(r.get("ok", false)):
		return
	_drip_left = DRIP_GAP
	HearthProps.play_player(player(), DRIP_CLIP)
	_refresh_objective()
	if bool(r.get("warmed", false)):
		_finale = true
		E21Shots.log("kuzular: donmuş kuzu ısındı, dördü sağ")
		E21Shots.shot(_root, "lambs_all", 1.5)
		sfx("sfx_lamb_bleat", flock.hearth)
		var t := say_seq(["act0.lambs.four", "act0.lambs.bard"])
		at(clock + maxf(t, 1.5) + 0.8, done)


## Sabahın yaşamı: kar yavaş yavaş erir, yurtların keçesinden buhar yükselir; Ağabey at bağından gelir (ilk kuzudan sonra).
func _start_life() -> void:
	var melt: Dictionary = step.get("melt", {})
	if not melt.is_empty():
		days.set_snow(float(melt.get("snow", 0.75)), float(melt.get("seconds", 200.0)))
	for e: Variant in step.get("steam", []):
		var row: Array = e
		var yurt := world().get_node_or_null(NodePath(str(row[0]))) as Node3D
		if yurt == null:
			continue
		var steam := Fx.smoke(Vector2(2.6, 2.2), Vector2(0.5, 0.2))
		steam.name = "MorningSteam"
		var mat := steam.material_override as ShaderMaterial
		mat.set_shader_parameter(&"smoke_color", Color(1.0, 1.0, 1.0, 1.0))
		mat.set_shader_parameter(&"opacity", float(row[1]))
		mat.set_shader_parameter(&"rise_speed", 0.18)
		_root.add_child(steam)
		steam.global_position = yurt.global_position + Vector3(0.0, 2.2, 0.0)


func _brother_arrives() -> void:
	var b := person("older_brother")
	if b == null:
		return
	var path := points(step.get("brother_walk", []))
	if not path.is_empty():
		b.walk(path, pace(1.3), "stand", flock.home)
	at(clock + 3.5, func() -> void:
		b.face_point(player().global_position)
		say("act0.lambs.brother"))


func _refresh_objective() -> void:
	if flock == null:
		return
	var fi := flock.frozen_index()
	if fi >= 0 and flock.state_of(fi) == LambFlock.BY_HEARTH:
		set_objective({"tr": "Kuzunun ağzına süt damlat", "en": "Drip milk into the lamb's mouth"})
		set_detail("(%d/%d)" % [flock.drips, LambFlock.DRIPS])
		set_hint({"tr": "Ocağın yanında E.", "en": "Press E by the fire."})
		return
	if flock.carrying >= 0:
		if flock.carried_is_frozen() and _frozen_told:
			set_objective({"tr": "Kuzuyu ocağın yanına koy", "en": "Set the lamb by the fire"})
			set_hint({"tr": "Yurdun ocağı.", "en": "The yurt's hearth."})
		else:
			set_objective({"tr": "Kuzuyu yurda götür", "en": "Carry the lamb to the yurt"})
			set_hint({"tr": "Anası ardından gelir. Kucakta koşulmaz.", "en": "Its mother follows. No running with a lamb."})
		set_detail("(%d/4)" % flock.counted)
		return
	set_objective({"tr": "Kuzuları bul", "en": "Find the lambs"})
	set_detail("(%d/4)" % flock.counted)
	set_hint({"tr": "Melemeyi dinle; kardaki iz anaya gider.", "en": "Listen for the bleating; the tracks lead to the ewes."}
		if not _said_last else {"tr": "Dere tarafında, kısık bir meleme.", "en": "A faint bleat, down by the stream."})


## Bot: en yakın kayıp kuzuya yürür, alır, kapıya taşır, verir; donmuş kuzuyu ocağa koyar, süt damlatır.
func autoplay(bot: Node, delta: float) -> void:
	if flock == null or _finale:
		bot.call(&"halt")
		return
	_bot_wait = maxf(_bot_wait - delta, 0.0)
	if _bot_wait > 0.0:
		return
	var p := player().global_position
	var act := interaction()
	if not act.is_empty():
		bot.call(&"halt")
		bot.call(&"press_e")
		_bot_wait = 0.9
		return
	var goal := target(p)
	_bot_log -= delta
	if _bot_log <= 0.0:
		_bot_log = 3.0
		E21Shots.log("kuzular bot: oyuncu (%.1f, %.1f) hedef %s taşıyor %d" % [p.x, p.z, str(goal), flock.carrying])
	if goal == Vector3.INF:
		bot.call(&"halt")
		return
	bot.call(&"go_to", E21Bot.next_point(days, p, goal), flock.carrying < 0)


# --- Yardımcılar ---------------------------------------------------------------------------------

func _layout() -> Dictionary:
	var home := point(step.get("home", "gol_family_door"))
	var yurt := point(step.get("yurt", "gol_family_yurt"))
	var hearth := point(step["hearth"]) if step.has("hearth") else (yurt + (home - yurt).normalized() * 0.9 if home != Vector3.INF and yurt != Vector3.INF else home)
	var lambs: Array = []
	for e: Variant in step.get("lambs", []):
		var d: Dictionary = e
		var at := point(d.get("at"))
		var ewe := point(d["ewe"]) if d.has("ewe") else at + Vector3(0.8, 0.0, 0.35)
		lambs.append({"at": at, "ewe": ewe, "frozen": bool(d.get("frozen", false))})
	# Ağıl: kapının yanı, halıların ve ocağın değil (kapıdan yurdun duvarı boyunca 3,4 m, biraz dışarı).
	var pen := home
	if home != Vector3.INF and yurt != Vector3.INF:
		var out := Vector3(home.x - yurt.x, 0.0, home.z - yurt.z).normalized()
		var side := Vector3(-out.z, 0.0, out.x)
		pen = point(step["pen"]) if step.has("pen") else point([home.x + side.x * 3.4 + out.x * 0.8, home.z + side.z * 3.4 + out.z * 0.8])
	return {"seed": int(step.get("seed", 90409)), "home": home, "hearth": hearth, "pen": pen, "lambs": lambs}


func _bard_spot() -> Vector3:
	var b := person("bard")
	return b.position() if b else point(step.get("bard_at", "gol_bard_door"))


func _player_forward() -> Vector3:
	var pl := player()
	return pl.forward_vector() if pl.has_method(&"forward_vector") else Vector3.FORWARD


func _ground_y(x: float, z: float) -> float:
	return days.ground_y(x, z) if days else 0.0


