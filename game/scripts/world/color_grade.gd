class_name ColorGrade
extends RefCounted
## "After the Wind" tarzı renk derecelendirmesi (color grading) için 3B LUT üretir.
##
## Referans görüntülerden ölçülen karakter: saf siyah ve saf beyaz yoktur.
##   - Koyular sıcak bir griye kalkar (lift),
##   - beyazlar hafif bastırılır ve fildişine döner (gain),
##   - aşırı doygun renkler biraz yumuşar (saturation).
## LUT, Environment.adjustment_color_correction'a verilir ve tüm 3B görüntüye (gökyüzü, su, çimen,
## karakterler...) aynı şekilde uygulanır; arayüz etkilenmez.
##
## Gece aşaması (night = true): malzemeler gündüz renkleriyle (2. referansa göre) ayarlıdır; gece
## görünümü (1. referans) "gündüzden geceye" renk ayarıyla elde edilir:
##   - yeşiller ve sarı-yeşiller koyulaşıp sönükleşir, zeytin tonuna döner (4. referans: ay ışıklı kamp),
##   - az doygun renkler (taş, keçe, gri) isteğe bağlı olarak mavi-griye karışabilir (şu an çok az),
##   - genel doygunluk biraz düşer,
##   - parlak sıcak renkler (ateş, kapı ve fener ışığı) ile çok parlak renkler (ay, yıldızlar) korunur.
## Değerler, menü görüntüsünün referansla (assets/_reference/menu_camp.png) aynı bölgelerinden ölçülen
## renk çiftlerine (renk ayarı kapalı ham görüntü → referans) uydurulmuştur.

## Saf siyahın dönüştüğü renk (sRGB).
var lift := Color(0.187, 0.163, 0.141)
## Saf beyazın dönüştüğü renk (sRGB).
var gain := Color(0.967, 0.943, 0.921)
## Orta tonlar için üs (1 = doğrusal; 1'den büyük orta tonları açar).
var gamma := 1.0
## Doygunluk çarpanı (1 = değişmez).
var saturation := 1.0
## Orta tonlara eklenen sıcaklık (sarı-turuncuya kayma); koyu ve açık tonlar etkilenmez.
var warmth := 0.012
var size := 32

# --- Gece aşaması ---
## Gece aşaması açık mı?
var night := false
## Yeşil bandının başladığı ton (derece; altı sarı/turuncu, etkilenmez).
var night_green_from := 63.6
## Yeşillerin ton kayması (derece) ve koyu yeşillerde eklenen fazladan kayma.
var night_green_shift := 3.8
var night_green_dark_shift := -15.1
## Yeşillerin doygunluk ve parlaklık çarpanı.
var night_green_saturation := 0.587
var night_green_value := 0.681
## Bu doygunluğun altındaki renkler mavi-griye çekilir (0.2 genişliğinde yumuşak geçiş).
var night_grey_from := 0.172
## Mavi-gri renk (ton derece, doygunluk), parlaklık çarpanı ve karışım miktarı.
var night_grey_hue := 222.7
var night_grey_saturation := 0.45
var night_grey_value := 1.05
var night_grey_amount := 0.01
## Korunmayan tüm renklere uygulanan doygunluk ve parlaklık çarpanı.
var night_general_saturation := 0.85
var night_general_value := 1.0


## Karakter oluşturucu (3. referans) için ölçülen soluk film görünümü (varsayılan değerler).
static func creator() -> ColorGrade:
	return ColorGrade.new()


## Oyun dünyası (2. referans, After the Wind oynanış) için ölçülen görünüm: siyahlar neredeyse hiç
## kalkmaz (doygun yeşiller korunur), beyazlar sıcak kreme döner.
static func world() -> ColorGrade:
	var grade := ColorGrade.new()
	grade.lift = Color(0.03, 0.03, 0.01)
	grade.gain = Color(1.0, 0.985, 0.93)
	grade.warmth = 0.01
	grade.saturation = 1.04
	return grade


## Oyun dünyasının gece görünümü (1. referans: ay ışıklı kamp): gündüz renkleri + gece aşaması.
static func world_night() -> ColorGrade:
	var grade := ColorGrade.new()
	grade.lift = Color(0.0, 0.0, 0.0)
	grade.gain = Color(1.0, 1.0, 1.0)
	grade.warmth = 0.0
	grade.night = true
	return grade


