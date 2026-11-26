class_name MenuCamera
extends Camera3D
## Ana menünün kamerası.
##
## Menüdeyken çok hafif "nefes alır" (yavaş salınım) ve fareye göre birkaç derece kayar (paralaks);
## sahne canlı görünür ama kadraj referanstaki gibi kalır. fly_to() ile başka bir kamera konumuna
## yumuşakça uçar (menü ↔ oyun geçişleri).
##
## Kadraj 16:9 için tasarlanmıştır. Ekran daha darsa (ör. 16:10 MacBook) yatay görüş açısı korunur:
## yurtlar ve ahır kenarlardan kesilmez, üstte ve altta biraz daha çayır ve orman görünür (menü kadrajında ufuk yoktur).
## Ekran daha genişse dikey açı korunur, yanlarda biraz daha manzara görünür.
##
## Menü kadrajı (K98; scenes/main.tscn'deki MenuCamera; referans docs/media/review/kadraj_referans.webp): kampa yukarıdan,
## kuzeye bakar; ateşe 26,4 m, eğim 38°, dikey görüş 36° (takip kamerasının K98 kadrajı; ayakta kişi kare yüksekliğinin
## ≈%8'i). Ateş ve ateş başı sağ ortadadır (soldan %58, yukarıdan %60), sol taraf menü panelinin altında kalır, iki yurt ve
## ahır aynı karededir, ufuk görünmez. Önde kadrajı kapatan çam ya da kaya yoktur (ön kayalar karenin alt kenarındadır).
##
## Önsöz'ün geri çekilmesi (K68, K98, godot.md §3.6): Yeni Oyun'da kamera ozana yaklaşmaz, menü kadrajından WIDE'a
## geri çekilir: fly_to(wide_transform(), PULLBACK_TIME, WIDE_FOV); ateşe 26,4 m'den 40 m'ye (1,52 kat; uzaklık hiç
## azalmaz), eğim 38°'den 9°'ye, görüş 36°'den 41,76°'ye, yön kuzey; ufuk 3,5 sn'de kareye girer, ateş karenin
## ortasının sağından (%58, %60) WIDE'daki yerine (%50, %80) kayar. WIDE kullanıcının onayladığı karedir (K68), K98'in
## ufuk istisnasıdır (40 m). WIDE'da start_drift(WIDE) ile kendi görüşünde (WIDE_FOV, drift_fov) menünün salınımıyla
## (0,06 m, 0,18 Hz) paralakssız nefes alır:
## salınımın merkezi drift_base'tir, menu_transform değişmez, menüye dönüş karesi aynı kalır (return_to_menu ve
## clear_drift drift_base'i boşaltır).

## Menü kadrajının eğimi ve 16:9'daki dikey görüşü (derece; sahnedeki dönüşümle aynı, test_menu_camera denetler).
const MENU_PITCH_DEG := 38.0
const MENU_FOV := 36.0

## WIDE: Önsöz'ün geniş karesi (dünya; ateş ve kamp merkezi 0, 0, 0). Kamp, vadi, göl, dağlar ve gök aynı karede:
## ufuk yukarıdan %29'da, ateş %80'de (ölçü 16:9, dikey görüş WIDE_FOV).
const WIDE_ORIGIN := Vector3(0.27, 14.9, 37.1)
const WIDE_PITCH_DEG := 9.0
const WIDE_FOV := 41.76
## Geri çekilmenin süresi (saniye).
const PULLBACK_TIME := 6.0

## Menü kadrajı. Boşsa sahnedeki ilk konum kullanılır.
@export var menu_transform := Transform3D.IDENTITY
## Kadrajın tasarlandığı en-boy oranı ve bu orandaki dikey görüş açısı (derece).
@export var design_aspect := 16.0 / 9.0
@export var design_fov := 32.5:
	set(value):
		design_fov = value
		if is_inside_tree():
			_apply_aspect()
## Salınım genliği (metre) ve hızı.
@export var drift_amount := 0.06
@export var drift_speed := 0.18
## Fareyle kayma (derece).
@export var parallax_degrees := 1.2

