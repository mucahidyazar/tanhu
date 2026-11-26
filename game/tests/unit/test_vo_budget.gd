extends TestCase
## Seslendirme verisinin sayacı ve kuralları (K61; godot.md §3.3, audio.md §5, act0-text.md):
## data/vo_lines.json ve VoLines.
##
## Sayaç: karakter ve süre perde, konuşmacı ve dilim başına yazdırılır; toplamda düşmez (K61: tavan yok).
## Defter (tools/vo_ledger.jsonl) doluysa ürün başına kredi toplamı da yazılır. Düşen kurallar: şema, kimlik
## tekilliği, dilim A–D, bilinen konuşmacı, yazılı dosya ve zaman yollarının varlığı, şarkının altyazı
## pencereleri, kilitli perdenin metni ve yapı kuralı (VoLines.problems). Satırlar üretilince de sınama aynı
## kalır: dosyası olan satırın süresi dosyanınkidir ve sözcük zamanı metinle aynı sıradadır; dosyası olmayan
## satır yer tutucudur (K89), altyazıyla `seconds` süresince akar.

const SONG := "act0.bard.song"
const SONG_SUBS: Array[String] = ["act0.bard.1", "act0.bard.2"]
const MYTH_IDS: Array[String] = ["act0.myth.3", "act0.myth.4", "act0.myth.5", "act0.myth.6", "act0.myth.7",
	"act0.myth.8", "act0.myth.9", "act0.myth.10", "act0.myth.11", "act0.myth.12", "act0.myth.13", "act0.myth.14", "act0.myth.15",
	"act0.myth.16", "act0.myth.17", "act0.myth.18", "act0.myth.19", "act0.myth.20", "act0.myth.21", "act0.myth.22", "act0.myth.23",
	"act0.myth.24", "act0.myth.25"]
const BIRTH := "act0.birth.12"
const HEREKA := "act0.birth.hereka"
const BRIDGE_IDS: Array[String] = ["act0.narr.1", "act0.narr.2", "act0.narr.3", "act0.narr.4", "act0.narr.5",
	"act0.narr.6", "act0.narr.7"]
## Köprülerin yeniden yazılan satırları (K36): eski metinli kayıtları yer tutucudur, yeniden çekilir.
const REWRITTEN_BRIDGES: Array[String] = ["act0.narr.2", "act0.narr.3", "act0.narr.6"]
const ELDRIN := "LvmvHEBEmMJBJw9UuhwO"
## Ozanın konuşma sesi (K35, K61; audio.md §5 kadro): mit satırlarını o okur.
const DAVID := "BNgbHR0DNeZixGQVzloa"
## Hereka'nın sesleri (K95; audio.md §5 kadro): I. ve IV. Perde Lea, Mature (speakers tablosu), Önsöz'ün 39 yaşı Heather Faith
## (satırın voice'u).
const LEA := "V4hbKpM9VBIJ9lKaWBjM"
const HEATHER := "49d0YOOn2K0LVSBCkZ0q"
## Şarkının çekimi (K95): 3104, planın karması, 26,853 sn, iki dize.
const SONG_TAKE := 3104
const SONG_HASH := "e673c424"
const SONG_SECONDS := 26.853
const LEDGER_PATH := "res://tools/vo_ledger.jsonl"
const LEDGER_KEYS: Array[String] = ["at", "product", "id", "take", "credits", "chars", "voice", "model"]
const PRODUCTS: Array[String] = ["tts", "music", "sfx", "stt"]
## Seslendirme havuzu (K59) ve 64 kb/sn satırın saniyedeki boyu (mp3_44100_64).
const VOICE_POOL := 2 * 1024 * 1024
const BYTES_PER_SECOND_64K := 8000.0
const PROLOGUE_DIR := "res://audio/vo/prologue"
## Oynanan sahnelerin satırları (E20/7; SceneVoice): önek → satır sayısı. Önsöz'ün satırları bunların dışındadır.
## E21 (K110): Önsöz'ün oynanan üç günü (milk … hearth) ve Çocukluk'un iki yeni günü (flock, bone, tally); sayım gününe bir söz.
const SCENE_PREFIXES := {"act0.child.": 56, "act0.depart.": 10, "act0.camp.": 3,
		"act0.milk.": 17, "act0.storm.": 22, "act0.lambs.": 12, "act0.feast.": 16, "act0.wrestle.": 11, "act0.hearth.": 12,
		"act0.flock.": 38, "act0.bone.": 16, "act0.tally.": 20}
