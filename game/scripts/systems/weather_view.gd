class_name WeatherView
extends Node3D
## Havanın görünümü (weather.md §9; godot.md §3 «WeatherView», §4.9): WeatherSim'in durumunu okur ve çizer. Işık eklenmez (H8): ışığın,
## ortamın, sisin ve gök tekdüzenlerinin tek yazıcısı SkyRig'dir; görünüm ona hava girdisini verir (SkyRig.set_weather). Kendi çizdikleri:
##   - Yağış noktaları (Precip, GPUParticles3D, ≤6000 + 192 sıçrama, tek çizim): kar, yoğun kar, tipi, Kara Boran, sulu kar, dolu, toz;
##     kutu 50 × 22 × 50 m (K98 kadrajı; aşağıda BOX), odak + 6 m kameranın baktığı yönde, +8 m yukarı; dünyaya bağlı sarılır
##     (shaders/weather_precip.gdshader).
##   - Yıldırım şeridi (Bolt, ≤96 üçgen, 0,35 sn; ≤900 m ve kadrajdaysa), kadraj dışı ≤1,5 km düşüşte ekranın kenarında ayak.
##   - Ekran yağışı (ScreenLayer, katman 2: PainterlyOverlay'den sonra, arayüzden önce): yağmur, kar, dolu ve toz çizgisi, üç katman,
##     paralaks ve sarma; katman alfası LAYER_ALPHA (K58, W16); türün derecesi (doygunluk, karşıtlık, ton) yalnız hava varken.
##   - Zemin ve rüzgâr genel tekdüzenleri (weather_ground, weather_wind): ıslak zemin, birikinti, kar örtüsü, dolu, çimin bükülmesi.
## Kimlik (menü; §9.12): WeatherSim.enter_k 0'a inince her şey gizlenir, genel tekdüzenler 0'a, SkyRig'in hava girdisi boşa döner:
## menü karesi değişmez. Çizim payı en kötü +2 (yağış ve şerit), ekran katmanı 0 çizim.
##   var view := WeatherView.new()
##   world.add_child(view)
##   view.bind(sim, world, player)

## Katman alfası (weather.md §9.3, K58; W16): 0,5'te yağmur çizgisi boyalı süzgeçte zayıf okundu (2026-11-08, 900p: yurdun keçesinde
## soluk, çimende neredeyse görünmez), kural gereği 0,65'e çıktı; başka değer denenmedi. Göz onayı kullanıcınındır.
const LAYER_ALPHA := 0.65
const LAYER_ALPHA_BASE := 0.5
const POINTS_MAX := 6000
const SPLASH_MAX := 192
## Karede en çok yeni sıçrama; sıçramanın yaşamı (sn; yağmur tacı, dolu sekmesi) ve odak çevresindeki daire (m).
const SPLASH_PER_FRAME := 32
const SPLASH_LIFE := Vector2(0.25, 0.4)
const SPLASH_RADIUS := 24.0
## Yağış kutusu (m). weather.md §9.4'ün 70 × 30 × 90'lık kutusu prototipin alçak kamerası içindi; K98'in uzak ve yüksek kadrajında (38°,
## 28 m) görünen hava odağın çevresinde ince bir kamadır (yerde ≈10 m geriden ≈25 m ileriye, kameranın altında ≤17 m): eski kutunun
## ≈%10'u kadraja düşüyordu. Kutu kadrajın havasını tutacak boyda, odağın 6 m ilerisinde ve 8 m yukarısındadır; nokta tavanı aynıdır.
const BOX := Vector3(50.0, 22.0, 50.0)
const BOX_AHEAD := 6.0
const BOX_UP := 8.0
## Yıldırım: şeridin göründüğü en büyük uzaklık (m), ömür (sn), bulut tabanının yüksekliği (m), kadraj dışı ayağın uzaklığı (m).
const BOLT_MAX_M := 900.0
const BOLT_LIFE := 0.35
const BOLT_BASE := 220.0
const EDGE_MAX_M := 1500.0
const BOLT_SEGMENTS := 32
const BRANCH_SEGMENTS := 8
## Ekran yağışının sarma periyodu (hücre) ve katman paralaksları.
const WRAP_CELLS := 256.0
const PARALLAX := Vector3(0.6, 1.0, 1.4)
const SCALES := Vector3(34.0, 22.0, 13.0)
const SPEED_CLASSES: Array[float] = [0.8, 0.93333, 1.06667, 1.2]
const SCREEN_LAYER := 2

const PRECIP_SHADER := preload("res://shaders/weather_precip.gdshader")
const POINT_SHADER := preload("res://shaders/weather_point.gdshader")
const BOLT_SHADER := preload("res://shaders/weather_bolt.gdshader")
const SCREEN_SHADER := preload("res://shaders/weather_screen.gdshader")
const GRADE_SHADER := preload("res://shaders/weather_grade.gdshader")

