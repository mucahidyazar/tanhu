class_name E21Sound
extends RefCounted
## E21'in sesleri (docs/design/d3/e21-atmosphere.md «Yollar ve kurallar»): ana oturumun ElevenLabs'la ürettiği dosyalar kimlikle bağlanır, dosya
## yoksa yer tutucu çalar (var olan ses ya da kodla basılan), dosya gelip içe aktarılınca kendiliğinden yerine geçer: kod değişmez.
##   döngü (yatak)     amb_<…>  res://audio/ambience/e21/<kimlik>.wav   (döngü açılır; içe aktarmanın loop_mode'u kapalı olsa da)
##   tek seferlik      sfx_<…>  res://audio/sfx/e21/<kimlik>.wav ya da <kimlik>_a/_b/_c.wav (çeşitlerden biri rastgele, aynısı art arda çalmaz)
##   müzik             mus_<…>  res://audio/music/e21/<kimlik>.mp3
## Konumlu yatak (bed) AudioStreamPlayer3D'dir: yarıçapın ötesinde susar, içinde uzaklıkla kısılır; görünmeyen kaynağın sesi boğuktur
## (attenuation_filter: uzakta alçak geçiren). Yataklar ve tek seferlik sesler çağıranın düğümünün altındadır: sahne dururken onunla gider.
##   var bed := E21Sound.bed("amb_feast_crowd", "res://audio/ambience/campfire_loop.wav", 30.0)
##   parent.add_child(bed); bed.global_position = ateş; E21Sound.fade_in(bed, 2.5)
##   E21Sound.one_shot(parent, "sfx_lamb_bleat", kuzu.global_position, {"placeholder": "res://audio/sfx/gen/lamb.wav", "max_m": 30.0})

const LOOP_DIR := "res://audio/ambience/e21"
const SFX_DIR := "res://audio/sfx/e21"
const MUSIC_DIR := "res://audio/music/e21"
const VARIANTS: Array[String] = ["", "_a", "_b", "_c", "_d"]
## Yatağın sessizden açılışı ve kapanışı (sn; atmosferin kuralı 2–4 sn).
const FADE_S := 2.5
## Sessiz sayılan düzey (dB).
const SILENT_DB := -60.0

## Son çalınan çeşit (kimlik → yol): aynısı art arda çalmasın.
static var _last: Dictionary = {}
static var _rng := RandomNumberGenerator.new()


## Kimliğin ElevenLabs dosyası var mı (içe aktarılmış)?
static func has_file(id: String) -> bool:
	return not E21Sound.paths(id).is_empty()


## Kimliğin var olan dosyaları (türü önekinden: amb_, sfx_, mus_).
static func paths(id: String) -> PackedStringArray:
	var out := PackedStringArray()
	if id.begins_with("mus_"):
		var p := MUSIC_DIR.path_join(id + ".mp3")
		if ResourceLoader.exists(p):
			out.append(p)
		return out
	var dir := LOOP_DIR if id.begins_with("amb_") else SFX_DIR
	for suffix in VARIANTS:
		var p := dir.path_join(id + suffix + ".wav")
		if ResourceLoader.exists(p):
			out.append(p)
	return out


## Akış: kimliğin dosyası (çeşitlerden biri), yoksa yer tutucu (res:// yolu; boşsa null). loop döngüyü açar.
static func stream(id: String, placeholder: String = "", loop: bool = false) -> AudioStream:
	var list := E21Sound.paths(id)
	var path := ""
	if not list.is_empty():
		path = list[0]
		if list.size() > 1:
			var avoid := str(_last.get(id, ""))
			var pick := list[_rng.randi() % list.size()]
			if pick == avoid:
				pick = list[(list.find(pick) + 1) % list.size()]
			path = pick
		_last[id] = path
	elif not placeholder.is_empty():
		path = placeholder
	if path.is_empty():
		return null
	var s := AudioUtil.load_stream(path, false)
	if s == null:
		return null
	if loop:
		# Döngü akışın kendisinde açılır: önbellekteki kaynak paylaşılır, tek seferlik çalan başka yer yoktur (yatak kimlikleri amb_ ve mus_).
		AudioUtil.enable_loop(s)
	return s


