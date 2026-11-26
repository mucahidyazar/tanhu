class_name TestCase
extends Node
## Tüm birim testlerinin temeli.
##
## tests/unit/test_*.gd dosyalarındaki "test_" ile başlayan her metot ayrı bir test olarak çalışır.
## Test sınıfı sahne ağacına eklenir; bu yüzden sahne örneklemek ve kare beklemek mümkündür:
##   func test_menu_has_four_buttons() -> void:
##       var menu := preload("res://scenes/ui/main_menu.tscn").instantiate()
##       add_child(menu)
##       await wait_frames(2)
##       assert_eq(menu.get_main_buttons().size(), 4)
##
## Test sürerken konsola yazılan hata (SCRIPT ERROR, push_error, motorun ERROR satırı) testi düşürür ve
## nedeni ✗ satırının altına yazılır (bkz. run_test). Testin bilerek yazdırdığı hata expect_errors ile
## bildirilir.

## Hata nedenlerinden en fazla kaç farklı ileti ayrı satır olarak yazılır (aynı ileti tek satırda "×n" olur).
const MAX_ERROR_LINES := 5

var failures: Array[String] = []
var current_test := ""
## Bu testin bilerek yazdırdığı hataların parçaları (bkz. expect_errors); her testin başında boşalır.
var expected_errors := PackedStringArray()


## Her testten önce/sonra çağrılır (alt sınıflar isterse ezebilir).
func before_each() -> void:
	pass


func after_each() -> void:
	pass


## Koşucu her test için bunu çağırır: before_each, test ve after_each; bu sürede error_log'a düşen hatalar
## settle_errors ile teste işlenir, sonuç failures'tadır. Beklenip yazılan hata sayısını döndürür.
## Testten sonra kare beklenmez (eskisi gibi): beklemek her testin sildiği düğümleri ve onlarla giden
## kaynakları gerçekten bırakır, sonraki test modelleri diskten yeniden yükler (karakter oluşturucu
## testleri ≈9 kat yavaşlar). Bu yüzden testin bitişinden sonra çalışan iş (call_deferred, silinen düğüm,
## kare sonu) hatasını bir kare bekleyen ilk sonraki teste ya da dosyanın kapanışına yazar.
func run_test(method: String, error_log: TestErrorLog) -> int:
	failures.clear()
	expected_errors.clear()
	current_test = method
	before_each()
	# Betik hatası test fonksiyonunu yarıda keser; after_each yine çalışır.
	await call(method)
	after_each()
	return settle_errors(error_log.take())


## Testin bilerek yazdırdığı hataları bildirir (ör. bozuk bir dosyanın reddedildiğini sınayan testte motorun
## yazdığı ayrıştırma hatası). Her parça, test sürerken yazılan en az bir hata iletisinde geçmeli (yeri
## sayılmaz): parçayı içeren hatalar testi düşürmez; içermeyen her hata ve hiç yazılmayan bir parça düşürür.
##   expect_errors(["ConfigFile parse error"])   # bozuk settings.cfg'yi motor konsola yazar
func expect_errors(fragments: PackedStringArray) -> void:
	for fragment in fragments:
		if fragment.strip_edges().is_empty():
			fail("expect_errors'a boş parça verildi: boş parça her hatayı susturur")
		else:
			expected_errors.append(fragment)


## Test sürerken yazılan hataları (TestErrorLog iletileri) beklenenlerle karşılaştırır. Beklenmeyen hatalar
## ve hiç yazılmayan beklenen parçalar failures'ın başına eklenir (denetimin düşmesinin nedeni çoğu zaman
## odur). Beklenip yazılan hata sayısını döndürür.
func settle_errors(errors: PackedStringArray) -> int:
	var matched := 0
	var unexpected := PackedStringArray()
	var seen := {}
	for error in errors:
		# Yer ("— işlev (dosya:satır)") eşleşmeye girmez: "game_settings" gibi bir parça o dosyadaki her
		# hatayı susturmasın.
		var message := error.substr(0, error.rfind(" — ")) if error.contains(" — ") else error
		var hit := false
		for fragment in expected_errors:
			if message.contains(fragment):
				seen[fragment] = true
				hit = true
		if hit:
			matched += 1
		else:
			unexpected.append(error)
	var reasons := summarize_errors(unexpected)
	for fragment in expected_errors:
		if not seen.has(fragment):
			reasons.append("Beklenen hata yazılmadı: «%s»" % fragment)
	reasons.append_array(failures)
	failures = reasons
	return matched


