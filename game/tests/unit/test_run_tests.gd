extends TestCase
## Koşucunun kendisi (tests/run_tests.gd, TestCase.run_test, TestErrorLog): test sürerken konsola yazılan
## betik hatası (SCRIPT ERROR), push_error ve motor hatası o testi düşürür ve nedeni yeriyle birlikte ✗
## satırının altına yazılır; await'ten sonra ve test beklerken çalışan ertelenmiş çağrıda çıkan hata da
## kendi testinde yakalanır, test bittikten sonra çalışanınki dosyanın ✗ satırına düşer (kaybolmaz);
## expect_errors ile bildirilen hata testi düşürmez, bildirilip yazılmayan düşürür; uyarı düşürmez;
## testlerin dışında yazılan hata dosyayı düşürür; özet ve çıkış kodu bunları sayar.
##
## Bu, koşucunun kalıcı hata ekleme denemesidir: bilerek hata yazan tests/framework/selftest/test_faults.gd
## ayrı bir Godot sürecinde gerçek koşucuyla koşturulur (bir kez, ≈0,5 sn) ve çıktısı burada okunur.
## Kasıtlı hatalar o sürecin çıktısında kalır; bu koşunun konsolu kirlenmez.

const SELFTEST_DIR := "res://tests/framework/selftest"
const FIXTURE_PATH := "res://tests/framework/selftest/test_faults.gd"
## test_faults.gd'deki testler, dosyadaki sırayla.
const FIXTURE_TESTS: Array[String] = [
	"test_clean",
	"test_script_error",
	"test_script_error_after_await",
	"test_push_error",
	"test_engine_error",
	"test_error_in_called_code",
	"test_deferred_error_inside_the_test",
	"test_expected_error",
	"test_expected_error_never_written",
	"test_warning_is_not_a_failure",
	"test_repeated_error_is_one_line",
	"test_error_comes_before_assertion",
	"test_deferred_error_after_the_test",
]

## Ayrı süreçteki koşunun sonucu (bkz. _report); dosyanın testleri paylaşır.
var _cached := {}


# --- Ayrı süreçte gerçek koşucu ------------------------------------------------------------

func test_fixture_runs_every_test_in_file_order() -> void:
	var report := _report()
	assert_eq(report.get("order"), FIXTURE_TESTS, "Koşucu test_faults.gd'nin bütün testlerini sırayla koşmalı")


func test_clean_tests_pass_without_reasons() -> void:
	# Uyarı başarısızlık değildir; test bittikten sonra çalışan çağrının hatası testin değil dosyanındır.
	for test_name in ["test_clean", "test_warning_is_not_a_failure", "test_deferred_error_after_the_test"]:
		var result := _fixture(test_name)
		assert_true(result.get("passed", false), "%s geçmeli" % test_name)
		assert_eq(result.get("reasons", []).size(), 0, "%s'in nedeni olmamalı" % test_name)


func test_script_error_fails_its_test_and_names_the_line() -> void:
	var reasons := _failed_reasons("test_script_error")
	assert_eq(reasons.size(), 1, "Tek neden: betik hatası. %s" % [reasons])
	if reasons.size() == 1:
		assert_true(reasons[0].begins_with("Betik hatası: "), reasons[0])
		assert_true(reasons[0].contains("deliberate_script_error"), "Konsoldaki ileti yazılmalı: %s" % reasons[0])
		assert_true(reasons[0].contains("— test_script_error (%s:" % FIXTURE_PATH), "Yeri testin satırı olmalı: %s" % reasons[0])


func test_script_error_after_await_is_caught() -> void:
	var reasons := _failed_reasons("test_script_error_after_await")
	assert_eq(reasons.size(), 1, "%s" % [reasons])
	if reasons.size() == 1:
		assert_true(reasons[0].begins_with("Betik hatası: "), reasons[0])
		assert_true(reasons[0].contains("deliberate_missing_key"), reasons[0])


func test_push_error_fails_its_test() -> void:
	var reasons := _failed_reasons("test_push_error")
	assert_eq(reasons.size(), 1, "%s" % [reasons])
	if reasons.size() == 1:
		assert_true(reasons[0].begins_with("push_error: kasıtlı push_error — test_push_error (%s:" % FIXTURE_PATH),
				"push_error'ın yeri C++ dosyası değil, onu çağıran betik satırı olmalı: %s" % reasons[0])
		# Bu test await eden bir testten hemen sonra koşar: yığında kalan önceki testin çerçevesi yere karışmamalı.
		assert_false(reasons[0].contains("←"), "Yer yalnız bu testin satırı olmalı: %s" % reasons[0])


