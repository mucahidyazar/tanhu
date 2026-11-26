class_name HudActionPrompt
extends Control
## O an yapılabileceğin ipucu, HUD'un dilinde (PlayerController.prompt_changed: «E Bin», «Shift Dürt · E İn · Sağ tık Nişan»): yuva
## şeridinin hemen üstünde, ortalı ince lacivert bir şerit; tuşlar lacivert-altın kapakta krem Cinzel, eylemler krem Alegreya. HUD
## açıkken oyuncunun kendi ipucu panelinin (PlayerPrompt) yerine görünür (GameplayHud); tuş ipuçları şeridi (GameHud) XP çubuğunun
## altındadır: üçü birbirine değmez. Alt ortaya çapalıdır, 1080 satıra çizilir. Boş liste gizler.

## Şeridin alt kenarının ekranın altına uzaklığı (1080 satır; yuvaların tuş yazılarının üstü) ve yüksekliği.
const BOTTOM := 172.0
const HEIGHT := 34.0
const KEY_SIZE := 14
const ACTION_SIZE := 17
const PAD := 34.0
const GAP := 14.0

var pairs: Array = []
## HUD ölçeğinin iç kayması (1080 satır, aşağı +; set_lift).
var lift := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	_place()


func set_pairs(p_pairs: Array) -> void:
	pairs = p_pairs.duplicate()
	visible = not pairs.is_empty()
	_place()
	queue_redraw()


## Düz yazı (sınama): GameHud.format_hints biçiminde.
func get_text() -> String:
	return GameHud.format_hints(pairs)


## Şeridin genişliği (saf hesap: tuş kapakları ve yazılar).
static func strip_width(p_pairs: Array) -> float:
	var w := PAD * 2.0
	var key_font := UIKit.font("Cinzel", 700)
	var f := HudKit.body_font(500)
	for i in p_pairs.size():
		if i > 0:
			w += GAP + 8.0
		w += HudKit.text_width(key_font, str(p_pairs[i][0]), KEY_SIZE) + 16.0 + 7.0
		w += HudKit.text_width(f, str(p_pairs[i][1]), ACTION_SIZE)
	return w


## HUD ölçeğinin iç kayması (HudKit.lift_for; GameplayHud verir): şerit yuvalarla birlikte XP çubuğunun alt kenarından büyür.
func set_lift(v: float) -> void:
	lift = v
	_place()


func _place() -> void:
	var w := strip_width(pairs)
	offset_left = -w * 0.5
	offset_right = w * 0.5
	offset_top = -BOTTOM - HEIGHT + lift
	offset_bottom = -BOTTOM + lift
	# Genişlik ipucuyla değişir: ölçeğin dayanağı yine çapa noktası olsun (UIKit.scale_at_anchor'ın kuralı; kayma ölçeğin içindedir).
	pivot_offset = Vector2(-offset_left, -offset_top)


func _draw() -> void:
	if pairs.is_empty():
		return
	var r := Rect2(Vector2(14.0, 1.0), size - Vector2(28.0, 2.0))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.035, 0.07, 0.14, 0.82)
	sb.set_corner_radius_all(int(r.size.y * 0.5))
	sb.border_color = Color(HudKit.GOLD, 0.55)
	sb.set_border_width_all(1)
	sb.anti_aliasing = true
	draw_style_box(sb, r)
	var cloud := Vector2(r.size.y * 1.9, r.size.y * 0.95)
	HudKit.draw_centered(self, "cloud_left", Vector2(r.position.x - cloud.x * 0.16, r.get_center().y), cloud)
	HudKit.draw_centered(self, "cloud_right", Vector2(r.end.x + cloud.x * 0.16, r.get_center().y), cloud)
	var key_font := UIKit.font("Cinzel", 700)
	var f := HudKit.body_font(500)
	var x := PAD
	var mid := size.y * 0.5
	for i in pairs.size():
		if i > 0:
			draw_circle(Vector2(x + 4.0, mid), 2.0, Color(HudKit.GOLD, 0.7))
			x += GAP + 8.0
		var key := str(pairs[i][0])
		var kw := HudKit.text_width(key_font, key, KEY_SIZE) + 16.0
		var kr := Rect2(Vector2(x, mid - 11.0), Vector2(kw, 22.0))
		draw_style_box(HudKit.keycap_box(), kr)
		HudKit.draw_text(self, key_font, Vector2(kr.get_center().x, mid + 5.0), key, KEY_SIZE, HudKit.CREAM, 1, Color(0, 0, 0, 0), 0)
		x += kw + 7.0
		var action := str(pairs[i][1])
		HudKit.draw_text(self, f, Vector2(x, mid + 6.0), action, ACTION_SIZE, HudKit.CREAM, 0, HudKit.SHADOW, 3)
		x += HudKit.text_width(f, action, ACTION_SIZE)
