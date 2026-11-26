---
title: Zanaat
order: 40
status: tasarim
summary: 'Mete küçük işi saniyede elinde yapar; parça tezgâhta ve ustada, yapı şantiyede ekiple çıkar; hepsi tek emek havuzundan ödenir, tezgâh eski ekip eğrisiyle, inşaat ve onarım yurt eğrisiyle işler, kalite yalnız teçhizattadır.'
sources:
  - docs/design/decisions.md
  - docs/design/d2/core.md
  - docs/design/economy.md
  - docs/design/progression.md
  - docs/design/settlement.md
  - docs/design/structures.md
  - docs/design/d3/oyun-durumu.md
---

Üç tür iş vardır. [Mete](/encyclopedia/mete) ip, sırık, ok gibi küçük işi elinde saniyeler içinde yapar. Tezgâh işi sipariştir: eller atanır, iş akar. Usta işi ustasız hiç yürümez. Bekleme oyun saatiyle akar, oyuncuyu bekletmez. Yurtlar ve yerleşimin öteki yapıları bu parçalarla kurulur.

> [!NOT]
> «o yüzden oyunda malzeme ve envanter sistemide olması gerekiyor yine yurtlar, yerleşim yerindeki diğer gerekli birimler malzemeler ile kurulacak, malzemeler açık dünyada savaşlarla, ağaç kesere, avlanarak eti toplacanak, yine bir para birimi ve bu parayı harcayacak satıcılar etc olacak»

## Birimler ve üç tür iş

