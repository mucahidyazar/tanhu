extends TestCase
## Kodla kişi üretici (Folk; scripts/character/folk.gd, data/character/folk.json; Yol Haritası folk-generator):
##   - tohumdan aynı kişi: aynı tohum her çağrıda (ve önbellek boşaltılınca) aynı görünüşü verir, başka tohum başka kişiyi;
##   - halklar ayrıdır: Yüeçi, Hun ve Çiang kişileri kendi ten, saç ve giysi listelerinden; rolün giysisi halkınkinin yerine geçer
##     (nöbetçinin kızıl ve kahve giysisi, pullu yeleğin modeli); esirin giysisi solgundur;
##   - verilen alan tohumun yerine geçer (act1.md §3'ün adlı kişileri: Uldın, Berik…); kendi modeli olan adlı kişi kendi modelindedir;
##   - tam kişi: kalabalık modellerinin bölge maskesi ve giysi ölçüsü vardır; prepare modeli, ölçeği ve boyaları verir, boyalar
##     malzemeye yazılır ve model yeniden kurulunca da kalır; maskesiz modelde StandIn'in renk çarpanı ılımlıdır;
##   - kukla ve kart: palet altı yuvalıdır, başlık biçimi üç kuklanın birine iner; çocuk ve yaşlı tam kişi olmaz;
##   - adlı erin portresi görünüşün anahtarıyla önbelleğe girer (başsızda çizilmez, sessizce null).

var _trash: Array[Node] = []


func after_each() -> void:
	for node in _trash:
		if is_instance_valid(node):
			node.queue_free()
	_trash.clear()


func test_same_seed_gives_the_same_person() -> void:
	var a := Folk.make("kislak:market:3", {"role": "townsfolk"})
	Folk.reset()
	var b := Folk.make("kislak:market:3", {"role": "townsfolk"})
	assert_eq(JSON.stringify(_plain(a)), JSON.stringify(_plain(b)), "Aynı tohum aynı kişi")
	var differs := 0
	for i in 12:
		var other := Folk.make("kislak:market:%d" % (100 + i), {"role": "townsfolk"})
		if JSON.stringify(_plain(other)) != JSON.stringify(_plain(a)):
			differs += 1
	assert_eq(differs, 12, "Başka tohum başka kişi")


func test_peoples_use_their_own_palettes() -> void:
	var d := Folk.data()
	for people in ["yuezhi", "hun", "qiang"]:
		var folk: Dictionary = d["peoples"][people]
		var skins := _colors(folk["skin"])
		var hairs := _colors(folk["hair"]) + _colors(folk["elder_hair"])
		for i in 20:
			var look := Folk.make("t:%s:%d" % [people, i], {"people": people, "role": "townsfolk"})
			assert_eq(look["people"], people)
			assert_true(skins.has((look["skin"] as Color).to_html(false)), "%s: ten halkın listesinden" % people)
			assert_true(hairs.has((look["hair"] as Color).to_html(false)), "%s: saç halkın listesinden" % people)
	# Yüeçi'nin ateş kızılı ve sarısı Hun'un kahvesinden ayrılır: ortalama giysi tonu farklıdır.
	var yz := _mean_coat("yuezhi")
	var hn := _mean_coat("hun")
	assert_true(yz.r - yz.g > hn.r - hn.g, "Yüeçi giysisi Hun'unkinden kızıl (%s, %s)" % [yz.to_html(false), hn.to_html(false)])


func test_roles_override_the_people() -> void:
	for i in 10:
		var guard := Folk.make("kislak:guard:%d" % i, {"role": "guard"})
		assert_eq(guard["people"], "yuezhi")
		assert_eq(guard["body"], "male")
		assert_eq(guard["model"], "crowd_hun_rider", "Nöbetçi pullu yelekli modelde")
		assert_true(["saka", "fur"].has(str(guard["hat"])), "Nöbetçinin başlığı: %s" % guard["hat"])
		assert_true((guard["style"] as Array).has("warrior"))
		var captive := Folk.make("kislak:hollow:%d" % i, {"role": "captive"})
		assert_true(["hun", "qiang"].has(str(captive["people"])), "Esir Hun ya da Çiang")
		assert_between(float(captive["shade"]), 0.72, 0.9, "Esirin giysisi solgun")


