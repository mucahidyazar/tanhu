class_name WorldHost
extends Node
## Tek dünyanın konağı (godot.md §4.1–§4.3; Yol Haritası world-swap): bellekte bir dünya durur, kamp (menü, Serbest Gez, Ev) ya da bir
## iç harita (MapWorld: deneme haritası, I. Perde'nin Kışlak'ı). main.gd kurar (Main'in çocuğu, adı "WorldHost"); dünyaları Main'in
## çocuğu olarak tutar: kampın yolu Main/World olarak kalır (sınamalar, bütçe sahnesi, sinema onu bu yolla bulur).
##
## Değişim perde karayken yapılır, sırası (godot.md §4.3):
##   1. İstek erken açılır: yeni dünyanın sahnesi, pişmiş parçaları (MapSpec.bakes; tools/bake_map.gd) ve kurulumda yüklenen varlıkları
##      (MapSpec.load_paths) ResourceLoader.load_threaded_request ile, alt iş parçacıksız (4.7.2'de use_sub_threads yükleyicide RefCounted
##      bırakır). İstekler eski dünya bırakılmadan önce açılır: disk ve ayrıştırma bırakma ve temizlikle üst üste biner.
##   2. Eski dünya bırakılır: önce world_released yayılır (Main kampa ya da haritaya tuttuğu başvuruları bırakır), sonra ağaçtan çıkar
##      (grupları hemen boşalır: yeni kampın çayırı ve ormanı eski haritanın yurtlarını engel saymaz) ve queue_free; bir kare beklenir,
##      statik önbellekler boşaltılır (clear_static_caches: MeshyProp, TreeKit, RockField, Style, World'ün LUT'u, binek koyun ağı), HUD
##      haritasının o dünyaya ait pişmiş görüntüsü unutulur (WorldMap.forget). Kamp bırakılınca gece çayırının sesi susar.
##   3. Yükleme her kare sorulur; load_threaded_get yalnız durum LOADED olunca çağrılır. Sonuçlar dünya kurulana dek tutulur (önbellekten
##      düşmesinler), sonra bırakılır.
##   4. Örnekleme ve ağaca ekleme ana iş parçacığındadır; dünya hazır olana dek beklenir (MapWorld.is_ready, World.is_built).
##   5. world_changed(dünya, tarif) yayılır; ölçüler last_swap'tadır (ms): free_ms (bırakma ve temizlik), wait_ms (kalan yükleme), build_ms
##      (örnekleme ve kurulum), total_ms; history son değişimleri tutar. Hedef: kampa dönüş ≤2 sn, iç harita ≤6 sn (K63, K64).
## Hikâyenin küçük dünyaları (Ordos, Yola Çıkış) bugün main.gd'nin kendi yoluyla kurulur, kamp bırakılmaz gizlenir (CineHost.release_camp);
## konak onlara dokunmaz. Kamp gizliyken haritaya girilirse önce gizleme geri alınır (CineHost'un anlık görüntüsü boşa düşmesin).
##   var map := await world_host.enter_map(MapSpec.find("testmap"))      # perde karayken
##   var camp := await world_host.return_to_camp()

## Eski dünya bırakılmak üzere (başvurular şimdi bırakılır) ve yeni dünya hazır (kamp: World, harita: MapWorld).
signal world_released(world: Node3D)
signal world_changed(world: Node3D, spec: MapSpec)

## Kamp düğümünün adı (Main/World).
const CAMP_NAME := &"World"
## Yüklemenin ve kurulumun bekçisi (sn): aşılırsa değişim bırakılır (dünya kurulamadı).
const LOAD_TIMEOUT := 40.0
const READY_TIMEOUT := 40.0
## Kaç değişimin ölçüsü tutulur.
const HISTORY := 8

## Dünyaların ebeveyni (Main), kamp, açık iç harita ve şu anki dünyanın tarifi.
var host: Node
var camp: World
var map_world: Node3D
var spec: MapSpec
## Kampın gizlenmesi ve sesi (sahnede CineHost; yoksa null).
var cine: CineHost
## Değişim sürüyor mu?
var busy := false
## Yükleme iş parçacığında mı (load_threaded_request)? Başsızda kapalıdır: boş çizicinin ağ ve doku kimlikleri iş parçacığına karşı
## korunmuyor (sınamada eşzamanlı yüklemeler «unimplemented base type», «Parameter "m" is null» ve kimlik sızıntısı verdi; testler.md'deki
## yük yarışı); pencerede gerçek çizici iş parçacığından kurulan kaynakları taşır, istekler paralel koşar.
var threaded := DisplayServer.get_name() != "headless"
## Son değişimin ve son değişimlerin ölçüleri.
var last_swap: Dictionary = {}
var history: Array[Dictionary] = []

var _camp_index := 0
## Bu konağın açtığı yükleme istekleri (yol → true) ve alınan kaynaklar (yol → Resource; dünya kurulana dek).
var _requests: Dictionary = {}
var _held: Dictionary = {}


