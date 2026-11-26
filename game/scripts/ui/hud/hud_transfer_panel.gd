class_name HudTransferPanel
extends RefCounted
## Aktarma paneli (economy.md §4.6; economy/inventory-load «Aktarma»): Envanter'in (HudInventoryScreen) ikinci sekmesi. İki sütun:
## solda kap (bugün yakındaki atın terkisi; sonra sandık, Menzil Ambarı, ambar: E ile açılan her kap), sağda Heybe; ekranın penceresi,
## başlığı ve alt şeridi aynıdır, kitabın dili sürer (koyu yuva, soluk altın kenar, seçilide sıcak zemin, üzerine gelince gök mavisi).
## Tık bir yığını öbür sütuna taşır, Shift ya da sağ tık bir tanesini; sürükleyip öbür kartta bırakmak da taşır. Kabın almadığı eşya
## soluk görünür: «Bu kap bunu almaz»; sığmayan kalır: «Terki dolu», «Yük dolu». Hızlı düğmeler alt çekmecededir: Sırtı Boşalt
## (tag:bulk), Malzemeyi Bırak (Zanaat), Yiyeceği Bırak (Erzak), Hepsini Al; Eksikleri Al yalnız istenen bir liste varken (need).
## Klavye: oklar seçer, Sekme (Tab) sütun değiştirir, Enter taşır (Shift ile bir tane). Oyun ve saat duraklıdır (GameplayHud).
## Panel bir Control değildir: ekran çizer ve girdiyi iletir (draw, gui_input, key_input).

## Sütunların kartları ve ızgaraları (ekranın kartlarıyla aynı yer; sol ızgara kartında ortalı).
const LEFT_BOX := Rect2(32.0, 124.0, 620.0, 556.0)
const RIGHT_BOX := Rect2(676.0, 124.0, 692.0, 556.0)
const LEFT_GRID := Vector2(58.0, 198.0)
const RIGHT_GRID := Vector2(738.0, 198.0)
const COLS := 5
const ROWS := 4
const CELL := 104.0
const GAP := 12.0
## Alt çekmece (ekranın çekmecesiyle aynı yer) ve hızlı düğmeler (iki satır, iki sütun).
const DRAWER := Rect2(0.0, 756.0, 1400.0, 156.0)
const QUICK_AT := Vector2(870.0, 776.0)
const QUICK_SIZE := Vector2(236.0, 50.0)
const QUICK_STEP := Vector2(250.0, 62.0)
## Hızlı düğmeler: [iş, Türkçe, İngilizce, simge].
const QUICK: Array = [["unload_back", "Sırtı Boşalt", "Unload Back", "icon_weight"], ["store_materials", "Malzemeyi Bırak", "Store Materials", "icon_mortar"],
	["store_food", "Yiyeceği Bırak", "Store Food", "icon_herb"], ["take_all", "Hepsini Al", "Take All", "icon_bag"]]
## Sürüklemenin başladığı uzaklık (px) ve durum yazısının ekranda kaldığı süre (sn).
const DRAG_START := 6.0
const STATUS_HOLD := 3.0

var inventory: Inventory
## Sesleri çalan düğüm (ekran).
var host: Node
## Kap ve başlığı («TERKİ · DORU»).
var target: ItemContainer
var title := ""
## Eksikleri Al'ın listesi ([{id, n}]; boşsa düğme yok).
var need: Array = []
## Seçim: sütun ("left" kap, "right" heybe) ve sırası.
var focus := "right"
var selected := -1

var _hover_side := ""
var _hover_index := -1
var _hover_quick := -1
var _scroll := {"left": 0, "right": 0}
var _press_side := ""
var _press_index := -1
var _press_at := Vector2.ZERO
var _dragging := false
var _mouse := Vector2.ZERO
var _status := ""
var _status_warn := false
var _status_left := 0.0


func _init(p_inventory: Inventory, p_target: ItemContainer, p_title: String) -> void:
	inventory = p_inventory
	target = p_target
	title = p_title


static func lang() -> String:
	return SubtitleBar.ui_lang()


