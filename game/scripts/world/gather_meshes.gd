class_name GatherMeshes
extends RefCounted
## Toplama düğümlerinin kodla kurulan ağları (economy.md §3.7 «Okunurluk», §11.3; K66: düğüm programatiktir). Her ağ köşe rengini taşır
## (doğrusal renk), tek toon malzemesiyle çizilir (Style.toon, use_vertex_color): tür başına bir MultiMesh, bir çizim. Uzak kadrajda (K98,
## 28 m) okunsun diye renkler zeminden ayrılır: kesik odun açık, kabuk koyu, demir pası, bakır yeşili, tezek koyu kahve, saz saman sarısı.
##   var mesh := GatherMeshes.for_look({"geo": "pine"}, 3)   # ArrayMesh (taban y = 0, gerçek boy)
##   GatherMeshes.tool_mesh("axe")                           # elde taşınan araç (sapın ucu orijinde, +Y boyunca)

const BARK := Color("#4a3626")
const CUT := Color("#b89468")
const IRON := Color("#7a4a32")
const COPPER := Color("#3f8f6f")
const STONE := Color("#8f8a7e")
const STONE_DARK := Color("#6b665d")
const REED := Color("#c8b26a")
const REED_TIP := Color("#8a6a3a")
const DUNG := Color("#4b3a26")
const HAY := Color("#c2a85e")
const HERB := Color("#7f8f7c")
const WOOD := Color("#7a5534")
const WOOD_DARK := Color("#4f3622")
const METAL := Color("#5a5c62")


## Bir türün görünüşünden ağ (look.geo; bilinmeyen geo küçük bir tümsek). seed: aynı türün çeşidi.
static func for_look(look: Dictionary, seed := 1) -> ArrayMesh:
	match str(look.get("geo", "")):
		"pine":
			return pine(seed)
		"juniper":
			return juniper(seed)
		"willow":
			return juniper(seed + 31, Color("#6f7d4e"))
		"deadfall":
			return deadfall(seed)
		"reed":
			return reed(seed)
		"herb":
			return herb(seed, SkyRig.to_color(look.get("leaf", HERB.to_html(false))), SkyRig.to_color(look.get("tip", look.get("leaf", HERB.to_html(false)))))
		"dung":
			return dung(seed)
		"heap":
			return heap(SkyRig.to_color(look.get("color", HAY.to_html(false))), float(look.get("squash", 1.0)))
		"boulder":
			return boulder(seed)
		"vein":
			return vein(seed, SkyRig.to_color(look.get("ore", IRON.to_html(false))))
		"scree":
			return scree(seed)
		"block":
			return chopping_block()
		"bush":
			return bush(seed, SkyRig.to_color(look.get("berry", "#b8322a")), SkyRig.to_color(look.get("leaf", "#55603e")))
	return heap(STONE_DARK, 0.5)


# --- Ağlar ---------------------------------------------------------------------------------------------------------------

## Çam: deneme haritasının çamlarıyla aynı boyda (≈7 m) ama gövdesi açık: dallar 1,9 m'den başlar, kesen Mete ve baltası uzak kadrajda
## gövdenin önünde okunur (TreeKit'in ladini yere dek dallıdır). Altı kat, koyudan açığa; kabuk koyu, gövde yukarı incelir.
static func pine(seed := 1) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1300 + seed
	var parts: Array = [[_cyl(0.22, 0.09, 6.6, 8), Transform3D(Basis(), Vector3(0, 3.3, 0)), BARK]]
	var tiers := 6
	for t in tiers:
		var f := float(t) / float(tiers - 1)
		var r := lerpf(1.4, 0.38, f) * rng.randf_range(0.92, 1.06)
		var y0 := lerpf(1.9, 6.0, f)
		var h := lerpf(1.6, 1.4, f)
		var col := Color("#26422a").lerp(Color("#3f6a3a"), f * 0.8 + rng.randf_range(-0.05, 0.05))
		parts.append([_cyl(r, 0.02, h, 9), Transform3D(Basis(Vector3.UP, rng.randf_range(0.0, TAU)), Vector3(0, y0 + h * 0.5, 0)), col])
	return merge(parts)


static func juniper(seed := 1, tint := Color("#3f5a3a")) -> ArrayMesh:
	var parts: Array = [[_cyl(0.12, 0.09, 1.0, 6), Transform3D(Basis(), Vector3(0, 0.5, 0)), BARK]]
	var rng := RandomNumberGenerator.new()
	rng.seed = 700 + seed
	for k in 6:
		var a := TAU * k / 6.0 + rng.randf_range(-0.3, 0.3)
		var r := rng.randf_range(0.35, 0.6)
		var y := rng.randf_range(1.0, 2.6)
		var s := rng.randf_range(0.55, 0.85)
		parts.append([_sphere(s, s * 1.3, 6, 4), Transform3D(Basis(), Vector3(cos(a) * r, y, sin(a) * r)), tint.darkened(rng.randf_range(0.0, 0.2))])
	parts.append([_sphere(0.45, 0.9, 6, 4), Transform3D(Basis(), Vector3(0, 3.0, 0)), tint.lightened(0.08)])
	return merge(parts)


