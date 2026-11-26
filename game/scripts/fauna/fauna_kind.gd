class_name FaunaKind
extends Resource
## Hayvan türünün kaydı (fauna.md §10; godot.md «Hayvanlar»): data/fauna/kinds.json'un bir satırı. Sürü ve küçük av türün
## oranını, hızını, canını ve davranış sayılarını buradan okur; kimlikler fauna.md §1 ile aynıdır.
##
##   var sheep := FaunaKind.named("sheep")
##   sheep.speed("trot")   # 2,5 m/sn
##   sheep.model_path()    # res://assets/animals/sheep/sheep.glb (dosya henüz yoksa kodla çizilir: FaunaMesh)
##   var gazelle := FaunaKind.named("gazelle")
##   gazelle.peak_speed(), gazelle.sustained_speed(), gazelle.flight_time()   # 15, 10, 12 (fauna.md §4.1 kaçış)
##   gazelle.sense("sight"), gazelle.activity(&"noon")                        # 40 m; 1 (survival.md §4.3–§4.4)

const PATH := "res://data/fauna/kinds.json"
## Gün içi etkinliğin evre sırası (GameClock.phase; survival.md §4.3: Tan, Sabah, Öğle, İkindi, Akşam, Gece).
const PHASES: Array[StringName] = [&"dawn", &"morning", &"noon", &"golden", &"dusk", &"night"]
## Yazılmayan kaçış süresi (sn; fauna.md §4.1: «öteki 8 sn»).
const FLIGHT_T := 8.0
## Gece görüş çarpanı (survival.md §4.4; tilki ve kurt 1, satırında yazar).
const NIGHT_SIGHT := 0.6

@export var id := ""
@export var kind_class := ""
@export var plan := ""
## Omuz yüksekliği ve burundan kuyruğa boy (metre; gerçek ya da Godot ölçüsü, fauna.md §10).
@export var shoulder := 0.0
@export var length := 0.0
## Kodla çizimin gerçek boya göre büyütmesi (oyun kamerasında okunsun diye).
@export var draw_scale := 1.0
@export var hp := 1
## Satırın tamamı (speed, stride, yield, game, model, name).
@export var def: Dictionary = {}


## Satırı kurar (saf).
static func from_def(kind_id: String, row: Dictionary) -> FaunaKind:
	var kind := FaunaKind.new()
	kind.id = kind_id
	kind.def = row
	kind.kind_class = str(row.get("class", ""))
	kind.plan = str(row.get("plan", ""))
	kind.shoulder = float(row.get("shoulder", 0.0))
	kind.length = float(row.get("length", 0.0))
	kind.draw_scale = float(row.get("draw_scale", 1.0))
	kind.hp = int(row.get("hp", 1))
	return kind


