# `architecture.md` birleşik deltası ve işleme defteri (K20–K26)

> **Yerini aldı (2026-11-03, K26).** Bu defter ve bağladığı beş alan deltası (`d2/{time,weather,labour,settlement,economy}-delta-architecture.md`) `d2/architecture-delta.md`'ye indirildi: o dosya bu defterin uygulanmış ve tamamlanmış biçimidir (§3.23–§3.27, 8.14, 9.10, Faz 13, paket ayrıklığı, düzeltilmiş sayılar: camp3 1.434 / 1.188 sn, Gün V yaması 07:00–08:42). `L` `architecture.md`'yi yalnız onunla işler; bu dosya iz için kalır ve işlenmez.

Kaynak: `d2/core.md` (K26), `time.md`, `weather.md`, `settlement.md` son biçimleri. Faz 7 bitince `L` işler; Faz 7 sürerken `architecture.md` düzenlenmez. Beş alan deltası aynı satırlara dokunduğu için bu defter **önce** okunur: §1 sırayı, §2 her alan maddesinin durumunu, §3 çakışan çapaların birleşik metnini ve baş tasarımcı kararlarının yeni maddelerini verir. Her madde bölüm başlığıyla, birebir bulunacak metinle ve yeni metinle yazılır; «Bul» metni tutmazsa madde atlanmaz, `L`'ye sorulur (Faz 7 metni değiştirmiş olabilir; anlam korunur).

## 1. Sıra

1. Bu dosyanın §3 maddeleri (C1–C14).
2. `d2/time-delta-architecture.md` (A1–A22).
3. `d2/weather-delta-architecture.md` (1–14).
4. `d2/labour-delta-architecture.md` (A0–A12).
5. `d2/settlement-delta-architecture.md` (SA1–SA18).
6. `d2/economy-delta-architecture.md` (E1–E14).

Her alan dosyasında §2'nin «Atla» dediği madde işlenmez (metni §3'tedir), «Değiştirerek» dediği madde verilen değişiklikle işlenir; listede olmayan madde olduğu gibi işlenir.

## 2. Alan maddelerinin durumu

