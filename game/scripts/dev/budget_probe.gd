extends Node
## Bütçe ölçüm sahnesi (godot.md §7.4, K63; Yol Haritası budget-probe): kampı sabit pozlarda ölçer ve sonucu JSON
## olarak yazar; tools/check_budget.py sonucu data/budgets.json'daki sınırlarla karşılaştırır.
##
## Pozlar: 5 nokta (ateş, ahır, yurtların arası, göle bakan yamaç, oyun alanının kenarı) × 4 yön (0°, 90°, 180°,
## 270°; takip kamerasının açısı: 0'da kamera noktanın güneyindedir, kuzeye, -Z'ye bakar) × 3 uzaklık (14, 28, 40 m; K98);
## her biri varsayılan eğimde (FollowCamera.pitch_for_distance) ve eğim bandının iki ucunda (15°, 60°; godot.md §5.1):
## 180 poz. Önce menü karesi ölçülür (menü kamerası ve arayüzüyle); sonra menünün «Serbest Gez» isteğiyle kampa
## inilir (varsayılan karakter ateşin önündedir) ve pozlar takip kamerasının kadrajıyla kurulur: odak noktanın
## 0,7 m üstü, dikey görüş FollowCamera.DEFAULT_FOV (K98: 36°), zemine gömülmeden. Çimenin payı ayrı yazılır: menü karesi ve varsayılan
## uzaklıktaki (28 m) varsayılan eğimli 20 poz çimen tutamları gizlenerek, eşinin hemen ardından yinelenir; fark (çimenli − çimensiz) çimenin payıdır.
## Her pozda görünür ve gölge geçişi ayrı okunur (Viewport.get_render_info: çizim, üçgen, nesne); kare süresi tik
## farkıdır; GPU ve CPU çizim süresi RenderingServer'dandır (Metal sürücüsü GPU zamanını bildirmez, 0 yazar: rapordaki
## gpu_timing); süreç adımı (GDScript bütçesinin ölçüsü) karenin process_frame anından en son işlenen bu düğümün
## _process'ine dek geçen süredir (Performance.TIME_PROCESS çizimi de içerir, kullanılmaz); video ve tampon belleği
## Performance'tandır. Doku belleği sahnedeki 3B malzeme dokularının ekran kartındaki boyudur (biçim ve mip düzeyiyle;
## texture_mem_probe.gd'nin hesabı): motorun RENDER_TEXTURE_MEM_USED sayacı Godot 4.7.2 Metal'de güvenilmez (pencere
## boyuna göre eksiye düşüp sarıyor); yalnız bilgi için texture_counter_mib olarak yazılır, geçersizse boştur.
## Dikey eşitleme kapalı, boyalı görünüm açık; 240 kare ısınma, her pozda 30 kare oturma ve 180 kare ölçüm;
## ortalama, %95'lik dilim ve en büyük değer yazılır.
##
## Çalıştırma (pencere açar, normal bir terminalden; birkaç dakika sürer):
##   tools/capture.sh $TMPDIR/budget.png 1 --scene=res://scenes/dev/budget_probe.tscn --window=1920x1080 --probe=camp --timeout=1800
##   python3 tools/check_budget.py $TMPDIR/budget.json
## Sonuç görüntünün yanına aynı adla .json olarak yazılır; görüntü ölçümden sonraki varsayılan kadrajdır (ateş, 27 m).
## Doğum takımı (--probe=birth): Önsöz dizisi doğumun başına ileri sarılır, sinema akarken çekim başına ölçülür (7a yurdun içi, 7b
## şafak, 7d sayım hattı, 7e beşik; kişiler ve Meshy eşyaları yerinde). Kamp dünyası bırakılmıştır ama bellektedir: iki dünya birlikte
## sayılır. childhood_ordos bir iç haritadır, sınır «interior» satırıdır. Isınma ve oturma yoktur: oyuncunun gördüğü ilk geçiştir.
## Mit takımı (--probe=myth; K93): aynı yol mit sinemasının başından: panel başına çekimin 3. saniyesi, satır yine «interior». Video
## çözmenin kare maliyeti buradan görülür: her satırın video alanı mit videosunun oynayıp oynamadığını yazar (dosya yoksa keçe
## yedeği ölçülür). Pano 6'da childhood_ordos altta önceden çizilir: o satır video + 3B'dir.
## Çocukluk takımı (--probe=childhood; satır «interior»): childhood_ordos'un oynanış kadrajları (K98: eğim 38°, görüş 36°). Kamp bırakılır (Önsöz'deki gibi bellekte kalır),
## dünya kurulur, set_childhood_mode(true) ile ağıl, sürü, av ve gün ışığı gelir; kadraj 8 noktada (yurt, ağıl, yarış yolu, taş, çayır, sayım hattı, hepsini tutan 40 m kadrajın
## odağı ve sayımda çocukların yeri), 4 yönde, 22 ve 40 m; 14 m (yön 0). Kişiler: üç çocuk (Çocuk modeli, noktada yürür), Lan Hatun kapıda, sayıcı yerinde; sayımın en ağır anı
## baştan kurulur: saat 11:00 (Dailin'in kart kademesindeki kalabalığı toplanmış), Teoman ve üç bey ata binmiş hâlde Mete'nin hattaki yerinin önünde (sahnenin verisi ve kodu).
## Sürü noktaya göre: yurtta ve ağılda ağılda, yarış yolunda ağıldan çıkıyor, taşta ve çayırda otluyor, hatta sayılıyor. Bakmak için kareler scenes/dev/childhood_lineup.tscn'dedir.
## Yola Çıkış takımı (--probe=depart; satır «interior»): depart_yurt'un oynanış kadrajları (K98: eğim 38°, görüş 36°). Kamp bırakılır (bellekte kalır), dünya
## kurulur; kişiler sahnedeki gibi (Yançi, Eskam, Huyan Hatun ve kucağında Gutu, Lan Hatun; CineActor) ve oluşturulan Mete (varsayılan profil) noktada, yayı
## beşikte asılı; kadraj 6 noktada (yurdun içi: çatı kalkık; avlu; Eskam'ın yanı; Teoman'ın kapısı; at; hepsini tutan 40 m kadrajın odağı), 4 yönde, 28 ve
## 40 m; 14 m (yön 0). Yağan kar odağı izler.
## Kışlak takımı (--probe=kislak; satır «interior»; act-1-p2): KISLAK_POINTS'in yerleşim noktaları (Ulu Ocak, Amaga'nın Yurdu, Rehine Yurdu,
## Ambar, Ahır, Yar Bakışı, Ambar doğusunun nöbet ateşi) ve bölgelerin ortaları (Ak Otlak, Kara Yamaç, Demir Diş ve ötekiler), 4 yönde,
## 28 ve 40 m; 14 m (yön 0). Kamp bırakılır (bellekte kalır), kislak.tscn kurulur, Mete noktada.
## Argümanlar: --probe=camp, birth, myth, childhood, depart ya da kislak, --probe-out=yol (JSON başka yere), --probe-warmup=240,
## --probe-frames=180, --probe-settle=30, --probe-only=parça (yalnız kimliğinde bu parça geçen pozlar, ör. "/27m/";
## kısa deneme içindir, taban ölçümü bütün pozlarla alınır). tools/capture.sh olmadan da koşar (--probe-out ile):
## ölçüm bitince oyun kendini kapatır. Koşu oyuncunun kaydına ve ayarına yazmaz ("--" sonrası argüman vardır).

const CaptureTool := preload("res://scripts/dev/capture.gd")
const TextureMemProbe := preload("res://scripts/dev/texture_mem_probe.gd")
const MAIN_SCENE := preload("res://scenes/main.tscn")

const VERSION := 1
const MIB := 1048576.0
## Ölçüm takımı → data/budgets.json'daki satır.
const PROBES := {"camp": "camp", "birth": "interior", "myth": "interior", "childhood": "interior", "depart": "interior", "kislak": "interior",
	"prologue": "camp"}
