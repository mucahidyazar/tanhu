extends Node3D
## Geliştirme sahnesi (K58; godot.md §8.5): Mete'nin pelerininin okunurluk kareleri.
##
## Bir ışık durağı (data/character/cape_light_stops.json: kampın ay ışığı ve ateşi, Ordos'un sabahı ve gün ortası, time.md
## §5.3 tablosundan tan, ikindi ve akşam; K101), oyuncunun kılığıyla Mete (CharacterAvatar: Kışlak Kaftanı, Kışlak Pelerini, profilin boyası; oyundaki
## oyuncuyla aynı malzeme yolu) ve çevresinde kalabalık (crowd_hun_*), oyunun takip kamerası (FollowCamera: 38°, 28 m; K98) ve
## boyalı süzgeç (PainterlyOverlay) ile dünyanın renk ayarı (ColorGrade). Mete kuzeye bakar, kamera arkasındadır (oyunun
## varsayılanı): pelerin görünür.
##
## Işık durakları (v3, sun-light): oyunun altı ışık durağı (data/time/light_stops.json) ana kampın ölçüm dakikalarında (11 Nisan MÖ
## 209: gece 23:00, tan 05:10, sabah 07:07, öğle 11:45, ikindi 13:40, akşam 18:38) ve gece ateş başı; değerler LightStops.probe_sample'dan
## (ışığın yönü ve k gerçek güneşten, ayın yerinden ya da gök yönünden), --export-stops ile cape_light_stops.json'a yazılır.
## Ortamın renk ayarı durağınkidir (doygunluk ve karşıtlık; gece menününki) ve durağın gece payıyla (grade_night) ColorGrade.
##
## Argümanlar (Godot ... -- ):
##   --stop=<kimlik>        ışık durağı (varsayılan noon)
##   --mode=crowd|dyes      crowd: Mete ve kalabalık (P4); dyes: altı Mete yan yana, her biri bir boyayla (başının üstünde adı)
##   --distance=28          kameranın uzaklığı (m); --pitch=38, --yaw=derece (0: kamera güneyde, kuzeye bakar)
##   --dye=N                Mete'nin boyası (crowd kipinde; 0 Göl Mavisi)
##   --key                  pelerin anahtar renginde (#00ff00) çizilir: aynı pozun iki karesinin farkı pelerinin lekesidir
##                          (tools/palette_compare.py --blob kare.png anahtar.png)
##   --cape_hex=#rrggbb     aday boya: pelerin bu renkte çizilir (veriye yazmadan denemek için; anahtar karesi aynıdır)
##   --crowd=28             kalabalığın kişi sayısı (Mete'nin çevresinde 10 × 8 m'de, aralarında en az 0,95 m)
##   --batch=/mutlak/klasör tek koşuda anahtar karesi ve beş boyanın kareleri (<durak>_<uzaklık>_<key|boya>.png); --window=1920x1080 ve
##                          --freeze-time=12 gibi (kendi başına donar); bitince kapanır. palette_compare.py --blob her boyayı anahtarla ölçer.
##   --export-stops         durakları light_stops.json'dan çözüp data/character/cape_light_stops.json'a yazar ve kapanır
## Örnek: tools/capture.sh /tmp/p4.png 150 --freeze-time=12 --window=1920x1080 --scene=res://scenes/dev/cape_lineup.tscn --stop=camp_night

