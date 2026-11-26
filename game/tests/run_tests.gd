extends SceneTree
## Test koşucusu: tests/unit/test_*.gd dosyalarındaki tüm testleri çalıştırır.
##
## Kullanım (proje klasöründe):
##   tools/run_tests.sh                    # hepsi
##   tools/run_tests.sh --filter=terrain   # dosya adında "terrain" geçenler
##   tools/run_tests.sh --dir=res://tests/framework/selftest   # başka bir klasörün test_*.gd dosyaları
## Test sürerken konsola yazılan hata (SCRIPT ERROR, push_error, motorun ERROR satırı) o testi düşürür ve
## nedeni ✗ satırının altına yazılır; testin bilerek yazdırdığı hata TestCase.expect_errors ile bildirilir.
## Testlerin dışında yazılan hata (dosya yüklenirken, kurulurken ya da kapanırken; son testlerin ertelenmiş
## çağrıları ve silinen düğümleri de dosya kapanırken çalışır) dosyayı düşürür.
## Çıkış kodu: 0 = hepsi geçti, 1 = en az bir test başarısız (ya da bir test takıldı).

const TEST_DIR := "res://tests/unit"
## Tek bir testin en uzun süresi (saniye). Aşılırsa test "takıldı" sayılır ve koşu durdurulur
## (ör. hiç gelmeyen bir sinyali bekleyen test, koşucuyu sonsuza kadar bekletmesin).
const TEST_TIMEOUT := 180.0

## Çalışan testin sıra numarası: bekçi, kendi testi hâlâ çalışıyorsa koşuyu durdurur.
var _test_serial := 0
## Koşu boyunca konsola yazılan hataları toplar; her testin sonunda o testin hataları alınır.
var _errors := TestErrorLog.new()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var filter := ""
	var dir := TEST_DIR
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--filter="):
			filter = arg.substr(9)
		elif arg.begins_with("--dir="):
			dir = arg.substr(6).trim_suffix("/")
	var files := Array(DirAccess.get_files_at(dir)).filter(
		func(f: String) -> bool: return f.begins_with("test_") and f.ends_with(".gd") and (filter.is_empty() or f.contains(filter)))
	files.sort()
	var total := 0
	var failed := 0
	var started := Time.get_ticks_msec()
	OS.add_logger(_errors)
	for file in files:
		var script := load(dir.path_join(file)) as GDScript
		# Testlerin dışında yazılan hatalar (yüklerken, kurarken, kapatırken) dosyanın hanesine yazılır.
		var file_errors := _errors.take()
		# Sözdizimi hatalı bir betik de yüklenir ama örneklenemez: new() çağrılırsa koşu yarıda kalır.
		if script == null or not script.can_instantiate():
			print("✗ %s yüklenemedi (sözdizimi hatası olabilir)" % file)
			_print_reasons(TestCase.summarize_errors(file_errors))
			failed += 1
			continue
		var test = script.new()
		if not test is TestCase:
			print("✗ %s TestCase'den türemiyor" % file)
			failed += 1
			continue
		root.add_child(test)
		print("● %s" % file)
		for method in test.get_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			file_errors.append_array(_errors.take())
			_test_serial += 1
			_watch(_test_serial, "%s › %s" % [file, name])
			var expected: int = await test.run_test(name, _errors)
			total += 1
			if test.failures.is_empty():
				var note := "  (beklenen hata: %d)" % expected if expected > 0 else ""
				print("    ✓ %s%s" % [name, note])
			else:
				failed += 1
				print("    ✗ %s" % name)
				_print_reasons(test.failures)
		test.queue_free()
		await process_frame
		file_errors.append_array(_errors.take())
		if not file_errors.is_empty():
			failed += 1
			print("    ✗ %s: testlerin dışında hata yazıldı (dosya kurulurken ya da kapanırken; son testlerin ertelenmiş işi de burada çalışır)" % file)
			_print_reasons(TestCase.summarize_errors(file_errors))
	OS.remove_logger(_errors)
	print("")
	_test_serial += 1
	print("%d test, %d başarısız (%.1f sn)" % [total, failed, (Time.get_ticks_msec() - started) / 1000.0])
	quit(1 if failed > 0 else 0)


## Bir ✗ satırının altındaki neden satırları.
func _print_reasons(reasons: Array[String]) -> void:
	for reason in reasons:
		print("        - %s" % reason)


## Bekçi: TEST_TIMEOUT sonra aynı test hâlâ çalışıyorsa adını ve o ana dek yazılan hataları (çoğu zaman
## beklenen sinyalin neden gelmediğini söyler) yazar, koşuyu başarısız olarak bitirir.
func _watch(serial: int, label: String) -> void:
	await create_timer(TEST_TIMEOUT).timeout
	if serial == _test_serial:
		print("    ✗ %s %.0f sn içinde bitmedi (takıldı); test koşusu durduruluyor" % [label, TEST_TIMEOUT])
		_print_reasons(TestCase.summarize_errors(_errors.take()))
		quit(1)
