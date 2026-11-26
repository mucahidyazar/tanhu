class_name HudMapPage
extends Control
## Yolculuğun kitabında (duraklatma, GameMenu) «HARİTA» sayfası; M kitabı bu sayfada açar (yeniden M ya da Esc kapatır). Prototipin
## 75.000 km²'lik atlasıdır (Three.js, src/map/atlas.js; E20, K40, godot.md §4.8, site Harita): üst menünün altı kenardan kenara
## haritadır (kitap bu sayfada alt şeridini gizler). Yakınlaştıkça Bozkır Dünyası › bölge › vadi › yer diye iner:
##   atlas düzeyi   58–136°D, 23–58°K'nin boyalı kabartması (hud_atlas.gdshader ışını kabartmada yürütür: dağlar yükselir), ırmaklar,
##                  göller, çöller, ormanlar, kar; dönemin siyasi katmanı (devletler, hâkimiyetler, lekeler; AtlasPolitical), şehirler ve
##                  simgeleri, Çin Surları, Mete'nin hayatının olayları, coğrafyanın adları (öncelikle, çakışan gizlenir); iki bulut katmanı
##   gerçek düzey   görüş REAL_SPAN'in altına inince kısa bir kararmayla iç haritanın tepeden pişmiş iki görüntüsü (WorldMap: vadi ve
##                  yürünür alanın çevresi) evin (AtlasGeo.homes) üstüne yatar; vadinin adları, yerler, görevin hedefi, yürünür alan
##   sol üst   kırıntılar (tıklanınca o düzeye uçar), büyük başlık (son kırıntı), dönemin satırı
##   sağ       sırıktan sarkan kilim: DÖNEM, GÖREV (tıklayınca hedefe uçar), KATMANLAR, METE'NİN HAYATI (tıklayınca olaya uçar), YERLER
##             (gerçek düzeyde), ölçeğin notu
##   sol alt   yer kartı (ada tıklayınca: türü, adı, notu; olayda önceki ve sonraki), «Haritayı kapat [M]»
##   alt orta  pusula (döndürülmüşse tıklayınca kuzey yukarı), ölçek çubuğu (atlas km'si, gerçek düzeyde sahne metresi), «Konumum», + ve −
## Girdi (prototipinki ve E20): tekerlek, MacBook'un dokunmatik yüzeyinde iki parmakla kıstırma (InputEventMagnifyGesture) ve iki parmakla
## kaydırma (InputEventPanGesture) imlecin altına yakınlaşır ya da uzaklaşır; sol tuşla sürüklemek kaydırır (tutulan yer imlecin altında
## kalır), sağ tuşla ya da Shift'le sürüklemek döndürür, çift tık iki kat yakınlaşır; WASD ya da oklar kaydırır, + ve − yakınlaşır, Z ve
## C döndürür, Boşluk «Konumum»dur. Görüş yumuşakça hedefine akar (6,5/sn); uzaktan bakış diktir (60°), yakında yatar (46°).
## Açılış (site Harita): oyuncunun üstünde 26 birimlik görüş. Evden uzakta yakınlaşma AWAY_MIN'de durur (yol kapalı yazar); evin üstünde
## görüş kendiliğinden eve kayar (5,6 birimden), 2,9 birimin altında gerçek düzeydir.
## Bütçe (K63): 3B çizim yoktur, tek bir 2B çizim: kabartma ve siyasi katman önceden üretilmiş dokulardır, adlar ve araçlar bir katmanda.
## Harita üst menünün altını örttüğü için sayfa açıkken arkadaki dünyanın 3B çizimi kapanır (oluşturucu gibi; kapanınca geri gelir).
## Ölçüm (--map-probe, 1920 × 1080, dikey eşitleme kapalı): sayfa açıkken kare ≈5,9 ms, haritanın payı ≈1,8 ms, GDScript ≈1,7 ms.
## Veriyi kitap açılırken GameplayHud.map_page_data() verir.

## «Haritayı kapat» düğmesi (kitap kapanır).
signal close_requested

const ATLAS_SHADER := preload("res://assets/ui/hud/hud_atlas.gdshader")
const TEX_NH := "res://assets/map/atlas_nh.png"
const TEX_BIO := "res://assets/map/atlas_bio.png"
const TEX_ENV := "res://assets/map/atlas_env.png"
const TEX_RIVER := "res://assets/map/atlas_river.png"
const TEX_CLOUD := "res://assets/map/atlas_cloud.png"
const TEX_BRUSH := "res://assets/map/atlas_brush.png"
## Kamera (prototip: FOV 32°, uzaktan dik, yakında yatık; görüşün genişliği span harita birimi).
const FOV := 32.0
const PITCH_NEAR := 46.0
const PITCH_FAR := 60.0
const SPAN_NEAR := 4.0
const SPAN_FAR := 50.0
## Düzeyler (harita birimi; site Harita'nın tablosu): en uzak haritanın 1,34 katı, açılış 26, kırıntıya bölge 18, evden uzakta durak 6,
## eve kayış 5,6–3,1, gerçek düzey 2,9, kırıntıya yer 0,6; en yakın pişmiş görüntünün MAX_MAGNIFY katı büyütülmesidir.
const MAX_SPAN_K := 1.34
const OPEN_SPAN := 26.0
const REGION_SPAN := 18.0
const AWAY_MIN := 6.0
const HOME_PULL_FROM := 5.6
const HOME_PULL_TO := 3.1
const REAL_SPAN := 2.9
const SITE_SPAN := 0.6
const HOME_SPAN := 11.0
const REGION_FLY_SPAN := 13.0
const VALLEY_FLY_SPAN := 2.2
const EVENT_FLY_SPAN := 21.0
const MIN_SPAN := 0.085
const MAX_MAGNIFY := 4.0
const SMOOTH := 6.5
const WHEEL_ZOOM := 1.18
const KEY_ZOOM := 1.25
const BUTTON_ZOOM_IN := 0.62
const BUTTON_ZOOM_OUT := 1.6
## İz dörtgeni: iki parmakla kaydırmanın dikey payı başına yakınlaşma (üstel; aşağı yakınlaştırır, tekerleğin yönü) ve kıstırma.
const PAN_ZOOM := 0.12
## Klavyeyle kaydırma (görüş genişliği / sn) ve döndürme (radyan / sn); sağ tuşla döndürme (radyan / px).
const KEY_PAN := 0.8
const KEY_YAW := 1.1
const DRAG_YAW := 0.005
const DOUBLE_CLICK_MS := 500
const CLICK_SLOP := 16.0
## Düzey değişiminin kararması (prototip: 0,09 sn'de kararır, açılır).
const VEIL_RATE := 11.0
## Görüş merkezinin sola kayması (prototip: geniş ekranda kilimin dışındaki alana, en çok 150 px).
const SHIFT_MAX := 150.0
## Kilim (sağ), başlık (sol üst), araçlar (alt) ölçüleri (1080 satır).
const KILIM_W := 340.0
const KILIM_RIGHT := 30.0
const KILIM_TOP := 16.0
const KILIM_MAX_H := 860.0
const BAND_H := 30.0
const FRINGE_H := 26.0
const ROD_H := 17.0
const BUTTON_H := 40.0
const CARD_W := 400.0
## Prototipin renkleri (src/ui/style.css, woven.js).
const FELT := Color("#4b1c1a")
const FELT_DEEP := Color("#331311")
const WOOL := Color("#ecdcb9")
const WOOL_DIM := Color("#c9b48d")
const BRONZE := Color("#bb9150")
const BRONZE_LIT := Color("#e2c07f")
const INK := Color("#17100d")
const MADDER := Color("#b34a2d")
const MADDER_DEEP := Color("#8d3722")
const EDGE := Color("#2b100e")
const MOTIF := Color("#6f2523")
const HALO := Color(0.04, 0.024, 0.016, 0.8)
## Ölçek çubuğu (km; prototipin SCALE_STEPS'i) ve en uzun boyu (px). Atlasta bir birim KM_PER_UNIT km, gerçek düzeyde 1 km'dir.
const SCALE_STEPS: Array[float] = [0.005, 0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 50.0, 100.0]
const SCALE_MAX_PX := 150.0
## Katmanlar: kimlik, dizge, kilimdeki örnek. Düğmesi olmayan katman (tribes) hep açıktır.
const LAYERS: Array = [
	["states", "atlas.layer.states"], ["realms", "atlas.layer.realms"], ["cities", "atlas.layer.cities"],
	["events", "atlas.layer.events"], ["nature", "atlas.layer.nature"], ["quest", "atlas.layer.quest"],
	["area", "atlas.layer.area"], ["clouds", "atlas.layer.clouds"],
]
const PAINTED_LAYERS := ["states", "realms"]
## Adların biçimi (prototipin .al-* sınıfları; 1080 satırda biraz büyütülmüş): yazı, boy, harf aralığı, renk, büyük harf.
const LABEL_STYLE := {
	"state": ["Cinzel", 600, 3, 22, "wool", true],
	"realm": ["Cinzel", 500, 3, 14, "#f2c7a8", true],
	"tribe": ["Cinzel", 500, 1, 15, "wool", false],
	"rumour": ["Cinzel", 500, 2, 14, "wool", false],
	"seat": ["Cinzel", 600, 1, 15, "bronze", false],
	"clan": ["Alegreya-Italic", 500, 0, 17, "#f3d9a6", false],
	"city": ["Alegreya", 500, 0, 17, "wool", false],
	"event": ["Alegreya", 500, 0, 16, "ink", false],
	"range": ["Alegreya-Italic", 400, 3, 16, "#e8e2d4", false],
	"desert": ["Alegreya-Italic", 400, 4, 16, "#fbecc6", false],
	"river": ["Alegreya-Italic", 400, 0, 15, "#bfe0ee", false],
	"lake": ["Alegreya-Italic", 400, 0, 15, "#cfeaf4", false],
	"sea": ["Alegreya-Italic", 400, 4, 20, "#cfe6ee", false],
	"wall": ["Alegreya-Italic", 400, 1, 14, "#e6dcc4", false],
	"local": ["Cinzel", 500, 2, 16, "wool", true],
}

var map: WorldMap
## Oyuncunun ve görevin hedefinin dünyadaki yeri (sahne metresi; ev sahnenin (0, 0) noktasıdır).
var player_xz := Vector2.ZERO
var facing := 0.0
var target_xz := Vector2.INF
var quest_text := ""
var quest_title := ""
## Kitabın sayfası (GameMenu "embedded" yazar).
var embedded := true
## Açık katmanlar.
var layers := {"states": true, "realms": true, "cities": true, "events": true, "nature": true, "quest": true, "area": true, "clouds": true}
## Görünen dönem, açılma kuralı (Serbest Gez "camp", Çocukluk "childhood"), dilin kodu.
var era := ""
var rule := "camp"
var lang := "tr"
var geo: AtlasGeo
## Evin anahtarı (WorldMap'in anahtarı) ve harita noktası.
var home_key := "camp"
var home := Vector2.ZERO

## Görüşün o anki ve varılacak hâli: merkez (harita birimi), genişlik (birim), dönüş (radyan; 0 kuzey yukarıda).
var cx := 0.0
var cz := 0.0
var span := OPEN_SPAN
var yaw := 0.0
var cx_t := 0.0
var cz_t := 0.0
var span_t := OPEN_SPAN
var yaw_t := 0.0
## Gerçek düzeyde mi ve düzey geçişinin kararması (0..1).
var real := false
var veil := 0.0

## Adlar (prototipin items'ı; öncelik sırasıyla) ve gerçek düzeyin adları.
var items: Array = []
var locals: Array = []
## Açık dönemler (ERAS sırasıyla) ve açık olaylar (kimlik → item).
var open_eras: PackedStringArray = []
## Açık yer kartı (item ya da boş).
var card: Dictionary = {}

var _view: ColorRect
var _overlay: Control
var _mat: ShaderMaterial
var _political: AtlasPolitical
var _time := 0.0
var _player_at := Vector2.ZERO
var _target_at := Vector2.INF
var _local_rect := Rect2()
var _valley_rect := Rect2()
var _area_c := Vector2.ZERO
var _area_r := 0.04
var _region_points: Array = []
var _region_rev: Array = []
## Tıklanır yerler (her çizimde yeniden kurulur): [{rect, id}].
var _hot: Array = []
var _hover := ""
## Sürükleme: 0 yok, 1 kaydırma, 2 döndürme.
var _drag := 0
var _last := Vector2.ZERO
var _travel := 0.0
var _click_ms := -100000
var _click_at := Vector2.ZERO
## Kilimin içeriğinin istediği boy (her çizimde ölçülür).
var _kilim_h := KILIM_MAX_H
## Yol kapalı yazısının kalan süresi (sn).
var _road_note := 0.0
## Açılışta görünümün 3B çizimi kapalı mıydı (1), açık mıydı (0); -1: sayfa dokunmadı.
var _restore_3d := -1
## Son jestin anahtarı (kopyasını ayıklamak için).
## Jestin ikinci kopyası (GestureDedupe).
var _gestures := GestureDedupe.new()
## Girdi sondasının günlüğü (--map-input-probe; yoksa null).
var _input_log: Variant = null
## Mete'nin hayatı listesinin kayması (ilk görünen satır), görünen ve toplam satır.
var _life_scroll := 0
var _life_rows := 0
var _life_total := 0

static var _felt: NoiseTexture2D


## GameplayHud.map_page_data()'nın sözlüğünden kurar.
static func from_data(d: Dictionary) -> HudMapPage:
	var p := HudMapPage.new()
	p.map = d.get("map") as WorldMap
	p.player_xz = d.get("player_xz", Vector2.ZERO)
	p.facing = float(d.get("facing", 0.0))
	p.target_xz = d.get("target_xz", Vector2.INF)
	p.quest_text = str(d.get("quest_text", ""))
	p.quest_title = str(d.get("quest_title", ""))
	return p


