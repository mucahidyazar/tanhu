extends TestCase
## Koşul ve etki dili (Cond, Effects; godot.md §3 «Görev ve diyalog», architecture.md §3.14; Yol Haritası conditions-effects): saf sınamalar.
##   - Cond: öncelik ve ayraç, sayı / bool / kelime / tırnaklı metin kıyası, dizi uzunluğu ve üyeliği, önekli atomlar (geçerli ve
##     geçersiz evre, görev ve vakit durumu), item:ref[:n], okunamayan koşulun yerli hata iletisi, önbellek, atom listesi.
##   - JourneyFlags'in dili genişler, değişmez: verideki bütün koşullar ve eski biçimin tuhaf dizgeleri ("a ||", "a b", "a && *")
##     2026-11-08'den önceki algoritmayla (bu dosyadaki dondurulmuş kopya) her işaret takımında aynı sonucu verir; yeni biçim (ayraç,
##     kıyas) işaretlerde çalışır.
##   - Effects: her op doğru hizmeti çağırır; bayrak, dizi bayrağı, bir kezlik give ve card, if / else, saat (set, atLeast, advance,
##     hold, release; yalnız ileri), hava yoksa yok sayılır, yapı yöntemi eşlemesi, defter; bozuk etki listeyi durdurmaz; check() biçimi
##     hizmetsiz denetler.

const DAY := 1041


func before_each() -> void:
	Cond.clear_cache()


# --- Cond: dil -----------------------------------------------------------------------------------------------

func test_precedence_parentheses_and_not() -> void:
	var ctx := Cond.DictCtx.new({"a": true, "b": false, "c": true})
	assert_true(Cond.holds("a || b && false_flag", ctx), "&& önce bağlanır: a || (b && x)")
	assert_false(Cond.holds("(a || b) && false_flag", ctx), "Ayraç önceliği değiştirir")
	assert_true(Cond.holds("!b && c", ctx), "! en sıkı bağlanır")
	assert_false(Cond.holds("!(a && c)", ctx))
	assert_true(Cond.holds("!!a", ctx))
	assert_true(Cond.holds("  a  ", ctx), "Boşluk önemsiz")
	assert_true(Cond.holds("", ctx), "Boş koşul tutar")
	assert_true(Cond.holds("*", ctx), "«*» tutar")
	assert_false(Cond.holds("missing", ctx), "Bilinmeyen ad yanlış")
	assert_true(Cond.holds("a&&c", ctx), "Boşluksuz işleç")


func test_number_bool_and_word_comparisons() -> void:
	var ctx := Cond.DictCtx.new({
		"trust": 27, "korku": 1.5, "day_n": -5600, "fate": "covered", "spared": true, "names": "3", "word": "abc",
		"first_ten": ["uldin", {"id": "berik"}], "empty": [],
	})
	assert_true(Cond.holds("trust>=27", ctx))
	assert_false(Cond.holds("trust>27", ctx))
	assert_true(Cond.holds("korku<2 && korku>1", ctx), "Kesirli sayı")
	assert_true(Cond.holds("day_n<-5000", ctx), "Eksi sayı")
	assert_true(Cond.holds("trust==27 && trust!=26", ctx))
	assert_true(Cond.holds("missing==0", ctx), "Yok sayıyla kıyasta 0")
	assert_true(Cond.holds("names>=3", ctx), "Sayı metni sayıdır")
	assert_false(Cond.holds("word>=0", ctx), "Sayıya dönmeyen metin sıra kıyasını tutmaz")
	assert_false(Cond.holds("word<0", ctx))
	assert_true(Cond.holds("fate==covered", ctx), "Kelime eşitliği")
	assert_true(Cond.holds("fate!=uncovered", ctx))
	assert_true(Cond.holds("fate=='covered'", ctx), "Tırnaklı metin")
	assert_true(Cond.holds("spared==true && spared!=false", ctx), "Bool kıyası doğruluktur")
	assert_true(Cond.holds("missing==false", ctx))
	assert_true(Cond.holds("first_ten==uldin", ctx), "Dizide üyelik")
	assert_true(Cond.holds("first_ten==berik", ctx), "Sözlük eleman id ile")
	assert_false(Cond.holds("first_ten==mene", ctx))
	assert_true(Cond.holds("first_ten>=2 && first_ten<3", ctx), "Dizi sayıyla kıyasta uzunluğudur")
	assert_true(Cond.holds("first_ten", ctx), "Dolu dizi doğru")
	assert_false(Cond.holds("empty", ctx), "Boş dizi yanlış (prototipin push bayrağı)")
	var spaced := Cond.DictCtx.new({"name": "Kızıl Kazık"})
	assert_true(Cond.holds("name=='Kızıl Kazık'", spaced), "Tırnak içinde boşluk ve Türkçe harf")
	assert_true(Cond.holds("name==\"Kızıl Kazık\"", spaced))


