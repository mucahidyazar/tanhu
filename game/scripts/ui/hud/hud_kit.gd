class_name HudKit
extends RefCounted
## Oyun içi HUD'un takımı (docs/media/review/hud_referans.webp, kullanıcının görseli): dokular, renkler, yazılar ve yerleşim.
##
## Dokular assets/ui/hud/'dadır: gpt-image-2 sayfaları (tools/imagegen/gen.sh; istekleri, kaynak sayfalar ve kesici
## assets/ui/hud/_src/'de, .gdignore'la içe aktarılmaz) macenta zeminden kesildi: gümüş-mavi bulut kıvrımlı halkalar, lacivert-altın
## yuvalar, ok uçlu çubuklar, simgeler. Ölçüler _src/metrics.json'dandır (halkanın merkezi ve iç yarıçapı, çubuğun kanalı).
## Her parça 1080 satırlık ekrana göre yerleşir (referansın pikselleri: 1448 × 1086 ≈ 1080 satır) ve UIKit.ui_k() × HUD_SCALE ile ölçeklenir
## (K104: Ayarlar'ın tek «Arayüz ölçeği» menüleri ve HUD'u birlikte büyütür; HUD menülerin 0,8 katıdır).
## Bir doku eksikse parça yerine sade bir şekil çizilir (tex() null döner): HUD yine çalışır.
## Yazı ailesi oyununki: başlık Cinzel (altın), gövde Alegreya; sayılar düz (lining) rakamla.

const DIR := "res://assets/ui/hud/"

# --- Renkler (referanstan) -------------------------------------------------------------------------------
const GOLD := Color("#e7c372")
const GOLD_DEEP := Color("#b8873a")
const CREAM := Color("#f6eedb")
const TEXT_DIM := Color("#e5d9bf")
const NAVY := Color("#14284a")
const NAVY_DEEP := Color("#0b1628")
const INK := Color(0.02, 0.03, 0.07, 0.78)
const PLUS := Color("#9cc3e4")
const SHADOW := Color(0.0, 0.0, 0.0, 0.62)
const SILVER := Color("#e9e6dc")

# --- Yerleşim (1080 satır; referansın pikselleri) -----------------------------------------------------------
## Portre paneli (sol üst köşeye çapalı): halkanın merkezi, halka dokusunun ölçeği, portrenin yarıçapı; rozet; çubuklar; durum yuvaları.
const PORTRAIT_CENTER := Vector2(111.6, 89.6)
const PORTRAIT_RING_SCALE := 0.418
const PORTRAIT_RING_PIVOT := Vector2(207.0, 176.0)
const PORTRAIT_RADIUS := 64.5
const BADGE_CENTER := Vector2(115.0, 170.0)
const BADGE_SIZE := 50.0
const HP_RECT := Rect2(163.0, 58.0, 268.0, 32.0)
const STAMINA_RECT := Rect2(163.0, 103.0, 254.0, 32.0)
const STATUS_CENTERS: Array[Vector2] = [Vector2(208.0, 170.0), Vector2(261.0, 170.0)]
const STATUS_SIZE := 42.0
const PORTRAIT_SIZE := Vector2(440.0, 205.0)
## Mini harita (sağ üst köşeye çapalı; köşeye göre): halkanın merkezi, halka dokusunun ölçeği, haritanın yarıçapı.
const MAP_CENTER := Vector2(-162.0, 142.5)
const MAP_RING_SCALE := 0.39
const MAP_RING_PIVOT := Vector2(358.2, 348.0)
const MAP_RADIUS := 111.0
## Görev kartı (sağ üst köşeye çapalı): süs çubuğunun sol kenarı, çubuğun ekseni (y) ve genişliği.
const QUEST_LEFT := -340.0
const QUEST_ROD_Y := 319.0
const QUEST_WIDTH := 312.0
## Yuva şeridi (alt ortaya çapalı): altıgenin boyu, aralığı, merkezinin alttan yüksekliği; XP çubuğu.
const SLOT_SIZE := Vector2(76.0, 72.0)
const SLOT_PITCH := 73.0
const SLOT_CENTER_Y := -116.0
const XP_RECT := Rect2(-278.0, -70.0, 554.0, 20.0)
## XP çubuğunun alt kenarının ekranın altına uzaklığı (ekranda × ui_k): parçalar HUD_SCALE'de çizildiği için alt ortadakiler bu çizgiye göre
## kaydırılır ve ondan yukarı büyür (lift_for).
const HUD_FLOOR := 50.0
## Tuş ipuçları şeridinin üst kenarıyla XP çubuğunun alt kenarı arasındaki en az boşluk (1080 satır; şerit HUD'un ölçeğinde çizilir).
const HINTS_GAP := 4.0
## HUD'un arayüz ölçeğine göre büyüklüğü (K104): Ayarlar › Görüntü › «Arayüz ölçeği» tek ayardır, menüler ui_k() ile, HUD ui_k() × HUD_SCALE
## ile çizilir. Ayar %100'de HUD, eski ayrı «HUD ölçeği»nin %80'indeki boyundadır (kullanıcının E20'deki eşlemesi).
const HUD_SCALE := 0.8
## Düğmeler (sağ alt köşeye çapalı): merkezler ve çap.
const BUTTON_CENTERS: Array[Vector2] = [Vector2(-227.0, -97.0), Vector2(-158.0, -97.0), Vector2(-88.0, -97.0)]
const BUTTON_SIZE := 62.0

