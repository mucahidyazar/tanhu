class_name PrologueWorld
extends Node3D
## Önsöz'ün yerleri (E21, K110; story.md §3 «Göl Obası'nda üç gün»; docs/design/d3/e21-prologue-api.md §4): kamp dünyasında yalnız Önsöz'ün
## günlerinde kurulan Kayın Obası, Göl Obası'ndan inen yol, dere ve sığ geçidi, on iki keçe bayraklı kazık, rüzgârı kesen kayalar ve aile
## yurdunun açık hâli. Veri data/story/prologue_days/places.json'dadır. teardown() her şeyi geri koyar: gizlenen çam ve ot örnekleri, kampın
## aile yurdu (Camp/YurtLeft). Menü karesi değişmez (menü kadrajı kuzeye bakar, oba ve yol güneydedir; dönüşte hepsi kalkar).
##
## Kayın Obası (≈320 m güneybatı, vadi ormanının açıklığı): üç yurt (StructureSet: yakında tam açık yurt, uzakta YurtField; Saruk'un ve
## Künay'ın yurdu açık, içine girilir: çatısız diorama, K98), sabanın ahşap çatısı ve deri saba, kurut sergisi, at bağı ve iki at, güreş
## halkası, açık ocak; Künay'ın yurdunda beşik ve beşiğe asılı küçük yay. Yol: köşe noktaları yumuşar (PathNetwork.smooth_polyline), toprağı
## çıkartmadır (Decal: arazinin ağına oturur), üstündeki ve yanındaki çam ve ot örnekleri gizlenir (MultiMesh tamponu; geri yazılır). Yokuş
## beş kolludur (kollar ≈12°, dönemeçler ≈25°). Yürünür alan: yol boyunca daireler (açık vadide geniş) ve obaların daireleri (walk_circles).
##   var places := PrologueWorld.new(); places.world = world; places.player = player
##   add_child(places); await places.build()
##   places.marker("saba")            # Vector3 (zeminde)
##   places.walk_circles()            # PlayerController.play_area_extra
##   places.teardown()                # geri koyar

const PLACES_PATH := "res://data/story/prologue_days/places.json"
## Kampın aile yurdu (Önsöz'de açık yurtla değişir) ve kampın düğümleri.
const FAMILY_YURT := ^"Camp/YurtLeft"
const FOREST := ^"Forest"
const MEADOW := ^"Meadow"
## Yolun yumuşatma örneği (köşe başına) ve yürünür alanın daire aralığı (m).
const ROAD_SAMPLES := 6
const WALK_STEP := 2.5
## Gizlenen çam: yolun yarı genişliği + bu pay (m; gövde ve alt dal), obada bu yarıçap; ot: yarı genişlik + pay.
const TREE_CLEAR := 2.8
## Yolun kamera yanında (güneyinde) gizlenen ladinlerin yola en büyük uzaklığı (m): takip kamerası 22–28 m geriden, 38°'den bakar.
const CAMERA_CLEAR := 11.0
const OBA_CLEAR := 33.0
const STREAM_CLEAR := 2.2
## Çimen: yurdun çevresinde çıkmadığı yarıçap ve obanın çayırının yarıçapı (m; ağaçların açıklığı OBA_CLEAR).
const YURT_GRASS_R := 3.9
const OBA_GRASS_R := 31.0
## Vadi ladinlerinin kamera örtmesinin yarıçapı (m; kamp çamlarınınkinden geniş: ladin iri, kamera uzak).
const VALLEY_OCCLUSION := 2.4
const GRASS_CLEAR := 0.45
## Yürünür alanın içinde kalan (gizlenmeyen) çamın gövdesi engeldir (m).
const TRUNK_RADIUS := 0.32
## Ev düzeninde Çocuk'un döşeği (yurdun yerel uzayı; yurt_layouts.json «ev» mattress [−1,0, 2,05]) ve Künay'ın döşeği (bedding [3,62, 2,45]).
const FAMILY_BED_LOCAL := Vector3(-1.725, 0.0, 1.108)
const KUNAY_BED_LOCAL := Vector3(-1.13, 0.0, -2.18)
## Yatağın başı: yataktan yurdun ortasına doğru (m).
const BEDSIDE := 0.8
const CRADLE_LOCAL := Vector3(1.55, 0.0, -1.2)
## Basma taşlarının geçidin ortasından yol boyunca uzaklıkları (m).
const FORD_STONES: Array[float] = [-1.55, -0.55, 0.45, 1.45]
## Kazığın bayrak renkleri (keçe: kızıl ve krem, sırayla).
const FLAG_COLORS: Array[Color] = [Color("#a33a22"), Color("#c9b48a")]

var world: Node3D
var player: PlayerController
var data: Dictionary = {}
## Yumuşatılmış yol ve köşelerin yol boyu uzaklığı (m).
var road := PackedVector2Array()
var road_arc := PackedFloat32Array()
var stream := PackedVector2Array()
var stake_nodes: Array[Node3D] = []
var stake_points: Array[Vector3] = []
## Rüzgârı kesen kayalar: Vector3(x, z, yarıçap).
var shelter_rocks: Array[Vector3] = []
var structures: StructureSet
var yurt_slots: Dictionary = {}
var family_yurt: StagedYurt
var saba_node: Node3D
var cradle: Node3D
var oba_fire: Node3D
## Yolun ve obanın çimeni (PrologueGrass).
var grass: PrologueGrass
var built := false

