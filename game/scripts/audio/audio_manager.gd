extends Node
## Müzik, ortam, efekt, arayüz sesi ve seslendirmeyi yöneten autoload (proje ayarlarında "AudioManager").
##
## Bir ses dosyası eksikse sessizce atlanır; oyun sessiz de çalışır, satır altyazıyla akar (K59).
## Veri yolları default_bus_layout.tres'tedir (godot.md §3.3): Music [Amplify, EQ10, Compressor (yan zincir Voice),
## Reverb], Ambience [Amplify, Compressor (yan zincir Voice)], SFX [Amplify], Voice [Panner, EQ10 (Erlik)].
##
## Müzik (K59, K61; audio.md §3): menünün ElevenLabs parçası play_music(&"menu") ile çalar. Dünyanın kodla basılmış
## müziği bir bankadır (MusicBank, data/audio/banks/<bank>.json): set_music_bank(bank, state, fade) bankayı kurar ve
## çalan parçadan çapraz geçer, set_music_state(state) aynı dünyada klip değiştirir (switch_to_clip_by_name; ölçü
## sınırında), set_layer_db(layer, db, sn) katman sesini tween'le yürütür. Perde rengi set_music_color ile gelir.
##
## Söz (K78; audio.md §1): play_line(id) satırı Voice yolunda çalar ve süresini döndürür (dosyası yoksa ya da
## yüklenmediyse ses yok, süre yine döner: altyazıyı çağıran gösterir). Ana sözde (A, B dilimi) Music ve Ambience
## yollarının başındaki Amplify, çalan müzik durumunun türüne göre (DuckTable) satırdan 0,15 sn önce 0,3 sn'de iner,
## satır bitince 1,0 sn'de döner; iki kompresör bu sırada kapalıdır. Sistem sözünde (C dilimi) kompresörler açık
## kalır, yan zincir kısar. Konuşma boyunca Music EQ10'un 2 kHz bandı −3 dB'dir. Kısma ve sessizlik aynı Amplify'ı
## paylaşır; tween'lerin tek sahibi burasıdır: Amplify = kısma + alçak/kara sessizlik.
##
## Sessizlik (K59; audio.md §3 «Sessizlik»): low_silence (müzik ve çayır katmanı söner, rüzgâr −40 dB, ateş kalır),
## black_silence (Music, Ambience, SFX −60 dB; Master'a dokunulmaz, dijital sıfır yok).

signal line_started(id: String)
signal line_finished(id: String)
signal music_state_changed(state: StringName)

const MUSIC_TRACKS := {
	&"menu": "res://audio/music/menu_theme.mp3",
}
const AMBIENCE_PATH := "res://audio/ambience/night_meadow_loop.wav"
const UI_SOUNDS := {
	&"hover": "res://audio/sfx/ui_click.wav",
	&"click": "res://audio/sfx/ui_click.wav",
	&"whoosh": "res://audio/sfx/whoosh.wav",
}

const MUSIC_VOLUME := 0.36
const AMBIENCE_VOLUME := 0.16

## Ortam katmanlarının ve efektlerin klasörleri: araçla basılan (gen) önce, sonra elle konan. Yol kimlikten kurulur.
const AMBIENCE_DIRS: Array[String] = ["res://audio/ambience/gen", "res://audio/ambience"]
const SFX_DIRS: Array[String] = ["res://audio/sfx/gen", "res://audio/sfx"]
const WAV_EXT := ".wav"
## Perde rengi dosyaları: data/music/act_<n>.tres.
const COLOR_DIR := "res://data/music"

const SILENT_DB := -80.0
## Kara sessizlik (K59): her şey −60 dB'e iner, rüzgâr kuyruğu kalır; iniş ve dönüş tık olmasın diye kısa.
const BLACK_SILENCE_DB := -60.0
const BLACK_EDGE := 0.08
## Alçak sessizlik (K59): katmanlar 3 sn'de sökülür, rüzgâr −40 dB.
const LOW_SILENCE_FADE := 3.0
## Kamp bırakılınca çayır döngüsünün sönme süresi (suspend_meadow).
const MEADOW_SUSPEND_FADE := 1.0
const LOW_SILENCE_WIND_DB := -40.0
const WIND_LAYER := &"wind_steppe"
## Ozanın şarkısı 2B'dir, ozanın yönüne en çok %10 kayar (K60).
const SONG_PAN_MAX := 0.1
## Tek seslik efekt havuzu (K63, godot.md §7.2): canlı 3B oynatıcı ≤40; 2B tek seslikler için küçük havuz.
const SFX_3D_MAX := 40
const SFX_2D_MAX := 8

var _music: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _ui: AudioStreamPlayer
var _ui_soft: AudioStreamPlayer
## Bankanın AudioStreamInteractive'ini çalar (Music yolu). Bankadan bankaya geçişte çalan oynatıcı _bank_out olur ve
## söner, yenisi öbüründe başlar (çapraz geçiş).
var _bank: AudioStreamPlayer
var _bank_out: AudioStreamPlayer
## Satır, şarkı ve tanıtım (Voice yolu).
var _voice: AudioStreamPlayer
var _current_track: StringName = &""
var _tweens := {}

# Banka
var _bank_id := ""
var _bank_def: Dictionary = {}
var _state: StringName = &""
var _color: MusicColor
var _built := {}                     # banka kimliği → AudioStreamInteractive
var _layer_tweens := {}              # "klip/katman" → Tween
var _choir_plays := {}               # perde → koro çalışı (K59: oynanışta perde başına ≤2)

