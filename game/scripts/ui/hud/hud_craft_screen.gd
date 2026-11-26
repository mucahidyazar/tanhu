class_name HudCraftScreen
extends HudScreen
## Tezgâhın sayfası (economy.md §6.1, §6.7, §13; HUD'un dili: HudScreen'in lacivert panosu, altın Cinzel başlık, HudJournalPage kartları,
## kitabın tuş kapakları). Solda tezgâhta yapılabilecekler iki öbekte: El İşi (Mete'nin tutuşu, ≤8 sn; girdi Heybe'den) ve Tezgâh İşi
## (sipariş; girdi tezgâhın sandığından, iş oyunun saatiyle akar). Sağda seçili tarif: girdiler (var / gerek), çıktı, süre, eksiklerin nedeni
## («Malzeme bekliyor: 2 Bakır Cevheri», «Usta gerek: Demirci»); düğmeler: Yap (el işinde E ya da sol tık basılı tutulur, çubuk dolar,
## bırakınca sıfırlanır), adet (Tezgâh İşi), Eksikleri Al (sandıktan Heybe'ye, Inventory.take_missing), Malzemeyi Bırak (Heybe'den sandığa),
## Hepsini Al (sandıktan Heybe'ye), Birlikte Çalış (Mete tezgâhta bir el olur), Bitene Dek Bekle (sayfa kapanır, saat işin kalanı kadar
## hızlı akar). Altta sıra (ilerleme çubuğu, bekleme nedeni) ve sandığın içeriği. Oyun durur (GatherLayer.open_bench); Esc kapatır.
##   W / S ya da ↑ ↓ seç · E yap · Q / R adet · Esc kapat

const SIZE := Vector2(1240.0, 760.0)
const LIST := Rect2(32.0, 112.0, 452.0, 530.0)
const DETAIL := Rect2(504.0, 112.0, 704.0, 530.0)
const QUEUE := Rect2(32.0, 652.0, 1176.0, 46.0)
const ROW_H := 50.0
const HEAD_H := 30.0
const BTN_H := 44.0
## Etiket → simgesi olan eşya (_tag_icon'un belleği).
static var _tag_icons: Dictionary = {}

## Katman (işler onundur) ve tezgâhın kimliği.
var layer: GatherLayer
var bench_id := ""
## Listenin satırları: [{kind: "head", text} | {kind: "recipe", id, hand}], seçili tarif ve kaydırma.
var rows: Array = []
var selected := ""
var scroll := 0
var quantity := 1
## El işinin tutuşu (sn) ve tutulan düğme.
var hold_t := 0.0
var holding := false
var status := ""
var status_warn := false

var _buttons: Array = []
var _status_left := 0.0
var _hover := -1


func _init() -> void:
	super._init()
	kind = "craft"
	panel_size = SIZE


func _ready() -> void:
	var b := layer.bench(bench_id) if layer else {}
	title = Craft.station_name(str((b.get("row", {}) as Dictionary).get("station", "")), HudBag.lang()) if not b.is_empty() else ""
	_build_rows()
	super._ready()


func _lang() -> String:
	return HudBag.lang()


func _bench() -> Dictionary:
	return layer.bench(bench_id) if layer else {}


func _ws() -> Workshop:
	var b := _bench()
	return b["ws"] if b.has("ws") else null


func _chest() -> ItemContainer:
	var b := _bench()
	return b["chest"] if b.has("chest") else null


func _inv() -> Inventory:
	return layer.gather.inventory as Inventory if layer and layer.gather and layer.gather.inventory is Inventory else null


func _station() -> String:
	return str((_bench().get("row", {}) as Dictionary).get("station", ""))


