class_name OkColor
extends RefCounted
## OKLab ve OKLCH renk uzayı (Björn Ottosson, https://bottosson.github.io/posts/oklab/): saf, yan etkisiz.
##
## Okunurluk ölçütü (K58, sanat-animasyon.md öneri 4) farkı OKLab'da ölçer: ΔE = OKLab uzaklığı; 0,02 aşağı yukarı
## görünür bir farktır. Pelerinin soğuk bandı OKLCH'dadır: ton (h, derece) ve doygunluk (C).
## tools/palette_compare.py aynı dönüşümü Python'da yapar; ikisi aynı sayıyı verir (test_cape_dye.gd sınar).
##
##   OkColor.oklab(Color.html("#2a6f8c"))   # Vector3(L, a, b)
##   OkColor.oklch(Color.html("#2a6f8c"))   # Vector3(L, C, h°)
##   OkColor.delta_e(a, b)


## sRGB renk (Color, 0..1; alfa yok sayılır) → OKLab (L, a, b).
static func oklab(c: Color) -> Vector3:
	var lin := c.srgb_to_linear()
	return OkColor.oklab_linear(Vector3(lin.r, lin.g, lin.b))


## Doğrusal RGB (0..1) → OKLab.
static func oklab_linear(rgb: Vector3) -> Vector3:
	var l := 0.4122214708 * rgb.x + 0.5363325363 * rgb.y + 0.0514459929 * rgb.z
	var m := 0.2119034982 * rgb.x + 0.6806995451 * rgb.y + 0.1073969566 * rgb.z
	var s := 0.0883024619 * rgb.x + 0.2817188376 * rgb.y + 0.6299787005 * rgb.z
	var l_ := OkColor._cbrt(l)
	var m_ := OkColor._cbrt(m)
	var s_ := OkColor._cbrt(s)
	return Vector3(
		0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
		1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
		0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_)


## sRGB renk → OKLCH (L, C, h derece 0..360).
static func oklch(c: Color) -> Vector3:
	var lab := OkColor.oklab(c)
	var chroma := Vector2(lab.y, lab.z).length()
	var hue := fposmod(rad_to_deg(atan2(lab.z, lab.y)), 360.0)
	return Vector3(lab.x, chroma, hue)


## İki sRGB renk arasındaki OKLab farkı.
static func delta_e(a: Color, b: Color) -> float:
	return OkColor.oklab(a).distance_to(OkColor.oklab(b))


## Renk OKLCH'da verilen ton aralığında (derece, uçlar dahil) ve en az chroma_min doygunlukta mı?
static func in_band(c: Color, hue_min: float, hue_max: float, chroma_min: float) -> bool:
	var lch := OkColor.oklch(c)
	return lch.y >= chroma_min and lch.z >= hue_min and lch.z <= hue_max


static func _cbrt(v: float) -> float:
	return signf(v) * pow(absf(v), 1.0 / 3.0)