# Ortam katmanları ve efektler
var _layers := {}                    # kimlik → AudioStreamPlayer (Ambience yolu)
var _layer_db := {}                  # kimlik → hedef dB
var _sfx_paths := {}                 # kimlik → çeşit yolları (önbellek)
var _sfx_2d: Array[AudioStreamPlayer] = []
var _sfx_3d: Array[AudioStreamPlayer3D] = []
var _low_silence := false
var _wind_before_low := SILENT_DB
var _meadow_before_low := 0.0
## Kamp bırakıldı: gece çayırı susar, alçak sessizliğin kalkması onu geri getirmez (suspend_meadow).
var _meadow_suspended := false

# Söz
var _line_id := ""
var _line_tween: Tween
var _release_tween: Tween
var _requests := {}                  # satır kimliği → istenen yol (load_threaded_request)
var _streams := {}                   # satır kimliği → yüklü AudioStream
var _draining := {}                  # bırakılan ama yüklemesi süren yollar

# Amplify bileşenleri (dB): kısma (duck) + müziğin söndürülmesi (quiet: music_off, alçak sessizlik) + kara sessizlik
# (black); her bileşenin kendi tween'i vardır, Amplify bileşenlerin toplamıdır.
var _amp := {
	"duck": {&"Music": 0.0, &"Ambience": 0.0},
	"quiet": {&"Music": 0.0},
	"black": {&"Music": 0.0, &"Ambience": 0.0, &"SFX": 0.0},
}
var _amp_tweens := {}
var _eq_db := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = _make_player(&"MusicPlayer", &"Music")
	_ambience = _make_player(&"AmbiencePlayer", &"Ambience")
	_ui = _make_player(&"UiPlayer", &"SFX")
	_ui_soft = _make_player(&"UiSoftPlayer", &"SFX")
	_bank = _make_player(&"BankPlayerA", &"Music")
	_bank_out = _make_player(&"BankPlayerB", &"Music")
	_voice = _make_player(&"VoicePlayer", &"Voice")
	_voice.finished.connect(_on_voice_finished)
	set_process(false)
	reset_buses()


func _exit_tree() -> void:
	release_lines()
	_silence_all()


## Çıkışta (kök ağaçtan çıkarken) çalan oynatıcı kalmaz: AudioServer çıkışta çalan oynatımı bırakmıyor. Haritanın bankası 2 sn'de söner
## (MapSoundscape); süren sönüşte çıkılırsa bankanın AudioStreamPlaybackInteractive'i ve altındaki onlarca Ogg oynatımı «leaked at exit»,
## Ogg'ları «resources still in use» yazılıyordu (Kışlak'ın kış bankası: 150'den çok nesne). Tween'ler durur, oynatıcılar durur ve akışları
## bırakılır, kurulmuş bankalar unutulur.
func _silence_all() -> void:
	for t: Variant in _tweens.values() + _layer_tweens.values() + _amp_tweens.values() + [_line_tween, _release_tween]:
		if t is Tween and (t as Tween).is_valid():
			(t as Tween).kill()
	_tweens.clear()
	_layer_tweens.clear()
	var players: Array = [_music, _ambience, _ui, _ui_soft, _bank, _bank_out, _voice]
	players.append_array(_layers.values())
	players.append_array(_sfx_2d)
	players.append_array(_sfx_3d)
	for p: Variant in players:
		if p is Node and is_instance_valid(p):
			p.call(&"stop")
			p.set(&"stream", null)
	_built.clear()
	_bank_id = ""
	_bank_def = {}
	# Durdurulan oynatımı AudioServer ses iş parçacığının sonraki karışımlarında siler (≈12 ms'lik tampon başına bir adım); çıkış ondan
	# önce sürücüyü kapatırsa oynatım (dünyanın az önce bırakılan 3B sesleri de) yine bırakılmazdı. Kökün AudioManager'ı (autoload) çıkışta
	# 60 ms bekler; sınamaların kendi kopyaları beklemez.
	if is_inside_tree() and get_parent() == get_tree().root:
		OS.delay_msec(60)


# --- Menü müziği, gece ambiyansı ve arayüz (ElevenLabs dosyaları) ---------------------------

## Müziği yavaşça açar. Aynı parça zaten çalıyorsa bir şey yapmaz. Banka çalıyorsa ondan geçer.
## Menü bankasının kaynağı "baked" olunca (kulak onayından sonra) menü bankanın camp klibini çalar.
func play_music(track: StringName, fade_time: float = 3.0) -> void:
	if track == &"menu" and MusicBank.menu_source(MusicBank.load_def("camp")) == "baked":
		set_music_bank("camp", &"camp", fade_time)
		return
	if _current_track == track and _music.playing:
		return
	var stream := AudioUtil.load_stream(MUSIC_TRACKS.get(track, ""), true)
	if stream == null:
		return
	stop_music_bank(minf(fade_time, 2.0))
	_current_track = track
	_music.stream = stream
	_set_linear(0.0, _music)
	_music.play()
	_fade(_music, MUSIC_VOLUME, fade_time)


## Gece çayırı ambiyansını (cırcır böcekleri, rüzgâr) döngüde çalar.
func play_ambience(fade_time: float = 4.0) -> void:
	if _ambience.playing:
		return
	var stream := AudioUtil.load_stream(AMBIENCE_PATH, true)
	if stream == null:
		return
	_ambience.stream = stream
	_set_linear(0.0, _ambience)
	_ambience.play()
	_fade(_ambience, 0.0 if _low_silence or _meadow_suspended else AMBIENCE_VOLUME, fade_time)


