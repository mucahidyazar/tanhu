extends TestCase
## Havanın yürütücüsü ve görünümü (WeatherSim, WeatherLook, WeatherView, CampWeather; weather.md §5.8, §6.3, §8.7, §9, §12.7; W12, W15,
## W25, W27): sahnesiz ve küçük bir deneme dünyasıyla.
##   - Kimlik (k 0): SkyRig'in hava girdisi etkisiz, genel tekdüzenler 0, görünüm gizli: menü karesi değişmez (W12).
##   - Yağmur: ekran yağışı ve sıçrama, kar: 3B noktalar, dolu: nokta ve sekme; görünüm menüye dönüşte kimliğe karışır ve iz bırakmaz.
##   - Fırtına: şimşek dizisi oynar, nabız 0..1; Serbest Gez'in tasarlanmış düşüşü kadrajda ve Çocuktan ≥25 m (W25); ışık eklenmez (W15).
##   - Kamp: mevsimi takvim verir (camp_spring → camp_winter), kar yalnız kışın tutar (W27); ilk Serbest Gez 0,5 sa açık (§6.3).
##   - Kayıt: weather bloğu ≤1 KB, durağan denetimden geçer, yükleme aynı planı verir (W23).

const SPRING_DAY := 1171
const WINTER_DAY := 1171 + 230


func _sim(day_n: int = SPRING_DAY, minute: float = 886.18, seed: int = 4242) -> WeatherSim:
	var s := WeatherSim.new()
	s.structure_done = func(_id: String) -> bool: return true
	s.setup("tanhu_camp", {}, GameClock.abs_of(day_n, minute) / 60.0, day_n, seed)
	s.from_identity(true)
	return s


func _ctx(day_n: int = SPRING_DAY) -> WeatherSim.Ctx:
	var c := WeatherSim.Ctx.new()
	c.day_n = day_n
	c.cam_fwd_x = 0.0
	c.cam_fwd_z = -1.0
	return c


static func _run(s: WeatherSim, ctx: WeatherSim.Ctx, h0: float, seconds: float, dt: float = 1.0 / 30.0) -> float:
	var t := 0.0
	var h := h0
	while t < seconds:
		s.step(dt, h, ctx)
		t += dt
		h += dt / WeatherPlanner.S_PER_H
	return h


# --- Görünüş hesabı -------------------------------------------------------------------------------------------------

func test_identity_look_is_neutral() -> void:
	var p := WeatherData.params_of(WeatherData.index_of(&"thunderstorm"))
	var w := WeatherLook.sky_rig_params(p, 0.0, 1.0, 1.0, 28.0, Vector2(1, 0))
	assert_almost(float(w["light_mul"]), 1.0, 1e-12, "Kimlikte ışık çarpanı 1")
	assert_almost(float(w["ambient_mul"]), 1.0, 1e-12)
	assert_almost(float(w["exposure_mul"]), 1.0, 1e-12)
	assert_almost(float(w["fog_density_mul"]), 1.0, 1e-12)
	assert_almost(float(w["flash"]), 0.0, 1e-12, "Kimlikte şimşek yok")
	assert_false(w.has("shadow"), "Kimlikte gölge örneğin")
	for key: String in ["weather_cover", "weather_dark", "weather_flash", "weather_dust"]:
		assert_almost(float(w["sky"][key]), 0.0, 1e-12, "Gök katmanı %s 0" % key)
	var fx := WeatherFx.new()
	fx.wet_ground = 1.0
	fx.snowpack = 0.5
	assert_eq(WeatherLook.ground(fx, 0.0, true), Vector4.ZERO, "Zemin tekdüzeni kimlikte 0")
	assert_eq(WeatherLook.wind(fx, 0.0), Vector4.ZERO, "Rüzgâr tekdüzeni kimlikte 0: çim kendi rüzgârında")
	assert_true(WeatherLook.grade_is_identity(WeatherLook.grade(p, 0.0)))


