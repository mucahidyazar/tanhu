class_name Derive
extends RefCounted
## Oyuncunun türetilen sayıları (progression.md §2.3): stat, seviye, beceri anahtarları (mods), donanım, yara, Tokluk, yük ve ortamdan
## can, stamina, hız, yük, yay, sapan, gürültü, sezgi, Güven ve binek değerleri (saf; kare başına çağrılmaz, girdi değişince koşar).
## Prototipin game/derive.js'inin birebir taşınmasıdır, altın değerlerle sınanır (tests/fixtures/derive.json, 1e-9; K29).
##
## Girdi (verilmeyen alan varsayılandır; anahtar adları belgenin ve prototipin adlarıdır):
##   stats {grip, wind, foot, eye, word} dağıtılan (3); level (1); wounds açık yara (0); fullness Tokluk 0..100 (100); load Yük (0)
##   mods Progression.mods() değerleri; tek satırın {mul} ve {set} biçimi de değere çözülür
##   gear donanım toplamı: statBonus {stat: n}, hp, load, noise, gallop toplanır; runMul, drawMul, spreadMul, turnMul, visMul,
##        snowSpeed, trackMul, saddleSpreadMul, saddleDrawMul çarpandır; dr {tür: yüzde}; saddled; öteki alanlar olduğu gibi geçer
##   buff süreli yemek (survival.md §3): grip … word ve sta toplanır; staRegen, runMul, visMul çarpandır
##   flags bayrak sözlüğü (debt_erlik, hearths_out); axes {kut, korku, hearths_out}; diff zorluk satırı (yoksa Normal)
##   bond At Bağı 0..100; mount {base, spur = 3, saddled, load, cap} ya da null; env {ground: "path" | "deep" | "shelter", shelter,
##   blizzard, route, wetBow 0..1}; bow yay satırı ({id, dmg, pull, draw, spread, range}) ya da kimliği (İnce İş «hun_bow+»),
##   kimlik bows'tan (yoksa Weapons tablosundan) okunur; bell {on, plug}
## Çıktının yürüyüşe ve hıza bağlı üç alanı tablodur, kullanım anında seçilir: staRegen {still, moving}, noiseR {still, crouch, walk,
## run}, turnRate {still, top} (ara hız turn_rate_at). Rüzgâr, sürüş zemini, işitme ve görüş çarpanları kullanım anında uygulanır.

const STAT_IDS: Array[String] = ["grip", "wind", "foot", "eye", "word"]
const DR_TYPES: Array[String] = ["slash", "pierce", "blunt", "fire"]
const BASE := 3.0

# Can ve yara (§2.3, §3; act1.md §8.5 Kül Borcu).
const HP_BASE := 100.0
const HP_LEVEL := 5.0
const HP_GRIP := 2.0
const ASH_BASE := 5.0
const ASH_MAX := 15.0
const ASH_STATES: Array[String] = ["open", "ash"]
const HP_REGEN := 1.2
const WOUND_REGEN := 0.25

# Stamina.
const STA_BASE := 100.0
const STA_WIND := 6.0
const STA_WOUND := 8.0
const RUN_DRAIN := 17.0
const REGEN_STILL := 15.0
const REGEN_MOVING := 7.0
const HUNGRY := 25.0
const JUMP_COST := 8.0
const EXHAUSTED_UNTIL := 24.0

# Hız m/sn (act1.md §9.5) ve Üç Zemin (act1.md §9.2).
const CROUCH := 2.2
const WALK := 4.4
const RUN := 7.6
const DEEP_SPEED := 0.7
const DEEP_REGEN := 0.8
const SHELTER_REGEN := 1.5

# Yük (economy.md §4.1): koşu dörtte üçe, zıplama yarıya dek.
const LOAD_BASE := 12.0
const LOAD_GRIP := 3.0
const LOAD_SLOW := 0.3
const RUN_LOAD := 0.75
const JUMP_LOAD := 0.5

# Savuş, sapan, yay (§2.3, §7.2).
const DODGE_T := 0.25
const DODGE_COST := 15.0
const DODGE_MIN := 6.0
const SLING_DMG := 6.0
const SLING_RANGE := 18.0
const SLING_STUN := 1.2
const SLING_RELOAD := 1.6
const SPREAD_MIN := 0.25
const RIDE_SPREAD := 1.6
const GALLOP_DRAW := 0.25
const FINE_K := 1.1