func test_prefixed_atoms_and_items() -> void:
	var ctx := Cond.DictCtx.new({
		"quest:mq_count.done": true, "beat:b_hunt.open": true, "step:mq_ration.share": true, "skill:riding": true,
		"phase:golden": true, "slice:noon": true, "atlas:hexi": true, "tally:farnak": true,
		"item:meal": 2, "item:tag:wood": 5,
	})
	for expr in ["quest:mq_count.done", "beat:b_hunt.open", "step:mq_ration.share", "skill:riding", "phase:golden", "slice:noon",
			"atlas:hexi", "tally:farnak", "item:meal", "item:meal:2", "item:tag:wood:5"]:
		assert_eq(Cond.error_of(expr), "", "Geçerli atom: %s" % expr)
		assert_true(Cond.holds(expr, ctx), "Tutmalı: %s" % expr)
	assert_false(Cond.holds("item:meal:3", ctx), "item:meal:3 üç ister")
	assert_false(Cond.holds("quest:mq_ration.done", ctx), "Konmamış görev yanlış")
	assert_eq(Cond.atoms("item:tag:wood:5"), PackedStringArray(["item:tag:wood"]), "Eşik yola girmez")
	for bad in ["phase:afternoon", "quest:mq_count.started", "beat:b.late", "step:mq", "foo:bar", "item:tag", "item:meal:0",
			"skill:ri-ding", "quest:a.done.x"]:
		assert_ne(Cond.error_of(bad), "", "Geçersiz atom hatadır: %s" % bad)


func test_bad_syntax_reports_where() -> void:
	var cases := {
		"a &&": "erken bitti", "(a": "«)» eksik", "a ==": "değer bekleniyordu", "a >= b": "sayı ister",
		"true": "geçersiz ad", "a & b": "beklenmeyen karakter", "'açık": "kapanmayan tırnak", "a b": "beklenmeyen «b»",
		"a || || b": "beklenmeyen «||»", "1abc": "geçersiz ad",
	}
	for expr: String in cases:
		var err := Cond.error_of(expr)
		assert_true(err.contains(str(cases[expr])), "«%s» hatası «%s» içermeli: %s" % [expr, cases[expr], err])
		assert_true(err.contains("karakterde"), "Hata yerini söyler: %s" % err)
		assert_null(Cond.compile(expr))
	assert_true(Cond.error_of("a >= b").contains("3. karakterde"), "İşlecin yeri (1'den sayılır): %s" % Cond.error_of("a >= b"))


func test_compile_is_cached_and_atoms_are_listed() -> void:
	var a: Variant = Cond.compile("trust>=10 && !quest:x.done")
	var b: Variant = Cond.compile("trust>=10 && !quest:x.done")
	assert_true(a is Array and is_same(a, b), "Aynı dizge bir kez derlenir")
	assert_eq(Cond.atoms("a || b>2 && !a && item:meal:2"), PackedStringArray(["a", "b", "item:meal"]))
	assert_eq(Cond.atoms("a ||"), PackedStringArray(), "Okunamayan koşulun atomu yok")


