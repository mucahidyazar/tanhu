class_name CookWheel
extends Control
## Tarif çemberi (survival.md §3, K45; HUD'un dilinde: lacivert-altın altıgen yuvalar, Cinzel başlık, Alegreya gövde): ateşin yanında E
## açar, oyun durmaz. Yuvalar bilinen ateş tarifleridir (pişebilen parlak, öteki soluk ve nedeni yazar: «Eksik: Et», «Kazan için taş halkası
## ve küçük kazan gerek»), ardından iki dilim: Yakıt (Y'nin ekleyeceği tür; seçmek sıradakine çevirir: tezek, dal, odun) ve Ocağa Pay
## (aç-kapa; ateş başına günde bir). Seçim: fareyle ya da 1–9; E ve Esc kapatır. Ekranın ortasına çapalıdır (K98 kadrajında Mete ortada),
## 1080 satıra çizilir, UIKit.ui_k() × HUD ölçeğiyle büyür.
##   var w := CookWheel.new()
##   w.setup(survival, fire)
##   w.chosen.connect(func(id: String, share: bool) -> void: ...)

signal chosen(recipe_id: String, share: bool)
signal closed

const RADIUS := 128.0
const SLOT := Vector2(76.0, 72.0)
const ICON := 34.0
const TITLE_SIZE := 20
const NAME_SIZE := 15
const INFO_SIZE := 17
## Ekranın ortasından aşağı kayma (1080 satır): çember Mete'nin göğsünün çevresinde durur.
const CENTER_DROP := 10.0

var survival: Survival
var fire: FireState
## Ocağa Pay açık mı (sonraki pişirmeye).
var share := false

var _slots: Array = []
var _hover := -1
var _k := 1.0


func _init() -> void:
	name = "CookWheel"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	UIKit.full_rect(self)
	focus_mode = Control.FOCUS_NONE
	_rebuild()


func setup(p_survival: Survival, p_fire: FireState) -> void:
	survival = p_survival
	fire = p_fire
	_rebuild()


## Yuvalar: [{kind: "recipe" | "fuel" | "share", id, name, ok, reason, missing}].
func slots() -> Array:
	return _slots


func _rebuild() -> void:
	_slots = []
	if survival == null:
		return
	for o: Dictionary in survival.cook_options(fire):
		var row := o.duplicate()
		row["kind"] = "recipe"
		_slots.append(row)
	# Yerleşimin ocağını halk besler: Yakıt dilimi yok.
	if fire == null or not fire.hearth:
		_slots.append({"kind": "fuel", "id": survival.fuel_choice, "ok": true,
			"name": Cooking.text("fuel_slice", survival.lang, {"fuel": survival.fuel_name(survival.fuel_choice)})})
	var can_share := fire != null and fire.can_share(survival.day())
	_slots.append({"kind": "share", "id": "share", "ok": can_share, "name": Cooking.text("share_slice", survival.lang)})
	if not can_share:
		share = false
	queue_redraw()


## Seçer (1–9, tık): tarifte pişirmeye başlanır (chosen), Yakıt dilimi sıradakine döner, Ocağa Pay aç-kapa. Döner: iş yapıldı mı.
func pick(index: int) -> bool:
	if index < 0 or index >= _slots.size():
		return false
	var s: Dictionary = _slots[index]
	match str(s["kind"]):
		"fuel":
			survival.cycle_fuel()
			_rebuild()
			return true
		"share":
			if not bool(s["ok"]):
				return false
			share = not share
			queue_redraw()
			return true
	if not bool(s["ok"]):
		return false
	chosen.emit(str(s["id"]), share)
	return true


func close() -> void:
	closed.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event is InputEventKey or not (event as InputEventKey).pressed or (event as InputEventKey).echo:
		return
	var key := (event as InputEventKey).physical_keycode
	if key >= KEY_1 and key <= KEY_9:
		if pick(int(key - KEY_1)):
			get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := _slot_at((event as InputEventMouseMotion).position)
		if h != _hover:
			_hover = h
			queue_redraw()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var i := _slot_at((event as InputEventMouseButton).position)
		if i >= 0:
			pick(i)
			accept_event()
		else:
			close()
			accept_event()


func _center() -> Vector2:
	return size * 0.5 + Vector2(0.0, CENTER_DROP * _k)


func _slot_center(i: int) -> Vector2:
	var n := maxi(_slots.size(), 1)
	var a := -PI * 0.5 + TAU * float(i) / float(n)
	return _center() + Vector2(cos(a), sin(a)) * RADIUS * _k


func _slot_at(p: Vector2) -> int:
	for i in _slots.size():
		if p.distance_to(_slot_center(i)) <= SLOT.y * 0.5 * _k:
			return i
	return -1


func _process(_delta: float) -> void:
	var k := UIKit.ui_k() * HudKit.hud_scale()
	if not is_equal_approx(k, _k):
		_k = k
		queue_redraw()