## Arayüz sesi çalar: &"hover", &"click" veya &"whoosh".
func play_ui(kind: StringName) -> void:
	var stream := AudioUtil.load_stream(UI_SOUNDS.get(kind, ""), false)
	if stream == null:
		return
	var player := _ui_soft if kind == &"hover" else _ui
	player.stream = stream
	match kind:
		&"hover":
			player.pitch_scale = randf_range(1.5, 1.65)
			player.volume_db = -16.0
		&"whoosh":
			player.pitch_scale = 1.0
			player.volume_db = -7.0
		_:
			player.pitch_scale = randf_range(0.95, 1.05)
			player.volume_db = -5.0
	player.play()


## Bütün oynatıcıları hemen durdurur ve seslerini bırakır (sınamalar ve sahne kapanışı): ses sunucusu çalış
## kayıtlarını bir sonraki karışımda boşaltır. Satır, banka ve ortam katmanları sıfırlanır; yol efektlerine ve
## sessizlik durumuna dokunulmaz (onları reset_buses sıfırlar).
func stop_all() -> void:
	for table: Dictionary in [_tweens, _layer_tweens]:
		for key: Variant in table:
			if (table[key] as Tween).is_valid():
				(table[key] as Tween).kill()
		table.clear()
	if _line_tween and _line_tween.is_valid():
		_line_tween.kill()
	_line_id = ""
	for child in get_children():
		if child is AudioStreamPlayer:
			(child as AudioStreamPlayer).stop()
			(child as AudioStreamPlayer).stream = null
		elif child is AudioStreamPlayer3D:
			(child as AudioStreamPlayer3D).stop()
			(child as AudioStreamPlayer3D).stream = null
	for id: StringName in _layers:
		(_layers[id] as Node).queue_free()
	_layers.clear()
	_layer_db.clear()
	_bank_id = ""
	_bank_def = {}
	_state = &""
	_current_track = &""


## Tüm sesleri kısar; çıkışta kullanılır. Bittiğinde dönen Tween'in finished sinyali tetiklenir.
func fade_out_all(duration: float = 0.8) -> Tween:
	var tween := create_tween().set_parallel(true)
	var players: Array[AudioStreamPlayer] = [_music, _ambience, _bank, _bank_out, _voice]
	for id: StringName in _layers:
		players.append(_layers[id])
	for player in players:
		tween.tween_method(_set_linear.bind(player), _get_linear(player), 0.0, duration)
	return tween


# --- Müzik bankası (MusicBank) --------------------------------------------------------------

## Bankayı kurar ve `state` klibiyle başlatır: çalan parçadan (menünün ElevenLabs parçası ya da başka banka)
## `fade` saniyede çapraz geçer. Banka zaten çalıyorsa yalnız durumu değiştirir. Banka ya da klip yoksa false.
func set_music_bank(bank: String, state: StringName, fade: float = 2.0) -> bool:
	if bank == _bank_id and _bank.playing:
		return set_music_state(state)
	var stream := _bank_stream(bank)
	var def := MusicBank.load_def(bank)
	var index := MusicBank.clip_index(def, state)
	if stream == null or index == -1:
		return false
	if _bank.playing:
		# Başka banka çalıyor: o oynatıcı söner, yeni banka öbüründe başlar.
		var old := _bank
		_bank = _bank_out
		_bank_out = old
		_fade_and_stop(_bank_out, fade)
	_kill_player_tween(_bank)
	# Banka baştan başlar: önceki çalışın katman düzeyleri (sinemanın set_layer_db'leri) taşınmaz.
	_reset_layers(stream, def)
	stream.initial_clip = index
	_bank_id = bank
	_bank_def = def
	_state = state
	_bank.stream = stream
	_set_linear(0.0, _bank)
	_bank.play()
	_fade(_bank, MUSIC_VOLUME, fade)
	if _music.playing:
		_fade_and_stop(_music, fade)
	_current_track = &""
	_note_choir(state)
	music_state_changed.emit(state)
	return true


## Aynı dünyada müzik durumunu değiştirir (bankanın klibi; geçiş bankanın kuralıyla, ölçü sınırında). Klip yoksa false.
func set_music_state(state: StringName) -> bool:
	if _bank_id.is_empty() or MusicBank.clip_index(_bank_def, state) == -1:
		return false
	if state == _state:
		return true
	if _bank.playing:
		var playback := _bank.get_stream_playback() as AudioStreamPlaybackInteractive
		if playback:
			playback.switch_to_clip_by_name(state)
	_state = state
	_note_choir(state)
	music_state_changed.emit(state)
	return true


## Çalan bankanın müzik durumu; banka çalmıyorsa boş (menünün parçası `camp` sayılır: DuckTable.DEFAULT_STATE).
func current_music_state() -> StringName:
	return _state


## Çalan bankanın kimliği (yoksa boş).
func current_music_bank() -> String:
	return _bank_id


## Bankanın Synchronized katmanının sesini `seconds` saniyede `db`'ye yürütür (küçük adımlarla; sıçrama olmaz).
## state boşsa çalan klip. Banka, klip ya da katman yoksa false.
func set_layer_db(layer: StringName, db: float, seconds: float = 2.0, state: StringName = &"") -> bool:
	var clip := state if state != &"" else _state
	var sync := music_clip_stream(clip)
	var index := MusicBank.layer_index(_bank_def, clip, layer)
	if sync == null or index == -1:
		return false
	var key := "%s/%s" % [clip, layer]
	if _layer_tweens.has(key) and (_layer_tweens[key] as Tween).is_valid():
		(_layer_tweens[key] as Tween).kill()
	var target := maxf(db, SILENT_DB)
	if seconds <= 0.0:
		sync.set_sync_stream_volume(index, target)
		return true
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void: sync.set_sync_stream_volume(index, v),
			sync.get_sync_stream_volume(index), target, seconds)
	_layer_tweens[key] = tween
	return true