const CaptureTool := preload("res://scripts/dev/capture.gd")
const CAMP_SCENE := "res://scenes/world/world.tscn"
## Ölçümün durakları (sırayla): oyunun altı durağı ve gece ateş başı (kampın ateşi, campfire.gd: 3,3 enerji, 8 m).
const MEASURE_STOPS: Array[Dictionary] = [
	{"id": "night", "name": "Gece (kamp, ay batık)", "k20": "night"},
	{"id": "night_fire", "name": "Gece, ateş başı", "k20": "night", "light_stop": "night",
		"fire": {"color": [1.0, 0.74, 0.42], "energy": 3.3, "range": 8.0, "distance": 2.6}},
	{"id": "dawn", "name": "Tan", "k20": "dawn"},
	{"id": "morning", "name": "Sabah", "k20": "morning"},
	{"id": "noon", "name": "Öğle", "k20": "noon"},
	{"id": "golden", "name": "İkindi", "k20": "golden"},
	{"id": "dusk", "name": "Akşam", "k20": "dusk"},
]
const PAINTERLY := preload("res://scenes/ui/painterly_overlay.tscn")
const STOPS_PATH := "res://data/character/cape_light_stops.json"
const CROWD_MODELS: Array[String] = ["crowd_hun_man", "crowd_hun_woman", "crowd_hun_rider"]
const KEY_COLOR := Color(0.0, 1.0, 0.0)
## Zemin: kuru bozkır otu (sanat-animasyon.md §10'un ot rengi).
const GROUND_COLOR := Color("#8fa058")
## Kampın ay ışığının yönü (world.gd: azimut 140°, yükseklik 50°).
const CAMP_LIGHT_AZIMUTH := 140.0
const CAMP_LIGHT_ELEVATION := 50.0

var _camera: Camera3D
var _rig: SkyRig
var _env: WorldEnvironment
var _metes: Array[CharacterAvatar] = []


func _ready() -> void:
	var args := CaptureTool.parse_args(OS.get_cmdline_user_args())
	if args.has("export-stops"):
		var ok := export_stops(STOPS_PATH)
		print("[cape_lineup] durakları yazdı: %s (%s)" % [STOPS_PATH, ok])
		get_tree().quit(0 if ok else 1)
		return
	var stop := _find_stop(str(args.get("stop", "noon")))
	_build_environment(stop)
	_build_ground()
	var mode := str(args.get("mode", "crowd"))
	if mode == "dyes":
		_build_dye_row()
	else:
		_build_crowd(int(args.get("crowd", 28)), int(args.get("dye", 0)))
	_build_camera(float(args.get("distance", FollowCamera.DEFAULT_DISTANCE)), float(args.get("pitch", FollowCamera.DEFAULT_PITCH_DEG)),
		deg_to_rad(float(args.get("yaw", 0.0))), mode)
	add_child(PAINTERLY.instantiate())
	if args.has("batch"):
		_run_batch(args, stop)
		return
	if args.has("key") or args.has("cape_hex"):
		# Model yüklendikten ve renkler yazıldıktan sonra (aynı karede): yalnız pelerinin rengi değişir. --cape_hex aday
		# bir boyayı veriye yazmadan dener (aynı pozun anahtar karesi yeniden kullanılır).
		var color := KEY_COLOR if args.has("key") else Color.html(str(args.get("cape_hex", "")))
		await get_tree().process_frame
		for mete in _metes:
			for mat in mete.get_materials():
				mat.set_shader_parameter(&"cape_color", color)


func _find_stop(id: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(STOPS_PATH))
	for stop: Dictionary in (parsed as Dictionary).get("stops", []):
		if str(stop.get("id", "")) == id:
			return stop
	push_error("[cape_lineup] ışık durağı yok: %s" % id)
	return {}