var sim: WeatherSim
var world: Node3D
## Odak (oyuncu); yoksa kameranın baktığı yer.
var focus: Node3D
var sky_rig: SkyRig
## Zemin yüksekliği (x, z) → y; barınak (x, z) → 0..1.
var ground_at: Callable
var shelter_at: Callable
## Katman alfası (W16'nın tek seçeneği 0,65).
var layer_alpha := LAYER_ALPHA
## Kesme sırası (godot.md §7.5 madde 7): parçacık yarıya, ekran yağışı bir katman azalır.
var reduced := false
## Geliştirme (--weather-debug): noktalar kırmızı ve büyük.
var debug_points := false
## Son karede yazılanlar (sınama ve bütçe).
var last_points := 0
var last_splashes := 0
var last_precip := Vector4.ZERO
var last_bolt_visible := false
var last_ground := Vector4.ZERO
var last_wind := Vector4.ZERO

var _precip_mat: ShaderMaterial
var _point_mat: ShaderMaterial
var _bolt_mat: ShaderMaterial
var _screen_mat: ShaderMaterial
var _grade_mat: ShaderMaterial
var _bolt_mesh: ArrayMesh
var _screen_layer: CanvasLayer
var _splash_img: Image
var _splash_tex: ImageTexture
var _splash_head := 0
var _splash_live := 0
var _splash_acc := 0.0
var _splash_rng := WeatherRng.new(0x5a1a5)
var _fall_off := PackedFloat64Array()
var _fall_upload := PackedVector3Array()
var _screen_off := PackedFloat64Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
var _sway_phase := 0.0
var _last_wt := NAN
var _prev_focus := Vector3.INF
var _prev_screen := Vector2.INF
var _bolt_at := -1.0
var _bolt_seen := 0
var _edge := Vector4.ZERO
var _edge_at := -1.0
var _seg := Vector4.ZERO
var _seg_at := -1.0
var _seg_seed := 0.0
var _rig_sent: Dictionary = {}
var _rig_cleared := true
var _globals_zero := true
var _bolt_rng := WeatherRng.new(0xb017)
var _warm_frames := 0
var _bolt_pts := PackedVector3Array()
var _bolt_w := PackedFloat32Array()


func _init() -> void:
	name = "WeatherView"
	process_priority = 20
	_fall_off.resize(36)
	_fall_upload.resize(12)


func _ready() -> void:
	_build()
	_set_visible(false)


## Görünümü havaya bağlar. world: dünya kökü (SkyRig'i ve araziyi oradan bulur); p_focus: oyuncu.
func bind(p_sim: WeatherSim, p_world: Node3D, p_focus: Node3D = null) -> void:
	sim = p_sim
	world = p_world
	focus = p_focus
	_find_world_services()
	_last_wt = NAN
	_prev_focus = Vector3.INF
	_bolt_seen = sim.bolt_serial if sim else 0
	# İlk yağmurda derleme takılması olmasın (weather.md §9.12 madde 4): bağlanınca iki kare her düğüm görünür ve boş çizilir.
	_warm_frames = 2


func _find_world_services() -> void:
	if world == null:
		return
	sky_rig = world.get_node_or_null(^"SkyRig") as SkyRig
	if world.has_method(&"get_terrain_shape") and not ground_at.is_valid():
		var shape: Object = world.call(&"get_terrain_shape")
		if shape and shape.has_method(&"height_at"):
			ground_at = Callable(shape, &"height_at")
	if world.has_method(&"collect_walls") and not shelter_at.is_valid():
		var walls: Array = world.call(&"collect_walls")
		shelter_at = func(x: float, z: float) -> float:
			for w: Variant in walls:
				if w and (w as RingWall).contains(Vector2(x, z)):
					return 1.0
			return 0.0


# --- Kurulum --------------------------------------------------------------------------------------------------------

