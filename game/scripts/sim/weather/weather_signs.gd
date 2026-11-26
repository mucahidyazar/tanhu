class_name WeatherSigns
extends RefCounted
## Okunur işaretler (saf; weather.md §7, H6): oyunu değiştiren her hava en az 1 sa (Hikâye 1,5, Zor 0,75) önceden en az üç kanaldan, biri
## ses, okunur. Bekleyen işaretler plan kuyruğundan okunur; gök okuma (iron_stake) önümüzdeki altı saatin ilk cephesini ve dinişini
## söyler. Prototipin weather-core.js işaret bölümünden birebir.

## Bekleyen bir işaret: kimlik, kanal, cephe türü, kaç saat sonra, cephenin başı.
class Entry:
	extends RefCounted
	var id := ""
	var ch := ""
	var type := ""
	var in_h := 0.0
	var t0 := 0.0


## signs_for'un yüzü (yeniden kullanılır): list ilk n'i geçerlidir; front {type, in_h, t0} ya da boş; hud anahtar ya da "".
class State:
	extends RefCounted
	var list: Array[Entry] = []
	var n := 0
	var front_type := ""
	var front_in_h := 0.0
	var front_t0 := 0.0
	var has_front := false
	var hud := ""
	var clearing := false

	func entry(id: String) -> Entry:
		for i in n:
			if list[i].id == id:
				return list[i]
		return null

	func clear() -> void:
		n = 0
		has_front = false
		hud = ""
		clearing = false


static var _ids := PackedStringArray()
static var _rows: Array[Dictionary] = []
static var _line: Dictionary = {}


static func _tables() -> void:
	if not _ids.is_empty():
		return
	var signs: Dictionary = WeatherData.section("signs")
	for id: String in signs:
		_ids.append(id)
		_rows.append(signs[id])
	_line = WeatherData.section("sign_line")


## Bir bölümün işaret verdiği cephe türü (§7.2): ıslak ve fırtına türüne kurudan, griden ya da ağırlaşarak geçiş; sis; hazırlık bölümü
## kendi işaretini taşımaz (hedefinki çalar). Döner: tür ya da "".
static func front_kind(seg: WeatherSegment, before: WeatherSegment) -> String:
	if seg == null or seg.src == WeatherSegment.SRC_BUILD or seg.src == WeatherSegment.SRC_STORY:
		return ""
	if String(seg.type_id()) == "fog":
		return "" if before and String(before.type_id()) == "fog" else "fog"
	var g := WeatherData.group[seg.type]
	if g != WeatherData.GROUP_WET and g != WeatherData.GROUP_STORM:
		return ""
	if before == null:
		return String(seg.type_id())
	var gb := WeatherData.group[before.type]
	if (gb != WeatherData.GROUP_WET and gb != WeatherData.GROUP_STORM) or WeatherData.sev[seg.type] > WeatherData.sev[before.type]:
		return String(seg.type_id())
	return ""


## Bekleyen işaretler (§7.1–§7.2) out'a. diff_k Hikâye 1,5, Zor 0,75; act1 I. Perde'nin kemikleri; quiet_until varışın ilk 0,5 sa'i söz
## yok; prev geçen bölüm; lock_type ve lock_at «signs» kilidinin kendi saatinden kurduğu çizelge (lock_type boşsa yok).
static func signs_for(plan: Array[WeatherSegment], now_h: float, diff_k: float, act1: bool, quiet_until: float, prev: WeatherSegment,
		lock_type: String, lock_at: float, out: State) -> State:
	_tables()
	out.clear()
	if not lock_type.is_empty() and lock_at > now_h:
		_visit(out, lock_type, lock_at - now_h, lock_at, now_h, diff_k, act1, quiet_until)
	for i in plan.size():
		var seg := plan[i]
		var in_h := seg.t0 - now_h
		if in_h > 8.0 * diff_k:
			break
		var before: WeatherSegment = plan[i - 1] if i > 0 else prev
		if in_h <= 0.0:
			continue
		if seg.src == WeatherSegment.SRC_CLEAR and before and WeatherData.wet[before.type] and in_h <= 0.5:
			out.clearing = true
		var kind := front_kind(seg, before)
		if not kind.is_empty():
			_visit(out, kind, in_h, seg.t0, now_h, diff_k, act1, quiet_until)
	if out.hud.is_empty() and out.clearing:
		out.hud = "weather.sign.clearing"
	return out


static func _visit(out: State, kind: String, in_h: float, t0: float, now_h: float, diff_k: float, act1: bool, quiet_until: float) -> void:
	for s in _ids.size():
		var id := _ids[s]
		var row := _rows[s]
		if not kind in (row["fronts"] as Array) or (bool(row.get("act1", false)) and not act1):
			continue
		if kind == "fog" and id != "hud" and id != "npc" and id != "skill":
			continue
		if in_h > float(row["lead"]) * diff_k:
			continue
		if id == "npc" and now_h < quiet_until:
			continue
		_take(out, id, str(row["ch"]), kind, in_h, t0)
	if not out.has_front and in_h <= 2.0 * diff_k:
		out.has_front = true
		out.front_type = kind
		out.front_in_h = in_h
		out.front_t0 = t0
		var hud_lead := float((_rows[_ids.find("hud")] as Dictionary).get("lead", 1.0))
		if in_h <= hud_lead * diff_k:
			out.hud = "weather.sign.%s" % str(_line.get(kind, "rain"))


static func _take(out: State, id: String, ch: String, type: String, in_h: float, t0: float) -> void:
	if out.n >= out.list.size():
		out.list.append(Entry.new())
	var e := out.list[out.n]
	e.id = id
	e.ch = ch
	e.type = type
	e.in_h = in_h
	e.t0 = t0
	out.n += 1


## Gök okuma (§7.5, iron_stake): önümüzdeki saatlerin ilk cephesi ve dinişi → {kind: none|one|two, type, at, end}.
static func sky_read(plan: Array[WeatherSegment], now_h: float, hours: float = 6.0) -> Dictionary:
	var out := {"kind": "none", "type": "", "at": 0.0, "end": 0.0}
	for i in plan.size():
		var seg := plan[i]
		if seg.t0 > now_h + hours:
			break
		var kind := front_kind(seg, plan[i - 1] if i > 0 else null)
		if kind.is_empty() or seg.t0 <= now_h:
			continue
		out["kind"] = "one"
		out["type"] = kind
		out["at"] = seg.t0
		for j in range(i + 1, plan.size()):
			if plan[j].t0 > now_h + hours:
				break
			var g := WeatherData.group[plan[j].type]
			if g != WeatherData.GROUP_WET and g != WeatherData.GROUP_STORM:
				out["kind"] = "two"
				out["end"] = plan[j].t0
				break
		break
	return out