func test_truthiness_and_numbers() -> void:
	assert_false(Cond.truthy(null))
	assert_false(Cond.truthy(false))
	assert_false(Cond.truthy(0))
	assert_false(Cond.truthy(0.0))
	assert_true(Cond.truthy(-5600), "Eksi gün doğru")
	assert_false(Cond.truthy(""))
	assert_false(Cond.truthy("false"), "JourneyFlags'in kuralı")
	assert_false(Cond.truthy("0"))
	assert_true(Cond.truthy("x"))
	assert_false(Cond.truthy([]))
	assert_true(Cond.truthy([0]))
	assert_false(Cond.truthy({}))
	assert_true(Cond.truthy({"id": "x"}))
	assert_almost(Cond.to_number(true), 1.0, 1e-12)
	assert_almost(Cond.to_number(" 4.5 "), 4.5, 1e-12)
	assert_almost(Cond.to_number(""), 0.0, 1e-12)
	assert_true(is_nan(Cond.to_number("abc")))
	assert_almost(Cond.to_number([1, 2, 3]), 3.0, 1e-12)


func test_bad_condition_is_false_and_reported_once() -> void:
	expect_errors(["cond: «>=» sonrası değer bekleniyordu"])
	assert_false(Cond.holds("hour>=", Cond.DictCtx.new({"hour": 5})))
	assert_false(Cond.holds("hour>="), "İkinci kez yazılmaz")


# --- JourneyFlags: dil genişler, değişmez -------------------------------------------------------------------

func test_old_conditions_give_the_same_results() -> void:
	var corpus := _data_conditions()
	assert_true(corpus.size() >= 8, "Verideki koşullar okunmalı (%d)" % corpus.size())
	corpus.append_array([
		"a", "!a", "a || b", "a && !b", "!a && !b", "a||b&&c", "a && b || c", "!!a", "  a  ", "*", "", "a ||", "|| a", "a &&",
		"!", "a b", "kisiler/ana", "a && *", "a-b", "true", "1", "a.b", "quest:x.done", "ties.mene", "! a", "a&&b&&c",
		"a || b || c", "ozan_dinledi", "cocuk_gezinti", "ates_basi && ahir_ziyaret && gol_yamaci", "yosunlu_kaya || kaya_kumesi",
	])
	var keys := ["a", "b", "c", "a b", "kisiler/ana", "a-b", "a.b", "quest:x.done", "ties.mene", "true", "1"]
	var values: Array = [null, true, false, 0, 2, -5600, "0", "false", "", "evet"]
	var flagsets: Array = []
	for i in 400:
		var flags := {}
		var n := i
		for k in keys:
			var v: Variant = values[n % values.size()]
			n = int(n / values.size()) + i * 7 + 3
			if v != null:
				flags[k] = v
		flagsets.append(flags)
	for key in ["ilk_gezinti", "ates_basi", "ahir_ziyaret", "yosunlu_kaya", "kaya_kumesi", "gol_yamaci", "onsoz", "ozan_dinledi"]:
		flagsets.append({key: true})
	flagsets.append({"ates_basi": true, "ahir_ziyaret": true, "gol_yamaci": true, "yosunlu_kaya": true, "cocuk_gezinti": true})
	var checked := 0
	var differ := PackedStringArray()
	for cond: String in corpus:
		for flags: Dictionary in flagsets:
			checked += 1
			if JourneyFlags.holds(flags, cond) != _old_holds(flags, cond) and differ.size() < 8:
				differ.append("«%s» %s" % [cond, JSON.stringify(flags)])
	assert_eq(differ.size(), 0, "Eski koşul aynı sonucu vermeli: %s" % ", ".join(differ))
	assert_true(checked > 10000, "Sınanan durum sayısı: %d" % checked)