var _markers: Dictionary = {}
var _shape: RefCounted
var _hidden_buffers: Array = []
## Kamera örtmesi açılan vadi ladini malzemeleri (_open_occlusion).
var _occluding: Array[ShaderMaterial] = []
var _hidden_nodes: Array[Node3D] = []
var _camp_yurt: Node3D
var _camp_yurt_in_group := false
var _family_open := false
var _trunks: Array[Vector3] = []
var _solid: Array[Vector3] = []
var _refresh_left := 0.0
var _near_count := -1
var _snow := 0.0
var _storm := 0.0
var _flow := Vector2(0.866, 0.5)
var _yurt_hearth: Dictionary = {}


## Verinin okunuşu (saf; sınama).
static func load_places(path: String = PLACES_PATH) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	return parsed if parsed is Dictionary else {}


## Yumuşatılmış yol (saf).
static func road_of(d: Dictionary) -> PackedVector2Array:
	var raw := PackedVector2Array()
	for p: Variant in d.get("road", []):
		raw.append(Vector2(float(p[0]), float(p[1])))
	return PathNetwork.smooth_polyline(raw, ROAD_SAMPLES) if raw.size() >= 2 else raw


## Çizginin köşelerinin yol boyu uzaklıkları (saf).
static func arcs_of(line: PackedVector2Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var acc := 0.0
	for i in line.size():
		if i > 0:
			acc += line[i].distance_to(line[i - 1])
		out.append(acc)
	return out


## Çizgide yol boyu uzaklıktaki nokta (saf).
static func point_at_arc(line: PackedVector2Array, arcs: PackedFloat32Array, s: float) -> Vector2:
	if line.is_empty():
		return Vector2.ZERO
	if s <= 0.0:
		return line[0]
	for i in range(1, line.size()):
		if arcs[i] >= s:
			var k := (s - arcs[i - 1]) / maxf(arcs[i] - arcs[i - 1], 0.0001)
			return line[i - 1].lerp(line[i], k)
	return line[line.size() - 1]


## Noktanın çizgiye en yakın yeri: Vector3(yol boyu, uzaklık, kesim dizini) (saf).
static func project(line: PackedVector2Array, arcs: PackedFloat32Array, p: Vector2) -> Vector3:
	var best := Vector3(0.0, INF, 0.0)
	for i in range(1, line.size()):
		var a := line[i - 1]
		var b := line[i]
		var ab := b - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
		var q := a + ab * t
		var d := p.distance_to(q)
		if d < best.y:
			best = Vector3(arcs[i - 1] + ab.length() * t, d, float(i - 1))
	return best


## Kazıkların yerleri (saf): yokuşun başından (stakes.from'un yol üstündeki izdüşümü) geçidin önüne (before_ford m kala) eşit arayla.
static func stake_spots(d: Dictionary, line: PackedVector2Array, arcs: PackedFloat32Array) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var cfg: Dictionary = d.get("stakes", {})
	var n := int(cfg.get("count", 12))
	var from_p := Vector2(float((cfg.get("from", [-6, 52]) as Array)[0]), float((cfg.get("from", [-6, 52]) as Array)[1]))
	var ford_raw: Array = (d.get("markers", {}) as Dictionary).get("ford", [-212, 168])
	var s0 := PrologueWorld.project(line, arcs, from_p).x
	var s1 := PrologueWorld.project(line, arcs, Vector2(float(ford_raw[0]), float(ford_raw[1]))).x - float(cfg.get("before_ford", 6.0))
	for i in n:
		var s := lerpf(s0, s1, float(i) / float(maxi(n - 1, 1)))
		var p := PrologueWorld.point_at_arc(line, arcs, s)
		# Kazık yolun kenarındadır (sağ yanında 1,3 m; bayrak yola dönük).
		var ahead := PrologueWorld.point_at_arc(line, arcs, s + 1.0)
		var dir := (ahead - p).normalized() if ahead.distance_to(p) > 0.01 else Vector2(1, 0)
		out.append(p + Vector2(-dir.y, dir.x) * 1.3)
	return out


## Yürünür alanın daireleri (saf; kampın dairesi dışında): yol boyunca WALK_STEP arayla (açık vadide open_radius), verinin walk daireleri.
static func walk_of(d: Dictionary, line: PackedVector2Array, arcs: PackedFloat32Array) -> Array[Vector3]:
	var out: Array[Vector3] = []
	if line.is_empty():
		return out
	var r_road := float(d.get("road_radius", 5.5))
	var r_open := float(d.get("open_radius", 16.0))
	var open_raw: Array = d.get("open_from", [-140, 126])
	var open_s := PrologueWorld.project(line, arcs, Vector2(float(open_raw[0]), float(open_raw[1]))).x
	var total := arcs[arcs.size() - 1]
	var s := 0.0
	while s <= total + 0.01:
		var p := PrologueWorld.point_at_arc(line, arcs, s)
		var r := r_road if s < open_s else lerpf(r_road, r_open, clampf((s - open_s) / 20.0, 0.0, 1.0))
		out.append(Vector3(p.x, p.y, r))
		s += WALK_STEP
	for w: Variant in d.get("walk", []):
		out.append(Vector3(float(w[0]), float(w[1]), float(w[2])))
	return out


# --- Kurulum ----------------------------------------------------------------------------------------------

## Kurar (karelere bölünür; perde kapalıyken). Dünya yoksa yalnız veri ve işaretler.
func build() -> void:
	if data.is_empty():
		data = PrologueWorld.load_places()
	_shape = world.call(&"get_terrain_shape") if world and world.has_method(&"get_terrain_shape") else TerrainShape.new()
	road = PrologueWorld.road_of(data)
	road_arc = PrologueWorld.arcs_of(road)
	for p: Variant in data.get("stream", []):
		stream.append(Vector2(float(p[0]), float(p[1])))
	stream = PathNetwork.smooth_polyline(stream, 4) if stream.size() >= 2 else stream
	_read_markers()
	if world == null or not is_inside_tree():
		built = true
		return
	_clear_corridor()
	await get_tree().process_frame
	_build_road()
	_build_stream()
	_build_stakes()
	_build_rocks()
	await get_tree().process_frame
	_build_oba()
	await get_tree().process_frame
	_build_grass()
	await get_tree().process_frame
	_build_family_yurt()
	set_process(true)
	built = true


func _read_markers() -> void:
	_markers.clear()
	for id: String in (data.get("markers", {}) as Dictionary):
		var v: Array = data["markers"][id]
		_markers[id] = Vector2(float(v[0]), float(v[1]))
	var spots := PrologueWorld.stake_spots(data, road, road_arc)
	for i in spots.size():
		_markers["stake_%d" % (i + 1)] = spots[i]
	var ford: Vector2 = _markers.get("ford", Vector2(-212, 168))
	var f := PrologueWorld.project(road, road_arc, ford)
	var dir := (PrologueWorld.point_at_arc(road, road_arc, f.x + 1.0) - PrologueWorld.point_at_arc(road, road_arc, f.x - 1.0)).normalized()
	for i in FORD_STONES.size():
		_markers["ford_stone_%d" % (i + 1)] = ford + dir * FORD_STONES[i]
	_markers["ford_east"] = ford - dir * 3.4
	_markers["ford_west"] = ford + dir * 3.4
	var rocks: Array = data.get("shelter_rocks", [])
	for i in rocks.size():
		_markers["shelter_rock_%d" % (i + 1)] = Vector2(float(rocks[i][0]), float(rocks[i][1]))
	# Kayın Obası'nın yurtları: merkez, kapı (dışarıda), ocak; Künay'ın yurdunda döşek ve beşik.
	var yurts: Dictionary = data.get("yurts", {})
	for id: String in yurts:
		var rec: Dictionary = yurts[id]
		var xf := _yurt_xform(rec)
		var at := Vector2(xf.origin.x, xf.origin.z)
		var door_dir := Vector2(xf.basis.z.x, xf.basis.z.z).normalized()
		var key := id if id.begins_with("birch") else id
		_markers[key + "_yurt"] = at
		_markers[key + "_door"] = at + door_dir * 4.3
		_markers[key + "_in"] = at + door_dir * 2.0
		_markers[key + "_hearth"] = at + door_dir * 0.25
		_markers[key + "_bed"] = _local_xz(xf, KUNAY_BED_LOCAL)
		_markers[key + "_bedside"] = _local_xz(xf, PrologueWorld.bedside_of(KUNAY_BED_LOCAL))
		if id == "kunay":
			_markers["kunay_cradle"] = _local_xz(xf, CRADLE_LOCAL)
	# Göl Obası'nın aile yurdu (kampın YurtLeft'i): yatak, kapı, sırık.
	var fam := _family_xform()
	var fdoor := Vector2(fam.basis.z.x, fam.basis.z.z).normalized()
	var fat := Vector2(fam.origin.x, fam.origin.z)
	_markers["gol_family_yurt"] = fat
	_markers["gol_family_bed"] = _local_xz(fam, FAMILY_BED_LOCAL)
	_markers["gol_family_bedside"] = _local_xz(fam, PrologueWorld.bedside_of(FAMILY_BED_LOCAL))
	_markers["gol_family_in"] = fat + fdoor * 1.8
	_markers["gol_family_door"] = fat + fdoor * 4.4
	_markers["gol_milk_pole"] = fat + fdoor * 4.6 + Vector2(-fdoor.y, fdoor.x) * 1.3


## Yatağın başı (saf): yatağın yurdun ortasına (ocağa) bakan yanı, yataktan BEDSIDE m içeride; başında diz çöken kişinin yeri
## (yatan kişiyle üst üste düşmez).
static func bedside_of(bed_local: Vector3, k: float = BEDSIDE) -> Vector3:
	var flat := Vector3(bed_local.x, 0.0, bed_local.z)
	if flat.length() < 0.01:
		return bed_local
	return bed_local - flat.normalized() * k


func _local_xz(xf: Transform3D, local: Vector3) -> Vector2:
	var w := xf * local
	return Vector2(w.x, w.z)


func _family_xform() -> Transform3D:
	var n := world.get_node_or_null(FAMILY_YURT) as Node3D if world else null
	if n:
		return Transform3D(n.global_transform.basis.orthonormalized(), n.global_position)
	# Sahnenin değeri (world.tscn Camp/YurtLeft).
	return Transform3D(Basis(Vector3(0.57204, 0, -0.82023), Vector3.UP, Vector3(0.82023, 0, 0.57204)), Vector3(-6.18, 0, -4.31))


func _yurt_xform(rec: Dictionary) -> Transform3D:
	var at := Vector2(float(rec["at"][0]), float(rec["at"][1]))
	var face_raw: Array = rec.get("face", [at.x, at.y + 1.0])
	var face := Vector2(float(face_raw[0]), float(face_raw[1]))
	var rot := atan2(face.x - at.x, face.y - at.y)
	var y := _ground(at.x, at.y)
	return Transform3D(Basis(Vector3.UP, rot), Vector3(at.x, y, at.y))


# --- Yolun ve obanın açıklığı ------------------------------------------------------------------------------

## Yolun, derenin ve obanın üstündeki çam ve ot örnekleri sıfır ölçeğe iner (tampon geri yazılır); yürünür alanın içinde kalan çamın gövdesi
## engel olur. Örnekler önce kaba bir ızgarayla süzülür (yolun, derenin ve obanın hücreleri). Başsızda tampon okunmaz (çizim yok).
func _clear_corridor() -> void:
	var half := float(data.get("road_width", 1.7)) * 0.5
	var oba: Vector2 = _markers.get("birch_center", Vector2(-250, 197))
	var walk := PrologueWorld.walk_of(data, road, road_arc)
	var stream_arc := PrologueWorld.arcs_of(stream)
	var stream_half := float(data.get("stream_width", 2.6)) * 0.5
	var cells := _cells_near(walk, oba)
	var forest := world.get_node_or_null(FOREST)
	if forest:
		var hide_tree := func(p: Vector2) -> bool:
			if p.distance_to(oba) < OBA_CLEAR:
				return true
			var pr := PrologueWorld.project(road, road_arc, p)
			if pr.y < half + TREE_CLEAR:
				return true
			# Kameranın yanı: takip kamerası (yön 0) oyuncunun güneyindedir; yolun güneyindeki yakın ladin kameranın önüne girer.
			if pr.y < CAMERA_CLEAR and p.y > PrologueWorld.point_at_arc(road, road_arc, pr.x).y - 1.0:
				return true
			return stream.size() >= 2 and PrologueWorld.project(stream, stream_arc, p).y < stream_half + STREAM_CLEAR
		for n in forest.find_children("*", "MultiMeshInstance3D", true, false):
			_clear_multimesh(n as MultiMeshInstance3D, hide_tree, walk, cells)
			_open_occlusion(n as MultiMeshInstance3D)
		if not _occluding.is_empty():
			add_to_group(FollowCamera.OCCLUDER_GROUP)
		for n in forest.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			if not mi.visible:
				continue
			var p := Vector2(mi.global_position.x, mi.global_position.z)
			if p.y > 8.0 and cells.has(_cell(p)) and PrologueWorld.project(road, road_arc, p).y < half + TREE_CLEAR + 1.0:
				mi.visible = false
				_hidden_nodes.append(mi)
	var meadow := world.get_node_or_null(MEADOW)
	if meadow:
		var hide_grass := func(p: Vector2) -> bool:
			return PrologueWorld.project(road, road_arc, p).y < half + GRASS_CLEAR
		for n in meadow.find_children("*", "MultiMeshInstance3D", true, false):
			_clear_multimesh(n as MultiMeshInstance3D, hide_grass, [], cells)


const CELL := 8.0


func _cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x / CELL), floori(p.y / CELL))


