class_name MapSpec
extends Resource
## Bir dünyanın tarifi (godot.md §4.2; site Harita): kimlik, ad, tür, sahne, boyut, atlas iğnesi, iklim, yükseklik ve maske, kapılar ve
## belirme noktaları, yapı kayıtları, bölgeler, ses profili, kamera sınırı, hikâye hava kilidi ve önyükleme listesi. Veri
## data/maps/<id>/map.json'dadır; WorldHost dünyayı bununla yükler (arka planda istenecek sahne, pişmiş parçalar ve varlıklar), MapWorld
## bununla kurar.
##
## Koordinatlar (site Harita «İç haritanın haritaya oturma kuralları»): iğne iç haritanın (0, 0) noktasıdır, sahnenin kuzeyi haritanın
## kuzeyidir (-Z), döndürme yoktur; harita (0, 0)'ın çevresinde size kadardır, ya da «bounds» verilmişse o dikdörtgendir (Kışlak: x −450..950,
## z −760..290; Ulu Ocak (0, 0)'dadır ama haritanın ortası değildir; act1.md §4). Pusula yönü derecedir: 0 kuzey (-Z), 90 doğu (+X).
## Yapı kaydı yönünü iki biçimde taşır: «facing» (pusula derecesi, kapının baktığı yön) ya da «rot» (radyan; act1.md §4 ve structures.md
## §11.1: kapı (sin rot, cos rot) yönüne bakar; K51'in kaydı {kind, id, at, rot, size, style, layout}). rot verilmişse facing ondan çıkar.
## Türler: camp (kamp dünyası; menü, Serbest Gez, Ev: world.tscn), interior (iç harita: Kışlak, deneme haritası), story (hikâyenin küçük
## dünyaları: Ordos, Yola Çıkış; bugün main.gd kendi yoluyla kurar, kamp bırakılmaz gizlenir).
##   var spec := MapSpec.find("testmap")       # data/maps/testmap/map.json (yoksa null)
##   spec.spawn("start")                       # {at: Vector2, facing: derece}
##   spec.gate_at(Vector2(x, z))               # o noktayı kapsayan kapı (yoksa boş)

const CAMP := "camp"
const TESTMAP := "testmap"
## I. Perde'nin dünyası (act-1-p2; data/maps/kislak/map.json).
const KISLAK := "kislak"
const KIND_CAMP := "camp"
const KIND_INTERIOR := "interior"
const KIND_STORY := "story"

