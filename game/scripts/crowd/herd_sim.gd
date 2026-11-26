class_name HerdSim
extends RefCounted
## Sürünün saf benzetimi (fauna.md §10: FaunaDirector'un sürü işi, 4 Hz; aradaki kareleri HerdField ara değerler). Düğüm kurmaz,
## gölgelendiriciye dokunmaz: tests/unit/test_herd_field.gd kareler çizmeden sınar. Sürü ajan taşımaz; her koyun bir kuyruk durumu
## ve kısa bir rota izler, ayrılma itişi ile yan yana dizilir. Ayrılma gövdenin yönlü elipsiyledir (facing, body_scale): K98'in
## yukarıdan kadrajında iki koyun iç içe geçmez; önü kapanan gezinen durur, ağıldan iki sıra çıkılır.
##
## Evreler (phase):
##   PEN      ağılda: dar alanda otlar, gezer.
##   LEAVING  release(): sırayla kapıya gider, çıkar, çayırda kendi yerine yürür (bitince MEADOW, olay &"settled"; son koyun kapıdan
##            çıkınca olay &"released"). release(…, hold) son hold koyunu (kapıdan en uzaktakiler) ağılda bırakır: otlar, ağılda gezinir;
##            kaçınılan nokta (oyuncu) NUDGE_RADIUS'a girince çıkış yoluna düşer (Çocukluk: «Koyunları ağıldan sen çıkaracaksın.»).
##            release_held() hepsini birden salar.
##   MEADOW   çayırda: otlar, kısa kısa yer değiştirir, sürü yavaşça sürüklenir ama diskin içinde kalır.
##   DRIVING  drive(): rotada tek sıra yürür; her koyun count_at noktasına varınca bir kez sayılır (olay &"counted"); sonra after
##            diskine yayılır (bitince COUNTED, olay &"count_finished").
##   COUNTED  sayımdan sonra otlar.
##   DRIVEN   (E21, K110: «Çobanlık») çocuklar sürer: koyun sürücüden (drivers: oyuncu, binilen koyun, kanattaki çocuklar) kaçar, kaçarken yolun
##            ileri yönüne (drive_path) kayar, sürünün ortasına toplanır, öndekini (leader: Luhun) izler; sıkıştırılmayan koyun yavaşlar ve otlar.
##            stray(): birkaç koyun (yanı seçilir) yoldan sapar, sürücü önüne geçince sürüye döner (olay &"stray_back"). Sürünün ortası hedefe
##            varınca olay &"arrived". gate verilmişse (count_through) iki taşın arasından geçen koyun bir kez sayılır (&"gate_counted"); pen_home
##            açıkken kapıya yaklaşan koyun ağıla girer, girerken sayılır (&"penned"; hepsi girince &"all_in").
##   WATER    (E21) göl kıyısında: koyunlar suya koşar (water_line'ın en yakın noktasına), içer, sonra kıyının otlağında otlar (calm).
##   hidden   take_out(i) koyunu benzetimden çıkarır (balçıktaki kuzu: HerdField çizmez), put_back(i, yer) geri koyar.
## Olaylar events dizisine yazılır: HerdField her tikten sonra okur ve sinyale çevirir.
##
## Yerler spec'tedir (layout.json "childhood": pen, herd). Ağıl RingWall'dur: oyuncunun çarptığı duvarla aynı; koyun kapıdan başka
## yerden geçemez. Kapı kapalıyken (gate_open = false) kapı aralığı ObstacleBox ile kapalıdır.

enum Phase { PEN, LEAVING, MEADOW, DRIVING, COUNTED, DRIVEN, WATER }
enum Mode { GRAZE, AMBLE, WAIT, ROUTE }

## Benzetim adımı (saniye): 4 Hz.
const TICK := 0.25
## Koyunun engele çarpma yarıçapı (metre).
const BODY_RADIUS := 0.36
## Koyunun üstten görünen gövdesi: yönüne göre elips (yarı boy, yarı en; metre, boy çarpanı 1; kinds.json boyu 1,264 m + pay). İki koyunun
## merkezleri elipslerinin o yöndeki yarıçapları toplamından yakınsa ayrılırlar: yan yana sokulur (≈0,64 m), baş kuyruğa binmez (≈1,36 m).
const BODY_HALF_LENGTH := 0.68
const BODY_HALF_WIDTH := 0.32
## Yönün dönmesi için gereken en az kendi hızı (m/sn): komşunun küçük itişi koyunu döndürmez; oyuncudan kaçan itiş (PUSH_TURN) döndürür.
const TURN_SPEED := 0.05
const PUSH_TURN := 0.5
## Gezinen koyunun önü bu hız çarpanının altına kapanınca durur (bkz. _approach_slow).
const BLOCKED_SLOW := 0.3
## Ağıldan çıkışın iki sırasının kapı ortasından yana uzaklığı (metre).
const RELEASE_LANE := 0.5
## Rotada önündekine bu kadar yaklaşan koyun yavaşlar.
const FOLLOW_GAP := 1.5
## Rota noktasına bu uzaklıkta varılmış sayılır.
const WAYPOINT_REACH := 0.7
## Ayrılma itişinin hıza çevrilmesi (1/sn) ve en büyük itiş hızı (m/sn).
const PUSH_GAIN := 1.6
const PUSH_MAX := 1.2
## Ağılda bırakılan koyunu kaçınılan noktanın (oyuncu) yürüten uzaklığı (m).
const NUDGE_RADIUS := 3.0
## Otlama ve ağır yürüyüş.
const IDLE_RANGE := Vector2(3.0, 11.0)
const AMBLE_SPEED := Vector2(0.45, 0.8)
const WANDER_RANGE := Vector2(0.8, 2.8)
## Yerinde otlarken başın aşağıda olma olasılığı.
const GRAZE_SHARE := 0.8

var count := 40
var phase := Phase.PEN
var clock := 0.0
## Kapı açık mı? (kapalıyken kapı aralığı kapalıdır: LEAVING ve DRIVING kendisi açar)
var gate_open := false

var pos := PackedVector2Array()
var prev := PackedVector2Array()
var vel := PackedVector2Array()
## Koyunun baktığı yön (birim, x z): yalnız kendi yürüyüşüyle döner; HerdField gövdeyi buna çevirir.
var facing := PackedVector2Array()
## Koyunun boy çarpanı (1 = kinds.json boyu; HerdField kuzuları ve iri koyunları yazar): ayrılma elipsi buna göre büyür.
var body_scale := PackedFloat32Array()
var goal := PackedVector2Array()
## Çayırdaki (ya da sayım sonrası) yer: sürüklenir.
var spot := PackedVector2Array()
var mode := PackedByteArray()
var grazing := PackedByteArray()
var timer := PackedFloat32Array()
var start_at := PackedFloat32Array()
var pace := PackedFloat32Array()
var route_i := PackedInt32Array()
var routes: Array[PackedVector2Array] = []
var jitter := PackedVector2Array()
var counted := PackedByteArray()
var out_of_pen := PackedByteArray()
var settled_flags := PackedByteArray()
## Ağılda bırakılan (dürtülmeyi bekleyen) koyunlar.
var held := PackedByteArray()
var tally := 0
## Bu tikte olanlar: {"type": &"released" | &"settled" | &"counted" | &"count_finished", "index": int, "tally": int}.
var events: Array[Dictionary] = []

