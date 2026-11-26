class_name GameMenu
extends Control
## Yolculuğun kitabı (Tanhu 1): bulanıklaşmış dünyanın üstünde tam ekran, üstte sekme çubuğu, altta
## tuş ipuçları; her sayfa bir sekme. Kitap arayüz ölçeğinde çizilir (UIKit.ui_k). Q / E (ya da omuz
## düğmeleri) sayfa çevirir, Esc kapatır. Girdiyi önce açık sayfaya sorar (godot.md §3.8): sayfanın
## turn_section(dir)'i bölüm çevirdiyse Q / E orada durur, sınırdaysa kitap komşu sayfaya geçer; Esc'te
## sayfanın back()'i (büyütülmüş görsel, arama) önce geri döner; sayfa metin alıyorsa (arama kutusu) Q / E harftir.
##   "title" kipi (açılış ekranı): yalnızca AYARLAR ve TUŞLAR sayfaları.
##   "book"  kipi (açılış ekranındaki Destan Kitabı): DESTAN, GÖK VE YER, KİŞİLER ve TAŞLAR bölümleri; son
##           kaydın işaretlerini okur (flags).
##   "game"  kipi (duraklatma): GENEL (devam et, kaydet, yükle, ayarlar, ana menü, masaüstü), HARİTA ve GÖREVLER (oyun içi HUD'un
##           büyük haritası ve görev günlüğü: HudMapPage, HudJournalPage; veriyi hud verir), Destan Kitabı'nın dört bölümü, TUŞLAR ve
##           AYARLAR; F5 / F9 kayıt yuvalarını açar; M haritaya, J görevlere geçer (açık olanda yeniden basmak kitabı kapatır).
##           HARİTA üst menünün altını kenardan kenara kaplar (FULL_PAGES: alt şerit gizlenir; prototipin atlası gibi).
## «Gök ve Yer» ve KİŞİLER ansiklopedi düzenindedir (EncyclopediaPage); Destan ve Taşlar DestanKitabiPage'dir.

signal closed
signal main_menu_requested
signal quit_requested
signal load_requested(slot: int)
## Oyunda bir yuvaya kaydedildi.
signal saved(slot: int)

const BACKDROP_SHADER := "res://assets/ui/menu_backdrop.gdshader"
## Sayfalar: kimlik, sekmedeki ad, simge.
const PAGE_GENERAL := {"id": "genel", "label": "GENEL", "glyph": "home"}
const PAGE_MAP := {"id": "harita", "label": "HARİTA", "glyph": "map"}
const PAGE_QUESTS := {"id": "gorevler", "label": "GÖREVLER", "glyph": "quest"}
const PAGE_SAGA := {"id": "destan", "label": "DESTAN", "glyph": "speech"}
const PAGE_SKY := {"id": "gok_yer", "label": "GÖK VE YER", "glyph": "sun"}
const PAGE_PEOPLE := {"id": "kisiler", "label": "KİŞİLER", "glyph": "people"}
const PAGE_STONES := {"id": "taslar", "label": "TAŞLAR", "glyph": "stone"}
const PAGE_KEYS := {"id": "tuslar", "label": "TUŞLAR", "glyph": "keys"}
const PAGE_SETTINGS := {"id": "ayarlar", "label": "AYARLAR", "glyph": "gear"}
const GAME_PAGES := [PAGE_GENERAL, PAGE_MAP, PAGE_QUESTS, PAGE_SAGA, PAGE_SKY, PAGE_PEOPLE, PAGE_STONES, PAGE_KEYS, PAGE_SETTINGS]
## Oyunda kitabı bir sayfada açan / kapatan tuşların eylemleri (InputSetup): sayfa → eylem.
const PAGE_KEYS_ACTIONS := {"harita": &"map", "gorevler": &"journal"}
const TITLE_PAGES := [PAGE_SETTINGS, PAGE_KEYS]
const BOOK_PAGES := [PAGE_SAGA, PAGE_SKY, PAGE_PEOPLE, PAGE_STONES]
## Sayfanın sağ alttaki ipucu.
const PAGE_HINTS := {
	"genel": "Yolculuğu kaydet, yükle ya da bırak",
	"harita": "M: haritayı kapat · tekerlek: yakınlaş · sürükle: kaydır",
	"gorevler": "J: kapat · yukarı / aşağı: görev seç",
	"destan": "Q E: bölüm çevir · yukarı / aşağı: dize seç",
	"gok_yer": "Q E bölüm · ↑ ↓ kişi · ← → görsel · Enter büyüt · Esc geri",
	"kisiler": "Q E bölüm · ↑ ↓ kişi · ← → görsel · Enter büyüt · Esc geri",
	"taslar": "Q E: bölüm çevir · yukarı / aşağı: taş seç",
	"tuslar": "Z C: görünüm değiştir (liste · klavye · oyun kolu · atama)",
	"ayarlar": "Yukarı / aşağı: bölüm seç · sağ: içine gir · Z C: bölüm değiştir",
}
const BAR_H := 112.0
const FOOT_H := 66.0
## Üst menünün altını kenardan kenara kaplayan sayfalar (alt şerit gizlenir).
const FULL_PAGES := ["harita"]
const QUIT_CONFIRM_TEXT := "Oyundan çıkıp masaüstüne dönülsün mü? Yolculuğun otomatik kayda yazılır."