func _build_environment(stop: Dictionary) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.62, 0.72) if str(stop.get("grade", "world")) == "world" else Color(0.05, 0.07, 0.14)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 6.0
	env.adjustment_enabled = true
	# Ortamın renk ayarı oyundaki gibi: durağın doygunluğu ve karşıtlığı (light_stops.json), yoksa kampınki (world.tscn).
	var camp_env := _camp_environment()
	if camp_env:
		env.adjustment_contrast = camp_env.adjustment_contrast
		env.adjustment_saturation = camp_env.adjustment_saturation
	var sample_def: Variant = stop.get("sample", {})
	if sample_def is Dictionary:
		env.adjustment_saturation = float((sample_def as Dictionary).get("saturation", env.adjustment_saturation))
		env.adjustment_contrast = float((sample_def as Dictionary).get("contrast", env.adjustment_contrast))
	var grade := ColorGrade.world_night() if str(stop.get("grade", "world")) == "night" else ColorGrade.world()
	grade.apply_to(env)
	_env = WorldEnvironment.new()
	_env.name = "WorldEnvironment"
	_env.environment = env
	add_child(_env)
	var sun := DirectionalLight3D.new()
	sun.name = "SunLight"
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90.0
	add_child(sun)
	_rig = SkyRig.new()
	_rig.name = "SkyRig"
	add_child(_rig)
	var sample: Variant = stop.get("sample", {})
	if sample is String:
		_rig.fix_from(str(stop.get("file", "")), sample)
	else:
		var s: Dictionary = (sample as Dictionary).duplicate(true)
		s["light_dir"] = World.direction_from_angles(float(stop.get("light_azimuth", CAMP_LIGHT_AZIMUTH)),
			float(stop.get("light_elevation", CAMP_LIGHT_ELEVATION)))
		_rig.set_fixed_sample(s)
	var fire: Variant = stop.get("fire")
	if fire is Dictionary:
		var omni := OmniLight3D.new()
		omni.name = "Fire"
		omni.light_color = SkyRig.to_color(fire.get("color", [1, 0.74, 0.42]))
		omni.light_energy = float(fire.get("energy", 3.3))
		omni.omni_range = float(fire.get("range", 8.0))
		# Ateş Mete'nin güney doğusunda, kameranın yanında: pelerine vuran ışığıdır.
		var d := float(fire.get("distance", 2.6))
		omni.position = Vector3(d * 0.6, 0.6, d * 0.8)
		add_child(omni)


## Kampın ortamı (sahneyi kurmadan, sahnenin durumundan).
static func _camp_environment() -> Environment:
	var packed := load(CAMP_SCENE) as PackedScene
	if packed == null:
		return null
	var state := packed.get_state()
	for i in state.get_node_count():
		if str(state.get_node_name(i)) != "WorldEnvironment":
			continue
		for j in state.get_node_property_count(i):
			if str(state.get_node_property_name(i, j)) == "environment":
				return state.get_node_property_value(i, j) as Environment
	return null


