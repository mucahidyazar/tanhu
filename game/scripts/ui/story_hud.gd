class_name StoryHud
extends Control
## Oynanan sahnenin küçük ve sade yazıları (K98, K99; Çocukluk «Koyun Sırtında», sonra Yola Çıkış ve I. Perde): sol üstte sahnenin adı,
## amaç satırı ve ipucu (oyun içi HUD açıkken bunları onun görev kartı gösterir: show_box kapalı); Destan Kitabı'nın yazı ailesi (Alegreya SC başlık, Alegreya amaç, Alegreya italik ipucu). Altta sözün altyazısı
## (SubtitleBar): söz konuşanın adıyla yazılır; sesi SceneVoice çalar, altyazı sesin süresi kadar durur (E20/7). Sinema yazısının ölçeğindedir (UIKit.film_k: yazı resmin
## parçasıdır, Retina'da menüler gibi yarıya küçülmez; sinemanın altyazısıyla aynı boyda); amaç bloğu sol üst köşesinin çevresinde
## ölçeklenir. Fareyi engellemez. main.gd perdenin (UI/Fade) altına koyar: kara perde yazıları da örter; altyazının katmanı (SubtitleBar, 6)
## perdenin üstündedir, son söz kararan ekranda okunur.
##   hud.set_title("Koyun Sırtında")
##   hud.set_objective("Ağıla git"); hud.set_hint("Ağıl doğuda.")
##   hud.say("Lan Hatun", "Kalk, bugün sayım var.", 4.2, clock)    # clock: sahnenin saati (sn)
##   hud.tick(clock)                                              # her kare

## Sol üst köşeden pay (1080 satırda piksel).
const MARGIN := Vector2(46.0, 38.0)
const TITLE_SIZE := 17
const OBJECTIVE_SIZE := 24
const HINT_SIZE := 18
## Altyazı kutusunun alt kenara uzaklığı: ipucunun (PlayerPrompt, alt ortada 104 px) üstünde.
const SUBTITLE_MARGIN := 188.0
## Yazı değişince belirme süresi (sn).
const FADE := 0.35
## Sözün ekranda kaldığı süre (sn; saf): okuma hızı ≈18 harf/sn, en az MIN_LINE.
const MIN_LINE := 2.0
const LINE_BASE := 0.9
const LINE_PER_CHAR := 0.055

var subtitles: SubtitleBar
## Sol üstteki sade amaç bloğu görünsün mü? Oyun içi HUD'un görev kartı (GameplayHud, HudQuestCard) onun yerine geçince kapalıdır:
## yazılar yine tutulur (objective_text, sınama), yalnız çizilmez.
var show_box := true:
	set(value):
		show_box = value
		if _box:
			_box.visible = value

var _box: VBoxContainer
var _title: Label
var _objective: Label
var _hint: Label
var _tweens: Dictionary = {}


func _ready() -> void:
	name = "StoryHud" if name.is_empty() else name
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(self)
	_box = VBoxContainer.new()
	_box.name = "Box"
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_theme_constant_override("separation", 4)
	_box.position = MARGIN
	_box.visible = show_box
	add_child(_box)
	_title = UIKit.label("", TITLE_SIZE, "AlegreyaSC-Regular", 400, Color(UIKit.GOLD, 0.85), 2)
	_title.name = "Title"
	_objective = UIKit.label("", OBJECTIVE_SIZE, "Alegreya", 500, UIKit.PARCHMENT)
	_objective.name = "Objective"
	_hint = UIKit.label("", HINT_SIZE, "Alegreya-Italic", 400, UIKit.TEXT_DIM)
	_hint.name = "Hint"
	for l: Label in [_title, _objective, _hint]:
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		l.visible = false
		_box.add_child(l)
	subtitles = SubtitleBar.new()
	subtitles.name = "Subtitles"
	add_child(subtitles)
	subtitles.film_frame = true
	subtitles.base_margin = SUBTITLE_MARGIN
	UIKit.on_ui_scale_changed(self, _apply_ui_scale)
	_apply_ui_scale()


## Sahnenin adı (küçük harf başlık; boş gizler).
func set_title(text: String) -> void:
	_put(_title, text.to_upper())


func set_objective(text: String) -> void:
	_put(_objective, text)


func set_hint(text: String) -> void:
	_put(_hint, text)


func objective_text() -> String:
	return _objective.text if _objective and _objective.visible else ""


func hint_text() -> String:
	return _hint.text if _hint and _hint.visible else ""


func title_text() -> String:
	return _title.text if _title and _title.visible else ""


## Sözü now..now+seconds arasında altyazıda gösterir: «Konuşan: söz» (konuşan boşsa yalnız söz).
func say(speaker: String, text: String, seconds: float, now: float) -> void:
	if subtitles == null:
		return
	var shown := text if speaker.is_empty() else "%s: %s" % [speaker, text]
	subtitles.set_windows([{"id": "say", "t0": now, "t1": now + maxf(seconds, 0.1), "text": shown}])
	subtitles.show_at(now)


## Her kare sahnenin saatiyle: altyazı penceresi biter, kutu söner.
func tick(now: float) -> void:
	if subtitles:
		subtitles.show_at(now)


## Bütün yazılar ve altyazı silinir.
func clear() -> void:
	for l: Label in [_title, _objective, _hint]:
		if l:
			l.text = ""
			l.visible = false
	if subtitles:
		subtitles.clear()


## Sözün ekranda kalacağı süre (saf; sn).
static func line_seconds(text: String) -> float:
	return maxf(MIN_LINE, LINE_BASE + text.length() * LINE_PER_CHAR)


func _put(label: Label, text: String) -> void:
	var shown := not text.is_empty()
	if label == null or (label.text == text and label.visible == shown):
		return
	label.text = text
	label.visible = shown
	if text.is_empty() or not is_inside_tree():
		return
	var old: Tween = _tweens.get(label.name)
	if old and old.is_valid():
		old.kill()
	label.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(label, ^"modulate:a", 1.0, FADE).set_trans(Tween.TRANS_SINE)
	_tweens[label.name] = t


func _apply_ui_scale() -> void:
	if _box:
		var k := UIKit.film_k()
		_box.scale = Vector2(k, k)
		_box.position = MARGIN * k