func test_storm_look_darkens_and_fogs() -> void:
	var p := WeatherData.params_of(WeatherData.index_of(&"thunderstorm"))
	var w := WeatherLook.sky_rig_params(p, 1.0, 0.0, 1.0, 28.0, Vector2.ZERO)
	assert_almost(float(w["light_mul"]), 0.12, 1e-9, "Fırtınada güneş ×0,12 (§3.4)")
	assert_almost(float(w["exposure_mul"]), 1.0, 1e-9, "Fırtınada pozlama telafisi yok")
	assert_eq(w.get("shadow"), false, "Kapalı gökte gölge kapanır")
	# Sis uzağında %95 sis (üstel: 3 / uzak); kısalma payıyla örneğin yoğunluğundan geçilir.
	var base := 0.00045
	var fog_p := WeatherData.params_of(WeatherData.index_of(&"fog"))
	var dens := WeatherLook.fog_density(base, fog_p, 28.0)
	assert_almost(dens, lerpf(base, 3.0 / 98.0, 0.93), 1e-9, "Siste 98 m (kamera tabanı 78 m'nin üstünde)")
	assert_true(1.0 - exp(-dens * 98.0) > 0.9, "Siste kadrajın tepesi (≈100 m) tam sisli")
	assert_true(1.0 - exp(-dens * 28.0) < 0.6, "Oyuncu (28 m) görünür kalır")
	var bliz := WeatherLook.fog_density(base, WeatherData.params_of(WeatherData.index_of(&"blizzard")), 28.0)
	assert_almost(bliz, 3.0 / 140.0, 1e-9, "Tipi sisi mutlak 140 m")
	var clear := WeatherLook.fog_density(base, WeatherData.params_of(WeatherData.index_of(&"clear")), 28.0)
	assert_almost(clear, base, 1e-12, "Açıkta örneğin sisi aynen")
	var rain := WeatherLook.sky_rig_params(WeatherData.params_of(WeatherData.index_of(&"rain")), 1.0, 0.0, 1.0, 28.0, Vector2.ZERO, base)
	assert_true(float(rain["fog_density_mul"]) > 5.0, "Yağmurda sis kalınlaşır (490 m)")
	var g := WeatherLook.grade(WeatherData.params_of(WeatherData.index_of(&"blizzard")), 1.0)
	assert_almost(float(g["sat"]), 0.655, 1e-9, "Tipi doygunluğu act1 §10")
	var gale := WeatherFx.new()
	gale.wind = 16.0
	gale.dir_x = 1.0
	gale.dir_z = 0.0
	assert_almost(WeatherLook.wind(gale, 1.0).z, 2.309, 0.001, "Fırtınada çim bükümü ×2,3 (W18)")


# --- Yürütücü ---------------------------------------------------------------------------------------------------------

func test_first_roam_is_clear_for_half_an_hour_then_planner() -> void:
	var s := _sim()
	s.begin_roam(GameClock.abs_of(SPRING_DAY, 886.18) / 60.0)
	var ctx := _ctx()
	var h0 := GameClock.abs_of(SPRING_DAY, 886.18) / 60.0
	s.step(0.1, h0, ctx)
	assert_eq(s.type_id(), &"clear", "İlk Serbest Gez 0,5 sa açık (roam_first)")
	assert_true(s.locked("roam_first"))
	s.step(0.1, h0 + 0.51, ctx)
	assert_false(s.locked("roam_first"), "0,5 sa sonra planlayıcı sürer")
	assert_eq(s.planner.season, "camp_spring", "Kampın baharı (11 Nisan)")


func test_camp_season_rows_and_snow_only_in_winter() -> void:
	var s := _sim()
	assert_eq(s.row_season, "camp_spring")
	assert_false(WeatherData.accumulates(s.cfg, s.season), "Baharda kar tutmaz")
	var w := _sim(WINTER_DAY)
	assert_eq(w.row_season, "camp_winter", "16 Kasım'dan kampın kışı")
	assert_true(WeatherData.accumulates(w.cfg, w.season), "Kışın kar tutar")
	# Takvim kışa geçince satır değişir (K67, W27).
	var ctx := _ctx(SPRING_DAY)
	var h := GameClock.abs_of(SPRING_DAY, 600.0) / 60.0
	s.step(0.1, h, ctx)
	ctx.day_n = GameCalendar.day_n_of(16, 11, 209)
	s.step(0.1, h + 0.01, ctx)
	assert_eq(s.season, "winter")
	assert_eq(s.planner.season, "camp_winter", "Planlayıcı kampın kış satırına geçer")
	ctx.day_n = GameCalendar.day_n_of(20, 5, 208)
	s.step(0.1, h + 0.02, ctx)
	assert_eq(s.planner.season, "camp_summer", "15 Mayıs'tan kampın yazı")


