class_name Journey
extends RefCounted
## O an süren yolculuk: karakter, oyuncunun kamptaki yeri, oynanan süre ve işaretler; kaydetme ve
## kayıttan geri yükleme köprüsü. Ana akış (main.gd) bir tane tutar; duraklatma menüsü ve kayıt
## paneli bununla kaydeder, Destan Kitabı işaretlerini buradan okur.
##
##   var journey := Journey.new(SaveSystem.new())
##   journey.set_flag(JourneyFlags.FIRESIDE)
##   journey.save_manual(3)            # 3. yuvaya, duraklatma menüsünün çektiği küçük resimle
##   var record := journey.saves.slot_info(3)
##   journey.apply_record(record)      # karakter, yer, süre ve işaretler geri gelir

## Kayıt v2 (godot.md §3.4): yolculuğun kipi, perdesi, dünyası ve tohumu kayda yazılır. Bloklar iki yerdedir: blocks kaydın blok
## sözlüğüdür ({ad: {v, ...}}; kayıttan geri kurulunca dolar, oturumu olmayan sistem de buraya yazabilir: RoamTime.store_into), live_blocks
## süren oturumun kaydıdır (Session.blocks; oturum kurulunca bağlanır). Kayıt ikisini birleştirir, oturumun bloğu geçer; oturum
## kapanınca son hâli blocks'a geçer (Session'ı yeniden kuran Serbest Gez saati sürdürür).

## Bir işaret ilk kez konunca yayılır.
signal flag_set(key: String)

var saves: SaveSystem
var profile: CharacterProfile
var flags: Dictionary = {}
var play_time := 0.0
## Kip ("roam": Serbest Gez, "story": hikâye), perde (0: perdesiz), dünyanın kimliği ve yolculuğun tohumu (SaveData).
var mode := SaveData.MODE_ROAM
var act := 0
var map := SaveData.DEFAULT_MAP
var journey_seed := 0
## Kaydın blokları: son yüklenen kaydınki, kapanan oturumun son hâli ya da oturumsuz sistemin yazdığı (kayıt bunları taşır).
var blocks: Dictionary = {}
## Süren oturumun blok kaydı (Session.setup bağlar, oturum kapanınca null).
var live_blocks: SaveBlocks
## Oyuncunun son bilinen yeri ve baktığı yön (ana akış oyun sırasında günceller).
var position := Vector3.ZERO
var yaw := 0.0
## Yer işaretleri (bkz. JourneyFlags.landmarks_from_world); kartlardaki yer adı bunlardan çıkar.
var landmarks: Dictionary = {}
## Duraklatma menüsü açılırken çekilen kare: bir sonraki kaydın küçük resmi olur.
var pending_thumb: Image
## Ozanın yanına varılan anın oynanan süresi (play_time; -1 = ozanın yanında değil). Ozanı dinlemek
## (JourneyFlags.BARD_LISTEN) kesintisiz BARD_LISTEN_SECONDS ister: ozandan ayrılan sayacı sıfırlar.
var _bard_since := -1.0
## Yeni yolculuğun ilk oto kaydı önceki yolculuğun küçük resmini taşımaz.
var _fresh := false


func _init(p_saves: SaveSystem = null, p_profile: CharacterProfile = null) -> void:
	saves = p_saves if p_saves else SaveSystem.new()
	profile = p_profile if p_profile else CharacterProfile.new()
	landmarks = JourneyFlags.build_landmarks(JourneyFlags.DEFAULT_FIRE, JourneyFlags.DEFAULT_STABLE, [], [])
	journey_seed = new_seed()


## Yeni bir yolculuk: işaretler ve süre sıfırlanır (kayıtlar diskte kalır); hikâye kipinde, perdesiz başlar, yeni tohum seçilir, kaydın
## blokları düşer.
func reset(p_profile: CharacterProfile = null) -> void:
	if p_profile:
		profile = p_profile.copy()
	flags = {}
	play_time = 0.0
	pending_thumb = null
	_bard_since = -1.0
	mode = SaveData.MODE_STORY
	act = 0
	map = ""
	journey_seed = new_seed()
	blocks = {}
	# Süren oturum (varsa) yeni yolculuğa eski bloklarını yazmasın.
	live_blocks = null
	_fresh = true


## Yolculuk tohumu (1..2³¹−1; rastgele, yeni yolculukta bir kez).
static func new_seed() -> int:
	var s := randi() & 0x7FFFFFFF
	return s if s != 0 else 1


## İşareti koyar; ilk kez konduysa true döner ve flag_set yayılır.
func set_flag(key: String, value: Variant = true) -> bool:
	var was := JourneyFlags.is_set(flags, key)
	flags[key] = value
	var now := JourneyFlags.is_set(flags, key)
	if now and not was:
		flag_set.emit(key)
		return true
	return false


func has_flag(key: String) -> bool:
	return JourneyFlags.is_set(flags, key)


## İşaretin değeri (yoksa fallback).
func get_flag(key: String, fallback: Variant = null) -> Variant:
	return flags.get(key, fallback)


## Dizi işaretine tekil eleman ekler (JourneyFlags.push); işaret ilk kez konunca flag_set yayılır. Döner: eklendi mi?
func push_flag(key: String, value: Variant) -> bool:
	var was := JourneyFlags.is_set(flags, key)
	var added := JourneyFlags.push(flags, key, value)
	if added and not was and JourneyFlags.is_set(flags, key):
		flag_set.emit(key)
	return added


