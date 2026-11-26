extends TestCase
## Ansiklopedi verisinin ve görsellerinin sınamaları (godot.md §3.8; K85): tools/import_encyclopedia.py'nin yazdığı
## data/kisiler.json ve data/mitler.json sitenin kaydıyla (docs-app/content/encyclopedia.json) eşleşir (kimlik
## kebab → alt çizgi, «Tanrılar ve Ruhlar» mitlerde, öteki bölümler kişilerde), soy bağları çözülür, mitlerle kişiler
## çakışmaz, her görsel ve ses yolu ya dosyadır ya boştur. İçe aktarılmış her görselin .import'u VRAM sıkıştırmalı
## (BC7) ve mipmaplidir, boy sınırı türüne göredir (art ve T-poz 1024, profil 512, küçük resim 128) ve oyun kopyası
## o boya küçültülmüştür (asıl PNG docs'tadır). Ansiklopedi sayfası kapanınca görsel başvurularını bırakır.

const SITE_JSON := "../docs-app/content/encyclopedia.json"
const IMAGE_DIR := "res://assets/ui/encyclopedia/"
const LIMITS := {"art": 1024, "pose": 1024, "portrait": 512, "thumb": 128}
const VOICE_DIR := "res://audio/vo/ency/"

var _nodes: Array[Node] = []


func before_each() -> void:
	MenuStyle.muted = true
	DestanKitabi.clear_cache()


func after_each() -> void:
	for n in _nodes:
		if is_instance_valid(n):
			n.queue_free()
	_nodes.clear()


## Sitenin ansiklopedisi (proje klasörünün yanındaki docs-app).
func _site() -> Dictionary:
	var path := ProjectSettings.globalize_path("res://").path_join(SITE_JSON).simplify_path()
	var text := FileAccess.get_file_as_string(path)
	assert_false(text.is_empty(), "Sitenin ansiklopedisi okunamadı: %s" % path)
	var parsed: Variant = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}


func _records() -> Array:
	return DestanKitabi.all_entries("kisiler") + DestanKitabi.all_entries("gok_yer")


func test_ids_match_the_site() -> void:
	var site := _site()
	var entries: Array = site.get("entries", [])
	assert_false(entries.is_empty())
	var people := {}
	for p: Dictionary in DestanKitabi.all_entries("kisiler"):
		people[str(p["id"])] = p
	var myths := {}
	for p: Dictionary in DestanKitabi.all_entries("gok_yer"):
		myths[str(p["id"])] = p
	for e: Dictionary in entries:
		var id := str(e["id"]).replace("-", "_")
		var gods := str(e["chapter"]) == "gods"
		var table := myths if gods else people
		assert_true(table.has(id), "%s → %s %s'de olmalı (tools/import_encyclopedia.py yeniden koşulmalı)" % [e["id"], id, "mitler.json" if gods else "kisiler.json"])
		if not table.has(id):
			continue
		var rec: Dictionary = table[id]
		assert_eq(str(rec["site_id"]), str(e["id"]))
		assert_eq(str(rec["section"]), str(e["chapter"]), "%s: bölüm" % id)
		assert_eq(str(rec["name"]), str(e["name"]), "%s: ad" % id)
	var site_ids := {}
	for e: Dictionary in entries:
		site_ids[str(e["id"]).replace("-", "_")] = true
	for rec: Dictionary in _records():
		if rec.get("godot_only", false):
			assert_eq(str(rec["site_id"]), "", "%s: Godot'nun kendi kaydı" % rec["id"])
			continue
		assert_true(site_ids.has(str(rec["id"])), "%s sitede yok: Godot'nun kendi kaydıysa godot_only taşımalı" % rec["id"])
	var own := _records().filter(func(r: Dictionary) -> bool: return r.get("godot_only", false)).map(func(r: Dictionary) -> String: return str(r["id"]))
	own.sort()
	assert_eq(own, ["akbulut", "birth", "doru"], "Sitede olmayan kayıtlar: iki at ve «Doğum»")


