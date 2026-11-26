class_name WaitPlan
extends RefCounted
## Bekle tekerinin satırları (saf; K20, K45; time.md §6.3, §7.1–§7.4, §11; survival.md §2.7, §7.4; Yol Haritası wait-sleep). Kip, saat ve
## bağlamdan tekerin satırlarını kurar; tekeri (WaitWheel) ve sınamayı besler. Düğüm, ağaç, girdi ve duvar saati okumaz.
##
## Kipler ve satırlar (en çok altı; 1–6 ya da tık seçer):
##   wait   Bekle: «Bir saat», «Üç saat», sonra sıradaki dört evrenin başı («Akşama dek» …; «Tan ağarana dek» Tan'ın başı). Her yerde.
##   rest   Dinlen (ateş başı): Bekle'nin satırları, atlamanın nedeni «rest» (Tokluk ×0,5, Stamina hemen dolar, ≥2 sa ve Tokluk ≥25'te
##          6 oyun saatinde bir Yara −1; survival.md §2.7).
##   sleep  Uyu (döşekte): «Tanla uyan» (sivil şafak), «Güneşle uyan» (doğuş + 30 dk); yalnız Akşam ve Gece evrelerinde açık, sonra
##          «Bir saat», «Üç saat» ve sıradaki iki evre (beklemek döşekte de olur).
##   work   Çalış (şantiyede): «Bir saat çalış», «Üç saat çalış», «Akşama dek çalış», «Bitene dek çalış» (şantiyenin kalan süresi); Çocukta
##          yalnız «Bir saat yardım et». Tokluk <25 ise satırlar kapalı: «Önce bir şey ye.»
## Sınırlar: tek bekleme ve çalışma ≤12 oyun saati; «Tan ağarana dek» ve uyku ≤15. Sınırı aşan, bekleyişi geçen (clock.holds) ya da
## bağlamın yasakladığı satır soluktur, nedenini söyler. Atlama yalnız ileri gider; ≤3 sa bekleme, dinlenme ve çalışma görünür akıştır
## (GameClock.begin_lapse; 1,8 sn), uzun bekleme ve uyku karartma altında tek atlamadır (GameClock.skip). 24 saatten uzun atlama tek
## skipped sinyalidir (GameClock): teker en çok 15 sa atlattığı için onu kurmaz; Kronik ve atlas kendi yollarıyla kurar.
##   var rows := WaitPlan.rows(&"wait", clock, {"lang": "tr"})
##   rows[0]  # {id: "h1", label: "Bir saat", minutes: 60, target: abs, at_text: "→ 15:46", reason: &"wait", sleep: false,
##            #  lapse: true, enabled: true, why: ""}

