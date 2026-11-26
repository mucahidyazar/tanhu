class_name MapBake
extends Resource
## Pişmiş harita parçası (godot.md §4.3 madde 4): tools/bake_map.gd başsız Godot'ta üretir, dünya kurulurken okur. Ağır üretim
## (kampın arazi ağları, çayırın ve ormanın örnekleri; iç haritanın yüksekliği, arazi parçaları, otu ve navmesh karoları) çalışırken
## yeniden yapılmaz: dünyanın kurulumu ağı ve örnek dizisini dosyadan alır.
##
## Her parça girdilerinin imzasını taşır (signature_of: ayarlar, engeller, patikalar, biçimin örnek noktaları...). Dünyanın o anki
## girdileriyle hesaplanan imza tutmazsa parça kullanılmaz, dünya kendisi üretir: yavaş ama doğru yol (geliştirme koşusunda bir kez
## uyarı yazılır: «tools/bake_map.gd ile yeniden pişir»). Girdilerin aynı kaldığı ama üretim kodunun değiştiği durumu
## test_map_bake.gd yakalar: pişmiş parçayı taze üretimle karşılaştırır.
##
## Dosyalar data/maps/<harita>/baked/<parça>.res'tedir (ikili kaynak; ağlar gömülüdür). MultiMesh örnekleri ham dizi olarak durur
## (instance_buffer): başsız Godot'nun boş çizim sunucusu MultiMesh örneklerini saklamaz, pişirme diziyi kendisi kurar.
##   var bake := MapBake.fetch("camp", "terrain", signature)   # yoksa ya da tutmazsa null
##   MapBake.store(bake, MapBake.path_for("camp", "terrain"))   # yalnız pişirme aracı

## Biçimin sürümü: alanların anlamı değişirse artar (eski dosyalar okunmaz).
const VERSION := 1
const ROOT := "res://data/maps"

## İmzanın biçim noktaları (probe_shape): kamptan 3,6 km'ye dek halkalar × beş yön. Arazi biçiminin kodu değişirse
## yükseklik değişir, imza tutmaz.
const PROBE_RADII: Array[float] = [0.6, 2.0, 6.0, 14.0, 30.0, 60.0, 120.0, 300.0, 800.0, 2000.0, 3500.0]
const PROBE_ANGLES: Array[float] = [0.0, 1.3, 2.6, 3.9, 5.2]

## Pişmiş parçaların kullanılıp kullanılmadığı (sınama ve pişirme aracı kapatır: taze üretim).
static var enabled := true
## Pişirme aracı açar: dünyanın parçaları üretirken ham dizilerini (MultiMesh örnekleri) bake_payload için saklar.
static var capture := false
## Bu koşuda imzası tutmayan parçalar (aynı uyarı bir kez yazılır).
static var _warned: Dictionary = {}

## Parçanın türü (kamp: terrain, meadow, forest; iç harita: ground, chunks, grass, nav) ve haritası.
@export var kind := ""
@export var map_id := ""
## Girdilerin imzası (signature_of).
@export var signature := ""
@export var version := VERSION
## Gömülü ağlar (sırası parçanın kendi düzenidir; data'daki adlar ve sıralar ona başvurur).
@export var meshes: Array[Mesh] = []
## Parçanın verisi (ham diziler, adlar, ölçüler).
@export var data: Dictionary = {}


## Parçanın dosya yolu (saf).
static func path_for(p_map_id: String, p_kind: String) -> String:
	return "%s/%s/baked/%s.res" % [ROOT, p_map_id, p_kind]


## Pişmiş parça: dosya varsa, sürümü ve imzası tutuyorsa (signature boşsa imza sorulmaz). Yoksa null. Kaynak önbellekteyse (WorldHost
## arka planda istediyse) diske gidilmez.
static func fetch(p_map_id: String, p_kind: String, p_signature: String = "") -> MapBake:
	if not enabled:
		return null
	var path := path_for(p_map_id, p_kind)
	if not ResourceLoader.exists(path):
		return null
	var bake := load(path) as MapBake
	if bake == null or bake.version != VERSION:
		_warn_once(path, "sürümü eski")
		return null
	if not p_signature.is_empty() and bake.signature != p_signature:
		_warn_once(path, "imzası tutmuyor (girdiler değişti)")
		return null
	return bake


## Pişmiş parçayı yazar (pişirme aracı). Döner: Error.
static func store(bake: MapBake, path: String) -> Error:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	bake.version = VERSION
	return ResourceSaver.save(bake, path)


## Girdilerin imzası (saf): girdiler var_to_bytes ile dizilir, MD5'in onaltılık yazısı. Kayan sayılar bit bit girer: aynı girdi aynı imza.
static func signature_of(inputs: Array) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_MD5)
	ctx.update(var_to_bytes(inputs))
	return ctx.finish().hex_encode()


