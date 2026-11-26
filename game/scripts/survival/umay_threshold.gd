class_name UmayThreshold
extends CanvasLayer
## Umay Eşiği'nin perdesi (progression.md §8.5; combat «Düşüş»; K1, K35; story.md §9): kısa kararma, altın ışık, uyanış. Kapı, kuş ve görü
## yoktur. İlk Düşüş'te karanlığın ortasında tek söz yazar: «Umay.» Sırayı SurvivalLayer yürütür: dark() ile kararır, karanlıkta
## Survival.apply_fall ve uyanış yeri, sonra dawn() altın ışıkla açılır. Bekleme, oyunun ağacı duraklatılmadan kendi saatiyle yürür.
##   var u := UmayThreshold.new(); add_child(u)
##   await u.dark(0.6)                 # kararır
##   await u.show_card("Umay.", 2.4)   # ilk Düşüş
##   await u.dawn(1.8)                 # altın ışıkla açılır

const GOLD_LIGHT := Color(1.0, 0.82, 0.42)
const LAYER := 90

var _black: ColorRect
var _gold: ColorRect
var _card: Label


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_black = ColorRect.new()
	_black.name = "Black"
	_black.color = Color(0.0, 0.0, 0.0, 0.0)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(_black)
	add_child(_black)
	_gold = ColorRect.new()
	_gold.name = "Gold"
	_gold.color = Color(GOLD_LIGHT, 0.0)
	_gold.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(_gold)
	add_child(_gold)
	_card = Label.new()
	_card.name = "Card"
	_card.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_card.add_theme_font_override(&"font", UIKit.font("Cinzel", 700))
	_card.add_theme_font_size_override(&"font_size", int(64 * UIKit.ui_k()))
	_card.add_theme_color_override(&"font_color", HudKit.GOLD)
	_card.add_theme_color_override(&"font_shadow_color", Color(0.0, 0.0, 0.0, 0.7))
	_card.add_theme_constant_override(&"shadow_offset_y", 3)
	_card.modulate.a = 0.0
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(_card)
	add_child(_card)


## Kararır (saniyede): altın bir parıltıdan siyaha.
func dark(seconds := 0.6) -> void:
	var t := create_tween().set_parallel(true)
	t.tween_property(_gold, ^"color:a", 0.35, seconds * 0.4)
	t.tween_property(_black, ^"color:a", 1.0, seconds).set_trans(Tween.TRANS_SINE)
	await t.finished
	_gold.color.a = 0.0


## İlk Düşüş kartı: karanlıkta tek söz.
func show_card(text: String, seconds := 2.4) -> void:
	_card.text = text
	var t := create_tween()
	t.tween_property(_card, ^"modulate:a", 1.0, 0.6)
	t.tween_interval(maxf(seconds - 1.2, 0.2))
	t.tween_property(_card, ^"modulate:a", 0.0, 0.6)
	await t.finished


## Altın ışıkla açılır: siyah söner, altın bir an parlar, sonra o da söner.
func dawn(seconds := 1.8) -> void:
	_gold.color.a = 0.55
	var t := create_tween().set_parallel(true)
	t.tween_property(_black, ^"color:a", 0.0, seconds * 0.6).set_trans(Tween.TRANS_SINE)
	t.tween_property(_gold, ^"color:a", 0.0, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await t.finished


## Perde şu an kapalı mı (sınama)?
func is_dark() -> bool:
	return _black.color.a > 0.99


func card_text() -> String:
	return _card.text
