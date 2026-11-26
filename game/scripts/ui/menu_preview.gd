extends Node3D
## Geliştirme önizlemesi: açılış ekranını gerçek gece sahnesinin ve boyalı efektin üstünde gösterir.
## (scenes/ui/_preview/menu_preview.tscn) Oyunun parçası değildir; ekran görüntüsüyle görsel kontrol içindir.
## Gerçek oyun akışı için: tools/capture.sh /tmp/menu.png 360 --window=3200x1800
##
## Komut satırı seçenekleri ("--" sonrasına):
##   --focus=N        100. karede N. butonu vurgula (0-5 sütun, 6 = Serbest Gez)
##   --toast=Yazı     190. karede bildirim göster
##   --hud            menüyü gizle, oyun içi ipucu panelini göster
##   --painterly=0    boyalı efekti kapat
##   --strength=0.6   boyalı efektin şiddeti
##   --instant        giriş animasyonunu atla
##   --intro          Tanhu 1'in perdeli girişini oynat
##   --save-dir=/yol  kayıtları bu klasörden oku (yoksa kayıt yokmuş gibi)
## Örnek:
##   tools/capture.sh /tmp/menu.png 240 --scene=res://scenes/ui/_preview/menu_preview.tscn --focus=2

const CaptureTool := preload("res://scripts/dev/capture.gd")

@onready var _menu: MainMenu = $UI/MainMenu
@onready var _hud: GameHud = $UI/GameHud
@onready var _overlay: PainterlyOverlay = $PainterlyOverlay


func _ready() -> void:
	var args := CaptureTool.parse_args(OS.get_cmdline_user_args())
	var dir := str(args.get("save-dir", OS.get_temp_dir().path_join("tanhu3_preview_empty")))
	_menu.saves = SaveSystem.new(dir, false)
	_menu.refresh_saves()
	if args.has("painterly"):
		_overlay.enabled = str(args["painterly"]) != "0"
	if args.has("strength"):
		_overlay.strength = float(args["strength"])
	if args.has("hud"):
		_menu.hide_menu(false)
		_hud.show_hints()
		return
	if args.has("instant"):
		_menu.show_menu(false)
	elif args.has("intro"):
		_menu.hide_menu(false)
		_menu.play_intro()
	if args.has("focus"):
		_focus_later(int(args["focus"]))
	if args.has("toast"):
		_toast_later(str(args["toast"]))


func _focus_later(index: int) -> void:
	await _frames(100)
	var buttons: Array[KnotButton] = _menu.get_main_buttons()
	buttons.append(_menu.get_free_roam_button())
	var b := buttons[clampi(index, 0, buttons.size() - 1)]
	if not b.disabled:
		b.grab_focus()


func _toast_later(text: String) -> void:
	await _frames(190)
	_menu.show_toast(text)


# Süre yerine kare sayılır: ekran görüntüsü aracı da kare sayar, böylece zamanlama kesinleşir.
func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame
