class_name GameCalendar
extends RefCounted
## Takvim (K20, K33, K42, K55, K56, K67; time.md §2, §11, §12.4; godot.md §3.5): saf, yalnız static func. Tek sayaç GameClock'un
## day_n'idir (rehinenin günü): day_n 1 = 26 Ocak MÖ 212 (doy 25, 0 = 1 Ocak). Oyun yılı 365 gündür, artık gün yoktur; etiket gerçek
## takvimin (Jülyen tablo) günüdür.
##   year_bc = 212 − floor((day_n + 24) / 365),  doy = (day_n + 24) mod 365 (negatifte pozitif kalan)
## Örnek: −7.785 → 27 Eylül MÖ 234 (doğum), −5.600 → 22 Eylül MÖ 228 (Çocukluk), −41 → 15 Aralık MÖ 213, 1.041 → 2 Aralık MÖ 210 (Gün I),
## 1.171 → 11 Nisan MÖ 209 (Serbest Gez'in açılışı ve Ev).
##
## Ay (time.md §2): yaş = (mutlak gün − 1044,75 + 29,53/2) mod 29,530588; dolunay Gün IV 18:00'dedir, aydınlık (1 − cos(2π·yaş/29,53)) / 2.
## Mutlak gün kesirlidir: day_n + dakika / 1440 (GameClock.abs_minute() / 1440). Ay ayı: kış gündönümünden (doy 354) sonraki ikinci yeni
## ay 1. aydır. Toplantılar (K56): Kış Toplantısı 1. ayın yeni ayı, Lung-çeng 5. ayın dolunayı, Dailin 8. ayın dolunayı; gün, o anın
## düştüğü takvim günüdür. Akın penceresi (K55): moon_illum(day_n + 0,5) ≥ 0,97. Prototipin calendar.js'iyle aynı hesap
## (tests/fixtures/time_core.json); toplantı günleri prototipte yoktur, beklenen değerleri time.md §17'dendir.
## Godot'nun Time tekili kullanılmaz.

const DAY1_YEAR_BC := 212
const DAY1_DOY := 25
const YEAR_DAYS := 365
const DAY_MIN := 1440.0
const MONTH_DAYS: Array[int] = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
const MONTHS_TR: Array[String] = ["Ocak", "Şubat", "Mart", "Nisan", "Mayıs", "Haziran", "Temmuz", "Ağustos", "Eylül", "Ekim", "Kasım", "Aralık"]
const MONTHS_EN: Array[String] = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
## Mevsimlerin doy aralıkları (time.md §2; kış yılı sarar).
const SEASONS := [[&"winter", 319, 73], [&"spring", 74, 133], [&"summer", 134, 233], [&"autumn", 234, 318]]
const SEASON_NAMES := {
	&"winter": ["Kış", "Winter"], &"spring": ["Bahar", "Spring"], &"summer": ["Yaz", "Summer"], &"autumn": ["Güz", "Autumn"],
}
## Sinodik ay (gün) ve dolunayın anı (mutlak gün: Gün IV 18:00).
const SYNODIC := 29.530588
const MOON_EPOCH := 1044.75
## Kış gündönümü (doy; ay ayının başlangıcı ondan sonraki ikinci yeni aydır).
const SOLSTICE_DOY := 354
## Perde başları (K25, K42; time.md §2).
const ACT_START := {1: 1041, 2: 1222, 3: 1679, 4: 2682, 5: 4314, 6: 5237}
## Ev (home) ve Serbest Gez'in açılış günü: 11 Nisan MÖ 209 (K7, K67).
const HOME_DAY := 1171
## Akın penceresinin aydınlık eşiği (K55).
const RAID_ILLUM := 0.97
## Dailin, Lung-çeng ve Kış Toplantısı'nın ay ayları (K56).
const DAILIN_MONTH := 8
const LONGCHENG_MONTH := 5
const WINTER_MEET_MONTH := 1


## MÖ yılı.
static func year_bc(day_n: int) -> int:
	return DAY1_YEAR_BC - floori(float(day_n + DAY1_DOY - 1) / YEAR_DAYS)


## Yılın günü (0 = 1 Ocak).
static func doy(day_n: int) -> int:
	return posmod(day_n + DAY1_DOY - 1, YEAR_DAYS)