## Çocukluk'un önekleri: Mete'nin adı söylenmez (story.md §4).
const CHILDHOOD_PREFIXES := ["act0.child.", "act0.flock.", "act0.bone.", "act0.tally."]
## At üstünde gelen söz B dilimidir (K61): Yola Çıkış'ta binişten sonra Eskam.
const RIDE_LINES := ["act0.depart.eskam_ride"]
## Sahnelerin kadrosu (K86: kişi ansiklopedideki sesiyle konuşur; çocuklar kendi yaşlarının sesiyle, K95'in kalıbı; E20/7 kullanıcı onayı).
const SCENE_VOICES := {
	"lan_hatun": "LI283TzJcIwSKqsXiH7u", "counter": "S9V0fuqWOqX0i8Kb8ctu", "yanchi": "E4IXevHtHpKGh0bvrPPr",
	"eskam": "dcbUcEjFfmgpM8W4YTRG", "huyan_hatun": "r1KmysJdVYZjJCm4mL3b", "mete": "XALcFq0WF65uNKzmpcZW",
	"mother": "DJpgP3rIDYoqtCH3IzV6", "father": "FWipwLM0YqCuwisLprpU", "bard": "BNgbHR0DNeZixGQVzloa",
	"mete_child": "tJHJUEHzOkMoPmJJ5jo2", "yanchi_child": "nDJIICjR9zfJExIFeSCN", "luhun_child": "Xb3zeLrTi6F4ziIcXdwk",
	# E21 (K110): Kayın Obası, Ebe Obası, Ağabey (ansiklopedideki sesi) ve 45 yaşındaki Hereka (Önsöz'ün 39 yaşının sesi, K95).
	"saruk": "VNHNa6nN6yJdVF3YRyuF", "boru": "loY1uopAz31XyhAEhNSa", "kunay": "9XELrPIyVsbmAjCB3Bwh", "tonga": "CDdUdrzh7qrDE2xpRZyQ",
	"older_brother": "wSqOdjeNqDrHcoK0zorF", "folk_man": "KvaCHcJoMXfOzwtsULOZ", "folk_woman": "JXFyLOwtCuySmwGGzqHN",
	"ebe_man": "2iDFkWhzZij4MDCakenJ", "ebe_woman": "NMbEhOPNJop9OLjdn7UU", "hereka_young": "49d0YOOn2K0LVSBCkZ0q",
}

var _letters := RegEx.create_from_string("[^\\p{L}\\p{N}]+")


func before_each() -> void:
	VoLines.clear_cache()


func after_each() -> void:
	VoLines.clear_cache()


# --- Sayaç (düşmez) -------------------------------------------------------------------------

func test_report_by_act_speaker_and_tier() -> void:
	# K61: karakter perde, konuşmacı ve dilim başına; süre 12 kr/sn ya da seconds. Rapor düşmez.
	var rows := {}
	var total_chars := 0
	var total_seconds := 0.0
	for item: Variant in VoLines.lines():
		var line: Dictionary = item
		var id := str(line.get("id", ""))
		var key := "%d · %s · %s" % [int(line.get("act", -1)), str(line.get("speaker", "")), str(line.get("tier", ""))]
		if not rows.has(key):
			rows[key] = {"lines": 0, "chars": 0, "seconds": 0.0, "files": 0}
		var row: Dictionary = rows[key]
		row["lines"] += 1
		var kind := str(line.get("kind", ""))
		# Altyazı dizesi şarkının içindedir: süresi ve karakteri şarkınınkine eklenmez.
		if kind == "line":
			row["chars"] += VoLines.chars(id)
			total_chars += VoLines.chars(id)
		if kind != "sub":
			row["seconds"] += VoLines.seconds(id)
			total_seconds += VoLines.seconds(id)
		if VoLines.has_audio(id):
			row["files"] += 1
	print("    Seslendirme sayacı (perde · konuşmacı · dilim: satır, okunan EN karakter, süre, dosyalı satır)")
	for key: String in rows:
		var row: Dictionary = rows[key]
		print("      %s: %d satır, %d kr, %.1f sn, %d dosya" % [key, row["lines"], row["chars"], row["seconds"], row["files"]])
	print("      Toplam: %d satır, %d kr (≈%d kredi), %.1f sn" % [VoLines.lines().size(), total_chars, total_chars, total_seconds])
	var credits := _ledger_credits()
	if credits.is_empty():
		print("      Defter boş (tools/vo_ledger.jsonl)")
	for product: String in credits:
		print("      Defter: %s %d kredi (%d çağrı)" % [product, credits[product]["credits"], credits[product]["calls"]])
	assert_false(rows.is_empty(), "vo_lines.json'da satır yok")


func test_prologue_voice_pool_projection_fits() -> void:
	# Önsöz sinemasının sesleri seslendirme havuzuna (K59: dünya başına 2 MiB) sığmalı: dosyası olan satırın içe
	# aktarılan boyu, olmayanın 64 kb/sn'de `seconds`'ı. Üretimden önce bütçe sürprizi olmasın. Köprüler (`use`) ayrı sinemadır:
	# CineHost yalnız dizinin satırlarını ister, satırlar sinema bitince bırakılır; aynı anda yüklü olmazlar. Oynanan sahnelerin satırları
	# (E20/7) kendi dünyalarındadır (Çocukluk childhood_ordos, Yola Çıkış depart_yurt, Serbest Gez kamp): her biri ayrı havuzdur.
	# E21: günlerin sözleri gün gün yüklenir (her gün kendi sahne dosyasıdır); havuz gün başınadır.
	var groups := {"Önsöz": [], "Çocukluk": ["act0.child."], "Yola Çıkış": ["act0.depart."], "Serbest Gez": ["act0.camp."],
		"Önsöz 1. gün": ["act0.milk.", "act0.storm."], "Önsöz 2. gün": ["act0.lambs.", "act0.feast.", "act0.wrestle."],
		"Önsöz 3. gün": ["act0.hearth."], "Çocukluk 1. gün": ["act0.flock.", "act0.bone."], "Çocukluk 2. gün": ["act0.tally."]}
	for group: String in groups:
		var bytes := 0.0
		var projected := 0.0
		var prefixes: Array = groups[group]
		for id in VoLines.ids("act0."):
			var line := VoLines.line(id)
			var own := _scene_prefix(id)
			if str(line.get("kind", "")) == "sub" or line.has("use") or (own.is_empty() != prefixes.is_empty()) \
					or (not prefixes.is_empty() and not prefixes.has(own)):
				continue
			var path := VoLines.declared_file(id)
			if not path.is_empty():
				bytes += _imported_bytes(path)
			elif line.get("voice") is String:
				projected += VoLines.seconds(id) * BYTES_PER_SECOND_64K
		print("    %s: dosyalı %.2f MiB, üretilecekler ≈%.2f MiB; toplam ≈%.2f MiB (havuz 2 MiB)"
				% [group, bytes / 1048576.0, projected / 1048576.0, (bytes + projected) / 1048576.0])
		assert_true(bytes + projected <= VOICE_POOL, "%s'ün sesleri seslendirme havuzunu aşar: %.2f MiB" % [group, (bytes + projected) / 1048576.0])


