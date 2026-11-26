extends TestCase
## Destan Kitabı testleri (godot.md §3.8; K35, K85, K86): dört bölüm (Destan, Gök ve Yer, Kişiler, Taşlar) ve
## verileri, kayıtların yolculuk işaretleriyle açılması (ilk dize ve ocak halkı baştan açık, mit girdileri Önsöz'le,
## iyeler ozanı 5 sn dinleyince), çağ rozetleri, kimlik göçü ve «Kopuz», koşul dili (JourneyFlags.holds) ve
## kamptaki yer işaretleri. Ansiklopedi sayfası (EncyclopediaPage): altı bölüm sekmesi, portreli dizin ve
## Türkçe katlamalı arama, Q / E'nin bölüm sınırında kitabın komşu sayfasına geçmesi, arama odaktayken Q / E'nin
## harf yazması, ← / → görsel yuvaları, Enter ile büyütme, Esc sırası (büyütme → arama → kitap), eksik görselin
## yazısı, soy kartları ve tanıtım sesi (hoparlör Voice yolunda çalar, kısma, ikinci basış ve kişi değişimi susturur,
## altyazı Türkçe). Ses başsız sürücüde sahtedir: kısma Amplify'ın değeri olarak sınanır; zaman Engine.time_scale
## ile hızlanır ve her testten sonra 1'e döner.

const MainScript := preload("res://scripts/main.gd")
const AudioManagerScript := preload("res://scripts/audio/audio_manager.gd")

var _nodes: Array[Node] = []
var _audio: Node


func before_each() -> void:
	MenuStyle.muted = true
	InputSetup.ensure_actions()
	DestanKitabi.clear_cache()


# Koşucu after_each'i beklemez: her şey hemen yapılır. Basılı kalan eylem (Esc, ui_cancel) sonraki dosyaların
# basılı tutma denetimini (CineHost'un atlaması) yanıltmasın diye bırakılır.
func after_each() -> void:
	Engine.time_scale = 1.0
	for action in [&"ui_cancel", &"pause", &"book_intro"]:
		if InputMap.has_action(action):
			Input.action_release(action)
	for n in _nodes:
		if is_instance_valid(n):
			n.queue_free()
	_nodes.clear()
	if is_instance_valid(_audio):
		_audio.stop_all()
		_audio.reset_buses()
		_audio.free()
	_audio = null


func _titles(chapter: String, flags: Dictionary) -> Array:
	return DestanKitabi.entries(chapter, flags).map(func(e: Dictionary) -> String: return str(e["title"]))


func _ids(chapter: String, flags: Dictionary) -> Array:
	return DestanKitabi.entries(chapter, flags).map(func(e: Dictionary) -> String: return str(e["id"]))


func _all_flags() -> Dictionary:
	var f := {}
	for key in JourneyFlags.ALL:
		f[key] = true
	return f


# --- Veri ve açılma -----------------------------------------------------------------------------

func test_four_chapters_with_their_data() -> void:
	assert_eq(DestanKitabi.CHAPTERS, ["destan", "gok_yer", "kisiler", "taslar"] as Array[String])
	assert_eq(DestanKitabi.chapter_title("destan"), "Destan")
	assert_eq(DestanKitabi.chapter_title("gok_yer"), "Gök ve Yer")
	assert_eq(DestanKitabi.chapter_title("kisiler"), "Kişiler")
	assert_eq(DestanKitabi.chapter_title("taslar"), "Taşlar")
	assert_eq(DestanKitabi.total("destan"), 7, "Gece kampı üstüne yedi dize")
	assert_eq(DestanKitabi.total("taslar"), 5, "Kampın taşları ve yerleri")
	assert_true(DestanKitabi.total("gok_yer") >= 25, "Gök ve Yer: sitenin tanrıları ve «Doğum» (%d)" % DestanKitabi.total("gok_yer"))
	assert_true(DestanKitabi.total("kisiler") >= 100, "Kişiler: sitenin öteki beş bölümü ve iki at (%d)" % DestanKitabi.total("kisiler"))
	assert_eq(DestanKitabi.SECTIONS, ["gods", "mete", "huns", "neighbors", "han", "companions"] as Array[String], "Altı bölüm sekmesi")
	assert_eq(DestanKitabi.sections_of("gok_yer"), ["gods"] as Array[String], "«Gök ve Yer» tanrıların bölümünü açar")
	assert_eq(DestanKitabi.sections_of("kisiler"), ["mete", "huns", "neighbors", "han", "companions"] as Array[String])
	var glyphs := DestanKitabi.SECTIONS.map(func(s: String) -> String: return str(DestanKitabi.section_info(s)["icon"]))
	assert_eq(glyphs, ["sun", "bow", "yurt", "horse", "tower", "people"], "Sekme simgeleri: güneş, yay, yurt, at, kule, kişiler")
	for chapter in DestanKitabi.CHAPTERS:
		for e in DestanKitabi.entries(chapter, _all_flags()):
			assert_ne(str(e["title"]), "", "%s: başlıksız kayıt" % chapter)
			assert_true(str(e["text"]).length() > 40, "%s/%s: metin kısa" % [chapter, e["id"]])


func test_first_verse_and_the_camp_folk_are_open_from_the_start() -> void:
	assert_eq(_titles("destan", {}), ["Ocak Başında"], "Baştan yalnızca ilk dize açık")
	assert_eq(DestanKitabi.entries("taslar", {}).size(), 0, "Hiçbir taş baştan açık değil")
	assert_eq(DestanKitabi.entries("gok_yer", {}).size(), 0, "Mit girdileri Önsöz'den önce kapalı")
	var people := _ids("kisiler", {})
	people.sort()
	assert_eq(people, ["bard", "child", "father", "mother", "older_brother"], "Ocak halkı baştan bilinir: Ozan, Ana, Baba, Ağabey, Çocuk")