# --- E21 (K110): sürülen sürü ---
## Sürücüler Vector3(x, z, ürkme yarıçapı): oyuncu (binilen koyunun sırtında da), kanattaki çocuklar. Koyun bu yarıçapın içinde kaçar.
var drivers: Array[Vector3] = []
## Sürünün yolu (başından hedefe) ve hedefin yarıçapı; öndeki (Luhun; yoksa INF).
var drive_path := PackedVector2Array()
var drive_goal := Vector2.INF
var goal_radius := 10.0
var leader := Vector2.INF
## Kaçışın, yürüyüşün ve sürülürken en yüksek hız (m/sn; K105'in sınırı oyuncunun koşusudur: 3,6).
var flee_speed := 2.7
var herd_walk := 1.05
var drive_max := 3.2
## Sürünün toplanma yarıçapı (m): ortadan bundan uzak koyun ortaya çekilir; yolun koridoru (m): yolun bu kadar dışına çıkan koyun yola çekilir.
var cohesion_radius := 7.0
var corridor := 14.0
## Benzetimden çıkarılan koyun (balçıktaki kuzu) ve sapanlar.
var hidden := PackedByteArray()
var straying := PackedByteArray()
var stray_to := PackedVector2Array()
## Sayım kapısı (iki taş; a == b ise yok) ve kapıdan sayılanlar.
var gate_a := Vector2.INF
var gate_b := Vector2.INF
var gate_tally := 0
var gate_counted := PackedByteArray()
## Kapının ileri yönü (yolun kapıdan geçtiği yön; count_through hesaplar).
var gate_fwd := Vector2.RIGHT
## Ağıla dönüş: kapıya yaklaşan koyun ağıla girer, sayılır.
var pen_home := false
var penned := PackedByteArray()
var pen_tally := 0
## Göl kıyısı: su çizgisi (kıyının noktaları), içme süresi, otlağın merkezi ve yarıçapı.
var water_line := PackedVector2Array()
var water_graze := Vector2.ZERO
var water_graze_radius := 12.0
var drink_left := PackedFloat32Array()
var _pressure := PackedFloat32Array()
var _arrived_sent := false
var _all_in_sent := false
var _center := Vector2.ZERO
## Sürünün bütününün baskısı (0..1; yumuşatılmış): arkadan sıkıştırılan sürü bütün olarak yolun ileri yönüne yürür (sürü yolu bilir).
var _flock_push := 0.0
## Sürünün bütününün yürüyüşü (m/sn; baskı 1 iken).
var flock_speed := 3.0
## Kaçışın yolun ileri yönüne eğilimi (kaçış yönü = uzağa + ileri × bu) ve sürünün gövdesinin yarıçapı (m; ortanın ve arkanın ölçüsü).
const FLEE_FORWARD := 1.4
const CORE_M := 20.0
## Sayım kapısının hunisi: kapının önünde bu kadar (m) uzaktaki sayılmamış koyunun ileri yönü iki taşın arasına döner; kapının ortasından
## bu payı (kapı yarı boyunun oranı: iki taşın arası) hedeflenir.
const GATE_FUNNEL_M := 18.0
const GATE_INNER := 0.34
## Eve dönüşte sürünün kendi yürüyüşü (baskının en azı; flock_speed'in oranı).
const HOME_WALK := 0.7

## Sabit engeller Vector3(x, z, yarıçap) (yurtlar, taş, kazıklar; ChildhoodSite verir). E21: engeller OBSTACLE_CELL'lik ızgaraya dizilir
## (her engel değdiği hücrelere): koyun yalnız kendi hücresindekilere bakar (yolun kayaları yüzlercedir; kurulum ve tik engel sayısıyla
## büyümez). Dizi yerinde büyütülürse ızgara ilk çözümde yeniden kurulur.
var obstacles: Array[Vector3] = []:
	set(value):
		obstacles = value
		_obstacle_grid_n = -1
const OBSTACLE_CELL := 8.0
var _obstacle_grid: Dictionary = {}
var _obstacle_grid_n := -1
var _no_obstacles := PackedInt32Array()
## Kaçınılan hareketli noktalar Vector3(x, z, yarıçap): oyuncu ve bineği. Koyun yol verir; oyuncu koyuna çarpmaz.
var avoid: Array[Vector3] = []

var pen_center := Vector2.ZERO
var pen_radius := 8.0
var gate_dir := Vector2.RIGHT
var gate_width := 2.4
var wall: RingWall
var gate_box: ObstacleBox
var meadow_center := Vector2.ZERO
var meadow_radius := 12.0
var after_center := Vector2.ZERO
var after_radius := 8.0
var walk_speed := 1.1
var lead_speed := 1.25
var drive_speed := 2.2
var release_cadence := 0.45
var drive_cadence := 0.66
var line_route := PackedVector2Array()
var count_at := 0

var _rng := RandomNumberGenerator.new()
var _push := PackedVector2Array()
var _slow := PackedFloat32Array()
var _out_count := 0
var _settled_count := 0
var _released_sent := false
var _active_center := Vector2.ZERO
var _active_radius := 12.0


## spec: layout.json "childhood" sözlüğü; speeds: türün hızları (walk, trot; FaunaKind).
func _init(spec: Dictionary = {}, speeds: Dictionary = {}) -> void:
	var pen: Dictionary = spec.get("pen", {})
	var herd: Dictionary = spec.get("herd", {})
	count = maxi(int(herd.get("count", 40)), 1)
	_rng.seed = int(herd.get("seed", 410))
	pen_center = OrdosGround._vec2(pen.get("at", [0.0, 0.0]))
	pen_radius = float(pen.get("radius", 8.0))
	gate_width = float(pen.get("gate_width", 2.4))
	gate_dir = azimuth_vector(float(pen.get("gate_az", 90.0)))
	wall = pen_wall(pen)
	gate_box = pen_gate_box(pen)
	var meadow: Dictionary = herd.get("meadow", {})
	meadow_center = OrdosGround._vec2(meadow.get("center", [0.0, 0.0]))
	meadow_radius = float(meadow.get("radius", 12.0))
	var line: Dictionary = herd.get("line", {})
	for p: Array in line.get("route", []):
		line_route.append(OrdosGround._vec2(p))
	count_at = int(line.get("count_at", 0))
	var after: Dictionary = line.get("after", {})
	after_center = OrdosGround._vec2(after.get("center", [0.0, 0.0]))
	after_radius = float(after.get("radius", 8.0))
	walk_speed = float(speeds.get("walk", walk_speed))
	lead_speed = float(herd.get("lead_speed", walk_speed * 1.15))
	drive_speed = float(line.get("speed", drive_speed))
	release_cadence = float(herd.get("release_cadence", release_cadence))
	drive_cadence = float(line.get("cadence", drive_cadence))
	_active_center = pen_center
	_active_radius = pen_radius - 0.9
	_alloc()
	place_in_pen()
	var drive: Dictionary = herd.get("drive", {})
	flee_speed = float(drive.get("flee_speed", flee_speed))
	herd_walk = float(drive.get("walk", herd_walk))
	drive_max = float(drive.get("max", drive_max))
	cohesion_radius = float(drive.get("cohesion", cohesion_radius))
	corridor = float(drive.get("corridor", corridor))
	flock_speed = float(drive.get("flock_speed", flock_speed))


## Pusula azimutundan (0 kuzey, 90 doğu) düzlem yönü (x, z).
static func azimuth_vector(az_deg: float) -> Vector2:
	var a := deg_to_rad(az_deg)
	return Vector2(sin(a), -cos(a))


## Ağılın duvarı (saf): kapılı daire. Kapı aralığı gate_width kadardır.
static func pen_wall(pen: Dictionary) -> RingWall:
	return RingWall.new(OrdosGround._vec2(pen.get("at", [0.0, 0.0])), float(pen.get("radius", 8.0)), azimuth_vector(float(pen.get("gate_az", 90.0))),
		float(pen.get("gate_width", 2.4)) * 0.5, float(pen.get("thickness", 0.3)))


