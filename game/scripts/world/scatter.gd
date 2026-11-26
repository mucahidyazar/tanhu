class_name Scatter
extends RefCounted
## Nesneleri araziye dağıtmak için saf yardımcılar (test edilebilir, yan etkisiz).
## Daireler Vector3(x, z, yarıçap) biçiminde tutulur.


## Nokta herhangi bir dairenin (padding kadar genişletilmiş) içinde mi?
static func is_blocked(x: float, z: float, circles: Array[Vector3], padding: float = 0.0) -> bool:
	for c in circles:
		var dx := x - c.x
		var dz := z - c.y
		var r := c.z + padding
		if dx * dx + dz * dz < r * r:
			return true
	return false


## En yakın daire kenarına uzaklık (içerideyse negatif). Daire yoksa INF.
static func distance_to_circles(x: float, z: float, circles: Array[Vector3]) -> float:
	var best := INF
	for c in circles:
		best = minf(best, Vector2(x - c.x, z - c.y).length() - c.z)
	return best


## Disk içinde düzgün dağılmış rastgele nokta.
static func random_in_disk(rng: RandomNumberGenerator, center: Vector2, radius: float) -> Vector2:
	var r := radius * sqrt(rng.randf())
	var a := rng.randf() * TAU
	return center + Vector2(cos(a), sin(a)) * r


## Bir noktanın ait olduğu kare (chunk) anahtarı; görünmeyen kareler kırpılabilsin diye.
static func chunk_key(x: float, z: float, chunk_size: float) -> Vector2i:
	return Vector2i(floori(x / chunk_size), floori(z / chunk_size))


## Dikdörtgen bölgenin (Rect2: x, z, genişlik, derinlik) içinde 1, dışında yumuşakça 0'a inen ağırlık.
static func foreground_weight(x: float, z: float, area: Rect2, falloff: float = 3.0) -> float:
	var dx := maxf(maxf(area.position.x - x, x - area.end.x), 0.0)
	var dz := maxf(maxf(area.position.y - z, z - area.end.y), 0.0)
	return 1.0 - smoothstep(0.0, falloff, sqrt(dx * dx + dz * dz))


## Transform listesini MultiMesh'e dönüştürür. custom: her örnek için Color (shader'da INSTANCE_CUSTOM).
static func make_multimesh(mesh: Mesh, transforms: Array[Transform3D], custom: PackedColorArray = PackedColorArray()) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = not custom.is_empty()
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
		if mm.use_custom_data:
			mm.set_instance_custom_data(i, custom[i])
	return mm
