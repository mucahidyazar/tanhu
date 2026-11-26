extends TestCase
## Yer tutucu kişi modelleri (StandIn, scripts/character/stand_in.gd; K89, Yol Haritası camp-cast):
##   - glb yokken meta.json'un stand_in kaydı (iki Lan kadını: Hun kadınının ağı, renk çarpanı, kendi ölçeği),
##   - glb varken kişinin kendi kimliği (sahte glb ve gerçek kadro: Meshy modeli gelince yer tutucu kendiliğinden kalkar),
##   - kendi modeli gelen dokuz kişi oynamaya hazır: dört rolün klibi, ölçüm dosyası, boy, oyun boyunda doku,
##   - renk çarpanı yalnız o avatarın kendi malzemelerine gider: aynı modeli kullanan Baba'nınki değişmez,
##   - ölçek uygulanır; tekrar uygulamak çarpanı biriktirmez; chibi yedeğinde paylaşılan malzemelere dokunulmaz.

const TempDir := preload("res://tests/support/temp_dir.gd")
## Kendi Meshy modeli gelen kişiler (E7.6, E7.9) ve boyları (metre; tools/asset_plan.json).
const CAST := {"teoman": 1.84, "lan_hatun": 1.58, "older_brother": 1.75, "hereka": 1.6, "hereka_young": 1.62, "counter": 1.65,
	"crowd_hun_man": 1.72, "crowd_hun_woman": 1.62, "crowd_hun_rider": 1.74}
## Kişilerin doku sınıfı (named): en büyük kenar ve masaüstü VRAM biçimi (BC7). Lan Hatun ve Ağabey'in dokusu hero sınıfındadır: doğum
## sahnesinin ve ansiklopedinin yakın 3B'sinde yüz okunmalı (tools/asset_plan.json).
const NAMED_TEXTURE_SIZE := 1024
const TEXTURE_SIZE_OVERRIDES := {"lan_hatun": 2048, "older_brother": 2048}
const NAMED_TEXTURE_FORMAT := Image.FORMAT_BPTC_RGBA

var _trash: Array[Node] = []
var _dirs: PackedStringArray = []


func after_each() -> void:
	for node in _trash:
		if is_instance_valid(node):
			node.queue_free()
	_trash.clear()
	for dir in _dirs:
		_wipe_tree(dir)
	_dirs.clear()


func test_lan_women_resolve_to_the_crowd_woman_stand_in() -> void:
	# Lan soyundan iki kadının kendi modeli planlı değildir: Hun kadınının ağını kendi çarpanı, ölçeği ve başlığıyla gösterir.
	assert_true(StandIn.has_model("crowd_hun_woman"), "Yer tutucunun modeli")
	var tints := []
	for id in ["lan_woman_a", "lan_woman_b"]:
		assert_false(StandIn.has_model(id), "%s: kendi modeli yok" % id)
		var r := StandIn.resolve(id)
		assert_eq(r["id"], id)
		assert_eq(r["model"], "crowd_hun_woman", "%s: Hun kadınının ağı" % id)
		assert_true(r["stand_in"])
		var meta := StandIn.meta(id)
		assert_almost(float(r["scale"]) * 1.62, float(meta["height_m"]), 0.005, "%s: ölçek kendi boyunu verir" % id)
		var tint: Color = r["tint"]
		assert_ne(tint, Color.WHITE, "%s: kendi renk çarpanı" % id)
		tints.append(tint)
		assert_false((meta["stand_in"] as Dictionary).has("headwear"), "%s: Hun kadınının keçe başlığı kalır, kodla baş örtüsü yok" % id)
	assert_ne(tints[0], tints[1], "İki kadın aynı ağda birbirinden ayrılır")


func test_cast_with_own_models_resolves_to_the_own_identity() -> void:
	for id: String in CAST:
		var r := StandIn.resolve(id)
		assert_eq(r["id"], id)
		assert_eq(r["model"], id, "%s: kendi modeli" % id)
		assert_false(r["stand_in"], "%s: yer tutucu kalktı" % id)
		assert_almost(r["scale"], 1.0, 0.0001, "%s: kendi boyunda" % id)
		assert_eq(r["tint"], Color.WHITE, "%s: renk çarpanı yok" % id)
		assert_eq(str(StandIn.meta(id).get("status", "")), "meshy", "%s: meta.json durumu" % id)