func test_named_people_follow_their_act1_definition() -> void:
	var uldin := Folk.person("uldin")
	assert_false(bool(uldin["own"]), "Uldın'ın Meshy modeli yok: Folk'tan")
	assert_eq(uldin["people"], "hun")
	assert_eq((uldin["coat"] as Color).to_html(false), "6a4a34", "act1.md §3: coat #6a4a34")
	assert_eq((uldin["trim"] as Color).to_html(false), "8a3f2a")
	assert_almost(float(uldin["build"]), 1.12, 0.001)
	assert_eq(uldin["model"], "crowd_hun_man")
	assert_almost(float(uldin["scale"]) * 1.72, 1.78, 0.002, "Boy 1,78 m")
	var berik := Folk.person("berik")
	assert_eq(berik["hat"], "band")
	assert_eq((berik["hat_color"] as Color).to_html(false), "b8862d")
	var opia := Folk.person("opia")
	assert_eq(opia["body"], "female")
	assert_eq(opia["model"], "crowd_hun_woman")
	for id in ["amaga", "farnak", "palak", "kujul", "hereka"]:
		var own := Folk.person(id)
		assert_true(bool(own["own"]), "%s kendi modelinde" % id)
		assert_eq(own["model"], id)


func test_children_and_elders_stay_puppets() -> void:
	var kids := 0
	var elders := 0
	for i in 80:
		var look := Folk.make("t:body:%d" % i, {"role": "townsfolk"})
		if look["body"] == "child":
			kids += 1
			assert_false(Folk.has_full(look), "Çocuk tam kişi olmaz")
			assert_between(float(look["height_m"]), 1.0, 1.4)
		if bool(look["elder"]) and look["body"] != "child":
			elders += 1
		assert_between(float(look["height_m"]), 1.0, 1.85)
	assert_true(kids > 0, "Kasabalıların arasında çocuk var")
	assert_true(elders > 0, "Kasabalıların arasında yaşlı var")


func test_crowd_garments_stay_out_of_the_cold_band() -> void:
	# K58: soğuk bant (OKLCH ton 190–300°, doygunluk ≥0,05) kalabalık giysisinde yasaktır, Mete pelerininden seçilir.
	var d := Folk.data()
	for people: String in d["peoples"]:
		var folk: Dictionary = d["peoples"][people]
		for key in ["coat", "trim", "hat_color", "boots"]:
			for c: Variant in folk.get(key, []):
				assert_false(CharacterOptions.in_cold_band(Color.html(str(c))), "%s %s %s soğuk bantta" % [people, key, c])
	for role: String in ["townsfolk", "guard", "captive", "builder"]:
		for i in 60:
			var look := Folk.make("t:cold:%s:%d" % [role, i], {"role": role})
			for key in ["coat", "trim", "hat_color"]:
				assert_false(CharacterOptions.in_cold_band(look[key]), "%s %d %s soğuk bantta" % [role, i, key])
	for id: String in d["named"]:
		if id == "doc":
			continue
		var look := Folk.person(id)
		assert_false(CharacterOptions.in_cold_band(look["coat"]), "%s giysisi soğuk bantta" % id)


func test_palette_and_puppet_variant() -> void:
	var look := Folk.make("t:palette", {"people": "yuezhi", "body": "male", "hat": {"kind": "saka", "color": "#b8862d"}, "coat": "#6b2130"})
	var pal := Folk.palette(look)
	assert_eq(pal.size(), Folk.SLOTS)
	assert_eq(pal[Folk.SLOT_COAT].to_html(false), "6b2130", "Verilen giysi kaymaz")
	assert_eq(pal[Folk.SLOT_HAT].to_html(false), "b8862d")
	assert_eq(Folk.puppet_variant(look), Folk.PUPPET_HATS.find("cap"), "Saka başlığı sivri kukla")
	assert_eq(Folk.puppet_variant(Folk.make("t:fur", {"hat": {"kind": "fur"}})), Folk.PUPPET_HATS.find("fur"))
	assert_eq(Folk.puppet_variant(Folk.make("t:veil", {"body": "female", "hat": {"kind": "veil", "color": "#8a3a3a"}})), Folk.PUPPET_HATS.find("bare"))
	var veil := Folk.palette(Folk.make("t:veil", {"body": "female", "hat": {"kind": "veil", "color": "#8a3a3a"}}))
	assert_eq(veil[Folk.SLOT_HAIR].to_html(false), "8a3a3a", "Örtü saçı örter")


func test_crowd_models_have_masks_and_cloth_measures() -> void:
	var models: Dictionary = Folk.data()["models"]
	for model: String in models:
		assert_true(StandIn.has_model(model), "%s modeli" % model)
		assert_true(Folk.has_mask(model), "%s_regions.png (tools/bake_regions.py --size 1024)" % model)
		var m: Dictionary = models[model]
		assert_between(float(m["cloth_lum"]), 0.02, 0.4, "%s giysi parlaklığı" % model)
		assert_true(float(m["band"][0]) < float(m["band"][1]), "%s boya bandı" % model)
		var regions := CharacterAvatar._load_regions(model)
		assert_true(regions.has("mask") and regions.has("skin_base"), "%s bölge maskesi ve ten tabanı" % model)
		var mask := (regions["mask"] as Texture2D).get_image()
		assert_eq(mask.get_width(), 1024, "%s maskesi dokuyla aynı boyda (1024)" % model)


