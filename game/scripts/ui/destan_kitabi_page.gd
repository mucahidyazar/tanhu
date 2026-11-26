class_name DestanKitabiPage
extends Control
## Destan Kitabı'nın bir bölümü (Destan ya da Taşlar; Kişiler ve «Gök ve Yer» ansiklopedi düzenindedir,
## EncyclopediaPage), Tanhu 1'in ayarlar sayfası düzeninde:
## solda bölümün adı ve açılmış kayıtların listesi (gruplarıyla), ince altın çizgi, sağda seçilen
## kayıt: başlığı, alt yazısı ve metni. Yukarı / aşağı kayıt seçer (seçilen hemen sağda açılır);
## bölümleri oyun menüsü Q / E ile çevirir, Esc kapatır. Hiçbir kaydı açılmamış bölüm boş sayfa
## yazısını gösterir (Tanhu 2'deki gibi).

var embedded := true
var chapter := "destan"
var flags: Dictionary = {}

var _list: VBoxContainer
var _count: Label
var _title: Label
var _sub: Label
var _text: RichTextLabel
var _buttons: Array[EntryButton] = []
var _entries: Array[Dictionary] = []
var _shown := -1


func _init(p_chapter: String = "destan", p_flags: Dictionary = {}) -> void:
	chapter = p_chapter
	flags = p_flags


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 0)
	var panel := OrnateFrame.wrap(hb, 34.0)
	add_child(panel)
	hb.add_child(_build_left())
	var rule := SettingsPanel.VRule.new()
	rule.custom_minimum_size = Vector2(40, 640)
	hb.add_child(rule)
	hb.add_child(_build_right())
	_fill()
	UIKit.center_in_parent(panel)
	await get_tree().process_frame
	if is_instance_valid(self) and not _buttons.is_empty():
		_buttons[0].grab_focus()


func _build_left() -> Control:
	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(420, 640)
	side.add_theme_constant_override("separation", 6)
	var cap := UIKit.label(DestanKitabi.TITLE.to_upper(), 22, "Cinzel", 700, Color(UIKit.GOLD, 0.8), 6)
	cap.custom_minimum_size = Vector2(0, 40)
	cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	side.add_child(cap)
	_count = UIKit.label("", 19, "Alegreya-Italic", 400, UIKit.TEXT_DIM)
	side.add_child(_count)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(420, 560)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	side.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 4)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	return side


func _build_right() -> Control:
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(880, 640)
	right.add_theme_constant_override("separation", 6)
	_title = UIKit.label("", 34, "Cinzel", 700, UIKit.GOLD, 4)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.custom_minimum_size = Vector2(860, 0)
	right.add_child(_title)
	_sub = UIKit.label("", 21, "Alegreya-Italic", 400, UIKit.SKY)
	_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sub.custom_minimum_size = Vector2(860, 0)
	right.add_child(_sub)
	var div := SaveLoadPanel.Divider.new()
	div.custom_minimum_size = Vector2(0, 26)
	right.add_child(div)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(880, 520)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	_text = UIKit.rich(26, "Alegreya")
	_text.add_theme_color_override("default_color", UIKit.PARCHMENT)
	_text.add_theme_constant_override("line_separation", 10)
	_text.custom_minimum_size = Vector2(840, 0)
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_text)
	return right


## Açık kayıtları listeler; ilkini sağda açar (hiçbiri yoksa boş sayfa yazısı).
func _fill() -> void:
	_entries = DestanKitabi.entries(chapter, flags)
	_count.text = "%s  ·  %d / %d açıldı" % [DestanKitabi.chapter_title(chapter), _entries.size(), DestanKitabi.total(chapter)]
	var group := ""
	for i in _entries.size():
		var e := _entries[i]
		if str(e.get("group", "")) != group:
			group = str(e.get("group", ""))
			if group != "":
				var g := UIKit.label(group.to_upper(), 16, "Cinzel", 700, Color(UIKit.GOLD, 0.75), 3)
				g.custom_minimum_size = Vector2(0, 34)
				g.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
				_list.add_child(g)
		var b := EntryButton.new(str(e["title"]))
		b.focus_entered.connect(show_entry.bind(i))
		b.pressed.connect(show_entry.bind(i))
		_list.add_child(b)
		_buttons.append(b)
	if _entries.is_empty():
		_show_empty()
	else:
		show_entry(0)


## i. kaydı sağda açar.
func show_entry(i: int) -> void:
	if i < 0 or i >= _entries.size():
		return
	_shown = i
	var e := _entries[i]
	_title.text = str(e.get("title", ""))
	_sub.text = str(e.get("sub", ""))
	_sub.visible = _sub.text != ""
	var body := str(e.get("text", ""))
	_text.text = "[i]%s[/i]" % body if chapter == "destan" else body
	for k in _buttons.size():
		_buttons[k].selected = k == i
		_buttons[k].queue_redraw()


func _show_empty() -> void:
	_shown = -1
	_title.text = DestanKitabi.chapter_title(chapter)
	_sub.text = ""
	_sub.visible = false
	_text.text = "[i]%s[/i]" % DestanKitabi.EMPTY_TEXT


## Listelenen kayıtlar (açık olanlar).
func get_entries() -> Array[Dictionary]:
	return _entries


## Sağda açık kaydın sırası (-1 = boş sayfa).
func get_shown_index() -> int:
	return _shown


func get_entry_buttons() -> Array[EntryButton]:
	return _buttons


## Sağdaki başlık ve metin (testler için).
func get_shown_title() -> String:
	return _title.text


func get_shown_text() -> String:
	return _text.text


## Listedeki bir kayıt: adı; seçiliyken altın bir çubuk, odakta gök mavisi kenar (kenar çubuğu gibi).
class EntryButton extends Button:
	var label := ""
	var selected := false

	func _init(text_label: String) -> void:
		label = text_label
		custom_minimum_size = Vector2(400, 50)
		focus_mode = Control.FOCUS_ALL
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var empty := StyleBoxEmpty.new()
		for st in ["normal", "hover", "focus", "pressed", "disabled", "hover_pressed"]:
			add_theme_stylebox_override(st, empty)
		focus_entered.connect(func() -> void:
			if KnotButton.navigating():
				MenuStyle.play_ui(self, &"hover")
			queue_redraw())
		focus_exited.connect(queue_redraw)
		mouse_entered.connect(func() -> void:
			MenuStyle.play_ui(self, &"hover")
			grab_focus())

	func _draw() -> void:
		var hot := has_focus()
		var r := Rect2(Vector2.ZERO, size)
		if selected:
			draw_rect(r, Color(0.12, 0.09, 0.05, 0.85), true)
			draw_rect(Rect2(Vector2.ZERO, Vector2(4, size.y)), UIKit.GOLD, true)
		elif hot:
			draw_rect(r, Color(0.07, 0.09, 0.12, 0.8), true)
		if hot:
			draw_rect(r.grow(-1.0), Color(UIKit.SKY, 0.8), false, 1.5)
		var col := UIKit.GOLD if selected else (UIKit.SKY if hot else UIKit.PARCHMENT)
		var f := UIKit.font("Alegreya", 600)
		draw_string(f, Vector2(22, size.y * 0.5 + 9.0), label, HORIZONTAL_ALIGNMENT_LEFT, size.x - 30.0, 25, col)
