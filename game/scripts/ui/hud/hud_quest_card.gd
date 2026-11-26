class_name HudQuestCard
extends Control
## Mini haritanın altındaki görev kartı (referanstaki gibi): bulut kıvrımlı gümüş süs çubuğunun üstünde altın Cinzel başlık
## («KOYUN SIRTINDA»), solda çubuktan sarkan mavi sancak ve baklavası, sağında beyaz amaç («Sayım hattına koş») ve küçük ayrıntı
## satırı («Sayıcı sürüyü hattan geçiriyor.»; sığmazsa iki satır). Yazı değişince kart kısa bir parıltıyla yenilenir. Sağ üst köşeye
## çapalıdır, 1080 satıra çizilir. Görev yoksa gizlidir.

const TITLE_SIZE := 17
const OBJECTIVE_SIZE := 21
const DETAIL_SIZE := 16
## Kartın kutusu (sağ üst köşeye göre).
const BOX := Rect2(HudKit.QUEST_LEFT, 276.0, -HudKit.QUEST_LEFT, 140.0)
## Kutunun içindeki yerler (kutunun sol üstüne göre): yazının sol kenarı, başlığın taban çizgisi, amacın ve ayrıntının taban çizgisi.
const TEXT_X := 74.0
const TITLE_BASE := 33.0
const OBJECTIVE_BASE := 72.0
const DETAIL_BASE := 96.0
const DETAIL_LINE := 19.0
const BANNER_X := 38.0
const FLASH := 0.6

var title := ""
var objective := ""
var detail := ""

var _flash := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = BOX.position.x
	offset_right = BOX.end.x
	offset_top = BOX.position.y
	offset_bottom = BOX.end.y


## Kartın yazıları; değiştiyse kart parlar. Boş başlık kartı gizler.
func set_quest(p_title: String, p_objective: String, p_detail: String) -> void:
	if p_title == title and p_objective == objective and p_detail == detail:
		return
	var changed_step := p_objective != objective and not objective.is_empty()
	title = p_title
	objective = p_objective
	detail = p_detail
	visible = not title.is_empty()
	if changed_step:
		_flash = FLASH
	queue_redraw()


func _process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(_flash - delta, 0.0)
		queue_redraw()


## Yazının genişliği: süs çubuğunun sağ ucuna dek (referanstaki gibi yazı yaprakların altında biter).
const TEXT_WIDTH := HudKit.QUEST_WIDTH - TEXT_X


## Ayrıntının çizilen satırları (sınama).
func detail_lines() -> PackedStringArray:
	return HudKit.wrap_lines(HudKit.body_font(), detail, DETAIL_SIZE, TEXT_WIDTH, 2)


func _draw() -> void:
	if title.is_empty():
		return
	var rod_y := HudKit.QUEST_ROD_Y - BOX.position.y
	var k := HudKit.RULE_SCALE
	var rule_h := HudKit.RULE_SIZE.y * k
	HudKit.draw_hslice(self, "quest_rule", Rect2(0.0, rod_y - HudKit.RULE_ROD_Y * k, HudKit.QUEST_WIDTH, rule_h),
		HudKit.RULE_PATCH.x, HudKit.RULE_PATCH.y)
	var gold := HudKit.GOLD.lerp(Color(1.0, 0.95, 0.75), _flash / FLASH * 0.6)
	var title_font := HudKit.title_font()
	var shown_title := HudKit.fit_text(title_font, title.to_upper(), TITLE_SIZE, HudKit.QUEST_WIDTH - TEXT_X - 52.0)
	HudKit.draw_text(self, title_font, Vector2(TEXT_X, TITLE_BASE), shown_title, TITLE_SIZE, gold, 0, HudKit.SHADOW, 3)
	var banner := HudKit.tex("quest_banner")
	if banner:
		var bs := banner.get_size() * HudKit.BANNER_SCALE
		draw_texture_rect(banner, Rect2(Vector2(BANNER_X - bs.x * 0.5, rod_y - 3.0), bs), false)
	if not objective.is_empty():
		var f := HudKit.body_font(600)
		HudKit.draw_text(self, f, Vector2(TEXT_X, OBJECTIVE_BASE), HudKit.fit_text(f, objective, OBJECTIVE_SIZE, TEXT_WIDTH + 12.0),
			OBJECTIVE_SIZE, HudKit.CREAM, 0, HudKit.SHADOW, 4)
	var y := DETAIL_BASE
	for line in detail_lines():
		HudKit.draw_text(self, HudKit.body_font(), Vector2(TEXT_X, y), line, DETAIL_SIZE, HudKit.TEXT_DIM, 0, HudKit.SHADOW, 3)
		y += DETAIL_LINE
