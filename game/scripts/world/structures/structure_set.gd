class_name StructureSet
extends Node3D
## Bir dünyanın yapıları (godot.md §4.6 «Yurt»; structures.md §13.5, §13.6; settlement.md §13.3): kayıt sayısı (≤160), canlı yapı
## (≤48), yurtların uzaklık kademesi ve gece ışığı. MapWorld ilk yapı kaydında kurar («Places/Structures»).
##
## Uzaklık kademesi (kamera hedefinden, 4 Hz; ±4 m pay): en yakın 4 yurt ≤40 m'de tam yurdu (StagedYurt; winter, açık yurtta iç ve oda),
## 40–220 m YurtField'in kapalı örneği (≈1,5k üçgen, millet başına 1 çizim + 1 gölge), ötesi uzak kubbe (96 üçgen). Yakına giren yurt
## örneğini bırakır, kendi düğümünü kurar; aşama, hasar ve yanık kayıttan okunur. Kapalı yurtlar uzakta da engeldir (bu düğüm daireyi
## verir). Gece ocak ışığı sızar: kapalı yurdun kapı aralığı (glow) akşamdan şafağa yanar; nöbet ateşleri 16:30'da yanar, 07:40'ta söner
## (act1.md §5). Saat oturumundur (Main/Session; yoksa gündüz).
##   var set := StructureSet.new()
##   set.ground = map.ground; set.snow = 0.8
##   places.add_child(set)
##   var slot := set.yurt_slot(normalized_record, xform)

const NEAR_M := 40.0
const NEAR_MAX := 4
const FAR_M := 220.0
const HYSTERESIS := 4.0
const UPDATE_S := 0.25
const CLOCK_S := 2.0
## Nöbet ateşinin saatleri (act1.md §4 «9 nöbet ateşi»; gün dakikası).
const FIRE_ON := 990.0
const FIRE_OFF := 460.0

var ground: Object
var snow := 0.0
## Odak (oyuncu); yoksa takip kamerasının hedefi, o da yoksa kamera.
var focus: Node3D
var slots: Array[YurtSlot] = []
var field: YurtField
## Kayıt sayısı (build'e gelen yapılar) ve en çok canlı yapı (ölçüm).
var records := 0
var live_peak := 0
## Saat kaynağı (Callable → gün dakikası); verilmezse Main/Session'ın saati.
var clock_source: Callable

var _tick := 0.0
var _clock_tick := 0.0
var _night := 0.0


func _init() -> void:
	name = "Structures"


func _ready() -> void:
	add_to_group(World.OBSTACLE_GROUP)
	if field == null:
		field = YurtField.new()
		field.name = "YurtField"
		add_child(field)
	field.snow = snow
	set_process(true)


## Yurt kaydının yuvası (yerinde; kademesini bu düğüm seçer).
func yurt_slot(r: Dictionary, xf: Transform3D) -> YurtSlot:
	if field == null:
		field = YurtField.new()
		field.name = "YurtField"
		add_child(field)
	var slot := YurtSlot.new()
	slot.record = r
	slot.owner_set = self
	slot.transform = xf
	slots.append(slot)
	records += 1
	field.add_entry(slot)
	return slot


## Yapı kaydı sayıldı (yurt dışı türler; sınır 160).
func count_record() -> void:
	records += 1


## Canlı yapı sayısı (structures.md §13.6: yakın, şantiye, hasarlı): ağaçtaki aşamalı yapılar; yalnız aşaması olan türler ve yurtlar sayılır
## (aşamasız eşya: sayım taşı, iş tahtası, fener, kazan, odunluk, hela, kapı, kara bez sayılmaz).
func live_count() -> int:
	var n := 0
	var root := get_parent() if get_parent() else self
	for node in root.find_children("*", "StagedStructure", true, false):
		var s := node as StagedStructure
		if s.is_inside_tree() and (s is StagedYurt or StructureCatalog.stages_of(s.kind) > 0):
			n += 1
	return n