# --- Kurallar ---------------------------------------------------------------------------------

func test_data_is_valid() -> void:
	var problems := VoLines.problems(VoLines.data())
	assert_true(problems.is_empty(), "vo_lines.json kuralları: %s" % "; ".join(problems))
	# Önsöz'ün satırları: şarkı, iki dize, mit 3–11, doğum 12, Hereka ve köprüler N1–N7.
	var expected: Array[String] = [SONG]
	expected.append_array(SONG_SUBS)
	expected.append_array(MYTH_IDS)
	expected.append_array([BIRTH, HEREKA])
	expected.append_array(BRIDGE_IDS)
	assert_eq(_prologue_ids(), PackedStringArray(expected), "Önsöz'ün satırları ve sırası")
	for prefix: String in SCENE_PREFIXES:
		assert_eq(VoLines.ids(prefix).size(), int(SCENE_PREFIXES[prefix]), "%s satırları (E20/7)" % prefix)
	for id in VoLines.ids():
		assert_eq(int(VoLines.line(id).get("act", -1)), 0, "%s perde 0'dır" % id)


func test_injected_faults_are_caught() -> void:
	# Hata ekleme: her bozulma bir ihlal yazdırmalı (kural gerçekten sınıyor).
	var cases := {
		"kimlik iki kez": func(d: Dictionary) -> void: _line_of(d, "act0.myth.4")["id"] = "act0.myth.3",
		"karmasıyla tutmuyor": func(d: Dictionary) -> void: _line_of(d, "act0.myth.3")["text"]["en"] = "First there was sea.",
		"tier A–D": func(d: Dictionary) -> void: _line_of(d, "act0.myth.5")["tier"] = "E",
		"speakers tablosunda yok": func(d: Dictionary) -> void: _line_of(d, "act0.myth.6")["speaker"] = "ghost",
		"ses dosyası yok": func(d: Dictionary) -> void: _line_of(d, "act0.narr.1")["file"] = PROLOGUE_DIR + "/yok_boyle_dosya.mp3",
		"şarkının içinde değil": func(d: Dictionary) -> void: _line_of(d, "act0.bard.2")["window"] = [20.0, 30.0],
		"kararlılığı yalnız": func(d: Dictionary) -> void: _line_of(d, "act0.myth.8")["stability"] = 0.3,
		"bilinen bir zincir": func(d: Dictionary) -> void: _line_of(d, "act0.myth.9")["fx"] = "yankı",
		"sesliden sessize": func(d: Dictionary) -> void: _add_node_conflict(d),
	}
	for fragment: String in cases:
		var d: Dictionary = VoLines.data().duplicate(true)
		(cases[fragment] as Callable).call(d)
		var problems := VoLines.problems(d)
		assert_true(_any_contains(problems, fragment), "«%s» bozulması yakalanmadı: %s" % [fragment, "; ".join(problems)])
	assert_true(VoLines.problems(VoLines.data().duplicate(true)).is_empty(), "Bozulmamış kopya geçerli olmalı")


func test_structure_rule_on_fixture() -> void:
	# K61: bir düğümde aynı konuşmacı sesliden sessize geçmez. Bugün düğümlü satır yok; kural fikstürle.
	var fixture: Array = [
		{"id": "a.1", "node": "n1", "speaker": "teoman", "tier": "B"},
		{"id": "a.2", "node": "n1", "speaker": "teoman", "tier": "D"},
		{"id": "a.3", "node": "n1", "speaker": "mete", "tier": "D"},
		{"id": "b.1", "node": "n2", "speaker": "teoman", "tier": "A"},
		{"id": "b.2", "node": "n2", "speaker": "teoman", "tier": "C"},
		{"id": "c.1", "speaker": "teoman", "tier": "D"},
	]
	var problems := VoLines.structure_problems(fixture)
	assert_eq(problems.size(), 1, "Yalnız n1'de teoman sesliden yazıya geçiyor: %s" % "; ".join(problems))
	assert_true(_any_contains(problems, "n1 · teoman"), "İhlal düğümü ve konuşmacıyı söylemeli: %s" % "; ".join(problems))
	assert_true(VoLines.structure_problems(VoLines.lines()).is_empty(), "Gerçek veride yapı ihlali olmamalı")


