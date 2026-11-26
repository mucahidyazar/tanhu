extends TestCase
## Altı ışık durağı (LightStops, data/time/light_stops.json; K20, K58, K67, K101; time.md §5.1–§5.3, §5.5): saf sınamalar.
##   - Durakların sırası ve alanları; gece durağı Godot'nun menü gecesidir (world.tscn'nin ışığı ve ortamı, gök gölgelendiricisinin
##     varsayılanları): Serbest Gez'in gecesi menünün gecesi gibidir.
##   - Menü dakikası (14:46,2): s 4,3, renkler ikindi→akşam 0,3, ışık güneşin kendisi (menü vektörü), ateş böceği yok.
##   - Tanın ve akşamın gölge dolgusu soğuktur (K101): ortam rengi mavi, gökten pay 0.
##   - Işık kaynağının çarpanı (k) ölçüm dakikalarında; gece renk ayarının payı; yerel yıldız zamanı bir yıldız gününde bir tur döner.
##   - Tablonun başlangıç değerleri K101'in oranıyla çevrilmiştir (ikindi ve akşam prototipin menü ışığıdır).

const CAMP_SCENE := "res://scenes/world/world.tscn"
const SKY_SHADER_PATH := "res://shaders/sky.gdshader"
const ROAM_DAY := 1171


func before_each() -> void:
	LightStops.clear_cache()


func test_six_stops_in_order_with_their_fields() -> void:
	var table := LightStops.load_table()
	assert_false(table.is_empty(), "light_stops.json okunmalı")
	if table.is_empty():
		return
	assert_eq(table["order"], [&"night", &"dawn", &"morning", &"noon", &"golden", &"dusk"], "Durakların sırası (s 0..5)")
	assert_eq(table["order"], Daylight.STOPS, "Daylight.STOPS ile aynı")
	for id: StringName in table["order"]:
		var stop := LightStops.stop(table, id)
		for key in ["light_color", "light_energy", "ambient_color", "ambient_energy", "ambient_sky", "exposure", "grade_night", "sky", "fog", "water", "props"]:
			assert_true(stop.has(key), "%s: %s olmalı" % [id, key])
		assert_true(stop.get("light_color") is Color, "%s: renk çözülmeli" % id)
		var sky: Dictionary = stop.get("sky", {})
		var names := _sky_uniforms()
		for key: String in sky:
			assert_true(names.has(SkyRig.SKY_ALIASES.get(key, key)), "%s: gökte %s tekdüzeni olmalı" % [id, key])
	var camp := LightStops.place(table, "camp")
	assert_almost(float(camp["lat"]), Daylight.CAMP_LAT, 1e-12, "Kampın enlemi")
	assert_almost(float(camp["dec_offset"]), Daylight.CAMP_DEC_OFFSET, 1e-12, "Açılış payı")
	assert_almost(float(camp["golden"]), Daylight.CAMP_GOLDEN, 1e-12, "İkindi anahtarı 13:40")
	assert_almost(float(camp["menu"]), Daylight.MENU_MINUTE, 1e-12, "Menü anahtarı 14:46,2")


func test_night_stop_is_the_godot_menu_night() -> void:
	# Menünün gecesi: world.tscn'nin ay ışığı (0,42; 0,66 0,75 1) ve ortamı (0,3 0,38 0,66; 0,5; gökten 0,55), sis; gök varsayılanları.
	var night := LightStops.stop(LightStops.load_table(), &"night")
	var props := _scene_props()
	var light: Dictionary = props.get("MoonLight", {})
	var env := props.get("WorldEnvironment", {}).get("environment") as Environment
	assert_not_null(env, "Kampın ortamı okunmalı")
	if env == null:
		return
	assert_true((night["light_color"] as Color).is_equal_approx(light.get("light_color", Color.BLACK)), "Ay ışığının rengi")
	assert_almost(float(night["light_energy"]), float(light.get("light_energy", 0.0)), 1e-6, "Ay ışığının gücü")
	assert_true((night["ambient_color"] as Color).is_equal_approx(env.ambient_light_color), "Ortamın rengi")
	assert_almost(float(night["ambient_energy"]), env.ambient_light_energy, 1e-6, "Ortamın gücü")
	assert_almost(float(night["ambient_sky"]), env.ambient_light_sky_contribution, 1e-6, "Ortamın gökten payı")
	assert_almost(float(night["exposure"]), env.tonemap_exposure, 1e-6, "Pozlama")
	assert_true((night["fog"]["color"] as Color).is_equal_approx(env.fog_light_color), "Sisin rengi")
	assert_almost(float(night["fog"]["density"]), env.fog_density, 1e-9, "Sisin yoğunluğu")
	assert_almost(float(night["volumetric"]["density"]), env.volumetric_fog_density, 1e-9, "Hacimli sis")
	assert_almost(float(night["grade_night"]), 1.0, 1e-12, "Gece renk ayarı tam")
	assert_almost(float(night["saturation"]), env.adjustment_saturation, 1e-6, "Doygunluk menününki")
	assert_almost(float(night["contrast"]), env.adjustment_contrast, 1e-6, "Karşıtlık menününki")
	# Gök: gece durağının değerleri gölgelendiricinin varsayılanlarıdır (menü bu tekdüzenleri yazmaz).
	var defaults := _shader_defaults()
	var sky: Dictionary = night["sky"]
	for key: String in sky:
		var uniform: String = SkyRig.SKY_ALIASES.get(key, key)
		# Gerçek gece göğü ve ayın evresi yalnız Serbest Gez'indir (menünün varsayılanı 0: sabit yıldız alanı).
		if not defaults.has(uniform) or uniform in ["night_sky", "moon_phase_shade", "sky_rotation", "sky_latitude"]:
			continue
		var want: Variant = defaults[uniform]
		var got: Variant = sky[key]
		if got is Color:
			assert_true((got as Color).is_equal_approx(want), "Gece göğü %s menününki" % key)
		else:
			assert_almost(float(got), float(want), 1e-6, "Gece göğü %s menününki" % key)
	for key in ["sun_glow_strength", "sun_disc_size", "cloud_light_from_sun"]:
		assert_almost(float(sky[key]), 0.0, 1e-12, "Gece %s 0 (menü)" % key)