func _play(kind: StringName, volume_db := -6.0) -> void:
	MenuStyle.play_ui(host, kind, volume_db)


# --- Satırlar ----------------------------------------------------------------------------------------------------------

func _box(side: String) -> ItemContainer:
	return target if side == "left" else inventory.pack


func _other(side: String) -> String:
	return "right" if side == "left" else "left"


## Sütunun hücreleri: yığın yığın [{id, n}] (bir hücre bir yığın).
func cells(side: String) -> Array:
	var out: Array = []
	var box := _box(side)
	if box == null:
		return out
	for it: Dictionary in box.list():
		var item_id := str(it["id"])
		var left := int(it["n"])
		var st := ItemCatalog.stack(item_id)
		while left > 0:
			var k := mini(left, st)
			out.append({"id": item_id, "n": k})
			left -= k
	return out


static func cell_rect(side: String, i: int) -> Rect2:
	var at := LEFT_GRID if side == "left" else RIGHT_GRID
	return Rect2(at + Vector2(i % COLS, i / COLS) * (CELL + GAP), Vector2(CELL, CELL))


static func quick_rect(i: int) -> Rect2:
	return Rect2(QUICK_AT + Vector2((i % 2) * QUICK_STEP.x, (i / 2) * QUICK_STEP.y), QUICK_SIZE)


## Hızlı düğmeler (Eksikleri Al yalnız liste varken).
func quick_buttons() -> Array:
	var out: Array = QUICK.duplicate()
	if not need.is_empty():
		out.append(["take_missing", "Eksikleri Al", "Take What's Missing", "icon_swap"])
	return out


## Bu yığın öbür sütuna gidebilir mi (kabın kabul süzgeci)? Heybe her şeyi alır.
func accepted(side: String, item_id: String) -> bool:
	return _box(_other(side)).accepts(item_id)


func _cell_at(p: Vector2) -> Array:
	for side: String in ["left", "right"]:
		for i in COLS * ROWS:
			if cell_rect(side, i).has_point(p):
				return [side, i + int(_scroll[side]) * COLS]
	return []


func _side_at(p: Vector2) -> String:
	if LEFT_BOX.has_point(p):
		return "left"
	if RIGHT_BOX.has_point(p):
		return "right"
	return ""


# --- İşler -------------------------------------------------------------------------------------------------------------

## side sütunundaki index'inci yığını öbür sütuna taşır (one: bir tane). Dönüş: taşınan adet.
func move_cell(side: String, index: int, one := false) -> int:
	var list := cells(side)
	if index < 0 or index >= list.size():
		return 0
	var it: Dictionary = list[index]
	var item_id := str(it["id"])
	var from := _box(side)
	var to := _box(_other(side))
	if not to.accepts(item_id):
		_say(HudBag.message("refuses"), true)
		return 0
	var r := inventory.move(from, to, item_id, 1 if one else int(it["n"]))
	var moved := int(r["moved"])
	if moved <= 0:
		_say(_full_message(to, item_id), true)
		return 0
	var name := ItemCatalog.name_of(item_id, lang())
	var dest := title.capitalize() if to == target else ItemContainer.kind_name("pack", lang())
	_say("%s × %d → %s" % [name, moved, dest], false)
	if moved < (1 if one else int(it["n"])):
		_say("%s × %d → %s · %s" % [name, moved, dest, _full_message(to, item_id)], true)
	return moved


func _full_message(to: ItemContainer, item_id: String) -> String:
	if to == inventory.pack:
		var why := inventory.refuse_reason(item_id)
		return HudBag.message(why if not why.is_empty() else "pack_full")
	return HudBag.message("saddlebags_full" if to.kind == "saddlebags" else "store_full")


