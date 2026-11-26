class_name HudHotbar
extends Control
## Alt ortadaki beceri şeridi (referanstaki gibi): köşeleri yuvarlatılmış dokuz lacivert-altın altıgen yuva (1, 2, 3, 4, üç boş «+»,
## Q, E), iki ucunda gümüş bulut kıvrımı; altında uzun XP çubuğu (mavi dolgu), onun da uçlarında küçük bulutlar. Yuvanın tuşu sol
## üstünde, simgesi ortada, sayısı (varsa) sağ altta koyu küçük rozette yazılır. Boş yuva soluk bir «+» gösterir. Çocuğun becerisi
## yoktur: bütün yuvalar boştur, yalnız elindeki oyuncak yay 3. yuvadadır (GameplayHud.CHILD_LOADOUT). Alt ortaya çapalıdır, 1080 satıra çizilir.
## Yuvaya basmak (1–4, Q, E tuşu ya da yuvaya tıklamak) boş olsa bile kısa bir basılma efekti verir: yuva küçülüp hafif taşarak geri
## gelir, arkasında bir ışıltı ve dışa açılan ince bir halka söner, «+» bir an parlar; dolu yuvada ışıltı altındır ve slot_pressed
## yayılır (eşyanın işi). Tuşlar yutulmaz: Q ve E kamerayı da döndürür, E etkileşimi de yapar. Fare yalnız altıgenlerin içinde tutulur.

## Yuvaya basıldı (sıra; boş yuvada da).
signal slot_pressed(index: int)

## Yuvaların tuş yazıları, soldan sağa ("" = yazısız).
const KEYS: Array[String] = ["1", "2", "3", "4", "", "", "", "Q", "E"]
## Yuvaya basan tuşlar (fiziksel tuş → yuvanın sırası).
const SLOT_KEYS := {KEY_1: 0, KEY_2: 1, KEY_3: 2, KEY_4: 3, KEY_Q: 7, KEY_E: 8}
## Denetimin kutusu (alt ortaya göre).
const BOX := Rect2(-400.0, -165.0, 800.0, 125.0)
const KEY_SIZE := 19
const COUNT_SIZE := 15
const ICON_BOX := 50.0
## Uçların bulutları: büyük (yuva şeridinin), küçük (XP çubuğunun) boyları ve merkezlerinin x uzaklığı, y'si (alt ortaya göre).
const CLOUD_BIG := Vector2(64.0, 32.0)
const CLOUD_BIG_AT := Vector2(346.0, -90.0)
const CLOUD_SMALL := Vector2(38.0, 19.0)
const CLOUD_SMALL_AT := Vector2(292.0, -60.0)
const FILL_EASE := 6.0
## Basılma efekti: süresi (sn), en küçük ölçek, yuvanın tıklanan yarıçapı (px), ışıltının renkleri (boş: gök mavisi, dolu: altın).
const PRESS_TIME := 0.36
const PRESS_SQUASH := 0.84
const PRESS_DOWN := 0.07
const HIT_RADIUS := 35.0
const GLOW_EMPTY := Color(0.62, 0.86, 1.0)
const GLOW_FULL := Color(1.0, 0.84, 0.48)

## Yuva sırası → {icon: doku kimliği, count: sayı (0 = yazılmaz)}.
var loadout: Dictionary = {}
## XP'nin gösterilen oranı (0..1).
var xp_ratio := 0.0
## HUD ölçeğinin iç kayması (HudKit.lift_for; GameplayHud verir).
var lift := 0.0

var _xp_shown := 0.0
## Yuvaların basılmadan bu yana geçen süreleri (PRESS_TIME ve üstü: dinlenmede).
var _press := PackedFloat32Array()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	_press.resize(KEYS.size())
	_press.fill(PRESS_TIME)
	_place()
	_dev_press.call_deferred()


## Geliştirme (belge karesi): --hud-press=1,3,8 şerit göründükten --hud-at (2) saniye sonra o yuvalara basar; ekran görüntüsünü
## (DevCapture, --capture) basılmanın en küçük anına dek bekletir. Argüman yoksa bir şey yapmaz.
func _dev_press() -> void:
	var slots := PackedInt32Array()
	var wait := 2.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--hud-press="):
			for part in a.substr(12).split(",", false):
				if part.is_valid_int():
					slots.append(int(part) - 1)
		elif a.begins_with("--hud-at=") and a.substr(9).is_valid_float():
			wait = float(a.substr(9))
	if slots.is_empty() or not is_inside_tree():
		return
	var cap := get_tree().root.get_node_or_null(^"DevCapture")
	if cap and cap.has_method(&"hold_capture"):
		cap.call(&"hold_capture")
	while is_inside_tree() and not is_visible_in_tree():
		await get_tree().process_frame
	if not is_inside_tree():
		return
	await get_tree().create_timer(wait).timeout
	for i in slots:
		press(i)
		await get_tree().process_frame
	await get_tree().create_timer(PRESS_DOWN * 0.6).timeout
	if cap and cap.has_method(&"release_capture"):
		cap.call(&"release_capture")


