extends TestCase
## Prototip fikstürleri (godot.md §8.2, K29; Yol Haritası proto-fixtures): karşılaştırıcı (tests/support/proto_fixture.gd) tolerans
## içindekini geçirir, dışındakini, eksik anahtarı, uzunluğu ve türü yakalar; run_cases her tutmayan durumu yazar (hata ekleme
## denemesi); tests/fixtures'taki her prototip fikstürünün üreticisi vardır, değişen kural (T(n), kopuz, Serbest Gez'in ayrı sayacı)
## fikstüre girmez; çalıştırıcının düzeni (tools/proto_fixtures.mjs, tools/proto_fixtures/<alan>.mjs, _shared.mjs) yerindedir.

const ProtoFixture := preload("res://tests/support/proto_fixture.gd")
## Bu maddenin fikstürleri: tam biçim ({meta, cases}) denetlenir.
const OWN := {"labour": "tools/proto_fixtures/labour.mjs", "progress": "tools/proto_fixtures/progression.mjs", "derive": "tools/proto_fixtures/progression.mjs"}
## Değişen kuralın işlevleri ve modülleri (tools/proto_fixtures/_shared.mjs CHANGED_RULES ile aynı).
const CHANGED_FNS := ["stepRate", "simulate", "etaMinutes", "remaining", "deriveSteps", "repairWork", "roamMoonAge"]
const CHANGED_MODULES := ["src/audio/instruments/dombra.js"]


## run_cases'in yazdığı başarısızlıkları toplayan sahte test.
class _Sink:
	extends RefCounted
	var failures: Array[String] = []

	func fail(message: String) -> void:
		failures.append(message)


func test_numbers_compare_within_tolerance() -> void:
	assert_true(ProtoFixture.compare(1.0 + 5e-10, 1.0, 1e-9).is_empty(), "1e-9 içinde eşit")
	assert_false(ProtoFixture.compare(1.0 + 2e-9, 1.0, 1e-9).is_empty(), "1e-9 dışı fark")
	assert_true(ProtoFixture.compare(3, 3.0, 0.0).is_empty(), "int ile float aynı sayı")
	assert_false(ProtoFixture.compare(3, 3.000001, 0.0).is_empty(), "Tam eşitlikte en küçük fark da düşer")
	assert_true(ProtoFixture.compare(INF, "inf", 1e-9).is_empty(), "«inf» sonsuzdur")
	assert_true(ProtoFixture.compare(-INF, "-inf", 1e-9).is_empty())
	assert_true(ProtoFixture.compare(NAN, "nan", 1e-9).is_empty(), "«nan» NaN'dır")
	assert_false(ProtoFixture.compare(1e300, "inf", 1e-9).is_empty(), "Büyük sayı sonsuz değildir")
	assert_false(ProtoFixture.compare(NAN, 1.0, 1e-9).is_empty(), "NaN sayıya eşit değildir")
	assert_false(ProtoFixture.compare("1", 1.0, 1e-9).is_empty(), "Yazı sayı değildir")
	assert_true(ProtoFixture.compare("inf", "inf", 0.0).is_empty(), "Yazı olarak «inf» de eşittir")
	assert_eq(ProtoFixture.decode_number("-inf"), -INF)
	assert_eq(ProtoFixture.decode_number("x"), "x")
	assert_eq(ProtoFixture.tolerance_of({"meta": {"kind": "sim"}}), 1e-6, "Birikimli benzetim 1e-6")
	assert_eq(ProtoFixture.tolerance_of({"meta": {"kind": "exact"}}), 0.0, "Tamsayı ve kimlik tam eşit")
	assert_eq(ProtoFixture.tolerance_of({"meta": {"kind": "math", "tol": 1e-7}}), 1e-7, "meta.tol türün önüne geçer")
	assert_eq(ProtoFixture.tolerance_of({}), 1e-9, "Varsayılan saf matematik")