func test_menu_minute_is_afternoon_to_evening_point_three() -> void:
	var table := LightStops.load_table()
	var s := LightStops.sample(table, "camp", ROAM_DAY, Daylight.MENU_MINUTE)
	assert_almost(float(s["s"]), 4.3, 1e-9, "Menü dakikasında s 4,3")
	var golden := LightStops.stop(table, &"golden")
	var dusk := LightStops.stop(table, &"dusk")
	assert_true((s["light_color"] as Color).is_equal_approx((golden["light_color"] as Color).lerp(dusk["light_color"], 0.3)), "Işığın rengi ikindi→akşam 0,3")
	assert_true((s["ambient_color"] as Color).is_equal_approx((golden["ambient_color"] as Color).lerp(dusk["ambient_color"], 0.3)), "Ortam 0,3")
	assert_almost(float(s["light_k"]), 1.0, 1e-9, "36,7°'de güneş tam")
	assert_almost(float(s["light_energy"]), lerpf(float(golden["light_energy"]), float(dusk["light_energy"]), 0.3), 1e-9, "Güç 0,3")
	assert_true(rad_to_deg((s["light_dir"] as Vector3).angle_to(Daylight.MENU_SUN.normalized())) < 0.25, "Işık menü güneşinden (dakikanın başı: ≤0,25° adım)")
	assert_vec_almost(s["sun_dir"], Daylight.MENU_SUN.normalized(), 2e-5, "Göğün güneşi menü vektörü")
	assert_almost(float((s["props"] as Dictionary)["motes"]), 0.0, 1e-12, "İlk karede ateş böceği yok (time.md §5.3)")
	assert_eq(s["phase"], &"golden")
	assert_eq(s["night_class"], &"day")
	assert_almost(float(s["grade_night"]), 0.0, 1e-12, "Gündüz renk ayarı")


func test_motes_channel_and_night_grade_ramp() -> void:
	var table := LightStops.load_table()
	assert_almost(LightStops.motes_at(table, 4.0), 0.0, 1e-12, "İkindi başı")
	assert_almost(LightStops.motes_at(table, 4.3), 0.0, 1e-12, "Menü anahtarı")
	assert_almost(LightStops.motes_at(table, 4.65), 0.5, 1e-9, "Menüden batışa yarı")
	assert_almost(LightStops.motes_at(table, 5.0), 1.0, 1e-12, "Batış")
	assert_almost(LightStops.motes_at(table, 0.0), 1.0, 1e-12, "Gece")
	assert_almost(LightStops.motes_at(table, 1.0), 0.6, 1e-12, "Tan")
	assert_almost(LightStops.motes_at(table, 2.0), 0.0, 1e-12, "Sabah")
	assert_almost(float(LightStops.mix_stops(table, 5.5)["grade_night"]), 0.5, 1e-12, "Akşam→gece yarı yolda gece renk ayarı yarı")
	assert_almost(float(LightStops.mix_stops(table, 0.5)["grade_night"]), 0.5, 1e-12, "Gece→tan yarı yolda")
	assert_almost(float(LightStops.mix_stops(table, 3.0)["grade_night"]), 0.0, 1e-12, "Öğle")


