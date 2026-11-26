class_name MapBaker
extends RefCounted
## İç haritanın ağır üretimi (godot.md §4.3 madde 4, §4.4, §4.5, §4.7): saf, düğüm kurmaz; tools/bake_map.gd başsız Godot'ta koşar, sonucu
## MapBake parçaları olarak yazar. MapWorld kurulurken parçaları okur; parça yoksa ya da imzası tutmazsa aynı işlevlerle burada üretir (yavaş
## yol, uyarılı). Parçalar:
##   ground  yükseklik (Image FORMAT_RF, 1 m; HeightmapShape okur) ve zemin maskesi (Image RGBA8, 2 m: R açık toprak, G kum, B çakıl,
##           A koyu otluk; childhood_ground.gdshader)
##   chunks  100 m'lik arazi parçaları, üç düzey (1, 4, 16 m ızgara), dikişte etek şeridi; dış halka (haritanın kenarından 3,2 km'ye dek
##           seyrekleşen ızgara: kaba arazi, tepeler, dağ siluetleri; K27)
##   grass   otun MultiMesh örnekleri (parça × çeşit; ham dizi: 12 dönüşüm + 4 özel veri)
##   nav     navmesh karoları (arazi parçalarıyla aynı 100 m; filter_baking_aabb ve border_size karo dikişini hizalar; yurt, ocak, kaya, çam
##           çıkıntı engelidir)
## Tarif MapSpec.ground, grass ve nav'dır (data/maps/<id>/map.json). Koordinatlar MapSpec'inki: dikdörtgen spec.rect() (bounds ya da (0, 0)
## ortada size), kuzey -Z. Hangi parçaların pişeceği spec.bakes'tir (yoksa dördü).
##
## Elle tarif edilen harita (Kışlak; ground.relief ya da ground.height_file): yükseklik TerrainPaint'in boyasıdır, dosyadan okunur
## (height.exr R32F 1 m, mask.png RGBA8 2 m, cover.png RGBA8 4 m; tools/paint_height.gd yazar), dosya yoksa burada boyanır. Zemin parçası
## ayrıca örtüyü (cover) ve normal dokusunu (RG8; normal_image) taşır. Arazi parçaları GPU'da yükselir (ground.gpu): üç düzeyin her biri için
## ortak düz ızgara (tam parça ve haritanın kenarındaki yarım parça), parça başına yalnız dikdörtgen ve yükseklik kutusu (aabb) saklanır;
## kislak_snow.gdshader yüksekliği dokudan alır. 154 parçanın üç düzeyi CPU ağı olsaydı ≈70 MB tutardı, böyle birkaç yüz KB'tır. Dış halka
## haritanın kenarının yüksekliğini dışa uzatır (Recipe.attach), üstüne tepeler, yönlü dağ siluetleri (far.sides) ve Buz Kolu'nun iki uçta
## süren vadisi (far.valleys) gelir: kenarda dikiş yoktur.

## Otun tutam çeşitleri: Vector4i(yaprak, tohum, kök yayılımı × 100, bölüt); son çeşit uzun ot (Meadow.tuft_mesh).
const TUFT_VARIANTS: Array[Vector4i] = [Vector4i(7, 5, 46, 1), Vector4i(8, 11, 52, 1), Vector4i(9, 23, 96, 2)]
const FLOATS_PER_TUFT := 16
## Etek şeridinin düzey başına derinliği (m; tarifte skirt) ve dış halkanın iç kenarının eteği (hücrenin oranı).
const RING_SKIRT := 0.4


## Tarifin imzası (saf): haritanın kimliği, boyu, zemin, ot ve navmesh tarifi, yapı kayıtları ve kapılar (engeller ve düz yerler bunlardan).
## Elle tarif edilen haritada ayrıca dikdörtgen, yükseklik ve maske dosyalarının içeriği (MD5), yol dosyası ve TerrainPaint'in değişmezleri:
## dosya elle değişirse parçalar eskir.
static func signature(spec: MapSpec) -> String:
	# Yapı kitinin değişmezleri (otun ve navmesh'in izi: GRASS_BASE ve ötekiler) de girer: iz değişince parçalar eskir.
	var inputs: Array = ["map", MapBake.VERSION, spec.id, spec.size, spec.ground, spec.grass, spec.nav,
		spec.structures, spec.gates, MapBake.script_constants(MapBaker), MapBake.script_constants(StructureKit)]
	if is_painted(spec):
		# Elle tarif edilen haritada renkler, belgeler ve akan çimen parçalara girmez (malzeme ve GrassField kurulurken okur): renk ayarı
		# yeniden pişirme istemez. Yapı kayıtlarından yalnız düz yerlere ve engellere girenler (tür, yer, boy, flat, obstacle) sayılır.
		var g := spec.ground.duplicate(true)
		g.erase("colors")
		g.erase("doc")
		var recs: Array = []
		for s: Dictionary in spec.structures:
			recs.append([s.get("kind"), s.get("id"), s.get("at"), s.get("size"), s.get("radius"), s.get("flat"), s.get("obstacle"),
				s.get("outdoor"), s.get("type"), s.get("trample"), s.get("y")])
		inputs = ["map", MapBake.VERSION, spec.id, spec.size, g, spec.nav, recs, spec.gates, MapBake.script_constants(MapBaker),
			MapBake.script_constants(StructureKit)]
		inputs.append_array([spec.rect(), spec.bakes, _file_hash(str(spec.ground.get("height_file", ""))),
			_file_hash(str(spec.ground.get("mask_file", ""))), _file_hash(str(spec.ground.get("cover_file", ""))),
			TerrainPaint.load_roads(spec), MapBake.script_constants(TerrainPaint)])
	return MapBake.signature_of(inputs)


## Elle tarif edilen harita mı (ground.relief ya da ground.height_file; Kışlak)?
static func is_painted(spec: MapSpec) -> bool:
	return spec.ground.has("relief") or spec.ground.has("height_file")


## Pişecek parçaların türleri: spec.bakes (yoksa ground, chunks, grass, nav). ground hep vardır.
static func kinds_of(spec: MapSpec) -> PackedStringArray:
	var out := PackedStringArray(spec.bakes) if not spec.bakes.is_empty() else PackedStringArray(["ground", "chunks", "grass", "nav"])
	if not out.has("ground"):
		out.insert(0, "ground")
	return out


