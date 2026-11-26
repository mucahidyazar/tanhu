class_name HudInventoryScreen
extends HudScreen
## Envanter (I): yolculuğun kitabının üst menüsünün tasarım dilinde (menünün kendisi görünmez) geniş bir pencere; yan yana kanıt
## docs/media/review/hud2_envanter.jpg, gerçek envanterle docs/media/review/envanter_*.jpg. Başlık kitabın açık sekmesi gibidir: koyu
## şeritte altın dolu baklava ve içinde heybe işareti, altında harf aralıklı Cinzel «ENVANTER» ve altın alt çizgi; şeridin altında
## kitabın süs çizgisi. Yakında Yük'ü olan bir binek varsa (15 m; ya da E ile açılan bir kap: open_container) yanında ikinci sekme
## «TERKİ · DORU» belirir: aktarma paneli (HudTransferPanel). Q / E ya da tık sekme değiştirir. Şeridin solunda yuva (II'den kese),
## sağında Yük: «0,6 / 6 Yük» ve altında ince çubuk (yarıda zıplama, dörtte üçte koşu biter: çubuğun iki çentiği; renk ısınır).
##   sol kart «KUŞAM»   oynanan kişinin 3B, canlandırmalı (bekleme klibi) görseli; fareyle sürükleyince döner (CreatorTurntable ve
##                      EncyclopediaModelView'in kalıbı: kendi 3B dünyası olan saydam SubViewport). Kuşam yuvaları progression.md
##                      §6.1'in on yuvasıdır, iki yanda ayrı sütunlarda (sol baştan ayağa: baş, boyun, gövde, el, çizme; sağ: sırt, yay,
##                      sadak, kuşak, kılıç), karakterin üstüne değmez; boş yuvada yuvanın soluk işareti.
##   sağ kart «HEYBE»   başlığın sağında sekmeler (Hepsi, Sırt, Erzak, Zanaat, Araç, Hatıra; economy.md §4.2), beş sütun dört satır
##                      yuva; bir hücre bir yığındır (25 et: 10, 10, 5), fazlası tekerlekle ya da oklarla kayar.
##   alt                tuş ipuçları (kitabın alt şeridi gibi): Esc Kapat (tıklanır), Sol tık Seç, Sürükle Döndür, Q E Sekme; sağda son
##                      işin sonucu («Tarla Kuşu × 2 → Terki», «Yük dolu»).
## Yuvalar kitabın tuş kapakları ve seçme düğmeleri gibidir: koyu zemin, ince soluk altın kenar, 3 px köşe, aralarında 12 px; üzerine
## gelinen gök mavisi kenarlı, seçili sıcak zeminli ve iki piksel altın kenarlı; boş yuvada soluk bir baklava. Seçili eşyanın çekmecesi
## (simge, ad, sayı, ölçü satırı, yazı; Kuşan ya da Çıkar ya da Kullan, Taşı, Bırak; eşyanın o işi yoksa sönük) hep görünmez: yalnız bir
## eşya seçilince ya da üstüne gelinince pencerenin altında belirir (kısa solma ve kayma); boş kuşam yuvasının üstünde yuvanın adı.
## Veri HudBag'den (gerçek envanter: Inventory). Fare ya da ok tuşları seçer, Enter kuşanır ya da çıkarır, Sekme heybenin sekmesini
## değiştirir; boş yere tıklamak seçimi bırakır; Esc ya da I kapatır. Oyun durur (GameplayHud).

## Pencere (çekmece hariç) ve çekmece (pencerenin altında); panonun tamamı.
const SIZE := Vector2(1400.0, 740.0)
const DRAWER := Rect2(0.0, 756.0, 1400.0, 156.0)
const PANEL := Vector2(1400.0, 912.0)
## Başlık şeridinin yüksekliği, kartlar ve karakterin alanı.
const HEAD_H := 108.0
const LEFT_BOX := Rect2(32.0, 124.0, 620.0, 556.0)
const RIGHT_BOX := Rect2(676.0, 124.0, 692.0, 556.0)
const CHAR_RECT := Rect2(198.0, 190.0, 288.0, 480.0)
## Kuşam yuvaları: kimlik → [merkez, boy]; sol sütun x 110, sağ sütun x 574 (karakterin alanının dışında), aralık 92 px.
const EQUIP_SIZE := 80.0
const EQUIP_SLOTS := {
	"head": [Vector2(110.0, 248.0), 80.0], "neck": [Vector2(110.0, 340.0), 80.0], "body": [Vector2(110.0, 432.0), 80.0],
	"hands": [Vector2(110.0, 524.0), 80.0], "feet": [Vector2(110.0, 616.0), 80.0],
	"cape": [Vector2(574.0, 248.0), 80.0], "bow": [Vector2(574.0, 340.0), 80.0], "quiver": [Vector2(574.0, 432.0), 80.0],
	"belt": [Vector2(574.0, 524.0), 80.0], "blade": [Vector2(574.0, 616.0), 80.0],
}
## Eşya ızgarası: sütun, satır, yuva boyu, aralık ve ilk yuvanın sol üstü (sağ kartta ortalı).
const COLS := 5
const ROWS := 4
const CELL := 104.0
const GAP := 12.0
const GRID_AT := Vector2(738.0, 198.0)
## Heybenin sekmeleri: kartın başlık satırında, sağa yaslı; yazı boyu ve aralık.
const BAG_TAB_SIZE := 18
const BAG_TAB_GAP := 22.0
## Başlığın sekmeleri: baklavanın merkezi ve iki sekmenin aralığı.
const TAB_CENTER_Y := 36.0
const TAB_SPACING := 250.0
## Çekmece: simge yuvası, yazının başı ve genişliği, düğmeler (sağda yan yana).
const DETAIL_ICON := Vector2(96.0, 834.0)
const DETAIL_SLOT := 112.0
const TEXT_AT := Vector2(176.0, 806.0)
const TEXT_W := 600.0
const BUTTON_RECT := Rect2(830.0, 810.0, 168.0, 48.0)
const BUTTON_STEP := 180.0
## Düğmeler: [iş, yazı, simge]. İlk düğmenin yazısı eşyaya göre değişir (Kuşan, Çıkar, Kullan; satırın use_label'ı).
const BUTTONS: Array = [["use", "Kullan", "icon_mortar"], ["move", "Taşı", "icon_swap"], ["drop", "Bırak", "icon_trash"]]
## Kitabın renkleri (GameMenu.Strip, ControlsPage._card, ToggleButton).
const WINDOW_BG := Color(0.014, 0.02, 0.034, 0.97)
const CARD_BG := Color(0.022, 0.028, 0.042, 0.92)
const SLOT_BG := Color(0.03, 0.04, 0.06, 0.85)
const SLOT_ACTIVE_BG := Color(0.12, 0.09, 0.05, 0.9)
## 3B görselin kamerası (CreatorTurntable.full_frame) ve sürüklemenin piksel başına dönüşü.
const MODEL_FOV := 28.0
const MODEL_FILL := 0.86
const MODEL_CENTER := 0.53
const MODEL_ELEVATION := 7.0
const DRAG_SENSITIVITY := 0.0105
## Çekmecenin belirme hızı (1/sn) ve kayması (px); son işin yazısının ekranda kaldığı süre (sn).
const DRAWER_SPEED := 9.0
const DRAWER_SLIDE := 14.0
const STATUS_HOLD := 3.0

