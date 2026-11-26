class_name SettingsPanel
extends Control
## "Ayarlar": oyun menüsünün bir sayfası (açılış ekranında ve oyunda), Tanhu 1'deki gibi. Bölümler
## soldaki kenar çubuğundadır: Oyun (kamera, ipuçları ve Önsöz), Dil (yalnızca Türkçe), Görüntü (pencere
## ya da tam ekran, çözünürlük, dikey eşitleme, boyalı görünüm, arayüz ölçeği) ve Ses (ana ses, müzik,
## seslendirme, efektler, ortam; audio.md §1); sağda seçilen bölüm durur. Yukarı / aşağı kenar çubuğunda
## gezer, sağ bölümün içine girer, Z / C bölüm değiştirir. Her değişiklik hemen uygulanır; sayfa kapanınca
## kaydedilir.

signal closed

## [başlık, alt yazı, simge]
const SECTIONS := [
	["Oyun", "Kamera, eğim, dönüş hızı, tuş ipuçları ve Önsöz", "gear"],
	["Dil", "Arayüzün dili", "speech"],
	["Görüntü", "Pencere ya da tam ekran, çözünürlük, dikey eşitleme ve arayüz ölçeği", "monitor"],
	["Ses", "Ana ses, müzik, seslendirme, efektler ve ortam", "speaker"],
]
const TITLE := "AYARLAR"
## Bölümün yüksekliği: Görüntü'nün satırları (ekran, çözünürlük ve notu, dikey eşitleme, boyalı görünüm, arayüz ölçeği, not) sığar.
const PAGE_H := 620.0
## Ayarların betiği (autoload'un sınıf adı yok): arayüz ölçeğinin aralığı ve adımı (UI_SCALE_MIN, UI_SCALE_MAX, UI_SCALE_STEP) ve yedek düğüm.
const SETTINGS_SCRIPT := preload("res://scripts/settings/game_settings.gd")
const ON_OFF := [[true, "Açık"], [false, "Kapalı"]]
## Önsöz satırı (K36): kapalı ilk yeni oyunda oynar, sonra atlanır; açık her yeni oyunda oynar.
const PROLOGUE_OPTIONS := [[true, "Her yeni oyunda"], [false, "İlk yeni oyunda"]]
## «Ters sürükleme» satırı: iki ayarı (camera_invert_x, camera_invert_y) tek satırda seçer.
const INVERT_OPTIONS := [["none", "Yok"], ["x", "Yatay"], ["y", "Dikey"], ["xy", "İkisi"]]
## Ses bölümünün kaydırıcıları, sırayla (audio.md §1: Ana ses, Müzik, Seslendirme, Efektler, Ortam).
const SOUND_ROWS := [
	["master_volume", "Ana ses"],
	["music_volume", "Müzik"],
	["voice_volume", "Seslendirme"],
	["sfx_volume", "Efektler"],
	["ambience_volume", "Ortam sesi"],
]

## Oyun menüsü her sayfasına koyar (Tanhu 1 ile aynı).
var embedded := true
## Değiştirilen ayarlar (GameSettings düğümü). Boşsa autoload kullanılır.
var settings: Node

static var _last_section := 0

var _section := 0
var _side: Array = []               # SideButton
var _pages: Array[VBoxContainer] = []
var _first: Array = []              # her bölümün ilk denetimi
var _rows: VBoxContainer
var _head: Label
var _head_sub: Label
var _panel: Control
var _mode_buttons: Dictionary = {}
var _res_pick: Dropdown
var _res_note: Label
var _last_buttons: Dictionary = {}
## Eğim payının yanındaki değer («+4°»).
var _bias_label: Label
## Arayüz ölçeğinin yanındaki değer («%100») ve fareyle sürüklenirken (bırakınca uygulanır) true.
var _ui_scale_label: Label
var _ui_scale_held := false
## Ayar adı → o satırın denetimi (testler için: Button grubu ya da HSlider).
var _controls: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	process_mode = Node.PROCESS_MODE_ALWAYS
	if settings == null:
		settings = UIKit.settings_node()
	if settings == null:
		settings = preload("res://scripts/settings/game_settings.gd").new()
		settings.persist = false
		add_child(settings)
	_build()


