class_name CineAudio
extends RefCounted
## Sinemanın ses komutlarını AudioManager'a (ya da sınamanın sahte hedefine) ileten bağdaştırıcı
## (godot.md §3.3). Sözleşme (Yol Haritası voice-bus ve music-engine):
##   play_line(id, opts) → süre, play_song(id), stop_line(fade), set_music_bank(bank, state, fade),
##   set_music_state(state), set_layer_db(layer, db, sn), set_ambience_layer(id, db, sn), low_silence(on, sn),
##   black_silence(sn), play_sfx(id, opts), request_lines(ids), release_lines(ids); menüye dönüşte
##   play_music(&"menu", sn). Şarkının saat kilidi için song_position(id) → sn (yoksa -1) okunur; hedefte bu
##   yöntem yoksa hedefin çalan, şarkı dosyasını taşıyan AudioStreamPlayer çocuğunun konumu okunur.
## Hedefte yöntem yoksa komut sessizce geçer: ses çekirdeği gelmeden sinema altyazıyla akar. Fazla argüman
## hedefin yönteminin argüman sayısına kırpılır.
## İleri sarmada (seeking) satır, şarkı, efekt ve kara sessizlik çalmaz; müzik durumu, katman, ortam ve alçak
## sessizlik geçişsiz kurulur.

## Durum kuran (ileri sarmada da uygulanan) türler.
const STATE_TYPES: Array[String] = ["music", "layer", "ambience", "low_silence"]
## Ses çalan (ileri sarmada atlanan) türler.
const SOUND_TYPES: Array[String] = ["line", "song", "sfx", "black_silence", "stop_line"]
## Müzik işaretinin varsayılan geçişi (K68: menü müziği 2 sn'de camp_bard dronuna iner).
const MUSIC_FADE := 2.0
## Ana söz (A ve B dilimi, şarkı) AudioManager'da kısma başladıktan 0,15 sn sonra başlar (K78, godot.md §3.3).
const PREROLL := 0.15
## Ana sözün dilimleri.
const MAIN_TIERS: Array[String] = ["A", "B"]
const STOP_FADE := 0.3

## Komutların gittiği nesne (AudioManager ya da sahte hedef); null ise her komut sessizce geçer.
var target: Object

var _low_silence := false


func _init(p_target: Object = null) -> void:
	target = p_target


## Oyunun ses autoload'u (yoksa null).
static func autoload() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null(^"AudioManager") if tree else null


## Satırın ses isteğinin sesin başlamasından ne kadar önce gideceği (saniye): ana sözde ve şarkıda PREROLL,
## çığlık ve sistem sözünde (C) ve bilinmeyen satırda 0. Çizelge satırın _voice olayını bu kadar öne koyar.
static func lead_time(line_id: String) -> float:
	if str(VoLines.line(line_id).get("kind", "")) == "song" or MAIN_TIERS.has(VoLines.tier(line_id)):
		return PREROLL
	return 0.0


## Bu bağdaştırıcının işlediği tür mü?
static func handles(type: String) -> bool:
	return STATE_TYPES.has(type) or SOUND_TYPES.has(type)


## Çizelgenin ses olayını uygular.
func handle(ev: Dictionary, seeking: bool = false) -> void:
	var type := str(ev.get("type", ""))
	if seeking and SOUND_TYPES.has(type):
		return
	match type:
		"line":
			call_target(&"play_line", [str(ev.get("line", "")), _line_opts(ev)])
		"song":
			# pan: şarkı ozanın yönüne kayar (AudioManager pan_max'la sınırlar; kamp segmenti verir).
			call_target(&"play_song", [str(ev.get("line", "")), _line_opts(ev)])
		"stop_line":
			call_target(&"stop_line", [_number(ev, "fade", STOP_FADE)])
		"sfx":
			call_target(&"play_sfx", [str(ev.get("id", "")), _sfx_opts(ev)])
		"black_silence":
			call_target(&"black_silence", [_number(ev, "dur", 0.0)])
		"music":
			var fade := 0.0 if seeking else _number(ev, "fade", MUSIC_FADE)
			var state := str(ev.get("state", ""))
			if ev.get("bank") is String and _has(&"set_music_bank"):
				call_target(&"set_music_bank", [str(ev["bank"]), state, fade])
			else:
				call_target(&"set_music_state", [state])
		"layer":
			call_target(&"set_layer_db", [str(ev.get("layer", "")), _number(ev, "db", 0.0),
				0.0 if seeking else _number(ev, "dur", 0.0)])
		"ambience":
			call_target(&"set_ambience_layer", [str(ev.get("id", "")), _number(ev, "db", 0.0),
				0.0 if seeking else _number(ev, "dur", 0.0)])
		"low_silence":
			_low_silence = bool(ev.get("on", true))
			call_target(&"low_silence", [_low_silence, 0.0 if seeking else _number(ev, "fade", 1.0)])


