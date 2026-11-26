extends TestCase
## Ücretsiz varlıkların işareti (E7.5, K89; assets/_free: FREE_ASSETS.json, usage.jsonl, LICENSES.md; Varlıklar
## kataloğu docs/assets/catalog.json):
##   - assets/_free altındaki her dosya (_staging, LICENSES.md, FREE_ASSETS.json ve usage.jsonl dışında) bir kayda
##     bağlıdır: <kind>/<id>/ klasörü kaydın türü ve kimliğidir. Kayıt FREE_ASSETS.json'dadır; denetim henüz
##     birleştirmediyse yeni indirme usage.jsonl'da «new»: true ile tam kayıt olarak durur.
##   - Her kaydın alanları tamdır, lisansı CC0 ya da kamu malıdır ve URL'siyle LICENSES.md'de yazılıdır.
##   - Kullanılan kaydın (usedIn'i dolu ya da usage.jsonl'da satırı olan) dosyası _staging dışındadır (path) ve
##     _staging'de kopyası kalmaz; _staging'den taşınan her kayıt kullanılır, kullanılmayanın dosyası _staging'de durur.
##   - usedIn ve usage.jsonl «sahne:düğüm yolu» yazar; FREE_ASSETS.json'un catalog'u ile katalog satırının free'si aynı
##     bağı iki yandan yazar.
##   - Sahnelerde assets/_free'ye başvuran her düğüm free_asset meta verisini taşır:
##       · .tscn'de: düğüme yazılan başvuru (örneklenen sahne ya da özellik; alt kaynak zinciri ve .tres bir düzey)
##         assets/_free/<kind>/<id>/'ye gidiyorsa düğüm metadata/free_asset = <id> taşır. Dizi değerli özellik
##         (preloaded gibi yükleme listesi) kullanım sayılmaz: listedeki varlığı kullanan düğümü betik kurar, kurulan
##         sahnede denetlenir. Hiçbir dosya _staging'e başvurmaz.
##       · Kurulan sahnede (usedIn'de, usage.jsonl'da adı geçen; assets/_free'yi kendisi ya da betiği anan sahneler;
##         CineScene konaksız setup({}) ve build_all ile, is_ready'li sahne hazır olana dek): düğümün kendisinin çizdiği
##         ya da çaldığı kaynak (örneklendiği sahne ve motorun kaydedilen özellikleri: ağ ve yüzey malzemeleri, malzeme,
##         gölgelendirici dokuları, ortam ve gök, ses akışı) assets/_free'den geliyorsa düğüm o kimliği taşır; ücretsiz
##         sahnenin (glTF) içindeki düğümde işaret örneğin kökündedir. Betik değişkenleri (kurucunun girdisi, yükleme
##         listesi, önbellek) sayılmaz: kurdukları düğümler denetlenir.
##       · usedIn'deki ve usage.jsonl'daki her «sahne:düğüm» kurulan sahnede durur ve o kimliği taşır.
##   - Meshy modeli gelen varlık (replacedBy: modelin dosyası) kayıttan silinmez, replaceLater false olur; usedIn ve catalog
##     boştur ve kurulan sahnede hiçbir düğüm onu çizmez. Dosyası yerinde kalır: model yokken kurulan kodla çizim kullanır.
##     fallbackIn'deki her «sahne:düğüm» (ve usage.jsonl'un aynı satırı) sahne modelsiz kurulunca (MeshyProp.models_enabled
##     kapalı) durur ve o kimliği taşır; modelsiz kurulumda da işaretsiz düğüm olmaz.
##   - Motion-studio videosu gelen varlık da aynı kuraldadır (K93; fabric034, replacedBy assets/cine/video/*.ogv): yedek düğümler
##     CineVideo.enabled kapalıyken durur. Videoyu ana oturum kopyalar: dosya henüz yoksa ya da sahne keçe kipindeyse o sahnede
##     yedek çizilir, «çizmemeli» denetimi o sahneye uygulanmaz; dosya gelince kendiliğinden işler.
## Denetleyicilerin kendisi küçük örneklerle sınanır (işaretsiz düğüm, kayda bağlanmayan dosya, CC0 olmayan lisans
## yakalanır).

const FREE_ROOT := "res://assets/_free/"
const ASSETS_FILE := "res://assets/_free/FREE_ASSETS.json"
const USAGE_FILE := "res://assets/_free/usage.jsonl"
const LICENSES_FILE := "res://assets/_free/LICENSES.md"
## Defterin kendi dosyaları: kayda bağlanmaz.
const LEDGER_FILES: Array[String] = ["FREE_ASSETS.json", "LICENSES.md", "usage.jsonl"]
## Varlıklar kataloğu (proje klasörünün yanındaki docs).
const CATALOG_JSON := "../docs/assets/catalog.json"
const KINDS: Array[String] = ["texture", "model", "hdri", "sound"]
## Kaydın dolu olması gereken alanları; yeni indirmenin usage.jsonl satırı da bunları taşır.
const RECORD_FIELDS: Array[String] = ["id", "name", "kind", "source", "url", "license", "author", "plannedUse",
	"regenWith"]
## assets/_free'yi anan betiklerin aranmadığı klasör (sınamalar yolu dizge olarak yazar).
const SCRIPT_SCAN_SKIP: Array[String] = ["res://tests"]
## Kurulumun en uzun bekleyişi (saniye; childhood_ordos iş parçacığı işleri ve kare bütçesiyle kurulur).
const READY_TIMEOUT := 90.0
## Kaynak ağacında en çok derinlik (düğüm → ortam → gök → malzeme → doku).
const MAX_DEPTH := 8
## Metin sahnesinin bölüm başlığı.
const SECTION := "^\\[(gd_scene|gd_resource|ext_resource|sub_resource|node|connection|editable|resource)[ \\]]"