func test_each_journey_flag_opens_its_entries() -> void:
	assert_true("İlk Adım" in _titles("destan", {JourneyFlags.FIRST_ROAM: true}))
	var fire := {JourneyFlags.FIRESIDE: true}
	assert_true("Ateşin Sözü" in _titles("destan", fire))
	assert_eq(_titles("taslar", fire), ["Ocak Taşları"])
	var stable := {JourneyFlags.STABLE: true}
	assert_true("Ahırda İki At" in _titles("destan", stable))
	assert_true("doru" in _ids("kisiler", stable) and "akbulut" in _ids("kisiler", stable), "Atlar ahırda tanınır")
	assert_eq(_titles("taslar", stable), ["Ahır"])
	for key in [JourneyFlags.BOULDER, JourneyFlags.FORMATION]:
		assert_true("Taşların Dili" in _titles("destan", {key: true}), "%s Taşların Dili'ni açmalı" % key)
	assert_eq(_titles("taslar", {JourneyFlags.BOULDER: true}), ["Yosunlu Kayalar"])
	assert_eq(_titles("taslar", {JourneyFlags.FORMATION: true}), ["Dikili Kayalar"])
	var lake := {JourneyFlags.LAKE_VIEW: true}
	assert_true("Göle Bakan Yamaç" in _titles("destan", lake))
	assert_eq(_titles("taslar", lake), ["Göl"])
	assert_false("Gece Biterken" in _titles("destan", {JourneyFlags.FIRESIDE: true, JourneyFlags.STABLE: true}))
	assert_true("Gece Biterken" in _titles("destan", {JourneyFlags.FIRESIDE: true, JourneyFlags.STABLE: true, JourneyFlags.LAKE_VIEW: true}),
		"Son dize ateş, ahır ve göl görülünce açılır")
	assert_eq(DestanKitabi.entries("destan", _all_flags()).size(), 7, "Bütün işaretlerle bütün dizeler açık")


func test_people_and_stones_keep_their_groups() -> void:
	var people := DestanKitabi.entries("kisiler", {JourneyFlags.STABLE: true})
	for e in people:
		assert_eq(str(e["section"]), "huns", "%s: ocak halkı ve atlar Hun Ordası bölümünde" % e["id"])
		assert_eq(str(e["group"]), "Ocak ve anlatı")
	var games := {}
	for e in people:
		games[str(e["id"])] = str(e["game_group"])
	assert_eq(games["mother"], "Ocak Halkı", "Oyunun grubu (game_group) korunur")
	assert_eq(games["akbulut"], "Atlar")
	var stones := DestanKitabi.entries("taslar", _all_flags())
	assert_eq(str(stones[0]["group"]), "Kamp")
	assert_eq(str(DestanKitabi.entries("destan", {})[0]["sub"]), DestanKitabi.SAGA_SUB)


func test_unlock_rules() -> void:
	assert_true(DestanKitabi.is_unlocked("*", {}))
	assert_false(DestanKitabi.is_unlocked("", {"x": true}), "Boş koşullu kişi kendiliğinden açılmaz (Tanhu 2)")
	assert_true(DestanKitabi.is_unlocked("x", {"x": true}))


func test_ids_migrate_and_the_bard_plays_a_kopuz() -> void:
	var ids := DestanKitabi.all_entries("kisiler").map(func(p: Dictionary) -> String: return str(p["id"]))
	for id in ["mother", "father", "child", "bard", "older_brother", "akbulut", "doru"]:
		assert_true(id in ids, "%s kimliği kişilerde olmalı" % id)
	for old in ["ana", "baba", "cocuk", "ozan", "ak_at"]:
		assert_false(old in ids, "Eski kimlik göçmeli: %s" % old)
	var mete: Dictionary = DestanKitabi.find_record("mete").get("record", {})
	assert_eq(str(mete.get("section", "")), "mete", "«mete» Mete'nin kendisidir; ateş başındaki atlı Ağabey'dir (K37)")
	assert_eq(str((DestanKitabi.find_record("older_brother")["record"] as Dictionary)["unlock"]), "*", "Ağabey ocak halkıdır")
	var akbulut: Dictionary = DestanKitabi.find_record("akbulut")["record"]
	var akbulut_text := JSON.stringify(akbulut.get("sections", []))
	assert_false(akbulut_text.contains("Mete"), "Akbulut'un Mete cümlesi kalktı")
	assert_false(akbulut_text.contains("ay ışığ") or akbulut_text.contains("gümüş"), "Ay atı dili kalktı")
	assert_true(JSON.stringify(DestanKitabi.find_record("bard")["record"]).contains("opuz"), "Ozanın kaydı kopuzu anar")
	assert_true(DestanKitabi.entries("destan", {})[0]["text"].contains("kopuzu"), "Ozan kopuzu aldı (camp-cast)")
	for path in ["res://data/destan.json", "res://data/kisiler.json", "res://data/mitler.json"]:
		var text := FileAccess.get_file_as_string(path)
		assert_false(text.contains("ombıra") or text.contains("ombira") or text.contains("iki tel"), "%s «Dombıra / iki tel» değil kopuz" % path)


# --- Gök ve Yer: mitler, rozetler, açılma ----------------------------------------------------------

