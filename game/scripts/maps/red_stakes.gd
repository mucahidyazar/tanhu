class_name RedStakes
extends Node3D
## Kızıl Kazık hattı (act1.md §2 «Yumuşak sınır», §9.7; K43): bölge kenarı duvar değildir, yerde kırmızı başlı kazıklardır. Hat map.json
## «red_stakes»tır: rütbe 0 alanının (Kışlak, Esir Çukuru ve aradaki yol) dış çizgisi; kazıklar spacing metre arayla dizilir, yolların
## geçtiği yerde (yolun yarı eni + gap metre) boşluk kalır: yol hattı keser, kural görünür kalır (kazıklar hattın iki yanında durur).
## Kazık 1,25 m boyunda, başı kırmızı bezlidir; K98'in 28 m'lik kadrajında ≈25 piksel boyla okunur. Hepsi tek MultiMesh'tir (bir çizim,
## gölge düşürür). Sayaç ve Kazık Atlısı (40 sn, Güven −2) kuralın sahibinindir; burada yalnız görünüş ve hattın sorgusu vardır.
##   var stakes := RedStakes.new()
##   stakes.setup(def, ground, roads)        # def: map.json red_stakes
##   stakes.crossed(from, to)                # iki nokta arasında hat geçildi mi (sayaç için)
##   stakes.inside(p)                        # nokta hattın içinde mi (rütbe 0 alanı)

const POLE := Color("#5b4632")
const HEAD := Color("#a3241a")

var outline := PackedVector2Array()
var spacing := 4.5
var gap := 2.5
## Kazıkların yerleri (dünya; zeminde) ve sayısı.
var points: PackedVector3Array = []

var _mmi: MultiMeshInstance3D


## Kurar: tarif (outline: [[x, z], ...] kapalı çokgen; spacing, gap), yükseklik yüzü ve yollar (roads.json «roads»: boşluklar).
func setup(def: Dictionary, shape: TerrainShape, roads: Array = []) -> void:
	outline.clear()
	for p: Variant in def.get("outline", []):
		outline.append(MapSpec.vec2(p))
	spacing = float(def.get("spacing", 4.5))
	gap = float(def.get("gap", 2.5))
	points = stake_points(outline, spacing, roads, gap, shape)


## Saf: kazıkların yerleri. Çokgenin kenarları boyunca spacing aralıkla (köşeler dahil), yol orta çizgisine (yarı en + gap) yakın olanlar
## düşer. shape verilmişse y zemindedir.
static func stake_points(poly: PackedVector2Array, p_spacing: float, roads: Array, p_gap: float, shape: TerrainShape = null) -> PackedVector3Array:
	var out := PackedVector3Array()
	if poly.size() < 2:
		return out
	var lines: Array = []
	for r: Dictionary in roads:
		var pts := PackedVector2Array()
		for q: Variant in r.get("points", []):
			pts.append(MapSpec.vec2(q))
		lines.append([pts, float(r.get("width", 3.0)) * 0.5 + p_gap])
	var n := poly.size()
	for i in n:
		var a := poly[i]
		var b := poly[(i + 1) % n]
		var seg := a.distance_to(b)
		var count := maxi(1, ceili(seg / p_spacing))
		for k in count:
			var p := a.lerp(b, float(k) / float(count))
			var blocked := false
			for line: Array in lines:
				if MapBaker.polyline_distance(line[0], p) <= float(line[1]):
					blocked = true
					break
			if blocked:
				continue
			out.append(Vector3(p.x, shape.height_at(p.x, p.y) if shape else 0.0, p.y))
	return out


## Nokta hattın içinde mi (çokgen; rütbe 0 alanı)?
func inside(p: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(p, outline)


## İki nokta arasında hat geçildi mi (biri içeride, öteki dışarıda)?
func crossed(from: Vector2, to: Vector2) -> bool:
	return inside(from) != inside(to)


func _ready() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = stake_mesh()
	mm.instance_count = points.size()
	for i in points.size():
		var lean := Basis(Vector3(1, 0, 0), 0.06 * sin(float(i) * 2.3)) * Basis(Vector3(0, 0, 1), 0.05 * cos(float(i) * 1.7))
		var basis := Basis(Vector3.UP, float(i) * 0.9) * lean
		mm.set_instance_transform(i, Transform3D(basis.scaled(Vector3.ONE * (0.92 + 0.16 * fposmod(float(i) * 0.618, 1.0))), points[i] - Vector3(0, 0.08, 0)))
	_mmi = MultiMeshInstance3D.new()
	_mmi.name = "Stakes"
	_mmi.multimesh = mm
	_mmi.material_override = Style.toon(Color.WHITE, {"use_vertex_color": true, "brush_strength": 0.1})
	add_child(_mmi)


## Kazığın ağı (köşe renkli): ince direk ve kırmızı baş, başta küçük bez (BoxMesh'lerin dizileri: sarım Godot'nunki).
static func stake_mesh() -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	for part: Array in [[Vector3(0.0, 0.62, 0.0), Vector3(0.07, 1.24, 0.07), POLE], [Vector3(0.0, 1.16, 0.0), Vector3(0.1, 0.26, 0.1), HEAD],
			[Vector3(0.09, 1.12, 0.0), Vector3(0.14, 0.18, 0.012), HEAD.darkened(0.1)]]:
		var box := BoxMesh.new()
		box.size = part[1]
		var arr := box.get_mesh_arrays()
		var base := verts.size()
		for v: Vector3 in arr[Mesh.ARRAY_VERTEX]:
			verts.append(v + part[0])
			cols.append(part[2])
		norms.append_array(arr[Mesh.ARRAY_NORMAL])
		for i: int in arr[Mesh.ARRAY_INDEX]:
			idx.append(base + i)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
