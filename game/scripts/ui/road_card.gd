class_name RoadCard
extends Control
## Yol Kartı (travel.md §6.2, §15; Yol Haritası roads-relays): arabaya binince sağda açılır, HUD'un dilindedir (lacivert zemin, soluk altın
## kenar, Cinzel başlık, Alegreya gövde). Yakın Duraklar: bağlı duraklar süreye göre (ad, metre, ≈süre, ücret); duyulan ve bulunan duraklar
## soluk, nedeniyle; kilitli satır kilidin sözünü yazar. Seçenekler: 1 Yolu İzle, 2 Yolu Kısalt, 3 Yük Bindir (Kendin Sür carter ister,
## I. Perde'de yolcu görevleriyle gelir). ↑↓ seçer, Enter (ya da 1) Yolu İzle, 2 Yolu Kısalt, 3 Yük Bindir, Esc arabadan iner; fareyle satır
## seçilir, düğmeye tıklanır. Kart açıkken saat durur (TravelLayer, Session.set_pause «modal»), dünya kıpırdar; 1080 satıra çizilir,
## UIKit.ui_k() × HUD ölçeğiyle büyür.
##   var card := RoadCard.new()
##   card.setup(rows, "Kışlak Menzili", "tr")      # rows: [{id, name, meters, seconds, fare, enabled, reason}]
##   card.chosen.connect(func(id: String, mode: String) -> void: ...)   # mode: watch | shorten | cargo
##   card.closed.connect(...)                                          # Esc: in

signal chosen(station_id: String, mode: String)
signal closed

const PANEL := Rect2(1420.0, 300.0, 460.0, 0.0)
const ROW_H := 58.0
const HEAD_H := 96.0
const FOOT_H := 132.0
const PAD := 22.0
const TITLE_SIZE := 24
const ROW_SIZE := 19
const SMALL_SIZE := 15
const MODES: Array[String] = ["watch", "shorten", "cargo"]

var rows: Array = []
var here := ""
var lang := "tr"
## Arabadaki yük (Yük; «Yük Bindir»in yanında yazar) ve sınırı.
var cargo := 0.0
var cargo_cap := 40.0
var selected := 0

var _k := 1.0
var _hover_row := -1
var _hover_mode := -1


func _init() -> void:
	name = "RoadCard"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	UIKit.full_rect(self)
	focus_mode = Control.FOCUS_NONE
	_k = UIKit.ui_k() * HudKit.hud_scale()
	_first_enabled()


func setup(p_rows: Array, p_here: String, p_lang := "tr") -> void:
	rows = p_rows.duplicate(true)
	here = p_here
	lang = p_lang
	_first_enabled()
	queue_redraw()


func _first_enabled() -> void:
	selected = clampi(selected, 0, maxi(rows.size() - 1, 0))
	for i in rows.size():
		if bool((rows[i] as Dictionary).get("enabled", false)):
			selected = i
			return


func _t(key: String) -> String:
	return Travel.text(key, lang)


## Seçili durak ("" yoksa ya da kapalıysa).
func selected_id() -> String:
	if selected < 0 or selected >= rows.size():
		return ""
	var r: Dictionary = rows[selected]
	return str(r["id"]) if bool(r.get("enabled", false)) else ""


## Seçeneği seçer (watch, shorten, cargo). Yük Bindir durak istemez. Döner: iş yapıldı mı.
func pick(mode: String) -> bool:
	if mode == "cargo":
		chosen.emit("", "cargo")
		return true
	var id := selected_id()
	if id.is_empty():
		MenuStyle.play_ui(self, &"deny")
		return false
	chosen.emit(id, mode)
	return true


func move(step: int) -> void:
	if rows.is_empty():
		return
	selected = clampi(selected + step, 0, rows.size() - 1)
	MenuStyle.play_ui(self, &"hover")
	queue_redraw()


func close() -> void:
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible or not is_inside_tree():
		return
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		var key := (event as InputEventKey).physical_keycode
		var handled := true
		match key:
			KEY_UP, KEY_W:
				move(-1)
			KEY_DOWN, KEY_S:
				move(1)
			KEY_1, KEY_ENTER, KEY_KP_ENTER, KEY_E:
				pick("watch")
			KEY_2:
				pick("shorten")
			KEY_3:
				pick("cargo")
			KEY_ESCAPE:
				close()
			_:
				handled = false
		if handled:
			get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var p := (event as InputEventMouseMotion).position
		var r := _row_at(p)
		var m := _mode_at(p)
		if r != _hover_row or m != _hover_mode:
			_hover_row = r
			_hover_mode = m
			queue_redraw()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var p := (event as InputEventMouseButton).position
		var r := _row_at(p)
		if r >= 0:
			selected = r
			queue_redraw()
			accept_event()
			return
		var m := _mode_at(p)
		if m >= 0:
			pick(MODES[m])
			accept_event()


func _process(_delta: float) -> void:
	var k := UIKit.ui_k() * HudKit.hud_scale()
	if not is_equal_approx(k, _k):
		_k = k
		queue_redraw()


# --- Çizim -------------------------------------------------------------------------------------------------------------

## Kartın kutusu (ekran pikseli): sağ kenara yaslı, satır sayısı kadar uzun.
func panel_rect() -> Rect2:
	var h := HEAD_H + maxf(rows.size(), 1) * ROW_H + FOOT_H
	var w := PANEL.size.x * _k
	var right := size.x - (1920.0 - PANEL.end.x) * _k
	return Rect2(right - w, PANEL.position.y * _k, w, h * _k)


func _row_rect(i: int) -> Rect2:
	var p := panel_rect()
	return Rect2(p.position + Vector2(PAD * 0.5, (HEAD_H + i * ROW_H) * _k), Vector2(p.size.x - PAD * _k, (ROW_H - 4.0) * _k))


