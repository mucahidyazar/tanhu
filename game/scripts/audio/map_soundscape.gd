class_name MapSoundscape
extends Node3D
## İç haritanın ses profili (map.json «audio» → data/audio/profiles/<kimlik>.json; audio.md §1 «Hava», §3 «Saate bağlı durum», §4 «Ortamın saati»;
## K20, K22, K59; Yol Haritası kislak-ambience). Haritanın ortamının tek sahibidir (K22): perdenin rengini kurar (data/music/act_<n>.tres), dünyanın
## müzik bankasını açar ve gündelik durumu saatle seçer (Kışlak: winter_day Sabah, Öğle, İkindi; winter_evening Tan ve 22:30'a dek Akşam ve Gece;
## winter_night 22:30'dan Tan'a); sahne müziği (gündelik olmayan durum) çalarken müziğe dokunmaz. Ambience yolunun döngülerini evreyle, havanın
## rüzgârıyla (windK), karıyla ve yutmasıyla (quiet) yürütür; havanın kendi döngülerinden haritada basılmış olanları çalar (blizzard, wind_gale);
## 3B döngüleri (Yol Kemikleri'nin bone_hum'u) en yakın birkaç noktada çalar (canlı ses oynatıcısı ≤40, K63). Alçak sessizlikte rüzgâr −40 dB'e
## iner, ötekiler söner (K59). Bırakılınca döngüler söner, perdenin önceki rengi geri gelir.
## MapWorld kurulumun son adımında kurar (build); profil dosyası yoksa bir şey kurulmaz (deneme haritası: menünün müziği sürer).
##   MapSoundscape.build(map_world, spec.audio)
##   MapSoundscape.daily_state(&"dusk", 1360.0, profile["states"])   # &"winter_night"

const PROFILE_DIR := "res://data/audio/profiles"
const UPDATE_S := 0.25
## Katmanın sesi bundan az değişirse yazılmaz (dB) ve geçiş süresi (sn).
const DB_EPS := 0.5
const FADE_S := 2.5
const SILENT_DB := -80.0
const LOW_SILENCE_WIND_DB := -40.0
const DAY_PHASES: Array[StringName] = [&"morning", &"noon", &"golden"]
## Perde rengi ve ortam döngülerinin klasörleri (AudioManager ile aynı yer: data/music/act_<n>.tres; audio/ambience/gen, audio/ambience).
const COLOR_DIR := "res://data/music"
const AMBIENCE_DIRS: Array[String] = ["res://audio/ambience/gen", "res://audio/ambience"]

var profile: Dictionary = {}
var world: Node3D
var ground: TerrainShape
## Yol Kemiği onarıldı mı (kimlik → bool; görev ve yol sistemi yazar). Boşsa hepsi onarılmamış sayılır.
var repaired: Callable = Callable()
var session: Session

var _audio: Node
var _prev_color: MusicColor
var _left := 0.0
var _bed_db: Dictionary = {}
var _emitters: Array[Dictionary] = []
var _local_clock: GameClock
var _owned_bank := false


## Profili kurar ve haritanın altına ekler. Profil yoksa null.
static func build(p_world: Node3D, profile_id: String) -> MapSoundscape:
	if p_world == null or profile_id.is_empty():
		return null
	var def := load_profile(profile_id)
	if def.is_empty():
		return null
	var node := MapSoundscape.new()
	node.name = "Soundscape"
	node.profile = def
	node.world = p_world
	p_world.add_child(node)
	return node


static func load_profile(profile_id: String) -> Dictionary:
	var path := PROFILE_DIR.path_join(profile_id + ".json")
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## Gündelik müziğin durumu (saf; audio.md §3 «Saate bağlı durum»): gündüz evreleri day, Tan evening, Akşam ve Gece night_from'a dek evening,
## sonra (gece yarısından Tan'a dek) night. Evre boşsa dakikadan (FaunaDirector.phase_of).
static func daily_state(phase: StringName, minute: float, states: Dictionary) -> StringName:
	var p := phase if phase != &"" else FaunaDirector.phase_of(minute)
	var night_from := _minute_of(states.get("night_from", "22:30"))
	if DAY_PHASES.has(p):
		return StringName(str(states.get("day", "winter_day")))
	if p == &"dawn":
		return StringName(str(states.get("evening", "winter_evening")))
	if minute >= night_from or minute < 720.0:
		return StringName(str(states.get("night", "winter_night")))
	return StringName(str(states.get("evening", "winter_evening")))


