# `structures.md` değişiklikleri: Ekonomi (K24)

> **Yerini aldı, işlenmez (2026-11-03, K26).** `structures.md` yalnız `d2/structures-delta.md` birleşik defteriyle işlenir; bu dosyanın maddeleri oraya, sayıları `d2/core.md`'ye göre düzeltilerek indirildi. Dosya iz için kalır; `L` onu ikinci kez işlemez (çapalar ikinci geçişte tutmaz).

Kaynak: `d2/economy.md` §6, §13. Faz 7 bitince birleşir. Emek taslağının (`d2/labour-delta-structures.md`) `dur`, `crew` → `work`, `min`, `max` değişikliğiyle aynı satırlara değer; bu belgenin eklediği alanlar (`parts`, `rawWork`, `rawRole`) onunkilerle yan yana durur, birini ötekine bağlamaz. Malzeme toplamları (a1) değişmez.

---

## S1. §2.2 Veri biçimi: adımın parça biçimi

**İşlem:** satırı değiştir (kod bloğunun içi).

**Eski metin:**

```js
      cost: { 'tag:wood': 8, rope: 2 }, mat: 'lattice', hp: 45,
```

**Yeni metin:**

```js
      cost: { 'tag:wood': 8, rope: 2 }, mat: 'lattice', hp: 45,
      parts: { kerege_set: 1 }, rawWork: 720, rawRole: 'cr_carpenter',   // K24: parça gelirse cost karşılanmış sayılır; ham gelirse adıma rawWork İD eklenir
```

**İşlem:** kod bloğunun altına paragraf ekle. **Yer:** `` `StructureManager` (`world.structures`) listeyi tutar `` ile başlayan paragraftan önce.

**Yeni metin:**

```
**Parça ve ham biçim (K24, `d2/economy.md` §6.1).** `cost` a1 ham biçimidir ve değişmez. `parts` aynı adımın II. Perde ve sonrası bileşen biçimidir: teslim edilen parça `cost`'u bütünüyle karşılar. Şantiyeye ham mal gelirse adımın emeğine `rawWork` İD eklenir (bileşen tarifinin İS'i × 60) ve `rawRole` varsa ekipte o zanaatın ustası aranır, yoksa `labour.md` `K_usta` ×0,7 işler. Bohça (`yurt_kit`, `tent_kit`) teslimde açılır. Etiket çözümü `matches(id, ref)` iledir (`architecture.md` §3.13), ad öneki değil.
```

## S2. §3.1 Yurt adımları: parça biçimi notu

**İşlem:** satırdan sonra paragraf ekle. **Yer:** tablonun `| **Toplam** | | | **590** | …` satırından sonra.

**Yeni metin:**

```
**Parça biçimi (K24).** `y_bosaga` `parts: { door_frame: 1 }`, `rawWork: 360`; `y_kerege` `parts: { kerege_set: 1 }`, `rawWork: 720`, `rawRole: 'cr_carpenter'`; `y_uuk` `parts: { uuk_set: 1 }`, `rawWork: 480`; `y_liner` `parts: { chiy: 1 }`, `rawWork: 120`. Tündük, sırık, keçe, ip ve köz zaten eşyadır. Parça biçimi bir düzey açılınca bu tablonun malzemesidir (54 birim, 146 Yük); `tools/econ-sim.mjs` sınar. Kışlak'ta (`preset: 'winter'`) ham teslim kuralı aynen: Nanay'ın eli parçayı yerinde yapar.
```

## S3. §4.4 Araba: parça biçimi

**İşlem:** paragrafın sonuna cümle ekle.

**Eski metin:**

```
**Act 1.** Araba kurulmaz, yalnız kırılır ve onarılır: `uStage` 0/1 (`travel.md` §3.3 "Kırık aşama"). Yeni araba kurmak II. Perde'dir.
```

**Yeni metin:**

```
**Act 1.** Araba kurulmaz, yalnız kırılır ve onarılır: `uStage` 0/1 (`travel.md` §3.3 "Kırık aşama"). Yeni araba kurmak II. Perde'dir. O zaman `c_axle` `parts: { wheel_pair: 1, 'tag:wood': 1, iron_bar: 1 }`, `rawWork: 600`, `rawRole: 'cr_cartwright'`: teker çifti Ağaç Atölyesi'nin usta işidir (`d2/economy.md` §4.4); iki teker sert odundansa (`tag:wood_hard`) araba canı +%25. Büyük arabaların malzemesi `d2/economy.md` §6.2.
```

## S4. §7 Onarım: «Malzeme» satırı

**İşlem:** satırı değiştir.

**Eski metin:**

```
| Malzeme | `economy.md` §6.3. Yama: maliyet × 0,5 × eksik can oranı. Yeniden kaldırma: aşama maliyetinin yarısı, `repair` ile `repairCost` ¼, `repairTime` ×0,5; yukarı yuvarlanır. Demir, tündük, köz düşüşte kurtarılır. `y_tunduk` 3 kişi şartı kalır. Yanık birim +%25 |
```

**Yeni metin:**

```
| Malzeme | `economy.md` §6.3. Yama: maliyet × 0,5 × eksik can oranı. Yeniden kaldırma: aşama maliyetinin yarısı, `repair` ile `repairCost` ¼, `repairTime` ×0,5; yukarı yuvarlanır. Demir, tündük, köz düşüşte kurtarılır. `y_tunduk` 3 kişi şartı kalır. Yanık birim +%25. **Onarım her zaman ham biçimle (`cost`) hesaplanır, parça istemez**: düşen kerege kanadı 4 odun ve 1 iple kalkar (`d2/economy.md` §6.3) |
```

(«`y_tunduk` 3 kişi şartı» cümlesini emek taslağı «iki el» yapar; iki değişiklik aynı satırda birleşir.)

## S5. §15 Sonraki perde kancaları

**İşlem:** satırı değiştir, satır ekle.

**Eski metin:**

```
| Erzak (istek 12) | `deliver` Kış Hesabı ile aynı eşya kimliklerini kullanır; yapı bir tüketici, `ledger` düşmez, ambar düşer |
```

**Yeni metin:**

```
| Erzak (istek 12) | `deliver` Kış Hesabı ile aynı eşya kimliklerini kullanır; yapı bir tüketici, `ledger` düşmez, ambar düşer. II. Perde'den yerleşim ambarı `Container`'dır; şantiye 150 m içindeki ambardan kendi taşır (`d2/labour.md` §6.3, `d2/economy.md` §5) |
```

**Yer:** `| Ana kamp | camp3 bittikten sonra …` satırından sonra.

**Yeni metin:**

```
| Göç ve ganimet (K23, K24) | Sağlam yurdun sökümü 1 `yurt_kit` verir (60 Yük: bir keçe araba ya da iki deve); yeni yerde aynı yurt bohçadan kalkar. Kaçan düşmanın bıraktığı sağlam yurt sökülüp ganimet olur (`d2/economy.md` §3.5, §3.7) |
| Kap yapıları (K24) | `store_yurt` 400, `granary` 600, `granary_tower` 800, `grain_pit` 120 (baskında bulunmaz), `shed` 500, `treasury` 120, `armoury` 200, `supply_depot` 600 Yük: içerik yapının `toJSON`'unda değil yerleşimin `settlement` bloğundadır (`StorePool`, `settlement.md` §9, §16); yapı aşama 2'nin altına inerse sandık ve ambar içeriği yer yığınına, yanarsa tablodaki pay yiter (`d2/economy.md` §5.1) |
```
