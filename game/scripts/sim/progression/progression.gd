class_name Progression
extends RefCounted
## Mete'nin ilerlemesi (progression.md §1, §2, §4; act1.md §11): seviye ve XP, stat, beceri, beceri anahtarları (mods) ve kayıt
## bloğu (saf; godot.md §3 «İlerleme ve beceriler»). Prototipin game/progress.js'inin taşınmasıdır, altın değerlerle sınanır
## (tests/fixtures/progress.json); eksenler (Güven, Kut, Korku), antlar ve atlas kendi sistemlerindedir, koşullarda okunur.
##
## Kurallar: seviye 20, perde tavanı I 5 … VI 20 (atlamayı durdurur, XP'yi silmez); her seviye +1 stat, +1 beceri puanı; L20'den sonra
## her 1.800 XP +1 beceri puanı (en çok 3). Statlar 3'ten başlar, köken +1 (K104: Zırhlı Atlılar Arasında Bilek, Otağda Yetişen Söz,
## Yılkı Beyi Ayak ve Bağ +10; eski kimlikler yenisine göçer, current_origin), tek stat tavanı I'de 7. Her beceriyi bir insan öğretir:
## puan tek başına yetmez, usta (teach.when), seviye (tier tabanı) ve önkoşul birlikte aranır; usta istemeyen üç beceri lead_count, two_tongues ve tumen_call'dur. İnsan öldürmek hiçbir
## perdede XP vermez (award, data/progression/progression.json «xp.zero»).
## Beceri durumları: hidden (gizli ad, nameFlag yok), locked (perde ya da önkoşul), teachable (usta koşulu tutmuyor), ready (usta
## tamam: puan ve seviye varsa alınır; koşul sonradan bozulsa da hazır kalır), learned, lost_master (sentenced anında ustası tutmayan
## I. Perde becerisi; perde geçişinde temizlenir).
##   var p := Progression.new()
##   p.reset_player("origin_riders")        # Bilek 4
##   p.award("main", {"base": 110})          # I. Perde: 110 XP
##   p.set_flag("quest:sq_fever.done", true) # Hereka öğretir: hearth_craft hazır
##   p.learn("hearth_craft")
##   p.mods()                                # {"mealFull": 1.5, "cookQuality": 1, …}

signal xp_gained(amount: int, src: String, total: int)
signal level_up(new_level: int)
signal stat_spent(id: String)
signal skill_taught(id: String)
signal skill_learned(id: String)
## Durum değişti (HUD, kayıt).
signal changed

const DATA_PATH := "res://data/progression/progression.json"
const SKILLS_PATH := "res://data/progression/skills.json"
const ORIGINS_PATH := "res://data/character/origins.json"
## Kayıt v2'nin «progression» bloğunun sürümü (godot.md §3.4).
const BLOCK_VERSION := 1

static var _data: Dictionary = {}
static var _skills: Dictionary = {}
static var _origins: Dictionary = {}
## Eski köken kimliği → bugünkü kimlik (origins.json former_ids; K104: origin_load → origin_riders …).
static var _former_origins: Dictionary = {}

# Tablolar (verilmezse data/progression/ ve data/character/origins.json).
var xp_curve: Array = []
var level_caps: Array = []
var stat_caps: Array = []
var xp_scale: Array = []
## Köken kimliği → {stats: {stat: n}, bond}.
var origins: Dictionary = {}
var stat_ids: Array = []
var tier_levels: Array = []
## Beceri kimliği → satır, tablo sırasıyla.
var skill_rows: Dictionary = {}

## Koşul değerlendirici: Callable(ifade: String) → bool. Verilmezse ortak koşul dili (Cond, scripts/sim/story/cond.gd) ilerlemenin
## kendi yollarıyla (level, act, stat.<id>, skill:<id>), gerisini context'ten, o da yoksa flags'tan okur.
var cond: Callable
## Yol okuyucusu: Callable(yol: String) → değer (bayrak, eksen, görev, eşya). Verilmezse flags sözlüğü.
var context: Callable
## Bayraklar (context yokken koşulların kaynağı; set_flag yazar).
var flags: Dictionary = {}
## Derive'ın ilerlemenin bilmediği girdileri: Callable() → Dictionary (wounds, gear, buff, fullness, load, diff, bond, mount, env …).
var inputs: Callable