## Kataloğun bütün satırları (kimlik → satır; dosya okunamazsa boş). Her çağrı dosyayı okur: kurulumda bir kez sorulur.
static func table(path: String = PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("[fauna] katalog yok: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var kinds: Variant = (parsed as Dictionary).get("kinds") if parsed is Dictionary else null
	return kinds if kinds is Dictionary else {}


## Tür kaydı; katalogda yoksa null.
static func named(kind_id: String, path: String = PATH) -> FaunaKind:
	var rows := table(path)
	if not rows.has(kind_id):
		push_warning("[fauna] katalogda %s yok" % kind_id)
		return null
	return from_def(kind_id, rows[kind_id])


## Hız (m/sn; "walk", "trot", "gallop", "flight", "flee", "sustained"); yoksa fallback.
func speed(gait: String, fallback: float = 0.0) -> float:
	return float((def.get("speed", {}) as Dictionary).get(gait, fallback))


## Adım boyu (metre; "walk", "trot", "gallop"; fauna.md §10); yoksa fallback.
func stride(gait: String, fallback: float = 1.0) -> float:
	return float((def.get("stride", {}) as Dictionary).get(gait, fallback))


## Av davranışının sayısı (hit_radius, scare_radius...); yoksa fallback.
func game_value(key: String, fallback: Variant = 0.0) -> Variant:
	return (def.get("game", {}) as Dictionary).get(key, fallback)


## Meshy modelinin yolu (res://assets/<folder>/<id>/<id>.glb); türün modeli yazılmamışsa boş.
func model_path() -> String:
	var model: Dictionary = def.get("model", {})
	if model.is_empty():
		return ""
	return MeshyProp.model_path(str(model.get("folder", "animals")), str(model.get("id", id)))


## Uzak sürünün ağı (res://assets/<folder>/<id>/<far>.glb; Meshy varlık hattının T1 çıktısı, ör. sheep_far.glb). Yazılmamışsa boş.
func far_model_path() -> String:
	var model: Dictionary = def.get("model", {})
	if not model.has("far"):
		return ""
	return "res://assets/%s/%s/%s.glb" % [str(model.get("folder", "animals")), str(model.get("id", id)), str(model["far"])]


## Sürünün çizeceği model: uzak ağ varsa o, yoksa asıl model (HerdField T1'e indirir); hiçbiri yoksa boş.
func herd_model_path() -> String:
	var far := far_model_path()
	if not far.is_empty() and ResourceLoader.exists(far):
		return far
	var main := model_path()
	return main if not main.is_empty() and ResourceLoader.exists(main) else ""


## Modelin ölçtüğü boy (metre; <id>.json'un length_m'i, varlik-hatti); dosya yoksa türün boyu.
func model_length() -> float:
	var model: Dictionary = def.get("model", {})
	if model.is_empty():
		return length
	var path := "res://assets/%s/%s/%s.json" % [str(model.get("folder", "animals")), str(model.get("id", id)), str(model.get("id", id))]
	if not FileAccess.file_exists(path):
		return length
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return float((parsed as Dictionary).get("length_m", length)) if parsed is Dictionary else length


## Modelin tek örneğine izin verilen en çok üçgen (sürünün T1 kademesi, army.md §7.1: ≤1.800).
func max_triangles() -> int:
	return int((def.get("model", {}) as Dictionary).get("max_triangles", 1800))


# --- Kışlak takımı (act-1-p2): kaçış, algı, etkinlik, görünüş ---------------------------------------------------

## Kaçışın tepe hızı (m/sn; fauna.md §1 «tepe»): yabanda peak, küçük avda flee, evcilde gallop.
func peak_speed() -> float:
	return speed("peak", speed("flee", speed("gallop", speed("trot", 1.0))))


## Kaçışın sürek hızı (m/sn; fauna.md §1 «sürek»): yabanda sustained, evcilde trot.
func sustained_speed() -> float:
	return speed("sustained", speed("trot", peak_speed()))


## Tepe hızın söndüğü süre T (sn; fauna.md §4.1: ceylan 12, zeren 15, kulan 20, öteki 8).
func flight_time() -> float:
	return float((def.get("flight", {}) as Dictionary).get("T", FLIGHT_T))


## Algı değeri (survival.md §4.4): sight, hear (m), smell (çarpanın gücü), night (gece görüş çarpanı), alarm (m).
func sense(key: String, fallback: float = 0.0) -> float:
	var s: Dictionary = def.get("sense", {})
	if key == "night":
		return float(s.get("night", NIGHT_SIGHT))
	return float(s.get(key, fallback))


## Evrenin etkinlik ağırlığı (0–3; survival.md §4.3). Satırı olmayan tür (evcil) her evrede 3'tür; bilinmeyen evre 3.
func activity(phase: StringName) -> int:
	var row: Variant = def.get("activity")
	if not row is Array or (row as Array).size() < PHASES.size():
		return 3
	var i := PHASES.find(phase)
	return int((row as Array)[i]) if i >= 0 else 3


## Sürü boyu [en az, en çok] (fauna.md §1 Sürü); sahnedeki en çok scene ile kırpılır (kurt 4).
func group_range() -> Vector2i:
	var g: Variant = def.get("group", [1, 1])
	var lo := int((g as Array)[0]) if g is Array and (g as Array).size() >= 1 else 1
	var hi := int((g as Array)[1]) if g is Array and (g as Array).size() >= 2 else lo
	var cap := int(def.get("scene", hi))
	return Vector2i(mini(lo, cap), mini(hi, cap))


## Davranış (FaunaDirector): graze, stop_look, cliff, cover, charge, predator, sly, camp_dog, domestic, soar.
func temper() -> String:
	return str(def.get("temper", "graze"))


func is_wild() -> bool:
	return kind_class == "wild"


func is_bird() -> bool:
	return kind_class == "bird"


## Yırtıcı mı (K3, K65: ana kampa ve Kışlak'ın yerleşimine girmez; kurt, tilki)?
func is_predator() -> bool:
	return temper() == "predator" or temper() == "sly"


## Modelin boy çarpanı (Hun Atı ×0,94, K65; yer tutucu ağın türün boyuna çarpanı).
func model_scale() -> float:
	return float((def.get("model", {}) as Dictionary).get("scale", 1.0))


## Yer tutucunun doku çarpanı (yoksa beyaz).
func tint() -> Color:
	var t: Variant = (def.get("model", {}) as Dictionary).get("tint")
	return Color(str(t)) if t is String else Color.WHITE


## Kodla çizilen ağın adı (FaunaMesh; boşsa Meshy modeli ya da yok).
func drawn() -> String:
	return str(def.get("draw", ""))


## Uzak sürünün gölgelendirici ölçüleri (herd_field.gdshader; boy ve uzunluğa oran): {hip, neck: [y, z], tail: [y, z], graze, tints}.
func herd_look() -> Dictionary:
	var h: Variant = def.get("herd")
	return h if h is Dictionary else {}
