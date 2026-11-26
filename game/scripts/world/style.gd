class_name Style
extends RefCounted
## Ortak malzeme fabrikası ve renk paleti.
##
## Aynı renk ve ayarlarla istenen malzemeler önbellekten paylaşılır;
## yüzlerce küçük parça (karakter, dekor) tek tek malzeme üretmez.

const TOON_SHADER := preload("res://shaders/soft_toon.gdshader")
const TOON_DOUBLE_SHADER := preload("res://shaders/soft_toon_double.gdshader")

# --- Palet (sahnenin genel renk dili) ----------------------------------------
const FELT := Color(0.94, 0.85, 0.69)
const FELT_SHADOW := Color(0.78, 0.72, 0.62)
const WOOD := Color(0.47, 0.3, 0.17)
const WOOD_DARK := Color(0.3, 0.19, 0.11)
const WOOD_LIGHT := Color(0.62, 0.43, 0.25)
const ORNAMENT_BROWN := Color(0.42, 0.24, 0.13)
const FUR_WHITE := Color(0.95, 0.92, 0.86)
const FUR_BROWN := Color(0.55, 0.38, 0.24)
const SKIN := Color(0.98, 0.8, 0.66)
const SKIN_WARM := Color(0.94, 0.72, 0.56)
const HAIR_DARK := Color(0.16, 0.1, 0.08)
const HAIR_BROWN := Color(0.3, 0.18, 0.11)
const HAIR_WHITE := Color(0.92, 0.92, 0.9)
const IRON := Color(0.36, 0.37, 0.42)
const GOLD := Color(0.86, 0.66, 0.3)
const STONE := Color(0.6, 0.6, 0.58)
const STRAW := Color(0.83, 0.68, 0.38)

## Kampın damgası (tamga) ve kalkan yüzü dokularının çözünürlüğü (piksel).
const TAMGA_TEXTURE_SIZE := 128
const SHIELD_TEXTURE_SIZE := 256
## Yurt keçesine boyanan damganın çizgi kalınlaştırması (bayraktakinden daha kalın, uzaktan okunur).
const TAMGA_PAINT_BOLD := 0.014

static var _cache: Dictionary = {}
static var _tamga_texture: ImageTexture
static var _shield_texture: ImageTexture


## Yumuşak toon malzemesi döndürür. options: shader parametreleri (ör. {"brush_strength": 0.2}).
static func toon(color: Color, options: Dictionary = {}) -> ShaderMaterial:
	return _toon_material(TOON_SHADER, "toon", color, options)


## İki yüzlü toon malzemesi (pelerin, kumaş gibi arkası da görünen ince yüzeyler).
static func toon_double(color: Color, options: Dictionary = {}) -> ShaderMaterial:
	return _toon_material(TOON_DOUBLE_SHADER, "double", color, options)


static func _toon_material(shader: Shader, kind: String, color: Color, options: Dictionary) -> ShaderMaterial:
	var key := "%s|%s|%s" % [kind, color.to_html(), str(options)]
	if _cache.has(key):
		return _cache[key]
	var mat := ShaderMaterial.new()
	mat.shader = shader
	mat.set_shader_parameter("albedo", color)
	for param in options:
		mat.set_shader_parameter(param, options[param])
	_cache[key] = mat
	return mat


## Kendi kendine parlayan (ateş, fener, pencere ışığı) malzeme.
static func glow(color: Color, energy: float) -> ShaderMaterial:
	return toon(color, {"emission_color": color, "emission_energy": energy, "brush_strength": 0.0})


## Işıktan etkilenmeyen düz renk (gözlerdeki parıltı gibi küçük ayrıntılar için).
static func unshaded(color: Color) -> StandardMaterial3D:
	var key := "unshaded|%s" % color.to_html()
	if _cache.has(key):
		return _cache[key]
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	_cache[key] = mat
	return mat


## Kampın damgası (tamga): halka, ortasından geçen dikey çubuk ve üstte yatay kol; bayraklardaki
## damgayla (banner.gdshader) aynı biçim. p: merkez (0, 0), aşağı +y. Döner: işaretli uzaklık (içeride eksi; saf fonksiyon).
static func tamga_distance(p: Vector2) -> float:
	var ring := absf(p.length() - 0.15) - 0.028
	var bar := maxf(absf(p.x) - 0.024, absf(p.y - 0.05) - 0.3)
	var arms := maxf(absf(p.y + 0.24) - 0.024, absf(p.x) - 0.12)
	return minf(ring, minf(bar, arms))


