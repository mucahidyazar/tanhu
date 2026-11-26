class_name SceneVoice
extends RefCounted
## Oynanan sahnelerin sözü (E20/7; K61, K78, K98): Çocukluk, Yola Çıkış ve Serbest Gez'in kampı. Sahnenin satırı (anahtarı) vo_lines.json'un
## satırına bağlanır (prefix + anahtar: «act0.child.» + «wake»). Satırın sesi varsa AudioManager.play_line onu Voice yolunda çalar (ana sözde
## kısma DuckTable'ın türüyle, sesin önüne PREROLL; satırın gain_db'si −18 LUFS'a getirir), altyazı sesin süresi kadar (+ TAIL, en az MIN_SUB)
## durur; sesi olmayan satır bugünkü gibi yalnız altyazıdır, süresi text_seconds'tır (K89). Sözler üst üste binmez: konuşulurken gelen söz
## sıraya girer, önceki bitince gap kadar sonra başlar; sıradaki söz başlarken ok koşulu tutmazsa düşer (adım değişti, evre geçti). Tepki sözü
## (bark; K61 C havuzu) sıraya girmez: konuşulurken düşer; aynı rol aynı olayda en az cooldown (45 sn) arayla konuşur, olayın son çeşidi
## tekrarlanmaz. Saat sahnenin saatidir (sn): sahne her kare tick(saat) çağırır; Engine.time_scale'de sahneyle aynı akar (sınamada ses gerçek
## zamanda çalar, sıra sahnenin saatiyle yürür).
##   var voice := SceneVoice.new()
##   voice.prefix = "act0.child."
##   voice.show = _show_line                   # func(anahtar, altyazının süresi): altyazı, said
##   voice.text_seconds = func(k): return 2.0  # sesi olmayan satırın süresi
##   voice.audio = get_node_or_null(^"/root/AudioManager")
##   var seconds := voice.say("wake")          # sözün bitişine kalan süre (sıradaysa bekleme de içinde)
##   voice.bark("miss", [{"by": "yanchi_child", "line": "bark.miss.yanchi_child.1"}])
##   voice.tick(clock)                         # her kare

## Sıradaki sözün öncekinin bitişinden sonraki boşluğu (sn) ve tepki sözünün aynı rol, aynı olaydaki en kısa arası (sn; K61).
const GAP := 0.45
const COOLDOWN := 45.0
## Sesli satırın altyazısı sesin bitişinden bu kadar sonra söner (sn; SubtitleBar.TAIL) ve en az bu kadar durur (sn).
const TAIL := 0.4
const MIN_SUB := 1.2
## Ana söz (A, B dilimi) sesin önünde kısmanın payını bekler (sn; AudioManager, DuckTable.PREROLL); sistem sözü (C) beklemez.
const MAIN_LEAD := DuckTable.PREROLL

## vo_lines.json'daki kimliğin öneki.
var prefix := ""
## Söz başlarken: func(anahtar: String, altyazının süresi: float) -> void.
var show: Callable
## Sesi olmayan satırın süresi: func(anahtar: String) -> float (yoksa MIN_SUB).
var text_seconds: Callable
## Konuşanın sağ-sol yeri (−1..1): func(anahtar: String) -> float (yoksa 0).
var pan_of: Callable
## AudioManager (yoksa sessiz: altyazı ve sıra yine işler).
var audio: Node
var gap := GAP
var cooldown := COOLDOWN
## Sahnenin saati (tick yazar).
var clock := 0.0

var _busy_until := -INF
var _queue: Array[Dictionary] = []
var _bark_at := {}
var _bark_last := {}
var _current := ""
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	# Tepki sözünün seçimi her koşuda aynı sırayla (sınama ve kayıt tekrarlanır).
	_rng.seed = 74


## Satırın vo_lines.json kimliği.
func id_of(key: String) -> String:
	return prefix + key


## Satırın sesi var mı (dosyası içe aktarılmış, bugünkü metnin kaydı)?
func has_audio(key: String) -> bool:
	return VoLines.has_audio(id_of(key))


## Söz başlayınca sesinin bitişine dek geçen süre (sn): sesliyse ana sözün payı ve dosyanın süresi, değilse text_seconds.
func length(key: String) -> float:
	var id := id_of(key)
	if VoLines.has_audio(id):
		return (MAIN_LEAD if VoLines.tier(id) != "C" else 0.0) + VoLines.seconds(id)
	return _text_seconds(key)


