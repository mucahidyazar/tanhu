---
title: Yapı Kataloğu
order: 30
status: kismen
summary: 'Yurt dışındaki yapılar da malzemeyle ve yurdun emek eğrisiyle kurulur; sürü, ambar, atölye, savunma, araba ve avlu yapılarının kademesi, malzemesi, emeği, süresi ve işi tek sayfada.'
sources:
  - docs/design/settlement.md
  - docs/design/structures.md
  - docs/design/economy.md
  - docs/design/decisions.md
  - docs/design/d2/labour-model.json
  - docs/design/d2/settlement-model.json
  - docs/design/travel.md
  - docs/design/progression.md
  - docs/design/d3/oyun-durumu.md
  - game/scripts/camp/stable.gd
---

Yerleşim yalnız yurttan oluşmaz. Ahır atları, ağıl sürüyü, ambar malı, atölye zanaatı, kule ve sur baskını karşılar. Oyuncu bu yapıları II. Perde'den Plan Kipi'yle (`P`) yerleştirir, halk malzeme ve emekle kurar (K23, K24); I. Perde'de Plan Kipi kapalıdır. Hepsi aşamalıdır, hasarda geri düşer ([Hasar ve Onarım](/docs/buildings/damage-repair)).

> [!NOT]
> «yine yurtlar, yerleşim yerindeki diğer gerekli birimler malzemeler ile kurulacak»

Bu notun karşılığı K24'tür: her yapının malzemesi vardır, malzeme toplamadan, avdan ve savaştan gelir, bir kısmı zanaatla yapılır; zanaat ve kurma tek emek havuzundan ödenir ([K24](/docs/source/design/decisions#k24)). Kurma süresi yurdunkiyle aynı eğridir ([K50](/docs/source/design/decisions#k50)).

**Tabloları okuma.**