## Damganın beyaz dokusu (alfa = damga; kenarlar fırçayla boyanmış gibi hafif düzensiz, çizgiler kalın).
## Rengi onu kullanan Decal ya da malzeme verir. Bir kez üretilir, paylaşılır.
static func tamga_texture() -> ImageTexture:
	if _tamga_texture == null:
		_tamga_texture = ImageTexture.create_from_image(tamga_image(TAMGA_TEXTURE_SIZE, TAMGA_PAINT_BOLD))
	return _tamga_texture


## tamga_texture'ın görüntüsü (saf fonksiyon, test edilebilir): damga görüntünün ortasında, kenarlara taşmaz.
## bold: çizgileri bu kadar kalınlaştırır (damga birimi; 0 = bayraktaki kalınlık).
static func tamga_image(size: int, bold: float = 0.0) -> Image:
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var span := 0.8 + bold * 2.0
	var texel := span / float(size)
	for y in size:
		for x in size:
			var p := (Vector2(x + 0.5, y + 0.5) / float(size) - Vector2(0.5, 0.5)) * span
			# Elle boyanmış gibi titrek kenar: düşük frekanslı, belirlenimci bir dalgalanma.
			var wobble := sin(p.x * 61.0 + p.y * 23.0) * 0.004 + sin(p.y * 47.0 - p.x * 31.0) * 0.003
			var d := tamga_distance(p) + wobble - bold
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, clampf(0.5 - d / (texel * 1.5), 0.0, 1.0)))
	img.generate_mipmaps()
	return img


## Yuvarlak kalkanın yüzü: krem boyalı tahta üstünde dalgalı ışınlı kırmızı Hun güneşi (silah sehpası
## modelindeki kalkanla aynı motif). Bir kez üretilir, paylaşılır.
static func shield_texture() -> ImageTexture:
	if _shield_texture == null:
		_shield_texture = ImageTexture.create_from_image(shield_image(SHIELD_TEXTURE_SIZE))
	return _shield_texture


## shield_texture'ın görüntüsü (saf fonksiyon). UV (0,5; 0,5) kalkanın ortası, yarıçap 0,5.
static func shield_image(size: int) -> Image:
	var img := Image.create_empty(size, size, false, Image.FORMAT_RGB8)
	var cream := Color(0.86, 0.77, 0.6)
	var red := Color(0.62, 0.14, 0.09)
	var rays := 12.0
	for y in size:
		for x in size:
			var q := (Vector2(x + 0.5, y + 0.5) / float(size) - Vector2(0.5, 0.5)) * 2.0
			var r := q.length()
			# Dikey tahtalar: aralarında koyu derz, üstünde ince damar.
			var plank := fposmod(q.x * 2.5 + 0.5, 1.0)
			var seam := smoothstep(0.0, 0.05, plank) * smoothstep(1.0, 0.95, plank)
			var grain := 0.5 + 0.5 * sin(q.y * 31.0 + sin(q.x * 11.0) * 2.0 + floorf(q.x * 2.5) * 1.7)
			var col := cream * (0.86 + grain * 0.1) * (0.8 + seam * 0.2)
			# Güneş: dolu daire ve sivrilen, dalgalı ışınlar.
			var angle := atan2(q.y, q.x)
			var sector := TAU / rays
			var delta := angle - roundf(angle / sector) * sector + sin(r * 16.0) * 0.07
			var ray_width := 0.16 * (1.0 - clampf((r - 0.26) / 0.38, 0.0, 1.0))
			if r < 0.25 or (r < 0.66 and absf(delta) < ray_width):
				col = red * (0.9 + grain * 0.12)
			img.set_pixel(x, y, Color(col.r, col.g, col.b))
	img.generate_mipmaps()
	return img


## Önbelleği temizler (testlerde ve editörde yeniden üretim için).
static func clear_cache() -> void:
	_cache.clear()