func _build() -> void:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 0)
	_panel = OrnateFrame.wrap(hb, 34.0)
	add_child(_panel)

	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(300, PAGE_H + 100.0)
	side.add_theme_constant_override("separation", 8)
	hb.add_child(side)
	var cap := UIKit.label(TITLE, 22, "Cinzel", 700, Color(UIKit.GOLD, 0.8), 6)
	cap.custom_minimum_size = Vector2(0, 54)
	cap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	side.add_child(cap)
	_side.clear()
	for i in SECTIONS.size():
		var b := SideButton.new(str(SECTIONS[i][0]), str(SECTIONS[i][2]))
		b.focus_entered.connect(func() -> void: _show(i))
		b.pressed.connect(func() -> void:
			_show(i)
			_focus_first())
		# sağ her zaman bölümün içine, ilk denetimine girer
		b.gui_input.connect(func(e: InputEvent) -> void:
			if e.is_action_pressed(&"ui_right"):
				b.accept_event()
				_show(i)
				_focus_first())
		side.add_child(b)
		_side.append(b)

	var rule := VRule.new()
	rule.custom_minimum_size = Vector2(40, PAGE_H + 100.0)
	hb.add_child(rule)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(1000, PAGE_H + 100.0)
	right.add_theme_constant_override("separation", 6)
	hb.add_child(right)
	_head = UIKit.label("", 32, "Cinzel", 700, UIKit.GOLD, 4)
	right.add_child(_head)
	_head_sub = UIKit.label("", 20, "Alegreya-Italic", 400, UIKit.TEXT_DIM)
	right.add_child(_head_sub)
	var div := SaveLoadPanel.Divider.new()
	div.custom_minimum_size = Vector2(0, 26)
	right.add_child(div)
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(1000, PAGE_H)
	right.add_child(holder)
	_pages.clear()
	_first.clear()
	for i in SECTIONS.size():
		# Bölüm sayfaya sığmazsa (Oyun: kamera satırlarıyla) kaydırılır; odaktaki satır hep görünür kalır (follow_focus).
		var scroll := ScrollContainer.new()
		scroll.size = Vector2(1000, PAGE_H)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.follow_focus = true
		_style_scroll(scroll)
		holder.add_child(scroll)
		var page := VBoxContainer.new()
		page.add_theme_constant_override("separation", 14)
		page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(page)
		_pages.append(page)
	_build_game_page()
	_build_lang_page()
	_build_display_page()
	_build_sound_page()
	_show(clampi(_last_section, 0, SECTIONS.size() - 1))
	_wire_focus()
	UIKit.center_in_parent(_panel)
	await get_tree().process_frame
	if is_instance_valid(self) and _section < _side.size():
		(_side[_section] as Control).grab_focus()


## Bir bölümün ilk sütunundan sola basmak o bölümün kenar çubuğundaki adına döner (yanındaki
## başka bir bölüme değil; yoksa oyuncunun altından bölüm değişirdi).
func _wire_focus() -> void:
	for i in _pages.size():
		for row in _pages[i].get_children():
			if not row is HBoxContainer:
				continue
			for c in row.get_children():
				if c is Control and (c as Control).focus_mode != Control.FOCUS_NONE:
					(c as Control).focus_neighbor_left = (c as Control).get_path_to(_side[i])
					break


## Açık bölüm (0 Oyun, 1 Dil, 2 Görüntü, 3 Ses).
func get_section() -> int:
	return _section


## Bir ayarın satırdaki denetimi: seçenekli satırda {değer: Button}, kaydırıcıda HSlider.
func get_control(key: String) -> Variant:
	return _controls.get(key)


# --- Bölümler ---------------------------------------------------------------------

func _build_game_page() -> void:
	_rows = _pages[0]
	_first.append(_slider_row("camera_speed", "Kamera dönüş hızı", float(settings.camera_speed), func(v: float) -> void:
		settings.camera_speed = v
		settings.apply()))
	_slider_row("mouse_sensitivity", "Fare hassasiyeti", float(settings.mouse_sensitivity), func(v: float) -> void:
		settings.mouse_sensitivity = v
		settings.apply())
	_choice_row("camera_follow", "Kamera takibi", [["off", "Kapalı"], ["soft", "Yumuşak"], ["normal", "Normal"], ["tight", "Sıkı"]], settings.camera_follow, func(v: Variant) -> void:
		settings.camera_follow = v
		settings.apply())
	_choice_row("camera_fov", "Görüş açısı", [["narrow", "Dar"], ["normal", "Normal"], ["wide", "Geniş"]], settings.camera_fov, func(v: Variant) -> void:
		settings.camera_fov = v
		settings.apply())
	# Eğim payı (godot.md §5.6; −3..+12°, k98-recalc): oyuncunun seçtiği varsayılan kare; `/` onu silmez.
	var bias_range := Vector3(float(SETTINGS_SCRIPT.PITCH_BIAS_MIN), float(SETTINGS_SCRIPT.PITCH_BIAS_MAX), 1.0)
	var bias_slider := _slider_row("camera_pitch_bias", "Eğim payı", float(settings.get("camera_pitch_bias")), func(v: float) -> void:
		settings.set("camera_pitch_bias", v)
		_bias_label.text = degrees_text(v)
		settings.apply(), bias_range)
	_bias_label = UIKit.label(degrees_text(float(settings.get("camera_pitch_bias"))), 22, "Cinzel", 700, UIKit.GOLD)
	_bias_label.custom_minimum_size = Vector2(80, 0)
	_bias_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bias_slider.get_parent().add_child(_bias_label)
	_choice_row("camera_tilt", "Oyunda eğim", ON_OFF, bool(settings.get("camera_tilt")), func(v: Variant) -> void:
		settings.set("camera_tilt", v)
		settings.apply())
	_choice_row("camera_invert", "Ters sürükleme", INVERT_OPTIONS, invert_value(bool(settings.get("camera_invert_x")), bool(settings.get("camera_invert_y"))), func(v: Variant) -> void:
		settings.set("camera_invert_x", str(v).contains("x"))
		settings.set("camera_invert_y", str(v).contains("y"))
		settings.apply(), 160.0)
	_choice_row("show_hints", "Tuş ipuçları", ON_OFF, bool(settings.show_hints), func(v: Variant) -> void:
		settings.show_hints = v
		settings.apply())
	_choice_row("prologue_always", "Önsöz", PROLOGUE_OPTIONS, bool(settings.prologue_always), func(v: Variant) -> void:
		settings.prologue_always = v
		settings.apply(), 250.0)
	_note("Eğim payı varsayılan kareyi yükseltir ya da alçaltır; / kamerayı kuzeye, başlangıç uzaklığına ve bu eğime döndürür. Önsöz her yeni oyunda oynar («İlk yeni oyunda»: bir kez); basılı Esc atlar.")


