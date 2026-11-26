extends SceneTree
## Haritaları önceden pişirir (godot.md §4.3 madde 4, §4.4, §4.7; Yol Haritası world-swap): başsız Godot'ta koşar, dünyayı oyunda
## kurulduğu gibi kurar ve ağır üretimin sonucunu data/maps/<harita>/baked/*.res'e yazar (MapBake). Oyun o dosyaları okur, aynı şeyi
## yeniden hesaplamaz: kampa dönüş karartma altında ≤2 sn, iç harita yüklemesi ≤6 sn (K63, K64).
##
##   kamp (--map=camp)        terrain.res  arazinin merkez diski ve 112 parçası (Terrain; 720 × 220 kutupsal ızgara)
##                            meadow.res   çayırın çimen ve çiçek kareleri (Meadow; MultiMesh örneklerinin ham dizileri)
##                            forest.res   dikilen çamlar, LOD zincirleri, uzak ve gölge düzeyi, ladinler, vadinin kareleri (Forest)
##                            preload.json kampın kurulurken yüklediği varlıklar: WorldHost onları arka planda önceden ister
##   iç harita (--map=<kimlik>; MapBaker, scripts/maps/map_baker.gd): ground.res (yükseklik, 1 m; zemin maskesi, 2 m), chunks.res (100 m'lik
##   ör. --map=testmap)       parçalar, 1, 4, 16 m düzey, dikişte etek; dış halka), grass.res (ot), nav.res (navmesh karoları, 100 m)
##
## Her parça girdilerinin imzasını taşır; girdiler (kampın düzeni, ayarlar, arazi biçimi) değişince dünya pişmiş parçayı kullanmaz, kendisi
## üretir ve geliştirme koşusunda uyarır. Üretim kodu değişince test_map_bake.gd düşer: o zaman bu araç yeniden koşulur.
##
## Çalıştırma (proje klasöründe; pencere açmaz, kum havuzunda da koşar):
##   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s res://tools/bake_map.gd -- --map=camp
##   ... -- --map=testmap      ... -- --map=all (varsayılan: kamp ve tarifi olan bütün iç haritalar)

const CAMP_SCENE := "res://scenes/world/world.tscn"
const CAMP_ID := "camp"
## Önyükleme listesine giren varlık türleri (kampın kurulumunda load() ile gelenler).
const PRELOAD_EXTENSIONS: Array[String] = ["glb", "gltf", "png", "jpg", "jpeg", "webp", "hdr", "exr", "tres", "res", "scn", "tscn", "ogg", "wav", "mp3"]
const PRELOAD_ROOTS: Array[String] = ["res://assets", "res://audio"]

var _failed := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var which := "all"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="):
			which = arg.substr(6)
	MapBake.enabled = false
	MapBake.capture = true
	var started := Time.get_ticks_msec()
	if which in ["all", CAMP_ID]:
		await _bake_camp()
	# İç haritalar: --map=<kimlik> (data/maps/<kimlik>/map.json, tür interior) ya da all ile hepsi (I. Perde'nin Kışlak'ı gelince aynı yol).
	for map_id in (_interior_maps() if which == "all" else ([] if which == CAMP_ID else [which])):
		await _bake_map(map_id)
	MapBake.capture = false
	MapBake.enabled = true
	print("[bake_map] bitti: %.1f sn, %d hata" % [(Time.get_ticks_msec() - started) / 1000.0, _failed])
	# Ocağın ses oynatıcısı ses sunucusunun iş parçacığında bırakılır: çıkışta sızıntı yazılmasın.
	await create_timer(0.3).timeout
	quit(1 if _failed > 0 else 0)


# --- Kamp ----------------------------------------------------------------------------------------

## Kamp iki kez kurulur: önce taze üretimle (parçalar pişirilir), sonra pişmiş parçalarla (üçü de kullanılmalı; o kurulumun yüklediği
## varlıklar önyükleme listesine yazılır: çam modeli artık yüklenmez, pişmiş ağ yeter).
func _bake_camp() -> void:
	var t0 := Time.get_ticks_usec()
	var world := await _build_camp()
	var build_ms := (Time.get_ticks_usec() - t0) / 1000.0
	var parts := {"terrain": world.get_node(^"Terrain"), "meadow": world.get_node(^"Meadow"), "forest": world.get_node(^"Forest")}
	for kind: String in parts:
		var node: Node = parts[kind]
		var bake: MapBake = node.call(&"bake_payload")
		bake.map_id = CAMP_ID
		_store(bake, MapBake.path_for(CAMP_ID, kind))
	print("[bake_map] kamp taze üretimle %.0f ms'de kuruldu, parçaları pişirildi" % build_ms)
	await _free_camp(world)
	MapBake.enabled = true
	MapBake.capture = false
	t0 = Time.get_ticks_usec()
	world = await _build_camp()
	var baked_ms := (Time.get_ticks_usec() - t0) / 1000.0
	for kind: String in parts:
		if not bool(world.get_node(NodePath(kind.capitalize())).get(&"used_bake")):
			_fail("kampın %s parçası pişmiş haliyle kurulmadı (imza tutmadı)" % kind)
	_write_preload_list(CAMP_ID, _cached_assets())
	print("[bake_map] kamp pişmiş parçalarla %.0f ms'de kuruldu (başsız, önyüklemesiz)" % baked_ms)
	await _free_camp(world)
	MapBake.enabled = false
	MapBake.capture = true


