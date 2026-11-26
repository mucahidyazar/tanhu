class_name HudJournalPage
extends Control
## Yolculuğun kitabında (duraklatma, GameMenu) «GÖREVLER» sayfası; J kitabı bu sayfada açar (yeniden J ya da Esc kapatır). Kitabın
## öteki sayfaları gibi (TUŞLAR, AYARLAR) üst menünün altındaki alana doğrudan yerleşir, ayrı bir pano ya da başlık çizmez (sayfanın
## adı sekmededir): kitabın kartları (koyu zemin, ince soluk altın kenar, 3 px köşe), Cinzel altın bölüm başlıkları ve altlarında ince
## çizgi, Alegreya satırlar. Solda görevlerin listesi («SÜREN» ve «BİTEN» bölümleri; satırlar kitabın seçme düğmeleri gibi: seçili
## sıcak zeminli ve altın kenarlı, üzerine gelinen gök mavisi), sağda seçilen görevin adı, o anki amacı ve ayrıntısı, adımları: bitenler
## altın bir işaretle ve soluk, o anki adım vurgulu (sıcak şerit ve baklava), sonrakiler gizli (yalnız «…»). Yukarı / aşağı ya da fare
## görev seçer. Görev: {id, title, objective, detail, steps: [{id, text, state: done|current|todo}], done} (GameplayHud.journal_quests()).

## Kartların sayfaya payları, sol kartın genişliği, aradaki boşluk ve en büyük toplam genişlik (TUŞLAR'ın üç sütunu kadar).
const MARGIN := Vector2(92.0, 34.0)
const LIST_W := 560.0
const GAP := 28.0
const MAX_W := 1736.0
## Kartın iç payı, başlığın yüksekliği, liste satırının yüksekliği ve aralığı, adım satırının yüksekliği.
const PAD := Vector2(30.0, 26.0)
const HEAD_H := 46.0
const ROW_H := 64.0
const ROW_GAP := 10.0
const STEP_H := 44.0
## Kitabın kart biçimi (ControlsPage._card ile aynı).
const CARD_BG := Color(0.022, 0.028, 0.042, 0.92)
const ROW_BG := Color(0.03, 0.04, 0.06, 0.85)
const ROW_ACTIVE_BG := Color(0.12, 0.09, 0.05, 0.9)

var quests: Array = []
var selected := 0
var embedded := true

var _hover := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	resized.connect(queue_redraw)
	mouse_exited.connect(func() -> void:
		_hover = -1
		queue_redraw())


## Sol (liste) ve sağ (ayrıntı) kartın kutuları (sayfanın boyuna göre; saf).
static func cards_for(page: Vector2) -> Array:
	var w := minf(page.x - MARGIN.x * 2.0, MAX_W)
	var x := (page.x - w) * 0.5
	var h := maxf(page.y - MARGIN.y * 2.0, 200.0)
	var list := Rect2(x, MARGIN.y, LIST_W, h)
	var detail := Rect2(x + LIST_W + GAP, MARGIN.y, w - LIST_W - GAP, h)
	return [list, detail]


## Listedeki sıralar: süren görevler önce, bitenler sonra; [sıra, bölüm başlığı mı] çiftleri yerine satırların y'si (saf).
## Döner: [{index, y}] ve bölüm başlıklarının [{text, y}]ı.
static func layout_rows(p_quests: Array, top: float) -> Dictionary:
	var rows: Array = []
	var heads: Array = []
	var y := top
	for done_pass in [false, true]:
		var first := true
		for i in p_quests.size():
			if bool((p_quests[i] as Dictionary).get("done", false)) != done_pass:
				continue
			if first:
				heads.append({"text": "BİTEN" if done_pass else "SÜREN", "y": y})
				y += 34.0
				first = false
			rows.append({"index": i, "y": y})
			y += ROW_H + ROW_GAP
		if not first:
			y += 10.0
	return {"rows": rows, "heads": heads}


