@tool
class_name PathNetwork
extends Node3D
## Kamp çevresindeki toprak patikalar ("After the Wind" tarzı, çimenin içinden kıvrılan yollar).
##
## Her patika XZ düzleminde bir çoklu çizgidir (PackedVector2Array). Köşe noktaları yumuşak bir
## eğriye (Catmull-Rom) çevrilir ve tüm ağ en fazla MAX_SEGMENTS doğru parçasına bölünür. Bu parçalar:
##   - arazi shader'ına gönderilir: toprak rengi, gürültülü yumuşak kenar, açık renkli taş benekleri,
##   - çayıra (Meadow) verilir: patikanın üstünde çimen/çiçek çıkmaz, kenara yakın seyrekleşir,
##   - patika kenarlarına küçük çakıl taşları (MultiMesh) serpiştirmek için kullanılır.
## Patikanın yalnızca son ucu daralarak çimenin içinde kaybolur; başlangıç uçları kamp toprağına
## ya da başka bir patikaya bağlanır.
##
## distance_to_paths() saf bir sorgudur (yan etkisiz); tests/unit/test_path_network.gd ile sınanır.

## Bu düğümün katıldığı grup (Meadow ve RockField patikayı buradan bulur).
const GROUP := &"path_network"
## Shader parçaları sekizli gruplar halinde kırpar (grubun kutusu dışındaki pikseller atlanır).
const GROUP_SIZE := 8
const MAX_GROUPS := 8
## Shader'a gönderilebilen en fazla doğru parçası (terrain.gdshader'daki dizi boyutlarıyla aynı olmalı).
const MAX_SEGMENTS := GROUP_SIZE * MAX_GROUPS
## Shader'daki kenar gürültüsünün kutulara eklenen payı (metre).
const BOUNDS_MARGIN := 0.9
## Hızlı sorgu ızgarasının hücre boyu ve "yakın" sayılan en büyük uzaklık (metre).
const INDEX_CELL := 2.0
const INDEX_REACH := 2.0
const PEBBLE_SHADER := preload("res://shaders/atw_rock.gdshader")

## Patikalar: her biri XZ düzleminde köşe noktaları (metre). İlk nokta bağlantı ucu, son nokta serbest uçtur.
## Kadraj içindeki köşeler 4. referanstan (assets/_reference/menu_camp.png) geri izdüşürülmüştür
## (tools/menu_camera_fit.json → patikaA_*, patikaB_*); referansta yalnızca bu iki yol vardır.
@export var paths: Array[PackedVector2Array] = [
	# 0) Ana patika: ateşin sağ önünden kadrajın sağ altına iner; kadrajın dışında güneydoğudaki iki kaya
	#    kümesinin arasından (ikisinin de ön yüzü bu yola bakar) platonun ucuna kıvrılır.
	PackedVector2Array([
		Vector2(0.7, 1.4), Vector2(2.1, 2.55), Vector2(3.45, 3.9), Vector2(4.15, 5.25), Vector2(5.0, 8.0),
		Vector2(6.5, 11.3), Vector2(8.6, 14.0), Vector2(11.0, 16.2), Vector2(13.4, 19.2), Vector2(14.6, 22.4),
		Vector2(15.4, 25.6),
	]),
	# 1) Ahıra giden yol: sağdaki yurdun kapı önünden sağa kıvrılır, sağ kenardaki çamların önünden
	#    kuzeye döner ve ahırın doğu ucunun önünde biter.
	PackedVector2Array([
		Vector2(5.15, -3.17), Vector2(7.11, -1.49), Vector2(9.51, -2.09), Vector2(12.48, -5.16), Vector2(14.2, -9.67),
		Vector2(14.1, -10.45),
	]),
]:
	set(value):
		paths = value
		_mark_dirty()
## Her patikanın genişliği (metre). Eksikse default_width kullanılır.
@export var widths := PackedFloat32Array([1.3, 1.2]):
	set(value):
		widths = value
		_mark_dirty()
@export var default_width := 1.2:
	set(value):
		default_width = value
		_mark_dirty()
## Serbest uçta daralmanın uzunluğu (metre) ve uçtaki genişlik oranı.
@export var end_taper := 2.6:
	set(value):
		end_taper = value
		_mark_dirty()
