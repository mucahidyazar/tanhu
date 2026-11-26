class_name MapSky
extends Node
## İç haritanın saatli ışığı (godot.md §4.9; time.md §5; K20, K58): haritanın ışık dosyası bir LightStops tablosu taşıyorsa (order, stops,
## places; Kışlak: data/maps/kislak/light.json, altı durak, Hexi 38,9°K) oturumun saatinden (GameClock) saniyede 4 örnek üretir ve SkyRig'e
## verir (feed_clock). Işığın tek yazıcısı SkyRig kalır: sinema sabit örnek koyarsa saat örneği saklanır, kalkınca döner. Tablo yoksa
## (deneme haritası) bind false döner, sahnenin açılış örneği durur. Yön oyun dakikasında bir adım değişir (LightStops); gölgeyi ≥15°'deki
## güneş düşürür (Daylight.light_dir: altındaysa yön 15°'ye kıstırılır, K58'in gölge kareleri).
##   var sky := MapSky.new(); world.add_child(sky)
##   sky.bind(session.clock, world.get_sky_rig(), "res://data/maps/kislak/light.json", "kislak")

## Saniyedeki örnek sayısı (GameClock'un 4 Hz'i).
const RATE := 4.0

var clock: GameClock
var rig: SkyRig
var table: Dictionary = {}
var place_id := ""
## Son yazılan örneğin saati (sınama): [gün, dakika].
var last_fed := Vector2(-1.0, -1.0)

var _acc := 0.0


## Işık dosyası LightStops tablosu mu (altı duraklı order, stops ve en az bir yer)?
static func has_stops(path: String) -> bool:
	if path.is_empty() or not FileAccess.file_exists(path):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return false
	var d: Dictionary = parsed
	return (d.get("order", []) as Array).size() == 6 and d.get("stops") is Dictionary and not (d.get("places", {}) as Dictionary).is_empty()


## Saati ve göğü bağlar; hemen bir örnek yazar. p_place boşsa tablonun ilk yeri. Döner: bağlandı mı (tablo yoksa false).
func bind(p_clock: GameClock, p_rig: SkyRig, light_path: String, p_place: String = "") -> bool:
	clock = p_clock
	rig = p_rig
	table = LightStops.load_table(light_path) if has_stops(light_path) else {}
	if table.is_empty() or clock == null or rig == null:
		set_process(false)
		return false
	var places: Dictionary = table.get("places", {})
	place_id = p_place if places.has(p_place) else str(places.keys()[0])
	set_process(true)
	feed()
	return true


func _process(delta: float) -> void:
	_acc += delta
	if _acc < 1.0 / RATE:
		return
	_acc = 0.0
	feed()


## Şimdinin örneğini yazar.
func feed() -> void:
	if clock == null or not is_instance_valid(rig) or table.is_empty():
		return
	rig.feed_clock(sample_at(clock.day_n, clock.minute))
	last_fed = Vector2(float(clock.day_n), clock.minute)


## Tablonun o andaki örneği (saf olmayan: tablo bağlı olmalı).
func sample_at(day_n: int, minute: float) -> Dictionary:
	return LightStops.sample(table, place_id, day_n, minute)


## Geliştirme koşusunun saati (K58 kareleri; main.gd --state=kislak): --light=<durak> tablonun ölçüm dakikası (probe; clamp_am ve clamp_pm
## gölge kıstırması), ya da --clock=HH:MM; --day=N gün. Döner: Vector2(gün, dakika); istenmediyse (-1, -1).
static func dev_time(light_path: String, args: Dictionary) -> Vector2:
	if not has_stops(light_path):
		return Vector2(-1.0, -1.0)
	var t := LightStops.load_table(light_path)
	var probe: Dictionary = t.get("probe", {})
	var day := float(args["day"]) if args.has("day") and str(args["day"]).is_valid_int() else float(probe.get("day_n", -1))
	if args.has("light") and probe.has(str(args["light"])):
		return Vector2(day, GameClock.parse_hhmm(probe[str(args["light"])]))
	if args.has("clock"):
		var m := GameClock.parse_hhmm(str(args["clock"]))
		if m >= 0.0:
			return Vector2(day, m)
	return Vector2(-1.0, -1.0)
