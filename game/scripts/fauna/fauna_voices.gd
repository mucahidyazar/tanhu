class_name FaunaVoices
extends Node3D
## Hayvan sesleri (ses-tasarimi.md §6.2 «L3 Serpinti», §6.5, §7.4; audio.md §4 «Hayvan sesleri»; K3, K65; Yol Haritası fauna-sound-bank): iç haritanın
## hayvan sesini tek yerden çalar. İki kaynak vardır: FaunaDirector'un olayları (ürken ceylanın, maralın, yaban keçisinin alarmı; köpeğin kurda
## uyarısı; yaban domuzunun homurtusu; kurttan kaçan sürünün sesi) ve katmanın serpinti çizelgesi (fauna.json «voices»: tür, rol, evre ve saat,
## aralık, kaynak). Simülasyonda hayvan varsa ses ondan çıkar (grubun ajanı, sürünün bir hayvanı, görünen karga, gökteki kartal); yoksa grubun
## yerinden, oyuncuya ≥150 m'den gelir (FaunaVoiceRules.unseen_point). Aynı kimlik ≥45 sn, aynı tür ≥20 sn arayla çalar; at ≤60 m kurtta korku
## kişnemesini çalar; kurt uluması sürüdür (3–5 çalış). Ayla bağ yoktur. Ana kampa yırtıcı girmez, yalnız kurdun sesi duyulur (K3): kamp bu
## düğümü kullanmaz, kurdun sesi orada da bu kurallarla çalınabilir.
## Oynatıcılar Ambience yolunda, en çok POOL tane AudioStreamPlayer3D'dir (canlı ses oynatıcısı ≤40, K63).
##   var voices := FaunaVoices.new()
##   voices.setup(def.get("voices", []), director, world.ground)
##   voices.play("gazelle", &"alarm", Vector3(300, 0, -560))

const POOL := 6
const BUS := &"Ambience"
const THINK_S := 1.0
## Görünen kargadan çalınacak en uzak (m) ve çizelgenin «near»ı yoksa duyulma alanı (m).
const SEEN_M := 140.0
const NEAR_DEFAULT := 650.0
## Uzaktaki sesin tizi kısılır (Godot'nun 3B süzgeci; ses-tasarimi.md §6.5).
const FAR_CUTOFF := 5000.0
const FAR_DB := -24.0

var bank: FaunaBank
var rules: FaunaVoiceRules
var director: FaunaDirector
var ground: TerrainShape
var game_field: SmallGameField
var skies: Array[SkyEagle] = []
## Dinleyicinin düğümü (oyuncu; AudioListener3D onun 1,5 m üstündedir, K39).
var listener: Node3D
## Saat (gün dakikası, evre): FaunaLayer yazar.
var minute := 720.0
var phase: StringName = &"noon"
## Çalan son sesler (sınama ve hata ayıklama): [{kind, cluster, at, now}].
var played: Array[Dictionary] = []

var now := 0.0
var _schedule: Array[Dictionary] = []
var _next: PackedFloat32Array = PackedFloat32Array()
var _queue: Array[Dictionary] = []
var _players: Array[AudioStreamPlayer3D] = []
var _think_left := 0.0
var _rng := RandomNumberGenerator.new()


func setup(schedule: Array, p_director: FaunaDirector, shape: TerrainShape, seed_value: int = 7313) -> void:
	bank = FaunaBank.shared()
	rules = FaunaVoiceRules.new(bank.rules())
	director = p_director
	ground = shape
	_rng.seed = seed_value
	name = "FaunaVoices"
	for e: Variant in schedule:
		if e is Dictionary:
			_schedule.append(e)
	_next.resize(_schedule.size())
	for k in _schedule.size():
		var ev: Array = _schedule[k].get("every", [60.0, 120.0])
		_next[k] = _rng.randf_range(4.0, float(ev[0]))


func _ready() -> void:
	for k in POOL:
		var p := AudioStreamPlayer3D.new()
		p.name = "Voice_%d" % k
		p.bus = AudioUtil.bus_or_master(BUS)
		p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		p.attenuation_filter_cutoff_hz = FAR_CUTOFF
		p.attenuation_filter_db = FAR_DB
		p.max_polyphony = 1
		add_child(p)
		_players.append(p)


func _exit_tree() -> void:
	silence()


