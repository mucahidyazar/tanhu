class_name ChildhoodAtmos
extends Node
## Çocukluk'un günlerinin sesi (E21, K110; docs/design/d3/e21-atmosphere.md «Yollar ve kurallar», «Çobanlık»): günün verisindeki atmos.beds
## döngüleri (yatak) ve adımların tek seferlik sesleri. Kurallar atmosfer belgesinindir: yatak audio/ambience/e21/<kimlik>.wav, tek seferlik
## audio/sfx/e21/<kimlik>.wav ya da çeşitleri <kimlik>_a/_b/_c (rastgele, aynısı art arda çalmaz); aynı anda en çok MAX_BEDS yatak, geçiş
## FADE_S; konumlu yatak merkezinden radius'a dek tam, ötesinde kısılır ve boğuklaşır (AudioStreamPlayer3D'nin uzaklık süzgeci; dinleyici
## oyuncunun üstündedir, K39). Dosya yoksa yer tutucu çalar (PLACEHOLDERS: var olan ses); dosya gelince sonraki kurulumda kendiliğinden yerine
## geçer. Müzik bankası sahnenindir (data.music); adımlar katmanları kısar ya da açar (music_layers).
##   atmos.setup(scene, data["atmos"])          # beds: [{id, db, at?, radius?, from?, to?, when?}]
##   atmos.sfx("sfx_sheep_bell", sheep_pos)     # tek seferlik (konumlu ya da düz)
##   atmos.set_flag("swimming", true)          # when: "swimming" yatağı açılır
##   atmos.music_layers({"kopuz": -80.0, "kaval": -3.0}, 3.0)

const BED_DIR := "res://audio/ambience/e21"
const SFX_DIR := "res://audio/sfx/e21"
const WAV := ".wav"
const MAX_BEDS := 3
const FADE_S := 2.5
const UPDATE_S := 0.25
const SILENT_DB := -80.0
## Tek seferlik seslerin havuzu.
const POOL := 8
## Yer tutucular (dosya yokken): kimlik → var olan dosya (atmosfer belgesinin «Var olandan kullanılanlar»ı da burada).
const PLACEHOLDERS := {
	"amb_ordos_steppe_day": "res://audio/ambience/gen/wind_steppe.wav",
	"amb_reed_lake": "res://audio/ambience/gen/water_reed.wav",
	"amb_dailin_far": "res://audio/ambience/gen/wind_steppe.wav",
	"amb_ordos_dusk": "res://audio/ambience/night_meadow_loop.wav",
	"amb_child_swim": "res://audio/ambience/gen/water_reed.wav",
	"amb_moon_night": "res://audio/ambience/night_meadow_loop.wav",
	"amb_ebe_camp": "res://audio/ambience/gen/wind_steppe.wav",
	"sfx_sheep_bell": "res://audio/sfx/gen/bell_step.wav",
	"sfx_wade": "res://audio/sfx/gen/lake_bull.wav",
	"sfx_dive_up": "res://audio/sfx/gen/lake_bull.wav",
	"sfx_kids_laugh": "res://audio/sfx/gen/breath.wav",
	"sfx_mud_pull": "res://audio/sfx/gen/felt_flap.wav",
	"sfx_fox_bark": "res://audio/sfx/gen/fauna/fox_bark_1.wav",
	"sfx_cranes_overhead": "res://audio/sfx/gen/crane_call.wav",
	"sfx_lamb_bleat": "res://audio/sfx/gen/lamb.wav",
	"sfx_sheep": "res://audio/sfx/gen/sheep.wav",
	"sfx_wolf_far": "res://audio/sfx/gen/fauna/wolf_howl_2.wav",
}
## Atmosfer belgesinin «var olandan» eşlemesi (dosyası hiç üretilmeyecek kimlikler): yer tutucu değil, kalıcıdır.
const ALIASES := {
	"sfx_cranes_overhead": "res://audio/sfx/gen/crane_call.wav",
	"sfx_sheep": "res://audio/sfx/gen/sheep.wav",
	"sfx_wolf_far": "res://audio/sfx/gen/fauna/wolf_howl_2.wav",
}

var scene: Node
var beds: Array[Dictionary] = []
## Yatakların koşulları (when): bayrak → açık mı.
var flags := {}
## Çalan yatak sayısı (sınama).
var playing_beds := 0

var _players: Dictionary = {}
var _gain: Dictionary = {}
var _left := 0.0
var _pool: Array[AudioStreamPlayer3D] = []
var _pool_2d: Array[AudioStreamPlayer] = []
var _variants: Dictionary = {}
var _last: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _stopped := false


## Kurulum: scene (ChildhoodScene: point(), minute(), player), def (günün atmos'u).
func setup(p_scene: Node, def: Dictionary) -> void:
	scene = p_scene
	_rng.seed = 2028
	for b: Variant in def.get("beds", []):
		if b is Dictionary and not str((b as Dictionary).get("id", "")).is_empty():
			beds.append(b)
	set_process(true)