func _mode_rect(i: int) -> Rect2:
	var p := panel_rect()
	var w := (p.size.x - PAD * 2.0 * _k) / 3.0
	var y := p.end.y - (FOOT_H - 34.0) * _k
	return Rect2(Vector2(p.position.x + PAD * _k + w * i, y), Vector2(w - 8.0 * _k, 52.0 * _k))


func _row_at(p: Vector2) -> int:
	for i in rows.size():
		if _row_rect(i).has_point(p):
			return i
	return -1


func _mode_at(p: Vector2) -> int:
	for i in MODES.size():
		if _mode_rect(i).has_point(p):
			return i
	return -1


func _draw() -> void:
	var p := panel_rect()
	draw_rect(p, Color(HudKit.NAVY_DEEP, 0.9))
	draw_rect(p, Color(HudKit.GOLD, 0.55), false, 2.0 * _k)
	draw_rect(p.grow(-6.0 * _k), Color(HudKit.GOLD, 0.22), false, 1.0 * _k)
	HudKit.draw_text(self, HudKit.title_font(), p.position + Vector2(PAD * _k, 40.0 * _k), _t("card.title").to_upper(), int(TITLE_SIZE * _k), HudKit.GOLD)
	HudKit.draw_text(self, HudKit.body_font(500), p.position + Vector2(PAD * _k, 70.0 * _k), "%s · %s" % [_t("here"), here], int(SMALL_SIZE * _k),
		HudKit.TEXT_DIM)
	if rows.is_empty():
		HudKit.draw_text(self, HudKit.body_font(500), p.position + Vector2(PAD * _k, (HEAD_H + 34.0) * _k), _t("no_stops"), int(ROW_SIZE * _k),
			Color(HudKit.CREAM, 0.7))
	for i in rows.size():
		_draw_row(i, rows[i])
	for i in MODES.size():
		_draw_mode(i)


func _draw_row(i: int, r: Dictionary) -> void:
	var rect := _row_rect(i)
	var on := bool(r.get("enabled", false))
	if i == selected:
		draw_rect(rect, Color(HudKit.GOLD_DEEP, 0.32))
		draw_rect(rect, Color(HudKit.GOLD, 0.7), false, 1.5 * _k)
	elif i == _hover_row:
		draw_rect(rect, Color(HudKit.PLUS, 0.14))
	var a := 1.0 if on else 0.5
	var left := rect.position + Vector2(10.0 * _k, 25.0 * _k)
	var name_text := HudKit.fit_text(HudKit.body_font(600), str(r.get("name", "")), int(ROW_SIZE * _k), rect.size.x * 0.62)
	HudKit.draw_text(self, HudKit.body_font(600), left, name_text, int(ROW_SIZE * _k), Color(HudKit.CREAM, a))
	var sub := ""
	if on:
		sub = "%d m · ≈%s · %s" % [int(round(float(r.get("meters", 0.0)))), RoadCard.duration_text(float(r.get("seconds", 0.0)), lang), str(r.get("fare", ""))]
	else:
		sub = str(r.get("reason", ""))
	HudKit.draw_text(self, HudKit.body_font(400), left + Vector2(0.0, 22.0 * _k), HudKit.fit_text(HudKit.body_font(400), sub, int(SMALL_SIZE * _k),
		rect.size.x - 20.0 * _k), int(SMALL_SIZE * _k), Color(HudKit.TEXT_DIM, a))


func _draw_mode(i: int) -> void:
	var rect := _mode_rect(i)
	var mode := MODES[i]
	var on := mode == "cargo" or not selected_id().is_empty()
	var hover := i == _hover_mode
	draw_rect(rect, Color(HudKit.NAVY, 0.95 if hover else 0.8))
	draw_rect(rect, Color(HudKit.GOLD, 0.8 if hover else 0.45), false, 1.5 * _k)
	var label := "%d  %s" % [i + 1, _t("mode.%s" % mode)]
	HudKit.draw_text(self, HudKit.body_font(600), rect.position + Vector2(rect.size.x * 0.5, 22.0 * _k), HudKit.fit_text(HudKit.body_font(600), label,
		int(SMALL_SIZE * _k), rect.size.x - 8.0 * _k), int(SMALL_SIZE * _k), Color(HudKit.CREAM, 1.0 if on else 0.5), 1)
	if mode == "cargo":
		HudKit.draw_text(self, HudKit.number_font(500), rect.position + Vector2(rect.size.x * 0.5, 42.0 * _k), "%s / %s" % [RoadCard._num(cargo),
			RoadCard._num(cargo_cap)], int(13 * _k), HudKit.TEXT_DIM, 1)
	var foot := panel_rect()
	if i == 0:
		HudKit.draw_text(self, HudKit.body_font(400), Vector2(foot.position.x + PAD * _k, foot.end.y - 16.0 * _k),
			"↑↓ · Enter · Esc %s" % _t("cart.leave"), int(13 * _k), Color(HudKit.TEXT_DIM, 0.8))


## Süre yazısı (saf): «1 dk 16 sn» / «1 min 16 s»; 60 sn'den kısası yalnız saniye.
static func duration_text(seconds: float, p_lang := "tr") -> String:
	var s := int(round(seconds))
	var m := s / 60
	s -= m * 60
	if p_lang == "en":
		return ("%d min %d s" % [m, s]) if m > 0 else "%d s" % s
	return ("%d dk %d sn" % [m, s]) if m > 0 else "%d sn" % s


static func _num(v: float) -> String:
	return ("%.1f" % v).trim_suffix(".0").replace(".", ",")