func test_every_myth_carries_era_badges() -> void:
	var myths := DestanKitabi.all_entries("gok_yer")
	assert_false(myths.is_empty())
	for p: Dictionary in myths:
		var badges: Array = p.get("badges", [])
		assert_false(badges.is_empty(), "%s: en az bir çağ rozeti" % p["id"])
		for b: Variant in badges:
			assert_true(str(b) in DestanKitabi.BADGES, "%s: bilinmeyen rozet %s" % [p["id"], b])
		assert_true(str(p.get("group", "")) in ["Gök", "Yer", "Alt", "Hayvan", "Töre ve sunu", "Destan"], "%s: grup %s" % [p["id"], p.get("group")])
	var tengri: Dictionary = DestanKitabi.find_record("tengri")["record"]
	assert_eq(tengri["badges"], ["Yıllıktan", "Taştan"], "Tengri: adı Hun yıllıklarında, kut Orhun'da")
	var birth: Dictionary = DestanKitabi.find_record("birth")["record"]
	assert_eq(str(birth["name"]), "Doğum")
	assert_eq(str(birth["group"]), "Destan")
	assert_eq(birth["badges"], ["Yıllıktan", "Bizim"], "«Doğum»: Shiji 110 ve oyunun seçimi")


func test_prologue_opens_its_myths_and_the_birth() -> void:
	assert_eq(JourneyFlags.PROLOGUE, CineHost.PROLOGUE_FLAG, "Önsöz'ün işareti CineHost'unkiyle aynı")
	assert_eq(_ids("gok_yer", {}), [], "İşaretsiz kapalı")
	var open := _ids("gok_yer", {JourneyFlags.PROLOGUE: true})
	for id in ["tengri", "kayra_han", "ulgen", "umay", "erlik", "yer_sub", "od_ana", "toybodim", "al_karisi", "demirkazik", "birth"]:
		assert_true(id in open, "Önsöz'le açılmalı: %s" % id)
	for p: Dictionary in DestanKitabi.all_entries("gok_yer"):
		var in_prologue := "Önsöz" in (p.get("acts", []) as Array)
		assert_eq(str(p["id"]) in open, in_prologue, "%s: Önsöz'de geçen girdi açılır, geçmeyen kapalı kalır" % p["id"])
	assert_false("iyeler" in open, "İyeler ozanı dinleyince açılır")
	assert_true("iyeler" in _ids("gok_yer", {JourneyFlags.BARD_LISTEN: true}))
	assert_true("mete" in _ids("kisiler", {JourneyFlags.PROLOGUE: true}), "Önsöz'ün kişileri de açılır")


func test_listening_to_the_bard_for_five_seconds() -> void:
	var journey := Journey.new()
	var bard := JourneyFlags.DEFAULT_BARD
	var near := Vector3(bard.x + 1.0, 0.0, bard.y + 1.0)
	var far := Vector3(bard.x + 6.0, 0.0, bard.y + 6.0)
	journey.play_time = 10.0
	assert_false(JourneyFlags.BARD_LISTEN in journey.visit(near, 0.0))
	journey.play_time = 14.9
	assert_false(JourneyFlags.BARD_LISTEN in journey.visit(near, 0.0), "5 sn dolmadan konmaz")
	assert_almost(journey.bard_listen_time(), 4.9, 0.001)
	journey.play_time = 15.0
	assert_true(JourneyFlags.BARD_LISTEN in journey.visit(near, 0.0), "5 sn kesintisiz dinleyince konur")
	assert_true(journey.has_flag(JourneyFlags.BARD_LISTEN))
	# Ayrılan sayacı sıfırlar.
	var again := Journey.new()
	again.play_time = 0.0
	again.visit(near, 0.0)
	again.play_time = 3.0
	again.visit(near, 0.0)
	again.play_time = 3.25
	again.visit(far, 0.0)
	assert_almost(again.bard_listen_time(), 0.0, 0.001, "Ozandan ayrılınca sayaç sıfırlanır")
	again.play_time = 3.5
	again.visit(near, 0.0)
	again.play_time = 8.0
	assert_false(JourneyFlags.BARD_LISTEN in again.visit(near, 0.0), "Ayrılıp dönünce süre baştan sayılır")
	again.play_time = 8.5
	assert_true(JourneyFlags.BARD_LISTEN in again.visit(near, 0.0))
	var spawn := MainScript.SPAWN_OFFSET
	assert_false(JourneyFlags.near_bard(Vector2(spawn.x, spawn.z), again.landmarks), "Oyuncunun belirdiği yer ozanın yanı sayılmaz")


func test_bard_spot_comes_from_the_world() -> void:
	var world := Node3D.new()
	var camp := Node3D.new()
	camp.name = "Camp"
	world.add_child(camp)
	var npcs := Node3D.new()
	npcs.name = "CampNpcs"
	npcs.position = Vector3(1.0, 0.0, 1.0)
	camp.add_child(npcs)
	var elder := Node3D.new()
	elder.name = "Elder"
	elder.position = Vector3(2.0, 0.0, -1.0)
	npcs.add_child(elder)
	var marks := JourneyFlags.landmarks_from_world(world)
	world.free()
	var spot: Vector3 = marks[JourneyFlags.BARD_LISTEN][0]
	assert_almost(spot.x, 3.0, 0.001, "Ozanın yeri CampNpcs/Elder'dan, ebeveynin konumu eklenerek")
	assert_almost(spot.y, 0.0, 0.001)
	assert_almost(spot.z, JourneyFlags.BARD_RADIUS, 0.001)
	assert_false(JourneyFlags.BARD_LISTEN in JourneyFlags.flags_at(Vector2(3.0, 0.0), marks), "Süreli yer flags_at'le konmaz")


# --- Arama ----------------------------------------------------------------------------------------

