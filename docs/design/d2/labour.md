# Emek ve İnşa / Labour and Construction (K21)

> **İşlendi (2026-11-03).** Emek yasası `d2/structures-delta.md`'ye (`structures.md` §2.4, §2.5, §4.6, §11.6) işlendi, veri `d2/labour-model.json` v2'dir. Bu taslak iz için kalır; `L` onu işlemez.

> **Baş tasarımcı notu (2026-11-03).** Kesişen sayılar ve kurallar `d2/core.md` §2'dedir ve bu taslakla çeliştiği yerde kazanır (adım tablosu, tek el yalnız tündükte, ekip çizelgesi, `rawWork`, `dayCapacity`, gece emri, sığınma tablosu, Çocuğun fiil kuralı, camp3 sayıları ve «aile bekler», Kışlak gönderimi, `job_raise` yok). Bu taslak sonraki adımda var olan belgelere işlenirken `d2/core.md` §8 uygulanır.

Taslak (`d2`), Faz 7 bitince birleşir. Alan: emek yasası, ekip verimi, yurdun 13 adımının emeği, roller, sekiz yardım türü, hasar ve onarımın emek karşılığı, öteki yapılar ve K23 yapıları, üçüncü yurdun (`camp3`) ve Kışlak Yeni Yurdu'nun saatle yeniden zamanlanması, genel inşaat alanı (şantiye), Faz 6 kodunun yeniden çalışma listesi. Bağlayanlar: `decisions.md` K1–K19 ve yönetmen kararları K20 (gün 60 dk), K21 (emek), K22 (hava), K23 (yerleşim), K24 (ekonomi). Kimlikler ve kod İngilizce, oyun içi metinler TR / EN, hepsi yeni yazıldı.

Sayıların makine okunur kopyası `docs/design/d2/labour-model.json`; bu belgedeki bütün tablolar o dosyadan betikle hesaplandı (§19).

**Komşu taslaklar okundu ve uyuldu:** `d2/time.md` (K20: `WorldClock`, `clock:skip`, Bekle tekeri, `lightLevel`, ana kampın ve Kışlak'ın saat programı, Serbest Gez'in 14:46 açılışı, ustaların öğün sırası), `d2/weather.md` (K22: hava kimlikleri, `fx.moonSeen`, yıldırım kuralları, ustaların `SHELTER` durumu, `sleet` ve `dry_storm` satırları), `d2/economy.md` ve `d2/econ-model.json` (K24: tek emek havuzu, `labourWd` bu belgenin kopyası, zanaatçı rolleri, yaşlı ağırlığı). Çelişen tek nokta: zaman taslağı ustaları 22:00'de bıraktırıyor, K21 inşaatı kesintisiz sayıyor; çözüm önerisi §9.5. `architecture.md`, `structures.md`, `audio.md` Faz 7 boyunca düzenlenmez; bu belgenin onlara getirdiği değişiklikler birebir metinle `d2/labour-delta-architecture.md`, `d2/labour-delta-structures.md`, `d2/labour-delta-audio.md` dosyalarındadır. Öteki belgelerin değişiklik listesi §16.

## 0. Karar özeti

| # | Karar | Sayı | Neden |
|---|---|---|---|
| E1 | Emek birimi **iş dakikası (İD)**: bir işçinin bir oyun dakikalık emeği. 60 İD = 1 **iş saati (İS)**; 1.440 İD = 1 **iş günü (İG)** | Tek işçiyle 1 İD = 2,5 gerçek sn; 1 İG = 60 gerçek dk | K20 saatine bağlı tek para: kurulum, onarım, taşıma, söküm, ileride zanaat aynı birimle sayılır |
| E2 | Ekip verimi `eff(W) = min(W, 10 · (1 − 0,9^W))`; W ekipteki ağırlıkların toplamı | 1 → 1; 2 → 1,9; 3 → 2,71; 4 → 3,44; 6 → 4,69; 8 → 5,70 | K21 dizisinin kesirli uzantısı: yarım işçi yalnızken tam yarım iş yapar |
| E3 | **El (baş) ile ağırlık ayrıdır.** İki ellik adım baş sayısına, hız ağırlığa bakar | Usta + çocuk iki eldir | Tutmak güç değil el ister; çocuk ve çırak en çok burada değer kazanır |
| E4 | Yurdun 13 adımı tek el emeğiyle **1.440 İD**. Dört adım iki elliktir (kerege, tündük, tuurduk, üzük): yalnız işçi onları yavaş yöntemle yapar | Ekip emeği 1.282 İD; yalnız yöntemin fazlası 158 İD | K21: «tek işçi bir günde»; «tündük iki el ister, yalnız işçi bakanla yavaş kaldırır» |
| E5 | Adım başına el sınırı; yurtta en çok 8 el | 1 → 60,0; 2 → 28,5; 3 → 20,4; 4 → 16,3; 5 → 14,1; 6 → 12,6; 7 → 12,0; 8 → 11,6 dk | K21 ideal dizisinden en çok %−9,7 ile %+10,2 sapar; el arttıkça süre hep kısalır |
| E6 | Roller: Usta 1, El 1, Çırak 0,75, Yaşlı 0,5 (usta sayılır), Çocuk 0,5; Mete 1 ve emek becerileri | Yapının zanaatından usta yoksa ×0,7; işi ilerletmek için ekipte ağırlığı ≥0,75 ya da usta sayılan biri | Ağaç ve toprak zanaatçısı yerleşimde aranır; çocuk tek başına kuramaz |
| E7 | Sekiz yardım türü **işçi katkısıdır**: Çocuk ekibe katılınca yarım el sayılır; kütük, köz ve su ayak işleridir, ustanın yolunu ve adımın getirme payını üstlenir. Kredi ve 3 kat erime kalkar | camp3 14:54'te başlar: yardımsız ilk duman 00:16 (23,4 gerçek dk), Çocuğun bütün yardımıyla 22:46 (19,7 dk) | K21 «çocuk yarım işçi»; dürüst ve okunur katkı |
| E8 | İnşaat gece de sürer, ışık şartıyla: meşale direği ya da ateş ışığı ×1, ay görünürse ×0,7, karanlık ×0,4. Şantiyeye «Gece dinlenilsin» emri verilebilir: ekip zaman taslağının iş penceresine (06:00–22:00) çekilir | Meşale direği karanlığın 4 saatinde 1 `torch` yakar; ana kampta ve senaryo şantiyesinde bedava | K21 «meşale ve ateş ışığında kesintisiz»; K1: ışık yalnız gösterir, ısıtmaz |
| E9 | Hava şantiyeye çarpan ve durak verir (K22) | Yağmur ×0,85, keçe ×0,7; sağanakta keçe, gök gürültüsünde uzun iş, sert rüzgârda keçe durur; dolu, tipi, Kara Boran, toz fırtınası her şeyi durdurur | Keçe ıslanır ve ağırlaşır, rüzgârda yelken olur; yıldırım uzun ve yalnız şeyi sever |
| E10 | Malzeme şantiyenin yığınında durmalıdır. Ambardan taşıma ayrı emektir; ustalar 150 m'ye dek kendi taşır | 146 Yük'lük yurt 50 m'den 224 İD (%15,6), 150 m'den 621 İD; araba 3 seferde 54 İD | Ambarı yapıya yakın kurmak ve arabayı kullanmak bir karardır |
| E11 | Onarım emekle: yeniden kaldırma ×0,8, yama ×0,6 × eksik can, yanık birim ×1,25, `repair` ×0,5, yeniden koşan adım ×0,8 | Ateşli ok 7→5 sonrası 457 İD; camp3 ekibiyle 7,6 dk | `structures.md` §7 formülü saniye yerine İD ile |
| E12 | Söküm (göç) kurulum emeğinin 0,35'i; malzeme yığına döner, köz yanar | Yurt tek başına 21 dk, 4 kişiyle 5,7 dk | K23 mevsim kampları, `wagon_felt` |
| E13 | **Çalışma atlaması**: «Akşama dek çalış» uyku gibi saati atlatır, emek işler | | 60 dakikalık yalnız işi oyuncuya izletmemek |
| E14 | camp3 üç ustayla baştan sona: Oktar ve Erka usta, Dengiz çırak (0,75); yığın 4 kütük eksik başlar; öğün sırası zaman taslağından | Saf emek 535 oyun dk (22,3 dk); 14:54 başlangıç ve öğünle 9 sa 22 dk = 23,4 gerçek dk; Çocuğun bütün yardımıyla 7 sa 52 dk = 19,7 dk | K21; 590 sn ve 283 sn kalkar |
| E15 | Kışlak Yeni Yurdu saatle, ekiple ve malzemeyle ilerler; tündük `mq_crown`'u, ocak `mq_feast`'i bekler | Ekip Nanay ve iki el; bütün emek ≈8 iş saati, darboğaz malzeme ve hikâye kapıları | Act I temposu, %50 katkı kuralı ve kapılar korunur |
| E16 | Esir emeği yoktur: işçi havuzu hane, er ve gönüllü firaridir | | K23 |

## 1. Birimler ve saat

| Ölçü | Değer |
|---|---|
| 1 oyun günü | 24 oyun saati = 60 gerçek dakika (K20) |
| 1 oyun saati | 2,5 gerçek dakika |
| 1 oyun dakikası | 2,5 gerçek saniye; 1 gerçek saniye = 0,4 oyun dakikası |
| İD, iş dakikası | Bir işçinin bir oyun dakikası emeği |
| İS, iş saati | 60 İD |
| İG, iş günü | 1.440 İD = 24 İS; tek işçiyle 60 gerçek dakika |

**Oran.** Bir adımda ekibin oranı oyun dakikası başına İD'dir: `oran = eff(W) × K / solo` (§2, §5). Kalan oyun dakikası `kalan İD / oran`, gerçek saniye bunun 2,5 katı. Saat `WorldClock`'tur (`game/world-clock.js`, `d2/time.md` §12.2): emek onun `abs` oyun dakikasıyla akar. Saat durunca (menü, duraklatma, harita, Bekle tekeri açıkken) emek de durur; saat atlayınca (uyku, Bekle, çalışma atlaması, atlas yolculuğu) emek `clock:skip` olayında toplu işlenir (§6.8).

**Sözcükler.** HUD kalan süreyi yaklaşık oyun saatiyle yazar, zaman taslağının biçimiyle: «≈3 saat» / «≈3 hours» (§6.11). Defter'in yapı sayfası bitişi gün sözcüğüyle ve iş saatiyle yazar: «Akşam biter · ≈9 iş saati» / «Done at dusk · ≈9 work-hours». Yapı listesinde emek «1 iş günü» / «1 work-day» biçimindedir.

**Bir yetişkin günde 1 İG verir.** K21 emeği kesintisiz sayar: ışıklı şantiyeye verilen bir yetişkin bir oyun gününde 1 İG emek üretir. Açık hava üretim işleri (sürü, sağım, keçe dövme) zaman taslağının günlük programına uyar ve gece karanlıkta ×0,4 çalışır: `econ-model.json` `outdoorK` 0,8 (16 sa × 1 + 8 sa × 0,4 = 19,2 İS). Yerleşim ve ekonomi iş gücünü bu tek birimle hesaplar; zanaat da İS ile ödenir (`d2/economy.md` E24-3).

## 2. Ekip verimi

```
eff(W) = min(W, 10 · (1 − 0,9^W))          // W ≤ 1'de doğrusal, W ≥ 1'de K21 dizisi
W      = adımın el sınırına (max) dek en ağır üyelerin ağırlık toplamı
eller  = ekipteki baş sayısı (çocuk dahil)
```

| W | 0,5 | 0,75 | 1 | 1,5 | 2 | 2,5 | 2,75 | 3 | 3,25 | 3,5 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `eff` | 0,50 | 0,75 | 1 | 1,46 | 1,90 | 2,32 | 2,52 | 2,71 | 2,90 | 3,08 | 3,44 | 4,10 | 4,69 | 5,22 | 5,70 |

- **Neden 0,9.** Her yeni el bir öncekinden biraz az katar: aynı ipi, aynı kanadı, aynı yolu paylaşırlar. K21 dizisidir; W < 1'de doğrusal kol, yarım işçiye 1'den küçük üslü dizinin verdiği %2,6 fazlayı vermez.
- **Sıra bağımsız.** `eff` toplam ağırlığa bakar; aynı ekip hangi sırayla gelirse gelsin aynı hızdadır. El sınırı aşılırsa en ağır üyeler çalışır, kalanlar o adımda taşımaya ya da sonraki adımın yığınına geçer (§6.3), oran değişmez.
- **Yapı başına tavan.** Yurtta en çok 8 el (`def.crewMax`); ötekiler §8. Fazlası şantiyeye atanamaz.
- **Dağıtmak mı, yığmak mı.** 8 el tek yurtta günde 5,70 İG üretir; ikişer dörtlük iki şantiyede 6,88 İG. Tek yapıyı çabuk bitirmek ile toplam işi büyütmek arasında seçim oyuncunundur (yerleşim kararı, K23).

## 3. Roller ve ağırlıklar

| Rol | id | TR / EN | Ağırlık | Usta sayılır mı | Not |
|---|---|---|---|---|---|
| Usta | `usta` | Usta / Master | 1 | Kendi zanaatında | Sırayı bilir, adımı başlatır |
| El | `hand` | El / Hand | 1 | `home` zanaatında evet | Her yetişkin bir yurdu kurmayı bilir |
| Çırak | `apprentice` | Çırak / Apprentice | 0,75 | Hayır | 12–16 yaş; işi ilerletebilir |
| Yaşlı | `elder` | Yaşlı / Elder | 0,5 | Kendi zanaatında | Güç yarım, bilgi tam: usta sayılır, önder olur (`econ-model.json` `workerEq.elder` 0,5) |
| Çocuk | `child` | Çocuk / Child | 0,5 | Hayır | Yalnız Serbest Gez'in oyuncusu; yerleşimin çocukları atanmaz (`workerEq.child` 0); işi tek başına ilerletemez |
| Mete | `mete` | Mete | 1 | Her yetişkin gibi `home`'da | Emek becerileri aşağıda; Kışlak'ta Nanay'ın ekibinde eldir |

