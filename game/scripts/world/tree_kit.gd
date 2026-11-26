class_name TreeKit
extends RefCounted
## Çamlar ve Meshy doğa modelleri (ladinler, kayalar) için saf yardımcılar.
##
## - load_model(): assets/nature/<id>/<id>.glb içindeki meshi ve boyalı dokusunu bir kez yükler (önbellekli).
##   Dosya yoksa boş sözlük döner; çağıran prosedürel yedeğe geçer (konsola hata yazılmaz).
## - Meshy meshleri UV dikişlerinde çift köşelidir; bu yüzden motorun içe aktarırken ürettiği LOD'lar neredeyse
##   hiç sadeleşmez (ladinlerde hiç LOD yok). weld_by_position() köşeleri konuma göre birleştirir ve her köşeye
##   dokudan renk işler (UV gerekmez; gece ışığında dokulu modelden ayırt edilmez). Bunun üstüne:
##     lod_chain(): bütün LOD zinciri gömülü mesh (motor her örnek için uzaklığa göre seçer; çamlar),
##     baked_lod(): tek düzeyli, istenen üçgen sayısına sadeleştirilmiş mesh (MultiMesh'teki küçük kayalar).
## - spruce(): vadi ormanının ucuz prosedürel ladini. Siluet (kat kat, uçları sarkık dallar) ve renkler
##   Meshy ladininin (pine_b) dokusundan ölçülmüştür; uzaktan aynı ağaç gibi görünür.
## - Çam boyu / çeşidi, gövde engel yarıçapı ve takip kamerasının görüş hattı denetimi (saf fonksiyonlar).

## Meshy doğa modellerinin klasörü (res://assets/nature/<id>/<id>.glb).
const FOLDER := "nature"
## Uzun ve genç ladin modelleri.
const PINE_TALL := "pine_a"
const PINE_YOUNG := "pine_b"
## Kamp çamlarının ölçek birimi: ölçek 1 = 10 m boyunda ağaç (Forest.camp_trees; testlerdeki dal konisi
## da bu birimle tanımlıdır: tabanda 2,8, tepede 0,2 birim yarıçap).
const UNIT_HEIGHT := 10.0
## Bu boydan (metre) kısa çamlar genç ladin modeliyle çizilir (Forest.young_model / tall_model).
const YOUNG_MAX_HEIGHT := 6.5
## Dal konisi (ölçek birimiyle): tabandaki ve tepedeki yarıçap, dalların başladığı ve bittiği yükseklik.
const CONE_BASE_RADIUS := 2.8
const CONE_TOP_RADIUS := 0.2
const CONE_BOTTOM := 1.0
const CONE_TOP := 10.0

## Meshy ladininin (pine_b) dokusundan ölçülen renkler (sRGB): yaprakların koyu (%10), orta ve açık (%90)
## tonları ile gövde.
## Not: Köşe renkleri sRGB olarak saklanır (Godot köşe rengini 8 bit tutar; koyu yeşiller doğrusal uzayda
## birkaç basamağa sıkışırdı). foliage ve rock_formation shader'ları köşe aşamasında doğrusala çevirir.
const FOLIAGE_DARK_SRGB := Color(0.188, 0.322, 0.129)
const FOLIAGE_MID_SRGB := Color(0.216, 0.341, 0.165)
const FOLIAGE_LIGHT_SRGB := Color(0.216, 0.365, 0.235)
const TRUNK_SRGB := Color(0.44, 0.31, 0.153)

## Yüklenen modeller (yol → sözlük) ve üretilen hafif sürümler (anahtar → ArrayMesh).
static var _models := {}
static var _lods := {}


# --- Meshy modelleri ------------------------------------------------------------

## Model dosyasının yolu (saf fonksiyon).
static func model_path(id: String) -> String:
	return "res://assets/%s/%s/%s.glb" % [FOLDER, id, id]