func test_cast_with_own_models_is_ready_to_play() -> void:
	# Dört rolün klibi (yürüme ve koşma kendi iskelet görevinden, bekleme ve oturma bağışçıdan), ölçüm dosyası, Mete'nin
	# ölçeğinde gerçek boy (metre) ve oyun boyunda doku (named: 1024, Lan Hatun ve Ağabey hero: 2048; BC7).
	for id: String in CAST:
		var fit := CharacterAvatar._load_fit(id)
		assert_false(fit.is_empty(), "%s_fit.json eksik" % id)
		for role in CharacterAvatar.ROLES:
			assert_false(is_nan(CharacterAvatar.fit_value(fit, "ground_offset", role, NAN)), "%s: %s zemin payı" % [id, role])
		for role in [&"walk", &"run"]:
			assert_true(CharacterAvatar.fit_value(fit, "clip_speed", role, 0.0) > 0.5, "%s: %s klip hızı" % [id, role])
		var height: float = CAST[id]
		assert_almost(float(StandIn.meta(id).get("height_m", 0.0)), height, 0.001, "%s: meta.json boyu" % id)
		assert_almost(float(fit.get("height", 0.0)), height, 0.01, "%s: ölçülen boy" % id)
		var avatar := _avatar(id, true)
		await wait_frames(1)
		assert_true(avatar.has_meshy_model(), "%s: Meshy modeli yüklenmeli" % id)
		for role in CharacterAvatar.ROLES:
			assert_true(avatar.available_roles().has(role), "%s: %s klibi" % [id, role])
		assert_almost(avatar.get_model_height(), height, 0.01, "%s: modelin boyu" % id)
		var materials := StandIn.own_materials(avatar)
		assert_false(materials.is_empty(), "%s: kişiye özel malzemeler" % id)
		for mat in materials:
			var texture := mat.get_shader_parameter("albedo_texture") as Texture2D
			assert_not_null(texture, "%s: dokusu" % id)
			if texture:
				assert_eq(maxi(texture.get_width(), texture.get_height()), TEXTURE_SIZE_OVERRIDES.get(id, NAMED_TEXTURE_SIZE), "%s: doku oyun boyunda" % id)
				assert_eq(texture.get_image().get_format(), NAMED_TEXTURE_FORMAT, "%s: doku BC7" % id)
		avatar.queue_free()
		_trash.erase(avatar)
		await wait_frames(1)


func test_fake_glb_resolves_to_the_own_identity() -> void:
	var root := _fresh_root("stand_in_glb")
	_write(root.path_join("older_brother/meta.json"), JSON.stringify({"stand_in": {"model": "father", "tint": "#808080", "scale": 0.9}}))
	var before := StandIn.resolve("older_brother", root)
	assert_eq(before["model"], "father", "glb yokken yer tutucu")
	_write(root.path_join("older_brother/older_brother.glb"), "glTF")
	var after := StandIn.resolve("older_brother", root)
	assert_eq(after["model"], "older_brother", "glb gelince kişinin kendi modeli")
	assert_false(after["stand_in"])
	assert_almost(after["scale"], 1.0, 0.0001)
	assert_eq(after["tint"], Color.WHITE)


func test_missing_meta_and_bad_records_fall_back_to_the_identity() -> void:
	var root := _fresh_root("stand_in_meta")
	assert_eq(StandIn.resolve("nobody", root)["model"], "nobody", "meta.json yoksa kimliğin kendisi (chibi yedeği)")
	_write(root.path_join("broken/meta.json"), "{bozuk")
	assert_eq(StandIn.resolve("broken", root)["model"], "broken", "Bozuk meta.json")
	_write(root.path_join("self/meta.json"), JSON.stringify({"stand_in": {"model": "self"}}))
	assert_false(StandIn.resolve("self", root)["stand_in"], "Kendini gösteren kayıt yer tutucu değildir")
	_write(root.path_join("array_tint/meta.json"), JSON.stringify({"stand_in": {"model": "mother", "tint": [0.5, 0.25, 1.0], "scale": 1.1}}))
	var r := StandIn.resolve("array_tint", root)
	assert_eq(r["model"], "mother")
	assert_eq(r["tint"], Color(0.5, 0.25, 1.0))
	assert_almost(r["scale"], 1.1, 0.0001)


