class_name SaveSystem
extends RefCounted
## Kayıt yuvaları: 0 = otomatik kayıt (ana menüye ya da masaüstüne dönerken yazılır), 1..SLOTS =
## oyuncunun kendi kayıtları. Her yuva bir JSON dosyası ve (varsa) 320×180'lik küçük bir ekran
## görüntüsüdür. Dosya yazma işini yalnızca bu sınıf yapar; kaydın içeriği SaveData'dadır.
##
## Bozuk ya da yarım bir dosya boş yuva sayılır (oyun çökmez). Yazma önce geçici dosyaya yapılır,
## sonra yerine taşınır: yazarken oyun kapanırsa eski kayıt bozulmaz.
## Testler ve geliştirme çalıştırmaları başka bir klasör verir (oyuncunun kayıtlarına dokunulmaz):
##   var saves := SaveSystem.new("/tmp/tanhu3_test_saves")
##
## user:// proje adından bağımsız, sabit bir klasördür (project.godot: use_custom_user_dir ve
## custom_user_dir_name; macOS'ta ~/Library/Application Support/Tanhu Bozkir Destani). Eski varsayılan
## klasördeki (app_userdata/Tanhu) kayıtlar ilk açılışta bir kez kopyalanır (UserDirMigration, K30).
## Dosya adları ve SaveData.GAME_ID ("tanhu3") değişmez: oyuncunun kaydı öksüz kalmaz.

const SLOTS := 10
const AUTO_SLOT := 0
const FILE_PATTERN := "tanhu3_save_%d.json"
const THUMB_PATTERN := "tanhu3_thumb_%d.png"
## Küçük resmin boyutu (16:9).
const THUMB_SIZE := Vector2i(320, 180)

## Kayıtların klasörü ("user://" ya da mutlak bir yol).
var dir := "user://"
## Yazılabilir mi? Kapalıysa (ör. geliştirme çalıştırması) kayıtlar okunur ama yazılmaz.
var writable := true


func _init(p_dir: String = "user://", p_writable: bool = true) -> void:
	dir = p_dir if p_dir.ends_with("/") else p_dir + "/"
	writable = p_writable


## Geçerli bir yuva numarası mı (0..SLOTS)?
static func is_valid_slot(slot: int) -> bool:
	return slot >= AUTO_SLOT and slot <= SLOTS


func slot_path(slot: int) -> String:
	return dir + FILE_PATTERN % slot


func thumb_path(slot: int) -> String:
	return dir + THUMB_PATTERN % slot


## Yuvada okunabilir bir kayıt var mı? (Bozuk dosya "yok" sayılır.)
func has_save(slot: int) -> bool:
	return not slot_info(slot).is_empty()


## Herhangi bir yuvada kayıt var mı?
func has_any_save() -> bool:
	for s in range(AUTO_SLOT, SLOTS + 1):
		if has_save(s):
			return true
	return false


## Yuvadaki kayıt (yüklemeden önce bilgisi için de kullanılır), güncel biçimde: v1 kaydı okunurken v2'ye göçer (SaveData.migrate;
## dosya değişmez). Yoksa, bozuksa (bozuk blok dahil), daha yeni bir sürümünse ya da Tanhu'nun kaydı değilse {} döner.
func slot_info(slot: int) -> Dictionary:
	if not is_valid_slot(slot):
		return {}
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	# JSON.parse (örnek yöntemi) bozuk dosyada konsola hata yazmaz; bozuk kayıt sessizce boş sayılır.
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	var parsed: Variant = json.data
	if parsed is Dictionary and SaveData.is_record(parsed):
		return SaveData.migrate(parsed)
	return {}


## En son yazılan yuva; hiç kayıt yoksa -1.
func latest_slot() -> int:
	var best := -1
	var best_key := ""
	for s in range(AUTO_SLOT, SLOTS + 1):
		var info := slot_info(s)
		if info.is_empty():
			continue
		var key := SaveData.order_key(info)
		if best == -1 or key > best_key:
			best_key = key
			best = s
	return best