## "game", "title" ya da "book".
var mode := "game"
## Oyunda şu an kaydedilebilir mi?
var can_save := true
## Kaydın neden kapalı olduğu (boş değilse genel sayfada KAYDET'in altında yazar, F5'te bildirilir; K99: Çocukluk'ta kayıt yok).
var save_note := ""
## Genel sayfanın yolculuk kartının yeri ve satırı (boşsa kampın).
var card_place := ""
var card_note := ""
## Süren yolculuk (oyun kipi: kaydetme, genel sayfanın kartı, Destan Kitabı'nın işaretleri).
var journey: Journey
## Okunan kayıtlar (yoksa yolculuğunkiler).
var saves: SaveSystem
## Destan Kitabı'nın okuduğu işaretler ("book" kipi; oyun kipinde yolculuğunkiler).
var flags: Dictionary = {}
## Ayarlar sayfasının değiştirdiği ayarlar (boşsa GameSettings autoload'u).
var settings: Node
## Oyun içi HUD (GameplayHud): HARİTA ve GÖREVLER sayfalarının verisi (map_page_data, journal_quests); yoksa sayfalar boş görünür.
var hud: Node
var pages: Array = GAME_PAGES

var _i := -1
var _tabs: Array = []              # TabButton
var _content: Control
var _page: Control
var _hint: Label
var _frame: Control
var _overlay: Control
var _foot: Array = []              # KeyHint: geri / devam et, kaydet, yükle
var _foot_bar: Control
var _hint_tween: Tween


func _ready() -> void:
	UIKit.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	pages = pages_for(mode)
	if saves == null:
		saves = journey.saves if journey else SaveSystem.new()
	if mode == "game" and journey:
		flags = journey.flags
	var back := ColorRect.new()
	UIKit.full_rect(back)
	back.color = Color(0.012, 0.02, 0.035, 0.9)
	if ResourceLoader.exists(BACKDROP_SHADER):
		var mat := ShaderMaterial.new()
		mat.shader = load(BACKDROP_SHADER)
		back.material = mat
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(back)
	# Kitabın kendisi (çubuklar ve sayfalar) arayüz ölçeğinde; arkadaki bulanık dünya tam ekran.
	_frame = Control.new()
	_frame.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_frame)
	_content = Control.new()
	UIKit.full_rect(_content)
	_content.offset_top = BAR_H + 6.0
	_content.offset_bottom = -FOOT_H - 4.0
	_content.mouse_filter = Control.MOUSE_FILTER_PASS
	_frame.add_child(_content)
	_frame.add_child(_build_bar())
	_foot_bar = _build_foot()
	_frame.add_child(_foot_bar)
	_fit_frame()
	resized.connect(_fit_frame)
	var s := _settings()
	if s and s.has_signal(&"changed"):
		s.changed.connect(_fit_frame)
	_refresh_texts()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.18)
	MenuStyle.play_ui(self, &"page_turn", -4.0)


## Kipe göre sayfalar.
static func pages_for(p_mode: String) -> Array:
	match p_mode:
		"title":
			return TITLE_PAGES
		"book":
			return BOOK_PAGES
	return GAME_PAGES


# --- Çerçeve ---------------------------------------------------------------------------

## Yüksek çözünürlükte kitap piksel boyutunu korur, ekranın daha azını kaplar; oyuncunun arayüz
## ölçeği onu daha da küçültür. Sayfalar kalan geniş alana yerleşir.
func _fit_frame() -> void:
	var k := UIKit.ui_k()
	_frame.scale = Vector2(k, k)
	_frame.position = Vector2.ZERO
	_frame.size = size / k


func _build_bar() -> Control:
	var bar := Strip.new()
	bar.top = true
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_bottom = BAR_H
	bar.mouse_filter = Control.MOUSE_FILTER_PASS
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_top = 8.0
	row.offset_bottom = -12.0
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_child(row)
	row.add_child(_bumper("Q", -1))
	for i in pages.size():
		var t := TabButton.new(str(pages[i]["glyph"]))
		if mode == "game":
			t.custom_minimum_size = Vector2(166, 92)
		t.pressed.connect(func() -> void: show_page(str(pages[i]["id"])))
		row.add_child(t)
		_tabs.append(t)
	row.add_child(_bumper("E", 1))
	return bar


func _bumper(key: String, dir: int) -> Control:
	var b := KeyHint.new(key, "")
	b.custom_minimum_size = Vector2(64, 80)
	b.pressed.connect(func() -> void: turn_or_section(dir))
	return b