# Durum.
var act := 1
var level := 1
var xp := 0
## Köken kimliği; "" yok demektir (kayıtta null; stat puanı beklemede durur).
var origin := ""
var stats: Dictionary = {}
var stat_points := 0
var skill_points := 0
## Görev puanı verilen görevler (aynı kimlik iki kez puan vermez).
var points_granted: Array[String] = []
var overflow_points := 0
var respec_tokens := 0
## Öğrenilen beceriler, öğrenme sırasıyla: kimlik → {at: seviye, src: "point" | "free"}.
var learned: Dictionary = {}
## Usta koşulu tutmuş beceriler (ekleniş sırasıyla; değer true).
var teach_set: Dictionary = {}
## Ustası yiten beceriler (ekleniş sırasıyla; değer true).
var lost_master: Dictionary = {}
## Çubuk: barSlots yuva; öğrenilmiş beceri ya da sarf eşyası kimliği, null boş.
var bar: Array = []
## Bir kez sayılan XP kaynakları («kaynak:kimlik» → true) ve sınırlı kaynakların sayacı.
var xp_once: Dictionary = {}
var xp_counts: Dictionary = {}

var _checking := false
var _recheck := false
var _mod_acc: Dictionary = {}
var _mod_values: Dictionary = {}
var _mods_dirty := true
var _derived: Dictionary = {}
var _ctx: _Ctx


## tables: xpCurve, levelCaps, statCaps, xpScale, origins ({id: {stats, bond}}), skills (satır dizisi ya da {id: satır}); verilmeyen
## veri dosyasınınkidir. p_cond: koşul değerlendirici (bkz. cond).
func _init(tables: Dictionary = {}, p_cond: Callable = Callable()) -> void:
	var levels: Dictionary = Progression.data().get("levels", {})
	var stat_data: Dictionary = Progression.data().get("stats", {})
	xp_curve = tables["xpCurve"] if tables.has("xpCurve") else levels.get("xpCurve", [])
	level_caps = tables["levelCaps"] if tables.has("levelCaps") else levels.get("actCaps", [])
	stat_caps = tables["statCaps"] if tables.has("statCaps") else stat_data.get("actCaps", [])
	xp_scale = tables["xpScale"] if tables.has("xpScale") else (Progression.data().get("xp", {}) as Dictionary).get("scale", [1.0])
	# Verilen tablo veri dosyasını hiç okutmaz (sentetik tabloyla sınamalar).
	origins = tables["origins"] if tables.has("origins") else Progression.origin_table()
	stat_ids = stat_data.get("ids", ["grip", "wind", "foot", "eye", "word"])
	tier_levels = (Progression.data().get("skills", {}) as Dictionary).get("tierLevels", [1, 3, 6, 9, 12, 15])
	skill_rows = Progression.rows_by_id(tables["skills"] if tables.has("skills") else Progression.skill_data().get("skills", []))
	cond = p_cond
	_ctx = _Ctx.new(get_value)
	reset_player()


# ---------- Veri ----------

## data/progression/progression.json (bir kez okunur).
static func data() -> Dictionary:
	if _data.is_empty():
		_data = Progression._read(DATA_PATH)
	return _data


## data/progression/skills.json (bir kez okunur).
static func skill_data() -> Dictionary:
	if _skills.is_empty():
		_skills = Progression._read(SKILLS_PATH)
	return _skills


## Kökenler (data/character/origins.json): kimlik → {stats, bond}. Satırın eski kimlikleri (former_ids) _former_origins'e yazılır.
static func origin_table() -> Dictionary:
	if _origins.is_empty():
		for o: Variant in Progression._read(ORIGINS_PATH).get("origins", []):
			if o is Dictionary and (o as Dictionary).has("id"):
				var row: Dictionary = o
				_origins[str(row["id"])] = {"stats": row.get("stats", {}), "bond": float(row.get("bond", 0.0))}
				for old: Variant in Progression._arr(row.get("former_ids")):
					_former_origins[str(old)] = str(row["id"])
	return _origins


