class_name OrnamentLine
extends Control
## Logonun altındaki süs çizgisi (Tanhu 1): ortada çift elmas (içi gök mavisi), iki yanda uçları ok
## başı gibi açılan ince altın çizgiler. Genişliği 760 piksellik başlık bloğuna göre çizilir.
## "reveal" (0..1) açılış animasyonunda çizgileri ortadan dışa doğru açar.

## Açılma oranı (0 = yalnızca elmas, 1 = tam).
var reveal := 1.0:
	set(value):
		reveal = clampf(value, 0.0, 1.0)
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


## Çizginin merkezden görünen yarı uzunluğu (saf fonksiyon): reveal=0'da elmasın kenarında (30 px),
## reveal=1'de 330 px. Yumuşak (kübik) açılır.
static func half_length(p_reveal: float) -> float:
	var t := clampf(p_reveal, 0.0, 1.0)
	return lerpf(30.0, 330.0, 1.0 - pow(1.0 - t, 3.0))


func _draw() -> void:
	var y := size.y * 0.5
	var cx := size.x * 0.5
	var c := Color(UIKit.GOLD, 0.85)
	var outer := half_length(reveal)
	if outer > 30.5:
		draw_line(Vector2(cx - outer, y), Vector2(cx - 30, y), c, 2.0, true)
		draw_line(Vector2(cx + 30, y), Vector2(cx + outer, y), c, 2.0, true)
	if reveal >= 0.999:
		for s in [-1.0, 1.0]:
			draw_line(Vector2(cx + s * 330, y), Vector2(cx + s * 350, y - 6), c, 2.0, true)
			draw_line(Vector2(cx + s * 330, y), Vector2(cx + s * 350, y + 6), c, 2.0, true)
	var pts := PackedVector2Array([Vector2(cx, y - 13), Vector2(cx + 13, y), Vector2(cx, y + 13), Vector2(cx - 13, y), Vector2(cx, y - 13)])
	draw_polyline(pts, c, 2.4, true)
	var pts2 := PackedVector2Array([Vector2(cx, y - 7), Vector2(cx + 7, y), Vector2(cx, y + 7), Vector2(cx - 7, y), Vector2(cx, y - 7)])
	draw_polyline(pts2, Color(UIKit.SKY, 0.9), 2.0, true)