@export_range(0.1, 1.0) var end_width_scale := 0.45:
	set(value):
		end_width_scale = value
		_mark_dirty()
## Arazi düğümü (malzemesine patika parametreleri yazılır).
@export var terrain_path: NodePath = ^"../Terrain"
## Çakıl taşlarının oturtulacağı arazinin tohumu (Terrain.seed_value ile aynı olmalı).
@export var terrain_seed := 1207
@export var pebble_seed := 41
## Patikanın her metresi için kenarlara serpilen çakıl sayısı.
@export var pebbles_per_meter := 2.4
@export_tool_button("Yeniden oluştur", "Reload") var rebuild_button: Callable = rebuild

## Yumuşatılmış doğru parçaları: Vector4(ax, az, bx, bz) ve her parçanın yarı genişliği.
var _segments: Array[Vector4] = []
var _half_widths := PackedFloat32Array()
var _dirty := true
var _rebuild_queued := false
var _terrain_retries := 0
## Hızlı sorgu ızgarası: Vector2i hücre → o hücreye yakın parçaların sırası.
var _index := {}


func _enter_tree() -> void:
	add_to_group(GROUP)


func _ready() -> void:
	rebuild()


## Sahnedeki (ilk) patika ağını bulur; yoksa null.
static func find_in_tree(tree: SceneTree) -> PathNetwork:
	if tree == null:
		return null
	for node in tree.get_nodes_in_group(GROUP):
		if node is PathNetwork:
			return node
	return null


## Parçaları yeniden hesaplar, araziye gönderir ve çakılları yeniden serper.
func rebuild() -> void:
	_rebuild_queued = false
	_dirty = true
	_ensure_segments()
	if not is_inside_tree():
		return
	_terrain_retries = 0
	_apply_to_terrain()
	for child in get_children():
		if child.has_meta(&"generated"):
			remove_child(child)
			child.queue_free()
	_build_pebbles()


## Yumuşatılmış parçalar (Vector4(ax, az, bx, bz)).
func get_segments() -> Array[Vector4]:
	_ensure_segments()
	return _segments


## Parçaların yarı genişlikleri (get_segments() ile aynı sırada).
func get_half_widths() -> PackedFloat32Array:
	_ensure_segments()
	return _half_widths


## Noktanın en yakın patika KENARINA işaretli uzaklığı (metre):
## patikanın içinde eksi, kenarda 0, dışarıda artı. Patika yoksa INF.
func distance_to_paths(p: Vector2) -> float:
	_ensure_segments()
	return signed_distance(p, _segments, _half_widths)


## distance_to_paths() ile aynı, ama limit'ten uzak noktalar için doğrudan limit döner.
## Izgara kullandığı için çok hızlıdır (çayır on binlerce nokta sorar). limit en fazla INDEX_REACH olabilir.
func distance_to_paths_clamped(p: Vector2, limit: float = 1.0) -> float:
	_ensure_segments()
	var reach := minf(limit, INDEX_REACH)
	var key := Vector2i(floori(p.x / INDEX_CELL), floori(p.y / INDEX_CELL))
	var ids: PackedInt32Array = _index.get(key, PackedInt32Array())
	var best := reach
	for i in ids:
		var s := _segments[i]
		best = minf(best, distance_to_segment(p, Vector2(s.x, s.y), Vector2(s.z, s.w)) - _half_widths[i])
	return best


## Noktanın bir doğru parçasına (a-b) uzaklığı.
static func distance_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var len_sq := ab.length_squared()
	if len_sq < 0.000001:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / len_sq, 0.0, 1.0)
	return p.distance_to(a + ab * t)


## Parça listesine işaretli kenar uzaklığı (saf fonksiyon). Parça yoksa INF.
static func signed_distance(p: Vector2, segments: Array[Vector4], half_widths: PackedFloat32Array) -> float:
	var best := INF
	for i in segments.size():
		var s := segments[i]
		best = minf(best, distance_to_segment(p, Vector2(s.x, s.y), Vector2(s.z, s.w)) - half_widths[i])
	return best