var _trash: Array[Node] = []
## Kaynak → ücretsiz kimlikleri (bir sahnenin denetimi boyunca: paylaşılan malzeme bir kez gezilir).
var _resource_cache: Dictionary = {}


func before_each() -> void:
	Engine.time_scale = 1.0
	MeshyProp.models_enabled = true
	CineVideo.enabled = true


func after_each() -> void:
	MeshyProp.models_enabled = true
	CineVideo.enabled = true
	for node in _trash:
		if is_instance_valid(node):
			_release(node)
	_trash.clear()
	_resource_cache.clear()
	CineActor.clear_cache()
	Engine.time_scale = 1.0


# --- Dosyalar ve kayıtlar ---------------------------------------------------------------------------

func test_every_file_belongs_to_a_record() -> void:
	# Denetleyici: klasörsüz dosya, kaydı olmayan kimlik ve türü tutmayan klasör yakalanır.
	var fixture := {"dirt": {"id": "dirt", "kind": "texture"}}
	var caught := unbound_files(PackedStringArray(["texture/dirt/dirt.jpg", "texture/dirt/dirt.jpg.import",
		"texture/loose.jpg", "model/unknown/m.gltf", "sound/dirt/a.wav", "notes.txt"]), fixture)
	assert_eq(caught, PackedStringArray(["texture/loose.jpg", "model/unknown/m.gltf", "sound/dirt/a.wav", "notes.txt"]),
		"Denetleyici kayda bağlanmayan dosyaları bulmalı")
	for ledger in LEDGER_FILES:
		assert_true(FileAccess.file_exists(FREE_ROOT + ledger), "Defterin dosyası: assets/_free/%s" % ledger)
	var files := PackedStringArray()
	for path in list_files(FREE_ROOT):
		files.append(path.trim_prefix(FREE_ROOT))
	assert_false(files.size() <= LEDGER_FILES.size(), "assets/_free'de defterden başka dosya da olmalı")
	for rel in unbound_files(files, _all_records()):
		fail("assets/_free/%s bir kayda bağlı değil: dosya assets/_free/<kind>/<id>/ altında durur, kaydı FREE_ASSETS.json'da (ya da yeni indirmeyse usage.jsonl'da «new»: true ile) olur" % rel)


func test_records_are_complete_cc0_or_public_domain_and_listed() -> void:
	for license in ["CC0 1.0", "Kamu malı (ABD federal hükümeti eseri)", "Public Domain"]:
		assert_true(is_free_license(license), "%s kabul edilir" % license)
	for license in ["CC BY 4.0", "CC BY-SA 3.0", "GPL 3.0", "CC0-like", ""]:
		assert_false(is_free_license(license), "«%s» kabul edilmez" % license)
	var licenses := FileAccess.get_file_as_string(LICENSES_FILE)
	assert_false(licenses.is_empty(), "LICENSES.md okunmalı")
	var records := _records()
	assert_false(records.is_empty(), "FREE_ASSETS.json'da kayıt olmalı")
	var seen := {}
	var pending: Array[Dictionary] = []
	for line in _usage():
		if bool(line.get("new", false)):
			pending.append(line)
	for rec in records + pending:
		var id := str(rec.get("id", ""))
		for field in RECORD_FIELDS:
			assert_false(str(rec.get(field, "")).strip_edges().is_empty(), "%s: %s alanı dolu olmalı" % [id, field])
		var size: Variant = rec.get("sizeMB")
		assert_true((size is float or size is int) and float(size) > 0.0, "%s: sizeMB sayı olmalı" % id)
		assert_true(KINDS.has(str(rec.get("kind", ""))), "%s: tür %s'den biri (%s)" % [id, KINDS, rec.get("kind")])
		assert_true(is_free_license(str(rec.get("license", ""))), "%s: lisans CC0 ya da kamu malı olmalı (%s)" % [id, rec.get("license")])
		var url := str(rec.get("url", ""))
		assert_true(not url.is_empty() and licenses.contains(url), "%s: LICENSES.md'de URL'siyle yazılı olmalı (%s)" % [id, url])
		assert_false(seen.has(id), "%s: kimlik bir kez" % id)
		seen[id] = true
	for rec in records:
		var id := str(rec.get("id", ""))
		assert_true(rec.get("usedIn") is Array, "%s: usedIn dizi" % id)
		assert_true(rec.get("catalog", []) is Array, "%s: catalog dizi" % id)
		var model := str(rec.get("replacedBy", ""))
		if model.is_empty():
			assert_eq(rec.get("replaceLater"), true, "%s: replaceLater true (sonra yeniden üretilir)" % id)
			continue
		assert_eq(rec.get("replaceLater"), false, "%s: Meshy modeli geldi, yeniden üretim beklemez" % id)
		if _is_video(model) and not ResourceLoader.exists("res://" + model):
			print("    %s: %s henüz yok, keçe yedeği oynar (dosya denetimi atlandı)" % [id, model])
		else:
			assert_true(ResourceLoader.exists("res://" + model), "%s: replacedBy modelin dosyası (%s)" % [id, model])
		assert_true(str(rec.get("regenWith", "")).contains(model), "%s: regenWith modelin geldiğini yazar" % id)
		assert_true((rec.get("usedIn", []) as Array).is_empty(), "%s: modeli gelen varlık oyunda çizilmez (usedIn boş)" % id)
		assert_true((rec.get("catalog", []) as Array).is_empty(), "%s: katalog satırının yerini model tutar (catalog boş)" % id)
		assert_false((rec.get("fallbackIn", []) as Array).is_empty(), "%s: kodla çizimin düğümleri fallbackIn'de" % id)


