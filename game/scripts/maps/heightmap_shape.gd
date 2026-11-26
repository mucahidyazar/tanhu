class_name HeightmapShape
extends TerrainShape
## İç haritanın yükseklik yüzü (godot.md §4.4 «tek yükseklik yüzü»): pişmiş yükseklik ızgarasından çift doğrusal okuma. Kampın
## TerrainShape'i ve Ordos'un OrdosGround'u gibi TerrainShape'tir: oyuncu, kamera, binek ve ok height_at(x, z) sorar. Saftır (düğüm kurmaz):
## iş parçacığında da okunur.
##
## Izgara satır satırdır (z satır, x sütun), origin örnek (0, 0)'ın dünya noktası (x, z), cell örnek aralığı (m). Izgaranın dışı en yakın
## kenar örneğidir (kamera kutusu haritanın içinde kalır; dış halkanın ağı ayrıca pişer). Veri MapBake'in "ground" parçasındadır (Image,
## FORMAT_RF): tools/bake_map.gd yazar; elle çizilen yükseklik (Kışlak'ın height.exr'i) de aynı biçime çevrilir.
##   var shape := HeightmapShape.from_image(img, Vector2(-200, -150), 1.0)
##   shape.height_at(12.5, -3.0)

## Örnekler (satır satır: index = iz * width + ix), boyutları, ilk örneğin dünya noktası ve aralık.
var data := PackedFloat32Array()
var width := 0
var depth := 0
var origin := Vector2.ZERO
var cell := 1.0


func _init(p_data: PackedFloat32Array = PackedFloat32Array(), p_width: int = 0, p_depth: int = 0, p_origin: Vector2 = Vector2.ZERO,
		p_cell: float = 1.0) -> void:
	super()
	data = p_data
	width = p_width
	depth = p_depth
	origin = p_origin
	cell = maxf(p_cell, 0.0001)


## Görüntüden yüz (saf; FORMAT_RF ya da başka biçim: kırmızı kanal metre). Görüntü boşsa düz yüz.
static func from_image(img: Image, p_origin: Vector2, p_cell: float) -> HeightmapShape:
	if img == null or img.is_empty():
		return HeightmapShape.new(PackedFloat32Array([0.0]), 1, 1, p_origin, p_cell)
	var src := img
	if src.get_format() != Image.FORMAT_RF:
		src = img.duplicate() as Image
		src.convert(Image.FORMAT_RF)
	return HeightmapShape.new(src.get_data().to_float32_array(), src.get_width(), src.get_height(), p_origin, p_cell)


## Izgaradan görüntü (FORMAT_RF; pişirme aracı saklar).
static func to_image(p_data: PackedFloat32Array, p_width: int, p_depth: int) -> Image:
	return Image.create_from_data(p_width, p_depth, false, Image.FORMAT_RF, p_data.to_byte_array())


## Çift doğrusal yükseklik (m).
func height_at(x: float, z: float) -> float:
	if width <= 0 or depth <= 0:
		return 0.0
	var fx := clampf((x - origin.x) / cell, 0.0, float(width - 1))
	var fz := clampf((z - origin.y) / cell, 0.0, float(depth - 1))
	var ix := mini(int(fx), width - 2) if width > 1 else 0
	var iz := mini(int(fz), depth - 2) if depth > 1 else 0
	var tx := fx - float(ix) if width > 1 else 0.0
	var tz := fz - float(iz) if depth > 1 else 0.0
	var i := iz * width + ix
	var h00 := data[i]
	var h10 := data[i + 1] if width > 1 else h00
	var h01 := data[i + width] if depth > 1 else h00
	var h11 := data[i + width + 1] if width > 1 and depth > 1 else h00
	return lerpf(lerpf(h00, h10, tx), lerpf(h01, h11, tx), tz)


## Yüzün normali (merkezi fark).
func normal_at(x: float, z: float, eps: float = 0.5) -> Vector3:
	var hx := height_at(x + eps, z) - height_at(x - eps, z)
	var hz := height_at(x, z + eps) - height_at(x, z - eps)
	return Vector3(-hx, 2.0 * eps, -hz).normalized()


## Izgaranın örneği (sınırda kırpılır).
func sample(ix: int, iz: int) -> float:
	return data[clampi(iz, 0, depth - 1) * width + clampi(ix, 0, width - 1)]


## Izgaranın kapladığı dikdörtgen (x, z).
func rect() -> Rect2:
	return Rect2(origin, Vector2(float(width - 1), float(depth - 1)) * cell)


## Nokta ızgaranın içinde mi?
func contains(x: float, z: float) -> bool:
	return rect().has_point(Vector2(x, z))


## Kampın yüzünün sorguları iç haritada anlamsızdır: doğal yükseklik pişmiş yüksekliktir, su yok, orman yoğunluğu yok, köşe rengi nötr.
func natural_height_at(x: float, z: float) -> float:
	return height_at(x, z)


func is_underwater(_x: float, _z: float) -> bool:
	return false


func forest_density(_x: float, _z: float) -> float:
	return 0.0


func vertex_tint(_x: float, _z: float) -> Color:
	return Color.WHITE