func _process(delta: float) -> void:
	if _stopped:
		return
	_left -= delta
	if _left > 0.0:
		return
	_left = UPDATE_S
	_update_beds()


## Bayrak (when koşulu): ör. "swimming".
func set_flag(flag_name: String, on: bool) -> void:
	flags[flag_name] = on
	_left = 0.0


## Yatağın kazancı (saf; 0..1): saat aralığı (from–to, gün dakikası; yoksa hep), koşul (when) ve konum (at, radius: merkezden radius'a dek 1,
## radius × 2'de 0; dinleyici yoksa 1). Konumlu yatağın asıl kısılmasını AudioStreamPlayer3D yapar: bu çarpan yalnız seçim içindir.
static func bed_gain(bed: Dictionary, minute: float, listener: Vector3, center: Vector3, p_flags: Dictionary) -> float:
	var from := GameClock.parse_hhmm(bed.get("from", "")) if bed.has("from") else -1.0
	var to := GameClock.parse_hhmm(bed.get("to", "")) if bed.has("to") else -1.0
	var g := 1.0
	if from >= 0.0:
		g *= smoothstep(from - 10.0, from + 10.0, minute)
	if to >= 0.0:
		g *= 1.0 - smoothstep(to - 10.0, to + 10.0, minute)
	var when := str(bed.get("when", ""))
	if not when.is_empty():
		var negate := when.begins_with("!")
		var on := bool(p_flags.get(when.trim_prefix("!"), false))
		if on == negate:
			return 0.0
	if center != Vector3.INF and listener != Vector3.INF and bed.has("radius"):
		var r := float(bed["radius"])
		var d := Vector2(listener.x - center.x, listener.z - center.z).length()
		g *= 1.0 - smoothstep(r, r * 2.2, d)
	return g


func _update_beds() -> void:
	var minute := float(scene.call(&"minute")) if scene and scene.has_method(&"minute") else 720.0
	var listener := _listener()
	var wants: Array = []
	for bed: Dictionary in beds:
		var center := _bed_center(bed)
		var g := bed_gain(bed, minute, listener, center, flags)
		wants.append([g, bed])
	wants.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	var count := 0
	for pair: Array in wants:
		var bed: Dictionary = pair[1]
		var g := float(pair[0])
		var on := g > 0.02 and count < MAX_BEDS
		if on:
			count += 1
		_set_bed(bed, g if on else 0.0)
	playing_beds = count


func _set_bed(bed: Dictionary, g: float) -> void:
	var id := str(bed["id"])
	var player: Node = _players.get(id)
	if player == null:
		if g <= 0.0:
			return
		player = _make_bed(bed)
		if player == null:
			return
	var target := SILENT_DB if g <= 0.0 else float(bed.get("db", -12.0)) + 20.0 * log(maxf(g, 0.001)) / log(10.0)
	var last := float(_gain.get(id, -999.0))
	if absf(last - target) < 0.4:
		return
	_gain[id] = target
	if not player.get(&"playing"):
		player.set(&"volume_db", SILENT_DB)
		player.call(&"play", _rng.randf() * 4.0)
	var tw := create_tween()
	tw.tween_property(player, ^"volume_db", target, FADE_S).set_trans(Tween.TRANS_SINE)
	if target <= SILENT_DB:
		tw.tween_callback(player.stop)


func _make_bed(bed: Dictionary) -> Node:
	var id := str(bed["id"])
	var stream := AudioUtil.load_stream(resolve_bed(id), true)
	if stream == null:
		return null
	var center := _bed_center(bed)
	var node: Node
	if center != Vector3.INF and bed.has("radius"):
		var p3 := AudioStreamPlayer3D.new()
		var r := float(bed["radius"])
		p3.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		p3.unit_size = maxf(r * 0.55, 4.0)
		p3.max_distance = r * 3.0
		p3.panning_strength = 0.45
		p3.attenuation_filter_cutoff_hz = 3200.0
		p3.attenuation_filter_db = -18.0
		p3.position = center + Vector3.UP * 1.5
		node = p3
	else:
		node = AudioStreamPlayer.new()
	node.name = "Bed_%s" % id
	node.set(&"stream", stream)
	node.set(&"bus", AudioUtil.bus_or_master(&"Ambience"))
	node.set(&"volume_db", SILENT_DB)
	add_child(node)
	_players[id] = node
	return node


## Yatağın dosyası: e21 klasöründe, yoksa yer tutucu (yoksa boş).
static func resolve_bed(id: String) -> String:
	var own := BED_DIR.path_join(id + WAV)
	if ResourceLoader.exists(own):
		return own
	return str(PLACEHOLDERS.get(id, "")) if ResourceLoader.exists(str(PLACEHOLDERS.get(id, ""))) else ""


## Tek seferlik sesin çeşitleri (saf değil: dosyaya bakar): <id>.wav, <id>_a/_b/_c.wav; yoksa kalıcı eşleme ya da yer tutucu.
static func sfx_paths(id: String) -> PackedStringArray:
	var out := PackedStringArray()
	var plain := SFX_DIR.path_join(id + WAV)
	if ResourceLoader.exists(plain):
		out.append(plain)
	for suffix in ["_a", "_b", "_c", "_d"]:
		var p := SFX_DIR.path_join(id + suffix + WAV)
		if ResourceLoader.exists(p):
			out.append(p)
	if out.is_empty():
		var alt := str(ALIASES.get(id, PLACEHOLDERS.get(id, "")))
		if not alt.is_empty() and ResourceLoader.exists(alt):
			out.append(alt)
	return out


## Tek seferlik ses: at verilirse konumlu (3B), değilse düz. db sesin düzeyi, pitch oynama payı. Çalındıysa true.
func sfx(id: String, at: Vector3 = Vector3.INF, db: float = 0.0, pitch_spread: float = 0.04) -> bool:
	if _stopped:
		return false
	if not _variants.has(id):
		_variants[id] = sfx_paths(id)
	var paths: PackedStringArray = _variants[id]
	if paths.is_empty():
		return false
	var pick := _rng.randi() % paths.size()
	if paths.size() > 1 and pick == int(_last.get(id, -1)):
		pick = (pick + 1) % paths.size()
	_last[id] = pick
	var stream := AudioUtil.load_stream(paths[pick], false)
	if stream == null:
		return false
	var pitch := 1.0 + _rng.randf_range(-pitch_spread, pitch_spread)
	if at != Vector3.INF:
		var p3 := _free_3d()
		p3.stream = stream
		p3.volume_db = db
		p3.pitch_scale = pitch
		p3.global_position = at
		p3.play()
	else:
		var p2 := _free_2d()
		p2.stream = stream
		p2.volume_db = db
		p2.pitch_scale = pitch
		p2.play()
	return true


## Müzik bankasının katmanları (dB): {"kopuz": -80, "kaval": -3}; bankası çalmıyorsa bir şey olmaz.
func music_layers(layers: Dictionary, seconds: float = 3.0) -> void:
	var audio := _audio()
	if audio == null or not audio.has_method(&"set_layer_db"):
		return
	for layer: String in layers:
		audio.call(&"set_layer_db", StringName(layer), float(layers[layer]), seconds)


## Müziği kısar ya da açar (öğle dinlencesi: yalnız ortam).
func music_quiet(on: bool, seconds: float = 3.0) -> void:
	var audio := _audio()
	if audio:
		audio.call(&"music_off" if on else &"music_on", seconds)


## AudioManager (ağaçtayken yolundan; ağacın dışındayken sahnenin kökünden: sahne kapanırken de müzik geri açılır, mutlak yol hata yazmaz).
func _audio() -> Node:
	if is_inside_tree():
		return get_node_or_null(^"/root/AudioManager")
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null(^"AudioManager") if tree and tree.root else null


## Ağaçtan çıkarken söner (sahnenin stop'u çağrılmadan kaldırılsa da müzik açık kalır, yataklar susar).
func _exit_tree() -> void:
	stop()


## Hepsini söndürür (sahne durunca).
func stop() -> void:
	if _stopped:
		return
	_stopped = true
	for p: Node in _players.values():
		if is_instance_valid(p):
			p.call(&"stop")
	for p in _pool:
		if is_instance_valid(p):
			p.stop()
	for p in _pool_2d:
		if is_instance_valid(p):
			p.stop()
	music_quiet(false, 1.0)


func _bed_center(bed: Dictionary) -> Vector3:
	if not bed.has("at") or scene == null or not scene.has_method(&"point"):
		return Vector3.INF
	return scene.call(&"point", bed["at"])


func _listener() -> Vector3:
	var p: Variant = scene.get(&"player") if scene else null
	return (p as Node3D).global_position if p is Node3D and is_instance_valid(p) and (p as Node3D).is_inside_tree() else Vector3.INF


func _free_3d() -> AudioStreamPlayer3D:
	for p in _pool:
		if not p.playing:
			return p
	if _pool.size() < POOL:
		var p3 := AudioStreamPlayer3D.new()
		p3.name = "Sfx3D_%d" % _pool.size()
		p3.bus = AudioUtil.bus_or_master(&"SFX")
		p3.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		p3.unit_size = 6.0
		p3.max_distance = 90.0
		p3.attenuation_filter_cutoff_hz = 4000.0
		p3.attenuation_filter_db = -14.0
		add_child(p3)
		_pool.append(p3)
		return p3
	var oldest: AudioStreamPlayer3D = _pool.pop_front()
	oldest.stop()
	_pool.append(oldest)
	return oldest


func _free_2d() -> AudioStreamPlayer:
	for p in _pool_2d:
		if not p.playing:
			return p
	if _pool_2d.size() < 3:
		var p2 := AudioStreamPlayer.new()
		p2.name = "Sfx2D_%d" % _pool_2d.size()
		p2.bus = AudioUtil.bus_or_master(&"SFX")
		add_child(p2)
		_pool_2d.append(p2)
		return p2
	var oldest: AudioStreamPlayer = _pool_2d.pop_front()
	oldest.stop()
	_pool_2d.append(oldest)
	return oldest