func test_used_assets_are_moved_out_of_staging() -> void:
	var used_by_usage := {}
	for line in _usage():
		used_by_usage[str(line.get("id", ""))] = true
	var moved_count := 0
	var all := _all_records()
	for id: String in all:
		var rec: Dictionary = all[id]
		var folder := FREE_ROOT + "%s/%s" % [rec.get("kind", ""), id]
		var moved := DirAccess.dir_exists_absolute(folder)
		var used_in: Array = rec.get("usedIn", []) if rec.get("usedIn") is Array else []
		# Kodla çizimin yedeği de kullanımdır: dosya yerinde kalmalı.
		used_in = used_in + (rec.get("fallbackIn", []) as Array)
		var used := not used_in.is_empty() or used_by_usage.has(id)
		var staging := str(rec.get("stagingPath", "")) if rec.get("stagingPath") != null else ""
		if moved:
			moved_count += 1
			assert_true(used, "%s _staging'den taşınmış ama kullanılmıyor (usedIn de usage.jsonl de boş)" % id)
			if not staging.is_empty():
				assert_false(_exists(FREE_ROOT + staging), "%s taşınmalı, kopyalanmamalı: _staging'de de duruyor (%s)" % [id, staging])
		elif used:
			fail("%s kullanılıyor: dosyası _staging'den assets/_free/%s/%s/'ye taşınmalı" % [id, rec.get("kind", ""), id])
		else:
			assert_true(_exists(FREE_ROOT + staging), "%s kullanılmıyor: dosyası _staging'de durmalı (%s)" % [id, staging])
		if not used_in.is_empty():
			var path := str(rec.get("path", ""))
			assert_true(path.begins_with("%s/%s/" % [rec.get("kind", ""), id]), "%s: path assets/_free/<kind>/<id>/ altında (%s)" % [id, path])
			assert_true(_exists(FREE_ROOT + path), "%s: path diskte olmalı (%s)" % [id, path])
			assert_false(rec.has("stagingPath"), "%s: kullanılan kaydın stagingPath'i kalmaz (path yazılır)" % id)
	assert_true(moved_count > 0, "Oyuna alınmış en az bir ücretsiz varlık olmalı")


func test_used_in_and_usage_lines_name_scene_nodes() -> void:
	var scene_node := RegEx.create_from_string("^([^:]+\\.tscn):(.+)$")
	var records := {}
	for rec in _records():
		records[str(rec.get("id", ""))] = rec
		for entry: Variant in (rec.get("usedIn", []) as Array) + (rec.get("fallbackIn", []) as Array):
			var m := scene_node.search(str(entry))
			assert_not_null(m, "%s: usedIn «sahne.tscn:düğüm yolu» olmalı (%s)" % [rec.get("id"), entry])
			if m:
				assert_true(ResourceLoader.exists("res://" + m.get_string(1)), "%s: sahne var (%s)" % [rec.get("id"), entry])
	var lines := _usage()
	assert_false(lines.is_empty(), "usage.jsonl'da kullanım satırı olmalı")
	for i in lines.size():
		var line := lines[i]
		var where := "usage.jsonl %d. satır" % (i + 1)
		assert_false(line.is_empty(), "%s JSON sözlüğü olmalı" % where)
		var id := str(line.get("id", ""))
		assert_false(id.is_empty(), "%s: id" % where)
		var m := scene_node.search(str(line.get("usedIn", "")))
		assert_not_null(m, "%s: usedIn «sahne.tscn:düğüm yolu» olmalı (%s)" % [where, line.get("usedIn")])
		if m:
			assert_true(ResourceLoader.exists("res://" + m.get_string(1)), "%s: sahne var (%s)" % [where, line.get("usedIn")])
		assert_false(str(line.get("batch", "")).is_empty(), "%s: batch (işi yapan grup)" % where)
		assert_true(line.get("catalog", "") is String, "%s: catalog dizge (boş olabilir)" % where)
		if not records.has(id):
			assert_true(bool(line.get("new", false)), "%s: %s FREE_ASSETS.json'da yok; yeni indirmeyse «new»: true ve tam kayıt" % [where, id])


func test_catalog_rows_and_records_agree() -> void:
	var path := ProjectSettings.globalize_path("res://").path_join(CATALOG_JSON).simplify_path()
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(parsed is Dictionary, "Varlıklar kataloğu okunmalı: %s" % path)
	if not parsed is Dictionary:
		return
	var rows := {}
	for row: Variant in (parsed as Dictionary).get("assets", []):
		if row is Dictionary:
			rows[str(row.get("id", ""))] = row
	var records := {}
	for rec in _records():
		records[str(rec.get("id", ""))] = rec
	var linked := 0
	for id: String in records:
		for row_id: Variant in records[id].get("catalog", []):
			linked += 1
			assert_true(rows.has(str(row_id)), "%s: katalog satırı %s yok" % [id, row_id])
			if rows.has(str(row_id)):
				var free: Variant = rows[str(row_id)].get("free", [])
				assert_true(free is Array and (free as Array).has(id), "Katalog %s'in free alanı %s'i yazmalı" % [row_id, id])
	for row_id: String in rows:
		var free: Variant = rows[row_id].get("free")
		if free == null:
			continue
		assert_true(free is Array and not (free as Array).is_empty(), "Katalog %s: free boş olmayan dizi" % row_id)
		for id: Variant in (free if free is Array else []):
			assert_true(records.has(str(id)), "Katalog %s: free %s FREE_ASSETS.json'da yok" % [row_id, id])
			if records.has(str(id)):
				assert_true((records[str(id)].get("catalog", []) as Array).has(row_id), "%s'in catalog'u %s'i yazmalı" % [id, row_id])
	assert_true(linked > 0, "Kullanılan en az bir varlık bir katalog satırının yerini tutmalı")