## Modelin meshi ve dokusu: {"mesh": Mesh, "texture": Texture2D, "transform": Transform3D, "aabb": AABB}.
## "transform" meshin model kökündeki yeri, "aabb" bu dönüşümle model uzayındaki kutusudur.
## Meshy modelleri tek meshli ve tek yüzeylidir; ilk MeshInstance3D'nin ilk yüzeyi kullanılır.
## Model yoksa (ya da MeshyProp.models_enabled kapalıysa) boş sözlük döner.
static func load_model(id: String) -> Dictionary:
	if not MeshyProp.exists(FOLDER, id):
		return {}
	var path := model_path(id)
	if _models.has(path):
		return _models[path]
	var result := {}
	var scene := load(path) as PackedScene
	var root := scene.instantiate() if scene else null
	if root:
		var found := root.find_children("*", "MeshInstance3D", true, false)
		if not found.is_empty():
			var mi := found[0] as MeshInstance3D
			if mi.mesh and mi.mesh.get_surface_count() > 0:
				var xform := _relative_transform(root, mi)
				var src := mi.mesh.surface_get_material(0)
				result = {
					"mesh": mi.mesh,
					"texture": (src as BaseMaterial3D).albedo_texture if src is BaseMaterial3D else null,
					"transform": xform,
					"aabb": xform * mi.mesh.get_aabb(),
				}
		root.free()
	_models[path] = result
	return result


## Önbellekleri boşaltır (editörde modeller yeniden içe aktarılınca ve testlerde).
static func clear_cache() -> void:
	_models.clear()
	_lods.clear()


## Modelin birleştirilmiş (welded) meshi: LOD zinciri gömülüdür, motor her MeshInstance3D için ekrandaki
## boyuna göre düzeyi kendisi seçer. Model uzayındadır ("transform" uygulanmış); COLOR.rgb sRGB renk,
## COLOR.a = alpha (foliage.gdshader'da 1 = rüzgârda sallanır). Doku okunamazsa köşeler fallback rengini
## (sRGB) alır. Model yoksa null.
static func lod_chain(id: String, fallback: Color, alpha: float = 1.0) -> ArrayMesh:
	if load_model(id).is_empty():
		return null
	var key := "%s|zincir|%.2f" % [id, alpha]
	if _lods.has(key):
		return _lods[key]
	var welded := _welded(id, fallback, alpha)
	var importer := ImporterMesh.new()
	importer.add_surface(Mesh.PRIMITIVE_TRIANGLES, welded)
	importer.generate_lods(60.0, 60.0, [])
	var mesh := importer.get_mesh()
	_lods[key] = mesh
	return mesh


## Modelin tek düzeyli hafif sürümü: birleştirilmiş mesh yaklaşık target_triangles üçgene sadeleştirilir.
## (MultiMesh'te LOD bütün örnekler için birlikte seçildiğinden küçük kayalar sabit bir düzey kullanır.)
static func baked_lod(id: String, target_triangles: int, fallback: Color, alpha: float = 1.0) -> ArrayMesh:
	if load_model(id).is_empty():
		return null
	var key := "%s|%d|%.2f" % [id, target_triangles, alpha]
	if _lods.has(key):
		return _lods[key]
	var welded := _welded(id, fallback, alpha)
	var mesh := simplify(welded, target_triangles)
	_lods[key] = mesh
	return mesh


static func _welded(id: String, fallback: Color, alpha: float) -> Array:
	var model := load_model(id)
	if model.is_empty():
		return []
	var arrays: Array = (model["mesh"] as Mesh).surface_get_arrays(0)
	var image := _palette_image(model["texture"] as Texture2D)
	return weld_by_position(arrays, image, model["transform"] as Transform3D, fallback, alpha)


