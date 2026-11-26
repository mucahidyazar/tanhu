class_name ControlsPage
extends Control
## "Tuşlar" (Tanhu 1): bütün tuşlar ve oyun kolu düğmeleri, üstteki simgelerle (ya da Z / C) seçilen
## dört görünümde: ne zaman işe yaradığına göre gruplanmış bir liste (yürürken, karakter oluşturmada,
## menüde), her tuşun üstüne işini yazan bir klavye, düğmeleri yanlarına yazılmış bir oyun kolu ve tuş ataması.
## Her şey doğrudan tuş haritasından (InputMap; eylemler InputSetup'tadır) okunur: sayfa yalan söylemez. Tuşun adı
## klavye dizilişinden okunur (key_label: DisplayServer.keyboard_get_label_from_physical; Türkçe Q'da / tuşu «.» görünür).
## Oyun menüsünün bir sayfasıdır.
##
## Atama (K39, godot.md §5.6): her eylem satırında «Değiştir» sonraki tuşu ya da oyun kolu düğmesini dinler (Esc vazgeçer); olay aynı
## bağlamda başka bir eyleme bağlıysa «Şuna da bağlı: {eylem}» sorulur, evet denirse o eylem bu satırın eski tuşunu alır (eski eylem
## boş kalmaz; InputSetup.rebind). «Varsayılana dön» bütün atamayı siler. Her değişiklik ayarın [input] bölümüne hemen yazılır
## (GameSettings.input_bindings, save_settings). Esc ile oyun menüsü (pause, undo) atanmaz.

## [başlık, [[yazı, eylem ya da "" (özel satır), ek tuşlar, ek oyun kolu düğmeleri, (isteğe bağlı) eylem dizisi], ...]]
## Eylem dizisi olan satırın tuşları o eylemlerin birincil tuşlarından («W A S D»), sonra ikincillerinden («↑ ← ↓ →») kurulur.
const GROUPS := [
	["YÜRÜRKEN", [
		["Yürü", "", [], [], [&"move_forward", &"move_left", &"move_back", &"move_right"]],
		["Koş (basılı tut)", "sprint", [], []],
		["Kamerayı döndür", "", [], [], [&"camera_left", &"camera_right"]],
		["Kamerayı sürükle", "", ["Sağ tık", "Orta tuş"], []],
		["Kamerayı eğ", "", ["Orta tuş ↕", "Alt + tekerlek"], [], [&"camera_pitch_up", &"camera_pitch_down"]],
		["Yakınlaş / uzaklaş", "", ["Tekerlek"], [], [&"camera_zoom_in", &"camera_zoom_out"]],
		["Varsayılan kamera", "camera_reset", [], []],
		["Kuzeye hizala", "", ["Orta tık"], []],
		["Zıpla", "jump", [], []],
		["Envanter", "inventory", [], []],
		["Görevler", "journal", [], []],
		["Harita", "map", [], []],
		["Bekle · uyu · dinlen", "wait", [], []],
		["Yükü bırak (basılı tut)", "drop_load", [], []],
		["Oyun menüsü", "pause", [], []],
	]],
	["KARAKTER OLUŞTURMA", [
		["Satır seç", "", ["W", "S", "↑", "↓"], []],
		["Değeri değiştir", "", ["A", "D", "←", "→"], []],
		["Onayla", "accept", [], []],
		["Geri al", "undo", [], []],
		["Karakteri döndür", "", ["Sürükle"], []],
		["Yakın plan", "", ["Tab", "Tekerlek"], []],
	]],
	["MENÜ", [
		["Seç", "ui_accept", [], []],
		["Geri / kapat", "ui_cancel", [], []],
		["Butonlarda gezin", "", ["↑ ↓ ← →"], ["✣", "L"]],
		["Menüde sayfa çevir", "", ["Q", "E"], ["LB", "RB"]],
		["Bölüm / görünüm değiştir", "", ["Z", "C"], []],
		["Destan Kitabı'nda tanıtım", "book_intro", [], []],
		["Oyunda kaydet / yükle", "", ["F5", "F9"], []],
		["Tam ekran", "toggle_fullscreen", [], []],
	]],
	# Çocuk denetleyicisi (Çocukluk'un küçük Mete'si, Serbest Gez'in Çocuğu; K37): koyun ve oyuncak yay. Sağ tuş nişandır; kamerayı orta
	# tuşla sürükleme döndürür ve eğer (PlayerController, FollowCamera.right_drag).
	["ÇOCUKKEN: KOYUN VE YAY", [
		["Koyuna bin / in · yerden al", "", ["E"], []],
		["Koyunu dürt", "sprint", [], []],
		["Nişan al (basılı tut)", "", ["Sağ tık"], []],
		["Oku bırak", "", ["Sol tık"], []],
		["Kamerayı sürükle", "", ["Orta tuş"], []],
	]],
	# At (Serbest Gez'in ahırı, Yola Çıkış; E16, E18): yön tuşları adım yürütür, koşu tuşu önce tırıs, basılı kalınca dörtnal; Boşluk atı
	# sıçratır, havada inilmez (PlayerController, RideableHorse). Atta kamera Sürüş ön ayarına geçer (CameraPreset.ride). Ahır (act-1-p2):
	# atın başında E yem, E basılı tımar, F ad ya da yular (StableLayer). Arabanın tuşları (direğe E, binmek E, E basılı Yolu Kısalt) istem
	# satırında yazar: iki satırdan fazlası Liste görünümünü sayfadan taşırır (900 − 78 px).
	["AT VE AHIR", [
		["Ata bin / in", "", ["E"], []],
		["Tırıs · basılı tut: dörtnal", "sprint", [], []],
		["Atı sıçrat", "jump", [], []],
		["Ahırda yem · basılı: tımar", "", ["E"], []],
		["Ahırda ad koy · yular", "", ["F"], []],
	]],
]
## Hangi grup hangi sütunda.
const COLUMNS := [[0], [1, 3], [2, 4]]

const PAD_NAMES := {
	JOY_BUTTON_A: "A", JOY_BUTTON_B: "B", JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
	JOY_BUTTON_BACK: "Back", JOY_BUTTON_START: "Start", JOY_BUTTON_LEFT_STICK: "L3",
	JOY_BUTTON_RIGHT_STICK: "R3", JOY_BUTTON_LEFT_SHOULDER: "LB", JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_DPAD_UP: "✣", JOY_BUTTON_DPAD_DOWN: "✣", JOY_BUTTON_DPAD_LEFT: "✣", JOY_BUTTON_DPAD_RIGHT: "✣",
	JOY_BUTTON_GUIDE: "Guide", JOY_BUTTON_MISC1: "Share", JOY_BUTTON_PADDLE1: "P1", JOY_BUTTON_PADDLE2: "P2",
	JOY_BUTTON_PADDLE3: "P3", JOY_BUTTON_PADDLE4: "P4", JOY_BUTTON_TOUCHPAD: "Dokunmatik",
}
## Atamadaki yön tuşlarının adı (oyun kolu çizimindeki ✣ yerine).
const DPAD_NAMES := {JOY_BUTTON_DPAD_UP: "✣↑", JOY_BUTTON_DPAD_DOWN: "✣↓", JOY_BUTTON_DPAD_LEFT: "✣←", JOY_BUTTON_DPAD_RIGHT: "✣→"}