const MODES: Array[StringName] = [&"wait", &"rest", &"sleep", &"work"]
## Tek bekleme ve çalışmanın en uzunu; «Tan ağarana dek» ve uykunun en uzunu (oyun dk).
const MAX_WAIT_MIN := 720.0
const MAX_LONG_MIN := 900.0
## Bu süreye dek (dahil) atlama görünür akıştır (time.md §7.2), üstü karartma.
const LAPSE_MAX_MIN := 180.0
## Görünür akışın ve uzun atlamanın süreleri (gerçek sn; time.md §7.2).
const LAPSE_SECONDS := 1.8
const LAPSE_DIP := 0.25
const LAPSE_OPEN := 0.5
const FADE_OUT := 0.6
const ARC_TURN := 1.6
const FADE_IN := 0.8
## Çalışmanın ve dinlenmenin Tokluk eşiği (survival.md §2.7; time.md §7.1).
const HUNGER_MIN := 25.0
## Dinlenmenin yarayı kapatan en kısa süresi ve bir yaranın süresi (oyun dk; survival.md §2.7).
const REST_HEAL_MIN := 120.0
const REST_WOUND_EVERY := 360.0
## Uykunun yaraları kapatan en kısa süresi (oyun dk; K45).
const SLEEP_HEAL_MIN := 240.0
## Uyanışta günü sayılan hikâye günleri (I. Perde: Gün I–VI ve Son Gece).
const STORY_DAYS := 7
## Uykunun açık olduğu evreler.
const SLEEP_PHASES: Array[StringName] = [&"dusk", &"night"]
## Evrenin başının yedeği (yer yoksa: gün dakikası).
const PHASE_FALLBACK := {&"dawn": 330.0, &"morning": 480.0, &"noon": 720.0, &"golden": 900.0, &"dusk": 1110.0, &"night": 1200.0}
## Metinler (time.md §11): anahtar → [TR, EN].
const TEXT := {
	"title.wait": ["Bekle", "Wait"], "title.rest": ["Dinlen", "Rest"], "title.sleep": ["Uyu", "Sleep"], "title.work": ["Çalış", "Work"],
	"h1": ["Bir saat", "One hour"], "h3": ["Üç saat", "Three hours"],
	"to.morning": ["Sabaha dek", "Until morning"], "to.noon": ["Öğleye dek", "Until midday"], "to.golden": ["İkindiye dek", "Until afternoon"],
	"to.dusk": ["Akşama dek", "Until evening"], "to.night": ["Geceye dek", "Until nightfall"], "to.dawn": ["Tan ağarana dek", "Until first light"],
	"sleep.dawn": ["Tanla uyan", "Wake at first light"], "sleep.sun": ["Güneşle uyan", "Wake with the sun"],
	"work.h1": ["Bir saat çalış", "Work for an hour"], "work.h3": ["Üç saat çalış", "Work for three hours"],
	"work.to_evening": ["Akşama dek çalış", "Work until evening"], "work.to_done": ["Bitene dek çalış", "Work until it's done"],
	"work.child": ["Bir saat yardım et", "Help for an hour"],
	"deny.danger": ["Tehlike yakınken beklenmez.", "You cannot wait with danger this close."],
	"deny.watched": ["Gözler üstündeyken beklenmez.", "You cannot wait while you are watched."],
	"deny.moving": ["Atı durdur.", "Rein in first."],
	"deny.bed": ["Uyumak için bir döşek gerek.", "You need a bed to sleep."],
	"deny.early": ["Uyku vakti değil.", "It is not yet time to sleep."],
	"deny.hungry": ["Önce bir şey ye.", "Eat something first."],
	"deny.long": ["En çok on iki saat beklenir.", "You can wait twelve hours at most."],
	"deny.sleep_long": ["En çok on beş saat uyunur.", "You can sleep fifteen hours at most."],
	"deny.no_site": ["Burada bitecek bir iş yok.", "There is no work here to finish."],
	"deny.hold": ["Şafak seni bekliyor: %s", "Dawn is waiting for you: %s"],
	"deny.hold_plain": ["Şafak seni bekliyor.", "Dawn is waiting for you."],
	"day": ["Gün %s", "Day %s"],
	"keys": ["Seç", "Choose"], "close": ["Kapat", "Close"],
	"phase.dawn": ["Tan", "Dawn"], "phase.morning": ["Sabah", "Morning"], "phase.noon": ["Öğle", "Midday"],
	"phase.golden": ["İkindi", "Afternoon"], "phase.dusk": ["Akşam", "Evening"], "phase.night": ["Gece", "Night"],
	"phase_lc.dawn": ["tan", "dawn"], "phase_lc.morning": ["sabah", "morning"], "phase_lc.noon": ["öğle", "midday"],
	"phase_lc.golden": ["ikindi", "afternoon"], "phase_lc.dusk": ["akşam", "evening"], "phase_lc.night": ["gece", "night"],
}


## Metin (dil "tr" ya da "en"; bilinmeyen anahtar kendisi).
static func text(key: String, lang: String = "tr") -> String:
	var pair: Variant = TEXT.get(key)
	if not pair is Array:
		return key
	return str(pair[1] if lang == "en" else pair[0])


## Evrenin adı (Tan, Sabah …).
static func phase_name(phase: StringName, lang: String = "tr") -> String:
	return text("phase.%s" % phase, lang) if not String(phase).is_empty() else ""


## Kipin başlığı (Bekle, Dinlen, Uyu, Çalış).
static func title(mode: StringName, lang: String = "tr") -> String:
	return text("title.%s" % mode, lang)