## Tezgâhın listesi: I. Perde'nin el işleri (her yerde yapılır) ve bu tezgâhın tarifleri (tezgâhın act'ine dek).
func _build_rows() -> void:
	rows.clear()
	var st := _station()
	var act := int((_bench().get("row", {}) as Dictionary).get("act", 1))
	var hand: Array = []
	var queued: Array = []
	for id: String in Craft.recipes_at(st):
		var r := Craft.recipe(id)
		var own := str(r.get("station", "")) == st or (str(r.get("station", "")) == "hearth" and st == "kitchen")
		if not own and int(r.get("act", 1)) > 1:
			continue
		if own and int(r.get("act", 1)) > act:
			continue
		if Craft.is_hand(r):
			hand.append(id)
		elif own and Craft.is_queued(r):
			queued.append(id)
	var lg := _lang()
	if not hand.is_empty():
		rows.append({"kind": "head", "text": Craft.message("hand_work", lg)})
		for id: String in hand:
			rows.append({"kind": "recipe", "id": id, "hand": true})
	if not queued.is_empty():
		rows.append({"kind": "head", "text": Craft.message("station_work", lg)})
		for id: String in queued:
			rows.append({"kind": "recipe", "id": id, "hand": false})
	for r: Dictionary in rows:
		if r["kind"] == "recipe" and selected.is_empty():
			selected = str(r["id"])


func recipe_ids() -> Array:
	var out: Array = []
	for r: Dictionary in rows:
		if r["kind"] == "recipe":
			out.append(r["id"])
	return out


func is_hand(id: String) -> bool:
	for r: Dictionary in rows:
		if r["kind"] == "recipe" and r["id"] == id:
			return bool(r["hand"])
	return false


func select(id: String) -> void:
	if recipe_ids().has(id):
		selected = id
		quantity = 1
		hold_t = 0.0
		holding = false
		_keep_visible()
		queue_redraw_all()


func queue_redraw_all() -> void:
	var p := panel()
	if p:
		p.queue_redraw()


func _say(text: String, warn := false) -> void:
	status = text
	status_warn = warn
	_status_left = 3.0
	queue_redraw_all()


# --- İşler ---------------------------------------------------------------------------------------------------------------------

## El işinin ya da siparişin olabilirliği (can_craft; el işinde Heybe, siparişte sandık).
func check(id: String) -> Dictionary:
	if layer == null:
		return {"ok": false, "missing": []}
	var hand := is_hand(id)
	var pool: Variant = _inv() if hand else _chest()
	return Craft.can_craft(id, {"inv": pool, "station": _station(), "roles": layer.bench_roles(bench_id), "skills": layer.skills(), "n": 1 if hand else quantity})


## Yap: el işi tutuş bitince (GatherLayer.craft_hand); tezgâh işi sipariş olur.
func make() -> bool:
	if selected.is_empty() or layer == null:
		return false
	var lg := _lang()
	if is_hand(selected):
		var res := layer.craft_hand(bench_id, selected)
		if res.is_empty():
			_say(Craft.missing_text(check(selected)["missing"], lg), true)
			return false
		var names := PackedStringArray()
		for e: Dictionary in res["out"]:
			names.append("%d %s" % [int(e["n"]), ItemCatalog.name_of(str(e["id"]), lg)])
		var text := Craft.message("done", lg, {"item": ", ".join(names)})
		if int(res.get("xp", 0)) > 0:
			text += " · " + Craft.message("first", lg, {"xp": int(res["xp"])})
		_say(text)
		MenuStyle.play_ui(self, &"confirm", -8.0)
		return true
	var c := check(selected)
	var station_block := false
	for m: Dictionary in c["missing"]:
		if m.has("station") or m.has("skill"):
			station_block = true
	if station_block:
		_say(Craft.missing_text(c["missing"], lg), true)
		return false
	if layer.order(bench_id, selected, quantity) < 0:
		return false
	_say("%s · %s ×%d" % [Craft.message("queue", lg), Craft.recipe_name(selected, lg), quantity])
	MenuStyle.play_ui(self, &"confirm", -8.0)
	return true


