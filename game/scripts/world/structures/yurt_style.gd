class_name YurtStyle
extends Resource
## Yurdun milleti (K51; structures.md §3.6; godot.md §6.7): gövde oranları ve keçe rengi. Yakındaki yurtta ağın köşe rengi ve
## malzemenin süs renkleri (StagedYurt), YurtField'de örneğin rengi olur. Millet sayı değiştirmez: malzeme, emek ve can boydan çıkar.
## Veri data/structures/yurt_styles.json'dadır; bilinmeyen millet Hun'a düşer.
##   var hun := YurtStyle.find("hun")
##   hun.wall_height()      # 2,25 m (Hane, kök ölçeğinden önce)
##   YurtStyle.size_scale("s")   # Vector2(0,7; 0,84): yatay ve dikey kök ölçeği

const PATH := "res://data/structures/yurt_styles.json"
const DEFAULT := "hun"
const FAMILY_YURT := "yurt"
const FAMILY_DOME := "kubbe"
const FAMILY_CART := "cart"
const FAMILY_TENT := "tent"

@export var id := DEFAULT
@export var family := FAMILY_YURT
@export var wall_k := 1.0
@export var rise := 1.0
@export var bulge := 0.0
@export var crown_k := 1.0
## Kuzeyden kapı açısı ve payı (derece; yerleşimin varsayılanı).
@export var door_deg := Vector2(120.0, 45.0)
@export var door_kind := "bosaga"
@export var felt := Color("#d9cfba")
@export var band := Color("#7a2a22")
@export var rope := Color("#5a4632")
@export var motif := Color("#e8dcc0")
@export var accent := Color("#b08b4e")
@export var trim := Color("#8a5a2c")
@export var pattern := 1
@export var roof_pattern := 0
@export var rays := 13
@export var name_text: Dictionary = {}

static var _data: Dictionary = {}
static var _cache: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty() and FileAccess.file_exists(PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		_data = parsed if parsed is Dictionary else {}
	return _data


static func forget() -> void:
	_data = {}
	_cache = {}


## Milletin kimlikleri (veri sırasıyla).
static func ids() -> PackedStringArray:
	return PackedStringArray((data().get("styles", {}) as Dictionary).keys())


static func has(style_id: String) -> bool:
	return (data().get("styles", {}) as Dictionary).has(style_id)


## Kimlikle millet (önbellekli; bilinmeyen Hun).
static func find(style_id: String) -> YurtStyle:
	var key := style_id if YurtStyle.has(style_id) else DEFAULT
	if _cache.has(key):
		return _cache[key]
	var s := YurtStyle.from_dict(key, (data().get("styles", {}) as Dictionary).get(key, {}))
	_cache[key] = s
	return s


static func from_dict(style_id: String, d: Dictionary) -> YurtStyle:
	var s := YurtStyle.new()
	s.id = style_id
	s.family = str(d.get("family", FAMILY_YURT))
	s.wall_k = float(d.get("wall_k", 1.0))
	s.rise = float(d.get("rise", 1.0))
	s.bulge = float(d.get("bulge", 0.0))
	s.crown_k = float(d.get("crown_r", 1.0))
	var dd: Variant = d.get("door_deg", [120, 45])
	if dd is Array and (dd as Array).size() >= 2:
		s.door_deg = Vector2(float(dd[0]), float(dd[1]))
	s.door_kind = str(d.get("door", "bosaga"))
	s.felt = YurtStyle._col(d.get("felt"), s.felt)
	s.band = YurtStyle._col(d.get("band"), s.band)
	s.rope = YurtStyle._col(d.get("rope"), s.rope)
	s.motif = YurtStyle._col(d.get("motif"), s.motif)
	s.accent = YurtStyle._col(d.get("accent"), s.accent)
	s.trim = YurtStyle._col(d.get("trim"), s.trim)
	s.pattern = int(d.get("pattern", 0))
	s.roof_pattern = int(d.get("roof_pattern", 0))
	s.rays = int(d.get("rays", 13))
	s.name_text = d.get("name", {})
	return s


static func _col(v: Variant, fallback: Color) -> Color:
	if v is String and Color.html_is_valid(v):
		return Color.html(v)
	return fallback


## Gövdenin ölçüsü (body; m, Hane, kök ölçeğinden önce).
static func body(key: String, fallback: float) -> float:
	return float((data().get("body", {}) as Dictionary).get(key, fallback))


## Boyun satırı (s, m, l): scale, scale_y, kanat, uuk, tone.
static func size_row(size: String) -> Dictionary:
	var sizes: Dictionary = data().get("sizes", {})
	return sizes.get(size, sizes.get("m", {"scale": 1.0, "scale_y": 1.0, "kanat": 6, "uuk": 48, "tone": 1.0}))


## Boyun kök ölçeği: Vector2(yatay, dikey).
static func size_scale(size: String) -> Vector2:
	var row := YurtStyle.size_row(size)
	return Vector2(float(row.get("scale", 1.0)), float(row.get("scale_y", 1.0)))


static func size_tone(size: String) -> float:
	return float(YurtStyle.size_row(size).get("tone", 1.0))


# --- Gövde (Hane, kök ölçeğinden önce) --------------------------------------------------------------------

func radius() -> float:
	return YurtStyle.body("radius", 3.3)


## Duvarın boyu: wall × wall_k (kubbede 0: çatı yerden başlar).
func wall_height() -> float:
	return YurtStyle.body("wall", 2.25) * wall_k


## Çatının yüksekliği: roof × rise; kubbede duvarın payı da çatıya geçer.
func roof_height() -> float:
	if family == FAMILY_DOME:
		return (YurtStyle.body("wall", 2.25) + YurtStyle.body("roof", 1.5)) * rise * 0.72
	return YurtStyle.body("roof", 1.5) * rise


func crown_radius() -> float:
	return YurtStyle.body("crown", 0.6) * crown_k


func crown_height() -> float:
	return wall_height() + roof_height()


## Kapının eni ve boyu (m): en az body.door; duvarın 0,18 m altında kalır (kubbede çatının %62'si).
func door_size() -> Vector2:
	var d: Variant = (data().get("body", {}) as Dictionary).get("door", [0.95, 2.05])
	var w := float(d[0]) if d is Array else 0.95
	var h := float(d[1]) if d is Array else 2.05
	var top := wall_height() - 0.18 if family != FAMILY_DOME else roof_height() * 0.62
	return Vector2(w, minf(h, top))


## Kapı yönünün varsayılanı (radyan, rot; kapı (sin rot, cos rot)): kuzeyden door_deg pusula açısı.
func default_rot(great: bool = false) -> float:
	var deg := door_deg.x
	if great:
		var g: Variant = ((data().get("styles", {}) as Dictionary).get(id, {}) as Dictionary).get("door_deg_great")
		if g is Array and (g as Array).size() >= 2:
			deg = float(g[0])
	return PI - deg_to_rad(deg)