func test_myths_and_people_do_not_collide_and_lineage_resolves() -> void:
	var seen := {}
	for rec: Dictionary in _records():
		var id := str(rec["id"])
		assert_false(seen.has(id), "Kimlik iki kez geçiyor: %s" % id)
		seen[id] = true
		assert_false(id.contains("-"), "%s: Godot kimliği alt çizgilidir" % id)
	for rec: Dictionary in _records():
		var lineage: Dictionary = rec.get("lineage", {})
		for key in ["up", "down", "side"]:
			for rel: Dictionary in lineage.get(key, []):
				assert_true(seen.has(str(rel["id"])), "%s: soy bağı çözülmüyor: %s" % [rec["id"], rel["id"]])
	for p: Dictionary in DestanKitabi.all_entries("gok_yer"):
		assert_eq(str(p["section"]), "gods", "%s: mitler «Tanrılar ve Ruhlar»dandır" % p["id"])
	for p: Dictionary in DestanKitabi.all_entries("kisiler"):
		assert_ne(str(p["section"]), "gods", "%s: kişiler tanrı bölümünden olmaz" % p["id"])


func test_every_image_and_voice_path_is_a_file_or_empty() -> void:
	var with_art := 0
	for rec: Dictionary in _records():
		var images: Dictionary = rec.get("images", {})
		for kind in LIMITS:
			var path := str(images.get(kind, ""))
			if path.is_empty():
				continue
			assert_true(FileAccess.file_exists(path), "%s: %s dosyası yok: %s" % [rec["id"], kind, path])
			assert_eq(path, IMAGE_DIR + str(rec["id"]) + "/" + kind + ".png", "%s: görsel yolu" % rec["id"])
		var expected_missing := not FileAccess.file_exists(IMAGE_DIR + str(rec["id"]) + "/art.png")
		assert_eq(str(images.get("art", "")).is_empty(), expected_missing, "%s: eksik görselin yolu boş, olanınki dolu" % rec["id"])
		if not str(images.get("art", "")).is_empty():
			with_art += 1
		var audio := str(rec.get("intro_audio", ""))
		if not audio.is_empty():
			assert_true(FileAccess.file_exists(audio), "%s: tanıtım sesi yok: %s" % [rec["id"], audio])
			assert_eq(audio, VOICE_DIR + str(rec["id"]) + ".mp3")
			assert_true(rec.get("speaks", true), "%s: konuşmayan kişinin tanıtım sesi olmaz" % rec["id"])
	assert_true(with_art > 0, "Hiç görsel içe aktarılmamış (tools/import_encyclopedia.py --images)")
	for id in ["umay", "mene"]:
		var rec: Dictionary = DestanKitabi.find_record(id).get("record", {})
		assert_false(rec.get("speaks", true), "%s oyunda konuşmaz (K86)" % id)
		assert_eq(str(rec.get("intro_audio", "")), "", "%s: hoparlör hiç yok" % id)


func test_imported_images_are_vram_compressed_with_mipmaps_and_limits() -> void:
	var dirs := DirAccess.get_directories_at(IMAGE_DIR)
	assert_false(dirs.is_empty(), "%s boş" % IMAGE_DIR)
	var checked := 0
	for d in dirs:
		for kind: String in LIMITS:
			var path := IMAGE_DIR.path_join(d).path_join(kind + ".png")
			if not FileAccess.file_exists(path):
				continue
			checked += 1
			var cfg := ConfigFile.new()
			assert_eq(cfg.load(path + ".import"), OK, "%s.import yok" % path)
			assert_eq(cfg.get_value("remap", "importer", ""), "texture", path)
			assert_eq(cfg.get_value("params", "compress/mode", -1), 2, "%s: VRAM sıkıştırmalı" % path)
			assert_eq(cfg.get_value("params", "compress/high_quality", false), true, "%s: BC7" % path)
			assert_eq(cfg.get_value("params", "mipmaps/generate", false), true, "%s: mipmapli" % path)
			assert_eq(cfg.get_value("params", "process/size_limit", 0), LIMITS[kind], "%s: boy sınırı" % path)
			var dest: Array = cfg.get_value("deps", "dest_files", [])
			assert_false(dest.is_empty(), "%s: Godot içe aktarmamış" % path)
			var size := _png_size(path)
			# Kaynaklar sınırdan büyüktür: oyun kopyasının uzun kenarı tam sınırdadır (dikey art 683 × 1024).
			assert_eq(maxi(size.x, size.y), LIMITS[kind], "%s: oyun kopyası sınıra küçültülmeli (%s)" % [path, size])
			if kind in ["portrait", "thumb"]:
				assert_eq(size.x, size.y, "%s kare" % path)
	assert_true(checked > 0, "Hiç görsel denetlenmedi")
	for d in dirs:
		for f in DirAccess.get_files_at(IMAGE_DIR.path_join(d)):
			assert_false(f.ends_with(".webp") or f.begins_with("_portrait-ref"), "%s/%s: WebP ve yüz referansı oyuna girmez" % [d, f])


