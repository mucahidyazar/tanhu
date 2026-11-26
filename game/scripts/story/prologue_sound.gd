class_name PrologueSound
extends Node
## Önsöz'ün günlerinin sesi (E21, K110; docs/design/d3/e21-atmosphere.md; e21-prologue-api.md §8): ortam yatakları, tek seferlik sesler ve
## müzik. Kimlikler belgedekidir; yollar: yatak audio/ambience/e21/<kimlik>.wav, tek seferlik ses audio/sfx/e21/<kimlik>[_a|_b|_c].wav
## (çeşitlerden biri rastgele, aynısı art arda çalmaz), müzik audio/music/e21/<kimlik>.mp3. Dosya yoksa yer tutucu çalar (PLACEHOLDERS: var
## olan ses ya da kodla basılmış ses); dosya gelince kendiliğinden yerine geçer (yol her çağrıda sınanır, önbellek yalnız var olanındır).
## Yatak konumludur: merkezin r/2'sinde tam, r'de sessiz (uzaklıkla yumuşak söner); konumsuz yatak (at boş) her yerde. Aynı anda en çok 3
## yatak çalar (en yüksek üçü); geçişler 2–4 sn. Tek seferlik konumlu ses 3B çalar, uzakta kısık ve boğuktur (alçak geçiren süzgeç). Söz
## sürerken müzik ve ortam −3 dB kısılır (K78): Music ve Ambience yollarının kısması AudioManager'ındır (söz Voice yolundan çalar).
## Menünün müziği (menu_theme) ve gece çayırı Önsöz'ün günlerinde susar; sinemaya geçişte sinemanın bankası gelir.
##   var s := PrologueSound.new(); add_child(s)
##   s.apply_scene(scene_data, places)        # beds, music
##   s.bed("amb_blizzard_night", true, -2.0)
##   s.sfx("sfx_milk_pour", at)
##   s.music("mus_prologue_day")

const AMB_DIR := "res://audio/ambience/e21"
const SFX_DIR := "res://audio/sfx/e21"
const MUSIC_DIR := "res://audio/music/e21"
## Var olan sesler (kimlik → yol): e21 dosyası yokken çalar.
const PLACEHOLDERS := {
	"amb_camp_spring_night": "res://audio/ambience/night_meadow_loop.wav",
	"amb_ember_pot": "res://audio/ambience/gen/ember_crackle.wav",
	"amb_stream": "res://audio/ambience/gen/water_reed.wav",
	"amb_blizzard_night": "res://audio/ambience/gen/blizzard.wav",
	"amb_blizzard_lee": "res://audio/ambience/gen/snow_drift.wav",
	"amb_yurt_storm_inside": "res://audio/ambience/gen/yurt_inside.wav",
	"amb_birch_camp_day": "res://audio/ambience/e21/amb_camp_spring_day.wav",
	"amb_fire_small": "res://audio/ambience/campfire_loop.wav",
	"sfx_wolf_far": "res://audio/sfx/gen/fauna/wolf_howl_1.wav",
	"sfx_newborn_cry": "res://audio/sfx/gen/newborn_cry.wav",
	"sfx_fire_rekindle": "res://audio/sfx/gen/fire_catch.wav",
	"sfx_tinder_catch": "res://audio/sfx/gen/fire_catch.wav",
	"sfx_horses_storm": "res://audio/sfx/gen/horse_neigh.wav",
	"sfx_stake_flap": "res://audio/sfx/gen/felt_flap.wav",
	"sfx_dog_storm": "res://audio/sfx/gen/fauna/dog_bark_1.wav",
	"sfx_milk_slosh": "res://audio/sfx/gen/breath.wav",
}
## Çeşitlerin ekleri.
const VARIANTS: Array[String] = ["_a", "_b", "_c", "_d"]
const MAX_BEDS := 3
const SILENT_DB := -80.0
const BED_FADE := 2.5
## Uzaktaki tek seferlik sesin süzgeci: bu uzaklıktan (m) ötede boğuklaşır.
const FAR_FILTER_FROM := 25.0
const SFX_POOL := 12

## Dinleyicinin yeri (oyuncu): func() -> Vector3.
var listener_source: Callable
## Yataklar: kimlik → {player, at (Vector3 ya da INF), radius, db (taban), on, level}.
var beds: Dictionary = {}
var _music: AudioStreamPlayer
var _music_out: AudioStreamPlayer
var _music_id := ""
var _pool: Array[AudioStreamPlayer3D] = []
var _pool2d: Array[AudioStreamPlayer] = []
var _last_variant: Dictionary = {}
var _stream_cache: Dictionary = {}
var _menu_quiet := false


func _ready() -> void:
	_music = _make_player("PrologueMusic", &"Music")
	_music_out = _make_player("PrologueMusicOut", &"Music")
	_quiet_menu(true)