func _build_foot() -> Control:
	var foot := Strip.new()
	foot.top = false
	foot.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	foot.offset_top = -FOOT_H
	foot.mouse_filter = Control.MOUSE_FILTER_PASS
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 28.0
	row.offset_right = -28.0
	row.offset_top = 10.0
	row.add_theme_constant_override("separation", 26)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	foot.add_child(row)
	var hints: Array = [["Esc", "Geri", close]] if mode != "game" else [["Esc", "Devam et", close], ["F5", "Kaydet", func() -> void: open_slots("save")], ["F9", "Yükle", func() -> void: open_slots("load")]]
	for d in hints:
		var h := KeyHint.new(str(d[0]), str(d[1]))
		h.pressed.connect(d[2])
		row.add_child(h)
		_foot.append(h)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(gap)
	_hint = UIKit.label("", 20, "Alegreya-Italic", 400, UIKit.TEXT_DIM)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hint.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(_hint)
	return foot


func _refresh_texts() -> void:
	for i in _tabs.size():
		_tabs[i].text_label = str(pages[i]["label"])
		_tabs[i].queue_redraw()
	for h in _foot:
		h.refresh()
	if mode == "game" and _foot.size() >= 3:
		_foot[1].disabled = not can_save
		_foot[2].disabled = not saves.has_any_save()
	if _i >= 0:
		_hint.text = _page_hint()


# --- Sayfalar ----------------------------------------------------------------------------

func has_page(id: String) -> bool:
	for p in pages:
		if p["id"] == id:
			return true
	return false


## Açık sayfanın kimliği ("" = henüz yok).
func current_page() -> String:
	return str(pages[_i]["id"]) if _i >= 0 else ""


## Açık sayfanın denetimi.
func get_page() -> Control:
	return _page


func show_page(id: String) -> void:
	var i := -1
	for k in pages.size():
		if pages[k]["id"] == id:
			i = k
	if i < 0 or i == _i:
		return
	var turned := _i >= 0
	_i = i
	for k in _tabs.size():
		_tabs[k].active = k == i
		_tabs[k].queue_redraw()
	if _page:
		_page.queue_free()
	_page = _make_page(id)
	_fit_content(id)
	_content.add_child(_page)
	_hint.text = _page_hint()
	if turned:
		MenuStyle.play_ui(self, &"page_turn", -8.0)
		_page.modulate.a = 0.0
		create_tween().tween_property(_page, "modulate:a", 1.0, 0.16)


func _make_page(id: String) -> Control:
	var p: Control
	match id:
		"genel":
			var g := GeneralPage.new()
			g.can_save = can_save
			g.save_note = save_note
			g.card_place = card_place
			g.card_note = card_note
			g.journey = journey
			g.saves = saves
			g.chosen.connect(_on_general)
			p = g
		"gok_yer", "kisiler":
			var ep := EncyclopediaPage.new(id, flags)
			ep.page_requested.connect(_on_page_requested)
			p = ep
		"destan", "taslar":
			p = DestanKitabiPage.new(id, flags)
		"tuslar":
			p = ControlsPage.new()
		"harita":
			var mp := HudMapPage.from_data(hud.call(&"map_page_data") if hud and hud.has_method(&"map_page_data") else {})
			mp.close_requested.connect(close)
			p = mp
		"gorevler":
			var jp := HudJournalPage.new()
			jp.quests = hud.call(&"journal_quests") if hud and hud.has_method(&"journal_quests") else []
			p = jp
		_:
			var sp := SettingsPanel.new()
			sp.settings = _settings()
			p = sp
	if "embedded" in p:
		p.set("embedded", true)
	UIKit.full_rect(p)
	return p


func _page_hint() -> String:
	return str(PAGE_HINTS.get(current_page(), ""))


## Sayfanın alanı: HARİTA üst menünün altını kenardan kenara kaplar (prototipin atlası gibi; alt şerit gizlenir, haritanın kendi
## «Haritayı kapat» düğmesi ve araçları vardır), öteki sayfalar iki şeridin arasındadır.
func _fit_content(id: String) -> void:
	var full := id in FULL_PAGES
	_content.offset_top = BAR_H if full else BAR_H + 6.0
	_content.offset_bottom = 0.0 if full else -FOOT_H - 4.0
	if _foot_bar:
		_foot_bar.visible = not full


## Bir sayfa ileri (+1) ya da geri (-1); uçlarda başa sarar.
func turn(d: int) -> void:
	show_page(str(pages[posmod(_i + d, pages.size())]["id"]))


## Q / E: önce açık sayfanın bölümünü çevirir (turn_section); sayfa bölüm sınırındaysa kitabın komşu sayfasına
## geçer. Geri gelinen ansiklopedi sayfası son bölümünde açılır (enter_from).
func turn_or_section(d: int) -> void:
	if _page and _page.has_method(&"turn_section") and bool(_page.call(&"turn_section", d)):
		return
	turn(d)
	if _page and _page.has_method(&"enter_from"):
		_page.call(&"enter_from", d)


