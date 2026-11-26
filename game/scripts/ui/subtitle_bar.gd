class_name SubtitleBar
extends CanvasLayer
## Sinemanın altyazısı (K61, godot.md §3.3): ekranın alt ortasında en çok iki satır, arayüz ölçeğinde,
## katman 6'da (perdenin ve boyalı süzgecin üstünde: kara ekranda da okunur). Türkçe arayüzde TR, İngilizce
## arayüzde EN metin (söylenen dil İngilizcedir, K5).
##
## Pencere: satırın sözcük zamanı (VoLines.words) varsa ilk sözcüğün başından son sözcüğün sonuna +0,4 sn;
## yoksa satırın başından süresi (seconds) boyunca. Şarkının iki dizesi kendi pencerelerindedir
## (VoLines.sub_lines). CineHost çizelge açılınca pencereleri kurar (set_windows), her kare sinema saatini
## verir (show_at): ileri sarmada da o anın altyazısı görünür. Pencereler çakışırsa son başlayan görünür.
##   var bar := SubtitleBar.new()
##   bar.set_windows(SubtitleBar.line_windows("act0.bard.song", 6.0, 26.85, "tr"))
##   bar.show_at(11.0)    # "Dolunay batarken sayıma bir eklendi,"
## Video oynarken (K93: mit ve Çocukluk'a geçiş) parşömen açık renklidir, altyazı da parşömen rengindedir: video_band açıkken
## kutu videonun alttaki koyu bandına iner; video bitince sahne kapatır, kutu eski yerine döner. Bant pencerenin değil videonun
## bandıdır: video 16:9'u korur (CineVideo.fit_rect), 16:10 ekranda altında pencerenin boş bandı kalır; kutu o bant kadar yukarı
## kalkar (video_band_lift), videonun koyu bandının içinde durur.
## Oynanan sahnede (StoryHud) kutu alttaki ipucunun (PlayerPrompt) üstünde durur: base_margin büyütülür.

signal changed(text: String)

const LAYER := 6
## Sözcük zamanlı pencerenin son sözcükten sonraki payı (saniye).
const TAIL := 0.4
const MAX_LINES := 2
const FONT_SIZE := 36
## Dengeli kesmede noktalamanın önceliği (kutu genişliğinin payı).
const BREAK_BONUS := 0.3
## 1080 satırda kutunun genişliği ve alt kenara uzaklığı (piksel; arayüz ölçeğiyle küçülür).
const WIDTH := 1180.0
const HEIGHT := 112.0
const BOTTOM_MARGIN := 78.0
## Videonun alttaki koyu bandı ve kutunun o banttayken alt kenara uzaklığı (1080 satırda piksel; iki satır bandın içinde kalır).
const VIDEO_BAND := 124.0
const VIDEO_MARGIN := 16.0

## Altyazının dili ("tr" ya da "en").
var lang := "tr"
## Sinemanın altyazısı mı? Öyleyse resmin parçasıdır, pencereyle birlikte büyür (GameSettings.film_k); değilse (Destan Kitabı) menü gibi
## arayüz ölçeğiyle çizilir.
var film_frame := false:
	set(value):
		film_frame = value
		_layout()
## Altyazı videonun koyu bandında mı?
var video_band := false:
	set(value):
		video_band = value
		_place_box()
## Video bandı yokken kutunun alt kenara uzaklığı (1080 satırda piksel; oynanan sahnede ipucunun üstüne kalkar).
var base_margin := BOTTOM_MARGIN:
	set(value):
		base_margin = value
		_place_box()

var _windows: Array[Dictionary] = []
var _text := ""
var _box: Control
var _label: Label


func _ready() -> void:
	layer = LAYER
	_box = Control.new()
	_box.name = "Box"
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.anchor_left = 0.5
	_box.anchor_right = 0.5
	_box.anchor_top = 1.0
	_box.anchor_bottom = 1.0
	_box.offset_left = -WIDTH * 0.5
	_box.offset_right = WIDTH * 0.5
	_place_box()
	add_child(_box)
	_label = UIKit.label("", FONT_SIZE, "Alegreya", 500, UIKit.PARCHMENT)
	_label.name = "Text"
	UIKit.full_rect(_label)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.max_lines_visible = MAX_LINES
	_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_label.add_theme_constant_override("outline_size", 8)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	_box.add_child(_label)
	_box.visible = false
	UIKit.on_ui_scale_changed(_box, _layout)
	_layout()


## Pencereleri kurar ([{t0, t1, text, id}], sinema saatiyle).
func set_windows(windows: Array) -> void:
	_windows.clear()
	for w: Variant in windows:
		if w is Dictionary:
			_windows.append(w)


func windows() -> Array[Dictionary]:
	return _windows


## Sinema saati t'de görünmesi gereken altyazıyı gösterir.
func show_at(t: float) -> void:
	_set_text(text_at(t))


## t anının altyazısı (yoksa ""): pencereleri çakışırsa son başlayan.
func text_at(t: float) -> String:
	var best: Dictionary = {}
	for w in _windows:
		if t >= float(w["t0"]) and t < float(w["t1"]) and (best.is_empty() or float(w["t0"]) >= float(best["t0"])):
			best = w
	return str(best.get("text", ""))


func current_text() -> String:
	return _text


func clear() -> void:
	_windows.clear()
	_set_text("")