## Çalan sesler hemen durur ve bırakılır, kuyruk boşalır: ses sunucusu çalış kayıtlarını bir sonraki karışımda boşaltır (çıkışta sızıntı
## kalmasın; sınama koşunun sonunda bunu çağırıp bir karışım bekler).
func silence() -> void:
	for p in _players:
		if is_instance_valid(p):
			p.stop()
			p.stream = null
	_queue.clear()


func _process(delta: float) -> void:
	now += delta
	var i := _queue.size() - 1
	while i >= 0:
		var q: Dictionary = _queue[i]
		if now >= float(q["t"]):
			_queue.remove_at(i)
			_emit(q["kind"], q["pick"], q["at"], float(q["pitch"]))
		i -= 1
	_think_left -= delta
	if _think_left <= 0.0:
		_think_left = THINK_S
		_think()


# --- Yüz -----------------------------------------------------------------------------------------------------

## Türün rolünü çalar (kurallar işler). opts: unseen (görünmeyen kaynak: ≥150 m'ye itilir), pitch (çarpan), force (tekrar sınırını yok sayar:
## sürünün ikinci çalışı). Döner: çaldı mı?
func play(kind: String, role: StringName, at: Vector3, opts: Dictionary = {}) -> bool:
	var pick := _pick(kind, role, at)
	if pick.is_empty():
		return false
	var cluster := str(pick["cluster"])
	if not bool(opts.get("force", false)) and not rules.can_play(cluster, kind, now):
		return false
	var pos := at
	if bool(opts.get("unseen", false)) and listener and is_instance_valid(listener):
		var l := Vector2(listener.global_position.x, listener.global_position.z)
		var p2 := FaunaVoiceRules.unseen_point(l, Vector2(at.x, at.z), rules.unseen_min, Vector2.from_angle(_rng.randf() * TAU))
		pos = Vector3(p2.x, (ground.height_at(p2.x, p2.y) if ground else at.y) + 1.0, p2.y)
	rules.mark(cluster, kind, now)
	if role == &"howl" or cluster == "wolf_howl":
		# Sürünün uluması: ilk çalış şimdi, ötekiler 2–6 sn arayla, perdeleri ayrı; kaynaklar birbirinden birkaç metre.
		var calls := rules.pack_calls(_rng)
		for c in calls:
			var off := Vector3(_rng.randf_range(-12.0, 12.0), 0.0, _rng.randf_range(-12.0, 12.0)) if c.x > 0.0 else Vector3.ZERO
			_queue.append({"t": now + c.x, "kind": kind, "pick": pick, "at": pos + off, "pitch": c.y})
		return true
	_emit(kind, pick, pos, float(opts.get("pitch", 1.0)))
	return true


## Yönetmenin olayları (her tikte): ürkü, uyarı, homurtu, sürünün sesi.
func on_events(events: Array[Dictionary]) -> void:
	for ev: Dictionary in events:
		if ev.get("type") != &"voice":
			continue
		var at2: Vector2 = ev.get("at", Vector2.ZERO)
		play(str(ev.get("kind", "")), ev.get("role", &"call"), _ground3(at2))


## Kuyruktaki (ulumanın sonraki) çalışlar.
func queued() -> int:
	return _queue.size()


# --- Serpinti ---------------------------------------------------------------------------------------------------

func _think() -> void:
	if listener == null or not is_instance_valid(listener) or not listener.is_inside_tree():
		return
	var l := Vector2(listener.global_position.x, listener.global_position.z)
	for k in _schedule.size():
		if now < _next[k]:
			continue
		var e: Dictionary = _schedule[k]
		var every: Array = e.get("every", [60.0, 120.0])
		if e.has("night_every") and _late():
			every = e["night_every"]
		_next[k] = now + _rng.randf_range(float(every[0]), float(every[1]))
		if not _in_time(e):
			continue
		var near: Variant = e.get("near")
		if near is Array and l.distance_to(Vector2(float(near[0]), float(near[1]))) > float(near[2]):
			continue
		var src := _source(e, l)
		if src.is_empty():
			continue
		play(str(e.get("kind", "")), StringName(str(e.get("role", "call"))), src["at"], {"unseen": bool(src.get("unseen", false))})