## Yılın günü → Vector2i(ay 1..12, gün 1..31).
static func month_day(p_doy: int) -> Vector2i:
	var left := posmod(p_doy, YEAR_DAYS)
	for i in MONTH_DAYS.size():
		if left < MONTH_DAYS[i]:
			return Vector2i(i + 1, left + 1)
		left -= MONTH_DAYS[i]
	return Vector2i(12, 31)


## Gün, ay (1..12), MÖ yıl → day_n.
static func day_n_of(day: int, month: int, p_year_bc: int) -> int:
	var d := day - 1
	for i in clampi(month - 1, 0, 11):
		d += MONTH_DAYS[i]
	return (DAY1_YEAR_BC - p_year_bc) * YEAR_DAYS + d - (DAY1_DOY - 1)


## «22 Eylül MÖ 228».
static func format_tr(day_n: int) -> String:
	var md := month_day(doy(day_n))
	return "%d %s MÖ %d" % [md.y, MONTHS_TR[md.x - 1], year_bc(day_n)]


## «22 September 228 BC».
static func format_en(day_n: int) -> String:
	var md := month_day(doy(day_n))
	return "%d %s %d BC" % [md.y, MONTHS_EN[md.x - 1], year_bc(day_n)]


## Dile göre tarih (lang "en" ya da öteki: tr).
static func format(day_n: int, lang: String = "tr") -> String:
	return format_en(day_n) if lang == "en" else format_tr(day_n)


## Tarih ve rehinenin sayımı (time.md §11 tarih kartı, II–VI): «8 Haziran MÖ 209 · 1.229. gün» / «8 June 209 BC · Day 1,229».
static func format_count(day_n: int, lang: String = "tr") -> String:
	if lang == "en":
		return "%s · Day %s" % [format_en(day_n), group_digits(day_n, ",")]
	return "%s · %s. gün" % [format_tr(day_n), group_digits(day_n, ".")]


## Tam sayıyı binlik ayraçla yazar (1229 → «1.229»; eksi sayıda işaret önde).
static func group_digits(n: int, sep: String) -> String:
	var digits := str(absi(n))
	var out := ""
	while digits.length() > 3:
		out = sep + digits.right(3) + out
		digits = digits.left(digits.length() - 3)
	return ("-" if n < 0 else "") + digits + out


## Mevsim: winter, spring, summer, autumn.
static func season(day_n: int) -> StringName:
	return season_of_doy(doy(day_n))


## Yılın gününün mevsimi.
static func season_of_doy(p_doy: int) -> StringName:
	for row: Array in SEASONS:
		var from := int(row[1])
		var to := int(row[2])
		if (from <= to and p_doy >= from and p_doy <= to) or (from > to and (p_doy >= from or p_doy <= to)):
			return row[0]
	return &"winter"


## Mevsimin adı (lang "en" ya da tr).
static func season_name(p_season: StringName, lang: String = "tr") -> String:
	var names: Array = SEASON_NAMES.get(p_season, ["", ""])
	return str(names[1] if lang == "en" else names[0])


## Mevsim ve yıl (time.md §6.3 tarih kapısı: oyuncu günü geçtiyse sahne yılı ve mevsimi söyler): «Güz, MÖ 208» / «Autumn, 208 BC».
static func format_season_year(day_n: int, lang: String = "tr") -> String:
	var name := season_name(season(day_n), lang)
	return "%s, %d BC" % [name, year_bc(day_n)] if lang == "en" else "%s, MÖ %d" % [name, year_bc(day_n)]


## O günden sonra mevsimin ilk kez s mevsimine döndüğü gün (bugün o mevsimse bugün). Serbest Gez'in görünüş sınaması okur.
static func next_season_day(day_n: int, p_season: StringName) -> int:
	for k in YEAR_DAYS + 1:
		if season(day_n + k) == p_season:
			return day_n + k
	return day_n


## Perdenin başlangıç günü (K25, K42): 1 → 1.041 … 6 → 5.237; bilinmeyen perde 0.
static func act_start(act: int) -> int:
	return int(ACT_START.get(act, 0))


# --- Ay (time.md §2) -----------------------------------------------------------------------------------------------