func _ready() -> void:
	var t0 := Time.get_ticks_usec()
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	geo = AtlasGeo.shared()
	lang = SubtitleBar.ui_lang()
	home_key = map.key if map and not map.key.is_empty() else "camp"
	var hd := geo.home(home_key)
	home = geo.home_point(home_key)
	rule = str(hd.get("reveal", "camp"))
	_player_at = to_atlas(player_xz)
	_target_at = to_atlas(target_xz) if target_xz != Vector2.INF and target_xz.is_finite() else Vector2.INF
	if map:
		_local_rect = Rect2(to_atlas(map.rect.position), map.rect.size / 1000.0)
		if map.valley_texture:
			_valley_rect = Rect2(to_atlas(map.valley_rect.position), map.valley_rect.size / 1000.0)
		_area_c = to_atlas(map.area_center)
		_area_r = map.area_radius / 1000.0
	else:
		_local_rect = Rect2(_player_at - Vector2(0.094, 0.094), Vector2(0.188, 0.188))
		_area_c = _player_at
	_political = AtlasPolitical.new(geo)
	add_child(_political)
	_mat = ShaderMaterial.new()
	_mat.shader = ATLAS_SHADER
	_set_textures()
	_view = ColorRect.new()
	_view.name = "View"
	_view.material = _mat
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(_view)
	add_child(_view)
	_overlay = Overlay.new()
	_overlay.name = "Overlay"
	(_overlay as Overlay).host = self
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UIKit.full_rect(_overlay)
	add_child(_overlay)
	build_items()
	refresh_reveal(str(hd.get("era", "")))
	# Açılış (site Harita): oyuncunun üstünde, 26 birimlik görüş; kuzey yukarıda.
	cx_t = _player_at.x
	cz_t = _player_at.y
	span_t = OPEN_SPAN
	_clamp_target()
	cx = cx_t
	cz = cz_t
	span = span_t
	yaw = 0.0
	yaw_t = 0.0
	_dev_view()
	real = wants_real()
	resized.connect(_push)
	_push()
	# Harita üst menünün altını kenardan kenara örter: arkadaki dünyanın 3B çizimi boşa gider (oluşturucunun yaptığı gibi kapanır;
	# kitabın üst şeridinin bulanık zemini koyu mürekkep kalır). Sayfa kapanınca eski hâline döner.
	if embedded:
		var vp := get_viewport()
		_restore_3d = 1 if vp.disable_3d else 0
		vp.disable_3d = true
	_ready_ms = float(Time.get_ticks_usec() - t0) / 1000.0
	if OS.get_cmdline_user_args().has("--map-probe"):
		_probe.call_deferred()
	if OS.get_cmdline_user_args().has("--map-input-probe"):
		_input_probe.call_deferred()


## Geliştirme (E20): --map-input-probe gerçek girdi yolunu dener: olaylar Input.parse_input_event'le verilir (işletim sisteminin olayı
## gibi Input'tan, pencereden ve görünümden geçer). Tekerlek, iki parmakla kıstırma ve iki parmakla kaydırma sayfanın ortasında;
## her birinin önceki ve sonraki görüş genişliği yazılır.
func _input_probe() -> void:
	for i in 20:
		await get_tree().process_frame
	var at := get_global_rect().get_center()
	var cases: Array = []
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	wheel.factor = 1.0
	wheel.position = at
	wheel.global_position = at
	cases.append(["tekerlek yukarı", wheel])
	var wheel_down := wheel.duplicate() as InputEventMouseButton
	wheel_down.button_index = MOUSE_BUTTON_WHEEL_DOWN
	cases.append(["tekerlek aşağı", wheel_down])
	var pinch := InputEventMagnifyGesture.new()
	pinch.position = at
	pinch.factor = 1.5
	cases.append(["kıstırma (açılış)", pinch])
	var pan := InputEventPanGesture.new()
	pan.position = at
	pan.delta = Vector2(0.0, 3.0)
	cases.append(["iki parmak yukarı", pan])
	var pan2 := InputEventPanGesture.new()
	pan2.position = at
	pan2.delta = Vector2(0.0, -3.0)
	cases.append(["iki parmak aşağı", pan2])
	_input_log = []
	for c: Array in cases:
		var before := span_t
		_input_log.clear()
		Input.parse_input_event(c[1])
		await get_tree().process_frame
		await get_tree().process_frame
		print("[atlas-input] %s: %.3f → %.3f birim · %s" % [c[0], before, span_t, ", ".join(_input_log)])
	_input_log = null


func _exit_tree() -> void:
	if _restore_3d >= 0:
		get_viewport().disable_3d = _restore_3d == 1
		_restore_3d = -1


## Geliştirme (bütçe, K63): --map-probe haritanın bedelini ölçer. 120 kare harita açıkken, 120 kare görüntü ve katman gizliyken
## (kitap, dünya ve öteki her şey aynı) görünümün GPU süresi ve sayfanın kare başına GDScript süresi; fark haritanın bedelidir.
func _probe() -> void:
	var rid := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	for i in 30:
		await get_tree().process_frame
	var on := await _probe_frames(rid, 120)
	_view.visible = false
	_overlay.visible = false
	for i in 10:
		await get_tree().process_frame
	var off := await _probe_frames(rid, 120)
	_view.visible = true
	_overlay.visible = true
	# GPU süresi Metal'de okunmaz (0): o zaman kare farkı haritanın bedelidir (--disable-vsync ile anlamlı).
	var gpu := "gpu %.2f ms, " % on[0] if on[0] > 0.0 else ""
	print("[atlas-probe] %s, %d px · kurulum %.1f ms · açık: kare %.2f ms (%%95 %.2f), %ssayfanın GDScript'i %.3f ms · kapalı: kare %.2f ms (%%95 %.2f) · fark %.2f ms · ana 3B çizimi %s"
		% ["gerçek düzey" if real else "atlas", int(size.x), _ready_ms, on[2], on[3], gpu, on[4], off[2], off[3], on[2] - off[2], "kapalı" if get_viewport().disable_3d else "açık"])
## Katmanın son çiziminin ve sayfanın kurulumunun süresi (ms; ölçüm için).
var _draw_ms := 0.0
var _ready_ms := 0.0


## [gpu ort., gpu %95, kare ort. (ms), kare %95 (ms), sayfanın GDScript'i (ms; _push ve katmanın çizimi)].
func _probe_frames(rid: RID, n: int) -> Array:
	var gpu := PackedFloat32Array()
	var frames := PackedFloat32Array()
	var cpu := 0.0
	var last := Time.get_ticks_usec()
	for i in n:
		var a := Time.get_ticks_usec()
		_push()
		_overlay.queue_redraw()
		cpu += float(Time.get_ticks_usec() - a)
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		frames.append(float(now - last) / 1000.0)
		last = now
		cpu += _draw_ms * 1000.0 if _overlay.visible else 0.0
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(rid))
	var gs := gpu.duplicate()
	gs.sort()
	var fs := frames.duplicate()
	fs.sort()
	var gsum := 0.0
	for g in gpu:
		gsum += g
	var fsum := 0.0
	for f in frames:
		fsum += f
	return [gsum / n, gs[int(n * 0.95)], fsum / n, fs[int(n * 0.95)], cpu / n / 1000.0]


## Dünyadaki nokta (sahne metresi) → harita birimi: ev sahnenin (0, 0) noktasıdır, 1.000 m bir birimdir.
func to_atlas(xz: Vector2) -> Vector2:
	return home + xz / 1000.0


func _set_textures() -> void:
	for pair: Array in [[&"t_nh", TEX_NH], [&"t_bio", TEX_BIO], [&"t_env", TEX_ENV], [&"t_river", TEX_RIVER], [&"t_cloud", TEX_CLOUD], [&"t_brush", TEX_BRUSH]]:
		var tex: Texture2D = load(pair[1]) if ResourceLoader.exists(pair[1]) else null
		if tex:
			_mat.set_shader_parameter(pair[0], tex)
	_mat.set_shader_parameter(&"t_fill", _political.fill_texture)
	_mat.set_shader_parameter(&"t_line", _political.line_texture)
	_mat.set_shader_parameter(&"political_on", 1.0)
	_mat.set_shader_parameter(&"map_size", Vector2(geo.map_w, geo.map_d))
	_mat.set_shader_parameter(&"hmax", AtlasGeo.HMAX)
	_mat.set_shader_parameter(&"sun_dir", geo.sun)
	_mat.set_shader_parameter(&"home_pos", home)
	var local_tex: Texture2D = map.texture if map and map.texture else WorldMap.fallback_texture()
	_mat.set_shader_parameter(&"t_local", local_tex)
	_mat.set_shader_parameter(&"local_rect", Vector4(_local_rect.position.x, _local_rect.position.y, _local_rect.size.x, _local_rect.size.y))
	if map:
		_mat.set_shader_parameter(&"local_tone", Vector3(map.exposure, map.contrast, 0.5))
		_mat.set_shader_parameter(&"local_pivot", Vector3(map.pivot.r, map.pivot.g, map.pivot.b))
	if map and map.valley_texture:
		_mat.set_shader_parameter(&"t_valley", map.valley_texture)
		_mat.set_shader_parameter(&"valley_rect", Vector4(_valley_rect.position.x, _valley_rect.position.y, _valley_rect.size.x, _valley_rect.size.y))
		_mat.set_shader_parameter(&"valley_tone", Vector3(map.valley_exposure, map.valley_contrast, 0.5))
		_mat.set_shader_parameter(&"valley_pivot", Vector3(map.valley_pivot.r, map.valley_pivot.g, map.valley_pivot.b))
	else:
		_mat.set_shader_parameter(&"valley_rect", Vector4.ZERO)
	_mat.set_shader_parameter(&"area_center", _area_c)
	_mat.set_shader_parameter(&"area_radius", _area_r)


## Geliştirme (belge karesi): --map-view=yer[,genişlik[,dönüş_derece]] görüşü kurar. yer: "oyuncu", "dünya", evin anahtarı (camp, ordos),
## yerel yerin adı ya da "boylam:enlem"; genişlik harita birimidir. --map-reveal=all bütün satırları açar (siyasi haritanın bütün
## dönemleri; yalnız kare için), --map-era=dönem dönemi seçer. Argüman yoksa bir şey yapmaz.
func _dev_view() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--map-reveal="):
			rule = a.substr(13)
			refresh_reveal(era)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--map-era="):
			set_era(a.substr(10))
		if not a.begins_with("--map-view="):
			continue
		var parts := a.substr(11).split(",")
		var at := _player_at
		var what := parts[0]
		if what == "dünya" or what == "world":
			at = Vector2.ZERO
		elif geo.homes.has(what):
			at = geo.home_point(what)
		elif what.contains(":"):
			var ll := what.split(":")
			at = geo.to_map(float(ll[0]), float(ll[1]))
		elif map:
			for p: Dictionary in map.places:
				if str(p["name"]) == what:
					at = to_atlas(p["at"])
		var s := float(parts[1]) if parts.size() > 1 and parts[1].is_valid_float() else span_t
		cx_t = at.x
		cz_t = at.y
		span_t = clamp_span(s)
		if parts.size() > 2 and parts[2].is_valid_float():
			yaw_t = deg_to_rad(float(parts[2]))
		_clamp_target()
		cx = cx_t
		cz = cz_t
		span = span_t
		yaw = yaw_t


# --- Kamera (saf) --------------------------------------------------------------------------------------------

## Görüşün genişliğine göre kameranın yerden yükselişi (radyan): uzaktan diktir, yakında yatar (prototipin pitch'i).
static func pitch_for(s: float) -> float:
	var k := smoothstep(log(SPAN_NEAR), log(SPAN_FAR), log(maxf(s, 0.001)))
	return deg_to_rad(lerpf(PITCH_NEAR, PITCH_FAR, k))


## Kamera (saf): merkez (harita birimi; y bakılan yükseklik), görüşün genişliği, dönüş ve sayfanın boyu → {pos, f, r, u, tan_h, tan_v,
## d}. Dönüş 0'da kamera merkezin güneyindedir, kuzeye (-z) ve aşağı bakar: ekranın yukarısı kuzey, sağı doğu.
static func camera_for(center: Vector2, s: float, p_yaw: float, view: Vector2, look_y := 0.0) -> Dictionary:
	var tan_v := tan(deg_to_rad(FOV) * 0.5)
	var tan_h := tan_v * view.x / maxf(view.y, 1.0)
	var d := s / (2.0 * tan_h)
	var p := pitch_for(s)
	var target := Vector3(center.x, look_y, center.y)
	var pos := target + Vector3(sin(p_yaw) * cos(p) * d, sin(p) * d, cos(p_yaw) * cos(p) * d)
	var f := (target - pos).normalized()
	var r := f.cross(Vector3.UP).normalized()
	var u := r.cross(f)
	return {"pos": pos, "f": f, "r": r, "u": u, "tan_h": tan_h, "tan_v": tan_v, "d": d, "look_y": look_y}


## Ekrandaki noktanın altındaki yer (saf; harita birimi): ışın kameranın bakış yüksekliğindeki düzlemle kesişir (prototipin
## groundUnder'ı). Işın yere inmiyorsa Vector2.INF.
static func ground_at(cam: Dictionary, screen: Vector2, view: Vector2, shift: float) -> Vector2:
	var nx := (screen.x + shift) / view.x * 2.0 - 1.0
	var ny := 1.0 - screen.y / view.y * 2.0
	var dir: Vector3 = ((cam["f"] as Vector3) + (cam["r"] as Vector3) * nx * float(cam["tan_h"]) + (cam["u"] as Vector3) * ny * float(cam["tan_v"])).normalized()
	if dir.y > -0.0005:
		return Vector2.INF
	var pos: Vector3 = cam["pos"]
	var hit := pos + dir * ((float(cam.get("look_y", 0.0)) - pos.y) / dir.y)
	return Vector2(hit.x, hit.z)