func test_forced_rain_wets_ground_and_signals_change() -> void:
	var s := _sim()
	var ctx := _ctx()
	var w := watch_signal(s.changed)
	var h := GameClock.abs_of(SPRING_DAY, 600.0) / 60.0
	s.step(0.1, h, ctx)
	assert_true(s.force("rain", true, 0.0))
	h = _run(s, ctx, h, 60.0)
	assert_eq(s.type_id(), &"rain")
	assert_true(w.fired, "weather:change yayılır")
	assert_almost(s.p[WeatherData.P_RAIN], 0.6, 1e-9, "Yağmurun ekran yağışı 0,6")
	# 1,4 oyun saati yağmur zemini ıslatır (k 0,8): 1 − e^(−1,12) ≈ 0,67.
	h = _run(s, ctx, h, 150.0, 0.25)
	assert_almost(s.fx.wet_ground, 1.0 - exp(-0.8 * 1.4), 0.02, "1,4 sa'te zemin ≈0,67")
	assert_true(s.fx.mud > 0.1, "Çamur zemini izler")
	assert_true(s.fx.vis <= 200.0 + 1e-6, "Yağmurda görüş 200 m")


func test_storm_flashes_and_designed_strike_lands_in_frame_away_from_child() -> void:
	var s := _sim(SPRING_DAY, 600.0, 99)
	var ctx := _ctx()
	ctx.player_x = 10.0
	ctx.player_z = 20.0
	ctx.cam_fwd_x = 0.0
	ctx.cam_fwd_z = -1.0
	var h := GameClock.abs_of(SPRING_DAY, 600.0) / 60.0
	s.step(0.1, h, ctx)
	s.force("thunderstorm", true, 0.0)
	var strikes: Array[Dictionary] = []
	s.strike.connect(func(info: Dictionary) -> void: strikes.append(info))
	var thunders := watch_signal(s.thunder)
	var max_flash := 0.0
	var t := 0.0
	while t < 260.0:
		s.step(1.0 / 30.0, h, ctx)
		max_flash = maxf(max_flash, s.flash_k)
		t += 1.0 / 30.0
		h += (1.0 / 30.0) / WeatherPlanner.S_PER_H
	assert_true(max_flash > 0.5 and max_flash <= 1.0, "Şimşek nabzı 0..1 (%.2f)" % max_flash)
	assert_true(thunders.count > 0, "Gök gürültüsü gecikmeyle gelir")
	var near: Array[Dictionary] = []
	for e in strikes:
		if bool(e["near"]):
			near.append(e)
	# Tasarlanmış düşüş olasılıklıdır (%60); bu tohumda düşer. Kadrajda (kameranın baktığı yönde 30–70 m), Çocuktan ≥25 m.
	assert_true(near.size() <= 1, "Fırtına başına ≤1 tasarlanmış düşüş")
	for e in near:
		var dx := float(e["x"]) - 10.0
		var dz := float(e["z"]) - 20.0
		var d := sqrt(dx * dx + dz * dz)
		assert_true(d >= 25.0 - 1e-6 and d <= 31.5, "Çocuğun 25 m'si boş, kadrajın üst köşesinde (%.1f m)" % d)
		assert_true(dz <= -20.0 + 1e-6 and dz >= -24.0 - 1e-6, "Kameranın baktığı yönde 20–24 m ileride (kuzey)")
	assert_true(s.bolts.size() > 0, "Görünüme şerit kuyruğu")


func test_strike_rate_in_camp_storms_w25() -> void:
	# Kamp fırtınalarının ≥%50'sinde kadraja yakın düşüş (tasarlanmış %60; doğal ≤600 m düşüşler de görünür).
	var seen := 0
	var n := 40
	var out: Array[WeatherStorm.Event] = []
	for i in n:
		WeatherStorm.storm_events(100.0 + i * 7.0, 100.0 + i * 7.0 + 1.8, 31337, WeatherRng.str_hash("tanhu_camp"), 0.871, 0.49, 0.6, 1.0, out)
		for e in out:
			if e.ground and (e.near or e.d <= 600.0):
				seen += 1
				break
	assert_true(float(seen) / n >= 0.5, "Fırtınaların %d/%d'ında kadraja yıldırım" % [seen, n])


