class_name PrologueCamp
extends CineScene
## Önsöz'ün ilk sahnesi «Kamp ve şarkı» (K68; story.md §3 satır 0a–0d; godot.md §3.6). Kamp dünyasında, ana
## menünün kamerasıyla oynar; çizelgesi data/cine/prologue_camp.json'dadır (segment kimliği camp):
##   0,0  menü yazıları söner (Main), menü müziği 2 sn'de camp_bard dronuna iner, rüzgâr 0–6 sn'de yükselir;
##        kamera ozana yaklaşmaz, menü kadrajından (K98: ateşe 26,4 m, 38°, 36°) WIDE'a geri çekilir (shot pullback:
##        MenuCamera.fly_to(WIDE, 6 sn, 41,76°); ateşe 40 m, 9°, 1,52 kat; uzaklık hiç azalmaz, ufuk 3,5 sn'de kareye girer). WIDE
##        kullanıcının onayladığı karedir (K68), değişmedi.
##   4,0  yıldızlar 2 sn'de %35'e açılır (sky.gdshader star_brightness; gök kubbesi ilk kez görünür), ay yoktur.
##   4,2  ozan kopuzu kaldırır (1,1 sn; KopuzPlay).
##   6,0  kamera durur ve WIDE'da nefes alır (shot hold: start_drift, WIDE_FOV), şarkı başlar (act0.bard.song; Voice'ta 2B,
##        ozanın yönüne ≤%10), Çocuk ozana döner.
##   8,3  ozanın kolu kaydın vuruş ızgarasına bağlanır (strum; 1,2534 tur/sn, faz şarkının saatinden).
##   28,25 dron şarkının son 4,6 sn'sinde söner.
##   28,64 son vuruş: avuç tellerde kalır (palm_mute).
##   32,85 şarkı biter; 3 sn alçak sessizlik, 2 sn kararma, 1 sn kara (rüzgâr −40 dB'te sürer).
## Kol çekim 3104'ün zarfına ve vuruş ızgarasına bağlıdır (K95), şarkının başına ve sonuna değil. Baştaki sessizlik dosyadan
## kesildi (0,863 sn) ama kopuz 3,9 sn'de yükselerek girer: ilk duyulur vuruş şarkının 2,31. sn'sidir (rüzgâr ve dronun üstüne
## o zaman çıkar). Plan «one palm slap on the strings stops it dead» der: son vuruş 22,62. sn'dedir, dosyanın kalan 4,2 sn'si
## sönen kuyruktur. Bu yüzden strum song+2,3, mute song+22,64: ızgaranın o iki vuruşa en yakın noktaları (el orada telleri
## geçer, sıçramaz), kol sessizde vurmaz. Dron kuralı (son 4,6 sn) kalır: son vuruştan sonra ≈1,5 sn duyulur, kuyruğu o
## doldurur; kulak onayı kullanıcınındır. Çekim değişirse bu sayılar ölçüden yeniden alınır (test_prologue_camp).
## Gece ışığı menünündür, saat okunmaz (K20, K76). setup() gök tekdüzenlerinin (yıldız, ay), su parıltısının,
## sisin, menü kamerasının, Çocuk'un bakışının ve kopuzun anlık görüntüsünü alır; restore() hepsini geri yazar:
## menüye dönüş karesi değişmez (gölgelendiricilere dokunulmaz, yalnız tekdüzen değerleri değişir). Kamp segmenti
## dizinin sonuncusuysa ya da sinema atlandıysa rüzgâr katmanı da söner (yoksa mit sineması onu sürdürür).

## Gökte yıldız katmanı ve ayın tekdüzenleri (sky.gdshader); ay bu gece yarısından sonra doğar (story.md §3):
## çizilmez. Disk ve hale kapanır, ayın yönü doğu ufkunun altına iner (henüz doğmamış ay): WIDE karesinde ayın
## halesi, ay yönündeki bulut açıklığı ve bulutların aya bakan parlak kenarı da kalmaz. Işık menünündür (MoonLight
## ayrı bir yöndür, K20, K76); gölgelendiriciye dokunulmaz.
const STAR_PARAM := "star_brightness"
const MOON_HIDDEN := {"moon_radius": 0.0001, "moon_glow_strength": 0.0, "moon_glow_color": Color(0.0, 0.0, 0.0),
	"moon_direction": Vector3(0.9, -0.42, 0.12)}