var drifting := true
## Salınımın merkezi (has_drift_base doğruysa; ör. Önsöz'ün WIDE'ı): menu_transform değişmez.
var drift_base := Transform3D.IDENTITY
var has_drift_base := false
## Salınımın merkezindeki dikey görüş (16:9; derece; ≤0 ise menünün design_fov'u). WIDE'ın kendi görüşü vardır (WIDE_FOV, K68):
## menü kadrajı K98 ile 36°'ye daraldı, WIDE onaylı karesinde kalır.
var drift_fov := -1.0
## drift_base çevresinde fare paralaksı da uygulansın mı?
var drift_parallax := false
var _time := 0.0
var _parallax := Vector2.ZERO
var _tween: Tween


func _ready() -> void:
	if menu_transform == Transform3D.IDENTITY:
		menu_transform = global_transform
	get_viewport().size_changed.connect(_apply_aspect)
	_apply_aspect()


func _process(delta: float) -> void:
	if not drifting:
		return
	_time += delta
	var target := Vector2.ZERO
	var viewport := get_viewport()
	var with_parallax := not has_drift_base or drift_parallax
	if viewport and not Engine.is_editor_hint() and with_parallax:
		var size := viewport.get_visible_rect().size
		if size.x > 0.0 and size.y > 0.0:
			target = (viewport.get_mouse_position() / size - Vector2(0.5, 0.5)) * 2.0
	_parallax = _parallax.lerp(target.clampf(-1.0, 1.0), clampf(delta * 1.5, 0.0, 1.0))
	# Geçişten sonra salınım sıfırdan yumuşakça başlasın (zıplama olmasın).
	var weight := smoothstep(0.0, 2.5, _time)
	var base := drift_base if has_drift_base else menu_transform
	global_transform = drift_transform(base, _time, _parallax * weight, drift_amount * weight, drift_speed, parallax_degrees)


## Salınım + paralaks uygulanmış kadraj (saf fonksiyon, test edilebilir).
static func drift_transform(base: Transform3D, t: float, parallax: Vector2, amount: float, speed: float, degrees: float) -> Transform3D:
	var offset := Vector3(sin(t * speed * TAU) * amount, sin(t * speed * TAU * 0.7 + 1.3) * amount * 0.5, 0.0)
	var yaw := deg_to_rad(-parallax.x * degrees)
	var pitch := deg_to_rad(-parallax.y * degrees * 0.5)
	var basis := base.basis * Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)
	return Transform3D(basis, base.origin + base.basis * offset)


## Önsöz'ün geniş karesi (saf): WIDE_ORIGIN'de, kuzeye (-Z) bakan, WIDE_PITCH_DEG aşağı eğik.
static func wide_transform() -> Transform3D:
	return Transform3D(Basis(Vector3.RIGHT, -deg_to_rad(WIDE_PITCH_DEG)), WIDE_ORIGIN)


## fly_to'nun t saniyedeki pozu (saf; aynı formül): Tween'in TRANS_SINE / EASE_IN_OUT eğrisi, konum doğrusal, yön
## küresel aradeğer (Transform3D.interpolate_with). to boşsa WIDE.
static func pullback_pose(from: Transform3D, t: float, duration: float = PULLBACK_TIME, to: Variant = null) -> Transform3D:
	var target: Transform3D = to if to is Transform3D else wide_transform()
	return from.interpolate_with(target, ease_in_out(t / duration if duration > 0.0 else 1.0))


## Tween'in TRANS_SINE + EASE_IN_OUT eğrisi (saf): 0 → 0, 0,5 → 0,5, 1 → 1.
static func ease_in_out(k: float) -> float:
	var x := clampf(k, 0.0, 1.0)
	return -(cos(PI * x) - 1.0) * 0.5


## Kameranın karesinde bir noktanın yukarıdan oranı (0 üst kenar, 1 alt kenar; saf). vfov: dikey görüş (derece).
## Kameranın arkasındaki nokta için NAN.
static func screen_y(xform: Transform3D, vfov_deg: float, point: Vector3) -> float:
	var local := xform.affine_inverse() * point
	if local.z >= -0.0001:
		return NAN
	return 0.5 - (local.y / -local.z) / tan(deg_to_rad(vfov_deg) * 0.5) * 0.5