func test_structures_compare_by_shape() -> void:
	var expected := {"a": [1.0, 2.0, {"b": "x"}], "c": true, "d": null}
	assert_true(ProtoFixture.compare({"a": [1, 2, {"b": "x", "extra": 9}], "c": true, "d": null, "z": 0}, expected, 1e-9).is_empty(), "Gerçeğin fazladan anahtarı serbest")
	var missing := ProtoFixture.compare({"a": [1, 2, {"b": "x"}], "c": true}, expected, 1e-9)
	assert_eq(missing.size(), 1)
	assert_true(missing[0].begins_with("$.d: anahtar yok"), missing[0] if not missing.is_empty() else "")
	var deep := ProtoFixture.compare({"a": [1, 2, {"b": "y"}], "c": true, "d": null}, expected, 1e-9)
	assert_true(deep.size() == 1 and deep[0].begins_with("$.a[2].b"), "Farkın yeri yazılır: %s" % [deep])
	assert_false(ProtoFixture.compare([1.0, 2.0], [1.0, 2.0, 3.0], 1e-9).is_empty(), "Uzunluk farkı")
	assert_true(ProtoFixture.compare(PackedFloat64Array([1.0, 2.5]), [1.0, 2.5], 1e-9).is_empty(), "Packed dizi dizi sayılır")
	assert_true(ProtoFixture.compare(&"day", "day", 0.0).is_empty(), "StringName ile String")
	assert_false(ProtoFixture.compare(1, true, 0.0).is_empty(), "Sayı bool değildir")
	assert_false(ProtoFixture.compare(null, 0.0, 0.0).is_empty(), "null sayı değildir")
	assert_false(ProtoFixture.compare(0.0, null, 0.0).is_empty(), "Sayı null değildir")
	assert_false(ProtoFixture.compare([], {}, 0.0).is_empty(), "Dizi sözlük değildir")


func test_run_cases_reports_each_broken_case() -> void:
	var fixture := {
		"meta": {"kind": "math", "tol": 1e-9},
		"cases": [
			{"id": "ok", "fn": "sq", "in": [3.0], "out": 9.0},
			{"id": "wide", "fn": "sq", "in": [3.0], "out": 9.1, "tol": 0.2},
			{"id": "bad", "fn": "sq", "in": [2.0], "out": 5.0},
			{"id": "orphan", "fn": "cube", "in": [2.0], "out": 8.0},
		],
	}
	var sink := _Sink.new()
	var n := ProtoFixture.run_cases(sink, fixture, {"sq": func(a: Array) -> Variant: return float(a[0]) * float(a[0])})
	assert_eq(n, 3, "İşleyicisi olan üç durum koşar")
	assert_eq(sink.failures.size(), 2, "Tutmayan durum ve işleyicisiz işlev: %s" % [sink.failures])
	assert_true(sink.failures.any(func(m: String) -> bool: return m.begins_with("bad ")), "Tutmayan durumun kimliği yazılır")
	assert_true(sink.failures.any(func(m: String) -> bool: return m.contains("cube") and m.contains("işleyicisi yok")))
	# Hata ekleme denemesi: gerçek fikstürde tek bir beklenen değer bozulursa run_cases onu yakalar.
	var labour := ProtoFixture.load_fixture("labour")
	assert_false(labour.is_empty(), "tests/fixtures/labour.json")
	if labour.is_empty():
		return
	var broken: Dictionary = labour.duplicate(true)
	var eff_cases: Array = (broken["cases"] as Array).filter(func(c: Dictionary) -> bool: return c["fn"] == "eff")
	(eff_cases[10] as Dictionary)["out"] = float(eff_cases[10]["out"]) + 1e-6
	var handlers := {"eff": func(a: Array) -> Variant: return Labour.eff(float(ProtoFixture.decode_number(a[0])))}
	var clean := _Sink.new()
	ProtoFixture.run_cases(clean, labour, handlers, PackedStringArray(["eff"]))
	assert_true(clean.failures.is_empty(), "Bozulmamış fikstür geçer: %s" % [clean.failures])
	var caught := _Sink.new()
	var count := ProtoFixture.run_cases(caught, broken, handlers, PackedStringArray(["eff"]))
	assert_eq(count, ProtoFixture.count_cases(labour, "eff"), "Yalnız istenen işlevin durumları")
	assert_eq(caught.failures.size(), 1, "1e-6'lık bozulma 1e-9 toleransla yakalanır: %s" % [caught.failures])


## tests/fixtures'taki JSON dosyalarının üreticisi: meta.tool, meta.source ya da doc'taki «tools/….mjs» yolu.
static func _generator_of(fixture: Dictionary) -> String:
	var meta: Dictionary = fixture.get("meta", {}) if fixture.get("meta") is Dictionary else {}
	for key: String in ["tool", "source"]:
		var v: Variant = meta.get(key)
		if v is String and (v as String).ends_with(".mjs"):
			return v
	var doc: Variant = fixture.get("doc", meta.get("doc"))
	if doc is String:
		var m := RegEx.create_from_string("tools/[A-Za-z0-9_/.-]+\\.mjs").search(doc)
		if m:
			return m.get_string()
	return ""


func test_every_fixture_has_a_generator_and_skips_changed_rules() -> void:
	var root := ProjectSettings.globalize_path("res://")
	var found := 0
	for file: String in DirAccess.get_files_at(ProtoFixture.DIR):
		if not file.ends_with(".json"):
			continue
		var name := file.get_basename()
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ProtoFixture.DIR.path_join(file)))
		assert_true(parsed is Dictionary, "%s ayrıştırılır" % file)
		if not parsed is Dictionary:
			continue
		var fx: Dictionary = parsed
		var gen := _generator_of(fx)
		if gen == "":
			# Prototipten üretilmeyen sınama verisi (ör. eski kayıt örneği): fikstür üreticisi istemez.
			assert_false(OWN.has(name), "%s'in üreticisi yazılmalı" % file)
			continue
		found += 1
		assert_true(FileAccess.file_exists(root.path_join(gen)), "%s: üreticisi %s var" % [file, gen])
		var text := JSON.stringify(fx)
		for module: String in CHANGED_MODULES:
			assert_false(text.contains(module), "%s: değişen kuralın modülü %s fikstüre girmez" % [file, module])
		for c: Variant in fx.get("cases", []):
			if c is Dictionary:
				assert_false(str((c as Dictionary).get("fn", "")) in CHANGED_FNS, "%s: %s değişen kuraldır, fikstüre girmez" % [file, c.get("id")])
	assert_true(found >= OWN.size(), "En az bu maddenin üç fikstürü (%d)" % found)
	for name: String in OWN:
		var fx := ProtoFixture.load_fixture(name)
		assert_false(fx.is_empty(), "%s.json var" % name)
		if fx.is_empty():
			continue
		var meta: Dictionary = fx["meta"]
		assert_eq(meta["tool"], OWN[name], "%s üreticisi" % name)
		assert_eq(int(meta["v"]), 1)
		assert_true(str(meta["kind"]) in ProtoFixture.TOL, "%s türü" % name)
		assert_eq(float(meta["tol"]), float(ProtoFixture.TOL[meta["kind"]]), "%s toleransı türünün toleransı" % name)
		assert_true(meta["proto_sha"] is Dictionary and not (meta["proto_sha"] as Dictionary).is_empty(), "%s prototip özeti" % name)
		var ids := {}
		for c: Dictionary in fx["cases"]:
			assert_false(ids.has(c["id"]), "%s: durum kimliği tekil (%s)" % [name, c["id"]])
			ids[c["id"]] = true
			assert_true(c.has("in") and c.has("out") and c.has("fn"), "%s: %s durumunda in, fn, out" % [name, c["id"]])
	# Saf matematik 1e-9 (emek, türetilen), tamsayı ve kimlik tam eşit (ilerlemenin senaryoları).
	assert_eq(float(ProtoFixture.load_fixture("labour")["meta"]["tol"]), 1e-9)
	assert_eq(float(ProtoFixture.load_fixture("derive")["meta"]["tol"]), 1e-9)
	assert_eq(float(ProtoFixture.load_fixture("progress")["meta"]["tol"]), 0.0)


func test_runner_layout() -> void:
	var tools := ProjectSettings.globalize_path("res://tools")
	assert_true(FileAccess.file_exists(tools.path_join("proto_fixtures.mjs")), "Çalıştırıcı tools/proto_fixtures.mjs")
	assert_true(FileAccess.file_exists(tools.path_join("proto_fixtures/_shared.mjs")), "Ortak yardımcı _shared.mjs")
	var domains := Array(DirAccess.get_files_at(tools.path_join("proto_fixtures"))).filter(
		func(f: String) -> bool: return f.ends_with(".mjs") and not f.begins_with("_"))
	for own: String in ["labour.mjs", "progression.mjs"]:
		assert_true(own in domains, "Alan dosyası %s" % own)
	var shared := FileAccess.get_file_as_string(tools.path_join("proto_fixtures/_shared.mjs"))
	for fn: String in CHANGED_FNS:
		assert_true(shared.contains("'%s'" % fn), "_shared.mjs bekçisi %s'i durdurur" % fn)
	for module: String in CHANGED_MODULES:
		assert_true(shared.contains("'%s'" % module), "_shared.mjs bekçisi %s'i durdurur" % module)
