# `architecture.md` için hava deltası (K22)

> **Yerini aldı, işlenmez (2026-11-03, K26).** `architecture.md` yalnız `d2/architecture-delta.md` birleşik defteriyle işlenir; bu dosyanın maddeleri oraya, sayıları `d2/core.md`'ye göre düzeltilerek indirildi. Dosya iz için kalır; `L` onu ikinci kez işlemez (çapalar ikinci geçişte tutmaz).

Kaynak: `docs/design/d2/weather.md`. Faz 7 bitince baş mühendis (`L`) uygular; Faz 7 sırasında `architecture.md` düzenlenmez. Her madde: bölüm ve başlık, yer (bulunacak metin), yapılacak iş, yeni metnin tamamı. Satır numarası verilmez, metin çapası kullanılır (belge Faz 7'de değişiyor). Sayılar `weather.md`'den gelir; çelişirse `weather.md` kazanır.

## 1. §1 Hedef klasör ağacı

**1a.** `src/i18n/` altında, şu satırdan sonra:

```
  strings/quests.js                →10.7 Görevler ekranı çerçeve metinleri
```

ekle:

```
  strings/weather.js               →8.9 Hava türleri, işaretler, kişi satırları, kilit ve ret satırları
```

**1b.** `src/audio/` altında, şu satırdan sonra:

```
  sfx/ui.js, foot.js, weapon.js, structure.js, gather.js, horse.js, world.js, travel.js  →3.7 Reçeteler, alan başına
```

ekle:

```
  sfx/weather.js                   →9.8 Yakın ve uzak gök gürültüsü, uyarı vızıltısı, bora, damla, dolu tıkırtısı, sağırlık
```

**1c.** `src/data/` altında, şu satırdan sonra:

```
  enemies.js                       →8.8 Düşman tablosu
```

ekle:

```
  weather-types.js                 →8.9 Hava türü vektörleri ve etki sayıları
  climates.js                      →8.9 İklim payları, gün içi eğriler, hâkim rüzgâr, dünya → iklim
```

**1d.** `src/game/` altında, şu satırdan sonra:

```
  calendar.js                      →10.1 Perde, gün, dilim, İş Puanı (saf)
```

ekle:

```
  weather-core.js                  →8.9 Planlayıcı, ayar, ıslaklık, etki, yıldırım seçimi (saf)
  weather.js                       →8.9 WeatherSystem: saat, kilit, işaret, alt olay, fx, ses verisi
```

**1e.** `src/world/` altında şu satırı:

```
  weather.js                       →9.4 Kar noktaları, Tipi sisi
```

şununla değiştir:

```
  weather.js                       →9.4 WeatherView: yağış ve sıçrama noktaları, yıldırım şeridi; ışık, sis, kubbe, rüzgâr ve post bileşimi
  weather-hooks.js                 →9.4 Hava GLSL dizgeleri: ekran yağışı, ıslaklık, bulut örtüsü, kubbe (saf, yalnız dizge)
```

**1f.** `src/ui/` altında, şu satırdan sonra:

```
  hud/trust.js, axes.js, clock.js, squad-bar.js  →10.7 Çentik, Kut ve Korku, dilim ve Ay Saati, birlik
```

ekle:

```
  hud/weather.js                   →9.8 Hava simgesi, işaret satırı, gök okuma
```

ve şu satırdan sonra:

```
  css/journal.css                  →10.7
```

ekle:

```
  css/weather.css                  →9.8
```

**1g.** `src/core/` altında şu satırı:

```
  paint-material.js              E →1.5 Program anahtarına kanca karması
```

şununla değiştir:

```
  paint-material.js              E →1.5 Program anahtarına kanca karması; 9.4 hava uniform'ları (uWet, uWetFx, uCloudPhase, uFront, uWindK, uWindPhase)
```

## 2. §3.4 Ayarlar

Tabloda `a11y.reduceMotion` satırını:

```
| `a11y.reduceMotion` | false | | travel Akış, atlas nabzı, kamera sarsıntısı |
```

şununla değiştir ve altına yeni satır ekle:

```
| `a11y.reduceMotion` | false | | travel Akış, atlas nabzı, kamera sarsıntısı (yakın yıldırım dahil); ekran yağışı 3 → 1 katman |
| `a11y.flashes` | `full` | `full`, `soft`, `off` | world/weather: şimşek nabzı (`d2/weather.md` §9.6); `soft` ×0,35, tek vuruş, ≤2,5 parlama/sn |
```

## 3. §3.5 Kayıt

**3a.** Blok tablosunda şu satırdan sonra:

```
| `world.npcs` | 74 | `game/npcs.js` | |
```

ekle:

```
| `world.weather` | 75 | `game/weather.js` | ≤1 KB: tohum, plan (≤10 bölüm), ıslaklık, kilitler, yıldırım beklemesi (`d2/weather.md` §12.7) |
```

**3b.** Şu metni:

```
**Serbest Gez** ayrı bloktur: `{ schema:1, camp3, camp:{structures}, child:{pos,yaw,weapon,sit?}, mood, flags, playTime }`
```

şununla değiştir:

```
**Serbest Gez** ayrı bloktur: `{ schema:1, camp3, camp:{structures}, child:{pos,yaw,weapon,sit?}, mood, flags, playTime, weather }` (`weather` yolculuk bloğuyla aynı biçim, `d2/weather.md` §12.7)
```

## 4. §3.6 Ses motoru

**4a.** `audio/ambience.js` kod bloğunda şu yorumu:

```
// id: wind_steppe, wind_winter, blizzard, fire_loop, night_meadow, birds_day, camp_day, yurt_inside, ice_groan, water_reed; hepsi 22 kHz mono
```

şununla değiştir:

```
// id: wind_steppe, wind_winter, blizzard, fire_loop, night_meadow, birds_day, camp_day, yurt_inside, ice_groan, water_reed,
//     rain_light, rain_heavy, rain_felt, hail_bed, wind_gale, dust_storm (hava; yalnız planda cephe varken pişer); hepsi 22 kHz mono
```

**4b.** Efekt dosyası tablosunda şu satırdan sonra:

```
| `sfx/travel.js` | `cart_loop`, `travel_start`, `travel_arrive`, `post_knock`, `wheel_snow` |
```

ekle:

```
| `sfx/weather.js` | `thunder_crack`, `thunder_far`, `static_hum`, `gust`, `rain_drip`, `hail_tick`, `tinnitus` (`d2/weather.md` §10.2) |
```

**4c.** «**Efekt kimlikleri** `audio.md` §4'tür; ek:» paragrafının sonuna ekle:

```
 Hava: `thunder_crack`, `thunder_far`, `static_hum`, `gust`, `rain_drip`, `hail_tick`, `tinnitus` (`d2/weather.md` §10.2); `thunder` (`sfx/world.js`) orta uzaklıktır.
```

**4d.** «Faz 3 ekleri» listesinde **Oyun sesi** maddesinin sonuna ekle:

```
 **Hava (K22).** `SoundSystem` havanın döngü listesini kendisi kurmaz, `ctx.weather.audio`'yu okur: `{ beds, windK, windSwap, quiet, inside }`. Taban listede rüzgâr döngüsü × `windK` (`windSwap` ise `wind_gale`'e geçer), öteki döngüler × `quiet`, sonra `beds` eklenir; yurt içinde yağmur `rain_felt`'e döner, rüzgâr ×0,4. `ambience.set` yalnız kimlik listesi değişince ya da bir kazanç 0,05'ten çok oynayınca çağrılır, en çok 4 Hz. Menü, `newgame`, `creator` listesi havasızdır. Kış dünyasının ses sahibi (Faz 9) aynı birleşimi yapar (`d2/weather.md` §10.4).
```

**4e.** **Müzik** maddesindeki şu cümleyi:

```
`rain` katmanı `setLayer('rain', g)` çağrılana dek sessizdir.
```

şununla değiştir:

```
`rain` katmanı (çan damlaları) `setLayer('rain', g)` çağrılana dek sessizdir; çağıran `ctx.weather`'dır, yalnız ortam durumlarında (`camp`, `winter_day`, `winter_evening`, `winter_night`, `home`, `road_leg`): çisenti 0,35, yağmur 0,2, kar 0,15, yağmur sonrası 0,45 (`d2/weather.md` §10.3).
```

## 5. §3.7 Sistemler

Sistem tablosunda şu satırdan sonra:

```
| 20 | `calendar` | `game/calendar.js` | play |
```

ekle:

```
| 22 | `weather` | `game/weather.js` | ikisi |
```

Tablonun altındaki paragrafın sonuna ekle:

```
`weather` saatten sonra, okuyucularından (`campfire`, `structures`, `stealth`, `travel`, `nodes`, `sound`) önce çalışır: hepsi aynı karenin `ctx.weather.fx`'ini okur (`d2/weather.md` §12.5). `home`'da çalışmaz: hava kimliktir.
```

## 6. §3.8 WorldSpec, Terrain, World

**6a.** `world/specs/camp.js` örneğinde şu satırdan sonra:

```
  audio: { music: 'camp', ambience: [{ id: 'wind_steppe', gain: 0.8 }, { id: 'fire_loop', gain: 0.5, at: [0, 1, 0] }] },
```

ekle:

```
  weather: { climate: 'orkhon', season: 'camp_spring', exclude: [], accumulate: { snow: false }, snowFelt: 1, dur: { snow: [1, 3] },
             box: [70, 30, 90], points: 6000, splashes: 192, fogZones: [], shelters: null, menu: 'identity' },   // kış: climate 'hexi', season 'winter', exclude ['heavy_snow','blizzard'], snowFelt 0.5
```

**6b.** «**Gök, sis katmanı, göl hattı (Faz 4–5).**» paragrafından sonra yeni paragraf ekle:

```
**Hava (K22, `d2/weather.md` §9).** `world.weather` `WeatherView`'dur (`world/weather.js`): `World.build`'in son adımında, kendi tohumuyla kurulur (kamp RNG akışı değişmez). Üç ağı vardır: yağış noktaları ve sıçrama noktaları (`weather_pts`, tek program, iki örnek) ve yıldırım şeridi (`weather_bolt`); üçü de yükleyici derlemesinde görünür yapılır, sonra gizlenir. `applyMood(t)` iki parçaya ayrılır: `computeBase(t)` ışık düzeni tabanını `world.lightBase`'e (güneş, yarımküre, sis, kubbe anahtarları, göl, köy, kenar ışığı, pozlama) ayırmasız yazar; `writeLight()` taban × havayı üç nesneye ve uniform'lara yazar, karede en çok bir kez, yalnız biri değişince. Hava kimlikse `writeLight` tabanı bugünkü sırayla aynen yazar. Sıra: taban → hava (§3.4 çarpanları, kamera tabanı: yakın ≥0,5 × kamera uzaklığı, uzak ≥ kamera uzaklığı + 50 m) → şimşek nabzı (pozlama × (1 + A·f), yarımküre yoğunluğu ve rengi; ışık eklenmez) → `setFogOverride` kazanır. Hava etkinken göl sis aralığı `LAKE_FOG_R × fogFarK`. `world.weather.identity(fade)` §9.12 kimliğine döner. `world.tallThings` (`[{ id, x, z, h, kind, lone }]`, ≤256) yıldırım adaylarıdır: `flora.js` (kış ormanında 9.4) ve yapı yöneticisi doldurur. `world.shelterAt(x, z)` 0..1 barınak değerini verir (oda, yapı, araba koltuğu, orman kıyısı yarım).
```

## 7. §3.14 Bayrak, koşul, etki, görev

Etki tablosunda şu satırdan sonra:

```
| `cine` | `id` | `cine.play` |
```

ekle:

```
| `weather` | `do, id?, ...` | `ctx.weather`: `lock`, `release`, `progress`, `pin`, `freeze`, `calm`, `flash`, `strike`, `gap` (`d2/weather.md` §6.1); hava sistemi yoksa yok sayılır |
```

## 8. §3.19 Sinema zaman çizelgesi

«Veri biçimi §4.3. **Kurallar.**» paragrafının sonuna ekle:

```
 Satır `weather` (`{ t, weather: { do: 'lock', id, type, blend } }`) hava kilidi açar; `release()` sinemanın açtığı hava kilitlerini de kaldırır (`d2/weather.md` §12.6). Menü ve Yeni Oyun sinemasında hava kimliktir.
```

## 9. §3.21 Son işleme profilleri

Şu paragrafın:

```
`cloudShadow` `U.uCloudInfo.value.z`'ye yazılır (`main.js:108`): `creator` 0, diğerleri 0,34. `tone`, `brightness` `FINAL` gölgelendiricisine eklenir, varsayılanı nötrdür: `menuDiff` etkilenmez.
```

sonrasına yeni paragraf ekle:

```
**Hava katmanı (K22).** `post.weather = { sat, con, tone: [r,g,b], bright, precip: vec4, precipDir: vec4, precipOff: [vec3 ×3], precipCol }`; `render` FINAL uniform'larına profil × katman yazar (`uSat = s.saturation × w.sat` …), birikmez. Kimlik: çarpanlar 1, `precip` 0. FINAL'e ekran yağışı dalı girer (`world/weather-hooks.js` `PRECIP_FINAL`, `d2/weather.md` §9.3): tilt bulanıklığından sonra, doygunluktan önce; `uPrecip` toplamı 0 iken çalışmaz, menü karesi değişmez. `U.uCloudInfo.z` artık her kare `post.settings.cloudShadow × shadowK` olarak `WeatherView` tarafından yazılır (Serbest Gez ve oyunda); menüde profilin değeri aynen kalır. Kara Boran'ın derecesi hikâyenin `applyProfile('blizzard')` çağrısıdır, hava katmanı orada nötrdür.
```

## 10. §5 Uygulama fazları

**10a.** Faz 8 tablosuna, 8.8 satırından sonra ekle:

```
| 8.9 | `src/data/weather-types.js`, `src/data/climates.js`, `src/game/weather-core.js`, `src/game/weather.js`, `src/i18n/strings/weather.js`, `src/game/projectiles.js`, `test/weather-core.test.js`, `test/weather-fx.test.js`, `test/weather-strike.test.js` | `d2/weather.md` §3–§8, §12; planlayıcı, ayar, kilit, işaret, `fx`, yıldırım seçimi, ok sapması | `d2/weather.md` §15 W1–W11 |
```

**10b.** Faz 8'in `L` satırını:

```
`L`: `src/app/systems.js`, `src/app/app.js`: yeni sistemler ve `ctx` alanları.
```

şununla değiştir:

```
`L`: `src/app/systems.js`, `src/app/app.js`: yeni sistemler ve `ctx` alanları; `WeatherSystem` (`order` 22) ve `ctx.weather`.
```

**10c.** Faz 9 tablosunda şu satırı:

```
| 9.4 | `src/world/weather.js`, `src/world/flora.js`, `src/world/sky.js` | Kar noktaları 6000, Tipi sisi; kış ormanı | Bütçe §7 |
```

şununla değiştir:

```
| 9.4 | `src/world/weather.js`, `src/world/weather-hooks.js`, `src/world/flora.js`, `src/world/sky.js`, `src/world/grass.js`, `src/world/fire.js`, `src/world/camp.js`, `src/world/terrain.js`, `src/core/post.js`, `src/core/paint-material.js` | `d2/weather.md` §9: yağış noktaları (kar 6000), sıçrama, yıldırım şeridi, ekran yağışı, şimşek, bulut örtüsü ve cephe hattı, kubbe, ıslaklık, rüzgâr; Tipi ve Kara Boran sisi; kış ormanı; Yıldırım Çamı | Bütçe §7; `menuDiff` 0; program ≤92 |
```

**10d.** 9.6 satırının «İş» hücresinin sonuna ekle: `; FELT_WET kancası ve ateşli ok tutuşma çarpanı (d2/weather.md §8.6, §9.8)`.

**10e.** Faz 9 tablosuna son satır olarak ekle:

```
| 9.8 | `src/audio/sfx/weather.js`, `src/audio/ambience.js`, `src/ui/hud/weather.js`, `src/ui/css/weather.css`, `src/core/settings-schema.js`, `src/ui/menu/pages/settings.js` | `d2/weather.md` §10, §11: altı döngü, yedi efekt, HUD simgesi, `a11y.flashes` | §15 W19–W21; canlı düğüm ≤40 |
```

**10f.** Faz 9'un altına `L` satırı ekle:

```
`L`: `src/app/sounds.js` (hava döngü birleşimi, §3.6), `src/app/devtools.js` (`menuDiff` hava saklaması, `freeze` havayı da dondurur), `src/app/states/freeroam.js` (`tanhu.roam.weather`, giriş ve çıkış karışımı).
```

## 11. §6.1 `node:test`

**11a.** Test tablosunda şu satırdan sonra:

```
| `calendar`, `regions`, `jobs` | `game/calendar`, `game/regions`, `game/jobs` | `act1.md` §2 |
```

ekle:

```
| `weather-core`, `weather-fx`, `weather-strike` | `game/weather-core`, `data/weather-types`, `data/climates`, `i18n/strings/weather` | `d2/weather.md` §15 W1–W11: belirlenim, 38 iklim satırında ≤1,5 puan, süre ve cephe, kilit ve `pinFx`, I. Perde sayıları, etki matrisi, ıslaklık, yıldırım adaleti, ses gecikmesi, K1 |
```

**11b.** **Saf listesi** paragrafında `game/{` listesine `weather-core` ekle; `world/{terrain-field,structure-logic,structure-defs,node-store,road,lake-line}` listesine `weather-hooks` ekle.

## 12. §6.3 Tarayıcıda: `window.__tanhu`

**12a.** Panel tablosunda şu satırdan sonra:

```
| `stealth` | `guards, cones, suspicion, noise, pause` | 10.4 |
```

ekle:

```
| `weather` | `state, set, clear, plan, seed, skip, wind, wet, freeze, calm, flash, thunder, hail, strike, fx, sim, calibrate, budget, identity` (`d2/weather.md` §12.8) | 8.9, 9.4 |
```

**12b.** **`menuDiff` kuralı** paragrafının sonuna ekle:

```
 Hava: ölçümden önce `world.weather` durumu saklanır, `identity()` çağrılır, ölçümden sonra geri yüklenir (post ayarları gibi); `freeze` hava saatini de durdurur.
```

**12c.** Faz sonu duman tablosunda 9 satırını:

```
| 9 | `swap('hexi_winter')`, `perf()`: ≤2,74M, ≤323 |
```

şununla değiştir:

```
| 9 | `swap('hexi_winter')`, `perf()`: ≤2,74M, ≤323; `weather.set('heavy_snow')` +≤2 çizim; Serbest Gez'de `weather.set('thunderstorm')`, `strike('near')`, `hail()`, menüye dönüş `menuDiff` 0 |
```

## 13. §7 Performans bütçesi

**13a.** «**Dağılım.**» paragrafında `` `Dialogue` ≤0,1.`` sonrasına ekle: `` `Weather` ≤0,2 (saat sınırında ≤0,3).``

**13b.** Aynı paragraftaki «Program ≤92 (`structures.md`), kışta `*_w` ile ≤100;» sonrasına ekle: «hava +2 (`weather_pts`, `weather_bolt`; menü 56 → 58, Serbest Gez 57 → 59);».

**13c.** «Önce ne kesilir» tablosunda 8 satırını:

```
| 8 | Etki: `fxFlames` 24 → 12, saplı ok 64 → 32, kar 6000 → 3000, usta 3 → 2 | ≈−40k | Az etki | Yok |
```

şununla değiştir:

```
| 8 | Etki: `fxFlames` 24 → 12, saplı ok 64 → 32, kar 6000 → 3000, usta 3 → 2; ekran yağışı 3 → 2 katman, sıçrama 192 → 96, şimşek dönüşü 4 → 1 | ≈−40k; FINAL ≈−0,1 ms | Az etki | Yok |
```

**13d.** Sahne tablosuna, «Kara Boran» satırının not hücresine ekle: `; hava +1 çizim (kar noktası)`. «Serbest Gez, üçüncü yurt tam» satırının not hücresine ekle: `; fırtına en kötü +3 çizim, +96 üçgen (d2/weather.md §9.11)`.

## 14. §8 Kararlar ve uzlaştırma

Tablonun sonuna ekle:

```
| 37 | `d2/weather.md` (K22) | Hava görünümü ışık ve program bütçesine girmeli, menü değişmemeli; Kuwahara boyası ince yağmur çizgisini siler | Ekran yağışı FINAL'de (0 çizim), kar ve dolu tek nokta çizimi, şimşek pozlama + yarımküre yoğunluğu, ıslaklık paylaşılan uniform; menü, Yeni Oyun, oluşturucu ve `home`'da kimlik | §0 kural 7 ve 8; ölçüm W12–W16 |
```