## Yolun, derenin, obanın ve yürünür alanın hücreleri (kaba süzgeç).
func _cells_near(walk: Array[Vector3], oba: Vector2) -> Dictionary:
	var out := {}
	var mark := func(p: Vector2, r: float) -> void:
		var c0 := _cell(p - Vector2(r, r))
		var c1 := _cell(p + Vector2(r, r))
		for x in range(c0.x, c1.x + 1):
			for z in range(c0.y, c1.y + 1):
				out[Vector2i(x, z)] = true
	for c in walk:
		mark.call(Vector2(c.x, c.y), maxf(c.z + TREE_CLEAR + 1.0, CAMERA_CLEAR + 1.0))
	for i in stream.size():
		mark.call(stream[i], 6.0)
	mark.call(oba, OBA_CLEAR + 2.0)
	return out


## Örneklerden hide_if(p) doğru olanları gizler (tamponun kopyası saklanır). walk boş değilse gizlenmeyip yürünür alanda kalan örnek gövde engeli
## olur. cells: yalnız bu hücrelerdeki örnekler sınanır.
func _clear_multimesh(mmi: MultiMeshInstance3D, hide_if: Callable, walk: Array, cells: Dictionary) -> void:
	var mm := mmi.multimesh
	if mm == null or mm.instance_count == 0 or mm.transform_format != MultiMesh.TRANSFORM_3D:
		return
	var aabb := mmi.global_transform * mmi.get_aabb()
	var lo := _cell(Vector2(aabb.position.x, aabb.position.z))
	var hi := _cell(Vector2(aabb.end.x, aabb.end.z))
	var any := false
	for x in range(lo.x, hi.x + 1):
		for z in range(lo.y, hi.y + 1):
			if cells.has(Vector2i(x, z)):
				any = true
				break
		if any:
			break
	if not any:
		return
	var buf := mm.buffer
	var stride := 12 + (4 if mm.use_colors else 0) + (4 if mm.use_custom_data else 0)
	if buf.size() < mm.instance_count * stride:
		return
	var xf := mmi.global_transform
	var changed := false
	var out := buf.duplicate()
	for i in mm.instance_count:
		var k := i * stride
		var w := xf * Vector3(buf[k + 3], buf[k + 7], buf[k + 11])
		var p := Vector2(w.x, w.z)
		if not cells.has(_cell(p)):
			continue
		if hide_if.call(p):
			for j in 12:
				out[k + j] = 0.0
			out[k + 3] = buf[k + 3]
			out[k + 7] = buf[k + 7] - 60.0
			out[k + 11] = buf[k + 11]
			changed = true
		elif not walk.is_empty():
			for c: Vector3 in walk:
				if p.distance_to(Vector2(c.x, c.y)) <= c.z + 0.5:
					_trunks.append(Vector3(p.x, p.y, TRUNK_RADIUS))
					break
	if changed:
		_hidden_buffers.append([mm, buf])
		mm.buffer = out