func _exit_tree() -> void:
	_quiet_menu(false)


func _make_player(n: String, bus: StringName) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = n
	p.bus = AudioUtil.bus_or_master(bus)
	p.volume_db = SILENT_DB
	add_child(p)
	return p


## Sahnenin sesi: beds ([{id, at (işaret ya da [x, z]), radius, db}]) ve music ("" susar). Anılmayan yatak söner.
func apply_scene(scene: Dictionary, places: PrologueWorld) -> void:
	var wanted := {}
	for b: Variant in scene.get("beds", []):
		var e: Dictionary = b
		var id := str(e.get("id", ""))
		var at := Vector3.INF
		if e.get("at") is String and places:
			at = places.marker(str(e["at"]))
		elif e.get("at") is Array:
			at = Vector3(float(e["at"][0]), 0.0, float(e["at"][1]))
		bed(id, true, float(e.get("db", 0.0)), BED_FADE, at, float(e.get("radius", 0.0)))
		wanted[id] = true
	for id: String in beds.keys():
		if not wanted.has(id) and not bool((beds[id] as Dictionary).get("sticky", false)):
			bed(id, false)
	music(str(scene.get("music", "")))


## Yatağı açar ya da kapatır. at verilirse konumlu (radius m; r/2'de tam), yoksa her yerde.
func bed(id: String, on: bool, db: float = 0.0, seconds: float = BED_FADE, at: Vector3 = Vector3.INF, radius: float = 0.0) -> void:
	if id.is_empty():
		return
	if not on:
		if beds.has(id):
			(beds[id] as Dictionary)["on"] = false
			(beds[id] as Dictionary)["fade"] = seconds
		return
	var b: Dictionary = beds.get(id, {})
	if b.is_empty():
		var stream := _loop_stream(id)
		if stream == null:
			return
		var p := _make_player("Bed_" + id, &"Ambience")
		p.stream = stream
		p.play()
		b = {"player": p, "level": SILENT_DB}
		beds[id] = b
	b["on"] = true
	b["db"] = db
	b["at"] = at
	b["radius"] = radius
	b["fade"] = seconds


## Yatak çalıyor mu (hedefi açık)?
func bed_on(id: String) -> bool:
	return beds.has(id) and bool((beds[id] as Dictionary).get("on", false))


func _process(delta: float) -> void:
	var here: Vector3 = listener_source.call() if listener_source.is_valid() else Vector3.ZERO
	# Hedef düzeyler: konumlu yatak uzaklıkla söner; en yüksek üçü çalar.
	var targets := {}
	for id: String in beds:
		var b: Dictionary = beds[id]
		var t := SILENT_DB
		if bool(b.get("on", false)):
			var k := 1.0
			var at: Vector3 = b.get("at", Vector3.INF)
			var r := float(b.get("radius", 0.0))
			if at != Vector3.INF and r > 0.0:
				var d := Vector2(here.x - at.x, here.z - at.z).length()
				k = 1.0 - smoothstep(r * 0.5, r, d)
			t = float(b.get("db", 0.0)) + (linear_to_db(maxf(k, 0.0001)) if k < 1.0 else 0.0) if k > 0.001 else SILENT_DB
		targets[id] = t
	var order: Array = targets.keys()
	order.sort_custom(func(a: String, b: String) -> bool: return float(targets[a]) > float(targets[b]))
	for i in order.size():
		var id: String = order[i]
		var b: Dictionary = beds[id]
		var t := float(targets[id]) if i < MAX_BEDS else SILENT_DB
		var p: AudioStreamPlayer = b["player"]
		var rate := absf(SILENT_DB) / maxf(float(b.get("fade", BED_FADE)), 0.1)
		b["level"] = move_toward(float(b["level"]), t, rate * delta)
		p.volume_db = float(b["level"])
		if not p.playing and float(b["level"]) > SILENT_DB + 1.0:
			p.play()
	# Müziğin çapraz geçişi.
	if _music_out.playing:
		_music_out.volume_db = move_toward(_music_out.volume_db, SILENT_DB, 30.0 * delta)
		if _music_out.volume_db <= SILENT_DB + 0.5:
			_music_out.stop()


## Tek seferlik ses: konumluysa (at) 3B, değilse 2B. Kimliğin dosyası (ya da çeşitlerinden biri) yoksa yer tutucusu.
func sfx(id: String, at: Vector3 = Vector3.INF, db: float = 0.0, pitch: float = 1.0) -> Node:
	var stream := _one_shot_stream(id)
	if stream == null:
		return null
	if at != Vector3.INF:
		var p3 := _free_3d()
		p3.stream = stream
		p3.volume_db = db
		p3.pitch_scale = pitch
		p3.global_position = at
		p3.play()
		return p3
	var p2 := _free_2d()
	p2.stream = stream
	p2.volume_db = db
	p2.pitch_scale = pitch
	p2.play()
	return p2