## Konağı bağlar: dünyaların ebeveyni, açılıştaki kamp ve sinema konağı.
func setup(p_host: Node, p_camp: World, p_cine: CineHost = null) -> void:
	host = p_host
	camp = p_camp
	cine = p_cine
	spec = MapSpec.find(MapSpec.CAMP)
	if camp and camp.get_parent() == host:
		_camp_index = camp.get_index()


func _exit_tree() -> void:
	# Kimsenin almadığı istekler yükleyicide öksüz kalmasın (çıkışta ObjectDB sızıntısı): bitmiş olanlar alınır.
	for path: String in _requests.keys():
		if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED:
			ResourceLoader.load_threaded_get(path)
	_requests.clear()
	_held.clear()


## Şu anki dünya: açık iç harita, yoksa kamp (ikisi de yoksa null).
func current_world() -> Node3D:
	if is_instance_valid(map_world):
		return map_world
	return camp if is_instance_valid(camp) else null


## İç haritada mı?
func in_map() -> bool:
	return is_instance_valid(map_world)


## Kamp bellekte mi?
func has_camp() -> bool:
	return is_instance_valid(camp)


## İç haritaya geçer (perde karayken; beklenir): kamp ya da önceki harita bırakılır, harita arka planda yüklenir, kurulur. preloaded verilirse
## (ör. Köprü 2'nin önyüklediği Kışlak: main.take_preloaded) sahne yeniden istenmez. Döner: hazır harita (kurulamazsa null; o zaman kamp geri
## kurulur, dünya yine tektir).
func enter_map(p_spec: MapSpec, preloaded: PackedScene = null) -> Node3D:
	if busy or p_spec == null or p_spec.scene.is_empty():
		return null
	busy = true
	var t0 := Time.get_ticks_usec()
	var paths := p_spec.load_paths()
	if preloaded:
		paths.erase(p_spec.scene)
		_held[p_spec.scene] = preloaded
	_request_all(paths)
	await _release_current()
	var t_free := Time.get_ticks_usec()
	# Önyükleme listesindeki bir varlık yüklenemezse dünya yine kurulur (kurulum onu kendisi ister ya da yedeğine düşer); sahne şarttır.
	await _wait_loads(paths)
	var t_wait := Time.get_ticks_usec()
	var scene := _held.get(p_spec.scene) as PackedScene
	var node: Node3D = scene.instantiate() as Node3D if scene else null
	if node == null:
		push_warning("[world_host] harita kurulamadı: %s" % p_spec.scene)
		_held.clear()
		busy = false
		return await return_to_camp()
	node.name = StringName(p_spec.id.to_pascal_case())
	if &"spec" in node:
		node.set(&"spec", p_spec)
	host.add_child(node)
	var ready := await _wait_ready(node)
	_held.clear()
	map_world = node
	spec = p_spec
	busy = false
	_record("map", p_spec.id, t0, t_free, t_wait, ready)
	world_changed.emit(node, p_spec)
	return node


## Kampa döner (perde karayken; beklenir): iç harita bırakılır, kamp pişmiş parçalarıyla yeniden kurulur ve Main/World'e oturur. Kamp zaten
## bellekteyse hemen döner.
func return_to_camp() -> World:
	if has_camp() and not in_map():
		return camp
	if busy:
		return null
	busy = true
	var camp_spec := MapSpec.find(MapSpec.CAMP)
	var t0 := Time.get_ticks_usec()
	var paths := camp_spec.load_paths() if camp_spec else PackedStringArray()
	_request_all(paths)
	await _release_current()
	var t_free := Time.get_ticks_usec()
	await _wait_loads(paths)
	var t_wait := Time.get_ticks_usec()
	var scene_path := camp_spec.scene if camp_spec else "res://scenes/world/world.tscn"
	var scene := _held.get(scene_path) as PackedScene
	if scene == null:
		scene = load(scene_path) as PackedScene
	var node := scene.instantiate() as World
	node.name = CAMP_NAME
	host.add_child(node)
	host.move_child(node, mini(_camp_index, host.get_child_count() - 1))
	var ready := await _wait_built(node)
	_held.clear()
	camp = node
	spec = camp_spec
	busy = false
	_resume_camp_audio()
	_record("camp", MapSpec.CAMP, t0, t_free, t_wait, ready)
	world_changed.emit(node, camp_spec)
	return node


## Dünyalar arasında tutulan statik önbellekleri boşaltır (godot.md §4.3 madde 5): eski dünyanın dokuları, ağları ve malzemeleri bellekte
## kalmasın. Önbellek bir sonraki istekte yeniden dolar (kamp dönünce kendi modelleriyle). Oyuncuya ve arayüze ait olanlar (klipler,
## oyuncak yay, arayüz dokuları, kampın HUD haritası) kalır.
static func clear_static_caches() -> void:
	MeshyProp.clear_cache()
	TreeKit.clear_cache()
	RockField._hero_lods.clear()
	Style._cache.clear()
	Style._tamga_texture = null
	Style._shield_texture = null
	World._night_lut = null
	RideableSheep._herd_mesh = null