| Dosya, madde | Durum | Değişiklik ya da neden |
|---|---|---|
| time A9, ikinci «Bul» (blok tablosu `world.zone` satırı) | Uygula | |
| time A9, «Oto kayıt nedenleri» | Atla | C3 birleşik cümle (time, labour, settlement) |
| time A9, «Serbest Gez» | Atla | C4 birleşik satır |
| time A10, iki satır ekleme | Uygula | `clock` 15, `camp_life` 81 |
| time A10, `home` cümlesi | Atla | C5 (labour A6 ile birleşik) |
| time A11, `light:` satırı | Değiştirerek | Yorumdaki «10 Nisan» → «sapma +7,4223° iğneli (11 Nisan)» |
| time A11, `moods:` satırı | Uygula | |
| time A11, `applyMood` satırı ve «Saat ışığı» paragrafı | Atla | C6 (tek ışık hattı; `applyMoodMix` yok) |
| time A12 | Değiştirerek | Etki satırındaki `'hold', id, 'hh:mm'` kalır; sonuna «; vakit bekleyişi yok, yalnız `dawn_line`, `ice_story` (d2/core.md §1.5)» |
| time A18, 8.9 satırı | Değiştirerek | «Bitti» hücresinde «altı durakta program 57» → «saat taban üstüne 0 program»; dosya listesine `src/app/app.js` yok (`L`) |
| time A18, Faz 8 `L` satırı | Atla | C9 birleşik `L` satırı |
| time A19 | Değiştirerek | Test satırı uygulanır; saf listesi değişikliği atlanır (C11 birleşik küme) |
| time A20 | Uygula | |
| time A21 | Atla | C13 birleşik «Dağılım» |
| time A22 | Değiştirerek | Satır numaraları C14'e göre; satır 38'de «10 Nisan» → «11 Nisan (sapma iğneli)» |
| weather 1 | Uygula | Paket numaraları ağaçta: `→8.9` yazan hava satırları `→8.10` olur |
| weather 3a | Atla | C2 (`world.weather` order 78) |
| weather 3b | Atla | C4 |
| weather 5 | Değiştirerek | Satır uygulanır; paragraf C5'in metniyle |
| weather 6a | Uygula | |
| weather 6b | Atla | C6 |
| weather 10a | Değiştirerek | Paket numarası 8.10 (C9) |
| weather 10b | Atla | C9 |
| weather 10c, 10d, 10e | Uygula | 9.8 hava kalır |
| weather 10f | Atla | C10 birleşik Faz 9 `L` satırı |
| weather 11a | Değiştirerek | Satır, time A19'un eklediği `| `regions`, `jobs` |` satırından sonra eklenir; W listesine «W26» |
| weather 11b | Atla | C11 |
| weather 12a | Değiştirerek | Paket hücresi `8.10, 9.4` |
| weather 12b | Atla | C12 |
| weather 12c | Uygula | |
| weather 13a, 13b | Atla | C13 |
| weather 13c | Uygula | |
| weather 13d | Değiştirerek | «+3 çizim» → «+2 çizim» |
| weather 14 | Değiştirerek | Numara C14'e göre |
| labour A6, satır | Uygula | `sites` 61 |
| labour A6, `home` cümlesi | Atla | C5 |
| labour A7, satır | Uygula | `world.sites` 76; not hücresi «≤16 KB» → «bütün zonlarda ≤20 KB» |
| labour A7, Serbest Gez | Atla | C4 |
| labour A9 | Değiştirerek | 8.L1 → 8.11, 8.L2 → 8.12; «Bitti» hücresinde camp3 sayıları C9'daki gibi; alt paragraftaki «zaman taslağı 8.9'u aldı» cümlesi «Paket numaraları K26'dır» olur; `L` satırı C9 |
| labour A10 | Değiştirerek | `builders` satırının sınama hücresi C11'deki gibi; saf listesi C11 |
| labour A11 | Atla | C13 |
| labour A12 | Değiştirerek | Numara C14'e göre; «Çocuk ekibe yarım el olarak katılır» → «Çocuk adımın fiilini yaptıkça yarım el sayılır» |
| settlement SA2, SA5 | Değiştirerek | Ağaçtaki `→8.11` → `→8.13` |
| settlement SA3 | Değiştirerek | `→8.11` → `→8.13`; `settlement/caravan-orders.js` satırının yerine `  settlement/caravans.js           →8.13 CaravanBook: buyruk, koruma, yol töresi, akın, yoldaki yük; K24 transfer ve armyShare ile (saf)`; ek satırlar: `  settlement/stores.js             →8.13 StorePool: yerin kapları, ofPlace, kabul (saf)`, `  settlement/production.js         →8.13 Tezgâh saati, toplama kolu, sürü günü, mevsim olayları (saf)`, `  settlement/chronicle.js          →8.13 Kronik: perdeler arası yıllar, açılış tabanı, kış stoğu (saf)` |
| settlement SA7, `settlement` satırı | Atla | C2 |
| settlement SA7, `camps` satırı | Atla | C2 |
| settlement SA7, oto kayıt ve `force` | Atla | C3 |
| settlement SA8 | Değiştirerek | Satır uygulanır; paragraf C5 |
| settlement SA13 | Değiştirerek | «ikmal kervanı `r_whistle_ordu` üstünde K24 `Caravan` kaydıdır, `CaravanOrders` sürer» → «ikmal kervanı `r_whistle_ordu` üstünde yerleşimin `CaravanBook` kaydıdır» |
| settlement SA15 | Değiştirerek | `catchUp` yorumuna «≤3 gün saat saat, uzunu günlük adım; her şantiye için `sites.simulate(siteId, dk, env)`»; `caravan-orders.js` satırının yerine `// game/settlement/caravans.js (saf): CaravanBook { order(o); hour(env); trips(); inTransit; toJSON(); fromJSON(o); }   // K24 transfer ve armyShare ile`; ek satırlar `// game/settlement/stores.js (saf): StorePool { add(container, { place }); ofPlace(place); accept(id, n); toJSON(); fromJSON(o); }`, `// game/settlement/production.js (saf): hour(env); dawn(env)   // Workshop.tick, herdDay`, `// game/settlement/chronicle.js (saf): chronicle(state, fromDayN, toDayN, k24)   // K25` |
| settlement SA12 | Değiştirerek | «Yapı bitince Stores.register(container, { place })» → «Yapı bitince yerleşimin StorePool'una (settlement/stores.js) eklenir» |
| settlement SA16 | Değiştirerek | 8.11 → 8.13 ve dosya listesi C9; Faz 9 9.8 → 9.9; Faz 9 `L` satırı C10 |
| settlement SA17 | Değiştirerek | Test satırı uygulanır; saf listesi C11 |
| settlement SA18 | Değiştirerek | İki sahne satırı uygulanır; «Dağılım» değişikliği C13; «Program» değişikliği C13 |
| economy E4 | Uygula | |
| economy E6, E7 | Değiştirerek | `Container` §3.13 yüzünü uygular: `load()` Yük, `cap` okuyucu; `load10()`, `cap10` iç alan (C8) |
| economy E8 | Değiştirerek | C8 |
| economy E9 | Uygula | |
| economy E10 | Uygula | |
| economy E11 | Atla | C11 |
| economy E12 | Değiştirerek | Satırın sonuna «; `d2/weather-model.json`» |
| economy E13 | Uygula | |
| economy E14 | Atla | C13 |