## Ufkun (yatay bakış, sonsuzda) karedeki yukarıdan oranı (saf).
static func horizon_y(xform: Transform3D, vfov_deg: float) -> float:
	var forward := -xform.basis.z
	var flat := Vector3(forward.x, 0.0, forward.z)
	if flat.length_squared() < 0.000001:
		return NAN
	var local := xform.basis.inverse() * flat.normalized()
	return 0.5 - (local.y / -local.z) / tan(deg_to_rad(vfov_deg) * 0.5) * 0.5


## Kamera yolunun engellere en küçük payı (metre; saf): her örnek nokta (dünya) için çam taçlarına (TreeKit
## konisi: boy ve taç yarıçapı ağacın ölçeğinden), kayalara (küre) ve zemine (dikey) uzaklığın en küçüğü.
##   trees: Vector4(x, z, ölçek, tabanın zemin yüksekliği); rocks: Vector4(x, y, z, yarıçap) (y: kayanın merkezi);
##   ground: (x, z) → zemin yüksekliği (boşsa zemin sayılmaz).
static func path_clearance(samples: PackedVector3Array, trees: Array[Vector4], rocks: Array[Vector4], ground: Callable) -> float:
	var best := INF
	for q in samples:
		if ground.is_valid():
			best = minf(best, q.y - float(ground.call(q.x, q.z)))
		for tree in trees:
			best = minf(best, crown_clearance(q, tree))
		for rock in rocks:
			best = minf(best, q.distance_to(Vector3(rock.x, rock.y, rock.z)) - rock.w)
	return best


## Noktanın çamın tacına (TreeKit dal konisi) uzaklığı (metre; saf; içerideyse eksi). tree: Vector4(x, z, ölçek,
## taban yüksekliği). Koni dikey kesitte (yatay uzaklık, yükseklik) düzleminde bir doğru parçasıdır: tabanda
## CONE_BASE_RADIUS, tepede CONE_TOP_RADIUS (ölçekle çarpılır).
static func crown_clearance(q: Vector3, tree: Vector4) -> float:
	var s := tree.z
	var radial := Vector2(q.x, q.z).distance_to(Vector2(tree.x, tree.y))
	var h := q.y - tree.w
	var bottom := Vector2(TreeKit.CONE_BASE_RADIUS * s, TreeKit.CONE_BOTTOM * s)
	var top := Vector2(TreeKit.CONE_TOP_RADIUS * s, TreeKit.CONE_TOP * s)
	var p := Vector2(radial, h)
	var inside := h >= bottom.y and h <= top.y and radial <= lerpf(bottom.x, top.x, (h - bottom.y) / (top.y - bottom.y))
	var d := minf(MenuCamera._segment_distance(p, bottom, top),
		minf(MenuCamera._segment_distance(p, Vector2(0.0, bottom.y), bottom), MenuCamera._segment_distance(p, Vector2(0.0, top.y), top)))
	return -d if inside else d


## Geri çekilme yolunun örnekleri (saf): 0'dan duration'a step adımla fly_to'nun kamera konumları.
static func pullback_samples(from: Transform3D, step: float = 0.1, duration: float = PULLBACK_TIME) -> PackedVector3Array:
	var out := PackedVector3Array()
	var count := int(roundf(duration / step))
	for i in count + 1:
		out.append(pullback_pose(from, minf(i * step, duration), duration).origin)
	return out


static func _segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var k := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0000001), 0.0, 1.0)
	return p.distance_to(a + ab * k)


## Tasarım kadrajını verilen ekran oranına uydurur (saf fonksiyon, test edilebilir).
## Döner: {"keep": Camera3D.KEEP_HEIGHT veya KEEP_WIDTH, "fov": derece}.
## Ekran tasarımdan darsa yatay açı sabit tutulur (KEEP_WIDTH), değilse dikey açı (KEEP_HEIGHT).
static func fit_fov(design_vfov: float, p_design_aspect: float, aspect: float) -> Dictionary:
	if aspect <= 0.0 or aspect >= p_design_aspect:
		return {"keep": Camera3D.KEEP_HEIGHT, "fov": design_vfov}
	var half_width := atan(tan(deg_to_rad(design_vfov) * 0.5) * p_design_aspect)
	return {"keep": Camera3D.KEEP_WIDTH, "fov": rad_to_deg(half_width * 2.0)}


