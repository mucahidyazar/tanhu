extends TestCase
## Ekran görüntüsü aracının (scripts/dev/capture.gd) komut satırı ayrıştırma testleri.
##
## tools/capture.sh, Godot'a "-- --capture=... --frames=..." gibi argümanlar geçirir;
## parse_args bunları sözlüğe çevirir. Değerler metin (String) olarak döner, bayraklar true olur.

const CaptureTool := preload("res://scripts/dev/capture.gd")


func test_key_value_arguments() -> void:
	var args := CaptureTool.parse_args(PackedStringArray(["--capture=/tmp/menu.png", "--frames=180"]))
	assert_eq(args.size(), 2)
	assert_eq(args.get("capture"), "/tmp/menu.png")
	assert_eq(args.get("frames"), "180", "Değer metin olarak dönmeli; sayıya çevirmek çağıranın işi")
	assert_eq(int(args.get("frames", 150)), 180)


func test_flag_without_value_becomes_true() -> void:
	var args := CaptureTool.parse_args(PackedStringArray(["--hide-ui"]))
	assert_eq(args.get("hide-ui"), true)


func test_pose_value_keeps_commas_and_signs() -> void:
	var args := CaptureTool.parse_args(PackedStringArray(["--pose=0,1.2,3,0,-5"]))
	var parts := str(args.get("pose")).split(",")
	assert_eq(parts.size(), 5, "Poz beş sayıdan oluşur: x, y, z, yaw, pitch")
	assert_almost(float(parts[1]), 1.2)
	assert_almost(float(parts[4]), -5.0)


func test_window_and_state_arguments() -> void:
	# tools/capture.sh "--window=3200x1800" ile pencereyi 16:9 yapar; main.gd "--state=play" ya da
	# "--state=creator" ile menüyü atlayıp doğrudan serbest gezintiyi / karakter oluşturucuyu açar.
	var args := CaptureTool.parse_args(PackedStringArray(["--capture=/tmp/oyun.png", "--window=3200x1800", "--state=play", "--hide-ui"]))
	assert_eq(args.get("window"), "3200x1800")
	assert_eq(str(args.get("window")).split("x"), PackedStringArray(["3200", "1800"]), "Pencere boyutu genişlik x yükseklik olarak bölünebilmeli")
	assert_eq(args.get("state"), "play")
	assert_eq(args.get("hide-ui"), true)
	assert_eq(CaptureTool.parse_args(PackedStringArray(["--state=creator"])).get("state"), "creator")


func test_only_first_equals_sign_splits() -> void:
	var args := CaptureTool.parse_args(PackedStringArray(["--note=a=b", "--empty="]))
	assert_eq(args.get("note"), "a=b", "Değerin içindeki '=' korunmalı")
	assert_eq(args.get("empty"), "", "Boş değer boş metin olmalı")


func test_non_option_arguments_are_ignored() -> void:
	var args := CaptureTool.parse_args(PackedStringArray(["res://scenes/main.tscn", "-v", "capture=/tmp/x.png", "--frames=5"]))
	assert_eq(args.keys(), ["frames"], "Yalnızca '--' ile başlayanlar okunmalı")


func test_last_value_wins_and_empty_input() -> void:
	var args := CaptureTool.parse_args(PackedStringArray(["--frames=1", "--frames=2"]))
	assert_eq(args.get("frames"), "2", "Tekrarlanan argümanda sonuncusu geçerli")
	assert_true(CaptureTool.parse_args(PackedStringArray()).is_empty(), "Argüman yoksa sözlük boş")


func test_tool_removes_itself_without_capture_argument() -> void:
	# Normal oyunda (--capture yokken) araç kendini kaldırmalı; oyunu kapatmamalı.
	if CaptureTool.parse_args(OS.get_cmdline_user_args()).has("capture"):
		fail("Testler --capture argümanıyla çalıştırılmamalı (araç oyunu kapatırdı)")
		return
	var tool: Node = CaptureTool.new()
	add_child(tool)
	await wait_frames(1)
	assert_false(is_instance_valid(tool), "Yakalama aracı kendini silmeli")


# --- Kararlı kare: dondurulmuş zaman (--freeze-time, world_time genel tekdüzeni) -------------------------

func test_freeze_time_value_is_parsed() -> void:
	# tools/capture.sh ... --freeze-time=12: gölgelendiricilerin zamanı (world_time) 12. saniyede donar.
	var args := CaptureTool.parse_args(PackedStringArray(["--capture=/tmp/menu.png", "--freeze-time=12", "--window=1920x1080"]))
	assert_eq(args.get("freeze-time"), "12", "Değer metin olarak dönmeli; sayıya çevirmek freeze_time_from'un işi")
	assert_almost(CaptureTool.freeze_time_from(args), 12.0)
	assert_almost(CaptureTool.freeze_time_from(CaptureTool.parse_args(PackedStringArray(["--freeze-time=12.5"]))), 12.5)
	assert_almost(CaptureTool.freeze_time_from({"freeze-time": "12,5"}), 12.5, 0.0001, "Ondalık virgül de okunmalı")
	assert_almost(CaptureTool.freeze_time_from({"freeze-time": " 0 "}), 0.0, 0.0001, "0 geçerli bir an; boşluk sorun olmamalı")


func test_freeze_time_absent_means_time_flows() -> void:
	assert_eq(CaptureTool.freeze_time_from({}), -1.0, "Argüman yoksa zaman akar (eksi değer)")
	assert_eq(CaptureTool.freeze_time_from(CaptureTool.parse_args(PackedStringArray(["--capture=/tmp/a.png", "--frames=60"]))), -1.0)
	assert_true(CaptureTool.freeze_time_from(CaptureTool.parse_args(OS.get_cmdline_user_args())) < 0.0,
		"Testler dondurulmuş zamanla koşmamalı")


