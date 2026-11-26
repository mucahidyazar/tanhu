class_name GrassField
extends Node3D
## İç haritanın akan çimeni (godot.md §4.5 «Çimen»; Yol Haritası grass-streaming): oyuncunun (kameranın baktığı yerin) çevresinde chunk
## metrelik parçalar yaşar. Parçanın örnek dizisi (12 dönüşüm + 4 özel veri; MapBake.instance_buffer düzeni) tohumdan ve arazi verisinden
## (HeightmapShape, zemin maskesi) WorkerThreadPool'da kurulur; ana iş parçacığında MultiMesh.buffer bir atamayla yazılır (örnek başına
## çağrı yok). Uzaklaşan parçanın MultiMeshInstance3D'si havuza döner, yeni parça onu yeniden kullanır. Uzakta solma gölgelendiricidedir
## (atw_grass fade_start/fade_end: boyla); görünürlük aralığının saydam solması kullanılmaz (Godot belgesi: saydam geçişe zorlar).
##
## Tür (def.kind): «meadow» bahar otu (deneme haritası; maskenin açık toprağında, kumunda ve çakılında seyrek, koyu otlukta sık), «dry»
## Kışlak'ın kar altındaki çimeni: yalnız karın inceldiği yerde (ezik yerin ve yolun kıyısı, sazlık, rüzgârın açtığı tümsek) kuru tutam
## çıkar; sazlıkta uzun sap. Aynı tohum aynı parçayı verir (parça anahtarı tohuma girer): parça bırakılıp yeniden kurulunca değişmez.
##   var grass := GrassField.new()
##   grass.setup(ground, spec.grass, mask, mask_rect, blockers, cover)
##   world.add_child(grass)
##   grass.focus = player.global_position     # ya da follow = Callable(...) her kare sorar

## Parça başına en çok iş (aynı karede kurulan) ve havuzun tavanı.
const MAX_JOBS := 4
const POOL_MAX := 64
## Parçanın bırakılma payı (m): yarıçapın bu kadar ötesine geçen parça havuza döner (sınırda titreme olmasın).
const HYSTERESIS := 10.0
const FLOATS := 16

## Odak (dünya x, z): parçalar bunun çevresinde yaşar. follow verilmişse her kare ondan alınır.
var focus := Vector3.ZERO
var follow: Callable
var shape: HeightmapShape
var def: Dictionary = {}
var chunk := 24.0
var radius := 60.0
## Canlı parçalar: Vector2i → [MultiMeshInstance3D, ...] (çeşit başına); havuz: çeşit → [MultiMeshInstance3D].
var live: Dictionary = {}
var pool: Dictionary = {}
## Sayaçlar (sınama ve ölçüm): kurulan parça, havuzdan alınan, havuza dönen, buffer yazımı.
var stats := {"built": 0, "reused": 0, "released": 0, "writes": 0, "instances": 0}

var _material: ShaderMaterial
var _meshes: Array[Mesh] = []
var _mask := PackedByteArray()
var _mask_size := Vector2i.ZERO
var _mask_rect := Vector4.ZERO
var _cover := PackedByteArray()
var _cover_size := Vector2i.ZERO
var _blockers: Array[Vector3] = []
var _jobs: Dictionary = {}
var _seed := 91


## Kurar (ağaca girmeden önce): yükseklik yüzü, map.json «grass», zemin maskesi (RGBA8) ve dikdörtgeni, engeller (otun çıkmadığı daireler),
## örtü (Kışlak'ın cover'ı: saz B'de; yoksa null).
func setup(p_shape: HeightmapShape, p_def: Dictionary, mask: Image, mask_rect: Vector4, blockers: Array[Vector3] = [], cover: Image = null) -> void:
	shape = p_shape
	def = p_def
	chunk = float(def.get("chunk", 24.0))
	radius = float(def.get("radius", 60.0))
	_seed = int(def.get("seed", 91))
	_blockers = blockers
	if mask:
		var m := mask.duplicate() as Image
		if m.get_format() != Image.FORMAT_RGBA8:
			m.convert(Image.FORMAT_RGBA8)
		_mask = m.get_data()
		_mask_size = Vector2i(m.get_width(), m.get_height())
	_mask_rect = mask_rect
	if cover:
		var c := cover.duplicate() as Image
		if c.get_format() != Image.FORMAT_RGBA8:
			c.convert(Image.FORMAT_RGBA8)
		_cover = c.get_data()
		_cover_size = Vector2i(c.get_width(), c.get_height())
	_build_material()