# Islak kiriş (weather.md §8.8): bileşik yay 1, ağaç yay 0,5, arbalet 0,3; hasar −%15, menzil −%10, çekiş +%10 (w = 1'de).
const WET_DMG := 0.15
const WET_RANGE := 0.1
const WET_DRAW := 0.1
const WET_STEPS := 4.0
const BOW_WET := {"toy_bow": 0.5, "loan_bow": 0.5, "han_crossbow": 0.3}

# Çan yarıçapı m (act1.md §9.5): el çanda çömelik 2, keçe tıkaç ×0,4; çan gidince küçük değerler. Ayak puanı −0,2 m.
const BELL_ON := {"crouch": 2.0, "walk": 14.0, "run": 32.0}
const BELL_OFF := {"crouch": 1.5, "walk": 4.0, "run": 9.0}
const PLUG := 0.4

# Atlı (§2.3, act1.md §10): k = Bağ/100; mahmuz +3; dönüş dururken 4,4, tepe hızda 2,8 rad/sn.
const SPUR := 3.0
const BOND_GALLOP := 0.045
const DRAIN_BASE := 0.27
const DRAIN_BOND := 0.09
const BAREBACK := 1.3
const TIPI := 1.2
const TIPI_R1 := 1.25
const TIPI_KUT := 0.85
const REGEN_HORSE := 0.14
const REGEN_BOND := 0.1
const TURN_STILL := 4.4
const TURN_TOP := 2.8

# Binek yükü (economy.md §4.7): yarıya dek ×1, sonra 1 − 0,3 × (l − 0,5); dörtte üçün üstünde dörtnal yok.
const MOUNT_FREE := 0.5
const MOUNT_SLOW := 0.3
const MOUNT_GALLOP := 0.75

## Emek yasasının okuduğu beceri değerleri öğrenilmemişken nötrdür: Labour 1/buildTime ve 1/repairTime alır (K21).
const LABOUR_NEUTRAL := {"buildTime": 1.0, "helpers": 0.0, "repairTime": 1.0, "repairCost": 1.0}
## Zorluk satırı verilmezse Normal (data/character/difficulty.json; progression.md §12).
const NORMAL := {"staRegen": 1.0, "woundLimit": 3.0, "wetBowK": 1.0}


static func _num(v: Variant, fallback: float) -> float:
	return float(v) if (v is float or v is int) and is_finite(float(v)) else fallback


static func _is_num(v: Variant) -> bool:
	return (v is float or v is int) and is_finite(float(v))


static func _dict(v: Variant) -> Dictionary:
	return v if v is Dictionary else {}


## Korku eşiğinin Güven kazancına ve nöbetçinin ilk görüş duraksamasına etkisi (progression.md §5.2, act1.md §2).
static func dread_effects(korku: float) -> Dictionary:
	if korku >= 10.0:
		return {"trustGainK": 0.8, "guardPause": 0.5}
	if korku >= 4.0:
		return {"trustGainK": 0.9, "guardPause": 0.5}
	return {"trustGainK": 1.0, "guardPause": 0.0}


## Yay çekiş çarpanı (§2.3): Bilek çekiş eşiğinin üstündeyse puan başına +%2, altındaysa puan başına −%12 (en az 0,6); pull 0 olan
## yay (oyuncak yay, arbalet) Bilek okumaz.
static func pull_factor(pull: float, grip: float) -> float:
	if pull == 0.0:
		return 1.0
	return 1.0 + 0.02 * (grip - pull) if grip >= pull else maxf(0.6, 1.0 - 0.12 * (pull - grip))


## Islaklığın 0,25 basamağı: derive yalnız basamak değişince yeniden koşar.
static func step_wet(w: Variant) -> float:
	if not _is_num(w):
		return 0.0
	return roundf(minf(1.0, maxf(0.0, float(w))) * WET_STEPS) / WET_STEPS


## l = terki / binek Yük'ü (economy.md §4.7): yarıya dek ×1, sonra 1 − 0,3 × (l − 0,5).
static func mount_load_k(l: Variant) -> float:
	if not _is_num(l) or float(l) <= MOUNT_FREE:
		return 1.0
	return 1.0 - MOUNT_SLOW * (minf(float(l), 1.0) - MOUNT_FREE)