## Döngünün o anki kazancı (saf): gece ya da gündüz kazancı × rüzgâr × yutma × kar × çizgiye yakınlık; evre dışında 0.
static func bed_gain(bed: Dictionary, ctx: Dictionary) -> float:
	var phase: StringName = ctx.get("phase", &"noon")
	var phases: Variant = bed.get("phases")
	if phases is Array and not (phases as Array).is_empty() and not (phases as Array).has(String(phase)):
		return 0.0
	var night := phase == &"night" or phase == &"dusk"
	var g := float(bed.get("night_gain", bed.get("gain", 1.0))) if night else float(bed.get("gain", 1.0))
	if bool(bed.get("wind", false)):
		g *= float(ctx.get("wind_k", 1.0))
	if bool(bed.get("base_wind", false)):
		g *= float(ctx.get("base_wind", 1.0))
	if bool(bed.get("quiet", false)):
		g *= float(ctx.get("quiet", 1.0))
	if bool(bed.get("snow", false)):
		g *= clampf(float(ctx.get("snow", 0.0)), 0.0, 1.0)
	if bed.get("line") is Array:
		var d := line_distance(ctx.get("at", Vector2.ZERO), bed["line"])
		g *= 1.0 - smoothstep(float(bed.get("full_m", 90.0)), float(bed.get("zero_m", 320.0)), d)
	return maxf(g, 0.0)


## Noktanın çoklu çizgiye uzaklığı (m).
static func line_distance(p: Vector2, line: Array) -> float:
	var best := INF
	for k in range(line.size() - 1):
		var a := FaunaDirector._vec2(line[k])
		var b := FaunaDirector._vec2(line[k + 1])
		var ab := b - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-6), 0.0, 1.0)
		best = minf(best, p.distance_to(a + ab * t))
	return best


static func gain_db(ref_db: float, gain: float) -> float:
	return SILENT_DB if gain <= 0.0005 else ref_db + 20.0 * log(gain) / log(10.0)


static func _minute_of(v: Variant) -> float:
	if v is String:
		return GameClock.parse_hhmm(v)
	return float(v)


# --- Düğüm ------------------------------------------------------------------------------------------------

func _ready() -> void:
	ground = FaunaLayer._ground_of(world)
	_audio = get_node_or_null(^"/root/AudioManager")
	if _audio:
		if _audio.has_method(&"music_color"):
			_prev_color = _audio.call(&"music_color")
		var act := int(profile.get("act", -1))
		if act >= 0 and _audio.has_method(&"set_music_color"):
			var path := COLOR_DIR.path_join("act_%d.tres" % act)
			var color: MusicColor = load(path) as MusicColor if ResourceLoader.exists(path) else null
			if color:
				_audio.call(&"set_music_color", color)
	_build_emitters()
	_left = 0.0


func _exit_tree() -> void:
	for em: Dictionary in _emitters:
		for pl: AudioStreamPlayer3D in em["players"]:
			if is_instance_valid(pl):
				pl.stop()
				pl.stream = null
	if _audio and is_instance_valid(_audio):
		for id: String in _bed_db:
			_audio.call(&"set_ambience_layer", StringName(id), SILENT_DB, 1.5)
		if _owned_bank and str(_audio.call(&"current_music_bank")) == str(profile.get("bank", "")):
			_audio.call(&"stop_music_bank", 2.0)
		if _audio.has_method(&"set_music_color"):
			# Önceki renk (yoksa kampın ve menünün rengi: act_0).
			var back: MusicColor = _prev_color
			if back == null and ResourceLoader.exists(COLOR_DIR.path_join("act_0.tres")):
				back = load(COLOR_DIR.path_join("act_0.tres")) as MusicColor
			if back:
				_audio.call(&"set_music_color", back)
	_bed_db.clear()


func _process(delta: float) -> void:
	_left -= delta
	if _left > 0.0:
		return
	_left = UPDATE_S
	var ctx := _context()
	_update_music(ctx)
	_update_beds(ctx)
	_update_emitters(ctx)


