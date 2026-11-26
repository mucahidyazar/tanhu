class_name SaveLoadPanel
extends Control
## Kayıt yuvaları kart kart (Tanhu 1): küçük resim, yer ve kayıt numarası ("Ocak başı #3"), kampın
## adı ve yer, oynanan süre ve tarih. Kaydetme kipinde (oyunda) yolculuk seçilen yuvaya yazılır;
## yükleme kipinde seçilen yuva load_requested ile sahibine bildirilir (yüklemeyi o yapar).
## Yükleme kipinde otomatik kayıt (A) da listelenir. Esc ya da GERİ kapatır.

signal closed
signal load_requested(slot: int)
## Kaydetme kipinde bir yuvaya yazıldı.
signal saved(slot: int)

const SAVE_TITLE := "Kaydet"
const LOAD_TITLE := "Yükle"
const BACK_TEXT := "GERİ"
const EMPTY_TEXT := "Boş yuva"
const OVERWRITE_TEXT := "Bu kaydın üzerine yazılsın mı?"
const LOAD_CONFIRM_TEXT := "Kaydedilmemiş ilerleme kaybolacak. Yüklensin mi?"

var mode := "save"
var in_game := true
## Okunan / yazılan kayıtlar.
var saves: SaveSystem
## Kaydetme kipinde yazılacak yolculuk.
var journey: Journey
var back_button: KnotButton
var _cards: Array[SlotCard] = []
var _busy := false


func _init(m := "save", game := true) -> void:
	mode = m
	in_game = game


func _ready() -> void:
	UIKit.full_rect(self)
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	if saves == null:
		saves = journey.saves if journey else SaveSystem.new()
	var dim := ColorRect.new()
	UIKit.full_rect(dim)
	dim.color = Color(0, 0, 0, 0.64)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	var title := UIKit.label(SAVE_TITLE if mode == "save" else LOAD_TITLE, 44, "Cinzel", 700, UIKit.GOLD, 6)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(title)
	var rule := Divider.new()
	rule.custom_minimum_size = Vector2(0, 26)
	vb.add_child(rule)
	if mode == "load":
		var auto_row := HBoxContainer.new()
		auto_row.alignment = BoxContainer.ALIGNMENT_CENTER
		vb.add_child(auto_row)
		var ac := SlotCard.new(SaveSystem.AUTO_SLOT)
		ac.pressed.connect(_on_pick.bind(SaveSystem.AUTO_SLOT))
		auto_row.add_child(ac)
		_cards.append(ac)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 10)
	vb.add_child(grid)
	for s in range(1, SaveSystem.SLOTS + 1):
		var c := SlotCard.new(s)
		c.pressed.connect(_on_pick.bind(s))
		grid.add_child(c)
		_cards.append(c)
	back_button = KnotButton.new(BACK_TEXT, 30)
	back_button.custom_minimum_size = Vector2(340, 62)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(close)
	vb.add_child(back_button)
	var panel := OrnateFrame.wrap(vb, 34.0)
	add_child(panel)
	refresh()
	await get_tree().process_frame
	UIKit.center_panel(panel)
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.18)
	focus_first()


## Kartları diskteki kayıtlarla yeniler (yükleme kipinde boş yuvalar seçilemez).
func refresh() -> void:
	for c in _cards:
		var info := saves.slot_info(c.slot)
		c.set_info(info, saves.load_thumb(c.slot) if not info.is_empty() else null)
		c.disabled = mode == "load" and info.is_empty()
		c.focus_mode = Control.FOCUS_NONE if c.disabled else Control.FOCUS_ALL


## Yuvanın kartı (yoksa null).
func card_for(slot: int) -> SlotCard:
	for c in _cards:
		if c.slot == slot:
			return c
	return null


func get_cards() -> Array[SlotCard]:
	return _cards


## İlk seçilebilir kartı odaklar (hiçbiri yoksa GERİ'yi).
func focus_first() -> void:
	for c in _cards:
		if not c.disabled:
			c.grab_focus()
			return
	back_button.grab_focus_quietly()


## Paneli kapatır.
func close() -> void:
	closed.emit()
	queue_free()


## Bir yuva seçildi: kaydetme kipinde yazar (doluysa sorar), yükleme kipinde bildirir.
func pick(slot: int) -> void:
	await _on_pick(slot)


func _on_pick(slot: int) -> void:
	if _busy:
		return
	var info := saves.slot_info(slot)
	_busy = true
	if mode == "save":
		if not info.is_empty() and not await ConfirmDialog.ask(self, OVERWRITE_TEXT):
			_busy = false
			_focus(slot)
			return
		var ok := journey != null and journey.save_manual(slot)
		refresh()
		_focus(slot)
		_busy = false
		if ok:
			saved.emit(slot)
		else:
			MenuStyle.play_ui(self, &"deny")
		return
	if info.is_empty():
		_busy = false
		return
	if in_game and not await ConfirmDialog.ask(self, LOAD_CONFIRM_TEXT):
		_busy = false
		_focus(slot)
		return
	_busy = false
	load_requested.emit(slot)


func _focus(slot: int) -> void:
	var c := card_for(slot)
	if c and is_instance_valid(c):
		c.grab_focus()