## Kökenin bugünkü kimliği: eski kimlik (K104'ten önceki kayıt: origin_load, origin_listener, origin_stable) yenisine çevrilir,
## öteki kimlik olduğu gibi döner.
static func current_origin(id: String) -> String:
	Progression.origin_table()
	return str(_former_origins.get(id, id))


static func reset_cache() -> void:
	_data = {}
	_skills = {}
	_origins = {}
	_former_origins = {}


static func _read(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary:
		return parsed
	push_error("Progression: %s okunamadı" % path)
	return {}


## Satır dizisi ya da {id: satır} → {id: satır} (tablo sırasıyla).
static func rows_by_id(table: Variant) -> Dictionary:
	var out := {}
	if table is Array:
		for row: Variant in table:
			if row is Dictionary and (row as Dictionary).has("id"):
				out[str(row["id"])] = row
	elif table is Dictionary:
		for id: Variant in table:
			var row: Dictionary = (table[id] as Dictionary).duplicate()
			row["id"] = str(id)
			out[str(id)] = row
	return out


static func _cap_at(table: Array, p_act: int) -> float:
	if table.is_empty():
		return INF
	return float(table[clampi(p_act, 1, table.size()) - 1])


static func _is_num(v: Variant) -> bool:
	return (v is float or v is int) and is_finite(float(v))


## Kayıttaki liste alanı: dizi değilse boş (bozuk kayıtta yazı karakter karakter gezilmesin).
static func _arr(v: Variant) -> Array:
	return v if v is Array else []


# ---------- Koşul bağlamı ----------

## Koşul dilinin yolları: level, act, stat.<id>, skill:<id> ilerlemeden; gerisi context'ten (yoksa flags'tan).
func get_value(path: String) -> Variant:
	if path == "level":
		return level
	if path == "act":
		return act
	if path.begins_with("stat."):
		return stats.get(path.substr(5))
	if path.begins_with("skill:"):
		return learned.has(path.substr(6))
	if context.is_valid():
		return context.call(path)
	return flags.get(path)


## Koşul tutuyor mu?
func check(expr: String) -> bool:
	if cond.is_valid():
		return bool(cond.call(expr))
	return Cond.holds(expr, _ctx)


## Bayrağı yazar ve ilerlemenin dinleyicisini çağırır (bkz. on_flag_set).
func set_flag(key: String, value: Variant) -> void:
	flags[key] = value
	on_flag_set(key, value)


## Bayrak dinleyicisi (Session bayrak yazılınca çağırır): sentenced yazılınca ustası tutmayan I. Perde becerileri yiter, öteki
## bayrak usta koşullarını yeniden sınar.
func on_flag_set(key: String, value: Variant) -> void:
	var sentenced := str((data().get("skills", {}) as Dictionary).get("sentencedFlag", "sentenced"))
	if key == sentenced and Cond.truthy(value):
		on_sentenced()
	else:
		check_teach()
	changed.emit()


## Görev bitti (Session çağırır): usta koşulları yeniden sınanır.
func on_quest_done(_quest_id: String = "") -> void:
	check_teach()
	changed.emit()


# ---------- XP ve seviye ----------

## Perdenin seviye tavanı.
func act_cap() -> int:
	return int(minf(_cap_at(level_caps, act), float(xp_curve.size())))


## Ham XP ekler (en yakın tamsayı); perde tavanı seviye atlamayı durdurur, XP'yi silmez. → eklenen XP. Kaynak kuralları award'dadır.
func add_xp(n: float, src: String = "") -> int:
	if not is_finite(n) or n <= 0.0:
		return 0
	var gain := int(roundf(n))
	if gain <= 0:
		return 0
	xp += gain
	xp_gained.emit(gain, src, xp)
	_settle_level()
	changed.emit()
	return gain


func _settle_level() -> void:
	var cap := act_cap()
	var gained := false
	while level < cap and xp >= int(xp_curve[level]):
		level += 1
		stat_points += 1
		skill_points += 1
		gained = true
		invalidate()
		level_up.emit(level)
	var levels: Dictionary = data().get("levels", {})
	if level >= xp_curve.size():
		var over := mini(int(levels.get("overflowMax", 3)), floori(float(xp - int(xp_curve.back())) / float(levels.get("overflowXp", 1800))))
		if over > overflow_points:
			skill_points += over - overflow_points
			overflow_points = over
	if gained:
		check_teach()


## XP'nin eğrideki seviyesi (perde tavanı olmadan).
func level_for_xp(amount: int) -> int:
	var lv := 1
	while lv < xp_curve.size() and amount >= int(xp_curve[lv]):
		lv += 1
	return lv


## Perde geçişi (§15): tavanlar artar, biriken XP seviye verir, II'den her perde Ozan'a Anlattır +2, ustası yiten beceriler temizlenir.
func act_change(n: int) -> bool:
	if n <= act:
		return false
	respec_tokens += int((data().get("skills", {}) as Dictionary).get("respecPerAct", 2)) * (n - act)
	act = n
	lost_master.clear()
	invalidate()
	_settle_level()
	check_teach()
	changed.emit()
	return true


## Kaynağın bu perdedeki XP'si (progression.md §1.3): taban × xpScale[perde − 1], en yakın tamsayı (yarım yukarı).
func scale_xp(base: float, p_act: int = -1) -> int:
	return int(roundf(base * _cap_at(xp_scale, act if p_act < 1 else p_act)))


## XP verir (progression.md §1.3): kaynağın tabanı (main ve side görev verisinden opts.base) × xpScale, kuralları uygulanarak.
## opts: base (tabanı ezer), key (bir kez sayılan kaynağın kimliği: tür, tarif, durak, iç harita), day (günlük sınır: oyun günü),
## kind (atlas_node'da «waypost» XP vermez). İnsan öldürmek, ham toplama, ganimet ve öteki «zero» kaynaklar 0'dır. → eklenen XP.
func award(src: String, opts: Dictionary = {}) -> int:
	var xp_data: Dictionary = data().get("xp", {})
	if (xp_data.get("zero", []) as Array).has(src):
		return 0
	var sources: Dictionary = xp_data.get("sources", {})
	if not sources.has(src):
		push_error("Progression.award: bilinmeyen XP kaynağı «%s»" % src)
		return 0
	var rule: Dictionary = sources[src]
	if act < int(rule.get("fromAct", 1)):
		return 0
	if (rule.get("zeroKinds", []) as Array).has(opts.get("kind")):
		return 0
	var base: Variant = opts.get("base", rule.get("base"))
	if not _is_num(base):
		push_error("Progression.award: «%s» kaynağının tabanı görev verisinden gelmeli (opts.base)" % src)
		return 0
	var key := str(opts.get("key", ""))
	var once_key := "%s:%s" % [src, key]
	if rule.get("once", false) and key != "" and xp_once.has(once_key):
		return 0
	var act_key := "%s@%d" % [src, act]
	var act_max := -1
	if rule.has("perAct"):
		act_max = int(rule["perAct"])
	elif rule.has("perActFrom") and act >= int(rule["perActFrom"]):
		act_max = int(rule.get("perActMax", -1))
	if act_max >= 0 and int(xp_counts.get(act_key, 0)) >= act_max:
		return 0
	var day_key := "%s#day" % src
	var day: Variant = opts.get("day")
	if rule.has("perDay") and _is_num(day):
		var seen: Array = xp_counts.get(day_key, [day, 0])
		if float(seen[0]) == float(day) and int(seen[1]) >= int(rule["perDay"]):
			return 0
	var gain := add_xp(float(scale_xp(float(base))), src)
	if gain <= 0:
		return 0
	if rule.get("once", false) and key != "":
		xp_once[once_key] = true
	if act_max >= 0:
		xp_counts[act_key] = int(xp_counts.get(act_key, 0)) + 1
	if rule.has("perDay") and _is_num(day):
		var seen: Array = xp_counts.get(day_key, [day, 0])
		xp_counts[day_key] = [float(day), (int(seen[1]) if float(seen[0]) == float(day) else 0) + 1]
	return gain


## Bu seviyenin eşiği ve sonrakinin eşiği (birikimli XP); en son seviyede ikisi aynıdır.
func xp_floor() -> int:
	return int(xp_curve[clampi(level, 1, xp_curve.size()) - 1])


func xp_next() -> int:
	return int(xp_curve[level]) if level < xp_curve.size() else xp_floor()


## Bu seviyedeki ilerleme 0..1 (HUD'un XP çubuğu); en son seviyede 1.
func xp_ratio() -> float:
	var lo := xp_floor()
	var hi := xp_next()
	if hi <= lo:
		return 1.0
	return clampf(float(xp - lo) / float(hi - lo), 0.0, 1.0)


# ---------- Stat ----------

## Perdenin tek stat tavanı (I 7 … VI 12).
func stat_cap() -> int:
	return int(_cap_at(stat_caps, act))


## Kökenin satırı ({stats, bond}) ya da boş sözlük.
func origin_row() -> Dictionary:
	return origins.get(origin, {}) if origin != "" else {}


## Kökenin At Bağı katkısı (Yılkı Beyi +10): binek sistemi başlangıç Bağı'nı buradan okur.
func origin_bond() -> float:
	return float(origin_row().get("bond", 0.0))


func spend_stat(id: String) -> bool:
	if not stat_ids.has(id) or stat_points < 1 or int(stats.get(id, 0)) >= stat_cap():
		return false
	stats[id] = int(stats[id]) + 1
	stat_points -= 1
	invalidate()
	stat_spent.emit(id)
	check_teach()
	changed.emit()
	return true


# ---------- Beceri ----------

## Becerinin satırı (yoksa boş sözlük).
func skill_row(id: String) -> Dictionary:
	return skill_rows.get(id, {})


## Satırın en düşük seviyesi: satırın level'ı ile tier tabanının büyüğü.
func min_level(row: Dictionary) -> int:
	var tier := int(row.get("tier", 1))
	var base := int(tier_levels[tier - 1]) if tier >= 1 and tier <= tier_levels.size() else 1
	return maxi(int(row.get("level", 1)), base)


static func cost_of(row: Dictionary) -> int:
	return 0 if row.get("free", false) else 1


## "hidden" | "locked" | "teachable" | "ready" | "learned" | "lost_master"; bilinmeyen kimlik "".
func skill_state(id: String) -> String:
	if not skill_rows.has(id):
		return ""
	var row: Dictionary = skill_rows[id]
	if learned.has(id):
		return "learned"
	if lost_master.has(id):
		return "lost_master"
	if row.get("hideName", false) and not check(str((data().get("skills", {}) as Dictionary).get("nameFlag", "whistling_arrow"))):
		return "hidden"
	if int(row.get("act", 1)) > act or not requires_met(row):
		return "locked"
	return "ready" if teach_set.has(id) or teach_met(row) else "teachable"


## requires: beceri kimliği öğrenilmiş olmalı, başka her öğe koşul dilidir ("act1_done", "korku>=10").
func requires_met(row: Dictionary) -> bool:
	for need: Variant in row.get("requires", []):
		var n := str(need)
		if skill_rows.has(n):
			if not learned.has(n):
				return false
		elif not check(n):
			return false
	return true


## Usta koşulu teach.when; koşulu olmayan satırın (usta istemeyen beceri) ustası hazırdır.
func teach_met(row: Dictionary) -> bool:
	var teach: Variant = row.get("teach")
	var when: Variant = (teach as Dictionary).get("when") if teach is Dictionary else null
	return when == null or str(when) == "" or check(str(when))


## Öğrenmeyi engelleyen ilk neden: null ise öğrenilir; "unknown" | "learned" | "lost_master" | "locked" | "master" | "level" | "points".
func learn_block(id: String) -> Variant:
	var state := skill_state(id)
	if state == "":
		return "unknown"
	if state == "learned" or state == "lost_master":
		return state
	if state == "hidden" or state == "locked":
		return "locked"
	if state == "teachable":
		return "master"
	var row: Dictionary = skill_rows[id]
	if level < min_level(row):
		return "level"
	return "points" if skill_points < cost_of(row) else null


func can_learn(id: String) -> bool:
	return learn_block(id) == null


func learn(id: String) -> bool:
	if not can_learn(id):
		return false
	var row: Dictionary = skill_rows[id]
	skill_points -= cost_of(row)
	learned[id] = {"at": level, "src": "free" if row.get("free", false) else "point"}
	teach_set[id] = true
	_mods_dirty = true
	invalidate()
	skill_learned.emit(id)
	# Önkoşulu bu beceri olan satırın ustası şimdi tutabilir.
	check_teach()
	changed.emit()
	return true


## Usta öğretti: beceri hazır kalır, bedava olan hemen öğrenilir.
func teach(id: String) -> bool:
	if not skill_rows.has(id) or learned.has(id) or teach_set.has(id):
		return false
	teach_set[id] = true
	lost_master.erase(id)
	skill_taught.emit(id)
	if skill_rows[id].get("free", false):
		learn(id)
	changed.emit()
	return true


## Ustası tutan beceriyi teach_set'e yazar: koşul sonradan bozulsa da hazır kalır (§4.2 Act 1 kuralı); bedava olan öğrenilir.
## İç içe çağrı (öğrenme, dinleyici) turu yeniden başlatır; küme yalnız büyüdüğü için döngü biter.
func check_teach() -> void:
	if _checking:
		_recheck = true
		return
	_checking = true
	var again := true
	while again:
		_recheck = false
		for id: String in skill_rows:
			if learned.has(id) or skill_state(id) != "ready":
				continue
			if not teach_set.has(id):
				teach_set[id] = true
				skill_taught.emit(id)
			if skill_rows[id].get("free", false):
				learn(id)
		again = _recheck
	_checking = false


## sentenced: ustası o ana dek tutmayan bütün I. Perde becerileri lost_master olur; hazır olanlar kalır.
func on_sentenced() -> void:
	check_teach()
	for id: String in skill_rows:
		if int(skill_rows[id].get("act", 1)) != 1 or learned.has(id) or teach_set.has(id):
			continue
		lost_master[id] = true


## Görev puanı (§1.4): aynı kimlik iki kez puan vermez.
func grant_point(id: String) -> bool:
	if id == "" or points_granted.has(id):
		return false
	points_granted.append(id)
	skill_points += 1
	changed.emit()
	return true


## Öğrenilen edilgen becerilerin anahtarları (§4.4): sayı toplanır, {mul} çarpılır, {set} ezer; bool ve yazı ezer, dizi birleşir.
## Etkin ve aç-kapa becerinin mods'u kullanım anının değeridir, katlanmaz. Öğrenme sırasıyla katlanır; sonuç önbellektedir.
func mods() -> Dictionary:
	if _mods_dirty:
		_mod_acc = {}
		for id: String in learned:
			var row: Variant = skill_rows.get(id)
			if not row is Dictionary or str((row as Dictionary).get("kind", "passive")) != "passive":
				continue
			var m: Variant = (row as Dictionary).get("mods")
			if m is Dictionary:
				for key: String in m:
					Progression._fold_mod(_mod_acc, key, (m as Dictionary)[key])
		_mod_values = {}
		for key: String in _mod_acc:
			_mod_values[key] = Progression._mod_value(_mod_acc[key], null)
		_mods_dirty = false
	return _mod_values


## Tek anahtarın değeri; hiç öğrenilmemişse fallback; yalnız çarpan taşıyan anahtar fallback'ten çarpılır.
func mod(key: String, fallback: Variant = null) -> Variant:
	mods()
	return Progression._mod_value(_mod_acc[key], fallback) if _mod_acc.has(key) else fallback


static func _fold_mod(acc: Dictionary, key: String, value: Variant) -> void:
	if not acc.has(key):
		acc[key] = {"add": 0.0, "mul": 1.0, "set": null, "has_set": false, "list": null, "adds": false, "muls": false}
	var a: Dictionary = acc[key]
	if _is_num(value):
		a["add"] = float(a["add"]) + float(value)
		a["adds"] = true
	elif value is Array:
		var list: Array = (a["list"] as Array).duplicate() if a["list"] is Array else []
		for v: Variant in value:
			if not list.has(v):
				list.append(v)
		a["list"] = list
	elif value is Dictionary and _is_num((value as Dictionary).get("mul")):
		a["mul"] = float(a["mul"]) * float(value["mul"])
		a["muls"] = true
	elif value is Dictionary and (value as Dictionary).has("set"):
		a["set"] = value["set"]
		a["has_set"] = true
	else:
		a["set"] = value
		a["has_set"] = true


static func _mod_value(a: Dictionary, fallback: Variant) -> Variant:
	if a["list"] is Array:
		return (a["list"] as Array).duplicate()
	if a["has_set"] and not _is_num(a["set"]):
		return a["set"]
	var base := 0.0
	if a["has_set"]:
		base = float(a["set"])
	elif _is_num(fallback):
		base = float(fallback)
	elif a["muls"] and not a["adds"]:
		base = 1.0
	return (base + float(a["add"])) * float(a["mul"])


## Çubuk yuvası: öğrenilmiş beceri ya da sarf eşyası kimliği, null boş. Aynı kimlik tek yuvada durur.
func set_bar(slot: int, id: Variant) -> bool:
	if slot < 0 or slot >= bar.size():
		return false
	if id != null and (not (id is String or id is StringName) or String(id) == "" or (skill_rows.has(String(id)) and not learned.has(String(id)))):
		return false
	var value: Variant = String(id) if id != null else null
	for i in bar.size():
		if bar[i] == value:
			bar[i] = null
	bar[slot] = value
	changed.emit()
	return true


# ---------- Türetilen ----------

## Derive'ın girdisi: inputs()'un verdikleri, üstüne stat, seviye ve beceri anahtarları.
func derive_state(extra: Dictionary = {}) -> Dictionary:
	var state: Dictionary = inputs.call() if inputs.is_valid() else {}
	state = state.duplicate()
	state.merge(extra, true)
	state["stats"] = stats.duplicate()
	state["level"] = level
	state["mods"] = mods()
	return state


## Türetilen değerler (Derive.derive); girdi değişmedikçe önbellekten (invalidate ile yenilenir; inputs değişince çağıran söyler).
func derived() -> Dictionary:
	if _derived.is_empty():
		_derived = Derive.derive(derive_state())
	return _derived


func invalidate() -> void:
	_derived = {}


# ---------- Kayıt ----------

## Yeni yolculuk: köken oluşturucunun «origin» alanıdır (bilinmeyen ya da boş köken yok sayılır, stat puanı beklemede kalır). Tabloda
## olmayan eski kimlik (K104'ten önceki kayıt; from_dict de buradan geçer) yenisine göçer; tablodaki kimlik olduğu gibi kalır (sınamanın
## kendi tablosu, prototipin fikstürü).
func reset_player(p_origin: String = "") -> void:
	var id := p_origin if origins.has(p_origin) else Progression.current_origin(p_origin)
	origin = id if origins.has(id) else ""
	var row := origin_row()
	var bonus: Dictionary = row.get("stats", {})
	var start := int((data().get("stats", {}) as Dictionary).get("start", 3))
	act = 1
	level = 1
	xp = 0
	stats = {}
	for stat_id: String in stat_ids:
		stats[stat_id] = start + int(bonus.get(stat_id, 0))
	stat_points = 0 if not row.is_empty() else int((data().get("stats", {}) as Dictionary).get("originBonus", 1))
	skill_points = 0
	points_granted = []
	overflow_points = 0
	respec_tokens = 0
	learned = {}
	teach_set = {}
	lost_master = {}
	bar = []
	bar.resize(int((data().get("skills", {}) as Dictionary).get("barSlots", 6)))
	xp_once = {}
	xp_counts = {}
	_mods_dirty = true
	invalidate()
	changed.emit()


## Kayıt v2'nin «progression» bloğu (godot.md §3.4; alanlar progression.md §13.2 «player»ındır). Perde zarfın act'ıdır.
func to_dict() -> Dictionary:
	var skills := {}
	for id: String in learned:
		skills[id] = {"at": int(learned[id]["at"]), "src": str(learned[id]["src"])}
	return {
		"v": BLOCK_VERSION,
		"origin": origin if origin != "" else null,
		"level": level,
		"xp": xp,
		"statPoints": stat_points,
		"skillPoints": skill_points,
		"pointsGranted": points_granted.duplicate(),
		"overflowPoints": overflow_points,
		"respecTokens": respec_tokens,
		"stats": stats.duplicate(),
		"skills": skills,
		"teach": teach_set.keys(),
		"lostMaster": lost_master.keys(),
		"bar": bar.duplicate(),
		"xpOnce": xp_once.keys(),
		"xpCounts": xp_counts.duplicate(true),
	}


## Bloğu okur ve doğrular (progression.md §13.3): seviye = min(perde tavanı, XP'den seviye); statlar 3 ile perde tavanı arasına
## kırpılır, Σstat + statPoints = 15 + 1 + (Sv − 1) tutmazsa fark statPoints'e yazılır; bilinmeyen beceri silinir ve puanı geri
## verilir: skillPoints = (Sv − 1) + pointsGranted + aşkın − harcanan. Usta koşulları yeniden sınanmaz (kayıt olduğu gibi okunur).
func from_dict(d: Dictionary, p_act: int = 1) -> void:
	reset_player(str(d.get("origin")) if d.get("origin") is String else "")
	act = maxi(1, p_act)
	xp = maxi(0, int(d.get("xp", 0)) if _is_num(d.get("xp")) else 0)
	level = mini(act_cap(), level_for_xp(xp))
	var levels: Dictionary = data().get("levels", {})
	if level >= xp_curve.size():
		overflow_points = clampi(floori(float(xp - int(xp_curve.back())) / float(levels.get("overflowXp", 1800))), 0, int(levels.get("overflowMax", 3)))
	var start := int((data().get("stats", {}) as Dictionary).get("start", 3))
	var saved_stats: Dictionary = d.get("stats", {}) if d.get("stats") is Dictionary else {}
	var total := 0
	for id: String in stat_ids:
		var v: Variant = saved_stats.get(id)
		stats[id] = clampi(int(v) if _is_num(v) else start, start, stat_cap())
		total += int(stats[id])
	var expected := stat_ids.size() * start + int((data().get("stats", {}) as Dictionary).get("originBonus", 1)) + (level - 1)
	stat_points = maxi(0, expected - total)
	for g: Variant in Progression._arr(d.get("pointsGranted")):
		if g is String and g != "" and not points_granted.has(g):
			points_granted.append(g)
	respec_tokens = maxi(0, int(d.get("respecTokens", 0)) if _is_num(d.get("respecTokens")) else 0)
	var saved_skills: Dictionary = d.get("skills", {}) if d.get("skills") is Dictionary else {}
	var spent := 0
	for id: Variant in saved_skills:
		if not skill_rows.has(str(id)):
			continue
		var entry: Variant = saved_skills[id]
		var e: Dictionary = entry if entry is Dictionary else {}
		var at: int = int(e.get("at")) if _is_num(e.get("at")) else 1
		learned[str(id)] = {"at": at, "src": "free" if e.get("src") == "free" else "point"}
		spent += cost_of(skill_rows[str(id)])
	skill_points = maxi(0, (level - 1) + points_granted.size() + overflow_points - spent)
	for id: Variant in Progression._arr(d.get("teach")):
		if skill_rows.has(str(id)):
			teach_set[str(id)] = true
	for id: Variant in Progression._arr(d.get("lostMaster")):
		if skill_rows.has(str(id)):
			lost_master[str(id)] = true
	var saved_bar: Array = d.get("bar", []) if d.get("bar") is Array else []
	for i in bar.size():
		var b: Variant = saved_bar[i] if i < saved_bar.size() else null
		bar[i] = b if b is String and b != "" else null
	for k: Variant in Progression._arr(d.get("xpOnce")):
		if k is String:
			xp_once[k] = true
	if d.get("xpCounts") is Dictionary:
		xp_counts = (d["xpCounts"] as Dictionary).duplicate(true)
	_mods_dirty = true
	invalidate()
	changed.emit()


## Koşul bağlamı (Cond.Ctx): yolu ilerlemenin get_value'su çözer. Callable nesneyi tutmaz, döngüsel başvuru yoktur.
class _Ctx:
	extends Cond.Ctx

	var getter: Callable

	func _init(p_getter: Callable) -> void:
		getter = p_getter

	func get_value(path: String) -> Variant:
		return getter.call(path)
