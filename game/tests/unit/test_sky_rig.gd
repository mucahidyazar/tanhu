extends TestCase
## SkyRig (scripts/systems/sky_rig.gd): ışığın tek yazıcısı. Sinemanın sabit örneği (data/cine/birth_light.json)
## ışığın yönünü ve rengini, ortamı, sisi ve gök tekdüzenlerini yazar; sabitken saatin örneği yok sayılır.
## Gök gölgelendiricisinin güneş eklerinin (shaders/sky.gdshader) varsayılanları kampın gece göğünü değiştirmez.

const SKY_SHADER := preload("res://shaders/sky.gdshader")
const WATER_SHADER := preload("res://shaders/water.gdshader")
const SKY_SHADER_PATH := "res://shaders/sky.gdshader"
const BIRTH_LIGHT := "res://data/cine/birth_light.json"
const CAMP_SCENE := "res://scenes/world/world.tscn"
const CAMP_SCRIPT := "res://scripts/world/world.gd"
## Güneş eklerinin tekdüzenleri ve kampın göğünü değiştirmeyen varsayılanları.
const NEUTRAL_DEFAULTS := {
	"sun_glow_strength": 0.0, "sun_disc_size": 0.0, "ambient_panorama_mix": 0.0, "cloud_light_from_sun": 0.0,
}
const VEC_EPS := 1e-5

## Sınamanın sahnesi: kök > SunLight, WorldEnvironment (gök malzemesiyle), River (su), SkyRig.
var _root: Node3D
var _rig: SkyRig
var _light: DirectionalLight3D
var _env: Environment
var _sky_mat: ShaderMaterial
var _water_mat: ShaderMaterial


func before_each() -> void:
	_root = Node3D.new()
	_light = DirectionalLight3D.new()
	_light.name = "SunLight"
	_root.add_child(_light)
	_sky_mat = ShaderMaterial.new()
	_sky_mat.shader = SKY_SHADER
	var sky := Sky.new()
	sky.sky_material = _sky_mat
	_env = Environment.new()
	_env.background_mode = Environment.BG_SKY
	_env.sky = sky
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = _env
	_root.add_child(we)
	_water_mat = ShaderMaterial.new()
	_water_mat.shader = WATER_SHADER
	var river := MeshInstance3D.new()
	river.name = "River"
	river.mesh = PlaneMesh.new()
	river.material_override = _water_mat
	_root.add_child(river)
	_rig = SkyRig.new()
	_rig.name = "SkyRig"
	_rig.glint_paths = [^"../River"]
	_root.add_child(_rig)
	add_child(_root)


func after_each() -> void:
	if is_instance_valid(_root):
		_root.free()


# --- Sabit örnek ------------------------------------------------------------------------------------

func test_fixed_sample_writes_light_direction_and_color() -> void:
	var dir := Vector3(0.6, 0.5, -0.4).normalized()
	_rig.set_fixed_sample(_manual_sample(dir, Color(1.0, 0.7, 0.5), 1.1))
	assert_true(_rig.is_fixed(), "Örnek sabitlenmeli")
	assert_vec_almost(-_light.basis.z, -dir, VEC_EPS, "Işık örneğin yönünden gelmeli (−Z ilerleme yönüdür)")
	assert_eq(_light.light_color, Color(1.0, 0.7, 0.5), "Işığın rengi")
	assert_almost(_light.light_energy, 1.1, 1e-6, "Işığın gücü")
	assert_eq(_env.ambient_light_color, Color(0.3, 0.36, 0.58), "Ortam rengi")
	assert_almost(_env.ambient_light_energy, 0.35, 1e-6, "Ortam gücü")
	assert_eq(_env.fog_light_color, Color(0.3, 0.34, 0.5), "Sisin rengi")
	assert_almost(_env.fog_density, 0.0015, 1e-7, "Sisin yoğunluğu")
	assert_eq(_sky_mat.get_shader_parameter("zenith_color"), Color(0.05, 0.08, 0.22), "Gök tepesi (kısa ad zenith)")
	assert_eq(_sky_mat.get_shader_parameter("horizon_color"), Color(0.5, 0.44, 0.58), "Ufuk (kısa ad horizon)")
	assert_almost(float(_sky_mat.get_shader_parameter("sun_glow_strength")), 0.32, 1e-6, "Güneş ışıltısı")
	assert_almost(float(_sky_mat.get_shader_parameter("star_brightness")), 0.7, 1e-6, "Yıldızlar")


