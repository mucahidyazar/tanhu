extends TestCase
## Atlas testleri (E20; godot.md §4.8; site Harita): prototipin 75.000 km²'lik haritasının Godot verisi (AtlasGeo), açılma kuralları ve
## siyasi katman (AtlasPolitical), kitabın HARİTA sayfasının kamerası, düzeyleri (Bozkır Dünyası › bölge › vadi › yer), yakınlaşması
## ve girdisi. Girdi testleri olayı görünümden geçirir (Viewport.push_input): tekerlek, iki parmakla kıstırma (InputEventMagnifyGesture)
## ve iki parmakla kaydırma (InputEventPanGesture) haritaya ulaşır, başka bir düğüm yutmaz. Son test gerçek ana sahnede Serbest Gez'e
## iner, M ile kitabı açar ve aynı olayları kökün görünümüne verir.

const MAIN_SCENE := "res://scenes/main.tscn"
const TempDir := preload("res://tests/support/temp_dir.gd")
const VIEW := Vector2(1920.0, 968.0)

var _dir := ""


func before_each() -> void:
	MenuStyle.muted = true
	InputSetup.ensure_actions()


func after_each() -> void:
	get_tree().paused = false
	if not _dir.is_empty():
		TempDir.wipe(_dir)
		_dir = ""


# --- Veri -------------------------------------------------------------------------------------------------------------

func test_geography_is_the_prototypes_map_with_both_homes_on_it() -> void:
	var geo := AtlasGeo.shared()
	assert_true(geo.ok, "data/atlas/geography.json okundu")
	assert_almost(geo.map_w, 50.4175, 0.001)
	assert_almost(geo.map_d, 29.7515, 0.001)
	assert_almost(geo.map_w * geo.map_d * geo.km_per_unit * geo.km_per_unit, 75000.0, 15.0, "Harita 75.000 km²")
	assert_eq(geo.text("atlas.crumb.world", "tr"), "Bozkır Dünyası")
	assert_eq(geo.text("atlas.crumb.world", "en"), "The Steppe World")
	# Ana menünün kampı: Hangay eteğinde, Orhun'un yukarı vadisinde göllü vadi (prototipin CAMP_LONLAT'ı; K20'nin 47,35°K'si).
	var camp := geo.home("camp")
	assert_eq(camp["lonlat"], [103.1, 47.35])
	var camp_at := geo.home_point("camp")
	assert_almost(camp_at.x, 3.9429, 0.001)
	assert_almost(camp_at.y, -5.8228, 0.001)
	assert_true(Geometry2D.is_point_in_polygon(camp_at, geo.borders["xiongnu"]), "Kamp MÖ 210'da Hun yurdunda")
	assert_true(geo.height_at(camp_at) > 0.0, "Kabartmanın yüksekliği okunur")
	# Menünün kampı Göl Obası'dır; hikâyenin Tanhu Kampı (Yola Çıkış, K41'in konağı) ayrı yerdedir (K106).
	assert_eq(geo.text("atlas.crumb.camp", "tr"), "Göl Obası")
	assert_eq(geo.text("atlas.you.place", "en"), "Lake Camp")
	var tanhu: Dictionary = geo.home("depart_yurt")
	assert_almost(float(tanhu["lonlat"][1]), 46.5, 0.0001, "Yola Çıkış'ın ışığıyla aynı enlem")
	var tanhu_at := geo.home_point("depart_yurt")
	assert_true(tanhu_at.distance_to(camp_at) > 1.0, "Tanhu Kampı Göl Obası'nın vadisinde değil")
	assert_true(tanhu_at.x > camp_at.x and tanhu_at.y > camp_at.y, "Güneydoğuda")
	assert_true(Geometry2D.is_point_in_polygon(tanhu_at, geo.borders["xiongnu"]), "MÖ 210'da Hun yurdunda")
	# Çocukluk'un Ordos'u: Sarı Irmak kıvrımının içinde, ırmak 680 m doğuda, 39°K.
	var ordos: Dictionary = geo.home("ordos")
	assert_almost(float(ordos["lonlat"][1]), 39.0, 0.0001)
	var ordos_at := geo.home_point("ordos")
	var river := _yellow_river_x_at(geo, ordos_at.y)
	assert_almost(river - ordos_at.x, 0.68, 0.01, "Sarı Irmak 0,68 birim (680 sahne metresi) doğuda")
	assert_true(Geometry2D.is_point_in_polygon(ordos_at, geo.borders["xiongnu_228"]), "MÖ 228'de Ordos Hun yurdu")
	assert_false(Geometry2D.is_point_in_polygon(ordos_at, geo.borders["xiongnu"]), "MÖ 210'da Ordos Ç'in'indir (MÖ 215)")
	assert_true(Geometry2D.is_point_in_polygon(ordos_at, geo.borders["qin"]))
	# Kıvrımlı yollar ve surlar.
	assert_eq(geo.borders.size(), 23)
	assert_eq(geo.rivers.size(), 23)
	assert_true(geo.wall.size() >= 10)


