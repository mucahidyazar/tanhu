# Envanter, Malzeme, Zanaat ve Denge / Inventory, Materials, Crafting and Balance (K24)

> **İşlendi (2026-11-03).** Bu taslak `economy.md`'ye işlendi; bağlayıcı olan odur. Taslak iz için kalır; `L` onu işlemez.

> **Baş tasarımcı notu (2026-11-03).** Kesişen sayılar ve kurallar `d2/core.md` §5'tedir ve bu taslakla çeliştiği yerde kazanır (yer ve defter kimlikleri, sürücü yerleşimdir, `EconomySystem` yok, düz %10 Ordu Payı, tek baskın kuralı, belirli ganimet, `baseId`, bozulma kuralı, hava tepkilerinin sahipleri, kademe günü hedefleri, `dayCapacity`). Bu taslak sonraki adımda `economy.md`'ye işlenirken `d2/core.md` §8 uygulanır.

Taslak (`d2`), 2026-11-02; Faz 7 bitince birleşir. Alan: tek malzeme taksonomisi; kaynaklar ve oranlar (düğüm, av, sürü, savaş ganimeti, takas); işleme zincirleri ve tarifler; tezgâhlar ve zanaatçılar; kaplar ve aktarma; yapıların malzeme listeleri; hane ve ordu tüketimi; perde perde tempo; yeniden koşulabilir denge modeli. Bağlayanlar: `decisions.md` K1–K19 ve yönetmen kararları K20–K24; bu belge K24'ü ayrıntılandırır, tersine çevirmez. Kimlikler ve kod İngilizce, oyun içi metinler TR / EN ve bu belge için yeni yazıldı (Tanhu 1 ve Tanhu 3'ten alınmaz).

**Makine okunur kopya.** Bütün sayılar `docs/design/d2/econ-model.json` içindedir. Bu belgedeki türetilmiş tablolar `node tools/econ-sim.mjs` çıktısıdır (§9) ve betikle buraya yazıldı. Sayı değişince önce JSON değişir, sim yeniden koşulur, sonra belge. Bugünkü sonuç: **0 işaret**, `--strict` çıkış kodu 0.