func test_clock_sample_is_ignored_while_fixed() -> void:
	var fixed_dir := Vector3(0.9, 0.3, 0.1).normalized()
	_rig.set_fixed_sample(_manual_sample(fixed_dir, Color(0.66, 0.72, 0.95), 0.6))
	var applied := watch_signal(_rig.sample_applied)
	var clock := _manual_sample(Vector3(-0.2, 0.9, 0.3).normalized(), Color(1.0, 1.0, 0.9), 2.0)
	assert_false(_rig.feed_clock(clock), "Sabitken saatin örneği yazılmamalı")
	assert_eq(applied.count, 0, "Sabitken hiçbir örnek uygulanmamalı")
	assert_vec_almost(-_light.basis.z, -fixed_dir, VEC_EPS, "Işığın yönü sabit örnekte kalmalı")
	assert_eq(_light.light_color, Color(0.66, 0.72, 0.95), "Işığın rengi sabit örnekte kalmalı")
	assert_almost(_light.light_energy, 0.6, 1e-6, "Işığın gücü sabit örnekte kalmalı")
	assert_almost(float(_rig.current_sample()["light_energy"]), 0.6, 1e-6, "Son yazılan örnek sabit örnek")


func test_clear_fixed_sample_accepts_the_clock_again() -> void:
	_rig.set_fixed_sample(_manual_sample(Vector3(0.9, 0.3, 0.1).normalized(), Color(0.66, 0.72, 0.95), 0.6))
	var waiting_dir := Vector3(-0.2, 0.9, 0.3).normalized()
	_rig.feed_clock(_manual_sample(waiting_dir, Color(1.0, 1.0, 0.9), 2.0))
	_rig.clear_fixed_sample()
	assert_false(_rig.is_fixed(), "Sabit örnek bırakılmalı")
	assert_vec_almost(-_light.basis.z, -waiting_dir, VEC_EPS, "Sabitken gelen son saat örneği bırakınca yazılmalı")
	assert_almost(_light.light_energy, 2.0, 1e-6, "Saatin gücü")
	var next_dir := Vector3(0.1, 0.7, 0.7).normalized()
	assert_true(_rig.feed_clock(_manual_sample(next_dir, Color(0.9, 0.9, 1.0), 1.4)), "Sabit yokken saat örneği yazılmalı")
	assert_vec_almost(-_light.basis.z, -next_dir, VEC_EPS, "Yeni saat örneği yazılmalı")
	_rig.clear_fixed_sample()
	assert_almost(_light.light_energy, 1.4, 1e-6, "Sabit yokken bırakmak ışığı değiştirmemeli")