func _build() -> void:
	var precip := GPUParticles3D.new()
	precip.name = "Precip"
	precip.amount = POINTS_MAX + SPLASH_MAX
	precip.lifetime = 3600.0
	precip.explosiveness = 1.0
	precip.one_shot = false
	precip.local_coords = false
	precip.fixed_fps = 0
	precip.interpolate = false
	precip.draw_order = GPUParticles3D.DRAW_ORDER_INDEX
	precip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	precip.visibility_aabb = AABB(-BOX * 0.5 - Vector3(10.0, 10.0, 10.0), BOX + Vector3(20.0, 20.0, 20.0))
	_precip_mat = ShaderMaterial.new()
	_precip_mat.shader = PRECIP_SHADER
	precip.process_material = _precip_mat
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	_point_mat = ShaderMaterial.new()
	_point_mat.shader = POINT_SHADER
	_point_mat.render_priority = 2
	quad.material = _point_mat
	precip.draw_pass_1 = quad
	_splash_img = Image.create_empty(SPLASH_MAX, 1, false, Image.FORMAT_RGBAF)
	_splash_img.fill(Color(0.0, -10000.0, 0.0, 0.0))
	_splash_tex = ImageTexture.create_from_image(_splash_img)
	_precip_mat.set_shader_parameter(&"splash_data", _splash_tex)
	_precip_mat.set_shader_parameter(&"splash_base", float(POINTS_MAX))
	_precip_mat.set_shader_parameter(&"splash_life", SPLASH_LIFE)
	_precip_mat.set_shader_parameter(&"box_size", BOX)
	_precip_mat.set_shader_parameter(&"kind_size", Vector3(0.09, 0.06, 0.05))
	add_child(precip)
	var bolt := MeshInstance3D.new()
	bolt.name = "Bolt"
	bolt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_bolt_mesh = ArrayMesh.new()
	bolt.mesh = _bolt_mesh
	_bolt_mat = ShaderMaterial.new()
	_bolt_mat.shader = BOLT_SHADER
	_bolt_mat.render_priority = 3
	bolt.material_override = _bolt_mat
	bolt.top_level = true
	add_child(bolt)
	_screen_layer = CanvasLayer.new()
	_screen_layer.name = "ScreenLayer"
	_screen_layer.layer = SCREEN_LAYER
	var grade := ColorRect.new()
	grade.name = "Grade"
	grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_grade_mat = ShaderMaterial.new()
	_grade_mat.shader = GRADE_SHADER
	grade.material = _grade_mat
	_screen_layer.add_child(grade)
	var rect := ColorRect.new()
	rect.name = "Precip"
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen_mat = ShaderMaterial.new()
	_screen_mat.shader = SCREEN_SHADER
	rect.material = _screen_mat
	_screen_layer.add_child(rect)
	add_child(_screen_layer)


func precip_node() -> GPUParticles3D:
	# Kararlı karede yakalama aracı parçacık sistemini aynı adla yenisiyle değiştirir: her kare adla bulunur.
	return get_node_or_null(^"Precip") as GPUParticles3D


func bolt_node() -> MeshInstance3D:
	return get_node_or_null(^"Bolt") as MeshInstance3D


func screen_rect() -> ColorRect:
	return _screen_layer.get_node_or_null(^"Precip") as ColorRect if _screen_layer else null


func grade_rect() -> ColorRect:
	return _screen_layer.get_node_or_null(^"Grade") as ColorRect if _screen_layer else null


func _set_visible(on: bool) -> void:
	var p := precip_node()
	if p:
		p.visible = on and last_points + last_splashes > 0
		p.emitting = true
	var b := bolt_node()
	if b:
		b.visible = on and last_bolt_visible
	var r := screen_rect()
	if r:
		r.visible = on and (last_precip != Vector4.ZERO or _edge.z > 0.0)
	var g := grade_rect()
	if g:
		g.visible = on and g.visible


# --- Kare -------------------------------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	update(delta)


## Bir kare (sınama doğrudan çağırabilir).
func update(delta: float) -> void:
	if sim == null or not sim.ready():
		_to_identity()
		return
	var k := sim.enter_k
	if k <= 0.0:
		_to_identity()
		return
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	var fpos := _focus_pos(cam)
	var dwt := 0.0 if is_nan(_last_wt) else maxf(sim.wt - _last_wt, 0.0)
	_last_wt = sim.wt
	_update_precip(k, fpos, cam, dwt)
	_update_splashes(k, fpos, cam, dwt)
	_update_screen(k, fpos, cam, delta, dwt)
	_update_bolt(k, fpos, cam)
	_update_rig(k, fpos, cam)
	_update_globals(k)
	_globals_zero = false
	_rig_cleared = false
	if _warm_frames > 0:
		_warm_frames -= 1
		_warm()


func _focus_pos(cam: Camera3D) -> Vector3:
	if focus and is_instance_valid(focus) and focus.is_inside_tree():
		return focus.global_position
	if cam:
		return cam.global_position + _cam_forward(cam) * 28.0
	return Vector3.ZERO


static func _cam_forward(cam: Camera3D) -> Vector3:
	var f := -cam.global_transform.basis.z
	f.y = 0.0
	return f.normalized() if f.length_squared() > 1e-6 else Vector3.FORWARD