## Eylemin tuş kapağında / oyun kolu düğmesinin yanında görünen adı ve grubu:
## foot (yürürken, altın), creator (karakter oluşturma, gök mavisi), menu (menü, parşömen).
const SHORT := {
	"move_forward": ["Yukarı", "foot"], "move_back": ["Aşağı", "foot"],
	"move_left": ["Sol", "foot"], "move_right": ["Sağ", "foot"],
	"sprint": ["Koş", "foot"], "camera_left": ["Kamera", "foot"], "camera_right": ["Kamera", "foot"],
	"camera_pitch_up": ["Yükselt", "foot"], "camera_pitch_down": ["Alçalt", "foot"],
	"camera_zoom_in": ["Yaklaş", "foot"], "camera_zoom_out": ["Uzaklaş", "foot"], "camera_reset": ["Varsayılan", "foot"],
	"pause": ["Menü", "foot"],
	"jump": ["Zıpla", "foot"], "inventory": ["Envanter", "foot"], "journal": ["Görevler", "foot"], "map": ["Harita", "foot"],
	"wait": ["Bekle", "foot"], "drop_load": ["Yükü bırak", "foot"],
	"book_intro": ["Tanıtım", "menu"],
	"accept": ["Onayla", "creator"], "undo": ["Geri al", "creator"],
	"ui_accept": ["Seç", "menu"], "ui_cancel": ["Geri", "menu"],
	"ui_up": ["Gezin", "menu"], "ui_down": ["Gezin", "menu"], "ui_left": ["Gezin", "menu"], "ui_right": ["Gezin", "menu"],
	"toggle_fullscreen": ["Tam ekran", "menu"],
}
## Yalnızca menünün okuduğu tuşlar (tuş adına göre).
const MENU_KEYS := {"Q": "Sayfa", "E": "Sayfa", "F5": "Kaydet", "F9": "Yükle", "Z": "Bölüm", "C": "Bölüm"}
## Çocuk denetleyicisinin aynı tuşlara eklediği işler (yürürken; tuş adına göre).
const CHILD_KEYS := {"E": "Bin · in · al", "Shift": "Dürt"}
const GROUP_COLORS := {"foot": Color("#d9b56c"), "creator": Color("#7fe3ff"), "menu": Color("#efe2c4")}
const GROUP_NAMES := [["foot", "YÜRÜRKEN"], ["creator", "KARAKTER OLUŞTURMA"], ["menu", "MENÜ"]]
const VIEWS := [["list", "Liste"], ["keyboard", "Klavye"], ["pad", "Oyun kolu"], ["rebind", "Atama"]]
## Atama görünümünün indisi.
const REBIND_VIEW := 3
const MOUSE_NOTE := "Fare: orta tuş döndürür ve eğer, tıkı kuzeye hizalar · sağ tuş döndürür (çocukta nişan) · tekerlek yakınlaşır, Alt ile eğer"
## Dinlenen tuş bu kadar saniye gelmezse dinleme biter.
const LISTEN_SECONDS := 8.0
## Atamanın yazıları.
const CHANGE_TEXT := "Değiştir"
const CANCEL_TEXT := "Vazgeç"
const RESET_TEXT := "Varsayılana dön"
const LISTEN_HINT := "Bir tuşa ya da oyun kolu düğmesine bas · Esc: vazgeç"
const IDLE_HINT := "«Değiştir» sonraki tuşu dinler; tuş başka işe bağlıysa sorulur. Değişiklik hemen kaydedilir."

static var _view := 0

var embedded := true
## Atamanın yazıldığı ayarlar (GameSettings düğümü). Boşsa autoload kullanılır.
var settings: Node
var _view_buttons: Array = []
var _holder: Control
## Atama: dinlenen eylem (yoksa &""), dinlemenin kalan süresi, satır düğmeleri (eylem → Button), durum yazısı, soru sürerken mi.
var _listening: StringName = &""
var _listen_left := 0.0
var _rebind_buttons: Dictionary = {}
var _status: Label
var _asking := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	if settings == null:
		settings = UIKit.settings_node()
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_top = 6.0
	bar.offset_bottom = 66.0
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 14)
	add_child(bar)
	for i in VIEWS.size():
		var b := ViewButton.new(str(VIEWS[i][0]), str(VIEWS[i][1]))
		b.pressed.connect(func() -> void: show_view(i))
		bar.add_child(b)
		_view_buttons.append(b)
	_holder = Control.new()
	UIKit.full_rect(_holder)
	_holder.offset_top = 78.0
	_holder.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_holder)
	show_view(_view)
	_apply_dev_args(OS.get_cmdline_user_args())


func _process(delta: float) -> void:
	if _listening == &"":
		return
	_listen_left -= delta
	if _listen_left <= 0.0:
		cancel_listen()


## Görünümü açar: 0 liste, 1 klavye, 2 oyun kolu, 3 atama.
func show_view(i: int) -> void:
	cancel_listen()
	_view = posmod(i, VIEWS.size())
	for k in _view_buttons.size():
		_view_buttons[k].active = k == _view
		_view_buttons[k].queue_redraw()
	for c in _holder.get_children():
		c.queue_free()
	_rebind_buttons.clear()
	_status = null
	var v: Control
	match _view:
		1:
			v = KeyboardView.new()
		2:
			v = PadView.new()
		3:
			v = _rebind_view()
		_:
			v = _list_view()
	UIKit.full_rect(v)
	_holder.add_child(v)
	if _view == REBIND_VIEW and is_inside_tree():
		_focus_rebind.call_deferred(&"")


func get_view() -> int:
	return _view


## Esc önce dinlemeyi bırakır (GameMenu.back düzeni): dinleme sürüyorsa true.
func back() -> bool:
	if _listening != &"":
		cancel_listen()
		return true
	return false


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and (e.physical_keycode == KEY_Z or e.physical_keycode == KEY_C):
		get_viewport().set_input_as_handled()
		show_view(_view + (-1 if e.physical_keycode == KEY_Z else 1))
		MenuStyle.play_ui(self, &"hover")