func do_button(action: String) -> bool:
	var lg := _lang()
	match action:
		"make":
			if is_hand(selected):
				holding = true
				return true
			return make()
		"less":
			quantity = maxi(1, quantity - 1)
		"more":
			quantity = mini(20, quantity + 1)
		"take_missing":
			var r := layer.take_missing(bench_id, selected)
			_say(Craft.message("take_missing", lg) + (": " + Craft.list_text(r.get("moved", []), lg) if not (r.get("moved", []) as Array).is_empty() else ""))
		"store":
			var moved := layer.store_materials(bench_id, selected, quantity)
			_say(Craft.message("store_materials", lg) + (": " + Craft.list_text(moved, lg) if not moved.is_empty() else ""))
		"take_all":
			var r := layer.take_all(bench_id)
			_say(Craft.message("take_all", lg) + (": " + Craft.list_text(r.get("moved", []), lg) if not (r.get("moved", []) as Array).is_empty() else ""))
		"help":
			layer.helping[bench_id] = not bool(layer.helping.get(bench_id, false))
		"wait":
			if layer.wait_until_done(bench_id) <= 0.0:
				_say(Craft.wait_text(_ws().wait if _ws() else {}, lg), true)
				return false
			return true
		_:
			return false
	queue_redraw_all()
	return true


func _process(delta: float) -> void:
	if _status_left > 0.0:
		_status_left -= delta
		if _status_left <= 0.0:
			queue_redraw_all()
	if holding:
		var still := Input.is_action_pressed(&"accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		if not still or not is_hand(selected):
			holding = false
			hold_t = 0.0
		else:
			hold_t += delta
			var need := float(Craft.recipe(selected).get("hold", 1.0))
			if hold_t >= need:
				holding = false
				hold_t = 0.0
				make()
		queue_redraw_all()


func hold_k() -> float:
	return clampf(hold_t / maxf(0.05, float(Craft.recipe(selected).get("hold", 1.0))), 0.0, 1.0) if holding else 0.0


# --- Girdi -----------------------------------------------------------------------------------------------------------------------

func _content_input(event: InputEvent) -> bool:
	if event.is_echo():
		return false
	var ids := recipe_ids()
	var at := ids.find(selected)
	if _pressed(event, &"move_forward") or (event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).keycode == KEY_UP):
		if at > 0:
			select(ids[at - 1])
		return true
	if _pressed(event, &"move_back") or (event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).keycode == KEY_DOWN):
		if at < ids.size() - 1:
			select(ids[at + 1])
		return true
	if _pressed(event, &"accept"):
		do_button("make")
		return true
	if event is InputEventKey and (event as InputEventKey).pressed:
		match (event as InputEventKey).keycode:
			KEY_Q:
				do_button("less")
				return true
			KEY_R:
				do_button("more")
				return true
	return false


static func _pressed(event: InputEvent, action: StringName) -> bool:
	return InputMap.has_action(action) and event.is_action_pressed(action)


func _content_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var p := (event as InputEventMouseMotion).position
		var h := -1
		for k in _buttons.size():
			if (_buttons[k]["rect"] as Rect2).has_point(p) and _buttons[k]["on"]:
				h = k
		if h != _hover:
			_hover = h
			queue_redraw_all()
		return
	if not event is InputEventMouseButton:
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed:
		return
	if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
		scroll = maxi(0, scroll - 1)
		queue_redraw_all()
		return
	if mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		scroll = mini(maxi(0, rows.size() - _visible_rows()), scroll + 1)
		queue_redraw_all()
		return
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return
	for b: Dictionary in _buttons:
		if (b["rect"] as Rect2).has_point(mb.position) and b["on"]:
			do_button(str(b["action"]))
			return
	for k in _visible_rows():
		var ri := scroll + k
		if ri >= rows.size():
			break
		if _row_rect(k).has_point(mb.position) and rows[ri]["kind"] == "recipe":
			select(str(rows[ri]["id"]))
			return


func _visible_rows() -> int:
	return int((LIST.size.y - 60.0) / ROW_H)


func _row_rect(k: int) -> Rect2:
	return Rect2(LIST.position + Vector2(14.0, 52.0 + k * ROW_H), Vector2(LIST.size.x - 28.0, ROW_H - 4.0))


func _keep_visible() -> void:
	var at := -1
	for i in rows.size():
		if rows[i]["kind"] == "recipe" and rows[i]["id"] == selected:
			at = i
	if at < 0:
		return
	if at < scroll:
		scroll = at
	elif at >= scroll + _visible_rows():
		scroll = at - _visible_rows() + 1