## Dil: Tanhu şimdilik yalnızca Türkçedir.
func _build_lang_page() -> void:
	_rows = _pages[1]
	_first.append(_choice_row("language", "Arayüz dili", [["tr", "Türkçe"]], settings.language, func(v: Variant) -> void:
		settings.language = v
		settings.apply()))
	_note("Tanhu şimdilik yalnızca Türkçe oynanır; bütün yazılar Türkçedir.")


func _build_display_page() -> void:
	_rows = _pages[2]
	if not OS.has_feature("mobile") and not OS.has_feature("web"):
		_first.append(_choice_row("fullscreen", "Ekran", [[false, "Pencere"], [true, "Tam ekran"]], bool(settings.fullscreen), func(v: Variant) -> void:
			settings.fullscreen = v
			settings.apply_display()
			settings.apply()
			_sync_display()))
		_mode_buttons = _last_buttons
		var h := _row("Çözünürlük")
		_res_pick = Dropdown.new(self)
		_style_button(_res_pick)
		var list: Array = settings.resolutions()
		for i in list.size():
			var r: Vector2i = list[i]["size"]
			var label := str(list[i]["name"]) if r == Vector2i.ZERO else "%d × %d" % [r.x, r.y]
			if r != Vector2i.ZERO and str(list[i]["name"]) != "":
				label += "   ·   " + str(list[i]["name"])
			if not list[i]["fits"]:
				label += "   (ekrana sığmaz)"
			_res_pick.add_item(label, not list[i]["fits"], r)
		_res_pick.item_selected.connect(func(i: int) -> void:
			# Pencere o boyuta geçer; tam ekranda boyut arayüzü belirler (yüksek çözünürlükte daha küçük ve ince).
			settings.resolution = _res_pick.get_item_metadata(i)
			settings.apply_display()
			settings.apply()
			MenuStyle.play_ui(self, &"click")
			_sync_display())
		h.add_child(_res_pick)
		_controls["resolution"] = _res_pick
		_res_note = _note("")
		_choice_row("vsync", "Dikey eşitleme", ON_OFF, bool(settings.vsync), func(v: Variant) -> void:
			settings.vsync = v
			settings.apply_display()
			settings.apply())
	var first_other := _choice_row("painterly", "Boyalı görünüm", ON_OFF, bool(settings.painterly), func(v: Variant) -> void:
		settings.painterly = v
		settings.apply())
	_ui_scale_row()
	if _first.size() < 3:
		_first.append(first_other)
	_note("Arayüz ölçeği menüleri, kitapları ve oyun içindeki göstergeleri (portre, mini harita, görev kartı, yuvalar, düğmeler) birlikte büyütür ya da küçültür; ← → beşer beşer değiştirir. Göstergeler menülerin %80'i boyundadır; menüler ekrana sığdığı kadar büyür.")
	_sync_display()


## Ses: SOUND_ROWS sırasıyla birer kaydırıcı; her biri kendi veri yolunu sürer (GameSettings.apply).
## Efektler kaydırıcısı oynatılırken kısa bir arayüz sesi çalar (düzey kulakla seçilsin).
func _build_sound_page() -> void:
	_rows = _pages[3]
	for row: Array in SOUND_ROWS:
		var key: String = row[0]
		var slider := _slider_row(key, str(row[1]), float(settings.get(key)), func(v: float) -> void:
			settings.set(key, v)
			settings.apply()
			if key == "sfx_volume":
				MenuStyle.play_ui(self, &"hover"))
		if _first.size() < 4:
			_first.append(slider)