func open_count() -> int:
	var n := 0
	for s in slots:
		if bool(s.record.get("open", false)):
			n += 1
	return n


func _process(delta: float) -> void:
	_tick -= delta
	if _tick <= 0.0:
		_tick = UPDATE_S
		update_levels()
	_clock_tick -= delta
	if _clock_tick <= 0.0:
		_clock_tick = CLOCK_S
		_update_clock()


## Kademeleri seçer: odaktan uzaklık; yakın kümeye girenler tam yurt olur.
func update_levels(at: Variant = null) -> void:
	var f := _focus_point() if at == null else at as Vector3
	if f == Vector3.INF:
		f = global_position
	var ranked: Array = []
	for s in slots:
		var d := Vector2(s.global_position.x - f.x, s.global_position.z - f.z).length()
		var limit := NEAR_M + (HYSTERESIS if s.is_near() else 0.0)
		if d <= limit:
			ranked.append([d, s])
	ranked.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var near := {}
	for i in mini(ranked.size(), NEAR_MAX):
		near[ranked[i][1]] = true
	for s in slots:
		var d := Vector2(s.global_position.x - f.x, s.global_position.z - f.z).length()
		if near.has(s):
			s.make_near()
		else:
			s.make_far()
		field.set_level(s, YurtField.HIDDEN if near.has(s) else (YurtField.DOME if d > FAR_M + (HYSTERESIS if s.field_level == YurtField.DOME else 0.0) else YurtField.CLOSED))
	live_peak = maxi(live_peak, live_count())


func _focus_point() -> Vector3:
	if is_instance_valid(focus):
		return focus.global_position
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam == null:
		return Vector3.INF
	var p := cam.get_parent()
	var t: Variant = p.get(&"target") if p else null
	if t is Node3D and is_instance_valid(t):
		return (t as Node3D).global_position
	# Kameranın yere değen bakış noktası.
	var fwd := -cam.global_transform.basis.z
	if fwd.y < -0.05:
		var h := cam.global_position.y - (global_position.y)
		return cam.global_position + fwd * (h / -fwd.y)
	return cam.global_position


## Gün dakikası (saat yoksa öğle).
func day_minute() -> float:
	if clock_source.is_valid():
		return float(clock_source.call())
	var session := get_tree().root.get_node_or_null(^"Main/Session") if is_inside_tree() else null
	var clock: Variant = session.get(&"clock") if session else null
	if clock is GameClock:
		return (clock as GameClock).minute
	return 720.0


func _update_clock() -> void:
	var m := day_minute()
	# Gece: 18:30'dan 06:00'ya parıltı (akşam ve şafakta yumuşak geçiş).
	var dusk := smoothstep(1080.0, 1170.0, m)
	var dawn := 1.0 - smoothstep(300.0, 390.0, m)
	_night = maxf(dusk, dawn)
	field.set_glow(_night)
	var lit := m >= FIRE_ON or m < FIRE_OFF
	var root := get_parent() if get_parent() else self
	for node in root.find_children("*", "StagedStructure", true, false):
		var s := node as StagedStructure
		if s.kind == "watch_fire":
			for c in s.get_children():
				if c.has_meta(&"fire"):
					(c as Node3D).visible = lit
			s.glow = 1.0 if lit else 0.0
			s.refresh()
		elif s is StagedYurt and not (s as StagedYurt).open:
			s.glow = _night
			s.refresh()


# --- Engeller --------------------------------------------------------------------------------------------------

## Uzaktaki (tam olmayan) yurtların daireleri.
func get_obstacle_circles() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for s in slots:
		if s.is_near() or int(s.record.get("stage", 7)) < 2:
			continue
		var r: float = s.dims().get("foot", 3.55)
		out.append(Vector3(s.global_position.x, s.global_position.z, r))
	return out


## Bir yuva (yurt yuvası) yakın mı uzak mı (sınama).
func level_of(id: String) -> int:
	for s in slots:
		if str(s.record.get("id", "")) == id:
			return YurtField.NEAR if s.is_near() else s.field_level
	return -1