@export var id := ""
@export var kind := KIND_INTERIOR
## Ad ve alt yazı: {"tr": ..., "en": ...}.
@export var title: Dictionary = {}
@export var subtitle: Dictionary = {}
## Dünyanın sahnesi (res://scenes/...): WorldHost arka planda yükler.
@export var scene := ""
## Haritanın boyu (m; x doğu-batı, y kuzey-güney) ve atlas iğnesi (boylam, enlem; site Harita).
@export var size := Vector2.ZERO
@export var pin := Vector2.ZERO
## Haritanın dikdörtgeni (x, z; map.json «bounds» {min, max}); boşsa (0, 0)'ın çevresinde size (rect()).
@export var bounds := Rect2()
## İklim (hava; weather.md climates) ve hikâye hava kilidi (boşsa yok).
@export var climate := ""
@export var weather_lock := ""
## Ses profili (audio.md; boşsa dünyanın kendi sesi).
@export var audio := ""
## Işık: örnek dosyası ve açılış örneği (SkyRig).
@export var light := ""
@export var light_sample := ""
## Yürünür alan (PlayerController play_area_*): merkez, yarıçap, yumuşak kenar; kameranın kutusu (x, z).
@export var play_center := Vector2.ZERO
@export var play_radius := 40.0
@export var play_soft_edge := 3.0
@export var camera_bounds := Rect2()
## Kapılar: [{id, name{tr,en}, at Vector2, radius, facing, to, arrive}] (to: varılan dünya; arrive: oradaki belirme noktası).
@export var gates: Array[Dictionary] = []
## Belirme noktaları: kimlik → {at: Vector2, facing: derece}.
@export var spawns: Dictionary = {}
## Yapı kayıtları: [{kind, id, at Vector2, facing, ...}] (MapWorld kurar: yurt, ocak, eşya, sancak, at).
@export var structures: Array[Dictionary] = []
## Bölgeler: [{id, name{tr,en}, center Vector2, radius}].
@export var regions: Array[Dictionary] = []
## Pişmiş parçaların türleri (MapBake.path_for(id, tür)): WorldHost arka planda ister.
@export var bakes: PackedStringArray = []
## Kurulumda yüklenen varlıklar (map.json "preload"; WorldHost arka planda ister); preload_file verilmişse oradan da (tools/bake_map.gd yazar).
@export var preload_paths: PackedStringArray = []
@export var preload_file := ""
## Yüksekliğin ve arazinin tarifi (MapWorld.bake; iç harita): tohum, kabartma, düz yerler, dış halka...
@export var ground: Dictionary = {}
## Otun ve navmesh karolarının tarifi (MapWorld.bake).
@export var grass: Dictionary = {}
@export var nav: Dictionary = {}
## Veri katmanları: kimlik → katmanın dosyası (MapLayers; pişmiş parçaların imzasına girmez).
@export var layers: Dictionary = {}
## Ham tarif (map.json'un bütün sözlüğü): MapSpec'in alanı olmayan anahtarlar (audio'nun ayrıntısı, perish, weather, roads...) buradan
## okunur; öteki ajanlar kendi anahtarları için MapSpec'i değiştirmek zorunda kalmaz.
var raw: Dictionary = {}

## Okunan tarifler (kimlik → MapSpec; veri, çizim kaynağı tutmaz).
static var _cache: Dictionary = {}


## Tarifin dosyası (saf).
static func path_for(p_id: String) -> String:
	return "res://data/maps/%s/map.json" % p_id


## Kimlikle tarif (data/maps/<id>/map.json; yoksa ya da okunamazsa null). Bir kez okunur.
static func find(p_id: String) -> MapSpec:
	if _cache.has(p_id):
		return _cache[p_id]
	var path := path_for(p_id)
	if not FileAccess.file_exists(path):
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_warning("[map_spec] okunamadı: %s" % path)
		return null
	var spec := from_dict(parsed)
	if spec.id.is_empty():
		spec.id = p_id
	_cache[p_id] = spec
	return spec


