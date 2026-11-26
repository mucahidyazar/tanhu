class_name UIKit
extends RefCounted
## Tanhu 1'in arayüz takımı: ortak palet, yazı tipleri ve küçük parça üreticileri. Bütün menü
## sayfaları (açılış ekranı, ayarlar, tuşlar, kayıtlar, Destan Kitabı, duraklatma) aynı dili konuşur:
## koyu keçe paneller, ince altın sırma kenarlar, gök mavisi küçük süsler.
##
## Yazı tipleri res://assets/fonts/ altındadır (Alegreya, Alegreya-Italic, AlegreyaSC, Cinzel,
## CinzelDecorative; SIL Open Font License). Bir yazı tipi dosyası eksikse Godot'nun yedek yazı tipi
## kullanılır; arayüz yine çalışır.

const FONT_DIR := "res://assets/fonts/"

const GOLD := Color("#d9b56c")
const GOLD_DIM := Color("#7d6236")
const INK := Color("#090c12")
const FELT := Color(0.035, 0.043, 0.06, 0.9)
const PARCHMENT := Color("#efe2c4")
const SKY := Color("#7fe3ff")
const SKY_DEEP := Color("#2f8fb8")
const CRIMSON := Color("#d0343f")
const EMBER := Color("#ff8a3d")
const TEXT := Color("#f1e8d4")
const TEXT_DIM := Color("#a79d88")

## Sığdırmanın kenar payı (center_panel, center_in_parent): çerçevenin taşan süsleri (OrnateFrame'in elmasları) ekranın ya da kitabın
## şeritlerinin üstüne binmesin. %100'de 1080 satırda en büyük sayfa (ansiklopedi, 27 px boşluk) ve Kayıtlar (51 px) payın içinde kalır.
const FIT_MARGIN := 16.0

static var _fonts: Dictionary = {}
static var _soft_tex: Texture2D


## Adı verilen yazı tipi (ör. "Cinzel"), istenen kalınlık (değişken yazı tiplerinde "wght" ekseni)
## ve harf aralığıyla. Aynı istek hep aynı nesneyi döndürür (önbellek).
static func font(font_name := "Alegreya", weight := 400, spacing := 0) -> Font:
	var key := "%s_%d_%d" % [font_name, weight, spacing]
	if _fonts.has(key):
		return _fonts[key]
	var path := FONT_DIR + font_name + ".ttf"
	var base: Font = load(path) if ResourceLoader.exists(path) else ThemeDB.fallback_font
	var f: Font = base
	if weight != 400 or spacing != 0:
		var fv := FontVariation.new()
		fv.base_font = base
		if weight != 400:
			fv.variation_opentype = {"wght": weight}
		if spacing != 0:
			fv.spacing_glyph = spacing
		f = fv
	_fonts[key] = f
	return f


## Gölgeli tek satırlık yazı (Tanhu 1'in her ekranda kullandığı biçim).
static func label(text: String, size := 32, font_name := "Alegreya", weight := 400, color := TEXT, spacing := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font(font_name, weight, spacing))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", 3)
	l.add_theme_constant_override("shadow_outline_size", 6)
	return l


## BBCode'lu çok satırlı yazı (italik ve kalın biçimleriyle).
static func rich(size := 34, font_name := "Alegreya") -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.add_theme_font_override("normal_font", font(font_name))
	var italic := font_name + "-Italic"
	r.add_theme_font_override("italics_font", font(italic) if ResourceLoader.exists(FONT_DIR + italic + ".ttf") else font(font_name))
	r.add_theme_font_override("bold_font", font(font_name, 700))
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("italics_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_color_override("default_color", TEXT)
	r.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	r.add_theme_constant_override("shadow_offset_y", 3)
	r.add_theme_constant_override("shadow_outline_size", 5)
	r.add_theme_constant_override("line_separation", 6)
	return r


## Keçe panel biçimi: zemin, kenar rengi ve kalınlığı, köşe yuvarlaklığı, yumuşak gölge.
static func panel_style(bg := FELT, border := GOLD_DIM, bw := 2, radius := 4, glow := Color(0, 0, 0, 0.55), glow_size := 18) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.shadow_color = glow
	s.shadow_size = glow_size
	s.content_margin_left = 28
	s.content_margin_right = 28
	s.content_margin_top = 18
	s.content_margin_bottom = 18
	s.anti_aliasing = true
	return s


## Yumuşak, yuvarlak bir ışık lekesi dokusu (parıltılar için).
static func soft_texture() -> Texture2D:
	if _soft_tex:
		return _soft_tex
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.35, Color(1, 1, 1, 0.55))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 128
	t.height = 128
	_soft_tex = t
	return t


## Arayüzün çizildiği ölçek: oyuncunun arayüz ölçeği (%50–%150, K104) × çözünürlüğün payı (bkz. GameSettings.ui_k). Oyun içi HUD bunun
## HudKit.HUD_SCALE katındadır. Ayarlar autoload'u yoksa (ör. bazı testler) 1.
static func ui_k() -> float:
	var settings := settings_node()
	return float(settings.call(&"ui_k")) if settings and settings.has_method(&"ui_k") else 1.0


## Sinemanın üstündeki yazının ölçeği (GameSettings.film_k; autoload yoksa 1).
static func film_k() -> float:
	var settings := settings_node()
	return float(settings.call(&"film_k")) if settings and settings.has_method(&"film_k") else 1.0