## Köşe noktalarından geçen yumuşak eğriyi sık örnekler (Catmull-Rom). Uç noktalar korunur.
static func smooth_polyline(points: PackedVector2Array, samples_per_span: int = 8) -> PackedVector2Array:
	var n := points.size()
	if n < 3:
		return points.duplicate()
	var result := PackedVector2Array()
	for i in n - 1:
		var p0 := points[maxi(i - 1, 0)] if i > 0 else points[0] * 2.0 - points[1]
		var p1 := points[i]
		var p2 := points[i + 1]
		var p3 := points[i + 2] if i + 2 < n else points[n - 1] * 2.0 - points[n - 2]
		for k in samples_per_span:
			result.append(p1.cubic_interpolate(p2, p0, p3, float(k) / float(samples_per_span)))
	result.append(points[n - 1])
	return result


## Çoklu çizginin toplam uzunluğu.
static func polyline_length(points: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(1, points.size()):
		total += points[i].distance_to(points[i - 1])
	return total


## Çoklu çizgiyi yay uzunluğuna göre eşit aralıklı count + 1 noktaya böler.
static func resample(points: PackedVector2Array, count: int) -> PackedVector2Array:
	var result := PackedVector2Array()
	if points.size() < 2 or count < 1:
		return points.duplicate()
	var total := polyline_length(points)
	var step := total / float(count)
	result.append(points[0])
	var walked := 0.0
	var target := step
	for i in range(1, points.size()):
		var a := points[i - 1]
		var b := points[i]
		var seg := a.distance_to(b)
		while seg > 0.0 and walked + seg >= target - 0.00001 and result.size() < count:
			result.append(a.lerp(b, (target - walked) / seg))
			target += step
		walked += seg
	result.append(points[points.size() - 1])
	return result


## Her patikaya düşen parça sayısı: uzunlukla orantılı, en az 2, toplamı en fazla budget.
static func allocate_segments(lengths: PackedFloat32Array, budget: int) -> PackedInt32Array:
	var counts := PackedInt32Array()
	counts.resize(lengths.size())
	var total := 0.0
	for l in lengths:
		total += l
	if lengths.is_empty() or total <= 0.0:
		return counts
	var used := 0
	for i in lengths.size():
		counts[i] = maxi(2, floori(float(budget) * lengths[i] / total))
		used += counts[i]
	# Bütçe aşıldıysa en uzun parçalı patikalardan, kaldıysa en kaba olanlara ekle/çıkar.
	while used > budget:
		var best := -1
		for i in counts.size():
			if counts[i] > 2 and (best < 0 or lengths[i] / counts[i] < lengths[best] / counts[best]):
				best = i
		if best < 0:
			break
		counts[best] -= 1
		used -= 1
	while used < budget:
		var coarsest := 0
		for i in counts.size():
			if lengths[i] / counts[i] > lengths[coarsest] / counts[coarsest]:
				coarsest = i
		counts[coarsest] += 1
		used += 1
	return counts


## Patikaları yumuşatıp parçalara böler: [Array[Vector4] parçalar, PackedFloat32Array yarı genişlikler].
static func build_segments(p_paths: Array[PackedVector2Array], p_widths: PackedFloat32Array, p_default_width: float,
		taper_length: float, taper_scale: float, budget: int = MAX_SEGMENTS) -> Array:
	var curves: Array[PackedVector2Array] = []
	var lengths := PackedFloat32Array()
	for path in p_paths:
		if path.size() < 2:
			continue
		var curve := smooth_polyline(path)
		curves.append(curve)
		lengths.append(polyline_length(curve))
	var counts := allocate_segments(lengths, budget)
	var segments: Array[Vector4] = []
	var half_widths := PackedFloat32Array()
	var curve_index := 0
	for path_index in p_paths.size():
		if p_paths[path_index].size() < 2:
			continue
		var width := p_widths[path_index] if path_index < p_widths.size() else p_default_width
		var points := resample(curves[curve_index], counts[curve_index])
		var length := lengths[curve_index]
		var walked := 0.0
		for i in points.size() - 1:
			var a := points[i]
			var b := points[i + 1]
			var seg := a.distance_to(b)
			var to_end := length - (walked + seg * 0.5)
			var taper := lerpf(taper_scale, 1.0, smoothstep(0.0, maxf(taper_length, 0.001), to_end))
			segments.append(Vector4(a.x, a.y, b.x, b.y))
			half_widths.append(width * 0.5 * taper)
			walked += seg
		curve_index += 1
	return [segments, half_widths]


## Parça gruplarının kutuları: Vector4(min_x, min_z, max_x, max_z), kenar payı dahil.
static func group_bounds(segments: Array[Vector4], half_widths: PackedFloat32Array, group_size: int, margin: float) -> Array[Vector4]:
	var result: Array[Vector4] = []
	var g := 0
	while g * group_size < segments.size():
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for i in range(g * group_size, mini((g + 1) * group_size, segments.size())):
			var s := segments[i]
			var pad := half_widths[i] + margin
			lo = Vector2(minf(lo.x, minf(s.x, s.z) - pad), minf(lo.y, minf(s.y, s.w) - pad))
			hi = Vector2(maxf(hi.x, maxf(s.x, s.z) + pad), maxf(hi.y, maxf(s.y, s.w) + pad))
		result.append(Vector4(lo.x, lo.y, hi.x, hi.y))
		g += 1
	return result


# --- İç işler ---------------------------------------------------------------

## Veriler değişti: parçaları geçersiz say; sahnedeysek (ör. editörde) aynı karedeki
## değişiklikleri tek bir yeniden kurulumda topla.
func _mark_dirty() -> void:
	_dirty = true
	if is_inside_tree() and not _rebuild_queued:
		_rebuild_queued = true
		rebuild.call_deferred()


func _ensure_segments() -> void:
	if not _dirty:
		return
	_dirty = false
	var built := build_segments(paths, widths, default_width, end_taper, end_width_scale)
	_segments = built[0]
	_half_widths = built[1]
	_build_index()


## Her ızgara hücresine, INDEX_REACH mesafesine girebilecek parçaları kaydeder.
func _build_index() -> void:
	_index.clear()
	for i in _segments.size():
		var s := _segments[i]
		var pad := _half_widths[i] + INDEX_REACH
		var x0 := floori((minf(s.x, s.z) - pad) / INDEX_CELL)
		var x1 := floori((maxf(s.x, s.z) + pad) / INDEX_CELL)
		var z0 := floori((minf(s.y, s.w) - pad) / INDEX_CELL)
		var z1 := floori((maxf(s.y, s.w) + pad) / INDEX_CELL)
		for cx in range(x0, x1 + 1):
			for cz in range(z0, z1 + 1):
				# Hücre merkezinden parçaya uzaklık: hücre yarı köşegeni + erişim payı içinde mi?
				var center := Vector2((cx + 0.5) * INDEX_CELL, (cz + 0.5) * INDEX_CELL)
				var d := distance_to_segment(center, Vector2(s.x, s.y), Vector2(s.z, s.w)) - _half_widths[i]
				if d > INDEX_REACH + INDEX_CELL * 0.7072:
					continue
				var key := Vector2i(cx, cz)
				var ids: PackedInt32Array = _index.get(key, PackedInt32Array())
				ids.append(i)
				_index[key] = ids


## Arazi shader'ına yazılacak değerler (saf fonksiyon): parametre adı → değer.
## Diziler shader boyutuna (MAX_SEGMENTS, MAX_GROUPS) tamamlanır; sınırı aşan parçalar kırpılır
## (her patika en az 2 parça aldığından çok sayıda patika bütçeyi aşabilir). Boş kutu: (1, 1, -1, -1).
static func shader_parameters(segments: Array[Vector4], half_widths: PackedFloat32Array) -> Dictionary:
	var count := mini(segments.size(), MAX_SEGMENTS)
	var segs: Array[Vector4] = []
	segs.assign(segments.slice(0, count))
	var halves := half_widths.slice(0, count)
	var groups := group_bounds(segs, halves, GROUP_SIZE, BOUNDS_MARGIN)
	var bounds := Vector4(1.0, 1.0, -1.0, -1.0)
	if count > 0:
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for g in groups:
			lo = Vector2(minf(lo.x, g.x), minf(lo.y, g.y))
			hi = Vector2(maxf(hi.x, g.z), maxf(hi.y, g.w))
		bounds = Vector4(lo.x, lo.y, hi.x, hi.y)
	while segs.size() < MAX_SEGMENTS:
		segs.append(Vector4.ZERO)
		halves.append(0.0)
	while groups.size() < MAX_GROUPS:
		groups.append(Vector4(1.0, 1.0, -1.0, -1.0))
	return {
		"path_segments": segs,
		"path_half_widths": halves,
		"path_group_bounds": groups,
		"path_segment_count": count,
		"path_bounds": bounds,
	}


## Parçaları arazi shader'ının dizilerine yazar.
func _apply_to_terrain() -> void:
	var terrain := get_node_or_null(terrain_path) as Terrain
	if terrain == null:
		return
	if terrain.material == null:
		# Arazi henüz malzemesini kurmadıysa birkaç kez sonraki karede yeniden dene.
		_terrain_retries += 1
		if _terrain_retries < 30:
			_apply_to_terrain.call_deferred()
		return
	if _segments.size() > MAX_SEGMENTS:
		push_warning("PathNetwork: %d parça var ama arazi shader'ı en fazla %d parça çizebilir; fazlası çizilmiyor." % [_segments.size(), MAX_SEGMENTS])
	var params := shader_parameters(_segments, _half_widths)
	for key: String in params:
		terrain.material.set_shader_parameter(key, params[key])


## Çakıl yerleşimi (saf ve belirlenimci): üç biçim için Transform3D listeleri.
## Çakılların çoğu patika kenarında, bir kısmı yürünmüş yolun içindedir.
func pebble_transforms(shape: TerrainShape) -> Array:
	_ensure_segments()
	var buckets: Array = [[], [], []]
	if pebbles_per_meter <= 0.0:
		return buckets
	var rng := RandomNumberGenerator.new()
	rng.seed = pebble_seed
	for i in _segments.size():
		var s := _segments[i]
		var a := Vector2(s.x, s.y)
		var b := Vector2(s.z, s.w)
		var length := a.distance_to(b)
		if length < 0.01:
			continue
		var along := (b - a) / length
		var side := Vector2(-along.y, along.x)
		var count := int(round(length * pebbles_per_meter * rng.randf_range(0.7, 1.3)))
		for k in count:
			var t := rng.randf()
			var edge := rng.randf() < 0.78
			var offset := _half_widths[i] + rng.randf_range(-0.22, 0.12) if edge else rng.randf_range(0.0, _half_widths[i] * 0.8)
			var p := a.lerp(b, t) + side * offset * (1.0 if rng.randf() < 0.5 else -1.0)
			var size := rng.randf_range(0.035, 0.085) if edge else rng.randf_range(0.025, 0.05)
			if rng.randf() < 0.06:
				size *= 1.6
			var pebble_basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(size, size * rng.randf_range(0.45, 0.7), size))
			buckets[rng.randi() % 3].append(Transform3D(pebble_basis, Vector3(p.x, shape.height_at(p.x, p.y) - size * 0.15, p.y)))
	return buckets