## Vadi ladinlerinin malzemesine kamera örtmesi (Forest'un kamp çamlarındaki noktalı saydamlık; foliage.gdshader): vadinin ladinleri
## örtmesizdir (menüde uzakta durur), Önsöz'ün yolunda ise takip kamerasıyla oyuncunun arasına girer. Malzeme paylaşılır; teardown geri alır.
func _open_occlusion(mmi: MultiMeshInstance3D) -> void:
	var mat := mmi.material_override as ShaderMaterial
	if mat == null or _occluding.has(mat) or mat.shader != Forest.FOLIAGE_SHADER:
		return
	# Hiç verilmemiş tekdüze null döner (gölgelendiricinin varsayılanı 0: örtme kapalı); verilmişse ve açıksa Forest'unkidir.
	var r: Variant = mat.get_shader_parameter("occlusion_radius")
	if (r is float or r is int) and float(r) > 0.0:
		return
	mat.set_shader_parameter("occlusion_radius", VALLEY_OCCLUSION)
	_occluding.append(mat)


## FollowCamera her karede çağırır (OCCLUDER_GROUP): görüş hattı kameradan oyuncunun göğsüne.
func set_camera_occlusion(camera_position: Vector3, target_position: Vector3) -> void:
	for mat in _occluding:
		mat.set_shader_parameter("occlusion_from", camera_position)
		mat.set_shader_parameter("occlusion_to", target_position)