## MultiMesh'in ham örnek dizisi (saf; MultiMesh.buffer düzeni): örnek başına 12 kayan sayı (dönüşümün satırları: basis.x.x, basis.y.x,
## basis.z.x, origin.x, ...), custom verilmişse ardından 4 (r, g, b, a). Boş çizim sunucusunda da kurulur.
static func instance_buffer(transforms: Array, custom: Array = []) -> PackedFloat32Array:
	var stride := 12 + (4 if not custom.is_empty() else 0)
	var buf := PackedFloat32Array()
	buf.resize(transforms.size() * stride)
	var k := 0
	for i in transforms.size():
		var t: Transform3D = transforms[i]
		var b := t.basis
		buf[k] = b.x.x
		buf[k + 1] = b.y.x
		buf[k + 2] = b.z.x
		buf[k + 3] = t.origin.x
		buf[k + 4] = b.x.y
		buf[k + 5] = b.y.y
		buf[k + 6] = b.z.y
		buf[k + 7] = t.origin.y
		buf[k + 8] = b.x.z
		buf[k + 9] = b.y.z
		buf[k + 10] = b.z.z
		buf[k + 11] = t.origin.z
		if stride == 16:
			var c: Color = custom[i]
			buf[k + 12] = c.r
			buf[k + 13] = c.g
			buf[k + 14] = c.b
			buf[k + 15] = c.a
		k += stride
	return buf


## Ham diziden MultiMesh (instance_buffer'ın tersi): dizi tek atamayla gider (örnek başına çağrı yok). with_custom: dizi custom taşıyor mu.
static func multimesh_from(mesh: Mesh, buffer: PackedFloat32Array, with_custom: bool) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = with_custom
	mm.mesh = mesh
	var stride := 16 if with_custom else 12
	mm.instance_count = buffer.size() / stride
	if mm.instance_count > 0:
		mm.buffer = buffer
	return mm


## Ham dizinin i. örneğinin dönüşümü (saf; sınama ve engel hesabı).
static func buffer_transform(buffer: PackedFloat32Array, i: int, with_custom: bool) -> Transform3D:
	var k := i * (16 if with_custom else 12)
	return Transform3D(
		Vector3(buffer[k], buffer[k + 4], buffer[k + 8]),
		Vector3(buffer[k + 1], buffer[k + 5], buffer[k + 9]),
		Vector3(buffer[k + 2], buffer[k + 6], buffer[k + 10]),
		Vector3(buffer[k + 3], buffer[k + 7], buffer[k + 11]))


## Düğümün betiğinin değişmezleri ve dışa açık ayarları (saf olmayan ama yan etkisiz): [ad, değer] çiftleri adla sıralı. Nesne
## (önceden yüklenen gölgelendirici, düğüm) ve çağrılabilir (araç düğmesi) değerler girmez: imza koşudan koşuya aynı kalır.
static func script_inputs(obj: Object) -> Array:
	var out: Array = []
	var script := obj.get_script() as Script
	if script:
		out.append_array(script_constants(script))
	var props: Array = []
	for p: Dictionary in obj.get_property_list():
		var usage := int(p["usage"])
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE == 0 or usage & PROPERTY_USAGE_STORAGE == 0:
			continue
		var value: Variant = obj.get(p["name"])
		if _plain(value):
			props.append([str(p["name"]), value])
	props.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	out.append_array(props)
	return out


## Betiğin değişmezleri (saf): [ad, değer] çiftleri adla sıralı, nesneler hariç.
static func script_constants(script: Script) -> Array:
	# Adlar yazıya çevrilip sıralanır: StringName dizisinin sırası koşudan koşuya değişir (karşılaştırma yazıyla değildir).
	var by_name := {}
	var consts := script.get_script_constant_map()
	for k: Variant in consts:
		by_name[str(k)] = consts[k]
	var names: Array[String] = []
	names.assign(by_name.keys())
	names.sort()
	var out: Array = []
	for n in names:
		if _plain(by_name[n]):
			out.append([n, by_name[n]])
	return out


## Biçimin örnek noktalarındaki yükseklikler (ve verilirse aynı noktalarda öteki saf sorgular: method adları; ör. vertex_tint).
static func probe_shape(shape: Object, methods: Array[StringName] = [&"height_at"]) -> Array:
	var out: Array = []
	for r in PROBE_RADII:
		for a in PROBE_ANGLES:
			var x := r * cos(a)
			var z := r * sin(a)
			for m in methods:
				out.append(shape.call(m, x, z))
	return out


## Uyarılan parçaları unutur (sınama).
static func reset_warnings() -> void:
	_warned.clear()


static func _plain(value: Variant) -> bool:
	var t := typeof(value)
	if t == TYPE_OBJECT or t == TYPE_CALLABLE or t == TYPE_SIGNAL or t == TYPE_RID:
		return false
	if t == TYPE_ARRAY:
		for v: Variant in value:
			if not _plain(v):
				return false
	elif t == TYPE_DICTIONARY:
		for k: Variant in value:
			if not _plain(k) or not _plain(value[k]):
				return false
	return true


static func _warn_once(path: String, why: String) -> void:
	if _warned.has(path):
		return
	_warned[path] = true
	push_warning("[map_bake] %s %s: dünya kendisi üretiyor (tools/bake_map.gd ile yeniden pişir)" % [path, why])
