extends TestCase
## Klip kütüphanesi (K90; ClipLibrary, data/clip_library.json) ve belge sitesine dışa aktarması
## (tools/clip_library_export.gd): tanım (oyunun beş klibi, E9 paketinin taşıyıcı klipleri ve türetilmiş klipler), beden ve öbek eşlemesi,
## bağışçı ve taşıyıcı seçimi, kaynak çözümü (oyunun klibi > ham alım > bağışçı ya da taşıyıcı), oyunun döngü kuralları,
## alımların okunması (toplu alım, metinden hareket) ve kredi özeti, kök kaydırma (zemin payı) ve omuz düzeltmesinin
## pişirilmesi, gerçek modellerle aktarım; aracın yardımcıları (öbekler, taşıyıcılar, kredi, kişinin çeşitleri, sahnelerin seçimleri), yazılmış
## manifest.json'un sözleşmesi, GLB'lerin animasyon adları ve dışa aktarılmış kliplerin temas kemikleriyle zemine oturması.

const SIX: Array[String] = ["mete", "hero_f", "mother", "father", "elder", "child"]
const ARMS: Array[String] = ["LeftShoulder", "LeftArm", "LeftForeArm", "LeftHand", "RightShoulder", "RightArm", "RightForeArm", "RightHand"]
const CORE: Array[String] = ["idle_3", "idle_4", "sit", "walk", "run"]
const CARRIER := "_anim_library"
const EXPORT := preload("res://tools/clip_library_export.gd")


## Gerçek kadronun altı modeli var mı? Yoksa test atlanır ve bu konsola yazılır (sessizce geçmesin).
func _has_models(what: String = "") -> bool:
	var missing := SIX.filter(func(id: String) -> bool: return not StandIn.has_model(id))
	if not missing.is_empty():
		print("        (atlandı%s: modeli olmayan karakterler %s)" % [": " + what if not what.is_empty() else "", missing])
	return missing.is_empty()


## Sahte tanım: bir satın alınmış hareket (idle_x) ve oturma; dört kişi ve bir kalabalık kişisi.
func _fake_definition() -> Dictionary:
	return {
		"rule": "K90",
		"clips": [
			{"key": "idle_x", "role": "idle", "meshy_action": 900, "kind": "purchase", "loop": true,
				"donors": {"male": "m1", "female": "f1", "child": "f1"}},
			{"key": "sit", "role": "sit", "meshy_action": 363, "kind": "purchase", "loop": true,
				"donors": {"male": "m1", "female": "f1", "child": "c1"}},
		],
		"characters": {
			"m1": {"tr": "Er", "body": "male", "group": "player"},
			"m2": {"body": "male", "group": "named"},
			"f1": {"body": "female", "group": "named"},
			"c1": {"body": "child", "group": "named"},
			"z9": {"body": "male", "group": "crowd"},
		},
	}


## Sahte tanıma bir taşıyıcı ("pack") ve onun iki klibi: toplu alımdan bir hareket (wave) ve bir metinden hareket.
func _fake_carrier_definition() -> Dictionary:
	var def := _fake_definition()
	def["carriers"] = {"pack": {"tr": "Paket", "dir": "pack_dir", "model_of": "m1"}}
	(def["clips"] as Array).append({"key": "wave", "tr": "El sallama", "en": "Wave", "role": "work", "meshy_action": 901, "meshy_name": "Wave",
		"kind": "purchase", "loop": true, "carrier": "pack", "file": "anim_batch_01.glb", "note_tr": "Paket"})
	(def["clips"] as Array).append({"key": "ground_a", "tr": "Yerde A", "en": "Ground a", "role": "sit", "meshy_action": null,
		"meshy_name": "retarget_clip", "kind": "purchase", "loop": false, "carrier": "pack", "file": "motion_anim_ground_a.glb",
		"motion": "ground_a", "note_tr": "Metinden"})
	return def


func _source(kind: String, role: String, path: String = "") -> Dictionary:
	return {"kind": kind, "path": path, "role": role}


func _instantiate(id: String) -> Node3D:
	return (load(StandIn.model_path(id)) as PackedScene).instantiate() as Node3D


func _rotation_tracks(anim: Animation) -> int:
	var count := 0
	for t in anim.get_track_count():
		if anim.track_get_type(t) == Animation.TYPE_ROTATION_3D:
			count += 1
	return count


# --- Tanım ------------------------------------------------------------------------------------

func test_definition_lists_core_clips_and_the_e9_pack() -> void:
	var lib := ClipLibrary.new()
	assert_eq(lib.definition.get("rule"), "K90")
	assert_true(str(lib.definition.get("_aciklama", "")).contains("K90"), "Açıklama K90 kuralını anlatmalı")
	var keys := lib.clip_keys()
	assert_eq(keys.slice(0, 5), PackedStringArray(CORE), "Oyunun beş klibi başta")
	assert_eq(keys.size(), 122, "5 oyun klibi + E9'un 100 hazır hareketi, 9 metinden hareketi, 6 türetilmiş klibi, E14'ün yay nişanı ve zıplama (anim_batch_12)")
	var seen := {}
	var actions := {}
	for key in keys:
		assert_false(seen.has(key), "Yinelenen anahtar: %s" % key)
		seen[key] = true
		var action: Variant = lib.clip(key).get("meshy_action")
		if action != null:
			assert_false(actions.has(int(action)), "K90: Meshy hareketi %d kütüphanede iki kez (%s, %s)" % [int(action), actions.get(int(action)), key])
			actions[int(action)] = key
	assert_eq(lib.key_for_action(243), "idle_3")
	assert_eq(lib.key_for_action(244), "idle_4")
	assert_eq(lib.key_for_action(363), "sit")
	assert_eq(lib.key_for_action(246), "idle_6", "E9'un hareketi de kütüphanede")
	assert_eq(lib.key_for_action(999), "", "Kütüphanede olmayan hareket")
	for key in CORE:
		var spec := lib.clip(key)
		assert_true(CharacterAvatar.ROLES.has(StringName(lib.role_of(key))), "%s rolü CharacterAvatar rolü olmalı" % key)
		assert_eq(lib.carrier_of(key), "", "%s oyunun klibi, taşıyıcısı yok" % key)
		for field in ["tr", "en", "kind", "note_tr"]:
			assert_false(str(spec.get(field, "")).is_empty(), "%s: %s alanı boş" % [key, field])
		for body in ClipLibrary.BODIES:
			assert_false(str(spec.get("donors", {}).get(body, "")).is_empty(), "%s: %s bedeninin bağışçısı yok" % [key, body])
	assert_eq(lib.clip("idle_3")["donors"], {"male": "hero_f", "female": "hero_f", "child": "hero_f"}, "Kaynağı oyun dosyası: geliştirmede de dışa aktarılmış oyunda da aynı")
	assert_eq(lib.clip("idle_4")["donors"], {"male": "mete", "female": "mete", "child": "mete"})
	assert_eq(lib.clip("sit")["donors"], {"male": "father", "female": "mother", "child": "child"})
	assert_eq(lib.clip("walk")["kind"], "rig")
	assert_null(lib.clip("run")["meshy_action"], "İskelet hediyesinin Meshy hareketi yok")
	assert_eq(lib.keys_for_role("idle"), PackedStringArray(["idle_3", "idle_4"]), "Taşıyıcı klipleri oyunun rol çözümüne girmez")
	assert_eq(lib.keys_for_role("sit"), PackedStringArray(["sit"]))
	# E9 paketi: taşıyıcı iskeletin klipleri.
	assert_eq(lib.carrier_ids(), [CARRIER])
	assert_eq(lib.carrier(CARRIER).get("model_of"), "mete")
	assert_true(lib.is_carrier(CARRIER))
	assert_false(lib.is_carrier("mete"))
	var carried := lib.carrier_keys(CARRIER)
	assert_eq(carried.size(), 117)
	var batch := 0
	var motions := 0
	var derived := 0
	var roles: Array[String] = []
	for r in CharacterAvatar.ROLES:
		roles.append(String(r))
	roles.append_array(ClipLibrary.EXTRA_ROLES)
	for key in carried:
		var spec := lib.clip(key)
		assert_true(roles.has(lib.role_of(key)), "%s: bilinmeyen rol %s" % [key, lib.role_of(key)])
		for field in ["tr", "en", "note_tr", "group", "resource"]:
			assert_false(str(spec.get(field, "")).is_empty(), "%s: %s alanı boş" % [key, field])
		if lib.role_of(key) in ["sit_down", "stand_up"]:
			assert_false(spec.get("loop"), "%s geçiştir, bir kez oynar" % key)
		if spec.get("kind") == ClipLibrary.KIND_DERIVED:
			derived += 1
			assert_null(spec.get("meshy_action"), "%s: türetilmiş klip satın alınmaz" % key)
			assert_eq(spec.get("credits"), 0.0, "%s: 0 kredi" % key)
			continue
		assert_eq(spec.get("kind"), "purchase", key)
		for field in ["file", "meshy_name"]:
			assert_false(str(spec.get(field, "")).is_empty(), "%s: %s alanı boş" % [key, field])
		if spec.get("motion") != null:
			motions += 1
			assert_null(spec.get("meshy_action"), "%s: metinden hareketin Meshy hareket numarası yok" % key)
			assert_eq(spec.get("file"), "motion_anim_%s.glb" % spec["motion"])
		else:
			batch += 1
			assert_true(str(spec.get("file")).begins_with("anim_batch_"), "%s toplu alımın GLB'sinde" % key)
	assert_eq(batch, 102, "E9'un 100 hazır hareketi, E14'ün yay nişanı ve zıplama (anim_batch_12, Meshy 466)")
	assert_eq(motions, 9)
	assert_eq(derived, 6)


func test_body_and_group_cover_the_cast() -> void:
	var lib := ClipLibrary.new()
	var bodies := {
		"male": ["mete", "father", "elder", "teoman", "older_brother", "counter", "crowd_hun_man", "crowd_hun_rider"],
		"female": ["hero_f", "mother", "lan_hatun", "hereka", "hereka_young", "crowd_hun_woman"],
		"child": ["child"],
	}
	for body in bodies:
		for id in bodies[body]:
			assert_eq(lib.body_of(id), body, "%s bedeni" % id)
	for id in ["mete", "hero_f"]:
		assert_eq(lib.group_of(id), "player")
	for id in ["crowd_hun_man", "crowd_hun_woman", "crowd_hun_rider"]:
		assert_eq(lib.group_of(id), "crowd")
	for id in ["mother", "father", "elder", "child", "teoman", "lan_hatun", "older_brother", "hereka", "hereka_young", "counter"]:
		assert_eq(lib.group_of(id), "named", id)
	assert_eq(lib.body_of("nobody"), "", "Kütüphanede olmayan kişinin bedeni bilinmez")
	assert_eq(lib.group_of("crowd_new"), "crowd")
	assert_eq(lib.group_of("nobody"), "named")
	assert_eq(lib.name_of("hero_f"), "Kadın Kahraman")
	# asset_plan.json'daki her kişinin bedeni kütüphanede olmalı (yeni kişi önce buraya eklenir).
	var plan: Variant = ClipLibrary.read_json(ClipLibrary.ASSET_PLAN_PATH)
	if plan is Dictionary:
		for row in (plan as Dictionary).get("assets", []):
			if row is Dictionary and row.get("kind") == "character":
				assert_false(lib.body_of(str(row["id"])).is_empty(), "%s kütüphanede yok" % row["id"])


