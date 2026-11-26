---
title: İnşa ve Emek
order: 20
status: tasarim
summary: 'Bir yapıyı saat değil emek bitirir: Hane Yurdu tek işçinin 60 gerçek dakikasıdır, her yeni el süreyi %25 kısaltır (2 el 45, 3 el 33,75, 8 el 8,0 dk); Kâhya şantiyeyi el tavanına dek doldurur, gece ve hava yavaşlatır, malzemesiz adım başlamaz.'
sources:
  - docs/design/decisions.md
  - docs/design/structures.md
  - docs/design/d2/core.md
  - docs/design/d2/labour-model.json
  - docs/design/economy.md
  - docs/design/settlement.md
  - docs/design/act1.md
  - docs/design/time.md
  - docs/design/weather.md
  - docs/design/d3/oyun-durumu.md
---

Oyuncu şantiyede ustaları adım adım çalışırken görür; ekranda ekip ve kalan süre yazar: «Ekip: 3 el · ≈3 saat». Kişi arttıkça süre kısalır. Gece ve kötü hava yavaşlatır, malzeme gelmezse adım başlamaz. Oyuncu ekibe katılarak ya da yığına malzeme taşıyarak işi öne çeker.

> [!NOT]
> «1 çadır 1 kişi tarafından 60 dakikada kurulabilecek, 2 kişi kurarsa 45, 3 kişi kurarsa 33.75 yani her bir kişi 25% hızlandıracak»