## Noktanın ekrandaki yeri (saf): (x, y, derinlik); derinlik ≤ 0 kameranın arkasıdır. Yerdeki nokta (Vector2) bakış yüksekliğindedir.
static func project(cam: Dictionary, at: Variant, view: Vector2, shift: float) -> Vector3:
	var p3: Vector3 = at if at is Vector3 else Vector3((at as Vector2).x, float(cam.get("look_y", 0.0)), (at as Vector2).y)
	var v := p3 - (cam["pos"] as Vector3)
	var zc := v.dot(cam["f"])
	if zc <= 0.0001:
		return Vector3(0.0, 0.0, -1.0)
	var nx := v.dot(cam["r"]) / (zc * float(cam["tan_h"]))
	var ny := v.dot(cam["u"]) / (zc * float(cam["tan_v"]))
	return Vector3((nx + 1.0) * 0.5 * view.x - shift, (1.0 - ny) * 0.5 * view.y, zc)


## Görüş merkezinin sola kayması (px; prototip: genişliğin onda biri, en çok 150).
func view_shift() -> float:
	return minf(size.x * 0.1, SHIFT_MAX) if size.x > 860.0 else 0.0


## O anki kamera: atlas düzeyinde merkezdeki kabartmanın yarı yüksekliğine, gerçek düzeyde yere bakar.
func camera() -> Dictionary:
	return camera_for(Vector2(cx, cz), span, yaw, _view_size(), look_height(Vector2(cx, cz)))


func look_height(at: Vector2) -> float:
	return 0.0 if real else geo.height_at(at) * 0.5


func _view_size() -> Vector2:
	return Vector2(maxf(size.x, 64.0), maxf(size.y, 64.0))


## Harita noktasının sayfadaki yeri (o anki görüşle; arkadaysa Vector2.INF). y verilmezse yerin (atlasta kabartmanın) üstü.
func to_page(at: Vector2, lift := 0.0) -> Vector2:
	var y := (0.0 if real else geo.height_at(at)) + lift
	var p := project(camera(), Vector3(at.x, y, at.y), _view_size(), view_shift())
	return Vector2(p.x, p.y) if p.z > 0.0 else Vector2.INF


func player_point() -> Vector2:
	return to_page(_player_at)


## Görüşün en geniş hâli (haritanın 1,34 katı).
func max_span() -> float:
	return geo.map_w * MAX_SPAN_K


## Görüşün en dar hâli: yürünür alanın pişmiş görüntüsü en çok MAX_MAGNIFY kat büyür (daha yakında bulanıklaşır); yedekte prototipin 0,085'i.
func min_span() -> float:
	if map and map.baked and map.texture and _local_rect.size.x > 0.0:
		var px_per_unit := float(map.texture.get_width()) / _local_rect.size.x
		return clampf(_view_size().x / (px_per_unit * MAX_MAGNIFY), 0.02, MIN_SPAN)
	return MIN_SPAN


## Varılacak görüş evin üstünde mi (prototipin nearHome'u): gerçek düzeye yalnız evin üstünde inilir.
func near_home() -> bool:
	return Vector2(cx_t, cz_t).distance_to(home) < maxf(2.6, span_t * 0.55)


## Genişliğin sınırı: evin üstünde en yakına dek, uzakta AWAY_MIN'de durur (yol yok), en uzakta haritanın tamamı.
func clamp_span(s: float) -> float:
	return clampf(s, min_span() if near_home() else AWAY_MIN, max_span())


func wants_real() -> bool:
	return span < REAL_SPAN


# --- Görüşü sürmek ------------------------------------------------------------------------------------------------

## Görüşü bir yere uçurur (span verilmezse genişlik aynı kalır).
func fly_to(at: Vector2, p_span := -1.0) -> void:
	cx_t = at.x
	cz_t = at.y
	if p_span > 0.0:
		span_t = clamp_span(p_span)
	_clamp_target()


## «Konumum» (prototip): oyuncunun üstüne, 11 birimlik görüşe.
func fly_home() -> void:
	fly_to(_player_at, HOME_SPAN)


## Genişliği f katına getirir; at verilirse (sayfadaki nokta) o noktanın altındaki yer yerinde kalır. Evden uzakta durağa çarpınca
## yol kapalı yazar.
func zoom_by(f: float, at := Vector2.INF) -> void:
	var before := span_t
	span_t = clamp_span(span_t * f)
	if f < 1.0 and is_equal_approx(span_t, AWAY_MIN) and not near_home():
		_road_note = 2.2
	var k := span_t / before
	if at != Vector2.INF and not is_equal_approx(k, 1.0):
		var g := ground_at(camera(), at, _view_size(), view_shift())
		if g != Vector2.INF:
			cx_t = g.x + (cx_t - g.x) * k
			cz_t = g.y + (cz_t - g.y) * k
	_clamp_target()


## Ekrandaki kaymayı (px) yere taşır: tutulan yer imlecin altında kalır.
func pan_screen(from: Vector2, to: Vector2) -> void:
	var cam := camera()
	var a := ground_at(cam, from, _view_size(), view_shift())
	var b := ground_at(cam, to, _view_size(), view_shift())
	if a == Vector2.INF or b == Vector2.INF:
		return
	var d := a - b
	cx += d.x
	cz += d.y
	cx_t += d.x
	cz_t += d.y
	_clamp_target()


## Kuzeyi yukarı alır (pusula).
func north_up() -> void:
	yaw = wrapf(yaw, -PI, PI)
	yaw_t = 0.0


## Görüşün sınırı (prototipin clampTarget'ı): gerçek düzeyde evin çevresi (yakında yürünür alanın görüntüsü, uzakta vadi), atlasta harita.
func _clamp_target() -> void:
	var s := span_t
	if s < REAL_SPAN:
		var half := (_local_rect.size.x * 0.5 if s < SITE_SPAN else maxf(_valley_rect.size.x * 0.3, 0.3)) if map else 1.42
		var m := maxf(0.0, half - s * 0.32)
		var c := _local_rect.get_center() if s < SITE_SPAN and map else home
		cx_t = clampf(cx_t, c.x - m, c.x + m)
		cz_t = clampf(cz_t, c.y - m, c.y + m)
	else:
		var mx := maxf(0.0, geo.map_w * 0.5 - s * 0.32)
		var mz := maxf(0.0, geo.map_d * 0.5 - s * 0.16)
		cx_t = clampf(cx_t, -mx, mx)
		cz_t = clampf(cz_t, -mz, mz)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	_road_note = maxf(0.0, _road_note - delta)
	var ax := Input.get_axis(&"move_left", &"move_right") if InputMap.has_action(&"move_left") else 0.0
	var az := Input.get_axis(&"move_forward", &"move_back") if InputMap.has_action(&"move_forward") else 0.0
	if absf(ax) > 0.01 or absf(az) > 0.01:
		var step := Vector2(ax, az).limit_length(1.0) * span_t * KEY_PAN * delta
		var turned := step.rotated(-yaw)
		cx_t += turned.x
		cz_t += turned.y
		_clamp_target()
	var spin := float(Input.is_physical_key_pressed(KEY_C)) - float(Input.is_physical_key_pressed(KEY_Z))
	if spin != 0.0:
		yaw_t += spin * KEY_YAW * delta
	step_view(delta)
	_push()


## Görüşü bir kare ilerletir (saf değil ama girdisiz): eve kayış, sınırlar, yumuşak akış, düzey geçişinin kararması.
func step_view(delta: float) -> void:
	# Eve inerken görüş eve yönelir.
	if span_t < HOME_PULL_FROM and span_t >= REAL_SPAN:
		var m := smoothstep(HOME_PULL_FROM, HOME_PULL_TO, span_t) * minf(1.0, delta * 3.4)
		cx_t += (home.x - cx_t) * m
		cz_t += (home.y - cz_t) * m
	span_t = clamp_span(span_t)
	_clamp_target()
	var f := 1.0 - exp(-delta * SMOOTH)
	cx = lerpf(cx, cx_t, f)
	cz = lerpf(cz, cz_t, f)
	span = exp(lerpf(log(span), log(span_t), f))
	yaw = lerpf(yaw, yaw_t, f)
	# Düzey değişimi: kısa bir kararmayla gerçek düzeye geçer (ya da döner).
	var want := wants_real()
	var veil_target := 1.0 if want != real else 0.0
	veil = move_toward(veil, veil_target, delta * VEIL_RATE)
	if veil >= 1.0 and want != real:
		real = want


## Gölgelendiriciye o anki kamerayı ve payları yazar, katmanı yeniden çizdirir.
func _push() -> void:
	if _mat == null:
		return
	var view := _view_size()
	var cam := camera()
	var s := span
	_mat.set_shader_parameter(&"cam_pos", cam["pos"])
	_mat.set_shader_parameter(&"cam_f", cam["f"])
	_mat.set_shader_parameter(&"cam_r", cam["r"])
	_mat.set_shader_parameter(&"cam_u", cam["u"])
	_mat.set_shader_parameter(&"tan_h", cam["tan_h"])
	_mat.set_shader_parameter(&"tan_v", cam["tan_v"])
	_mat.set_shader_parameter(&"shift_ndc", view_shift() / view.x * 2.0)
	_mat.set_shader_parameter(&"span", s)
	_mat.set_shader_parameter(&"time_s", _time)
	_mat.set_shader_parameter(&"real_on", 1.0 if real else 0.0)
	_mat.set_shader_parameter(&"veil", veil)
	# Yakınlaştıkça siyasi renk çekilir, arazi öne çıkar; bulutlar kamera altına inmeden açılır (prototipin updateAtmosphere'i).
	_mat.set_shader_parameter(&"fill_amt", lerpf(0.42, 1.0, smoothstep(7.0, 26.0, s)))
	_mat.set_shader_parameter(&"line_amt", lerpf(0.72, 1.0, smoothstep(7.0, 26.0, s)))
	_mat.set_shader_parameter(&"near_amt", smoothstep(14.0, 4.5, s))
	var cloud := smoothstep(4.5, 15.0, s)
	_mat.set_shader_parameter(&"cloud_amt", lerpf(0.5, 1.0, cloud))
	_mat.set_shader_parameter(&"sky_amt", cloud)
	_mat.set_shader_parameter(&"sky_hi_on", 1.0 if s > 11.0 else 0.0)
	_mat.set_shader_parameter(&"real_cloud_amt", smoothstep(0.7, 2.0, s) * 0.86)
	_mat.set_shader_parameter(&"view_dist", s / (2.0 * tan(deg_to_rad(FOV) * 0.5) * (view.x / view.y)) * 2.6)
	_mat.set_shader_parameter(&"tree_k", smoothstep(26.0, 13.0, s))
	_mat.set_shader_parameter(&"clouds_on", 1.0 if layers["clouds"] else 0.0)
	_mat.set_shader_parameter(&"area_on", 1.0 if layers["area"] else 0.0)
	if _overlay:
		_overlay.queue_redraw()


# --- Açılma, dönemler, adlar -----------------------------------------------------------------------------------------------

## Adların listesi (prototipin buildItems'ı): devletler, yurtlar, kanatlar, şehirler, olaylar, coğrafya, surlar; öncelik sırasıyla.
func build_items() -> void:
	items.clear()
	for p: Dictionary in geo.rows("polities"):
		var rank := int(p.get("rank", 5))
		var big := rank >= 9
		var tribe := str(p.get("layer", "")) == "tribes"
		var style := str(p.get("style", "state"))
		var mn := 8.0 if big else ((4.5 if rank >= 6 else 3.6) if tribe else 5.0)
		var mx := 999.0 if style == "realm" or big else (56.0 if rank >= 7 else (46.0 if rank >= 6 else 34.0))
		var eras: Array = (p.get("eras", []) as Array).duplicate()
		var rumour: Variant = p.get("rumour")
		if rumour is Dictionary:
			eras = eras.filter(func(e: Variant) -> bool: return not ((rumour as Dictionary).get("eras", []) as Array).has(e))
		_add_item({"type": "realm" if style == "realm" else ("tribe" if tribe else "state"), "row": p, "table": "polities",
			"layer": str(p.get("layer", "")), "eras": eras, "at": geo.at_of(p["at"]), "min": mn, "max": mx, "pri": 60 + rank * 4,
			"color": str(p.get("color", "")), "icon": "tents" if tribe else ""})
		if rumour is Dictionary:
			_add_item({"type": "rumour", "row": p, "table": "polities", "layer": str(p.get("layer", "")),
				"eras": (rumour as Dictionary).get("eras", []), "at": geo.at_of((rumour as Dictionary)["at"]), "min": mn, "max": mx,
				"pri": 50 + rank * 4, "color": str(p.get("color", ""))})
	for c: Dictionary in geo.rows("clans"):
		var is_clan := str(c.get("layer", "")) == "clans"
		_add_item({"type": "clan" if is_clan else "seat", "row": c, "table": "clans", "layer": str(c.get("layer", "")), "eras": c.get("eras", []),
			"at": geo.at_of(c["at"]), "icon": str(c.get("icon", "")), "min": 2.6, "max": 15.0 if is_clan else 34.0, "pri": 42 + int(c.get("rank", 5)) * 4})
	for c: Dictionary in geo.rows("cities"):
		var rank := int(c.get("rank", 5))
		var mx := 999.0 if rank >= 9 else (34.0 if rank >= 7 else (22.0 if rank >= 5 else 14.0))
		var icon: Variant = c.get("icon")
		_add_item({"type": "city", "row": c, "table": "cities", "layer": "cities", "eras": c.get("eras", []), "at": geo.at_of(c["at"]),
			"icon": str(icon) if icon != null else "", "min": 2.6, "max": mx, "pri": 34 + rank * 4})
	var events := geo.rows("events")
	for i in events.size():
		var e: Dictionary = events[i]
		_add_item({"type": "event", "row": e, "table": "events", "layer": "events", "eras": [str(e.get("era", ""))], "at": geo.at_of(e["at"]),
			"icon": "flag", "min": 2.6, "max": 999.0, "pri": 90, "event": i})
	for pair: Array in [["range", "ranges"], ["range", "plateaus"], ["desert", "deserts"], ["lake", "lakes"], ["river", "rivers"], ["sea", "seas"]]:
		for n: Dictionary in geo.rows(pair[1]):
			if not n.has("at") or geo.row_text(pair[1], n, "name", lang).is_empty():
				continue
			var big := bool(n.get("big", false))
			_add_item({"type": pair[0], "row": n, "table": pair[1], "kind_key": "atlas.kind." + str(pair[0]), "layer": "nature",
				"at": geo.at_of(n["at"]), "min": 2.6, "max": 999.0 if big else 26.0, "pri": 22 if big else 8})
	# Çin Surları Meng Tian'ın birleştirdiği surlardır (MÖ 215 sonrası): Çocukluk'un MÖ 228'inde çizilmez.
	var wall_eras: Array = []
	for e: Dictionary in geo.rows("eras"):
		if str(e["id"]) != "228":
			wall_eras.append(str(e["id"]))
	_add_item({"type": "wall", "keys": {"name": "atlas.wall.name", "kind": "atlas.wall.kind", "note": "atlas.wall.note"}, "layer": "states",
		"at": geo.to_map(111.2, 41.9), "min": 4.0, "max": 60.0, "pri": 34, "eras": wall_eras})
	items.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["pri"]) > int(b["pri"]))
	for i in items.size():
		items[i]["index"] = i
	_build_locals()
	_region_points.clear()
	for r: Dictionary in geo.rows("regions"):
		_region_points.append(geo.at_of(r["at"]))