# --- Bağışçı, taşıyıcı ve kaynak çözümü (sahte kayıtlarla) -----------------------------------------------

func test_donor_for_follows_body_and_falls_back_to_a_local_holder() -> void:
	var lib := ClipLibrary.new(_fake_definition())
	lib.set_native_sources("m1", {"idle_x": _source("raw", "idle"), "sit": _source("game", "sit")})
	lib.set_native_sources("m2", {})
	lib.set_native_sources("f1", {"idle_x": _source("raw", "idle")})
	lib.set_native_sources("c1", {"sit": _source("game", "sit")})
	lib.set_native_sources("z9", {"idle_x": _source("game", "idle")})
	var all := ["m1", "m2", "f1", "c1"]
	assert_eq(lib.donor_for("idle_x", "m2", all), "m1", "Erkeğe erkek bağışçı")
	assert_eq(lib.donor_for("idle_x", "c1", all), "f1", "Çocuğa kütüphanedeki çocuk bağışçısı")
	assert_eq(lib.donor_for("sit", "f1", all), "m1", "Kadın bağışçısının klibi kendinde değil: öteki bedenin bağışçısına düşer")
	assert_eq(lib.donor_for("sit", "m2", ["m2", "f1", "c1"]), "c1", "Modeli olmayan bağışçı atlanır; aktarılmış klip yeniden aktarılmaz")
	assert_eq(lib.donor_for("idle_x", "m2", ["m2", "z9"]), "z9", "Bağışçılar yoksa klibi kendinde olan herhangi biri")
	assert_eq(lib.donor_for("idle_x", "m1", ["m1", "m2"]), "", "Kişi kendine bağışçı olmaz; kimsede yoksa boş")
	assert_eq(lib.donor_for("nope", "m2", all), "", "Kütüphanede olmayan klip")


func test_carrier_clips_come_from_the_carrier_unless_the_character_bought_them() -> void:
	var lib := ClipLibrary.new(_fake_carrier_definition())
	lib.set_native_sources("pack", {"wave": _source("raw", "work", "/ham/anim_batch_01.glb"), "ground_a": _source("raw", "sit", "/ham/motion_anim_ground_a.glb")})
	lib.set_native_sources("m1", {"idle_x": _source("raw", "idle")})
	lib.set_native_sources("m2", {"wave": _source("raw", "work", "/ham/m2_animation_901.glb")})
	lib.set_native_sources("f1", {})
	lib.set_native_sources("c1", {})
	for id in ["m1", "m2", "f1", "c1"]:
		lib.set_game_clips(id, {})
	var all := ["m1", "m2", "f1", "c1"]
	assert_eq(lib.raw_dir("pack"), "pack_dir", "Taşıyıcının klasörü tanımdan")
	assert_eq(lib.raw_dir("m1"), "m1")
	assert_eq(lib.carrier_keys(), PackedStringArray(["wave", "ground_a"]))
	assert_eq(lib.carrier_keys("pack"), PackedStringArray(["wave", "ground_a"]))
	assert_eq(lib.keys_for_role("sit"), PackedStringArray(["sit"]), "Taşıyıcının oturuşu oyunun oturma rolüne karışmaz")
	assert_eq(lib.donor_for("wave", "f1", all), "pack")
	var f1 := lib.resolve("f1", all)
	assert_eq(f1["wave"]["source"], ClipLibrary.RETARGET)
	assert_eq(f1["wave"]["donor"], "pack")
	assert_false(f1["wave"]["game_role"])
	assert_eq(f1["ground_a"]["donor"], "pack")
	var m2 := lib.resolve("m2", all)
	assert_eq(m2["wave"]["source"], ClipLibrary.NATIVE_RAW, "Karakter hareketi kendisi için almışsa kendi alımı önce gelir")
	assert_null(m2["wave"]["donor"])
	lib.set_native_sources("pack", {})
	assert_eq(lib.donor_for("wave", "f1", all), "m2", "Taşıyıcıda klip yoksa klibi kendinde olana düşer")
	assert_eq(lib.resolve("c1", ["c1"])["ground_a"]["source"], ClipLibrary.MISSING)


func test_resolve_prefers_game_clip_then_raw_purchase_then_donor() -> void:
	var lib := ClipLibrary.new(_fake_definition())
	lib.set_native_sources("m1", {"idle_x": _source("raw", "idle", "/ham/m1_animation_900.glb"), "sit": _source("game", "sit", "res://m1.glb")})
	lib.set_game_clips("m1", {"sit": {"key": "sit", "role": "sit", "source": "native", "donor": null, "path": "res://m1.glb"}})
	lib.set_native_sources("f1", {"idle_x": _source("raw", "idle")})
	lib.set_game_clips("f1", {"sit": {"key": "sit", "role": "sit", "source": "retarget", "donor": "m1", "path": "res://f1_sit.res"}})
	lib.set_native_sources("m2", {})
	lib.set_game_clips("m2", {})
	var all := ["m1", "m2", "f1"]
	var m1 := lib.resolve("m1", all)
	assert_eq(m1["sit"]["source"], ClipLibrary.NATIVE)
	assert_true(m1["sit"]["game_role"])
	assert_eq(m1["idle_x"]["source"], ClipLibrary.NATIVE_RAW, "Oyunda kullanılmayan satın alınmış klip")
	assert_false(m1["idle_x"]["game_role"])
	assert_null(m1["idle_x"]["donor"])
	var f1 := lib.resolve("f1", all)
	assert_eq(f1["sit"]["source"], ClipLibrary.RETARGET, "Oyunun aktarılmış klibi kaynaktır")
	assert_eq(f1["sit"]["donor"], "m1")
	assert_true(f1["sit"]["game_role"])
	var m2 := lib.resolve("m2", all)
	assert_eq(m2["idle_x"]["source"], ClipLibrary.RETARGET)
	assert_eq(m2["idle_x"]["donor"], "m1")
	assert_eq(m2["sit"]["donor"], "m1")
	var alone := lib.resolve("m2", ["m2"])
	assert_eq(alone["sit"]["source"], ClipLibrary.MISSING, "Bağışçı yoksa klip eksik")


func test_res_provenance_record_beats_stale_donor_table() -> void:
	# Bağışçı tablosundaki kayıt, .res kişinin kendi klibi diye yazılmamışsa geçerlidir. Tablo burada sahtedir
	# (character_fit_tool.gd DONORS'taki eski «mete: sit → father» kaydı gibi): kayıt silinse de sınama aynı kalır.
	var stale := {"sit": "father"}
	assert_eq(ClipLibrary.res_provenance("sit", false, true, stale), ClipLibrary.RETARGET)
	assert_eq(ClipLibrary.res_provenance("sit", true, true, stale), ClipLibrary.NATIVE,
		"meta.json'da kişinin kendi klibi diye yazılıysa tablodaki eski bağışçı geçersiz")
	assert_eq(ClipLibrary.res_provenance("sit", false, true, {"sit": "mother"}), ClipLibrary.RETARGET)
	assert_eq(ClipLibrary.res_provenance("walk", false, false, {}), ClipLibrary.NATIVE, "Kaydı olmayan eski klasörde yürüme kişinin kendi klibi")
	assert_eq(ClipLibrary.res_provenance("idle", false, true, {}), "", "Kaynağı bilinmeyen .res sayılmaz")


# --- Alımlar ve kredi -------------------------------------------------------------------------------------

func test_actions_from_tasks_splits_batches_and_skips_unknown_tasks() -> void:
	var tasks := {
		"model": {"id": "00", "status": "SUCCEEDED", "consumed_credits": 40},
		"anim_243": {"id": "01", "status": "SUCCEEDED", "consumed_credits": 3},
		"anim_batch_01": {"id": "02", "status": "SUCCEEDED", "consumed_credits": 9, "action_ids": [243, 600, 601]},
		"anim_batch_02": {"id": "03", "status": "FAILED", "consumed_credits": null, "action_ids": [602]},
		"anim_batch_03": {"id": "04", "status": "SUCCEEDED", "consumed_credits": 10, "action_ids": [610, 611, 612]},
		"anim_unknown": {"id": "05", "status": "SUCCEEDED", "consumed_credits": 3},
	}
	var records := ClipLibrary.actions_from_tasks("pack", tasks)
	assert_eq(records.size(), 8, "anim_243 bir kayıt, toplu alım hareket başına; hareket numarası olmayan görev atlanır")
	var batch := records.filter(func(r: Dictionary) -> bool: return r["task"] == "04")
	assert_eq(batch.map(func(r: Dictionary) -> int: return r["credits"]), [4, 3, 3], "Kredi eşit bölünür, kalan ilk kayda")
	assert_eq(batch.map(func(r: Dictionary) -> int: return r["order"]), [0, 1, 2])
	assert_eq(batch[0]["character"], "pack")
	records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["task"] < b["task"] or (a["task"] == b["task"] and a["order"] < b["order"]))
	# Toplu alımdaki 243 tekrar alımdır (K90): özet onu da sayar.
	assert_eq(ClipLibrary.credit_summary(records), {"spent_on_actions": 22, "purchases": 7, "distinct_actions": 6, "duplicate_credits": 3})


func test_motions_from_tasks_pair_generation_and_application() -> void:
	var tasks := {
		"rig": {"id": "09", "status": "SUCCEEDED", "consumed_credits": 5},
		"motion_ground_a": {"id": "10", "status": "SUCCEEDED", "consumed_credits": 10},
		"motion_anim_ground_a": {"id": "11", "status": "SUCCEEDED", "consumed_credits": 3},
		"motion_ground_b": {"id": "12", "status": "SUCCEEDED", "consumed_credits": 10},
	}
	var motions := ClipLibrary.motions_from_tasks("pack", tasks)
	assert_eq(motions.size(), 2)
	assert_eq(motions[0], {"character": "pack", "motion": "ground_a", "status": "SUCCEEDED", "credits": 13, "task": "11"})
	assert_eq(motions[1]["motion"], "ground_b")
	assert_eq(motions[1]["status"], "NOT_APPLIED", "Uygulanmamış hareket alınmış sayılmaz")
	assert_eq(motions[1]["credits"], 10)
	assert_true(ClipLibrary.actions_from_tasks("pack", tasks).is_empty(), "Metinden hareket Meshy hareket alımı değildir")


