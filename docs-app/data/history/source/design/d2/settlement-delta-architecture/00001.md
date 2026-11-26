# `architecture.md` değişiklikleri: Yerleşim, ordugâh ve hanlık (K23)

> **Yerini aldı, işlenmez (2026-11-03, K26).** `architecture.md` yalnız `d2/architecture-delta.md` birleşik defteriyle işlenir; bu dosyanın maddeleri oraya, sayıları `d2/core.md`'ye göre düzeltilerek indirildi. Dosya iz için kalır; `L` onu ikinci kez işlemez (çapalar ikinci geçişte tutmaz).

Kaynak: `d2/settlement.md`. Faz 7 bitince `L` işler. Biçim: **Yer** (bölüm ve bulunacak satır), **Bul** / **Yerine** (birebir değişim) ya da **Sonrasına ekle** / **Ekle** (tam yeni metin). K21 (`d2/labour-delta-architecture.md`) ve K20 (`d2/time-delta-architecture.md`) eklerinin aynı tablolara satır eklediği yerlerde bu dosya yalnız kendi satırını ekler; sıra `order` değerine göredir.

## SA1. Giriş paragrafı (satır 3)

**Bul:** `` `act1.md`, `progression.md`, `structures.md`, `economy.md`, `survival.md`, `travel.md`, `army.md`, `audio.md`, ``
**Yerine:** `` `act1.md`, `progression.md`, `structures.md`, `economy.md`, `survival.md`, `travel.md`, `army.md`, `settlement.md`, `audio.md`, ``