## Pencere / tam ekran düğmeleri, boyut listesi ve not birbirini izler.
func _sync_display() -> void:
	for k in _mode_buttons:
		(_mode_buttons[k] as Button).set_pressed_no_signal(k == bool(settings.fullscreen))
	if _res_pick:
		for i in _res_pick.items.size():
			if _res_pick.get_item_metadata(i) == settings.resolution:
				_res_pick.select(i)
	if _res_note:
		_res_note.text = resolution_note(bool(settings.fullscreen), settings.resolution, settings.screen_pixels())


## Derece yazısı: «+4°», «0°», «−3°» (saf).
static func degrees_text(v: float) -> String:
	var n := roundi(v)
	if n > 0:
		return "+%d°" % n
	if n < 0:
		return "−%d°" % absi(n)
	return "0°"


## Yüzde yazısı: «%100», «%85» (saf; arayüz ölçeğinin yanındaki değer).
static func percent_text(v: float) -> String:
	return "%%%d" % roundi(v * 100.0)


## Ters sürükleme satırının değeri (saf): "none", "x", "y" ya da "xy".
static func invert_value(x: bool, y: bool) -> String:
	if x and y:
		return "xy"
	if x:
		return "x"
	return "y" if y else "none"


## İki seçenek değeri aynı mı? Sayılar yaklaşık karşılaştırılır (ör. arayüz ölçeği 0,9).
static func same_value(a: Variant, b: Variant) -> bool:
	if (a is float or a is int) and (b is float or b is int) and not (a is bool or b is bool):
		return is_equal_approx(float(a), float(b))
	return typeof(a) == typeof(b) and a == b


## Çözünürlüğün altındaki not (saf fonksiyon).
static func resolution_note(full: bool, res: Vector2i, screen: Vector2i) -> String:
	if full:
		return "Tam ekranda oyun ekranın tamamını, kendi keskinliğinde kaplar (%d × %d). Çözünürlük arayüzün boyutunu belirler: 2K'da menüler daha küçük ve ince görünür." % [screen.x, screen.y]
	if res == Vector2i.ZERO:
		return "Pencere ekranın kullanılabilir alanını kaplar. Belli bir boyut seçilirse o boyutta, gerçek pikselle açılır."
	return "Pencere seçilen çözünürlükte, gerçek pikselle açılır. Çözünürlük yükseldikçe arayüz küçülür."


func _show(i: int) -> void:
	_section = i
	_last_section = i
	for k in _pages.size():
		(_pages[k].get_parent() as Control).visible = k == i
		_side[k].selected = k == i
		_side[k].queue_redraw()
	_head.text = str(SECTIONS[i][0])
	_head_sub.text = str(SECTIONS[i][1])


## Bölümü açar ve kenar çubuğundaki adını seçer (Z / C ve testler).
func show_section(i: int) -> void:
	_show(posmod(i, SECTIONS.size()))
	if is_inside_tree() and _section < _side.size():
		(_side[_section] as Control).grab_focus()


func _focus_first() -> void:
	if _section < _first.size() and _first[_section]:
		(_first[_section] as Control).grab_focus()


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and (e.physical_keycode == KEY_Z or e.physical_keycode == KEY_C):
		get_viewport().set_input_as_handled()
		_show(posmod(_section + (-1 if e.physical_keycode == KEY_Z else 1), SECTIONS.size()))
		(_side[_section] as Control).grab_focus()
		MenuStyle.play_ui(self, &"hover")


func _exit_tree() -> void:
	if settings and is_instance_valid(settings):
		settings.save_settings()


# --- Parçalar ---------------------------------------------------------------------------

func _row(label_text: String) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	var l := UIKit.label(label_text, 28, "Alegreya", 500)
	l.custom_minimum_size = Vector2(270, 0)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
	_rows.add_child(h)
	return h


func _note(text: String) -> Label:
	var n := UIKit.label(text, 20, "Alegreya-Italic", 400, UIKit.TEXT_DIM)
	n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	n.custom_minimum_size = Vector2(960, 0)
	_rows.add_child(n)
	return n


## Seçenek düğmelerinden bir satır; seçenek = [değer, yazı].
func _choice_row(key: String, label_text: String, options: Array, current: Variant, on_pick: Callable, width := 190.0) -> Control:
	var h := _row(label_text)
	var group := ButtonGroup.new()
	var first: Control = null
	_last_buttons = {}
	for opt in options:
		var b := Button.new()
		b.toggle_mode = true
		b.button_group = group
		b.text = str(opt[1])
		b.focus_mode = Control.FOCUS_ALL
		b.custom_minimum_size = Vector2(width, 50)
		b.button_pressed = same_value(opt[0], current)
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.add_theme_font_override("font", UIKit.font("Alegreya", 600))
		b.add_theme_font_size_override("font_size", 25)
		_style_button(b)
		var value: Variant = opt[0]
		b.toggled.connect(func(on: bool) -> void:
			if on:
				MenuStyle.play_ui(b, &"click")
				on_pick.call(value))
		b.focus_entered.connect(func() -> void:
			if KnotButton.navigating():
				MenuStyle.play_ui(b, &"hover"))
		b.mouse_entered.connect(func() -> void:
			if b.focus_mode != Control.FOCUS_NONE:
				b.grab_focus())
		h.add_child(b)
		_last_buttons[value] = b
		if first == null:
			first = b
	_controls[key] = _last_buttons
	return first


