extends TestCase
## Serbest Gez'in ışığı gerçek ana sahnede (K76; time.md §5.5; godot.md §3.5 «test_main_flow.gd: kayıtlı saati olmayan Serbest Gez gece
## menüsünden 2,4 sn'de 14:46,2 ışığına varır, menüye dönüşte menü karesi referansla aynıdır»; Yol Haritası roam-calendar, sun-light):
##   1) Menü gece kampıdır, saat okumaz: SkyRig yoktur, ay ışığı ve gece renk ayarı menününkidir.
##   2) SERBEST GEZ: saat 11 Nisan MÖ 209 14:46,2'de açılır; ışık gece menüsünden 2,4 sn'de süzülür, sonunda göğün güneşi menü vektörü
##      (1e−5 dolayı; time.md §17), ışık o dakikanın ikindi güneşinden gelir, gündüzün renk ayarı yazılır.
##   3) Esc → ANA MENÜ: uçuş boyunca (1,7 sn) ışık kimliğe döner; menüde her değer (ay ışığının yönü, rengi ve gücü, ortam, sis, LUT, gök
##      ve su tekdüzenleri, ateş) Serbest Gez'den önceki değerin kendisidir: menü karesi değişmez. Pencereli karşılaştırma
##      tools/capture.sh + tools/image_diff.py ile yapılır (docs/testler.md «Menü karesi»).
## Kayıtlar geçici bir klasördedir; çıkış sahte bir işlevle yakalanır.

const MAIN_SCENE := "res://scenes/main.tscn"
const TempDir := preload("res://tests/support/temp_dir.gd")

var _dir := ""


func before_each() -> void:
	MenuStyle.muted = true
	_dir = TempDir.fresh("roam_flow")


func after_each() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	TempDir.wipe(_dir)