## Çizelgenin kaynağı: {at: Vector3, unseen}. group:<kimlik> (sahnedeyse ajanı, değilse grubun yeri, görünmez), flock:<kimlik> (bir hayvan),
## birds:<tür> (görünen kuş), home (yer; görünmez). Bulunamazsa boş.
func _source(e: Dictionary, l: Vector2) -> Dictionary:
	var from := str(e.get("from", "home"))
	if from.begins_with("group:") and director:
		var g := director.group(from.substr(6))
		if g == null or not g.present:
			return {}
		if g.active and not g.slots.is_empty():
			var i := g.slots[_rng.randi() % g.slots.size()]
			if director.state[i] != FaunaDirector.State.DOWN:
				return {"at": _ground3(director.pos[i])}
		if l.distance_to(g.spot) > float(e.get("hear", NEAR_DEFAULT)):
			return {}
		return {"at": _ground3(g.spot), "unseen": true}
	if from.begins_with("flock:") and director:
		var f := director.flock(from.substr(6))
		if f == null or f.count == 0:
			return {}
		if l.distance_to(f.center) > float(e.get("hear", 320.0)):
			return {}
		return {"at": _ground3(f.pos[_rng.randi() % f.count])}
	if from.begins_with("birds:") and game_field and is_instance_valid(game_field):
		var list := game_field.of_kind(from.substr(6))
		var seen: Array[SmallGame] = []
		for a in list:
			if a.visible and a.is_inside_tree() and Vector2(a.global_position.x, a.global_position.z).distance_to(l) < SEEN_M:
				seen.append(a)
		if seen.is_empty():
			return {}
		return {"at": seen[_rng.randi() % seen.size()].global_position}
	if e.get("home") is Array:
		var h := FaunaDirector._vec2(e["home"])
		if l.distance_to(h) > float(e.get("hear", NEAR_DEFAULT)):
			return {}
		return {"at": _ground3(h), "unseen": true}
	return {}


## Çizelgenin evre ve saat koşulu: phases (evreler), after ve before (gün dakikası; gece yarısını aşabilir: after 23:00, before dawn).
func _in_time(e: Dictionary) -> bool:
	var phases: Variant = e.get("phases")
	if phases is Array and not (phases as Array).is_empty() and not (phases as Array).has(String(phase)):
		return false
	var after := float(e.get("after", -1.0))
	var before := float(e.get("before", -1.0))
	if after >= 0.0 and before >= 0.0:
		return minute >= after or minute < before if after > before else (minute >= after and minute < before)
	if after >= 0.0:
		return minute >= after
	if before >= 0.0:
		return minute < before
	return true


## 22:30'dan sonra mı (köpek seyrekleşir; audio.md §4 «Ortamın saati»)?
func _late() -> bool:
	return minute >= 1350.0 or minute < 390.0


func _pick(kind: String, role: StringName, at: Vector3) -> Dictionary:
	var r := role
	if kind == "horse" or kind == "takhi":
		# At: ≤60 m kurt korku (gök gürültüsü havanındır; Kışlak'ta yoktur, K22).
		var wolf_m := INF
		if director:
			wolf_m = director.nearest_wolf(Vector2(at.x, at.z)).y
		r = &"fear" if rules.horse_cluster(wolf_m) == "horse_fear" else &"calm"
	return bank.pick(kind, r) if bank else {}


func _emit(kind: String, pick: Dictionary, at: Vector3, pitch: float) -> void:
	var stream := bank.stream(str(pick["cluster"]))
	if stream == null or _players.is_empty():
		return
	var p := _free_player()
	p.stream = stream
	p.global_position = at
	p.unit_size = float(pick["unit"])
	p.max_distance = float(pick["max"])
	p.volume_db = float(pick["db"])
	p.pitch_scale = float(pick["pitch"]) * pitch
	p.play()
	played.append({"kind": kind, "cluster": pick["cluster"], "at": at, "now": now})
	if played.size() > 32:
		played.pop_front()


func _free_player() -> AudioStreamPlayer3D:
	for p in _players:
		if not p.playing:
			return p
	# Hepsi çalıyor: en uzaktaki susar.
	var far: AudioStreamPlayer3D = _players[0]
	if listener and is_instance_valid(listener):
		var best := -1.0
		for p in _players:
			var d := p.global_position.distance_squared_to(listener.global_position)
			if d > best:
				best = d
				far = p
	far.stop()
	return far


func _ground3(p: Vector2) -> Vector3:
	return Vector3(p.x, (ground.height_at(p.x, p.y) if ground else 0.0) + 0.8, p.y)