## UV dikişlerinde ikiye bölünmüş köşeleri konumlarına göre birleştirir (saf fonksiyon).
## Birleşen köşelerin normalleri ve (image verilmişse dokudan okunan, sRGB) renkleri ortalanır.
## Döner: Mesh.ARRAY_MAX boyunda dizi (köşe, normal, renk, indeks).
static func weld_by_position(arrays: Array, image: Image, xform: Transform3D = Transform3D.IDENTITY,
		fallback: Color = FOLIAGE_MID_SRGB, alpha: float = 1.0, precision: float = 10000.0) -> Array:
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if arrays[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
	var slot := {}
	var map := PackedInt32Array()
	map.resize(verts.size())
	var out_v := PackedVector3Array()
	var out_n := PackedVector3Array()
	var color_sum: Array[Vector4] = []
	for i in verts.size():
		var key := Vector3i((verts[i] * precision).round())
		var j: int = slot.get(key, -1)
		if j < 0:
			j = out_v.size()
			slot[key] = j
			out_v.append(xform * verts[i])
			out_n.append(Vector3.ZERO)
			color_sum.append(Vector4.ZERO)
		map[i] = j
		out_n[j] += normals[i] if i < normals.size() else Vector3.UP
		if image and i < uvs.size():
			var c := sample_image(image, uvs[i])
			color_sum[j] += Vector4(c.r, c.g, c.b, 1.0)
	var out_c := PackedColorArray()
	out_c.resize(out_v.size())
	for j in out_v.size():
		out_n[j] = (xform.basis * out_n[j]).normalized()
		var s := color_sum[j]
		var srgb := Color(s.x / s.w, s.y / s.w, s.z / s.w) if s.w > 0.0 else fallback
		out_c[j] = Color(srgb.r, srgb.g, srgb.b, alpha)
	var out_i := PackedInt32Array()
	out_i.resize(indices.size())
	for k in indices.size():
		out_i[k] = map[indices[k]]
	var result := []
	result.resize(Mesh.ARRAY_MAX)
	result[Mesh.ARRAY_VERTEX] = out_v
	result[Mesh.ARRAY_NORMAL] = out_n
	result[Mesh.ARRAY_COLOR] = out_c
	result[Mesh.ARRAY_INDEX] = _drop_degenerate(out_i)
	return result


## Birleştirilmiş meshi sadeleştirir: ImporterMesh'in ürettiği LOD'lar arasından üçgen sayısı hedefe en
## yakın olanı seçer (eşitlikte az üçgenli olan), kullanılmayan köşeleri atar.
static func simplify(arrays: Array, target_triangles: int) -> ArrayMesh:
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var best := indices
	if indices.size() / 3 > target_triangles:
		var importer := ImporterMesh.new()
		importer.add_surface(Mesh.PRIMITIVE_TRIANGLES, arrays)
		importer.generate_lods(60.0, 60.0, [])
		for l in importer.get_surface_lod_count(0):
			var lod := importer.get_surface_lod_indices(0, l)
			if lod.size() >= 3 and _closer(lod.size() / 3, best.size() / 3, target_triangles):
				best = lod
	return _compact(arrays, best)


## a üçgen sayısı hedefe b'den daha mı yakın? (Eşitlikte az olan.)
static func _closer(a: int, b: int, target: int) -> bool:
	var da := absi(a - target)
	var db := absi(b - target)
	return da < db or (da == db and a < b)


## Dokudan (sRGB) bilinear renk okuma; uv tekrarlanır (saf fonksiyon).
static func sample_image(image: Image, uv: Vector2) -> Color:
	var w := image.get_width()
	var h := image.get_height()
	var x := fposmod(uv.x, 1.0) * float(w) - 0.5
	var y := fposmod(uv.y, 1.0) * float(h) - 0.5
	var x0 := floori(x)
	var y0 := floori(y)
	var fx := x - float(x0)
	var fy := y - float(y0)
	var c00 := image.get_pixel(posmod(x0, w), posmod(y0, h))
	var c10 := image.get_pixel(posmod(x0 + 1, w), posmod(y0, h))
	var c01 := image.get_pixel(posmod(x0, w), posmod(y0 + 1, h))
	var c11 := image.get_pixel(posmod(x0 + 1, w), posmod(y0 + 1, h))
	return c00.lerp(c10, fx).lerp(c01.lerp(c11, fx), fy)


## Renk okumak için dokunun küçültülmüş (en fazla 256 piksel) ve sıkıştırması açılmış kopyası; okunamazsa null.
static func _palette_image(texture: Texture2D) -> Image:
	if texture == null:
		return null
	var image := texture.get_image()
	if image == null or image.is_empty():
		return null
	image = image.duplicate() as Image
	if image.is_compressed() and image.decompress() != OK:
		return null
	if image.has_mipmaps():
		image.clear_mipmaps()
	image.convert(Image.FORMAT_RGB8)
	# Kutu süzgeciyle yarıya indirme: her piksel altındaki dokuların ortalaması olur.
	while image.get_width() > 256 or image.get_height() > 256:
		image.shrink_x2()
	return image


static func _drop_degenerate(indices: PackedInt32Array) -> PackedInt32Array:
	var out := PackedInt32Array()
	for k in range(0, indices.size() - 2, 3):
		var a := indices[k]
		var b := indices[k + 1]
		var c := indices[k + 2]
		if a != b and b != c and a != c:
			out.append_array([a, b, c])
	return out


## Yalnızca indekslerin kullandığı köşelerle yeni bir ArrayMesh kurar.
static func _compact(arrays: Array, indices: PackedInt32Array) -> ArrayMesh:
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var remap := PackedInt32Array()
	remap.resize(verts.size())
	remap.fill(-1)
	var out_v := PackedVector3Array()
	var out_n := PackedVector3Array()
	var out_c := PackedColorArray()
	var out_i := PackedInt32Array()
	out_i.resize(indices.size())
	for k in indices.size():
		var i := indices[k]
		if remap[i] < 0:
			remap[i] = out_v.size()
			out_v.append(verts[i])
			out_n.append(normals[i])
			out_c.append(colors[i])
		out_i[k] = remap[i]
	var result := []
	result.resize(Mesh.ARRAY_MAX)
	result[Mesh.ARRAY_VERTEX] = out_v
	result[Mesh.ARRAY_NORMAL] = out_n
	result[Mesh.ARRAY_COLOR] = out_c
	result[Mesh.ARRAY_INDEX] = out_i
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, result)
	return mesh


