@tool
class_name CreatorRow
extends Control
## Karakter oluşturucuda tek bir seçenek satırı.
##
##   ▸ BAŞLIK        ◀      Değer      ▶
##                   ● ● ● ● ● ● ●            (yalnızca renk alanlarında; boyada kumaş örnekleri)
##              «açıklama · not»              (yalnızca köken ve zorlukta; kökende iki satır: söz, altında etki)
##
## Satır yalnızca görünümden sorumludur: oklara ya da renk örneklerine tıklanınca sinyal yayar,
## profili değiştirmek CharacterCreator'ın işidir. Odaktaki satırın başlığı sıcak kırmızıya döner
## ve solunda küçük bir ▸ işareti belirir. Yolun ilk satırının (köken) üstünde mürekkep bir ayraç çizilir:
## görünüş satırları ile yolun satırları (köken, zorluk, boya) ayrı okunur.

signal step_requested(field: StringName, step: int)
signal color_requested(field: StringName, index: int)
signal hovered(field: StringName)

## Değer satırının ve renk örneği şeridinin yüksekliği (piksel).
const LINE_HEIGHT := 58.0
const SWATCH_HEIGHT := 50.0
## Açıklama satırının yüksekliği ve yazı boyu sınırları (sığmazsa küçülür); iki satırlık açıklamanın (köken) ikinci satırının payı.
const DETAIL_HEIGHT := 26.0
const DETAIL_LINE_HEIGHT := 20.0
const DETAIL_FONT_SIZE := 15
const DETAIL_MIN_FONT_SIZE := 12
## Açıklamanın genişliği (değerin ortasına göre).
const DETAIL_WIDTH := 452.0
## Yolun ilk satırının üstündeki ayracın yüksekliği.
const SECTION_GAP := 30.0
## Sütunların satırın sol kenarına göre konumları (piksel); parşömen genişliği 680 piksele göre.
const MARKER_X := 46.0
const LABEL_X := 68.0
const LEFT_ARROW_X := 262.0
const RIGHT_ARROW_X := 606.0
## İlk renk örneğinin merkezi.
const SWATCH_X := 226.0
## Odak animasyonunun hızı.
const FOCUS_RATE := 10.0
## Ayarlanamayan satırın saydamlığı.
const LOCKED_ALPHA := 0.5

const FALLBACK_FOCUS := Color(0.72, 0.28, 0.21)
const FALLBACK_MARKER := Color(0.18, 0.3, 0.31)
const FALLBACK_DETAIL := Color(0.38, 0.33, 0.28)
const FALLBACK_RULE := Color(0.33, 0.27, 0.22, 0.55)

## Bu satırın gösterdiği profil alanı (ör. &"hair_color").
var field: StringName = &""
## Klavye / fare odağı bu satırda mı?
var focused := false:
	set(value):
		focused = value
		set_process(true)
## Alan bu karakterde ayarlanabilir mi? Ayarlanamayan satır (ör. Meshy modelinin yüzüne çizili sakal)
## soluk görünür, okları gizlenir ve değer yerine CharacterOptions.locked_text yazar.
var adjustable := true:
	set(value):
		adjustable = value
		_apply_adjustable()

var _label: Label
var _value: Label
var _detail: Label
var _left: CreatorArrow
var _right: CreatorArrow
var _swatches: CreatorSwatches
var _focus_amount := 0.0
var _bump_tween: Tween
## Satırın üstündeki ayraç payı (yalnız yolun ilk satırında SECTION_GAP).
var _top := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_entered.connect(_emit_hovered)


## Satırı bir alan için kurar. Renk alanlarında renk örneği şeridi, köken ve zorlukta açıklama satırı da eklenir.
func setup(p_field: StringName) -> void:
	field = p_field
	name = "Row_%s" % p_field
	_top = SECTION_GAP if CreatorRow.starts_section(field) else 0.0
	_label = _make_label(&"CreatorFieldLabel", HORIZONTAL_ALIGNMENT_LEFT)
	_label.text = str(CharacterOptions.FIELD_LABELS.get(field, String(field).to_upper()))
	_value = _make_label(&"CreatorValue", HORIZONTAL_ALIGNMENT_CENTER)
	_left = _make_arrow(-1)
	_right = _make_arrow(1)
	if is_color_row():
		_swatches = CreatorSwatches.new()
		_swatches.name = "Swatches"
		_swatches.fabric = field in CharacterOptions.FABRIC_FIELDS
		_swatches.colors = CharacterOptions.colors(field)
		_swatches.swatch_pressed.connect(func(i: int) -> void: color_requested.emit(field, i))
		_swatches.mouse_entered.connect(_emit_hovered)
		add_child(_swatches)
	if field in CharacterOptions.DETAIL_FIELDS:
		_detail = _make_label(&"CreatorDetail", HORIZONTAL_ALIGNMENT_CENTER)
		_detail.name = "Detail"
	custom_minimum_size = Vector2(0.0, CreatorRow.row_height(field))
	resized.connect(_layout)
	_layout()
	_apply_adjustable()