**Zanaat (`def.craft`).** `home` (Ev / Household): yurt, otağ, çadır, çit, ağıl, keçe avlusu, ordugâh yapıları; her yetişkin ustadır. `wood` (Ağaç / Woodwork): ahır, sundurma, ambar, kule, köprü, araba, atölye. `earth` (Toprak / Earthwork): kuyu, sur ve hendek, yarı gömük ev, ocak ve fırın, tarla. Usta zanaatı ve ağırlığı kişinin kaydındadır (yerleşim alanı hane kaydına yazar). Ekonominin zanaatçı rolleri (`cr_*`, `d2/economy.md` E24-19) bunlara eşlenir: `cr_carpenter` `wood` ustasıdır; çırak kendi zanaatında 120 İS çalışınca usta olur (ekonomi kuralı).

**İki kural.**
1. **Önder kuralı:** ekipte ağırlığı ≥0,75 ya da usta sayılan kimse yoksa iş ilerlemez (çocuk yalnız kalırsa bekler; yaşlı usta tek başına yürütür). Yırtık dikmek bu kuralın dışındadır (§7).
2. **Usta kuralı:** yapının zanaatından usta yoksa oran ×0,7: «Usta yok: iş yavaş» / «No master: the work is slow». `home` yapılarında her yetişkin usta sayıldığı için kural yalnız çırak ekiplerinde ve ağaç, toprak yapılarında işler. Böylece zanaatçı hane yerleşimde aranır.

**Mete: bir ve emek becerileri** (`progression.md` §4.5, sayılar değişmez, K21 anlamı yazılır).

| Beceri | Sayı | K21 karşılığı |
|---|---|---|
| (yok) | | Mete ekipte 1 ağırlıkla çalışır, `home` ustası sayılır; ağaç ve toprak zanaatı yoktur, onları yerleşimin ustası taşır |
| `carry_pack` | `load+8` | Taşıma seferinde yük tavanı +8 (§6.3); kurulum oranına etkisi yok |
| `repair` | `repairCost=0.25`, `repairTime×0.5` | Mete'nin çalıştığı onarımda emek ×0,5, malzeme ¼ (§7) |
| `quick_raise` | `buildTime×0.7`, `helpers+1` | Mete ekipteyken o şantiyenin oranı ×1/0,7 (≈×1,43); Mete'nin buyurduğu şantiyeye yerleşimin boştaki elinden biri kendiliğinden katılır |
| `wagon_ring` | 20 sn kuruluş | Savaş düzenidir, emek yasası dışında kalır: 8 `fence` parçası arabalarda hazır taşınır |
| Öteki emek becerileri | | Kurulum oranına etkisi yok |

Tek başına Mete bir yurdu 60 dk'da, `quick_raise` ile 42 dk'da kurar; ilk onluk (8 el) ile 11,6 dk, `quick_raise` ile 8,1 dk.

**Adlı büyük ustalar.** Ağırlık alanı 1,25'e dek çıkabilir (yerleşim alanının seçtiği adlı kişiler, örneğin bir ağaç ustası). Bu belge tavanı 1,25 koyar.

**Esir emeği yok.** İşçi havuzu yalnız özgür insanlardır: hane, er (birlikten `cmd_detail`), gönüllü firari (K23).

## 4. Yurt: 13 adım

### 4.1 Emek tablosu

Aşama, malzeme ve can `structures.md` §3.1 ile aynıdır; yalnız süre ve iş gücü sütunları değişir. «Tek el» bir işçinin harcadığı emek, «Ekip» iki ve daha fazla elin harcadığı emek, «Çarpan» tek el yönteminin fazlasıdır. El sınırı baş sayısıdır.

| Adım | TR / EN | Aşama | Tek el İD | Ekip İD | Çarpan | El en az | El en çok | Pay (tek el) |
|---|---|---|---|---|---|---|---|---|
| `y_site` | Zemin ve Ocak Halkası / Ground and Hearth Ring | 0 | 75 | 75 | 1 | 1 | 8 | %5,2 |
| `y_bosaga` | Bosağa / Door Frame | 1 | 75 | 75 | 1 | 1 | 4 | %5,2 |
| `y_kerege` | Kerege / Lattice Walls | 2 | 170 | 136 | 1,25 | 2 | 6 | %11,8 |
| `y_bag` | Kerege Bağı / Tension Band | 2 | 45 | 45 | 1 | 1 | 6 | %3,1 |
| `y_tunduk` | Tündük / Crown | 3 | 160 | 100 | 1,6 | 2 | 6 | %11,1 |
| `y_uuk` | Uuk / Roof Poles | 4 | 270 | 270 | 1 | 1 | 8 | %18,8 |
| `y_liner` | İç Örtü ve Çiy / Inner Liner and Reed Screen | 5 | 105 | 105 | 1 | 1 | 6 | %7,3 |
| `y_tuurduk` | Tuurduk / Felt Walls | 6 | 150 | 120 | 1,25 | 2 | 8 | %10,4 |
| `y_uzuk` | Üzük / Felt Roof | 6 | 170 | 136 | 1,25 | 2 | 8 | %11,8 |
| `y_kolan` | Kolan / Girth Ropes | 7 | 105 | 105 | 1 | 1 | 6 | %7,3 |
| `y_esik` | Kapı Keçesi / Door Curtain | 7 | 20 | 20 | 1 | 1 | 2 | %1,4 |
| `y_sirdak` | Şırdak / Floor Felts | 7 | 75 | 75 | 1 | 1 | 6 | %5,2 |
| `y_ocak` | Ocak Yakma / Hearth Lit | 7 | 20 | 20 | 1 | 1 | 1 | %1,4 |
| **Toplam** | | | **1.440** | **1.282** | | | | %100 |

**Payların dayanağı.** Faz 6'nın adım başına işçi-saniyesi (süre × usta: 60, 70, 140, 40, 135, 220, 90, 120, 140, 80, 15, 60, 20; toplam 1.190) 1.440'a ölçeklendi, sonra üç düzeltme yapıldı: ocak 20 İD'de kaldı (bir el, köz getirme dahil), kolan 105'e çıktı (3 çember ve 24 radyal bağ), eşik 20'ye yuvarlandı. Gerçek kurulumda uuk ve keçe en uzun iştir; tablo da öyle.

**El sınırlarının gerekçesi.** Zemin: 8 kazık, 8 el. Bosağa: iki dikme, iki yanda ikişer. Kerege: 6 kanat, kanat başına bir el. Bağ: kuşağı birkaç çift dolar. Tündük: 3 bakan ve tündüğü kilitleyen ilk sırıkları takan 3 el. Uuk: 8 dilim, dilim başına bir el. Çiy ve iç örtü: dışta 4, içte 2. Tuurduk ve üzük: 4 panel, panel başına iki el (biri çeker, biri yönetir). Kolan: 3 çember, ikişer el. Kapı keçesi iki elliktir. Şırdak: yurdun içi dardır, 6 el. Ocak: köze bir kişi üfler.

### 4.2 İki ellik adımlar ve tek el yöntemleri

Ekipte en az iki baş varsa (ağırlık ne olursa olsun) adım iki elle yürür. Tek baş kalınca adım durmaz, yavaş yöntemle sürer; HUD yöntemi yazar.

| Adım | Tek el yöntemi TR / EN | Çarpan | Görünen |
|---|---|---|---|
| `y_kerege` | «Tek el: destek kazığıyla» / «One pair of hands: with a prop stake» | ×1,25 | Her kanat çatal kazıkla dik tutulur, komşusuna bağlanır, kazık kuşaktan sonra sökülür |
| `y_tunduk` | «Tek el: bakanla, yavaş yavaş» / «One pair of hands: on the raising pole, slowly» | ×1,6 | Bakanlar sehpa kurar, tek işçi ayakları sırayla kaldırır: 3 hamle yerine 6 küçük hamle, `uHoist` 6→5→4→3→2→1→0, yalpa ×1,5 |
| `y_tuurduk` | «Tek el: kazıkla gererek» / «One pair of hands: pegged and stretched» | ×1,25 | Panelin üst kenarı çatal sopayla kerege başına asılır, alt kenarı kazıklanır, sonra bağlanır |
| `y_uzuk` | «Tek el: halatı kazığa dolayarak» / «One pair of hands: rope round a stake» | ×1,25 | Çekme halatı tündüğün üstünden karşı kazığa dolanır; işçi dolanır, gevşeği alır, geri gelip yönetir |

Hareketler mevcut jestlerdir (`heave`, `reach_up`, `tie`, `haul`); yeni jest gerekmez. Usta ve çocuk ya da usta ve çırak iki eldir: tek el çarpanı kalkar. Usta ile çocuk bir yurdu 36,8 dk'da, usta ile çırak 32,1 dk'da kurar (yalnız usta 60 dk).

### 4.3 Ekip çizelgesi

Yetişkin ekip (ağırlık 1), usta var, gündüz, açık hava.

| El | `eff` | Oyun saati | Gerçek dk | K21 ideali | Sapma |
|---|---|---|---|---|---|
| 1 | 1 | 24 sa 00 dk | 60,0 | 60,0 | 0 |
| 2 | 1,90 | 11 sa 24 dk | 28,5 | 31,6 | %−9,7 |
| 3 | 2,71 | 8 sa 09 dk | 20,4 | 22,1 | %−8,0 |
| 4 | 3,44 | 6 sa 32 dk | 16,3 | 17,4 | %−6,5 |
| 5 | 4,10 | 5 sa 37 dk | 14,1 | 14,7 | %−4,1 |
| 6 | 4,69 | 5 sa 01 dk | 12,6 | 12,8 | %−1,9 |
| 7 | 5,22 | 4 sa 48 dk | 12,0 | 11,5 | %+4,5 |
| 8 | 5,70 | 4 sa 39 dk | 11,6 | 10,5 | %+10,2 |

**Sapmanın iki nedeni.** Küçük ekipte ikinci el tek el yöntemini kaldırır: iki kişi yalnız işçinin iki katından da hızlıdır (158 İD fazlalık gider). Büyük ekipte el sınırları ve tek kişilik ocak sıkışma yaratır: sekiz kişi kapı keçesine ve köze sığmaz. İkisi de K21'in izin verdiği biçimlendirmedir; el her arttığında süre kısalır (sınandı, §15).

**Adım başına oyun dakikası.**

| Adım | 1 el | 2 | 3 | 4 | 6 | 8 |
|---|---|---|---|---|---|---|
| `y_site` | 75,0 | 39,5 | 27,7 | 21,8 | 16,0 | 13,2 |
| `y_bosaga` | 75,0 | 39,5 | 27,7 | 21,8 | 21,8 | 21,8 |
| `y_kerege` | 170,0 | 71,6 | 50,2 | 39,5 | 29,0 | 29,0 |
| `y_bag` | 45,0 | 23,7 | 16,6 | 13,1 | 9,6 | 9,6 |
| `y_tunduk` | 160,0 | 52,6 | 36,9 | 29,1 | 21,3 | 21,3 |
| `y_uuk` | 270,0 | 142,1 | 99,6 | 78,5 | 57,6 | 47,4 |
| `y_liner` | 105,0 | 55,3 | 38,7 | 30,5 | 22,4 | 22,4 |
| `y_tuurduk` | 150,0 | 63,2 | 44,3 | 34,9 | 25,6 | 21,1 |
| `y_uzuk` | 170,0 | 71,6 | 50,2 | 39,5 | 29,0 | 23,9 |
| `y_kolan` | 105,0 | 55,3 | 38,7 | 30,5 | 22,4 | 22,4 |
| `y_esik` | 20,0 | 10,5 | 10,5 | 10,5 | 10,5 | 10,5 |
| `y_sirdak` | 75,0 | 39,5 | 27,7 | 21,8 | 16,0 | 16,0 |
| `y_ocak` | 20,0 | 20,0 | 20,0 | 20,0 | 20,0 | 20,0 |

**Karışık ekipler.**

| Ekip | W (çoğu adımda) | Gerçek dk | Oyun saati |
|---|---|---|---|
| Usta + çocuk | 1,5 | 36,8 | 14 sa 43 dk |
| Usta + çırak | 1,75 | 32,1 | 12 sa 50 dk |
| Yalnız el, usta yok (×0,7) | 1 | 85,7 | 35 sa 43 dk |
| camp3: Oktar, Erka, Dengiz, yığın tam | 2,75 | 21,8 | 8 sa 44 dk |
| camp3 + Çocuk, yığın tam | 3,25 | 19,1 | 7 sa 39 dk |
| Kışlak: Nanay + iki el | 3 | 20,4 | 8 sa 09 dk |
| Mete yalnız, `quick_raise` | 1 | 42,0 | 16 sa 48 dk |
| Mete + ilk onluk (8 el), `quick_raise` | 5,70 | 8,1 | 3 sa 15 dk |

## 5. Çarpanlar ve duraklar

```
oran = eff(W) × K_usta × K_beceri × K_gece × K_hava × K_tok × K_su × hız / solo     // İD / oyun dk
solo = eller < adım.min ? adım.solo : 1
```

| Çarpan | Değer | Kaynak |
|---|---|---|
| `K_usta` | 1; zanaat ustası yoksa 0,7 | §3 |
| `K_beceri` | Mete ekipte ve `quick_raise` öğrenilmişse 1/0,7 | §3 |
| `K_gece` | Aydınlık 1; karanlıkta ışık varsa 1, ay görünürse 0,7, yoksa 0,4 | §5.1 |
| `K_hava` | §5.2 tablosu | K22 |
| `K_tok` | Yerleşimin `food` çizgisi ≥35: 1; <35: 0,85; <15: 0,7 | `SupplyLedger` (§11.8) |
| `K_su` | Su getirildiyse 1 oyun saati 1,1 | §9.3 |
| `hız` | Gizli panel `__tanhu.struct.speed` | |

### 5.1 Gece

