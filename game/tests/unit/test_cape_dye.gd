extends TestCase
## Pelerin boyası ve Kışlak kılığı (K58; story.md §7.4; Yol Haritası cape-dye): renk tek yerden gelir
## (CharacterOptions.cape_tint(eşya, boya)), beş boya oluşturucunun sırasıyla ve tasarımın rengiyle gelir, oluşturucunun
## önizlemesi ile oyundaki Mete aynı rengi verir (M18), kaftan pelerini boyamaz, soğuk bant kalabalık giysisinde yasaktır.

const CREATOR_SCENE := preload("res://scenes/ui/character_creator.tscn")
## Tasarımın beş boyası (K58, K101: Göl Mavisi #216e94, Turkuaz çıktı), oluşturucunun sırasıyla: kimlik, ad, renk.
const DESIGN_DYES := [
	["lake_blue", "Göl Mavisi", "#216e94"], ["sky", "Gök", "#3a78a8"], ["indigo", "Çivit", "#34508a"],
	["deep_indigo", "Koyu Çivit", "#2b3f66"], ["violet", "Menekşe", "#5f4a96"],
]
const CROWD_MODELS: Array[String] = ["crowd_hun_man", "crowd_hun_rider", "crowd_hun_woman"]
## Kalabalık dokusunda soğuk bantta kalabilecek en çok piksel payı (dokunun gölge ve kenar pikselleri için pay; ölçülen 0).
const CROWD_COLD_SHARE_MAX := 0.005


class FlatShape:
	extends TerrainShape

	func height_at(_x: float, _z: float) -> float:
		return 0.0


var _trash: Array[Node] = []


func after_each() -> void:
	for node in _trash:
		if is_instance_valid(node):
			node.queue_free()
	_trash.clear()
	CreatorTurntable.preload_enabled = true


# --- Boyalar ve tek kaynak --------------------------------------------------------------------------

func test_five_dyes_in_design_order_and_colors() -> void:
	assert_eq(CharacterOptions.count(&"cape_dye"), 5, "Oluşturucu beş boya sunar (K101)")
	var colors := CharacterOptions.colors(&"cape_dye")
	for i in DESIGN_DYES.size():
		var expected: Array = DESIGN_DYES[i]
		assert_eq(CharacterOptions.value_id(&"cape_dye", i), expected[0], "%d. boyanın kimliği" % i)
		assert_eq(CharacterOptions.value_name(&"cape_dye", i), expected[1], "%d. boyanın adı" % i)
		assert_eq(colors[i].to_html(false), Color.html(expected[2]).to_html(false), "%s'nin rengi" % expected[1])
		assert_eq(CharacterOptions.index_of_id(&"cape_dye", expected[0]), i)
	assert_eq(CharacterOptions.default_index(&"cape_dye"), 0, "Varsayılan boya Göl Mavisi")
	var p := CharacterProfile.new()
	assert_eq(p.cape_dye_id(), "lake_blue")
	assert_eq(p.cape_color().to_html(false), "216e94", "Profilin pelerini varsayılan olarak Göl Mavisi")


func test_cape_tint_is_the_single_source() -> void:
	for i in DESIGN_DYES.size():
		var expected := Color.html(DESIGN_DYES[i][2])
		assert_eq(CharacterOptions.cape_tint(&"cape_hostage", i), expected, "Kışlak Pelerini seçilen boyayı taşır")
		assert_eq(CharacterOptions.cape_tint(&"dyed_cape", i), expected, "Boyalı Pelerin de boyayı taşır")
	assert_true(CharacterOptions.cape_is_dyed(&"cape_hostage"))
	assert_false(CharacterOptions.cape_is_dyed(&"war_cape"))
	for dye in [0, 3, 5]:
		assert_eq(CharacterOptions.cape_tint(&"war_cape", dye).to_html(false), "a8321f", "Savaş peleri boyanmaz, kendi rengindedir")
	assert_eq(CharacterOptions.cape_tint(&"wolf_pelt", 2).to_html(false), "6a5f52")
	assert_eq(CharacterOptions.cape_tint(&"snow_cloak", 2).to_html(false), "d8d4c8")
	assert_eq(CharacterOptions.cape_tint(&"no_such_cape", 1).a, 0.0, "Bilinmeyen pelerin modelin kendi rengini bırakır")
	assert_eq(CharacterOptions.cape_tint(&"", 1).a, 0.0)
	assert_eq(CharacterOptions.cape_tint(&"cape_hostage", 99).to_html(false), "216e94", "Listede olmayan boya varsayılana düşer")
	assert_eq(CharacterOptions.cape_tint(&"cape_hostage", -1).to_html(false), "216e94")
	assert_eq(CharacterOptions.start_cape(), &"cape_hostage", "Başlangıç peleri Kışlak Pelerini")
	assert_eq(CharacterOptions.start_outfit(), &"hostage_coat", "Başlangıç kılığı Kışlak Kaftanı")
	assert_eq(CharacterOptions.item_name(&"cape_hostage"), "Kışlak Pelerini")
	assert_eq(CharacterOptions.item_name(&"hostage_coat"), "Kışlak Kaftanı")


