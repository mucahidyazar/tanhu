class_name Wounds
extends RefCounted
## Yara ve Düşüş (saf; progression.md §3, §8.5; survival.md §2.7, §7.4; time.md §10.5; K1, K35, K45; data/survival/needs.json).
## Can 0'da Yara +1, Can %50'ye döner, 1 sn dokunulmaz (Can'ı tutan çağırandır: hp_after_zero). Açık yara başına stamina −8, koşu −%3,
## Can dolumu −%25. Yara sınırı zorluğundur (Hikâye 5, Normal 3, Zor 2); dolunca Düşüş: Umay Eşiği (fall_plan, fall). Açlık ve hava
## Düşüş açmaz: yalnız Can yoluyla gelir. Kapanış: sargı ve Bozkır Çayı −1; ateş başında ≥2 oyun saati dinlenme Tokluk ≥25 ise −1,
## 6 oyun saatinde bir; ≥4 oyun saati süren uyku hepsini kapatır (Uyku Zarı daha önce keserse kapanmaz).
##   var w := Wounds.new("normal")
##   w.hit_zero()            # Can 0: Yara +1 → fell yayılır mı?
##   w.rest(180.0, 60.0, now) # 3 saat ateş başı dinlenme, Tokluk 60: −1
##   w.sleep(480.0)           # bütün yaralar kapanır
##   w.fall_plan({"kut": 0})  # {skip_min, cost, wake_wounds, first, card}

signal changed(count: int)
## Yara sınırı doldu (Düşüş; Survival Umay Eşiği'ni oynatır).
signal fell(plan: Dictionary)

var difficulty := "normal"
var count := 0
## Bugüne dek Düşüş sayısı (ilk Düşüş kartı tek söz yazar: «Umay.»).
var falls := 0
## Dinlenmeyle son kapanışın anı (mutlak dk; −INF yok).
var rest_heal_at := -INF


func _init(p_difficulty := "normal") -> void:
	difficulty = p_difficulty


static func data() -> Dictionary:
	return Needs.data().get("wounds", {}) as Dictionary


static func fall_data() -> Dictionary:
	return Needs.data().get("fall", {}) as Dictionary


## Yara sınırı (zorluğun woundLimit'i; needs.json limit yedektir).
func limit() -> int:
	var row := Needs.difficulty_row(difficulty)
	if row.has("woundLimit"):
		return int(row["woundLimit"])
	return int((data().get("limit", {}) as Dictionary).get(difficulty, 3))


## Yara ekler (çizimli doğrudan vuruş da +1). Sınıra varırsa fell yayılır, döner: Düşüş oldu mu.
func add(n := 1) -> bool:
	if n <= 0:
		return false
	count = mini(count + n, limit())
	changed.emit(count)
	if count >= limit():
		fell.emit(fall_plan())
		return true
	return false


## Can 0 (Mete'nin kuralı): Yara +1. Döner: Düşüş oldu mu (olmadıysa Can %50'ye döner: hp_after_zero).
func hit_zero() -> bool:
	return add(1)


## Can 0'dan sonra Can'ın oranı (0,5).
static func hp_after_zero() -> float:
	return float(data().get("hp_after_zero", 0.5))


## Yara kapanır (sargı, Bozkır Çayı, Kemik Suyu). Döner: kapanan sayı.
func heal(n := 1) -> int:
	var k := mini(maxi(n, 0), count)
	if k > 0:
		count -= k
		changed.emit(count)
	return k


func clear() -> void:
	if count != 0:
		count = 0
		changed.emit(count)


## Ateş başında dinlenme (Bekle tekerinin «rest» atlaması): minutes ≥ rest_min ve Tokluk ≥ rest_fullness ise ilk kapanış dinlenmenin
## rest_min'inde, sonrakiler rest_every_min'de bir; son kapanıştan rest_every_min geçmeden yenisi olmaz. end_abs: dinlenmenin sonu.
## Döner: kapanan sayı.
func rest(minutes: float, fullness: float, end_abs: float) -> int:
	var need := float(data().get("rest_min", 120.0))
	var every := float(data().get("rest_every_min", 360.0))
	if minutes < need - 1e-9 or fullness < float(data().get("rest_fullness", 25.0)) - 1e-9 or count <= 0:
		return 0
	var start := end_abs - minutes
	var at := start + need
	if at < rest_heal_at + every - 1e-9:
		at = rest_heal_at + every
	var healed := 0
	while at <= end_abs + 1e-9 and count > 0:
		count -= 1
		healed += 1
		rest_heal_at = at
		at += every
	if healed > 0:
		changed.emit(count)
	return healed


## Uyku: ≥ sleep_min süren (ve kesilmeyen) uyku bütün yaraları kapatır. Döner: kapanan sayı.
func sleep(minutes: float, interrupted := false) -> int:
	if interrupted or minutes < float(data().get("sleep_min", 240.0)) - 1e-9 or count <= 0:
		return 0
	var k := count
	clear()
	return k


## Açık yaraların etkisi (saf): sta stamina tavanından düşen, run koşu çarpanı, hp_regen Can dolumu çarpanı.
func effects() -> Dictionary:
	return Wounds.effects_of(count)


static func effects_of(n: int) -> Dictionary:
	var d := data()
	return {"sta": -float(d.get("wound_sta", 8.0)) * n, "run": maxf(0.0, 1.0 - float(d.get("wound_run", 0.03)) * n),
		"hp_regen": maxf(0.0, 1.0 - float(d.get("wound_hp_regen", 0.25)) * n)}


## Düşüşün planı (saf; progression.md §8.5): skip_min (+2 oyun saati), cost (zorluğun fallCost'u; Kut ≥5 ya da Geyik Muskası 0),
## wake_wounds (Hikâye 0, öteki 1), first (ilk Düşüş: kart «Umay.»), card. opts: kut, amulet (bool).
func fall_plan(opts: Dictionary = {}) -> Dictionary:
	var f := fall_data()
	var row := Needs.difficulty_row(difficulty)
	var cost := int(row.get("fallCost", 1))
	if int(opts.get("kut", 0)) >= int(f.get("kut_free", 5)) or bool(opts.get("amulet", false)):
		cost = 0
	var wake := int((f.get("wake_wounds", {}) as Dictionary).get(difficulty, 0 if difficulty == "story" else 1))
	return {"skip_min": float(f.get("skip_min", 120.0)), "cost": cost, "wake_wounds": wake, "first": falls == 0,
		"card": f.get("card", {"tr": "Umay.", "en": "Umay."})}


## Düşüşün yara yüzü: yara uyanış sayısına iner, Düşüş sayılır. Döner: plan.
func fall(opts: Dictionary = {}) -> Dictionary:
	var plan := fall_plan(opts)
	falls += 1
	count = int(plan["wake_wounds"])
	changed.emit(count)
	return plan


## survival.wounds.
func to_dict() -> Dictionary:
	return {"n": count, "falls": falls, "rest_at": rest_heal_at if is_finite(rest_heal_at) else null}


func from_dict(d: Variant) -> void:
	var o: Dictionary = d if d is Dictionary else {}
	count = clampi(int(o.get("n", 0)) if (o.get("n") is int or o.get("n") is float) else 0, 0, limit())
	falls = maxi(int(o.get("falls", 0)) if (o.get("falls") is int or o.get("falls") is float) else 0, 0)
	rest_heal_at = float(o["rest_at"]) if (o.get("rest_at") is int or o.get("rest_at") is float) else -INF
	changed.emit(count)