func _ready() -> void:
	set_process(true)


func _exit_tree() -> void:
	for key: Vector2i in _jobs.keys():
		WorkerThreadPool.wait_for_task_completion(int((_jobs[key] as Dictionary)["task"]))
	_jobs.clear()


func _process(_delta: float) -> void:
	if follow.is_valid():
		var f: Variant = follow.call()
		if f is Vector3:
			focus = f
	update()


## Parçaları odağa göre günceller: biten işler yazılır, uzaklaşan parça havuza döner, eksik parça için iş açılır (en yakından).
func update() -> void:
	_collect()
	var center := Vector2(focus.x, focus.z)
	for key: Vector2i in live.keys():
		if chunk_center(key).distance_to(center) > radius + chunk * 0.71 + HYSTERESIS:
			_release(key)
	var wanted := wanted_keys(center)
	# Başsızın eşzamanlı kurulumu da karede en çok MAX_JOBS parçadır.
	var made := 0
	for key in wanted:
		if _jobs.size() + made >= MAX_JOBS:
			break
		if live.has(key) or _jobs.has(key):
			continue
		_start(key)
		if not _jobs.has(key):
			made += 1


## Odak çevresindeki parçalar (yarıçapın içindekiler, en yakın önce).
func wanted_keys(center: Vector2) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var n := ceili(radius / chunk) + 1
	var c := Vector2i(floori(center.x / chunk), floori(center.y / chunk))
	for dz in range(-n, n + 1):
		for dx in range(-n, n + 1):
			var key := c + Vector2i(dx, dz)
			if chunk_center(key).distance_to(center) <= radius + chunk * 0.71:
				out.append(key)
	out.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return chunk_center(a).distance_squared_to(center) < chunk_center(b).distance_squared_to(center))
	return out


func chunk_center(key: Vector2i) -> Vector2:
	return (Vector2(key) + Vector2(0.5, 0.5)) * chunk


## Bütün işler bitene dek bekler ve yazar (sınama; kurulumda perde karayken).
func flush() -> void:
	for key: Vector2i in _jobs.keys():
		WorkerThreadPool.wait_for_task_completion(int((_jobs[key] as Dictionary)["task"]))
		(_jobs[key] as Dictionary)["joined"] = true
	_collect(true)


## Görünen örnek sayısı (canlı parçaların toplamı).
func instance_count() -> int:
	var n := 0
	for key: Vector2i in live:
		for mmi: MultiMeshInstance3D in live[key]:
			n += mmi.multimesh.instance_count if mmi.visible else 0
	return n


# --- İş ---------------------------------------------------------------------------------------------

func _start(key: Vector2i) -> void:
	# Başsızda iş parçacığı yok (FaunaMesh.background_loads'un kuralı: boş çizicinin kimlikleri iş parçacığına karşı korunmuyor; iş parçacığı
	# sürerken ana iş parçacığının çizim çağrısı «Parameter "t" is null» yazıyordu): parça aynı karede kurulur ve yazılır.
	if not FaunaMesh.background_loads():
		_place(key, build_chunk(key))
		return
	var job := {"result": []}
	var builder := func() -> void: job["result"] = build_chunk(key)
	job["task"] = WorkerThreadPool.add_task(builder, false, "GrassField parça")
	_jobs[key] = job


func _collect(all: bool = false) -> void:
	for key: Vector2i in _jobs.keys():
		var job: Dictionary = _jobs[key]
		if not bool(job.get("joined", false)):
			if not all and not WorkerThreadPool.is_task_completed(int(job["task"])):
				continue
			WorkerThreadPool.wait_for_task_completion(int(job["task"]))
		_jobs.erase(key)
		_place(key, job["result"])