## Bölümün kaydırma çubuğu: ince, kitabın altın tonunda.
func _style_scroll(scroll: ScrollContainer) -> void:
	var bar := scroll.get_v_scroll_bar()
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.12, 0.12, 0.14, 0.55)
	track.set_corner_radius_all(3)
	track.content_margin_left = 3
	track.content_margin_right = 3
	var grab := StyleBoxFlat.new()
	grab.bg_color = UIKit.GOLD_DIM
	grab.set_corner_radius_all(3)
	var hot := grab.duplicate() as StyleBoxFlat
	hot.bg_color = UIKit.GOLD
	bar.add_theme_stylebox_override("scroll", track)
	bar.add_theme_stylebox_override("grabber", grab)
	bar.add_theme_stylebox_override("grabber_highlight", hot)
	bar.add_theme_stylebox_override("grabber_pressed", hot)


func _style_button(b: Control) -> void:
	b.add_theme_stylebox_override("normal", UIKit.panel_style(Color(0.06, 0.07, 0.09, 0.9), Color(0.4, 0.35, 0.26, 0.7), 1, 3, Color(0, 0, 0, 0.2), 4))
	b.add_theme_stylebox_override("hover", UIKit.panel_style(Color(0.08, 0.1, 0.13, 0.95), UIKit.SKY_DEEP, 2, 3, Color(UIKit.SKY, 0.25), 8))
	b.add_theme_stylebox_override("focus", UIKit.panel_style(Color(0.08, 0.1, 0.13, 0.95), UIKit.SKY, 2, 3, Color(UIKit.SKY, 0.35), 10))
	b.add_theme_stylebox_override("pressed", UIKit.panel_style(Color(0.12, 0.09, 0.05, 0.95), UIKit.GOLD, 2, 3, Color(UIKit.GOLD, 0.25), 8))
	b.add_theme_stylebox_override("hover_pressed", UIKit.panel_style(Color(0.12, 0.09, 0.05, 0.95), UIKit.GOLD, 2, 3, Color(UIKit.GOLD, 0.3), 10))
	b.add_theme_color_override("font_pressed_color", UIKit.GOLD)
	b.add_theme_color_override("font_hover_pressed_color", UIKit.GOLD)


## «Arayüz ölçeği» satırı (K104): kitabın dilinde kaydırıcı (BookSlider, %50–%150, beşer beşer; %100 işaretli) ve yanında yüzde. Menüler,
## kitaplar ve HUD bu tek ayardan ölçeklenir (HUD menülerin 0,8 katı; HudKit.HUD_SCALE). Klavye ve oyun kolu (← →, sol çubuk) ve tekerlek
## adım adım değiştirir, hemen uygulanır. Fareyle sürüklerken yazı izler, ölçek bırakınca uygulanır: sayfa da bu ölçekte çizildiği için
## sürüklerken uygulansa kaydırıcı farenin altından kayardı.
func _ui_scale_row() -> HSlider:
	var h := _row("Arayüz ölçeği")
	var s := BookSlider.new()
	s.min_value = SETTINGS_SCRIPT.UI_SCALE_MIN
	s.max_value = SETTINGS_SCRIPT.UI_SCALE_MAX
	s.step = SETTINGS_SCRIPT.UI_SCALE_STEP
	s.marks = [1.0]
	s.value = float(settings.ui_scale)
	s.focus_mode = Control.FOCUS_ALL
	s.custom_minimum_size = Vector2(560, 40)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(s)
	_ui_scale_label = UIKit.label(percent_text(s.value), 22, "Cinzel", 700, UIKit.GOLD)
	_ui_scale_label.custom_minimum_size = Vector2(80, 0)
	_ui_scale_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(_ui_scale_label)
	# Basış gui_input sinyaliyle kaydırıcının kendi işleminden önce görülür: tıklamanın atlattığı değer de bırakınca uygulanır.
	s.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			if e.is_pressed():
				_ui_scale_held = true
			else:
				_release_ui_scale.call_deferred(s))
	s.drag_started.connect(func() -> void: _ui_scale_held = true)
	s.drag_ended.connect(func(_changed: bool) -> void: _release_ui_scale(s))
	s.value_changed.connect(func(v: float) -> void:
		_ui_scale_label.text = percent_text(v)
		if not _ui_scale_held:
			_set_ui_scale(v, s))
	s.focus_entered.connect(func() -> void:
		if KnotButton.navigating():
			MenuStyle.play_ui(s, &"hover"))
	s.mouse_entered.connect(func() -> void: s.grab_focus())
	_controls["ui_scale"] = s
	return s


