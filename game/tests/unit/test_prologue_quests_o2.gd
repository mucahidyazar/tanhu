extends TestCase
## Önsöz'ün son dört görevinin verisi (Ö2; K110; data/story/prologue_days/day2_lambs.json, day2_feast.json, day3_hearth.json): adımların sırası
## ve türleri (PrologueSteps.KINDS'te kayıtlı), andıkları sözler (docs/design/d3/e21-lines.json ya da koşucunun lines.json'u), andıkları
## işaretler (places.json), kuzuların düzeni (dört kuzu, biri donmuş), görevlerin bütün sözleri (lambs 12, feast 16, wrestle 11, hearth 12).

const FILES := {
	"lambs": "res://data/story/prologue_days/day2_lambs.json",
	"feast": "res://data/story/prologue_days/day2_feast.json",
	"hearth": "res://data/story/prologue_days/day3_hearth.json",
}
const LINES_DOC := "res://../docs/design/d3/e21-lines.json"
const RUNNER_LINES := "res://data/story/prologue_days/lines.json"
const PLACES := "res://data/story/prologue_days/places.json"
## Görevin sırası: [dosya, [adım türleri]].
const ORDER := {
	"lambs": ["wake", "reach", "lambs_find"],
	"feast": ["feast_walk", "feast_roam", "wrestle_ring", "feast_home", "night_end"],
	"hearth": ["hearth_wood", "hearth_stone", "hearth_build"],
}


func _json(path: String) -> Dictionary:
	var abs_path := ProjectSettings.globalize_path(path) if path.begins_with("res://") else path
	if path.begins_with("res://../"):
		abs_path = ProjectSettings.globalize_path("res://").path_join("..").path_join(path.substr(9)).simplify_path()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(abs_path)) if FileAccess.file_exists(abs_path) else null
	return parsed if parsed is Dictionary else {}


func _line_ids() -> Dictionary:
	var out := {}
	for path in [RUNNER_LINES, LINES_DOC]:
		var d := _json(path)
		for l: Variant in d.get("lines", []):
			out[str((l as Dictionary).get("id", ""))] = true
		if not out.is_empty():
			return out
	return out


func test_files_parse_and_steps_are_in_order() -> void:
	for key: String in FILES:
		var d := _json(FILES[key])
		assert_false(d.is_empty(), "%s okunur" % FILES[key])
		assert_eq(str(d.get("id", "")), key)
		var kinds: Array = []
		for s: Variant in d.get("steps", []):
			kinds.append(str((s as Dictionary).get("kind", "")))
		assert_eq(kinds, ORDER[key], "%s adımları" % key)
		assert_true((d.get("title", {}) as Dictionary).has("en"), "%s başlığı iki dilde" % key)


func test_my_kinds_are_registered() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/story/steps/prologue_steps.gd")
	for kind in ["lambs_find", "feast_walk", "feast_roam", "wrestle_ring", "feast_home", "hearth_wood", "hearth_stone", "hearth_build"]:
		assert_true(src.contains("\"%s\": \"res://scripts/story/steps/%s.gd\"" % [kind, kind]), "kayıt: %s" % kind)
		assert_true(ResourceLoader.exists("res://scripts/story/steps/%s.gd" % kind), "betik: %s" % kind)


func test_every_line_the_quests_use_exists() -> void:
	var ids := _line_ids()
	assert_false(ids.is_empty(), "sözler okunur")
	var used := {}
	for key: String in FILES:
		_collect(_json(FILES[key]), used)
	# Adım betiklerinin andığı sözler (line_keys) da dosyadadır.
	for kind in ["lambs_find", "feast_walk", "feast_roam", "wrestle_ring", "feast_home", "hearth_wood", "hearth_build"]:
		var src := FileAccess.get_file_as_string("res://scripts/story/steps/%s.gd" % kind)
		var re := RegEx.create_from_string("\"(act0\\.(?:lambs|feast|wrestle|hearth)\\.[a-z_0-9]+)\"")
		for m in re.search_all(src):
			used[m.get_string(1)] = true
	for id: String in used:
		assert_true(ids.has(id), "söz var: %s" % id)