Bu not kuralın kendisidir ([K50](/docs/source/design/decisions#k50)): tek işçi bir Hane Yurdu'nu 60, iki işçi 45, üç işçi 33,75 gerçek dakikada kurar; her yeni el süreyi %25 kısaltır. Notta «çadır» yurt anlamında okunur (K34); oyunun çadırı ayrı, daha küçük bir yapıdır: 1 el 9,0, 2 el 6,8, 4 el 3,8 gerçek dakika ([Yurtlar ve Çadırlar](/docs/buildings/yurts#cadir)). Eğri kurmada, sökümde ve onarımda geçer; tezgâhlar eski eğriyle kalır. Üçüncü yurdun ve Kışlak'ın saatleri bu eğriyi her ekipte birebir tutan modelden okunur ([K83](/docs/source/design/decisions#k83)).

## Emek yasası (K21)

K21 senin şu sözüne dayanır: «1 yurt 1 kişi ile 1 günde kurulabilsin, kişi arttıkça süre azalsın». K50 süre eğrisini senin notuna çevirdi; birimler, gece, hava, malzeme ve usta kuralları K21'indir.

Emek üç ölçüyle yazılır. İD (iş dakikası) bir işçinin bir oyun dakikası emeğidir: tek işçiyle 2,5 gerçek sn. İS (iş saati) 60 İD'dir. İG (iş günü) 1.440 İD = 24 İS = tek işçiyle 60 gerçek dk. Ekipte İD işin miktarıdır, harcanan el dakikası değildir.

Hane Yurdu 1.440 İD'dir; öteki yapılar yurda göre İG'dir ([Yapı Kataloğu](/docs/buildings/catalog)). Emek dünya saatiyle akar ([Zaman ve Takvim](/docs/world/time-calendar)): saat durunca (menü, duraklatma, harita, diyalog) emek durur, saat atlayınca (uyku, Bekle, çalışma, yolculuk) toplu işlenir. Yapı, onarım, taşıma, söküm ve zanaat aynı birimle, tek emek havuzundan ödenir.

```
T(n)  = taban × 0,75^(min(n, 8) − 1)              gerçek dk; taban = yapının tek el İD'si / 24
k(W)  = (4/3)^(min(W, 8) − 1)   W en az 1 ise;    k(W) = W   W 1'in altındaysa
oran  = k(W) × usta × beceri × gece × hava × tokluk     İD / oyun dk
```

- **Bütün yapıya tek katsayı.** Katsayı yapının bütün adımlarında aynıdır, adımın payı ekip büyüyünce değişmez. Böylece her ekipte `T(n)` tam tutar: Hane Yurdu 2 elle 45,0, 3 elle 33,75 dakikadır. Eski adım başına el sınırları ve tündüğün ×1,6 tek el çarpanı kalktı; o eski tablo yeni eğriyle koşulsaydı 2 eli 45 yerine 43,2 dakika yapardı.
- **Kapsam.** Eğri kurmada, sökümde ve onarımda işler; şantiyeye ham malla gelen parçanın emeği de şantiye ekibiyle bu eğriden geçer. Tezgâh ve zanaat tarifi K21'in eğrisiyle kalır: `eff(W) = min(W, 10 · (1 − 0,9^W))` ([Zanaat](/docs/economy/crafting)).
- **W** yapının el tavanına dek en ağır üyelerin ağırlık toplamıdır. Karışık ekipte n bu toplamdır: usta ve el 1, çırak 0,75, Çocuk 0,5. W 1'in altındaysa katsayı doğrusaldır: tek başına çırak 0,75, yaşlı 0,5 hızla çalışır; Çocuk tek başına ekip kuramaz.
- **El tavanı ve katsayı tavanı.** Baş sayısı yapının el tavanını geçemez: Küçük Yurt 6, Hane Yurdu ve yurt gövdeli yapılar 8, Otağ ve Bey Otağı 12. Katsayı 8 ağırlıkta durur: Otağ 12 elle de 20,0 dakikadır, 9.–12. eller taşır. Adlı büyük usta 1,25 ağırlıktır.
- **Görünen el** aynı anda o parçada iş başında görünen kişidir: bosağa ve tündük 6, kapı keçesi 4, ocak 1, ötekiler 8. Hızı sınırlamaz; yuvadan artan eller taşır, ipi tutar ve ekipte sayılır.
- **Tek el yöntemi görünüştür:** tündük bakanla 6 küçük hamlede kalkar, kerege ve keçe kazıkla tutulur; çarpan yoktur ([Yurtlar ve Çadırlar](/docs/buildings/yurts#parcalar-ve-kurulum-sirasi)).

| Rol | Ağırlık | Not |
|---|---|---|
| Usta | 1 | Kendi zanaatında; sırayı bilir, adımı başlatır. Adlı büyük usta en çok 1,25 |
| El | 1 | Her yetişkin Ev zanaatında ustadır, bir yurdu kurmayı bilir |
| Çırak | 0,75 | 12–16 yaş, usta sayılmaz, işi ilerletebilir |
| Yaşlı | 0,5 | Kendi zanaatında usta, şantiyede önder olur; sürü ve nöbete atanmaz |
| Çocuk | 0,5 | Yalnız Serbest Gez'in oyuncusu, adımın fiilini yaptıkça; yerleşimin çocukları atanmaz |
| Mete | 1 | Ev ustası; emek becerileri aşağıda |

- **Zanaat:** Ev (yurt, otağ, çadır, çit, ağıl, Keçe Avlusu, ordugâh yapıları), Ağaç (ahır, sundurma, ambar, kule, köprü, araba, atölye), Toprak (kuyu, sur ve hendek, yarı gömük ev, ocak ve fırın, tarla). Dülger, arabacı ve yaycı Ağaç'ın, demirci ve toprak ustası Toprak'ın ustasıdır; ötekiler Ev'indir.
- **Kurallar.** Usta kuralı: yapının zanaatından usta yoksa oran ×0,7, «Usta yok: iş yavaş». Önder kuralı: ağırlığı en az 0,75 ya da usta sayılan kimse yoksa iş ilerlemez, yırtık dikmek hariç. Tokluk: yerleşimin Yiyecek çizgisi 35 ve üstü ×1, 35'in altı ×0,85, 15'in altı ×0,7; Kışlak'ta ×1'e sabittir. Esir emeği yoktur: işçi havuzu hane, er ve gönüllü firaridir (K23).

## Ekip süre tablosu

Yetişkin, usta var, gündüz, açık hava; gerçek dakika ([structures.md §2.4](/docs/source/design/structures#2-4-emek-yasasi-labour-law-k21)):

| El | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 12 |
|---|---|---|---|---|---|---|---|---|---|
| Küçük Yurt (en çok 6 el) | 24,0 | 18,0 | 13,5 | 10,1 | 7,6 | 5,7 | – | – | – |
| Hane Yurdu | 60,0 | 45,0 | 33,75 | 25,3 | 19,0 | 14,2 | 10,7 | 8,0 | – |
| Hane Yurdu, oyun saati | 24 sa | 18 sa | 13 sa 30 dk | 10 sa 8 dk | 7 sa 36 dk | 5 sa 42 dk | 4 sa 16 dk | 3 sa 12 dk | – |
| Otağ (katsayı 8'de durur) | 150,0 | 112,5 | 84,4 | 63,3 | 47,5 | 35,6 | 26,7 | 20,0 | 20,0 |
| El başına verim | 1 | 0,67 | 0,59 | 0,59 | 0,63 | 0,70 | 0,80 | 0,94 | 0,62 |
| K21'in Hane Yurdu (kalktı) | 60,0 | 30,6 | 21,7 | 17,3 | 14,7 | 13,0 | 11,9 | 11,2 | – |

Her yeni el süreyi bir önceki sürenin %25'i kadar kısaltır: 3 elden 4'e geçmek hızı %33 artırır (K21'de %27). Kısa ekipte süre K21'den uzundur (2 el 45,0, K21'de 30,6), büyük ekipte kısadır (8 el 8,0, K21'de 11,2). El başına verim en düşük 3–4 eldedir, 8 elde 0,94'e çıkar. Dört ayrı yurtta tek başına çalışan dört el saatte 4 yurt kurar; aynı dört el tek yurtta saatte 2,4 yurt, sekiz el tek yurtta saatte 7,5 yurt kurar. Çabuk biten tek yapı ile ayrı şantiyelerde toplam iş arasındaki seçim oyuncunundur ([Kâhya'nın şantiye eli](/docs/buildings/construction-labour#kahya-nin-santiye-eli-k80)).

**Karışık ekipler** (Hane Yurdu; saf emek, öğünsüz ve yürüyüşsüz; Çocuk kapı keçesinde ve ocakta sayılmaz):

| Ekip | W | Gerçek dk |
|---|---|---|
| Usta ve Çocuk | 1,5 | 52,2 |
| Usta ve çırak | 1,75 | 48,4 |
| Üçüncü yurdun ekibi: iki usta, bir çırak | 2,75 | 36,3 |
| Üçüncü yurdun ekibi ve Çocuk (köz yığında) | 3,25 | 31,2 |
| Kışlak: Nanay ve iki el; II. Perde'nin Yüklü Hanesi (K53) | 3 | 33,75 |
| Mete yalnız, Çabuk Kurulum ile | 1 | 42,0 |
| Mete ve ilk onluk; Çabuk Kurulum ile | 8 | 8,0; 5,6 |

**Söküm** (K46, K50). Adımlar tersten işler, her adım payının 0,35'idir ve aynı eğriyle işler; görünüm kurulumun tersidir, döküntü yoktur. Sağlam taşınır yapı bohçasına döner (Küçük Yurt Yükü 38, Yurt Yükü 59, Otağ Yükü 109, Çadır Yükü 16 Yük), köz söner. Eksik ya da hasarlı yapı ve taşınmaz yapılar ayaktaki adımların ham malının yarısını verir. Dört elle Hane Yurdu sökümü 8,9 dakikadır (K21'de 6,0). Gerçekte söküm kurmaktan uzundur; oyunda göç akıcı kalsın diye kısadır.

| Söküm, gerçek dk | 1 el | 2 el | 3 el | 4 el | 6 el | 8 el |
|---|---|---|---|---|---|---|
| Küçük Yurt | 8,4 | 6,3 | 4,7 | 3,5 | 2,0 | – |
| Hane Yurdu | 21,0 | 15,75 | 11,8 | 8,9 | 5,0 | 2,8 |
| Otağ (12 el = 8 el) | 52,5 | 39,4 | 29,5 | 22,1 | 12,5 | 7,0 |
| Çadır | 3,2 | 2,4 | 1,8 | 1,3 | – | – |

## Kâhya'nın şantiye eli (K80)

Yerleşimde işi Kâhya dağıtır ([Haneler](/docs/settlement/households)); yüzü II, III ve IV. Perde'de [Lan Hatun](/encyclopedia/lan-hatun), V'ten [Yimo](/encyclopedia/yimo)'dur. Kural «el tavanına dek doldur, sonra sıradakine»dir ([K80](/docs/source/design/decisions#k80)): inşa sırasındaki ilk şantiye yapının el tavanına dek el alır, artan eller sıradaki şantiyeye gider.

| Yapı | El tavanı | Sonuç |
|---|---|---|
| Küçük Yurt | 6 | 5,7 dk, el başına verim 0,70 |
| Hane Yurdu ve yurt gövdeli yapılar | 8 | 8,0 dk, el başına verim 0,94 |
| Otağ ve Bey Otağı | 12 | Katsayı 8'de durur, 20,0 dk; 9.–12. eller malı ambardan taşır |
| Öteki yapılar | Yapının kendi tavanı, 1–8 ([Yapı Kataloğu](/docs/buildings/catalog)) | El tavanı 2–6 olan yapıda verim 0,59–0,70 |

- **El kilidi.** Oyuncu şantiyede `E` «Ekip» ya da Yerleşim Defteri'nin yapı sayfasından + / − ile şantiye başına eli sınırlar, tek elli şantiyeleri çoğaltabilir; şantiyenin önceliği 0–3'tür. «Kâhya'yı kapat» dağıtımı dondurur. Mete «Çalış» ile kendisi girer, Kâhya onu saymaz.
- **Neden bu kural.** K50'de n elin harcadığı emek tek elinkinin n × 0,75^(n−1) katıdır, el başına verim bunun tersidir. Kural yurdu en çabuk bitirir, oyuncu kişi arttıkça sürenin kısaldığını görür. Bedeli küçük yapılardadır: el tavanı 2–6 olan yapıda tavana dek doldurmak verimi 0,59–0,70'e indirir; bunlar yerleşim emeğinin küçük payıdır, kuralın kademe ortalaması 0,78–0,83 kalır. Sabit 4 el yurtta en pahalı ekiptir; tek elli şantiyeleri varsayılan yapmak toplam verimi artırır ama yarım yapı kalabalığı doğurur ve her yapıyı geç bitirir, bu yüzden oyuncunun kilidine kalır.
- **Günlük ilerleme.** El başına 24 İS elin zamanıdır, ilerleme değildir: bir şantiye günde `k(W) × 24` İS işler. 3 ellik şantiye günde 42,7 İS, 8 ellik 179,8 İS işler.

**Kademe günleri.** Yerleşimin her kademesinin hedef günü K24'tedir ([Obadan Hanlığa](/docs/settlement/encampment)). Resmî koşu 2026-11-04'tedir (K49; `econ-sim --strict`, 0 işaret); bu koşu kurmayı henüz K21'in eğrisiyle ve sabit 4 elle sayar. Eğrisi K50'ye çevrilmiş geçici kopya günleri 0,1–0,6 uzatır, hepsi hedefte kalır ([economy.md §10.6](/docs/source/design/economy#10-6-kademeler)).

| Kademe | Hedef, gün | Resmî koşu (K21, 4 el) | K50, 4 el | K50, 8 el |
|---|---|---|---|---|
| T1 Ocak | 2–5 | 2,2 | 2,3 | 2,2 |
| T2 Oba | 2,5–7 | 3,0 | 3,4 | 2,9 |
| T3 Boy Yurdu | 3–8 | 7,2 | 7,8 | 7,1 |
| T4 Toy Yeri | 4–9 | 4,6 | 4,9 | 4,5 |
| T5 Surlu Avlu | 4–12 | 8,1 | 8,6 | 7,9 |
| T5 Göçer Avlu | 4–12 | 7,8 | 8,1 | 7,7 |

Sınırda olan T3'tür: 4 elle 7,8 gün, üst uca 0,2 gün. Surlu'nun 8,1'i sur parçasının 16 odunuyladır (K52; eski 6,7 kalktı). İki uç koşu (bütün şantiyeler 4 ya da 8 elle) Kâhya kuralının kendisi değildir, ama ikisi de hedeftedir.

Doğrulanacak: Kâhya kuralıyla, K50 eğrisiyle ve şantiyenin `k(W) × 24` İS günlük ilerlemesiyle kademe günleri ([Yol Haritası](/roadmap#item-econ-sim-run)).

## Gece

İnşaat varsayılan olarak gece de sürer: «Gece de çalışılsın». Atanan el bir işçidir, nöbetleşmez; öğün ve uyku emeği durdurmaz. Bedeli meşaledir, Gönül bedeli yoktur.

| Işık | Çarpan | Kaynak |
|---|---|---|
| Işıklı ya da gündüz | ×1 | Şantiye meşale direği (karanlığın her 4 oyun saatinde 1 meşale), ışığı şantiyeye 4 m payla erişen ateş, yerleşimin fenerleri |
| Ay ışığı | ×0,7 | Bulut ay ışığını keser |
| Karanlık | ×0,4 | «Karanlık: meşale yok». İş durmaz, yavaşlar |

Işık gösterir, ısıtmaz (K1). Ana kampta ve senaryo şantiyelerinde meşale bedavadır. «Gece dinlenilsin» emri ekibi üretim penceresine çeker: ana kamp 06:00–22:00, Kışlak 07:00–23:00, yerleşim ve ordugâh yazın 05:30–21:30, kışın 07:00–23:00. Üretim ve ev işi (keçe, sepi, ağaç, aş, sağım, toplama) 16 saatlik penceredir, penceredeki her saat ışığa göre sayılır; oyuncunun buyurduğu gece vardiyası hanenin Gönül'ünü gece başına −0,2 düşürür. Bir işçinin günlük emeği: şantiye (gece emri, ışıklı) ve çobanlık 24 İS, ışıklı atölye 16 İS, açık hava üretimi yazın 15,2, baharda 14,6, güzde 13,0, kışın 12,4 İS. Hane ortalaması yazın ≈47, kışın ≈42 İS/gün'dür.

## Hava durağı

Hava yalnız fiziksel değer verir; tepki tablosu emeğindir ([Hava](/docs/world/weather), K22). «Keçe adımı» tuurduk, üzük, kapı keçesi, şırdak, araba çatısı ve çadır örtüsüdür; «uzun iş» tündük, uuk, kule ve kiriş adımlarıdır.

| Hava | Genel | Keçe adımı | Durak |
|---|---|---|---|
| Açık, bulut, kapalı, sis, rüzgâr | 1 | 1 | |
| Çisenti | 1 | 0,9 | |
| Yağmur, sulu kar | 0,85 | 0,7 | |
| Kar | 0,9 | 0,9 | |
| Yoğun kar | 0,7 | 0,7 | |
| Kuru fırtına | 0,9 | 1 | Uzun iş |
| Sağanak | 0,5 | 0 | Keçe |
| Gök gürültülü fırtına | 0,5 | 0 | Keçe, uzun iş |
| Fırtına (rüzgâr) | 0,9 (kerege 0,8) | 0 | Keçe |
| Dolu, tipi, Kara Boran, toz fırtınası | 0 | 0 | Hepsi |

- **Keçe ya da uzun iş durağında** ekip yerinde kalır, o adım bekler, ekip sonraki adımın yığınını hazırlar. Uzun işte bakandan 6 m çekilir: yıldırım kurulan yapıya inmez, bekleyiş korkudur, zarar değil.
- **Hepsi durağında** ustalar hemen en yakın yurt kapısına ya da ahır çatısına sığınır: «Ustalar fırtınanın dinmesini bekliyor.»
- **Dönüş:** adımın hava çarpanı 0,25 oyun saati (37 gerçek sn) işe izin verince.
- İş miktarı değişmez, takvim uzar: kampta ortalama ≈%8.

## Malzeme teslimi

Yığın, şantiyenin kapı yanındaki dikdörtgenidir; kapasitesi türün malzeme yükünün 1,25 katıdır.

- **Oyuncu** yığında `E` 1 sn: heybedeki uyan malzeme girer, katkısı sayılır. Yığın dikdörtgenine bırakılan yer yığını da sayılır.
- **Araba** yükü varışta kendiliğinden boşalır, bohça teslimde açılır.
- **Adım başlarken** malzemesi yığından adıma geçer. Eksikse adım başlamaz: «Malzeme bekliyor: {list}».
- **Ustalar** 150 m'ye dek bağlı ambardan kendi taşır: önce el tavanını ya da katsayı tavanını aşan boştaki eller (Otağ'ın 9.–12. elleri), yoksa en hafif üye sefer süresince ekipten çıkar. Ötesi: «Malzeme uzakta». Oyuncu getirir ya da araba atanır.

Bir sefer yetişkinde 20, çırakta 14, çocukta 6 Yük taşır. Taşımanın emeği (parantezde yapının tek el emeğine oranı):

| Yük | 25 m | 50 m | 100 m | 150 m | Araba, 50 m |
|---|---|---|---|---|---|
| Küçük Yurt, parça biçimi, 58 Yük (3 sefer) | 47 İD (%8,1) | 84 (%14,6) | 158 (%27,5) | 233 (%40,4) | 18 (1 sefer) |
| Hane Yurdu, parça biçimi, 89 Yük (5 sefer) | 78 İD (%5,4) | 140 (%9,7) | 264 (%18,3) | 388 (%26,9) | 36 (2 sefer) |
| Otağ, parça biçimi, 159 Yük (8 sefer) | 125 İD (%3,5) | 224 (%6,2) | 423 (%11,7) | 621 (%17,3) | 54 (3 sefer) |
| Hane Yurdu, ham, 146 Yük (8 sefer) | 125 İD (%8,7) | 224 (%15,6) | 423 (%29,3) | 621 (%43,1) | 54 (3 sefer) |

**Parça ve ham.** K21'in «1 kişi 1 gün» çapası parça biçimli Hane Yurdu'nun kurulumudur: bileşenler zanaattır, kurulum emektir. Şantiyeye ham mal gelirse parçanın zanaat emeği adıma eklenir ve şantiye ekibiyle inşaat eğrisinden geçer; aynı parça tezgâhta yapılırsa tezgâh eğrisiyle işler. HUD «Ham malzeme: +{n} iş saati» yazar.

| Adım | Ham biçim (Hane) | Hane Yurdu | Küçük Yurt | Otağ |
|---|---|---|---|---|
| Bosağa | 3 odun, 1 demir külçe | 360 İD (6 İS) | 360 | 360 |
| Kerege | 8 odun, 2 ip | 720 İD (12 İS); dülger ister | 360 (küçük takım: 4 odun, 1 ip; dülger) | 1.440 (2 takım) |
| Uuk | 12 odun | 480 İD (8 İS) | 240 (küçük demet: 6 odun) | 960 (2 demet) |
| İç Örtü ve Çiy | 6 saz | 120 İD (2 İS) | 120 | 240 (2 çiy) |
| **Toplam** | | **1.680 İD = 28 İS**; ham yurt tek işçiyle 3.120 İD = 130 gerçek dk, 3 elle 73,1, 8 elle 17,4 dk | **1.080 İD = 18 İS**; tek işçiyle 69 dk | **3.000 İD = 50 İS**; tek işçiyle 275 dk |

Tündük her biçimde parçadır. Usta tarifinin ustasız yolu yoktur: ekipte dülger yoksa kerege'nin ham payı işlemez, adım «Usta gerek» bekler, ×0,7 yolu yoktur. I. Perde ve ana kamp şantiyelerinde malzeme yontulmuş gelir: yurt 1.440 İD kalır. Bir yurdun zincirinin bütünü toplama 152, işleme 58, kurma 24 İS: 9,7 İG. Mete her hamı kendi toplarsa 11,0 gerçek dk harcar. **Bekleme.** Ekranda tek neden yazar, öncelik sırasıyla: yangın, tehlike, fırtına, hava, malzeme, usta, uzaklık, ekip, karanlık, gece dinlenmesi, hikâye kapısı ([structures.md §2.5](/docs/source/design/structures#2-5-santiye-building-site-k21-k23)).

## Oyuncunun payı

**Çocuk (Serbest Gez).** Çocuğun yardımı dokuz türdür: altı fiil, üç ayak işi (K52). Yığında ya da bir ustanın 4 m yakınında `E`: «Ustalara Katıl (yarım el)». Adımın fiilini oyuncu yaptığı sürece Çocuk ekipte 0,5 ağırlık ve bir baştır; bırakınca katkı durur, ceza yoktur, kamera serbesttir. Hareket girdisi ekipten çıkarır: «Ekipten ayrıldın». «Kendiliğinden» seçeneği açıksa Çocuğu ustaların durum makinesi sürer (varsayılan kapalı).

| Fiil | Adım | Çocuğun işi |
|---|---|---|
| Toprağı Çiğne | Zemin | Dairenin içinde çiğneyerek yürür |
| Taşı | Bosağa, uuk, çiy, şırdak | Yığında `E`, yuvada `E`, hız ×0,8: 1 dikme, 2 sırık, 1 saz, 1 rulo |
| Tut | Kerege, tuurduk | Yuvada `E` basılı: kanadı, panelin alt kenarını tutar |
| Bağla | Kerege bağı, kolan | Dış halkada `E` basılı: düğüm tutar |
| Çek | Tündük | Bakana omuz verir; çağrıda `E` (0,6 sn): tam hamlede yalpa yok, geçte yalpa ve gülüşme |
| Halatı Çek | Üzük | Yuvada geri yürüyerek çeker |

Kapı keçesinde ve ocakta yuva açılmaz, Çocuk bu iki adımda ekipte sayılmaz: «Kapı keçesi çocuk işi değil»; kapı keçesini ustalar diker ve asar. Ayak işleri ekibe girmeden yapılır, kazancı ustanın yoludur:

| İş | Ne değişir |
|---|---|
| Su Getir | Zemin, ocak halkasını oturtmak için yığında 2 kova su ister (kova yığına ≈21 m). Getirilmezse Dengiz iki sefer gider, her biri 20 gerçek sn ekipten çıkar |
| Kütük Getir | Yığın uuk için 4 kütük eksik başlar (kamp odunluğu yığına 19,7 m). Getirilmezse Dengiz dört sefer gider, her biri 26 gerçek sn |
| Köz Getir | Ateşten 27 m. Ocak adımının 20 İD'sinin 14'ü köz getirmektir: köz önceden yığına gelirse adım 6 İD'dir |

![Kerege adımının başı: bosağa ayakta, sağda Çocuğun yardım yuvası, sağ altta stok (prototip, üçüncü yurt)](/media/docs/research/p6-shots/smoke-help-kerege-start.png)

**Mete.** Şantiyede «Çalış» ile 1 ağırlıkla girer, hareket girdisi çıkarır. Tek başına bir Hane Yurdu'nu 60 dakikada kurar; II. Perde açılışında ilk onlukla (8 el) 8,0 dakikada (eski 11,2).

- **Çabuk Kurulum:** oran ×1/0,7 (≈×1,43), buyurduğu şantiyeye yerleşimin boştaki elinden biri katılır: yalnız 42,0, ilk onlukla 5,6 dk. Seviye 7 ve «Önce bir yurdu bitir» ister: II. Perde'nin ilk yurdu becerisizdir.
- **Onarım:** onarımda emek ×0,5, malzeme ¼ ([Hasar ve Onarım](/docs/buildings/damage-repair#onarim)).
- **Sırt Yükü:** taşıma seferi başına +8 Yük.
- **Çalışma atlaması:** `T` ya da `E` basılı 1 sn Bekle tekerini çalışma kipinde açar: «Bir saat çalış», «Üç saat çalış», «Akşama dek çalış», «Bitene dek çalış»; en çok 12 oyun saati. Tokluk 25'in altındaysa kapalıdır: «Önce bir şey ye.» Serbest Gez'de Çocuğun satırı «Bir saat yardım et»tir. İş Tahtası işi sayılmaz.

## Üçüncü yurt (camp3)

Ana kampın Serbest Gez'de kurulan yurdu. Ekip [Oktar](/encyclopedia/oktar) (Dülger), [Erka](/encyclopedia/erka) (Keçe Ustası ve Otacı) ve [Dengiz](/encyclopedia/dengiz) (çırak): W 2,75. Malzeme yontulmuş gelir, meşale bedavadır. Serbest Gez 11 Nisan MÖ 209, 14:46,2'de açılır (K76); ustalar 8 oyun dakikası sonra, 14:54'te iner ve zemin başlar. 18:30'dan sırayla 30'ar dakika öğün; batış 18:38'dedir, sonra iki meşale direği yanar. Emek yalnız Serbest Gez'in saati işlerken işler; kadraj dışında da sürer.

**Yardımsız** adım bitişleri: zemin 15:46 (Dengiz iki kova suya gider), bosağa 16:35, kerege 18:03, bağ 18:33, **tündük 20:36** (batıştan sonra, meşale ışığında), uuk 23:40 (Dengiz dört kütüğe gider), çiy 00:48, tuurduk 02:06, üzük 03:34, kolan 04:43, kapı keçesi 04:55, şırdak 05:44. Ekip ocağı hemen yaksaydı emek 05:56'da biterdi; aile kuralıyla ocak Ana'nın közüyle yanar: **ilk duman 05:48**, şafakta. **Bütün yardımla:** zemin 15:36, bosağa 16:19, kerege 17:35, bağ 18:00, tündük 19:48, uuk 22:22, çiy 23:22, tuurduk 00:29, üzük 01:46, kolan 02:45, kapı keçesi 02:57, şırdak 03:40, **ilk duman 03:43**, gece.

| Durum | Emek biter | İlk duman | Geçen oyun saati | Gerçek dk | Tündük | Uuk biter | Aile bekler |
|---|---|---|---|---|---|---|---|
| Yardımsız (suya ve kütüğe Dengiz gider) | 05:56 | 05:48, şafakta | 14 sa 54 dk | 37,2 | 20:36 | 23:40 | Hayır |
| Yalnız ayak işi: su, kütük, köz | 05:37 | 05:37, şafakta | 14 sa 43 dk | 36,8 | 20:33 | 23:29 | Hayır |
| Yalnız katılma, her fiilde | 04:02 | 04:02, gece | 13 sa 8 dk | 32,8 | 19:52 | 22:32 | Evet |
| Katılma ve ayak işi | 03:43 | 03:43, gece | 12 sa 49 dk | 32,1 | 19:48 | 22:22 | Evet |
| Yardımsız, «Gece dinlenilsin» | Ertesi 14:17 | Ertesi 14:17 | 23 sa 23 dk | 58,5 | 20:36 | Ertesi 07:40 | Hayır |

Saatsiz saf emek (öğünsüz, yürüyüşsüz): yardımsız 870 oyun dk = 36,3 gerçek dk, bütün yardımla 31,2 dk. Hava durakları kampta ortalama ≈%8 uzatır. Tündük her durumda batıştan sonra meşale ışığında kalkar: gece [Demirkazık](/encyclopedia/demirkazik)'a bakar, ozan bir satır söyler, Destan Kitabı'nda Gök Çadırı miti açılır. Eski saatler (yardımsız 05:25, bütün yardımla 03:12, tündük 19:57 ve 19:05) eski adım tablosundandı; o tablo 2 eli 45 yerine 43,2 dk yapıyordu, K83 ile kalktı. K21'in eğrisiyle ilk duman 00:55 ve 23:11'di.

**Aile bekler (K83).** Gece yeniden kurulur. camp3'ün kurulduğu gece [Ozan](/encyclopedia/bard), [Ana](/encyclopedia/mother) ve [Baba](/encyclopedia/father) 22:30'da yatmaz, 23:00'e dek ateş başında kalır; [Ağabey](/encyclopedia/older-brother) 22:30'da yatar.

- **23:00'te aşama 4 ya da üstüyse** (uuk bitmiş) aile ilk dumana dek bekler: ocak yurt bitince yanar; ilk duman, ustaların sevinci ve başların yurda dönüşü gece meşale ışığında olur. 05:00'e dek duman çıkmazsa Ana közü getirir (köz yığında: 6 İD), ocak yurt bitince yanar, aile yine oradadır.
- **23:00'te aşama 4'ün altındaysa** aile yatar. Ocak 05:00'ten önce yakılmaz: 05:00'te Ana közü getirir, ocağı ekip yakar, duman şafakla yükselir. Uyuyan Çocuk yurdu sabah kalkmış bulur, kartı uyanınca görür.
- **Satırlar.** Gece dumanında: «Yeni yurt gece kuruldu; ilk dumanı ozan gördü.» Şafak dumanında: «Yeni yurt gece kuruldu; ocağını sabah ben yaktım.» HUD «Ocak tanla yakılacak» yazar.

Neden: 23:00 denetimi ödülü katılmaya bağlar. Katılma ve bütün yardım uuk'u 22:32 ve 22:22'de bitirir (pay 28 ve 38 oyun dk), duman 04:02 ve 03:43'te gece çıkar; yardımsız ve yalnız ayak işi uuk'u 23:40 ve 23:29'da bitirir, aile yatar. Ateş başı yalnız o gece 30 oyun dakikası (75 gerçek sn) uzar. Sabit 04:15 bitişi seçilmedi: ocak yanana dek yağmur açıktır, yağmur keçe adımını ×0,7 yapar, tek yağmur bölümü 22–45 oyun dk geciktirir ve yalnız katılmanın 13 dakikalık payını aşar. «İlk dumana dek» açık havada aynı sonucu verir, yağmurda da katılan oyuncunun ateş başı anını korur. Ocak yanana dek kampta sağanak, fırtına, dolu ve toz fırtınası çıkmaz, yağmur, çisenti, sis ve kar serbesttir: fırtına durakları ateş başı anını götürmez ([Hava](/docs/world/weather)). K50'nin ilk kuralında aile 22:30'da aşama 4 ise 03:45'e dek bekliyordu; o sınırla hedefi yalnız bütün yardım tutuyordu.

**Bitiş.** İlk dumanda ustalar sevinir, Çocuk köz getirdiyse Erka ona döner, ateş başındaki uyanık figürler başlarını yurda çevirir. Kart: «Yeni yurt kuruldu». Ad Otacı Yurdu olur; içi Otacı Düzeni'dir ([Yurtlar ve Çadırlar](/docs/buildings/yurts#duzenler)).

![Tündük adımı: ustalar bakanlarla çalışıyor, önde bosağa, yerde ocak taşları (prototip, üçüncü yurt)](/media/docs/research/p6-shots/b65-tunduk3.png)

```varlik
oktar, erka, dengiz, torch, ember
```

## Kışlak Yeni Yurdu

I. Perde'nin yurdu ([I. Perde: Gün Gün](/docs/story/act-1-days)). Saat, ekip, malzeme ve hikâye kapısıyla ilerler. Ekip [Nanay](/encyclopedia/nanay) (usta, 10:30–19:30) ve iki Yapı Eri (07:00–23:00, pedde); üçü (W 3) bir yurdu 33,75 gerçek dakikalık emekle kurar (K50; K21'de 21,7). Şantiye ışığı bedavadır, tokluk ×1'e sabittir; darboğaz bilerek malzeme ve hikâyedir.

- **Kapılar.** Zemin ilk çetelenin altı taşıyla başlar. Tündük Gün III 08:30'daki Tündük Kaldırma sahnesini bekler: 171 İD, sahnedeki altı elle 40,6 oyun dakikası (≈101 gerçek sn) sürer, Gün III 09:11'de oturur (vakit 08:30–10:30). Ocak Gün IV'teki Toy közünü bekler: 17:00'de ateş bekçisi [Atşo](/encyclopedia/atsho) tek başına yakar (köz yığında 6 İD), ilk duman 17:06.
- **Ambar yalnız eksiği gönderir:** Gün II 09:00 ve 13:00, Gün III 13:00 ve 15:30, Gün IV 09:00 ve 13:00. Oyuncunun birimi adım onu tüketmeden yığına girdiyse sayılır, kısmi teslim de sayılır. Aşama 1'in demirini [Ardokşa](/encyclopedia/ardoksha) ilk çeteleyle (Gün I ≈14:00) verir; oyuncu demir getirmez.
- **Malzemenin yarısı senden** (27 / 54 birim): Toy'da Güven +10. Yayımlanan yol Gün I 14:00–17:30'da 21 birimdir (6 taş, bosağanın 3 odunu, kerege ve bağın 8 odunu ve 4 ipi), kalan 6 saz Gün III 15:30'a dek gelir.
- **Gün V yaması.** Baskında ateşli ok yurdu 7→5 düşürdüyse Nanay ve iki el yanık keçeyi 07:00–09:35'te kaldırır (275 İD, 154,7 oyun dk; K21'de 07:00–08:42). Aşama 7 kurulmaz, hapis odası açık kalır, çatı yırtığı durur.

| Aşama bitişi | Yalnız ekip ve Ambar | %50 yolu | Oyuncu her aşamayı önceden getirirse |
|---|---|---|---|
| 0 Zemin ve Ocak Halkası | Gün I 14:46 | Gün I 14:46 | Gün I 14:46 |
| 1 Kapı Çerçevesi | Gün II 10:01 | Gün I 15:31 | Gün I 15:31 |
| 2 Kerege | Gün II 14:49 | Gün I 19:19 | Gün I 17:20 |
| 3 Tündük | Gün III 09:11 | Gün III 09:11 | Gün III 09:11 |
| 4 Uuk | Gün III 15:43 | Gün III 15:43 | Gün III 12:14 |
| 5 Kamış Hasır | Gün III 16:47 | Gün III 16:47 | Gün III 13:17 |
| 6 Keçe | Gün IV 11:57 | Gün IV 11:57 | Gün III 15:52 |
| 7 Kolan, kapı keçesi, şırdak | Gün IV 15:01 | Gün IV 15:01 | Gün III 17:53 |
| 7 Duman | Gün IV 17:06 | Gün IV 17:06 | Gün IV 17:06 |

Hikâye kapıları kıpırdamaz (K50): Tündük Kaldırma Gün III 08:30, Toy'da ilk duman Gün IV 17:06, Göz Yolu Gün V 11:50. Keçe yarım gün geç kalkar ama Toy'dan önce biter. Mete pede girerse eli daha değerlidir: 3 elden 4'e hız %33 artar. Eski «tündük iki el ister, ≈25 oyun dk, III 08:55» sözü eski adım tablosundandı, K83 ile kalktı. Tam tablo [structures.md §14](/docs/source/design/structures#14-act-1-baglari) ve [act1.md §9.3](/docs/source/design/act1#9-3-yapi-sistemi-stagedstructure)'tedir.

```varlik
nanay
```

> [!DURUM]
> Oyunda (Godot): 2026-11-09'dan beri emek yasası (K50) şantiyenin durumunda çalışır ve Serbest Gez'in kamp günü vardır: Serbest Gez açıldıktan 20 gerçek sn sonra Oktar, Erka ve Dengiz iner, üçüncü yurdu kurar; yardımsız ilk duman 05:48 şafakta, bütün yardımla 03:43 gece. İş gece meşale ışığında sürer; Dengiz eksik kova ve kütük için sefere gider; «Aile bekler» 23:00'te aşamaya bakar, ocak halkı ateş saatlerine uyar. Çocuk yığında ya da bir ustanın yanında «Ustalara Katıl (yarım el)» der (yerinden ayrılınca ekipten çıkar), kovadan su, odunluktan kütük, ateşten köz getirir; yurt kayıtta kalır. Kışlak Yeni Yurdu'nun takvimi kodda ve sınamadadır, sahnesi sonraki fazdadır. Yok: Kâhya, Plan Kipi, malzeme taşıma seferleri, Çocuğun fiillerinin ayrı oynanışı (katılan Çocuk adımın fiilini kendiliğinden yapar), «Gece dinlenilsin» emri, sözlerin sesi (altyazıdır). Prototipte yurt saatsiz ve eski çizelgeyle kuruluyordu (yardımsız ≈9,8 gerçek dk), yardım kredi biçimindeydi.

![Serbest Gez'in üçüncü yurdu gece meşale ışığında: kerege ve bağ bitmiş, uuk kalkıyor, aile ateş başında (Godot, 22:10)](/media/docs/media/review/kislak_camp3_night.jpg)

![Üçüncü yurt bitti: tacından duman çıkar, ustalar gitmiş, satır şafağınki (Godot, ertesi 08:30)](/media/docs/media/review/kislak_camp3_done.jpg)

Yapılacak iş Yol Haritası'ndadır: [emek yasası](/roadmap#item-labour-law) (I. Perde, oyuncu ve dünya çekirdeği), [aşamalı kurulum](/roadmap#item-staged-building) ve [Serbest Gez'in kamp günü](/roadmap#item-roam-camp-life) (Kışlak fazı), [Kışlak Yeni Yurdu](/roadmap#item-new-yurt) (günler ve kaçış fazı), [ekonomi benzetiminin resmî koşusu](/roadmap#item-econ-sim-run) (II. Perde). Godot'da inşaat, söküm ve onarımın beklenen değerleri bu sayfanın kaynak belgelerinden yazılır; prototipin emek fikstürü yalnız tezgâh eğrisi, günlük emek, taşıma ve çarpanlar içindir (K29).

## Kaynaklar

- [decisions.md: K21 emek](/docs/source/design/decisions#k21)
- [decisions.md: K50 yurt eğrisi](/docs/source/design/decisions#k50)
- [decisions.md: K80 Kâhya'nın şantiye eli](/docs/source/design/decisions#k80)
- [decisions.md: K83 camp3'ün saatleri ve «Aile bekler»](/docs/source/design/decisions#k83)
- [decisions.md: K52 dokuz yardım türü ve sur odunu](/docs/source/design/decisions#k52)
- [decisions.md: K49 resmî koşu ve kademe günleri](/docs/source/design/decisions#k49)
- [structures.md §2.4: emek yasası](/docs/source/design/structures#2-4-emek-yasasi-labour-law-k21)
- [structures.md §2.5: şantiye](/docs/source/design/structures#2-5-santiye-building-site-k21-k23)
- [structures.md §11.6: üçüncü yurt, emek ve yardım](/docs/source/design/structures#11-6-emek-ve-oyuncunun-yardimi)
- [structures.md §14: Kışlak Yeni Yurdu takvimi](/docs/source/design/structures#14-act-1-baglari)
- [d2/core.md §2: emek ve inşa](/docs/source/design/d2/core#2-emek-ve-insa-k21)
- [settlement.md §6.2: Kâhya](/docs/source/design/settlement#6-2-kahya-steward)
- [economy.md §6.3: parça ve ham](/docs/source/design/economy#6-3-yurt-yapim-ve-onarim)
- [economy.md §10.6: kademeler](/docs/source/design/economy#10-6-kademeler)
- [act1.md §9.3: Yeni Yurt takvimi](/docs/source/design/act1#9-3-yapi-sistemi-stagedstructure)
- `d2/labour-model.json` v3: emek sayılarının makine okunur kopyası
