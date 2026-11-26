# `architecture.md` değişiklikleri: Ekonomi (K24)

> **Yerini aldı, işlenmez (2026-11-03, K26).** `architecture.md` yalnız `d2/architecture-delta.md` birleşik defteriyle işlenir; bu dosyanın maddeleri oraya, sayıları `d2/core.md`'ye göre düzeltilerek indirildi. Dosya iz için kalır; `L` onu ikinci kez işlemez (çapalar ikinci geçişte tutmaz).

Kaynak: `d2/economy.md`. Faz 7 bitince `L` uygular. Her madde: bölüm, işlem, eski metin (birebir) ya da yer, yeni metin (tam).

**Komşu deltalarla birleşme.** Ekonomi yalnız **saf servis** verir: `Container`, tarif ve `Workshop`, sürü hesabı, ganimet çekilişi, `SupplyLedger`'ın ambar kipi. Onları süren sistemler başka alanlarındır: yerleşimin `SettlementSystem`'i, `StorePool`'u ve `CaravanBook`'u (`d2/settlement-delta-architecture.md` SA3, SA12, SA15), şantiyenin `SiteSystem`'i ve `inventory.site(id)`'si (`d2/labour-delta-architecture.md` A5), saatin şafak ve atlama olayları (`d2/time-delta-architecture.md`). Bu yüzden ekonomi yeni bir `GameSystem`, ambar kaydı ya da kervan sınıfı eklemez. Aynı satıra değen ekler: §3.13 `Inventory` bloğu (A5, SA12, bu dosyanın E8'i: üçü de «altına ekle»dir, sıra önemsiz), §6.1 saf listesi (zaman, emek ve bu dosyanın E11'i: adlar birleştirilir), §7 «Dağılım» (hava ve bu dosyanın E14'ü).

---

## E1. §1 Hedef klasör ağacı, `src/data/`

**Yer:** `  craft-recipes.js                 →8.4 Zanaat tarifleri` satırının altı.

**Ekle:**

```
  items.js                         →8.2 Malzeme, parça, bohça satırları (economy.md §2, d2/economy.md §2; d2/econ-model.json ile aynı sayılar)
  loot-tables.js                   →8.4 Düşman ganimeti (d2/economy.md §3.5)
  herd-kinds.js                    →8.4 Sürü türleri: mevsim üretimi, kesim, kış yemi (d2/economy.md §3.4)
  stations.js                      →8.4 Tezgâhlar, zanaatçı rolleri (d2/economy.md §4.2, §4.3)
```

## E2. §1 Hedef klasör ağacı, `src/game/`

**Değiştir:**

```
  craft.js                         →8.4 Tarif çözümü (saf)
  supply.js                        →8.4 SupplyLedger (saf)
```

**Yeni:**

```
  craft.js                         →8.4 Tarif çözümü; Workshop: tezgâh kuyruğu ve bekleme (saf)
  supply.js                        →8.4 SupplyLedger: soyut (Kış Hesabı) ve ambar kipi (saf)
```

**Yer:** `  barter.js                        →8.4 Terazi (saf)` satırının altı.

**Ekle:**

```
  container.js                     →8.2 Container: bütün kaplar, onda bir Yük, gün anahtarlı bozulma (saf)
  herds.js                         →8.4 Sürü hesabı: mevsim üretimi, olaylar, zud (saf; yerleşim üretimi çağırır)
  loot.js                          →8.4 Ganimet çekilişi, birim ganimeti (saf)
```

## E3. §1 Hedef klasör ağacı, `src/ui/`

**Değiştir:**

```
  css/pack.css, ledger.css         →8.7
```

**Yeni:**

```
  css/pack.css, ledger.css, transfer.css  →8.7
```

**Değiştir:**

```
  pack.js, ledger.js, barter.js, glyphs.js  →8.7 Heybe, Defter, Terazi, SVG simgeler
```

**Yeni:**

```
  pack.js, ledger.js, barter.js, glyphs.js  →8.7 Heybe (Terki sekmesi dahil), Defter, Terazi, SVG simgeler
  transfer.js                      →8.7 İki sütunlu aktarma paneli: bütün kaplar (d2/economy.md §5.2)
```

## E4. §3.5 Kayıt, blok tablosu

**Değiştir:**

```
| `economy.pack`, `.tools`, `.chest`, `.seized`, `.stash`, `.cart`, `.sled`, `.cache` | 41 | `game/inventory.js` | `travel.md` `inventory.stash` yazmaz (§8) |
```

**Yeni:**

```
| `economy.pack`, `.tools`, `.chest`, `.seized`, `.stash`, `.cart`, `.sled`, `.cache`, `.saddlebags`, `.perish` | 41 | `game/inventory.js` | `travel.md` `inventory.stash` yazmaz (§8); `economy` blok sürümü 2 (`d2/economy.md` §16). Yerleşim ve ordugâh ambarlarının içeriği `settlement` bloğundadır (order 77) |
```

## E5. §3.13 Eşya, stat, beceri: `game/items.js`

**Değiştir:**

```js
// game/items.js (saf)
ITEMS[id] = { tr, en, w10, stack, worth, tags: ['bulk','wood'], food: { fullness, buff }|null, tool: {...}|null, slot: 'feet'|null };
// Dolduran: economy.md §2 satırları + data/gear.js + data/weapons.js birleşimi
export function matches(id, ref);          // ref: 'wood_pine' | 'tag:wood'
export function itemName(id);              // L({tr,en})
```

**Yeni:**

```js
// game/items.js (saf)
ITEMS[id] = { tr, en, tier: 'raw'|'proc'|'part'|'fin'|'bundle', w10, per: 1, stack, worth, tags: ['bulk','wood'], act,
  ration: 0, fuel: 0, bundle: null, source: null, food: { fullness, buff }|null, tool: {...}|null, slot: 'feet'|null, fine: false };
// Dolduran: data/items.js (economy.md §2, d2/economy.md §2) + data/gear.js + data/weapons.js birleşimi.
// per: w10 bu kadar adedin ağırlığıdır (ok, temren, gövde 10). bundle: { id: n } teslimde açılır. source 'trade': kaynak değil takas.
export function matches(id, ref);          // ref: 'wood_pine' | 'tag:wood'; etiket ITEMS[id].tags'ten, ad öneki değil; 'x+' baseId ile
export function itemName(id);              // L({tr,en}); İnce İş: «… · İnce İş» / «… · Fine Work»
export function baseId(id);  export function isFine(id);   // 'hun_bow+' → 'hun_bow', true (d2/economy.md §2.5)
export function stackLoad10(id, n);        // ceil(n × w10 / per), onda bir Yük
export function rationOf(id);              // pay (öğün): Tokluk ÷ 35; süt 0,8, kısrak sütü 0,7, çuval 6
export function fuelOf(id);  export function bundleOf(id);
```

## E6. §3.13: `Inventory` kapları

**Yer:** `game/inventory.js` bloğunda `d2/labour-delta-architecture.md` A5'in `  site(id);  deliverTo(siteId, ref, n);` satırının altı; A5 uygulanmadıysa `  chest;  stash(way);  cart;  cache;             // { add, remove, list, load, cap }` satırının altı. `d2/settlement-delta-architecture.md` SA12'nin `store(id)`, `storePool(place)` satırlarıyla aynı yere, sıra önemsiz.

**Ekle:**

```js
  sled;  saddlebags(mountId);                    // Yük Kızağı; Terki: binek Yük'ü sınırdır (d2/economy.md §5.4)
  // Bütün kaplar (chest, stash, cart, cache, sled, saddlebags, site, store) game/container.js Container'ıdır
```

## E7. §3.13: yeni `game/container.js`

**Yer:** `game/inventory.js` kod bloğunun içinde, `Inventory` sınıfını kapatan `}` satırından sonra, `// game/derive.js (saf).` yorumundan önce.

**Ekle:**

```js
// game/container.js (saf): bütün kaplar. Yük onda bir tamsayıdır.
export class Container {
  constructor({ id, kind, cap10, slots = 0, accept = null, owner = null, hidden = false });
  id; kind; cap10; owner; hidden;
  load10();  free10();  count(ref);  has(ref, n = 1);  list();      // [{ id, n }]
  canTake(id, n);                     // → alınabilir en çok adet: Yük, yuva (yalnız Heybe), kabul süzgeci
  add(id, n, { day, allowOver });     // → { added, rest }; çiğ et ve balıkta gün anahtarı
  remove(ref, n);                     // → [{ id, n }]; etiket kabul eder; önce eski gün
  onDawn(day, { perishFish = true }); // dünkü çiğ et (ve kış dünyası dışında çiğ balık) → spoiled
  toJSON();  fromJSON(o);
}
export function transfer(from, to, ref, n);   // → { moved, rest }; olay item:move
```

## E8. §3.22 Yardımcı oyun servisleri: `SupplyLedger` ve ekonomi servisleri

**Değiştir:**

```js
// game/supply.js (saf): economy.md §7
export class SupplyLedger {
  constructor(id, { fuel, food, fodder });
  value(line);  add(line, n);  onDawn(loss);  freezeToy();  toJSON();  fromJSON(o);
}
export function ledger(id);   // kayıtlı defter: 'winter_camp'
```

**Yeni:**

```js
// game/supply.js (saf): economy.md §7; d2/economy.md §7.2
export class SupplyLedger {
  constructor(id, { mode = 'abstract', fuel, food, fodder, pool = null, need = null });
  // abstract: Kış Hesabı aynen (yüzde, sabah kaybı). store: çizgi = min(100, gün ÷ hedef × 100); hedef yiyecek 30, yakacak 30,
  // yem kışın 100 gün; pool settlement StorePool'udur (settlement.md §9.4 bağdaştırıcısı bu sınıftır)
  value(line);  add(line, n);  onDawn(loss);  freezeToy();
  consume(day, season);         // store kipi: hane payı, Ordu Payı, yakacak, kış yemi; önce bozulacak et kazana
  toJSON();  fromJSON(o);
}
export function ledger(id);   // kayıtlı defter: 'winter_camp', 'own_camp' (yerleşim), 'camp_home', 'camp_field'
export function armyShare(riders);   // Ordu Payı öğün/gün: ≤100 atlı %10, ≤1.000 %2,5, ≤3.000 %2 (d2/economy.md §7.3)

// game/craft.js (saf): tarif çözümü ve tezgâh (d2/economy.md §4). Yerleşimin production.js'i Workshop'ları sürer.
export function canCraft(recipe, { inv, station, role, skills });   // → { ok, missing }
export function craftHand(recipe, inv);                              // el işi, tutuş bitince
export class Workshop {
  constructor({ id, station, slots, crewMax });
  queue;  cures;  crew;
  order(recipeId, n, { fine });  cancel(i);
  tick(gameMin, { crewW, lit, weather, pool });    // labour.eff(W); açık bekleme yuvası yağmurda durur
  toJSON();  fromJSON(o);
}

// game/herds.js (saf): data/herd-kinds.js. Yerleşimin SettlementState'i sürüyü tutar, bu fonksiyonları çağırır.
export function herdDay(counts, season, { deepSnow, fodder, pasture });   // → { yields, labourIS, fodderUse, losses }
export function herdEvent(counts, name, season);                         // 'shear' | 'comb' | 'births' | 'sogum' → { yields, counts }

// game/loot.js (saf): data/loot-tables.js
export function roll(tableId, rng);                   // → [{ id, n } | { herd, n } | { gear }]; insan yok (K23)
export function booty(defeated, { recovery = 0.6, share });   // birim ganimeti; ambar payı %25 ya da %75
```

## E9. §5 Faz 8: paket satırları

**Değiştir:**

```
| 8.2 | `src/game/items.js`, `src/data/gear.js`, `src/game/inventory.js`, `src/i18n/strings/items.js`, `test/inventory.test.js` | `economy.md` §2, §4 | `speedK` .85, .7; el koyma istisnaları |
```

**Yeni:**

```
| 8.2 | `src/game/items.js`, `src/data/items.js`, `src/data/gear.js`, `src/game/inventory.js`, `src/game/container.js`, `src/i18n/strings/items.js`, `test/inventory.test.js`, `test/container.test.js` | `economy.md` §2, §4; `d2/economy.md` §2, §5 | `speedK` .85, .7; el koyma istisnaları; `d2/economy.md` §17 #1–#7 |
```

**Değiştir:**

```
| 8.4 | `src/game/needs.js`, `src/game/craft.js`, `src/data/craft-recipes.js`, `src/game/supply.js`, `src/game/barter.js`, `test/needs.test.js`, `test/craft.test.js`, `test/supply.test.js` | `economy.md` §5–§9 | `economy.md` §7 senaryo tablosu |
```

**Yeni:**

```
| 8.4 | `src/game/needs.js`, `src/game/craft.js`, `src/data/craft-recipes.js`, `src/data/stations.js`, `src/game/supply.js`, `src/game/barter.js`, `src/game/herds.js`, `src/data/herd-kinds.js`, `src/game/loot.js`, `src/data/loot-tables.js`, `test/needs.test.js`, `test/craft.test.js`, `test/supply.test.js`, `test/herds.test.js`, `test/loot.test.js` | `economy.md` §5–§9; `d2/economy.md` §3–§7 | `economy.md` §7 senaryo tablosu; `d2/economy.md` §17 #8–#14; `node tools/econ-sim.mjs --strict` 0 işaret, `data/*` ile `econ-model.json` aynı sayılar |
```

**Değiştir:**

```
| 8.7 | `src/ui/pack.js`, `src/ui/ledger.js`, `src/ui/barter.js`, `src/ui/glyphs.js`, `src/ui/css/pack.css`, `src/ui/css/ledger.css`, `src/ui/hud/needs.js`, `src/ui/hud/gain.js`, `src/ui/hud/bar.js` | `progression.md` §14.1, `economy.md` §4.2 | `pause` sayfaları dolu |
```

**Yeni:**

```
| 8.7 | `src/ui/pack.js`, `src/ui/ledger.js`, `src/ui/barter.js`, `src/ui/glyphs.js`, `src/ui/transfer.js`, `src/ui/css/pack.css`, `src/ui/css/ledger.css`, `src/ui/css/transfer.css`, `src/ui/hud/needs.js`, `src/ui/hud/gain.js`, `src/ui/hud/bar.js` | `progression.md` §14.1, `economy.md` §4.2, `d2/economy.md` §5.2 | `pause` sayfaları dolu; aktarma paneli TR ve EN |
```

## E10. §6.1 `node:test` tablosu

**Değiştir:**

```
| `inventory`, `needs`, `craft`, `supply`, `gather` | `game/inventory`, `game/items`, `game/needs`, `game/craft`, `game/barter`, `game/supply`, `game/gather` (çekirdek) | `economy.md` §4.1, §7 senaryo tablosu, §10 |
```

**Yeni:**

```
| `inventory`, `container`, `needs`, `craft`, `supply`, `herds`, `loot`, `gather` | `game/inventory`, `game/container`, `game/items`, `game/needs`, `game/craft`, `game/barter`, `game/supply`, `game/herds`, `game/loot`, `game/gather` (çekirdek) | `economy.md` §4.1, §7 senaryo tablosu, §10; `d2/economy.md` §17 |
```

## E11. §6.1 saf listesi

**İşlem:** saf listesinin `game/{…}` kümesine üç ad ekle: `container`, `herds`, `loot` (`items` ve `inventory`'nin yanına). Zaman (`world-clock`, `daylight`) ve emek (`labour`, `site-core`) taslaklarının eklediği adlarla tek birleşik küme yazılır; üç taslak birlikte uygulanınca küme şudur:

```
game/{cond,flags,effects,damage,save,progress,derive,items,inventory,container,needs,craft,supply,barter,herds,loot,cooking,calendar,world-clock,daylight,jobs,quests,schedule,stealth-core,agent-move,interact,camera-rig,travel-data,nav,nav-patches,labour,site-core}
```

## E12. §6.2 Statik denetim

**Yer:** `| \`node tools/check-data.mjs\` | …` satırının altı.

**Ekle:**

```
| `node tools/econ-sim.mjs --strict` | K24 denge modeli (`d2/econ-model.json`, `d2/settlement-model.json`): kimlik ve etiket tutarlılığı, bohça ağırlığı, el işi tutuşu; malzeme, yapı, kademe ve perde hedefleri; kış payı bandı; baskın kaybı; tarif Kıymet bandı; I. Perde sözleşmesi (yurt 54 birim, 146 Yük, parça biçiminin ham biçime eşitliği) |
```

## E13. §6.3 Panel tablosu, `econ` satırı

**Değiştir:**

```
| `econ` | `give, setLedger, setNeeds, dawn, nodeStats, showFootprint, ratio` (`economy.md` §12) | 8.3 |
```

**Yeni:**

```
| `econ` | `give, setLedger, setNeeds, dawn, nodeStats, showFootprint, ratio` (`economy.md` §12); `put(id, n, containerId)`, `perish()`, `craft(recipeId, n)`, `loot(tableId, seed)` (`d2/economy.md` §14). Yerleşim ambarı, sürü ve kervan `__tanhu.hold`'dadır (`settlement.md` §19) | 8.3, 8.4 |
```

## E14. §7 Performans bütçesi, «Dağılım» paragrafı

**Yer:** `` `Dialogue` ≤0,1. `` sözcüklerinden sonra; hava taslağının `` `Weather` ≤0,2 (saat sınırında ≤0,3). `` eki varsa onun arkasına.

**Ekle:**

```
Ekonomi servisleri kare başına çalışmaz: `Container.onDawn` şafakta ≤0,2 ms, `Workshop.tick` ve `herdDay` yerleşimin saat bütçesinin içindedir (`settlement.md` §17).
```