func test_speakers_tiers_and_scenes() -> void:
	assert_eq(VoLines.speaker(SONG), "bard")
	for id in SONG_SUBS:
		assert_eq(VoLines.speaker(id), "bard", "%s ozanın dizesidir" % id)
		assert_eq(str(VoLines.line(id).get("of", "")), SONG, "%s şarkının altyazısıdır, ayrıca okunmaz" % id)
	for id in MYTH_IDS:
		assert_eq(VoLines.speaker(id), "bard", "%s ozanındır (K35: mit ozanın ağzındadır)" % id)
		assert_eq(str(VoLines.line(id).get("scene", "")), "myth", id)
	assert_eq(VoLines.speaker(BIRTH), "narrator")
	assert_eq(str(VoLines.line(BIRTH).get("scene", "")), "birth")
	assert_eq(VoLines.speaker(HEREKA), "hereka", "Doğumda konuşan tek kişi Hereka'dır")
	assert_eq(str(VoLines.line(HEREKA).get("scene", "")), "birth")
	for id in BRIDGE_IDS:
		assert_eq(VoLines.speaker(id), "narrator", id)
		var use := "bridge-one" if BRIDGE_IDS.find(id) < 5 else "bridge-two"
		assert_eq(str(VoLines.line(id).get("use", "")), use, "%s köprüsü (N1–N5 bir, N6–N7 iki)" % id)
	for id in _prologue_ids():
		assert_eq(VoLines.tier(id), "A", "Önsöz'ün bütün satırları A dilimidir (act0-text.md «Bedel»)")
	# Oynanan sahneler (E20/7, K61): ana görevin düğümleri A, tepki sözleri (bark) C, Serbest Gez'in kampı (yan görevin düğümü) ve at üstünde gelen söz B.
	for prefix: String in SCENE_PREFIXES:
		for id in VoLines.ids(prefix):
			var want := "B" if prefix == "act0.camp." or RIDE_LINES.has(id) else ("C" if id.contains(".bark.") else "A")
			assert_eq(VoLines.tier(id), want, "%s dilimi" % id)
	assert_eq(VoLines.speaker_name(HEREKA, "tr"), "Hereka")
	assert_eq(VoLines.speaker_name(BIRTH, "tr"), "Anlatıcı")
	assert_eq(VoLines.speaker_name(BIRTH, "en"), "Narrator")


func test_scene_lines_are_voiced_with_the_cast() -> void:
	# E20/7: oynanan sahnelerin her sözü sesli. Sahnenin satırı vo_lines.json'daki satırla aynı metin ve konuşan; ses dosyası içe aktarılmış; kişi
	# ansiklopedideki sesiyle (K86), çocuklar kendi yaşlarının sesiyle (K95'in kalıbı); kazanç sınırlar içinde; Çocukluk'ta Mete'nin adı söylenmez
	# (ad ilk kez N2'de duyulur, story.md §4); tepki sözlerinde iki rol, rol başına üç çeşit (K61 C: 3–6).
	var scenes := {"act0.child.": ChildhoodScene.load_data(), "act0.depart.": DepartScene.load_data()}
	for prefix: String in scenes:
		var d: Dictionary = scenes[prefix]
		assert_eq(str(d.get("vo_prefix", "")), prefix, "Sahnenin öneki")
		var lines: Dictionary = d["lines"]
		assert_eq(lines.size(), VoLines.ids(prefix).size(), "%s: sahnenin her satırının sesi var, fazlası yok" % prefix)
		for key: String in lines:
			var id: String = prefix + key
			assert_true(VoLines.has_line(id), "%s vo_lines.json'da" % id)
			assert_eq(VoLines.subtitle(id, "tr"), str(lines[key]["tr"]), "%s altyazısı sahneyle aynı" % id)
			assert_eq(VoLines.subtitle(id, "en"), str(lines[key]["en"]), "%s sözü sahneyle aynı" % id)
			assert_eq(VoLines.speaker(id), str(lines[key]["speaker"]), "%s konuşanı" % id)
			assert_true(VoLines.has_audio(id), "%s: sesi içe aktarılmış, bugünkü metnin kaydı" % id)
	var scene_of := {"act0.child.": "childhood", "act0.depart.": "depart", "act0.camp.": "camp_tour",
		"act0.milk.": "prologue_days", "act0.storm.": "prologue_days", "act0.lambs.": "prologue_days", "act0.feast.": "prologue_days",
		"act0.wrestle.": "prologue_days", "act0.hearth.": "prologue_days",
		"act0.flock.": "childhood_days", "act0.bone.": "childhood_days", "act0.tally.": "childhood_days"}
	for id in VoLines.ids("act0."):
		var prefix := _scene_prefix(id)
		if prefix.is_empty():
			continue
		var who := VoLines.speaker(id)
		assert_eq(str(VoLines.line(id).get("voice", "")), str(SCENE_VOICES.get(who, "?")), "%s: %s'in sesi" % [id, who])
		assert_eq(str(VoLines.line(id).get("model", "")), "eleven_v3", id)
		assert_between(VoLines.gain_db(id), -10.0, 6.0, "%s kazancı" % id)
		assert_eq(str(VoLines.line(id).get("scene", "")), str(scene_of[prefix]), "%s sahnesi" % id)
		if prefix == "act0.camp.":
			assert_true(VoLines.has_audio(id), "%s: sesi içe aktarılmış" % id)
		if CHILDHOOD_PREFIXES.has(prefix):
			assert_false(VoLines.subtitle(id, "en").contains("Mete"), "%s: Çocukluk'ta Mete'nin adı söylenmez" % id)
	# Sesler tekildir: çocuk sesleri büyüklerinkinden ve birbirinden ayrıdır (K86); speakers tablosu kişinin sesini yazar.
	var seen := {}
	for who: String in SCENE_VOICES:
		assert_false(seen.has(SCENE_VOICES[who]), "%s'in sesi başkasına da verilmiş" % who)
		seen[SCENE_VOICES[who]] = true
		var info: Dictionary = (VoLines.data()["speakers"] as Dictionary).get(who, {})
		assert_eq(str(info.get("voice", "")), str(SCENE_VOICES[who]), "speakers tablosunda %s" % who)
	var barks: Dictionary = (scenes["act0.child."] as Dictionary).get("barks", {})
	assert_almost(float(barks.get("cooldown", 0.0)), 45.0, 0.001, "Aynı rol aynı olayda ≥45 sn (K61)")
	for event in ["graze", "miss", "hit", "flush"]:
		var per := {}
		for e: Variant in barks.get(event, []):
			var entry: Dictionary = e
			per[str(entry["by"])] = int(per.get(str(entry["by"]), 0)) + 1
			assert_eq(VoLines.tier("act0.child." + str(entry["line"])), "C", "%s: havuz sözü" % entry["line"])
		assert_eq(int(per.get("yanchi_child", 0)), 3, "%s: Yançi'ye üç çeşit" % event)
		assert_eq(int(per.get("luhun_child", 0)), 3, "%s: Luhun'a üç çeşit" % event)


func test_english_character_counts_match_the_design() -> void:
	# act0-text.md «Bedel»: mit 3–25 1.352, doğum 12 113, Hereka 9; köprüler 704 (bir 518, iki 186), yeniden
	# çekilecek üç köprü satırı 359 karakter.
	assert_eq(_chars(MYTH_IDS), 1352, "Mit satırları 3–25")
	assert_eq(VoLines.chars(BIRTH), 113, "Doğum satırı 12")
	assert_eq(VoLines.chars(HEREKA), 9, "Hereka: «One more.»")
	assert_eq(_chars(BRIDGE_IDS), 704, "Köprüler N1–N7")
	assert_eq(_chars(BRIDGE_IDS.slice(0, 5)), 518, "Köprü 1")
	assert_eq(_chars(BRIDGE_IDS.slice(5)), 186, "Köprü 2")
	assert_eq(_chars(REWRITTEN_BRIDGES), 359, "N2, N3, N6")


func test_text_lock_matches_and_breaks_on_change() -> void:
	# K61: kilitli perdenin A/B metni karmasıyla aynı; bir sözcük değişince kilit tutmaz.
	var data := VoLines.data()
	var lock: Dictionary = (data.get("locks", {}) as Dictionary).get("0", {})
	assert_false(lock.is_empty(), "Önsöz'ün metni kilitli olmalı (E7.2)")
	assert_eq(str(lock.get("hash", "")), VoLines.lock_hash(0), "Kilidin karması bugünkü metnin karması")
	assert_true(VoLines.is_locked(0))
	assert_eq(str(lock.get("hash", "")).length(), 40, "SHA-1 onaltılık")
	var changed: Dictionary = data.duplicate(true)
	for item: Variant in changed["lines"]:
		if item is Dictionary and item["id"] == "act0.myth.14":
			item["text"]["en"] = str(item["text"]["en"]).replace("children", "sons")
	assert_ne(VoLines.lock_hash(0, changed), VoLines.lock_hash(0), "Bir sözcük karmayı değiştirmeli")
	assert_false(VoLines.is_locked(0, changed), "Değişen metin kilitli sayılmamalı")
	var tr_only: Dictionary = data.duplicate(true)
	_line_of(tr_only, "act0.myth.3")["text"]["tr"] = "Başka bir altyazı."
	assert_true(VoLines.is_locked(0, tr_only), "Kilit söylenen İngilizceyi tutar; altyazı düzeltmesi kilidi bozmaz")