## Önsöz'ün günleri (--probe=prologue; E21, K110; satır «camp»: kamp dünyasıdır): Yeni Oyun'un Önsöz aşaması açılır (PrologueDays, «Süt»ün
## sabahı: Kayın Obası, yol, dere, kazıklar, açık aile yurdu, kişiler), sonra aynı noktalarda tipi gecesi (görüş ≈25 m, kar yağışı, köz kabının
## ışığı, Börü). Noktalar × 4 yön × 22 (çocuk), 28 ve 40 m; ayrıca 14 m (yön 0); eğim K98'in 38°'si.
const PROLOGUE_DAY_POINTS: Array[String] = ["gol_family_yurt", "road_descent", "road_forest", "ford", "birch_center", "saba"]
const PROLOGUE_NIGHT_POINTS: Array[String] = ["road_open", "stake_9", "ford", "birch_center", "kunay_yurt"]
const PROLOGUE_DISTANCES: Array[float] = [22.0, 28.0, 40.0]
## Kışlak takımı (--probe=kislak; act-1-p2, satır «interior»): yerleşimin ağır noktaları ve bölgelerin ortaları (map.json yapı kayıtları ve
## dev_<bölge> belirme noktaları) × 4 yön × 28 ve 40 m; ayrıca 14 m (yön 0). Kamp bırakılır (bellekte kalır), dünya kurulur, oluşturulan
## Mete (varsayılan profil) noktadadır; ışık haritanın öğle örneğidir.
const KISLAK_SCENE := "res://scenes/maps/kislak.tscn"
const KISLAK_POINTS: Array[String] = ["great_hearth", "great_tent", "hostage_yurt", "stores", "stable", "lookout_bluff", "wf4",
	"dev_hollow", "dev_offering_pen", "dev_pale_pasture", "dev_black_slope", "dev_ice_branch", "dev_reed_hamlet", "dev_old_kurgans",
	"dev_iron_tooth", "dev_upper_folds", "dev_black_hills", "dev_mirror_lake", "dev_north_flat", "dev_bone_throat"]
const KISLAK_DISTANCES: Array[float] = [28.0, 40.0]
## Doğum takımının dizisi ve ölçüm anları: çekim → çekimin başından saniye (180 kare çekimin içinde kalsın diye başa yakın).
const BIRTH_SEQUENCE := "res://data/cine/prologue.json"
const BIRTH_SHOTS := {"7a": 3.0, "7b": 4.0, "7d": 3.0, "7e": 2.0}
## Mit takımının panoları (panel_1 … panel_6) ve ölçüm anı: panonun başından saniye (dizi yine BIRTH_SEQUENCE).
const MYTH_PANELS := 6
const MYTH_PANEL_AT := 3.0
## Çocukluk takımı: dünya, noktalar (düzenin işaretlerinden; yer → [işaret, sürünün durumu]) ve kişiler.
const CHILDHOOD_SCENE := "res://scenes/maps/childhood_ordos.tscn"
const CHILDHOOD_POINTS := {
	"yurt": ["child_start", "pen"], "pen": ["pen_inside", "pen"], "track": ["race_start", "leaving"],
	"stone": ["race_stone", "meadow"], "meadow": ["meadow", "meadow"], "line": ["line_start", "line"],
	"frame": ["frame_center", "meadow"], "count": ["children_at_line", "line"],
	# E21 (K110): Kamışlı Göl (kıyı, sazlık ve balçık, sayım taşları), göle giden yol (sürü yolda), Ebe Obası.
	"lake": ["lake_beach", "water"], "reeds": ["lake_mud", "water"], "gate_stones": ["count_gate", "water"],
	"way": ["flock_way_2", "way"], "ebe": ["hereka_door", "pen"],
}
## Yola Çıkış takımı: dünya ve noktalar (DepartWorld.marker kimlikleri; sırayla), uzaklıklar (yetişkinin takip kamerası 28 m) ve kişiler.
const DEPART_SCENE := "res://scenes/maps/depart_yurt.tscn"
const DEPART_POINTS: Array[String] = ["inside", "courtyard", "eskam_talk", "door_focus", "mount_approach", "frame_center"]
const DEPART_DISTANCES: Array[float] = [28.0, 40.0]
## Oyun içi kadraj (K98): eğim, görüş ve uzaklıklar (metre).
const CHILDHOOD_PITCH := 38.0
const CHILDHOOD_FOV := 36.0
const CHILDHOOD_DISTANCES: Array[float] = [22.0, 40.0]
const CHILDHOOD_NEAREST := 14.0
const CHILDHOOD_KIDS := 3
const CHILD_MODEL := "child"
const CHILD_WALK := 1.6
## Çocukların noktaya göre yeri (metre).
const KID_OFFSETS: Array[Vector2] = [Vector2(0.0, 0.0), Vector2(1.6, 0.9), Vector2(-1.4, 1.2)]
const WARMUP_FRAMES := 240
const MEASURE_FRAMES := 180
const SETTLE_FRAMES := 30
## Serbest Gez'e inince (takip kamerasının 1,6 sn'lik geçişi, oyuncunun modeli) ölçümden önce beklenen kare.
const PLAY_WARMUP_FRAMES := 120
## Serbest Gez'in açılması için en çok beklenen kare.
const PLAY_TIMEOUT_FRAMES := 900
const POINT_ORDER: Array[String] = ["fire", "stable", "yurts", "lake_slope", "edge"]
const YAWS: Array[float] = [0.0, 90.0, 180.0, 270.0]
## K98: takip kamerasının en yakını, varsayılanı ve en uzağı (FollowCamera).
const DISTANCES: Array[float] = [14.0, 28.0, 40.0]
## Eğim kipleri: varsayılan (uzaklığa bağlı, FollowCamera) ve bandın iki ucu (godot.md §5.1, K39).
const PITCH_MODES: Array[String] = ["default", "low", "high"]
const PITCH_BAND := Vector2(15.0, 60.0)
## FollowCamera'nın dışa açık varsayılanları (follow_camera.gd; test_budget_probe.gd eşitliklerini sınar).
const MIN_DISTANCE := 14.0
const MAX_DISTANCE := 40.0
const ZOOM_TILT := 6.0
const LOOK_HEIGHT := 0.7
const GROUND_CLEARANCE := 1.2
## Göle bakan yamaç: JourneyFlags'in yamaç diliminin ortasında, eşik uzaklığının bu kadar ötesinde (m).
const LAKE_MARGIN := 4.0
## Oyun alanının kenarı: kamp merkezinden bu yönde (kuzeyden saat yönünde derece; 180 = güney, gölün karşısı;
## kamera kuzeye dönünce bütün kamp, çayır ve vadi kadrajdadır) ve kenarın bu kadar içinde (m).
const EDGE_BEARING := 180.0
const EDGE_MARGIN := 2.0
## Çimenin payı için çimenli ve çimensiz pozların karşılaştırılan ölçüleri (alan → istatistik).
const SHARE_FIELDS := {
	"frame_ms": "mean", "gpu_ms": "mean", "cpu_ms": "mean", "draw_calls_visible": "max", "draw_calls_shadow": "max",
	"triangles_visible": "max", "triangles_shadow": "max",
}
## Bu düğüm sahnede en son işlenir: süreç adımının sonu (_process) buradan okunur.
const PROCESS_LAST := 2147483647
## Bellek sayacının geçerli üst sınırı (bayt): eksiye düşen işaretsiz sayaç ≈1,8e19 okunur.
const COUNTER_LIMIT := 1.0e15
## Viewport.Scaling3DMode adları (rapor için).
const SCALING_NAMES := {0: "bilinear", 1: "fsr", 2: "fsr2", 3: "metalfx_spatial", 4: "metalfx_temporal", 5: "nearest"}

var _args := {}
var _main: Node
## Görüntüyü bekleten yakalama aracı (tools/capture.sh ile koşarken); yoksa ölçüm bitince oyun kapanır.
var _capture: Node
var _results: Array[Dictionary] = []
## Süreç adımı: karenin process_frame anı (µs) ve son ölçülen süre (ms; bütün düğümlerin _process işi, GDScript dahil).
var _process_start := 0
var _process_ms := 0.0
## Makinenin yükü ölçümün başında (uptime): aynı anda koşan başka işler kare süresini bozar.
var _load_before := ""
## 3B malzeme dokularının tahmini (menüde ve Serbest Gez'de ayrı; bkz. _estimate_textures).
var _textures := {}
var _textures_by_phase := {}


# --- Saf hesaplar (tests/unit/test_budget_probe.gd) ------------------------------------------------

