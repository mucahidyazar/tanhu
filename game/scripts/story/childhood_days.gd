class_name ChildhoodDays
extends RefCounted
## Çocukluk'un günleri (E21, K110; story.md §5 «İki yeni gün», docs/design/d3/e21-childhood-api.md §1): data/story/childhood_days.json'un sırası.
## Her gün bir ChildhoodScene dosyasıdır; gün bitince (son adımı biter) main.gd sıradakini aynı Ordos dünyasında açar. Saf: sahne kurmaz.
## Dosyası olmayan ya da boş gün atlanır (Ç2'nin yer tutucusu henüz yoksa). card false olan gün (aynı akşam) kartsız, kısa kararmayla açılır.
##   var days := ChildhoodDays.load_default()
##   days.ids()                                   # ["day1_flock", "day1_bone", "day2_tally", "count"]
##   days.resolve("", "count")                    # {day: "count", step: "count"}: adımı içeren ilk gün
##   days.resolve("", "day1_flock:flock_lake")    # {day: "day1_flock", step: "flock_lake"}
##   days.next_of("day1_flock")                   # "day1_bone"

const PATH := "res://data/story/childhood_days.json"

var days: Array[Dictionary] = []


static func load_default(path: String = PATH) -> ChildhoodDays:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	return from_data(parsed if parsed is Dictionary else {})


static func from_data(d: Dictionary) -> ChildhoodDays:
	var out := ChildhoodDays.new()
	for e: Variant in d.get("days", []):
		if e is Dictionary and not str((e as Dictionary).get("id", "")).is_empty():
			out.days.append(e)
	return out


## Oynanabilir günlerin kimlikleri (dosyası olan), sırayla.
func ids() -> PackedStringArray:
	var out := PackedStringArray()
	for d in days:
		if is_playable(d):
			out.append(str(d["id"]))
	return out


## Bütün günlerin kimlikleri (dosyası olmasa da).
func all_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for d in days:
		out.append(str(d["id"]))
	return out


func entry(id: String) -> Dictionary:
	for d in days:
		if str(d["id"]) == id:
			return d
	return {}


func path_of(id: String) -> String:
	return str(entry(id).get("path", ""))


## Gün oynanabilir mi (dosya var, boş değil, adımı var)?
static func is_playable(d: Dictionary) -> bool:
	var path := str(d.get("path", ""))
	if not NewGameFlow.file_ok(path):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed is Dictionary and not ((parsed as Dictionary).get("steps", []) as Array).is_empty()


## Sıradaki oynanabilir gün (yoksa boş).
func next_of(id: String) -> String:
	var found := false
	for d in days:
		if found and is_playable(d):
			return str(d["id"])
		if str(d["id"]) == id:
			found = true
	return ""


## Günün verisi (ChildhoodScene.load_data; yoksa boş).
func data_of(id: String) -> Dictionary:
	var path := path_of(id)
	return ChildhoodScene.load_data(path) if not path.is_empty() else {}


## Gün kartsız mı açılır (aynı akşamın devamı)?
func carded(id: String) -> bool:
	return bool(entry(id).get("card", true))


## Başlangıç: gün ve adım. day_arg verilmişse o gün (adım step_arg ya da baştan); step_arg «gün:adım» olabilir; yalnız adım verilmişse onu
## içeren ilk gün; ikisi de boşsa ilk oynanabilir gün. Bilinmeyen adım: o gün baştan (ChildhoodScene.begin bilinmeyen adımı baştan açar).
func resolve(day_arg: String, step_arg: String) -> Dictionary:
	var day := day_arg
	var step := step_arg
	if step.contains(":"):
		var parts := step.split(":", false, 1)
		if parts.size() == 2:
			day = parts[0]
			step = parts[1]
	var playable := ids()
	if not day.is_empty() and playable.has(day):
		return {"day": day, "step": step}
	if not step.is_empty():
		for id in playable:
			if ChildhoodScene.step_ids(data_of(id)).has(step):
				return {"day": id, "step": step}
	return {"day": playable[0] if not playable.is_empty() else "", "step": step}