## Dinlerken her tuş ve düğme önce buraya gelir (sayfa kitabın çocuğudur: _input'u kitaptan önce okunur): Q / E sayfa çevirmez,
## Z / C görünüm değiştirmez, Esc kitabı kapatmaz; Esc dinlemeyi bırakır.
func _input(e: InputEvent) -> void:
	if _listening == &"" or _asking:
		return
	if e is InputEventKey:
		var k := e as InputEventKey
		get_viewport().set_input_as_handled()
		if not k.pressed or k.echo:
			return
		var code: int = k.physical_keycode if k.physical_keycode != KEY_NONE else k.keycode
		if code == KEY_ESCAPE:
			cancel_listen()
			return
		listen_received(InputSetup.key_event(code as Key))
	elif e is InputEventJoypadButton:
		get_viewport().set_input_as_handled()
		if (e as InputEventJoypadButton).pressed:
			listen_received(e)
	elif e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if mb.pressed and mb.button_index in [MOUSE_BUTTON_XBUTTON1, MOUSE_BUTTON_XBUTTON2]:
			get_viewport().set_input_as_handled()
			listen_received(e)


# --- Atama ----------------------------------------------------------------------------------

## «Değiştir»: eylemin sonraki tuşunu dinler (Atama görünümünü açar). Değiştirilemeyen eylemde bir şey yapmaz.
func begin_listen(action: StringName) -> void:
	if not InputSetup.is_rebindable(action):
		return
	if _view != REBIND_VIEW:
		show_view(REBIND_VIEW)
	cancel_listen()
	_listening = action
	_listen_left = LISTEN_SECONDS
	var b: Button = _rebind_buttons.get(action)
	if b:
		b.text = CANCEL_TEXT
		if b.is_inside_tree() and not b.has_focus():
			b.grab_focus()
		var row := b.get_parent()
		var kv := row.get_node_or_null(^"Keys") as KeysView
		if kv:
			kv.waiting = true
			kv.update_minimum_size()
			kv.queue_redraw()
	_set_status(LISTEN_HINT, UIKit.SKY)
	MenuStyle.play_ui(self, &"click")


## Dinlemeyi bırakır (Esc, süre, görünüm değişimi).
func cancel_listen() -> void:
	if _listening == &"":
		return
	var action := _listening
	_listening = &""
	_refresh_row(action)
	_set_status(IDLE_HINT, UIKit.TEXT_DIM)


## Dinlenen eylem (yoksa &"").
func listening_action() -> StringName:
	return _listening


## Dinlerken gelen olay: aynı bağlamda başka eyleme bağlı değilse hemen atanır; bağlıysa «Şuna da bağlı: {eylem}» sorulur.
## Döner: atandıysa true.
func listen_received(event: InputEvent) -> bool:
	var action := _listening
	if action == &"" or InputSetup.event_to_dict(event).is_empty():
		return false
	_listening = &""
	var others := InputSetup.conflicts_for(action, event)
	if not others.is_empty():
		_asking = true
		var ok: bool = await _ask(conflict_text(action, event, others))
		_asking = false
		if not is_inside_tree():
			return false
		if not ok:
			_refresh_row(action)
			_set_status(IDLE_HINT, UIKit.TEXT_DIM)
			_focus_rebind(action)
			return false
	var result := InputSetup.rebind(action, event)
	_save()
	_refresh_rows()
	if bool(result["changed"]):
		_set_status("%s: %s" % [action_label(action), event_name(event)], UIKit.GOLD)
	else:
		_set_status(IDLE_HINT, UIKit.TEXT_DIM)
	MenuStyle.play_ui(self, &"click")
	_focus_rebind(action)
	return true


## «Varsayılana dön»: sorulur, evet denirse bütün atama silinir ve kaydedilir.
func reset_all(ask := true) -> void:
	cancel_listen()
	if ask:
		_asking = true
		var ok: bool = await _ask("Bütün tuşlar varsayılana dönsün mü? Yaptığın atamalar silinir.")
		_asking = false
		if not ok or not is_inside_tree():
			return
	InputSetup.reset_bindings()
	_save()
	_refresh_rows()
	_set_status("Bütün tuşlar varsayılanda.", UIKit.GOLD)


## Çakışma sorusunun yazısı (saf): «Ş» şuna da bağlı: {eylem}. Evet denirse o eylem bu satırın eski tuşunu alır.
static func conflict_text(action: StringName, event: InputEvent, others: Array) -> String:
	var names := PackedStringArray()
	for o in others:
		names.append(action_label(o))
	var text := "«%s» şuna da bağlı: %s." % [event_name(event), ", ".join(names)]
	var old: InputEvent = null
	for e in InputSetup.events_of(action):
		if InputSetup.event_kind(e) == InputSetup.event_kind(event):
			old = e
			break
	if old:
		text += "\n«%s» satırına atansın mı? %s eski tuşu alır: «%s»." % [action_label(action), ", ".join(names), event_name(old)]
	else:
		text += "\n«%s» satırına da atansın mı?" % action_label(action)
	return text


## Eylemin oyuncuya görünen adı.
static func action_label(action: StringName) -> String:
	return str(InputSetup.LABELS.get(action, String(action)))


func _save() -> void:
	if settings == null or not is_instance_valid(settings):
		return
	if "input_bindings" in settings:
		settings.set("input_bindings", InputSetup.bindings())
	if settings.has_method(&"save_settings"):
		settings.call(&"save_settings")


## Soru: kitabın içindeysek kitabın sorusu (kitap o sırada Q / E ve Esc'i bırakır), değilse sayfanın üstünde.
func _ask(text: String) -> bool:
	var book := _book()
	if book:
		return await book.confirm(text)
	return await ConfirmDialog.ask(self, text)


func _book() -> GameMenu:
	var n := get_parent()
	while n:
		if n is GameMenu:
			return n as GameMenu
		n = n.get_parent()
	return null


func _set_status(text: String, color: Color) -> void:
	if _status and is_instance_valid(_status):
		_status.text = text
		_status.add_theme_color_override("font_color", color)


func _refresh_rows() -> void:
	for action in _rebind_buttons:
		_refresh_row(action)


func _refresh_row(action: StringName) -> void:
	var b: Button = _rebind_buttons.get(action)
	if b == null or not is_instance_valid(b):
		return
	b.text = CHANGE_TEXT
	var kv := b.get_parent().get_node_or_null(^"Keys") as KeysView
	if kv:
		kv.waiting = false
		var parts := action_keys(action)
		kv.keys = parts[0]
		kv.pads = parts[1]
		kv.update_minimum_size()
		kv.queue_redraw()


func _focus_rebind(action: StringName) -> void:
	if not is_inside_tree():
		return
	var b: Button = _rebind_buttons.get(action)
	if b == null:
		var acts := InputSetup.rebindable_actions()
		b = _rebind_buttons.get(acts[0]) if not acts.is_empty() else null
	if b and is_instance_valid(b) and b.is_inside_tree():
		b.grab_focus()


