class_name SaveData
extends RefCounted
## Bir kaydın içeriği ve okunması (saf fonksiyonlar; dosya işi SaveSystem'dadır).
##
## Kayıt bir sözlüktür (JSON), sürüm 2 (godot.md §3.4; Yol Haritası save-v2):
##   version, game          biçimin sürümü (2) ve oyunun adı ("tanhu3")
##   save_no                oyuncunun kayıt sırası ("Kayıt #3"); otomatik kayıtta 0
##   saved_at, saved_unix   kaydın tarihi (yerel saat, ISO) ve sıralama için Unix zamanı
##   play_time              oynanan süre (saniye)
##   profile                karakter oluşturucudaki seçimler (CharacterProfile.to_dict)
##   position, yaw          oyuncunun yeri [x, y, z] ve baktığı yön (radyan)
##   place                  o yerin adı için kısa kimlik (bkz. JourneyFlags.PLACE_NAMES)
##   flags                  yolculuğun işaretleri (Destan Kitabı bunlarla açılır)
##   mode                   "roam" (Serbest Gez) ya da "story" (hikâye)
##   act                    perde (0: perdesiz; Önsöz, Çocukluk, Serbest Gez; 1–6 perdeler)
##   map                    dünyanın kimliği ("camp": ana kamp; iç haritalar data/maps/<id>/)
##   seed                   yolculuğun tohumu (yeni yolculukta bir kez seçilir; hava ve olay zarları ondan türer)
##   blocks                 sistemlerin blokları {ad: {v, ...}} (SaveBlocks; clock, weather, inventory, party ...)
##   reason                 (yalnız otomatik kayıtta) oto kaydın nedeni (d2/core.md §6.2: dawn, sleep, to_menu ...)
##
## v1 kaydı (2026-11-08'e dek, Serbest Gez) okunurken bir kez göçer (migrate): mode "roam", act 0, map "camp", bloklar boş (sistemler
## varsayılanına döner), tohum kaydın kendisinden türer (aynı kayıt hep aynı tohumu verir); işaretlerdeki eski kişi kimlikleri
## (Destan açılışları) LEGACY_PERSON_IDS ile çevrilir. Dosyadaki v1 kaydı değişmez: bir sonraki yazımda v2 olur.
## Bozuk ya da yarım kayıt, bozuk blok, bilinmeyen (daha yeni) sürüm ve başka oyunun kaydı boş yuva sayılır (is_record).

const VERSION := 2
const GAME_ID := "tanhu3"
## Kampın adı (kayıt kartlarında yerin önünde yazar).
const CAMP_NAME := "Gece Kampı"
const MODE_ROAM := "roam"
const MODE_STORY := "story"
const MODES: Array[String] = [MODE_ROAM, MODE_STORY]
## Ana kampın dünya kimliği (v1 kaydının dünyası).
const DEFAULT_MAP := "camp"
## Kişi kimliklerinin göçü (godot.md §3.4, E4.4; story.md §8.1): data/kisiler.json'un eski Türkçe kimlikleri İngilizceye geçti; ateş
## başındaki «mete» kaydı Ağabey'dir (K37).
const LEGACY_PERSON_IDS := {
	"ana": "mother", "baba": "father", "cocuk": "child", "ozan": "bard", "ak_at": "akbulut", "mete": "older_brother",
}
## Destan Kitabı'nın bölümleri (DestanKitabi.CHAPTERS): «bölüm/kimlik» biçimli işaretler de çevrilir.
const LEGACY_CHAPTERS: Array[String] = ["destan", "gok_yer", "kisiler", "taslar"]


## Kaydı kurar (v2; kip, perde, dünya, tohum ve bloklar varsayılanlarıyla: Journey.to_record doldurur). saved_at / saved_unix
## verilmezse şimdiki zaman yazılır.
static func build(profile: CharacterProfile, position: Vector3, yaw: float, flags: Dictionary,
		play_time: float, save_no: int, place: String, saved_at: String = "", saved_unix: float = -1.0) -> Dictionary:
	return {
		"version": VERSION,
		"game": GAME_ID,
		"save_no": save_no,
		"saved_at": saved_at if saved_at != "" else Time.get_datetime_string_from_system(),
		"saved_unix": saved_unix if saved_unix >= 0.0 else Time.get_unix_time_from_system(),
		"play_time": maxf(play_time, 0.0),
		"profile": (profile if profile else CharacterProfile.new()).to_dict(),
		"position": [position.x, position.y, position.z],
		"yaw": yaw,
		"place": place,
		"flags": flags.duplicate(true),
		"mode": MODE_ROAM,
		"act": 0,
		"map": DEFAULT_MAP,
		"seed": 0,
		"blocks": {},
	}


