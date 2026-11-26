# `audio.md` değişiklikleri: Yerleşim, ordugâh ve hanlık (K23)

> **Yerini aldı, işlenmez (2026-11-03, K26).** `audio.md` yalnız `d2/audio-delta.md` birleşik defteriyle işlenir; bu dosyanın maddeleri oraya, sayıları `d2/core.md`'ye göre düzeltilerek indirildi. Dosya iz için kalır; `L` onu ikinci kez işlemez (çapalar ikinci geçişte tutmaz).

Kaynak: `d2/settlement.md` §12, §14. Faz 7 bitince `L` işler. Hepsi kodla sentezdir (Vibi yalnız konuşma), 22 kHz mono, yalnız yerleşim ve ordugâh dünyalarında dilimli ön üretim; hazır ses ≤40 MB tavanı içinde ≈0,9 MB. Tezgâh sesleri K24'ündür (`d2/economy-delta-audio.md`: `felt_roll`, `bellows`, `anvil`, `adze`, `tan_scrape`, `shear_snip`, `milk_pail`, `store_open`, `cart_unload`), şantiye sesleri K21'in (`torch_post`); bu dosya onları tekrarlamaz. Biçim: **Yer**, **Bul**, **Sonrasına ekle**.

## SU1. §3 Müzik durumları, tablo

**Yer:** K20 ekinin (`d2/time-delta-audio.md` AU1) eklediği satırlardan sonra, `| \`road_leg\` | …` satırının altı.
**Ekle:**
```
| `hold` | Yerleşim ve ordugâh, Tan'dan Akşam'a (K20 evresi) | 72 | Çekilen dombra ve uzak kobuz, hafif çerçeve davul ikinci zamanda; D Dorian; A G F D motifi kademe yükselişinde bir kez tam |
| `hold_night` | Yerleşim ve ordugâh, Gece | 56 | Dron, seyrek tel, kaval; davul yok |
| `court` | Toplantılar ve Toy (Kış Toplantısı, Dailin Sayımı, Toy Ver) | 96 | Major pentatonik: davul ve tüngür birlikte, boğaz dronu, koro uzakta; sevinç kipi (§3 kuralı) |
| `muster` | Ordugâhta talim ve toplantı | 108 | Tüngür ve çerçeve davul, kısa kopuz cümleleri, `whistling_arrow` sesinin perdesinde (2,4 kHz) tek kobuz notası |
```

## SU2. §4 Ortam ve efekt reçeteleri, ortam döngüleri

**Bul:** `` - **Ortam döngüleri:** `wind_steppe`, `wind_winter`, `blizzard`, `fire_loop`, `night_meadow` (cırcır), `birds_day`, `camp_day` (uzak uğultu, keçi, çekiç), `yurt_inside`, `ice_groan`, `water_reed`. ``
**Sonrasına ekle (K20 ve K22 eklerinden sonra):**
```
- **Yerleşim döngüleri (K23, `settlement.md`):** `hold_day` (yerleşimin gündüzü: sözsüz uzak konuşma uğultusu, bant 300–1.200 Hz, 0,3 Hz kabarma; seyrek köpek ve keçi; kazan kenarı tıkı; hane sayısıyla kazanç `0,25 + 0,5 × min(1, hane / 45)`), `herd_flock` (sürü: koyun ve keçi meleme kümesi, 4–9 sn'de bir, ±%8 perde; toynak hışırtısı; sürü kadrajdaysa 3B, sürünün merkezinden, erim 60 m), `camp_army` (ordugâh: at kişnemesi ve horlama 10–20 sn'de bir, uzak `anvil` 30 sn'de bir, alçak erkek uğultusu 150–500 Hz; yerleşik atlıyla kazanç), `gathering_crowd` (Toy ve toplantı: yoğun uğultu, kahkaha yerine nefesli coşku darbeleri, uzak `drum_hit` 2 sn'de bir; yalnız `court` müziği çalarken). Gece `hold_day` ve `camp_army` ×0,3, `herd_flock` ×0,5 (K20 evresi).
```

## SU3. §4, «Hayvan ve dünya» maddesinin altı

**Bul:** `` - **Hayvan ve dünya:** `wolf_howl`, `eagle_cry`, `crow`, `dog_bark`, `sheep`, `thunder`, `ice_crack`, `heartbeat`, `alarm_horn`, `drum_hit`, `bone_hum` (Yol Kemiği uğultusu: gürültü + bant geçiren, rüzgâra bağlı, 3B), `mene_hum` (Mene'nin falsolu mırıltısı). ``
**Sonrasına ekle (K20 ekinden sonra):**
```
- **Yerleşim ekleri (K23):** `plan_place` (Plan Kipi'nde yerleştirme: kazık vuruşu `hammer_wood` ×0,8 + kısa ip gerilmesi, bant 900 Hz, 120 ms; −14 dB), `plan_rotate` (döndürme: ince tahta tık, `ui_hover` ×0,6, 15°'de bir), `household_arrive` (hane kapıdan girer: uzak `hoof_walk` dörtlüsü + iki melemeli `sheep` + kısa karşılama boru notası, `alarm_horn`'un yumuşatılmışı, alçak geçiren 800 Hz, −20 dB, 3B kapıdan), `caravan_depart` (kervan kalkışı: `cart_loop` 2 sn kabarma, `horse_snort`; 3B ambardan), `tier_up` (kademe kartı: tunç gong 110 Hz FM + dombra A G F D, `level_up`'tan ayrı: gong önce, 1,2 sn sonra dombra; −12 dB), `dawn_bow` (Şafak Selamı: boğaz dronu D2 4 sn kabarıp söner + tek kaval D5, 1,5 sn; yalnız Gök Direği'nde), `omen_strike` (alamet: yakın `thunder` + `fire_catch` + 0,8 sn sessizlik + `bone_hum` perdesinde tek uzun ton; perde başına bir kez), `assembly_drum` (toplantı çağrısı: tüngür üçlüsü, 8 sn arayla iki kez, Toy Alanı'ndan 3B, erim 300 m).
```

## SU4. §4 Bellek paragrafı

**Bul:** `**Bellek.** Ortam döngüleri 22 kHz mono.`
**Sonuna ekle (K20 ve K24 eklerinden sonra):** ` K23 ekleri (dört döngü, sekiz efekt) yalnız yerleşim ve ordugâh dünyalarında ön üretilir, ≈0,9 MB.`