func _build_camp() -> World:
	var scene := load(CAMP_SCENE) as PackedScene
	var world := scene.instantiate() as World
	root.add_child(world)
	# Dağlar, orman, kayalar ve çayır ertelenmiş kurulur (engeller önce kaydolur).
	await process_frame
	while not world.is_built():
		await process_frame
	return world


func _free_camp(world: World) -> void:
	root.remove_child(world)
	world.free()
	WorldHost.clear_static_caches()
	await process_frame
	await process_frame


## Şu an önbellekte olan varlıklar (kampın kurulumunun yükledikleri): PRELOAD_ROOTS altında, PRELOAD_EXTENSIONS türünde. Model dosyası
## (glb) örneklenince önbellekten düşer: bağımlılığı (dokusu) önbellekteyse o da yazılır.
func _cached_assets() -> PackedStringArray:
	var out := PackedStringArray()
	for dir in PRELOAD_ROOTS:
		_scan(dir, out)
	out.sort()
	return out


func _scan(dir: String, out: PackedStringArray) -> void:
	for sub in DirAccess.get_directories_at(dir):
		if sub.begins_with(".") or sub.begins_with("_meshy_raw") or sub == "_reference":
			continue
		_scan(dir.path_join(sub), out)
	for f in DirAccess.get_files_at(dir):
		var ext := f.get_extension().to_lower()
		if not ext in PRELOAD_EXTENSIONS:
			continue
		var path := dir.path_join(f)
		if ResourceLoader.has_cached(path):
			out.append(path)
		elif ext in ["glb", "gltf"] and _dependency_cached(path):
			out.append(path)


static func _dependency_cached(path: String) -> bool:
	for dep in ResourceLoader.get_dependencies(path):
		var dep_path := dep.get_slice("::", dep.get_slice_count("::") - 1) if dep.contains("::") else dep
		if ResourceLoader.has_cached(dep_path):
			return true
	return false


func _write_preload_list(map_id: String, paths: PackedStringArray) -> void:
	var path := "%s/%s/baked/preload.json" % [MapBake.ROOT, map_id]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		_fail("%s yazılamadı" % path)
		return
	var doc := {
		"doc": "Haritanın kurulurken yüklediği varlıklar (tools/bake_map.gd yazar): WorldHost dünyayı kurmadan önce bunları arka planda ister, kurulum diske gitmez.",
		"map": map_id, "paths": Array(paths),
	}
	f.store_string(JSON.stringify(doc, "\t") + "\n")
	f.close()
	print("[bake_map] %s: %d varlık" % [path, paths.size()])


# --- İç haritalar --------------------------------------------------------------------------------

func _bake_map(map_id: String) -> void:
	var spec := MapSpec.find(map_id)
	if spec == null:
		_fail("haritanın tarifi yok: %s" % map_id)
		return
	var t0 := Time.get_ticks_usec()
	var bakes: Array[MapBake] = MapWorld.bake(spec)
	for bake in bakes:
		_store(bake, MapBake.path_for(map_id, bake.kind))
	print("[bake_map] %s pişirildi (%.0f ms, %d parça)" % [map_id, (Time.get_ticks_usec() - t0) / 1000.0, bakes.size()])
	await process_frame


# --- Yardımcılar ---------------------------------------------------------------------------------

## Tarifi olan iç haritalar (data/maps/*/map.json, tür interior).
func _interior_maps() -> Array[String]:
	var out: Array[String] = []
	for dir in DirAccess.get_directories_at(MapBake.ROOT):
		var spec := MapSpec.find(dir)
		if spec and spec.kind == MapSpec.KIND_INTERIOR:
			out.append(spec.id)
	out.sort()
	return out


func _store(bake: MapBake, path: String) -> void:
	var err := MapBake.store(bake, path)
	if err != OK:
		_fail("%s yazılamadı (%s)" % [path, error_string(err)])
		return
	var size := FileAccess.get_file_as_bytes(path).size()
	print("[bake_map] %s: %d ağ, %.2f MB, imza %s" % [path, bake.meshes.size(), size / 1048576.0, bake.signature.substr(0, 8)])


func _fail(message: String) -> void:
	_failed += 1
	push_error("[bake_map] " + message)