func test_credit_summary_counts_duplicate_purchases() -> void:
	var records := [
		{"character": "a", "action": 243, "status": "SUCCEEDED", "credits": 3, "task": "01"},
		{"character": "b", "action": 243, "status": "SUCCEEDED", "credits": 3, "task": "02"},
		{"character": "c", "action": 363, "status": "FAILED", "credits": 0, "task": "03"},
		{"character": "d", "action": 363, "status": "SUCCEEDED", "credits": 3, "task": "04"},
	]
	assert_eq(ClipLibrary.credit_summary(records), {"spent_on_actions": 9, "purchases": 3, "distinct_actions": 2, "duplicate_credits": 3})


func test_real_credit_summary_counts_every_anim_task() -> void:
	# Bağımsız sayım: bütün meshy.json'lardaki anim_* görevleri (toplu alım dahil). Özet bir görevi atlarsa tutmaz.
	var lib := ClipLibrary.new()
	var spent := 0
	var purchases := 0
	var actions := {}
	for dir in DirAccess.get_directories_at(ClipLibrary.RAW_ROOT):
		var data: Variant = ClipLibrary.read_json(ClipLibrary.RAW_ROOT.path_join(dir).path_join("meshy.json"))
		if not data is Dictionary or not (data as Dictionary).get("tasks") is Dictionary:
			continue
		for name in data["tasks"]:
			var task: Variant = data["tasks"][name]
			if not str(name).begins_with("anim_") or not task is Dictionary:
				continue
			spent += ClipLibrary.task_credits(task)
			var ids: Array = task["action_ids"] if task.get("action_ids") is Array else [str(name).trim_prefix("anim_").to_int()]
			if task.get("status") == "SUCCEEDED":
				purchases += ids.size()
				for a in ids:
					actions[int(a)] = true
	var summary := ClipLibrary.credit_summary(lib.all_purchases())
	assert_eq(summary["spent_on_actions"], spent, "Bütün anim_* görevlerinin kredisi")
	assert_eq(summary["purchases"], purchases, "Toplu alım hareket başına bir alım")
	assert_eq(summary["distinct_actions"], actions.size())
	if not FileAccess.file_exists(ProjectSettings.globalize_path(ClipLibrary.RAW_ROOT.path_join("mete/meshy.json"))):
		print("        (atlandı: ham Meshy kayıtları yok)")
		return
	# K90: ilk turun 15 kredilik tekrarı dışında tekrar alım yok (E9 paketi 243, 244 ve 363'ü yeniden almadı). Yeni bir
	# tekrar alım bu sınamayı bilerek düşürür.
	assert_eq(summary["duplicate_credits"], 15, "Tekrar alımlar: %s" % summary)
	assert_true(summary["purchases"] >= 108 and summary["distinct_actions"] >= 103, "E9'un 100 hareketi özette: %s" % summary)
	var first := {}
	for p in lib.all_purchases():
		if p["status"] == "SUCCEEDED" and not first.has(p["action"]):
			first[p["action"]] = p["character"]
	assert_eq(first.get(243), "mete")
	assert_eq(first.get(244), "mete")
	assert_eq(first.get(363), "child")
	assert_eq(first.get(246), CARRIER, "E9'un hareketleri taşıyıcı için alındı")
	var motions := lib.motion_purchases(CARRIER)
	assert_eq(motions.size(), 9, "E9'un dokuz metinden hareketi")
	for m in motions:
		assert_eq(m["status"], "SUCCEEDED", m["motion"])
		assert_eq(m["credits"], 13, "%s: text-to-motion 10 + uygulama 3" % m["motion"])


# --- Gerçek kadro -------------------------------------------------------------------------------------

func test_real_cast_resolves_like_the_game() -> void:
	if not _has_models():
		return
	var lib := ClipLibrary.new()
	var all := lib.characters_with_models()
	for id in SIX:
		assert_true(all.has(id), "%s modeli olmalı" % id)
	var own := ["native", null, true]
	var expect := {
		"mete": {"idle_3": ["native_raw", null, false], "idle_4": own, "sit": own, "walk": own, "run": own},
		"hero_f": {"idle_3": own, "idle_4": ["retarget", "mete", false], "sit": ["retarget", "mother", true], "walk": own, "run": own},
		"mother": {"idle_3": ["retarget", "hero_f", false], "idle_4": ["retarget", "mete", false], "sit": own, "walk": own, "run": own},
		"father": {"idle_3": ["retarget", "hero_f", false], "idle_4": ["retarget", "mete", false], "sit": own, "walk": own, "run": own},
		"elder": {"idle_3": ["retarget", "hero_f", false], "idle_4": ["retarget", "mete", false], "sit": own, "walk": own, "run": own},
		"child": {"idle_3": ["retarget", "hero_f", false], "idle_4": ["retarget", "mete", false], "sit": own, "walk": own, "run": own},
	}
	var carried := lib.carrier_keys(CARRIER)
	var raw_here := not lib.native_sources(CARRIER).is_empty()
	for id in expect:
		var plan := lib.resolve(id, all)
		for key in expect[id]:
			var want: Array = expect[id][key]
			assert_eq(plan[key]["source"], want[0], "%s/%s kaynağı" % [id, key])
			assert_eq(plan[key]["donor"], want[1], "%s/%s bağışçısı" % [id, key])
			assert_eq(plan[key]["game_role"], want[2], "%s/%s oyun rolü" % [id, key])
		if not raw_here:
			continue
		var wrong := Array(carried).filter(func(key: String) -> bool: return plan[key]["source"] != ClipLibrary.RETARGET or plan[key]["donor"] != CARRIER)
		assert_eq(wrong, [], "%s: E9 klipleri taşıyıcıdan aktarılmalı" % id)
	lib.release()


func test_mete_sit_is_his_own_purchase_and_hero_f_sit_comes_from_mother() -> void:
	# mete_sit.res Mete'nin kendi 363 alımıdır: prepare_character.py onu ham GLB'sinden çıkardı (meta.json extra_clips).
	# Veri de bunu söyler: dosya Mete'nin ham alımıyla birebir, Baba'dan aktarım ise yakın ama aynı değil (K92 öncesi 34°,
	# sonrası 2,3°: aktarım hareketi korur). Kadın kahramanın oturması ise gerçekten Ana'dan aktarılmıştır.
	if not _has_models():
		return
	var lib := ClipLibrary.new()
	var mete_sit: Dictionary = lib.game_clips("mete")["sit"]
	# character_fit_tool.gd DONORS'ta eski «mete: sit → father» kaydı durdukça kayıtlar çelişir; kayıt silinince çelişki
	# kalmaz, sonuç yine Mete'nin kendi klibidir.
	assert_eq(mete_sit["ambiguous"], ClipLibrary.FIT_TOOL.donors_of("mete").has("sit"), "Çelişki yalnız DONORS'ta eski kayıt varken")
	assert_eq(mete_sit["source"], ClipLibrary.NATIVE, "meta.json extra_clips: Mete'nin kendi klibi")
	var check := lib.verify_game_clip("mete", "sit")
	assert_true(check["checked"], "Mete'nin ham 363'üyle karşılaştırılmalı")
	assert_true(check["difference"] < ClipLibrary.SAME_CLIP_TOLERANCE, "mete_sit.res Mete'nin kendi alımı (fark %.4f rad)" % check["difference"])
	assert_eq(check["source"], ClipLibrary.NATIVE)
	assert_eq(lib.resolve("mete")["sit"]["source"], ClipLibrary.NATIVE)
	var mete := _instantiate("mete")
	var from_father := lib.retarget_from("sit", "father", ClipLibrary.find_skeleton(mete), "mete")
	var own := load(ClipLibrary.res_path("mete", "sit")) as Animation
	var transfer_gap := ClipLibrary.max_rotation_difference(own, from_father)
	assert_true(transfer_gap > ClipLibrary.SAME_CLIP_TOLERANCE, "Baba'dan aktarım Mete'nin kendi alımı sayılmamalı (%.4f rad)" % transfer_gap)
	assert_true(transfer_gap < 0.06, "Aynı hareketin aktarımı kişinin kendi alımını vermeli (%.4f rad)" % transfer_gap)
	var hero := _instantiate("hero_f")
	var hero_sit: Dictionary = lib.resolve("hero_f")["sit"]
	assert_eq(hero_sit["source"], ClipLibrary.RETARGET)
	assert_eq(hero_sit["donor"], "mother")
	assert_false(lib.game_clips("hero_f")["sit"]["ambiguous"])
	var fresh := lib.retarget_from("sit", "mother", ClipLibrary.find_skeleton(hero), "hero_f")
	var saved := load(ClipLibrary.res_path("hero_f", "sit")) as Animation
	assert_true(ClipLibrary.max_rotation_difference(saved, fresh) < ClipLibrary.SAME_CLIP_TOLERANCE, "hero_f_sit.res, Ana'nın oturmasının aktarımı")
	mete.free()
	hero.free()
	lib.release()


func test_real_retarget_father_sit_to_hero_f_has_every_bone() -> void:
	if not _has_models():
		return
	var lib := ClipLibrary.new()
	var hero := _instantiate("hero_f")
	var skel := ClipLibrary.find_skeleton(hero)
	var anim := lib.retarget_from("sit", "father", skel, "hero_f")
	assert_not_null(anim, "Baba'nın oturması kadın kahramana aktarılmalı")
	if anim:
		var prefix := ClipRetarget.track_prefix(anim)
		for b in skel.get_bone_count():
			# Parmak kemiği aktarılmaz: el HandGrip'ten gelir, oyunun klip kuralı dinlenme izi ekler (tools/hand_rig.py).
			if HandGrip.is_finger_bone(skel.get_bone_name(b)):
				assert_eq(anim.find_track(NodePath("%s:%s" % [prefix, skel.get_bone_name(b)]), Animation.TYPE_ROTATION_3D), -1, "Parmağa klip yazılmaz")
				continue
			assert_true(anim.find_track(NodePath("%s:%s" % [prefix, skel.get_bone_name(b)]), Animation.TYPE_ROTATION_3D) >= 0,
				"%s kemiğinin dönüş izi olmalı" % skel.get_bone_name(b))
		assert_true(anim.find_track(NodePath("%s:Hips" % prefix), Animation.TYPE_POSITION_3D) >= 0, "Kök kemiğin konum izi olmalı")
		assert_almost(anim.length, 2.533, 0.001, "Meshy 363 süresi")
		assert_eq(ClipLibrary.frame_count(anim), 77, "30 kare/sn örnek")
	# Kütüphanenin tam yolu: Baba'ya Kadın Kahraman'ın oyun dosyasından bekleme 3 (aktarım + oyunun kuralları).
	var father := _instantiate("father")
	var father_skel := ClipLibrary.find_skeleton(father)
	var idle := lib.build_clip("idle_3", "father", father_skel)
	assert_not_null(idle)
	if idle:
		assert_eq(idle.resource_name, "idle_3")
		assert_eq(idle.loop_mode, Animation.LOOP_LINEAR, "Bekleme döngülü")
		assert_almost(idle.length, 10.0, 0.01)
		assert_eq(_rotation_tracks(idle), father_skel.get_bone_count(), "Aktarılan klipte her kemiğin izi")
	var sit := lib.build_clip("sit", "hero_f", skel)
	assert_not_null(sit)
	if sit:
		assert_eq(sit.loop_mode, Animation.LOOP_LINEAR, "Oturma nefes döngüsüdür (is_cyclic)")
	hero.free()
	father.free()
	lib.release()