## Parçayı yazar: çeşit başına havuzdan bir MultiMeshInstance3D, buffer tek atama.
func _place(key: Vector2i, buffers: Array) -> void:
	var nodes: Array = []
	for v in buffers.size():
		var buf: PackedFloat32Array = buffers[v]
		if buf.is_empty():
			continue
		var mmi := _take(v)
		var mm := mmi.multimesh
		mm.instance_count = buf.size() / FLOATS
		mm.buffer = buf
		stats["writes"] = int(stats["writes"]) + 1
		stats["instances"] = int(stats["instances"]) + mm.instance_count
		mmi.visible = true
		mmi.set_meta(&"key", key)
		nodes.append(mmi)
	live[key] = nodes
	stats["built"] = int(stats["built"]) + 1


func _release(key: Vector2i) -> void:
	for mmi: MultiMeshInstance3D in live.get(key, []):
		mmi.visible = false
		var v := int(mmi.get_meta(&"variant", 0))
		var list: Array = pool.get(v, [])
		if list.size() < POOL_MAX:
			list.append(mmi)
			pool[v] = list
		else:
			mmi.queue_free()
	live.erase(key)
	stats["released"] = int(stats["released"]) + 1


func _take(v: int) -> MultiMeshInstance3D:
	var list: Array = pool.get(v, [])
	if not list.is_empty():
		stats["reused"] = int(stats["reused"]) + 1
		return list.pop_back()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = _meshes[v]
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Grass_%d_%d" % [v, get_child_count()]
	mmi.multimesh = mm
	mmi.material_override = _material
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.set_meta(&"variant", v)
	add_child(mmi)
	return mmi


# --- Parçanın örnekleri (saf; iş parçacığında) --------------------------------------------------------

## Parçanın çeşit başına örnek dizileri (saf: yalnız kurulumda kopyalanan veriyi okur). Titreşen ızgara; yoğunluk türün kuralından.
func build_chunk(key: Vector2i) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([_seed, key.x, key.y])
	var dry := str(def.get("kind", "meadow")) == "dry"
	var density := float(def.get("density", 0.6))
	var step := 1.0 / sqrt(maxf(density, 0.0001))
	var n := ceili(chunk / step)
	var base := Vector2(key) * chunk
	var out: Array = []
	for v in _meshes.size():
		out.append(PackedFloat32Array())
	# Parçaya değen engeller (Kışlak'ta yapı kitinin izleriyle yüzü aşkın daire; her tutam yalnız bunlara bakar).
	var blockers: Array[Vector3] = []
	for b in _blockers:
		if b.x + b.z >= base.x - 0.2 and b.x - b.z <= base.x + chunk + 0.2 and b.y + b.z >= base.y - 0.2 and b.y - b.z <= base.y + chunk + 0.2:
			blockers.append(b)
	var short_h := MapSpec.vec2(def.get("short_height", [0.12, 0.26] if dry else [0.16, 0.3]))
	var tall_h := MapSpec.vec2(def.get("tall_height", [0.5, 0.9] if dry else [0.38, 0.62]))
	for iz in n:
		for ix in n:
			var p := base + (Vector2(float(ix), float(iz)) + Vector2(rng.randf(), rng.randf())) * step
			var roll := rng.randf()
			var tone := rng.randf()
			if shape and not shape.contains(p.x, p.y):
				continue
			if Scatter.is_blocked(p.x, p.y, blockers, 0.1):
				continue
			var m := _mask_at(p)
			var c := _cover_at(p)
			var w := dry_weight(m, c, roll) if dry else meadow_weight(m)
			if roll > w:
				continue
			var tall := c.z > 0.4 if dry else rng.randf() < float(def.get("tall_share", 0.28)) * (1.0 + m.w)
			var variant := _meshes.size() - 1 if tall else rng.randi() % maxi(_meshes.size() - 1, 1)
			var span := tall_h if tall else short_h
			var h := rng.randf_range(span.x, span.y)
			var wd := h * Meadow.tuft_aspect(h) * rng.randf_range(0.9, 1.15)
			var y := (shape.height_at(p.x, p.y) if shape else 0.0) - 0.02
			var buf: PackedFloat32Array = out[variant]
			buf.append_array(PackedFloat32Array([wd, 0.0, 0.0, p.x, 0.0, h, 0.0, y, 0.0, 0.0, wd, p.y, tone, rng.randf(), rng.randf(), 0.5]))
			out[variant] = buf
	return out