## Verilen görüş açısı ayarının o ekran oranındaki DİKEY karşılığı (derece; saf fonksiyon).
static func vertical_fov_of(fov_deg: float, keep: int, aspect: float) -> float:
	if keep == Camera3D.KEEP_HEIGHT or aspect <= 0.0:
		return fov_deg
	return rad_to_deg(2.0 * atan(tan(deg_to_rad(fov_deg) * 0.5) / aspect))


func _viewport_aspect() -> float:
	var size := get_viewport().get_visible_rect().size
	return size.x / size.y if size.y > 0.0 else design_aspect


func _apply_aspect() -> void:
	if not drifting:
		return  # Uçuş sırasında görüş açısını tween yönetir.
	var vfov := drift_fov if has_drift_base and drift_fov > 0.0 else design_fov
	var fit := fit_fov(vfov, design_aspect, _viewport_aspect())
	keep_aspect = fit["keep"]
	fov = fit["fov"]


## Kamerayı verilen konuma yumuşakça uçurur; bittiğinde sinyal verir (await edilebilir).
## target_vfov > 0 ise görüş açısı da o dikey açıya geçer (ör. oyun kamerasının açısı).
func fly_to(target: Transform3D, duration: float = 1.4, target_vfov: float = -1.0) -> Signal:
	drifting = false
	_kill_tween()
	var from := global_transform
	# Uçuş boyunca dikey açıyla çalış; başlangıçtaki görüntü değişmesin diye eşdeğer dikey açıdan başla.
	var aspect := _viewport_aspect()
	var from_vfov := vertical_fov_of(fov, keep_aspect, aspect)
	keep_aspect = Camera3D.KEEP_HEIGHT
	fov = from_vfov
	var to_vfov := target_vfov if target_vfov > 0.0 else from_vfov
	_tween = create_tween()
	_tween.tween_method(func(k: float) -> void:
		global_transform = from.interpolate_with(target, k)
		fov = lerpf(from_vfov, to_vfov, k), 0.0, 1.0, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return _tween.finished


## Uçuşu (varsa) durdurur: kamera olduğu yerde kalır (sinemanın atlanması, sahnenin geri yazılması).
func stop_flight() -> void:
	_kill_tween()


## Uçuyor mu?
func is_flying() -> bool:
	return _tween != null and _tween.is_valid() and _tween.is_running()


## base çevresinde salınım başlatır (menu_transform değişmez): kamera base'e konur, salınım sıfırdan yumuşakça
## açılır; parallax kapalıysa fare kadrajı kaydırmaz. Uçuş varsa durur. vfov verilmezse WIDE'da WIDE_FOV, başka yerde menünün
## design_fov'u geçerlidir.
func start_drift(base: Transform3D, parallax: bool = false, vfov: float = -1.0) -> void:
	_kill_tween()
	drift_base = base
	has_drift_base = true
	drift_parallax = parallax
	drift_fov = vfov if vfov > 0.0 else (WIDE_FOV if base.is_equal_approx(MenuCamera.wide_transform()) else -1.0)
	_time = 0.0
	_parallax = Vector2.ZERO
	global_transform = base
	drifting = true
	_apply_aspect()


## Salınımın merkezini menü kadrajına döndürür (drift_base boşalır).
func clear_drift() -> void:
	drift_base = Transform3D.IDENTITY
	has_drift_base = false
	drift_parallax = false
	drift_fov = -1.0


## Menü kadrajına geri uçar ve salınımı yeniden başlatır.
func return_to_menu(duration: float = 1.6) -> void:
	clear_drift()
	var fit := fit_fov(design_fov, design_aspect, _viewport_aspect())
	await fly_to(menu_transform, duration, vertical_fov_of(fit["fov"], fit["keep"], _viewport_aspect()))
	_time = 0.0
	drifting = true
	_apply_aspect()


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null