func test_menu_identity_blend_and_save_round_trip() -> void:
	var s := _sim()
	var ctx := _ctx()
	var h := GameClock.abs_of(SPRING_DAY, 700.0) / 60.0
	s.step(0.1, h, ctx)
	s.force("downpour", true, 0.0)
	h = _run(s, ctx, h, 10.0)
	assert_almost(s.enter_k, 1.0, 1e-9)
	s.to_identity(1.7)
	assert_eq(s.fx.type, &"clear", "Menüye dönüşte fx kimlik")
	h = _run(s, ctx, h, 1.0)
	assert_between(s.enter_k, 0.35, 0.5, "1,7 sn'lik kimlik karışımı sürüyor")
	h = _run(s, ctx, h, 1.0)
	assert_almost(s.enter_k, 0.0, 1e-9, "1,7 sn'de kimlik")
	# Kayıt.
	var t := _sim()
	t.step(0.1, h, ctx)
	_run(t, ctx, h, 5.0)
	var d := t.to_dict()
	assert_eq(WeatherPlanner.validate_save_block(d), "", "Blok durağan denetimden geçer")
	assert_true(JSON.stringify(d).length() <= 1024, "Blok ≤1 KB (%d)" % JSON.stringify(d).length())
	var r := _sim()
	assert_true(r.from_dict(JSON.parse_string(JSON.stringify(d)), h))
	assert_eq(r.planner.plan[0].brief(), t.planner.plan[0].brief(), "Yükleme aynı planı verir")
	assert_ne(WeatherPlanner.validate_save_block({"v": 1, "plan": "x"}), "", "Bozuk blok reddedilir")


## Oturumun blok kaydı (Session.blocks, kayıt v2): register_block yazmayı ve okumayı bağlar; menünün durağan denetimi (OWNERS →
## WeatherPlanner.validate_save_block) bloğu geçirir; kayıttan taşınan blok kayıt anında okunur ve aynı planı verir.
func test_save_block_binds_to_session_blocks() -> void:
	var ctx := _ctx()
	var h := GameClock.abs_of(SPRING_DAY, 886.18) / 60.0
	var cw := CampWeather.new()
	cw.sim = _sim()
	cw.sim.step(0.1, h, ctx)
	cw.sim.force("rain", true, 0.0)
	h = _run(cw.sim, ctx, h, 2.0)
	var blocks := SaveBlocks.new()
	cw.register_block(blocks)
	assert_true(blocks.has_block("weather"), "Blok oturumun kaydında")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(blocks.collect()))
	assert_eq(SaveBlocks.check_blocks(saved), "", "Menünün durağan denetimi bloğu geçirir")
	var clock := GameClock.new()
	clock.day_n = SPRING_DAY
	clock.minute = h * 60.0 - GameClock.abs_of(SPRING_DAY, 0.0)
	var cw2 := CampWeather.new()
	cw2.sim = _sim()
	cw2._clock = clock
	var blocks2 := SaveBlocks.new()
	assert_eq(blocks2.apply(saved), "", "Kaydın blokları okunur")
	cw2.register_block(blocks2)
	assert_eq(cw2.sim.planner.plan[0].brief(), cw.sim.planner.plan[0].brief(), "Taşınan blok kayıt anında okunur: aynı plan")
	cw.free()
	cw2.free()


## Göl boğası (§10.2, K35): göllü kampta gök gürültülü fırtına ya da fırtına cephesinden ≤1 sa önce, cephe başına bir kez; gölsüz
## bölgede hiç.
func test_lake_bull_once_per_storm_front_in_lake_camp() -> void:
	var day := SPRING_DAY + 70
	var s := _sim(day, 360.0, 777)
	var got: Array[Dictionary] = []
	s.lake_bull.connect(func(info: Dictionary) -> void: got.append(info))
	var ctx := _ctx(day)
	var h := GameClock.abs_of(day, 360.0) / 60.0
	var fronts := {}
	for i in 24 * 30 * 4:
		s.step(WeatherSim.SLOW_S + 0.01, h, ctx)
		if s.signs.has_front and String(s.signs.front_type) in WeatherSim.LAKE_BULL_FRONTS and s.signs.front_in_h <= 1.0:
			fronts[s.signs.front_t0] = true
		h += 0.25
	assert_true(got.size() > 0, "Yaz ayında en az bir fırtına cephesi (%d)" % got.size())
	assert_eq(got.size(), fronts.size(), "Cephe başına bir kez")
	for info in got:
		assert_true(String(info["type"]) in WeatherSim.LAKE_BULL_FRONTS)
		assert_between(float(info["in_h"]), 0.0, 1.0, "Cepheden ≤1 sa önce")
	var dry := WeatherSim.new()
	dry.structure_done = func(_id: String) -> bool: return true
	dry.setup("hexi_winter", {}, GameClock.abs_of(day, 360.0) / 60.0, day, 777)
	assert_false(bool(dry.cfg.get("lake", false)), "Hexi'de göl yok: göl boğası çalmaz")