var bag: HudBag
## Oynanan kişi (ChildLook.PERSON_*; "" yetişkin) ve yetişkinin profili (3B görseli için).
var person := ""
var profile: CharacterProfile
## Seçili eşya: ("grid", sıra), ("equip", yuva) ya da ("", ...) seçim yok. Sıra heybenin o anki sekmesindeki yığının sırasıdır.
var selected_kind := ""
var selected_index := -1
var selected_slot := ""
## Açık sayfa: "bag" (kuşam ve heybe) ya da "transfer" (aktarma paneli); heybenin sekmesi.
var page := "bag"
var bag_tab := "all"

var _hover_kind := ""
var _hover_index := -1
var _hover_slot := ""
var _hover_button := -1
var _hover_close := false
var _hover_tab := -1
var _hover_bag_tab := -1
var _drawer_k := 0.0
var _scroll := 0
var _view: SubViewportContainer
var _viewport: SubViewport
var _pivot: Node3D
var _avatar: CharacterAvatar
## Çekmece kapanırken son gösterilen eşya (solarken yazısı kaybolmasın).
var _last_shown: Dictionary = {}
## Aktarma kabı ({container, title}; yoksa boş) ve paneli.
var _target: Dictionary = {}
var _transfer: HudTransferPanel
var _status := ""
var _status_warn := false
var _status_left := 0.0


func _init() -> void:
	super._init()
	kind = "bag"
	toggle_action = &"inventory"
	panel_size = PANEL
	framed = false


func _ready() -> void:
	super._ready()
	if _target.is_empty() and bag:
		_target = bag.transfer_target()
	_build_view()
	_dev_args()
	if bag and not bag.changed.is_connected(_on_bag_changed):
		bag.changed.connect(_on_bag_changed)


func _exit_tree() -> void:
	if bag and bag.changed.is_connected(_on_bag_changed):
		bag.changed.disconnect(_on_bag_changed)


func _on_bag_changed() -> void:
	panel().queue_redraw()


## Geliştirme (belge karesi): --inv-demo heybeye iki tarla kuşu ve bir kum faresi koyar (--inv-demo=full sekmelerin hepsine eşya ve
## kuşam); --inv-tab=food heybenin sekmesi; --inv-select=grid:0 ya da equip:bow o eşyayı seçer (çekmece açık); --inv-turn=derece
## karakteri döndürür; --inv-transfer aktarma sekmesini açar (=chest: denemelik bir sandıkla); --inv-move=lark o eşyayı aktarma kabına
## taşır; --inv-drop=gerbil o eşyayı oyuncunun önüne bırakır ve Envanter'i kapatır (yerdeki yığının karesi). Sıra: önce doldurma, sonra
## görünüm, sonra işler. Argüman yoksa bir şey yapmaz; geliştirme koşuları kayıt yazmaz.
func _dev_args() -> void:
	var args := OS.get_cmdline_user_args()
	if bag == null or not Array(args).any(func(a: String) -> bool: return a.begins_with("--inv-")):
		return
	for a in args:
		if a == "--inv-demo":
			bag.add("lark", 2)
			bag.add("gerbil", 1)
		elif a == "--inv-demo=full":
			_dev_fill(bag.inventory)
	for a in args:
		if a.begins_with("--inv-tab=") and HudBag.TABS.has(a.substr(10)):
			bag_tab = a.substr(10)
		elif a.begins_with("--inv-turn=") and a.substr(11).is_valid_float():
			turn_character(deg_to_rad(float(a.substr(11))) / DRAG_SENSITIVITY)
		elif a == "--inv-transfer=chest":
			var chest := ItemContainer.make("chest", {"id": "chest.dev"})
			for pair: Array in [["felt", 4], ["rope", 6], ["meal", 5], ["wood_pine", 3]]:
				chest.add(str(pair[0]), int(pair[1]))
			open_container(chest, "SANDIK" if HudBag.lang() == "tr" else "CHEST")
		elif a == "--inv-transfer" and not _target.is_empty():
			show_page("transfer")
	for a in args:
		if a.begins_with("--inv-move=") and not _target.is_empty():
			bag.inventory.move(bag.inventory.pack, _target["container"], a.substr(11), ItemContainer.ALL)
		elif a.begins_with("--inv-drop=") and bag.can_drop():
			bag.inventory.drop(a.substr(11), 1 << 20, bag.drop_point())
			close.call_deferred()
	for a in args:
		if a.begins_with("--inv-select="):
			var parts := a.substr(13).split(":")
			if parts.size() == 2 and parts[0] == "grid" and parts[1].is_valid_int():
				selected_kind = "grid"
				selected_index = int(parts[1])
			elif parts.size() == 2 and parts[0] == "equip":
				selected_kind = "equip"
				selected_slot = parts[1]
			elif parts.size() == 2 and parts[0] in ["left", "right"] and parts[1].is_valid_int() and _transfer:
				_transfer.focus = parts[0]
				_transfer.selected = int(parts[1])
			_drawer_k = 1.0 if drawer_visible() else 0.0
	panel().queue_redraw()


## Belge karesinin envanteri: her sekmeden eşya, kuşam (sınırı geçebilir: kare için).
static func _dev_fill(inv: Inventory) -> void:
	for pair: Array in [["wood_pine", 2], ["meal", 6], ["meat_small", 3], ["herb_wormwood", 4], ["berry_buckthorn", 12], ["rope", 5], ["felt", 3],
			["hide_small", 2], ["sinew", 4], ["arrow_bone", 18], ["notch_stick", 1]]:
		inv.add(str(pair[0]), int(pair[1]), "demo", true)
	inv.add("axe_bronze")
	inv.add("firestriker")
	for pair: Array in [["body", "hostage_coat"], ["cape", "cape_hostage"], ["feet", "felt_boots"], ["belt", "pouch_belt"], ["quiver", "quiver_farnak"]]:
		inv.equip(str(pair[0]), str(pair[1]))
	if inv.equipped("bow").is_empty():
		inv.equip("bow", "loan_bow")


## i. görünen ızgara yuvasının kutusu (panoya göre; saf).
static func cell_rect(i: int) -> Rect2:
	var col := i % COLS
	var row := i / COLS
	return Rect2(GRID_AT + Vector2(col, row) * (CELL + GAP), Vector2(CELL, CELL))


## Kuşam yuvasının kutusu (saf).
static func equip_rect(slot: String) -> Rect2:
	var def: Array = EQUIP_SLOTS.get(slot, [Vector2.ZERO, 0.0])
	var s: float = def[1]
	return Rect2((def[0] as Vector2) - Vector2(s, s) * 0.5, Vector2(s, s))


static func button_rect(i: int) -> Rect2:
	return Rect2(BUTTON_RECT.position + Vector2(BUTTON_STEP * i, 0.0), BUTTON_RECT.size)


## Kapatma ipucunun kutusu (alt şeritte, «Esc Kapat»).
static func close_rect() -> Rect2:
	return Rect2(Vector2(SIZE.x * 0.5 - 290.0, SIZE.y - 50.0), Vector2(150.0, 40.0))