func test_search_folds_turkish_letters_and_reads_alt_names() -> void:
	var list: Array = [
		{"id": "a", "title": "Erlik Han", "sub": "Alt dünyanın beyi", "alt_names": ["Kara Nama"]},
		{"id": "b", "title": "İyeler", "sub": "Yerin sahipleri", "alt_names": []},
		{"id": "c", "title": "Al Karısı", "sub": "Loğusa ruhu", "alt_names": ["Albastı"]},
		{"id": "d", "title": "Ülgen", "sub": "Göğün iyi beyi", "alt_names": ["Bay Ülgen"]},
	]
	var ids := func(q: String) -> Array: return DestanKitabi.search(q, list).map(func(e: Dictionary) -> String: return str(e["id"]))
	assert_eq(ids.call("erlik"), ["a"], "«Erlik» = «erlik»")
	assert_eq(ids.call("ERLİK"), ["a"], "İ küçük i'dir")
	assert_eq(ids.call("iyeler"), ["b"], "i büyük İ'yi bulur")
	assert_eq(ids.call("AL KARISI"), ["c"], "I küçük ı'yı bulur (Godot'nun to_lower'ı yerel değildir)")
	assert_eq(ids.call("karısı"), ["c"])
	assert_eq(ids.call("kara nama"), ["a"], "Öteki adlara bakar")
	assert_eq(ids.call("loğusa"), ["c"], "Sana bakar")
	assert_eq(ids.call("ulgen"), ["d"], "Ü ve u aynı")
	assert_eq(ids.call(""), ["a", "b", "c", "d"], "Boş sorgu bütün listedir")
	assert_eq(DestanKitabi.fold("Işık İz Ölçü"), "isik iz olcu")
	assert_eq(DestanKitabi.upper_tr("Gelenekteki görünüşü"), "GELENEKTEKİ GÖRÜNÜŞÜ")


# --- Ansiklopedi sayfası -----------------------------------------------------------------------------

func _page(chapter: String, flags: Dictionary) -> EncyclopediaPage:
	var holder := Control.new()
	holder.size = Vector2(1920, 892)
	add_child(holder)
	_nodes.append(holder)
	var page := EncyclopediaPage.new(chapter, flags)
	UIKit.full_rect(page)
	holder.add_child(page)
	return page


func _key(code: Key, unicode: int = 0) -> void:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.keycode = code
	e.unicode = unicode
	e.pressed = true
	Input.parse_input_event(e)
	var up := e.duplicate() as InputEventKey
	up.pressed = false
	Input.parse_input_event(up)
	await wait_frames(2)


func _esc() -> void:
	var esc := InputEventAction.new()
	esc.action = &"ui_cancel"
	esc.pressed = true
	Input.parse_input_event(esc)
	var up := InputEventAction.new()
	up.action = &"ui_cancel"
	up.pressed = false
	Input.parse_input_event(up)
	await wait_frames(2)


## Kayıtlarda görseli olan ilk açık kişi (yoksa "").
func _first_with_art(flags: Dictionary) -> String:
	for e in DestanKitabi.entries("kisiler", flags) + DestanKitabi.entries("gok_yer", flags):
		var art := str(e["images"]["art"])
		if not art.is_empty() and ResourceLoader.exists(art):
			return str(e["id"])
	return ""


func test_book_has_four_pages_and_six_section_tabs() -> void:
	var book := DestanKitabi.open(self, {})
	_nodes.append(book)
	await wait_frames(2)
	assert_eq(book.pages.map(func(p: Dictionary) -> String: return str(p["id"])), ["destan", "gok_yer", "kisiler", "taslar"],
		"Kitabın sırası: Destan, Gök ve Yer, Kişiler, Taşlar")
	book.show_page("kisiler")
	var page := book.get_page() as EncyclopediaPage
	assert_not_null(page, "Kişiler ansiklopedi düzeninde")
	if page == null:
		return
	assert_eq(page.get_tabs().size(), 6, "Simgeli altı bölüm sekmesi")
	assert_eq(page.get_tabs().map(func(t: EncyclopediaPage.SectionTab) -> String: return t.section), DestanKitabi.SECTIONS)
	assert_eq(page.get_section(), "huns", "Açık kaydı olan ilk bölüm açılır (ocak halkı)")
	assert_true(page.get_count_text().contains("5 / "), "«n / N açıldı»: %s" % page.get_count_text())
	book.show_page("gok_yer")
	assert_true(book.get_page() is EncyclopediaPage, "«Gök ve Yer» de ansiklopedi düzeninde")
	assert_eq((book.get_page() as EncyclopediaPage).get_sections(), ["gods"] as Array[String])
	book.show_page("destan")
	assert_true(book.get_page() is DestanKitabiPage, "Destan bugünkü düzende kalır")
	book.show_page("taslar")
	assert_true(book.get_page() is DestanKitabiPage)
	assert_eq(str(GameMenu.PAGE_HINTS["kisiler"]), EncyclopediaPage.KEY_HINT, "Tuş satırı: Q E bölüm · ↑ ↓ kişi · ← → görsel · Enter büyüt · Esc geri")


func test_index_lists_portrait_rows_and_arrows_pick_people() -> void:
	var page := _page("kisiler", {JourneyFlags.STABLE: true})
	await wait_frames(2)
	var ids := page.get_listed_ids()
	assert_eq(ids.size(), 7, "Ocak halkı ve iki at: %s" % [ids])
	assert_eq(page.get_selected_id(), ids[0], "İlk kişi açık başlar")
	assert_eq(page.get_rows().size(), 7)
	await _key(KEY_DOWN)
	assert_eq(page.get_selected_id(), ids[1], "↓ sonraki kişi")
	await _key(KEY_UP)
	await _key(KEY_UP)
	assert_eq(page.get_selected_id(), ids[0], "↑ başta durur")
	page.get_rows()[6].pressed.emit()
	assert_eq(page.get_selected_id(), ids[6], "Satıra basmak o kişiyi açar")


