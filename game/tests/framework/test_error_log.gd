class_name TestErrorLog
extends Logger
## Koşucunun günlükçüsü: test sürerken konsola yazılan hataları toplar (OS.add_logger ile kurulur).
##
## Sayılanlar: SCRIPT ERROR (betik çalışırken çıkan hata), push_error, motorun ERROR satırları (ör. açılamayan
## dosya, bozuk ayar dosyası, bulunamayan düğüm) ve SHADER ERROR. Sayılmayanlar: uyarılar (WARNING,
## push_warning) ve printerr. Godot _log_error'ı hatanın yazıldığı iş parçacığında çağırır; liste bu yüzden
## kilitle korunur.
##   var errors := TestErrorLog.new()
##   OS.add_logger(errors)
##   ...                                   # hata yazabilecek iş
##   OS.remove_logger(errors)
##   var lines := errors.take()            # ör. ["push_error: ... — test_x (res://tests/unit/test_x.gd:12)"]

## İki take() arasında tutulan en fazla ileti: her karede hata yazan bir döngü belleği şişirmesin.
const MAX_ENTRIES := 1000
## Hatanın yerini gösterirken atlanan çerçeveler: koşucunun kendisi her testin çağrı yığınındadır.
const RUNNER_FILES: Array[String] = ["res://tests/run_tests.gd", "res://tests/framework/test_case.gd"]

var _mutex := Mutex.new()
var _entries := PackedStringArray()
var _dropped := 0


func _log_error(function: String, file: String, line: int, code: String, rationale: String,
		_editor_notify: bool, error_type: int, script_backtraces: Array[ScriptBacktrace]) -> void:
	if error_type == Logger.ERROR_TYPE_WARNING:
		return
	# Konsol, açıklama varsa onu yazar (kod çoğu zaman 'Condition "x" is true.' gibi bir koşuldur).
	var text := rationale if not rationale.is_empty() else code
	var entry := describe(error_type, function, text, locate(function, file, line, script_backtraces))
	_mutex.lock()
	if _entries.size() < MAX_ENTRIES:
		_entries.append(entry)
	else:
		_dropped += 1
	_mutex.unlock()


## Toplanan iletileri verir ve listeyi boşaltır. Sınır aşıldıysa son satır kaç iletinin atıldığını söyler.
func take() -> PackedStringArray:
	_mutex.lock()
	var result := _entries
	if _dropped > 0:
		result.append("... %d hata daha yazıldı (gösterilmedi)" % _dropped)
	_entries = PackedStringArray()
	_dropped = 0
	_mutex.unlock()
	return result


## Bir hatanın tek satırlık açıklaması: türü, iletisi ve yeri.
##   "Betik hatası: Invalid call. ... — test_x (res://tests/unit/test_x.gd:12)"
static func describe(error_type: int, function: String, text: String, where: String) -> String:
	var kind := "Motor hatası"
	if error_type == Logger.ERROR_TYPE_SCRIPT:
		kind = "Betik hatası"
	elif error_type == Logger.ERROR_TYPE_SHADER:
		kind = "Gölgelendirici hatası"
	elif function == "push_error":
		kind = "push_error"
	if where.is_empty():
		return "%s: %s" % [kind, text]
	return "%s: %s — %s" % [kind, text, where]


## Hatanın yeri: en içteki betik çerçevesi ve (farklıysa) koşucunun çağırdığı giriş çerçevesi; testten
## çağrılan oyun kodunda bu "bozulan satır ← testin satırı" olur. Hatanın kendi yeri bir betikteyse ama
## yığında yoksa (ör. yüklenen dosyanın ayrıştırma hatası) en içteki yerine o yazılır. Betik çerçevesi
## yoksa (ör. motorun kendi işi) C++ konumu yazılır.
static func locate(function: String, file: String, line: int, script_backtraces: Array[ScriptBacktrace]) -> String:
	var frames := _innermost_and_entry(script_backtraces)
	var innermost := frames[0]
	var entry := frames[1]
	if file.begins_with("res://") and not innermost.ends_with("(%s:%d)" % [file, line]):
		innermost = "%s (%s:%d)" % [function, file, line]
	elif innermost.is_empty():
		return "%s (%s:%d)" % [function, file, line] if not file.is_empty() else ""
	return innermost if entry.is_empty() or entry == innermost else "%s ← %s" % [innermost, entry]


## Yığının en içteki çerçevesi ve koşucunun çağırdığı giriş çerçevesi (koşucu dışında çerçeve yoksa "").
## Yığın ilk koşucu çerçevesinde kesilir: await'ten dönen bir işlev, onu sürdüren eski çerçeveleri (önceki
## testleri bile) yığında taşır.
static func _innermost_and_entry(script_backtraces: Array[ScriptBacktrace]) -> PackedStringArray:
	var innermost := ""
	var entry := ""
	for backtrace in script_backtraces:
		for i in backtrace.get_frame_count():
			var frame := "%s (%s:%d)" % [backtrace.get_frame_function(i), backtrace.get_frame_file(i), backtrace.get_frame_line(i)]
			if innermost.is_empty():
				innermost = frame
			if backtrace.get_frame_file(i) not in RUNNER_FILES:
				entry = frame
			elif not entry.is_empty():
				# Testin (ya da ertelenmiş çağrının) dışına çıkıldı; ötesi koşucunun ve eski çerçevelerin.
				return PackedStringArray([innermost, entry])
	return PackedStringArray([innermost, entry])
