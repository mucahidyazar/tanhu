class_name HudWaitWheel
extends Control
## Bekle tekerinin yüzü (HUD'un dilinde; time.md §7.1, §7.2, §11 «Gök Kavisi»): ekranın ortasında gümüş-mavi bulut kıvrımlı halka
## (map_ring_large), içinde günün kavisi: 24 saatlik kadran, evrelerin renkli şeridi (gece lacivert, tan gül, sabah soluk altın, öğle gök
## mavisi, ikindi kehribar, akşam mor), şimdinin güneşi ya da ayı. Çevresinde en çok altı lacivert-altın altıgen (slot_hex): içinde hedef
## saat, sol üstünde tuşu (1–6), yanında satırın adı ve süresi; soluk satır nedenini söyler. Üstte başlık (Cinzel altın, görev çubuğunun
## süsüyle) ve tarih, altta tuşlar. Seçilen satırın kavisi altın yayla çizilir, hedefte baklava; ortada «→ 17:38».
## Akış (run_*): altıgenler söner, ekran %60'a kararır, kadranın güneşi saatle yürür (≤3 sa görünür akış); uzun atlama ve uykuda perde
## kararır, kavis kara perdenin üstünde 1,6 sn'de hedefe döner (turn_arc).
## Girdi: 1–6 ya da tık seçer, Esc ya da T kapatır; fare satırın altıgeninde ya da yazısında. Arayüz 1080 satıra çizilir, ekranın
## ortasında UIKit.ui_k() × HUD ölçeğiyle büyür.

signal chosen(index: int)
signal cancelled

## Kadran: iç disk, evre şeridi (iç, dış), dış yay; halkanın iç yarıçapı.
const R_DIAL := 150.0
const BAND_IN := 96.0
const BAND_OUT := 128.0
const ARC_R := 140.0
## Altıgenlerin elipsi (yatay, dikey yarıçap) ve boyu; yazının altıgenden uzaklığı ve genişliği.
const SLOT_RX := 320.0
const SLOT_RY := 250.0
const SLOT_SIZE := Vector2(86.0, 82.0)
const LABEL_GAP := 56.0
const LABEL_WIDTH := 300.0
## Başlık, tarih ve tuş satırının yükseklikleri (merkeze göre).
const TITLE_Y := -372.0
const SUB_Y := -334.0
const FOOT_Y := 352.0
## Karartma: seçerken ve akışta (time.md §7.2: %60).
const DIM_CHOOSE := 0.42
const DIM_RUN := 0.6
const FADE := 0.22
## Evrelerin şerit renkleri.
const PHASE_COLORS := {
	&"night": Color("#1d2c4f"), &"dawn": Color("#c98f86"), &"morning": Color("#ead09a"), &"noon": Color("#9fc6ea"),
	&"golden": Color("#e8b465"), &"dusk": Color("#8a6aa3"),
}
const SUN := Color("#ffd87a")
const MOON := Color("#e9eef7")

## Satırlar (WaitPlan.rows) ve kip.
var rows: Array[Dictionary] = []
var mode: StringName = &"wait"
var lang := "tr"
## Başlık ve tarih satırı.
var title_text := ""
var sub_text := ""
## Kadranın saati (okunur).
var clock: GameClock
## Seçili satır (klavye) ve üzerinde durulan (fare); yoksa -1.
var selected := -1
var hovered := -1

var _alpha := 0.0
var _dim := 0.0
var _slots_alpha := 1.0
var _running := false
## Akışın kavisi: başı ve hedefi (mutlak dk); turn_arc süren dönüşte gösterilen an.
var _run_from := NAN
var _run_to := NAN
var _turn_at := NAN
var _tween: Tween
var _vignette: Texture2D


func _ready() -> void:
	name = "WaitWheel" if name.is_empty() else name
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(self)
	visible = false


## Tekeri gösterir (satırlar, kip, saat).
func open(p_rows: Array[Dictionary], p_mode: StringName, p_clock: GameClock, p_title: String, p_sub: String) -> void:
	rows = p_rows
	mode = p_mode
	clock = p_clock
	title_text = p_title
	sub_text = p_sub
	selected = -1
	hovered = -1
	_running = false
	_run_from = NAN
	_run_to = NAN
	_turn_at = NAN
	_slots_alpha = 1.0
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_fade_to({"_alpha": 1.0, "_dim": DIM_CHOOSE}, FADE)