func test_search_finds_across_both_pages_and_esc_leaves_it() -> void:
	var book := DestanKitabi.open(self, _all_flags())
	_nodes.append(book)
	await wait_frames(2)
	book.show_page("kisiler")
	var page := book.get_page() as EncyclopediaPage
	page.set_query("ERLİK")
	assert_eq(page.get_selected_id(), "erlik", "Arama iki ansiklopedi sayfasına da bakar")
	assert_true(page.get_count_text().begins_with("Arama"))
	for t in page.get_tabs():
		assert_false(t.active, "Aramada hiçbir sekme açık değil")
	page.set_query("kara nama")
	assert_true("erlik" in page.get_listed_ids(), "Öteki adlara bakar")
	page.set_query("AL KARISI")
	assert_true("al_karisi" in page.get_listed_ids(), "I ile ı eşlenir")
	page.get_search_box().grab_focus()
	await wait_frames(1)
	await _esc()
	assert_eq(page.get_query(), "", "Esc aramadan çıkar")
	assert_false(page.get_search_box().has_focus())
	assert_true(is_instance_valid(book) and book.is_inside_tree() and book.current_page() == "kisiler", "Kitap açık kalır")


func test_q_and_e_turn_sections_then_the_book() -> void:
	var book := DestanKitabi.open(self, {})
	_nodes.append(book)
	await wait_frames(2)
	await _key(KEY_E)
	assert_eq(book.current_page(), "gok_yer", "Destan'dan sonra Gök ve Yer")
	await _key(KEY_E)
	assert_eq(book.current_page(), "kisiler", "Gök ve Yer'in tek bölümü var: E komşu sayfaya geçer")
	var page := book.get_page() as EncyclopediaPage
	var sections := page.get_sections()
	page.open_section(sections[0])
	for i in range(1, sections.size()):
		await _key(KEY_E)
		assert_eq(page.get_section(), sections[i], "E bir sonraki bölüm")
		assert_eq(book.current_page(), "kisiler")
	await _key(KEY_E)
	assert_eq(book.current_page(), "taslar", "Son bölümde E kitabın sonraki sayfasına geçer")
	await _key(KEY_Q)
	assert_eq(book.current_page(), "kisiler")
	page = book.get_page() as EncyclopediaPage
	assert_eq(page.get_section(), sections[sections.size() - 1], "Geri gelinen sayfa son bölümünde açılır")
	page.open_section(sections[0])
	await _key(KEY_Q)
	assert_eq(book.current_page(), "gok_yer", "İlk bölümde Q önceki sayfaya geçer")
	await _key(KEY_Q)
	assert_eq(book.current_page(), "destan")
	await _key(KEY_Q)
	assert_eq(book.current_page(), "taslar", "Kitap başa sarar")


func test_search_box_takes_q_and_e_as_letters() -> void:
	var book := DestanKitabi.open(self, {})
	_nodes.append(book)
	await wait_frames(2)
	book.show_page("kisiler")
	var page := book.get_page() as EncyclopediaPage
	var section := page.get_section()
	page.get_search_box().grab_focus()
	await wait_frames(1)
	await _key(KEY_Q, "q".unicode_at(0))
	await _key(KEY_E, "e".unicode_at(0))
	assert_eq(page.get_search_box().text, "qe", "Arama odaktayken Q ve E harf yazar")
	assert_eq(book.current_page(), "kisiler", "Sayfa çevrilmez")
	assert_eq(page.get_query(), "qe")
	page.clear_search()
	assert_eq(page.get_section(), section)


func test_entries_with_their_own_model_show_it() -> void:
	# K85, «3b modeli olmayanlar t pose a düşsün»: kişinin kendi glb'si varsa üçüncü yuva 3B'dir.
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/kisiler.json"))
	var seen := {}
	for rec: Dictionary in (parsed as Dictionary)["people"]:
		var id := str(rec["id"])
		if EncyclopediaModelView.model_path(id).is_empty():
			continue
		seen[id] = true
		assert_eq(str(rec.get("model", "")), id, "%s: kendi modeli kayıtta" % id)
		assert_eq(EncyclopediaPage.slot_kinds(rec)[2], "model", "%s: üçüncü yuva 3B" % id)
	for id in ["mete", "mother", "father", "child", "teoman", "lan_hatun", "older_brother", "counter", "hereka"]:
		assert_true(seen.has(id), "%s: kaydı ve modeli var" % id)
	# Sonradan gelen modeller 3B yuvasında kurulur ve ayakta durur.
	for id in ["teoman", "lan_hatun", "older_brother", "counter", "hereka"]:
		var view := EncyclopediaModelView.new(id)
		add_child(view)
		_nodes.append(view)
		for i in 240:
			if view.is_ready():
				break
			await wait_frames(1)
		assert_true(view.is_ready(), "%s: 3B kuruldu" % id)
		if view.is_ready():
			assert_true(view.get_avatar().has_meshy_model(), "%s: Meshy modeli" % id)
			assert_true(view.get_avatar().available_roles().has(&"idle"), "%s: bekleme klibi" % id)