## Bütün parçalar (pişirme aracı ve yavaş yol): ground ve spec.bakes'in öteki türleri (chunks, grass, nav).
static func bake(spec: MapSpec) -> Array[MapBake]:
	var out: Array[MapBake] = []
	var sig := signature(spec)
	var recipe := Recipe.new(spec)
	var ground := bake_painted_ground(spec) if is_painted(spec) else bake_ground(spec, recipe)
	var shape := shape_of(ground)
	recipe.attach(shape, spec)
	var mask: Image = ground.data["mask"]
	var kinds := kinds_of(spec)
	var parts: Array[MapBake] = [ground]
	if kinds.has("chunks"):
		parts.append(bake_gpu_chunks(spec, recipe, shape) if bool(spec.ground.get("gpu", is_painted(spec))) else bake_chunks(spec, recipe, shape))
	if kinds.has("grass"):
		parts.append(bake_grass(spec, shape, mask))
	if kinds.has("nav"):
		parts.append(bake_nav(spec, shape))
	for bake in parts:
		bake.signature = sig
		bake.map_id = spec.id
		out.append(bake)
	return out


## Dosyanın içeriğinin MD5'i (yoksa boş).
static func _file_hash(path: String) -> String:
	if path.is_empty() or not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_md5(path)


## Pişmiş zeminden yükseklik yüzü.
static func shape_of(ground: MapBake) -> HeightmapShape:
	return HeightmapShape.from_image(ground.data.get("height") as Image, ground.data.get("origin", Vector2.ZERO), float(ground.data.get("cell", 1.0)))


# --- Zemin: yükseklik ve maske --------------------------------------------------------------------

static func bake_ground(spec: MapSpec, recipe: Recipe) -> MapBake:
	var rect := spec.rect()
	var cell := float(spec.ground.get("cell", 1.0))
	var w := int(roundf(rect.size.x / cell)) + 1
	var d := int(roundf(rect.size.y / cell)) + 1
	var heights := PackedFloat32Array()
	heights.resize(w * d)
	for iz in d:
		var z := rect.position.y + float(iz) * cell
		for ix in w:
			heights[iz * w + ix] = recipe.height(rect.position.x + float(ix) * cell, z)
	var mcell := float(spec.ground.get("mask_cell", 2.0))
	var bake := MapBake.new()
	bake.kind = "ground"
	bake.data = {
		"height": HeightmapShape.to_image(heights, w, d), "origin": rect.position, "cell": cell,
		"mask": mask_image(recipe, rect, mcell), "mask_rect": Vector4(rect.position.x, rect.position.y, 1.0 / rect.size.x, 1.0 / rect.size.y),
	}
	return bake


## Zemin maskesi (saf; RGBA8, mcell aralıklı): R açık toprak (patikalar, ezik yerler), G kum (dere kıyısı), B çakıl (dere yatağı), A koyu otluk
## (gürültü lekeleri ve derenin çevresi).
static func mask_image(recipe: Recipe, rect: Rect2, mcell: float) -> Image:
	var w := int(roundf(rect.size.x / mcell)) + 1
	var d := int(roundf(rect.size.y / mcell)) + 1
	var bytes := PackedByteArray()
	bytes.resize(w * d * 4)
	var k := 0
	for iz in d:
		for ix in w:
			var m := recipe.mask_at(rect.position + Vector2(float(ix), float(iz)) * mcell)
			bytes[k] = int(clampf(m.x, 0.0, 1.0) * 255.0)
			bytes[k + 1] = int(clampf(m.y, 0.0, 1.0) * 255.0)
			bytes[k + 2] = int(clampf(m.z, 0.0, 1.0) * 255.0)
			bytes[k + 3] = int(clampf(m.w, 0.0, 1.0) * 255.0)
			k += 4
	return Image.create_from_data(w, d, false, Image.FORMAT_RGBA8, bytes)


## Elle tarif edilen zemin (saf olmayan: dosya okur): height.exr, mask.png ve cover.png varsa ve boyları tutuyorsa onlar, yoksa TerrainPaint
## burada boyar (yavaş; tools/paint_height.gd dosyaları yazar). Döner: ground parçası (height RF, mask RGBA8, cover RGBA8, normal RG8).
static func bake_painted_ground(spec: MapSpec) -> MapBake:
	var g := spec.ground
	var rect := spec.rect()
	var cell := float(g.get("cell", 1.0))
	var mcell := float(g.get("mask_cell", 2.0))
	var ccell := float(g.get("cover_cell", 4.0))
	var w := int(roundf(rect.size.x / cell)) + 1
	var d := int(roundf(rect.size.y / cell)) + 1
	var height := read_image(str(g.get("height_file", "")))
	var mask := read_image(str(g.get("mask_file", "")))
	var cover := read_image(str(g.get("cover_file", "")))
	if height and (height.get_width() != w or height.get_height() != d):
		push_warning("[map_baker] %s: yükseklik dosyası %d × %d, beklenen %d × %d: yeniden boyanıyor" % [spec.id, height.get_width(),
			height.get_height(), w, d])
		height = null
	if height == null or mask == null or cover == null:
		var paint := TerrainPaint.paint(spec)
		height = paint.height_image() if height == null else height
		mask = paint.mask_image(mcell) if mask == null else mask
		cover = paint.cover_image(ccell) if cover == null else cover
	if height.get_format() != Image.FORMAT_RF:
		height.convert(Image.FORMAT_RF)
	for img in [mask, cover]:
		if img.get_format() != Image.FORMAT_RGBA8:
			img.convert(Image.FORMAT_RGBA8)
	var bake := MapBake.new()
	bake.kind = "ground"
	bake.data = {
		"height": height, "origin": rect.position, "cell": cell, "mask": mask, "cover": cover, "normal": normal_image(height, cell),
		"mask_rect": Vector4(rect.position.x, rect.position.y, 1.0 / rect.size.x, 1.0 / rect.size.y),
	}
	return bake


## Dosyadan görüntü (res:// ya da mutlak yol; içe aktarılmayan .exr ve .png: importer skip). Yoksa ya da okunamazsa null.
static func read_image(path: String) -> Image:
	if path.is_empty() or not FileAccess.file_exists(path):
		return null
	# Mutlak yolla okunur: içe aktarılmayan dosya (importer skip) yalnız araçta ve başsız sınamada okunur, oyun pişmiş zemini okur.
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	return img if img and not img.is_empty() else null


