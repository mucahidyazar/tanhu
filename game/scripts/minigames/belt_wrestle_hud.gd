class_name BeltWrestleHud
extends Control
## Kuşak güreşinin küçük HUD'u (Önsöz «Güreş», K110): alt ortada denge çubuğu ve ipucu. Çubuğun solu Çocuk'un arkasıdır (Börü iterse işaret
## sola kayar), sağı Börü'nün yanıdır (çekerse sağa); kamera güreşçileri yandan gösterir, Çocuk solda, Börü sağdadır (wrestle_ring.gd).
## Ortadaki altın bant tutuşun bandıdır (BeltWrestle.hold_band); iki uç kızıldır, uca varan düşer. Börü'nün eğilişi (gelecek yüklenişin
## yönü) çubuğun üstünde o yana bakan köşeli okla görünür; pencere açılınca çubuğun ortasında E kapakçığı ve sönen halka belirir.
## İpucu satırı oyuncunun ipucunun (PlayerPrompt) görünüşündedir. Fareyi engellemez; BeltWrestle'ı okur, yazmaz.
##   var hud := BeltWrestleHud.new(); ui.add_child(hud); hud.bind(sim)
##   hud.refresh()            # her kare (çizim)

## Çubuğun boyu (1080 satırda piksel), alt kenara uzaklığı ve kalınlığı.
const BAR_SIZE := Vector2(560.0, 16.0)
const BAR_BOTTOM := 190.0
const MARKER := 13.0
const COLOR_BAR := Color(0.04, 0.062, 0.15, 0.82)
const COLOR_BAND := Color(UIKit.GOLD, 0.42)
const COLOR_END := Color(UIKit.CRIMSON, 0.85)
const COLOR_MARKER := UIKit.PARCHMENT
const COLOR_LEAN := Color(UIKit.EMBER, 0.95)
const COLOR_WINDOW := UIKit.GOLD
## İpucu: [[tuş, eylem], ...] (TR; EN yanında).
const PAIRS := {
	"tr": [["A D", "Dengede kal"], ["E", "At"], ["G basılı", "Kuşağı bırak"]],
	"en": [["A D", "Keep your balance"], ["E", "Throw"], ["Hold G", "Let go of the belt"]],
}
const PAIRS_DOWN := {
	"tr": [["G basılı", "Kuşağı bırak"]],
	"en": [["Hold G", "Let go of the belt"]],
}

var sim: BeltWrestle
var lang := "tr"
## Kuşağı bırakmanın basılı tutuşu [0, 1] (adım betiği yazar; çubuğun altında ince yay).
var give_up_fill := 0.0

var _prompt: PlayerPrompt
var _tries: Label
var _k := 1.0


func _ready() -> void:
	name = "BeltWrestleHud" if name.is_empty() else name
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(self)
	_prompt = PlayerPrompt.new()
	_prompt.name = "Prompt"
	add_child(_prompt)
	_tries = UIKit.label("", 18, "Alegreya-Italic", 400, UIKit.TEXT_DIM)
	_tries.name = "Tries"
	_tries.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tries.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_tries)
	UIKit.on_ui_scale_changed(self, _apply_ui_scale)
	_apply_ui_scale()
	refresh()


func bind(p_sim: BeltWrestle) -> void:
	sim = p_sim
	refresh()


## İpucunun düz yazısı (sınama).
func prompt_text() -> String:
	return _prompt.get_text() if _prompt else ""


## İşaretin çubuktaki yeri [0, 1] (saf; 0 sol uç, 1 sağ uç): denge +1 sol uçtur.
static func marker_x(balance: float) -> float:
	return clampf(0.5 - balance * 0.5, 0.0, 1.0)


func refresh() -> void:
	if _prompt:
		var down := sim != null and sim.phase in [BeltWrestle.FALLEN, BeltWrestle.REGRIP]
		var table: Dictionary = PAIRS_DOWN if down else PAIRS
		_prompt.show_pairs((table.get(lang, table["tr"]) as Array) if sim != null and not sim.is_over() else [])
	if _tries:
		var n := sim.tries if sim else 1
		_tries.text = ("%d. tutuş" % n if lang == "tr" else "Bout %d" % n) if sim and n > 1 and not sim.is_over() else ""
		var bar := _bar_rect()
		_tries.position = Vector2(bar.position.x, bar.position.y - 34.0 * _k)
		_tries.size = Vector2(bar.size.x, 24.0 * _k)
	queue_redraw()