func test_left_and_right_cycle_the_three_images() -> void:
	var page := _page("kisiler", _all_flags())
	await wait_frames(2)
	assert_true(page.open_entry("bard"))
	assert_eq(EncyclopediaPage.slot_kinds(page.get_selected()), ["profile", "art", "model"] as Array[String], "Ozanın modeli var: üçüncü yuva 3B")
	assert_true(page.open_entry("older_brother"))
	assert_eq(EncyclopediaPage.slot_kinds(page.get_selected()), ["profile", "art", "model"] as Array[String], "Ağabey'in modeli var: üçüncü yuva 3B")
	assert_true(page.open_entry("lan_clan"))
	assert_eq(EncyclopediaPage.slot_kinds(page.get_selected()), ["profile", "art", "pose"] as Array[String], "Modeli olmayanda T-POZ")
	var start := page.get_slot()
	assert_eq(start, EncyclopediaPage.default_slot(page.get_selected()))
	page.set_slot(1)
	await _key(KEY_RIGHT)
	assert_eq(page.get_slot(), 2, "→ ART'tan T-POZ'a")
	await _key(KEY_RIGHT)
	assert_eq(page.get_slot(), 0, "→ döngüyle PROFİL'e")
	await _key(KEY_LEFT)
	assert_eq(page.get_slot(), 2, "← geri döner")
	assert_eq(page.current_kind(), "pose")
	assert_eq(EncyclopediaPage.SLOT_LABELS["profile"], "PROFİL")
	assert_eq(EncyclopediaPage.SLOT_LABELS["model"], "3B")


func test_model_slot_loads_the_existing_model_only_when_chosen() -> void:
	var page := _page("kisiler", {})
	await wait_frames(2)
	page.open_entry("bard")
	page.set_slot(1)
	assert_null(page.get_model_view(), "3B yalnız seçilince kurulur")
	page.set_slot(2)
	var view := page.get_model_view()
	assert_not_null(view)
	if view == null:
		return
	assert_eq(view.model_id, "elder", "Ozanın modeli elder")
	var ready := view.is_ready()
	for i in 240:
		if ready:
			break
		await wait_frames(1)
		ready = view.is_ready()
	assert_true(ready, "Model arka planda yüklenir")
	page.set_slot(0)
	assert_null(page.get_model_view(), "Başka yuvaya geçince 3B bırakılır")


func test_enter_zooms_and_esc_backs_out_in_order() -> void:
	var flags := _all_flags()
	var id := _first_with_art(flags)
	if id.is_empty():
		fail("Görseli içe aktarılmış kişi yok (tools/import_encyclopedia.py --images)")
		return
	var book := DestanKitabi.open(self, flags)
	_nodes.append(book)
	await wait_frames(2)
	book.show_page("kisiler")
	var page := book.get_page() as EncyclopediaPage
	page.open_entry(id)
	page = book.get_page() as EncyclopediaPage
	page.set_slot(1)
	var title := str(page.get_selected()["title"])
	page.set_query(title)
	assert_eq(page.get_selected_id(), id, "Kişi aramada da açık kalır")
	await _key(KEY_ENTER)
	assert_true(page.is_zoomed(), "Enter görseli büyütür")
	page.get_search_box().grab_focus()
	await wait_frames(1)
	await _esc()
	assert_false(page.is_zoomed(), "Esc önce büyütülmüş görseli kapatır")
	assert_eq(page.get_query(), title, "Arama yerinde kalır")
	await _esc()
	assert_eq(page.get_query(), "", "Sonra aramadan çıkar")
	var closed := watch_signal(book.closed)
	await _esc()
	assert_eq(closed.count, 1, "En son kitabı kapatır")


func test_missing_images_show_the_initial_and_the_note() -> void:
	var page := _page("kisiler", {JourneyFlags.STABLE: true})
	await wait_frames(2)
	assert_true(page.open_entry("doru"))
	var e := page.get_selected()
	for kind in ["art", "portrait", "pose", "thumb"]:
		assert_eq(str(e["images"][kind]), "", "Doru'nun görseli yok: %s" % kind)
	assert_eq(page.get_stage_text(), EncyclopediaPage.EMPTY_IMAGE_TEXT, "«Görsel henüz üretilmedi.»")
	await _key(KEY_ENTER)
	assert_false(page.is_zoomed(), "Görseli olmayan yuva büyümez")


func test_lineage_cards_go_to_people_and_locked_ones_are_felt() -> void:
	var page := _page("kisiler", {})
	await wait_frames(2)
	page.open_entry("bard")
	var cards := page.get_lineage_cards()
	var child: EncyclopediaPage.LineageCard = null
	var mete: EncyclopediaPage.LineageCard = null
	for c in cards:
		if c.target == "child":
			child = c
		elif c.target == "mete":
			mete = c
	assert_not_null(child, "Ozanın ardılı Çocuk")
	assert_not_null(mete, "Ozanın II–III'te ocağında çaldığı Mete (K106: Teoman ocağın sahibi değil)")
	if child == null or mete == null:
		return
	assert_true(mete.locked and mete.disabled, "Açılmamış kişi adsız keçe siluettir, basılmaz")
	assert_eq(mete.title, "", "Adı yazılmaz")
	assert_false(child.locked)
	child.pressed.emit()
	assert_eq(page.get_selected_id(), "child", "Karta basınca o kişiye gidilir")


func test_badges_and_facts_on_the_sky_page() -> void:
	var page := _page("gok_yer", {JourneyFlags.PROLOGUE: true})
	await wait_frames(2)
	assert_true(page.open_entry("erlik"))
	var seals := page.find_children("*", "Control", true, false).filter(func(n: Node) -> bool: return n is EncyclopediaPage.BadgeSeal)
	assert_eq(seals.map(func(s: EncyclopediaPage.BadgeSeal) -> String: return s.text), ["Ozan der"], "Erlik'in rozeti «Ozan der»")
	var facts := page.find_child("Facts", true, false) as RichTextLabel
	assert_not_null(facts)
	if facts:
		assert_true(facts.text.contains("Gelenek:") and facts.text.contains("Alanı:") and facts.text.contains("Motifler:"), "Bilgi satırı")
	assert_not_null(page.find_child("Source", true, false), "Kaynak notu")
	var headings := page.find_children("*", "Label", true, false).map(func(l: Node) -> String: return (l as Label).text)
	assert_true("KİMLİĞİ" in headings and "ANLATI NOTU" in headings, "Numaralı bölümler: %s" % [headings])