## Kamptaki ölçüm noktaları (dünya x, z): ateş, ahır, iki yurdun ortası, göle bakan yamaç (JourneyFlags'in yamaç
## diliminin ortası) ve oyun alanının kenarı.
static func camp_points(fire: Vector2, stable: Vector2, yurt_a: Vector2, yurt_b: Vector2, play_center: Vector2, play_radius: float) -> Dictionary:
	var lake_bearing := deg_to_rad((JourneyFlags.LAKE_VIEW_SECTOR.x + JourneyFlags.LAKE_VIEW_SECTOR.y) * 0.5)
	var lake := fire + bearing_vector(lake_bearing) * (JourneyFlags.LAKE_VIEW_DISTANCE + LAKE_MARGIN)
	var edge := play_center + bearing_vector(deg_to_rad(EDGE_BEARING)) * (play_radius - EDGE_MARGIN)
	return {"fire": fire, "stable": stable, "yurts": (yurt_a + yurt_b) * 0.5, "lake_slope": lake, "edge": edge}


## Kuzeyden (-Z) saat yönünde ölçülen yönün birim vektörü (dünya x, z; JourneyFlags.bearing_deg'in tersi).
static func bearing_vector(radians: float) -> Vector2:
	return Vector2(sin(radians), -cos(radians))


## Eğim kipinin açısı (derece): "default" uzaklığa bağlıdır (FollowCamera), "low" ve "high" bandın uçlarıdır.
static func pitch_for(mode: String, distance: float) -> float:
	match mode:
		"low":
			return PITCH_BAND.x
		"high":
			return PITCH_BAND.y
	return FollowCamera.pitch_for_distance(distance, FollowCamera.DEFAULT_PITCH_DEG, FollowCamera.DEFAULT_DISTANCE,
		MIN_DISTANCE, MAX_DISTANCE, ZOOM_TILT)


## Bir poz: kimlik "nokta/uzaklık/yön/eğim[/nograss]".
static func make_pose(point_id: String, xz: Vector2, yaw: float, distance: float, mode: String, grass: bool) -> Dictionary:
	var id := "%s/%dm/yaw%d/%s" % [point_id, int(distance), int(yaw), mode]
	if not grass:
		id += "/nograss"
	return {
		"id": id, "point": point_id, "x": xz.x, "z": xz.y, "yaw": yaw, "distance": distance,
		"pitch": snappedf(pitch_for(mode, distance), 0.01), "pitch_mode": mode, "grass": grass,
	}


## Ölçülecek pozlar (saf): her eğim kipinde nokta × uzaklık × yön (180); 27 m'deki varsayılan eğimli 20 pozun
## çimensiz eşi, çimenin payı için, çimenli pozun hemen ardından gelir: uzun koşuda makinenin yükü ve ısısı kayar,
## eşler arasındaki süre kısa kalmalı. Menü karesi ayrıdır (kamerası menünündür).
static func build_poses(points: Dictionary) -> Array[Dictionary]:
	var poses: Array[Dictionary] = []
	for mode in PITCH_MODES:
		for point_id in POINT_ORDER:
			for distance in DISTANCES:
				for yaw in YAWS:
					poses.append(make_pose(point_id, points[point_id], yaw, distance, mode, true))
					if mode == "default" and distance == FollowCamera.DEFAULT_DISTANCE:
						poses.append(make_pose(point_id, points[point_id], yaw, distance, mode, false))
	return poses


## Pozun kamera dönüşümü (saf): odak noktanın LOOK_HEIGHT üstüdür (takip kamerası gibi), kamera
## FollowCamera.compute_transform ile kurulur ve zemine gömülmez (lift_above_ground). shape boşsa zemin 0'dır.
static func camera_transform(shape: TerrainShape, pose: Dictionary) -> Transform3D:
	var x := float(pose["x"])
	var z := float(pose["z"])
	var focus := Vector3(x, (shape.height_at(x, z) if shape else 0.0) + LOOK_HEIGHT, z)
	var xform := FollowCamera.compute_transform(focus, deg_to_rad(float(pose["yaw"])), float(pose["pitch"]), float(pose["distance"]))
	var ground := shape.height_at(xform.origin.x, xform.origin.z) if shape else 0.0
	return FollowCamera.lift_above_ground(xform, focus, ground, GROUND_CLEARANCE)