## Kapalı kapının kutusu (saf): kapı aralığını örter.
static func pen_gate_box(pen: Dictionary) -> ObstacleBox:
	var dir := azimuth_vector(float(pen.get("gate_az", 90.0)))
	var center := OrdosGround._vec2(pen.get("at", [0.0, 0.0])) + dir * float(pen.get("radius", 8.0))
	var half := float(pen.get("gate_width", 2.4)) * 0.5 + 0.05
	return ObstacleBox.new(center, Vector2(half, 0.18), Vector2(-dir.y, dir.x))


# --- Sürüş --------------------------------------------------------------------------------------------

## Koyunları ağıla yerleştirir (anında); kapı kapanır.
func place_in_pen() -> void:
	_reset_flags()
	gate_open = false
	phase = Phase.PEN
	_active_center = pen_center
	_active_radius = pen_radius - 0.9
	var points := scatter_points(pen_center, _active_radius, count, _rng, 1.3)
	for i in count:
		_put(i, points[i])
		_rest(i)
	relax()
	prev = pos.duplicate()


## Koyunları çayıra yerleştirir (anında; atlanan sahne, ölçüm). center boşsa düzen dosyasının çayırı.
func place_on_meadow(center: Variant = null, radius: float = -1.0) -> void:
	_reset_flags()
	gate_open = true
	_use_meadow(center, radius)
	phase = Phase.MEADOW
	var points := scatter_points(_active_center, _active_radius, count, _rng, 1.6)
	for i in count:
		_put(i, points[i])
		spot[i] = points[i]
		out_of_pen[i] = 1
		settled_flags[i] = 1
		_rest(i)
	relax()
	_out_count = count
	_settled_count = count
	_released_sent = true
	prev = pos.duplicate()


## Sayımdan sonraki yere yerleştirir (anında).
func place_after_count() -> void:
	_reset_flags()
	gate_open = true
	_active_center = after_center
	_active_radius = after_radius
	phase = Phase.COUNTED
	var points := scatter_points(after_center, after_radius, count, _rng, 1.4)
	for i in count:
		_put(i, points[i])
		spot[i] = points[i]
		out_of_pen[i] = 1
		counted[i] = 1
		settled_flags[i] = 1
		_rest(i)
	relax()
	tally = count
	_out_count = count
	_settled_count = count
	_released_sent = true
	prev = pos.duplicate()


## Yerleştirmeden sonra gövdeler ayrılır (zaman akmadan; rng ilerlemez): ayrılma itişi birkaç tur doğrudan uygulanır, koyun diskinde ve
## ağılın duvarı içinde kalır; yeri ve hedefi yeni konumdur. İlk karede iç içe geçmiş koyun görünmesin.
func relax(rounds: int = 10) -> void:
	for _round in rounds:
		_compute_push()
		for i in count:
			var p := pos[i]
			pos[i] = _resolve(p, clamp_to_disc(p + _push[i], _active_center, _active_radius + 0.5))
	for i in count:
		goal[i] = pos[i]
		spot[i] = pos[i]


## Kapı açılır, koyunlar sırayla çıkıp çayıra yayılır. center ve radius verilmezse düzen dosyasının çayırı.
func release(center: Variant = null, radius: float = -1.0, hold: int = 0) -> void:
	gate_open = true
	_use_meadow(center, radius)
	phase = Phase.LEAVING
	_out_count = 0
	_settled_count = 0
	_released_sent = false
	held.fill(0)
	var inner := pen_center + gate_dir * (pen_radius - 1.4)
	var outer := pen_center + gate_dir * (pen_radius + 1.2)
	var clear := pen_center + gate_dir * (pen_radius + 4.5)
	var path := PackedVector2Array([inner, outer, clear])
	var order := _order_by_distance(inner)
	var points := scatter_points(_active_center, _active_radius, count, _rng, 1.6)
	# Önden çıkan en uzak yere gider: arkadan gelen öncekilerin içinden geçmesin.
	var by_far := _sort_far_first(points, clear)
	for k in count:
		var i: int = order[k]
		routes[i] = path
		route_i[i] = 0
		spot[i] = by_far[k]
		out_of_pen[i] = 0
		settled_flags[i] = 0
		start_at[i] = clock + float(k) * release_cadence
		pace[i] = lead_speed * _rng.randf_range(0.92, 1.1)
		# Kapıdan iki sıra çıkılır (kapı 2,4 m: yan yana iki koyun sığar, tek sırada baş kuyruğa binerdi).
		var lane := RELEASE_LANE if k % 2 == 0 else -RELEASE_LANE
		jitter[i] = (lane + _rng.randf_range(-0.08, 0.08)) * Vector2(-gate_dir.y, gate_dir.x)
		mode[i] = Mode.WAIT
		grazing[i] = 0
		if k >= count - clampi(hold, 0, count):
			# Geride kalan: ağılda otlar, dürtülünce çıkar.
			held[i] = 1
			start_at[i] = INF
			_rest(i)


## Sürüyü sayım hattından geçirir: rotada tek sıra; rotanın count_at noktasına varan koyun bir kez sayılır. Ağılda kalan koyun önce kapıdan çıkar.
func drive() -> void:
	if line_route.is_empty():
		push_warning("[herd] sayım rotası yok")
		return
	gate_open = true
	phase = Phase.DRIVING
	tally = 0
	_settled_count = 0
	_active_center = after_center
	_active_radius = after_radius
	var order := _order_by_distance(line_route[0])
	var points := scatter_points(after_center, after_radius, count, _rng, 1.4)
	var by_far := _sort_far_first(points, line_route[line_route.size() - 1])
	var door_inner := pen_center + gate_dir * (pen_radius - 1.4)
	var door_outer := pen_center + gate_dir * (pen_radius + 1.2)
	var side := Vector2.RIGHT
	for k in count:
		var i: int = order[k]
		var path := line_route
		if pos[i].distance_to(pen_center) < pen_radius:
			path = PackedVector2Array([door_inner, door_outer])
			path.append_array(line_route)
		routes[i] = path
		route_i[i] = 0
		spot[i] = by_far[k]
		counted[i] = 0
		settled_flags[i] = 0
		start_at[i] = clock + float(k) * drive_cadence
		pace[i] = drive_speed * _rng.randf_range(0.96, 1.06)
		jitter[i] = _rng.randf_range(-0.22, 0.22) * side
		mode[i] = Mode.WAIT
		grazing[i] = 1 if _rng.randf() < 0.6 else 0


## Sayılan koyun sayısı.
func counted_total() -> int:
	return tally


## Ağıldan çıkan koyun sayısı.
func released_total() -> int:
	return _out_count


## Ağılda bırakılan (henüz dürtülmemiş) koyun sayısı.
func held_count() -> int:
	var n := 0
	for i in count:
		n += held[i]
	return n


## Ağılda bırakılan koyunların yerleri.
func held_positions() -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in count:
		if held[i] == 1:
			out.append(pos[i])
	return out


## Bırakılanları birden salar (yaşlı koyun binicisiyle çıkınca sürü ardından gelir).
func release_held() -> void:
	for i in count:
		if held[i] == 1:
			_nudge(i, 0.15 * float(i % 5))


func _nudge(i: int, delay: float) -> void:
	held[i] = 0
	mode[i] = Mode.WAIT
	start_at[i] = clock + delay
	grazing[i] = 0