## Yükseklikten normal dokusu (saf; RG8: normalin x ve z'si [−1, 1] → [0, 255], y gölgelendiricide √(1 − x² − z²)). Merkezi fark, cell.
static func normal_image(height: Image, cell: float) -> Image:
	var w := height.get_width()
	var d := height.get_height()
	var hs := height.get_data().to_float32_array()
	var bytes := PackedByteArray()
	bytes.resize(w * d * 2)
	var k := 0
	for iz in d:
		var z0 := maxi(iz - 1, 0) * w
		var z1 := mini(iz + 1, d - 1) * w
		var row := iz * w
		for ix in w:
			var hx := hs[row + mini(ix + 1, w - 1)] - hs[row + maxi(ix - 1, 0)]
			var hz := hs[z1 + ix] - hs[z0 + ix]
			var n := Vector3(-hx, 2.0 * cell, -hz).normalized()
			bytes[k] = int(clampf(n.x * 0.5 + 0.5, 0.0, 1.0) * 255.0 + 0.5)
			bytes[k + 1] = int(clampf(n.z * 0.5 + 0.5, 0.0, 1.0) * 255.0 + 0.5)
			k += 2
	return Image.create_from_data(w, d, false, Image.FORMAT_RG8, bytes)


# --- Arazi parçaları ve dış halka -----------------------------------------------------------------

## GPU'da yükselen parçalar (elle tarif edilen harita): her düzey için ortak düz ızgara (boy × düzey; tam ve kenarda kırpılmış parça),
## parça başına dikdörtgen, ağ kimlikleri ve yerel yükseklik kutusu (aabb: GPU yüksekliği ağda olmadığı için kırpma bununla yapılır).
## Dış halka CPU ağıdır (Recipe: kenarın yüksekliği dışa uzar).
static func bake_gpu_chunks(spec: MapSpec, recipe: Recipe, shape: HeightmapShape) -> MapBake:
	var g := spec.ground
	var size := float(g.get("chunk", 100.0))
	var lods: Array = g.get("lods", [1.0, 4.0, 16.0])
	var skirt := float(g.get("skirt", 1.6))
	var rect := spec.rect()
	var bake := MapBake.new()
	bake.kind = "chunks"
	var grids := {}
	var chunks: Array = []
	var nx := ceili(rect.size.x / size - 0.001)
	var nz := ceili(rect.size.y / size - 0.001)
	for cz in nz:
		for cx in nx:
			var r := chunk_rect(rect, size, cx, cz)
			var ids: Array = []
			for li in lods.size():
				var key := "%d_%d_%d" % [roundi(r.size.x * 10.0), roundi(r.size.y * 10.0), li]
				if not grids.has(key):
					grids[key] = bake.meshes.size()
					bake.meshes.append(flat_grid(r.size, float(lods[li]), skirt * float(li + 1)))
				ids.append(int(grids[key]))
			var span := height_span(shape, r)
			var deepest := skirt * float(lods.size()) + 0.5
			chunks.append({"key": Vector2i(cx, cz), "rect": r, "lods": ids,
				"aabb": AABB(Vector3(0.0, span.x - deepest, 0.0), Vector3(r.size.x, span.y - span.x + deepest + 0.5, r.size.y))})
	bake.data = {"gpu": true, "chunks": chunks, "ring": _bake_ring(bake, g, rect, recipe), "lod_ranges": g.get("lod_ranges", [150.0, 520.0]),
		"lod_margin": float(g.get("lod_margin", 12.0)), "skirt": skirt}
	return bake


## Dikdörtgenin içindeki en alçak ve en yüksek örnek (saf; Vector2(en az, en çok)).
static func height_span(shape: HeightmapShape, r: Rect2) -> Vector2:
	var lo := INF
	var hi := -INF
	var x0 := clampi(floori((r.position.x - shape.origin.x) / shape.cell), 0, shape.width - 1)
	var x1 := clampi(ceili((r.end.x - shape.origin.x) / shape.cell), 0, shape.width - 1)
	var z0 := clampi(floori((r.position.y - shape.origin.y) / shape.cell), 0, shape.depth - 1)
	var z1 := clampi(ceili((r.end.y - shape.origin.y) / shape.cell), 0, shape.depth - 1)
	for iz in range(z0, z1 + 1):
		for ix in range(x0, x1 + 1):
			var h := shape.data[iz * shape.width + ix]
			lo = minf(lo, h)
			hi = maxf(hi, h)
	return Vector2(lo, hi) if lo <= hi else Vector2.ZERO


## Ortak düz ızgara (saf): (0, 0)'dan size'a step aralıklı, y 0; dört kenarda skirt derinliğinde etek (köşeler y = −skirt). UV2.y köşenin
## eteğidir (yüzeyde 0): gölgelendirici yüksekliği dokudan alır, eteği UV2.y kadar indirir.
static func flat_grid(size: Vector2, step: float, skirt: float) -> ArrayMesh:
	var xs := grid_lines(0.0, size.x, step)
	var zs := grid_lines(0.0, size.y, step)
	var flat := func(_x: float, _z: float) -> float: return 0.0
	var up := func(_x: float, _z: float) -> Vector3: return Vector3.UP
	var mesh := _grid(flat, up, xs, zs, skirt, [true, true, true, true])
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uv2 := PackedVector2Array()
	uv2.resize(verts.size())
	for i in verts.size():
		uv2[i] = Vector2(1.0, skirt) if verts[i].y < -0.0001 else Vector2.ZERO
	arrays[Mesh.ARRAY_TEX_UV2] = uv2
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


static func bake_chunks(spec: MapSpec, recipe: Recipe, shape: HeightmapShape) -> MapBake:
	var g := spec.ground
	var size := float(g.get("chunk", 100.0))
	var lods: Array = g.get("lods", [1.0, 4.0, 16.0])
	var skirt := float(g.get("skirt", 1.6))
	var rect := spec.rect()
	var bake := MapBake.new()
	bake.kind = "chunks"
	var chunks: Array = []
	var nx := ceili(rect.size.x / size - 0.001)
	var nz := ceili(rect.size.y / size - 0.001)
	for cz in nz:
		for cx in nx:
			var r := chunk_rect(rect, size, cx, cz)
			var ids: Array = []
			for li in lods.size():
				ids.append(bake.meshes.size())
				bake.meshes.append(chunk_mesh(shape, r, float(lods[li]), skirt * float(li + 1)))
			chunks.append({"key": Vector2i(cx, cz), "rect": r, "lods": ids})
	bake.data = {"chunks": chunks, "ring": _bake_ring(bake, g, rect, recipe), "lod_ranges": g.get("lod_ranges", [150.0, 520.0]),
		"lod_margin": float(g.get("lod_margin", 12.0))}
	return bake


## Dış halkanın ağları parçanın ağlarına eklenir (tarifin ring düzeyleri: her biri dört şerit); döner: ağ kimlikleri.
static func _bake_ring(bake: MapBake, g: Dictionary, rect: Rect2, recipe: Recipe) -> Array:
	var ring: Array = []
	var inner := rect
	for level: Dictionary in g.get("ring", []):
		var c := float(level.get("cell", 32.0))
		var width := ceilf(float(level.get("width", 400.0)) / c) * c
		var outer := inner.grow(width)
		for strip in ring_strips(inner, outer):
			ring.append(bake.meshes.size())
			bake.meshes.append(grid_mesh(recipe, strip, c, c * RING_SKIRT))
		inner = outer
	return ring


