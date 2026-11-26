class_name WorldMap
extends RefCounted
## Dünyanın tepeden bir kez çizilip görüntüye pişirilmiş haritası (mini harita ve büyük harita, M; bütçe kuralı K63: her kare ikinci bir
## 3B çizim yoktur). bake() dünyanın üstüne dik (ortografik) bir kamerayla tek karelik bir SubViewport kurar: kuzey (-Z) yukarıda, doğu
## (+X) sağda; kare çizilince görüntü belleğe alınır (mip'li ImageTexture), SubViewport bırakılır. Kamera kendi ortamını taşır (düz ortam
## ışığı, sis ve renk ayarı yok: harita gecede de okunur); 400 m yüksekte durduğu için uzaklıkla sönen otlar (atw_grass, 26–40 m) çizilmez,
## zeminin kendi boyası (ot dibi, toprak, iz) haritanın zeminidir. Pişirme sırasında hareketli şeyler (oyuncu, sürü, av) gizlenir; perde
## kara ya da oyuncu menüdeyken çağrılır, gizleme görünmez. Başsız çalıştırmada (sınama) çizim yoktur: parşömen renginde bir yedek gelir.
## Aynı dünyanın haritası oturum boyunca bir kez pişer (cache; kamp menüde, Ordos dünya her kurulduğunda yeniden: Çocukluk'un izleri
## dünyayla gelir).
## Atlasın gerçek düzeyi (HudMapPage; prototipin «Göl Vadisi»): aynı kamera ikinci bir kare daha çizer, bu kez VALLEY_SIZE metrelik
## vadiyi (dünyanın arazisi, ormanı, gölü; dağ halkası dışarıda kalır) VALLEY_PX'e: valley_texture, valley_rect. Atlas bu iki görüntüyü
## evin (homes) çevresine yatırır; daha uzağı kabartmadır.
##   var spec := WorldMap.camp_spec(world, player)          # ya da WorldMap.ordos_spec(ordos)
##   var map: WorldMap = await WorldMap.bake(self, spec)
##   map.uv(Vector2(x, z))                                   # haritada 0..1

## Kameranın zeminden yüksekliği (m) ve uzak kesimi.
const CAMERA_HEIGHT := 400.0
const CAMERA_FAR := 1200.0
## Metre başına piksel ve kenarın sınırları (kampın 188 m'lik alanı ≈10,9, Ordos'un 268 m'lik alanı ≈7,6 px/m'ye iner: tam ekran
## haritada okunur; mini haritaya ≈3 px/m yeter).
const PX_PER_M := 11.0
const MIN_PX := 256
const MAX_PX := 2048
## Haritanın çizilen alanı: yürünür dairenin yarıçapının REACH katı ve MARGIN payı (m). Kitabın HARİTA sayfası üst menünün altını
## kenardan kenara kaplar (HudMapPage): yürünür alanın çevresi de görünür, pişirilen alanın kenarı bulutların altında kalır.
const REACH := 2.0
const MARGIN := 18.0
## Yedeğin ve haritanın dışının rengi (parşömen).
const PAPER := Color(0.66, 0.55, 0.36)
## Referansın mini haritasının parlaklığı (luma ortalaması ve standart sapması; docs/media/review/hud_referans.webp).
const TARGET_LUMA := 0.5
const TARGET_SPREAD := 0.085
## Vadinin görüntüsü (atlasın gerçek düzeyi): alanın kenarı (m), piksel, kameranın yüksekliği ve uzak kesimi (dağların tepesi
## görüntüye girsin, gök kubbesi girmesin).
const VALLEY_SIZE := 3600.0
const VALLEY_PX := 2048
const VALLEY_CAMERA_HEIGHT := 2400.0
const VALLEY_FAR := 4800.0
## Pişmiş görüntüyü dosyaya da yazmak için geliştirme argümanı (--map-out=klasör).
const OUT_ARG := "--map-out="
## Pişirmenin bir çizimi en çok bu kadar süreç karesi bekler (çizim gelmezse yedek görüntü).
const DRAW_WAIT_FRAMES := 90

var key := ""
var texture: Texture2D
## Dünyadaki alan (x, z; metre): position = kuzeybatı köşe.
var rect := Rect2(Vector2(-64.0, -64.0), Vector2(128.0, 128.0))
var title := ""
var subtitle := ""
## Yer adları: [{name, at: Vector2(x, z)}].
var places: Array = []
## Yürünür alan (büyük haritanın halkası onu çevreler).
var area_center := Vector2.ZERO
var area_radius := 40.0
## Dikdörtgen yürünür alan (Kışlak; boşsa yürünür alan dairedir).
var area_box := Rect2()
## Gerçekten çizildi mi (başsızda yedek: false)?
var baked := false
## Haritanın renk ayarı (hud_map.gdshader): pişmiş görüntünün ortalama parlaklığı ve yayılımı referansın mini haritasına çekilir
## (gece kampı da gündüz Ordos'u da aynı boyalı harita tonunda okunur): kazanç, karşıtlık ve dayanak rengi.
var exposure := 1.0
var contrast := 1.0
var pivot := Color(0.5, 0.5, 0.5)
## Vadinin görüntüsü (yoksa null: başsızda, yedekte) ve dünyadaki alanı (m), renk ayarı (measure'ın üçlüsü).
var valley_texture: Texture2D
var valley_rect := Rect2()
var valley_exposure := 1.0
var valley_contrast := 1.0
var valley_pivot := Color(0.5, 0.5, 0.5)