func test_real_carrier_clips_reach_every_body() -> void:
	# E9'un taşıyıcı iskeletinden (Mete'nin T-poz modelinin yeniden iskeletlenmişi; oyun iskeletinden farklı) erkeğe,
	# kadına ve çocuğa: bekleme döngülü ve yerinde, ayağa kalkma bir kez ve kök hareketiyle, metinden hareket oturuştur.
	if not _has_models("E9"):
		return
	var lib := ClipLibrary.new()
	var sources := lib.native_sources(CARRIER)
	if sources.is_empty():
		print("        (atlandı: E9 taşıyıcısının ham GLB'leri yok)")
		return
	assert_eq(sources.size(), 117, "E9'un, E14'ün ve zıplamanın bütün klipleri taşıyıcıda: oyun kaynağı (.res) ya da alımı başarılı ham GLB'si; 6 türetilmiş klip dahil")
	var cases := [["idle_6", "father", 7.367, Animation.LOOP_LINEAR], ["stand_up_1", "hero_f", 8.267, Animation.LOOP_NONE],
		["ground_doze", "child", 7.967, Animation.LOOP_NONE]]
	for c in cases:
		var model := _instantiate(c[1])
		var skel := ClipLibrary.find_skeleton(model)
		var anim := lib.build_clip(c[0], c[1], skel)
		assert_not_null(anim, "%s → %s kurulmalı" % [c[0], c[1]])
		if anim:
			assert_eq(anim.resource_name, c[0])
			assert_almost(anim.length, c[2], 0.002, "%s süresi" % c[0])
			assert_eq(anim.loop_mode, c[3], "%s döngüsü" % c[0])
			assert_eq(_rotation_tracks(anim), skel.get_bone_count(), "%s: her kemiğin izi" % c[0])
			var hips := anim.find_track(NodePath("%s:Hips" % ClipRetarget.track_prefix(anim)), Animation.TYPE_POSITION_3D)
			var first: Vector3 = anim.track_get_key_value(hips, 0)
			var last: Vector3 = anim.track_get_key_value(hips, anim.track_get_key_count(hips) - 1)
			if c[0] == "stand_up_1":
				assert_true(last.y - first.y > 30.0, "Ayağa kalkarken kalça yükselir (%.1f → %.1f)" % [first.y, last.y])
			elif c[0] == "idle_6":
				assert_vec_almost(Vector3(last.x, 0.0, last.z), Vector3(first.x, 0.0, first.z), 0.01, "Bekleme yerinde oynar")
		model.free()
	lib.release()


func test_core_idle_opens_no_raw_glb_for_men() -> void:
	# Mete'nin ham 243'ü 43 MB: kare içinde açılsa 0,67 sn takılırdı, dışa aktarılmış oyunda da yoktur (orada kaynak Kadın Kahraman'dı).
	if not _has_models():
		return
	var lib := ClipLibrary.new()
	var father := _instantiate("father")
	var anim := lib.clip_for("father", "idle_3", ClipLibrary.find_skeleton(father))
	assert_not_null(anim)
	for path in lib._scenes:
		assert_true(str(path).begins_with("res://"), "Ham GLB açılmamalı: %s" % path)
	father.free()
	lib.release()


func test_own_actions_need_no_tools_folder() -> void:
	# tools/ dışa aktarılmış oyunda yoktur: kişinin kendi klipleri tanımdan okunur, plan yalnız sınamada denetlenir.
	var lib := ClipLibrary.new()
	var plan: Variant = ClipLibrary.read_json(ClipLibrary.ASSET_PLAN_PATH)
	assert_true(plan is Dictionary, "asset_plan.json okunmalı")
	for row in (plan as Dictionary).get("assets", []):
		if row is Dictionary and row.get("kind") == "character":
			var want := PackedInt32Array()
			for action in row.get("animations", []):
				want.append(int(action))
			assert_eq(lib.own_actions(str(row["id"])), want, "%s: tanım plandakiyle aynı" % row["id"])
	# Plan okunamasa da aynı sonuç: Ozan kendi bağdaşını oynar (kopuz o poza ayarlı), bekleme klipleri kurulur.
	var no_plan := ClipLibrary.new()
	no_plan._plan_loaded = true
	assert_true(no_plan.plan_row("elder").is_empty(), "Sınama planı boş bırakır")
	assert_eq(no_plan.own_actions("elder"), PackedInt32Array([363]))
	assert_eq(no_plan.game_clips("elder").get("sit", {}).get("role"), "sit", "Ozanın bağdaşı kendi klibi")
	assert_eq(no_plan.resolve("elder")["idle_3"]["donor"], "hero_f", "Bağışçı bulunur")


# --- Oyunun kuralları, yardımcılar --------------------------------------------------------------------------

func _hips_clip(end: Vector3) -> Animation:
	var anim := Animation.new()
	anim.length = 1.0
	var p := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(p, ^"Armature/Skeleton3D:Hips")
	anim.position_track_insert_key(p, 0.0, Vector3(0.0, 100.0, 0.0))
	anim.position_track_insert_key(p, 0.5, Vector3(2.0, 98.0, 20.0))
	anim.position_track_insert_key(p, 1.0, end)
	return anim


func test_clip_rules_loop_and_in_place_like_character_avatar() -> void:
	for role in ["idle", "walk", "run", "talk", "work"]:
		var anim := _hips_clip(Vector3(0.0, 100.0, 40.0))
		ClipLibrary.apply_clip_rules(anim, role)
		assert_eq(anim.loop_mode, Animation.LOOP_LINEAR, "%s döngülü" % role)
		assert_vec_almost(anim.track_get_key_value(0, 2), Vector3(0.0, 100.0, 0.0), 0.0001, "%s yerinde oynar (kayma silinir)" % role)
	var breathing := _hips_clip(Vector3(0.0, 100.0, 0.0))
	ClipLibrary.apply_clip_rules(breathing, "sit")
	assert_eq(breathing.loop_mode, Animation.LOOP_LINEAR, "İlk ve son pozu aynı oturma döngülü")
	var sitting_down := _hips_clip(Vector3(0.0, 30.0, 40.0))
	ClipLibrary.apply_clip_rules(sitting_down, "sit")
	assert_eq(sitting_down.loop_mode, Animation.LOOP_NONE, "Oturmaya geçiş son karesinde durur")
	assert_vec_almost(sitting_down.track_get_key_value(0, 2), Vector3(0.0, 30.0, 40.0), 0.0001, "Oturma yerinden oynatılmaz")
	var standing_up := _hips_clip(Vector3(0.0, 160.0, 40.0))
	ClipLibrary.apply_clip_rules(standing_up, "stand_up", false)
	assert_eq(standing_up.loop_mode, Animation.LOOP_NONE, "Döngüsüz geçiş bir kez oynar")
	assert_vec_almost(standing_up.track_get_key_value(0, 2), Vector3(0.0, 160.0, 40.0), 0.0001, "Geçişin kök hareketi korunur")


func _small_skeleton(with_shoulders: bool) -> Skeleton3D:
	var skel := Skeleton3D.new()
	var names := ["Hips", "Spine", "LeftShoulder", "LeftArm", "RightShoulder", "RightArm"] if with_shoulders else ["Hips", "Spine", "Head"]
	for n in names:
		skel.add_bone(n)
	skel.set_bone_rest(0, Transform3D(Basis.IDENTITY, Vector3(0.0, 100.0, 0.0)))
	skel.set_bone_parent(1, 0)
	skel.set_bone_rest(1, Transform3D(Basis.IDENTITY, Vector3(0.0, 40.0, 0.0)))
	if with_shoulders:
		for side in [[2, 3, 1.0], [4, 5, -1.0]]:
			skel.set_bone_parent(side[0], 1)
			skel.set_bone_rest(side[0], Transform3D(Basis.IDENTITY, Vector3(side[2] * 3.0, 10.0, 0.0)))
			skel.set_bone_parent(side[1], side[0])
			skel.set_bone_rest(side[1], Transform3D(Basis.IDENTITY, Vector3(side[2] * 12.0, 4.0, 0.0)))
	else:
		skel.set_bone_parent(2, 1)
		skel.set_bone_rest(2, Transform3D(Basis.IDENTITY, Vector3(0.0, 20.0, 0.0)))
	skel.reset_bone_poses()
	return skel


func test_complete_rest_tracks_and_frame_count() -> void:
	var skel := _small_skeleton(true)
	var anim := Animation.new()
	anim.length = 1.0
	var r := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(r, ^"Armature/Skeleton3D:Spine")
	anim.rotation_track_insert_key(r, 0.0, Quaternion.IDENTITY)
	anim.rotation_track_insert_key(r, 0.5, Quaternion(Vector3.UP, 0.2))
	anim.rotation_track_insert_key(r, 1.0, Quaternion.IDENTITY)
	assert_eq(ClipLibrary.complete_rest_tracks(anim, skel), 6, "Beş kemiğe dönüş izi, köke konum izi")
	for n in ["Hips", "LeftShoulder", "RightArm"]:
		var t := anim.find_track(NodePath("Armature/Skeleton3D:%s" % n), Animation.TYPE_ROTATION_3D)
		assert_true(t >= 0, "%s izi eklenmeli" % n)
	var hips := anim.find_track(^"Armature/Skeleton3D:Hips", Animation.TYPE_POSITION_3D)
	assert_vec_almost(anim.position_track_interpolate(hips, 0.3), Vector3(0.0, 100.0, 0.0), 0.0001, "Dinlenme konumu")
	assert_eq(ClipLibrary.complete_rest_tracks(anim, skel), 0, "İkinci çağrı bir şey eklemez")
	assert_eq(ClipLibrary.frame_count(anim), 3, "Farklı anahtar zamanları: 0, 0.5, 1")
	skel.free()