## Gizlenenleri geri koyar.
func _restore_corridor() -> void:
	for mat in _occluding:
		mat.set_shader_parameter("occlusion_radius", 0.0)
	_occluding.clear()
	if is_in_group(FollowCamera.OCCLUDER_GROUP):
		remove_from_group(FollowCamera.OCCLUDER_GROUP)
	for e: Array in _hidden_buffers:
		var mm: MultiMesh = e[0]
		if is_instance_valid(mm):
			mm.buffer = e[1]
	_hidden_buffers.clear()
	for n in _hidden_nodes:
		if is_instance_valid(n):
			n.visible = true
	_hidden_nodes.clear()


# --- Yol, dere, kazıklar, kayalar ----------------------------------------------------------------------------

func _build_road() -> void:
	var dec := PrologueProps.road_decals(road, float(data.get("road_width", 1.7)), _ground)
	add_child(dec)


func _build_stream() -> void:
	if stream.size() < 2:
		return
	var mi := PrologueProps.stream_mesh(stream, float(data.get("stream_width", 2.6)), _ground)
	add_child(mi)
	for i in FORD_STONES.size():
		var p: Vector2 = _markers["ford_stone_%d" % (i + 1)]
		var s := PrologueProps.step_stone(500 + i)
		s.name = "FordStone%d" % (i + 1)
		s.position = Vector3(p.x, _ground(p.x, p.y) + 0.06, p.y)
		s.rotation.y = 0.7 * float(i)
		add_child(s)
	for r: Variant in data.get("stream_rocks", []):
		var rk := PrologueProps.rock(float(r[2]), 600 + int(absf(float(r[0]) * 3.0)))
		rk.position = Vector3(float(r[0]), _ground(float(r[0]), float(r[1])) - float(r[2]) * 0.25, float(r[1]))
		add_child(rk)
		_solid.append(Vector3(float(r[0]), float(r[1]), float(r[2]) * 0.8))


func _build_stakes() -> void:
	var height := float((data.get("stakes", {}) as Dictionary).get("height", 1.55))
	for i in 12:
		var key := "stake_%d" % (i + 1)
		if not _markers.has(key):
			continue
		var p: Vector2 = _markers[key]
		var s := PrologueProps.stake(height, FLAG_COLORS[i % FLAG_COLORS.size()], float(i) * 0.37)
		s.name = "Stake%d" % (i + 1)
		s.position = Vector3(p.x, _ground(p.x, p.y), p.y)
		add_child(s)
		stake_nodes.append(s)
		stake_points.append(s.position)
		_solid.append(Vector3(p.x, p.y, 0.14))


func _build_rocks() -> void:
	var i := 0
	for r: Variant in data.get("shelter_rocks", []):
		var rk := PrologueProps.rock(float(r[2]), 700 + i)
		rk.name = "ShelterRock%d" % (i + 1)
		rk.position = Vector3(float(r[0]), _ground(float(r[0]), float(r[1])) - float(r[2]) * 0.2, float(r[1]))
		add_child(rk)
		shelter_rocks.append(Vector3(float(r[0]), float(r[1]), float(r[2])))
		_solid.append(Vector3(float(r[0]), float(r[1]), float(r[2]) * 0.85))
		i += 1


# --- Kayın Obası ---------------------------------------------------------------------------------------------