func test_engine_error_fails_its_test() -> void:
	var reasons := _failed_reasons("test_engine_error")
	assert_eq(reasons.size(), 1, "%s" % [reasons])
	if reasons.size() == 1:
		assert_true(reasons[0].begins_with("Motor hatası: Node not found: \"deliberate_missing_node\""), reasons[0])
		assert_true(reasons[0].contains("— test_engine_error (%s:" % FIXTURE_PATH), reasons[0])


func test_error_in_called_code_names_both_lines() -> void:
	var reasons := _failed_reasons("test_error_in_called_code")
	assert_eq(reasons.size(), 1, "%s" % [reasons])
	if reasons.size() == 1:
		assert_true(reasons[0].begins_with("push_error: kasıtlı iç hata — _fail_inside (%s:" % FIXTURE_PATH), reasons[0])
		assert_true(reasons[0].contains(" ← test_error_in_called_code (%s:" % FIXTURE_PATH), "Bozulan satır ← testin satırı: %s" % reasons[0])


func test_deferred_error_while_the_test_waits_is_its_own() -> void:
	var reasons := _failed_reasons("test_deferred_error_inside_the_test")
	assert_eq(reasons.size(), 1, "Test bir kare beklerken çalışan çağrının hatası kendi testine yazılmalı. %s" % [reasons])
	if reasons.size() == 1:
		assert_true(reasons[0].contains("deliberate_deferred_error") and reasons[0].contains("— _fail_later ("), reasons[0])
	# Sonraki test yalnız kendi beklenen hatasını görmeli (taşan hata olsaydı onu da düşürürdü).
	assert_true(_fixture("test_expected_error").get("passed", false), "Hata sonraki teste taşmamalı")


func test_expected_error_passes_and_is_noted() -> void:
	var result := _fixture("test_expected_error")
	assert_true(result.get("passed", false), "expect_errors ile bildirilen hata testi düşürmemeli: %s" % [result])
	assert_true(str(result.get("line", "")).ends_with("(beklenen hata: 1)"), "✓ satırı beklenen hatayı saymalı: %s" % result.get("line", ""))


func test_expected_error_that_is_never_written_fails() -> void:
	var reasons := _failed_reasons("test_expected_error_never_written")
	var want: Array[String] = ["Beklenen hata yazılmadı: «hiç yazılmayan hata»"]
	assert_eq(reasons, want)


func test_repeated_error_is_reported_once_with_its_count() -> void:
	var reasons := _failed_reasons("test_repeated_error_is_one_line")
	assert_eq(reasons.size(), 1, "Aynı ileti tek satır olmalı. %s" % [reasons])
	if reasons.size() == 1:
		assert_true(reasons[0].begins_with("push_error: kasıtlı tekrarlanan hata") and reasons[0].ends_with("(×30)"), reasons[0])


func test_error_is_listed_before_the_failed_assertion() -> void:
	var reasons := _failed_reasons("test_error_comes_before_assertion")
	assert_eq(reasons.size(), 2, "%s" % [reasons])
	if reasons.size() == 2:
		assert_true(reasons[0].begins_with("push_error: kasıtlı neden"), "Önce hata (asıl neden): %s" % reasons[0])
		assert_true(reasons[1].contains("kasıtlı sonuç"), "Sonra düşen denetim: %s" % reasons[1])


func test_after_each_runs_even_when_the_test_errors() -> void:
	assert_eq(_report().get("after_each"), FIXTURE_TESTS, "Betik hatası testi yarıda kesse de after_each çalışmalı")


func test_error_outside_tests_fails_the_file() -> void:
	# Önce son testin bittikten sonra çalışan ertelenmiş çağrısı (kare sonunda), sonra düğüm silinirken
	# _exit_tree: ikisi de dosyanın ✗ satırına yazılmalı, kaybolmamalı.
	var reasons: Array = _report().get("file_reasons", [])
	assert_eq(reasons.size(), 2, "Testlerin dışında yazılan hatalar dosyanın ✗ satırına yazılmalı. %s" % [reasons])
	if reasons.size() == 2:
		assert_true(str(reasons[0]).begins_with("Betik hatası: ") and str(reasons[0]).contains("deliberate_late_error")
				and str(reasons[0]).contains("— _fail_after_the_test ("), str(reasons[0]))
		assert_true(str(reasons[1]).begins_with("push_error: kasıtlı dosya kapanış hatası — _exit_tree ("), str(reasons[1]))