func set_loadout(p_loadout: Dictionary) -> void:
	if p_loadout != loadout:
		loadout = p_loadout.duplicate(true)
		queue_redraw()


func set_xp(ratio: float) -> void:
	xp_ratio = clampf(ratio, 0.0, 1.0)


## HUD ölçeğinin iç kayması: şerit XP çubuğunun alt kenarından büyür (GameplayHud._apply_scale).
func set_lift(v: float) -> void:
	lift = v
	_place()


func _place() -> void:
	offset_left = BOX.position.x
	offset_right = BOX.end.x
	offset_top = BOX.position.y + lift
	offset_bottom = BOX.end.y + lift


func _process(delta: float) -> void:
	var dirty := false
	if absf(_xp_shown - xp_ratio) > 0.001:
		_xp_shown = lerpf(_xp_shown, xp_ratio, 1.0 - exp(-FILL_EASE * delta))
		if absf(_xp_shown - xp_ratio) < 0.002:
			_xp_shown = xp_ratio
		dirty = true
	for i in _press.size():
		if _press[i] < PRESS_TIME:
			_press[i] = minf(_press[i] + delta, PRESS_TIME)
			dirty = true
	if dirty:
		queue_redraw()


## i. yuvanın merkezi (alt ortaya göre; saf).
static func slot_center(i: int) -> Vector2:
	var first := -(KEYS.size() - 1) * HudKit.SLOT_PITCH * 0.5
	return Vector2(first + i * HudKit.SLOT_PITCH, HudKit.SLOT_CENTER_Y)


## Denetimdeki noktanın yuvası (-1 yok; saf): altıgenin iç dairesi.
static func slot_at(local: Vector2) -> int:
	for i in KEYS.size():
		if local.distance_to(slot_center(i) - BOX.position) <= HIT_RADIUS:
			return i
	return -1


## Yuvanın simgesi ("" boş; sınama).
func slot_icon(i: int) -> String:
	var s: Variant = loadout.get(i)
	return str((s as Dictionary).get("icon", "")) if s is Dictionary else ""


## Yuvaya basar: efekt başlar (boşta da), ses çalar, slot_pressed yayılır.
func press(i: int) -> void:
	if i < 0 or i >= KEYS.size():
		return
	if _press.size() != KEYS.size():
		_press.resize(KEYS.size())
		_press.fill(PRESS_TIME)
	_press[i] = 0.0
	queue_redraw()
	var full := not slot_icon(i).is_empty()
	MenuStyle.play_ui(self, &"click" if full else &"hover", -9.0 if full else -12.0)
	slot_pressed.emit(i)


## Yuvanın basılma efekti sürüyor mu (sınama)?
func is_pressing(i: int) -> bool:
	return i >= 0 and i < _press.size() and _press[i] < PRESS_TIME


## Yuvanın o anki ölçeği (sınama ve çizim).
func slot_scale(i: int) -> float:
	return press_scale(_press[i]) if i >= 0 and i < _press.size() else 1.0


## Basılmadan t saniye sonra yuvanın ölçeği (saf): PRESS_DOWN'da PRESS_SQUASH'a iner, sonra hafif taşıp (≈1,03) 1'e döner.
static func press_scale(t: float) -> float:
	if t >= PRESS_TIME or t < 0.0:
		return 1.0
	if t < PRESS_DOWN:
		var d := t / PRESS_DOWN
		return lerpf(1.0, PRESS_SQUASH, 1.0 - (1.0 - d) * (1.0 - d))
	var u := (t - PRESS_DOWN) / (PRESS_TIME - PRESS_DOWN)
	return 1.0 - (1.0 - PRESS_SQUASH) * (1.0 - u) * (1.0 - u) * cos(u * PI * 1.6)


## Basılmadan t saniye sonra ışıltının gücü (saf; 1 → 0).
static func press_glow(t: float) -> float:
	if t >= PRESS_TIME or t < 0.0:
		return 0.0
	var u := t / PRESS_TIME
	return pow(1.0 - u, 1.5)


## Tuşlar (1–4, Q, E) yuvaya basar; olay yutulmaz (Q, E kameranındır, E etkileşimindir). HUD görünmüyorsa ya da oyun durmuşsa yok.
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not is_visible_in_tree() or get_tree().paused:
		return
	var k := event as InputEventKey
	if not k.pressed or k.echo:
		return
	var code := k.physical_keycode if k.physical_keycode != KEY_NONE else k.keycode
	if SLOT_KEYS.has(code):
		press(int(SLOT_KEYS[code]))


func _has_point(p: Vector2) -> bool:
	return slot_at(p) >= 0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var i := slot_at((event as InputEventMouseButton).position)
		if i >= 0:
			accept_event()
			press(i)


func _local(p: Vector2) -> Vector2:
	return p - BOX.position