## Tek bir sRGB rengi dönüştürür (saf fonksiyon; LUT ve testler bunu kullanır).
func apply(c: Color) -> Color:
	var base := _apply_film(c)
	return night_apply(base) if night else base


## Gece aşaması (saf fonksiyon): bkz. sınıf açıklaması.
func night_apply(c: Color) -> Color:
	var h := c.h * 360.0
	var s := c.s
	var v := c.v
	var protect := _band(h, 0.0, 62.0, 10.0) * smoothstep(0.3, 0.55, s) * smoothstep(0.45, 0.75, v)
	var green := _band(h, night_green_from, 150.0, 12.0) * smoothstep(0.12, 0.3, s)
	var shift := (night_green_shift + night_green_dark_shift * (1.0 - smoothstep(0.2, 0.6, v))) * green
	var h2 := fposmod(h + shift, 360.0)
	var s2 := s * (1.0 + (night_green_saturation - 1.0) * green)
	var v2 := v * (1.0 + (night_green_value - 1.0) * green)
	var out := Color.from_hsv(h2 / 360.0, clampf(s2, 0.0, 1.0), clampf(v2, 0.0, 1.0))
	# Az doygun renkler: ton çemberinde döndürülmez (krem renkler mora kaymasın), parlaklığı korunarak
	# mavi-gri renge karıştırılır. Çok parlak renkler (ay, yıldız) bu adımdan korunur.
	var grey := (1.0 - smoothstep(night_grey_from, night_grey_from + 0.2, s)) * (1.0 - smoothstep(0.7, 0.95, v))
	var tint := Color.from_hsv(night_grey_hue / 360.0, night_grey_saturation, 1.0)
	var tinted := tint * (_luma(out) / maxf(_luma(tint), 0.0001)) * night_grey_value
	out = out.lerp(Color(tinted.r, tinted.g, tinted.b), grey * night_grey_amount)
	# Genel gece aşaması: doygunluk biraz düşer (koyu, sönük gece paleti).
	var l := _luma(out)
	out = Color(l + (out.r - l) * night_general_saturation, l + (out.g - l) * night_general_saturation,
		l + (out.b - l) * night_general_saturation) * night_general_value
	var result := c.lerp(out, 1.0 - protect)
	return Color(result.r, result.g, result.b)


static func _luma(c: Color) -> float:
	return c.r * 0.299 + c.g * 0.587 + c.b * 0.114


## Ton aralığı ağırlığı (derece; lo..hi arası 1, kenarlarda soft genişliğinde yumuşak geçiş).
static func _band(h: float, lo: float, hi: float, soft: float) -> float:
	return smoothstep(lo - soft, lo, h) * (1.0 - smoothstep(hi, hi + soft, h))


## Kaldırma/kazanç/sıcaklık/doygunluk aşaması ("soluk film" görünümü).
func _apply_film(c: Color) -> Color:
	var r := lift.r + pow(clampf(c.r, 0.0, 1.0), 1.0 / gamma) * (gain.r - lift.r)
	var g := lift.g + pow(clampf(c.g, 0.0, 1.0), 1.0 / gamma) * (gain.g - lift.g)
	var b := lift.b + pow(clampf(c.b, 0.0, 1.0), 1.0 / gamma) * (gain.b - lift.b)
	var l := r * 0.299 + g * 0.587 + b * 0.114
	var mid := 4.0 * l * (1.0 - l)
	r += warmth * 0.5 * mid
	b -= warmth * mid
	return Color(lerpf(l, r, saturation), lerpf(l, g, saturation), lerpf(l, b, saturation))


## size³ boyutunda 3B LUT dokusu üretir (x = kırmızı, y = yeşil, z = mavi).
func build_lut() -> ImageTexture3D:
	var slices: Array[Image] = []
	for z in size:
		var img := Image.create_empty(size, size, false, Image.FORMAT_RGB8)
		for y in size:
			for x in size:
				var c := Color(float(x) / float(size - 1), float(y) / float(size - 1), float(z) / float(size - 1))
				img.set_pixel(x, y, apply(c))
		slices.append(img)
	var tex := ImageTexture3D.new()
	tex.create(Image.FORMAT_RGB8, size, size, size, false, slices)
	return tex


## Ortama uygular: renk düzeltmesini açar ve LUT'u bağlar.
func apply_to(env: Environment) -> void:
	if env == null:
		return
	env.adjustment_enabled = true
	env.adjustment_color_correction = build_lut()
