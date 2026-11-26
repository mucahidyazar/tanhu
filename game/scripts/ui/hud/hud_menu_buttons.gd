class_name HudMenuButtons
extends Control
## Sağ alttaki üç yuvarlak düğme (referanstaki gibi): üstlerinde tuşu yazılı I (envanter), J (kitap: görevler), M (harita); iki ucunda
## küçük bulut kıvrımı. Tuşlar (inventory, journal, map; InputSetup) GameplayHud'dadır; düğmeye fareyle tıklamak da aynısını yapar (I Envanter'i, J ve M kitabın sayfasını açar)
## (yalnız dairenin içi fareyi tutar). Üzerine gelinen düğme ısınır. Sağ alt köşeye çapalıdır, 1080 satıra çizilir.

signal pressed(kind: String)

## [tuş, sayfa, simge] soldan sağa.
const BUTTONS: Array = [["I", "bag", "icon_bag"], ["J", "journal", "icon_book"], ["M", "map", "icon_map"]]
## Denetimin kutusu (sağ alt köşeye göre).
const BOX := Rect2(-300.0, -140.0, 300.0, 100.0)
const LETTER_SIZE := 19
const ICON_BOX := 36.0
const CLOUD := Vector2(42.0, 21.0)
const CLOUD_AT := Vector2(-270.0, -83.0)
const CLOUD_RIGHT_AT := Vector2(-45.0, -83.0)

var _hover := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 1.0
	anchor_bottom = 1.0
	offset_left = BOX.position.x
	offset_right = BOX.end.x
	offset_top = BOX.position.y
	offset_bottom = BOX.end.y
	mouse_exited.connect(func() -> void:
		_hover = -1
		queue_redraw())


## Düğmenin merkezi (denetime göre).
static func button_center(i: int) -> Vector2:
	return HudKit.BUTTON_CENTERS[i] - BOX.position


## Noktadaki düğme (-1 yok; denetime göre).
static func button_at(p: Vector2) -> int:
	for i in BUTTONS.size():
		if p.distance_to(button_center(i)) <= HudKit.BUTTON_SIZE * 0.5:
			return i
	return -1


func _has_point(p: Vector2) -> bool:
	return button_at(p) >= 0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var h := button_at((event as InputEventMouseMotion).position)
		if h != _hover:
			_hover = h
			queue_redraw()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var i := button_at((event as InputEventMouseButton).position)
		if i >= 0:
			accept_event()
			MenuStyle.play_ui(self, &"click")
			pressed.emit(str(BUTTONS[i][1]))


func _draw() -> void:
	HudKit.draw_centered(self, "cloud_left", CLOUD_AT - BOX.position, CLOUD)
	HudKit.draw_centered(self, "cloud_right", CLOUD_RIGHT_AT - BOX.position, CLOUD)
	var f := HudKit.title_font()
	for i in BUTTONS.size():
		var c := button_center(i)
		var hot := i == _hover
		var tint := Color(1.12, 1.06, 0.94) if hot else Color.WHITE
		HudKit.draw_centered(self, "button_round", c, Vector2.ONE * HudKit.BUTTON_SIZE * (1.05 if hot else 1.0), tint)
		HudKit.draw_icon(self, str(BUTTONS[i][2]), c + Vector2(0.0, 7.0), ICON_BOX, tint)
		HudKit.draw_text(self, f, c + Vector2(0.0, -9.0), str(BUTTONS[i][0]), LETTER_SIZE, HudKit.CREAM, 1, HudKit.SHADOW, 3)