## Gölün ay parıltısı (water.gdshader): ay yokken parıltı da yoktur.
const GLINT_PARAM := "glint_energy"
## Rüzgâr katmanı (AudioManager ortam katmanı) ve söndüğü düzey.
const WIND_LAYER := "wind_steppe"
const SILENT_DB := -80.0
const WIND_OUT := 0.5
## Çocuğun ozana dönüşünün varsayılan süresi (çizelge dur verir).
const LOOK_TIME := 1.5

## Sis yoğunluğunun bu sahnedeki çarpanı (1 = menünün sisi). Geri çekilme boyunca bu değere yürür.
@export var fog_scale := 1.0

var camp: Node3D
var camera: MenuCamera
var npcs: CampNpcs
var play: KopuzPlay

var _sky: ShaderMaterial
var _water: ShaderMaterial
var _env: Environment
var _snapshot := {}
var _song_start := -1.0
var _tweens: Array[Tween] = []
var _restored := false


func setup(p_ctx: Dictionary) -> void:
	super.setup(p_ctx)
	camp = p_ctx.get("world") as Node3D
	if camp == null:
		camp = p_ctx.get("camp") as Node3D
	camera = p_ctx.get("menu_camera") as MenuCamera
	npcs = camp.get_node_or_null(^"Camp/CampNpcs") as CampNpcs if camp else null
	_sky = PrologueCamp.sky_material(camp)
	_water = PrologueCamp.water_material(camp)
	var env_node := camp.get_node_or_null(^"WorldEnvironment") as WorldEnvironment if camp else null
	_env = env_node.environment if env_node else null
	_snapshot = snapshot()
	# Ay yoktur; yıldızlar 4,0 sn'de açılır (gök menü karesinde görünmez, geri çekilirken kareye girer).
	if _sky:
		for param: String in MOON_HIDDEN:
			_sky.set_shader_parameter(param, MOON_HIDDEN[param])
		_sky.set_shader_parameter(STAR_PARAM, 0.0)
	if _water:
		_water.set_shader_parameter(GLINT_PARAM, 0.0)
	if npcs and npcs.get_bard() and npcs.get_kopuz():
		play = KopuzPlay.attach(npcs.get_bard(), npcs.get_kopuz())
	set_process(true)


## Şu anki durumun anlık görüntüsü: gök ve su tekdüzenleri (atanmamışsa null: gölgelendiricinin varsayılanı), sis,
## kamera, Çocuk'un bakışı, kopuzun dönüşümü.
func snapshot() -> Dictionary:
	var snap := {}
	if _sky:
		var sky := {}
		for param: String in [STAR_PARAM] + MOON_HIDDEN.keys():
			sky[param] = _sky.get_shader_parameter(param)
		snap["sky"] = sky
	if _water:
		snap["glint"] = _water.get_shader_parameter(GLINT_PARAM)
	if _env:
		snap["fog_density"] = _env.fog_density
		snap["volumetric_fog_density"] = _env.volumetric_fog_density
	if camera:
		snap["camera"] = {"transform": camera.global_transform, "fov": camera.fov, "keep_aspect": camera.keep_aspect,
			"drifting": camera.drifting, "has_drift_base": camera.has_drift_base, "drift_base": camera.drift_base,
			"drift_fov": camera.drift_fov}
	var child := _child()
	if child:
		snap["child_face_point"] = child.face_point
	var kopuz := npcs.get_kopuz() if npcs else null
	if kopuz:
		snap["kopuz"] = kopuz.transform
	return snap


func on_shot(shot_name: String, ev: Dictionary) -> void:
	match shot_name:
		"pullback":
			_pullback(ev)
		"hold":
			if camera:
				camera.start_drift(MenuCamera.wide_transform(), false, MenuCamera.WIDE_FOV)