func test_shift_root_moves_the_root_track_and_adds_a_missing_one() -> void:
	var skel := _small_skeleton(false)
	var anim := _hips_clip(Vector3(0.0, 100.0, 0.0))
	assert_true(ClipLibrary.shift_root(anim, skel, Vector3(0.0, -5.0, 0.0)))
	assert_vec_almost(anim.track_get_key_value(0, 0), Vector3(0.0, 95.0, 0.0), 0.0001, "Bütün anahtarlar kayar")
	assert_vec_almost(anim.track_get_key_value(0, 1), Vector3(2.0, 93.0, 20.0), 0.0001)
	assert_false(ClipLibrary.shift_root(anim, skel, Vector3.ZERO), "Pay yoksa dokunulmaz")
	var bare := Animation.new()
	bare.length = 2.0
	var r := bare.add_track(Animation.TYPE_ROTATION_3D)
	bare.track_set_path(r, ^"Armature/Skeleton3D:Spine")
	bare.rotation_track_insert_key(r, 0.0, Quaternion.IDENTITY)
	assert_true(ClipLibrary.shift_root(bare, skel, Vector3(0.0, 9.3, 0.0)))
	var hips := bare.find_track(^"Armature/Skeleton3D:Hips", Animation.TYPE_POSITION_3D)
	assert_true(hips >= 0, "Kök kemiğin konum izi dinlenme konumundan kurulur")
	assert_eq(bare.track_get_key_count(hips), 2)
	assert_vec_almost(bare.position_track_interpolate(hips, 1.0), Vector3(0.0, 109.3, 0.0), 0.0001)
	skel.free()


func test_shift_root_ramp_gives_the_two_ends_their_own_offset() -> void:
	var skel := _small_skeleton(false)
	var anim := _hips_clip(Vector3(0.0, 100.0, 0.0))
	assert_true(EXPORT.shift_root_ramp(anim, skel, Vector3(0.0, -4.0, 0.0), Vector3(0.0, 6.0, 0.0)))
	assert_vec_almost(anim.track_get_key_value(0, 0), Vector3(0.0, 96.0, 0.0), 0.0001, "İlk kare başlangıç payıyla")
	assert_vec_almost(anim.track_get_key_value(0, 1), Vector3(2.0, 99.0, 20.0), 0.0001, "Arada doğrusal")
	assert_vec_almost(anim.track_get_key_value(0, 2), Vector3(0.0, 106.0, 0.0), 0.0001, "Son kare bitiş payıyla")
	var same := _hips_clip(Vector3(0.0, 100.0, 0.0))
	assert_true(EXPORT.shift_root_ramp(same, skel, Vector3(0.0, 3.0, 0.0), Vector3(0.0, 3.0, 0.0)))
	assert_vec_almost(same.track_get_key_value(0, 1), Vector3(2.0, 101.0, 20.0), 0.0001, "İki uç aynıysa düz kaydırma")
	assert_false(EXPORT.shift_root_ramp(same, skel, Vector3.ZERO, Vector3.ZERO), "Pay yoksa dokunulmaz")
	skel.free()


func test_complete_position_tracks_gives_every_clip_the_same_tracks() -> void:
	var skel := _small_skeleton(true)
	var own := _hips_clip(Vector3(0.0, 100.0, 0.0))
	var thigh := own.add_track(Animation.TYPE_POSITION_3D)
	own.track_set_path(thigh, ^"Armature/Skeleton3D:LeftArm")
	own.position_track_insert_key(thigh, 0.0, Vector3(13.0, 4.0, 0.0))
	var other := _hips_clip(Vector3(0.0, 100.0, 0.0))
	assert_eq(EXPORT.complete_position_tracks({"own": own, "other": other}, skel), 1, "Yalnız öteki klibe, yalnız eksik kemiğe")
	var added := other.find_track(^"Armature/Skeleton3D:LeftArm", Animation.TYPE_POSITION_3D)
	assert_true(added >= 0, "Öteki klipte de kol kemiğinin konum izi olmalı")
	assert_vec_almost(other.position_track_interpolate(added, 0.5), Vector3(12.0, 4.0, 0.0), 0.0001, "Dinlenme konumunda")
	assert_eq(EXPORT.complete_position_tracks({"own": own, "other": other}, skel), 0, "İkinci çağrı bir şey eklemez")
	skel.free()


func test_transition_states_name_the_two_floors() -> void:
	var transition := {"from": "stand", "to": "sit_ground"}
	assert_eq(EXPORT.transition_states({"transition": transition, "seat": "ground"}), ["stand", "sit_ground"])
	assert_eq(EXPORT.transition_states({"transition": transition, "seat": null}), ["stand", "sit_ground"])
	assert_eq(EXPORT.transition_states({"transition": {"from": "sit_chair", "to": "lie_back"}, "seat": "chair"}), [], "Oturak isteyen klipte beden zemine inmez")
	assert_eq(EXPORT.transition_states({"seat": "ground"}), [], "Geçiş değil: tek pay")
	var lib := ClipLibrary.new()
	assert_eq(EXPORT.transition_states(lib.clip("sleep")), [], "Uyku hâli yatak ister: son pozda beden yerden 58 cm yukarıda")
	assert_eq(EXPORT.transition_states(lib.clip("rev_stand_up_1")), ["stand", "sit_ground"])


func test_bake_refuses_without_shoulders_and_leaves_clip_unchanged() -> void:
	var skel := _small_skeleton(false)
	var anim := Animation.new()
	anim.length = 1.0
	var r := anim.add_track(Animation.TYPE_ROTATION_3D)
	anim.track_set_path(r, ^"Armature/Skeleton3D:Spine")
	anim.rotation_track_insert_key(r, 0.0, Quaternion.IDENTITY)
	var result := ClipLibrary.bake_shoulder_relax(anim, skel, Vector3.UP, 15.0)
	assert_false(result["baked"])
	assert_true(str(result["reason"]).contains("LeftShoulder"), "Neden yazılmalı: %s" % result["reason"])
	assert_eq(anim.get_track_count(), 1, "Klip değişmemeli")
	assert_false(ClipLibrary.bake_shoulder_relax(anim, skel, Vector3.UP, 0.0)["baked"], "Açı yoksa pişirme yok")
	skel.free()


# --- Omuz düzeltmesi: pişmiş klip = oyunun ShoulderRelax düğümü ------------------------------------------------

func _copy_skeleton(src: Skeleton3D) -> Skeleton3D:
	var out := Skeleton3D.new()
	for b in src.get_bone_count():
		out.add_bone(src.get_bone_name(b))
	for b in src.get_bone_count():
		out.set_bone_parent(b, src.get_bone_parent(b))
		out.set_bone_rest(b, src.get_bone_rest(b))
	out.reset_bone_poses()
	return out


## İskeleti klibin t anındaki pozuna getirir (izi olmayan kemik dinlenme pozunda; oynatıcı gibi).
func _pose(skel: Skeleton3D, anim: Animation, prefix: String, t: float) -> void:
	for b in skel.get_bone_count():
		var path := NodePath("%s:%s" % [prefix, skel.get_bone_name(b)])
		var rest := skel.get_bone_rest(b)
		var p := anim.find_track(path, Animation.TYPE_POSITION_3D)
		var r := anim.find_track(path, Animation.TYPE_ROTATION_3D)
		var s := anim.find_track(path, Animation.TYPE_SCALE_3D)
		skel.set_bone_pose_position(b, anim.position_track_interpolate(p, t) if p >= 0 else rest.origin)
		skel.set_bone_pose_rotation(b, anim.rotation_track_interpolate(r, t) if r >= 0 else rest.basis.get_rotation_quaternion())
		skel.set_bone_pose_scale(b, anim.scale_track_interpolate(s, t) if s >= 0 else rest.basis.get_scale())


func test_shoulder_bake_matches_the_runtime_modifier() -> void:
	# Ham klip + oyunun ShoulderRelax düğümü ile pişmiş klip (düzeltmesiz) her anahtarda aynı kol pozunu vermeli.
	if not _has_models():
		return
	var lib := ClipLibrary.new()
	var hero := _instantiate("hero_f")
	var source := ClipLibrary.find_skeleton(hero)
	var drop := 18.0
	for key in ["sit", "walk"]:
		var anim := lib.build_clip(key, "hero_f", source)
		ClipLibrary.complete_rest_tracks(anim, source)
		var baked := anim.duplicate(true) as Animation
		var result := ClipLibrary.bake_shoulder_relax(baked, source, Vector3.UP, drop)
		assert_true(result["baked"], "%s pişirilmeli: %s" % [key, result["reason"]])
		assert_true(result["between_deg"] < 0.1, "%s: örnekler arası sapma küçük (%.4f°)" % [key, result["between_deg"]])
		# İki iskelet de ağaçta olmalı: Skeleton3D ağaç dışındayken poz değişince global pozlarını yenilemez.
		var live := _copy_skeleton(source)
		add_child(live)
		var relax := ShoulderRelax.new()
		relax.drop_deg = drop
		live.add_child(relax)
		var still := _copy_skeleton(source)
		add_child(still)
		var prefix := ClipRetarget.track_prefix(anim)
		var track := baked.find_track(NodePath("%s:LeftShoulder" % prefix), Animation.TYPE_ROTATION_3D)
		var count := baked.track_get_key_count(track)
		var moved := 0.0
		for k in [0, count / 3, count / 2, count - 1]:
			var t := baked.track_get_key_time(track, k)
			_pose(live, anim, prefix, t)
			var before := live.get_bone_global_pose(live.find_bone("LeftArm")).origin
			relax._process_modification()
			_pose(still, baked, prefix, t)
			moved = maxf(moved, before.distance_to(live.get_bone_global_pose(live.find_bone("LeftArm")).origin))
			for bone_name in ARMS:
				var b := live.find_bone(bone_name)
				var want := live.get_bone_global_pose(b)
				var got := still.get_bone_global_pose(b)
				assert_true(want.origin.distance_to(got.origin) < 0.01, "%s %.3f sn %s konumu: %s / %s" % [key, t, bone_name, want.origin, got.origin])
				var angle := want.basis.get_rotation_quaternion().normalized().angle_to(got.basis.get_rotation_quaternion().normalized())
				assert_true(angle < 0.002, "%s %.3f sn %s dönüşü %.5f rad ayrışıyor" % [key, t, bone_name, angle])
		assert_true(moved > 0.5, "Düzeltme omzu gerçekten indirmeli (kol kökü %.2f birim kaydı)" % moved)
		live.free()
		still.free()
	hero.free()
	lib.release()