func test_flags_language_grows() -> void:
	var flags := {"takvim_gun": 1041, "child_spared": true, "eskam_saw": ["uldin"], "item:meal": 2, "a": true}
	assert_true(JourneyFlags.holds(flags, "takvim_gun>=1041"), "Takvim günü kıyaslanır")
	assert_false(JourneyFlags.holds(flags, "takvim_gun<0"))
	assert_true(JourneyFlags.holds(flags, "child_spared==true"))
	assert_true(JourneyFlags.holds(flags, "(a || missing) && !missing"), "Ayraç")
	assert_true(JourneyFlags.holds(flags, "eskam_saw==uldin"), "Dizi bayrağında üyelik")
	assert_true(JourneyFlags.holds(flags, "item:meal:2"), "Önekli atomun yolu bayrağın adıdır")
	assert_false(JourneyFlags.holds({"list": []}, "list"), "Boş dizi bayrağı konmamış")
	assert_false(JourneyFlags.is_set({"list": []}, "list"))
	assert_true(JourneyFlags.is_set({"day": -41}, "day"), "Eksi sayı konmuş")


func test_flag_push_inc_and_same_entry() -> void:
	var flags := {}
	assert_true(JourneyFlags.push(flags, "eskam_saw", "uldin"))
	assert_false(JourneyFlags.push(flags, "eskam_saw", "uldin"), "Tekil")
	var before: Array = flags["eskam_saw"]
	assert_true(JourneyFlags.push(flags, "eskam_saw", {"id": "berik", "at": 3}))
	assert_eq(before.size(), 1, "Eski dizi değişmez, yenisi yazılır")
	assert_false(JourneyFlags.push(flags, "eskam_saw", {"id": "berik", "at": 9}), "Sözlük id ile kıyaslanır")
	assert_true(JourneyFlags.push(flags, "pairs", {"a": 1}))
	assert_false(JourneyFlags.push(flags, "pairs", {"a": 1}), "id'siz sözlük içerikle kıyaslanır")
	flags["not_list"] = true
	assert_true(JourneyFlags.push(flags, "not_list", "x"), "Dizi olmayan eski değer boş sayılır")
	assert_eq(flags["not_list"], ["x"])
	assert_almost(JourneyFlags.inc(flags, "count"), 1.0, 1e-12)
	assert_almost(JourneyFlags.inc(flags, "count", 2.0), 3.0, 1e-12)
	assert_eq(flags["count"], 3)
	flags["word"] = "x"
	assert_almost(JourneyFlags.inc(flags, "word"), 1.0, 1e-12, "Sayı olmayan eski değer 0'dan başlar")


# --- Effects ---------------------------------------------------------------------------------------------------

func test_each_op_calls_its_service() -> void:
	var fake := _Fake.new()
	var flags := {}
	var s := {"flags": flags, "progress": fake, "inventory": fake, "quests": fake, "dialogue": fake, "travel": fake, "regions": fake,
		"audio": fake, "cine": fake, "ui": fake, "bus": fake, "supply": fake, "structures": fake, "weather": fake, "dev": true}
	var list := [
		["flag", "met_eskam"], ["flag", "yurt_pad", "A"], ["push", "eskam_saw", "uldin"],
		["axis", "kut", 2], ["axis", "trust", 3, "mq_ration.share"], ["ties", "farnak", 1], ["xp", 25], ["xp", 10, "bonus"],
		["give", "meal", 2], ["take", "tag:wood", 3], ["teach", "carry_pack"], ["point", "mq_herd_school"],
		["quest", "mq_ration"], ["step", "mq_ration", "share"], ["dialogue", "d_eskam"], ["bark", "eskam.hello"],
		["reveal", "hexi"], ["station", "way_fold", "linked"], ["route", "r1", "open"], ["rank", 2], ["region", "pale_pasture"],
		["ledger", "fuel", -4], ["ledger", "felt", 2, "own_camp"], ["music", "tension"], ["sfx", "bell_step"], ["cine", "c_bell"],
		["weather", "lock", "kara_boran"], ["structure", "new_yurt", "setStage", 3], ["structure", "new_yurt", "ignite"],
		["oath", "oath_cup", "given"], ["card", "axis_kut"], ["toast", "SAVE_WRITTEN"], ["emit", "bell", {"n": 1}],
	]
	assert_eq(Effects.check(list), PackedStringArray(), "Liste biçimce geçerli")
	var errors := Effects.apply(list, s, "mq_test")
	assert_eq(errors, PackedStringArray(), "Bütün etkiler uygulanmalı")
	assert_eq(flags["met_eskam"], true)
	assert_eq(flags["yurt_pad"], "A")
	assert_eq(flags["eskam_saw"], ["uldin"])
	assert_eq(flags["_card.axis_kut"], true, "Kart görüldü bayrağı")
	var expected := [
		["set_axis", "kut", 2.0, {"once": null, "src": "mq_test"}], ["set_axis", "trust", 3.0, {"once": "mq_ration.share", "src": "mq_test"}],
		["add_ties", "farnak", 1.0], ["add_xp", 25.0, "mq_test"], ["add_xp", 10.0, "bonus"],
		["add", "meal", 2, "mq_test", true], ["remove", "tag:wood", 3], ["teach", "carry_pack"],
		["grant_point", "mq_herd_school"], ["start", "mq_ration"], ["force_step", "mq_ration", "share"], ["start", "d_eskam"],
		["bark", "eskam.hello"], ["reveal", "hexi"], ["set_station", "way_fold", "linked"], ["set_route", "r1", "open"],
		["set_rank", 2], ["open", "pale_pasture"], ["get_ledger", "winter_camp"], ["add", "fuel", -4.0], ["get_ledger", "own_camp"],
		["add", "felt", 2.0], ["set_music_state", "tension"], ["play_sfx", "bell_step"], ["play", "c_bell"], ["lock", "kara_boran"],
		["get_structure", "new_yurt"], ["set_stage", 3], ["get_structure", "new_yurt"], ["ignite"], ["oath", "oath_cup", "given"],
		["card", "axis_kut"], ["toast", "SAVE_WRITTEN"], ["emit_event", &"bell", {"n": 1}],
	]
	assert_eq(fake.calls.size(), expected.size(), "Çağrı sayısı")
	for k in mini(fake.calls.size(), expected.size()):
		assert_eq(JSON.stringify(fake.calls[k]), JSON.stringify(expected[k]), "%d. çağrı" % k)


