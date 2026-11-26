class_name RingWall
extends RefCounted
## Kapılı dairesel duvar (otağın keçe duvarı): serbest gezintide duvardan geçilmez, yalnızca kapı aralığından
## girilip çıkılır.
##
## - İçerideki ya da dışarıdaki karakter duvara yaslanınca duvar boyunca kayar (geldiği tarafta kalır).
## - Kapı aralığı, kapı yönünde uzanan bir koridordur (yarı genişliği door_half_width - body_radius); koridordaki
##   karakter serbesttir. Eşikteyken yana kayan karakter kapı pervazına dayanır (koridorda tutulur).
## - Tek adımda duvarın öbür yanına geçilemez (kare takılmasında bile).
## Hesaplar düzlemseldir (dünya x, z) ve saf fonksiyondur (bkz. tests/unit/test_ring_wall.gd).

## Duvarın merkezi (dünya x, z) ve orta yüzeyinin yarıçapı (metre).
var center := Vector2.ZERO
var radius := 3.0
## Duvarın kalınlığı (metre): karakter iç ve dış yüzden body_radius kadar uzak durur.
var thickness := 0.16
## Kapının baktığı yön (birim; merkezden dışarı) ve kapı aralığının yarı genişliği (metre).
var door_dir := Vector2(0.0, 1.0)
var door_half_width := 0.42


func _init(p_center := Vector2.ZERO, p_radius := 3.0, p_door_dir := Vector2(0.0, 1.0), p_door_half_width := 0.42, p_thickness := 0.16) -> void:
	center = p_center
	radius = p_radius
	door_dir = p_door_dir.normalized() if p_door_dir.length_squared() > 0.000001 else Vector2(0.0, 1.0)
	door_half_width = p_door_half_width
	thickness = p_thickness


## Nokta duvarın içinde mi?
func contains(p: Vector2) -> bool:
	return p.distance_to(center) < radius


## Karakterin kapı koridorunda dolaşabileceği yarı genişlik (metre; en az 0).
func passage_half_width(body_radius: float) -> float:
	return maxf(door_half_width - body_radius, 0.0)


## from'dan to'ya giden adımın sonu, duvara göre düzeltilmiş (saf).
func resolve(from: Vector2, to: Vector2, body_radius: float) -> Vector2:
	var inner := radius - thickness * 0.5 - body_radius
	var outer := radius + thickness * 0.5 + body_radius
	var rel_to := to - center
	var rel_from := from - center
	# Kapı koridoru her zaman serbesttir.
	if _in_passage(rel_to, body_radius):
		return to
	var d_to := rel_to.length()
	var inside_from := rel_from.length() < radius
	var inside_to := d_to < radius
	var in_band := d_to > inner and d_to < outer
	if not in_band and inside_to == inside_from:
		return to
	# Eşikteki karakter yana kayınca pervaza dayanır: yanal konumu koridorun içine sıkıştırılır.
	if _in_passage(rel_from, body_radius) and absf(rel_from.length() - radius) < (outer - inner) * 0.5 + 0.001:
		var side := Vector2(-door_dir.y, door_dir.x)
		var half := passage_half_width(body_radius)
		return center + door_dir * rel_to.dot(door_dir) + side * clampf(rel_to.dot(side), -half, half)
	# Duvara yaslanma: karakter geldiği tarafta, duvarın yüzünde kalır.
	var dir := door_dir
	if d_to > 0.0001:
		dir = rel_to / d_to
	elif rel_from.length() > 0.0001:
		dir = rel_from.normalized()
	return center + dir * (inner if inside_from else outer)


## Nokta (merkeze göre) kapı koridorunda mı?
func _in_passage(rel: Vector2, body_radius: float) -> bool:
	if rel.dot(door_dir) <= 0.0:
		return false
	return absf(rel.dot(Vector2(-door_dir.y, door_dir.x))) <= passage_half_width(body_radius)
