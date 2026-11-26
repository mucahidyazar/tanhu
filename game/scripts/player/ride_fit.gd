class_name RideFit
extends RefCounted
## Binicinin bineğe oturuşunun ölçüsü (geliştirme aracı ve sınamalar; K58 M6, M9, M10, mete-model-checks): işlemcide (CPU) deri giydirilen
## köşelerle binicinin pelerin köşelerinin ve bacağının at gövdesine girişi. Pencere ya da ekran kartı gerekmez (başsız çalışır).
##
## Pelerin köşesi (sanat-animasyon.md öneri 12 ve bulgu 8: «kalça altı arka pelerin köşeleri»): boya maskesinde pelerin olan (<id>_dye.png R ≥
## DYE_CUT), dinlenmede kalçanın altında (y < CORNER_MAX_Y) ve gövdenin orta düzleminin arkasında (z < CORNER_MAX_Z) kalan köşe: Mete'de 11.782
## köşe (modelin kendi ağırlığının %93,9'u bacaklarda: uyluk, baldır, ayak; test_mete_model.gd). Prototipin z < 0,09'u kendi modelinin ekseniyle
## yazılmıştı; Godot'da Mete'nin orta düzlemi z = 0'dır, 0 ile 0,09 arası bacakların önündeki etek kanadıdır (pelerin değil; sürüşte üç köşesi
## eyerin önüne 6 cm girer, 2026-11-08 ölçüsü).
## Bineğin gövdesi, iskeletli ağın o anki pozudur: yalnız istenen kutunun içindeki üçgenler kurulur (sağrı ve sırt), her nokta için en yakın
## üçgen ızgarada aranır; nokta üçgenin iç yüzündeyse giriş, derinliği üçgene uzaklığıdır.
##   var corners := RideFit.cape_corners(mesh, dye_image)
##   var points := RideFit.skinned_points(rider_mi, corners)          # dünya uzayı
##   var body := RideFit.Surface.from_mesh(horse_mi, box)             # dünya uzayında kutu
##   var report := RideFit.penetration(points, body)                  # {share, max_depth, inside, count}

## Pelerin köşesinin sınırları (metre, modelin dinlenme uzayı) ve boya maskesinin eşiği.
const CORNER_MAX_Y := 1.0
const CORNER_MAX_Z := 0.0
const DYE_CUT := 0.5
## Gövde ızgarasının hücresi (metre) ve en yakın üçgenin arandığı en geniş halka (hücre; 0,08 × 8 = 0,64 m: gövdenin yarı genişliğinden büyük).
const CELL := 0.08
const MAX_RING := 8


## Boya maskesinde pelerin olan ve dinlenmede kalçanın altında, arkada kalan köşelerin sırası (yüzeyin köşe dizisinde).
static func cape_corners(mesh: Mesh, dye: Image, surface := 0, max_y := CORNER_MAX_Y, max_z := CORNER_MAX_Z) -> PackedInt32Array:
	var out := PackedInt32Array()
	if mesh == null or dye == null:
		return out
	var arrays := mesh.surface_get_arrays(surface)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var w := dye.get_width()
	var h := dye.get_height()
	for v in verts.size():
		var p := verts[v]
		if p.y >= max_y or p.z >= max_z:
			continue
		var uv := uvs[v]
		if dye.get_pixel(clampi(int(uv.x * w), 0, w - 1), clampi(int(uv.y * h), 0, h - 1)).r >= DYE_CUT:
			out.append(v)
	return out


## Boya maskesinde bir kanalı DYE_CUT'u geçen köşeler (kanal 0 R, 1 G, 2 B).
static func dyed_vertices(mesh: Mesh, dye: Image, channel := 0, surface := 0) -> PackedInt32Array:
	var out := PackedInt32Array()
	var arrays := mesh.surface_get_arrays(surface)
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var w := dye.get_width()
	var h := dye.get_height()
	for v in uvs.size():
		var c := dye.get_pixel(clampi(int(uvs[v].x * w), 0, w - 1), clampi(int(uvs[v].y * h), 0, h - 1))
		if c[channel] >= DYE_CUT:
			out.append(v)
	return out


