---
title: Ekonomi Dengesi
order: 60
status: tasarim
summary: 'Denge sayıları yeniden koşulabilir bir modelden gelir; 2026-11-04 resmî koşusu 0 işaret verdi: kademe günleri 2,2 / 3,0 / 7,2 / 4,6 / 8,1 ve 7,8, hepsi K24 hedefinde; akın perde başına ambarın en çok %7,9''unu götürür.'
sources:
  - docs/design/decisions.md
  - docs/design/d2/core.md
  - docs/design/economy.md
  - docs/design/settlement.md
  - docs/design/structures.md
  - docs/design/d2/econ-model.json
  - docs/design/d2/settlement-model.json
  - docs/design/d2/weather-model.json
  - docs/design/d2/labour-model.json
  - docs/design/d3/oyun-durumu.md
---

Ekonomi oyunun önüne geçmemeli: I. Perde'de oyun süresinin en çok %12'si, sonraki perdelerde en çok %25'i. Kış bilerek dardır. Sayılar elle yazılmaz, modelden gelir: `node tools/econ-sim.mjs --strict` (prototip deposunda koşar). **Resmî koşu 2026-11-04'te yapıldı ve 0 işaret verdi: «Bütün hedefler tutuyor.»** ([K49](/docs/source/design/decisions#k49)). O koşuda model 131 eşya, 85 tarif, 52 yapı, 5 kademe, 9 ganimet tablosu, 11 usta ve 6 satıcıdır; ekonomi modeli v3, yerleşim v3, emek v3, hava v2. Sonra modele mavi boya zinciri ([K58](/docs/source/design/decisions#k58)) ve Takas Yeri gezgini ([K81](/docs/source/design/decisions#k81)) girdi: aynı komut 134 eşya, 87 tarif, 52 yapı ve 7 satıcıyla yine 0 işaret verir, kademe ve perde günleri değişmez. Bu sayfanın sayıları, aksi yazılmadıkça o koşudandır.

Birimler: İD (iş dakikası: bir işçinin bir oyun dakikası), İS (iş saati: 60 İD), İG (iş günü: 1.440 İD, tek işçiyle 60 gerçek dk). T1–T5 yerleşim kademeleridir: Ocak, Oba, Boy Yurdu, Toy Yeri, Tanhu Avlusu.

**Simin bugünkü sınırı.** Sim emek modelinin v3'ünü okur ama inşaat eğrisini (`law.build`) uygulamaz: kurmayı K21'in eski ekip katsayısıyla ve sabit 4 elle sayar. K50 eğrisinin etkisi aşağıda ayrı tablodadır ([Yurt eğrisi ve Kâhya](#yurt-egrisi-ve-kahya)).

## K24 hedefleri

| Ölçü | Hedef | Koşunun sonucu |
|---|---|---|
| Sıradan ham (odun, taş, saz, kil, tezek, ot) | Mete ≤12 sn/birim | En kötü Taş 10 sn |
| Seyrek ham (cevher, tuz, saksavul, kökboya) | ≤40 sn/birim | Kalay Cevheri 18 sn |
| Av ürünü | ≤120 sn/birim | Kurt Kürkü 69 sn |
| İşlenmiş (ip, keçe, sepi deri, kömür, külçe) | ≤90 sn/birim | Demir Külçe 87 sn |
| El tarifi | ≤8 sn tutuş | Hepsi; pişirme oturmadır |
| Yurt | Zincir ≤12 dk Mete payı, ≤10 İG; kurulum 1 İG | 11,0 dk, 9,7 İG |
| Yurt gövdeli yapı | ≤14 dk, ≤12 İG | En çok 12,8 dk, 11,3 İG (Erzak Ambarı) |
| Büyük yapı | ≤35 dk, ≤30 İG | Otağ 19,9 dk, 18,6 İG |
| Atölye, kap yapısı | ≤8 dk, ≤8 İG | Demirci Ocağı 7,8 dk, 6,3 İG |
| Araba | ≤20 dk, ≤16 İG | Ordu Arabası 18,4 dk, 15,0 İG |
| Kademe günü | T1 2–5, T2 2,5–7, T3 3–8, T4 4–9, T5 4–12 | 2,2; 3,0; 7,2; 4,6; Surlu 8,1, Göçer 7,8 |
| Kademe oyuncu dakikası | T1 ≤35, T2 ≤60, T3 ≤60, T4 ≤50, T5 ≤45 | 25,5; 28,4; 35,8; 26,6; Surlu 27,0, Göçer 24,9 |
| Perde | Doğrudan ekonomi eylemi ≤%25 (420 dk'lık perdede ≤105 dk) | En çok %15 (II) |
| Kış payı | Saklananla %75–115 | %87–97; Surlu V'te %91, VI'dan tarla ve kuleyle %102; Göçer sürü tavanında %113 |
| Akın | Perde başına ambar kaybı ≤%10, Ambarcısız | Tek akında en çok %3,9; perde tavanında en çok %7,9 (ikisi de III) |
| Tarif Kıymeti | 0,85–1,6 ya da gerekçeli | İşaret yok |
| I. Perde | Yurt 54 birim, 146 Yük; Kış Hesabı teslimleri aynen | Aynen; 17 teslimin hepsi aynı |

**I. Perde'nin dakika hedefleri** ayrıdır, K24 onlara dokunmaz: tek iş ≤2,5 dk (model 0,5–2,0), yan görev malzemesi ≤5 dk (≤4,6), bir gün ≤%30 (Gün III %27), ana yol ≤%10 (16 dk / 220 dk = %7), tüm içerik ≤%12 (37 dk / 310 dk = %12).

## Kademe günleri

«Gün»: Mete oyuncu payını toplar, boştaki her el yapıya gider, şantiye gece de çalışır. «Mete toplamazsa»: pay 0. «Gece dinlenilsin»: ekip üretim penceresine çekilir. «Bol yiyecekle»: Kâhya avı ve yiyecek cezası olmadan; alt uç bununla da tutmalı.

| Kademe | Hedef | Gün | Mete toplamazsa | Gece dinlenilsin | Bol yiyecekle |
|---|---|---|---|---|---|
| T1 Ocak | 2–5 | 2,2 | 4,0 | 2,3 | 2,2 |
| T2 Oba | 2,5–7 | 3,0 | 4,2 | 3,5 | 2,6 |
| T3 Boy Yurdu | 3–8 | 7,2 | 8,9 | 8,2 | 7,2 |
| T4 Toy Yeri | 4–9 | 4,6 | 5,0 | 5,0 | 4,4 |
| T5 Surlu Avlu | 4–12 | 8,1 | 8,5 | 8,8 | 7,4 |
| T5 Göçer Avlu | 4–12 | 7,8 | 8,1 | 8,2 | 7,1 |

Hazır Yurt Yükü, gelen hanenin ve armağanın getirdiği yüktür. Oyuncu payı, hamın Mete'nin topladığı kısmıdır.

| Kademe | Perde, mevsim | Hane | Hazır yük | Çevre | Oyuncu payı | Mete dk (tavan) |
|---|---|---|---|---|---|---|
| T1 Ocak | II, yaz | 3 | 1 | 1 | %80 | 25,5 (35) |
| T2 Oba | II, yaz | 7→10 | 6 | 1 | %45 | 28,4 (60) |
| T3 Boy Yurdu | III, güz | 18→22 | 12 | 0,85 | %25 | 35,8 (60) |
| T4 Toy Yeri | IV, yaz | 22→45 | 22 | 0,7 | %12 | 26,6 (50) |
| T5 Surlu Avlu | V, kış | 45→80 | 17 | 0,6 | %5 | 27,0 (45) |
| T5 Göçer Avlu | V, kış | 45→80 | 17 | 0,6 | %5 | 24,9 (45) |

- **Okuma.** Ocak'ta oyuncunun eli asıl motordur (%80 pay, 25,5 dk); Tanhu Avlusu'nda oyuncu karar verir, halk kurar (%5 pay, 25–27 dk).
- **T1.** Ağaç Atölyesi henüz yoktur, Tündük pazarcıdan gelir, o da iki günde bir 1 tane getirir ([K52](/docs/source/design/decisions#k52)). 2,2 gün bundan çıkar; emek 1,8 gündür.
- **T2.** Alt ucu 2,5 gündür (K24): hazır yük 6 kalır; 2,5 oyun günü 150 gerçek dakikadır, tek sahne değildir.
- **T3 en uzun kademedir** (7,2 gün, üst uca 0,8 gün): güzde ot biçimi hane emeğinin ≈%30'unu alır, çevre 0,85'tir; otağ, Gök Direği, Takas Yeri ve 12 yurt aynı perdededir. Gece dinlenilirse 8,2 gün ile hedefin üstüne çıkar; sim yalnız «Gün» sütununu sınar, bu yüzden işaret vermez.
- **Ot biçimi penceresi** 8 Ağustos–15 Kasım'dır ve daraltılmaz: 85 günden kısası T3'ü 8 günün üstüne iter, Ağustos–Eylül 10,5 gün eder ([d2/core.md §7.1](/docs/source/design/d2/core#7-1-dogrulama-turu-2026-11-03-v1-v39)).
- **Perde günü** (K25 bütçesine karşı; II'de T1, T2 ve 2 yol günü): II 7,2 / 12, III 7,2 / 12, IV 4,6 / 14, V Surlu 8,1 / 12, V Göçer 7,8 / 12. Bütçe bir tasarım ölçüsüdür, oyunda sayaç yoktur ([K42](/docs/source/design/decisions#k42)).
- **Meşale.** Gece şantiyesi karanlığın her 4 saatinde şantiye başına 1 meşale yakar: T1 4, T2 9, T3 20, T4 26, Surlu 96, Göçer 58.

**Surlu ve Göçer** ([K52](/docs/source/design/decisions#k52)). Sur parçasının odunu 4'ten 16'ya çıktı: 40 parça 640 odun. Surlu odun ≈×1,4 ve kurma emeği ≈×1,7 ister (91,1 ve 54,9 İG); Göçer keçe ≈×1,6, ip ≈×1,5 ve demir ≈×2 ister. İki yolun günü 8,1 ve 7,8'dir: seçim hızla değil malla yapılır. Surlu'nun ham Yük'ü ≈%19 çoktur (8.053 ve 6.771); Mete dakikası 27,0 ve 24,9. Fazladan 480 odun IV'te zonda biter ve kereste kervanı ister (≈14 Ordu Arabası seferi).

**Hazır yük** ([K53](/docs/source/design/decisions#k53)). Oba dalgası, Avlu göçü ve toplantı haneleri Yüklü Hane'dir, yurt yükleriyle gelir: 1 / 6 / 12 / 22 / 17. Hazır yük eski az sayılara (1 / 1 / 2 / 5 / 8) düşseydi günler T2 4,9, T3 12,1 (Mete 60,4 dk; hedef 8 ve perde ölçüsü 12 aşılır), T4 7,9, T5 9,6 ve 9,3 olurdu. Yüklü Hane'nin payı kademe günlerinin taşıyıcısıdır; İsteyen Hane'nin payı büyürse T3 hedefi kaçar.

## Yurt eğrisi ve Kâhya

**Yurt eğrisi** ([K50](/docs/source/design/decisions#k50)). İnşaat, söküm ve onarım `T(n) = taban × 0,75^(min(n, 8) − 1)` ile işler; tezgâhlar K21'in eski katsayısıyla kalır. Hane Yurdu 1–8 elle 60 / 45 / 33,75 / 25,3 / 19,0 / 14,2 / 10,7 / 8,0 gerçek dk. n elin harcadığı emek tek elinkinin n × 0,75^(n − 1) katıdır: 1 el ×1, 2 el ×1,50, 3 ve 4 el ×1,69, 6 el ×1,42, 8 el ×1,07 (K21'de 4 el ×1,16, 8 el ×1,40). Mevsim havası inşayı yazın ×0,89, güzün ×0,97, kışın ×0,94 çarpar. Simin geçici kopyası kurma katsayısını K50'den alınca (proje dosyası değişmedi):

| Kademe | Bugünkü koşu (K21, 4 el ×1,16) | K50, 4 el (×1,69) | Fark | K50, 8 el (×1,07) | «Gece dinlenilsin», K50 4 el | Hedef |
|---|---|---|---|---|---|---|
| T1 Ocak | 2,2 | 2,3 | +0,1 | 2,2 | 3,0 | 2–5 |
| T2 Oba | 3,0 | 3,4 | +0,4 | 2,9 | 4,1 | 2,5–7 |
| T3 Boy Yurdu | 7,2 | 7,8 | +0,6 | 7,1 | 9,2 | 3–8 |
| T4 Toy Yeri | 4,6 | 4,9 | +0,3 | 4,5 | 5,5 | 4–9 |
| T5 Surlu Avlu | 8,1 | 8,6 | +0,5 | 7,9 | 9,7 | 4–12 |
| T5 Göçer Avlu | 7,8 | 8,1 | +0,3 | 7,7 | 8,8 | 4–12 |

Kurma el·günü 4 elle ≈%45 artar (Surlu 112,3 → 163,0, Göçer 67,7 → 98,2), ama kademe gününün çoğu toplamadır: gün 0,1–0,6 uzar, bütün kademeler hedefte kalır. Sınırda T3 vardır: 7,8 gün, üst uca 0,2 gün. Mete'nin dakikası 0,1–0,3 artar (meşale). Eğrinin oyuncu yüzü yurdun kendisidir: Yüklü Hane yurdunu 3 elle 33,75 dk'da, II açılışında Mete ve ilk onluk 8 elle 8,0 dk'da kurar.

**Kâhya'nın şantiye eli** ([K80](/docs/source/design/decisions#k80)). Kâhya sıradaki şantiyeyi yapının el tavanına dek doldurur, sonra sıradakine geçer: Küçük Yurt 6, Hane Yurdu ve yurt gövdeli yapılar 8, Otağ ve Bey Otağı 12 el (katsayı 8'de durur, 9.–12. eller malı ambardan taşır). Oyuncu el kilidiyle (+ / −) şantiye başına eli sınırlar, tek elli şantiyeleri çoğaltabilir. Neden: yurtta 8 elin el başına verimi 0,94, 3–4 elinki 0,59'dur; kural yurdu en çabuk bitirir ve oyuncu kişi arttıkça sürenin kısaldığını görür. Bedeli küçük yapılardadır: el tavanı 2–6 olan yapıda verim 0,59–0,70'e iner, bunlar yerleşim emeğinin küçük payıdır. Sabit 4 el yurtta en pahalı ekiptir, modelin «tipik 4 el» alanı bu yüzden kalktı ve yalnız bugünkü koşunun girdisi olarak durur. Tablonun iki ucu (bütün şantiyeler 4 elle ve 8 elle; T3 7,8 ve 7,1 gün) kuralın kendisi değildir, ikisi de hedeftedir. Kuralın şantiyedeki hâli: [İnşa ve Emek](/docs/buildings/construction-labour).

Doğrulanacak: Kâhya kuralının kademe günü; sim inşaat eğrisini, Kâhya kuralını ve şantiyenin günlük `k(W) × 24` İS ilerlemesini uygulayınca bu sayfanın tabloları yeniden basılır ([Yol Haritası](/roadmap#item-econ-sim-run)).

## Kış payı

Kış bilerek dardır (K24). Yaz ve güz artığının %35'i, soğum etinin %65'i kışa kalır. Ordugâh 16 Kasım–15 Mart arası kendiliğinden dağılır, kışın Ordu Payı ×0,1'dir; bu oyuncunun kolu değildir. %75'in altı çözülemez açlıktır, %115'in üstü gerilimsiz kıştır.

| Kademe | Hane, kişi | Ordu Payı yaz / kış | Pay/gün yaz / kış | Yaz | Kış | Kış + saklanan |
|---|---|---|---|---|---|---|
| T1 Ocak | 3, 15 | 1 / 0,1 | 14 / 13 | %159 | %74 | %97 |
| T2 Oba | 10, 50 | 10 / 1 | 53 / 44 | %139 | %73 | %87 |
| T3 Boy Yurdu | 22, 110 | 20 / 2 | 115 / 97 | %141 | %73 | %89 |
| T4 Toy Yeri | 45, 225 | 40 / 4 | 234 / 198 | %142 | %73 | %89 |
| T5 Surlu, V | 80, 400 | 60 / 6 | 404 / 350 | %146 | %73 | %91 |
| T5 Surlu, VI'dan tarla ve kuleyle | 80, 400 | 60 / 6 | 404 / 350 | %146 | %73 | %102 |
| T5 Göçer | 80, 400 | 66 / 6,6 | 410 / 351 | %144 | %73 | %90 |
| T5 Göçer, sürü tavanı ×1,2 | 80, 400 | 66 / 6,6 | 410 / 351 | %170 | %82 | %113 |

Yakacak her kademede %182'dir. Derin kar Tanhu Ordusu'nun kışında günlerin %16,0'ıdır; Kar Kabuğu kış başına 0,62 olay, günlerin %2,0'ıdır (hava modeli, K49). Yem/gün Yem Bağı ölçüsüdür (2 Ot = 1 Bağ), kış otu bir kışın Ot sayısıdır:

| Kademe | Yem/gün | Derin kar günü | Kış otu | Ot İG |
|---|---|---|---|---|
| T1 Ocak | 7 | 33 | 2.565 | 160 |
| T2 Oba | 22 | 109 | 8.551 | 534 |
| T3 Boy Yurdu | 48 | 239 | 18.813 | 1.175 |
| T4 Toy Yeri | 98 | 488 | 38.480 | 2.404 |
| T5 Surlu, Göçer | 174 | 868 | 68.410 | 4.273 |
| T5 Göçer, sürü tavanı ×1,2 | 201 | 1.034 | 80.172 | 5.008 |

**Surlu:** altı tarla mevsimde 3.000 Darı (1.500 öğün) verir, Tahıl Kulesi kuru erzakın %50'sini kışa geçirir. V'in kışı tarlasızdır ([K54](/docs/source/design/decisions#k54)): Surlu 20 Kasım 201'den sonra seçilir, tarla kar altında boş durur, kulenin %50'si de ilk güzden sonra işler; %102 VI'dan yazılır. **Göçer:** sürü tavanı ×1,2'dir (×1,25'te kış %118 olur, bandı aşardı). Surlu emek ve odunla öder, Göçer sürünün büyümesini bekler.

Açığı oyuncu kapatır. On avcılık sürek avı kolu kışın günde ≈83 öğün getirir; bu aynı zamanda ordunun talimidir.

| Kademe | Açık (öğün/gün) | Sürek avı kolu | Ya da Arpa Torbası/gün |
|---|---|---|---|
| T1 | 0,4 | 0 | 0,1 |
| T2 | 5,6 | 0,07 | 0,9 |
| T3 | 11,1 | 0,13 | 1,8 |
| T4 | 22,0 | 0,27 | 3,7 |
| T5 Surlu | V'te 32,1; VI'dan tarla ve kuleyle 0 | 0,39 | 5,3 |
| T5 Göçer | 35,9 (sürü tavanında 0) | 0,43 | 6,0 |

**Yerleşimin defteri.** Çizgiler ambarın içeriğinden okunur: Yiyecek %100 = 30 gün, Yakacak %100 = 30 gün, Yem %100 = kışın 100 gün, Ok yalnız ordugâhta. Yiyecek emeği çarpar: ≥35 ×1, <35 ×0,85, <15 ×0,7. Yakacak <15 ise kazan yanmaz, çiğ et pay vermez.

## Kış Hesabı (I. Perde teslimi)

Mete'nin rehineyken saydığı üç çizgi: Yakacak, Yiyecek, Yem. Başlangıç 60 / 55 / 65. Her şafakta −8 (Hikâye −6, Zor −10); uykuda atlanan şafak da düşer, Son Gece'de düşmez. Toplamak XP ve Güven vermez, teslim verir. Teslim yerleri: Ambar her şeyi alır, Mutfak su ve yemek, Ahır yem. Hesap Gözü becerisi teslimi ×1,3 yazar.

```varlik
ui_winter_ledger
```

| Teslim | Çizgi | Birim başına |
|---|---|---|
| Çam, Söğüt, Ardıç Odunu | Yakacak | +1,5; +1; +2 |
| Nöbet ateşine odun | Yakacak | +1 |
| Dal, Tezek, Kömür | Yakacak | +0,25; +0,5; +2 |
| Dolu Tulum | Yiyecek | +2,5 |
| Balık | Yiyecek | +1,25 |
| Et, Aş, Kak, Kurut, Darı, Arpa Torbası | Yiyecek | +2; +1,25; +1,25; +0,5; +0,5; +4 |
| Ot, Saman, Yem Bağı | Yem | +1,5; +0,75; +3 |
| Sürü işi, Ot Taşıma işi | Yem | +6; −2 |

| Etki | Okunan | An |
|---|---|---|
| Nöbet ateşi yarıçapı 6–12 m | Yakacak 60–100 arası | Canlı |
| Güven ve kase | Yiyecek | Canlı |
| Toy'da Kut +1 | Üçü de 100 | Toy |
| Takipçi at hızı +0,5 ya da −0,5 m/sn | Toy'daki Yem ≥100; canlı Yem ≤40 | Toy'da donar; Son Gece canlı |
| Akın | Tahıl kurtarıldıysa −10, yoksa −25; Ambar Eskam'a gösterildiyse −20 | Sazlık Yanıyor, Elçi |
| Son kart: ≥35 Kışlak bahara çıkar | Yiyecek | Adak Aygırı görevinin başı |

Senaryolar (Toy'da Yakacak / Yiyecek / Yem; sağ üç sütun Gün V Yiyeceği). Kalın, 35 eşiğine en yakın sonuçtur.

| Oyuncu | Toy | Tahıl kurtarıldı | Korumasız | Korumasız, Ambar görüldü |
|---|---|---|---|---|
| Hiç iş yok | 36 / 31 / 41 | 13 | 0 | 0 |
| Günde 2 iş | 56 / 41 / 45 | 23 | 8 | 0 |
| Günde 3 iş, karışık | 62 / 46 / 51 | **28** | 13 | 0 |
| Ve Balık Delikleri, 3 sabah | 62 / 61 / 51 | **43** | 28 | 8 |
| Ve Erzak Yolu, 3 kez | 98 / 76 / 51 | 58 | **43** | 23 |
| Ve Hesap Gözü | 100 / 90 / 55 | 72 | 57 | **37** |
| Araba seferleriyle tam | 100 / 100 / 100 | 82 | 67 | 47 |

Tam hesap ek ≈13 dk ister, Kut +1 verir, Yem 100 ile takipçiyi hızlandırır: tam oyuncu en iyi kovalanandır. Hiç iş yapmayan Son Gece Yem 33'tedir, takipçi yavaşlar.

## Hanenin bir günü

Hane bir yurt, beş kişidir: iki yetişkin, bir genç (çırak, 0,75), bir yaşlı (0,5), bir çocuk (iş vermez). 4,3 öğün yer, 3 birim yakacak yakar (kışın 3,5: uzun gece ve ışık; ısınma yok, K1). Sürüsü ≈18 at eşdeğeridir. Üretim ve ev işi 16 saatlik penceredir, çobanlık 24 saattir. İS/gün, bir hane; «ev işi» savaş mevsiminin nöbetiyle hesaplıdır.

| Mevsim | Emek | Ev işi | Yapıya kalan | Pay | Çobanlık | Sağım | Kırkım | Tezek | Aş | Ot | Nöbet barış / savaş |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Bahar | 46,2 | 25,3 | 20,9 | %45 | 15,5 | 0,8 | 0,3 | 3,0 | 2,0 | 0,0 | 1,8 / 3,6 |
| Yaz | 47,5 | 27,9 | 19,5 | %41 | 15,5 | 1,6 | 0,0 | 3,0 | 2,0 | 1,9 | 1,9 / 3,8 |
| Güz | 42,9 | 37,8 | 5,1 | %12 | 15,5 | 1,0 | 0,1 | 3,0 | 2,0 | 12,8 | 1,6 / 3,3 |
| Kış | 41,6 | 24,2 | 17,4 | %42 | 15,5 | 0,0 | 0,0 | 3,5 | 2,0 | 0,0 | 1,6 / 3,1 |

Kesim her mevsimde 0,1 İS'tir. En dar mevsim güzdür: ot biçimi takvimdedir (8 Ağustos–15 Kasım, 100 gün), pencere günü hane başına 12,8 İS ot biçer ve yapıya %12 kalır; yazın yalnız pencerenin ilk günleri düşer (ortalama 1,9). Şantiyeye verilen işçi ışıklı gece işinde günde 24 İS verir: inşaat üretimden hızlıdır, bedeli meşaledir.

## Akın

Akın yalnız ay penceresinde gelir: ay ≥0,97 dolu, ayda ≈3 gün ([K55](/docs/source/design/decisions#k55); SJ 110 月盛壯則攻戰). Dailin (16 Eylül 208) ve Lung-çeng (17 Haziran 205, 25 Haziran 203) günü akın yazılmaz. Başarı R ÷ (R + D)'dir, rastgele yoktur: aynı kayıt aynı akını verir. R akın gücüdür. D = nöbetçi × (1 + 0,5 × kule) + garnizon; garnizon zondaki İş Kolu erleri (5 / 15 / 20 / 30 / 50) ve zondaysa Mete'nin birliğidir; nöbetçi savaş mevsiminde 4 hanede 1'dir. Surlu ×0,5. Başarılı akında kaplar %30 (Tahıl Kulesi %10) yitirir, bulunmayan Ambar Çukuru kalır: tek akının kaybı = başarı × 0,3 × 0,7. Akın D'si küçük yere gider.

| Perde | Pencere | Tavan: yerleşim / ordugâh | R: yerleşim / ordugâh | D | Başarı | Tek akının kaybı | Ambarcıyla | Tavanda perde kaybı | Garnizonsuz, tek akın |
|---|---|---|---|---|---|---|---|---|---|
| II | Yok: Teoman'ın barışı | 0 / 0 | 0 / 0 | – | – | – | – | %0 | – |
| III | 15–17 Eylül 208 (16'sı Dailin) | 2 / 1 | 6 / 4; Tunghu toprağı kazanılınca 0 | 26,0 | %18,8 | %3,9 | %3,0 | %7,9 | %10,5 |
| IV | 16–18 Haziran 205, 24–26 Haziran 203 (17'si ve 25'i Lung-çeng) | 2 / 1 | 10 / 6; Yüeçi sürülünce (17 Haziran 205) 6 / 4; Loufan ve Baiyang katılınca (25 Haziran 203) 0 | 50,9 | %16,4 | %3,4 | %2,6 | %6,9 | %6,8 |
| V Surlu | 27–29 Kasım 201 kuşatmaya düşer; perdeden sonra 27–29 Aralık 201 | Perdeden sonra 1 / yok | 16 / yok; Baideng'den sonra 8 | 112,5 | %6,2; R 8'de %3,3 | %1,3; R 8'de %0,7 | %1,0 | Perdede %0; Serbest Dolaşım'da %0,7 | %2,1 |
| V Göçer | Aynı | Perdeden sonra 1 / yok | 16 / yok; Baideng'den sonra 8 | 104,7 | %13,3; R 8'de %7,1 | %2,8; R 8'de %1,5 | %2,1 | Perdede %0; Serbest Dolaşım'da %1,5 | %4,8 |
| VI | Yok: heqin | 0 / 0 | 0 / 0 | – | – | – | – | %0 | – |

- **Beklenen.** Oynanan takvimle beklenen akın III'te 1, IV'te 1–2, V'te 0'dır: beklenen kayıp III %3,9, IV %3,4–6,9. Hepsi ≤%10 hedefindedir, Ambarcısız. Ambarcı ([Moyan](/encyclopedia/moyan)) kap kaybını ×0,75 yapar, başarıya dokunmaz.
- **Garnizonsuz.** İş Kolu seferde ve Mete uzaktayken III'te D 6,0, başarı %50, tek akının kaybı %10,5 (tavanda %21). Bu yerleşimi boş bırakmanın bedelidir, bilerek bırakıldı, hedefe sayılmaz.
- **Ürün ve ganimet.** Haziran–Eylül arası başarılı yerleşim akını Surlu'nun güz ürününün %30'unu çiğner (K54). Def edilen akın Gönül +1; düşenler ganimeti ×0,6 verir, küçük akında «Paylaş» sayılır ([Toplama ve Kaynaklar](/docs/economy/gathering#savas-ganimeti)).

Doğrulanacak: IV satırının başarı ve kayıp sütunları R 10 iledir, çünkü sim akını perdenin başındaki güçle sayar; K55'in sırasıyla 24 Haziran 203'ün akını R 6 ile gelir, 26 Haziran'da R 0'dır. Sütunlar simin yeni sırayla koşusundan basılır ([Yol Haritası](/roadmap#item-econ-sim-run)).

**Ordugâh akını «Gece Akını / Night Raid»** (K55). Yalnız III ve IV'te, perde başına en çok 1; güç R × 0,6, yukarı yuvarlanır (III 4, IV 6 atlı); hedef yalnız at hattıdır, ambar, ok ve çadır etkilenmez. Tam ordugâhta başarı: Yüzlük R 6'da %5,2; Binlik (200 atlı, 2 kule) R 4'te %1,6, R 6'da %2,4; 400 atlıda %1,2. Birlik seferdeyken kalan bekçi Onluk'ta %25–35. Ordugâhın D'si yerleşiminkinden büyüktür (III'te 240 ve 26): akın yerleşime gider, ordugâh ancak birlik seferdeyken hedef olur. Başarılıysa her akıncı bir at götürür, 60 sn içinde At Çağrısı ile yakalanan döner, birlik moral −2. Püskürtülünce Mete oradaysa ≤6 atlıyla küçük dövüş olur (3 düşünce ya da 45 sn sonra dağılırlar), moral +2, sadakat +1; uzaktaysa kart. Uyarı üç kanaldandır (boru, bildirim, atlas): Konak ≈44 sn, Kule ≈33 sn, köpek ≈20 sn önce. Pencere açılırken Kâhya: «Ay doluyor. Atları içeri alın.» / «The moon is filling. Bring the horses in.»

## Econ-sim sonuçları

Sim şunları sınar: model tutarlılığı, malzeme saniyesi, tarif Kıymeti, yapı dakikası ve İG, kademe günü ve dakikası, yaz ve kış payı, perde dakikası, akın kaybı, I. Perde sözleşmesi ve her malın o perde ve mevsimde bir kaynağı olması (yün kırkım tarihinden, külçe Demirci Ocağı'ndan; hiçbir kademe kabuk istemez).

**Perde akışı** (Mete'nin kendi teçhizatı ve kademe payı, gerçek dk):

| Perde | Mete payı | Teçhizat dk | Teçhizat işçi İG | Kademe dk | Toplam dk | Tavan | 420 dk içinde |
|---|---|---|---|---|---|---|---|
| II | %60 | 8,7 | 10,8 | 53,9 | 62,6 | 105 | %15 |
| III | %45 | 17,7 | 28,0 | 35,8 | 53,5 | 105 | %13 |
| IV | %35 | 17,4 | 33,4 | 26,6 | 44,0 | 95 | %10 |
| V | %25 | 19,7 | 49,6 | 27,0 | 46,7 | 85 | %11 |
| VI | %15 | 2,2 | 10,2 | 0,0 | 2,2 | 70 | %1 |

V satırı iki yolun büyüğüdür (Surlu); Göçer 24,9 kademe dk, toplam 44,6. Perde ≈420 dk K25'in tasarım ölçüsüdür. Ganimetin, kabuğun ve Gecelik Kamp'ın dakikası tabloda yoktur: ganimet emek değildir, kamp `T` ile ≈25 sn'dir.

**Yiyecek.** Çizgi %100 = 30 gün. Bütün kademelerde emek çarpanı 1'de kalır.

| Kademe | Açılış | Öğün | Gün | Çizgi | Av kolu el·gün | Sonda gün |
|---|---|---|---|---|---|---|
| T1 Ocak | Armağan (217) ve gelen hane (66) | 283 | 20,4 | %68 | 0 | 20,7 |
| T2 Oba | Önceki kademe | 376 | 12,1 | %40 | 8,8 | 10,9 |
| T3 Boy Yurdu | Kronik: 15 gün ve saklanan | 1.694 | 19,4 | %65 | 0 | 16,0 |
| T4 Toy Yeri | Kronik: 15 gün ve saklanan | 2.000 | 17,5 | %58 | 15,9 | 12,8 |
| T5 Surlu | Kronik: kış stoğu | 3.583 | 18,1 | %60 | 98,6 | 13,1 |
| T5 Göçer | Kronik: kış stoğu | 3.583 | 18,1 | %60 | 95,6 | 13,1 |

Armağansız açılışta çizgi %16'ya iner, emek çarpanı en az 0,85 olur, Kâhya 5,8 el·gün av kolu açar, T1'in emek günü 1,8'den 2,7'ye çıkar. **Yün:** II'de birikimli talep 56 ve 130, kaynak 72 ve 194; III talep 277, kaynak 502. **Demir:** T1'in 2 külçesi armağandan, T2'nin 6 külçesinin 4'ü armağandan, 2'si ocaktan. Armağansız ve satıcısız ilk ocak 4 Demir Hurda ile kurulur.

**Simin öteki sınırları** (sim prototipin kodudur, bu turda değişmez):

- Doğrulanacak: ganimetin sürü Kıymeti; sim at ve sığırı koddaki sabitle (336, 120) sayar ve Han arabasını 188,7 basar, doğrusu ekonomi modelinin fiyatıyla 296,7'dir ([Yol Haritası](/roadmap#item-econ-sim-run)).
- Doğrulanacak: akın sıklığı; sim ay kapısını okumaz, perde tavanındaki en kötü akın sayısını sayar (III 2, IV 2, V 1) ([Yol Haritası](/roadmap#item-econ-sim-run)).
- Doğrulanacak: Godot ekonomisi bu çıktıyla `--strict` toleransında aynıdır ([Yol Haritası](/roadmap#item-settlement-measure)).

Kronik ve ordugâh tabloları: [economy.md §10.8](/docs/source/design/economy#10-8-denge-modeli), [settlement.md §4.2](/docs/source/design/settlement#4-2-tam-bilesim). Sayı değiştirmenin yolu: modeli değiştir, simi koş, işaret yoksa belgenin tablolarını yeniden bas.

## Oyunda şu an

> [!DURUM]
> Godot'da: oyuncunun gördüğü ekonomi yok; bu sayfanın sayıları oynanan bir oyunla ölçülmedi, prototipin benzetim modelidir.
>
> Prototipte denendi: Kış Hesabı defteri ve ambar kipi, Tokluk, Ordu Payı hesabı, Kronik'in yıl adımı. Godot'a taşınmadı.
>
> Godot'daki plan: ekonomi verisi ekonomi modelinden (`d2/econ-model.json`) dışa aktarılır, kimlikler aynı kalır; Godot ekonomisi simin çıktısıyla toleransta aynı olmalıdır ([K49](/docs/source/design/decisions#k49)). Simin resmî koşusu ve yerleşim ölçümleri II. Perde'nin yerleşim fazındadır:

```ilerleme
act-2-p2
```

## Kaynaklar

- [d2/core.md §5.8: Denge hedefleri](/docs/source/design/d2/core#5-8-denge-hedefleri)
- [d2/core.md §5.9: Model ve benzetim](/docs/source/design/d2/core#5-9-model-ve-benzetim)
- [d2/core.md §7.1: Doğrulama turu](/docs/source/design/d2/core#7-1-dogrulama-turu-2026-11-03-v1-v39)
- [economy.md §7: Kış Hesabı teslimi](/docs/source/design/economy#7-kis-hesabi-teslimi)
- [economy.md §7.1: Yerleşimin ve ordugâhın Kış Hesabı](/docs/source/design/economy#7-1-yerlesimin-ve-ordugahin-kis-hesabi-k23-k24)
- [economy.md §8.5: Hane, Ordu Payı, ordugâh](/docs/source/design/economy#8-5-hane-ordu-payi-ordugah-k23-k24)
- [economy.md §10.4: II. Perde ve sonrası hedefleri](/docs/source/design/economy#10-4-ii-perde-ve-sonrasi-hedefleri-k24)
- [economy.md §10.6: Kademeler](/docs/source/design/economy#10-6-kademeler), [§10.7: Perde akışı](/docs/source/design/economy#10-7-perde-akisi), [§10.8: Denge modeli](/docs/source/design/economy#10-8-denge-modeli)
- [structures.md §2.4: Emek yasası](/docs/source/design/structures#2-4-emek-yasasi-labour-law-k21) (yurt eğrisi, Kâhya'nın şantiye eli)
- [settlement.md §4.2: Tam bileşim](/docs/source/design/settlement#4-2-tam-bilesim), [§6.2: Kâhya](/docs/source/design/settlement#6-2-kahya-steward), [§15.4: Baskın](/docs/source/design/settlement#15-4-baskin)
- [d3/oyun-durumu.md](/docs/source/design/d3/game-state)
- Kararlar: [K21](/docs/source/design/decisions#k21), [K24](/docs/source/design/decisions#k24), [K25](/docs/source/design/decisions#k25), [K42](/docs/source/design/decisions#k42), [K49](/docs/source/design/decisions#k49), [K50](/docs/source/design/decisions#k50), [K52](/docs/source/design/decisions#k52), [K53](/docs/source/design/decisions#k53), [K54](/docs/source/design/decisions#k54), [K55](/docs/source/design/decisions#k55), [K80](/docs/source/design/decisions#k80)
- İlgili: [Obadan Hanlığa](/docs/settlement/encampment), [Haneler ve Kâhya](/docs/settlement/households), [Üretim ve Depolama](/docs/settlement/production-storage), [İnşa ve Emek](/docs/buildings/construction-labour)
- Önceki: [Para ve Satıcılar](/docs/economy/money-traders)