func _update_precip(k: float, fpos: Vector3, cam: Camera3D, dwt: float) -> void:
	var p := sim.p
	var fx := sim.fx
	var points := p[WeatherData.P_POINTS] * k * (0.5 if reduced else 1.0)
	var n := clampi(int(points), 0, POINTS_MAX)
	last_points = n
	var node := precip_node()
	if node == null:
		return
	var snow := p[WeatherData.P_SNOW]
	var hail := p[WeatherData.P_HAIL]
	var dust := p[WeatherData.P_DUST]
	var tot := snow + hail + dust
	var frac := Vector3(1.0, 0.0, 0.0) if tot <= 0.0 else Vector3(snow, hail, dust) / tot
	var falls := WeatherLook.falls(p, fx)
	for kind in 3:
		var f: Vector3 = falls[kind]
		for c in 4:
			var i := (kind * 4 + c) * 3
			var sv := SPEED_CLASSES[c]
			_fall_off[i] = fposmod(_fall_off[i] + f.x * sv * dwt, BOX.x)
			_fall_off[i + 1] = fposmod(_fall_off[i + 1] + f.y * sv * dwt, BOX.y)
			_fall_off[i + 2] = fposmod(_fall_off[i + 2] + f.z * sv * dwt, BOX.z)
			_fall_upload[kind * 4 + c] = Vector3(_fall_off[i], _fall_off[i + 1], _fall_off[i + 2])
	_sway_phase = fposmod(_sway_phase + 1.3 * dwt, TAU)
	var ahead := _cam_forward(cam) * BOX_AHEAD if cam else Vector3.FORWARD * BOX_AHEAD
	var center := fpos + ahead + Vector3(0.0, BOX_UP, 0.0)
	node.global_position = center
	_precip_mat.set_shader_parameter(&"box_center", center)
	_precip_mat.set_shader_parameter(&"active", float(n))
	_precip_mat.set_shader_parameter(&"kind_frac", frac)
	_precip_mat.set_shader_parameter(&"fall_off", _fall_upload)
	_precip_mat.set_shader_parameter(&"sway_phase", _sway_phase)
	_precip_mat.set_shader_parameter(&"sway", 0.25 * clampf(snow * 2.0, 0.0, 1.0))
	var rain := p[WeatherData.P_RAIN]
	_point_mat.set_shader_parameter(&"wet_snow", clampf(rain / maxf(rain + snow, 1e-6), 0.0, 1.0) if snow > 0.0 else 0.0)
	_point_mat.set_shader_parameter(&"dark_snow", 1.0 if fx.type == &"kara_boran" else 0.0)
	_point_mat.set_shader_parameter(&"lit_color", _lit_color())
	_point_mat.set_shader_parameter(&"alpha_k", k)
	_point_mat.set_shader_parameter(&"debug_points", 1.0 if debug_points else 0.0)
	var far := WeatherFx.fog_far_of(WeatherLook.BASE_FOG_FAR, p)
	_point_mat.set_shader_parameter(&"fog_far", clampf(far, 40.0, 140.0))
	_point_mat.set_shader_parameter(&"fog_near", clampf(far * 0.25, 10.0, 40.0))


## Işık düzeninin rengi (ortam ve ışığın payı; yağış noktaları ve ekran çizgisi): gece kar ve yağmur söner. Işık eklenmez, okunur.
func _lit_color() -> Color:
	var env := sky_rig.environment() if sky_rig and is_instance_valid(sky_rig) else _world_env()
	var light := sky_rig.sun_light() if sky_rig and is_instance_valid(sky_rig) else null
	var amb := Color(0.5, 0.55, 0.65)
	if env:
		amb = env.ambient_light_color * env.ambient_light_energy
	var sun := Color(0.0, 0.0, 0.0)
	if light:
		sun = light.light_color * light.light_energy * 0.35
	var c := Color(amb.r + sun.r, amb.g + sun.g, amb.b + sun.b)
	return Color(clampf(c.r, 0.05, 1.2), clampf(c.g, 0.05, 1.2), clampf(c.b, 0.05, 1.2))


func _world_env() -> Environment:
	var node := world.get_node_or_null(^"WorldEnvironment") as WorldEnvironment if world else null
	return node.environment if node else null


func _update_splashes(k: float, fpos: Vector3, cam: Camera3D, dwt: float) -> void:
	var p := sim.p
	var count := int(p[WeatherData.P_SPLASHES] * k * (0.5 if reduced else 1.0))
	var hail := sim.fx.type == &"hail"
	var life := SPLASH_LIFE.y if hail else SPLASH_LIFE.x
	var now := fmod(sim.wt, 1000.0)
	if count > 0 and dwt > 0.0:
		_splash_acc += float(count) / life * dwt
		var spawn := mini(int(_splash_acc), SPLASH_PER_FRAME)
		_splash_acc -= float(spawn)
		_splash_acc = minf(_splash_acc, float(SPLASH_PER_FRAME))
		var fwd := _cam_forward(cam) if cam else Vector3.FORWARD
		var changed := false
		for i in spawn:
			# Kameraya bakan yarıya ağırlıklı daire.
			var r := SPLASH_RADIUS * sqrt(_splash_rng.next())
			var a := (_splash_rng.next() - 0.5) * PI * 1.6
			var dir := fwd.rotated(Vector3.UP, a)
			if _splash_rng.next() < 0.25:
				dir = -dir
			var x := fpos.x + dir.x * r
			var z := fpos.z + dir.z * r
			if shelter_at.is_valid() and float(shelter_at.call(x, z)) >= 0.5:
				continue
			var y := float(ground_at.call(x, z)) if ground_at.is_valid() else fpos.y
			var born := now + 1.0
			_splash_img.set_pixel(_splash_head, 0, Color(x, y + 0.03, z, -born if hail else born))
			_splash_head = (_splash_head + 1) % SPLASH_MAX
			_splash_live = mini(_splash_live + 1, SPLASH_MAX)
			changed = true
		if changed:
			_splash_tex.update(_splash_img)
	last_splashes = _splash_live if count > 0 else 0
	_precip_mat.set_shader_parameter(&"splash_count", float(_splash_live if count > 0 or _splash_live > 0 else 0))
	_precip_mat.set_shader_parameter(&"splash_now", now)
	var node := precip_node()
	if node:
		node.visible = last_points > 0 or _splash_live > 0
		if count <= 0 and dwt > 0.0:
			_splash_live = maxi(_splash_live - int(ceilf(dwt / life * float(SPLASH_MAX))), 0)