## Dünyanın o anki ses girdileri: evre, dakika, dinleyicinin yeri, rüzgâr, yutma, kar, hava döngüleri.
func _context() -> Dictionary:
	var clock := _clock()
	var minute := clock.minute if clock else 720.0
	var phase := clock.phase() if clock else &""
	if phase == &"":
		phase = FaunaDirector.phase_of(minute)
	var ctx := {"phase": phase, "minute": minute, "at": _listener_xz(), "wind_k": 1.0, "quiet": 1.0, "snow": 0.6, "base_wind": 1.0,
		"beds": [], "signs": false}
	var sim := _weather_sim()
	if sim:
		var a: Dictionary = sim.audio
		ctx["wind_k"] = float(a.get("wind_k", 1.0))
		ctx["quiet"] = float(a.get("quiet", 1.0))
		ctx["beds"] = a.get("beds", [])
		if sim.fx:
			var snowing := sim.fx.type in [&"snow", &"heavy_snow", &"blizzard", &"kara_boran", &"sleet"]
			ctx["snow"] = clampf(maxf(sim.fx.snowpack, 0.6 if snowing else 0.0) * (1.4 if snowing else 1.0), 0.0, 1.0)
		for b: Variant in ctx["beds"]:
			if b is Dictionary and str((b as Dictionary).get("id", "")) in ["blizzard", "wind_gale"] and float((b as Dictionary).get("gain", 0.0)) > 0.5:
				ctx["base_wind"] = 0.0
		if sim.signs and sim.signs.has_method(&"entry") and sim.signs.call(&"entry", "bones"):
			ctx["signs"] = true
	return ctx


func _update_music(ctx: Dictionary) -> void:
	if _audio == null or not is_instance_valid(_audio):
		return
	var bank := str(profile.get("bank", ""))
	if bank.is_empty():
		return
	var states: Dictionary = profile.get("states", {})
	var want := daily_state(ctx["phase"], float(ctx["minute"]), states)
	var current_bank := str(_audio.call(&"current_music_bank"))
	var current: StringName = _audio.call(&"current_music_state")
	if current_bank != bank:
		if _owned_bank and current_bank != "":
			return
		if _audio.call(&"set_music_bank", bank, want, 3.0):
			_owned_bank = true
		return
	# Sahne müziği önce gelir: yalnız gündelik durumdayken saat müziği değiştirir.
	var daily: Array = [StringName(str(states.get("day", ""))), StringName(str(states.get("evening", ""))), StringName(str(states.get("night", "")))]
	if current != want and (daily.has(current) or current == &""):
		_audio.call(&"set_music_state", want)


func _update_beds(ctx: Dictionary) -> void:
	if _audio == null or not is_instance_valid(_audio):
		return
	var ref := float(profile.get("ref_db", -10.0))
	var low: bool = _audio.has_method(&"is_low_silence") and bool(_audio.call(&"is_low_silence"))
	for bed: Variant in profile.get("beds", []):
		if not bed is Dictionary:
			continue
		var id := str((bed as Dictionary).get("id", ""))
		var db := gain_db(ref, bed_gain(bed, ctx))
		if low:
			db = LOW_SILENCE_WIND_DB if bool((bed as Dictionary).get("base_wind", false)) else SILENT_DB
		_set_bed(id, db)
	# Havanın döngüleri: yalnız profilin tanıdıkları (Kışlak'ta basılmış olanlar).
	var known: Array = profile.get("weather_beds", [])
	var seen := {}
	for b: Variant in ctx.get("beds", []):
		if not b is Dictionary:
			continue
		var id := str((b as Dictionary).get("id", ""))
		if not known.has(id):
			continue
		seen[id] = true
		_set_bed(id, SILENT_DB if low else gain_db(ref, float((b as Dictionary).get("gain", 0.0))))
	for id: Variant in known:
		if not seen.has(str(id)) and _bed_db.has(str(id)):
			_set_bed(str(id), SILENT_DB)


func _set_bed(id: String, db: float) -> void:
	var old := float(_bed_db.get(id, SILENT_DB - 1.0))
	if absf(old - db) < DB_EPS:
		return
	if db <= SILENT_DB and not _bed_db.has(id):
		return
	_bed_db[id] = db
	_audio.call(&"set_ambience_layer", StringName(id), db, FADE_S)


## Güncel katmanların hedef sesleri (sınama).
func bed_levels() -> Dictionary:
	return _bed_db.duplicate()


# --- 3B döngüler (Yol Kemikleri) ---------------------------------------------------------------------------------