## Bir eylemin atamadaki tuş adları: [klavye ve fare, oyun kolu].
static func action_keys(action: StringName) -> Array:
	var keys: Array = []
	var pads: Array = []
	for e in InputSetup.events_of(action):
		var name := event_name(e, true)
		if name.is_empty():
			continue
		if e is InputEventJoypadButton:
			if name not in pads:
				pads.append(name)
		elif name not in keys:
			keys.append(name)
	return [keys, pads]


## Geliştirme: --tuslar=liste|klavye|kol|atama, --tuslar=atama:dinle:EYLEM, --tuslar=atama:cakisma:EYLEM:TUŞ (TUŞ fiziksel adı: Q, Slash...);
## kare almak için.
func _apply_dev_args(args: PackedStringArray) -> void:
	for a in args:
		if not a.begins_with("--tuslar="):
			continue
		var parts := a.substr(9).split(":")
		var views := {"liste": 0, "klavye": 1, "kol": 2, "atama": REBIND_VIEW}
		if views.has(parts[0]):
			show_view(int(views[parts[0]]))
		if parts.size() >= 3 and parts[1] in ["dinle", "cakisma"]:
			await get_tree().process_frame
			begin_listen(StringName(parts[2]))
			if parts[1] == "cakisma" and parts.size() >= 4:
				var code := OS.find_keycode_from_string(parts[3])
				if code != KEY_NONE:
					listen_received(InputSetup.key_event(code))


# --- Liste ----------------------------------------------------------------------------

func _list_view() -> Control:
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 28)
	center.add_child(cols)
	for c in COLUMNS:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 22)
		cols.add_child(col)
		for gi in c:
			col.add_child(_card(GROUPS[gi]))
	return center


func _card(g: Array) -> Control:
	var card := _card_frame(560)
	var vb: VBoxContainer = card.get_meta(&"body")
	vb.add_child(_card_title(str(g[0])))
	for row: Array in g[1]:
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		var l := UIKit.label(str(row[0]), 20, "Alegreya", 500, UIKit.PARCHMENT)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hb.add_child(l)
		var kv := KeysView.new()
		var keys: Array = []
		var pads: Array = []
		if str(row[1]) != "":
			keys = keys_of(str(row[1]))
			pads = pads_of(str(row[1]))
		if row.size() > 4:
			keys = composite_keys(row[4])
		kv.keys = keys + row[2]
		kv.pads = pads + row[3]
		hb.add_child(kv)
		vb.add_child(hb)
	return card


## Kartın çerçevesi; içindeki dikey kutu "body" üst verisindedir.
func _card_frame(width: float) -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UIKit.panel_style(Color(0.022, 0.028, 0.042, 0.92), Color(UIKit.GOLD_DIM, 0.8), 1, 3, Color(0, 0, 0, 0.4), 12))
	card.custom_minimum_size = Vector2(width, 0)
	var m := MarginContainer.new()
	for side in ["left", "right"]:
		m.add_theme_constant_override("margin_" + side, 22)
	m.add_theme_constant_override("margin_top", 14)
	m.add_theme_constant_override("margin_bottom", 16)
	card.add_child(m)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	m.add_child(vb)
	card.set_meta(&"body", vb)
	return card


func _card_title(text: String) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_child(UIKit.label(text, 21, "Cinzel", 700, UIKit.GOLD, 4))
	var rule := ColorRect.new()
	rule.color = Color(UIKit.GOLD, 0.25)
	rule.custom_minimum_size = Vector2(0, 1)
	box.add_child(rule)
	return box


## Birden çok eylemin satırı: önce birincil tuşları birlikte («W A S D»), sonra ikincilleri («↑ ← ↓ →»), tuş haritasından.
static func composite_keys(actions: Array) -> Array:
	var rows: Array = []
	for action in actions:
		var names := keys_of(str(action))
		for i in names.size():
			while rows.size() <= i:
				rows.append(PackedStringArray())
			# PackedStringArray değer türüdür: kopyaya eklenir, geri yazılır.
			var r: PackedStringArray = rows[i]
			r.append(str(names[i]))
			rows[i] = r
	var out: Array = []
	for r: PackedStringArray in rows:
		out.append(" ".join(r))
	return out