func on_event(ev: Dictionary) -> void:
	var gone := elapsed(ev)
	match str(ev.get("type", "")):
		"stars":
			_stars(float(ev.get("share", 0.35)), float(ev.get("dur", 0.0)), gone)
		"raise_kopuz":
			if play:
				var dur := float(ev.get("dur", KopuzPlay.LIFT_TIME))
				if gone >= dur:
					play.set_lift(1.0)
				else:
					play.set_lift(gone / dur)
					play.lift(dur)
		"song":
			_song_start = float(ev["t"])
			_update_song_clock()
		"child_look":
			_child_look(float(ev.get("dur", LOOK_TIME)), gone)
		"strum":
			if play:
				play.start_strum()
		"palm_mute":
			if play:
				play.palm_mute()


func _process(_delta: float) -> void:
	_update_song_clock()


## Segmentin sonunda ya da atlanınca: dokunulan her şey setup'taki hâline döner (bir kez).
func restore() -> void:
	if _restored:
		return
	_restored = true
	set_process(false)
	for tween in _tweens:
		if tween.is_valid():
			tween.kill()
	_tweens.clear()
	if play and is_instance_valid(play):
		play.detach()
	play = null
	var snap := _snapshot
	if _sky and snap.has("sky"):
		var sky: Dictionary = snap["sky"]
		for param: String in sky:
			_sky.set_shader_parameter(param, sky[param])
	if _water and snap.has("glint"):
		_water.set_shader_parameter(GLINT_PARAM, snap["glint"])
	if _env and snap.has("fog_density"):
		_env.fog_density = snap["fog_density"]
		_env.volumetric_fog_density = snap["volumetric_fog_density"]
	if camera and snap.has("camera"):
		var cam: Dictionary = snap["camera"]
		camera.stop_flight()
		camera.clear_drift()
		if bool(cam["has_drift_base"]):
			camera.drift_base = cam["drift_base"]
			camera.has_drift_base = true
			camera.drift_fov = float(cam.get("drift_fov", -1.0))
		camera.keep_aspect = cam["keep_aspect"]
		camera.fov = cam["fov"]
		camera.global_transform = cam["transform"]
		camera.drifting = cam["drifting"]
	var child := _child()
	if child and snap.has("child_face_point"):
		child.face_point = snap["child_face_point"]
	var kopuz := npcs.get_kopuz() if npcs else null
	if kopuz and snap.has("kopuz"):
		kopuz.transform = snap["kopuz"]
	if _sequence_ends():
		var audio := ctx.get("audio") as CineAudio
		if audio:
			audio.handle({"type": "ambience", "id": WIND_LAYER, "db": SILENT_DB, "dur": WIND_OUT})


## Kamp dünyasının gökyüzü malzemesi (yoksa null; saf).
static func sky_material(world: Node) -> ShaderMaterial:
	var env_node := world.get_node_or_null(^"WorldEnvironment") as WorldEnvironment if world else null
	if env_node == null or env_node.environment == null or env_node.environment.sky == null:
		return null
	return env_node.environment.sky.sky_material as ShaderMaterial


## Gölün malzemesi (yoksa null; saf).
static func water_material(world: Node) -> ShaderMaterial:
	var water := world.get_node_or_null(^"Water") as Water if world else null
	return water.material if water else null


## Gölgelendiricideki bir float tekdüzenin varsayılanı (saf): çizim sunucusundan, okunamazsa (başsız sürücü)
## kaynak koddaki «uniform float ad … = değer;» satırından; bulunmazsa 0.
static func shader_default(shader: Shader, param: String) -> float:
	if shader == null:
		return 0.0
	var value: Variant = RenderingServer.shader_get_parameter_default(shader.get_rid(), param)
	if (value is float or value is int) and float(value) != 0.0:
		return float(value)
	var re := RegEx.create_from_string("uniform\\s+float\\s+%s\\s*(?::[^=;]*)?=\\s*([-+]?[0-9]*\\.?[0-9]+)" % param)
	var m := re.search(shader.code)
	return m.get_string(1).to_float() if m else 0.0