func _add_item(o: Dictionary) -> void:
	var it := {"row": {}, "table": "", "eras": null, "name": "", "sub": "", "kind": "", "note": "", "icon": "", "rev": true, "color": ""}
	it.merge(o, true)
	var at: Vector2 = it["at"]
	it["y"] = geo.height_at(at)
	if not (it["row"] as Dictionary).is_empty():
		var event := str(it["type"]) == "event"
		var table := str(it["table"])
		it["name"] = geo.row_text(table, it["row"], "name", lang)
		it["sub"] = geo.row_text(table, it["row"], "year" if event else "sub", lang)
		it["note"] = geo.row_text(table, it["row"], "note", lang)
		it["kind"] = str(it["sub"]) if event else (geo.text(str(it["kind_key"]), lang) if it.has("kind_key") else "")
	if it.has("keys"):
		for field: String in (it["keys"] as Dictionary):
			it[field] = geo.text(str(it["keys"][field]), lang)
	items.append(it)


## Gerçek düzeyin adları: evin vadisindeki sabit adlar (homes.*.names) ve yürünür alanın yerleri (WorldMap.places).
func _build_locals() -> void:
	locals.clear()
	for n: Array in (geo.home(home_key).get("names", []) as Array):
		locals.append({"name": geo.text(str(n[0]), lang), "at": to_atlas(Vector2(float(n[1]), float(n[2]))), "min": float(n[3]),
			"max": float(n[4]), "type": str(n[5])})
	if map:
		for p: Dictionary in map.places:
			locals.append({"name": str(p["name"]), "at": to_atlas(p["at"]), "min": 0.0, "max": 0.75, "type": "local", "place": true})


## Açılma kuralını okur (prototipin refreshReveal'ı): adlar, dönemler, bölgeler; siyasi katmanı boyar. want_era: açılışta seçilen dönem.
func refresh_reveal(want_era := "") -> void:
	for it: Dictionary in items:
		it["rev"] = (it["row"] as Dictionary).is_empty() or AtlasGeo.revealed(rule, it["row"])
	_region_rev.clear()
	for r: Dictionary in geo.rows("regions"):
		_region_rev.append(AtlasGeo.revealed(rule, r))
	open_eras = PackedStringArray()
	for e: Dictionary in geo.rows("eras"):
		var id := str(e["id"])
		if not AtlasGeo.revealed(rule, e):
			continue
		var has_row := false
		for it: Dictionary in items:
			if bool(it["rev"]) and it["eras"] is Array and (it["eras"] as Array).has(id):
				has_row = true
				break
		if has_row or id == want_era:
			open_eras.append(id)
	if not want_era.is_empty() and open_eras.has(want_era):
		era = want_era
	elif not open_eras.has(era):
		era = open_eras[0] if not open_eras.is_empty() else ""
	_paint()


func _paint(force := false) -> void:
	if _political and not era.is_empty():
		_political.paint(era, layers, func(p: Dictionary) -> bool: return AtlasGeo.revealed(rule, p), force)


## Dönemi seçer (kilimin DÖNEM düğmeleri): siyasi katman o dönemin olur.
func set_era(id: String) -> void:
	if id == era or not open_eras.has(id):
		return
	era = id
	_paint()
	if not card.is_empty() and not item_on(card, true):
		card = {}


func set_layer(k: String, on: bool) -> void:
	if bool(layers.get(k, true)) == on:
		return
	layers[k] = on
	if k in PAINTED_LAYERS:
		_paint(true)
	_push()


## Ad görünür mü (prototipin itemOn'u): açılmış, dönemi ve katmanı açık, yakınlık aralığında. any_span: yakınlığa bakmadan.
func item_on(it: Dictionary, any_span := false) -> bool:
	if not bool(it["rev"]):
		return false
	if it["eras"] is Array and not (it["eras"] as Array).is_empty() and not (it["eras"] as Array).has(era):
		return false
	if not str(it.get("layer", "")).is_empty() and layers.get(str(it["layer"]), true) == false:
		return false
	return any_span or (span >= float(it["min"]) and span <= float(it["max"]))


## Olay açık mı: satırı açılmış ve dönemi açık.
func event_open(i: int) -> bool:
	for it: Dictionary in items:
		if int(it.get("event", -1)) == i:
			return bool(it["rev"]) and open_eras.has(str((it["row"] as Dictionary).get("era", "")))
	return false


func _event_item(i: int) -> Dictionary:
	for it: Dictionary in items:
		if int(it.get("event", -1)) == i:
			return it
	return {}


## Kartın önceki ve sonraki olayı: açılmamış olay atlanır; yoksa -1.
func step_event(i: int, dir: int) -> int:
	var n := geo.rows("events").size()
	var j := i + dir
	while j >= 0 and j < n:
		if event_open(j):
			return j
		j += dir
	return -1


## Olaya gider: dönemi ve olay katmanını açar, kartını gösterir.
func open_event(i: int) -> void:
	if i < 0 or not event_open(i):
		return
	var it := _event_item(i)
	set_era(str((it["row"] as Dictionary).get("era", era)))
	set_layer("events", true)
	fly_to(it["at"], EVENT_FLY_SPAN)
	card = it


# --- Kırıntılar ----------------------------------------------------------------------------------------------------------

## Görüşün bölgesi (açılmamış bölgenin adı yoktur: -1). Evin üstünde evin bölgesi.
func nearest_region() -> int:
	var at := home if (near_home() and span < 12.0) else Vector2(cx, cz)
	var best := -1
	var bd := INF
	for i in _region_points.size():
		var d := (_region_points[i] as Vector2).distance_to(at)
		if d < bd:
			bd = d
			best = i
	return best if best >= 0 and best < _region_rev.size() and bool(_region_rev[best]) else -1


## Kırıntı yolu (kimlikler): world › region › valley › site.
func crumb_ids() -> PackedStringArray:
	var out := PackedStringArray(["world"])
	if span < REGION_SPAN and nearest_region() >= 0:
		out.append("region")
	if real:
		out.append("valley")
		if span < SITE_SPAN:
			out.append("site")
	return out


func crumb_text(id: String) -> String:
	match id:
		"world":
			return geo.text("atlas.crumb.world", lang)
		"region":
			var r := nearest_region()
			return geo.row_text("regions", geo.rows("regions")[r], "name", lang) if r >= 0 else ""
		"valley":
			return geo.text(str(geo.home(home_key).get("valley", "atlas.crumb.valley")), lang)
		"site":
			return site_name()
	return ""


## Yerin adı (kırıntının ucu, «Buradasın»ın altı): dünyanın haritasının adı.
func site_name() -> String:
	if map and not map.title.is_empty():
		return map.title
	return geo.text("atlas.crumb.camp", lang)


## Kırıntılar (metin).
func crumbs() -> PackedStringArray:
	var out := PackedStringArray()
	for id in crumb_ids():
		out.append(crumb_text(id))
	return out


func fly_to_crumb(id: String) -> void:
	match id:
		"world":
			fly_to(Vector2.ZERO, max_span())
		"region":
			var r := nearest_region()
			if r >= 0:
				fly_to(_region_points[r], REGION_FLY_SPAN)
		"valley":
			fly_to(home, VALLEY_FLY_SPAN)
		"site":
			fly_to(_area_c, clampf(_area_r * 4.5, min_span(), SITE_SPAN * 0.9))


## Ölçek çubuğu (saf): görüşün genişliği, bir birimin km'si ve sayfanın genişliği → [km, px].
static func scale_bar(p_span: float, km_per_unit: float, view_w: float) -> Array:
	var px_per_km := view_w / maxf(p_span * km_per_unit, 0.000001)
	var best := SCALE_STEPS[0]
	for s: float in SCALE_STEPS:
		if s * px_per_km < SCALE_MAX_PX:
			best = s
	return [best, best * px_per_km]


## Sayının Türkçe ya da İngilizce yazımı (binler, ondalık).
static func fmt_number(v: float, p_lang := "tr") -> String:
	var neg := v < 0.0
	var a := absf(v)
	var whole := int(floor(a + 0.0000001))
	var frac := snappedf(a - whole, 0.1)
	if frac >= 1.0:
		whole += 1
		frac = 0.0
	var digits := str(whole)
	var grouped := ""
	var n := digits.length()
	for i in n:
		grouped += digits[i]
		if (n - 1 - i) % 3 == 0 and i < n - 1:
			grouped += "." if p_lang == "tr" else ","
	var out := grouped
	if frac > 0.0:
		out += ("," if p_lang == "tr" else ".") + str(roundi(frac * 10.0))
	return ("-" if neg else "") + out


## Ölçeğin notu (prototipin atlas.side.note'u): alan ve sıkıştırma (gerçek bir enlem derecesi / haritadaki derecenin km'si).
func scale_note() -> String:
	var compression := 111.0 / (geo.units_per_deg_lat() * geo.km_per_unit)
	return geo.format("atlas.side.note", {"area": fmt_number(geo.area_km2, lang), "ratio": fmt_number(roundf(compression * 10.0) / 10.0, lang)}, lang)


# --- Girdi ------------------------------------------------------------------------------------------------------

func _gui_input(event: InputEvent) -> void:
	if _input_log != null:
		_input_log.append("%s#%d" % [event.get_class(), event.get_instance_id()])
	if event is InputEventMagnifyGesture:
		# İki parmakla kıstırma: parmaklar açılınca yakınlaşır (factor > 1), imlecin altına.
		var mg := event as InputEventMagnifyGesture
		if mg.factor > 0.0 and not _repeated_gesture(mg, Vector2(mg.factor, 0.0)):
			zoom_by(1.0 / mg.factor, mg.position)
		accept_event()
		return
	if event is InputEventPanGesture:
		# macOS'ta iki parmakla kaydırma tekerlek değil bu olaydır: dikey payı tekerlek gibi yakınlaştırır (aşağı yakın, yukarı uzak).
		var pg := event as InputEventPanGesture
		if absf(pg.delta.y) > 0.0001 and not _repeated_gesture(pg, pg.delta):
			zoom_by(exp(pg.delta.y * PAN_ZOOM), pg.position)
		accept_event()
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		match mb.button_index:
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
				if mb.pressed and _in_kilim(mb.position):
					# Kilimin üstünde tekerlek Mete'nin hayatı listesini kaydırır (sığmıyorsa).
					if _life_total > _life_rows:
						_life_scroll = clampi(_life_scroll + (-1 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1), 0, _life_total - _life_rows)
						_overlay.queue_redraw()
				elif mb.pressed:
					var notches := mb.factor if mb.factor > 0.0 else 1.0
					var k := pow(WHEEL_ZOOM, notches)
					zoom_by(1.0 / k if mb.button_index == MOUSE_BUTTON_WHEEL_UP else k, mb.position)
				accept_event()
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
				if mb.pressed:
					var hot := _hot_at(mb.position)
					if mb.button_index == MOUSE_BUTTON_LEFT and not hot.is_empty():
						_activate(hot)
					elif not _in_kilim(mb.position) and not _in_card(mb.position):
						_drag = 2 if (mb.button_index == MOUSE_BUTTON_RIGHT or mb.shift_pressed) else 1
						_last = mb.position
						_travel = 0.0
						mouse_default_cursor_shape = Control.CURSOR_DRAG if _drag == 1 else Control.CURSOR_HSIZE
				else:
					if _drag == 1 and mb.button_index == MOUSE_BUTTON_LEFT and _travel <= CLICK_SLOP:
						_count_click(mb.position)
					_drag = 0
					mouse_default_cursor_shape = Control.CURSOR_ARROW
				accept_event()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _drag != 0:
			_travel += absf(mm.relative.x) + absf(mm.relative.y)
			if _drag == 1:
				pan_screen(_last, mm.position)
			else:
				yaw_t -= mm.relative.x * DRAG_YAW
			_last = mm.position
			accept_event()
			return
		var hot := _hot_at(mm.position)
		var id := str(hot.get("id", ""))
		if id != _hover:
			_hover = id
			if not id.is_empty() and not id.begins_with("label:"):
				MenuStyle.play_ui(self, &"hover", -10.0)
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if not id.is_empty() else Control.CURSOR_ARROW
			_overlay.queue_redraw()