## Değerlerin p'lik dilimi (saf; en yakın sıra yöntemi: p = 0.95 → sıralı dizinin %95'indeki değer).
static func percentile(values: PackedFloat64Array, p: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	var rank := clampi(ceili(p * sorted.size()) - 1, 0, sorted.size() - 1)
	return sorted[rank]


## Ortalama, %95'lik dilim ve en büyük değer (saf); step yuvarlama adımıdır.
static func summarize(values: PackedFloat64Array, step: float = 0.001) -> Dictionary:
	if values.is_empty():
		return {"mean": 0.0, "p95": 0.0, "max": 0.0}
	var total := 0.0
	var top := -INF
	for v in values:
		total += v
		top = maxf(top, v)
	return {
		"mean": snappedf(total / values.size(), step),
		"p95": snappedf(percentile(values, 0.95), step),
		"max": snappedf(top, step),
	}


## Çimenin payı (saf): her çimensiz pozun çimenli eşine göre farkı (çimenli − çimensiz); farkların ortalaması
## ve en büyüğü. Eşi olmayan çimensiz poz sayılmaz.
static func grass_share(poses: Array) -> Dictionary:
	var by_id := {}
	for pose: Dictionary in poses:
		by_id[str(pose["id"])] = pose
	var deltas := {}
	for field in SHARE_FIELDS:
		deltas[field] = []
	var pairs := PackedStringArray()
	for pose: Dictionary in poses:
		if bool(pose.get("grass", true)):
			continue
		var twin_id := str(pose["id"]).trim_suffix("/nograss")
		if not by_id.has(twin_id):
			continue
		var twin: Dictionary = by_id[twin_id]
		pairs.append(twin_id)
		for field: String in SHARE_FIELDS:
			var stat: String = SHARE_FIELDS[field]
			if twin.has(field) and pose.has(field):
				(deltas[field] as Array).append(float(twin[field][stat]) - float(pose[field][stat]))
	var out := {"pairs": pairs.size(), "poses": pairs}
	for field: String in SHARE_FIELDS:
		var stats := summarize(PackedFloat64Array(deltas[field]), 0.001)
		out[field] = {"stat": SHARE_FIELDS[field], "mean": stats["mean"], "max": stats["max"]}
	return out


## JSON'un yolu (saf): --probe-out verilmişse o, yoksa ekran görüntüsünün yanı (aynı ad, .json); ikisi de yoksa "".
static func output_path(args: Dictionary) -> String:
	var out := str(args.get("probe-out", ""))
	if out != "" and out != "true":
		return out
	var shot := str(args.get("capture", ""))
	if shot != "" and shot != "true":
		return shot.get_basename() + ".json"
	return ""


## Doğum takımının pozları (saf): çekim sırasıyla kimlik ve dizinin saatine göre ölçüm anı. Dizide bulunmayan çekim atlanır.
static func birth_poses(timeline: CineTimeline) -> Array[Dictionary]:
	var poses: Array[Dictionary] = []
	for shot: String in BIRTH_SHOTS:
		var start := timeline.time_of("birth:%s" % shot)
		if not is_nan(start):
			poses.append({"id": "birth/%s" % shot, "point": "birth", "grass": true, "pitch_mode": "cine",
				"at": snappedf(start + float(BIRTH_SHOTS[shot]), 0.01)})
	return poses


## Mit takımının pozları (saf): panel sırasıyla kimlik ve dizinin saatine göre ölçüm anı (çekimin 3. saniyesi). Dizide bulunmayan pano
## atlanır.
static func myth_poses(timeline: CineTimeline) -> Array[Dictionary]:
	var poses: Array[Dictionary] = []
	for i in MYTH_PANELS:
		var shot := "panel_%d" % (i + 1)
		var start := timeline.time_of("myth:%s" % shot)
		if not is_nan(start):
			poses.append({"id": "myth/%s" % shot, "point": "myth", "grass": true, "pitch_mode": "cine",
				"at": snappedf(start + MYTH_PANEL_AT, 0.01)})
	return poses


## Çocukluk takımının noktaları (saf): düzenin "childhood.markers" işaretlerinden (x, z); bulunmayan işaret atlanır.
static func childhood_points(layout: Dictionary) -> Dictionary:
	var markers: Dictionary = (layout.get("childhood", {}) as Dictionary).get("markers", {})
	var out := {}
	for id: String in CHILDHOOD_POINTS:
		var marker_id: String = CHILDHOOD_POINTS[id][0]
		if markers.has(marker_id):
			var at: Array = markers[marker_id]
			out[id] = Vector2(float(at[0]), float(at[1]))
	return out


## Çocukluk takımının pozları (saf; K98): her noktada 4 yön × 22 ve 40 m, 14 m (yön 0); eğim 38°, pozda sürünün durumu.
static func childhood_poses(points: Dictionary) -> Array[Dictionary]:
	var poses: Array[Dictionary] = []
	for id: String in CHILDHOOD_POINTS:
		if not points.has(id):
			continue
		var xz: Vector2 = points[id]
		var herd: String = CHILDHOOD_POINTS[id][1]
		var row: Array[Dictionary] = []
		for distance: float in CHILDHOOD_DISTANCES:
			for yaw: float in YAWS:
				row.append(make_pose(id, xz, yaw, distance, "default", true))
		row.append(make_pose(id, xz, 0.0, CHILDHOOD_NEAREST, "default", true))
		for pose in row:
			pose["herd"] = herd
			pose["pitch"] = CHILDHOOD_PITCH
			pose["pitch_mode"] = "k98"
			poses.append(pose)
	return poses


## Yola Çıkış takımının pozları (saf; K98): her noktada 4 yön × 28 ve 40 m, 14 m (yön 0); eğim 38°. points: nokta → (x, z).
static func depart_poses(points: Dictionary) -> Array[Dictionary]:
	var poses: Array[Dictionary] = []
	for id in DEPART_POINTS:
		if not points.has(id):
			continue
		var xz: Vector2 = points[id]
		var row: Array[Dictionary] = []
		for distance: float in DEPART_DISTANCES:
			for yaw: float in YAWS:
				row.append(make_pose(id, xz, yaw, distance, "default", true))
		row.append(make_pose(id, xz, 0.0, CHILDHOOD_NEAREST, "default", true))
		for pose in row:
			pose["pitch"] = CHILDHOOD_PITCH
			pose["pitch_mode"] = "k98"
			poses.append(pose)
	return poses


## Pozun kimliği süzgeçten geçiyor mu? (--probe-only; boş ya da değersiz süzgeç her pozu geçirir.)
static func wanted(id: String, only: String) -> bool:
	return only == "" or only == "true" or id.contains(only)


## Makinenin yükü (macOS ve Linux'ta uptime çıktısı; okunamazsa boş).
static func system_load() -> String:
	if OS.get_name() == "Windows":
		return ""
	var output := []
	if OS.execute("uptime", PackedStringArray(), output) != 0 or output.is_empty():
		return ""
	return str(output[0]).strip_edges()


## Bellek sayacının MiB değeri; eksiye düşüp sarmışsa (COUNTER_LIMIT'ten büyük) null.
static func counter_mib(bytes: float) -> Variant:
	if bytes < 0.0 or bytes >= COUNTER_LIMIT:
		return null
	return snappedf(bytes / MIB, 0.1)


## Ağdaki üçgen sayısı (saf; ArrayMesh için diziler kopyalanmadan okunur).
static func mesh_triangles(mesh: Mesh) -> int:
	if mesh == null:
		return 0
	var total := 0
	for s in mesh.get_surface_count():
		if mesh is ArrayMesh:
			var array_mesh := mesh as ArrayMesh
			var indices := array_mesh.surface_get_array_index_len(s)
			total += (indices if indices > 0 else array_mesh.surface_get_array_len(s)) / 3
		else:
			var arrays := mesh.surface_get_arrays(s)
			var index_array: Variant = arrays[Mesh.ARRAY_INDEX]
			if index_array is PackedInt32Array and not (index_array as PackedInt32Array).is_empty():
				total += (index_array as PackedInt32Array).size() / 3
			else:
				total += (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return total


# --- Ölçüm --------------------------------------------------------------------------------------------

func _enter_tree() -> void:
	process_priority = PROCESS_LAST
	get_tree().process_frame.connect(_on_process_frame)


func _exit_tree() -> void:
	if get_tree().process_frame.is_connected(_on_process_frame):
		get_tree().process_frame.disconnect(_on_process_frame)


func _on_process_frame() -> void:
	_process_start = Time.get_ticks_usec()


## Süreç adımının sonu: bu düğüm en son işlenir (PROCESS_LAST). process_frame'den buraya dek geçen süre bütün
## düğümlerin _process işidir (GDScript ve motorun canlandırma gibi iç süreçleri); çizim ve fizik adımı dışındadır.
func _process(_delta: float) -> void:
	if _process_start > 0:
		_process_ms = float(Time.get_ticks_usec() - _process_start) / 1000.0


func _ready() -> void:
	_args = CaptureTool.parse_args(OS.get_cmdline_user_args())
	_capture = get_node_or_null(^"/root/DevCapture")
	if _capture and _capture.has_method(&"hold_capture"):
		_capture.call(&"hold_capture")
	else:
		_capture = null
	var probe := str(_args.get("probe", "camp"))
	if not PROBES.has(probe):
		push_error("[budget] bilinmeyen ölçüm takımı: %s (bilinen: %s)" % [probe, ", ".join(PackedStringArray(PROBES.keys()))])
		_finish()
		return
	_main = MAIN_SCENE.instantiate()
	add_child(_main)
	_run.call_deferred(probe)


func _run(probe: String) -> void:
	var warmup := maxi(int(_args.get("probe-warmup", WARMUP_FRAMES)), 0)
	var frames := maxi(int(_args.get("probe-frames", MEASURE_FRAMES)), 1)
	var settle := maxi(int(_args.get("probe-settle", SETTLE_FRAMES)), 0)
	var only := str(_args.get("probe-only", ""))
	# Dünyanın parçaları kurulumlarını bir kare erteler; menünün girişi atlanır (arayüz tam görünür).
	await _wait(6)
	var world := _main.get_node(^"World") as World
	var menu := _main.get_node(^"UI/MainMenu") as MainMenu
	menu.finish_intro()
	_force_look()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	_load_before = system_load()
	if probe == "childhood":
		await _run_childhood(warmup, frames, settle, only)
		return
	if probe == "depart":
		await _run_depart(warmup, frames, settle, only)
		return
	if probe == "kislak":
		await _run_kislak(warmup, frames, settle, only)
		return
	if probe == "prologue":
		await _run_prologue(warmup, frames, settle, only)
		return
	if probe != "camp":
		await _run_cine(probe, frames, only)
		return
	var points := _points_from(world)
	var poses := build_poses(points).filter(func(p: Dictionary) -> bool: return wanted(str(p["id"]), only))
	var menu_poses := ["menu", "menu/nograss"].filter(func(id: String) -> bool: return wanted(id, only))
	# Önsöz'ün geniş karesi (WIDE; K68, Yol Haritası prologue-pullback): yalnız süzgeçle istenince ölçülür
	# (--probe-only=wide ya da =menu); taban ölçümünün poz listesi değişmez.
	if only != "" and only != "true" and wanted("menu/wide", only):
		menu_poses.append("menu/wide")
	var total := poses.size() + menu_poses.size()
	print("[budget] takım=%s poz=%d ısınma=%d oturma=%d ölçüm=%d kare; pencere %s, sürücü %s" % [
		probe, total, warmup, settle, frames, _size_text(Vector2(DisplayServer.window_get_size())),
		RenderingServer.get_current_rendering_driver_name()])
	await _wait(warmup)
	var scene := _scene_counts(world)
	_textures = _estimate_textures("menu")
	# Menü karesi: menü kamerası, arayüz ve boyalı görünüm; çimensiz eşi çimenin menüdeki payıdır.
	for id: String in menu_poses:
		var grass := not id.ends_with("/nograss")
		_set_grass(world, grass)
		_show_wide(id == "menu/wide")
		var pose := {"id": id, "point": "menu", "grass": grass, "pitch_mode": "menu"}
		_results.append(await _measure_pose(pose, frames, settle, total))
	_show_wide(false)
	_set_grass(world, true)
	if not poses.is_empty():
		var camera := await _enter_play()
		if camera == null:
			push_error("[budget] Serbest Gez açılmadı; pozlar ölçülmedi")
		else:
			await _wait(PLAY_WARMUP_FRAMES)
			_textures = _estimate_textures("play")
			var shape := world.get_terrain_shape()
			for pose: Dictionary in poses:
				var xform := camera_transform(shape, pose)
				camera.global_transform = xform
				_set_grass(world, bool(pose["grass"]))
				pose["camera"] = [snappedf(xform.origin.x, 0.01), snappedf(xform.origin.y, 0.01), snappedf(xform.origin.z, 0.01)]
				_results.append(await _measure_pose(pose, frames, settle, total))
			_set_grass(world, true)
			# Görüntü (tools/capture.sh) Serbest Gez'in varsayılan kadrajıdır: ateş, 27 m, kuzey.
			camera.global_transform = camera_transform(shape, make_pose("fire", points["fire"], 0.0, FollowCamera.DEFAULT_DISTANCE, "default", true))
			await _wait(settle)
	_write_report(probe, scene, points, warmup, frames, settle, only)
	_finish()


## Sinema takımları (doğum, mit): dizi segmentin başına ileri sarılır (Yeni Oyun'un yolu, main.gd), saat ölçüm anına gelince o çekim
## ölçülür. Görüntü (tools/capture.sh) son çekimden kalan karedir.
func _run_cine(probe: String, frames: int, only: String) -> void:
	var timeline := CineTimeline.from_path(BIRTH_SEQUENCE)
	var all_poses := myth_poses(timeline) if probe == "myth" else birth_poses(timeline)
	var poses := all_poses.filter(func(p: Dictionary) -> bool: return wanted(str(p["id"]), only))
	print("[budget] takım=%s poz=%d ölçüm=%d kare; pencere %s, sürücü %s" % [probe, poses.size(), frames,
		_size_text(Vector2(DisplayServer.window_get_size())), RenderingServer.get_current_rendering_driver_name()])
	var cine := _main.get_node(^"CineHost") as CineHost
	_main.call(&"_play_prologue", BIRTH_SEQUENCE, timeline.time_of(probe))
	for pose: Dictionary in poses:
		while cine.is_playing() and cine.time() < float(pose["at"]):
			await get_tree().process_frame
		if not cine.is_playing():
			push_error("[budget] sinema ölçüm bitmeden kapandı: %s" % pose["id"])
			break
		if _textures.is_empty():
			_textures = _estimate_textures(probe)
		if probe == "myth":
			var myth := cine.scene_node("myth") as PrologueMyth
			pose["video"] = myth != null and myth.video != null
		_results.append(await _measure_pose(pose, frames, 0, poses.size()))
	_write_report(probe, _scene_counts(get_tree().root), {}, 0, frames, 0, only)
	_finish()


## Çocukluk takımı: kamp bırakılır, childhood_ordos kurulur, Çocukluk'un yerleri açılır; kamera takip kadrajlarında.
func _run_childhood(warmup: int, frames: int, settle: int, only: String) -> void:
	var points := childhood_points(OrdosWorld.load_layout(OrdosWorld.LAYOUT_PATH))
	var poses := childhood_poses(points).filter(func(p: Dictionary) -> bool: return wanted(str(p["id"]), only))
	print("[budget] takım=childhood poz=%d ısınma=%d oturma=%d ölçüm=%d kare; pencere %s, sürücü %s" % [poses.size(), warmup, settle, frames,
		_size_text(Vector2(DisplayServer.window_get_size())), RenderingServer.get_current_rendering_driver_name()])
	(_main.get_node(^"UI/MainMenu") as Control).visible = false
	(_main.get_node(^"CineHost") as CineHost).release_camp()
	var world := (load(CHILDHOOD_SCENE) as PackedScene).instantiate() as OrdosWorld
	_main.add_child(world)
	var camera := Camera3D.new()
	camera.near = 0.05
	camera.far = 6000.0
	camera.fov = CHILDHOOD_FOV
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	add_child(camera)
	camera.make_current()
	while not world.is_ready():
		await get_tree().process_frame
	world.set_childhood_mode(true)
	while not world.is_childhood_ready():
		await get_tree().process_frame
	var site := world.childhood()
	var shape := world.get_terrain_shape()
	var kids := _childhood_cast(world)
	# Sayımın en ağır anı: kalabalık toplanmış (11:00), Teoman ve üç bey ata binmiş hâlde Mete'nin önünden geçiyor, kalabalık onlara bakıyor.
	var column := _childhood_riders(world)
	world.set_childhood_time(ChildhoodScene.BEAT_MINUTE)
	if column and column.leader():
		site.watch_crowd(column.leader().position())
	await _wait(warmup)
	_textures = _estimate_textures("childhood")
	var herd_state := ""
	for pose: Dictionary in poses:
		if str(pose["herd"]) != herd_state:
			herd_state = str(pose["herd"])
			_set_herd(site, herd_state)
		var focus := Vector2(float(pose["x"]), float(pose["z"]))
		for i in kids.size():
			var at := focus + KID_OFFSETS[i % KID_OFFSETS.size()]
			kids[i].global_position = Vector3(at.x, shape.height_at(at.x, at.y), at.y)
		var xform := world.clamp_camera_transform(camera_transform(shape, pose),
			Vector3(focus.x, shape.height_at(focus.x, focus.y) + LOOK_HEIGHT, focus.y))
		camera.global_transform = xform
		pose["camera"] = [snappedf(xform.origin.x, 0.01), snappedf(xform.origin.y, 0.01), snappedf(xform.origin.z, 0.01)]
		_results.append(await _measure_pose(pose, frames, settle, poses.size()))
	var scene := _scene_counts(world)
	scene["sheep"] = site.herd.count()
	scene["sheep_triangles"] = site.herd.mesh_triangles()
	scene["rocks"] = int(site.scatter_counts.get("rocks", 0))
	scene["shrubs"] = int(site.scatter_counts.get("shrubs", 0))
	scene["crowd_cards"] = site.crowd.size() if site.crowd else 0
	scene["riders"] = column.size() if column else 0
	_write_report("childhood", scene, points, warmup, frames, settle, only)
	_finish()


## Yola Çıkış takımı: kamp bırakılır, depart_yurt kurulur; kişiler sahnedeki yerlerinde (DepartScene'in verisi), Mete pozun noktasında.
func _run_depart(warmup: int, frames: int, settle: int, only: String) -> void:
	(_main.get_node(^"UI/MainMenu") as Control).visible = false
	(_main.get_node(^"CineHost") as CineHost).release_camp()
	var world := (load(DEPART_SCENE) as PackedScene).instantiate() as DepartWorld
	_main.add_child(world)
	var camera := Camera3D.new()
	camera.near = 0.05
	camera.far = 6000.0
	camera.fov = CHILDHOOD_FOV
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	add_child(camera)
	camera.make_current()
	while not world.is_ready():
		await get_tree().process_frame
	var points := {}
	for id in DEPART_POINTS:
		var at := world.marker(id)
		if at != Vector3.INF:
			points[id] = Vector2(at.x, at.z)
	var poses := depart_poses(points).filter(func(p: Dictionary) -> bool: return wanted(str(p["id"]), only))
	print("[budget] takım=depart poz=%d ısınma=%d oturma=%d ölçüm=%d kare; pencere %s, sürücü %s" % [poses.size(), warmup, settle, frames,
		_size_text(Vector2(DisplayServer.window_get_size())), RenderingServer.get_current_rendering_driver_name()])
	var mete := await _depart_cast(world)
	world.mete_bow.visible = true
	world.mete_bow.global_transform = world.hang_transform()
	world.snow_follow = mete
	var shape := world.get_terrain_shape()
	await _wait(warmup)
	_textures = _estimate_textures("depart")
	for pose: Dictionary in poses:
		var focus2 := Vector2(float(pose["x"]), float(pose["z"]))
		mete.global_position = Vector3(focus2.x, shape.height_at(focus2.x, focus2.y), focus2.y)
		var focus := Vector3(focus2.x, shape.height_at(focus2.x, focus2.y) + LOOK_HEIGHT, focus2.y)
		var xform := world.clamp_camera_transform(camera_transform(shape, pose), focus)
		camera.global_transform = xform
		if world.home:
			world.home.set_camera_occlusion(xform.origin, focus)
			world.home.snap_cut(world.home.cut_goal)
		pose["camera"] = [snappedf(xform.origin.x, 0.01), snappedf(xform.origin.y, 0.01), snappedf(xform.origin.z, 0.01)]
		_results.append(await _measure_pose(pose, frames, settle, poses.size()))
	var scene := _scene_counts(world)
	scene["build_ms"] = snappedf(float(world.build_stats["ready_ms"]), 0.1)
	scene["build_max_frame_ms"] = snappedf(float(world.build_stats["max_frame_ms"]), 0.01)
	_write_report("depart", scene, points, warmup, frames, settle, only)
	_finish()


## Kışlak'ın pozları (saf): noktalar × 4 yön × 28 ve 40 m, ayrıca 14 m (yön 0); eğim K98'in 38°'si.
static func kislak_poses(points: Dictionary) -> Array[Dictionary]:
	var poses: Array[Dictionary] = []
	for id in KISLAK_POINTS:
		if not points.has(id):
			continue
		var xz: Vector2 = points[id]
		var row: Array[Dictionary] = []
		for distance: float in KISLAK_DISTANCES:
			for yaw: float in YAWS:
				row.append(make_pose(id, xz, yaw, distance, "default", true))
		row.append(make_pose(id, xz, 0.0, CHILDHOOD_NEAREST, "default", true))
		for pose in row:
			pose["pitch"] = CHILDHOOD_PITCH
		poses.append_array(row)
	return poses


## Önsöz'ün pozları (saf): noktalar × 4 yön × PROLOGUE_DISTANCES, ayrıca 14 m (yön 0); kimliğin başı evredir (day, storm).
static func prologue_poses(phase: String, points: Dictionary, ids: Array[String]) -> Array[Dictionary]:
	var poses: Array[Dictionary] = []
	for id in ids:
		if not points.has(id):
			continue
		var xz: Vector2 = points[id]
		var row: Array[Dictionary] = []
		for distance: float in PROLOGUE_DISTANCES:
			for yaw: float in YAWS:
				row.append(make_pose("%s:%s" % [phase, id], xz, yaw, distance, "default", true))
		row.append(make_pose("%s:%s" % [phase, id], xz, 0.0, CHILDHOOD_NEAREST, "default", true))
		for pose in row:
			pose["pitch"] = CHILDHOOD_PITCH
			pose["pitch_mode"] = "k98"
		poses.append_array(row)
	return poses


func _run_prologue(warmup: int, frames: int, settle: int, only: String) -> void:
	_main.set(&"prologue_path", "res://data/cine/prologue.json")
	_main.set(&"new_game_only", PackedStringArray(["prologue"]))
	_main.set(&"_force_prologue", true)
	_main.call(&"_begin_new_game", "prologue")
	var playing := _state_value(_main, "PLAYING")
	var days: PrologueDays = null
	for i in PLAY_TIMEOUT_FRAMES * 4:
		await get_tree().process_frame
		days = _main.call(&"prologue_runner") as PrologueDays
		if days and days.is_running() and int(_main.get(&"state")) == playing:
			break
	if days == null or not days.is_running():
		push_error("[budget] Önsöz'ün günleri açılmadı")
		_finish()
		return
	var player := _main.get_node(^"Player") as PlayerController
	var follow := _main.get_node(^"FollowCamera") as FollowCamera
	player.set_active(false)
	follow.set_active(false)
	var camera := follow.camera
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.fov = CHILDHOOD_FOV
	camera.make_current()
	var world := _main.get_node(^"World") as World
	var shape := world.get_terrain_shape()
	var points := {}
	for id in PROLOGUE_DAY_POINTS + PROLOGUE_NIGHT_POINTS:
		var at := days.point(id)
		if at != Vector3.INF:
			points[id] = Vector2(at.x, at.z)
	var day_poses := prologue_poses("day", points, PROLOGUE_DAY_POINTS).filter(func(p: Dictionary) -> bool: return wanted(str(p["id"]), only))
	var night_poses := prologue_poses("storm", points, PROLOGUE_NIGHT_POINTS).filter(func(p: Dictionary) -> bool: return wanted(str(p["id"]), only))
	var total := day_poses.size() + night_poses.size()
	print("[budget] takım=prologue poz=%d ısınma=%d oturma=%d ölçüm=%d kare; pencere %s, sürücü %s" % [total, warmup, settle, frames,
		_size_text(Vector2(DisplayServer.window_get_size())), RenderingServer.get_current_rendering_driver_name()])
	await _wait(warmup)
	_textures = _estimate_textures("prologue")
	for phase in ["day", "storm"]:
		if phase == "storm":
			# Tipi gecesi: kar yağışı, görüş ≈25 m, köz kabının ışığı, Börü yanında.
			days.set_time("21:30")
			days.set_weather("blizzard", 0.0, {"vis": 25.0, "wind": 13.0, "gust": 19.0, "dir_from": 300.0})
			days.set_snow(0.45)
			days.carry("ember_pot")
			var boru := days.cast.person("boru")
			if boru:
				boru.set_present(true)
			await _wait(settle * 3)
		for pose: Dictionary in (day_poses if phase == "day" else night_poses):
			var focus2 := Vector2(float(pose["x"]), float(pose["z"]))
			player.spawn_at(Vector3(focus2.x, shape.height_at(focus2.x, focus2.y), focus2.y), 0.0)
			if phase == "storm":
				var boru2 := days.cast.person("boru")
				if boru2:
					boru2.place(player.global_position + Vector3(1.4, 0.0, 1.2), player.global_position)
			var xform := camera_transform(shape, pose)
			camera.global_transform = xform
			pose["camera"] = [snappedf(xform.origin.x, 0.01), snappedf(xform.origin.y, 0.01), snappedf(xform.origin.z, 0.01)]
			_results.append(await _measure_pose(pose, frames, settle, total))
	var scene := _scene_counts(world)
	_write_report("prologue", scene, points, warmup, frames, settle, only)
	_finish()


func _run_kislak(warmup: int, frames: int, settle: int, only: String) -> void:
	(_main.get_node(^"UI/MainMenu") as Control).visible = false
	(_main.get_node(^"CineHost") as CineHost).release_camp()
	var world := (load(KISLAK_SCENE) as PackedScene).instantiate() as MapWorld
	_main.add_child(world)
	var camera := Camera3D.new()
	camera.near = 0.05
	camera.far = 6000.0
	camera.fov = CHILDHOOD_FOV
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	add_child(camera)
	camera.make_current()
	while not world.is_ready():
		await get_tree().process_frame
	var points := {}
	for id in KISLAK_POINTS:
		var at := world.marker(id)
		if at != Vector3.INF:
			points[id] = Vector2(at.x, at.z)
	var poses := kislak_poses(points).filter(func(p: Dictionary) -> bool: return wanted(str(p["id"]), only))
	print("[budget] takım=kislak poz=%d ısınma=%d oturma=%d ölçüm=%d kare; pencere %s, sürücü %s" % [poses.size(), warmup, settle, frames,
		_size_text(Vector2(DisplayServer.window_get_size())), RenderingServer.get_current_rendering_driver_name()])
	var mete := CharacterAvatar.new()
	mete.profile = CharacterProfile.new()
	world.add_child(mete)
	var shape := world.get_terrain_shape()
	await _wait(warmup)
	_textures = _estimate_textures("kislak")
	for pose: Dictionary in poses:
		var focus2 := Vector2(float(pose["x"]), float(pose["z"]))
		mete.global_position = Vector3(focus2.x, shape.height_at(focus2.x, focus2.y), focus2.y)
		var focus := Vector3(focus2.x, shape.height_at(focus2.x, focus2.y) + LOOK_HEIGHT, focus2.y)
		var xform := world.clamp_camera_transform(camera_transform(shape, pose), focus)
		camera.global_transform = xform
		pose["camera"] = [snappedf(xform.origin.x, 0.01), snappedf(xform.origin.y, 0.01), snappedf(xform.origin.z, 0.01)]
		_results.append(await _measure_pose(pose, frames, settle, poses.size()))
	var scene := _scene_counts(world)
	scene["build_ms"] = snappedf(float(world.build_stats["ready_ms"]), 0.1)
	scene["build_max_frame_ms"] = snappedf(float(world.build_stats["max_frame_ms"]), 0.01)
	_write_report("kislak", scene, points, warmup, frames, settle, only)
	_finish()


## Yola Çıkış'ın kişileri (DepartScene'in verisiyle: CineActor, Gutu kucakta) ve oluşturulan Mete (varsayılan profil). Döner: Mete.
func _depart_cast(world: DepartWorld) -> CharacterAvatar:
	var data := DepartScene.load_data()
	var defs: Dictionary = data.get("actors", {})
	var actors := {}
	for id: String in defs:
		var def: Dictionary = defs[id]
		var a := CineActor.new()
		a.character_id = id
		a.build_on_ready = false
		if str(def.get("pose", "")) == "sit":
			a.pose = &"sit"
		world.add_child(a)
		a.build()
		a.ensure_idle()
		actors[id] = a
		await get_tree().process_frame
	for id: String in defs:
		var def: Dictionary = defs[id]
		var a: CineActor = actors[id]
		var carrier := str(def.get("carried_by", ""))
		if carrier.is_empty():
			a.global_position = world.marker(str(def.get("start", "")))
		else:
			var c: CineActor = actors[carrier]
			c.global_position = world.marker(str((defs[carrier] as Dictionary).get("start", "")))
			a.global_transform = c.global_transform * Transform3D(Basis(Vector3.UP, deg_to_rad(DepartScene.CARRY_YAW_DEG)),
				Vector3(DepartScene.CARRY_OFFSET.x, 0.95 + DepartScene.CARRY_OFFSET.y, DepartScene.CARRY_OFFSET.z))
	var mete := CharacterAvatar.new()
	mete.profile = CharacterProfile.new()
	world.add_child(mete)
	return mete


## Kişiler: üç çocuk (yürür), Lan Hatun kapıda, sayıcı yerinde. Döner: pozla yer değiştiren çocuklar.
func _childhood_cast(world: OrdosWorld) -> Array[CharacterAvatar]:
	var kids: Array[CharacterAvatar] = []
	for i in CHILDHOOD_KIDS:
		var kid := _avatar(CHILD_MODEL, world, Vector3.ZERO)
		kid.set_locomotion(CHILD_WALK)
		kids.append(kid)
	_avatar("lan_hatun", world, world.marker("lan_stand"))
	_avatar("counter", world, world.marker("counter"))
	return kids


## Teoman ve beyleri (sahnenin verisinden: data/story/childhood/scene.json sayım adımının procession'ı): ata binmiş, Teoman Mete'nin hattaki
## yerinin önünde (geçiş noktası), beyler düzende. Atlar ve binicilerin pozu sahnenin koduyla (StoryMover, RideableHorse, RiderColumn).
func _childhood_riders(world: OrdosWorld) -> RiderColumn:
	var data := ChildhoodScene.load_data()
	var proc: Dictionary = {}
	for step: Dictionary in data.get("steps", []):
		if step.get("procession") is Dictionary:
			proc = step["procession"]
	if proc.is_empty():
		return null
	var shape := world.get_terrain_shape()
	var pts := PackedVector2Array()
	for p: Array in proc.get("path", []):
		pts.append(Vector2(float(p[0]), float(p[1])))
	var column := RiderColumn.new(pts, shape)
	var child := world.marker("children_at_line")
	column.pass_at = column.closest_offset(Vector2(child.x, child.z)) - float(proc.get("lead", 2.5))
	var leader_id := str(proc.get("leader", "teoman"))
	var riders: Array = [{"model": leader_id, "horse": str((data["actors"] as Dictionary)[leader_id].get("horse", "horse_white")), "slot": [0.0, 0.0]}]
	riders.append_array(proc.get("escort", []))
	for r: Dictionary in riders:
		var actor := CineActor.new()
		actor.character_id = str(r["model"])
		actor.build_on_ready = false
		world.add_child(actor)
		actor.build()
		var horse := RideableHorse.new()
		horse.model_path = ChildhoodScene.HORSE_DIR % [r["horse"], r["horse"]]
		world.add_child(horse)
		var mover := StoryMover.new(actor, shape, horse)
		mover.place(child, 0.0)
		mover.seat()
		RiderShadow.attach(horse, actor)
		var slot: Array = r.get("slot", [0.0, 0.0])
		column.add(mover, Vector2(float(slot[0]), float(slot[1])))
	column.start(column.pass_at)
	column.speed = column.pass_speed
	column.tick(1.0 / 60.0)
	return column


static func _avatar(model: String, parent: Node, at: Vector3) -> CharacterAvatar:
	var avatar := CharacterAvatar.new()
	avatar.model_override = model
	parent.add_child(avatar)
	avatar.global_position = at
	return avatar


static func _set_herd(site: ChildhoodSite, state: String) -> void:
	match state:
		"pen":
			site.reset_herd()
		"leaving":
			site.reset_herd()
			site.release_herd()
		"meadow":
			site.skip_herd_to_meadow()
		"line":
			site.skip_herd_to_meadow()
			site.drive_herd()
		"water":
			# E21: sürü göl kıyısının otlağında.
			site.herd.place_on_meadow(Vector2(334.0, 46.0), 12.0)
		"way":
			# E21: sürü göle giden yolun ortasında.
			site.herd.place_on_meadow(Vector2(160.0, 30.0), 8.0)


## Boyalı görünüm açık (oyunun görünüşü; oyuncunun ayarı kapatmış olabilir; ayar dosyasına yazılmaz).
func _force_look() -> void:
	var settings := get_node_or_null(^"/root/GameSettings")
	if settings and &"painterly" in settings:
		settings.set(&"painterly", true)
	var overlay := _main.get_node_or_null(^"PainterlyOverlay")
	if overlay and &"enabled" in overlay:
		overlay.set(&"enabled", true)


## Önsöz'ün geniş karesi: menü kamerası WIDE'da nefes alır (MenuCamera.start_drift), menü yazıları sönük; off menü
## kadrajına döner.
func _show_wide(on: bool) -> void:
	var camera := _main.get_node(^"MenuCamera") as MenuCamera
	var menu := _main.get_node(^"UI/MainMenu") as Control
	if on:
		menu.visible = false
		camera.start_drift(MenuCamera.wide_transform())
	elif camera.has_drift_base:
		camera.clear_drift()
		camera.global_transform = camera.menu_transform
		menu.visible = true


## Dünyadaki noktalar: ateş, ahır ve iki yurt düğümlerinden, oyun alanı oyuncunun ayarından.
func _points_from(world: World) -> Dictionary:
	var fire := _xz(world.get_node_or_null(^"Camp/Campfire"), JourneyFlags.DEFAULT_FIRE)
	var stable := _xz(world.get_node_or_null(^"Camp/Stable"), JourneyFlags.DEFAULT_STABLE)
	var yurt_a := _xz(world.get_node_or_null(^"Camp/YurtLeft"), fire)
	var yurt_b := _xz(world.get_node_or_null(^"Camp/YurtRight"), fire)
	var player := _main.get_node_or_null(^"Player") as PlayerController
	var center := player.play_area_center if player else Vector2.ZERO
	var radius := player.play_area_radius if player else 38.0
	return camp_points(fire, stable, yurt_a, yurt_b, center, radius)


static func _xz(node: Node, fallback: Vector2) -> Vector2:
	var n3 := node as Node3D
	return Vector2(n3.global_position.x, n3.global_position.z) if n3 else fallback


## Serbest Gez: menünün «Serbest Gez» isteğiyle (oyuncunun yolu) kampa inilir, varsayılan karakterle. Oyuncunun
## girdisi ve takip kamerası kapatılır; kamerayı ölçüm yönetir (takip kamerasının kendi kamerası).
func _enter_play() -> Camera3D:
	_main.set(&"profile", CharacterProfile.new())
	var menu := _main.get_node(^"UI/MainMenu") as MainMenu
	var follow := _main.get_node(^"FollowCamera") as FollowCamera
	var player := _main.get_node(^"Player") as PlayerController
	var playing := _state_value(_main, "PLAYING")
	menu.free_roam_requested.emit()
	for i in PLAY_TIMEOUT_FRAMES:
		await get_tree().process_frame
		if follow.is_active() and int(_main.get(&"state")) == playing:
			break
	if not follow.is_active():
		return null
	player.set_active(false)
	follow.set_active(false)
	var camera := follow.camera
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.fov = FollowCamera.DEFAULT_FOV
	camera.make_current()
	return camera


## Ana sahnenin durum sayısı (main.gd'nin State sayımı; betiğin sabitlerinden okunur).
static func _state_value(main: Node, state_name: String) -> int:
	var script := main.get_script() as Script
	var states: Variant = script.get_script_constant_map().get("State") if script else null
	return int((states as Dictionary).get(state_name, -1)) if states is Dictionary else -1


## Çayırın çimen tutamları (Meadow'un "Grass_*" MultiMesh'leri; çiçekler kalır).
static func _set_grass(world: Node, visible: bool) -> void:
	var meadow := world.get_node_or_null(^"Meadow")
	if meadow == null:
		return
	for node in meadow.get_children():
		if node is MultiMeshInstance3D and String(node.name).begins_with("Grass"):
			(node as MultiMeshInstance3D).visible = visible


## Bir pozu ölçer: oturma kareleri, sonra frames kare boyunca kare başına okunanlar; özet satırı döner.
func _measure_pose(pose: Dictionary, frames: int, settle: int, total: int) -> Dictionary:
	await _wait(settle)
	var viewport := get_viewport()
	var rid := viewport.get_viewport_rid()
	var keys: Array[String] = ["frame_ms", "gpu_ms", "cpu_ms", "script_ms", "draw_calls_visible", "draw_calls_shadow",
		"draw_calls_canvas", "triangles_visible", "triangles_shadow", "objects_visible", "objects_shadow"]
	var series := {}
	for key in keys:
		series[key] = []
	var last := Time.get_ticks_usec()
	for i in frames:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		var sample := [
			float(now - last) / 1000.0,
			RenderingServer.viewport_get_measured_render_time_gpu(rid),
			RenderingServer.viewport_get_measured_render_time_cpu(rid),
			_process_ms,
			viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
			viewport.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
			viewport.get_render_info(Viewport.RENDER_INFO_TYPE_CANVAS, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
			viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),
			viewport.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),
			viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_OBJECTS_IN_FRAME),
			viewport.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW, Viewport.RENDER_INFO_OBJECTS_IN_FRAME),
		]
		last = now
		for k in keys.size():
			(series[keys[k]] as Array).append(float(sample[k]))
	var row := pose.duplicate()
	for key in keys:
		row[key] = summarize(PackedFloat64Array(series[key]), 0.001 if key.ends_with("_ms") else 0.1)
	row["texture_mib"] = _textures.get("mib", 0.0)
	row["texture_counter_mib"] = counter_mib(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED))
	row["buffer_mib"] = counter_mib(Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED))
	row["video_mib"] = counter_mib(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))
	print("[budget] %d/%d %s: kare %.2f ms (%%95 %.2f), gpu %.2f ms, çizim %d + gölge %d, üçgen %.2fM + gölge %.2fM" % [
		_results.size() + 1, total, row["id"], row["frame_ms"]["mean"], row["frame_ms"]["p95"], row["gpu_ms"]["mean"],
		int(row["draw_calls_visible"]["max"]), int(row["draw_calls_shadow"]["max"]),
		float(row["triangles_visible"]["max"]) / 1e6, float(row["triangles_shadow"]["max"]) / 1e6])
	return row


