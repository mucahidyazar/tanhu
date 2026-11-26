extends TestCase
## Mete'nin modeli (K58, sanat-animasyon.md öneri 12; Yol Haritası mete-model-checks): M1 (tek ağ, tek yüzey, çizgi geçişi ve gölge, üçgen
## bütçesi), M4 (kılık maskeleri kendi giysisinde: tene, saça, göze ve birbirine taşmaz), pelerin köşelerinin kalçaya bağlanması (RideCape), M5
## (yürüyüşte ve koşuda kalça altı arka pelerin bacak arasından ayrılmaz), M11 (ayak kayması ≤6 cm; K98'in 28 m'lik kamerası), M12 (taban ile
## zemin arası ≤2 cm). Sürüşün satırları (M6–M10) test_mete_riding.gd'de, M18 test_cape_dye.gd'dedir. Ölçü RideFit'tir: köşeler işlemcide
## deri giydirilir (pelerin kemiklerinin pozu RideCape.solve_now'dan). Gerçek model: assets/characters/mete.

const DT := 1.0 / 60.0
const MODEL := "res://assets/characters/mete/mete.glb"
const DYE := "res://assets/characters/mete/mete_dye.png"
const DYE2 := "res://assets/characters/mete/mete_dye2.png"
const REGIONS := "res://assets/characters/mete/mete_regions.png"
## M1: üçgen bütçesi (prototipin «60,6k × 3, 3 çizim»i; Godot'da tek yüzey: boyalı geçiş, çizgi geçişi ve gölge).
const M1_TRIANGLES := 65000
## M4: bir giysinin maskesinin tene, saça, göze ya da başka giysiye düşen en büyük payı (dokunun örneklenen pikselleri).
const M4_SPILL := 0.01
## M5: bacak arasında örtünün en çok açılması (m; kenarın duruştakinden uzaması: bacak arasında ayrılan örtünün yarığı). Ölçüt M11'in görünürlük
## eşiğidir: K98'in 28 m'lik kamerasında (36°, 1080 piksel) 6 cm ≈ 3,6 piksel.
const M5_GAP := 0.06
## M5: bacak arası (m; kalça eklemlerinin arası, modelin dinlenme uzayında |x|).
const M5_BETWEEN := 0.1
## M11: basan ayağın (LeftToeBase, RightToeBase) yerde kayması (m) ve basmanın sayıldığı yükseklik bandı (m; ayağın en alçak yerinin üstü).
const M11_SLIDE := 0.06
const M11_BAND := 0.02
## M12: tabanla zemin arası (m; batma da kalkma da).
const M12_GAP := 0.02
## M12: koşunun bir adımı (sn; havadaki anı içine alan pencere).
const M12_STEP := 0.35
const THIGHS: Array[String] = ["LeftUpLeg", "RightUpLeg", "LeftLeg", "RightLeg", "LeftFoot", "RightFoot", "LeftToeBase", "RightToeBase"]
const FEET: Array[String] = ["LeftFoot", "LeftToeBase", "RightFoot", "RightToeBase"]


class FlatShape:
	extends TerrainShape

	func height_at(_x: float, _z: float) -> float:
		return 0.0


var _trash: Array[Node] = []
var _player: PlayerController
var _avatar: CharacterAvatar
var _anim: AnimationPlayer
var _cape: RideCape


func after_each() -> void:
	for node in _trash:
		if is_instance_valid(node):
			node.queue_free()
	_trash.clear()