## Oyuncunun kayıtlarındaki en büyük sıra numarasının bir fazlası ("Kayıt #4").
func next_save_no() -> int:
	var n := 0
	for s in range(1, SLOTS + 1):
		n = maxi(n, int(slot_info(s).get("save_no", 0)))
	return n + 1


## Kaydı yuvaya yazar; thumb verilirse küçük resmi de (16:9 kırpılıp küçültülür). Başarılıysa true.
## thumb null ise yuvanın eski küçük resmi silinir (başka bir anın resmi kalmasın); keep_thumb ise eskisi kalır (oto kayıt son resmi
## kullanır: godot.md §3.4). Kayıt yolculuk tavanını (SaveBlocks.JOURNEY_MAX_BYTES) aşarsa uyarı yazılır, kayıt yine yazılır.
func write(slot: int, record: Dictionary, thumb: Image = null, keep_thumb: bool = false) -> bool:
	if not writable or not is_valid_slot(slot):
		return false
	if not _ensure_dir():
		return false
	var path := slot_path(slot)
	var tmp := path + ".tmp"
	var text := JSON.stringify(record, "\t")
	# Tavan sıkışık JSON'undur (girinti sayılmaz); girintili metin tavanın altındaysa sıkışığı da altındadır.
	if text.length() > SaveBlocks.JOURNEY_MAX_BYTES:
		var size := JSON.stringify(record).to_utf8_buffer().size()
		if size > SaveBlocks.JOURNEY_MAX_BYTES:
			push_warning("[save] %d. yuvanın kaydı tavanı aşıyor: %d > %d bayt" % [slot, size, SaveBlocks.JOURNEY_MAX_BYTES])
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(_absolute(path))
	if DirAccess.rename_absolute(_absolute(tmp), _absolute(path)) != OK:
		return false
	if thumb != null or not keep_thumb:
		_write_thumb(slot, thumb)
	return true


## Yuvayı (ve küçük resmini) siler.
func remove(slot: int) -> void:
	if not writable or not is_valid_slot(slot):
		return
	for path in [slot_path(slot), thumb_path(slot)]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(_absolute(path))


## Yuvanın küçük resmi; yoksa ya da okunamazsa null.
func load_thumb(slot: int) -> Texture2D:
	var path := thumb_path(slot)
	if not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(_absolute(path))
	if img == null or img.is_empty():
		return null
	return ImageTexture.create_from_image(img)


## Bir kareden 16:9'luk küçük resim: ortası kırpılır ve THUMB_SIZE'a küçültülür (saf fonksiyon).
static func make_thumbnail(frame: Image) -> Image:
	if frame == null or frame.is_empty():
		return null
	var img := frame.duplicate() as Image
	if img.is_compressed():
		img.decompress()
	var w := img.get_width()
	var h := img.get_height()
	var cw := mini(w, int(h * 16.0 / 9.0))
	var ch := mini(h, int(w * 9.0 / 16.0))
	if cw != w or ch != h:
		img = img.get_region(Rect2i(int((w - cw) * 0.5), int((h - ch) * 0.5), cw, ch))
	img.resize(THUMB_SIZE.x, THUMB_SIZE.y, Image.INTERPOLATE_LANCZOS)
	return img


func _write_thumb(slot: int, thumb: Image) -> void:
	var path := thumb_path(slot)
	var small := make_thumbnail(thumb)
	if small:
		small.save_png(_absolute(path))
	elif FileAccess.file_exists(path):
		DirAccess.remove_absolute(_absolute(path))


func _ensure_dir() -> bool:
	var abs_dir := _absolute(dir)
	if DirAccess.dir_exists_absolute(abs_dir):
		return true
	return DirAccess.make_dir_recursive_absolute(abs_dir) == OK


static func _absolute(path: String) -> String:
	return ProjectSettings.globalize_path(path) if path.begins_with("user://") or path.begins_with("res://") else path