## Sayımın bitmesine kalan tahmini süre (sn): sayılmamış her koyunun yola çıkışına kalan süresi ve sayım noktasına kalan yolu / kendi hızı;
## en büyüğü (önündekini izlerken yavaşlama sayılmaz: alt tahmin). Sürüş yoksa ya da hepsi sayıldıysa 0. Çocukluk'ta sayımın vaktine
## yetişen görünür akış bu süreye yayılır (ChildhoodScene).
func count_eta() -> float:
	if phase != Phase.DRIVING or line_route.is_empty():
		return 0.0
	var worst := 0.0
	for i in count:
		if counted[i] == 1:
			continue
		var path := routes[i]
		var target := path.size() - line_route.size() + count_at
		var at := pos[i]
		var d := 0.0
		for k in range(route_i[i], mini(target, path.size() - 1) + 1):
			var q := path[k] + jitter[i]
			d += at.distance_to(q)
			at = q
		var wait := maxf(start_at[i] - clock, 0.0) if mode[i] == Mode.WAIT else 0.0
		worst = maxf(worst, wait + d / maxf(pace[i], 0.1))
	return worst


# --- Adım ---------------------------------------------------------------------------------------------

## Bir benzetim adımı (TICK saniye).
func step() -> void:
	clock += TICK
	prev = pos.duplicate()
	events.clear()
	if phase == Phase.LEAVING and not avoid.is_empty():
		for i in count:
			if held[i] == 1:
				for a in avoid:
					if pos[i].distance_to(Vector2(a.x, a.y)) <= NUDGE_RADIUS:
						_nudge(i, 0.0)
						break
	_compute_push()
	if phase == Phase.DRIVEN or phase == Phase.WATER:
		_drive_prepare()
	for i in count:
		if hidden[i] == 1:
			vel[i] = Vector2.ZERO
			continue
		if phase == Phase.DRIVEN:
			_drive_sheep(i)
		elif phase == Phase.WATER and mode[i] == Mode.ROUTE:
			_water_sheep(i)
		else:
			_step_sheep(i)
	_check_phase()


func _step_sheep(i: int) -> void:
	var p := pos[i]
	var desired := Vector2.ZERO
	match mode[i]:
		Mode.GRAZE:
			timer[i] -= TICK
			if timer[i] <= 0.0:
				_wander(i)
		Mode.AMBLE:
			var to_goal := goal[i] - p
			var d := to_goal.length()
			if d < 0.3:
				_arrive(i)
			elif _slow[i] < BLOCKED_SLOW and _calm():
				# Önü kapanan koyun itişmez: durur, olduğu yerde otlar (ağılda, çayırda; sürüşte yürür).
				_rest(i)
			else:
				desired = to_goal / d * pace[i]
		Mode.WAIT:
			if clock >= start_at[i]:
				mode[i] = Mode.ROUTE
				grazing[i] = 0
		Mode.ROUTE:
			desired = _follow_route(i, p)
	var v := desired
	if mode[i] == Mode.ROUTE or mode[i] == Mode.AMBLE:
		v *= _slow[i]
	var push := (_push[i] * PUSH_GAIN).limit_length(PUSH_MAX if mode[i] != Mode.ROUTE else PUSH_MAX * 0.6)
	# Yön kendi yürüyüşünden gelir; komşunun itişi koyunu yan kaydırır ama döndürmez, oyuncudan kaçış döndürür.
	if desired.length_squared() > TURN_SPEED * TURN_SPEED:
		facing[i] = desired.normalized()
	elif push.length_squared() > PUSH_TURN * PUSH_TURN:
		facing[i] = push.normalized()
	v += push
	vel[i] = v
	var next := p + v * TICK
	next = _resolve(p, next)
	pos[i] = next


func _follow_route(i: int, p: Vector2) -> Vector2:
	var path := routes[i]
	var idx := route_i[i]
	if idx >= path.size():
		_end_route(i)
		return Vector2.ZERO
	var target := path[idx] + jitter[i]
	var to_target := target - p
	var d := to_target.length()
	if d < WAYPOINT_REACH:
		_on_waypoint(i, path, idx)
		route_i[i] = idx + 1
		return _follow_route(i, p)
	return to_target / d * pace[i]


## Rotanın bir noktasına varıldı: sayım noktasında sayılır, ağıl kapısının dışında çıktı yazılır.
func _on_waypoint(i: int, path: PackedVector2Array, idx: int) -> void:
	if phase == Phase.LEAVING and idx == 1 and out_of_pen[i] == 0:
		out_of_pen[i] = 1
		_out_count += 1
		if _out_count == count and not _released_sent:
			_released_sent = true
			events.append({"type": &"released", "index": i, "tally": _out_count})
	if phase == Phase.DRIVING and counted[i] == 0:
		# Ağıldan gelen koyunun rotası kapı noktalarıyla uzar: sayım noktası sondan sayılır.
		if idx == path.size() - line_route.size() + count_at:
			counted[i] = 1
			tally += 1
			events.append({"type": &"counted", "index": i, "tally": tally})
			if tally == count:
				events.append({"type": &"count_finished", "index": i, "tally": tally})


func _end_route(i: int) -> void:
	goal[i] = spot[i]
	mode[i] = Mode.AMBLE
	grazing[i] = 0


## Yerine varan koyun durur, otlar. İlk varış sürünün yerleşmesini sayar.
func _arrive(i: int) -> void:
	_rest(i)
	# Ağılda bırakılan koyun gezinirken yerleşmiş sayılmaz: sürü o çıkana dek çıkışta kalır.
	if held[i] == 0 and settled_flags[i] == 0 and (phase == Phase.LEAVING or phase == Phase.DRIVING):
		settled_flags[i] = 1
		_settled_count += 1


## Yerinde otlama süresi.
func _rest(i: int) -> void:
	mode[i] = Mode.GRAZE
	timer[i] = _rng.randf_range(IDLE_RANGE.x, IDLE_RANGE.y)
	grazing[i] = 1 if _rng.randf() < GRAZE_SHARE else 0
	vel[i] = Vector2.ZERO


## Otlayan koyun kısa bir yer değiştirir; yeri diskin içinde kalır.
func _wander(i: int) -> void:
	var a := _rng.randf() * TAU
	var r := _rng.randf_range(WANDER_RANGE.x, WANDER_RANGE.y)
	var target := spot[i] + Vector2.from_angle(a) * r
	if held[i] == 1:
		# Ağılda bırakılan ağılın içinde gezinir.
		target = clamp_to_disc(target, pen_center, pen_radius - 1.2)
	else:
		target = clamp_to_disc(target, _active_center, _active_radius)
	if phase != Phase.PEN and held[i] == 0:
		spot[i] = spot[i].lerp(target, 0.35)
	goal[i] = target
	mode[i] = Mode.AMBLE
	grazing[i] = 0
	pace[i] = _rng.randf_range(AMBLE_SPEED.x, AMBLE_SPEED.y)


## Sürü kendi hâlinde mi (ağılda, çayırda, sayımdan sonra, göl kıyısında)? Çıkış ve sürüşte koyunlar yerine yürür.
func _calm() -> bool:
	return phase == Phase.PEN or phase == Phase.MEADOW or phase == Phase.COUNTED or phase == Phase.WATER


func _check_phase() -> void:
	if phase == Phase.LEAVING and _settled_count == count:
		phase = Phase.MEADOW
		events.append({"type": &"settled", "index": -1, "tally": count})
	elif phase == Phase.DRIVING and _settled_count == count and tally == count:
		phase = Phase.COUNTED
	elif phase == Phase.DRIVEN:
		if not _arrived_sent and drive_goal.is_finite() and flock_center().distance_to(drive_goal) <= goal_radius:
			_arrived_sent = true
			events.append({"type": &"arrived", "index": -1, "tally": 0})
		# Hepsi sayıldı ve hepsi çitin içinde (kapı kapanınca dışarıda kalan olmasın).
		if pen_home and not _all_in_sent and pen_tally >= visible_count() and _inside_pen() >= visible_count():
			_all_in_sent = true
			events.append({"type": &"all_in", "index": -1, "tally": pen_tally})