- **Karanlık:** `WorldClock.dark` (güneş ufkun altında; `d2/time.md` §12.2); alacakaranlık ışık sayılır.
- **Sınıf:** şantiyede ışık kaynağı varsa ×1. Yoksa `lightLevel(sunEl, moonEl, illum, cloud)` (`d2/time.md` §12.3): ≥0,6 gündüz ×1; 0,25–0,6 ve havada `fx.moonSeen` (`d2/weather.md` §8.11: bulut <0,6, yağış ve sis yok) ×0,7; ötesi ×0,4. Kapalı gecede ay ışığı yoktur.
- **Işık kaynağı:** (a) şantiyenin meşale direği (`torch_post`, şantiye başına 1, yurtta 2 görsel), yığında `torch` varken; (b) ışık yarıçapı şantiye merkezine 4 m payla erişen yanan bir ateş (`survival.md` §2: küçük 6 m, orta 10 m, büyük 14 m); (c) yerleşimin fenerleri (yerleşim alanı). Ana kampta ve senaryo şantiyelerinde meşale bedavadır (`spec.labour.torchFree`).
- **Tüketim:** meşale direği karanlığın her 4 oyun saatinde yığından 1 `torch` alır (bir gece ≈3). `torch` 1 dal + 1 reçinedir (`economy.md` §6.2): gece işi küçük bir reçine talebi doğurur.
- **Gece emri:** «Gece de çalışılsın» / «Work through the night» (inşaatın varsayılanı, K21) ya da «Gece dinlenilsin» / «Rest at night»: ekip zaman taslağının iş penceresine çekilir (ana kamp 06:00–22:00, Kışlak 07:00–23:00, yerleşim ve ordugâh mevsimine göre; `d2/time.md` §10.1), pencere içinde batıştan sonra yine meşalede çalışır. Penceredeki tek işçinin yurdu 1,5 günde biter; öğün sırası (§9.1) iki kipte de işler.
- **Görünürlük:** ışıklı şantiye gece uzaktan görünür (`act1.md` «ışık gösterir ama ele verir»); gizlilik bölgesinde nöbetçi algısına ateş gibi eklenir.
- **K1:** ışık yalnız gösterir; üşüme, ısınma, soğuk cezası yoktur.

### 5.2 Hava (K22 tepki tablosu)

Hava kimlikleri ve olasılıkları hava alanınındır; bu tablo yalnız şantiyenin tepkisidir. «Keçe adımı» `y_tuurduk`, `y_uzuk`, `y_esik`, `y_sirdak`, `c_tilt`, `t_cover`; «uzun iş» `y_tunduk`, `y_uuk`, kule ve kiriş adımları (`tall`).

| Hava | Genel | Keçe adımı | Durak | Ustanın sözü (TR / EN) |
|---|---|---|---|---|
| Açık, bulutlu, kapalı, sis | 1 | 1 | | |
| Çisenti | 1 | 0,9 | | |
| Yağmur | 0,85 | 0,7 | | «Islak keçe iki kat çeker.» / «Wet felt pulls twice as heavy.» |
| Sağanak | 0,5 | 0 | Keçe adımı bekler | «Keçeyi yağmura açmayız. Bekleyelim.» / «We don't open felt to the rain. We wait.» |
| Gök gürültülü fırtına | 0,5 | 0 | Uzun iş ve keçe bekler; ekip bakandan 6 m çekilir | «Bakanın dibinden çekilin. Gök uzun şeyi sever.» / «Step away from the poles. The sky loves a tall thing.» |
| Dolu | 0 | 0 | Hepsi, kısa | |
| Rüzgâr | 1 | 1 | | |
| Sert rüzgâr | 0,9 | 0 | Keçe bekler; kerege 0,8 | «Bu rüzgârda keçe yelken olur.» / «In this wind the felt becomes a sail.» |
| Sulu kar | 0,85 | 0,7 | | |
| Kuru fırtına | 0,9 | 1 | Uzun iş bekler | «Bakanın dibinden çekilin. Gök uzun şeyi sever.» / «Step away from the poles. The sky loves a tall thing.» |
| Kar | 0,9 | 0,9 | | |
| Yoğun kar | 0,7 | 0,7 | | |
| Tipi, Kara Boran, toz fırtınası | 0 | 0 | Hepsi; ekip sığınağa gider | «Ustalar fırtınanın dinmesini bekliyor.» / «The builders are waiting out the storm.» (`lock.weather_build`, hava taslağı) |

Sulu kar ve kuru fırtına satırları hava taslağının önerisidir (`d2/weather.md` §8.11); kimlikler o taslağın §3.1 listesiyle birdir.

- **Islak keçe:** yağmurda ya da çisentide asılan keçe biriminin ıslaklığı hava taslağının `felt` durum değişkenidir (`d2/weather.md` §5.9); kuruma ve `structures.md` §6.2 sıçrama çarpanı oradadır.
- **Yıldırım:** hava taslağının adil kuralı geçer: tamamlanmamış yapı hedef olmaz («oyuncunun emeği bir anlık zarla yanmaz», `d2/weather.md` §8.7). Ekip yine de gök gürültüsünde ve kuru fırtınada uzun işi bırakır, bakandan 6 m çekilir: bekleyiş korkudur, zarar değil. Bitmiş yapıya düşen yıldırımın onarımı §7 ile.
- **Sığınma:** durak sürerken ustalar en yakın yurdun ya da ahır çatısının altına yürür (`SHELTER`, hava taslağı); `sev` 0,25 oyun saati <3 kalınca döner. Emek değişmez, takvim uzar (ana kampta ortalama ≈%8, hava taslağının benzetimi).
- **Yollar:** taşıma seferinde araba hızı `travel.md` §3.2'nin yol ve kar sütunundan; çamur hava alanının zemin durumudur (§6.3 formülü hızı oradan okur).

## 6. Genel inşaat alanı (şantiye)

### 6.1 Kavram

**Şantiye / Building Site** (`ConstructionSite`): bir `StagedStructure`'ın yerleşimden bitişe ve sökümüne dek bütün yaşamı: yer, yığın, ekip, emirler, bekleme nedeni, katkı. Herhangi bir `STRUCTURE_DEFS` türüyle çalışır. camp3 bunun özel, elle döşenmiş bir örneğidir (§9); Kışlak Yeni Yurdu senaryolu bir örneği (§10); II. Perde'den yerleşim ve ordugâh yapıları oyuncunun açtığı örneklerdir (K23). I. Perde altyapıyı ve geliştirici kum havuzunu kurar (`?state=play&sandbox=site`); hikâye açılışı II. Perde'dedir.

### 6.2 Yerleşim

- **Kip:** yapı listesinden tür seçilir, ayak dibinde iz önizlemesi (`Game.marker` gölgelendiricisi; yeni program yok), yeni `keymap.rotate` eylemi (öneri `R`) ya da tekerlek 15° döndürür. Kapı varsayılanı yerleşimin ocağına bakar (`act1.md` Kışlak kuralı).
- **Geçerli yer:** iz `def.bounds` ile; yürüme ızgarasında kapalı hücre (`blocked`, `sb`) yok; eğim normal.y ≥ 0,9 (yurtta ped, `y0` izin en yüksek noktasından; `site-pad.js` genelleşir); su ve buz yok; başka yapının duvarına ≥4 m (keçe yapıda yangın sıçraması, `contract-requests.md` açık maddesi: §6.2 yarıçapı merkezden ölçülüyor); yollara ≥3 m; senaryo yasak alanı yok.
- **Düğümler (§3.12):** izdeki ağaç ve iri kaya yerleşimi engeller (önce kesilir, kırılır: odun ve taş verir); dal, ot, tezek düğümleri `y_site`'ta silinir (`perm` biti).
- **Geçersizse** halka kızıl, neden yazılır: «Yer düz değil» / «The ground is not level», «Ağaç var» / «A tree stands here», «Başka yapıya çok yakın» / «Too close to another building».
- **Yer işaretlenince** aşama 0 öncesi şantiye doğar: kazık ve ip izi (`G_STAKES`), boş yığın alanı.

### 6.3 Yığın, teslim ve taşıma

- **Yığın / Stock:** şantiyenin kapı yanındaki dikdörtgeni, `Inventory` kabı (`architecture.md` §3.13'e eklenecek `site(id)`): `{ add, remove, list, load, cap }`, `cap` türün toplam malzeme yükünün 1,25 katı.
- **Teslim:** oyuncu yığında `E` 1 sn: heybedeki uyan malzeme girer (`economy.md` §6.3 kuralı), `contrib.player` sayılır. Yere bırakılan yığın (`node_ground_pile`) yığın dikdörtgenindeyse teslim sayılır. Araba yükü (`travel.md` «Yük Bindir») varışta kendiliğinden boşalır.
- **Tüketim:** adım başlarken o adımın `cost`'u yığından adıma geçer (yığın görünür biçimde azalır). Eksikse adım başlamaz: «Malzeme bekliyor: 4 keçe» / «Waiting for materials: 4 felt». Malzeme listesi K24 ekonomisinden gelir (bileşenler: kerege, uuk, tündük, keçe panel); emek tablosu malzemeden bağımsızdır.
- **Kendi taşıması:** malzeme bağlı bir ambarda 150 m içindeyse ekip kendisi taşır. Önce adımın el sınırını aşan boştaki eller gider; yoksa en hafif üye ekipten çıkar (oran düşer).
- **Taşıma formülü** (görünmeyen sefer, aynı sayılar ustaların `V_FETCH`, `V_CARRY` hızlarıdır):

```
sefer_sn = d / 1,9 + d / 1,4 + 8            // boş, dolu, alma ve bırakma
sefer    = ceil(yük / tavan)                  // tavan: yetişkin 20, çırak 14, çocuk 6 Yük; Mete loadMax
taşıma_İD = sefer × sefer_sn / 2,5            // taşıyanın kendi zamanı; ağırlık değil tavan önemlidir
araba    : sefer_sn = 2d / v + 30; tavan travel.md §3.2 (keçe araba 60, v yolda 6,8)
```

| Yurt, 146 Yük | 25 m | 50 m | 100 m | 150 m | Araba, 50 m |
|---|---|---|---|---|---|
| Sefer | 8 | 8 | 8 | 8 | 3 |
| Taşıma İD | 125 | 224 | 423 | 621 | 54 |
| Yurt emeğine oranı | %8,7 | %15,6 | %29,3 | %43,1 | %3,7 |

150 m ötesi: «Malzeme uzakta» / «The materials are far away»: oyuncu getirir ya da araba atanır («Arabayla taşı» / «Haul by cart»).

### 6.4 Ekip atama

- **Havuz:** yerleşim halkı (K23 hane kaydı: yetişkin, çırak; çocuk atanmaz), ordugâhta birliğin eli (`UnitRec.strength − wounded`, `cmd_detail` İş Kolu), I. Perde'de senaryo kişileri. Bir kişi aynı anda tek şantiyededir; şantiyede çalışan başka iş üretmez (sürü, keçe, nöbet: yerleşim ve ekonomi alanı).
- **Arayüz:** şantiyede `E` «Ekip» / «Crew» ya da Defter'in yapı sayfası: + / − ile el; usta kendiliğinden seçilir; bitiş sözcüğü canlı değişir. «Boştaki eller yapıya» / «Idle hands to building» yerleşim ayarı açıkken boşta kalan yetişkinler önceliği en yüksek şantiyeye gider.
- **Öncelik:** 0–3; atama ve kendi taşıması önce yüksek önceliğe.
- **Oyuncu:** Mete şantiyede `E` «Çalış» / «Work» ile ekibe 1 ağırlıkla girer (§6.7 atlamasıyla); Çocuk «Ustalara Katıl» / «Join the Builders» ile yarım el (§9.3). Hareket girdisi ekipten çıkarır: «Ekipten ayrıldın» / «You left the crew».

### 6.5 İlerleme

- Görünen ve uzak bütün şantiyeler kare başına `dİD = dOyunDk × oran` işler; oran ekip, gece, hava ya da yığın değişince yeniden hesaplanır (≤4 Hz), kare başına ayırma yok.
- Adım bitince olay `structure:step_done`; bütün yapı bitince `structure:done` ve `site:done` (`first`).
- **Ustanın görünümü zaman çizelgesini süsler** (`structures.md` §10.2 kuralı aynen): takılan görünür işçi emeği kilitlemez.

### 6.6 Kesintiler ve bekleme nedenleri

Öncelik sırasıyla tek neden yazılır.

| id | TR / EN | Ne olur |
|---|---|---|
| `fire` | «Yangın söndürülüyor» / «Putting out the fire» | Emek durur, ekip kova zinciri (§6.3 `structures.md`) |
| `threat` | «Tehlike: iş bırakıldı» / «Danger: work abandoned» | 40 m içinde düşman ya da baskın: `FLEE`, emek durur |
| `storm` | «Ustalar fırtınanın dinmesini bekliyor.» / «The builders are waiting out the storm.» | §5.2 durakları, `SHELTER` |
| `weather` | «Keçe yağmur dinsin diye bekliyor» / «The felt waits for the rain to ease»; «Rüzgâr keçeyi alıyor» / «The wind is taking the felt»; «Yıldırım: bakanın dibi boşaltıldı» / «Lightning: the poles are left alone» | Yalnız o adım durur; ekip sonraki adımın yığınını hazırlar, emek işlemez |
| `material` | «Malzeme bekliyor: {liste}» / «Waiting for materials: {list}» | Adım başlamaz |
| `far` | «Malzeme uzakta» / «The materials are far away» | 150 m ötesi |
| `crew` | «Ekip yok» / «No crew» | Önder kuralı |
| `dark` | «Karanlık: meşale yok» / «Dark: no torches» | Oran ×0,4 ya da ×0,7, durmaz |
| `rest` | «Gece dinleniyorlar» / «Resting for the night» | Gece emri |
| `story` | «Tündük kaldırılmayı bekliyor» / «The crown waits to be raised» | Senaryo kapısı (§10) |

### 6.7 Çalışma atlaması

Uyku ve Bekle saati atlatır (K20, `d2/time.md` §7); çalışma da atlatır ve zaman taslağının **Bekle tekerini** kullanır. Mete şantiyedeyken `T` (ya da şantiyede `E` basılı 1 sn) tekeri çalışma kipinde açar: satırlar «Bir saat çalış» / «Work for an hour», «Üç saat çalış» / «Work for three hours», «Akşama dek çalış» / «Work until evening», «Bitene dek çalış» / «Work until it's done»; her satır hedef saati yazar, «Bitene dek» bitiş anını `etaMinutes`'ten okur. Kurallar Bekle'ninkidir: en çok 12 oyun saati, aynı yer kısıtları ve kesintiler (`d2/time.md` §7.1, §7.3). Saat `clock:skip { reason: 'work' }` ile atlar, emek Mete ekipteymiş gibi işler (`quick_raise` dahil), Tokluk uyanık oranıyla düşer (`d2/economy.md`: −5 / oyun saati), kayıt yazılır. Tokluk <25 ise çalışma satırları kapalı: «Önce bir şey ye.» / «Eat something first.» Serbest Gez'de Çocuğun «Bir saat yardım et» / «Help for an hour» satırı aynı yoldur.

### 6.8 Uzak şantiye, atlama ve dönüş

- Kadraj dışındaki şantiyede işçi çizilmez, emek işler. 120 m ötesinde aktör yoktur, 40–120 m kukla (`army.md` T1), 40 m içinde en çok 8 tam `Folk` (§13).
- **Toplu benzetim** `simulate(state, dakika, ortam)`: saat dilimli (oyun saati başına bir ortam örneği: gece, hava, ekip, öğün), her dilimde adım adım O(adım). `clock:skip` (uyku, Bekle, çalışma, yolculuk; `d2/time.md` §7.4) ve dünyaya dönüş (`catchUp(şimdi − lastMin)`) bunu çağırır; atlamanın saat başı olaylarını (`skipping: true`) yok sayar. Yerleşim Mete yokken de büyür (K23); hava geçmişi hava taslağının tohumlu saatlik zincirinden okunur.
- **Eşdeğerlik:** 600 dakikalık toplu benzetim 600 tek dakikalık adımla aynı sonucu verir (±1e−6 İD, §15).

### 6.9 Söküm

«Sök» / «Dismantle»: adımlar tersten, her adım kurulum emeğinin 0,35'i (tek el çarpanı da 0,35'le), el sınırları aynı. Görünüm kurulumun tersidir (`uGK` 1→0, döküntü yok). Malzeme yığına döner, `ember` yanar. Yurt tek başına 21 dk, 4 kişiyle 5,7 dk; `wagon_felt` 120 Yük taşır. Mevsim kampları ve göç (K23) bunu kullanır.

