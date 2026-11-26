class_name MapEdge
extends Node3D
## İç haritanın kenarı (map.json «edge» {margin}; Kışlak): haritanın dikdörtgeninin margin metre içinde dört uzun engel kutusu (ObstacleBox).
## PlayerController'ın yürünür alanı dairedir (play_area); dikdörtgen harita (1.400 × 1.050 m) daireye sığmadığından sınırı bu kutular çizer:
## oyuncu kenara yürüyünce kutunun yüzünde kayar, görünmez duvar gibidir ama ses ve uyarı vermez (Kızıl Kazık yumuşak sınırdır, act1.md §2;
## harita kenarı yalnız dünyanın sonudur). Çizmez; «obstacles» grubundadır (MapWorld.collect_boxes).
##   var edge := MapEdge.new(); edge.setup(spec.rect(), 6.0); world.add_child(edge)

## Kutunun kalınlığı (m): hızlı binek bir karede geçemesin.
const THICKNESS := 40.0

var rect := Rect2()
var margin := 6.0
var _boxes: Array[ObstacleBox] = []


func setup(p_rect: Rect2, p_margin: float) -> void:
	rect = p_rect
	margin = p_margin
	_boxes = boxes_for(rect, margin)


func _ready() -> void:
	add_to_group(World.OBSTACLE_GROUP)


func get_obstacle_boxes() -> Array[ObstacleBox]:
	return _boxes


## Yürünür iç dikdörtgen (haritanın margin içi).
func walkable() -> Rect2:
	return rect.grow(-margin)


## Dört kutu (saf): kuzey, güney, batı, doğu; iç yüzleri haritanın margin metre içindedir.
static func boxes_for(r: Rect2, p_margin: float) -> Array[ObstacleBox]:
	var inner := r.grow(-p_margin)
	var t := THICKNESS
	var span := inner.size + Vector2.ONE * t * 2.0
	var c := inner.get_center()
	return [
		ObstacleBox.new(Vector2(c.x, inner.position.y - t * 0.5), Vector2(span.x * 0.5, t * 0.5)),
		ObstacleBox.new(Vector2(c.x, inner.end.y + t * 0.5), Vector2(span.x * 0.5, t * 0.5)),
		ObstacleBox.new(Vector2(inner.position.x - t * 0.5, c.y), Vector2(t * 0.5, span.y * 0.5)),
		ObstacleBox.new(Vector2(inner.end.x + t * 0.5, c.y), Vector2(t * 0.5, span.y * 0.5)),
	]
