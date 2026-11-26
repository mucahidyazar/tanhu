class_name DuckTable
extends RefCounted
## Konuşmada müzik ve ortam kısması (K78; audio.md §1 «Konuşmada kısma», godot.md §3.3): saf tablo ve zarf.
##
## Kısma o an çalan müzik durumunun türüne göredir; kimlikler audio.md §3'ün 22 durumudur. Ana söz (A ve B
## dilimi) `Music` ve `Ambience` yollarının başındaki `AudioEffectAmplify` ile kesin kısılır: iniş satırdan
## PREROLL önce başlar, ATTACK'te hedefe varır; satır bitince RELEASE'te 0 dB'e döner. Konuşma boyunca
## `Music` yolundaki EQ10'un EQ_BAND bandı (2 kHz) EQ_DB iner. AudioManager bu sayıları uygular; tablo
## sahnesizdir ve sınanır (tests/unit/test_voice_bus.gd).
##   DuckTable.levels(&"raid")             # Vector2(-9, -6): müzik ve ortam dB
##   DuckTable.envelope(t, start, end)     # 0..1: kısmanın derinliği (1 = hedefte)

## Durum türleri (K78).
const NARRATIVE := &"narrative"     ## Anlatı ve sinema
const EVERYDAY := &"everyday"       ## Gündelik
const TENSION := &"tension"         ## Gerilim ve toplanma
const RAID := &"raid"               ## Baskın ve kovalamaca

## Türün kısması: Vector2(müzik dB, ortam dB).
const LEVELS := {
	NARRATIVE: Vector2(-3.0, -3.0),
	EVERYDAY: Vector2(-6.0, -3.0),
	TENSION: Vector2(-6.0, -6.0),
	RAID: Vector2(-9.0, -6.0),
}

## audio.md §3'ün 22 müzik durumu → tür.
const STATES := {
	&"narration": NARRATIVE, &"myth": NARRATIVE, &"camp_bard": NARRATIVE, &"tengri": NARRATIVE,
	&"erlik": NARRATIVE, &"dawn": NARRATIVE, &"home": NARRATIVE, &"creator": NARRATIVE,
	&"camp": EVERYDAY, &"camp_night": EVERYDAY, &"hold": EVERYDAY, &"hold_night": EVERYDAY,
	&"winter_day": EVERYDAY, &"winter_evening": EVERYDAY, &"winter_night": EVERYDAY,
	&"road_leg": EVERYDAY, &"childhood": EVERYDAY,
	&"tension": TENSION, &"muster": TENSION, &"court": TENSION,
	&"raid": RAID, &"chase": RAID,
}

## Bilinmeyen ya da boş durumun türü: menü ve Serbest Gez `camp`'tır (audio.md §3), bugünkü menü müziği de onun yerine çalar.
const DEFAULT_STATE := &"camp"

## Zaman (saniye): iniş satırdan PREROLL önce başlar, ATTACK'te hedefe varır, satır bitince RELEASE'te döner.
const PREROLL := 0.15
const ATTACK := 0.3
const RELEASE := 1.0

## Anlaşılırlık: konuşma boyunca Music yolunda EQ10'un 2 kHz bandı (31, 62, 125, 250, 500, 1k, 2k … sırasında 6.) −3 dB.
const EQ_BAND := 6
const EQ_DB := -3.0

## Erlik zinciri (audio.md §2 «Mit sineması»): satır −3 dB, Voice yolunun EQ10'unda 800 Hz altı (31–500 Hz, 0–4. bantlar) +2 dB.
const ERLIK_LINE_DB := -3.0
const ERLIK_LOW_BANDS := 5
const ERLIK_LOW_DB := 2.0


## Durumun türü (bilinmeyen ya da boş durumda DEFAULT_STATE'inki).
static func kind_of(state: StringName) -> StringName:
	return STATES.get(state, STATES[DEFAULT_STATE])


## Durumun kısması: Vector2(müzik dB, ortam dB).
static func levels(state: StringName) -> Vector2:
	return LEVELS[kind_of(state)]


## Türdeki durumlar (tabloyla aynı sırada).
static func states_of(kind: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for state: StringName in STATES:
		if STATES[state] == kind:
			out.append(state)
	return out


## Kısmanın derinliği (0 = kısma yok, 1 = hedefte), t anında; satır start'ta başlar, end'de biter (saniye).
## İniş start − PREROLL'da başlar ve doğrusal olarak ATTACK'te 1'e varır; satır bitince o anki derinlikten
## RELEASE'te 0'a iner. Satır inişten kısaysa dönüş o anki derinlikten başlar.
static func envelope(t: float, start: float, end: float) -> float:
	var a0 := start - PREROLL
	var at_end := clampf((end - a0) / ATTACK, 0.0, 1.0)
	if t <= a0:
		return 0.0
	if t <= end:
		return clampf((t - a0) / ATTACK, 0.0, 1.0)
	return at_end * clampf(1.0 - (t - end) / RELEASE, 0.0, 1.0)