## Kuru dal: yere düşmüş üç dal, açık kabuk uçları.
static func deadfall(seed := 1) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 900 + seed
	var parts: Array = []
	for k in 3:
		var yaw := rng.randf_range(0.0, PI)
		var len := rng.randf_range(1.0, 1.5)
		var b := Basis(Vector3.UP, yaw) * Basis(Vector3(0, 0, 1), PI * 0.5 + rng.randf_range(-0.12, 0.12))
		parts.append([_cyl(0.045, 0.035, len, 5), Transform3D(b, Vector3(rng.randf_range(-0.2, 0.2), 0.06 + k * 0.05, rng.randf_range(-0.2, 0.2))), CUT.darkened(0.25)])
	return merge(parts)


## Saz kümesi: sık, uzun, saman sarısı yapraklar ve dört başak.
static func reed(seed := 1) -> ArrayMesh:
	var parts: Array = []
	var blades := MeshKit.grass_clump(16, 400 + seed, 0.22)
	parts.append([blades, Transform3D(Basis().scaled(Vector3(1.4, 1.8, 1.4)), Vector3.ZERO), REED])
	var rng := RandomNumberGenerator.new()
	rng.seed = 410 + seed
	for k in 4:
		var p := Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(1.5, 1.85), rng.randf_range(-0.2, 0.2))
		parts.append([_sphere(0.05, 0.22, 5, 3), Transform3D(Basis(), p), REED_TIP])
	return merge(parts)


static func herb(seed := 1, leaf := HERB, tip := HERB) -> ArrayMesh:
	var parts: Array = [[MeshKit.grass_clump(10, 500 + seed, 0.12), Transform3D(Basis().scaled(Vector3(1.6, 0.45, 1.6)), Vector3.ZERO), leaf]]
	parts.append([_sphere(0.22, 0.12, 6, 3), Transform3D(Basis(), Vector3(0, 0.18, 0)), tip])
	return merge(parts)


## Tezek: üst üste basık üç disk (koyu kahve; açık ota karşı okunur).
static func dung(seed := 1) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 600 + seed
	var parts: Array = []
	for k in 3:
		var p := Vector3(rng.randf_range(-0.18, 0.18), 0.03 + k * 0.035, rng.randf_range(-0.18, 0.18))
		parts.append([_sphere(rng.randf_range(0.17, 0.24), 0.06, 8, 3), Transform3D(Basis(), p), DUNG.lightened(rng.randf_range(0.0, 0.12))])
	return merge(parts)


## Ot yığını (ve saman, yün, kil): yarım küre, alt kenarı koyu.
static func heap(color: Color, squash := 1.0) -> ArrayMesh:
	return merge([[_sphere(0.85, 1.1 * squash, 10, 6), Transform3D(Basis(), Vector3(0, 0.15 * squash, 0)), color],
		[_sphere(0.95, 0.25, 10, 3), Transform3D(Basis(), Vector3(0, 0.05, 0)), color.darkened(0.25)]])


static func boulder(seed := 1) -> ArrayMesh:
	return merge([[MeshKit.rock(820 + seed, 2), Transform3D(Basis().scaled(Vector3(1.15, 1.0, 1.05)), Vector3.ZERO), STONE]])


## Damar: kaya ve yüzünde altı cevher yumrusu (demir pası, bakır yeşili).
static func vein(seed := 1, ore := IRON) -> ArrayMesh:
	var parts: Array = [[MeshKit.rock(840 + seed, 2), Transform3D(Basis().scaled(Vector3(1.1, 1.0, 1.0)), Vector3.ZERO), STONE_DARK]]
	var rng := RandomNumberGenerator.new()
	rng.seed = 850 + seed
	for k in 6:
		var a := rng.randf_range(0.0, TAU)
		var p := Vector3(cos(a) * 0.55, rng.randf_range(0.35, 0.75), sin(a) * 0.5)
		parts.append([_sphere(0.16, 0.12, 6, 3), Transform3D(Basis(), p), ore])
	return merge(parts)


static func scree(seed := 1) -> ArrayMesh:
	var parts: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = 870 + seed
	for k in 4:
		var s := rng.randf_range(0.35, 0.55)
		parts.append([MeshKit.rock(880 + seed * 7 + k, 1), Transform3D(Basis().scaled(Vector3.ONE * s), Vector3(rng.randf_range(-0.4, 0.4), 0.0, rng.randf_range(-0.4, 0.4))), STONE])
	return merge(parts)


