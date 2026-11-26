class_name HudMinimap
extends Control
## HUD'un sağ üstündeki yuvarlak mini harita (referanstaki gibi): bulut kıvrımlı gümüş halkanın içinde pişirilmiş dünya (WorldMap),
## ortada beyaz oyuncu oku, altın baklava görev işareti. Harita kamerayla döner: ekranda yukarısı kameranın baktığı yöndür (W «yukarı»
## yürür, ok da yukarı bakar); görev işareti dairenin dışında kalınca kenarda, yönünde durur. Görünen alan VIEW_RADIUS metredir.
## Sağ üst köşeye çapalıdır, 1080 satıra çizilir; ölçeği GameplayHud verir.

const MAP_SHADER := preload("res://assets/ui/hud/hud_map.gdshader")
## Dairenin yarıçapının dünyadaki boyu (m).
const VIEW_RADIUS := 36.0
## Denetimin kutusu (sağ üst köşeye göre) ve halkanın denetimdeki merkezi.
const BOX := Rect2(-310.0, 0.0, 310.0, 282.0)
const ARROW_SIZE := Vector2(26.0, 27.0)
const DIAMOND_SIZE := 27.0
## Kenara taşan görev işaretinin halkadan payı (px).
const EDGE_INSET := 13.0

var map: WorldMap
## Oyuncunun yeri (dünya x, z), baktığı açı (PlayerController.get_facing_yaw), kameranın yaw'ı (FollowCamera.get_yaw).
var player_xz := Vector2.ZERO
var facing := 0.0
var camera_yaw := 0.0
## Görevin hedefi (dünya x, z; yoksa Vector2.INF).
var target_xz := Vector2.INF

var _disc: ColorRect
var _overlay: Control
var _mat: ShaderMaterial
var _pulse := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = BOX.position.x
	offset_right = BOX.end.x
	offset_top = BOX.position.y
	offset_bottom = BOX.end.y
	_mat = ShaderMaterial.new()
	_mat.shader = MAP_SHADER
	_disc = ColorRect.new()
	_disc.name = "Disc"
	_disc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_disc.material = _mat
	var r := HudKit.MAP_RADIUS + 2.0
	_disc.position = ring_center() - Vector2(r, r)
	_disc.size = Vector2(r, r) * 2.0
	add_child(_disc)
	_overlay = Overlay.new()
	_overlay.name = "Overlay"
	(_overlay as Overlay).host = self
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.size = BOX.size
	add_child(_overlay)
	_apply_map()


## Halkanın denetimdeki merkezi.
static func ring_center() -> Vector2:
	return HudKit.MAP_CENTER - BOX.position


func set_map(p_map: WorldMap) -> void:
	map = p_map
	_apply_map()


func _apply_map() -> void:
	if _mat == null:
		return
	_mat.set_shader_parameter(&"map_tex", map.texture if map else null)
	if map:
		_mat.set_shader_parameter(&"exposure", map.exposure)
		_mat.set_shader_parameter(&"contrast", map.contrast)
		_mat.set_shader_parameter(&"pivot", Vector3(map.pivot.r, map.pivot.g, map.pivot.b))
	_refresh()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_pulse = fmod(_pulse + delta, 2.0)
	_refresh()
	_overlay.queue_redraw()


func _refresh() -> void:
	if _mat == null or map == null:
		return
	_mat.set_shader_parameter(&"center_uv", map.uv(player_xz))
	_mat.set_shader_parameter(&"radius_uv", VIEW_RADIUS / maxf(map.rect.size.x, 1.0))
	_mat.set_shader_parameter(&"rotation", camera_yaw)


## Dünya farkının (hedef − oyuncu; x, z) dairedeki yeri (px, halkanın merkezine göre; saf): haritanın dönüşüyle, kenara kırpılmadan.
static func offset_on_map(delta_xz: Vector2, yaw: float, px_per_m: float) -> Vector2:
	return delta_xz.rotated(yaw) * px_per_m


## Kenara kırpar (saf): yarıçaptan uzunsa aynı yönde kenarda. Döner: [yer, kırpıldı mı].
static func clamp_to_disc(offset: Vector2, radius: float) -> Array:
	if offset.length() <= radius:
		return [offset, false]
	return [offset.normalized() * radius, true]


## Oyuncu okunun ekrandaki açısı (saf): ok doku olarak yukarı bakar; kameranın yaw'ıyla döner harita için PI − bakış + yaw.
static func arrow_rotation(p_facing: float, yaw: float) -> float:
	return PI - p_facing + yaw


## Görev işaretinin dairedeki yeri (sınama): [yer (halkanın merkezine göre), kenarda mı]; hedef yoksa boş.
func quest_marker() -> Array:
	if target_xz == Vector2.INF or not target_xz.is_finite():
		return []
	var px_per_m := HudKit.MAP_RADIUS / VIEW_RADIUS
	return clamp_to_disc(offset_on_map(target_xz - player_xz, camera_yaw, px_per_m), HudKit.MAP_RADIUS - EDGE_INSET)


func _draw_overlay(ci: Control) -> void:
	var c := ring_center()
	var ring := HudKit.tex("map_ring")
	if ring:
		var s := HudKit.MAP_RING_SCALE
		ci.draw_texture_rect(ring, Rect2(c - HudKit.MAP_RING_PIVOT * s, ring.get_size() * s), false)
	else:
		ci.draw_arc(c, HudKit.MAP_RADIUS + 4.0, 0.0, TAU, 96, HudKit.SILVER, 7.0, true)
	var q := quest_marker()
	if not q.is_empty():
		var at: Vector2 = c + (q[0] as Vector2)
		var size := DIAMOND_SIZE * (0.86 if q[1] else 1.0) * (1.0 + 0.06 * sin(_pulse * PI))
		HudKit.draw_centered(ci, "marker_diamond", at, Vector2(size, size))
	var arrow := HudKit.tex("marker_arrow")
	ci.draw_set_transform(c, arrow_rotation(facing, camera_yaw), Vector2.ONE)
	if arrow:
		ci.draw_texture_rect(arrow, Rect2(-ARROW_SIZE * 0.5, ARROW_SIZE), false)
	else:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(0, -13), Vector2(10, 12), Vector2(0, 6), Vector2(-10, 12)]), Color.WHITE)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Halkayı ve işaretleri haritanın üstünde çizen katman.
class Overlay extends Control:
	var host: HudMinimap

	func _draw() -> void:
		if host:
			host._draw_overlay(self)