static func _yellow_river_x_at(geo: AtlasGeo, z: float) -> float:
	var best := -INF
	for r: Dictionary in geo.rivers:
		if str(r["id"]) != "yellow_river":
			continue
		var pts: PackedVector2Array = r["pts"]
		for i in pts.size() - 1:
			var a := pts[i]
			var b := pts[i + 1]
			if (a.y - z) * (b.y - z) > 0.0 or is_equal_approx(a.y, b.y):
				continue
			var x := a.x + (z - a.y) / (b.y - a.y) * (b.x - a.x)
			if x > geo.to_map(109.6, 0.0).x and x < geo.to_map(111.8, 0.0).x:
				best = maxf(best, x)
	return best


func test_reveal_rules_split_free_roam_and_childhood() -> void:
	assert_true(AtlasGeo.revealed("camp", {"id": "baikal"}), "Fiziki coğrafya hep açık")
	assert_true(AtlasGeo.revealed("camp", {"unlock": "start"}))
	assert_true(AtlasGeo.revealed("camp", {"unlock": "camp"}))
	assert_false(AtlasGeo.revealed("camp", {"unlock": "childhood"}))
	assert_false(AtlasGeo.revealed("camp", {"unlock": "act>=2"}), "Hikâyenin koşulu Serbest Gez'de kapalı")
	assert_true(AtlasGeo.revealed("childhood", {"unlock": "childhood"}))
	assert_false(AtlasGeo.revealed("childhood", {"unlock": "start"}))
	var geo := AtlasGeo.shared()
	var camp_open := func(p: Dictionary) -> bool: return AtlasGeo.revealed("camp", p)
	var child_open := func(p: Dictionary) -> bool: return AtlasGeo.revealed("childhood", p)
	var all_on := {}
	var ids := func(rows: Array) -> Array: return rows.map(func(p: Dictionary) -> String: return str(p["id"]))
	assert_eq(ids.call(AtlasPolitical.painted_rows(geo.rows("polities"), "210", all_on, camp_open)), ["yuezhi", "xiongnu"],
		"MÖ 210: devlet altta, çekirdek üstte; Ç'in Kervan Haberi'yle açılır")
	assert_eq(ids.call(AtlasPolitical.painted_rows(geo.rows("polities"), "228", all_on, child_open)), ["yuezhi_228", "xiongnu_228"])
	assert_eq(str(AtlasPolitical.core_of(geo.rows("polities"), "210", camp_open).get("id", "")), "xiongnu")
	assert_eq(ids.call(AtlasPolitical.painted_rows(geo.rows("polities"), "210", {"states": false}, camp_open)), [], "Devletler katmanı kapalı")
	var wusun: Dictionary = {}
	for p: Dictionary in geo.rows("polities"):
		if str(p["id"]) == "wusun":
			wusun = p
	assert_false(AtlasPolitical.drawn_in(wusun, "210"), "Söylenti döneminde leke yok")
	assert_true(AtlasPolitical.drawn_in(wusun, "174"))


func test_political_layer_paints_once_per_change() -> void:
	var pol := AtlasPolitical.new()
	add_child(pol)
	var open := func(p: Dictionary) -> bool: return AtlasGeo.revealed("camp", p)
	pol.paint("210", {}, open)
	assert_eq(pol.key, "210,yuezhi,xiongnu")
	assert_not_null(pol.fill_texture)
	assert_eq(pol.line_texture.get_size(), Vector2(float(AtlasPolitical.LINE_W), roundf(AtlasPolitical.LINE_W * AtlasGeo.shared().map_d / AtlasGeo.shared().map_w)))
	pol.paint("210", {}, open)
	assert_eq(pol.key, "210,yuezhi,xiongnu", "Değişmeyen boyama yinelenmez")
	pol.queue_free()


# --- Kamera ---------------------------------------------------------------------------------------------------------