## Bahar otunun olasılığı (deneme haritası; MapBaker.grass_entries'in kuralı): açık toprak, kum, çakıl seyrekleştirir, koyu otluk sıklaştırır.
static func meadow_weight(m: Vector4) -> float:
	return (1.0 - 0.96 * m.x) * (1.0 - 0.9 * m.y) * (1.0 - 0.97 * m.z) * (0.75 + 0.55 * m.w)


## Kışlak'ın kuru tutamı (saf): maske Vector4(kar, toprak, yol, kabuk), örtü Vector4(buz, kaya, saz, orman). Kar inceldiği yerde (ezik
## yerin ve yolun kıyısı: toprak ya da yol 0,15–0,6), sazlıkta (uzun sap) ve açık karda çok seyrek (rüzgârın açtığı tümsek); buzda,
## kabukta, yolun ve ezik yerin ortasında yok.
static func dry_weight(m: Vector4, c: Vector4, _roll: float) -> float:
	if c.x > 0.3 or c.y > 0.5:
		return 0.0
	var edge := maxf(smoothstep(0.1, 0.3, m.y) * (1.0 - smoothstep(0.55, 0.8, m.y)), smoothstep(0.08, 0.25, m.z) * (1.0 - smoothstep(0.4, 0.6, m.z)))
	var reeds := smoothstep(0.25, 0.6, c.z)
	var open := 0.035 * (1.0 - m.w) * (1.0 - c.w * 0.6)
	return clampf(maxf(maxf(edge * 0.55, reeds * 0.9), open), 0.0, 1.0)


func _mask_at(p: Vector2) -> Vector4:
	return _sample(_mask, _mask_size, p)


func _cover_at(p: Vector2) -> Vector4:
	return _sample(_cover, _cover_size, p)


func _sample(data: PackedByteArray, size: Vector2i, p: Vector2) -> Vector4:
	if data.is_empty() or size.x < 2:
		return Vector4.ZERO
	var uv := (p - Vector2(_mask_rect.x, _mask_rect.y)) * Vector2(_mask_rect.z, _mask_rect.w)
	var ix := clampi(int(roundf(uv.x * float(size.x - 1))), 0, size.x - 1)
	var iz := clampi(int(roundf(uv.y * float(size.y - 1))), 0, size.y - 1)
	var k := (iz * size.x + ix) * 4
	return Vector4(data[k], data[k + 1], data[k + 2], data[k + 3]) / 255.0


# --- Görünüş ----------------------------------------------------------------------------------------

func _build_material() -> void:
	_material = ShaderMaterial.new()
	_material.shader = MapWorld.GRASS_SHADER
	_material.set_shader_parameter(&"instance_patches", true)
	var colors: Dictionary = def.get("colors", {})
	for key: String in colors:
		_material.set_shader_parameter(StringName(key), SkyRig.to_color(colors[key]))
	_material.set_shader_parameter(&"wind_strength", float(def.get("wind_strength", 0.09)))
	_material.set_shader_parameter(&"fade_start", float(def.get("fade_start", radius * 0.55)))
	_material.set_shader_parameter(&"fade_end", float(def.get("fade_end", radius * 0.85)))
	_meshes.clear()
	for v in MapBaker.TUFT_VARIANTS:
		_meshes.append(Meadow.tuft_mesh(v.x, v.y, float(v.z) / 100.0, v.w, Meadow.BLADE_WIDTH.x if v.w == 1 else Meadow.BLADE_WIDTH.y))