## İkişer ayrılma itişi (gövde elipsleri) ve rotada önündekini izleme.
func _compute_push() -> void:
	_push.fill(Vector2.ZERO)
	_slow.fill(1.0)
	var largest := 1.0
	for s in body_scale:
		largest = maxf(largest, s)
	# Tarama gezinenin yavaşlama bandının dışına dek (gövdenin %40 dışı; bkz. _approach_slow).
	var reach := maxf(FOLLOW_GAP, 2.0 * BODY_HALF_LENGTH * largest * 1.4)
	var reach2 := reach * reach
	for i in count:
		var pi := pos[i]
		var fi := facing[i]
		var si := body_scale[i]
		var dir_i := vel[i]
		for j in range(i + 1, count):
			var delta := pos[j] - pi
			var ds := delta.length_squared()
			if ds >= reach2:
				continue
			var dist := sqrt(ds)
			var u := delta / dist if dist > 0.001 else Vector2.RIGHT
			var need := body_reach(fi, u) * si + body_reach(facing[j], u) * body_scale[j]
			if dist < need:
				var away := u * (need - dist) * 0.5
				_push[i] -= away
				_push[j] += away
			# Önündekine yürüyen yavaşlar: rotada izleme aralığı ve gövdeye değme, gezinirken gövdenin biraz dışı.
			if dir_i.dot(delta) > 0.0:
				_slow[i] = minf(_slow[i], _approach_slow(mode[i], dist, need))
			if vel[j].dot(-delta) > 0.0:
				_slow[j] = minf(_slow[j], _approach_slow(mode[j], dist, need))
		for a in avoid:
			var center := Vector2(a.x, a.y)
			var off := pi - center
			var d2 := off.length_squared()
			if d2 < a.z * a.z:
				var dist := sqrt(d2)
				_push[i] += (off / dist if dist > 0.001 else Vector2.RIGHT) * (a.z - dist) * 1.4


## Adımın sonu: engeller, ağılın duvarı ve kapalı kapı.
func _resolve(from: Vector2, to: Vector2) -> Vector2:
	var p := to
	if _obstacle_grid_n != obstacles.size():
		_build_obstacle_grid()
	var near: PackedInt32Array = _obstacle_grid.get(Vector2i(floori(p.x / OBSTACLE_CELL), floori(p.y / OBSTACLE_CELL)), _no_obstacles)
	for idx in near:
		var c := obstacles[idx]
		var center := Vector2(c.x, c.y)
		var min_dist := c.z + BODY_RADIUS
		var off := p - center
		var ds := off.length_squared()
		if ds < min_dist * min_dist:
			var dist := sqrt(ds)
			p = center + (off / dist if dist > 0.0001 else Vector2.RIGHT) * min_dist
	var reach := pen_radius + 2.0
	if from.distance_squared_to(pen_center) < reach * reach or p.distance_squared_to(pen_center) < reach * reach:
		if not gate_open:
			p = gate_box.push_out(p, BODY_RADIUS)
		p = wall.resolve(from, p, BODY_RADIUS)
	return p


## Engellerin ızgarası: her engel çemberinin (gövdenin payıyla) değdiği hücrelere.
func _build_obstacle_grid() -> void:
	_obstacle_grid.clear()
	_obstacle_grid_n = obstacles.size()
	for idx in obstacles.size():
		var c := obstacles[idx]
		var r := c.z + BODY_RADIUS + 0.05
		var lo := Vector2i(floori((c.x - r) / OBSTACLE_CELL), floori((c.y - r) / OBSTACLE_CELL))
		var hi := Vector2i(floori((c.x + r) / OBSTACLE_CELL), floori((c.y + r) / OBSTACLE_CELL))
		for gx in range(lo.x, hi.x + 1):
			for gy in range(lo.y, hi.y + 1):
				var key := Vector2i(gx, gy)
				var list: PackedInt32Array = _obstacle_grid.get(key, PackedInt32Array())
				list.append(idx)
				_obstacle_grid[key] = list


# --- Yardımcılar ----------------------------------------------------------------------------------------

## Önündeki koyuna dist uzaklıkta yürüyenin hız çarpanı (saf): need iki gövdenin o yöndeki toplam yarıçapıdır. Rotada (ROUTE) izleme aralığı
## FOLLOW_GAP ve gövdeye değme yavaşlatır (tek sıranın aralığı değişmesin); gezinen (AMBLE) gövdenin %40 dışından yavaşlar, değince durur.
static func _approach_slow(m: int, dist: float, need: float) -> float:
	if m == Mode.ROUTE:
		return minf(clampf(dist / FOLLOW_GAP, 0.15, 1.0), clampf((dist - need * 0.8) / (need * 0.2), 0.15, 1.0))
	if m == Mode.AMBLE:
		return clampf((dist - need * 0.95) / (need * 0.45), 0.1, 1.0)
	return 1.0


## Gövde elipsinin u yönündeki yarıçapı (saf; boy çarpanı 1): f koyunun yönü, u birim yön. Baş ya da kuyruk yönünde BODY_HALF_LENGTH,
## yanda BODY_HALF_WIDTH.
static func body_reach(f: Vector2, u: Vector2) -> float:
	var c := u.dot(f)
	var s2 := maxf(1.0 - c * c, 0.0)
	var a := BODY_HALF_LENGTH
	var b := BODY_HALF_WIDTH
	return a * b / sqrt(b * b * c * c + a * a * s2)


## Nokta diskin içine çekilir (saf).
static func clamp_to_disc(p: Vector2, center: Vector2, radius: float) -> Vector2:
	var off := p - center
	return center + off.limit_length(radius)


## Diske count nokta dağıtır (saf ama rng ilerler): en iyi aday yöntemi; noktalar arasında en az min_gap (sığıyorsa).
static func scatter_points(center: Vector2, radius: float, n: int, rng: RandomNumberGenerator, min_gap: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for _i in n:
		var best := center
		var best_d := -1.0
		for _try in 14:
			var a := rng.randf() * TAU
			var r := sqrt(rng.randf()) * radius
			var c := center + Vector2.from_angle(a) * r
			var nearest := INF
			for q in out:
				nearest = minf(nearest, c.distance_squared_to(q))
			if nearest > best_d:
				best_d = nearest
				best = c
			if nearest > min_gap * min_gap * 4.0:
				break
		out.append(best)
	return out


func _alloc() -> void:
	pos.resize(count)
	prev.resize(count)
	vel.resize(count)
	facing.resize(count)
	body_scale.resize(count)
	body_scale.fill(1.0)
	# Başlangıç yönleri altın açıyla dağılır (rng ilerlemez: aynı tohumun sürüsü değişmesin).
	for i in count:
		facing[i] = Vector2.from_angle(fposmod(float(i) * 2.39996 + 0.7, TAU))
	goal.resize(count)
	spot.resize(count)
	jitter.resize(count)
	_push.resize(count)
	mode.resize(count)
	grazing.resize(count)
	counted.resize(count)
	out_of_pen.resize(count)
	settled_flags.resize(count)
	held.resize(count)
	timer.resize(count)
	start_at.resize(count)
	pace.resize(count)
	_slow.resize(count)
	route_i.resize(count)
	routes.resize(count)
	hidden.resize(count)
	straying.resize(count)
	stray_to.resize(count)
	gate_counted.resize(count)
	penned.resize(count)
	drink_left.resize(count)
	_pressure.resize(count)


func _reset_flags() -> void:
	counted.fill(0)
	out_of_pen.fill(0)
	settled_flags.fill(0)
	held.fill(0)
	route_i.fill(0)
	straying.fill(0)
	gate_counted.fill(0)
	penned.fill(0)
	hidden.fill(0)
	gate_tally = 0
	pen_tally = 0
	pen_home = false
	_arrived_sent = false
	_all_in_sent = false
	tally = 0
	_out_count = 0
	_settled_count = 0
	_released_sent = false
	events.clear()


func _put(i: int, p: Vector2) -> void:
	pos[i] = p
	goal[i] = p
	spot[i] = p
	vel[i] = Vector2.ZERO
	pace[i] = AMBLE_SPEED.x


func _use_meadow(center: Variant, radius: float) -> void:
	_active_center = center if center is Vector2 else meadow_center
	_active_radius = radius if radius > 0.0 else meadow_radius


## Koyunların sırası: noktaya yakın olan önce.
func _order_by_distance(point: Vector2) -> Array[int]:
	var order: Array[int] = []
	for i in count:
		order.append(i)
	var from := pos
	order.sort_custom(func(a: int, b: int) -> bool: return from[a].distance_squared_to(point) < from[b].distance_squared_to(point))
	return order


## Noktalar, verilen noktaya uzaktan yakına sıralı.
static func _sort_far_first(points: PackedVector2Array, from: Vector2) -> PackedVector2Array:
	var list := Array(points)
	list.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.distance_squared_to(from) > b.distance_squared_to(from))
	return PackedVector2Array(list)


