class_name AtlasGeo
extends RefCounted
## Atlasın verisi (godot.md §4.8; site Harita): data/atlas/geography.json (prototipin src/map/geography.js satırları, geo.js ve atlas.js
## dizgeleri, iç haritaların evleri) ve data/atlas/shapes.json (kıvrımlı siyasi sınırlar, ırmaklar, Çin Surları). İkisini
## tools/atlas/dump_geography.mjs ve bake_atlas.mjs yazar; kabartmanın dokuları assets/map/ altındadır. Oturum boyunca bir kez
## yüklenir (shared()); saftır, düğüm ve sahne okumaz.
## Harita birimi: x doğu, z güney, harita (0, 0) çevresinde 50,42 × 29,75 birim. Haritada bir birim 7,07 gösterim km'sidir (75.000 km²),
## gerçek sahne düzeyinde (iç haritanın üstünde) 1.000 sahne metresi: ev (homes) sahnenin (0, 0) noktasıdır, kuzey haritanın kuzeyidir.
##   var geo := AtlasGeo.shared()
##   geo.to_map(103.1, 47.35)                  # Vector2(3.94, -5.82)
##   geo.text("atlas.crumb.world", "tr")        # «Bozkır Dünyası»
##   geo.row_text("polities", row, "name", "en")

const GEO_PATH := "res://data/atlas/geography.json"
const SHAPES_PATH := "res://data/atlas/shapes.json"
const NH_PATH := "res://assets/map/atlas_nh.png"
## Kabartmanın yükseklik kodu (relief-core.js HMAX): dokunun mavi kanalı 0..HMAX birimdir.
const HMAX := 0.7
## Açılma kuralının özel değerleri (geography.js UNLOCK_*): başta açık, Serbest Gez'in kampı; Godot'nun eki Çocukluk.
const UNLOCK_START := "start"
const UNLOCK_CAMP := "camp"
const UNLOCK_CHILDHOOD := "childhood"
## Kuralların açtığı değerler: Serbest Gez (ve Yola Çıkış) başta ve kamp satırlarını, Çocukluk yalnız kendi satırlarını görür.
## Koşulsuz satır (fiziki coğrafya) her kuralda açıktır; "all" (geliştirme karesi) her satırı açar.
const RULES := {"camp": ["start", "camp"], "childhood": ["childhood"]}
## Evi olmayan dünyanın evi (prototip: DEFAULT_ZONE, uyarıyla).
const DEFAULT_HOME := "camp"

var map_w := 50.4175
var map_d := 29.7515
var km_per_unit := 7.0711
var area_km2 := 75000.0
var lon0 := 58.0
var lon1 := 136.0
var lat0 := 23.0
var lat1 := 58.0
## Haritanın sabit güneşi (kuzeybatıdan, alçak) ve gök pusu.
var sun := Vector3(-0.7374, 0.4988, -0.4554)
var haze := Color("#a9bdd2")
var data: Dictionary = {}
var strings: Dictionary = {}
var homes: Dictionary = {}
## Kıvrımlı yollar (harita birimi): sınırlar kimlikle, ırmaklar sırayla ({id, w, pts}), surlar.
var borders: Dictionary = {}
var rivers: Array = []
var wall := PackedVector2Array()
var ok := false

var _heights := PackedByteArray()
var _hw := 0
var _hd := 0

static var _shared: AtlasGeo


## Oturumun verisi (ilk çağrıda yüklenir).
static func shared() -> AtlasGeo:
	if _shared == null:
		_shared = AtlasGeo.new()
		_shared.load_files()
	return _shared


func load_files(geo_path := GEO_PATH, shapes_path := SHAPES_PATH) -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(geo_path)) if FileAccess.file_exists(geo_path) else null
	if not (parsed is Dictionary):
		push_error("[atlas] coğrafya okunamadı: %s" % geo_path)
		return
	data = parsed
	var m: Dictionary = data.get("map", {})
	map_w = float(m.get("w", map_w))
	map_d = float(m.get("d", map_d))
	km_per_unit = float(m.get("km_per_unit", km_per_unit))
	area_km2 = float(m.get("area_km2", area_km2))
	lon0 = float(m.get("lon0", lon0))
	lon1 = float(m.get("lon1", lon1))
	lat0 = float(m.get("lat0", lat0))
	lat1 = float(m.get("lat1", lat1))
	var s: Array = m.get("sun", [])
	if s.size() == 3:
		sun = Vector3(float(s[0]), float(s[1]), float(s[2])).normalized()
	haze = Color(str(m.get("haze", "#a9bdd2")))
	strings = data.get("strings", {})
	homes = data.get("homes", {})
	var sh: Variant = JSON.parse_string(FileAccess.get_file_as_string(shapes_path)) if FileAccess.file_exists(shapes_path) else null
	if sh is Dictionary:
		for id: String in (sh["polities"] as Dictionary):
			borders[id] = _points((sh["polities"] as Dictionary)[id])
		for r: Dictionary in (sh.get("rivers", []) as Array):
			rivers.append({"id": str(r["id"]), "w": float(r["w"]), "pts": _points(r["pts"])})
		wall = _points(sh.get("wall", []))
	else:
		push_warning("[atlas] kıvrımlı yollar okunamadı: %s" % shapes_path)
	ok = true