**Komşu taslaklar okundu ve uyuldu.** `d2/labour.md`, `labour-model.json` (K21): emek birimi İD, İS, İG; `eff(W)`; yapı türleri, adları ve İG'leri; şantiye yığını, 150 m kendi taşıması; gece ve hava çarpanları. Bu belgenin İS'si emeğin İS'sidir: zanaat ve yapı tek emek havuzundan ödenir (`labour.md` §18 soru 3'ün yanıtı). `d2/time.md` (K20): şafak olayı, atlamada sistemler, Tokluk'un saat oranı, sırığın 2 oyun saati. `d2/weather.md` (K22): hava kimlikleri, ıslaklık, çamur, kar örtüsü; o belge bu modelin `params.actSeason`, `params.seasonDays`, `stations.drying_rack` alanlarını okur, bu adlar sabit tutuldu. `d2/settlement.md`, `settlement-model.json` (K23): kademe adları ve bileşimi, yapı kataloğu, `StorePool`, kervan, baskın, bakım, ordugâh kademeleri; o taslak bu modelin malzeme listelerini, tariflerini ve hane sayılarını almıştır. Sim kademe bileşimini ve baskın sıklığını `settlement-model.json`'dan okur (§9). Yerleşimin eklediği on yapının malzemesi burada onaylandı (Gök Direği'nde bir düzeltmeyle, §6.2).

**Değişmeyen.** I. Perde'nin bütün sayıları: Kış Hesabı (`economy.md` §7), a1 tarifleri ve tutuşları (`act1.md` §9.1), Yeni Yurt'un 54 birim ve 146 Yük malzemesi, Kıymet tablosu, düğüm ve araç tabloları. Tek ek: büyük avda kemik ve iç yağı (§3.3). Sim bu sözleşmeyi her koşuda sınar (§9).

`architecture.md`, `structures.md`, `audio.md` Faz 7 boyunca düzenlenmez: değişiklikleri birebir metinle `d2/economy-delta-architecture.md`, `d2/economy-delta-structures.md`, `d2/economy-delta-audio.md` dosyalarındadır. Öteki belgelerin değişiklik listesi §12.

## 0. Sütunlar ve karar özeti

| Sütun | Kural | Oyuncunun yaşadığı |
|---|---|---|
| Elin çabuktur, yurt zamanla kalkar | Mete'nin el işi sıkışıktır (≈50×), tezgâh işi ve kurma sıkışmaz (§1.2) | Toplamak ve küçük işi yapmak saniyelerdir; parça ustayı, yapı ekibi ve günü ister |
| Bir yurt bir arabaya sığar | Yurt Yükü 60 Yük: bir keçe araba ya da iki deve (§2.3) | Göç, armağan, ganimet ve takas aynı eşyadır |
| Kış yazın sayılır | Yerleşimin Kış Hesabı saklananla %75–115 (§7.2) | Yazın kurut, güzün soğum; kışın sürek avı, takas, akın |
| Ganimet paylaşılır | Ambar payı paylaşılırsa %25, alıkonursa %75 ve Sadakat −10 (§3.5) | Hazine ile sadakat arasında seçim |
| Defter büyür, çizgiler aynıdır | `SupplyLedger` ambar kipi: Yiyecek, Yakacak, Yem, Ok (§7.2) | Rehineyken saydığın üç çizgi, hanken dört çizgidir |
| Kalite teçhizattadır, yığın sadedir | Kalite yalnız teçhizatta: İnce İş (§2.5) | Heybe ve ambar tek kimlikle sayılır |

| # | Karar | Sayı | Neden |
|---|---|---|---|
| E24-1 | **Tek taksonomi, beş kademe:** Ham, İşlenmiş, Parça, Mamul, Bohça; sürü ayrı sayıdır | 21 yeni kimlik; `economy.md` §2 kimlikleri aynen | Ham maldan yapıya ve teçhizata tek yol; I. Perde kimlikleri korunur |
| E24-2 | Yük onda bir tamsayı kalır; adetli küçük eşyada `per: 10` | Ok, temren, gövde: 10 adet 0,5 Yük | `progression.md` §7.3'ün 0,05 Yük'ü onda birle yazılamıyordu |
| E24-3 | Emek İS'tir (`labour.md` E1); bekleme oyun saatidir (K20); tutuş gerçek saniyedir | 1 İS = 2,5 gerçek dk tek işçiyle | Zanaat, toplama ve kurma tek emek havuzundan ödenir |
| E24-4 | **İki hız:** el işi ≈50× sıkışık, tezgâh, usta ve kurma işi sıkışmaz | Yurdun tezgâh işi 42,3 İS: Mete yapsa 106 gerçek dk | Var olan sayıların sonucu (§1.2); oyuncunun dakikası en kıt kaynaktır |
| E24-5 | **Kalite en çok iki kademe, yalnız teçhizatta:** Olağan ve İnce İş (`+`) | Ana değer ×1,1; emek ×1,5 ve +1 asıl malzeme; Kıymet ×1,5 | Malzeme ve yemekte kalite yığını böler, defteri bulandırır |
| E24-6 | Yurt **parça biçiminde** kurulur (bosağa, kerege takımı, uuk demeti, tündük, çiy, keçe, ip); ham mal da teslim edilebilir, o zaman adımın emeği parçanın İS'i kadar artar | Parça biçimi bir düzey açılınca a1 ham biçimine eşittir (sim sınar) | II. Perde'de zanaat görünür olur, I. Perde değişmez |
| E24-7 | **Yurt Yükü** (`yurt_kit`) bohçadır: yurdun bütün parçaları, teslimde açılır | 60 Yük, Kıymet 240 | Göç (`labour.md` §6.9), armağan, ganimet |
| E24-8 | NPC oranları `economy.md` §8.3 Erzak Kolu'dur; dilim 6 oyun saati (K20) | Kütük 2,5 İS, ot 1,5 İS, cevher 5 İS | Var olan tablo; tek kaynak |
| E24-9 | Ortak ürün (av, kesim) emeği Kıymet payıyla bölünür | Ceylan: deri %22, et %33, sinir %22 | Tutarlı fiyat, keyfî atama yok |
| E24-10 | Sürü baş başına mevsimli üretir; soğum, kırkım, doğum olaydır; derin kar günü yem ister | Hane ≈18 at eşdeğeri, 5 kişi | Bozkır ekonomisinin asıl kaynağı sürüdür (Shiji 110) |
| E24-11 | Ganimet düşman türüne göre çekilir; **esir yoktur** (K23); at sürüye gider | Atlıdan %30–50 at | Hun savaşının kazancı at ve demirdir |
| E24-12 | Kap tek sınıftır (`Container`): heybe, terki, sandık, şantiye yığını, yerleşim ve ordugâh kapları; yerin kaplarını yerleşimin `StorePool`'u birleştirir | Kapasiteler §5.1 | Tek API, tek kayıt biçimi (`architecture.md` §3.13); paralel ambar sistemi yok |
| E24-13 | **Ordu Payı ölçekle düşer:** ordugâh atlısı × %10 (≤100), %2,5 (≤1.000), %2 (≤3.000) | Oba 10, Boy Yurdu ve Toy Yeri 25, Tanhu Avlusu 60 öğün/gün (Göçer ×1,1) | Büyük ordu kendi boyunun sürüsüyle beslenir; düz %10 Tanhu Avlusu'nu kışın aç bırakıyordu (§7.3) |
| E24-14 | `SupplyLedger` ambar kipi: çizgi = gün ÷ hedef; yiyecek ve yakacak 30 gün, yem kışın 100 gün | Yiyecek ≥35 → `K_tok` 1 (`labour.md` §5) | Defter aynı kalır, sayı ambar içeriğinden gelir (`settlement.md` §9.4 ile aynı) |
| E24-15 | Kıymet a1 kalır; yeni eşyada girdi + 0,75 × İS; bilerek kayıplı tarifler listelidir | Bant 0,85–1,6 | Takasta döngü kurulmaz |
| E24-16 | Hedefler: malzeme saniyesi, yapı dakikası ve İG'si, kademe günü ve dakikası, perde dakikası (%25 tavan) | §8.1 | K24 |
| E24-17 | Model ve sim: `econ-model.json`, `tools/econ-sim.mjs` | 0 işaret | Yeniden koşulabilir denge |
| E24-18 | Tezgâhlar emek ve yerleşim taslaklarının yapılarıdır: Keçe Avlusu, Sepi Yeri, Ağaç Atölyesi, Demirci Ocağı, Fırın, Okçu Yurdu; kazan ve sırık yapı değil | 11 tezgâh | Paralel yapı listesi kurulmaz |
| E24-19 | Zanaatçı rolü (`cr_*`) öğretmen ustadan ayrıdır; usta işi rol ister | 8 rol, iki derece | Yerleşimde insan aranır (`labour.md` E6 ile aynı ruh) |
| E24-20 | Hava ve saat ekonomiye çarpan ve durak verir, soğuk modellenmez (K1) | §11 | K20, K22 |
| E24-21 | Ekonomi **saf servis** verir (`Container`, `Workshop`, sürü hesabı, ganimet, `SupplyLedger` ambar kipi); onları yerleşimin `SettlementSystem`'i, `StorePool`'u ve `CaravanBook`'u sürer | Yeni `GameSystem` yok | Paralel sistem kurulmaz (`settlement.md` §18) |

## 1. Birimler ve iki hız

### 1.1 Birimler

| Ölçü | Değer | Kaynak |
|---|---|---|
| Yük | `economy.md` birimi; içeride onda bir tamsayı (`w10`). Yeni eşya ağırlığı için gizli ölçü 1 Yük ≈ 5 kg (kütük 4 ≈ 20 kg) | `economy.md` §2 |
| Adetli küçük eşya | `per: 10`: `w10` on adedin ağırlığıdır; yığının yükü `ceil(n × w10 / per)` onda bir | Ok 0,05 Yük (`progression.md` §7.3) |
| Oyun saati | 1 oyun günü = 24 oyun saati = 60 gerçek dk; 1 oyun saati = 2,5 gerçek dk | K20 |
| İD, İS, İG | İş dakikası, iş saati (60 İD), iş günü (24 İS). JSON'da İS alanı `wh` | `labour.md` E1 |
| Bir yetişkin | Günde 1 İG (24 İS) verir; açık hava işi gece ×0,4: gündüz 16 sa + gece 8 sa × 0,4 = 19,2 İS (×0,8). Işıklı atölye ve şantiye gece de ×1 | `labour.md` §1, §5.1; `time.md` §10.4 programı 06–22 |
| Bekleme (kür) | Oyun saati; tezgâhın bekleme yuvasını tutar, oyuncuyu bekletmez | K20 |
| Tutuş | Gerçek saniye; yalnız el işi; en çok 8 sn | `economy.md` §6.1 |
| Kıymet | Gizli; a1 ölçüsü korunur; yeni eşyada girdi Kıymeti + 0,75 × İS | `economy.md` §9.1 |
| Pay (öğün) | 1 öğün = 1 kişi-gün = 0,1 Yük (`meal`) | `army.md` §3.6 |

### 1.2 İki hız: el ve emek

**Var olan sayıların sonucu, yeni kural değildir.** Mete araba ile on kütüğü 69 sn'de keser ve taşır (`economy.md` §10.2): kütük başına ≈6 gerçek sn = 2,4 oyun dk = 0,04 İS. Erzak Kolu on işçiyle bir dilimde (6 oyun saati, 60 İS) 24 kütük getirir (`economy.md` §8.3): kütük başına 2,5 İS. Oran ≈54; ot 66, cevher 37. Ortalama ≈50 (`params.handRatio`).

| İş | Mete | NPC | Neden |
|---|---|---|---|
| Toplama (vuruş, tutuş) | Gerçek saniye, sıkışık | İS (Erzak Kolu oranı) | Oyuncunun eli oyunun eylem katmanıdır |
| El tarifi (ip, keçe, sırık, ok) | Tutuş 1–8 sn | İS (`wh`) | `economy.md` §6.1: bekleten sayaç yok |
| Tezgâh ve usta işi (kerege, külçe, yay) | Bir işçi: 1 İS = 1 oyun saati = 2,5 gerçek dk | Aynı | K21: Mete bir işçidir (`labour.md` E6) |
| Kurma | Bir işçi, `labour.md` | Aynı | K21 zaman çizelgesi |

Yurdun tezgâh ve usta işi 42,3 İS'tir: Mete tek başına yapsa 106 gerçek dakika. Oyuncu toplar ve küçük işi yapar; parçayı usta, yapıyı ekip kurar. Erken kademede (II. Perde açılışı) usta azdır: ilk yurtlar armağan ve ganimet Yurt Yükü ile, ilk usta ile kurulur (§8.3).

## 2. Malzeme taksonomisi

### 2.1 Kademeler ve kimlik kuralları

| Kademe | id | TR / EN | Ne | Örnek |
|---|---|---|---|---|
| Ham | `raw` | Ham / Raw | Toplanır, avlanır, sağılır, kırkılır, yağmalanır | `wood_pine`, `hide`, `wool`, `iron_scrap` |
| İşlenmiş | `proc` | İşlenmiş / Processed | Bir tarifle ham maldan; kendi başına alınıp satılır | `rope`, `felt`, `leather`, `charcoal`, `iron_bar` |
| Parça | `part` | Parça / Component | Yapıya, araca, teçhizata girer; kendi başına kullanılmaz | `kerege_set`, `wheel_pair`, `arrowhead_iron` |
| Mamul | `fin` | Mamul / Finished | Kullanılır, giyilir, yenir, atılır | `hun_bow`, `arrow_iron`, `cauldron` |
| Bohça | `bundle` | Bohça / Bundle | Parçaların taşıma biçimi; şantiyede açılır | `yurt_kit`, `tent_kit` |
| Sürü | `herd` | Sürü / Herd | Sayıdır, kaba girmez (`economy.md` §9.4) | `sheep`, `horse` |

- Kimlikler `economy.md` §2, §5.2, `progression.md` §6–§7 ile birdir; yeni kimlik yalnız §2.3'tedir.
- **Etiket** `ITEMS[id].tags` alanıdır; `tag:x` isteyen yere etiketi taşıyan her eşya gider. Kodun bugünkü ad öneki kuralı (`tag:wood` → `wood_*`, `structure-logic.js`) yalnız oduna yeter; çözüm `matches(id, ref)` olur (`architecture.md` §3.13; §13).
- Yeni alanlar: `tier`, `per`, `ration` (pay), `fuel` (Yakacak), `bundle`, `source` (`trade`: kaynak değil takas). Biçim `d2/economy-delta-architecture.md`.

### 2.2 Etiketler

| Etiket | TR / EN | Eşyalar | Okuyan |
|---|---|---|---|
| `wood` | Odun / Wood | `wood_pine`, `wood_juniper`, `wood_willow`, `wood_birch`, `wood_elm`, `wood_tamarisk` (+3) | Yapı ve tarif «odun»u; ad öneki kuralının yerine |
| `wood_light` | Hafif odun / Light wood | `wood_willow`, `wood_birch`, `wood_tamarisk`, `wood_poplar` | Kerege (+%10 can), ok gövdesi, eyer kaşı |
| `wood_hard` | Sert odun / Hardwood | `wood_elm`, `wood_saxaul`, `wood_larch` | Teker (+%25 araba canı) |
| `fuel` | Yakacak / Fuel | `wood_pine`, `wood_juniper`, `wood_willow`, `wood_birch`, `wood_elm`, `wood_tamarisk` (+7) | Ateş, Yakacak çizgisi |
| `tinder` | Kav / Tinder | `resin`, `birch_bark`, `reed` | Ateş kavı (survival.md §2) |
| `fiber` | Lif / Fibre | `reed`, `wool`, `hair` | İp, çiy |
| `forage` | Kaba yem / Forage | `hay`, `straw` | Yem Bağı |
| `tan` | Sepi katkısı / Tanning agent | `salt`, `fat`, `milk` | Sepi |
| `herb` | Ot / Herb | `herb_wormwood` | Yahni, çay |
| `berry` | Yemiş / Berry | `berry_buckthorn` | Yemiş keki |
| `food` | Yiyecek / Food | `berry_buckthorn`, `meat`, `meat_small`, `fish`, `milk`, `mare_milk` (+7) | Pay hesabı, Tahıl Ambarı kabulü |
| `grain` | Tahıl / Grain | `millet`, `barley_sack`, `grain_sack` | Tahıl Ambarı kabulü |
| `meat` | Et / Meat | `meat`, `meat_small` | Kazan |
| `ore` | Cevher / Ore | `ore_copper`, `ore_iron`, `ore_tin` | Ocak |
| `metal` | Külçe / Metal | `tin_ingot`, `iron_bar`, `bronze_bar` | Ocak, Silahlık |
| `scrap` | Hurda / Scrap | `bronze_scrap`, `iron_scrap` | Yeniden dövme |
| `gem` | Taş / Gem | `turquoise_raw`, `jade_raw` | Takas |
| `fur` | Kürk / Fur | `fur_fox`, `fur_wolf`, `fur_sable` | Kürk çizme, takas |
| `hide` | Ham deri / Hide | `hide` | Ham deri işleri |
| `fletch` | Tüy / Fletching | `feather` | Ok |
| `shaft` | Gövde / Shaft | `arrow_shaft` | Ok |
| `head` | Temren / Head | `arrowhead_bone`, `arrowhead_bronze`, `arrowhead_iron` | Ok |
| `arrow` | Ok / Arrow | `arrow_bone`, `arrow_bronze`, `arrow_iron` | Ateşli ve ıslıklı ok, Silahlık kabulü |
| `bulk` | Sırt yükü / Bulk | `wood_pine`, `wood_juniper`, `wood_willow`, `wood_birch`, `wood_elm`, `wood_saxaul` (+10) | Heybe Sırt sekmesi |
| `trade` | Ticaret malı / Trade good | `silk_bolt`, `wine_jar` | Takas |
| `gear` | Teçhizat / Gear | `felt_coat`, `hide_lamellar`, `bronze_scale`, `iron_lamellar`, `war_cape`, `riding_boots` (+18) | Silahlık kabulü, İnce İş |
| `key` | Görevlik / Key | `ember` | Satılmaz, el konmaz |
| `valuable` | Değerli / Valuable | `turquoise_raw`, `jade_raw`, `gold_dust`, `fur_sable`, `silk_bolt`, `gold_old` (+2) | Hazine ve Ambar Çukuru kabulü (`settlement.md` §9.1) |

### 2.3 Yeni kimlikler

| id | TR / EN | Kademe | Yük | Yığın | Kıymet | Kaynak | Perde | Neden |
|---|---|---|---|---|---|---|---|---|
| `wood_larch` | Melez Odunu / Larch Log | Ham | 4 | 8 | 4 | `node_larch` | III | Hangay ve Hentiy ormanı; Noin-Ula odaları melezdir |
| `madder` | Kökboya / Madder Root | Ham | 0,1 | 20 | 2 | `node_madder` | II | Kızıl boyanın kökü; `war_cape` «boya»sı |
| `hair` | Kıl / Hair | Ham | 0,2 | 30 | 1 | Sürü (tarama, kırkım), ganimet atı | II | Kıl ipi bozkırın ipidir |
| `iron_scrap` | Demir Hurda / Iron Scrap | Ham | 0,5 | 10 | 3 | Ganimet (§3.5) | II | Zırh ve silah kırığı; 4 → 1 külçe |
| `fur_sable` | Samur Kürkü / Sable Fur | Ham | 0,2 | 5 | 40 | `sable` avı, Dingling takası | VI | VI. Perde kuzey ticareti |
| `felt_white` | Ak Keçe / White Felt | İşlenmiş | 1 | 10 | 9 | `rc_felt_white` | II | Otağ ve Ak Keçe pelerini |
| `leather` | Sepi Deri / Tanned Leather | İşlenmiş | 1 | 10 | 11 | `rc_leather` | II | Sepi zinciri: ham deri yalnız ham deri işine |
| `glue` | Tutkal / Glue | İşlenmiş | 0,1 | 20 | 2 | `rc_glue`, `rc_glue_fish` | II | Bileşik yay ve eyer kaşı |
| `dye` | Kızıl Boya / Red Dye | İşlenmiş | 0,1 | 20 | 5 | `rc_dye` | II | Kızıl Pelerin, otağ |
| `door_frame` | Bosağa / Door Frame | Parça | 8 | 1 | 32 | `rc_door_frame` | II | Yurdun 1. aşaması |
| `kerege_set` | Kerege Takımı / Lattice Set | Parça | 14 | 1 | 47 | `rc_kerege_set` | II | Yurdun 2. aşaması (kuşak hariç) |
| `uuk_set` | Uuk Demeti / Roof Pole Bundle | Parça | 16 | 1 | 54 | `rc_uuk_set` | II | Yurdun 4. aşaması |
| `chiy` | Çiy / Reed Screen | Parça | 3 | 2 | 8 | `rc_chiy` | II | Yurdun 5. aşaması; keçe avlusunun yuvarlama hasırı |
| `crown_great` | Ulu Tündük / Great Crown | Parça | 10 | 1 | 62 | `rc_crown_great` | III | Otağın tündüğü |
| `wheel_pair` | Teker Çifti / Pair of Wheels | Parça | 6 | 1 | 16 | `rc_wheel_pair` | II | Her araba; Pazyryk parmaklı tekeri |
| `saddle_tree` | Eyer Kaşı / Saddle Tree | Parça | 1,5 | 2 | 13 | `rc_saddle_tree` | II | Ağaç ve savaş eyeri |
| `arrow_shaft` | Ok Gövdesi / Arrow Shaft | Parça | 0,05 | 60 | 0,35 | `rc_shafts`, `rc_shafts_branch` | II | Ok zinciri |
| `arrowhead_bone` | Kemik Temren / Bone Arrowhead | Parça | 0,05 | 60 | 0,35 | `rc_heads_bone` | II | Ok zinciri |
| `arrowhead_bronze` | Tunç Temren / Bronze Arrowhead | Parça | 0,05 | 60 | 1 | `rc_heads_bronze` | II | Kalıpta döküm üç kanatlı temren |
| `arrowhead_iron` | Demir Temren / Iron Arrowhead | Parça | 0,05 | 60 | 1,6 | `rc_heads_iron` | II | Dövme temren |
| `yurt_kit` | Yurt Yükü / Packed Yurt | Bohça | 60 | 1 | 240 | Söküm, `rc_yurt_kit`, armağan, ganimet, takas | II | Göç ve taşıma: bir keçe araba ya da iki deve |
| `tent_kit` | Çadır Yükü / Packed Tent | Bohça | 16 | 1 | 42 | Söküm, `rc_tent_kit` | II | Onluk çadırı |
| `ember_pot` | Köz Kabı / Ember Pot | Mamul | 1 | 1 | 15 | `rc_ember_pot` | II | Köz Kabı: ocaktan ocağa köz (`settlement.md` §2.1 `mq2_own_hearth`) |

**Yurt Yükü.** Bosağa 8, kerege takımı 14, tündük 6, iki sırık 3, uuk demeti 16, çiy 3, altı keçe 6, sekiz ip 4: 60 Yük. Bir keçe araba (60) ya da iki yük devesi (2 × 30) bir yurdu taşır; Yüksek Teker (80) yurdu ve sahibinin eşyasını. İskit ve Pazyryk araba verisiyle aynı ölçek (`travel.md` §3.1; Hunların kendi göç arabası için doğrudan kanıt yok). Teslimde bohça açılır, parçalar şantiye yığınına girer (§5.2).

### 2.4 Var olan kimliklerde değişen

| id | Değişen | Neden |
|---|---|---|
| `hide` | Anlamı netleşir: ham deri (rawhide). Sapan, keçe eyer, toynak sargısı, deri dilimli zırh, kule korkuluğu, teker bağı buradan; yumuşak deri işi `leather` ister | I. Perde anlamı kalır; sepi zinciri II. Perde'de açılır |
| `tin_ingot` | Kademe `proc`, `source: trade`: II–III'te yalnız takas; IV'te `rc_tin_ingot` | `economy.md` §2.4 tarih kapısı |
| `arrow_bone`, `arrow_bronze`, `arrow_iron` | Kıymet 1,3; 1,9; 2,5. `per: 10`, 10 adet 0,5 Yük | Kıymet yoktu |
| `milk`, `mare_milk` | Pay 0,8 ve 0,7 | Hane ölçeğinde süt yazın asıl yiyecektir: 1 süt ≈2,5 litre |
| `barley_sack`, `grain_sack` | Pay 6 | `economy.md` §9.4 «6 öğün» |
| `charcoal` | Kıymet 3 kalır; `rc_charcoal` bilerek kayıplı (§4.6) | a1 takas dengesi |
| Öteki yiyecekler | Pay = Tokluk ÷ 35 (`economy.md` §8.3 `toFood`) | Değişmez |

### 2.5 Kalite: en çok iki kademe, yalnız teçhizatta

| Kural | Değer |
|---|---|
| Kademeler | Olağan / Common ve İnce İş / Fine Work |
| Hangi eşya | Ana değeri olan teçhizat: kılıç, süngü, topuz, yay, gövde zırhı, miğfer, kolluk, eyer, at zırhı, sadak |
| Kim yapar | Kendi zanaatında **Usta** derecesindeki zanaatçı (§4.3), siparişte «İnce İş» seçilince |
| Bedel | Emek ×1,5; +1 asıl malzeme (yay +1 sinir, kılıç +1 demir külçe, zırh +1 sepi deri, eyer +1 sepi deri) |
| Etki | Ana değer ×1,1 (hasar, DR, sadak kapasitesi, eyer etkisi); Kıymet ×1,5 |
| Kimlik | `id+` (`hun_bow+`); `baseId` çözümü; ad «Hun Yayı · İnce İş» / «Hun Bow · Fine Work» |
| Ganimet, takas | Ganimet olağandır (adlı hikâye eşyası hariç); satıcı İnce İş satmaz |
| Malzeme, parça, yiyecek | **Kalite yok.** `survival.md` §3 yıldızı yalnız ateş başında hemen yenince geçer; heybeye giren yemek olağandır (★2) |

**Neden.** Malzemede kalite yığını böler (üç `felt`, üç `meat`), ambar defterini ve taşıma hesabını çoğaltır, kaydı büyütür. Dönemin gerçek farkları zaten ayrı kimliktir: ham deri ve sepi deri, keçe ve ak keçe, kemik ve tunç temren. Teçhizatta tek kademe ise yerleşimin ustalarına somut bir ödül verir ve oyuncunun kendi kitinde fark edilir; zorunlu değildir.

### 2.6 Yığın, ağırlık, bozulma

- **Yığın** yalnız Heybe yuvası içindir (`economy.md` §4.2); öteki kaplarda yuva yoktur, sınır Yük'tür.
- **Ağırlık** onda bir tamsayı; `per` eşyasında yığının yükü yukarı yuvarlanır.
- **Bozulma:** çiğ et ve çiğ balık 1 günde bozulur (`survival.md` §3). Kap, bozulan eşyayı gün anahtarıyla iki parça tutar (bugün, dün); şafakta dünkü parça `spoiled` olur. Edinme dakikası yerine gün anahtarı: kayıt küçük, sonuç aynı (`time.md` §7.4). Kış dünyasında balık donuktur ve bozulmaz (`economy.md` §5.2 «Çiğ, donmuş»): dünya kuralıdır (`spec.perish`), oyuncuya soğuk mekaniği değildir (K1).

## 3. Kaynaklar ve oranlar

### 3.1 Toplama

**II. Perde ve sonrası düğümleri** (`economy.md` §3.2 kuralıyla; I. Perde tablosu aynen).

| id | Nesne TR / EN | İstem TR / EN | Araç | Eylem | Verim × hak | Yenilenme | Perde |
|---|---|---|---|---|---|---|---|
| `node_birch` | Huş / Birch | Kes / Fell | Balta | 5 vuruş tunç, 4 demir | 3 `wood_birch` + 1 `birch_bark` × 1 | Kalıcı | II |
| `node_elm` | Karaağaç / Elm | Kes / Fell | Balta | 6 tunç, 5 demir | 3 `wood_elm` × 1 | Kalıcı | II |
| `node_tamarisk` | Ilgın / Tamarisk | Kes / Cut | Balta ya da `knife_iron` | 3 vuruş | 4 `wood_tamarisk` × 1 | Kalıcı | II |
| `node_saxaul` | Saksavul / Saxaul | Kır / Break | Balta | 4 vuruş | 2 `wood_saxaul` × 1 | Kalıcı | II |
| `node_larch` | Melez / Larch | Kes / Fell | Balta | 6 tunç, 5 demir | 3 `wood_larch` × 1 | Kalıcı | III |
| `node_quarry` | Taş Ocağı / Quarry Face | Kır / Break | Kazma | 3 tunç, 2 demir | 1 `stone` × 6 | Şafak, boy ×0,8 | II |
| `node_madder` | Kökboya / Madder | Sök / Dig Up | El | 2 sn | 2 `madder` × 1 | Şafak | II |
| `node_poplar`, `node_vein_tin`, `node_vein_turquoise`, `node_placer_gold` | `economy.md` §3.2 son paragrafı | | `pick_iron` | | | | IV |

**Birim başına emek ve saniye.** Mete sütunu II. Perde ölçüsüdür (demir balta ve kazma, Bilek 5, yakın küme, araba); İşçi İS `1 / npcPerWh`.

| Eşya | TR / EN | Mete sn | İşçi İS | Düğüm | Perde |
|---|---|---|---|---|---|
| `wood_pine` | Çam Odunu / Pine Log | 6 | 2,5 | `node_pine` | I |
| `wood_juniper` | Ardıç Odunu / Juniper Log | 7 | 2,86 | `node_juniper` | I |
| `wood_willow` | Söğüt Odunu / Willow Log | 5 | 2,22 | `node_willow` | I |
| `wood_birch` | Huş Odunu / Birch Log | 6 | 2,86 | `node_birch` | II |
| `wood_elm` | Karaağaç / Elm Log | 7 | 3,03 | `node_elm` | II |
| `wood_tamarisk` | Ilgın / Tamarisk Stem | 4 | 1,67 | `node_tamarisk` | II |
| `wood_saxaul` | Saksavul / Saxaul Log | 8 | 3,33 | `node_saxaul` | II |
| `wood_larch` | Melez Odunu / Larch Log | 7 | 3,03 | `node_larch` | III |
| `wood_poplar` | Toğrak / Desert Poplar Log | 6 | 2,5 | `node_poplar` | IV |
| `branch` | Dal / Branch | 1,5 | 0,5 | `node_deadfall` | I |
| `resin` | Reçine / Resin | 3 | 1 | `node_resin` | I |
| `birch_bark` | Huş Kabuğu / Birch Bark | 2 | 0,5 | `node_birch` | II |
| `stone` | Taş Blok / Stone Block | 10 | 4 | `node_scree`, `node_boulder`, `node_quarry` (II) | I |
| `clay` | Kil / Clay | 5 | 2 | `node_clay` | I |
| `salt` | Tuz / Salt | 6 | 2,5 | `node_salt` | I |
| `reed` | Saz / Reed | 2 | 0,67 | `node_reed` | I |
| `madder` | Kökboya / Madder Root | 2 | 1,25 | `node_madder` | II |
| `herb_wormwood` | Yavşan / Wormwood | 1,5 | 1 | `node_wormwood` | I |
| `bark_willow` | Söğüt Kabuğu / Willow Bark | 2 | 1 | `node_willow` | I |
| `berry_buckthorn` | Topalak / Sea Buckthorn | 1 | 0,5 | `node_buckthorn` | I |
| `ore_iron` | Demir Cevheri / Iron Ore | 15 | 5 | `node_vein_iron` | I |
| `ore_copper` | Bakır Cevheri / Copper Ore | 15 | 5 | `node_vein_copper` | I |
| `ore_tin` | Kalay Cevheri / Tin Ore | 18 | 6,67 | `node_vein_tin` | IV |
| `turquoise_raw` | Ham Firuze / Rough Turquoise | 30 | 20 | `node_vein_turquoise` | IV |
| `gold_dust` | Altın Kumu / Gold Dust | 20 | 10 | `node_placer_gold` | IV |
| `hay` | Ot / Hay | 1,5 | 1,5 | `node_hay` | I |
| `straw` | Saman / Straw | 1,5 | 1 | `node_straw` | I |
| `dung` | Tezek / Dung Fuel | 3 | 0,5 | `node_dung` | I |
| `fish` | Balık / Fish | 6 | 2 | `node_fish_spot` | I |
| `millet` | Darı / Millet | – | 0,5 | `millet_field` | V |

**Çevre tükenir.** Ağaç ve kaya kalıcıdır (`economy.md` §14 karar 3): yerleşim büyüdükçe yakın orman açılır, kol uzağa gider. Kademe başına çevre katsayısı işçi toplama hızını çarpar: 1; 1; 0,85; 0,7; 0,6 (§8.3). Yakın kaynağı bitmiş yerleşim kervanla ve takasla beslenir: konum kararı ekonomiktir.

### 3.2 Biyom

Yerleşimin yeri (K23) neyin yakında olduğunu söyler. Tasarım tercihi, dönem bitki ve hayvan dağılımına dayanır.

| Biyom | Bol | Az | Yok | Örnek dünya (`travel.md` ZONES) |
|---|---|---|---|---|
| Orman bozkırı | Melez, huş, çam; maral, karaca, ayı | Saz | Saksavul | Hangay, Hentiy, Orhun yukarısı |
| Irmak vadisi | Söğüt, karaağaç, toğrak (IV), saz, kil, kökboya, balık, kaz | Taş | | Tula, Kerulen, Hey Irmağı |
| Bozkır | Tezek, ot, taş, ceylan, tarbagan, kurt, toy kuşu | Odun | | Tanhu avlusu çevresi |
| Gobi, Alaşan | Saksavul, ılgın, tuz, kulan, deve | Ot | Saz | `whistle_field` yolu, Alaşan |
| Dağ | Cevher, taş, ardıç, yaban keçisi, argali | Ot | | Çilyan, Yin, Altay eteği |

### 3.3 Av

`survival.md` §4 kuralları aynen; verim tablosu genişler. «(+)» bu belgenin ekidir: büyük avın kemiği ve marala iç yağı. I. Perde etkisi küçüktür: kemik zaten Mutfak Artığı ve Çukur'da boldur.

| id | TR / EN | Perde | Mete dk | Av kolu İS | Verim ((+) bu belgenin eki) | Biyom |
|---|---|---|---|---|---|---|
| `crow` | Karga / Crow | I | 0,4 | 1 | 2 `feather` | Kamp, otlak |
| `hare` | Tavşan / Hare | I | 0,5 | 3 | 1 `meat`, 1 `hide_small` | Otlak, sazlık |
| `marmot` | Tarbagan / Marmot | I | 0,5 | 3 | 1 `meat`, 1 `fat`, 1 `hide_small` | Otlak, yamaç |
| `partridge` | Keklik / Partridge | I | 0,4 | 2 | 1 `meat_small`, 2 `feather` | Yamaç |
| `fox` | Tilki / Fox | I | 1 | 8 | 1 `fur_fox` | Otlak, sazlık |
| `gazelle` | Ceylan / Gazelle | I | 2 | 22 | 3 `meat`, 1 `hide`, 2 `sinew`, 1 `horn`, 2 `bone` (+) | Bozkır, Gobi kenarı |
| `ibex` | Yaban Keçisi / Ibex | I | 2,5 | 26 | 3 `meat`, 1 `hide`, 2 `horn`, 2 `sinew`, 2 `bone` (+) | Dağ |
| `boar` | Domuz / Boar | I | 2 | 22 | 4 `meat`, 2 `fat`, 1 `hide`, 2 `bone` (+) | Orman, sazlık |
| `deer` | Maral / Red Deer | I | 2,5 | 26 | 4 `meat`, 1 `hide`, 2 `sinew`, 1 `antler`, 3 `bone` (+), 1 `fat` (+) | Orman bozkırı |
| `wolf` | Kurt / Wolf | I | 1,5 | 15 | 1 `fur_wolf`, 1 `sinew`, 1 `bone` (+) | Her yer |
| `argali` | Argali / Argali | II | 3 | 30 | 4 `meat`, 1 `hide`, 2 `horn`, 2 `sinew`, 3 `bone`, 1 `fat` | Dağ, Gobi Altay |
| `kulan` | Kulan / Wild Ass | II | 3 | 30 | 5 `meat`, 2 `hide`, 2 `sinew`, 3 `bone`, 1 `fat` | Gobi, Alaşan |
| `bustard` | Toy Kuşu / Great Bustard | II | 1 | 6 | 1 `meat`, 4 `feather` | Bozkır |
| `goose` | Kaz / Goose | II | 0,8 | 3 | 2 `meat_small`, 4 `feather` | Göl, ırmak |
| `roe` | Karaca / Roe Deer | III | 1,5 | 15 | 2 `meat`, 1 `hide`, 1 `sinew`, 1 `bone` | Orman bozkırı |
| `bear` | Ayı / Bear | III | 4 | 40 | 6 `meat`, 2 `hide`, 2 `sinew`, 4 `bone`, 4 `fat` | Hangay, Hentiy ormanı |
| `sable` | Samur / Sable | VI | 1,5 | 10 | 1 `fur_sable` | Tayga (Dingling) |

- **Ortak ürün.** Bir avın dakikası ürünlere Kıymet payıyla bölünür (sim, `huntUnit`). Ceylan: et %33, deri %22, sinir %22, boynuz %17, kemik %6.
- **Av kolu.** On avcı bir dilimde 8 et, 2 deri, 1 boynuz getirir (`economy.md` §8.3); bu belge satıra 4 kemik, 4 sinir, 1 iç yağı ekler (ceylanın tablosuyla tutar).
- **Bölge sayacı.** `survival.md` §4: günde %30 geri gelir. Bölge stoğu büyük avda bozkır 40, dağ 25, orman 30; küçük av ×3. Sürdürülebilir av günde stoğun %30'udur; fazlası o bölgeyi boşaltır, yavrulu sürü kırılırsa Korku +1 (aynen).

### 3.4 Sürü

Sürü yerleşimin ve ordunun kaydında sayıdır. Baş başına günlük ortalama, mevsime göre:

| id | TR / EN | At eşd. | Çoban başına | Doğum/yıl | Kesim/yıl | Süt/gün (bahar/yaz/güz/kış) | Kırkım (baş başına) | Kıl/yıl | Tezek/gün | Kesimde | Kış yemi/gün (olağan/derin kar) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `sheep` | Koyun / Sheep | 0,15 | 120 | %45 | %20 | 0,04/0,08/0,05/0 `milk` | bahar 1, güz 0,5 `wool` | – | 0,1 | 6 `meat`, 1 `hide`, 2 `bone`, 1 `fat` | 0,02 / 0,1 |
| `goat` | Keçi / Goat | 0,12 | 120 | %50 | %20 | 0,05/0,1/0,06/0 `milk` | – | 0,5 | 0,08 | 4 `meat`, 1 `hide`, 2 `bone` | 0,02 / 0,08 |
| `horse` | At / Horse | 1 | 40 | %20 | %4 | 0,1/0,25/0,15/0 `mare_milk` | – | 0,5 | 0,6 | 18 `meat`, 2 `hide`, 6 `bone`, 2 `sinew`, 2 `hair`, 1 `fat` | 0,05 / 0,5 |
| `cattle` | Sığır / Cattle | 1 | 50 | %25 | %10 | 0,25/0,5/0,3/0 `milk` | – | – | 1 | 20 `meat`, 2 `hide`, 6 `bone`, 2 `sinew`, 2 `horn`, 2 `fat` | 0,1 / 0,6 |
| `camel` | Deve / Camel | 1,3 | 30 | %12 | %5 | 0,15/0,3/0,15/0,05 `milk` | bahar 1 `hair` | – | 0,5 | 24 `meat`, 3 `hide`, 8 `bone`, 2 `sinew`, 3 `fat` | 0,05 / 0,3 |

| Olay | Zaman (`time.md` takvimi) | Ne olur | Emek |
|---|---|---|---|
| Sağım / Milking | Bahar–güz, günde iki kez (06:00, 19:00) | Süt ve kısrak sütü ambara | 0,2 İS süt, 0,25 İS kısrak sütü |
| Kırkım / Shearing | Bahar sonu (koyun 1 yün, deve 1 kıl), güz başı (koyun 0,5 yün) | Yün ve kıl ambara | Koyun başına 0,5 İS |
| Tarama / Combing | Bahar | Keçi ve at kılı | Baş başına 0,5 İS |
| Doğum / Births | Bahar | Sürü yıllık doğum payı kadar büyür | |
| Ot biçimi / Haymaking | Yaz sonu | Kış yemi için ot | `hay` 1,5 İS |
| Soğum / Winter Slaughter | Güz sonu | Koyun ve keçinin %10'u, sığırın %8'i, atın %5'i kesilir; et kurutulur, kışa yayılır (%20 kayıp) | Küçükbaş 2 İS, büyükbaş 6 İS |
| Derin kar / Deep Snow | Kış; payı hava taslağının (model 0,15) | Yem ister (tablo); yem yoksa o gün beslenmeyen sürünün %2'si yiter, kışta en çok %30 (zud) | Yemleme |
| Kesim / Butchering | Yıl boyu | Yıllık kesim payı | Aynı |

- **Çobanlık** gece de sürer (gece nöbeti): çoban başına 24 İS (`herderPer`).
- **Otlak** `economy.md` §8.4 modeli bütün sürüye genişler: at eşdeğeri (`lu`) ile sayılır. Otlak bitince yem kış gibi işler.
- **Ordu atı.** Birliğin `remounts`'u sürü sayısıdır; ganimet atı önce ordugâh sürüsüne girer (§3.5).

### 3.5 Savaş ganimeti

**Kişi ölçeği.** Yere düşmüş (ölü ya da baygın) düşmanda «Ara / Search», 1,5 sn: tablo çekilir (tohumlu). At kaçar; `herd_habit` ve `horse_call` ile 60 sn içinde yakalanırsa ordugâh sürüsüne geçer. **Esir yoktur** (K23): Shiji 110'un 虜'su oyunda mal değildir.

| Düşman | Perde | Çekiliş (adet, olasılık) |
|---|---|---|
| `guard_yuezhi` | I | 1 `hide` %30; 1 `bronze_scrap` %20 |
| `rider_hun` | I | 4–8 `arrow_bone` %100; 1 `felt` %30; 1 `bronze_scrap` %25; 1 horse (sürüye) %35 |
| `guard_hun` | II | 1–2 `hide` %40; 1–2 `iron_scrap` %40; 1 `bronze_scrap` %30; `ring_sword` %8 |
| `rider_donghu` | III | 4–8 `arrow_bronze` %100; 1 `hide` %30; 1 `fur_fox` %15; 1 `bronze_scrap` %40; 1 horse (sürüye) %40 |
| `elite_donghu` | III | 6 `arrow_bronze` %100; 2–3 `bronze_scrap` %80; 1–2 `iron_scrap` %40; 1 horse (sürüye) %50; `iron_sword` %10 |
| `lancer_yuezhi` | IV | 2–3 `iron_scrap` %60; 1 `hide` %30; 1 horse (sürüye) %45 |
| `archer_saka` | IV | 8–12 `arrow_bronze` %100; 1 `felt` %30; 1 `bronze_scrap` %40; 1 horse (sürüye) %30 |
| `foot_han` | V | 2–4 `iron_scrap` %70; 1 `hide` %20; `han_sword` %10 |
| `xbow_han` | V | 1–2 `iron_scrap` %50; 6–12 `bolt` %100; `han_crossbow` %6 |
| `guard_elite` | VI | 2–4 `iron_scrap` %80; 1–2 `hide` %40; 1 horse (sürüye) %50 |
| `han_wagon` | V | 4–6 `grain_sack` %100; 2–4 `iron_scrap` %80; 10–20 `bolt` %60; 1–2 cattle (sürüye) %60 |

**Birim ölçeği.** Akından sonra ganimet havuzu = Σ (yenilen × beklenen değer) × 0,6 toplanan payı. Shiji 110 #12: «aldığı ganimet kendisinindir» (`army.md` §1). Mete'nin kararı:

| Karar | Ambara | `army.md` §3.5 olayı |
|---|---|---|
| Paylaş / Share (`booty_share`) | %25: atlar, oklar, hurda | Sadakat +8, Moral +6 |
| Alıkoy / Keep (`booty_keep`) | %75 | Sadakat −10, Moral −4, Korku +1 |

**Düşman başına beklenen değer** (sim):

| düşman | P | Kıymet | demir külçe | at | ok | silah |
|---|---|---|---|---|---|---|
| guard_yuezhi | I | 4,8 | 0,00 | 0,00 | 0,0 |  |
| rider_hun | I | 129,9 | 0,00 | 0,35 | 6,0 |  |
| guard_hun | II | 10,2 | 0,15 | 0,00 | 0,0 | ring_sword %8 |
| rider_donghu | III | 154,8 | 0,00 | 0,40 | 6,0 |  |
| elite_donghu | III | 205,2 | 0,15 | 0,50 | 6,0 | iron_sword %10 |
| lancer_yuezhi | IV | 158,1 | 0,38 | 0,45 | 0,0 |  |
| archer_saka | IV | 126,1 | 0,00 | 0,30 | 10,0 |  |
| foot_han | V | 7,9 | 0,52 | 0,00 | 0,0 | han_sword %10 |
| xbow_han | V | 2,3 | 0,19 | 0,00 | 9,0 | han_crossbow %6 |
| guard_elite | VI | 180,0 | 0,60 | 0,50 | 0,0 |  |
| han_wagon | V | 175,2 | 0,60 | 0,00 | 9,0 |  |

**Yağmalanan kamp.** Düşman kampının ambarı kültür tablosuyla çekilir: Tunghu kürk ve at, Yüeçi keçe, demir hurda ve firuze, Han arabası tahıl, demir hurda ve arbalet oku. Kaçanın bıraktığı sağlam yurt «Sök» ile Yurt Yükü olur (`labour.md` §6.9): ganimet olarak ev de alınır, insan alınmaz.

### 3.6 Takas

Kural `economy.md` §9 aynen: para yok, Kıymet gizli, Terazi, satıcı istediğini satmaz, satıcılar arası kâr ≤%11. II. Perde'den satıcı satırları (öneri; kişi adları perde içeriğinindir):

| id | Kim, nerede | Perde | Stok (şafak) | İster |
|---|---|---|---|---|
| `vendor_tanhu_market` | Tanhu avlusunun pazarı | II–III | `millet` ×10, `salt` ×4, `rope` ×8, `felt` ×6, `iron_bar` ×2, `tin_ingot` ×1, `yurt_crown` ×1; haftada bir `yurt_kit` | `wool`, `hair`, `hide`, `fur_*`, `horn`, `sinew`, at |
| `vendor_qiang_salt` | Çiang tuzcusu (Yuan'ın kervanı) | II–IV | `salt` ×10, `ore_copper` ×4, `herb_sleep` ×1 | `felt`, `meal`, `dried_meat`, `qurt` |
| `vendor_saka` | Saka tüccarı | IV | `tin_ingot` ×3, `bronze_bar` ×4, `turquoise_raw` ×2, `saka_bow` ×1, `gorytos` ×1 | At, `felt_white`, `fur_fox`, `leather` |
| `vendor_oasis` | Hexi vahası | IV | `grain_sack` ×6, `jade_raw` ×1, `dye` ×4, `madder` ×6 | `felt`, `hide`, at, koyun |
| `vendor_han_border` | Sınır pazarı (heqin sonrası) | VI | `grain_sack` ×12, `silk_bolt` ×4, `wine_jar` ×2, `iron_bar` ×4 | At, koyun, `fur_*`, `hide`, `felt` |
| `vendor_dingling` | Dingling kürkçüsü | VI | `fur_sable` ×4, `wood_larch` ×8 | `iron_bar`, `bronze_bar`, `millet` |

### 3.7 Söküm ve kurtarma

| Durum | Dönen | Kaynak |
|---|---|---|
| Sağlam yurdun sökümü | 1 `yurt_kit`; köz söner | `labour.md` §6.9 (emek kurmanın 0,35'i) |
| Eksik yurdun sökümü | Ayaktaki birimlerin parçaları; düşmüş ve yanmış birimin malzemesi yoktur | |
| Öteki yapılar | Ayaktaki adımların ham malzemesinin yarısı | |
| Yıkıntı (aşama 0'a inmiş) | Düşen aşamaların ham malzemesinin %25'i, yer yığını olarak | `structures.md` §5.7 döküntüsü |

## 4. İşleme zincirleri ve tarifler

### 4.1 Kurallar

1. **Kim.** `hand` el işidir: Mete tutuşla, NPC İS ile; `station` tezgâh ister; `master` tezgâh ve o zanaatın zanaatçısını (`role`) ister. Mete usta işinde yardım eder (İS'i sayılır), başlatamaz.
2. **El işi** en çok 8 sn tutuş (a1 kuralı); yemek pişirme `survival.md` §3 süreleridir, tutuş değil oturmadır.
3. **Tezgâh işi** iş kuyruğudur: sipariş (`Yap / Make`, adet), eller (`labour.md` `eff(W)`, tezgâhın el sınırı), İS akar. Girdi siparişte ayrılır; eksikse «Malzeme bekliyor: {liste}» / «Waiting for materials: {list}».
4. **Bekleme** pasiftir: yuvayı tutar, el istemez; uykuda ve atlamada da akar (`time.md` §7.4). Açık hava beklemesi (kurutma sırığı, Sepi Yeri'nin açık yuvası, keçe kurutma) çisenti, yağmur, sağanak, kar ve dolu sürerken durur; çatı altındaki yuva durmaz (§11).
5. **Kaynak kap.** Tezgâh girdisini 150 m içindeki yerleşim ambarlarından alır (`labour.md` §6.3 yarıçapı); çıktıyı kabul eden en yakın kaba koyar.
6. **Gece.** Işıklı atölye ×1, her 4 karanlık saatte 1 `torch` yakar; ışıksız ×0,4 (`labour.md` §5.1). Keçe Avlusu açık havadır: `labour.md` §5.2'nin keçe adımı çarpanları ona da uyar.
7. **NPC el işi** en yakın uygun tezgâhta (ip ve sırık Ağaç Atölyesi'nde, ok Okçu Yurdu'nda), yoksa ocak başında yapılır.
8. **İlk kez.** Tarif başına bir kez +20 XP (`progression.md` §1.3 `recipe`); tekrar yok.

### 4.2 Tezgâhlar

Yapı kimlikleri ve emekleri `labour.md` §8.2–§8.3'ündür; burada tezgâh yüzü.

| Tezgâh | TR / EN | Yapı | El en çok | Bekleme yuvası | Perde | Tarifler |
|---|---|---|---|---|---|---|
| `hand` | El / Hand | — | 1 | – | I | `rc_rope`, `rc_rope_hair`, `rc_hide_patch`, `rc_skin_bag`, `rc_pole`, `rc_shafts`, `rc_shafts_branch` (+6) |
| `hearth` | Ocak / Hearth | — | 2 | – | I | `rc_dye`, `rc_torch`, `rc_pot`, `rc_meal`, `rc_ember_pot` |
| `felt_yard` | Keçe Avlusu / Felting Yard | `felt_yard` | 6 | 2 | I | `rc_felt`, `rc_felt_batch`, `rc_felt_white`, `rc_chiy`, `rc_saddle_felt`, `rc_felt_boots`, `rc_felt_coat` (+2) |
| `tannery` | Sepi Yeri / Tannery | `tannery` | 3 | 4 | II | `rc_leather`, `rc_hide_lamellar`, `rc_riding_boots`, `rc_fur_boots`, `rc_pouch_belt`, `rc_tool_belt`, `rc_war_quiver` (+3) |
| `wood_shop` | Ağaç Atölyesi / Woodshop | `wood_shop` | 3 | 2 | II | `rc_door_frame`, `rc_kerege_set`, `rc_uuk_set`, `rc_yurt_crown`, `rc_crown_great`, `rc_wheel_pair`, `rc_saddle_tree` |
| `smithy` | Demirci Ocağı / Smithy | `smithy` | 3 | 1 | I | `rc_heads_bronze`, `rc_heads_iron`, `rc_copper_bit`, `rc_iron_bar`, `rc_bloom`, `rc_reforge`, `rc_bronze_bar` (+11) |
| `kiln` | Fırın / Kiln | `kiln` | 2 | 1 | II | `rc_charcoal` |
| `fletchery` | Okçu Yurdu / Fletcher's Yurt | `fletchery` | 3 | 4 | II | `rc_thumb_ring`, `rc_hun_bow`, `rc_bone_bow`, `rc_horn_bow`, `rc_great_bow` |
| `kitchen` | Kazan Ocağı / Cauldron Hearth | Kazanlı herhangi bir yurt ocağı; yapı değil | 3 | 2 | II | `rc_glue`, `rc_glue_fish`, `rc_meal_batch`, `rc_cauldron_meat`, `rc_kumis_batch`, `rc_lamp_oil` |
| `stable` | Ahır / Stable | `stable` | 2 | – | I | `rc_fodder` |
| `drying_rack` | Kurutma Sırığı / Drying Rack | `rack` | 1 | 6 | I | `rc_dried_meat`, `rc_dried_batch`, `rc_qurt`, `rc_qurt_batch` |

### 4.3 Zanaatçılar

| id | TR / EN | Tezgâh | Usta işi | Not |
|---|---|---|---|---|
| `cr_felter` | Keçeci / Felt-maker | Keçe Avlusu | Ak keçe toplu | I. Perde: Nanay'ın avlusu |
| `cr_tanner` | Sepici / Tanner | Sepi Yeri | | |
| `cr_carpenter` | Dülger / Carpenter | Ağaç Atölyesi | Kerege takımı, tündük, ulu tündük | `labour.md` `wood` zanaatıyla aynı kişi olabilir |
| `cr_cartwright` | Arabacı / Cartwright | Ağaç Atölyesi | Teker çifti | |
| `cr_smith` | Demirci / Smith | Demirci Ocağı | Eritme, tunç, kazan, demir teçhizat | I. Perde: Kujul |
| `cr_bowyer` | Yaycı / Bowyer | Okçu Yurdu | Yaylar | `progression.md` §4.3 `m_bowyer` aynı kişi olabilir |
| `cr_saddler` | Saraç / Saddler | Sepi Yeri | Savaş eyeri, at zırhı | |
| `cr_cook` | Aşçı / Cook | Kazan Ocağı | | Toplu yemek ×1,25 hız |

- **Derece.** Çırak / Apprentice (`labour.md` ağırlık 0,75; usta işi yapamaz) ve Usta / Master. Kendi zanaatında 120 İS çalışan (≈5 oyun günü) ya da hikâyeyle gelen usta olur. İnce İş yalnız ustanındır (§2.5).
- **Mete** zanaatçı değildir; becerileri (`hearth_craft`, `repair`, `quick_raise`) olduğu gibi işler.
- **Öğretmen usta** (`progression.md` §4.3) beceri öğretir; zanaatçı mal üretir. Aynı kişi ikisi olabilir.

### 4.4 Zincirler

1. **Keçe.** Kırkım (koyun başına 0,5 İS) → `wool` → Keçe Avlusu: el ile 2 yün → 1 keçe (4 sn, a1) ya da toplu 12 yün → 6 keçe (7 İS, 6 sa bekleme, yağmurda durur) → yurt 6, çadır 3, araba 2–8, kaftan 4, keçe eyer 3, çizme 2, çul 2. Ak keçe 3 yün → 1: otağ 12, Ak Keçe pelerini.
2. **Sepi.** Av ya da kesim → `hide` → Sepi Yeri: 1 deri + 1 sepi katkısı (`tag:tan`: `fat`, `milk` ya da `salt`) → 1 `leather` (1 İS, 12 sa) → çizme, kuşak, kolluk, sadak, eyer, koşum, at zırhı. Ham deri doğrudan: sapan, keçe eyer, toynak sargısı, deri dilimli zırh (ham deri dilimleri dönemin zırhıdır).
3. **İp.** 3 saz → 1 ip (2 sn, a1) ya da 2 kıl → 1 ip (3 sn): kıl ipi bozkırın ipidir, sazı olmayan Gobi kampı onunla bağlanır.
4. **Ağaç ve yurt parçası.** Ağaç Atölyesi: bosağa (3 odun + 1 demir külçe, 6 İS), kerege takımı (8 odun + 2 ip, 12 İS, usta; odunun yarısı hafif ise kerege canı +%10, `economy.md` §2.1 söğüt kuralı), uuk demeti (12 odun, 8 İS), tündük (2 huş + 2 sinir, 10 İS, 24 sa, usta), ulu tündük (4 huş + 4 sinir + 2 tutkal, 20 İS, 24 sa, usta), teker çifti (2 odun, 10 İS, usta; ikisi de sert odun ise araba canı +%25), eyer kaşı (2 hafif odun + 1 tutkal, 4 İS), ok gövdesi (1 hafif odun → 15, ya da 1 dal → 5). Çiy 6 saz Keçe Avlusu'nda, sırık 1 odun → 2 el ile.
5. **Kömür ve maden.** Fırın: 3 odun → 2 kömür (1,5 İS, 12 sa). Demirci Ocağı: 1 bakır cevheri → 1 bakır parça; 4 demir cevheri + 3 kömür → 1 külçe (usta, 4 İS, 6 sa); 4 demir hurda + 1 kömür → 1 külçe (2 İS); 8 bakır + 1 kalay + 2 kömür → 4 tunç külçe (usta); 4 tunç hurda + 1 kömür → 1 tunç (kayıplı: hurda takasta değerlidir); 4 kalay cevheri + 2 kömür → 1 kalay (IV). I. Perde'de Kujul'un körüğü a1'dir: 4 cevher → 1 külçe, kömürü Kujul katar.
6. **Yay ve ok.** Tutkal: 3 kemik → 2 ya da 2 balık → 3 (Kazan Ocağı, 6 sa). Yay: boynuz + sinir + odun + tutkal (Okçu Yurdu, usta, 12–20 İS, 24 sa). Temren: 1 kemik → 5 (el), 1 tunç külçe + 1 kömür → 30 döküm temren (3 İS), 1 demir külçe + 1 kömür → 15 dövme temren (5 İS). Ok: 5 temren + 5 gövde + 1 tüy → 5 ok (el 4 sn; NPC 2,5 İS). Islıklı ve ateşli ok `progression.md` §7.3 aynen.
7. **Eyer ve koşum.** Eyer kaşı + 2 sepi deri → ağaç eyer (Sepi Yeri); + 1 demir külçe → savaş eyeri (usta). Keçe eyer a1.
8. **Araba.** Teker çifti + odun + keçe + demir + ip → şantiyede kurulur (`labour.md` §8.1: araba 0,3 İG). Malzeme §6.
9. **Yiyecek.** `survival.md` §3 tarifleri aynen. Hane ölçeği: kazanda 1 et → 5 öğün (defter payı, eşya değil: `economy.md` §8.3), 10 darı → 5 Aş, 4 süt + 1 tuz → 4 kurut, 4 et + 1 tuz → 4 kak, 10 kısrak sütü → 5 kımız (12 sa).

### 4.5 Tarif tablosu

**Lif, keçe, ip.**

| Tarif | Çıktı | Girdi | Tutuş sn | İS | Bekleme sa | Tezgâh | Kim | Perde | Not |
|---|---|---|---|---|---|---|---|---|---|
| `rc_rope` | 1 `rope` | 3 `reed` | 2 | 0,5 | – | `hand` | El | I | a1 |
| `rc_rope_hair` | 1 `rope` | 2 `hair` | 3 | 0,75 | – | `hand` | El | II |  |
| `rc_felt` | 1 `felt` | 2 `wool` | 4 | 1,5 | – | `felt_yard` | El | I | a1 |
| `rc_felt_batch` | 6 `felt` | 12 `wool` | – | 7 | 6 | `felt_yard` | Tezgâh | II |  |
| `rc_felt_white` | 1 `felt_white` | 3 `wool` | 5 | 2 | – | `felt_yard` | El | II |  |
| `rc_chiy` | 1 `chiy` | 6 `reed` | 4 | 2 | – | `felt_yard` | El | II |  |
| `rc_dye` | 1 `dye` | 2 `madder` | 3 | 1 | – | `hearth` | El | II |  |

**Deri ve tutkal.**

| Tarif | Çıktı | Girdi | Tutuş sn | İS | Bekleme sa | Tezgâh | Kim | Perde | Not |
|---|---|---|---|---|---|---|---|---|---|
| `rc_hide_patch` | 1 `hide` | 3 `hide_small` | 3 | 1 | – | `hand` | El | I | economy.md §6.2 |
| `rc_leather` | 1 `leather` | 1 `hide`, 1 `tag:tan` | 3 | 1 | 12 | `tannery` | El | II |  |
| `rc_glue` | 2 `glue` | 3 `bone` | – | 1 | 6 | `kitchen` | Tezgâh | II |  |
| `rc_glue_fish` | 3 `glue` | 2 `fish` | – | 1 | 6 | `kitchen` | Tezgâh | II |  |
| `rc_skin_bag` | 1 `skin_bag` | 1 `hide` | 3 | 1 | – | `hand` | El | II | economy.md §6.6 |

**Ağaç ve yurt parçası.**

| Tarif | Çıktı | Girdi | Tutuş sn | İS | Bekleme sa | Tezgâh | Kim | Perde | Not |
|---|---|---|---|---|---|---|---|---|---|
| `rc_pole` | 2 `pole` | 1 `tag:wood` | 2 | 0,5 | – | `hand` | El | I | economy.md §6.2 |
| `rc_door_frame` | 1 `door_frame` | 3 `tag:wood`, 1 `iron_bar` | – | 6 | – | `wood_shop` | Tezgâh | II |  |
| `rc_kerege_set` | 1 `kerege_set` | 8 `tag:wood`, 2 `rope` | – | 12 | – | `wood_shop` | Usta | II | `cr_carpenter`; Odunun en az yarısı tag:wood_light ise kerege aşama canı +%10 (economy.md §2.1 söğüt kuralı) |
| `rc_uuk_set` | 1 `uuk_set` | 12 `tag:wood` | – | 8 | – | `wood_shop` | Tezgâh | II |  |
| `rc_yurt_crown` | 1 `yurt_crown` | 2 `wood_birch`, 2 `sinew` | – | 10 | 24 | `wood_shop` | Usta | II | `cr_carpenter` |
| `rc_crown_great` | 1 `crown_great` | 4 `wood_birch`, 4 `sinew`, 2 `glue` | – | 20 | 24 | `wood_shop` | Usta | III | `cr_carpenter` |
| `rc_wheel_pair` | 1 `wheel_pair` | 2 `tag:wood` | – | 10 | – | `wood_shop` | Usta | II | `cr_cartwright`; İki odunun ikisi de tag:wood_hard ise arabanın aşama canı +%25 (a1 söğüt kuralının eşi) |
| `rc_saddle_tree` | 1 `saddle_tree` | 2 `tag:wood_light`, 1 `glue` | – | 4 | – | `wood_shop` | Tezgâh | II |  |
| `rc_shafts` | 15 `arrow_shaft` | 1 `tag:wood_light` | 6 | 3 | – | `hand` | El | II |  |
| `rc_shafts_branch` | 5 `arrow_shaft` | 1 `branch` | 2 | 1 | – | `hand` | El | II |  |

**Kömür ve maden.**

| Tarif | Çıktı | Girdi | Tutuş sn | İS | Bekleme sa | Tezgâh | Kim | Perde | Not |
|---|---|---|---|---|---|---|---|---|---|
| `rc_charcoal` | 2 `charcoal` | 3 `tag:wood` | – | 1,5 | 12 | `kiln` | Tezgâh | II |  |
| `rc_copper_bit` | 1 `copper_bit` | 1 `ore_copper` | 2 | 1 | – | `smithy` | Tezgâh | I | economy.md §6.2 |
| `rc_iron_bar` | 1 `iron_bar` | 4 `ore_iron` | 6 | 4 | – | `smithy` | Usta | I | a1; `kujul`; Kujul'un körüğü; kömürü Kujul katar |
| `rc_bloom` | 1 `iron_bar` | 4 `ore_iron`, 3 `charcoal` | – | 4 | 6 | `smithy` | Usta | II | `cr_smith` |
| `rc_reforge` | 1 `iron_bar` | 4 `iron_scrap`, 1 `charcoal` | – | 2 | – | `smithy` | Tezgâh | II |  |
| `rc_bronze_bar` | 4 `bronze_bar` | 8 `copper_bit`, 1 `tin_ingot`, 2 `charcoal` | – | 4 | 2 | `smithy` | Usta | II | `cr_smith` |
| `rc_bronze_recast` | 1 `bronze_bar` | 4 `bronze_scrap`, 1 `charcoal` | – | 2 | – | `smithy` | Tezgâh | II |  |
| `rc_tin_ingot` | 1 `tin_ingot` | 4 `ore_tin`, 2 `charcoal` | – | 4 | – | `smithy` | Usta | IV | `cr_smith` |
| `rc_cauldron` | 1 `cauldron` | 4 `bronze_bar` | – | 8 | – | `smithy` | Usta | II | economy.md §6.6; `cr_smith` |
| `rc_pot` | 1 `pot` | 2 `clay` | 6 | 2 | – | `hearth` | El | I | economy.md §6.2 |

**Ok.**

| Tarif | Çıktı | Girdi | Tutuş sn | İS | Bekleme sa | Tezgâh | Kim | Perde | Not |
|---|---|---|---|---|---|---|---|---|---|
| `rc_heads_bone` | 5 `arrowhead_bone` | 1 `bone` | 3 | 1 | – | `hand` | El | II |  |
| `rc_heads_bronze` | 30 `arrowhead_bronze` | 1 `bronze_bar`, 1 `charcoal` | – | 3 | 1 | `smithy` | Tezgâh | II |  |
| `rc_heads_iron` | 15 `arrowhead_iron` | 1 `iron_bar`, 1 `charcoal` | – | 5 | – | `smithy` | Tezgâh | II |  |
| `rc_arrow_bone` | 5 `arrow_bone` | 5 `arrowhead_bone`, 5 `arrow_shaft`, 1 `feather` | 4 | 2,5 | – | `hand` | El | II |  |
| `rc_arrow_bronze` | 5 `arrow_bronze` | 5 `arrowhead_bronze`, 5 `arrow_shaft`, 1 `feather` | 4 | 2,5 | – | `hand` | El | II | beceri `trilobate` |
| `rc_arrow_iron` | 5 `arrow_iron` | 5 `arrowhead_iron`, 5 `arrow_shaft`, 1 `feather` | 4 | 2,5 | – | `hand` | El | II | beceri `trilobate` |

**Yemek ve yem (hane ölçeği; tekil tarifler survival.md §3).**

| Tarif | Çıktı | Girdi | Tutuş sn | İS | Bekleme sa | Tezgâh | Kim | Perde | Not |
|---|---|---|---|---|---|---|---|---|---|
| `rc_meal` | 1 `meal` | 2 `millet` | 15 | 0,25 | – | `hearth` | El | I | survival.md §3; survival.md §3: pişirme süresi tutuş sayılır |
| `rc_meal_batch` | 5 `meal` | 10 `millet` | – | 1 | – | `kitchen` | Tezgâh | II |  |
| `rc_cauldron_meat` | 5 pay (defter) | 1 `meat` | – | 0,5 | – | `kitchen` | Tezgâh | II | economy.md §8.3: 1 et + su = 5 öğün |
| `rc_dried_meat` | 1 `dried_meat` | 1 `meat`, 1 `salt` | 2 | 0,5 | 2 | `drying_rack` | El | I | a1 |
| `rc_dried_batch` | 4 `dried_meat` | 4 `meat`, 1 `salt` | – | 1 | 2 | `drying_rack` | Tezgâh | II |  |
| `rc_qurt` | 1 `qurt` | 1 `milk`, 1 `salt` | 2 | 0,5 | 2 | `drying_rack` | El | I | a1 |
| `rc_qurt_batch` | 4 `qurt` | 4 `milk`, 1 `salt` | – | 1 | 2 | `drying_rack` | Tezgâh | II |  |
| `rc_kumis_batch` | 5 `kumis` | 10 `mare_milk` | – | 1 | 12 | `kitchen` | Tezgâh | II |  |
| `rc_fodder` | 1 `fodder` | 2 `tag:forage` | 2 | 0,25 | – | `stable` | El | I | a1 |

**I. Perde eşyası (a1).**

| Tarif | Çıktı | Girdi | Tutuş sn | İS | Bekleme sa | Tezgâh | Kim | Perde | Not |
|---|---|---|---|---|---|---|---|---|---|
| `rc_torch` | 1 `torch` | 1 `branch`, 1 `resin` | 2 | 0,25 | – | `hearth` | El | I | a1 |
| `rc_saddle_felt` | 1 `saddle_felt` | 3 `felt`, 1 `hide`, 1 `rope` | 6 | 3 | – | `felt_yard` | El | I | a1 |
| `rc_felt_boots` | 1 `felt_boots` | 2 `felt` | 4 | 1,5 | – | `felt_yard` | El | I | a1 |
| `rc_hoof_wraps` | 1 `hoof_wraps` | 2 `hide`, 4 `copper_bit`, 2 `iron_bar` | 8 | 4 | – | `smithy` | Usta | I | a1; `kujul` |

**Teçhizat (progression.md §6–§7 eşlemesi).**

| Tarif | Çıktı | Girdi | Tutuş sn | İS | Bekleme sa | Tezgâh | Kim | Perde | Not |
|---|---|---|---|---|---|---|---|---|---|
| `rc_felt_coat` | 1 `felt_coat` | 4 `felt` | – | 3 | – | `felt_yard` | Tezgâh | II |  |
| `rc_hide_lamellar` | 1 `hide_lamellar` | 6 `hide`, 2 `rope` | – | 8 | – | `tannery` | Tezgâh | II |  |
| `rc_bronze_scale` | 1 `bronze_scale` | 8 `copper_bit`, 2 `tin_ingot`, 4 `leather`, 2 `charcoal` | – | 12 | – | `smithy` | Usta | III | `cr_smith` |
| `rc_iron_lamellar` | 1 `iron_lamellar` | 10 `iron_bar`, 4 `leather`, 2 `charcoal` | – | 16 | – | `smithy` | Usta | V | `cr_smith` |
| `rc_war_cape` | 1 `war_cape` | 3 `felt`, 1 `dye` | – | 2 | – | `felt_yard` | Tezgâh | III |  |
| `rc_riding_boots` | 1 `riding_boots` | 3 `leather` | – | 2 | – | `tannery` | Tezgâh | II |  |
| `rc_fur_boots` | 1 `fur_boots` | 3 `leather`, 1 `fur_fox` | – | 3 | – | `tannery` | Tezgâh | III |  |
| `rc_pouch_belt` | 1 `pouch_belt` | 2 `leather` | – | 2 | – | `tannery` | Tezgâh | II |  |
| `rc_tool_belt` | 1 `tool_belt` | 3 `leather`, 1 `iron_bar` | – | 3 | – | `tannery` | Tezgâh | IV |  |
| `rc_iron_helm` | 1 `iron_helm` | 3 `iron_bar`, 1 `leather`, 1 `charcoal` | – | 6 | – | `smithy` | Usta | IV | `cr_smith` |
| `rc_iron_bracer` | 1 `iron_bracer` | 2 `iron_bar`, 1 `leather` | – | 4 | – | `smithy` | Tezgâh | V |  |
| `rc_thumb_ring` | 1 `thumb_ring` | 1 `horn` | – | 1 | – | `fletchery` | Tezgâh | III |  |
| `rc_war_quiver` | 1 `war_quiver` | 2 `leather`, 1 `wood_birch` | – | 3 | – | `tannery` | Tezgâh | IV |  |
| `rc_hun_bow` | 1 `hun_bow` | 2 `horn`, 2 `sinew`, 1 `tag:wood`, 1 `glue` | – | 12 | 24 | `fletchery` | Usta | II | `cr_bowyer` |
| `rc_bone_bow` | 1 `bone_bow` | 3 `horn`, 3 `sinew`, 2 `bone`, 1 `tag:wood`, 1 `glue` | – | 14 | 24 | `fletchery` | Usta | III | `cr_bowyer` |
| `rc_horn_bow` | 1 `horn_bow` | 4 `horn`, 4 `sinew`, 1 `wood_birch`, 2 `glue` | – | 18 | 24 | `fletchery` | Usta | IV | `cr_bowyer` |
| `rc_great_bow` | 1 `great_bow` | 5 `horn`, 5 `sinew`, 2 `wood_birch`, 2 `glue` | – | 20 | 24 | `fletchery` | Usta | V | `cr_bowyer` |
| `rc_saddle_wood` | 1 `saddle_wood` | 1 `saddle_tree`, 2 `leather` | – | 4 | – | `tannery` | Tezgâh | III |  |
| `rc_saddle_war` | 1 `saddle_war` | 1 `saddle_tree`, 2 `leather`, 1 `iron_bar` | – | 6 | – | `tannery` | Usta | V | `cr_saddler` |
| `rc_blanket_felt` | 1 `blanket_felt` | 2 `felt` | – | 1,5 | – | `felt_yard` | Tezgâh | II |  |
| `rc_horse_armor` | 1 `horse_armor` | 8 `leather`, 4 `iron_bar` | – | 16 | – | `tannery` | Usta | V | `cr_saddler` |
| `rc_ring_sword` | 1 `ring_sword` | 3 `iron_bar`, 1 `charcoal`, 1 `leather` | – | 8 | – | `smithy` | Usta | II | `cr_smith` |
| `rc_iron_sword` | 1 `iron_sword` | 5 `iron_bar`, 2 `charcoal`, 1 `leather` | – | 10 | – | `smithy` | Usta | III | `cr_smith` |
| `rc_long_sword` | 1 `long_sword` | 7 `iron_bar`, 3 `charcoal`, 1 `leather` | – | 14 | – | `smithy` | Usta | IV | `cr_smith` |

**Işık ve köz.**

| Tarif | Çıktı | Girdi | Tutuş sn | İS | Bekleme sa | Tezgâh | Kim | Perde | Not |
|---|---|---|---|---|---|---|---|---|---|
| `rc_lamp_oil` | 1 `lamp_oil` | 1 `fat` | – | 0,5 | – | `kitchen` | Tezgâh | II | İç yağı eritilir; Fener Direği 3 gecede 1 yakar (settlement.md §6.4) |
| `rc_ember_pot` | 1 `ember_pot` | 1 `pot`, 1 `hide` | 4 | 1 | – | `hearth` | El | II | Doldurma: yanan ocakta 2 sn, 48 sa; besleme 1 charcoal, +24 sa |

**Bohça.**

| Tarif | Çıktı | Girdi | Tutuş sn | İS | Bekleme sa | Tezgâh | Kim | Perde | Not |
|---|---|---|---|---|---|---|---|---|---|
| `rc_yurt_kit` | 1 `yurt_kit` | 1 `door_frame`, 1 `kerege_set`, 1 `yurt_crown`, 2 `pole`, 1 `uuk_set`, 1 `chiy`, 6 `felt`, 8 `rope` | 3 | 0 | – | `hand` | El | II | Söküm 6 wh (0,25 wd) yapı tarafındadır; burada yalnız bohça |
| `rc_tent_kit` | 1 `tent_kit` | 2 `wood_pine`, 2 `pole`, 4 `rope`, 3 `felt` | 3 | 0 | – | `hand` | El | II |  |

### 4.6 Kıymet dengesi

Oran = çıktının Kıymeti ÷ (girdilerin Kıymeti + 0,75 × İS); bant 0,85–1,6. Bandın dışında kalan her tarif ya bilerek seçilmiştir ya düzeltilir (sim işaretler). Bilerek kayıplı ya da kârlı olanlar:

- `rc_torch`: a1 Kıymeti; meşale sarftır
- `rc_charcoal`: a1 Kıymeti 3: kömür takas malı değil eritme yakıtıdır
- `rc_iron_bar`: a1 Kıymeti
- `rc_bloom`: a1 Kıymeti 16: demirin değeri kullanımdadır, satıcıda külçe az (1–2)
- `rc_bronze_recast`: Hurdanın Kıymeti kurgan bulgusudur; takas daha iyidir
- `rc_fodder`: a1 Kıymeti 4; satıcı ot satmaz, döngü kurulmaz
- `rc_saddle_felt`: a1 Kıymeti 24
- `rc_dried_meat`: Kak taşımak içindir: Yük ×0,2, bozulmaz
- `rc_dried_batch`: Kak taşımak içindir: Yük ×0,2, bozulmaz
- `rc_qurt`: Kurut kışa saklamaktır
- `rc_qurt_batch`: Kurut kışa saklamaktır
- `rc_kumis_batch`: Kımız törendir ve yazın içilir

Kayıplı tarif bir «zarar» değildir: kak, kurut ve kömür takas için değil kullanım içindir (taşımak, saklamak, eritmek); satıcının onu girdisinden ucuza alması döngü kurmayı önler. **Teçhizatın önerilen Kıymeti** (girdi + emek; `progression.md` §6–§7 tablosuna sütun olarak): `felt_coat` 22, `hide_lamellar` 60, `bronze_scale` 179, `iron_lamellar` 222, `war_cape` 22, `riding_boots` 35, `fur_boots` 47, `pouch_belt` 24, `tool_belt` 51, `iron_helm` 67, `iron_bracer` 46, `thumb_ring` 7, `war_quiver` 28, `hun_bow` 35, `bone_bow` 49, `horn_bow` 62, `great_bow` 77, `saddle_wood` 38, `saddle_war` 56, `blanket_felt` 11, `horse_armor` 164, `ring_sword` 68, `iron_sword` 105, `long_sword` 143.

## 5. Kaplar

### 5.1 Kap tablosu

Kapasite ve kabul bu belgenin; yerleşim yapısının kademesi, yeri ve baskın kuralı `settlement.md` §7, §9, §15.4'ündür. Bir yerin kapları tek **Ambar / Store** görünümünde birleşir (`StorePool`, `settlement.md` §9.1).

| id | TR / EN | Nerede | Sınır Yük | Kabul | Not |
|---|---|---|---|---|---|
| `pack` | Heybe / Pack | Mete | `loadMax` (21 → perde tavanı); Erzak ve Zanaat 24 ortak yuva | Hepsi | `sentenced` el koyma (`progression.md` §6.1) |
| `saddlebags` | Terki / Saddlebags | Her binek | Binek Yük'ü: Yakve 40, Adak Aygırı 50, `spare_horse` 30, `hun_pony` 40, `west_steed` 45 | Hepsi | At düşerse yer yığını |
| `sled` | Yük Kızağı / Load Sled | Mete | +12 | `tag:bulk` | a1 |
| `cart` | Araba / Cart | Durak ya da yol | 40 / 60 / 80 / 140; `wagon_felt` 120, `cart_ox` 60, `pack_camel` 30 | Hepsi | Teker kırılırsa yük yere (`travel.md`) |
| `chest` | Sandık / Chest | Mete'nin yurdu ve her hane yurdu | 60 | Hepsi | Yurt aşama 2'nin altına inerse yer yığını |
| `store_yurt` | Ambar Yurdu / Store Yurt | Yerleşim | 400 | Hepsi | |
| `shed` | Sundurma / Shed | Yerleşim | 500 | `tag:bulk`, `tag:forage`, `fodder` | Ot içeriği yanar (`structures.md` §6) |
| `granary` | Tahıl Ambarı / Granary | Yerleşim | 600 | `tag:food`, `tag:grain` | |
| `granary_tower` | Tahıl Kulesi / Grain Tower | Surlu Avlu | 800 | `tag:food`, `tag:grain` | Baskında ×0,5 |
| `grain_pit` | Ambar Çukuru / Grain Pit | Yerleşim | 120 | `tag:food`, `tag:grain`, `tag:valuable` | **Baskında bulunmaz** |
| `treasury` | Hazine / Treasury | Toy Yeri'nden | 120 | `tag:valuable` | Armağan, pay, Kurultay dağıtımı |
| `armoury` | Silahlık / Armoury | Ordugâh | 200 | `tag:gear`, `tag:arrow`, `tag:metal` | |
| `supply_depot` | Erzak Ambarı / Supply Depot | Ordugâh | 600 | Hepsi | `army.md` §3.6 çizgileri buradan |
| `haystack` | Ot Yığını / Haystack | Açıkta | Yok | `hay`, `straw` | Islak her gün %2 çürür (§11) |
| `site` | Şantiye Yığını / Site Stock | Şantiye | Yapının malzeme yükü × 1,25 | O yapının malzemesi | `labour.md` §6.3 |
| `stash` | Menzil Ambarı / Waystation Store | `linked` durak | 40 | Hepsi | a1 |
| `cache` | Zula / Cache | Onarılmış `RB` | 6 yuva × 6 | Hepsi | a1: bulunmaz |
| `ground_pile` | Yer Yığını / Ground Pile | Bırakılan yer | Yok; dünyada ≤24 | Hepsi | a1 |

**Baskın** (`settlement.md` §9.3, §15.4): kayıp payı `R / (R + D)`; Ambar Çukuru'ndan hiçbir şey alınmaz, sur içi ×0,3, Tahıl Kulesi ×0,5. Perde başına beklenen kayıp §9'da sınanır (≤%10).

### 5.2 Aktarma kuralları

1. Kap `E` ile açılır: iki sütunlu aktarma paneli; açıkken oyun durur (`progression.md` §14.1 kuralı). Sürükle, tıkla, ya da adet seç.
2. Hızlı düğmeler: «Sırtı Boşalt / Unload Back» (`tag:bulk`), «Malzemeyi Bırak / Store Materials» (Zanaat sekmesi), «Yiyeceği Bırak / Store Food», «Hepsini Al / Take All», «Eksikleri Al / Take What's Missing» (seçili tarif ya da şantiye için eksik girdiyi hesaplar).
3. Sınır onda bir Yük ile sınanır: `canTake(id, n)` alınabilecek en çok adedi verir; sığmayan kalır, «Ambar dolu / The store is full».
4. Kabul süzgeci kap türündedir; uymayan eşya sütunda soluk görünür.
5. Yerleşim ambarlarına varan araba ve kervan kendiliğinden boşalır (I. Perde Ambar durağı kuralı).
6. Şantiye ve tezgâh 150 m içindeki yerleşim ambarlarından kendi taşır (`labour.md` §6.3); oyuncu yerleşim içinde yük taşımaz.
7. Bohça teslimde açılır: `yurt_kit` şantiye yığınına parça olarak girer.
8. Hane sandığı hanenindir, yerleşim toplamına girmez; Mete'nin sandığı Mete'nindir.
9. Ganimet önce Heybe'ye, sığmazsa terkiye, sonra yer yığınına.

### 5.3 Kervan

Kervan buyruğu, yol, hava, baskın ve yol töresi yerleşim taslağınındır (`settlement.md` §11, `CaravanBook`). Ekonomi yükü ve ölçüsünü verir:

- **Sınır** arabaların toplamıdır (§5.1); bir keçe araba 600 öğün ya da 30 yem bağı taşır.
- **`@army_share: n`** n günlük Ordu Payı'dır (§7.3). Kervana yalnız **kuru erzak** girer: Aş, darı, kak, kurut, arpa ve tahıl çuvalı (pay yoğunluğu Aş'ta 10 öğün/Yük, kakta 5,7, darıda 5); çiğ et ve süt girmez (bozulur).
- **Yem taşınmaz:** yüzlük bir ordugâh otlaksız günde 600 Yük yem ister; kervan yemi yalnız at hattı ve ahır içindir (§7.3).
- **Geri yük**: ganimetin ambar payı (§3.5), av kollarının deri, boynuz, sinir ve hurdası.

### 5.4 Terki ve binek

- **Terki** atın kendi kabıdır, sınırı binek Yük'üdür (`economy.md` §4.3 «Binek» satırı). Atlıyken toplanan önce Heybe'ye, dolunca terkiye girer; at 15 m içindeyse yaya toplamada da taşma terkiye gider.
- **Hız**: binek yükü `l = terki / sınır`; `l ≤ 0,5` hız ×1, üstünde `1 − 0,3 × (l − 0,5)` (dolu ×0,85); `l > 0,75` dörtnal yok. Formül `progression.md` §2.3 `derive`'ına girer (`mountLoadK`).
- **Yedek at** (`spare_horse`) ikinci terkidir; birlikte yürür (`travel.md` §7.3 `spare_mount`).

### 5.5 Metinler

Anahtarlar `src/i18n/strings/economy.js` (8.3) içinde; eşya, tezgâh ve yapı adları tablolardaki TR / EN çiftleridir (`item.<id>`, `station.<id>`). Hepsi bu belge için yeni yazıldı.

| Anahtar | TR | EN |
|---|---|---|
| `econ.transfer` | Aktar | Transfer |
| `econ.unload_back` | Sırtı Boşalt | Unload Back |
| `econ.store_materials` | Malzemeyi Bırak | Store Materials |
| `econ.store_food` | Yiyeceği Bırak | Store Food |
| `econ.take_all` | Hepsini Al | Take All |
| `econ.take_missing` | Eksikleri Al | Take What's Missing |
| `econ.store_full` | Ambar dolu | The store is full |
| `econ.wont_take` | Bu kap bunu almaz | This store won't take that |
| `econ.wait_materials` | Malzeme bekliyor: {list} | Waiting for materials: {list} |
| `econ.need_master` | Usta gerek: {role} | A master is needed: {role} |
| `econ.make` | Yap | Make |
| `econ.fine` | İnce İş | Fine Work |
| `econ.cure_paused` | Yağmurda kurumaz | Nothing dries in the rain |
| `econ.spoiled` | Et bozuldu | The meat has spoiled |
| `econ.search` | Ara | Search |
| `econ.saddlebags` | Terki | Saddlebags |
| `econ.ember_out` | Köz söndü | The ember has gone out |
| `econ.booty_share` | Ganimeti paylaştır | Share the booty |
| `econ.booty_keep` | Ganimeti ambara al | Take the booty into store |
| `herd.shear` | Kırkım başladı | Shearing has begun |
| `herd.sogum` | Soğum günü | The winter slaughter |
| `herd.deep_snow` | Derin kar: sürüye ot gerek | Deep snow: the herd needs hay |
| `herd.zud` | Zud: {n} baş yitti | Zud: {n} head lost |
| `ledger.days` | {line}: {n} gün | {line}: {n} days |

## 6. Malzeme listeleri

### 6.1 Yurt

| Adım | Aşama | Parça biçimi (II. Perde ve sonrası) | Ham biçim (a1, Kışlak) | Ham teslimde adıma eklenen emek |
|---|---|---|---|---|
| `y_site` | 0 | 6 `stone` | Aynı | |
| `y_bosaga` | 1 | 1 `door_frame` | 3 `tag:wood`, 1 `iron_bar` | 6 İS (`rc_door_frame`) |
| `y_kerege` | 2 | 1 `kerege_set` | 8 `tag:wood`, 2 `rope` | 12 İS, usta (`rc_kerege_set`) |
| `y_bag` | 2 | 2 `rope` | Aynı | |
| `y_tunduk` | 3 | 1 `yurt_crown`, 2 `pole` | Aynı | Tündük her iki biçimde parçadır |
| `y_uuk` | 4 | 1 `uuk_set` | 12 `tag:wood` | 8 İS (`rc_uuk_set`) |
| `y_liner` | 5 | 1 `chiy` | 6 `reed` | 2 İS (`rc_chiy`) |
| `y_tuurduk`, `y_uzuk` | 6 | 4 + 2 `felt` | Aynı | |
| `y_kolan`, `y_esik` | 7 | 3 + 1 `rope` | Aynı | |
| `y_sirdak`, `y_ocak` | 7 | 1 `ember` | Aynı | |

- **Eşdeğerlik.** Parça biçimi bir düzey açılınca a1 ham biçimidir: 6 taş, 23 odun, 1 demir külçe, 8 ip, 1 tündük, 2 sırık, 6 saz, 6 keçe, 1 köz; 54 birim, 146 Yük (sim sınar). Kışlak'ta Nanay'ın eli parçayı yerinde yapar; I. Perde değişmez.
- **Ham teslim kuralı.** Şantiyeye ham mal gelirse adımın emeği parçanın İS'i kadar artar, usta işi ise ekipte o zanaatın ustası ister (`labour.md` `K_usta` aynen: yoksa ×0,7).
- **Zincirin bütünü** (sim): ham eşdeğeri 30 reed, 28,50 wood_pine, 12 wool, 6 stone, 4 ore_iron, 2 wood_birch, 2 sinew, 1 ember; teslim yükü 89 Yük (parça), ham yükü 187 Yük; toplama 152 İS, işleme 58 İS, kurma 24 İS (K21): **9,7 İG**. En kötü durumda (bütün toplanabilir hamı Mete toplar) **11,0 gerçek dk**; tezgâh işi işçinin.

**Ekip eğrisi** (K21 ideal dizisi; adım el sınırlarıyla gerçek değerler `labour.md` §4.3, 8 elde 11,6 dk):

| işçi | eff(N) | gerçek dk | harcanan İS |
|---|---|---|---|
| 1 | 1,000 | 60,0 | 24,0 |
| 2 | 1,900 | 31,6 | 25,3 |
| 3 | 2,710 | 22,1 | 26,6 |
| 4 | 3,439 | 17,4 | 27,9 |
| 6 | 4,686 | 12,8 | 30,7 |
| 8 | 5,695 | 10,5 | 33,7 |

### 6.2 Bütün yapılar

Emek (`kurma İS` = İG × 24) `labour.md` §8'dendir; malzeme bu belgenindir. «Mete dk» en kötü durumdur: bütün toplanabilir ham Mete'nin, tezgâh işi işçinin. Sütunlar 1/2/4/8: K21 ideal eğrisiyle gerçek dk, el sınırının üstü «–».

| yapı | tür | Yük parça | Yük ham | toplama İS | işleme İS | kurma İS | zincir İG | Mete dk | 1 kişi dk | 2 | 4 | 8 | Mete toplamaz |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| yurt | home | 89 | 187 | 152 | 58 | 24 | 9,7 | 11,0 | 60,0 | 31,6 | 17,4 | 10,5 | 12 wool, 1 ember |
| otag | great | 159 | 330 | 274 | 113 | 60 | 18,6 | 19,9 | 150,0 | 78,9 | 43,6 | 26,3 | 36 wool, 1 ember |
| tent | small | 16 | 21 | 19 | 7 | 4 | 1,2 | 1,5 | 9,0 | 4,7 | – | – | 6 wool |
| stable | work | 102 | 106 | 79 | 7 | 36 | 5,0 | 5,7 | 90,0 | 47,4 | 26,2 | – | 6 wool |
| fence | line | 25 | 27 | 19 | 1 | 2 | 0,9 | 1,4 | 4,5 | 2,4 | – | – |  |
| pen | line | 77 | 78 | 63 | 1 | 8 | 3,0 | 4,5 | 19,2 | 10,1 | 5,6 | – |  |
| shed | small | 47 | 51 | 42 | 2 | 14 | 2,4 | 3,0 | 36,0 | 18,9 | 10,5 | – |  |
| granary | store | 59 | 63 | 50 | 2 | 19 | 3,0 | 3,6 | 48,0 | 25,3 | 14,0 | – |  |
| hut | small | 37 | 41 | 38 | 2 | 12 | 2,2 | 2,7 | 30,0 | 15,8 | – | – |  |
| tower | work | 105 | 109 | 84 | 2 | 36 | 5,1 | 6,3 | 90,0 | 47,4 | 26,2 | – |  |
| bridge | work | 129 | 135 | 96 | 3 | 48 | 6,1 | 6,9 | 120,0 | 63,2 | 34,9 | – |  |
| rack | small | 17 | 19 | 14 | 1 | 0 | 0,6 | 1,0 | 0,1 | 0,1 | – | – |  |
| road_bone | small | 1 | 2 | 3 | 1 | 0 | 0,1 | 0,2 | 0,4 | – | – | – |  |
| cart | vehicle | 35 | 71 | 57 | 20 | 7 | 3,5 | 4,1 | 18,0 | 9,5 | – | – | 4 wool |
| cart_felt | vehicle | 55 | 123 | 101 | 30 | 10 | 5,8 | 7,1 | 24,0 | 12,6 | – | – | 8 wool |
| cart_high | vehicle | 77 | 209 | 175 | 45 | 14 | 9,8 | 12,2 | 36,0 | 18,9 | 10,5 | – | 12 wool |
| cart_war | vehicle | 114 | 314 | 264 | 72 | 24 | 15,0 | 18,4 | 60,0 | 31,6 | 17,4 | – | 16 wool |
| felt_yard | work | 23 | 27 | 24 | 7 | 12 | 1,8 | 1,9 | 30,0 | 15,8 | 8,7 | – | 4 wool |
| horse_line | small | 26 | 30 | 23 | 2 | 2 | 1,1 | 1,7 | 4,8 | 2,5 | 1,4 | – |  |
| well | work | 48 | 51 | 43 | 2 | 24 | 2,9 | 3,2 | 60,0 | 31,6 | – | – |  |
| training_ground | work | 41 | 43 | 48 | 1 | 14 | 2,6 | 3,8 | 36,0 | 18,9 | 10,5 | 6,3 |  |
| store_yurt | yurtlike | 89 | 187 | 152 | 58 | 24 | 9,7 | 11,0 | 60,0 | 31,6 | 17,4 | 10,5 | 12 wool |
| grain_pit | store | 28 | 28 | 24 | 3 | 7 | 1,4 | 1,8 | 18,0 | 9,5 | 5,2 | – | 4 wool |
| tannery | work | 40 | 48 | 38 | 4 | 10 | 2,1 | 2,8 | 24,0 | 12,6 | 7,0 | – |  |
| wood_shop | work | 66 | 102 | 83 | 8 | 19 | 4,6 | 5,8 | 48,0 | 25,3 | 14,0 | – |  |
| smithy | work | 89 | 123 | 106 | 8 | 36 | 6,3 | 7,8 | 90,0 | 47,4 | 26,2 | – |  |
| kiln | work | 54 | 54 | 40 | 0 | 14 | 2,3 | 2,7 | 36,0 | 18,9 | 10,5 | – |  |
| rampart | line | 31 | 31 | 23 | 0 | 12 | 1,5 | 1,6 | 30,0 | 15,8 | 8,7 | 5,3 |  |
| pit_house | great | 109 | 109 | 77 | 3 | 48 | 5,3 | 5,4 | 120,0 | 63,2 | 34,9 | – | 4 wool |
| field | line | 13 | 13 | 10 | 0 | 12 | 0,9 | 0,7 | 30,0 | 15,8 | 8,7 | – |  |
| granary_tower | great | 146 | 152 | 111 | 3 | 48 | 6,7 | 7,9 | 120,0 | 63,2 | 34,9 | – |  |
| gathering_ground | work | 92 | 92 | 71 | 8 | 10 | 3,7 | 4,9 | 24,0 | 12,6 | 7,0 | 4,2 | 8 wool |
| armoury | yurtlike | 113 | 211 | 167 | 58 | 29 | 10,6 | 12,1 | 72,0 | 37,9 | 20,9 | 12,6 | 12 wool |
| fletchery | yurtlike | 105 | 203 | 162 | 58 | 29 | 10,4 | 11,7 | 72,0 | 37,9 | 20,9 | 12,6 | 12 wool |
| supply_depot | yurtlike | 122 | 222 | 176 | 59 | 36 | 11,3 | 12,8 | 90,0 | 47,4 | 26,2 | 15,8 | 12 wool |
| cmd_yurt | yurtlike | 89 | 187 | 152 | 58 | 24 | 9,7 | 11,0 | 60,0 | 31,6 | 17,4 | 10,5 | 12 wool, 1 ember |
| palisade | line | 33 | 34 | 22 | 1 | 2 | 1,0 | 1,6 | 6,0 | 3,2 | 1,7 | 1,1 |  |
| watch_tower | work | 105 | 109 | 84 | 2 | 36 | 5,1 | 6,3 | 90,0 | 47,4 | 26,2 | – |  |
| envoy_yurt | yurtlike | 91 | 191 | 157 | 63 | 24 | 10,2 | 11,4 | 60,0 | 31,6 | 17,4 | 10,5 | 18 wool, 1 ember |
| healer_yurt | yurtlike | 89 | 188 | 156 | 58 | 24 | 9,9 | 11,1 | 60,0 | 31,6 | 17,4 | 10,5 | 12 wool, 1 ember |
| sky_pole | work | 71 | 73 | 62 | 5 | 14 | 3,4 | 4,2 | 36,0 | 18,9 | 10,5 | – | 4 wool |
| banner_pole | small | 5 | 5 | 6 | 3 | 0 | 0,4 | 0,4 | 0,4 | – | – | – | 2 wool |
| lantern_post | small | 5 | 6 | 6 | 1 | 0 | 0,3 | 0,5 | 0,4 | – | – | – |  |
| barter_ground | work | 38 | 42 | 32 | 8 | 12 | 2,2 | 2,4 | 30,0 | 15,8 | 8,7 | – | 8 wool |
| outpost | small | 40 | 45 | 34 | 7 | 10 | 2,1 | 2,6 | 24,0 | 12,6 | 7,0 | – | 6 wool |
| rampart_gate | great | 132 | 200 | 155 | 15 | 36 | 8,5 | 10,8 | 90,0 | 47,4 | 26,2 | – |  |
| treasury | store | 116 | 129 | 98 | 8 | 29 | 5,6 | 6,9 | 72,0 | 37,9 | 20,9 | – | 4 wool, 0 tin_ingot |
| wagon_felt | vehicle | 129 | 267 | 217 | 63 | 29 | 12,9 | 15,4 | 72,0 | 37,9 | 20,9 | – | 20 wool |

**Malzeme listeleri** (parça biçimi; a1 türlerinde ham biçim `economy.md` §6.4 aynen):

| `kind` | Malzeme | Not |
|---|---|---|
| `yurt`, `cmd_yurt` | 6 `stone`, 1 `door_frame`, 1 `kerege_set`, 6 `rope`, 1 `yurt_crown`, 2 `pole`, 1 `uuk_set`, 1 `chiy`, 6 `felt`, 1 `ember` | §6.1 |
| `otag` | 10 `stone`, 1 `door_frame`, 2 `kerege_set`, 2 `uuk_set`, 1 `crown_great`, 4 `pole`, 2 `chiy`, 12 `felt_white`, 14 `rope`, 2 `dye`, 1 `ember` | 36 yün: otağ bir oba yünüdür |
| `store_yurt` | Yurt, köz yok | 400 Yük |
| `armoury` | Yurt (köz yok) + 6 `tag:wood` raf | 200 Yük |
| `fletchery` | Yurt (köz yok) + 4 `tag:wood` tezgâh | |
| `supply_depot` | Yurt (köz yok) + 8 `tag:wood`, 2 `rope` yük sekisi | 600 Yük |
| `envoy_yurt` | Yurt + 2 `felt_white`, 1 `dye` | `settlement.md` §7.2 önerisi aynen |
| `healer_yurt` | Yurt + 4 `herb_wormwood` | Aynen |
| `treasury` | 8 `stone`, 16 `tag:wood`, 4 `rope`, 2 `felt`, 2 `clay`, 1 `bronze_bar` (kilit) | Aynen; 120 Yük `tag:valuable` |
| `sky_pole` | **12** `stone`, 2 `tag:wood` (huş ya da melez), 2 `felt`, 1 `dye`, 2 `rope` | Öneri 24 taştı; on iki taş ayların halkasıdır ve yapı küçük yapı hedefine iner (24 taşla 7,4 dk) |
| `banner_pole`, `lantern_post` | 1 `tag:wood`, 1 `felt`, 1 `dye`; 1 `tag:wood`, 1 `rope`, 1 `lamp_oil` | Basılı tutma (≤12 İD, `labour.md` §8.1) |
| `barter_ground` | 8 `tag:wood`, 4 `felt`, 4 `rope` | Aynen |
| `outpost` | 8 `tag:wood`, 2 `pole`, 4 `rope`, 3 `felt` | Çadır ve alçak kule |
| `rampart_gate` | 6 `stone`, 24 `tag:wood`, 4 `rope`, 2 `iron_bar` | Aynen; büyük yapı hedefiyle sınanır |
| `wagon_felt` | 2 `wheel_pair`, 24 `tag:wood`, 10 `felt`, 4 `iron_bar`, 6 `rope` | Aynen; 120 Yük, Göçer Avlu |
| `tent` | 2 `tag:wood`, 2 `pole`, 4 `rope`, 3 `felt` | a1; `tent_kit` |
| `stable` | 4 `stone`, 18 `tag:wood`, 4 `rope`, 10 `reed`, 3 `felt` | a1 kış biçimi; canlı kamp 32 odun |
| `fence` (10 m), `palisade` (10 m) | 6 `tag:wood`, 2 `rope`; 8 `tag:wood`, 1 `rope` | |
| `pen` (40 m) | 10 `tag:wood`, 72 `branch`, 1 `rope` | Pano başına 1 odun ya da 4 dal (örgü) |
| `shed`, `granary` | 2 `stone`, 7 `tag:wood`, 4 `rope`, 6 `branch`, 8 `reed`; tahıl ambarına +4 `clay` | a1 |
| `granary_tower` | 6 `stone`, 24 `tag:wood`, 6 `rope`, 10 `reed`, 4 `clay` | 800 Yük |
| `grain_pit` | 2 `stone`, 2 `tag:wood`, 2 `felt`, 1 `hide`, 2 `clay` | 120 Yük, gizli |
| `hut`, `tower`, `watch_tower`, `bridge`, `rack`, `road_bone` | `economy.md` §6.4 aynen | a1 |
| `felt_yard` | 1 `chiy`, 4 `tag:wood`, 4 `rope`, 2 `felt` | Ana keçe ve yuvarlama hasırı |
| `tannery` | 6 `tag:wood`, 4 `rope`, 2 `stone`, 1 `pot`, 4 `reed` | Çerçeve, ıslatma çukuru |
| `wood_shop` | 2 `stone`, 12 `tag:wood`, 4 `rope`, 1 `iron_bar`, 8 `reed` | Alet demiri |
| `smithy` | 8 `stone`, 6 `clay`, 2 `leather`, 6 `tag:wood`, 1 `iron_bar`, 6 `reed` | Körük deridir |
| `kiln` | 6 `stone`, 8 `clay` | |
| `horse_line` (20 at) | 6 `tag:wood`, 4 `rope` | |
| `well` | 6 `stone`, 4 `tag:wood`, 2 `rope`, 1 `skin_bag` | |
| `training_ground` | 8 `tag:wood`, 4 `straw`, 4 `hide`, 2 `rope` | Hedef ve direk |
| `gathering_ground` | 8 `stone`, 12 `tag:wood`, 4 `felt`, 2 `dye` | Öneri (Lung-çeng, Dailin) |
| `rampart` (10 m) | 2 `stone`, 4 `tag:wood`, 10 `branch` | Sıkıştırılmış toprak: emek ağır, malzeme hafif |
| `pit_house` | 4 `stone`, 16 `tag:wood`, 6 `clay`, 10 `reed`, 2 `felt` | |
| `field` | 2 `tag:wood`, 10 `branch` | Mevsimde 60 darı; ekim ve biçim 4 İG |
| `cart` | 1 `wheel_pair`, 6 `tag:wood`, 1 `iron_bar`, 2 `felt`, 2 `rope` | a1 toplamı aynen |
| `cart_felt` | 1 `wheel_pair`, 10 `tag:wood`, 4 `felt`, 2 `iron_bar`, 2 `rope` | `progression.md` §10.3 toplamları |
| `cart_high` | 1 `wheel_pair`, 14 `tag:wood`, 6 `felt`, 4 `iron_bar`, 2 `rope` | |
| `cart_war` | 2 `wheel_pair`, 20 `tag:wood`, 8 `felt`, 6 `iron_bar`, 4 `rope` | |

### 6.3 Onarım ve bakım

- **Onarım ham malla** yapılır, parça istemez: `structures.md` §7 maliyeti (yama ×0,5 × eksik can, yeniden kaldırma aşamanın yarısı, `repair` ¼, yanık +%25) ham biçim üstünden hesaplanır; emek `labour.md` §7. Düşen kerege kanadı için kerege takımı gerekmez: 4 odun ve 1 ip yeter.
- **Bakım** yerleşim taslağınındır (`settlement.md` §7.10): mevsim sonunda ambardan düşer (yurt gövdeliler 1 keçe, 1 ip; ahşap yapılar 2 odun, 2 saz …). Ekonomi açısından sonuç: Keçe Avlusu ve Sepi Yeri Tanhu Avlusu'nda da çalışır; bakım emeği yerleşimin %1'inden azdır.

## 7. Tüketim

### 7.1 Hane

Hane bir yurt, beş kişidir: iki yetişkin, bir genç (çırak, 0,75), bir yaşlı (hafif iş, 0,5), bir çocuk (iş vermez). Sürü ≈18 at eşdeğeri: 35 koyun, 10 keçi, 7 at, 4 sığır, ½ deve.

| Kalem | Değer | Neden |
|---|---|---|
| Pay | 4,3 öğün/gün (yetişkin ve genç 1, yaşlı 0,8, çocuk 0,5) | `army.md` 1 öğün = 1 kişi-gün |
| Yakacak | 3 birim/gün (kışın 3,5: uzun gece, ışık); 6–7 tezek | Pişirme ve ışık; K1: ısınma yok |
| Emek | 3,25 işçi − 0,5 ev işi = 2,75 × 24 = 66 İS/gün | `labour.md` §1 |
| Bakım emeği | Aşağıda | |

| mevsim | emek | çobanlık | sağım | kırkım | kesim | tezek | aş | ot | bakım | yapıya kalan |
|---|---|---|---|---|---|---|---|---|---|---|
| summer | 66 | 15,5 | 1,6 | 0,0 | 0,1 | 3,0 | 2,0 | 12,2 | 34,5 | %48 |
| winter | 66 | 15,5 | 0,0 | 0,0 | 0,1 | 3,5 | 2,0 | 0,0 | 21,1 | %68 |

### 7.2 Yerleşimin Kış Hesabı

`SupplyLedger` ambar kipidir (`economy.md` §0 «defter aynı kalır»): çizgiler aynı, sayı ambar içeriğinden gelir.

| Çizgi | Değer | %100 (`settlement.md` §9.4) | Okuyan |
|---|---|---|---|
| Yiyecek / Food | Ambardaki payların toplamı ÷ günlük pay | 30 gün | `labour.md` `K_tok` (≥35 ×1, <35 ×0,85, <15 ×0,7); hane Gönül'ü (`settlement.md` §5.4) |
| Yakacak / Fuel | Yakacak birimi ÷ günlük gereksinim | 30 gün | <15: kazan yanmaz, çiğ et pay vermez; gece ışığı yok |
| Yem / Fodder | (Ot ÷ 2 + yem bağı) ÷ kış günlük gereksinimi | Kışın 100 gün | Derin kar günü yem yoksa zud (§3.4) |
| Ok / Arrows | Yalnız ordugâh: ok ÷ (atlı × 24) | Dolu sadak | `army.md` §3.6 `quiver` |

Defter kimlikleri: yerleşim `own_camp` (`economy.md` §8.3 adı), ordugâh `camp_home`, sefer ordugâhı `camp_field`; yer kimlikleri `hold`, `camp_home`, `camp_field` (`settlement.md` §9.4, §11.2).

**Şafak** (`time.md` `dawn`): hane ve Ordu Payı ambardan düşer (önce bozulacak et kazana, sonra süt, sonra kuru erzak), yakacak yanar, kışsa yem verilir, çizgiler yeniden yazılır (`ledger:change`). Kırkım, soğum ve doğum takvim olaylarıdır.

**Kış bilerek dardır.** Yaz ve güz artığı kurut, yağ ve kak olur (yarısı kalır); soğum eti kışa yayılır; kış payı saklananla %75–115 olmalıdır. Altı çözülemez açlıktır, üstü gerilimsiz kıştır; aradaki açığı oyuncu sürek avıyla (on avcı günde ≈107 öğün getirir: 8 et × kazan), takasla, akınla ya da ordugâhı dağıtarak kapatır. Sürek avı aynı zamanda ordunun talimidir (`army.md` §3.6): kışın açlığı ve ordunun eğitimi tek karardır.

| kademe | hane | kişi | Ordu Payı | pay/gün | yaz üretim | yaz | kış üretim | kış | kış + saklanan | yakacak | yem/gün | derin kar | kış otu | ot İG |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| T1 | 3 | 15 | 1 | 14 | 22 | %159 | 10 | %74 | %105 | %182 | 7 | 31 | 2449 | 153 |
| T2 | 10 | 50 | 10 | 53 | 74 | %139 | 34 | %65 | %82 | %182 | 22 | 104 | 8163 | 510 |
| T3 | 22 | 110 | 25 | 120 | 162 | %135 | 76 | %63 | %78 | %182 | 48 | 228 | 17959 | 1122 |
| T4 | 45 | 225 | 25 | 219 | 331 | %152 | 155 | %71 | %97 | %182 | 98 | 466 | 36733 | 2295 |
| T5.walled | 80 | 400 | 60 | 404 | 589 | %146 | 276 | %68 | %90 | %182 | 174 | 828 | 65304 | 4079 |
| T5.moving | 80 | 400 | 66 | 410 | 589 | %144 | 276 | %67 | %87 | %182 | 174 | 828 | 65304 | 4079 |

**Kış açığı ve kapatma yolu** (öğün/gün):

| kademe | açık | sürek avı kolu (10 avcı) | ya da arpa torbası/gün |
|---|---|---|---|
| T1 | 0 | 0,00 | 0,0 |
| T2 | 10 | 0,07 | 1,6 |
| T3 | 26 | 0,20 | 4,4 |
| T4 | 8 | 0,06 | 1,3 |
| T5.walled | 41 | 0,32 | 6,9 |
| T5.moving | 52 | 0,40 | 8,6 |

### 7.3 Ordu

`army.md` §3.6 birimleri aynen. Ordugâhın öğününün bir payı yerleşimden gelir (**Ordu Payı / Army Share**); kalanı birliğin kendi sürüsü, sürek avı, otlak ve ganimettir. Pay ordugâh büyüdükçe düşer: ≤100 atlı %10, ≤1.000 %2,5, ≤3.000 %2. Neden: binlik ve tümen kendi boylarının sürüsüyle gelir (`army.md` §2: atlı ailesiyle kendi payındadır); düz %10 Tanhu Avlusu'na günde 300 öğün yükler: 80 hanelik yerleşim yazın bile %91'de kalır, kışın saklananla %43'e düşer (Boy Yurdu %39; sim, `depotShareByRiders` düz 0,1 ile).

| birim | atlı | öğün/gün | Yük | yem (otlaksız) | Yük | kış yakacak | savaşta yitik ok | ok yenileme İG | Ordu Payı Yük/gün | keçe araba/gün |
|---|---|---|---|---|---|---|---|---|---|---|
| ten | 10 | 10 | 1 | 30 | 60 | 6 | 48 | 2,0 | 0,1 | 0,00 |
| hundred | 100 | 100 | 10 | 300 | 600 | 60 | 480 | 20,0 | 1,0 | 0,02 |
| thousand | 1000 | 1000 | 100 | 3000 | 6000 | 600 | 4800 | 200,0 | 2,5 | 0,04 |
| tumen | 10000 | 10000 | 1000 | 30000 | 60000 | 6000 | 48000 | 2000,0 | 20,0 | 0,33 |

- **Ordu Payı** kademe başına (ordugâh atlısı `settlement.md` §10.1): Ocak 1 (10 atlı), Oba 10 (100), Boy Yurdu 25 (1.000), Toy Yeri 25 (1.000), Tanhu Avlusu 60 (3.000; Göçer Avlu ×1,1 = 66) öğün/gün. Kervanla iki günde bir: 2–132 öğün = 0,2–13 Yük.
- **Yem** otlakta 0; otlaksız (kış, Gobi, Alaşan) at başına 1 bağ: yüzlük 600 Yük/gün ister, taşınamaz. Kış seferi otlak, Menzil ambarı ya da akın ister (`army.md` §3.6 «kış seferi»).
- **Ok** savaşta atlı başına 12 atılır, %60 toplanır: yüzlük savaş başına 480 ok yitirir = 20 İG ok yapımı. Okçu Yurdu ve atlıların kendi yapımı (ordugâhta atlı başına günde 2 ok, malzeme ambardan) yeniler; ganimet oku ve arbalet oku da girer.

### 7.4 Tokluk ve saat

`time.md` §10.5 önerisi K24 olarak onaylanır: uyanıkken −5 Tokluk/oyun saati (bugünkü −2/gerçek dk ile aynı), uykuda ×0,25 (−1,25/oyun saati), çalışma atlamasında uyanık oranı (`labour.md` §6.7). Kışlak'ta 16 saat uyanık + 8 saat uyku: günde −90, tayın ve akşam kasesiyle tutar (`economy.md` §5.6 tablosu değişmez). Serbest Gez'de Tokluk yoktur (`economy.md` §5.1).

## 8. Denge hedefleri ve sonuçlar

### 8.1 Hedefler

| Ölçü | Hedef | Sonuç (sim) |
|---|---|---|
| Sıradan ham (odun, taş, saz, kil, tezek, ot) | Mete ≤12 sn/birim | En kötü taş 10 sn |
| Seyrek ham (cevher, tuz, saksavul, kökboya) | ≤40 sn/birim | Kalay cevheri 18 sn |
| Av ürünü | ≤120 sn/birim | Kurt kürkü 69 sn |
| İşlenmiş (ip, keçe, sepi deri, kömür, külçe) | ≤90 sn/birim | Demir külçe 87 sn |
| El tarifi | ≤8 sn tutuş | Hepsi (pişirme oturmadır) |
| Yurt | ≤12 dk, ≤10 İG zincir | 11,0 dk, 9,7 İG |
| Yurt gövdeli yapı (ambar, silahlık, okçu, erzak ambarı) | ≤14 dk, ≤12 İG | En çok 12,8 dk, 11,3 İG |
| Büyük yapı (otağ, yarı gömük ev, tahıl kulesi) | ≤35 dk, ≤30 İG | Otağ 19,9 dk, 18,6 İG |
| Atölye ve iş yapısı | ≤8 dk, ≤8 İG | En çok 7,8 dk, 6,3 İG (Demirci Ocağı) |
| Kap yapısı (çukur, tahıl ambarı, Hazine) | ≤8 dk, ≤8 İG | En çok 6,9 dk, 5,6 İG (Hazine) |
| Araba | ≤20 dk, ≤16 İG | Ordu arabası 18,4 dk, 15,0 İG |
| Kademe | Günü ve oyuncu dakikası kademe satırında | §8.3 |
| Kış payı | Saklananla %75–115 | %78–105 |
| Baskın | Perde başına ambar kaybı ≤%10 | En çok %7 (III) |
| Perde | Doğrudan ekonomi eylemi ≤%25 (420 dk'lık perdede ≤105 dk) | §8.4 |
| Tarif Kıymeti | 0,85–1,6 ya da gerekçeli | §4.6 |
| I. Perde | Yurt 54 birim, 146 Yük; Kış Hesabı teslimleri | Aynen |

### 8.2 Neden bu hedefler

- **Malzeme saniyesi** `economy.md` §10'un tek iş ≤2,5 dk ölçüsünden gelir: bir sefer (sırt ya da araba) bir hedefe giden yükü 2,5 dk'da toplamalıdır.
- **Yurt 12 dk**: I. Perde'de malzemenin yarısı ≈5 dk idi (`economy.md` §6.3); tamamı ve demir zinciri iki katı. Bir yurt bir oturuşta (bir oyun gecesi) toplanabilir.
- **Kademe günü** alt sınırı da vardır: kademe bir sahnede bitmemelidir (K23 kilidi hikâyeyle açar, yapı oyuncunun emeğiyle tamamlanır).
- **Perde %25**: I. Perde %12'ydi (rehine, iş bahanedir); II. Perde'den yerleşim bir oyun sütunudur ama savaş, yolculuk ve hikâyenin önüne geçmez.

### 8.3 Kademeler

Ad, kademe kapısı ve bileşim yerleşim taslağınındır (`settlement.md` §4: Ocak, Oba, Boy Yurdu, Toy Yeri, Tanhu Avlusu; V. kademede Surlu Avlu ya da Göçer Avlu). Sim bileşimi `settlement-model.json`'dan okur. Bu belgenin kademe kolları:

| Kademe | Perde | Hane | Hazır Yurt Yükü | Ordu kolu (er) | Oyuncu payı | Çevre | Ordugâh atlısı → Ordu Payı |
|---|---|---|---|---|---|---|---|
| T1 Ocak / Hearth | II | 3 | 1 (Teoman'ın armağanı) | 5 | %80 | 1 | 10 → 1 |
| T2 Oba / Clan Camp | II | 10 | 1 | 15 | %45 | 1 | 100 → 10 |
| T3 Boy Yurdu / Lineage Seat | III | 22 | 2 | 20 | %25 | 0,85 | 1.000 → 25 |
| T4 Toy Yeri / Gathering Seat | IV | 45 | 5 | 30 | %12 | 0,7 | 1.000 → 25 |
| T5 Tanhu Avlusu / The Tanhu's Court | V–VI | 80 | 8 | 50 | %5 | 0,6 | 3.000 → 60 (Göçer 66) |

**Sonuç** (sim; «gün» işçi günüyle ve boştaki bütün emek yapıya giderse alt sınırdır; gerçek süreyi gelen hane ve malzeme belirler, `settlement.md` §4.2):

| kademe | P | mevsim | hane | çevre | Yük ham | işçi İG (Mete yok) | işçi İG (Mete payıyla) | emek İS/gün | bakım İS/gün | yapıya İG/gün | gün (yalnız) | gün (payla) | hedef | pay | Mete dk | hedef dk |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| T1 Ocak | II | summer | 3 | 1,00 | 628 | 38 | 17 | 318 | 103 | 8,9 | 4,2 | 1,9 | 1–3 | %80 | 30,0 | 35 |
| T2 Oba | II | summer | 10 | 1,00 | 2026 | 121 | 83 | 1020 | 345 | 28,1 | 4,3 | 3,0 | 2–5 | %45 | 53,1 | 60 |
| T3 Boy Yurdu | III | autumn | 22 | 0,85 | 3915 | 261 | 215 | 1932 | 477 | 60,6 | 4,3 | 3,5 | 2.5–6 | %25 | 57,0 | 60 |
| T4 Toy Yeri | IV | summer | 45 | 0,70 | 6008 | 465 | 423 | 3690 | 1551 | 89,1 | 5,2 | 4,7 | 3–7 | %12 | 42,2 | 50 |
| T5 Tanhu Avlusu · Surlu Avlu | V | winter | 80 | 0,60 | 7622 | 656 | 631 | 6480 | 1688 | 199,7 | 3,3 | 3,2 | 3–10 | %5 | 21,0 | 45 |
| T5 Tanhu Avlusu · Göçer Avlu | V | winter | 80 | 0,60 | 8368 | 728 | 700 | 6480 | 1688 | 199,7 | 3,6 | 3,5 | 3–10 | %5 | 24,4 | 45 |

Okuma: Ocak'ta oyuncunun eli asıl motordur (%80 pay, 30 dk); Tanhu Avlusu'nda oyuncu karar verir, halk kurar (%5 pay, 21–24 dk). Göçer Avlu Surlu'dan ≈%10 daha çok malzeme ister (35 yurt ve 6 göç arabası, 12 yarı gömük ev ve 400 m sur yerine), emeği ise yerleşim taslağının sayımıyla daha azdır (`settlement.md` §4.3). Oyuncunun kararı büyür, tıklaması büyümez (`economy.md` §14 karar 9).

### 8.4 Perde akışı

Perde başına doğrudan ekonomi eylemi: kademe payı ve Mete'nin kendi teçhizatının (temsilî kit: II'de Hun yayı, keçe kaftan, binici çizmesi, kese kuşak, keçe çul, halka kabzalı kılıç, 40 tunç ok; III'te kemik sıyahlı yay, tunç pullu zırh, ağaç eyer, kürk çizme, kızıl pelerin, okçu yüzüğü, demir kılıç, 60 demir ok; IV'te boynuz yay, demir miğfer, alet kuşağı, uzun kılıç, savaş sadağı, 60 ok; V'te ulu yay, demir dilimli zırh, demir kolluk, savaş eyeri, at zırhı, 80 ok; VI'da 60 ok) hamından Mete'nin topladığı pay.

| perde | Mete payı | teçhizat dk | teçhizat işçi İG | kademe dk | toplam dk | tavan | 420 dk içinde |
|---|---|---|---|---|---|---|---|
| II | %60 | 9,6 | 12,0 | 83,2 | 92,7 | 105 | %22 |
| III | %45 | 17,0 | 28,0 | 57,0 | 74,0 | 105 | %18 |
| IV | %35 | 15,6 | 33,4 | 42,2 | 57,7 | 95 | %14 |
| V | %25 | 16,8 | 49,6 | 24,4 | 41,2 | 85 | %10 |
| VI | %15 | 1,9 | 10,2 | 0,0 | 1,9 | 70 | %0 |

## 9. Denge modeli

| Dosya | İçerik |
|---|---|
| `docs/design/d2/econ-model.json` | `params` (birim, saat, emek, hane, mevsim, `actSeason`, `tagRep`), `items`, `gather`, `hunts`, `herdLabour`, `herds`, `stations`, `recipes`, `structures`, `household`, `tiers`, `army`, `loot`, `kits`, `targets`, `a1` |
| `tools/econ-sim.mjs` | Node, bağımlılıksız. Modeli okur, birim maliyetlerini özyineli çözer (ham eşdeğeri, toplama ve işleme İS'i, tezgâh İS'i, Mete saniyesi), tabloları basar, hedefleri işaretler |
| `docs/design/d2/settlement-model.json` | Yerleşim taslağının modeli: sim kademe bileşimini (V. kademenin iki yolu dahil), hane sayılarını, perde oyun günlerini ve baskın sıklığını buradan okur; yapı listesinin her satırının bu modelde malzemesi olduğunu sınar. Dosya yoksa `econ-model.json`'daki yedek kopya kullanılır |

```
node tools/econ-sim.mjs                         # bütün bölümler
node tools/econ-sim.mjs --only tiers,balance    # check, items, recipes, structures, tiers, balance, army, raids, kits, loot, a1, flags
node tools/econ-sim.mjs --strict                # işaret varsa çıkış kodu 1 (CI)
node tools/econ-sim.mjs --model başka.json      # dal denemesi
node tools/econ-sim.mjs --settlement yol.json   # başka yerleşim modeli
```

**Ne sınar.** (1) Model tutarlılığı: kimlikler, etiketler, tezgâhlar, bohça ağırlığı = içeriği, el işinde tutuş, usta işinde rol. (2) Malzeme saniyesi kategorilere göre. (3) Tarif Kıymet bandı; kayıplı ya da kârlı olan gerekçe ister. (4) Yapı başına dakika ve İG. (5) Kademe günü ve dakikası (çevre katsayısı, gece çarpanı, ekip payı ×1,16 dahil). (6) Yaz payı ≥%100, kış payı saklananla %75–115, yakacak ≥%100. (7) Perde dakikası tavanı. (8) Baskında perde başına ambar kaybı ≤%10. (9) I. Perde sözleşmesi: yurt 54 birim ve 146 Yük, aşama toplamı, parça biçiminin ham biçime eşitliği.

**Baskın** (sıklık `settlement.md` §15.4; baskın başına pay R / (R + D) varsayılan nöbetle bu modelin varsayımıdır, yerleşimin R tablosu gelince oradan okunur):

| perde | yol | oyun günü | baskın aralığı (gün) | baskın | baskın başına pay | kap katsayısı | perde kaybı |
|---|---|---|---|---|---|---|---|
| II | — | 25 | – | 0,00 | %0 | 1,00 | %0 |
| III | — | 30 | 12 | 2,50 | %4 | 1,00 | %7 |
| IV | — | 40 | 30 | 1,33 | %5 | 1,00 | %5 |
| V | walled | 40 | 40 | 1,00 | %6 | 0,30 | %1 |
| V | moving | 40 | 40 | 1,00 | %6 | 0,60 | %3 |
| VI | walled | 60 | – | 0,00 | %0 | 0,30 | %0 |
| VI | moving | 60 | – | 0,00 | %0 | 0,60 | %0 |

**Bugünkü işaretler.**

```
Bütün hedefler tutuyor.
```

**Uyarı.** Sim bir uyarı basar: Gök Direği'nin malzemesi yerleşim modelindekinden farklıdır (24 → 12 taş, §6.2); bu model kazanır, yerleşim modeli güncellenir (§12).

**Sayı nasıl değişir.** JSON'u değiştir, simi koş, işaret yoksa bu belgenin tablolarını yeniden üret (tablolar betikle yazıldı). Emek sayıları (`labourWd`) `labour-model.json` ve `settlement-model.json` önerilerinin kopyasıdır: emek taslağı değişirse buradaki satır güncellenir. Sim `check-data` gibi CI'a girer (§17).

## 10. Perde perde ekonomi

| Perde | Mevsim (model) | Ekonominin yüzü | Kaynak kancası |
|---|---|---|---|
| I | Kış 210 | **Değişmez.** Kış Hesabı, tayın, zula, Kantu'nun arabası, a1 tarifleri; yeni olan yalnız büyük avın kemiği ve kabın iç yapısı (oyuncu görmez) | `economy.md` §7–§8 |
| II | Yaz 209 | Kendi ocağın (`mq2_own_hearth`: Köz Kabı ile Ulu Ocak'tan köz): Teoman'ın armağanı (1 Yurt Yükü, sürü), ilk usta, Keçe Avlusu, Sepi Yeri, Ağaç Atölyesi, Demirci Ocağı; Ocak → Oba; ordugâh ayrı, Ordu Payı başlar; Hun yayı ve tunç ok | Tanhu pazarı, Çiang tuzu, hurda |
| III | Güz 208 | Boy Yurdu: otağ (ak keçe 36 yün), Gök Direği, Takas Yeri; soğum ve ilk yerleşim kışı; Tunghu'dan kürk ve at, baskın 12 günde bir; demir azdır: ganimet ve eritme | Tunghu ganimeti, `wood_larch` |
| IV | Yaz 205–203 | Toy Yeri: Lung-çeng toplantısı, Hazine; Yüeçi ve Saka: kalay, firuze, tunç; kuyu, ordu arabası | `node_vein_tin`, Saka ve vaha satıcısı |
| V | Kış 201–200 | Tanhu Avlusu: Surlu (sur, yarı gömük ev, tahıl kulesi, tarla) ya da Göçer (35 yurt, keçe göç arabası); Han sınırı: demir hurda ve tahıl arabası, kış seferinin yemi | Han ganimeti |
| VI | Yaz 198–174 | Yönetim: dağıtım Kut terazisinde (`progression.md` §9.2); heqin malı, sınır pazarı, samur | Sınır pazarı, Dingling |

## 11. Saat ve hava bağları

**Saat (K20).** Bekleme oyun saatiyle akar, uykuda ve atlamada da (`time.md` §7.4: atlanan her şafakta `onDawn` bir kez). Kurutma sırığı 2 oyun saati (eski 5 gerçek dk ile aynı), kımız 12, sepi 12, kömür 12, yay tutkalı ve tündük 24. Satıcı 06:00–20:00 açıktır, stok şafakta yenilenir. Düğüm şafakta döner (aynen). NPC görünen programı 06–22'dir (`time.md` §10.4); emek gücü `labour.md` birimidir.

**Hava (K22).** Kimlikler `weather.md` §3; soğuk ve sıcaklık modellenmez (K1).

| Hava | Ekonomiye etkisi |
|---|---|
| Çisenti, yağmur | Açık hava beklemesi durur (sırık, Sepi Yeri'nin açık yuvası, keçe kurutma); örtüsüz ot yığını ıslak günde %2 çürür; saz ve ot biçimi ×0,8; açık ateşte pişirme ×1,25 süre, taş halkasız ateş daha çabuk söner (`survival.md` §2) |
| Sağanak | Aynısı; Keçe Avlusu durur (`labour.md` §5.2 keçe adımı) |
| Dolu | Tarla `settlement.md` §8.1 (%30–60); sırıktaki açık yığın %25 bozulur |
| Gök gürültülü fırtına | Yıldırım uzun ve tek olanı seçer (`weather.md`, `labour.md`); at hattı yoksa sürüden %1 at kaçar, ertesi gün %50'si döner |
| Sert rüzgâr | Keçe Avlusu durur; açık kurutma ×1,25 hızlı |
| Kar, yoğun kar | Toplama ×0,8; çobanlık emeği ×1,25 |
| Tipi, Kara Boran, kum fırtınası | Bütün açık hava işi durur; derin kar günü sayılır (yem); kervan kalkmaz |
| Çamur, taze kar (`weather.md` §5.9) | Araba ve kervan hızı `travel.md` kar sütunu ya da ×0,7 |

## 12. Var olan belgelerde değişecekler

`architecture.md`, `structures.md`, `audio.md`: birebir metin `d2/economy-delta-*.md` dosyalarındadır. Ötekiler (sahibi birleştirir):

| Belge | Bölüm | Değişiklik |
|---|---|---|
| `economy.md` | §0 | Sütun tablosuna üç satır: «Elin çabuktur, yurt zamanla kalkar», «Kış yazın sayılır», «Ganimet paylaşılır» (bu belge §0) |
| | §1.2 | Yeni eşleme satırları: «deri» II. Perde teçhizatında yumuşak işte `leather`, dilimli zırh, sapan ve eyerde `hide`; «tunç» `bronze_bar`; «demir» `iron_bar`; «kalay» `tin_ingot`; «boya» `dye`; «tutkal» `glue`; «kıl» `hair` |
| | §2 | Tabloya `Kademe`, `Etiket`, `Pay` sütunları ve `per` notu; §2.3'ün 21 satırı; `tin_ingot` «Yalnız takas (II–III); IV'te `rc_tin_ingot`»; okların Kıymeti |
| | §3.2 | «Sonraki perde düğümleri» paragrafı → bu belgenin §3.1 tablosu |
| | §3.6 | «Av ve tuzak» sonuna: ortak ürün Kıymet payıyla bölünür; bölge stoğu 40 / 25 / 30 |
| | §4.3 | «Binek» satırı: «Sırt yükü ata geçer; sınırı aşan alınmaz» → «Terki: atın kendi kabı, sınırı binek Yük'ü; atlıyken toplanan önce heybeye, dolunca terkiye (`d2/economy.md` §5.4)» |
| | §4.4 | Tabloya §5.1'in yeni kapları; «Sandık» satırı her hane yurduna genişler |
| | §5.2 | Sütun notu: «Pay (`ration`) = Tokluk ÷ 35; süt 0,8, kısrak sütü 0,7, arpa ve tahıl çuvalı 6» |
| | §5.3 | «Tokluk −2/dk» → «uyanıkken −5/oyun saati (−2/gerçek dk), uykuda ×0,25» |
| | §6.1 | «Bekleten sayaç yok» → «El işi bekletmez; tezgâh işi ve bekleme oyun saatiyle akar, oyuncuyu bekletmez (`d2/economy.md` §4.1)»; el, tezgâh, usta tanımları |
| | §6.2 | Tabloya «İS» (NPC emeği) sütunu: bu belgenin §4.5 değerleri |
| | §6.3 | Tablonun altına parça biçimi ve ham teslim kuralı (§6.1); «3 kişi şartı kalır» emek taslağının cümlesidir |
| | §6.4 | Başa: «Yeni türler ve parça biçimi `d2/economy.md` §6.2» |
| | §6.6 | Tablo → bu belgenin §4.5 satırları (`rc_bronze_bar` +2 kömür; `rc_yurt_crown` 10 İS, 24 sa; `rc_cauldron` 8 İS) |
| | §8.3 | «dilim» → «6 oyun saati (K20)»; Erzak Kolu «Av» satırına «4 `bone`, 4 `sinew`, 1 `fat`»; `toFood` → `ITEMS[id].ration`; «Kendi ocağın» hane tablosu (§7.1) |
| | §8.4 | Otlak bütün sürüye: at eşdeğeri koyun 0,15, keçi 0,12, at 1, sığır 1, deve 1,3 |
| | §9.3 sonu | II. Perde ve sonrası satıcıları (§3.6) |
| | §10.1 | II. Perde ve sonrası hedefleri (§8.1) |
| | §12 | Modül tablosuna §14'ün modülleri; kayıt bloğu `economy` sürüm 2 (§16) |
| | §14 | Karar satırları E24-1…E24-21 özetle |
| `survival.md` | §3 Kalite | «Kalite yalnız ateş başında hemen yenince geçerlidir; heybeye giren yemek olağandır (★2)» |
| | §4 tablo | Ceylan, yaban keçisi, domuz +2 `bone`; maral +3 `bone`, +1 `fat`; kurt +1 `bone`; yeni satırlar `argali`, `kulan`, `bustard`, `goose`, `roe`, `bear`, `sable` (§3.3) |
| | §5 «Ekipman deriden» | «tabakhane rafı `hide` + `fat` + `salt`» → «Sepi Yeri: 1 `hide` + 1 `fat` ya da `milk` → 1 `leather`, 12 oyun saati» |
| `progression.md` | §2.3 | `mountLoadK` (§5.4) ve `gear.fine` çarpanı ×1,1 |
| | §4.3 | Not: zanaatçı rolleri `d2/economy.md` §4.3; öğretmen usta ile aynı kişi olabilir |
| | §6.2 «Kaynak» | «deri» → `leather` (kaftan dışı yumuşak iş) ya da `hide` (`hide_lamellar`); tezgâh adı eklenir; İnce İş notu |
| | §6.4 | `saddle_wood` «Yaycı: 2 odun, 2 deri» → «Sepi Yeri: 1 `saddle_tree`, 2 `leather`»; `saddle_war` +1 `iron_bar`, usta; `bridle_bronze`, `horse_armor` tezgâhları |
| | §7.1 | Silah kaynakları: «Demirci Ocağı (usta): n `iron_bar`, k `charcoal`, 1 `leather`» |
| | §7.2 | Yaylar: +1 `glue` (`hun_bow`, `bone_bow`), +2 (`heavy_bow`, `horn_bow`, `great_bow`); Okçu Yurdu, usta, 24 sa bekleme |
| | §7.3 | Ok tarifleri: 5 temren + 5 gövde + 1 tüy → 5; tunç temren 1 külçe → 30 (döküm), demir 1 → 15 |
| | §10.3 | Araba tarifleri parça biçimiyle (§6.2) |
| | §13.2 | `economy` bloğu sürüm 2 (§16) |
| `army.md` | §3.6 tablo, «Yem» satırı | «Bağ (1 Yük)» → «Bağ (2 Yük)»: Yem Bağı `economy.md` §2.5'te 2 Yük'tür (a1) |
| | §3.6 «Taşıma» | «`cart_felt` 40 Yük: 400 öğün ya da 40 Bağ» → «`cart_felt` 60 Yük: 600 öğün ya da 30 Bağ»; «Kışın Onluk otlaksız bölgede günde 11 Yük» → «günde 61 Yük (10 öğün 1 Yük, 30 atın yemi 60 Yük)» |
| | §3.6 | `supply` çizgileri ordugâhın `supply_depot` kabından okunur; Ordu Payı ölçek tablosu (§7.3); ganimetin ambar payı (%25 / %75); ok yenileme |
| | §9 | Erzak Ambarı içeriği yerleşimin `settlement` / `camps` bloklarındadır (`settlement.md` §16) |
| `travel.md` | §3.2 | Not: bir Yurt Yükü bir keçe arabaya ya da iki deveye sığar |
| | §7.2 | Değer tablosuna «Yurt Yükü 60» (Kıymet ÷ 4) |
| | §9.7 | Kervan `settlement.md` §11'dedir; yük biçimi `d2/economy.md` §5.3 |
| `act1.md` | | Sayı değişmez. §9.2 Tokluk satırı zaman taslağının saat oranıyla birlikte yazılır |
| `d2/time.md` | §10.4 | «günlük üretim saati 16» → «görünen program 16 saat; emek 1 İG/gün, açık hava gece ×0,4 (`econ-model.json` `params.outdoorK` 0,8)» |
| `d2/labour.md` | §11.7 | `inventory.site(id)` bu belgenin `Container`'ıdır (`d2/economy-delta-architecture.md`) |
| `d2/settlement.md` | §7.6 `sky_pole` | Malzeme «taş 24» → «taş 12» (§6.2: on iki ay; küçük yapı hedefi) |
| | §10.1, §11.2, §11.4 | Ordu Payı «yerleşik atlı × 0,1» → «× ölçek payı: ≤100 %10, ≤1.000 %2,5, ≤3.000 %2» (§7.3); «II: 10, V: 300 öğün/gün» → «II: 10, III–IV: 25, V–VI: 60 (Göçer 66)»; §11.4 akışı buna göre (V–VI ≈120 öğün/sefer) |
| | §9.1 | `grain_pit` süzgecine `tag:grain`; `shed` süzgecine `fodder` |
| | §16 `settlement` bloğu | Yeni alanlar: `stores` (yerin kaplarının `Container.toJSON`'u: `{ kapId: { id: n } }`) ve `workshops` (tezgâh başına `Workshop.toJSON`: kuyruk, bekleme); `camps.<id>.depot` aynı biçim |
| | §21 «Denge» | «kış ambarla ≥0,95» → «kış ambarla %75–115 bandı (bilerek dar; açığı sürek avı, takas, akın kapatır)» |
| | §23 soru 4 | Yanıt: † malzemeler onaylandı (Gök Direği 12 taş); `ember_pot` tanımlandı (§2.3, `rc_ember_pot`); `@army_share` = n günlük Ordu Payı, yalnız kuru erzak (§5.3); Yem Bağı 2 Yük (`army.md` düzelir) |

## 13. Yapılı kodda değişecekler

Bu fazda kod değiştirilmez; liste sonraki fazın paketidir (`d2/economy-delta-architecture.md` §5: Faz 8 paketleri).

| Dosya | Yer | Değişiklik |
|---|---|---|
| `src/world/structure-logic.js` | `_have`, `_spend` (215–240) | Ad öneki kuralı (`tag:wood` → `wood_*`) yerine `matches(id, ref)` (`game/items.js`); bugün yalnız odun için doğru |
| | `deliver` (208) | Bohça açılır: `yurt_kit` → parçalar; `contrib` birim sayar (a1 %50 kuralı aynen) |
| | `sliceTick`, `advance` | Adımın parça ya da ham karşılanması: `step.parts` varsa ve teslim edildiyse adımın emeği aynı; ham ise `rawWork` İD eklenir (emek taslağının `work` alanına) |
| `src/world/structure-defs.js` | `YURT_STEPS` | `y_bosaga` `parts: { door_frame: 1 }`, `rawWork: 360`; `y_kerege` `parts: { kerege_set: 1 }`, `rawWork: 720`, `rawRole: 'cr_carpenter'`; `y_uuk` `parts: { uuk_set: 1 }`, `rawWork: 480`; `y_liner` `parts: { chiy: 1 }`, `rawWork: 120`. `cost` (a1) değişmez |
| | `CART` `c_axle` | `parts: { wheel_pair: 1, 'tag:wood': 1, iron_bar: 1 }`, `rawWork: 600` |
| `src/game/damage.js` | `attackFor`, `makeAttack` | `baseId(id)` ile `+` eki; İnce İş hasar ×1,1 |
| `src/data/weapons.js`, `damage-tables.js` | | Değişmez |

## 14. Uygulama taslağı

**İlke.** Ekonomi saf servis verir; onları süren sistemler başka alanlarındır (E24-21). Kişisel kaplar `Inventory`'nindir; yerleşim ve ordugâh kaplarını, tezgâh kuyruklarını, sürüyü ve kervanı yerleşimin `SettlementSystem`'i (`settlement.md` §18: `state.js`, `production.js`, `stores.js` `StorePool`, `caravans.js` `CaravanBook`, `camps.js`) sürer; şantiye yığını emeğin `SiteSystem`'inindir (`labour.md` §11.5). Yeni `GameSystem` yoktur.

Saf modüller (`architecture.md` §6.1 listesine girer, `tools/check-pure.mjs`; birebir metin `d2/economy-delta-architecture.md` E5–E8):

```js
// game/items.js (saf): eşya tablosu ve çözüm (data/items.js + data/gear.js + data/weapons.js)
ITEMS[id] = { tr, en, tier, w10, per = 1, stack, worth, tags, act, ration, fuel, bundle, source, food, tool, slot, fine };
export function matches(id, ref);        // 'tag:wood' | 'felt'; '+' eki baseId ile
export function baseId(id);  export function isFine(id);
export function stackLoad10(id, n);      // ceil(n × w10 / per)
export function rationOf(id);  export function fuelOf(id);  export function bundleOf(id);

// game/container.js (saf): bütün kaplar
export class Container {
  constructor({ id, kind, cap10, slots = 0, accept = null, owner = null, hidden = false });
  load10();  free10();  count(ref);  has(ref, n = 1);  list();
  canTake(id, n);  add(id, n, { day, allowOver });  remove(ref, n);
  onDawn(day, { perishFish = true });
  toJSON();  fromJSON(o);
}
export function transfer(from, to, ref, n);

// game/craft.js (saf): tarif çözümü; Workshop yerleşimin production.js'ince sürülür
export function canCraft(recipe, { inv, station, role, skills });   // → { ok, missing }
export function craftHand(recipe, inv);
export class Workshop {
  constructor({ id, station, slots, crewMax });
  order(recipeId, n, { fine });  cancel(i);
  tick(gameMin, { crewW, lit, weather, pool });    // labour.eff(W); açık bekleme yuvası yağmurda durur
  toJSON();  fromJSON(o);
}

// game/herds.js (saf): sürü SettlementState'te durur, hesap buradadır
export function herdDay(counts, season, { deepSnow, fodder, pasture });   // → { yields, labourIS, fodderUse, losses }
export function herdEvent(counts, name, season);                         // shear | comb | births | sogum

// game/loot.js (saf); data/loot-tables.js
export function roll(tableId, rng);                   // → [{ id, n } | { herd, n } | { gear }]
export function booty(defeated, { recovery = 0.6, share });

// game/supply.js (saf): SupplyLedger iki kipte; ambar kipi settlement.md §9.4 bağdaştırıcısıdır
export class SupplyLedger {
  constructor(id, { mode = 'abstract', fuel, food, fodder, pool = null, need = null });
  value(line);  add(line, n);  onDawn(loss);  freezeToy();  consume(day, season);
  toJSON();  fromJSON(o);
}
export function armyShare(riders);       // Ordu Payı (§7.3)
```

| Sürücü | Ne zaman | Ekonomi çağrısı |
|---|---|---|
| `Inventory` (8.2) | `dawn` | Kişisel kapların `onDawn` bozulması |
| `barter.js` (8.4) | `dawn` | Satıcı stoğu yenilenir |
| `SettlementSystem` (`settlement.md` §18.2) | `clock:hour`, `dawn`, `clock:skip` | `Workshop.tick`, `herdDay`, `herdEvent`, `SupplyLedger.consume`, `StorePool` kaplarının `onDawn`'ı |
| `CaravanBook` (`settlement.md` §11) | Kalkış, varış | `transfer`, `armyShare`, `rationOf` |
| `SiteSystem` (`labour.md` §11.5) | Teslim | `inventory.site(id)` (Container), bohça açma, `matches` |
| Savaş (`combat`, `army`) | Düşman düşünce, akından sonra | `roll`, `booty` |

- **WorldSpec**: kış dünyası (Kışlak, Faz 9) `perish: { fish: false }` taşır; yerleşim dünyasının ambar, tezgâh ve sürü alanları `spec.settlement`'tadır (`settlement.md` §13.4). Kamp spec'i değişmez: menü karesi aynı.
- **`StagedStructure`**: `deliver` bohçayı açar; şantiye yığını `inventory.site(id)` Container'ıdır (`labour.md` §6.3); `parts` ve `rawWork` `d2/economy-delta-structures.md` S1.
- **`NodeStore`** (§3.12): uzak toplama `applyTaken(cluster, n)` ile (`settlement.md` §9.5); çevre katsayısı (§3.1) bu sayaçtan okunur.
- **Ordu** (`army.md` §3): `UnitRec.supply` bir görünümdür: ordugâh kabından `food` (pay ÷ güç), `fodder`, `arrows`, `fuel`; `remounts` ordugâh sürüsünün at sayısı.
- **Arayüz**: `ui/transfer.js` (iki sütun, bütün kaplar), Heybe'ye Terki sekmesi (at yakınken); tezgâh siparişi ve ambar çizgileri Yerleşim Defteri'ndedir (`settlement.md` §14.2).
- **Gizli panel** `__tanhu.econ` ekleri: `put(id, n, containerId)`, `perish()`, `craft(recipeId, n)`, `loot(tableId, seed)`; yerleşim ambarı, sürü ve kervan `__tanhu.hold`'dadır.

## 15. Bütçe

| İş | Tavan | Not |
|---|---|---|
| Kare başına | 0 | Ekonomi servisleri olayla çalışır |
| `Container.onDawn` | ≤0,2 ms | Kişisel kaplar ve yerin kapları |
| `Workshop.tick`, `herdDay` | Yerleşimin saat bütçesinin içinde (≤0,5 ms, `settlement.md` §17) | 40 tezgâh, beş sürü sayısı |
| Bellek | `ITEMS` ≈130 satır, tarif ≈80 | Sabit tablo |
| Çizim, program | Yok | Kap ve tezgâh yapıdır: bütçesi emek ve yerleşim taslağının; aktarma paneli DOM |
| Ses | `d2/economy-delta-audio.md` | Tezgâh döngüsü ≤2 kaynak |
| Kayıt | `economy` ≤6 KB | Yolculuk ≤96 KB içinde |

## 16. Kayıt

`economy` bloğu sürüm 2 (`progression.md` §13.2; `architecture.md` §3.5 sıra 41–44 aynen). Ekonomi yalnız kişisel kapları yazar; yerleşim ve ordugâh ambarlarının içeriği, tezgâh kuyrukları, sürü ve kervan yerleşimin `settlement` (order 77) ve `camps` (order 92) bloklarındadır (`settlement.md` §16; o bloğa `stores` ve `workshops` alanı istendi, §12).

```jsonc
"economy": {
  "v": 2, "nodesV": 1,
  "pack": { "wood_pine": 2, "meal": 1 }, "tools": ["axe_iron"], "chest": {}, "seized": null,
  "saddlebags": { "offering_stallion": { "felt": 4 } },                // yeni
  "stash": {}, "cart": {}, "sled": {}, "cache": [],
  "perish": { "pack": { "meat": [[1203, 2], [1204, 1]] } },          // yeni: gün anahtarlı bozulan yığın
  "ledger": { "fuel": 62, "food": 46, "fodder": 51 }, "ledgerToy": null, "needs": { "fullness": 60 },
  "nodes": { "perm": "<base64>", "day": [], "piles": [] },
  "stats": { "felled": 0, "stones": 0, "delivered": 0, "gatherSec": 0, "playSec": 0, "crafted": 0 }
}
// settlement bloğuna istenen iki alan (biçim Container.toJSON ve Workshop.toJSON):
"stores":    { "store_yurt_1": { "wool": 40, "felt": 12 }, "grain_pit_1": { "qurt": 60, "gold_old": 1 } },
"workshops": { "felt_yard_1": { "q": [["rc_felt_batch", 2, 3.5]], "cures": [["rc_felt_batch", 4.2]] } }
```

- **Göç 1 → 2**: yeni alanlar boş; `pack` ve öteki kaplar aynen; bozulan yığın bugünün günüyle başlar.
- **İnce İş** kimlikte taşınır (`inventory.equip.bow: "hun_bow+"`); ayrı alan yok.
- **Boyut**: `economy` ≈4 KB; Tanhu Avlusu'nun ambarları ≈60 kimlik × 6 kap ≈3 KB (`settlement` bloğunun 10 KB'ı içinde).

## 17. Test planı

**Saf (`node:test`).**
1. `stackLoad10`: ok 10 adet 5, 11 adet 6; kütük 3 adet 120.
2. `Container.canTake`: Yük sınırı onda birle; kabul süzgeci (Tahıl Ambarı odun almaz, Hazine yalnız `tag:valuable`); yuva sınırı yalnız Heybe'de.
3. `transfer` kısmi: sığmayan kalır, toplam korunur.
4. Bozulma: bugün 2 et + dün 1 et; şafakta 1 `spoiled`, 2 et; `perishFish: false` ile balık kalır.
5. `matches`: `tag:wood` `wood_larch`'ı, `tag:wood_light` `wood_birch`'ü kabul eder; `hun_bow+` `hun_bow`'dur.
6. Bohça: `yurt_kit` teslimi şantiye yığınına 8 kimlik, 21 parça; ağırlık 60 Yük.
7. Yurt eşdeğerliği: parça biçimi bir düzey açılınca a1 ham biçimi; 54 birim, 146 Yük.
8. `Workshop.tick`: 4 elle `eff` 3,439; yağmurda açık bekleme durur, çatı altı sürer; usta yoksa usta işi başlamaz.
9. `herdDay`, `herdEvent`: yaz sütü, kış derin kar yemi; yemsiz derin kar günü %2 kayıp, kış tavanı %30; soğum ve kırkım.
10. `SupplyLedger` ambar kipi (sahte havuz): 30 günlük pay %100; yem kışın 100 gün; `K_tok` eşikleri 35 ve 15; `armyShare(100)` 10, `(1000)` 25, `(3000)` 60.
11. `loot.roll` tohumlu ve tekrarlanabilir; insan dönmez (K23).
12. `booty`: paylaş %25, alıkoy %75.
13. I. Perde regresyonu: Kış Hesabı teslim tablosu (`economy.md` §7) birebir; a1 tutuşları.
14. Kayıt: `economy` v2 gidiş dönüşü; v1 göçü.

**Statik.** `node tools/econ-sim.mjs --strict` CI'da (`d2/economy-delta-architecture.md` E12): model hatası, kaçan hedef ya da yerleşim modelinde malzemesiz yapı düşürür. Kod tablolarının modelle eşitliği: `data/items.js` ve `data/craft-recipes.js` yazılınca `tools/check-data.mjs` modeldeki kimlik ve sayıları karşılaştırır (paket isteği).

**Tarayıcıda.** Emeğin kum havuzu (`?state=play&sandbox=site`, yerleşim kipi `&hold=1`) içinde `__tanhu.econ.put`, `craft`, `loot`; aktarma paneli TR ve EN; menü karesi `menuDiff` (değişmez).

## 18. Doldurulan boşluklar

1. Beş kademeli taksonomi ve kimlik kuralları; 21 yeni kimlik.
2. `per` alanıyla adetli küçük eşyanın onda bir Yük'le yazılması.
3. El hızının var olan sayılardan çıkarılması ve iki hız kuralı.
4. Kalitenin yalnız teçhizatta, İnce İş olarak, deterministik verilmesi.
5. Yurdun parça biçimi, ham teslim kuralı ve eşdeğerlik sınaması.
6. Yurt ve çadır bohçası; bir yurdun bir keçe arabaya sığması.
7. II. Perde ve sonrası düğümleri, biyom tablosu, çevre katsayısı.
8. Av verimine kemik ve iç yağı; yedi yeni av hayvanı; ortak ürün emeğinin Kıymet payıyla bölünmesi; bölge stoğu.
9. Sürünün baş başına mevsimli üretimi, soğum, kırkım, tarama, derin kar ve zud kuralı, çobanlık ve ot emeği.
10. Düşman başına ganimet tabloları, at yakalama, yağmalanan kamp, sağlam yurdun ganimet olarak sökülmesi; ganimetin ambar payı.
11. II. Perde ve sonrası satıcı satırları.
12. Söküm ve yıkıntı kurtarma payları.
13. Sepi zinciri, tutkal, boya, kıl ipi, ak keçe, döküm ve dövme temren, eyer kaşı, teker çifti.
14. Tezgâhların emek taslağının yapılarına bağlanması; kazan ve sırığın yapı olmayan tezgâh olması.
15. Zanaatçı rolleri, dereceleri ve usta olma kuralı.
16. Kap sınıfı, kap tablosu, aktarma kuralları, Terki ve binek yükünün hıza etkisi.
17. Ordu Payı'nın ölçek tablosu; kervan yükünün biçimi (`@army_share`, yalnız kuru erzak); Köz Kabı; kandil yağı; `tag:valuable`.
18. `SupplyLedger` ambar kipi, çizgi yüzdesinin 30 günlük paya bağlanması.
19. Hane bileşimi, payı, yakacağı, emeği ve bakım emeği.
20. Yerleşimin Kış Hesabı bandı ve açığın sürek avıyla kapanması.
21. Onarımın ham malla yapılması; yurt başına perde bakımı.
22. Bozulmanın gün anahtarıyla tutulması.
23. Kademe önerisi ve kademe, perde hedefleri; yeniden koşulabilir model.
24. Hava ve saatin ekonomi tepki tablosu.

## 19. Açık sorular

> **Kapandı (2026-11-04, E6).** Taslak izdir (K31); sekiz sorunun hepsi kapandı, sahibi belgeler ve K'ler geçerlidir. Her maddenin sonunda kapatan karar yazılıdır.

1. **Yerleşim (K23):** II. Perde açılışındaki armağanın ölçüsü (1 Yurt Yükü ve ≈4 at eşdeğeri sürü, `settlement.md` §5.3 `hh_story` ile) ve ilk dülgerin kim olduğu (öneri: canlı kampın Oktar'ı). Kerege takımı ve tündük usta işidir: dülger gelmeden yalnız hazır yük ve takas tündüğü kalkar. (K23 ve K52 ile kapandı: armağan K23'ündür; ilk dülger II'nin hikâye hanesiyle gelen Ruodi'dir, atölyeyi Oba açılınca kurar; `story.md` §14.2.)
2. **Saat (K20):** NPC'nin emek gücü 1 İG/gün (gece açık hava ×0,4) ile görünen 06–22 programı birlikte kalabilir mi? Model öyle sayar; `time.md` §10.4 cümlesi güncellenmeli (§12). (K21 ile kapandı: inşaat gece de sürer, üretim ve ev işi 16 saatlik penceredir; `structures.md` §2.4.)
3. **İlerleme:** yaylara tutkal, oka tüy ve döküm temren, «deri»nin `leather` / `hide` ayrımı, İnce İş ×1,1 (`progression.md` §6–§7). Sahibi onaylamalı; reddedilirse yalnız tarif satırları değişir, denge kayda değer oynamaz. (K24 ile kapandı: tarifler `progression.md` §6–§7'ye ve `economy.md` §6.10'a işlendi.)
4. **Hayatta kalma:** büyük avın kemiği ve iç yağı I. Perde verimini küçük ölçüde değiştirir. Onay. (K24 ile kapandı: `economy.md` §3'te; K65 av döngüsü `fauna.md`.)
5. **Ordu:** Ordu Payı ölçek tablosu (%10, %2,5, %2), ganimet payı (%25 / %75) ve Yem Bağı'nın 2 Yük'e birleşmesi (`army.md` §3.6). Sahibi onaylamalı. (K23 ve K24 ile kapandı: Ordu Payı yerleşik atlının düz %10'u, ölçek tablosu kalktı; Yem Bağı 2 Yük; ganimet %25 / %75, `economy.md` §3.12.)
6. **Baskın payı:** baskın başına kayıp (III %4, IV %5, V %6; varsayılan nöbetle `R / (R + D)`) bu modelin varsayımıdır; `settlement.md` §15.4'ün R tablosu yazılınca sim oradan okur. (K24 ve K55 ile kapandı: tek baskın kuralı `R / (R + D)`, akın yalnız ay penceresinde, perde tavanlı; `economy.md` §10.8.)
7. **Ot emeği** yazın hane emeğinin ≈%18'i; derin kar payı dünya başına hava taslağından gelmeli (model 0,15). (K49 ile kapandı: derin kar payı `weather-model.json` v2'nindir, Tanhu Ordusu'nun kışında %16,0; ot biçimi takvimdedir, `d2/core.md` §7.1.)
8. **Mete'nin sınırsız el keçesi** (4 sn/keçe) bilerek açık bırakıldı; darboğaz yündür. Erken kademede oyuncunun yerleşimi kendi eliyle hızlandırması amaçtır. (Soru değildir, kapandı: `economy.md` §8.1'in bilinçli kuralıdır, 2 yün → 1 keçe, 4 sn.)

## 20. Doğrulama durumu ve kaynaklar

- **Okundu:** `decisions.md`; `architecture.md` §0, §1, §3.5, §3.7, §3.8, §3.11–§3.13, §3.22, §5, §6, §7; `economy.md` bütünü; `survival.md` bütünü; `progression.md` §1.3, §1.4, §4.1–§4.5, §6–§13; `structures.md` §0–§4, §7, §10, §11, §14, §15; `army.md` §0–§3; `travel.md` §3.2, §7, §9, §11; `act1.md` §1, §2, §9.1–§9.4, §16, §17; `audio.md` §4; `contract-requests.md` Faz 6; d2: `labour.md`, `labour-model.json`, `time.md`, `weather.md`, `settlement.md`, `settlement-model.json` ve bütün delta dosyalarının bu belgeye değen maddeleri (aynı satıra değen eklerin birleşmesi `d2/economy-delta-architecture.md` başında). Kod: `src/data/weapons.js`, `src/data/damage-tables.js`, `src/world/structure-defs.js`, `src/world/structure-logic.js` (teslim, maliyet, kayıt).
- **Betikle hesaplandı:** bütün türetilmiş tablolar (`tools/econ-sim.mjs`, `econ-model.json` ve `settlement-model.json` ile); 0 işaret, 1 bilinen uyarı (Gök Direği malzemesi).
- **Tahmin, oyunda ölçülmedi:** Mete saniyeleri (II. Perde ölçüsü), av dakikaları, sürü verimleri, kademe bileşimi. İlk yerleşim diliminde `stats.gatherSec / stats.playSec` ve `__tanhu.econ.ledger` ile ölçülür; sapma JSON'a yazılır, sim yeniden koşulur.
- **Hafızadan, bu oturumda doğrulanamadı:** Shiji 110 (ana sürü at, sığır, koyun; deve ve eşek seyrek; «suyu ve otu izleyerek göçerler»; ganimet kuralı, `army.md` §1 #12), Hanshu 94A (kuyu, sur, tahıl kulesi öğüdü; Mete'den geç dönem), Ivolga kalesi (Ulan-Ude yakını; sur, hendek, yarı gömük ev, demir ocağı, darı), Noin-Ula odalarının melez ağacı, Pazyryk parmaklı tekeri ve keçesi, Moğol bozkırında zud ve otor. Metne geçmeden denetlenir.
- **`tasarım tercihi`** (Destan Kitabı'nın kurgu listesine girmez): Yurt Yükü ölçüsü, hane bileşimi, El hızı oranı, İnce İş, zanaatçı dereceleri, kademe adları (K23 onayına dek), biyom tablosu.