func test_roam_fades_in_from_the_night_menu_and_returns_to_identity() -> void:
	var main = load(MAIN_SCENE).instantiate()
	main.quit_handler = func() -> void: pass
	main.saves = SaveSystem.new(_dir)
	main.prologue_path = ""
	add_child(main)
	await wait_frames(3)
	main.menu.finish_intro()
	var world: Node = main.world
	var moon := world.get_node(^"MoonLight") as DirectionalLight3D
	var env := (world.get_node(^"WorldEnvironment") as WorldEnvironment).environment
	var sky := env.sky.sky_material as ShaderMaterial
	var water := world.get_node_or_null(^"Water/WaterMesh") as GeometryInstance3D
	var water_mat := water.material_override as ShaderMaterial if water else null
	var fire := world.get_node_or_null(^"Camp/Campfire")
	assert_null(world.get_node_or_null(^"SkyRig"), "Menüde SkyRig yok: menü saati okumaz")
	var before := {
		"basis": moon.basis, "color": moon.light_color, "energy": moon.light_energy, "ambient": env.ambient_light_color,
		"ambient_energy": env.ambient_light_energy, "fog": env.fog_density, "lut": env.adjustment_color_correction,
		"exposure": env.tonemap_exposure, "zenith": sky.get_shader_parameter("zenith_color"),
		"moon_dir": sky.get_shader_parameter("moon_direction"), "night_sky": sky.get_shader_parameter("night_sky"),
		"water_deep": water_mat.get_shader_parameter("deep_color") if water_mat else null,
		"water_moon": water_mat.get_shader_parameter("moon_direction") if water_mat else null,
		"fire": fire.get(&"light_energy") if fire else null,
	}
	# 2) Serbest Gez: saat 11 Nisan 14:46,2, ışık 2,4 sn'de süzülür.
	main.menu.free_roam_requested.emit()
	await _wait_until(func() -> bool: return world.get_node_or_null(^"SkyRig") != null, 4.0)
	var rig := world.get_node_or_null(^"SkyRig") as SkyRig
	assert_not_null(rig, "Serbest Gez'de SkyRig ışığın tek yazıcısı")
	if rig == null:
		await _silence_audio()
		main.queue_free()
		return
	var roam: RoamTime = main._roam_time
	assert_true(roam.is_running(), "Serbest Gez'in saati akıyor")
	assert_eq(roam.clock.day_n, 1171, "11 Nisan MÖ 209")
	assert_true(absf(roam.clock.minute - Daylight.MENU_MINUTE) < 2.0, "14:46,2'de açılır (%s)" % roam.clock.text())
	assert_true(rig.is_taken(), "Menünün ışığı saklandı")
	assert_true(rig.is_fading(), "Gece menüsünden süzülme")
	await _wait_until(func() -> bool: return not rig.is_fading(), 4.0)
	assert_false(rig.is_fading(), "2,4 sn'de biter")
	var s := rig.current_sample()
	var sun_dir: Variant = sky.get_shader_parameter("sun_direction")
	assert_true(sun_dir is Vector3, "Göğün güneşi yazıldı")
	if sun_dir is Vector3:
		# Gök kırılmayla görünen yönü taşır (36,7°'de ≈0,02°); saat süzülme boyunca ≈1 oyun dakikası akmıştır (≈0,25°).
		assert_true(rad_to_deg((sun_dir as Vector3).angle_to(Daylight.MENU_SUN.normalized())) < 0.5, "Süzülmenin sonunda güneş menü vektöründe")
	assert_true(rad_to_deg(moon.basis.z.angle_to(Daylight.MENU_SUN.normalized())) < 0.5, "Işık ikindi güneşinden")
	assert_almost(moon.light_energy, float(s["light_energy"]), 1e-4, "Işığın gücü saatin örneği")
	assert_false(env.adjustment_color_correction == before["lut"], "Gündüzün renk ayarı")
	assert_eq(s["phase"], &"golden", "İkindi")
	# 3) Esc → ANA MENÜ: kimlik bit bit.
	main.player.pause_requested.emit()
	await _wait_until(func() -> bool: return main.pause_menu.is_open(), 3.0)
	await wait_frames(2)
	(main.pause_menu.get_menu() as GameMenu)._on_general("main")
	await _wait_until(func() -> bool: return main.state == main.State.MENU, 6.0)
	await _wait_until(func() -> bool: return not rig.is_taken(), 3.0)
	assert_eq(main.state, main.State.MENU, "Menüye dönüldü")
	assert_false(roam.is_running(), "Saat durdu")
	assert_true(moon.basis.is_equal_approx(before["basis"]), "Ay ışığının yönü menününki")
	assert_eq(moon.light_color, before["color"], "Rengi menününki")
	assert_eq(moon.light_energy, before["energy"], "Gücü menününki")
	assert_eq(env.ambient_light_color, before["ambient"], "Ortam")
	assert_eq(env.ambient_light_energy, before["ambient_energy"])
	assert_eq(env.fog_density, before["fog"], "Sis")
	assert_eq(env.tonemap_exposure, before["exposure"], "Pozlama")
	assert_true(env.adjustment_color_correction == before["lut"], "Menünün gece renk ayarı (aynı doku)")
	assert_eq(sky.get_shader_parameter("zenith_color"), before["zenith"], "Göğün tepesi")
	assert_eq(sky.get_shader_parameter("moon_direction"), before["moon_dir"], "Ayın yönü")
	assert_eq(sky.get_shader_parameter("night_sky"), before["night_sky"], "Gerçek gece göğü menüde kapalı")
	if water_mat:
		assert_eq(water_mat.get_shader_parameter("deep_color"), before["water_deep"], "Suyun rengi")
		assert_eq(water_mat.get_shader_parameter("moon_direction"), before["water_moon"], "Suyun parıltısı")
	if fire:
		assert_eq(fire.get(&"light_energy"), before["fire"], "Ateş")
	await _silence_audio()
	main.queue_free()
	await wait_frames(2)


func _silence_audio() -> void:
	var audio := get_node_or_null(^"/root/AudioManager")
	if audio:
		for p in audio.get_children():
			if p is AudioStreamPlayer:
				(p as AudioStreamPlayer).stop()
				(p as AudioStreamPlayer).stream = null
	await get_tree().create_timer(0.25).timeout


func _wait_until(condition: Callable, timeout: float) -> void:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while not condition.call() and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