## Fare bırakıldı: kaydırıcının değeri uygulanır (iki yoldan gelebilir: drag_ended ve gui_input; ikincisi bir şey yapmaz).
func _release_ui_scale(s: HSlider) -> void:
	if not _ui_scale_held:
		return
	_ui_scale_held = false
	if is_instance_valid(s):
		_set_ui_scale(s.value, s)


## Arayüz ölçeğini yazar ve uygular (GameSettings.changed: kitap, sayfalar ve HUD yeniden ölçeklenir). Klavyeyle değiştirilirken sayfa
## büyüyüp küçülünce duran farenin altına giren denetim odağı almasın (sayfanın denetimleri fareyle odak alır): kaydırıcı odakta kalır.
func _set_ui_scale(v: float, s: HSlider) -> void:
	var snapped: float = SETTINGS_SCRIPT.snap_ui_scale(v)
	if is_equal_approx(float(settings.ui_scale), snapped):
		return
	settings.ui_scale = snapped
	settings.apply()
	if s.has_focus():
		_keep_focus(s)


func _keep_focus(c: Control) -> void:
	for i in 2:
		await get_tree().process_frame
		if not is_instance_valid(c) or not c.is_inside_tree():
			return
		if not c.has_focus():
			c.grab_focus()


## Kaydırıcılı satır; value_range = (en az, en çok, adım), varsayılan 0..1, 0,05. Kaydırıcı kitabın dilindedir (BookSlider; K104'ün
## arayüz ölçeğiyle aynı: sayfanın bütün kaydırıcıları tek biçimde).
func _slider_row(key: String, label_text: String, value: float, on_change: Callable, value_range := Vector3(0.0, 1.0, 0.05)) -> Control:
	var h := _row(label_text)
	var s := BookSlider.new()
	s.min_value = value_range.x
	s.max_value = value_range.y
	s.step = value_range.z
	s.value = value
	s.focus_mode = Control.FOCUS_ALL
	s.custom_minimum_size = Vector2(560, 40)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	s.value_changed.connect(func(v: float) -> void: on_change.call(v))
	s.mouse_entered.connect(func() -> void: s.grab_focus())
	h.add_child(s)
	_controls[key] = s
	return s


## Kitabın üst menüsünün dilinde kaydırıcı (GameMenu.Strip, TabButton): ince altın çizgi, dolan kısmı parlak altın; tutamak koyu taş bir
## elmas, altın kenarlı, ortasında küçük elmas (şeridin ortasındaki süs gibi); odakta ya da fare üstündeyken kenarı ve içi gök mavisi yanar.
## marks: çizginin üstünde küçük elmasla işaretlenen değerler (arayüz ölçeğinde %100). Godot'nun kendi çizimi boş bırakılır; boş tutamak
## dokusunun genişliği (GRAB) farenin değere eşlenmesini belirler, elmas o tutamağın yerine çizilir (grab_x).
class BookSlider extends HSlider:
	const GRAB := 30.0
	## Bütün kaydırıcıların ortak boş tutamağı (saydam, GRAB × GRAB).
	static var _blank: Texture2D
	var marks: Array = []
	var _hover := false

	func _init() -> void:
		var empty := StyleBoxEmpty.new()
		for st in ["slider", "grabber_area", "grabber_area_highlight"]:
			add_theme_stylebox_override(st, empty)
		if _blank == null:
			_blank = ImageTexture.create_from_image(Image.create(int(GRAB), int(GRAB), false, Image.FORMAT_RGBA8))
		for icon in ["grabber", "grabber_highlight", "grabber_disabled", "tick"]:
			add_theme_icon_override(icon, _blank)
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		focus_entered.connect(queue_redraw)
		focus_exited.connect(queue_redraw)
		mouse_entered.connect(func() -> void:
			_hover = true
			queue_redraw())
		mouse_exited.connect(func() -> void:
			_hover = false
			queue_redraw())
		value_changed.connect(func(_v: float) -> void: queue_redraw())

	## Değerin çizgideki x'i: Godot'nun tutamağının merkezi (yarım tutamak payından sonra oranla).
	func grab_x(v: float) -> float:
		var span := maxf(max_value - min_value, 0.0001)
		return GRAB * 0.5 + clampf((v - min_value) / span, 0.0, 1.0) * maxf(size.x - GRAB, 0.0)

	func _draw() -> void:
		var y := size.y * 0.5
		var x0 := grab_x(min_value)
		var x1 := grab_x(max_value)
		var xv := grab_x(value)
		var hot := has_focus() or _hover
		draw_line(Vector2(x0, y), Vector2(x1, y), Color(UIKit.GOLD, 0.22), 2.0, true)
		draw_line(Vector2(x0, y), Vector2(xv, y), Color(UIKit.GOLD, 0.8), 3.0, true)
		for x: float in [x0, x1]:
			_diamond(Vector2(x, y), 3.5, Color(UIKit.GOLD, 0.5))
		for m: Variant in marks:
			_diamond(Vector2(grab_x(float(m)), y), 4.5, UIKit.GOLD if value >= float(m) - 0.0001 else UIKit.GOLD_DIM)
		var c := Vector2(xv, y)
		if hot:
			draw_circle(c, 21.0, Color(UIKit.SKY, 0.12))
		var r := 12.0
		var dia := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
		draw_colored_polygon(dia, Color(0.03, 0.04, 0.06, 0.95))
		dia.append(dia[0])
		draw_polyline(dia, UIKit.SKY if hot else UIKit.GOLD, 2.0, true)
		_diamond(c, 4.5, UIKit.SKY if hot else UIKit.GOLD)

	func _diamond(c: Vector2, d: float, col: Color) -> void:
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -d), c + Vector2(d, 0), c + Vector2(0, d), c + Vector2(-d, 0)]), col)