# --- Sahne dosyaları --------------------------------------------------------------------------------

func test_scene_scan_follows_sub_resources_and_skips_load_lists() -> void:
	var text := "\n".join(PackedStringArray([
		"[gd_scene format=3]",
		"",
		"[ext_resource type=\"Texture2D\" path=\"res://assets/_free/texture/fixture_tex/a.jpg\" id=\"1_tex\"]",
		"[ext_resource type=\"PackedScene\" path=\"res://assets/_free/model/fixture_model/m.gltf\" id=\"2_model\"]",
		"[ext_resource type=\"Material\" path=\"res://materials/fixture.tres\" id=\"3_mat\"]",
		"",
		"[sub_resource type=\"StandardMaterial3D\" id=\"Mat\"]",
		"albedo_texture = ExtResource(\"1_tex\")",
		"",
		"[sub_resource type=\"Environment\" id=\"Env\"]",
		"sky = SubResource(\"Sky\")",
		"",
		"[sub_resource type=\"Sky\" id=\"Sky\"]",
		"sky_material = SubResource(\"Mat\")",
		"",
		"[node name=\"Root\" type=\"Node3D\"]",
		"preloaded = Array[Resource]([ExtResource(\"1_tex\"),",
		"ExtResource(\"2_model\")])",
		"",
		"[node name=\"Floor\" type=\"MeshInstance3D\" parent=\".\"]",
		"material_override = SubResource(\"Mat\")",
		"",
		"[node name=\"Model\" parent=\"Floor\" instance=ExtResource(\"2_model\")]",
		"metadata/free_asset = \"fixture_model\"",
		"",
		"[node name=\"Env\" type=\"WorldEnvironment\" parent=\".\"]",
		"environment = SubResource(\"Env\")",
		"metadata/free_asset = [\"fixture_tex\"]",
		"",
		"[node name=\"Wall\" type=\"MeshInstance3D\" parent=\".\"]",
		"material_override = ExtResource(\"3_mat\")",
		"",
	]))
	var parsed := parse_text_resource(text)
	var paths: Array = []
	for node: Dictionary in parsed["nodes"]:
		paths.append(node["path"])
	assert_eq(paths, [".", "Floor", "Floor/Model", "Env", "Wall"], "Düğüm yolları başlıklardan")
	# .tres bir düzey: sahnenin başvurduğu .tres'in ücretsiz kimlikleri düğüme sayılır.
	var tres := {"res://materials/fixture.tres": {"fixture_wall": true}}
	assert_eq(unmarked_scene_nodes(parsed, tres), PackedStringArray(["Floor: fixture_tex", "Wall: fixture_wall"]),
		"Alt kaynak zinciri ve .tres izlenir, işaretsiz düğümler yakalanır, yükleme listesi sayılmaz")
	assert_eq(free_id_of("res://assets/_free/model/wooden_spoon/textures/x.jpg"), "wooden_spoon")
	assert_eq(free_id_of("res://assets/_free/_staging/polyhaven/dirt/x.jpg"), "")
	assert_eq(free_id_of("res://assets/characters/mother/mother.glb"), "")


func test_scene_files_mark_their_free_references() -> void:
	var files := list_files("res://", PackedStringArray(["tscn", "tres"]))
	assert_false(files.is_empty(), "Sahne dosyaları bulunmalı")
	var tres_ids := {}
	for path in files:
		if path.get_extension() != "tres":
			continue
		var parsed := parse_text_resource(FileAccess.get_file_as_string(path))
		var refs: Array = []
		for sub: Dictionary in (parsed["subs"] as Dictionary).values():
			refs.append_array(sub["refs"])
		var ids := ref_ids(refs, parsed, {})
		if not ids.is_empty():
			tres_ids[path] = ids
	for path in files:
		var text := FileAccess.get_file_as_string(path)
		assert_false(text.contains(FREE_ROOT + "_staging"), "%s _staging'e başvuruyor: varlık önce assets/_free/<kind>/<id>/'ye taşınır" % path)
		if path.get_extension() != "tscn":
			continue
		for problem in unmarked_scene_nodes(parse_text_resource(text), tres_ids):
			fail("%s › %s: düğüm assets/_free'ye başvuruyor ama metadata/free_asset bu kimliği taşımıyor" % [path, problem])


# --- Kurulan sahneler -------------------------------------------------------------------------------

