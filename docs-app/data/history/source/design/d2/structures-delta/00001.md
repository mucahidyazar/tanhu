# `structures.md` birleşik deltası (K20–K24; emek ve ekonomi birleşmesi)

Tarih 2026-11-03. Faz 7 bitince `L` işler; Faz 7 sürerken `structures.md` düzenlenmez (`decisions.md` K26). **Bu dosya `structures.md` için tek işleme defteridir.** `d2/core-delta-structures.md` (§2 değişiklikleri, CS1–CS3), `d2/labour-delta-structures.md` (D1–D26), `d2/time-delta-structures.md` (S1–S7, zaten labour'ın içindeydi), `d2/weather-delta-structures.md` (1–8), `d2/settlement-delta-structures.md` (SD1–SD5) ve `d2/economy-delta-structures.md` (S1–S5) maddelerini `d2/core.md` §2–§5 sayılarıyla tek metne indirir; `L` yalnız bu dosyayı işler, altı kaynak dosya iz için kalır ve ayrıca işlenmez. Maddeler `structures.md`'nin bölüm sırasıyla dizilidir.

**Emek yasası bu belgeye girer.** `d2/core.md` §8, `d2/labour.md`'nin kurallarının var olan belgelere işlenmesini ister: emek yasası `structures.md`'nin yeni §2.4'ü, genel şantiye yeni §2.5'i, yerleşim ve ordugâh yapıları yeni §4.6'sıdır. Eski deltaların «`labour.md` §n» başvuruları burada bu bölümlere çevrildi; `d2/labour.md` ayrı belge olarak taşınmaz.

**Sayılar `d2/core.md` §2'dendir; üç yerde gerekçeyle inceltildi:**
1. camp3'ün yardımsız ilk dumanı ≈00:51 → **≈00:55** (+4 oyun dk = +10 gerçek sn). Core §2.11 tablosu, §2.10'un su kuralını (Çocuk su getirmezse zemin adımında Dengiz iki kez gider, her biri 20 gerçek sn) saymadan hesaplanmıştı. Aynı nedenle yardımsız tündük 17:58 → 18:02 (yine batıştan önce), «yalnız katılma» 23:34 → 23:37, «Gece dinlenilsin» ≈08:50 → ≈08:55, saatsiz yardımsız saf emek 1.423 → 1.434 sn, saatli yardımsız 1.493 → 1.503 sn (`d2/core-delta-architecture.md` C11'in kabul sayısı da). Bütün yardımla 23:11 (1.244 sn), yalnız ayak işi 00:27 ve bütün yardımla tündük 17:34 aynen; saatsiz bütün yardım 1.187 → 1.188 sn (yuvarlama). Benzetim 0,05 oyun dakikası adımlıdır; aile 01:30'a dek beklediği için hikâye değişmez.
2. Kışlak'ın Gün V yaması 256 → **275 İD**, 07:00–08:35 → **07:00–08:42**: core §2.12 eski adım tablosuyla (tuurduk 120, üzük 136) hesaplanmıştı; §2.2 tablosuyla (129, 146) × 0,8 × 1,25 = 275.
3. camp3 + Çocuk saf emeği 20,3 → **20,4 dk** (488,8 oyun dk = 20,37 dk; Çocuk `y_esik` ve `y_ocak`'ta sayılmaz).
4. usta + Çocuk 39,5 → **39,8 dk** (aynı kural; doğrulama V3, `d2/core.md` §2.3). Ayrıca doğrulama turunun kararları (2026-11-03, `d2/core.md` §7.1): ham kerege `cr_carpenter` ister, ×0,7 yolu yoktur (V18); atanan el nöbetleşmez (V36); `quick_raise` II. Perde açılışında yoktur, ilk onlukla yurt 11,2 dk (V9); aile 01:30'da aşama ≥6 ise 03:00'e dek bekler, kuralın sahibi `BuilderSystem` (V5, V33); kapı keçesi ipucu (V37); yerleşik atlı kendi çadırıyla gelir (V1).

**Core'un emek alanına bıraktığı tablolar burada kesinleşir** (`d2/core.md` §2.13): yurt gövdeli türlerin adım farkı (§3.5; Silahlık ve Okçu Yurdu `economy.md` §6.12'deki gibi ocaksızdır, raf adımı 308 İD ile 1,2 İG'yi tutar) ve K23 türlerinin, büyük arabaların adım tabloları (§4.6). İG'ler `settlement.md` §7'nin ve iki modelin `labourWd` alanıyla aynıdır (keçe araba 0,4, yüksek teker 0,6); `crewMax` için §4.5 ve §4.6 geçerlidir, modellerin eski sütunu bunu kopyalar.

Biçim: **Bul** birebir metindir (2026-11-03'te bugünkü `structures.md`'de tek eşleşme olarak denetlendi; maddeler sırayla işlenince de her biri tek eşleşmedir); **Yerine**, **Önüne ekle** ya da **Sonrasına ekle** yeni metnin tamamıdır. **Yerine** bulunan metnin yerine birebir girer. **Önüne ekle** ve **Sonrasına ekle** yeni metni bulunan metnin önüne ya da ardına ayrı blok olarak koyar, araya bir boş satır girer; eklenen metin tablo satırı ya da liste maddesiyse bir alt satıra, boş satırsız girer. **Bul (aralık)** başı ve sonu verilen bölümün tamamıdır. Faz 7 bir «Bul» metnini değiştirdiyse madde atlanmaz, `L`'ye sorulur (`d2/core.md` §6.7).

---

## X1. Giriş paragrafı

**Bul:** `` araba ağı `travel.md` §3 ile birdir. ``
**Yerine:** `` araba ağı `travel.md` §3 ile birdir. Emek yasası (K21) ve genel şantiye bu belgenin §2.4 ve §2.5'idir; saat `time.md` (K20), hava `weather.md` (K22), yerleşim ve ordugâh yapıları §4.6 ve `settlement.md` (K23), malzeme, parça biçimi ve kaplar `economy.md` §2, §4.5, §6 (K24). ``

**Bul:** `` Yeni modüller: `world/structure.js`, `world/structure-defs.js`, `world/structure-shader.js`, `world/structure-fx.js`, `game/builders.js`. ``
**Yerine:** `` Yeni modüller: `world/structure.js`, `world/structure-defs.js`, `world/structure-shader.js`, `world/structure-fx.js`, `game/builders.js`; K21 ile `game/labour.js` (saf), `game/site-core.js` (saf), `game/sites.js`, `world/site-pad.js`. ``

## X2. §0 Karar özeti, ilk tablo

**Bul:**
```
| Süre | 8 × 3 dk = 24 dk | 590 sn = 9 dk 50 sn; yardımla en az 4 dk 43 sn | İstenen aralık 8–12 dk |
```
**Yerine:**
```
| Süre | 8 × 3 dk = 24 dk | Emek: tek işçiyle 1 iş günü (1.440 iş dakikası = 60 gerçek dk, §2.4). camp3'ü iki usta ve bir çırak kurar: öğün sırasıyla ≈25 dk (14:54 → ≈00:55), Çocuğun bütün yardımıyla 20,7 dk (23:11; §11.6) | K21 (2026-11-02): süre emekten çıkar |
```

**Bul:**
```
| Çocuğun yardımı | Odun getirirse aşama −15 sn | Kütük −15 sn korunur (`help_log`); ek olarak adıma göre 2–8 sn, 8 yardım türü (§11.6) | 13 adımın 12'si yardıma açık, toplam alt sınır 283 sn |
```
**Yerine:**
```
| Çocuğun yardımı | Odun getirirse aşama −15 sn | Çocuk adımın fiilini yaptıkça yarım el (0,5) ve bir baştır; kütük, köz ve su ayak işidir (§11.6) | K21: «çocuk yarım işçi»; kredi ve 3 kat erime kalktı |
```

**Bul:**
```
| `economy.md` §6.5 | (−22,−20), 180 sn/aşama, aşamada 8 parça | §11.1, §11.6: adım başına 1 parça, toplam 4, parça −15 sn | Yer geçersiz; adımlar kısa |
```
**Yerine:**
```
| `economy.md` §6.5 | (−22,−20), 180 sn/aşama, aşamada 8 parça | §11.1, §11.6: yığın uuk için 4 kütük eksik başlar; Çocuk getirmezse Dengiz gider | Yer geçersiz; K21 emek yasası |
```

## X3. §1 Gerçek kurulum sırası ve sözcükler, ilk paragraf

**Bul:** `2–3 kişi bir boz yurdu gerçekte 60–90 dakikada kurar. Oyun bunu ≈1:8 sıkıştırır; sıra korunur.`
**Yerine:** `2–3 kişi bir boz yurdu gerçekte 60–90 dakikada kurar. Oyun emeği K21 ile sabitler: yurt bir işçinin bir iş günüdür (1.440 iş dakikası, tek işçiyle 60 gerçek dakika); ekip büyüdükçe süre azalan verimle kısalır (§2.4). Sıra korunur.`

## X4. §2.1 Kavramlar, tabloya iki satır

**Bul:** `` | Adım | `step` | Gerçek iş sırası; bir aşamada 1–4 adım | ``
**Sonrasına ekle:**
```
| Emek | `work` | Adımın ekip emeği (iş dakikası); tek el emeği `solo`, el sınırı `min`–`max` (§2.4) |
| Şantiye | `ConstructionSite` | Bir yapının yerleşimden bitişe ve sökümüne dek yaşamı: yer, yığın, ekip, emirler, bekleme nedeni (§2.5) |
```

## X5. §2.2 Veri biçimi

**Bul:**
```
  steps: [
    { id: 'y_kerege', stage: 2, name: { tr: 'Kerege', en: 'Lattice Walls' }, dur: 70, crew: 2,
      cost: { 'tag:wood': 8, rope: 2 }, mat: 'lattice', hp: 45,
```
**Yerine:**
```
  craft: 'home', crewMax: 8,                                         // §2.4
  steps: [
    { id: 'y_kerege', stage: 2, name: { tr: 'Kerege', en: 'Lattice Walls' }, work: 146, min: 1, max: 8,   // tek el yöntemi yalnız y_tunduk'ta: solo: 1.6, min: 2
      cost: { 'tag:wood': 8, rope: 2 }, mat: 'lattice', hp: 45,
      parts: { kerege_set: 1 }, rawWork: 720, rawRole: 'cr_carpenter',   // K24: parça gelirse cost karşılanır; ham gelirse adıma rawWork İD eklenir (§2.4)
```

**Bul:**
```
  constructor(def, place, world, { mode: 'timed' | 'slice', preset, startFull })
  stage; step; stepT;                 // aşama, adım dizini, adım içi 0..1
  advance(dtWork);                    // zaman modu
  sliceTick();                        // Kışlak dilim modu (§14)
  deliver(item, n, who);              // malzeme; who 'player' | 'npc', contrib sayılır
  credit(seconds);                    // oyuncu yardımı
```
**Yerine:**
```
  constructor(def, place, world, { mode: 'timed' | 'script', preset, startFull })   // K20: 'slice' kalktı; Kışlak da dünya saatiyle
  stage; step; stepT; wm;             // aşama, adım dizini, adım içi 0..1, işlenen emek (iş dakikası)
  advance(wm);                        // emek kipi: wm = oran × oyun dakikası; oranı sürücü yazar, atlamada toplu (§2.4, §2.5)
  deliver(item, n, who);              // malzeme; who 'player' | 'npc', contrib sayılır; bohça (yurt_kit, tent_kit) açılır
  credit(wm);                         // senaryo armağanı, çarpansız
  dismantle();                        // söküm: tersten, emeğin 0,35'i (§2.4)
```

**Bul:**
```
  repairStep(dtWork, who);            // §7
```
**Yerine:**
```
  repairStep(wm, who);                // §7, iş dakikası
```

**Bul:** `` `StructureManager` (`world.structures`) listeyi tutar ``
**Önüne ekle (yeni paragraf):**
```
**Parça ve ham biçim (K24, `economy.md` §6.3).** `cost` a1 ham biçimidir ve değişmez. `parts` aynı adımın II. Perde ve sonrası bileşen biçimidir: teslim edilen parça `cost`'u bütünüyle karşılar. Şantiyeye ham mal gelirse adımın emeğine `rawWork` İD eklenir (bileşen tarifinin İS'i × 60) ve `rawRole` varsa ekipte o rolün ustası bulunmalıdır; yoksa ham pay işlemez, adım `master` nedeniyle bekler (usta tarifinin ustasız yolu yoktur, `economy.md` §6.7). I. Perde ve ana kampın şantiyeleri (`camp3`, Kışlak Yeni Yurdu, onarımlar, senaryo şantiyeleri) `spec.labour.rawWork: false` taşır: malzeme yontulmuş gelir, `rawWork` eklenmez. Bohça (`yurt_kit`, `tent_kit`) teslimde açılır. Etiket çözümü `matches(id, ref)` iledir (`architecture.md` §3.13), ad öneki değil.
```

## X6. Yeni §2.4 Emek yasası ve §2.5 Şantiye

**Bul:** `Can çubuğu yoktur; hasar yapının üstünde okunur.`
**Sonrasına ekle:**
````
### 2.4 Emek yasası / Labour Law (K21)

Kullanıcı: «1 yurt 1 kişi ile 1 günde kurulabilsin, kişi arttıkça süre azalsın» (`decisions.md` K21). Sayıların makine okunur kopyası `d2/labour-model.json` v2'dir (2026-11-03, bu bölümle aynı sayılar); kesişen sayılar `d2/core.md` §2.

**Birimler.**

| Ölçü | Değer |
|---|---|
| İD, iş dakikası | Bir işçinin bir oyun dakikası emeği; tek işçiyle 1 İD = 2,5 gerçek sn (K20: 1 oyun günü 60 gerçek dk) |
| İS, iş saati | 60 İD |
| İG, iş günü | 1.440 İD = 24 İS = tek işçiyle 60 gerçek dk |

Emek dünya saatiyle akar (`WorldClock.abs`): saat durunca (menü, duraklatma, harita, diyalog, Bekle tekeri) emek de durur; saat atlayınca (uyku, Bekle, çalışma, yolculuk) emek `clock:skip`'te toplu işlenir (§2.5). Bütün yapılar, onarım, taşıma, söküm ve zanaat (`economy.md` §6.7) aynı birimle ve tek emek havuzundan ödenir.

**Ekip verimi.**

```
eff(W) = min(W, 10 · (1 − 0,9^W))      // W ≤ 1'de doğrusal, W ≥ 1'de K21 dizisi
W      = adımın el sınırına (max) dek en ağır üyelerin ağırlık toplamı;  eller = baş sayısı
oran   = eff(W) × K_usta × K_beceri × K_gece × K_hava × K_tok × hız / solo     // İD / oyun dk
solo   = eller < adım.min ? adım.solo : 1     // yurtta yalnız y_tunduk: bakanla ×1,6
```

| W | 0,5 | 0,75 | 1 | 1,5 | 2 | 2,5 | 2,75 | 3 | 3,25 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `eff` | 0,50 | 0,75 | 1 | 1,46 | 1,90 | 2,32 | 2,52 | 2,71 | 2,90 | 3,44 | 4,10 | 4,69 | 5,22 | 5,70 |

Her yeni el bir öncekinden biraz az katar: aynı ipi, kanadı, yolu paylaşırlar. `eff` toplam ağırlığa bakar, sıra bağımsızdır; el sınırı aşılırsa en ağır üyeler çalışır, kalanlar taşır ya da sonraki adımın yığınını hazırlar. Yapı başına tavan tanımın `crewMax`'ıdır (yurt 8, otağ 12; §4.6). Tek yapıyı çabuk bitirmek ile iki şantiyede toplam işi büyütmek arasındaki seçim oyuncunundur.

**Roller.**

| Rol | id | TR / EN | Ağırlık | Usta sayılır mı | Not |
|---|---|---|---|---|---|
| Usta | `usta` | Usta / Master | 1 | Kendi zanaatında | Sırayı bilir, adımı başlatır; adlı büyük usta ≤1,25 |
| El | `hand` | El / Hand | 1 | `home` zanaatında | Her yetişkin bir yurdu kurmayı bilir |
| Çırak | `apprentice` | Çırak / Apprentice | 0,75 | Hayır | 12–16 yaş; işi ilerletebilir |
| Yaşlı | `elder` | Yaşlı / Elder | 0,5 | Kendi zanaatında | Güç yarım, bilgi tam: şantiyede önder olur; sürü ve nöbete atanmaz |
| Çocuk | `child` | Çocuk / Child | 0,5 | Hayır | Yalnız Serbest Gez'in oyuncusu, fiili yaptıkça (§11.6); yerleşimin çocukları atanmaz |
| Mete | `mete` | Mete | 1 | `home` ustası | Emek becerileri aşağıda |

**Zanaat** (`def.craft`): `home` (Ev / Household: yurt, otağ, çadır, çit, ağıl, keçe avlusu, ordugâh yapıları; her yetişkin ustadır), `wood` (Ağaç / Woodwork: ahır, sundurma, ambar, kule, köprü, araba, atölye), `earth` (Toprak / Earthwork: kuyu, sur ve hendek, yarı gömük ev, ocak ve fırın, tarla). Ekonominin zanaatçı rolleri bunlara eşlenir (`economy.md` §6.8): `cr_carpenter`, `cr_cartwright`, `cr_bowyer` → `wood`; `cr_smith`, `cr_earth` → `earth`; ötekiler `home`. **Önder kuralı:** ekipte ağırlığı ≥0,75 ya da usta sayılan biri yoksa iş ilerlemez (yırtık dikmek hariç). **Usta kuralı:** yapının zanaatından usta yoksa oran ×0,7: «Usta yok: iş yavaş» / «No master: the work is slow».

**Mete** ekipte 1 ağırlıktır, `home` ustası sayılır. `quick_raise`: Mete ekipteyken o şantiyenin oranı ×1/0,7 (≈×1,43), Mete'nin buyurduğu şantiyeye yerleşimin boştaki elinden biri kendiliğinden katılır; `repair`: Mete'nin çalıştığı onarımda emek ×0,5, malzeme ¼; `carry_pack`: taşıma seferinde yük tavanı +8; `wagon_ring` savaş düzenidir, emek yasası dışında kalır (`progression.md` §4.5). Tek başına Mete bir yurdu 60 dk'da, `quick_raise` ile 42,0 dk'da kurar; ilk onlukla (8 el) 11,2 dk, `quick_raise` varsa 7,8 dk (beceri seviye 7 ve «Önce bir yurdu bitir» ister: II. Perde'nin ilk yurdu becerisizdir). **Esir emeği yoktur:** işçi havuzu hane, er ve gönüllü firaridir (K23).

**Çarpanlar.**

| Çarpan | Değer |
|---|---|
| `K_gece` | `daylight.nightClass` (`time.md` §12.3): `lit` ve `day` 1, `dim` (ay ışığı) 0,7, `dark` 0,4. Işık: şantiyenin meşale direği (yığında `torch` varken; karanlığın her 4 oyun saatinde 1 `torch`), ışık yarıçapı şantiye merkezine 4 m payla erişen yanan ateş (`survival.md` §2: 6, 10, 14 m), yerleşimin fenerleri. Ana kampta ve senaryo şantiyesinde meşale bedava (`spec.labour.torchFree`). Işık gösterir, ısıtmaz (K1) |
| `K_hava` | Aşağıdaki hava tablosu |
| `K_tok` | Bağlı defterin Yiyecek çizgisi ≥35: 1; <35: 0,85; <15: 0,7 (`economy.md` §7.1). Kışlak'ta 1'e iğneli |
| `K_beceri` | `quick_raise` ×1/0,7 |

**Gece emri ve günlük emek.** İnşaatın varsayılanı **«Gece de çalışılsın» / «Work through the night»**: ekip yapı bitene dek ışıkta sürer; atanan el bir işçidir ve nöbetleşmez (öğün ve uyku emeği durdurmaz; `dayCapacity('build')` el başına 24 İS, Kâhya bir el için bir işçi sayar; camp3'ün öğün sırası yalnız senaryo görünümüdür); bedeli meşaledir, Gönül bedeli yoktur. **«Gece dinlenilsin» / «Rest at night»** emri ekibi üretim penceresine çeker: ana kamp 06:00–22:00, Kışlak 07:00–23:00, yerleşim ve ordugâh yazın 05:30–21:30, kışın 07:00–23:00. Senaryo ekipleri hikâye programına uyar (Kışlak Yeni Yurdu: iki el 07:00–23:00, Nanay 10:30–19:30). Üretim ve ev işi (keçe, sepi, ağaç, aş, sağım, toplama) 16 saatlik penceredir, penceredeki her saat `nightClass` çarpanıyla sayılır, ışıklı atölye ×1; oyuncunun buyurduğu üretim gece vardiyası hanenin Gönül'ünü gece başına −0,2 düşürür. Çobanlık 24 saattir. Tek işlev: `labour.dayCapacity(job, dayInfo, lit, nightOrder)`.

| İşçi başına İS / gün | Yaz | Bahar | Güz | Kış |
|---|---|---|---|---|
| Açık hava üretimi (`tanhu_ordu` 43,5°K, pencere, ışıksız akşam) | 15,2 | 14,6 | 13,0 | 12,4 |
| Işıklı atölye | 16 | 16 | 16 | 16 |
| Şantiye, gece emri, ışıklı | 24 | 24 | 24 | 24 |
| Çobanlık | 24 | 24 | 24 | 24 |
| Hane (2,75 ağırlık, 0,65 çoban) | ≈47 | ≈46 | ≈43 | ≈42 |

**Hava tepkisi ve sığınma** (K22; hava yalnız fiziksel `fx` verir, bu tablo emeğin; `d2/core.md` §2.8). «Keçe adımı»: `y_tuurduk`, `y_uzuk`, `y_esik`, `y_sirdak`, `c_tilt`, `t_cover`; «uzun iş» (`tall`): `y_tunduk`, `y_uuk`, kule ve kiriş adımları.

| Hava | Genel | Keçe adımı | Durak (`hold`) |
|---|---|---|---|
| Açık, bulut, kapalı, sis, rüzgâr | 1 | 1 | |
| Çisenti | 1 | 0,9 | |
| Yağmur, sulu kar | 0,85 | 0,7 | |
| Sağanak | 0,5 | 0 | `felt` |
| Gök gürültülü fırtına | 0,5 | 0 | `felt`, `tall` |
| Kuru fırtına | 0,9 | 1 | `tall` |
| Fırtına (rüzgâr) | 0,9 | 0 | `felt`; kerege 0,8 |
| Kar | 0,9 | 0,9 | |
| Yoğun kar | 0,7 | 0,7 | |
| Dolu, tipi, Kara Boran, toz fırtınası | 0 | 0 | `all` |

| Durak | Ustalar |
|---|---|
| Yok | Oranla çalışır |
| `felt` ya da `tall` | Yerinde kalır: o adım bekler, ekip sonraki adımın yığınını hazırlar (`tall`'da bakandan 6 m çekilir); ne şimdiki ne sonraki adım ilerleyebiliyorsa `SHELTER` |
| `all` | Hemen `SHELTER` (en yakın yurt kapısı ya da ahır çatısı) |
| Dönüş | Adımın hava çarpanı 0,25 oyun saati (37 sn) işe izin verince |

Ustalar `weather.md` §8.12'nin genel NPC sığınma kuralına değil bu tabloya uyar; tek ortak nokta `all`'dır. Yıldırım kurulan yapıya inmez; ekip yine de bakandan çekilir: bekleyiş korkudur, zarar değil (§6.5). Ustanın sözleri §10.6. Hava durakları kampta ortalama ≈%8 uzatır; iş miktarı değişmez, takvim uzar.

**Çalışma atlaması.** Mete şantiyedeyken `T` (ya da `E` basılı 1 sn) Bekle tekerini çalışma kipinde açar (`time.md` §7.1): «Bir saat çalış / Work for an hour», «Üç saat çalış / Work for three hours», «Akşama dek çalış / Work until evening», «Bitene dek çalış / Work until it's done»; en çok 12 oyun saati, Bekle'nin yasak yerleri ve kesintileri; Tokluk uyanık oranıyla düşer, <25 ise satırlar kapalı: «Önce bir şey ye.» / «Eat something first.» Saat `clock:skip { reason: 'work' }` ile atlar, emek Mete ekipteymiş gibi işler (`quick_raise` dahil), ≥1 oyun saati ise oto kayıt `work`. Serbest Gez'de Çocuğun satırı «Bir saat yardım et / Help for an hour» aynı yoldur. İş Tahtası işi sayılmaz (`job_raise` yok).

**Taşıma.** Malzeme şantiyenin yığınında durmalıdır; ustalar 150 m'ye dek bağlı ambardan kendi taşır, önce el sınırını aşan boştaki eller, yoksa en hafif üye ekipten çıkar.

```
sefer_sn  = d / 1,9 + d / 1,4 + 8            // boş, dolu, alma ve bırakma
sefer     = ceil(yük / tavan)                // tavan: yetişkin 20, çırak 14, çocuk 6 Yük; Mete loadMax
taşıma_İD = sefer × sefer_sn / 2,5
araba     : sefer_sn = 2d / 6,8 + 30; keçe araba 60 Yük
```

| Yük | 25 m | 50 m | 100 m | 150 m | Araba, 50 m |
|---|---|---|---|---|---|
| Parça biçimli yurt, 89 Yük (5 sefer) | 78 İD (%5,4) | 140 (%9,7) | 264 (%18,3) | 388 (%26,9) | 36 (%2,5; 2 sefer) |
| Ham yurt (a1), 146 Yük (8 sefer) | 125 (%8,7) | 224 (%15,6) | 423 (%29,3) | 621 (%43,1) | 54 (%3,7; 3 sefer) |

150 m ötesi: «Malzeme uzakta» / «The materials are far away»: oyuncu getirir ya da araba atanır («Arabayla taşı» / «Haul by cart»).

**Parça biçimi ve ham teslim (K24).** K21'in «1 kişi 1 gün» çapası **standart (parça biçimli) yurdun kurulumudur**: bileşenler zanaattır (`economy.md` §6.10), kurulum emektir. Şantiyeye parça yerine ham mal gelirse parçanın zanaat emeği o adıma eklenir, aynı el sınırları ve ekiple işlenir:

| Adım | Ham biçim (a1) | `rawWork` |
|---|---|---|
| `y_bosaga` | 3 odun, 1 demir külçe | 360 İD (6 İS, `rc_door_frame`) |
| `y_kerege` | 8 odun, 2 ip | 720 İD (12 İS, `rc_kerege_set`; `cr_carpenter` ister: usta yoksa ham pay işlemez, adım `master` bekler) |
| `y_uuk` | 12 odun | 480 İD (8 İS, `rc_uuk_set`) |
| `y_liner` | 6 saz | 120 İD (2 İS, `rc_chiy`) |
| **Toplam** | | **1.680 İD = 28 İS**; ham biçimli yurt tek işçiyle 3.120 İD ≈ 2,17 gün |

Tündük her biçimde parçadır. HUD: «Ham malzeme: +{n} iş saati» / «Raw materials: +{n} work-hours». I. Perde ve ana kampın şantiyeleri `spec.labour.rawWork: false` taşır: yurt 1.440 İD kalır.

**Söküm** («Sök» / «Dismantle»): adımlar tersten, her adım kurulum emeğinin 0,35'i (tek el çarpanı da 0,35'le), el sınırları aynı; görünüm kurulumun tersi, döküntü yok. Malzeme yığına döner, `ember` yanar; sağlam yurt 1 `yurt_kit` (59 Yük) olur (`economy.md` §3.13). Yurt tek başına 21,0, dört elle 6,0 gerçek dk.

**Yurdun ekip çizelgesi** (yetişkin, usta var, gündüz, açık hava; §3.1 adımları):

| El | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
|---|---|---|---|---|---|---|---|---|
| Gerçek dk | 60,0 | 30,6 | 21,7 | 17,3 | 14,7 | 13,0 | 11,9 | 11,2 |
| Oyun saati | 24 sa | 12 sa 14 dk | 8 sa 40 dk | 6 sa 54 dk | 5 sa 52 dk | 5 sa 11 dk | 4 sa 46 dk | 4 sa 28 dk |
| K21 ideali (60 / eff) | 60,0 | 31,6 | 22,1 | 17,4 | 14,7 | 12,8 | 11,5 | 10,5 |

İki işçi tek işçinin iki katından hızlı değildir (1.440 / 733 = 1,96); el her arttığında süre kısalır. Büyük ekipte el sınırları (bosağa ve tündük 6, eşik 4, ocak 1) eğriyi idealin biraz üstünde tutar. **Karışık ekipler** (Çocuk `y_esik` ve `y_ocak`'ta sayılmaz): usta + Çocuk 39,8 dk; usta + çırak 34,4 dk; camp3 (Oktar 1, Erka 1, Dengiz 0,75) saf emek 559 oyun dk = 23,3 dk; camp3 + Çocuk 20,4 dk; Kışlak Nanay + iki el 21,7 dk; Mete yalnız `quick_raise` ile 42,0 dk; Mete ve ilk onluk 8 el 11,2 dk, `quick_raise` varsa 7,8 dk; yalnız el, ağaç yapıda ustasız ×0,7 (yapının zanaatı; usta tarifinin ustasız yolu yoktur). **Çocuğun yardımı** (sekiz tür) işçi katkısıdır: fiili yaptıkça yarım el; kütük, köz, su ayak işidir (§11.6).

### 2.5 Şantiye / Building Site (K21, K23)

**Kavram.** Şantiye (`ConstructionSite`) bir `StagedStructure`'ın yerleşimden bitişe ve sökümüne dek bütün yaşamıdır: yer, yığın, ekip, emirler, bekleme nedeni, katkı. Her `STRUCTURE_DEFS` türüyle çalışır. camp3 onun elle döşenmiş bir örneğidir (§11), Kışlak Yeni Yurdu senaryolu bir örneği (§14, `act1.md` §9.3), II. Perde'den yerleşim ve ordugâh yapıları oyuncunun açtığı örneklerdir (K23, §4.6, `settlement.md` §7). I. Perde altyapıyı ve geliştirici kum havuzunu kurar (`?state=play&sandbox=site`; yerleşim kipi `&hold=1`); hikâye açılışı II. Perde'dedir.

**Yerleşim.** Yapı listesinden tür seçilir; ayak dibinde iz önizlemesi (`Game.marker` gölgelendiricisi, yeni program yok), yeni `keymap.rotate` eylemi (öneri `R`) ya da tekerlek 15° döndürür; kapı varsayılanı yerleşimin ocağına bakar. Geçerli yer: iz `def.bounds` ile; yürüme ızgarasında kapalı hücre (`blocked`, `sb`) yok; eğim normal.y ≥0,9 (yurtta ped, `site-pad.js` genelleşir); su ve buz yok; başka yapının duvarına ≥4 m; yollara ≥3 m; senaryo yasak alanı yok. İzdeki ağaç ve iri kaya yerleşimi engeller (önce kesilir, kırılır); dal, ot, tezek düğümleri `y_site`'ta silinir (`perm` biti). Geçersizse halka kızıl, neden yazılır: «Yer düz değil» / «The ground is not level», «Ağaç var» / «A tree stands here», «Başka yapıya çok yakın» / «Too close to another building». Yer işaretlenince aşama 0 öncesi şantiye doğar: kazık ve ip izi, boş yığın alanı. Yerleşimde Plan Kipi bu yolun arayüzüdür (`settlement.md` §14.1).

**Yığın ve teslim.** Yığın / Stock şantiyenin kapı yanındaki dikdörtgenidir, bir `Container`'dır (`inventory.site(id)`, `economy.md` §4.5): kapasite türün malzeme yükünün 1,25 katı. Oyuncu yığında `E` 1 sn: heybedeki uyan malzeme girer, `contrib.player` sayılır; yığın dikdörtgenine bırakılan yer yığını teslim sayılır; araba yükü varışta kendiliğinden boşalır; bohça açılır. Adım başlarken o adımın `cost`'u (ya da `parts`'ı) yığından adıma geçer; eksikse adım başlamaz: «Malzeme bekliyor: {list}» / «Waiting for materials: {list}».

**Ekip atama.** Havuz yerleşim halkı (hane kaydı: yetişkin, çırak; çocuk atanmaz), ordugâhta birliğin eli (`strength − wounded`, `cmd_detail` İş Kolu), I. Perde'de senaryo kişileri. Bir kişi aynı anda tek şantiyededir; şantiyede çalışan başka iş üretmez. Şantiyede `E` «Ekip / Crew» ya da Yerleşim Defteri'nin yapı sayfası: + / − ile el, usta kendiliğinden seçilir; öncelik 0–3; «Boştaki eller yapıya / Idle hands to building» yerleşim ayarı. Mete «Çalış / Work» ile 1 ağırlıkla girer, Çocuk «Ustalara Katıl / Join the Builders» ile yarım el; hareket girdisi çıkarır: «Ekipten ayrıldın» / «You left the crew».

**İlerleme.** Görünen ve uzak bütün şantiyeler kare başına `dİD = dOyunDk × oran` işler; oran ekip, gece, hava ya da yığın değişince yeniden hesaplanır (≤4 Hz). Adım bitince `structure:step_done`, yapı bitince `structure:done` ve `site:done`. Ustanın görünümü emek çizelgesini süsler, takılan işçi emeği kilitlemez (§10.2). Kadraj dışındaki şantiyede işçi çizilmez, emek işler; 40 m içinde en çok 8 tam `Folk`, 40–120 m kukla, ötesi yok.

**Bekleme nedenleri** (öncelik sırasıyla tek neden yazılır).

| id | TR / EN | Ne olur |
|---|---|---|
| `fire` | «Yangın söndürülüyor» / «Putting out the fire» | Emek durur, kova zinciri (§6.3) |
| `threat` | «Tehlike: iş bırakıldı» / «Danger: work abandoned» | 40 m içinde düşman ya da baskın: `FLEE` |
| `storm` | «Ustalar fırtınanın dinmesini bekliyor.» / «The builders are waiting out the storm.» | §2.4 `all` durağı, `SHELTER` |
| `weather` | «Keçe yağmur dinsin diye bekliyor» / «The felt waits for the rain to ease»; «Rüzgâr keçeyi alıyor» / «The wind is taking the felt»; «Yıldırım: bakanın dibi boşaltıldı» / «Lightning: the poles are left alone» | Yalnız o adım durur; ekip sonraki adımın yığınını hazırlar |
| `material` | «Malzeme bekliyor: {list}» / «Waiting for materials: {list}» | Adım başlamaz |
| `master` | «Usta gerek: {role}» / «A master is needed: {role}» | Ham pay (`rawRole`) işlemez; parça gelince ya da usta ekibe girince sürer |
| `far` | «Malzeme uzakta» / «The materials are far away» | 150 m ötesi |
| `crew` | «Ekip yok» / «No crew» | Önder kuralı |
| `dark` | «Karanlık: meşale yok» / «Dark: no torches» | Oran ×0,4 ya da ×0,7, durmaz |
| `rest` | «Gece dinleniyorlar» / «Resting for the night» | Gece emri |
| `story` | «Tündük kaldırılmayı bekliyor» / «The crown waits to be raised» | Senaryo kapısı |

**Atlama ve dönüş.** Toplu benzetim `simulate(state, dakika, ortam)` saat dilimlidir (oyun saati başına bir ortam örneği: gece, hava, ekip, öğün), her dilimde adım adım O(adım); `clock:skip` ve dünyaya dönüş (`catchUp(şimdi − lastMin)`) bunu çağırır, atlamanın saat başı olaylarını (`skipping: true`) yok sayar. Yerleşimli zonda (`spec.settlement`) atlanan saatleri yerleşimin `catchUp`'ı `sites.simulate(siteId, dk, env)` ile işler; yerleşimsiz zonda `sites.onSkip`: çift işleme yoktur (`d2/core.md` §6.1). Uzun atlamada (>24 sa) günlük adımla tümlenir. 600 dakikalık toplu benzetim 600 tek dakikalık adımla aynı sonucu verir (±1e−6 İD).

**Olaylar.** `site:placed`, `site:wait` (`{ id, reason }`, değişince), `site:crew` (`{ id, heads, W }`), `site:done`, `site:dismantled`; yapının `structure:*` olayları aynen.

**Arayüz.** HUD inşaat parçası (`ui/hud/build-status.js`): ad, adım, birim sayacı ve yeni satır; kalan süre oyun saatidir: «Ekip: 3 el · ≈3 saat» / «Crew: 3 hands · ≈3 hours»; Mete ya da Çocuk ekipteyse «Ekip: 3 el + sen» / «Crew: 3 hands + you»; bekleme nedeni varsa sürenin yerine geçer; tündüğün tek el yöntemi sürerken alt satırda «Tek el: bakanla, yavaş yavaş» / «One pair of hands: on the raising pole, slowly». Bitiş sözcüğü Defter'in yapı sayfasında ve çalışma tekerindedir, kalıp «{gün}{saat} biter» / «Done {day}{time}»: ertesi gün «yarın» / «tomorrow», ≥2 gün «{n} gün sonra» / «in {n} days»; saat 05:00–07:59 «şafakta / at dawn», 08:00–10:59 «sabah / in the morning», 11:00–13:59 «öğlende / at midday», 14:00–16:59 «ikindide / in the afternoon», 17:00–19:59 «akşam / at dusk», 20:00–23:59 «gece / at night», 00:00–04:59 «gece yarısından sonra / after midnight». Yapı listesinde emek «1 iş günü / 1 work-day» biçimindedir.

**Sözleşme** (`game/site-core.js` saf; `game/sites.js` `GameSystem` `sites`, order 61, kipler `freeroam`, `play`, `home`):

```js
export function validatePlacement(def, place, { nav, height, normalAt, nodes, structures, roads });   // → { ok, reason }
export class SiteCore { constructor(def, place, opts); stock; crew; orders; wait; contrib; lastMin;
  deliver(item, n, who);  needFor(step);  consume(step);  waitReason(env);  toJSON();  fromJSON(o); }
export class SiteSystem {
  attach(ctx);  onWorld(world, nav);
  beginPlacement(kind, { preset });  place(kind, opts);   // → ConstructionSite (SiteCore + StagedStructure)
  get(id);  list();  assign(siteId, workerIds);  release(workerId);  order(siteId, { night, priority, dismantle });
  deliver(siteId, item, n, who);  update(dt, t);  onSkip(fromMin, toMin);  catchUp(minutes);
  collectInteractions(q, out);   // Teslim Et / Deliver, Çalış / Work, Ekip / Crew, Sök / Dismantle
  toJSON();  fromJSON(o);        // world.sites (order 76)
}
// game/labour.js (saf): LABOUR, eff, crewOn, stepRate, weatherK, nightK, remaining, etaMinutes, simulate, haulTrip, haulWork, etaWords
```

**Kayıt** (`world.sites`, order 76): zon kimliğiyle anahtarlanır; şantiye kaydı sıkıdır: saplı ok ve yanık izi yazılmaz, can nicemlenir, en çok 8 yırtık, zon başına hasar ayrıntısı tavanlı; bitmiş ve sağlam yapı tek satırlık dizidir (`["yurt", x, z, rot, "done"]`); ordugâh çadırları `CampPlan` kaydıdır (`count`, `seed`, `doneAt`). Bütün zonlarda ≤20 KB; baskın sonrası en kötü durum gidiş-dönüşü `sites.test.js`'te sınanır. `world.structures` (73) senaryo yapılarını tutar; şantiyeye bağlı yapı yalnız `world.sites`'tadır; Kışlak Yeni Yurdu `world.sites.zones.hexi_winter.sites.new_yurt`'tür.

**Bütçe.** `labour.js` oranı değişimde ≤0,02 ms; uzak şantiye ≤24, kare başına ≤0,05 ms; bir oyun günlük toplu benzetim 24 şantiyede ≤0,3 ms; şantiye başına ≤8 tam `Folk`, dünyada ≤16; program eklenmez.
````


## X7. §3.1 Yurdun adımları: başlık, paragraf, tablo ve parça biçimi

**Bul:** `### 3.1 Adımlar: süre, iş gücü, malzeme, can`
**Yerine:** `### 3.1 Adımlar: emek, el, malzeme, can`

**Bul:** `` Süreler `hero` hazır ayarı, 2 usta, oranı 1 (§10.3). Malzeme ve can toplamları aşama başına `act1.md` ile birebir aynıdır. ``
**Yerine:** `Emek iş dakikasıdır (İD, §2.4): «Tek el» bir işçinin, «Ekip» iki ve daha fazla elin harcadığı emek; ikisi yalnız tündükte ayrılır. «El» baş sayısıdır, en az ve en çok. Süre ekipten çıkar (§2.4 çizelgesi); gösterim `hero` hazır ayarıdır. Adım emekleri parça biçimli standart yurdundur (K21, K24); malzeme ve can toplamları aşama başına `act1.md` ile birebir aynıdır.`

**Bul:**
```
| Adım | TR / EN | Aşama | Süre sn | Bitiş | Usta | Malzeme | Can | Pay | Sınıf |
|---|---|---|---|---|---|---|---|---|---|
| `y_site` | Zemin ve Ocak Halkası / Ground and Hearth Ring | 0 | 30 | 0:30 | 2 | 6 taş | Yıkılmaz | 0 | stone |
| `y_bosaga` | Bosağa / Door Frame | 1 | 35 | 1:05 | 2 | 3 odun, 1 demir | 40 | %9,5 | wood |
| `y_kerege` | Kerege / Lattice Walls | 2 | 70 | 2:15 | 2 | 8 odun, 2 ip | 45 | %10,7 | lattice |
| `y_bag` | Kerege Bağı / Tension Band | 2 | 20 | 2:35 | 2 | 2 ip | 15 | %3,6 | bands |
| `y_tunduk` | Tündük / Crown | 3 | 45 | 3:20 | 3 | 1 tündük (`yurt_crown`), 2 sırık (`pole`) | 50 | %11,9 | wood |
| `y_uuk` | Uuk / Roof Poles | 4 | 110 | 5:10 | 2 | 12 odun | 80 | %19,0 | wood |
| `y_liner` | İç Örtü ve Çiy / Inner Liner and Reed Screen | 5 | 45 | 5:55 | 2 | 6 saz | 40 | %9,5 | reed |
| `y_tuurduk` | Tuurduk / Felt Walls | 6 | 60 | 6:55 | 2 | 4 keçe | 70 | %16,7 | felt |
| `y_uzuk` | Üzük / Felt Roof | 6 | 70 | 8:05 | 2 | 2 keçe | 50 | %11,9 | felt |
| `y_kolan` | Kolan / Girth Ropes | 7 | 40 | 8:45 | 2 | 3 ip | 24 | %5,7 | bands |
| `y_esik` | Kapı Keçesi / Door Curtain | 7 | 15 | 9:00 | 1 | 1 ip (keçe artığı) | 6 | %1,4 | felt |
| `y_sirdak` | Şırdak / Floor Felts | 7 | 30 | 9:30 | 2 | Ambardan, sayılmaz | 0 | 0 | felt |
| `y_ocak` | Ocak Yakma / Hearth Lit | 7 | 20 | 9:50 | 1 | 1 köz | 0 | 0 | yok |
| **Toplam** | | | **590** | | | 6 taş, 23 odun, 1 demir, 8 ip, 1 tündük, 2 sırık, 6 saz, 6 keçe, 1 köz | **420** | | |
```
**Yerine:**
```
| Adım | TR / EN | Aşama | Tek el İD | Ekip İD | El | Malzeme | Can | Pay | Sınıf |
|---|---|---|---|---|---|---|---|---|---|
| `y_site` | Zemin ve Ocak Halkası / Ground and Hearth Ring | 0 | 81 | 81 | 1–8 | 6 taş | Yıkılmaz | 0 | stone |
| `y_bosaga` | Bosağa / Door Frame | 1 | 81 | 81 | 1–6 | 3 odun, 1 demir | 40 | %9,5 | wood |
| `y_kerege` | Kerege / Lattice Walls | 2 | 146 | 146 | 1–8 | 8 odun, 2 ip | 45 | %10,7 | lattice |
| `y_bag` | Kerege Bağı / Tension Band | 2 | 48 | 48 | 1–8 | 2 ip | 15 | %3,6 | bands |
| `y_tunduk` | Tündük / Crown | 3 | 171 (bakanla, ×1,6) | 107 | 2–6 | 1 tündük (`yurt_crown`), 2 sırık (`pole`) | 50 | %11,9 | wood |
| `y_uuk` | Uuk / Roof Poles | 4 | 290 | 290 | 1–8 | 12 odun | 80 | %19,0 | wood |
| `y_liner` | İç Örtü ve Çiy / Inner Liner and Reed Screen | 5 | 113 | 113 | 1–8 | 6 saz | 40 | %9,5 | reed |
| `y_tuurduk` | Tuurduk / Felt Walls | 6 | 129 | 129 | 1–8 | 4 keçe | 70 | %16,7 | felt |
| `y_uzuk` | Üzük / Felt Roof | 6 | 146 | 146 | 1–8 | 2 keçe | 50 | %11,9 | felt |
| `y_kolan` | Kolan / Girth Ropes | 7 | 113 | 113 | 1–8 | 3 ip | 24 | %5,7 | bands |
| `y_esik` | Kapı Keçesi / Door Curtain | 7 | 21 | 21 | 1–4 | 1 ip (keçe artığı) | 6 | %1,4 | felt |
| `y_sirdak` | Şırdak / Floor Felts | 7 | 81 | 81 | 1–8 | Ambardan, sayılmaz | 0 | 0 | felt |
| `y_ocak` | Ocak Yakma / Hearth Lit | 7 | 20; köz yığındaysa 6 | 20 | 1–1 | 1 köz | 0 | 0 | yok |
| **Toplam** | | | **1.440** | **1.376** | En çok 8 | 6 taş, 23 odun, 1 demir, 8 ip, 1 tündük, 2 sırık, 6 saz, 6 keçe, 1 köz | **420** | | |

**Tek el yöntemleri.** Tündük tek başına da kalkar, yavaş: «Tek el: bakanla, yavaş yavaş» / «One pair of hands: on the raising pole, slowly». Bakanlar sehpa kurar, tek işçi ayakları sırayla kaldırır: 3 hamle yerine 6 küçük hamle (`uHoist.x` 6→5→4→3→2→1→0), yalpa ×1,5; emek ×1,6. Kerege, tuurduk ve üzük tek başına aynı emekle kurulur, yalnız görünüş değişir: kerege kanadı çatal kazıkla dik tutulup komşusuna bağlanır, kazık kuşaktan sonra sökülür («Tek el: destek kazığıyla» / «One pair of hands: with a prop stake»); tuurduk panelinin üst kenarı çatal sopayla kerege başına asılır, alt kenarı kazıklanır («Tek el: kazıkla gererek» / «One pair of hands: pegged and stretched»); üzüğün çekme halatı tündüğün üstünden karşı kazığa dolanır («Tek el: halatı kazığa dolayarak» / «One pair of hands: rope round a stake»). Hareketler var olan jestlerdir (`heave`, `reach_up`, `tie`, `haul`); HUD yöntemi alt satırda yazar. Ekip çizelgesi §2.4: 1 el 60,0; 2 el 30,6; 3 el 21,7; 4 el 17,3; 6 el 13,0; 8 el 11,2 gerçek dakika.
```

**Bul:** `### 3.2 Adımlar: çarpışma, oda, görünen`
**Önüne ekle (yeni paragraf):**
```
**Parça biçimi (K24).** `y_bosaga` `parts: { door_frame: 1 }`, `rawWork: 360`; `y_kerege` `parts: { kerege_set: 1 }`, `rawWork: 720`, `rawRole: 'cr_carpenter'`; `y_uuk` `parts: { uuk_set: 1 }`, `rawWork: 480`; `y_liner` `parts: { chiy: 1 }`, `rawWork: 120` (§2.4). Tündük, sırık, keçe, ip ve köz zaten eşyadır. Parça biçimi bir düzey açılınca bu tablonun malzemesidir (54 birim, 146 Yük); `tools/econ-sim.mjs` sınar. I. Perde ve ana kampın şantiyeleri (`camp3`, Kışlak Yeni Yurdu, onarımlar, senaryo şantiyeleri) `spec.labour.rawWork: false` taşır: malzeme yontulmuş gelir, `rawWork` eklenmez, yurt 1.440 İD kalır. K21'in «1 kişi 1 gün» çapası parça biçimli standart yurdun kurulumudur.
```

## X8. §3.5 Hazır ayarlar: yerleşim yurtları

**Bul:** `` `winter` 24 uuk kullanır: `act1.md` §8.5 "24 sırık". ``
**Sonrasına ekle:**
```
**Yerleşim yurtları (K23, `settlement.md` §7).** Hepsi yurt gövdelidir; yakında `winter`, uzakta `YurtField` (§13.6). Fark iç tasarım, son adım ve emektir (§4.6 emek tablosu).

| Kullanım | `kind` | İç (`designFor`) | Adım farkı | Emek, tek el |
|---|---|---|---|---|
| Hane yurdu | `yurt` | `otaci` ya da `bolmeli` (tohumla) | Yok | 1.440 İD (1 İG) |
| Tanhu Otağı | `otag` | `han` (bugün kullanılmayan tasarım, §13.5) | `scale: 1.4`, `hero`; kapı doğuya; 10–12 kanat | 3.600 İD (2,5 İG); adımlar ×2,5, el sınırları ×1,5, `crewMax: 12` |
| Ambar Yurdu | `store_yurt` | `bolmeli` + çuval yığını | `y_ocak` yok (`hearth: false`) | 1.420 İD |
| Elçi Yurdu | `envoy_yurt` | `otag` | Yok | 1.440 İD |
| Otacı Yurdu | `healer_yurt` | `otaci` | Yok | 1.440 İD |
| Buyruk Yurdu | `cmd_yurt` | `silah` | Yok | 1.440 İD |
| Silahlık, Okçu Yurdu | `armoury`, `fletchery` | `silah` + raf ya da tezgâh | `y_ocak` yok; sonuna `y_raf` Raflar / Racks: aşama 7, `wood`, can 10, emek 308 İD, el 1–4 | 1.728 İD (1,2 İG) |
| Erzak Ambarı | `supply_depot` | `bolmeli` | `y_ocak` yok; sonuna `y_seki` Yük Sekisi / Loading Platform: aşama 7, `wood`, can 20, kapı yanında 6 × 4 m, emek 740 İD, el 1–8 | 2.160 İD (1,5 İG) |

**`scale`.** `def.scale` (varsayılan 1) kök ölçeğini, `bounds`'u, nav şekillerini (`navShapes`), oda sınırını (`Room.floorAt`) ve pedi birlikte çarpar; birim canı `scale²` ile çarpılır, yukarı yuvarlanır (Otağ 420 → 824). Program değişmez: ölçek köke uygulanır, köşe etiketleri aynıdır.
```

## X9. §4.1 Ahır, tablo

**Bul:**
```
| Adım | TR / EN | Aşama | Süre | Usta | Malzeme | Can, sınıf, birim | Çarpışma | Oda | Görünen, üçgen |
|---|---|---|---|---|---|---|---|---|---|
| `st_site` | Zemin ve Oluk / Ground and Trough | 0 | 25 | 2 | 4 taş | Yıkılmaz | Yok | Yok | Saman izli zemin, 8 yuva, stok |
| `st_posts` | Direk / Posts | 1 | 60 | 2 | 6 odun | 60, wood, 4 sütun çifti × 15 | 8 `circle(0.13)` (`camp.js:527-532`) | Yok | 8 direk, 8 payanda; 1.200 |
| `st_walls` | Bölme ve Duvar / Stalls and Walls | 2 | 90 | 2 | 6 odun, 4 ip | 60: arka 30, yan 14 wood; `rails` 2 × 8 bands | 2 `rect` (`camp.js:525-526`), 2 `rect(top -1.1)` (`camp.js:534-535`) | Yemlik, eyer, fener; atlar bağlanır | 26 arka, 9 yan tahta 3.780; korkuluk 480; fener 330; iç eşya 9.440 |
| `st_beams` | Kiriş / Beams | 3 | 70 | 2 | 6 odun | 30, wood, 4 × 7,5 | Değişmez | Yok | 2 saçak, mahya kirişi, 8 mertek, 4 bağ; 1.104 |
| `st_roof` | Çatı / Roof | 4 | 135 | 2 | Canlı kamp 14 odun; Kışlak 10 saz, 3 keçe | 20, canlı `wood`, Kışlak `reed`; 6 dilim | Değişmez | `room.enabled`: kesit açılır | 496 tahta sıra sıra saçaktan mahyaya, mahya tahtası; 6.252 |
| **Toplam** | | | **380** | | | **170** | | | **12.816 + 9.770** |
```
**Yerine:**
```
| Adım | TR / EN | Aşama | Ekip İD | El | Malzeme | Can, sınıf, birim | Çarpışma | Oda | Görünen, üçgen |
|---|---|---|---|---|---|---|---|---|---|
| `st_site` | Zemin ve Oluk / Ground and Trough | 0 | 140 | 1–6 | 4 taş | Yıkılmaz | Yok | Yok | Saman izli zemin, 8 yuva, stok |
| `st_posts` | Direk / Posts | 1 | 340 | 1–4 | 6 odun | 60, wood, 4 sütun çifti × 15 | 8 `circle(0.13)` (`camp.js:527-532`) | Yok | 8 direk, 8 payanda; 1.200 |
| `st_walls` | Bölme ve Duvar / Stalls and Walls | 2 | 510 | 1–6 | 6 odun, 4 ip | 60: arka 30, yan 14 wood; `rails` 2 × 8 bands | 2 `rect` (`camp.js:525-526`), 2 `rect(top -1.1)` (`camp.js:534-535`) | Yemlik, eyer, fener; atlar bağlanır | 26 arka, 9 yan tahta 3.780; korkuluk 480; fener 330; iç eşya 9.440 |
| `st_beams` | Kiriş / Beams | 3 | 270; tek el ×1,5 | 2–4 | 6 odun | 30, wood, 4 × 7,5 | Değişmez | Yok | 2 saçak, mahya kirişi, 8 mertek, 4 bağ; 1.104 |
| `st_roof` | Çatı / Roof | 4 | 765 | 1–6 | Canlı kamp 14 odun; Kışlak 10 saz, 3 keçe | 20, canlı `wood`, Kışlak `reed`; 6 dilim | Değişmez | `room.enabled`: kesit açılır | 496 tahta sıra sıra saçaktan mahyaya, mahya tahtası; 6.252 |
| **Toplam** | | | **2.025; tek el 2.160 = 1,5 iş günü** | En çok 6 | | **170** | | | **12.816 + 9.770** |

Zanaat `wood` (`craft: 'wood'`, `crewMax: 6`): ağaç ustası yoksa oran ×0,7 (§2.4). Tek başına 90,0, iki elle 44,4, dört elle 24,5, altı elle 20,0 gerçek dakika. Direk çukuru, tahta duvar ve çatı yerinde biçilir: ahır yurttan ağırdır, çünkü yurt hazır parçayla kurulur.
```

## X10. §4.2 Çit, tablo

**Bul:**
```
| Adım | TR / EN | Aşama | Süre | Usta | Malzeme | Can, sınıf | Çarpışma | Görünen |
|---|---|---|---|---|---|---|---|---|
| `f_stakes` | Kazıklar / Stakes | 0 | 6 sn/m | 1 | 4 odun / 10 m | Yıkılmaz (kırık kütük) | Yok | Kazıklar sırayla çakılır; 48 üçgen/kazık |
| `f_rails` | Kuşaklar / Rails | 1 | 3 sn/m | 1 | 2 odun, 2 ip / 10 m | 20 / 2 m, wood | `capsule(r 0.1, top -0.95)`, üstünden atlanır | 2 kuşak kip 5 |
```
**Yerine:**
```
| Adım | TR / EN | Aşama | Ekip İD | El | Malzeme | Can, sınıf | Çarpışma | Görünen |
|---|---|---|---|---|---|---|---|---|
| `f_stakes` | Kazıklar / Stakes | 0 | 7,2 / m | 1; 2 m'lik parça başına bir el, en çok 8 | 4 odun / 10 m | Yıkılmaz (kırık kütük) | Yok | Kazıklar sırayla çakılır; 48 üçgen/kazık |
| `f_rails` | Kuşaklar / Rails | 1 | 3,6 / m | Aynı | 2 odun, 2 ip / 10 m | 20 / 2 m, wood | `capsule(r 0.1, top -0.95)`, üstünden atlanır | 2 kuşak kip 5 |

10 m çit tek el 108 İD (0,075 iş günü): tek başına 4,5, beş elle 1,1 gerçek dakika. Zanaat `home`.
```

## X11. §4.3 Ağıl, tablo

**Bul:**
```
| Adım | TR / EN | Aşama | Süre | Usta | Malzeme | Can, sınıf | Çarpışma | Oda, işlev | Görünen |
|---|---|---|---|---|---|---|---|---|---|
| `p_line` | Kazık Hattı / Stake Line | 0 | 12 sn / 10 m | 1 | 1 odun / 5 m | Yıkılmaz | Yok | Hayvan tutmaz | Köşe kazıkları, ip |
| `p_wattle` | Örgü Çit / Wattle Fence | 1 | 8 sn / pano | 2 | 1 odun / pano | 20 / pano, wood | `capsule(r 0.1, top -1.1)` pano başına | Kapalı döngü: yeniden etiket (§12.4) | 2,2 m pano 64 üçgen |
| `p_gate` | Kapı / Gate | 1 | 20 | 2 | 2 odun, 1 ip | 20, wood | `open` ise silinir | `gate.toggle()`; E ya da at | 3,2 m kanat |
```
**Yerine:**
```
| Adım | TR / EN | Aşama | Ekip İD | El | Malzeme | Can, sınıf | Çarpışma | Oda, işlev | Görünen |
|---|---|---|---|---|---|---|---|---|---|
| `p_line` | Kazık Hattı / Stake Line | 0 | 1,5 / m | 1; 5 m başına bir el, en çok 8 | 1 odun / 5 m | Yıkılmaz | Yok | Hayvan tutmaz | Köşe kazıkları, ip |
| `p_wattle` | Örgü Çit / Wattle Fence | 1 | 20 / pano | 1; pano başına bir el, en çok 8 | 1 odun / pano | 20 / pano, wood | `capsule(r 0.1, top -1.1)` pano başına | Kapalı döngü: yeniden etiket (§12.4) | 2,2 m pano 64 üçgen |
| `p_gate` | Kapı / Gate | 1 | 40; tek el ×1,25 | 2–2 | 2 odun, 1 ip | 20, wood | `open` ise silinir | `gate.toggle()`; E ya da at | 3,2 m kanat |

Adak Ağılı (148 m, 66 pano, kapı): tek el 1.592 İD (1,1 iş günü); tek başına 66,3, dört elle 19,6, altı elle 14,6, sekiz elle 12,2 gerçek dakika. Yerleşimin 40 m'lik ağılı ≈470 İD (0,32 iş günü). Zanaat `home`.
```

## X12. §4.4 Araba: tablo, I. Perde paragrafı, onarım

**Bul:**
```
| Adım | TR / EN | Süre | Usta | Malzeme (`economy.md` §6.4 toplamı) | Birim can, sınıf | Çarpışma | Binek | Görünen, üçgen |
|---|---|---|---|---|---|---|---|---|
| `c_axle` | Dingil ve Teker / Axle and Wheels | 60 | 2 | 3 odun, 1 `iron_bar` | `c_wheels` 2 × 8, `c_axle` 8; wood | `circle(r 1.6)` | Yok | 2 teker (`InstancedMesh`), dingil; 1.112 + kasadan pay |
| `c_bed` | Kasa / Cart Bed | 45 | 2 | 2 odun | 12, wood | Değişmez | Yük 40 | Taban, yan tahta, sürücü sandığı, yük; 1.564 |
| `c_hoops` | Çember / Hoops | 30 | 1 | 1 odun | 4, lattice | Değişmez | Yok | 3 kaburga; çatının içinde |
| `c_tilt` | Keçe Çatı / Felt Tilt | 30 | 2 | 2 keçe | 6, felt | Değişmez | Yolcu korunur | Yarım silindir, 2 kapak; 568 |
| `c_yoke` | Koşum / Harness | 20 | 1 | 2 odun, 2 ip | 4, bands | Değişmez | **4 yolcu + sürücü, aşama 1** | Oklar, göğüs kayışı, kolan, dizgin; 416 at ağında |
| **Toplam** | | **185** | | 8 odun, 1 `iron_bar`, 2 keçe, 2 ip | **50** | | | |
```
**Yerine:**
```
| Adım | TR / EN | Ekip İD | El | Malzeme (`economy.md` §6.4 toplamı) | Birim can, sınıf | Çarpışma | Binek | Görünen, üçgen |
|---|---|---|---|---|---|---|---|---|
| `c_axle` | Dingil ve Teker / Axle and Wheels | 110; tek el ×1,5 | 2–4 | 3 odun, 1 `iron_bar` | `c_wheels` 2 × 8, `c_axle` 8; wood | `circle(r 1.6)` | Yok | 2 teker (`InstancedMesh`), dingil; 1.112 + kasadan pay |
| `c_bed` | Kasa / Cart Bed | 120 | 1–4 | 2 odun | 12, wood | Değişmez | Yük 40 | Taban, yan tahta, sürücü sandığı, yük; 1.564 |
| `c_hoops` | Çember / Hoops | 40 | 1–2 | 1 odun | 4, lattice | Değişmez | Yok | 3 kaburga; çatının içinde |
| `c_tilt` | Keçe Çatı / Felt Tilt | 60; tek el ×1,25 | 2–4 | 2 keçe | 6, felt | Değişmez | Yolcu korunur | Yarım silindir, 2 kapak; 568 |
| `c_yoke` | Koşum / Harness | 32 | 1–2 | 2 odun, 2 ip | 4, bands | Değişmez | **4 yolcu + sürücü, aşama 1** | Oklar, göğüs kayışı, kolan, dizgin; 416 at ağında |
| **Toplam** | | **362; tek el 432 = 0,3 iş günü** | En çok 4 | 8 odun, 1 `iron_bar`, 2 keçe, 2 ip | **50** | | | |

Zanaat `wood`: tekerlek ve dingil zanaattır (K24), şantiyede yalnız birleştirme yapılır. Tek başına 18,0, iki elle 7,9, dört elle 5,1 gerçek dakika.
```

**Bul:** `**Act 1.** Araba kurulmaz, yalnız kırılır ve onarılır: `uStage` 0/1 (`travel.md` §3.3 "Kırık aşama"). Yeni araba kurmak II. Perde'dir.`
**Yerine:** `` **Act 1.** Araba kurulmaz, yalnız kırılır ve onarılır: `uStage` 0/1 (`travel.md` §3.3 "Kırık aşama"). Yeni araba kurmak II. Perde'dir. O zaman `c_axle` `parts: { wheel_pair: 1, 'tag:wood': 1, iron_bar: 1 }`, `rawWork: 600`, `rawRole: 'cr_cartwright'` (yoksa `cr_carpenter`): teker çifti Ağaç Atölyesi'nin usta işidir (`economy.md` §6.10 `rc_wheel_pair`); iki teker sert odundansa (`tag:wood_hard`) araba canı +%25. Büyük arabaların malzemesi `economy.md` §6.12, emeği §4.6. ``

**Bul:** `Sıradan onarım 1 odun, 1 ip, 25 sn;`
**Yerine:** `` Sıradan onarım 1 odun, 1 ip; emek 29 İD (teker kaldırma, `c_wheels` 8/24 can × 110 × 0,8; §7): Mete ve sürücüyle ≈39 sn, `repair` ile ≈19 sn; ``

## X13. §4.5 Kısa liste: emek sütunu ve hava

**Bul:**
```
| `kind` | Aşama | Adımlar TR / EN | Can, sınıf | Kullanım |
|---|---|---|---|---|
| `tent` | 3 | Kazık / Stakes, Direk ve İp / Poles and Ropes, Örtü / Cover | —, 30 wood, 50 felt | Çiang çadırı; T1'de ip kesilir; `rope_cutter` tek vuruşta aşama düşürür |
| `hut` | 4 | Zemin / Ground, Çatkı / Frame, Kamış Duvar / Reed Walls, Saz Çatı / Thatch Roof | —, 30 wood, 25 reed, 25 reed | Sazlık kulübeleri, 4 adet |
| `shed` | 5 | Ayak / Footing, Direk / Posts, Kiriş / Beams, Dallık / Brush Layer, Örtü / Thatch | —, 40 wood, 40 wood, 30 reed, 20 reed | Yukarı Ağıllar; yanık aşama, kor ışığı |
| `granary` | 5 | `shed` ile aynı | —, 40, 40, 30, 20; `hay` içerik yanığı +30 sn | Tahıl Ambarı; `grain` hedefi: çatıyı kes |
| `tower` | 4 | Ayak / Base, Çapraz / Braces, Platform / Platform, Korkuluk / Rail | —, 80, 60, 40 wood | Kule |
| `tower_gate` | 4 | `tower` ile aynı | —, 10, 10, 10 wood | Boğaz kuleleri, senaryo yapısı (`progression.md` §16): Farnak'ın oku 2 hasarla ≈15 ok |
| `bridge` | 6 | Ayak / Footing, Kazık / Piles, Kiriş / Stringers, Döşeme / Deck, Bağ / Lashings, Korkuluk / Rails | —, 40, 40, 40 wood, 30 bands, 30 wood | Eski Köprü: `sq_old_bridge` 2→5, `cut()` 3 sn → 2; `stage` `bridge_stage` bayrağına yazılır (`travel.md` e09) |
| `rack` | 2 | Kırık / Broken, Raf / Rack | —, 10 wood | 400 üçgen, instanced. Kurutma rafı; `horse_chest` kırar, `BOGGED` |
| `road_bone` | 2 | Kırık Direk / Broken Pole, Öten Direk / Singing Pole | —, 15 wood | 500 üçgen, instanced. RB01–RB14; onarım `act1.md` §4 |
```
**Yerine:**
```
| `kind` | Aşama | Adımlar TR / EN | Can, sınıf | Emek: tek el İD (iş günü); adımların ekip İD'si; el | Kullanım |
|---|---|---|---|---|---|
| `tent` | 3 | Kazık / Stakes, Direk ve İp / Poles and Ropes, Örtü / Cover | —, 30 wood, 50 felt | 216 (0,15); 36, 60 (2 el, tek el ×1,2), 90 (2 el, ×1,2); en çok 4, `home` | Çiang çadırı; T1'de ip kesilir; `rope_cutter` tek vuruşta aşama düşürür; fırtınada bağsızsa hava bölümü başına %25 olasılıkla örtü bir aşama düşer, Bağla / Tie Down kalıcıdır (§6.5) |
| `hut` | 4 | Zemin / Ground, Çatkı / Frame, Kamış Duvar / Reed Walls, Saz Çatı / Thatch Roof | —, 30 wood, 25 reed, 25 reed | 720 (0,5); 60, 176 (2 el, ×1,25), 240, 200; en çok 4, `home` | Sazlık kulübeleri, 4 adet |
| `shed` | 5 | Ayak / Footing, Direk / Posts, Kiriş / Beams, Dallık / Brush Layer, Örtü / Thatch | —, 40 wood, 40 wood, 30 reed, 20 reed | 864 (0,6); 60, 180, 132 (2 el, ×1,5), 200, 226; en çok 4, `wood` | Yukarı Ağıllar; yanık aşama, kor ışığı |
| `granary` | 5 | `shed` ile aynı | —, 40, 40, 30, 20; `hay` içerik yanığı +30 sn | 1.152 (0,8); 80, 240, 176 (2 el, ×1,5; en çok 4), 266, 302; en çok 6, `wood` | Tahıl Ambarı; `grain` hedefi: çatıyı kes |
| `tower` | 4 | Ayak / Base, Çapraz / Braces, Platform / Platform, Korkuluk / Rail | —, 80, 60, 40 wood | 2.160 (1,5); 300, 440 (2 el, ×1,5), 528 (2 el, ×1,25), 540; ayak en çok 6, üst adımlar 4, `wood` | Kule |
| `tower_gate` | 4 | `tower` ile aynı | —, 10, 10, 10 wood | 2.160 (1,5); senaryo yapısı, oyuncu kurmaz; yalnız onarım formülü için | Boğaz kuleleri, senaryo yapısı (`progression.md` §16): Farnak'ın oku 2 hasarla ≈15 ok |
| `bridge` | 6 | Ayak / Footing, Kazık / Piles, Kiriş / Stringers, Döşeme / Deck, Bağ / Lashings, Korkuluk / Rails | —, 40, 40, 40 wood, 30 bands, 30 wood | 2.880 (2); 360, 480 (2 el, ×1,5), 400 (2 el, ×1,5), 480, 300, 420; döşeme en çok 8, ötekiler 6, `wood` | Eski Köprü: `sq_old_bridge` 2→5, `cut()` 3 sn → 2; `stage` `bridge_stage` bayrağına yazılır (`travel.md` e09); 2→5 1.200 İD: Sazlık'ın 6 eli malzeme gelince ≈4,5 oyun saatinde (≈11 gerçek dk) kurar |
| `rack` | 2 | Kırık / Broken, Raf / Rack | —, 10 wood | 3,2: basılı tutma 8 sn (`rc_rack`) | 400 üçgen, instanced. Kurutma rafı; `horse_chest` kırar, `BOGGED`; kurutma ilerlemesi havanın kurutma çarpanıyla, dolu içindekini bozar, fırtınada bağsızsa içindekinin %20'si düşer (§6.5, `weather.md` §8.5) |
| `road_bone` | 2 | Kırık Direk / Broken Pole, Öten Direk / Singing Pole | —, 15 wood | 8: basılı tutma 20 sn (`rp_road_bone`) | 500 üçgen, instanced. RB01–RB14; onarım `act1.md` §4 |

Gerçek dakika (usta var, gündüz, açık hava): çadır 9,0 / 4,1 / 2,3 (1 / 2 / 4 el); kulübe 30,0 / 14,8 / 8,2; sundurma 36,0 / 17,5 / 9,7; tahıl ambarı 48,0 / 23,3 / 12,9, altı elle 10,0; kule 90,0 / 39,6 / 21,9; köprü 120,0 / 53,5 / 29,6, sekiz elle 20,9. Adım emekleri ve el sınırlarının makine okunur kopyası `d2/labour-model.json` v2'nin `defs` ve `settlement` bloklarıdır (2026-11-03, bu belgeyle aynı); `econ-model.json` ve `settlement-model.json` `labourWd` ve `crewMax` alanlarını oradan okur. **Basılı tutma kuralı:** emeği ≤12 İD olan yerleştirilebilir (raf, direk onarımı, kamp ateşi, fener direği) şantiye açmaz; oyuncunun basılı tutması emeğin kendisidir (1 gerçek sn = 0,4 İD).
```

## X14. Yeni §4.6 Yerleşim ve ordugâh yapıları (K23)

**Bul:** `## 5. Hasar`
**Önüne ekle:**
```
### 4.6 Yerleşim ve ordugâh yapıları (K23)

Ad, işlev, kademe, kapasite ve bakım `settlement.md` §7; malzeme `economy.md` §6.12; emek yasası §2.4. Bu bölüm adımları, canı, sınıfı, görünümü ve emeği verir; yurt gövdeli türler §3.5'tedir. Bütün yeni türler `simple()` ile ya da kendi adım listesiyle `STRUCTURE_DEFS`'e girer; görünüm aileleri `core/geo.js` ile kodla kurulur, köşe renklidir, `struct_parts` ve `struct_props` programlarını kullanır (yeni program yok). Hepsi ≤6k üçgen, ≤2 çizim (`act1.md` §9.3 küçük yapı sınırı); çok sayıda olanlar örneklidir. `—` yıkılmaz aşama 0.

**Görünüm aileleri.**

| Aile | Türler | Ağ | Etiket |
|---|---|---|---|
| `yard` | `felt_yard`, `tannery`, `barter_ground`, `training_ground` | Düzlük çıkartması (ped deseni, `PadField`), köşe direkleri (`beam`), alçak çit, tür donanımı | Grup başına donanım, kip 0 (yerden yükselir) |
| `mound` | `grain_pit`, `kiln`, `smithy` ocağı, `pit_house`, `rampart` | Kazı çukuru (`lathe` iç yüz), toprak sırtı (`surf`), kapak ya da çatı | Kip 0; sur parçası örnekli |
| `ring` | `well`, `sky_pole`, `gathering_ground` | Taş halka (`blob` örnekli), direk, oturak ya da çıkrık | Kip 0; direk kip 3 (yükselir) |
| `post` | `banner_pole`, `lantern_post` | Direk, flama ya da fener; fener sahte ışık (`fxGlow`, köşe rengi >1) | Örnekli, zon başına 1 çizim |
| `field` | `field` | Sürülmüş toprak çıkartması + örnekli sap demeti; `uGrow` 0..1 takvimden | 1 çizim, ≤4k |

**Var olan türlerin yeni hazır ayarları.**

| Tür | Hazır ayar | Değişiklik | Kullanan |
|---|---|---|---|
| `shed` | `open` | Duvarsız, saz dam (bugünkü `shed`'in açık hâli) | `shed`, `wood_shop` (+ tezgâh props, aşama 4) |
| `shed` | `walled` | Tahta duvar (aşama 2'ye eklenir), keçe dam, tunç kilit birimi | `treasury` |
| `tower` | `low` | 4 m platform, korkuluk yerine merdiven | `outpost` |
| `tower` | `gate` | İki direk, iki kanat (`door` birimi açılır ve kapanır), üst geçit | `rampart_gate` |
| `tower` | `granary` | Platformda tahta duvarlı ambar, saz dam, h 9 m | `granary_tower` |
| `tower` | (var) | Değişmez, `crewMax: 4` | `watch_tower` |
| `fence` | `picket` | 5 m'de bir direk, tek ip; atlar örnekli bağlı | `horse_line` |
| `fence` | `stockade` | 2,5 m sivri kazık, sık | `palisade` |
| `tent` | (var) | `TentField` uzak örneği | Ordugâh |

**Adımlar.**

| `kind` | Aşamalar TR / EN | Can, sınıf | Not |
|---|---|---|---|
| `felt_yard` | Zemin / Ground, Direk ve Çit / Posts and Fence, Germe Çerçevesi / Stretching Frames, Döğme Hasırı ve Çiy / Beating Mats and Reed Screen | —, 20 wood, 15 wood, 10 reed | Çiy rüzgârlık; yağmurda hasır ıslak işaretlenir (K22) |
| `tannery` | Çukur ve Tekne / Pits and Vats, Sergi / Drying Frames, Gölgelik / Awning | —, 15 wood, 10 reed | |
| `wood_shop` | `shed` `open` adımları; tezgâh aşama 4'te | `shed` canları | |
| `smithy` | Ocak Çukuru / Furnace Pit, Kil Ocak / Clay Furnace, Körük / Bellows, Sundurma / Shelter | —, 40 stone, 10 bands, 20 reed | Çalışırken kor parıltısı `fxGlow`; yeri rüzgâraltı kuralıyla (`settlement.md` §13.2) |
| `kiln` | Çukur / Pit, Toprak Kubbe / Earth Dome, Baca ve Ağız / Vent and Mouth | —, 40 stone, 10 stone | Çalışırken duman `fxSmoke` (havuzdan) |
| `grain_pit` | Çukur / Pit, Kapak / Lid | —, 10 wood | Gizli: baskında %50 olasılıkla bulunur, bulunursa içeriğin %30'u gider; yanmaz (`economy.md` §4.5) |
| `well` | Kazı / Dig, Taş Bilezik / Stone Collar, Çıkrık / Windlass | —, 40 stone, 15 wood | Kazı tek ağızdan: el en çok 3 |
| `field` | Sürüm / Ploughing, Ekin / Crop | —, 20 reed (olgunken) | Ekin takvimle büyür (bahar ekim, güz biçim); dolu −%30–60; olgun tarla tutuşur |
| `pit_house` | Çukur / Pit, Direk / Posts, Çatı / Roof Frame, Örtü / Cover | —, 40 wood, 40 wood, 30 reed | `Room` aşama 3'te |
| `rampart` (10 m) | Hendek / Ditch, Toprak Sur / Earth Bank | —, 80 stone | Kütük duvar aşama 1'in son %20'si; örnekli parça ≤1,2k üçgen; ateş işlemez |
| `granary_tower` | Ayak / Base, Direk / Posts, Döşeme / Floor, Duvar / Walls, Dam / Roof | —, 60 wood, 40 wood, 40 wood, 30 reed | `tall`: yıldırım adayı |
| `watch_tower` | `tower` adımları | `tower` canları | `tall`: yıldırım adayı; görüş 300 m |
| `horse_line` (20 m) | Kazık / Stakes, İp / Line | —, 6 bands | İp kesilince atlar dağılır (`breach`) |
| `palisade` (10 m) | `fence` `stockade` adımları | `fence` canları | Sefer ordugâhının çevresi |
| `training_ground` | Açma / Clearing, Hedef Direkleri / Target Posts, At Yolu / Riding Course | —, 12 wood, 8 wood | 6 hedef; ok saplanır (`ARROW_STICK` `wood`) |
| `sky_pole` | Taş Halka / Stone Ring, Direk / Pole, Flama ve Sunu Taşı / Streamers and Offering Stone | —, 30 wood, 10 felt | Direk 12 m, `tall`; yıldırımda flama kuruysa `ignite({ power: 30 })`, ıslaksa yalnız yanık izi; alamet `settlement.md` §12.4 |
| `gathering_ground` | Düzlük / Levelled Ground, Oturak Halkası / Felt Seats, Sancaklar / Banners | —, 30 felt, 20 wood | Oturaklar örnekli (120), r 18 |
| `barter_ground` | Düzlük / Ground, Direk / Posts, Gölgelik / Awnings | —, 20 wood, 15 felt | 4 gölgelik, at bağlama |
| `banner_pole` | Çukur / Hole, Direk / Pole, Flama / Streamer | —, 20 wood, 5 felt | Direk 10 m, `tall`: yıldırım adayı (`weather.md` §8.7); örnekli |
| `lantern_post` | Çukur / Hole, Direk / Pole | —, 10 wood | Basılı tutma; fener `fxGlow`; örnekli |
| `outpost` | `tent` + `tower` `low` (ikili yerleşim): Ayak / Base, Çapraz / Braces, Platform / Platform, Merdiven / Ladder | `tent` canları; `tower` `low` —, 30, 20, 15 wood | Görüş 400 m |
| `rampart_gate` | Ayak / Base, Direk / Posts, Kanatlar / Gate Leaves, Geçit / Walkway | —, 60 wood, 40 wood, 30 wood | `door` birimi açık ya da kapalı nav damgası |
| `treasury` | `shed` `walled`: Ayak / Footing, Direk / Posts, Duvar / Walls, Dam / Roof, Kilit / Lock | —, 40 wood, 60 wood, 30 felt, 20 metal | Kilit düşmeden Hazine kabı açılmaz (baskın) |

**Emek** (usta var, gündüz, açık hava; iki ellik adımda en az 2 el, tek el çarpanı parantezde).

| `kind` | Zanaat | Tek el İD (İG) | Adımların ekip İD'si | El en çok | Gerçek dk: 1 / 2 / 4 / en çok el |
|---|---|---|---|---|---|
| `otag` | home | 3.600 (2,5) | Yurdun 13 adımı ×2,5: 203, 203, 365, 120, 268 (×1,6), 725, 283, 323, 365, 283, 53, 203, 50 | 12 (bosağa ve tündük 9, eşik 6, ocak 1) | 150,0 / 76,4 / 43,2 / 22,4 |
| `store_yurt` | home | 1.420 (0,99) | Yurdun ilk 12 adımı | 8 | 59,2 / 29,7 / 16,4 / 10,3 |
| `cmd_yurt`, `envoy_yurt`, `healer_yurt` | home | 1.440 (1) | Yurt (§3.1) | 8 | 60,0 / 30,6 / 17,3 / 11,2 |
| `armoury`, `fletchery` | home | 1.728 (1,2) | Yurdun ilk 12 adımı + `y_raf` 308 (el 4) | 8 | 72,0 / 36,5 / 20,2 / 14,0 |
| `supply_depot` | home | 2.160 (1,5) | Yurdun ilk 12 adımı + `y_seki` 740 | 8 | 90,0 / 46,0 / 25,4 / 15,7 |
| `felt_yard` | home | 720 (0,5) | 144, 216, 216, 144 | 6 | 30,0 / 15,8 / 8,7 / 6,4 |
| `tannery` | home | 576 (0,4) | 173, 230, 173 | 4 | 24,0 / 12,6 / 7,0 / 7,0 |
| `wood_shop` | wood | 1.152 (0,8) | 80, 240, 176 (×1,5; el 4), 266, 302 | 6 | 48,0 / 23,3 / 12,9 / 10,0 |
| `smithy` | earth | 2.160 (1,5) | 540, 756, 432, 432 | 6 | 90,0 / 47,4 / 26,2 / 19,2 |
| `kiln` | earth | 864 (0,6) | 259, 432, 173 | 4 | 36,0 / 18,9 / 10,5 / 10,5 |
| `grain_pit` | earth | 432 (0,3) | 302, 130 | 4 | 18,0 / 9,5 / 5,2 / 5,2 |
| `well` | earth | 1.440 (1) | 864, 432, 144 | 3 | 60,0 / 31,6 / – / 22,1 |
| `field` | earth | 720 (0,5), tarla başına | 432, 288 | 6 | 30,0 / 15,8 / 8,7 / 6,4 |
| `pit_house` | earth | 2.880 (2) | 1.008, 576, 480 (×1,5), 576 | 6 | 120,0 / 57,9 / 32,0 / 23,5 |
| `rampart` (10 m) | earth | 720 (0,5) | 324, 396 | 8 | 30,0 / 15,8 / 8,7 / 5,3 |
| `granary_tower` | wood | 2.880 (2) | 432, 480 (×1,5), 576 (×1,25), 576, 432 | 6 | 120,0 / 54,7 / 30,2 / 22,2 |
| `watch_tower` | wood | 2.160 (1,5) | `tower`: 300, 440 (×1,5), 528 (×1,25), 540 | 4 | 90,0 / 39,6 / 21,9 / 21,9 |
| `treasury` | wood | 1.728 (1,2) | 173, 432, 518, 432, 173 | 6 | 72,0 / 37,9 / 20,9 / 15,4 |
| `rampart_gate` | wood | 2.160 (1,5) | 432, 432 (×1,5), 518 (×1,25), 432 | 6 | 90,0 / 39,8 / 22,0 / 16,1 |
| `palisade` (10 m) | wood | 144 (0,1) | Kazık 9,6 / m, kuşak 4,8 / m | 2 m'ye bir el, en çok 8 | 6,0 / 3,2 / 1,7 / 1,5 (5 el) |
| `horse_line` (20 m) | home | 115 (0,08) | 69, 46 | 4 | 4,8 / 2,5 / 1,4 / 1,4 |
| `training_ground` | home | 864 (0,6) | 432, 259, 173 | 8 | 36,0 / 18,9 / 10,5 / 6,3 |
| `gathering_ground` | home | 576 (0,4) | 230, 230, 115 | 8 | 24,0 / 12,6 / 7,0 / 4,2 |
| `barter_ground` | home | 720 (0,5) | 216, 288, 216 | 6 | 30,0 / 15,8 / 8,7 / 6,4 |
| `sky_pole` | wood | 864 (0,6) | 432, 202 (×1,5), 130 | 6 | 36,0 / 16,7 / 9,2 / 6,8 |
| `outpost` | home (çadır), wood (kule) | 576 (0,4) | Çadır 36, 60 (×1,2), 90 (×1,2); kule `low` 60, 80 (×1,5), 96 (×1,25), 60 | 4 | 24,0 / 10,6 / 5,8 / 5,8 |
| `banner_pole` | home | 40 (0,03) | 8, 16 (×1,5), 8 | 2 (uzun direk) | 1,7 / 0,7 / – / 0,7 |
| `lantern_post` | home | 10 | Basılı tutma 25 sn (§4.5 kuralı) | 1 | – |
| `cart_felt` | wood | 576 (0,4) | `cart` adımları ×4/3: 147 (×1,5), 160, 53, 80 (×1,25), 43 | 4 | 24,0 / 10,6 / 6,8 / 6,8 |
| `cart_high` | wood | 864 (0,6) | ×2: 220 (×1,5), 240, 80, 120 (×1,25), 64 | 4 | 36,0 / 15,9 / 10,2 / 10,2 |
| `cart_war` | wood | 1.440 (1) | ×10/3: 367 (×1,5), 400, 133, 200 (×1,25), 107 | 6 | 60,0 / 26,5 / 15,4 / 12,3 |
| `wagon_felt` | wood | 1.728 (1,2) | ×4: 440 (×1,5), 480, 160, 240 (×1,25), 128 | 6 | 72,0 / 31,8 / 18,5 / 14,7 |

Sayılar `settlement.md` §7'nin İG sütunuyla aynıdır; † önerileri burada kesinleşir. `econ-model.json` ve `settlement-model.json` `labourWd` ve `crewMax` alanlarını bu tablodan ve §4.5'ten kopyalar (bugünkü `econ-model.json` `crewMax` sütununda `tent` 3, `hut` 3, `fence` 2, `pen` 4, `granary` 4, `tower` 4, `bridge` 6, `rack` 2, `cart` 3, `cart_felt` 3 eskidir; doğrusu 4, 4, 10 m'de 5, 40 m'de 8, 6, 6, 8, 1, 4, 4). Ham malla kurulursa yurt gövdelilere §2.4'ün `rawWork`'ü eklenir; otağda parça sayısınca 3.000 İD.

**Tarih dayanağı.** Shiji 110 Hun evini keçe çadır diye anar; yurt ve otağ hane bilgisidir, usta istemez (`home`). Hanshu 94A, Wei Lü'nün Tanhu'ya kuyu kazmayı, sur kurmayı ve tahılı kulede saklamayı öğütlediğini yazar; geç Hun yerleşimleri (Ivolga) sur, hendek, yarı gömük ev, demir ocağı ve darı tarlası gösterir. Bu yüzden toprak ve kule işleri ayrı zanaat ister ve en çok emeği onlar yer: yerleşim büyüdükçe emek ve usta ihtiyacı birlikte büyür.

**Ordugâh kurulumu (`cmd_camp`).** Çadırlar atlıların kendi `tent_kit`'leridir (yerleşimin keçesinden çıkmaz, `settlement.md` §10.1); her onluk kendi iki çadırını kurar (çadır başına 4 el ve bir taşıyıcı, ≈2,3 gerçek dk): birlik büyüdükçe çadırlar paralel kalkar, tümenin konağı da onluğunki kadar sürer (≈2–3 gerçek dk). `CampPlan` çadır başına kayıt tutmaz: `count`, `seed`, `doneAt` (§2.5). İnşaatta çalışan er o saatte talim kazanmaz (`army.md` `drill`): ordunun emek bedeli fırsattır. Ordugâhın yapıları ve günü `army.md` §3.7.

**Yangın ve hava.** Yeni türler §6'nın malzeme hızlarını kullanır (`stone` yanmaz). Islak keçe ve saz (K22 `wet`) sıçrama olasılığını düşürür (§6.2 `ıslak`). Gök gürültülü fırtınada `tall` türler (`sky_pole`, `banner_pole`, `watch_tower`, `granary_tower`, kule) yıldırım adayıdır; kurulmakta olan yapı aday değildir (§6.5, `weather.md` §8.7).

**Nav.** `rampart` parçaları ve `rampart_gate` kapalı kanadı yürüme ve at ızgarasına damgalanır; `field` ve `yard` düzlüğü yürünür; `grain_pit` kapaklıyken yürünür, açıkken `circle(r 1,2)` kapalı. Damga §12.3 ile (`rebuild(box)`).
```

## X15. §6.1 Yanma: ateşli ok ıslak keçede

**Bul:** `` | Ateşli ok | `max(burnT, 30)` | Keçe, saz, kolan, hemen. Ahşapta yalnız yanık izi | ``
**Yerine:** `` | Ateşli ok | `max(burnT, 30)` | Keçe, saz, kolan, hemen. Ahşapta yalnız yanık izi; tutuşturma gücü `× (1 − 0,5 × keçeIslaklığı)` (`weather.md` §8.6: ıslak keçe zor tutuşur; kuru havada değişmez) | ``

## X16. §6.2 Yayılma: rüzgâr ve ıslaklık havadan

**Bul:** `` - Rüzgâr hızı 3 m/sn (Kara Boran 8), yönü `U.uWindDir`. ``
**Yerine:** `` - Rüzgâr hızı ve yönü havadan gelir (`weather.md` §8.6): `StructureManager.wind = clamp(rüzgâr + 0,5 × bora; 0; 24)`, `windDir` havanın akış yönü. Havasız dünyada (sınama, menü) 3 m/sn ve `U.uWindDir` yönü kalır. Kara Boran 8 m/sn (`act1.md` §10 ile aynı sayı); I. Perde baskın kilidi 3 m/sn, kuzeydoğudan. ``

**Bul:** `` - `ıslak`: Kışlak'ta karlı keçe 0,5; taze karlı keçe 0,2; aksi 1. ``
**Yerine:** `` - `ıslak` (`spreadEntry.wet`, hava her kare yazar): keçe ve saz `min(1 − 0,8 × keçeIslaklığı, karÇarpanı)`; ahşap `1 − 0,4 × keçeIslaklığı`; taş ve metal 1. `karÇarpanı`: Kışlak'ta taze kar (son yağışın örtüsü >0,5) 0,2, aksi 0,5 (eski sayılar korunur); karın tutmadığı iklimde 1. `keçeIslaklığı` 0..1 yağmurla ıslanır, güneş ve rüzgârla kurur (`weather.md` §5.9). ``

## X17. §6.3 Söndürme: yağış

**Bul:** `` | Çatıyı Kesme / Cut the Roof | Üst havuzu düşürür, `burnT` 0 | `grain` hedefi, `act1.md` §8.3 | ``
**Yerine:**
```
| Çatıyı Kesme / Cut the Roof | Üst havuzu düşürür, `burnT` 0 | `grain` hedefi, `act1.md` §8.3 |
| Yağış / Rainfall | Barınaksız yanan yapıda `burnT` sn başına: çisenti −0,25, yağmur −1, gök gürültülü fırtına ve dolu −1,5, sağanak −2,5, sulu kar ve tipi −0,5, yoğun kar −0,3; hafif kar 0 | Hava (`weather.md` §8.6), `douse(oran × dt)` |

**Yağmurda yanık (hesap).** `tickBurn` ile yağış birlikte işler. Keçe henüz kuruyken ateşli ok (`burnT` 30) yağmurda 15 sn yanar (7→6; 6→5 için 30 sn gerekir), sağanakta 8,6 sn; meşale (70) yağmurda 35 sn (7→5), sağanakta 20 sn (7→6). Islak keçede (§6.1 tutuşma çarpanı) ateşli ok yağmurda 7,5 sn yanar. Hafif kar söndürmez: Son Gece oyalaması §6.1 kalibrasyonunda kalır (≈70 sn'de 7→3).
```

## X18. Yeni §6.5 Hava ve yıldırım

**Bul:** `## 7. Onarım`
**Önüne ekle:**
```
### 6.5 Hava ve yıldırım

Kurallar `weather.md` §8.6, §8.7; sayılar buraya özet olarak geçer (`d2/core.md` §3.3, §3.5).

**Dolu.** İri dolu (dolu sağanaklarının %30'u): `reed` birimi −0,5 Can/sn, `tent` örtüsü −0,2 Can/sn; küçük dolu `reed` −0,1 Can/sn. Keçe, ahşap, kafes dolu almaz. Dolu bir yapıyı aşama 1'in altına indirmez ve bir sağanakta en çok bir aşama düşürür.

**Fırtına (`fx.galeDamage`: ortalama rüzgâr ≥16 ya da bora >20 m/sn).** Tetik açık bir hava bölümünde bağsız her `tent` örtüsü bir kez %25 olasılıkla bir birim aşaması düşer; bağsız `rack` içindekinin %20'sini döker. **Bağla / Tie Down** (`E` basılı 3 sn; `tent`, `rack`) kalıcı bir durumdur, **Çöz / Untie** (`E` 1 sn) ya da sökümle kalkar; hane ve ordugâh ekipleri fırtına işareti gelince kendi çadırlarını kendiliğinden bağlar. Yurt (kolan) ve ahır (kiriş) rüzgâr almaz. Taban aynı: aşama 1'in altı yok. Sıçrama yarıçapı `R = 10 + manager.wind` (§6.2) tek kuraldır.

**Yıldırım.** Hedefi hava seçer (en uzun ve en yalnız aday, `weather.md` §8.7 skoru). Adaylar `world.tallThings`'tir: yapı yöneticisi aşama değişince ekler ve siler; kurulmakta olan yapı aday değildir; yurt (`bounds.top` 8,6 m) varsayılan en uzun adaydır. Yurt ve ahır: tepe birimine `blunt` 25 (`STRUCT.blunt.wood` 1) ve `addScorch`; keçe ıslaklığı <0,3 ise (kuru fırtına) `ignite({ power: 30 })`, ≥0,5 ise tutuşmaz. Kule: tepe birimine `blunt` 40. **Sancak Direği / Banner Pole** (`banner_pole`, 10 m): ≈9 m içindeki yurtların yerine yıldırımı alır, `blunt` 25 ve iz, kuru flama tutuşur. **Gök Direği / Sky Pole** (`sky_pole`, 12 m, yalnız Kutlu Tepe): alamet (`settlement.md` §12.4); kuru flama tutuşur (meşale 70), ıslaksa iz. Vurulan yapı 1 oyun günü bekler; bir yerleşimde fırtına başına en çok bir yapı; ana kampın yapılarına yıldırım inmez (Serbest Gez). Emek tarafı §2.4: `tall` durağında ekip bakandan 6 m çekilir, bekleyiş korkudur, zarar değil.

**Islak keçe görünümü.** `struct_tex` dış yüzü `U.uWet.y` ile koyulaşır ve dikey akıntı izi alır (`FELT_WET` kancası); iç duvar kuru kalır (dışa bakan normal sınaması ya da yapı başına merkez uniform'u). Kar çatısı Kışlak'ın kar kancasıdır (K2).

**Görünüm bütçesi.** Hava yapıya çizim ya da program eklemez: kanca metni değişir, anahtar ve program sayısı aynıdır.
```

## X19. §7 Onarım: emek, malzeme, usta, oyuncu ve örnekler

**Bul:**
```
| Süre | **Yama / Patch**, canı eksik birim: `dur × (birim canı / adım canı) × (1 − can/max) × 0,6`. **Yeniden kaldırma / Re-raise**, düşmüş birim: `dur × pay × 0,8`, kurulum gösterimiyle |
```
**Yerine:**
```
| Emek | Birimin emeği `work × (birim canı / adım canı)` (iş dakikası). **Yama / Patch**, canı eksik birim: birim emeği × (1 − can/max) × 0,6. **Yeniden kaldırma / Re-raise**, düşmüş birim: birim emeği × 0,8, kurulum gösterimiyle; adımın el sınırı ve tek el çarpanı geçer. Birimsiz yeniden koşan adım (`y_sirdak`, `y_ocak`: aşama 6'nın altına düşünce sıfırlanan, `keep: 6`) ×0,8. Geri düşüş fiziktir, emek istemez (§5.7). Süre ekipten çıkar (§2.4) |
```

**Bul:**
```
| Malzeme | `economy.md` §6.3. Yama: maliyet × 0,5 × eksik can oranı. Yeniden kaldırma: aşama maliyetinin yarısı, `repair` ile `repairCost` ¼, `repairTime` ×0,5; yukarı yuvarlanır. Demir, tündük, köz düşüşte kurtarılır. `y_tunduk` 3 kişi şartı kalır. Yanık birim +%25 |
```
**Yerine:**
```
| Malzeme | `economy.md` §6.3. Yama: maliyet × 0,5 × eksik can oranı. Yeniden kaldırma: aşama maliyetinin yarısı; Mete ekipteyken `repair` ile malzeme ¼ ve emek ×0,5; yukarı yuvarlanır. Demir, tündük, köz düşüşte kurtarılır. `y_tunduk` iki el ister, tek başına bakanla ×1,6 (eski «3 kişi şartı» kalkar). Yanık birim emekte ve malzemede +%25. **Onarım her zaman ham biçimle (`cost`) hesaplanır, parça istemez:** düşen kerege (`y_kerege`) 4 odun ve 1 iple kalkar |
```

**Bul:**
```
| Usta | Öncelik: yangın > düşmüş birim > can <%50. Elindeki iş biter, `REPAIR`'a geçer. Serbest Gez'de malzeme stoktan, sayılmaz |
```
**Yerine:**
```
| Usta | Öncelik: yangın > düşmüş birim > can <%50. Elindeki iş biter, `REPAIR`'a geçer. Serbest Gez'de malzeme stoktan, sayılmaz. A, B, ahır ve çitin yedek onarımı ana kampın iki adsız elidir (W 2, oran 1,9 İD / oyun dk), vuruştan 30 gerçek sn sonra gelirler |
```

**Bul:**
```
| Oyuncu | ≤2,2 m, E basılı: «Onar / Repair». Mete `hammer` ya da `tie`. Çocuk yalnız çentik ve yırtık yamar: «Yama / Patch», 4 sn |
```
**Yerine:**
```
| Oyuncu | ≤2,2 m, E basılı: «Onar / Repair»: Mete ekibe 1 ağırlıkla girer, `repair` ile emek ×0,5. Mete `hammer` ya da `tie`. Çocuk yalnız yırtık diker: «Yama / Patch», yırtık başına 4 İD, yarım elle 8 oyun dk ≈20 gerçek sn, `E` basılı, bırakınca ilerleme kalır; önder kuralı dışındadır. Can onarımına «Ustalara Katıl» ile yarım el katılır |
```

**Bul:** `` | Kışlak | `deliver` ister, Güven görevleri aynı (`act1.md` §9.3). Gündüz oyuncu baltayla vurursa nöbetçi uyarır | ``
**Yerine:**
```
| Kışlak | `deliver` ister, Güven görevleri aynı (`act1.md` §9.3). Gündüz oyuncu baltayla vurursa nöbetçi uyarır |

**Örnekler (hesap, §3.1 adımlarıyla).**

| Olay | Emek | Süre |
|---|---|---|
| Ateşli ok, yurt 7→5: kolan, eşik, tuurduk, üzük yanık kaldırma; şırdak ve ocak yeniden | 490 İD | camp3 ekibiyle (W 2,75; ocak tek el) 3 sa 24 dk oyun, ≈8,5 gerçek dk |
| Bosağa %50 canda, yama | 24 İD | camp3 ekibiyle ≈24 gerçek sn |
| Kerege kanadı düştü (7,5 can), kaldırma | 146 × 7,5/45 × 0,8 = 19,5 İD | ≈8 oyun dk |
| Yurt aşama 0'a indi, yalnız işçi yeniden kurar | (1.440 − 81) × 0,8 = 1.087 İD | ≈45,3 gerçek dk |
| Kışlak Gün V: yanık keçe (tuurduk, üzük) yeniden | (129 + 146) × 0,8 × 1,25 = 275 İD | Nanay ve iki el (W 3) 07:00–08:42 |
| Araba tekeri (`c_wheels` 8/24 can), kaldırma | 110 × 8/24 × 0,8 = 29 İD | Mete ve sürücü (2 el) ≈39 gerçek sn; `repair` ile ≈19 sn |
```

## X20. §10.1 Kadro, son paragraf

**Bul:** `` Adlar Hun ad kümesinden, `kurgu tercihi`. Dengiz yalnız `y_tunduk`'ta gelir, Çocuk sırığa geçerse gelmez. Bitince Oktar çıkar, Erka yurdun içinde oturur (`sitWant=1`). ``
**Yerine:** `` Adlar Hun ad kümesinden, `kurgu tercihi`. Üçü birlikte gelir ve baştan sona çalışır: Oktar ve Erka usta (ağırlık 1), Dengiz çırak (0,75); W 2,75 (§2.4). Dengiz'in işleri §10.4, Çocuğun katılışı §11.6. Bitince Oktar ve Dengiz çıkar, Erka yurdun içinde oturur (`sitWant=1`); Erka Otacı Yurdu'nun programına geçer, Oktar üç günde bir akşam aşına gelir. ``

## X21. §10.2 Durum makinesi: emek çizelgesi, sığınma, ustaların günü

**Bul:** `` **Zaman çizelgesi asıldır:** `stepT` süreyi sayar, usta onu süsler. ``
**Yerine:** `` **Emek çizelgesi asıldır:** `stepT` adımın emeğini sayar (iş dakikası, §2.4), usta onu süsler. ``

**Bul:** `` | `FLEE` | Yangın ≤4 m ya da düşüş: 6 m uzağa 3 m/sn, `wave` | Söner | ``
**Yerine:**
```
| `FLEE` | Yangın ≤4 m ya da düşüş: 6 m uzağa 3 m/sn, `wave` | Söner |
| `SHELTER` | Emek tablosunda `hold: all` (dolu, tipi, Kara Boran, toz fırtınası) ya da ne şimdiki ne sonraki adım ilerleyebiliyorsa (§2.4): en yakın yurt kapısına ya da ahır çatısının altına 1,9 m/sn; çizelge bekler | Adımın hava çarpanı 0,25 oyun saati (37 sn) işe izin verince önceki işe |
```

**Bul:** `**Yol.** A* kullanılmaz (kapıdan arkaya 64,8 ms ölçüldü).`
**Önüne ekle (yeni paragraf):**
```
**Hava.** Hız çarpanı ve duraklar emek yasasının hava tablosudur (§2.4): `felt` ve `tall` durağında o adım bekler, ekip sonraki adımın yığınını hazırlar (`tall`'da bakandan 6 m çekilir); yalnız `all` durağında ya da hiçbir adım ilerleyemiyorsa `SHELTER`. Usta beklerken HUD satırı «Ustalar fırtınanın dinmesini bekliyor.» / «The builders are waiting out the storm.» (`site:wait` `storm`, anahtar `lock.weather_build`). İş miktarı değişmez, takvim uzar.
```

**Bul:** `` Sabit `WORK` ≥3 sn ise `stampDyn(circle(r 0.3), WALK_R)`, yalnız yürüme ızgarası. ``
**Sonrasına ekle (yeni paragraf):**
```
**Ustaların günü (K20, K21).** Ustalar dünya saatiyle çalışır (`time.md`). Ana kampta ilk geliş yalnız 06:00–22:00 arasındadır: Serbest Gez 14:46'da açılır, ustalar 20 gerçek sn (8 oyun dk) sonra kuzey yamaçtaki usta girişinden (−4,5; −31) iner. 12:00 ve 18:30 öğünlerinde sırayla 30'ar dakika ateş başına oturur, iş öteki ikisiyle sürer. Batıştan (18:38) sonra iki meşale direği yanar, iş ışıkta ×1 sürer; K21 gereği ekip 22:00'de bırakmaz, yurt bitene dek çalışır (yardımsız ilk duman ≈00:55; 22:30'da yurt aşama ≥5'teyse aile ocak yanana dek ateş başında kalır, en geç 01:30; daha geç biterse `y_ocak` 05:00'te, §11.6). Şantiyeye «Gece dinlenilsin» emri verilirse ekip 22:00'de kuzeye çıkar, 06:00'da döner. Hava durağında yalnız `all` durağında ya da ne şimdiki ne sonraki adım ilerleyebiliyorsa `SHELTER`: en yakın yurdun ya da ahır çatısının altı. Kışlak'ta senaryo ekibi hikâye programına uyar: iki el 07:00–23:00, Nanay 10:30–19:30. Bekleme, uyku ve çalışma atlamasında (`clock:skip`) emek toplu işlenir, ustalar programdaki yerine konur (karartma altında). Yapı bitince Erka Otacı Yurdu'nun programına geçer, Oktar üç günde bir akşam aşına gelir.
```

## X22. §10.3 İş oranı, bölümün tamamı

**Bul:** `` `oran = (usta < crew ? 0,6 : usta > crew ve crew ≥ 2 ? 1,25 : 1) × su çarpanı`. `crew` §3.1. `REPAIR`'daki usta sayılmaz; `help_heave` ile Çocuk 1 usta sayılır. II. Perde `quick_raise`: `buildTime` ×0,7, `helpers` +1. Kışlak'ta `slice` kipi: zaman yok, usta `schedule` süsüdür. ``
**Yerine:** `` `oran = eff(W) × K_usta × K_beceri × K_gece × K_hava × K_tok × hız / solo`, iş dakikası / oyun dakikası (§2.4). `eff(W) = min(W, 10 · (1 − 0,9^W))`; W, adımın el sınırına (§3.1 «El») dek en ağır üyelerin ağırlığı: usta ve el 1, çırak 0,75, Çocuk 0,5. `solo` yurtta yalnız `y_tunduk`'tadır: tek baş kalınca bakan yöntemi (171 / 107). `REPAIR`'daki usta o adımda sayılmaz. Çocuk adımın fiilini yaptıkça 0,5 ağırlık ve bir baştır (§11.6). `quick_raise`: Mete ekipteyken ×1/0,7, Mete'nin buyurduğu şantiyeye +1 el. Gece ışıkta ×1, ay ışığında ×0,7, karanlıkta ×0,4; camp3'ün iki meşale direği batıştan sonra yanar. Su çarpanı kalkar: su zemin adımının ayak işidir (§11.6). Kışlak'ta dilim kipi kalkar: `timed` kip, dünya saati; Yeni Yurt ekibi `act1.md` §5 saat programındadır (Nanay 10:30–19:30, iki el 07:00–23:00), aşamayı malzeme ve hikâye kapıları belirler (§14, `act1.md` §9.3). ``

## X23. §10.4 İş tablosu

**Bul:** `Yüzde adım içi. Yuva yerel `(α°, r)`, kapı α=0, `(sin α·r, cos α·r)`.`
**Yerine:** `` Yüzde adım içi; adımın gerçek süresi `stepSpanS = kalan İD / oran × 2,5` ile okunur (`dur` yok), uzun pencerede hareket döngüsü sürer (`loop`). Yuva yerel `(α°, r)`, kapı α=0, `(sin α·r, cos α·r)`. Dengiz her adımda çalışır (tablonun altı); katılan Çocuğun satırları §11.6. ``

**Bul:** `` | | 40–90 | Üçü ya da Çocuk | 3 hamle: `uHoist.x` 6→4→2→0, her biri 0,9 sn | | `heave` | `uHoist.y` ±0,05 yalpa | ``
**Yerine:** `` | | 40–90 | Üçü; Çocuk katıldıysa dördü | 3 hamle: `uHoist.x` 6→4→2→0, her biri 0,9 sn; tek baş kaldığında 6 küçük hamle (`uHoist.x` 6→5→4→3→2→1→0), yalpa ×1,5 | | `heave` | `uHoist.y` ±0,05 yalpa | ``

**Bul:** `` | | 8–100 | İkisi | İç halkada, karşılıklı dilim. Sırık başı `reach_up` 0,9 + iniş 1,0 + `tie` 0,9 sn; iki ustayla 2,1 sn/sırık | `prop_pole` | `reach_up`, `tie` | `G_UUK*` | ``
**Yerine:** `` | | 8–100 | İkisi; Dengiz yığından sırık getirir | İç halkada, karşılıklı dilim. Sırık başı `reach_up` 0,9 + iniş 1,0 + `tie` 0,9 sn hareket; adım emeği 290 İD, camp3 ekibiyle (W 2,75) sırık başına ≈6,0 gerçek sn, arada `tie` döngüsü | `prop_pole` | `reach_up`, `tie` | `G_UUK*` | ``

**Bul:** `` Prop: `Folk.attach` ile usta başına 1 `Mesh`, `geometry` iş başına değişir, `props` malzemesi. +1 çizim, +1 gölge; hepsi ≤1,2k üçgen. ``
**Önüne ekle (yeni paragraf):**
```
**Dengiz (K21).** `JOBS`'a her adım için `dengiz` sütunu eklenir: zeminde Erka'yla çiğner; bosağada dikmeleri taşır ve tutar; kerege ve uukta yığından bir sonraki paketi getirir (yığın kapıdan 3,5 m); bağ ve kolanda dış halkada bağlar; tündükte bakan (bugünkü satır); çiyde saz rulosu; tuurdukta alt kenarı tutar; üzükte Oktar'la halat çeker; eşikte yığını toplar; şırdakta sandık taşır; ocakta kapıda bekler. Zemin başında yığında olmayan her kova su için, uuk başında eksik her kütük için bir sefer gider (§11.6). Uzun pencerelerde hareket döngüsü sürer (`loop`). Katılan Çocuk `CHILD_JOBS` satırlarıyla sürülür (§11.6).
```

## X24. §10.6 Ustaların sözleri, ek

**Bul:** `- Bitişte, Oktar: «Boş ev olmaz. Otacısı var artık.» / «No house stays empty. This one has its healer.»`
**Sonrasına ekle:**
```
- Alacakaranlık, Erka: «Meşaleleri dikin. Gece işi bitirmez, ışık olsun yeter.» / «Plant the torches. Night won't stop the work, so long as there is light.»
- Gece, Oktar: «Karanlıkta düğüm parmakla görülür.» / «In the dark you see a knot with your fingers.»
- Yağmur, Oktar: «Keçeyi yağmura açmayız. Bekleyelim.» / «We don't open felt to the rain. We wait.»
- Çocuk katılınca, Oktar: «Gel. Yarım el de eldir.» / «Come. Half a hand is still a hand.»
- Kütük eksik, Dengiz: «Kütük eksik. Ben getiririm.» / «We're short of logs. I'll fetch them.»
- Su yığına gelince, Dengiz: «Su mu? Sen olmasan kovaya ben koşacaktım.» / «Water? Without you I'd be running to the bucket.»
```

## X25. §11.5 Stok, uuk satırı

**Bul:** `` | Uuk | (0.4, −1.2), görsel boy 3,6 m | 12 | `y_uuk` | ``
**Yerine:** `` | Uuk | (0.4, −1.2), görsel boy 3,6 m | 12; ilk 8'i dolu başlar, 4'ü kamp odunluğundan gelince dolar (§11.6) | `y_uuk` | ``

**Bul:** `` | Taş | (−1.4, 1.2) | 6 | `y_site` | ``
**Yerine:** `` | Taş | (−1.4, 1.2) | 6; yanında 2 kova yeri, boş başlar (§11.6) | `y_site` | ``

## X26. §11.6 Emek ve oyuncunun yardımı (camp3 saatle)

**Bul (aralık):** başı `### 11.6 Zaman ve oyuncunun yardımı` başlığı, sonu `### 11.7 Tasarım seçimi` başlığından önceki boş satır. Aradaki her şey (başlık, iki paragraf, iki tablo, «Bitiş» paragrafı) değişir.
**Yerine:**
```
### 11.6 Emek ve oyuncunun yardımı

**Ekip.** Dünya saatiyle ilerler (`time.md`, K20). Serbest Gez 14:46,2'de açılır; ilk girişte saat 06:00–22:00 arasındaysa ustalar 20 gerçek sn (8 oyun dk) sonra, 14:54'te iner ve `y_site` başlar; değilse ertesi 06:00'da. Oktar, Erka ve Dengiz baştan sona çalışır (W 2,75; malzeme yontulmuş gelir, `rawWork: false`); 18:30'dan sırayla 30'ar dakika öğün, batıştan (18:38) sonra iki meşale direği (§10.2). Emek yalnız Serbest Gez saati işlerken işler: menüde, haritada ve duraklatmada saat durduğu için durur; Bekle, uyku ve çalışma atlamasında toplu işlenir (§2.5). Yürüyen iş kadraj dışında da işler. Kalan süre HUD'da oyun saatiyle yazılır: «Ekip: 3 el · ≈3 saat» / «Crew: 3 hands · ≈3 hours».

**İlk gün** (0,05 oyun dakikası adımlı benzetim). Yardımsız adımların bittiği saatler: zemin 15:30 (Dengiz iki kova suya gider), bosağa 16:02, kerege 17:00, bağ 17:20, **tündük 18:02** (batıştan önce, ikindi ışığında), uuk 20:35 (Dengiz dört kütüğe gider), çiy 21:20, tuurduk 22:11, üzük 23:09, kolan 23:54, eşik 00:03, şırdak 00:35, **ilk duman 00:55**.

| Durum (14:54 başlangıç, öğün sırası, gece meşalede) | İlk duman | Geçen oyun saati | Gerçek |
|---|---|---|---|
| Yardımsız (suya ve kütüğe Dengiz gider) | 00:55 | 10 sa 1 dk | 25,0 dk (1.503 sn) |
| Yalnız ayak işi: su, kütük, köz | 00:27 | 9 sa 33 dk | 23,9 dk (1.431 sn) |
| Yalnız katılma, her fiilde | 23:37 | 8 sa 43 dk | 21,8 dk (1.308 sn) |
| Katılma ve ayak işi | 23:11 | 8 sa 17 dk | 20,7 dk (1.244 sn) |
| Yardımsız, «Gece dinlenilsin» | Ertesi ≈08:55 | 18 sa 1 dk | 45,0 dk |

Bütün yardımla tündük 17:34'te kalkar. Saatsiz saf emek (öğünsüz, yürüyüş yolsuz): yardımsız 1.434 sn, bütün yardımla 1.188 sn. Hava durakları ortalama ≈%8 uzatır; menü ve Yeni Oyun karesi hep açıktır (K22). Uyuyan oyuncu sabah kalkmış yurdu bulur; uyanık kalan ilk dumanı gece yarısından sonra meşale ışığında görür.

**Aile bekler.** 22:30'da camp3 aşama ≥5'teyse Ozan, Ana ve Baba ocak yanana dek ateş başında kalır (en geç 01:30; 01:30'da aşama ≥6'daysa en geç 03:00); ilk duman, `CHEER` ve başların yurda dönüşü gece meşale ışığında olur. Kalan iş bu sınırı aşacaksa `y_ocak` 05:00'te, Ana közü canlandırınca yakılır. Kuralın tek sahibi `BuilderSystem`'dir: `camp3:family_wait { until }` ve `camp3:hearth_dawn` yayar, `CampLife` (`time.md` §8.2) yalnız uyar. camp3'ün ocağı yanana dek kamp havası `sev` ≤2'dir (`weather.md` §6.3): fırtına durakları ateş başı anını götürmez; HUD «Ocak tanla yakılacak» / «The hearth will be lit at first light». `world.folk.lookAt` yalnız uyanık figürlere uygulanır. Uyuyan Çocuk kartı uyanınca görür, ilk konuşan Ana söyler: «Yeni yurt gece kuruldu; ilk dumanı ozan gördü.» / «The new yurt went up in the night; the bard saw its first smoke.»

**Yardım: işçi katkısı.** Çocuk **adımın fiilini oyuncu yaptığı sürece** ekipte yarım el (0,5) ve bir baştır: çiğneme yürüyüşü, yığından yuvaya taşıma seferi, `E` basılı tutma, bağlama, geri yürüyerek çekme, çağrıda omuz. Fiil başına bir birim penceresi sayılır (adımın birim başına emeğinin süresi); fiil bırakılınca katkı durur, kamera serbesttir. Kredi, 3 kat erime ve adım başına sınırlar yoktur. Yığında ya da bir ustanın 4 m yakınında `E`: «Ustalara Katıl (yarım el)» / «Join the Builders (half a hand)»; hareket girdisi ekipten çıkarır: «Ekipten ayrıldın» / «You left the crew». «Kendiliğinden / Auto» seçeneği açıksa `BuilderSystem` Çocuğu ustaların durum makinesiyle sürer (`CHILD_JOBS`; isteğe bağlı, varsayılan kapalı). Yuva parlak halkadır (`Game.marker` gölgelendiricisi), istem `hud.setPrompt`. Ceza yok.

| id | TR / EN | Adım | Çocuğun fiili |
|---|---|---|---|
| `help_tamp` | Toprağı Çiğne / Tamp the Earth | `y_site` | Dairenin içinde çiğneyerek yürür |
| `help_carry` | Taşı / Carry | `y_bosaga`, `y_uuk`, `y_liner`, `y_sirdak` | Yığında `E`, yuvada `E`, hız ×0,8: 1 dikme, 2 sırık, 1 saz, 1 rulo |
| `help_hold` | Tut / Hold | `y_kerege`, `y_tuurduk` | Yuvada `E` basılı: kanadı, panelin alt kenarını tutar |
| `help_tie` | Bağla / Tie | `y_bag`, `y_kolan` | Dış halkada `E` basılı: düğüm tutar |
| `help_heave` | Çek / Heave | `y_tunduk` | Bakana omuz verir; çağrıda `E` (0,6 sn): tam hamlede yalpa yok, geçte yalpa ve gülüşme |
| `help_pull` | Halatı Çek / Haul the Rope | `y_uzuk` | Yuvada geri yürüyerek çeker |

**Ayak işleri** (katılmadan; Çocuk o sırada taşıyıcıdır, ekipte sayılmaz; kazancı ustanın yoludur):

| id | TR / EN | Ne değişir |
|---|---|---|
| `help_water` | Su Getir / Bring Water | Zemin adımı ocak halkasını oturtmak için yığında 2 kova su ister (kova (−3.65, 0.2), yığına ≈21 m). Eksik her kova için Dengiz bir sefer gider: 20 gerçek sn ekipten çıkar. Çocuğun önceden getirdiği kova sayısınca sefer düşer |
| `help_log` | Kütük Getir / Bring a Log | Yığın uuk için 4 kütük eksik başlar (`node_camp_logs` (6.12,−5.75), yığına 19,7 m, `E` 1,5 sn; Yük ve hız `progression.md` §2.5). Çocuk getirmezse uuk başında Dengiz dört kez gider: her sefer 26 gerçek sn ekipten çıkar |
| `help_ember` | Köz Getir / Bring an Ember | Ateşten (0,0) köz, 27 m. `y_ocak`'ın 20 İD'sinin 14'ü köz getirmektir: köz önceden yığına gelirse adım 6 İD'dir, Erka Çocuğa döner |

Kapı keçesinde (`y_esik`) ve ocakta (`y_ocak`) Çocuğa yuva açılmaz; ipucu «Kapı keçesi çocuk işi değil» / «The door felt is not a child's job» (el sınırı 4: ustalar diker ve asar). Sözler §10.6.

**Bitiş.** İlk duman, `stage_done`, ustalar `CHEER`. Çocuk köz getirdiyse Erka ona döner; ateş başındaki uyanık figürler başlarını yurda çevirir (`lookAtPoint`, 4 sn). Kart: «Yeni yurt kuruldu / The new yurt stands». Ad `Otacı Yurdu / Healer's Yurt` olur. Yer adı inşaatta `hud.setPlace`: «Yeni Yurt · Kerege 3/6» / «New Yurt · Lattice Walls 3/6», r <10 m. İnşaat parçası ekibi ve bitişi yazar: «Ekip: 3 el · Gece yarısından sonra biter» / «Crew: 3 hands · Done after midnight»; Çocuk katılınca «Ekip: 3 el + sen» / «Crew: 3 hands + you» (§2.5).

```

## X27. §11.8 Hasar ve kayıt: şema v2 ve sıkı kayıt

**Bul:**
```
{ "camp3": { "stage": 2, "hp": [0, 40, 60, 50, 80, 40, 120, 30], "t": 143.2, "cut": 1, "burnT": 0, "stuck": 1,
    // bu belgenin eki
    "step": 3, "stepT": 0.42, "units": { "k0": 7.5, "door": 40 }, "fell": [],
    "tears": [[0.62, 0.72, 1.1, 0.4, 0]], "arrows": [[-14.1, 3.2, -17.9, 0.7, -0.2, -0.6, "w1"]],
    "contrib": { "player": 3, "npc": 19 }, "helps": 12, "doneAt": null } }
```
**Yerine:**
```
{ "camp3": { "v": 2, "stage": 3, "hp": [0, 40, 60, 50, 0, 0, 0, 0], "wm": 552.9, "cut": 1, "burnT": 0, "stuck": 1,
    // bu belgenin eki
    "step": 5, "stepT": 0.31, "units": { "k0": 7.5, "door": 40 }, "fell": [], "char": {},
    "tears": [[0.62, 0.72, 1.1, 0.4, 0]],
    "contrib": { "player": 3, "npc": 19, "wm": { "player": 12.5, "npc": 540.4 } }, "doneAt": null,
    // K21 eki
    "crew": { "arrived": true }, "child": { "joined": false, "logs": 2, "ember": 0, "water": 1 },
    "stock": { "short": { "tag:wood": 2 } }, "startMin": 894.0 } }
```

**Bul:** `` `hp` havuz dizisidir, `t` işlenen saniye, `cut` yırtık sayısı, `stuck` saplı ok sayısı. Serbest Gez kaydında kalır, Yeni Oyun silmez (`progression.md` §13.4). A, B, ahır ve çitler `camp.structures[id]`, Kışlak yapıları yolculuk şemasında `structures[id]`. ≤3 KB, adım sonunda ve 30 sn'de bir. `tears` ≤48, `arrows` ≤24. ``
**Yerine:** `` `v` şema sürümü; `hp` havuz dizisidir (can 0,5 adımla nicemlenir), `wm` işlenen iş dakikası, `cut` yırtık sayısı, `stuck` saplı ok sayısı, `char` yanık birimler (onarımda ×1,25). **Sıkı kayıt (K21):** saplı okun konumu ve yanık izi (`scorch`) yazılmaz, yüklemede yeniden çizilmez; en çok 8 yırtık. `child` ayak işlerinin sayacıdır (`logs` 0–4, `ember` 0–1, `water` 0–2), `stock.short` yığının eksiği. **Göç 1 → 2:** `stage`, `hp`, `units`, `fell`, `tears`, `step`, `stepT` aynen (adım içi oran emekten bağımsızdır); `t` atılır, `wm` adım ve oranından hesaplanır; `credit` ve `helps` atılır (kalan kredi kaybolur: en çok birkaç dakikalık fark); `arrows` atılır, sayısı `stuck`'ta kalır; `doneAt` varsa bitmiş yapıdır: `doneAt: 0`; bozuk alan sessizce varsayılana düşer. Serbest Gez kaydında kalır, Yeni Oyun silmez (`progression.md` §13.4). A, B, ahır ve çitler `camp.structures[id]`; Kışlak ve sonraki perdelerin şantiyeleri yolculuk kaydında `world.sites`'tadır (§2.5). ≤2 KB, adım sonunda ve 30 sn'de bir. ``

## X28. §13.3 Aşama: `?q=low` ve Dengiz

**Bul:** `` `?q=low`: usta en çok 2, yangın alevi ≤12. ``
**Yerine:**
```
`?q=low`: Dengiz kukla ağıyla (≤1,2k üçgen) çizilir, ekipte sayılır (süre değişmez); yangın alevi ≤12.

**K21.** Dengiz baştan sona çalışır: tablonun 2 ustalı her satırına +14k ana, +14k gölge, +3 / +3 çizim (`Folk` 14.078). Faz 6'nın ölçülen en kötü karesi +217k, +35 çizim → +245k, +41: tavan içinde. İki meşale direği `frame`'de ≈120 üçgen, çizim yok; alevler `fxFlames`, parıltı `fxGlow` havuzundan; ışık ve program eklenmez.
```

## X29. Yeni §13.6 Yerleşim ve ordugâh (K23)

**Bul:** `` `closed` yurtta iç yok. ``
**Sonrasına ekle:**
```
### 13.6 Yerleşim ve ordugâh (K23)

| Uzaklık (kamera hedefinden) | Yurt | Öteki | Çizim |
|---|---|---|---|
| ≤40 m, en yakın 4 | `winter` (Otağ `hero`, iç yalnız odadayken) | Tam | Yapı başına (§13.2) |
| 40–220 m | `YurtField`: `closed` ağın (≈3k) örnekleri; `aCut` (0..1 yapım yüksekliği: yarım yurt uzaktan yarım görünür), `aChar` (yanık) | `KitField`: bütün türlerin kaba ağları (≤400 üçgen) tek `BatchedMesh` | 1 + 1 (gölge 1 + 1) |
| >220 m | `YurtField` uzak kubbe, 96 üçgen | Yok | Aynı çizimler |

- Aynı anda ≤48 canlı `StagedStructure` (yakın, şantiye, hasarlı); kayıtta zon başına ≤160 yapı.
- Yakına giren yurt `YurtField` yuvasını bırakıp kendi ağını kurar: kurulum yükleyicide hazırdır (havuz 6 `winter` ağı), geçiş 0,25 sn karışım; hasar ve aşama `StructureState`'ten okunur.
- Program: `yurt_field`, `kit_field` ve derinlik eşleri +4; `plot_decal`, `field_stalk` +2: yerleşim dünyası +6 (≤92). `plan_ghost` yoktur: yerleşim önizlemesi `Game.marker` ve `KitField`'in renk uniform'udur (§2.5). Kışta `yurt_field_w`, `kit_field_w` +2 (≤100).
- En kötü kare (Tanhu Avlusu, `settlement.md` §17): yapılar ≈460k ana üçgen, ≈22 çizim.
- Kod: `src/world/settlement-view.js` (`YurtField`, `KitField`, parsel çıkartması, `settlement.md` §18).
```

## X30. §14 Act 1 bağları: Kışlak Yeni Yurdu saatle

**Bul:** `` | `mq_first_tally`: ped, aşama 0 | `structures.spawn('yurt', { id: 'new_yurt', preset: 'winter', mode: 'slice', pad })`, `deliver('stone', 6, 'player')` | ``
**Yerine:** `` | `mq_first_tally`: ped, aşama 0 | `sites.place('yurt', { id: 'new_yurt', preset: 'winter', mode: 'timed', pad, crew, schedule: 'kislak_new_yurt' })`, spec `labour: { rawWork: false, torchFree: true, K_tok: 1 }`; `deliver('stone', 6, 'player')` | ``

**Bul:** `` | Yeni Yurt takvimi | `sliceTick()`: NPC 2 dilimde 1 aşama, malzeme gelirse dilim başına 1; aşama içi adımlar 1,5 sn'de birlikte; Gün IV akşamı `ensureStage(7)` | ``
**Yerine:** `` | Yeni Yurt takvimi | Dünya saati, ekip, malzeme ve hikâye kapısı (`act1.md` §9.3): Nanay 10:30–19:30, iki el 07:00–23:00 pedde (üçü 21,7 gerçek dk'lık emek; darboğaz malzeme ve hikâyedir). **Ambar yalnız eksiği gönderir:** II 09:00, II 13:00, III 13:00, III 15:30, IV 09:00, IV 13:00'te yığında olmayanı pede bırakır; oyuncunun birimi adım onu tüketmeden yığına girdiyse sayılır, kısmi teslim de sayılır. Aşama 1'in demirini Ardokşa ilk çeteleyle (Gün I ≈14:00) verir; oyuncu demir getirmez. `y_tunduk` `mq_crown`'u (Gün III 08:30, sahnede altı el), `y_ocak` `mq_feast` közünü bekler (köz yığında: 6 İD). Gün IV `b_feast` vaktinde eksik varsa `ensureStage(7)` | ``

**Bul:** `` | `mq_envoy` `new_yurt`: 7→5 | Ateşli ok `burnT` 30, kendiliğinden biter (§6.1); baskın saati yetmezse `setStage(5, { cause: 'fire' })`; Gün V sabahı `ensureStage(6)`: hapis odası açık kalır, çatı yırtığı durur | ``
**Yerine:** `` | `mq_envoy` `new_yurt`: 7→5 | Ateşli ok `burnT` 30, kendiliğinden biter (§6.1); baskın saati yetmezse `setStage(5, { cause: 'fire' })`; Gün V sabahı Nanay ve iki el (program istisnası, W 3) yanık keçeyi 07:00–08:42'de kaldırır (275 İD, §7 örnekleri); emniyet `ensureStage(6)`: aşama 7 kurulmaz, hapis odası açık kalır, çatı yırtığı durur | ``

**Bul:** `` | `army.md` salvo, `cmd_camp` | `hit({ type: 'pierce', sdmg: 2 * n, … }, point, dir)`; Onluk çadırı `tent`, `mode: 'slice'` | ``
**Yerine:** `` | `army.md` salvo, `cmd_camp` | `hit({ type: 'pierce', sdmg: 2 * n, … }, point, dir)`; Onluk çadırı `tent`, `mode: 'timed'`, onluklar paralel kurar (§4.6); ordugâh günü `army.md` §3.7 | ``

**Bul:** `` | `quick_raise`, `wagon_ring` | `buildTime`, `helpers`; `ringR` 14: 8 `fence` birimi, kuruluş 20 sn (`progression.md` §4.5) | ``
**Yerine:** `` | `quick_raise`, `wagon_ring` | `quick_raise`: Mete ekipteyken oran ×1/0,7, Mete'nin buyurduğu şantiyeye +1 el (§2.4); `wagon_ring` savaş düzenidir, emek yasası dışında: `ringR` 14, 8 `fence` birimi, kuruluş 20 sn (`progression.md` §4.5) | ``

## X31. §15 Sonraki perde kancaları

**Bul:** `` | Birlik, tümen (istek 13) | `crew` listesi `Squad.members` kabul eder; `oran` usta sayısıyla ölçeklenir (5–10 kişide ×2,2 tavan). `CampPlan = [{ kind, x, z, rot, preset }]`: tümen konaklaması `closed` LOD + 1–3 tam yapı, `sliceTick` | ``
**Yerine:** `` | Birlik, tümen (istek 13) | `crew` listesi `Squad.members` kabul eder; oran §2.4 (`eff(W)`, yapı başına ≤`crewMax` el, fazlası taşır). `CampPlan = [{ kind, x, z, rot, preset }]`: tümen konaklaması `closed` LOD + 1–3 tam yapı; onluklar çadırlarını paralel kurar (≈2–3 gerçek dk); gece kesintisiz (K21), «Gece dinlenilsin» emriyle ordugâh penceresinde | ``

**Bul:** `` | Erzak (istek 12) | `deliver` Kış Hesabı ile aynı eşya kimliklerini kullanır; yapı bir tüketici, `ledger` düşmez, ambar düşer | ``
**Yerine:** `` | Erzak (istek 12) | `deliver` Kış Hesabı ile aynı eşya kimliklerini kullanır; yapı bir tüketici, `ledger` düşmez, ambar düşer. II. Perde'den yerleşim ambarı `Container`'dır (`economy.md` §4.5); şantiye 150 m içindeki ambardan kendi taşır (§2.4 taşıma, §2.5) | ``

**Bul:** `` | Ana kamp | `camp3` bittikten sonra aynı yolla 4. yapı için `SITE_*` eklenir; `LAYOUT` dokunulmaz | ``
**Yerine:**
```
| Ana kamp | `camp3` bittikten sonra aynı yolla 4. yapı için `SITE_*` eklenir; `LAYOUT` dokunulmaz |
| Şantiye (K21, K23) | `game/sites.js`: her `STRUCTURE_DEFS` türü için yerleşim, yığın ve taşıma, ekip atama, gece ve hava kesintisi, söküm, kayıt (§2.5) |
| II. Perde yerleşimi ve ordugâh (K23) | `settlement.md`: yerleşim `tanhu_ordu` (`own_seat`), ordugâh `whistle_field` (`own_camp`); yapılar şantiyedir (`SiteSystem`), uzak yurt `YurtField`; §4.6 türleri; `CampPlan` çadırları `count`, `seed`, `doneAt` |
| Kalıcı yerleşimin bakımı | 10 günde bir mevsim payı ambardan düşer; ödenmezse en üst havuz %25 düşer (`settlement.md` §7.10): yapı geri düşüş kuralıyla (§5.7) yaşlanır |
| Göç ve ganimet (K23, K24) | Sağlam yurdun sökümü 1 `yurt_kit` verir (59 Yük: bir keçe araba ya da iki deve; söküm §2.4); yeni yerde aynı yurt bohçadan kalkar. Kaçan düşmanın bıraktığı sağlam yurt sökülüp ganimet olur (`economy.md` §3.12, §3.13) |
| Kap yapıları (K24) | `store_yurt` 400, `granary` 600, `granary_tower` 800, `grain_pit` 120, `shed` 500, `treasury` 120, `armoury` 200, `supply_depot` 600 Yük: içerik yapının `toJSON`'unda değil yerleşimin `settlement` bloğundadır (`StorePool`, `settlement.md` §9, §16); yapı aşama 2'nin altına inerse sandık ve ambar içeriği yer yığınına; baskın ve yangın payı tek kuraldır (`economy.md` §4.5: Ambar Çukuru %50 olasılıkla bulunur, bulunursa %30'u gider, yanmaz) |
```

## X32. §16 İstek ve ilke çatışmaları

**Bul:** `| 2 | 11: gerçekçi süre | Gerçek kurulum saat | 1:8, 9 dk 50 sn, sıra gerçek | Tempo; süre oyuncuya bırakılır, yardım hızlandırır |`
**Yerine:** `| 2 | 11: gerçekçi süre; K21 | Gerçek kurulum saat | K21: standart (parça biçimli) yurt 1 iş günü (tek işçi 60 dk; 2 el 30,6, 4 el 17,3, 8 el 11,2 dk), dünya saatinde; inşaat ışıkta gece de sürer, «Gece dinlenilsin» emriyle üretim penceresi; ham malla `rawWork` (I. Perde ve ana kampta yok); camp3 ≈25 dk (14:54 → ≈00:55); sıra gerçek | K21; Çocuğun yardımı yarım el olarak hızlandırır |`

**Bul:** `| 13 | Yapı malzeme kuralları | `progression.md` §8.3 ve `army.md` ok için aksini varsayıyor | §5.1 geçerli, §0 tablosu | Malzeme kuralları bu belgenin görev tanımında açık |`
**Yerine:**
```
| 13 | Yapı malzeme kuralları | `progression.md` §8.3 ve `army.md` ok için aksini varsayıyor | §5.1 geçerli, §0 tablosu | Malzeme kuralları bu belgenin görev tanımında açık |
| 14 | K22: hava yapıları etkiler | Yağmur yangını, yıldırım ve dolu oyuncunun emeğini zarla yok edebilir | Yağış söndürür ve ıslak keçe zor tutuşur; yıldırım uzun olanı seçer, kurulan yapıyı seçmez, bir gün bekler, ıslak keçeyi yakmaz; dolu ve fırtına aşama 1'in altına indirmez; konut halkasında Sancak Direği korur; Bağla hazırlığı | Hava okunur ve hazırlanılır olmalı; kalıcı kayıp sürpriz olmamalı |
| 15 | K23, K24: kendi yerleşimi, ordugâhı, malzemesi | Her yapı için yeni sanat ve program bütçeyi aşar | Yeni türler var olan ağların hazır ayarı ya da beş görünüm ailesidir (§4.6); uzak yapılar `YurtField` ve tek `BatchedMesh` `KitField`; program +6 (≤92) | Bütçe ve okunurluk |
```

## X33. §17 Uygulama sırası ve kabul

**Bul:** `` | 7 | Kışlak `winter`, `closed`, `slice`, Act 1 bağları | `world/winter-spec`, `game/quests` | 8, 9 | ``
**Yerine:**
```
| 7 | Kışlak `winter`, `closed`, emek kipi, Act 1 bağları | `world/winter-spec`, `game/quests` | 8, 9 |
| 8 | Emek yasası ve Faz 6 yeniden çalışması: `work`, `min`, `max`, `eff(W)`, gece ve hava çarpanları, camp3 saatle, Dengiz, Çocuğun katılışı, kayıt v2 | `game/labour.js`, `world/structure-defs.js`, `world/structure-logic.js`, `world/structure.js`, `game/builders.js`, `ui/hud/build-status.js` | K20 saati |
| 9 | Şantiye ve kum havuzu (`?state=play&sandbox=site`) | `game/site-core.js`, `game/sites.js`, `world/site-pad.js` | Bu tablonun 8'i |
| 10 | Yerleşim ve ordugâh türleri (§4.6), hazır ayarlar, `YurtField`, `KitField` (§13.6) | `world/structure-defs.js`, `src/world/settlement-view.js` | Bu tablonun 9'u; K23 yerleşim sistemi |
```

**Bul:** `` `list()`, `get(id)`, `setStep(id, stepId, t)`, `hit(id, type, lx, y, lz)`, `ignite(id, lx, y, lz)`, `speed(k)`, `reset(id)`, `diff()` (no-op piksel farkı), `nav(on)` (katman üstü çizim). ``
**Yerine:** `` `list()`, `get(id)`, `setStep(id, stepId, t)`, `hit(id, type, lx, y, lz)`, `ignite(id, lx, y, lz)`, `speed(k)`, `reset(id)`, `diff()` (no-op piksel farkı), `nav(on)` (katman üstü çizim), `labour(id)` (ekip, oran, bitiş). Emek paneli `__tanhu.labour`: `eff(W)`, `rate(siteId)`, `eta(siteId)`, `crew(siteId)`, `simulate(siteId, min)`, `weather(id)` (yerel deneme), `night(on)`, `sandbox()` (düz zemin, her tür, ekip ve hava düğmeleri). ``

**Bul:** `4. Yardımsız 590 sn ±5; bütün yardımlarla ≥283 sn.`
**Yerine:** `4. camp3 14:54 saatiyle ve öğün sırasıyla yardımsız 1.503 sn ±15 (ilk duman ≈00:55), Çocuğun bütün yardımıyla 1.244 sn ±15 (23:11); saatsiz saf emek 1.434 ve 1.188 sn ±10; tek işçi yurdu 60,0 dk ±0,1; 2 el 30,6, 4 el 17,3, 8 el 11,2 dk ±0,1.`

**Bul:** `6. Kaydet, yükle: aşama, can, yırtık, ok, yanık, yama aynı.`
**Yerine:** `6. Kaydet, yükle: aşama, can (0,5 adımla), yırtık (≤8), yanık birim ve yama aynı; saplı ok ve yanık izi kayda yazılmaz (§11.8); v1 kaydı v2'ye göçer.`

**Bul:** `10. Program sayısı ≤92, derleme hatası yok.`
**Sonrasına ekle:**
```
11. Hava: keçe kuruyken yağmurda ateşli ok 7→6'da durur (15 sn ±2), meşale 7→5'te (35 sn ±2); `a1_last_night` kilidinde meşale 7→3 70 sn ±2 (değişmez); `a1_feast_raid` kilidinde `spreadEntry.wet` 0,5, rüzgâr 3.
12. Yıldırım: kurulmakta olan yapı (`world.tallThings`'te değildir) ve 1 gün içinde vurulan yapı hedef olmaz; ıslak keçe (≥0,5) tutuşmaz; 10 m Sancak Direği ≈9 m içindeki yurtların yerine vurulur (`weather.md` §15 W9).
13. Dolu ve fırtına bir yapıyı aşama 1'in altına indirmez; bağlanmış çadır fırtınada aşama yitirmez; bağsız çadır hava bölümü başına en çok bir aşama düşer.
14. `FELT_WET` ile program sayısı değişmez; `menuDiff` 0.
15. (K23) §4.6'nın her türü kum havuzunda kurulur, vurulur, geri düşer; ≤6k üçgen, ≤2 çizim; `grain_pit` yangında içeriğini korur.
16. (K23) `otag` `scale 1.4`: kapı → içeri → ateş yolu var, oda sınırı ve ped ölçekli; birim canı ×scale².
17. (K23) `YurtField`: 60 uzak yurt 1 çizim; yakına giren yurt 0,25 sn'de kendi ağına geçer, aşama ve yanık aynı; `aCut` yarım yurdu yarım gösterir.
18. (K23) Yerleşim dünyası programı ≤92; ≤48 canlı yapı sınırında kare §13.6 tablosu içinde.
19. Emek eğrisi: tek işçi 1.440 İD; 2 el ≥30 dk (1.440 / ≥720 oyun dk); el arttıkça süre hep kısalır; tek el çarpanı yurtta yalnız tündükte.
20. Ham teslim: II. Perde şantiyesinde ham malla yurt 3.120 İD, kerege ustasız ×0,7; `spec.labour.rawWork: false` ile (camp3, Kışlak) 1.440 İD.
21. camp3: 22:30'da aşama ≥5 ise statik halk ateş başında kalır (01:30'da aşama ≥6 ise 03:00'e dek; `camp3:family_wait` olayıyla, `CampLife` uyar), ilk dumanda `lookAt` yalnız uyanıklara; sınırı aşan bitişte `camp3:hearth_dawn` ve `y_ocak` 05:00'te; ocak yanana dek kamp havası `sev` ≤2.
22. Şantiye: 600 dakikalık toplu benzetim 600 tek dakikalık adımla aynı (±1e−6 İD); `clock:skip` ve dönüşte çift işleme yok (yerleşimli zonda `catchUp`, yerleşimsiz zonda `onSkip`); `world.sites` bütün zonlarda ≤20 KB, baskın sonrası en kötü durum gidiş-dönüşü (`sites.test.js`).
23. Hava durakları: sağanakta keçe adımı bekler, ekip sonraki adımın yığınını hazırlar; dolu, tipi, Kara Boran ve toz fırtınasında `SHELTER`; dönüş 37 sn sonra; iş miktarı değişmez.
24. Kışlak Yeni Yurdu: Ambar yalnız eksiği gönderir; %50 yolu (27 birim) Toy'da Güven +10 verir; Gün V yaması 07:00–08:42 (275 İD, W 3); `ensureStage(7)` yalnız `b_feast`'te eksik varsa çalışır.
```

## X34. §18 Doğrulama durumu: hesap satırı

**Bul:** `**Hesap:** vuruş sayıları ve yanık süreleri (§5.3, §6.1), aşama bütçeleri, süre toplamları.`
**Yerine:** `**Hesap:** vuruş sayıları ve yanık süreleri (§5.3, §6.1), aşama bütçeleri, süre toplamları. **K21–K24 (2026-11-03, geçici dizinde betik, proje dosyası değişmedi):** yurdun ekip çizelgesi ve karışık ekipler (§2.4; `d2/core.md` §2.3 ile aynı), camp3 ilk günü (0,05 oyun dakikası adımlı benzetim: öğün sırası, su ve kütük yolları; §11.6), Kışlak Yeni Yurdu takvimi ve Gün V yaması (§14), onarım örnekleri (§7), öteki yapıların ve §4.6 türlerinin ekip süreleri. Tarayıcıda denenmedi.`