## cx, cz. parçanın dikdörtgeni (saf; son parça haritanın kenarında kırpılır).
static func chunk_rect(rect: Rect2, size: float, cx: int, cz: int) -> Rect2:
	var a := rect.position + Vector2(float(cx), float(cz)) * size
	var b := Vector2(minf(a.x + size, rect.end.x), minf(a.y + size, rect.end.y))
	return Rect2(a, b - a)


## Izgara çizgileri (saf): from'dan to'ya step aralıkla, iki uç dahil (son aralık kısa olabilir).
static func grid_lines(from: float, to: float, step: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var n := floori((to - from) / step + 0.0001)
	for i in n + 1:
		out.append(from + float(i) * step)
	if to - out[out.size() - 1] > 0.001:
		out.append(to)
	return out


## Yükseklik ızgarasından parça ağı (saf): step aralıklı ızgara, normaller yüzden (her düzeyde aynı köşede aynı normal: dikişte ışık
## kırılmaz), dört kenarda skirt derinliğinde dışa bakan etek.
static func chunk_mesh(shape: HeightmapShape, r: Rect2, step: float, skirt: float) -> ArrayMesh:
	var xs := grid_lines(r.position.x, r.end.x, step)
	var zs := grid_lines(r.position.y, r.end.y, step)
	var height := func(x: float, z: float) -> float: return shape.height_at(x, z)
	var normal := func(x: float, z: float) -> Vector3: return shape.normal_at(x, z, shape.cell)
	return _grid(height, normal, xs, zs, skirt, [true, true, true, true])


## Tariften seyrek ızgara ağı (saf; dış halka): normaller sonlu farkla; etek yalnız iç kenarda (önceki halkanın kenarına bakan).
static func grid_mesh(recipe: Recipe, r: Rect2, step: float, skirt: float) -> ArrayMesh:
	var xs := grid_lines(r.position.x, r.end.x, step)
	var zs := grid_lines(r.position.y, r.end.y, step)
	var eps := step * 0.5
	var height := func(x: float, z: float) -> float: return recipe.height(x, z)
	var normal := func(x: float, z: float) -> Vector3:
		var hx := recipe.height(x + eps, z) - recipe.height(x - eps, z)
		var hz := recipe.height(x, z + eps) - recipe.height(x, z - eps)
		return Vector3(-hx, 2.0 * eps, -hz).normalized()
	return _grid(height, normal, xs, zs, skirt, [true, true, true, true])


## Halkanın dört şeridi (saf): kuzey ve güney tam en, batı ve doğu aradaki boy.
static func ring_strips(inner: Rect2, outer: Rect2) -> Array[Rect2]:
	return [
		Rect2(outer.position, Vector2(outer.size.x, inner.position.y - outer.position.y)),
		Rect2(Vector2(outer.position.x, inner.end.y), Vector2(outer.size.x, outer.end.y - inner.end.y)),
		Rect2(Vector2(outer.position.x, inner.position.y), Vector2(inner.position.x - outer.position.x, inner.size.y)),
		Rect2(Vector2(inner.end.x, inner.position.y), Vector2(outer.end.x - inner.end.x, inner.size.y)),
	]


## Izgara ağı ve etekleri. Ön yüz Godot'nun sırasıdır (yukarı bakan yüzde (b − a) × (c − a) aşağıyı gösterir; Terrain.build_mesh gibi).
## edges: [kuzey (z en küçük), güney, batı (x en küçük), doğu] eteği olsun mu.
static func _grid(height: Callable, normal: Callable, xs: PackedFloat32Array, zs: PackedFloat32Array, skirt: float, edges: Array) -> ArrayMesh:
	var nx := xs.size()
	var nz := zs.size()
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	verts.resize(nx * nz)
	norms.resize(nx * nz)
	for iz in nz:
		for ix in nx:
			var x := xs[ix]
			var z := zs[iz]
			verts[iz * nx + ix] = Vector3(x, float(height.call(x, z)), z)
			norms[iz * nx + ix] = normal.call(x, z)
	var idx := PackedInt32Array()
	for iz in nz - 1:
		for ix in nx - 1:
			var a := iz * nx + ix
			var b := a + 1
			var c := a + nx
			var dd := c + 1
			idx.append_array(PackedInt32Array([a, b, c, b, dd, c]))
	if skirt > 0.0:
		var runs: Array = []
		if edges[0]:
			runs.append([_row(0, nx), Vector3(0.0, 0.0, -1.0)])
		if edges[1]:
			runs.append([_row((nz - 1) * nx, nx), Vector3(0.0, 0.0, 1.0)])
		if edges[2]:
			runs.append([_column(0, nx, nz), Vector3(-1.0, 0.0, 0.0)])
		if edges[3]:
			runs.append([_column(nx - 1, nx, nz), Vector3(1.0, 0.0, 0.0)])
		for run: Array in runs:
			_add_skirt(verts, norms, idx, run[0], run[1], skirt)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _row(first: int, count: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	for i in count:
		out.append(first + i)
	return out


static func _column(ix: int, nx: int, nz: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	for iz in nz:
		out.append(iz * nx + ix)
	return out


## Kenar boyunca aşağı inen şerit: köşeler kenarın kopyası (aynı normal), dışa bakar.
static func _add_skirt(verts: PackedVector3Array, norms: PackedVector3Array, idx: PackedInt32Array, edge: PackedInt32Array, outward: Vector3,
		depth: float) -> void:
	if edge.size() < 2:
		return
	var low := PackedInt32Array()
	for i in edge:
		low.append(verts.size())
		verts.append(verts[i] - Vector3(0.0, depth, 0.0))
		norms.append(norms[i])
	# Sıra ilk çiftten seçilir: üçgenin (v1 − v0) × (v2 − v0)'ı dışa bakmıyorsa (Godot'nun ön yüzü) o sıra kullanılır.
	var cross := (verts[low[0]] - verts[edge[0]]).cross(verts[edge[1]] - verts[edge[0]])
	var keep := cross.dot(outward) < 0.0
	for k in edge.size() - 1:
		var a := edge[k]
		var b := edge[k + 1]
		var la := low[k]
		var lb := low[k + 1]
		if keep:
			idx.append_array(PackedInt32Array([a, la, b, b, la, lb]))
		else:
			idx.append_array(PackedInt32Array([a, b, la, b, lb, la]))


# --- Ot ---------------------------------------------------------------------------------------------

static func bake_grass(spec: MapSpec, shape: HeightmapShape, mask: Image) -> MapBake:
	var bake := MapBake.new()
	bake.kind = "grass"
	bake.data = {"entries": grass_entries(spec, shape, mask, grass_blockers(spec))}
	return bake


## Otun çıkmadığı daireler (saf): yurtlar, ocak, eşya, kaya, çam (Vector3(x, z, yarıçap)). Yapı kitinin kayıtları (StructureKit.handles:
## K51 yurtları, Kışlak'ın yapı kataloğu) kitin izindendir (StructureKit.grass_blockers: izin daireleri ve kutuları kaplayan daireler,
## çatılı yapının bütün tabanı).
static func grass_blockers(spec: MapSpec) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var ctx := StructureKit.zone_ctx(spec)
	for s: Dictionary in spec.structures:
		var at: Vector2 = s["at"]
		if StructureKit.handles(s):
			out.append_array(StructureKit.grass_blockers(s, ctx))
			continue
		match str(s.get("kind", "")):
			"yurt":
				out.append(Vector3(at.x, at.y, TerrainPaint.yurt_radius(s) + 0.4))
			"campfire":
				out.append(Vector3(at.x, at.y, 2.2))
			"prop":
				out.append(Vector3(at.x, at.y, 0.9))
			"rock":
				out.append(Vector3(at.x, at.y, float(s.get("size", 2.0)) * 0.45))
			"tree":
				out.append(Vector3(at.x, at.y, 0.7))
	return out


## Otun parçaları (saf): [[Vector3i(parça x, parça z, çeşit), ham dizi], ...] anahtarla sıralı. Titreşen ızgara; maskenin açık toprağında,
## çakılında ve kumunda yok ya da seyrek, koyu otlukta sık ve uzun; çemberin kenarına doğru seyrekleşir.
static func grass_entries(spec: MapSpec, shape: HeightmapShape, mask: Image, blockers: Array[Vector3]) -> Array:
	var g := spec.grass
	var seed_value := int(g.get("seed", 91))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var center := MapSpec.vec2(g.get("center", [0.0, 0.0]))
	var radius := float(g.get("radius", 100.0))
	var count := maxi(int(g.get("count", 20000)), 1)
	var chunk := float(g.get("chunk", 40.0))
	var tall_share := float(g.get("tall_share", 0.3))
	var short_h := MapSpec.vec2(g.get("short_height", [0.16, 0.3]))
	var tall_h := MapSpec.vec2(g.get("tall_height", [0.4, 0.6]))
	var clump := _noise(seed_value + 5, 1.0 / 14.0, 2)
	var tall_noise := _noise(seed_value + 9, 1.0 / 20.0, 2)
	var patch := _noise(seed_value + 17, 1.0 / 11.0, 3)
	var rect := spec.rect()
	var mrect := Rect2(rect.position, rect.size)
	var cell := sqrt(PI * radius * radius / float(count))
	var n := ceili(radius / cell)
	var buffers := {}
	for ix in range(-n, n):
		for iz in range(-n, n):
			var p := center + Vector2(float(ix) + rng.randf(), float(iz) + rng.randf()) * cell
			var dist := p.distance_to(center)
			var roll := rng.randf()
			if dist > radius or not mrect.has_point(p) or Scatter.is_blocked(p.x, p.y, blockers, 0.1):
				continue
			var m := sample_mask(mask, mrect, p)
			var density := (1.0 - smoothstep(radius * 0.72, radius, dist)) * lerpf(0.55, 1.1, clump.get_noise_2d(p.x, p.y) * 0.5 + 0.5)
			density *= (1.0 - 0.96 * m.x) * (1.0 - 0.9 * m.y) * (1.0 - 0.97 * m.z) * (0.75 + 0.55 * m.w)
			if roll > density:
				continue
			var tall := rng.randf() < tall_share * (1.0 + m.w) * smoothstep(-0.2, 0.4, tall_noise.get_noise_2d(p.x, p.y)) * 2.0
			var variant := TUFT_VARIANTS.size() - 1 if tall else rng.randi() % (TUFT_VARIANTS.size() - 1)
			var span := tall_h if tall else short_h
			var h := rng.randf_range(span.x, span.y) * lerpf(1.0, 0.6, smoothstep(0.0, 0.5, m.x))
			var w := h * Meadow.tuft_aspect(h) * rng.randf_range(0.9, 1.15)
			var y := shape.height_at(p.x, p.y) - 0.02
			var key := Vector3i(floori(p.x / chunk), floori(p.y / chunk), variant)
			var buffer: PackedFloat32Array = buffers.get(key, PackedFloat32Array())
			buffers.erase(key)
			buffer.append_array(PackedFloat32Array([w, 0.0, 0.0, p.x, 0.0, h, 0.0, y, 0.0, 0.0, w, p.y,
				rng.randf(), rng.randf(), rng.randf(), clampf(patch.get_noise_2d(p.x, p.y) * 0.5 + 0.5, 0.0, 1.0)]))
			buffers[key] = buffer
	var keys: Array = buffers.keys()
	keys.sort()
	var out: Array = []
	for key: Vector3i in keys:
		out.append([key, buffers[key]])
	return out


## Maskenin noktadaki değeri (saf; en yakın örnek): Vector4(toprak, kum, çakıl, koyu otluk).
static func sample_mask(mask: Image, rect: Rect2, p: Vector2) -> Vector4:
	if mask == null or mask.is_empty():
		return Vector4.ZERO
	var uv := (p - rect.position) / rect.size
	var ix := clampi(int(roundf(uv.x * float(mask.get_width() - 1))), 0, mask.get_width() - 1)
	var iz := clampi(int(roundf(uv.y * float(mask.get_height() - 1))), 0, mask.get_height() - 1)
	var c := mask.get_pixel(ix, iz)
	return Vector4(c.r, c.g, c.b, c.a)


# --- Navmesh karoları -------------------------------------------------------------------------------

static func bake_nav(spec: MapSpec, shape: HeightmapShape) -> MapBake:
	var nav: Dictionary = spec.nav
	var size := float(spec.ground.get("chunk", 100.0))
	var rect := spec.rect()
	var obstacles := nav_obstacles(spec)
	var outlines := nav_outlines(spec)
	var tiles: Array = []
	var nx := ceili(rect.size.x / size - 0.001)
	var nz := ceili(rect.size.y / size - 0.001)
	for cz in nz:
		for cx in nx:
			var r := chunk_rect(rect, size, cx, cz)
			tiles.append({"key": Vector2i(cx, cz), "rect": r, "mesh": nav_tile(shape, rect, r, nav, obstacles, outlines)})
	var bake := MapBake.new()
	bake.kind = "nav"
	bake.data = {"tiles": tiles}
	return bake


## Navmesh engelleri (saf): [Vector3(x, z, yarıçap)] yapı kayıtlarından (yurt, ocak, eşya, kaya, çam). Atlar engel değildir (yürür).
## Yapı kitinin kayıtları (StructureKit.handles) kitin izinin daireleridir (StructureKit.footprint; kutuları nav_outlines'tadır): ahırın
## içi, ağılın içi yürünür, duvarı ve çiti engeldir.
static func nav_obstacles(spec: MapSpec) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var ctx := StructureKit.zone_ctx(spec)
	for s: Dictionary in spec.structures:
		var at: Vector2 = s["at"]
		if StructureKit.handles(s):
			for c: Variant in StructureKit.footprint(s, ctx).get("circles", []):
				out.append(c)
			continue
		match str(s.get("kind", "")):
			"yurt":
				out.append(Vector3(at.x, at.y, TerrainPaint.yurt_radius(s) + 0.15))
			"campfire":
				out.append(Vector3(at.x, at.y, 1.0))
			"prop":
				out.append(Vector3(at.x, at.y, 0.6))
			"rock":
				out.append(Vector3(at.x, at.y, float(s.get("size", 2.0)) * 0.42))
			"tree":
				out.append(Vector3(at.x, at.y, 0.45))
			_:
				var r := TerrainPaint.obstacle_radius(s)
				if r > 0.0:
					out.append(Vector3(at.x, at.y, r))
	return out


## Navmesh'in çokgen engelleri (saf): yapı kitinin kayıtlarının kutuları (StructureKit.footprint «boxes»: ahırın duvarları, çitin kesimleri,
## kutulu yapılar), dünyada dört köşe.
static func nav_outlines(spec: MapSpec) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	var ctx := StructureKit.zone_ctx(spec)
	for s: Dictionary in spec.structures:
		if not StructureKit.handles(s):
			continue
		for b: Variant in StructureKit.footprint(s, ctx).get("boxes", []):
			out.append(StructureKit.box_outline(b))
	return out


## Bir karonun navmesh'i (saf; NavigationServer3D'nin eşzamanlı pişirmesi): kaynak yüzey karonun ve border_size'ın biraz ötesine kadar
## yükseklik ızgarasının üçgenleri (source_cell aralıklı), engeller çıkıntı engeli; filter_baking_aabb karoyu tam keser.
static func nav_tile(shape: HeightmapShape, map_rect: Rect2, r: Rect2, nav: Dictionary, obstacles: Array[Vector3],
		outlines: Array[PackedVector2Array] = []) -> NavigationMesh:
	var job := nav_source(shape, map_rect, r, nav, obstacles, outlines)
	NavigationServer3D.bake_from_source_geometry_data(job[0], job[1])
	return job[0]


## Karonun pişirme işi (saf; iş parçacığında da kurulur, MapNav): [NavigationMesh (ayarlı, filter_baking_aabb karonun kesimi),
## NavigationMeshSourceGeometryData3D (yükseklik ızgarasının üçgenleri, daire engeller ve outlines'ın çokgen engelleri)]. Pişirmeyi çağıran
## yapar: eşzamanlı (nav_tile, pişirme aracı) ya da eşzamansız (NavigationServer3D.bake_from_source_geometry_data_async; MapNav).
static func nav_source(shape: HeightmapShape, map_rect: Rect2, r: Rect2, nav: Dictionary, obstacles: Array[Vector3],
		outlines: Array[PackedVector2Array] = []) -> Array:
	var nm := NavigationMesh.new()
	nm.cell_size = float(nav.get("cell_size", 0.25))
	nm.cell_height = float(nav.get("cell_height", 0.25))
	nm.agent_radius = float(nav.get("agent_radius", 0.45))
	nm.agent_height = float(nav.get("agent_height", 1.8))
	nm.agent_max_climb = float(nav.get("agent_max_climb", 0.5))
	nm.agent_max_slope = float(nav.get("agent_max_slope", 40.0))
	nm.border_size = maxf(nm.agent_radius * 2.0, 1.0)
	nm.edge_max_error = 1.0
	var src_cell := float(nav.get("source_cell", 2.0))
	var src_rect := r.grow(nm.border_size + src_cell * 2.0).intersection(map_rect)
	var low := INF
	var high := -INF
	var xs := grid_lines(src_rect.position.x, src_rect.end.x, src_cell)
	var zs := grid_lines(src_rect.position.y, src_rect.end.y, src_cell)
	var faces := PackedVector3Array()
	for iz in zs.size() - 1:
		for ix in xs.size() - 1:
			var a := Vector3(xs[ix], shape.height_at(xs[ix], zs[iz]), zs[iz])
			var b := Vector3(xs[ix + 1], shape.height_at(xs[ix + 1], zs[iz]), zs[iz])
			var c := Vector3(xs[ix], shape.height_at(xs[ix], zs[iz + 1]), zs[iz + 1])
			var d := Vector3(xs[ix + 1], shape.height_at(xs[ix + 1], zs[iz + 1]), zs[iz + 1])
			# Ön yüz Godot'nun sırasıdır (çizimdeki gibi); navmesh pişirmesi yukarı bakan yüzü bu sırayla yürünür sayar.
			faces.append_array(PackedVector3Array([a, b, c, b, d, c]))
			for v in [a, b, c, d]:
				low = minf(low, v.y)
				high = maxf(high, v.y)
	var src := NavigationMeshSourceGeometryData3D.new()
	src.add_faces(faces, Transform3D.IDENTITY)
	for o in obstacles:
		if not src_rect.grow(o.z).has_point(Vector2(o.x, o.y)):
			continue
		var ring := PackedVector3Array()
		for k in 12:
			var ang := TAU * float(k) / 12.0
			ring.append(Vector3(o.x + cos(ang) * o.z, 0.0, o.y + sin(ang) * o.z))
		var ground := shape.height_at(o.x, o.y)
		src.add_projected_obstruction(ring, ground - 2.0, 6.0, true)
	for outline in outlines:
		if outline.size() < 3:
			continue
		var box := Rect2(outline[0], Vector2.ZERO)
		var pts := PackedVector3Array()
		for q in outline:
			box = box.expand(q)
			pts.append(Vector3(q.x, 0.0, q.y))
		if not src_rect.intersects(box):
			continue
		var c := box.get_center()
		src.add_projected_obstruction(pts, shape.height_at(c.x, c.y) - 2.0, 8.0, true)
	# 4.7.2'de border_size kutunun içinden yenir (denendi: karo kenardan tam border_size içeride biter): kutu karonun border_size kadar
	# büyüğüdür, pişen karo tam karonun kenarında biter, komşusunun kenarıyla aynı çizgidedir (kenar bağlantısı; ajan yarıçapı kenarı yemez).
	var cut := r.grow(nm.border_size)
	nm.filter_baking_aabb = AABB(Vector3(cut.position.x, low - 4.0, cut.position.y), Vector3(cut.size.x, high - low + 8.0, cut.size.y))
	return [nm, src]


static func _noise(p_seed: int, frequency: float, octaves: int, fractal: FastNoiseLite.FractalType = FastNoiseLite.FRACTAL_FBM) -> FastNoiseLite:
	var n := FastNoiseLite.new()
	n.seed = p_seed
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = frequency
	n.fractal_type = fractal
	n.fractal_octaves = octaves
	return n


## Haritanın yükseklik ve zemin tarifi (saf; iş parçacığında kendi örneğiyle): MapSpec.ground'dan. height(x, z) haritanın içinde de dışında
## da süreklidir: pişmiş yükseklik ve dış halka aynı işlevden örneklenir, kenarda dikiş yoktur.
class Recipe:
	extends RefCounted

	var half := Vector2(200.0, 150.0)
	var swell: FastNoiseLite
	var swell_amp := 0.0
	var detail: FastNoiseLite
	var detail_amp := 0.0
	var rim_noise: FastNoiseLite
	var rim_from := 0.55
	var rim_to := 1.05
	var rim_amp := 0.0
	var gate_radius := 40.0
	var gates: Array[Vector2] = []
	var hills: FastNoiseLite
	var hill_amp := 0.0
	var ridges: FastNoiseLite
	var mountain_from := 1600.0
	var mountain_to := 3000.0
	var mountain_amp := 0.0
	var lush: FastNoiseLite
	var lush_threshold := 0.58
	## Düz yerler: [merkez Vector2, yarıçap, geçiş, yükseklik].
	var flats: Array = []
	var stream := PackedVector2Array()
	var stream_width := 6.0
	var stream_depth := 1.0
	var stream_bank := 6.0
	## Patikalar: [noktalar PackedVector2Array, en]; ezik yerler: Vector3(x, z, yarıçap).
	var paths: Array = []
	var trampled: Array[Vector3] = []
	## Elle tarif edilen harita (attach): içerisi pişmiş yükseklik, dışarısı kenarın yüksekliği ve dış halkanın terimleri.
	var painted := false
	var shape: HeightmapShape
	var rect := Rect2()
	## Yönlü dağlar: [birim yön Vector2, yayılım (°), from, to, genlik, gürültü]; vadiler: [noktalar, en].
	var sides: Array = []
	var valleys: Array = []

	func _init(spec: MapSpec) -> void:
		var g := spec.ground
		var seed_value := int(g.get("seed", 4207))
		half = spec.size * 0.5
		var sw: Dictionary = g.get("swell", {})
		swell = MapBaker._noise(seed_value, 1.0 / float(sw.get("wavelength", 90.0)), 3)
		swell_amp = float(sw.get("amplitude", 2.0))
		var de: Dictionary = g.get("detail", {})
		detail = MapBaker._noise(seed_value + 11, 1.0 / float(de.get("wavelength", 12.0)), 2)
		detail_amp = float(de.get("amplitude", 0.3))
		var rim: Dictionary = g.get("rim", {})
		rim_noise = MapBaker._noise(seed_value + 23, 1.0 / float(rim.get("wavelength", 120.0)), 3)
		rim_from = float(rim.get("from", 0.55))
		rim_to = float(rim.get("to", 1.05))
		rim_amp = float(rim.get("amplitude", 14.0))
		gate_radius = float(rim.get("gate_radius", 40.0))
		for gate: Dictionary in spec.gates:
			gates.append(gate["at"])
		var far: Dictionary = g.get("far", {})
		hills = MapBaker._noise(seed_value + 37, 1.0 / float(far.get("hill_wavelength", 700.0)), 4)
		hill_amp = float(far.get("hill_amplitude", 60.0))
		ridges = MapBaker._noise(seed_value + 53, 1.0 / float(far.get("mountain_wavelength", 900.0)), 5, FastNoiseLite.FRACTAL_RIDGED)
		mountain_from = float(far.get("mountain_from", 1600.0))
		mountain_to = float(far.get("mountain_to", 3000.0))
		mountain_amp = float(far.get("mountain_amplitude", 380.0))
		var lu: Dictionary = g.get("lush", {})
		lush = MapBaker._noise(seed_value + 71, float(lu.get("frequency", 0.03)), 3)
		lush_threshold = float(lu.get("threshold", 0.58))
		var st: Dictionary = g.get("stream", {})
		for p: Variant in st.get("points", []):
			stream.append(MapSpec.vec2(p))
		stream_width = float(st.get("width", 6.0))
		stream_depth = float(st.get("depth", 1.0))
		stream_bank = float(st.get("bank", 6.0))
		for path: Dictionary in g.get("paths", []):
			var pts := PackedVector2Array()
			for p: Variant in path.get("points", []):
				pts.append(MapSpec.vec2(p))
			paths.append([pts, float(path.get("width", 2.4))])
		for t: Dictionary in g.get("trampled", []):
			var at := MapSpec.vec2(t.get("at", [0.0, 0.0]))
			trampled.append(Vector3(at.x, at.y, float(t.get("radius", 3.0))))
		for f: Dictionary in g.get("flats", []):
			var c := MapSpec.vec2(f.get("at", [0.0, 0.0]))
			flats.append([c, float(f.get("radius", 10.0)), float(f.get("blend", 10.0)), natural(c.x, c.y)])

	## Elle tarif edilen haritanın pişmiş yüksekliğine bağlanır (MapBaker.bake, ground parçasından sonra): içerisi o yüzdür, dışarısı
	## kenarın yüksekliğinin dışa uzantısı ve far'ın terimleri (tepeler, yönlü dağlar, vadiler).
	func attach(p_shape: HeightmapShape, spec: MapSpec) -> void:
		if not MapBaker.is_painted(spec):
			return
		painted = true
		shape = p_shape
		rect = spec.rect()
		var far: Dictionary = spec.ground.get("far", {})
		var seed_value := int(spec.ground.get("seed", 1041))
		hills = MapBaker._noise(seed_value + 37, 1.0 / float(far.get("hill_wavelength", 650.0)), 4)
		hill_amp = float(far.get("hill_amplitude", 60.0))
		sides.clear()
		var k := 0
		for s: Dictionary in far.get("sides", []):
			k += 1
			sides.append([TerrainPaint.compass_dir(float(s.get("toward", 180.0))), float(s.get("spread", 60.0)), float(s.get("from", 400.0)),
				float(s.get("to", 2600.0)), float(s.get("amplitude", 400.0)),
				MapBaker._noise(seed_value + 53 + k * 7, 1.0 / float(s.get("wavelength", 800.0)), 5, FastNoiseLite.FRACTAL_RIDGED)])
		valleys.clear()
		for v: Dictionary in far.get("valleys", []):
			var pts := PackedVector2Array()
			for p: Variant in v.get("points", []):
				pts.append(MapSpec.vec2(p))
			valleys.append([pts, float(v.get("width", 150.0))])

	## Elle tarif edilen haritanın yüksekliği: içeride pişmiş yüz; dışarıda kenarın en yakın örneği (yüz kendisi kırpar), kenardan uzaklıkla
	## yükselen tepeler ve yönlü dağ siluetleri; vadilerin yakınında yükselme söner (Buz Kolu iki uçta sürer). Kenarda (uzaklık 0) yüzle aynı.
	func painted_height(x: float, z: float) -> float:
		var h := shape.height_at(x, z)
		var p := Vector2(x, z)
		var inside := Vector2(clampf(x, rect.position.x, rect.end.x), clampf(z, rect.position.y, rect.end.y))
		var beyond := p.distance_to(inside)
		if beyond <= 0.0:
			return h
		var calm := 1.0
		for v: Array in valleys:
			var dv := MapBaker.polyline_distance(v[0], p)
			calm = minf(calm, smoothstep(float(v[1]) * 0.5, float(v[1]) * 1.8, dv))
		var rise := hill_amp * smoothstep(0.0, 800.0, beyond) * (hills.get_noise_2d(x, z) * 0.5 + 0.5)
		var dir := (p - rect.get_center()).normalized()
		for s: Array in sides:
			var ang := rad_to_deg(acos(clampf(dir.dot(s[0]), -1.0, 1.0)))
			var aw := 1.0 - smoothstep(float(s[1]) * 0.55, float(s[1]), ang)
			if aw <= 0.0:
				continue
			var ridge := clampf((s[5] as FastNoiseLite).get_noise_2d(x, z) * 0.5 + 0.5, 0.0, 1.0)
			rise += float(s[4]) * aw * smoothstep(float(s[2]), float(s[3]), beyond) * ridge * ridge
		return h + rise * calm * smoothstep(0.0, 60.0, beyond)

	## Düz yerler uygulanmadan önceki yükseklik: bozkır dalgası ve ayrıntı, kenarın tepeleri (kapılarda geçit), dışarıda tepeler ve dağlar,
	## derenin yatağı.
	func natural(x: float, z: float) -> float:
		if painted:
			return painted_height(x, z)
		var h := swell_amp * swell.get_noise_2d(x, z) + detail_amp * detail.get_noise_2d(x, z)
		var d := maxf(absf(x) / half.x, absf(z) / half.y)
		var rim := rim_amp * smoothstep(rim_from, rim_to, d) * (0.6 + 0.4 * (rim_noise.get_noise_2d(x, z) * 0.5 + 0.5))
		for gate in gates:
			rim *= lerpf(0.18, 1.0, smoothstep(gate_radius * 0.3, gate_radius, Vector2(x, z).distance_to(gate)))
		h += rim
		var beyond := maxf(d - 1.0, 0.0) * minf(half.x, half.y)
		h += hill_amp * smoothstep(0.0, 800.0, beyond) * (hills.get_noise_2d(x, z) * 0.5 + 0.5)
		var r := Vector2(x, z).length()
		if r > mountain_from:
			var ridge := clampf(ridges.get_noise_2d(x, z) * 0.5 + 0.5, 0.0, 1.0)
			h += mountain_amp * smoothstep(mountain_from, mountain_to, r) * ridge * ridge
		var s := stream_distance(Vector2(x, z))
		var reach := stream_width * 0.5 + stream_bank
		if s < reach:
			h -= stream_depth * (1.0 - smoothstep(stream_width * 0.3, reach, s))
		return h

	## Yükseklik: doğal yükseklik, düz yerlerde merkezin yüksekliğine çekilir (yurtlar, belirme, kapılar).
	func height(x: float, z: float) -> float:
		if painted:
			return painted_height(x, z)
		var h := natural(x, z)
		for f: Array in flats:
			var dist := Vector2(x, z).distance_to(f[0])
			if dist < float(f[1]) + float(f[2]):
				h = lerpf(h, float(f[3]), 1.0 - smoothstep(float(f[1]), float(f[1]) + float(f[2]), dist))
		return h

	## Derenin orta çizgisine uzaklık (m; dere yoksa INF).
	func stream_distance(p: Vector2) -> float:
		return MapBaker.polyline_distance(stream, p)

	## En yakın patikanın kenarına uzaklık (m; içeride eksi).
	func path_edge(p: Vector2) -> float:
		var best := INF
		for path: Array in paths:
			best = minf(best, MapBaker.polyline_distance(path[0], p) - float(path[1]) * 0.5)
		return best

	## Maske: Vector4(açık toprak, kum, çakıl, koyu otluk).
	func mask_at(p: Vector2) -> Vector4:
		var soil := 1.0 - smoothstep(-0.2, 1.1, path_edge(p))
		for t in trampled:
			soil = maxf(soil, 1.0 - smoothstep(t.z - 1.6, t.z + 0.6, p.distance_to(Vector2(t.x, t.y))))
		var s := stream_distance(p) - stream_width * 0.5
		var gravel := 1.0 - smoothstep(-1.2, 0.5, s)
		var sand := (1.0 - smoothstep(0.4, 3.2, s)) * (1.0 - gravel)
		var dark := smoothstep(lush_threshold, lush_threshold + 0.16, lush.get_noise_2d(p.x, p.y) * 0.5 + 0.5)
		dark = maxf(dark, (1.0 - smoothstep(2.5, 14.0, s)) * 0.7) * (1.0 - soil) * (1.0 - gravel)
		return Vector4(soil, sand, gravel, dark)


## Kırık çizgiye uzaklık (saf; nokta yoksa INF).
static func polyline_distance(points: PackedVector2Array, p: Vector2) -> float:
	if points.size() == 0:
		return INF
	if points.size() == 1:
		return p.distance_to(points[0])
	var best := INF
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var ab := b - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 1e-9), 0.0, 1.0)
		best = minf(best, p.distance_to(a + ab * t))
	return best