## Aynı jestin ikinci kopyası mı? Godot 4.7.2'de Input'tan geçen jest sayfaya iki kez varır (--map-input-probe ile görüldü; GestureDedupe):
## ikincisi yok sayılır, yoksa yakınlaşma iki kat hızlı olurdu.
func _repeated_gesture(g: InputEventGesture, _value: Vector2) -> bool:
	return _gestures.repeated(g)


## Çift tık: imlecin altına iki kat yakınlaşır.
func _count_click(at: Vector2) -> void:
	var now := Time.get_ticks_msec()
	if now - _click_ms < DOUBLE_CLICK_MS and at.distance_to(_click_at) < CLICK_SLOP:
		_click_ms = -100000
		zoom_by(0.5, at)
		return
	_click_ms = now
	_click_at = at


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not (event is InputEventKey) or not event.is_pressed() or (event as InputEventKey).echo:
		return
	var k := event as InputEventKey
	# Karakter gelirse o sayılır (Türkçe Q'da «-» ABD'nin Equal tuşundadır; prototipin ZOOM_CHARS'ı), gelmezse fiziksel tuş.
	var ch := char(k.unicode) if k.unicode > 0 else ""
	var code := k.physical_keycode
	if ch == "+" or ch == "=" or (ch.is_empty() and code == KEY_EQUAL) or code == KEY_KP_ADD:
		zoom_by(1.0 / KEY_ZOOM)
	elif ch == "-" or (ch.is_empty() and code == KEY_MINUS) or code == KEY_KP_SUBTRACT:
		zoom_by(KEY_ZOOM)
	elif code == KEY_SPACE or code == KEY_HOME:
		fly_home()
	else:
		return
	get_viewport().set_input_as_handled()


func _hot_at(p: Vector2) -> Dictionary:
	for i in range(_hot.size() - 1, -1, -1):
		if (_hot[i]["rect"] as Rect2).has_point(p):
			return _hot[i]
	return {}


func _in_kilim(p: Vector2) -> bool:
	return kilim_rect().has_point(p)


func _in_card(p: Vector2) -> bool:
	return not card.is_empty() and card_rect().has_point(p)


## Tıklanan düğmenin işi.
func _activate(hot: Dictionary) -> void:
	var id := str(hot["id"])
	if not id.begins_with("label:"):
		MenuStyle.play_ui(self, &"click")
	if id == "close":
		close_requested.emit()
	elif id == "home":
		fly_home()
	elif id == "zoom_in":
		zoom_by(BUTTON_ZOOM_IN)
	elif id == "zoom_out":
		zoom_by(BUTTON_ZOOM_OUT)
	elif id == "compass":
		north_up()
	elif id == "quest":
		if _target_at != Vector2.INF:
			fly_to(_target_at, clampf(_area_r * 3.0, min_span(), SITE_SPAN * 0.9))
	elif id == "card_close":
		card = {}
	elif id == "card_prev" or id == "card_next":
		var j := step_event(int(card.get("event", -1)), -1 if id == "card_prev" else 1)
		if j >= 0:
			open_event(j)
	elif id.begins_with("era:"):
		set_era(id.substr(4))
	elif id.begins_with("layer:"):
		var k := id.substr(6)
		set_layer(k, not bool(layers.get(k, true)))
	elif id.begins_with("life:"):
		open_event(int(id.substr(5)))
	elif id.begins_with("label:"):
		var i := int(id.substr(6))
		if i >= 0 and i < items.size() and not str(items[i]["note"]).is_empty():
			MenuStyle.play_ui(self, &"click")
			card = items[i]
	elif id.begins_with("place:"):
		var i := int(id.substr(6))
		if map and i >= 0 and i < map.places.size():
			fly_to(to_atlas(map.places[i]["at"]), clampf(_area_r * 2.2, min_span(), SITE_SPAN * 0.9))
	elif id.begins_with("crumb:"):
		fly_to_crumb(id.substr(6))
	_overlay.queue_redraw()


# --- Çizim --------------------------------------------------------------------------------------------------------

## Kilimin kutusu (sayfaya göre): içeriği kadar uzun (bir önceki çizimin ölçüsü), sayfaya ve KILIM_MAX_H'ye sığar.
func kilim_rect() -> Rect2:
	var h := minf(minf(size.y - KILIM_TOP - 64.0, KILIM_MAX_H), _kilim_h)
	return Rect2(size.x - KILIM_RIGHT - KILIM_W, KILIM_TOP, KILIM_W, h)


## Yer kartının kutusu (sol altta, kapat düğmesinin üstünde; boyu notun satırlarına göre).
func card_rect() -> Rect2:
	var h := float(card.get("_h", 160.0))
	return Rect2(24.0, size.y - 22.0 - BUTTON_H - 14.0 - h, CARD_W, h)


func _draw_overlay(ci: Control) -> void:
	var t0 := Time.get_ticks_usec()
	_hot.clear()
	var view := _view_size()
	var cam := camera()
	var shift := view_shift()
	# Başlık, kilim ve alttaki araçlar adlardan önce yer tutar: ad onların altına girmez.
	var taken: Array[Rect2] = [head_rect(), kilim_rect().grow(6.0), Rect2(0.0, size.y - 22.0 - BUTTON_H - 12.0, size.x, BUTTON_H + 34.0)]
	if not real and wall_on():
		_draw_wall(ci, cam, view, shift)
	_draw_you(ci, cam, view, shift, taken)
	if real and layers["quest"]:
		_draw_quest(ci, cam, view, shift, taken)
	if real:
		_draw_locals(ci, cam, view, shift, taken)
	else:
		_draw_items(ci, cam, view, shift, taken)
	_draw_head(ci)
	_draw_kilim(ci)
	_draw_card(ci)
	_draw_tools(ci, cam, view, shift)
	if _road_note > 0.0:
		var t := geo.text("atlas.road.closed_roam" if rule == "camp" else "atlas.road.closed", lang)
		var a := clampf(_road_note / 0.4, 0.0, 1.0)
		halo_text(ci, UIKit.font("Alegreya-Italic"), Vector2(size.x * 0.5, size.y - 22.0 - BUTTON_H - 22.0), t, 20, Color(WOOL, a), 1)
	_draw_ms = float(Time.get_ticks_usec() - t0) / 1000.0