## Alanın satır yüksekliği: renk alanlarında renk örneği şeridi, köken ve zorlukta açıklama (detail_height), yolun ilk satırında ayraç
## eklenir.
static func row_height(p_field: StringName) -> float:
	var h := LINE_HEIGHT
	if p_field in CharacterOptions.COLOR_FIELDS:
		h += SWATCH_HEIGHT
	h += CreatorRow.detail_height(p_field)
	if CreatorRow.starts_section(p_field):
		h += SECTION_GAP
	return h


## Açıklamanın yüksekliği: tek satır DETAIL_HEIGHT, iki satırlık açıklamada (köken: söz ve etki) bir satır payı daha; açıklaması
## olmayan alanda 0.
static func detail_height(p_field: StringName) -> float:
	if not p_field in CharacterOptions.DETAIL_FIELDS:
		return 0.0
	return DETAIL_HEIGHT + (DETAIL_LINE_HEIGHT if p_field in CharacterOptions.TWO_LINE_DETAIL_FIELDS else 0.0)


## Alan yolun bölümünü mü açıyor (üstünde ayraç)?
static func starts_section(p_field: StringName) -> bool:
	return not CharacterOptions.JOURNEY_FIELDS.is_empty() and p_field == CharacterOptions.JOURNEY_FIELDS[0]


## Profildeki güncel değeri gösterir (saç modeli adları vücut tipine göre değişir).
func refresh(profile: CharacterProfile) -> void:
	var index := profile.get_value(field)
	_value.text = CharacterOptions.value_name(field, index, profile.body_type) if adjustable else CharacterOptions.locked_text(field)
	if _swatches:
		_swatches.selected = index
	if _detail:
		_detail.text = CharacterOptions.value_detail(field, index)
		_fit_detail()


## Değer metnini değişim yönünde kısa bir kaydırma ile canlandırır (-1 sola, 1 sağa).
func bump(direction: int) -> void:
	if _bump_tween:
		_bump_tween.kill()
	(_right if direction >= 0 else _left).nudge()
	if not is_inside_tree():
		return
	var base_x := LEFT_ARROW_X + 20.0
	_value.position.x = base_x + 16.0 * float(signi(direction))
	_value.modulate.a = 0.25
	_bump_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_bump_tween.tween_property(_value, ^"position:x", base_x, 0.22)
	_bump_tween.tween_property(_value, ^"modulate:a", 1.0, 0.18)
	if _detail:
		_detail.modulate.a = 0.0
		_bump_tween.tween_property(_detail, ^"modulate:a", 1.0, 0.3).set_delay(0.05)


func is_color_row() -> bool:
	return field in CharacterOptions.COLOR_FIELDS


func get_value_text() -> String:
	return _value.text if _value else ""


func get_label_text() -> String:
	return _label.text if _label else ""


## Açıklama satırının metni (köken ve zorlukta; yoksa "").
func get_detail_text() -> String:
	return _detail.text if _detail else ""


## Açıklama satırı (yoksa null).
func get_detail_label() -> Label:
	return _detail


## Renk örneği şeridi (renk alanı değilse null).
func get_swatches() -> CreatorSwatches:
	return _swatches


func get_arrows() -> Array[CreatorArrow]:
	return [_left, _right]


func _process(delta: float) -> void:
	var target := 1.0 if focused else 0.0
	_focus_amount = move_toward(_focus_amount, target, delta * FOCUS_RATE * 0.5)
	if _label:
		var base := get_theme_color(&"font_color", &"CreatorFieldLabel")
		_label.add_theme_color_override(&"font_color", base.lerp(_color(&"label_focus", FALLBACK_FOCUS), _focus_amount))
	queue_redraw()
	if is_equal_approx(_focus_amount, target):
		set_process(false)


func _draw() -> void:
	if _top > 0.0:
		_draw_section_rule()
	if _focus_amount <= 0.01:
		return
	# Odak işareti (▸): soldan kayarak belirir.
	var center := Vector2(MARKER_X - 6.0 * (1.0 - _focus_amount), _top + LINE_HEIGHT * 0.5)
	var color := _color(&"marker", FALLBACK_MARKER)
	color.a *= _focus_amount
	var points := CreatorArrow.triangle_points(center, Vector2(7.0, 9.0), 1)
	draw_colored_polygon(points, color)
	var outline := points.duplicate()
	outline.append(points[0])
	draw_polyline(outline, color, 1.0, true)