func _update_screen(k: float, fpos: Vector3, cam: Camera3D, delta: float, dwt: float) -> void:
	var p := sim.p
	var precip := Vector4(p[WeatherData.P_RAIN], p[WeatherData.P_SNOW], p[WeatherData.P_HAIL], p[WeatherData.P_DUST]) * k
	last_precip = precip
	var rect := screen_rect()
	if rect == null:
		return
	# Düşüş yönü: 3B yağış vektörünün (rüzgâr + yerçekimi) odaktaki izdüşümü; rüzgârda çizgiler yatar.
	var fx := sim.fx
	var w := Vector3(fx.dir_x, 0.0, fx.dir_z) * (fx.wind + fx.gust)
	var rain_fall := Vector3(w.x * 0.5, -8.0, w.z * 0.5)
	var dir2 := Vector2(0.0, 1.0)
	var size := get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(1920.0, 1080.0)
	if cam and precip.x + precip.z + precip.y + precip.w > 0.0:
		var weight := precip.x + precip.z
		var falls := WeatherLook.falls(p, fx)
		var f3: Vector3 = (rain_fall * weight + (falls[0] as Vector3) * precip.y + (falls[2] as Vector3) * precip.w) / maxf(weight + precip.y + precip.w, 1e-6)
		var a := cam.unproject_position(fpos)
		var b := cam.unproject_position(fpos + f3.normalized() * 2.0)
		if not cam.is_position_behind(fpos):
			var d := (b - a) / size.y
			if d.length() > 1e-5:
				dir2 = d.normalized()
	# Paralaks: odağın önceki yeri bu karede ekranda ne kadar kaydı (dünya kayınca yağmur camdaki damla gibi değil, havadaki gibi okunur).
	var shift := Vector2.ZERO
	if cam and _prev_focus != Vector3.INF and not cam.is_position_behind(_prev_focus):
		var now_s := cam.unproject_position(_prev_focus) / size.y
		if _prev_screen != Vector2.INF:
			shift = now_s - _prev_screen
	if cam and not cam.is_position_behind(fpos):
		_prev_screen = cam.unproject_position(fpos) / size.y
	_prev_focus = fpos
	if shift.length() > 0.2:
		shift = Vector2.ZERO
	var nrm := Vector2(-dir2.y, dir2.x)
	var speeds := WeatherLook.layer_speeds(precip)
	# Tipide ve Kara Boran'da kar yatay ve hızlı akar (§3.4 «1 yatay»).
	var streak := 1.0 if fx.blizzard else 0.0
	if fx.blizzard:
		speeds = speeds.lerp(Vector3(2.2, 1.5, 1.0), clampf(precip.y, 0.0, 1.0))
	for i in 3:
		var scale: float = SCALES[i]
		var sp: float = speeds[i]
		_screen_off[i * 2] = fposmod(_screen_off[i * 2] - nrm.dot(shift) * scale * PARALLAX[i], WRAP_CELLS)
		_screen_off[i * 2 + 1] = fposmod(_screen_off[i * 2 + 1] - sp * scale * dwt - dir2.dot(shift) * scale * PARALLAX[i], WRAP_CELLS)
	var aspect := size.x / maxf(size.y, 1.0)
	_screen_mat.set_shader_parameter(&"precip", precip)
	_screen_mat.set_shader_parameter(&"precip_dir", Vector4(dir2.x, dir2.y, 0.06 * clampf(precip.y * 2.0, 0.0, 1.0), 1.0 + precip.x * 0.3))
	_screen_mat.set_shader_parameter(&"precip_off0", Vector3(_screen_off[0], _screen_off[1], 0.0))
	_screen_mat.set_shader_parameter(&"precip_off1", Vector3(_screen_off[2], _screen_off[3], 17.0))
	_screen_mat.set_shader_parameter(&"precip_off2", Vector3(_screen_off[4], _screen_off[5], 31.0))
	_screen_mat.set_shader_parameter(&"precip_col", WeatherLook.precip_color(precip, _lit_color(), fx.type == &"kara_boran"))
	_screen_mat.set_shader_parameter(&"snow_streak", streak)
	_screen_mat.set_shader_parameter(&"layer_alpha", layer_alpha)
	_screen_mat.set_shader_parameter(&"aspect", aspect)
	_screen_mat.set_shader_parameter(&"layers", 2 if reduced else 3)
	# Kadraj dışı yıldırımın ayağı: 0,35 sn'de söner.
	var edge := _edge
	if _edge_at >= 0.0:
		var age := sim.wt - _edge_at
		edge.z = clampf(1.0 - age / BOLT_LIFE, 0.0, 1.0) * maxf(sim.flash_k, 0.35) * k
		if age > BOLT_LIFE:
			_edge_at = -1.0
			edge.z = 0.0
	else:
		edge.z = 0.0
	_edge = edge
	_screen_mat.set_shader_parameter(&"bolt_edge", edge)
	var seg_power := 0.0
	if _seg_at >= 0.0:
		var sage := sim.wt - _seg_at
		if sage > BOLT_LIFE:
			_seg_at = -1.0
		else:
			seg_power = clampf(1.0 - sage / BOLT_LIFE * 0.6, 0.0, 1.0) * clampf(maxf(sim.flash_k, 0.3) * 1.6, 0.0, 1.0) * k
	_screen_mat.set_shader_parameter(&"bolt_seg", _seg)
	_screen_mat.set_shader_parameter(&"bolt_seg_power", seg_power)
	_screen_mat.set_shader_parameter(&"bolt_seg_seed", _seg_seed)
	rect.visible = precip != Vector4.ZERO or edge.z > 0.0 or seg_power > 0.0
	# Derece (doygunluk, karşıtlık, ton): yalnız hava varken (ekranı okuyan geçiş kimlikte gizli).
	var g := WeatherLook.grade(p, k)
	var grect := grade_rect()
	if grect:
		var on := not WeatherLook.grade_is_identity(g)
		grect.visible = on
		if on:
			_grade_mat.set_shader_parameter(&"saturation", float(g["sat"]))
			_grade_mat.set_shader_parameter(&"contrast", float(g["con"]))
			_grade_mat.set_shader_parameter(&"tone", g["tone"])