func test_walk_finds_free_resources_drawn_by_nodes() -> void:
	var tex := _fixture_texture("texture/fixture_tex/a.png")
	var model_tex := _fixture_texture("model/fixture_model/textures/b.png")
	var root := Node3D.new()
	root.name = "Root"
	_box().add_child(root)
	var marked := MeshInstance3D.new()
	marked.name = "Marked"
	marked.mesh = BoxMesh.new()
	var std := StandardMaterial3D.new()
	std.albedo_texture = tex
	(marked.mesh as BoxMesh).material = std
	marked.set_meta(&"free_asset", "fixture_tex")
	root.add_child(marked)
	var unmarked := MeshInstance3D.new()
	unmarked.name = "Unmarked"
	unmarked.mesh = BoxMesh.new()
	var shader := Shader.new()
	shader.code = "shader_type spatial;\nuniform sampler2D mottle_tex;\nvoid fragment() { ALBEDO = texture(mottle_tex, UV).rgb; }\n"
	var shader_mat := ShaderMaterial.new()
	shader_mat.shader = shader
	shader_mat.set_shader_parameter(&"mottle_tex", tex)
	unmarked.set_surface_override_material(0, shader_mat)
	root.add_child(unmarked)
	var sky_node := WorldEnvironment.new()
	sky_node.name = "Sky"
	var sky_mat := PanoramaSkyMaterial.new()
	sky_mat.panorama = tex
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	sky_node.environment = env
	root.add_child(sky_node)
	# Ücretsiz sahnenin örneği: içindeki düğümün işareti örneğin kökündedir.
	var model := Node3D.new()
	model.name = "Model"
	model.scene_file_path = FREE_ROOT + "model/fixture_model/m.gltf"
	model.set_meta(&"free_asset", "fixture_model")
	root.add_child(model)
	var part := MeshInstance3D.new()
	part.name = "Part"
	part.mesh = BoxMesh.new()
	var part_mat := StandardMaterial3D.new()
	part_mat.albedo_texture = model_tex
	part.material_override = part_mat
	model.add_child(part)
	part.owner = model
	var plain := Node3D.new()
	plain.name = "Plain"
	root.add_child(plain)
	assert_eq(unmarked_free_nodes(root), PackedStringArray(["Unmarked: fixture_tex", "Sky: fixture_tex"]),
		"Yüzey malzemesindeki ve gökteki doku yakalanır; işaretli düğüm ve örneğin içi geçer")
	model.remove_meta(&"free_asset")
	_resource_cache.clear()
	assert_eq(unmarked_free_nodes(root), PackedStringArray(["Unmarked: fixture_tex", "Sky: fixture_tex",
		"Model: fixture_model", "Model/Part: fixture_model"]), "İşaretsiz örnek ve içi yakalanır")


func test_built_scenes_mark_every_free_node() -> void:
	var used := _used_nodes()
	var scenes := _scenes_to_build()
	assert_false(scenes.is_empty(), "Ücretsiz varlık kullanan sahne bulunmalı")
	var replaced := {}
	for rec in _records():
		if rec.has("replacedBy"):
			replaced[str(rec.get("id", ""))] = rec["replacedBy"]
	for scene_path in scenes:
		var root: Node = await _build(scene_path)
		if root == null:
			continue
		var rel := scene_path.trim_prefix("res://")
		_resource_cache.clear()
		for problem in unmarked_free_nodes(root):
			fail("%s › %s: düğüm ücretsiz varlığı kullanıyor ama free_asset bu kimliği taşımıyor" % [rel, problem])
		var drawing := nodes_drawing(root)
		for id: String in replaced:
			if _draws_video_fallback(root, str(replaced[id])):
				continue
			assert_false(drawing.has(id), "%s: %s'nin modeli geldi (%s), sahne onu çizmemeli" % [rel, id, replaced[id]])
		for entry: Array in used.get(scene_path, []):
			var node := root.get_node_or_null(NodePath(str(entry[1])))
			assert_not_null(node, "%s: %s:%s düğümü kurulan sahnede yok" % [entry[2], rel, entry[1]])
			if node:
				assert_true(marks_of(free_mark(node)).has(str(entry[0])),
					"%s: %s:%s free_asset = %s taşımalı (%s)" % [entry[2], rel, entry[1], entry[0], node.get_meta(&"free_asset", "")])
		var box := root.get_parent()
		_release(box)
		_trash.erase(box)
		_resource_cache.clear()
		await wait_frames(2)


func test_fallback_nodes_stand_when_the_models_are_off() -> void:
	var fallback := _fallback_nodes()
	assert_false(fallback.is_empty(), "Kodla çizim yedeği olan kayıt bulunmalı")
	MeshyProp.models_enabled = false
	CineVideo.enabled = false
	for scene_path: String in fallback:
		var root: Node = await _build(scene_path)
		if root == null:
			continue
		var rel := scene_path.trim_prefix("res://")
		_resource_cache.clear()
		for problem in unmarked_free_nodes(root):
			fail("%s (modelsiz) › %s: düğüm ücretsiz varlığı kullanıyor ama free_asset bu kimliği taşımıyor" % [rel, problem])
		# Denetleyici yedeğin dokusunu görür: model varken «çizmez» denetimi boşa dönmez (birleştirilen ağ kaynağını söylemez,
		# onun işareti aşağıda düğümden sınanır).
		var drawing := nodes_drawing(root)
		var seen := 0
		for entry: Array in fallback[scene_path]:
			var node := root.get_node_or_null(NodePath(str(entry[1])))
			assert_not_null(node, "fallbackIn: %s:%s düğümü modelsiz kurulumda yok" % [rel, entry[1]])
			if node:
				assert_true(marks_of(free_mark(node)).has(str(entry[0])), "fallbackIn: %s:%s free_asset = %s taşımalı" % [rel, entry[1], entry[0]])
			if drawing.has(str(entry[0])):
				seen += 1
		assert_true(seen > 0, "%s: modelsiz kurulumda kodla çizimin ücretsiz varlığı görülmeli" % rel)
		var box := root.get_parent()
		_release(box)
		_trash.erase(box)
		_resource_cache.clear()
		await wait_frames(2)
	MeshyProp.models_enabled = true


# --- Denetleyiciler (saf) ---------------------------------------------------------------------------

## Yerini tutan dosya video mu (K93; motion-studio'dan gelir, gelene dek keçe yedeği oynar)?
static func _is_video(replacement: String) -> bool:
	return replacement.ends_with(".ogv")


## Sahne, yerini video tutan varlığı yedek olarak çiziyor mu (sahnenin video değişkeni boş: dosya yok ya da açılmadı)?
static func _draws_video_fallback(root: Node, replacement: String) -> bool:
	return _is_video(replacement) and &"video" in root and root.get(&"video") == null