func test_m1_one_skinned_surface_with_outline_and_shadow() -> void:
	await _setup()
	var shown: Array[MeshInstance3D] = []
	for node in _avatar.find_children("*", "MeshInstance3D", true, false):
		if (node as MeshInstance3D).is_visible_in_tree():
			shown.append(node)
	assert_eq(shown.size(), 1, "Mete tek ağdır")
	var mi := shown[0]
	assert_eq(mi.mesh.get_surface_count(), 1, "Tek yüzey: bir çizim")
	var triangles := _triangles(mi.mesh)
	assert_true(triangles <= M1_TRIANGLES, "M1: %d üçgen (≤%d)" % [triangles, M1_TRIANGLES])
	assert_eq(mi.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_ON, "Gölge düşürür (bir gölge çizimi)")
	assert_not_null(mi.skin, "Deri giydirilir")
	var mat := mi.get_active_material(0) as ShaderMaterial
	assert_not_null(mat, "Boyalı gölgelendirici")
	var passes := 1 + (1 if mat and mat.next_pass else 0)
	assert_eq(passes, 2, "Boyalı geçiş ve çizgi geçişi")
	# Pelerin iskeleti ağı yeniden kurar: üçgen, köşe ve yüzey sayısı modelinkiyle aynı.
	var original := (load(MODEL) as PackedScene).instantiate() as Node3D
	var omi: MeshInstance3D = original.find_children("*", "MeshInstance3D", true, false)[0]
	assert_eq(_triangles(omi.mesh), triangles, "Pelerin iskeleti üçgen eklemez")
	assert_eq(omi.mesh.get_surface_count(), mi.mesh.get_surface_count())
	original.free()
	print("    M1: %d üçgen, %d yüzey, %d geçiş + 1 gölge = %d çizim" % [triangles, mi.mesh.get_surface_count(), passes, passes + 1])


func test_m4_garment_masks_stay_on_their_garments() -> void:
	var dye := _image(DYE)
	var dye2 := _image(DYE2)
	var regions := _image(REGIONS)
	# Ağın üçgenleri (ağırlık merkezinin dokudaki yeri; adaların arasındaki boşluk ve kenarın yumuşak pikselleri sayılmaz): dört giysi (pelerin
	# dye R, levha G, gömlek B; kuşak, önlük ve şeritler dye2 R) tene, saça, göze ve birbirine taşmaz.
	var original := (load(MODEL) as PackedScene).instantiate() as Node3D
	var omi: MeshInstance3D = original.find_children("*", "MeshInstance3D", true, false)[0]
	var arrays := omi.mesh.surface_get_arrays(0)
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	original.free()
	var names: Array[String] = ["pelerin", "levha", "gömlek", "kuşak"]
	var counts := [0, 0, 0, 0]
	var on_body := [0, 0, 0, 0]
	var overlap := {}
	for t in range(0, index.size(), 3):
		var uv := (uvs[index[t]] + uvs[index[t + 1]] + uvs[index[t + 2]]) / 3.0
		var c := _sample(dye, uv)
		var hit: Array[bool] = [c.r >= RideFit.DYE_CUT, c.g >= RideFit.DYE_CUT, c.b >= RideFit.DYE_CUT, _sample(dye2, uv).r >= RideFit.DYE_CUT]
		var r := _sample(regions, uv)
		var body := maxf(r.r, maxf(r.g, r.b)) > 0.5
		for g in 4:
			if not hit[g]:
				continue
			counts[g] += 1
			if body:
				on_body[g] += 1
			for k in range(g + 1, 4):
				if hit[k]:
					overlap[Vector2i(g, k)] = int(overlap.get(Vector2i(g, k), 0)) + 1
	var line := "    M4 (üçgen):"
	for g in 4:
		assert_true(int(counts[g]) > 500, "%s maskesi var (%d üçgen)" % [names[g], counts[g]])
		var spill := float(on_body[g]) / maxf(float(counts[g]), 1.0)
		assert_true(spill < M4_SPILL, "%s maskesi tene, saça, göze taşmaz (%%%.2f)" % [names[g], 100.0 * spill])
		line += " %s %d, tene %%%.2f;" % [names[g], counts[g], 100.0 * spill]
	for pair: Vector2i in [Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3)]:
		var shared := float(overlap.get(pair, 0)) / maxf(float(mini(int(counts[pair.x]), int(counts[pair.y]))), 1.0)
		assert_true(shared < M4_SPILL, "%s ve %s maskeleri birbirine taşmaz (%%%.2f)" % [names[pair.x], names[pair.y], 100.0 * shared])
		line += " %s∩%s %%%.2f;" % [names[pair.x], names[pair.y], 100.0 * shared]
	print(line)


func test_cape_corners_hang_from_the_hips_not_the_thighs() -> void:
	await _setup()
	var mi := RideCape.skinned_mesh(_avatar)
	var corners := RideFit.cape_corners(_cape.ride_mesh, _image(DYE))
	var before := _shares(_cape.walk_mesh, _bind_names(mi), corners)
	var after := _shares(_cape.ride_mesh, _bind_names(mi), corners)
	print("    Pelerin köşeleri (%d): uyluk ve bacak payı önce %%%.1f, sonra %%%.1f (örtüde %%%.1f); pelerin kemikleri %%%.1f" % [corners.size(), 100.0 * before["legs"], 100.0 * after["legs"], 100.0 * after["sheet_legs"], 100.0 * after["cape"]])
	assert_true(float(before["legs"]) > 0.9, "Modelin kendi ağırlığında köşeler uyluklara bağlı (bulgu 8)")
	assert_true(float(after["sheet_legs"]) < 0.001, "Örtüde (z ≤ %.2f) bacak payı kalmaz" % RideCape.SHEET_Z.y)
	assert_true(float(after["cape"]) > 0.8, "Köşeler kalçanın çocuğu pelerin zincirlerine bağlı")
	assert_true(float(after["legs"]) < 0.15, "Halkayla örtü arasındaki geçişte uyluk payı azalır")


func test_m5_back_cape_does_not_split_between_the_legs() -> void:
	await _setup()
	var mi := RideCape.skinned_mesh(_avatar)
	var corners := RideFit.cape_corners(mi.mesh, _image(DYE))
	var edges := _edges_within(mi.mesh, corners)
	assert_true(edges.size() > 10000, "Köşelerin kenarları (%d)" % (edges.size() / 2))
	# Bacak arası: iki ucu da kalça eklemlerinin arasında (|x| ≤ M5_BETWEEN) kalan kenarlar.
	var verts: PackedVector3Array = mi.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var between := PackedInt32Array()
	for e in edges.size() / 2:
		if absf(verts[corners[edges[e * 2]]].x) <= M5_BETWEEN and absf(verts[corners[edges[e * 2 + 1]]].x) <= M5_BETWEEN:
			between.append(edges[e * 2])
			between.append(edges[e * 2 + 1])
	assert_true(between.size() > 2000, "Bacak arasındaki kenarlar (%d)" % (between.size() / 2))
	# Zincirli ağın serilişi (karşılaştırma için; oyunda yalnız atta): aynı köşeler zincirlerin ağırlığıyla.
	var r_arrays := _cape.ride_mesh.surface_get_arrays(0)
	_steps(Vector2.ZERO, false, 0.5)
	assert_eq(mi.mesh, _cape.walk_mesh, "Yaya modelin kendi ağırlığıyla yürür")
	var standing := RideFit.skinned_points(mi, corners)
	var rest := _edge_lengths(standing, between)
	var rest_all := _edge_lengths(standing, edges)
	var worst := {"walk": Vector2.ZERO, "all": Vector2.ZERO, "drape": Vector2.ZERO}
	var drape_rest := PackedFloat32Array()
	for gait: Array in [["yürüyüş", Vector2(0, 1), false, 2.0], ["koşu", Vector2(0, 1), true, 2.0], ["dönüş", Vector2(1, 0), true, 1.0], ["geri dönüş", Vector2(0, -1), false, 1.5]]:
		var gait_worst := Vector2.ZERO
		for i in int(float(gait[3]) / (DT * 6.0)):
			_steps(gait[1], gait[2], DT * 6.0)
			var now := RideFit.skinned_points(mi, corners)
			gait_worst = gait_worst.max(_stretch(now, between, rest))
			worst["all"] = (worst["all"] as Vector2).max(_stretch(now, edges, rest_all))
			var drape := RideFit.skin_arrays(r_arrays, RideFit.skin_matrices(mi, _cape.solve_now()), corners, mi.global_transform)
			if drape_rest.is_empty():
				drape_rest = _edge_lengths(standing, between)
			worst["drape"] = (worst["drape"] as Vector2).max(_stretch(drape, between, drape_rest))
		worst["walk"] = (worst["walk"] as Vector2).max(gait_worst)
		assert_true(gait_worst.y <= M5_GAP, "M5 %s: bacak arasında örtü en çok %.1f cm açılır (≤%.0f cm; kenar ×%.2f)" % [gait[0], 100.0 * gait_worst.y, 100.0 * M5_GAP, gait_worst.x])
	print("    M5: bacak arasında en çok %.1f cm, ×%.2f; bütün arka örtüde %.1f cm, ×%.2f (yayada serilseydi bacak arasında %.1f cm)" % [
		100.0 * (worst["walk"] as Vector2).y, (worst["walk"] as Vector2).x, 100.0 * (worst["all"] as Vector2).y, (worst["all"] as Vector2).x, 100.0 * (worst["drape"] as Vector2).y])


func test_m11_feet_do_not_slide_while_walking_and_running() -> void:
	await _setup()
	var skel := _avatar.get_skeleton()
	var report := ""
	for gait: Array in [["yürüyüş", false], ["koşu", true]]:
		_steps(Vector2(0, 1), gait[1], 1.0)
		_avatar._apply_ground_offset(true)
		var tracks := {}
		for toe in ["LeftToeBase", "RightToeBase"]:
			tracks[toe] = PackedVector3Array()
		for i in int(3.0 / DT):
			_steps(Vector2(0, 1), gait[1], DT)
			for toe: String in tracks:
				var track: PackedVector3Array = tracks[toe]
				track.append(skel.global_transform * skel.get_bone_global_pose(skel.find_bone(toe)).origin)
				tracks[toe] = track
		var worst := 0.0
		var windows := 0
		for toe: String in tracks:
			var r := _slide(tracks[toe])
			worst = maxf(worst, float(r["slide"]))
			windows += int(r["windows"])
		assert_true(windows >= 4, "%s: basmalar ölçüldü (%d)" % [gait[0], windows])
		assert_true(worst <= M11_SLIDE, "M11 %s: basan ayak en çok %.1f cm kayar (≤6 cm)" % [gait[0], 100.0 * worst])
		report += " %s %.1f cm (%d basma);" % [gait[0], 100.0 * worst, windows]
		_steps(Vector2.ZERO, false, 1.0)
	print("    M11:" + report)