Emek iş dakikasıyla ölçülür ([K21](/docs/source/design/decisions#k21)). İD (iş dakikası): bir işçinin bir oyun dakikası. İS (iş saati): 60 İD, tek işçiyle 2,5 gerçek dk. İG (iş günü): 1.440 İD, 24 İS, tek işçiyle 60 gerçek dk.

| Tür | Kim yapar | Süre | Örnek |
|---|---|---|---|
| El işi | Mete tutuşla, işçi İS ile | En çok 8 sn tutuş | İp 2 sn, Keçe 4 sn, Ok 4 sn |
| Tezgâh işi | Sipariş, tezgâhın el sınırı | İS ve bekleme | Toplu Keçe 7 İS, 6 oyun saati |
| Usta işi | Tezgâh ve o zanaatın ustası | İS ve bekleme | Kerege Takımı 12 İS, Dülger |

**İki hız.** Toplama ve el tarifi Mete'de sıkışıktır (≈50 kat). Tezgâh, usta işi ve kurma sıkışmaz: orada Mete bir işçidir. Yurdun tezgâh ve usta işi 42,3 İS'tir, Mete tek başına yapsa 106 gerçek dk sürer. Oyuncu toplar ve küçük işi yapar; parçayı usta, yapıyı ekip kurar. Zanaat ve kurma tek emek havuzundan ödenir ([K24](/docs/source/design/decisions#k24)).

**İki eğri.** Tezgâh ve zanaat tarifi K21'in ekip eğrisiyle kalır: `eff(W) = min(W, 10 · (1 − 0,9^W))`. İnşaat, söküm ve onarım yurt eğrisiyle işler ([K50](/docs/source/design/decisions#k50)): her yeni el süreyi %25 kısaltır, katsayı 8 elde durur. Aynı parça tezgâhta yapılırsa tezgâh eğrisinden, şantiyeye ham gelirse inşaat eğrisinden geçer ([structures.md §2.4](/docs/source/design/structures#2-4-emek-yasasi-labour-law-k21)).

| El | 1 | 2 | 3 | 4 | 6 | 8 |
|---|---|---|---|---|---|---|
| Tezgâh katsayısı (K21) | 1 | 1,90 | 2,71 | 3,44 | 4,69 | – |
| İnşaat katsayısı (K50) | 1 | 1,33 | 1,78 | 2,37 | 4,21 | 7,49 |
| Hane Yurdu, gerçek dk (K50) | 60,0 | 45,0 | 33,75 | 25,3 | 14,2 | 8,0 |

Tezgâhın el sınırı en çok 6'dır (Keçe Avlusu); bu yüzden tezgâh satırında 8 el yoktur.

**Kurallar.**

- Tarifi insan öğretir: ilgili ustanın işi bitince açılır, Defter'e yazılır. Tarif başına ilk kez +20 XP.
- Sipariş «Yap», adetle verilir; girdi siparişte ayrılır. Eksikse «Malzeme bekliyor». Usta yoksa «Usta gerek»: ustasız yol yoktur, parçada kalite olmadığı için ×0,7'lik ustasız yol da yoktur.
- Bekleme yuvayı tutar, el istemez, uykuda ve atlamada da akar. Açık hava beklemesi (sırık, Sepi Yeri'nin açık yuvası, keçe kurutma) çisenti, yağmur ve sağanakta durur: «Yağmurda kurumaz». Rüzgârda ×1,3, çatı altında en az ×0,6.
- Tezgâh girdisini 150 m içindeki yerleşim ambarlarından alır, çıktıyı kabul eden en yakın kaba koyar.
- Üretim 16 saatlik penceredir. Işıklı atölye gece de ×1 çalışır, karanlığın her 4 oyun saatinde 1 Meşale yakar; ışıksız ×0,4. Buyurulan gece vardiyası hanenin Gönül'ünü gece başına −0,2 düşürür.
- İşçinin el işi en yakın uygun tezgâhta (ip ve sırık Ağaç Atölyesi'nde, ok Okçu Yurdu'nda), yoksa ocak başında yapılır.
- Rehine silah dövemez, satın alamaz. Araçlar ve teçhizat aşınmaz.

## 11 tezgâh

| Tezgâh | Yapı | El en çok | Bekleme yuvası | Perde | Başlıca işler |
|---|---|---|---|---|---|
| El | Yok | 1 | Yok | I | İp, Sırık, Ok Gövdesi, Kemik Temren, Ok, bohçalar |
| Ocak | Yok | 2 | Yok | I | Kızıl Boya, Mavi Boya, Meşale, Küçük Kazan, Aş, Köz Kabı |
| Keçe Avlusu | Keçe Avlusu | 6 | 2 | I | Keçe, Ak Keçe, Çiy, Keçe Eyer, Keçe Çizme, Keçe Kaftan, Kızıl Pelerin, Boyalı Pelerin, Keçe Çul |
| Sepi Yeri | Sepi Yeri | 3 | 4 | II | Sepi Deri, Deri Dilimli Zırh, çizmeler, kuşaklar, sadak, eyerler, At Zırhı |
| Ağaç Atölyesi | Ağaç Atölyesi | 3 | 2 | II, Oba'da kurulur | Bosağa, Kerege Takımı (iki boy), Uuk Demeti (iki boy), Tündük, Ulu Tündük, Teker Çifti, Eyer Kaşı |
| Demirci Ocağı | Demirci Ocağı | 3 | 1 | I (Kujul'un körüğü) | Bakır Parça, külçeler, Hun Kazanı, temren, silah ve madenî zırh; IV'ten Tunç Kabuk, V'te arbalet okunu eritme |
| Fırın | Fırın | 2 | 1 | II | Kömür |
| Okçu Yurdu | Okçu Yurdu | 3 | 4 | III (yaycıyla; II'de ok elle) | Okçu Yüzüğü, yaylar |
| Kazan Ocağı | Kazanlı yurt ocağı; yapı değil | 3 | 2 | II | Tutkal, toplu Aş, kazan eti, Kımız, Kandil Yağı |
| Ahır | Ahır | 2 | Yok | I | Yem Bağı |
| Kurutma Sırığı | Sırık | 1 | 6 | I | Kak, Kurut |

Ağaç Atölyesi Oba'da (2. kademe) açılır; Ocak'ta atölye yoktur, Tündük pazarcıdan gelir ([K52](/docs/source/design/decisions#k52)). Keçe Avlusu açık havadır: emek tablosunun keçe adımı hava çarpanları ona da uyar (yağmur ×0,7, sağanak ve sert rüzgârda durur). Yerleşimde tezgâh başına sürekli emir listesi vardır, Kâhya sırayla işler:

| Tezgâh | Varsayılan emir | Neden |
|---|---|---|
| Keçe Avlusu | Keçe 20 tut; Çiy 2 tut | Bakım ve yeni yurt |
| Ağaç Atölyesi | Sırık 8, Bosağa 1, Kerege Takımı 1, Uuk Demeti 1 tut | Hazır yük olmayan hane için |
| Demirci Ocağı | Demir Külçe 4 tut; Kömür 10 tut | Yurt kapısı, araba |
| Okçu Yurdu | Ordugâh ok stoğu atlı başına 24 hedefine doğru | Sadak |
| Sırık | Kurut 40, Kak 20 tut (yaz ve güz) | Kış yiyeceği |

```varlik
felt_yard, tannery, wood_shop, smithy, kiln, fletchery, stable, rack
work_table, anvil, skin_rack, grindstone
```

## 9 zanaatçı

| Zanaatçı | Tezgâh | Usta işi | Ne zaman gelir |
|---|---|---|---|
| Keçeci | Keçe Avlusu | Toplu Ak Keçe | I. Perde'de Nanay'ın avlusu; II'de her hanede |
| Sepici | Sepi Yeri | | II, hane |
| Dülger | Ağaç Atölyesi | Kerege Takımı (iki boy), Tündük, Ulu Tündük; arabacı gelene dek Teker Çifti | II, hikâye hanesiyle; atölyeyi Oba açılınca kurar |
| Arabacı | Ağaç Atölyesi | Teker Çifti | III |
| Demirci | Demirci Ocağı | Eritme, tunç, kazan, demir teçhizat; IV'ten Tunç Kabuk | I. Perde'de Kujul; II'de Oba göreviyle ([Dutu](/encyclopedia/dutu)) |
| Yaycı | Okçu Yurdu | Yaylar | III |
| Saraç | Sepi Yeri | Savaş Eyeri, At Zırhı | IV |
| Aşçı | Kazan Ocağı | Toplu yemek ×1,25 hız | II |
| Toprak Ustası | Şantiye | Kuyu, sur, yarı gömük ev, ocak ve fırın | V, Surlu yolun sığınanı |

- **Ad.** Ağaç işinin ustası «Dülger / Carpenter»dır; «Ağaç Ustası» adı kalktı ([K34](/docs/source/design/decisions#k34)).
- **Derece.** Çırak (emek ağırlığı 0,75, usta işi yapamaz) ve Usta. Kendi zanaatında 120 İS çalışan (≈8 oyun günü) ya da hikâyeyle gelen ustadır. İnce İş yalnız ustanındır.
- **Mete** zanaatçı değildir. Usta işine yardım eder, emeği sayılır, başlatamaz. Becerileri (Ocak Bilgisi, Onarım, Çabuk Kurulum) olduğu gibi işler.
- **Öğretmen usta** beceri öğretir, zanaatçı mal üretir; aynı kişi ikisi olabilir. Benzetim «11 usta» sayar: dokuz rol, Otacı ve I. Perde'nin Kujul'u.

## Tarif örnekleri

Tutuş Mete'nin gerçek saniyesi, İS işçinin emeği, bekleme oyun saatidir. Bütün liste: [economy.md §6.2](/docs/source/design/economy#6-2-i-perde-tarifleri), [§6.10](/docs/source/design/economy#6-10-tarif-tablosu-ii-perde-ve-sonrasi).

| Çıktı | Girdi | Tutuş | İS | Bekleme | Tezgâh, kim | Perde |
|---|---|---|---|---|---|---|
| 1 İp | 3 Saz | 2 | 0,5 | | El | I |
| 1 İp | 2 Kıl | 3 | 0,75 | | El | II |
| 1 Keçe | 2 Yün | 4 | 1,5 | | Keçe Avlusu, el | I |
| 6 Keçe | 12 Yün | | 7 | 6 | Keçe Avlusu | II |
| 1 Ak Keçe | 3 Yün | 5 | 2 | | Keçe Avlusu, el | II |
| 1 Çiy | 6 Saz | 4 | 2 | | Keçe Avlusu, el | II |
| 1 Sepi Deri | 1 Ham Deri, 1 sepi katkısı | 3 | 1 | 12 | Sepi Yeri, el | II |
| 2 Tutkal | 3 Kemik | | 1 | 6 | Kazan Ocağı | II |
| 2 Sırık | 1 odun | 2 | 0,5 | | El | I |
| 1 Bosağa | 3 odun, 1 Demir Külçe | | 6 | | Ağaç Atölyesi | II |
| 1 Kerege Takımı | 8 odun, 2 İp | | 12 | | Ağaç Atölyesi, usta Dülger | II |
| 1 Küçük Kerege Takımı | 4 odun, 1 İp | | 6 | | Ağaç Atölyesi, usta Dülger | II |
| 1 Uuk Demeti | 12 odun | | 8 | | Ağaç Atölyesi | II |
| 1 Küçük Uuk Demeti | 6 odun | | 4 | | Ağaç Atölyesi | II |
| 1 Tündük | 2 Huş, 2 Sinir | | 10 | 24 | Ağaç Atölyesi, usta Dülger | II |
| 1 Ulu Tündük | 4 Huş, 4 Sinir, 2 Tutkal | | 20 | 24 | Ağaç Atölyesi, usta Dülger | III |
| 1 Teker Çifti | 2 odun | | 10 | | Ağaç Atölyesi, usta Arabacı ya da Dülger | II |
| 2 Kömür | 3 odun | | 1,5 | 12 | Fırın | II |
| 1 Demir Külçe | 4 Demir Cevheri, 3 Kömür | | 4 | 6 | Demirci Ocağı, usta | II |
| 1 Demir Külçe | 4 Demir Hurda, 1 Kömür | | 2 | | Demirci Ocağı | II |
| 4 Tunç Külçe | 8 Bakır Parça, 1 Kalay, 2 Kömür | | 4 | 2 | Demirci Ocağı, usta | II |
| 1 Tunç Külçe | 4 Tunç Hurda, 1 Kömür | | 2 | | Demirci Ocağı | II |
| 1 Hun Kazanı | 4 Tunç Külçe | | 8 | | Demirci Ocağı, usta | II |
| 3 Tunç Kabuk | 1 Tunç Hurda | | 1 | | Demirci Ocağı, usta | IV |
| 1 Tunç Hurda | 8 Arbalet Oku | | 0,5 | | Demirci Ocağı | V |
| 30 Tunç Temren | 1 Tunç Külçe, 1 Kömür | | 3 | 1 | Demirci Ocağı | II |
| 15 Demir Temren | 1 Demir Külçe, 1 Kömür | | 5 | | Demirci Ocağı | II |
| 15 Ok Gövdesi | 1 hafif odun | 6 | 3 | | El | II |
| 5 Ok | 5 temren, 5 gövde, 1 Tüy | 4 | 2,5 | | El; tunç ve demirde Üç Kanat Temren becerisi | II |
| Hun Yayı | 2 Boynuz, 2 Sinir, 1 odun, 1 Tutkal | | 12 | 24 | Okçu Yurdu, usta Yaycı | III |
| Halka Kabzalı Kılıç | 3 Demir Külçe, 1 Kömür, 1 Sepi Deri | | 8 | | Demirci Ocağı, usta | II |
| Deri Dilimli Zırh | 6 Ham Deri, 2 İp | | 8 | | Sepi Yeri | II |
| Demir Dilimli Zırh | 10 Demir Külçe, 4 Sepi Deri, 2 Kömür | | 16 | | Demirci Ocağı, usta | V |
| 5 Aş | 10 Darı | | 1 | | Kazan Ocağı | II |
| 5 öğün (defter payı) | 1 Et | | 0,5 | | Kazan Ocağı | II |
| 4 Kak | 4 Et, 1 Tuz | | 1 | 2 | Kurutma Sırığı | II |
| 4 Kurut | 4 Süt, 1 Tuz | | 1 | 2 | Kurutma Sırığı | II |
| 5 Kımız | 10 Kısrak Sütü | | 1 | 12 | Kazan Ocağı; bahar–güz | II |
| 1 Kandil Yağı | 1 İç Yağı | | 0,5 | | Kazan Ocağı | II |
| Köz Kabı | 1 Küçük Kazan, 1 Ham Deri | 4 | 1 | | Ocak, el | II |
| Yurt Yükü | Yurdun taşsız ve közsüz parçaları | 3 | 0 | | El | II |

Hurdayla külçe ilk ocağın yoludur: körük ve ocak demiri 1 Demir Külçe ya da 4 Demir Hurda ile olur, ilk Demirci Ocağı külçesiz kurulur. I. Perde'de Kujul'un körüğü 4 cevheri 1 külçe yapar, kömürü kendisi katar. Tunç Kabuk döngü kurmaz: 3 kabuk bir Tunç Hurda'nın Kıymeti kadardır ([Para ve Satıcılar](/docs/economy/money-traders#kabuk)).

## Boya

İki boya vardır, ikisi de ocakta elle yapılır ([K58](/docs/source/design/decisions#k58), [economy.md §6.9](/docs/source/design/economy#6-9-isleme-zincirleri)).

| Çıktı | Girdi | Tutuş | İS | Tezgâh | Perde | Nereye girer |
|---|---|---|---|---|---|---|
| 1 Kızıl Boya | 2 Kökboya | 3 | 1 | Ocak, el | II | Kızıl Pelerin (3 Keçe + 1 boya, III), otağ kuşağı, sancak, Gök Direği |
| 1 Mavi Boya | 2 Çivit Otu | 3 | 1 | Ocak, el | II | Boyalı Pelerin |
| Boyalı Pelerin | 2 Keçe, 1 Mavi Boya | | 2 | Keçe Avlusu | II | II. Perde'nin pelerini; önerilen Kıymet 17 |

Boyalı Pelerin'in rengi oluşturucunun «Boya / Dye» satırından gelir: altı renk tek boyayla olur, boya bir kez yapılır, renk seçimdir. Varsayılan renk Göl Mavisi'dir. Mavi Boya'nın tarif oranı 1,05'tir, bantta kalır. Hun çağında mavi boyaya tanık yoktur [kurgu]. Pelerinin değerleri: [Seviye ve Gelişim](/docs/gameplay/progression).

```varlik
madder, dye, woad, dye_blue, dyed_cape, war_cape
```

## Yapıların malzemesi

Yurt ve öteki yapılar malzemeyle kurulur, emek bunun üstüne ekip işidir (K21, K24). Standart yurt parça biçimidir: «1 yurt 1 kişi 1 gün» onun kurulumudur.

| Biçim | İçerik | Yük |
|---|---|---|
| Parça (II. Perde'den) | 6 Taş, 1 Bosağa, 1 Kerege Takımı, 6 İp, 1 Tündük, 2 Sırık, 1 Uuk Demeti, 1 Çiy, 6 Keçe, 1 Köz | 89 |
| Ham (I. Perde) | 6 Taş, 23 odun, 1 Demir Külçe, 8 İp, 1 Tündük, 2 Sırık, 6 Saz, 6 Keçe, 1 Köz = 54 birim | 146 |
| Yurt Yükü | Parça biçiminin taşsız ve közsüz hâli | 59 |

Şantiyeye parça yerine ham mal gelirse parçanın emeği adıma eklenir, toplam +28 İS (Bosağa 6, Kerege Takımı 12, Uuk Demeti 8, Çiy 2): tek işçiyle ≈2,17 gün. Küçük Yurt'ta ek 18 İS, Otağ'da 50 İS'tir. Ham kerege Dülger ister. Tündük her biçimde parçadır. I. Perde ve ana kamp şantiyelerinde malzeme yontulmuş gelir, yurt 1.440 İD kalır. Bir yurdun bütün zinciri: toplama 152 İS, işleme 58 İS, kurma 24 İS, toplam 9,7 İG. Mete her hamı toplarsa 11,0 gerçek dk.

«Mete dk» en kötü durumdur: toplanabilir bütün ham Mete'nin, tezgâh işi işçinin. Kurma süresi yurt eğrisidir: usta var, gündüz, açık hava ([structures.md §4.6](/docs/source/design/structures#4-6-yerlesim-ve-ordugah-yapilari-k23)).

| Yapı | Malzeme | Zincir İG | Mete dk | Kurma, gerçek dk: 1 / 2 / 4 el | En çok el: dk |
|---|---|---|---|---|---|
| Hane Yurdu | Yukarıdaki parça biçimi | 9,7 | 11,0 | 60,0 / 45,0 / 25,3 | 8: 8,0 |
| Küçük Yurt | 4 Taş, 1 Bosağa, 1 Küçük Kerege Takımı, 1 Küçük Uuk Demeti, 1 Tündük, 1 Sırık, 1 Çiy, 3 Keçe, 3 İp, 1 Köz | 6,6 | 7,7 | 24,0 / 18,0 / 10,1 | 6: 5,7 |
| Otağ, Bey Otağı | 10 Taş, 1 Bosağa, 2 Kerege Takımı, 2 Uuk Demeti, 1 Ulu Tündük, 4 Sırık, 2 Çiy, 12 Ak Keçe, 14 İp, 2 Kızıl Boya, 1 Köz | 18,6 | 19,9 | 150,0 / 112,5 / 63,3 | 12: 20,0 (katsayı 8'de) |
| Çadır | 2 odun, 2 Sırık, 4 İp, 3 Keçe | 1,2 | 1,5 | 9,0 / 6,8 / 3,8 | 4: 3,8 |
| Gecelik Çadır, Döşek | 2 Dal, 1 Sırık, 1 İp, 1 Keçe; döşek 1 Keçe | 0,3; 0,1 | 0,4; 0,1 | 1,8 / 1,35 / – | 2: 1,35 |
| Ambar Yurdu | Yurt, köz yok | 9,7 | 11,0 | 59,2 / 44,4 / 25,0 | 8: 7,9 |
| Ahır | 4 Taş, 18 odun, 4 İp, 10 Saz, 3 Keçe | 5,0 | 5,7 | 90,0 / 67,5 / 38,0 | 6: 21,4 |
| Sundurma | 2 Taş, 7 odun, 4 İp, 6 Dal, 8 Saz | 2,4 | 3,0 | 36,0 / 27,0 / 15,2 | 4: 15,2 |
| Tahıl Ambarı | Sundurma ve 4 Kil | 3,0 | 3,6 | 48,0 / 36,0 / 20,3 | 6: 11,4 |
| Ambar Çukuru | 2 Taş, 2 odun, 2 Keçe, 1 Ham Deri, 2 Kil | 1,4 | 1,8 | 18,0 / 13,5 / 7,6 | 4: 7,6 |
| Keçe Avlusu | 1 Çiy, 4 odun, 4 İp, 2 Keçe | 1,8 | 1,9 | 30,0 / 22,5 / 12,7 | 6: 7,1 |
| Sepi Yeri | 6 odun, 4 İp, 2 Taş, 1 Küçük Kazan, 4 Saz | 2,1 | 2,8 | 24,0 / 18,0 / 10,1 | 4: 10,1 |
| Ağaç Atölyesi | 2 Taş, 12 odun, 4 İp, 1 Demir Külçe, 8 Saz | 4,6 | 5,8 | 48,0 / 36,0 / 20,3 | 6: 11,4 |
| Demirci Ocağı | 8 Taş, 6 Kil, 2 Sepi Deri, 6 odun, 1 Demir Külçe ya da 4 Demir Hurda, 6 Saz | 6,3 | 7,8 | 90,0 / 67,5 / 38,0 | 6: 21,4 |
| Fırın | 6 Taş, 8 Kil | 2,3 | 2,7 | 36,0 / 27,0 / 15,2 | 4: 15,2 |
| Hazine | 8 Taş, 16 odun, 4 İp, 2 Keçe, 2 Kil, 1 Tunç Külçe | 5,6 | 6,9 | 72,0 / 54,0 / 30,4 | 6: 17,1 |
| Kuyu | 6 Taş, 4 odun, 2 İp, 1 Boş Tulum | 2,9 | 3,2 | 60,0 / 45,0 / – | 3: 33,75 |
| Sur (10 m) | 2 Taş, 16 odun, 10 Dal | 2,7 | 3,8 | 30,0 / 22,5 / 12,7 | 8: 4,0 |
| Keçe Araba | 1 Teker Çifti, 10 odun, 4 Keçe, 2 Demir Külçe, 2 İp | 5,8 | 7,1 | 24,0 / 18,0 / 10,1 | 4: 10,1 |
| Ordu Arabası | 2 Teker Çifti, 20 odun, 8 Keçe, 6 Demir Külçe, 4 İp | 15,0 | 18,4 | 60,0 / 45,0 / 25,3 | 6: 14,2 |

- **Sur odunu** ([K52](/docs/source/design/decisions#k52)): sur parçası 4 yerine 16 odun ister, 40 parça 640 odun eder. Surlu yol odunla ve emekle öder.
- **Gecelik Çadır** ([K46](/docs/source/design/decisions#k46)) küçük bir şantiye açar: 43,2 İD, tek başına 108, iki elle 81 gerçek sn; Plan Kipi gerekmez. Parti yanındayken yoldaşlar çadır kurar, beş kişiye bir; kurma Mete'nin süresine eklenmez ([K88](/docs/source/design/decisions#k88)). Kuruluşu: [Tek Gecelik Kamp](/docs/gameplay/overnight-camp).
- **Kâhya'nın şantiye eli** ([K80](/docs/source/design/decisions#k80)): Kâhya şantiyeyi yapının el tavanına dek doldurur, sonra sıradakine geçer; oyuncu el kilidiyle sınırlar ([İnşa ve Emek](/docs/buildings/construction-labour)).

Bütün liste: [economy.md §6.12](/docs/source/design/economy#6-12-butun-yapilarin-malzemesi). Zincir ve Mete dakikası 2026-11-04 resmî koşusundandır. Yapıların işi: [Yapı Kataloğu](/docs/buildings/catalog).

## İnce İş

Kalite yalnız teçhizattadır, iki kademedir: Olağan ve İnce İş (K24).

| Soru | Kural |
|---|---|
| Hangi eşya | Ana değeri olan teçhizat: kılıç, süngü, topuz, yay, gövde zırhı, miğfer, kolluk, eyer, at zırhı, sadak |
| Kim yapar | Kendi zanaatında Usta derecesindeki zanaatçı, siparişte «İnce İş» seçilince |
| Bedel | Emek ×1,5 ve +1 asıl malzeme: yay +1 Sinir, kılıç +1 Demir Külçe, zırh ve eyer +1 Sepi Deri |
| Etki | Ana değer ×1,1 (hasar, zırh, sadak kapasitesi, eyer etkisi); Kıymet ×1,5 |
| Ad | «Hun Yayı · İnce İş» |
| Ganimet, satıcı | Ganimet olağandır, adlı hikâye eşyası hariç; satıcı İnce İş satmaz |

Malzemede kalite yoktur: yığını böler, ambar defterini ve taşıma hesabını çoğaltır. Dönemin gerçek farkları zaten ayrı maldır: Ham Deri ve Sepi Deri, Keçe ve Ak Keçe, kemik ve tunç temren.

## Onarım

**Yurt.** Onarım her zaman ham biçimle hesaplanır, parça istemez: düşen kerege kanadı 4 odun ve 1 iple kalkar. Onarım bir inşaat işidir, süresi yurt eğrisinden çıkar (K50). Onarım becerisi malzemeyi ¼'e, emeği ×0,5'e indirir.

| Aşama | Malzeme | Can | Yeniden kaldırma | Beceriyle |
|---|---|---|---|---|
| 0 Zemin ve Ocak Halkası | 6 Taş | Yıkılmaz | Yok | Yok |
| 1 Kapı Çerçevesi | 3 odun, 1 Demir Külçe | 40 | 2 odun | 1 odun |
| 2 Kerege | 8 odun, 4 İp | 60 | 4 odun, 2 İp | 2 odun, 1 İp |
| 3 Tündük | 1 Tündük, 2 Sırık | 50 | 1 Sırık | 1 Sırık |
| 4 Uuk | 12 odun | 80 | 6 odun | 3 odun |
| 5 Kamış Hasır | 6 Saz | 40 | 3 Saz | 2 Saz |
| 6 Keçe | 6 Keçe | 120 | 3 Keçe | 2 Keçe |
| 7 Kolan ve Duman | 4 İp, 1 Köz | 30 | 2 İp | 1 İp |

| Soru | Kural |
|---|---|
| Yama | Canı eksik birim. Malzeme: maliyet × 0,5 × eksik can oranı. Emek: birim emeği × (1 − can oranı) × 0,6 |
| Yeniden kaldırma | Düşmüş birim. Malzeme: aşama maliyetinin yarısı, yukarı yuvarlanır. Emek: birim emeği × 0,8 |
| Kurtarılan | Demir, Tündük, Köz düşüşte kurtarılır; tündük tek elle de kalkar |
| Yanık | Yanık birim emekte ve malzemede +%25 |
| Sıra | Alttan üste; yangın varsa önce söndürülür |
| Oyuncu | 2,2 m içinde `E` basılı «Onar»: Mete ekibe 1 ağırlıkla girer. Çocuk yalnız yırtık diker |

| Örnek | Emek | Süre |
|---|---|---|
| Bosağa %50 canda, yama | 24 İD | camp3 ekibiyle ≈37 gerçek sn |
| Kerege kanadı düştü, kaldırma | 19,5 İD | camp3 ekibiyle ≈12 oyun dk |
| Ateşli ok, Hane Yurdu 7 → 5 | 490 İD | camp3 ekibiyle ≈12,3 gerçek dk |
| Otağ kerege kanadı düştü, kaldırma | 36,5 İD | 4 elle ≈15 oyun dk |
| Yurt aşama 0'a indi, yalnız işçi yeniden kurar | 1.087 İD | ≈45,3 gerçek dk |

Ayrıntı: [structures.md §7](/docs/source/design/structures#7-onarim), [Hasar ve Onarım](/docs/buildings/damage-repair).

**Bakım.** Yerleşimde 10 günde bir mevsim payı ambardan düşer: yurt gövdeliler mevsimde 1 Keçe, 1 İp; ahşap yapılar 2 odun, 2 Saz. Ödenmezse yapının en üst havuzu %25 düşer, konutta hane Gönül −1. Toplam yerleşim emeğinin %1'inden azdır, ama Keçe Avlusu ve Sepi Yeri Tanhu Avlusu'nda da çalışır ([settlement.md §7.10](/docs/source/design/settlement#7-10-bakim)).

## Oyunda şu an

> [!DURUM]
> Godot'da: zanaat, tarif, tezgâh ve sipariş yok. Gece kampının iki yurdu ve ahırı hazır Meshy modelidir; aşamalı kurulum, hasar ve onarım yoktur.
>
> Prototipte denendi: 79 tarif ve I. Perde tarifleri, 11 tezgâh, 9 rol, tezgâh kuyruğu, İnce İş ve el tarifi (yalnız geliştirici panelinden). Godot'a taşınmadı.
>
> Yol Haritası: zanaat ve tezgâhlar ([madde](/roadmap#item-crafting)), emek yasası ([madde](/roadmap#item-labour-law)), aşamalı kurulum ve hasar ([madde](/roadmap#item-staged-building)), Kışlak'ın atölyeleri ([madde](/roadmap#item-building-catalog)).

## Kaynaklar

- [d2/core.md §5.4: Tezgâhlar ve zanaatçılar](/docs/source/design/d2/core#5-4-tezgahlar-ve-zanaatcilar)
- [d2/core.md §5.5: Yurdun malzemesi](/docs/source/design/d2/core#5-5-yurdun-malzemesi)
- [economy.md §6: Zanaat ve onarım](/docs/source/design/economy#6-zanaat-ve-onarim)
- [economy.md §6.7: Tezgâhlar ve iki hız](/docs/source/design/economy#6-7-tezgahlar-ve-iki-hiz-k24), [§6.8: Zanaatçılar](/docs/source/design/economy#6-8-zanaatcilar), [§6.9: İşleme zincirleri](/docs/source/design/economy#6-9-isleme-zincirleri)
- [economy.md §6.10: Tarif tablosu](/docs/source/design/economy#6-10-tarif-tablosu-ii-perde-ve-sonrasi), [§6.11: Kıymet dengesi](/docs/source/design/economy#6-11-kiymet-dengesi), [§6.12: Bütün yapıların malzemesi](/docs/source/design/economy#6-12-butun-yapilarin-malzemesi)
- [economy.md §2.10: Kalite, yığın, bozulma](/docs/source/design/economy#2-10-kalite-yigin-bozulma)
- [structures.md §2.4: Emek yasası](/docs/source/design/structures#2-4-emek-yasasi-labour-law-k21), [§4.6: Yerleşim ve ordugâh yapıları](/docs/source/design/structures#4-6-yerlesim-ve-ordugah-yapilari-k23), [§7: Onarım](/docs/source/design/structures#7-onarim)
- [settlement.md §8: Üretim zincirleri ve atölyeler](/docs/source/design/settlement#8-uretim-zincirleri-ve-atolyeler)
- [progression.md §6.2: Giyilen eşya](/docs/source/design/progression#6-2-giyilen-esya) (Boyalı Pelerin), [§7: Silahlar](/docs/source/design/progression#7-silahlar)
- [d3/oyun-durumu.md](/docs/source/design/d3/game-state)
- Kararlar: [K21](/docs/source/design/decisions#k21), [K24](/docs/source/design/decisions#k24), [K34](/docs/source/design/decisions#k34), [K46](/docs/source/design/decisions#k46), [K48](/docs/source/design/decisions#k48), [K49](/docs/source/design/decisions#k49), [K50](/docs/source/design/decisions#k50), [K51](/docs/source/design/decisions#k51), [K52](/docs/source/design/decisions#k52), [K58](/docs/source/design/decisions#k58), [K80](/docs/source/design/decisions#k80), [K88](/docs/source/design/decisions#k88)
- Önceki: [Toplama ve Kaynaklar](/docs/economy/gathering). Sonraki: [Para ve Satıcılar](/docs/economy/money-traders)
