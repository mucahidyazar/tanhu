extends TestCase
## Serbest Gez'in saati ve ışığı (RoamTime; K20, K67, K76; time.md §2, §5.5, §8.1, §11, §13, §17 «roam-clock»; godot.md §3.5):
##   - Kayıtsız Serbest Gez 11 Nisan MÖ 209 (1.171) 14:46,2'de açılır; eski kaydın {day: 3, minute: 600}'ı 1.174'e göçer; mood > 0,75 18:38.
##   - 34 × 1.440 oyun dk sonra mevsim yaz, 134'te güz, 219'da kış; görünüş (güz tonu, kar örtüsü) 3 günde süzülür.
##   - Kayıt v2: oturum yokken saat bekleyen bloklara yazılır (journey.pending_blocks.clock), oturumun bloğu varsa ona dokunulmaz.
##   - Küçük bir kamp dünyasında: açılış ışığı yazar ve kimliği saklar; Tan'da 2 sn tarih kartı («12 Nisan MÖ 209»; gün sayısı yok);
##     Serbest Gez'de takvim olayı ve sayım yazılmaz; end ışığı kimliğe döndürür.

const TempDir := preload("res://tests/support/temp_dir.gd")
const SKY_SHADER := preload("res://shaders/sky.gdshader")
const WATER_SHADER := preload("res://shaders/water.gdshader")

var _world: Node3D
var _light: DirectionalLight3D
var _env: Environment
var _fire: OmniLight3D
var _roam: RoamTime
var _dir := ""


func before_each() -> void:
	_dir = TempDir.fresh("roam_time")
	_world = Node3D.new()
	_world.name = "World"
	_light = DirectionalLight3D.new()
	_light.name = "MoonLight"
	_light.light_energy = 0.42
	_light.basis = SkyRig.light_basis(World.direction_from_angles(140.0, 50.0))
	_world.add_child(_light)
	var mat := ShaderMaterial.new()
	mat.shader = SKY_SHADER
	var sky := Sky.new()
	sky.sky_material = mat
	_env = Environment.new()
	_env.background_mode = Environment.BG_SKY
	_env.sky = sky
	_env.adjustment_enabled = true
	_env.adjustment_color_correction = ColorGrade.world_night().build_lut()
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = _env
	_world.add_child(we)
	var water := Node3D.new()
	water.name = "Water"
	var wm := MeshInstance3D.new()
	wm.name = "WaterMesh"
	wm.mesh = PlaneMesh.new()
	var wmat := ShaderMaterial.new()
	wmat.shader = WATER_SHADER
	wm.material_override = wmat
	water.add_child(wm)
	_world.add_child(water)
	var camp := Node3D.new()
	camp.name = "Camp"
	_fire = OmniLight3D.new()
	_fire.name = "Campfire"
	_fire.light_energy = 3.3
	camp.add_child(_fire)
	_world.add_child(camp)
	add_child(_world)
	_roam = RoamTime.new()
	add_child(_roam)


func after_each() -> void:
	if is_instance_valid(_roam):
		_roam.free()
	if is_instance_valid(_world):
		_world.free()
	TempDir.wipe(_dir)


func test_config_is_the_one_calendar() -> void:
	var cfg := RoamTime.load_config()
	assert_eq(int(cfg["day_n"]), GameCalendar.HOME_DAY, "Açılış 1.171")
	assert_eq(GameCalendar.format_tr(int(cfg["day_n"])), str(cfg["date"]["tr"]), "11 Nisan MÖ 209")
	assert_almost(float(cfg["minute"]), Daylight.MENU_MINUTE, 1e-12, "14:46,2")
	assert_almost(float(cfg["fade_seconds"]), 2.4, 1e-12, "Gece menüsünden 2,4 sn (K76)")
	assert_almost(float(cfg["return_seconds"]), 1.7, 1e-12, "Menüye dönüş 1,7 sn")
	assert_almost(float(cfg["dawn_card_seconds"]), 2.0, 1e-12, "Tan'da 2 sn")
	var root: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RoamTime.CALENDAR_PATH))
	var cal: Dictionary = root["calendar"]
	assert_eq(int(cal["day1"]["year_bc"]), GameCalendar.DAY1_YEAR_BC)
	assert_eq(int(cal["day1"]["doy"]), GameCalendar.DAY1_DOY)
	assert_eq(int(cal["year_days"]), GameCalendar.YEAR_DAYS)
	assert_almost(float(cal["synodic"]), GameCalendar.SYNODIC, 1e-12)
	assert_almost(float(cal["moon_epoch"]), GameCalendar.MOON_EPOCH, 1e-12)
	for i in GameCalendar.SEASONS.size():
		assert_eq(str(cal["seasons"][i][0]), str(GameCalendar.SEASONS[i][0]), "Mevsim sırası")
		assert_eq(int(cal["seasons"][i][1]), int(GameCalendar.SEASONS[i][1]))
		assert_eq(int(cal["seasons"][i][2]), int(GameCalendar.SEASONS[i][2]))
	for act: String in cal["acts"]:
		assert_eq(int(cal["acts"][act]), GameCalendar.act_start(int(act)), "%s. perde" % act)