## Tekeri kapatır (akış yoksa); anında da olabilir.
func close(instant: bool = false) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_running = false
	if instant:
		_kill()
		_alpha = 0.0
		_dim = 0.0
		visible = false
		return
	_fade_to({"_alpha": 0.0, "_dim": 0.0}, FADE, true)


func is_open() -> bool:
	return visible and not _running and mouse_filter == Control.MOUSE_FILTER_STOP


## Akış başlar: altıgenler söner, ekran %60'a kararır; kadran saatle yürür.
func run_begin(row: Dictionary, from_abs: float) -> void:
	_running = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_run_from = from_abs
	_run_to = float(row.get("target", NAN))
	selected = rows.find(row)
	_fade_to({"_slots_alpha": 0.0, "_dim": DIM_RUN, "_alpha": 1.0}, 0.4)


## Uzun atlamada kavis kara perdenin üstünde seconds sn'de hedefe döner (gösterim; saat sonra atlar).
func turn_arc(seconds: float) -> void:
	if not is_finite(_run_from) or not is_finite(_run_to):
		return
	_kill()
	_turn_at = _run_from
	_tween = create_tween()
	_tween.tween_property(self, ^"_turn_at", _run_to, maxf(seconds, 0.01)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


## Akış bitti: kadran söner.
func run_end(seconds: float = 0.3) -> void:
	_running = false
	_fade_to({"_alpha": 0.0, "_dim": 0.0}, seconds, true)


func is_running() -> bool:
	return _running


## Kadrandaki an (mutlak dk): dönüş sürüyorsa dönüşün anı, değilse saatin.
func shown_minute() -> float:
	if is_finite(_turn_at):
		return _turn_at
	return clock.abs_minute() if clock else 0.0


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _fade_to(props: Dictionary, seconds: float, hide_after: bool = false) -> void:
	_kill()
	_tween = create_tween().set_parallel(true)
	for key: String in props:
		_tween.tween_property(self, NodePath(key), float(props[key]), seconds).set_trans(Tween.TRANS_SINE)
	if hide_after:
		_tween.chain().tween_callback(func() -> void:
			if not _running and _alpha <= 0.001:
				visible = false)


func _kill() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()


# --- Girdi ----------------------------------------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if visible and _running and (event is InputEventKey or event is InputEventMouseButton):
		# Atlama sürerken (görünür akış, karartma) öteki tuşlar (I, J, M, Esc) işlemez: akış yarıda bir sayfaya düşmesin.
		get_viewport().set_input_as_handled()
		return
	if not is_open():
		return
	_handle_open_input(event)
	# Teker açıkken başka tuş (I, J, M, Boşluk) oyuna geçmez.
	if event is InputEventKey and is_inside_tree():
		get_viewport().set_input_as_handled()


func _handle_open_input(event: InputEvent) -> void:
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		var key := (event as InputEventKey).physical_keycode
		if key >= KEY_1 and key <= KEY_6:
			_pick(int(key - KEY_1))
			get_viewport().set_input_as_handled()
			return
		if key == KEY_UP or key == KEY_LEFT:
			_step_selection(-1)
			get_viewport().set_input_as_handled()
			return
		if key == KEY_DOWN or key == KEY_RIGHT:
			_step_selection(1)
			get_viewport().set_input_as_handled()
			return
		if (key == KEY_ENTER or key == KEY_KP_ENTER or key == KEY_SPACE) and selected >= 0:
			_pick(selected)
			get_viewport().set_input_as_handled()
			return
	if event.is_action_pressed(&"pause") or event.is_action_pressed(&"undo") or (InputMap.has_action(&"wait") and event.is_action_pressed(&"wait")):
		get_viewport().set_input_as_handled()
		cancelled.emit()
		return
	if event is InputEventMouseMotion:
		hovered = row_at((event as InputEventMouseMotion).position)
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			var i := row_at(mb.position)
			get_viewport().set_input_as_handled()
			if i >= 0:
				_pick(i)
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			get_viewport().set_input_as_handled()
			cancelled.emit()


func _pick(i: int) -> void:
	if i < 0 or i >= rows.size():
		return
	selected = i
	if not bool(rows[i].get("enabled", false)):
		MenuStyle.play_ui(self, &"click", -14.0)
		return
	chosen.emit(i)


func _step_selection(d: int) -> void:
	if rows.is_empty():
		return
	selected = posmod((selected if selected >= 0 else (-1 if d > 0 else 0)) + d, rows.size())


# --- Yerleşim (1080 satır, merkeze göre) ------------------------------------------------------------------------------

## Ölçek (ui_k × HUD ölçeği).
func scale_k() -> float:
	return UIKit.ui_k() * HudKit.hud_scale()


## Satırın altıgeninin merkezi (merkeze göre, 1080 satır). n satır saat yönünde, birincisi sağ üstte.
static func slot_center(i: int, n: int) -> Vector2:
	var a := deg_to_rad(slot_angle(i, n))
	return Vector2(cos(a) * SLOT_RX, sin(a) * SLOT_RY)


## Satırın açısı (derece; 0 sağ, saat yönünde): altı satırda saatin 1, 3, 5, 7, 9 ve 11'i.
static func slot_angle(i: int, n: int) -> float:
	if n <= 1:
		return 0.0
	return -90.0 + 360.0 / float(n) * (float(i) + 0.5)


## Ekrandaki noktanın satırı (altıgen ya da yazısı; yoksa -1).
func row_at(screen_pos: Vector2) -> int:
	var k := scale_k()
	var p := (screen_pos - size * 0.5) / maxf(k, 0.001)
	for i in rows.size():
		var c := slot_center(i, rows.size())
		if p.distance_to(c) <= SLOT_SIZE.x * 0.5:
			return i
		if _label_rect(i).has_point(p):
			return i
	return -1


func _label_rect(i: int) -> Rect2:
	var c := slot_center(i, rows.size())
	var right := c.x >= -1.0
	var x := c.x + LABEL_GAP if right else c.x - LABEL_GAP - LABEL_WIDTH
	return Rect2(x, c.y - 30.0, LABEL_WIDTH, 60.0)


## Günün dakikasının kadrandaki açısı (radyan; 00:00 altta, 06:00 solda, 12:00 üstte, 18:00 sağda).
static func dial_angle(minute_of_day: float) -> float:
	return PI * 0.5 + minute_of_day / GameClock.DAY_MIN * TAU


# --- Çizim ----------------------------------------------------------------------------------------------------------

func _draw() -> void:
	if _dim > 0.001:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.02, _dim * 0.75))
		_draw_vignette(_dim)
	if _alpha <= 0.001:
		return
	var k := scale_k()
	draw_set_transform(size * 0.5, 0.0, Vector2(k, k))
	_draw_dial()
	if _slots_alpha > 0.001:
		_draw_header()
		for i in rows.size():
			_draw_slot(i)
		_draw_footer()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_vignette(a: float) -> void:
	if _vignette == null:
		var g := Gradient.new()
		g.set_color(0, Color(0, 0, 0, 0))
		g.set_color(1, Color(0, 0, 0, 1))
		g.add_point(0.55, Color(0, 0, 0, 0.0))
		var t := GradientTexture2D.new()
		t.gradient = g
		t.fill = GradientTexture2D.FILL_RADIAL
		t.fill_from = Vector2(0.5, 0.5)
		t.fill_to = Vector2(1.0, 0.5)
		t.width = 256
		t.height = 256
		_vignette = t
	draw_texture_rect(_vignette, Rect2(Vector2(-size.x * 0.12, -size.y * 0.12), size * 1.24), false, Color(1, 1, 1, 0.85 * a))