func test_prepare_paints_the_full_person_and_survives_reload() -> void:
	var look := Folk.make("t:full", {"role": "townsfolk", "people": "yuezhi", "body": "male", "coat": "#6b2130"})
	var avatar := CharacterAvatar.new()
	var allocator := ClipVariety.Allocator.new()
	Folk.prepare(avatar, look, allocator)
	assert_eq(avatar.model_override, "crowd_hun_man")
	assert_eq(avatar.variety_person, "t:full")
	assert_true(allocator.people.has("t:full"), "Kişi dağıtıcıya kendi profiliyle kaydoldu")
	assert_eq(allocator.profile_for("t:full")["body"], "male")
	add_child(avatar)
	_trash.append(avatar)
	await wait_frames(1)
	assert_true(avatar.has_meshy_model(), "Kalabalık modeli yüklendi")
	assert_almost(avatar.model_scale, float(look["scale"]), 0.0001)
	var mat: ShaderMaterial = avatar.get_materials()[0]
	var cloth: Color = mat.get_shader_parameter("cloth_color")
	assert_true(cloth.a > 0.5, "Giysi boyası açık")
	assert_eq(Color(cloth.r, cloth.g, cloth.b).to_html(false), "6b2130")
	assert_true(bool(mat.get_shader_parameter("use_region_mask")), "Bölge maskesiyle ten ve saç")
	assert_eq((mat.get_shader_parameter("skin_color") as Color).to_html(false), (look["skin"] as Color).to_html(false))
	# Profilin yeniden uygulanması ve modelin yeniden kurulması boyayı silmez.
	avatar.apply_profile(CharacterProfile.new())
	avatar.model_override = "crowd_hun_man"
	await wait_frames(1)
	var again: ShaderMaterial = avatar.get_materials()[0]
	assert_true((again.get_shader_parameter("cloth_color") as Color).a > 0.5, "Boya model yeniden kurulunca da kalır")
	assert_eq((again.get_shader_parameter("skin_color") as Color).to_html(false), (look["skin"] as Color).to_html(false))
	# Çeşitliliğin aktarım kaynakları (bağışçı modeller) bırakılır: sahne kurulumunun sonu gibi.
	ClipVariety.release_sources()


func test_own_model_people_are_not_repainted() -> void:
	var avatar := CharacterAvatar.new()
	Folk.prepare(avatar, Folk.person("farnak"))
	assert_eq(avatar.model_override, "farnak")
	assert_true(avatar.shader_overrides.is_empty(), "Kendi modelindeki kişi boyanmaz")
	assert_almost(avatar.model_scale, 1.0, 0.0001)
	avatar.free()


func test_fallback_tint_is_mild() -> void:
	for coat in ["#6b2130", "#e6dcc4", "#2e2a2b", "#5e6a4a"]:
		var tint := Folk.fallback_tint({"model": "crowd_hun_man", "coat": Color.html(coat)})
		for c in 3:
			assert_between(tint[c], Folk.TINT_RANGE.x, Folk.TINT_RANGE.y, "%s: çarpan ılımlı" % coat)


func test_portrait_key_of_the_named_soldier() -> void:
	var look := Folk.person("berik")
	var key := Folk.key_of(look)
	assert_true(key.begins_with("folk|berik|"), key)
	assert_eq(key, Folk.key_of(Folk.person("berik")), "Anahtar kararlı")
	assert_ne(key, Folk.key_of(Folk.person("uldin")))
	var baker := PortraitBaker.new()
	add_child(baker)
	_trash.append(baker)
	var tex: Texture2D = await baker.bake_look(look)
	if PortraitBaker.can_render():
		assert_not_null(tex, "Pencerede portre çizilir")
	else:
		assert_null(tex, "Başsızda çizici yok: çağıran yedeğini çizer")


static func _plain(look: Dictionary) -> Dictionary:
	var out := {}
	for k: Variant in look:
		var v: Variant = look[k]
		out[k] = (v as Color).to_html(false) if v is Color else v
	return out


static func _colors(list: Array) -> PackedStringArray:
	var out := PackedStringArray()
	for c: Variant in list:
		out.append(Color.html(str(c)).to_html(false))
	return out


static func _mean_coat(people: String) -> Color:
	var sum := Color(0, 0, 0)
	for i in 40:
		var c: Color = Folk.make("t:mean:%s:%d" % [people, i], {"people": people, "role": "townsfolk"})["coat"]
		sum = Color(sum.r + c.r, sum.g + c.g, sum.b + c.b)
	return Color(sum.r / 40.0, sum.g / 40.0, sum.b / 40.0)