## Katmanın şu anki sesi (dB); yoksa SILENT_DB.
func layer_db(layer: StringName, state: StringName = &"") -> float:
	var clip := state if state != &"" else _state
	var sync := music_clip_stream(clip)
	var index := MusicBank.layer_index(_bank_def, clip, layer)
	return sync.get_sync_stream_volume(index) if sync and index != -1 else SILENT_DB


## Çalan bankadaki klibin Synchronized'ı (yoksa null).
func music_clip_stream(state: StringName) -> AudioStreamSynchronized:
	var stream := _built.get(_bank_id) as AudioStreamInteractive
	var index := MusicBank.clip_index(_bank_def, state)
	return stream.get_clip_stream(index) as AudioStreamSynchronized if stream and index != -1 else null


## Bankanın çalan oynatıcısı (Music yolu; sınamalar ve hata ayıklama için).
func bank_player() -> AudioStreamPlayer:
	return _bank


## Bankayı `fade` saniyede susturur ve durdurur.
func stop_music_bank(fade: float = 2.0) -> void:
	if _bank.playing:
		_fade_and_stop(_bank, fade)
	_bank_id = ""
	_bank_def = {}
	_state = &""


## Müziği (menü parçası ve banka) Music yolunun Amplify'ında `fade` saniyede söndürür; music_on geri açar.
func music_off(fade: float = 2.0) -> void:
	_tween_amp("quiet", &"Music", SILENT_DB, fade)


func music_on(fade: float = 2.0) -> void:
	_tween_amp("quiet", &"Music", 0.0, fade)


## Perde rengi (data/music/act_<n>.tres): kurulu bankalar yeniden kurulur; çalan bankanın öbekli katmanları tween'le
## yeni sesine yürür (boş cümle kopyası bankanın sonraki başlangıcında değişir).
func set_music_color(color: MusicColor) -> void:
	_color = color
	var keep: Variant = _built.get(_bank_id)
	_built.clear()
	if keep != null:
		_built[_bank_id] = keep
	for clip_name in MusicBank.clip_names(_bank_def):
		for layer: Variant in MusicBank.layers(MusicBank.clip(_bank_def, StringName(clip_name))):
			if layer is Dictionary and str(layer.get("group", "")) != "":
				set_layer_db(StringName(str(layer.get("name", ""))), MusicBank.layer_volume(layer, color), 2.0, StringName(clip_name))


## Perdenin rengini yükler (data/music/act_<n>.tres; yoksa null).
static func load_music_color(act: int) -> MusicColor:
	var path := COLOR_DIR.path_join("act_%d.tres" % act)
	return load(path) as MusicColor if ResourceLoader.exists(path) else null


func music_color() -> MusicColor:
	return _color


## Perdenin koro çalışı (K59: koro yalnız tengri ve dawn; oynanışta perde başına ≤2). Günlüğe de yazılır.
func choir_plays(act: int) -> int:
	return int(_choir_plays.get(act, 0))


func _bank_stream(bank: String) -> AudioStreamInteractive:
	if not _built.has(bank):
		if _color == null:
			_color = load_music_color(0)
		var stream := MusicBank.build(MusicBank.load_def(bank), _color)
		if stream == null:
			return null
		_built[bank] = stream
	return _built[bank]


## Kurulu bankanın bütün kliplerinde katmanları bankanın (ve perde renginin) düzeyine döndürür, süren katman
## geçişlerini keser: Önsöz yeniden oynayınca (ör. «Her yeni oyunda») kamp dronu, mitin kopuzu ve doğumun dronu ilk
## oynatmadaki gibi başlar.
func _reset_layers(stream: AudioStreamInteractive, def: Dictionary) -> void:
	for key: Variant in _layer_tweens:
		if (_layer_tweens[key] as Tween).is_valid():
			(_layer_tweens[key] as Tween).kill()
	_layer_tweens.clear()
	for clip_name in MusicBank.clip_names(def):
		var sync := stream.get_clip_stream(MusicBank.clip_index(def, StringName(clip_name))) as AudioStreamSynchronized
		if sync == null:
			continue
		var list := MusicBank.layers(MusicBank.clip(def, StringName(clip_name)))
		for i in mini(list.size(), sync.stream_count):
			if list[i] is Dictionary and sync.get_sync_stream(i) != null:
				sync.set_sync_stream_volume(i, MusicBank.layer_volume(list[i], _color))


func _note_choir(state: StringName) -> void:
	for layer: Variant in MusicBank.layers(MusicBank.clip(_bank_def, state)):
		if layer is Dictionary and MusicBank.is_choir(layer):
			var act := _color.act if _color else 0
			_choir_plays[act] = choir_plays(act) + 1
			print("[ses] koro: perde %d, %d. çalış (%s)" % [act, _choir_plays[act], state])
			return


# --- Ortam katmanları, sessizlik ve efektler ------------------------------------------------

## Ortam döngüsünü (audio/ambience/gen/<id>.wav, yoksa audio/ambience/<id>.wav) `seconds` saniyede `db`'ye
## yürütür; çalmıyorsa sessizden başlatır, SILENT_DB'ye inince durdurur. Dosya yoksa false.
func set_ambience_layer(id: StringName, db: float, seconds: float = 2.0) -> bool:
	var player := _layer_player(id)
	if player == null:
		return false
	var target := maxf(db, SILENT_DB)
	_layer_db[id] = target
	if not player.playing:
		player.volume_db = SILENT_DB
		player.play()
	_fade_db(player, target, seconds, target <= SILENT_DB)
	return true