## Bir eylemin klavye tuşlarının adları ("Esc", "Enter", "Shift"...), tuş haritasından; adlar klavye dizilişindendir.
static func keys_of(action: String) -> Array:
	var out: Array = []
	if not InputMap.has_action(action):
		return out
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			var s := key_name(e as InputEventKey)
			if s != "" and s not in out:
				out.append(s)
		elif e is InputEventMouseButton and (e as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			out.append("Tık")
	return out


## Tuşun kapakta görünen adı (dizilişten).
static func key_name(e: InputEventKey) -> String:
	return key_label(e.physical_keycode if e.physical_keycode != 0 else e.keycode)


## Fiziksel tuşun bu klavye dizilişindeki adı: özel tuşlar Türkçe adıyla (Esc, Boşluk, oklar), öteki tuşlar dizilişin yazdığı harfle
## (DisplayServer.keyboard_get_label_from_physical; Türkçe Q'da , . / tuşları Ö, Ç, nokta). Başsızda (sınama) ABD dizilişi sayılır.
static func key_label(code: int) -> String:
	match code:
		KEY_ESCAPE:
			return "Esc"
		KEY_ENTER, KEY_KP_ENTER:
			return "Enter"
		KEY_SPACE:
			return "Boşluk"
		KEY_SHIFT:
			return "Shift"
		KEY_CTRL:
			return "Ctrl"
		KEY_ALT:
			return "Alt"
		KEY_META:
			return "Cmd"
		KEY_TAB:
			return "Tab"
		KEY_BACKSPACE:
			return "⌫"
		KEY_UP:
			return "↑"
		KEY_DOWN:
			return "↓"
		KEY_LEFT:
			return "←"
		KEY_RIGHT:
			return "→"
	var shown := code
	if code > 0 and code < KEY_SPECIAL and DisplayServer.get_name() != "headless":
		var label := int(DisplayServer.keyboard_get_label_from_physical(code as Key))
		if label > 0:
			shown = label
	var s := String.chr(shown).to_upper() if shown >= 0x20 and shown < KEY_SPECIAL else OS.get_keycode_string(shown)
	# Türkçe Q: noktasız ı'nın büyüğü I'nın yerindedir, noktalı i'ninki (İ) başka tuştadır.
	if s == "I" and code != KEY_I:
		s = "İ"
	return s


## Olayın oyuncuya görünen adı: tuş (dizilişten), fare düğmesi ya da oyun kolu düğmesi. detailed: yön tuşları okuyla.
static func event_name(e: InputEvent, detailed := false) -> String:
	if e is InputEventKey:
		return key_name(e as InputEventKey)
	if e is InputEventMouseButton:
		match (e as InputEventMouseButton).button_index:
			MOUSE_BUTTON_LEFT:
				return "Sol tık"
			MOUSE_BUTTON_RIGHT:
				return "Sağ tık"
			MOUSE_BUTTON_MIDDLE:
				return "Orta tuş"
			MOUSE_BUTTON_XBUTTON1:
				return "Fare 4"
			MOUSE_BUTTON_XBUTTON2:
				return "Fare 5"
		return ""
	if e is InputEventJoypadButton:
		var index := (e as InputEventJoypadButton).button_index
		if detailed and DPAD_NAMES.has(index):
			return str(DPAD_NAMES[index])
		return str(PAD_NAMES.get(index, "Düğme %d" % int(index)))
	return ""


## Bir eylemin oyun kolu düğmelerinin adları ("A", "LB", "✣"...).
static func pads_of(action: String) -> Array:
	var out: Array = []
	if not InputMap.has_action(action):
		return out
	for e in InputMap.action_get_events(action):
		var s := ""
		if e is InputEventJoypadButton:
			s = PAD_NAMES.get((e as InputEventJoypadButton).button_index, "")
		elif e is InputEventJoypadMotion and (e as InputEventJoypadMotion).axis == JOY_AXIS_TRIGGER_RIGHT:
			s = "RT"
		if s != "" and s not in out:
			out.append(s)
	return out


## Her tuş adı ("W", "Escape", "F5"...; fiziksel adlar) ve yaptığı işler: {ad: [[yazı, grup], ...]}.
static func key_uses() -> Dictionary:
	var out := {}
	for action in SHORT:
		if not InputMap.has_action(action):
			continue
		for e in InputMap.action_get_events(action):
			if e is InputEventKey:
				var k := e as InputEventKey
				var code: int = k.physical_keycode if k.physical_keycode != 0 else k.keycode
				add_use(out, OS.get_keycode_string(code), str(SHORT[action][0]), str(SHORT[action][1]))
	for k in CHILD_KEYS:
		add_use(out, k, str(CHILD_KEYS[k]), "foot")
	for k in MENU_KEYS:
		add_use(out, k, str(MENU_KEYS[k]), "menu")
	return out


## Her oyun kolu denetimi ("A", "LB", "LS", "DPAD"...) ve yaptığı işler.
static func pad_uses() -> Dictionary:
	var out := {}
	for action in SHORT:
		if not InputMap.has_action(action):
			continue
		for e in InputMap.action_get_events(action):
			var pad_name := ""
			if e is InputEventJoypadButton:
				pad_name = PAD_NAMES.get((e as InputEventJoypadButton).button_index, "")
				if pad_name == "✣":
					pad_name = "DPAD"
			elif e is InputEventJoypadMotion:
				match (e as InputEventJoypadMotion).axis:
					JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y:
						pad_name = "LS"
					JOY_AXIS_TRIGGER_RIGHT:
						pad_name = "RT"
					JOY_AXIS_TRIGGER_LEFT:
						pad_name = "LT"
			if pad_name != "":
				add_use(out, pad_name, str(SHORT[action][0]), str(SHORT[action][1]))
	add_use(out, "LB", "Sayfa", "menu")
	add_use(out, "RB", "Sayfa", "menu")
	return out


static func add_use(out: Dictionary, key: String, text: String, group: String) -> void:
	if not out.has(key):
		out[key] = []
	for u in out[key]:
		if u[0] == text:
			return
	out[key].append([text, group])


# --- Atama görünümü ---------------------------------------------------------------------

## İki sütunlu kartlar: her eylemin satırı (adı, tuşları ve kol düğmeleri, «Değiştir»), altta durum yazısı ve «Varsayılana dön».
func _rebind_view() -> Control:
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_PASS
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 22)
	center.add_child(outer)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 28)
	outer.add_child(cols)
	var layout := [[0], [1, 2]]
	for col_groups: Array in layout:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 22)
		cols.add_child(col)
		for gi: int in col_groups:
			var group: Array = InputSetup.REBIND_GROUPS[gi]
			var card := _card_frame(780)
			var vb: VBoxContainer = card.get_meta(&"body")
			vb.add_child(_card_title(str(group[0])))
			for action: StringName in group[1]:
				vb.add_child(_rebind_row(action))
			col.add_child(card)
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.add_theme_constant_override("separation", 28)
	_status = UIKit.label(IDLE_HINT, 20, "Alegreya-Italic", 400, UIKit.TEXT_DIM)
	_status.custom_minimum_size = Vector2(1180, 0)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	foot.add_child(_status)
	var reset := _small_button(RESET_TEXT, 240.0)
	reset.name = "ResetAll"
	reset.pressed.connect(func() -> void: reset_all())
	foot.add_child(reset)
	outer.add_child(foot)
	return center


func _rebind_row(action: StringName) -> Control:
	var hb := HBoxContainer.new()
	hb.name = String(action)
	hb.add_theme_constant_override("separation", 12)
	var l := UIKit.label(action_label(action), 20, "Alegreya", 500, UIKit.PARCHMENT)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(l)
	var kv := KeysView.new()
	kv.name = "Keys"
	var parts := action_keys(action)
	kv.keys = parts[0]
	kv.pads = parts[1]
	hb.add_child(kv)
	var b := _small_button(CHANGE_TEXT, 150.0)
	b.name = "Change"
	b.pressed.connect(func() -> void:
		if _listening == action:
			cancel_listen()
		else:
			begin_listen(action))
	hb.add_child(b)
	_rebind_buttons[action] = b
	return hb


func _small_button(text: String, width: float) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.custom_minimum_size = Vector2(width, 38)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_font_override("font", UIKit.font("Alegreya", 600))
	b.add_theme_font_size_override("font_size", 20)
	# İnce satır: kutuların iç payı küçük (gölge payı satırı büyütmesin).
	var tight := func(sb: StyleBoxFlat) -> StyleBoxFlat:
		sb.content_margin_top = 2
		sb.content_margin_bottom = 2
		sb.content_margin_left = 10
		sb.content_margin_right = 10
		return sb
	b.add_theme_stylebox_override("normal", tight.call(UIKit.panel_style(Color(0.06, 0.07, 0.09, 0.9), Color(0.4, 0.35, 0.26, 0.7), 1, 3, Color(0, 0, 0, 0.2), 4)))
	b.add_theme_stylebox_override("hover", tight.call(UIKit.panel_style(Color(0.08, 0.1, 0.13, 0.95), UIKit.SKY_DEEP, 2, 3, Color(UIKit.SKY, 0.25), 8)))
	b.add_theme_stylebox_override("focus", tight.call(UIKit.panel_style(Color(0.08, 0.1, 0.13, 0.95), UIKit.SKY, 2, 3, Color(UIKit.SKY, 0.35), 10)))
	b.add_theme_stylebox_override("pressed", tight.call(UIKit.panel_style(Color(0.12, 0.09, 0.05, 0.95), UIKit.GOLD, 2, 3, Color(UIKit.GOLD, 0.25), 8)))
	b.add_theme_color_override("font_color", UIKit.PARCHMENT)
	b.add_theme_color_override("font_focus_color", UIKit.SKY)
	b.add_theme_color_override("font_hover_color", UIKit.SKY)
	b.mouse_entered.connect(func() -> void: b.grab_focus())
	b.focus_entered.connect(func() -> void:
		if KnotButton.navigating():
			MenuStyle.play_ui(b, &"hover"))
	return b


