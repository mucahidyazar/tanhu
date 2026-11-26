class_name HudNeeds
extends Control
## HUD'un Tokluk ve Yara göstergesi, Vitals'ın dilinde (HudPortrait: ok uçlu çerçeve, dolgu şeridi, krem sayılar; HudKit): portrenin çocuğudur,
## onun 1080 satırlık yerleşimiyle çizilir ve ölçeğini taşır. Tokluk iki küçük durum yuvasının sağında kısa bir çubuktur (amber dolgu,
## «60»; Tok altın, Aç kızıla döner ve yavaşça nabız atar, Bitkin koyu kızıl); yaralar çubuğun üstünde yara sınırı kadar küçük baklavadır
## (dolu baklava kızıl: yoldaş kartının saat 6'daki baklavalarının dili, ui-menus.md). Serbest Gez'de Tokluk ve yara yoktur: survival
## bağlı değilse ya da Tokluk kapalıysa çizmez. Değerleri Survival'dan okur (Needs, Wounds).
##   var hn := HudNeeds.new()
##   hn.survival = survival
##   gameplay_hud.portrait.add_child(hn)

## Tokluk çubuğu ve baklavalar (1080 satır, portrenin yerleşimi: can 163..431 × 58..90, takat 163..417 × 103..135, durum yuvaları
## 208 ve 261, y 170).
const BAR_RECT := Rect2(292.0, 154.0, 132.0, 27.0)
const DIAMOND_Y := 144.0
const DIAMOND_X0 := 302.0
const DIAMOND_PITCH := 18.0
const DIAMOND_SIZE := 12.0
const TEXT_SIZE := 17
## Bantların dolgu çarpanı (yeşil dolgu şeridini amber, altın ve kızıla çevirir).
const BAND_TINT := {
	"sated": Color(1.0, 0.86, 0.5), "ok": Color(1.0, 0.7, 0.36), "hungry": Color(1.0, 0.42, 0.28), "spent": Color(0.82, 0.26, 0.2),
}
const WOUND_FILL := Color(0.84, 0.16, 0.12)
const EASE := 8.0

var survival: Survival

var _shown := -1.0
var _pulse := 0.0
var _wounds := -1
var _limit := 0
var _band := ""


func _init() -> void:
	name = "Needs"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = HudKit.PORTRAIT_SIZE


## Gösterilecek mi (Tokluk açık bir Survival bağlı)?
func active() -> bool:
	return survival != null and survival.needs.enabled


func _process(delta: float) -> void:
	if not active() or not is_visible_in_tree():
		return
	var want := survival.needs.fullness
	var dirty := false
	if _shown < 0.0:
		_shown = want
		dirty = true
	elif absf(_shown - want) > 0.01:
		_shown = want if absf(_shown - want) < 0.05 else lerpf(_shown, want, 1.0 - exp(-EASE * delta))
		dirty = true
	var band := survival.needs.band()
	if band != _band or survival.wounds.count != _wounds or survival.wounds.limit() != _limit:
		_band = band
		_wounds = survival.wounds.count
		_limit = survival.wounds.limit()
		dirty = true
	if band == "hungry" or band == "spent":
		_pulse += delta
		dirty = true
	if dirty:
		queue_redraw()


## Çubuğun yazısı (sınama): «60».
func bar_text() -> String:
	return str(roundi(survival.needs.fullness)) if active() else ""


## Baklavalar (sınama): [dolu sayısı, toplam].
func diamonds() -> Array:
	return [survival.wounds.count, survival.wounds.limit()] if active() else [0, 0]


func _draw() -> void:
	if not active():
		return
	var ratio := clampf((_shown if _shown >= 0.0 else survival.needs.fullness) / Needs.value("max"), 0.0, 1.0)
	var tint: Color = BAND_TINT.get(survival.needs.band(), BAND_TINT["ok"])
	if _band == "hungry" or _band == "spent":
		# Aç bant yavaşça nabız atar (1,2 sn): göz kaçırmaz, bağırmaz.
		tint = tint.lerp(Color(1.0, 0.85, 0.75), 0.18 * (0.5 + 0.5 * sin(_pulse * TAU / 1.2)))
	_draw_bar(BAR_RECT, ratio, tint, bar_text())
	var lim := survival.wounds.limit()
	for i in lim:
		var c := Vector2(DIAMOND_X0 + DIAMOND_PITCH * i, DIAMOND_Y)
		_draw_diamond(c, DIAMOND_SIZE, i < survival.wounds.count)


## HudPortrait._draw_bar'ın dili: çerçeve (9 dilim), koyu kanalın içinde dolgu, ortada sayı; dolgu yeşil şeridin amberle çarpımıdır.
func _draw_bar(rect: Rect2, ratio: float, tint: Color, text: String) -> void:
	var k := rect.size.y / HudKit.BAR_SIZE.y
	HudKit.draw_hslice(self, "bar_frame", rect, HudKit.BAR_PATCH.x, HudKit.BAR_PATCH.z)
	var ch := HudKit.BAR_CHANNEL
	var x0 := rect.position.x + ch.position.x * k
	var x1 := rect.end.x - (HudKit.BAR_SIZE.x - ch.end.x) * k
	var y0 := rect.position.y + ch.position.y * k + 1.0
	var y1 := rect.position.y + ch.end.y * k - 1.0
	var w := (x1 - x0) * clampf(ratio, 0.0, 1.0)
	if w > 0.5:
		HudKit.draw_hslice(self, "bar_fill_green", Rect2(x0, y0, w, y1 - y0), HudKit.FILL_PATCH, HudKit.FILL_PATCH, Vector2(-1.0, -1.0), tint)
	# Çanak işareti (Tokluk): kanalın solunda küçük, krem.
	HudItemIcon.draw_glyph(self, "bowl", Vector2(x0 + 11.0, (y0 + y1) * 0.5 + 0.5), 6.5, Color(1.0, 1.0, 1.0, 0.9))
	var mid := Vector2((x0 + 22.0 + x1) * 0.5, (y0 + y1) * 0.5 + TEXT_SIZE * 0.34)
	HudKit.draw_text(self, HudKit.number_font(600), mid, text, TEXT_SIZE, HudKit.CREAM, 1)


## Yara baklavası: lacivert mine, altın kenar; açık yara kızıl.
func _draw_diamond(c: Vector2, s: float, filled: bool) -> void:
	var h := s * 0.5
	var pts := PackedVector2Array([c + Vector2(0.0, -h), c + Vector2(h, 0.0), c + Vector2(0.0, h), c + Vector2(-h, 0.0)])
	draw_colored_polygon(PackedVector2Array([pts[0] + Vector2(0.0, 1.5), pts[1] + Vector2(0.0, 1.5), pts[2] + Vector2(0.0, 1.5),
		pts[3] + Vector2(0.0, 1.5)]), Color(0.0, 0.0, 0.0, 0.45))
	draw_colored_polygon(pts, WOUND_FILL if filled else Color(HudKit.NAVY, 0.85))
	var loop := pts.duplicate()
	loop.append(pts[0])
	draw_polyline(loop, Color(HudKit.GOLD, 0.95 if filled else 0.7), 1.6, true)