## Ortam katmanının hedef sesi (dB); çalmıyorsa SILENT_DB.
func ambience_layer_db(id: StringName) -> float:
	return float(_layer_db.get(id, SILENT_DB))


## Alçak sessizlik (K59): müzik ve çayır katmanı `seconds` saniyede söner, rüzgâr −40 dB'e iner, ateş çıtırtısı
## (sahnedeki 3B ses) kalır. off ile her şey önceki düzeyine döner.
func low_silence(on: bool, seconds: float = LOW_SILENCE_FADE) -> void:
	if on == _low_silence:
		return
	_low_silence = on
	if on:
		_wind_before_low = ambience_layer_db(WIND_LAYER)
		_meadow_before_low = _get_linear(_ambience) if _ambience.playing else 0.0
		music_off(seconds)
		if _ambience.playing:
			_fade(_ambience, 0.0, seconds)
		set_ambience_layer(WIND_LAYER, LOW_SILENCE_WIND_DB, seconds)
	else:
		music_on(seconds)
		if _ambience.playing and not _meadow_suspended:
			_fade(_ambience, _meadow_before_low if _meadow_before_low > 0.0 else AMBIENCE_VOLUME, seconds)
		if _layers.has(WIND_LAYER):
			set_ambience_layer(WIND_LAYER, _wind_before_low, seconds)


func is_low_silence() -> bool:
	return _low_silence


## Gece çayırı kampındır (cırcır böcekleri): kamp dünyası bırakılınca (CineHost.release_camp) mit panolarının ve Ordos'un
## şafağının altında çalmaz; kamp geri gelince (restore_camp) yeniden duyulur, alçak sessizlik sürüyorsa onun kalkışını bekler.
func suspend_meadow(on: bool, seconds: float = MEADOW_SUSPEND_FADE) -> void:
	if on == _meadow_suspended:
		return
	_meadow_suspended = on
	if not _ambience.playing:
		return
	if on:
		_fade(_ambience, 0.0, seconds)
	elif not _low_silence:
		_fade(_ambience, AMBIENCE_VOLUME, seconds)


func is_meadow_suspended() -> bool:
	return _meadow_suspended


## Kara sessizlik (K59): Music, Ambience ve SFX'in Amplify'ı `seconds` saniye −60 dB'te durur, sonra döner; Master'a
## dokunulmaz, dijital sıfır yoktur (rüzgâr kuyruğu −60 dB'te kalır). Dönen Tween'in finished'ı sessizliğin sonudur.
func black_silence(seconds: float = 2.5) -> Tween:
	var hold := maxf(seconds - 2.0 * BLACK_EDGE, 0.0)
	var tween := create_tween()
	tween.tween_method(_set_black, amp_component("black", &"Music"), BLACK_SILENCE_DB, BLACK_EDGE)
	tween.tween_interval(hold)
	tween.tween_method(_set_black, BLACK_SILENCE_DB, 0.0, BLACK_EDGE)
	_kill_amp_tween("black")
	_amp_tweens["black"] = tween
	return tween


## Efekt çalar: audio/sfx/gen/<id>.wav (yoksa audio/sfx/<id>.wav); `<id>_v1`, `<id>_v2` … çeşitleri varsa biri
## rastgele seçilir. opts: at (Vector3: 3B havuzdan, ≤40), volume_db (ya da db), pitch, bus. Dosya yoksa null.
func play_sfx(id: StringName, opts: Dictionary = {}) -> Node:
	var paths := sfx_variants(id)
	if paths.is_empty():
		return null
	var stream := AudioUtil.load_stream(paths[randi() % paths.size()], false)
	if stream == null:
		return null
	var bus := AudioUtil.bus_or_master(StringName(str(opts.get("bus", "SFX"))))
	var volume := float(opts.get("volume_db", opts.get("db", 0.0)))
	var pitch := float(opts.get("pitch", 1.0))
	if opts.get("at") is Vector3:
		var p3 := _free_3d()
		p3.stream = stream
		p3.bus = bus
		p3.volume_db = volume
		p3.pitch_scale = pitch
		p3.position = opts["at"]
		p3.play()
		return p3
	var p2 := _free_2d()
	p2.stream = stream
	p2.bus = bus
	p2.volume_db = volume
	p2.pitch_scale = pitch
	p2.play()
	return p2


## Efektin çeşit yolları (önbellekli): <id>.wav ve <id>_v<n>.wav, önce araçla basılan klasör.
func sfx_variants(id: StringName) -> PackedStringArray:
	if _sfx_paths.has(id):
		return _sfx_paths[id]
	var paths := PackedStringArray()
	for dir in SFX_DIRS:
		var plain := dir.path_join(String(id) + WAV_EXT)
		if ResourceLoader.exists(plain):
			paths.append(plain)
		var n := 1
		while ResourceLoader.exists(dir.path_join("%s_v%d%s" % [id, n, WAV_EXT])):
			paths.append(dir.path_join("%s_v%d%s" % [id, n, WAV_EXT]))
			n += 1
		if not paths.is_empty():
			break
	_sfx_paths[id] = paths
	return paths