# --- Çizim --------------------------------------------------------------------------------------------------------------------------

func _draw_content(ci: Control) -> void:
	var lg := _lang()
	_buttons.clear()
	_draw_masters(ci, lg)
	HudJournalPage.draw_card(ci, LIST, "TARİFLER" if lg == "tr" else "RECIPES")
	HudJournalPage.draw_card(ci, DETAIL, Craft.recipe_name(selected, lg).to_upper() if not selected.is_empty() else "")
	_draw_list(ci, lg)
	if not selected.is_empty():
		_draw_detail(ci, lg)
	_draw_queue(ci, lg)


## Başlığın altı: tezgâhtaki ustalar ve eller.
func _draw_masters(ci: Control, lg: String) -> void:
	var names := PackedStringArray()
	for r: Variant in layer.bench_roles(bench_id) if layer else []:
		names.append(Craft.role_name(r, lg))
	var ws := _ws()
	var w: float = float(ws.crew.get("W", 0.0)) if ws else 0.0
	var text := "%s · %s" % [(("Usta: " if lg == "tr" else "Masters: ") + ", ".join(names)) if not names.is_empty() else "", Craft.message("crew", lg, {"w": _num(w)})]
	HudKit.draw_text(ci, HudKit.body_font(500), Vector2(SIZE.x * 0.5, 100.0), text.lstrip(" ·"), 18, HudKit.TEXT_DIM, 1, HudKit.SHADOW, 2)


