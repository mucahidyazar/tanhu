class_name MenuToast
extends VBoxContainer
## Sağ üst köşede kısa süre görünüp kaybolan bildirim (Tanhu 1'in FX.toast'u): küçük, taşsız bir
## süslü çerçeve içinde yazı. Yeni bildirim öncekinin altına dizilir; okunacak bir not olduğundan
## fare içinden geçer. Oyun içi HUD açıkken (sağ üstte mini harita) üst ortaya geçer: centered.

## Belirme, bekleme ve kaybolma süreleri (saniye).
const FADE_IN := 0.3
const HOLD := 3.2
const FADE_OUT := 0.6
## Çerçeve rengi: "info" altın, "save" gök mavisi, "warn" kızıl.
const TINTS := {"info": UIKit.GOLD, "save": UIKit.SKY, "warn": UIKit.CRIMSON}

## Animasyon hız çarpanı (testler hızlandırır).
var speed := 1.0
## Üst ortada mı (oyun içi HUD açıkken), yoksa sağ üst köşede mi?
var centered := false:
	set(value):
		if centered == value:
			return
		centered = value
		if is_inside_tree():
			_place()


func _ready() -> void:
	_place()
	alignment = BoxContainer.ALIGNMENT_BEGIN
	add_theme_constant_override("separation", 10)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _place() -> void:
	if centered:
		set_anchors_preset(Control.PRESET_CENTER_TOP)
		offset_left = -380
		offset_right = 380
		offset_top = 30
	else:
		set_anchors_preset(Control.PRESET_TOP_RIGHT)
		offset_left = -760
		offset_right = -36
		offset_top = 36
	for p in get_children():
		if p is Control:
			(p as Control).size_flags_horizontal = Control.SIZE_SHRINK_CENTER if centered else Control.SIZE_SHRINK_END


## Bildirimi gösterir; birkaç saniye sonra kendiliğinden kaybolur.
func show_text(text: String, kind: String = "info") -> void:
	var l := UIKit.label(text, 26, "Alegreya", 500)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_RIGHT
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(minf(680.0, 14.0 * text.length()), 0)
	var p := OrnateFrame.wrap(l, 18.0, false, 14.0, TINTS.get(kind, UIKit.GOLD), Color(0.024, 0.031, 0.047, 0.86))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if centered else Control.SIZE_SHRINK_END
	p.modulate.a = 0.0
	add_child(p)
	MenuStyle.play_ui(self, &"toast", -8.0)
	if not is_inside_tree():
		p.modulate.a = 1.0
		return
	var tw := create_tween().set_speed_scale(maxf(speed, 0.01))
	tw.tween_property(p, "modulate:a", 1.0, FADE_IN)
	tw.tween_interval(HOLD)
	tw.tween_property(p, "modulate:a", 0.0, FADE_OUT)
	tw.tween_callback(p.queue_free)


## Ekrandaki bildirimlerin yazıları (testler için).
func texts() -> PackedStringArray:
	var out := PackedStringArray()
	for p in get_children():
		if p.is_queued_for_deletion():
			continue
		for c in p.get_children():
			if c is Label:
				out.append((c as Label).text)
	return out


## Bütün bildirimleri hemen kaldırır.
func dismiss() -> void:
	for p in get_children():
		p.queue_free()
