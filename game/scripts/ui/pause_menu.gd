class_name PauseMenu
extends CanvasLayer
## Serbest gezintide Esc (Tanhu 1): dünyayı duraklatır ve yolculuğun kitabını (GameMenu, "game"
## kipi) GENEL sayfasında açar: DEVAM ET, KAYDET, YÜKLE, AYARLAR, ANA MENÜ, MASAÜSTÜNE DÖN. M ve J kitabı HARİTA ve GÖREVLER
## sayfalarında açar (open(page)); bu sayfaların verisi oyun içi HUD'dandır (hud).
## Açılırken ekranın o anki karesi bir sonraki kaydın küçük resmi olarak saklanır.
## Akışı ana sahne (main.gd) yönetir: sinyalleri dinler, ana menüye dönüşü ve yüklemeyi o yapar.

## Kitap kapandı, oyun sürüyor.
signal resumed
signal main_menu_requested
signal quit_requested
signal load_requested(slot: int)

const LAYER := 120

## Kaydedilen / okunan yolculuk.
var journey: Journey
## Ayarlar sayfasının değiştirdiği ayarlar (boşsa GameSettings autoload'u).
var settings: Node
## Kaydın kapalı olduğu an (Yeni Oyun'un Çocukluk'u, K99): boş değilse KAYDET kapalıdır ve bu satır nedenini söyler.
var save_note := ""
## Genel sayfanın yolculuk kartı: yerin adı ve altındaki satır (boşsa kampın yeri ve gecesi).
var card_place := ""
var card_note := ""
## Oyun içi HUD (GameplayHud): kitabın HARİTA ve GÖREVLER sayfalarının verisi.
var hud: Node

var _menu: GameMenu


func _ready() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS


## Kitabı açar ve dünyayı duraklatır (zaten açıksa bir şey yapmaz). take_thumb: ekranın şu anki karesi
## bir sonraki kaydın küçük resmi olsun mu (ana akış kareyi arayüzsüz kendisi çektiyse false verir).
func open(page: String = "genel", take_thumb: bool = true) -> void:
	if _menu != null:
		return
	if take_thumb and journey and DisplayServer.get_name() != "headless":
		journey.pending_thumb = get_viewport().get_texture().get_image()
	_pause(true)
	_menu = GameMenu.new()
	_menu.mode = "game"
	_menu.journey = journey
	_menu.settings = settings
	_menu.can_save = journey != null and save_note.is_empty()
	_menu.save_note = save_note
	_menu.card_place = card_place
	_menu.card_note = card_note
	_menu.hud = hud
	add_child(_menu)
	_menu.show_page(page)
	_menu.closed.connect(_on_closed)
	_menu.main_menu_requested.connect(func() -> void:
		close()
		main_menu_requested.emit())
	_menu.quit_requested.connect(func() -> void:
		close()
		quit_requested.emit())
	_menu.load_requested.connect(func(slot: int) -> void:
		close()
		load_requested.emit(slot))


## Kitabı kapatır ve dünyayı sürdürür (sinyal yaymaz).
func close() -> void:
	if _menu:
		_menu.queue_free()
		_menu = null
	_pause(false)


func is_open() -> bool:
	return _menu != null


## Açık kitap (yoksa null).
func get_menu() -> GameMenu:
	return _menu


func _on_closed() -> void:
	close()
	resumed.emit()


func _pause(on: bool) -> void:
	if is_inside_tree():
		get_tree().paused = on
