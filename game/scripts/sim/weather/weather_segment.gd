class_name WeatherSegment
extends RefCounted
## Planlayıcının tek türlü zaman dilimi (bölüm; weather.md §5.1): Segment = {type, t0, t1, src, front, seed}. t0 ve t1 hourAbs'tır
## (oyun saati). src sim (planlayıcı), build (cephe hazırlığı), clear (çözülme), story (hikâye kilidi). front hazırlıkta hedefi (to),
## çözülmede çıkılan türü (from) bilir. Fırtınanın parçaları aynı hücrenin [cell0, cell1]'ini taşır. g 1: aynı cephe grubunun sonraki
## bölümü gelecek (kayıt grubu bölmez). blend_s kilit sonrasının karışımıdır (NAN: kural). Kayıtta seed yazılmaz, t0'dan türer.

const SRC_SIM := 0
const SRC_BUILD := 1
const SRC_CLEAR := 2
const SRC_STORY := 3
const SRC_NAMES: Array[String] = ["sim", "build", "clear", "story"]

const FRONT_NONE := 0
const FRONT_BUILD := 1
const FRONT_CLEAR := 2

## Tür (WeatherData sıra numarası).
var type := 0
var t0 := 0.0
var t1 := 0.0
var src := SRC_SIM
var front_kind := FRONT_NONE
## Hazırlıkta hedef tür, çözülmede çıkılan tür (yoksa −1).
var front_type := -1
var seed := 0
var has_cell := false
var cell0 := 0.0
var cell1 := 0.0
var g := 0
var blend_s := NAN


static func make(p_type: int, p_t0: float, p_t1: float, p_src: int, p_front_kind: int = FRONT_NONE, p_front_type: int = -1) -> WeatherSegment:
	var s := WeatherSegment.new()
	s.type = p_type
	s.t0 = p_t0
	s.t1 = p_t1
	s.src = p_src
	s.front_kind = p_front_kind
	s.front_type = p_front_type
	return s


func type_id() -> StringName:
	return WeatherData.id_of(type)


func src_name() -> String:
	return SRC_NAMES[src]


## Kayıt biçimi (prototipin packSeg'i): {type, t0, t1, src, front?, cell?, g?, blendS?}.
func to_dict() -> Dictionary:
	var o := {"type": String(type_id()), "t0": t0, "t1": t1, "src": src_name()}
	if front_kind == FRONT_BUILD:
		o["front"] = {"kind": "build", "to": String(WeatherData.id_of(front_type))}
	elif front_kind == FRONT_CLEAR:
		o["front"] = {"kind": "clear", "from": String(WeatherData.id_of(front_type))}
	if has_cell:
		o["cell"] = [cell0, cell1]
	if g:
		o["g"] = 1
	if not is_nan(blend_s):
		o["blendS"] = blend_s
	return o


## Kayıttan (bozuksa null).
static func from_dict(o: Variant) -> WeatherSegment:
	if not o is Dictionary:
		return null
	var d: Dictionary = o
	var ti := WeatherData.index_of(str(d.get("type", "")))
	var a: Variant = d.get("t0")
	var b: Variant = d.get("t1")
	if ti < 0 or not (a is float or a is int) or not (b is float or b is int):
		return null
	var src_i := SRC_NAMES.find(str(d.get("src", "sim")))
	var s := make(ti, float(a), float(b), maxi(src_i, 0))
	var fr: Variant = d.get("front")
	if fr is Dictionary:
		var kind := str((fr as Dictionary).get("kind", ""))
		if kind == "build":
			s.front_kind = FRONT_BUILD
			s.front_type = WeatherData.index_of(str((fr as Dictionary).get("to", "")))
		elif kind == "clear":
			s.front_kind = FRONT_CLEAR
			s.front_type = WeatherData.index_of(str((fr as Dictionary).get("from", "")))
	var cell: Variant = d.get("cell")
	if cell is Array and (cell as Array).size() == 2:
		s.has_cell = true
		s.cell0 = float(cell[0])
		s.cell1 = float(cell[1])
	s.g = 1 if d.get("g", 0) else 0
	var bs: Variant = d.get("blendS")
	s.blend_s = float(bs) if bs is float or bs is int else NAN
	return s


## Kısa yazım (sınama ve günlük): tür|t0|t1|src.
func brief() -> String:
	return "%s|%s|%s|%s" % [type_id(), str(t0), str(t1), src_name()]