func test_parse_tint() -> void:
	assert_eq(StandIn.parse_tint("#ff8000"), Color(1.0, 128.0 / 255.0, 0.0))
	assert_eq(StandIn.parse_tint([0.1, 0.2, 0.3]), Color(0.1, 0.2, 0.3))
	assert_eq(StandIn.parse_tint("renk değil"), Color.WHITE)
	assert_eq(StandIn.parse_tint(null), Color.WHITE)


func test_tint_reaches_only_that_avatar_and_scale_applies() -> void:
	# İki avatar aynı Meshy modelini (Baba) gösterir: biri yer tutucu olur, öbürü değişmez.
	var brother := _avatar("father", true)
	var father := _avatar("father", true)
	await wait_frames(1)
	assert_true(brother.has_meshy_model() and father.has_meshy_model(), "Baba'nın Meshy modeli yüklenmeli")
	var father_before := _tints(father)
	assert_false(father_before.is_empty(), "Baba'nın kişiye özel malzemeleri olmalı")
	var tint := Color(0.7, 0.75, 0.85)
	var count := StandIn.apply(brother, tint, 0.95)
	assert_true(count > 0, "Çarpan yer tutucunun malzemelerine gitmeli")
	for value in _tints(brother):
		assert_true(value.is_equal_approx(tint), "Yer tutucunun malzemesi çarpanı almalı (%s)" % value)
	assert_eq(_tints(father), father_before, "Aynı modeli kullanan Baba'nın malzemeleri değişmemeli")
	for mat in StandIn.own_materials(brother):
		assert_false(StandIn.own_materials(father).has(mat), "Malzemeler paylaşılmamalı")
	assert_almost(brother.model_scale, 0.95, 0.0001)
	assert_vec_almost(brother.get_model_node().scale, Vector3.ONE * 0.95, 0.0001, "Ölçek modele uygulanmalı")
	assert_almost(father.model_scale, 1.0, 0.0001)
	assert_vec_almost(father.get_model_node().scale, Vector3.ONE, 0.0001)
	assert_almost(brother.get_model_height(), father.get_model_height() * 0.95, 0.01, "Yer tutucu Baba'dan %5 kısa")
	# Tekrar uygulamak çarpanı biriktirmez.
	StandIn.apply(brother, tint, 0.95)
	for value in _tints(brother):
		assert_true(value.is_equal_approx(tint), "Çarpan birikmemeli (%s)" % value)
	StandIn.apply(brother, Color.WHITE, 1.0)
	for value in _tints(brother):
		assert_true(value.is_equal_approx(Color.WHITE), "Beyaz çarpan ilk rengi geri getirmeli")


func test_chibi_fallback_gets_scale_but_shared_materials_stay() -> void:
	var avatar := _avatar("older_brother", false)
	var other := _avatar("older_brother", false)
	await wait_frames(1)
	assert_false(avatar.has_meshy_model())
	var shared := _override_materials(other)
	var count := StandIn.apply(avatar, Color(0.5, 0.5, 0.5), 0.9)
	assert_eq(count, 0, "Chibi yedeğinin malzemeleri paylaşılır: çarpan uygulanmaz")
	assert_almost(avatar.model_scale, 0.9, 0.0001)
	assert_eq(_override_materials(other), shared, "Öteki avatarın malzemeleri değişmemeli")


# --- Yardımcılar ---------------------------------------------------------------------------------

func _avatar(model: String, meshy: bool) -> CharacterAvatar:
	var avatar := CharacterAvatar.new()
	avatar.use_meshy_models = meshy
	avatar.model_override = model
	avatar.start_pose = &"sit"
	add_child(avatar)
	_trash.append(avatar)
	return avatar


func _tints(avatar: CharacterAvatar) -> Array[Color]:
	var out: Array[Color] = []
	for mat in StandIn.own_materials(avatar):
		out.append(mat.get_shader_parameter("albedo_tint"))
	return out


func _override_materials(avatar: CharacterAvatar) -> Array:
	var out := []
	for node in avatar.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		out.append(mi.material_override)
		if mi.material_override is ShaderMaterial:
			out.append((mi.material_override as ShaderMaterial).get_shader_parameter("albedo"))
	return out


func _fresh_root(name: String) -> String:
	var dir := TempDir.fresh(name)
	_dirs.append(dir)
	return dir


func _write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


## Geçici kök ve alt klasörleri silinir (TempDir.wipe alt klasöre inmez).
static func _wipe_tree(dir: String) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	for sub in d.get_directories():
		_wipe_tree(dir.path_join(sub))
	TempDir.wipe(dir)