## Hızlı düğme. Dönüş: taşınan toplam.
func quick(action: String) -> int:
	var r := {}
	match action:
		"unload_back":
			r = inventory.unload_back(target)
		"store_materials":
			r = inventory.store_materials(target)
		"store_food":
			r = inventory.store_food(target)
		"take_all":
			r = inventory.take_all(target)
		"take_missing":
			r = inventory.take_missing(target, need)
	var n := 0
	for it: Dictionary in r.get("moved", []):
		n += int(it["n"])
	var label := _quick_label(action)
	var rest: Array = r.get("rest", [])
	if n > 0 and rest.is_empty():
		_say("%s: %d" % [label, n], false)
	elif rest.is_empty():
		_say("%s: 0" % label, false)
	else:
		var to := inventory.pack if action.begins_with("take") else target
		var first := str(rest[0]["id"])
		var why := HudBag.message("refuses") if not to.accepts(first) else _full_message(to, first)
		_say(("%s: %d · %s" % [label, n, why]) if n > 0 else why, true)
	return n


func _quick_label(action: String) -> String:
	for q: Array in quick_buttons():
		if q[0] == action:
			return str(q[2] if lang() == "en" else q[1])
	return action


func _say(text: String, warn: bool) -> void:
	_status = text
	_status_warn = warn
	_status_left = STATUS_HOLD


## Son durum yazısı (sınama).
func status() -> String:
	return _status


## Sürenin akışı (duraklıyken de; ekranın _process'i). Dönüş: yeniden çizilsin mi.
func process(delta: float) -> bool:
	if _status_left <= 0.0:
		return false
	_status_left -= delta
	if _status_left <= 0.0:
		_status = ""
		return true
	return false


# --- Girdi -------------------------------------------------------------------------------------------------------------

## Fare (panoya göre). Dönüş: iş yapıldı ya da durum değişti (yeniden çiz).
func gui_input(event: InputEvent) -> bool:
	if event is InputEventMouseMotion:
		_mouse = (event as InputEventMouseMotion).position
		var c := _cell_at(_mouse)
		var hs := str(c[0]) if not c.is_empty() else ""
		var hi := int(c[1]) if not c.is_empty() else -1
		var hq := -1
		for i in quick_buttons().size():
			if quick_rect(i).has_point(_mouse):
				hq = i
		if not _press_side.is_empty() and _press_at.distance_to(_mouse) > DRAG_START:
			_dragging = true
		var changed := hs != _hover_side or hi != _hover_index or hq != _hover_quick or _dragging
		if changed and ((hi >= 0 and hi < cells(hs).size() and (hs != _hover_side or hi != _hover_index)) or (hq >= 0 and hq != _hover_quick)):
			_play(&"hover", -10.0)
		_hover_side = hs
		_hover_index = hi
		_hover_quick = hq
		return changed
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if not mb.pressed:
				return false
			var side := _side_at(mb.position)
			return not side.is_empty() and scroll(side, -1 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1)
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			for i in quick_buttons().size():
				if quick_rect(i).has_point(mb.position):
					_play(&"click")
					quick(str(quick_buttons()[i][0]))
					return true
			var c := _cell_at(mb.position)
			if c.is_empty() or int(c[1]) >= cells(str(c[0])).size():
				_press_side = ""
				return false
			_press_side = str(c[0])
			_press_index = int(c[1])
			_press_at = mb.position
			focus = _press_side
			selected = _press_index
			return true
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed and not _press_side.is_empty():
			var from_side := _press_side
			var index := _press_index
			var drag := _dragging
			_press_side = ""
			_dragging = false
			if drag:
				var to_side := _side_at(mb.position)
				if to_side.is_empty() or to_side == from_side:
					return true
			var c := _cell_at(mb.position)
			if not drag and (c.is_empty() or str(c[0]) != from_side or int(c[1]) != index):
				return true
			var moved := move_cell(from_side, index, mb.shift_pressed)
			_play(&"click" if moved > 0 else &"deny")
			_clamp_selection()
			return true
		if mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			var c := _cell_at(mb.position)
			if c.is_empty():
				return false
			var moved := move_cell(str(c[0]), int(c[1]), true)
			_play(&"click" if moved > 0 else &"deny")
			_clamp_selection()
			return true
	return false