## Başlığın sekmeleri: [{id, label}]; ikincisi yalnız aktarma kabı varken.
func top_tabs() -> Array:
	var out: Array = [{"id": "bag", "label": "ENVANTER" if HudBag.lang() == "tr" else "INVENTORY"}]
	if not _target.is_empty():
		out.append({"id": "transfer", "label": str(_target.get("title", "TERKİ"))})
	return out


## i. başlık sekmesinin baklavasının merkezi.
func tab_center(i: int) -> Vector2:
	var n := top_tabs().size()
	return Vector2(SIZE.x * 0.5 + (i - (n - 1) * 0.5) * TAB_SPACING, TAB_CENTER_Y)


func _tab_rect(i: int) -> Rect2:
	var c := tab_center(i)
	return Rect2(c - Vector2(110.0, 34.0), Vector2(220.0, 96.0))


## Heybenin sekmelerinin kutuları (kartın başlık satırında, sağa yaslı; HudBag.TABS sırasıyla).
func bag_tab_rects() -> Array:
	var f := UIKit.font("AlegreyaSC-Regular", 400, 1)
	var widths: Array = []
	var total := 0.0
	for t: String in HudBag.TABS:
		var w := f.get_string_size(ItemCatalog.label("tabs", t, HudBag.lang()), HORIZONTAL_ALIGNMENT_LEFT, -1, BAG_TAB_SIZE).x
		widths.append(w)
		total += w
	total += BAG_TAB_GAP * (HudBag.TABS.size() - 1)
	var x := RIGHT_BOX.end.x - 30.0 - total
	var out: Array = []
	for w: float in widths:
		out.append(Rect2(x - 4.0, RIGHT_BOX.position.y + 26.0, w + 8.0, 32.0))
		x += w + BAG_TAB_GAP
	return out


# --- Sayfalar ----------------------------------------------------------------------------------------------------------

## Sayfayı açar: "bag" ya da "transfer" (aktarma kabı yoksa açılmaz). Dönüş: açıldı mı.
func show_page(p: String) -> bool:
	if p == "transfer" and _target.is_empty():
		return false
	if p == page and (p != "transfer" or _transfer):
		return true
	page = p
	clear_selection()
	_hover_kind = ""
	_hover_index = -1
	_hover_slot = ""
	if p == "transfer":
		_transfer = HudTransferPanel.new(bag.inventory, _target["container"], str(_target.get("title", "")))
		_transfer.host = self
	else:
		_transfer = null
	if _view:
		_view.visible = p == "bag"
	MenuStyle.play_ui(self, &"page_turn", -12.0)
	panel().queue_redraw()
	return true


## E ile açılan bir kap (sandık, Menzil Ambarı, ambar): aktarma sekmesi bu kapla açılır.
func open_container(c: ItemContainer, title_text: String) -> void:
	_target = {"container": c, "title": title_text}
	page = "bag"
	show_page("transfer")


## Aktarma paneli (sınama; sekme kapalıyken null).
func transfer_panel() -> HudTransferPanel:
	return _transfer


# --- Seçim ------------------------------------------------------------------------------------------------------------

## Heybenin o anki sekmesinin yığınları.
func grid_entries() -> Array:
	return bag.grid(bag_tab) if bag else []


## Seçili eşyanın satırı (yoksa boş).
func selected_entry() -> Dictionary:
	return _entry(selected_kind, selected_index, selected_slot)


## Çekmecede gösterilen eşya: üzerine gelinen, yoksa seçili (yoksa boş).
func shown_entry() -> Dictionary:
	var h := _entry(_hover_kind, _hover_index, _hover_slot)
	return h if not h.is_empty() else selected_entry()


## Çekmece görünüyor mu (bir eşya seçili ya da üzerine gelinmiş; boş kuşam yuvasının üstünde yuvanın adı)?
func drawer_visible() -> bool:
	return page == "bag" and (not shown_entry().is_empty() or _empty_slot_hovered())


func _empty_slot_hovered() -> bool:
	return _hover_kind == "equip" and not _hover_slot.is_empty() and _entry("equip", -1, _hover_slot).is_empty()


func _entry(k: String, index: int, slot: String) -> Dictionary:
	if bag == null or page != "bag":
		return {}
	if k == "equip":
		return bag.equipped().get(slot, {})
	if k == "grid":
		var g := grid_entries()
		return g[index] if index >= 0 and index < g.size() else {}
	return {}


## Düğmenin işi çekmecedeki eşyada var mı (yoksa sönük)?
func action_enabled(action: String) -> bool:
	var e := shown_entry()
	return not e.is_empty() and (e.get("actions", []) as Array).has(action)


## Seçimi bırakır (çekmece kapanır).
func clear_selection() -> void:
	selected_kind = ""
	selected_index = -1
	selected_slot = ""
	panel().queue_redraw()


func _draw_footer(_ci: Control) -> void:
	pass


func _process(delta: float) -> void:
	var want := 1.0 if drawer_visible() else 0.0
	var redraw := false
	if not is_equal_approx(_drawer_k, want):
		_drawer_k = move_toward(_drawer_k, want, delta * DRAWER_SPEED)
		redraw = true
	if _status_left > 0.0:
		_status_left -= delta
		redraw = true
	if _transfer and _transfer.process(delta):
		redraw = true
	if redraw:
		panel().queue_redraw()


func _say(text: String, warn: bool) -> void:
	_status = text
	_status_warn = warn
	_status_left = STATUS_HOLD if not text.is_empty() else 0.0


## Son işin yazısı (sınama).
func status_text() -> String:
	return _status if _status_left > 0.0 else ""


func _content_input(event: InputEvent) -> bool:
	if bag == null:
		return false
	var tabs := top_tabs()
	if tabs.size() > 1 and (_pressed(event, &"camera_left") or _pressed(event, &"camera_right")):
		show_page("transfer" if page == "bag" else "bag")
		return true
	if page == "transfer":
		if _transfer and _transfer.key_input(event):
			panel().queue_redraw()
			return true
		return false
	if _pressed(event, &"ui_focus_next") or _pressed(event, &"ui_focus_prev"):
		var i := HudBag.TABS.find(bag_tab)
		var step := -1 if _pressed(event, &"ui_focus_prev") else 1
		_set_bag_tab(HudBag.TABS[(i + step + HudBag.TABS.size()) % HudBag.TABS.size()])
		return true
	if _pressed(event, &"ui_accept") and not selected_entry().is_empty():
		do_action("use")
		return true
	var n := grid_entries().size()
	var step := 0
	if _pressed(event, &"ui_right") or _pressed(event, &"move_right"):
		step = 1
	elif _pressed(event, &"ui_left") or _pressed(event, &"move_left"):
		step = -1
	elif _pressed(event, &"ui_down") or _pressed(event, &"move_back"):
		step = COLS
	elif _pressed(event, &"ui_up") or _pressed(event, &"move_forward"):
		step = -COLS
	if step == 0 or n == 0:
		return false
	if selected_kind != "grid" or selected_index < 0:
		selected_index = 0
	else:
		selected_index = clampi(selected_index + step, 0, n - 1)
	selected_kind = "grid"
	_keep_visible(selected_index)
	MenuStyle.play_ui(self, &"hover")
	panel().queue_redraw()
	return true