# --- Dokuların iç ölçüleri (_src/metrics.json) ---------------------------------------------------------------
## Çubuk çerçevesi (900 × 91): koyu kanal x 24..835, y 16..74; 9 dilim payları (sol yuvarlak uç, sağda ok ucu ve altın köşeli).
const BAR_SIZE := Vector2(900.0, 91.0)
const BAR_CHANNEL := Rect2(24.0, 16.0, 811.0, 58.0)
const BAR_PATCH := Vector4(40.0, 0.0, 100.0, 0.0)
## Dolgu şeritleri (640 × 96): yuvarlak uçların payı.
const FILL_PATCH := 48.0
## XP çerçevesi (1400 × 57; opak y 3..54): kanal x 12..1387, y 11..44.
const XP_SIZE := Vector2(1400.0, 57.0)
const XP_OPAQUE_Y := Vector2(3.0, 54.0)
const XP_CHANNEL := Rect2(12.0, 11.0, 1375.0, 33.0)
const XP_PATCH := 30.0
const XP_FILL_PATCH := 32.0
## Görev süs çubuğu (900 × 127): çubuğun ekseni y 91,5; 9 dilim payları (solda bulut, sağda yapraklar).
const RULE_SIZE := Vector2(900.0, 127.0)
const RULE_ROD_Y := 91.5
const RULE_PATCH := Vector2(200.0, 160.0)
const RULE_SCALE := 0.39
## Sancak (130 × 160): kumaşın ortası (x 65,5) ve ölçeği (kumaş 34 px).
const BANNER_SCALE := 0.378
## Büyük harita halkası (1200 × 1129): merkez ve iç yarıçap.
const BIG_RING_PIVOT := Vector2(596.9, 579.4)
const BIG_RING_INNER := 475.2

static var _tex: Dictionary = {}
static var _fonts: Dictionary = {}


## Takımın dokusu (ör. "slot_hex"); dosya yoksa null (önbellekli).
static func tex(id: String) -> Texture2D:
	if _tex.has(id):
		return _tex[id]
	var path := DIR + id + ".png"
	var t: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_tex[id] = t
	return t


## Başlık yazısı (Cinzel, kalın).
static func title_font() -> Font:
	return UIKit.font("Cinzel", 700)


## Gövde yazısı (Alegreya); weight 400 düz, 600 yarı kalın.
static func body_font(weight := 400) -> Font:
	return UIKit.font("Alegreya", weight)


## Sayılar: Alegreya'nın düz (lining) rakamları ("86 / 100"; varsayılanı eski üslup rakamdır).
static func number_font(weight := 600) -> Font:
	var key := "num_%d" % weight
	if _fonts.has(key):
		return _fonts[key]
	var fv := FontVariation.new()
	fv.base_font = UIKit.font("Alegreya")
	var ts := TextServerManager.get_primary_interface()
	var features := {}
	if ts:
		features[ts.name_to_tag("lnum")] = 1
		features[ts.name_to_tag("pnum")] = 1
	fv.opentype_features = features
	if weight != 400:
		fv.variation_opentype = {"wght": weight}
	_fonts[key] = fv
	return fv


