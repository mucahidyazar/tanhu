class_name CineRunner
extends RefCounted
## Sinema çalıştırıcısı (saf): CineTimeline'ın olaylarını sinema saatiyle sırayla yayar (godot.md §3.3, §3.6).
## Düğüm kurmaz, ses çalmaz: CineHost her kare step() çağırır ve yayılan olayları uygular; sınamalar
## kare beklemeden sürer.
##
##   var runner := CineRunner.new()
##   runner.load("res://data/cine/test_timeline.json")   # dizi ya da segment; Dictionary ya da CineTimeline de olur
##   runner.fired.connect(_on_cue)                        # (ev, seeking)
##   runner.step(delta)    # kare süresi en çok 0,25 sn sayılır: takılmada sinema sıçramaz (K20)
##   runner.seek(12.0)     # geçilen olaylar seeking = true ile yayılır: ses çalmadan durum kurulur
##   runner.skip()         # kalan olaylar yayılmaz; finished(true)
## Aynı andaki olaylar yazıldıkları sırayla yayılır. hold() saati yayılan son olayda tutar (ör. segmentin
## dünyası hazır değil); resume() bırakır. sync_to() saati dışarıdaki bir saate (şarkının çalış konumu) eşler.

signal fired(ev: Dictionary, seeking: bool)
signal finished(skipped: bool)

## Bir adımda sayılan en uzun süre (saniye).
const MAX_STEP := 0.25
const EPSILON := 0.000001

var timeline: CineTimeline
## Sinema saati (saniye, çizelgenin başından).
var time := 0.0
## Olay yayılırken ileri sarılıyor mu (seek)?
var seeking := false
## Bu adımın (ya da ileri sarmanın) vardığı saat: olay yayılırken saat olayın anındadır, olayın üstünden geçen
## süre target_time - ev.t'dir (ileri sarılan kararma, AnimationPlayer'ın sarılması).
var target_time := 0.0
var held := false
var done := false
var skipped := false

var _next := 0
var _last_fired := 0.0


## Diziyi ya da segmenti yükler ve saati başa alır. seq: dosya yolu, Dictionary ya da CineTimeline;
## seconds: satır kimliği → süre (boşsa VoLines.seconds). En az bir segment kurulduysa true.
func load(seq: Variant, seconds: Callable = Callable()) -> bool:
	if seq is CineTimeline:
		timeline = seq
	elif seq is Dictionary:
		timeline = CineTimeline.from_dict(seq, seconds)
	else:
		timeline = CineTimeline.from_path(str(seq), seconds)
	reset()
	return timeline.ok()


## Saati başa alır; olaylar yeniden yayılabilir.
func reset() -> void:
	time = 0.0
	target_time = 0.0
	_next = 0
	_last_fired = 0.0
	seeking = false
	held = false
	done = false
	skipped = false


func total() -> float:
	return timeline.total() if timeline else 0.0


func is_running() -> bool:
	return timeline != null and not done


## Saati dt kadar (en çok MAX_STEP) ilerletir; geçilen olaylar sırayla yayılır. Sona varınca finished(false).
func step(dt: float) -> void:
	if timeline == null or done or held:
		return
	_advance(time + clampf(dt, 0.0, MAX_STEP), false)


## Saati t'ye götürür: geçilen olaylar seeking = true ile yayılır (sesler çalmaz, durum kurulur). Geri
## sarmada saat başa alınır ve olaylar baştan sessizce yayılır.
func seek(t: float) -> void:
	if timeline == null:
		return
	if t < time - EPSILON:
		reset()
	if done:
		return
	held = false
	seeking = true
	_advance(clampf(t, 0.0, total()), true)
	seeking = false


## Sona atlar: kalan olaylar yayılmaz; finished(true).
func skip() -> void:
	if timeline == null or done:
		return
	skipped = true
	done = true
	held = false
	time = total()
	target_time = time
	finished.emit(true)


## Saati yayılan son olayda tutar (o anın sonraki olayları beklemeye kalır).
func hold() -> void:
	held = true


func resume() -> void:
	held = false


## Saati dışarıdaki saate eşler: ileri giderken olaylar sırayla (seeking olmadan) yayılır; geri giderken
## yayılan olay geri alınmaz, saat yayılan son olayın önüne düşmez.
func sync_to(t: float) -> void:
	if timeline == null or done or held:
		return
	if t > time:
		_advance(minf(t, total()), false)
	else:
		time = maxf(t, _last_fired)
		target_time = time


## Yayılmış ve hâlâ süren olaylar (type boşsa hepsi): başlangıcı geçti, bitişi gelmedi.
func active(type: String = "") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if timeline == null:
		return out
	for i in _next:
		var ev: Dictionary = timeline.events[i]
		if (type.is_empty() or ev["type"] == type) and float(ev["end"]) > time:
			out.append(ev)
	return out


## Yayılmamış ilk olayın sırası (sınama ve konak için).
func next_index() -> int:
	return _next


## Olayın başından bu adımın vardığı saate dek geçen süre (≥ 0).
func elapsed_since(ev: Dictionary) -> float:
	return maxf(maxf(target_time, time) - float(ev.get("t", 0.0)), 0.0)


func _advance(target: float, seek_mode: bool) -> void:
	target_time = target
	var list := timeline.events
	while _next < list.size() and float(list[_next]["t"]) <= target + EPSILON:
		var ev: Dictionary = list[_next]
		_next += 1
		time = maxf(time, float(ev["t"]))
		_last_fired = time
		fired.emit(ev, seek_mode)
		if held or done:
			return
	time = maxf(time, target)
	if _next >= list.size() and time >= total() - EPSILON:
		done = true
		time = total()
		finished.emit(false)