## Satırlar. ctx: lang ("tr"), child (Çocuk: Çalış'ta yalnız «yardım et»), fullness (Tokluk 0–100; bilinmiyorsa eksi), site_eta (şantiyenin
## kalan iş dakikası; yoksa eksi), deny (bağlamın yasağı: «Atı durdur.» …; doluysa bütün satırlar soluk).
static func rows(mode: StringName, clock: GameClock, ctx: Dictionary = {}) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if clock == null:
		return out
	var lang := str(ctx.get("lang", "tr"))
	match mode:
		&"sleep":
			out.append(_row("sleep_dawn", text("sleep.dawn", lang), clock.next("civil_dawn"), clock, &"sleep", true))
			out.append(_row("sleep_sun", text("sleep.sun", lang), clock.next("sunrise+30"), clock, &"sleep", true))
			out.append(_row("h1", text("h1", lang), clock.abs_minute() + 60.0, clock, &"wait"))
			out.append(_row("h3", text("h3", lang), clock.abs_minute() + 180.0, clock, &"wait"))
			for p: StringName in upcoming_phases(clock, 2):
				out.append(_row("to_%s" % p, text("to.%s" % p, lang), phase_start(clock, p), clock, &"wait"))
		&"work":
			if bool(ctx.get("child", false)):
				out.append(_row("work_child", text("work.child", lang), clock.abs_minute() + 60.0, clock, &"work"))
			else:
				out.append(_row("work_h1", text("work.h1", lang), clock.abs_minute() + 60.0, clock, &"work"))
				out.append(_row("work_h3", text("work.h3", lang), clock.abs_minute() + 180.0, clock, &"work"))
				out.append(_row("work_evening", text("work.to_evening", lang), phase_start(clock, &"dusk"), clock, &"work"))
				var eta := float(ctx.get("site_eta", -1.0))
				var done := _row("work_done", text("work.to_done", lang), clock.abs_minute() + eta if eta > 0.0 else NAN, clock, &"work")
				if eta <= 0.0:
					done["enabled"] = false
					done["why"] = text("deny.no_site", lang)
				out.append(done)
		_:
			var reason: StringName = &"rest" if mode == &"rest" else &"wait"
			out.append(_row("h1", text("h1", lang), clock.abs_minute() + 60.0, clock, reason))
			out.append(_row("h3", text("h3", lang), clock.abs_minute() + 180.0, clock, reason))
			for p: StringName in upcoming_phases(clock, 4):
				out.append(_row("to_%s" % p, text("to.%s" % p, lang), phase_start(clock, p), clock, reason))
	_gate(out, mode, clock, ctx, lang)
	return out


## Şimdiden sonraki ilk n evre başı, sırayla (şimdi başlayan sayılmaz).
static func upcoming_phases(clock: GameClock, n: int) -> Array[StringName]:
	var starts: Array = []
	for p: StringName in Daylight.PHASES:
		var t := phase_start(clock, p)
		if is_finite(t) and t - clock.abs_minute() > 0.5:
			starts.append([t, p])
	starts.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var out: Array[StringName] = []
	for pair: Array in starts:
		if out.size() >= n:
			break
		out.append(pair[1])
	return out


## Evrenin sıradaki başı (mutlak dk): yerli saatte günün ışığından, yersizde yedek dakikadan.
static func phase_start(clock: GameClock, phase: StringName) -> float:
	if clock.has_place():
		var t := clock.next(phase)
		if is_finite(t) and t - clock.abs_minute() <= 0.5:
			t = clock.at(phase, clock.day_n + 1)
		return t
	var m := float(PHASE_FALLBACK.get(phase, NAN))
	if is_nan(m):
		return NAN
	var today := GameClock.abs_of(clock.day_n, m)
	return today if today - clock.abs_minute() > 0.5 else GameClock.abs_of(clock.day_n + 1, m)


## Satırın atlaması görünür akış mı (≤3 sa bekleme, dinlenme ya da çalışma)?
static func is_lapse(row: Dictionary) -> bool:
	return not bool(row.get("sleep", false)) and float(row.get("minutes", 0.0)) <= LAPSE_MAX_MIN + 1e-6


## Dinlenmenin kapattığı yara (survival.md §2.7): ≥2 sa ve Tokluk ≥25 ise 6 oyun saatinde bir (en az bir).
static func rest_wounds_healed(minutes: float, fullness: float) -> int:
	if minutes + 1e-6 < REST_HEAL_MIN or (fullness >= 0.0 and fullness < HUNGER_MIN):
		return 0
	return maxi(1, floori((minutes + 1e-6) / REST_WOUND_EVERY))