func test_once_effects_and_branches() -> void:
	var fake := _Fake.new()
	var journey := Journey.new(SaveSystem.new("user://", false))
	var s := {"flags": journey, "inventory": fake, "ui": fake, "dev": true}
	var watcher := watch_signal(journey.flag_set)
	Effects.apply([["give", "toy_bow", 1, "first_bow"], ["give", "toy_bow", 1, "first_bow"], ["card", "rule_bell"], ["card", "rule_bell"]], s)
	assert_eq(fake.calls.size(), 2, "Bir kezlik eşya ve kart ikinci kez gelmez: %s" % JSON.stringify(fake.calls))
	assert_true(journey.has_flag("_given.first_bow"), "Bayrak yolculukta (kayıtla taşınır)")
	assert_true(watcher.count >= 2, "Journey.set_flag'den geçer")
	journey.set_flag("spared", true)
	Effects.apply([["if", "spared && !missing", [["flag", "branch_then"]], [["flag", "branch_else"]]],
		["if", "missing", [["flag", "no"]]], ["if", "missing", [["flag", "no"]], [["push", "seen", "x"]]]], s)
	assert_true(journey.has_flag("branch_then"))
	assert_false(journey.has_flag("branch_else"))
	assert_false(journey.has_flag("no"), "else'siz yanlış dal hiçbir şey yapmaz")
	assert_eq(journey.flags["seen"], ["x"], "Journey.push_flag")
	var ctx := Cond.DictCtx.new({"trust": 30})
	var flags := {}
	Effects.apply([["if", "trust>=25", [["flag", "trusted"]]]], {"flags": flags, "cond": ctx})
	assert_true(flags.has("trusted"), "Verilen koşul bağlamı okunur")