## Patika kenarlarına küçük, açık renkli çakıllar serper (3 biçim, her biri bir MultiMesh).
func _build_pebbles() -> void:
	if _segments.is_empty():
		return
	var buckets := pebble_transforms(TerrainShape.new(terrain_seed))
	# Açık gri-bej çakıl: lekeler taşın kendi renginden yalnızca biraz açık (çiçek gibi parlamasın), yosunsuz.
	var mat := ShaderMaterial.new()
	mat.shader = PEBBLE_SHADER
	mat.set_shader_parameter("rock_color", Color(0.68, 0.64, 0.57))
	mat.set_shader_parameter("blotch_color", Color(0.78, 0.75, 0.68))
	mat.set_shader_parameter("speck_amount", 0.2)
	mat.set_shader_parameter("moss_amount", 0.0)
	var meshes: Array[Mesh] = [MeshKit.rock(911, 1, 0.3), MeshKit.rock(912, 1, 0.4), MeshKit.rock(913, 1, 0.35)]
	for v in 3:
		var transforms: Array[Transform3D] = []
		transforms.assign(buckets[v])
		if transforms.is_empty():
			continue
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Pebbles%d" % v
		mmi.multimesh = Scatter.make_multimesh(meshes[v], transforms)
		mmi.material_override = mat
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mmi.set_meta(&"generated", true)
		add_child(mmi)