## Ansiklopedi sayfası başka bir sayfanın bölümünü ya da kaydını istedi (sekme, soy kartı).
func _on_page_requested(page_id: String, section: String, entry_id: String) -> void:
	if not has_page(page_id):
		return
	show_page(page_id)
	if _page is EncyclopediaPage:
		var ep := _page as EncyclopediaPage
		if not section.is_empty():
			ep.open_section(section)
		if not entry_id.is_empty():
			ep.open_entry(entry_id)


## Kitabı kapatır (sahibi serbest bırakır).
func close() -> void:
	if _overlay:
		return
	MenuStyle.play_ui(self, &"page_turn", -6.0)
	closed.emit()


## Üstünde açık bir pencere (soru, kayıt yuvaları) var mı?
func has_overlay() -> bool:
	return _overlay != null and is_instance_valid(_overlay)


## Genel sayfanın butonları.
func _on_general(what: String) -> void:
	match what:
		"resume":
			close()
		"save":
			open_slots("save")
		"load":
			open_slots("load")
		"settings":
			show_page("ayarlar")
		"main":
			main_menu_requested.emit()
		"quit":
			if await confirm(QUIT_CONFIRM_TEXT):
				quit_requested.emit()


## Kitabın üstünde evet / hayır sorusu sorar.
func confirm(text: String) -> bool:
	var d := ConfirmDialog.new()
	_overlay = d
	add_child(d)
	var ok: bool = await d.run(text)
	_overlay = null
	return ok


# --- Girdi -------------------------------------------------------------------------------------
## Sayfaların denetimlerinden önce okunur: Q / E sayfa çevirir, Esc kapatır.

func _input(e: InputEvent) -> void:
	if has_overlay() or not visible or not is_inside_tree():
		return
	if e.is_action_pressed(&"ui_cancel") or (InputMap.has_action(&"pause") and e.is_action_pressed(&"pause")):
		get_viewport().set_input_as_handled()
		# Sayfa önce kendi içinde geri döner (büyütülmüş görsel, arama); dönemezse kitap kapanır.
		if _page and _page.has_method(&"back") and bool(_page.call(&"back")):
			return
		close()
		return
	if e is InputEventKey and e.pressed and not e.echo:
		match (e as InputEventKey).physical_keycode:
			KEY_Q, KEY_E:
				# Arama kutusu odaktayken Q ve E harftir: olay kutuya gider.
				if _page and _page.has_method(&"wants_text_input") and bool(_page.call(&"wants_text_input")):
					return
				get_viewport().set_input_as_handled()
				turn_or_section(-1 if (e as InputEventKey).physical_keycode == KEY_Q else 1)
				return
			KEY_F5, KEY_F9:
				if mode == "game":
					get_viewport().set_input_as_handled()
					open_slots("save" if (e as InputEventKey).physical_keycode == KEY_F5 else "load")
					return
	# Oyunda M haritaya, J görevlere geçer; açık olan sayfanın tuşu kitabı kapatır (oyuna döner).
	if mode == "game":
		for page_id: String in PAGE_KEYS_ACTIONS:
			var action: StringName = PAGE_KEYS_ACTIONS[page_id]
			if InputMap.has_action(action) and e.is_action_pressed(action) and has_page(page_id):
				get_viewport().set_input_as_handled()
				if current_page() == page_id:
					close()
				else:
					show_page(page_id)
				return
	if e is InputEventJoypadButton and e.pressed and (e as InputEventJoypadButton).button_index in [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER]:
		get_viewport().set_input_as_handled()
		turn_or_section(-1 if (e as InputEventJoypadButton).button_index == JOY_BUTTON_LEFT_SHOULDER else 1)


## Kitabın üstünde kayıt yuvaları ("save" ya da "load").
func open_slots(m: String) -> void:
	if has_overlay():
		return
	if mode != "game" or (m == "save" and (not can_save or journey == null)) or (m == "load" and not saves.has_any_save()):
		MenuStyle.play_ui(self, &"deny")
		if m == "save" and not save_note.is_empty():
			show_notice(save_note)
		return
	var p := SaveLoadPanel.new(m, true)
	p.saves = saves
	p.journey = journey
	_overlay = p
	add_child(p)
	p.load_requested.connect(func(slot: int) -> void:
		p.queue_free()
		_overlay = null
		load_requested.emit(slot))
	p.saved.connect(func(slot: int) -> void:
		show_notice("Yolculuk kaydedildi · #%d" % int(saves.slot_info(slot).get("save_no", slot)))
		saved.emit(slot))
	await p.closed
	_overlay = null
	if is_inside_tree():
		_refresh_texts()


## Alttaki ipucunun yerinde kısa bir bildirim (ör. "Yolculuk kaydedildi · #3"); sonra ipucu geri gelir.
func show_notice(text: String) -> void:
	if _hint == null:
		return
	if _hint_tween and _hint_tween.is_valid():
		_hint_tween.kill()
	_hint.text = text
	_hint.add_theme_color_override("font_color", UIKit.SKY)
	MenuStyle.play_ui(self, &"toast", -8.0)
	_hint_tween = create_tween()
	_hint_tween.tween_interval(2.6)
	_hint_tween.tween_callback(func() -> void:
		_hint.text = _page_hint()
		_hint.add_theme_color_override("font_color", UIKit.TEXT_DIM))