# --- Dışa aktarma aracı (tools/clip_library_export.gd) ----------------------------------------------------------

func test_pending_reason_follows_meshy_tasks() -> void:
	var lib := ClipLibrary.new()
	var row := {"id": "x", "kind": "character"}
	var done := {"status": "SUCCEEDED"}
	assert_eq(EXPORT.pending_reason(lib, row, {}), "Henüz Meshy'ye gönderilmedi")
	assert_eq(EXPORT.pending_reason(lib, row, {"model": {"status": "IN_PROGRESS"}}), "Meshy kuyruğunda; gelince klipleriyle burada")
	assert_true(EXPORT.pending_reason(lib, row, {"model": {"status": "FAILED"}}).contains("tamamlanmadı (FAILED)"))
	assert_true(EXPORT.pending_reason(lib, row, {"model": done}).contains("iskelet (rig) görevi sırada"), "İskelet görevi henüz açılmadı")
	assert_true(EXPORT.pending_reason(lib, row, {"model": done, "rig": {"status": "PLANNED"}}).contains("iskelet (rig) görevi sırada"))
	assert_true(EXPORT.pending_reason(lib, row, {"model": done, "rig": {"status": "IN_PROGRESS"}}).contains("iskelet (rig) görevi sürüyor"))
	assert_true(EXPORT.pending_reason(lib, row, {"model": done, "rig": done}).contains("tools/prepare_character.py"), "İndi, oyuna hazırlanmayı bekliyor")
	assert_true(EXPORT.pending_reason(lib, {"id": "y", "variant_of": "hereka"}, {}).contains("Hereka modelinin doku çeşidi"))


func test_clip_rows_list_batch_and_motion_purchases() -> void:
	var lib := ClipLibrary.new(_fake_carrier_definition())
	var purchases := [
		{"character": "m1", "action": 900, "status": "SUCCEEDED", "credits": 3, "task": "01", "order": 0},
		{"character": "pack", "action": 901, "status": "SUCCEEDED", "credits": 3, "task": "02", "order": 4},
		{"character": "f1", "action": 363, "status": "FAILED", "credits": 0, "task": "03", "order": 0},
	]
	var motions := [{"character": "pack", "motion": "ground_a", "status": "SUCCEEDED", "credits": 13, "task": "04"}]
	var rows := EXPORT.clip_rows(lib, purchases, motions)
	assert_eq(rows.map(func(r: Dictionary) -> String: return r["key"]), ["idle_x", "sit", "wave", "ground_a"])
	for r in rows:
		assert_eq(Array(r.keys()), Array(EXPORT.CLIP_FIELDS), "%s: sözleşmenin alanları, bu sırayla" % r["key"])
	assert_eq(rows[0]["purchases"], [{"character": "m1", "credits": 3}])
	assert_eq(rows[1]["purchases"], [], "Başarısız alım listelenmez")
	assert_eq(rows[2]["purchases"], [{"character": "pack", "credits": 3}], "Toplu alımın hareketi")
	assert_eq(rows[3]["purchases"], [{"character": "pack", "credits": 13}], "Metinden hareket: üretim ve uygulama")
	assert_null(rows[3]["meshy_action"])
	assert_eq(rows[3]["kind"], "purchase")


func test_clip_rows_carry_group_seat_tags_prompt_and_derived() -> void:
	var def := _fake_carrier_definition()
	var clips: Array = def["clips"]
	clips[3]["group"] = "sit_ground"
	clips[3]["seat"] = "ground"
	clips[3]["tags"] = {"body": ["male"], "age": ["adult"], "style": ["calm"]}
	clips[3]["note_tr"] = "Yerde oturur. İstem: «A person sits.» Son."
	clips.append({"key": "rev_a", "tr": "Ters", "en": "Reverse", "role": "sit_down", "group": "sit_down", "meshy_action": null, "kind": "derived", "credits": 0,
		"derived": {"from": "wave", "op": "reverse", "trim_start": 1.5}, "loop": false, "carrier": "pack", "seat": "ground", "note_tr": "Türetilmiş"})
	clips.append({"key": "rev_b", "kind": "derived", "derived": {"from": "wave", "op": "reverse"}, "loop": false, "carrier": "pack"})
	var rows := EXPORT.clip_rows(ClipLibrary.new(def), [], [])
	for r in rows:
		assert_eq(Array(r.keys()), Array(EXPORT.CLIP_FIELDS), "%s: sözleşmenin alanları, bu sırayla" % r["key"])
	var plain: Dictionary = rows[0]
	assert_eq(plain["group"], "")
	assert_null(plain["seat"], "Oturmayan klipte oturak yok")
	assert_eq(plain["tags"], {"body": [], "age": [], "style": []}, "Yazılı değilse boş listeler")
	assert_null(plain["prompt"])
	assert_null(plain["derived"])
	var motion: Dictionary = rows[3]
	assert_eq(motion["group"], "sit_ground")
	assert_eq(motion["seat"], "ground")
	assert_eq(motion["tags"], {"body": ["male"], "age": ["adult"], "style": ["calm"]})
	assert_eq(motion["prompt"], "A person sits.", "İstem notun içinden")
	var reversed: Dictionary = rows[4]
	assert_eq(reversed["kind"], "derived")
	assert_eq(reversed["derived"], {"from": "wave", "op": "reverse", "trim_start": 1.5})
	assert_eq(reversed["purchases"], [], "Türetilmiş klip satın alınmaz")
	assert_eq(rows[5]["derived"]["trim_start"], 0.0, "Kesilmemiş türetme")
	assert_null(EXPORT.prompt_of({"motion": "x", "note_tr": "İstem yazılmamış"}))
	assert_null(EXPORT.prompt_of({"note_tr": "İstem: «metinden hareket değil»"}))


func test_group_rows_follow_the_page_and_count_the_clips() -> void:
	var lib := ClipLibrary.new()
	var rows := EXPORT.group_rows(lib)
	assert_eq(rows.map(func(r: Dictionary) -> String: return r["key"]), EXPORT.GROUP_LABELS.keys(), "Sayfanın sırası")
	assert_eq(EXPORT.group_keys(lib), EXPORT.GROUP_LABELS.keys())
	var total := 0
	for r: Dictionary in rows:
		assert_eq(Array(r.keys()), Array(EXPORT.GROUP_FIELDS))
		assert_eq(r["tr"], EXPORT.GROUP_LABELS[r["key"]])
		assert_eq(r["count"], lib.variants_in(r["key"]).size(), "%s klip sayısı" % r["key"])
		total += r["count"]
	assert_eq(total, lib.clip_keys().size(), "Her klip bir öbekte")
	assert_eq(rows.filter(func(r: Dictionary) -> bool: return r["key"] == "walk")[0]["tr"], "Yürüme")
	# Sayfada adı olmayan öbek tanımdaki adıyla sona eklenir; klibi olmayan öbek yazılmaz.
	var def := _fake_definition()
	def["groups"] = {"dance": {"tr": "Dans"}, "empty": {"tr": "Boş"}}
	def["clips"][0]["group"] = "dance"
	def["clips"][1]["group"] = "walk"
	assert_eq(EXPORT.group_rows(ClipLibrary.new(def)), [{"key": "walk", "tr": "Yürüme", "count": 1, "live": true}, {"key": "dance", "tr": "Dans", "count": 1, "live": false}])
	# Bugün sahnede rolü olan öbekler (K91): bekle, yürü, koş, otur; öteki yedisinin sahnesi henüz yok.
	assert_eq(rows.filter(func(r: Dictionary) -> bool: return r["live"]).map(func(r: Dictionary) -> String: return r["key"]), ["idle_loop", "walk", "run", "sit_ground"])


func test_seat_loop_and_travel_come_from_the_measures() -> void:
	var lib := ClipLibrary.new()
	assert_true(EXPORT.seat_loop_of(lib, "ground_side_sit"), "Metinden yer oturuşu oturma rolünde döngüye kapatılır (ClipVariety.role_clip)")
	assert_true(EXPORT.seat_loop_of(lib, "chair_sit_idle_f"), "Oturaktaki bir kez oynayan oturuş da")
	assert_false(EXPORT.seat_loop_of(lib, "sit_arms_crossed"), "Kolları kavuşan klip son pozunda durur: dikişi çok ayrışır")
	assert_null(EXPORT.seat_loop_of(lib, "sit"), "Zaten döngülü")
	assert_null(EXPORT.seat_loop_of(lib, "stand_up_1"), "Oturma öbeğinde değil")
	assert_eq(EXPORT.travel_of(lib, "walk"), 0.0, "Döngülü klip yerinde oynar")
	assert_true(EXPORT.travel_of(lib, "walk_to_sit") > 1.0, "Oturmaya yürüyen klip yerinden gider")
	assert_true(EXPORT.travel_of(lib, "ground_side_sit") < 0.1, "Oturuşun kökü yerinde durur")
	assert_eq(EXPORT.travel_of(ClipLibrary.new(_fake_definition()), "idle_x"), 0.0, "Ölçülmemiş klip")


func test_carrier_rows_give_the_carrier_a_name() -> void:
	assert_eq(EXPORT.carrier_rows(ClipLibrary.new(_fake_carrier_definition())), {"pack": {"tr": "Paket"}})
	assert_eq(EXPORT.carrier_rows(ClipLibrary.new(_fake_definition())), {})
	assert_false(str(EXPORT.carrier_rows(ClipLibrary.new())[CARRIER]["tr"]).begins_with("_"), "Sayfa ham kimliği göstermesin")


func test_credit_block_adds_motions_and_the_total() -> void:
	var purchases := [
		{"character": "a", "action": 243, "status": "SUCCEEDED", "credits": 3, "task": "01"},
		{"character": "b", "action": 243, "status": "SUCCEEDED", "credits": 3, "task": "02"},
	]
	var motions := [
		{"character": "pack", "motion": "ground_a", "status": "SUCCEEDED", "credits": 13, "task": "03"},
		{"character": "pack", "motion": "ground_b", "status": "NOT_APPLIED", "credits": 10, "task": "04"},
	]
	var block := EXPORT.credit_block(purchases, motions)
	assert_eq(Array(block.keys()), Array(EXPORT.CREDIT_FIELDS))
	assert_eq(block["spent_on_actions"], 6, "Mağaza hareketleri ayrı")
	assert_eq(block["duplicate_credits"], 3)
	assert_eq(block["motions"], {"count": 1, "credits": 23}, "Uygulanmamış hareket sayılmaz, kredisi harcanmıştır")
	assert_eq(block["total"], 29)
	assert_eq(EXPORT.credit_block([], [])["total"], 0)