(K21 eki `labour.md`'yi aynı listeye ekler; ikisi birlikte uygulanır.)

## SA2. §1 Hedef klasör ağacı, `src/data/`

**Bul:** `  enemies.js                       →8.8 Düşman tablosu`
**Sonrasına ekle:**
```
  settlement.js                    →8.11 Yerleşim: kademe, yapı satırı, parsel kuralı, hane kaynağı, ordugâh kademesi (saf; settlement.md, d2/settlement-model.json)
```

## SA3. §1, `src/game/`

**Bul:** `  squad/demo.js                    →10.6 ?squad=10, yalnız geliştirme`
**Sonrasına ekle:**
```
  settlement/state.js              →8.11 SettlementState: hane, kişi kaydı, iş kodu, çekim, Gönül, kademe, yol (saf)
  settlement/households.js         →8.11 Katılım, ayrılış, seferberlik, yenilenlerin seçimi (saf)
  settlement/steward.js            →8.11 Kâhya: ekip listeleri (K21 şantiye, K24 tezgâh, sürü, toplama kolu, nöbet, sürücü) (saf)
  settlement/caravan-orders.js     →8.11 CaravanOrders: buyruk, koruma, yol töresi, akın; K24 Caravan'ı sürer (saf)
  settlement/raids.js              →8.11 Yerleşim akını: tehdit, savunma, başarı (saf)
  settlement/camps.js              →8.11 CampState: ordugâh kademesi, konfor, talim, CampPlan (saf)
  settlement/court.js              →8.11 Divan, toplantılar, alamet, Hazine (saf)
  settlement/index.js              →9.8 SettlementSystem (GameSystem 'settlement'); 10.10 Defter ve kervan
  settlement/plan.js               →9.8 Plan Kipi: 'plan' bağlamı, önizleme, sites.place
```

## SA4. §1, `src/world/`

**Bul:** `  specs/winter-layout.js           →9.1 act1.md §4 yerleşim verisi`
**Sonrasına ekle:**
```
  settlement-view.js               →9.8 YurtField, KitField, parsel çıkartması, sürü örnekleri
  specs/tanhu-ordu.js              →13 II. Perde yerleşim dünyası (settlement.md §3.2)
  specs/whistle-field.js           →13 II. Perde ana ordugâh dünyası (settlement.md §3.3)
```

## SA5. §1, `src/ui/` ve `src/i18n/strings/`

**Bul:** `  act-card.js                      →11.9 Perde kartı`
**Sonrasına ekle:**
```
  hold-ledger.js                   →10.10 Yerleşim Defteri sayfası (settlement.md §14.2)
  hud/plan-bar.js                  →9.8 Plan Kipi şeridi
  css/hold.css                     →9.8 Plan şeridi ve Defter sayfası
```

**Bul:** `  strings/quests.js                →10.7 Görevler ekranı çerçeve metinleri`
**Sonrasına ekle:**
```
  strings/settlement.js            →8.11 Yerleşim, ordugâh, Plan Kipi, Defter, kademe kartları
```

## SA6. §3.2 Girdi, `InputCtx.id` yorumu ve tuş tablosu

**Bul:** `  id,                  // 'game' | 'map' | 'menu' | 'book' | 'dialogue' | 'cine' | 'roadcard' | ...`
**Yerine:** `  id,                  // 'game' | 'map' | 'menu' | 'book' | 'dialogue' | 'cine' | 'roadcard' | 'plan' | ...`

**Bul:** `pause:['Escape'], save:['F5'], load:['F9'], mood:['KeyT'],`
**Yerine:** `pause:['Escape'], save:['F5'], load:['F9'], mood:['KeyT'], build_mode:['KeyP'],`

**Bul (tablonun altındaki paragrafın sonu):** `` 0,6 sn basılı `drop_load` (`holdTime`). ``
**Sonrasına ekle:**

`build_mode` (`P`) Plan Kipi'ni açar (`settlement.md` §14.1): `plan` bağlamı modal değildir ama `actions` listesiyle Q, E (15° döndür, Shift ile 5°), tekerlek, sol ve sağ tık, `Tab`, `Delete` ve `Escape`'i yutar; böylece Q (`quick`, `cmd_call`) ve R (`cmd_loose`) çakışmaz. K21'in önerdiği `rotate` eylemi bu bağlamda Q ve E'dir. `mood` K20 ile `T` Bekle olur (`d2/time-delta-architecture.md`).

## SA7. §3.5 Kayıt, blok tablosu

**Yer:** K21 ekinin `| \`world.sites\` | 76 | …` satırının altı (K21 eki yoksa `| \`world.npcs\` | 74 | …` satırının altı).
**Ekle:** `| \`settlement\` | 77 | \`game/settlement/index.js\` | Yerleşim: hane, işçi iş kodu, çekim, kervan buyruğu, Divan; ≤10 KB (\`settlement.md\` §16). Yapılar \`world.sites\`'ta; kap, sürü ve yoldaki kervan K24 \`economy\` bloğunda |`

**Yer:** `| \`army\` | 90 | \`game/squad/index.js\` | \`Follower\` yazılmaz |` satırının altı.
**Ekle:** `| \`camps\` | 92 | \`game/settlement/camps.js\` | Ana ve sefer ordugâhı: kademe, \`CampPlan\`, konfor; ≤4 KB |`

**Bul:** `` **Oto kayıt nedenleri.** `slice`, `quest_done`, `level_spend`, `region` (≥60 sn), `act`, `world`, `fire`, `rest`, `depart`, `alight`, `pagehide`, `to_menu`. ``
**Yerine:** `` **Oto kayıt nedenleri.** `slice`, `quest_done`, `level_spend`, `region` (≥60 sn), `act`, `world`, `fire`, `rest`, `depart`, `alight`, `pagehide`, `to_menu`, `tier` (yerleşim kademesi), `caravan` (kervan varışı, ≥60 sn), `court_path` (V. kademe yolu). ``

**Bul:** `` `force`: `act`, `world`, `depart`, `alight`, `pagehide`, `to_menu`. ``
**Yerine:** `` `force`: `act`, `world`, `depart`, `alight`, `pagehide`, `to_menu`, `court_path`. ``

(K20 eki aynı cümleye `sleep`, `wait` ekler; birlikte uygulanır.)

## SA8. §3.7 Sistem tablosu

**Yer:** K21 ekinin `| 61 | \`sites\` | …` satırının altı (yoksa `| 62 | \`builders\` | …` satırının altı).
**Ekle:** `| 64 | \`settlement\` | \`game/settlement/index.js\` | play |`

**Tablonun altına ekle (paragraf):**

**`SettlementSystem` (`settlement.md` §18).** Yerleşim ve ordugâh durumu yolculuk kaydındadır, hangi dünya yüklü olursa olsun her `clock:hour`'da işler (K20): önce `SettlementState.hour` (Kâhya ekipleri yazar), sonra K21 `SiteSystem` şantiye emeğini, K24 `EconomySystem` tezgâhları ve toplama kolunu, sonra `CampState.hour` ve `CaravanOrders.hour`; `dawn`'da K24 tüketim ve sürü, sonra çekim, katılım, ayrılış, Gönül; `clock:skip`'te aynı sıra saat saat (`catchUp`). Olay sırasına güvenilmez: Kâhya'nın yazdığı ekip değişene dek kalır; K24 `economy` (102) ve K21 `sites` (61) o anki ekiple çalışır, en kötü durum bir saatlik gecikmedir. Yüklü dünya `spec.settlement` taşıyorsa görünüm (`world/settlement-view.js`), Plan Kipi ve etkileşimler (Ambara Koy, Ambardan Al, Divan, Güne Selam, Toy Ver) açılır; taşımıyorsa sistem yalnız saat işini yapar. `ctx.settlement` `{ hold, camps, openPlan(), closePlan() }` (`hold` `own_seat`'in `SettlementState`'i). Görünür işçi `NpcManager.budget`'ını (16 tam, 40 kukla) paylaşır; ayrı bütçe yoktur.

## SA9. §3.8 WorldSpec, kamp spec'i bloğunun altı

**Yer:** `` `grass`, `flora`, `valley`, `camp`, `interior`, `game`, `atlas`, `world` bugünkü `import { height }` satırlarını korur `` ile başlayan paragrafın önü.
**Ekle:**

**Yerleşim ve ordugâh dünyaları (`settlement.md` §3, §13.4).** II. Perde dünyaları `spec.settlement` taşır; Kışlak ve kamp taşımaz.

```js
// world/specs/tanhu-ordu.js (Faz 13). whistle-field.js aynı alanı kind: 'camp' ile yazar.
settlement: {
  kind: 'hold',                                   // 'hold' | 'camp'
  hearthSites: [{ id: 'hs_terrace', at: [-80, -120], name: { tr: 'Seki', en: 'The Terrace' }, traits: { water: 45, flood: 0, wind: 1 } } /* hs_bend, hs_lee */],
  plots: { /* hearthSite → önceden kırpılmış parsel çokgenleri: core, dwell, work, pen, field, wall, edge */ },
  sacred: { id: 'sacred_hill', at: [-420, -470], r: 6 },
  water: [{ kind: 'brook', pts: [[-700, -300], [-80, -150], [160, 60], [700, 150]], flood: 25 }],
  clusters: ['c_elm_bend', 'c_willow_brook', 'c_reed_bend', 'c_hay_meadow', 'c_dung_steppe', 'c_saxaul', 'c_quarry', 'c_clay', 'c_salt', 'c_iron'],
  gates: ['gate_ordu_w', 'gate_ordu_e'],  dailin: { at: [380, 300], r: 160 },  limits: { records: 160, live: 48 },
},
campSites: [],                                    // sefer iç haritaları: [{ id, x, z, r, water, grazeKm2 }]
weather: { climate: 'steppe_south' },  light: { lat: 43.5 },
```

Parsel çokgenleri yükleyicide hesaplanmaz, veriye yazılır. Kurallar `data/settlement.js` `PLACEMENT`'tır; K21 `validatePlacement(def, place, { …, rules })` onları okur.

## SA10. §3.11 Yapı sistemi, K21 ekinden sonra

**Yer:** §3.11 maddelerinin sonu (K21 ekinin **K21 emek yasası** paragrafından sonra).
**Ekle:**

**K23 yerleşim yapıları (`settlement.md` §7, `d2/settlement-delta-structures.md`).** Yeni türler `STRUCTURE_DEFS`'e girer: `yard` (`felt_yard`, `tannery`, `barter_ground`, `training_ground`), `mound` (`grain_pit`, `kiln`, `smithy`, `pit_house`, `rampart`), `ring` (`well`, `sky_pole`, `gathering_ground`), `post` (`banner_pole`, `lantern_post`), `field`; hazır ayarlar `shed` `open`, `walled`; `tower` `low`, `gate`, `granary`; `fence` `picket`, `stockade`; `yurt` `scale` alanı (`otag` 1,4: kök, nav şekli, oda ve ped birlikte ölçeklenir). Hepsi `struct_parts` ve `struct_props` programlarını kullanır.
- **Uzak yurt.** 40 m ötesinde ya da en yakın dördün dışında yurt kendi ağını gizler, `YurtField` örneğine geçer (`closed` ağ, örnek başına `aCut` yapım yüksekliği ve `aChar` yanık); 220 m ötesi 96 üçgenlik kubbe. Öteki türler aynı kuralla `KitField`'e (tür başına ≤400 üçgen kaba ağ). Aynı anda ≤48 canlı `StagedStructure`.
- **Yerleşim denetimi.** `nav.canPlace(shapes)`: geçici damga, `labelComponents`, ocak, kapılar ve zon kapıları aynı bileşende mi; sonra geri alır (≤3 ms, tıklamada bir kez).

## SA11. §3.12 Kaynak düğümleri, `NodeStore`

**Bul:** `  onDawn();                     // yenilenir, kalıcı bit kalır`
**Sonrasına ekle:**
```
  applyTaken(cluster, n);       // yerleşimin uzaktan aldığı n hakkı kümenin düğümlerinde tohumlu sırayla işaretler (kalıcı: perm, yenilenen: day); dünya kurulurken
```

**Kod bloğundan sonra ekle (paragraf):** `spec.nodes` kümeleri `id` taşır (`c_elm_bend` …); yerleşim toplama işinde kümeden aldığı hakları `settlement.taken[cluster]`'a sayar, `NodeStore` bellekte olmasa da (`settlement.md` §9.5).

## SA12. §3.13 Eşya, `Inventory`

Kap sınıfı ve ambar kaydı K24'ündür (`d2/economy-delta-architecture.md`: `Container`, `Stores`). Bu dosya yalnız yer kimliklerini ve yapı → kap eşlemesini ekler.

**Yer:** K24 ekinin `Stores` satırlarının altı (yoksa §3.13 kod bloğunun sonu).
**Ekle:**
```
// Yer kimlikleri (K23, settlement.md §3.1): 'own_seat' (yerleşim, tanhu_ordu), 'own_camp' (ana ordugâh, whistle_field), 'field_camp' (sefer).
// Kap taşıyan yapılar: grain_pit, store_yurt, shed, granary, granary_tower, treasury (yerleşim); armoury, supply_depot (ordugâh). Yapı bitince Stores.register(container, { place }).
```

## SA13. §3.17 Hızlı yolculuk ve birlik, «Act 1 kancası» paragrafının altı

**Ekle:**

**II. Perde kancası (K23).** Yerleşim `tanhu_ordu` (`own_seat`), ana ordugâh `whistle_field` (`own_camp`); ikmal kervanı `r_whistle_ordu` üstünde K24 `Caravan` kaydıdır, `CaravanOrders` sürer, dünya kurmaz: atlasta `travel.md` §10.4 minik arabasıyla görünür, varışta yük kaba yazılır. Mete kervanla giderse atlas bacağı kervanındır ve yol olayları ona sorulur; gitmezse «Yol Töresi» kendiliğinden çözer (`settlement.md` §11). `cmd_detail` erleri yerleşimin iş havuzuna girer; `cmd_camp` `CampPlan` kurar (K21 §8.3).

## SA14. §3.20 HUD ve kabuk, HudWidget satırının altı

**Bul:** `` // BuilderSystem.status'u okur (rev değişince yazar): yapı adı, adım, «3/6», fırça izi ilerlemesi, adım düğümleri, yardım ipucu. Can çubuğu yok. ``
**Sonrasına ekle:**
```
// K23: ui/hud/plan-bar.js PlanBar(ctx): id 'plan_bar', slot 'bc', modes ['play']; yalnız 'plan' bağlamı açıkken görünür.
//      Kategori şeridi, seçili yapının kartı (malzeme var/gerek, emek ve bitiş sözcüğü, bakım, kapasite, kilit nedeni).
// K23: ui/hold-ledger.js registerPage({ id: 'hold', tab: 'ledger', glyph: 'hearth', modes: { game: 6 } }): Yerleşim Defteri (settlement.md §14.2).
```

## SA15. §3.22 Yardımcı oyun servisleri

**Yer:** K21 ekinin `labour.eff(W); …` satırının altı (aynı kod bloğu).
**Ekle:**
```
// game/settlement/state.js (saf): settlement.md §18.2
export class SettlementState {
  hour(env);  dawn(env);  seasonEnd(env);  catchUp(toMin, envAt, sites);   // env: { minute, phase, season, weather, act, kut, korku, threat }
  tierCheck(act, built);  join(src, n, opts);  leave(id, reason);  levy(householdId, unitId);
  workers();  assign(job, target, n);  lock(job, min, max);  setAuto(on);  toJSON();  fromJSON(o);
}
// game/settlement/caravan-orders.js (saf): CaravanOrders { order(o); hour(env); trips(); toJSON(); fromJSON(o); }   // K24 Caravan örneklerini kurar
// game/settlement/raids.js (saf): Raids { threat(act, zone); resolve(env, rng); }
// game/settlement/camps.js (saf): CampState { hour(env); dawn(env); comfort(); plan; toJSON(); fromJSON(o); }
```

## SA16. §5 Uygulama fazları

**Yer:** Faz 8 paket tablosunun son satırının altı (K21'in 8.9, 8.10 satırlarından sonra).
**Ekle:**
```
| 8.11 | `src/data/settlement.js`, `src/game/settlement/state.js`, `src/game/settlement/households.js`, `src/game/settlement/steward.js`, `src/game/settlement/caravan-orders.js`, `src/game/settlement/raids.js`, `src/game/settlement/camps.js`, `src/game/settlement/court.js`, `src/i18n/strings/settlement.js`, `test/settlement.test.js` | Yerleşim çekirdeği, saf (`settlement.md` §5, §6, §10–§12, §15.4): hane, Kâhya, kervan buyruğu, akın, ordugâh, Divan; K24 `Container`, `Stores`, `Workshop`, `Herd`, `SupplyLedger`, `Caravan` ve K21 `SiteSystem` sözleşmeyle; `d2/settlement-model.json` ile aynı sayılar | `settlement.md` §21 saf maddeleri 1–16 |
```

**Yer:** Faz 9 paket tablosunun son satırının altı.
**Ekle:**
```
| 9.8 | `src/game/settlement/index.js`, `src/game/settlement/plan.js`, `src/world/settlement-view.js`, `src/ui/hud/plan-bar.js`, `src/ui/css/hold.css` | `SettlementSystem` (64), Plan Kipi, `YurtField`, `KitField`, parsel çıkartması; K21 kum havuzunda yerleşim kipi `?state=play&sandbox=site&hold=1` | 200 rastgele yerleşimde bağlantı kopmaz; yapay V. kademe karesi §7 satırında; program ≤92 |
```

**Yer:** Faz 10 paket tablosunun son satırının altı.
**Ekle:**
```
| 10.10 | `src/ui/hold-ledger.js`, `src/game/settlement/index.js` (Defter ve kervan bağı) | Yerleşim Defteri bütün bölümleri; kervan kum havuzunun iki ucu arasında saatle | Her bölüm dolu; kervan, Kâhya, baskın ×240 hızla 10 gün; kaydet, yükle aynı |
```

**Tablonun altına ekle (Faz 9):** `9.8, 8.11'in saf çekirdeğini ve K21 8.10'un \`SiteSystem\`'ini sözleşmeyle alır. \`keymap.build_mode\` (\`P\`): \`CONTRACT-REQUEST: src/core/keymap.js\`. \`NodeStore.applyTaken\`: \`CONTRACT-REQUEST: src/world/node-store.js\`. \`nav.canPlace\`: \`CONTRACT-REQUEST: src/game/nav.js\`.`

**Faz 12'den sonra (yeni satır, `### Faz 12` bölümünün sonuna):** `**II. Perde (Faz 13 ve sonrası).** \`specs/tanhu-ordu.js\`, \`specs/whistle-field.js\`, II. Perde hikâye klasörü ve yerleşimin açılışı (\`settlement.md\` §2) I. Perde kapandıktan sonra ayrı faz planıyla yazılır.`

**`L` satırı (Faz 9):** `` `L`: `src/app/systems.js`: `SettlementSystem` (64), `ctx.settlement`. ``

## SA17. §6.1 Test tablosu ve saf listesi

**Yer:** K21 ekinin `| \`sites\` | …` satırının altı.
**Ekle:** `| \`settlement\` | \`data/settlement\`, \`game/settlement/*\` (saf; sahte K21 \`SiteSystem\`, sahte takvim ve hava) | \`settlement.md\` §21: veri bütünlüğü, kademe, çekim, katılım, Gönül, esir yok, Kâhya, tüketim, kap ve baskın, kervan, ordugâh, toplantı, yer kuralları, atlama eşdeğerliği, kayıt boyutu, küme |`

**Saf listesine ekle:** `` `data/settlement`, `game/settlement/{state,households,steward,production,stores,caravans,camps,court}` ``

## SA18. §7 Performans bütçesi

**Yer:** `| II. Perde, Onluk, bozkır | ≈1,78M | ≈2,5M | ≈240 | ≤2 ms | \`army.md\` §7.1, kanca |` satırının altı.
**Ekle:**
```
| II+. Perde, yerleşim, Tanhu Avlusu | ≤2,04M | ≤2,74M | ≤323 | ≤3 ms | `settlement.md` §17: ≤4 tam yurt, `YurtField` 1 çizim, `KitField`, sürü örnekli ≤300; hesap ≈1,92M, ≈198 ana çizim |
| II+. Perde, ordugâh, Binlik | ≤2,04M | ≤2,74M | ≤323 | ≤3 ms | 40 tam çadır, `TentField`, ordu `army.md` §7.2 Binlik satırı |
```

**Bul (Dağılım paragrafı):** `` `Squad` ≤2 (Act 1'de ≤0,5); `Stealth` ≤0,5; ``
**Yerine:** `` `Squad` ≤2 (Act 1'de ≤0,5); `Stealth` ≤0,5; `SettlementSystem` kare başına ≤0,1, saat başına ≤0,5, 12 saatlik atlama ≤8; ``

**Bul:** `Program ≤92 (\`structures.md\`), kışta \`*_w\` ile ≤100;`
**Yerine:** `Program ≤92 (\`structures.md\`; yerleşim dünyası +7: \`yurt_field\`, \`kit_field\` ve derinlikleri, \`plan_ghost\`, \`plot_decal\`, \`field_stalk\`), kışta \`*_w\` ile ≤100;`