func test_song_file_timing_and_windows() -> void:
	# Çekim 3104 prototipin bard-song.mjs işlemesinden geçti (baştaki sessizlik kesilir, mono, −18 LUFS, 128 kb/sn; 3106'nın
	# oyundaki dosyası aynı işlemle bayt bayt yeniden çıkar); zamanlar işlenmiş dosyanındır.
	var path := VoLines.audio_path(SONG)
	assert_eq(path, PROLOGUE_DIR + "/act0.bard.song.mp3", "Şarkının dosyası içe aktarılmış olmalı")
	assert_true(path.begins_with("res://audio/vo/"), "Şarkı seslendirme havuzundadır (test_audio_budget)")
	assert_eq(_importer(path), "mp3", "MP3 olduğu gibi içe aktarılır")
	assert_true(_imported_bytes(path) > 0, "İçe aktarılan dosya var")
	var stream := load(path) as AudioStreamMP3
	assert_not_null(stream)
	if stream:
		assert_almost(VoLines.seconds(SONG), stream.get_length(), VoLines.SECONDS_TOLERANCE, "seconds dosyanın süresi")
	assert_almost(VoLines.seconds(SONG), SONG_SECONDS, 0.001)
	var timing := VoLines.timing(SONG)
	assert_false(timing.is_empty(), "Şarkının zaman dosyası")
	assert_eq(int(timing.get("take", 0)), SONG_TAKE)
	assert_eq(int(timing.get("seed", 0)), SONG_TAKE)
	assert_eq(str(timing.get("hash", "")), SONG_HASH)
	assert_eq(str(timing.get("model", "")), "music_v2_5")
	assert_almost(float(timing.get("seconds", 0.0)), SONG_SECONDS, 0.001)
	assert_almost(float(timing.get("pan_max", 0.0)), 0.1, 0.0001, "Şarkı ozanın yönüne en çok %10 kayar")
	var beat: Dictionary = timing.get("beat", {})
	assert_eq(int(beat.get("bpm", 0)), 52, "6/8, noktalı dörtlük 52")
	assert_eq(int(beat.get("bar_beats", 0)), 2)
	assert_eq(int(VoLines.line(SONG).get("take", 0)), SONG_TAKE)
	# 23 sözcük, iki dizenin EN metniyle aynı sırada; yönergeler ({...}) yok.
	var words := VoLines.words(SONG)
	var expected := _tokens(VoLines.subtitle(SONG_SUBS[0], "en")) + _tokens(VoLines.subtitle(SONG_SUBS[1], "en"))
	assert_eq(words.size(), 23, "Şarkının 23 sözcüğü")
	assert_eq(_word_tokens(words), expected, "Sözcükler dizelerle aynı sırada")
	var last := -1.0
	for word: Variant in words:
		assert_false(str(word["w"]).contains("{"), "Küme parantezli yönerge sözcük sayılmaz")
		assert_true(float(word["t0"]) >= last and float(word["t1"]) > float(word["t0"]), "Sözcük zamanları artan: %s" % word)
		last = float(word["t1"])
	# Dizelerin penceresi şarkının içinde, sırayla, ilk ve son sözcüğe oturur.
	var subs := VoLines.sub_lines(SONG)
	assert_eq(subs.size(), 2, "Şarkının iki dizesi")
	var timing_lines: Array = timing.get("lines", [])
	var at := 0
	for i in subs.size():
		var sub: Dictionary = subs[i]
		assert_eq(str(sub["id"]), SONG_SUBS[i])
		assert_between(float(sub["t0"]), 0.0, SONG_SECONDS)
		assert_between(float(sub["t1"]), float(sub["t0"]), SONG_SECONDS)
		if i > 0:
			assert_true(float(sub["t0"]) > float(subs[i - 1]["t1"]), "Dizeler örtüşmez")
		var count := _tokens(str(sub["en"])).size()
		assert_almost(float(sub["t0"]), float(words[at]["t0"]), 0.0005, "%s ilk sözcüğüyle açılır" % sub["id"])
		assert_almost(float(sub["t1"]), float(words[at + count - 1]["t1"]), 0.0005, "%s son sözcüğüyle kapanır" % sub["id"])
		at += count
		if i < timing_lines.size():
			assert_almost(float(timing_lines[i]["t0"]), float(sub["t0"]), 0.0005)
			assert_almost(float(timing_lines[i]["t1"]), float(sub["t1"]), 0.0005)
		assert_almost(VoLines.seconds(str(sub["id"])), float(sub["t1"]) - float(sub["t0"]), 0.001, "Dizenin süresi penceresidir")
	assert_eq(timing_lines.size(), 2, "Zaman dosyasında iki dizenin penceresi")


func test_lines_with_files_match_their_audio() -> void:
	# Dosyası olan her satır: içe aktarılmış, seconds dosyanın süresi (±0,05 sn), sözcük zamanı metinle aynı sırada.
	var checked := 0
	for id in VoLines.ids():
		var path := VoLines.declared_file(id)
		if path.is_empty():
			continue
		checked += 1
		assert_true(ResourceLoader.exists(path), "%s: dosya yüklenebilir olmalı" % id)
		assert_eq(VoLines.audio_path(id), "" if VoLines.is_stale(id) else path,
				"%s: bugünkü metnin kaydı çalınır, eski metinli kayıt çalınmaz (K36)" % id)
		assert_eq(_importer(path), "mp3", "%s: MP3 içe aktarıcısı" % id)
		var stream := load(path) as AudioStreamMP3
		assert_not_null(stream, id)
		if stream:
			assert_almost(VoLines.seconds(id), stream.get_length(), VoLines.SECONDS_TOLERANCE, "%s: seconds dosyanın süresi" % id)
		if id == SONG or VoLines.timing(id).is_empty():
			continue
		assert_eq(_word_tokens(VoLines.words(id)), _tokens(VoLines.subtitle(id, "en")), "%s: sözcük zamanı EN metinle aynı sırada" % id)
		assert_eq(str(VoLines.timing(id).get("hash", "")), str(VoLines.line(id).get("take_hash", "")), "%s: zaman dosyası aynı çekimden" % id)
	assert_true(checked >= 8, "Şarkı ve yedi köprü kaydı dosyalıdır (%d)" % checked)


func test_placeholder_lines_flow_with_subtitles() -> void:
	# K89: dosyası olmayan satır yer tutucudur; seconds tahmindir, altyazı iki dilde vardır.
	for id in VoLines.ids("act0."):
		var line := VoLines.line(id)
		assert_false(VoLines.subtitle(id, "tr").is_empty(), "%s: TR altyazı" % id)
		assert_false(VoLines.subtitle(id, "en").is_empty(), "%s: EN metin" % id)
		assert_true(VoLines.seconds(id) > 0.0, "%s: süre" % id)
		if VoLines.declared_file(id).is_empty():
			assert_eq(VoLines.audio_path(id), "", "%s: dosyasız satırda çalınacak ses yok" % id)
			assert_almost(VoLines.seconds(id), VoLines.est(id), 0.0001, "%s: dosya yokken seconds tahmindir" % id)
			assert_null(line.get("timing"), "%s: dosyasız satırın sözcük zamanı da yok" % id)
	# Tahminler çapaların bildiği sürelerdir: mit satırlarında okunan sürenin yuvarlağı (E13: metin okunduktan sonra yazıldı).
	for id in MYTH_IDS:
		assert_almost(VoLines.est(id), VoLines.seconds(id), 0.051, "%s: tahmin okunan süreden sapmaz" % id)
	assert_almost(VoLines.est(BIRTH), 9.4, 0.0001)
	assert_almost(VoLines.est(HEREKA), 1.0, 0.0001)