# --- E21 (K110): sürülen sürü, göl, sayım kapısı, ağıla dönüş ----------------------------------------------------------

## Sürüyü sürmeye başlar (DRIVEN): yol (başından hedefe), hedefin yarıçapı. Ağıldaki koyun kapıdan çıkar (yolun başına kapı noktaları eklenir).
func drive_along(path: PackedVector2Array, radius: float = 10.0) -> void:
	if path.is_empty():
		return
	gate_open = true
	phase = Phase.DRIVEN
	drive_path = path
	drive_goal = path[path.size() - 1]
	goal_radius = radius
	_arrived_sent = false
	straying.fill(0)
	for i in count:
		held[i] = 0
		mode[i] = Mode.AMBLE
		goal[i] = pos[i]
		pace[i] = herd_walk
		if pos[i].distance_to(pen_center) < pen_radius:
			# Ağıldaki koyun önce kapıdan çıkar (iki sıra).
			var lane := RELEASE_LANE if i % 2 == 0 else -RELEASE_LANE
			var side := Vector2(-gate_dir.y, gate_dir.x)
			routes[i] = PackedVector2Array([pen_center + gate_dir * (pen_radius - 1.4) + side * lane, pen_center + gate_dir * (pen_radius + 2.0) + side * lane])
			route_i[i] = 0
			mode[i] = Mode.WAIT
			start_at[i] = clock + float(i % 20) * 0.35
			out_of_pen[i] = 0


## Sürünün ortası (görünen ve sapmayan koyunların ortalaması; ortadan CORE_M'den uzak geride kalanlar ikinci geçişte sayılmaz: ağılda takılan
## koyun sürünün ortasını geri çekmesin).
func flock_center() -> Vector2:
	var sum := Vector2.ZERO
	var n := 0
	for i in count:
		if hidden[i] == 0 and straying[i] == 0:
			sum += pos[i]
			n += 1
	if n == 0:
		return pen_center
	var mean := sum / float(n)
	var core := Vector2.ZERO
	var m := 0
	for i in count:
		if hidden[i] == 0 and straying[i] == 0 and pos[i].distance_to(mean) < CORE_M:
			core += pos[i]
			m += 1
	return core / float(m) if m >= n / 2 else mean


## Sürünün dağınıklığı (m): ortadan en uzak (sapmayan) koyunun uzaklığı.
func flock_spread() -> float:
	var c := flock_center()
	var worst := 0.0
	for i in count:
		if hidden[i] == 0 and straying[i] == 0:
			worst = maxf(worst, pos[i].distance_to(c))
	return worst


## Birkaç koyun yoldan sapar: side +1 yolun sağı, −1 solu (yürüyüşün yönüne göre), n koyun, dist m öteye. Döner: sapanların dizinleri.
func stray(side: float, n: int = 3, dist: float = 26.0) -> PackedInt32Array:
	var out := PackedInt32Array()
	if phase != Phase.DRIVEN:
		return out
	var c := flock_center()
	var fwd := path_tangent(c)
	var right := Vector2(-fwd.y, fwd.x) * signf(side if side != 0.0 else 1.0)
	# O yandaki en dıştaki koyunlar sapar.
	var order: Array[int] = []
	for i in count:
		if hidden[i] == 0 and straying[i] == 0:
			order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool: return (pos[a] - c).dot(right) > (pos[b] - c).dot(right))
	for k in mini(n, order.size()):
		var i: int = order[k]
		straying[i] = 1
		stray_to[i] = pos[i] + right * dist + fwd * _rng.randf_range(-4.0, 6.0)
		out.append(i)
		events.append({"type": &"strayed", "index": i, "tally": 0})
	return out


## Sapan koyun sayısı.
func stray_count() -> int:
	var n := 0
	for i in count:
		n += straying[i]
	return n


## Sapanların yerleri.
func stray_positions() -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in count:
		if straying[i] == 1:
			out.append(pos[i])
	return out


## Yolun noktadaki ileri yönü (saf değil: drive_path).
func path_tangent(p: Vector2) -> Vector2:
	if drive_path.size() < 2:
		return (drive_goal - p).normalized() if drive_goal.is_finite() else Vector2.RIGHT
	var best := INF
	var dir := Vector2.RIGHT
	for k in drive_path.size() - 1:
		var a := drive_path[k]
		var b := drive_path[k + 1]
		var q := Geometry2D.get_closest_point_to_segment(p, a, b)
		var d := q.distance_squared_to(p)
		if d < best:
			best = d
			dir = (b - a).normalized()
	return dir


## Yolun noktaya en yakın yeri (saf değil; yol yoksa INF).
func closest_on_path(p: Vector2) -> Vector2:
	if drive_path.size() < 2:
		return Vector2.INF
	var best := INF
	var out := Vector2.INF
	for k in drive_path.size() - 1:
		var q := Geometry2D.get_closest_point_to_segment(p, drive_path[k], drive_path[k + 1])
		var d := q.distance_squared_to(p)
		if d < best:
			best = d
			out = q
	return out


## Noktanın yola uzaklığı ve yola doğru yön (saf değil): Vector3(uzaklık, yön x, yön z).
func _path_pull(p: Vector2) -> Vector3:
	var best := INF
	var to := Vector2.ZERO
	for k in drive_path.size() - 1:
		var q := Geometry2D.get_closest_point_to_segment(p, drive_path[k], drive_path[k + 1])
		var d := q.distance_to(p)
		if d < best:
			best = d
			to = (q - p).normalized() if d > 0.001 else Vector2.ZERO
	return Vector3(best, to.x, to.y)


## Sayım kapısı: iki taşın arası; geçen koyun bir kez sayılır (gate_counted olayı).
func count_through(a: Vector2, b: Vector2) -> void:
	gate_a = a
	gate_b = b
	gate_tally = 0
	gate_counted.fill(0)
	var along := (b - a).normalized()
	gate_fwd = Vector2(-along.y, along.x)
	if drive_path.size() >= 2 and path_tangent((a + b) * 0.5).dot(gate_fwd) < 0.0:
		gate_fwd = -gate_fwd