### 6.10 Olaylar

`site:placed`, `site:wait` (`{ id, reason }`, değişince), `site:crew` (`{ id, heads, W }`), `site:done`, `site:dismantled`; yapının `structure:*` olayları aynen.

### 6.11 Arayüz

- **HUD inşaat parçası** (`ui/hud/build-status.js`, camp3'te var olan): ad, adım, birim sayacı, düğümler ve yeni bir satır; kalan süre zaman taslağının biçimiyle oyun saatidir (`d2/time.md` §10.1): «Ekip: 3 el · ≈3 saat» / «Crew: 3 hands · ≈3 hours»; Çocuk ya da Mete ekipteyse «Ekip: 3 el + sen» / «Crew: 3 hands + you»; bekleme nedeni varsa sürenin yerine geçer. Tek el yöntemi sürerken alt satırda yöntem yazar (§4.2). Yalnız değişince yazılır.
- **Bitiş sözcüğü** Defter'in yapı sayfasında ve çalışma tekerindedir: `now + kalan` oyun saatine göre.

| Bitişin saati | TR | EN |
|---|---|---|
| 05:00–07:59 | şafakta | at dawn |
| 08:00–10:59 | sabah | in the morning |
| 11:00–13:59 | öğlende | at midday |
| 14:00–16:59 | ikindide | in the afternoon |
| 17:00–19:59 | akşam | at dusk |
| 20:00–23:59 | gece | at night |
| 00:00–04:59 | gece yarısından sonra | after midnight |

Gün öneki: aynı gün yok; ertesi gün «yarın» / «tomorrow»; ≥2 gün «{n} gün sonra» / «in {n} days,». Kalıp «{gün}{saat} biter» / «Done {day}{time}», ilk harf büyür: «Yarın öğlende biter» / «Done tomorrow at midday».

- **Defter, yapı sayfası:** şantiye listesi, iş saati, ekip, yığın eksiği, gece emri, öncelik, «Sök».

## 7. Hasar, geri düşüş ve onarım

Geri düşüş fiziktir, emek istemez (`structures.md` §5.7 aynen). Kaldırmak ve yamamak emektir; formüller `structures.md` §7'nin saniyesini İD'ye çevirir.

| Soru | Kural |
|---|---|
| Birimin emeği | `adım.work × (birim canı / adım canı)` |
| Yeniden kaldırma / Re-raise | Birim emeği × 0,8; kurulum gösterimiyle; adımın el sınırı ve tek el çarpanı geçerli |
| Yama / Patch | Birim emeği × (1 − can/en çok) × 0,6 |
| Yanık birim | ×1,25 |
| Yeniden koşan birimsiz adım | `y_sirdak`, `y_ocak` gibi adımlar (aşama 6 altına düşünce sıfırlanan, `keep: 6`) yeniden koşarken ×0,8 |
| `repair` becerisi | Mete ekipteyken onarım emeği ×0,5, malzeme ¼ (yukarı yuvarlanır) |
| Sıra ve öncelik | `structures.md` §7 aynen: yangın > düşmüş birim > can <%50; alttan üste |
| Tündük | İki el; tek başına bakanla ×1,6 (eski «3 kişi şartı» kalkar) |
| Yedek onarım (A, B, ahır, çit) | Ana kampın iki adsız eli (W 2, oran 1,9 İD/dk) vuruştan 30 gerçek sn sonra gelir |
| Çocuk | Yalnız yırtık diker: yırtık başına 4 İD, yarım elle 8 oyun dk ≈ 20 gerçek sn, `E` basılı, bırakınca ilerleme kalır; önder kuralı dışında. Can onarımına «Ustalara Katıl» ile yarım el katılır |

**Örnekler.**

| Olay | Emek | camp3 ekibiyle (W 2,75) |
|---|---|---|
| Ateşli ok, yurt 7→5: kolan, eşik, tuurduk, üzük yanık kaldırma; şırdak ve ocak yeniden | 457 İD | 3 sa 02 dk oyun; 7,6 gerçek dk |
| Bosağa %50 can, yama | 22,5 İD | 9 dk oyun; 22 gerçek sn |
| Kerege kanadı düştü (7,5 can), kaldırma | 136 × 7,5/45 × 0,8 = 18,1 İD | 7,2 dk oyun |
| Yurt aşama 0'a indi, yalnız işçi yeniden kurar | 1.092 İD | Yalnız 45,5 gerçek dk |
| Kışlak Gün V: yanık keçeyi iki el kaldırır | 256 İD | İki elle 134,7 dk oyun (07:00–09:15, §10.3) |
| Araba tekeri (`c_wheels` 8/24 can), kaldırma | 110 × 8/24 × 0,8 = 29,3 İD | Mete ve sürücü (2 el) 15,4 dk oyun ≈ 39 gerçek sn; `repair` ile ≈ 19 sn |

Son satır `travel.md` §3.6'nın «sıradan onarım 25 sn»ini ≈39 sn yapar (§16).

## 8. Öteki yapılar

Tek el emeği yurda göre iş günüdür (İG). Gerçek dakikalar usta varken, gündüz, açık havadır.

### 8.1 Faz 6 türleri

| `kind` | Zanaat | İG | Tek el İD | 1 el | 2 el | 4 el | 8 el | Gerekçe |
|---|---|---|---|---|---|---|---|---|
| `yurt` | home | 1 | 1.440 | 60,0 | 28,5 | 16,3 | 11,6 | K21 çapası |
| `stable` | wood | 1,5 | 2.160 | 90,0 | 44,4 | 24,5 | 20,0 | Direk çukuru, tahta duvar ve çatı yerinde biçilir; yurt hazır parçayla kurulur |
| `cart` | wood | 0,3 | 432 | 18,0 | 7,9 | 5,1 | 5,1 | Tekerlek ve dingil zanaattır (K24); şantiyede yalnız birleştirme |
| `tent` | home | 0,15 | 216 | 9,0 | 4,1 | 2,3 | 2,3 | İki direk, bir örtü |
| `hut` | home | 0,5 | 720 | 30,0 | 14,8 | 8,2 | 8,2 | Saz duvar ve dam |
| `shed` | wood | 0,6 | 864 | 36,0 | 17,5 | 9,7 | 9,7 | Açık sundurma |
| `granary` | wood | 0,8 | 1.152 | 48,0 | 23,3 | 12,9 | 10,0 | Sundurmanın sıkı, yüksek tabanlı biçimi |
| `tower` | wood | 1,5 | 2.160 | 90,0 | 39,6 | 21,9 | 20,9 | Yükseklik, çapraz ve platform iki ellik |
| `tower_gate` | wood | 1,5 | 2.160 | | | | | Senaryo yapısı, oyuncu kurmaz; onarım formülü için |
| `bridge` | wood | 2 | 2.880 | 120,0 | 53,5 | 29,6 | 20,9 | Kazık ve kiriş suda iki ellik |
| `fence`, 10 m | home | 0,075 | 108 (kazık 7,2, kuşak 3,6 İD/m) | 4,5 | 2,4 | 1,3 | 1,1 | Faz 6'nın 9 sn/m'si ölçeklendi; el sınırı 2 m'lik parça sayısı (10 m'de 5) |
| `pen`, Adak Ağılı 148 m | home | 1,1 | 1.592 (hat 1,5 İD/m, pano 20 İD, kapı 40 İD iki elle, tek el ×1,25) | 66,3 | 34,7 | 19,6 | 12,2 | 66 pano; kapı iki kişilik |
| `rack` | home | 0,002 | 3,2 | 8 sn | | | | `rc_rack` 8 sn basılı tutma aynen |
| `road_bone` | home | 0,006 | 8 | 20 sn | | | | `rp_road_bone` 20 sn aynen |

**Şantiye el tavanı (`crewMax`)**, adımların en geniş sınırı: yurt 8, ahır 6, araba 4, çadır 4, kulübe 4, sundurma 4, ambar 6, kule 6, köprü 8, çit 10 m'de 5, ağıl 40 m'de 8, raf ve direk 1. `econ-model.json` `structures.*.crewMax` bu sütunu kopyalar.

**Basılı tutma kuralı.** Emeği ≤12 İD olan yerleştirilebilir (raf, direk onarımı, kamp ateşi) şantiye açmaz: oyuncunun basılı tutması emeğin kendisidir (1 gerçek sn = 0,4 İD). Yasa tutarlı kalır, oynanış değişmez.

**Adım ayrıntısı** (`labour-model.json` `defs`): ahır `st_site` 140, `st_posts` 340, `st_walls` 510, `st_beams` 270 (2 el, ×1,5), `st_roof` 765; araba `c_axle` 110 (2 el, ×1,5), `c_bed` 120, `c_hoops` 40, `c_tilt` 60 (2 el, ×1,25), `c_yoke` 32; çadır 36, 60 (×1,2), 90 (×1,2); kulübe 60, 176 (×1,25), 240, 200; sundurma 60, 180, 132 (×1,5), 200, 226; ambar 80, 240, 176 (×1,5), 266, 302; kule 300, 440 (×1,5), 528 (×1,25), 540; köprü 360, 480 (×1,5), 400 (×1,5), 480, 300, 420. Çit ve ağıl el sınırı parça sayısıdır (2 m'ye ya da panoya bir el, en çok 8).

**I. Perde etkisi.** `sq_old_bridge` 2→5 (deste, bağ, korkuluk) 1.200 İD'dir: Sazlık'ın 6 eli malzeme gelince ≈4,5 oyun saatinde (≈11 gerçek dk) kurar; görev malzemesi değişmez.

### 8.2 K23 yerleşim yapıları (taslak, yerleşim alanıyla)

Ad, kademe, görünüm ve hangi kademede açıldığı yerleşim alanınındır; emek, el sınırı ve zanaat bu belgenin. Dörtlük ekip usta varken.

| `kind` (öneri) | TR / EN (öneri) | Zanaat | İG | El en çok | 4 elle dk | Aşama payları, iki ellik aşama |
|---|---|---|---|---|---|---|
| `otag` | Otağ / Great Yurt | home | 2,5 | 12 | 43,6 (12 elle ≈22) | Yurdun 8 aşaması, 10–12 kanat; kerege ×1,25, tündük ×1,6, keçe ×1,25 |
| `store_yurt` | Ambar Yurdu / Store Yurt | home | 1 | 8 | 16,3 | Yurt |
| `felt_yard` | Keçe Avlusu / Felt Yard | home | 0,5 | 6 | 8,7 | Zemin, tezgâh, germe çerçevesi, yuvarlama yolu |
| `wood_shop` | Ağaç Atölyesi / Woodshop | wood | 0,8 | 6 | 12,9 | Ambar gibi |
| `smithy` | Demirci Ocağı / Smithy | earth | 1,5 | 6 | 26,2 | Ocak, körük, sundurma |
| `kiln` | Fırın / Kiln | earth | 0,6 | 4 | 10,5 | |
| `tannery` | Sepi Yeri / Tannery | home | 0,4 | 4 | 7,0 | |
| `grain_pit` | Ambar Çukuru / Grain Pit | earth | 0,3 | 4 | 5,2 | |
| `well` | Kuyu / Well | earth | 1 | 3 | 22,1 | Kazı tek ağızdan, 3 el |
| `field` | Darı Tarlası / Millet Field | earth | 0,5 / tarla | 6 | 8,7 | |
| `pit_house` | Yarı Gömük Ev / Pit House | earth | 2 | 6 | 34,9 | Çatı kirişi ×1,5 |
| `rampart` | Sur ve Hendek / Rampart and Ditch | earth | 0,5 / 10 m | 8 | 8,7 / 10 m | |
| `granary_tower` | Tahıl Kulesi / Grain Tower | wood | 2 | 6 | 34,9 | Direk ×1,5, döşeme ×1,25 |

**Tarih dayanağı.** Shiji 110 Hun evini keçe çadır (穹廬) diye anar; yurt ve otağ hane bilgisidir, usta istemez. Hanshu 94A, Wei Lü'nün Tanhu'ya kuyu kazmayı, sur kurmayı ve tahılı kulede saklamayı öğütlediğini yazar (穿井築城，治樓以藏穀); geç Hun yerleşimleri (Ivolga) sur, hendek, yarı gömük ev, demir ocağı ve darı tarlası gösterir. Bu yüzden toprak ve kule işleri ayrı zanaat ister ve en çok emeği onlar yer: yerleşim büyüdükçe emek ve usta ihtiyacı birlikte büyür.

### 8.3 Ordugâh yapıları (taslak)

| `kind` | TR / EN (öneri) | Zanaat | İG | El en çok | Not |
|---|---|---|---|---|---|
| `tent` | Onluk Çadırı / Ten's Tent | home | 0,15 | 4 | Onluk 2 çadır; 5'er el: 2,3 gerçek dk |
| `cmd_yurt` | Buyruk Yurdu / Command Yurt | home | 1 | 8 | Yurt |
| `horse_line` | At Hattı / Horse Line | home | 0,04 / 10 at | 4 | Direk ve ip |
| `armoury` | Silahlık / Armoury | home | 1,2 | 8 | Yurt ve raflar (0,2) |
| `fletchery` | Okçu Yurdu / Fletcher's Yurt | home | 1,2 | 8 | Yurt ve tezgâh (0,2) |
| `training_ground` | Talim Alanı / Training Ground | home | 0,6 | 8 | Açma, hedef direkleri, at yolu |
| `supply_depot` | Erzak Ambarı / Supply Depot | home | 1,5 | 8 | Ambar yurdu ve yük sekisi |
| `palisade` | Çit Halkası / Palisade | wood | 0,1 / 10 m | 8 | |
| `watch_tower` | Gözcü Kulesi / Watchtower | wood | 1,5 | 4 | Kule |

**Ordugâh kurulumu (`cmd_camp`).** Her onluk kendi çadırlarını kurar: birlik büyüdükçe çadırlar paralel kalkar, tümenin konağı da onluğunki kadar sürer (≈2–3 gerçek dk). `CampPlan` çadır başına kayıt tutmaz: `count`, `seed`, `doneAt` (§14). İnşaatta çalışan er o saatte talim kazanmaz (`army.md` `drill`): ordunun emek bedeli fırsattır.

## 9. Üçüncü yurt (`camp3`) saatle

### 9.1 Ekip ve süre

Oktar (usta, 1), Erka (usta, 1), Dengiz (çırak, 0,75) **baştan sona** çalışır; Dengiz'in yalnız tündükte gelme kuralı kalkar. Çocuk katılınca yarım el (§9.3). Saat yüzü zaman taslağınındır (`d2/time.md` §8.3): Serbest Gez menü dakikasında (14:46) açılır, ustalar ilk girişten 20 gerçek sn (8 oyun dk) sonra kuzey yamaçtan iner (ilk geliş yalnız 06:00–22:00 arasında, değilse ertesi 06:00'da); 12:00 ve 18:30'da sırayla 30'ar dakika ateş başında yerler; batıştan (18:38) sonra iki meşale direği yanar (bedava). K21 gereği ekip 22:00'de bırakmaz, yurt bitene dek meşalede sürer (§9.5). Emek yalnız Serbest Gez saati işlerken işler: menüde, haritada, duraklatmada durur; uyku ve Bekle'de toplu işler.

