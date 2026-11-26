# `architecture.md` değişiklikleri (K21 emek yasası)

> **Yerini aldı, işlenmez (2026-11-03, K26).** `architecture.md` yalnız `d2/architecture-delta.md` birleşik defteriyle işlenir; bu dosyanın maddeleri oraya, sayıları `d2/core.md`'ye göre düzeltilerek indirildi. Dosya iz için kalır; `L` onu ikinci kez işlemez (çapalar ikinci geçişte tutmaz).

Kaynak: `docs/design/d2/labour.md`. Faz 7 bitince baş mühendis birleştirir; birleşmede `d2/labour.md` → `docs/design/labour.md` taşınır, alan belgeleri listesine (giriş paragrafı) `labour.md` eklenir. Her madde: bölüm, değiştirilecek metin (birebir), yeni metin. Satır numaraları 2026-11-02 sürümünündür, yalnız yol göstericidir.

**Zaman taslağıyla aynı satırlar.** `d2/time-delta-architecture.md` (K20) şu satırlara da dokunur; aşağıdaki maddeler birleşik metni yazar, ikisi birlikte uygulanmaz: A9 (§3.5 Serbest Gez cümlesi) → bu dosyanın A7'si; A10 (`home` cümlesi) → A6; A18 (Faz 8 `L` satırı, paket 8.9) → A9 (bu dosyanın paketleri 8.9'u kullanmaz); A22 (karar satırları 37–40) → A12 sıradaki numarayı alır.

---

## A0. Giriş paragrafı (satır 3)

**Değiştir:** `` `act1.md`, `progression.md`, `structures.md`, `economy.md`, ``
**Yeni:** `` `act1.md`, `progression.md`, `structures.md`, `labour.md`, `economy.md`, ``

## A1. §3.11 Yapı sistemi, `StructureState` (≈1205–1210)

**Değiştir:**
```
  constructor(def, { mode, preset, startFull });
  stage; step; stepT; pools; units; burnT; contrib; fell; tears;
  advance(dtWork);  sliceTick();  deliver(item, n, who);  credit(seconds);
```
**Yeni:**
```
  constructor(def, { mode /* 'timed' | 'script' */, preset, startFull });
  stage; step; stepT; wm; rate; pools; units; burnT; contrib; fell; tears;   // wm işlenen iş dakikası; rate İD / oyun dk, sürücü yazar
  advance(wm);  deliver(item, n, who);  credit(wm);  dismantle();            // labour.md §11.2; sliceTick kalktı, credit çarpansız
```

**Değiştir:** `  setStage(n, { cause, stagger });  repairStep(dtWork, who);`
**Yeni:** `  setStage(n, { cause, stagger });  repairStep(wm, who);           // onarım emeği labour.md §7`

## A2. §3.11, `StagedStructure` (≈1216, 1220)

**Değiştir:** `  constructor(def, place, world, { mode: 'timed'|'slice', preset, startFull });`
**Yeni:** `  constructor(def, place, world, { mode: 'timed'|'script', preset, startFull });`

**Değiştir:** `  deliver(item, n, who);  credit(seconds);  repairStep(dtWork, who);  sliceTick();`
**Yeni:** `  deliver(item, n, who);  credit(wm);  repairStep(wm, who);  dismantle();`

## A3. §3.11, kod bloğundan sonra yeni blok

**Yer:** `export class StructureSystem { … }` ile biten kod bloğunun kapanışından hemen sonra, «`STRUCTURE_DEFS` ve `def.steps` biçimi» maddesinden önce.
**Ekle:**
````
```js
// game/labour.js (saf): emek yasası (labour.md §2, §5, §11.1)
export const LABOUR;                                 // DAY 1440, REAL_S_PER_MIN 2.5, B 0.9, SITE_MAX 8, ROLE_W, NIGHT, REPAIR, HAUL …
export function eff(W);                              // min(W, 10·(1 − 0,9^W))
export function crewOn(step, members, out);          // → { heads, W, lead, usta, mete }: adımın max'ına dek en ağır üyeler
export function stepRate(step, crew, env);           // → iş dakikası / oyun dakikası; solo, usta, gece, hava, tokluk, su, beceri
export function etaMinutes(state, members, envAt);   // → oyun dakikası
export function simulate(state, minutes, { membersAt, envAt, stockAt });   // saat dilimli toplu benzetim (uyku, atlama, dönüş)
export function haulWork(load, d, carrier);          // → İD (labour.md §6.3)
export function etaWords(nowMin, etaMin);            // → { dayKey, timeKey }

// game/site-core.js (saf) ve game/sites.js: şantiye (labour.md §6, §11.5)
export class SiteSystem {        // GameSystem; id 'sites', order 61; ctx.sites
  beginPlacement(kind, opts);  place(kind, opts);  get(id);  list();
  assign(siteId, workerIds);  release(workerId);  order(siteId, { night, priority, dismantle });  deliver(siteId, item, n, who);
  update(dt, t);  onSkip(fromMin, toMin);  catchUp(minutes);  collectInteractions(q, out);
  toJSON();  fromJSON(o);        // world.sites (order 76)
}
```
````