## i. görevin satırının kutusu (sayfaya göre; listede yoksa boş).
func row_rect(i: int) -> Rect2:
	var list: Rect2 = cards_for(size)[0]
	for r: Dictionary in layout_rows(quests, list.position.y + PAD.y + HEAD_H)["rows"]:
		if int(r["index"]) == i:
			return Rect2(list.position.x + PAD.x - 10.0, float(r["y"]), list.size.x - PAD.x * 2.0 + 20.0, ROW_H)
	return Rect2()


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or quests.size() < 2:
		return
	var step := 0
	if event.is_action_pressed(&"ui_down") or event.is_action_pressed(&"move_back"):
		step = 1
	elif event.is_action_pressed(&"ui_up") or event.is_action_pressed(&"move_forward"):
		step = -1
	if step == 0:
		return
	get_viewport().set_input_as_handled()
	# Listenin görünen sırasıyla (süren önce) gezilir.
	var order: Array = (layout_rows(quests, 0.0)["rows"] as Array).map(func(r: Dictionary) -> int: return int(r["index"]))
	var at := maxi(order.find(selected), 0)
	selected = int(order[clampi(at + step, 0, order.size() - 1)])
	MenuStyle.play_ui(self, &"hover")
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := _row_at((event as InputEventMouseMotion).position)
		if h != _hover:
			_hover = h
			if h >= 0:
				MenuStyle.play_ui(self, &"hover")
			queue_redraw()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var i := _row_at((event as InputEventMouseButton).position)
		if i >= 0:
			selected = i
			MenuStyle.play_ui(self, &"click")
			queue_redraw()
			accept_event()


func _row_at(p: Vector2) -> int:
	for i in quests.size():
		if row_rect(i).has_point(p):
			return i
	return -1


## Görünen adımlar (saf): bitenler ve o anki; sonrakiler tek bir «…» satırı olur.
static func visible_steps(steps: Array) -> Array:
	var out: Array = []
	var hidden := false
	for s: Dictionary in steps:
		if str(s.get("state", "")) == "todo":
			hidden = true
			continue
		out.append(s)
	if hidden:
		out.append({"id": "", "text": "…", "state": "todo"})
	return out


## Kitabın kartı (ControlsPage._card'ın biçimi) ve başlığı: Cinzel altın, harf aralıklı; altında ince altın çizgi.
static func draw_card(ci: CanvasItem, r: Rect2, head: String) -> void:
	ci.draw_style_box(UIKit.panel_style(CARD_BG, Color(UIKit.GOLD_DIM, 0.8), 1, 3, Color(0, 0, 0, 0.4), 12), r)
	if head.is_empty():
		return
	var f := UIKit.font("Cinzel", 700, 4)
	var x := r.position.x + PAD.x
	var w := r.size.x - PAD.x * 2.0
	ci.draw_string(f, Vector2(x, r.position.y + PAD.y + 22.0), HudKit.fit_text(f, head, 21, w), HORIZONTAL_ALIGNMENT_LEFT, -1, 21, UIKit.GOLD)
	ci.draw_line(Vector2(x, r.position.y + PAD.y + HEAD_H - 10.0), Vector2(x + w, r.position.y + PAD.y + HEAD_H - 10.0), Color(UIKit.GOLD, 0.25), 1.0)