**Adım emekleri** (öğünsüz, yığın tam; W 2,75):

| Adım | Oyun dk | Gerçek sn | Çocuk katılırsa oyun dk |
|---|---|---|---|
| `y_site` | 29,8 | 75 | 25,9 |
| `y_bosaga` | 29,8 | 75 | 25,9 |
| `y_kerege` | 54,1 | 135 | 46,9 |
| `y_bag` | 17,9 | 45 | 15,5 |
| `y_tunduk` | 39,8 | 99 | 34,5 |
| `y_uuk` | 107,3 | 268 | 93,1 |
| `y_liner` | 41,7 | 104 | 36,2 |
| `y_tuurduk` | 47,7 | 119 | 41,4 |
| `y_uzuk` | 54,1 | 135 | 46,9 |
| `y_kolan` | 41,7 | 104 | 36,2 |
| `y_esik` | 10,5 | 26 | 10,5 |
| `y_sirdak` | 29,8 | 75 | 25,9 |
| `y_ocak` | 20,0 | 50 | 20,0 (köz önceden gelirse 6,0) |
| **Toplam** | **524,3** | **1.311 sn = 21,8 dk** | **458,9 = 19,1 dk** |

**Yığın eksiği.** camp3 yığını uuk için 4 kütük eksik başlar (§9.3 `help_log`): Çocuk getirmezse uuk başında Dengiz dört sefer (106 gerçek sn) ekipten çıkar, uuk 10,3 oyun dk uzar.

**İlk gün** (0,1 oyun dakikası adımlı benzetim: 14:54 başlangıç, 18:30 öğün sırası, gece meşalede; §19). Yardımsız adımların bittiği saatler: zemin 15:23, bosağa 15:53, kerege 16:47, bağ 17:05, **tündük 17:45** (batıştan önce, altın ışıkta), uuk 20:10, çiy 20:52, tuurduk 21:40, üzük 22:34, kolan 23:15, eşik 23:26, şırdak 23:56, **ilk duman 00:16**.

| Durum | İlk duman | Geçen oyun saati | Gerçek |
|---|---|---|---|
| Yardımsız | 00:16 | 9 sa 22 dk | 23,4 dk (1.405 sn) |
| Yalnız ayak işi: 4 kütük ve köz | 23:52 | 8 sa 58 dk | 22,4 dk |
| Yalnız katılma (kütüğe Dengiz gider) | 23:04 | 8 sa 10 dk | 20,4 dk |
| Katılma ve ayak işi | 22:46 | 7 sa 52 dk | 19,7 dk (1.181 sn) |
| Yardımsız, zaman taslağının 22:00 durağıyla (§9.5) | Ertesi 08:16 | 17 sa 22 dk | 43,4 dk |

Uyuyan oyuncu sabah kalkmış yurdu bulur; uyanık kalan ilk dumanı gece yarısı meşale ışığında görür.

**Hava.** Ana kampın iklimi hava taslağınındır (`d2/weather.md`: kampta saatin ≈11 oyun dakikası ıslak, fırtına ≈0,64/gün); §5.2 durakları yurdu ortalama ≈%8 uzatır. Menü ve Yeni Oyun karesi hep açıktır (K22).

**`?q=low`.** Usta sayısı oynanışı değiştirmez: Dengiz kukla ağıyla (≤1,2k üçgen) çizilir, ekipte sayılır. Eski «usta en çok 2» kesintisi kalkar (§13).

### 9.2 Dengiz'in işleri

`builders.js` `JOBS`'a her adım için `dengiz` sütunu eklenir: zeminde Erka'yla çiğner; bosağada dikmeleri taşır, tutar; kerege ve uukta yığından bir sonraki paketi getirir (yığın kapıdan 3,5 m); bağ ve kolanda dış halkada bağlar; tündükte bakan (bugünkü satır); çiyde saz rulosu; tuurdukta alt kenarı tutar; üzükte Oktar'la halat çeker; eşikte yığını toplar; şırdakta sandık taşır; ocakta kapıda bekler. Uzun pencerelerde hareket döngüsü sürer (`loop`); kare ve ses bütçesi §13.

### 9.3 Çocuğun yardımı: sekiz yardım türü işçi katkısı olarak

**Ana kural.** Çocuk şantiyenin bir işini yaptığı sürece ekipte yarım el (0,5) ve bir baş sayılır. Kredi, 3 kat erime, adım başına sınırlar ve «En çok», «Toplam» sütunları kalkar.

**Katılma.** Stokta ya da bir ustanın 4 m yakınında `E`: «Ustalara Katıl (yarım el)» / «Join the Builders (half a hand)». Çocuk dördüncü işçi olur: `BuilderSystem` onu ustaların durum makinesiyle sürer (`CHILD_JOBS` satırları), kamera izler. Hareket girdisi çıkarır. Oktar: «Gel. Yarım el de eldir.» / «Come. Half a hand is still a hand.»

| Eski id | Adım | Çocuğun işi (katılınca) | Katkısı |
|---|---|---|---|
| `help_tamp` | `y_site` | Dairenin içinde toprağı çiğner (`tamp` rotası) | Yarım el |
| `help_carry` | `y_bosaga`, `y_uuk`, `y_liner`, `y_sirdak` | Yığından yuvaya taşır: 1 dikme, 2 sırık, 1 saz, 1 rulo | Yarım el |
| `help_hold` | `y_kerege`, `y_tuurduk` | Kanadı, panelin alt kenarını tutar | Yarım el; iki el şartını tek başına karşılar |
| `help_tie` | `y_bag`, `y_kolan` | Dış halkada düğüm tutar | Yarım el |
| `help_heave` | `y_tunduk` | Bakana omuz verir; üç çağrıda `E` (0,6 sn pencere): tam hamlede yalpa yok, geçte yalpa ve gülüşme | Yarım el; çağrı yalnız görünüm ve söz |
| `help_pull` | `y_uzuk` | Halatı geri yürüyerek çeker | Yarım el |

**Ayak işleri** (katılmadan: Çocuk o sırada taşıyıcıdır, ekipte sayılmaz; kazancı ustanın yolu ve adımın getirme payıdır):

| Eski id | TR / EN | Ne değişir |
|---|---|---|
| `help_log` | «Kütük Getir» / «Bring a Log» | camp3 yığını uuk için **4 kütük eksik** başlar (`node_camp_logs` (6.12,−5.75), 19,7 m). Çocuk getirmezse uuk başında Dengiz dört kez gider: her sefer 26 gerçek sn ekipten çıkar (ekip 6,5 İD kaybeder). Dengiz: «Kütük eksik. Ben getiririm.» / «We're short of logs. I'll fetch them.» |
| `help_ember` | «Köz Getir» / «Bring an Ember» | `y_ocak`'ın 20 İD'sinin 14'ü közü ateşten (27 m) getirmektir. Köz önceden yığına gelirse adım 6 İD'ye iner: 35 gerçek sn kazanç, Erka çocuğa döner (bugünkü sahne) |
| `help_water` | «Su Getir» / «Bring Water» | Kova (−3.65, 0.2) yığına: bütün ekip 1 oyun saati (2,5 gerçek dk) ×1,1; yapı başına en çok 4, arada 1 oyun saati. Dengiz: «Su mu? Sen olmasan kovaya ben koşacaktım.» / «Water? Without you I'd be running to the bucket.» |

`y_esik` iki kişiliktir: Çocuğa iş yoktur, ipucu «Kapı keçesi iki kişilik iş» / «The door felt is a two-person job». `y_ocak` tek kişiliktir: katkı yalnız köz.

**Sonuç.** Yardımsız yurt öğünlerle 23,4 dk sürer. Çocuk her adımda katılırsa 20,4 dk, kütüğü ve közü de getirirse 19,7 dk (%16 kısa). Katkı dürüst ve görünürdür: HUD «Ekip: 3 el + sen · ≈2 saat», kalan süre kısalır.

### 9.4 Ustaların yeni sözleri

Altyazı, seslendirme yok, `structures.md` §10.6 kuralıyla (adım başına ≤1, 6 m).

- Alacakaranlık, Erka: «Meşaleleri dikin. Gece işi bitirmez, ışık olsun yeter.» / «Plant the torches. Night won't stop the work, so long as there is light.»
- Gece, Oktar: «Karanlıkta düğüm parmakla görülür.» / «In the dark you see a knot with your fingers.»
- Yağmur, Oktar: «Keçeyi yağmura açmayız. Bekleyelim.» / «We don't open felt to the rain. We wait.»
- Çocuk katılınca, Oktar: «Gel. Yarım el de eldir.» / «Come. Half a hand is still a hand.»
- Kütük, Dengiz: «Kütük eksik. Ben getiririm.» / «We're short of logs. I'll fetch them.»
- Su, Dengiz: «Su mu? Sen olmasan kovaya ben koşacaktım.» / «Water? Without you I'd be running to the bucket.»

### 9.5 Zaman taslağıyla uzlaşma

Zaman taslağı (`d2/time.md` §8.3, §10.1 ve `d2/time-delta-structures.md` S2) ustalara 06:00–22:00 iş penceresi verir: 22:00'de kuzeye çıkarlar. K21 ise inşaatı kesintisiz sayar («meşale ve ateş ışığında»); ekonomi taslağı da ışıklı şantiyeyi gece ×1 sayar (`econ-model.json` `_noteLabour`). Öneri:

- **İnşaat ekipleri kesintisizdir** (camp3, yerleşim ve ordugâh şantiyeleri): 22:00'de bırakmaz, meşalede sürer, yapı bitince çıkar. Varsayılan gece emri «Gece de çalışılsın».
- **Zaman taslağının penceresi** iki yerde geçerlidir: üretim ve ev işleri (sürü, sağım, keçe, aş) ve şantiyeye «Gece dinlenilsin» emri verildiğinde. Bu emirle camp3 ertesi sabah 08:16'da biter.
- **Senaryo ekipleri** (Kışlak Yeni Yurdu) hikâye programına uyar: iki el 07:00–23:00, Nanay 10:30–19:30 (`d2/time.md` §9.4, §10.1); I. Perde gecesi gizliliğindir.
- Zaman taslağından aynen alınanlar: 14:46 açılış, 20 sn sonra gelme, ilk gelişin 06:00–22:00 kuralı, 12:00 ve 18:30 öğün sırası, batıştan sonra meşale, `clock:skip`, Bekle tekeri, HUD'da «≈N saat».
- İki ayrım zaman taslağına önerilir (§16): §8.3 «Oktar ve Erka (tündükte Dengiz)» → «Oktar, Erka ve Dengiz»; «22:00 iş biter, kuzeye çıkarlar» → «yurt bitene dek meşalede sürer; `Gece dinlenilsin` emriyle 22:00'de çıkarlar».

## 10. Kışlak Yeni Yurdu (`act1.md` §9.3) saatle

### 10.1 Ekip, saat ve kapılar

`İş Puanı` dilimi K20 ile saate döner (zaman alanı). Yeni Yurt artık dilim kipinde değil, emek kipinde (`mode: 'timed'`, `SiteSystem` sürer) ilerler: emek yasası ekiple, adım malzemeyle, büyük anlar hikâyeyle kapılıdır.