# --- Tanıtım sesi (K86) ---------------------------------------------------------------------------------

func _audio_page(id: String, flags: Dictionary) -> EncyclopediaPage:
	_audio = AudioManagerScript.new()
	add_child(_audio)
	var page := _page("kisiler", flags)
	page.audio = _audio
	await wait_frames(2)
	page.open_entry(id)
	return page


func test_speaker_plays_the_intro_on_the_voice_bus_with_ducking() -> void:
	var page: EncyclopediaPage = await _audio_page("bard", {})
	assert_true(page.has_speaker(), "Dosyası olan kişide hoparlör var")
	assert_false(page.has_intro_text())
	await _key(KEY_SPACE)
	assert_true(page.is_intro_playing(), "Boşluk (book_intro) tanıtımı başlatır")
	assert_eq(_audio.current_line(), "ency.bard")
	var voice := _audio.get_node("VoicePlayer") as AudioStreamPlayer
	assert_eq(voice.bus, &"Voice", "Tanıtım Voice yolundan çalar")
	assert_not_null(voice.stream)
	assert_eq(voice.process_mode, Node.PROCESS_MODE_INHERIT, "Oynatıcı AudioManager'ın her zaman işleyen kipini alır")
	assert_eq(_audio.process_mode, Node.PROCESS_MODE_ALWAYS, "Duraklatmada da çalar")
	await get_tree().create_timer(DuckTable.PREROLL + DuckTable.ATTACK + 0.1).timeout
	assert_true(_audio.amp_db(&"Music") < -1.0, "Müzik kısılır (Amplify): %.2f dB" % _audio.amp_db(&"Music"))
	assert_true(_audio.amp_db(&"Ambience") < -1.0, "Ortam kısılır: %.2f dB" % _audio.amp_db(&"Ambience"))
	var intro: Dictionary = page.get_selected()["intro"]
	assert_eq(page.get_subtitle_text(), str(intro["tr"]), "Altyazı Türkçe")
	page.get_speaker().pressed.emit()
	assert_false(page.is_intro_playing(), "İkinci basış susturur")
	assert_eq(_audio.current_line(), "")
	assert_eq(page.get_subtitle_text(), "")


func test_changing_person_or_closing_silences_the_intro() -> void:
	var page: EncyclopediaPage = await _audio_page("bard", {})
	page.play_intro()
	assert_eq(_audio.current_line(), "ency.bard")
	page.open_entry("mother")
	assert_false(page.is_intro_playing(), "Başka kişiye geçince susar")
	assert_eq(_audio.current_line(), "")
	page.play_intro()
	assert_eq(_audio.current_line(), "ency.mother")
	page.get_parent().remove_child(page)
	assert_eq(_audio.current_line(), "", "Kitap kapanınca susar")
	page.free()


func test_no_speaker_without_a_file_and_never_for_the_silent() -> void:
	var page := _page("kisiler", {JourneyFlags.PROLOGUE: true})
	await wait_frames(2)
	page.open_entry("child")
	assert_eq(str(page.get_selected()["intro_audio"]), "", "Çocuğun sesi seçimini bekliyor")
	assert_false(page.has_speaker(), "Dosyası olmayan kişide hoparlör yok")
	assert_true(page.has_intro_text(), "İki cümle sayfada yazıdır")
	page.open_entry("umay")
	assert_false(page.get_selected()["speaks"], "Umay oyunda konuşmaz (K36)")
	assert_false(page.has_speaker(), "Konuşmayan kişide hoparlör hiç yok")
	await _key(KEY_SPACE)
	assert_false(page.is_intro_playing())


# --- Kitap kipi ------------------------------------------------------------------------------------------

func test_book_mode_turns_chapters_with_q_and_e_and_closes_with_esc() -> void:
	var book := DestanKitabi.open(self, {})
	_nodes.append(book)
	await wait_frames(2)
	assert_eq(book.mode, "book")
	assert_eq(book.current_page(), "destan")
	await _key(KEY_Q)
	assert_eq(book.current_page(), "taslar", "Q geri çevirir, baştan sona sarar")
	var closed := watch_signal(book.closed)
	await _esc()
	assert_eq(closed.count, 1, "Esc kitabı kapatmalı")


func test_destan_page_lists_entries() -> void:
	var holder := Control.new()
	holder.size = Vector2(1920, 900)
	add_child(holder)
	_nodes.append(holder)
	var page := DestanKitabiPage.new("taslar", {})
	UIKit.full_rect(page)
	holder.add_child(page)
	await wait_frames(2)
	assert_eq(page.get_entries().size(), 0)
	assert_eq(page.get_shown_index(), -1)
	assert_eq(page.get_shown_title(), "Taşlar")
	assert_true(page.get_shown_text().contains(DestanKitabi.EMPTY_TEXT))
	var verses := DestanKitabiPage.new("destan", {})
	UIKit.full_rect(verses)
	holder.add_child(verses)
	await wait_frames(2)
	assert_true(verses.get_shown_text().begins_with("[i]"), "Dizeler italik yazılır")


# --- Koşullar ve yer işaretleri ---------------------------------------------------------------------

