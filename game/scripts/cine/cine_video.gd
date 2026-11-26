class_name CineVideo
extends Control
## Sinemanın tam ekran video oynatıcısı (K93; story.md §3 satır 1–6 ve 8, godot.md §3.6): motion-studio'da işlenen sessiz Ogg
## Theora'yı (Godot 4.7.2'nin tek video biçimi; .ogv içe aktarılmaz, load doğrudan VideoStreamTheora verir) sinema saatine
## bağlı oynatır. 16:9'u korur, başka en-boyda artan yer siyaha yakın banttır (BAR_COLOR). Kökü Control'dür: çağıran onu LAYER
## katmanındaki kendi yerine koyar (mit: overlay'in SubViewport'u; doğumun son 10 sn'si: PanelLayer). Dosya yoksa ya da açılamazsa
## sessizce kapalı kalır, çağıran keçe yedeğine döner. MeshyProp.models_enabled gibi enabled statik anahtarı sınamalar içindir.
##
## Saat: follow(t) her kare çağrılır. |konum − t| MAX_DRIFT'i aşarsa sarılır, iki sarma arası en az SEEK_GAP'tir. Küçük sapmayı hız
## alır (TRIM_*): video birkaç yüz milisaniye biraz hızlı ya da yavaş akar, sarılmaz. Ölçüm (2026-11-07, 1080p, 128 karede bir anahtar
## kare): sarma eşzamanlıdır ve önceki anahtar kareden çözer, 22–350 ms kare takılır; ardından video bir sonraki karenin süresi
## kadar (≤0,15 sn) geride kalır. Bu pay kırpılmazsa sarma yeni sarmayı doğururdu. Takılma kendisi sapma yapmaz: motor süreç adımını
## ≈0,14 sn'ye kırpar (max_physics_steps_per_frame), sinema saati de video da aynı adımla akar. Hız speed'dir (CineHost.speed). Saat
## durursa (dünya bekleniyor) video duraklar. Saat videonun sonunu geçerse son karede kalır: motor bitince doku son karede durur.
##
##   var video := CineVideo.new()
##   add_child(video)
##   if video.open("res://assets/cine/video/myth.ogv"):
##       video.speed = host.speed
##       video.follow(host.time() - seg_start)    # her kare

## Video katmanı: boyalı süzgecin (PainterlyOverlay, 1) üstünde, perdenin (5) ve altyazının (6) altında. Süzgeç videonun ince
## mürekkep çizgilerini bozardı; altındaki 3B yine süzgeçlidir (çakışmada süzgeç aç-kapa yapılmaz).
const LAYER := 2
## Videonun en-boyu (1920 × 1080). Pencere buna bu paydan yakınsa bant yok: 1366 × 768'de 1 piksellik çizgi kalmasın.
const ASPECT := 16.0 / 9.0
const ASPECT_SNAP := 0.005
## Artan yerin rengi: siyaha çok yakın, videonun koyu bandının çözülmüş rengi (motion-studio #150803, Theora çözümünde #120500;
## pencerede ölçüldü). Saf siyah olsaydı 16:10 ekranda bantla arasında dikiş görünürdü.
const BAR_COLOR := Color("#120500")
## Düzeltilen en küçük sapma ve iki sarma arasındaki en kısa süre (sn).
const MAX_DRIFT := 0.12
const SEEK_GAP := 0.5
## Küçük sapmanın düzeltilmesi: sapma TRIM_START'ı aşınca video TRIM_FAST ya da TRIM_SLOW katı akar, TRIM_STOP'un altında normale
## döner. Sarmanın bıraktığı ≈0,15 sn SEEK_GAP içinde kapanır: sarma sarma doğurmaz.
const TRIM_START := 0.04
const TRIM_STOP := 0.015
const TRIM_FAST := 1.5
const TRIM_SLOW := 0.75
## Saat videonun sonunu geçince hedef: son karenin biraz önü (sarma son kareyi görsün, video kendiliğinden bitsin).
const END_PAD := 0.05
## Başlığın aranacağı ve bir videonun en az olması gereken bayt (Theora'nın üç başlığı bundan büyüktür).
const HEAD_BYTES := 4096
## Ogg sayfasının imzası, Theora'nın kimlik başlığı (0x80 "theora") ve kurulum başlığı (0x82 "theora").
const OGG_MAGIC := "4f676753"
const THEORA_INFO := "807468656f7261"
const THEORA_SETUP := "827468656f7261"

## Video kullanılsın mı? Kapalıyken usable false döner: sahneler keçe yedeğiyle kurulur (sınamalar).
static var enabled := true

## Oynatma hızı (CineHost.speed; sinema saatiyle aynı oran).
var speed := 1.0:
	set(value):
		speed = maxf(value, 0.001)
		_player.speed_scale = speed * _trim
## Sarma sayısı (ilk konumlanma dahil; sınama ve günlük okur).
var seek_count := 0

var _player: VideoStreamPlayer
var _bars: ColorRect
var _length := 0.0
var _trim := 1.0
var _started := false
var _last_t := -INF
var _last_seek := -INF


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(self)
	_bars = ColorRect.new()
	_bars.name = "Bars"
	_bars.color = BAR_COLOR
	_bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(_bars)
	add_child(_bars)
	_player = VideoStreamPlayer.new()
	_player.name = "Player"
	_player.expand = true
	_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_player)
	resized.connect(_fit)


# --- Saf ---------------------------------------------------------------------------------------------

## Dosya oynatılabilir mi (sessiz: motora açtırmadan, başlığına bakılır)? enabled kapalıyken false.
static func usable(path: String) -> bool:
	return enabled and is_theora(path)