## Lisans CC0 ya da kamu malı mı (E7.5: NC, ND, SA, BY ve belirsiz lisans alınmaz).
static func is_free_license(license: String) -> bool:
	var l := license.strip_edges().to_lower()
	return l == "cc0" or l.begins_with("cc0 ") or l.begins_with("kamu malı") or l.begins_with("public domain")


## assets/_free/<kind>/<id>/... yolunun kimliği; değilse ya da _staging'deyse boş.
static func free_id_of(path: String) -> String:
	var p := path.get_slice("::", 0)
	if not p.begins_with(FREE_ROOT):
		return ""
	var parts := p.trim_prefix(FREE_ROOT).split("/")
	return parts[1] if parts.size() >= 3 and not parts[0].begins_with("_") else ""


## Düğümün free_asset meta verisi (yoksa null; get_meta'nın null varsayılanı eksik anahtarda hata yazar).
static func free_mark(node: Node) -> Variant:
	return node.get_meta(&"free_asset") if node.has_meta(&"free_asset") else null


## free_asset meta verisinin kimlikleri (tek kimlik ya da kimlik dizisi).
static func marks_of(meta: Variant) -> PackedStringArray:
	var out := PackedStringArray()
	if meta is String or meta is StringName:
		out.append(str(meta))
	elif meta is Array or meta is PackedStringArray:
		for v: Variant in meta:
			out.append(str(v))
	return out