## Sayı işaretini artırır (JourneyFlags.inc); işaret ilk kez konunca flag_set yayılır. Döner: yeni değer.
func inc_flag(key: String, n: float = 1.0) -> float:
	var was := JourneyFlags.is_set(flags, key)
	var next := JourneyFlags.inc(flags, key, n)
	if not was and JourneyFlags.is_set(flags, key):
		flag_set.emit(key)
	return next


## Oyuncunun yerini kaydeder ve oradaki yer işaretlerini koyar. Yeni konan işaretleri döndürür.
## Ana akış bunu oyun sürerken düzenli aralıkla (0,25 sn) çağırır; ozanı dinlemenin süresi iki çağrı
## arasındaki oynanan süre farkından sayılır (duraklatmada play_time akmaz, sayaç da durur).
func visit(p_position: Vector3, p_yaw: float) -> PackedStringArray:
	position = p_position
	yaw = p_yaw
	var xz := Vector2(p_position.x, p_position.z)
	var fresh := PackedStringArray()
	for key in JourneyFlags.flags_at(xz, landmarks):
		if set_flag(key):
			fresh.append(key)
	if _listened_to_bard(xz) and set_flag(JourneyFlags.BARD_LISTEN):
		fresh.append(JourneyFlags.BARD_LISTEN)
	return fresh


## Ozanın yanında kesintisiz BARD_LISTEN_SECONDS kalındı mı? Ozandan ayrılınca sayaç sıfırlanır.
func _listened_to_bard(xz: Vector2) -> bool:
	if has_flag(JourneyFlags.BARD_LISTEN):
		return false
	if not JourneyFlags.near_bard(xz, landmarks):
		_bard_since = -1.0
		return false
	if _bard_since < 0.0:
		_bard_since = play_time
	return play_time - _bard_since >= JourneyFlags.BARD_LISTEN_SECONDS


## Ozanın yanında kesintisiz geçen oynanan süre (sn; yanında değilse 0).
func bard_listen_time() -> float:
	return play_time - _bard_since if _bard_since >= 0.0 else 0.0


## Oyuncunun bulunduğu yerin kimliği (bkz. JourneyFlags.PLACE_NAMES).
func place_id() -> String:
	return JourneyFlags.place_at(Vector2(position.x, position.z), landmarks)


## Şu anki yolculuğun kaydı (v2): kip, perde, dünya, tohum ve bloklar (kaydın blokları, üstüne süren oturumunkiler). reason oto
## kaydın nedenidir (d2/core.md §6.2), elle kayıtta boş kalır.
func to_record(save_no: int, reason: StringName = &"") -> Dictionary:
	var record := SaveData.build(profile, position, yaw, flags, play_time, save_no, place_id())
	record["mode"] = mode if SaveData.MODES.has(mode) else SaveData.MODE_ROAM
	record["act"] = maxi(act, 0)
	record["map"] = map if not map.is_empty() else SaveData.DEFAULT_MAP
	record["seed"] = journey_seed
	record["blocks"] = collect_blocks()
	if reason != &"":
		record["reason"] = String(reason)
	return record


## Oyuncunun kendi yuvasına (1..SLOTS) kaydeder; küçük resim duraklatma anının karesidir.
func save_manual(slot: int) -> bool:
	if slot < 1 or slot > SaveSystem.SLOTS:
		return false
	return saves.write(slot, to_record(saves.next_save_no()), pending_thumb)


## Otomatik kayıt (0. yuva): ana menüye ya da masaüstüne dönerken ve oturumun oto kayıt nedenlerinde (Session.autosave_requested).
## Duraklatmanın karesi yoksa yuvanın son küçük resmi kalır (yeni yolculuğun ilk oto kaydı hariç).
func save_auto(reason: StringName = &"to_menu") -> bool:
	var ok := saves.write(SaveSystem.AUTO_SLOT, to_record(0, reason), pending_thumb, not _fresh)
	if ok:
		_fresh = false
	return ok


## Kayıttan yolculuğu geri kurar: karakter, yer, yön, süre, işaretler, kip, perde, dünya, tohum ve bloklar (sonraki oturum okur:
## Session.setup). Kayıt okunamıyorsa (bozuk blok dahil) false ve yolculuk değişmez.
func apply_record(record: Dictionary) -> bool:
	if not SaveData.is_record(record):
		return false
	var data := SaveData.parse(record)
	profile = data["profile"]
	flags = data["flags"]
	play_time = data["play_time"]
	if data["has_position"]:
		position = data["position"]
		yaw = data["yaw"]
	mode = data["mode"]
	act = data["act"]
	map = data["map"]
	journey_seed = data["seed"] if int(data["seed"]) != 0 else new_seed()
	blocks = data["blocks"]
	# Kaydın blokları geçer: süren oturum (varsa) kapanırken eski bloklarını bunların üstüne yazmasın; yeni oturum bunları okur.
	live_blocks = null
	pending_thumb = null
	_bard_since = -1.0
	_fresh = false
	return true


## Kayda girecek bloklar: kaydın blokları, üstüne süren oturumun kaydının yazdıkları (aynı adda oturumunki geçer).
func collect_blocks() -> Dictionary:
	var out := blocks.duplicate(true)
	if live_blocks != null:
		out.merge(live_blocks.collect(), true)
	return out


## Kaydın bir yeri var mı (yoksa oyuncu ateşin önünde belirir)?
static func record_has_position(record: Dictionary) -> bool:
	return bool(SaveData.parse(record)["has_position"])