func _draw_dial() -> void:
	var a := _alpha
	var now := shown_minute()
	var day := floori(now / GameClock.DAY_MIN)
	var m := now - float(day) * GameClock.DAY_MIN
	var info: Dictionary = clock.info_at(day) if clock else {}
	# İç disk: gündüz gök mavisi, gece lacivert (ışık düzeyinden).
	var light := clampf(clock.light_level_at(now) if clock else 1.0, 0.0, 1.0)
	var disc := HudKit.NAVY_DEEP.lerp(Color("#2f5f93"), light)
	draw_circle(Vector2.ZERO, R_DIAL + 2.0, Color(disc, 0.96 * a))
	var soft := UIKit.soft_texture()
	draw_texture_rect(soft, Rect2(Vector2(-R_DIAL, -R_DIAL) * 0.9, Vector2(R_DIAL, R_DIAL) * 1.8), false, Color(1.0, 1.0, 1.0, 0.07 * a))
	# Evre şeridi.
	var phases: Array = info.get("phases", []) if not info.is_empty() else []
	var mid := (BAND_IN + BAND_OUT) * 0.5
	var width := BAND_OUT - BAND_IN
	if phases.is_empty():
		draw_arc(Vector2.ZERO, mid, 0.0, TAU, 96, Color(HudKit.NAVY, 0.9 * a), width, true)
	else:
		for i in phases.size():
			var p0 := float((phases[i] as Array)[1])
			var p1 := float((phases[(i + 1) % phases.size()] as Array)[1])
			if p1 <= p0:
				p1 += GameClock.DAY_MIN
			var col: Color = PHASE_COLORS.get(StringName(str((phases[i] as Array)[0])), HudKit.NAVY)
			draw_arc(Vector2.ZERO, mid, dial_angle(p0), dial_angle(p1), maxi(8, int((p1 - p0) / 12.0)), Color(col, 0.92 * a), width, true)
	draw_arc(Vector2.ZERO, BAND_IN - 1.0, 0.0, TAU, 96, Color(HudKit.GOLD_DEEP, 0.55 * a), 1.6, true)
	draw_arc(Vector2.ZERO, BAND_OUT + 1.0, 0.0, TAU, 96, Color(HudKit.GOLD_DEEP, 0.55 * a), 1.6, true)
	# Saat çentikleri ve dört ana saat.
	for h in 24:
		var ang := dial_angle(h * 60.0)
		var major := h % 6 == 0
		var r0 := BAND_IN - (12.0 if major else 6.0)
		draw_line(Vector2(cos(ang), sin(ang)) * r0, Vector2(cos(ang), sin(ang)) * (BAND_IN - 2.0), Color(HudKit.CREAM, (0.75 if major else 0.4) * a),
			2.0 if major else 1.2, true)
		if major:
			var lp := Vector2(cos(ang), sin(ang)) * (BAND_IN - 26.0) + Vector2(0.0, 6.0)
			HudKit.draw_text(self, HudKit.number_font(600), lp, "%02d" % h, 15, Color(HudKit.TEXT_DIM, 0.8 * a), 1, Color(0, 0, 0, 0.0), 0)
	# Seçilen satırın ya da akışın kavisi.
	var span_from := NAN
	var span_to := NAN
	if is_finite(_run_from) and is_finite(_run_to):
		span_from = _run_from
		span_to = _run_to
	else:
		var f := hovered if hovered >= 0 else selected
		if f >= 0 and f < rows.size() and is_finite(float(rows[f].get("target", NAN))):
			span_from = clock.abs_minute() if clock else now
			span_to = float(rows[f]["target"])
	if is_finite(span_from) and span_to > span_from:
		var a0 := dial_angle(span_from - float(floori(span_from / GameClock.DAY_MIN)) * GameClock.DAY_MIN)
		var a1 := a0 + (span_to - span_from) / GameClock.DAY_MIN * TAU
		draw_arc(Vector2.ZERO, ARC_R, a0, a1, maxi(8, int((a1 - a0) / 0.05)), Color(HudKit.GOLD, 0.95 * a), 5.0, true)
		var tip := Vector2(cos(a1), sin(a1)) * ARC_R
		HudKit.draw_centered(self, "marker_diamond", tip, Vector2(24.0, 24.0), Color(1, 1, 1, a))
	# Şimdinin güneşi ya da ayı (görünür akışta saatle, dönüşte dönüşle yürür).
	var ang_now := dial_angle(m)
	var body := Vector2(cos(ang_now), sin(ang_now)) * mid
	var sun_up := false
	if not info.is_empty():
		sun_up = m >= float(info.get("sunrise", 360.0)) and m < float(info.get("sunset", 1080.0))
	else:
		sun_up = m >= 360.0 and m < 1080.0
	if sun_up:
		for r in 8:
			var ra := TAU * float(r) / 8.0
			draw_line(body + Vector2(cos(ra), sin(ra)) * 14.0, body + Vector2(cos(ra), sin(ra)) * 19.0, Color(SUN, a), 2.4, true)
		draw_circle(body, 11.0, Color(SUN, a))
		draw_arc(body, 11.0, 0.0, TAU, 32, Color(HudKit.GOLD_DEEP, a), 1.6, true)
	else:
		draw_circle(body, 11.0, Color(MOON, a))
		draw_circle(body + Vector2(4.5, -3.0), 9.5, Color(disc.lerp(PHASE_COLORS[&"night"], 0.4), a))
	# Halka (bulut kıvrımlı gümüş).
	var ring := HudKit.tex("map_ring_large")
	if ring:
		var s := (R_DIAL + 4.0) / HudKit.BIG_RING_INNER
		draw_texture_rect(ring, Rect2(-HudKit.BIG_RING_PIVOT * s, ring.get_size() * s), false, Color(1, 1, 1, a))
	else:
		draw_arc(Vector2.ZERO, R_DIAL + 8.0, 0.0, TAU, 96, Color(HudKit.SILVER, a), 12.0, true)
	# Ortadaki yazı: seçilen satırın hedefi ya da şimdinin saati.
	var f2 := hovered if hovered >= 0 else selected
	var big := GameClock.hhmm(m)
	var small := WaitPlan.phase_name(clock.phase(), lang) if clock and not is_finite(_turn_at) else ""
	if not _running and f2 >= 0 and f2 < rows.size():
		big = str(rows[f2].get("at_text", big))
		small = str(rows[f2].get("label", ""))
	HudKit.draw_text(self, HudKit.number_font(600), Vector2(0.0, 10.0), big, 38, Color(HudKit.CREAM, a), 1, HudKit.SHADOW, 4)
	if not small.is_empty():
		HudKit.draw_text(self, HudKit.body_font(500), Vector2(0.0, 40.0), HudKit.fit_text(HudKit.body_font(500), small, 19, BAND_IN * 1.7),
			19, Color(HudKit.TEXT_DIM, a), 1, HudKit.SHADOW, 3)


