extends Node3D
## Sınamanın sahte iç haritası (FaunaLayer): yükseklik yüzü, tarif (bölgeler, yapı kayıtları) ve engel yüzü (MapWorld'ün yüzü).

var ground: TerrainShape
var spec: MapSpec


func collect_obstacles() -> Array[Vector3]:
	return []