func test_sky_material_gets_sun_and_moon_direction() -> void:
	# Yön verilmeyen örnekte güneş ve ay enlem, gün ve dakikadan hesaplanır (Daylight).
	_rig.set_fixed_sample({"lat": 39.0, "doy": 269, "minute": 363.0, "moon_age": 14.912896})
	var dec := Daylight.solar_dec(269.0)
	var sun := Daylight.sun_at(39.0, dec, 363.0)
	var moon := Daylight.moon_at(39.0, dec, 363.0, 14.912896)
	var sky_sun: Variant = _sky_mat.get_shader_parameter("sun_direction")
	var sky_moon: Variant = _sky_mat.get_shader_parameter("moon_direction")
	assert_true(sky_sun is Vector3 and sky_moon is Vector3, "Göğe sun_direction ve moon_direction gitmeli (%s, %s)" % [sky_sun, sky_moon])
	if sky_sun is Vector3 and sky_moon is Vector3:
		assert_vec_almost(sky_sun, Daylight.apparent_dir(sun), VEC_EPS, "Gökteki güneş kırılmayla görünen yönde")
		assert_vec_almost(sky_moon, Daylight.dir_of(moon), VEC_EPS, "Gökteki ay Daylight'ın yönünde")
	assert_vec_almost(-_light.basis.z, -Daylight.light_dir(sun), VEC_EPS, "Işık güneşin azimutundan 15° yükseklikten gelmeli")
	var water_dir: Variant = _water_mat.get_shader_parameter("moon_direction")
	assert_true(water_dir is Vector3, "Suyun parıltı yönü yazılmalı")
	if water_dir is Vector3:
		assert_vec_almost(water_dir, Daylight.apparent_dir(sun), VEC_EPS, "Ufuktaki güneş suda parlamalı")


func test_resolve_is_idempotent() -> void:
	var once := SkyRig.resolve({"lat": 39.0, "doy": 269, "minute": 350.0, "moon_age": 14.903868,
		"light_color": [0.66, 0.72, 0.95], "sky": {"zenith": "#0d1438", "sun_glow_strength": 0.3}})
	var twice := SkyRig.resolve(once)
	for key in ["sun_dir", "moon_dir", "light_dir"]:
		assert_true(once[key] is Vector3, "%s Vector3 olmalı" % key)
		assert_vec_almost(twice[key], once[key], 1e-7, "%s ikinci çözümde değişmemeli" % key)
	assert_true(once["light_color"] is Color, "Renk dizisi Color olmalı")
	assert_true((once["sky"] as Dictionary)["zenith"] is Color, "Gökteki kısa adlı renk Color olmalı")
	assert_eq(twice["light_color"], once["light_color"])


# --- Doğumun örnekleri ---------------------------------------------------------------------------

func test_birth_light_has_the_two_dawn_samples() -> void:
	var samples := SkyRig.load_samples(BIRTH_LIGHT)
	assert_true(samples.has("inside") and samples.has("outside"), "İçeride 05:50 ve dışarıda 06:03 örnekleri olmalı")
	if not (samples.has("inside") and samples.has("outside")):
		return
	var inside: Dictionary = samples["inside"]
	var outside: Dictionary = samples["outside"]
	assert_almost(float(inside["minute"]), 350.0, 0.0001, "İçeride 05:50")
	assert_almost(float(outside["minute"]), 363.0, 0.0001, "Dışarıda 06:03")
	assert_almost(float(outside["lat"]), 39.0, 0.0001, "Ordos 39°K")
	assert_almost(float(outside["dec"]), -2.12, 0.02, "27 Eylül'ün sapması")
	var in_sun: Dictionary = inside["sun"]
	var out_sun: Dictionary = outside["sun"]
	var out_moon: Dictionary = outside["moon"]
	assert_between(float(in_sun["el"]), -4.0, -2.5, "05:50 güneş sivil alacada")
	assert_between(float(out_sun["el"]), -1.5, 0.5, "06:03 güneş ufukta")
	assert_between(float(out_sun["az"]), 88.0, 96.0, "06:03 güneş doğuda")
	assert_between(float(out_moon["az"]), 260.0, 280.0, "06:03 dolunay batıda")
	assert_between(float(out_moon["el"]), 0.0, 2.5, "06:03 dolunay ufukta")
	assert_almost(float(out_moon["illum"]), 1.0, 0.001, "Dolunay")
	# İçerisi soğuk mavi, köz baskın; dışarısı sıcak ve alçak güneş.
	var in_light: Color = inside["light_color"]
	var out_light: Color = outside["light_color"]
	assert_true(in_light.b > in_light.r, "05:50 ışığı soğuk (mavi) olmalı: %s" % in_light)
	assert_true(out_light.r > out_light.b, "06:03 ışığı sıcak olmalı: %s" % out_light)
	assert_true(float(inside["ambient_energy"]) < float(outside["ambient_energy"]), "İçerinin ortamı dışarıdan karanlık")
	var in_sky: Dictionary = inside["sky"]
	var out_sky: Dictionary = outside["sky"]
	assert_almost(float(in_sky.get("sun_disc_size", 0.0)), 0.0, 1e-9, "05:50'de güneş diski yok (ufkun altında)")
	assert_true(float(out_sky.get("sun_disc_size", 0.0)) > 0.0, "06:03'te güneş diski ufukta görünür")
	assert_true(float(in_sky["star_brightness"]) > float(out_sky["star_brightness"]), "Son yıldızlar 05:50'de")
	for sample: Dictionary in [inside, outside]:
		var sky: Dictionary = sample["sky"]
		var pano := str(sky.get("ambient_panorama", ""))
		assert_true(ResourceLoader.exists(pano), "%s: ortam panoraması içe aktarılmış olmalı (%s)" % [sample["id"], pano])
		for key: String in sky:
			assert_true(_sky_uniform_names().has(SkyRig.SKY_ALIASES.get(key, key)), "%s: gökte %s tekdüzeni olmalı" % [sample["id"], key])