func _layer_player(id: StringName) -> AudioStreamPlayer:
	if _layers.has(id):
		return _layers[id]
	for dir in AMBIENCE_DIRS:
		var stream := AudioUtil.load_stream(dir.path_join(String(id) + WAV_EXT), true)
		if stream:
			var player := _make_player(StringName("Layer_%s" % id), &"Ambience")
			player.stream = stream
			_layers[id] = player
			return player
	return null


func _free_2d() -> AudioStreamPlayer:
	for p in _sfx_2d:
		if not p.playing:
			return p
	if _sfx_2d.size() < SFX_2D_MAX:
		var player := _make_player(StringName("Sfx2D_%d" % _sfx_2d.size()), &"SFX")
		_sfx_2d.append(player)
		return player
	var oldest: AudioStreamPlayer = _sfx_2d.pop_front()
	oldest.stop()
	_sfx_2d.append(oldest)
	return oldest


func _free_3d() -> AudioStreamPlayer3D:
	for p in _sfx_3d:
		if not p.playing:
			return p
	if _sfx_3d.size() < SFX_3D_MAX:
		var player := AudioStreamPlayer3D.new()
		player.name = "Sfx3D_%d" % _sfx_3d.size()
		player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		add_child(player)
		_sfx_3d.append(player)
		return player
	# Havuz dolu: en eski çalan susar, yenisi girer.
	var oldest: AudioStreamPlayer3D = _sfx_3d.pop_front()
	oldest.stop()
	_sfx_3d.append(oldest)
	return oldest


# --- Söz: satır, şarkı ve tanıtım (K78) -----------------------------------------------------

## Satırları arka planda ister (load_threaded_request; sinema açılırken bütün satırlar). Dosyası olmayan satır atlanır.
func request_lines(ids: PackedStringArray) -> void:
	for id in ids:
		if _streams.has(id) or _requests.has(id):
			continue
		var path := VoLines.audio_path(id)
		if path.is_empty():
			continue
		if ResourceLoader.load_threaded_request(path, "AudioStream") == OK:
			_requests[id] = path


## İstenen ya da yüklü satırları bırakır (boşsa hepsini). Yüklemesi süren satır bitince sessizce boşaltılır.
func release_lines(ids: PackedStringArray = PackedStringArray()) -> void:
	var list := ids
	if list.is_empty():
		list = PackedStringArray(_requests.keys())
		for id: String in _streams:
			if not list.has(id):
				list.append(id)
	for id in list:
		_streams.erase(id)
		if _requests.has(id):
			_drain(str(_requests[id]))
			_requests.erase(id)


## Satır istendi ve henüz yükleniyor mu?
func is_line_pending(id: String) -> bool:
	return _requests.has(id) and ResourceLoader.load_threaded_get_status(_requests[id]) == ResourceLoader.THREAD_LOAD_IN_PROGRESS


## Satırın çalınabilir sesi: yüklüyse o; istendi ama yüklenmediyse null (ses yok, altyazı akar); hiç istenmediyse
## dosyası şimdi yüklenir (küçük MP3, çözülmeden durur). Dosyası olmayan satırda null.
func line_stream(id: String) -> AudioStream:
	if _streams.has(id):
		return _streams[id]
	if _requests.has(id):
		var path: String = _requests[id]
		if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_LOADED:
			return null
		var loaded := ResourceLoader.load_threaded_get(path) as AudioStream
		_requests.erase(id)
		if loaded:
			_streams[id] = loaded
		return loaded
	var file := VoLines.audio_path(id)
	if file.is_empty():
		return null
	var stream := load(file) as AudioStream
	if stream:
		_streams[id] = stream
	return stream


## Satırı Voice yolunda çalar ve süresini döndürür (saniye: dosya varsa onun boyu, yoksa vo_lines.json'un `seconds`'ı).
## Ana sözde (A, B dilimi) ses kısmanın ardından PREROLL (0,15 sn) sonra başlar; line_started ses başlayınca, line_finished
## satır bitince yayılır. opts: state (kısmanın durumu; yoksa çalan müzik durumu), kind (DuckTable türü), tier, fx
## ("erlik": satır −3 dB, Voice EQ10'un 800 Hz altı +2 dB), pan (−1..1), delay (sesin gecikmesi), volume_db (ya da db).
## CineAudio satırın olayını DuckTable.PREROLL öne koyar: ses çizelgedeki anında başlar.
func play_line(id: String, opts: Dictionary = {}) -> float:
	var stream := line_stream(id)
	var o := opts.duplicate()
	if not o.has("tier"):
		o["tier"] = VoLines.tier(id)
	if not o.has("fx"):
		o["fx"] = VoLines.fx(id)
	var seconds := stream.get_length() if stream and stream.get_length() > 0.0 else VoLines.seconds(id)
	return _speak(id, stream, seconds, o)


## Ozanın şarkısı (act0.bard.song): Voice yolunda 2B, ozanın yönüne en çok SONG_PAN_MAX (ya da zaman dosyasının
## pan_max'ı) kayar; kısma anlatı türündedir (K78). Süresini döndürür.
func play_song(id: String, opts: Dictionary = {}) -> float:
	var o := opts.duplicate()
	var pan_max := float(VoLines.timing(id).get("pan_max", SONG_PAN_MAX))
	o["pan"] = clampf(float(o.get("pan", 0.0)), -pan_max, pan_max)
	o["kind"] = DuckTable.NARRATIVE
	o["tier"] = "A"
	return play_line(id, o)


