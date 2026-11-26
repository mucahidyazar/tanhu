class_name Effects
extends RefCounted
## Etki dili (godot.md §3 «Görev ve diyalog»; architecture.md §3.14'ün tablosu; prototipin src/game/effects.js'i): görev, diyalog ve
## sinema verisindeki etki dizilerini ([op, ...]) sırayla hizmet çağrılarına çevirir. Saftır: hizmetler dışarıdan verilir (Session
## kurar, sınama sahte nesne verir). Bozuk etki listeyi durdurmaz: hatası döner, dev açıksa push_error ile yazılır, kapalıysa uyarıdır.
##
##   var errors := Effects.apply([["flag", "met_eskam"], ["give", "meal", 2, "first_meal"], ["clock", "set", "13:30"]], services, "mq_ration")
##   Effects.check(list)   # yalnız biçim denetimi (veri sınaması): bilinmeyen op, eksik ya da yanlış türde değişken, okunmayan koşul
##
## Hizmetler (services: Dictionary; ad → nesne). Op'un hizmeti yoksa etki hatadır; hava (weather) yoksa op yok sayılır:
##   flags      Journey (set_flag, get_flag, push_flag) ya da işaret sözlüğü (JourneyFlags.push ile)
##   clock      GameClock: skip, next («hh:mm», evre ya da çapa), day_n, abs_minute, hold, release
##   cond       Cond.Ctx («if» op'u; yoksa işaret sözlüğünden kurulur)
##   progress   add_xp(n, src), teach(skill), grant_point(id) (Progression); set_axis(axis, n, opts {once, src}), add_ties(npc, n),
##              reveal(atlas), oath(id, state) (eksenler, atlas ve antlar: sahipleri gelince aynı hizmete ya da ayrı hizmete)
##   inventory  add(item, n, src, allow_over), remove(ref, n)   (Inventory: scripts/sim/economy/inventory.gd)
##   quests     start(id), force_step(qid, step_id)
##   dialogue   start(id), bark(line_ref)
##   travel     set_station(id, state), set_route(id, state)
##   regions    set_rank(n), open(id)
##   supply     get_ledger(place) → add(line, n)       (winter_camp, own_seat, own_camp, field_camp)
##   audio      set_music_state(state), play_sfx(id)
##   cine       play(id)
##   weather    lock, release, progress, pin, freeze, calm, flash, strike, gap (weather.md §6.1)
##   structures get_structure(id) → set_stage, ensure_stage, tear, ignite, cut_roof, begin_heave (prototipin camelCase adı da okunur)
##   ui         card(key), toast(key)                  (anahtar oyuncu dizgesidir: Catalog.text)
##   bus        emit_event(name, payload)              (Session.event sinyali)
##   dev        bool (varsayılan true)

## op → [en az, en çok] değişken sayısı (op'un kendisi sayılmaz; -1 sınırsız).
const OPS := {
	"flag": [1, 2], "push": [2, 2], "axis": [2, 3], "ties": [2, 2], "xp": [1, 2],
	"give": [1, 3], "take": [1, 2], "teach": [1, 1], "point": [1, 1],
	"quest": [1, 1], "step": [2, 2], "dialogue": [1, 1], "bark": [1, 1],
	"reveal": [1, 1], "station": [2, 2], "route": [2, 2], "rank": [1, 1], "region": [1, 1],
	"clock": [1, 3], "ledger": [2, 3], "music": [1, 1], "sfx": [1, 1], "cine": [1, 1],
	"weather": [1, -1], "structure": [2, -1], "oath": [2, 2], "card": [1, 1], "toast": [1, 1],
	"emit": [1, 2], "if": [2, 3],
}
const CLOCK_VERBS: Array[String] = ["set", "atLeast", "advance", "hold", "release"]
## Hikâyenin kurduğu bekleyişler (time.md §6.3); home_golden saatin kendisinindir.
const STORY_HOLDS: Array[String] = ["dawn_line", "ice_story"]
const WEATHER_DO: Array[String] = ["lock", "release", "progress", "pin", "freeze", "calm", "flash", "strike", "gap"]
## Yapı yöntemleri: prototipin adı → Godot adı.
const STRUCTURE_METHODS := {
	"setStage": "set_stage", "ensureStage": "ensure_stage", "tear": "tear", "ignite": "ignite", "cutRoof": "cut_roof",
	"beginHeave": "begin_heave",
}
const LEDGER_PLACES: Array[String] = ["winter_camp", "own_seat", "own_camp", "field_camp"]
const WINTER_LEDGER := "winter_camp"
## Hikâye kesmesinin atlama nedeni (time.md §7.4): sistemler atlanan süreyi işler, oto kayıt yazılmaz.
const CUT_REASON := &"cine"
const DAY_MIN := 1440.0
## Bir kez verilen eşyanın ve gösterilen kartın bayrak öneki (kayıtla taşınır).
const GIVEN_PREFIX := "_given."
const CARD_PREFIX := "_card."