func _build_emitters() -> void:
	for e: Variant in profile.get("emitters", []):
		if not e is Dictionary:
			continue
		var id := str((e as Dictionary).get("id", ""))
		var stream: AudioStream = null
		for dir in AMBIENCE_DIRS:
			stream = AudioUtil.load_stream(dir.path_join(id + ".wav"), true)
			if stream:
				break
		var players: Array[AudioStreamPlayer3D] = []
		for k in int((e as Dictionary).get("players", 2)):
			var p := AudioStreamPlayer3D.new()
			p.name = "%s_%d" % [id.to_pascal_case(), k]
			p.bus = AudioUtil.bus_or_master(&"Ambience")
			p.stream = stream
			p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
			p.unit_size = float((e as Dictionary).get("unit", 9.0))
			p.max_distance = float((e as Dictionary).get("range", 120.0))
			p.volume_db = SILENT_DB
			add_child(p)
			players.append(p)
		_emitters.append({"def": e, "players": players, "at": []})


func _update_emitters(ctx: Dictionary) -> void:
	var l: Vector2 = ctx["at"]
	for em: Dictionary in _emitters:
		var e: Dictionary = em["def"]
		var points: Array = e.get("points", [])
		var ids: Array = e.get("ids", [])
		var range_m := float(e.get("range", 120.0))
		var order: Array = []
		for k in points.size():
			var p := FaunaDirector._vec2(points[k])
			var d := l.distance_to(p)
			if d <= range_m + 20.0:
				order.append([d, k])
		order.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
		var players: Array[AudioStreamPlayer3D] = em["players"]
		var wind_k := float(ctx.get("wind_k", 1.0)) if bool(e.get("wind", true)) else 1.0
		for j in players.size():
			var pl := players[j]
			if pl.stream == null:
				continue
			if j >= order.size():
				if pl.playing:
					pl.stop()
				continue
			var k: int = order[j][1]
			var p := FaunaDirector._vec2(points[k])
			var y := ground.height_at(p.x, p.y) if ground else 0.0
			pl.global_position = Vector3(p.x, y + 2.4, p.y)
			var fixed := repaired.is_valid() and k < ids.size() and bool(repaired.call(str(ids[k])))
			var db := float(e.get("db", -9.0)) + 20.0 * log(clampf(wind_k, 0.05, 2.0)) / log(10.0)
			if not fixed:
				db += 20.0 * log(float(e.get("unrepaired", 0.35))) / log(10.0)
				pl.max_distance = range_m * 0.5
			else:
				pl.max_distance = range_m
			if bool(ctx.get("signs", false)):
				db += float(e.get("signs_db", 6.0))
			pl.volume_db = db
			if not pl.playing:
				pl.play(randf() * 4.0)


## Çalan 3B döngülerin yerleri (sınama).
func emitter_positions() -> PackedVector3Array:
	var out := PackedVector3Array()
	for em: Dictionary in _emitters:
		for pl: AudioStreamPlayer3D in em["players"]:
			if pl.playing:
				out.append(pl.global_position)
	return out


# --- Girdiler ------------------------------------------------------------------------------------------------

func _listener_xz() -> Vector2:
	var vp := get_viewport() if is_inside_tree() else null
	var main := world.get_parent() if world else null
	var player: Variant = main.get("player") if main and "player" in main else null
	if player is Node3D and is_instance_valid(player):
		var p := (player as Node3D).global_position
		return Vector2(p.x, p.z)
	var cam := vp.get_camera_3d() if vp else null
	if cam:
		return Vector2(cam.global_position.x, cam.global_position.z)
	return Vector2.ZERO


func _clock() -> GameClock:
	var s := _session()
	if s and s.clock:
		return s.clock
	if _local_clock == null:
		_local_clock = GameClock.new(1041, 720.0)
	return _local_clock


func _session() -> Session:
	if session and is_instance_valid(session):
		return session
	var main := world.get_parent() if world else null
	var s: Variant = main.get("session") if main and "session" in main else null
	session = s if s is Session and is_instance_valid(s) else null
	return session


func _weather_sim() -> WeatherSim:
	var s := _session()
	if s == null:
		return null
	for id: StringName in [&"weather", &"map_weather", &"kislak_weather"]:
		var m: Variant = s.get_system(id)
		if m is WeatherSim:
			return m
		if m is Object and "sim" in (m as Object) and (m as Object).get("sim") is WeatherSim:
			return (m as Object).get("sim")
		if m is Callable and (m as Callable).get_object() and "sim" in (m as Callable).get_object():
			var o: Variant = (m as Callable).get_object().get("sim")
			if o is WeatherSim:
				return o
	return null
