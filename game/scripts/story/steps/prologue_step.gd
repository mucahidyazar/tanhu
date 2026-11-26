class_name PrologueStep
extends RefCounted
## Önsöz'ün adım türü (E21, K110; docs/design/d3/e21-prologue-api.md §3): her tür bu sınıftan türeyen ayrı bir betiktir
## (scripts/story/steps/<tür>.gd) ve PrologueSteps.KINDS'e bir satırla kaydolur. Koşucu (PrologueDays) adımı açarken türün betiğini kurar,
## start() ile başlatır, her kare tick(delta) çağırır, HUD'un yönünü target() ile, oyuncunun E'sini interaction() ile sorar; adım biterken ya da
## koşucu dururken stop() çağırır (bir kez). Adım done() ile biter. Yüz Ç1'in ChildhoodStep'iyle aynı kalıptadır.
##   class_name LambsFind extends PrologueStep
##   func start() -> void: set_objective({"tr": "Kuzuları bul", "en": "Find the lambs"})
##   func tick(_delta: float) -> void: if found == 4: done()
## Söz kancası her türde aynıdır: adımın say listesi ([{line, at}]) adımın saatinde çalar, on_done listesi adım biterken.

## Koşucu (bağlam: dünya, oyuncu, kamera, kişiler, söz, saat, hava, ses).
## İşin süresince yerinde durma (walk_mods): hız sıfır değil çok küçüktür; HUD'un koşu eşiği yürüme hızıyla çarpılır, sıfırda duran
## oyuncu «koşuyor» sayılıp takati tükenirdi.
const HOLD_MODS := {"speed_k": 0.02, "can_run": false, "can_jump": false}

var days: PrologueDays
## Adımın verisi (sahne dosyasının steps satırı).
var step: Dictionary = {}
## Adımın evresi (boş: tek evreli).
var phase := ""
## Adımın saati (sn; koşucunun step_clock'u).
var clock := 0.0

var _done := false
var _stopped := false


func _init(p_days: PrologueDays = null, p_step: Dictionary = {}) -> void:
	days = p_days
	step = p_step


# --- Türün yüzü (alt sınıf yazar) ----------------------------------------------------------------------

## Adım başlar (amaç ve ipucu koşucu yazar: objective, hint).
func start() -> void:
	pass


## Her kare (perde geçişinde çağrılmaz).
func tick(_delta: float) -> void:
	pass


## HUD'un yönü (görevin o anki hedefi; yoksa Vector3.INF).
func target(_from: Vector3) -> Vector3:
	return Vector3.INF


## Oyuncunun E'si: {key: "E", label: "Dök", run: Callable} ya da boş (koşucu oyuncunun interaction_source'una verir).
func interaction() -> Dictionary:
	return {}


## Geliştirme --step bu adımın ötesinden açılırken: dünyanın adım sonrası hâli (kişiler, eşya, saat).
func preset() -> void:
	pass


## Temizlik (adım biterken ya da koşucu dururken; bir kez).
func cleanup() -> void:
	pass


## --autoplay botu bu adımı oynar (bot: scripts/dev/prologue_autoplay.gd). Yazılmazsa bot hedefe yürür.
func autoplay(bot: Node, _delta: float) -> void:
	var t := target(player().global_position if player() else Vector3.ZERO)
	if t != Vector3.INF and bot.has_method(&"go_to"):
		bot.call(&"go_to", t, false)
	if not interaction().is_empty() and bot.has_method(&"press_e"):
		bot.call(&"press_e")


## Verinin eksikleri (saf).
static func check(_step: Dictionary, _data: Dictionary) -> PackedStringArray:
	return PackedStringArray()


## Adımın andığı satır kimlikleri (doğrulama; say ve on_done'a ek olarak).
func line_keys() -> Array:
	return []


# --- Koşucunun bağı -------------------------------------------------------------------------------------

## Adımı bitirir: koşucu sıradaki adımı açar (stop önce çağrılır).
func done() -> void:
	if _done or days == null:
		return
	_done = true
	days.step_done(self)