func _set_bag_tab(t: String) -> void:
	if t == bag_tab:
		return
	bag_tab = t
	_scroll = 0
	clear_selection()
	MenuStyle.play_ui(self, &"hover")


## Izgarayı satır satır kaydırır. Dönüş: kaydı mı.
func scroll_grid(rows: int) -> bool:
	var total := ceili(grid_entries().size() / float(COLS))
	var want := clampi(_scroll + rows, 0, maxi(0, total - ROWS))
	if want == _scroll:
		return false
	_scroll = want
	panel().queue_redraw()
	return true


func _keep_visible(index: int) -> void:
	var row := index / COLS
	if row < _scroll:
		_scroll = row
	elif row >= _scroll + ROWS:
		_scroll = row - ROWS + 1


## Noktadaki yuva: ["grid", sıra, ""], ["equip", -1, yuva] ya da boş.
func _slot_at(p: Vector2) -> Array:
	for i in COLS * ROWS:
		if cell_rect(i).has_point(p):
			return ["grid", i + _scroll * COLS, ""]
	for slot: String in EQUIP_SLOTS:
		if equip_rect(slot).has_point(p):
			return ["equip", -1, slot]
	return []


func _content_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var p := (event as InputEventMouseMotion).position
		var ht := -1
		for i in top_tabs().size():
			if top_tabs().size() > 1 and _tab_rect(i).has_point(p):
				ht = i
		var hc := close_rect().has_point(p)
		var changed := ht != _hover_tab or hc != _hover_close
		if ht != _hover_tab and ht >= 0:
			MenuStyle.play_ui(self, &"hover", -10.0)
		_hover_tab = ht
		_hover_close = hc
		if page == "transfer":
			if (_transfer and _transfer.gui_input(event)) or changed:
				panel().queue_redraw()
			return
		var s := _slot_at(p)
		var hk := str(s[0]) if not s.is_empty() else ""
		var hi := int(s[1]) if not s.is_empty() else -1
		var hs := str(s[2]) if not s.is_empty() else ""
		var hb := -1
		if _drawer_k > 0.5:
			for i in BUTTONS.size():
				if _drawer_rect(button_rect(i)).has_point(p):
					hb = i
		var hbt := -1
		var rects := bag_tab_rects()
		for i in rects.size():
			if (rects[i] as Rect2).has_point(p):
				hbt = i
		if hk != _hover_kind or hi != _hover_index or hs != _hover_slot or hb != _hover_button or hbt != _hover_bag_tab or changed:
			if (hb != _hover_button and hb >= 0) or (hbt != _hover_bag_tab and hbt >= 0) or (not _entry(hk, hi, hs).is_empty() and (hk != _hover_kind or hi != _hover_index or hs != _hover_slot)):
				MenuStyle.play_ui(self, &"hover", -10.0)
			_hover_kind = hk
			_hover_index = hi
			_hover_slot = hs
			_hover_button = hb
			_hover_bag_tab = hbt
			panel().queue_redraw()
		return
	if event is InputEventMouseButton and page == "bag" and (event as InputEventMouseButton).pressed:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP or mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if RIGHT_BOX.has_point(mb.position):
				scroll_grid(-1 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1)
			return
	if not (event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT):
		if page == "transfer" and _transfer and event is InputEventMouseButton and _transfer.gui_input(event):
			panel().queue_redraw()
		return
	var mbe := event as InputEventMouseButton
	var at := mbe.position
	if mbe.pressed:
		if close_rect().has_point(at):
			close()
			return
		var tabs := top_tabs()
		if tabs.size() > 1:
			for i in tabs.size():
				if _tab_rect(i).has_point(at):
					show_page(str(tabs[i]["id"]))
					return
	if page == "transfer":
		if _transfer and _transfer.gui_input(event):
			panel().queue_redraw()
		return
	if not mbe.pressed:
		return
	if _drawer_k > 0.5:
		for i in BUTTONS.size():
			if _drawer_rect(button_rect(i)).has_point(at):
				var action := str(BUTTONS[i][0])
				if action_enabled(action):
					do_action(action)
				else:
					MenuStyle.play_ui(self, &"deny")
				return
		if DRAWER.has_point(at):
			return
	var rects := bag_tab_rects()
	for i in rects.size():
		if (rects[i] as Rect2).has_point(at):
			_set_bag_tab(HudBag.TABS[i])
			return
	var s := _slot_at(at)
	if not s.is_empty() and not _entry(str(s[0]), int(s[1]), str(s[2])).is_empty():
		selected_kind = str(s[0])
		selected_index = int(s[1])
		selected_slot = str(s[2])
		MenuStyle.play_ui(self, &"click")
		panel().queue_redraw()
		return
	if not selected_kind.is_empty():
		clear_selection()


## Çekmecenin işi (use: kuşan, çıkar ya da kullan; move: aktarma kabına; drop: yere). Dönüş: yapıldı mı.
func do_action(action: String) -> bool:
	var e := shown_entry()
	if e.is_empty() or not (e.get("actions", []) as Array).has(action):
		MenuStyle.play_ui(self, &"deny")
		return false
	var ok := false
	var item_id := str(e["id"])
	match action:
		"use":
			var worn := str(e.get("slot", ""))
			ok = bag.use(e)
			if ok and worn.is_empty():
				selected_kind = "equip"
				selected_slot = str(e.get("equip_slot", ""))
				selected_index = -1
			elif ok:
				_select_in_grid(item_id)
		"move":
			var r := bag.move_to_target(e)
			ok = int(r["moved"]) > 0
			_say(str(r["text"]), not ok)
			_clamp_selection()
		"drop":
			ok = bag.drop(e)
			if ok:
				_say(("Yere bırakıldı: %s × %d" if HudBag.lang() == "tr" else "Dropped: %s × %d") % [str(e["name"]), int(e["count"])], false)
				if not str(e.get("slot", "")).is_empty():
					clear_selection()
			_clamp_selection()
	_hover_kind = ""
	_hover_index = -1
	_hover_slot = ""
	MenuStyle.play_ui(self, &"click" if ok else &"deny")
	panel().queue_redraw()
	return ok


func _select_in_grid(item_id: String) -> void:
	if not grid_entries().any(func(g: Dictionary) -> bool: return str(g["id"]) == item_id):
		bag_tab = "all"
	var g := grid_entries()
	for i in g.size():
		if str(g[i]["id"]) == item_id:
			selected_kind = "grid"
			selected_index = i
			selected_slot = ""
			_keep_visible(i)
			return
	clear_selection()


func _clamp_selection() -> void:
	if selected_kind == "grid":
		var n := grid_entries().size()
		if n == 0:
			clear_selection()
		else:
			selected_index = mini(selected_index, n - 1)
	elif selected_kind == "equip" and bag.equipped().get(selected_slot, {}).is_empty():
		clear_selection()
	var total := ceili(grid_entries().size() / float(COLS))
	_scroll = clampi(_scroll, 0, maxi(0, total - ROWS))


# --- 3B görsel ----------------------------------------------------------------------------------------------------