func _settings() -> Node:
	return settings if settings else UIKit.settings_node()


# --- Parçalar -------------------------------------------------------------------------------------

## Üstteki ve alttaki koyu şeritler, her birinin altın çizgisiyle.
class Strip extends Control:
	var top := true

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var a := Color(0.008, 0.012, 0.022, 0.94)
		var b := Color(0.01, 0.016, 0.03, 0.55)
		var cols := PackedColorArray([a, a, b, b]) if top else PackedColorArray([b, b, a, a])
		draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, 0), r.end, Vector2(0, r.end.y)]), cols)
		var y := size.y - 1.0 if top else 1.0
		var cx := size.x * 0.5
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(UIKit.GOLD, 0.16), 1.0)
		draw_line(Vector2(cx - 640, y), Vector2(cx + 640, y), Color(UIKit.GOLD, 0.55), 1.5, true)
		var d := 7.0
		draw_colored_polygon(PackedVector2Array([Vector2(cx, y - d), Vector2(cx + d, y), Vector2(cx, y + d), Vector2(cx - d, y)]), UIKit.GOLD)
		draw_colored_polygon(PackedVector2Array([Vector2(cx, y - 3), Vector2(cx + 3, y), Vector2(cx, y + 3), Vector2(cx - 3, y)]), UIKit.SKY)


## Çubuktaki bir sayfa: sayfanın simgesi olan bir elmas, altında adı; açık sayfa altın yanar.
class TabButton extends Button:
	var glyph := ""
	var text_label := ""
	var active := false

	func _init(g: String) -> void:
		glyph = g
		custom_minimum_size = Vector2(176, 92)
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var empty := StyleBoxEmpty.new()
		for st in ["normal", "hover", "focus", "pressed", "disabled", "hover_pressed"]:
			add_theme_stylebox_override(st, empty)
		mouse_entered.connect(func() -> void:
			MenuStyle.play_ui(self, &"hover")
			queue_redraw())
		mouse_exited.connect(queue_redraw)

	func _draw() -> void:
		var hot := is_hovered()
		var c := Vector2(size.x * 0.5, 30.0)
		var col := UIKit.GOLD if active else (UIKit.SKY if hot else Color(UIKit.TEXT_DIM, 0.85))
		var r := 21.0
		var dia := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
		if active:
			draw_circle(c, 34.0, Color(UIKit.GOLD, 0.1))
			draw_colored_polygon(dia, Color(UIKit.GOLD, 0.9))
		else:
			draw_colored_polygon(dia, Color(0.03, 0.04, 0.06, 0.9))
		dia.append(dia[0])
		draw_polyline(dia, col, 2.0, true)
		GameMenu.draw_glyph(self, glyph, c, 10.0, Color(0.05, 0.05, 0.07) if active else col)
		var f := UIKit.font("Cinzel", 700, 2)
		var fs := 19
		var w := f.get_string_size(text_label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(f, Vector2((size.x - w) * 0.5, 78.0), text_label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		if active:
			draw_line(Vector2(size.x * 0.5 - w * 0.5, 87.0), Vector2(size.x * 0.5 + w * 0.5, 87.0), Color(UIKit.GOLD, 0.8), 2.0)


## Bir tuş kapağı ve yaptığı iş: "[F5] Kaydet". Tıklanabilir.
class KeyHint extends Button:
	var key := ""
	var what := ""

	func _init(k: String, what_text: String) -> void:
		key = k
		what = what_text
		focus_mode = Control.FOCUS_NONE
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var empty := StyleBoxEmpty.new()
		for st in ["normal", "hover", "focus", "pressed", "disabled", "hover_pressed"]:
			add_theme_stylebox_override(st, empty)
		mouse_entered.connect(queue_redraw)
		mouse_exited.connect(queue_redraw)

	## Butonlar kendi en küçük boylarını tutar; genişlik elle verilir.
	func refresh() -> void:
		var w := GameMenu.keycap_width(key) + 10.0
		if what != "":
			w += UIKit.font("AlegreyaSC-Regular", 400).get_string_size(what, HORIZONTAL_ALIGNMENT_LEFT, -1, 21).x + 6.0
		custom_minimum_size = Vector2(w, 44)
		queue_redraw()

	func _draw() -> void:
		var hot := is_hovered() and not disabled
		var a := 0.35 if disabled else 1.0
		var kw := GameMenu.keycap_width(key)
		var y := size.y * 0.5
		GameMenu.draw_keycap(self, Rect2(Vector2(0, y - 17), Vector2(kw, 34)), key, hot, a)
		if what != "":
			var f := UIKit.font("AlegreyaSC-Regular", 400)
			draw_string(f, Vector2(kw + 10.0, y + 7.0), what, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color(UIKit.SKY if hot else UIKit.PARCHMENT, a))


static func keycap_width(key: String) -> float:
	var f := UIKit.font("Cinzel", 700)
	return maxf(34.0, f.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x + 20.0)


## Bir tuş kapağı: koyu taş, altın kenar, içinde tuşun adı.
static func draw_keycap(ci: CanvasItem, r: Rect2, key: String, hot := false, alpha := 1.0) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(0, 3), r.size), Color(0, 0, 0, 0.5 * alpha), true)
	ci.draw_rect(r, Color(0.06, 0.07, 0.1, 0.95 * alpha), true)
	ci.draw_rect(r.grow(-1.0), Color(UIKit.SKY if hot else UIKit.GOLD_DIM, alpha), false, 1.6)
	ci.draw_line(r.position + Vector2(3, 3), Vector2(r.end.x - 3, r.position.y + 3), Color(1, 1, 1, 0.08 * alpha), 1.0)
	var f := UIKit.font("Cinzel", 700)
	var fs := 17
	var w := f.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	ci.draw_string(f, Vector2(r.get_center().x - w * 0.5, r.get_center().y + 6.0), key, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(UIKit.SKY if hot else UIKit.GOLD, alpha))