func test_all_lines_of_the_four_quests_are_spoken_somewhere() -> void:
	var ids := _line_ids()
	var used := {}
	for key: String in FILES:
		_collect(_json(FILES[key]), used)
	for kind in ["lambs_find", "feast_walk", "feast_roam", "feast_watch", "wrestle_ring", "feast_home", "hearth_wood", "hearth_build"]:
		var src := FileAccess.get_file_as_string("res://scripts/story/steps/%s.gd" % kind)
		var re := RegEx.create_from_string("\"(act0\\.(?:lambs|feast|wrestle|hearth)\\.[a-z_0-9]+)\"")
		for m in re.search_all(src):
			used[m.get_string(1)] = true
	var counts := {"lambs": 0, "feast": 0, "wrestle": 0, "hearth": 0}
	for id: String in ids:
		var parts := id.split(".")
		if parts.size() < 3 or not counts.has(parts[1]):
			continue
		assert_true(used.has(id), "söz bir yerde söylenir: %s" % id)
		counts[parts[1]] = int(counts[parts[1]]) + 1
	assert_true(int(counts["lambs"]) >= 12 and int(counts["feast"]) >= 16 and int(counts["wrestle"]) >= 11 and int(counts["hearth"]) >= 12,
		"görevlerin sözleri: %s" % counts)


func test_markers_exist_in_places() -> void:
	var places := _json(PLACES)
	var markers: Dictionary = places.get("markers", {})
	# Koşucunun türettiği işaretler (yurtlardan, yoldan).
	for derived in ["gol_family_yurt", "gol_family_bed", "gol_family_door", "kunay_cradle", "kunay_yurt", "kunay_door"]:
		markers[derived] = true
	for key: String in FILES:
		var refs := {}
		_collect_markers(_json(FILES[key]), refs)
		for m: String in refs:
			assert_true(markers.has(m), "%s: işaret var: %s" % [key, m])


func test_lambs_four_and_one_frozen() -> void:
	var d := _json(FILES["lambs"])
	var find: Dictionary = {}
	for s: Variant in d.get("steps", []):
		if (s as Dictionary).get("kind") == "lambs_find":
			find = s
	var lambs: Array = find.get("lambs", [])
	assert_eq(lambs.size(), 4)
	var frozen := 0
	for l: Variant in lambs:
		if bool((l as Dictionary).get("frozen", false)):
			frozen += 1
	assert_eq(frozen, 1)
	assert_true(float((d.get("weather", {}) as Dictionary).get("snow", 0.0)) >= 0.99, "9 Nisan sabahı karlı")


func test_feast_night_has_no_moon_and_hearth_runs_to_evening() -> void:
	var feast := _json(FILES["feast"])
	var start := GameClock.parse_hhmm((feast.get("clock", {}) as Dictionary).get("start", ""))
	assert_true(start >= 20.0 * 60.0, "şilde gece")
	var hearth := _json(FILES["hearth"])
	assert_eq(str((hearth.get("clock", {}) as Dictionary).get("start", "")), "15:00", "Ocak 15:00'te başlar")


func _collect(v: Variant, out: Dictionary) -> void:
	if v is Dictionary:
		for k: Variant in v:
			_collect(v[k], out)
	elif v is Array:
		for e: Variant in v:
			_collect(e, out)
	elif v is String and (v as String).begins_with("act0.") and (v as String).count(".") >= 2:
		out[v] = true


func _collect_markers(v: Variant, out: Dictionary) -> void:
	if v is Dictionary:
		for k: Variant in v:
			var val: Variant = v[k]
			if str(k) in ["at", "target", "face", "to", "bed", "door", "home", "yurt", "fire", "gate", "edge", "stone_at", "bank", "hearth",
					"ring", "road"] and val is String and not (val as String).begins_with("act0.") and not (val as String).begins_with("Camp/"):
				out[val] = true
			elif str(k) in ["route", "path", "via"] and val is Array:
				for p: Variant in val:
					if p is String:
						out[p] = true
			else:
				_collect_markers(val, out)
	elif v is Array:
		for e: Variant in v:
			_collect_markers(e, out)