## Klavye. Dönüş: işlendi mi.
func key_input(event: InputEvent) -> bool:
	if _pressed(event, &"ui_focus_next") or _pressed(event, &"ui_focus_prev"):
		focus = _other(focus)
		selected = 0 if not cells(focus).is_empty() else -1
		_play(&"hover")
		return true
	if _pressed(event, &"ui_accept"):
		var shift := event is InputEventKey and (event as InputEventKey).shift_pressed
		var moved := move_cell(focus, selected, shift)
		_play(&"click" if moved > 0 else &"deny")
		_clamp_selection()
		return true
	var step := 0
	if _pressed(event, &"ui_right") or _pressed(event, &"move_right"):
		step = 1
	elif _pressed(event, &"ui_left") or _pressed(event, &"move_left"):
		step = -1
	elif _pressed(event, &"ui_down") or _pressed(event, &"move_back"):
		step = COLS
	elif _pressed(event, &"ui_up") or _pressed(event, &"move_forward"):
		step = -COLS
	var n := cells(focus).size()
	if step == 0 or n == 0:
		return false
	selected = 0 if selected < 0 else clampi(selected + step, 0, n - 1)
	_keep_visible(focus, selected)
	_play(&"hover")
	return true


## Satır satır kaydırır. Dönüş: kaydı mı.
func scroll(side: String, rows: int) -> bool:
	var total := ceili(cells(side).size() / float(COLS))
	var want := clampi(int(_scroll[side]) + rows, 0, maxi(0, total - ROWS))
	if want == int(_scroll[side]):
		return false
	_scroll[side] = want
	return true


func _keep_visible(side: String, index: int) -> void:
	var row := index / COLS
	if row < int(_scroll[side]):
		_scroll[side] = row
	elif row >= int(_scroll[side]) + ROWS:
		_scroll[side] = row - ROWS + 1


func _clamp_selection() -> void:
	var n := cells(focus).size()
	selected = mini(selected, n - 1)
	for side: String in ["left", "right"]:
		scroll(side, 0)
		var total := ceili(cells(side).size() / float(COLS))
		_scroll[side] = clampi(int(_scroll[side]), 0, maxi(0, total - ROWS))


# --- Çizim -------------------------------------------------------------------------------------------------------------

func draw(ci: Control) -> void:
	_draw_card(ci, "left", LEFT_BOX, title, target)
	_draw_card(ci, "right", RIGHT_BOX, ItemContainer.kind_name("pack", lang()).to_upper(), inventory.pack)
	_draw_drawer(ci)
	if _dragging and not _press_side.is_empty():
		var list := cells(_press_side)
		if _press_index < list.size():
			HudItemIcon.draw(ci, str(list[_press_index]["id"]), _mouse, CELL * 0.6, Color(1, 1, 1, 0.85))