## Satırın (line ya da song) altyazı pencereleri, çizelgenin mutlak saniyesiyle: [{id, t0, t1, text}].
## start satırın çalmaya başladığı an, duration süresi (sözcük zamanı yoksa pencere odur). words verilirse
## satırın sözcük zamanı yerine o okunur (sınama).
static func line_windows(line_id: String, start: float, duration: float, p_lang: String = "tr", words: Variant = null) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var subs := VoLines.sub_lines(line_id)
	if not subs.is_empty():
		for s in subs:
			var text := _pick(s, p_lang)
			if not text.is_empty():
				out.append({"id": str(s["id"]), "t0": start + float(s["t0"]), "t1": start + float(s["t1"]) + TAIL, "text": text})
		return out
	var text := VoLines.subtitle(line_id, p_lang)
	if text.is_empty():
		return out
	var span := words_window(words if words is Array else VoLines.words(line_id))
	if span.y > span.x:
		out.append({"id": line_id, "t0": start + span.x, "t1": start + span.y + TAIL, "text": text})
	else:
		out.append({"id": line_id, "t0": start, "t1": start + maxf(duration, 0.0), "text": text})
	return out


## Sözcük zamanlarının kapsadığı aralık (dosyanın başından): (ilk sözcüğün t0'ı, son sözcüğün t1'i);
## sözcük yoksa (0, 0).
static func words_window(words: Array) -> Vector2:
	var first := INF
	var last := -INF
	for w: Variant in words:
		if w is Dictionary and (w as Dictionary).has("t0") and (w as Dictionary).has("t1"):
			first = minf(first, float(w["t0"]))
			last = maxf(last, float(w["t1"]))
	return Vector2(first, last) if last > first else Vector2.ZERO


## Arayüzün dili: GameSettings.language ("en" ise EN, değilse TR).
static func ui_lang() -> String:
	var settings := UIKit.settings_node()
	if settings and &"language" in settings and str(settings.get(&"language")) == "en":
		return "en"
	return "tr"


## İki satıra düşen yazıyı dengeli böler (saf): kendiliğinden kaydırma ilk satırı doldurup ikinciye tek sözcük bırakabilir. Kesme iki
## satırın boyu en yakın olan boşluktadır; noktalamadan sonraki boşluk önceliklidir (BREAK_BONUS), çünkü altyazı önce anlamdan kesilir.
## Kutuya sığan yazıya ve elle kesilmiş satıra dokunmaz; iki satıra sığmıyorsa kaydırma kalır.
static func balanced(text: String, font: Font, font_size: int, width: float) -> String:
	if font == null or text.contains("\n") or _text_width(text, font, font_size) <= width:
		return text
	var best := -1
	var best_score := INF
	for i in text.length():
		if text[i] != " ":
			continue
		var left := _text_width(text.substr(0, i), font, font_size)
		var right := _text_width(text.substr(i + 1), font, font_size)
		if left > width or right > width:
			continue
		var score := absf(left - right) - (width * BREAK_BONUS if i > 0 and ",;:.!?—".contains(text[i - 1]) else 0.0)
		if score < best_score:
			best_score = score
			best = i
	return text if best < 0 else "%s\n%s" % [text.substr(0, best), text.substr(best + 1)]


static func _text_width(text: String, font: Font, font_size: int) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


static func _pick(sub: Dictionary, p_lang: String) -> String:
	for key in [p_lang, "tr", "en"]:
		var text := str(sub.get(key, ""))
		if not text.is_empty():
			return text
	return ""


func _set_text(text: String) -> void:
	if text == _text:
		return
	_text = text
	if _label:
		_label.text = balanced(text, _label.get_theme_font(&"font"), FONT_SIZE, WIDTH)
		_box.visible = not text.is_empty()
	changed.emit(text)


## Kutunun alt kenara uzaklığı şu an (1080 satırda piksel; arayüz ölçeğiyle küçülür). Video bandında videonun alt kenarına göredir.
func bottom_margin() -> float:
	return VIDEO_MARGIN if video_band else base_margin


## Videonun 16:9 dikdörtgeninin altında kalan pencere bandı (tuval pikseli, saf): 16:9'da 0; 1920 × 1200'de (16:10) 60.
static func video_band_lift(viewport_size: Vector2) -> float:
	var rect := CineVideo.fit_rect(viewport_size)
	if rect.size.y <= 0.0:
		return 0.0
	return maxf(viewport_size.y - rect.end.y, 0.0)


## Kutuyu alt kenara uzaklığına koyar (_layout).
func _place_box() -> void:
	_layout()


## Kutuyu ölçeğiyle alt kenarın ortasına çapalar. Video bandında pencerenin videonun altında kalan bandı kadar yukarı kalkar:
## pay ölçekle küçülmez (çapa ölçeklenmeden önceki yerdedir), bu yüzden ölçeğe bölünüp yazılır.
func _layout() -> void:
	if _box == null:
		return
	var k := UIKit.film_k() if film_frame else UIKit.ui_k()
	var lift := video_band_lift(_box.get_viewport_rect().size) / maxf(k, 0.001) if video_band and _box.is_inside_tree() else 0.0
	_box.offset_top = -(bottom_margin() + HEIGHT + lift)
	_box.offset_bottom = -(bottom_margin() + lift)
	UIKit.scale_at_anchor(_box, k)