## Sözlükten tarif (saf; map.json'un biçimi). Bilinmeyen anahtar yok sayılır.
static func from_dict(d: Dictionary) -> MapSpec:
	var spec := MapSpec.new()
	spec.id = str(d.get("id", ""))
	spec.kind = str(d.get("kind", KIND_INTERIOR))
	spec.title = d.get("title", {})
	spec.subtitle = d.get("subtitle", {})
	spec.scene = str(d.get("scene", ""))
	spec.size = vec2(d.get("size", [0.0, 0.0]))
	spec.pin = vec2(d.get("pin", [0.0, 0.0]))
	var box: Dictionary = d.get("bounds", {}) if d.get("bounds") is Dictionary else {}
	if not box.is_empty():
		var lo := vec2(box.get("min", [0.0, 0.0]))
		var hi := vec2(box.get("max", [0.0, 0.0]))
		spec.bounds = Rect2(lo, hi - lo).abs()
		if spec.size == Vector2.ZERO:
			spec.size = spec.bounds.size
	spec.raw = d
	spec.climate = str(d.get("climate", ""))
	spec.weather_lock = str(d.get("weather_lock", ""))
	spec.audio = str(d.get("audio", ""))
	var light_def: Dictionary = d.get("light", {})
	spec.light = str(light_def.get("path", ""))
	spec.light_sample = str(light_def.get("sample", ""))
	var area: Dictionary = d.get("play_area", {})
	spec.play_center = vec2(area.get("center", [0.0, 0.0]))
	spec.play_radius = float(area.get("radius", 40.0))
	spec.play_soft_edge = float(area.get("soft_edge", 3.0))
	var bounds: Dictionary = d.get("camera_bounds", {})
	if not bounds.is_empty():
		var a := vec2(bounds.get("min", [0.0, 0.0]))
		var b := vec2(bounds.get("max", [0.0, 0.0]))
		spec.camera_bounds = Rect2(a, b - a)
	for g: Dictionary in d.get("gates", []):
		var gate := g.duplicate(true)
		gate["at"] = vec2(g.get("at", [0.0, 0.0]))
		gate["radius"] = float(g.get("radius", 6.0))
		gate["facing"] = float(g.get("facing", 0.0))
		spec.gates.append(gate)
	for k: String in (d.get("spawns", {}) as Dictionary):
		var s: Dictionary = d["spawns"][k]
		spec.spawns[k] = {"at": vec2(s.get("at", [0.0, 0.0])), "facing": float(s.get("facing", 0.0))}
	for s: Dictionary in d.get("structures", []):
		var rec := s.duplicate(true)
		rec["at"] = vec2(s.get("at", [0.0, 0.0]))
		if s.has("rot") and not s.has("facing"):
			rec["facing"] = facing_of_rot(float(s["rot"]))
		else:
			rec["facing"] = float(s.get("facing", 0.0))
		spec.structures.append(rec)
	for r: Dictionary in d.get("regions", []):
		var reg := r.duplicate(true)
		reg["center"] = vec2(r.get("center", [0.0, 0.0]))
		reg["radius"] = float(r.get("radius", 10.0))
		spec.regions.append(reg)
	spec.bakes = PackedStringArray(d.get("bakes", []))
	spec.preload_paths = PackedStringArray(d.get("preload", []))
	spec.preload_file = str(d.get("preload_file", ""))
	spec.ground = d.get("ground", {})
	spec.grass = d.get("grass", {})
	spec.nav = d.get("nav", {})
	spec.layers = d.get("layers", {}) if d.get("layers") is Dictionary else {}
	return spec


## Kamp mı (menü, Serbest Gez, Ev)?
func is_camp() -> bool:
	return kind == KIND_CAMP


## Adı (dil "tr" ya da "en"; yoksa kimlik).
func title_text(lang: String = "tr") -> String:
	return str(title.get(lang, title.get("tr", id)))


## Belirme noktası: {at: Vector2, facing: derece}; yoksa boş.
func spawn(p_id: String) -> Dictionary:
	return spawns.get(p_id, {})


## Kimlikle kapı (yoksa boş).
func gate(p_id: String) -> Dictionary:
	for g in gates:
		if str(g.get("id", "")) == p_id:
			return g
	return {}


## Noktayı (x, z) kapsayan kapı (yarıçapının içinde; yoksa boş).
func gate_at(p: Vector2) -> Dictionary:
	for g in gates:
		if p.distance_to(g["at"]) <= float(g["radius"]):
			return g
	return {}


## Noktanın bölgesi. Biçimli bölgeler (Kışlak; act1.md §4: «size» dikdörtgen, «points» + «width» şerit (Buz Kolu), «ridge» ek dikdörtgen
## (Şafak Sırtı)) varsa noktayı kapsayanların alanı en küçüğü (iç içe bölgede özel olan kazanır); yalnız yarıçaplı bölgelerde (deneme
## haritası) yarıçapın içindeki en yakın merkez. Yoksa boş.
func region_at(p: Vector2) -> Dictionary:
	var shaped := false
	for r in regions:
		if r.has("size") or r.has("points"):
			shaped = true
			break
	var best := {}
	if shaped:
		var best_area := INF
		for r in regions:
			var area := region_area(r)
			if area < best_area and region_contains(r, p):
				best = r
				best_area = area
		return best
	var best_d := INF
	for r in regions:
		var d := p.distance_to(r["center"])
		if d <= float(r["radius"]) and d < best_d:
			best = r
			best_d = d
	return best