## A4. §3.11 maddeleri

**Değiştir:**
```
- **Usta** `game/builders.js` zaman çizelgesine bağlıdır: takılan usta inşaatı kilitlemez (`structures.md` §10.2).
```
**Yeni:**
```
- **Usta** `game/builders.js` emek çizelgesine bağlıdır: oran `labour.stepRate`'ten, takılan usta inşaatı kilitlemez (`structures.md` §10.2). Saat durunca emek durur, saat atlayınca `simulate` toplu işler (`labour.md` §6.8).
```

**Değiştir (Faz 6 entegrasyonu, «Usta.» maddesinin ilk cümlesi):**
```
- **Usta.** Yardım tablosu tektir: `game/builders.js` `HELP` (`structure-defs.js`'teki kopya kalktı).
```
**Yeni:**
```
- **Usta.** Yardım tablosu tektir: `game/builders.js` `CHILD_HELP` (`labour.md` §9.3: katılma işleri ve ayak işleri; kredi kalktı). Ekip Oktar, Erka, Dengiz baştan sona; katılan Çocuk 0,5 ağırlık ve bir baştır; gece `G_TORCH` direkleri.
```

**Yer:** §3.11 maddelerinin sonu (Faz 6 entegrasyonu listesinden sonra).
**Ekle:**
```
**K21 emek yasası.** Süre saniye değil emektir: adımın `work` alanı iki elle iş dakikası (İD), `solo` tek el çarpanı, `min`–`max` el sınırı; tanımda `craft` (`home`, `wood`, `earth`) ve `crewMax`. Oranı yalnız sürücü yazar (camp3'te `BuilderSystem`, ötekilerde `SiteSystem`, ana kampın A, B, ahır, çitinde yapının yedeği: iki el); `StructureState` yalnız tüketir. Kışlak Yeni Yurdu `mode: 'timed'`'dır, `SiteSystem` saat, ekip, malzeme ve hikâye kapısıyla sürer (`labour.md` §10). Sayılar `labour.md` ve `labour-model.json`.
```

## A5. §3.13 Eşya, stat, beceri, `Inventory`

**Değiştir:** `  chest;  stash(way);  cart;  cache;             // { add, remove, list, load, cap }`
**Yeni:**
```
  chest;  stash(way);  cart;  cache;             // { add, remove, list, load, cap }
  site(id);  deliverTo(siteId, ref, n);          // şantiye yığını, aynı yüz; cap türün malzeme yükü × 1,25 (labour.md §6.3)
```

## A6. §3.7 sistem tablosu ve `home` cümlesi

**Yer:** aşağıdaki satırın altı:
```
| 60 | `structures` | `world/structure.js` | ikisi |
```
**Ekle:**
```
| 61 | `sites` | `game/sites.js` | ikisi, home |
```