## Dönüş hızı rad/sn: dururken turnRate.still, dörtnal tepe hızında turnRate.top; arası doğrusal.
static func turn_rate_at(d: Dictionary, speed: float) -> float:
	var g: Variant = d.get("gallop")
	var t := minf(1.0, maxf(0.0, speed / float(g))) if _is_num(g) and float(g) > 0.0 else 0.0
	var tr: Dictionary = d.get("turnRate", {})
	return lerpf(float(tr.get("still", TURN_STILL)), float(tr.get("top", TURN_TOP)), t)


## Tek satırın biçimi değere iner: {mul} çarpan, {set} ezen değer; dizi kopyalanır; öteki değer olduğu gibi.
static func value_of(v: Variant) -> Variant:
	if v is Array:
		return (v as Array).duplicate()
	if v is Dictionary:
		var d: Dictionary = v
		if _is_num(d.get("mul")):
			return float(d["mul"])
		if d.has("set"):
			return d["set"]
	return v


## Beceri değerleri: emek yasasının nötr değerleri, üstüne verilenler (değere çözülmüş).
static func resolve_mods(mods: Variant) -> Dictionary:
	var out := LABOUR_NEUTRAL.duplicate()
	if mods is Dictionary:
		for key: Variant in mods:
			out[key] = value_of((mods as Dictionary)[key])
	return out


static func _sum_table(table: Variant, ids: Array[String], fallback: float) -> Dictionary:
	var t := _dict(table)
	var out := {}
	for id in ids:
		out[id] = _num(t.get(id), fallback)
	return out


## Donanım toplamının bilinen alanları varsayılanla doldurulur; başka alanlar (bow, saddled, courtOnly …) korunur.
static func gear_of(gear: Variant) -> Dictionary:
	var g := _dict(gear)
	var out := g.duplicate(true)
	out["statBonus"] = _sum_table(g.get("statBonus"), STAT_IDS, 0.0)
	out["dr"] = _sum_table(g.get("dr"), DR_TYPES, 0.0)
	for key: String in ["hp", "load", "noise", "gallop"]:
		out[key] = _num(g.get(key), 0.0)
	for key: String in ["runMul", "drawMul", "spreadMul", "turnMul", "visMul", "snowSpeed", "trackMul", "saddleSpreadMul", "saddleDrawMul"]:
		out[key] = _num(g.get(key), 1.0)
	return out


## Yay: {id, row, fine} ya da null. Kimlikte İnce İş «+» ile taşınır (hun_bow+); kimlik bows'tan, yoksa Weapons tablosundan okunur.
static func bow_of(ref: Variant, bows: Variant = null) -> Variant:
	if (ref is String or ref is StringName) and String(ref) != "":
		var text := String(ref)
		var id := text.trim_suffix("+") if text.ends_with("+") else text
		var row: Variant = (bows as Dictionary).get(id) if bows is Dictionary else Weapons.bow(id)
		if row is Dictionary and not (row as Dictionary).is_empty():
			return {"id": id, "row": row, "fine": id != text}
		return null
	if ref is Dictionary and _is_num((ref as Dictionary).get("dmg")):
		var rid: Variant = (ref as Dictionary).get("id")
		var id: Variant = String(rid).trim_suffix("+") if rid is String or rid is StringName else null
		return {"id": id, "row": ref, "fine": false}
	return null


static func _bow_wet_k(b: Variant) -> float:
	if b == null:
		return 0.0
	var id: Variant = (b as Dictionary).get("id")
	return float(BOW_WET[id]) if id is String and BOW_WET.has(id) else 1.0


static func _flag(flags: Variant, key: String) -> Variant:
	if flags is Dictionary:
		return (flags as Dictionary).get(key)
	if flags is Callable and (flags as Callable).is_valid():
		return (flags as Callable).call(key)
	return null