## Sekmelerdeki küçük işaretler, çizgilerle çizilir.
static func draw_glyph(ci: CanvasItem, kind: String, c: Vector2, s: float, col: Color) -> void:
	match kind:
		"people":
			ci.draw_arc(c + Vector2(-s * 0.4, -s * 0.35), s * 0.32, 0, TAU, 14, col, 1.5, true)
			ci.draw_arc(c + Vector2(s * 0.4, -s * 0.35), s * 0.32, 0, TAU, 14, col, 1.5, true)
			ci.draw_arc(c + Vector2(-s * 0.4, s * 0.75), s * 0.6, PI, TAU, 12, col, 1.5, true)
			ci.draw_arc(c + Vector2(s * 0.4, s * 0.75), s * 0.6, PI, TAU, 12, col, 1.5, true)
		"keys":
			ci.draw_rect(Rect2(c - Vector2(s, s * 0.65), Vector2(s * 2.0, s * 1.3)), col, false, 1.5)
			for k in 3:
				ci.draw_rect(Rect2(c + Vector2(-s * 0.75 + k * s * 0.55, -s * 0.35), Vector2(s * 0.38, s * 0.3)), col, true)
			ci.draw_line(c + Vector2(-s * 0.5, s * 0.3), c + Vector2(s * 0.5, s * 0.3), col, 1.6)
		"gear":
			ci.draw_arc(c, s * 0.55, 0, TAU, 20, col, 1.6, true)
			for k in 8:
				var d := Vector2.from_angle(TAU * k / 8.0)
				ci.draw_line(c + d * s * 0.62, c + d * s, col, 2.0, true)
			ci.draw_circle(c, s * 0.18, col)
		"home":
			# keçe bir yurt: kubbe ve kapı
			ci.draw_arc(c + Vector2(0, s * 0.25), s * 0.95, PI, TAU, 18, col, 1.6, true)
			ci.draw_line(c + Vector2(-s * 0.95, s * 0.25), c + Vector2(-s * 0.95, s * 0.85), col, 1.6, true)
			ci.draw_line(c + Vector2(s * 0.95, s * 0.25), c + Vector2(s * 0.95, s * 0.85), col, 1.6, true)
			ci.draw_line(c + Vector2(-s * 0.95, s * 0.85), c + Vector2(s * 0.95, s * 0.85), col, 1.6, true)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.22, s * 0.3), Vector2(s * 0.44, s * 0.55)), col, false, 1.4)
			ci.draw_line(c + Vector2(0, -s * 0.7), c + Vector2(0, -s), col, 1.6, true)
		"map":
			# katlanmış bir harita: üç dilim, içinde kesik bir yol ve baklava
			var m := PackedVector2Array([c + Vector2(-s, -s * 0.75), c + Vector2(-s * 0.33, -s * 0.55), c + Vector2(s * 0.33, -s * 0.75),
				c + Vector2(s, -s * 0.55), c + Vector2(s, s * 0.75), c + Vector2(s * 0.33, s * 0.55), c + Vector2(-s * 0.33, s * 0.75),
				c + Vector2(-s, s * 0.55), c + Vector2(-s, -s * 0.75)])
			ci.draw_polyline(m, col, 1.6, true)
			ci.draw_line(c + Vector2(-s * 0.33, -s * 0.55), c + Vector2(-s * 0.33, s * 0.75), col, 1.2, true)
			ci.draw_line(c + Vector2(s * 0.33, -s * 0.75), c + Vector2(s * 0.33, s * 0.55), col, 1.2, true)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 0.62, -s * 0.28), c + Vector2(s * 0.8, -s * 0.1), c + Vector2(s * 0.62, s * 0.08), c + Vector2(s * 0.44, -s * 0.1)]), col)
		"quest":
			# asılı bir sancak: çubuk, kırlangıç kuyruklu kumaş, ortasında baklava
			ci.draw_line(c + Vector2(-s * 0.75, -s * 0.85), c + Vector2(s * 0.75, -s * 0.85), col, 1.8, true)
			var flag := PackedVector2Array([c + Vector2(-s * 0.55, -s * 0.85), c + Vector2(-s * 0.55, s * 0.9), c + Vector2(0, s * 0.5),
				c + Vector2(s * 0.55, s * 0.9), c + Vector2(s * 0.55, -s * 0.85)])
			ci.draw_polyline(flag, col, 1.6, true)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 0.38), c + Vector2(s * 0.24, -s * 0.12), c + Vector2(0, s * 0.14), c + Vector2(-s * 0.24, -s * 0.12)]), col)
		"speech":
			ci.draw_arc(c + Vector2(0, -s * 0.1), s * 0.8, 0, TAU, 22, col, 1.6, true)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.35, s * 0.55), c + Vector2(-s * 0.7, s * 1.0), c + Vector2(-s * 0.05, s * 0.65)]), col)
		"stone":
			# dikili bir taş: yuvarlak tepeli gövde, üstünde oyulmuş bir halka
			var body := PackedVector2Array()
			for k in 13:
				var a := PI + PI * k / 12.0
				body.append(c + Vector2(cos(a) * s * 0.55, -s * 0.35 + sin(a) * s * 0.6))
			body.append(c + Vector2(s * 0.62, s))
			body.append(c + Vector2(-s * 0.62, s))
			body.append(body[0])
			ci.draw_polyline(body, col, 1.6, true)
			ci.draw_arc(c + Vector2(0, -s * 0.2), s * 0.22, 0, TAU, 12, col, 1.4, true)
			ci.draw_line(c + Vector2(-s * 0.3, s * 0.35), c + Vector2(s * 0.3, s * 0.35), col, 1.4, true)
		"monitor":
			ci.draw_rect(Rect2(c - Vector2(s, s * 0.75), Vector2(s * 2.0, s * 1.3)), col, false, 1.6)
			ci.draw_line(c + Vector2(0, s * 0.55), c + Vector2(0, s * 0.85), col, 1.6)
			ci.draw_line(c + Vector2(-s * 0.45, s * 0.9), c + Vector2(s * 0.45, s * 0.9), col, 1.8)
		"speaker":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 0.9, -s * 0.3), c + Vector2(-s * 0.45, -s * 0.3), c + Vector2(0, -s * 0.8), c + Vector2(0, s * 0.8), c + Vector2(-s * 0.45, s * 0.3), c + Vector2(-s * 0.9, s * 0.3)]), col)
			ci.draw_arc(c + Vector2(s * 0.1, 0), s * 0.45, -0.9, 0.9, 10, col, 1.5, true)
			ci.draw_arc(c + Vector2(s * 0.1, 0), s * 0.85, -0.9, 0.9, 12, col, 1.5, true)
		"list":
			for k in 3:
				var y := (k - 1) * s * 0.6
				ci.draw_circle(c + Vector2(-s * 0.8, y), s * 0.13, col)
				ci.draw_line(c + Vector2(-s * 0.5, y), c + Vector2(s, y), col, 1.8, true)
		"keyboard":
			ci.draw_rect(Rect2(c - Vector2(s * 1.2, s * 0.7), Vector2(s * 2.4, s * 1.4)), col, false, 1.6)
			for row in 2:
				for k in 5:
					ci.draw_rect(Rect2(c + Vector2(-s * 0.98 + k * s * 0.42, -s * 0.48 + row * s * 0.42), Vector2(s * 0.28, s * 0.26)), col, true)
			ci.draw_line(c + Vector2(-s * 0.6, s * 0.42), c + Vector2(s * 0.6, s * 0.42), col, 2.0)
		"pad":
			var pad_body := PackedVector2Array()
			for k in 25:
				var a := TAU * k / 24.0
				var v := Vector2(cos(a) * s * 1.25, sin(a) * s * 0.62)
				if sin(a) > 0.0:
					v.y += absf(cos(a)) * s * 0.45
				pad_body.append(c + v)
			ci.draw_polyline(pad_body, col, 1.6, true)
			ci.draw_line(c + Vector2(-s * 0.85, -s * 0.05), c + Vector2(-s * 0.45, -s * 0.05), col, 1.6)
			ci.draw_line(c + Vector2(-s * 0.65, -s * 0.25), c + Vector2(-s * 0.65, s * 0.15), col, 1.6)
			ci.draw_circle(c + Vector2(s * 0.55, -s * 0.2), s * 0.12, col)
			ci.draw_circle(c + Vector2(s * 0.8, s * 0.02), s * 0.12, col)
		"sun":
			# güneş: daire ve sekiz ışın (Tanrılar ve Ruhlar, «Gök ve Yer»)
			ci.draw_arc(c, s * 0.45, 0, TAU, 20, col, 1.6, true)
			for k in 8:
				var d := Vector2.from_angle(TAU * k / 8.0)
				ci.draw_line(c + d * s * 0.66, c + d * s * (1.0 if k % 2 == 0 else 0.86), col, 1.6, true)
		"bow":
			# gerili bir yay ve oku (Mete ve Soyu)
			ci.draw_arc(c + Vector2(s * 0.35, 0), s * 0.95, PI * 0.62, PI * 1.38, 16, col, 1.8, true)
			var tip_a := c + Vector2(s * 0.35, 0) + Vector2.from_angle(PI * 0.62) * s * 0.95
			var tip_b := c + Vector2(s * 0.35, 0) + Vector2.from_angle(PI * 1.38) * s * 0.95
			ci.draw_line(tip_a, tip_b, col, 1.0, true)
			ci.draw_line(c + Vector2(-s * 0.75, 0), c + Vector2(s * 0.95, 0), col, 1.4, true)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(s * 1.0, 0), c + Vector2(s * 0.7, -s * 0.18), c + Vector2(s * 0.7, s * 0.18)]), col)
		"yurt":
			# keçe yurt: kubbe, duvar ve kapı (Hun Ordası)
			ci.draw_arc(c + Vector2(0, s * 0.1), s * 0.95, PI, TAU, 18, col, 1.6, true)
			ci.draw_line(c + Vector2(-s * 0.95, s * 0.1), c + Vector2(-s * 0.95, s * 0.8), col, 1.6, true)
			ci.draw_line(c + Vector2(s * 0.95, s * 0.1), c + Vector2(s * 0.95, s * 0.8), col, 1.6, true)
			ci.draw_line(c + Vector2(-s * 1.1, s * 0.8), c + Vector2(s * 1.1, s * 0.8), col, 1.6, true)
			ci.draw_line(c + Vector2(-s * 0.95, s * 0.1), c + Vector2(s * 0.95, s * 0.1), col, 1.2, true)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.2, s * 0.32), Vector2(s * 0.4, s * 0.48)), col, false, 1.3)
			ci.draw_circle(c + Vector2(0, -s * 0.85), s * 0.12, col)
		"tower":
			# mazgallı kule (Ç'in ve Han)
			var base := PackedVector2Array([c + Vector2(-s * 0.55, s), c + Vector2(-s * 0.55, -s * 0.45), c + Vector2(-s * 0.75, -s * 0.45), c + Vector2(-s * 0.75, -s), c + Vector2(-s * 0.4, -s), c + Vector2(-s * 0.4, -s * 0.75), c + Vector2(-s * 0.12, -s * 0.75), c + Vector2(-s * 0.12, -s), c + Vector2(s * 0.12, -s), c + Vector2(s * 0.12, -s * 0.75), c + Vector2(s * 0.4, -s * 0.75), c + Vector2(s * 0.4, -s), c + Vector2(s * 0.75, -s), c + Vector2(s * 0.75, -s * 0.45), c + Vector2(s * 0.55, -s * 0.45), c + Vector2(s * 0.55, s), c + Vector2(-s * 0.55, s)])
			ci.draw_polyline(base, col, 1.5, true)
			ci.draw_rect(Rect2(c + Vector2(-s * 0.18, s * 0.45), Vector2(s * 0.36, s * 0.55)), col, false, 1.3)
		"cube":
			# 3B model
			var top := PackedVector2Array([c + Vector2(0, -s), c + Vector2(s * 0.9, -s * 0.5), c + Vector2(0, 0), c + Vector2(-s * 0.9, -s * 0.5), c + Vector2(0, -s)])
			ci.draw_polyline(top, col, 1.5, true)
			ci.draw_line(c + Vector2(-s * 0.9, -s * 0.5), c + Vector2(-s * 0.9, s * 0.5), col, 1.5, true)
			ci.draw_line(c + Vector2(s * 0.9, -s * 0.5), c + Vector2(s * 0.9, s * 0.5), col, 1.5, true)
			ci.draw_line(c, c + Vector2(0, s), col, 1.5, true)
			ci.draw_line(c + Vector2(-s * 0.9, s * 0.5), c + Vector2(0, s), col, 1.5, true)
			ci.draw_line(c + Vector2(s * 0.9, s * 0.5), c + Vector2(0, s), col, 1.5, true)
		"horse":
			# yandan bir at başı
			var pts := PackedVector2Array([c + Vector2(-s * 0.2, s), c + Vector2(-s * 0.35, -s * 0.1), c + Vector2(-s * 0.1, -s * 0.75), c + Vector2(0, -s), c + Vector2(s * 0.12, -s * 0.72), c + Vector2(s * 0.85, -s * 0.15), c + Vector2(s * 0.75, s * 0.15), c + Vector2(s * 0.2, s * 0.05), c + Vector2(s * 0.45, s)])
			ci.draw_polyline(pts, col, 1.6, true)
			ci.draw_circle(c + Vector2(s * 0.15, -s * 0.35), s * 0.09, col)
		_:
			ci.draw_circle(c, s * 0.3, col)