## Deri bağlarının dünya matrisleri (iskeletin o anki pozu; Skeleton3D.get_bone_global_pose: değiştiricilerden önceki poz). overrides: kemik →
## iskelet uzayında poz (değiştiricinin çıktısı: RideCape.solve_now, RideableHooves); verilen kemiğin çocukları da ona göre taşınır.
static func skin_matrices(mi: MeshInstance3D, overrides: Dictionary = {}) -> Array[Transform3D]:
	var mats: Array[Transform3D] = []
	var skel := mi.get_node_or_null(mi.skeleton) as Skeleton3D if mi.skin else null
	if skel == null:
		return mats
	var at := skel.global_transform
	var poses := RideFit.global_poses(skel, overrides)
	for i in mi.skin.get_bind_count():
		var bone := mi.skin.get_bind_bone(i)
		if bone < 0:
			bone = skel.find_bone(mi.skin.get_bind_name(i))
		var pose: Transform3D = poses[bone] if bone >= 0 else Transform3D.IDENTITY
		mats.append(at * pose * mi.skin.get_bind_pose(i))
	return mats


## Kemiklerin iskelet uzayındaki pozu: klibin pozu, verilen kemikte overrides'ınki (çocukları yerel pozlarıyla onu izler).
static func global_poses(skel: Skeleton3D, overrides: Dictionary = {}) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	out.resize(skel.get_bone_count())
	if overrides.is_empty():
		for b in skel.get_bone_count():
			out[b] = skel.get_bone_global_pose(b)
		return out
	var done := PackedByteArray()
	done.resize(skel.get_bone_count())
	for b in skel.get_bone_count():
		RideFit._pose_of(skel, b, overrides, out, done)
	return out


static func _pose_of(skel: Skeleton3D, bone: int, overrides: Dictionary, out: Array[Transform3D], done: PackedByteArray) -> Transform3D:
	if done[bone] == 1:
		return out[bone]
	var pose: Transform3D
	if overrides.has(bone):
		pose = overrides[bone]
	else:
		var parent := skel.get_bone_parent(bone)
		pose = (RideFit._pose_of(skel, parent, overrides, out, done) * skel.get_bone_pose(bone)) if parent >= 0 else skel.get_bone_global_pose(bone)
	out[bone] = pose
	done[bone] = 1
	return pose


## Seçilen köşelerin (boşsa hepsinin) dünya konumları, iskeletin o anki pozuyla deri giydirilmiş (overrides: skin_matrices).
static func skinned_points(mi: MeshInstance3D, indices: PackedInt32Array = PackedInt32Array(), surface := 0, overrides: Dictionary = {}) -> PackedVector3Array:
	var arrays := mi.mesh.surface_get_arrays(surface)
	return skin_arrays(arrays, skin_matrices(mi, overrides), indices, mi.global_transform)


## Yüzey dizilerinden deri giydirme (saf; matrisler skin_matrices). İskeletsiz ağda rest dönüşümü (rest) uygulanır.
static func skin_arrays(arrays: Array, mats: Array[Transform3D], indices: PackedInt32Array, rest: Transform3D) -> PackedVector3Array:
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var out := PackedVector3Array()
	var all := indices.is_empty()
	var count := verts.size() if all else indices.size()
	out.resize(count)
	if mats.is_empty() or arrays[Mesh.ARRAY_BONES] == null:
		for i in count:
			out[i] = rest * verts[i if all else indices[i]]
		return out
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var stride := bones.size() / maxi(verts.size(), 1)
	for i in count:
		var v := i if all else indices[i]
		var base := v * stride
		var p := Vector3.ZERO
		for k in stride:
			var wt := weights[base + k]
			if wt > 0.0:
				p += (mats[bones[base + k]] * verts[v]) * wt
		out[i] = p
	return out


## Noktaların gövdeye girişi: {count, inside (giren nokta), share (oran), max_depth (m), depths (girenlerin derinliği)}.
static func penetration(points: PackedVector3Array, body: Surface, margin := 0.0) -> Dictionary:
	var inside := 0
	var deepest := 0.0
	var depths := PackedFloat32Array()
	for p in points:
		var d := body.depth(p)
		if d > margin:
			inside += 1
			deepest = maxf(deepest, d)
			depths.append(d)
	return {"count": points.size(), "inside": inside, "share": float(inside) / maxf(points.size(), 1.0), "max_depth": deepest, "depths": depths}