## Gölgeli yazı (referanstaki gibi yumuşak koyu gölge ve ince kontur). align: 0 sol, 1 orta, 2 sağ; pos taban çizgisinin başı
## (orta hizada merkez x).
static func draw_text(ci: CanvasItem, font: Font, pos: Vector2, text: String, size: int, color: Color, align := 0,
		shadow := SHADOW, outline := 4) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var at := pos
	if align == 1:
		at.x -= w * 0.5
	elif align == 2:
		at.x -= w
	if shadow.a > 0.0:
		ci.draw_string_outline(font, at + Vector2(0.0, 2.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline + 2, Color(shadow, shadow.a * 0.55))
		ci.draw_string(font, at + Vector2(0.0, 2.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, shadow)
		if outline > 0:
			ci.draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, outline, Color(0.02, 0.03, 0.06, 0.55))
	ci.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


## Yazının genişliği.
static func text_width(font: Font, text: String, size: int) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## Dokuyu merkezi ve boyuyla çizer (doku yoksa fallback rengiyle yuvarlak bir taş). flip_h: yatay ayna.
static func draw_centered(ci: CanvasItem, id: String, center: Vector2, size: Vector2, modulate := Color.WHITE, flip_h := false) -> void:
	var t := tex(id)
	var r := Rect2(center - size * 0.5, size)
	if t == null:
		ci.draw_circle(center, minf(size.x, size.y) * 0.5, Color(NAVY, 0.9 * modulate.a))
		return
	if flip_h:
		ci.draw_set_transform(Vector2(center.x * 2.0, 0.0), 0.0, Vector2(-1.0, 1.0))
		ci.draw_texture_rect(t, r, false, modulate)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		ci.draw_texture_rect(t, r, false, modulate)


## Simgeyi kutuya en boy oranını koruyarak sığdırır.
static func draw_icon(ci: CanvasItem, id: String, center: Vector2, box: float, modulate := Color.WHITE) -> void:
	var t := tex(id)
	if t == null:
		return
	var s := t.get_size()
	var k := box / maxf(s.x, s.y)
	ci.draw_texture_rect(t, Rect2(center - s * k * 0.5, s * k), false, modulate)


## Yatay 9 dilim: dokunun sol ve sağ payı korunur, ortası uzar; dikeyde bütün doku hedefin boyuna ölçeklenir.
## src_y: dokunun dikeyde kullanılan aralığı (piksel; boşsa hepsi).
static func draw_hslice(ci: CanvasItem, id: String, dest: Rect2, left: float, right: float, src_y := Vector2(-1.0, -1.0), modulate := Color.WHITE) -> void:
	var t := tex(id)
	if t == null:
		ci.draw_rect(dest, Color(NAVY, 0.9 * modulate.a))
		return
	var size := t.get_size()
	var y0 := src_y.x if src_y.x >= 0.0 else 0.0
	var y1 := src_y.y if src_y.y >= 0.0 else size.y
	var k := dest.size.y / maxf(y1 - y0, 1.0)
	var l := minf(left * k, dest.size.x * 0.5)
	var r := minf(right * k, dest.size.x * 0.5)
	var mid := maxf(dest.size.x - l - r, 0.0)
	var h := dest.size.y
	ci.draw_texture_rect_region(t, Rect2(dest.position, Vector2(l, h)), Rect2(0.0, y0, l / k, y1 - y0), modulate)
	if mid > 0.0:
		ci.draw_texture_rect_region(t, Rect2(dest.position + Vector2(l, 0.0), Vector2(mid, h)), Rect2(left, y0, size.x - left - right, y1 - y0), modulate)
	ci.draw_texture_rect_region(t, Rect2(dest.position + Vector2(l + mid, 0.0), Vector2(r, h)), Rect2(size.x - r / k, y0, r / k, y1 - y0), modulate)


## Bir kutunun kenarına doğru kısaltılmış yazı (sığmazsa sonu «…»).
static func fit_text(font: Font, text: String, size: int, width: float) -> String:
	if text_width(font, text, size) <= width:
		return text
	var t := text
	while t.length() > 1 and text_width(font, t + "…", size) > width:
		t = t.substr(0, t.length() - 1)
	return t.strip_edges() + "…"


## Sözcük sözcük satırlara böler (en çok max_lines; son satır sığmazsa «…» ile kısalır; saf).
static func wrap_lines(font: Font, text: String, size: int, width: float, max_lines := 2) -> PackedStringArray:
	var out := PackedStringArray()
	var line := ""
	for word in text.split(" ", false):
		var next := word if line.is_empty() else line + " " + word
		if text_width(font, next, size) <= width or line.is_empty():
			line = next
			continue
		out.append(line)
		line = word
		if out.size() == max_lines:
			break
	if out.size() < max_lines and not line.is_empty():
		out.append(line)
	elif out.size() == max_lines and not line.is_empty():
		out[max_lines - 1] = fit_text(font, out[max_lines - 1] + " " + line, size, width)
	for i in out.size():
		out[i] = fit_text(font, out[i], size, width)
	return out


## Tuş ipuçlarının HUD dilindeki biçimi (GameHud.hud_style, HudActionPrompt): tuş lacivert-altın kapakta krem Cinzel, eylem krem
## Alegreya, ayraç soluk altın.
static func style_key_label(label: Label, variation: StringName) -> void:
	label.add_theme_color_override(&"font_shadow_color", Color(0, 0, 0, 0.6))
	label.add_theme_constant_override(&"shadow_offset_y", 1)
	match variation:
		&"HudKey":
			label.add_theme_font_override(&"font", UIKit.font("Cinzel", 700))
			label.add_theme_font_size_override(&"font_size", 13)
			label.add_theme_color_override(&"font_color", CREAM)
			label.add_theme_stylebox_override(&"normal", keycap_box())
		&"HudAction":
			label.add_theme_font_override(&"font", body_font(500))
			label.add_theme_font_size_override(&"font_size", 16)
			label.add_theme_color_override(&"font_color", CREAM)
		_:
			label.add_theme_font_size_override(&"font_size", 16)
			label.add_theme_color_override(&"font_color", Color(GOLD, 0.75))


## HUD'un tuş kapağı: lacivert mine, ince altın kenar.
static func keycap_box() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.15, 0.29, 0.95)
	sb.border_color = Color(GOLD, 0.9)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 7.0
	sb.content_margin_right = 7.0
	sb.content_margin_top = 1.0
	sb.content_margin_bottom = 2.0
	sb.anti_aliasing = true
	return sb