func _draw_header() -> void:
	var a := _alpha * _slots_alpha
	var tf := HudKit.title_font()
	var title := title_text.to_upper()
	var w := HudKit.text_width(tf, title, 34)
	var rule_w := maxf(w + 220.0, 420.0)
	var kr := HudKit.RULE_SCALE * 0.9
	var rule_h := HudKit.RULE_SIZE.y * kr
	HudKit.draw_hslice(self, "quest_rule", Rect2(-rule_w * 0.5, TITLE_Y + 14.0 - HudKit.RULE_ROD_Y * kr, rule_w, rule_h), HudKit.RULE_PATCH.x,
		HudKit.RULE_PATCH.y, Vector2(-1.0, -1.0), Color(1, 1, 1, a))
	HudKit.draw_text(self, tf, Vector2(0.0, TITLE_Y), title, 34, Color(HudKit.GOLD, a), 1, HudKit.SHADOW, 4)
	if not sub_text.is_empty():
		HudKit.draw_text(self, UIKit.font("Alegreya-Italic", 400), Vector2(0.0, SUB_Y + 14.0), sub_text, 20, Color(HudKit.TEXT_DIM, a), 1,
			HudKit.SHADOW, 3)


func _draw_slot(i: int) -> void:
	var row := rows[i]
	var c := slot_center(i, rows.size())
	var enabled := bool(row.get("enabled", false))
	var focus := i == hovered or i == selected
	var a := _alpha * _slots_alpha * (1.0 if enabled else 0.5)
	if focus and enabled:
		var soft := UIKit.soft_texture()
		var r := SLOT_SIZE.x * 0.95
		draw_texture_rect(soft, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(1.0, 0.84, 0.48, 0.55 * a))
	HudKit.draw_centered(self, "slot_hex", c, SLOT_SIZE, Color(1.0, 1.0, 1.0, a) if not focus else Color(1.25, 1.18, 1.05, a))
	var at := str(row.get("at_text", "")).replace("→ ", "")
	HudKit.draw_text(self, HudKit.number_font(600), c + Vector2(0.0, 8.0), at, 21, Color(HudKit.CREAM, a), 1, HudKit.SHADOW, 3)
	HudKit.draw_text(self, HudKit.title_font(), c + Vector2(-24.0, -14.0), str(i + 1), 18, Color(HudKit.CREAM, a), 1, HudKit.SHADOW, 3)
	# Yazı: sağ yarıda altıgenin sağında, sol yarıda solunda.
	var right := c.x >= -1.0
	var x := c.x + LABEL_GAP if right else c.x - LABEL_GAP
	var align := 0 if right else 2
	var bf := HudKit.body_font(600)
	var label := HudKit.fit_text(bf, str(row.get("label", "")), 25, LABEL_WIDTH)
	var lc := HudKit.CREAM if enabled else HudKit.TEXT_DIM
	if focus and enabled:
		lc = Color(1.0, 0.95, 0.8)
	HudKit.draw_text(self, bf, Vector2(x, c.y + 2.0), label, 25, Color(lc, a), align, HudKit.SHADOW, 4)
	var note := str(row.get("why", "")) if not enabled else duration_text(float(row.get("minutes", 0.0)), lang)
	if not note.is_empty():
		var nf := UIKit.font("Alegreya-Italic", 400)
		HudKit.draw_text(self, nf, Vector2(x, c.y + 26.0), HudKit.fit_text(nf, note, 18, LABEL_WIDTH), 18,
			Color(HudKit.TEXT_DIM if enabled else Color("#e7b8a0"), _alpha * _slots_alpha * (0.9 if enabled else 0.85)), align, HudKit.SHADOW, 3)