| Kim | Rol | Pedde (oyun saati) | Dayanak |
|---|---|---|---|
| Nanay | Usta (home, felt) | 10:30–19:30 | `d2/time.md` §9.4: 10:30–14:30 Yeni Yurt pedi, 14:30–19:30 pedde dikiş; batıştan (16:49) sonra kendi fenerinde |
| İki el (adsız Yüeçi `Folk`, «Yapı Eri» / «Builder») | El | 07:00–23:00 | `act1.md` §8.1 «iki işçi»; Kışlak iş penceresi `d2/time.md` §10.1; 23:00'den sonra Kışlak gecesi gizliliğindir |
| Mete | El (rehine) | İsterse | §10.4 |

Saatler zaman taslağınındır (Gün I doğuş 07:11, batış 16:49; vakitler `d2/time.md` §9.2); kapılar olaya bağlıdır, saat kayarsa tablo da kayar.

**Kapılar.**
- Aşama 0: `mq_first_tally` (oyuncunun 6 taşı ve ped seçimi) yığına girince ekip o öğleden sonra kurar.
- Aşama 3: `y_tunduk` `mq_crown`'u bekler («Tündük kaldırılmayı bekliyor»). Sahne Gün III 08:30'da (08:30–10:30 vakti); 7 kişi (Nanay, Farnak, Sak, Ardokşa, iki el, Mete), el sınırı 6: 100 İD 21 oyun dk; üç hamlenin kapısı (`beginHeave`) aynen.
- `y_ocak` `mq_feast`'teki közü bekler (Atşo; Toy 17:00, `b_feast` vakti 16:30–17:30): yakma 6 İD, ilk duman sahnenin içindedir.
- Emniyet: `mq_feast` başında eksik varsa `ensureStage(7)` (eski «Gün IV akşamı en geç 7»).

**Ambarın gönderimi.** Oyuncu getirmezse Ardokşa'nın taşıyıcıları her aşamanın malzemesini aşağıdaki saatte pede bırakır. Oyuncu bir aşamanın malzemesini önceden getirdiyse o gönderim düşer ve ekip ilk saatinde kurar.

| Aşama | Ambar gönderimi | Yalnız NPC ile bittiği an | Oyuncu her aşamayı önceden getirirse |
|---|---|---|---|
| 0 | Oyuncu (`mq_first_tally`, ≈14:00) | Gün I 14:28 | Gün I 14:28 |
| 1 | Gün II 09:00 | Gün II 09:40 | Gün I 16:28 |
| 2 | Gün II 13:00 | Gün II 14:08 | Gün II 10:06 |
| 3 | `mq_crown`, 08:30 | Gün III 08:52 | Gün III 08:52 |
| 4 | Gün III 13:00 | Gün III 14:40 | Gün III 11:28 |
| 5 | Gün III 15:30 | Gün III 16:09 | Gün III 12:07 |
| 6 | Gün IV 09:00 | Gün IV 11:02 | Gün III 18:36 (meşalede) |
| 7 (kolan, eşik, şırdak) | Gün IV 13:00 | Gün IV 14:18 | Gün IV 10:42 |
| 7 (ocak) | `mq_feast` közü | Gün IV 17:06 | Gün IV 17:06 |

Sütunlar dakika adımlı benzetimdir (§19). Bütün emek ekibe ≈8 iş saati yeter: darboğaz malzeme ve hikâyedir, bu bilinçlidir. Oyuncunun getirdiği malzeme günün içinde yurdu öne alır ve %50 katkı kuralını doldurur; perdenin büyük anları yerinde kalır.

### 10.2 Katkı ve Güven

- **Malzemenin %50'si sendense Toy'da Güven +10** aynen (54 birimden 27, `job_stone` dahil).
- `contrib` yeni alanı `wm: { player, npc }`: Mete'nin pede verdiği emek. Son kart ve Destan dizesi isterse okur.

### 10.3 Baskın ve onarım

`mq_envoy` `new_yurt` gösterildiyse ateşli ok 7→5 (`structures.md` §6.1 kalibrasyonu aynen). Gün V sabahı iki el yanık keçeyi kaldırır (Nanay 10:30'a dek Keçe Avlusu'ndadır): 256 İD, iki elle 07:00–09:15. `ensureStage(6)` emniyet olarak kalır; oda açılır, çatı yırtığı sahnedeki gibi durur.

### 10.4 Mete pedde çalışırsa

Pedde `E` «Çalış» / «Work»: ekibe 1 ağırlıkla girer, çalışma atlaması (§6.7) kullanılabilir. Nanay ilk katılışta: «Elin boş durmasın, Hun. Kerege seni de tanısın.» / «Don't let your hands sit idle, Hun. Let the lattice know you too.» Sabahları 3 saat (08:00–11:00) çalışan Mete (Gün II ve IV, oyuncunun malzemesi önceden gelmişse) kerege, bağ, kolan ve şırdağı 17–28 oyun dakikası öne alır (benzetim, §19).

**Öneri (act1 ve ekonomi sahibine):** `job_raise` «Yurt İşi / Yurt Work»: pedde 2 oyun saati çalışmak İş Tahtası'nda 1 iş sayılır, günde en çok 1. Bedeli gerçektir: saat ilerler, günün öteki işleri kaçar. Kabul edilmezse çalışma yalnız yurdu öne alır.

## 11. Uygulama taslağı

### 11.1 `game/labour.js` (yeni, saf)

```js
// game/labour.js (saf): emek yasası, ekip verimi, çarpanlar, taşıma ve toplu benzetim (d2/labour.md). three ve DOM yok.
export const LABOUR = Object.freeze({
  DAY: 1440, REAL_S_PER_MIN: 2.5, B: 0.9, SITE_MAX: 8, NO_USTA: 0.7, LEAD_W: 0.75,
  ROLE_W: { usta: 1, hand: 1, apprentice: 0.75, elder: 0.5, child: 0.5 }, MASTER_W_MAX: 1.25,
  NIGHT: { lit: 1, moon: 0.7, dark: 0.4, dayLevel: 0.6, moonLevel: 0.25, fireLightPad: 4, torchDarkHours: 4 },   // lightLevel eşikleri (time.md §12.3)
  REPAIR: { raise: 0.8, patch: 0.6, burnt: 1.25, rerun: 0.8, tearStitch: 4 },
  DISMANTLE: 0.35, WATER: { k: 1.1, minutes: 60, max: 4 },
  HAUL: { vLoaded: 1.4, vEmpty: 1.9, handleS: 8, cap: { adult: 20, apprentice: 14, child: 6 }, selfR: 150 },
  QUICK_RAISE: 1 / 0.7,
});
export function eff(W);                                   // min(W, 10·(1 − 0,9^W))
export function crewOn(step, members, out);               // members ağırlığa göre sıralı; → out { heads, W, lead, usta, mete }
export function stepRate(step, crew, env);                // → İD / oyun dk; env { night, weather, fed, water, speed, craft }
export function weatherK(step, weatherId);                // → { k, hold, reason } (§5.2; kimlikler d2/weather.md §3.1)
export function nightK({ dark, lit, level, moonSeen });   // level: daylight.lightLevel, moonSeen: weather fx → 1 | 0,7 | 0,4
export function remaining(state);                         // → [{ step, work }]: kalan adım emekleri (yeniden koşan ×0,8)
export function etaMinutes(state, members, envAt);        // → oyun dk; adım adım, el sınırlarıyla
export function simulate(state, minutes, { membersAt, envAt, stockAt });   // saat dilimli; → işlenen İD, olaylar
export function haulTrip(d, carrier);  export function haulWork(load, d, carrier);   // gerçek sn, İD
export function realToMinutes(s);  export function minutesToReal(m);
export function etaWords(nowMin, etaMin);                 // → { dayKey, timeKey } (§6.11 tablosu)
```

Saf modül listesine girer (`tools/check-pure.mjs`). Bütün sayılar `labour-model.json` ile aynı; sınama ikisini karşılaştırır.

### 11.2 `world/structure-defs.js` ve `world/structure-logic.js`

- Adım alanları: `dur` → `work` (İD, iki elle), `crew` → `min`, `max` (baş), yeni `solo`, `tall`, `felt`; tanımda `craft`, `crewMax`. Çit ve ağılda `per: 'm' | 'unit'` emeği çarpar; el sınırı parça sayısı. `y_ocak` `fetch: { item: 'ember', work: 14 }`: köz yığında ise adım 6 İD.
- `StructureState`: `advance(wm)` adımın `work`'ünü tüketir (yeniden koşan birimsiz adım ×0,8); `t` → `wm` (işlenen İD); `rate` sürücünün yazdığı İD / oyun dk; `credit(wm)` yalnız senaryo armağanı, çarpansız (`CREDIT_RATE` kalkar); `repairStep(wm, who)`; `_raiseWork`, `_patchWork` §7 ile; `sliceTick` kalkar; kip `'timed'` (emek: `BuilderSystem` ya da `SiteSystem` sürer) ya da `'script'` (yalnız `setStage`, `ensureStage`). `dismantle()` tersten çizelge (§6.9).
- `toJSON` / `fromJSON` sürüm 2 (§14).

### 11.3 `world/structure.js`

- `_work(dt)` yedek onarımı: `dOyunDk = dt × 0,4 × hız`, oran ana kampın iki eli (`stepRate` W 2). Sürülen yapıda (`manager.driven`) iş yapılmaz (karar 34 aynen).
- `G_TORCH` (46): camp3 `frame` ağına iki meşale direği (≈120 üçgen, yeni çizim yok); alev ve parıltı `fxFlames`, `fxGlow` havuzlarından (§13). Menü kipinde gizli.

### 11.4 `game/builders.js` (camp3)

- `workRate` silinir; oran `labour.stepRate(step, crewOn(step, members), env)`; `members` Oktar, Erka, Dengiz ve katılmışsa Çocuk.
- `advance(dt)`: `st.advance(dt × 0,4 × oran)`; `workDone` `work` toplar.
- `tickJob`, `dueOf`: `dur` yerine `stepSpanS()` = kalan İD / oran × 2,5 (gerçek sn); oran değişince kayar.
- `HELP` tablosu → `CHILD_HELP` (§9.3: katılma satırları, ayak işleri, su çarpanı); `HelpDesk.credit` kalkar; `childCrew` → `child.joined`.
- `JOBS`: `dengiz` sütunu (§9.2), uzun pencerede `loop: true`; Dengiz baştan gelir (`DENGIZ_CALL_K` kalkar).
- Gece: batıştan sonra direkler yanar (`G_TORCH` ve alevler), Erka'nın sözü; uzun işin hava durağında ekip bakandan 6 m çekilir, fırtınada `SHELTER`.
- Saat programı (`d2/time.md` §8.3): ilk geliş yalnız 06:00–22:00 arasında, 12:00 ve 18:30 öğün sırası (her usta 30 dk, sırayla), 22:00'de kalış (K21; `Gece dinlenilsin` emriyle çıkış). Hava durağında yeni `SHELTER` durumu (`d2/weather.md` §8.11): en yakın yurt ya da ahır çatısı.
- `status`: `heads`, `W`, `etaMin`, `wait`, `solo`; HUD satırı bunları okur.

### 11.5 `game/sites.js` (yeni) ve `game/site-core.js` (saf)

```js
// game/site-core.js (saf): yerleşim denetimi, yığın, tüketim, bekleme nedeni, kayıt biçimi
export function validatePlacement(def, place, { nav, height, normalAt, nodes, structures, roads });   // → { ok, reason }
export class SiteCore { constructor(def, place, opts); stock; crew; orders; wait; contrib; lastMin;
  deliver(item, n, who);  needFor(step);  consume(step);  waitReason(env);  toJSON();  fromJSON(o); }

// game/sites.js: GameSystem, id 'sites', order 61, modlar freeroam, play, home
export class SiteSystem {
  attach(ctx);  onWorld(world, nav);
  beginPlacement(kind, { preset });  place(kind, opts);   // → ConstructionSite (SiteCore + StagedStructure)
  get(id);  list();  assign(siteId, workerIds);  release(workerId);  order(siteId, { night, priority, dismantle });
  deliver(siteId, item, n, who);
  update(dt, t);                 // görünen ve uzak şantiyelerde emek; ekip görünümü ≤8 Folk / şantiye
  onSkip(fromMin, toMin);        // clock:skip (uyku, Bekle, çalışma, yolculuk) → labour.simulate
  catchUp(minutes);              // dünyaya dönüş
  collectInteractions(q, out);   // Teslim Et / Deliver, Çalış / Work, Ekip / Crew, Sök / Dismantle
  toJSON();  fromJSON(o);        // world.sites bloğu (order 76)
}
```

Görünür işçi: `BuilderSystem`'in durum makinesi genelleşir (`CrewView`): yurt `JOBS` tablosunu, öteki türler genel işi kullanır (yığından birimin yanına taşı, malzemeye göre hareket: ağaç `hammer`, ip `tie`, keçe `reach_up`, saz `reach_up`, taş `lay`, toprak `pick` ve `stomp`; jestler Faz 8'in `labour.js` jestleridir).

### 11.6 WorldSpec

```js
// world/specs/*.js
sites: [ { id, kind, preset, x, z, rot, y0, mode: 'timed', crew: ['nanay', 'yz_hand1', 'yz_hand2'],
           schedule: 'kislak_new_yurt', stock: {}, orders: { night: 'rest' }, gates: { y_tunduk: 'crown_raised', y_ocak: 'feast_ember' } } ],
labour: { torchFree: true, fireLight: true, deliveries: 'kislak_new_yurt' },   // ana kamp: { torchFree: true }
```

camp3 bugünkü gibi `World.buildStructures` ve `SITE_YURT` ile doğar (menü karesi için `LAYOUT` dışı); emek yasasını `BuilderSystem` uygular.

### 11.7 Envanter, düğüm, defter, ordu

- **Envanter (§3.13):** `inventory.site(id)` kabı ve `deliverTo(siteId, ref, n)`; yığın Yük'ü onda bir tamsayı (`w10`).
- **Düğüm (§3.12):** `validatePlacement` `store.query` ile izdeki düğümleri okur; `y_site` küçük düğümleri `consume` eder (`perm`).
- **`SupplyLedger`:** yerleşim defterinin `food` çizgisi `K_tok`'u verir; `fuel` çizgisine meşale yazılmaz (meşale eşyadır, yerleşim alanı isterse çizgiye çevirir).
- **Ordu (`army.md` §3):** el sayısı `UnitRec.strength − wounded`; `cmd_detail` bir onluğu şantiyeye verir (8'i yurtta, 2'si taşımada); `CampPlan` çadırlarını toplu kurar; şantiyedeki er `drill` almaz, `fatigue` dinlenmez.