func test_camera_projects_and_picks_the_ground() -> void:
	var c := Vector2(3.9, -5.8)
	var cam := HudMapPage.camera_for(c, 26.0, 0.0, VIEW, 0.1)
	var center := HudMapPage.project(cam, c, VIEW, 150.0)
	assert_almost(center.x, VIEW.x * 0.5 - 150.0, 0.01, "Görüşün merkezi sola kayık (kilimin dışı)")
	assert_almost(center.y, VIEW.y * 0.5, 0.01)
	var north := HudMapPage.project(cam, c + Vector2(0.0, -3.0), VIEW, 150.0)
	assert_true(north.y < center.y and absf(north.x - center.x) < 0.01, "Kuzey yukarıda")
	var east := HudMapPage.project(cam, c + Vector2(4.0, 0.0), VIEW, 150.0)
	assert_true(east.x > center.x, "Doğu sağda")
	for p: Vector2 in [Vector2(100.0, 100.0), Vector2(1700.0, 200.0), Vector2(960.0, 900.0)]:
		var g := HudMapPage.ground_at(cam, p, VIEW, 150.0)
		assert_true(g != Vector2.INF, "Işın yere iner")
		var back := HudMapPage.project(cam, g, VIEW, 150.0)
		assert_almost(back.x, p.x, 0.05, "Yer ve yansıması aynı nokta")
		assert_almost(back.y, p.y, 0.05)
	var top := HudMapPage.project(cam, c + Vector2(0.0, -8.0), VIEW, 0.0)
	var bottom := HudMapPage.project(cam, c + Vector2(0.0, 8.0), VIEW, 0.0)
	assert_true((center.y - top.y) < (bottom.y - center.y), "Eğik bakış: uzak taraf kısalır")
	assert_almost(rad_to_deg(HudMapPage.pitch_for(2.0)), 46.0, 0.01, "Yakında 46°")
	assert_almost(rad_to_deg(HudMapPage.pitch_for(67.0)), 60.0, 0.01, "Uzaktan 60°")
	var turned := HudMapPage.camera_for(c, 26.0, PI * 0.5, VIEW, 0.1)
	var e2 := HudMapPage.project(turned, c + Vector2(4.0, 0.0), VIEW, 0.0)
	var c2 := HudMapPage.project(turned, c, VIEW, 0.0)
	assert_true(absf(e2.x - c2.x) < 1.0, "Döndürülünce doğu artık yan yönde değil")
	# Ölçek çubuğu: atlasta bir birim 7,07 km (prototipte 26 birimde «10 km»), gerçek düzeyde 1 km.
	assert_eq(HudMapPage.scale_bar(26.0, 7.0711, 1920.0)[0], 10.0)
	assert_true(float(HudMapPage.scale_bar(26.0, 7.0711, 1920.0)[1]) < HudMapPage.SCALE_MAX_PX)
	assert_eq(HudMapPage.scale_bar(0.2, 1.0, 1920.0)[0], 0.01, "Gerçek düzeyde sahne metresi")
	assert_eq(HudMapPage.fmt_number(75000.0, "tr"), "75.000")
	assert_eq(HudMapPage.fmt_number(18.5, "tr"), "18,5")
	assert_eq(HudMapPage.fmt_number(18.5, "en"), "18.5")


# --- Sayfa: düzeyler, yakınlaşma, araçlar ------------------------------------------------------------------------------

func _page(map: WorldMap, player := Vector2(2.0, 3.0)) -> HudMapPage:
	var page := HudMapPage.from_data({"map": map, "player_xz": player, "facing": 0.0, "target_xz": Vector2(10.0, -20.0),
		"quest_text": "Ateşin başına var", "quest_title": "Kampı Dolaş"})
	page.size = VIEW
	add_child(page)
	page.size = VIEW
	return page


func _settle(page: HudMapPage, frames := 240) -> void:
	for i in frames:
		page.step_view(1.0 / 60.0)