## Statik önbelleklerde kalan girdi sayısı (sınama: bırakınca 0).
static func static_cache_size() -> int:
	var n := MeshyProp._material_cache.size() + TreeKit._models.size() + TreeKit._lods.size() + RockField._hero_lods.size() + Style._cache.size()
	for v: Variant in [Style._tamga_texture, Style._shield_texture, World._night_lut, RideableSheep._herd_mesh]:
		if v != null:
			n += 1
	return n


# --- Değişimin adımları ------------------------------------------------------------------------------

## Şu anki dünyayı bırakır: world_released, ağaçtan çıkarma, queue_free, bir kare, statik önbellekler.
func _release_current() -> void:
	var old: Node3D = null
	var old_id := ""
	if is_instance_valid(map_world):
		old = map_world
		old_id = spec.id if spec else ""
		map_world = null
	elif is_instance_valid(camp):
		if cine and cine.is_camp_released():
			# Sinemanın gizlediği kamp: anlık görüntü geri yazılır (CineHost başvuruyu bırakır), sonra bırakılır.
			cine.restore_camp()
		old = camp
		camp = null
		_suspend_camp_audio()
	if old == null:
		return
	world_released.emit(old)
	if cine and cine.world == old:
		cine.world = null
	if old.get_parent():
		old.get_parent().remove_child(old)
	old.queue_free()
	if not old_id.is_empty():
		WorldMap.forget(old_id)
	await get_tree().process_frame
	clear_static_caches()


func _request_all(paths: PackedStringArray) -> void:
	if not threaded:
		return
	for path in paths:
		if _held.has(path) or _requests.has(path):
			continue
		if ResourceLoader.load_threaded_request(path, "", false) == OK:
			_requests[path] = true


## İsteklerin bitmesini bekler; bitenler alınıp tutulur. Döner: hepsi yüklendi mi (bekçi dolmadan). threaded kapalıyken (başsız) sırayla
## eşzamanlı yüklenir.
func _wait_loads(paths: PackedStringArray) -> bool:
	if not threaded:
		var all := true
		for path in paths:
			if not _held.has(path):
				_held[path] = load(path)
				all = all and _held[path] != null
		return all
	var deadline := Time.get_ticks_msec() + int(LOAD_TIMEOUT * 1000.0)
	var ok := true
	while true:
		var pending := false
		for path in paths:
			if _held.has(path) or not _requests.has(path):
				continue
			var status := ResourceLoader.load_threaded_get_status(path)
			if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				pending = true
			elif status == ResourceLoader.THREAD_LOAD_LOADED:
				_held[path] = ResourceLoader.load_threaded_get(path)
				_requests.erase(path)
			else:
				push_warning("[world_host] yüklenemedi: %s" % path)
				_requests.erase(path)
				ok = false
		if not pending:
			return ok
		if Time.get_ticks_msec() > deadline:
			push_warning("[world_host] yükleme bekçisi doldu (%.0f sn)" % LOAD_TIMEOUT)
			return false
		await get_tree().process_frame
	return ok


## Haritanın hazır olmasını bekler (is_ready varsa; yoksa bir kare). Döner: bekçi dolmadan hazır oldu mu.
func _wait_ready(node: Node) -> bool:
	var deadline := Time.get_ticks_msec() + int(READY_TIMEOUT * 1000.0)
	await get_tree().process_frame
	while node.has_method(&"is_ready") and not node.call(&"is_ready"):
		if Time.get_ticks_msec() > deadline or not is_instance_valid(node):
			push_warning("[world_host] dünya hazır olmadı: %s" % node.name)
			return false
		await get_tree().process_frame
	return true


## Kampın ertelenen kurulumlarının (orman, kayalar, çayır, dağlar) bitmesini bekler (World.is_built).
func _wait_built(node: World) -> bool:
	var deadline := Time.get_ticks_msec() + int(READY_TIMEOUT * 1000.0)
	await get_tree().process_frame
	while not node.is_built():
		if Time.get_ticks_msec() > deadline or not is_instance_valid(node):
			push_warning("[world_host] kamp kurulamadı")
			return false
		await get_tree().process_frame
	return true


func _suspend_camp_audio() -> void:
	if cine and cine.audio:
		cine.audio.call_target(&"suspend_meadow", [true])


func _resume_camp_audio() -> void:
	if cine and cine.audio:
		cine.audio.call_target(&"suspend_meadow", [false])


func _record(kind: String, id: String, t0: int, t_free: int, t_wait: int, ready: bool) -> void:
	var now := Time.get_ticks_usec()
	last_swap = {
		"kind": kind, "id": id, "ok": ready,
		"free_ms": (t_free - t0) / 1000.0, "wait_ms": (t_wait - t_free) / 1000.0, "build_ms": (now - t_wait) / 1000.0,
		"total_ms": (now - t0) / 1000.0, "frame": Engine.get_process_frames(),
	}
	history.append(last_swap)
	while history.size() > HISTORY:
		history.pop_front()
	if OS.is_debug_build() and not OS.get_cmdline_user_args().is_empty():
		print("[world_host] %s %s: %.0f ms (bırakma %.0f, yükleme %.0f, kurulum %.0f)" % [kind, id, last_swap["total_ms"],
			last_swap["free_ms"], last_swap["wait_ms"], last_swap["build_ms"]])