func _apply_ui_scale() -> void:
	_k = UIKit.film_k()
	refresh()


func _bar_rect() -> Rect2:
	var vp := get_viewport_rect().size if is_inside_tree() else Vector2(1920, 1080)
	var size := BAR_SIZE * _k
	return Rect2(Vector2((vp.x - size.x) * 0.5, vp.y - BAR_BOTTOM * _k - size.y), size)


func _draw() -> void:
	if sim == null or sim.is_over():
		return
	var bar := _bar_rect()
	var pad := 6.0 * _k
	draw_rect(bar.grow(pad), COLOR_BAR, true)
	# Tutuşun bandı ve iki uç.
	var band := float(sim.cfg.get("hold_band", 0.42))
	var band_w := bar.size.x * band
	draw_rect(Rect2(Vector2(bar.position.x + (bar.size.x - band_w) * 0.5, bar.position.y), Vector2(band_w, bar.size.y)), COLOR_BAND, true)
	var end_w := bar.size.x * 0.06
	draw_rect(Rect2(bar.position, Vector2(end_w, bar.size.y)), COLOR_END, true)
	draw_rect(Rect2(Vector2(bar.end.x - end_w, bar.position.y), Vector2(end_w, bar.size.y)), COLOR_END, true)
	draw_rect(bar, Color(UIKit.GOLD_DIM, 0.9), false, maxf(1.0, 1.5 * _k))
	# Börü'nün eğilişi: gelecek yüklenişin işareti oynatacağı yana bakan köşeli ok (iterse sola, çekerse sağa).
	var lean := sim.lean()
	if absf(lean) > 0.05:
		var dir := -signf(lean)
		var cx := bar.get_center().x + dir * bar.size.x * 0.36
		var cy := bar.position.y - 14.0 * _k
		var s := (7.0 + 5.0 * absf(lean)) * _k
		var col := Color(COLOR_LEAN, clampf(absf(lean) * 1.2, 0.3, 1.0))
		for i in 2:
			var ox := cx + dir * float(i) * s * 0.9
			draw_polyline(PackedVector2Array([Vector2(ox - dir * s * 0.5, cy - s * 0.6), Vector2(ox + dir * s * 0.5, cy),
				Vector2(ox - dir * s * 0.5, cy + s * 0.6)]), col, maxf(2.0, 2.5 * _k), true)
	# İşaret.
	var mx := bar.position.x + bar.size.x * BeltWrestleHud.marker_x(sim.balance)
	var my := bar.get_center().y
	var m := MARKER * _k
	var marker_col := COLOR_MARKER if sim.phase != BeltWrestle.FALLEN else Color(UIKit.CRIMSON, 0.95)
	draw_colored_polygon(PackedVector2Array([Vector2(mx, my - m), Vector2(mx + m * 0.7, my), Vector2(mx, my + m), Vector2(mx - m * 0.7, my)]), marker_col)
	# Pencere: ortada E ve sönen halka.
	if sim.window_open():
		var c := Vector2(bar.get_center().x, bar.position.y - 52.0 * _k)
		var r := (18.0 + 16.0 * sim.window_left()) * _k
		draw_arc(c, r, 0.0, TAU, 40, Color(COLOR_WINDOW, 0.35 + 0.6 * sim.window_left()), maxf(2.0, 3.0 * _k), true)
		var font := UIKit.font("AlegreyaSC-Regular", 700)
		var fs := int(26.0 * _k)
		var text_size := font.get_string_size("E", HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		draw_string(font, c - Vector2(text_size.x * 0.5, -text_size.y * 0.3), "E", HORIZONTAL_ALIGNMENT_CENTER, -1, fs, COLOR_WINDOW)
	# Kuşağı bırakmanın basılı tutuşu.
	if give_up_fill > 0.0:
		var y := bar.end.y + 10.0 * _k
		draw_line(Vector2(bar.position.x, y), Vector2(bar.position.x + bar.size.x * clampf(give_up_fill, 0.0, 1.0), y), Color(UIKit.TEXT_DIM, 0.9),
			maxf(2.0, 3.0 * _k))