func _draw_footer() -> void:
	var a := _alpha * _slots_alpha
	var keys := "1–%d" % maxi(rows.size(), 1)
	var parts := [[keys, WaitPlan.text("keys", lang)], ["Esc", WaitPlan.text("close", lang)]]
	var cap_font := HudKit.title_font()
	var body := HudKit.body_font(500)
	var widths: Array = []
	var total := 0.0
	for p: Array in parts:
		var w := HudKit.text_width(cap_font, str(p[0]), 15) + 18.0 + 10.0 + HudKit.text_width(body, str(p[1]), 18)
		widths.append(w)
		total += w
	total += 36.0 * (parts.size() - 1)
	var x := -total * 0.5
	for i in parts.size():
		var p: Array = parts[i]
		var cw := HudKit.text_width(cap_font, str(p[0]), 15) + 18.0
		var box := Rect2(x, FOOT_Y - 20.0, cw, 26.0)
		var sb := HudKit.keycap_box()
		sb.bg_color.a *= a
		sb.border_color.a *= a
		draw_style_box(sb, box)
		HudKit.draw_text(self, cap_font, Vector2(x + cw * 0.5, FOOT_Y - 1.0), str(p[0]), 15, Color(HudKit.CREAM, a), 1, Color(0, 0, 0, 0), 0)
		HudKit.draw_text(self, body, Vector2(x + cw + 10.0, FOOT_Y), str(p[1]), 18, Color(HudKit.CREAM, a), 0, HudKit.SHADOW, 3)
		x += float(widths[i]) + 36.0


## Süre yazısı: «1 sa», «3 sa 52 dk», «45 dk» (EN «1 h», «3 h 52 min»).
static func duration_text(minutes: float, p_lang: String = "tr") -> String:
	if not is_finite(minutes) or minutes <= 0.0:
		return ""
	var total := roundi(minutes)
	var h := total / 60
	var m := total % 60
	var hs := "sa" if p_lang != "en" else "h"
	var ms := "dk" if p_lang != "en" else "min"
	if h <= 0:
		return "%d %s" % [m, ms]
	return "%d %s" % [h, hs] if m == 0 else "%d %s %d %s" % [h, hs, m, ms]