## Etkileri sırayla uygular. Döner: hatalar (boşsa hepsi uygulandı). Hatalı etki atlanır, sonraki sürer.
static func apply(list: Variant, services: Dictionary, source: String = "") -> PackedStringArray:
	var errors := PackedStringArray()
	_apply_into(list, services, source, errors)
	if not errors.is_empty():
		var dev := bool(services.get("dev", true))
		for e in errors:
			if dev:
				push_error(e)
			else:
				push_warning(e)
	return errors


## Listenin biçim denetimi (veri sınaması; hizmet gerekmez). Döner: hatalar.
static func check(list: Variant, source: String = "") -> PackedStringArray:
	var errors := PackedStringArray()
	if list == null:
		return errors
	if not list is Array:
		errors.append(_msg("etki listesi dizi değil: %s" % _short(list), source))
		return errors
	for fx: Variant in list:
		var e := check_one(fx, source)
		if not e.is_empty():
			errors.append(e)
		elif fx is Array and str(fx[0]) == "if":
			errors.append_array(check(fx[2], source))
			if (fx as Array).size() > 3:
				errors.append_array(check(fx[3], source))
	return errors


## Tek etkinin biçim denetimi (iç içe «if» listeleri hariç). Döner: hata ya da "".
static func check_one(fx: Variant, source: String = "") -> String:
	if not fx is Array or (fx as Array).is_empty():
		return _msg("etki [op, ...] dizisi olmalı: %s" % _short(fx), source)
	var a := fx as Array
	var op := str(a[0])
	if not OPS.has(op):
		return _msg("bilinmeyen op %s" % _short(fx), source)
	var n := a.size() - 1
	var lo: int = OPS[op][0]
	var hi: int = OPS[op][1]
	if n < lo or (hi >= 0 and n > hi):
		return _msg("%s: değişken sayısı %d (%d–%s olmalı) %s" % [op, n, lo, "∞" if hi < 0 else str(hi), _short(fx)], source)
	match op:
		"flag", "teach", "point", "quest", "dialogue", "bark", "reveal", "region", "music", "sfx", "cine", "card", "toast", "emit":
			if not _is_text(a[1]):
				return _msg("%s: ilk değişken kimlik olmalı %s" % [op, _short(fx)], source)
		"push":
			if not _is_text(a[1]):
				return _msg("push: anahtar kimlik olmalı %s" % _short(fx), source)
		"axis":
			if not _is_text(a[1]) or not _is_number(a[2]) or (n > 2 and a[3] != null and not _is_text(a[3])):
				return _msg("axis: [axis, ad, sayı, once?] %s" % _short(fx), source)
		"ties":
			if not _is_text(a[1]) or not _is_number(a[2]):
				return _msg("ties: [ties, kişi, sayı] %s" % _short(fx), source)
		"xp":
			if not _is_number(a[1]) or (n > 1 and not _is_text(a[2])):
				return _msg("xp: [xp, sayı, kaynak?] %s" % _short(fx), source)
		"give":
			if not _is_text(a[1]) or (n > 1 and not _is_number(a[2])) or (n > 2 and a[3] != null and not _is_text(a[3])):
				return _msg("give: [give, eşya, adet?, once?] %s" % _short(fx), source)
		"take":
			if not _is_text(a[1]) or (n > 1 and not _is_number(a[2])):
				return _msg("take: [take, eşya ya da tag:x, adet?] %s" % _short(fx), source)
		"step", "station", "route", "oath":
			if not _is_text(a[1]) or not _is_text(a[2]):
				return _msg("%s: iki kimlik ister %s" % [op, _short(fx)], source)
		"rank":
			if not _is_number(a[1]):
				return _msg("rank: sayı ister %s" % _short(fx), source)
		"clock":
			return _check_clock(a, source)
		"ledger":
			if not _is_text(a[1]) or not _is_number(a[2]):
				return _msg("ledger: [ledger, satır, sayı, yer?] %s" % _short(fx), source)
			if n > 2 and not LEDGER_PLACES.has(str(a[3])):
				return _msg("ledger: bilinmeyen defter «%s» (yalnız %s)" % [a[3], ", ".join(PackedStringArray(LEDGER_PLACES))], source)
		"weather":
			if not WEATHER_DO.has(str(a[1])):
				return _msg("weather: «%s» yok (yalnız %s)" % [a[1], ", ".join(PackedStringArray(WEATHER_DO))], source)
		"structure":
			if not _is_text(a[1]) or _structure_method(str(a[2])).is_empty():
				return _msg("structure: yöntem «%s» izinli değil %s" % [a[2], _short(fx)], source)
		"if":
			if not (a[1] is String):
				return _msg("if: koşul metin olmalı %s" % _short(fx), source)
			var err := Cond.error_of(str(a[1]))
			if not err.is_empty():
				return _msg("if: %s" % err, source)
			if not a[2] is Array or (n > 2 and a[3] != null and not a[3] is Array):
				return _msg("if: dallar etki listesi olmalı %s" % _short(fx), source)
	return ""