## Bir düğümün verilen köke göre dönüşümü (aradaki Node3D'lerin dönüşümleri çarpılır).
static func _relative_transform(root: Node, node: Node3D) -> Transform3D:
	var xform := Transform3D.IDENTITY
	var n: Node = node
	while n != null and n != root:
		if n is Node3D:
			xform = (n as Node3D).transform * xform
		n = n.get_parent()
	return xform


# --- Kamp çamları -----------------------------------------------------------------

## Ölçekten ağacın boyu (metre).
static func tree_height(scale: float) -> float:
	return scale * UNIT_HEIGHT


## Gövde engel yarıçapı (metre): oyuncu gövdeye ve en alttaki sık dallara girmesin.
static func trunk_radius(height_m: float) -> float:
	return clampf(height_m * 0.06, 0.3, 0.75)


## Ağacın zemindeki tabanından h metre yukarıdaki dal konisi yarıçapı (metre; dal yoksa 0).
## Koni ölçek birimiyle tanımlıdır; bütün Meshy ve prosedürel çamlar bu koninin içinde kalır.
static func cone_radius(scale: float, h: float) -> float:
	var u := h / maxf(scale, 0.001)
	if u < CONE_BOTTOM * 0.8 or u > CONE_TOP + 0.5:
		return 0.0
	return lerpf(CONE_BASE_RADIUS, CONE_TOP_RADIUS, clampf((u - CONE_BOTTOM) / (CONE_TOP - CONE_BOTTOM), 0.0, 1.0)) * scale


## Göz (kamera) ile odak (oyuncu) arasındaki görüş hattının bu çamın dal konisine en yakın yatay payı
## (metre; eksi = görüş hattı dalların içinden geçiyor, INF = hiç yaklaşmıyor).
## tree: Vector4(x, z, ölçek, tohum); ground: ağacın tabanındaki zemin yüksekliği.
static func sight_clearance(eye: Vector3, focus: Vector3, tree: Vector4, ground: float) -> float:
	var best := INF
	for k in 25:
		var q := eye.lerp(focus, float(k) / 24.0)
		var radius := cone_radius(tree.z, q.y - ground)
		if radius <= 0.0:
			continue
		best = minf(best, Vector2(q.x, q.z).distance_to(Vector2(tree.x, tree.y)) - radius)
	return best


# --- Prosedürel ladin (vadi ormanı) -----------------------------------------------------

## Yapraklar ve gövde için renkler (sRGB): [koyu, orta, açık, gövde].
static func palette() -> Array[Color]:
	return [FOLIAGE_DARK_SRGB, FOLIAGE_MID_SRGB, FOLIAGE_LIGHT_SRGB, TRUNK_SRGB]


