class_name Cond
extends RefCounted
## Koşul dili (godot.md §3 «Görev ve diyalog»; architecture.md §3.14; prototipin src/game/cond.js'i): görev, diyalog, sinema ve Destan
## Kitabı verisindeki koşul dizgelerini önbellekli ağaçlara derler ve bir bağlamda (Cond.Ctx) sınar. Saftır: düğüm, ağaç, girdi ve
## duvar saati okumaz; derleme bir kez yapılır, sınama ayırma yapmaz.
##
## Dil (progression.md §4.1'in genişletilmişi):
##   expr  := and ('||' and)*          and := unary ('&&' unary)*
##   unary := '!' unary | '(' expr ')' | atom
##   atom  := name ('>=' | '<=' | '==' | '!=' | '>' | '<') value | name
##          | 'skill:'id | 'item:'ref[':'n] | 'quest:'id'.'('active' | 'done' | 'failed') | 'step:'qid'.'stepId
##          | 'slice:'name | 'phase:'evre | 'beat:'id'.'('wait' | 'open' | 'held' | 'done') | 'atlas:'id | 'tally:'kişi
##   name  := [A-Za-z_][A-Za-z0-9_]*('.'[A-Za-z0-9_]+)*      (true, false, null, undefined ad olamaz)
##   value := sayı | true | false | ad | 'metin' | "metin"
## Boş koşul ve "*" her zaman tutar (JourneyFlags'in kuralı; prototipte boş dizge hataydı, çağıran null'ı yorumluyordu).
## evre: dawn, morning, noon, golden, dusk, night. Başka evre ya da durum derlemede hatadır: yanlış yazılan ad sessizce hep yanlış
## dönmesin. slice: eski dört dilim, adı serbesttir.
##
## Bağlam (Cond.Ctx): get_value(yol) atomun yolunu çözer; yol atomun yazısıdır ('trust', 'ties.mene', 'quest:mq_ration.done',
## 'item:meal'; item:meal:2'nin eşiği yola girmez, burada kıyaslanır). Bilinmeyen ad bayrak sayılır: bağlam null döner, sayıyla
## kıyasta 0'dır. truthy(yol) yalın adın doğruluğudur (varsayılan Cond.truthy).
##
## Kıyas kuralları:
##   Sayıyla: yok 0, true 1, false 0, dizi uzunluğu; sayıya dönmeyen metin hiçbir sıra kıyasını tutmaz
##   Kelimeyle (opia_fate==covered): tam eşitlik; dizide üyelik, sözlük elemanda id (first_ten==uldin)
##   true/false ile ve yalın adda: doğruluk (Cond.truthy: boş dizi ve sözlük yanlış, "", "false", "0" yanlış)
##
##   Cond.holds("trust>=10 && !quest:mq_count.done", ctx)
##   Cond.error_of("hour>=")        # «cond: '>=' sonrası değer bekleniyordu, 4. karakterde: "hour>="»
##   Cond.atoms("a || b>2")         # ["a", "b"]

const _T_OP := 0
const _T_WORD := 1
const _T_STR := 2

## Derlenmiş ağacın düğüm türleri: [tür, ...].
const K_CONST := 0      ## [K_CONST, bool]
const K_TRUTHY := 1     ## [K_TRUTHY, yol]
const K_NOT := 2        ## [K_NOT, düğüm]
const K_AND := 3        ## [K_AND, a, b]
const K_OR := 4         ## [K_OR, a, b]
const K_ORDER := 5      ## [K_ORDER, yol, işleç (0 >=, 1 <=, 2 >, 3 <), sayı]
const K_NUM_EQ := 6     ## [K_NUM_EQ, yol, sayı, eşit mi istenir]
const K_BOOL_EQ := 7    ## [K_BOOL_EQ, yol, bool, eşit mi istenir]
const K_WORD_EQ := 8    ## [K_WORD_EQ, yol, kelime, eşit mi istenir]
const K_ITEM := 9       ## [K_ITEM, yol, en az adet]