**Değiştir:**
```
`ikisi` `freeroam` ve `play` demektir. `home`'da yalnız `mount`, `child`, `structures` çalışır.
```
**Yeni** (zaman taslağının A10'uyla birleşik):
```
`ikisi` `freeroam` ve `play` demektir. `home`'da yalnız `mount`, `child`, `structures`, `sites` ve iğneli `clock` çalışır.
```

## A7. §3.5 Kayıt, blok tablosu ve Serbest Gez cümlesi

**Yer:** aşağıdaki satırın altı:
```
| `world.npcs` | 74 | `game/npcs.js` | |
```
**Ekle:**
```
| `world.sites` | 76 | `game/sites.js` | Şantiyeler, dünya (`zone`) başına; bitmiş sağlam yapı sıkı dizi; ordugâh çadırları `CampPlan`; ≤16 KB (`labour.md` §14) |
```

**Değiştir:**
```
**Serbest Gez** ayrı bloktur: `{ schema:1, camp3, camp:{structures}, child:{pos,yaw,weapon,sit?}, mood, flags, playTime }`,
```
**Yeni** (zaman taslağının A9'uyla birleşik):
```
**Serbest Gez** ayrı bloktur: `{ schema:1, camp3, camp:{structures}, child:{pos,yaw,weapon,sit?}, clock:{day,minute}, flags, playTime }` (`camp3` kendi `v: 2` sürümünü taşır, göç `labour.md` §14; `mood` artık yazılmaz, okunursa saate göç eder: >0,75 akşam 18:38, değilse menü dakikası 14:46,2),
```

## A8. §3.22 Yardımcı oyun servisleri

**Yer:** `campfire.place(x, z, { stones });  campfire.feed(id, fuelS);  campfire.nearest(x, z, r);  campfire.rest(id);` satırının altı (aynı kod bloğu).
**Ekle:**
```
// game/labour.js (saf): emek yasası; §3.11 bloğu. Yerleşim, ordu ve ekonomi iş gücünü bu birimle sayar: bir yetişkin bir oyun gününde 1 iş günü (1.440 İD)
labour.eff(W);  labour.stepRate(step, crew, env);  labour.etaMinutes(state, members, envAt);  labour.haulWork(load, d, carrier);
```

## A9. §5 Faz 8, paket tablosu ve `L` satırı

**Yer:** `| 8.8 | …` satırının altı.
**Ekle:**
```
| 8.L1 | `src/game/labour.js`, `src/world/structure-defs.js`, `src/world/structure-logic.js`, `src/world/structure.js`, `src/game/builders.js`, `src/ui/hud/build-status.js`, `src/i18n/strings/structures.js`, `test/labour.test.js`, `test/structure-logic.test.js`, `test/builders.test.js` | K21 emek yasası; Faz 6 kodunun yeniden çalışması (`labour.md` §12): `work`, `solo`, `min`, `max`, `advance(wm)`, `CHILD_HELP`, Dengiz baştan sona, öğün sırası, `SHELTER`, `G_TORCH`, HUD ekip ve «≈N saat» satırı; K20 saatine bağlanır | `labour.md` §15 maddeleri; camp3 saatsiz 1.338 sn ±10, 14:54 saatiyle 1.405 sn ±15, bütün yardımla 1.125 / 1.181 sn; `menuDiff` 0; program ≤92 |
| 8.L2 | `src/game/site-core.js`, `src/game/sites.js`, `src/world/site-pad.js`, `src/i18n/strings/sites.js`, `test/sites.test.js` | Şantiye: yerleşim, yığın ve taşıma, ekip atama, gece ve hava kesintisi, çalışma atlaması, söküm, `world.sites` kaydı; kum havuzu `?state=play&sandbox=site` (`labour.md` §6, §11.5) | `labour.md` §15 `sites` maddeleri; Kışlak benzetimi §10.1 tablosunu ±2 oyun dk verir |
```
**Tablonun altına ekle:**
```
Paket numaraları birleşmede verilir (zaman taslağı 8.9'u aldı). 8.L1 zaman taslağının 8.9 paketine (`WorldClock`, `daylight`, `clock:skip`) sözleşmeyle bağlanır; aynı fazda paralel yürür, dosya paylaşmaz. 8.L2 `inventory.site(id)`'yi 8.2'den (§3.13), `labour.js`'i 8.L1'den sözleşmeyle alır. Defter'in yapı sayfası 8.7'nindir (`ui/ledger.js`), veriyi `ctx.sites.list()`'ten okur. `keymap.rotate` (öneri `R`): `keymap.js` zaman taslağının 8.9 paketindedir, eylem o pakete eklenir (`CONTRACT-REQUEST: src/core/keymap.js`).
```

**Faz 8 `L` satırı:** zaman taslağının A18 metnine (`clock` 15, `camp_life` 81, `ctx.worldClock`, `ctx.calendar` …) parantez içinde `sites` 61 ve `ctx.sites` eklenir; zaman taslağı uygulanmazsa satır şöyle olur:
```
`L`: `src/app/systems.js`, `src/app/app.js`: yeni sistemler ve `ctx` alanları; `SiteSystem` (61), `ctx.sites`.
```

## A10. §6.1 Test tablosu ve saf listesi

**Değiştir:**
```
| `structure-logic` | `world/structure-logic`, `world/structure-defs` (yardım toplamı `game/builders` `HELP`'ten) | `structures.md` §5.3, §6.1; `progression.md` §17.1 #11, #12 |
| `builders` | `game/builders` (sahte aktör ve sahte yapı, gerçek `StructureState`), `character/gestures/build`, `i18n/strings/structures` | `structures.md` §10, §11.6: yardımsız 590 sn ±5, bütün yardımlarla ≥283 sn, takılan usta en çok 6 sn bekletir; dizgeler TR ve EN |
```
**Yeni:**
```
| `structure-logic` | `world/structure-logic`, `world/structure-defs` (emek `labour-model.json` ile aynı) | `structures.md` §5.3, §6.1; `progression.md` §17.1 #11, #12; `labour.md` §7 onarım emekleri |
| `builders` | `game/builders` (sahte aktör ve sahte yapı, gerçek `StructureState`), `character/gestures/build`, `i18n/strings/structures` | `structures.md` §10, §11.6: saatsiz yardımsız 1.338 sn ±10, Çocuğun bütün yardımıyla 1.125 sn ±10; 14:54 saatiyle ve öğünle 1.405 ve 1.181 sn ±15; Dengiz her adımda, 22:00'de kalır, takılan usta en çok 6 sn bekletir; dizgeler TR ve EN |
| `labour` | `game/labour` | `labour.md` §15 maddeleri 1–15: `eff` tablosu, tek el 1.440 İD, ekip çizelgesi, iki el, önder ve usta kuralı, gece, hava, onarım, taşıma, toplu benzetim eşdeğerliği, söküm, bitiş sözcüğü |
| `sites` | `game/site-core` (saf), `game/sites` (sahte dünya) | `labour.md` §15: yerleşim nedenleri, yığın tüketimi, 150 m taşıma, gece emri, çalışma atlaması, kayıt gidiş dönüş, Kışlak benzetimi |
```

**Değiştir (saf listesi içinde):** `` `game/{cond,flags,effects,damage,save,progress,derive,items,inventory,needs,craft,supply,barter,cooking,calendar,jobs,quests,schedule,stealth-core,agent-move,interact,camera-rig,travel-data,nav,nav-patches}` ``
**Yeni:** `` `game/{cond,flags,effects,damage,save,progress,derive,items,inventory,needs,craft,supply,barter,cooking,calendar,jobs,quests,schedule,stealth-core,agent-move,interact,camera-rig,travel-data,nav,nav-patches,labour,site-core}` ``

## A11. §7 Performans bütçesi, «Dağılım» paragrafı

**Değiştir:** `` `StructureManager` ≤0,5; `Squad` ≤2 ``
**Yeni:** `` `StructureManager` ≤0,5; `SiteSystem` ≤0,1 (toplu benzetim bir oyun günü, 24 şantiye ≤0,3 ms, atlamada); `Squad` ≤2 ``

**Aynı paragrafın sonuna ekle:**
```
camp3 inşaatında Dengiz baştan sona: +28k üçgen, +6 çizim, Faz 6'nın ölçülen en kötü karesiyle +245k, +41 (tavan +250k, +45); meşale direkleri `frame`'de, çizim ve ışık eklemez (`labour.md` §13).
```

## A12. §8 Kararlar ve uzlaştırma, yeni satır

**Yer:** tablonun son satırı altı; numara birleşmede sıradaki boş numaradır (zaman taslağı 37–40'ı istedi).
**Ekle:**
```
| (sıradaki) | K21, `structures.md` §10.3, §11.6 | Faz 6 süreyi saniye ve krediyle sayıyordu (camp3 590 sn, yardımla 283 sn; kredi kalan süreyi 3 kat eritiyordu) | Emek yasası `game/labour.js`: adımın `work` iş dakikası, oran ekipten (`eff(W) = min(W, 10·(1 − 0,9^W))`, el sınırı, tek el çarpanı); `StructureState.advance(wm)`; kredi kalkar, Çocuk ekibe yarım el olarak katılır; Kışlak dilim kipi kalkar | K21; kurulum, onarım, taşıma ve söküm tek birimle, yerleşim ve ordu aynı yasayla sayılır (`labour.md`) |
```