## Kişinin 3B görseli: saydam, kendi 3B dünyası olan bir SubViewport; ışık, kamera ve bekleme klibindeki CharacterAvatar.
func _build_view() -> void:
	_view = DragView.new()
	(_view as DragView).host = self
	_view.name = "Character"
	_view.stretch = true
	_view.mouse_filter = Control.MOUSE_FILTER_STOP
	_view.mouse_default_cursor_shape = Control.CURSOR_DRAG
	_view.position = CHAR_RECT.position
	_view.size = CHAR_RECT.size
	_view.visible = page == "bag"
	panel().add_child(_view)
	_viewport = SubViewport.new()
	_viewport.name = "Viewport"
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	_view.add_child(_viewport)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.9, 0.88, 0.84)
	e.ambient_light_energy = 0.6
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	_viewport.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-34.0, 30.0, 0.0)
	key.light_energy = 1.2
	key.light_color = Color(1.0, 0.94, 0.84)
	_viewport.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-14.0, -150.0, 0.0)
	rim.light_energy = 0.55
	rim.light_color = Color(0.72, 0.84, 1.0)
	_viewport.add_child(rim)
	var cam := Camera3D.new()
	cam.name = "Camera"
	cam.fov = MODEL_FOV
	cam.current = true
	_viewport.add_child(cam)
	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	_pivot.rotation.y = deg_to_rad(-14.0)
	_viewport.add_child(_pivot)
	_avatar = CharacterAvatar.new()
	_avatar.name = "Avatar"
	_avatar.start_pose = &"idle"
	var look: Dictionary = {}
	if not person.is_empty():
		look = ChildLook.resolve(person)
		# Çocuğun modelinde bekleme klibi yoktur: oyuncununki gibi klip çeşitliliğinden gelir (ClipVariety; aynı kişiye aynı klip).
		_avatar.variety_person = person
		_avatar.variety_allocator = ClipVariety.Allocator.new()
		_avatar.model_override = str(look.get("model", person))
	elif profile:
		_avatar.profile = profile
	_pivot.add_child(_avatar)
	if not look.is_empty():
		ChildLook.apply(_avatar, look)
	var f := CreatorTurntable.full_frame(_avatar.get_model_height(), MODEL_FOV, MODEL_FILL, MODEL_CENTER, MODEL_ELEVATION)
	cam.look_at_from_position(f[0], f[1], Vector3.UP)


## 3B görselin denetimi ve karakteri (sınama).
func character_view() -> SubViewportContainer:
	return _view


func character_avatar() -> CharacterAvatar:
	return _avatar


## Karakterin o anki dönüşü (radyan; sınama).
func character_yaw() -> float:
	return _pivot.rotation.y if _pivot else 0.0


## Karakteri sürükleyerek döndürür (px).
func turn_character(dx: float) -> void:
	if _pivot:
		_pivot.rotation.y += dx * DRAG_SENSITIVITY


# --- Çizim --------------------------------------------------------------------------------------------------------

func _draw_content(ci: Control) -> void:
	_draw_window(ci)
	_draw_head(ci)
	if page == "transfer" and _transfer:
		_transfer.draw(ci)
		_draw_foot(ci)
		return
	HudJournalPage.draw_card(ci, LEFT_BOX, "KUŞAM" if HudBag.lang() == "tr" else "GEAR")
	HudJournalPage.draw_card(ci, RIGHT_BOX, "HEYBE" if HudBag.lang() == "tr" else "PACK")
	_draw_bag_tabs(ci)
	_draw_floor(ci)
	_draw_equipment(ci)
	_draw_grid(ci)
	_draw_foot(ci)
	_draw_drawer(ci)


## Pencere: koyu zemin, ince soluk altın kenar, 3 px köşe, gölge; başlık şeridi kitabın üst şeridi gibi.
func _draw_window(ci: Control) -> void:
	var r := Rect2(Vector2.ZERO, SIZE)
	ci.draw_style_box(UIKit.panel_style(WINDOW_BG, Color(UIKit.GOLD_DIM, 0.85), 1, 3, Color(0, 0, 0, 0.6), 28), r)
	var head := Rect2(r.position + Vector2(1.0, 1.0), Vector2(r.size.x - 2.0, HEAD_H))
	var a := Color(0.008, 0.012, 0.022, 0.94)
	var b := Color(0.01, 0.016, 0.03, 0.55)
	ci.draw_polygon(PackedVector2Array([head.position, Vector2(head.end.x, head.position.y), head.end, Vector2(head.position.x, head.end.y)]),
		PackedColorArray([a, a, b, b]))
	draw_ornament_line(ci, HEAD_H, SIZE.x, 480.0)


## Kitabın süs çizgisi (GameMenu.Strip): baştan sona ince soluk çizgi, ortası parlak, ortada gök mavisi gözlü altın baklava.
static func draw_ornament_line(ci: CanvasItem, y: float, width: float, half: float) -> void:
	var cx := width * 0.5
	ci.draw_line(Vector2(1.0, y), Vector2(width - 1.0, y), Color(UIKit.GOLD, 0.16), 1.0)
	ci.draw_line(Vector2(cx - half, y), Vector2(cx + half, y), Color(UIKit.GOLD, 0.55), 1.5, true)
	var d := 7.0
	ci.draw_colored_polygon(PackedVector2Array([Vector2(cx, y - d), Vector2(cx + d, y), Vector2(cx, y + d), Vector2(cx - d, y)]), UIKit.GOLD)
	ci.draw_colored_polygon(PackedVector2Array([Vector2(cx, y - 3), Vector2(cx + 3, y), Vector2(cx, y + 3), Vector2(cx - 3, y)]), UIKit.SKY)