func test_birth_samples_apply_to_a_world() -> void:
	# Örnek sırayla uygulanınca (çekim değişimi) ışık ve gök her seferinde örneğin kendisidir.
	var samples := SkyRig.load_samples(BIRTH_LIGHT)
	for id in ["inside", "outside", "inside"]:
		_rig.set_fixed_sample(samples[id])
		var s: Dictionary = samples[id]
		assert_vec_almost(-_light.basis.z, -(s["light_dir"] as Vector3), VEC_EPS, "%s: ışığın yönü" % id)
		assert_eq(_light.light_color, s["light_color"], "%s: ışığın rengi" % id)
		assert_eq(_light.shadow_enabled, id == "outside", "%s: dışarıda şafak ışığı gölge düşürür; içeride yalnız zemini aydınlatır, gölgesizdir (bütçe, K63)" % id)
		assert_almost(float(_sky_mat.get_shader_parameter("sun_glow_strength")), float((s["sky"] as Dictionary)["sun_glow_strength"]), 1e-6, "%s: ışıltı" % id)
		assert_true(_sky_mat.get_shader_parameter("ambient_panorama") is Texture2D, "%s: ortam panoraması bağlanmalı" % id)
	var moon_dir: Vector3 = (samples["inside"] as Dictionary)["moon_dir"]
	var water_dir: Variant = _water_mat.get_shader_parameter("moon_direction")
	assert_true(water_dir is Vector3 and (water_dir as Vector3).distance_to(moon_dir) < VEC_EPS, "05:50'de suda ay parlar")


# --- Kampın göğü ------------------------------------------------------------------------------------