## Sahnedeki 3B malzeme dokuları (texture_mem_probe.gd'nin hesabı: her doku bir kez, biçim ve mip düzeyiyle):
## toplam MiB, doku sayısı, VRAM sıkıştırmalı olanlar. phase raporda ayrı yazılır (menü ve Serbest Gez).
func _estimate_textures(phase: String) -> Dictionary:
	var textures := {}
	TextureMemProbe.collect_textures(get_tree().root, textures)
	var total := 0.0
	var compressed := 0
	for row: Dictionary in textures.values():
		total += float(row["bytes"])
		if row["compressed"]:
			compressed += 1
	var out := {"mib": snappedf(total / MIB, 0.1), "textures": textures.size(), "compressed": compressed}
	_textures_by_phase[phase] = out
	return out


## Sahnenin sayıları (godot.md §7.2 dipnotu): görünür konumsal ışıklar (gölgeli ayrı), çalan ses oynatıcıları ve
## görünür MultiMesh örneklerinin toplam üçgeni (kırpmadan önce; ground_perf.gd gibi), çimeninki ayrı.
func _scene_counts(world: Node) -> Dictionary:
	var root := get_tree().root
	var lights := 0
	var shadowed := 0
	for node in root.find_children("*", "Light3D", true, false):
		var light := node as Light3D
		if light is DirectionalLight3D or not light.is_visible_in_tree():
			continue
		lights += 1
		if light.shadow_enabled:
			shadowed += 1
	var players := 0
	for type in ["AudioStreamPlayer", "AudioStreamPlayer2D", "AudioStreamPlayer3D"]:
		for node in root.find_children("*", type, true, false):
			if bool(node.get(&"playing")):
				players += 1
	var mm_total := 0
	var mm_grass := 0
	var cache := {}
	for node in world.find_children("*", "MultiMeshInstance3D", true, false):
		var mmi := node as MultiMeshInstance3D
		if not mmi.is_visible_in_tree() or mmi.multimesh == null or mmi.multimesh.mesh == null:
			continue
		var mesh := mmi.multimesh.mesh
		if not cache.has(mesh):
			cache[mesh] = mesh_triangles(mesh)
		var count := mmi.multimesh.visible_instance_count
		var tris: int = cache[mesh] * (mmi.multimesh.instance_count if count < 0 else count)
		mm_total += tris
		if String(mmi.name).begins_with("Grass") and mmi.get_parent() and mmi.get_parent().name == &"Meadow":
			mm_grass += tris
	return {
		"positional_lights": lights,
		"positional_lights_shadowed": shadowed,
		"audio_players": players,
		"multimesh_triangles": mm_total,
		"grass_triangles": mm_grass,
	}