## Çizelgenin satırlarını ve şarkısını arka planda yükletir (K59: sinema açılırken hepsi istenir).
func request_lines(ids: PackedStringArray) -> void:
	if not ids.is_empty():
		call_target(&"request_lines", [ids])


func release_lines(ids: PackedStringArray) -> void:
	if not ids.is_empty():
		call_target(&"release_lines", [ids])


## Sinemanın sesini durdurur (atlamada ve bitişte): satır ve şarkı söner, alçak sessizlik kalkar.
func stop_all(fade: float = 0.5) -> void:
	call_target(&"stop_line", [fade])
	if _low_silence:
		_low_silence = false
		call_target(&"low_silence", [false, fade])


## Menü müziği geri gelir (Önsöz bitince oluşturucunun ve menünün müziği).
func restore_menu_music(fade: float = MUSIC_FADE) -> void:
	call_target(&"play_music", [&"menu", fade])


## Şarkının çalış konumu (saniye, dosyanın başından); bilinmiyorsa ya da çalmıyorsa -1.
func song_position(line_id: String) -> float:
	if not _alive():
		return -1.0
	if target.has_method(&"song_position"):
		var value: Variant = call_target(&"song_position", [line_id])
		return float(value) if (value is float or value is int) else -1.0
	if not target is Node:
		return -1.0
	var path := VoLines.audio_path(line_id)
	if path.is_empty():
		return -1.0
	for child in (target as Node).get_children():
		var player := child as AudioStreamPlayer
		if player and player.playing and player.stream and player.stream.resource_path == path:
			return player.get_playback_position() + AudioServer.get_time_since_last_mix()
	return -1.0


## Hedefte yöntem varsa çağırır (fazla argüman kırpılır), yoksa null.
func call_target(method: StringName, args: Array) -> Variant:
	if not _has(method):
		return null
	var count := target.get_method_argument_count(method)
	if count >= 0 and args.size() > count:
		args = args.slice(0, count)
	return target.callv(method, args)


func _has(method: StringName) -> bool:
	return _alive() and target.has_method(method)


func _alive() -> bool:
	return target != null and is_instance_valid(target)


static func _line_opts(ev: Dictionary) -> Dictionary:
	var opts: Dictionary = (ev["opts"] as Dictionary).duplicate() if ev.get("opts") is Dictionary else {}
	for key in ["pan", "fx", "db"]:
		if ev.has(key) and not opts.has(key):
			opts[key] = ev[key]
	return opts


static func _sfx_opts(ev: Dictionary) -> Dictionary:
	var opts: Dictionary = (ev["opts"] as Dictionary).duplicate() if ev.get("opts") is Dictionary else {}
	var at: Variant = ev.get("at")
	if at is Array and (at as Array).size() == 3:
		opts["at"] = Vector3(float(at[0]), float(at[1]), float(at[2]))
	for key in ["db", "pitch", "pan"]:
		if ev.has(key) and not opts.has(key):
			opts[key] = ev[key]
	return opts


static func _number(ev: Dictionary, key: String, fallback: float) -> float:
	var value: Variant = ev.get(key)
	return float(value) if (value is float or value is int) else fallback