func test_dawn_and_dusk_shadow_fill_stay_cold() -> void:
	# K101: tanın ve akşamın gölge dolgusu tablonun sky rengi gibi soğuk kalır; yoksa camgöbeği boya otun zeytin grisine düşer.
	var table := LightStops.load_table()
	for id: StringName in [&"dawn", &"dusk"]:
		var stop := LightStops.stop(table, id)
		var fill: Color = stop["ambient_color"]
		assert_true(fill.b > fill.r + 0.2 and fill.b > fill.g + 0.15, "%s: ortam rengi mavi (%s)" % [id, fill])
		assert_almost(float(stop["ambient_sky"]), 0.0, 1e-12, "%s: ortamın gökten payı 0 (dolgu yalnız soğuk renk)" % id)
		assert_true(float(stop["fog"]["color"].b) > float(stop["fog"]["color"].r), "%s: sis soğuk" % id)


func test_table_values_follow_the_k101_conversion() -> void:
	# light_energy = sunI × 0,376; ambient_energy = hemi × 0,291; pozlama × 0,84 (time.md §5.3 tablosu; gece menünündür).
	var table := LightStops.load_table()
	var want := {&"dawn": [1.25, 1.25, 1.36], &"morning": [3.2, 1.55, 1.22], &"noon": [4.1, 1.75, 1.16], &"golden": [3.75, 1.62, 1.24], &"dusk": [1.55, 1.32, 1.38]}
	for id: StringName in want:
		var stop := LightStops.stop(table, id)
		assert_almost(float(stop["light_energy"]), float(want[id][0]) * 0.376, 0.006, "%s: ışık sunI × 0,376" % id)
		assert_almost(float(stop["ambient_energy"]), float(want[id][1]) * 0.291, 0.006, "%s: ortam hemi × 0,291" % id)
		assert_almost(float(stop["exposure"]), float(want[id][2]) * 0.84, 0.006, "%s: pozlama × 0,84" % id)
	assert_true((LightStops.stop(table, &"golden")["light_color"] as Color).is_equal_approx(Color("#ffcb8a")), "İkindi prototipin menü ışığı")
	assert_true((LightStops.stop(table, &"dusk")["light_color"] as Color).is_equal_approx(Color("#ff9f6d")), "Akşam prototipin menü ışığı")


func test_probe_minutes_hit_each_stop_with_its_light_source() -> void:
	# Ölçüm kareleri 11 Nisan'ın anahtarlarında: s tam durak; tan ve akşamda güneş ufukta (k 0,35), gece ay batık (k 0,55), gündüz 1.
	var table := LightStops.load_table()
	var day := LightStops.probe_day(table)
	assert_eq(day, ROAM_DAY)
	var want_k := {&"night": 0.55, &"dawn": 0.35, &"morning": 1.0, &"noon": 1.0, &"golden": 1.0, &"dusk": 0.35}
	for i in 6:
		var id: StringName = table["order"][i]
		var m := LightStops.probe_minute(table, id)
		assert_false(is_nan(m), "%s: ölçüm dakikası" % id)
		var s := LightStops.sample(table, "camp", day, m)
		assert_almost(float(s["s"]), float(i), 0.02, "%s: s %d" % [id, i])
		assert_almost(float(s["light_k"]), float(want_k[id]), 0.02, "%s: k" % id)
		assert_true((s["light_dir"] as Vector3).y >= sin(deg_to_rad(Daylight.SHADOW_EL)) - 1e-4, "%s: ışık 15°'nin altından gelmez" % id)


func test_light_direction_steps_once_per_game_minute() -> void:
	# time.md §5.1: yön oyun dakikasında bir adım; dakika içinde aynı, göğün güneşi ise o anın kendisi.
	var table := LightStops.load_table()
	var a := LightStops.sample(table, "camp", ROAM_DAY, 900.1)
	var b := LightStops.sample(table, "camp", ROAM_DAY, 900.9)
	assert_vec_almost(a["light_dir"], b["light_dir"], 1e-7, "Dakika içinde ışığın yönü aynı")
	assert_false((a["sun_dir"] as Vector3).is_equal_approx(b["sun_dir"]), "Göğün güneşi akar")
	var c := LightStops.sample(table, "camp", ROAM_DAY, 901.0)
	assert_true(rad_to_deg((a["light_dir"] as Vector3).angle_to(c["light_dir"])) <= 0.26, "Bir adım ≤0,25°")