## Bineğin gövdesinin (iskeletli ağ, o anki poz) üçgenleri, dünya uzayında, ızgarada: en yakın üçgen ve içte mi.
class Surface:
	extends RefCounted
	var a := PackedVector3Array()
	var b := PackedVector3Array()
	var c := PackedVector3Array()
	var n := PackedVector3Array()
	var grid := {}
	var cell := CELL
	## Dış yön (b − a) × (c − a)'nın tersi mi?
	var flip := true
	## Gövdenin ortası (yan ışının yönü) ve ışının en çok yürüdüğü hücre.
	var center := Vector3.ZERO
	var max_steps := 40

	## Ağın kutudaki üçgenleri (dünya uzayı; kutu boşsa hepsi). Dış yön köşe normallerinin çoğunluğundan seçilir (Godot'nun ön yüzü saat
	## yönündedir: (b − a) × (c − a) içe bakar; içe aktarılan her ağ böyledir ama sınama bunu varsaymaz).
	static func from_mesh(mi: MeshInstance3D, box: AABB = AABB(), surface := 0) -> Surface:
		var s := Surface.new()
		var arrays := mi.mesh.surface_get_arrays(surface)
		var points := RideFit.skin_arrays(arrays, RideFit.skin_matrices(mi), PackedInt32Array(), mi.global_transform)
		var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		s.flip = Surface.winding_flip(arrays)
		var use_box := box.size != Vector3.ZERO
		s.center = mi.global_position
		s.max_steps = int(ceil((box.size.length() if use_box else 6.0) / s.cell)) + 2
		for t in range(0, index.size(), 3):
			var pa := points[index[t]]
			var pb := points[index[t + 1]]
			var pc := points[index[t + 2]]
			if use_box and not (box.has_point(pa) or box.has_point(pb) or box.has_point(pc)):
				continue
			s.add(pa, pb, pc)
		return s

	## Üçgenin (b − a) × (c − a) yönü köşe normallerinin tersine mi (çoğunluk; saf)?
	static func winding_flip(arrays: Array) -> bool:
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: Variant = arrays[Mesh.ARRAY_NORMAL]
		var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		if not normals is PackedVector3Array or (normals as PackedVector3Array).is_empty():
			return true
		var nn: PackedVector3Array = normals
		var vote := 0
		var step := maxi(3, (index.size() / 3 / 2000) * 3)
		for t in range(0, index.size() - 2, step):
			var fn := (verts[index[t + 1]] - verts[index[t]]).cross(verts[index[t + 2]] - verts[index[t]])
			vote += 1 if fn.dot(nn[index[t]] + nn[index[t + 1]] + nn[index[t + 2]]) < 0.0 else -1
		return vote > 0

	func add(pa: Vector3, pb: Vector3, pc: Vector3) -> void:
		var normal := (pb - pa).cross(pc - pa) * (-1.0 if flip else 1.0)
		if normal.length_squared() < 1e-14:
			return
		var id := a.size()
		a.append(pa)
		b.append(pb)
		c.append(pc)
		n.append(normal.normalized())
		var lo := pa.min(pb).min(pc)
		var hi := pa.max(pb).max(pc)
		var i0 := Vector3i((lo / cell).floor())
		var i1 := Vector3i((hi / cell).floor())
		for x in range(i0.x, i1.x + 1):
			for y in range(i0.y, i1.y + 1):
				for z in range(i0.z, i1.z + 1):
					var key := Vector3i(x, y, z)
					if not grid.has(key):
						grid[key] = PackedInt32Array()
					var list: PackedInt32Array = grid[key]
					list.append(id)
					grid[key] = list

	func size() -> int:
		return a.size()

	## Noktanın gövdeye girişi (m): en yakın üçgenin iç yüzündeyse uzaklık, dışındaysa eksi uzaklık; MAX_RING içinde üçgen yoksa -INF.
	## Arama halka halka genişler: bulunan en yakın uzaklık taranan halkanın içinde kalınca durur (daha uzak hücrede daha yakın üçgen olamaz).
	func depth(p: Vector3) -> float:
		var key := Vector3i((p / cell).floor())
		var best := INF
		var sign := -1.0
		var seen := {}
		for ring in RideFit.MAX_RING + 1:
			for x in range(key.x - ring, key.x + ring + 1):
				for y in range(key.y - ring, key.y + ring + 1):
					for z in range(key.z - ring, key.z + ring + 1):
						if maxi(maxi(absi(x - key.x), absi(y - key.y)), absi(z - key.z)) != ring:
							continue
						var list: Variant = grid.get(Vector3i(x, y, z))
						if list == null:
							continue
						for t: int in list:
							if seen.has(t):
								continue
							seen[t] = true
							var q := RideFit.closest_on_triangle(p, a[t], b[t], c[t])
							var d := p.distance_to(q)
							if d < best - 1e-7:
								best = d
								sign = 1.0 if (p - q).dot(n[t]) < 0.0 else -1.0
			if best <= float(ring) * cell:
				break
		if best == INF:
			return -INF
		# En yakın üçgenin yüzü ince parçada (eyer örtüsünün kanadı, püskül, kayış) yanıltır: «içte» denen nokta üç ışının tek-çift sayısıyla
		# doğrulanır (yukarı, yanda gövdenin dışına doğru, geriye); ikisi tek değilse içte değildir.
		if sign > 0.0 and not inside(p):
			sign = -1.0
		return best * sign

	## Kapalı yüzeyin içinde mi (üç ışının çoğunluğu tek sayıda üçgen keser)?
	func inside(p: Vector3) -> bool:
		var odd := 0
		var side := Vector3.RIGHT if p.x - center.x >= 0.0 else Vector3.LEFT
		for dir: Vector3 in [Vector3.UP, side, Vector3.BACK]:
			if _crossings(p, dir) % 2 == 1:
				odd += 1
		return odd >= 2

	## Işının (p'den dir yönünde, kutunun sonuna dek) kestiği üçgen sayısı: ızgarada hücre hücre yürünür (her üçgen bir kez).
	func _crossings(p: Vector3, dir: Vector3) -> int:
		var seen := {}
		var count := 0
		var key := Vector3i((p / cell).floor())
		var step := Vector3i(int(signf(dir.x)), int(signf(dir.y)), int(signf(dir.z)))
		for i in max_steps:
			var list: Variant = grid.get(key)
			if list != null:
				for t: int in list:
					if seen.has(t):
						continue
					seen[t] = true
					if Geometry3D.ray_intersects_triangle(p, dir, a[t], b[t], c[t]) != null:
						count += 1
			key += step
		return count