func test_page_opens_on_the_player_and_zooms_down_to_the_camp() -> void:
	var page := _page(WorldMap.bake_fallback(WorldMap.camp_spec(null, null)))
	await wait_frames(2)
	var geo := AtlasGeo.shared()
	assert_eq(page.home_key, "camp")
	assert_true(page.home.is_equal_approx(geo.home_point("camp")), "Ev kampın atlas noktası")
	assert_almost(page.span_t, HudMapPage.OPEN_SPAN, 0.001, "Açılış 26 birim (site Harita)")
	assert_almost(page.cx_t, page.home.x + 0.002, 0.0001, "Oyuncunun üstünde (2 m doğuda)")
	assert_false(page.real)
	assert_eq(page.era, "210")
	assert_eq(page.open_eras, PackedStringArray(["210"]), "Serbest Gez yalnız MÖ 210'u açar")
	assert_eq(page.crumbs(), PackedStringArray(["Bozkır Dünyası"]))
	# Tekerlek imlecin altına yakınlaşır: o yer imlecin altında kalır.
	page.cx = page.cx_t
	page.cz = page.cz_t
	page.span = page.span_t
	var at := Vector2(700.0, 400.0)
	var before := HudMapPage.ground_at(page.camera(), at, page.size, page.view_shift())
	page._gui_input(_wheel(at, MOUSE_BUTTON_WHEEL_UP))
	assert_almost(page.span_t, HudMapPage.OPEN_SPAN / HudMapPage.WHEEL_ZOOM, 0.001, "Tekerlek ×1,18 yakınlaşır")
	page.cx = page.cx_t
	page.cz = page.cz_t
	page.span = page.span_t
	var after := HudMapPage.ground_at(page.camera(), at, page.size, page.view_shift())
	assert_true(before.distance_to(after) < 0.3, "İmlecin altındaki yer yerinde kalır (%.3f birim)" % before.distance_to(after))
	# Evden uzakta yakınlaşma 6 birimde durur (yol kapalı yazar).
	page.fly_to(Vector2(-15.0, 5.0), 10.0)
	page.zoom_by(0.1)
	assert_almost(page.span_t, HudMapPage.AWAY_MIN, 0.001, "Evden uzakta 6 birimde durak")
	assert_true(page._road_note > 0.0, "«Serbest Gez'de yol kapalı.»")
	# Evin üstünde: bölge, kısa kararmayla vadi (gerçek düzey), sonra yer.
	page.fly_to(page.home, 12.0)
	_settle(page)
	assert_eq(page.crumbs(), PackedStringArray(["Bozkır Dünyası", "Hangay ve Orhun"]), "18 birimin altında bölge")
	page.fly_to(page.home, 2.2)
	_settle(page)
	assert_true(page.real, "2,9 birimin altında gerçek düzey")
	assert_almost(page.veil, 0.0, 0.001, "Kararma açıldı")
	assert_eq(page.crumbs(), PackedStringArray(["Bozkır Dünyası", "Hangay ve Orhun", "Göl Vadisi"]))
	page.fly_to_crumb("site")
	_settle(page)
	assert_eq(page.crumbs()[page.crumbs().size() - 1], "Göl Obası", "En derinde yürünür alanın adı")
	assert_true(page.span_t >= page.min_span() - 0.0001)
	page.zoom_by(0.001)
	assert_almost(page.span_t, page.min_span(), 0.0001, "En yakın: pişmiş görüntünün sınırı")
	# Kırıntı: Bozkır Dünyası'na uçar; gerçek düzeyden kararmayla çıkar.
	page.fly_to_crumb("world")
	_settle(page)
	assert_false(page.real)
	assert_almost(page.span_t, page.max_span(), 0.001)
	# Konumum, pusula, katman, dönem, kapat.
	page.fly_home()
	assert_almost(page.span_t, HudMapPage.HOME_SPAN, 0.001)
	assert_almost(page.cz_t, page.home.y + 0.003, 0.0001)
	page.yaw_t = 1.2
	page.north_up()
	assert_almost(page.yaw_t, 0.0, 0.0001, "Pusula kuzeyi yukarı alır")
	page._activate({"id": "layer:clouds"})
	assert_false(page.layers["clouds"], "Katman kapanır")
	page.set_era("174")
	assert_eq(page.era, "210", "Açılmamış dönem seçilmez")
	var closing := watch_signal(page.close_requested)
	page._activate({"id": "close"})
	assert_eq(closing.count, 1, "Haritayı kapat")
	page.queue_free()


