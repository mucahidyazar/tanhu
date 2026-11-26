class_name NewGameFlow
extends RefCounted
## Yeni Oyun'un aşama sırası (K99): data/story/new_game.json'u okur, bugün oynatılabilen aşamaları sırayla verir. Saf: sahne kurmaz,
## main.gd her aşamayı oynatır, bitince next() ister. Dosyası olmayan ya da oynatıcısı henüz yazılmamış aşama (bugün I. Perde: act)
## sessizce atlanır; son kart (card) unless'teki aşama hazır olunca kendiliğinden düşer. Takvim atlamaları (K67) yolculuğa DAY_FLAG
## işaretiyle yazılır: jumps(aşama) aşamanın atlamalarıdır, sırayla ve yalnız ileri ({day_n, date, at}; at: sinemanın olay kimliği, atlama o
## olay çalınca yazılır, yoksa aşama bitince). advance(gün, yeni) takvimin tek kuralıdır: geri gitmez.
##   var flow := NewGameFlow.load_default()
##   flow.start("", [])                  # baştan; start("creator") oluşturucudan; only ile yalnız o aşamalar (sınama)
##   var stage := flow.next()           # {id, kind, ...}; bitince {}
##   NewGameFlow.jumps(stage)           # [{day_n: 1, at: "tie", ...}, {day_n: 1041, ...}]

const PATH := "res://data/story/new_game.json"
## Yolculuğun takvim günü (dayN; K67: 22 Eylül MÖ 228 = −5.600, I. Perde'nin Gün I'i = 1.041).
const DAY_FLAG := "takvim_gun"
## Bilinen türler ve main.gd'nin bugün oynatabildikleri.
const KINDS: Array[String] = ["prologue", "childhood", "cine", "creator", "scene", "act", "card"]
const PLAYABLE: Array[String] = ["prologue", "childhood", "cine", "creator", "scene", "card"]

var stages: Array[Dictionary] = []

var _plan: Array[Dictionary] = []
var _i := -1


static func load_default(path: String = PATH) -> NewGameFlow:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if not parsed is Dictionary:
		push_warning("[flow] Yeni Oyun'un sırası okunamadı: %s" % path)
	return from_data(parsed if parsed is Dictionary else {})


static func from_data(d: Dictionary) -> NewGameFlow:
	var flow := NewGameFlow.new()
	for s: Variant in d.get("stages", []):
		if s is Dictionary:
			flow.stages.append(s)
	return flow


## Aşamanın kimliği → tanımı (yoksa boş).
func stage(id: String) -> Dictionary:
	for s in stages:
		if str(s.get("id", "")) == id:
			return s
	return {}


## Aşama bugün oynatılabilir mi (saf değil: dosyaya bakar)? Dosyalı aşamanın dosyası olmalı ve boş olmamalı; kart, unless'teki aşama
## hazırsa gösterilmez.
func is_ready(s: Dictionary) -> bool:
	var kind := str(s.get("kind", ""))
	if not PLAYABLE.has(kind):
		return false
	if kind == "card":
		var unless := str(s.get("unless", ""))
		return unless.is_empty() or stage(unless).is_empty() or not is_ready(stage(unless))
	for key in ["path", "scene"]:
		if s.has(key) and not NewGameFlow.file_ok(str(s[key])):
			return false
	return true


## Dosya var ve boş değil mi?
static func file_ok(path: String) -> bool:
	return not path.is_empty() and FileAccess.file_exists(path) and not FileAccess.get_file_as_string(path).strip_edges().is_empty()


## from'dan (boşsa baştan) bugün oynatılacak aşamalar; only boş değilse yalnız onların kimlikleri.
func plan(from: String = "", only: PackedStringArray = PackedStringArray()) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var started := from.is_empty()
	for s in stages:
		var id := str(s.get("id", ""))
		if not started and id == from:
			started = true
		if not started or (not only.is_empty() and not only.has(id)):
			continue
		if is_ready(s):
			out.append(s)
	return out


## Akışı başlatır (next() ilk aşamayı verir).
func start(from: String = "", only: PackedStringArray = PackedStringArray()) -> void:
	_plan = plan(from, only)
	_i = -1


## Sıradaki aşama; bittiyse boş.
func next() -> Dictionary:
	_i += 1
	return _plan[_i] if _i < _plan.size() else {}


## Süren aşama (başlamadıysa ya da bittiyse boş).
func current() -> Dictionary:
	return _plan[_i] if _i >= 0 and _i < _plan.size() else {}


func current_id() -> String:
	return str(current().get("id", ""))


## Plandaki aşamaların kimlikleri (sınama ve günlük).
func plan_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for s in _plan:
		out.append(str(s.get("id", "")))
	return out


## Plan bu aşamayı içeriyor mu?
func plans(id: String) -> bool:
	return plan_ids().has(id)


## Aşamanın takvim atlamaları (saf): "jumps" listesi, yoksa tek "jump"; day_n'siz kayıt atlanır.
static func jumps(s: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var list: Array = s.get("jumps", []) if s.get("jumps") is Array else ([s["jump"]] if s.get("jump") is Dictionary else [])
	for j: Variant in list:
		if j is Dictionary and (j as Dictionary).has("day_n"):
			out.append(j)
	return out


## Takvimin yeni günü (saf; K67): yolculuk geri gitmez. current null ise (gün yok) yeni gün.
static func advance(current: Variant, day_n: int) -> int:
	if current == null:
		return day_n
	return maxi(int(current), day_n)


## Aşamanın metni ({tr, en}; dilde yoksa TR).
static func text(entry: Variant, lang: String = "tr") -> String:
	if entry is Dictionary:
		return str((entry as Dictionary).get(lang, (entry as Dictionary).get("tr", "")))
	return str(entry) if entry != null else ""