## Sayımın sonu: kapıdan sayılmamış (görünen) koyunlardan kapıya en yakınını sayar (geride kalanı sayıcı sayar). Olayı HerdField verir
## (tikin dışında çağrılır). Döner: dizin ya da −1.
func count_gate_one() -> int:
	if not gate_a.is_finite():
		return -1
	var mid := (gate_a + gate_b) * 0.5
	var best := -1
	var best_d := INF
	for i in count:
		if hidden[i] == 0 and gate_counted[i] == 0:
			var d := pos[i].distance_squared_to(mid)
			if d < best_d:
				best_d = d
				best = i
	if best >= 0:
		gate_counted[best] = 1
		gate_tally += 1
	return best


## Kapıdan sayılmamış görünen koyun sayısı.
func gate_left() -> int:
	var n := 0
	for i in count:
		if hidden[i] == 0 and gate_counted[i] == 0:
			n += 1
	return n


## Sayım kapısının hunisi (saf değil): kapının önündeki sayılmamış koyunun ileri yönü iki taşın arasına (kapının biraz ötesine) döner.
func _gate_funnel(p: Vector2, fwd: Vector2) -> Vector2:
	var mid := (gate_a + gate_b) * 0.5
	var rel := p - mid
	var before := -rel.dot(gate_fwd)
	if before < -0.3 or before > GATE_FUNNEL_M:
		return fwd
	var along := (gate_b - gate_a).normalized()
	var half := gate_a.distance_to(gate_b) * 0.5 * GATE_INNER
	var aim := mid + along * clampf(rel.dot(along), -half, half) + gate_fwd * 2.0
	var to := aim - p
	return to.normalized() if to.length() > 0.05 else fwd


## Yolun sonunu geçti mi (saf değil): son parçanın doğrultusunda yolun son noktasının ötesinde. Yolun sonundaki koyun ileri itilmez (sürü
## hedefte durur, otlar; ağıla dönüşte kapının hunisi yönetir).
func _past_path_end(p: Vector2) -> bool:
	if pen_home or drive_path.size() < 2:
		return false
	var end := drive_path[drive_path.size() - 1]
	var last := (end - drive_path[drive_path.size() - 2]).normalized()
	return (p - end).dot(last) > 0.0


func clear_gate() -> void:
	gate_a = Vector2.INF
	gate_b = Vector2.INF


## Ağıla dönüş: kapıya yaklaşan koyun ağıla girer ve sayılır (penned; hepsi girince all_in). Yol drive_along'unkidir.
func home_to_pen() -> void:
	pen_home = true
	pen_tally = 0
	penned.fill(0)
	_all_in_sent = false


## Göl kıyısı (WATER): koyunlar su çizgisinin en yakın noktasına koşar (speed), içer (drink_s), sonra otlağa (graze) yayılıp otlar.
func water(line: PackedVector2Array, graze: Vector2, graze_radius: float, speed: float = 2.4, drink_s: float = 6.0) -> void:
	phase = Phase.WATER
	water_line = line
	water_graze = graze
	water_graze_radius = graze_radius
	_active_center = graze
	_active_radius = graze_radius
	straying.fill(0)
	var points := scatter_points(graze, graze_radius, count, _rng, 1.5)
	for i in count:
		if hidden[i] == 1:
			continue
		var drink := _nearest_on(water_line, pos[i]) + Vector2(_rng.randf_range(-1.6, 1.6), _rng.randf_range(-1.6, 1.6))
		routes[i] = PackedVector2Array([drink])
		route_i[i] = 0
		spot[i] = points[i]
		mode[i] = Mode.ROUTE
		pace[i] = speed * _rng.randf_range(0.9, 1.08)
		drink_left[i] = drink_s * _rng.randf_range(0.7, 1.3)
		grazing[i] = 0


## Koyunu benzetimden çıkarır (balçıktaki kuzu): görünmez, itişmez.
func take_out(i: int) -> void:
	if i < 0 or i >= count:
		return
	hidden[i] = 1
	straying[i] = 0
	pos[i] = Vector2(1.0e5, 1.0e5) + Vector2(float(i), 0.0)
	prev[i] = pos[i]
	vel[i] = Vector2.ZERO


## Koyunu geri koyar (kucaktan iner): yerinde, sürünün evresinde.
func put_back(i: int, at: Vector2) -> void:
	if i < 0 or i >= count:
		return
	hidden[i] = 0
	_put(i, at)
	prev[i] = at
	_rest(i)


## Görünen koyun sayısı.
func visible_count() -> int:
	var n := 0
	for i in count:
		n += 1 - hidden[i]
	return n


## En küçük (kuzu) görünen koyun: balçığa saplanacak olan.
func smallest() -> int:
	var best := -1
	for i in count:
		if hidden[i] == 0 and (best < 0 or body_scale[i] < body_scale[best]):
			best = i
	return best


func _nearest_on(line: PackedVector2Array, p: Vector2) -> Vector2:
	if line.is_empty():
		return p
	if line.size() == 1:
		return line[0]
	var best := line[0]
	var best_d := INF
	for k in line.size() - 1:
		var q := Geometry2D.get_closest_point_to_segment(p, line[k], line[k + 1])
		var d := q.distance_squared_to(p)
		if d < best_d:
			best_d = d
			best = q
	return best


## Sürünün tiki öncesi: ortanın ve baskının ön hesabı; sürünün bütününün baskısı hızla artar, yavaşça söner (sürücü bir an uzaklaşınca
## sürü hemen durmaz).
func _drive_prepare() -> void:
	_center = flock_center()
	var most := 0.0
	for i in count:
		var p := pos[i]
		var push := 0.0
		for d in drivers:
			var dist := p.distance_to(Vector2(d.x, d.y))
			if dist < d.z:
				push = maxf(push, 1.0 - dist / d.z)
		_pressure[i] = push
		if hidden[i] == 0 and straying[i] == 0 and penned[i] == 0:
			most = maxf(most, push)
	var want := clampf(most * 3.0, 0.0, 1.0)
	_flock_push = move_toward(_flock_push, want, 0.5 if want > _flock_push else 0.06)