## Prototipin ad yazısı: koyu hale ve gölge, üstünde yazı. align: 0 sol, 1 orta, 2 sağ.
static func halo_text(ci: CanvasItem, font: Font, pos: Vector2, text: String, size: int, color: Color, align := 0) -> void:
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var at := pos - Vector2(w * 0.5 if align == 1 else (w if align == 2 else 0.0), 0.0)
	# Prototipin text-shadow'u (0 1px 2px koyu, 0 0 7px hale): geniş soluk hale, bir piksel aşağıda koyu gölge, üstünde yazı.
	ci.draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 7, Color(HALO, 0.2 * color.a))
	ci.draw_string(font, at + Vector2(0.0, 1.5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(HALO, 0.85 * color.a))
	ci.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


static func _free(taken: Array[Rect2], r: Rect2) -> bool:
	for t in taken:
		if t.intersects(r):
			return false
	return true


## Yerde bir daire (yansıtılmış: eğik bakışta elips); y yerin yüksekliği.
static func _ground_ring(ci: CanvasItem, cam: Dictionary, view: Vector2, shift: float, c: Vector2, y: float, r: float, col: Color, width: float) -> void:
	var pts := PackedVector2Array()
	for i in 49:
		var a := TAU * i / 48.0
		var p := project(cam, Vector3(c.x + cos(a) * r, y, c.y + sin(a) * r), view, shift)
		if p.z <= 0.0:
			return
		pts.append(Vector2(p.x, p.y))
	ci.draw_polyline(pts, col, width, true)


func _style_color(key: String) -> Color:
	match key:
		"wool":
			return WOOL
		"bronze":
			return BRONZE_LIT
		"ink":
			return INK
	return Color(key)


## Oyuncu: nabız gibi açılan altın halka, baktığı yöne dönen ok (gerçek düzeyde) ya da iğne (atlasta), «BURADASIN» levhası ve yerin adı.
func _draw_you(ci: Control, cam: Dictionary, view: Vector2, shift: float, taken: Array[Rect2]) -> void:
	var y := 0.0 if real else geo.height_at(_player_at)
	var p := project(cam, Vector3(_player_at.x, y, _player_at.y), view, shift)
	if p.z <= 0.0:
		return
	var at := Vector2(p.x, p.y)
	var pulse := fmod(_time * 0.7, 1.0)
	var ring_r := maxf(0.0014, span * 0.035) if real else span * 0.026
	var edge := project(cam, Vector3(_player_at.x + ring_r, y, _player_at.y), view, shift)
	var r_px := (Vector2(edge.x, edge.y) - at).length() if edge.z > 0.0 else 20.0
	var band := clampf(r_px * 0.18 * (0.35 + pulse), 2.0, 9.0)
	_ground_ring(ci, cam, view, shift, _player_at, y, ring_r * (0.35 + pulse), Color(1.0, 0.9, 0.68, (1.0 - pulse) * 0.9), band)
	_ground_ring(ci, cam, view, shift, _player_at, y, ring_r * 0.42, Color(1.0, 0.92, 0.74, 0.9), clampf(r_px * 0.07, 2.0, 5.0))
	if real:
		# Okun ekrandaki yönü: baktığı yöne bir metre ötedeki noktanın yansıması.
		var ahead := project(cam, Vector3(_player_at.x + sin(facing) * 0.001, 0.0, _player_at.y + cos(facing) * 0.001), view, shift)
		var ang := (Vector2(ahead.x, ahead.y) - at).angle() + PI * 0.5 if ahead.z > 0.0 else 0.0
		var arrow := HudKit.tex("marker_arrow")
		ci.draw_set_transform(at, ang, Vector2.ONE)
		if arrow:
			ci.draw_texture_rect(arrow, Rect2(Vector2(-16.0, -17.0), Vector2(32.0, 34.0)), false)
		else:
			ci.draw_colored_polygon(PackedVector2Array([Vector2(0, -15), Vector2(11, 13), Vector2(0, 7), Vector2(-11, 13)]), WOOL)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		# Prototipin iğnesi: altın damla, kızıl uç.
		var top := at + Vector2(0.0, -30.0)
		ci.draw_colored_polygon(PackedVector2Array([at + Vector2(0.0, -2.0), top + Vector2(-8.0, 6.0), top + Vector2(0.0, -6.0), top + Vector2(8.0, 6.0)]), Color("#e2c07f"))
		ci.draw_circle(top + Vector2(0.0, 2.0), 8.0, Color("#e2c07f"))
		ci.draw_circle(top + Vector2(-2.5, 0.0), 3.0, Color(1.0, 0.96, 0.84, 0.8))
		ci.draw_line(at + Vector2(0.0, -8.0), at, Color("#8a2622"), 2.4, true)
	var f := UIKit.font("Cinzel", 700, 1)
	var label := geo.text("atlas.you.here", lang).to_upper()
	var tw := f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	var lift := 66.0 if real else 74.0
	var plate := Rect2(at + Vector2(-tw * 0.5 - 11.0, -lift), Vector2(tw + 22.0, 24.0))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#ebcf91")
	sb.set_corner_radius_all(2)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 2)
	ci.draw_style_box(sb, plate)
	ci.draw_rect(Rect2(plate.position, Vector2(plate.size.x, plate.size.y * 0.45)), Color(1.0, 0.95, 0.82, 0.25))
	ci.draw_string(f, Vector2(plate.position.x + 11.0, plate.end.y - 6.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, INK)
	var under := _nearest_place_name(_player_at) if real else site_name()
	if not under.is_empty():
		halo_text(ci, UIKit.font("Alegreya-Italic"), Vector2(at.x, plate.end.y + 16.0), under, 16, Color("#f6e6bf"), 1)
	taken.append(Rect2(plate.position - Vector2(6.0, 4.0), plate.size + Vector2(12.0, 28.0)))
	taken.append(Rect2(at - Vector2(18.0, 34.0 if not real else 18.0), Vector2(36.0, 52.0 if not real else 36.0)))


func _nearest_place_name(at: Vector2) -> String:
	if map == null:
		return site_name()
	var best := ""
	var bd := 0.014
	for p: Dictionary in map.places:
		var d := to_atlas(p["at"]).distance_to(at)
		if d < bd:
			bd = d
			best = str(p["name"])
	return best if not best.is_empty() else site_name()


## Görevin hedefi (gerçek düzey): halkası, baklavası ve amacın tunç levhası; ekranın dışındaysa kenarda, yönünde.
func _draw_quest(ci: Control, cam: Dictionary, view: Vector2, shift: float, taken: Array[Rect2]) -> void:
	if _target_at == Vector2.INF:
		return
	var p := project(cam, _target_at, view, shift)
	var pulse := 1.0 + 0.07 * sin(_time * PI)
	var inner := Rect2(Vector2(24.0, 24.0), view - Vector2(48.0, 48.0))
	inner.size.x -= KILIM_W + KILIM_RIGHT
	var at := Vector2(p.x, p.y)
	if p.z > 0.0 and inner.has_point(at):
		var pulse_r := fmod(_time * 0.6 + 0.5, 1.0)
		_ground_ring(ci, cam, view, shift, _target_at, 0.0, span * 0.022 * (0.4 + pulse_r), Color(1.0, 0.78, 0.36, (1.0 - pulse_r) * 0.8), 2.4)
		var me := to_page(_player_at)
		var near := me != Vector2.INF and me.distance_to(at) < 34.0
		var mark := at + (Vector2(30.0, -8.0) if near else Vector2(0.0, -14.0))
		HudKit.draw_centered(ci, "marker_diamond", mark, Vector2(34.0, 34.0) * pulse)
		taken.append(Rect2(mark - Vector2(20.0, 20.0), Vector2(40.0, 40.0)))
		if not quest_text.is_empty():
			var f := UIKit.font("Alegreya", 600)
			var text := HudKit.fit_text(f, quest_text, 17, 300.0)
			var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
			var plate := Rect2(at + Vector2(-tw * 0.5 - 9.0, 24.0 if near else 12.0), Vector2(tw + 18.0, 24.0))
			if _free(taken, plate.grow(3.0)):
				var sb := StyleBoxFlat.new()
				sb.bg_color = BRONZE_LIT
				sb.set_corner_radius_all(2)
				sb.shadow_color = Color(0, 0, 0, 0.45)
				sb.shadow_size = 5
				ci.draw_style_box(sb, plate)
				ci.draw_rect(Rect2(plate.position + Vector2(0.0, plate.size.y * 0.55), Vector2(plate.size.x, plate.size.y * 0.45)), Color(BRONZE, 0.55))
				ci.draw_string(f, Vector2(plate.position.x + 9.0, plate.end.y - 6.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, INK)
				taken.append(plate.grow(3.0))
		return
	# Ekranın dışında: kenarda, yönünde küçük bir baklava ve ok.
	var c := inner.get_center()
	var dir := (at - c) if p.z > 0.0 else (c - at)
	if dir.length() < 1.0:
		return
	dir = dir.normalized()
	var half := inner.size * 0.5
	var t := minf(half.x / maxf(absf(dir.x), 0.0001), half.y / maxf(absf(dir.y), 0.0001))
	var e := c + dir * t
	HudKit.draw_centered(ci, "marker_diamond", e, Vector2(28.0, 28.0) * pulse)
	var tip := e + dir * 22.0
	ci.draw_colored_polygon(PackedVector2Array([tip, e + dir * 12.0 + dir.orthogonal() * 7.0, e + dir * 12.0 - dir.orthogonal() * 7.0]), BRONZE_LIT)


## Gerçek düzeyin adları (vadinin sabit adları, yürünür alanın yerleri; yakınlık aralığında, çakışan gizlenir).
func _draw_locals(ci: Control, cam: Dictionary, view: Vector2, shift: float, taken: Array[Rect2]) -> void:
	var kil := kilim_rect()
	for l: Dictionary in locals:
		if span < float(l["min"]) or span > float(l["max"]):
			continue
		var q := project(cam, l["at"], view, shift)
		if q.z <= 0.0:
			continue
		var at := Vector2(q.x, q.y)
		if at.x < -40.0 or at.y < -20.0 or at.y > view.y + 20.0 or at.x > kil.position.x - 16.0:
			continue
		var kind := str(l["type"])
		var st: Array = LABEL_STYLE.get(kind, LABEL_STYLE["local"])
		var f := UIKit.font(str(st[0]), int(st[1]), int(st[2]))
		var fs := int(st[3])
		var text := str(l["name"]).to_upper() if bool(st[5]) else str(l["name"])
		var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var box := Rect2(at + Vector2(-tw * 0.5 - 4.0, -fs - 12.0), Vector2(tw + 8.0, fs + 18.0))
		if not _free(taken, box):
			continue
		taken.append(box)
		if bool(l.get("place", false)):
			ci.draw_circle(at, 4.2, Color(HALO, 0.85))
			ci.draw_circle(at, 2.6, WOOL)
		halo_text(ci, f, at + Vector2(0.0, -9.0 if bool(l.get("place", false)) else 0.0), text, fs, _style_color(str(st[4])), 1)


## Atlasın adları (prototipin updateLabels'ı): konum işareti önce yerleşmiştir, sonra öncelik sırasıyla; çakışan gizlenir. Simgeler
## adların altında (yerinde) çizilir; notu olan ad tıklanır (kart).
func _draw_items(ci: Control, cam: Dictionary, view: Vector2, shift: float, taken: Array[Rect2]) -> void:
	var kil := kilim_rect()
	var lift := span * 0.006
	var icon_px := clampf(view.x * 0.019 * 1.2, 18.0, 40.0)
	# Simgeler önce (adların altında kalır).
	for it: Dictionary in items:
		if str(it["icon"]).is_empty() or not item_on(it):
			continue
		var q := project(cam, Vector3((it["at"] as Vector2).x, float(it["y"]), (it["at"] as Vector2).y), view, shift)
		if q.z <= 0.0:
			continue
		AtlasIcons.draw(ci, str(it["icon"]), Vector2(q.x, q.y), icon_px)
	for it: Dictionary in items:
		if not item_on(it):
			continue
		var at3 := Vector3((it["at"] as Vector2).x, float(it["y"]) + lift, (it["at"] as Vector2).y)
		var q := project(cam, at3, view, shift)
		if q.z <= 0.0:
			continue
		var at := Vector2(q.x, q.y)
		if at.x < -60.0 or at.y < -30.0 or at.y > view.y + 30.0 or at.x > kil.position.x - 10.0:
			continue
		var r := _draw_label(ci, it, at, taken)
		if r.size.x > 0.0 and not str(it["note"]).is_empty():
			_hot.append({"rect": r, "id": "label:%d" % int(it["index"])})


## Bir ad (prototipin .al-<tür>'ü): yer boşsa çizer ve kutusunu döner; yoksa boş kutu.
func _draw_label(ci: Control, it: Dictionary, at: Vector2, taken: Array[Rect2]) -> Rect2:
	var kind := str(it["type"])
	var st: Array = LABEL_STYLE.get(kind, LABEL_STYLE["city"])
	var f := UIKit.font(str(st[0]), int(st[1]), int(st[2]))
	var fs := int(st[3])
	var name_text := str(it["name"])
	if name_text.is_empty():
		return Rect2()
	if bool(st[5]):
		name_text = name_text.to_upper()
	if kind == "clan":
		name_text = "◆ " + name_text
	var sub := str(it["sub"])
	var sf := UIKit.font("Alegreya-Italic")
	var tw := f.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var sw := sf.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x if not sub.is_empty() else 0.0
	var w := maxf(tw + (14.0 if kind == "event" else 0.0), sw)
	# Prototipin kutusu (öğenin boyu; satır yüksekliği 1,05): ad ve altında küçük satır.
	var h := fs * 1.05 + (13.0 if not sub.is_empty() else 0.0)
	var box := Rect2(at - Vector2(w * 0.5, h * 0.5), Vector2(w, h))
	# Yarısı sayfanın dışında kalan ad yazılmaz (kesik yazı okunmaz).
	if box.position.y < 0.0 or box.end.y > size.y or box.position.x < 0.0 or box.end.x > size.x:
		return Rect2()
	if not _free(taken, box.grow_individual(4.0, 2.0, 4.0, 2.0)):
		return Rect2()
	taken.append(box.grow_individual(4.0, 2.0, 4.0, 2.0))
	var hot := _hover == "label:%d" % int(it["index"])
	var col := _style_color(str(st[4]))
	if kind == "state" and not str(it["color"]).is_empty():
		col = WOOL
	var alpha := 0.58 if kind == "rumour" else 1.0
	if kind == "event":
		# Yılı üstte, adı tunç levhada (prototipin column-reverse'ü).
		if not sub.is_empty():
			halo_text(ci, UIKit.font("Alegreya"), Vector2(at.x, box.position.y + 12.0), sub, 13, BRONZE_LIT, 1)
		var plate := Rect2(Vector2(at.x - tw * 0.5 - 7.0, box.end.y - fs - 6.0), Vector2(tw + 14.0, fs + 6.0))
		var sb := StyleBoxFlat.new()
		sb.bg_color = BRONZE_LIT.lightened(0.08) if hot else BRONZE_LIT
		sb.set_corner_radius_all(2)
		sb.shadow_color = Color(0, 0, 0, 0.4)
		sb.shadow_size = 4
		ci.draw_style_box(sb, plate)
		ci.draw_rect(Rect2(plate.position + Vector2(0.0, plate.size.y * 0.5), Vector2(plate.size.x, plate.size.y * 0.5)), Color(BRONZE, 0.6))
		ci.draw_string(f, Vector2(plate.position.x + 7.0, plate.end.y - 5.0), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#3a1513") if hot else INK)
		return box
	var y := box.position.y + fs
	halo_text(ci, f, Vector2(at.x, y), name_text, fs, Color(BRONZE_LIT if hot else col, alpha), 1)
	if not sub.is_empty():
		halo_text(ci, sf, Vector2(at.x, y + 15.0), sub, 13, Color(col, 0.86 * alpha), 1)
	return box


## Çin Surları (prototipin buildWall'ı): kabartmanın üstünde taş rengi çizgi ve aralıklı kuleler.
func _draw_wall(ci: Control, cam: Dictionary, view: Vector2, shift: float) -> void:
	if geo.wall.size() < 2:
		return
	var w_units := 0.033
	var pts := PackedVector2Array()
	var towers := PackedVector2Array()
	var n := 0
	for i in geo.wall.size() - 1:
		var a := geo.wall[i]
		var b := geo.wall[i + 1]
		var steps := maxi(2, ceili(a.distance_to(b) / 0.2))
		for k in steps:
			var p := a.lerp(b, float(k) / steps)
			var q := project(cam, Vector3(p.x, geo.height_at(p) + 0.02, p.y), view, shift)
			if q.z <= 0.0:
				continue
			pts.append(Vector2(q.x, q.y))
			n += 1
			if n % 5 == 3:
				towers.append(Vector2(q.x, q.y))
	if pts.size() < 2:
		return
	var c0 := project(cam, Vector3(cx, 0.0, cz), view, shift)
	var c1 := project(cam, Vector3(cx + w_units, 0.0, cz), view, shift)
	var px := clampf(Vector2(c1.x - c0.x, c1.y - c0.y).length(), 1.2, 9.0) if c0.z > 0.0 and c1.z > 0.0 else 2.0
	ci.draw_polyline(pts, Color(0.12, 0.09, 0.06, 0.7), px + 1.6, true)
	ci.draw_polyline(pts, Color("#b0a288"), px, true)
	var ts := px * 1.6
	for t in towers:
		ci.draw_rect(Rect2(t - Vector2(ts, ts * 1.5) * 0.5 - Vector2(0.0, ts * 0.4), Vector2(ts, ts * 1.5)), Color("#8f8268"))


## Sol üst: kırıntılar (tıklanınca o düzeye uçar), başlık (son kırıntı), dönemin satırı.
func _draw_head(ci: Control) -> void:
	var x := 30.0
	var y := 34.0
	var ids := crumb_ids()
	var it := UIKit.font("Alegreya-Italic")
	for i in ids.size():
		var text := crumb_text(ids[i])
		var last := i == ids.size() - 1
		var w := it.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
		var hot := not last and _hover == "crumb:" + ids[i]
		halo_text(ci, it, Vector2(x, y), text, 19, WOOL if (last or hot) else WOOL_DIM)
		if not last:
			ci.draw_line(Vector2(x, y + 4.0), Vector2(x + w, y + 4.0), Color(WOOL, 0.35), 1.0)
			_hot.append({"rect": Rect2(x - 4.0, y - 20.0, w + 8.0, 28.0), "id": "crumb:" + ids[i]})
			halo_text(ci, it, Vector2(x + w + 9.0, y), "›", 19, Color(WOOL, 0.6))
			x += w + 26.0
	var title := crumb_text(ids[ids.size() - 1]).to_upper()
	halo_text(ci, UIKit.font("Cinzel", 500, 6), Vector2(30.0, y + 50.0), title, 46, WOOL)
	var line := era_line()
	if not line.is_empty():
		halo_text(ci, it, Vector2(30.0, y + 80.0), line, 21, BRONZE_LIT)


## Başlığın kutusu (kırıntılar, başlık, dönemin satırı): adlar onun altına girmez.
func head_rect() -> Rect2:
	var ids := crumb_ids()
	var w := UIKit.font("Cinzel", 500, 6).get_string_size(crumb_text(ids[ids.size() - 1]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 46).x
	var cw := 0.0
	for id in ids:
		cw += UIKit.font("Alegreya-Italic").get_string_size(crumb_text(id), HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x + 26.0
	return Rect2(Vector2(16.0, 8.0), Vector2(maxf(maxf(w, cw), 300.0) + 30.0, 116.0))


## Surlar bu dönemde var mı (Meng Tian'dan önce yok).
func wall_on() -> bool:
	for it: Dictionary in items:
		if str(it["type"]) == "wall":
			return (it["eras"] as Array).has(era)
	return true


## Dönemin satırı: «MÖ 210 · Yüeçi'de rehine».
func era_line() -> String:
	for e: Dictionary in geo.rows("eras"):
		if str(e["id"]) == era:
			var label := geo.row_text("eras", e, "label", lang)
			var title := geo.row_text("eras", e, "title", lang)
			return "%s · %s" % [label, title] if not title.is_empty() else label
	return ""


# --- Kilim ----------------------------------------------------------------------------------------------------------

## Sırıktan sarkan kilim ve içindekiler (prototipin .kilim'i ve atlas-side'ı).
func _draw_kilim(ci: Control) -> void:
	var r := kilim_rect()
	var sh := StyleBoxFlat.new()
	sh.bg_color = Color(0, 0, 0, 0)
	sh.shadow_color = Color(0.024, 0.07, 0.063, 0.5)
	sh.shadow_size = 22
	sh.shadow_offset = Vector2(0.0, 16.0)
	var cloth := Rect2(r.position + Vector2(0.0, 15.0 + ROD_H - 5.0), Vector2(r.size.x, r.size.y - 15.0 - ROD_H + 5.0))
	ci.draw_style_box(sh, cloth)
	ci.draw_rect(cloth, FELT)
	var felt := felt_texture()
	if felt:
		ci.draw_texture_rect(felt, cloth, true, Color(0.0, 0.0, 0.0, 0.22))
		ci.draw_texture_rect(felt, Rect2(cloth.position + Vector2(3.0, 2.0), cloth.size), true, Color(1.0, 0.86, 0.72, 0.05))
	var band := Rect2(cloth.position, Vector2(cloth.size.x, BAND_H))
	_draw_meander(ci, band)
	_draw_fringe(ci, Rect2(cloth.position.x, cloth.end.y - FRINGE_H, cloth.size.x, FRINGE_H))
	_draw_rod(ci, Rect2(r.position + Vector2(-16.0, 15.0), Vector2(r.size.x + 32.0, ROD_H)))
	var x := cloth.position.x + 26.0
	var w := cloth.size.x - 52.0
	var y := band.end.y + 12.0
	var body := UIKit.font("Alegreya", 500)
	# DÖNEM: açık dönemler (seçili olan yün zeminli).
	if not open_eras.is_empty():
		y = _kilim_head(ci, x, y, w, geo.text("atlas.side.era", lang))
		var ex := x
		for id in open_eras:
			var label := ""
			for e: Dictionary in geo.rows("eras"):
				if str(e["id"]) == id:
					label = geo.row_text("eras", e, "label", lang)
			var cw := body.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x + 22.0
			if ex + cw > x + w:
				ex = x
				y += 36.0
			var chip := Rect2(ex, y, cw, 30.0)
			var on := id == era
			var hot := _hover == "era:" + id
			var sb := StyleBoxFlat.new()
			sb.bg_color = WOOL if on else Color(0, 0, 0, 0)
			sb.border_color = WOOL if on else (BRONZE_LIT if hot else Color(BRONZE, 0.7))
			sb.set_border_width_all(1)
			sb.set_corner_radius_all(3)
			ci.draw_style_box(sb, chip)
			ci.draw_string(body, Vector2(ex + 11.0, y + 21.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("#3a1513") if on else WOOL)
			_hot.append({"rect": chip, "id": "era:" + id})
			ex += cw + 8.0
		y += 40.0
		y = _kilim_rule(ci, x, y, w)
	# GÖREV.
	if not quest_text.is_empty():
		y = _kilim_head(ci, x, y, w, geo.text("atlas.side.quest", lang))
		var row := Rect2(x - 6.0, y - 4.0, w + 12.0, 62.0)
		var hot := _hover == "quest"
		if hot:
			ci.draw_rect(row, Color(1.0, 0.9, 0.7, 0.06))
		HudKit.draw_centered(ci, "marker_diamond", Vector2(x + 11.0, y + 16.0), Vector2(24.0, 24.0))
		var tf := UIKit.font("Cinzel", 600, 2)
		var qt := quest_title.to_upper() if not quest_title.is_empty() else geo.text("atlas.side.quest", lang).to_upper()
		ci.draw_string(tf, Vector2(x + 32.0, y + 22.0), HudKit.fit_text(tf, qt, 15, w - 34.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, BRONZE_LIT)
		ci.draw_string(body, Vector2(x + 32.0, y + 47.0), HudKit.fit_text(body, quest_text, 19, w - 34.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 19, BRONZE_LIT if hot else WOOL)
		_hot.append({"rect": row, "id": "quest"})
		y += 66.0
		y = _kilim_rule(ci, x, y, w)
	# KATMANLAR.
	y = _kilim_head(ci, x, y, w, geo.text("atlas.side.layers", lang))
	for l: Array in LAYERS:
		var k := str(l[0])
		if k == "quest" and _target_at == Vector2.INF:
			continue
		var id := "layer:" + k
		var on := bool(layers.get(k, true))
		var row := Rect2(x - 6.0, y - 2.0, w + 12.0, 29.0)
		var hot := _hover == id
		var a := 1.0 if on else 0.42
		_draw_swatch(ci, k, Rect2(x, y + 5.0, 26.0, 17.0), a)
		var col := Color(BRONZE_LIT if hot else WOOL, a)
		var text := geo.text(str(l[1]), lang)
		ci.draw_string(body, Vector2(x + 38.0, y + 20.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, col)
		if not on:
			var lw := body.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x
			ci.draw_line(Vector2(x + 38.0, y + 14.0), Vector2(x + 38.0 + lw, y + 14.0), col, 1.2)
		_hot.append({"rect": row, "id": id})
		y += 29.0
	y = _kilim_rule(ci, x, y + 4.0, w)
	# Kilimin sığabileceği en alt satır: uzun liste kayar, YERLER ve ölçeğin notu yalnız sığarsa çizilir (sayfa kısa, içerik uzun olabilir).
	var bottom := r.position.y + minf(size.y - KILIM_TOP - 64.0, KILIM_MAX_H) - FRINGE_H - 20.0
	# METE'NİN HAYATI: açık olaylar (yıl, ad). Sığmazsa liste kayar (tekerlek kilimin üstünde; okların yanında kalan sayısı).
	var open_list: Array[int] = []
	var events := geo.rows("events")
	for i in events.size():
		if event_open(i):
			open_list.append(i)
	if not open_list.is_empty():
		y = _kilim_head(ci, x, y, w, geo.text("atlas.side.life", lang))
		var rows := clampi(int((bottom - y - 16.0) / 27.0), 2, open_list.size())
		_life_scroll = clampi(_life_scroll, 0, open_list.size() - rows)
		if rows < open_list.size():
			var sf := UIKit.font("Alegreya-Italic")
			var above := _life_scroll
			var below := open_list.size() - rows - _life_scroll
			var tag := ("▲ %d  " % above if above > 0 else "") + ("▼ %d" % below if below > 0 else "")
			ci.draw_string(sf, Vector2(x + w - sf.get_string_size(tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x, y - 14.0), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, WOOL_DIM)
		for k in range(_life_scroll, _life_scroll + rows):
			var i := open_list[k]
			var e: Dictionary = events[i]
			var id := "life:%d" % i
			var hot := _hover == id or int(card.get("event", -1)) == i
			ci.draw_string(body, Vector2(x, y + 18.0), geo.row_text("events", e, "year", lang), HORIZONTAL_ALIGNMENT_LEFT, 84.0, 15, BRONZE_LIT)
			var name_text := HudKit.fit_text(body, geo.row_text("events", e, "name", lang), 18, w - 90.0)
			ci.draw_string(body, Vector2(x + 90.0, y + 18.0), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, BRONZE_LIT if hot else WOOL)
			if int(card.get("event", -1)) == i:
				var nw := body.get_string_size(name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
				ci.draw_line(Vector2(x + 90.0, y + 22.0), Vector2(x + 90.0 + nw, y + 22.0), Color(BRONZE_LIT, 0.8), 1.0)
			_hot.append({"rect": Rect2(x - 6.0, y - 2.0, w + 12.0, 27.0), "id": id})
			y += 27.0
		_life_rows = rows
		_life_total = open_list.size()
		y = _kilim_rule(ci, x, y + 4.0, w)
	# YERLER (gerçek düzeyde): yürünür alanın yerleri, tıklanınca yere uçar.
	if real and map and not map.places.is_empty() and y + 46.0 + map.places.size() * 28.0 <= bottom:
		y = _kilim_head(ci, x, y, w, geo.text("atlas.side.places", lang))
		for i in map.places.size():
			var id := "place:%d" % i
			var hot := _hover == id
			_draw_mini_diamond(ci, Vector2(x + 8.0, y + 12.0), 4.5, BRONZE_LIT)
			var pn := str(map.places[i]["name"])
			ci.draw_string(body, Vector2(x + 24.0, y + 19.0), HudKit.fit_text(body, pn, 19, w - 26.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 19, BRONZE_LIT if hot else WOOL)
			_hot.append({"rect": Rect2(x - 6.0, y - 2.0, w + 12.0, 28.0), "id": id})
			y += 28.0
		y = _kilim_rule(ci, x, y + 4.0, w)
	var nf := UIKit.font("Alegreya-Italic")
	var note_lines := HudKit.wrap_lines(nf, scale_note(), 16, w, 6)
	if y + note_lines.size() * 20.0 <= bottom:
		for line in note_lines:
			ci.draw_string(nf, Vector2(x, y + 14.0), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, WOOL_DIM)
			y += 20.0
	# Kilim içeriği kadar uzar: bir sonraki çizim bu boyla (kare başına yeniden çizilir).
	var need := y + 24.0 + FRINGE_H - r.position.y
	if absf(need - _kilim_h) > 1.0:
		_kilim_h = need


func _kilim_head(ci: Control, x: float, y: float, _w: float, text: String) -> float:
	ci.draw_string(UIKit.font("Cinzel", 500, 3), Vector2(x, y + 16.0), text.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, WOOL)
	return y + 30.0


func _kilim_rule(ci: Control, x: float, y: float, w: float) -> float:
	ci.draw_line(Vector2(x - 4.0, y + 4.0), Vector2(x + w + 4.0, y + 4.0), Color(WOOL, 0.14), 1.0)
	return y + 16.0


## Katmanın küçük örneği (prototipin .lg-* sınıfları).
func _draw_swatch(ci: Control, id: String, r: Rect2, a: float) -> void:
	match id:
		"states":
			ci.draw_rect(r, Color(201.0 / 255.0, 162.0 / 255.0, 79.0 / 255.0, 0.28 * a))
			ci.draw_rect(r.grow(-1.0), Color(Color("#c9a24f"), a), false, 2.0)
		"realms":
			ci.draw_rect(r, Color(190.0 / 255.0, 70.0 / 255.0, 60.0 / 255.0, 0.16 * a))
			var c := Color(Color("#c9544a"), a)
			var x := r.position.x
			while x < r.end.x:
				ci.draw_line(Vector2(x, r.position.y + 1.0), Vector2(minf(x + 4.0, r.end.x), r.position.y + 1.0), c, 2.0)
				ci.draw_line(Vector2(x, r.end.y - 1.0), Vector2(minf(x + 4.0, r.end.x), r.end.y - 1.0), c, 2.0)
				x += 7.0
			ci.draw_line(Vector2(r.position.x + 1.0, r.position.y), Vector2(r.position.x + 1.0, r.end.y), c, 2.0)
			ci.draw_line(Vector2(r.end.x - 1.0, r.position.y), Vector2(r.end.x - 1.0, r.end.y), c, 2.0)
		"cities":
			var b := Rect2(r.position + Vector2(0.0, 3.0), Vector2(r.size.x, r.size.y - 4.0))
			ci.draw_rect(b, Color(Color("#b8a88a"), a))
			ci.draw_rect(b.grow(-1.0), Color(Color("#8f8268"), a), false, 2.0)
		"events":
			ci.draw_rect(r, Color(BRONZE_LIT, a))
			ci.draw_rect(Rect2(r.position + Vector2(0.0, r.size.y * 0.5), Vector2(r.size.x, r.size.y * 0.5)), Color(BRONZE, a))
		"nature":
			ci.draw_colored_polygon(PackedVector2Array([r.position, r.position + Vector2(r.size.x * 0.55, 0.0), r.position + Vector2(0.0, r.size.y)]), Color(Color("#7c7268"), a))
			ci.draw_colored_polygon(PackedVector2Array([r.position + Vector2(r.size.x * 0.55, 0.0), r.position + Vector2(r.size.x * 0.85, 0.0),
				r.position + Vector2(r.size.x * 0.3, r.size.y), r.position + Vector2(0.0, r.size.y)]), Color(Color("#4f94ad"), a))
			ci.draw_colored_polygon(PackedVector2Array([r.position + Vector2(r.size.x * 0.85, 0.0), r.end - Vector2(0.0, r.size.y),
				r.end, r.position + Vector2(r.size.x * 0.3, r.size.y)]), Color(Color("#d9bd83"), a))
		"quest":
			HudKit.draw_centered(ci, "marker_diamond", r.get_center(), Vector2(20.0, 20.0), Color(1, 1, 1, a))
		"area":
			ci.draw_rect(r, Color(0.62, 0.27, 0.2, 0.32 * a))
			ci.draw_rect(r.grow(-1.0), Color(0.7, 0.24, 0.2, a), false, 2.0)
		"clouds":
			ci.draw_rect(r, Color(0.56, 0.64, 0.8, 0.55 * a))
			ci.draw_circle(r.position + Vector2(9.0, 10.0), 6.0, Color(1.0, 0.98, 0.94, a))
			ci.draw_circle(r.position + Vector2(17.0, 8.0), 7.0, Color(1.0, 0.98, 0.94, a))


static func _draw_mini_diamond(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s), c + Vector2(s, 0), c + Vector2(0, s), c + Vector2(-s, 0)]), col)


## Kilimin üst bandı: yün zemin, koyu kenarlar, kızıl meander (prototipin woven.js'i: 58 × 26 px'lik karo).
func _draw_meander(ci: Control, band: Rect2) -> void:
	ci.draw_rect(band, WOOL)
	var e := band.size.y * 5.0 / 52.0
	ci.draw_rect(Rect2(band.position, Vector2(band.size.x, e)), EDGE)
	ci.draw_rect(Rect2(band.position.x, band.end.y - e, band.size.x, e), EDGE)
	var tile := band.size.y * 58.0 / 26.0
	var half := tile * 0.5
	var y := band.position.y + band.size.y * 8.0 / 52.0
	var h := band.size.y * 36.0 / 52.0
	var lw := band.size.y * 5.4 / 52.0
	var x := band.position.x
	while x < band.end.x:
		var u := half / 8.0
		var v := h / 6.0
		var pts := PackedVector2Array([Vector2(x, y + 5.0 * v), Vector2(x + 6.0 * u, y + 5.0 * v), Vector2(x + 6.0 * u, y + v),
			Vector2(x + 2.0 * u, y + v), Vector2(x + 2.0 * u, y + 3.4 * v), Vector2(x + 4.2 * u, y + 3.4 * v)])
		for i in pts.size():
			pts[i].x = minf(pts[i].x, band.end.x)
		ci.draw_polyline(pts, MOTIF, lw)
		ci.draw_line(Vector2(minf(x + 6.0 * u, band.end.x), y + 5.0 * v), Vector2(minf(x + 8.0 * u, band.end.x), y + 5.0 * v), MOTIF, lw)
		x += half


## Saçak: kızıl ve yün püsküller.
func _draw_fringe(ci: Control, r: Rect2) -> void:
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x, 3.0)), EDGE)
	var step := 17.0
	var n := int(r.size.x / step)
	var x0 := r.position.x + (r.size.x - n * step) * 0.5 + step * 0.5
	for i in n:
		var x := x0 + i * step
		var wool := i % 2 == 1
		ci.draw_rect(Rect2(x - 3.0, r.position.y + 2.0, 6.0, 8.0), WOOL if wool else MADDER)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 4.0, r.position.y + 9.0), Vector2(x + 4.0, r.position.y + 9.0),
			Vector2(x + 2.4, r.end.y + 8.0), Vector2(x - 2.4, r.end.y + 8.0)]), WOOL_DIM if wool else MADDER_DEEP)


## Sırık: koyu cevizden yuvarlak çubuk, uçlarında tunç topuzlar.
func _draw_rod(ci: Control, rod: Rect2) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#5c4029")
	sb.set_corner_radius_all(int(rod.size.y * 0.5))
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 3)
	ci.draw_style_box(sb, rod)
	ci.draw_rect(Rect2(rod.position + Vector2(rod.size.y * 0.5, 2.0), Vector2(rod.size.x - rod.size.y, rod.size.y * 0.3)), Color("#8d6a44"))
	ci.draw_rect(Rect2(rod.position + Vector2(rod.size.y * 0.5, rod.size.y * 0.72), Vector2(rod.size.x - rod.size.y, rod.size.y * 0.22)), Color("#33231a"))
	for side in [0, 1]:
		var k := Rect2(Vector2(rod.position.x - 3.0 if side == 0 else rod.end.x - 10.0, rod.position.y - 4.0), Vector2(13.0, 23.0))
		var kb := StyleBoxFlat.new()
		kb.bg_color = BRONZE
		kb.set_corner_radius_all(4)
		ci.draw_style_box(kb, k)
		ci.draw_rect(Rect2(k.position + Vector2(2.0, 2.0), Vector2(k.size.x - 4.0, k.size.y * 0.4)), Color(BRONZE_LIT, 0.9))
		ci.draw_rect(Rect2(k.position + Vector2(2.0, k.size.y * 0.7), Vector2(k.size.x - 4.0, k.size.y * 0.25)), Color("#7c5c2e"))


# --- Yer kartı -------------------------------------------------------------------------------------------------------

## Ada tıklanınca açılan kart (prototipin .atlas-card'ı): türü, adı, alt adı, notu; olayda önceki ve sonraki olay.
func _draw_card(ci: Control) -> void:
	if card.is_empty():
		return
	var body := UIKit.font("Alegreya", 500)
	var it := UIKit.font("Alegreya-Italic")
	var title_f := UIKit.font("Cinzel", 500, 2)
	var kind_f := UIKit.font("Cinzel", 600, 2)
	var inner_w := CARD_W - 40.0
	var lines := HudKit.wrap_lines(body, str(card["note"]), 19, inner_w, 9)
	var is_event := card.has("event")
	var h := 16.0 + (20.0 if not str(card["kind"]).is_empty() else 0.0) + 32.0
	if not str(card["sub"]).is_empty() and not is_event:
		h += 24.0
	h += lines.size() * 25.0 + 12.0 + (34.0 if is_event else 0.0)
	card["_h"] = h
	var r := card_rect()
	var sb := StyleBoxFlat.new()
	sb.bg_color = FELT
	sb.border_color = BRONZE
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.shadow_color = Color(0.024, 0.07, 0.063, 0.5)
	sb.shadow_size = 18
	sb.shadow_offset = Vector2(0, 10)
	ci.draw_style_box(sb, r)
	var felt := felt_texture()
	if felt:
		ci.draw_texture_rect(felt, r.grow(-1.0), true, Color(0.0, 0.0, 0.0, 0.2))
	var x := r.position.x + 20.0
	var y := r.position.y + 16.0
	if not str(card["kind"]).is_empty():
		ci.draw_string(kind_f, Vector2(x, y + 12.0), str(card["kind"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, inner_w - 24.0, 13, BRONZE_LIT)
		y += 20.0
	ci.draw_string(title_f, Vector2(x, y + 24.0), str(card["name"]), HORIZONTAL_ALIGNMENT_LEFT, inner_w - 24.0, 25, WOOL)
	y += 32.0
	if not str(card["sub"]).is_empty() and not is_event:
		ci.draw_string(it, Vector2(x, y + 16.0), str(card["sub"]), HORIZONTAL_ALIGNMENT_LEFT, inner_w, 18, WOOL_DIM)
		y += 24.0
	y += 6.0
	for line in lines:
		ci.draw_string(body, Vector2(x, y + 18.0), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, WOOL)
		y += 25.0
	var xr := Rect2(r.end.x - 36.0, r.position.y + 4.0, 30.0, 30.0)
	var xhot := _hover == "card_close"
	ci.draw_string(body, Vector2(xr.position.x + 8.0, xr.end.y - 7.0), "×", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, WOOL if xhot else WOOL_DIM)
	_hot.append({"rect": xr, "id": "card_close"})
	if is_event:
		var i := int(card["event"])
		var prev := step_event(i, -1)
		var next := step_event(i, 1)
		y += 8.0
		for pair: Array in [["card_prev", "atlas.card.prev", prev, 0], ["card_next", "atlas.card.next", next, 1]]:
			var text := geo.text(str(pair[1]), lang)
			var tw := body.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
			var px := x if int(pair[3]) == 0 else r.end.x - 20.0 - tw
			var ok := int(pair[2]) >= 0
			var hot := ok and _hover == str(pair[0])
			var col := Color(BRONZE_LIT if hot else WOOL, 1.0 if ok else 0.35)
			ci.draw_string(body, Vector2(px, y + 18.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, col)
			if ok:
				ci.draw_line(Vector2(px, y + 22.0), Vector2(px + tw, y + 22.0), Color(col, 0.6), 1.0)
				_hot.append({"rect": Rect2(px - 4.0, y - 2.0, tw + 8.0, 28.0), "id": str(pair[0])})


# --- Araçlar --------------------------------------------------------------------------------------------------------

## Prototipin .hud-btn'i: koyu keçe, soluk tunç kenar; üzerine gelince tunç.
func _hud_button(ci: Control, r: Rect2, text: String, id: String, key := "") -> void:
	var hot := _hover == id
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(84.0 / 255.0, 30.0 / 255.0, 27.0 / 255.0, 0.92) if hot else Color(51.0 / 255.0, 19.0 / 255.0, 17.0 / 255.0, 0.84)
	sb.border_color = BRONZE_LIT if hot else Color(BRONZE_LIT, 0.5)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	ci.draw_style_box(sb, r)
	var f := UIKit.font("Alegreya", 500)
	var fs := 19
	var tw := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var kf := UIKit.font("Cinzel", 500)
	var kw := kf.get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 9.0 if not key.is_empty() else 0.0
	var x := r.get_center().x - (tw + kw) * 0.5
	ci.draw_string(f, Vector2(x, r.get_center().y + 7.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, WOOL)
	if not key.is_empty():
		ci.draw_string(kf, Vector2(x + tw + 9.0, r.get_center().y + 6.0), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(WOOL, 0.68))
	_hot.append({"rect": r, "id": id})


func _button_w(text: String, key := "") -> float:
	var w := UIKit.font("Alegreya", 500).get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 19).x + 32.0
	if not key.is_empty():
		w += UIKit.font("Cinzel", 500).get_string_size(key, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 9.0
	return w


## Alt: solda kapat; ortada pusula, ölçek çubuğu, «Konumum», + ve −.
func _draw_tools(ci: Control, cam: Dictionary, view: Vector2, shift: float) -> void:
	var y := size.y - 22.0 - BUTTON_H
	var close_text := geo.text("atlas.tool.close", lang)
	var close_key := ControlsPage.keys_of("map")
	var key := str(close_key[0]) if not close_key.is_empty() else "M"
	_hud_button(ci, Rect2(30.0, y, _button_w(close_text, key), BUTTON_H), close_text, "close", key)
	var sb := scale_bar(span, 1.0 if real else geo.km_per_unit, view.x)
	var bar_w := maxf(float(sb[1]), 40.0)
	var compass := 50.0
	var home_text := geo.text("atlas.tool.home", lang)
	var home_w := _button_w(home_text)
	var zoom_w := 40.0
	var gap := 12.0
	var total := compass + gap + maxf(bar_w, 120.0) + gap + home_w + gap + zoom_w + gap + zoom_w
	var x := size.x * 0.5 - total * 0.5
	# Pusula: koyu keçe daire, tunç kenar; iğne ekranda kuzeyi gösterir.
	var cc := Vector2(x + compass * 0.5, y + BUTTON_H * 0.5)
	var hot := _hover == "compass"
	ci.draw_circle(cc, compass * 0.5, Color(51.0 / 255.0, 19.0 / 255.0, 17.0 / 255.0, 0.86))
	ci.draw_arc(cc, compass * 0.5, 0.0, TAU, 48, BRONZE_LIT if hot else BRONZE, 1.4, true)
	var ly := float(cam.get("look_y", 0.0))
	var c0 := project(cam, Vector3(cx, ly, cz), view, shift)
	var c1 := project(cam, Vector3(cx, ly, cz - span * 0.05), view, shift)
	var north := (Vector2(c1.x, c1.y) - Vector2(c0.x, c0.y)).normalized() if c0.z > 0.0 and c1.z > 0.0 else Vector2.UP
	var side := north.orthogonal()
	var tip := cc + north * 19.0
	ci.draw_colored_polygon(PackedVector2Array([tip, cc + north * 3.0 + side * 6.0, cc + north * 3.0 - side * 6.0]), BRONZE_LIT)
	ci.draw_colored_polygon(PackedVector2Array([cc - north * 11.0, cc + north * 3.0 + side * 4.0, cc + north * 3.0 - side * 4.0]), Color(WOOL, 0.35))
	HudKit.draw_text(ci, UIKit.font("Cinzel", 600), cc + Vector2(0.0, 19.0), geo.text("atlas.tool.north_letter", lang), 13, WOOL, 1, Color(0, 0, 0, 0), 0)
	_hot.append({"rect": Rect2(cc - Vector2(compass, compass) * 0.5, Vector2(compass, compass)), "id": "compass"})
	x += compass + gap
	# Ölçek çubuğu: altı açık ince yün çerçeve, altında uzunluğu.
	var bw := maxf(bar_w, 120.0)
	var bx := x + (bw - float(sb[1])) * 0.5
	var by := y + 12.0
	for pass_i in 2:
		var col := Color(HALO, 0.8) if pass_i == 0 else WOOL
		var wdt := 3.0 if pass_i == 0 else 1.2
		ci.draw_line(Vector2(bx, by), Vector2(bx, by + 6.0), col, wdt)
		ci.draw_line(Vector2(bx + float(sb[1]), by), Vector2(bx + float(sb[1]), by + 6.0), col, wdt)
		ci.draw_line(Vector2(bx, by + 6.0), Vector2(bx + float(sb[1]), by + 6.0), col, wdt)
	var km := float(sb[0])
	var label := geo.format("atlas.scale.m", {"n": fmt_number(roundf(km * 1000.0), lang)}, lang) if km < 1.0 \
		else geo.format("atlas.scale.km", {"n": fmt_number(km, lang)}, lang)
	halo_text(ci, UIKit.font("Alegreya-Italic"), Vector2(x + bw * 0.5, by + 27.0), label, 17, WOOL, 1)
	x += bw + gap
	_hud_button(ci, Rect2(x, y, home_w, BUTTON_H), home_text, "home")
	x += home_w + gap
	_hud_button(ci, Rect2(x, y, zoom_w, BUTTON_H), "+", "zoom_in")
	x += zoom_w + gap
	_hud_button(ci, Rect2(x, y, zoom_w, BUTTON_H), "−", "zoom_out")


# --- Dokular --------------------------------------------------------------------------------------------------------

## Keçenin ince dokusu (kilim, kart).
static func felt_texture() -> Texture2D:
	if _felt:
		return _felt
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_VALUE_CUBIC
	n.seed = 5
	n.frequency = 0.22
	n.fractal_type = FastNoiseLite.FRACTAL_FBM
	n.fractal_octaves = 2
	var t := NoiseTexture2D.new()
	t.width = 128
	t.height = 128
	t.seamless = true
	t.noise = n
	_felt = t
	return t


## Haritanın üstündeki her şeyi çizen katman.
class Overlay extends Control:
	var host: HudMapPage

	func _draw() -> void:
		if host:
			host._draw_overlay(self)