## Geri çekilme: menü kadrajından WIDE'a (ileri sarmada yolun o anından devam eder).
func _pullback(ev: Dictionary) -> void:
	if camera == null:
		return
	var duration := float(ev.get("dur", MenuCamera.PULLBACK_TIME))
	var gone := elapsed(ev)
	var target := MenuCamera.wide_transform()
	var vfov := _wide_vfov()
	if gone >= duration:
		camera.stop_flight()
		camera.drifting = false
		camera.keep_aspect = Camera3D.KEEP_HEIGHT
		camera.fov = vfov
		camera.global_transform = target
		_fog_to(fog_scale, 0.0)
		return
	if gone > 0.0:
		camera.global_transform = MenuCamera.pullback_pose(camera.global_transform, gone, duration)
	camera.fly_to(target, duration - gone, vfov)
	_fog_to(fog_scale, duration - gone)


## WIDE'ın dikey görüşü bu ekranda: menü gibi, dar ekranda yatay açı korunur.
func _wide_vfov() -> float:
	var size := camera.get_viewport().get_visible_rect().size if camera.is_inside_tree() else Vector2.ZERO
	var aspect := size.x / size.y if size.y > 0.0 else camera.design_aspect
	var fit := MenuCamera.fit_fov(MenuCamera.WIDE_FOV, camera.design_aspect, aspect)
	return MenuCamera.vertical_fov_of(fit["fov"], fit["keep"], aspect)


func _stars(share: float, duration: float, gone: float) -> void:
	if _sky == null:
		return
	var target := share * _full_stars()
	if duration <= 0.0 or gone >= duration:
		_sky.set_shader_parameter(STAR_PARAM, target)
		return
	var from := lerpf(0.0, target, gone / duration)
	_sky.set_shader_parameter(STAR_PARAM, from)
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void: _sky.set_shader_parameter(STAR_PARAM, v), from, target, duration - gone)
	_tweens.append(tween)


func _fog_to(scale: float, duration: float) -> void:
	if _env == null or not _snapshot.has("fog_density") or is_equal_approx(scale, 1.0):
		return
	var fog: float = float(_snapshot["fog_density"]) * scale
	var vol: float = float(_snapshot["volumetric_fog_density"]) * scale
	if duration <= 0.0:
		_env.fog_density = fog
		_env.volumetric_fog_density = vol
		return
	var tween := create_tween().set_parallel()
	tween.tween_property(_env, ^"fog_density", fog, duration).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_env, ^"volumetric_fog_density", vol, duration).set_trans(Tween.TRANS_SINE)
	_tweens.append(tween)


## Çocuk ozana döner: bakış noktası ateşten ozana yürür.
func _child_look(duration: float, gone: float) -> void:
	var child := _child()
	var bard := npcs.get_bard() if npcs else null
	if child == null or bard == null:
		return
	var from: Vector3 = _snapshot.get("child_face_point", child.face_point)
	var to := bard.global_position
	if duration <= 0.0 or gone >= duration:
		child.face_point = to
		return
	child.face_point = from.lerp(to, gone / duration)
	var tween := create_tween()
	tween.tween_property(child, ^"face_point", to, duration - gone).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tweens.append(tween)


## Yıldızların tam parlaklığı: setup'ta (yıldızlar kapatılmadan önce) malzemedeki değer, yoksa gölgelendiricinin.
func _full_stars() -> float:
	var sky: Dictionary = _snapshot.get("sky", {})
	var own: Variant = sky.get(STAR_PARAM)
	if own is float or own is int:
		return float(own)
	return PrologueCamp.shader_default(_sky.shader, STAR_PARAM) if _sky else 0.0


func _update_song_clock() -> void:
	if play and _song_start >= 0.0:
		play.song_time = maxf(cine_time() - _song_start, 0.0)


func _child() -> CharacterAvatar:
	return npcs.get_node_or_null(^"Child") as CharacterAvatar if npcs else null


## Dizi bu segmentle bitiyor mu (atlama, durdurma ya da son segment)?
func _sequence_ends() -> bool:
	var h := host()
	if h == null or h.is_skipping() or not h.is_playing() or h.runner == null or h.runner.done:
		return true
	var timeline := h.timeline()
	var seg: Dictionary = ctx.get("segment", {})
	if timeline == null or seg.is_empty():
		return true
	return int(seg.get("index", 0)) >= timeline.segments.size() - 1