## Sürülen koyunun adımı: kaçış, yolun ileri yönü, toplanma, koridor, öndeki; sapan kendi yerine gider, sürücü önüne geçince döner.
func _drive_sheep(i: int) -> void:
	var p := pos[i]
	if mode[i] == Mode.WAIT:
		if clock >= start_at[i]:
			mode[i] = Mode.ROUTE
		else:
			vel[i] = Vector2.ZERO
			return
	if mode[i] == Mode.ROUTE:
		var desired_r := _follow_route(i, p)
		if route_i[i] >= routes[i].size():
			mode[i] = Mode.AMBLE
			out_of_pen[i] = 1
		_finish_drive_step(i, p, desired_r)
		return
	var c := _center
	var v := Vector2.ZERO
	var pressure := _pressure[i]
	var fwd := path_tangent(p)
	if pen_home:
		# Ağılın önünde yol kapıya döner (koyun ağılın yolunu bilir): kapının dışına doğru, çite değil.
		var outer := pen_center + gate_dir * (pen_radius + 2.2)
		var to_gate := outer - p
		if to_gate.length() < 22.0 and to_gate.length() > 0.3:
			fwd = to_gate.normalized()
			if pressure <= 0.0 and _flock_push < 0.2:
				v += fwd * herd_walk * 0.8
	if gate_a.is_finite() and gate_counted[i] == 0 and straying[i] == 0:
		fwd = _gate_funnel(p, fwd)
	var past_end := straying[i] == 0 and _past_path_end(p)
	if penned[i] == 1:
		# Ağıla giren koyun içeride kendi hâlindedir.
		if mode[i] == Mode.AMBLE and pos[i].distance_to(goal[i]) > 0.3:
			v = (goal[i] - p).normalized() * pace[i]
		_finish_drive_step(i, p, v)
		return
	# Sürücüden kaçış (yarıçapın içinde; yakınken güçlü): sapmayan koyun yolun ileri yönüne doğru kaçar (sürü dağılmaz, ileri gider),
	# sapan koyun düpedüz uzağa.
	for d in drivers:
		var off := p - Vector2(d.x, d.y)
		var dist := off.length()
		if dist < d.z and dist > 0.001:
			var away := off / dist
			var dir := away if straying[i] == 1 or past_end else (away + fwd * FLEE_FORWARD).normalized()
			v += dir * flee_speed * sqrt(1.0 - dist / d.z)
	if straying[i] == 1:
		# Sapan: sürücü önüne geçmediyse yerine yürür; geçtiyse (baskı) sürüye kaçar.
		if pressure > 0.05:
			v += (c - p).normalized() * flee_speed * 0.9
		else:
			var to := stray_to[i] - p
			v += to.normalized() * herd_walk * 1.15 if to.length() > 1.0 else Vector2.ZERO
		if p.distance_to(c) < cohesion_radius * 1.3 and pressure > 0.0:
			straying[i] = 0
			events.append({"type": &"stray_back", "index": i, "tally": 0})
	else:
		# Baskı yolun ileri yönüne kayar (koyun sürücüden ileri, yolu izleyerek kaçar); arkadan sıkıştırılan sürü bütün olarak yürür.
		var forward_push := _flock_push
		for d in drivers:
			var dd := p.distance_to(Vector2(d.x, d.y))
			if dd < d.z * 1.6:
				forward_push = maxf(forward_push, 1.0 - dd / (d.z * 1.6))
		if past_end:
			forward_push = 0.0
		elif pen_home:
			# Eve dönüşte koyun ağılın yolunu bilir: sürülmese de yürür (sürücü hızlandırır).
			forward_push = maxf(forward_push, HOME_WALK)
		v += fwd * flock_speed * forward_push
		var to_c := c - p
		var dc := to_c.length()
		if dc > cohesion_radius:
			v += to_c / dc * minf((dc - cohesion_radius) / cohesion_radius, 1.0) * herd_walk
		var pull := _path_pull(p)
		if pull.x > corridor:
			v += Vector2(pull.y, pull.z) * minf((pull.x - corridor) / corridor, 1.0) * herd_walk
		if leader.is_finite():
			var to_l := leader - p
			var dl := to_l.length()
			if dl < 26.0 and dl > 2.5 and to_l.dot(fwd) > 0.0:
				v += to_l / dl * 0.35 * (1.0 - dl / 26.0) * (0.4 + forward_push)
		if pressure <= 0.0 and forward_push <= 0.0 and v.length() < 0.25:
			# Sıkıştırılmayan koyun durur, otlar.
			v = Vector2.ZERO
	var speed := v.length()
	if speed > drive_max:
		v = v / speed * drive_max
	grazing[i] = 1 if speed < 0.2 else 0
	_finish_drive_step(i, p, v)


func _finish_drive_step(i: int, p: Vector2, desired: Vector2) -> void:
	var v := desired * _slow[i] if mode[i] == Mode.ROUTE else desired
	var push := (_push[i] * PUSH_GAIN).limit_length(PUSH_MAX)
	if desired.length_squared() > TURN_SPEED * TURN_SPEED:
		facing[i] = desired.normalized()
	elif push.length_squared() > PUSH_TURN * PUSH_TURN:
		facing[i] = push.normalized()
	v += push
	vel[i] = v
	var next := _resolve(p, p + v * TICK)
	pos[i] = next
	_check_gate(i, p, next)
	_check_pen(i)


## Kapıdan geçiş: iki taşın doğrusunu taşların arasından kesen koyun bir kez sayılır.
func _check_gate(i: int, from: Vector2, to: Vector2) -> void:
	if not gate_a.is_finite() or gate_counted[i] == 1:
		return
	var hit: Variant = Geometry2D.segment_intersects_segment(from, to, gate_a, gate_b)
	if hit != null:
		gate_counted[i] = 1
		gate_tally += 1
		events.append({"type": &"gate_counted", "index": i, "tally": gate_tally})


## Ağıla dönüş: kapının dışına yaklaşan koyun içeri yürür (iki sıra), girerken sayılır.
func _check_pen(i: int) -> void:
	if not pen_home or penned[i] == 1 or mode[i] == Mode.ROUTE:
		return
	var outer := pen_center + gate_dir * (pen_radius + 2.2)
	if pos[i].distance_to(outer) > 4.5:
		return
	penned[i] = 1
	pen_tally += 1
	var inside := pen_center + Vector2.from_angle(_rng.randf() * TAU) * sqrt(_rng.randf()) * (pen_radius - 1.8)
	spot[i] = inside
	routes[i] = PackedVector2Array([outer, pen_center + gate_dir * (pen_radius - 1.2), inside])
	route_i[i] = 0
	mode[i] = Mode.ROUTE
	pace[i] = herd_walk * 1.2
	events.append({"type": &"penned", "index": i, "tally": pen_tally})


## Göl kıyısındaki koyun: suya koşar, içer, sonra otlağına yürür.
func _water_sheep(i: int) -> void:
	var p := pos[i]
	var path := routes[i]
	if route_i[i] < path.size():
		var desired := _follow_route(i, p)
		var v := desired * _slow[i] + (_push[i] * PUSH_GAIN).limit_length(PUSH_MAX)
		if desired.length_squared() > TURN_SPEED * TURN_SPEED:
			facing[i] = desired.normalized()
		vel[i] = v
		pos[i] = _resolve(p, p + v * TICK)
		return
	# Suyun başında: içer (baş aşağı), sonra otlağa.
	drink_left[i] -= TICK
	vel[i] = Vector2.ZERO
	grazing[i] = 1
	if drink_left[i] <= 0.0:
		goal[i] = spot[i]
		mode[i] = Mode.AMBLE
		pace[i] = _rng.randf_range(AMBLE_SPEED.x, AMBLE_SPEED.y)


## Ağıla dönüş bitti: sürü ağılda kendi hâlinde (PEN), kapı kapanır.
func settle_in_pen() -> void:
	phase = Phase.PEN
	gate_open = false
	pen_home = false
	_active_center = pen_center
	_active_radius = pen_radius - 0.9
	for i in count:
		if hidden[i] == 0:
			spot[i] = clamp_to_disc(pos[i], pen_center, pen_radius - 1.2)
			if mode[i] != Mode.ROUTE:
				_rest(i)


## Sürünün arkası (saf değil): yolun ileri yönüne göre en gerideki (sapmayan) koyunun izdüşümü; sürücünün durduğu yer bunun gerisidir.
func flock_rear(fwd: Vector2) -> Vector2:
	var c := flock_center()
	var least := 0.0
	for i in count:
		if hidden[i] == 0 and straying[i] == 0:
			least = minf(least, (pos[i] - c).dot(fwd))
	return c + fwd * least


## En gerideki (sapmayan) koyunun yeri (saf değil): yolun ileri yönüne göre izdüşümü en küçük olan (sürünün gövdesinden; geride takılan sayılmaz).
func rear_sheep(fwd: Vector2) -> Vector2:
	var c := flock_center()
	var least := INF
	var best := c
	for i in count:
		if hidden[i] == 0 and straying[i] == 0 and pos[i].distance_to(c) < CORE_M:
			var k := (pos[i] - c).dot(fwd)
			if k < least:
				least = k
				best = pos[i]
	return best


## Çitin içindeki (görünen) koyun sayısı.
func _inside_pen() -> int:
	var n := 0
	for i in count:
		if hidden[i] == 0 and pos[i].distance_to(pen_center) < pen_radius - 0.6:
			n += 1
	return n