## Verilen sesi ana söz olarak çalar (Destan Kitabı'nın tanıtımı, K86): Voice yolu, Amplify kısması. Süresini döndürür.
## opts play_line'ınkilerdir; ayrıca id (sinyallerde görünen kimlik).
func play_voice_stream(stream: AudioStream, opts: Dictionary = {}) -> float:
	if stream == null:
		return 0.0
	var o := opts.duplicate()
	if not o.has("tier"):
		o["tier"] = "A"
	return _speak(str(o.get("id", "voice_stream")), stream, stream.get_length(), o)


## Çalan satırı `fade` saniyede susturur; kısma 1,0 sn'de döner. Satır yoksa bir şey yapmaz.
func stop_line(fade: float = 0.2) -> void:
	if _line_id.is_empty():
		return
	var id := _line_id
	if _line_tween and _line_tween.is_valid():
		_line_tween.kill()
	if _voice.playing:
		_fade_and_stop(_voice, fade)
	_finish_line(id)


## Çalan satırın kimliği (yoksa boş).
func current_line() -> String:
	return _line_id


## Satırın (şarkının) çalış konumu, saniye, dosyanın başından; çalmıyorsa -1. Sinema saati şarkıya bunu okuyarak
## kilitlenir (CineAudio.song_position).
func song_position(id: String) -> float:
	if id != _line_id or not _voice.playing:
		return -1.0
	return _voice.get_playback_position() + AudioServer.get_time_since_last_mix()


func is_speaking() -> bool:
	return not _line_id.is_empty()


func _speak(id: String, stream: AudioStream, seconds: float, opts: Dictionary) -> float:
	_interrupt_line()
	var main := str(opts.get("tier", "A")) != "C"
	var duck := Vector2.ZERO
	if main:
		var kind := StringName(str(opts.get("kind", "")))
		duck = DuckTable.LEVELS.get(kind, DuckTable.levels(StringName(str(opts.get("state", _state)))))
		_set_compressors(false)
		_tween_amp("duck", &"Music", duck.x, DuckTable.ATTACK)
		_tween_amp("duck", &"Ambience", duck.y, DuckTable.ATTACK)
	_tween_eq(DuckTable.EQ_DB, DuckTable.ATTACK)
	var erlik := str(opts.get("fx", "")) == "erlik"
	AudioUtil.set_effect_enabled(&"Voice", "AudioEffectEQ10", erlik)
	_set_pan(clampf(float(opts.get("pan", 0.0)), -1.0, 1.0))
	if _release_tween and _release_tween.is_valid():
		_release_tween.kill()
	_kill_player_tween(_voice)
	_line_id = id
	_voice.stream = stream
	_voice.volume_db = float(opts.get("volume_db", opts.get("db", 0.0))) + (DuckTable.ERLIK_LINE_DB if erlik else 0.0)
	var delay := maxf(float(opts.get("delay", DuckTable.PREROLL if main else 0.0)), 0.0)
	_line_tween = create_tween()
	if delay > 0.0:
		_line_tween.tween_interval(delay)
	_line_tween.tween_callback(_start_voice.bind(id))
	_line_tween.tween_interval(maxf(seconds, 0.01))
	_line_tween.tween_callback(_finish_line.bind(id))
	return seconds


func _start_voice(id: String) -> void:
	if id != _line_id:
		return
	if _voice.stream:
		_voice.play()
	line_started.emit(id)


## Satır bitti: kısma, EQ ve (ana sözde) kompresörler RELEASE'te döner.
## Zaman çizelgesinin (_line_tween) son adımı da burayı çağırır: tween'i burada öldürmek kendi geri çağrısını keserdi;
## erken bitişte (stop_line, sesin kendi sonu) çağıran öldürür.
func _finish_line(id: String) -> void:
	if id != _line_id:
		return
	_line_id = ""
	# Biten satırın başvurusu bırakılır (K59: satır penceresi Godot'da yükleme kuralıdır).
	_streams.erase(id)
	line_finished.emit(id)
	_tween_amp("duck", &"Music", 0.0, DuckTable.RELEASE)
	_tween_amp("duck", &"Ambience", 0.0, DuckTable.RELEASE)
	_tween_eq(0.0, DuckTable.RELEASE)
	_release_tween = create_tween()
	_release_tween.tween_interval(DuckTable.RELEASE)
	_release_tween.tween_callback(_after_release)


func _after_release() -> void:
	if not _line_id.is_empty():
		return
	_set_compressors(true)
	AudioUtil.set_effect_enabled(&"Voice", "AudioEffectEQ10", false)
	_set_pan(0.0)


## Yeni satır gelince çalan satır hemen susar (kısma yeni satırın hedefine o anki değerden iner).
func _interrupt_line() -> void:
	if _line_id.is_empty():
		return
	var id := _line_id
	_line_id = ""
	if _line_tween and _line_tween.is_valid():
		_line_tween.kill()
	_voice.stop()
	line_finished.emit(id)


func _on_voice_finished() -> void:
	if _line_id.is_empty():
		return
	if _line_tween and _line_tween.is_valid():
		_line_tween.kill()
	_finish_line(_line_id)


func _drain(path: String) -> void:
	match ResourceLoader.load_threaded_get_status(path):
		ResourceLoader.THREAD_LOAD_LOADED:
			ResourceLoader.load_threaded_get(path)
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_draining[path] = true
			set_process(true)


func _process(_delta: float) -> void:
	for path: String in _draining.keys():
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			continue
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			ResourceLoader.load_threaded_get(path)
		_draining.erase(path)
	if _draining.is_empty():
		set_process(false)


# --- Veri yolu efektleri -------------------------------------------------------------------