## Görünüş ile yol arasındaki ayraç: ortada küçük bir mürekkep baklava, iki yanda uçları incelen fırça çizgisi.
func _draw_section_rule() -> void:
	var y := _top * 0.5 - 2.0
	var cx := (LABEL_X + RIGHT_ARROW_X + 19.0) * 0.5
	var half := (RIGHT_ARROW_X + 19.0 - LABEL_X) * 0.5
	var color := _color(&"rule", FALLBACK_RULE)
	for side in [-1.0, 1.0]:
		# Fırça izi: merkezden uca incelen, hafif dalgalı birkaç kısa parça.
		var steps := 14
		for i in steps:
			var t0 := float(i) / steps
			var t1 := float(i + 1) / steps
			var x0: float = cx + side * lerpf(12.0, half, t0)
			var x1: float = cx + side * lerpf(12.0, half, t1)
			var wave0 := sin(t0 * 7.0 + side) * 0.6
			var wave1 := sin(t1 * 7.0 + side) * 0.6
			var width := lerpf(1.8, 0.5, t1)
			var c := color
			c.a *= lerpf(1.0, 0.35, t1)
			draw_line(Vector2(x0, y + wave0), Vector2(x1, y + wave1), c, width, true)
	var d := 4.5
	var diamond := PackedVector2Array([Vector2(cx, y - d), Vector2(cx + d, y), Vector2(cx, y + d), Vector2(cx - d, y)])
	draw_colored_polygon(diamond, color)


func _layout() -> void:
	if _label == null:
		return
	_label.position = Vector2(LABEL_X, _top)
	_label.size = Vector2(LEFT_ARROW_X - 24.0 - LABEL_X, LINE_HEIGHT)
	_left.position = Vector2(LEFT_ARROW_X, _top + LINE_HEIGHT * 0.5) - _left.custom_minimum_size * 0.5
	_right.position = Vector2(RIGHT_ARROW_X, _top + LINE_HEIGHT * 0.5) - _right.custom_minimum_size * 0.5
	_value.position = Vector2(LEFT_ARROW_X + 20.0, _top)
	_value.size = Vector2(RIGHT_ARROW_X - LEFT_ARROW_X - 40.0, LINE_HEIGHT)
	var below := _top + LINE_HEIGHT
	if _swatches:
		var strip := CreatorSwatches.strip_size(_swatches.colors.size())
		_swatches.position = Vector2(SWATCH_X - CreatorSwatches.center_x(0), below - 8.0)
		_swatches.size = strip
		below += SWATCH_HEIGHT
	if _detail:
		var center_x := (LEFT_ARROW_X + RIGHT_ARROW_X) * 0.5
		_detail.position = Vector2(center_x - DETAIL_WIDTH * 0.5, below - 12.0)
		_detail.size = Vector2(DETAIL_WIDTH, CreatorRow.detail_height(field))


## Açıklamanın en geniş satırı sığmazsa yazı boyunu küçültür (en az DETAIL_MIN_FONT_SIZE).
func _fit_detail() -> void:
	if _detail == null:
		return
	var font := _detail.get_theme_font(&"font")
	var size := DETAIL_FONT_SIZE
	while size > DETAIL_MIN_FONT_SIZE and font and _widest_line(font, size) > DETAIL_WIDTH - 8.0:
		size -= 1
	_detail.add_theme_font_size_override(&"font_size", size)


func _widest_line(font: Font, size: int) -> float:
	var widest := 0.0
	for line in _detail.text.split("\n"):
		widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x)
	return widest


## Ayarlanabilirliği görünüme uygular: oklar, renk örnekleri ve açıklama yalnızca ayarlanabilir satırda görünür,
## ayarlanamayan satır soluklaşır.
func _apply_adjustable() -> void:
	if _label == null:
		return
	for arrow: CreatorArrow in [_left, _right]:
		arrow.visible = adjustable
	if _swatches:
		_swatches.visible = adjustable
	if _detail:
		_detail.visible = adjustable
	modulate.a = 1.0 if adjustable else LOCKED_ALPHA


func _make_label(variation: StringName, align: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.theme_type_variation = variation
	label.horizontal_alignment = align
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = false
	add_child(label)
	return label


func _make_arrow(dir: int) -> CreatorArrow:
	var arrow := CreatorArrow.new()
	arrow.name = "Left" if dir < 0 else "Right"
	arrow.direction = dir
	arrow.size = arrow.custom_minimum_size
	arrow.pressed.connect(func() -> void: step_requested.emit(field, dir))
	arrow.mouse_entered.connect(_emit_hovered)
	add_child(arrow)
	return arrow


## Fare satıra, oklarından birine ya da renk örneklerine geldi. Oklar ve renk örnekleri fare olayını
## kendileri tutar (MOUSE_FILTER_STOP); imleç doğrudan onlara gelince satırın kendi mouse_entered
## sinyali yayılmaz. Bu yüzden onların sinyali de buraya bağlıdır: satır her durumda odaklanır.
func _emit_hovered() -> void:
	hovered.emit(field)


func _color(item: StringName, fallback: Color) -> Color:
	return get_theme_color(item, &"CreatorRow") if has_theme_color(item, &"CreatorRow") else fallback