# --- Parçalar ------------------------------------------------------------------------------

## Sayfanın üstündeki görünüm simgelerinden biri.
class ViewButton extends Button:
	var glyph := ""
	var label := ""
	var active := false

	func _init(g: String, text_label: String) -> void:
		glyph = g
		label = text_label
		custom_minimum_size = Vector2(190, 56)
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tooltip_text = text_label
		var empty := StyleBoxEmpty.new()
		for st in ["normal", "hover", "focus", "pressed", "disabled", "hover_pressed"]:
			add_theme_stylebox_override(st, empty)
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)

	func _draw() -> void:
		var hot := is_hovered()
		var r := Rect2(Vector2.ZERO, size)
		var col := UIKit.GOLD if active else (UIKit.SKY if hot else UIKit.TEXT_DIM)
		draw_style_box(UIKit.panel_style(Color(0.12, 0.09, 0.05, 0.9) if active else Color(0.03, 0.04, 0.06, 0.85), col if (active or hot) else Color(UIKit.GOLD_DIM, 0.6), 2 if active else 1, 3, Color(0, 0, 0, 0.3), 6), r)
		var c := Vector2(36, size.y * 0.5)
		if glyph == "rebind":
			# iki yönlü ok: tuşun yeri değişir
			var s := 12.0
			draw_line(c + Vector2(-s, -4), c + Vector2(s, -4), col, 1.6)
			draw_line(c + Vector2(s, -4), c + Vector2(s - 5, -9), col, 1.6)
			draw_line(c + Vector2(-s, 4), c + Vector2(s, 4), col, 1.6)
			draw_line(c + Vector2(-s, 4), c + Vector2(-s + 5, 9), col, 1.6)
		else:
			GameMenu.draw_glyph(self, glyph, c, 12.0, col)
		var f := UIKit.font("AlegreyaSC-Regular", 400, 1)
		draw_string(f, Vector2(64, size.y * 0.5 + 8.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, col)


## Bir liste satırının tuşları: klavye için taş kapaklar, oyun kolu için yuvarlak gök mavisi taşlar. waiting: atamada tuş bekleniyor.
class KeysView extends Control:
	var keys: Array = []
	var pads: Array = []
	var waiting := false

	func _get_minimum_size() -> Vector2:
		if waiting:
			return Vector2(maxf(_keys_w(), 200.0), 36)
		return Vector2(_keys_w(), 36)

	func _keys_w() -> float:
		var w := 0.0
		for k in keys:
			w += GameMenu.keycap_width(str(k)) + 6.0
		if not pads.is_empty():
			w += 18.0
			for p in pads:
				w += _pad_w(str(p)) + 6.0
		return w

	func _pad_w(p: String) -> float:
		return maxf(34.0, UIKit.font("Cinzel", 700).get_string_size(p, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 18.0)

	func _draw() -> void:
		if waiting:
			var f := UIKit.font("Alegreya-Italic", 400)
			var t := "tuşa bas…"
			var tw := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
			var r := Rect2(Vector2(size.x - tw - 24.0, 1), Vector2(tw + 24.0, 32))
			draw_style_box(UIKit.panel_style(Color(0.04, 0.07, 0.1, 0.95), Color(UIKit.SKY, 0.9), 2, 3, Color(UIKit.SKY, 0.25), 8), r)
			draw_string(f, Vector2(r.position.x + 12.0, r.get_center().y + 7.0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UIKit.SKY)
			return
		var x := maxf(size.x - _keys_w(), 0.0)
		for k in keys:
			var w := GameMenu.keycap_width(str(k))
			GameMenu.draw_keycap(self, Rect2(Vector2(x, 1), Vector2(w, 32)), str(k))
			x += w + 6.0
		if pads.is_empty():
			return
		draw_line(Vector2(x + 6.0, 6), Vector2(x + 6.0, 30), Color(UIKit.TEXT_DIM, 0.4), 1.0)
		x += 18.0
		var f := UIKit.font("Cinzel", 700)
		for p in pads:
			var w := _pad_w(str(p))
			var r := Rect2(Vector2(x, 1), Vector2(w, 32))
			draw_style_box(UIKit.panel_style(Color(0.04, 0.07, 0.1, 0.95), Color(UIKit.SKY, 0.7), 1, 16, Color(0, 0, 0, 0.3), 3), r)
			var tw := f.get_string_size(str(p), HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
			draw_string(f, Vector2(r.get_center().x - tw * 0.5, r.get_center().y + 5.0), str(p), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UIKit.SKY)
			x += w + 6.0


## Her tuşun üstüne işi, ne zaman işe yaradığının rengiyle yazılmış bir klavye ve altında açıklaması. Kapaktaki yazı dizilişindir.
class KeyboardView extends Control:
	# [tuş adı, kapaktaki yazı, tuş birimi cinsinden genişlik]
	const ROWS := [
		[["Escape", "Esc", 1.0], ["", "", 1.0], ["F1", "F1", 1.0], ["F2", "F2", 1.0], ["F3", "F3", 1.0], ["F4", "F4", 1.0], ["", "", 0.5], ["F5", "F5", 1.0], ["F6", "F6", 1.0], ["F7", "F7", 1.0], ["F8", "F8", 1.0], ["", "", 0.5], ["F9", "F9", 1.0], ["F10", "F10", 1.0], ["F11", "F11", 1.0], ["F12", "F12", 1.0]],
		[["QuoteLeft", "`", 1.0], ["1", "1", 1.0], ["2", "2", 1.0], ["3", "3", 1.0], ["4", "4", 1.0], ["5", "5", 1.0], ["6", "6", 1.0], ["7", "7", 1.0], ["8", "8", 1.0], ["9", "9", 1.0], ["0", "0", 1.0], ["Minus", "-", 1.0], ["Equal", "=", 1.0], ["Backspace", "⌫", 2.0]],
		[["Tab", "Tab", 1.5], ["Q", "Q", 1.0], ["W", "W", 1.0], ["E", "E", 1.0], ["R", "R", 1.0], ["T", "T", 1.0], ["Y", "Y", 1.0], ["U", "U", 1.0], ["I", "I", 1.0], ["O", "O", 1.0], ["P", "P", 1.0], ["BracketLeft", "[", 1.0], ["BracketRight", "]", 1.0], ["Backslash", "\\", 1.5]],
		[["CapsLock", "Caps", 1.75], ["A", "A", 1.0], ["S", "S", 1.0], ["D", "D", 1.0], ["F", "F", 1.0], ["G", "G", 1.0], ["H", "H", 1.0], ["J", "J", 1.0], ["K", "K", 1.0], ["L", "L", 1.0], ["Semicolon", ";", 1.0], ["Apostrophe", "'", 1.0], ["Enter", "Enter", 2.25]],
		[["Shift", "Shift", 2.25], ["Z", "Z", 1.0], ["X", "X", 1.0], ["C", "C", 1.0], ["V", "V", 1.0], ["B", "B", 1.0], ["N", "N", 1.0], ["M", "M", 1.0], ["Comma", ",", 1.0], ["Period", ".", 1.0], ["Slash", "/", 1.0], ["Shift", "Shift", 2.75]],
		[["Ctrl", "Ctrl", 1.25], ["Alt", "Alt", 1.25], ["Meta", "Cmd", 1.25], ["Space", "Boşluk", 6.25], ["Meta", "Cmd", 1.25], ["Alt", "Alt", 1.25], ["Menu", "", 1.25], ["Ctrl", "Ctrl", 1.25]],
	]
	# [tuş adı, kapaktaki yazı, ok bloğundaki sütun, -, satır]
	const ARROWS := [["Up", "↑", 1.0, 0.0, 4.0], ["Left", "←", 0.0, 0.0, 5.0], ["Down", "↓", 1.0, 0.0, 5.0], ["Right", "→", 2.0, 0.0, 5.0]]

	var _uses: Dictionary = {}

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_uses = ControlsPage.key_uses()
		resized.connect(queue_redraw)

	## Kapaktaki yazı: tek karakterli (harf, sayı, noktalama) tuşlar dizilişten okunur, ötekiler tablodaki adıyla kalır.
	static func cap_text(key: String, fallback: String) -> String:
		if fallback.length() != 1:
			return fallback
		var code := OS.find_keycode_from_string(key)
		return ControlsPage.key_label(code) if code != KEY_NONE else fallback

	func _draw() -> void:
		var units := Vector2(15.0 + 0.5 + 3.0, 6.0 + 0.35)
		var u := floorf(minf((size.x - 60.0) / units.x, (size.y - 90.0) / units.y))
		if u <= 4.0:
			return
		var origin := Vector2((size.x - units.x * u) * 0.5, 6.0)
		var gap := u * 0.08
		for ri in ROWS.size():
			var x := 0.0
			var y := ri * u + (0.0 if ri == 0 else u * 0.35)
			for k in ROWS[ri]:
				var w: float = k[2]
				if str(k[0]) != "":
					_cap(Rect2(origin + Vector2(x * u, y) + Vector2(gap, gap) * 0.5, Vector2(w * u - gap, u - gap)), str(k[0]), cap_text(str(k[0]), str(k[1])), u)
				x += w
		for a in ARROWS:
			var rx: float = 15.5 + float(a[2])
			var ry: float = float(a[4]) * u + u * 0.35
			_cap(Rect2(origin + Vector2(rx * u, ry) + Vector2(gap, gap) * 0.5, Vector2(u - gap, u - gap)), str(a[0]), str(a[1]), u)
		_legend(Vector2(origin.x, origin.y + units.y * u + 22.0), units.x * u)

	func _cap(r: Rect2, key: String, text: String, u: float) -> void:
		var uses: Array = _uses.get(key, [])
		var col := Color(UIKit.GOLD_DIM, 0.55)
		var fill := Color(0.04, 0.05, 0.07, 0.92)
		if not uses.is_empty():
			col = ControlsPage.GROUP_COLORS.get(uses[0][1], UIKit.GOLD)
			fill = Color(col.r * 0.16, col.g * 0.16, col.b * 0.16, 0.95)
		draw_rect(Rect2(r.position + Vector2(0, 3), r.size), Color(0, 0, 0, 0.45), true)
		draw_rect(r, fill, true)
		draw_rect(r.grow(-1.0), Color(col, 0.9 if not uses.is_empty() else 0.5), false, 1.5 if not uses.is_empty() else 1.0)
		var f := UIKit.font("Cinzel", 700)
		var fs := int(u * 0.22)
		draw_string(f, r.position + Vector2(7, fs + 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(UIKit.PARCHMENT, 0.95 if not uses.is_empty() else 0.4))
		# tuşun işe yaradığı her an için bir nokta
		var dx := r.end.x - 9.0
		var seen := {}
		for use in uses:
			if seen.has(use[1]):
				continue
			seen[use[1]] = true
			draw_circle(Vector2(dx, r.position.y + 9.0), 3.5, ControlsPage.GROUP_COLORS.get(use[1], UIKit.GOLD))
			dx -= 10.0
		if uses.is_empty():
			return
		var lf := UIKit.font("Alegreya", 500)
		var ls := int(clampf(u * 0.165, 11.0, 15.0))
		var lines: Array = []
		for use in uses:
			lines.append(str(use[0]))
		lines = lines.slice(0, 3)
		var ly := r.end.y - 6.0 - (lines.size() - 1) * (ls + 1)
		for line in lines:
			draw_string(lf, Vector2(r.position.x + 6.0, ly), line, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 10.0, ls, Color(UIKit.PARCHMENT, 0.92))
			ly += ls + 1

	func _legend(at: Vector2, width: float) -> void:
		var f := UIKit.font("AlegreyaSC-Regular", 400)
		var x := at.x
		for g in ControlsPage.GROUP_NAMES:
			var c: Color = ControlsPage.GROUP_COLORS[g[0]]
			draw_circle(Vector2(x + 7.0, at.y + 8.0), 6.0, c)
			var t := str(g[1])
			draw_string(f, Vector2(x + 20.0, at.y + 15.0), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(c, 0.95))
			x += f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x + 52.0
		var note := ControlsPage.MOUSE_NOTE
		var nf := UIKit.font("Alegreya-Italic", 400)
		var nw := nf.get_string_size(note, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
		draw_string(nf, Vector2(at.x + width - nw, at.y + 15.0), note, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, UIKit.TEXT_DIM)


## Ortada çizilmiş bir oyun kolu; her düğmesi yanına yazılmış işiyle.
class PadView extends Control:
	var _uses: Dictionary = {}

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_uses = ControlsPage.pad_uses()
		resized.connect(queue_redraw)

	func _draw() -> void:
		var k := minf(1.0, minf(size.x / 1500.0, size.y / 640.0))
		if k <= 0.05:
			return
		var c := Vector2(size.x * 0.5, size.y * 0.5 - 10.0)
		var body := Color(0.075, 0.085, 0.115)
		var rim := Color(UIKit.GOLD_DIM, 0.9)
		# gövdenin arkasındaki tetikler ve omuzlar
		for side in [-1.0, 1.0]:
			_round(Rect2(c + Vector2(side * 250.0 - 60.0, -205.0) * k, Vector2(120, 56) * k), Color(0.06, 0.07, 0.09), rim, 14.0 * k)
			_round(Rect2(c + Vector2(side * 250.0 - 85.0, -160.0) * k, Vector2(170, 44) * k), Color(0.07, 0.08, 0.1), rim, 16.0 * k)
		# gövde: orta ve iki tutamak tek bir siluette
		var shape := _rrect(Rect2(c + Vector2(-330, -140) * k, Vector2(660, 250) * k), 90.0 * k)
		for g in [[Vector2(-230, 40), 150.0], [Vector2(230, 40), 150.0], [Vector2(-175, 160), 105.0], [Vector2(175, 160), 105.0]]:
			var merged := Geometry2D.merge_polygons(shape, _circle(c + g[0] * k, float(g[1]) * k))
			var best := 0
			for i in merged.size():
				if merged[i].size() > merged[best].size():
					best = i
			shape = merged[best]
		draw_colored_polygon(shape, body)
		var outline := shape.duplicate()
		outline.append(shape[0])
		draw_polyline(outline, rim, 2.0, true)
		# çubuklar, yön tuşları, yüz düğmeleri, back / start
		var ls := c + Vector2(-230, -10) * k
		var rs := c + Vector2(120, 80) * k
		var dp := c + Vector2(-120, 80) * k
		var face := c + Vector2(230, -10) * k
		for s in [ls, rs]:
			draw_circle(s, 52.0 * k, Color(0.03, 0.035, 0.05))
			draw_arc(s, 52.0 * k, 0, TAU, 48, rim, 2.0, true)
			draw_circle(s, 34.0 * k, Color(0.11, 0.12, 0.15))
		for d in [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0)]:
			_round(Rect2(dp + d * 26.0 * k - Vector2(16, 16) * k, Vector2(32, 32) * k), Color(0.11, 0.12, 0.15), rim, 5.0 * k)
		var faces := {"Y": [Vector2(0, -46), Color("#c7b25b")], "A": [Vector2(0, 46), Color("#5fae6b")], "X": [Vector2(-46, 0), Color("#5b8fc7")], "B": [Vector2(46, 0), Color("#c75b5b")]}
		var f := UIKit.font("Cinzel", 700)
		for n in faces:
			var p: Vector2 = face + faces[n][0] * k
			draw_circle(p, 24.0 * k, Color(0.05, 0.06, 0.08))
			draw_arc(p, 24.0 * k, 0, TAU, 32, faces[n][1], 2.5, true)
			var tw := f.get_string_size(n, HORIZONTAL_ALIGNMENT_LEFT, -1, int(22 * k)).x
			draw_string(f, p + Vector2(-tw * 0.5, 8.0 * k), n, HORIZONTAL_ALIGNMENT_LEFT, -1, int(22 * k), faces[n][1])
		var back := c + Vector2(-60, -60) * k
		var start := c + Vector2(60, -60) * k
		for s in [back, start]:
			_round(Rect2(s - Vector2(22, 12) * k, Vector2(44, 24) * k), Color(0.11, 0.12, 0.15), rim, 12.0 * k)
		# yan yazılar: [düğme adı, koldaki yeri]
		var left := [["LT", c + Vector2(-250, -180) * k], ["LB", c + Vector2(-250, -140) * k], ["Back", back], ["LS", ls], ["L3", ls + Vector2(0, 30) * k], ["DPAD", dp]]
		var right := [["RT", c + Vector2(250, -180) * k], ["RB", c + Vector2(250, -140) * k], ["Start", start], ["Y", face + Vector2(0, -46) * k], ["X", face + Vector2(-46, 0) * k], ["B", face + Vector2(46, 0) * k], ["A", face + Vector2(0, 46) * k], ["R3", rs]]
		_callouts(left, -1.0, c, k)
		_callouts(right, 1.0, c, k)

	func _callouts(list: Array, side: float, c: Vector2, k: float) -> void:
		var shown: Array = []
		for item in list:
			if _uses.has(item[0]):
				shown.append(item)
		var top := c.y - (shown.size() - 1) * 34.0
		var x := c.x + side * 430.0 * k
		var f := UIKit.font("Cinzel", 700)
		var lf := UIKit.font("Alegreya", 500)
		for i in shown.size():
			var pad_name: String = shown[i][0]
			var anchor: Vector2 = shown[i][1]
			var y := top + i * 68.0
			var uses: Array = _uses[pad_name]
			var col: Color = ControlsPage.GROUP_COLORS.get(uses[0][1], UIKit.GOLD)
			var start := Vector2(x, y)
			draw_polyline(PackedVector2Array([anchor, Vector2(anchor.x + side * 30.0 * k, y), start]), Color(col, 0.55), 1.5, true)
			draw_circle(anchor, 4.0, col)
			var tag: String = {"LS": "Sol çubuk", "DPAD": "Yön tuşları"}.get(pad_name, pad_name)
			var tw := f.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 20.0
			var texts: Array = []
			for use in uses:
				texts.append(str(use[0]))
			var line := " · ".join(texts)
			var lw := lf.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
			var pill_x := x if side > 0 else x - tw
			draw_style_box(UIKit.panel_style(Color(0.04, 0.07, 0.1, 0.95), Color(col, 0.85), 1, 14, Color(0, 0, 0, 0.3), 3), Rect2(Vector2(pill_x, y - 16.0), Vector2(tw, 30)))
			draw_string(f, Vector2(pill_x + 10.0, y + 6.0), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col)
			var tx := pill_x + tw + 12.0 if side > 0 else pill_x - 12.0 - lw
			draw_string(lf, Vector2(tx, y + 7.0), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UIKit.PARCHMENT)

	func _circle(at: Vector2, r: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		for i in 48:
			pts.append(at + Vector2.from_angle(TAU * i / 48.0) * r)
		return pts

	func _rrect(r: Rect2, radius: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		var corners := [[r.position + Vector2(radius, radius), PI], [Vector2(r.end.x - radius, r.position.y + radius), PI * 1.5], [r.end - Vector2(radius, radius), 0.0], [Vector2(r.position.x + radius, r.end.y - radius), PI * 0.5]]
		for cc in corners:
			for i in 9:
				pts.append(cc[0] + Vector2.from_angle(float(cc[1]) + PI * 0.5 * i / 8.0) * radius)
		return pts

	func _round(r: Rect2, fill: Color, border: Color, radius: float) -> void:
		var sb := StyleBoxFlat.new()
		sb.bg_color = fill
		sb.border_color = border
		sb.set_border_width_all(2 if border.a > 0.0 else 0)
		sb.set_corner_radius_all(int(radius))
		sb.anti_aliasing = true
		draw_style_box(sb, r)