func is_done() -> bool:
	return _done


## Koşucunun çağırdığı temizlik (bir kez).
func stop() -> void:
	if _stopped:
		return
	_stopped = true
	cleanup()


func is_stopped() -> bool:
	return _stopped


## Satırı söyler (tam kimlik: act0.milk.wake). Döner: sözün bitişine kalan süre (sn).
func say(line_id: String, ok: Callable = Callable(), optional := false) -> float:
	return days.say(line_id, ok, optional) if days else 0.0


## Satırları sırayla söyler. Döner: sonuncusunun bitişine kalan süre (sn).
func say_seq(ids: Array) -> float:
	var t := 0.0
	for id: Variant in ids:
		t = say(str(id))
	return t


## Adımın saatinde t saniyede fn (adım bitince kuyruk boşalır).
func at(t: float, fn: Callable) -> void:
	if days:
		days.at(t, fn)


func point(spec: Variant) -> Vector3:
	return days.point(spec) if days else Vector3.INF


func points(list: Variant) -> Array:
	return days.points(list) if days else []


## Oyuncu noktaya radius'tan yakın mı (düzlemde)?
func near(at_point: Vector3, radius: float) -> bool:
	return days.near(at_point, radius) if days else false


func person(id: String) -> PrologueCast.Person:
	return days.cast.person(id) if days and days.cast else null


func actor(id: String) -> CineActor:
	var p := person(id)
	return p.actor if p else null


func player() -> PlayerController:
	return days.player if days else null


func world() -> Node3D:
	return days.world if days else null


func places() -> PrologueWorld:
	return days.places if days else null


## Hız oyuncunun koşusunun altında (K105).
func pace(speed: float) -> float:
	return days.pace(speed) if days else speed


func set_objective(entry: Variant) -> void:
	if days:
		days.set_objective(days.text_of(entry))


func set_hint(entry: Variant) -> void:
	if days:
		days.set_hint(days.text_of(entry))


## Amaç satırının ayrıntısı (sayaç: «Kazık 4/12»).
func set_detail(text_value: String) -> void:
	if days:
		days.set_hint(text_value)


## Yolculuğa yazılacak işaret (günün başındaki kayıtta ve Önsöz'ün sonunda).
func flag(flag_name: String, value: Variant = true) -> void:
	if days:
		days.flag(flag_name, value)


## Görevin sonucu (koşucunun results'ı; sonraki adımlar okur).
func result(key: String, value: Variant) -> void:
	if days:
		days.results[key] = value


## Saati görünür akışla verilen saate getirir (hh:mm ya da gün dakikası), seconds saniyede.
func clock_to(when: Variant, seconds: float) -> void:
	if days:
		days.lapse_to(when, seconds)


func jump_clock(when: Variant) -> void:
	if days:
		days.set_time(when)


func fade(alpha: float, seconds: float) -> void:
	if days:
		await days.fade(alpha, seconds)


func weather(type: String, seconds: float = 6.0, params: Dictionary = {}) -> void:
	if days:
		days.set_weather(type, seconds, params)


func sfx(id: String, at_point: Variant = null, db: float = 0.0, pitch: float = 1.0) -> void:
	if days:
		days.sfx(id, at_point, db, pitch)


func bed(id: String, on: bool, db: float = 0.0) -> void:
	if days:
		days.bed(id, on, db)


func music(id: String) -> void:
	if days:
		days.music(id)


## Elde eşya (ember_pot, milk_yoke, lamb, wood, stone; "" bırakır).
func carry(item_id: String) -> Node3D:
	return days.carry(item_id) if days else null


func walk_mods(mods: Dictionary) -> void:
	if days:
		days.walk_mods(mods)


## Metin ({tr, en} ya da düz).
func text(entry: Variant) -> String:
	return days.text_of(entry) if days else str(entry)


## Düzlemde uzaklık.
static func flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