func test_the_coat_does_not_dye_the_cape() -> void:
	var kit := CharacterOptions.outfit_colors(&"hostage_coat")
	assert_eq(kit.keys().size(), 3, "Kılığın bölgeleri: zırh levhası, gömlek, kuşak ve şeritler")
	assert_false(kit.has("cape"), "Kaftanın pelerin rengi yoktur (K58)")
	assert_eq((kit["plate"] as Color).to_html(false), "46372b")
	assert_eq((kit["tunic"] as Color).to_html(false), "a89a82")
	assert_eq((kit["trim"] as Color).to_html(false), "5d4a3a")
	for region in kit:
		assert_false(CharacterOptions.in_cold_band(kit[region]), "Kılığın %s rengi sıcak bantta" % region)
	for region in CharacterOptions.outfit_colors(&"no_such_outfit").values():
		assert_eq((region as Color).a, 0.0, "Bilinmeyen kılık modelin kendi rengini bırakır")


func test_oklab_matches_the_python_reference() -> void:
	# tools/palette_compare.py (oklab_linear) ile aynı sayılar: #2a6f8c → L 0,5112, a −0,0534, b −0,0622.
	var lab := OkColor.oklab(Color.html("#2a6f8c"))
	assert_almost(lab.x, 0.5112, 0.0005)
	assert_almost(lab.y, -0.0534, 0.0005)
	assert_almost(lab.z, -0.0622, 0.0005)
	var lch := OkColor.oklch(Color.html("#2a6f8c"))
	assert_almost(lch.y, 0.0819, 0.0005)
	assert_almost(lch.z, 229.4, 0.2)
	assert_almost(OkColor.delta_e(Color.html("#2a6f8c"), Color.html("#3e5f6b")), 0.0609, 0.0005, "Eski varsayılanla fark")
	assert_almost(OkColor.oklab(Color.WHITE).x, 1.0, 0.001)
	assert_almost(OkColor.oklab(Color.BLACK).x, 0.0, 0.001)


# --- Soğuk bant (kalabalıkta yasak) -----------------------------------------------------------------

func test_cold_band_is_forbidden_for_crowd_garments() -> void:
	for dye: Array in DESIGN_DYES:
		var c := Color.html(dye[2])
		assert_true(CharacterOptions.in_cold_band(c), "%s soğuk bantta (Mete'nin tek soğuk vurgusu)" % dye[1])
		assert_false(CharacterOptions.crowd_garment_allowed(c), "%s kalabalık giysisinde yasak" % dye[1])
	for warm in ["#7a2a22", "#a8321f", "#a68972", "#b5936e", "#4b2c1e", "#8fa058"]:
		assert_true(CharacterOptions.crowd_garment_allowed(Color.html(warm)), "Sıcak ya da toprak rengi serbest: %s" % warm)
	# Doygunluğu düşük gri ve lacivert gölge bandın dışında kalır (C < 0,05): kalabalığın pantolonu ve keçesi.
	for grey in ["#292727", "#3a3d44", "#45484f"]:
		assert_true(CharacterOptions.crowd_garment_allowed(Color.html(grey)), "Az doygun gri serbest: %s" % grey)
	# Bandın sınırları: ton 190–300°, doygunluk ≥0,05 (capes.json cold_band).
	assert_true(OkColor.in_band(Color.html("#1d7a80"), 190.0, 300.0, 0.05), "201° (K101'de listeden çıkan Turkuaz) bantta")
	assert_false(OkColor.in_band(Color.html("#1d7a80"), 210.0, 300.0, 0.05), "Bant 210°'den başlasa 201° dışarıda kalırdı")