func _unhandled_input(e: InputEvent) -> void:
	if _busy:
		return
	if e.is_action_pressed(&"ui_cancel") or (InputMap.has_action(&"pause") and e.is_action_pressed(&"pause")):
		get_viewport().set_input_as_handled()
		close()


## Tek yuva: küçük resim, başlık, kamp ve yer, süre ve tarih; menü butonları gibi ışır.
class SlotCard extends Button:
	var slot := 0
	var _thumb: TextureRect
	var _empty_mark: Label
	var _title: Label
	var _sub: Label
	var _meta: Label

	func _init(s: int) -> void:
		slot = s
		focus_mode = Control.FOCUS_ALL
		custom_minimum_size = Vector2(800, 112)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_build()

	func _build() -> void:
		add_theme_stylebox_override("normal", UIKit.panel_style(Color(0.045, 0.055, 0.078, 0.9), Color(0.45, 0.38, 0.26, 0.75), 2, 3, Color(0, 0, 0, 0.4), 8))
		var hot := UIKit.panel_style(Color(0.06, 0.09, 0.12, 0.97), UIKit.SKY, 3, 3, Color(UIKit.SKY, 0.45), 18)
		add_theme_stylebox_override("hover", hot)
		add_theme_stylebox_override("focus", hot)
		add_theme_stylebox_override("pressed", hot)
		add_theme_stylebox_override("disabled", UIKit.panel_style(Color(0.04, 0.045, 0.06, 0.55), Color(0.3, 0.27, 0.22, 0.45), 2, 3, Color(0, 0, 0, 0.25), 4))
		var hb := HBoxContainer.new()
		hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
		hb.add_theme_constant_override("separation", 16)
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(hb)
		var frame := PanelContainer.new()
		var fsb := UIKit.panel_style(Color(0.02, 0.025, 0.035, 1.0), UIKit.GOLD_DIM, 1, 2, Color(0, 0, 0, 0), 0)
		fsb.set_content_margin_all(2)
		frame.add_theme_stylebox_override("panel", fsb)
		frame.custom_minimum_size = Vector2(144, 81)
		frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(frame)
		_thumb = TextureRect.new()
		_thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_thumb.custom_minimum_size = Vector2(144, 81)
		_thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(_thumb)
		_empty_mark = UIKit.label("◇", 34, "Cinzel", 400, Color(UIKit.GOLD_DIM, 0.8))
		_empty_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_empty_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		frame.add_child(_empty_mark)
		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		vb.add_theme_constant_override("separation", 0)
		vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(vb)
		_title = UIKit.label("", 24, "Alegreya", 600, UIKit.PARCHMENT)
		_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_title.clip_text = true
		_sub = UIKit.label("", 17, "AlegreyaSC-Regular", 400, UIKit.GOLD, 1)
		_meta = UIKit.label("", 16, "Alegreya-Italic", 400, UIKit.TEXT_DIM)
		for l in [_title, _sub, _meta]:
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vb.add_child(l)
		var num := UIKit.label("A" if slot == SaveSystem.AUTO_SLOT else str(slot), 30, "Cinzel", 700, Color(UIKit.GOLD, 0.8))
		num.custom_minimum_size = Vector2(46, 0)
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		num.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(num)
		mouse_entered.connect(func() -> void:
			if not disabled:
				grab_focus())
		focus_entered.connect(func() -> void: MenuStyle.play_ui(self, &"hover"))
		pressed.connect(func() -> void: MenuStyle.play_ui(self, &"click"))

	## Kartı bir kaydın bilgisiyle doldurur ({} = boş yuva).
	func set_info(info: Dictionary, thumb: Texture2D = null) -> void:
		if info.is_empty():
			_title.text = SaveLoadPanel.EMPTY_TEXT
			_title.add_theme_color_override("font_color", UIKit.TEXT_DIM)
			_sub.text = ""
			_meta.text = ""
			_thumb.texture = null
			_empty_mark.visible = true
			return
		_title.text = SaveData.slot_title(info, slot)
		_title.add_theme_color_override("font_color", UIKit.PARCHMENT)
		_sub.text = SaveData.place_line(info)
		_meta.text = SaveData.meta_line(info)
		_thumb.texture = thumb
		_empty_mark.visible = thumb == null

	## Kartın yazıları tek satırda (testler için).
	func summary() -> String:
		return "%s · %s · %s" % [_title.text, _sub.text, _meta.text]


## Menünün ortası elmaslı altın çizgisi.
class Divider extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var y := size.y * 0.5
		var cx := size.x * 0.5
		var c := Color(UIKit.GOLD, 0.8)
		var half := minf(300.0, cx - 4.0)
		draw_line(Vector2(cx - half, y), Vector2(cx - 22, y), c, 2.0, true)
		draw_line(Vector2(cx + 22, y), Vector2(cx + half, y), c, 2.0, true)
		draw_polyline(PackedVector2Array([Vector2(cx, y - 11), Vector2(cx + 11, y), Vector2(cx, y + 11), Vector2(cx - 11, y), Vector2(cx, y - 11)]), c, 2.2, true)
		draw_polyline(PackedVector2Array([Vector2(cx, y - 5), Vector2(cx + 5, y), Vector2(cx, y + 5), Vector2(cx - 5, y), Vector2(cx, y - 5)]), Color(UIKit.SKY, 0.9), 1.8, true)