func test_assigned_rows_are_clip_varietys_default_for_every_group() -> void:
	var lib := ClipLibrary.new()
	var groups := EXPORT.group_keys(lib)
	for id in ["teoman", "lan_hatun", "hereka", "child", "older_brother"]:
		var assigned := EXPORT.assigned_rows(id, groups)
		var allocator := ClipVariety.Allocator.new()
		allocator.register(id)
		for group in ["idle_loop", "walk", "run", "sit_ground"]:
			assert_eq(assigned[group], allocator.key_for(id, group), "%s/%s: boş dağıtıcıdaki atama" % [id, group])
		assert_eq(assigned[ClipVariety.FIDGET_GROUP], ClipVariety.fidget_pool(ClipVariety.profile_of(id)), "%s: ara hareketler liste" % id)
		assert_eq(assigned.keys(), groups, "%s: bütün öbekler, sayfanın sırasıyla" % id)
		for group in assigned:
			for key in (assigned[group] if assigned[group] is Array else [assigned[group]]):
				assert_eq(lib.clip(key).get("group"), group, "%s/%s: %s o öbeğin klibi" % [id, group, key])
	var teoman := EXPORT.assigned_rows("teoman", groups)
	assert_eq(teoman["walk"], "proud_strut", "Gururlu kişinin yürüyüşü")
	assert_eq(EXPORT.assigned_rows("teoman", groups), teoman, "Atama belirlenimci")
	for id in ["mete", "hero_f"]:
		assert_eq(EXPORT.assigned_rows(id, groups), {}, "%s: oyuncu karakteri çeşit almaz, kendi klipleriyle oynar (K91)" % id)


func test_scene_picks_are_what_the_scenes_play() -> void:
	assert_eq(EXPORT.camp_picks(), {"mother": "ground_kneel_heels", "child": "ground_hug_knees", "father": "ground_warm_hands", "older_brother": "ground_one_knee", "elder": "sit"},
		"Ateş başının beş oturuşu (CampNpcs.SEATS)")
	var picks := EXPORT.scene_pick_rows(self)
	assert_eq(picks["mother"], {"camp": {"sit_ground": "ground_kneel_heels"}})
	assert_eq(picks["lan_hatun"], {"birth": {"sit_ground": "sit"}}, "Kolu keregeye uzanan Lan Hatun kendi oturuşunda kalır, ayağa kalkmaz")
	assert_eq(picks["hereka_young"]["birth"]["sit_ground"], "ground_kneel_heels", "Ebe topukları üstünde diz çöker")
	assert_true(picks["hereka_young"]["birth"].has("walk"), "Ebe kapıdan çıkar")
	assert_eq(picks["teoman"]["birth"]["walk"], "proud_strut", "Gururlu yürüyüş")
	assert_false(picks["teoman"]["birth"].has("sit_ground"), "Teoman doğumda oturmaz: kullanılmayan rol yazılmaz")
	assert_eq((picks["counter"]["birth"] as Dictionary).keys(), ["idle_loop"], "Sayıcı ayakta durur")
	assert_false(picks.has("lan_woman_a"), "Başka kişinin ağını gösteren yer tutucunun sayfada satırı yok")
	assert_false(picks.has("mete"), "Oyuncu karakteri bu sahnelerde yok")
	for person: String in picks:
		for scene: String in picks[person]:
			assert_true(EXPORT.SCENES.has(scene), "%s: bilinen sahne" % person)


func _valid_manifest() -> Dictionary:
	return {
		"updated": "2026-11-05T00:00:00Z",
		"_aciklama": "sınama",
		"rule": "K90",
		"credits": {"spent_on_actions": 6, "purchases": 2, "distinct_actions": 1, "duplicate_credits": 3, "motions": {"count": 1, "credits": 13}, "total": 19},
		"groups": [{"key": "sit_ground", "tr": "Yerde oturma", "count": 1, "live": true}, {"key": "idle_fidget", "tr": "Ara hareket", "count": 1, "live": false}],
		"carriers": {"_pack": {"tr": "Paketin taşıyıcı iskeleti"}},
		"clips": [
			{"key": "sit", "tr": "Oturma", "en": "Sit", "role": "sit", "group": "sit_ground", "seat": "ground",
				"tags": {"body": ["female"], "age": ["adult"], "style": ["calm"]}, "meshy_action": 363, "kind": "purchase", "prompt": null, "derived": null,
				"purchases": [{"character": "f1", "credits": 3}], "loop": true, "seat_loop": null, "travel_m": 0.0, "note_tr": ""},
			{"key": "fidget", "tr": "Ters", "en": "Reverse", "role": "work", "group": "idle_fidget", "seat": null,
				"tags": {"body": [], "age": [], "style": []}, "meshy_action": null, "kind": "derived", "prompt": null,
				"derived": {"from": "sit", "op": "reverse", "trim_start": 0.0}, "purchases": [], "loop": false, "seat_loop": null, "travel_m": 0.5, "note_tr": ""},
		],
		"characters": [{"id": "f1", "tr": "F", "group": "named", "body": "female", "glb": "docs/assets/animations/f1.glb", "bytes": 10,
			"poster": null, "height_m": 1.6, "status": "ready", "assigned": {"sit_ground": "sit", "idle_fidget": ["fidget"]}, "scene_picks": {"camp": {"sit_ground": "sit"}},
			"clips": {"sit": {"source": "retarget", "donor": "m1", "duration": 2.5, "frames": 76, "loop": true, "game_role": false}}}],
		"pending": [{"id": "x", "tr": "X", "group": "crowd", "reason_tr": "Meshy kuyruğunda"}],
	}


## Geçerli örneği bozup sözleşmenin yakaladığını sınar: change örneği değiştirir, needle sorunların metninde aranır.
func _assert_flags(change: Callable, needle: String) -> void:
	var manifest := _valid_manifest()
	change.call(manifest)
	var problems := "; ".join(EXPORT.manifest_problems(manifest))
	assert_true(problems.contains(needle), "«%s» yakalanmalı; bulunan: «%s»" % [needle, problems])


func test_manifest_checker_flags_contract_breaks() -> void:
	assert_eq(EXPORT.manifest_problems(_valid_manifest()), PackedStringArray(), "Geçerli örnek")
	var extra := _valid_manifest()
	extra["characters"][0]["shoulder_relax_baked"] = true
	assert_true("".join(EXPORT.manifest_problems(extra)).contains("shoulder_relax_baked"), "Sözleşmede olmayan alan")
	var pending_body := _valid_manifest()
	pending_body["pending"][0]["body"] = "male"
	assert_false(EXPORT.manifest_problems(pending_body).is_empty(), "Bekleyende fazla alan")
	var missing := _valid_manifest()
	missing["pending"][0].erase("reason_tr")
	assert_false(EXPORT.manifest_problems(missing).is_empty(), "Eksik alan")
	var donor := _valid_manifest()
	donor["characters"][0]["clips"]["sit"]["donor"] = null
	assert_true("".join(EXPORT.manifest_problems(donor)).contains("donor"), "Aktarımın bağışçısı olmalı")
	var unknown := _valid_manifest()
	unknown["characters"][0]["clips"]["zzz"] = unknown["characters"][0]["clips"]["sit"]
	assert_true("".join(EXPORT.manifest_problems(unknown)).contains("zzz"), "Kütüphanede olmayan klip")
	var credits := _valid_manifest()
	credits["credits"]["purchases"] = 2.5
	assert_false(EXPORT.manifest_problems(credits).is_empty(), "Kredi alanları tam sayı")
	assert_false(EXPORT.manifest_problems([]).is_empty(), "Kök nesne olmalı")
	_assert_flags(func(m: Dictionary) -> void: m["groups"][0]["count"] = 5, "groups[sit_ground].count")
	_assert_flags(func(m: Dictionary) -> void: m["groups"].append(m["groups"][0]), "yinelenen anahtar «sit_ground»")
	_assert_flags(func(m: Dictionary) -> void: m["clips"][0]["group"] = "yok", "öbeklerde yok")
	_assert_flags(func(m: Dictionary) -> void: m["clips"][0]["seat"] = "sandalye", "clips[sit].seat")
	_assert_flags(func(m: Dictionary) -> void: m["clips"][0]["tags"].erase("style"), "clips[sit].tags")
	_assert_flags(func(m: Dictionary) -> void: m["clips"][0].erase("tags"), "clips[sit].tags nesne değil")
	_assert_flags(func(m: Dictionary) -> void: m["clips"][0]["prompt"] = "", "clips[sit].prompt")
	_assert_flags(func(m: Dictionary) -> void: m["clips"][0]["derived"] = {"from": "sit"}, "türetilmiş olmayan klipte")
	_assert_flags(func(m: Dictionary) -> void: m["clips"][1]["derived"] = null, "clips[fidget].derived nesne değil")
	_assert_flags(func(m: Dictionary) -> void: m["clips"][1]["derived"]["from"] = "yok", "kütüphanede yok")
	_assert_flags(func(m: Dictionary) -> void: m["clips"][1]["kind"] = "bedava", "clips[fidget].kind")
	_assert_flags(func(m: Dictionary) -> void: m["carriers"]["_pack"]["tr"] = "", "carriers[_pack].tr boş")
	_assert_flags(func(m: Dictionary) -> void: m["carriers"] = [], "carriers nesne değil")
	_assert_flags(func(m: Dictionary) -> void: m["characters"][0]["clips"]["sit"]["donor"] = "_yok", "carriers'ta yok")
	_assert_flags(func(m: Dictionary) -> void: m["clips"][0]["purchases"][0]["character"] = "_yok", "carriers'ta yok")
	_assert_flags(func(m: Dictionary) -> void: m["characters"][0]["assigned"]["sit_ground"] = "fidget", "o öbeğin klibi değil")
	_assert_flags(func(m: Dictionary) -> void: m["characters"][0]["assigned"]["yok"] = "sit", "öbeklerde olmayan yok")
	_assert_flags(func(m: Dictionary) -> void: m["characters"][0]["assigned"]["sit_ground"] = ["sit"], "tek anahtar olmalı")
	_assert_flags(func(m: Dictionary) -> void: m["characters"][0]["assigned"]["idle_fidget"] = "fidget", "liste olmalı")
	_assert_flags(func(m: Dictionary) -> void: m["characters"][0]["assigned"] = null, "assigned nesne değil")
	_assert_flags(func(m: Dictionary) -> void: m["characters"][0]["group"] = "player", "oyuncu karakteri çeşit almaz")
	_assert_flags(func(m: Dictionary) -> void: m["characters"][0]["scene_picks"] = null, "scene_picks nesne değil")
	_assert_flags(func(m: Dictionary) -> void: m["characters"][0]["scene_picks"]["sahne"] = {}, "bilinmeyen sahne")
	_assert_flags(func(m: Dictionary) -> void: m["characters"][0]["scene_picks"]["camp"]["sit_ground"] = "fidget", "o öbeğin klibi değil")
	_assert_flags(func(m: Dictionary) -> void: m["groups"][0]["live"] = "evet", "groups[sit_ground].live")
	_assert_flags(func(m: Dictionary) -> void: m["clips"][0]["seat_loop"] = true, "clips[sit].seat_loop")
	_assert_flags(func(m: Dictionary) -> void: m["clips"][1]["seat_loop"] = "evet", "clips[fidget].seat_loop")
	_assert_flags(func(m: Dictionary) -> void: m["clips"][1]["travel_m"] = -1.0, "clips[fidget].travel_m")
	_assert_flags(func(m: Dictionary) -> void: m["clips"][1]["travel_m"] = null, "clips[fidget].travel_m")
	_assert_flags(func(m: Dictionary) -> void: m["credits"]["total"] = 7, "credits.total 7")
	_assert_flags(func(m: Dictionary) -> void: m["credits"]["motions"]["count"] = 1.5, "credits.motions.count")
	_assert_flags(func(m: Dictionary) -> void: m["credits"].erase("motions"), "credits.motions nesne değil")