## Tuş ipuçları şeridinin iç payları (şeridi GameHud.Ribbon çizer).
static func key_strip_box() -> StyleBoxEmpty:
	var sb := StyleBoxEmpty.new()
	sb.content_margin_left = 40.0
	sb.content_margin_right = 40.0
	sb.content_margin_top = 4.0
	sb.content_margin_bottom = 5.0
	return sb


## Ekranın ölçeği (UIKit.ui_k; ayar autoload'u yoksa 1).
static func k() -> float:
	return UIKit.ui_k()


## HUD'un arayüz ölçeğine göre çarpanı (HUD_SCALE, 0,8; K104): her parça kendi çapasında ui_k() × hud_scale() ile çizilir. Ayrı bir ayar
## değildir: oyuncunun ölçeği ui_k()'nın içindedir (GameSettings.ui_scale, %50–%150).
static func hud_scale() -> float:
	return HUD_SCALE


## Alt ortadaki parçaların (yuva şeridi, eylem şeridi) HUD'un arayüze göre ölçeği s'teki (hud_scale) iç kayması (saf; 1080 satır, aşağı +):
## çapanın çevresinde ui_k × s ile ölçeklenen parça bu kadar kayınca XP çubuğunun alt kenarı ekranın altından hep floor_px × ui_k uzakta
## kalır (çubuğun altındaki tuş ipuçları şeridine hiçbir ölçekte değmez; şerit ve eylem şeridi yukarı doğru büyür).
## floor_px: XP çubuğunun alt kenarının ekranın altına istenen uzaklığı (1080 satır; varsayılan HUD_FLOOR, GameplayHud.xp_floor verir).
static func lift_for(s: float, floor_px: float = HUD_FLOOR) -> float:
	return HUD_FLOOR - floor_px / maxf(s, 0.01)