## Ucuz, stilize ladin: ince gövde ve üst üste binen, uçları sarkık, yıldız kenarlı koni katları.
## Siluet Meshy ladinine göre: en/boy ≈ 0,5, en geniş kat tabana yakın, tepe sivri.
## Yükseklik ~10 birim (UNIT_HEIGHT), taban y = 0. COLOR.rgb sRGB renk; COLOR.a = 1 yaprak, 0 gövde.
## with_trunk false ise gövde yoktur (uzak vadi ormanı: gövde piksel altıdır, 34 yerine 24 üçgen); katlar aynıdır.
static func spruce(rng_seed: int, tiers: int = 7, segments: int = 7, with_trunk: bool = true) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var colours := palette()
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var trunk := colours[3]
	if with_trunk:
		_add_trunk(vertices, normals, colors, indices, 0.22, 0.08, 0.0, 3.2, Color(trunk.r * 0.7, trunk.g * 0.7, trunk.b * 0.7, 0.0), Color(trunk.r, trunk.g, trunk.b, 0.0))
	var height := rng.randf_range(9.6, 10.2)
	for t in tiers:
		var f := float(t) / float(maxi(tiers - 1, 1))
		var radius := lerpf(2.55, 0.75, pow(f, 0.85)) * rng.randf_range(0.92, 1.06)
		var y0 := lerpf(1.1, height * 0.72, f)
		var tier_height := height - y0 if t == tiers - 1 else lerpf(3.0, 2.1, f)
		var bottom := colours[0].lerp(colours[1], f * 0.6)
		var top := colours[1].lerp(colours[2], 0.35 + f * 0.65)
		_add_tier(vertices, normals, colors, indices, rng, y0, radius, tier_height, segments, bottom, top)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _add_trunk(vertices: PackedVector3Array, normals: PackedVector3Array, colors: PackedColorArray, indices: PackedInt32Array,
		r_bottom: float, r_top: float, y0: float, y1: float, col_bottom: Color, col_top: Color) -> void:
	var base := vertices.size()
	var segments := 5
	var slope := (r_bottom - r_top) / maxf(y1 - y0, 0.001)
	for s in segments + 1:
		var a := TAU * float(s) / float(segments)
		var dir := Vector3(cos(a), 0.0, sin(a))
		var n := (dir + Vector3(0.0, slope, 0.0)).normalized()
		vertices.append(dir * r_bottom + Vector3(0.0, y0, 0.0))
		vertices.append(dir * r_top + Vector3(0.0, y1, 0.0))
		normals.append(n)
		normals.append(n)
		colors.append(col_bottom)
		colors.append(col_top)
	for s in segments:
		var b0 := base + s * 2
		indices.append_array([b0, b0 + 2, b0 + 1, b0 + 1, b0 + 2, b0 + 3])


## Bir dal katı: tepe noktasından inen, kenarı yıldız biçimli (uzun dal uçları sarkık) bir koni.
static func _add_tier(vertices: PackedVector3Array, normals: PackedVector3Array, colors: PackedColorArray, indices: PackedInt32Array,
		rng: RandomNumberGenerator, y0: float, radius: float, tier_height: float, segments: int, col_bottom: Color, col_top: Color) -> void:
	var base := vertices.size()
	var apex := Vector3(rng.randf_range(-0.06, 0.06), y0 + tier_height, rng.randf_range(-0.06, 0.06))
	var rim := segments * 2
	var phase := rng.randf() * TAU
	for s in rim + 1:
		var a := phase + TAU * float(s % rim) / float(rim) + rng.randf_range(-0.06, 0.06)
		var tip := s % 2 == 0
		var r := radius * (1.0 if tip else 0.62) * rng.randf_range(0.88, 1.08)
		var droop := rng.randf_range(0.35, 0.7) if tip else -0.08
		var dir := Vector3(cos(a), 0.0, sin(a))
		vertices.append(dir * r + Vector3(0.0, y0 - droop, 0.0))
		normals.append((dir * tier_height + Vector3(0.0, radius * 0.9, 0.0)).normalized())
		colors.append(col_bottom.lerp(col_top, 0.15) if tip else col_bottom)
	vertices.append(apex)
	normals.append(Vector3.UP)
	colors.append(col_top)
	var apex_index := vertices.size() - 1
	for s in rim:
		indices.append_array([base + s, base + s + 1, apex_index])