## Yolun iki yanının ve obanın açıklığının çimeni (PrologueGrass): yurtların, kazıkların, kayaların dibinde yok; ocağın, kapıların,
## sabanın, at bağının ve güreş halkasının çevresi ezik.
func _build_grass() -> void:
	var blockers: Array[Vector3] = _solid.duplicate()
	blockers.append_array(shelter_rocks)
	for r: Variant in data.get("stream_rocks", []):
		blockers.append(Vector3(float(r[0]), float(r[1]), float(r[2]) + 0.3))
	var trample: Array[Vector3] = []
	for id: String in (data.get("yurts", {}) as Dictionary):
		var c: Vector2 = _markers.get(id + "_yurt", Vector2.INF)
		if c != Vector2.INF:
			blockers.append(Vector3(c.x, c.y, YURT_GRASS_R))
		var d: Vector2 = _markers.get(id + "_door", Vector2.INF)
		if d != Vector2.INF:
			trample.append(Vector3(d.x, d.y, 1.8))
	for spec: Array in [["birch_fire", 3.4], ["wrestle_ring", 3.3], ["saba", 2.3], ["saba_stand", 1.6], ["kurut_rack", 1.8],
			["horse_tether", 2.8], ["birch_play", 2.4], ["ford_east", 1.4], ["ford_west", 1.4], ["birch_gate", 1.6]]:
		var m: Vector2 = _markers.get(str(spec[0]), Vector2.INF)
		if m != Vector2.INF:
			trample.append(Vector3(m.x, m.y, float(spec[1])))
	var oba: Vector2 = _markers.get("birch_center", Vector2(-250, 197))
	grass = PrologueGrass.new()
	grass.name = "Grass"
	add_child(grass)
	grass.build({"shape": _shape, "road": road, "road_arc": road_arc, "road_half": float(data.get("road_width", 1.7)) * 0.5,
		"stream": stream, "stream_half": float(data.get("stream_width", 2.6)) * 0.5, "blockers": blockers, "trample": trample,
		"oba": Vector3(oba.x, oba.y, OBA_GRASS_R)})


func _build_oba() -> void:
	structures = StructureSet.new()
	structures.ground = _shape
	structures.focus = player
	structures.clock_source = _minute_source()
	add_child(structures)
	var yurts: Dictionary = data.get("yurts", {})
	for id: String in yurts:
		var rec: Dictionary = (yurts[id] as Dictionary).duplicate()
		var xf := _yurt_xform(rec)
		var r := StructureKit.normalize({"kind": "yurt", "id": "birch_" + id, "size": "m", "style": "hun", "layout": str(rec.get("layout", "ev")),
			"open": bool(rec.get("open", false)), "preset": YurtGeometry.WINTER if bool(rec.get("open", false)) else YurtGeometry.CLOSED,
			"hearth": bool(rec.get("hearth", true)), "at": [xf.origin.x, xf.origin.z], "rot": xf.basis.get_euler().y})
		var slot := structures.yurt_slot(r, xf)
		slot.name = id.to_pascal_case() + "Yurt"
		structures.add_child(slot)
		yurt_slots[id] = slot
	# Saba: dört direk, ahşap dam, asılı deri saba; önü obanın ortasına bakar.
	var saba_at: Vector2 = _markers.get("saba", Vector2(-241, 188))
	var center: Vector2 = _markers.get("birch_center", Vector2(-250, 197))
	saba_node = PrologueProps.saba()
	saba_node.position = Vector3(saba_at.x, _ground(saba_at.x, saba_at.y), saba_at.y)
	saba_node.rotation.y = atan2(center.x - saba_at.x, center.y - saba_at.y)
	add_child(saba_node)
	var saba_basis := Basis(Vector3.UP, saba_node.rotation.y)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var post := saba_basis * Vector3(1.5 * sx, 0.0, 1.15 * sz)
			_solid.append(Vector3(saba_at.x + post.x, saba_at.y + post.z, 0.12))
	_solid.append(Vector3(saba_at.x, saba_at.y, 0.42))
	var rack_at: Vector2 = _markers.get("kurut_rack", Vector2(-244, 183))
	var rack := PrologueProps.kurut_rack()
	rack.position = Vector3(rack_at.x, _ground(rack_at.x, rack_at.y), rack_at.y)
	rack.rotation.y = 0.4
	add_child(rack)
	_solid.append(Vector3(rack_at.x, rack_at.y, 0.75))
	# At bağı: iki direk (kuzey–güney, 6 m) ve ip.
	var teth: Vector2 = _markers.get("horse_tether", Vector2(-236, 197))
	var ta := Vector3(0.0, 0.0, -3.0)
	var tb := Vector3(0.0, 0.0, 3.0)
	var tether := PrologueProps.tether(ta, tb)
	tether.position = Vector3(teth.x, _ground(teth.x, teth.y), teth.y)
	add_child(tether)
	_solid.append(Vector3(teth.x, teth.y - 3.0, 0.15))
	_solid.append(Vector3(teth.x, teth.y + 3.0, 0.15))
	# Güreş halkası.
	var ring_at: Vector2 = _markers.get("wrestle_ring", Vector2(-251, 211))
	var ring := PrologueProps.ring(2.6, _ground)
	ring.position = Vector3(ring_at.x, _ground(ring_at.x, ring_at.y), ring_at.y)
	add_child(ring)
	# Açık ocak (obanın ateşi; şildenin büyük ateşi Ö2'nindir).
	var fire_at: Vector2 = _markers.get("birch_fire", Vector2(-250, 198))
	var fire := Campfire.new()
	fire.name = "BirchFire"
	fire.light_energy = 1.6
	fire.light_range = 6.0
	fire.flame_scale = 0.6
	fire.position = Vector3(fire_at.x, _ground(fire_at.x, fire_at.y), fire_at.y)
	add_child(fire)
	oba_fire = fire
	# Künay'ın yurdunda beşik (Meshy beşiği; yoksa kutu) ve asılı küçük yay.
	var cr_at: Vector2 = _markers.get("kunay_cradle", Vector2(-238, 208))
	cradle = Node3D.new()
	cradle.name = "Cradle"
	cradle.position = Vector3(cr_at.x, _ground(cr_at.x, cr_at.y), cr_at.y)
	add_child(cradle)
	if MeshyProp.exists("props", "cradle"):
		var prop := MeshyProp.new()
		prop.model_id = "cradle"
		prop.folder = "props"
		prop.size_axis = 1
		prop.target_size = 0.95
		cradle.add_child(prop)
		if MeshyProp.exists("props", "cradle_bow"):
			var bow := MeshyProp.new()
			bow.model_id = "cradle_bow"
			bow.folder = "props"
			bow.size_axis = 1
			bow.target_size = 0.55
			bow.position = Vector3(0.0, 0.55, 0.0)
			cradle.add_child(bow)
	else:
		var box := MeshInstance3D.new()
		box.mesh = Procedural3D.box(Vector3(0.9, 0.45, 0.45))
		box.material_override = Style.toon(PrologueProps.WOOD)
		box.position = Vector3(0, 0.3, 0)
		cradle.add_child(box)
	_solid.append(Vector3(cr_at.x, cr_at.y, 0.45))