## Başlık: kitabın sekmeleri gibi (altın dolu baklava ve içinde heybe ya da aktarma işareti; harf aralıklı Cinzel ad ve altın alt
## çizgi; tek sekmede yalnız «ENVANTER»); solda yuva ya da kese, sağda Yük ve çubuğu.
func _draw_head(ci: Control) -> void:
	var tabs := top_tabs()
	var f := UIKit.font("Cinzel", 700, 2)
	for i in tabs.size():
		var c := tab_center(i)
		var active := str(tabs[i]["id"]) == page
		var hot := i == _hover_tab and not active
		var col := UIKit.GOLD if active else (UIKit.SKY if hot else Color(UIKit.TEXT_DIM, 0.85))
		var r := 21.0
		var dia := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
		if active:
			ci.draw_circle(c, 34.0, Color(UIKit.GOLD, 0.1))
			ci.draw_colored_polygon(dia, Color(UIKit.GOLD, 0.9))
		else:
			ci.draw_colored_polygon(dia, Color(0.03, 0.04, 0.06, 0.9))
		dia.append(dia[0])
		ci.draw_polyline(dia, col, 2.0, true)
		var glyph_col := Color(0.05, 0.05, 0.07) if active else col
		if str(tabs[i]["id"]) == "bag":
			draw_bag_glyph(ci, c, 9.0, glyph_col)
		else:
			draw_swap_glyph(ci, c, 9.0, glyph_col)
		var label := str(tabs[i]["label"])
		var w := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 21).x
		ci.draw_string(f, Vector2(c.x - w * 0.5, 84.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, col)
		if active:
			ci.draw_line(Vector2(c.x - w * 0.5, 93.0), Vector2(c.x + w * 0.5, 93.0), Color(UIKit.GOLD, 0.8), 2.0)
	if bag == null:
		return
	var inv := bag.inventory
	var lg := HudBag.lang()
	if inv.purse_on:
		_draw_stat(ci, Vector2(48.0, 54.0), "icon_coins", "%d" % inv.cowries(), "Kese" if lg == "tr" else "Purse", false)
	else:
		_draw_stat(ci, Vector2(48.0, 54.0), "icon_bag", "%d / %d" % [inv.slots_used(), inv.slots_max()], "Yuva" if lg == "tr" else "Slots", false)
	var carried := inv.load_amount()
	var cap := inv.capacity()
	var frac := CarryLoad.frac(carried, cap)
	var right := Vector2(SIZE.x - 48.0, 50.0)
	_draw_stat(ci, right, "icon_weight", "%s / %s" % [HudBag.yuk_text(carried, lg), HudBag.yuk_text(cap, lg)], "Yük" if lg == "tr" else "Load", true,
		load_color(frac))
	draw_load_bar(ci, Rect2(right.x - 190.0, 80.0, 190.0, 4.0), frac, true)


## Yükün rengi: yarıya dek krem, yarıdan sonra (zıplama yok) köz, dörtte üçten sonra (koşu yok) kızıl.
static func load_color(frac: float) -> Color:
	if frac > 0.75 + 1e-9:
		return UIKit.CRIMSON
	if frac > 0.5 + 1e-9:
		return UIKit.EMBER
	return UIKit.TEXT


## Yükün ince çubuğu: soluk zemin, dolu kısım yükün renginde; ticks ise yarıda ve dörtte üçte çentik (zıplama ve koşunun sınırı).
static func draw_load_bar(ci: CanvasItem, r: Rect2, frac: float, ticks: bool) -> void:
	ci.draw_rect(r, Color(UIKit.GOLD_DIM, 0.35))
	var w := r.size.x * clampf(frac, 0.0, 1.0)
	if w > 0.5:
		ci.draw_rect(Rect2(r.position, Vector2(w, r.size.y)), Color(load_color(frac), 0.9))
	if ticks:
		for t: float in [0.5, 0.75]:
			var x := r.position.x + r.size.x * t
			ci.draw_line(Vector2(x, r.position.y - 3.0), Vector2(x, r.end.y + 3.0), Color(UIKit.GOLD, 0.7), 1.0)


## Kese, yuva ve Yük: tuş kapağı biçiminde simge, yanında sayı ve adı (AlegreyaSC).
func _draw_stat(ci: Control, at: Vector2, icon: String, value: String, label: String, right: bool, value_color := UIKit.TEXT) -> void:
	var nf := HudKit.number_font(600)
	var lf := UIKit.font("AlegreyaSC-Regular", 400, 1)
	var vw := nf.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	var lw := lf.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
	var cap := 44.0
	var total := cap + 12.0 + vw + 10.0 + lw
	var x := at.x - total if right else at.x
	var cr := Rect2(Vector2(x, at.y - cap * 0.5), Vector2(cap, cap))
	_draw_slot_box(ci, cr, false, false)
	HudKit.draw_icon(ci, icon, cr.get_center(), cap * 0.72)
	ci.draw_string(nf, Vector2(x + cap + 12.0, at.y + 8.0), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, value_color)
	ci.draw_string(lf, Vector2(x + cap + 12.0 + vw + 10.0, at.y + 7.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UIKit.TEXT_DIM)


## Heybe işareti (sekmelerin çizgi işaretleri gibi): bağlı ağızlı torba.
static func draw_bag_glyph(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	var body := PackedVector2Array()
	for k in 17:
		var a := PI * 0.08 + PI * 0.84 * k / 16.0
		body.append(c + Vector2(cos(a) * s * 0.95, s * 0.2 + sin(a) * s * 0.85))
	body.insert(0, c + Vector2(-s * 0.42, -s * 0.38))
	body.append(c + Vector2(s * 0.42, -s * 0.38))
	ci.draw_polyline(body, col, 1.7, true)
	ci.draw_line(c + Vector2(-s * 0.5, -s * 0.42), c + Vector2(s * 0.5, -s * 0.42), col, 2.0, true)
	ci.draw_line(c + Vector2(-s * 0.3, -s * 0.42), c + Vector2(-s * 0.55, -s * 0.95), col, 1.5, true)
	ci.draw_line(c + Vector2(s * 0.3, -s * 0.42), c + Vector2(s * 0.55, -s * 0.95), col, 1.5, true)


## Aktarma işareti: karşılıklı iki ok.
static func draw_swap_glyph(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	ci.draw_line(c + Vector2(-s, -s * 0.35), c + Vector2(s, -s * 0.35), col, 1.8, true)
	ci.draw_polyline(PackedVector2Array([c + Vector2(s * 0.45, -s * 0.8), c + Vector2(s, -s * 0.35), c + Vector2(s * 0.45, s * 0.1)]), col, 1.8, true)
	ci.draw_line(c + Vector2(s, s * 0.45), c + Vector2(-s, s * 0.45), col, 1.8, true)
	ci.draw_polyline(PackedVector2Array([c + Vector2(-s * 0.45, 0.0), c + Vector2(-s, s * 0.45), c + Vector2(-s * 0.45, s * 0.9)]), col, 1.8, true)


## Kitabın yuvası: koyu zemin, ince soluk altın kenar, 3 px köşe; üzerine gelince gök mavisi, seçiliyken sıcak zemin ve altın.
static func _draw_slot_box(ci: CanvasItem, r: Rect2, hot: bool, active: bool) -> void:
	var border := UIKit.GOLD if active else (UIKit.SKY if hot else Color(UIKit.GOLD_DIM, 0.7))
	var bw := 2 if active else 1
	var sb := UIKit.panel_style(SLOT_ACTIVE_BG if active else SLOT_BG, border, bw, 3, Color(UIKit.GOLD, 0.22) if active else Color(0, 0, 0, 0.3), 10 if active else 5)
	ci.draw_style_box(sb, r)
	# Üst kenarın ince ışığı (tuş kapağı gibi).
	ci.draw_line(r.position + Vector2(4.0, 4.0), Vector2(r.end.x - 4.0, r.position.y + 4.0), Color(1, 1, 1, 0.06), 1.0)


## Boş yuvanın soluk baklavası.
static func _draw_empty_mark(ci: CanvasItem, c: Vector2, s: float) -> void:
	var dia := PackedVector2Array([c + Vector2(0, -s), c + Vector2(s, 0), c + Vector2(0, s), c + Vector2(-s, 0), c + Vector2(0, -s)])
	ci.draw_polyline(dia, Color(UIKit.GOLD_DIM, 0.55), 1.4, true)
	ci.draw_circle(c, 1.8, Color(UIKit.GOLD_DIM, 0.6))


## Karakterin ayağının altında yumuşak bir ışık ve kitabın süs çizgisi gibi ince bir elips.
func _draw_floor(ci: Control) -> void:
	var c := Vector2(CHAR_RECT.get_center().x, CHAR_RECT.end.y - 22.0)
	var soft := UIKit.soft_texture()
	ci.draw_texture_rect(soft, Rect2(c - Vector2(150.0, 34.0), Vector2(300.0, 68.0)), false, Color(UIKit.GOLD, 0.16))
	var pts := PackedVector2Array()
	for k in 65:
		var a := TAU * k / 64.0
		pts.append(c + Vector2(cos(a) * 118.0, sin(a) * 20.0))
	ci.draw_polyline(pts, Color(UIKit.GOLD, 0.28), 1.2, true)
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-124.0, -5.0), c + Vector2(-117.0, 0.0), c + Vector2(-124.0, 5.0), c + Vector2(-131.0, 0.0)]), Color(UIKit.GOLD, 0.6))
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(124.0, -5.0), c + Vector2(131.0, 0.0), c + Vector2(124.0, 5.0), c + Vector2(117.0, 0.0)]), Color(UIKit.GOLD, 0.6))