func test_default_uniforms_leave_the_camp_sky_unchanged() -> void:
	# Güneş ekleri varsayılanlarıyla etkisizdir ve her biri kendi koşuluyla atlanır: kampın gece göğü ve menü
	# karesi aynı kalır (godot.md §1 madde 11). Kamp bu tekdüzenlere hiç dokunmaz.
	var code := FileAccess.get_file_as_string(SKY_SHADER_PATH)
	var names := _sky_uniform_names()
	for uniform: String in NEUTRAL_DEFAULTS:
		assert_true(names.has(uniform), "Gölgelendiricide %s olmalı" % uniform)
		var found := RegEx.create_from_string("uniform\\s+float\\s+%s\\s*(?::[^=;]*)?=\\s*([-0-9.]+)\\s*;" % uniform).search(code)
		assert_not_null(found, "%s'in varsayılanı yazılmalı" % uniform)
		if found:
			assert_almost(found.get_string(1).to_float(), float(NEUTRAL_DEFAULTS[uniform]), 1e-9, "%s'in varsayılanı etkisiz olmalı" % uniform)
		assert_true(code.contains("if (%s > 0.0)" % uniform), "%s'in kolu kendi koşuluyla atlanmalı" % uniform)
	var camp_scene := FileAccess.get_file_as_string(CAMP_SCENE)
	var camp_script := FileAccess.get_file_as_string(CAMP_SCRIPT)
	for uniform in ["sun_direction", "sun_glow_strength", "sun_disc_size", "ambient_panorama", "cloud_light_from_sun"]:
		assert_false(camp_scene.contains(uniform), "Kamp sahnesi %s yazmamalı" % uniform)
		assert_false(camp_script.contains(uniform), "World (kamp) %s yazmamalı" % uniform)
	assert_true(camp_script.contains("\"moon_direction\""), "Kampın gök yolu (World._apply_directions) moon_direction'ı yazmaya devam eder")
	# Kampın bugünkü gök malzemesi yeni tekdüzenleri boş bırakır.
	var camp_mat := ShaderMaterial.new()
	camp_mat.shader = SKY_SHADER
	for uniform: String in NEUTRAL_DEFAULTS:
		assert_null(camp_mat.get_shader_parameter(uniform), "Yeni bir gök malzemesi %s'i ezmemeli" % uniform)


func test_sky_shader_reads_frozen_world_time() -> void:
	# W8: zamana bağlı her gölgelendirici TIME yerine tn_time() okur (dondurulmuş kare, godot.md §8.5).
	var code := FileAccess.get_file_as_string(SKY_SHADER_PATH)
	assert_true(code.contains("#include \"res://shaders/include/world_time.gdshaderinc\""), "world_time eklenmeli")
	var bare_time := 0
	for line in code.split("\n"):
		var body := line.split("//")[0]
		if RegEx.create_from_string("\\bTIME\\b").search(body):
			bare_time += 1
	assert_eq(bare_time, 0, "Gök TIME'ı doğrudan okumamalı (tn_time kullanılır)")
	assert_true(code.contains("tn_time()"), "Gök zamanı tn_time()'dan okumalı")


# --- Kimlik, süzülme, renk ayarı ve hava (sun-light, roam-calendar; K76) ------------------------------

## Menünün gece ışığı gibi bir kimlik kurar: ay ışığı, ortam, sis, gök ve su tekdüzenleri, renk ayarı LUT'u.
func _menu_identity() -> ImageTexture3D:
	_light.basis = SkyRig.light_basis(World.direction_from_angles(140.0, 50.0))
	_light.light_color = Color(0.66, 0.75, 1.0)
	_light.light_energy = 0.42
	_env.ambient_light_color = Color(0.3, 0.38, 0.66)
	_env.ambient_light_energy = 0.5
	_env.ambient_light_sky_contribution = 0.55
	_env.fog_light_color = Color(0.18, 0.26, 0.46)
	_env.fog_density = 0.00045
	_sky_mat.set_shader_parameter("moon_direction", Vector3(0.39, 0.24, -0.89))
	_water_mat.set_shader_parameter("moon_direction", Vector3(0.39, 0.24, -0.89))
	var lut := ColorGrade.world_night().build_lut()
	_env.adjustment_enabled = true
	_env.adjustment_color_correction = lut
	return lut


