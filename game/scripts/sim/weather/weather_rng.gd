class_name WeatherRng
extends RefCounted
## Havanın tohumu (weather.md §5.5; godot.md §3.2 madde 2, §8.2): prototipin weather-core.js'indeki strHash (FNV-1a), hash32 (murmur3
## karışımı) ve mulberry32 bit bit taşınır. JS'nin 32 bitlik işlemleri (Math.imul, >>>, |0) GDScript'in 64 bitlik tamsayısında
## 0xFFFFFFFF maskesiyle yürür: bütün ara değerler işaretsiz 32 bit tutulur, çarpım taşmasın diye 16 bitlik yarımlarla yapılır.
## Math.random kullanılmaz; aynı kayıt, aynı saat, aynı dünya her zaman aynı havayı verir.
##   var rng := WeatherRng.new(WeatherRng.hash32(seed, WeatherRng.str_hash("tanhu_camp"), floori(t0 * 4.0)))
##   rng.next()          # [0, 1)
##   rng.span(1.0, 2.0)

const MASK := 0xFFFFFFFF
const TWO32 := 4294967296.0

var s := 1


func _init(p_seed: int = 1) -> void:
	s = p_seed & MASK


## Yeniden tohumlar (kare başına nesne ayrılmaz).
func reseed(p_seed: int) -> WeatherRng:
	s = p_seed & MASK
	return self


## mulberry32: [0, 1).
func next() -> float:
	s = (s + 0x6d2b79f5) & MASK
	var t := s
	t = imul(t ^ (t >> 15), t | 1)
	t = t ^ ((t + imul(t ^ (t >> 7), t | 61)) & MASK)
	return float((t ^ (t >> 14)) & MASK) / TWO32


## a + (b − a) × next() (prototipin range'i).
func span(a: float, b: float) -> float:
	return a + (b - a) * next()


## Math.imul'un işaretsiz 32 bitlik sonucu (taşmasız: 16 bitlik yarımlar).
static func imul(a: int, b: int) -> int:
	a &= MASK
	b &= MASK
	var lo := (a & 0xFFFF) * b
	var hi := ((a >> 16) * b) & 0xFFFF
	return (lo + (hi << 16)) & MASK


## FNV-1a: zon adı tohuma sayı olarak girer (UTF-16 birimi; zon adları ASCII'dir).
static func str_hash(text: String) -> int:
	var h := 0x811c9dc5
	for i in text.length():
		h ^= text.unicode_at(i)
		h = imul(h, 0x01000193)
	return h & MASK


static func _mix(h: int, k: int) -> int:
	k = imul(k & MASK, 0xcc9e2d51)
	k = ((k << 15) & MASK) | (k >> 17)
	k = imul(k, 0x1b873593)
	h = (h ^ k) & MASK
	h = ((h << 13) & MASK) | (h >> 19)
	return (imul(h, 5) + 0xe6546b64) & MASK


## hash32(journeySeed, zone, floor(t0 × 4)) (weather.md §5.5): sıra sayısı tohuma girmez; d ikinci akışlar içindir (alt olay, kabuk).
## Eksi argüman JS'nin |0'ı gibi 32 bitlik ikiye tümleyene çevrilir.
static func hash32(a: int, b: int, c: int, d: int = 0) -> int:
	var h := _mix(_mix(_mix(_mix(0x9747b28c, a), b), c), d)
	h ^= h >> 16
	h = imul(h, 0x85ebca6b)
	h ^= h >> 13
	h = imul(h, 0xc2b2ae35)
	h ^= h >> 16
	return h & MASK


## hash32'nin [0, 1) kesri.
static func unit(a: int, b: int, c: int, d: int = 0) -> float:
	return float(hash32(a, b, c, d)) / TWO32


## JS'nin Math.round'u (yarım +∞'a): GDScript'in round'u yarımı sıfırdan uzağa yuvarlar.
static func js_round(x: float) -> float:
	var f := floorf(x)
	return f + 1.0 if x - f >= 0.5 else f