## Açık yurdun ocağı yanıyor mu (Künay'ın yurdu tipide söner: «kara yurt»)?
func set_yurt_hearth(id: String, lit: bool) -> void:
	_yurt_hearth[id] = lit
	var slot := yurt_slots.get(id) as YurtSlot
	if slot == null:
		return
	slot.record["hearth"] = lit
	if slot.is_near():
		slot.near_yurt.hearth_lit = lit
	if structures and structures.field:
		structures.field.set_level(slot, slot.field_level)


## Açık yurdun tam düğümü (yakında değilse null).
func yurt(id: String) -> StagedYurt:
	var slot := yurt_slots.get(id) as YurtSlot
	return slot.near_yurt if slot and slot.is_near() else null


func _minute_source() -> Callable:
	return func() -> float:
		var n: Node = self
		while n and not n is PrologueDays:
			n = n.get_parent()
		return (n as PrologueDays).minute() if n is PrologueDays else 720.0


# --- Aile yurdu ------------------------------------------------------------------------------------------------

func _build_family_yurt() -> void:
	var xf := _family_xform()
	family_yurt = StagedYurt.new()
	family_yurt.name = "FamilyYurt"
	family_yurt.configure({"size": "m", "style": "hun", "layout": "ev", "preset": YurtGeometry.WINTER, "open": true, "hearth": true})
	family_yurt.ground = _shape
	family_yurt.room_focus = player
	family_yurt.transform = xf
	family_yurt.visible = false
	family_yurt.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(family_yurt)
	if family_yurt.is_in_group(World.OBSTACLE_GROUP):
		family_yurt.remove_from_group(World.OBSTACLE_GROUP)


## Aile yurdu açık (içine girilir; Önsöz'ün sabahları ve geceleri) ya da kampın yurdu (menüdeki Meshy yurdu). Değişim perde karayken yapılır.
func set_family_yurt(open: bool) -> void:
	if family_yurt == null or open == _family_open:
		return
	_family_open = open
	_camp_yurt = world.get_node_or_null(FAMILY_YURT) as Node3D if world else null
	if _camp_yurt:
		_camp_yurt.visible = not open
		if open and _camp_yurt.is_in_group(World.OBSTACLE_GROUP):
			_camp_yurt.remove_from_group(World.OBSTACLE_GROUP)
			_camp_yurt_in_group = true
		elif not open and _camp_yurt_in_group:
			_camp_yurt.add_to_group(World.OBSTACLE_GROUP)
			_camp_yurt_in_group = false
	family_yurt.visible = open
	family_yurt.process_mode = Node.PROCESS_MODE_INHERIT if open else Node.PROCESS_MODE_DISABLED
	if open:
		family_yurt.add_to_group(World.OBSTACLE_GROUP)
	elif family_yurt.is_in_group(World.OBSTACLE_GROUP):
		family_yurt.remove_from_group(World.OBSTACLE_GROUP)
	if is_instance_valid(player):
		player.refresh_obstacles.call_deferred()


func is_family_open() -> bool:
	return _family_open


# --- Hava ------------------------------------------------------------------------------------------------------

## Kar örtüsü (0..1): yurtların ve kazıkların karı.
func set_snow(k: float, _seconds: float = 0.0) -> void:
	_snow = clampf(k, 0.0, 1.0)
	if structures:
		structures.snow = _snow
		if structures.field:
			structures.field.snow = _snow
		for s: YurtSlot in structures.slots:
			if s.is_near():
				s.near_yurt.snow = _snow
				s.near_yurt.refresh()
	if family_yurt:
		family_yurt.snow = _snow
		family_yurt.refresh()


## Tipinin şiddeti (0..1) ve rüzgârın akış yönü (dünya xz, birim): bayraklar yatay çırpar.
func set_storm(k: float, flow: Vector2) -> void:
	_storm = clampf(k, 0.0, 1.0)
	if flow.length_squared() > 0.0001:
		_flow = flow.normalized()
	for s in stake_nodes:
		PrologueProps.set_flag_wind(s, lerpf(0.15, 1.0, _storm), _flow)