## Hata iletilerini rapor satırlarına çevirir: aynı ileti bir kez, "(×n)" ile; en fazla MAX_ERROR_LINES
## farklı ileti, kalanı tek satırda sayılır.
static func summarize_errors(errors: PackedStringArray) -> Array[String]:
	var counts := {}
	for error in errors:
		counts[error] = int(counts.get(error, 0)) + 1
	var lines: Array[String] = []
	for error: String in counts:
		if lines.size() == MAX_ERROR_LINES:
			lines.append("... ve %d farklı hata daha" % (counts.size() - MAX_ERROR_LINES))
			break
		var n: int = counts[error]
		lines.append(error if n == 1 else "%s (×%d)" % [error, n])
	return lines


func fail(message: String) -> void:
	failures.append(message)


func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		fail("Doğru olması bekleniyordu. %s" % message)


func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		fail("Yanlış olması bekleniyordu. %s" % message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if typeof(actual) != typeof(expected) and not (_is_number(actual) and _is_number(expected)):
		fail("Tür farklı: %s (%s) != %s (%s). %s" % [actual, type_string(typeof(actual)), expected, type_string(typeof(expected)), message])
	elif actual != expected:
		fail("Eşit değil: %s != %s. %s" % [actual, expected, message])


func assert_ne(actual: Variant, unexpected: Variant, message: String = "") -> void:
	if actual == unexpected:
		fail("Farklı olması bekleniyordu: %s. %s" % [actual, message])


func assert_almost(actual: float, expected: float, epsilon: float = 0.001, message: String = "") -> void:
	if absf(actual - expected) > epsilon:
		fail("%f ≉ %f (tolerans %f). %s" % [actual, expected, epsilon, message])


func assert_vec_almost(actual: Vector3, expected: Vector3, epsilon: float = 0.001, message: String = "") -> void:
	if actual.distance_to(expected) > epsilon:
		fail("%s ≉ %s (tolerans %f). %s" % [actual, expected, epsilon, message])


func assert_between(value: float, low: float, high: float, message: String = "") -> void:
	if value < low or value > high:
		fail("%f, [%f, %f] aralığında değil. %s" % [value, low, high, message])


func assert_not_null(value: Variant, message: String = "") -> void:
	if value == null:
		fail("null olmaması bekleniyordu. %s" % message)


func assert_null(value: Variant, message: String = "") -> void:
	if value != null:
		fail("null olması bekleniyordu, %s geldi. %s" % [value, message])


## Sinyal yayıldı mı? Kullanım: var w := watch_signal(menu.quit_requested); ...; assert_true(w.fired)
func watch_signal(sig: Signal) -> SignalWatcher:
	var watcher := SignalWatcher.new()
	sig.connect(watcher.on_emit)
	return watcher


## n kare bekler (UI animasyonları, ertelenmiş çağrılar için).
func wait_frames(n: int = 1) -> void:
	for i in n:
		await get_tree().process_frame


static func _is_number(v: Variant) -> bool:
	return typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT


## Bir sinyalin kaç kez ve hangi argümanlarla yayıldığını kaydeder.
class SignalWatcher:
	extends RefCounted
	var count := 0
	var last_args: Array = []
	var fired: bool:
		get:
			return count > 0

	func on_emit(a: Variant = null, b: Variant = null, c: Variant = null, d: Variant = null) -> void:
		count += 1
		last_args = [a, b, c, d].filter(func(x): return x != null)