func test_crowd_models_keep_out_of_the_cold_band() -> void:
	# Var olan kalabalık modellerinin dokusu kuralı tutar: soğuk banttaki piksel payı ≈0 (palette_compare.py --cape ile aynı ölçü).
	for model in CROWD_MODELS:
		var path := "res://assets/characters/%s/%s_Image_0.jpg" % [model, model]
		var texture := load(path) as Texture2D
		assert_not_null(texture, "Doku yüklenmeli: %s" % path)
		if texture == null:
			continue
		var image := texture.get_image()
		if image.is_compressed():
			image.decompress()
		var cold := 0
		var total := 0
		var step := maxi(image.get_width() / 96, 1)
		for y in range(0, image.get_height(), step):
			for x in range(0, image.get_width(), step):
				total += 1
				if CharacterOptions.in_cold_band(image.get_pixel(x, y)):
					cold += 1
		assert_true(float(cold) / maxf(total, 1) <= CROWD_COLD_SHARE_MAX,
			"%s soğuk bantta %d / %d piksel taşımamalı" % [model, cold, total])


# --- Kılık maskesi ve malzeme -------------------------------------------------------------------------

func test_mete_has_a_dye_mask_with_cape_and_coat_regions() -> void:
	var regions := CharacterAvatar._load_regions("mete")
	assert_true(regions.has("dye_mask"), "mete_dye.png yüklenmeli")
	assert_true(regions.has("dye_mask2"), "mete_dye2.png yüklenmeli")
	for key in ["cape_lum", "plate_lum", "tunic_lum", "trim_lum"]:
		assert_true(regions.has(key), "mete_dye.json %s taşımalı" % key)
	assert_between(float(regions.get("cape_lum", 0.0)), 0.02, 0.2, "Kızıl pelerinin doğrusal ortalama parlaklığı")
	var mask := (regions["dye_mask"] as Texture2D).get_image()
	var albedo := (load("res://assets/characters/mete/mete_Image_0.jpg") as Texture2D).get_image()
	var skin := (load("res://assets/characters/mete/mete_regions.png") as Texture2D).get_image()
	for image: Image in [mask, albedo, skin]:
		if image.is_compressed():
			image.decompress()
	var cape := 0
	var cape_red := 0
	var cape_on_body := 0
	var total := 0
	for y in range(0, mask.get_height(), 16):
		for x in range(0, mask.get_width(), 16):
			total += 1
			if mask.get_pixel(x, y).r < 0.6:
				continue
			cape += 1
			var c := albedo.get_pixel(x * albedo.get_width() / mask.get_width(), y * albedo.get_height() / mask.get_height())
			if c.r > c.g * 1.4 and c.r > c.b * 1.4:
				cape_red += 1
			var r := skin.get_pixel(x * skin.get_width() / mask.get_width(), y * skin.get_height() / mask.get_height())
			if maxf(r.r, maxf(r.g, r.b)) > 0.5:
				cape_on_body += 1
	assert_true(float(cape) / total > 0.15, "Pelerin dokunun büyük bir bölümüdür (%d / %d)" % [cape, total])
	assert_true(float(cape_red) / maxf(cape, 1) > 0.9, "Maskenin pelerin pikselleri modelin kızıl kumaşıdır (%d / %d)" % [cape_red, cape])
	assert_true(float(cape_on_body) / maxf(cape, 1) < 0.01, "Pelerin maskesi saça, tene ve göze taşmaz")


func test_creator_and_game_give_the_same_cape_color() -> void:
	# M18 (sanat-animasyon.md öneri 12): oluşturucunun önizlemesi ve oyundaki Mete aynı malzeme yolundan aynı rengi verir.
	CreatorTurntable.preload_enabled = false
	var creator := CREATOR_SCENE.instantiate() as CharacterCreator
	add_child(creator)
	_trash.append(creator)
	var player := await _make_player()
	for i in DESIGN_DYES.size():
		var profile := CharacterProfile.new()
		profile.set_value(&"cape_dye", i)
		creator.open(profile)
		player.use_profile(profile)
		var preview := creator.get_avatar()
		var game := player.get_avatar()
		var expected := CharacterOptions.cape_tint(CharacterOptions.start_cape(), i)
		assert_eq(preview.get_cape_color(), expected, "Oluşturucu %s'yi göstermeli" % DESIGN_DYES[i][1])
		assert_eq(game.get_cape_color(), expected, "Oyundaki Mete %s'yi giymeli" % DESIGN_DYES[i][1])
		assert_eq(preview.get_outfit_colors(), game.get_outfit_colors(), "Kışlak Kaftanı ikisinde aynı")
	for avatar: CharacterAvatar in [creator.get_avatar(), player.get_avatar()]:
		assert_true(avatar.has_dye_mask(), "Mete'nin kılık maskesi yüklü")
		assert_eq(avatar.worn_outfit(), &"hostage_coat")
		assert_eq(avatar.worn_cape(), &"cape_hostage")
		var mat := avatar.get_materials()[0]
		assert_true(bool(mat.get_shader_parameter(&"use_dye_mask")), "Malzeme kılık maskesini kullanır")
		assert_eq((mat.get_shader_parameter(&"dye_mask") as Texture2D).resource_path, "res://assets/characters/mete/mete_dye.png")
		assert_eq(mat.shader, CharacterAvatar.CHARACTER_SHADER, "Aynı gölgelendirici")