# --- Uygulama ---------------------------------------------------------------------------------------------

static func _apply_into(list: Variant, s: Dictionary, source: String, errors: PackedStringArray) -> void:
	if list == null:
		return
	if not list is Array:
		errors.append(_msg("etki listesi dizi değil: %s" % _short(list), source))
		return
	for fx: Variant in list:
		var e := check_one(fx, source)
		if e.is_empty():
			e = _run(fx, s, source, errors)
		if not e.is_empty():
			errors.append(e)


## Tek etkiyi çalıştırır (biçimi denetlenmiş). Döner: hata ya da "".
static func _run(a: Array, s: Dictionary, source: String, errors: PackedStringArray) -> String:
	var op := str(a[0])
	var n := a.size() - 1
	match op:
		"flag":
			return _flag_set(s, str(a[1]), a[2] if n > 1 else true, source)
		"push":
			return _flag_push(s, str(a[1]), a[2], source)
		"axis":
			return _call(s, "progress", "set_axis", [str(a[1]), float(a[2]), {"once": a[3] if n > 2 else null, "src": source}], source)
		"ties":
			return _call(s, "progress", "add_ties", [str(a[1]), float(a[2])], source)
		"xp":
			return _call(s, "progress", "add_xp", [float(a[1]), str(a[2]) if n > 1 else source], source)
		"give":
			# Önce bayrak: eşyanın dinleyicisi oto kayıt yazsa da kayıtta ikisi birlikte bulunur. Görev eşyası yük yüzünden yitmez.
			var once: Variant = a[3] if n > 2 else null
			if once != null:
				var key := GIVEN_PREFIX + str(once)
				if Cond.truthy(_flag_get(s, key)):
					return ""
				var fe := _flag_set(s, key, true, source)
				if not fe.is_empty():
					return fe
			return _call(s, "inventory", "add", [str(a[1]), int(a[2]) if n > 1 else 1, source, true], source)
		"take":
			return _call(s, "inventory", "remove", [str(a[1]), int(a[2]) if n > 1 else 1], source)
		"teach":
			return _call(s, "progress", "teach", [str(a[1])], source)
		"point":
			return _call(s, "progress", "grant_point", [str(a[1])], source)
		"quest":
			return _call(s, "quests", "start", [str(a[1])], source)
		"step":
			return _call(s, "quests", "force_step", [str(a[1]), str(a[2])], source)
		"dialogue":
			return _call(s, "dialogue", "start", [str(a[1])], source)
		"bark":
			return _call(s, "dialogue", "bark", [str(a[1])], source)
		"reveal":
			return _call(s, "progress", "reveal", [str(a[1])], source)
		"station":
			return _call(s, "travel", "set_station", [str(a[1]), str(a[2])], source)
		"route":
			return _call(s, "travel", "set_route", [str(a[1]), str(a[2])], source)
		"rank":
			return _call(s, "regions", "set_rank", [int(a[1])], source)
		"region":
			return _call(s, "regions", "open", [str(a[1])], source)
		"clock":
			return _clock(s, a, source)
		"ledger":
			var place := str(a[3]) if n > 2 else WINTER_LEDGER
			var supply: Variant = s.get("supply")
			if supply == null or not (supply is Object and supply.has_method(&"get_ledger")):
				return _msg("ledger: defter hizmeti (supply) yok", source)
			var ledger: Variant = supply.get_ledger(place)
			if not (ledger is Object and ledger.has_method(&"add")):
				return _msg("ledger: «%s» defteri kayıtlı değil" % place, source)
			ledger.add(str(a[1]), float(a[2]))
			return ""
		"music":
			return _call(s, "audio", "set_music_state", [str(a[1])], source)
		"sfx":
			return _call(s, "audio", "play_sfx", [str(a[1])], source)
		"cine":
			return _call(s, "cine", "play", [str(a[1])], source)
		"weather":
			# Hava sistemi yoksa yok sayılır (weather.md §6.1).
			var weather: Variant = s.get("weather")
			if weather == null:
				return ""
			return _call(s, "weather", str(a[1]), a.slice(2), source)
		"structure":
			var structures: Variant = s.get("structures")
			if not (structures is Object and structures.has_method(&"get_structure")):
				return _msg("structure: yapı hizmeti (structures) yok", source)
			var target: Variant = structures.get_structure(str(a[1]))
			if not target is Object:
				return _msg("structure: bilinmeyen yapı «%s»" % a[1], source)
			var method := _structure_method(str(a[2]))
			if not (target as Object).has_method(method):
				return _msg("structure: «%s» yapısında %s yok" % [a[1], method], source)
			(target as Object).callv(method, a.slice(3))
			return ""
		"oath":
			return _call(s, "progress", "oath", [str(a[1]), str(a[2])], source)
		"card":
			# Bir kez: görüldü bilgisi bayrakta durur, kayıtla taşınır.
			var seen := CARD_PREFIX + str(a[1])
			if Cond.truthy(_flag_get(s, seen)):
				return ""
			var ce := _flag_set(s, seen, true, source)
			if not ce.is_empty():
				return ce
			return _call(s, "ui", "card", [str(a[1])], source)
		"toast":
			return _call(s, "ui", "toast", [str(a[1])], source)
		"emit":
			return _call(s, "bus", "emit_event", [StringName(str(a[1])), a[2] if n > 1 else null], source)
		"if":
			var ctx: Variant = s.get("cond")
			if not ctx is Cond.Ctx:
				ctx = _flags_ctx(s)
			var branch: Variant = a[2] if Cond.holds(str(a[1]), ctx) else (a[3] if n > 2 else null)
			_apply_into(branch, s, source, errors)
			return ""
	return _msg("bilinmeyen op %s" % _short(a), source)


