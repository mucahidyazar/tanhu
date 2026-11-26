extends RefCounted
## Prototip fikstürlerini okuyan ve karşılaştıran yardımcı (godot.md §8.2, K29; Yol Haritası proto-fixtures).
##
## Fikstürler tools/proto_fixtures/<alan>.mjs ile üretilir (çalıştırıcı: node tools/proto_fixtures.mjs) ve tests/fixtures/<ad>.json'da
## durur. Önerilen biçim: {meta: {v, tool, proto, kind, tol, note}, constants, cases: [{id, fn, in, out, tol?}]}.
##   const ProtoFixture := preload("res://tests/support/proto_fixture.gd")
##   var fx := ProtoFixture.load_fixture("labour")
##   var n := ProtoFixture.run_cases(self, fx, {"eff": func(a: Array) -> Variant: return Labour.eff(a[0])})
## Karşılaştırma (compare):
##   sayı      |gerçek − beklenen| ≤ tol; int ile float aynı sayılır (Godot JSON'u sayıyı float okur)
##   "inf", "-inf", "nan"  sayı beklenen yerde (gerçek sayıysa) sonsuz ve NaN'dır (prototipin Infinity ve NaN'ı JSON'a böyle yazılır)
##   yazı      String ve StringName tam eşit; bool tam eşit; null yalnız null'a eşit
##   dizi      aynı uzunluk, sırayla (Packed*Array da dizi sayılır)
##   sözlük    beklenen her anahtar gerçekte olmalı ve eşit olmalı; gerçeğin fazladan anahtarı serbesttir (taşınan sınıf alan ekleyebilir)
## Toleranslar (TOL): saf matematik 1e-9, birikimli benzetim 1e-6, tamsayı ve kimlik tam eşit (0).

const DIR := "res://tests/fixtures"
const TOL := {"math": 1e-9, "sim": 1e-6, "exact": 0.0}
## Bir durum için en çok kaç fark yazılır (gerisi tek satırda sayılır).
const MAX_DIFFS := 8
const SPECIAL := ["inf", "-inf", "nan"]


## Fikstürün yolu (res://tests/fixtures/<ad>.json).
static func path_of(name: String) -> String:
	return DIR.path_join("%s.json" % name)


## Fikstür sözlüğü; dosya yoksa ya da bozuksa boş sözlük (testi çağıran denetler: boş fikstür «fikstür yok» diye düşmeli).
static func load_fixture(name: String) -> Dictionary:
	var path := path_of(name)
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## Fikstürün toleransı: meta.tol, yoksa meta.kind'ın toleransı, o da yoksa saf matematik.
static func tolerance_of(fixture: Dictionary) -> float:
	var meta: Dictionary = fixture.get("meta", {})
	var tol: Variant = meta.get("tol")
	if tol is float or tol is int:
		return float(tol)
	return float(TOL.get(str(meta.get("kind", "math")), 1e-9))


static func is_number(v: Variant) -> bool:
	return v is float or v is int


## "inf", "-inf", "nan" yazısını sayıya çevirir; başka değer olduğu gibi döner.
static func decode_number(v: Variant) -> Variant:
	if v is String:
		match v:
			"inf":
				return INF
			"-inf":
				return -INF
			"nan":
				return NAN
	return v


static func _is_packed(v: Variant) -> bool:
	return typeof(v) in [TYPE_PACKED_BYTE_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_FLOAT32_ARRAY,
		TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_VECTOR2_ARRAY, TYPE_PACKED_VECTOR3_ARRAY, TYPE_PACKED_COLOR_ARRAY]


static func _text(v: Variant) -> String:
	if v is float:
		return String.num(v, 12) if is_finite(v) else str(v)
	var s := JSON.stringify(v) if v is Dictionary or v is Array else str(v)
	return s if s.length() <= 120 else s.substr(0, 117) + "..."


## Gerçek ve beklenen değerin farkları (boşsa eşittir). path farkın yeridir ($, $.W, $.cases[3].out ...).
static func compare(actual: Variant, expected: Variant, tol: float, path: String = "$", out: PackedStringArray = PackedStringArray()) -> PackedStringArray:
	if out.size() >= MAX_DIFFS:
		return out
	var e: Variant = expected
	if e is String and (e as String) in SPECIAL and is_number(actual):
		e = decode_number(e)
	if is_number(e):
		if not is_number(actual):
			out.append("%s: sayı bekleniyordu (%s), %s geldi" % [path, _text(e), _text(actual)])
			return out
		var a := float(actual)
		var x := float(e)
		if is_nan(x):
			if not is_nan(a):
				out.append("%s: NaN bekleniyordu, %s geldi" % [path, _text(a)])
		elif is_inf(x) or is_inf(a):
			if a != x:
				out.append("%s: %s ≠ %s" % [path, _text(a), _text(x)])
		elif is_nan(a) or absf(a - x) > tol:
			out.append("%s: %s ≉ %s (fark %s, tolerans %s)" % [path, _text(a), _text(x), String.num(absf(a - x), 15), str(tol)])
		return out
	if e == null:
		if actual != null:
			out.append("%s: null bekleniyordu, %s geldi" % [path, _text(actual)])
		return out
	if e is bool:
		if not actual is bool or actual != e:
			out.append("%s: %s bekleniyordu, %s geldi" % [path, _text(e), _text(actual)])
		return out
	if e is String or e is StringName:
		if not (actual is String or actual is StringName) or String(actual) != String(e):
			out.append("%s: «%s» bekleniyordu, %s geldi" % [path, String(e), _text(actual)])
		return out
	if e is Array:
		var list: Variant = Array(actual) if _is_packed(actual) else actual
		if not list is Array:
			out.append("%s: dizi bekleniyordu, %s geldi" % [path, _text(actual)])
			return out
		var ea: Array = e
		var aa: Array = list
		if aa.size() != ea.size():
			out.append("%s: uzunluk %d bekleniyordu, %d geldi (%s)" % [path, ea.size(), aa.size(), _text(aa)])
			return out
		for i in ea.size():
			compare(aa[i], ea[i], tol, "%s[%d]" % [path, i], out)
		return out
	if e is Dictionary:
		if not actual is Dictionary:
			out.append("%s: sözlük bekleniyordu, %s geldi" % [path, _text(actual)])
			return out
		var ad: Dictionary = actual
		for key: Variant in (e as Dictionary):
			if not ad.has(key):
				out.append("%s.%s: anahtar yok" % [path, key])
				continue
			compare(ad[key], (e as Dictionary)[key], tol, "%s.%s" % [path, key], out)
		return out
	if actual != e:
		out.append("%s: %s bekleniyordu, %s geldi" % [path, _text(e), _text(actual)])
	return out


## Fikstürün durumlarını koşar: her durum handlers[fn].call(in) ile hesaplanır, beklenen out ile (durumun tol'u, yoksa fikstürün)
## karşılaştırılır; fark test.fail'e «<id> <yer>: …» diye yazılır. fns verilirse yalnız o işlevlerin durumları koşar.
## → koşulan durum sayısı. İşleyicisi olmayan işlev test.fail'dir (fikstüre yeni işlev girince sınama da genişlemeli).
static func run_cases(test: Object, fixture: Dictionary, handlers: Dictionary, fns: PackedStringArray = PackedStringArray()) -> int:
	var tol := tolerance_of(fixture)
	var count := 0
	var failed := 0
	for item: Variant in fixture.get("cases", []):
		if not item is Dictionary:
			continue
		var c: Dictionary = item
		var fn := str(c.get("fn", ""))
		if not fns.is_empty() and not fn in fns:
			continue
		if not handlers.has(fn):
			test.call("fail", "%s: «%s» işlevinin işleyicisi yok" % [c.get("id", "?"), fn])
			continue
		var actual: Variant = (handlers[fn] as Callable).call(c.get("in"))
		var case_tol: Variant = c.get("tol")
		var diffs := compare(actual, c.get("out"), float(case_tol) if is_number(case_tol) else tol)
		count += 1
		if diffs.is_empty():
			continue
		failed += 1
		if failed <= MAX_DIFFS:
			for d in diffs:
				test.call("fail", "%s %s" % [c.get("id", "?"), d])
	if failed > MAX_DIFFS:
		test.call("fail", "... ve %d durum daha tutmadı" % (failed - MAX_DIFFS))
	return count


## Fikstürde fn'i bu olan durumların sayısı.
static func count_cases(fixture: Dictionary, fn: String) -> int:
	var n := 0
	for item: Variant in fixture.get("cases", []):
		if item is Dictionary and str((item as Dictionary).get("fn", "")) == fn:
			n += 1
	return n