func test_sky_turns_once_per_sidereal_day() -> void:
	# Gök kutbun çevresinde yıldız günüyle döner: bir tur 23 sa 56 dk oyun saati (time.md §5.6).
	var a := LightStops.sidereal_angle(ROAM_DAY, 600.0)
	var b := LightStops.sidereal_angle(ROAM_DAY + 1, 600.0 - 3.93)
	assert_almost(angle_difference(a, b), 0.0, 0.002, "23 sa 56 dk sonra gök aynı yerde")
	var c := LightStops.sidereal_angle(ROAM_DAY, 1320.0)
	assert_almost(fposmod(c - a, TAU), deg_to_rad(180.49), 0.002, "12 saatte yarım tur (artı güneşin yarım günlük kayması)")
	# Nisan gece yarısı Büyük Ayı kutbun üstündedir (yerel yıldız zamanı ≈13 sa; Alioth'un sağ açıklığı MÖ 209'da ≈165°).
	var lst := rad_to_deg(LightStops.sidereal_angle(ROAM_DAY + 1, 0.0))
	assert_between(fposmod(lst - 165.0 + 180.0, 360.0) - 180.0, -50.0, 50.0, "Büyük Ayı Nisan gecesinde meridyende")


func test_cape_measurement_follows_the_light_stops() -> void:
	# K101 → sun-light: pelerin ölçümünün durakları (cape_light_stops.json v3) oyunun ışık duraklarından çözülür (cape_lineup --export-stops).
	var path := "res://data/character/cape_light_stops.json"
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, "Pelerin durakları okunmalı")
	if not parsed is Dictionary:
		return
	assert_eq(int(parsed["version"]), 3, "v3: oyunun ışık durakları")
	var table := LightStops.load_table()
	var seen := {}
	for row: Dictionary in parsed["stops"]:
		var id := StringName(str(row.get("light_stop", "")))
		seen[id] = true
		var p := LightStops.probe_sample(table, id)
		assert_false(p.is_empty(), "%s: ışık durağı var" % row["id"])
		if p.is_empty():
			continue
		var sample: Dictionary = row["sample"]
		assert_eq(str(row["minute"]), GameClock.hhmm(float(p["minute"])), "%s: ölçüm dakikası" % row["id"])
		assert_almost(float(sample["light_energy"]), float(p["light_energy"]), 1e-3, "%s: ışığın gücü (× k)" % row["id"])
		assert_almost(float(sample["ambient_energy"]), float(p["ambient_energy"]), 1e-3, "%s: ortam" % row["id"])
		assert_almost(float(sample["exposure"]), float(p["exposure"]), 1e-3, "%s: pozlama" % row["id"])
		var lc: Color = p["light_color"]
		var ac: Color = p["ambient_color"]
		for i in 3:
			assert_almost(float(sample["light_color"][i]), [lc.r, lc.g, lc.b][i], 1e-3, "%s: ışığın rengi" % row["id"])
			assert_almost(float(sample["ambient_color"][i]), [ac.r, ac.g, ac.b][i], 1e-3, "%s: ortamın rengi" % row["id"])
		assert_almost(float(row["light_azimuth"]), float(p["light_azimuth"]), 0.02, "%s: azimut" % row["id"])
		assert_almost(float(row["light_elevation"]), float(p["light_elevation"]), 0.02, "%s: yükseklik" % row["id"])
		assert_eq(str(row["grade"]), "night" if float(p["grade_night"]) >= 0.5 else "world", "%s: renk ayarı" % row["id"])
	for id: StringName in table["order"]:
		assert_true(seen.has(id), "%s durağı ölçülür" % id)


# --- Yardımcılar ------------------------------------------------------------------------------------

func _sky_uniforms() -> Dictionary:
	var names := {}
	for u in (load(SKY_SHADER_PATH) as Shader).get_shader_uniform_list():
		names[str(u["name"])] = true
	return names


## Kamp sahnesinin düğüm özellikleri (sahneyi kurmadan): {düğüm adı: {özellik: değer}}.
func _scene_props() -> Dictionary:
	var state := (load(CAMP_SCENE) as PackedScene).get_state()
	var out := {}
	for i in state.get_node_count():
		var props := {}
		for j in state.get_node_property_count(i):
			props[str(state.get_node_property_name(i, j))] = state.get_node_property_value(i, j)
		out[str(state.get_node_name(i))] = props
	return out


## Gök gölgelendiricisinin sayı ve renk varsayılanları (kaynak metinden: float ve vec3).
func _shader_defaults() -> Dictionary:
	var code := FileAccess.get_file_as_string(SKY_SHADER_PATH)
	var out := {}
	var re_f := RegEx.create_from_string("uniform\\s+float\\s+(\\w+)\\s*(?::[^=;]*)?=\\s*([-0-9.]+)\\s*;")
	for m in re_f.search_all(code):
		out[m.get_string(1)] = m.get_string(2).to_float()
	var re_v := RegEx.create_from_string("uniform\\s+vec3\\s+(\\w+)\\s*(?::[^=;]*)?=\\s*vec3\\(([^)]*)\\)\\s*;")
	for m in re_v.search_all(code):
		var parts := m.get_string(2).split(",")
		if parts.size() == 3:
			out[m.get_string(1)] = Color(parts[0].to_float(), parts[1].to_float(), parts[2].to_float())
	return out