## Saat (K20; time.md §6.4, §12.7). set: o anın şimdiki ya da sonraki ilk anı (bugün ya da yarın); atLeast: bugünkü an henüz gelmediyse
## ona, geçtiyse boşa düşer; advance: dakika ekler. Atlama «cine» nedeniyledir, ilk bekleyişte durur. hold ve release yalnız dawn_line ve
## ice_story içindir; hold'un anı şimdiki ya da sonraki ilk andır. Saat yalnız ileri gider.
static func _clock(s: Dictionary, a: Array, source: String) -> String:
	var clock: Variant = s.get("clock")
	if not clock is Object:
		return _msg("clock: saat hizmeti yok", source)
	var verb := str(a[1])
	match verb:
		"set", "atLeast":
			var to := _next(clock, a[2])
			if is_nan(to):
				return _msg("clock %s %s: an değil" % [verb, _short(a[2])], source)
			if verb == "atLeast" and floori(to / DAY_MIN) != int(clock.day_n):
				return ""
			var minutes: float = to - float(clock.abs_minute())
			if minutes > 0.0:
				clock.skip(minutes, CUT_REASON)
			return ""
		"advance":
			var m := float(a[2])
			if m > 0.0:
				clock.skip(m, CUT_REASON)
			return ""
		"hold":
			if not (clock as Object).has_method(&"hold"):
				return _msg("clock hold: saatte bekleyiş yok", source)
			var at := _next(clock, a[3])
			if is_nan(at):
				return _msg("clock hold %s: an değil" % _short(a[3]), source)
			if not clock.hold(StringName(str(a[2])), at):
				return _msg("clock hold %s kurulamadı" % a[2], source)
			return ""
		"release":
			if not (clock as Object).has_method(&"release"):
				return _msg("clock release: saatte bekleyiş yok", source)
			clock.release(StringName(str(a[2])))
			return ""
	return _msg("clock «%s» izinli değil" % verb, source)