## Ölçüm duraklarını oyunun ışık duraklarından çözer ve dosyaya yazar (v3). Döner: yazıldı mı?
static func export_stops(path: String) -> bool:
	var table := LightStops.load_table()
	if table.is_empty():
		return false
	var old: Dictionary = {}
	if FileAccess.file_exists(path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			old = parsed
	var stops: Array = []
	for def: Dictionary in MEASURE_STOPS:
		var light_stop := str(def.get("light_stop", def["id"]))
		var p := LightStops.probe_sample(table, StringName(light_stop))
		if p.is_empty():
			return false
		var lc: Color = p["light_color"]
		var ac: Color = p["ambient_color"]
		var row := {
			"id": def["id"], "name": "%s (%s)" % [def["name"], GameClock.hhmm(float(p["minute"]))], "k20": def["k20"], "light_stop": light_stop,
			"minute": GameClock.hhmm(float(p["minute"])), "s": snappedf(float(p["s"]), 0.0001), "light_k": snappedf(float(p["light_k"]), 0.0001),
			"sample": {
				"light_color": [snappedf(lc.r, 0.0001), snappedf(lc.g, 0.0001), snappedf(lc.b, 0.0001)],
				"light_energy": snappedf(float(p["light_energy"]), 0.0001),
				"ambient_color": [snappedf(ac.r, 0.0001), snappedf(ac.g, 0.0001), snappedf(ac.b, 0.0001)],
				"ambient_energy": snappedf(float(p["ambient_energy"]), 0.0001), "ambient_sky": 0.0,
				"exposure": snappedf(float(p["exposure"]), 0.0001),
				"saturation": snappedf(float(p["saturation"]), 0.0001), "contrast": snappedf(float(p["contrast"]), 0.0001),
			},
			"light_azimuth": snappedf(float(p["light_azimuth"]), 0.01), "light_elevation": snappedf(float(p["light_elevation"]), 0.01),
			"grade": "night" if float(p["grade_night"]) >= 0.5 else "world",
		}
		if def.has("fire"):
			row["fire"] = def["fire"]
		stops.append(row)
	var out := {
		"version": 3,
		"source": "K58, K101; sanat-animasyon.md öneri 4 (P1, P4); time.md §5.3; godot.md §8.5; Yol Haritası sun-light",
		"doc": "Pelerin okunurluğunun ışık durakları (v3, 2026-11-08): oyunun altı ışık durağı (data/time/light_stops.json; night, dawn, morning, noon, golden, dusk) ana kampın ölçüm dakikalarında (light_stops.json probe: 11 Nisan MÖ 209) ve gece ateş başı. Değerler LightStops.probe_sample'dan çözülür (scenes/dev/cape_lineup.tscn --export-stops; test_light_stops.gd dosyanın durakları izlediğini sınar): ışığın gücü durağın değeri × ışık kaynağının çarpanıdır (k: tanda ve akşamda güneş ufukta 0,35, gece ay batık 0,55, gündüz 1), ışığın azimutu ve yüksekliği gerçek güneşten (≥15°), ayın yerinden ya da gök yönünden (az 160°, 55°) gelir. Ortam yalnız renktir (ambient_sky 0): kampta gece göğü %55 karışır, o da aynı koyu mavidir; tanın ve akşamın gölge dolgusu (ambient_color) soğuktur (K101). grade: night ya da world (ColorGrade; durağın gece payı). fire: ateşin karakterden uzaklığı (m) ile OmniLight3D'si (campfire.gd; titreme ortalaması 1). tools/palette_compare.py --cape ve scenes/dev/cape_lineup.tscn bu dosyayı okur. v2 (K101) ölçümü sun-light gelmeden önce kampın gecesi, ateşi, Çocukluk'un Ordos sabahı ve gün ortası ile tablonun tan, ikindi ve akşamıyla yapılmıştı (history).",
		"light_stops": LightStops.PATH,
		"stops": stops,
		"history": old.get("history", [{"version": 2, "at": "2026-11-08", "note": "K101: kamp gecesi ve ateşi (sahneden), Ordos 08:40 ve 11:00, tablonun tan, ikindi ve akşamı (Ordos oranıyla); P1 en kötü 0,068 (Koyu Çivit), P4 Göl Mavisi en kötü 0,065 (tan ve akşam, 40 m)."}]),
	}
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(out, "\t") + "\n")
	return true


## Tek koşuda anahtar ve beş boyanın kareleri (P4): pelerinin rengi değiştirilir, kare çizilince görüntü kaydedilir.
func _run_batch(args: Dictionary, stop: Dictionary) -> void:
	var dir := str(args["batch"])
	DirAccess.make_dir_recursive_absolute(dir)
	# Pencere sahne kurulurken değiştirilemez: bir kare beklenir.
	await get_tree().process_frame
	if args.has("window"):
		var size := str(args["window"]).split("x")
		if size.size() == 2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(Vector2i(int(size[0]), int(size[1])))
	RenderingServer.global_shader_parameter_set(CaptureTool.WORLD_TIME, CaptureTool.freeze_time_from({"freeze-time": args.get("freeze-time", "12")}))
	var variants: Array = [["key", KEY_COLOR]]
	for i in CharacterOptions.count(&"cape_dye"):
		variants.append([CharacterOptions.value_id(&"cape_dye", i), CharacterOptions.cape_tint(CharacterOptions.start_cape(), i)])
	for hex in str(args.get("hexes", "")).split(",", false):
		variants.append([hex.trim_prefix("#"), Color.html(hex)])
	var settle := int(args.get("settle", 150))
	for i in settle:
		await get_tree().process_frame
	print("[cape_lineup] %d kare beklendi, %d kare çekilecek" % [settle, variants.size()])
	# Canlandırmalar durur: anahtar ve boya kareleri aynı pozda olmalı (farkları yalnız pelerinin lekesidir).
	Engine.time_scale = 0.0
	var tag := "%s_%s" % [str(stop.get("id", "stop")), str(args.get("distance", int(FollowCamera.DEFAULT_DISTANCE)))]
	for v: Array in variants:
		for mete in _metes:
			for mat in mete.get_materials():
				mat.set_shader_parameter(&"cape_color", v[1])
		for i in 4:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var out := dir.path_join("%s_%s.png" % [tag, v[0]])
		print("[cape_lineup] %s %s" % [out, img.save_png(out)])
	get_tree().quit()