- **Kademe:** yerleşim kademesi: 1 Ocak, 2 Oba, 3 Boy Yurdu, 4 Toy Yeri, 5 Tanhu Avlusu; V. Perde'de Surlu ya da Göçer yol seçilir ([Obadan Hanlığa](/docs/settlement/encampment)). Kademesi gelmemiş yapının kartı Plan Kipi'nde kilitli görünür.
- **Malzeme:** II. Perde'nin parça biçimi. Odun her tür kütüğü karşılar.
- **Emek:** tek işçinin İG'si (iş günü: 1.440 İD, tek işçiyle 60 gerçek dk; İD iş dakikasıdır, bir işçinin bir oyun dakikası).
- **Süre:** gerçek dakika, 1 el / 4 el / en çok el; parantezde o el sayısı. Eğri K50'dir: tek el İD / 24 × 0,75^(el − 1); el yapının tavanına ve 8'e dek sayılır. Usta var, gündüz, açık hava ([İnşa ve Emek](/docs/buildings/construction-labour)). Kâhya şantiyeyi el tavanına dek doldurur ([K80](/docs/source/design/decisions#k80)).

Bir yapının zanaatından usta yoksa oran ×0,7'dir. Her yetişkin Ev zanaatında ustadır; Ağaç ve Toprak işi usta ister.

## Sürü ve at

Ahır Ağaç, ötekiler Ev zanaatıdır.

| Yapı | Kademe | Malzeme | Emek | Süre | İşi |
|---|---|---|---|---|---|
| Ahır / Stable | 2 | 4 taş, 18 odun, 4 ip, 10 saz, 3 keçe | 1,5 | 90,0 / 38,0 / 21,4 (6) | 8 at, tımar, eyer ve koşum, kışın yem tezgâhı |
| Ağıl / Pen, 40 m | 1 | 10 odun, 72 dal, 1 ip | 0,32 | 19,6 / 8,3 / 2,6 (8) | 90 küçükbaş ya da 15 sığır; kurt kaybını keser |
| Çit / Fence, 10 m | 1 | 6 odun, 2 ip | 0,075 | 4,5 / 1,9 / 1,4 (5) | Yol ve sınır |
| At Hattı / Horse Line, 20 m | 1 | 6 odun, 4 ip | 0,08 | 4,8 / 2,0 / 2,0 (4) | 20 binek atı; gök gürültüsünde ürkme kaybını keser |

Ahır yurttan ağırdır: yurt hazır parçayla kurulur, ahırın direk çukuru, tahta duvarı ve çatısı yerinde biçilir. Beş aşamadır: Zemin ve Oluk, Direk, Bölme ve Duvar, Kiriş, Çatı. Tek el 2.160 İD'dir, en çok 6 el çalışır: 1 / 2 / 4 / 6 elle 90,0 / 67,5 / 38,0 / 21,4 dk (K21'de 90,0 / 44,4 / 24,5 / 20,0). Ana kamptaki ahırın çatısı tahtadır (toplam 32 odun, saz ve keçe yok); Kışlak'ta saz ve keçedir. Korkuluk düşünce atlar ürker. Adak Ağılı 148 m'dir (66 pano ve kapı): tek el 1.592 İD, 1 / 4 / 8 elle 66,3 / 28,0 / 8,9 dk (K21'de 66,3 / 19,6 / 12,2). Ağıl kapısı `E` ile ya da atla açılır; kırık pano sürüyü salar.

**Kuşhane / Mews** (kademe 3, IV. Perde'den, kuşçu [Sungur](/encyclopedia/sungur) gelince; 0,12 İG; 6 odun, 2 ip, 2 keçe, 1 deri) doğanın (IV) ve kartalın (V) yeridir. Bir kuşçuyla güz ve kışta günde 0,25 tilki kürkü ve 0,5 küçük deri getirir, yiyeceğe etkisi yoktur ([Hayvanlar](/docs/world/animals)).

![Ahır (prototip, ana kamp)](/media/docs/research/p6-shots/p61_ref_s_ext.png)

![Ahır, kesit: yemlik, eyer, fener, bağlı atlar (prototip)](/media/docs/research/p6-shots/smoke2-stable-rail.png)

```varlik
stable, pen, fence, horse_line, mews
```

## Ambar

Ambar Çukuru Toprak, Ambar Yurdu Ev, ötekiler Ağaç zanaatıdır. Başarılı akında kap başına kayıp: Ambar Yurdu, Sundurma ve Tahıl Ambarı %30; Hazine %30 (30 m içinde Gözcü Kulesi varsa ×0,5), Hazine'deki kabuğun da %30'u; Tahıl Kulesi %10. Ambar Çukuru %50 olasılıkla bulunur, bulunursa %30'u gider; yanmaz (K24). Ambarcı kap kaybını ×0,75 yapar, başarıya dokunmaz (K55). Ot sundurması tutuşursa içi bütünüyle gider; ambar yapısı aşama 2'nin altına inerse içeriği yer yığınına döner.

| Yapı | Kademe | Malzeme | Emek | Süre | İşi |
|---|---|---|---|---|---|
| Ambar Çukuru / Grain Pit | 1 | 2 taş, 2 odun, 2 keçe, 1 ham deri, 2 kil | 0,3 | 18,0 / 7,6 / 7,6 (4) | 120 Yük, yalnız yiyecek ve tahıl; gizli |
| Ambar Yurdu / Store Yurt | 2 | Yurt, köz yok | 0,99 | 59,2 / 25,0 / 7,9 (8) | 400 Yük, genel ambar; içi Yük Düzeni |
| Sundurma / Shed | 2 | 2 taş, 7 odun, 4 ip, 6 dal, 8 saz | 0,6 | 36,0 / 15,2 / 15,2 (4) | 500 Yük: ot, yem, kütük, kömür |
| Tahıl Ambarı / Granary | 3 | Sundurma + 4 kil | 0,8 | 48,0 / 20,3 / 11,4 (6) | 600 Yük, yiyecek |
| Hazine / Treasury | 4 | 8 taş, 16 odun, 4 ip, 2 keçe, 2 kil, 1 tunç külçe | 1,2 | 72,0 / 30,4 / 17,1 (6) | 120 Yük, yalnız değerli mal; kilit düşmeden açılmaz |
| Tahıl Kulesi / Grain Tower | 5, Surlu | 6 taş, 24 odun, 6 ip, 10 saz, 4 kil | 2 | 120,0 / 50,6 / 28,5 (6) | 800 Yük, yiyecek; yaz ve güz artığının %50'si kışa kalır (öteki yerlerde %35) |

```varlik
grain_pit, store_yurt, shed, granary, treasury, granary_tower
```

## Atölyeler

Tablodaki el sayısı kurulum içindir. Tezgâhta çalışan el ayrıdır ve K21'in eğrisiyle işler: Keçe Avlusu 6, Sepi Yeri 3, Ağaç Atölyesi 3, Demirci Ocağı 3, Fırın 2, Okçu Yurdu 3 el ([Zanaat](/docs/economy/crafting); [economy.md §6.7](/docs/source/design/economy#6-7-tezgahlar-ve-iki-hiz-k24)). Keçe Avlusu, Sepi Yeri ve Okçu Yurdu Ev; Ağaç Atölyesi Ağaç; Demirci Ocağı ve Fırın Toprak zanaatıdır. Kazan Ocağı yapı değildir: kazanı olan her yurt ocağıdır.

| Yapı | Kademe | Malzeme | Emek | Süre | İşi |
|---|---|---|---|---|---|
| Keçe Avlusu / Felting Yard | 1 | 1 çiy, 4 odun, 4 ip, 2 keçe | 0,5 | 30,0 / 12,7 / 7,1 (6) | Keçe, ak keçe, çiy, eyer keçesi |
| Ağaç Atölyesi / Woodshop | 2 (Oba); kartı Ocak'ta kilitli | 2 taş, 12 odun, 4 ip, 1 demir külçe, 8 saz | 0,8 | 48,0 / 20,3 / 11,4 (6) | Sırık, bosağa, iki boyda kerege takımı ve uuk demeti, tündük, ulu tündük, teker çifti, eyer ağacı |
| Sepi Yeri / Tannery | 2, su en çok 100 m | 6 odun, 4 ip, 2 taş, 1 küçük kazan, 4 saz | 0,4 | 24,0 / 10,1 / 10,1 (4) | Sepi deri, tutkal, ahşap eyer |
| Demirci Ocağı / Smithy | 2 | 8 taş, 6 kil, 2 sepi deri, 6 odun, 1 demir külçe ya da 4 demir hurda, 6 saz | 1,5 | 90,0 / 38,0 / 21,4 (6) | Demir, tunç, kazan, uç, alet; IV'ten tunç kabuk. İlk ocak külçesiz kurulur |
| Fırın / Kiln | 2 | 6 taş, 8 kil | 0,6 | 36,0 / 15,2 / 15,2 (4) | Kömür |
| Okçu Yurdu / Fletcher's Yurt | 3 | Yurt, köz yok, + 4 odun | 1,2 | 72,0 / 30,4 / 9,6 (8) | Ok, yay; yaycı III. Perde'de gelir |

**Ağaç Atölyesi Oba'da açılır ([K52](/docs/source/design/decisions#k52)).** Ocak'ta atölye yoktur, tündük Tanhu pazarcısından iki günde bir gelir. Dülger [Ruodi](/encyclopedia/ruodi) II. Perde'nin ilk aileleriyle gelir, atölyeyi Oba açılınca kurar; armağanın altı demir külçesi atölyeye ve demirci gelmeden kurulan iki yurdun bosağasına yeter. Plan Kipi'nde kartı Ocak'ta kilitli görünür: «Oba'da açılır.» / «Opens with the Clan Camp.»

**Zanaatçılar** ([economy.md §6.8](/docs/source/design/economy#6-8-zanaatcilar)). Keçeci I. Perde'de Nanay'ın avlusundadır, II'de her hanede. Dülger II'de hikâye hanesiyle, Arabacı III'te, Demirci I. Perde'de [Kujul](/encyclopedia/kujul) olarak, II'de Oba göreviyle, Yaycı III'te, Saraç IV'te, Aşçı II'de, Toprak Ustası V'te Surlu yolun sığınanıyla gelir. Kendi zanaatında 120 İS çalışan (≈8 oyun günü) ya da hikâyeyle gelen usta olur.

```varlik
felt_yard, tannery, wood_shop, smithy, kiln, fletchery
```

## Kule ve sur

Kule, Sur Kapısı ve Çit Halkası Ağaç; sur Toprak zanaatıdır. Baskında savunma D = nöbetçi × (1 + 0,5 × kule) + garnizon; başarı R / (R + D); kapalı sur halkası akının başarı payını ×0,5 yapar (K24).

| Yapı | Kademe | Malzeme | Emek | Süre | İşi |
|---|---|---|---|---|---|
| Gözcü Kulesi / Watchtower | 3 | 4 taş, 20 odun, 4 ip, 2 ham deri | 1,5 | 90,0 / 38,0 / 38,0 (4) | Görüş 300 m, baskın uyarısı, 2 nöbetçi. Yıldırım adayı |
| Gözcü Konağı / Watch Post | 3, zon kenarı | 8 odun, 2 sırık, 4 ip, 3 keçe (çadır ve alçak kule) | 0,4 | 24,0 / 10,1 / 10,1 (4) | Görüş 400 m, erken uyarı, kervan güvenliği, 2 nöbetçi |
| Sur ve Hendek / Rampart and Ditch, 10 m | 5, Surlu | 2 taş, 16 odun, 10 dal | 0,5 | 30,0 / 12,7 / 4,0 (8) | Kapalı halka akının başarı payını yarıya indirir; ateş işlemez |
| Sur Kapısı / Rampart Gate | 5, Surlu | 6 taş, 24 odun, 4 ip, 2 demir külçe | 1,5 | 90,0 / 38,0 / 21,4 (6) | Sur açıklığı, iki kanat |
| Çit Halkası / Palisade, 10 m | Ordugâh | 8 odun, 1 ip | 0,1 | 6,0 / 2,5 / 1,9 (5) | Sefer ordugâhının çevresi |

**Surlu yol odun ve emekle öder (K52).** Sur parçasının odunu 4'ten 16'ya çıktı: 40 parça (400 m) 640 odun eder. Surlu yol odunu ≈×1,4 ve kurma emeğini ≈×1,7 ister (91,1 ve 54,9 İG); Göçer yol keçeyi ≈×1,6, ipi ≈×1,5 ve demiri ≈×2 ister. İki yolun kademe günü 8,1 ve 7,8'dir: seçim hızla değil malla yapılır. Surlu yolun ham Yük'ü ≈%19 çoktur; fazladan 480 odun IV. Perde'de zonda biter, kereste kervanı ister (≈14 Ordu Arabası seferi). Eski «emek ağır, malzeme hafif» sözü sur odunu 4 iken doğruydu, kalktı.

Shiji Hun evini keçe çadır diye anar; Hanshu 94A, Wei Lü'nün Tanhu'ya kuyu kazmayı, sur kurmayı ve tahılı kulede saklamayı öğütlediğini yazar; geç Hun yerleşimleri (Ivolga) sur, hendek, yarı gömük ev, demir ocağı ve darı tarlası gösterir. Bu yüzden toprak ve kule işleri ayrı zanaat ister ve en çok emeği onlar yer: yerleşim büyüdükçe emek ve usta ihtiyacı birlikte büyür.

```varlik
watch_tower, outpost, rampart, rampart_gate, palisade
```

## Araba

Hepsi Ağaç zanaatıdır. Teker çifti Ağaç Atölyesi'nin usta işidir (10 İS, tezgâh eğrisiyle; iki teker de sert odunsa araba canı +%25), şantiyede yalnız birleştirme yapılır.

| Yapı | Kademe | Malzeme | Emek | Süre | İşi |
|---|---|---|---|---|---|
| Kantu'nun Arabası | I. Perde'de kurulmaz, onarılır | 1 teker çifti, 6 odun, 1 demir külçe, 2 keçe, 2 ip | 0,3 | 18,0 / 7,6 / 7,6 (4) | 40 Yük, 4 yolcu, 1 at |
| Keçe Araba / Felt Cart | 2 | 1 teker çifti, 10 odun, 4 keçe, 2 demir külçe, 2 ip | 0,4 | 24,0 / 10,1 / 10,1 (4) | 60 Yük, 4 yolcu, 1 at |
| Yüksek Teker / High-Wheeled Cart | 3 | 1 teker çifti, 14 odun, 6 keçe, 4 demir külçe, 2 ip | 0,6 | 36,0 / 15,2 / 15,2 (4) | 80 Yük, 6 yolcu, 2 at |
| Ordu Arabası / Army Wagon | 4 | 2 teker çifti, 20 odun, 8 keçe, 6 demir külçe, 4 ip | 1 | 60,0 / 25,3 / 14,2 (6) | 140 Yük, 8 yolcu, 4 at |
| Keçe Göç Arabası / Felt House Wagon | 5, Göçer | 2 teker çifti, 24 odun, 10 keçe, 4 demir külçe, 6 ip | 1,2 | 72,0 / 30,4 / 17,1 (6) | 120 Yük, 6 yolcu, 4 öküz |

**Plan Kipi'nin Araba kartı ([K57](/docs/source/design/decisions#k57)).** Sekizinci kategori açılmaz: Atölye kategorisinde tek kart **Araba / Cart** vardır, tür kartın içinde ◂ ▸ ile seçilir (Q / E nesneyi döndürmeye kalır). Kilit satırları: «Önce Ağaç Atölyesi.» ve «Dülger yok.» Araba **Araba Yeri / Cart Yard**'da kurulur: iş parselinde, Ağaç Atölyesi'ne en çok 30 m uzakta, 6 × 12 m pedli bir yerdir, yapı değildir. Kart yükü, çekeni, yol ve kar hızını, malzemeyi, emeği ve «Boşta {n} · Kervanda {m}» satırını yazar; kurulum ile teker çiftinin tezgâh işi ayrı satırdadır. Biten araba yerleşimin araba listesine girer, çeken hayvan sürüden ayrılır. Kırık araba aynı kartta «Onar»la onarılır; söküm ham malın yarısını verir (K46). [Teoman](/encyclopedia/teoman)'ın Keçe Araba'sı listede başlar: Ocak'ta kart kilitlidir, araba vardır. Tenteli Araba kartta yoktur, V. Perde'de armağandır.

[Kantu](/encyclopedia/kantu)'nun arabası I. Perde'de yalnız kırılır ve onarılır. Sıradan onarım 1 odun ve 1 iptir, emeği 44 İD: Mete ve sürücüyle ≈83 gerçek sn, Onarım becerisiyle ≈41 sn. Kışlak'taki Kırık Tekerlek 2 tomruk, 1 demir pim ve 1 ip ister. Araba kırıkken o yol kapanır: «Araba kırık.» ([Yolculuk](/docs/world/travel)).

```varlik
cart_kantu, cart_felt, cart_high, cart_war, wagon_felt, wheel_pair, chariot_yao
```

## Öteki yapılar

Ayrıntı [settlement.md §7](/docs/source/design/settlement#7-yapi-katalogu) ve [structures.md §4.6](/docs/source/design/structures#4-6-yerlesim-ve-ordugah-yapilari-k23)'dadır. Yurt ve çadır: [Yurtlar ve Çadırlar](/docs/buildings/yurts). Ordugâh yapılarının kademesi ordugâhın kendi basamağıdır (Onluk, Yüzlük, Binlik; [Ordugâh ve Kervanlar](/docs/settlement/war-camp-caravans)).

| Yapı | Kademe | Emek | Süre | İşi |
|---|---|---|---|---|
| Kamış Kulübe / Reed Hut | 1, saz kümesi | 0,5 | 30,0 / 12,7 / 12,7 (4) | Keçesiz geçici konut, ½ hane |
| Yarı Gömük Ev / Pit House | 5, Surlu | 2 | 120,0 / 50,6 / 28,5 (6) | Sığınan hanenin kalıcı evi; İsteyen Hane'ye verilince Gönül +10 (K53) |
| Elçi Yurdu / Envoy Yurt | 3; önkoşul Tanhu Otağı | 1 | 60,0 / 25,3 / 8,0 (8) | Elçi konağı, diplomasi olayları; içi Konuk Düzeni |
| Otacı Yurdu / Healer's Yurt | 4; ordugâhta Binlik | 1 | 60,0 / 25,3 / 8,0 (8) | 8 yaralı, ordugâhta iyileşme ×2 |
| Buyruk Yurdu / Command Yurt | Ordugâh, Yüzlük | 1 | 60,0 / 25,3 / 8,0 (8) | Onbaşı, yüzbaşı ve beyin yurdu; atama yeri |
| Silahlık / Armoury | Ordugâh, Yüzlük | 1,2 | 72,0 / 30,4 / 9,6 (8) | 200 Yük silah ve ok, sadak dolumu |
| Erzak Ambarı / Supply Depot | Ordugâh, Yüzlük | 1,5 | 90,0 / 38,0 / 12,0 (8) | 600 Yük ordugâh ambarı, kapı yanında yük sekisi |
| Talim Alanı / Training Ground | Ordugâh, Onluk | 0,6 | 36,0 / 15,2 / 4,8 (8) | Talim, 6 hedef direği, at yolu |
| Toy Alanı / Gathering Ground | 3 | 0,4 | 24,0 / 10,1 / 3,2 (8) | Toy, Avlu Toplantısı, Dailin Sayımı başı, Kurultay; 120 oturak |
| Takas Yeri / Barter Ground | 3 | 0,5 | 30,0 / 12,7 / 7,1 (6) | Hun gezgininin yeri: III'te 3 günde bir, IV'te 2, V'te 3 günde bir gelir (K81; [Para ve Satıcılar](/docs/economy/money-traders)) |
| Gök Direği / Sky Pole | 3, yalnız Kutlu Tepe | 0,6 | 36,0 / 15,2 / 8,5 (6) | 12 m; Şafak Selamı, yıldırım alameti |
| Sancak Direği / Banner Pole | 1 | 40 İD | 1,7 / – / 1,3 (2) | 10 m; toplanma yeri, ≈9 m içindeki yurtların yerine yıldırımı alır |
| Kuyu / Well | 4 (Kuytu'da 2) | 1 | 60,0 / – / 33,75 (3) | 150 m çevresinde su kuralını sağlar; kazı tek ağızdan |
| Darı Tarlası / Millet Field | 5, yalnız Surlu | 0,5 ekim + 0,5 biçim | Her biri 30,0 / 12,7 / 7,1 (6) | Mevsimde 500 darı; işi Kâhya yapar, kart çıkmaz; ilk ürün VI'da (K54) |
| Kuşhane / Mews | 3, IV'ten | 0,12 | 7,2 tek el | Doğan ve kartal |
| Köprü / Bridge | I. Perde senaryosu | 2 | 120,0 / 50,6 / 16,0 (8) | Eski Köprü 2→5: 1.200 İD, Sazlık'ın 6 eli malzeme gelince ≈11,9 gerçek dk'da kurar |

**Basılı tutma.** Emeği 12 İD ve altındaki yerleştirilebilir şantiye açmaz, oyuncunun basılı tutması emeğin kendisidir (1 gerçek sn = 0,4 İD): Kurutma Sırığı 3,2 İD (8 sn), Yol Kemiği 8 İD (20 sn), Fener Direği 10 İD (25 sn; 8 m ışık, 3 gecede 1 kandil yağı). Gecelik Çadır 43,2 İD ile küçük bir şantiye açar ([Gecelik Kamp](/docs/gameplay/overnight-camp)).

**Yer seçme** ([Plan Kipi](/docs/settlement/plan-mode)). Yürüme ızgarasında kapalı hücre olmamalı; eğim yurt gövdeleri, yarı gömük ev ve yerleşimde çadırla kulübe için en çok 6°, ahşap ve avlu yapıları için 9°, çizgi yapılar (ağıl, çit, at hattı, sur, çit halkası) için parça başına 15°'dir (K57). Su ve buz olmamalı, başka yapının duvarına en az 4 m (8 m'nin altında «Ateş payı dar» uyarısı), yola en az 3 m kalmalı. Hane yatan yapı suya en çok 150 m olmalı, aşılırsa Gönül −0,3/gün. Demirci Ocağı, Fırın ve Sepi Yeri konuta en az 40 m ve hâkim rüzgârın altında durmalı, yoksa Gönül −0,2/gün. İzdeki ağaç ve iri kaya önce kesilir ya da kırılır. Geçersizse en çok üç neden yazılır: «Yer düz değil», «Ağaç var», «Başka yapıya çok yakın».

**Bakım** ([settlement.md §7.10](/docs/source/design/settlement#7-10-bakim)). Hiçbir yapı kurulup unutulmaz: 10 günde bir mevsim payı ambardan düşer. Yurt gövdeliler mevsimde 1 keçe ve 1 ip, Küçük Yurt ½ keçe ve 1 ip, Otağ ve Bey Otağı 2 ak keçe, 2 ip ve 1 kızıl boya, çadır 1 keçe ister. Ahşap yapılar 2 odun ve 2 saz; Keçe Avlusu ve Sepi Yeri 2 saz ve 1 ip; Demirci Ocağı ve Fırın 2 kil (körüğe yılda 1 sepi deri); Ağıl 6 dal, çit ve çit halkası 1 odun; At Hattı ve Kuyu 1 ip; yarı gömük ev 2 saz ve 1 kil; Toy Alanı ve Gök Direği 1 keçe ister. Sur 0,02 İG emek ister, sağanaktan sonra 0,05. Ödenmezse yapının en üst havuzu %25 düşer, konutta hane Gönül −1. IV. kademede (≈100 yapı) bakım mevsim başına ≈3,4 İG ve ≈55 keçedir: yerleşim emeğinin %1'inden azı.

> [!DURUM]
> Oyunda (Godot): menü ve Serbest Gez kampında ahır (Meshy modeli; fenerli, iki at bağlı) ve yedi parça çit bitmiş hâlde durur. 2026-11-09'dan beri Kışlak'ın öteki yapıları kodla kurulan aşama kitidir: Ulu Ocak (12 m meydan), ahır (8 bölme; atlar bölmelere bağlanır), Kule (4 aşama), Keçe Avlusu, Mutfak Kazanı ve kurutma sehpaları, Odunluk, İş Tahtası, Sayım Taşı, Nöbet Yurdu, Kantu'nun Barakası (ambar da onun kitiyle durur), Hela, Adak Ağılı (44 × 30 m çit ve kapı) ve Esir Çukuru'nun kapısı. Yapılar haritanın kaydından gelir, izleri engeldir, aşamaları vardır. Ahırın içine girince çatı kalkar, kameraya bakan yan alçalır ([K98](/docs/source/design/decisions#k98); [karesi](/media/docs/media/review/kislak_ahir_kesit.jpg)); ağılların çiti oyuncuyu, kişileri ve sürüyü durdurur, kapıdan geçilir. Yok: Plan Kipi, şantiye (yalnız Serbest Gez'in üçüncü yurdu kurulur), atölyelerin ve ambarın işi, hasar. Prototipte denendi: ana kampın ahırı ve çitlerinin hasarı ve onarımı; ağıl, araba, kulübe, sundurma, tahıl ambarı, kule ve köprünün aşama ve can kuralı (görünüşsüz); zanaat tezgâhları ve tarifleri.


İş Yol Haritası'ndadır: [Kışlak'ın öteki yapıları](/roadmap#item-building-catalog) I. Perde'de; [Plan Kipi](/roadmap#item-plan-mode) ve [yerleşim](/roadmap#item-settlement) II'de; [Boy Yurdu kademesi](/roadmap#item-boy-yurdu) III'te; [Toy Yeri kademesi](/roadmap#item-toy-yeri) IV'te; [Tanhu Avlusu'nun iki yolu](/roadmap#item-avlu-paths) V'te.

```ilerleme
act-2-p2
```

## Kaynaklar

- [settlement.md §7: yapı kataloğu](/docs/source/design/settlement#7-yapi-katalogu)
- [settlement.md §4.1: kademeler](/docs/source/design/settlement#4-1-tablo)
- [settlement.md §13.2: yer kuralları](/docs/source/design/settlement#13-2-kurallar)
- [structures.md §4: diğer yapılar](/docs/source/design/structures#4-diger-yapilar)
- [structures.md §4.6: emek tablosu](/docs/source/design/structures#4-6-yerlesim-ve-ordugah-yapilari-k23)
- [economy.md §6.12: bütün yapıların malzemesi](/docs/source/design/economy#6-12-butun-yapilarin-malzemesi)
- [travel.md: arabalar](/docs/source/design/travel)
- [decisions.md: K24 ekonomi](/docs/source/design/decisions#k24)
- [decisions.md: K50 emek eğrisi](/docs/source/design/decisions#k50)
- [decisions.md: K52 Ağaç Atölyesi ve sur odunu](/docs/source/design/decisions#k52)
- [decisions.md: K57 Araba kartı ve eğim](/docs/source/design/decisions#k57)
- `d2/labour-model.json` v3: adım emekleri ve el tavanları