## 3. Birleşik ve yeni maddeler

### C1. §2.5 Kare döngüsü (K20: duvar saati)

**Bul:** `  const dt = clamp((now - this.last) / 1000, 0, 0.05);        // kıstırma kalır`
**Sonrasına ekle:**
```
  this.wallDt = clamp((now - this.last) / 1000, 0, 0.25);       // K20: dünya saati kırpılmamış süreyle ilerler (ClockSystem okur; d2/core.md §1.1)
```

**Bul:** `**Saat.** `core/clock.js` iki zaman verir:` ile başlayan paragrafın sonu
**Sonrasına ekle:**
```
**Dünya saati (K20).** `ClockSystem` (8.9) oyun dakikasını `ctx.app.wallDt` ile ilerletir: kare 0,05 sn'ye kırpılsa da bir oyun günü 60 gerçek dakika kalır; duraklama nedenleri (`map`, `pause`, diyalog, sinema, Bekle tekeri, Donuk Kamp) yine durdurur; gizli sekmede rAF durduğu için saat de durur.
```

### C2. §3.5 Kayıt, blok tablosu

**Bul:** `| `world.npcs` | 74 | `game/npcs.js` | |`
**Sonrasına ekle** (labour A7'nin `world.sites` satırından sonra, bu sırayla):
```
| `settlement` | 77 | `game/settlement/index.js` | Yerleşim: hane, ustalar, iş kodu, Çekim, ambar içerikleri (`StorePool`), tezgâh kuyrukları, sürüler, kervan buyrukları ve yoldaki yük, Divan, Kronik; ≤14 KB (`settlement.md` §16). Yapılar `world.sites`'ta; kişisel kaplar `economy` bloğunda |
| `world.weather` | 78 | `game/weather.js` | ≤1 KB: tohum, plan (≤10 bölüm; sabit çapadan yeniden üretilebilir), ıslaklık, kar örtüsü ve kabuk, kilitler, yıldırım beklemesi (`struck`, site kimliğiyle) (`weather.md` §12.7) |
```

**Bul:** `| `army` | 90 | `game/squad/index.js` | `Follower` yazılmaz |`
**Sonrasına ekle:**
```
| `camps` | 92 | `game/settlement/camps.js` | Ana ve sefer ordugâhı: kademe, `CampPlan`, konfor, Erzak Ambarı içeriği, kış dağılması; ≤4 KB |
```

### C3. §3.5 Oto kayıt nedenleri

**Bul:** `**Oto kayıt nedenleri.** `slice`, `quest_done`, `level_spend`, `region` (≥60 sn), `act`, `world`, `fire`, `rest`, `depart`, `alight`, `pagehide`, `to_menu`. `force`: `act`, `world`, `depart`, `alight`, `pagehide`, `to_menu`.`
**Yerine:**
```
**Oto kayıt nedenleri.** `dawn`, `sleep`, `wait` (≥1 oyun saati), `work` (≥1 oyun saati), `quest_done`, `level_spend`, `region` (≥60 sn), `act`, `world`, `fire`, `rest`, `depart`, `alight`, `pagehide`, `to_menu`, `tier` (yerleşim kademesi), `caravan` (kervan varışı, ≥60 sn), `court_path` (V. kademe yolu). `force`: `act`, `world`, `depart`, `alight`, `pagehide`, `to_menu`, `court_path`.
```

### C4. §3.5 Serbest Gez

**Bul:** `**Serbest Gez** ayrı bloktur: `{ schema:1, camp3, camp:{structures}, child:{pos,yaw,weapon,sit?}, mood, flags, playTime }``
**Yerine:**
```
**Serbest Gez** ayrı bloktur: `{ schema:1, camp3, camp:{structures}, child:{pos,yaw,weapon,sit?}, clock:{day,minute}, flags, playTime, weather }` (`camp3` kendi `v: 2` sürümünü taşır, `labour.md` §14; `weather` yolculuk bloğuyla aynı biçim, `weather.md` §12.7; `mood` artık yazılmaz, okunursa saate göç eder: >0,75 ise akşam 18:38, değilse menü dakikası 14:46,2)
```

### C5. §3.7 Sistemler: `home` cümlesi ve sistem paragrafı

**Bul:** `` `ikisi` `freeroam` ve `play` demektir. `home`'da yalnız `mount`, `child`, `structures` çalışır. ``
**Yerine:**
```
`ikisi` `freeroam` ve `play` demektir. `home`'da yalnız `mount`, `child`, `structures`, `sites` ve iğneli `clock` çalışır; `weather` `home`'da çalışmaz (hava kimlik).

**Saat, hava, şantiye, yerleşim (K20–K24, `d2/core.md` §6).** `clock` (15) dünya saatini ilerletir, `world.lightBase`'i yazar, Bekle, Uyu, Dinlen, Çalış ve vakit çağrısını yürütür. `weather` (22) saatten sonra, okuyucularından (`campfire`, `structures`, `sites`, `settlement`, `stealth`, `travel`, `nodes`, `sound`) önce çalışır: hepsi aynı karenin `ctx.weather.fx`'ini okur. `sites` (61) şantiyeleri sürer; `settlement` (64) yerleşim ve ordugâh durumunu, hangi dünya yüklü olursa olsun her `clock:hour`'da işler: önce Kâhya ekipleri yazar, sonra K21 `sites` şantiye emeğini, yerleşimin `production`'ı tezgâhları (`Workshop.tick`) ve toplama kolunu, `CampState` ve `CaravanBook`; `dawn`'da tüketim (`SupplyLedger`) ve sürü (`herdDay`), sonra Çekim, katılım, ayrılış, Gönül; `clock:skip`'te ≤3 gün saat saat, uzunu günlük adım; `act_change`'te Kronik. K24 ayrı bir `GameSystem` kurmaz: `Container`, `Workshop`, `herdDay`, `transfer`, `armyShare`, `rolloverYears`, `SupplyLedger` saf servislerdir. Yüklü dünya `spec.settlement` taşıyorsa görünüm (`world/settlement-view.js`), Plan Kipi ve etkileşimler açılır. `ctx.settlement` `{ hold, camps, openPlan(), closePlan() }`. Görünür işçi `NpcManager.budget`'ını (16 tam, 40 kukla) paylaşır.
```

### C6. §3.8 World: ışığın tek hattı

**Bul:** `  moodT; moodTarget; mood; applyMood(t); setFogOverride({ near, far, color } | null);  // applyMood sonunda uygulanır`
**Yerine:**
```
  moodT; moodTarget; mood; applyMood(t); setFogOverride({ near, far, color } | null);  // applyMood sonunda uygulanır; menü yolu, değişmez
  lightBase;  setTimeOfDay(sample | null);  writeLight();  timeDriven;   // 8.9: saat yalnız lightBase'i yazar; writeLight tek yazıcı (8.9 kimlik, 9.4'ten WeatherView.compose)
```

**Bul:** `**Gök, sis katmanı, göl hattı (Faz 4–5).**` ile başlayan paragrafın sonu
**Sonrasına ekle:**
```
**Işığın tek hattı (K20, K22, K26; `time.md` §5, §12.6, `weather.md` §9.2).** `MOODS` altı durak taşır: `night`, `dawn`, `morning`, `noon`, `golden`, `dusk`; son ikisi bugünkü değerlerdir. Menü, Yeni Oyun, oluşturucu ve `home` `applyMood(t)`'yi bugünkü gibi kullanır, saati ve havayı okumaz. `freeroam` ve `play`'de `ClockSystem` 4 Hz'de `setTimeOfDay(sample)` çağırır: iki durak `mixTone` ile karışır, sonuç düz `world.lightBase` kaydına yazılır (renkler, yoğunluklar, sis, kubbe, göl, köy, kenar, pozlama, yön, `k`, ay, gece); three.js nesnesine dokunmaz, ayırma yapmaz. Güneşi, yarımküreyi, sisi, kubbe, göl ve kenar uniform'larını ve pozlamayı yalnız `writeLight()` yazar: 8.9'da kimlik (tabanın kopyası), 9.4'ten `WeatherView.compose(base, params, flash)` (hava çarpanı, kamera sis tabanı, şimşek nabzı; kimlikte doğrudan kopya). `writeLight` karede en çok bir kez, yalnız taban, hava ya da şimşek değişince çalışır; `setFogOverride` en son kazanır. Yön oyun dakikasında bir adım değişir ve ışık uzayında gölge ızgarasına oturtulur; gölge düşüren yükseklik ≥15°, `normalBias` düşük güneşte ölçeklenir, gölge donukken yön de donar. Geceleri aynı `DirectionalLight` ay ya da gök yönündendir; ışık eklenmez, saat program eklemez (hava +2). Serbest Gez yeni oturumda menü dakikasında (14:46,2) açılır: o dakikada saat ışığı menü ışığıdır; menüden iniş 2,4 sn, dönüş 1,7 sn süzülür (ışık ve hava birlikte).
```

### C7. §3.5 `setRules`: İnce İş kimliği

**Bul:** `  setRules({ xpCurve, levelCaps, statCaps, axisCaps, skills, items, derive, autosaveBlocked });   // tablolar sonraki fazlarda; verilmeyen denetim atlanır`
**Yerine:**
```
  setRules({ xpCurve, levelCaps, statCaps, axisCaps, skills, items, derive, autosaveBlocked });   // tablolar sonraki fazlarda; verilmeyen denetim atlanır; items denetimi baseId(id) ile: İnce İş 'hun_bow+' geçerlidir (K24)
```

### C8. §3.13 ve §3.22: K24 servisleri (economy E6–E8 ve settlement SA12'nin değişikliği)

economy E8'in «Yeni» bloğunda şu satırlar değişir (öteki satırlar aynen):
- `export function ledger(id);   // kayıtlı defter: 'winter_camp', 'own_camp' (yerleşim), 'camp_home', 'camp_field'` → `export function ledger(id);   // kayıtlı defter: 'winter_camp', 'own_seat' (yerleşim), 'own_camp' (ana ordugâh), 'field_camp' (sefer)`
- `export function armyShare(riders);   // Ordu Payı öğün/gün: ≤100 atlı %10, ≤1.000 %2,5, ≤3.000 %2 (d2/economy.md §7.3)` → `export function armyShare(residentRiders, { movingK = 1, winter = false });   // Ordu Payı öğün/gün: yerleşik atlı × 0,1 (Göçer ×1,1; kışın dağılma: ×0,1) (d2/core.md §4.6)`
- `export function roll(tableId, rng);                   // → [{ id, n } | { herd, n } | { gear }]; insan yok (K23)` → `export function of(enemyKind, counters);             // belirli ganimet: türün sabit verimi, kesirli pay tür sayacında birikir; insan yok (K23), adlı silah elle konur (progression.md karar 6)`
- bloğun sonuna ekle: `export function transfer(from, to, items, { filter });   // kaplar arası aktarma (StorePool, CaravanBook çağırır)` ve `export function rolloverYears(state, years, { capacity, targets });   // Kronik'in kapalı yıl adımı (K25)`

economy E6–E7: `Container` sınıfı `architecture.md` §3.13 kap yüzünü uygular: `{ add, remove, list, load(), cap }` (Yük); `load10()`, `free10()`, `cap10` iç alanlardır.

settlement SA12 «Ekle» bloğunun ikinci satırı: `// Kap taşıyan yapılar: grain_pit, store_yurt, shed, granary, granary_tower, treasury (yerleşim); armoury, supply_depot (ordugâh). Yapı bitince yerleşimin StorePool'una eklenir (settlement/stores.js, ofPlace).`

### C9. §5 Faz 8: paket numaraları ve `L` satırı

Faz 8 tablosuna 8.8'den sonra şu sırayla: 8.9 (time A18, değişikliğiyle), 8.10 (weather 10a), 8.11 ve 8.12 (labour A9), 8.13 (aşağıda). labour A9'un 8.11 satırında «Bitti» hücresi: `camp3 saatsiz yardımsız 1.423 sn ±10, bütün yardımla 1.187 sn ±10; 14:54 saatiyle ve öğünle ilk duman 00:51 (1.493 sn) ve 23:11 (1.244 sn) ±15; aile ocak yanana dek ateşte (en geç 01:30); menuDiff 0; program ≤92`.

**8.13 satırı** (settlement SA16'nın 8.11 satırının yerine):
```
| 8.13 | `src/data/settlement.js`, `src/game/settlement/state.js`, `src/game/settlement/households.js`, `src/game/settlement/steward.js`, `src/game/settlement/stores.js`, `src/game/settlement/production.js`, `src/game/settlement/caravans.js`, `src/game/settlement/raids.js`, `src/game/settlement/camps.js`, `src/game/settlement/court.js`, `src/game/settlement/chronicle.js`, `src/i18n/strings/settlement.js`, `test/settlement.test.js` | Yerleşim çekirdeği, saf (`settlement.md` §5, §6, §9–§12, §15, §16): hane, Kâhya, ambar havuzu, üretim, kervan, akın, ordugâh, Divan, Kronik; K24 `Container`, `Workshop`, `herdDay`, `transfer`, `armyShare`, `rolloverYears`, `SupplyLedger` ve K21 `SiteSystem` sözleşmeyle; `d2/settlement-model.json` v2 ile aynı sayılar | `settlement.md` §21 saf maddeleri 1–19 |
```

**Bul (Faz 8 `L` satırı):** `` `L`: `src/app/systems.js`, `src/app/app.js`: yeni sistemler ve `ctx` alanları. ``
**Yerine:**
```
`L`: `src/app/systems.js`, `src/app/app.js`: yeni sistemler ve `ctx` alanları: `clock` 15, `weather` 22, `sites` 61, `settlement` 64 (9.9'da bağlanır), `camp_life` 81; `ctx.worldClock`, `ctx.calendar`, `ctx.weather`, `ctx.sites`, `ctx.settlement`; `app.wallDt` (C1). `src/ui/hud.js` geliştirme ışık düğmesi kalkar, Gök Kavisi yuvaya takılır; `src/app/sounds.js` ortamı evreye ve havaya bağlar (`time.md` §8.5, `weather.md` §10.4); `src/app/devtools.js` C12; `src/app/states/freeroam.js` `roam.clock`, `roam.weather`, `endSession` geri yüklemesi (`time.md` §14).

Paket numaraları K26'dır: 8.10 8.9'un saat yüzünü, 8.11–8.13 8.9 ve 8.10'u sözleşmeyle alır; dosya paylaşmazlar. `keymap.js` 8.9'dadır: `wait` (`T`), K21 `rotate` ve K23 `build_mode` (`P`) eylemleri oraya `CONTRACT-REQUEST` ile eklenir.
```

### C10. §5 Faz 9: paket numaraları ve `L` satırı

Faz 9 tablosu: 9.4 (weather 10c), 9.6 (weather 10d eki), 9.8 hava sesi ve HUD (weather 10e), **9.9** yerleşim görünümü ve Plan Kipi (settlement SA16'nın 9.8 satırı, numarası 9.9). Faz 10: 10.10 (settlement SA16).

**Faz 9 tablosunun altına ekle** (weather 10f ve settlement SA16 `L` satırlarının yerine):
```
`L`: `src/app/sounds.js` (hava döngü birleşimi, §3.6), `src/app/devtools.js` (`drawMenuFrame` hava, saat ve CampLife saklaması; `freeze` havayı da dondurur), `src/app/states/freeroam.js` (`tanhu.roam.weather`, giriş 2,4 sn ve çıkış 1,7 sn karışımı), `src/app/systems.js` (`SettlementSystem` 64, `ctx.settlement`).
```

### C11. §6.1 Test tablosu ve saf listesi

labour A10'un `builders` satırının sınama hücresi: `structures.md` §10, §11.6: saatsiz yardımsız 1.423 sn ±10, Çocuğun bütün yardımıyla 1.187 sn ±10; 14:54 saatiyle ve öğünle 1.493 ve 1.244 sn ±15; Dengiz her adımda; aile ocak yanana dek ateşte; takılan usta en çok 6 sn bekletir; dizgeler TR ve EN`.

**Bul (saf listesi içinde):** `game/{cond,flags,effects,damage,save,progress,derive,items,inventory,needs,craft,supply,barter,cooking,calendar,jobs,quests,schedule,stealth-core,agent-move,interact,camera-rig,travel-data,nav,nav-patches}`
**Yerine:**
```
game/{cond,flags,effects,damage,save,progress,derive,items,inventory,container,needs,craft,supply,barter,herds,loot,cooking,calendar,world-clock,daylight,weather-core,jobs,quests,schedule,stealth-core,agent-move,interact,camera-rig,travel-data,nav,nav-patches,labour,site-core}`, `game/settlement/{state,households,steward,stores,production,caravans,raids,camps,court,chronicle}
```

**Bul (saf listesi içinde):** `world/{terrain-field,structure-logic,structure-defs,node-store,road,lake-line}`
**Yerine:** `world/{terrain-field,structure-logic,structure-defs,node-store,road,lake-line,weather-hooks}`

### C12. §6.3 `window.__tanhu`: menü güvencesi

**Bul:** `**`menuDiff` kuralı.**` ile başlayan paragrafın sonu
**Sonrasına ekle:**
```
**`menuDiff` ve saat, hava (K20, K22).** `menuDiff` Serbest Gez sürerken de çalışır (`struct.diff`, `refs.compare`). `drawMenuFrame` çizmeden önce `world.setTimeOfDay(null)`, `campLife.menuPose(true)` (statik Ozan, Ana ve Baba görünür, ikizler ve yaban hayvanı gizli) ve `world.weather.identity(0)` çağırır, çizdikten sonra son saat örneğini, oturum pozunu ve havayı geri yazar (post ayarlarını sakladığı gibi); `freeze` hava saatini de durdurur. Zerre `uDusk` menüde kurulum değeridir (0) ve saat kanalı menü anahtarına dek 0'dır. Kabul: Serbest Gez'den çıkmadan 03:00'te `menuDiff` 0; gece oturumundan sonra `menuDiff` 0; yeni oturumun ilk karesi `uDusk` ve halk görünürlüğü dahil menüyle aynı (`time.md` §17). `CONTRACT-REQUEST: src/app/devtools.js, drawMenuFrame saat, CampLife ve hava saklaması` (`L`).
```

### C13. §7 Performans bütçesi

**Bul:** `` `Quests`, `Calendar`, `Regions` ≤0,1; ``
**Yerine:** `` `Quests`, `Calendar`, `Regions` ≤0,1; `ClockSystem` ≤0,02 (4 Hz taban yazımı ≤0,03 çağrı başına); `CampLife` ≤0,05; `Weather` ≤0,2 (saat sınırında ≤0,3); `SiteSystem` ≤0,1; `SettlementSystem` kare başına ≤0,1, saat başına ≤0,5; atlamanın toplu işi karartma altında ≤60 ms / 15 oyun saati, uzun atlama ≤150 ms / mevsim; ``

**Bul:** `Program ≤92 (`structures.md`), kışta `*_w` ile ≤100;`
**Yerine:** `Program ≤92 (`structures.md`; saat 0 ekler; hava +2: `weather_pts`, `weather_bolt`, menü 56 → 58, Serbest Gez 57 → 59; yerleşim dünyası +6: `yurt_field`, `kit_field` (`BatchedMesh`) ve derinlikleri, `plot_decal`, `field_stalk`, `plan_ghost` yok), kışta `*_w` ile ≤100 (yerleşimde +2);`

**Bul:** `| Serbest Gez, üçüncü yurt tam | ≤2,70M | ≤4,06M | ≤511; `Smoke` birleşince ≤481 | ≤3 ms | Hesap: Çocuk +9 çizim, üçüncü yurt ≤+45 ve ≤+248k (`structures.md` §13), araba +6, +9,6k. Bugünü aşan tek sahne; kampta 33 ms kabul |`
**Yerine:**
```
| Serbest Gez, üçüncü yurt tam | ≤2,70M | ≤4,06M | ≤511; `Smoke` birleşince ≤481 | ≤3 ms | Hesap: Çocuk +9 çizim, üçüncü yurt ≤+45 ve ≤+248k (`structures.md` §13), araba +6, +9,6k; saatin gündüz ikizleri ≤+6, hava fırtınada +2: 514 > 511, **`Smoke` birleşmesi (5.2) önkoşuldur** → 484; birleşme düşerse gündüz ikizi 1 (511). Gece içeride uyuyan üç statik −9. Bugünü aşan tek sahne; kampta 33 ms kabul |
```

labour A11'in «Aynı paragrafın sonuna ekle» cümlesi ve economy E14'ün cümlesi bu paragrafın sonuna eklenir (değişmeden).

### C14. §8 Kararlar ve uzlaştırma: satır sırası

Tablonun son satırından sonra, sıradaki boş numaradan başlayarak bu sırayla: time A22'nin dört satırı (37–40 istedi), weather 14, labour A12, ardından şu satır:

```
| (sıradaki) | K26: beş d2 alanı aynı dikişlere dokunur | Işık hattı, kayıt satırları, paket numaraları, kimlikler iki ya da üç taslakta farklı yazıldı | Her dikişin tek sahibi `d2/core.md` §6'dadır; çakışan delta maddeleri `d2/core-delta-*.md` defterinin birleşik metniyle işlenir | Birleşmede kayıp ve çift sayı yok |
```

`time A22`'nin `| 25 | §3.2: `mood` yalnız geliştirme |` satırına eki «K20'de kalktı: §8 karar 40.» numarası değişirse buna göre yazılır.
