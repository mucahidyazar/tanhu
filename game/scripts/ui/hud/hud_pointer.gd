class_name HudPointer
extends Control
## Görevin yönü ekranda: hedef ekrandaysa üstünde küçük bir altın baklava iğnesi ve uzaklığı («34 m»), ekranın dışındaysa (ya da
## kameranın arkasındaysa) ekranın kenarında, hedefe dönük altın bir ok, baklava ve uzaklık. K98 kadrajı uzaktır (22–40 m): boylar
## ekran pikselidir, uzaklığa göre küçülmez; işaretler arayüz ölçeğiyle (UIKit.ui_k) büyür. Kenar oku köşelere girmez (elips üstünde
## durur) ve HUD'un parçalarına (sol üst portre, sağ üst harita, alttaki şerit) değmesin diye içeride kalır. Tam ekrana yayılır, fareyi
## engellemez.

## Hedefin üstünde iğnenin durduğu yükseklik (m; çocuğun ≈1,1 m boyunun üstü).
const LIFT := 2.4
## Hedefin «geldin» sayıldığı yakınlık (m): iğne söner.
const NEAR := 2.0
## Kenar okunun içeride kaldığı paylar (1080 satır; sol, üst, sağ, alt).
const INSET := Vector4(150.0, 120.0, 150.0, 190.0)
const PIN_SIZE := Vector2(30.0, 38.0)
const ARROW_RADIUS := 26.0
const TEXT_SIZE := 17

## Hedef (dünya; yoksa Vector3.INF) ve oyuncunun yeri (uzaklık için).
var target := Vector3.INF
var player_pos := Vector3.ZERO
var ui_scale := 1.0

var _pulse := 0.0
var _state := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(self)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_pulse = fmod(_pulse + delta, 2.0)
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	_state = compute(cam, target, player_pos, get_rect().size, ui_scale)
	queue_redraw()


## O anki işaretin durumu (sınama): {mode: "", "pin" ya da "edge", at: Vector2, angle, meters}.
func state() -> Dictionary:
	return _state


## İşaretin hesabı (kamera, hedef, oyuncu, ekranın boyu, ölçek): hedef yoksa ya da çok yakınsa boş.
static func compute(cam: Camera3D, p_target: Vector3, p_player: Vector3, view: Vector2, k: float) -> Dictionary:
	if cam == null or p_target == Vector3.INF or not p_target.is_finite():
		return {}
	var meters := Vector2(p_target.x - p_player.x, p_target.z - p_player.z).length()
	if meters < NEAR:
		return {}
	var top := p_target + Vector3.UP * LIFT
	var behind := cam.is_position_behind(top)
	var at := cam.unproject_position(top)
	var inset := Rect2(Vector2(INSET.x, INSET.y) * k, view - Vector2(INSET.x + INSET.z, INSET.y + INSET.w) * k)
	if not behind and inset.has_point(at):
		return {"mode": "pin", "at": at, "angle": 0.0, "meters": meters}
	var center := inset.get_center()
	var dir := at - center
	if behind:
		dir = -dir
	if dir.length_squared() < 0.0001:
		dir = Vector2.DOWN
	return {"mode": "edge", "at": edge_point(center, dir, inset.size * 0.5), "angle": dir.angle(), "meters": meters}


## Elipsin (merkez, yarı eksenler) yöndeki noktası (saf): köşelere girmez.
static func edge_point(center: Vector2, dir: Vector2, half: Vector2) -> Vector2:
	var d := dir.normalized()
	var t := 1.0 / sqrt(pow(d.x / maxf(half.x, 1.0), 2.0) + pow(d.y / maxf(half.y, 1.0), 2.0))
	return center + d * t


## Uzaklığın yazısı (saf): «34 m».
static func meters_text(meters: float) -> String:
	return "%d m" % roundi(meters)


func _draw() -> void:
	if _state.is_empty():
		return
	var k := ui_scale
	var at: Vector2 = _state["at"]
	var text := meters_text(float(_state["meters"]))
	var bob := sin(_pulse * PI) * 3.0 * k
	if _state["mode"] == "pin":
		var size := PIN_SIZE * k
		var c := at + Vector2(0.0, -size.y * 0.5 + bob)
		HudKit.draw_centered(self, "marker_pin", c, size)
		HudKit.draw_text(self, HudKit.number_font(600), at + Vector2(0.0, 20.0 * k + bob), text, int(TEXT_SIZE * k), HudKit.CREAM, 1, HudKit.SHADOW, 4)
		return
	var angle: float = _state["angle"]
	var d := Vector2.from_angle(angle)
	var n := d.orthogonal()
	# Ok: halkanın hedefe bakan yanına oturan ince, simetrik altın bir üçgen (koyu konturlu), hafifçe nefes alır.
	var r := ARROW_RADIUS * k
	var push := (1.0 + bob * 0.6) * k
	var tip := at + d * (r + 21.0 * k + push)
	var base := at + d * (r - 1.0 * k + push)
	var head := PackedVector2Array([tip, base + n * 8.5 * k, base - n * 8.5 * k])
	var rim := PackedVector2Array([tip + d * 3.0 * k, base + n * 11.5 * k - d * 1.5 * k, base - n * 11.5 * k - d * 1.5 * k])
	draw_circle(at, r, Color(0.03, 0.05, 0.1, 0.42))
	draw_arc(at, r, 0.0, TAU, 48, Color(HudKit.GOLD, 0.85), 2.0 * k, true)
	draw_colored_polygon(rim, Color(0.05, 0.04, 0.02, 0.8))
	draw_colored_polygon(head, HudKit.GOLD)
	HudKit.draw_centered(self, "marker_diamond", at, Vector2.ONE * 30.0 * k)
	# Uzaklık okun karşı yanında (ekranın içine doğru): kenardaki HUD parçalarına taşmaz.
	var label := at - d * (ARROW_RADIUS + 18.0) * k + Vector2(0.0, TEXT_SIZE * 0.35 * k)
	HudKit.draw_text(self, HudKit.number_font(600), label, text, int(TEXT_SIZE * k), HudKit.CREAM, 1, HudKit.SHADOW, 4)
