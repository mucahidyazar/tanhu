class_name PrologueBridge
extends CineScene
## Anlatıcının iki köprüsü (Yol Haritası bridge-one, bridge-two; story.md §6, K36, K67, K93): scenes/cine/bridge.tscn'in kökü, segmentler
## data/cine/bridge_1.json ve bridge_2.json. CineHost sahneyi kendi SubViewport'unda (overlay) gösterir, ana 3B çizilmez, kamp bırakılır.
## Görüntü iki kiplidir:
##   - Video: motion-studio'da işlenen parşömen videosu (assets/cine/video/<segment kimliği>.ogv; süresi segment + 1,0 sn), sinema saatini
##     izler (CineVideo). --cine-at ve hız ona da işler.
##   - Dosya yoksa (ya da CineVideo.enabled kapalıysa): kara ekran. Satırlar, altyazı ve olaylar aynen akar, konsola hata yazılmaz.
## İki kipte de katman CineVideo.LAYER'dır (boyalı süzgecin üstü, perdenin ve altyazının altı), altyazı alttaki koyu banttadır.
## Çekimler (fox_hare, bow … / road, gate …) yalnız izlenir: kesmeler videoya işlenmiştir, zamanları aynı çizelgeden gelir.
## Sahnenin olayları: bed {bed, db, dur} ortam döngüsü, cue {sfx, db, pitch} efekt (PrologueMyth'in kuralı: ileri sarmada efekt çalmaz, ortam
## geçişsiz kurulur).
##
##   CineHost.play("res://data/cine/bridge_1.json")   # --cine=res://data/cine/bridge_1.json
##   # Bitişte perde karadır; finished(false), atlanırsa finished(true).

## Videoların klasörü; dosya adı segmentin kimliğidir.
const VIDEO_DIR := "res://assets/cine/video"
const VIDEO_EXT := ".ogv"
## Videonun segmentten uzunluğu (sn): perde kapanırken görüntü sürer.
const VIDEO_TAIL := 1.0
## Video yokken (ve video açılana dek) görünen renk.
const BLANK_COLOR := Color.BLACK

## Oynatılacak video (sınama fixture ya da olmayan yol verir); boşsa segmentin kendi dosyası.
static var video_override := ""

## Video kipinin oynatıcısı (kara ekranda null).
var video: CineVideo
## Son çekim.
var current_shot := ""
## Sahnenin kendi oynattığı sesler (ileri sarmada boş kalır; sınama okur).
var sounds: Array = []

var _blank: ColorRect
## Sahnenin açtığı ortam döngüleri: dizi bu segmentte biterse (atlama, durdurma, son segment) restore onları susturur.
var _touched_beds: Dictionary = {}


func _ready() -> void:
	set_process(false)


## Segment başlarken: kara zemin ve (varsa) video kurulur, katman ve altyazı yerine konur.
func setup(p_ctx: Dictionary) -> void:
	super.setup(p_ctx)
	_build_view()
	var h := host()
	if h:
		h.use_video_layer(_segment_id())
		_set_subtitle_band(true)
	set_process(video != null)


## Segmentin video yolu: ör. bridge_1 → res://assets/cine/video/bridge_1.ogv.
static func video_path_for(seg_id: String) -> String:
	return video_override if not video_override.is_empty() else VIDEO_DIR.path_join(seg_id + VIDEO_EXT)


## Video sinema saatini izler. Atlanırken saat sona sıçrar, perde inerken video sarılmaz.
func _process(_delta: float) -> void:
	var h := host()
	if h == null or h.is_skipping():
		return
	video.speed = h.speed
	video.follow(h.time() - _segment_start())


func on_shot(shot_name: String, _ev: Dictionary) -> void:
	current_shot = shot_name


func on_event(ev: Dictionary) -> void:
	match str(ev.get("type", "")):
		"bed":
			_touched_beds[str(ev.get("bed", ""))] = true
			_audio(&"set_ambience_layer", [str(ev.get("bed", "")), float(ev.get("db", -80.0)),
				0.0 if seeking else float(ev.get("dur", 0.0))])
		"cue":
			if not seeking:
				var opts := {"db": float(ev.get("db", 0.0)), "pitch": float(ev.get("pitch", 1.0))}
				sounds.append([str(ev.get("sfx", "")), opts])
				_audio(&"play_sfx", [str(ev.get("sfx", "")), opts])


func restore() -> void:
	# Süreç de durur: sahne bu karenin sonunda silinir, follow videoyu yeniden başlatıp sarmasın.
	set_process(false)
	if video:
		video.stop()
	_set_subtitle_band(false)
	sounds.clear()
	if _sequence_ends():
		for bed: String in _touched_beds:
			_audio(&"set_ambience_layer", [bed, -80.0, 0.5])
	_touched_beds.clear()


func is_ready() -> bool:
	return true


## Görünen kara zemin (video kipinde videonun altında kalır; sınama okur).
func blank() -> ColorRect:
	return _blank


# --- Kurulum -------------------------------------------------------------------------------------------

func _build_view() -> void:
	_blank = ColorRect.new()
	_blank.name = "Blank"
	_blank.color = BLANK_COLOR
	_blank.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(_blank)
	add_child(_blank)
	var path := video_path_for(_segment_id())
	if not CineVideo.usable(path):
		return
	var made := CineVideo.new()
	made.name = "Video"
	add_child(made)
	if made.open(path):
		video = made
	else:
		remove_child(made)
		made.free()


func _set_subtitle_band(on: bool) -> void:
	var h := host()
	if h and h.subtitles:
		h.subtitles.video_band = on


# --- Yardımcılar ---------------------------------------------------------------------------------------

func _segment_id() -> String:
	var seg: Variant = ctx.get("segment")
	return str((seg as Dictionary).get("id", "")) if seg is Dictionary else ""


## Segmentin dizideki başlangıcı (sn).
func _segment_start() -> float:
	var seg: Variant = ctx.get("segment")
	return float((seg as Dictionary).get("start", 0.0)) if seg is Dictionary else 0.0


func _audio(method: StringName, args: Array) -> void:
	var audio: Variant = ctx.get("audio")
	if audio is CineAudio:
		(audio as CineAudio).call_target(method, args)


## Dizi bu segmentle bitiyor mu (atlama, durdurma ya da son segment)? PrologueMyth'in kuralı.
func _sequence_ends() -> bool:
	var h := host()
	if h == null or h.is_skipping() or not h.is_playing() or h.runner == null or h.runner.done:
		return true
	var timeline := h.timeline()
	var seg: Dictionary = ctx.get("segment", {})
	if timeline == null or seg.is_empty():
		return true
	return int(seg.get("index", 0)) >= timeline.segments.size() - 1