func _draw() -> void:
	# Uçların bulutları: kuyruk dışa bakar (soldaki sola, sağdaki sağa).
	for side in [-1.0, 1.0]:
		var big := _local(Vector2(CLOUD_BIG_AT.x * side, CLOUD_BIG_AT.y))
		HudKit.draw_centered(self, "cloud_left" if side < 0.0 else "cloud_right", big, CLOUD_BIG)
		var small := _local(Vector2(CLOUD_SMALL_AT.x * side, CLOUD_SMALL_AT.y))
		HudKit.draw_centered(self, "cloud_left" if side < 0.0 else "cloud_right", small, CLOUD_SMALL)
	_draw_xp()
	var key_font := HudKit.title_font()
	for i in KEYS.size():
		var c := _local(slot_center(i))
		var t := _press[i] if i < _press.size() else PRESS_TIME
		var icon := slot_icon(i)
		var glow := press_glow(t)
		var glow_col := GLOW_FULL if not icon.is_empty() else GLOW_EMPTY
		if glow > 0.0:
			_draw_glow(c, glow, glow_col, t)
		var k := press_scale(t)
		draw_set_transform(c, 0.0, Vector2(k, k))
		var tint := Color.WHITE.lerp(Color(1.3, 1.22, 1.08), glow) if glow > 0.0 else Color.WHITE
		HudKit.draw_centered(self, "slot_hex", Vector2.ZERO, HudKit.SLOT_SIZE, tint)
		if glow > 0.0:
			_draw_flash(glow, glow_col)
		if icon.is_empty():
			_draw_plus(Vector2.ZERO, glow)
		else:
			HudKit.draw_icon(self, icon, Vector2(2.0, 3.0), ICON_BOX, tint)
		if not KEYS[i].is_empty():
			HudKit.draw_text(self, key_font, Vector2(-21.0, -12.0), KEYS[i], KEY_SIZE, HudKit.CREAM.lerp(Color.WHITE, glow), 1, HudKit.SHADOW, 3)
		var count := int((loadout.get(i, {}) as Dictionary).get("count", 0)) if loadout.get(i) is Dictionary else 0
		if count > 0:
			var bc := Vector2(24.0, 22.0)
			HudKit.draw_centered(self, "badge_count", bc, Vector2(26.0, 26.0))
			HudKit.draw_text(self, HudKit.number_font(600), bc + Vector2(0.0, 5.0), str(count), COUNT_SIZE, HudKit.CREAM, 1, HudKit.SHADOW, 2)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Basılan yuvanın arkasındaki yumuşak ışıltı ve dışa açılan ince halka.
func _draw_glow(c: Vector2, glow: float, col: Color, t: float) -> void:
	var soft := UIKit.soft_texture()
	var r := HudKit.SLOT_SIZE.x * (0.95 + 0.25 * (1.0 - glow))
	draw_texture_rect(soft, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(col, glow))
	draw_texture_rect(soft, Rect2(c - Vector2(r, r) * 0.8, Vector2(r, r) * 1.6), false, Color(col, 0.7 * glow))
	var u := clampf(t / PRESS_TIME, 0.0, 1.0)
	var ring := HudKit.SLOT_SIZE.x * (0.5 + 0.24 * u)
	draw_arc(c, ring, 0.0, TAU, 48, Color(col, 0.9 * glow), 2.6, true)


## Basılan yuvanın üstüne düşen ışık (yuvanın içi bir an aydınlanır).
func _draw_flash(glow: float, col: Color) -> void:
	var soft := UIKit.soft_texture()
	var r := HudKit.SLOT_SIZE.x * 0.42
	draw_texture_rect(soft, Rect2(-Vector2(r, r), Vector2(r, r) * 2.0), false, Color(col.lerp(Color.WHITE, 0.5), 0.42 * glow))


## Boş yuvanın soluk gök mavisi «+»sı (koyu konturlu); basılınca bir an beyaza parlar.
func _draw_plus(c: Vector2, glow := 0.0) -> void:
	var arm := 11.0
	for pass_i in 2:
		var w := 6.5 if pass_i == 0 else 3.4
		var col := Color(0.03, 0.06, 0.12, 0.7) if pass_i == 0 else Color(HudKit.PLUS, 0.92).lerp(Color(1.0, 1.0, 1.0, 1.0), glow)
		draw_line(c + Vector2(-arm, 0.0), c + Vector2(arm, 0.0), col, w, true)
		draw_line(c + Vector2(0.0, -arm), c + Vector2(0.0, arm), col, w, true)


func _draw_xp() -> void:
	var r := Rect2(_local(HudKit.XP_RECT.position), HudKit.XP_RECT.size)
	var src := HudKit.XP_OPAQUE_Y
	HudKit.draw_hslice(self, "xp_frame", r, HudKit.XP_PATCH, HudKit.XP_PATCH, src)
	var k := r.size.y / (src.y - src.x)
	var ch := HudKit.XP_CHANNEL
	var x0 := r.position.x + ch.position.x * k
	var x1 := r.end.x - (HudKit.XP_SIZE.x - ch.end.x) * k
	var y0 := r.position.y + (ch.position.y - src.x) * k
	var y1 := r.position.y + (ch.end.y - src.x) * k
	var w := (x1 - x0) * _xp_shown
	if w > 1.0:
		HudKit.draw_hslice(self, "xp_fill", Rect2(x0, y0, w, y1 - y0), HudKit.XP_FILL_PATCH, HudKit.XP_FILL_PATCH)