## Tanhu'nun okunabilir bir kaydı mı? Sürüm (1 ya da 2), karakter bilgisi ve oyunun adı olmalı; v2'de bloklar sağlam olmalı
## (SaveBlocks.check_blocks): bozuk blok boş yuva sayılır.
static func is_record(d: Variant) -> bool:
	if not d is Dictionary:
		return false
	var rec := d as Dictionary
	if not rec.has("version") or not rec.get("profile") is Dictionary or str(rec.get("game", GAME_ID)) != GAME_ID:
		return false
	var v := version_of(rec)
	if v < 1 or v > VERSION:
		return false
	if v >= 2 and not SaveBlocks.check_blocks(rec.get("blocks", {})).is_empty():
		return false
	return true


## Kaydın sürümü (okunamıyorsa 0).
static func version_of(rec: Dictionary) -> int:
	var v: Variant = rec.get("version")
	if v is int or (v is float and is_finite(v) and float(v) == floorf(v)):
		return int(v)
	return 0


## Kaydın güncel biçimi (kopya): v1 kaydı v2'ye göçer, v2 olduğu gibi kopyalanır. SaveSystem.slot_info okurken çağırır.
static func migrate(d: Dictionary) -> Dictionary:
	var rec := d.duplicate(true)
	if version_of(rec) < 2:
		rec = _migrate_v1(rec)
	return rec


## Kaydı okur; eksik ya da bozuk alanlar güvenli varsayılanlara düşer (v1 kaydı önce göçer).
## Döner: {profile: CharacterProfile, position: Vector3, yaw: float, has_position: bool, flags: Dictionary, play_time: float,
##         place: String, save_no: int, saved_at: String, version: int (kaydın kendi sürümü, göçten önce), mode: String, act: int,
##         map: String, seed: int, blocks: Dictionary, reason: String}
static func parse(d: Dictionary) -> Dictionary:
	var source_version := version_of(d)
	var rec := d if source_version >= 2 else _migrate_v1(d.duplicate(true))
	var profile_data: Variant = rec.get("profile", {})
	var flags: Variant = rec.get("flags", {})
	var pos: Variant = _vector3(rec.get("position", null))
	var mode := str(rec.get("mode", MODE_ROAM))
	var map_id: Variant = rec.get("map", DEFAULT_MAP)
	var blocks: Variant = rec.get("blocks", {})
	return {
		"profile": CharacterProfile.from_dict(profile_data if profile_data is Dictionary else {}),
		"position": pos if pos != null else Vector3.ZERO,
		"has_position": pos != null,
		"yaw": _number(rec.get("yaw", 0.0), 0.0),
		"flags": (flags as Dictionary).duplicate(true) if flags is Dictionary else {},
		"play_time": maxf(_number(rec.get("play_time", 0.0), 0.0), 0.0),
		"place": str(rec.get("place", "")),
		"save_no": int(_number(rec.get("save_no", 0), 0.0)),
		"saved_at": str(rec.get("saved_at", "")),
		"version": maxi(source_version, 1),
		"mode": mode if MODES.has(mode) else MODE_ROAM,
		"act": maxi(int(_number(rec.get("act", 0), 0.0)), 0),
		"map": str(map_id) if (map_id is String and not (map_id as String).is_empty()) else DEFAULT_MAP,
		"seed": int(_number(rec.get("seed", 0), 0.0)),
		"blocks": (blocks as Dictionary).duplicate(true) if blocks is Dictionary else {},
		"reason": str(rec.get("reason", "")),
	}


## İşaretlerdeki eski kişi kimlikleri (godot.md §3.4): adı eski kimlik olan işaret («ana»), «bölüm/kimlik» işareti («kisiler/ozan»)
## ve dizi değerindeki kimlik («met»: ["cocuk"]) çevrilir. Öteki işaretlere dokunulmaz («cocuk_gezinti», «ozan_dinledi» yer ve olay
## işaretidir). Yeni kimlik zaten konmuşsa eskisi onu ezmez. Döner: yeni sözlük.
static func migrate_person_ids(flags: Dictionary) -> Dictionary:
	var out := {}
	var legacy: Array = []
	for key: Variant in flags:
		var k := str(key)
		var nk := _person_key(k)
		var value: Variant = flags[key]
		if value is Array:
			value = _person_list(value)
		if nk != k:
			legacy.append([nk, value])
		else:
			out[k] = value
	for pair: Array in legacy:
		if not Cond.truthy(out.get(pair[0])):
			out[pair[0]] = pair[1]
	return out


## Kararlı 32 bitlik özet (FNV-1a, UTF-8): Godot sürümünden bağımsızdır (String.hash değildir). Döner: 0..2³²−1.
static func hash32(text: String) -> int:
	var h := 2166136261
	for b in text.to_utf8_buffer():
		h = h ^ b
		h = (h * 16777619) & 0xFFFFFFFF
	return h