## Noktaya üçgenin en yakın noktası (Ericson, Real-Time Collision Detection §5.1.5).
static func closest_on_triangle(p: Vector3, a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var ab := b - a
	var ac := c - a
	var ap := p - a
	var d1 := ab.dot(ap)
	var d2 := ac.dot(ap)
	if d1 <= 0.0 and d2 <= 0.0:
		return a
	var bp := p - b
	var d3 := ab.dot(bp)
	var d4 := ac.dot(bp)
	if d3 >= 0.0 and d4 <= d3:
		return b
	var vc := d1 * d4 - d3 * d2
	if vc <= 0.0 and d1 >= 0.0 and d3 <= 0.0:
		return a + ab * (d1 / (d1 - d3))
	var cp := p - c
	var d5 := ab.dot(cp)
	var d6 := ac.dot(cp)
	if d6 >= 0.0 and d5 <= d6:
		return c
	var vb := d5 * d2 - d1 * d6
	if vb <= 0.0 and d2 >= 0.0 and d6 <= 0.0:
		return a + ac * (d2 / (d2 - d6))
	var va := d3 * d6 - d5 * d4
	if va <= 0.0 and (d4 - d3) >= 0.0 and (d5 - d6) >= 0.0:
		return b + (c - b) * ((d4 - d3) / ((d4 - d3) + (d5 - d6)))
	var denom := 1.0 / (va + vb + vc)
	var v := vb * denom
	var w := vc * denom
	return a + ab * v + ac * w


## Bineğin sırtının yükseklik alanı (RideCape'in serilişi; Rideable.back_clearance): iskeletli ağın dinlenme pozundaki köşelerinden, bir gövde
## kemiğinin (atta Hips: sağrı ve eyerin arkası) dinlenme çerçevesinde x–z ızgarası, hücre başına en yüksek köşe. Sorguda nokta kemiğin
## bugünkü pozuyla dinlenmeye taşınır (sağrı kemikle rijit döner), komşu dokuz hücrenin en yükseğine göre farkı döner: sırtın üstündeyse artı.
## Ağ başına bir kez kurulur (paylaşılır).
class BackField:
	extends RefCounted
	const CELL := 0.025
	const X_RANGE := Vector2(-0.6, 0.6)
	const Z_RANGE := Vector2(-1.0, 1.0)
	static var _cache := {}
	var bone := -1
	var rest := Transform3D.IDENTITY
	var nx := 0
	var nz := 0
	var top := PackedFloat32Array()

	## Ağın alanı (önbellekte varsa o). bone_name: çerçevenin kemiği; members: alana giren üçgenlerin baskın kemik adı süzgeci (Callable(ad) ->
	## bool; boşsa hepsi).
	static func of(mi: MeshInstance3D, skel: Skeleton3D, bone_name := "Hips", members := Callable(), tag := "") -> BackField:
		var key := "%d:%s:%s" % [mi.mesh.get_instance_id(), bone_name, tag]
		if _cache.has(key):
			return _cache[key]
		var field := BackField.new()
		field._build(mi, skel, bone_name, members)
		_cache[key] = field
		return field

	## Dört ayaklının gövde alanları (quadruped_rig.py kemikleri): gövde (bacaklar dışı, Hips çerçevesinde) ve iki arka bacak (uyluk çerçevesinde;
	## dörtnalda geriye açılan uyluk sağrının dinlenme alanında yoktur).
	static func quadruped(mi: MeshInstance3D, skel: Skeleton3D) -> Array:
		var out := []
		out.append(BackField.of(mi, skel, "Hips", func(n: String) -> bool: return not (n.begins_with("Front") or n.begins_with("Hind")), "body"))
		for side in ["L", "R"]:
			if skel.find_bone("HindUpper" + side) >= 0:
				out.append(BackField.of(mi, skel, "HindUpper" + side, func(n: String) -> bool: return n.begins_with("Hind") and n.ends_with(side), "hind" + side))
		return out

	func _build(mi: MeshInstance3D, skel: Skeleton3D, bone_name: String, members := Callable()) -> void:
		bone = skel.find_bone(bone_name)
		if bone < 0:
			return
		rest = skel.get_bone_global_rest(bone)
		# Ağ uzayından iskeletin dinlenme uzayına: bir bağın dinlenme dönüşümü (hepsi aynıdır).
		var to_skel := Transform3D.IDENTITY
		if mi.skin and mi.skin.get_bind_count() > 0:
			var b := mi.skin.get_bind_bone(0)
			if b < 0:
				b = skel.find_bone(mi.skin.get_bind_name(0))
			to_skel = skel.get_bone_global_rest(b) * mi.skin.get_bind_pose(0)
		nx = int(ceil((X_RANGE.y - X_RANGE.x) / CELL))
		nz = int(ceil((Z_RANGE.y - Z_RANGE.x) / CELL))
		top.resize(nx * nz)
		top.fill(-INF)
		# Üçgenler hücreden sık örneklenir (köşeler seyrek olabilir: sağrının ortasında köşe aralığı hücreden büyüktür).
		var arrays := mi.mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var q := PackedVector3Array()
		q.resize(verts.size())
		for v in verts.size():
			q[v] = to_skel * verts[v] - rest.origin
		# Köşenin baskın kemiği süzgeçten geçiyor mu (üçgen, köşelerinden biri geçince alana girer).
		var keep := PackedByteArray()
		keep.resize(verts.size())
		keep.fill(1)
		if members.is_valid() and mi.skin and arrays[Mesh.ARRAY_BONES] != null:
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var stride := bones.size() / maxi(verts.size(), 1)
			var names := PackedStringArray()
			for i in mi.skin.get_bind_count():
				var bb := mi.skin.get_bind_bone(i)
				names.append(skel.get_bone_name(bb) if bb >= 0 else String(mi.skin.get_bind_name(i)))
			for v in verts.size():
				var dom := 0
				for k in range(1, stride):
					if weights[v * stride + k] > weights[v * stride + dom]:
						dom = k
				keep[v] = 1 if bool(members.call(names[bones[v * stride + dom]])) else 0
		for t in range(0, index.size(), 3):
			if keep[index[t]] == 0 and keep[index[t + 1]] == 0 and keep[index[t + 2]] == 0:
				continue
			var a := q[index[t]]
			var b := q[index[t + 1]]
			var c := q[index[t + 2]]
			var lo := a.min(b).min(c)
			var hi := a.max(b).max(c)
			if hi.x < X_RANGE.x or lo.x > X_RANGE.y or hi.z < Z_RANGE.x or lo.z > Z_RANGE.y:
				continue
			var span := maxf(maxf(a.distance_to(b), b.distance_to(c)), c.distance_to(a))
			var n := maxi(1, int(ceil(span / (CELL * 0.7))))
			for i in n + 1:
				for j in n + 1 - i:
					_mark(a + (b - a) * (float(i) / n) + (c - a) * (float(j) / n))

	func _mark(p: Vector3) -> void:
		var ix := int(floor((p.x - X_RANGE.x) / CELL))
		var iz := int(floor((p.z - Z_RANGE.x) / CELL))
		if ix < 0 or iz < 0 or ix >= nx or iz >= nz:
			return
		var i := iz * nx + ix
		if p.y > top[i]:
			top[i] = p.y

	## Noktanın sırtın üstündeki yüksekliği (iskeletin biriminde × dünya ölçeği = metre): artı üstte, eksi içeride; alanın dışında ya da altında gövde
	## yoksa INF.
	func clearance(skel: Skeleton3D, p_world: Vector3) -> float:
		if bone < 0 or top.is_empty():
			return INF
		var xf := skel.global_transform
		var s := xf.affine_inverse() * p_world
		var moved := skel.get_bone_global_pose(bone) * rest.affine_inverse()
		var q := moved.affine_inverse() * s - rest.origin
		var ix := int(floor((q.x - X_RANGE.x) / CELL))
		var iz := int(floor((q.z - Z_RANGE.x) / CELL))
		var best := -INF
		for dz: int in [-1, 0, 1]:
			for dx: int in [-1, 0, 1]:
				var x: int = ix + dx
				var z: int = iz + dz
				if x < 0 or z < 0 or x >= nx or z >= nz:
					continue
				best = maxf(best, top[z * nx + x])
		if best == -INF:
			return INF
		return (q.y - best) * xf.basis.get_scale().y


## Binicinin diz ve kaval köşeleri (M10, sanat-animasyon.md öneri 12: «diz ve kaval, at örtüsü, giriş ≤1 cm»): baskın kemiği baldır (Leg) olan ya da
## diz ekleminin KNEE_RADIUS içindeki uyluk köşeleri; giysinin boyalı kumaşı (boya maskesinin pelerin, levha, gömlek kanalları; dye2 kuşak ve
## şeritler) sayılmaz: kumaş RideCape ve M6'nındır, bu küme bacağın kendisidir (pantolon, çizme).
const KNEE_RADIUS := 0.12


static func leg_vertices(mi: MeshInstance3D, dye: Image, surface := 0, dye2: Image = null) -> PackedInt32Array:
	var out := PackedInt32Array()
	var skel := mi.get_node_or_null(mi.skeleton) as Skeleton3D if mi.skin else null
	if skel == null:
		return out
	var arrays := mi.mesh.surface_get_arrays(surface)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var stride := bones.size() / maxi(verts.size(), 1)
	# Bağ → 1 baldır, 2 uyluk; dizlerin dinlenme yeri (ağ uzayı).
	var kind := PackedByteArray()
	kind.resize(mi.skin.get_bind_count())
	var knees: Array[Vector3] = []
	for i in mi.skin.get_bind_count():
		var b := mi.skin.get_bind_bone(i)
		var n := skel.get_bone_name(b) if b >= 0 else String(mi.skin.get_bind_name(i))
		kind[i] = 1 if n in ["LeftLeg", "RightLeg"] else (2 if n in ["LeftUpLeg", "RightUpLeg"] else 0)
		if n in ["LeftLeg", "RightLeg"]:
			knees.append(mi.skin.get_bind_pose(i).affine_inverse().origin)
	var w := dye.get_width()
	var h := dye.get_height()
	for v in verts.size():
		var dom := 0
		for k in range(1, stride):
			if weights[v * stride + k] > weights[v * stride + dom]:
				dom = k
		var kd := kind[bones[v * stride + dom]]
		if kd == 0:
			continue
		var p := verts[v]
		if kd == 2:
			var near := false
			for knee in knees:
				if p.distance_to(knee) <= KNEE_RADIUS:
					near = true
			if not near:
				continue
		var px := clampi(int(uvs[v].x * w), 0, w - 1)
		var py := clampi(int(uvs[v].y * h), 0, h - 1)
		var c := dye.get_pixel(px, py)
		if c.r >= DYE_CUT or c.g >= DYE_CUT or c.b >= DYE_CUT:
			continue
		if dye2 and dye2.get_pixel(clampi(int(uvs[v].x * dye2.get_width()), 0, dye2.get_width() - 1), clampi(int(uvs[v].y * dye2.get_height()), 0, dye2.get_height() - 1)).r >= DYE_CUT:
			continue
		out.append(v)
	return out
