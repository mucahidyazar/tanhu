extends TestCase
## Oyuncu modellerinin bölge maskeleri (tools/bake_regions.py ile pişirilen <id>_regions.png / _regions2.png /
## _regions.json) için testler. Karakter oluşturucudaki saç, ten ve göz rengi bu maskelerle değişir; maske eksik,
## boş ya da düşük çözünürlüklü olursa renk seçimi ya hiçbir şey yapmaz ya da komşu doku adalarına taşar.
## (Model yeniden üretilirse: python3 tools/bake_regions.py assets/characters/<id>/<id>.glb)

const PLAYER_MODELS: Array[String] = ["mete", "hero_f"]
## Gerçekçi modellerin doku atlası binlerce küçük adadan oluşur; 1024 piksellik maske komşu adalara sızar.
const REALISTIC_MASK_SIZE := 2048
## Maskeden kaç pikselde bir örnek alınacağı (hız için).
const SAMPLE_STEP := 8
## Bölgelerin atlastaki en küçük payları (örneklenen piksellere oranla).
const MIN_HAIR_SHARE := 0.02
const MIN_SKIN_SHARE := 0.01
const MIN_EYE_SHARE := 0.0002
## Aynı pikselin hem saç hem ten sayılma oranı (ten piksellerine göre) en fazla bu kadar olabilir.
const MAX_OVERLAP_SHARE := 0.05


func test_player_models_have_region_masks_and_base_colors() -> void:
	for id in PLAYER_MODELS:
		if not ResourceLoader.exists(CharacterOptions.model_path(id)):
			continue
		var regions := CharacterAvatar._load_regions(id)
		assert_true(regions.has("mask"), "%s_regions.png eksik" % id)
		assert_true(regions.has("mask2"), "%s_regions2.png eksik" % id)
		for key in ["hair_base", "skin_base", "eye_base"]:
			assert_true(regions.has(key), "%s_regions.json içinde %s yok" % [id, key])
		if regions.has("skin_base"):
			var skin: Color = regions["skin_base"]
			assert_true(skin.r > skin.b, "%s ten rengi sıcak bir ton olmalı (%s)" % [id, skin.to_html(false)])


func test_player_region_masks_cover_hair_skin_and_eyes() -> void:
	for id in PLAYER_MODELS:
		if not ResourceLoader.exists(CharacterOptions.model_path(id)):
			continue
		var regions := CharacterAvatar._load_regions(id)
		if not regions.has("mask"):
			continue
		var image := (regions["mask"] as Texture2D).get_image()
		assert_eq(image.get_width(), REALISTIC_MASK_SIZE, "%s maskesi gerçekçi model çözünürlüğünde olmalı" % id)
		var shares := RegionStats.shares(image, SAMPLE_STEP)
		assert_true(shares["hair"] > MIN_HAIR_SHARE, "%s saç maskesi boş gibi (%.4f)" % [id, shares["hair"]])
		assert_true(shares["skin"] > MIN_SKIN_SHARE, "%s ten maskesi boş gibi (%.4f)" % [id, shares["skin"]])
		assert_true(shares["eye"] > MIN_EYE_SHARE, "%s göz maskesi boş gibi (%.5f)" % [id, shares["eye"]])
		assert_true(shares["overlap"] <= MAX_OVERLAP_SHARE, "%s: saç ve ten maskeleri üst üste binmemeli (%.3f)" % [id, shares["overlap"]])


func test_region_stats_helper() -> void:
	var image := Image.create(4, 4, false, Image.FORMAT_RGB8)
	image.fill(Color.BLACK)
	image.set_pixel(0, 0, Color(1.0, 0.0, 0.0))
	image.set_pixel(1, 0, Color(0.0, 1.0, 0.0))
	image.set_pixel(2, 0, Color(1.0, 1.0, 0.0))
	image.set_pixel(3, 0, Color(0.0, 0.0, 1.0))
	var shares := RegionStats.shares(image, 1)
	assert_almost(shares["hair"], 2.0 / 16.0)
	assert_almost(shares["skin"], 2.0 / 16.0)
	assert_almost(shares["eye"], 1.0 / 16.0)
	assert_almost(shares["overlap"], 0.5, 0.0001, "İki ten pikselinden biri saçla çakışıyor")


## Maske görüntüsünden bölge payları (saf yardımcı; testte tanımlı).
class RegionStats:
	## R = saç, G = ten, B = göz; step pikselde bir örnek alınır. Döner: {hair, skin, eye, overlap}
	## (overlap: hem saç hem ten olan örneklerin ten örneklerine oranı).
	static func shares(image: Image, step: int) -> Dictionary:
		var total := 0
		var hair := 0
		var skin := 0
		var eye := 0
		var both := 0
		for y in range(0, image.get_height(), step):
			for x in range(0, image.get_width(), step):
				var c := image.get_pixel(x, y)
				total += 1
				var is_hair := c.r > 0.5
				var is_skin := c.g > 0.5
				hair += 1 if is_hair else 0
				skin += 1 if is_skin else 0
				eye += 1 if c.b > 0.5 else 0
				both += 1 if is_hair and is_skin else 0
		var n := float(maxi(total, 1))
		return {"hair": hair / n, "skin": skin / n, "eye": eye / n, "overlap": both / float(maxi(skin, 1))}