## Mutlak günün (kesirli: day_n + dakika/1440) ayı: yaş (gün, 0 yeni ay, 14,765 dolunay).
static func moon_age_days(t: float, epoch: float = MOON_EPOCH) -> float:
	return fposmod(t - epoch + SYNODIC / 2.0, SYNODIC)


## Mutlak dakikanın (GameClock.abs_minute) ay yaşı.
static func moon_age(abs_minute: float, epoch: float = MOON_EPOCH) -> float:
	return moon_age_days(abs_minute / DAY_MIN, epoch)


## Mutlak dakikanın ay aydınlığı (0 yeni ay, 1 dolunay). Bulut ay olayını değiştirmez (K22): dolunay takvimdir.
static func moon_illum(abs_minute: float, epoch: float = MOON_EPOCH) -> float:
	return (1.0 - cos(TAU * moon_age(abs_minute, epoch) / SYNODIC)) / 2.0


## Ay büyüyor mu (yaş dolunaydan önce)?
static func moon_waxing(abs_minute: float, epoch: float = MOON_EPOCH) -> bool:
	return moon_age(abs_minute, epoch) < SYNODIC / 2.0


## y yılının (MÖ (211 − y) yılına giren kışın) 1. ay ayının başı (mutlak gün, kesirli): gündönümünden sonraki ikinci yeni ay.
## y: prototipin yıl sayacı (day_n = doy − 24 + 365·y).
static func _first_month(y: int, epoch: float) -> float:
	var new_moon := epoch - SYNODIC / 2.0
	var solstice := float(SOLSTICE_DOY - (DAY1_DOY - 1) + YEAR_DAYS * y)
	var k := floori((solstice - new_moon) / SYNODIC) + 1
	return new_moon + float(k + 1) * SYNODIC


## Ay ayı (1..13): kış gündönümünden (doy 354) sonraki ikinci yeni ay 1. ayın başıdır.
static func lunar_month(abs_minute: float, epoch: float = MOON_EPOCH) -> int:
	var t := abs_minute / DAY_MIN
	var y := floori((t - float(SOLSTICE_DOY - (DAY1_DOY - 1))) / YEAR_DAYS)
	var start := _first_month(y, epoch)
	while start > t:
		y -= 1
		start = _first_month(y, epoch)
	var after := _first_month(y + 1, epoch)
	while after <= t:
		start = after
		y += 1
		after = _first_month(y + 1, epoch)
	return floori((t - start) / SYNODIC) + 1


## MÖ yılın month. ay ayının başı (yeni ayın anı; mutlak gün, kesirli). 1. ay o yılın şubatı dolayıdır.
static func month_start(p_year_bc: int, month: int, epoch: float = MOON_EPOCH) -> float:
	return _first_month(211 - p_year_bc, epoch) + float(month - 1) * SYNODIC


## MÖ yılın month. ay ayının dolunayının anı (mutlak gün, kesirli).
static func full_moon_of(p_year_bc: int, month: int, epoch: float = MOON_EPOCH) -> float:
	return month_start(p_year_bc, month, epoch) + SYNODIC / 2.0


## Dailin (K56): 8. ayın dolunayının günü. 234 → −7.785 (doğum), 228 → −5.600, 208 → 1.694, 203 → 3.525, 174 → 14.097.
static func dailin_day(p_year_bc: int) -> int:
	return floori(full_moon_of(p_year_bc, DAILIN_MONTH))


## Lung-çeng (K56): 5. ayın dolunayının günü. 205 → 2.698, 203 → 3.436, 198 → 5.238, 176 → 13.270.
static func longcheng_day(p_year_bc: int) -> int:
	return floori(full_moon_of(p_year_bc, LONGCHENG_MONTH))


## Kış Toplantısı (K56): 1. ayın yeni ayının günü. 208 → 1.472 (6 Şubat 208).
static func winter_meet_day(p_year_bc: int) -> int:
	return floori(month_start(p_year_bc, WINTER_MEET_MONTH))


## Akın penceresi (K55): ordugâh ve yerleşim akını yalnız moon_illum(day_n + 0,5) ≥ 0,97 günlerinde gelir (ayda ≈3 gün).
static func raid_window(day_n: int) -> bool:
	return moon_illum((float(day_n) + 0.5) * DAY_MIN) >= RAID_ILLUM
