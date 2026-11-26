class_name ChildhoodSteps
extends RefCounted
## Çocukluk'un adım türlerinin kaydı (E21, K110; docs/design/d3/e21-childhood-api.md §2): tür adı → betik (ChildhoodStep'ten türer). Her tür
## tek satırdır; betik ilk kullanımda yüklenir. Adımın verisinde "script" de verilebilir (kayıtta yoksa o okunur). ChildhoodScene'in kendi dört
## türü (reach, race, hunt, count) burada değildir.
##   ChildhoodSteps.make("flock_drive", scene, step)   # ChildhoodStep ya da null
##   ChildhoodSteps.has("sleep")                         # true

const KINDS := {
	# Ç1: uyku ve günün kartı, «Çobanlık»
	"sleep": "res://scripts/story/steps/sleep_step.gd",
	"flock_wake": "res://scripts/story/steps/flock_wake.gd",
	"flock_gate": "res://scripts/story/steps/flock_gate.gd",
	"flock_drive": "res://scripts/story/steps/flock_drive.gd",
	"flock_lake": "res://scripts/story/steps/flock_lake.gd",
	"flock_stone": "res://scripts/story/steps/flock_stone.gd",
	"flock_noon": "res://scripts/story/steps/flock_noon.gd",
	"flock_count": "res://scripts/story/steps/flock_count.gd",
	"flock_lamb": "res://scripts/story/steps/flock_lamb.gd",
	"flock_home": "res://scripts/story/steps/flock_home.gd",
	# Ç2: «Ak Kemik» (bone_*), «Ebenin Çetelesi» (tally_*): her tür bir satır.
	"bone_call": "res://scripts/story/steps/bone_call.gd",
	"bone_play": "res://scripts/story/steps/bone_play.gd",
	"tally_errand": "res://scripts/story/steps/tally_errand_step.gd",
	"tally_dogs": "res://scripts/story/steps/tally_dogs_step.gd",
	"tally_visit": "res://scripts/story/steps/tally_visit.gd",
	"tally_news": "res://scripts/story/steps/tally_news.gd",
	"tally_home": "res://scripts/story/steps/tally_home.gd",
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
		push_warning("[steps] tür betiği yok: %s (%s)" % [kind, path])
		return null
	var s := load(path) as Script
	_scripts[path] = s
	return s


## Türün adımı (kurulmuş; başlatılmamış). Tür bilinmiyorsa null.
static func make(kind: String, scene: ChildhoodScene, step: Dictionary) -> ChildhoodStep:
	var s := script_of(kind, step)
	if s == null:
		return null
	var handler: Variant = s.new()
	if not handler is ChildhoodStep:
		push_warning("[steps] %s ChildhoodStep değil" % kind)
		return null
	var h := handler as ChildhoodStep
	h.scene = scene
	h.step = step
	return h


## Türün veri denetimi (betiğin static check'i; yoksa boş).
static func check(kind: String, step: Dictionary, data: Dictionary) -> PackedStringArray:
	var s := script_of(kind, step)
	if s == null:
		return PackedStringArray(["%s: tür betiği yüklenemedi (%s)" % [str(step.get("id", "")), kind]])
	var out: Variant = s.call(&"check", step, data)
	return out if out is PackedStringArray else PackedStringArray()
