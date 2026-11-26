# `audio.md` birleşik deltası ve işleme defteri (K20–K26)

> **Yerini aldı (2026-11-03).** Bu defter ve bağladığı beş alan deltası `d2/audio-delta.md` birleşik deltasına indirildi; `L` yalnız onu işler. Bu dosya iz için kalır.

Kaynak: `d2/core.md` §3.7, `weather.md` §10. Faz 7 bitince `L` işler; Faz 7 sürerken `audio.md` düzenlenmez. Dört alan deltası aynı paragraflara (Bellek, Ortam döngüleri, Hayvan ve dünya, Komşu belgelerin ekleri) ekler; bu defter sırayı ve tek çakışmanın birleşik metnini verir.

## 1. Sıra

1. `d2/time-delta-audio.md` (AU1–AU3; AU4 atlanır, §3 CA1).
2. `d2/weather-delta-audio.md` (1, 2, 3b, 3c, 3d; 3a atlanır, CA1).
3. `d2/labour-delta-audio.md` (U1, U2).
4. `d2/settlement-delta-audio.md` (SU1–SU3; SU4 atlanır, CA1).
5. `d2/economy-delta-audio.md` (A1, A2; A3 atlanır, CA1).
6. Bu dosyanın CA1–CA2 maddeleri.

## 2. Değişiklikler

| Dosya, madde | Durum | Değişiklik |
|---|---|---|
| weather 3b | Değiştirerek | Döngü süreleri ve bellek: `rain_light` 8 sn (0,71 MB), `rain_heavy` 8 sn (0,71 MB), `rain_felt` 6 sn (0,53 MB), `hail_bed` 4 sn (0,35 MB), `wind_gale` 10 sn (0,88 MB), `dust_storm` 10 sn (0,88 MB); `far_rain` işareti `rain_light`'ın alçak geçiren (900 Hz) uzak 3B çalınışıdır, yeni pişirme yoktur |
| weather 3d | Değiştirerek | Hava efektleri reçetede `sr: AMB_RATE` (22,05 kHz) taşır (motorun varsayılanı 32 kHz) |
| weather 1 | Değiştirerek | Kar öncesi işaret: `gust` 20–30 sn'de bir (`gust_rise`, ayrı reçete yok) |

## 3. Birleşik maddeler

### CA1. §4 «Bellek» paragrafı

**Bul:** `**Bellek.** Ortam döngüleri 22 kHz mono.`
**Yerine:**
```
**Bellek.** Ortam döngüleri 22 kHz mono. Saat ekleri (`meal_call`, `night_drum`, `wait_lapse`, `wake`; K20) toplam ≤0,5 MB. Hava döngüleri ve efektleri (K22) yükleyicide değil, plan bir cephe gösterince pişer (en az 1 oyun saati = 150 sn önce, dilimli, kare başına ≤4 ms); cephe geçtikten 1 oyun saati sonra bırakılır. Kampta yerleşik hava sesi en çok 3,2 MB döngü + 2,5 MB efekt (hepsi 22,05 kHz); Kışlak'ta `wind_gale` 0,88 MB. Kampın efekt ve ortam önbelleği fırtınalı akşamda ≈15,2 MB, 16 MB pişirme tavanının (`sfx.js` `BAKE_BUDGET`) altında (`weather.md` §10.1, W19 ölçer). Yerleşim ekleri (K23: dört döngü, sekiz efekt) yalnız yerleşim ve ordugâh dünyalarında ön üretilir, ≈0,9 MB. Ekonomi döngüleri (`felt_roll`, `bellows`, `tan_scrape`; K24) yalnız yerleşim ve ordugâh dünyalarında ön üretilir; Kışlak'ta yalnız `anvil` ve `bellows` (Kujul'un körüğü).
```

(Not: economy A3 «paragrafın sonuna (`… kare başına ≤4 ms.` sözcüklerinden sonra)» der; bugünkü paragraf o sözcüklerle bitmiyorsa ekonominin cümlesi yukarıdaki son cümledir, ayrıca eklenmez.)

### CA2. §3 Müzik durumları: saat ve hava

time AU2'nin eklediği «**Saate bağlı durum (K20).**» paragrafından sonra weather 2'nin «**Yağmur katmanı.**» paragrafı gelir; settlement SU1'in dört satırı time AU1'in `camp_night` satırından ve `road_leg` satırından sonra eklenir. Yakın gök gürültüsü müziği 2 sn −3 dB indirir (weather 2) ve bu yalnız ortam durumlarında geçerlidir; hikâye müziklerine (`chase`, `raid`, `erlik`, `tengri`, `tension`) hava dokunmaz.