## Türetilen değerler (progression.md §2.3); girdi yukarıdaki biçimdedir. Dönen sözlük yenidir, çağıran saklayabilir.
static func derive(input: Dictionary = {}) -> Dictionary:
	var dif: Dictionary = input.get("diff") if input.get("diff") is Dictionary else NORMAL
	var m := resolve_mods(input.get("mods"))
	var gr := gear_of(input.get("gear"))
	var bf := _dict(input.get("buff"))
	var e := _dict(input.get("env"))
	var stats := _dict(input.get("stats"))
	var axes := _dict(input.get("axes"))
	var flags: Variant = input.get("flags")
	var lv := _num(input.get("level"), 1.0)
	var wd := maxf(0.0, _num(input.get("wounds"), 0.0))
	var full := _num(input.get("fullness"), 100.0)

	# Etkili stat: dağıtılan + eşya + süreli yemek; tavan dışı (§2.3).
	var st := {}
	var bonus: Dictionary = gr["statBonus"]
	for id in STAT_IDS:
		st[id] = _num(stats.get(id), BASE) + float(bonus[id]) + _num(bf.get(id), 0.0)
	var g: float = st["grip"]
	var w: float = st["wind"]
	var f: float = st["foot"]
	var ey: float = st["eye"]
	var v: float = st["word"]

	# Can ve yara.
	var hearths := _num(axes.get("hearths_out"), _num(_flag(flags, "hearths_out"), 0.0))
	var debt: Variant = _flag(flags, "debt_erlik")
	var ash_debt := minf(ASH_MAX, ASH_BASE + hearths) if debt is String and ASH_STATES.has(debt) else 0.0
	var hp_max := HP_BASE + HP_LEVEL * (lv - 1.0) + HP_GRIP * maxf(0.0, g - BASE) + float(gr["hp"]) - ash_debt
	var hp_regen := HP_REGEN * maxf(0.0, 1.0 - WOUND_REGEN * wd)

	# Yük.
	var load_max := LOAD_BASE + LOAD_GRIP * g + _num(m.get("load"), 0.0) + float(gr["load"])
	var load_frac := maxf(0.0, _num(input.get("load"), 0.0)) / load_max if load_max > 0.0 else 0.0
	var slow_from := minf(0.95, maxf(0.0, _num(m.get("slowFrom"), 0.0)))
	var load_mul := 1.0 - LOAD_SLOW * minf(1.0, maxf(0.0, (load_frac - slow_from) / (1.0 - slow_from)))

	# Zemin (act1.md §9.2): Derin Kar hızı ve dolumu, barınağın dolumu.
	var deep: bool = e.get("ground") == "deep"
	var shelter: bool = e.get("shelter") == true or e.get("ground") == "shelter"
	var ground_speed := _num(m.get("deepSnowSpeed"), DEEP_SPEED) * float(gr["snowSpeed"]) if deep else 1.0
	var ground_regen := _num(m.get("deepSnowRegen"), DEEP_REGEN) if deep else (SHELTER_REGEN if shelter else 1.0)

	# Stamina: Soluk ≥7 açlık cezasını, ≥9 yara cezasının yarısını kaldırır (§2.1).
	var hungry := full < HUNGRY
	var sta_max := STA_BASE + STA_WIND * (w - BASE) + _num(bf.get("sta"), 0.0) - STA_WOUND * wd * (0.5 if w >= 9.0 else 1.0)
	var run_drain := RUN_DRAIN * (1.0 - 0.02 * (w - BASE)) * (1.0 + load_frac)
	var sta_regen_k := (1.0 + 0.04 * (w - BASE)) * (0.6 if hungry and w < 7.0 else 1.0) * ground_regen * _num(bf.get("staRegen"), 1.0) \
		* _num(dif.get("staRegen"), 1.0)

	# Son Diş (last_tooth): yara sınırın bir altındayken hız ×mods.speed; hasar çarpanı Combat'ındır.
	var limit := _num(dif.get("woundLimit"), 3.0)
	var last_tooth := _is_num(m.get("speed")) and wd > 0.0 and wd == limit - 1.0
	var tooth_k := float(m["speed"]) if last_tooth else 1.0
	var crouch := CROUCH * (1.0 + 0.02 * (f - BASE)) * tooth_k
	var walk := WALK * (1.0 + 0.012 * (f - BASE)) * tooth_k
	var run := RUN * (1.0 + 0.015 * (f - BASE)) * (1.0 - 0.03 * wd) * (0.95 if hungry else 1.0) * float(gr["runMul"]) \
		* _num(bf.get("runMul"), 1.0) * tooth_k

	# Vuruş, toplama, sapan: Bilek puanı başına +%6.
	var melee_mul := 1.0 + 0.06 * (g - BASE)

	# Yay: çekiş eşiği pull (pull 0 Bilek okumaz), Göz menzil ve hasar, ıslak kiriş, İnce İş (§2.3, §7.2).
	var bow_ref: Variant = input.get("bow") if input.get("bow") != null else gr.get("bow")
	var b: Variant = bow_of(bow_ref, input.get("bows"))
	var row: Dictionary = (b as Dictionary)["row"] if b != null else {}
	var pull := _num(row.get("pull"), 0.0)
	var pull_f := pull_factor(pull, g)
	var eye_k := 1.0 + 0.02 * (ey - BASE)
	var wet_bow := step_wet(e.get("wetBow")) * _bow_wet_k(b) * _num(dif.get("wetBowK"), 1.0)
	var wet_k := 1.0 - WET_DMG * wet_bow
	var fine: bool = b != null and (b as Dictionary)["fine"]
	var arrow_k := pull_f * eye_k * wet_k * (FINE_K if fine else 1.0)
	var draw_k := (1.0 if g >= pull else 1.0 + 0.2 * (pull - g)) * _num(m.get("draw"), 1.0) * float(gr["drawMul"]) * (1.0 + WET_DRAW * wet_bow)
	var spread_k := maxf(SPREAD_MIN, (1.0 - 0.05 * (ey - BASE)) * _num(m.get("spread"), 1.0) * float(gr["spreadMul"]))
	var draw_t: Variant = _num(row.get("draw"), 0.0) * draw_k if b != null else null
	var spread: Variant = _num(row.get("spread"), 0.0) * spread_k if b != null else null
	var range_m: Variant = _num(row.get("range"), 0.0) * eye_k * (1.0 - WET_RANGE * wet_bow) if b != null else null
	var ride_draw_t: Variant = float(draw_t) * float(gr["saddleDrawMul"]) if draw_t != null else null
	var gallop_draw_t: Variant = float(ride_draw_t) * (1.0 + GALLOP_DRAW * _num(m.get("gallopDrawPenalty"), 1.0)) if ride_draw_t != null else null
	var ride_spread: Variant = float(spread) * RIDE_SPREAD * _num(m.get("rideSpread"), 1.0) * float(gr["saddleSpreadMul"]) if spread != null else null

	# Gizlilik: çan ya da adım; dururken 0 (§2.3 noiseR; kar adımı çömelik tabanını ezer).
	var bell := _dict(input.get("bell"))
	var bell_on: bool = bell.get("on") == true
	var noise_table: Dictionary = BELL_ON if bell_on else BELL_OFF
	var plug_k := PLUG if bell_on and bell.get("plug", false) else 1.0
	var noise_add := -0.2 * (f - BASE) + float(gr["noise"])
	var crouch_noise := float(m["noiseCrouch"]) if _is_num(m.get("noiseCrouch")) else float(noise_table["crouch"])
	var noise_r := {
		"still": 0.0,
		"crouch": maxf(0.0, crouch_noise * plug_k + noise_add),
		"walk": maxf(0.0, float(noise_table["walk"]) * plug_k + noise_add),
		"run": maxf(0.0, float(noise_table["run"]) * plug_k + noise_add),
	}
	var sense := 6.0 + 3.0 * ey + _num(m.get("sense"), 0.0)

	# Atlı ve binek.
	var bond_v := minf(100.0, maxf(0.0, _num(input.get("bond"), 0.0)))
	var k := bond_v / 100.0
	var mount: Variant = input.get("mount") if input.get("mount") is Dictionary else null
	var md := _dict(mount)
	var mount_l := maxf(0.0, _num(md.get("load"), 0.0)) / float(md["cap"]) if mount != null and _num(md.get("cap"), 0.0) > 0.0 else 0.0
	var load_k_mount := mount_load_k(mount_l)
	var gallop: Variant = (_num(md.get("base"), 0.0) + BOND_GALLOP * bond_v + _num(m.get("gallop"), 0.0) + float(gr["gallop"])) * load_k_mount if mount != null else null
	var kut := _num(axes.get("kut"), 0.0)
	var blizzard: bool = e.get("blizzard", false) == true
	var tipi_drain := TIPI * (TIPI_R1 if e.get("route") == "R1" else 1.0) * (TIPI_KUT if kut >= 5.0 else 1.0) if blizzard else 1.0
	var saddled: Variant = md.get("saddled") if md.get("saddled") != null else gr.get("saddled")
	var bareback: bool = saddled is bool and saddled == false
	var horse_drain := (DRAIN_BASE - DRAIN_BOND * k) * _num(m.get("horseDrain"), 1.0) * (BAREBACK if bareback else 1.0) * tipi_drain
	var horse_regen := (REGEN_HORSE + REGEN_BOND * k) * (2.0 if shelter else (0.7 if blizzard else 1.0))
	var turn_k := _num(m.get("turn"), 1.0) * float(gr["turnMul"])

	# Söz: Güven, birlik sadakati, takas (§2.1); Korku eşiği Güven kazancını keser (§5.2).
	var word_k := 1.0 + 0.06 * (v - BASE)
	var dread := dread_effects(_num(axes.get("korku"), 0.0))
	var dr_in: Dictionary = gr["dr"]
	var dr := {}
	for t in DR_TYPES:
		dr[t] = minf(0.6, maxf(-0.25, float(dr_in[t]) / 100.0))

	return {
		"stats": st,
		"gear": gr,
		"mods": m,
		"hpMax": hp_max,
		"hpRegen": hp_regen,
		"ashDebt": ash_debt,
		"staMax": sta_max,
		"runDrain": run_drain,
		"staRegenK": sta_regen_k,
		"staRegen": {"still": REGEN_STILL * sta_regen_k, "moving": REGEN_MOVING * sta_regen_k},
		"jumpCost": JUMP_COST,
		"exhaustedUntil": EXHAUSTED_UNTIL,
		"crouch": crouch,
		"walk": walk,
		"run": run,
		"groundSpeed": ground_speed,
		"lastTooth": last_tooth,
		"loadMax": load_max,
		"loadFrac": load_frac,
		"loadMul": load_mul,
		"slowFrom": slow_from,
		"canRun": load_frac <= RUN_LOAD,
		"canJump": load_frac <= JUMP_LOAD,
		"dodgeT": _num(m.get("dodgeT"), DODGE_T),
		"dodgeCost": maxf(DODGE_MIN, _num(m.get("dodgeCost"), DODGE_COST) - 0.5 * (f - BASE)),
		"dodgeCharges": 2 if f >= 8.0 else 1,
		"dr": dr,
		"meleeMul": melee_mul,
		"strikeMul": melee_mul,
		"slingDmg": SLING_DMG * melee_mul,
		"slingRange": _num(m.get("slingRange"), SLING_RANGE) + (ey - BASE),
		"slingStun": _num(m.get("slingStun"), SLING_STUN),
		"slingReload": SLING_RELOAD,
		"bow": (b as Dictionary)["id"] if b != null else null,
		"pullF": pull_f,
		"eyeK": eye_k,
		"wetBow": wet_bow,
		"wetK": wet_k,
		"arrowK": arrow_k,
		"pen": minf(1.0, maxf(0.0, _num(m.get("pen"), 0.0))),
		"drawT": draw_t,
		"spreadK": spread_k,
		"spread": spread,
		"range": range_m,
		"saddleShot": m.get("saddleShot") == true,
		"rideDrawT": ride_draw_t,
		"gallopDrawT": gallop_draw_t,
		"rideSpread": ride_spread,
		"sense": sense,
		"oreSense": sense + _num(m.get("oreSense"), 0.0),
		"trackK": gr["trackMul"],
		"noiseR": noise_r,
		"visBase": float(gr["visMul"]) * _num(bf.get("visMul"), 1.0),
		"trustGainK": word_k * _num(m.get("trustGain"), 1.0) * float(dread["trustGainK"]),
		"loyaltyK": word_k,
		"barterK": 1.0 - 0.03 * (v - BASE),
		"canMount": m.get("mount") == true,
		"bondGainK": _num(m.get("bondGain"), 1.0),
		"mountLoadK": load_k_mount,
		"canGallop": mount_l <= MOUNT_GALLOP,
		"gallop": gallop,
		"spur": _num(md.get("spur"), SPUR) if mount != null else 0.0,
		"horseDrain": horse_drain,
		"horseRegen": horse_regen,
		"turnRate": {"still": TURN_STILL * turn_k, "top": TURN_TOP * turn_k},
		"cartSpeed": _num(m.get("cartSpeed"), 0.0),
		"jolt": _num(m.get("jolt"), 1.0),
		# Stat eşikleri (§2.1): kendi sayısını değiştirenler; içerik açan eşikler koşul dilindedir (stat.word>=5 …).
		"thresholds": {
			"carryMan": 1.5 if g >= 6.0 else 1.2,
			"ropeBreak": g >= 10.0,
			"breathK": 1.15 if w >= 5.0 else 1.0,
			"climbK": 0.6 if f >= 6.0 else 1.0,
			"guardMarkR": 6.0 if ey >= 5.0 else 0.0,
			"arrowWarn": 0.1 if ey >= 7.0 else 0.0,
			"autoLead": ey >= 9.0,
		},
	}