func test_freeze_time_without_or_with_bad_value_uses_default() -> void:
	# Değersiz bayrak ya da okunamayan değer yine dondurur (istenen dondurmaktır): varsayılan an kullanılır.
	assert_almost(CaptureTool.freeze_time_from(CaptureTool.parse_args(PackedStringArray(["--freeze-time"]))), CaptureTool.DEFAULT_FREEZE_TIME)
	for bad: String in ["", "abc", "12s", "1.2.3"]:
		assert_almost(CaptureTool.freeze_time_from({"freeze-time": bad}), CaptureTool.DEFAULT_FREEZE_TIME, 0.0001, "«%s»" % bad)


func test_negative_freeze_time_is_clamped_to_zero() -> void:
	# world_time'ın eksisi "zaman akıyor" demektir: eksi değer dondurma isteğini kaybettirmemeli.
	assert_eq(CaptureTool.freeze_time_from({"freeze-time": "-3"}), 0.0)
	assert_eq(CaptureTool.freeze_time_from({"freeze-time": "-0.5"}), 0.0)


func test_world_time_global_uniform_flows_by_default() -> void:
	# project.godot [shader_globals]: gölgelendiricilerin okuduğu genel tekdüzen. Varsayılanı eksidir: oyunda
	# gölgelendiriciler motorun TIME'ını kullanır, yalnız yakalama aracı onu sabitler.
	assert_true(ProjectSettings.has_setting("shader_globals/world_time"), "world_time genel tekdüzeni project.godot'ta tanımlı olmalı")
	var entry: Variant = ProjectSettings.get_setting("shader_globals/world_time")
	if not entry is Dictionary:
		fail("Genel tekdüzen {type, value} sözlüğü olmalı: %s" % [entry])
		return
	assert_eq(str((entry as Dictionary).get("type", "")), "float")
	assert_true(float((entry as Dictionary).get("value", 0.0)) < 0.0, "Oyunda zaman akmalı: varsayılan değer eksi olmalı")


func test_shaders_read_world_time_not_raw_time() -> void:
	# Zamana bağlı her gölgelendirici tn_time() okur (shaders/include/world_time.gdshaderinc). Ham TIME okuyan yeni
	# bir gölgelendirici --freeze-time ile donmaz: menü karesi referansı (tests/refs/) koşudan koşuya değişir.
	var files := _shader_files("res://shaders")
	assert_true(files.size() > 20, "Gölgelendiriciler bulunmalı (%d)" % files.size())
	var raw_time := RegEx.create_from_string("\\bTIME\\b")
	var offenders := PackedStringArray()
	var missing_include := PackedStringArray()
	var users := 0
	for path in files:
		if path.ends_with("/world_time.gdshaderinc"):
			continue
		var text := FileAccess.get_file_as_string(path)
		var code := _strip_comments(text)
		if raw_time.search(code):
			offenders.append(path)
		if code.contains("tn_time()"):
			users += 1
			if not text.contains("#include \"res://shaders/include/world_time.gdshaderinc\""):
				missing_include.append(path)
	assert_true(offenders.is_empty(), "Ham TIME okuyan gölgelendirici (tn_time() kullanılmalı): %s" % ", ".join(offenders))
	assert_true(missing_include.is_empty(), "tn_time() okuyup world_time.gdshaderinc'i içermeyen: %s" % ", ".join(missing_include))
	assert_true(users >= 10, "Çimen, su, alev, duman, gök ve sancak zamanı tn_time()'dan okumalı (%d dosya)" % users)


func test_world_time_include_falls_back_to_time() -> void:
	# Ortak dosya: eksi world_time'da TIME, değilse world_time; birden çok kez içerilebilir (koruma).
	var code := FileAccess.get_file_as_string("res://shaders/include/world_time.gdshaderinc")
	assert_true(code.contains("global uniform float world_time;"), "world_time genel tekdüzen olarak bildirilmeli")
	assert_true(code.contains("#ifndef TN_WORLD_TIME"), "İçerme koruması olmalı")
	var body := _strip_comments(code)
	assert_true(body.contains("world_time >= 0.0 ? world_time : TIME"), "Dondurulmuşsa world_time, değilse TIME")


func test_hold_capture_counts_requests() -> void:
	# Kendi akışını yöneten sahne (bütçe ölçümü) görüntüyü bekletir; her bekletme bir bırakma ister.
	var tool := CaptureTool.new()
	assert_false(tool.is_capture_held())
	tool.hold_capture()
	tool.hold_capture()
	assert_true(tool.is_capture_held())
	tool.release_capture()
	assert_true(tool.is_capture_held(), "İki istekten biri bırakıldı; görüntü hâlâ beklemeli")
	tool.release_capture()
	tool.release_capture()
	assert_false(tool.is_capture_held(), "Fazla bırakma sayacı eksiye düşürmemeli")
	tool.free()


## Klasördeki (alt klasörler dahil) .gdshader ve .gdshaderinc dosyaları.
func _shader_files(dir: String) -> PackedStringArray:
	var out := PackedStringArray()
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".gdshader") or file.ends_with(".gdshaderinc"):
			out.append(dir.path_join(file))
	for sub in DirAccess.get_directories_at(dir):
		out.append_array(_shader_files(dir.path_join(sub)))
	return out


## Gölgelendirici kodundan /* */ ve // yorumlarını atar ("res://" yollarındaki // yorum sayılmaz).
static func _strip_comments(code: String) -> String:
	var block := RegEx.create_from_string("(?s)/\\*.*?\\*/")
	var line := RegEx.create_from_string("(?<!:)//[^\\n]*")
	return line.sub(block.sub(code, "", true), "", true)