func test_summary_and_exit_code_count_every_failure() -> void:
	var report := _report()
	var failed := 0
	for test_name: String in report.get("tests", {}):
		if not report["tests"][test_name]["passed"]:
			failed += 1
	if not report.get("file_reasons", []).is_empty():
		failed += 1
	assert_eq(failed, 10, "9 test ve dosyanın kendisi düşmeli")
	assert_true(str(report.get("summary", "")).begins_with("%d test, %d başarısız" % [FIXTURE_TESTS.size(), failed]),
			"Özet: %s" % report.get("summary", ""))
	assert_eq(report.get("exit_code"), 1, "Başarısız koşunun çıkış kodu 1")


# --- Aynı süreçte, konsola yazmadan ---------------------------------------------------------

func test_settle_errors_separates_expected_from_unexpected() -> void:
	var subject := TestCase.new()
	subject.fail("önceki denetim")
	subject.expect_errors(["bozuk dosya", "hiç gelmeyen"])
	var matched := subject.settle_errors(PackedStringArray([
		"Motor hatası: bozuk dosya (a)", "push_error: başka", "Motor hatası: yine bozuk dosya", "push_error: başka"]))
	assert_eq(matched, 2, "Parçayı içeren iki hata beklenen sayılmalı")
	var want: Array[String] = ["push_error: başka (×2)", "Beklenen hata yazılmadı: «hiç gelmeyen»", "önceki denetim"]
	assert_eq(subject.failures, want, "Önce beklenmeyen hata, sonra yazılmayan beklenen, en son denetimler")
	subject.free()


func test_fragment_matches_the_message_not_the_place() -> void:
	# "game_settings" gibi bir parça, o dosyada çıkan her hatayı susturmamalı.
	var subject := TestCase.new()
	subject.expect_errors(["game_settings", "bozuk dosya"])
	var matched := subject.settle_errors(PackedStringArray([
		"Betik hatası: başka bir şey — apply (res://scripts/settings/game_settings.gd:161)",
		"Motor hatası: bozuk dosya — load_settings (res://scripts/settings/game_settings.gd:94)"]))
	assert_eq(matched, 1, "Yalnız iletisinde parça geçen hata beklenen sayılmalı")
	var want: Array[String] = [
		"Betik hatası: başka bir şey — apply (res://scripts/settings/game_settings.gd:161)",
		"Beklenen hata yazılmadı: «game_settings»",
	]
	assert_eq(subject.failures, want)
	subject.free()


func test_empty_fragment_cannot_silence_errors() -> void:
	var subject := TestCase.new()
	subject.expect_errors([""])
	assert_eq(subject.expected_errors.size(), 0, "Boş parça eklenmemeli")
	assert_eq(subject.failures.size(), 1, "Boş parça testi düşürmeli")
	assert_eq(subject.settle_errors(PackedStringArray(["Betik hatası: x"])), 0)
	assert_eq(subject.failures.size(), 2, "Hata yine sayılmalı")
	subject.free()


func test_summarize_errors_caps_distinct_lines() -> void:
	var errors := PackedStringArray()
	for i in TestCase.MAX_ERROR_LINES + 3:
		errors.append("hata %d" % i)
	var lines := TestCase.summarize_errors(errors)
	assert_eq(lines.size(), TestCase.MAX_ERROR_LINES + 1)
	if lines.size() == TestCase.MAX_ERROR_LINES + 1:
		assert_eq(lines[0], "hata 0")
		assert_eq(lines[TestCase.MAX_ERROR_LINES], "... ve 3 farklı hata daha")


func test_error_log_names_each_kind_and_skips_warnings() -> void:
	var collector := TestErrorLog.new()
	var none: Array[ScriptBacktrace] = []
	collector._log_error("test_x", "res://tests/unit/test_x.gd", 12, "Invalid call.", "", false, Logger.ERROR_TYPE_SCRIPT, none)
	collector._log_error("push_error", "core/variant/variant_utility.cpp", 1023, "kasıtlı", "", false, Logger.ERROR_TYPE_ERROR, none)
	collector._log_error("load", "scene/resources/resource_format_text.cpp", 1442, "Condition \"err != OK\" is true.",
			"Cannot open file 'res://yok.tres'.", false, Logger.ERROR_TYPE_ERROR, none)
	collector._log_error("_compile", "servers/rendering/shader_language.cpp", 7, "Bozuk gölgelendirici", "", false, Logger.ERROR_TYPE_SHADER, none)
	collector._log_error("push_warning", "core/variant/variant_utility.cpp", 1033, "uyarı", "", false, Logger.ERROR_TYPE_WARNING, none)
	assert_eq(collector.take(), PackedStringArray([
		"Betik hatası: Invalid call. — test_x (res://tests/unit/test_x.gd:12)",
		"push_error: kasıtlı — push_error (core/variant/variant_utility.cpp:1023)",
		"Motor hatası: Cannot open file 'res://yok.tres'. — load (scene/resources/resource_format_text.cpp:1442)",
		"Gölgelendirici hatası: Bozuk gölgelendirici — _compile (servers/rendering/shader_language.cpp:7)",
	]), "Uyarı sayılmamalı; açıklama varsa koşul kodu yerine o yazılmalı")
	assert_eq(collector.take(), PackedStringArray(), "take() listeyi boşaltmalı")