### 11.8 Gizli panel

`__tanhu.labour`: `eff(W)`, `rate(siteId)`, `eta(siteId)`, `crew(siteId)`, `simulate(siteId, min)`, `weather(id)` (yerel deneme), `night(on)`, `sandbox()` (`?state=play&sandbox=site`: düz zemin, her tür, ekip ve hava düğmeleri). `__tanhu.struct.speed` kalır.

## 12. Faz 6 kodunda yeniden çalışma listesi

Kod bu fazda değiştirilmez; aşağıdaki liste sonraki fazın paketidir (`d2/labour-delta-architecture.md` A9 önerisi: Faz 8 paketi 8.L1, numara birleşmede verilir; zaman taslağının saat paketine sözleşmeyle bağlanır).

| Dosya | Satır, alan | Değişiklik |
|---|---|---|
| `src/world/structure-defs.js` | 40–44 `REPAIR`, `CREDIT_RATE` | `CREDIT_RATE` silinir; `REPAIR.childPatch` (4 sn) → `tearStitch: 4` (İD); `rerun: 0.8` eklenir |
| | 72–157 `YURT_STEPS` | Her adımda `dur`, `crew` yerine `work`, `min`, `max`, `solo`, `tall`, `felt` (§4.1); `y_ocak` `fetch`; `help` alanı kalır (Çocuğun iş türü), değer kimliği aynı |
| | 159–177 `YURT` | `craft: 'home'`, `crewMax: 8` |
| | 190–222 `STABLE.steps` | `work` 140, 340, 510, 270, 765; `st_beams` `min 2`, `solo 1.5`; `craft: 'wood'`, `crewMax: 6` |
| | 236–245 `FENCE` | `dur` 6/3 sn/m → `work` 7,2 / 3,6 İD/m; `max: 'seg'` |
| | 256–269 `PEN` | `p_line` 1,5 İD/m; `p_wattle` 20 İD/pano; `p_gate` 40 İD, `min 2`, `solo 1.25` |
| | 282–290 `CART` | `work` 110, 120, 40, 60, 32; `c_axle`, `c_tilt` iki ellik |
| | 297–307 `simple()` | `dur: 10 + hp×0,6` kuralı kalkar; her tür §8.1'in adım emeğini alır (`labour-model.json`) |
| | 365–393 `resolveSteps` | `per` çarpımı `work`'e; `max: 'seg'` → `min(8, parça sayısı)` |
| `src/world/structure-logic.js` | 3, 72–74, 144–186 | `advance(wm)`, `this.wm`, `rate` İD/oyun dk, `credit(wm)` çarpansız, `bonus` kalkar |
| | 189–206 `sliceTick` | Silinir (Kışlak `mode: 'timed'`, `SiteSystem` sürer); `_buildTo` senaryo için kalır |
| | 728–804 onarım | `repairStep(wm, who)`, `_raiseWork`, `_patchWork` (§7), yanık ×1,25 birim kömürse |
| | 300, 346 `doneAt` | İD cinsinden işlenen emek; saat damgası şantiye kaydında |
| | 976–1046 `toJSON`/`fromJSON` | Sürüm 2: `wm`, `credit` yok, `v: 2`; göç §14 |
| `src/world/structure.js` | 1277 `wait` | 20 gerçek sn kalır |
| | 1740–1751 `_work` | Oyun dakikası ve iki elin oranı (§11.3) |
| | 2112–2247 `StructureSystem` roam | camp3 sürüm 2 yazımı ve göçü |
| | yeni | `G_TORCH` grubu ve gece alevleri (camp3) |
| `src/game/builders.js` | 1 başlık yorumu | «zaman çizelgesi» → «emek çizelgesi» |
| | 61 `DENGIZ_CALL_K`, 1575–1580 | Kalkar; Dengiz girişte gelir |
| | 98–104 `workRate` | Silinir → `labour.stepRate` |
| | 221–368 `JOBS` | `dengiz` sütunu; uzun pencerede `loop`; `CHILD_JOBS` satırları |
| | 396–421 `HELP` | `CHILD_HELP` (§9.3); `credit`, `cap`, `total`, `late` alanları kalkar; `help_log` yığın eksiği, `help_ember` adım getirme payı, `help_water` ×1,1 / 60 oyun dk / 4 |
| | 735–1110 `HelpDesk` | `credit()` kalkar; katılma durumu, ayak işleri, su süresi oyun dakikası |
| | 1415–1421 `workDone` | `work` toplar |
| | 1423–1427 `crewCount` | `members()`: ağırlık listesi ve baş; `childCrew` → `child.joined` |
| | 1450–1474 `advance` | `dt × 0,4 × oran` |
| | 1785–1815 `dueOf`, `tickJob` | `dur` → `stepSpanS()` |
| | yeni durumlar | `SHELTER` (hava durağı), öğün sırası (12:00, 18:30), ilk gelişin 06:00–22:00 kuralı, 22:00'de kalış (§9.5) |
| | 2813–2814 `status` | `heads`, `W`, `etaMin`, `wait`, `solo` |
| `src/ui/hud/build-status.js` | yeni satır | Ekip ve «≈N saat» ya da bekleme nedeni (§6.11) |
| `src/i18n/strings/structures.js` | yeni anahtarlar | `labour.*` (§6, §9) |
| `test/structure-logic.test.js` | 150–173 | «yardımsız 590 sn» → «`advance` 1.282 İD'de biter, 13 adım sırası aynı, `wm` 1.282» |
| | 187–206 | «283 sn» kalkar → «`credit(wm)` çarpansız düşer» |
| | 304–338 | Onarım değerleri İD: k3 kaldırma 18,13, k2 yama 6,8 |
| | 352–375 | Yeniden kurulum emeği (aşama 5→7): ×0,8 yeniden koşma dahil |
| | 424 | Ahır `steps` toplamı 380 sn → tek el 2.160 İD |
| `test/builders.test.js` | 1, 19–24 | Başlık ve `YURT_STEPS` tablosu `work`, `min`, `max`, `solo` |
| | 26–58 `TimelineState` | `credit` ve 2 kat erime kalkar; `advance(wm)` |
| | 125–134 | `workRate` sınaması → `labour.test.js` |
| | 136–154 | Yardım toplamları 217/60/30/283 → `CHILD_HELP` satır sınaması |
| | 156–180 | «590 sn ±5» → «yardımsız üç ustayla, saatsiz sınamada 1.338 sn ±10 (22,3 dk; uuk başında Dengiz 4 kütüğe gider); 14:54 saatiyle ve öğünle 1.405 sn ±15», Dengiz her adımda |
| | 182–198 | Takılan usta: bekleme ≤6 sn aynen; süre «1.338 + 6,5» (saatsiz) |
| | 280–292 | «≥283 sn» → «Çocuk her adımda katılır, kütük ve köz getirir: saatsiz 1.125 sn ±10 (18,8 dk), 14:54 saatiyle 1.181 sn ±15; ayak işi olmadan saatsiz 1.170 sn ±10» |
| | 296–311 | «Çocuk tündükte bir usta sayılır» → «katılan Çocuk 0,5 ağırlık ve bir baştır; ayak işindeyken ekipte sayılmaz» |
| | 418–427 | Gerçek `StructureState`: saatsiz 1.338 sn ±10 |

## 13. Bütçe

| İş | Tavan | Not |
|---|---|---|
| `labour.js` oran | Değişimde ≤0,02 ms; kare başına O(1) | Oran önbellekte, ≤4 Hz yenilenir |
| Uzak şantiye | ≤24 şantiye, kare başına ≤0,05 ms | Çarpma ve toplama |
| Toplu benzetim | Bir oyun günü, 24 şantiye ≤0,3 ms | 24 dilim × adım |
| camp3 Dengiz baştan sona | +14k ana, +14k gölge üçgen; +3 / +3 çizim | Faz 6'nın ölçülen en kötü karesi +217k, +35 çizim → +245k, +41: `structures.md` §13.3 tavanı ≤250k, ≤45 içinde |
| camp3 meşale direkleri | +≈120 üçgen `frame`'de, 0 çizim; 2 `fxFlames` (havuz 24), 2 `fxGlow` (havuz 8) | Işık eklenmez; program eklenmez (≤92) |
| Yerleşim şantiyesi | Şantiye başına ≤8 tam `Folk` 40 m içinde; dünyada ≤16 tam (`NpcManager.budget`); 40–120 m kukla; ötesi yok | Yerleşim sahnesi bütçesi yerleşim alanınındır |
| Ses | Gece aletleri −4 dB; meşale çıtırtısı ≤2 kaynak | `d2/labour-delta-audio.md` |
| Kayıt | Şantiye ≤3 KB; `world.sites` dünya başına ≤16 KB; bitmiş sağlam yapı sıkı biçim ≈40 B | Yolculuk kaydı ≤96 KB (§3.5) |

Menü karesi değişmez: camp3, direkler, ustalar ve Çocuğun katılma halkası menü kipinde gizlidir (`drawMenuFrame` aynen).

## 14. Kayıt

**Serbest Gez `tanhu.roam.camp3`, sürüm 2.**

```jsonc
{ "camp3": { "v": 2, "stage": 3, "hp": [0, 40, 60, 50, 0, 0, 0, 0], "wm": 514.7, "step": 5, "stepT": 0.31,
    "units": {}, "fell": [], "tears": [], "arrows": [], "char": {}, "scorch": [], "emberT": 0, "burnT": 0, "cut": 0, "stuck": 0,
    "done": 31, "peak": 5.31, "doneAt": null, "delivered": {},
    "contrib": { "player": 0, "npc": 0, "wm": { "player": 12.5, "npc": 502.2 } },
    "crew": { "arrived": true },
    "child": { "joined": false, "logs": 2, "ember": 0, "water": 1, "waterUntil": 1095.0, "waterNext": 1095.0 },
    "stock": { "short": { "tag:wood": 2 } }, "startMin": 894.0 } }
```

**Göç 1 → 2.** `stage`, `hp`, `units`, `fell`, `tears`, `arrows`, `char`, `scorch`, `done`, `peak`, `step`, `stepT` aynen (adım içi oran emekten bağımsızdır). `t` atılır, `wm` adım ve oranından hesaplanır. `credit` atılır (kalan kredi kaybolur: en çok birkaç dakikalık fark). `help` sayaçları sıfırlanır; `logs` 0, `ember` 0. `doneAt` varsa bitmiş yapıdır: `doneAt: 0`. Bozuk alan sessizce varsayılana düşer (bugünkü kural).

**Yolculuk, yeni blok `world.sites` (order 76, `game/sites.js`).** Dünyaya göre ayrılır (`zone`), yerleşim Mete yokken de yaşar.

```jsonc
{ "v": 1, "zones": { "own_camp": { "lastMin": 41210.0, "sites": {
    "s_014": { "kind": "yurt", "preset": "winter", "p": [12.0, -40.5, 0.6, 0.12], "st": { /* StructureState v2 */ },
               "stock": { "felt": 2, "rope": 4 }, "crew": ["h_03a", "h_03b"], "orders": { "night": "work", "priority": 2 },
               "contrib": { "player": 18, "npc": 36, "wm": { "player": 120, "npc": 980 } }, "wait": null },
    "s_002": [ "yurt", 3.0, -12.0, 1.57, "done" ] } } } }
```

Bitmiş ve sağlam yapı sıkı dizidir; ordugâh çadırları `CampPlan` kaydıdır (`count`, `seed`, `doneAt`), tek tek yazılmaz. `world.structures` (73) senaryo yapılarını tutar, şantiyeye bağlı yapı yalnız `world.sites`'tadır. Kışlak Yeni Yurdu yolculuk kaydında `world.sites.zones.hexi_winter.sites.new_yurt`'tür (`act1.md` `yurt_stage_night` okuması aynen).

## 15. Test planı

**Saf (`test/labour.test.js`, yeni).**
1. `eff` tablosu: 1; 1,9; 2,71; 3,439; 4,68559; 5,6953279; `eff(0,5)` 0,5; artan; `eff(W) ≤ W`.
2. Yurt tek el toplamı tam 1.440 İD; ekip toplamı 1.282.
3. Tek işçi (W 1, baş 1) dakika adımlı benzetimle 60,00 gerçek dk ±0,01.
4. Ekip çizelgesi 1–8: §4.3 değerleri ±0,05 dk; kesin azalan.
5. İki el kuralı: usta + çocuk (baş 2, W 1,5) tek el çarpanını kaldırır: 36,80 dk; usta + çırak 32,06.
6. Önder kuralı: yalnız çocuk 0 ilerler; yalnız çırak ilerler, usta kuralıyla ×0,7.
7. Usta kuralı: `wood` yapı, ustasız 4 el, ×0,7.
8. Gece: ışıklı 1, dolunay 0,7, karanlık 0,4; meşale karanlığın 4 saatinde 1 `torch`.
9. Hava: §5.2 her satırı; sağanakta keçe adımı bekler, uzun iş yürür.
10. Onarım: §7 örnekleri (457; 22,5; 18,13; 1.092; 256; 29,3 İD).
11. Taşıma: 146 Yük, 50 m → 8 sefer, 224,1 İD; araba 3 sefer.
12. Toplu benzetim eşdeğerliği: `simulate(600)` = 600 × `simulate(1)` ±1e−6.
13. Söküm 504 İD; malzeme döner, köz dönmez.
14. `etaWords` saat ve gün sınırları.
15. `labour-model.json` ile `LABOUR` ve `STRUCTURE_DEFS` aynı sayıları taşır.

**`test/structure-logic.test.js`, `test/builders.test.js`** §12 satırlarıyla; ek: camp3 saatsiz yardımsız 1.338 sn ±10, katılma ve ayak işiyle 1.125 sn ±10; 14:54 saatiyle ve öğünle 1.405 sn ±15 ve 1.181 sn ±15; Dengiz her adımda; 22:00'de kalır; «Gece dinlenilsin» emriyle ertesi 08:16 ±10 oyun dk; `SHELTER`'da emek durur; takılan usta ≤6 sn bekletir; menü kipinde ustalar ve direkler gizli.

