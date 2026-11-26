class_name Weapons
extends RefCounted
## Yay ve ok tabloları (saf; data/combat/weapons.json, progression.md §7): ilk çağrıda okunur, önbelleklidir (godot.md §2 «Catalog» kalıbı).

const DATA_PATH := "res://data/combat/weapons.json"

static var _data: Dictionary = {}


## Yayın satırı (yoksa boş).
static func bow(id: String) -> Dictionary:
	return (Weapons._load().get("bows", {}) as Dictionary).get(id, {})


## Okun satırı (yoksa boş).
static func arrow(id: String) -> Dictionary:
	return (Weapons._load().get("arrows", {}) as Dictionary).get(id, {})


## Yayın oku (yoksa boş).
static func arrow_of(bow_id: String) -> Dictionary:
	return Weapons.arrow(str(Weapons.bow(bow_id).get("arrow", "")))


static func reset_cache() -> void:
	_data = {}


static func _load() -> Dictionary:
	if _data.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
		_data = parsed if parsed is Dictionary else {}
	return _data