func test_dye_change_reaches_the_preview_at_once() -> void:
	CreatorTurntable.preload_enabled = false
	var creator := CREATOR_SCENE.instantiate() as CharacterCreator
	add_child(creator)
	_trash.append(creator)
	creator.open(CharacterProfile.new())
	creator.change(&"cape_dye", 2)
	assert_eq(creator.get_avatar().get_cape_color().to_html(false), "34508a", "Boya aynı karede pelerine geçmeli (Çivit)")
	creator.select_color(&"cape_dye", 4)
	assert_eq(creator.get_avatar().get_cape_color().to_html(false), "5f4a96", "Kumaş örneğine tıklamak da (Menekşe)")
	assert_true(creator.undo())
	assert_eq(creator.get_avatar().get_cape_color().to_html(false), "34508a", "Geri alma pelerine de uygulanır")


func test_fixed_models_keep_their_own_look() -> void:
	# Sabit model gösteren avatar (NPC, ansiklopedi, sinema) Kışlak kılığını giymez: kızıl pelerin ve zırh modelin kendisidir.
	var avatar := CharacterAvatar.new()
	avatar.model_override = "mete"
	add_child(avatar)
	_trash.append(avatar)
	assert_eq(avatar.worn_cape(), &"")
	assert_eq(avatar.worn_outfit(), &"")
	assert_eq(avatar.get_cape_color().a, 0.0, "Pelerin modelin kendi rengi")
	for c in avatar.get_outfit_colors().values():
		assert_eq((c as Color).a, 0.0)
	# Elle verilen kılık giyilir (ör. II. Perde'nin Kızıl Pelerin'i).
	avatar.cape_item = &"war_cape"
	assert_eq(avatar.get_cape_color().to_html(false), "a8321f")
	avatar.cape_item = &"none"
	assert_eq(avatar.get_cape_color().a, 0.0, "&\"none\" pelerinsizdir")


func test_chibi_fallback_takes_the_cape_from_the_same_source() -> void:
	var avatar := CharacterAvatar.new()
	avatar.use_meshy_models = false
	add_child(avatar)
	_trash.append(avatar)
	var profile := CharacterProfile.new()
	profile.set_value(&"cape_dye", 4)
	avatar.apply_profile(profile)
	assert_eq(avatar.get_cape_color().to_html(false), "5f4a96", "Yedeğin peleri de cape_tint'ten (Menekşe)")
	assert_true(avatar.has_cape())


func test_model_without_a_cape_has_no_tint() -> void:
	# Kadın kahramanın (Tip 2) pelerini yoktur: kılık maskesi de yoktur, boya malzemeye işlemez.
	var avatar := CharacterAvatar.new()
	add_child(avatar)
	_trash.append(avatar)
	var profile := CharacterProfile.new()
	profile.set_value(&"body_type", 1)
	profile.set_value(&"cape_dye", 3)
	avatar.apply_profile(profile)
	assert_eq(avatar.model_id, "hero_f")
	assert_false(avatar.has_dye_mask())
	assert_false(avatar.has_cape())
	assert_eq(avatar.get_cape_color().a, 0.0)


## Dünyasız (düz zeminli) oyuncu: oyundaki Mete'nin denetleyicisi ve avatarı.
func _make_player() -> PlayerController:
	var player := PlayerController.new()
	player.terrain_shape = FlatShape.new()
	player.start_active = false
	var avatar := CharacterAvatar.new()
	player.add_child(avatar)
	add_child(player)
	_trash.append(player)
	player.set_process(false)
	await wait_frames(1)
	player.obstacles = []
	return player