func test_clock_opens_on_the_menu_minute_and_old_days_migrate() -> void:
	var c := _roam.clock_from(null)
	assert_eq(c.day_n, 1171, "Kayıtsız Serbest Gez 1.171")
	assert_almost(c.minute, 886.18, 1e-9, "14:46,2")
	assert_true(c.has_place(), "Ana kampın yeri")
	assert_eq(c.phase(), &"golden", "İkindi")
	assert_almost(GameCalendar.moon_illum(c.abs_minute()), 0.36, 0.01, "Ay %36, tek formül (ayrı ay yok)")
	var old := _roam.clock_from({"day": 3, "minute": 600})
	assert_eq(old.day_n, 1174, "Eski kayıt: 1.171 + 3")
	assert_almost(old.minute, 600.0, 1e-9)
	var saved := _roam.clock_from({"v": 1, "day_n": 1205, "minute": 300.0, "holds": []})
	assert_eq(saved.day_n, 1205, "Kayıtlı saat")
	var dusk := _roam.clock_from(null, 0.8)
	assert_eq(dusk.text(), "18:38", "Saatsiz eski kayıtta mood > 0,75 akşam")
	assert_eq(_roam.clock_from(null, 0.3).text(), "14:46", "mood ≤ 0,75 menü dakikası")
	var broken := _roam.clock_from({"minute": 5})
	assert_eq(broken.day_n, 1171, "Okunamayan blok açılışa düşer")
	# 34 oyun günü sonra yaz (time.md §17 roam-clock).
	var summer := _roam.clock_from(null)
	summer.skip(34.0 * 1440.0, &"dev")
	assert_eq(GameCalendar.season(summer.day_n), &"summer", "34 × 1.440 oyun dk sonra yaz")


func test_saved_block_rides_the_save_v2_blocks() -> void:
	var journey := Journey.new(SaveSystem.new(_dir))
	assert_null(RoamTime.saved_block(journey), "Kayıtsız yolculukta saat yok")
	_roam.clock = _roam.clock_from(null)
	_roam.clock.skip(90.0, &"dev")
	_roam.store_into(journey)
	assert_null(RoamTime.saved_block(journey), "Serbest Gez sürmüyorken yazılmaz")
	_roam.running = true
	_roam.store_into(journey)
	var block: Variant = RoamTime.saved_block(journey)
	assert_true(block is Dictionary, "Oturum yokken kaydın bloklarına yazılır")
	if block is Dictionary:
		assert_eq(int(block["day_n"]), _roam.clock.day_n)
		assert_almost(float(block["minute"]), _roam.clock.minute, 1e-9)
		assert_eq(SaveBlocks.check_clock(block), "", "Blok kayıt v2'nin denetiminden geçer")
	var record := journey.to_record(0)
	assert_true((record.get("blocks", {}) as Dictionary).has("clock"), "Kayda clock bloğu girer")
	# Kayıttan geri kurulan yolculuk aynı saati okur.
	var back := Journey.new(SaveSystem.new(_dir))
	assert_true(back.apply_record(JSON.parse_string(JSON.stringify(record))))
	var c := _roam.clock_from(RoamTime.saved_block(back))
	assert_eq(c.day_n, _roam.clock.day_n, "Yüklenen kaydın günü")
	assert_almost(c.minute, _roam.clock.minute, 1e-6, "Yüklenen kaydın dakikası")
	# Oturumun bloğu varsa saat onundur: yazılmaz, onunki okunur.
	var session_clock := GameClock.new(1300, 100.0)
	var blocks := SaveBlocks.new()
	blocks.register("clock", 1, session_clock.to_dict, session_clock.load_dict)
	journey.live_blocks = blocks
	journey.blocks = {}
	_roam.store_into(journey)
	assert_false(journey.blocks.has("clock"), "Oturum kuruluyken kaydın bloklarına yazılmaz")
	assert_eq(int((RoamTime.saved_block(journey) as Dictionary)["day_n"]), 1300, "Oturumun bloğu okunur")
	_roam.running = false