func _update_bolt(k: float, fpos: Vector3, cam: Camera3D) -> void:
	var node := bolt_node()
	if node == null:
		return
	# Yeni inişler: son görülen id'den sonrakiler.
	for b: Dictionary in sim.bolts:
		if int(b["id"]) > _bolt_seen:
			_bolt_seen = int(b["id"])
			_start_bolt(b, fpos, cam)
	var age := sim.wt - _bolt_at
	last_bolt_visible = _bolt_at >= 0.0 and age <= BOLT_LIFE
	node.visible = last_bolt_visible
	if last_bolt_visible:
		_bolt_mat.set_shader_parameter(&"flash", clampf(maxf(sim.flash_k, 0.25) * (1.0 - age / BOLT_LIFE * 0.5), 0.0, 1.0) * k)


func _start_bolt(b: Dictionary, fpos: Vector3, cam: Camera3D) -> void:
	var x := float(b["x"])
	var z := float(b["z"])
	var d := float(b["d"])
	var gy := float(ground_at.call(x, z)) if ground_at.is_valid() else fpos.y
	var base := Vector3(x, gy, z)
	var top := Vector3(x, gy + BOLT_BASE, z)
	var in_view := cam != null and _in_view(cam, base, top)
	if debug_points:
		print("[weather] şerit (%.1f, %.1f) d %.1f kadrajda %s odak %s" % [x, z, d, in_view, fpos])
	if d <= BOLT_MAX_M and in_view:
		# Gök görünüyorsa (bulut tabanı kadrajda: alçak eğim, sinema) 3B şerit; K98'in yüksek oyun kadrajında gök görünmez, şeridin
		# yalnız dibi kadrajdadır ve boyalı süzgeç onu bulanıklaştırır: gövde son geçişte, inişin ekrandaki yerinden düşey sütunun
		# izdüşümü yönünde üst kenara keskin çizilir. İkisi birlikte çizilmez.
		if cam.is_position_in_frustum(top):
			_build_bolt(top, base, cam, d)
			_bolt_at = sim.wt
		else:
			var size := get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(1920.0, 1080.0)
			var g := cam.unproject_position(base) / size
			var up := cam.unproject_position(base + Vector3(0.0, 3.0, 0.0)) / size
			var dir := up - g
			if dir.y < -1e-5:
				var t := -g.y / dir.y
				_seg = Vector4(g.x + dir.x * t, 0.0, g.x, g.y)
				_seg_at = sim.wt
				_seg_seed = float(int(b.get("id", 0)) % 97)
	elif d <= EDGE_MAX_M and cam != null:
		_edge = _edge_of(cam, base)
		_edge_at = sim.wt