static func _points(list: Variant) -> PackedVector2Array:
	var out := PackedVector2Array()
	if list is Array:
		for p: Variant in list:
			out.append(Vector2(float(p[0]), float(p[1])))
	return out


# --- Koordinat ----------------------------------------------------------------------------------------------------

## Boylam, enlem → harita birimi (geography.js toMap).
func to_map(lon: float, lat: float) -> Vector2:
	return Vector2(((lon - lon0) / (lon1 - lon0) - 0.5) * map_w, ((lat1 - lat) / (lat1 - lat0) - 0.5) * map_d)


func at_of(lonlat: Variant) -> Vector2:
	return to_map(float(lonlat[0]), float(lonlat[1])) if lonlat is Array and (lonlat as Array).size() >= 2 else Vector2.ZERO


## Harita birimi → boylam, enlem (saf).
func lonlat_of(p: Vector2) -> Vector2:
	return Vector2(lon0 + (p.x / map_w + 0.5) * (lon1 - lon0), lat1 - (p.y / map_d + 0.5) * (lat1 - lat0))


## Bir enlem derecesinin harita birimi (ölçeğin notu ve lekelerin yarıçapı).
func units_per_deg_lat() -> float:
	return to_map(0.0, 0.0).y - to_map(0.0, 1.0).y


func units_per_deg_lon() -> float:
	return to_map(1.0, 0.0).x - to_map(0.0, 0.0).x


## Kabartmanın yüksekliği (harita birimi; çift doğrusal). Doku ilk çağrıda belleğe alınır (RGBA baytları; yükseklik mavi kanalda).
func height_at(p: Vector2) -> float:
	if _heights.is_empty():
		_load_heights()
		if _heights.is_empty():
			return 0.0
	var fx := clampf((p.x / map_w + 0.5) * (_hw - 1), 0.0, _hw - 1.001)
	var fz := clampf((p.y / map_d + 0.5) * (_hd - 1), 0.0, _hd - 1.001)
	var i := int(fx)
	var j := int(fz)
	var u := fx - i
	var v := fz - j
	# Dokunun RGBA baytlarında mavi kanal (k * 4 + 2).
	var k := (j * _hw + i) * 4 + 2
	var row := _hw * 4
	var a := lerpf(float(_heights[k]), float(_heights[k + 4]), u)
	var b := lerpf(float(_heights[k + row]), float(_heights[k + row + 4]), u)
	return lerpf(a, b, v) / 255.0 * HMAX


func _load_heights() -> void:
	var tex := load(NH_PATH) as Texture2D if ResourceLoader.exists(NH_PATH) else null
	var img := tex.get_image() if tex else null
	if img == null or img.is_empty():
		push_warning("[atlas] kabartma dokusu okunamadı: %s" % NH_PATH)
		return
	if img.is_compressed():
		img.decompress()
	img.clear_mipmaps()
	img.convert(Image.FORMAT_RGBA8)
	_hw = img.get_width()
	_hd = img.get_height()
	# Baytlar olduğu gibi tutulur (piksel piksel kopya ilk açılışı yavaşlatırdı).
	_heights = img.get_data()


# --- Satırlar ve dizgeler ---------------------------------------------------------------------------------------------

func rows(table: String) -> Array:
	return data.get(table, []) as Array


## Dizge (dil: "tr" ya da "en"; bulunmazsa Türkçesi, o da yoksa boş).
func text(key: String, lang := "tr") -> String:
	var e: Variant = strings.get(key)
	if e is Dictionary:
		return str((e as Dictionary).get(lang, (e as Dictionary).get("tr", "")))
	return ""


func has_text(key: String) -> bool:
	return strings.has(key)


## Satırın görünür metni (prototipin rowText'i): geo.<tablo>.<kimlik>.<alan>.
func row_text(table: String, row: Dictionary, field: String, lang := "tr") -> String:
	if row.has("id"):
		var key := "geo.%s.%s.%s" % [table, str(row["id"]), field]
		if strings.has(key):
			return text(key, lang)
	return ""


## Yer tutuculu dizge: {ad} → değer.
func format(key: String, values: Dictionary, lang := "tr") -> String:
	var s := text(key, lang)
	for k: String in values:
		s = s.replace("{%s}" % k, str(values[k]))
	return s


# --- Evler ve açılma ----------------------------------------------------------------------------------------------

## Dünyanın evi (WorldMap'in anahtarıyla); yoksa kampınki (prototip gibi, uyarıyla).
func home(key: String) -> Dictionary:
	if homes.has(key):
		return homes[key]
	if not key.is_empty():
		push_warning("[atlas] \"%s\" dünyasının atlasta evi yok, kampınki kullanılıyor" % key)
	return homes.get(DEFAULT_HOME, {"lonlat": [103.1, 47.35]})


func home_point(key: String) -> Vector2:
	return at_of(home(key).get("lonlat", [103.1, 47.35]))


## Satır bu kuralda açık mı (saf): koşulsuz satır her zaman; özel değerler kuralın listesinde; koşul dili (act>=2, quest:…) kuralsız
## kalır: Godot'da hikâyenin atlası henüz yok (yalnız Serbest Gez ve Çocukluk), açık sayılmaz.
static func revealed(rule: String, row: Dictionary) -> bool:
	var u := str(row.get("unlock", ""))
	if u.is_empty() or rule == "all":
		return true
	return (RULES.get(rule, RULES["camp"]) as Array).has(u)