func test_m12_soles_touch_the_ground() -> void:
	await _setup()
	var mi := RideCape.skinned_mesh(_avatar)
	var feet := _bone_vertices(mi, FEET, 0.5)
	assert_true(feet.size() > 500, "Ayak köşeleri (%d)" % feet.size())
	_steps(Vector2.ZERO, false, 1.0)
	_avatar._apply_ground_offset(true)
	var idle := _lowest(RideFit.skinned_points(mi, feet, 0, _cape.last_poses))
	assert_almost(idle, 0.0, M12_GAP, "M12 duruş: taban zeminde (%.1f cm)" % (100.0 * idle))
	var worst := absf(idle)
	var report := "duruş %.1f cm;" % (100.0 * idle)
	for gait: Array in [["yürüyüş", false], ["koşu", true]]:
		_steps(Vector2(0, 1), gait[1], 1.0)
		_avatar._apply_ground_offset(true)
		var lows := PackedFloat32Array()
		for i in int(2.0 / (DT * 2.0)):
			_steps(Vector2(0, 1), gait[1], DT * 2.0)
			lows.append(_lowest(RideFit.skinned_points(mi, feet, 0, _cape.last_poses)))
		# Batma: hiçbir karede taban zeminin M12_GAP altına inmez. Değme: her adımda (M12_STEP sn'lik pencere; koşunun havadaki anı sayılmaz) alttaki
		# taban zemine M12_GAP'e dek iner.
		var sink := 0.0
		for low in lows:
			sink = minf(sink, low)
		var window := int(M12_STEP / (DT * 2.0))
		var lift := 0.0
		for start in lows.size() - window:
			var touch := INF
			for j in window:
				touch = minf(touch, lows[start + j])
			lift = maxf(lift, touch)
		assert_true(sink >= -M12_GAP, "M12 %s: taban zemine en çok %.1f cm batar" % [gait[0], -100.0 * sink])
		assert_true(lift <= M12_GAP, "M12 %s: her adımda taban zemine iner (en çok %.1f cm yukarıda)" % [gait[0], 100.0 * lift])
		worst = maxf(worst, maxf(-sink, lift))
		report += " %s batma %.1f, değme %.1f cm;" % [gait[0], -100.0 * sink, 100.0 * lift]
	print("    M12: " + report)


# --- Yardımcılar ---------------------------------------------------------------------------------------------------

## Oyundaki Mete: profil, Kışlak kılığı, pelerin iskeleti; düz zemin.
func _setup() -> void:
	_player = PlayerController.new()
	_player.terrain_shape = FlatShape.new()
	_player.start_active = false
	_avatar = CharacterAvatar.new()
	_player.add_child(_avatar)
	add_child(_player)
	_trash.append(_player)
	_player.set_process(false)
	await wait_frames(1)
	_player.obstacles = []
	_player.use_profile(CharacterProfile.new())
	_player.set_active(true)
	_player.spawn_at(Vector3.ZERO, 0.0)
	_cape = _avatar.get_node_or_null(^"RideCape") as RideCape
	_anim = _avatar.get_animation_player()


func _steps(input: Vector2, sprint: bool, seconds: float) -> void:
	for i in maxi(int(round(seconds / DT)), 1):
		_player.step(DT, input, sprint, 0.0)
		_anim.advance(DT)
		if _cape:
			_cape.solve_now(DT)


func _image(path: String) -> Image:
	return Image.load_from_file(ProjectSettings.globalize_path(path))


static func _triangles(mesh: Mesh) -> int:
	var total := 0
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		var index: Variant = arrays[Mesh.ARRAY_INDEX]
		total += (index as PackedInt32Array).size() / 3 if index != null else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return total


## Köşelerin ağırlık payları: bacak (uyluk, baldır, ayak), pelerin kemikleri, örtüdeki (z ≤ SHEET_Z.y) bacak payı. names: derinin bağ adları.
static func _shares(mesh: Mesh, names: PackedStringArray, indices: PackedInt32Array) -> Dictionary:
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var stride := bones.size() / maxi(verts.size(), 1)
	var legs := 0.0
	var cape := 0.0
	var sheet_legs := 0.0
	var sheet := 0
	for v in indices:
		var in_sheet := verts[v].z <= RideCape.SHEET_Z.y
		if in_sheet:
			sheet += 1
		for k in stride:
			var wt := weights[v * stride + k]
			if wt <= 0.0:
				continue
			var bone_name := names[bones[v * stride + k]]
			if bone_name in THIGHS:
				legs += wt
				if in_sheet:
					sheet_legs += wt
			elif RideCape.is_cape_bone(bone_name):
				cape += wt
	var n := maxf(float(indices.size()), 1.0)
	return {"legs": legs / n, "cape": cape / n, "sheet_legs": sheet_legs / maxf(float(sheet), 1.0)}


