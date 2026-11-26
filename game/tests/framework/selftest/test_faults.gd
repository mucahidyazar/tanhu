extends TestCase
## Koşucunun kendi sınaması için bilerek hata yazan testler. tests/unit/test_run_tests.gd bu klasörü ayrı
## bir Godot sürecinde gerçek koşucuyla koşturur (--dir=res://tests/framework/selftest) ve çıktısını okur.
## Olağan koşu bu klasöre bakmaz; buradaki ✗'ler beklenen sonuçtur. Elle görmek için:
##   tools/run_tests.sh --dir=res://tests/framework/selftest
## Kasıtlı hataların metninde "deliberate" ya da "kasıtlı" geçer. Testler dosyadaki sırayla koşar; sıra ve
## adlar test_run_tests.gd'deki FIXTURE_TESTS ile aynı kalmalı.


func after_each() -> void:
	# Betik hatası testi yarıda kesse de temizlik çalışmalı: test_run_tests.gd bu satırları okur.
	print("    · after_each %s" % current_test)


func _exit_tree() -> void:
	# Testlerin dışında (dosya kapanırken) yazılan hata dosyanın hanesine yazılmalı.
	push_error("kasıtlı dosya kapanış hatası")


func test_clean() -> void:
	assert_true(true)


func test_script_error() -> void:
	var target = null
	target.deliberate_script_error()


func test_script_error_after_await() -> void:
	await wait_frames(1)
	var empty := {}
	print(empty["deliberate_missing_key"])


func test_push_error() -> void:
	push_error("kasıtlı push_error")


func test_engine_error() -> void:
	get_node("deliberate_missing_node")


func test_error_in_called_code() -> void:
	# Oyun kodu gibi: hata testin çağırdığı işlevde; yer "bozulan satır ← testin satırı" olmalı.
	_fail_inside()


func test_deferred_error_inside_the_test() -> void:
	# Ertelenmiş çağrı test bir kare beklerken çalışır: hatası bu testin hanesine yazılmalı.
	_fail_later.call_deferred()
	await wait_frames(1)


func test_expected_error() -> void:
	expect_errors(["kasıtlı beklenen hata"])
	push_error("kasıtlı beklenen hata")


func test_expected_error_never_written() -> void:
	expect_errors(["hiç yazılmayan hata"])


func test_warning_is_not_a_failure() -> void:
	push_warning("kasıtlı uyarı")


func test_repeated_error_is_one_line() -> void:
	for i in 30:
		push_error("kasıtlı tekrarlanan hata")


func test_error_comes_before_assertion() -> void:
	push_error("kasıtlı neden")
	assert_true(false, "kasıtlı sonuç")


func test_deferred_error_after_the_test() -> void:
	# Test kare beklemeden biter; ertelenmiş çağrı dosya kapanırken çalışır, hatası dosyanın ✗ satırına
	# yazılmalı (sessizce kaybolmamalı). Bu yüzden dosyanın son testidir.
	_fail_after_the_test.call_deferred()


func _fail_inside() -> void:
	push_error("kasıtlı iç hata")


func _fail_later() -> void:
	var target = null
	target.deliberate_deferred_error()


func _fail_after_the_test() -> void:
	var target = null
	target.deliberate_late_error()
