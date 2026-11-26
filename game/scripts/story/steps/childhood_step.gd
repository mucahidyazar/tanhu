class_name ChildhoodStep
extends RefCounted
## Çocukluk'un adım türü (E21, K110; docs/design/d3/e21-childhood-api.md §2): ChildhoodScene'in bugünkü dört türü (reach, race, hunt, count)
## sahnenin içindedir; yeni türler bu sınıftan türeyen ayrı betiklerdir (scripts/story/steps/<tür>.gd) ve ChildhoodSteps.KINDS'e bir satırla
## kaydolur. Sahne adımı açarken türün betiğini kurar (ChildhoodSteps.make), start() ile başlatır, her kare tick(delta) çağırır, HUD'un yönünü
## target() ile sorar, adım biterken ya da sahne dururken stop() çağırır (bir kez). Adım done() ile biter (sahne sıradakini açar).
##   class_name FlockGate extends ChildhoodStep
##   func start() -> void: site().set_gate_open(true)
##   func tick(_delta: float) -> void: if site().herd.released_total() >= 40: done()
## Evre (phase) sahnenin current_phase()'idir (sınama, bot, HUD). Söz kancası her türde aynıdır: adımın say listesi sahnenin saatinde çalar.

## Sahne (bağlam: dünya, oyuncu, kamera, kişiler, söz, saat).
var scene: ChildhoodScene
## Adımın verisi (günün dosyasındaki steps satırı).
var step: Dictionary = {}
## Adımın evresi (boş: tek evreli).
var phase := ""
## Adımın saati (sn; sahnenin step_clock'u).
var clock := 0.0

var _done := false
var _stopped := false


func _init(p_scene: ChildhoodScene = null, p_step: Dictionary = {}) -> void:
	scene = p_scene
	step = p_step


# --- Türün yüzü (alt sınıf yazar) ----------------------------------------------------------------------

## Adım başlar (amaç ve ipucu sahne yazar: objective, hint).
func start() -> void:
	pass


## Her kare (görüntü donukken çağrılmaz).
func tick(_delta: float) -> void:
	pass


## HUD'un yönü (görevin o anki hedefi; yoksa Vector3.INF).
func target(_from: Vector3) -> Vector3:
	return Vector3.INF


## Geliştirme --step bu adımın ötesinden açılırken: dünyanın adım sonrası hâli (sürü, kişiler, kapı).
func preset() -> void:
	pass


## Temizlik (adım biterken ya da sahne dururken; bir kez).
func cleanup() -> void:
	pass


## --autoplay botu bu adımı oynar (bot: scripts/dev/childhood_autoplay.gd).
func autoplay(_bot: Node, _delta: float) -> void:
	pass


## Oyuncunun E'si bu adımda (PlayerController.interaction_source'un önünde): {key, label, run: Callable} ya da boş. Basılı tutma işi
## run'da başlar, adım is_holding() ile sürdürür.
func interaction() -> Dictionary:
	return {}


## E basılı mı (oyuncunun tuşu ya da botun basılı tutması: scene.auto_hold)?
func is_holding() -> bool:
	if scene and scene.auto_hold:
		return true
	return InputMap.has_action(&"accept") and Input.is_action_pressed(&"accept")


## Verinin eksikleri (saf; ChildhoodScene.validate çağırır).
static func check(_step: Dictionary, _data: Dictionary) -> PackedStringArray:
	return PackedStringArray()


## Adımın andığı satır anahtarları (doğrulama; bugünkü line, *_line alanlarına ek olarak).
func line_keys() -> Array:
	return []


# --- Sahnenin bağı ------------------------------------------------------------------------------------

## Adımı bitirir: sahne sıradaki adımı açar (stop önce çağrılır).
func done() -> void:
	if _done or scene == null:
		return
	_done = true
	scene.next_step()


func is_done() -> bool:
	return _done