## Müzik: kimlik ("" susar); aynı kimlik çalıyorsa bir şey yapmaz. Çapraz geçiş seconds sn.
func music(id: String, seconds: float = 3.0) -> void:
	if id == _music_id:
		return
	_music_id = id
	if _music.playing:
		var tmp := _music_out
		_music_out = _music
		_music = tmp
	if id.is_empty():
		return
	var path := MUSIC_DIR.path_join(id + ".mp3")
	var stream := AudioUtil.load_stream(path, true) if ResourceLoader.exists(path) else null
	if stream == null:
		return
	_music.stream = stream
	_music.volume_db = SILENT_DB
	_music.play()
	var t := create_tween()
	t.tween_property(_music, "volume_db", -9.0, seconds).set_trans(Tween.TRANS_SINE)


func music_id() -> String:
	return _music_id


## Her şeyi söndürür (seconds sn): yataklar ve müzik.
func stop_all(seconds: float = 1.6) -> void:
	for id: String in beds:
		(beds[id] as Dictionary)["on"] = false
		(beds[id] as Dictionary)["fade"] = seconds
	_music_id = ""
	if _music.playing:
		var t := create_tween()
		t.tween_property(_music, "volume_db", SILENT_DB, seconds)
		t.tween_callback(_music.stop)


# --- Yollar ------------------------------------------------------------------------------------------------

## Döngünün akışı: e21 dosyası, yoksa yer tutucu (döngülü).
func _loop_stream(id: String) -> AudioStream:
	var path := AMB_DIR.path_join(id + ".wav")
	if not ResourceLoader.exists(path):
		path = str(PLACEHOLDERS.get(id, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return AudioUtil.load_stream(path, true)


## Tek seferlik sesin yolları (saf; sınama): <id>.wav, <id>_a.wav …; yoksa yer tutucu.
static func sfx_paths(id: String) -> PackedStringArray:
	var out := PackedStringArray()
	var plain := SFX_DIR.path_join(id + ".wav")
	if ResourceLoader.exists(plain):
		out.append(plain)
	for v in VARIANTS:
		var p := SFX_DIR.path_join(id + v + ".wav")
		if ResourceLoader.exists(p):
			out.append(p)
	if out.is_empty():
		var base := id
		for v in VARIANTS:
			base = base.trim_suffix(v)
		var ph := str(PLACEHOLDERS.get(id, PLACEHOLDERS.get(base, "")))
		if not ph.is_empty() and ResourceLoader.exists(ph):
			out.append(ph)
	return out


func _one_shot_stream(id: String) -> AudioStream:
	var paths := PrologueSound.sfx_paths(id)
	if paths.is_empty():
		return null
	var pick := randi() % paths.size()
	if paths.size() > 1 and pick == int(_last_variant.get(id, -1)):
		pick = (pick + 1) % paths.size()
	_last_variant[id] = pick
	var path := paths[pick]
	if not _stream_cache.has(path):
		_stream_cache[path] = AudioUtil.load_stream(path, false)
	return _stream_cache[path]


func _free_3d() -> AudioStreamPlayer3D:
	for p in _pool:
		if not p.playing:
			return p
	if _pool.size() < SFX_POOL:
		var p := AudioStreamPlayer3D.new()
		p.bus = AudioUtil.bus_or_master(&"SFX")
		p.unit_size = 6.0
		p.max_distance = 140.0
		p.attenuation_filter_cutoff_hz = 2200.0
		p.attenuation_filter_db = -18.0
		add_child(p)
		_pool.append(p)
		return p
	return _pool[0]


func _free_2d() -> AudioStreamPlayer:
	for p in _pool2d:
		if not p.playing:
			return p
	if _pool2d.size() < 4:
		var p := _make_player("Sfx2D", &"SFX")
		_pool2d.append(p)
		return p
	return _pool2d[0]


## Menünün müziği ve gece çayırı susar (Önsöz'ün günleri); bırakınca çayır geri gelir (müziği sinema ya da menü kurar).
func _quiet_menu(on: bool) -> void:
	if on == _menu_quiet:
		return
	_menu_quiet = on
	var am := get_node_or_null(^"/root/AudioManager")
	if am == null:
		return
	if am.has_method(&"suspend_meadow"):
		am.call(&"suspend_meadow", on, 1.5)
	if on:
		if am.has_method(&"stop_music_bank"):
			am.call(&"stop_music_bank", 2.0)
		var menu_player: Variant = am.get(&"_music")
		if menu_player is AudioStreamPlayer and (menu_player as AudioStreamPlayer).playing:
			var p := menu_player as AudioStreamPlayer
			var t := create_tween()
			t.tween_property(p, "volume_db", SILENT_DB, 2.0)
			t.tween_callback(p.stop)