## Seçilen köşeler arasındaki üçgen kenarları (yinelenmeden; çiftler düz dizide, seçimdeki sırayla).
static func _edges_within(mesh: Mesh, indices: PackedInt32Array) -> PackedInt32Array:
	var slot := {}
	for i in indices.size():
		slot[indices[i]] = i
	var index: PackedInt32Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
	var seen := {}
	var out := PackedInt32Array()
	for t in range(0, index.size(), 3):
		for e in 3:
			var a := index[t + e]
			var b := index[t + (e + 1) % 3]
			if not slot.has(a) or not slot.has(b):
				continue
			var key := Vector2i(mini(a, b), maxi(a, b))
			if seen.has(key):
				continue
			seen[key] = true
			out.append(int(slot[a]))
			out.append(int(slot[b]))
	return out


static func _edge_lengths(points: PackedVector3Array, edges: PackedInt32Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(edges.size() / 2)
	for e in out.size():
		out[e] = points[edges[e * 2]].distance_to(points[edges[e * 2 + 1]])
	return out


## Kenarların duruşa göre en büyük uzaması: x oran (2 mm'den kısa kenarlar sayılmaz), y uzunluk farkı (m; açılan yarığın genişliği).
static func _stretch(points: PackedVector3Array, edges: PackedInt32Array, rest: PackedFloat32Array) -> Vector2:
	var worst := Vector2.ZERO
	for e in rest.size():
		var now := points[edges[e * 2]].distance_to(points[edges[e * 2 + 1]])
		worst.y = maxf(worst.y, now - rest[e])
		if rest[e] >= 0.002:
			worst.x = maxf(worst.x, now / rest[e])
	return worst


## Basmaların kayması: ayağın en alçak yerinin M11_BAND üstüne dek basıyor sayılır; her basmada yataydaki en büyük yer değişimi.
static func _slide(track: PackedVector3Array) -> Dictionary:
	var low := INF
	for p in track:
		low = minf(low, p.y)
	var worst := 0.0
	var windows := 0
	var start := -1
	for i in track.size() + 1:
		var down := i < track.size() and track[i].y <= low + M11_BAND
		if down and start < 0:
			start = i
		elif not down and start >= 0:
			if i - start >= 3:
				windows += 1
				var from := Vector2(track[start].x, track[start].z)
				for j in range(start, i):
					worst = maxf(worst, from.distance_to(Vector2(track[j].x, track[j].z)))
			start = -1
	return {"slide": worst, "windows": windows}


## Kemiklere (adlarıyla) en az min_weight bağlı köşeler.
static func _bone_vertices(mi: MeshInstance3D, names: Array[String], min_weight: float) -> PackedInt32Array:
	var arrays := mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var stride := bones.size() / maxi(verts.size(), 1)
	var bind_names := _bind_names(mi)
	var out := PackedInt32Array()
	for v in verts.size():
		var w := 0.0
		for k in stride:
			if bind_names[bones[v * stride + k]] in names:
				w += weights[v * stride + k]
		if w >= min_weight:
			out.append(v)
	return out


## Derinin bağlarının kemik adları (bağ adıyla ya da iskeletteki kemiğiyle).
static func _bind_names(mi: MeshInstance3D) -> PackedStringArray:
	var skel := mi.get_node_or_null(mi.skeleton) as Skeleton3D
	var out := PackedStringArray()
	for i in mi.skin.get_bind_count():
		var bind_name := str(mi.skin.get_bind_name(i))
		if bind_name.is_empty() and skel and mi.skin.get_bind_bone(i) >= 0:
			bind_name = skel.get_bone_name(mi.skin.get_bind_bone(i))
		out.append(bind_name)
	return out


static func _sample(image: Image, uv: Vector2) -> Color:
	return image.get_pixel(clampi(int(uv.x * image.get_width()), 0, image.get_width() - 1), clampi(int(uv.y * image.get_height()), 0, image.get_height() - 1))


static func _lowest(points: PackedVector3Array) -> float:
	var low := INF
	for p in points:
		low = minf(low, p.y)
	return low