func _write_report(probe: String, scene: Dictionary, points: Dictionary, warmup: int, frames: int, settle: int, only: String) -> void:
	var viewport := get_viewport()
	var version: Dictionary = Engine.get_version_info()
	var point_rows := {}
	for id: String in points:
		var p: Vector2 = points[id]
		point_rows[id] = [snappedf(p.x, 0.01), snappedf(p.y, 0.01)]
	var report := {
		"version": VERSION,
		"probe": probe,
		"row": PROBES[probe],
		"date": Time.get_datetime_string_from_system(false, true),
		"device": {
			"adapter": RenderingServer.get_video_adapter_name(),
			"vendor": RenderingServer.get_video_adapter_vendor(),
			"driver": RenderingServer.get_current_rendering_driver_name(),
			"method": RenderingServer.get_current_rendering_method(),
			"godot": str(version.get("string", "")),
			"os": "%s %s" % [OS.get_name(), OS.get_version()],
			"cpu": OS.get_processor_name(),
			"threads": OS.get_processor_count(),
			"window": _size_text(Vector2(DisplayServer.window_get_size())),
			"viewport": _size_text(viewport.get_visible_rect().size),
			"screen_scale": DisplayServer.screen_get_scale(),
			"scaling_3d_mode": SCALING_NAMES.get(int(viewport.scaling_3d_mode), str(viewport.scaling_3d_mode)),
			"scaling_3d_scale": viewport.scaling_3d_scale,
			"msaa_3d": viewport.msaa_3d,
			"vsync": DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED,
			"gpu_timing": _results.any(func(r: Dictionary) -> bool: return float(r.get("gpu_ms", {}).get("max", 0.0)) > 0.0),
			"load_before": _load_before,
			"load_after": system_load(),
		},
		"settings": {"warmup": warmup, "frames": frames, "settle": settle, "only": "" if only == "true" else only, "painterly": true},
		"points": point_rows,
		"scene": scene,
		"textures": {
			"source": "3B malzeme dokuları (texture_mem_probe.gd: biçim ve mip düzeyiyle); motor sayacı texture_counter_mib",
			"phases": _textures_by_phase,
			"counter_valid": _results.any(func(r: Dictionary) -> bool: return r.get("texture_counter_mib") != null),
		},
		"poses": _results,
		"grass_share": grass_share(_results),
	}
	var text := JSON.stringify(report, "\t")
	var path := output_path(_args)
	if path == "":
		print("[budget] JSON yolu yok (--probe-out ya da --capture); sonuç:\n" + text)
		return
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("[budget] JSON yazılamadı: %s (%s)" % [path, error_string(FileAccess.get_open_error())])
		return
	file.store_string(text + "\n")
	file.close()
	print("[budget] sonuç: %s (%d poz)" % [path, _results.size()])


## Ölçüm bitti: yakalama aracı görüntüyü alıp oyunu kapatır; araç yoksa oyun burada kapanır.
func _finish() -> void:
	if _capture:
		_capture.call(&"release_capture")
	else:
		get_tree().quit()


func _wait(frames: int) -> void:
	for i in frames:
		await get_tree().process_frame


static func _size_text(size: Vector2) -> String:
	return "%dx%d" % [int(size.x), int(size.y)]