func _draw() -> void:
	var cards := cards_for(size)
	var list: Rect2 = cards[0]
	var detail: Rect2 = cards[1]
	draw_card(self, list, "GÖREV GÜNLÜĞÜ")
	if quests.is_empty():
		draw_card(self, detail, "")
		draw_string(UIKit.font("Alegreya-Italic"), list.position + Vector2(PAD.x, PAD.y + HEAD_H + 30.0), "Şimdilik bir görev yok.", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, UIKit.TEXT_DIM)
		return
	selected = clampi(selected, 0, quests.size() - 1)
	var lay := layout_rows(quests, list.position.y + PAD.y + HEAD_H)
	var small := UIKit.font("Cinzel", 700, 3)
	for h: Dictionary in lay["heads"]:
		draw_string(small, Vector2(list.position.x + PAD.x, float(h["y"]) + 20.0), str(h["text"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(UIKit.GOLD, 0.7))
	for r: Dictionary in lay["rows"]:
		_draw_row(int(r["index"]))
	draw_card(self, detail, str(quests[selected].get("title", "")).to_upper())
	_draw_quest(detail, quests[selected])


## Listenin satırı: kitabın seçme düğmesi gibi (TUŞLAR'ın görünüm düğmeleri): görev simgesi, adı (Cinzel), durumu (AlegreyaSC).
func _draw_row(i: int) -> void:
	var q: Dictionary = quests[i]
	var r := row_rect(i)
	var active := i == selected
	var hot := i == _hover and not active
	var done := bool(q.get("done", false))
	var col := UIKit.GOLD if active else (UIKit.SKY if hot else (Color(UIKit.TEXT_DIM, 0.85) if done else UIKit.PARCHMENT))
	var border := UIKit.GOLD if active else (UIKit.SKY if hot else Color(UIKit.GOLD_DIM, 0.6))
	draw_style_box(UIKit.panel_style(ROW_ACTIVE_BG if active else ROW_BG, border, 2 if active else 1, 3, Color(0, 0, 0, 0.3), 6), r)
	var c := Vector2(r.position.x + 34.0, r.get_center().y)
	_draw_diamond(c, 15.0, active, col)
	GameMenu.draw_glyph(self, "quest", c, 7.0, Color(0.05, 0.05, 0.07) if active else col)
	var f := UIKit.font("Cinzel", 700, 2)
	var x := r.position.x + 64.0
	draw_string(f, Vector2(x, r.position.y + 28.0), HudKit.fit_text(f, str(q.get("title", "")).to_upper(), 18, r.size.x - 80.0),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, col)
	draw_string(UIKit.font("AlegreyaSC-Regular"), Vector2(x, r.position.y + 51.0), "Bitti" if done else "Sürüyor", HORIZONTAL_ALIGNMENT_LEFT, -1, 17,
		Color(UIKit.TEXT_DIM, 0.85))


## Kitabın sekmelerindeki baklava: açıkta altın dolu, değilse koyu ve kenarlı.
func _draw_diamond(c: Vector2, r: float, filled: bool, col: Color) -> void:
	var dia := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
	draw_colored_polygon(dia, Color(UIKit.GOLD, 0.9) if filled else Color(0.03, 0.04, 0.06, 0.9))
	dia.append(dia[0])
	draw_polyline(dia, col, 1.6, true)


## Sağ kart: amaç, ayrıntı, adımlar.
func _draw_quest(card: Rect2, q: Dictionary) -> void:
	var x := card.position.x + PAD.x
	var w := card.size.x - PAD.x * 2.0
	var y := card.position.y + PAD.y + HEAD_H + 18.0
	var done := bool(q.get("done", false))
	var body := UIKit.font("Alegreya", 600)
	if done:
		draw_string(UIKit.font("Alegreya-Italic"), Vector2(x, y + 6.0), "Bu görev bitti.", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, UIKit.TEXT_DIM)
		y += 40.0
	elif not str(q.get("objective", "")).is_empty():
		draw_string(body, Vector2(x, y + 8.0), HudKit.fit_text(body, str(q["objective"]), 27, w), HORIZONTAL_ALIGNMENT_LEFT, -1, 27, UIKit.TEXT)
		y += 40.0
		var it := UIKit.font("Alegreya-Italic")
		for line in HudKit.wrap_lines(it, str(q.get("detail", "")), 21, w, 2):
			draw_string(it, Vector2(x, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 21, UIKit.TEXT_DIM)
			y += 28.0
	y += 20.0
	var small := UIKit.font("Cinzel", 700, 3)
	draw_string(small, Vector2(x, y), "ADIMLAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(UIKit.GOLD, 0.8))
	draw_line(Vector2(x, y + 10.0), Vector2(x + w, y + 10.0), Color(UIKit.GOLD, 0.18), 1.0)
	y += 24.0
	for s: Dictionary in visible_steps(q.get("steps", [])):
		var state := str(s.get("state", ""))
		var row := Rect2(Vector2(x - 10.0, y), Vector2(w + 20.0, STEP_H - 6.0))
		var c := Vector2(x + 14.0, row.get_center().y)
		var text_col := UIKit.PARCHMENT
		var f := UIKit.font("Alegreya", 500)
		match state:
			"current":
				draw_style_box(UIKit.panel_style(ROW_ACTIVE_BG, Color(UIKit.GOLD, 0.75), 1, 3, Color(0, 0, 0, 0.0), 0), row)
				HudKit.draw_centered(self, "marker_diamond", c, Vector2(24.0, 24.0))
				text_col = UIKit.TEXT
				f = UIKit.font("Alegreya", 700)
			"done":
				HudJournalPage.draw_check(self, c)
				text_col = Color(UIKit.TEXT_DIM, 0.85)
			_:
				text_col = Color(UIKit.TEXT_DIM, 0.55)
		draw_string(f, Vector2(x + 40.0, row.get_center().y + 8.0), HudKit.fit_text(f, str(s.get("text", "")), 22, w - 50.0),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 22, text_col)
		y += STEP_H


## Bitmiş adımın altın işareti.
static func draw_check(ci: CanvasItem, c: Vector2) -> void:
	var pts := PackedVector2Array([c + Vector2(-7.0, 0.0), c + Vector2(-2.0, 6.0), c + Vector2(8.0, -7.0)])
	ci.draw_polyline(pts, Color(0.05, 0.04, 0.02, 0.8), 5.0, true)
	ci.draw_polyline(pts, UIKit.GOLD, 2.6, true)