static func _in_view(cam: Camera3D, a: Vector3, b: Vector3) -> bool:
	for p: Vector3 in [a, a.lerp(b, 0.25), a.lerp(b, 0.5)]:
		if cam.is_position_in_frustum(p):
			return true
	return false


## Kadraj dışı düşüşün ekrandaki en yakın kenarı: x kenar boyunca yer (0..1), y genişlik, z güç, w kenar (0 üst, 1 sağ, 2 alt, 3 sol).
func _edge_of(cam: Camera3D, p: Vector3) -> Vector4:
	var size := get_viewport().get_visible_rect().size if is_inside_tree() else Vector2(1920.0, 1080.0)
	var center := size * 0.5
	var s := cam.unproject_position(p)
	var d := s - center
	if cam.is_position_behind(p):
		d = -d
	if d.length() < 1.0:
		d = Vector2(0.0, -1.0)
	var tx := (center.x / absf(d.x)) if absf(d.x) > 1e-4 else INF
	var ty := (center.y / absf(d.y)) if absf(d.y) > 1e-4 else INF
	var t := minf(tx, ty)
	var hit := center + d * t
	if ty <= tx:
		return Vector4(clampf(hit.x / size.x, 0.02, 0.98), 0.012, 1.0, 0.0 if d.y < 0.0 else 2.0)
	return Vector4(clampf(hit.y / size.y, 0.02, 0.98), 0.012, 1.0, 1.0 if d.x > 0.0 else 3.0)


## Şerit (weather.md §9.6): bulut tabanından iniş noktasına orta nokta kaydırmalı çizgi, 32 parçalık gövde + 2 dal (8'er); kameraya dönük
## şerit; genişlik 0,6 m (uzaklıkla ölçekli). Vuruş başına bir kez kurulur.
func _build_bolt(top: Vector3, base: Vector3, cam: Camera3D, d: float) -> void:
	_bolt_rng.reseed(WeatherRng.hash32(sim.seed, floori(sim.wt * 1000.0), 0xb017))
	_bolt_pts.resize(BOLT_SEGMENTS + 1)
	var span := top.distance_to(base)
	for i in BOLT_SEGMENTS + 1:
		_bolt_pts[i] = top.lerp(base, float(i) / BOLT_SEGMENTS)
	# Orta nokta kaydırması: kaba-ince beş düzey.
	var amp := span * 0.08
	var step := BOLT_SEGMENTS
	while step > 1:
		var half := step / 2
		var i := half
		while i < BOLT_SEGMENTS:
			var off := Vector3(_bolt_rng.span(-1.0, 1.0), 0.0, _bolt_rng.span(-1.0, 1.0)) * amp
			_bolt_pts[i] = (_bolt_pts[i - half] + _bolt_pts[mini(i + half, BOLT_SEGMENTS)]) * 0.5 + off
			i += step
		amp *= 0.55
		step = half
	var width := 0.6 + d * 0.004
	var verts := PackedVector3Array()
	var uvs := PackedVector2Array()
	var cols := PackedColorArray()
	var view := cam.global_position
	_strip(_bolt_pts, width, view, verts, uvs, cols, 1.0)
	for br in 2:
		var from_i := 8 + br * 10 + int(_bolt_rng.next() * 4.0)
		var pts := PackedVector3Array()
		pts.resize(BRANCH_SEGMENTS + 1)
		var dir := Vector3(_bolt_rng.span(-1.0, 1.0), -1.2, _bolt_rng.span(-1.0, 1.0)).normalized()
		var p := _bolt_pts[from_i]
		var len := span * 0.18 / BRANCH_SEGMENTS
		for j in BRANCH_SEGMENTS + 1:
			pts[j] = p
			p += (dir + Vector3(_bolt_rng.span(-0.5, 0.5), 0.0, _bolt_rng.span(-0.5, 0.5))) * len
		_strip(pts, width * 0.55, view, verts, uvs, cols, 0.7)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = cols
	_bolt_mesh.clear_surfaces()
	_bolt_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


static func _strip(pts: PackedVector3Array, width: float, view: Vector3, verts: PackedVector3Array, uvs: PackedVector2Array,
		cols: PackedColorArray, alpha: float) -> void:
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var t := (b - a).normalized()
		var side := t.cross((view - a).normalized()).normalized() * width * 0.5
		var u0 := float(i) / float(pts.size() - 1)
		var u1 := float(i + 1) / float(pts.size() - 1)
		var c := Color(1.0, 1.0, 1.0, alpha * (1.0 - u0 * 0.3))
		for v: Vector3 in [a - side, a + side, b + side, a - side, b + side, b - side]:
			verts.append(v)
			cols.append(c)
		uvs.append_array([Vector2(u0, 0.0), Vector2(u0, 1.0), Vector2(u1, 1.0), Vector2(u0, 0.0), Vector2(u1, 1.0), Vector2(u1, 0.0)])