## assets/_free'ye göreli dosyalardan kayda bağlanmayanlar: <kind>/<id>/... ve kaydın türü o klasör.
static func unbound_files(files: PackedStringArray, records: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	for rel in files:
		if LEDGER_FILES.has(rel):
			continue
		var parts := rel.split("/")
		var rec: Dictionary = records.get(parts[1], {}) if parts.size() >= 3 else {}
		if rec.is_empty() or str(rec.get("kind", "")) != parts[0]:
			out.append(rel)
	return out


## dir altındaki dosyalar (gizliler, .gdignore'lu ve atlanan klasörler dışında); exts boşsa hepsi.
static func list_files(dir: String, exts: PackedStringArray = PackedStringArray(), skip: Array[String] = []) -> PackedStringArray:
	var out := PackedStringArray()
	_list_into(dir, exts, skip, out)
	return out


static func _list_into(dir: String, exts: PackedStringArray, skip: Array[String], out: PackedStringArray) -> void:
	if skip.has(dir.trim_suffix("/")) or FileAccess.file_exists(dir.path_join(".gdignore")):
		return
	for f in DirAccess.get_files_at(dir):
		if not f.begins_with(".") and (exts.is_empty() or exts.has(f.get_extension())):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		if not d.begins_with("."):
			_list_into(dir.path_join(d), exts, skip, out)


## Metin sahnesinin (.tscn) ya da kaynağının (.tres) başvuruları: ext (kimlik → yol), subs (kimlik → başvurular;
## .tres'in kökü «» kimliğiyle) ve düğümler (yol, başvurular, free_asset meta verisi). Düğümün dizi değerli özelliği
## (yükleme listesi) sayılmaz; çok satırlı değerin devamı kendi özelliğine yazılır.
static func parse_text_resource(text: String) -> Dictionary:
	var header := RegEx.create_from_string(SECTION)
	var prop := RegEx.create_from_string("^([A-Za-z_][A-Za-z0-9_/:.\\-]*) = (.*)$")
	var ref_ext := RegEx.create_from_string("ExtResource\\(\\s*\"([^\"]+)\"\\s*\\)")
	var ref_sub := RegEx.create_from_string("SubResource\\(\\s*\"([^\"]+)\"\\s*\\)")
	var ext := {}
	var subs := {}
	var nodes: Array[Dictionary] = []
	var section: Dictionary = {}
	var kind := ""
	var in_list := false
	for raw in text.split("\n"):
		var line := raw.strip_edges()
		var head := header.search(line)
		if head:
			kind = head.get_string(1)
			in_list = false
			section = {}
			match kind:
				"ext_resource":
					ext[_attr(line, "id")] = _attr(line, "path")
				"sub_resource", "resource":
					section = {"refs": []}
					subs[_attr(line, "id") if kind == "sub_resource" else ""] = section
				"node":
					var node_name := _attr(line, "name")
					var parent := _attr(line, "parent")
					var path := "." if not line.contains(" parent=\"") else (node_name if parent == "." else parent + "/" + node_name)
					section = {"path": path, "refs": [], "meta": null}
					for m in ref_ext.search_all(line):
						(section["refs"] as Array).append(["ext", m.get_string(1)])
					nodes.append(section)
			continue
		if section.is_empty():
			continue
		var value := line
		var p := prop.search(line)
		if p:
			value = p.get_string(2)
			in_list = kind == "node" and (value.begins_with("Array[") or value.begins_with("["))
			if kind == "node" and p.get_string(1) == "metadata/free_asset":
				section["meta"] = JSON.parse_string(value)
		if in_list:
			continue
		for m in ref_ext.search_all(value):
			(section["refs"] as Array).append(["ext", m.get_string(1)])
		for m in ref_sub.search_all(value):
			(section["refs"] as Array).append(["sub", m.get_string(1)])
	return {"ext": ext, "subs": subs, "nodes": nodes}


## Başvuruların ücretsiz kimlikleri: alt kaynaklar zincirle, .tres bir düzey (tres_ids: yol → kimlikler).
static func ref_ids(refs: Array, parsed: Dictionary, tres_ids: Dictionary, seen: Dictionary = {}) -> Dictionary:
	var ids := {}
	for ref: Array in refs:
		if ref[0] == "ext":
			var path := str((parsed["ext"] as Dictionary).get(ref[1], ""))
			var id := free_id_of(path)
			if not id.is_empty():
				ids[id] = true
			ids.merge(tres_ids.get(path, {}))
		elif not seen.has(ref[1]):
			seen[ref[1]] = true
			var sub: Dictionary = (parsed["subs"] as Dictionary).get(ref[1], {})
			ids.merge(ref_ids(sub.get("refs", []), parsed, tres_ids, seen))
	return ids


## .tscn'in işaretsiz düğümleri: «düğüm yolu: kimlik».
static func unmarked_scene_nodes(parsed: Dictionary, tres_ids: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	for node: Dictionary in parsed["nodes"]:
		var marks := marks_of(node["meta"])
		for id: String in ref_ids(node["refs"], parsed, tres_ids):
			if not marks.has(id):
				out.append("%s: %s" % [node["path"], id])
	return out


## Kurulan ağacın işaretsiz düğümleri: «düğüm yolu: kimlik» (kök «.»).
func unmarked_free_nodes(root: Node) -> PackedStringArray:
	var out := PackedStringArray()
	var nodes: Array[Node] = [root]
	nodes.append_array(root.find_children("*", "", true, false))
	for node in nodes:
		var ids := node_free_ids(node)
		if ids.is_empty():
			continue
		var marks := marks_of(free_mark(node))
		var inst := node.owner
		if marks.is_empty() and inst != null and inst != root and inst.scene_file_path.begins_with(FREE_ROOT):
			marks = marks_of(free_mark(inst))
		for id: String in ids:
			if not marks.has(id):
				out.append("%s: %s" % [root.get_path_to(node), id])
	return out


## Kurulan ağaçta çizilen ya da çalınan ücretsiz varlıklar: {kimlik: true}.
func nodes_drawing(root: Node) -> Dictionary:
	var ids := {}
	for node: Node in root.find_children("*", "", true, false):
		ids.merge(node_free_ids(node))
	return ids


## Düğümün kendisinin çizdiği ya da çaldığı ücretsiz varlıklar: örneklendiği sahne ve motorun kaydedilen özellikleri
## (ağ ve yüzey malzemeleri, malzeme, gölgelendirici dokuları, ortam ve gök, ses akışı).
func node_free_ids(node: Node) -> Dictionary:
	var ids := {}
	var own := free_id_of(node.scene_file_path)
	if not own.is_empty():
		ids[own] = true
	for prop: Dictionary in node.get_property_list():
		if _is_engine_object(prop):
			var value: Variant = node.get(prop["name"])
			if value is Resource:
				ids.merge(_resource_ids(value, 0))
	var mi := node as MeshInstance3D
	if mi:
		for i in mi.get_surface_override_material_count():
			ids.merge(_resource_ids(mi.get_surface_override_material(i), 0))
	return ids


## Kaynağın ve alt kaynaklarının ücretsiz kimlikleri (ağın yüzey malzemeleri, gölgelendiricinin dokuları dahil).
func _resource_ids(res: Resource, depth: int) -> Dictionary:
	if res == null or res is Script or depth > MAX_DEPTH:
		return {}
	var key := res.get_instance_id()
	if _resource_cache.has(key):
		return _resource_cache[key]
	var ids := {}
	_resource_cache[key] = ids
	var own := free_id_of(res.resource_path)
	if not own.is_empty():
		ids[own] = true
	var children: Array[Resource] = []
	var mesh := res as Mesh
	if mesh:
		for i in mesh.get_surface_count():
			children.append(mesh.surface_get_material(i))
	var shader_mat := res as ShaderMaterial
	if shader_mat and shader_mat.shader:
		for param_name in _sampler_names(shader_mat.shader):
			var param: Variant = shader_mat.get_shader_parameter(param_name)
			if param is Resource:
				children.append(param)
	for prop: Dictionary in res.get_property_list():
		if _is_engine_object(prop):
			var value: Variant = res.get(prop["name"])
			if value is Resource:
				children.append(value)
	for child in children:
		ids.merge(_resource_ids(child, depth + 1))
	return ids


## Gölgelendiricinin doku tekdüzenleri: başsız sürücüde tekdüzen listesi boş gelebilir, bildirimler koddan da okunur.
static func _sampler_names(shader: Shader) -> PackedStringArray:
	var out := PackedStringArray()
	for uniform: Dictionary in shader.get_shader_uniform_list():
		out.append(str(uniform["name"]))
	var decl := RegEx.create_from_string("uniform\\s+(?:\\w+\\s+)*sampler\\w*\\s+(\\w+)")
	for m in decl.search_all(shader.code):
		if not out.has(m.get_string(1)):
			out.append(m.get_string(1))
	return out


## Motorun kaydedilen nesne özelliği mi (betik değişkeni ve betiğin kendisi değil).
static func _is_engine_object(prop: Dictionary) -> bool:
	var usage := int(prop["usage"])
	return int(prop["type"]) == TYPE_OBJECT and (usage & PROPERTY_USAGE_STORAGE) != 0 \
		and (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0 and str(prop["name"]) != "script"


# --- Yardımcılar ------------------------------------------------------------------------------------

## FREE_ASSETS.json'un kayıtları.
func _records() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ASSETS_FILE))
	if parsed is Dictionary and (parsed as Dictionary).get("assets") is Array:
		for rec: Variant in parsed["assets"]:
			if rec is Dictionary:
				out.append(rec)
	return out


## usage.jsonl'un satırları (sözlük olmayan satır boş sözlük olarak gelir; sınama yakalar).
func _usage() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for line in FileAccess.get_file_as_string(USAGE_FILE).split("\n", false):
		if line.strip_edges().is_empty():
			continue
		var parsed: Variant = JSON.parse_string(line)
		out.append(parsed if parsed is Dictionary else {})
	return out


## Kimlik → kayıt: FREE_ASSETS.json'dakiler ve denetimin henüz birleştirmediği yeni indirmeler («new»: true).
func _all_records() -> Dictionary:
	var out := {}
	for rec in _records():
		out[str(rec.get("id", ""))] = rec
	for line in _usage():
		var id := str(line.get("id", ""))
		if bool(line.get("new", false)) and not out.has(id):
			out[id] = line
	return out


## Sahne (res://) → [kimlik, düğüm yolu, kaynak] (FREE_ASSETS.json'un usedIn'i ve usage.jsonl; kodla çizim yedeğinin satırları
## hariç: onlar modelsiz kurulumda denetlenir).
func _used_nodes() -> Dictionary:
	var rows: Array = []
	var fallback := {}
	for rec in _records():
		for entry: Variant in rec.get("fallbackIn", []):
			fallback["%s|%s" % [rec.get("id", ""), entry]] = true
		for entry: Variant in rec.get("usedIn", []):
			rows.append([str(rec.get("id", "")), str(entry), "FREE_ASSETS.json"])
	for line in _usage():
		if not fallback.has("%s|%s" % [line.get("id", ""), line.get("usedIn", "")]):
			rows.append([str(line.get("id", "")), str(line.get("usedIn", "")), "usage.jsonl"])
	return _by_scene(rows)


## Sahne (res://) → [kimlik, düğüm yolu, kaynak]: kodla çizim yedeğinin düğümleri (FREE_ASSETS.json'un fallbackIn'i).
func _fallback_nodes() -> Dictionary:
	var rows: Array = []
	for rec in _records():
		for entry: Variant in rec.get("fallbackIn", []):
			rows.append([str(rec.get("id", "")), str(entry), "FREE_ASSETS.json"])
	return _by_scene(rows)


## [kimlik, «sahne:düğüm», kaynak] satırları sahneye göre gruplanır.
static func _by_scene(rows: Array) -> Dictionary:
	var out := {}
	for row: Array in rows:
		var entry: String = row[1]
		var colon := entry.find(":")
		if colon < 0:
			continue
		var scene := "res://" + entry.substr(0, colon)
		if not out.has(scene):
			out[scene] = []
		(out[scene] as Array).append([row[0], entry.substr(colon + 1), row[2]])
	return out


## Kurulacak sahneler: usedIn'de ve usage.jsonl'da adı geçenler, assets/_free'yi anan ve betiği assets/_free'yi anan
## sahneler.
func _scenes_to_build() -> PackedStringArray:
	var scenes := _used_nodes()
	var scripts := PackedStringArray()
	for path in list_files("res://", PackedStringArray(["gd"]), SCRIPT_SCAN_SKIP):
		if FileAccess.get_file_as_string(path).contains(FREE_ROOT):
			scripts.append(path)
	for path in list_files("res://", PackedStringArray(["tscn"])):
		var text := FileAccess.get_file_as_string(path)
		var uses := text.contains(FREE_ROOT)
		for script in scripts:
			uses = uses or text.contains("\"%s\"" % script)
		if uses:
			scenes[path] = true
	var out := PackedStringArray(scenes.keys())
	out.sort()
	return out


## Sahneyi kendi dünyası olan bir SubViewport'ta kurar (sınamanın dünyasına dokunmaz): CineScene konaksız setup({}),
## build_all varsa bütün kurulum, is_ready varsa hazır olana dek.
func _build(scene_path: String) -> Node:
	var packed := load(scene_path) as PackedScene
	assert_not_null(packed, "%s yüklenmeli" % scene_path)
	if packed == null:
		return null
	var root := packed.instantiate()
	_box().add_child(root)
	if root is CineScene:
		(root as CineScene).setup({})
	if root.has_method(&"build_all"):
		root.call(&"build_all")
	var deadline := Time.get_ticks_msec() + int(READY_TIMEOUT * 1000.0)
	while root.has_method(&"is_ready") and not bool(root.call(&"is_ready")) and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	if root.has_method(&"is_ready"):
		assert_true(bool(root.call(&"is_ready")), "%s %.0f sn içinde kurulmalı" % [scene_path, READY_TIMEOUT])
	await wait_frames(1)
	return root


## Kendi dünyası olan, çizilmeyen SubViewport (sahne sınamanın dünyasına ve ortamına dokunmaz).
func _box() -> SubViewport:
	var box := SubViewport.new()
	box.own_world_3d = true
	box.size = Vector2i(64, 64)
	box.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(box)
	_trash.append(box)
	return box


## Kurulan sahneyi bırakır (sinema sahnesi önce geri yüklenir).
func _release(box: Node) -> void:
	if not is_instance_valid(box):
		return
	for child in box.get_children():
		if child is CineScene:
			(child as CineScene).restore()
	box.queue_free()


## Diskte olmayan, bellekte ücretsiz yolu taşıyan küçük doku (denetleyicinin örneği).
func _fixture_texture(rel: String) -> ImageTexture:
	var tex := ImageTexture.create_from_image(Image.create(4, 4, false, Image.FORMAT_RGBA8))
	tex.resource_path = FREE_ROOT + rel
	return tex


static func _exists(path: String) -> bool:
	return FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path.trim_suffix("/"))


static func _attr(line: String, attr: String) -> String:
	var m := RegEx.create_from_string("(^|[\\s\\[])%s=\"([^\"]*)\"" % attr).search(line)
	return m.get_string(2) if m else ""