func test_prologue_lines_carry_no_chain() -> void:
	# Önsöz'ü ozan okur: Erlik zinciri (−3 dB, 800 Hz altı +2 dB) eski anlatıcı içindi, «Erlik.» sözünde ses oyunu gibi durur;
	# anı sessizlik taşır. Zincir I. Perde'de Erlik'in kendi sesinde kalır (Voice yolu, test_voice_bus.gd).
	for id in VoLines.ids("act0."):
		assert_eq(VoLines.fx(id), "", "%s: ses zinciri yok" % id)


func test_narrator_and_hereka_lines_are_ready_to_generate() -> void:
	# Üretim: ozanın 3–25. satırları (E13), anlatıcının doğum satırı ve Hereka'nın sözü. Araç bunları okur.
	var ids: Array[String] = MYTH_IDS.duplicate()
	ids.append_array([BIRTH, HEREKA])
	for id in ids:
		var line := VoLines.line(id)
		assert_eq(str(line.get("kind", "")), "line", id)
		assert_eq(str(line.get("model", "")), "eleven_v3", "%s: eleven_v3 (K17)" % id)
		assert_almost(float(line.get("stability", -1.0)), 0.5, 0.0001, "%s: kararlılık 0,5" % id)
		assert_false(VoLines.target_path(id).is_empty(), "%s: üretimin hedefi perdenin klasöründe" % id)
		assert_eq(VoLines.target_path(id), PROLOGUE_DIR.path_join(id + ".mp3"))
		if not VoLines.declared_file(id).is_empty():
			assert_false(VoLines.is_stale(id), "%s: dosyası bugünkü metinden ve sesten olmalı" % id)
	for id in MYTH_IDS:
		assert_eq(str(VoLines.line(id).get("voice", "")), DAVID, "%s: David (K35, K61)" % id)
	assert_eq(str(VoLines.line(BIRTH).get("voice", "")), ELDRIN, "Doğumun tarih satırı Eldrin (K17)")
	# Hereka'nın 39 yaşı kendi sesiyle (K95); okuma satırın sesini kullanır, tablo yaşlı Hereka'nın sesidir.
	var hereka := VoLines.line(HEREKA)
	assert_eq(str(hereka.get("voice", "")), HEATHER, "Önsöz'ün 39 yaşı Heather Faith")
	assert_false(hereka.has("voice_pending"), "Hereka'nın sesi seçildi")
	var speaker: Dictionary = (VoLines.data().get("speakers", {}) as Dictionary).get("hereka", {})
	assert_eq(str(speaker.get("voice", "")), LEA, "I. ve IV. Perde'nin Hereka'sı Lea, Mature")
	assert_false(speaker.has("voice_pending"), "Kişinin sesi seçildi")
	assert_true(VoLines.is_locked(0), "Üretim için Önsöz'ün metni kilitli")


func test_take_hash_matches_the_prototype_and_marks_stale_bridges() -> void:
	# Çekim karması prototipin tools/voices.mjs karmasıyla aynı (manifest: act0.narr.1 4811a723d0fe).
	var n1 := {"voice": ELDRIN, "model": "eleven_v3", "stability": 0.5, "similarity_boost": 0.8,
		"text": {"en": "Before there were empires of grass, there was only the wind, and those who could outlast it."}}
	assert_eq(VoLines.take_hash(n1), "4811a723d0fe")
	assert_eq(VoLines.take_hash({"voice": null, "model": "eleven_v3", "text": {"en": "x"}}), "", "Sesi olmayan satırın karması yok")
	# Eskimiş kayıt yalnız köprüde olabilir: Önsöz'ün satırı başka metnin kaydını çalmaz.
	var stale := PackedStringArray()
	for id in VoLines.ids("act0."):
		if VoLines.is_stale(id):
			stale.append(id)
			assert_true(REWRITTEN_BRIDGES.has(id), "%s: eskimiş kayıt yalnız yeniden yazılan köprüde olabilir" % id)
			assert_eq(VoLines.audio_path(id), "", "%s: eski metinli kayıt çalınmaz, satır altyazıyla akar" % id)
			assert_false(VoLines.declared_file(id).is_empty(), "%s: kayıt yeniden üretilene dek veride durur" % id)
	if not stale.is_empty():
		print("    Eski metinli köprü kayıtları (yer tutucu; bridge-one ve bridge-two yeniden çeker): %s" % ", ".join(stale))
	for id in ["act0.narr.1", "act0.narr.4", "act0.narr.5", "act0.narr.7"]:
		assert_false(VoLines.is_stale(id), "%s değişmedi, kaydı güncel (K61: değişmeyen satıra kredi harcanmaz)" % id)


func test_vo_lines_api() -> void:
	assert_true(VoLines.has_line(SONG))
	assert_false(VoLines.has_line("act0.yok"))
	assert_true(VoLines.line("act0.yok").is_empty())
	assert_eq(VoLines.seconds("act0.yok"), 0.0, "Bilinmeyen satırın süresi yok")
	assert_eq(VoLines.ids("act0.myth.").size(), 23)
	assert_eq(VoLines.ids("act0.bard.").size(), 3)
	assert_eq(VoLines.subtitle(HEREKA, "tr"), "Bir eklendi.")
	assert_eq(VoLines.subtitle(HEREKA, "en"), "One more.")
	assert_eq(VoLines.subtitle(HEREKA, "de"), "One more.", "Bilinmeyen dilde EN'e düşer")
	assert_eq(VoLines.fx("act0.myth.11"), "", "Ozanın sözü zincir taşımaz: «Erlik.»i sessizlik taşır")
	assert_eq(VoLines.declared_file(SONG), PROLOGUE_DIR + "/act0.bard.song.mp3")
	assert_eq(VoLines.target_path(SONG), PROLOGUE_DIR + "/act0.bard.song.mp3")
	assert_eq(VoLines.target_path("act0.yok"), "")
	assert_true(VoLines.timing("act0.yok").is_empty())
	assert_true(VoLines.words(SONG_SUBS[0]).is_empty(), "Altyazı dizesinin kendi zaman dosyası yok")
	var subs := VoLines.sub_lines(SONG)
	assert_eq(str(subs[0]["tr"]), "Dolunay batarken sayıma bir eklendi,")
	assert_eq(str(subs[1]["en"]), "and the steppe learned his name from the sound of a bell.")
	assert_true(VoLines.sub_lines(BIRTH).is_empty(), "Şarkı olmayan satırın dizesi yok")
	# Önbellek: clear_cache sonrası veri yeniden okunur, aynı kalır.
	var before := VoLines.data()
	VoLines.clear_cache()
	assert_eq(VoLines.data(), before)