## Kenar çubuğundaki bölüm: simgesi, adı, seçiliyken altın bir çubuk.
class SideButton extends Button:
	var glyph := ""
	var label := ""
	var selected := false

	func _init(text_label: String, g: String) -> void:
		label = text_label
		glyph = g
		custom_minimum_size = Vector2(290, 64)
		focus_mode = Control.FOCUS_ALL
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var empty := StyleBoxEmpty.new()
		for st in ["normal", "hover", "focus", "pressed", "disabled", "hover_pressed"]:
			add_theme_stylebox_override(st, empty)
		focus_entered.connect(func() -> void:
			MenuStyle.play_ui(self, &"hover")
			queue_redraw())
		focus_exited.connect(queue_redraw)
		mouse_entered.connect(grab_focus)

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
		var col := UIKit.GOLD if selected else (UIKit.SKY if hot else UIKit.TEXT_DIM)
		GameMenu.draw_glyph(self, glyph, Vector2(36, size.y * 0.5), 11.0, col)
		var f := UIKit.font("Cinzel", 700, 3)
		draw_string(f, Vector2(66, size.y * 0.5 + 8.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, col)


## Kenar çubuğu ile bölüm arasındaki ince altın çizgi.
class VRule extends Control:
	func _draw() -> void:
		var x := size.x * 0.5
		draw_line(Vector2(x, 10), Vector2(x, size.y - 10), Color(UIKit.GOLD, 0.35), 1.0)
		var c := Vector2(x, size.y * 0.5)
		var d := 6.0
		draw_colored_polygon(PackedVector2Array([c + Vector2(0, -d), c + Vector2(d, 0), c + Vector2(0, d), c + Vector2(-d, 0)]), UIKit.GOLD)


## Sayfanın içinde çizilen açılır liste (ayrı bir pencere değil): her zaman ayarların üstünde, opak ve
## temaya uygun açılır. Dışına tıklamak ya da Esc kapatır.
class Dropdown extends Button:
	signal item_selected(index: int)

	var items: Array = []           # {text, disabled, meta}
	var selected := -1
	var _host: Control
	var _catcher: Control
	var _list: PanelContainer

	func _init(host: Control) -> void:
		_host = host
		custom_minimum_size = Vector2(520, 50)
		focus_mode = Control.FOCUS_ALL
		alignment = HORIZONTAL_ALIGNMENT_LEFT
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		add_theme_font_override("font", UIKit.font("Alegreya", 600))
		add_theme_font_size_override("font_size", 25)
		pressed.connect(func() -> void:
			if is_open():
				close()
			else:
				open_list())
		mouse_entered.connect(func() -> void: grab_focus())

	func add_item(text_label: String, disabled_item: bool, meta: Variant) -> void:
		items.append({"text": text_label, "disabled": disabled_item, "meta": meta})

	func select(i: int) -> void:
		selected = i
		text = "   " + str(items[i]["text"])
		queue_redraw()

	func get_item_metadata(i: int) -> Variant:
		return items[i]["meta"]

	func is_open() -> bool:
		return _list != null and is_instance_valid(_list)

	func _draw() -> void:
		# sağdaki ok
		var c := Vector2(size.x - 26.0, size.y * 0.5)
		var col := UIKit.SKY if has_focus() or is_hovered() else UIKit.GOLD
		var d := 7.0
		var pts := PackedVector2Array([c + Vector2(-d, -d * 0.5), c + Vector2(0, d * 0.5), c + Vector2(d, -d * 0.5)]) if not is_open() else PackedVector2Array([c + Vector2(-d, d * 0.5), c + Vector2(0, -d * 0.5), c + Vector2(d, d * 0.5)])
		draw_polyline(pts, col, 2.0, true)

	func open_list() -> void:
		_catcher = Catcher.new()
		_catcher.owner_dropdown = self
		_host.add_child(_catcher)
		_list = PanelContainer.new()
		# listenin kendi payına tıklamak listede kalır
		_list.mouse_filter = Control.MOUSE_FILTER_STOP
		_list.add_theme_stylebox_override("panel", UIKit.panel_style(Color(0.03, 0.04, 0.06, 1.0), UIKit.GOLD_DIM, 2, 3, Color(0, 0, 0, 0.6), 16))
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 4)
		_list.add_child(vb)
		var first: Button = null
		var live: Array[Button] = []
		for i in items.size():
			var b := Button.new()
			b.text = str(items[i]["text"])
			b.disabled = bool(items[i]["disabled"])
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			# sığmayan boyut seçilemez; oklar onu atlar
			b.focus_mode = Control.FOCUS_NONE if b.disabled else Control.FOCUS_ALL
			b.custom_minimum_size = Vector2(size.x - 56.0, 46)
			b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			b.add_theme_font_override("font", UIKit.font("Alegreya", 500))
			b.add_theme_font_size_override("font_size", 24)
			b.add_theme_color_override("font_color", UIKit.GOLD if i == selected else UIKit.TEXT)
			b.add_theme_color_override("font_hover_color", UIKit.SKY)
			b.add_theme_color_override("font_focus_color", UIKit.SKY)
			b.add_theme_color_override("font_disabled_color", Color(UIKit.TEXT_DIM, 0.45))
			var empty := StyleBoxEmpty.new()
			empty.content_margin_left = 12
			b.add_theme_stylebox_override("normal", empty)
			b.add_theme_stylebox_override("disabled", empty)
			var hl := UIKit.panel_style(Color(0.08, 0.1, 0.14, 1.0), UIKit.SKY, 1, 2, Color(0, 0, 0, 0), 0)
			hl.content_margin_left = 12
			b.add_theme_stylebox_override("hover", hl)
			b.add_theme_stylebox_override("focus", hl)
			b.add_theme_stylebox_override("pressed", hl)
			b.mouse_entered.connect(func() -> void:
				if not b.disabled:
					b.grab_focus())
			b.pressed.connect(func() -> void:
				select(i)
				item_selected.emit(i)
				close())
			vb.add_child(b)
			if not b.disabled:
				live.append(b)
				if i == selected or first == null:
					first = b
		_host.add_child(_list)
		# oklar listede gezer ve listede kalır
		for b in live:
			b.focus_neighbor_left = b.get_path()
			b.focus_neighbor_right = b.get_path()
		if not live.is_empty():
			live[0].focus_neighbor_top = live[0].get_path()
			live[-1].focus_neighbor_bottom = live[-1].get_path()
		# düğmenin altında, onun ölçeğinde (kitabın arayüz ölçeği); ekran önce biterse üstünde
		var gk := get_global_transform().get_scale()
		_list.scale = gk / _host.get_global_transform().get_scale()
		_list.custom_minimum_size.x = size.x
		var h := _list.get_combined_minimum_size().y * gk.y
		var below := global_position + Vector2(0, (size.y + 4.0) * gk.y)
		if below.y + h > get_viewport_rect().size.y - 8.0:
			below = global_position - Vector2(0, h + 4.0 * gk.y)
		_list.global_position = below
		queue_redraw()
		if first:
			first.grab_focus()

	func close() -> void:
		_dismiss()
		queue_redraw()
		if is_inside_tree():
			grab_focus()

	func _dismiss() -> void:
		if is_instance_valid(_list):
			_list.queue_free()
		if is_instance_valid(_catcher):
			_catcher.queue_free()
		_list = null
		_catcher = null

	func _exit_tree() -> void:
		# sayfa açık bir listenin altından gitti: liste de gider
		_dismiss()


## Açık bir listenin arkasında: başka bir yere tıklamak ya da Esc listeyi kapatır.
class Catcher extends Control:
	var owner_dropdown: Dropdown

	func _ready() -> void:
		UIKit.full_rect(self)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			accept_event()
			owner_dropdown.close()

	func _input(e: InputEvent) -> void:
		if e.is_action_pressed(&"ui_cancel") or (InputMap.has_action(&"pause") and e.is_action_pressed(&"pause")):
			get_viewport().set_input_as_handled()
			owner_dropdown.close()
			return
		# başka bir tuş (ör. sayfa ya da bölüm çevirmek) önce listeyi kapatır
		if (e is InputEventKey or e is InputEventJoypadButton) and e.is_pressed() and not e.is_echo():
			for a in [&"ui_up", &"ui_down", &"ui_accept"]:
				if e.is_action(a):
					return
			owner_dropdown.close()