## Yolların efektlerini kısmasız, sessizliksiz başlangıç hâline döndürür (açılışta ve sınamalardan sonra):
## Amplify'lar 0 dB, Music EQ10 düz, kompresörler açık, Voice EQ10 kapalı, Panner ortada.
func reset_buses() -> void:
	for key: Variant in _amp_tweens:
		if (_amp_tweens[key] as Tween).is_valid():
			(_amp_tweens[key] as Tween).kill()
	_amp_tweens.clear()
	for component: String in _amp:
		var table: Dictionary = _amp[component]
		for bus: StringName in table:
			table[bus] = 0.0
	for bus: StringName in [&"Music", &"Ambience", &"SFX"]:
		_apply_amp(bus)
	_low_silence = false
	_meadow_suspended = false
	_eq_db = 0.0
	_apply_eq()
	_set_compressors(true)
	AudioUtil.set_effect_enabled(&"Voice", "AudioEffectEQ10", false)
	_set_pan(0.0)


## Yolun başındaki Amplify'ın sesi (dB); yoksa 0.
func amp_db(bus: StringName) -> float:
	var amp := AudioUtil.bus_effect(bus, "AudioEffectAmplify") as AudioEffectAmplify
	return amp.volume_db if amp else 0.0


func _set_black(db: float) -> void:
	var table: Dictionary = _amp["black"]
	for bus: StringName in table:
		table[bus] = db
		_apply_amp(bus)


## Amplify bileşenini (duck, quiet) `seconds` saniyede `db`'ye yürütür; aynı bileşenin önceki tween'i kesilir.
func _tween_amp(component: String, bus: StringName, db: float, seconds: float) -> void:
	var table: Dictionary = _amp[component]
	var key := "%s/%s" % [component, bus]
	_kill_amp_tween(key)
	if seconds <= 0.0:
		table[bus] = db
		_apply_amp(bus)
		return
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void:
		table[bus] = v
		_apply_amp(bus), float(table[bus]), db, seconds)
	_amp_tweens[key] = tween


func _kill_amp_tween(key: Variant) -> void:
	if _amp_tweens.has(key) and (_amp_tweens[key] as Tween).is_valid():
		(_amp_tweens[key] as Tween).kill()
	_amp_tweens.erase(key)


## Amplify = kısma + söndürme + kara sessizlik (en az SILENT_DB).
func _apply_amp(bus: StringName) -> void:
	var amp := AudioUtil.bus_effect(bus, "AudioEffectAmplify") as AudioEffectAmplify
	if amp == null:
		return
	var db := 0.0
	for component: String in _amp:
		db += float((_amp[component] as Dictionary).get(bus, 0.0))
	amp.volume_db = maxf(db, SILENT_DB)


## Amplify bileşeninin şu anki değeri (dB; sınamalar ve hata ayıklama için).
func amp_component(component: String, bus: StringName) -> float:
	return float((_amp.get(component, {}) as Dictionary).get(bus, 0.0))


func _tween_eq(db: float, seconds: float) -> void:
	_kill_amp_tween("eq")
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void:
		_eq_db = v
		_apply_eq(), _eq_db, db, maxf(seconds, 0.001))
	_amp_tweens["eq"] = tween


func _apply_eq() -> void:
	var eq := AudioUtil.bus_effect(&"Music", "AudioEffectEQ10") as AudioEffectEQ
	if eq:
		eq.set_band_gain_db(DuckTable.EQ_BAND, _eq_db)


func _set_compressors(on: bool) -> void:
	AudioUtil.set_effect_enabled(&"Music", "AudioEffectCompressor", on)
	AudioUtil.set_effect_enabled(&"Ambience", "AudioEffectCompressor", on)


func _set_pan(pan: float) -> void:
	var panner := AudioUtil.bus_effect(&"Voice", "AudioEffectPanner") as AudioEffectPanner
	if panner:
		panner.pan = pan


# --- Oynatıcılar --------------------------------------------------------------------------

func _make_player(player_name: StringName, bus: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = AudioUtil.bus_or_master(bus)
	add_child(player)
	return player


func _fade(player: AudioStreamPlayer, target: float, duration: float) -> void:
	if _tweens.has(player) and _tweens[player].is_valid():
		_tweens[player].kill()
	var tween := create_tween()
	tween.tween_method(_set_linear.bind(player), _get_linear(player), target, maxf(duration, 0.001))
	_tweens[player] = tween


func _kill_player_tween(player: AudioStreamPlayer) -> void:
	if _tweens.has(player) and _tweens[player].is_valid():
		_tweens[player].kill()
	_tweens.erase(player)


func _fade_and_stop(player: AudioStreamPlayer, duration: float) -> void:
	_fade(player, 0.0, duration)
	(_tweens[player] as Tween).tween_callback(player.stop)


## Oynatıcının sesini dB ölçeğinde yürütür (ortam katmanları); stop_after ise sonunda durdurur.
func _fade_db(player: AudioStreamPlayer, db: float, duration: float, stop_after: bool) -> void:
	if _tweens.has(player) and _tweens[player].is_valid():
		_tweens[player].kill()
	var tween := create_tween()
	tween.tween_property(player, "volume_db", db, maxf(duration, 0.001))
	if stop_after:
		tween.tween_callback(player.stop)
	_tweens[player] = tween


# Ses seviyesini doğrusal (0..1) ölçekte ayarlar; kulağa daha doğal bir geçiş verir.
func _set_linear(value: float, player: AudioStreamPlayer) -> void:
	player.volume_db = linear_to_db(maxf(value, 0.0001))


func _get_linear(player: AudioStreamPlayer) -> float:
	return db_to_linear(player.volume_db)
