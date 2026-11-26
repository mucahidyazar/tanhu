class_name Epigraph
extends Control
## Açılış sözü (Tanhu 1'deki gibi): koyu ekranın ortasında Mete'nin sözü, altında kimin söylediği.
##
## Ekran siyahtan yavaşça açılır (fade_in), söz bir süre kalır (hold), sonra ekran yeniden siyaha döner
## (fade_out); ardından menünün girişi başlar. Beklerken bir tuşa, fareye ya da oyun kolu düğmesine basmak
## beklemeyi kısaltır; belirirken basılan tuş sayılmaz (yanlışlıkla atlanmasın). Söz ekranda dururken
## basışlar alttaki düğümlere ulaşmaz (F11 hariç: tam ekran her an değiştirilebilir). Söz bloğu arayüz
## ölçeğiyle (UIKit.ui_k) ortalanır; pencere boyu ya da ölçek değişince yeniden ortalanır.
##
## Kullanım:
##   var epigraph := Epigraph.new()
##   $UI.add_child(epigraph)
##   await epigraph.play()    # bitince finished yayar ve kendini siler

signal finished

const QUOTE := "«Yer, devletin temelidir. Onu kimseye vermem.»"
const BY := "Mete, Hunların Tanhusu · MÖ 3. yüzyıl"
const BACKGROUND := Color(0.015, 0.018, 0.026)

## Süreler (saniye): siyahtan açılma, sözün ekranda kalması, siyaha dönüş.
@export var fade_in := 1.6
@export var hold := 4.2
@export var fade_out := 1.2

var _box: VBoxContainer
var _skip := false
var _waiting := false


func _ready() -> void:
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var bg := ColorRect.new()
	bg.name = "Background"
	UIKit.full_rect(bg)
	bg.color = BACKGROUND
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_box = VBoxContainer.new()
	_box.name = "Box"
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_theme_constant_override("separation", 26)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)
	var quote := UIKit.label(QUOTE, 48, "Alegreya-Italic", 400, UIKit.PARCHMENT)
	quote.name = "Quote"
	quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(quote)
	var by := UIKit.label(BY, 24, "Cinzel", 600, UIKit.GOLD_DIM, 4)
	by.name = "By"
	by.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(by)
	modulate.a = 0.0
	resized.connect(_layout)
	UIKit.on_ui_scale_changed(self, _layout)
	_layout()


## Sözü oynatır: ekran siyahtan açılır, söz bekler (kısaltılabilir), ekran siyaha döner. Bitince finished
## yayar ve kendini siler.
func play() -> void:
	await get_tree().process_frame
	_layout()
	if fade_in > 0.0:
		var appear := create_tween()
		appear.tween_property(self, ^"modulate:a", 1.0, fade_in).set_trans(Tween.TRANS_SINE)
		# Söz çoğu zaman ağır sahne kurulumunun hemen ardından başlar: açılış atlanmasın.
		MenuStyle.play_when_settled(self, appear)
		await appear.finished
	modulate.a = 1.0
	_skip = false
	_waiting = true
	var t := 0.0
	while t < hold and not _skip:
		await get_tree().process_frame
		t += get_process_delta_time()
	_waiting = false
	if fade_out > 0.0:
		var vanish := create_tween()
		vanish.tween_property(self, ^"modulate:a", 0.0, fade_out).set_trans(Tween.TRANS_SINE)
		await vanish.finished
	modulate.a = 0.0
	finished.emit()
	queue_free()


## Söz bekliyor mu (basış onu kısaltır)?
func is_waiting() -> bool:
	return _waiting


## Basış sözü kısaltan türden mi? Tuş, fare (tekerlek değil), oyun kolu düğmesi ya da dokunuş; F11 (tam ekran)
## sayılmaz (saf fonksiyon).
static func is_skip_event(event: InputEvent) -> bool:
	if InputMap.has_action(&"toggle_fullscreen") and event.is_action(&"toggle_fullscreen"):
		return false
	if event is InputEventKey:
		return event.is_pressed() and not event.is_echo()
	if event is InputEventMouseButton:
		var b := (event as InputEventMouseButton).button_index
		return event.is_pressed() and b in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]
	if event is InputEventJoypadButton or event is InputEventScreenTouch:
		return event.is_pressed()
	return false


func _input(event: InputEvent) -> void:
	if not Epigraph.is_skip_event(event):
		return
	get_viewport().set_input_as_handled()
	if _waiting:
		_skip = true


## Söz bloğunu arayüz ölçeğiyle ekranın ortasına koyar.
func _layout() -> void:
	if _box == null or not is_inside_tree():
		return
	_box.size = _box.get_combined_minimum_size()
	UIKit.center_panel(_box)