## Sahnenin çağırdığı temizlik (bir kez).
func stop() -> void:
	if _stopped:
		return
	_stopped = true
	cleanup()


func is_stopped() -> bool:
	return _stopped


## Satırı söyler (anahtar; vo_prefix sahnenindir). Döner: sözün bitişine kalan süre (sn).
func say(key: String, ok: Callable = Callable(), optional := false) -> float:
	return scene.say(key, ok, optional) if scene else 0.0


## Adımın saatinde t saniyede fn (adım bitince kuyruk boşalır).
func at(t: float, fn: Callable) -> void:
	if scene:
		scene.at(t, fn)


func point(spec: Variant) -> Vector3:
	return scene.point(spec) if scene else Vector3.INF


func points(list: Variant) -> Array:
	return scene.points(list) if scene else []


## Oyuncu noktaya radius'tan yakın mı (düzlemde)?
func near(at_point: Vector3, radius: float) -> bool:
	return scene.near(at_point, radius) if scene else false


func mover(id: String) -> StoryMover:
	return scene.movers.get(id) as StoryMover if scene else null


func actor(id: String) -> CineActor:
	return scene.actors.get(id) as CineActor if scene else null


func player() -> PlayerController:
	return scene.player if scene else null


func site() -> ChildhoodSite:
	return scene.site if scene else null


func world() -> Node3D:
	return scene.world if scene else null


## Hız oyuncunun koşusunun altında (K105).
func pace(speed: float) -> float:
	return scene.pace(speed) if scene else speed


func set_objective(entry: Variant) -> void:
	if scene and scene.hud:
		scene.hud.set_objective(scene.text_of(entry))


func set_hint(entry: Variant) -> void:
	if scene and scene.hud:
		scene.hud.set_hint(scene.text_of(entry))


## Tepki sözü (verinin barks'ı).
func bark(event: String) -> void:
	if scene:
		scene.bark(event)


## Kişiye kütüphane klibi (iş olarak; kişinin yürüyüşü durur: hold). unpose ile bırakılır.
func pose(id: String, clip_key: String) -> bool:
	return scene.pose_actor(id, clip_key) if scene else false


func unpose(id: String) -> void:
	if scene:
		scene.unpose_actor(id)


## Kişinin yürütücüsünü sahnenin tikinden çıkarır (dışarıdan sürülür) ya da geri koyar.
func hold(id: String, on: bool) -> void:
	if scene:
		scene.hold_mover(id, on)


## Bitişte yolculuğa yazılacak işaret.
func flag(flag_name: String) -> void:
	if scene and not scene.extra_flags.has(flag_name):
		scene.extra_flags.append(flag_name)


## Saati görünür akışla verilen saate getirir (hh:mm ya da gün dakikası), seconds saniyede.
func clock_to(when: Variant, seconds: float) -> void:
	if scene:
		var minute := GameClock.parse_hhmm(when) if when is String else float(when)
		if minute >= 0.0:
			scene.lapse_to(minute, seconds)


## Görünür kara perde alfa'ya seconds saniyede (uyku; main.gd'nin perdesi). Döner: tween (yoksa null).
func fade(alpha: float, seconds: float) -> Tween:
	return scene.screen_fade_to(alpha, seconds) if scene else null


## Sesin yatakları ve tek seferlik sesler (günün atmos'u; yoksa null).
func atmos() -> ChildhoodAtmos:
	return scene.atmos if scene and is_instance_valid(scene.atmos) else null


## Tek seferlik ses (atmosfer belgesinin kimliği; dosya yoksa yer tutucu).
func sfx(id: String, at_point: Vector3 = Vector3.INF, db: float = 0.0) -> void:
	var a := atmos()
	if a:
		a.sfx(id, at_point, db)


## Metin ({tr, en} ya da düz).
func text(entry: Variant) -> String:
	return scene.text_of(entry) if scene else str(entry)


## Düzlemde uzaklık.
static func flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