static var _cache: Dictionary = {}
static var _fallback: Texture2D


## Dünya noktasının haritadaki yeri (0..1; saf).
func uv(xz: Vector2) -> Vector2:
	return (xz - rect.position) / rect.size


## Haritadaki yerin dünya noktası (saf).
func world_xz(p_uv: Vector2) -> Vector2:
	return rect.position + p_uv * rect.size


## Kampın haritası: oyun alanı dairesi (PlayerController.play_area_*), ocak, ahır, yurtlar ve göle bakan yamaç.
static func camp_spec(world: Node3D, player: PlayerController) -> Dictionary:
	var center := player.play_area_center if player else Vector2.ZERO
	var radius := player.play_area_radius if player else 38.0
	var places: Array = []
	for pair: Array in [["Ocak", ^"Camp/Campfire"], ["Ahır", ^"Camp/Stable"], ["Yurtlar", ^"Camp/YurtLeft"]]:
		var n := world.get_node_or_null(pair[1]) as Node3D if world else null
		if n:
			places.append({"name": pair[0], "at": JourneyFlags.xz_in(world, n)})
	var lake := CampTour.lake_view_point(center)
	places.append({"name": "Göl", "at": lake})
	return {
		"key": "camp", "title": "Göl Obası", "subtitle": "Bozkırda bir kamp", "center": center,
		"radius": radius, "places": places, "hide": [],
	}


## Ordos'un haritası (Çocukluk): yürünür alan (OrdosWorld.play_area) ve sahnenin yerleri; sürü ve av gizlenir.
static func ordos_spec(ordos: Node3D) -> Dictionary:
	var area: Dictionary = ordos.call(&"play_area") if ordos and ordos.has_method(&"play_area") else {}
	var places: Array = []
	for pair: Array in [["Lan Hatun'un yurdu", "lan_stand"], ["Ağıl", "pen_inside"], ["Taş", "race_stone"], ["Çayır", "meadow"],
			["Sayım hattı", "count_point"], ["Teoman'ın otağı", "teoman_door"]]:
		var at: Variant = ordos.call(&"marker", pair[1]) if ordos and ordos.has_method(&"marker") else Vector3.INF
		if at is Vector3 and at != Vector3.INF:
			places.append({"name": pair[0], "at": Vector2((at as Vector3).x, (at as Vector3).z)})
	var hide: Array = []
	var site: Object = ordos.call(&"childhood") if ordos and ordos.has_method(&"childhood") else null
	if site:
		for prop in [&"herd", &"game"]:
			var n: Variant = site.get(prop)
			if n is Node3D:
				hide.append(n)
	return {
		"key": "ordos", "title": "Ordos", "subtitle": "Teoman'ın güz otlağı", "center": area.get("center", Vector2(26.0, 10.0)),
		"radius": float(area.get("radius", 58.0)), "places": places, "hide": hide,
	}


## Tepeden dik bakan kameranın dönüşümü (saf): merkezin height metre üstünde, aşağı bakar; ekranın yukarısı kuzey (-Z), sağı doğu (+X).
static func top_down_transform(center: Vector2, height: float) -> Transform3D:
	return Transform3D(Basis.looking_at(Vector3.DOWN, Vector3(0.0, 0.0, -1.0)), Vector3(center.x, height, center.y))


## Haritanın alanı (saf): yarıçapın REACH katı ve MARGIN payı, kare.
static func area_rect(center: Vector2, radius: float) -> Rect2:
	var half := radius * REACH + MARGIN
	return Rect2(center - Vector2(half, half), Vector2(half, half) * 2.0)


## Pişirilmiş haritası varsa (aynı anahtar) onu döner.
static func cached(p_key: String) -> WorldMap:
	return _cache.get(p_key) as WorldMap


static func forget(p_key: String) -> void:
	_cache.erase(p_key)


## Pişirmeden, yedek dokuyla haritası (saf; pişirme bitene dek ve başsızda).
static func bake_fallback(spec: Dictionary) -> WorldMap:
	var map := WorldMap.new()
	map.key = str(spec.get("key", ""))
	map.title = str(spec.get("title", ""))
	map.subtitle = str(spec.get("subtitle", ""))
	map.places = spec.get("places", [])
	map.area_center = spec.get("center", Vector2.ZERO)
	map.area_radius = float(spec.get("radius", 40.0))
	map.rect = area_rect(map.area_center, map.area_radius)
	# Dikdörtgen yürünür alan (Kışlak: 1.400 × 1.050 m'nin kenar payı içi; MapWorld.hud_map_spec «box»): harita onu MARGIN payla kapsayan
	# karedir; daire (area_radius) dikdörtgeni çevreleyen yarı köşegendir (atlasın halkası dairedir).
	var box: Rect2 = spec.get("box", Rect2()) if spec.get("box") is Rect2 else Rect2()
	if box.has_area():
		map.area_box = box
		map.area_center = box.get_center()
		map.area_radius = box.size.length() * 0.5
		var side := maxf(box.size.x, box.size.y) + MARGIN * 2.0
		map.rect = Rect2(map.area_center - Vector2.ONE * side * 0.5, Vector2.ONE * side)
	map.texture = fallback_texture()
	return map


## Haritayı pişirir (iki kare bekler); host ağaçta olmalı. Başsızda ve host yoksa yedek döner. extra_hide: ayrıca gizlenecekler.
static func bake(host: Node, spec: Dictionary, extra_hide: Array = []) -> WorldMap:
	var map := bake_fallback(spec)
	if host == null or not host.is_inside_tree() or DisplayServer.get_name() == "headless":
		return map
	var px := clampi(int(map.rect.size.x * PX_PER_M), MIN_PX, MAX_PX)
	var vp := SubViewport.new()
	vp.name = "MapBake"
	vp.size = Vector2i(px, px)
	vp.own_world_3d = false
	vp.transparent_bg = false
	vp.msaa_3d = Viewport.MSAA_4X
	vp.positional_shadow_atlas_size = 0
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.size = map.rect.size.y
	cam.near = 1.0
	cam.far = CAMERA_FAR
	cam.environment = _environment()
	cam.attributes = CameraAttributesPractical.new()
	# Dik bakış: kamera ağaca girmeden önce yerleşir (SubViewport bir Node3D değildir: yerel dönüşüm dünyadakidir); kuzey yukarıda.
	var c := map.rect.get_center()
	cam.transform = top_down_transform(c, CAMERA_HEIGHT)
	vp.add_child(cam)
	host.add_child(vp)
	cam.current = true
	var hidden: Array[Node3D] = []
	for n: Variant in (spec.get("hide", []) as Array) + extra_hide:
		if n is Node3D and is_instance_valid(n) and (n as Node3D).visible:
			(n as Node3D).visible = false
			hidden.append(n)
	# Arazi parçalarının aralık payı pişirme boyunca kapalı (MapWorld.set_range_margins): yeni görüntü alanında düzeyler arasında ölü bant
	# kalmasın (kâğıt rengi kareler).
	var ranges: Callable = spec.get("ranges", Callable()) if spec.get("ranges") is Callable else Callable()
	if ranges.is_valid():
		ranges.call(false)
	# Kamera ve gizlemeler bir karede çizim sunucusuna geçer, çizim ondan sonraki karededir.
	await host.get_tree().process_frame
	if is_instance_valid(cam):
		cam.global_transform = top_down_transform(c, CAMERA_HEIGHT)
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	# Çizim gelmezse (pencere çizmiyor, ana düğüm ağaçtan çıktı) pişirme beklemez: gizlenenler (oyuncu, atlar) geri gelir, harita yedektir;
	# yoksa iç haritaya giriş (main._enter_map) burada kalır, kare Mete'siz ve takip etmeyen kamerayla donardı.
	var drawn := await _await_draws(host, 2)
	var img: Image = vp.get_texture().get_image() if drawn and is_instance_valid(vp) else null
	# Vadi: aynı kamera daha yükseğe ve daha geniş alana (VALLEY_SIZE), bir kare daha.
	var valley: Image = null
	if drawn and is_instance_valid(vp) and is_instance_valid(cam):
		vp.size = Vector2i(VALLEY_PX, VALLEY_PX)
		cam.size = VALLEY_SIZE
		cam.far = VALLEY_FAR
		cam.global_transform = top_down_transform(c, VALLEY_CAMERA_HEIGHT)
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
		if await _await_draws(host, 2):
			valley = vp.get_texture().get_image() if is_instance_valid(vp) else null
	for n in hidden:
		if is_instance_valid(n):
			n.visible = true
	if ranges.is_valid():
		ranges.call(true)
	if is_instance_valid(vp):
		vp.queue_free()
	if img == null or img.is_empty():
		map.texture = fallback_texture()
		return map
	img.convert(Image.FORMAT_RGBA8)
	map.measure(img)
	_maybe_save(img, map.key)
	img.generate_mipmaps()
	map.texture = ImageTexture.create_from_image(img)
	map.baked = true
	if valley != null and not valley.is_empty():
		valley.convert(Image.FORMAT_RGBA8)
		var tone := tone_of(valley)
		map.valley_exposure = tone[0]
		map.valley_contrast = tone[1]
		map.valley_pivot = tone[2]
		_maybe_save(valley, map.key + "_valley")
		valley.generate_mipmaps()
		map.valley_texture = ImageTexture.create_from_image(valley)
		map.valley_rect = valley_area(c)
	if not map.key.is_empty():
		_cache[map.key] = map
	return map