func test_clock_effects_only_go_forward() -> void:
	var clock := GameClock.new(DAY, 600.0)
	var s := {"clock": clock, "dev": true}
	Effects.apply([["clock", "set", "13:30"]], s)
	assert_eq(clock.day_n, DAY)
	assert_almost(clock.minute, 810.0, 1e-6, "set: bugünün 13:30'u")
	Effects.apply([["clock", "set", "08:00"]], s)
	assert_eq(clock.day_n, DAY + 1, "Geçmiş an yarının anıdır: saat geri gitmez")
	assert_almost(clock.minute, 480.0, 1e-6)
	Effects.apply([["clock", "atLeast", "07:00"]], s)
	assert_almost(clock.minute, 480.0, 1e-6, "atLeast: bugünkü an geçtiyse boşa düşer")
	Effects.apply([["clock", "atLeast", "09:15"]], s)
	assert_almost(clock.minute, 555.0, 1e-6, "atLeast: bugünkü an gelmediyse ona")
	Effects.apply([["clock", "advance", 45]], s)
	assert_almost(clock.minute, 600.0, 1e-6, "advance: dakika ekler")
	var skipped := watch_signal(clock.skipped)
	Effects.apply([["clock", "advance", 0]], s)
	assert_eq(skipped.count, 0, "Sıfır dakika atlama değildir")
	Effects.apply([["clock", "advance", 30]], s)
	assert_eq(str((skipped.last_args[0] as Dictionary).get("reason", "")), "cine", "Etki atlaması hikâye kesmesidir")
	assert_eq(Effects.check([["clock", "advance", -5]]).size(), 1, "Saat geri gitmez")
	assert_eq(Effects.check([["clock", "rewind", 5]]).size(), 1, "Bilinmeyen fiil")
	assert_eq(Effects.check([["clock", "hold", "home_golden", "14:46"]]).size(), 1, "home_golden saatin kendisinindir")
	if clock.has_method(&"hold"):
		var errs := Effects.apply([["clock", "hold", "dawn_line", "23:00"]], s)
		assert_eq(errs, PackedStringArray(), "dawn_line kurulur")
		assert_true(clock.has_hold(&"dawn_line"))
		Effects.apply([["clock", "release", "dawn_line"]], s)
		assert_false(clock.has_hold(&"dawn_line"), "release salar")


func test_broken_effects_do_not_stop_the_list() -> void:
	var flags := {}
	var s := {"flags": flags, "dev": false}
	var errors := Effects.apply([["flag", "first"], ["nope", 1], "not a tuple", ["give", "meal"], ["weather", "lock", "x"],
		["flag", "last"]], s, "mq_bad")
	assert_eq(errors.size(), 3, "Bilinmeyen op, dizi olmayan etki ve hizmeti olmayan give: %s" % ", ".join(errors))
	assert_true(errors[0].contains("bilinmeyen op") and errors[0].contains("mq_bad"), "Kaynak yazılır: %s" % errors[0])
	assert_true(errors[2].contains("inventory hizmeti yok"), errors[2])
	assert_true(flags.has("first") and flags.has("last"), "Bozuk etki sonrakileri durdurmaz")
	expect_errors(["effects: bilinmeyen op"])
	Effects.apply([["nope"]], {"flags": {}, "dev": true})


func test_check_validates_shapes_without_services() -> void:
	var bad := {
		"[1]": [[1]], "flag eksik": [["flag"]], "flag fazla": [["flag", "a", true, 3]], "axis türü": [["axis", "kut", "çok"]],
		"ledger yeri": [["ledger", "fuel", 1, "moon"]], "weather fiili": [["weather", "rain"]],
		"structure yöntemi": [["structure", "new_yurt", "explode"]], "if koşulu": [["if", "a >=", []]],
		"if dalı": [["if", "a", "flag"]], "liste değil": {"op": "flag"},
	}
	for label: String in bad:
		assert_true(Effects.check(bad[label]).size() >= 1, "Biçim hatası yakalanmalı: %s" % label)
	var nested := [["if", "a", [["flag", "x"], ["nope"]], [["clock", "advance", -1]]]]
	assert_eq(Effects.check(nested).size(), 2, "İç içe dallar da denetlenir")
	assert_eq(Effects.check(null), PackedStringArray(), "Etkisiz liste geçer")
	assert_eq(Effects.check([["structure", "new_yurt", "set_stage", 2], ["structure", "new_yurt", "cutRoof"]]), PackedStringArray(),
		"Prototipin ve Godot'nun yöntem adı")