## Hedefin şimdiki ya da sonraki ilk anı (mutlak dk; okunamazsa NAN). Saatin next'i varsa o (evre ve çapa da okur), yoksa «hh:mm».
static func _next(clock: Object, target: Variant) -> float:
	if clock.has_method(&"next"):
		var v: Variant = clock.call(&"next", target)
		return float(v) if (v is float or v is int) else NAN
	var m := GameClock.parse_hhmm(target)
	if m < 0.0:
		return NAN
	var now: float = clock.call(&"abs_minute")
	var at := float(int(clock.get(&"day_n"))) * DAY_MIN + m
	return at + DAY_MIN if at < now - 0.000001 else at


static func _check_clock(a: Array, source: String) -> String:
	var verb := str(a[1])
	if not CLOCK_VERBS.has(verb):
		return _msg("clock «%s» izinli değil (yalnız %s)" % [verb, ", ".join(PackedStringArray(CLOCK_VERBS))], source)
	var n := a.size() - 1
	match verb:
		"set", "atLeast":
			if n != 2 or not (_is_text(a[2]) or _is_number(a[2])):
				return _msg("clock %s: [clock, %s, an] %s" % [verb, verb, _short(a)], source)
		"advance":
			if n != 2 or not _is_number(a[2]) or float(a[2]) < 0.0:
				return _msg("clock advance %s: saat yalnız ileri gider" % _short(a[2] if n > 1 else null), source)
		"hold":
			if n != 3 or not STORY_HOLDS.has(str(a[2])):
				return _msg("clock hold: yalnız %s, [clock, hold, id, an] %s" % [", ".join(PackedStringArray(STORY_HOLDS)), _short(a)], source)
		"release":
			if n != 2 or not STORY_HOLDS.has(str(a[2])):
				return _msg("clock release: yalnız %s %s" % [", ".join(PackedStringArray(STORY_HOLDS)), _short(a)], source)
	return ""


# --- Bayraklar ve hizmetler ---------------------------------------------------------------------------------

static func _flag_get(s: Dictionary, key: String) -> Variant:
	var f: Variant = s.get("flags")
	if f is Dictionary:
		return (f as Dictionary).get(key)
	if f is Object and (f as Object).has_method(&"get_flag"):
		return f.get_flag(key)
	return null


static func _flag_set(s: Dictionary, key: String, value: Variant, source: String) -> String:
	var f: Variant = s.get("flags")
	if f is Dictionary:
		(f as Dictionary)[key] = value
		return ""
	if f is Object and (f as Object).has_method(&"set_flag"):
		f.set_flag(key, value)
		return ""
	return _msg("flag: bayrak hizmeti (flags) yok", source)


static func _flag_push(s: Dictionary, key: String, value: Variant, source: String) -> String:
	var f: Variant = s.get("flags")
	if f is Dictionary:
		JourneyFlags.push(f, key, value)
		return ""
	if f is Object and (f as Object).has_method(&"push_flag"):
		f.push_flag(key, value)
		return ""
	return _msg("push: bayrak hizmeti (flags) yok", source)


## Koşul bağlamı verilmediyse bayraklardan kurulur.
static func _flags_ctx(s: Dictionary) -> Cond.Ctx:
	var f: Variant = s.get("flags")
	if f is Dictionary:
		return Cond.DictCtx.new(f)
	if f is Object and f.get(&"flags") is Dictionary:
		return Cond.DictCtx.new(f.get(&"flags"))
	return Cond.DictCtx.new()


static func _call(s: Dictionary, service: String, method: String, args: Array, source: String) -> String:
	var svc: Variant = s.get(service)
	if not svc is Object or not is_instance_valid(svc):
		return _msg("%s hizmeti yok (%s)" % [service, method], source)
	if not (svc as Object).has_method(method):
		return _msg("%s hizmetinde %s yok" % [service, method], source)
	(svc as Object).callv(method, args)
	return ""


static func _structure_method(name: String) -> String:
	if STRUCTURE_METHODS.has(name):
		return str(STRUCTURE_METHODS[name])
	if STRUCTURE_METHODS.values().has(name):
		return name
	return ""


static func _is_text(v: Variant) -> bool:
	return (v is String or v is StringName) and not String(v).is_empty()


static func _is_number(v: Variant) -> bool:
	return (v is int or v is float) and is_finite(float(v))


static func _short(v: Variant) -> String:
	var t := JSON.stringify(v)
	return t if t.length() <= 120 else t.substr(0, 117) + "..."


static func _msg(text: String, source: String) -> String:
	return "effects: %s%s" % [text, "" if source.is_empty() else " (kaynak: %s)" % source]