## count çizimi (RenderingServer.frame_post_draw) bekler, en çok DRAW_WAIT_FRAMES süreç karesi; host ağaçtan çıkarsa bırakır. Döner: çizildi mi.
static func _await_draws(host: Node, count: int) -> bool:
	var seen := [0]
	var on_draw := func() -> void: seen[0] += 1
	RenderingServer.frame_post_draw.connect(on_draw)
	var frames := 0
	while seen[0] < count and frames < DRAW_WAIT_FRAMES and is_instance_valid(host) and host.is_inside_tree():
		await host.get_tree().process_frame
		frames += 1
	RenderingServer.frame_post_draw.disconnect(on_draw)
	if seen[0] < count:
		push_warning("[world_map] harita pişmedi: %d karede %d çizim (yedek görüntü)" % [frames, seen[0]])
	return seen[0] >= count


## Vadinin alanı (saf): merkezin çevresinde VALLEY_SIZE kenarlı kare (m).
static func valley_area(center: Vector2) -> Rect2:
	return Rect2(center - Vector2(VALLEY_SIZE, VALLEY_SIZE) * 0.5, Vector2(VALLEY_SIZE, VALLEY_SIZE))


## Görüntünün parlaklığını ölçer ve renk ayarını kurar (64 × 64 küçük kopyadan; bir kez).
func measure(img: Image) -> void:
	var tone := tone_of(img)
	exposure = tone[0]
	contrast = tone[1]
	pivot = tone[2]


## Görüntünün renk ayarı (saf): [kazanç, karşıtlık, dayanak rengi]; ortalama parlaklık ve yayılım referansın mini haritasına çekilir.
static func tone_of(img: Image) -> Array:
	var small := img.duplicate() as Image
	small.resize(64, 64, Image.INTERPOLATE_BILINEAR)
	var sum := Color(0, 0, 0, 0)
	var lumas := PackedFloat32Array()
	lumas.resize(64 * 64)
	for y in 64:
		for x in 64:
			var c := small.get_pixel(x, y)
			sum += c
			lumas[y * 64 + x] = c.get_luminance()
	var n := 64.0 * 64.0
	var mean := Color(sum.r / n, sum.g / n, sum.b / n)
	var lm := 0.0
	for l in lumas:
		lm += l
	lm /= n
	var var_sum := 0.0
	for l in lumas:
		var_sum += (l - lm) * (l - lm)
	var spread := sqrt(var_sum / n)
	var k := clampf(TARGET_LUMA / maxf(lm, 0.02), 0.35, 3.0)
	return [k, clampf(TARGET_SPREAD / maxf(spread * k, 0.005), 0.8, 2.2), Color(mean.r * k, mean.g * k, mean.b * k)]


## --map-out=klasör: pişmiş görüntü <klasör>/map_<anahtar>.png olarak yazılır (geliştirme; belge karesi).
static func _maybe_save(img: Image, p_key: String) -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(OUT_ARG):
			var dir := a.substr(OUT_ARG.length())
			DirAccess.make_dir_recursive_absolute(dir)
			img.save_png(dir.path_join("map_%s.png" % p_key))


## Başsız ve çizilemeyen durumun haritası: parşömen, kenara doğru koyulaşan (küçük; oturum boyunca bir kez üretilir).
static func fallback_texture() -> Texture2D:
	if _fallback:
		return _fallback
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var d := Vector2(x - 31.5, y - 31.5).length() / 45.0
			img.set_pixel(x, y, PAPER.darkened(clampf(d - 0.3, 0.0, 0.4) * 0.5))
	_fallback = ImageTexture.create_from_image(img)
	return _fallback


## Pişirme kamerasının ortamı: düz zemin rengi, nötr ortam ışığı, sis yok, renk ayarı yok.
static func _environment() -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = PAPER
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1.0, 0.98, 0.94)
	env.ambient_light_energy = 0.6
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.85
	env.fog_enabled = false
	env.volumetric_fog_enabled = false
	env.glow_enabled = false
	env.ssao_enabled = false
	env.ssr_enabled = false
	env.sdfgi_enabled = false
	return env