func test_labels_open_cards_and_the_life_list_flies_to_the_event() -> void:
	var page := _page(WorldMap.bake_fallback(WorldMap.camp_spec(null, null)))
	await wait_frames(2)
	var hun: Dictionary = {}
	for it: Dictionary in page.items:
		if str((it["row"] as Dictionary).get("id", "")) == "xiongnu" and str(it["type"]) == "state":
			hun = it
	assert_false(hun.is_empty())
	assert_eq(hun["name"], "Hun Tanhuluğu")
	assert_true(page.item_on(hun), "26 birimde Hun Tanhuluğu'nun adı görünür")
	page._activate({"id": "label:%d" % int(hun["index"])})
	assert_eq(page.card.get("name", ""), "Hun Tanhuluğu", "Ada tıklayınca kartı açılır")
	page._activate({"id": "card_close"})
	assert_true(page.card.is_empty())
	# Mete'nin hayatı: Serbest Gez'de yalnız rehinelik (başta açık) açıktır; tıklayınca olaya uçar.
	var events := AtlasGeo.shared().rows("events")
	var hostage := -1
	for i in events.size():
		if str(events[i]["id"]) == "hostage":
			hostage = i
	assert_true(page.event_open(hostage))
	page._activate({"id": "life:%d" % hostage})
	assert_almost(page.span_t, HudMapPage.EVENT_FLY_SPAN, 0.001)
	assert_eq(str(page.card.get("name", "")), "Yüeçi'de rehine")
	assert_eq(page.step_event(hostage, 1), -1, "Kaçış eve dönüşle açılır")
	page.queue_free()


func test_childhood_page_shows_the_ordos_in_its_own_era() -> void:
	var page := _page(WorldMap.bake_fallback(WorldMap.ordos_spec(null)), Vector2(-4.0, 6.0))
	await wait_frames(2)
	var geo := AtlasGeo.shared()
	assert_eq(page.home_key, "ordos")
	assert_true(page.home.is_equal_approx(geo.home_point("ordos")))
	assert_eq(page.era, "228", "Çocukluk kendi döneminde açılır")
	assert_eq(page.open_eras, PackedStringArray(["228"]))
	assert_eq(page.era_line(), "MÖ 228 · Ordos'ta çocukluk")
	var names := page.items.filter(func(it: Dictionary) -> bool: return page.item_on(it, true)).map(func(it: Dictionary) -> String: return str(it["name"]))
	assert_true(names.has("Hun Tanhuluğu") and names.has("Yüeçi"), "Hunlar ve Yüeçi")
	assert_false(names.has("Ç'in İmparatorluğu"), "Çin MÖ 228'de çizilmez")
	assert_true(names.has("Doğum") and names.has("Koyun Sırtında"), "Mete'nin hayatı doğumla başlar")
	page.fly_to(page.home, 2.0)
	_settle(page)
	assert_true(page.real)
	assert_eq(page.crumbs(), PackedStringArray(["Bozkır Dünyası", "Yin Dağları ve Ordos", "Sarı Irmak Kıvrımı"]))
	page.queue_free()


# --- Girdi: tekerlek, kıstırma, iki parmakla kaydırma ----------------------------------------------------------------------

static func _wheel(at: Vector2, button: MouseButton, factor := 1.0) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = button
	e.pressed = true
	e.factor = factor
	e.position = at
	e.global_position = at
	return e


static func _magnify(at: Vector2, factor: float) -> InputEventMagnifyGesture:
	var e := InputEventMagnifyGesture.new()
	e.position = at
	e.factor = factor
	return e


static func _pan(at: Vector2, delta: Vector2) -> InputEventPanGesture:
	var e := InputEventPanGesture.new()
	e.position = at
	e.delta = delta
	return e


func test_trackpad_pinch_and_two_finger_scroll_zoom_under_the_cursor() -> void:
	var page := _page(WorldMap.bake_fallback(WorldMap.camp_spec(null, null)))
	await wait_frames(2)
	var at := Vector2(800.0, 450.0)
	page._gui_input(_magnify(at, 1.5))
	assert_almost(page.span_t, HudMapPage.OPEN_SPAN / 1.5, 0.001, "Parmaklar açılınca yakınlaşır")
	page._gui_input(_magnify(at, 0.5))
	assert_almost(page.span_t, HudMapPage.OPEN_SPAN / 1.5 * 2.0, 0.001, "Kıstırınca uzaklaşır")
	var s := page.span_t
	page._gui_input(_pan(at, Vector2(0.0, -2.0)))
	assert_almost(page.span_t, s * exp(-2.0 * HudMapPage.PAN_ZOOM), 0.001, "İki parmak aşağı: yakınlaşır (tekerlek yukarı gibi)")
	page._gui_input(_pan(at, Vector2(0.0, 2.0)))
	assert_almost(page.span_t, s, 0.001, "İki parmak yukarı: uzaklaşır")
	page._gui_input(_wheel(at, MOUSE_BUTTON_WHEEL_DOWN, 2.0))
	assert_almost(page.span_t, s * pow(HudMapPage.WHEEL_ZOOM, 2.0), 0.001, "Yumuşak tekerleğin payı (factor) sayılır")
	# Godot 4.7.2 Input'tan geçen jesti iki kopya olarak verir (aynı değer, aynı kare): ikincisi sayılmaz, sonraki karedeki sayılır.
	var s2 := page.span_t
	page._gui_input(_pan(at, Vector2(0.0, -1.0)))
	page._gui_input(_pan(at, Vector2(0.0, -1.0)))
	assert_almost(page.span_t, s2 * exp(-HudMapPage.PAN_ZOOM), 0.001, "Aynı karedeki kopya yok sayılır")
	await wait_frames(1)
	page._gui_input(_pan(at, Vector2(0.0, -1.0)))
	assert_almost(page.span_t, s2 * exp(-2.0 * HudMapPage.PAN_ZOOM), 0.001, "Sonraki karedeki aynı jest sayılır")
	page.queue_free()