const RESERVED: Array[String] = ["true", "false", "null", "undefined"]
const QUEST_STATES: Array[String] = ["active", "done", "failed"]
const BEAT_STATES: Array[String] = ["wait", "open", "held", "done"]
const PHASES: Array[String] = ["dawn", "morning", "noon", "golden", "dusk", "night"]
## Yalnız kimlik alan önekler.
const PLAIN_PREFIXES: Array[String] = ["skill", "slice", "atlas", "tally"]
const _ORDER_OPS := {">=": 0, "<=": 1, ">": 2, "<": 3}
const _OPS2: Array[String] = ["&&", "||", ">=", "<=", "==", "!="]
const _OPS1: Array[String] = [">", "<", "!", "(", ")"]
## Önbelleğin tavanı: veri koşulları sonludur; aşılırsa (kodla üretilen koşullar) önbellek boşalır.
const CACHE_MAX := 4096

## Koşul → derlenmiş ağaç (Array) ya da hata iletisi (String).
static var _cache: Dictionary = {}
## Hatası bir kez yazılan koşullar (holds).
static var _reported: Dictionary = {}
static var _empty_ctx: Ctx = Ctx.new()


## Koşulun bağlamı: atomun yolunu çözer. Alt sınıflar get_value'yu (ve isterse truthy'yi) yazar.
class Ctx:
	extends RefCounted

	## Atomun yolu → değer (yoksa null).
	func get_value(_path: String) -> Variant:
		return null

	## Yalın adın doğruluğu.
	func truthy(path: String) -> bool:
		return Cond.truthy(get_value(path))


## Sözlükle kurulan bağlam: yol sözlüğün anahtarıdır (bayraklar, sınamalar).
class DictCtx:
	extends Ctx

	var values: Dictionary = {}

	func _init(p_values: Dictionary = {}) -> void:
		values = p_values

	func get_value(path: String) -> Variant:
		return values.get(path)


# --- Dış yüz ----------------------------------------------------------------------------------------------

## Koşul bu bağlamda tutuyor mu? Okunamayan koşul yanlıştır ve hatası bir kez yazılır (push_error). ctx null ise boş bağlam.
static func holds(expr: String, ctx: Ctx = null) -> bool:
	var node: Variant = compile(expr)
	if node == null:
		if not _reported.has(expr):
			_reported[expr] = true
			push_error(error_of(expr))
		return false
	return eval_node(node, ctx if ctx != null else _empty_ctx)


## Koşulu derler (önbellekli). Döner: ağaç (Array) ya da okunamıyorsa null; hata yazılmaz (bkz. error_of).
static func compile(expr: String) -> Variant:
	var hit: Variant = _cache.get(expr)
	if hit == null:
		if _cache.size() >= CACHE_MAX:
			_cache.clear()
		hit = _parse(expr)
		_cache[expr] = hit
	return hit if hit is Array else null


## Koşul okunabiliyor mu? Döner: hata iletisi ya da "".
static func error_of(expr: String) -> String:
	compile(expr)
	var hit: Variant = _cache.get(expr)
	return hit if hit is String else ""


## Koşulun andığı yollar, yazıldıkları sırayla (tekil). Okunamayan koşulda boş.
static func atoms(expr: String) -> PackedStringArray:
	var out := PackedStringArray()
	var node: Variant = compile(expr)
	if node != null:
		_collect_atoms(node, out)
	return out


## Önbelleği ve yazılmış hataları boşaltır (sınamalar).
static func clear_cache() -> void:
	_cache.clear()
	_reported.clear()


## Derlenmiş ağacı bağlamda sınar.
static func eval_node(node: Array, ctx: Ctx) -> bool:
	match int(node[0]):
		K_CONST:
			return bool(node[1])
		K_TRUTHY:
			return ctx.truthy(node[1])
		K_NOT:
			return not eval_node(node[1], ctx)
		K_AND:
			return eval_node(node[1], ctx) and eval_node(node[2], ctx)
		K_OR:
			return eval_node(node[1], ctx) or eval_node(node[2], ctx)
		K_ORDER:
			var a := to_number(ctx.get_value(node[1]))
			var b: float = node[3]
			match int(node[2]):
				0:
					return a >= b
				1:
					return a <= b
				2:
					return a > b
				_:
					return a < b
		K_NUM_EQ:
			return (to_number(ctx.get_value(node[1])) == float(node[2])) == bool(node[3])
		K_BOOL_EQ:
			return (ctx.truthy(node[1]) == bool(node[2])) == bool(node[3])
		K_WORD_EQ:
			return matches_word(ctx.get_value(node[1]), node[2]) == bool(node[3])
		K_ITEM:
			return to_number(ctx.get_value(node[1])) >= float(node[2])
	return false


## Değerin doğruluğu (JourneyFlags.is_set de bunu kullanır): yok ve false yanlış; sayı 0'dan farklıysa doğru; metin "", "false" ve "0"
## dışında doğru; dizi ve sözlük boş değilse doğru; nesne geçerliyse doğru.
static func truthy(v: Variant) -> bool:
	match typeof(v):
		TYPE_NIL:
			return false
		TYPE_BOOL:
			return v
		TYPE_INT, TYPE_FLOAT:
			return float(v) != 0.0
		TYPE_STRING, TYPE_STRING_NAME:
			var s := String(v)
			return s != "" and s != "false" and s != "0"
		TYPE_ARRAY:
			return not (v as Array).is_empty()
		TYPE_DICTIONARY:
			return not (v as Dictionary).is_empty()
		TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_BYTE_ARRAY:
			return v.size() > 0
		TYPE_OBJECT:
			return is_instance_valid(v)
	return true


## Sayıya çevirme: yok 0, true 1, false 0, dizi uzunluğu, sayı metni sayısı; sayıya dönmeyen metin NAN (hiçbir sıra kıyasını tutmaz).
static func to_number(v: Variant) -> float:
	match typeof(v):
		TYPE_NIL:
			return 0.0
		TYPE_BOOL:
			return 1.0 if v else 0.0
		TYPE_INT, TYPE_FLOAT:
			return float(v)
		TYPE_STRING, TYPE_STRING_NAME:
			var s := String(v).strip_edges()
			if s.is_empty():
				return 0.0
			return s.to_float() if s.is_valid_float() else NAN
		TYPE_ARRAY:
			return float((v as Array).size())
		TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY:
			return float(v.size())
	return NAN


## Kelime kıyası: metinde tam eşitlik; dizide üyelik ya da sözlük elemanda id.
static func matches_word(v: Variant, word: String) -> bool:
	if v is Array or v is PackedStringArray:
		for e: Variant in v:
			if (e is String or e is StringName) and String(e) == word:
				return true
			if e is Dictionary:
				var id: Variant = (e as Dictionary).get("id")
				if (id is String or id is StringName) and String(id) == word:
					return true
		return false
	return (v is String or v is StringName) and String(v) == word


## Ad kuralı: [A-Za-z_][A-Za-z0-9_]*('.'[A-Za-z0-9_]+)*.
static func is_name(s: String) -> bool:
	if s.is_empty() or not _is_alpha(s[0]):
		return false
	var part_start := true
	for ch in s:
		if ch == ".":
			if part_start:
				return false
			part_start = true
			continue
		if not (_is_alpha(ch) or _is_digit(ch)):
			return false
		part_start = false
	return not part_start


## Kimlik kuralı: [A-Za-z0-9_]+.
static func is_id(s: String) -> bool:
	if s.is_empty():
		return false
	for ch in s:
		if not (_is_alpha(ch) or _is_digit(ch)):
			return false
	return true


# --- Derleme ----------------------------------------------------------------------------------------------

## Koşulu ayrıştırır. Döner: ağaç (Array) ya da hata iletisi (String).
static func _parse(expr: String) -> Variant:
	var trimmed := expr.strip_edges()
	if trimmed.is_empty() or trimmed == "*":
		return [K_CONST, true]
	var p := _Parser.new(expr)
	if not p.tokenize():
		return p.error
	var node: Variant = p.parse_or()
	if p.error.is_empty() and p.i < p.tokens.size():
		p.fail("beklenmeyen «%s»" % p.tokens[p.i][1], int(p.tokens[p.i][2]))
	if not p.error.is_empty():
		return p.error
	return node


static func _collect_atoms(node: Array, out: PackedStringArray) -> void:
	match int(node[0]):
		K_NOT:
			_collect_atoms(node[1], out)
		K_AND, K_OR:
			_collect_atoms(node[1], out)
			_collect_atoms(node[2], out)
		K_TRUTHY, K_ORDER, K_NUM_EQ, K_BOOL_EQ, K_WORD_EQ, K_ITEM:
			var path := String(node[1])
			if not out.has(path):
				out.append(path)


static func _is_alpha(ch: String) -> bool:
	return (ch >= "a" and ch <= "z") or (ch >= "A" and ch <= "Z") or ch == "_"


static func _is_digit(ch: String) -> bool:
	return ch >= "0" and ch <= "9"


static func _is_word_char(ch: String) -> bool:
	return _is_alpha(ch) or _is_digit(ch) or ch == "." or ch == ":" or ch == "-"


static func _is_number_text(s: String) -> bool:
	# -?\d+(\.\d+)?
	var body := s.substr(1) if s.begins_with("-") else s
	var parts := body.split(".")
	if parts.size() > 2:
		return false
	for part in parts:
		if not _is_digits(part):
			return false
	return true


static func _is_digits(s: String) -> bool:
	if s.is_empty():
		return false
	for ch in s:
		if not _is_digit(ch):
			return false
	return true


## Özyinelemeli iniş ayrıştırıcısı. Hata ilk yerde kalır; hatadan sonra dönen düğümler kullanılmaz.
class _Parser:
	extends RefCounted

	var src := ""
	var tokens: Array = []
	var i := 0
	var error := ""

	func _init(p_src: String) -> void:
		src = p_src

	func fail(message: String, at: int) -> void:
		if error.is_empty():
			error = "cond: %s, %d. karakterde: \"%s\"" % [message, at + 1, src]

	func tokenize() -> bool:
		var n := src.length()
		var k := 0
		while k < n:
			var ch := src[k]
			if ch == " " or ch == "\t" or ch == "\n" or ch == "\r":
				k += 1
				continue
			if k + 1 < n and Cond._OPS2.has(src.substr(k, 2)):
				tokens.append([Cond._T_OP, src.substr(k, 2), k])
				k += 2
				continue
			if Cond._OPS1.has(ch):
				tokens.append([Cond._T_OP, ch, k])
				k += 1
				continue
			if ch == "'" or ch == "\"":
				var end := src.find(ch, k + 1)
				if end < 0:
					fail("kapanmayan tırnak", k)
					return false
				tokens.append([Cond._T_STR, src.substr(k + 1, end - k - 1), k])
				k = end + 1
				continue
			if Cond._is_word_char(ch):
				var j := k
				while j < n and Cond._is_word_char(src[j]):
					j += 1
				tokens.append([Cond._T_WORD, src.substr(k, j - k), k])
				k = j
				continue
			fail("beklenmeyen karakter «%s»" % ch, k)
			return false
		return true

	func _at() -> int:
		return int(tokens[i][2]) if i < tokens.size() else src.length()

	func accept(text: String) -> bool:
		if i < tokens.size() and int(tokens[i][0]) == Cond._T_OP and str(tokens[i][1]) == text:
			i += 1
			return true
		return false

	func parse_or() -> Variant:
		var left: Variant = parse_and()
		while error.is_empty() and accept("||"):
			var right: Variant = parse_and()
			left = [Cond.K_OR, left, right]
		return left

	func parse_and() -> Variant:
		var left: Variant = parse_unary()
		while error.is_empty() and accept("&&"):
			var right: Variant = parse_unary()
			left = [Cond.K_AND, left, right]
		return left

	func parse_unary() -> Variant:
		if not error.is_empty():
			return null
		if accept("!"):
			return [Cond.K_NOT, parse_unary()]
		if accept("("):
			var inner: Variant = parse_or()
			if error.is_empty() and not accept(")"):
				fail("«)» eksik", _at())
			return inner
		return parse_atom()

	func parse_atom() -> Variant:
		if i >= tokens.size():
			fail("koşul erken bitti", src.length())
			return null
		var tok: Array = tokens[i]
		if int(tok[0]) != Cond._T_WORD:
			fail("beklenmeyen «%s»" % tok[1], int(tok[2]))
			return null
		i += 1
		var text := str(tok[1])
		var at := int(tok[2])
		if text.contains(":"):
			return prefixed(text, at)
		if not Cond.is_name(text) or Cond.RESERVED.has(text):
			fail("geçersiz ad «%s»" % text, at)
			return null
		if i < tokens.size() and int(tokens[i][0]) == Cond._T_OP:
			var op := str(tokens[i][1])
			if Cond._ORDER_OPS.has(op) or op == "==" or op == "!=":
				var op_at := int(tokens[i][2])
				i += 1
				return comparison(text, op, op_at)
		return [Cond.K_TRUTHY, text]

	func prefixed(text: String, at: int) -> Variant:
		var colon := text.find(":")
		var prefix := text.substr(0, colon)
		var rest := text.substr(colon + 1)
		if prefix == "item":
			return item_atom(rest, at)
		if not valid_prefixed(prefix, rest):
			fail("geçersiz atom «%s»" % text, at)
			return null
		return [Cond.K_TRUTHY, text]

	func valid_prefixed(prefix: String, rest: String) -> bool:
		if prefix == "phase":
			return Cond.PHASES.has(rest)
		if Cond.PLAIN_PREFIXES.has(prefix):
			return Cond.is_id(rest)
		var parts := rest.split(".")
		if parts.size() > 2 or not Cond.is_id(parts[0]):
			return false
		var tail := parts[1] if parts.size() > 1 else ""
		match prefix:
			"quest":
				return Cond.QUEST_STATES.has(tail)
			"beat":
				return Cond.BEAT_STATES.has(tail)
			"step":
				return Cond.is_id(tail)
		return false

	## 'item:'ref[':'n]: ref 'meal' ya da 'tag:wood'; n verilmezse 1.
	func item_atom(rest: String, at: int) -> Variant:
		var parts := rest.split(":")
		var n := 1
		var last := parts[parts.size() - 1]
		if Cond._is_digits(last):
			n = int(last)
			parts.remove_at(parts.size() - 1)
		var ref := ":".join(parts)
		var ok := n >= 1
		if ok:
			if parts.size() == 2:
				ok = parts[0] == "tag" and Cond.is_id(parts[1])
			elif parts.size() == 1:
				ok = parts[0] != "tag" and Cond.is_id(parts[0])
			else:
				ok = false
		if not ok:
			fail("geçersiz atom «item:%s»" % rest, at)
			return null
		return [Cond.K_ITEM, "item:" + ref, float(n)]

	func comparison(path: String, op: String, op_at: int) -> Variant:
		if i >= tokens.size() or int(tokens[i][0]) == Cond._T_OP:
			fail("«%s» sonrası değer bekleniyordu" % op, _at())
			return null
		var tok: Array = tokens[i]
		i += 1
		var rhs: Variant
		var text := str(tok[1])
		if int(tok[0]) == Cond._T_STR:
			rhs = text
		elif Cond._is_number_text(text):
			rhs = text.to_float()
		elif text == "true" or text == "false":
			rhs = text == "true"
		elif Cond.is_name(text) and not Cond.RESERVED.has(text):
			rhs = text
		else:
			fail("geçersiz değer «%s»" % text, int(tok[2]))
			return null
		if Cond._ORDER_OPS.has(op):
			if not (rhs is float):
				fail("«%s» sayı ister" % op, op_at)
				return null
			return [Cond.K_ORDER, path, int(Cond._ORDER_OPS[op]), rhs]
		var want := op == "=="
		if rhs is float:
			return [Cond.K_NUM_EQ, path, rhs, want]
		if rhs is bool:
			return [Cond.K_BOOL_EQ, path, rhs, want]
		return [Cond.K_WORD_EQ, path, str(rhs), want]