func test_snowpack_grows_in_camp_winter_snow() -> void:
	var s := _sim(WINTER_DAY, 600.0)
	var ctx := _ctx(WINTER_DAY)
	var h := floorf(GameClock.abs_of(WINTER_DAY, 600.0) / 60.0)
	s.step(0.1, h, ctx)
	s.force("heavy_snow", true, 0.0)
	s.skip(h, h + 6.0)
	assert_almost(s.pack.snowpack, 0.54, 1e-6, "Yoğun kar saatte 0,09 (6 sa)")
	s.step(0.1, h + 6.0, ctx)
	assert_true(s.fx.snowpack > 0.4)
	assert_true(WeatherLook.ground(s.fx, 1.0, true).y > 0.9, "Kampın kış kar örtüsü görünür")


# --- Görünüm ----------------------------------------------------------------------------------------------------------

func _world() -> Node3D:
	var w := Node3D.new()
	w.name = "TestWorld"
	var env := WorldEnvironment.new()
	env.name = "WorldEnvironment"
	env.environment = Environment.new()
	w.add_child(env)
	var light := DirectionalLight3D.new()
	light.name = "SunLight"
	w.add_child(light)
	var cam := Camera3D.new()
	cam.name = "Cam"
	cam.position = Vector3(0.0, 18.0, 22.0)
	w.add_child(cam)
	add_child(w)
	cam.look_at(Vector3.ZERO)
	cam.make_current()
	return w


func test_view_draws_rain_and_returns_to_identity() -> void:
	var w := _world()
	var s := _sim()
	var ctx := _ctx()
	var h := GameClock.abs_of(SPRING_DAY, 700.0) / 60.0
	s.step(0.1, h, ctx)
	s.force("rain", true, 0.0)
	h = _run(s, ctx, h, 2.0)
	var view := WeatherView.new()
	w.add_child(view)
	view.bind(s, w, null)
	for i in 5:
		h += (1.0 / 30.0) / WeatherPlanner.S_PER_H
		s.step(1.0 / 30.0, h, ctx)
		view.update(1.0 / 30.0)
	assert_almost(view.last_precip.x, 0.6, 1e-6, "Ekran yağışı yağmurda 0,6")
	assert_true(view.screen_rect().visible, "Ekran katmanı görünür")
	assert_eq(view.last_points, 0, "Yağmur 3B nokta almaz (derinliği sıçramadadır)")
	assert_true(view.last_splashes > 0, "Sıçrama havuzu dolar")
	assert_eq(view.layer_alpha, WeatherView.LAYER_ALPHA)
	assert_true(WeatherView.LAYER_ALPHA in [0.5, 0.65], "Katman alfası yalnız 0,5 ya da 0,65 (K58, W16)")
	assert_true(ProjectSettings.has_setting("shader_globals/weather_ground"), "weather_ground genel tekdüzeni tanımlı")
	assert_true(ProjectSettings.has_setting("shader_globals/weather_wind"), "weather_wind genel tekdüzeni tanımlı")
	assert_true(view.last_wind.z > 0.0, "Rüzgâr tekdüzeni yazıldı")
	# Kar: 3B noktalar.
	s.force("snow", true, 0.0)
	for i in 3:
		h += (1.0 / 30.0) / WeatherPlanner.S_PER_H
		s.step(1.0 / 30.0, h, ctx)
		view.update(1.0 / 30.0)
	assert_eq(view.last_points, 3000, "Kar 3000 nokta")
	# Menüye dönüş: kimlik.
	s.to_identity(0.0)
	view.update(1.0 / 30.0)
	assert_false(view.screen_rect().visible, "Kimlikte ekran katmanı gizli")
	assert_false(view.precip_node().visible, "Kimlikte noktalar gizli")
	assert_eq(view.last_ground, Vector4.ZERO, "Zemin tekdüzeni 0")
	assert_eq(view.last_wind, Vector4.ZERO, "Rüzgâr tekdüzeni 0")
	w.queue_free()


func test_camp_weather_follows_roam_clock() -> void:
	var w := _world()
	var roam := Node.new()
	roam.set_script(load("res://tests/support/weather_fake_roam.gd"))
	add_child(roam)
	var clock := GameClock.new(SPRING_DAY, 886.18)
	roam.set(&"clock", clock)
	var cw := CampWeather.new()
	add_child(cw)
	cw.begin(w, roam, null, null, true)
	assert_true(cw.is_running())
	assert_eq(cw.sim.zone, "tanhu_camp")
	var h0: float = clock.abs_minute() / 60.0
	clock.skip(90.0, &"dev")
	cw._process(0.1)
	assert_almost(cw.sim.planner.now, h0 + 1.5, 1e-6, "Hava oyunun saatini okur")
	cw.end(0.0)
	assert_false(cw.is_running())
	cw.queue_free()
	roam.queue_free()
	w.queue_free()