## Konumlu yatak: döngü, yarıçapın ötesinde sessiz (max_distance), içinde uzaklıkla kısılır; başlangıçta sessizdir, fade_in açar.
## bus: Ambience (müzik yatağı için Music). Akış yoksa null.
static func bed(id: String, placeholder: String, radius: float, db: float = 0.0, bus: StringName = &"Ambience") -> AudioStreamPlayer3D:
	var s := E21Sound.stream(id, placeholder, true)
	if s == null:
		return null
	var p := AudioStreamPlayer3D.new()
	p.name = id.to_pascal_case()
	p.stream = s
	p.bus = AudioUtil.bus_or_master(bus)
	p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	p.unit_size = maxf(radius * 0.35, 1.0)
	p.max_distance = radius
	p.attenuation_filter_cutoff_hz = 9000.0
	p.attenuation_filter_db = -10.0
	p.volume_db = SILENT_DB
	p.set_meta(&"bed_db", db)
	p.set_meta(&"e21_id", id)
	p.set_meta(&"placeholder", not E21Sound.has_file(id))
	return p


## Yatağı açar (çalmıyorsa başlatır) ve verilen düzeye (yoksa kendi düzeyine) karıştırır.
static func fade_in(p: AudioStreamPlayer3D, seconds: float = FADE_S, db: float = NAN) -> Tween:
	if p == null or not p.is_inside_tree():
		return null
	var want := float(p.get_meta(&"bed_db", 0.0)) if is_nan(db) else db
	if not p.playing:
		p.volume_db = SILENT_DB
		p.play(randf() * maxf(p.stream.get_length() - 0.5, 0.0) if p.stream and p.stream.get_length() > 4.0 else 0.0)
	var tw := p.create_tween()
	tw.tween_property(p, "volume_db", want, maxf(seconds, 0.01))
	return tw


## Yatağı söndürür; stop doğruysa sonunda durdurur.
static func fade_out(p: AudioStreamPlayer3D, seconds: float = FADE_S, stop: bool = true) -> Tween:
	if p == null or not p.is_inside_tree():
		return null
	var tw := p.create_tween()
	tw.tween_property(p, "volume_db", SILENT_DB, maxf(seconds, 0.01))
	if stop:
		tw.tween_callback(p.stop)
	return tw


## Tek seferlik konumlu ses: parent'ın altına kurulur, bitince silinir. opts: placeholder (res:// yolu), db, pitch (ya da pitch_jitter),
## max_m (duyulan en uzak yer; varsayılan 40), bus (SFX). Akış yoksa null.
static func one_shot(parent: Node, id: String, at: Vector3, opts: Dictionary = {}) -> AudioStreamPlayer3D:
	if parent == null or not parent.is_inside_tree():
		return null
	var s := E21Sound.stream(id, str(opts.get("placeholder", "")), false)
	if s == null:
		return null
	var p := AudioStreamPlayer3D.new()
	p.name = "%sShot" % id.to_pascal_case()
	p.stream = s
	p.bus = AudioUtil.bus_or_master(StringName(str(opts.get("bus", "SFX"))))
	p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	var max_m := float(opts.get("max_m", 40.0))
	p.max_distance = max_m
	p.unit_size = maxf(max_m * 0.18, 1.0)
	p.volume_db = float(opts.get("db", 0.0))
	var jitter := float(opts.get("pitch_jitter", 0.0))
	p.pitch_scale = float(opts.get("pitch", 1.0)) * (1.0 + _rng.randf_range(-jitter, jitter))
	parent.add_child(p)
	p.global_position = at
	p.finished.connect(p.queue_free)
	p.play()
	return p


## Konumsuz tek seferlik ses (arayüz, yakın; parent'ın altına). Akış yoksa null.
static func flat_shot(parent: Node, id: String, opts: Dictionary = {}) -> AudioStreamPlayer:
	if parent == null or not parent.is_inside_tree():
		return null
	var s := E21Sound.stream(id, str(opts.get("placeholder", "")), false)
	if s == null:
		return null
	var p := AudioStreamPlayer.new()
	p.name = "%sFlat" % id.to_pascal_case()
	p.stream = s
	p.bus = AudioUtil.bus_or_master(StringName(str(opts.get("bus", "SFX"))))
	p.volume_db = float(opts.get("db", 0.0))
	parent.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
	return p