## v1 kaydının tohumu: kaydın tarihi, zamanı ve sırasından (aynı kayıt hep aynı tohumu verir). Döner: 1..2³¹−1.
static func legacy_seed(rec: Dictionary) -> int:
	var key := "%s|%d|%d" % [str(rec.get("saved_at", "")), int(_number(rec.get("saved_unix", 0), 0.0)), int(_number(rec.get("save_no", 0), 0.0))]
	var s := hash32(key) & 0x7FFFFFFF
	return s if s != 0 else 1


## Kayıtları yeniden eskiye sıralamak için anahtar (büyük olan daha yeni).
static func order_key(info: Dictionary) -> String:
	return "%018.3f|%s" % [maxf(_number(info.get("saved_unix", 0.0), 0.0), 0.0), str(info.get("saved_at", ""))]


## "Ocak başı #3"; otomatik kayıt: "Otomatik kayıt · Ocak başı".
static func slot_title(info: Dictionary, slot: int) -> String:
	var place := JourneyFlags.place_name(str(info.get("place", "")))
	if slot == SaveSystem.AUTO_SLOT:
		return "Otomatik kayıt · %s" % place
	return "%s #%d" % [place, int(_number(info.get("save_no", slot), float(slot)))]


## Kartın yer satırı: "Gece Kampı · Ocak başı".
static func place_line(info: Dictionary) -> String:
	return "%s · %s" % [CAMP_NAME, JourneyFlags.place_name(str(info.get("place", "")))]


## Oynanan süre: "0 sa 05 dk" (Tanhu 1'in biçimi).
static func format_play_time(sec: float) -> String:
	var m := int(maxf(sec, 0.0) / 60.0)
	return "%d sa %02d dk" % [int(m / 60.0), m % 60]


## Kısa süre: "12 dk", bir saatten uzunsa "1 sa 5 dk" (en az 1 dk).
static func format_duration(sec: float) -> String:
	var m := int(maxf(sec, 0.0) / 60.0)
	if m >= 60:
		return "%d sa %d dk" % [int(m / 60.0), m % 60]
	return "%d dk" % maxi(m, 1)


## "2026-10-26T06:53:12" → "26.10.2026  06:53".
static func format_date(iso: String) -> String:
	if iso.length() < 16:
		return iso
	return "%s.%s.%s  %s" % [iso.substr(8, 2), iso.substr(5, 2), iso.substr(0, 4), iso.substr(11, 5)]


## Kartın alt satırı: "0 sa 05 dk  ·  26.10.2026  06:53".
static func meta_line(info: Dictionary) -> String:
	return "%s  ·  %s" % [format_play_time(_number(info.get("play_time", 0.0), 0.0)), format_date(str(info.get("saved_at", "")))]


# --- Göç ---------------------------------------------------------------------------------------------------

## v1 → v2 (yerinde): bugünkü v1 kaydı Serbest Gez'in ana kamp kaydıdır.
static func _migrate_v1(rec: Dictionary) -> Dictionary:
	rec["version"] = VERSION
	rec["mode"] = MODE_ROAM
	rec["act"] = 0
	rec["map"] = DEFAULT_MAP
	rec["seed"] = legacy_seed(rec)
	rec["blocks"] = {}
	var flags: Variant = rec.get("flags")
	if flags is Dictionary:
		rec["flags"] = migrate_person_ids(flags)
	rec["migrated_from"] = 1
	return rec


static func _person_key(k: String) -> String:
	if LEGACY_PERSON_IDS.has(k):
		return str(LEGACY_PERSON_IDS[k])
	var slash := k.find("/")
	if slash > 0:
		var chapter := k.substr(0, slash)
		var id := k.substr(slash + 1)
		if LEGACY_CHAPTERS.has(chapter) and LEGACY_PERSON_IDS.has(id):
			return "%s/%s" % [chapter, LEGACY_PERSON_IDS[id]]
	return k


static func _person_list(list: Array) -> Array:
	var changed := false
	for e: Variant in list:
		if (e is String or e is StringName) and LEGACY_PERSON_IDS.has(String(e)):
			changed = true
			break
	if not changed:
		return list
	var out: Array = []
	for e: Variant in list:
		var v: Variant = LEGACY_PERSON_IDS.get(String(e), e) if (e is String or e is StringName) else e
		if not out.has(v):
			out.append(v)
	return out


static func _number(v: Variant, fallback: float) -> float:
	if v is float or v is int:
		return float(v)
	return fallback


static func _vector3(v: Variant) -> Variant:
	if v is Array and (v as Array).size() == 3:
		var a := v as Array
		for x in a:
			if not (x is float or x is int):
				return null
		var p := Vector3(float(a[0]), float(a[1]), float(a[2]))
		if is_finite(p.x) and is_finite(p.y) and is_finite(p.z):
			return p
	return null