**`test/sites.test.js` (yeni).** Yerleşim nedenleri (eğim, ağaç, yakınlık, yol); yığın tüketimi ve bekleme nedeni; 150 m kendi taşıması; gece emri; çalışma atlaması; kayıt gidiş dönüş; Kışlak benzetimi §10.1 tablosunu ±2 oyun dk verir (NPC ve oyuncu sütunları).

**Tarayıcı.** camp3 baştan sona `__tanhu.struct.speed(20)` ile: adım sırası, gece direkleri, katılan Çocuğun yolları; hava denemesi (`__tanhu.labour.weather('rain')`); `menuDiff` 0 piksel; program ≤92; en kötü kare ≤+250k, ≤+45 çizim.

## 16. Komşu belgelerde değişecekler

`architecture.md`, `structures.md`, `audio.md`: birebir metin delta dosyalarındadır. Ötekiler (sahibi birleştirir):

| Belge | Bölüm | Değişiklik |
|---|---|---|
| `act1.md` | §2 Gün dilimi | İş Puanı yerine saat (zaman alanı); Yeni Yurt artık dilim saymaz |
| | §5 NPC programı | Zaman taslağının saat tablosu (`d2/time.md` §9.4) geçerli; ek satır: iki el (adsız `Folk`) Yeni Yurt pedi 07:00–23:00 |
| | §8.1 | «Nanay, Farnak, Sak, Ardokşa ve iki işçi» aynen; tündük iki eldir (el sınırı 6), 3 hamle aynen |
| | §9.3 tablo, «3 Tündük» satırı | «1 tündük, 2 sırık; 3 kişi» → «1 tündük, 2 sırık; iki el» |
| | §9.3 «Yeni Yurt takvimi» | Bu belgenin §10.1 paragrafı ve tablosu |
| | §9.3 «Ana kampın üçüncü yurdu» | «13 adım 590 sn (yardımla en az 283 sn), 2–3 usta; Çocuk kütük getirirse −15 sn» → «13 adım, emek 1 iş günü; Oktar, Erka ve Dengiz ile, öğün sırasıyla 23,4 dk (14:54 → 00:16), Çocuğun bütün yardımıyla 19,7 dk (`d2/labour.md` §9)» |
| | §17 #5 | «Kışlakta dilim, ana kampta 590 sn» → «Kışlakta saat ve malzeme, ana kampta emek yasası (K21)» |
| `economy.md` | §6.3 | «3 kişi şartı kalır» → «tündük iki el ister»; tabloya «Ekip emeği İD» sütunu (aşama 0–7: 75, 75, 181, 100, 270, 105, 256, 220; toplam 1.282; tek el 1.440) |
| | §6.4 | Başa: «Kurulum emeği `d2/labour.md` §8» |
| | §6.5 | Paragraf: «Yer, emek ve ekip `structures.md` §11, `d2/labour.md` §9. Ekonominin payı yalnız odun yığınıdır: camp3 yığını 4 kütük eksik başlar; Çocuk getirmezse Dengiz gider» |
| | §8.2 | «`camp3` yardımı» → «`camp3` ekibine katılmak ve ayak işleri» |
| | §8.3 | Yeni satır: «Kendi ocağın emeği: ışıklı şantiyede yetişkin günde 1 iş günü, açık hava işinde 0,8; `d2/labour.md` §1» (ekonomi taslağı bunu zaten yazar: `d2/economy.md` §0 tablosu) |
| | §10.1 | Yeni hedef satırı: «Yapı başına gerçek dakika: §8.1 tablosu, dörtlük ekip» (K24 hedefleri ekonomi alanınındır) |
| `progression.md` | §2.5 Yük satırı | «`help_log` kütüğü −15 sn; öteki yardımlar §11.6» → «Çocuk yardım ederken yarım el (`d2/labour.md` §9.3)» |
| | §4.5 `repair`, `quick_raise` | Sayılar aynen; Act 1 sütununun yanına K21 anlamı (§3 tablosu) |
| | §4.5 `wagon_ring` | «Kuruluş 20 sn savaş düzenidir, emek yasası dışında» notu |
| | §13.4 | `camp3` örneği sürüm 2 (§14) |
| `army.md` | §3.6 İş Kolu | «crew = Squad.members, 5–10 kişide ×2,2 tavan» → «K21: `eff(W)`, yapı başına ≤8 el, fazlası taşır» |
| | §3.6 Ordugâh | «Onluk `tent`, `mode: 'slice'`» → «Onluk 2 çadır, 216 İD'lik, 5'er el: ≈2,3 dk; `CampPlan` toplu» |
| `travel.md` | §3.6 | «Sıradan onarım 1 odun, 1 ip, 25 sn» → «… emek 29 İD: Mete ve sürücüyle ≈39 sn, `repair` ile ≈19 sn» |
| | §17 tablosu, `help_log` satırı | «−15 sn» → «camp3 yığınının 4 kütük eksiği» |
| `survival.md` | §2 | Yeni madde: «Işık şantiyede gece işini açar (`d2/labour.md` §5.1); ısıtmaz (K1)» |
| `d2/time.md` (K20 taslağı) | §8.3 Ustalar | «Oktar ve Erka (tündükte Dengiz)» → «Oktar, Erka ve Dengiz»; «22:00 İş biter, kuzeye çıkarlar; Çocuk o gece yardım yuvası bulmaz» → «22:00'den sonra meşalede sürer, yurt bitince çıkarlar (K21); `Gece dinlenilsin` emriyle 22:00'de çıkarlar» (§9.5) |
| | §10.1 | «İş penceresi NPC ekiplerinindir» → «İş penceresi üretim ve ev işlerinindir; inşaat ekipleri K21 gereği kesintisizdir, `Gece dinlenilsin` emri pencereye çeker» |
| | §7.1 Bekle tekeri | Şantiyede çalışma kipi (§6.7): «Bir saat çalış», «Üç saat çalış», «Akşama dek çalış», «Bitene dek çalış»; `clock:skip` `reason: 'work'` |
| `d2/time-delta-structures.md` | S1, S3–S7 | Aynı satırlara bu belgenin delta dosyası birleşik metin yazar (`labour-delta-structures.md` başı); S2'nin yerine D15b |
| `d2/weather.md` (K22 taslağı) | §8.11 | Önerilen iki satır (`sleet`, `dry_storm`) `labour-model.json`'a girdi; `SHELTER` ve `lock.weather_build` dizgesi benimsendi; ay görünürlüğü `fx.moonSeen` ile `nightK`'ya bağlandı |
| `d2/econ-model.json` | `structures.*.crewMax` | §8.1 «Şantiye el tavanı» satırıyla eşlenir (tent 3 → 4, cart 3 → 4, hut 3 → 4, tower 4 → 6, bridge 6 → 8, fence 2 → 5 / 10 m); otağ 12 bu belgeye geçti |

**Zaman alanına (K20):** oyun dakikası `WorldClock.abs`, `dark`, `daylight.lightLevel`, `calendar.moonIllum()` ve `clock:skip { from, to, minutes, reason, sleep }` okunur; `reason` değerlerine `work` eklenir.
**Hava alanına (K22):** kimlikler `d2/weather.md` §3.1 listesidir; `fx.type`, `fx.sev`, `fx.moonSeen` okunur; tamamlanmamış yapı yıldırım hedefi olmaz (onların kuralı).
**Yerleşim alanına (K23):** §8.2, §8.3 adları ve kademeleri; hane kaydında `role`, `w`, `crafts`; «Boştaki eller yapıya» ayarı; fenerler ışık sayılır mı.
**Ekonomi alanına (K24):** bileşen malzeme listeleri adım `cost`'una; zanaat İS ile ödenir (benimsendi); meşale tüketimi ve `fed` eşikleri; `haulMinPerYuk` 0,02 değeri ≈ araba ile 50 m taşımaya denktir, yaya taşıma bunun 3 katıdır (§6.3).

## 17. Doldurulan boşluklar

1. Kesirli ağırlıkta verim: `eff(W) = min(W, 10·(1 − 0,9^W))`.
2. El ile ağırlığın ayrılması: iki ellik kural başa, hız ağırlığa.
3. Dört iki ellik adım ve tek el yöntemleri, çarpanları, görünümleri.
4. Roller, zanaatlar (`home`, `wood`, `earth`), önder ve usta kuralları; Mete'nin becerilerinin K21 anlamı.
5. Yardım türlerinin katılma ve ayak işi olarak yeniden yazılması; camp3 yığınının kütük eksiği, ocağın köz payı, suyun çarpanı.
6. Gece ışığı kaynakları, ay, meşale tüketimi, gece emri.
7. Şantiyenin hava tepkisi ve yıldırım adayları.
8. Taşıma emeği ve 150 m kendi taşıması.
9. Söküm (göç) emeği.
10. Çalışma atlaması.
11. Kışlak Yeni Yurdu'nun saat, ekip, gönderim ve kapı tablosu; `job_raise` önerisi.
12. Uzak şantiye, toplu benzetim ve dönüşte yetişme.
13. Yerleşim kuralları ve düğüm temizliği.
14. Onarımın İD karşılığı, yeniden koşan adım ×0,8, çocuğun yırtık dikişi, ana kampın yedek onarım eli.
15. `wagon_ring` gibi savaş düzenlerinin yasa dışı kalması; ≤12 İD'lik basılı tutma kuralı.
16. `?q=low`'da süreyi değiştirmeyen kukla Dengiz.
17. K23 yapılarının emek, el sınırı ve zanaat taslağı; ordugâh çadırlarının toplu kurulumu.
18. Esir emeği olmaması.
19. Yaşlının yarım güçle usta ve önder sayılması.
20. İnşaatın kesintisiz, üretimin pencereli olduğu ayrım (§9.5).

## 18. Açık sorular

> **Kapandı (2026-11-04, E6).** Taslak izdir (K31); beş sorunun hepsi kapandı, sahibi belgeler ve K'ler geçerlidir. Her maddenin sonunda kapatan karar yazılıdır.

1. **22:00 durağı (zaman alanıyla):** inşaat ekipleri kesintisiz mi (bu belge, K21, ekonomi taslağı) yoksa 06:00–22:00 penceresinde mi (zaman taslağı)? Öneri §9.5; baş mühendis seçer. Seçime göre camp3 ilk dumanı 00:16 ya da ertesi 08:16. (K21 ile kapandı: inşaat kesintisizdir, «Gece dinlenilsin» emri ekibi pencereye çeker; camp3'ün saatleri K50 ve K83'tür, `structures.md` §11.6.)
2. **Yerleşim fenerleri (yerleşim alanı):** ışık sayılırsa şantiyelerin meşale talebi düşer. (K21 ile kapandı: yerleşimin fenerleri `K_gece`'de ışık sayılır, `structures.md` §2.4.)
3. **`quick_raise` ×0,7:** K21'de ekip büyüdükçe çok güçlü (8 elle 11,6 → 8,1 dk). Sayı korundu; ilerleme alanı ×0,8'e indirmek isterse bu belge yalnız sabiti değiştirir. (K50 ile kapandı: ×1/0,7 kaldı; K50 eğrisinde 8 el 8,0 dk, `quick_raise` ile 5,6 dk, `structures.md` §2.4.)
4. **`job_raise`:** act1 ve ekonomi sahibi İş Tahtası'na eklemeyi onaylamalı. (K21 ile kapandı: `job_raise` yoktur.)
5. **`keymap.rotate`:** zaman taslağının paketi `keymap.js`'e dokunuyor; yerleşim döndürme eylemi o pakete eklenmeli. (K57 ve K39 ile kapandı: `keymap.rotate` prototipindi; Godot'da Plan Kipi nesneyi Q / E ile döndürür, tuşlar yeniden atanabilir.)

## 19. Doğrulama durumu

- **Okundu:** komşu taslaklar `d2/time.md` (§0–§2, §5.1, §7, §8, §9, §10, §12.2–§12.3), `d2/time-delta-structures.md`, `d2/time-delta-architecture.md` (A9, A10, A18, A22), `d2/weather.md` (§3.1, §5.9, §8.7, §8.11, §8.12), `d2/economy.md` (§0, §5, §8 satırları), `d2/econ-model.json` (`params`, `structures`); `decisions.md`; `architecture.md` §0, §2.5, §2.6, §3.5, §3.7, §3.8, §3.11–§3.13, §3.16, §3.17, §3.22, §5, §6.1, §7, §8; `structures.md` bütünü; `act1.md` §1, §2, §4, §5, §6, §8.1–§8.3, §9; `economy.md` §2, §4, §6, §8, §10; `progression.md` §2, §4.1–§4.5, §8.3, §13.4; `army.md` §0–§3; `travel.md` §3.2, §3.6, §6.8, §9.1, §10.3; `survival.md` §1–§4; `audio.md`; `contract-requests.md` Faz 6 satırları. Kod: `structure-defs.js` (bütün), `structure-logic.js` (zaman çizelgesi, onarım, kayıt), `structure.js` (`_work`, roam kaydı), `builders.js` (sabitler, `JOBS`, `HELP`, çizelge), `build-status.js`, `clock.js`, `test/builders.test.js`, `test/structure-logic.test.js` ilgili satırları.
- **Betikle hesaplandı** (geçici dizinde, projeye yalnız `labour-model.json` yazıldı): §2 verim tablosu; §4.3 ekip çizelgesi, adım tablosu, karışık ekipler; §6.3 taşıma; §6.9 söküm; §7 onarım örnekleri; §8.1 tür toplamları ve 1/2/4/8 el süreleri; §9.1 camp3 adım adım ve dört yardım senaryosu (0,1 oyun dakikası adımlı, kütük eksiği ve köz payıyla); §9.1 ilk gün benzetimi (14:54 başlangıç, öğün sırası, gece meşale ve 22:00 durağı karşılaştırması); §10.1 Kışlak benzetimi (dakika adımlı, zaman taslağının saatleriyle; NPC, oyuncu malzemesi, Mete'nin sabah işi). Tek el toplamı 1.440, ekip toplamı 1.282; ekip süresi her el sayısında azalır.
- **Hesap, koşulmadı:** §13 bütçe satırları (Faz 6 ölçümleri ve `Folk` üçgenleriyle toplama), K23 yapılarının 4 el süreleri (tek el çarpanı yok sayılarak).
- **Yapılmadı:** hiçbir kod, oyun içi deneme ya da tarayıcı ölçümü; `?state=play&sandbox=site` yok.