func _update_rig(k: float, fpos: Vector3, cam: Camera3D) -> void:
	if sky_rig == null or not is_instance_valid(sky_rig):
		if world:
			sky_rig = world.get_node_or_null(^"SkyRig") as SkyRig
		if sky_rig == null:
			return
	var cam_dist := cam.global_position.distance_to(fpos) if cam else 28.0
	var base_fog := 0.00045
	var cs: Dictionary = sky_rig.clock_sample()
	if cs.get("fog") is Dictionary and ((cs["fog"] as Dictionary).get("density") is float or (cs["fog"] as Dictionary).get("density") is int):
		base_fog = float(cs["fog"]["density"])
	var params := WeatherLook.sky_rig_params(sim.p, k, sim.flash_k, sim.light_k, cam_dist, sim.flash_dir, base_fog)
	if not sim.gap.is_empty():
		var g: Dictionary = sim.gap
		var age := sim.wt - float(g["at"])
		if age <= float(g["seconds"]):
			var dir: Vector2 = g["dir"]
			(params["sky"] as Dictionary)["weather_gap"] = Vector4(dir.x, 0.6, dir.y, float(g["radius"]))
	if _rig_changed(params):
		_rig_sent = params
		sky_rig.set_weather(params)


## Değişti mi (gönderim yalnız fark varken; şimşek her kare)?
func _rig_changed(params: Dictionary) -> bool:
	if _rig_sent.is_empty():
		return true
	if float(params["flash"]) > 0.0 or float(_rig_sent.get("flash", 0.0)) > 0.0:
		return true
	for key: String in ["light_mul", "ambient_mul", "exposure_mul", "fog_density_mul", "volumetric_mul", "fog_color_mix"]:
		if absf(float(params.get(key, 0.0)) - float(_rig_sent.get(key, 0.0))) > 0.002:
			return true
	if params.get("shadow", true) != _rig_sent.get("shadow", true):
		return true
	var a: Dictionary = params["sky"]
	var b: Dictionary = _rig_sent["sky"]
	for key: String in ["weather_cover", "weather_dark", "weather_dust"]:
		if absf(float(a[key]) - float(b[key])) > 0.002:
			return true
	return a.has("weather_gap") != b.has("weather_gap")


func _update_globals(k: float) -> void:
	var acc := WeatherData.accumulates(sim.cfg, sim.season)
	last_ground = WeatherLook.ground(sim.fx, k, acc)
	last_wind = WeatherLook.wind(sim.fx, k)
	RenderingServer.global_shader_parameter_set(&"weather_ground", last_ground)
	RenderingServer.global_shader_parameter_set(&"weather_wind", last_wind)


## Isınma: noktalar, şerit ve ekran katmanı görünür ama boş çizilir (gölgelendiriciler derlenir; görüntüye bir şey düşmez).
func _warm() -> void:
	var p := precip_node()
	if p and not p.visible:
		p.visible = true
		p.emitting = true
	var b := bolt_node()
	if b and not b.visible:
		if _bolt_mesh.get_surface_count() == 0:
			var arrays := []
			arrays.resize(Mesh.ARRAY_MAX)
			arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([Vector3.ZERO, Vector3.ZERO, Vector3.ZERO])
			arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
			arrays[Mesh.ARRAY_COLOR] = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0), Color(1, 1, 1, 0)])
			_bolt_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		_bolt_mat.set_shader_parameter(&"flash", 0.0)
		b.visible = true
	var r := screen_rect()
	if r and not r.visible:
		r.visible = true


## Kimlik (§9.12): her şey gizli, genel tekdüzenler 0, SkyRig'in hava girdisi boş.
func _to_identity() -> void:
	last_points = 0
	last_splashes = 0
	last_precip = Vector4.ZERO
	last_bolt_visible = false
	_bolt_at = -1.0
	_edge_at = -1.0
	_edge = Vector4.ZERO
	_seg_at = -1.0
	_splash_live = 0
	_set_visible(false)
	var g := grade_rect()
	if g:
		g.visible = false
	last_ground = Vector4.ZERO
	last_wind = Vector4.ZERO
	if not _globals_zero:
		RenderingServer.global_shader_parameter_set(&"weather_ground", Vector4.ZERO)
		RenderingServer.global_shader_parameter_set(&"weather_wind", Vector4.ZERO)
		_globals_zero = true
	if not _rig_cleared:
		if sky_rig and is_instance_valid(sky_rig):
			sky_rig.clear_weather()
		_rig_sent = {}
		_rig_cleared = true


func _exit_tree() -> void:
	_to_identity()