func _draw() -> void:
	if survival == null:
		return
	var c := _center()
	# Çemberin zemini: ince lacivert halka.
	draw_circle(c, (RADIUS + SLOT.y * 0.62) * _k, Color(HudKit.NAVY_DEEP, 0.42))
	draw_arc(c, (RADIUS + SLOT.y * 0.62) * _k, 0.0, TAU, 72, Color(HudKit.GOLD, 0.45), 2.0 * _k, true)
	draw_arc(c, (RADIUS - SLOT.y * 0.62) * _k, 0.0, TAU, 72, Color(HudKit.GOLD, 0.3), 1.5 * _k, true)
	var title := Cooking.text("cook_title", survival.lang)
	HudKit.draw_text(self, HudKit.title_font(), c + Vector2(0.0, -8.0 * _k), title.to_upper(), int(TITLE_SIZE * _k), HudKit.GOLD, 1)
	if fire and fire.is_lit():
		var stage_name := Catalog.pick(fire.stage_row().get("name", ""), survival.lang)
		HudKit.draw_text(self, HudKit.body_font(500), c + Vector2(0.0, 16.0 * _k), stage_name, int(NAME_SIZE * _k), HudKit.TEXT_DIM, 1)
	for i in _slots.size():
		_draw_slot(i, _slots[i])
	_draw_info()


func _draw_slot(i: int, s: Dictionary) -> void:
	var p := _slot_center(i)
	var ok := bool(s.get("ok", false))
	var on := str(s["kind"]) == "share" and share
	var mod := Color(1.0, 1.0, 1.0, 1.0 if ok else 0.5)
	if i == _hover:
		HudKit.draw_centered(self, "slot_hex", p, SLOT * _k * 1.12, Color(1.25, 1.15, 0.9, mod.a))
	else:
		HudKit.draw_centered(self, "slot_hex", p, SLOT * _k, mod)
	match str(s["kind"]):
		"recipe":
			HudItemIcon.draw(self, str(s["id"]), p, ICON * _k, mod)
		"fuel":
			HudItemIcon.draw_glyph(self, "twigs" if survival.fuel_choice == "branch" else ("log" if survival.fuel_choice == "wood" else "block"), p,
				ICON * 0.5 * _k, mod)
		"share":
			HudItemIcon.draw_glyph(self, "bowl", p, ICON * 0.5 * _k, Color(1.0, 0.85, 0.5, mod.a) if on else mod)
			if on:
				draw_arc(p, SLOT.y * 0.42 * _k, 0.0, TAU, 32, Color(HudKit.GOLD, 0.95), 3.0 * _k, true)
	# Tuş rozeti (1–9) ve ad.
	if i < 9:
		HudKit.draw_text(self, HudKit.number_font(600), p + Vector2(-SLOT.x * 0.36 * _k, -SLOT.y * 0.28 * _k), str(i + 1), int(13 * _k),
			Color(HudKit.CREAM, mod.a), 1)
	var name_text := HudKit.fit_text(HudKit.body_font(500), str(s.get("name", "")), int(NAME_SIZE * _k), 132.0 * _k)
	HudKit.draw_text(self, HudKit.body_font(500), p + Vector2(0.0, (SLOT.y * 0.5 + 16.0) * _k), name_text, int(NAME_SIZE * _k),
		Color(HudKit.CREAM, 1.0 if ok else 0.6), 1)


## Seçili (fare altındaki) yuvanın açıklaması: girdi, süre, Tokluk; pişemiyorsa nedeni.
func _draw_info() -> void:
	if _hover < 0 or _hover >= _slots.size():
		return
	var s: Dictionary = _slots[_hover]
	var text := ""
	match str(s["kind"]):
		"recipe":
			var rec := Cooking.recipe(str(s["id"]))
			var parts := PackedStringArray()
			for ref: String in rec.get("in", {}):
				parts.append("%d %s" % [int(rec["in"][ref]), survival.ref_name(ref)])
			text = " · ".join(parts)
			var full := Needs.fullness_of(str(s["id"]))
			if full > 0.0:
				text += " · %s +%d" % [Catalog.pick((Needs.data().get("text", {}) as Dictionary).get("fullness", "Tokluk"), survival.lang), int(full)]
			match str(s.get("reason", "")):
				"missing":
					var names := PackedStringArray()
					for ref: String in s.get("missing", {}):
						names.append(survival.ref_name(ref))
					text = Cooking.text("missing", survival.lang, {"items": ", ".join(names)})
				"no_pot":
					text = Cooking.text("no_pot", survival.lang)
				"no_station":
					text = Cooking.text("no_station", survival.lang)
				"weather":
					text = Cooking.text("weather_blocks", survival.lang)
		"share":
			text = Cooking.text("share_on", survival.lang) if bool(s["ok"]) else Cooking.text("share_used", survival.lang)
		"fuel":
			text = str(s["name"])
	if text.is_empty():
		return
	var y := _center().y + (RADIUS + SLOT.y + 34.0) * _k
	var font := HudKit.body_font(500)
	var w := HudKit.text_width(font, text, int(INFO_SIZE * _k)) + 40.0 * _k
	draw_rect(Rect2(Vector2(_center().x - w * 0.5, y - 22.0 * _k), Vector2(w, 32.0 * _k)), Color(HudKit.NAVY_DEEP, 0.78))
	HudKit.draw_text(self, font, Vector2(_center().x, y), text, int(INFO_SIZE * _k), HudKit.CREAM, 1)