# --- Yardımcılar ------------------------------------------------------------------------------------------------

## Verideki bütün koşullar: Destan dizeleri (if) ve Destan Kitabı'nın açılma koşulları (unlock).
func _data_conditions() -> Array:
	var out: Array = []
	for chapter in DestanKitabi.CHAPTERS:
		for e: Variant in DestanKitabi.all_entries(chapter):
			if e is Dictionary:
				for k in ["if", "unlock"]:
					if (e as Dictionary).has(k) and not out.has(str(e[k])):
						out.append(str(e[k]))
	return out


## 2026-11-08'den önceki JourneyFlags.holds ve is_set (dondurulmuş kopya; karşılaştırmanın ölçüsü).
static func _old_holds(flags: Dictionary, cond: String) -> bool:
	cond = cond.strip_edges()
	if cond == "" or cond == "*":
		return true
	if cond.contains("||"):
		for part in cond.split("||"):
			if _old_holds(flags, part):
				return true
		return false
	if cond.contains("&&"):
		for part in cond.split("&&"):
			if not _old_holds(flags, part):
				return false
		return true
	if cond.begins_with("!"):
		return not _old_holds(flags, cond.substr(1))
	return _old_is_set(flags, cond)


static func _old_is_set(flags: Dictionary, key: String) -> bool:
	var v: Variant = flags.get(key, false)
	if v is bool:
		return v
	if v is int or v is float:
		return float(v) != 0.0
	if v is String:
		return v != "" and v != "false" and v != "0"
	return v != null


## Bütün hizmetlerin yerine geçen kaydedici: her çağrı [yöntem, değişkenler...] olarak yazılır.
class _Fake:
	extends RefCounted

	var calls: Array = []

	func _rec(name: String, args: Array) -> void:
		var row: Array = [name]
		row.append_array(args)
		calls.append(row)

	func set_axis(a: Variant, n: Variant, opts: Variant) -> void: _rec("set_axis", [a, n, opts])
	func add_ties(a: Variant, n: Variant) -> void: _rec("add_ties", [a, n])
	func add_xp(n: Variant, src: Variant) -> void: _rec("add_xp", [n, src])
	func teach(a: Variant) -> void: _rec("teach", [a])
	func grant_point(a: Variant) -> void: _rec("grant_point", [a])
	func reveal(a: Variant) -> void: _rec("reveal", [a])
	func oath(a: Variant, b: Variant) -> void: _rec("oath", [a, b])
	func add(a: Variant, n: Variant = null, src: Variant = null, allow_over: Variant = null) -> void: _rec("add", [a, n] if src == null else [a, n, src, allow_over])
	func remove(a: Variant, n: Variant) -> void: _rec("remove", [a, n])
	func start(a: Variant) -> void: _rec("start", [a])
	func force_step(a: Variant, b: Variant) -> void: _rec("force_step", [a, b])
	func bark(a: Variant) -> void: _rec("bark", [a])
	func set_station(a: Variant, b: Variant) -> void: _rec("set_station", [a, b])
	func set_route(a: Variant, b: Variant) -> void: _rec("set_route", [a, b])
	func set_rank(a: Variant) -> void: _rec("set_rank", [a])
	func open(a: Variant) -> void: _rec("open", [a])
	func set_music_state(a: Variant) -> void: _rec("set_music_state", [a])
	func play_sfx(a: Variant) -> void: _rec("play_sfx", [a])
	func play(a: Variant) -> void: _rec("play", [a])
	func card(a: Variant) -> void: _rec("card", [a])
	func toast(a: Variant) -> void: _rec("toast", [a])
	func emit_event(a: Variant, b: Variant) -> void: _rec("emit_event", [a, b])
	func lock(a: Variant) -> void: _rec("lock", [a])
	func set_stage(a: Variant) -> void: _rec("set_stage", [a])
	func ignite() -> void: _rec("ignite", [])

	func get_ledger(place: Variant) -> Object:
		_rec("get_ledger", [place])
		return self

	func get_structure(id: Variant) -> Object:
		_rec("get_structure", [id])
		return self
