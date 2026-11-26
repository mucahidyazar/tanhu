class_name ChildLook
extends RefCounted
## Çocuk denetleyicisinin gösterdiği kişi (K37, K89): Serbest Gez'in Çocuğu (child) ya da Çocukluk'un küçük Mete'si (mete_child). İkisi aynı denetleyiciyi kullanır, farkları görünüştür.
##
## Kişi StandIn'le çözülür: <id>.glb varsa kendi modeli (bugün ikisinin de var), meta.json'da stand_in varsa o. İkisi de yoksa çocuğun modeli FALLBACK_TINT ve FALLBACK_SCALE ile yer tutar:
## kişi hiç görünmez kalmaz, chibi yedeğine de düşmez (yer tutucu kuralı K89). Çarpan avatarın kendi malzemelerine gider: ateş başındaki Çocuk etkilenmez.

## Serbest Gez'in Çocuğu ve Çocukluk'un küçük Mete'si.
const PERSON_CHILD := "child"
const PERSON_METE := "mete_child"
## Yer tutucunun çarpanı (göl mavisine kırık: Çocuk'tan ayrılsın) ve ölçeği (beş yaş, yedi yaşın modeliyle).
const FALLBACK_TINT := Color(0.8, 0.9, 1.0)
const FALLBACK_SCALE := 0.92


## Kişinin görünüşü: StandIn.resolve; kendi modeli ve kaydı yoksa çocuğun modeli.
static func resolve(person_id: String, root: String = StandIn.ROOT) -> Dictionary:
	var look := StandIn.resolve(person_id, root)
	if person_id != PERSON_CHILD and str(look["model"]) == person_id and not StandIn.has_model(person_id, root):
		return {"id": person_id, "model": PERSON_CHILD, "tint": FALLBACK_TINT, "scale": FALLBACK_SCALE, "stand_in": true}
	return look


## Çarpanı ve ölçeği avatara uygular (model yüklendikten sonra).
static func apply(avatar: CharacterAvatar, look: Dictionary) -> void:
	if avatar:
		StandIn.apply(avatar, look.get("tint", Color.WHITE), float(look.get("scale", 1.0)))
