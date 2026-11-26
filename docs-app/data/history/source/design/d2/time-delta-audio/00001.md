# `audio.md` değişiklikleri: Zaman ve Takvim (K20)

> **Yerini aldı, işlenmez (2026-11-03, K26).** `audio.md` yalnız `d2/audio-delta.md` birleşik defteriyle işlenir; bu dosyanın maddeleri oraya, sayıları `d2/core.md`'ye göre düzeltilerek indirildi. Dosya iz için kalır; `L` onu ikinci kez işlemez (çapalar ikinci geçişte tutmaz).

Kaynak: `d2/time.md` §7.2, §8.5, §9.2. Faz 7 bitince işlenir. Hava sesleri (yağmur, gök gürültüsü, dolu, tipi) K22'nin delta dosyasındadır; bu dosya yalnız günün saatine bağlı sesi verir. Her madde bölüm başlığı, birebir bulunacak metin ve yeni metinle verilir.

## AU1. §3 Müzik durumları, tablo

**Bul:** `| `camp` | Menü, Serbest Gez | Noktalı dörtlük 52 | Dron + boğaz çok hafif, **hafif dombra** (Serbest Gez'de ozanın konumundan), ara sıra kobuz cümlesi, rüzgâr ortamı |`
**Yerine:** `| `camp` | Menü; Serbest Gez Tan'dan Akşam'a | Noktalı dörtlük 52 | Dron + boğaz çok hafif, **hafif dombra** (Serbest Gez'de ozanın konumundan, yalnız ozan ateş başındayken: 09:00–22:30), ara sıra kobuz cümlesi, rüzgâr ortamı |`

**Sonrasına ekle (yeni satır):**
```
| `camp_night` | Serbest Gez, Gece evresi | 46 | Dron, ozan ateşteyken (22:30'a dek) seyrek dombra ozanın konumundan; sonra yalnız dron ve 40–70 sn'de bir kısa kaval cümlesi. A G F D motifi gecede bir kez |
```

**Bul:** `| `winter_day` | Act 1 gündüz | 84 | Çekilen kopuz, hafif çerçeve davul, seyrek kobuz |`
**Yerine:** `| `winter_day` | Act 1, Sabah, Öğle, İkindi | 84 | Çekilen kopuz, hafif çerçeve davul, seyrek kobuz |`

**Bul:** `| `winter_evening` | Act 1 akşam, kazan başı | 66 | Kaval + dron, kamp sesleri |`
**Yerine:** `| `winter_evening` | Act 1, Tan; Akşam ve Gece'nin 22:30'a dek olanı (kazan başı, ateşler) | 66 | Kaval + dron, kamp sesleri |`

**Bul:** `| `winter_night` | Act 1 gece | 60 | Alçak dron, seyrek tel, nefesli kaval |`
**Yerine:** `| `winter_night` | Act 1, 22:30'dan Tan'a | 60 | Alçak dron, seyrek tel, nefesli kaval |`

## AU2. §3 Müzik durumları, tablonun altı

**Bul:** `Geçişler katman kazançlarıyla 2–4 sn; durum değişince aynı ölçü sınırında girilir.`
**Sonrasına ekle:**
```
**Saate bağlı durum (K20).** Kamp ve Kışlak'ın gündelik müziği `clock:phase` ve saatle seçilir; sahne ve görev durumu (`tension`, `raid`, `erlik`, `chase` …) her zaman önce gelir. Bekleme ve uyku atlamasında müzik durumu varış saatine göre seçilir, geçiş karartma içinde biter. Menü `camp`'tır, saati okumaz.
```

## AU3. §4 Ortam ve efekt reçeteleri

**Bul:** `- **Ortam döngüleri:** `wind_steppe`, `wind_winter`, `blizzard`, `fire_loop`, `night_meadow` (cırcır), `birds_day`, `camp_day` (uzak uğultu, keçi, çekiç), `yurt_inside`, `ice_groan`, `water_reed`.`
**Sonrasına ekle:**
```
- **Ortamın saati (K20, `app/sounds.js`).** Serbest Gez'de kazançlar evreyle 8 sn'de süzülür: Tan `birds_day` 0,5, `wind_steppe` 0,35, `fire_loop` 0,6; Sabah `birds_day` 0,35, `camp_day` 0,35, `wind_steppe` 0,55; Öğle ve İkindi `camp_day` 0,35, `wind_steppe` 0,7; Akşam `camp_day` 0,2 → `night_meadow` 0,3, `wind_steppe` 0,45, `fire_loop` 1; Gece `night_meadow` 0,45, `wind_steppe` 0,3, `fire_loop` 1 (22:30'dan 0,5). Bugünkü `moodTarget > 0,75` eşiği kalkar. Kışlak'ta `wind_winter` gündüz 0,6, gece 0,45; `ice_groan` Tan ve Gece'de; köpek havlaması (`dog_bark`) 22:30'dan sonra seyrekleşir. Gece 23:00'ten sonra uzak `wolf_howl` 6–10 dk'da bir (ana kamp ve Ak Otlak).
```

**Bul:** `- **Hayvan ve dünya:** `wolf_howl`, `eagle_cry`, `crow`, `dog_bark`, `sheep`, `thunder`, `ice_crack`, `heartbeat`, `alarm_horn`, `drum_hit`, `bone_hum` (Yol Kemiği uğultusu: gürültü + bant geçiren, rüzgâra bağlı, 3B), `mene_hum` (Mene'nin falsolu mırıltısı).`
**Sonrasına ekle:**
```
- **Saat ekleri (K20):** `meal_call` (Mutfak Kazanı'nın kenarına vurulan tunç: FM, 180 Hz taban, iki uyumsuz kısmi, 2,5 sn kuyruk; öğle çanı 12:00 ve akşam aşı 17:30, 3B kazandan), `night_drum` (gece davulu: üç ağır `drum_hit`, 1,5 oyun saatinde bir, Nöbet Yurdu'ndan, 3B), `wait_lapse` (arayüz: 1,8 sn yumuşak rüzgâr kabarması, bekleme akışı), `wake` (arayüz: soluk ve köz çıtırtısı, uyanış).
```

## AU4. §4 Bellek satırı

**Bul:** `**Bellek.** Ortam döngüleri 22 kHz mono.`
**Yerine:** `**Bellek.** Ortam döngüleri 22 kHz mono; K20 ekleri (`meal_call`, `night_drum`, `wait_lapse`, `wake`) toplam ≤0,5 MB.`