func test_page_releases_its_images_when_closed() -> void:
	var holder := Control.new()
	holder.size = Vector2(1920, 892)
	add_child(holder)
	_nodes.append(holder)
	var flags := {JourneyFlags.PROLOGUE: true, JourneyFlags.STABLE: true}
	var page := EncyclopediaPage.new("kisiler", flags)
	UIKit.full_rect(page)
	holder.add_child(page)
	var shown := ""
	for e in DestanKitabi.entries("kisiler", flags):
		if not str(e["images"]["art"]).is_empty() and ResourceLoader.exists(str(e["images"]["art"])):
			shown = str(e["id"])
			break
	if shown.is_empty():
		fail("Görseli içe aktarılmış kişi yok")
		return
	page.open_entry(shown)
	for i in 120:
		if page.pending_paths().is_empty():
			break
		await wait_frames(1)
	assert_true(page.cached_paths().has(str(page.get_selected()["images"]["art"])), "Seçili kişinin art'ı yüklenir")
	assert_true(page.cached_paths().size() <= 9, "Yalnız seçili kişi ve iki komşusu (en çok 3 × 3 görsel): %d" % page.cached_paths().size())
	holder.remove_child(page)
	assert_eq(page.cached_paths().size(), 0, "Kapanınca görseller bırakılır")
	assert_eq(page.pending_paths().size(), 0, "Bekleyen yüklemeler teslim alınıp bırakılır")
	page.free()


## PNG'nin boyu (IHDR'den; dosyayı çözmeden).
static func _png_size(path: String) -> Vector2i:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return Vector2i.ZERO
	f.big_endian = true
	f.seek(16)
	var w := f.get_32()
	var h := f.get_32()
	return Vector2i(w, h)


## Kitap oyuncunundur: tasarım belgesi atfı (K numarası, «story.md §3») ve sitenin «Oyundaki yeri» bölümü oyuna geçmez
## (tools/import_encyclopedia.py: player_text, SITE_ONLY_SECTIONS).
func test_book_text_has_no_design_references() -> void:
	var refs := RegEx.create_from_string("\\bK\\d{1,3}\\b|\\.md\\b|§|\\bGodot\\b")
	for pair: Array in [["res://data/kisiler.json", "people"], ["res://data/mitler.json", "myths"]]:
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(pair[0]))
		for rec: Dictionary in data[pair[1]]:
			var texts: Array = [rec.get("era_note", ""), rec.get("source_note", "")]
			for sec: Dictionary in rec.get("sections", []):
				assert_true(str(sec["title"]) != "Oyundaki yeri", "%s: «Oyundaki yeri» yalnız sitededir" % rec["id"])
				texts.append(sec["text"])
			for fact: Dictionary in rec.get("facts", []):
				texts.append(fact["value"])
			for text: Variant in texts:
				assert_true(refs.search(str(text)) == null, "%s: belge atfı kaldı: %s" % [rec["id"], str(text).left(80)])