func test_condition_language() -> void:
	var f := {"a": true, "b": false, "n": 2, "z": 0, "s": "evet", "e": ""}
	assert_true(JourneyFlags.holds(f, ""))
	assert_true(JourneyFlags.holds(f, "*"))
	assert_true(JourneyFlags.holds(f, "a"))
	assert_false(JourneyFlags.holds(f, "b"))
	assert_true(JourneyFlags.holds(f, "!b"))
	assert_true(JourneyFlags.holds(f, "b || a"))
	assert_false(JourneyFlags.holds(f, "a && b"))
	assert_true(JourneyFlags.holds(f, "a && !b"))
	assert_true(JourneyFlags.holds(f, "n && s"), "Sıfır olmayan sayı ve dolu yazı konmuş sayılır")
	assert_false(JourneyFlags.holds(f, "z || e"))
	assert_false(JourneyFlags.holds(f, "yok"))


func _camp_landmarks() -> Dictionary:
	var field := RockField.new()
	var marks := JourneyFlags.build_landmarks(JourneyFlags.DEFAULT_FIRE, JourneyFlags.DEFAULT_STABLE, field.hero_rocks, field.formations)
	field.free()
	return marks


func test_spawn_point_sets_no_landmark_flag() -> void:
	var marks := _camp_landmarks()
	var spawn := MainScript.SPAWN_OFFSET
	assert_eq(JourneyFlags.flags_at(Vector2(spawn.x, spawn.z), marks), PackedStringArray(),
		"Oyuncunun belirdiği yer (ateşin sağ önü) hiçbir işareti kendiliğinden koymamalı")
	assert_eq(JourneyFlags.place_at(Vector2(spawn.x, spawn.z), marks), "ocak", "Belirme yeri ocak başı sayılır")


func test_landmarks_of_the_camp() -> void:
	var marks := _camp_landmarks()
	assert_true(JourneyFlags.FIRESIDE in JourneyFlags.flags_at(Vector2(1.2, 1.5), marks), "Ateşin başı")
	assert_true(JourneyFlags.STABLE in JourneyFlags.flags_at(Vector2(10.5, -10.0), marks), "Ahırın önü")
	assert_true(JourneyFlags.BOULDER in JourneyFlags.flags_at(Vector2(-2.12, -15.96 + 2.3), marks), "R8 kayasının yanı")
	assert_true(JourneyFlags.FORMATION in JourneyFlags.flags_at(Vector2(-20.6 + 3.0, 2.3), marks), "Batıdaki kaya kümesi")
	assert_true(JourneyFlags.LAKE_VIEW in JourneyFlags.flags_at(Vector2(-4.0, -26.0), marks), "Göle bakan yamaç")
	assert_eq(JourneyFlags.place_at(Vector2(-4.0, -26.0), marks), "yamac")
	assert_eq(JourneyFlags.place_at(Vector2(10.5, -10.0), marks), "ahir")
	assert_eq(JourneyFlags.place_at(Vector2(0.0, 30.0), marks), "cayir")
	assert_eq(JourneyFlags.place_name("yok"), "Yurtların arası", "Bilinmeyen yer kampın içi sayılır")
	# Önsöz ve ozanı dinlemek yer işaretlerinin yanına eklendi; yerler bozulmaz.
	assert_true(JourneyFlags.PROLOGUE in JourneyFlags.ALL and JourneyFlags.BARD_LISTEN in JourneyFlags.ALL)
	for key in [JourneyFlags.FIRESIDE, JourneyFlags.STABLE, JourneyFlags.BOULDER, JourneyFlags.FORMATION]:
		assert_true(marks.has(key), "%s yer işareti kalır" % key)
	assert_false(marks.has(JourneyFlags.PROLOGUE), "Önsöz bir yer değildir")


func test_lake_view_needs_the_northern_edge() -> void:
	assert_false(JourneyFlags.overlooks_lake(Vector2(0.0, -15.0)), "Kampın içinden göl görülmez")
	assert_true(JourneyFlags.overlooks_lake(Vector2(0.0, -23.0)), "Kuzey kenarı göle bakar")
	assert_false(JourneyFlags.overlooks_lake(Vector2(0.0, 30.0)), "Güney (menü kamerasının arkası) göle bakmaz")
	assert_false(JourneyFlags.overlooks_lake(Vector2(28.0, 0.0)), "Doğu göle bakmaz")
	assert_almost(JourneyFlags.bearing_deg(Vector2(0.0, -1.0)), 0.0, 0.001, "Kuzey 0°")
	assert_almost(JourneyFlags.bearing_deg(Vector2(1.0, 0.0)), 90.0, 0.001, "Doğu 90°")


func test_landmarks_from_world_fall_back_without_a_world() -> void:
	var marks := JourneyFlags.landmarks_from_world(null)
	assert_true(JourneyFlags.FIRESIDE in JourneyFlags.flags_at(Vector2.ZERO, marks), "Dünya yoksa world.tscn'deki yerler kullanılır")
	assert_eq((marks[JourneyFlags.BOULDER] as Array).size(), 0)
	assert_true(JourneyFlags.near_bard(JourneyFlags.DEFAULT_BARD, marks), "Ozanın yedek yeri CampNpcs/Elder'ınki")


func test_unlocked_ids_for_the_toast() -> void:
	var before: Dictionary = MainScript.unlocked_ids({})
	var after: Dictionary = MainScript.unlocked_ids({JourneyFlags.FIRESIDE: true})
	assert_true(before.has("destan/ocak_basinda"))
	assert_false(before.has("destan/atesin_sozu"))
	assert_eq(str(after.get("destan/atesin_sozu", "")), "Ateşin Sözü", "Yeni açılan dize bildirimde adıyla görünür")
	assert_eq(str(after.get("taslar/ocak_taslari", "")), "Ocak Taşları")
	var listened: Dictionary = MainScript.unlocked_ids({JourneyFlags.BARD_LISTEN: true})
	assert_eq(str(listened.get("gok_yer/iyeler", "")), "İyeler", "Ozanı dinleyince iyeler bildirilir")
