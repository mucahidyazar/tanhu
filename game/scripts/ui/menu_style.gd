class_name MenuStyle
extends RefCounted
## Tanhu'nun sıcak vurgu renkleri ve küçük ortak yardımcılar (menü butonları, oyun içi ipucu paneli).
##
## Tanhu 1'in paleti UIKit'tedir; burada Tanhu'ya özgü "üzerine gelince ısınan" vurgunun renkleri,
## arayüz seslerinin çağrısı ve animasyonu ağır karelerden koruyan yardımcı bulunur.

const THEME_PATH := "res://ui/menu_theme.tres"
## Kare süresi bundan kısaysa (saniye) oyun "akıcı" sayılır; bkz. play_when_settled().
const SETTLE_DELTA := 0.1
## Tanhu 1'den gelen sayfa ve uyarı sesleri (AudioManager'ın kendi hover / click / whoosh seslerine ek).
const EXTRA_SOUNDS := {
	&"page_turn": "res://assets/ui/sfx/page_turn.ogg",
	&"deny": "res://assets/ui/sfx/ui_deny.wav",
	&"toast": "res://assets/ui/sfx/ui_toast.wav",
}

# --- Palet ------------------------------------------------------------------
## Başlık ve yazıların krem rengi (#F2EAD8).
const CREAM := Color(0.949, 0.918, 0.847)
## Vurgulu (üzerine gelinmiş) butonda yazıya uygulanan sıcak altın ton (çarpan).
const HOT_TINT := Color(1.05, 0.93, 0.66)
## Gece mavisi mürekkep (fırça darbeleri).
const INK := Color(0.04, 0.062, 0.15, 0.8)
## Vurgulu fırça darbesinin sıcak, koyu kehribar mürekkebi.
const INK_WARM := Color(0.27, 0.17, 0.07, 0.86)
## Üzerine gelince beliren yumuşak altın parıltı.
const GLOW := Color(1.0, 0.8, 0.46, 0.62)
## Yazıların arkasındaki koyu mavi gölge.
const SHADOW := Color(0.015, 0.03, 0.09, 0.62)
## Vurgulu düğüm butonunun altın kenarı ve düğümleri.
const HOT_GOLD := Color(1.0, 0.82, 0.5)

## Bütün arayüz seslerini susturur (testler açar: çıkışta yarım kalan ses oynatıcısı kalmasın).
static var muted := false


## Arayüz sesi çalar (&"hover", &"click", &"whoosh" AudioManager'dan; &"page_turn", &"deny",
## &"toast" Tanhu 1'in sesleri). AudioManager autoload'u yoksa ya da dosya eksikse sessizce geçer.
static func play_ui(node: Node, kind: StringName, volume_db: float = -6.0) -> void:
	if muted or node == null or not node.is_inside_tree():
		return
	if EXTRA_SOUNDS.has(kind):
		_play_extra(node, kind, volume_db)
		return
	var audio := node.get_node_or_null(^"/root/AudioManager")
	if audio and audio.has_method(&"play_ui"):
		audio.play_ui(kind)


## Menülerin oyun koluyla da kullanılması için: A seçer (ui_accept), B geri çıkar (ui_cancel), Start oyun
## menüsünü açar / kapatır (pause). Godot'nun varsayılan ui_* eylemlerinde kol düğmesi yoktur. Tekrar
## çağrılması güvenlidir (aynı düğme iki kez eklenmez).
static func ensure_pad_actions() -> void:
	for pair in [[&"ui_accept", JOY_BUTTON_A], [&"ui_cancel", JOY_BUTTON_B], [&"pause", JOY_BUTTON_START]]:
		var action: StringName = pair[0]
		if not InputMap.has_action(action):
			continue
		var event := InputEventJoypadButton.new()
		event.button_index = pair[1]
		if not InputMap.action_has_event(action, event):
			InputMap.action_add_event(action, event)


## Tween'i kare süresi normale dönene kadar bekletir, sonra oynatır.
## Neden: dünya gibi ağır bir sahne aynı karede kurulursa sonraki karenin süresi saniyeler sürer;
## Tween o kareyi yaşarsa animasyon bir anda biter ve hiç görünmez. Normal durumda gecikme tek karedir.
static func play_when_settled(node: Node, tween: Tween, max_frames: int = 12) -> void:
	if tween == null or not tween.is_valid():
		return
	tween.pause()
	if node == null or not node.is_inside_tree():
		tween.play()
		return
	var tree := node.get_tree()
	for i in max_frames:
		await tree.process_frame
		if not tween.is_valid() or not is_instance_valid(node):
			return
		if node.get_process_delta_time() < SETTLE_DELTA:
			break
	if tween.is_valid():
		tween.play()


# Ek sesler tek seferlik bir oynatıcıyla, SFX veri yolunda çalar; oyun duraklatılmışken de duyulur.
static func _play_extra(node: Node, kind: StringName, volume_db: float) -> void:
	var stream := AudioUtil.load_stream(str(EXTRA_SOUNDS[kind]), false)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = AudioUtil.bus_or_master(&"SFX")
	player.volume_db = volume_db
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.finished.connect(player.queue_free)
	var host := node.get_node_or_null(^"/root/AudioManager")
	(host if host else node.get_tree().root).add_child(player)
	player.play()