func test_release_restores_the_identity_bit_for_bit() -> void:
	var lut := _menu_identity()
	var basis := _light.basis
	var energy := _light.light_energy
	var fog := _env.fog_density
	var zenith: Variant = _sky_mat.get_shader_parameter("zenith_color")
	var fire := OmniLight3D.new()
	fire.light_energy = 3.3
	var fire_energy := fire.light_energy
	_root.add_child(fire)
	_rig.take_over({"fire": {"node": fire, "property": "light_energy"}})
	assert_true(_rig.is_taken(), "Kimlik alındı")
	assert_true(SkyRig.grades_ready(true), "Renk ayarının taban görüntüleri hazır")
	var sample := LightStops.sample(LightStops.load_table(), "camp", 1171, Daylight.MENU_MINUTE)
	_rig.feed_clock(sample)
	assert_vec_almost(-_light.basis.z, -(sample["light_dir"] as Vector3), VEC_EPS, "Saatin ışığı yazıldı")
	assert_almost(_light.light_energy, float(sample["light_energy"]), 1e-6)
	assert_false(_env.adjustment_color_correction == lut, "Gündüzün renk ayarı (grade_night 0)")
	assert_almost(fire.light_energy, 3.3 * float(sample["props"]["fire"]), 1e-5, "Ateş kimliğin × payı")
	assert_true(_sky_mat.get_shader_parameter("zenith_color") is Color, "Gök yazıldı")
	await _rig.release(0.0)
	assert_false(_rig.is_taken(), "Bırakıldı")
	assert_true(_light.basis.is_equal_approx(basis), "Işığın yönü kimliğe döner")
	assert_eq(_light.light_color, Color(0.66, 0.75, 1.0), "Rengi")
	assert_eq(_light.light_energy, energy, "Gücü (bit bit)")
	assert_eq(_env.ambient_light_color, Color(0.3, 0.38, 0.66), "Ortam")
	assert_eq(_env.fog_density, fog, "Sis (bit bit)")
	assert_true(_env.adjustment_color_correction == lut, "Menünün LUT'u (aynı doku)")
	assert_eq(_sky_mat.get_shader_parameter("zenith_color"), zenith, "Yazılmamış gök tekdüzeni yine yazılmamış (varsayılan)")
	assert_null(_sky_mat.get_shader_parameter("sun_glow_strength"), "Güneş ışıltısı menüde yazılmamış kalır")
	assert_vec_almost(_sky_mat.get_shader_parameter("moon_direction"), Vector3(0.39, 0.24, -0.89), VEC_EPS, "Ayın yönü")
	assert_vec_almost(_water_mat.get_shader_parameter("moon_direction"), Vector3(0.39, 0.24, -0.89), VEC_EPS, "Suyun parıltısı")
	assert_null(_water_mat.get_shader_parameter("deep_color"), "Suyun rengi yazılmamış kalır")
	assert_eq(fire.light_energy, fire_energy, "Ateş kimliğe döner")
	assert_true(_rig.feed_clock(sample), "Bırakıldıktan sonra kimliksiz besleme (Çocukluk'un yolu) sürer")
	assert_true(_env.adjustment_color_correction == lut, "Kimliksiz beslemede LUT yazılmaz")


func test_fade_from_identity_reaches_the_clock_and_dips_the_light() -> void:
	_menu_identity()
	_rig.take_over()
	var sample := LightStops.sample(LightStops.load_table(), "camp", 1171, Daylight.MENU_MINUTE)
	_rig.feed_clock(sample)
	var applied := watch_signal(_rig.sample_applied)
	_rig.fade_from_identity(2.4)
	assert_true(_rig.is_fading(), "Süzülme başladı")
	assert_vec_almost(-_light.basis.z, -World.direction_from_angles(140.0, 50.0), 1e-4, "İlk karede ay ışığının yönü (gece menüsü)")
	assert_almost(_light.light_energy, 0.42, 1e-4, "İlk karede menünün gücü")
	var from_dir := World.direction_from_angles(140.0, 50.0)
	var angle := rad_to_deg(from_dir.angle_to(sample["light_dir"]))
	assert_true(angle > SkyRig.FADE_DIP_ANGLE, "Yön farkı 30°'den büyük: %.1f°" % angle)
	# Ortada (t 0,5): güç iki ucun ortası × 0,4.
	_rig._step_fade(1.2)
	var mid := lerpf(0.42, float(sample["light_energy"]), 0.5) * SkyRig.FADE_DIP_K
	assert_almost(_light.light_energy, mid, 1e-3, "Ortada ışık katsayısı 0,4")
	_rig._step_fade(1.2)
	assert_false(_rig.is_fading(), "2,4 sn'de biter")
	assert_vec_almost(-_light.basis.z, -(sample["light_dir"] as Vector3), VEC_EPS, "Sonunda saatin ışığı")
	assert_almost(_light.light_energy, float(sample["light_energy"]), 1e-6)
	assert_true(applied.count >= 3, "Her adımda yazılır")
	assert_almost(SkyRig.sine_in_out(0.5), 0.5, 1e-12)
	assert_almost(SkyRig.sine_in_out(0.0), 0.0, 1e-12)
	assert_almost(SkyRig.sine_in_out(1.0), 1.0, 1e-12)


func test_release_fades_back_over_the_flight() -> void:
	var lut := _menu_identity()
	var energy := _light.light_energy
	_rig.take_over()
	_rig.feed_clock(LightStops.sample(LightStops.load_table(), "camp", 1171, 700.0))
	var done := watch_signal(_rig.released)
	_rig.release(1.7)
	assert_true(_rig.is_fading(), "Uçuş boyunca süzülür")
	_rig._step_fade(0.85)
	assert_true(_rig.is_taken(), "Yarıda hâlâ alınmış")
	_rig._step_fade(0.9)
	assert_eq(done.count, 1, "Sonunda released")
	assert_false(_rig.is_taken())
	assert_eq(_light.light_energy, energy, "Kimlik bit bit")
	assert_true(_env.adjustment_color_correction == lut)


func test_grade_mix_blends_day_and_night() -> void:
	# (1 − t)·a + t·b, C++ yolu (adjust_bcs, blend_rect): 8 bitte 1/255 içinde.
	var a: Array[Image] = []
	var b: Array[Image] = []
	for z in SkyRig.LUT_SIZE:
		var ia := Image.create_empty(SkyRig.LUT_SIZE, SkyRig.LUT_SIZE, false, Image.FORMAT_RGBAF)
		ia.fill(Color(0.2, 0.6, 0.9, 1.0))
		var ib := Image.create_empty(SkyRig.LUT_SIZE, SkyRig.LUT_SIZE, false, Image.FORMAT_RGBAF)
		ib.fill(Color(0.8, 0.1, 0.3, 0.5))
		a.append(ia)
		b.append(ib)
	for t in [0.0, 0.25, 0.5, 1.0]:
		var out := SkyRig.mix_grade_slices(a, b, t)
		var c := out[7].get_pixel(3, 5)
		var want := Color(0.2, 0.6, 0.9).lerp(Color(0.8, 0.1, 0.3), t)
		assert_almost(c.r, want.r, 1e-5, "r t=%s" % t)
		assert_almost(c.g, want.g, 1e-5, "g t=%s" % t)
		assert_almost(c.b, want.b, 1e-5, "b t=%s" % t)
		assert_almost(c.a, 1.0, 1e-6, "alfa 1")
	# Rig: grade_night 1 kimliğin LUT'u, 0 gündüzün, arası karışık; taban görüntüleri hazırlanır.
	var lut := _menu_identity()
	_rig.take_over()
	assert_true(SkyRig.grades_ready(true), "Taban görüntüleri hazır")
	var sample := LightStops.sample(LightStops.load_table(), "camp", 1171, 700.0)
	sample["grade_night"] = 1.0
	_rig.feed_clock(sample)
	assert_true(_env.adjustment_color_correction == lut, "Gece payı 1: menünün LUT'u")
	sample["grade_night"] = 0.0
	_rig.feed_clock(sample)
	var day: Variant = _env.adjustment_color_correction
	assert_true(day is ImageTexture3D and day != lut, "Gece payı 0: gündüzün LUT'u")
	sample["grade_night"] = 0.5
	_rig.feed_clock(sample)
	var mixed: Variant = _env.adjustment_color_correction
	assert_true(mixed is ImageTexture3D and mixed != lut and mixed != day, "Yarı: karışık LUT")
	sample["grade_autumn"] = 1.0
	sample["grade_night"] = 0.0
	_rig.feed_clock(sample)
	assert_true(_env.adjustment_color_correction != day, "Güz tonu gündüzün LUT'una karışır")
	await _rig.release(0.0)