## Söyler: boşsa hemen, konuşuluyorsa sıraya. ok (Callable) söz başlarken sorulur, false dönerse söz düşer. optional: söz sırası (drop_optional)
## bırakılabilir. Döner: sözün bitişine kalan süre (sn; bekleme de içinde) ya da 0 (söz düştü).
func say(key: String, ok: Callable = Callable(), optional := false) -> float:
	if key.is_empty():
		return 0.0
	if _queue.is_empty() and clock >= _busy_until:
		if ok.is_valid() and not bool(ok.call()):
			return 0.0
		return _start(key)
	_queue.append({"key": key, "ok": ok, "optional": optional})
	var wait := maxf(_busy_until - clock, 0.0)
	for i in _queue.size() - 1:
		wait += gap + length(str(_queue[i]["key"]))
	return wait + gap + length(key)


## Tepki sözü (K61 C): entries ([{by, line}], koşulu tutanlar) arasından, rolün bu olaydaki son sözünden cooldown geçmiş ve olayın son çeşidi
## olmayan biri. Konuşulurken düşer. Döner: söylenen anahtar ya da "".
func bark(event: String, entries: Array) -> String:
	if not is_free():
		return ""
	var pool: Array[Dictionary] = []
	for e: Variant in entries:
		if not e is Dictionary:
			continue
		var role := str((e as Dictionary).get("by", ""))
		var key := str((e as Dictionary).get("line", ""))
		if key.is_empty() or clock - float(_bark_at.get("%s|%s" % [event, role], -INF)) < cooldown:
			continue
		if key == str(_bark_last.get(event, "")):
			continue
		pool.append(e)
	if pool.is_empty():
		return ""
	var pick: Dictionary = pool[_rng.randi() % pool.size()]
	var chosen := str(pick.get("line", ""))
	_bark_at["%s|%s" % [event, str(pick.get("by", ""))]] = clock
	_bark_last[event] = chosen
	_start(chosen)
	return chosen


## Rol bu olayda konuşabilir mi (son sözünden cooldown geçti mi)?
func bark_ready(event: String, role: String) -> bool:
	return clock - float(_bark_at.get("%s|%s" % [event, role], -INF)) >= cooldown


## Her kare: saat ilerler, sıradaki söz vakti gelince başlar (koşulu tutmayan düşer).
func tick(now: float) -> void:
	clock = now
	while not _queue.is_empty() and clock >= _busy_until + gap:
		var item: Dictionary = _queue.pop_front()
		var ok: Callable = item.get("ok", Callable())
		if ok.is_valid() and not bool(ok.call()):
			continue
		_start(str(item["key"]))
		break


## Söz yok ve sıra boş mu?
func is_free() -> bool:
	return _queue.is_empty() and clock >= _busy_until


## Çalan sözün ve sıranın bitişine kalan süre (sn).
func remaining() -> float:
	var wait := maxf(_busy_until - clock, 0.0)
	for item: Dictionary in _queue:
		wait += gap + length(str(item["key"]))
	return wait


## Sıradaki isteğe bağlı sözler düşer (söz sırası başlarken bekleme sözleri gibi).
func drop_optional() -> void:
	_queue = _queue.filter(func(item: Dictionary) -> bool: return not bool(item.get("optional", false)))


## Çalan söz (yoksa "").
func current() -> String:
	return _current if clock < _busy_until else ""


## Sıra boşalır, çalan söz bu sahnenin sözüyse kısa bir sönüşle susar.
func stop() -> void:
	_queue.clear()
	if is_instance_valid(audio) and audio.has_method(&"current_line") and audio.has_method(&"stop_line"):
		var line := str(audio.call(&"current_line"))
		if not prefix.is_empty() and line.begins_with(prefix):
			audio.call(&"stop_line", 0.15)
	_busy_until = -INF
	_current = ""


## Sesli satırın altyazısı (saf): sesin bitişinden TAIL sonra söner, en az MIN_SUB.
static func subtitle_seconds(voice_seconds: float) -> float:
	return maxf(voice_seconds + TAIL, MIN_SUB)


func _start(key: String) -> float:
	var id := id_of(key)
	var seconds := _text_seconds(key)
	var sub := seconds
	if is_instance_valid(audio) and audio.has_method(&"play_line") and VoLines.has_audio(id):
		var opts := {"volume_db": VoLines.gain_db(id)}
		if pan_of.is_valid():
			opts["pan"] = clampf(float(pan_of.call(key)), -1.0, 1.0)
		var played := float(audio.call(&"play_line", id, opts))
		seconds = (MAIN_LEAD if VoLines.tier(id) != "C" else 0.0) + played
		sub = SceneVoice.subtitle_seconds(seconds)
	elif VoLines.has_audio(id):
		# AudioManager yok (sınamanın başsız düğümü): süre yine sesin süresidir, sıra aynı akar.
		seconds = length(key)
		sub = SceneVoice.subtitle_seconds(seconds)
	_busy_until = clock + seconds
	_current = key
	if show.is_valid():
		show.call(key, sub)
	return seconds


func _text_seconds(key: String) -> float:
	return float(text_seconds.call(key)) if text_seconds.is_valid() else MIN_SUB