## Barınak (0..1): rüzgârın akışına göre kayaların, yurtların ve ormanın ardı.
func shelter_at(p: Vector3, flow: Vector2) -> float:
	var f := flow.normalized() if flow.length_squared() > 0.0001 else _flow
	var q := Vector2(p.x, p.z)
	var best := 0.0
	var blockers: Array[Vector3] = shelter_rocks.duplicate()
	for id: String in yurt_slots:
		var slot: YurtSlot = yurt_slots[id]
		blockers.append(Vector3(slot.global_position.x, slot.global_position.z, 3.3))
	for b in blockers:
		var d := q - Vector2(b.x, b.y)
		var along := d.dot(f)
		var side := absf(d.cross(f))
		if along > -b.z * 0.3 and along < b.z * 4.0 and side < b.z * 1.15:
			best = maxf(best, 1.0 - clampf(along / (b.z * 4.0), 0.0, 1.0) * 0.6)
	# Göl Obası'nın içi: yurtlar, çitler ve odunluk rüzgârı kırar.
	if q.length() < 20.0:
		best = maxf(best, 0.5)
	# Yurdun içi tam barınaktır.
	for id: String in yurt_slots:
		var slot2: YurtSlot = yurt_slots[id]
		if q.distance_to(Vector2(slot2.global_position.x, slot2.global_position.z)) < 3.1:
			return 1.0
	# Ormanın içinde rüzgâr kırılır (yolun orman kesimi).
	var s := PrologueWorld.project(road, road_arc, q)
	var forest_from := PrologueWorld.project(road, road_arc, _markers.get("road_descent", Vector2(-6, 52))).x
	var open_from := PrologueWorld.project(road, road_arc, Vector2(float(data.get("open_from", [-140, 126])[0]), float(data.get("open_from", [-140, 126])[1]))).x
	if s.x > forest_from and s.x < open_from:
		best = maxf(best, 0.55)
	return best


# --- Sorgular ---------------------------------------------------------------------------------------------------

## İşaret (zeminde; bilinmiyorsa Vector3.INF).
func marker(id: String) -> Vector3:
	if not _markers.has(id):
		return Vector3.INF
	var p: Vector2 = _markers[id]
	return Vector3(p.x, _ground(p.x, p.y), p.y)


func markers() -> Dictionary:
	return _markers.duplicate()


func has_marker(id: String) -> bool:
	return _markers.has(id)


## Yürünür alanın daireleri (kampın dairesine eklenir).
func walk_circles() -> Array[Vector3]:
	return PrologueWorld.walk_of(data, road, road_arc)


## Oyuncunun ek engelleri: kazıklar, kayalar, sabanın direkleri, at bağı, beşik ve yürünür alandaki çam gövdeleri.
func obstacles() -> Array[Vector3]:
	var out: Array[Vector3] = _solid.duplicate()
	out.append_array(_trunks)
	return out


## Noktanın yola uzaklığı ve yol boyu yeri: Vector2(yol boyu, uzaklık).
func road_projection(p: Vector3) -> Vector2:
	var r := PrologueWorld.project(road, road_arc, Vector2(p.x, p.z))
	return Vector2(r.x, r.y)


## Yol boyu uzaklıktaki nokta (zeminde).
func road_point(s: float) -> Vector3:
	var p := PrologueWorld.point_at_arc(road, road_arc, s)
	return Vector3(p.x, _ground(p.x, p.y), p.y)


func road_length() -> float:
	return road_arc[road_arc.size() - 1] if not road_arc.is_empty() else 0.0


## Yolun noktaları from'dan to'ya (yol boyu; ters de olur), her step m'de bir (zeminde): kişilerin ve botun yolu.
func road_path(from_s: float, to_s: float, step: float = 6.0) -> Array:
	var out: Array = []
	var dir := 1.0 if to_s >= from_s else -1.0
	var s := from_s
	while (to_s - s) * dir > 0.01:
		out.append(road_point(s))
		s += step * dir
	out.append(road_point(to_s))
	return out


func _ground(x: float, z: float) -> float:
	return float(_shape.call(&"height_at", x, z)) if _shape else 0.0


func _process(delta: float) -> void:
	if not built or structures == null:
		return
	# Oba'nın yurtları yakına girince (tam yurt: duvar, kapı, iç eşya) oyuncunun engelleri yenilenir.
	_refresh_left -= delta
	if _refresh_left > 0.0:
		return
	_refresh_left = 0.5
	var near := 0
	for s: YurtSlot in structures.slots:
		if s.is_near():
			near += 1
			var id := str(s.record.get("id", "")).trim_prefix("birch_")
			if _yurt_hearth.has(id) and s.near_yurt.hearth_lit != bool(_yurt_hearth[id]):
				s.near_yurt.hearth_lit = bool(_yurt_hearth[id])
			if s.near_yurt.room_focus != player:
				s.near_yurt.room_focus = player
	if near != _near_count:
		_near_count = near
		if is_instance_valid(player):
			player.refresh_obstacles()


## Her şeyi geri koyar (koşucu durunca): çam ve ot örnekleri, kampın aile yurdu.
func teardown() -> void:
	_restore_corridor()
	set_family_yurt(false)
	if _camp_yurt and is_instance_valid(_camp_yurt):
		_camp_yurt.visible = true
	built = false
	set_process(false)