func _draw_card(ci: Control, side: String, box: Rect2, head: String, c: ItemContainer) -> void:
	HudJournalPage.draw_card(ci, box, head)
	# Kartın başlığının sağında Yük'ü: «12,5 / 50 Yük» ve ince çubuk.
	var lg := lang()
	var cap := inventory.capacity() if c == inventory.pack else c.cap()
	var carried := inventory.load_amount() if c == inventory.pack else c.load_amount()
	var text := "%s / %s" % [HudBag.yuk_text(carried, lg), HudBag.yuk_text(cap, lg) if cap != INF else "∞"]
	var nf := HudKit.number_font(600)
	var lf := UIKit.font("AlegreyaSC-Regular", 400, 1)
	var right := box.end.x - 30.0
	var label := "Yük" if lg == "tr" else "Load"
	var lw := lf.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	var tw := nf.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	ci.draw_string(lf, Vector2(right - lw, box.position.y + 46.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UIKit.TEXT_DIM)
	var frac := CarryLoad.frac(carried, cap) if cap != INF else 0.0
	ci.draw_string(nf, Vector2(right - lw - 10.0 - tw, box.position.y + 47.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, HudInventoryScreen.load_color(frac))
	HudInventoryScreen.draw_load_bar(ci, Rect2(right - 150.0, box.position.y + 56.0, 150.0, 3.0), frac, c == inventory.pack)
	var list := cells(side)
	var first := int(_scroll[side]) * COLS
	for i in COLS * ROWS:
		var r := cell_rect(side, i)
		var index := first + i
		var active := focus == side and selected == index
		var hot := _hover_side == side and _hover_index == index and index < list.size()
		HudInventoryScreen._draw_slot_box(ci, r, hot, active)
		if index >= list.size():
			HudInventoryScreen._draw_empty_mark(ci, r.get_center(), 9.0)
			continue
		var it: Dictionary = list[index]
		var ok := accepted(side, str(it["id"]))
		var dim := 1.0 if ok else 0.38
		if _dragging and _press_side == side and _press_index == index:
			dim = 0.3
		HudItemIcon.draw(ci, str(it["id"]), r.get_center() + Vector2(0.0, -2.0), CELL * 0.68, Color(1, 1, 1, dim))
		if int(it["n"]) > 1:
			HudInventoryScreen._draw_count(ci, r, int(it["n"]))
	# Kaydırma: kartın sağ kenarında ince çubuk.
	var total := ceili(list.size() / float(COLS))
	if total > ROWS:
		var track := Rect2(box.end.x - 12.0, cell_rect(side, 0).position.y, 3.0, ROWS * (CELL + GAP) - GAP)
		ci.draw_rect(track, Color(UIKit.GOLD_DIM, 0.35))
		var h := track.size.y * ROWS / float(total)
		var y := track.position.y + (track.size.y - h) * int(_scroll[side]) / float(maxi(1, total - ROWS))
		ci.draw_rect(Rect2(track.position.x, y, track.size.x, h), Color(UIKit.GOLD, 0.8))
	if _dragging and _side_at(_mouse) == side and _press_side != side:
		ci.draw_rect(box.grow(-3.0), Color(UIKit.SKY, 0.7), false, 2.0)


## Alt çekmece: üzerine gelinen yığının adı ve ölçüsü (ya da son durum), hızlı düğmeler.
func _draw_drawer(ci: Control) -> void:
	ci.draw_style_box(UIKit.panel_style(HudInventoryScreen.WINDOW_BG, Color(UIKit.GOLD_DIM, 0.85), 1, 3, Color(0, 0, 0, 0.55), 22), DRAWER)
	var lg := lang()
	var shown := _shown_cell()
	var icon_c := Vector2(96.0, DRAWER.get_center().y)
	var icon_r := Rect2(icon_c - Vector2(56.0, 56.0), Vector2(112.0, 112.0))
	ci.draw_style_box(UIKit.panel_style(HudInventoryScreen.SLOT_ACTIVE_BG, Color(UIKit.GOLD, 1.0 if not shown.is_empty() else 0.4), 2, 3, Color(UIKit.GOLD, 0.18), 10), icon_r)
	var tx := 176.0
	var nf := UIKit.font("Cinzel", 700, 3)
	var bf := UIKit.font("Alegreya", 500)
	if not shown.is_empty():
		var item_id := str(shown["id"])
		HudItemIcon.draw(ci, item_id, icon_c, 112.0 * 0.72)
		var name_text := ItemCatalog.name_of(item_id, lg).to_upper()
		ci.draw_string(nf, Vector2(tx, 806.0), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, UIKit.GOLD)
		var w := nf.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
		if int(shown["n"]) > 1:
			ci.draw_string(HudKit.number_font(600), Vector2(tx + w + 14.0, 806.0), "× %d" % int(shown["n"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, UIKit.TEXT_DIM)
		ci.draw_line(Vector2(tx, 818.0), Vector2(tx + 600.0, 818.0), Color(UIKit.GOLD, 0.25), 1.0)
		ci.draw_string(UIKit.font("AlegreyaSC-Regular", 400, 1), Vector2(tx, 850.0), HudBag.meta_line(item_id, int(shown["n"]), lg), HORIZONTAL_ALIGNMENT_LEFT,
			-1, 19, UIKit.TEXT_DIM)
		var side := str(shown["side"])
		var line := HudBag.message("refuses") if not accepted(side, item_id) else (
			("Tık: yığını taşı · Shift ya da sağ tık: bir tane" if lg == "tr" else "Click: move the stack · Shift or right click: one"))
		ci.draw_string(bf, Vector2(tx, 882.0), line, HORIZONTAL_ALIGNMENT_LEFT, 600, 20, UIKit.EMBER if not accepted(side, item_id) else UIKit.PARCHMENT)
	else:
		HudInventoryScreen.draw_swap_glyph(ci, icon_c, 22.0, Color(UIKit.GOLD, 0.8))
		ci.draw_string(nf, Vector2(tx, 806.0), ("AKTARMA" if lg == "tr" else "TRANSFER"), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, UIKit.GOLD)
		ci.draw_line(Vector2(tx, 818.0), Vector2(tx + 600.0, 818.0), Color(UIKit.GOLD, 0.25), 1.0)
		var help := ("Bir yığına tıkla ya da sürükle: öbür sütuna geçer. Kabın almadığı soluk görünür." if lg == "tr"
			else "Click or drag a stack to send it across. What the store won't take is greyed out.")
		var y := 852.0
		for l in HudKit.wrap_lines(bf, help, 21, 600.0, 2):
			ci.draw_string(bf, Vector2(tx, y), l, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, UIKit.PARCHMENT)
			y += 28.0
	if not _status.is_empty():
		var a := clampf(_status_left / 0.4, 0.0, 1.0)
		var sf := UIKit.font("Alegreya", 600)
		ci.draw_string(sf, Vector2(tx, 742.0), _status, HORIZONTAL_ALIGNMENT_LEFT, 640, 20, Color(UIKit.EMBER if _status_warn else UIKit.SKY, a))
	# Ayraç ve hızlı düğmeler (kitabın seçme düğmeleri gibi).
	var vx := QUICK_AT.x - 26.0
	ci.draw_line(Vector2(vx, DRAWER.position.y + 22.0), Vector2(vx, DRAWER.end.y - 22.0), Color(UIKit.GOLD, 0.35), 1.0)
	var vc := Vector2(vx, DRAWER.get_center().y)
	ci.draw_colored_polygon(PackedVector2Array([vc + Vector2(0, -6), vc + Vector2(6, 0), vc + Vector2(0, 6), vc + Vector2(-6, 0)]), UIKit.GOLD)
	var buttons := quick_buttons()
	for i in buttons.size():
		var r := quick_rect(i)
		var hot := i == _hover_quick
		var col := UIKit.SKY if hot else UIKit.PARCHMENT
		ci.draw_style_box(UIKit.panel_style(HudInventoryScreen.SLOT_BG, col if hot else Color(UIKit.GOLD_DIM, 0.6), 1, 3, Color(0, 0, 0, 0.3), 6), r)
		HudKit.draw_icon(ci, str(buttons[i][3]), r.position + Vector2(28.0, r.size.y * 0.5), 28.0)
		ci.draw_string(UIKit.font("AlegreyaSC-Regular", 400, 1), Vector2(r.position.x + 52.0, r.get_center().y + 7.0),
			str(buttons[i][2] if lg == "en" else buttons[i][1]), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 58.0, 20, col)


## Çekmecede gösterilen yığın: üzerine gelinen, yoksa seçili ({id, n, side} ya da boş).
func _shown_cell() -> Dictionary:
	for pair: Array in [[_hover_side, _hover_index], [focus, selected]]:
		var side := str(pair[0])
		var index := int(pair[1])
		if side.is_empty() or index < 0:
			continue
		var list := cells(side)
		if index < list.size():
			var it: Dictionary = (list[index] as Dictionary).duplicate()
			it["side"] = side
			return it
	return {}


## Eylem tanımlıysa basıldı mı (tanımsız eylemi sormak motor hatası yazar; sınamalar InputSetup'sız kurar).
static func _pressed(event: InputEvent, action: StringName) -> bool:
	return InputMap.has_action(action) and event.is_action_pressed(action)