## Odunluk kütüğü: kalın kütük, üstünde saplı balta (site_axe; kalkmaz).
static func chopping_block() -> ArrayMesh:
	var parts: Array = [[_cyl(0.32, 0.36, 0.55, 10), Transform3D(Basis(), Vector3(0, 0.275, 0)), BARK],
		[_cyl(0.3, 0.3, 0.02, 10), Transform3D(Basis(), Vector3(0, 0.56, 0)), CUT]]
	var handle := Transform3D(Basis(Vector3(0, 0, 1), deg_to_rad(-62.0)), Vector3(0.22, 0.78, 0.0))
	parts.append([_cyl(0.022, 0.022, 0.62, 5), handle, WOOD])
	parts.append([_box(Vector3(0.05, 0.16, 0.12)), Transform3D(Basis(), Vector3(-0.02, 0.6, 0.0)), METAL])
	for k in 3:
		parts.append([_cyl(0.1, 0.1, 0.5, 6), Transform3D(Basis(Vector3(1, 0, 0), PI * 0.5) * Basis(Vector3(0, 0, 1), 0.0), Vector3(-0.55 + k * 0.21, 0.1, 0.45)), CUT.darkened(0.15)])
	return merge(parts)


static func bush(seed := 1, berry := Color("#b8322a"), leaf := Color("#55603e")) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 950 + seed
	var parts: Array = []
	for k in 3:
		parts.append([_sphere(0.45, 0.55, 7, 4), Transform3D(Basis(), Vector3(rng.randf_range(-0.25, 0.25), 0.5, rng.randf_range(-0.25, 0.25))), leaf])
	for k in 8:
		var a := rng.randf_range(0.0, TAU)
		parts.append([_sphere(0.06, 0.06, 5, 3), Transform3D(Basis(), Vector3(cos(a) * 0.5, rng.randf_range(0.4, 0.95), sin(a) * 0.5)), berry])
	return merge(parts)


## Devrilen ağacın kütüğü.
static func stump() -> ArrayMesh:
	return merge([[_cyl(0.26, 0.3, 0.42, 9), Transform3D(Basis(), Vector3(0, 0.21, 0)), BARK],
		[_cyl(0.25, 0.25, 0.02, 9), Transform3D(Basis(), Vector3(0, 0.43, 0)), CUT]])


## Elde taşınan araç: sapın tutulan ucu orijinde, sap +Y boyunca, baş sapın ucunda; balta başı +X'e keser, kazma çift uçlu. Uzak kadrajda
## (K98, 28 m) okunsun diye gerçeğin biraz üstündedir (sap 0,95 m) ve başı açık tunç rengidir.
const TOOL_HEAD := Color("#c9a25a")


static func tool_mesh(kind: String) -> ArrayMesh:
	var parts: Array = [[_cyl(0.026, 0.03, 0.95, 6), Transform3D(Basis(), Vector3(0, 0.475, 0)), Color("#8a5a32")]]
	match kind:
		"pick":
			parts.append([_box(Vector3(0.62, 0.075, 0.075)), Transform3D(Basis(Vector3(0, 0, 1), 0.12), Vector3(0.0, 0.92, 0.0)), TOOL_HEAD])
		_:
			parts.append([_box(Vector3(0.26, 0.19, 0.05)), Transform3D(Basis(), Vector3(0.11, 0.87, 0.0)), TOOL_HEAD])
			parts.append([_box(Vector3(0.035, 0.22, 0.055)), Transform3D(Basis(), Vector3(0.25, 0.87, 0.0)), TOOL_HEAD.lightened(0.35)])
	return merge(parts)


# --- Yardımcılar -------------------------------------------------------------------------------------------------------------

## Parçaları tek ağda birleştirir: [[Mesh, Transform3D, renk (sRGB)], …]; renk köşe rengine (doğrusal) yazılır.
static func merge(parts: Array) -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for part: Array in parts:
		var mesh: Mesh = part[0]
		var xf: Transform3D = part[1]
		var col: Color = (part[2] as Color).srgb_to_linear()
		var nb := xf.basis.inverse().transposed()
		for s in mesh.get_surface_count():
			var arrays := mesh.surface_get_arrays(s)
			var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var n: Variant = arrays[Mesh.ARRAY_NORMAL]
			var idx: Variant = arrays[Mesh.ARRAY_INDEX]
			var base := verts.size()
			for k in v.size():
				verts.append(xf * v[k])
				normals.append((nb * ((n as PackedVector3Array)[k] if n is PackedVector3Array and (n as PackedVector3Array).size() > k else Vector3.UP)).normalized())
				colors.append(col)
			if idx is PackedInt32Array and not (idx as PackedInt32Array).is_empty():
				for i: int in idx:
					indices.append(base + i)
			else:
				for i in v.size():
					indices.append(base + i)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


## Ağın sRGB köşe renklerini doğrusala çevirir (TreeKit sRGB yazar), boyu ölçekler.
static func _linear(mesh: ArrayMesh, height_k := 1.0) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	for i in colors.size():
		var c := colors[i]
		colors[i] = Color(c.r, c.g, c.b, 1.0).srgb_to_linear()
	arrays[Mesh.ARRAY_COLOR] = colors
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in verts.size():
		verts[i] *= height_k
	arrays[Mesh.ARRAY_VERTEX] = verts
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


static func _cyl(r_bottom: float, r_top: float, h: float, seg: int) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.bottom_radius = r_bottom
	m.top_radius = r_top
	m.height = h
	m.radial_segments = seg
	m.rings = 1
	return m


static func _sphere(r: float, h: float, seg: int, rings: int) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = h
	m.radial_segments = seg
	m.rings = rings
	return m


static func _box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m