func _draw_equipment(ci: Control) -> void:
	var eq := bag.equipped() if bag else {}
	for slot: String in EQUIP_SLOTS:
		var r := equip_rect(slot)
		var active := selected_kind == "equip" and selected_slot == slot
		var hot := _hover_kind == "equip" and _hover_slot == slot
		_draw_slot_box(ci, r, hot, active)
		if eq.has(slot):
			HudItemIcon.draw(ci, str((eq[slot] as Dictionary)["id"]), r.get_center(), r.size.x * 0.7)
		else:
			HudItemIcon.draw_slot(ci, slot, r.get_center(), r.size.x * 0.52, Color(0.55, 0.6, 0.7, 0.24 if not hot else 0.5))


## Heybenin sekmeleri: kartın başlık satırında, sağa yaslı; açık olan altın ve alt çizgili, boş sekme soluk.
func _draw_bag_tabs(ci: Control) -> void:
	var f := UIKit.font("AlegreyaSC-Regular", 400, 1)
	var rects := bag_tab_rects()
	for i in HudBag.TABS.size():
		var t := HudBag.TABS[i]
		var r: Rect2 = rects[i]
		var active := t == bag_tab
		var empty := bag != null and t != "all" and bag.tab_count(t) == 0
		var col := UIKit.GOLD if active else (UIKit.SKY if i == _hover_bag_tab else Color(UIKit.TEXT_DIM, 0.45 if empty else 0.9))
		ci.draw_string(f, Vector2(r.position.x + 4.0, r.position.y + 22.0), ItemCatalog.label("tabs", t, HudBag.lang()), HORIZONTAL_ALIGNMENT_LEFT, -1,
			BAG_TAB_SIZE, col)
		if active:
			ci.draw_line(Vector2(r.position.x + 4.0, r.end.y - 2.0), Vector2(r.end.x - 4.0, r.end.y - 2.0), Color(UIKit.GOLD, 0.8), 2.0)


func _draw_grid(ci: Control) -> void:
	var g := grid_entries()
	var first := _scroll * COLS
	for i in COLS * ROWS:
		var r := cell_rect(i)
		var index := first + i
		var active := selected_kind == "grid" and selected_index == index
		var hot := _hover_kind == "grid" and _hover_index == index and index < g.size()
		_draw_slot_box(ci, r, hot, active)
		if index >= g.size():
			_draw_empty_mark(ci, r.get_center(), 9.0)
			continue
		var e: Dictionary = g[index]
		HudItemIcon.draw(ci, str(e["id"]), r.get_center() + Vector2(0.0, -2.0), CELL * 0.68)
		if int(e["count"]) > 1:
			_draw_count(ci, r, int(e["count"]))
	var total := ceili(g.size() / float(COLS))
	if total > ROWS:
		var track := Rect2(RIGHT_BOX.end.x - 14.0, GRID_AT.y, 3.0, ROWS * (CELL + GAP) - GAP)
		ci.draw_rect(track, Color(UIKit.GOLD_DIM, 0.35))
		var h := track.size.y * ROWS / float(total)
		var y := track.position.y + (track.size.y - h) * _scroll / float(maxi(1, total - ROWS))
		ci.draw_rect(Rect2(track.position.x, y, track.size.x, h), Color(UIKit.GOLD, 0.8))