## Ayarlar autoload'u (GameSettings) ya da yoksa null.
static func settings_node() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null(^"GameSettings") if tree else null


## Açılır bir paneli görünen ekranın ortasına, oyuncunun arayüz ölçeğiyle koyar. Ölçek paneli ekrandan taşıracaksa (büyük arayüz ölçeği,
## küçük pencere: 1080 satırda %150) panel ekrana sığacak kadar küçülür (fit_scale); sığan panel oyuncunun ölçeğinde kalır.
static func center_panel(panel: Control) -> void:
	var vp := panel.get_viewport_rect().size
	var s := minf(ui_k(), fit_scale(panel.size, vp - Vector2.ONE * FIT_MARGIN * 2.0))
	panel.scale = Vector2(s, s)
	panel.position = ((vp - panel.size * s) * 0.5).round()


## İçeriği alana sığdıran en büyük ölçek (saf): içerik alandan büyükse 1'in altında, küçükse üstünde; çağıran bir üst sınırla min alır.
## Boyu henüz belli olmayan içerik ya da alan (0) sınır koymaz: INF.
static func fit_scale(content: Vector2, area: Vector2) -> float:
	if content.x <= 0.0 or content.y <= 0.0 or area.x <= 0.0 or area.y <= 0.0:
		return INF
	return minf(area.x / content.x, area.y / content.y)


## Bir köşeye ya da kenar ortasına çapalanmış Control'ü (çapası tek nokta: anchor_left = anchor_right,
## anchor_top = anchor_bottom) k ölçeğinde çizer: çapa noktası yerinde kalır, kenara uzaklığı da ölçekle
## küçülür. Boyu değişebilen (kendi içeriğine göre büyüyen) bir Control için resized'da yeniden çağrılmalı.
static func scale_at_anchor(c: Control, k: float) -> void:
	c.pivot_offset = Vector2(-c.offset_left, -c.offset_top)
	c.scale = Vector2(k, k)


## Tek noktaya çapalanmış Control'ün (scale_at_anchor'ın kuralı) ebeveyninden taşmadan çizilebileceği en büyük ölçek; k'yi aşmaz. Çapa
## noktası yerinde kalır, dört kenar ebeveynin içinde FIT_MARGIN payıyla kalır: büyük arayüz ölçeğinde (1080 satırda %150) oluşturucunun
## parşömeni ekrandan taşmaz. Ebeveyni Control değilse ya da boyu henüz yoksa k döner.
static func anchor_fit_k(c: Control, k: float) -> float:
	var parent := c.get_parent() as Control
	var area := parent.size if parent else c.get_viewport_rect().size
	if area.x <= 0.0 or area.y <= 0.0:
		return k
	var a := Vector2(c.anchor_left * area.x, c.anchor_top * area.y)
	var out := k
	for edge: Array in [[c.offset_left, a.x, area.x], [c.offset_right, a.x, area.x], [c.offset_top, a.y, area.y], [c.offset_bottom, a.y, area.y]]:
		var off: float = edge[0]
		if off < 0.0:
			out = minf(out, (float(edge[1]) - FIT_MARGIN) / -off)
		elif off > 0.0:
			out = minf(out, (float(edge[2]) - FIT_MARGIN - float(edge[1])) / off)
	return maxf(out, 0.1)


## Arayüz ölçeği değişebilecek her durumda (oyuncunun ölçek ayarı, pencerenin piksel boyu) callback'i
## çağırır. callback host'un bir metodu olmalı ki host silinince bağlantılar kendiliğinden kopsun.
static func on_ui_scale_changed(host: Control, callback: Callable) -> void:
	host.get_viewport().size_changed.connect(callback)
	var settings := settings_node()
	if settings and settings.has_signal(&"changed"):
		settings.changed.connect(callback)


## Paneli ebeveyninin (oyun menüsünün bir sayfası; çerçeve arayüz ölçeğini zaten taşır) ortasına
## koyar. Q / E ile çevrilen bir sayfa bir karenin ortasında kurulur, o an panelin boyu yalnızca
## kenar paylarını sayar; önce güncellenir ve panel ya da sayfa boy değiştirdikçe yeniden ortalanır.
## Büyük arayüz ölçeğinde kitabın sayfa alanı küçülür (1080 satırda %150): alana (FIT_MARGIN payıyla) sığmayan panel sığacak kadar küçülür,
## sığan 1'de kalır.
static func center_in_parent(panel: Control) -> void:
	if not panel.has_meta("centred"):
		panel.set_meta("centred", true)
		var again := func() -> void:
			if is_instance_valid(panel) and panel.is_inside_tree():
				_center_in_parent(panel)
		panel.resized.connect(again)
		var parent := panel.get_parent() as Control
		if parent:
			parent.resized.connect(again)
	_center_in_parent(panel)


static func _center_in_parent(panel: Control) -> void:
	var area := (panel.get_parent() as Control).size
	panel.reset_size()
	var f := minf(1.0, fit_scale(panel.size, area - Vector2.ONE * FIT_MARGIN * 2.0))
	panel.scale = Vector2(f, f)
	panel.position = ((area - panel.size * f) * 0.5).round()


## Denetimi ebeveyninin tamamına yayar.
static func full_rect(c: Control) -> void:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.offset_left = 0
	c.offset_top = 0
	c.offset_right = 0
	c.offset_bottom = 0