## Dosya Ogg Theora mı? Yok, kısa ya da bozuk dosya motora verilmez: motor konsola hata yazardı.
static func is_theora(path: String) -> bool:
	if path.is_empty() or not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() < HEAD_BYTES:
		return false
	var head := file.get_buffer(HEAD_BYTES).hex_encode()
	return head.begins_with(OGG_MAGIC) and head.contains(THEORA_INFO) and head.contains(THEORA_SETUP)


## Videonun outer içindeki dikdörtgeni: en-boyu korunur, ortalanır, artan yer banttır.
static func fit_rect(outer: Vector2, aspect: float = ASPECT) -> Rect2:
	if outer.x <= 0.0 or outer.y <= 0.0 or aspect <= 0.0:
		return Rect2()
	if absf(outer.x / outer.y / aspect - 1.0) <= ASPECT_SNAP:
		return Rect2(Vector2.ZERO, outer)
	var w := minf(outer.x, outer.y * aspect)
	var fitted := Vector2(w, w / aspect)
	return Rect2((outer - fitted) * 0.5, fitted)


## Videodaki noktanın (0..1) ekrandaki yeri (0..1), bantlar hesaba katılarak.
static func screen_point(uv: Vector2, outer: Vector2, aspect: float = ASPECT) -> Vector2:
	var rect := fit_rect(outer, aspect)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return uv
	return (rect.position + uv * rect.size) / outer


## Sarılmalı mı? Sapma sınırı hızla büyür: hızlı oynatmada bir karelik adım tek başına sınırı aşar, sapma sayılmaz.
static func should_seek(playhead_at: float, target: float, since_seek: float, rate: float = 1.0) -> bool:
	return absf(playhead_at - target) > MAX_DRIFT * maxf(rate, 1.0) and since_seek >= SEEK_GAP


## Küçük sapma için hız çarpanı: drift saatin videodan ilerde olduğu süre (sn), current şimdiki çarpan; TRIM_START ile TRIM_STOP
## arasında çarpan değişmez (her karede gidip gelmesin). Sınırlar da hızla büyür.
static func trim_for(drift: float, current: float, rate: float = 1.0) -> float:
	var amount := absf(drift) / maxf(rate, 1.0)
	if amount > TRIM_START:
		return TRIM_FAST if drift > 0.0 else TRIM_SLOW
	return 1.0 if amount < TRIM_STOP else current


# --- Oynatma -----------------------------------------------------------------------------------------

## Dosyayı açar (oynatmaz: ilk follow başlatır). Açılamazsa false, oynatıcı kapalı kalır.
func open(path: String) -> bool:
	close()
	if not usable(path):
		return false
	var stream := load(path) as VideoStream
	if stream == null:
		return false
	_player.stream = stream
	_length = _player.get_stream_length()
	if _length <= 0.0:
		close()
		return false
	return true


## Oynatmayı durdurur, dosya açık kalır (sonraki follow baştan başlatır).
func stop() -> void:
	_player.stop()
	_player.paused = false
	_set_trim(1.0)
	_started = false
	_last_t = -INF
	_last_seek = -INF


## Dosyayı bırakır: oynatıcı kapalıdır.
func close() -> void:
	stop()
	_player.stream = null
	_length = 0.0


func is_open() -> bool:
	return _length > 0.0


## Video oynuyor mu (duraklamış da sayılır; bitince false)?
func is_playing() -> bool:
	return _player.is_playing()


func is_paused() -> bool:
	return _player.paused


## Videonun süresi (sn; kapalıyken 0).
func length() -> float:
	return _length


## Videonun konumu (sn; video bitince motor 0 döndürür).
func playhead() -> float:
	return _player.stream_position


## Oynatıcı düğümü (sınama: dikdörtgen).
func player() -> VideoStreamPlayer:
	return _player


## Sinema saatini izler (her kare; t videonun başından saniye). now sarma aralığının saatidir (sn; sınama verir, yoksa gerçek
## saat).
func follow(t: float, now: float = -1.0) -> void:
	if not is_open() or not is_inside_tree():
		return
	var clock := now if now >= 0.0 else Time.get_ticks_usec() / 1000000.0
	var target := clampf(t, 0.0, maxf(_length - END_PAD, 0.0))
	if not _started:
		_start(target, clock)
	elif _player.is_playing():
		var held := t == _last_t
		if _player.paused != held:
			_player.paused = held
		if not held:
			if should_seek(_ahead_playhead(), target, clock - _last_seek, speed):
				_seek(target, clock)
			_set_trim(trim_for(target - _ahead_playhead(), _trim, speed) if t < _length else 1.0)
	elif t < _length - MAX_DRIFT:
		# Video saatten önce bitmiş (geri sarma ya da uzun sapma): yeniden başlar. Sonuna gelmişse son karede kalır.
		_start(target, clock)
	_last_t = t


func _start(target: float, clock: float) -> void:
	_started = true
	_player.paused = false
	_player.play()
	# Başa yakın hedefte sarılmaz: sarma kareyi takar, küçük farkı hız alır.
	if target > MAX_DRIFT:
		_seek(target, clock)


## Bu karenin sonundaki konum. follow, saat bu karenin adımını almışken çağrılır; oynatıcı (çocuk düğüm) bu karenin adımını sonra
## alır: ham konumla uzun bir kare (≤0,15 sn adım) sapma sanılırdı.
func _ahead_playhead() -> float:
	return _player.stream_position + get_process_delta_time() * _player.speed_scale


func _set_trim(value: float) -> void:
	if value != _trim:
		_trim = value
		_player.speed_scale = speed * _trim


func _seek(target: float, clock: float) -> void:
	_player.stream_position = target
	_last_seek = clock
	seek_count += 1


func _fit() -> void:
	var rect := fit_rect(size)
	_player.position = rect.position
	_player.size = rect.size