## Kitabın HARİTA sayfası görünümden geçen olaylarla yakınlaşır: tekerleği, kıstırmayı ve iki parmakla kaydırmayı başka düğüm yutmaz.
func test_book_map_page_gets_wheel_and_gestures_through_the_viewport() -> void:
	var hud := GameplayHud.new()
	hud.live_check = func() -> bool: return true
	add_child(hud)
	hud.set_world_map(WorldMap.bake_fallback(WorldMap.camp_spec(null, null)))
	var book := GameMenu.new()
	book.mode = "game"
	book.hud = hud
	add_child(book)
	book.show_page("harita")
	await wait_frames(2)
	var page := book.get_page() as HudMapPage
	assert_not_null(page)
	if page:
		_check_viewport_zoom(page)
	book.queue_free()
	hud.queue_free()


func _check_viewport_zoom(page: HudMapPage) -> void:
	var at := page.get_global_rect().get_center()
	var s0 := page.span_t
	get_viewport().push_input(_wheel(at, MOUSE_BUTTON_WHEEL_UP), true)
	assert_true(page.span_t < s0 * 0.9, "Tekerlek haritayı yakınlaştırır (%.2f → %.2f)" % [s0, page.span_t])
	var s1 := page.span_t
	get_viewport().push_input(_magnify(at, 1.6), true)
	assert_true(page.span_t < s1 * 0.7, "Kıstırma yakınlaştırır")
	var s2 := page.span_t
	get_viewport().push_input(_pan(at, Vector2(0.0, 4.0)), true)
	assert_true(page.span_t > s2 * 1.5, "İki parmakla kaydırma uzaklaştırır")


func test_free_roam_map_zooms_with_real_input() -> void:
	_dir = TempDir.fresh("atlas")
	var main = load(MAIN_SCENE).instantiate()
	main.quit_handler = func() -> void: pass
	main.saves = SaveSystem.new(_dir)
	main.prologue_path = ""
	add_child(main)
	await wait_frames(3)
	main.menu.finish_intro()
	main.menu.free_roam_requested.emit()
	var deadline := Time.get_ticks_msec() + 8000
	while main.state != main.State.PLAYING and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	await wait_frames(2)
	var g: GameplayHud = main.gameplay_hud
	var m := InputEventKey.new()
	m.physical_keycode = KEY_M
	m.pressed = true
	g._unhandled_input(m)
	await wait_frames(2)
	assert_true(main.pause_menu.is_open() and get_tree().paused, "M duraklatma kitabını açar")
	var book: GameMenu = main.pause_menu.get_menu()
	var page := book.get_page() as HudMapPage if book else null
	assert_not_null(page, "Kitap HARİTA sayfasında")
	if page:
		assert_eq(page.home_key, "camp", "Ana kampın haritası atlasın kampındadır")
		assert_true(get_viewport().disable_3d, "Harita açıkken arkadaki dünyanın 3B çizimi kapalı (K63)")
		_check_viewport_zoom(page)
	main.pause_menu.close()
	main._on_pause_resumed()
	await wait_frames(1)
	assert_false(get_viewport().disable_3d, "Harita kapanınca dünya yeniden çizilir")
	main.queue_free()
	# Ana sahnenin müziği ve ortam sesi ses sunucusundan çekilsin (dosya bitince çıkışta sızıntı sayılmasın).
	await get_tree().create_timer(0.5).timeout
	await wait_frames(2)