func test_error_log_keeps_at_most_max_entries() -> void:
	var collector := TestErrorLog.new()
	var none: Array[ScriptBacktrace] = []
	for i in TestErrorLog.MAX_ENTRIES + 5:
		collector._log_error("f", "res://a.gd", 1, "hata %d" % i, "", false, Logger.ERROR_TYPE_ERROR, none)
	var lines := collector.take()
	assert_eq(lines.size(), TestErrorLog.MAX_ENTRIES + 1)
	if not lines.is_empty():
		assert_eq(lines[lines.size() - 1], "... 5 hata daha yazıldı (gösterilmedi)")


# --- Yardımcılar ---------------------------------------------------------------------------

## Koşucuyu ayrı bir Godot sürecinde test_faults.gd ile koşturur (ilk istenişte bir kez) ve çıktısını
## ayrıştırır; ayrıca "exit_code" ve ham "output" alanları vardır.
func _report() -> Dictionary:
	if _cached.is_empty():
		var output := []
		var args := PackedStringArray(["--headless", "--path", ProjectSettings.globalize_path("res://"),
				"-s", "res://tests/run_tests.gd", "--", "--dir=" + SELFTEST_DIR])
		var exit_code := OS.execute(OS.get_executable_path(), args, output, true)
		var text := "\n".join(PackedStringArray(output))
		_cached = parse_report(text)
		_cached["exit_code"] = exit_code
		_cached["output"] = text
	return _cached


## Ayrı süreçteki bir testin sonucu: {"passed", "line", "reasons"}; yoksa {} ve başarısızlık.
func _fixture(test_name: String) -> Dictionary:
	var report := _report()
	var tests: Dictionary = report.get("tests", {})
	if not tests.has(test_name):
		fail("Ayrı süreçteki koşuda %s yok (çıkış kodu %s). Çıktının sonu: %s" % [test_name, report.get("exit_code"), str(report.get("output", "")).right(600)])
		return {}
	return tests[test_name]


## Düşmesi gereken bir testin neden satırları.
func _failed_reasons(test_name: String) -> Array[String]:
	var result := _fixture(test_name)
	var reasons: Array[String] = []
	if result.is_empty():
		return reasons
	assert_false(result["passed"], "%s düşmeliydi" % test_name)
	reasons.assign(result["reasons"])
	return reasons


## Koşucunun çıktısını okur (konsolun hata satırları atlanır):
##   {"tests": {ad: {"passed": bool, "line": String, "reasons": Array[String]}}, "order": Array[String],
##    "file_reasons": Array[String], "after_each": Array[String], "summary": String}
static func parse_report(output: String) -> Dictionary:
	var tests := {}
	var order: Array[String] = []
	var file_reasons: Array[String] = []
	var after_each: Array[String] = []
	var summary := ""
	# Neden satırları ("        - ...") en son okunan ✗ satırına aittir.
	var target: Array[String] = []
	for raw in output.split("\n"):
		var line := raw.trim_suffix("\r")
		if line.begins_with("    ✓ ") or line.begins_with("    ✗ "):
			var head := line.substr(6)
			var test_name := head.get_slice(" ", 0)
			if test_name.ends_with(".gd:"):
				target = file_reasons
			else:
				var reasons: Array[String] = []
				tests[test_name] = {"passed": line.begins_with("    ✓"), "line": head, "reasons": reasons}
				order.append(test_name)
				target = reasons
		elif line.begins_with("        - "):
			target.append(line.substr(10))
		elif line.begins_with("    · after_each "):
			after_each.append(line.substr(17))
		elif line.contains(" test, ") and line.contains(" başarısız"):
			summary = line
	return {"tests": tests, "order": order, "file_reasons": file_reasons, "after_each": after_each, "summary": summary}