## Bölge noktayı kapsıyor mu (saf; size, points + width, ridge; yoksa yarıçap)?
static func region_contains(r: Dictionary, p: Vector2) -> bool:
	if r.has("points"):
		var pts := PackedVector2Array()
		for q: Variant in r["points"]:
			pts.append(vec2(q))
		if MapBaker.polyline_distance(pts, p) <= float(r.get("width", 60.0)) * 0.5:
			return true
	elif r.has("size"):
		var half := vec2(r["size"]) * 0.5
		var c := vec2(r.get("center", [0.0, 0.0]))
		if absf(p.x - c.x) <= half.x and absf(p.y - c.y) <= half.y:
			return true
	elif p.distance_to(vec2(r.get("center", [0.0, 0.0]))) <= float(r.get("radius", 10.0)):
		return true
	var ridge: Variant = r.get("ridge")
	if ridge is Dictionary:
		var rh := vec2((ridge as Dictionary).get("size", [0.0, 0.0])) * 0.5
		var rc := vec2((ridge as Dictionary).get("center", [0.0, 0.0]))
		return absf(p.x - rc.x) <= rh.x and absf(p.y - rc.y) <= rh.y
	return false


## Bölgenin alanı (m²; saf): dikdörtgen, şerit (boy × en) ya da daire.
static func region_area(r: Dictionary) -> float:
	if r.has("points"):
		var length := 0.0
		var raw: Array = r["points"]
		for i in raw.size() - 1:
			length += vec2(raw[i]).distance_to(vec2(raw[i + 1]))
		return length * float(r.get("width", 60.0))
	if r.has("size"):
		var s := vec2(r["size"])
		return s.x * s.y
	var rad := float(r.get("radius", 10.0))
	return PI * rad * rad


## Haritanın dikdörtgeni (x, z): bounds verilmişse o, yoksa (0, 0) ortada size.
func rect() -> Rect2:
	return bounds if bounds.has_area() else Rect2(-size * 0.5, size)


## Kimlikle yapı kaydı (yoksa boş).
func structure(p_id: String) -> Dictionary:
	for s in structures:
		if str(s.get("id", "")) == p_id:
			return s
	return {}


## Kapının yönü (radyan; act1.md §4: kapı (sin rot, cos rot) yönüne bakar) → pusula derecesi (0 kuzey −Z, 90 doğu +X; [0, 360)). Saf.
static func facing_of_rot(rot: float) -> float:
	return fposmod(180.0 - rad_to_deg(rot), 360.0)


## Arka planda istenecek yollar: sahne, pişmiş parçalar ve varlıklar (preload ve preload_file), var olanlar, tekrarsız.
func load_paths() -> PackedStringArray:
	var out := PackedStringArray()
	if not scene.is_empty():
		out.append(scene)
	for k in bakes:
		out.append(MapBake.path_for(id, k))
	var extra := preload_paths.duplicate()
	if not preload_file.is_empty() and FileAccess.file_exists(preload_file):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(preload_file))
		if parsed is Dictionary:
			extra.append_array(PackedStringArray((parsed as Dictionary).get("paths", [])))
	for p in extra:
		if not out.has(p):
			out.append(p)
	var existing := PackedStringArray()
	for p in out:
		if ResourceLoader.exists(p):
			existing.append(p)
	return existing


## Okunan tarifleri unutur (sınama: dosya değişti).
static func forget_cache() -> void:
	_cache.clear()


## [x, z] ya da Vector2 → Vector2 (saf).
static func vec2(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	if value is Array and (value as Array).size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO
