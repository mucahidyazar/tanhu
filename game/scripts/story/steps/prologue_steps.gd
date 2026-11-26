class_name PrologueSteps
extends RefCounted
## Önsöz'ün adım türlerinin kaydı (E21, K110; docs/design/d3/e21-prologue-api.md §3): tür adı → betik (PrologueStep'ten türer). Her tür tek
## satırdır; betik ilk kullanımda yüklenir. Adımın verisinde "script" de verilebilir (kayıtta yoksa o okunur). Genel türler tek betikte
## (prologue_basic.gd, kind'a göre) toplanmıştır.
##   PrologueSteps.make("lambs_find", days, step)   # PrologueStep ya da null
##   PrologueSteps.has("sleep")                      # true

const BASIC := "res://scripts/story/steps/prologue_basic.gd"
const KINDS := {
	# Ö1: genel türler (prologue_basic.gd), «Süt» ve «Tipi».
	"say": BASIC,
	"reach": BASIC,
	"wait": BASIC,
	"interact": BASIC,
	"fade": BASIC,
	"clock": BASIC,
	"weather": BASIC,
	"cast": BASIC,
	"wake": BASIC,
	"sleep": BASIC,
	"night_end": BASIC,
	"cinema": BASIC,
	"place": BASIC,
	"sound": BASIC,
	"milk_carry": "res://scripts/story/steps/milk_carry.gd",
	"milk_churn": "res://scripts/story/steps/milk_churn.gd",
	"storm_walk": "res://scripts/story/steps/storm_walk.gd",
	"storm_hearth": "res://scripts/story/steps/storm_hearth.gd",
	# Ö2: «Kuzular» (lambs_*), «Şilde Gecesi» (feast_*), «Güreş» (wrestle_*), «Ocak» (hearth_*): her tür bir satır.
	"lambs_find": "res://scripts/story/steps/lambs_find.gd",
	"feast_walk": "res://scripts/story/steps/feast_walk.gd",
	"feast_roam": "res://scripts/story/steps/feast_roam.gd",
	"wrestle_ring": "res://scripts/story/steps/wrestle_ring.gd",
	"feast_home": "res://scripts/story/steps/feast_home.gd",
	"hearth_wood": "res://scripts/story/steps/hearth_wood.gd",
	"hearth_stone": "res://scripts/story/steps/hearth_stone.gd",
	"hearth_build": "res://scripts/story/steps/hearth_build.gd",
}

static var _scripts: Dictionary = {}


## Tür kayıtlı mı (ya da adımın kendi betiği var mı)?
static func has(kind: String, step: Dictionary = {}) -> bool:
	return KINDS.has(kind) or not str(step.get("script", "")).is_empty()


## Kayıtlı türler.
static func kinds() -> PackedStringArray:
	return PackedStringArray(KINDS.keys())


## Türün betiği (yüklenemezse null).
static func script_of(kind: String, step: Dictionary = {}) -> Script:
	var path := str(KINDS.get(kind, step.get("script", "")))
	if path.is_empty():
		return null
	if _scripts.has(path):
		return _scripts[path]
	if not ResourceLoader.exists(path):
		push_warning("[prologue] tür betiği yok: %s (%s)" % [kind, path])
		return null
	var s := load(path) as Script
	_scripts[path] = s
	return s


## Türün adımı (kurulmuş; başlatılmamış). Tür bilinmiyorsa null.
static func make(kind: String, days: PrologueDays, step: Dictionary) -> PrologueStep:
	var s := script_of(kind, step)
	if s == null:
		return null
	var handler: Variant = s.new()
	if not handler is PrologueStep:
		push_warning("[prologue] %s PrologueStep değil" % kind)
		return null
	var h := handler as PrologueStep
	h.days = days
	h.step = step
	return h


## Türün veri denetimi (betiğin static check'i; yoksa boş).
static func check(kind: String, step: Dictionary, data: Dictionary) -> PackedStringArray:
	var s := script_of(kind, step)
	if s == null:
		return PackedStringArray(["%s: tür betiği yüklenemedi (%s)" % [str(step.get("id", "")), kind]])
	var out: Variant = s.call(&"check", step, data)
	return out if out is PackedStringArray else PackedStringArray()


## Sahnenin verisinin eksikleri (saf; sınama): adımların türü, andığı satırlar ve işaretler.
static func validate(data: Dictionary, lines: Dictionary, markers: Dictionary = {}) -> PackedStringArray:
	var problems := PackedStringArray()
	for s: Variant in data.get("steps", []):
		if not s is Dictionary:
			problems.append("adım sözlük değil")
			continue
		var step: Dictionary = s
		var sid := str(step.get("id", ""))
		var kind := str(step.get("kind", ""))
		if not PrologueSteps.has(kind, step):
			problems.append("%s: bilinmeyen tür %s" % [sid, kind])
			continue
		problems.append_array(PrologueSteps.check(kind, step, data))
		for ref: String in PrologueSteps.line_refs(step):
			if not lines.has(ref):
				problems.append("%s: satır yok: %s" % [sid, ref])
		if not markers.is_empty():
			for m: String in PrologueSteps.marker_refs(step):
				if not markers.has(m):
					problems.append("%s: işaret yok: %s" % [sid, m])
	return problems


## Adımın andığı satırlar (saf): her derinlikte line, lines ve *_line alanları (act0. ile başlayanlar).
static func line_refs(v: Variant) -> PackedStringArray:
	var out := PackedStringArray()
	PrologueSteps._collect(v, out, "act0.")
	return out


## Adımın andığı işaretler (saf): at, target, face, to, path alanlarındaki dizgeler.
static func marker_refs(v: Variant) -> PackedStringArray:
	var out := PackedStringArray()
	PrologueSteps._collect_markers(v, out)
	return out


static func _collect(v: Variant, out: PackedStringArray, prefix: String) -> void:
	if v is Dictionary:
		for k: Variant in v:
			PrologueSteps._collect(v[k], out, prefix)
	elif v is Array:
		for e: Variant in v:
			PrologueSteps._collect(e, out, prefix)
	elif v is String and (v as String).begins_with(prefix) and (v as String).count(".") >= 2:
		out.append(v)


static func _collect_markers(v: Variant, out: PackedStringArray) -> void:
	if v is Dictionary:
		for k: Variant in v:
			var val: Variant = v[k]
			if str(k) in ["at", "target", "face", "to", "bed", "door"] and val is String and not (val as String).begins_with("act0."):
				out.append(val)
			elif str(k) in ["path", "via"] and val is Array:
				for p: Variant in val:
					if p is String:
						out.append(p)
			else:
				PrologueSteps._collect_markers(val, out)
	elif v is Array:
		for e: Variant in v:
			PrologueSteps._collect_markers(e, out)