func test_weather_input_multiplies_the_clock_sample() -> void:
	var s := {"light_energy": 1.5, "ambient_energy": 0.5, "exposure": 1.0, "light_color": Color(1.0, 0.9, 0.8),
		"fog": {"density": 0.0003, "color": Color(0.6, 0.7, 0.8)}, "sky": {"cloud_coverage": 0.3, "star_brightness": 2.0}}
	var w := SkyRig.apply_weather(s, {"light_mul": 0.4, "ambient_mul": 1.2, "exposure_mul": 1.1, "fog_density_mul": 3.0,
		"fog_color": Color(0.5, 0.5, 0.5), "fog_color_mix": 0.5, "sky": {"cloud_coverage": 0.9}, "sky_mul": {"star_brightness": 0.0}, "shadow": false})
	assert_almost(float(w["light_energy"]), 0.6, 1e-9, "Işık × 0,4")
	assert_almost(float(w["ambient_energy"]), 0.6, 1e-9, "Ortam × 1,2")
	assert_almost(float(w["exposure"]), 1.1, 1e-9)
	assert_almost(float(w["fog"]["density"]), 0.0009, 1e-12, "Sis × 3")
	assert_true((w["fog"]["color"] as Color).is_equal_approx(Color(0.55, 0.6, 0.65)), "Sisin rengi yarı yolda")
	assert_almost(float(w["sky"]["cloud_coverage"]), 0.9, 1e-12, "Bulut örtüsü ezilir")
	assert_almost(float(w["sky"]["star_brightness"]), 0.0, 1e-12, "Yıldızlar bulutun ardında")
	assert_false(bool(w["light_shadow"]), "Kapalı gök gölgesiz")
	assert_almost(float(s["light_energy"]), 1.5, 1e-12, "Saatin örneği değişmez (kopya)")
	var flash := SkyRig.apply_weather(s, {"flash": 1.0})
	assert_almost(float(flash["light_energy"]), 1.5 + 3.0, 1e-9, "Şimşek parlatır")
	# Rig: saatin örneğine uygulanır, temizleyince geri gelir.
	_rig.feed_clock(_manual_sample(Vector3(0.0, 1.0, 0.0), Color(1, 1, 1), 2.0))
	_rig.set_weather({"light_mul": 0.25})
	assert_almost(_light.light_energy, 0.5, 1e-6, "Hava hemen yazılır")
	_rig.clear_weather()
	assert_almost(_light.light_energy, 2.0, 1e-6, "Hava kalkınca saatin gücü")
	_rig.set_fixed_sample(_manual_sample(Vector3(0.0, 1.0, 0.0), Color(1, 1, 1), 1.0))
	_rig.set_weather({"light_mul": 0.25})
	assert_almost(_light.light_energy, 1.0, 1e-6, "Sinemanın sabit örneğine hava yazılmaz")


# --- Yardımcılar ------------------------------------------------------------------------------------

## Yönü ve rengi verilen elle kurulmuş örnek (05:50'nin renkleri).
static func _manual_sample(dir: Vector3, color: Color, energy: float) -> Dictionary:
	return {
		"sun_dir": [dir.x, dir.y, dir.z], "light_dir": [dir.x, dir.y, dir.z], "moon_dir": [-0.99, 0.08, 0.02],
		"light_color": [color.r, color.g, color.b], "light_energy": energy,
		"ambient_color": [0.3, 0.36, 0.58], "ambient_energy": 0.35,
		"sky": {"zenith": [0.05, 0.08, 0.22], "horizon": [0.5, 0.44, 0.58], "sun_glow_strength": 0.32, "star_brightness": 0.7},
		"fog": {"color": [0.3, 0.34, 0.5], "density": 0.0015},
	}


static func _sky_uniform_names() -> Dictionary:
	var names := {}
	for u in SKY_SHADER.get_shader_uniform_list():
		names[str(u["name"])] = true
	return names
