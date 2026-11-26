class_name ObstacleBox
extends RefCounted
## Döndürülmüş dikdörtgen engel (otağdaki yatak, sandık, dolap): serbest gezintide karakter kutunun kenarlarından
## body_radius kadar uzak durur; köşelerin çevresinden yuvarlak bir yolla kayar. Hesaplar düzlemseldir (dünya
## x, z) ve saf fonksiyondur (bkz. tests/unit/test_ring_wall.gd).

## Kutunun merkezi (dünya x, z) ve yarı boyutları (metre; x kutunun kendi x ekseni boyunca).
var center := Vector2.ZERO
var half := Vector2(0.5, 0.5)
## Kutunun kendi x ve z eksenlerinin dünya düzlemindeki yönleri (birim).
var axis_x := Vector2(1.0, 0.0)
var axis_z := Vector2(0.0, 1.0)


func _init(p_center := Vector2.ZERO, p_half := Vector2(0.5, 0.5), p_axis_x := Vector2(1.0, 0.0)) -> void:
	center = p_center
	half = p_half.abs()
	axis_x = p_axis_x.normalized() if p_axis_x.length_squared() > 0.000001 else Vector2(1.0, 0.0)
	axis_z = Vector2(-axis_x.y, axis_x.x)


## Bir Node3D dönüşümünden (yerel x/z yarı boyutlu, yere paralel) kutu: dönüşümün x ekseni yatay düzleme yansıtılır.
static func from_transform(xform: Transform3D, p_half: Vector2) -> ObstacleBox:
	var x := Vector2(xform.basis.x.x, xform.basis.x.z)
	var z := Vector2(xform.basis.z.x, xform.basis.z.z)
	var box := ObstacleBox.new(Vector2(xform.origin.x, xform.origin.z), p_half, x)
	# Aynalı dönüşümde z ekseni ters yöne bakar; yarı boyutlar eksenlere göre olduğundan sonuç değişmez.
	if z.length_squared() > 0.000001:
		box.axis_z = z.normalized()
	return box


## Noktayı kutunun dışına iter (kutuya body_radius'tan yakınsa).
func push_out(p: Vector2, body_radius: float) -> Vector2:
	var rel := p - center
	var local := Vector2(rel.dot(axis_x), rel.dot(axis_z))
	var nearest := local.clamp(-half, half)
	var diff := local - nearest
	var dist := diff.length()
	if dist >= body_radius:
		return p
	if dist > 0.00001:
		local = nearest + diff / dist * body_radius
	else:
		# Kutunun içinde: en az içeri girdiği kenardan dışarı çıkar.
		var gap := half - local.abs()
		if gap.x < gap.y:
			local.x = (half.x + body_radius) * (1.0 if local.x >= 0.0 else -1.0)
		else:
			local.y = (half.y + body_radius) * (1.0 if local.y >= 0.0 else -1.0)
	return center + axis_x * local.x + axis_z * local.y


## Nokta kutunun içinde mi (body_radius payı olmadan)?
func contains(p: Vector2) -> bool:
	var rel := p - center
	return absf(rel.dot(axis_x)) <= half.x and absf(rel.dot(axis_z)) <= half.y