func _build_ground() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(160.0, 160.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = GROUND_COLOR
	mat.roughness = 1.0
	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	ground.mesh = plane
	ground.material_override = mat
	add_child(ground)


## Mete ortada, kuzeye bakar; kalabalık çevresinde dağınık durur (tohumlu: her koşu aynı).
func _build_crowd(count: int, dye: int) -> void:
	var profile := CharacterProfile.new()
	profile.set_value(&"cape_dye", dye)
	_add_mete(profile, Vector3.ZERO, PI + deg_to_rad(8.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 58
	var placed: Array[Vector2] = [Vector2.ZERO]
	var tries := 0
	while placed.size() < count + 1 and tries < 4000:
		tries += 1
		var p := Vector2(rng.randf_range(-5.0, 5.0), rng.randf_range(-4.5, 3.5))
		if p.length() < 1.1:
			continue
		var ok := true
		for q in placed:
			if p.distance_to(q) < 0.95:
				ok = false
				break
		if not ok:
			continue
		placed.append(p)
		var avatar := CharacterAvatar.new()
		avatar.model_override = CROWD_MODELS[(placed.size() - 2) % CROWD_MODELS.size()]
		avatar.position = Vector3(p.x, 0.0, p.y)
		avatar.rotation.y = rng.randf_range(-PI, PI)
		add_child(avatar)


## Altı Mete yan yana: her biri bir boya (CharacterOptions.dyes sırasıyla, soldan sağa); başlarının üstünde boyanın adı.
func _build_dye_row() -> void:
	var n := CharacterOptions.count(&"cape_dye")
	for i in n:
		var profile := CharacterProfile.new()
		profile.set_value(&"cape_dye", i)
		var at := Vector3((float(i) - (n - 1) * 0.5) * 1.35, 0.0, 0.0)
		_add_mete(profile, at, PI + deg_to_rad(14.0))
		var label := Label3D.new()
		label.text = CharacterOptions.value_name(&"cape_dye", i)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 40
		label.pixel_size = 0.004
		label.outline_size = 10
		label.modulate = Color(1.0, 0.97, 0.9)
		label.outline_modulate = Color(0.12, 0.1, 0.08)
		label.no_depth_test = true
		label.position = at + Vector3(0.0, 2.15, 0.0)
		add_child(label)


func _add_mete(profile: CharacterProfile, at: Vector3, yaw: float) -> void:
	var avatar := CharacterAvatar.new()
	avatar.profile = profile
	avatar.position = at
	avatar.rotation.y = yaw
	add_child(avatar)
	_metes.append(avatar)


func _build_camera(distance: float, pitch_deg: float, yaw: float, mode: String) -> void:
	_camera = Camera3D.new()
	_camera.name = "Camera"
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_camera.fov = FollowCamera.DEFAULT_FOV
	_camera.near = 0.05
	_camera.far = 600.0
	add_child(_camera)
	var target := Vector3(0.0, 0.7 if mode != "dyes" else 0.95, 0.0)
	_camera.global_transform = FollowCamera.compute_transform(target, yaw, pitch_deg, distance)
	_camera.make_current()