## Sayı: sağ altta kitabın tuş kapağı gibi küçük bir kutu.
static func _draw_count(ci: CanvasItem, r: Rect2, n: int) -> void:
	var nf := HudKit.number_font(600)
	var text := str(n)
	var w := maxf(24.0, nf.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x + 12.0)
	var b := Rect2(Vector2(r.end.x - w - 6.0, r.end.y - 28.0), Vector2(w, 22.0))
	ci.draw_rect(b, Color(0.06, 0.07, 0.1, 0.95))
	ci.draw_rect(b.grow(-0.5), Color(UIKit.GOLD_DIM, 0.9), false, 1.0)
	ci.draw_string(nf, Vector2(b.get_center().x - (w - 12.0) * 0.5, b.end.y - 5.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, UIKit.GOLD)


## Alt şerit: kitabın tuş ipuçları gibi (Esc Kapat tıklanır); sağda son işin yazısı.
func _draw_foot(ci: Control) -> void:
	draw_ornament_line(ci, SIZE.y - 60.0, SIZE.x, 480.0)
	var lg := HudBag.lang()
	var hints: Array = [["Esc", "Kapat" if lg == "tr" else "Close"]]
	if page == "transfer":
		hints.append_array([["Sol tık", "Taşı"], ["Shift", "Bir tane"]] if lg == "tr" else [["Click", "Move"], ["Shift", "One"]])
	else:
		hints.append_array([["Sol tık", "Seç"], ["Sürükle", "Döndür"]] if lg == "tr" else [["Click", "Select"], ["Drag", "Turn"]])
	if top_tabs().size() > 1:
		hints.append(["Q E", "Sekme" if lg == "tr" else "Tab"])
	var f := UIKit.font("AlegreyaSC-Regular", 400)
	var x := close_rect().position.x - (90.0 if hints.size() > 3 else 0.0)
	var y := SIZE.y - 30.0
	for i in hints.size():
		var key := str(hints[i][0])
		var what := str(hints[i][1])
		var kw := GameMenu.keycap_width(key)
		var hot := i == 0 and _hover_close
		GameMenu.draw_keycap(ci, Rect2(Vector2(x, y - 17.0), Vector2(kw, 34.0)), key, hot)
		ci.draw_string(f, Vector2(x + kw + 10.0, y + 7.0), what, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, UIKit.SKY if hot else UIKit.PARCHMENT)
		x += kw + 10.0 + f.get_string_size(what, HORIZONTAL_ALIGNMENT_LEFT, -1, 21).x + 46.0
	if _status_left > 0.0 and not _status.is_empty() and page == "bag":
		var sf := UIKit.font("Alegreya", 600)
		var a := clampf(_status_left / 0.4, 0.0, 1.0)
		var sw := sf.get_string_size(_status, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
		ci.draw_string(sf, Vector2(SIZE.x - 40.0 - sw, y + 7.0), _status, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(UIKit.EMBER if _status_warn else UIKit.SKY, a))


## Çekmecenin o anki kayması (belirirken aşağıdan yukarı).
func _drawer_rect(r: Rect2) -> Rect2:
	return Rect2(r.position + Vector2(0.0, (1.0 - _drawer_k) * DRAWER_SLIDE), r.size)


## Çekmece: eşyanın büyük simgesi, adı ve sayısı, ölçü satırı ve yazısı; Kuşan / Çıkar / Kullan, Taşı, Bırak (kitabın seçme düğmeleri
## gibi). Boş kuşam yuvasının üstünde yuvanın adı ve ne aldığı.
func _draw_drawer(ci: Control) -> void:
	if _drawer_k <= 0.001:
		return
	var e := shown_entry()
	if e.is_empty() and _empty_slot_hovered():
		e = _slot_entry(_hover_slot)
	if e.is_empty():
		e = _last_shown
	else:
		_last_shown = e
	if e.is_empty():
		return
	var a := clampf(_drawer_k, 0.0, 1.0)
	var dy := (1.0 - a) * DRAWER_SLIDE
	ci.draw_set_transform(Vector2(0.0, dy), 0.0, Vector2.ONE)
	var sb := UIKit.panel_style(Color(WINDOW_BG, WINDOW_BG.a * a), Color(UIKit.GOLD_DIM, 0.85 * a), 1, 3, Color(0, 0, 0, 0.55 * a), 22)
	ci.draw_style_box(sb, DRAWER)
	var icon_r := Rect2(DETAIL_ICON - Vector2(DETAIL_SLOT, DETAIL_SLOT) * 0.5, Vector2(DETAIL_SLOT, DETAIL_SLOT))
	ci.draw_style_box(UIKit.panel_style(Color(SLOT_ACTIVE_BG, SLOT_ACTIVE_BG.a * a), Color(UIKit.GOLD, a), 2, 3, Color(UIKit.GOLD, 0.18 * a), 10), icon_r)
	if bool(e.get("empty_slot", false)):
		HudItemIcon.draw_slot(ci, str(e["slot"]), DETAIL_ICON, DETAIL_SLOT * 0.56, Color(0.75, 0.78, 0.85, 0.6 * a))
	else:
		HudItemIcon.draw(ci, str(e["id"]), DETAIL_ICON, DETAIL_SLOT * 0.72, Color(1, 1, 1, a))
	var nf := UIKit.font("Cinzel", 700, 3)
	var name_text := str(e["name"]).to_upper()
	ci.draw_string(nf, TEXT_AT, name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(UIKit.GOLD, a))
	var w := nf.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x
	if int(e.get("count", 1)) > 1:
		ci.draw_string(HudKit.number_font(600), TEXT_AT + Vector2(w + 14.0, 0.0), "× %d" % int(e["count"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(UIKit.TEXT_DIM, a))
	var meta := str(e.get("meta", ""))
	if not meta.is_empty():
		var mf := UIKit.font("AlegreyaSC-Regular", 400, 1)
		var mw := mf.get_string_size(meta, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
		ci.draw_string(mf, Vector2(TEXT_AT.x + TEXT_W - mw, TEXT_AT.y), meta, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(UIKit.TEXT_DIM, a))
	ci.draw_line(TEXT_AT + Vector2(0.0, 12.0), TEXT_AT + Vector2(TEXT_W, 12.0), Color(UIKit.GOLD, 0.25 * a), 1.0)
	var bf := UIKit.font("Alegreya", 500)
	var y := TEXT_AT.y + 44.0
	for line in HudKit.wrap_lines(bf, str(e["text"]), 21, TEXT_W, 2):
		ci.draw_string(bf, Vector2(TEXT_AT.x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color(UIKit.PARCHMENT, a))
		y += 28.0
	# Ayraç: kitabın dikey çizgisi (SettingsPanel.VRule) ve ortasında baklava.
	var vx := BUTTON_RECT.position.x - 26.0
	ci.draw_line(Vector2(vx, DRAWER.position.y + 22.0), Vector2(vx, DRAWER.end.y - 22.0), Color(UIKit.GOLD, 0.35 * a), 1.0)
	var vc := Vector2(vx, DRAWER.get_center().y)
	ci.draw_colored_polygon(PackedVector2Array([vc + Vector2(0, -6), vc + Vector2(6, 0), vc + Vector2(0, 6), vc + Vector2(-6, 0)]), Color(UIKit.GOLD, a))
	for i in BUTTONS.size():
		var r := button_rect(i)
		var on := (e.get("actions", []) as Array).has(str(BUTTONS[i][0]))
		var hot := on and i == _hover_button
		var ba := a * (1.0 if on else 0.38)
		var col := UIKit.SKY if hot else UIKit.PARCHMENT
		ci.draw_style_box(UIKit.panel_style(Color(SLOT_BG, SLOT_BG.a * ba), Color(col if hot else Color(UIKit.GOLD_DIM, 0.6), ba), 1, 3, Color(0, 0, 0, 0.3 * ba), 6), r)
		HudKit.draw_icon(ci, str(BUTTONS[i][2]), r.position + Vector2(30.0, r.size.y * 0.5), 30.0, Color(1, 1, 1, ba))
		ci.draw_string(UIKit.font("AlegreyaSC-Regular", 400, 1), Vector2(r.position.x + 56.0, r.get_center().y + 7.0), button_label(i, e),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color(col, ba))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Düğmenin yazısı: ilk düğme eşyaya göre (Kuşan, Çıkar, Kullan), ötekiler sabit (İngilizce arayüzde İngilizcesi).
static func button_label(i: int, e: Dictionary) -> String:
	var lg := HudBag.lang()
	if i == 0:
		var tr := str(e.get("use_label", BUTTONS[0][1]))
		return tr if lg == "tr" else {"Kuşan": "Equip", "Çıkar": "Unequip"}.get(tr, "Use")
	return str(BUTTONS[i][1]) if lg == "tr" else ["Use", "Move", "Drop"][i]


## Boş kuşam yuvasının çekmece satırı: yuvanın adı ve ne aldığı.
func _slot_entry(slot: String) -> Dictionary:
	var lg := HudBag.lang()
	var nm := ItemCatalog.label("slots", slot, lg)
	return {"id": "", "name": nm, "count": 1, "slot": slot, "empty_slot": true, "actions": [],
		"meta": "Boş yuva" if lg == "tr" else "Empty slot",
		"text": ("%s yuvasına kuşanılan eşya burada durur. Heybeden seç, Kuşan'a bas." if lg == "tr" else "Gear worn in the %s slot sits here. Pick it in the pack and press Equip.") % nm.to_lower()}



## Eylem tanımlıysa basıldı mı (tanımsız eylemi sormak motor hatası yazar; sınamalar InputSetup'sız kurar).
static func _pressed(event: InputEvent, action: StringName) -> bool:
	return InputMap.has_action(action) and event.is_action_pressed(action)


## Karakterin görseli: sürükleyince döner.
class DragView extends SubViewportContainer:
	var host: HudInventoryScreen
	var _dragging := false

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			_dragging = (event as InputEventMouseButton).pressed
			accept_event()
		elif event is InputEventMouseMotion and _dragging:
			if host:
				host.turn_character((event as InputEventMouseMotion).relative.x)
			accept_event()
