class_name ConfirmDialog
extends Control
## Menü biçiminde evet / hayır sorusu (Tanhu 1). `await ConfirmDialog.ask(ebeveyn, yazı)` evet için
## true döner. Esc (ui_cancel) "hayır" demektir; odak önce "HAYIR"dadır.

const YES_TEXT := "EVET"
const NO_TEXT := "HAYIR"

var _result := 0
var yes_button: KnotButton
var no_button: KnotButton


static func ask(parent: Node, text: String) -> bool:
	var d := ConfirmDialog.new()
	parent.add_child(d)
	return await d.run(text)


## Soruyu gösterir ve yanıtı bekler (ask() bunu çağırır).
func run(text: String) -> bool:
	UIKit.full_rect(self)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	UIKit.full_rect(dim)
	dim.color = Color(0, 0, 0, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 26)
	var l := UIKit.label(text, 34, "Alegreya", 500, UIKit.PARCHMENT)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(760, 0)
	vb.add_child(l)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 30)
	vb.add_child(hb)
	yes_button = KnotButton.new(YES_TEXT, 30)
	yes_button.custom_minimum_size = Vector2(280, 66)
	yes_button.pressed.connect(answer.bind(true))
	no_button = KnotButton.new(NO_TEXT, 30)
	no_button.custom_minimum_size = Vector2(280, 66)
	no_button.pressed.connect(answer.bind(false))
	hb.add_child(yes_button)
	hb.add_child(no_button)
	# Sol / sağ iki buton arasında döner; yukarı / aşağı yerinde kalır.
	for b: KnotButton in [yes_button, no_button]:
		var other := no_button if b == yes_button else yes_button
		b.focus_neighbor_left = b.get_path_to(other)
		b.focus_neighbor_right = b.get_path_to(other)
		b.focus_neighbor_top = b.get_path_to(b)
		b.focus_neighbor_bottom = b.get_path_to(b)
	var panel := OrnateFrame.wrap(vb)
	add_child(panel)
	await get_tree().process_frame
	UIKit.center_panel(panel)
	no_button.grab_focus_quietly()
	while _result == 0:
		await get_tree().process_frame
	var ok := _result == 1
	queue_free()
	return ok


## Soruyu yanıtlar (butonlar ve testler kullanır).
func answer(yes: bool) -> void:
	if _result == 0:
		_result = 1 if yes else 2


func _input(event: InputEvent) -> void:
	if _result == 0 and (event.is_action_pressed(&"ui_cancel") or (InputMap.has_action(&"pause") and event.is_action_pressed(&"pause"))):
		get_viewport().set_input_as_handled()
		answer(false)