## Uyanışın kısa bildirimi (time.md §7.2, §11): I. Perde'nin rehine günlerinde (Gün I–VI ve Son Gece) «Gün III, tan», öteki yerde tarih
## ve evre («12 Nisan MÖ 209, sabah»).
static func woke_text(clock: GameClock, story: bool, story_day: int, lang: String = "tr") -> String:
	var counted := story and story_day >= 1 and story_day <= STORY_DAYS
	var head := text("day", lang) % roman(story_day) if counted else GameCalendar.format(clock.day_n, lang)
	var phase := text("phase_lc.%s" % clock.phase(), lang) if not String(clock.phase()).is_empty() else ""
	return head if phase.is_empty() else "%s, %s" % [head, phase]


## Roma rakamı (1–3999; hikâye günleri: Gün I … Gün VI).
static func roman(n: int) -> String:
	if n <= 0:
		return str(n)
	var vals := [1000, 900, 500, 400, 100, 90, 50, 40, 10, 9, 5, 4, 1]
	var syms := ["M", "CM", "D", "CD", "C", "XC", "L", "XL", "X", "IX", "V", "IV", "I"]
	var out := ""
	var left := mini(n, 3999)
	for i in vals.size():
		while left >= int(vals[i]):
			out += str(syms[i])
			left -= int(vals[i])
	return out


# --- İç -------------------------------------------------------------------------------------------------------------

static func _row(id: String, label: String, target: float, clock: GameClock, reason: StringName, sleep: bool = false) -> Dictionary:
	var minutes := target - clock.abs_minute() if is_finite(target) else NAN
	var row := {"id": id, "label": label, "target": target, "minutes": minutes, "reason": reason, "sleep": sleep, "enabled": is_finite(target),
		"why": "", "at_text": ""}
	if is_finite(target):
		var d := floori(target / GameClock.DAY_MIN)
		row["at_text"] = "→ " + GameClock.hhmm(target - float(d) * GameClock.DAY_MIN)
	row["lapse"] = is_lapse(row)
	return row


## Satırları kapatır: bağlamın yasağı, uyku vakti, Tokluk, süre sınırı, bekleyiş.
static func _gate(out: Array[Dictionary], mode: StringName, clock: GameClock, ctx: Dictionary, lang: String) -> void:
	var deny := str(ctx.get("deny", ""))
	var fullness := float(ctx.get("fullness", -1.0))
	var phase := clock.phase()
	var held := _first_hold(clock)
	for row: Dictionary in out:
		if not bool(row["enabled"]):
			continue
		var why := ""
		var minutes := float(row["minutes"])
		if not deny.is_empty():
			why = deny
		elif bool(row["sleep"]) and not phase.is_empty() and not SLEEP_PHASES.has(phase):
			why = text("deny.early", lang)
		elif mode == &"work" and fullness >= 0.0 and fullness < HUNGER_MIN:
			why = text("deny.hungry", lang)
		elif bool(row["sleep"]) and minutes > MAX_LONG_MIN + 1e-6:
			why = text("deny.sleep_long", lang)
		elif not bool(row["sleep"]) and minutes > (MAX_LONG_MIN if str(row["id"]) == "to_dawn" else MAX_WAIT_MIN) + 1e-6:
			why = text("deny.long", lang)
		elif not held.is_empty() and float(held["at"]) <= float(row["target"]) + 1e-6:
			var note := str(held.get("note", ""))
			why = text("deny.hold", lang) % note if not note.is_empty() else text("deny.hold_plain", lang)
		if not why.is_empty():
			row["enabled"] = false
			row["why"] = why


## Şimdiden sonraki ilk tutmamış bekleyiş (yoksa boş).
static func _first_hold(clock: GameClock) -> Dictionary:
	var best: Dictionary = {}
	for h: Dictionary in clock.holds():
		if bool(h.get("on", false)) or float(h["at"]) <= clock.abs_minute() + 1e-6:
			continue
		if best.is_empty() or float(h["at"]) < float(best["at"]):
			best = h
	return best