func _draw_list(ci: Control, lg: String) -> void:
	var f := HudKit.body_font(600)
	var sf := HudKit.body_font(400)
	for k in _visible_rows():
		var ri := scroll + k
		if ri >= rows.size():
			break
		var row: Dictionary = rows[ri]
		var r := _row_rect(k)
		if row["kind"] == "head":
			HudKit.draw_text(ci, UIKit.font("Cinzel", 700, 2), Vector2(r.position.x + 6.0, r.position.y + 34.0), str(row["text"]).to_upper(), 16, HudKit.GOLD_DEEP, 0, Color(0, 0, 0, 0), 0)
			ci.draw_line(Vector2(r.position.x + 6.0, r.end.y - 6.0), Vector2(r.end.x - 6.0, r.end.y - 6.0), Color(UIKit.GOLD, 0.25), 1.0)
			continue
		var id := str(row["id"])
		var on := id == selected
		var ok := bool(check(id)["ok"])
		var bg := Color(0.12, 0.09, 0.05, 0.9) if on else Color(0.03, 0.04, 0.06, 0.55)
		ci.draw_style_box(UIKit.panel_style(bg, Color(UIKit.GOLD, 0.9) if on else Color(UIKit.GOLD_DIM, 0.45), 1, 3, Color(0, 0, 0, 0.0), 0), r)
		var out_id := _first_out(id)
		HudItemIcon.draw(ci, out_id, r.position + Vector2(26.0, r.size.y * 0.5), 34.0, Color(1, 1, 1, 1.0 if ok else 0.55))
		ci.draw_string(f, r.position + Vector2(54.0, 21.0), HudKit.fit_text(f, Craft.recipe_name(id, lg), 19, r.size.x - 80.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 19,
			UIKit.TEXT if ok else UIKit.TEXT_DIM)
		ci.draw_string(sf, r.position + Vector2(54.0, 40.0), _kind_line(id, lg), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, UIKit.TEXT_DIM)
		ci.draw_circle(Vector2(r.end.x - 16.0, r.get_center().y), 5.0, UIKit.SKY if ok else Color(UIKit.GOLD_DIM, 0.7))
	if rows.size() > _visible_rows():
		var track := Rect2(LIST.end.x - 8.0, LIST.position.y + 52.0, 3.0, _visible_rows() * ROW_H)
		ci.draw_rect(track, Color(UIKit.GOLD_DIM, 0.4))
		var k := float(_visible_rows()) / rows.size()
		ci.draw_rect(Rect2(track.position + Vector2(0, track.size.y * float(scroll) / rows.size()), Vector2(3.0, track.size.y * k)), Color(UIKit.GOLD, 0.8))


func _first_out(id: String) -> String:
	for out_id: String in (Craft.recipe(id).get("out", {}) as Dictionary):
		return out_id
	return ""


## «El İşi · 2 sn» ya da «Tezgâh İşi · 6 iş saati».
func _kind_line(id: String, lg: String) -> String:
	var r := Craft.recipe(id)
	if is_hand(id):
		return "%s · %s sn" % [Craft.message("hand_work", lg), _num(float(r.get("hold", 0.0)))]
	var line := "%s · %s" % [Craft.message("station_work", lg), Craft.message("work_hours", lg, {"h": _num(float(r.get("wh", 0.0)))})]
	if float(r.get("cure", 0.0)) > 0.0:
		line += " · " + Craft.message("cure", lg, {"h": _num(float(r["cure"]))})
	return line


static func _num(v: float) -> String:
	return str(int(v)) if is_equal_approx(v, roundf(v)) else String.num(v, 2).replace(".", ",")


func _draw_detail(ci: Control, lg: String) -> void:
	var r := Craft.recipe(selected)
	var hand := is_hand(selected)
	var f := HudKit.body_font(600)
	var sf := HudKit.body_font(400)
	var x := DETAIL.position.x + 34.0
	var y := DETAIL.position.y + 78.0
	HudItemIcon.draw(ci, _first_out(selected), Vector2(x + 44.0, y + 40.0), 80.0)
	var outs := PackedStringArray()
	for out_id: String in (r.get("out", {}) as Dictionary):
		outs.append("%d %s" % [int(r["out"][out_id]) * (1 if hand else quantity), ItemCatalog.name_of(out_id, lg) if not out_id.begins_with("@") else out_id])
	ci.draw_string(f, Vector2(x + 110.0, y + 26.0), " + ".join(outs), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, UIKit.GOLD)
	ci.draw_string(sf, Vector2(x + 110.0, y + 54.0), _kind_line(selected, lg), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UIKit.TEXT_DIM)
	if not hand:
		var ws := _ws()
		# Eller şimdiki hâliyle (Birlikte Çalış basılınca hemen; tezgâhın W'si saatin adımında yazılır).
		var crew := layer.bench_crew(bench_id) if layer else (float(ws.crew.get("W", 0.0)) if ws else 0.0)
		var eta := Craft.unit_minutes(selected, crew) * quantity / 60.0
		var eta_text := Craft.message("eta", lg, {"h": _num(snappedf(eta, 0.1))}) if is_finite(eta) else Craft.message("no_crew", lg)
		ci.draw_string(sf, Vector2(x + 110.0, y + 78.0), eta_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UIKit.TEXT_DIM)
	y += 118.0
	ci.draw_line(Vector2(x, y), Vector2(DETAIL.end.x - 34.0, y), Color(UIKit.GOLD, 0.25), 1.0)
	y += 30.0
	var pool: Variant = _inv() if hand else _chest()
	var where := Craft.message("pack", lg) if hand else Craft.message("chest", lg)
	ci.draw_string(UIKit.font("Cinzel", 700, 2), Vector2(x, y), ("GİRDİ · " if lg == "tr" else "INPUT · ") + where.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, HudKit.GOLD_DEEP)
	y += 12.0
	for e: Dictionary in Craft.inputs_of(selected):
		y += 34.0
		var need := int(e["n"]) * (1 if hand else quantity)
		var have := Craft.pool_count(pool, str(e["id"]))
		var enough := have >= need
		var ref := str(e["id"])
		var icon_id := HudCraftScreen._tag_icon(ref.substr(4)) if ref.begins_with("tag:") else ref
		if not icon_id.is_empty():
			HudItemIcon.draw(ci, icon_id, Vector2(x + 16.0, y - 7.0), 28.0)
		ci.draw_string(f, Vector2(x + 40.0, y), Craft.ref_name(ref, lg), HORIZONTAL_ALIGNMENT_LEFT, -1, 19, UIKit.TEXT)
		var count := "%d / %d" % [have, need]
		var nf := HudKit.number_font(600)
		ci.draw_string(nf, Vector2(x + 420.0, y), count, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, UIKit.SKY if enough else UIKit.EMBER)
	var c := check(selected)
	y += 40.0
	if not c["ok"]:
		ci.draw_string(sf, Vector2(x, y), HudKit.fit_text(sf, Craft.missing_text(c["missing"], lg), 18, DETAIL.size.x - 68.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UIKit.EMBER)
	# Düğmeler: Yap (ve adet), malzemenin yolu, sandık, birlikte çalış, bekle.
	var by := DETAIL.end.y - 2.0 * BTN_H - 30.0
	var bx := x
	var make_label := Craft.message("make", lg)
	if hand:
		make_label += " · " + Craft.message("hold_to_make", lg, {"s": _num(float(r.get("hold", 1.0)))})
	bx = _button(ci, Vector2(bx, by), make_label, "make", true, true)
	if not hand:
		bx = _button(ci, Vector2(bx + 10.0, by), "−", "less", quantity > 1)
		ci.draw_string(HudKit.number_font(600), Vector2(bx + 14.0, by + 30.0), "×%d" % quantity, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, UIKit.GOLD)
		bx = _button(ci, Vector2(bx + 66.0, by), "+", "more", quantity < 20)
	var chest := _chest()
	var by2 := by + BTN_H + 12.0
	var bx2 := x
	if hand:
		bx2 = _button(ci, Vector2(bx2, by2), Craft.message("take_missing", lg), "take_missing", chest != null and not chest.is_empty())
	else:
		bx2 = _button(ci, Vector2(bx2, by2), Craft.message("store_materials", lg), "store", true)
		var on := bool(layer.helping.get(bench_id, false)) if layer else false
		bx2 = _button(ci, Vector2(bx2 + 10.0, by2), ("✓ " if on else "") + Craft.message("work_with", lg), "help", true)
		var ws := _ws()
		bx2 = _button(ci, Vector2(bx2 + 10.0, by2), Craft.message("work_until_done", lg), "wait", ws != null and (not ws.queue.is_empty() or not ws.cures.is_empty()))
	# Sandığı boşaltmak: el işinde alt sırada; tezgâh işinde alt sıra dolu (üç düğme), üst sıranın sağ ucuna yaslanır.
	var take_label := Craft.message("take_all", lg)
	var take_at := Vector2(bx2 + 10.0, by2) if hand else Vector2(DETAIL.end.x - 34.0 - _button_w(take_label), by)
	_button(ci, take_at, take_label, "take_all", chest != null and not chest.is_empty())
	if holding:
		var bar := Rect2(Vector2(x, by - 12.0), Vector2(DETAIL.size.x - 68.0, 5.0))
		ci.draw_rect(bar, Color(UIKit.GOLD_DIM, 0.5))
		ci.draw_rect(Rect2(bar.position, Vector2(bar.size.x * hold_k(), bar.size.y)), UIKit.GOLD)


## Düğme (kitabın seçme düğmesi gibi): koyu yuva, ince altın kenar, krem yazı; kapalıysa soluk. → sağ kenar.
func _button(ci: Control, at: Vector2, text: String, action: String, on: bool, primary := false) -> float:
	var f := UIKit.font("AlegreyaSC-Regular", 400, 1)
	var r := Rect2(at, Vector2(_button_w(text), BTN_H))
	var hot := on and _hover == _buttons.size()
	var a := 1.0 if on else 0.38
	var border := UIKit.SKY if hot else (Color(UIKit.GOLD, 0.9) if primary else Color(UIKit.GOLD_DIM, 0.7))
	ci.draw_style_box(UIKit.panel_style(Color(0.03, 0.04, 0.06, 0.85 * a), Color(border, a), 1, 3, Color(0, 0, 0, 0.3 * a), 6), r)
	ci.draw_string(f, Vector2(r.position.x + 17.0, r.get_center().y + 7.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color(UIKit.SKY if hot else UIKit.PARCHMENT, a))
	_buttons.append({"rect": r, "action": action, "on": on})
	return r.end.x


## Etiketin simgesi (tag:wood → kataloğun o etiketli ilk eşyası, çam odunu); bir kez aranır.
static func _tag_icon(tag: String) -> String:
	if not _tag_icons.has(tag):
		var found := ""
		for id in ItemCatalog.ids():
			if ItemCatalog.has_tag(id, tag):
				found = id
				break
		_tag_icons[tag] = found
	return str(_tag_icons[tag])


## Düğmenin genişliği (yazı ve iki yanı 17 px; en az 56 px).
static func _button_w(text: String) -> float:
	return maxf(56.0, UIKit.font("AlegreyaSC-Regular", 400, 1).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x + 34.0)


## Altta: sıra (tarif, adet, ilerleme, bekleme nedeni), yuvalar ve sandığın içeriği.
func _draw_queue(ci: Control, lg: String) -> void:
	ci.draw_style_box(UIKit.panel_style(Color(0.02, 0.03, 0.05, 0.7), Color(UIKit.GOLD_DIM, 0.5), 1, 3, Color(0, 0, 0, 0.0), 0), QUEUE)
	var f := HudKit.body_font(500)
	var x := QUEUE.position.x + 16.0
	var y := QUEUE.position.y + 29.0
	var ws := _ws()
	var parts := PackedStringArray()
	if ws:
		var st := ws.status()
		for q: Dictionary in st["queue"]:
			parts.append("%s ×%d %d%%" % [Craft.recipe_name(str(q["recipe"]), lg), int(q["n"]), roundi(float(q["progress"]) * 100.0)])
		for cv: Dictionary in st["cures"]:
			parts.append("%s %s" % [Craft.recipe_name(str(cv["recipe"]), lg), Craft.message("cure", lg, {"h": _num(snappedf(float(cv["hours"]), 0.1))})])
	var qtext := "%s: %s" % [Craft.message("queue", lg), " · ".join(parts) if not parts.is_empty() else "—"]
	var wait := Craft.wait_text(ws.wait, lg) if ws else ""
	if not wait.is_empty() and not parts.is_empty():
		qtext += "  ·  " + wait
	ci.draw_string(f, Vector2(x, y), HudKit.fit_text(f, qtext, 18, 640.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UIKit.EMBER if not wait.is_empty() and not parts.is_empty() else UIKit.TEXT)
	var chest := _chest()
	var items := PackedStringArray()
	if chest:
		for e: Dictionary in chest.list():
			items.append("%d %s" % [int(e["n"]), ItemCatalog.name_of(str(e["id"]), lg)])
	var ctext := "%s: %s" % [Craft.message("chest", lg), ", ".join(items) if not items.is_empty() else "—"]
	ci.draw_string(f, Vector2(x + 680.0, y), HudKit.fit_text(f, ctext, 18, 480.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UIKit.TEXT_DIM)


func _draw_footer(ci: Control) -> void:
	var lg := _lang()
	var hints: Array = [["Esc", "Kapat" if lg == "tr" else "Close"], ["W S", "Seç" if lg == "tr" else "Select"], ["E", Craft.message("make", lg)],
		["Q R", "Adet" if lg == "tr" else "Amount"]]
	var f := UIKit.font("AlegreyaSC-Regular", 400)
	var x := 40.0
	var y := SIZE.y - 30.0
	for h: Array in hints:
		var kw := GameMenu.keycap_width(str(h[0]))
		GameMenu.draw_keycap(ci, Rect2(Vector2(x, y - 17.0), Vector2(kw, 34.0)), str(h[0]))
		ci.draw_string(f, Vector2(x + kw + 10.0, y + 7.0), str(h[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UIKit.PARCHMENT)
		x += kw + 10.0 + f.get_string_size(str(h[1]), HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + 40.0
	if _status_left > 0.0 and not status.is_empty():
		var sf := UIKit.font("Alegreya", 600)
		var a := clampf(_status_left / 0.4, 0.0, 1.0)
		var sw := sf.get_string_size(status, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
		ci.draw_string(sf, Vector2(SIZE.x - 40.0 - minf(sw, 560.0), y + 7.0), HudKit.fit_text(sf, status, 19, 560.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 19,
			Color(UIKit.EMBER if status_warn else UIKit.SKY, a))