func test_season_looks_turn_and_blend() -> void:
	# 15 Mayıs yaz (baharın görünüşü), 23 Ağustos'tan güz tonu, 16 Kasım'dan kar örtüsü; 3 günde süzülür.
	var spring := _roam.look_at(1171, 886.18)
	assert_eq(spring["season"], &"spring")
	assert_almost(float(spring["grade_autumn"]), 0.0, 1e-12)
	assert_almost(float(spring["snow"]), 0.0, 1e-12)
	var summer := _roam.look_at(GameCalendar.day_n_of(20, 5, 209), 0.0)
	assert_eq(summer["season"], &"summer", "15 Mayıs'tan yaz")
	assert_almost(float(summer["grade_autumn"]), 0.0, 1e-12, "Yazın görünüşü baharınki")
	var autumn_day := GameCalendar.day_n_of(23, 8, 209)
	assert_eq(autumn_day - 1171, 134, "Güze 134 gün")
	var full := float(RoamTime.load_config()["looks"]["autumn"]["grade_autumn"])
	assert_true(full > 0.0, "Güz tonu var")
	assert_almost(float(_roam.look_at(autumn_day, 0.0)["grade_autumn"]), 0.0, 1e-9, "Güzün ilk anı yazın tonu")
	assert_almost(float(_roam.look_at(autumn_day + 1, 720.0)["grade_autumn"]), full * 0.5, 1e-9, "Bir buçuk günde yarı")
	assert_almost(float(_roam.look_at(autumn_day + 4, 0.0)["grade_autumn"]), full, 1e-9, "Güz tonu tam")
	var winter_day := GameCalendar.day_n_of(16, 11, 209)
	assert_eq(winter_day - 1171, 219, "Kışa 219 gün")
	var winter := _roam.look_at(winter_day + 5, 0.0)
	assert_eq(winter["season"], &"winter")
	assert_almost(float(winter["snow"]), 1.0, 1e-9, "Kar örtüsü (SnowPack'in hedefi)")
	var thaw := _roam.look_at(GameCalendar.day_n_of(16, 3, 208), 0.0)
	assert_almost(float(thaw["snow"]), 1.0, 1e-9, "Baharın ilk anı kışın görünüşü")
	assert_almost(float(_roam.look_at(GameCalendar.day_n_of(20, 3, 208), 0.0)["snow"]), 0.0, 1e-9, "Kar 3 günde kalkar")


func test_roam_writes_the_light_shows_the_dawn_card_and_returns_to_identity() -> void:
	var basis := _light.basis
	var energy := _light.light_energy
	var fire_energy := _fire.light_energy
	var lut := _env.adjustment_color_correction
	var cards: Array = []
	_roam.date_card.connect(func(text: String, seconds: float) -> void: cards.append([text, seconds]))
	_roam.begin(_world, null, 0.0)
	assert_true(_roam.is_running())
	var rig := _roam.rig
	assert_not_null(rig, "SkyRig kuruldu")
	if rig == null:
		return
	assert_eq(rig.get_parent(), _world, "Dünyanın çocuğu")
	assert_true(rig.is_taken(), "Kimlik saklandı")
	assert_vec_almost(-_light.basis.z, -(rig.current_sample()["light_dir"] as Vector3), 1e-5, "Saatin ışığı yazıldı")
	assert_true(rad_to_deg((rig.current_sample()["light_dir"] as Vector3).angle_to(Daylight.MENU_SUN.normalized())) < 0.25, "İkindi güneşi")
	assert_almost(_fire.light_energy, 3.3 * float(rig.current_sample()["props"]["fire"]), 1e-4, "Ateş gündüz sönük")
	assert_eq(cards.size(), 0, "Açılışta kart yok")
	# Tan ağarana dek: 04:21 dolayı (12 Nisan), atlamanın sonunda tek kart; yalnız tarih.
	var clock := _roam.clock
	clock.skip(clock.next(&"dawn") - clock.abs_minute() + 10.0, &"wait")
	assert_eq(cards.size(), 1, "Tan'da tarih kartı")
	if cards.size() == 1:
		assert_eq(str(cards[0][0]), "12 Nisan MÖ 209", "Yalnız tarih, gün sayısı yok")
		assert_almost(float(cards[0][1]), 2.0, 1e-9, "2 sn")
	# Akan saatte de (atlamasız) Tan kartı bir kez.
	cards.clear()
	clock.skip(clock.next(&"dawn") - clock.abs_minute() - 0.2, &"dev")
	cards.clear()
	for i in 60:
		_roam._process(0.05)
	assert_eq(cards.size(), 1, "Akan saatte Tan kartı")
	# Menüye dönüş: kimlik bit bit.
	await _roam.end(0.0)
	assert_false(_roam.is_running())
	assert_false(rig.is_taken(), "Bırakıldı")
	assert_true(_light.basis.is_equal_approx(basis), "Işığın yönü menününki")
	assert_eq(_light.light_energy, energy, "Gücü menününki")
	assert_true(_env.adjustment_color_correction == lut, "Menünün LUT'u")
	assert_eq(_fire.light_energy, fire_energy, "Ateş menününki")


func test_session_clock_is_read_not_stepped() -> void:
	var external := GameClock.new(1171, 900.0)
	_roam.begin(_world, null, 0.0, external)
	assert_true(_roam.clock == external, "Oturumun saati")
	assert_true(external.has_place(), "Yer verilir")
	for i in 20:
		_roam._process(0.1)
	assert_almost(external.minute, 900.0, 1e-12, "RoamTime oturumun saatini adım attırmaz")
	await _roam.end(0.0)