func test_ledger_lines_have_the_schema() -> void:
	# Defter: her API çağrısı bir JSON satırı; boş defter de geçerlidir (yorum satırı yok).
	assert_true(FileAccess.file_exists(LEDGER_PATH), "tools/vo_ledger.jsonl kurulu olmalı")
	var number := 0
	for row in FileAccess.get_file_as_string(LEDGER_PATH).split("\n", false):
		number += 1
		var entry: Variant = JSON.parse_string(row)
		assert_true(entry is Dictionary, "Defterin %d. satırı JSON sözlüğü değil: %s" % [number, row])
		if not entry is Dictionary:
			continue
		for key in LEDGER_KEYS:
			assert_true((entry as Dictionary).has(key), "Defterin %d. satırında %s yok" % [number, key])
		assert_true(PRODUCTS.has(str(entry.get("product", ""))), "Defterin %d. satırında ürün: %s" % [number, entry.get("product")])
		assert_false(entry.has("dry_run"), "Kuru koşu deftere yazılmaz (%d. satır)" % number)


# --- Yardımcılar ------------------------------------------------------------------------------

## Önsöz'ün satırları (oynanan sahnelerinkiler dışında), dosyadaki sırayla.
func _prologue_ids() -> PackedStringArray:
	var out := PackedStringArray()
	for id in VoLines.ids("act0."):
		if _scene_prefix(id).is_empty():
			out.append(id)
	return out


## Satırın oynanan sahnesinin öneki (SCENE_PREFIXES; Önsöz'ün satırıysa "").
func _scene_prefix(id: String) -> String:
	for prefix: String in SCENE_PREFIXES:
		if id.begins_with(prefix):
			return prefix
	return ""


func _group_prefix(prefixes: Array) -> String:
	return str(prefixes[0]) if not prefixes.is_empty() else ""


func _chars(ids: Array) -> int:
	var total := 0
	for id: String in ids:
		total += VoLines.chars(id)
	return total


func _tokens(text: String) -> Array:
	var out := []
	for token in text.split(" ", false):
		var word := _letters.sub(token.to_lower(), "", true)
		if not word.is_empty():
			out.append(word)
	return out


func _word_tokens(words: Array) -> Array:
	var out := []
	for word: Variant in words:
		out.append_array(_tokens(str(word.get("w", ""))))
	return out


func _any_contains(lines: PackedStringArray, fragment: String) -> bool:
	for line in lines:
		if line.contains(fragment):
			return true
	return false


## Verinin (kopyasının) satırı; yoksa boş sözlük.
func _line_of(d: Dictionary, id: String) -> Dictionary:
	for item: Variant in d.get("lines", []):
		if item is Dictionary and item.get("id") == id:
			return item
	fail("Fikstürde %s yok" % id)
	return {}


## Aynı düğümde aynı konuşmacının sesli (A) ve yazı (D) satırı.
func _add_node_conflict(d: Dictionary) -> void:
	var voiced := _line_of(d, "act0.myth.3")
	voiced["node"] = "sinama"
	var copy: Dictionary = voiced.duplicate(true)
	copy["id"] = "act0.sinama.yazi"
	copy["tier"] = "D"
	(d["lines"] as Array).append(copy)


## Sesin içe aktarıcısı (`.import`'un [remap] importer'ı; yoksa "").
func _importer(path: String) -> String:
	var cfg := ConfigFile.new()
	if cfg.load(path + ".import") != OK:
		return ""
	return str(cfg.get_value("remap", "importer", ""))


## İçe aktarılan dosyaların boyu (bayt; yoksa 0).
func _imported_bytes(path: String) -> int:
	var cfg := ConfigFile.new()
	if cfg.load(path + ".import") != OK:
		return 0
	var total := 0
	for dest: String in cfg.get_value("deps", "dest_files", []):
		if FileAccess.file_exists(dest):
			total += FileAccess.open(dest, FileAccess.READ).get_length()
	return total


## Defterin ürün başına kredi toplamı: {ürün: {credits, calls}}.
func _ledger_credits() -> Dictionary:
	var out := {}
	if not FileAccess.file_exists(LEDGER_PATH):
		return out
	for row in FileAccess.get_file_as_string(LEDGER_PATH).split("\n", false):
		var entry: Variant = JSON.parse_string(row)
		if not entry is Dictionary:
			continue
		var product := str(entry.get("product", "?"))
		if not out.has(product):
			out[product] = {"credits": 0, "calls": 0}
		out[product]["credits"] += int(entry.get("credits", 0))
		out[product]["calls"] += 1
	return out
