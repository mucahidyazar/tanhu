class_name FlowCard
extends Control
## Yeni Oyun'un son kartı (K99): yapımın geldiği yerin sonu. Kara ekranın ortasında «I. Perde: Çan» (Cinzel), altında kısa «Yapım
## aşamasında.» satırı (Alegreya italik); I. Perde'nin kara ekranının çanı bir kez çalar (bell_step, AudioManager). Kart kara perdenin
## üstünde açılır ve kapanır (perde altta kara kalır); bekleme bir tuşla kısalır (açıldıktan MIN_HOLD sonra), F11 sayılmaz.
## I. Perde gelince NewGameFlow kartı kendiliğinden düşürür (new_game.json: unless). Akış kayıt yazmaz; kart bitince açılış ekranı gelir.
##   var card := FlowCard.new()
##   card.title_text = "I. Perde: Çan"; card.line_text = "Yapım aşamasında."
##   $UI.add_child(card)
##   await card.play()          # bitince finished yayar ve kendini siler

signal finished

const BACKGROUND := Color(0.012, 0.014, 0.022)
const TITLE_SIZE := 54
const LINE_SIZE := 27
## Bekleme bu kadar sürmeden basış kısaltmaz (sn): kart kazara geçilmesin.
const MIN_HOLD := 1.0
const SFX_DB := -12.0

@export var fade_in := 1.2
@export var hold := 5.0
@export var fade_out := 1.1

var title_text := ""
var line_text := ""
## Açılırken çalan efekt (boşsa yok).
var sfx := "bell_step"

var _box: VBoxContainer
var _skip := false
var _waiting := false
var _held := 0.0


func _ready() -> void:
	name = "FlowCard" if name.is_empty() else name
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
	_box.add_theme_constant_override("separation", 22)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_box)
	var title := UIKit.label(title_text, TITLE_SIZE, "Cinzel", 600, UIKit.GOLD, 3)
	title.name = "Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(title)
	var line := UIKit.label(line_text, LINE_SIZE, "Alegreya-Italic", 400, UIKit.TEXT_DIM)
	line.name = "Line"
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.visible = not line_text.is_empty()
	_box.add_child(line)
	modulate.a = 0.0
	resized.connect(_layout)
	UIKit.on_ui_scale_changed(self, _layout)
	_layout()


## Kartı oynatır: belirir (çan çalar), bekler (kısaltılabilir), söner. Bitince finished yayar ve kendini siler.
func play() -> void:
	await get_tree().process_frame
	_layout()
	if not sfx.is_empty():
		var audio := get_node_or_null(^"/root/AudioManager")
		if audio and audio.has_method(&"play_sfx"):
			audio.call(&"play_sfx", StringName(sfx), {"db": SFX_DB})
	if fade_in > 0.0:
		var appear := create_tween()
		appear.tween_property(self, ^"modulate:a", 1.0, fade_in).set_trans(Tween.TRANS_SINE)
		await appear.finished
	modulate.a = 1.0
	_skip = false
	_waiting = true
	_held = 0.0
	while _held < hold and not _skip:
		await get_tree().process_frame
		_held += get_process_delta_time()
	_waiting = false
	if fade_out > 0.0:
		var vanish := create_tween()
		vanish.tween_property(self, ^"modulate:a", 0.0, fade_out).set_trans(Tween.TRANS_SINE)
		await vanish.finished
	modulate.a = 0.0
	finished.emit()
	queue_free()


func is_waiting() -> bool:
	return _waiting


## Beklemeyi kısaltır (MIN_HOLD dolduysa; sınama ve tuş).
func skip() -> void:
	if _waiting and _held >= MIN_HOLD:
		_skip = true


func _input(event: InputEvent) -> void:
	if not Epigraph.is_skip_event(event):
		return
	get_viewport().set_input_as_handled()
	skip()


## Kart sinemanın yazısıdır (CineHost'un kartı gibi): film ölçeğinde (UIKit.film_k) ekranın ortasında.
func _layout() -> void:
	if _box == null or not is_inside_tree():
		return
	_box.size = _box.get_combined_minimum_size()
	var k := UIKit.film_k()
	_box.scale = Vector2(k, k)
	_box.position = ((get_viewport_rect().size - _box.size * k) * 0.5).round()