## Yazılmış manifest.json (yoksa boş; atlandığı konsola yazılır).
func _written_manifest() -> Dictionary:
	var path := EXPORT.repo_root().path_join(EXPORT.OUT_DIR).path_join("manifest.json")
	var data: Variant = ClipLibrary.read_json(path)
	if not data is Dictionary:
		print("        (atlandı: %s yok; clip_library_export.gd koşmadı)" % path)
		return {}
	return data


func test_written_manifest_matches_contract_library_and_glbs() -> void:
	var manifest := _written_manifest()
	if manifest.is_empty():
		return
	assert_eq(EXPORT.manifest_problems(manifest), PackedStringArray(), "manifest.json sözleşmeye uymalı")
	var lib := ClipLibrary.new()
	var keys := Array(lib.clip_keys())
	assert_eq((manifest["clips"] as Array).map(func(c: Dictionary) -> String: return c["key"]), keys,
		"Manifest kütüphanenin bütün kliplerini taşımalı (kütüphane değişince araç yeniden koşar)")
	var summary := EXPORT.credit_block(lib.all_purchases(), lib.all_motion_purchases())
	for field in summary:
		if field != "motions":
			assert_eq(int(manifest["credits"][field]), summary[field], "credits.%s bugünkü alımlarla aynı (yeni alımdan sonra araç yeniden koşar)" % field)
	for field in summary["motions"]:
		assert_eq(int(manifest["credits"]["motions"][field]), summary["motions"][field], "credits.motions.%s" % field)
	var groups := EXPORT.group_rows(lib)
	assert_eq((manifest["groups"] as Array).map(func(g: Dictionary) -> String: return g["key"]), groups.map(func(g: Dictionary) -> String: return g["key"]))
	for i in groups.size():
		assert_eq(manifest["groups"][i]["tr"], groups[i]["tr"])
		assert_eq(int(manifest["groups"][i]["count"]), groups[i]["count"], "%s klip sayısı" % groups[i]["key"])
	assert_eq(manifest["carriers"], EXPORT.carrier_rows(lib))
	var group_keys := EXPORT.group_keys(lib)
	var picks := EXPORT.scene_pick_rows(self)
	var listed := []
	for ch: Dictionary in manifest["characters"]:
		var id := str(ch["id"])
		listed.append(id)
		assert_true(StandIn.has_model(id), "%s: manifest'te var, modeli yok" % id)
		assert_eq(Array((ch["clips"] as Dictionary).keys()), keys, "%s: bütün klipler, kütüphane sırasıyla" % id)
		var glb := EXPORT.repo_root().path_join(str(ch["glb"]))
		assert_eq(FileAccess.get_file_as_bytes(glb).size(), int(ch["bytes"]), "%s: bytes dosyanın boyu" % id)
		var parts := EXPORT.glb_parts(glb)
		assert_true(parts["model"] > 0 and parts["animation"] > 0 and parts["model"] + parts["animation"] < int(ch["bytes"]),
			"%s: GLB'nin ağ ve doku kısmıyla klip verisi ayrılabilmeli (%s)" % [id, parts])
		assert_eq(ch["assigned"], EXPORT.assigned_rows(id, group_keys), "%s: atama ClipVariety'nin bugünkü ataması (kural ya da kişi değişince araç yeniden koşar)" % id)
		assert_eq(ch["scene_picks"], picks.get(id, {}), "%s: sahnelerin bugünkü seçimi (sahne değişince araç yeniden koşar: --manifest-only yeter)" % id)
		# Araç yazarken dosyayı geri okuyup sahne de kurar (_verify_glb); burada 15 dosyanın JSON parçası yeter.
		var names := EXPORT.glb_animation_names(glb)
		names.sort()
		var want := keys.duplicate()
		want.sort()
		assert_eq(names, want, "%s.glb'deki animasyonların adları klip anahtarları" % id)
	for id in ["teoman", "lan_hatun", "older_brother", "hereka", "hereka_young", "counter", "crowd_hun_man", "crowd_hun_woman", "crowd_hun_rider"]:
		if StandIn.has_model(id):
			assert_true(listed.has(id), "%s sayfada olmalı" % id)
	var stale := lib.characters_with_models().filter(func(id: String) -> bool: return not listed.has(id))
	if not stale.is_empty():
		print("        (not: %s modeli var ama sayfada yok; tools/clip_library_export.gd yeniden koşmalı)" % [stale])
	lib.release()


func test_exported_clips_stand_on_the_floor() -> void:
	# Web oynatıcısı zemini ve gölgeyi dinlenme pozunun en altına (y = 0) koyar. Her klipte temas kemiklerinin (tanımın contact'ı;
	# oyunun ölçümü) en altı da y = 0'da olmalı; geçişte ilk kare başlangıç, son kare bitiş duruşunun temas kemikleriyle.
	var manifest := _written_manifest()
	if manifest.is_empty():
		return
	var lib := ClipLibrary.new()
	for id in ["mother", "father", "hereka_young"]:
		var glb := EXPORT.repo_root().path_join(EXPORT.OUT_DIR).path_join(id + ".glb")
		if not FileAccess.file_exists(glb):
			print("        (atlandı: %s yok)" % glb)
			continue
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		state.handle_binary_image_mode = GLTFState.HANDLE_BINARY_IMAGE_MODE_DISCARD_TEXTURES
		assert_eq(doc.append_from_file(glb, state), OK)
		var root := doc.generate_scene(state) as Node3D
		add_child(root)
		var player := root.find_children("*", "AnimationPlayer", true, false)[0] as AnimationPlayer
		var skel := ClipLibrary.find_skeleton(root)
		# GLTFDocument kemiklerin o anki pozunu yazar: GLB'nin dinlenme pozu oyun modelininki olmalı (ölçümden kalan poz değil).
		if StandIn.has_model(id):
			var game := _instantiate(id)
			assert_eq(EXPORT._rest_difference(skel, ClipLibrary.find_skeleton(game)), "", "%s.glb'nin dinlenme pozu oyun modelininki" % id)
			game.free()
		skel.reset_bone_poses()
		assert_almost(PoseFit.skinned_min_y(root), 0.0, 0.005, "%s dinlenme pozu zeminde" % id)
		# Ayakta, yürürken ve oturakta ayak; yerde oturuşta kalça ve bacak, eli yere dayanan klipte el de; yatarken gövde ve baş.
		# Her klipten önce poz sıfırlanır: Godot GLB'yi okurken dinlenme pozunda duran izi atar, klipsiz kemik önceki klibin pozunda
		# kalırdı (GLB'de iz vardır, web oynatıcısında bu olmaz).
		for key in ["sit", "idle_3", "idle_4", "ground_doze", "ground_side_sit", "chair_sit_idle_m", "sleep_normally"]:
			var anim := player.get_animation(key)
			var contact := lib.contact_for(key)
			skel.reset_bone_poses()
			player.play(key)
			var lowest := INF
			for time in PoseFit.floor_times(anim.length, lib.clip(key)):
				player.seek(time, true)
				lowest = minf(lowest, PoseFit.skinned_min_y(root, contact))
			assert_almost(lowest, 0.0, 0.004, "%s/%s zemine oturmalı (en alt %+.4f m)" % [id, key, lowest])
		# Yürüme oyunun kuralıyla: 60 örnek, sonuncusu süreden bir adım önce; kare başına en alt noktaların alttan dörtte biri y = 0'da
		# (PoseFit.floor_offset). En alçak an y = 0 olsaydı kişi çoğu karede havada kalırdı. Pay oyunun ölçüsüyle aynı olmalı.
		var walk_anim := player.get_animation("walk")
		skel.reset_bone_poses()
		player.play("walk")
		var walk_lows := PackedFloat32Array()
		for time in PoseFit.floor_times(walk_anim.length, lib.clip("walk")):
			player.seek(time, true)
			walk_lows.append(PoseFit.skinned_min_y(root, lib.contact_for("walk")))
		assert_eq(walk_lows.size(), PoseFit.STRIDE_FLOOR_SAMPLES, "%s/walk: yürüme örnekleri" % id)
		assert_almost(PoseFit.floor_offset(walk_lows, lib.clip("walk")), 0.0, 0.004, "%s/walk: alttan dilim zeminde" % id)
		var sorted_lows := walk_lows.duplicate()
		sorted_lows.sort()
		assert_true(sorted_lows[0] <= 0.0, "%s/walk: dilimin altında kalan kareler zemine değer ya da biraz gömülür (%+.4f m)" % [id, sorted_lows[0]])
		for key in ["stand_up_1", "rev_stand_up_1", "rev_stand_up_3", "rev_kneel_and_stand", "stand_to_side_lying"]:
			var anim := player.get_animation(key)
			var states := EXPORT.transition_states(lib.clip(key))
			assert_eq(states.size(), 2, "%s geçiş" % key)
			skel.reset_bone_poses()
			player.play(key)
			player.seek(0.0, true)
			assert_almost(PoseFit.skinned_min_y(root, lib.contact_for_state(states[0])), 0.0, 0.004, "%s/%s ilk karede %s zeminde" % [id, key, states[0]])
			player.seek(anim.length, true)
			assert_almost(PoseFit.skinned_min_y(root, lib.contact_for_state(states[1])), 0.0, 0.004, "%s/%s son karede %s zeminde" % [id, key, states[1]])
		player.stop()
		root.free()
	lib.release()
